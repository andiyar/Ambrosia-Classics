import XCTest
import HectorResources
@testable import FerazelCore

/// R5 (docs/plans/2026-10-06-ferazel-phase1.md): the ◇ player pose (player-states §3.11, transcribed from
/// `.HandlePlayerSprite @ 1004d5fc`), the camera (`.FindUpperLeftCorner @ 1000b5ec`, engine §5) with the ◇ focus
/// driver, and one `.GameLoop @ 10009d48` iteration in `.PaintFrameWrap @ 10011cf8` order — against the committed
/// `Resources/Ferazel` (D26). A missing data file is a FAILURE, never a skip.
final class SessionTests: XCTestCase {

    private func resources() throws -> FerazelResources { try FerazelData.open(try FerazelData.dataDirectory()) }

    private func level1() throws -> LevelFile { try LevelFile.load(from: try resources(), level: 1) }

    private func pose() throws -> PlayerPose { PlayerPose(header: try level1().header) }

    private func faces(_ p: inout PlayerPose, frames: Int, left: Bool = false, right: Bool = false,
                       run: Bool = false) -> [FaceRef?] {
        (0..<frames).map { _ in p.step(left: left, right: right, run: run); return p.face }
    }

    // MARK: - PlayerPose

    func testPlayerStartPose() throws {
        var p = try pose()
        // `.GameLoop(hdr+0x2848 − 0x20, hdr+0x2846 − 0x20, …)` (`.NewGame` l. 5823) → `MTNewSprite(0, x, y, 10, …)`.
        XCTAssertEqual(p.x, 83)
        XCTAssertEqual(p.y, 143)
        XCTAssertEqual(PlayerPose.layer, 10)
        XCTAssertEqual(p.facing, .right)                     // G+0x16 = hdr 0x26c8 = 0 → F = 2, +0x17e = 0
        XCTAssertFalse(p.mirrored)
        XCTAssertNil(p.face)                                 // `.SetupPlayerSprite`: +0xc0 = 0 until the first Handle
        XCTAssertEqual(p.slot.layer, 10)
        XCTAssertEqual(p.hotRect, IdleSprites.Rect(top: 143 + 0x22, left: 83 + 0x26, bottom: 143 + 0x55,
                                                   right: 83 + 0x3e))
        // First Handle: stand entry forces chest frame 3 → face 1003[3]; then the breathing triangle (phase 4 → 2,
        // phase 5 → 1 after the 7-frame calm period, then held at 1: `.HandleBreathing @ 1004bb44`).
        let seen = faces(&p, frames: 10)
        XCTAssertEqual(seen.first, FaceRef(pict: 1003, index: 3, set: .encoded))
        XCTAssertEqual(seen.map { $0?.index }, [3, 2, 2, 2, 2, 2, 2, 1, 1, 1])
        XCTAssertTrue(seen.allSatisfy { $0?.pict == 1003 })
        XCTAssertFalse(p.mirrored)
        XCTAssertEqual(p.slot.face, FaceRef(pict: 1003, index: 1, set: .encoded))
        XCTAssertEqual(p.slot.x, 83)
        XCTAssertEqual(p.slot.y, 143)
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
        // (handler l. 2088–2120) → 0xe → face 1020[7]; then +2 per frame, wrap past 0x1f to 0.
        let seen = faces(&p, frames: 20, right: true)
        let expected = (0..<20).map { k -> Int in ((0xe + 2 * k) % 0x20) >> 1 }
        XCTAssertEqual(seen.map { $0?.index }, expected)
        XCTAssertEqual(Array(expected.prefix(10)), [7, 8, 9, 10, 11, 12, 13, 14, 15, 0])
        XCTAssertTrue(seen.allSatisfy { $0?.pict == 1020 })
        XCTAssertFalse(p.mirrored)
        XCTAssertEqual(p.idle, 0)                            // `.HandleKeys` zeroes idle on L/R
        // Release: back to standing with chest frame 3 on entry.
        p.step(left: false, right: false, run: false)
        XCTAssertEqual(p.face, FaceRef(pict: 1003, index: 3, set: .encoded))
        // Walk again: the phase restarts at 0xc (+2).
        p.step(left: false, right: true, run: false)
        XCTAssertEqual(p.face, FaceRef(pict: 1020, index: 7, set: .encoded))
    }

    func testRunCycleFaces() throws {
        var p = try pose()
        p.step(left: false, right: false, run: false)
        // Run held: +2 per frame, wrap past 0x17 to 0 → the 12 faces of 1024; no turn check on the run arm.
        let seen = faces(&p, frames: 24, right: true, run: true)
        let expected = (0..<24).map { k -> Int in ((0xe + 2 * k) % 0x18) >> 1 }
        XCTAssertEqual(seen.map { $0?.index }, expected)
        XCTAssertEqual(Array(expected.prefix(6)), [7, 8, 9, 10, 11, 0])
        XCTAssertEqual(Set(expected).count, 12)
        XCTAssertTrue(seen.allSatisfy { $0?.pict == 1024 })
        // A reversal while running does not turn: the run arm returns before the turn test.
        p.step(left: true, right: false, run: true)
        XCTAssertEqual(p.face?.pict, 1024)
        XCTAssertTrue(p.mirrored)
    }

    func testTurnSequence() throws {
        var p = try pose()
        _ = faces(&p, frames: 2)
        var turn: [(FaceRef?, Bool, Bool)] = []
        for _ in 0..<6 {
            p.step(left: true, right: false, run: false)
            turn.append((p.face, p.turnFlag, p.mirrored))
        }
        // F 2 → 1 with no velocity (Phase 1: no physics): the walk arm fails, the stand arm starts countdown 4:
        // 1030[0], [1], [2] with the turn flag (drawn with the OLD facing — +0x17e toggled back to right), then
        // [1], [0] facing left; frame 6 walks (phase 0xc + 2 → 1020[7]).
        XCTAssertEqual(turn.map { $0.0 }, [
            FaceRef(pict: 1030, index: 0, set: .encoded), FaceRef(pict: 1030, index: 1, set: .encoded),
            FaceRef(pict: 1030, index: 2, set: .encoded), FaceRef(pict: 1030, index: 1, set: .encoded),
            FaceRef(pict: 1030, index: 0, set: .encoded), FaceRef(pict: 1020, index: 7, set: .encoded),
        ])
        XCTAssertEqual(turn.map { $0.1 }, [true, true, true, false, false, false])
        XCTAssertEqual(turn.map { $0.2 }, [false, false, false, true, true, true])
        XCTAssertEqual(p.facing, .left)
        // A turn back to the right while standing: same five frames, mirrored the other way.
        p.step(left: false, right: false, run: false)
        let back = (0..<5).map { _ -> (Int?, Bool) in
            p.step(left: false, right: true, run: false); return (p.face?.index, p.mirrored)
        }
        XCTAssertEqual(back.map { $0.0 }, [0, 1, 2, 1, 0])
        XCTAssertEqual(back.map { $0.1 }, [true, true, true, false, false])
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
        // origin + (50, 59) = (133, 202) on the first Handle.
        var driver = CameraFocusDriver(spriteX: 83, spriteY: 143)
        XCTAssertEqual(driver.focusX, 83)
        XCTAssertEqual(driver.focusY, 143)
        XCTAssertEqual(driver.pointX, 133)
        XCTAssertEqual(driver.pointY, 202)
        // Level start (l. 5209): ease from (−125, −65) toward (−224, −49): (−141, −63) → scroll (0, 0).
        cam.findUpperLeftCorner(focusX: driver.focusX, focusY: driver.focusY)
        XCTAssertEqual([cam.h, cam.v, cam.scrollH, cam.scrollV], [-141, -63, 0, 0])
        // Iteration 1 (still the origin focus: `.PlayerScroll` runs in `.HandleSprites`, after the draw).
        cam.findUpperLeftCorner(focusX: driver.focusX, focusY: driver.focusY)
        XCTAssertEqual([cam.h, cam.v, cam.scrollH, cam.scrollV], [-154, -61, 0, 0])
        driver.step(keys: KeyState(), prefs: FerazelPrefs())
        XCTAssertEqual([driver.focusX, driver.focusY], [133, 202])
        // Then the pan-in toward target (−176 after the 16-px snap, 10): v climbs by max(Δ/6, 1).
        var vs: [Int] = []
        for _ in 0..<40 {
            cam.findUpperLeftCorner(focusX: driver.focusX, focusY: driver.focusY, playerVX: driver.vx)
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
                case .wrapEraseSprites: return "erase"
                case .statusBar: return "status"
                }
            }
        }
        // Level start (`.SetupLevel` l. 2571–2582, `.GameLoop` l. 5203–5221), then iteration 1 (l. 5224–5290).
        XCTAssertEqual(kinds(first.draws), ["clut", "picture", "entire", "grid", "entire", "status",
                                            "grid", "lights", "sprites", "copy", "erase", "status"])
        XCTAssertEqual(first.draws[0], .setScreenClut(id: 202))
        XCTAssertEqual(first.draws[1], .drawPicture(id: 129, chain: .frontEnd, h: 0, v: 0))
        XCTAssertEqual(first.draws[2], .redrawEntireScrollGrid(h: 0, v: 0))
        XCTAssertEqual(first.draws[3], .redrawScrollGrid(h: 0, v: 0))
        XCTAssertEqual(first.draws[4], .redrawEntireScrollGrid(h: 0, v: 0))
        let start = StatusBarState(score: 0, coins: 0, health: 560, breath: 560, magic: 560,
                                   levelName: "A Scent Of Peril", selectedSlot: 0)
        XCTAssertEqual(first.draws[5], .statusBar(start))
        XCTAssertEqual(first.draws[9], .copyToScreen(h: 0, v: 0, graphicsMode: 1, backdrop: true))
        XCTAssertEqual(first.draws[11], .statusBar(start))
        XCTAssertEqual(first.music, [.play(track: 1)])
        XCTAssertEqual(first.requests, [.hideMenuBar, .hideCursor])
        XCTAssertTrue(first.drawn)
        XCTAssertTrue(first.sounds.isEmpty)
        // Iteration 1 draws the 10 spawned-now sprites; the player's face is still 0 (`.SetupPlayerSprite`).
        guard case .wrapDrawSprites(let drawn1) = first.draws[8] else { return XCTFail("sprites") }
        XCTAssertEqual(drawn1.count, 10)
        XCTAssertFalse(drawn1.contains { $0.face.pict == 1003 })
        guard case .wrapEraseSprites(let sprites1, let eh, let ev) = first.draws[10] else { return XCTFail("erase") }
        XCTAssertEqual([eh, ev], [0, 0])
        XCTAssertEqual(sprites1, session.active.sprites)
        let player = try XCTUnwrap(session.active.sprite(id: session.playerID))
        XCTAssertEqual(player.face, FaceRef(pict: 1003, index: 3, set: .encoded))
        XCTAssertEqual(player.layer, 10)
        XCTAssertEqual(session.lights.count, 68)

        // Iteration 2: no level-start ops; the player is drawn.
        let second = session.step(keys: KeyState())
        XCTAssertEqual(kinds(second.draws), ["grid", "lights", "sprites", "copy", "erase", "status"])
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
                                               "grid", "lights", "sprites", "erase", "status"])
        XCTAssertEqual(kinds(steps[1].draws), ["grid", "lights", "sprites", "copy", "erase", "status"])
        XCTAssertEqual(kinds(steps[2].draws), ["grid", "lights", "sprites", "erase", "status"])

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

        // The keys drive the stub: right arrow walks in place and moves the focus 1900/256 px per frame.
        let k = try FerazelSession(resources: r, prefs: FerazelPrefs(), level: 1)
        _ = k.step(keys: KeyState())
        _ = k.step(keys: KeyState(pressed: [CameraFocusDriver.arrowRight]))
        XCTAssertEqual(k.focusDriver.pointX256, (133 << 8) + 1900)
        XCTAssertEqual(k.active.sprite(id: k.playerID)?.face, FaceRef(pict: 1020, index: 7, set: .encoded))
    }
}
