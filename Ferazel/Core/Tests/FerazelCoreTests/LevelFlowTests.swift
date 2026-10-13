import XCTest
@testable import FerazelCore

/// W4 (docs/plans/2026-10-10-ferazel-phase2.md): the level-2 Setups Phase 1 never transcribed, the level exit 3249
/// (`.HitPlayerSprite` M l. 49733–49741) → ◇ `LevelFlow` (`Mmap 200`, world-data §4.2; the Phase-2 mapping, D33), and
/// game over → `ShellRequest.deathEffect` → `deathEffectDone()` → restart with fresh globals (D33), against the
/// committed `Resources/Ferazel` (D26). A missing data file is a FAILURE, never a skip.
final class LevelFlowTests: XCTestCase {

    private func resources() throws -> FerazelResources { try FerazelData.open(try FerazelData.dataDirectory()) }

    /// Puts the player so that his feet (`y + 0x55`) are 4 px below `top`, his rect's x span over `x`, moving down at
    /// `vy` (as `BoxRopeTests.dropPlayer`).
    private func dropPlayer(_ w: SpriteWorld, _ p: Int, ontoTop top: Int, x: Int, vy: Int32) {
        let r = HandleKeys.standardHotRect
        w.active.update(id: p) { s in
            s.x = x - r.left - 4
            s.y = top + 4 - r.bottom
            s.x256 = Int32(s.x) << 8
            s.y256 = Int32(s.y) << 8
            s.vx = 0
            s.vy = vy
            s.groundKind = 0
            s.ridden = nil
            s.centre = SpriteSlot.Point(x: s.x + 0x32, y: s.y + 0x3b)
        }
    }

    /// Inserts the level exit of record `rec` (its Setup) and puts the player inside its rect, then runs the player
    /// pass's contact (`HitPlayerSprite.hit`).
    private func touchExit(_ s: FerazelSession, record rec: Int) throws {
        let c = SetupFaces.Context(level: s.level, playerX: 0)
        let e = try SetupFaces.setup(s.level.placements[rec], context: c)
        let exit = s.world.active.insert(e.slot)
        let pid = try XCTUnwrap(s.world.playerID)
        s.world.active.update(id: pid) { $0.x = e.slot.x; $0.y = e.slot.y }
        HitPlayerSprite.hit(s.world, player: pid, other: exit)
    }

    func testLevel2SessionBuilds() throws {
        let r = try resources()
        let L = try LevelFile.load(from: r, level: 2)
        XCTAssertEqual(L.activePlacements.count, 212)
        let s = try FerazelSession(resources: r, prefs: FerazelPrefs(), level: 2)
        XCTAssertEqual(try SetupFaces.spawnLevelSprites(context: SetupFaces.Context(level: L, playerX: 0)) { _ in .noFace }
            .created.count, 212)
        XCTAssertEqual(s.idle.entries.compactMap { $0 }.count, 196)
        // The platforms are faceless and spoke-less until their first Handle (W1): 40 spokes + 4 siblings after it.
        XCTAssertEqual(s.active.sprites.filter { $0.type == 0x596 }.count, 0)
        _ = s.step(keys: KeyState())
        XCTAssertEqual(s.active.sprites.filter { $0.handler == .chain && $0.type == 0x596 }.count, 40)
        XCTAssertEqual(s.active.sprites.filter { $0.handler == .platform && $0.recordIndex == -1 }.count, 4)

        // One record per new type (Setup face, rect, layer, fields), with the session stream's draws in order.
        let c = SetupFaces.Context(level: L, playerX: SetupFaces.Context.levelStartPlayerX(L.header))
        func setup(_ rec: Int, seed: Int32 = 1) throws -> (SetupFaces.Entry, FastRand) {
            var rng = FastRand(seed: seed)
            let e = try SetupFaces.setup(L.placements[rec], context: c, rng: &rng)
            return (e, rng)
        }
        func f(_ pict: Int16, _ i: Int = 0) -> FaceRef { FaceRef(pict: pict, index: i, set: .encoded) }
        func rect(_ l: Int, _ t: Int, _ rr: Int, _ b: Int) -> IdleSprites.Rect {
            IdleSprites.Rect(top: t, left: l, bottom: b, right: rr)
        }
        var x = FastRand(seed: 1)

        // 1056 (rec 175): the 0x41f arm — R(0x13) → +0x46, R(6) + 0x1c, R(3) + 2, then the tail's R(0x3c); light 0x2c.
        var (e, rng) = try setup(175)
        XCTAssertEqual(L.placements[175].type, 1056)
        XCTAssertEqual([e.slot.phase, e.slot.slip, e.slot.friction], [x.next(0x13), x.next(6) + 0x1c, x.next(3) + 2])
        XCTAssertEqual(e.slot.classTimer, Int32(x.next(0x3c)))
        XCTAssertEqual(rng.seed, x.seed)
        XCTAssertEqual([e.slot.face, e.source == .handle ? e.slot.face : nil], [f(0x421), f(0x421)])
        XCTAssertEqual(e.light, SetupFaces.Light(pict: 0x336, width: 0x34, height: 0x34, x: 4335 + 0x10, y: 740 + 0x10,
                                                 colour: 0x2c))
        XCTAssertFalse(e.slot.lightOverlay)
        // The light is gated on prefs +6 (Effects) == 1 (M l. 52452): Effects 2 → no light, the same draws.
        var r2 = FastRand(seed: 1)
        let e2 = try SetupFaces.setup(L.placements[175], context: SetupFaces.Context(level: L, playerX: c.playerX,
                                                                                    effects: 2), rng: &r2)
        XCTAssertNil(e2.light)
        XCTAssertEqual(r2.seed, x.seed)
        // 1058 (rec 228): faceless trigger, SetRect(0, 0, 0x60, 0x60) (M l. 52472), the tail's draw only.
        x = FastRand(seed: 1)
        (e, rng) = try setup(228)
        XCTAssertEqual([e.source == .none, e.slot.face == nil, e.slot.lightOverlay, e.light == nil], [true, true, false, true])
        XCTAssertEqual(e.slot.hotRect, rect(0, 0, 0x60, 0x60))
        XCTAssertEqual(e.slot.classTimer, Int32(x.next(0x3c)))
        XCTAssertEqual(rng.seed, x.seed)
        // 1332 (rec 206, sphere): R(0x10) → +0x46 after its light (99), tail R(0x3c).
        x = FastRand(seed: 1)
        (e, rng) = try setup(206)
        XCTAssertEqual([e.slot.phase, Int16(e.slot.classTimer)], [x.next(0x10), x.next(0x3c)])
        XCTAssertEqual([e.slot.face, e.light?.colour == 99 ? f(0x534) : nil], [f(0x534), f(0x534)])
        XCTAssertEqual(rng.seed, x.seed)
        // 1341 (rec 187): ungated light 0x32a at (x + 0x16, y + 0x14) colour 0x21, R(0x10) → +0x15c, tail.
        for seed in [0x2c1b1519, 0x7fff_1234] + Array(Int32(1)...32) {
            x = FastRand(seed: seed)
            (e, rng) = try setup(187, seed: seed)
            XCTAssertEqual([e.slot.classWord15c, e.slot.classTimer], [Int32(x.next(0x10)), Int32(x.next(0x3c))],
                           "seed \(seed)")
            XCTAssertEqual(rng.seed, x.seed, "seed \(seed)")
        }
        x = FastRand(seed: 1)
        (e, rng) = try setup(187)
        XCTAssertEqual(e.light, SetupFaces.Light(pict: 0x32a, width: 0x48, height: 0x48, x: 431 + 0x16, y: 484 + 0x14,
                                                 colour: 0x21))
        XCTAssertEqual([e.slot.classWord15c, e.slot.classTimer, Int32(e.slot.phase)],
                       [Int32(x.next(0x10)), Int32(x.next(0x3c)), 0])
        XCTAssertEqual([e.slot.face, e.sheet.map { f($0.pict) }], [f(0x53d), f(0x53d)])
        XCTAssertEqual(e.sheet?.count, 6)
        XCTAssertEqual(e.sheet?.cellWidth, 0x2c)
        // 3205 (rec 78, item): R(0x10) → +0x46 before the light (99), tail.
        x = FastRand(seed: 1)
        (e, rng) = try setup(78)
        XCTAssertEqual([e.slot.phase, Int16(e.slot.classTimer)], [x.next(0x10), x.next(0x3c)])
        XCTAssertEqual([e.slot.face], [f(0xc85)])
        XCTAssertEqual(e.source, .setup)
        // 1740 (rec 186, bat): no draw; layer 0xb, HP 500, rect, Handle face set 0x6cc (11 × 0x38×0x34, clut 200).
        (e, rng) = try setup(186)
        XCTAssertEqual(rng.seed, 1)
        XCTAssertEqual([Int(e.slot.layer), Int(e.slot.hp), Int(e.slot.classWord150), Int(e.slot.classWord158)],
                       [0xb, 500, -1, 0x1e])
        XCTAssertEqual([Int(e.slot.subtype), Int(e.slot.gravity)], [7, 0])           // `+0xb0 = 7` (M l. 68310)
        XCTAssertEqual(e.slot.hotRect, rect(0xc, 0xf, 0x2b, 0x2f))
        XCTAssertEqual([e.slot.face], [f(0x6cc)])
        XCTAssertEqual([e.source == .handle, e.slot.handler == .inert], [true, true])
        XCTAssertEqual([e.sheet?.count, e.sheet?.cellWidth, e.sheet?.cellHeight, Int(e.sheet?.clut ?? 0)],
                       [0xb, 0x38, 0x34, 200])
        // 1800 (rec 173, frog): R(0x1e) → +0x14c = −0x14 − r, then R(0x5fff) → +0xf0; p1 0 → HP 0x15e, `+0xb8` 0.
        for seed: Int32 in [1, 0x2c1b1519, 0x7fff_1234] {
            x = FastRand(seed: seed)
            (e, rng) = try setup(173, seed: seed)
            XCTAssertEqual(e.slot.classTimer, -0x14 - Int32(x.next(0x1e)), "seed \(seed)")
            XCTAssertEqual(e.slot.voicePitch, Int32(x.next(0x5fff)) * 2 + 0xbfff, "seed \(seed)")
            XCTAssertEqual(rng.seed, x.seed)
        }
        XCTAssertEqual([Int(e.slot.layer), Int(e.slot.hp), Int(e.slot.mode), Int(e.slot.classWord15c)], [0xb, 0x15e, 0, 0])
        // `+0xb0 = 0xb` (M l. 70171), gravity `+0x110 = 0x8c` (l. 70179).
        XCTAssertEqual([Int(e.slot.subtype), Int(e.slot.gravity)], [0xb, 0x8c])
        // The p1 tiers (l. 70185–70206) on synthetic placements of rec 173: `+0x15c` = p1, (HP, `+0xb8`).
        let frog = L.placements[173]
        for (p1, hp, mode) in [(Int16(1), 500, 0x1000c), (2, 0x15e, 0x10017), (3, 0x5dc, 0x1000f), (4, 1000, 0x1000b),
                               (5, 500, 0), (-1, 500, 0)] {
            let q = Placement(index: frog.index, flag: frog.flag, byte1: frog.byte1, type: frog.type, p1: p1,
                              p2: frog.p2, p3: frog.p3, p4: frog.p4, y: frog.y, x: frog.x)
            var fr = FastRand(seed: 1)
            let fe = try SetupFaces.setup(q, context: c, rng: &fr)
            XCTAssertEqual([Int(fe.slot.hp), Int(fe.slot.mode), Int(fe.slot.classWord15c)], [hp, mode, Int(p1)], "p1 \(p1)")
        }
        XCTAssertEqual(e.slot.hotRect, rect(0xb, 0x14, 0x48, 0x49))
        XCTAssertEqual([e.slot.face], [f(0x708)])
        XCTAssertEqual(e.source, .setupCached)
        XCTAssertEqual(L.header.inLiquid, 0)                       // `+0x8e` untouched
        // Box types (no draw): decorations 2848 / 2849 (p3 1 → layer 10000), the door left 2911 (set 0xb5e, mirrored),
        // furniture 2925 / 2926 / 2928, the NPC 2954.
        for (rec, face, src, layer, r0, oneWay) in [
            (17, f(0xb20), SetupFaces.FaceSource.setupCached, 10000, rect(0, 0, 0, 0), true),
            (211, f(0xb21), .setupCached, 10000, rect(0, 0, 0, 0), true),
            (212, f(0xb5e), .setup, 0, rect(0x24, -0x40, 0x3c, 0x98), false),
            (63, f(0xb6d), .handle, 0, rect(0xe, 0x17, 0x28, 0x28), true),
            (64, f(0xb6e), .handle, 0, rect(6, 0, 0x37, 0x20), false),
            (48, f(0xb70), .handle, 0, rect(3, 5, 0x4d, 0x20), false),
            (188, f(0xb8a), .handle, 0, rect(0, 0, 0, 0), true),
        ] {
            (e, rng) = try setup(rec)
            XCTAssertEqual(rng.seed, 1, "rec \(rec)")
            XCTAssertEqual(e.slot.face, face, "rec \(rec)")
            XCTAssertEqual(e.source, src, "rec \(rec)")
            XCTAssertEqual(Int(e.slot.layer), layer, "rec \(rec)")
            XCTAssertEqual(e.slot.hotRect, r0, "rec \(rec)")
            XCTAssertEqual(e.slot.oneWay, oneWay, "rec \(rec)")
            XCTAssertEqual(e.slot.handler, .box, "rec \(rec)")
        }
        XCTAssertTrue(try setup(212).0.slot.mirrored)
        // Stalactites 2932 (recs 158–160): the parent (set 0xb75 cell p1, one-way, rect (9, 10, 0x18, 0x2a), HP 0x96,
        // `+0x14c` 0x40, `+0x150` 100, `+0x154` = x) goes idle; its Setup-time child (record −1, layer 1, set 0xb74
        // cell p1, no hit) is active from the start, linked from the parent's `+0x1d4`.
        let kids = s.active.sprites.filter { $0.type == 0xb74 }
        XCTAssertEqual(kids.count, 3)
        let parents = s.idle.entries.compactMap { $0 }.filter { $0.saved.type == 0xb74 }.map(\.saved)
        XCTAssertEqual(parents.map(\.recordIndex), [158, 159, 160])
        XCTAssertEqual(parents.map(\.siblings.first), kids.map(\.id))
        for (k, p) in zip(kids, parents) {
            XCTAssertEqual([k.recordIndex, Int16(k.layer), k.gravity], [-1, 1, 0])
            XCTAssertEqual([k.hasHit, k.hasTileHit, k.oneWay], [false, false, false])
            XCTAssertEqual([k.face], [f(0xb74)])
            XCTAssertEqual([k.x, k.y], [p.x, p.y])
            XCTAssertEqual(k.handler, .box)
            XCTAssertEqual([p.face], [f(0xb75)])
            XCTAssertEqual(p.hotRect, rect(9, 10, 0x18, 0x2a))
            XCTAssertEqual([Int(p.hp), Int(p.classTimer), Int(p.classWord150), Int(p.classWord154), Int(p.layer)],
                           [0x96, 0x40, 100, p.x, 2])
            XCTAssertTrue(p.oneWay)
        }
        XCTAssertEqual(parents.map(\.x), [3492, 3581, 3668])
        XCTAssertTrue(SetupFaces.boxChildSheets.contains { $0.pict == 0xb74 && $0.count == 0xc && $0.cellHeight == 0x14 })

        // W3 review carry: the NPC arm (M l. 49199–49210) returns before `.PlatformBounce` — never solid, even with a
        // rect the player lands in (L1 rec 157, type 2951).
        let L1 = try LevelFile.load(from: r, level: 1)
        let w = SpriteWorld(level: L1)
        let pid = try XCTUnwrap(Player.spawn(world: w, x: 2000, y: 1000))
        w.playerID = pid
        XCTAssertEqual(L1.placements[157].type, 2951)
        var npcSlot = try SetupFaces.setup(L1.placements[157], context: SetupFaces.Context(level: L1, playerX: 0)).slot
        npcSlot.hotRect = rect(0, 0, 0x40, 0x30)
        let npc = w.active.insert(npcSlot)
        dropPlayer(w, pid, ontoTop: npcSlot.y, x: npcSlot.x, vy: 0x400)
        HitPlayerSprite.hit(w, player: pid, other: npc)
        let ps = try XCTUnwrap(w.active.sprite(id: pid))
        XCTAssertNil(ps.ridden)
        XCTAssertEqual([ps.vy, Int32(ps.groundKind)], [0x400, 0])
    }

    func testLevel2Header() throws {
        let L = try LevelFile.load(from: try resources(), level: 2)
        XCTAssertEqual([L.header.patternPict, L.header.music, L.header.startX, L.header.startY, L.header.chapter],
                       [509, 3, 901, 256, 0])
        XCTAssertNotEqual(L.header.patternPeriodSix, 0)              // 6×6
        XCTAssertEqual(L.header.mapNodeLevel, 2)
        XCTAssertEqual(L.header.autoScrollEnable, 0)
        // The session's level start plays music 3 at full volume (the Phase-1 cue; the fade-in stays a Phase-3 carry).
        let s = try FerazelSession(resources: try resources(), prefs: FerazelPrefs(), level: 2)
        XCTAssertEqual(s.step(keys: KeyState()).music, [.play(track: 3)])
        XCTAssertEqual(s.levelNumber, 2)
    }

    func testLevel1ExitLeadsTo2() throws {
        let r = try resources()
        let map = try WorldMap.load(from: r)
        let L1 = try LevelFile.load(from: r, level: 1)
        let rec = L1.placements[66]
        XCTAssertEqual([rec.type, rec.p1, rec.p2], [3249, 0, 0])
        XCTAssertEqual(map.nodes.first { $0.level == 1 }?.index, 1)
        XCTAssertEqual(map.nodes.first { $0.index == 1 }?.links.first, 2)
        XCTAssertEqual(LevelFlow.next(level: 1, exit: 0, map: map), 2)
        XCTAssertEqual(LevelFlow.exitRequest(level: 1, exit: 0, map: map, current: 1), .loadLevel(2))

        // Through the session: the exit's rect (12, 12, 84, 84); the arm's cue 421 (no draw), exit index p1, level
        // complete — the loop ends after the iteration → `.loadLevel(2)`, once.
        let s = try FerazelSession(resources: r, prefs: FerazelPrefs(), level: 1)
        _ = s.step(keys: KeyState())
        s.world.globals.crunchLog.append(CrunchLogEntry(level: 1, col: 7, row: 9))
        // Non-default G for the carry below (G+4 follows the player's HP at the Handle's tail).
        s.world.active.update(id: try XCTUnwrap(s.world.playerID)) { $0.hp = 333 }
        s.world.globals.magic = 211
        s.world.globals.coins = 17
        s.world.globals.score = 4321
        s.world.globals.breath = 300
        s.world.globals.xichrons = 2
        s.world.globals.selectedSlot = 1
        s.world.globals.startFacing = 7
        let e = try SetupFaces.setup(rec, context: SetupFaces.Context(level: L1, playerX: 0))
        XCTAssertEqual(e.slot.hotRect, IdleSprites.Rect(top: 0xc, left: 0xc, bottom: 0x54, right: 0x54))
        XCTAssertNil(e.slot.face)
        let seed = s.rngSeed
        s.world.player.cues = []
        try touchExit(s, record: 66)
        XCTAssertEqual(s.rngSeed, seed)
        XCTAssertEqual(s.player.cues, [PlayerCue(call: .reg, snd: 421, priority: 1, volume: 0x100)])
        XCTAssertEqual([s.player.exitIndex, s.player.exit2], [0, -1])
        XCTAssertTrue(s.player.levelDone)
        XCTAssertNil(s.ended)
        let ops = s.step(keys: KeyState())
        XCTAssertEqual(ops.requests, [.loadLevel(2)])
        XCTAssertEqual(s.ended, .loadLevel(2))
        XCTAssertFalse(s.world.playerDead)
        XCTAssertFalse(s.step(keys: KeyState()).requests.contains(.loadLevel(2)))   // emitted once

        // The carry (P3 carries): the parity and the crunch log run on into level 2 — and the whole of G: only
        // `.NewGame` calls `.InitGameGlobals` (M l. 5747), the next-level loop (l. 5815–5836) re-writes only `+0x16`
        // (the start facing, l. 5821) and `.SetupLevel` only `+0x20`/`+0x22`/`+0x176` (not modelled).
        let carry = s.carry
        XCTAssertEqual(carry, LevelCarry(parity: s.world.parity, crunchLog: [CrunchLogEntry(level: 1, col: 7, row: 9)],
                                         globals: s.globals))
        XCTAssertEqual([s.globals.health, s.globals.magic, s.globals.coins], [333, 211, 17])
        let next = try FerazelSession(resources: r, prefs: FerazelPrefs(), level: 2, seed: s.rngSeed, carry: carry)
        var expected = s.globals
        expected.startFacing = Int16(next.level.header.startFacingLeft)
        XCTAssertEqual(next.globals, expected)
        XCTAssertEqual([next.globals.score, Int32(next.globals.xichrons), Int32(next.globals.selectedSlot)], [4321, 2, 1])
        XCTAssertNotEqual(next.globals.startFacing, 7)
        let np = try XCTUnwrap(next.world.playerID.flatMap { next.active.sprite(id: $0) })
        XCTAssertEqual(np.hp, 333)                                     // `.SetupPlayerSprite`: `+0xa4 = G+4`
        XCTAssertEqual(next.carry.globals, expected)

        // The exit touched inside the iteration's player pass: the arm's cue 421 is handed out with that (last)
        // iteration — the Sound Tool starts it at once — after the Handle pass's cues.
        let t = try FerazelSession(resources: r, prefs: FerazelPrefs(), level: 1)
        _ = t.step(keys: KeyState())
        // The player is put on rec 66; its idle entry wakes inside the iteration (`.HandleIdleSprites`).
        let tp = try XCTUnwrap(t.world.playerID)
        t.world.active.update(id: tp) { $0.x = e.slot.x; $0.y = e.slot.y; $0.x256 = Int32(e.slot.x) << 8
            $0.y256 = Int32(e.slot.y) << 8 }
        XCTAssertEqual(t.step(keys: KeyState()).requests, [.loadLevel(2)])
        XCTAssertEqual(t.active.sprites.filter { $0.type == HitPlayerSprite.levelExit }.map(\.recordIndex), [66])
        XCTAssertEqual(t.frameCues.last, PlayerCue(call: .reg, snd: 421, priority: 1, volume: 0x100))
        XCTAssertEqual(t.frameCues.filter { $0.snd == 421 }.count, 1, "\(t.frameCues)")
        XCTAssertTrue(t.player.cues.isEmpty)
        for parity in [false, true] {
            let n = try FerazelSession(resources: r, prefs: FerazelPrefs(), level: 2, seed: s.rngSeed,
                                       carry: LevelCarry(parity: parity, crunchLog: carry.crunchLog))
            XCTAssertEqual(n.world.parity, parity)
            XCTAssertEqual(n.globals.crunchLog, carry.crunchLog)
            XCTAssertEqual(n.carry.parity, parity)
        }
    }

    func testLevel2ExitsUnlock() throws {
        let r = try resources()
        let map = try WorldMap.load(from: r)
        XCTAssertEqual(map.nodes.first { $0.index == 2 }?.links, [1, 3, 4, 0, 0, 0, 0])
        XCTAssertNil(LevelFlow.next(level: 2, exit: -1, map: map))
        XCTAssertEqual(LevelFlow.next(level: 2, exit: 0, map: map), 1)
        XCTAssertEqual(LevelFlow.next(level: 2, exit: 1, map: map), 3)
        XCTAssertEqual(LevelFlow.next(level: 2, exit: 2, map: map), 4)
        XCTAssertNil(LevelFlow.next(level: 2, exit: 3, map: map))        // link 0 = none
        XCTAssertNil(LevelFlow.next(level: 2, exit: 7, map: map))        // past the seven links
        XCTAssertNil(LevelFlow.next(level: 99, exit: 0, map: map))       // no node
        // The Phase-2 mapping (D33): 1 and 2 load; 3, 4 and no target restart the current level.
        XCTAssertEqual(LevelFlow.phase2Level(next: 3, current: 2), 2)
        XCTAssertEqual(LevelFlow.phase2Level(next: 4, current: 2), 2)
        XCTAssertEqual(LevelFlow.phase2Level(next: nil, current: 2), 2)
        XCTAssertEqual(LevelFlow.phase2Level(next: 1, current: 2), 1)
        XCTAssertEqual(LevelFlow.phase2Level(next: 2, current: 1), 2)
        XCTAssertEqual(LevelFlow.phase2Level(next: 0, current: 1), 1)

        // Level 2's three exits through the session: recs 0 (p1 −1), 39 (1 → 3), 98 (2 → 4) all restart level 2.
        let L2 = try LevelFile.load(from: r, level: 2)
        for (rec, p1) in [(0, Int16(-1)), (39, 1), (98, 2)] {
            XCTAssertEqual([L2.placements[rec].type, L2.placements[rec].p1], [3249, p1])
            let s = try FerazelSession(resources: r, prefs: FerazelPrefs(), level: 2)
            _ = s.step(keys: KeyState())
            try touchExit(s, record: rec)
            XCTAssertEqual(s.player.exitIndex, p1)
            XCTAssertEqual(s.step(keys: KeyState()).requests, [.loadLevel(2)], "rec \(rec)")
        }
    }

    func testDeathRequestsWipeThenRestart() throws {
        let r = try resources()
        let s = try FerazelSession(resources: r, prefs: FerazelPrefs(), level: 1)
        _ = s.step(keys: KeyState())
        let pid = try XCTUnwrap(s.world.playerID)
        s.world.active.update(id: pid) { $0.hp = 0 }
        // The dying arm runs until it sets the game-over flag (P4); the iteration that sets it ends the loop with
        // G+4 < 1 → `*_DAT_1009ffa8 = 1` and `.deathEffect`, once; nothing earlier.
        var frames = 0
        while !s.player.gameOver && frames < 200 {
            let ops = s.step(keys: KeyState())
            frames += 1
            if s.player.gameOver {
                XCTAssertEqual(ops.requests, [.deathEffect])
                XCTAssertLessThan(s.globals.health, 1)
                XCTAssertTrue(s.world.playerDead)
            } else {
                XCTAssertTrue(ops.requests.isEmpty, "frame \(frames)")
                XCTAssertFalse(s.world.playerDead)
            }
        }
        XCTAssertTrue(s.player.gameOver)
        XCTAssertEqual(s.ended, .deathEffect)
        XCTAssertTrue(s.step(keys: KeyState()).requests.isEmpty)
        // The shell reports the wipe's end → the current level again.
        XCTAssertEqual(s.deathEffectDone(), .loadLevel(1))
        let l2 = try FerazelSession(resources: r, prefs: FerazelPrefs(), level: 2)
        XCTAssertEqual(l2.deathEffectDone(), .loadLevel(2))
        // Death wins over a completed level (G+4 < 1 is tested first, l. 5302).
        let both = try FerazelSession(resources: r, prefs: FerazelPrefs(), level: 1)
        _ = both.step(keys: KeyState())
        both.world.player.levelDone = true
        both.world.active.update(id: try XCTUnwrap(both.world.playerID)) { $0.hp = 0 }
        XCTAssertEqual(both.step(keys: KeyState()).requests, [.deathEffect])
    }

    func testRestartFreshGlobals() throws {
        let r = try resources()
        let s = try FerazelSession(resources: r, prefs: FerazelPrefs(), level: 1)
        for _ in 0..<5 { _ = s.step(keys: KeyState()) }
        s.world.globals.magic = 3
        s.world.globals.breath = 7
        s.world.globals.coins = 9
        s.world.globals.score = 55
        s.world.globals.crunchLog = [CrunchLogEntry(level: 1, col: 1, row: 2)]
        // The death path: HP 0 → the dying arm → game over → `.deathEffect`; the shell's wipe ends → restart.
        s.world.active.update(id: try XCTUnwrap(s.world.playerID)) { $0.hp = 0 }
        var frames = 0
        while s.ended == nil && frames < 200 { _ = s.step(keys: KeyState()); frames += 1 }
        XCTAssertEqual(s.ended, .deathEffect)
        XCTAssertLessThan(s.globals.health, 1)
        s.world.parity = true
        XCTAssertEqual(s.carry.crunchLog.count, 1)
        XCTAssertNotNil(s.carry.globals)
        guard case .loadLevel(let n) = s.deathEffectDone() else { return XCTFail("no loadLevel") }
        XCTAssertEqual(n, 1)
        // Fresh G (D33): the crunch log goes with it; the parity is not G's and runs on.
        XCTAssertEqual(s.carry, LevelCarry(parity: true, crunchLog: []))
        XCTAssertNil(s.carry.globals)
        let fresh = try FerazelSession(resources: r, prefs: FerazelPrefs(), level: n, seed: s.rngSeed, carry: s.carry)
        XCTAssertEqual([fresh.globals.health, fresh.globals.magic, fresh.globals.breath], [560, 560, 560])
        XCTAssertEqual([fresh.globals.maxHealth, fresh.globals.maxMagic, fresh.globals.coins], [560, 560, 0])
        XCTAssertEqual(fresh.globals, GameGlobals(header: fresh.level.header))
        XCTAssertEqual(fresh.globals.crunchLog, [])
        XCTAssertTrue(fresh.world.parity)
        XCTAssertNil(fresh.ended)
        XCTAssertFalse(fresh.world.playerDead)
        XCTAssertFalse(fresh.player.gameOver)
        XCTAssertFalse(fresh.player.levelDone)
        let p = try XCTUnwrap(fresh.world.playerID.flatMap { fresh.active.sprite(id: $0) })
        let h = fresh.level.header
        // The start position (`.GameLoop(hdr+0x2848 − 0x20, hdr+0x2846 − 0x20, …)`): 24.8 and the spawn copy
        // (`+0xc`/`+0xa` keep `.MTNewSprite`'s quirk until the first separation).
        XCTAssertEqual([Int(p.x256 >> 8), Int(p.y256 >> 8)], [Int(h.startX) - 0x20, Int(h.startY) - 0x20])
        XCTAssertEqual([p.oldPosition.x, p.oldPosition.y], [Int(h.startX) - 0x20, Int(h.startY) - 0x20])
        XCTAssertEqual(p.hp, 560)
        // The stream continues from the dead session's state (A3 passes `rngSeed`).
        XCTAssertEqual(try FerazelSession(resources: r, prefs: FerazelPrefs(), level: 1, seed: s.rngSeed).seedAfterSetups,
                       fresh.seedAfterSetups)
    }
}
