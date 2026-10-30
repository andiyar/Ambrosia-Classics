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

    /// Core's `.swift` sources, read once: the number of files and every line with its `//` comment cut off. One code
    /// path on every platform, with no Foundation call Wine lacks (PB fix round 3): no directory enumerator (it reads
    /// file attributes — advapi32 under Wine), no regex (ICU) — only `contentsOfDirectory(atPath:)`,
    /// `fileExists(atPath:isDirectory:)` and `String(contentsOf:)`, which run green in Proof B elsewhere.
    private static let coreSources = Result { () throws -> (files: Int, lines: [String]) in
        let core = URL(fileURLWithPath: #filePath).resolvingSymlinksInPath().deletingLastPathComponent()
            .deletingLastPathComponent().deletingLastPathComponent().appendingPathComponent("Sources/FerazelCore")
        let fm = FileManager.default
        var files = 0, lines: [String] = [], folders = [core]
        while let dir = folders.popLast() {
            for name in try fm.contentsOfDirectory(atPath: dir.path).sorted() where !name.hasPrefix(".") {
                let url = dir.appendingPathComponent(name)
                var isDir: ObjCBool = false
                guard fm.fileExists(atPath: url.path, isDirectory: &isDir) else { continue }
                if isDir.boolValue { folders.append(url); continue }
                guard name.hasSuffix(".swift") else { continue }
                files += 1
                for line in try String(contentsOf: url, encoding: .utf8).split(separator: "\n") {
                    lines.append(String(line.split(separator: "//", maxSplits: 1, omittingEmptySubsequences: false)
                        .first ?? ""))
                }
            }
        }
        return (files, lines)
    }

    /// Every `Face(pict: <lit>,` / `FaceRef(pict: <lit>,` in `code` — `<lit>` one `0x…` hex or decimal literal, then
    /// optional whitespace and a comma, `Face` not preceded by a word character. Pure Swift over UTF-8 bytes.
    private static func facePictLiterals(in code: String) -> [Int16] {
        let b = Array(code.utf8)
        func at(_ i: Int, _ s: String) -> Bool {
            let t = Array(s.utf8)
            return i + t.count <= b.count && b[i..<(i + t.count)].elementsEqual(t)
        }
        func isWord(_ c: UInt8) -> Bool {
            c >= 0x80 || c == 0x5f || (c >= 0x30 && c <= 0x39) || ((c | 0x20) >= 0x61 && (c | 0x20) <= 0x7a)
        }
        func digits(from i: Int, _ ok: (UInt8) -> Bool) -> Int {
            var j = i
            while j < b.count && ok(b[j]) { j += 1 }
            return j
        }
        let isDec: (UInt8) -> Bool = { $0 >= 0x30 && $0 <= 0x39 }
        let isHex: (UInt8) -> Bool = { isDec($0) || (($0 | 0x20) >= 0x61 && ($0 | 0x20) <= 0x66) }
        var out: [Int16] = [], i = 0
        while i < b.count {
            defer { i += 1 }
            guard at(i, "Face"), i == 0 || !isWord(b[i - 1]) else { continue }
            var j = i + 4
            if at(j, "Ref") { j += 3 }
            guard at(j, "(pict: ") else { continue }
            j += 7
            let value: Int?, end: Int
            if at(j, "0x"), digits(from: j + 2, isHex) > j + 2 {
                end = digits(from: j + 2, isHex)
                value = Int(String(decoding: b[(j + 2)..<end], as: UTF8.self), radix: 16)
            } else {
                end = digits(from: j, isDec)
                value = end > j ? Int(String(decoding: b[j..<end], as: UTF8.self)) : nil
            }
            var k = end
            while k < b.count && (b[k] == 0x20 || b[k] == 0x09) { k += 1 }
            guard let value, k < b.count, b[k] == 0x2c else { continue }
            out.append(Int16(value))
            i = k
        }
        return out
    }

    /// The literal PICTs Core's sources face sprites with at run time (`FaceRef(pict: 0x…` / `Face(pict: 0x…`).
    private static func literalFacePicts() throws -> Set<Int16> {
        Set(try coreSources.get().lines.flatMap(facePictLiterals))
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
        let scanned = try Self.coreSources.get().files
        XCTAssertGreaterThanOrEqual(scanned, 100, "Core .swift files scanned (0 = the source walk found nothing)")
        XCTAssertGreaterThanOrEqual(literals.count, 15, "literal face PICTs in \(scanned) Core .swift files")
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
