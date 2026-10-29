import XCTest
import FerazelCore
@testable import FerazelRender

/// The renderer loads every face the original loads at boot (`BootFaces`), then the level's caches — so no sprite Core
/// can make draws a face that is not loaded. The faces Core can reference are derived, not listed: every Setup sheet of
/// every placement in the shipped levels, every class sheet list Core declares, and every literal PICT in a
/// `FaceRef(pict:` / `Face(pict:` in Core's sources. A missing data file is a FAILURE, never a skip.
final class BootFacesTests: XCTestCase {
    nonisolated(unsafe) private static let resources = Result { try FerazelData.open(try FerazelData.dataDirectory()) }

    private static func sheet(_ loader: FaceSheet.Loader) -> SetupFaces.Sheet {
        switch loader {
        case .single(let pict): return .single(pict)
        case .set(let a):
            return SetupFaces.Sheet(pict: a.pict, count: a.count, cellWidth: a.cellWidth, cellHeight: a.cellHeight,
                                    columns: a.columns, clut: 200)
        }
    }

    /// Every sheet Core declares outside the per-placement Setups.
    private static var classSheets: [SetupFaces.Sheet] {
        BonusSprite.sheets + PlayerShot.sheets + HeldItem.sheets + ButtonSprite.sheets + SetupFaces.boxChildSheets
            + SetupFaces.platformSheets + SetupFaces.backgroundSheets + SetupFaces.backgroundW2bSheets
            + Array(BoxSprite.spawnSheets) + Array(BonusSprite.dropSheets)
            + (FaceSheet.playerSheets + FaceSheet.gliderSheets).map(sheet)
    }

    /// The Setup sheets of every placement of `level` (the Setups not transcribed yet make none).
    private static func setupSheets(_ L: LevelFile) -> [SetupFaces.Sheet] {
        let ctx = SetupFaces.Context(level: L, playerX: SetupFaces.Context.levelStartPlayerX(L.header), effects: 1)
        return L.activePlacements.compactMap { try? SetupFaces.setup($0, context: ctx).sheet }
            + Array(BoxSprite.dropSheets(L.placements))
    }

    /// The literal PICTs Core's sources face sprites with at run time (`FaceRef(pict: 0x…` / `Face(pict: 0x…`).
    private static func literalFacePicts() throws -> Set<Int16> {
        let core = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
            .deletingLastPathComponent().appendingPathComponent("Sources/FerazelCore")
        let files = try XCTUnwrap(FileManager.default.enumerator(at: core, includingPropertiesForKeys: nil))
        let pattern = try NSRegularExpression(pattern: #"\bFace(?:Ref)?\(pict: (0x[0-9a-fA-F]+|[0-9]+)\s*,"#)
        var out = Set<Int16>()
        for case let url as URL in files where url.pathExtension == "swift" {
            for line in try String(contentsOf: url, encoding: .utf8).split(separator: "\n") {
                let code = String(line.split(separator: "//", maxSplits: 1, omittingEmptySubsequences: false).first ?? "")
                let ns = code as NSString
                for m in pattern.matches(in: code, range: NSRange(location: 0, length: ns.length)) {
                    let lit = ns.substring(with: m.range(at: 1))
                    out.insert(Int16(lit.hasPrefix("0x") ? Int(lit.dropFirst(2), radix: 16)! : Int(lit)!))
                }
            }
        }
        return out
    }

    /// `BootFaces` matches every other definition Core makes of the same PICT (cells, columns, CLUT), so the first
    /// definition the renderer loads is the one every reader expects.
    func testBootFacesAgreeWithEveryDeclaration() throws {
        let res = try Self.resources.get()
        let boot = Dictionary(uniqueKeysWithValues: BootFaces.sheets.map { ($0.pict, $0) })
        XCTAssertEqual(boot.count, BootFaces.sheets.count, "no PICT twice")
        var all = Self.classSheets
        for r in res.world.resources(of: "Mlvl") { all += Self.setupSheets(try LevelFile(resource: r)) }
        for s in all { if let b = boot[s.pict] { XCTAssertEqual(s, b, "PICT \(s.pict)") } }
    }

    /// Levels 1–4: every boot face the data holds, every class sheet Core declares and every Setup sheet of the level's
    /// placements is loaded; and every literal PICT Core faces a sprite with is one of those or a per-level cache face
    /// `.LoadCachedSpriteFaces` loads for some level 1–4 (`CachedFaces.needed`) — a cache face is drawn only by the type
    /// whose Setup sheet carries it, which the first check covers on the levels that place it.
    func testEveryReferencedFaceIsLoaded() throws {
        let res = try Self.resources.get()
        let literals = try Self.literalFacePicts()
        XCTAssertGreaterThanOrEqual(literals.count, 15)
        let present: (Int16) -> Bool = { res.resource(type: "PICT", id: $0, chain: .frontEnd) != nil }
        let always = Set(BootFaces.sheets.map(\.pict) + Self.classSheets.map(\.pict))
        var cachedSomewhere = Set<Int16>()
        for level in BuiltLevels.range {
            let r = try FrameRenderer(resources: res, level: level, search: ColorSearch(model: .ruled, tieBreak: .lowest),
                                      dither: .errorDiffusion, text: StatusBarTests.BoxRasterizer(), prefs: FerazelPrefs())
            let loaded = r.sprites.faces.sheets
            for p in always.union(Self.setupSheets(r.level).map(\.pict)).sorted() where present(p) {
                XCTAssertNotNil(loaded[p], "level \(level): PICT \(p) (0x\(String(p, radix: 16))) not loaded")
            }
            let s = try FerazelSession(resources: res, prefs: FerazelPrefs(), level: level, seed: 1,
                                       faceBounds: r.faceBounds)
            let needed = CachedFaces.needed(by: s)
            cachedSomewhere.formUnion(literals.filter { needed.sets.contains($0) || needed.singles.contains($0) })
        }
        for p in literals.subtracting(always).sorted() {
            XCTAssertTrue(cachedSomewhere.contains(p), "PICT \(p) (0x\(String(p, radix: 16))): a literal face no loader knows")
        }
    }
}
