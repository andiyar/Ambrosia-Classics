import Foundation
import HectorResources
@testable import FerazelCore

/// 6A-FX — the level fixture (docs/superpowers/plans/2026-11-04-ferazel-remainder.md, "Verification-model additions for
/// 6A": the design, stated there once; docs/ferazel/phase6-engine-contracts.md §7.2; DECISIONS D46.3). A named TEST
/// STAND-IN, never in `Sources`: a level's real `Mlvl` with the listed placements' active flag cleared and the named
/// header bytes patched — every other record, every other header byte and the maps after the header as the level has
/// them. The patch is made in memory; the data files stay read-only.
///
/// ONE file in both test targets: `Tests/FerazelRenderTests/LevelFixture.swift` is a git symlink to this file, at the
/// same folder depth. So it compiles under each target's imports — Foundation, HectorResources and FerazelCore only —
/// and the Render half (the renderer-backed services) lives in `FerazelRenderTests/LevelFixtureServices.swift`.
/// Proof-B rules hold here too: no `@MainActor`, no `FileManager.enumerator`, no `NSRegularExpression`, no Foundation
/// string search or trim.
enum LevelFixture {
    /// One entry of a leave-out list: every active record of a type, or one active record by placement index.
    enum LeaveOut: Equatable, Sendable {
        case type(Int16)
        case record(Int)
    }

    /// A header patch: `bytes` written at `offset` into the `Mlvl` (inside its 0xb29c-byte header).
    typealias HeaderPatch = (offset: Int, bytes: [UInt8])

    /// A leave-out list or header patch that does not fit the level (a fixture written wrong — never skipped).
    enum Misuse: Error, Equatable {
        case noLevel(Int)
        case typeNotPlaced(Int16)
        case recordNotActive(Int)
        case headerOutOfRange(offset: Int, count: Int)
        /// A header patch inside the placement table (bytes 4 ..< 4 + 16·511): records change through `leaveOut` only.
        case headerInPlacementTable(offset: Int, count: Int)
    }

    /// The shipped data (`FerazelData.open`), opened once per test process.
    nonisolated(unsafe) static let base = Result { try FerazelData.open(try FerazelData.dataDirectory()) }

    /// Level 21's leave-out list (6A-FX; LL §4 "Level 21", ENG §7.2): its 30 refused records, by type — every record
    /// of each type. A literal list, never computed from what the port refuses today: a later task that builds one of
    /// these types never edits it, so nothing this fixture pins moves. It lives here, not in a test, because both halves
    /// of 6A-FX's proof read it (the Render target cannot see a Core test's private list); it is frozen, and the Core test
    /// pins it again with literals (13 entries, 30 records, the count per type). Later fixtures' lists live in their own
    /// test files.
    static let level21: [LeaveOut] = [
        // The faces and talkers (6A-BX1b): 1061 ×14, 2921 ×2, 2962 ×1.
        .type(1061), .type(2921), .type(2962),
        // The level 21 pipe wiring: 1490, 1491 ×3, 1492, 1493.
        .type(1490), .type(1491), .type(1492), .type(1493),
        // The Box scenery (6A-BX1a): 2827, 2831 ×2, 2833, 2834, 2836, 2850.
        .type(2827), .type(2831), .type(2833), .type(2834), .type(2836), .type(2850),
    ]

    /// The active records (flag 1) of `level` that `leaveOut` names, in record order (an entry named twice counts once).
    /// Throws `Misuse` for a type with no active record on the level, or a record index that is not active or out of
    /// range (`recordNotActive`).
    static func leftOut(_ level: LevelFile, _ leaveOut: [LeaveOut]) throws -> [Int] {
        var out = Set<Int>()
        for entry in leaveOut {
            switch entry {
            case .type(let t):
                let hit = level.placements.filter { $0.flag == 1 && $0.type == t }.map(\.index)
                guard !hit.isEmpty else { throw Misuse.typeNotPlaced(t) }
                out.formUnion(hit)
            case .record(let i):
                guard level.placements.indices.contains(i), level.placements[i].flag == 1 else {
                    throw Misuse.recordNotActive(i)
                }
                out.insert(i)
            }
        }
        return out.sorted()
    }

    /// The shipped resources with `Mlvl <level>` patched in memory: the left-out records' active flag (record i's
    /// byte `4 + 16·i`, `.SetupLevelSprites` spawns flag 1 only) set to 0, then each `header` patch written. Every other
    /// resource of every file as shipped (the World Data collection copied, the `GameFlowGameTests` pattern). Throws
    /// `Misuse` for a level with no `Mlvl`, a bad leave-out entry (`leftOut`), or a header patch past the header or
    /// touching the placement table (records change through `leaveOut` only).
    static func resources(level: Int, leaveOut: [LeaveOut], header: [HeaderPatch] = []) throws -> FerazelResources {
        let r = try base.get()
        guard let mlvl = r.world.resource(type: "Mlvl", id: Int16(level)) else { throw Misuse.noLevel(level) }
        let file = try LevelFile(resource: mlvl)
        var d = mlvl.data
        for i in try leftOut(file, leaveOut) { d[d.startIndex + 4 + 16 * i] = 0 }
        for p in header {
            guard p.offset >= 0, p.offset + p.bytes.count <= LevelFile.headerSize else {
                throw Misuse.headerOutOfRange(offset: p.offset, count: p.bytes.count)
            }
            guard p.offset + p.bytes.count <= 4 || p.offset >= 4 + 16 * LevelFile.placementCount else {
                throw Misuse.headerInPlacementTable(offset: p.offset, count: p.bytes.count)
            }
            for (k, b) in p.bytes.enumerated() { d[d.startIndex + p.offset + k] = b }
        }
        var world = ResourceCollection()
        for type in r.world.types() {
            for res in r.world.resources(of: type) {
                guard type == "Mlvl" && res.id == mlvl.id else { world.add(res); continue }
                world.add(Resource(type: type, id: res.id, name: res.name, data: d))
            }
        }
        return FerazelResources(app: r.app, world: world, backgrounds: r.backgrounds, sprites: r.sprites,
                                sounds: r.sounds, titles: r.titles, musicDirectory: r.musicDirectory)
    }

    /// The patched level opened **through the level runner** (`LevelRun.init`, `Front/LevelRun.swift:247`; the
    /// `GoblinBurnLevelRunTests` pattern — never through `BuiltLevels`, which `LevelRun` does not consult), so the
    /// level setup runs as the game's does. Nothing is ticked yet: the caller ticks the run (its first ticks hold
    /// `.SetupLevel`'s draws, which a renderer must see). `start` nil → the header's start; `services` defaults to
    /// the headless stub (no faces) so the Core rules tests open fixtures directly; the Render tests pass
    /// `LevelFixtureServices.open`, which builds the patched resources once for the run and its renderer.
    static func open(level: Int, leaveOut: [LeaveOut], header: [HeaderPatch] = [], start: (x: Int, y: Int)? = nil,
                     prefs: FerazelPrefs = FerazelPrefs(), carry: LevelCarry = LevelCarry(),
                     services: LevelServices = Headless(), seed: Int32 = 1) throws -> LevelRun {
        try open(resources: try resources(level: level, leaveOut: leaveOut, header: header), level: level, start: start,
                 prefs: prefs, carry: carry, services: services, seed: seed)
    }

    /// `open` on resources already patched (`resources(level:leaveOut:header:)`) — the one path both halves use, so a
    /// run and its renderer (`LevelFixtureServices.open`) read one patched data set, built once. `StageSounds` carries
    /// no sound lengths: `LevelRun` reads them only for the stage-complete sound at a level's end (`LevelRun.swift`,
    /// `.stageComplete`), so a fixture test that finishes a level gets that sound with length 0. No `files:` and no
    /// `date:`: the pause's prefs read sees defaults and a save writes no file.
    static func open(resources: FerazelResources, level: Int, start: (x: Int, y: Int)? = nil,
                     prefs: FerazelPrefs = FerazelPrefs(), carry: LevelCarry = LevelCarry(),
                     services: LevelServices = Headless(), seed: Int32 = 1) throws -> LevelRun {
        try LevelRun(resources: resources, prefs: prefs, level: level, seed: seed, carry: carry, save: SaveBlock(),
                     fade: ScreenFade(), music: MusicFade(), services: services,
                     sounds: StageSounds(prefs: prefs, lengths: [:]), start: start)
    }

    /// The first `limit` byte offsets where `a` and `b` differ (past the shorter one's end, every offset differs) — a
    /// failure message's worth, never the ~1 MB a whole-level `XCTAssertEqual` prints.
    static func firstDifferences(_ a: Data, _ b: Data, limit: Int = 8) -> [Int] {
        let x = [UInt8](a), y = [UInt8](b)
        return Array((0 ..< max(x.count, y.count)).lazy.filter { $0 >= x.count || $0 >= y.count || x[$0] != y[$0] }
            .prefix(limit))
    }

    /// A refusal named by record as well as by type, for a failure message. A Setup refuses by type
    /// (`SetupFaces.Error.notTranscribed` / `.unmapped`), so every active record of that type on `level` refuses: the
    /// message names the level and those records' placement indices — what a leave-out list must name. Any other error
    /// as it is.
    static func describe(_ error: Error, level: LevelFile) -> String {
        let type: Int16
        switch error as? SetupFaces.Error {
        case .notTranscribed(let t)?, .unmapped(let t)?: type = t
        default: return "\(error)"
        }
        let records = level.activePlacements.filter { $0.type == type }.map(\.index)
        return "\(error) — level \(level.id): active records \(records) of type \(type)"
    }

    /// The headless `LevelServices` (no faces) — the stub the Core `LevelRun` tests use (`SoundVoicesTests`).
    final class Headless: LevelServices {
        func prepare(level: Int) throws -> LevelFaces { LevelFaces() }
        func attach(lights: [SetupFaces.Light], tintTableDraws: [Int16]) throws {}
        func deathEffectStep(_ k: Int) throws {}
    }
}
