import XCTest
@testable import FerazelCore

/// P5 (docs/plans/2026-10-10-ferazel-phase2.md): `.PlayerScroll @ 1004c528` (raw `1004c528..1004c808`, decompile
/// l. 43754–43851; engine §5) and the look-ahead row before it in `.HandlePlayerSprite` (raw `10051494..1005158c`,
/// l. 46393–46422; triggers-background-2 §8.2). The plan's hand arithmetic (PS1–PS5, LA1–LA5) on a bare
/// `PlayerState`: the scroll point `PTR_DAT_1009fe78` = (`scrollH`, `scrollV`), the centre (`fd94`, `fd90`), the focus
/// (`fd44`, `fd40`), ground y `_DAT_100a0740`, latch `DAT_100a5f58`, easing `_DAT_100a06dc`, look-ahead
/// `_DAT_100a0680`. The band is (scrollV + 16, scrollH, scrollV + 0x180 − 0x60, scrollH + 0x260), `PtInRect`.
final class PlayerScrollTests: XCTestCase {

    /// A player at centre (300, y) with the scroll point (0, scrollV).
    private func state(y: Int16, focusY: Int16, groundY: Int16, latch: Bool, scrollV: Int = 0) -> PlayerState {
        var p = PlayerState()
        p.centreX = 300
        p.centreY = y
        p.focusX = 0
        p.focusY = focusY
        p.groundCentreY = groundY
        p.scrollLatch = latch
        p.scrollH = 0
        p.scrollV = scrollV
        return p
    }

    // MARK: - .PlayerScroll

    func testGroundedExactFollow() {
        // PS1: grounded (`+0xce` ≠ 0) skips the freeze; the latch (1 from `.ClearPlayerVars`) takes path B:
        // easing 0, fd40 = fd90 exactly, every frame. fd44 = fd94 + (L >> 8).
        var p = state(y: 250, focusY: 202, groundY: 250, latch: true)
        p.lookAhead = 0x1234
        p.scrollEasing = true
        PlayerScroll.scroll(&p, groundKind: 4, inWind: false)
        XCTAssertEqual(p.focusX, 318)
        XCTAssertEqual(p.focusY, 250)
        XCTAssertFalse(p.scrollEasing)
        XCTAssertTrue(p.scrollLatch)
        for y: Int16 in [251, 263, 240] {
            p.centreY = y
            p.groundCentreY = y
            PlayerScroll.scroll(&p, groundKind: 4, inWind: false)
            XCTAssertEqual(p.focusY, y)
        }
        // A latched player out of the freeze (in wind `+0x92`, airborne) follows exactly too.
        p.centreY = 100
        PlayerScroll.scroll(&p, groundKind: 0, inWind: true)
        XCTAssertEqual(p.focusY, 100)
    }

    func testJumpFreeze() {
        // PS2: airborne, nothing set, in band, fd90 ≤ ground y → path A: the focus holds, the latch drops to 0.
        var p = state(y: 190, focusY: 202, groundY: 202, latch: true)
        PlayerScroll.scroll(&p, groundKind: 0, inWind: false)
        XCTAssertEqual(p.focusY, 202)
        XCTAssertFalse(p.scrollLatch)
        XCTAssertFalse(p.scrollEasing)
        for y: Int16 in [170, 150, 202] {
            p.centreY = y
            PlayerScroll.scroll(&p, groundKind: 0, inWind: false)
            XCTAssertEqual(p.focusY, 202)
            XCTAssertFalse(p.scrollLatch)
        }
        // The x still follows: fd44 = fd94 + (L >> 8).
        XCTAssertEqual(p.focusX, 300)
        // Each freeze veto sends a latched frame to path B instead (exact follow): rope, swim, jump base.
        var q = state(y: 190, focusY: 202, groundY: 202, latch: false)
        q.swim = 1
        PlayerScroll.scroll(&q, groundKind: 0, inWind: false)
        XCTAssertEqual(q.focusY, 190)
        XCTAssertFalse(q.scrollLatch)
        // fd90 = ground y still freezes (`cmpw r0,r3; bgt` at `1004c660`: only fd90 > ground y skips), latch dropped.
        var eq = state(y: 202, focusY: 190, groundY: 202, latch: true)
        PlayerScroll.scroll(&eq, groundKind: 0, inWind: false)
        XCTAssertEqual(eq.focusY, 190)
        XCTAssertFalse(eq.scrollLatch)
        // Vetoes of the freeze only (ridden `0558`, easing `06dc`: not in path B's list) → path C, up by
        // max((230 − 195) / 7, 5): 225, easing 1 (a freeze would hold 230). The rope `0588` vetoes both → path B, exact.
        var ridden = state(y: 190, focusY: 230, groundY: 195, latch: false)
        ridden.ridden = 5
        PlayerScroll.scroll(&ridden, groundKind: 0, inWind: false)
        XCTAssertEqual(ridden.focusY, 225)
        XCTAssertTrue(ridden.scrollEasing)
        var easing = state(y: 190, focusY: 230, groundY: 195, latch: false)
        easing.scrollEasing = true
        PlayerScroll.scroll(&easing, groundKind: 0, inWind: false)
        XCTAssertEqual(easing.focusY, 225)
        XCTAssertTrue(easing.scrollEasing)
        var rope = state(y: 190, focusY: 230, groundY: 195, latch: false)
        rope.rope = true
        PlayerScroll.scroll(&rope, groundKind: 0, inWind: false)
        XCTAssertEqual(rope.focusY, 190)
        XCTAssertFalse(rope.scrollEasing)
    }

    func testFallEaseDown() {
        // PS3: below ground y with the latch 0 → path C, down: focus += max(Δ / 6, 6) (mulhw 0x2aaaaaab, raw
        // `1004c728..1004c74c`). scrollV = 64: the band is rows 80..352, so 230 / 240 / 300 are in band.
        var p = state(y: 230, focusY: 202, groundY: 202, latch: false, scrollV: 64)
        var got: [Int16] = []
        for y: Int16 in [230, 240, 300] {
            p.centreY = y
            PlayerScroll.scroll(&p, groundKind: 0, inWind: false)
            got.append(p.focusY)
            XCTAssertTrue(p.scrollEasing)
            XCTAssertFalse(p.scrollLatch)
        }
        XCTAssertEqual(got, [208, 214, 228])
        // Catching up: focus ≥ y → easing 0, latch 1, focus = y (raw `1004c770..1004c77c`).
        p.focusY = 296
        PlayerScroll.scroll(&p, groundKind: 0, inWind: false)
        XCTAssertEqual(p.focusY, 300)
        XCTAssertFalse(p.scrollEasing)
        XCTAssertTrue(p.scrollLatch)
        // Landing exactly on fd90 ends the ease (`cmpw r0,r4; blt` at `1004c768`: only focus < fd90 keeps easing):
        // 196 + max(6 / 6, 6) = 202.
        var x = state(y: 202, focusY: 196, groundY: 150, latch: false, scrollV: 64)
        PlayerScroll.scroll(&x, groundKind: 0, inWind: false)
        XCTAssertEqual(x.focusY, 202)
        XCTAssertFalse(x.scrollEasing)
        XCTAssertTrue(x.scrollLatch)
    }

    func testLandHigherEaseUp() {
        // PS4: landed (grounded) above the focus with the latch 0 → path C, up: focus −= max((focus − groundY) / 7, 5)
        // — divided by the distance to ground y, not to fd90 (raw `1004c788..1004c7b8`, mulhw 0x92492493).
        var p = state(y: 140, focusY: 210, groundY: 150, latch: false)
        var got: [Int16] = []
        for _ in 0..<11 {
            PlayerScroll.scroll(&p, groundKind: 4, inWind: false)
            got.append(p.focusY)
            if got.count < 11 {
                XCTAssertTrue(p.scrollEasing)
                XCTAssertFalse(p.scrollLatch)
            }
        }
        XCTAssertEqual(got, [202, 195, 189, 184, 179, 174, 169, 164, 159, 154, 150])
        XCTAssertFalse(p.scrollEasing)
        XCTAssertTrue(p.scrollLatch)
        // Latched again: path B, exact.
        PlayerScroll.scroll(&p, groundKind: 4, inWind: false)
        XCTAssertEqual(p.focusY, 140)
        // Landing exactly on the ground y ends it (`cmpw r0,r4; bgt` at `1004c7d4`: only focus > ground y keeps
        // easing): 155 − max(5 / 7, 5) = 150.
        var x = state(y: 140, focusY: 155, groundY: 150, latch: false)
        PlayerScroll.scroll(&x, groundKind: 4, inWind: false)
        XCTAssertEqual(x.focusY, 150)
        XCTAssertFalse(x.scrollEasing)
        XCTAssertTrue(x.scrollLatch)
    }

    func testOutOfBandSnaps() {
        // PS5: scrollV 0 → the band is rows 16..287; fd90 300 is out → path B: focus = 300 at once, easing 0.
        var p = state(y: 300, focusY: 202, groundY: 202, latch: false)
        p.scrollEasing = true
        PlayerScroll.scroll(&p, groundKind: 0, inWind: false)
        XCTAssertEqual(p.focusY, 300)
        XCTAssertFalse(p.scrollEasing)
        XCTAssertFalse(p.scrollLatch)
        // The band's four edges, each pinned in and out (raw `1004c590..1004c5cc`: `SetRect(r, h, v, h + 0x260,
        // v + 0x180)`, top `addi 0x10`, bottom `subi 0x60`; `PtInRect(fd90, fd94)` at `1004c670` / `1004c6dc`: left /
        // top inclusive, right / bottom exclusive). Scroll point (100, 64): rows 80..351, cols 100..707. An in-band
        // y ≤ ground y freezes (focus 202 holds); an in-band y > ground y eases; out of band snaps (focus = y).
        func edge(x: Int16 = 300, y: Int16) -> Int16 {
            var e = state(y: y, focusY: 202, groundY: 202, latch: false, scrollV: 64)
            e.scrollH = 100
            e.centreX = x
            PlayerScroll.scroll(&e, groundKind: 0, inWind: false)
            return e.focusY
        }
        XCTAssertEqual(edge(y: 80), 202)                     // top = scrollV + 16: in (freeze)
        XCTAssertEqual(edge(y: 79), 79)                      // scrollV + 15: out (snap)
        XCTAssertEqual(edge(y: 351), 226)                    // bottom − 1 = scrollV + 287: in (ease 202 + 149 / 6)
        XCTAssertEqual(edge(y: 352), 352)                    // scrollV + 288: out (snap)
        XCTAssertEqual(edge(x: 100, y: 230), 208)            // left = scrollH: in (ease 202 + 6)
        XCTAssertEqual(edge(x: 99, y: 230), 230)             // scrollH − 1: out
        XCTAssertEqual(edge(x: 707, y: 230), 208)            // scrollH + 607: in
        XCTAssertEqual(edge(x: 708, y: 230), 230)            // scrollH + 608: out
    }

    // MARK: - the look-ahead row

    func testLookAheadWalkCapsAt80() {
        // LA1: walking at vx 0x76c: L += vx >> 2 = 475 a frame, cap 0x5000; the focus offset fd44 − fd94 = L >> 8.
        var p = state(y: 250, focusY: 250, groundY: 250, latch: true)
        var offsets: [Int] = []
        for _ in 0..<50 {
            PlayerScroll.lookAhead(&p, vx: 0x76c)
            XCTAssertTrue(p.snapArmed)
            PlayerScroll.scroll(&p, groundKind: 4, inWind: false)
            offsets.append(Int(p.focusX) - 300)
        }
        XCTAssertEqual(offsets[0], 1)
        XCTAssertEqual(offsets[9], 18)
        XCTAssertEqual(offsets[42], 79)
        XCTAssertEqual(offsets[43], 80)
        XCTAssertEqual(offsets[49], 80)
        XCTAssertEqual(p.lookAhead, 0x5000)
        // vx 0x101 counts (> 0x100); left mirrored, floor −0x5000.
        var q = PlayerState()
        PlayerScroll.lookAhead(&q, vx: 0x101)
        XCTAssertEqual(q.lookAhead, 0x40)
        for _ in 0..<200 { PlayerScroll.lookAhead(&q, vx: -0x76c) }
        XCTAssertEqual(q.lookAhead, -0x5000)
        // Left arm, both adds `srawi r0,r0,0x2` (raw `100514f0`, `1005150c`): −0x101 >> 2 = −0x41 (C's / 4 gives
        // −0x40). From 0: −0x41. From 0x100: 0xbf, still > 0 → again: 0x7e. (The right arm's two srawi see vx > 0x100
        // only, where >> 2 and / 4 agree.)
        var n = PlayerState()
        PlayerScroll.lookAhead(&n, vx: -0x101)
        XCTAssertEqual(n.lookAhead, -0x41)
        n.lookAhead = 0x100
        PlayerScroll.lookAhead(&n, vx: -0x101)
        XCTAssertEqual(n.lookAhead, 0x7e)
    }

    func testLookAheadReversal() {
        // LA3: from L 530 (frame 21), vx −0x76c: L += −475, still > 0 → again (double rate swinging back): −420 at
        // frame 22; −895 at 23, whose offset is −895 >> 8 = −4 (srawi, raw `1004c580`; C division would give −3).
        var p = state(y: 250, focusY: 250, groundY: 250, latch: true)
        p.lookAhead = 530
        PlayerScroll.lookAhead(&p, vx: -0x76c)
        XCTAssertEqual(p.lookAhead, -420)
        PlayerScroll.scroll(&p, groundKind: 4, inWind: false)
        XCTAssertEqual(p.focusX, 300 - 2)
        PlayerScroll.lookAhead(&p, vx: -0x76c)
        XCTAssertEqual(p.lookAhead, -895)
        PlayerScroll.scroll(&p, groundKind: 4, inWind: false)
        XCTAssertEqual(p.focusX, 300 - 4)
        // Mirrored: from −530 at vx +0x76c → +420.
        var q = PlayerState()
        q.lookAhead = -530
        PlayerScroll.lookAhead(&q, vx: 0x76c)
        XCTAssertEqual(q.lookAhead, 420)
    }

    func testLookAheadDecayOvershoot() {
        // LA4: slow (|vx| ≤ 0x100), facing left (F 1), L > 0 → L −= 0x200 and the snap disarmed (`uRam100a5114` 0):
        // 0x300 → 0x100 → −0x100, which then stays (it no longer points against the facing; armed again).
        var p = PlayerState()
        p.facing = 1
        p.lookAhead = 0x300
        PlayerScroll.lookAhead(&p, vx: 0x100)
        XCTAssertEqual(p.lookAhead, 0x100)
        XCTAssertFalse(p.snapArmed)
        PlayerScroll.lookAhead(&p, vx: -0x100)
        XCTAssertEqual(p.lookAhead, -0x100)
        XCTAssertFalse(p.snapArmed)
        PlayerScroll.lookAhead(&p, vx: 0)
        XCTAssertEqual(p.lookAhead, -0x100)
        XCTAssertTrue(p.snapArmed)
        // Facing right, L < 0 → += 0x200 (mirror arm).
        var m = PlayerState()
        m.facing = 2
        m.lookAhead = -0x300
        PlayerScroll.lookAhead(&m, vx: 0)
        XCTAssertEqual(m.lookAhead, -0x100)
        XCTAssertFalse(m.snapArmed)
        // LA5: no decay with the facing (F 2, L > 0; F 1, L < 0).
        var q = PlayerState()
        q.facing = 2
        q.lookAhead = 0x300
        PlayerScroll.lookAhead(&q, vx: 0)
        XCTAssertEqual(q.lookAhead, 0x300)
        XCTAssertTrue(q.snapArmed)
        q.facing = 1
        q.lookAhead = -0x300
        PlayerScroll.lookAhead(&q, vx: 0)
        XCTAssertEqual(q.lookAhead, -0x300)
        XCTAssertTrue(q.snapArmed)
    }
}
