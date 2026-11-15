import XCTest
@testable import DeimosCore
@testable import DeimosHost

/// The campaign sweep (plan CS; appendix B §4). **A MACHINE SMOKE CHECK, NOT A FIDELITY PROOF.** No demo film covers
/// sectors 5–12, a level transition or the finale, so this bundle plays them with a cheat and a robot: every pass,
/// before it runs, each in-game player is forced invulnerable and sticky (+0xce / +0xcf — "god mode"; it blocks the
/// shield loss in `FUN_10027100`, `10027154..10027160`, and like the real flag also refuses weapon pickups,
/// `10037630..10037658`), and the keys come from a deterministic pilot, not a person. What it proves: every sector
/// runs to its level end and on into the next sector (or, after sector 12, to the campaign's end) without a trap, the
/// units it spawns all belong to that level's data, and one session started at sector 1 reaches the finale and ends.
/// What it does NOT prove: that any tick matches the original — the ship cannot die, so the game's own course is not
/// the original's, and only the films (G4) and the unit tests read from the listing are fidelity checks.
///
/// The pilots. **Passive**: no keys at all. **Scripted** (deterministic, from the pass count alone): a left/right
/// sweep (45 passes each way), both fire buttons held for 120 passes of every 150 and released for 30, and Select
/// tapped (one pass) every 600. The release is the one departure from appendix B §4's "fire held": a weapon whose
/// power-up runs longer than its overload time (180 ticks for the Ion Cannon, Bacta Gun and Rear Gun) overloads
/// (`1003c230..1003c248`), and the overload's last warning kills the ship (`10027040..1002705c`) whether or not it is
/// invulnerable — a held button would end every scripted run in a death the cheat cannot stop. A release also lets
/// the pending air weapon chosen by Select take effect (`1003c4b4..1003c4d4`), which is how the scripted pilot reaches
/// the Photon Beam at sector 5 and beyond. In a two-player run player 2 flies its own script on its own pad, phased
/// against player 1's (`scriptB`), so that what player 2 does can be told from what player 1's keys would make it do.
///
/// Logic only: no renderer. Every loop names its bound and fails on reaching it. A failure writes the run's
/// `ReplayTrace` CSV (with its sector column) to the temporary directory and names the file.
final class CampaignSweepTests: XCTestCase {

    // MARK: - The pilot and god mode

    enum Pilot: String, CaseIterable { case passive, scripted }

    struct Pad { let left, right, fireAir, fireGround, select: UInt16 }

    /// The fresh prefs' key table (`1000515c..10005194`): P1 ← → ⌘ (fire air) ⌥ (fire ground) Space (select); P2
    /// keypad 4, keypad 6, End, Forward Delete, Page Down.
    static let pads = [Pad(left: 0x7B, right: 0x7C, fireAir: 0x37, fireGround: 0x3A, select: 0x31),
                       Pad(left: 0x56, right: 0x58, fireAir: 0x77, fireGround: 0x75, select: 0x79)]

    static let sweepHalf = 45, firePeriod = 150, fireHeld = 120, selectPeriod = 600

    /// One pad's scripted controls, a pure function of the pass count: the sweep (shifted by `sweepPhase`, starting
    /// right when `startRight`), both fire buttons held while `(k + firePhase) mod 150 < 120`, Select on the pass
    /// where `k mod 600 == selectAt`.
    struct Script {
        let sweepPhase: Int, startRight: Bool, firePhase: Int, selectAt: Int

        /// The controls this script holds on pass `k` — what the key table must hand that player (film byte order).
        func input(pass k: Int) -> PlayerInput {
            let t = CampaignSweepTests.self
            var out: PlayerInput = (((k + sweepPhase) / t.sweepHalf) % 2 == 0) != startRight ? .left : .right
            if (k + firePhase) % t.firePeriod < t.fireHeld { out.formUnion([.fireAir, .fireGround]) }
            if k % t.selectPeriod == selectAt { out.insert(.select) }
            return out
        }

        /// The keys of `pad` that hold `input(pass: k)`.
        func keys(pass k: Int, pad: Pad) -> Set<UInt16> {
            let i = input(pass: k)
            let map: [(PlayerInput, UInt16)] = [(.left, pad.left), (.right, pad.right), (.fireAir, pad.fireAir),
                                                (.fireGround, pad.fireGround), (.select, pad.select)]
            return Set(map.filter { i.contains($0.0) }.map(\.1))
        }
    }

    /// Player 1's script — every one-player run flies it: left first, fire from pass 0, Select on pass 599 of 600.
    static let scriptA = Script(sweepPhase: 0, startRight: false, firePhase: 0, selectAt: 599)
    /// Player 2's own script, phased against player 1's so the two pads differ on most passes: its sweep 22 passes
    /// on and starting right, its fire released for `k mod 150` in 45 ..< 75 (player 1's: 120 ..< 150), Select on
    /// pass 299 of 600.
    static let scriptB = Script(sweepPhase: 22, startRight: true, firePhase: 75, selectAt: 299)

    /// The pilot's keys for pass `k` (0-based, counted from the session's start), for the first `players` pads:
    /// player 1 flies `scriptA`, player 2 `scriptB`.
    static func keys(_ pilot: Pilot, pass k: Int, players: Int) -> HeldKeys {
        guard pilot == .scripted else { return HeldKeys() }
        return keys(pass: k, scripts: Array([scriptA, scriptB].prefix(players)))
    }

    /// The keys for pass `k` when pad `i` flies `scripts[i]` (nil: that pad untouched).
    static func keys(pass k: Int, scripts: [Script?]) -> HeldKeys {
        var held = Set<UInt16>()
        for (pad, script) in zip(pads, scripts) {
            if let script { held.formUnion(script.keys(pass: k, pad: pad)) }
        }
        return HeldKeys(held: held)
    }

    /// God mode (appendix B §4 item 1): each in-game player invulnerable and sticky before the pass.
    static func godMode(_ s: inout DeimosSession) {
        for i in s.game.players.indices where s.game.players[i].inGame {
            s.game.players[i].invulnerable = true
            s.game.players[i].invulnerableSticky = true
        }
    }

    /// One sweep pass: god mode, then the pilot's keys.
    @discardableResult
    static func step(_ s: inout DeimosSession, _ pilot: Pilot, pass k: Int, players: Int) -> PassOutput {
        godMode(&s)
        return s.pass(keys: keys(pilot, pass: k, players: players), ticks: 0)
    }

    /// The level of each sector, 1…12 (appendix B §3, by the levels' identifiers: Lucena, Yippe, Vista, Swoop, Conrad,
    /// Delos, Sparta, Saratoga, Hannibal, Leonidas, Thebes, Yamato) — literals, not the code's level order.
    static let levels = ["le07", "le06", "le02", "le08", "le11", "le04", "le12", "le03", "le05", "le01", "le10", "le09"]
        .map { FourCC($0)! }

    static func level(sector: Int) -> FourCC { levels[sector - 1] }

    static func session(sector: Int, players: Int) throws -> DeimosSession {
        try DeimosSession(assets: CampaignTestData.getAssets(), prefs: .fresh,
                          start: SessionStart(sector: sector, players: players, film: nil), seed: 0x469c2,
                          levels: CampaignTestData.getLevels())
    }

    /// Writes `trace` to the temporary directory as `deimos-campaign-<name>.csv`; returns the file and its last rows,
    /// for a failure message.
    static func dump(_ trace: ReplayTrace, name: String) -> String {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("deimos-campaign-\(name.replacingOccurrences(of: " ", with: "-")).csv")
        let written = (try? trace.write(to: url)) != nil
        let tail = trace.rows.suffix(3).map(ReplayTrace.csvLine).joined(separator: " | ")
        return (written ? "trace \(url.path)" : "trace not written") + "; columns \(ReplayTrace.csvHeader); last rows \(tail)"
    }

    /// Why a session that is not running stopped, in words (the sweep presses neither Esc nor Caps Lock).
    static func why(_ s: DeimosSession) -> String {
        let f = s.game.flags
        if !s.players.contains(where: \.inGame) { return "game over (no player in game)" }
        return "level \(f.level), sector \(f.sector), levels started \(f.levelsStarted), level complete \(f.levelComplete)"
    }

    // MARK: - The census

    /// Each level's unit closure, computed from the definitions (appendix B §4 item 4): the units the level places,
    /// the units of the air and ground weapons its sector allows (minimum ≤ sector ≤ maximum, a maximum < 1 read as
    /// 9,999), the 40 permanent objects (`idli gaob`) and every unit a player definition names — and then, again and
    /// again, every unit named by an `…_ID <tag>` value (not a sprite, sound or layer key) in the definition text of a
    /// unit already in the set. Rule
    /// branches never taken make the closure larger than what a run spawns; that difference is information only.
    struct Census {
        let units: Set<FourCC>
        let refs: [FourCC: Set<FourCC>]
        let common: Set<FourCC>
        let weapons: [(min: Int32, max: Int32, refs: Set<FourCC>)]
        let placed: [Int: Set<FourCC>]

        static let shared: Result<Census, Error> = Result { try Census() }

        init() throws {
            let a = try CampaignTestData.getAssets()
            let units = Set(a.unitIndex.keys)
            self.units = units
            var refs: [FourCC: Set<FourCC>] = [:]
            for u in units { refs[u] = Self.unitIDs(in: try CampaignTestData.text(type: "unde", id: u), units) }
            self.refs = refs
            var common = Set(a.objects).intersection(units)
            for p in a.definitions.players {
                common.formUnion(Self.unitIDs(in: try CampaignTestData.text(type: "plde", id: p.id), units))
            }
            self.common = common
            weapons = try a.definitions.weapons.map { w in
                (w.minimumLevelAvailable, w.maximumLevelAvailable < 1 ? 9999 : w.maximumLevelAvailable,
                 Self.unitIDs(in: try CampaignTestData.text(type: "wede", id: w.id), units))
            }
            var placed: [Int: Set<FourCC>] = [:]
            for sector in 1...12 {
                let tag = CampaignSweepTests.level(sector: sector)
                guard let level = a.definitions.levels.first(where: { $0.id == tag }) else {
                    throw CampaignTestData.Missing(description: "no level definition '\(tag)' for sector \(sector)")
                }
                placed[sector] = Set(level.objects.map(\.unit))
            }
            self.placed = placed
        }

        /// Every `#key_ID <tag>` value in `text` that names a unit — except under the keys that name a sprite, a
        /// sound or a draw layer (`…SpriteFace_ID`, `…Face_ID`, `…Sound_ID`, `drawLayer_ID`): those tag spaces share
        /// names with units (the sound `miac` and the iris unit `miac`, say), and reading them as units would pull
        /// unrelated units into the closure.
        static func unitIDs(in text: [UInt8], _ units: Set<FourCC>) -> Set<FourCC> {
            let key = Array("_ID <".utf8), close = UInt8(ascii: ">"), hash = UInt8(ascii: "#")
            var out = Set<FourCC>()
            var i = 0
            while i + key.count + 5 <= text.count {
                guard text[i] == key[0], Array(text[i..<(i + key.count)]) == key, text[i + key.count + 4] == close else {
                    i += 1
                    continue
                }
                var k = i
                while k > 0 && text[k] != hash && text[k] != 0x0a && text[k] != 0x0d { k -= 1 }
                let name = String(decoding: text[k..<i], as: UTF8.self) + "_ID"
                let excluded = name.hasSuffix("Face_ID") || name.hasSuffix("Sound_ID") || name == "#drawLayer_ID"
                let id = FourCC(bytes: Array(text[(i + key.count)..<(i + key.count + 4)]))
                if !excluded && units.contains(id) { out.insert(id) }
                i += key.count + 5
            }
            return out
        }

        func closure(sector: Int) -> Set<FourCC> {
            var seed = common.union(placed[sector] ?? [])
            for w in weapons where w.min <= Int32(sector) && Int32(sector) <= w.max { seed.formUnion(w.refs) }
            var seen = Set<FourCC>(), stack = Array(seed)
            while let u = stack.popLast() {
                guard units.contains(u), seen.insert(u).inserted else { continue }
                stack += refs[u] ?? []
            }
            return seen
        }
    }

    /// The units of every entity created with a serial in `first ..< nextSerial` — the pass's spawns, read from the
    /// pool slots (a slot freed in the pass keeps its entity until it is allocated again). A spawn whose slot was
    /// freed and allocated again within the same pass is not seen: the census is a lower bound.
    static func newUnits(_ g: GameState, from first: Int32, into set: inout Set<FourCC>) {
        let end = g.world.nextSerial
        guard end != first else { return }
        let units = g.assets.definitions.units
        g.world.entities.withUnsafeBufferPointer { buf in
            for i in buf.indices where buf[i].serial >= first && buf[i].serial < end && buf[i].unit >= 0 {
                set.insert(units[buf[i].unit].id)
            }
        }
    }

    /// The crossing pass's spawns into a sector 2–12, split at the level start's pool reset (`EntityWorld.levelReset`:
    /// every slot out of use, serials from 1000 again). The next level's start spawns are the slots in use after the
    /// pass (serial in 1000 ..< `nextSerial`); this level's own spawns earlier in the pass are the slots out of use
    /// whose serial is ≥ `first`, the serial at the pass's start (a slot taken again after the reset is lost: a lower
    /// bound, as in `newUnits`). The split needs the two serial runs apart (`nextSerial` ≤ `first`); false when not.
    static func crossingUnits(_ g: GameState, from first: Int32, level: inout Set<FourCC>,
                              nextLevel: inout Set<FourCC>) -> Bool {
        let end = g.world.nextSerial
        guard end <= first else { return false }
        let units = g.assets.definitions.units
        g.world.entities.withUnsafeBufferPointer { buf in
            for i in buf.indices where buf[i].unit >= 0 {
                if g.world.inUse[i] && buf[i].serial >= EntityWorld.firstSerial && buf[i].serial < end {
                    nextLevel.insert(units[buf[i].unit].id)
                } else if !g.world.inUse[i] && buf[i].serial >= first {
                    level.insert(units[buf[i].unit].id)
                }
            }
        }
        return true
    }

    /// Whether a live (in use, not deleted) entity of unit `id` is in the pool.
    static func isLive(_ g: GameState, _ id: FourCC) -> Bool {
        guard let ui = g.assets.unitIndex[id] else { return false }
        return g.world.entities.withUnsafeBufferPointer { buf in
            buf.indices.contains { g.world.inUse[$0] && !buf[$0].deleted && buf[$0].unit == ui }
        }
    }

    // MARK: - One sector from a direct start

    struct SectorRun {
        var passes = 0
        /// The pass (1-based) after which G+0x39 first stood.
        var levelEndPass: Int?
        /// Levels started changed: the next sector's level start ran (or, after sector 12, level `none`).
        var crossed = false
        var levelEndingBefore = false
        var failure: String?
        /// The units the direct start's level start spawned, before pass 1.
        var startSpawned = Set<FourCC>()
        /// The units spawned on passes 1… — this level's share of the crossing pass included.
        var laterSpawned = Set<FourCC>()
        /// Sectors 1–11: the units the next sector's level start spawned on the crossing pass.
        var nextStartSpawned = Set<FourCC>()
        var spawned: Set<FourCC> { startSpawned.union(laterSpawned) }
        var airWeapons = Set<FourCC>()
        var trace = ReplayTrace()
        var end: DeimosSession
        var startLevel: FourCC
    }

    /// The pass bound of each direct-start sector run. The plan's 16,000 was an estimate made before any run was
    /// measured; sector 11 (`le10`) is not stuck but long — five scroll pauses of about 2,500–3,200 passes each — and
    /// measured its level end at pass 17,216 (passive) / 17,149 (scripted), crossing at 17,613 / 17,573. Ruled up to
    /// 20,000 for every sector by the seat on 2026-11-15.
    static let sectorBound = 20_000

    static func runSector(_ sector: Int, pilot: Pilot, bound: Int = sectorBound) throws -> SectorRun {
        var s = try session(sector: sector, players: 1)
        var r = SectorRun(end: s, startLevel: s.level)
        newUnits(s.game, from: EntityWorld.firstSerial, into: &r.startSpawned)    // the level start's own spawns
        let started = s.game.flags.levelsStarted
        while r.passes < bound {
            r.levelEndingBefore = s.game.flags.levelEnding
            let first = s.game.world.nextSerial
            let out = step(&s, pilot, pass: r.passes, players: 1)
            r.passes += 1
            r.trace.record(s)
            if r.levelEndPass == nil && s.game.flags.levelEnding { r.levelEndPass = r.passes }
            if s.game.flags.levelsStarted != started {                   // the crossing
                r.crossed = true
                if s.game.flags.level == .none {                         // after sector 12: no pool reset (`levelStart`)
                    newUnits(s.game, from: first, into: &r.laterSpawned)
                } else if !crossingUnits(s.game, from: first, level: &r.laterSpawned, nextLevel: &r.nextStartSpawned) {
                    r.failure = "the crossing pass's serials overlap (next \(s.game.world.nextSerial) > \(first)): "
                        + "its spawns cannot be told apart by level"
                }
                break
            }
            r.airWeapons.insert(s.players[0].handler.air.id)
            newUnits(s.game, from: first, into: &r.laterSpawned)
            if out.sessionEnded {
                r.failure = "the session ended at pass \(r.passes): \(why(s))"
                break
            }
        }
        if !r.crossed && r.failure == nil { r.failure = "bound: still in the level after \(bound) passes" }
        r.end = s
        return r
    }

    // MARK: - Tests

    /// Sectors 1–12, each from a direct start (one life, that sector's weapons), with the passive and the scripted
    /// pilot; bound `sectorBound` (20,000) passes each. Each run reaches its level end (G+0x39) and crosses: sectors 1–11 into the
    /// next sector's level (levels started 2, game time 1, the trace's sector column moving on), sector 12 to the
    /// campaign's end (level `none`, the session over, no "all levels" flag — only one level was started). Every unit
    /// the run spawned is in the level's closure — the crossing pass's spawns included, this level's in its closure and
    /// the next level start's in the next sector's — and the run spawned at least one kind of unit in play that the
    /// level does not place, that is not common (`Census.common`: notices, the player's units) and that its start did
    /// not spawn. From sector 5 on, the scripted pilot's Select cycles the three air weapons the sector allows and the
    /// Photon Beam's power-up releases (`pbps`). Recorded (printed, not asserted) per run: the level-end pass, the
    /// tally's length (level end to crossing, in passes), those units spawned in play, the next level start's units,
    /// and the closure's units the run never spawned.
    func testEverySectorReachesItsEnd() throws {
        let census = try Census.shared.get()
        let photon = FourCC("aipb")!
        var table: [String] = []

        // The census's word filter, on two cases read from the data. The unit `bgpo` names `icpo` as a SOUND
        // (`#stateEntrySound_ID <icpo>`), and `icpo` is also a unit's tag; the iris unit `miac` (placed by sector 12)
        // names `cair` as a SPRITE FACE, and `cair` is also a unit's tag. Neither reference may pull its tag into a
        // closure: `bgpo` and `miac` are in sector 12's closure, `icpo` and `cair` are not — and `icpo` is in a closure
        // (sectors 1–3) exactly where a unit reference (a unit key, a placement, a weapon) puts it there.
        let bgpo = FourCC("bgpo")!, icpo = FourCC("icpo")!, miac = FourCC("miac")!, cair = FourCC("cair")!
        for (unit, line, tag) in [(bgpo, "#stateEntrySound_ID <icpo>", icpo), (miac, "#stateSpriteFace_ID <cair>", cair)] {
            let text = try CampaignTestData.text(type: "unde", id: unit)
            let key = Array(line.utf8)
            XCTAssertTrue(text.indices.contains { text[$0...].starts(with: key) }, "\(unit)'s definition holds \(line)")
            XCTAssertTrue(census.units.contains(tag), "\(tag) is also a unit")
            XCTAssertFalse(Census.unitIDs(in: text, census.units).contains(tag), "\(unit): \(line) is not a unit reference")
            XCTAssertTrue(census.closure(sector: 12).contains(unit), "\(unit) in sector 12's closure")
            XCTAssertFalse(census.closure(sector: 12).contains(tag), "\(tag) not in sector 12's closure")
        }
        let icpoSectors = (1...12).filter { census.closure(sector: $0).contains(icpo) }
        XCTAssertEqual(icpoSectors, [1, 2, 3], "icpo's closures")
        for sector in 1...12 {
            let c = census.closure(sector: sector)
            let referred = (census.placed[sector] ?? []).contains(icpo) || census.common.contains(icpo)
                || c.contains { census.refs[$0]?.contains(icpo) ?? false }
                || census.weapons.contains { $0.min <= Int32(sector) && Int32(sector) <= $0.max && $0.refs.contains(icpo) }
            XCTAssertEqual(c.contains(icpo), referred, "sector \(sector): icpo in the closure iff a unit reference puts it")
        }

        for sector in 1...12 {
            let closure = census.closure(sector: sector)
            let placed = census.placed[sector] ?? []
            XCTAssertLessThan(closure.count, census.units.count, "sector \(sector): the closure is not every unit")
            // Every tag the level places names a unit definition (the closure would otherwise drop it silently).
            XCTAssertFalse(placed.isEmpty, "sector \(sector) places units")
            XCTAssertTrue(placed.isSubset(of: census.units), "sector \(sector) places tags with no unit definition: "
                          + "\(placed.subtracting(census.units).map(\.description).sorted())")
            for pilot in Pilot.allCases {
                let name = "sector \(sector) \(pilot)"
                let r = try Self.runSector(sector, pilot: pilot)
                // Spawned during play, by the level's own units: not placed, not common (the notices, the player's
                // own units), not already spawned by the level start.
                let newKinds = r.laterSpawned.subtracting(placed).subtracting(census.common).subtracting(r.startSpawned)
                table.append("\(name): level end at pass \(r.levelEndPass.map(String.init) ?? "-"), crossed at "
                             + "\(r.crossed ? String(r.passes) : "-"), tally \(r.levelEndPass.map { String(r.passes - $0) } ?? "-")"
                             + " passes; spawned \(r.spawned.count) of a closure of "
                             + "\(closure.count); air weapons \(r.airWeapons.map(\.description).sorted()); pb "
                             + "\(r.spawned.filter { $0.description.hasPrefix("pb") }.map(\.description).sorted())"
                             + "\n    spawned in play, not placed or common: \(newKinds.map(\.description).sorted())"
                             + "\n    next level's start: \(r.nextStartSpawned.map(\.description).sorted())"
                             + "\n    closure minus spawned: \(closure.subtracting(r.spawned).map(\.description).sorted())")
                if let failure = r.failure {
                    XCTFail("\(name): \(failure); \(Self.dump(r.trace, name: name))")
                    continue
                }
                let s = r.end
                XCTAssertEqual(r.startLevel, Self.level(sector: sector), name)
                XCTAssertNotNil(r.levelEndPass, "\(name): G+0x39 never rose")
                XCTAssertEqual(s.game.flags.levelsStarted, 2, name)
                XCTAssertEqual(r.trace.rows.dropLast().map(\.sector), Array(repeating: Int32(sector), count: r.passes - 1),
                               name)
                if sector < 12 {
                    XCTAssertTrue(s.running, "\(name): a mid-game transition does not end the session")
                    XCTAssertEqual(s.sector, sector + 1, name)
                    XCTAssertEqual(s.level, Self.level(sector: sector + 1), name)
                    XCTAssertEqual(s.levelInfo.id, s.level, name)
                    XCTAssertEqual(s.gameTime, 1, name)
                    XCTAssertEqual(r.trace.rows.last?.sector, Int32(sector + 1), name)
                } else {
                    XCTAssertFalse(s.running, name)
                    XCTAssertEqual(s.level, .none, name)
                    XCTAssertFalse(s.game.flags.allLevels, name)
                    XCTAssertEqual(HeadlessRunner.reason(s, levelEndingBefore: r.levelEndingBefore), .campaignEnd, name)
                }
                XCTAssertFalse(r.spawned.isDisjoint(with: placed), "\(name): the census saw none of the level's placed units")
                XCTAssertFalse(newKinds.isEmpty, "\(name): the census saw no unit spawned in play that the level does "
                               + "not place (nor a common one)")
                let outside = r.spawned.subtracting(closure)
                XCTAssertTrue(outside.isEmpty, "\(name): spawned outside the level's closure: "
                              + "\(outside.map(\.description).sorted()); \(Self.dump(r.trace, name: name))")
                if sector < 12 {
                    let next = census.closure(sector: sector + 1)
                    XCTAssertFalse(r.nextStartSpawned.isEmpty, "\(name): the census saw nothing of the next level's start")
                    let outsideNext = r.nextStartSpawned.subtracting(next)
                    XCTAssertTrue(outsideNext.isEmpty, "\(name): the next level's start spawned outside sector "
                                  + "\(sector + 1)'s closure: \(outsideNext.map(\.description).sorted())")
                } else {
                    XCTAssertTrue(r.nextStartSpawned.isEmpty, name)
                }
                if pilot == .scripted && sector >= 5 {
                    // Select cycled the three air weapons sector 5 on allows, and the Photon Beam's power-up released.
                    XCTAssertEqual(r.airWeapons, [FourCC("aibg")!, FourCC("airg")!, photon], name)
                    XCTAssertTrue(r.spawned.contains(FourCC("pbps")!), "\(name): no Photon Beam release (pbps)")
                }
            }
        }
        print("CampaignSweep per sector:\n" + table.joined(separator: "\n"))
    }

    /// One scripted god-mode session from sector 1 to the finale; bound 150,000 passes. Wave 3.2's finale tests poke
    /// the scroll past sector 12's end fight; this run plays the fight out, but it reaches the finale by OUTLASTING the
    /// fight, not by winning it. Sector 12's end controller `12e1` holds the scroll until it enters its "Spawn
    /// Flippers" state for the fourth time — a timer path, the state's on-counter (`StateEntry.swift`, the
    /// `stateOnCounter` test, listing `10014dc8`). The Beamer `be02`'s death is only an early exit from that hold, and
    /// neither pilot takes it: `be02` is alive from about game time 10,376 through the level end and on into the
    /// finale (the level end deletes nothing, `10006da4`). The early exit by killing the Beamer is NOT exercised by
    /// this bundle; the run pins what it sees instead — `be02` alive on the pass the "all levels" notice is requested
    /// (G+0x0d rising, `10006e00..10006ee4`) — so a change in that behaviour is noticed. Eleven transitions start sectors 2…12 in order and the twelfth level start finds
    /// level `none`: levels started 13, the "all levels" flag G+0x0d (set at sector 12's level end, not before), the
    /// session over by the campaign end. Relative to T0 — the twelfth level's end, the first pass after which G+0x29
    /// stands — the finale keeps the ticks wave 3.2 pinned from its poked start (plan correction 1): `acbo` at T0 and
    /// T0+7 … T0+85 (fifteen), `leen` at T0+103, `12gc` live from T0+90 until its deletion on the pass at T0+955, the
    /// accuracy tally's 1 → 2 after the 1,200-tick wait at T0+1201.
    func testCampaignOneToTwelve() throws {
        let acbo = FourCC("acbo")!, leen = FourCC("leen")!, gc12 = FourCC("12gc")!, be02 = FourCC("be02")!
        var s = try Self.session(sector: 1, players: 1)
        var trace = ReplayTrace()
        var crossings: [(pass: Int, levelsStarted: Int32, sector: Int32, level: FourCC)] = []
        var passes = 0, levelEndingBefore = false, ended = false
        var t0: Int32?, t0Pass = 0, allLevelsBeforeT0 = false
        var acboAt: [Int32] = [], leenAt: [Int32] = [], gcAt: [Int32] = [], tallyTwoAt: Int32?
        var beamerFirstLive: Int32?, beamerAtAllLevels: Bool?
        while passes < 150_000 {
            let t = s.gameTime, started = s.game.flags.levelsStarted, tallyBefore = s.game.tally.state
            let allLevelsBefore = s.game.flags.allLevels
            levelEndingBefore = s.game.flags.levelEnding
            let out = Self.step(&s, .scripted, pass: passes, players: 1)
            passes += 1
            trace.record(s)
            let f = s.game.flags
            if f.levelsStarted != started { crossings.append((passes, f.levelsStarted, f.sector, f.level)) }
            if f.sector == 12 && f.levelsStarted == 12 {                 // the twelfth level, to the campaign end's pass
                if beamerFirstLive == nil && Self.isLive(s.game, be02) { beamerFirstLive = t }
                if !allLevelsBefore && f.allLevels { beamerAtAllLevels = Self.isLive(s.game, be02) }
                acboAt += out.sounds.filter { $0.id == acbo }.map { _ in t }
                leenAt += out.sounds.filter { $0.id == leen }.map { _ in t }
                if t0 == nil && f.levelEndHandled { (t0, t0Pass) = (t, passes) }
                if t0 != nil {
                    if Self.isLive(s.game, gc12) { gcAt.append(t) }
                    if tallyTwoAt == nil && tallyBefore == 1 && s.game.tally.state == 2 { tallyTwoAt = t }
                }
            }
            if t0 == nil && f.allLevels { allLevelsBeforeT0 = true }
            if out.sessionEnded {
                ended = true
                break
            }
        }
        print("CampaignSweep campaign: \(passes) passes; crossings at passes \(crossings.map(\.pass)); T0 = game time "
              + "\(t0.map(String.init) ?? "-") of the twelfth level, pass \(t0Pass); be02 first live at game time "
              + "\(beamerFirstLive.map(String.init) ?? "-"), live at the all-levels notice: "
              + "\(beamerAtAllLevels.map(String.init) ?? "-")")
        guard ended else {
            return XCTFail("bound: the campaign still runs after 150,000 passes (\(Self.why(s))); "
                           + Self.dump(trace, name: "campaign"))
        }
        let f = s.game.flags
        XCTAssertEqual(crossings.map(\.levelsStarted), Array(2...13), Self.dump(trace, name: "campaign"))
        XCTAssertEqual(crossings.map(\.sector), Array(2...12) + [12], "G+0x14 is not set after the none exit")
        XCTAssertEqual(crossings.dropLast().map(\.level), Array(Self.levels.dropFirst()))
        XCTAssertEqual(crossings.last?.level, FourCC.none)
        XCTAssertEqual(crossings.last?.pass, passes, "the last level start is the session's last pass")
        XCTAssertEqual(f.levelsStarted, 13)
        XCTAssertEqual(s.level, .none)
        XCTAssertFalse(s.running)
        XCTAssertTrue(f.allLevels, "G+0x0d")
        XCTAssertFalse(allLevelsBeforeT0, "G+0x0d rises at the twelfth level's end, not before")
        XCTAssertEqual(beamerAtAllLevels, true, "the Beamer be02 is alive when the all-levels notice is requested: the "
                       + "sweep outlasts sector 12's end fight, it does not win it")
        XCTAssertEqual(HeadlessRunner.reason(s, levelEndingBefore: levelEndingBefore), .campaignEnd)
        XCTAssertTrue(s.players[0].inGame, "god mode: the pilot never left the game")
        // The trace's sector column walks 1 → 12, one step at each crossing.
        var steps: [Int32] = []
        for (prev, row) in zip(trace.rows.map(\.sector).dropLast(), trace.rows.map(\.sector).dropFirst())
            where row != prev { steps.append(row) }
        XCTAssertEqual(trace.rows.first?.sector, 1)
        XCTAssertEqual(steps, Array(2...12))

        let t0v = try XCTUnwrap(t0, "the twelfth level never reached its end")
        // acbo: nothing else in the twelfth level plays it, so the list from the level's start is exactly the finale's.
        // leen: the iris mine projectile (`irmp`) plays it during the level's fight; from T0 on, only noal does.
        XCTAssertEqual(acboAt.map { $0 - t0v }, [0] + (Int32(1)...14).map { 6 * $0 + 1 }, "fifteen acbo: T0, T0+7 … T0+85")
        XCTAssertEqual(leenAt.filter { $0 >= t0v }.map { $0 - t0v }, [103])
        XCTAssertEqual(gcAt.first.map { $0 - t0v }, 90)
        XCTAssertEqual(gcAt.last.map { $0 - t0v }, 954, "12gc deleted on the pass at T0 + 955")
        XCTAssertEqual(gcAt.count, 955 - 90, "12gc live on every pass in between")
        XCTAssertEqual(tallyTwoAt.map { $0 - t0v }, 1201, "the 1,200-tick wait (flli 196), strict")
    }

    /// Two players from sector 1, player 1 flying `scriptA` on its keys and player 2 its own `scriptB` on its keys.
    ///
    /// First, whose keys move whom: three fresh copies of the session fly 2,000 passes each — both scripts; player 2's
    /// pad empty; the two scripts swapped. In every copy each player's controls, on every pass it flies, are exactly
    /// its own pad's script (bits pinned from the scripts and the prefs' key codes, not from the key table). Player
    /// 2's own state then differs exactly as its own keys say: with an empty pad it never moves off its start (x 312,
    /// three quarters of the 416-pixel field), never launches its air weapon and drops no ground shot; flying
    /// `scriptB` it first launches at pass 75, where `scriptB`'s fire window reopens after the ships appear (pass 56,
    /// where `scriptA` already holds fire), and drops 13 ground shots — `scriptA` on player 1 drops 14 — and the swapped
    /// copy turns both round (player 2: pass 56, 14 shots; player 1: pass 75, 13). Player 1's flight is the same with
    /// player 2's pad empty or not. Select cannot tell the pads apart here: sector 1 allows one air and one ground
    /// weapon (`aiic`, `plbo`), so there is nothing to cycle.
    ///
    /// Then the first copy flies on through the first transition; bound 16,000 passes. Both are still in the game at
    /// sector 2 and both had flown. The variant branches a copy of
    /// the session at pass 2,000 (a session is a plain value), takes player 2 out of the game as the life-state step
    /// leaves an eliminated player (`1002a264`: no lives, state 1, +0xc4 = 0, no shield) and plays the copy on with
    /// the same pilot: the game goes on with player 1 (`10006c3c..10006c7c`), crosses into sector 2, and player 2
    /// stays out — the level start leaves it untouched (`100269c4..100269cc`).
    func testTwoPlayerCampaignStart() throws {
        let le07 = Self.level(sector: 1), le06 = Self.level(sector: 2)
        var s = try Self.session(sector: 1, players: 2)
        XCTAssertEqual(s.game.flags.numPlayers, 2)
        XCTAssertTrue(s.players.allSatisfy(\.inGame))
        let branchAt = 2_000, bound = 16_000
        var variant: DeimosSession?
        var flew = [false, false]

        /// What each player did in the first `branchAt` passes of a fresh copy whose pad `i` flies `scripts[i]`.
        struct Seen {
            var controlsOff = [0, 0]                     // passes flown whose controls were not the pad's script
            var appeared = [false, false]
            var firstAirLaunch: [Int?] = [nil, nil]      // the pass (0-based) whose launch first moved +lastAirLaunch
            var groundShots = [0, 0]                     // passes that moved +lastBomb
            var x: [[Float]] = [[], []]
            var weapons: [Set<FourCC>] = [[], []]
        }
        func watch(_ scripts: [Script?], name: String) throws -> Seen {
            var c = try Self.session(sector: 1, players: 2), seen = Seen()
            for k in 0..<branchAt {
                let before = c.players.map { ($0.handler.lastAirLaunch, $0.handler.lastBomb) }
                Self.godMode(&c)
                if c.pass(keys: Self.keys(pass: k, scripts: scripts), ticks: 0).sessionEnded {
                    XCTFail("\(name): the session ended at pass \(k + 1): \(Self.why(c))")
                    break
                }
                for p in 0..<2 {
                    let pl = c.players[p]
                    seen.x[p].append(pl.object.x)
                    seen.weapons[p].formUnion([pl.handler.air.id, pl.handler.ground.id])
                    guard pl.lifeState == 4 else { continue }
                    seen.appeared[p] = true
                    if pl.input != (scripts[p]?.input(pass: k) ?? []) { seen.controlsOff[p] += 1 }
                    if seen.firstAirLaunch[p] == nil && pl.handler.lastAirLaunch != before[p].0 { seen.firstAirLaunch[p] = k }
                    if pl.handler.lastBomb != before[p].1 { seen.groundShots[p] += 1 }
                }
            }
            print("CampaignSweep two players, \(name): first air launch \(seen.firstAirLaunch), ground shots "
                  + "\(seen.groundShots), x at pass \(branchAt) \(seen.x.map { $0.last ?? .nan })")
            return seen
        }
        let both = try watch([Self.scriptA, Self.scriptB], name: "both scripts")
        let empty = try watch([Self.scriptA, nil], name: "player 2's pad empty")
        let swapped = try watch([Self.scriptB, Self.scriptA], name: "scripts swapped")
        for (name, seen) in [("both scripts", both), ("player 2's pad empty", empty), ("scripts swapped", swapped)] {
            XCTAssertEqual(seen.appeared, [true, true], "\(name): both ships appeared")
            XCTAssertEqual(seen.controlsOff, [0, 0], "\(name): each player's controls are its own pad's script")
            XCTAssertEqual(seen.weapons, [[FourCC("aiic")!, FourCC("plbo")!], [FourCC("aiic")!, FourCC("plbo")!]], name)
        }
        XCTAssertEqual(both.firstAirLaunch, [56, 75], "player 2 first fires where its own fire window reopens")
        XCTAssertEqual(swapped.firstAirLaunch, [75, 56])
        XCTAssertEqual(empty.firstAirLaunch, [56, nil], "an empty pad never fires")
        XCTAssertEqual(both.groundShots, [14, 13])
        XCTAssertEqual(swapped.groundShots, [13, 14])
        XCTAssertEqual(empty.groundShots, [14, 0])
        XCTAssertEqual(empty.x[1], Array(repeating: 312, count: branchAt), "an empty pad's ship never leaves its start")
        XCTAssertEqual(both.x[0], empty.x[0], "player 1 flies the same whatever player 2's pad holds")
        XCTAssertNotEqual(both.x[1], swapped.x[1], "player 2 flies its own script")
        XCTAssertEqual(both.x[1].last, 345.4001)
        XCTAssertEqual(swapped.x[1].last, 281.2002)

        /// Runs `s` from pass `k` to the crossing; nil, with a failure, at a session end or the bound.
        func runToCrossing(_ s: inout DeimosSession, from k: Int, name: String,
                           branch: ((Int, DeimosSession) -> Void)? = nil) -> Int? {
            var k = k, trace = ReplayTrace()
            let started = s.game.flags.levelsStarted
            while k < bound {
                branch?(k, s)
                let out = Self.step(&s, .scripted, pass: k, players: 2)
                k += 1
                trace.record(s)
                if s.game.flags.levelsStarted != started { return k }
                for i in 0..<2 where s.players[i].lifeState == 4 { flew[i] = true }
                if out.sessionEnded {
                    XCTFail("\(name): the session ended at pass \(k): \(Self.why(s)); \(Self.dump(trace, name: name))")
                    return nil
                }
            }
            XCTFail("\(name): bound: no crossing in \(bound) passes; \(Self.dump(trace, name: name))")
            return nil
        }

        let crossed = runToCrossing(&s, from: 0, name: "two players") { k, now in
            if k == branchAt { variant = now }
        }
        print("CampaignSweep two players: crossed at pass \(crossed.map(String.init) ?? "-")")
        guard crossed != nil else { return }
        XCTAssertEqual(flew, [true, true], "both ships flew")
        XCTAssertTrue(s.running)
        XCTAssertEqual(s.sector, 2)
        XCTAssertEqual(s.level, le06)
        XCTAssertEqual(s.game.flags.levelsStarted, 2)
        XCTAssertEqual(s.game.flags.numPlayers, 2)
        for i in 0..<2 {
            XCTAssertTrue(s.players[i].inGame, "player \(i + 1) in the game at sector 2")
            XCTAssertEqual(s.players[i].levelRef, le06, "player \(i + 1)'s level start ran")
            XCTAssertEqual(s.players[i].lifeState, 2, "player \(i + 1) waits to appear")
        }

        var v = try XCTUnwrap(variant, "no copy at pass \(branchAt)")
        XCTAssertTrue(v.players[1].inGame)
        v.game.players[1].lives = 0
        v.game.players[1].setLifeState(1, now: v.gameTime)
        v.game.players[1].inGame = false
        v.game.players[1].shield = 0
        let p2Score = v.players[1].score
        flew = [false, false]
        let vCrossed = runToCrossing(&v, from: branchAt, name: "two players, player 2 out")
        print("CampaignSweep two players, player 2 out: crossed at pass \(vCrossed.map(String.init) ?? "-")")
        guard vCrossed != nil else { return }
        XCTAssertEqual(flew, [true, false], "only player 1 flew after the branch")
        XCTAssertTrue(v.running, "the game goes on with player 1")
        XCTAssertEqual(v.sector, 2)
        XCTAssertEqual(v.level, le06)
        XCTAssertTrue(v.players[0].inGame)
        XCTAssertEqual(v.players[0].levelRef, le06)
        XCTAssertEqual(v.players[0].lifeState, 2)
        XCTAssertFalse(v.players[1].inGame, "player 2 stays out")
        XCTAssertEqual(v.players[1].levelRef, le07, "no level start for an out player")
        XCTAssertEqual(v.players[1].lifeState, 1)
        XCTAssertEqual(v.players[1].lives, 0)
        XCTAssertEqual(v.players[1].score, p2Score, "an out player scores nothing")
    }
}
