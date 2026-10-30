import XCTest
import HectorResources
@testable import FerazelCore

/// BT (docs/plans/2026-10-24-ferazel-phase4.md): the Buttons 1320…1322 (`.SetupButtonSprite` / `.HandleButtonSprite` /
/// `.HitButtonSprite`, M l. 61703–61843), the gate 2940 (`.HandleBoxSprite` M l. 61016–61064), the switch blocks
/// 1250…1279 (M l. 61088–61113) and the boulder spouts 1450…1453 (M l. 60488–60547) on the records of levels 3 and 4,
/// over a synthetic empty grid (none of them reads a tile). Every expected draw is re-derived from a copy of the stream.
final class ButtonGateTests: XCTestCase {

    private func resources() throws -> FerazelResources { try FerazelData.open(try FerazelData.dataDirectory()) }

    /// Level `level` with a 16×16 empty grid and the player spawned at (`px`, `py`).
    private func world(level: Int16, px: Int = 100, py: Int = 200) throws -> (SpriteWorld, Int) {
        let w = SpriteWorld(level: try LevelFile.load(from: try resources(), level: level))
        let empty = [UInt16](repeating: 0, count: 16 * 16)
        w.tiles = TileGrid(fg: TileMap(width: 16, height: 16, cells: empty), bg: TileMap(width: 16, height: 16, cells: empty),
                           fgKinds: Array(0..<0x60), bgKinds: [Int](repeating: 0, count: 0x60))
        let pid = try XCTUnwrap(Player.spawn(world: w, x: px, y: py))
        w.playerID = pid
        return (w, pid)
    }

    /// Record `i`'s Setup (`SetupFaces`), optionally moved to (`x`, `y`), inserted.
    private func add(_ w: SpriteWorld, record i: Int, at: (Int, Int)? = nil) throws -> Int {
        var p = w.records[i]
        if let (x, y) = at {
            p = Placement(index: p.index, flag: p.flag, byte1: p.byte1, type: p.type, p1: p.p1, p2: p.p2, p3: p.p3,
                          p4: p.p4, y: Int16(y), x: Int16(x))
        }
        let s = try SetupFaces.setup(p, context: SetupFaces.Context(level: w.level, playerX: 0)).slot
        return w.active.insert(s)
    }

    private func setP4(_ w: SpriteWorld, _ i: Int, _ v: Int16) {
        let q = w.records[i]
        w.records[i] = Placement(index: q.index, flag: q.flag, byte1: q.byte1, type: q.type, p1: q.p1, p2: q.p2,
                                 p3: q.p3, p4: v, y: q.y, x: q.x)
    }

    private func button(_ w: SpriteWorld, _ id: Int) -> SpriteSlot { w.active.sprite(id: id)! }

    private func handle(_ w: SpriteWorld, _ id: Int) {
        ButtonSprite.handle(world: w, id: id) { PlayerShot.cellRect($0).right }
    }

    private func cue(_ snd: Int16, _ s: SpriteSlot) -> PlayerCue {
        PlayerCue(call: .threeD, snd: snd, priority: 10, volume: 0x100, position: s.centre)
    }

    // MARK: -

    func testMomentaryButton() throws {
        // Level 4 record 30: a 1322 with p1 0 (momentary) — its Setup (M l. 61703–61739): layer 1, the Button Handle and
        // hit, no tile callback, SetRect(8, 4, 0x18, 0x14), `+0x46 = 0`, `+0xe4 = 0`, no face (the Handle sets it).
        let (w, pid) = try world(level: 4)
        XCTAssertEqual([w.records[30].type, w.records[30].p1, w.records[30].p4], [1322, 0, 0])
        let p = button(w, pid)
        // Placed so its rect meets the player's feet: both collision passes see the contact.
        let bx = p.x + p.hotRect.left - 8, by = p.y + p.hotRect.bottom - 12
        let b = try add(w, record: 30, at: (bx, by))
        let s0 = button(w, b)
        XCTAssertEqual([Int(s0.layer), Int(s0.phase)], [1, 0])
        XCTAssertEqual([s0.handler == .button, s0.hasHit, s0.hasTileHit, s0.firstHandled], [true, true, false, false])
        XCTAssertEqual(s0.hotRect, IdleSprites.Rect(top: 4, left: 8, bottom: 0x14, right: 0x18))
        XCTAssertNil(s0.face)
        XCTAssertEqual([s0.x, s0.y, Int(s0.x256 >> 8), Int(s0.y256 >> 8)], [bx, by, bx, by])

        // One frame as the binary runs it: the Handle in the handle pass, then `.MTCollideSprites` (the Button is the
        // outer A with a hit callback, the player a B) and `.MTCollideSpecialSprite` (`.HitPlayerSprite` has no Button
        // arm; the Button's own hit follows) — two presses per frame while the player stands on it.
        func frame(stand: Bool) {
            w.player.cues = []
            handle(w, b)
            guard stand else { return }
            w.collideSprites { FerazelSession.hitCallback($0, $1, $2) }
            w.collideSpecial(hitPlayer: { HitPlayerSprite.hit($0, player: $1, other: $2) },
                             hit: { FerazelSession.hitCallback($0, $1, $2) })
        }
        // Frame 1: the Handle 0 → −1 → 0 (face cell clamp(0 − 2) = 0, p4 0); press 1: level 0 → snd 4704, 8; press 2: 16.
        frame(stand: true)
        var s = button(w, b)
        XCTAssertEqual([Int(s.phase), Int(w.records[30].p4)], [16, 0])
        XCTAssertEqual(s.face, FaceRef(pict: 0x52a, index: 0, set: .encoded))
        XCTAssertEqual(w.player.cues, [cue(4704, s)])
        XCTAssertTrue(s.firstHandled)
        // Frame 2: 16 → 15 → 11 → 9 (1322) → p4 1, face 7; pressed again (no sound: the level is not 0).
        frame(stand: true)
        s = button(w, b)
        XCTAssertEqual([Int(s.phase), Int(w.records[30].p4), s.face?.index], [25, 1, 7])
        XCTAssertEqual(w.player.cues, [])

        // Stepping off: 25 → 24 → 11 → 9 (p4 still 1), then 8 (p4 0), 7, 6, 5, and 4 plays snd 4705 (the previous 5).
        var got: [[Int]] = []
        var cues: [[PlayerCue]] = []
        for _ in 0..<6 {
            frame(stand: false)
            let t = button(w, b)
            got.append([Int(t.phase), Int(w.records[30].p4), t.face?.index ?? -1])
            cues.append(w.player.cues)
        }
        XCTAssertEqual(got, [[9, 1, 7], [8, 0, 6], [7, 0, 5], [6, 0, 4], [5, 0, 3], [4, 0, 2]])
        XCTAssertEqual(cues, [[], [], [], [], [], [cue(4705, button(w, b))]])
        XCTAssertEqual(button(w, b).buttonPrevious, 4)

        // One press per frame (a single hitter, `.HitButtonSprite` direct): 0 → 8 (snd 4704), 8 → 7 → 15, then the
        // Handle clamps 14 → 11 → 9 and writes p4 = 1 on the third frame (0 on the first two) — the bank's "+8 − 1".
        let (v, vp) = try world(level: 4)
        let c = try add(v, record: 30)
        var seq: [[Int]] = []
        for _ in 0..<3 {
            handle(v, c)
            seq.append([Int(button(v, c).phase), Int(v.records[30].p4)])
            ButtonSprite.hit(v, id: c, other: vp)
        }
        XCTAssertEqual(seq, [[0, 0], [7, 0], [9, 1]])
        XCTAssertEqual(button(v, c).phase, 17)
        // A dead Button or a dead hitter: nothing.
        v.active.update(id: vp) { $0.dead = true }
        ButtonSprite.hit(v, id: c, other: vp)
        XCTAssertEqual(button(v, c).phase, 17)
        // A dead Button's Handle makes only its `.StandardSpriteHandles`: no decrement, no record write.
        v.active.update(id: c) { $0.dead = true }
        handle(v, c)
        XCTAssertEqual([Int(button(v, c).phase), Int(v.records[30].p4)], [17, 1])
    }

    func testLatchingButton() throws {
        // Level 3 record 90: a 1322 with p1 1 (latching). Pressed once by the player (0 → 8), it counts down like a
        // momentary one until it reaches 9; then the decrement stops for good.
        let (w, pid) = try world(level: 3)
        XCTAssertEqual([w.records[90].type, w.records[90].p1, w.records[90].p4], [1322, 1, 0])
        let b = try add(w, record: 90)
        handle(w, b)
        ButtonSprite.hit(w, id: b, other: pid)
        ButtonSprite.hit(w, id: b, other: pid)                      // 16
        var got: [[Int]] = []
        for _ in 0..<4 {
            handle(w, b)
            got.append([Int(button(w, b).phase), Int(w.records[90].p4)])
        }
        // 16 ≥ 9 with p1 1: no decrement, clamp 11, 1322 → 9; then 9 stays 9.
        XCTAssertEqual(got, [[9, 1], [9, 1], [9, 1], [9, 1]])

        // A save-point resume: the Button is set up again from the record (p4 1) — its first Handle sets 10 (M l.
        // 61755–61759), latched: no decrement, 1322 → 9, p4 stays 1.
        let (v, _) = try world(level: 3)
        setP4(v, 90, 1)
        let c = try add(v, record: 90)
        handle(v, c)
        XCTAssertEqual([Int(button(v, c).phase), Int(v.records[90].p4), button(v, c).face?.index], [9, 1, 7])
        // A momentary one restored the same way (level 4 record 30): 10 → 9 (p4 1), then 8 (p4 0).
        let (m, _) = try world(level: 4)
        setP4(m, 30, 1)
        let d = try add(m, record: 30)
        handle(m, d)
        XCTAssertEqual([Int(button(m, d).phase), Int(m.records[30].p4)], [9, 1])
        handle(m, d)
        XCTAssertEqual([Int(button(m, d).phase), Int(m.records[30].p4)], [8, 0])
        // Level 4 record 63: a latching 1320 (rect SetRect(0, −20, 20, 12), face `level >> 1`): 10 stays 10, face 5.
        setP4(m, 63, 1)
        XCTAssertEqual([m.records[63].type, m.records[63].p1], [1320, 1])
        let e = try add(m, record: 63)
        XCTAssertEqual(button(m, e).hotRect, IdleSprites.Rect(top: -20, left: 0, bottom: 12, right: 20))
        handle(m, e)
        handle(m, e)
        XCTAssertEqual([Int(button(m, e).phase), Int(m.records[63].p4)], [10, 1])
        XCTAssertEqual(button(m, e).face, FaceRef(pict: 0x528, index: 5, set: .encoded))
        // Past 11: a shot press (11) then a stand-on press (+8 → 19); latched, the Handle only clamps — 0…11 (M l.
        // 61765–61771) → 11, face 11 >> 1 = 5; a momentary 1320 from 19 the same way: 18 → 11.
        let mp = try XCTUnwrap(m.playerID)
        let ms = try XCTUnwrap(PlayerShot.spawn(m, type: 0x0001, x: 0, y: 0))
        ButtonSprite.hit(m, id: e, other: ms)
        ButtonSprite.hit(m, id: e, other: mp)
        XCTAssertEqual(button(m, e).phase, 19)
        handle(m, e)
        XCTAssertEqual([Int(button(m, e).phase), button(m, e).face?.index], [11, 5])
        setP4(m, 63, 0)
        let q63 = m.records[63]
        m.records[63] = Placement(index: q63.index, flag: q63.flag, byte1: q63.byte1, type: q63.type, p1: 0, p2: q63.p2,
                                  p3: q63.p3, p4: 0, y: q63.y, x: q63.x)
        let f = try add(m, record: 63)
        handle(m, f)
        m.active.update(id: f) { $0.phase = 19 }
        handle(m, f)
        XCTAssertEqual([Int(button(m, f).phase), button(m, f).face?.index, Int(m.records[63].p4)], [11, 5, 1])
    }

    func testShotPressesButton() throws {
        // A Fireball (a player shot, `PTR_PTR_100a04e8`) → snd 4704 at any level, level = 11 (M l. 61838–61841).
        let (w, _) = try world(level: 4)
        let b = try add(w, record: 30)
        handle(w, b)
        let shot = try XCTUnwrap(PlayerShot.spawn(w, type: 0x0001, x: 300, y: 300))
        w.player.cues = []
        FerazelSession.hitCallback(w, b, shot)
        XCTAssertEqual(button(w, b).phase, 11)
        XCTAssertEqual(w.player.cues, [cue(4704, button(w, b))])
        w.active.update(id: b) { $0.phase = 5 }
        w.player.cues = []
        FerazelSession.hitCallback(w, b, shot)
        XCTAssertEqual(button(w, b).phase, 11)
        XCTAssertEqual(w.player.cues, [cue(4704, button(w, b))])
        // The next Handle: 11 → 10 → 9 (1322) → p4 1.
        handle(w, b)
        XCTAssertEqual([Int(button(w, b).phase), Int(w.records[30].p4)], [9, 1])
        // Any other hitter (an Effect, an idled player shot) presses nothing.
        let fx = try XCTUnwrap(w.newSprite(type: 0x4b1, x: 0, y: 0, layer: 1, handler: .effect))
        let idled = try XCTUnwrap(PlayerShot.spawn(w, type: 0x0001, x: 300, y: 300))
        w.active.update(id: idled) { $0.handleCleared = true }
        w.active.update(id: b) { $0.phase = 0 }
        w.player.cues = []
        ButtonSprite.hit(w, id: b, other: fx)
        ButtonSprite.hit(w, id: b, other: idled)
        XCTAssertEqual(button(w, b).phase, 0)
        XCTAssertEqual(w.player.cues, [])
    }

    func testGateRisesWithButton() throws {
        // Level 3 gate 72 (p1 90, p2 0) ← Button 90. Its Setup (M l. 59469–59497): `+0x188`, the boot single 0xb7c, no
        // HP store (600), gravity 0, layer 0, friction 6, `+0x1bc = 4`, `+0x158 = y`, both callbacks 0, rect (0, 0,
        // 0x20, 0x74).
        let (w, pid) = try world(level: 3)
        XCTAssertEqual([w.records[72].type, w.records[72].p1, w.records[72].p2], [2940, 90, 0])
        let g = try add(w, record: 72)
        let g0 = try XCTUnwrap(w.active.sprite(id: g))
        let y0 = Int(w.records[72].y)
        XCTAssertEqual([Int(g0.gravity), Int(g0.hp), Int(g0.friction), Int(g0.clip.top), Int(g0.classWord158), g0.y],
                       [0, 600, 6, 4, y0, y0])
        XCTAssertEqual([g0.keepRecord, g0.hasHit, g0.hasTileHit, g0.oneWay], [true, false, false, false])
        XCTAssertEqual(g0.face, FaceRef(pict: 0xb7c, index: 0, set: .encoded))
        XCTAssertEqual(g0.mode, 0)                                   // hdr 0x26cd is 0 on level 3: no tint
        var lights = LightTable()
        let solver = TileSolver(world: w)
        func frame() {
            w.player.cues = []
            BoxSprite.handle(world: w, id: g, solver: solver, lights: &lights, effects: 1)
            w.active.update(id: g) { $0.recordDrawn() }              // `.WrapDrawSprites`' `+0xc4` copy
        }
        // Closed (record 90's p4 0) at its start: it stays; the clip `start − y + 7` = 7; no sound test.
        let seed = w.rng.seed
        frame()
        XCTAssertEqual([w.active.sprite(id: g)!.y, Int(w.active.sprite(id: g)!.clip.top)], [y0, 7])
        XCTAssertEqual([w.player.cues.count, Int(w.rng.seed)], [0, Int(seed)])

        // Button 90 pressed (a shot): the next Handle writes p4 1.
        let b = try add(w, record: 90)
        handle(w, b)
        let shot = try XCTUnwrap(PlayerShot.spawn(w, type: 0x0001, x: 0, y: 0))
        ButtonSprite.hit(w, id: b, other: shot)
        handle(w, b)
        XCTAssertEqual(w.records[90].p4, 1)
        _ = pid

        // Open, the sound playing (`FUN_100916dc(460)` ≠ 0): it rises 2 px with no call and no draw.
        w.voices = SoundVoices(playing: [460])
        var r = w.rng
        frame()
        XCTAssertEqual(w.active.sprite(id: g)!.y, y0 - 2)
        XCTAssertEqual([w.player.cues.count, Int(w.rng.seed)], [0, Int(r.seed)])
        // Idle: the call is made — `.STPlay3DSoundRand(460, 1, 0x100, centre)` and its R(10000).
        w.voices = SoundVoices()
        let centre = w.active.sprite(id: g)!.centre
        let rate = r.soundRate()
        frame()
        XCTAssertEqual(w.player.cues, [PlayerCue(call: .threeDRand, snd: 460, priority: 1, volume: 0x100,
                                                 position: centre, rate: rate)])
        XCTAssertEqual(w.rng.seed, r.seed)
        // It goes on 2 px/frame until 100 px above the start (50 frames in all), then stops: no move, no call.
        var ys: [Int] = []
        for _ in 0..<49 {
            frame()
            ys.append(w.active.sprite(id: g)!.y)
        }
        XCTAssertEqual(ys, (3...51).map { y0 - 2 * min($0, 50) })
        XCTAssertEqual(ys.last, y0 - 100)
        XCTAssertEqual(Int(w.active.sprite(id: g)!.clip.top), 100 + 7)
        w.player.cues = []
        let still = w.rng.seed
        frame()
        XCTAssertEqual([w.active.sprite(id: g)!.y, w.player.cues.count, Int(w.rng.seed)], [y0 - 100, 0, Int(still)])
        // The record's p2 ≠ 0 adds 0x20 to the clip.
        let q = w.records[72]
        w.records[72] = Placement(index: q.index, flag: q.flag, byte1: q.byte1, type: q.type, p1: q.p1, p2: 1, p3: q.p3,
                                  p4: q.p4, y: q.y, x: q.x)
        w.voices = SoundVoices(playing: [460])
        frame()
        XCTAssertEqual(Int(w.active.sprite(id: g)!.clip.top), 100 + 7 + 0x20)
        // Closed again (p4 0): back down 2 px/frame to the start.
        setP4(w, 90, 0)
        frame()
        XCTAssertEqual(w.active.sprite(id: g)!.y, y0 - 98)
        for _ in 0..<60 { frame() }
        XCTAssertEqual(w.active.sprite(id: g)!.y, y0)

        // p1 −2 (the 2907 timer's countdown `iRam100a5110`): open while it is > −20; p1 −1: `*_DAT_1009fed0 == 1`.
        func open(p1: Int16, countdown: Int32 = -0x1e, bossFlag: UInt8 = 1, paintDraw: Bool = true) throws -> Bool {
            let (v, _) = try world(level: 3)
            let q = v.records[72]
            v.records[72] = Placement(index: q.index, flag: q.flag, byte1: q.byte1, type: q.type, p1: p1, p2: 0, p3: 0,
                                      p4: 0, y: q.y, x: q.x)
            v.countdown = countdown
            v.bossFlag = bossFlag
            v.paintDraw = paintDraw
            let k = try add(v, record: 72)
            v.voices = SoundVoices(playing: [460])
            var l = LightTable()
            BoxSprite.handle(world: v, id: k, solver: TileSolver(world: v), lights: &l, effects: 1)
            return v.active.sprite(id: k)!.y == Int(q.y) - 2
        }
        XCTAssertEqual(try [open(p1: -2, countdown: -20), open(p1: -2, countdown: -19), open(p1: -2, countdown: 0),
                            open(p1: -2, countdown: 300)], [false, true, true, true])
        XCTAssertEqual(try [open(p1: -1, bossFlag: 1), open(p1: -1, bossFlag: 0)], [true, false])
        // p1 below −2: r19 as the Handle found it — `.PaintFrameWrap`'s draw flag.
        XCTAssertEqual(try [open(p1: -3, paintDraw: true), open(p1: -3, paintDraw: false)], [true, false])
    }

    func testSwitchBlocksFollowButton() throws {
        // Level 4 block 53 (1250, p1 2, p2 57) ← Button 57. Setup: snapped to 8 px, rect (1, 1, 0x23, 0x23), HP 1, layer
        // −(2y + x), the set 0x4e2 cell 0.
        let (w, _) = try world(level: 4)
        XCTAssertEqual([w.records[53].type, w.records[53].p1, w.records[53].p2], [1250, 2, 57])
        let k = try add(w, record: 53)
        let s0 = try XCTUnwrap(w.active.sprite(id: k))
        XCTAssertEqual([s0.x, s0.y], [10224, 904])
        XCTAssertEqual(s0.face, FaceRef(pict: 0x4e2, index: 0, set: .encoded))
        var lights = LightTable()
        let solver = TileSolver(world: w)
        func frame() { BoxSprite.handle(world: w, id: k, solver: solver, lights: &lights, effects: 1) }
        let solid = IdleSprites.Rect(top: 1, left: 1, bottom: 0x23, right: 0x23)
        let empty = IdleSprites.Rect(top: 0, left: 0, bottom: 0, right: 0)
        // Record 57's p4 0: the empty rect, `+0x88 = 0`, the outline face (PICT 1252 = 0x4e4).
        frame()
        var s = try XCTUnwrap(w.active.sprite(id: k))
        XCTAssertEqual([s.hotRect == empty, s.lightOverlay], [true, false])
        XCTAssertEqual(s.face, FaceRef(pict: 0x4e4, index: 0, set: .encoded))
        // p4 1: solid, `+0x88 = 1`, the set's cell (type − 0x4e2).
        setP4(w, 57, 1)
        frame()
        s = try XCTUnwrap(w.active.sprite(id: k))
        XCTAssertEqual([s.hotRect == solid, s.lightOverlay], [true, true])
        XCTAssertEqual(s.face, FaceRef(pict: 0x4e2, index: 0, set: .encoded))
        setP4(w, 57, 0)
        frame()
        XCTAssertEqual(try XCTUnwrap(w.active.sprite(id: k)).hotRect, empty)
        // A block whose record p1 is not 2 keeps its Setup state.
        let q = w.records[53]
        w.records[53] = Placement(index: q.index, flag: q.flag, byte1: q.byte1, type: q.type, p1: 0, p2: q.p2, p3: q.p3,
                                  p4: q.p4, y: q.y, x: q.x)
        let k2 = try add(w, record: 53)
        BoxSprite.handle(world: w, id: k2, solver: solver, lights: &lights, effects: 1)
        XCTAssertEqual(try XCTUnwrap(w.active.sprite(id: k2)).hotRect, solid)
        XCTAssertEqual(try XCTUnwrap(w.active.sprite(id: k2)).face, FaceRef(pict: 0x4e2, index: 0, set: .encoded))
        // HP < 1 (a spin stomp's − 1): `.KillBox` in its Handle — dead, `.STPlay3DSoundRand(424, …)` with its R(10000).
        w.active.update(id: k) { $0.hp = 0 }
        w.player.cues = []
        var r = w.rng
        let rate = r.soundRate()
        let centre = try XCTUnwrap(w.active.sprite(id: k)).centre
        frame()
        XCTAssertTrue(try XCTUnwrap(w.active.sprite(id: k)).dead)
        XCTAssertEqual(w.player.cues, [PlayerCue(call: .threeDRand, snd: 424, priority: 1, volume: 0x100,
                                                 position: centre, rate: rate)])
    }

    func testSpoutTimerAndDraws() throws {
        // Level 4 spout 28 (1450, p1 30, p2 31, p4 1 → the bomb boulder 0x6e2). Setup: `+0x185 = 0`, the set 0x5aa cell
        // 0, gravity 0, layer 10, `+0xa6 = 0`.
        let (w, _) = try world(level: 4)
        XCTAssertEqual([w.records[28].type, w.records[28].p1, w.records[28].p2, w.records[28].p4], [1450, 30, 31, 1])
        let k = try add(w, record: 28)
        let s0 = try XCTUnwrap(w.active.sprite(id: k))
        XCTAssertEqual([Int(s0.gravity), Int(s0.layer), Int(s0.counterA6)], [0, 10, 0])
        XCTAssertFalse(s0.oneWay)
        XCTAssertEqual(s0.face, FaceRef(pict: 0x5aa, index: 0, set: .encoded))
        var lights = LightTable()
        let solver = TileSolver(world: w)
        func frame() { BoxSprite.handle(world: w, id: k, solver: solver, lights: &lights, effects: 1) }
        // Neither Button pressed: the timer stays 0 and re-tests every frame — no draws.
        let seed = w.rng.seed
        let count = w.active.sprites.count
        for _ in 0..<3 { frame() }
        XCTAssertEqual([Int(w.rng.seed), Int(w.active.sprite(id: k)!.counterA6)], [Int(seed), 0])
        // Button 31 pressed: at `+0xa6` 0 the spout fires (ES): `MTNewSprite(0x6e1 + own p4 = 0x6e2, …,
        // .SetupEnemyShotSprite)` — the Setup's R(5), R(2), R(100) and, above 0x56, R(5) (M l. 51449, 51478–51485) —
        // then R(300), R(400) for its speeds, then `+0xa6 = R(30) + 50`; one sprite more.
        func shotSetup(_ r: inout FastRand) {
            _ = r.next(5)
            _ = r.next(2)
            if 0x56 < r.next(100) { _ = r.next(5) }
        }
        setP4(w, 31, 1)
        var r = w.rng
        shotSetup(&r)
        _ = r.next(300)
        _ = r.next(400)
        let t = Int16(r.next(30)) + 50
        frame()
        XCTAssertEqual(w.rng.seed, r.seed)
        XCTAssertEqual(w.active.sprite(id: k)!.counterA6, t)
        XCTAssertEqual(w.active.sprites.count, count + 1)
        XCTAssertEqual(w.active.sprites.filter { $0.handler == .enemyShot && $0.type == 0x6e2 }.count, 1)
        // The timer counts down with no draw until it is 0 again.
        for _ in 0..<Int(t) - 1 { frame() }
        XCTAssertEqual([Int(w.rng.seed), Int(w.active.sprite(id: k)!.counterA6)], [Int(r.seed), 1])
        // Each type's pair after the shot's Setup: 1451 R(300), R(300); 1452 / 1453 R(600), R(700).
        for (type, a, b) in [(Int16(0x5ab), 300, 300), (0x5ac, 600, 700), (0x5ad, 600, 700)] {
            w.active.update(id: k) { $0.type = type; $0.counterA6 = 0 }
            var q = w.rng
            shotSetup(&q)
            _ = q.next(Int16(a))
            _ = q.next(Int16(b))
            let u = Int16(q.next(30)) + 50
            frame()
            XCTAssertEqual(w.rng.seed, q.seed, "type \(type)")
            XCTAssertEqual(w.active.sprite(id: k)!.counterA6, u, "type \(type)")
        }
        XCTAssertEqual(w.active.sprites.filter { $0.handler == .enemyShot && $0.type == 0x6e2 }.count, 4)
        // Spout 183 names record 0 twice (a 1401 with p4 0): it never fires.
        XCTAssertEqual([w.records[183].p1, w.records[183].p2, w.records[0].p4], [0, 0, 0])
        let n = try add(w, record: 183)
        let s183 = w.rng.seed
        BoxSprite.handle(world: w, id: n, solver: solver, lights: &lights, effects: 1)
        XCTAssertEqual(w.rng.seed, s183)
    }
}
