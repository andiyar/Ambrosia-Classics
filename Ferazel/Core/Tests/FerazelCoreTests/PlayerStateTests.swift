import XCTest
import HectorResources
@testable import FerazelCore

/// P3 (docs/plans/2026-10-10-ferazel-phase2.md): `.HandlePlayerSprite @ 1004d5fc` row 33 — the state / face selection
/// (decompile l. 45219–46196, first match wins), `.HandleBreathing @ 1004bb44` (l. 43314–43404), row 36's
/// invulnerability blink on the parity frames (l. 46242–46346), the footsteps and the fidgets' `FastRand`. Synthetic
/// 32×16 grid with a flat FG kind-3 floor on row 12 (surface Y + 16 = 400) and the real tile callback (P2), as
/// `PlayerTileTests`. Numbers: plan P3 (probe A `jumpfaces.out`) and the arithmetic next to each assertion; the
/// `FastRand` values are replayed on a copy of the stream (seed 1), so a missing or extra draw fails.
final class PlayerStateTests: XCTestCase {

    /// The player stands with his hot-rect bottom (`y + 0x55`) on the floor surface 400.
    private let standY = 400 - 0x55

    private func level1() throws -> LevelFile {
        let r = try FerazelData.open(try FerazelData.dataDirectory())
        return try LevelFile.load(from: r, level: 1)
    }

    private func world() throws -> SpriteWorld {
        let w = SpriteWorld(level: try level1())
        let cols = 32
        var fg = [UInt16](repeating: 0, count: cols * 16)
        for c in 0..<cols { fg[12 * cols + c] = 3 + 1 }
        w.tiles = TileGrid(fg: TileMap(width: cols, height: 16, cells: fg),
                           bg: TileMap(width: cols, height: 16, cells: [UInt16](repeating: 0, count: cols * 16)),
                           fgKinds: Array(0..<0x60), bgKinds: [Int](repeating: 0, count: 0x60))
        return w
    }

    private func player(_ w: SpriteWorld) -> SpriteSlot { w.active.sprite(id: w.playerID!)! }

    /// One `.HandlePlayerSprite` (real tile callback); the previous frame's outputs are drained first, as the session
    /// does after each handle pass. Returns this frame's face.
    @discardableResult
    private func frame(_ w: SpriteWorld, _ solver: TileSolver, _ keys: InputActions = []) -> FaceRef? {
        _ = w.player.drainFrameOutputs()
        Player.handle(world: w, keys: keys, solver: solver)
        return player(w).face
    }

    /// Spawn on the floor at x and settle 2 frames (frame 1 lands, frame 2 refills the jump counter).
    private func standing(_ w: SpriteWorld, x: Int = 100) -> TileSolver {
        XCTAssertNotNil(Player.spawn(world: w, x: x, y: standY))
        let solver = TileSolver(world: w)
        frame(w, solver)
        frame(w, solver)
        XCTAssertEqual(player(w).groundKind, 3)
        XCTAssertEqual(w.player.jumpCounter, 6)
        return solver
    }

    private func f(_ pict: Int16, _ i: Int) -> FaceRef { FaceRef(pict: pict, index: i, set: .encoded) }

    // MARK: - airborne

    func testJumpFrameDrawnGrounded() throws {
        // JUMP held 6 frames from rest (P1a `testFullJumpApex`). Frame 1: `0738` was latched by row 20 before
        // `.HandleKeys` made the impulse, so row 33 takes the grounded arm → stand 1003[chest] (Bank correction A9).
        let w = try world()
        let solver = standing(w)
        let chest = Int(w.player.chestFrame)
        var faces: [FaceRef?] = []
        var counters: [Int16] = []
        for k in 1...23 {
            faces.append(frame(w, solver, k <= 6 ? [.jump] : []))
            counters.append(w.player.airCounter)
        }
        XCTAssertEqual(faces[0]?.pict, 1003)
        XCTAssertEqual(faces[0], f(1003, chest))
        // The air counter c: rising and not spinning → +1 while c < 10 (frames 2–11: 1…10); c ≥ 10 holds while
        // rising (frame 12, the apex frame) and +1 falling (frames 13…: 11, 12, …).
        XCTAssertEqual(Array(counters.prefix(13)), [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 10, 11])
        // Buckets: 0–1 → 0, 2–3 → 1, 4–5 → 2, 6–7 → 3, 8–15 → 4, 16–23 → 5.
        XCTAssertEqual(faces[1...12].map { $0?.pict }, [Int16?](repeating: 1010, count: 12))
        XCTAssertEqual(faces[1...12].map { $0?.index }, [0, 1, 1, 2, 2, 3, 3, 4, 4, 4, 4, 4])
        XCTAssertEqual(faces[12...16].map { $0?.index }, [4, 4, 4, 4, 4])     // frames 13–17: c 11…15
        XCTAssertEqual(faces[17...22].map { $0 }, [FaceRef?](repeating: f(1010, 5), count: 6))  // c 16… from frame 18
        XCTAssertEqual(counters[17], 16)
        // Frame 24 lands (P2): grounded again — stand.
        XCTAssertEqual(frame(w, solver)?.pict, 1003)
        XCTAssertEqual(w.player.airCounter, 0)

        // Falling with c < 3 (it rose < 3 frames) jumps to 0x12 → 1010[5] at once; c 3…9 falling adds 2.
        for (c, next) in [(Int16(2), Int16(0x12)), (3, 5), (9, 11)] {
            let a = try world()
            let sa = standing(a)
            frame(a, sa, [.jump])
            a.player.airCounter = c
            a.active.update(id: a.playerID!) { $0.vy = 0x200 }
            frame(a, sa)
            XCTAssertEqual(a.player.airCounter, next, "c \(c)")
        }
        XCTAssertEqual(PlayerStates.bucket(0x12), 5)
        XCTAssertEqual([-1, 0, 1, 2, 3, 4, 5, 6, 7, 8, 15, 16, 23, 24, 29, 30, 35, 36, 41, 42].map {
            PlayerStates.bucket(Int16($0)) }, [9, 0, 0, 1, 1, 2, 2, 3, 3, 4, 4, 5, 5, 6, 6, 7, 7, 8, 8, 9])
        // Spinning: c = 0x1a and 1025[spin frame + 1 mod 8]; the launched tumble 1015 leaves the facing alone.
        let s = try world()
        let ss = standing(s)
        frame(s, ss, [.jump])
        s.player.spin = true
        s.player.spinFrame = 7
        XCTAssertEqual(frame(s, ss), f(1025, 0))
        XCTAssertEqual(s.player.airCounter, 0x1a)
        s.player.spin = false
        s.player.launched = true
        s.player.facing = 1                                               // F 1 → would mirror; the tumble keeps it
        let mirrored = player(s).mirrored
        XCTAssertEqual(frame(s, ss), f(1015, 1))
        XCTAssertEqual(player(s).mirrored, mirrored)
        XCTAssertLessThanOrEqual(s.player.airCounter, 0xf)
    }

    // MARK: - grounded: walk, run, turn, fidget

    func testWalkFootstepFrames() throws {
        // RIGHT held from rest: the first walking frame sets `+0x46` = 0xc and adds 2 → 0xe (1020[7]); a footstep at
        // `+0x46` 6 and 0x16 → frames 5 (0x16) and 13 (6), then every 8 (21, 29). Index += FastRand(2) + 1, −4 past 3;
        // dry: `.STPlayRegSound(410 + index, 1, 0x55)`.
        let w = try world()
        let solver = standing(w, x: 40)
        var replay = w.rng
        var index: Int16 = 0
        var steps: [Int] = []
        for k in 1...30 {
            let face = frame(w, solver, [.right])
            if k == 1 { XCTAssertEqual(face, f(1020, 7)) }
            XCTAssertEqual(face?.pict, 1020)
            let cues = w.player.cues.filter { (410...413).contains($0.snd) }
            if !cues.isEmpty {
                steps.append(k)
                index = index &+ replay.next(2) &+ 1
                if 3 < index { index -= 4 }
                XCTAssertEqual(cues, [PlayerCue(call: .reg, snd: 410 + index, priority: 1, volume: 0x55)])
                XCTAssertEqual(w.player.footstep, index)
            }
        }
        XCTAssertEqual(steps, [5, 13, 21, 29])
        XCTAssertEqual(w.rng.seed, replay.seed)                           // exactly one FastRand(2) per step

        // In liquid (`+0x120 ≠ 0` — SSH copies `+0x11c`): the 3D splash 454 instead, its rate drawn after the R(2).
        let l = try world()
        let ls = standing(l, x: 40)
        var lr = l.rng
        for k in 1...5 {
            l.active.update(id: l.playerID!) { $0.waterRow = 30 }
            let centre = player(l).centre                                // `+0xe` at the call: row 39 runs after row 33
            frame(l, ls, [.right])
            if k == 5 {
                _ = lr.next(2)
                let rate = lr.soundRate()
                XCTAssertEqual(l.player.cues.filter { $0.snd == 454 },
                               [PlayerCue(call: .threeDRand, snd: 454, priority: 1, volume: 0x2a,
                                          position: centre, rate: rate)])
                XCTAssertEqual(l.rng.seed, lr.seed)
            }
        }
    }

    func testRunFootstepFrames() throws {
        // RIGHT + RUN from rest: `+0x46` 0xe, 0x10 (frame 2: step), … wraps past 0x17 to 0 (12 faces of 1024); steps at
        // 6 and 0x10 → frames 2, 9, 14, 21; vol 0x78. Double Speed moves them to 8 and 0x10.
        let w = try world()
        let solver = standing(w, x: 20)
        var steps: [Int] = []
        var faces: [Int] = []
        for k in 1...21 {
            let face = frame(w, solver, [.right, .run])
            XCTAssertEqual(face?.pict, 1024)
            faces.append(face?.index ?? -1)
            let cues = w.player.cues.filter { (410...413).contains($0.snd) }
            if !cues.isEmpty {
                steps.append(k)
                XCTAssertEqual(cues.map(\.volume), [0x78])
                XCTAssertEqual(cues.map(\.priority), [1])
            }
        }
        XCTAssertEqual(steps, [2, 9, 14, 21])
        XCTAssertEqual(Array(faces.prefix(8)), [7, 8, 9, 10, 11, 0, 1, 2])
        XCTAssertEqual(w.player.turnCountdown, 0)
        // Double Speed (no Phase-2 writer; set directly): steps at `+0x46` 8 and 0x10.
        let d = try world()
        let ds = standing(d, x: 20)
        d.player.doubleSpeed = true
        var dsteps: [Int] = []
        for k in 1...14 {
            frame(d, ds, [.right, .run])
            if d.player.cues.contains(where: { (410...413).contains($0.snd) }) { dsteps.append(k) }
        }
        XCTAssertEqual(dsteps, [2, 10, 14])                               // `+0x46` 0x10, 8 (after the wrap), 0x10
    }

    func testTurnFromRest() throws {
        // Facing right at rest, LEFT held: vx < 0 sets F = 1 (`.HandleKeys`), |vx| ≤ 0x5db and F ≠ F' → the walk arm
        // falls through to the stand arm: countdown 4 → 1030[0] with the turn flag `PTR_DAT_100a06c4`, then
        // 3 → [1] flag, 2 → [2] flag, 1 → [1], 0 → [0]; `+0x17e = (F ≠ 2) XOR flag`. Frame 6 walks (1020[7]).
        let w = try world()
        let solver = standing(w, x: 300)
        var seen: [(FaceRef?, Bool, Bool)] = []
        for _ in 0..<6 {
            let face = frame(w, solver, [.left])
            seen.append((face, w.player.turnMirror, player(w).mirrored))
        }
        XCTAssertEqual(seen.map { $0.0 }, [f(1030, 0), f(1030, 1), f(1030, 2), f(1030, 1), f(1030, 0), f(1020, 7)])
        XCTAssertEqual(seen.map { $0.1 }, [true, true, true, false, false, false])
        XCTAssertEqual(seen.map { $0.2 }, [false, false, false, true, true, true])
        XCTAssertEqual(w.player.facing, 1)
        // Released and stopped, then RIGHT: the turn back mirrors 1, 1, 1, 0, 0.
        for _ in 0..<12 { frame(w, solver) }
        XCTAssertEqual(player(w).vx, 0)
        let back = (0..<5).map { _ -> (Int?, Bool) in
            let face = frame(w, solver, [.right]); return (face?.index, player(w).mirrored)
        }
        XCTAssertEqual(back.map { $0.0 }, [0, 1, 2, 1, 0])
        XCTAssertEqual(back.map { $0.1 }, [true, true, true, false, false])
        // Above 0x5db the walk arm draws the walk at once even while F ≠ F' (raw `1005080c cmpwi r0,0x5dc`): facing
        // left while sliding right at 0x700, RIGHT turns F to 2 (vx > 0) with |vx| = 0x76c → 1020, no turn.
        w.player.facing = 1
        w.active.update(id: w.playerID!) { $0.vx = 0x700 }
        XCTAssertEqual(frame(w, solver, [.right])?.pict, 1020)
        XCTAssertEqual(w.player.turnCountdown, 0)
        // At exactly 0x5db after the frame's walk accel (+0x104, + the right-only push 0x14a: P1b) it turns instead.
        w.player.facing = 1
        w.active.update(id: w.playerID!) { $0.vx = 0x5db - 0x104 - 0x14a }
        XCTAssertEqual(frame(w, solver, [.right]), f(1030, 0))
        // One more (0x5dc after the accel) walks.
        for _ in 0..<5 { frame(w, solver) }
        w.player.facing = 1
        w.active.update(id: w.playerID!) { $0.vx = 0x5dc - 0x104 - 0x14a }
        XCTAssertEqual(frame(w, solver, [.right])?.pict, 1020)
    }

    func testFirstFidgetAt150() throws {
        // Idle +1 per Handle (row 6) from `.ClearPlayerVars`' 0: frame 150 (idle 150, m 0) → 1029[0]; m 0…7 → m/3,
        // 8…99 → [2], 100…139 → min(m − 92, 15)/3 (m 107 → [5]), 140…155 → (15 − (m − 140))/3; m 156 → idle 0,
        // fidgets 1 (the face is left from m 155: [0]).
        let w = try world()
        let solver = standing(w)
        var faces: [Int: FaceRef?] = [:]
        for k in 3...306 { faces[k] = frame(w, solver) }
        XCTAssertEqual(faces[149]??.pict, 1003)
        XCTAssertEqual(faces[150], f(1029, 0))
        XCTAssertEqual(faces[153], f(1029, 1))                           // m 3
        XCTAssertEqual(faces[158], f(1029, 2))                           // m 8
        XCTAssertEqual(faces[249], f(1029, 2))                           // m 99
        XCTAssertEqual(faces[250], f(1029, 2))                           // m 100: min(8, 15)/3
        XCTAssertEqual(faces[257], f(1029, 5))                           // m 107: 15/3
        XCTAssertEqual(faces[289], f(1029, 5))                           // m 139
        XCTAssertEqual(faces[290], f(1029, 5))                           // m 140: 15/3
        XCTAssertEqual(faces[305], f(1029, 0))                           // m 155: 0/3
        XCTAssertEqual(faces[306], f(1029, 0))                           // m 156: reset, face kept
        XCTAssertEqual(w.player.idle, 0)
        XCTAssertEqual(w.player.fidgets, 1)
        // Any L/R zeroes idle and fidgets (`.HandleKeys`), so the next fidget waits another 150 frames.
        frame(w, solver, [.right])
        XCTAssertEqual([w.player.idle, w.player.fidgets], [0, 0])
    }

    func testSecondFidgetSet() throws {
        // After three fidgets (each 157 frames from idle 150: m 0…156), fidgets 3 → 1028[(m mod 20) >> 1]; at m 241
        // (> 0xf0): idle = −FastRand(60), fidgets 0 — the only draw.
        let w = try world()
        let solver = standing(w)
        var k = 2
        while w.player.fidgets < 3 { frame(w, solver); k += 1 }
        XCTAssertEqual(k, 3 * 306)                                       // idle 1…306 per cycle (reset at m 156)
        var replay = w.rng
        var seen: [FaceRef?] = []
        while w.player.idle < 0x95 { seen.append(frame(w, solver)) }
        XCTAssertEqual(seen.last??.pict, 1003)
        var m: [Int: FaceRef?] = [:]
        for i in 0...241 { m[i] = frame(w, solver) }
        XCTAssertEqual(m[0], f(1028, 0))
        XCTAssertEqual(m[2], f(1028, 1))
        XCTAssertEqual(m[19], f(1028, 9))
        XCTAssertEqual(m[20], f(1028, 0))
        XCTAssertEqual(m[240], f(1028, 0))
        XCTAssertEqual(m[241], f(1028, 0))                               // 241 mod 20 = 1 → 0, then the reset
        XCTAssertEqual(w.player.idle, 0 &- replay.next(60))
        XCTAssertEqual(w.player.fidgets, 0)
        XCTAssertEqual(w.rng.seed, replay.seed)
        XCTAssertLessThanOrEqual(w.player.idle, 0)
        // From −R(60) the idle climbs back: the stand face until 150 again.
        XCTAssertEqual(frame(w, solver)?.pict, 1003)
    }

    // MARK: - hurt, dying

    func testHurtStunFaces() throws {
        // `_DAT_100a0748 = 1` (`.HurtPlayer`, W2a; set directly): 1013 index n − 1 for n < 5, 3 for n < 8, 3 − (n − 8)
        // after → 0,1,2,3,3,3,3,3,2,1; n + 1 > 10 → 0. Each frame: climb, spin, crouch 0; stop 427 if playing.
        let w = try world()
        let solver = standing(w)
        w.player.stun = 1
        w.player.spin = true
        w.player.crouch = 3
        var faces: [Int] = []
        for _ in 0..<10 {
            let face = frame(w, solver)
            XCTAssertEqual(face?.pict, 1013)
            faces.append(face?.index ?? -1)
            XCTAssertTrue(w.player.cues.contains(PlayerCue(call: .stopIfPlaying, snd: 427)))
            XCTAssertFalse(w.player.spin)
            XCTAssertEqual(w.player.crouch, 0)
            XCTAssertFalse(w.player.standing0670)
        }
        XCTAssertEqual(faces, [0, 1, 2, 3, 3, 3, 3, 3, 2, 1])
        XCTAssertEqual(w.player.stun, 0)
        // Then the stand arm (chest frame 3 on entry: `0670` was cleared).
        XCTAssertEqual(frame(w, solver), f(1003, 3))
    }

    func testDyingFacesAndEnd() throws {
        // `_DAT_100a069c = 1` (the death trigger, P4; set directly). c = the counter before its +1: c < 30 → 1022[c/3],
        // buoyancy `+0x19e` += (c & 1) + 1, float line `+0x1a0` = −22, and for c > 8 the hot rect drifts 2 px toward
        // the facing side (`+0x36`/`+0x3a`; the row-20 reset is skipped while dying); c ≥ 30 → 1022[9]. vx 0, climb 0,
        // `+0x116` 0, hit callback off. Ends (DAT_100a5106) when the counter passes 0x50 (100 in liquid): frame 80.
        for liquid in [false, true] {
            for left in [false, true] {
                let w = try world()
                let solver = standing(w)
                w.player.dying = 1
                w.player.diedInLiquid = liquid
                if left { w.player.facing = 1 }
                w.active.update(id: w.playerID!) { $0.invulnerable = 30 }
                var end = 0
                var buoyancy: Int16 = 0
                for c in 1...101 {
                    let face = frame(w, solver)
                    let s = player(w)
                    XCTAssertEqual(face, f(1022, c < 30 ? c / 3 : 9), "c \(c)")
                    if c < 30 {
                        buoyancy += Int16(c & 1) + 1
                        XCTAssertEqual(s.buoyancy, buoyancy)
                        XCTAssertEqual(s.floatOffset, -22)
                    }
                    let drift = 2 * max(0, min(c, 29) - 8) * (s.mirrored ? -1 : 1)
                    XCTAssertEqual(s.hotRect, IdleSprites.Rect(top: 0x22, left: 0x26 + drift, bottom: 0x55,
                                                               right: 0x3e + drift), "c \(c)")
                    XCTAssertEqual(s.vx, 0)
                    XCTAssertEqual(s.invulnerable, 0)
                    XCTAssertFalse(s.hasHit)
                    XCTAssertEqual(s.mirrored, left)
                    if end == 0 && w.player.gameOver { end = c }
                }
                XCTAssertEqual(end, liquid ? 100 : 80)
            }
        }
    }

    // MARK: - breathing, blink

    func testBreathingCalmHoldsAtChest1() throws {
        // `.HandleBreathing` with E 0 (L = 2, period 9 − 2 = 7): phase 3 → 4 (frame 1, chest 2) → 5 (frame 8, chest 1);
        // at frame 15 chest 1 ∧ E < 0xa0 ∧ last phase ≥ 2 → no advance: held at chest 1 (l. 43367; Bank correction A11).
        let w = try world()
        XCTAssertNotNil(Player.spawn(world: w, x: 100, y: standY))
        let id = w.playerID!
        var phases: [Int16] = [], chests: [Int16] = [], periods: [Int16] = []
        for _ in 0..<30 {
            Breathing.handle(world: w, id: id)
            phases.append(w.player.breathPhase)
            chests.append(w.player.chestFrame)
            periods.append(w.player.breathPeriod)
        }
        XCTAssertEqual(Array(phases.prefix(16)), [4, 4, 4, 4, 4, 4, 4, 5, 5, 5, 5, 5, 5, 5, 5, 5])
        XCTAssertEqual(Set(phases.suffix(23)), [5])
        XCTAssertEqual(Array(chests.prefix(8)), [2, 2, 2, 2, 2, 2, 2, 1])
        XCTAssertEqual(Set(chests.suffix(23)), [1])
        XCTAssertEqual(Array(periods.prefix(8)), [7, 6, 5, 4, 3, 2, 1, 7])
        XCTAssertTrue(w.player.cues.isEmpty)                             // phase 2 never reached: no breath sound

        // Exertion ≥ 0xa0 breaks the hold: L = (0xa0 − 100) >> 6 = 0 → 2 still (period 7), the phase cycles 5 → 0
        // (wrap) → 1 → 2: the breath sound 409 (9 − L = 7 ≥ 4) at prio 1, vol 0x37; E −2 per frame.
        w.player.exertion = 0xc0
        var sounds: [PlayerCue] = []
        for _ in 0..<25 {
            Breathing.handle(world: w, id: id)
            sounds += w.player.cues
            w.player.cues = []
        }
        XCTAssertEqual(sounds, [PlayerCue(call: .reg, snd: 409, priority: 1, volume: 0x37)])
        XCTAssertEqual(w.player.exertion, 0xc0 - 50)
        // Exhausted (E 600 → L 7 → 6, period 3 < 4): the faster 408.
        w.player.exertion = 600 + 2
        w.player.breathPhase = 1
        w.player.breathPeriod = 1
        Breathing.handle(world: w, id: id)
        XCTAssertEqual(w.player.cues, [PlayerCue(call: .reg, snd: 408, priority: 1, volume: 0x37)])
        XCTAssertEqual(w.player.breathPeriod, 3)
        // Oxygen below health: f = (1 − 560)·400 (f32) = −223600; E 0 + f < 220 → E = (i16)−223600 = −26992.
        let o = try world()
        XCTAssertNotNil(Player.spawn(world: o, x: 100, y: standY))
        o.globals.breath = 559
        Breathing.handle(world: o, id: o.playerID!)
        XCTAssertEqual(o.player.exertion, -26992)
        // Dying: nothing runs.
        o.player.dying = 1
        let before = o.player
        Breathing.handle(world: o, id: o.playerID!)
        XCTAssertEqual(o.player, before)
    }

    func testInvulBlinkParity() throws {
        // Row 36: parity `_DAT_1009fd30` set ∧ `+0x116 ≥ 15` (after row 10's SSH −1) ∧ not stunned → `+0xb8 0x10006`,
        // `+0x18c` 1; > 60 → 0x10009, `+0x1a6` 0xdc, `+0x1a8` 0x10. Otherwise (no power-up tint) `+0xb8` 0, `+0x1a6` /
        // `+0x1a8` 0, `+0x88` 1.
        func blink(invul: Int16, parity: Bool, stun: Int16 = 0) throws -> SpriteSlot {
            let w = try world()
            let solver = standing(w)
            w.parity = parity
            w.player.stun = stun
            w.active.update(id: w.playerID!) { $0.invulnerable = invul }
            frame(w, solver)
            return player(w)
        }
        let on = try blink(invul: 16, parity: true)                      // 15 after SSH
        XCTAssertEqual(on.mode, 0x10006)
        XCTAssertTrue(on.noWaterSplit)
        XCTAssertEqual(on.glowKind, 0)
        let off = try blink(invul: 16, parity: false)
        XCTAssertEqual(off.mode, 0)
        XCTAssertTrue(off.lightOverlay)
        XCTAssertEqual([off.glowKind, off.glowChance], [0, 0])
        XCTAssertEqual(try blink(invul: 15, parity: true).mode, 0)       // 14 < 15
        XCTAssertEqual(try blink(invul: 16, parity: true, stun: 1).mode, 0)
        let high = try blink(invul: 62, parity: true)                    // 61 > 60
        XCTAssertEqual(high.mode, 0x10009)
        XCTAssertEqual([high.glowKind, high.glowChance], [0xdc, 0x10])
        XCTAssertEqual(try blink(invul: 61, parity: true).mode, 0x10006) // 60
        // The power-up tints (Phase 4 flags, set directly) and their `+0x88` 0 / `+0x1a8` 8.
        let w = try world()
        let solver = standing(w)
        w.player.tint0634 = true
        w.player.highJump = true
        frame(w, solver)
        XCTAssertEqual(player(w).mode, 0x1000c)
        XCTAssertEqual([player(w).glowKind, player(w).glowChance], [9, 8])
        XCTAssertFalse(player(w).lightOverlay)

        // The session flips the parity on drawn iterations only, before `.WrapCopyToScreen` (so the Handles of that
        // iteration see the new value): default prefs T, F, T, F; "Reduce frame rate" (draws F, T, F, T) F, T, T, F.
        let r = try FerazelData.open(try FerazelData.dataDirectory())
        let s = try FerazelSession(resources: r, prefs: FerazelPrefs(), level: 1)
        XCTAssertFalse(s.world.parity)
        XCTAssertEqual((0..<4).map { _ in _ = s.step(keys: KeyState()); return s.world.parity }, [true, false, true, false])
        var slow = FerazelPrefs()
        slow.reduceFrameRate = 1
        let t = try FerazelSession(resources: r, prefs: slow, level: 1)
        XCTAssertEqual((0..<4).map { _ in _ = t.step(keys: KeyState()); return t.world.parity }, [false, true, true, false])
        // And the player in the session blinks on the parity: invulnerable 40 → odd iterations drawn with 0x10006.
        let b = try FerazelSession(resources: r, prefs: FerazelPrefs(), level: 1)
        _ = b.step(keys: KeyState())
        b.world.active.update(id: b.playerID) { $0.invulnerable = 40 }
        let modes = (0..<4).map { _ -> UInt32 in _ = b.step(keys: KeyState()); return b.active.sprite(id: b.playerID)!.mode }
        XCTAssertEqual(modes, [0, 0x10006, 0, 0x10006])
    }
}
