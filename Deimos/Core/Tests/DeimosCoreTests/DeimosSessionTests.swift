import XCTest
import HectorResources
@testable import DeimosCore

/// `DeimosSession` (plan C6): the session set-up + level start (`FUN_100051a0` set-up, `FUN_100064d0`) and one
/// pass of the loop in the original's order (engine-loop §3, timing-frame §2.1–§2.4).
final class DeimosSessionTests: XCTestCase {
    private func assets() throws -> DeimosAssets { try PlayerPhase1Tests.loaded.get() }

    private func session(seed: UInt32 = 0x469c2, players: Int = 1) throws -> DeimosSession {
        try DeimosSession(assets: assets(), prefs: .fresh, start: SessionStart(sector: 1, players: players, film: nil),
                          seed: seed)
    }

    private static func rect(_ t: Int32, _ l: Int32, _ b: Int32, _ r: Int32) -> MacRect {
        MacRect(top: t, left: l, bottom: b, right: r)
    }

    /// The terrain → back blit of `FUN_10010120` with the window top `top` (offset 0, pref 5 off).
    private static func terrainBlit(top: Int32) -> RenderOp {
        .copy(from: .terrain, to: .back, src: rect(top, 32, top + 480, 448), dst: rect(0, 0, 480, 416),
              interlaced: false)
    }

    private static func isTerrainBlit(_ op: RenderOp) -> Bool {
        if case .copy(from: .terrain, to: .back, _, _, _) = op { return true }
        return false
    }

    /// A coarse op kind, for order assertions.
    private static func kind(_ op: RenderOp) -> String {
        switch op {
        case .loadTerrain: return "loadTerrain"
        case .fill: return "fill"
        case .loadImage: return "loadImage"
        case .copy(from: .terrain, _, _, _, _): return "terrainBlit"
        case .copy: return "copy"
        case .draw: return "draw"
        case .clearLayers: return "clearLayers"
        case .flushLayers(let r): return "flush\(r.lowerBound)-\(r.upperBound)"
        case .screenBlit: return "screenBlit"
        case .fade: return "fade"
        case .limit: return "limit"
        case .present: return "present"
        }
    }

    /// Init ops (returned by pass 0, before its own `clearLayers`): `FUN_1000fbc0` jum2, `FUN_10009f00` back ← 0
    /// (`1000690c`), the score bar's level start with screen blits off (`10006914..10006934`), the first terrain
    /// blit at the window top 3120 (`10006974`); no present.
    func testInitOps() throws {
        let a = try assets()
        var s = try session()
        let out = s.pass(keys: HeldKeys())
        let first = out.ops.firstIndex(of: .clearLayers)!
        let initOps = Array(out.ops[..<first])

        let w = try PlayerPhase1Tests.World(assets: a, players: 1)
        var expected: [RenderOp] = [.loadTerrain(image: FourCC("jum2")!), .fill(.back, colour: 0)]
        expected += try ScoreBarDraw(assets: a).levelStartOps(state: w.bar)
        expected.append(Self.terrainBlit(top: 3120))

        XCTAssertEqual(initOps.count, expected.count)
        for (i, (got, want)) in zip(initOps, expected).enumerated() { XCTAssertEqual(got, want, "init op \(i)") }
        // Two scor loads, then P1 and P2 elements (restores from the save buffer).
        XCTAssertEqual(initOps.filter { if case .loadImage = $0 { return true } else { return false } }.count, 2)
        XCTAssertFalse(initOps.contains { if case .present = $0 { return true } else { return false } })
        XCTAssertFalse(initOps.contains { if case .screenBlit = $0 { return true } else { return false } })
        // The second pass carries no init ops.
        let second = s.pass(keys: HeldKeys())
        XCTAssertEqual(second.ops.first, .clearLayers)
        XCTAssertFalse(second.ops.contains { if case .loadTerrain = $0 { return true } else { return false } })
    }

    /// Game times 0 and 1: ticked, limited (pref 10 on), but not presented (the game has not appeared).
    func testPassesZeroAndOneUnpresented() throws {
        var s = try session()
        for t in 0..<2 {
            let out = s.pass(keys: HeldKeys())
            XCTAssertTrue(out.ticked, "pass \(t)")
            XCTAssertFalse(out.sessionEnded)
            XCTAssertEqual(out.ops.last, .limit, "pass \(t)")
            XCTAssertFalse(out.ops.contains { if case .present = $0 { return true } else { return false } }, "pass \(t)")
            XCTAssertFalse(out.ops.contains { if case .fade = $0 { return true } else { return false } }, "pass \(t)")
            XCTAssertFalse(out.ops.contains { if case .screenBlit = $0 { return true } else { return false } }, "pass \(t)")
        }
    }

    /// Pass 2 (game time = flli 18 = 2): `clearLayers`, then the fade from black before any update, then the
    /// draw; ends with the first `present(.gameScreen)`. Later passes do not fade again.
    func testFadeAtTick2() throws {
        XCTAssertEqual(try assets().floats[18], 2)
        var s = try session()
        _ = s.pass(keys: HeldKeys())
        _ = s.pass(keys: HeldKeys())
        let out = s.pass(keys: HeldKeys())
        XCTAssertEqual(Array(out.ops.prefix(2)), [.clearLayers, .fade(.fromBlack, .gameLayout)])
        XCTAssertEqual(out.ops.last, .present(.gameScreen))
        XCTAssertEqual(out.ops.filter { if case .fade = $0 { return true } else { return false } }.count, 1)
        XCTAssertTrue(out.ticked)
        for _ in 0..<5 {
            let later = s.pass(keys: HeldKeys())
            XCTAssertFalse(later.ops.contains { if case .fade = $0 { return true } else { return false } })
            XCTAssertEqual(later.ops.last, .present(.gameScreen))
        }
    }

    /// Pass 200: begin (`clearLayers`) → [tick: no ops] → draw world (P1's crosshair, shadow, sprite; then the
    /// score bar's weapon slots, dirty every tick because handler +0x08 is never cleared after level start —
    /// loose-ends-combat §6.4 — each restore, slot 0's icon, screen blit; the meters have settled) → end frame:
    /// layers 0–1, terrain blit, layers 2–5, layers 6–15, limit, present.
    func testSteadyPassOrder() throws {
        var s = try session()
        for _ in 0..<200 { _ = s.pass(keys: HeldKeys()) }
        let out = s.pass(keys: HeldKeys())
        XCTAssertEqual(out.ops.map(Self.kind),
                       ["clearLayers", "draw", "draw", "draw",
                        "copy", "draw", "screenBlit", "copy", "screenBlit", "copy", "screenBlit",
                        "flush0-1", "terrainBlit", "flush2-5", "flush6-15", "limit", "present"])
        XCTAssertEqual(out.ops.last, .present(.gameScreen))
        XCTAssertTrue(out.ticked)
        XCTAssertEqual(out.sounds, [])
        XCTAssertEqual(out.music, [])
        XCTAssertEqual(out.requests, [])
    }

    /// The scroll steps once per tick after the draw-side state of the tick: pass t blits from top 3119 − t
    /// for t ≤ 3118 (scroll tick 3119 ends the level at top 1), then 1 forever.
    func testTerrainTopPerPass() throws {
        var s = try session()
        for t in 0..<3125 {
            let out = s.pass(keys: HeldKeys())
            let blit = out.ops.last(where: Self.isTerrainBlit)
            let top: Int32 = t <= 3118 ? 3119 - Int32(t) : 1
            XCTAssertEqual(blit, Self.terrainBlit(top: top), "pass \(t)")
            if blit != Self.terrainBlit(top: top) { break }
        }
    }

    /// Esc (0x35, pref 8 off) ends the session: that pass still ticks, draws and presents and carries
    /// `sessionEnded`; the loop does not run again.
    func testEscEndsSession() throws {
        var s = try session()
        for _ in 0..<10 { XCTAssertFalse(s.pass(keys: HeldKeys()).sessionEnded) }
        let out = s.pass(keys: HeldKeys(held: [0x35]))
        XCTAssertTrue(out.sessionEnded)
        XCTAssertTrue(out.ticked)
        XCTAssertEqual(out.ops.first, .clearLayers)
        XCTAssertTrue(out.ops.contains { if case .draw = $0 { return true } else { return false } })
        XCTAssertEqual(out.ops.last, .present(.gameScreen))
        let after = s.pass(keys: HeldKeys())
        XCTAssertTrue(after.sessionEnded)
        XCTAssertEqual(after.ops, [])
        XCTAssertFalse(after.ticked)
    }

    /// Same seed + key script → identical outputs; another seed → the same outputs (the one Phase-1 draw, the
    /// P1 integrity tick, has no visible effect).
    func testDeterministicReplay() throws {
        func script(_ t: Int) -> HeldKeys {
            switch t % 90 {
            case 0..<30: return HeldKeys(held: [0x7B])                 // P1 left
            case 30..<45: return HeldKeys(held: [0x7C, 0x7D])          // P1 right + down
            case 45..<60: return HeldKeys(held: [0x56, 0x37])          // P2 left, P1 button
            default: return HeldKeys()
            }
        }
        func run(seed: UInt32) throws -> [PassOutput] {
            var s = try session(seed: seed, players: 2)
            return (0..<400).map { s.pass(keys: script($0)) }
        }
        let a = try run(seed: 1234), b = try run(seed: 1234), c = try run(seed: 98765)
        XCTAssertEqual(a.count, 400)
        XCTAssertTrue(a == b, "same seed and keys must replay identically")
        XCTAssertTrue(a == c, "the seed has no visible effect in Phase 1")
        // The script moved the view: some terrain blit left differs from 32.
        XCTAssertTrue(a.contains { $0.ops.contains { op in
            if case .copy(from: .terrain, to: .back, let src?, _, _) = op { return src.left != 32 }
            return false
        } })
    }
}
