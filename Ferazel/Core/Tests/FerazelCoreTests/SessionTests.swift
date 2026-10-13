import XCTest
import HectorResources
@testable import FerazelCore

/// R5 (docs/plans/2026-10-06-ferazel-phase1.md): the player's grounded faces (player-states §3.11; since P3 the real
/// `.HandlePlayerSprite @ 1004d5fc` in the session — the Phase-1 ◇ pose is gone, the face sequences are the binary's
/// and unchanged), the camera (`.FindUpperLeftCorner @ 1000b5ec`, engine §5; since P5 fed by `.PlayerScroll`), and one
/// `.GameLoop @ 10009d48` iteration in `.PaintFrameWrap @ 10011cf8` order — against the committed `Resources/Ferazel`
/// (D26). A missing data file is a FAILURE, never a skip. The keys are the original defaults (keypad 4 / 6, Shift).
final class SessionTests: XCTestCase {

    private func resources() throws -> FerazelResources { try FerazelData.open(try FerazelData.dataDirectory()) }

    private func level1() throws -> LevelFile { try LevelFile.load(from: try resources(), level: 1) }

    /// The level-1 session with the player at its start (P3: the real player in place of the ◇ pose).
    private func pose() throws -> Pose { Pose(try FerazelSession(resources: try resources(), prefs: FerazelPrefs(),
                                                                 level: 1)) }

    /// The player as the Phase-1 tests read it: one `step` = one `.GameLoop` iteration with keypad 4 / keypad 6 /
    /// Shift (`FerazelPrefs.defaultKeys` 0x56 / 0x58 / 0x38) held.
    private struct Pose {
        let session: FerazelSession
        init(_ s: FerazelSession) { session = s }
        var sprite: SpriteSlot { session.active.sprite(id: session.playerID)! }
        var face: FaceRef? { sprite.face }
        var mirrored: Bool { sprite.mirrored }
        var turnFlag: Bool { session.player.turnMirror }
        var idle: Int16 { session.player.idle }
        var facing: Int16 { session.player.facing }
        func step(left: Bool, right: Bool, run: Bool) {
            var codes: [Int] = []
            if left { codes.append(0x56) }
            if right { codes.append(0x58) }
            if run { codes.append(0x38) }
            _ = session.step(keys: KeyState(pressed: codes))
        }
    }

    private func fr(_ pict: Int16, _ index: Int) -> FaceRef? { FaceRef(pict: pict, index: index, set: .encoded) }

    private func faces(_ p: inout Pose, frames: Int, left: Bool = false, right: Bool = false,
                       run: Bool = false) -> [FaceRef?] {
        (0..<frames).map { _ in p.step(left: left, right: right, run: run); return p.face }
    }

    // MARK: - the player's grounded faces

    func testPlayerStartPose() throws {
        var p = try pose()
        // `.GameLoop(hdr+0x2848 − 0x20, hdr+0x2846 − 0x20, …)` (`.NewGame` l. 5823) → `MTNewSprite(0, x, y, 10, …)` →
        // `.SetupPlayerSprite`: `fd44 = fe68 = +8`, `fd40 = fe64 = +6` (`PlayerState.focusX/focusY`).
        XCTAssertEqual(p.session.player.focusX, 83)
        XCTAssertEqual(p.session.player.focusY, 143)
        XCTAssertEqual(p.sprite.oldPosition, SpriteSlot.Point(x: 83, y: 143))
        XCTAssertEqual(Player.layer, 10)
        XCTAssertEqual(p.facing, 2)                          // G+0x16 = hdr 0x26c8 = 0 → F = 2, +0x17e = 0
        XCTAssertFalse(p.mirrored)
        XCTAssertNil(p.face)                                 // `.SetupPlayerSprite`: +0xc0 = 0 until the first Handle
        XCTAssertEqual(p.sprite.layer, 10)
        XCTAssertEqual(p.sprite.hotRect, IdleSprites.Rect(top: 0x22, left: 0x26, bottom: 0x55, right: 0x3e))
        // The level start's tail of the active list (P3): `.SetupPlayerSprite` makes the held item (100, layer 0x14)
        // and the five trails (1, layer 9) **before** the player is inserted (`.MTNewSprite` runs the Setup before
        // `.MTInsertSprite`), then the countdown 0x4c4's Setup makes six digits 0x4c5 before it (all layer 0x7fff);
        // each lands at the tail of its layer group: trails, player, held item, digits, countdown.
        let all = p.session.active.sprites
        guard all.count == 24 else { return XCTFail("active list: \(all.count) sprites, expected 24") }
        XCTAssertEqual(Array(all.suffix(14)).map { [Int($0.type), Int($0.layer)] },
                       [[1, 9], [1, 9], [1, 9], [1, 9], [1, 9], [0x45, 10], [100, 0x14]]
                       + [[Int]](repeating: [0x4c5, 0x7fff], count: 6) + [[0x4c4, 0x7fff]])
        XCTAssertEqual(all[15].id, p.session.playerID)
        XCTAssertEqual(p.session.player.heldItem, all[16].id)
        XCTAssertEqual(p.session.player.trail, all[10...14].map { Optional($0.id) })
        XCTAssertEqual(p.session.countdownID, all[23].id)
        // `.MTNewSprite` with all 700 records in use: no player, no Setup (`*_DAT_1009fdd8 = 0`). With one record left,
        // the player's record is taken before its Setup runs (raw `100331cc`), so the held item and the trails find
        // none.
        for (filled, spawns) in [(700, false), (699, true)] {
            let full = SpriteWorld(level: try level1())
            for _ in 0..<filled { _ = full.active.insert(SpriteSlot(type: 0x51b, x: 0, y: 0)) }
            XCTAssertEqual(Player.spawn(world: full, x: 83, y: 143) != nil, spawns)
            XCTAssertEqual(full.playerID != nil, spawns)
            XCTAssertNil(full.player.heldItem)
            XCTAssertEqual(full.player.trail.compactMap { $0 }, [])
            XCTAssertEqual(full.active.sprites.count, 700)
        }
        let hot = { (s: SpriteSlot) in IdleSprites.Rect(top: s.y + s.hotRect.top, left: s.x + s.hotRect.left,
                                                         bottom: s.y + s.hotRect.bottom, right: s.x + s.hotRect.right) }
        // The spawn's hot rect in the world, at `+8`/`+6` (`.MTNewSprite` leaves `+0xc`/`+0xa` to the first writer).
        let spawn = p.sprite.oldPosition
        XCTAssertEqual(IdleSprites.Rect(top: spawn.y + 0x22, left: spawn.x + 0x26, bottom: spawn.y + 0x55,
                                        right: spawn.x + 0x3e),
                       IdleSprites.Rect(top: 143 + 0x22, left: 83 + 0x26, bottom: 143 + 0x55, right: 83 + 0x3e))
        // First Handle: stand entry forces chest frame 3 → face 1003[3]; then the breathing triangle (phase 4 → 2,
        // phase 5 → 1 after the 7-frame calm period, then held at 1: `.HandleBreathing @ 1004bb44`).
        let seen = faces(&p, frames: 10)
        XCTAssertEqual(seen.first, FaceRef(pict: 1003, index: 3, set: .encoded))
        XCTAssertEqual(seen.map { $0?.index }, [3, 2, 2, 2, 2, 2, 2, 1, 1, 1])
        XCTAssertTrue(seen.allSatisfy { $0?.pict == 1003 })
        XCTAssertFalse(p.mirrored)
        XCTAssertEqual(p.sprite.face, FaceRef(pict: 1003, index: 1, set: .encoded))
        // ⚑ P3 (re-measured, Invariant-10 ruling): the frame-1 lift 143 → 123. The start point puts the hot-rect bottom
        // at 228, 20 px inside FG (4, 6) — kind 4; the pre-move `.SeparateFromTiles2` (row 19, `bl 0x1003c804` at raw
        // `1004e58c`) hands it to `.WallBounce`'s kind-4 floor arm (decompile l. 33244–33266): y = Y + 0x10 −
        // rect.bottom = 192 + 16 − 0x55 = 123 (vy 0, so `+0xce` is not set there). Phase 1's pose never moved.
        XCTAssertEqual(p.sprite.x, 83)
        XCTAssertEqual(p.sprite.y, 123)
        XCTAssertEqual(hot(p.sprite), IdleSprites.Rect(top: 123 + 0x22, left: 83 + 0x26, bottom: 123 + 0x55,
                                                       right: 83 + 0x3e))
        // Fidget after 150 idle frames (idle +1 per frame, l. 44591): face 1029[m / 3], m = idle − 150.
        var q = try pose()
        let f = faces(&q, frames: 160)
        XCTAssertEqual(f[148]?.pict, 1003)                   // idle 149
        XCTAssertEqual(f[149], FaceRef(pict: 1029, index: 0, set: .encoded))   // idle 150, m 0
        XCTAssertEqual(f[152], FaceRef(pict: 1029, index: 1, set: .encoded))   // m 3
        XCTAssertEqual(f[159], FaceRef(pict: 1029, index: 2, set: .encoded))   // m 10 → 8 / 3
    }

    func testWalkCycleFaces() throws {
        var p = try pose()
        _ = faces(&p, frames: 3)
        // Right held (F unchanged): the first walking frame sets `+0x46 = 0xc` and adds 2 in the same frame
        // (handler l. 2088–2120) → 0xe → face 1020[7]; then +2 per frame (the flat-floor cycle with its wrap past 0x1f
        // is pinned by `PlayerStateTests.testWalkFootstepFrames`).
        // ⚑ P3 (re-measured, Invariant-10 ruling; was 20 × 1020[7…15, 0…10] walking in place): the real player
        // walks off the start ledge — FG (5, 6) is empty — on frame 6 (airborne, c 0 < 3 → 0x12 → 1010[5]) and from
        // frame 10 clings to the pit's far wall (FG (6, 6) kind 6; hot-rect right 146 + 0x3e = 208, its left edge 192 +
        // 16) at x 146: 1012[(phase 1 − 1) >> 1] = 1012[0]. The session hands the frame's cues over (`frameCues`):
        // the grounded arm's stop 427 on frames 1–5 and the footstep on frame 5 (`+0x46` 0x16; FastRand(2) = 0 under
        // seed 1 → index 1 → 411, vol 0x55).
        var cues: [[PlayerCue]] = []
        let seen = (0..<20).map { _ -> FaceRef? in
            p.step(left: false, right: true, run: false)
            cues.append(p.session.frameCues)
            return p.face
        }
        let stop = PlayerCue(call: .stopIfPlaying, snd: 427)
        XCTAssertEqual(cues.prefix(5).map { $0 }, [[stop], [stop], [stop], [stop],
                                                   [stop, PlayerCue(call: .reg, snd: 411, priority: 1, volume: 0x55)]])
        // Airborne (frames 6–9): none. The first cling frame (10): 455 (`.STPlay3DSoundRand`) and the cling arm's stop 427;
        // then each clinging frame: row 26's stop 427 and the cling arm's.
        XCTAssertEqual(cues[5...8].map(\.count), [0, 0, 0, 0])
        XCTAssertEqual(cues[9].map(\.snd), [455, 427])
        XCTAssertEqual(cues[9].map(\.call), [.threeDRand, .stopIfPlaying])
        XCTAssertEqual(Array(cues.suffix(10)), [[PlayerCue]](repeating: [stop, stop], count: 10))
        XCTAssertEqual(seen, [fr(1020, 7), fr(1020, 8), fr(1020, 9), fr(1020, 10), fr(1020, 11)]
                       + [FaceRef?](repeating: fr(1010, 5), count: 4) + [FaceRef?](repeating: fr(1012, 0), count: 11))
        XCTAssertEqual(p.sprite.x, 146)
        XCTAssertFalse(p.mirrored)
        XCTAssertEqual(p.idle, 0)                            // `.HandleKeys` zeroes idle on L/R
        // Release: the cling holds (the tile callback re-asserts it every frame) — still 1012[0]; walk again: 1012[0].
        p.step(left: false, right: false, run: false)
        XCTAssertEqual(p.face, FaceRef(pict: 1012, index: 0, set: .encoded))
        p.step(left: false, right: true, run: false)
        XCTAssertEqual(p.face, FaceRef(pict: 1012, index: 0, set: .encoded))
    }

    func testRunCycleFaces() throws {
        var p = try pose()
        p.step(left: false, right: false, run: false)
        // Run held: +2 per frame from 0xc + 2 → 1024[7], 1024[8] …; no turn check on the run arm (the flat-floor
        // 12-face cycle with its wrap past 0x17 is pinned by `PlayerStateTests.testRunFootstepFrames`).
        // ⚑ P3 (re-measured, Invariant-10 ruling; was 24 × 1024[7…11, 0…11, 0…6] running in place, then a reversal
        // drawn 1024 mirrored): the real player runs off the start ledge on frame 5 (1010[5]) and clings to the pit's
        // far wall from frame 7 at x 146 (1012[0]); the reversal (LEFT + RUN) leaves the cling as it is — 1012[0],
        // facing right (`+0x17e` 0: the wall is on the right).
        let seen = faces(&p, frames: 24, right: true, run: true)
        XCTAssertEqual(seen, [fr(1024, 7), fr(1024, 8), fr(1024, 9), fr(1024, 10), fr(1010, 5), fr(1010, 5)]
                       + [FaceRef?](repeating: fr(1012, 0), count: 18))
        XCTAssertEqual(p.sprite.x, 146)
        p.step(left: true, right: false, run: true)
        XCTAssertEqual(p.face, fr(1012, 0))
        XCTAssertFalse(p.mirrored)
    }

    func testTurnSequence() throws {
        var p = try pose()
        _ = faces(&p, frames: 2)
        var turn: [(FaceRef?, Bool, Bool)] = []
        for _ in 0..<6 {
            p.step(left: true, right: false, run: false)
            turn.append((p.face, p.turnFlag, p.mirrored))
        }
        // F 2 → 1 (vx −335 < 0, |vx| ≤ 0x5db): the walk arm fails, the stand arm starts countdown 4: 1030[0], [1], [2]
        // with the turn flag (drawn with the OLD facing — +0x17e toggled back to right), then [1], [0] facing left;
        // frame 6 walks (phase 0xc + 2 → 1020[7]). Unchanged with the real player (he walks left, away from the pit).
        XCTAssertEqual(turn.map { $0.0 }, [
            FaceRef(pict: 1030, index: 0, set: .encoded), FaceRef(pict: 1030, index: 1, set: .encoded),
            FaceRef(pict: 1030, index: 2, set: .encoded), FaceRef(pict: 1030, index: 1, set: .encoded),
            FaceRef(pict: 1030, index: 0, set: .encoded), FaceRef(pict: 1020, index: 7, set: .encoded),
        ])
        XCTAssertEqual(turn.map { $0.1 }, [true, true, true, false, false, false])
        XCTAssertEqual(turn.map { $0.2 }, [false, false, false, true, true, true])
        XCTAssertEqual(p.facing, 1)
        // A turn back to the right after one release frame.
        // ⚑ P3 (re-measured, Invariant-10 ruling; was 1030[0, 1, 2, 1, 0] mirrored 1, 1, 1, 0, 0 from a standstill):
        // the release frame decelerates −1635 → −835 (stand 1003[3]); the first RIGHT frame brings vx to 0 without
        // turning F (F changes only on vx > 0), so the walk arm draws 1020[7] facing left; vx 665 on the next frame
        // turns F → 2 and the turn runs 1030[0], [1], [2] with the flag, then [1] facing right.
        p.step(left: false, right: false, run: false)
        XCTAssertEqual(p.face, fr(1003, 3))
        let back = (0..<5).map { _ -> (FaceRef?, Bool) in
            p.step(left: false, right: true, run: false); return (p.face, p.mirrored)
        }
        XCTAssertEqual(back.map { $0.0 }, [fr(1020, 7), fr(1030, 0), fr(1030, 1), fr(1030, 2), fr(1030, 1)])
        XCTAssertEqual(back.map { $0.1 }, [true, true, true, true, false])
    }

    // MARK: - Camera

    func testCameraStartScroll() throws {
        let L = try level1()
        // `.GameLoop` l. 5168–5195: the camera state (fd84+2, fd84) starts at the sprite origin − 0xd0.
        var cam = try Camera(header: L.header, spriteX: 83, spriteY: 143)
        XCTAssertEqual(cam.h, 83 - 0xd0)
        XCTAssertEqual(cam.v, 143 - 0xd0)
        XCTAssertEqual(cam.maxH, 5760)
        XCTAssertEqual(cam.maxV, 1216)
        // The focus base (⚑ plan note 10): `.FindUpperLeftCorner` reads (fd44, fd40), which `.SetupPlayerSprite`
        // sets to the sprite origin (83, 143); `.PlayerScroll` moves it to the hot-rect centre (fd94, fd90) =
        // origin + (50, 59) = (133, 202) on the first Handle (R5's measurement: a player standing at the origin's
        // centre; the session's player is lifted on frame 1 — `testPlayerStartPose`).
        XCTAssertEqual([83 + 0x32, 143 + 0x3b], [133, 202])
        // Level start (l. 5209): ease from (−125, −65) toward (−224, −49): (−141, −63) → scroll (0, 0).
        cam.findUpperLeftCorner(focusX: 83, focusY: 143)
        XCTAssertEqual([cam.h, cam.v, cam.scrollH, cam.scrollV], [-141, -63, 0, 0])
        // Iteration 1 (still the origin focus: `.PlayerScroll` runs in `.HandleSprites`, after the draw).
        cam.findUpperLeftCorner(focusX: 83, focusY: 143)
        XCTAssertEqual([cam.h, cam.v, cam.scrollH, cam.scrollV], [-154, -61, 0, 0])
        // Then the pan-in toward target (−176 after the 16-px snap, 10): v climbs by max(Δ/6, 1).
        var vs: [Int] = []
        for _ in 0..<40 {
            cam.findUpperLeftCorner(focusX: 133, focusY: 202, playerVX: 0)
            vs.append(cam.scrollV)
        }
        XCTAssertEqual(Array(vs.prefix(14)), [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 2])
        let settle = try XCTUnwrap(vs.firstIndex(of: 10))
        XCTAssertEqual(settle, 21)                           // the 24th FindUpperLeftCorner of the level
        XCTAssertEqual(vs.last, 10)
        XCTAssertEqual(cam.scrollH, 0)
        XCTAssertEqual(cam.h, -176)
        // Clamps (tail of `.FindUpperLeftCorner`): 0 ≤ h ≤ 32·200 − 640, 0 ≤ v ≤ 32·50 − 384.
        for _ in 0..<200 { cam.findUpperLeftCorner(focusX: 30_000, focusY: 30_000) }
        XCTAssertEqual([cam.scrollH, cam.scrollV], [5760, 1216])
        for _ in 0..<200 { cam.findUpperLeftCorner(focusX: -9_999, focusY: -9_999) }
        XCTAssertEqual([cam.scrollH, cam.scrollV], [0, 0])
        // Graphics modes 2 and 3 force an even v; the snap needs |vx| < 0x100.
        var odd = try Camera(header: L.header, spriteX: 83, spriteY: 143)
        for _ in 0..<60 { odd.findUpperLeftCorner(focusX: 400, focusY: 299, graphics: 2) }
        XCTAssertEqual(odd.scrollV % 2, 0)
        var snap = try Camera(header: L.header, spriteX: 1000, spriteY: 143)
        for _ in 0..<200 { snap.findUpperLeftCorner(focusX: 992 + 0x130 + 7, focusY: 400) }
        XCTAssertEqual(snap.h, 992)
        for _ in 0..<200 { snap.findUpperLeftCorner(focusX: 992 + 0x130 + 7, focusY: 400, playerVX: 1900) }
        XCTAssertEqual(snap.h, 999)
        // The snap vetoes (P5, raw `1000b894..1000b944`): riding a 0x57a, water `+0x11c`/`+0x120`, or the one-shot
        // `*_DAT_1009fd34`, which the snap test clears (returned); an unarmed snap (`uRam100a5114` 0) or |vx| ≥ 0x100
        // leaves the latch as it was.
        var veto = snap
        XCTAssertFalse(veto.findUpperLeftCorner(focusX: 992 + 0x130 + 7, focusY: 400, ridingVeto: true))
        XCTAssertEqual(veto.h, 999)
        XCTAssertFalse(veto.findUpperLeftCorner(focusX: 992 + 0x130 + 7, focusY: 400, inWater: true))
        XCTAssertEqual(veto.h, 999)
        XCTAssertFalse(veto.findUpperLeftCorner(focusX: 992 + 0x130 + 7, focusY: 400, latch: true))
        XCTAssertEqual(veto.h, 999)
        XCTAssertTrue(veto.findUpperLeftCorner(focusX: 992 + 0x130 + 7, focusY: 400, snapArmed: false, latch: true))
        XCTAssertTrue(veto.findUpperLeftCorner(focusX: 992 + 0x130 + 7, focusY: 400, playerVX: -0x100, latch: true))
        XCTAssertEqual(veto.h, 999)
        XCTAssertFalse(veto.findUpperLeftCorner(focusX: 992 + 0x130 + 7, focusY: 400, playerVX: 0xff))
        XCTAssertEqual(veto.h, 998)                          // snapped target 992: 999 − max(7 / 6, 1)
    }

    // MARK: - FerazelSession.step

    func testStepOrderAndSkippedDraw() throws {
        let r = try resources()
        let session = try FerazelSession(resources: r, prefs: FerazelPrefs(), level: 1)
        let first = session.step(keys: KeyState())
        func kinds(_ ops: [DrawOp]) -> [String] {
            ops.map { op in
                switch op {
                case .setScreenClut: return "clut"
                case .drawPicture: return "picture"
                case .redrawScrollGrid: return "grid"
                case .redrawEntireScrollGrid: return "entire"
                case .drawLightsOntoTiles: return "lights"
                case .wrapDrawSprites: return "sprites"
                case .copyToScreen: return "copy"
                case .changeLightFace: return "lightFace"
                case .wrapEraseSprites: return "erase"
                case .statusBar: return "status"
                case .gammaStep: return "gamma"
                case .setTile: return "setTile"
                }
            }
        }
        // Level start (`.SetupLevel` l. 2571–2582, `.GameLoop` l. 5203–5221), then iteration 1 (l. 5224–5290).
        // `.HandleSprites` runs between the copy and the erase: the active potion's light twinkle (`BonusHandle`).
        XCTAssertEqual(kinds(first.draws), ["clut", "picture", "entire", "grid", "entire", "status",
                                            "grid", "lights", "sprites", "copy", "lightFace", "erase", "status"])
        XCTAssertEqual(first.draws[0], .setScreenClut(id: 202))
        XCTAssertEqual(first.draws[1], .drawPicture(id: 129, chain: .frontEnd, h: 0, v: 0))
        XCTAssertEqual(first.draws[2], .redrawEntireScrollGrid(h: 0, v: 0))
        XCTAssertEqual(first.draws[3], .redrawScrollGrid(h: 0, v: 0))
        XCTAssertEqual(first.draws[4], .redrawEntireScrollGrid(h: 0, v: 0))
        let start = StatusBarState(score: 0, coins: 0, health: 560, breath: 560, magic: 560,
                                   levelName: "A Scent Of Peril", selectedSlot: 0)
        XCTAssertEqual(first.draws[5], .statusBar(start))
        XCTAssertEqual(first.draws[9], .copyToScreen(h: 0, v: 0, graphicsMode: 1, backdrop: true))
        XCTAssertEqual(first.draws[10], .changeLightFace(slot: 24, pict: 0x32b, width: 0x48, height: 0x48)) // seed 1: 6 → 7, k 1
        XCTAssertEqual(first.draws[12], .statusBar(start))
        XCTAssertEqual(first.music, [.play(track: 1)])
        XCTAssertEqual(first.requests, [.hideMenuBar, .hideCursor])
        XCTAssertTrue(first.drawn)
        XCTAssertTrue(first.sounds.isEmpty)
        // Iteration 1 draws the 10 spawned-now sprites; the player's face is still 0 (`.SetupPlayerSprite`).
        guard case .wrapDrawSprites(let drawn1) = first.draws[8] else { return XCTFail("sprites") }
        XCTAssertEqual(drawn1.count, 10)
        XCTAssertFalse(drawn1.contains { $0.face.pict == 1003 })
        guard case .wrapEraseSprites(let sprites1, let eh, let ev) = first.draws[11] else { return XCTFail("erase") }
        XCTAssertEqual([eh, ev], [0, 0])
        XCTAssertEqual(sprites1, session.active.sprites)
        let player = try XCTUnwrap(session.active.sprite(id: session.playerID))
        XCTAssertEqual(player.face, FaceRef(pict: 1003, index: 3, set: .encoded))
        XCTAssertEqual(player.layer, 10)
        XCTAssertEqual(session.lights.count, 68)

        // Iteration 2: no level-start ops; the player is drawn.
        let second = session.step(keys: KeyState())
        XCTAssertEqual(kinds(second.draws), ["grid", "lights", "sprites", "copy", "lightFace", "erase", "status"])
        XCTAssertTrue(second.music.isEmpty && second.requests.isEmpty)
        guard case .wrapDrawSprites(let drawn2) = second.draws[2] else { return XCTFail("sprites") }
        XCTAssertTrue(drawn2.contains { $0.face == FaceRef(pict: 1003, index: 3, set: .encoded) && $0.x == 83 })

        // prefs[0] "Reduce frame rate": the FIRST iteration skips (odd starts false), then they alternate. A skipped
        // draw omits only `.WrapCopyToScreen` (`.PaintFrameWrap` l. 9254–9450); tiles, lights, sprites, erase run.
        var slow = FerazelPrefs()
        slow.reduceFrameRate = 1
        let s = try FerazelSession(resources: r, prefs: slow, level: 1)
        let steps = (0..<4).map { _ in s.step(keys: KeyState()) }
        XCTAssertEqual(steps.map(\.drawn), [false, true, false, true])
        XCTAssertEqual(kinds(steps[0].draws), ["clut", "picture", "entire", "grid", "entire", "status",
                                               "grid", "lights", "sprites", "lightFace", "erase", "status"])
        XCTAssertEqual(kinds(steps[1].draws), ["grid", "lights", "sprites", "copy", "lightFace", "erase", "status"])
        XCTAssertEqual(kinds(steps[2].draws), ["grid", "lights", "sprites", "lightFace", "erase", "status"])

        // Effects 3 (Reduced) drops `.DrawLightsOntoTiles`; Low Detail / plain copy reach the copy's arguments.
        var reduced = FerazelPrefs()
        reduced.effects = 3
        reduced.graphics = 2
        reduced.plainCopy = 1
        let e = try FerazelSession(resources: r, prefs: reduced, level: 1)
        _ = e.step(keys: KeyState())
        let e2 = e.step(keys: KeyState())
        XCTAssertEqual(kinds(e2.draws), ["grid", "sprites", "copy", "erase", "status"])
        XCTAssertEqual(e2.draws[2], .copyToScreen(h: 0, v: 0, graphicsMode: 2, backdrop: false))

        // The keys drive the player; his Handle's look-ahead row and `.PlayerScroll` move the focus (P5; the arrow
        // keys of the Phase-1 ◇ focus driver are gone): keypad 6 (action 1, `FerazelPrefs.defaultKeys`) walks.
        let k = try FerazelSession(resources: r, prefs: FerazelPrefs(), level: 1)
        _ = k.step(keys: KeyState())
        _ = k.step(keys: KeyState(pressed: [0x58]))
        let kp = k.player, ks = try XCTUnwrap(k.active.sprite(id: k.playerID))
        // Frame 2: vx 665 (the walk's first step), L = 665 >> 2 = 166; centre x = 85 + 0x26 + 12 = 135 (x256 21913),
        // fd44 = 135 + (166 >> 8) = 135; grounded with the latch set → path B: fd40 = fd90 = 123 + 0x22 + 25 = 182.
        XCTAssertEqual([ks.vx, ks.x256, kp.lookAhead], [665, 21913, 166])
        XCTAssertEqual([kp.centreX, kp.centreY, kp.focusX, kp.focusY, kp.groundCentreY], [135, 182, 135, 182, 182])
        XCTAssertTrue(kp.scrollLatch && kp.snapArmed && !kp.scrollEasing)
        XCTAssertEqual([kp.scrollH, kp.scrollV], [k.camera.scrollH, k.camera.scrollV])
        XCTAssertEqual(k.active.sprite(id: k.playerID)?.face, FaceRef(pict: 1020, index: 7, set: .encoded))
    }

    // MARK: - `.HandleBonusSprite`'s item-light twinkle

    func testItemLightTwinkle() throws {
        // The potion 0xc84 at (291, 123) adds light 24 (PICT 0x32a, 72×72, colour 99) and keeps its slot in `+0x9a`.
        let r = try resources()
        let session = try FerazelSession(resources: r, prefs: FerazelPrefs(), level: 1)
        XCTAssertEqual(session.lights[24], SetupFaces.Light(pict: 0x32a, width: 0x48, height: 0x48, x: 307, y: 135,
                                                            colour: 99))
        let placed = session.active.sprites + session.idle.entries.compactMap { $0?.saved }
        let potion = try XCTUnwrap(placed.first { $0.type == 0xc84 })
        XCTAssertEqual(potion.light, 24)
        XCTAssertEqual(potion.phase, 6)                         // seed 1: the Setup's `FastRand(0x10)` (raw `1005e724`)

        // +0x46 += 1, k = (+0x46 >> 2) mod 6 → faces 0, 1, 2, 3, 2, 1 of 0x32a…0x32d, four calls each (1005f834..).
        // From phase 6: 7 → k 1; 8–11 → 2; 12–15 → 3; 16–19 → 4; 20–23 → 5; 24–27 → 0; 28–31 → 1; 32–34 → 2.
        var s = potion
        let seq = (0..<28).map { _ in BonusHandle.twinkle(&s, effects: 1) }
        let picts = seq.map { op -> Int16? in
            guard case .changeLightFace(24, let p, 0x48, 0x48)? = op else { return nil }
            return p
        }
        XCTAssertEqual(picts, [0x32b] + [Int16](repeating: 0x32c, count: 4)
                       + [Int16](repeating: 0x32d, count: 4) + [Int16](repeating: 0x32c, count: 4)
                       + [Int16](repeating: 0x32b, count: 4) + [Int16](repeating: 0x32a, count: 4)
                       + [Int16](repeating: 0x32b, count: 4) + [Int16](repeating: 0x32c, count: 3))
        // Effects 3 takes the other branch (no call, no count); no light (`+0x9a` −1) counts but changes nothing; the
        // Int16 counter wraps negative and the truncating mod gives k < 0 → no call; a non-item does nothing.
        var e3 = potion
        XCTAssertNil(BonusHandle.twinkle(&e3, effects: 3))
        XCTAssertEqual(e3.phase, 6)
        var dark = potion
        dark.light = -1
        XCTAssertNil(BonusHandle.twinkle(&dark, effects: 1))
        XCTAssertEqual(dark.phase, 7)
        var wrap = potion
        wrap.phase = .max
        XCTAssertNil(BonusHandle.twinkle(&wrap, effects: 1))
        XCTAssertEqual(wrap.phase, .min)
        var torch = potion
        torch.type = 0x51b
        XCTAssertNil(BonusHandle.twinkle(&torch, effects: 1))

        // In the session: one op per step for slot 24 while the potion is active; none at Effects 3.
        let ops = (0..<8).map { _ in session.step(keys: KeyState()).draws.filter {
            if case .changeLightFace = $0 { return true } else { return false } } }
        XCTAssertEqual(ops.map(\.count), [Int](repeating: 1, count: 8))
        XCTAssertEqual(ops[3], [.changeLightFace(slot: 24, pict: 0x32c, width: 0x48, height: 0x48)])   // phase 10, k 2
        var reduced = FerazelPrefs()
        reduced.effects = 3
        let e = try FerazelSession(resources: r, prefs: reduced, level: 1)
        XCTAssertFalse((0..<8).contains { _ in e.step(keys: KeyState()).draws.contains {
            if case .changeLightFace = $0 { return true } else { return false } } })
    }
}
