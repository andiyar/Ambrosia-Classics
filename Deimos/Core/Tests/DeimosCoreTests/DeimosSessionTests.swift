import XCTest
import HectorResources
@testable import DeimosCore

/// `DeimosSession` (plan C6, re-pointed by C18a to the Phase-2 session): the session set-up + level start
/// (`FUN_100051a0` set-up, `FUN_100064d0`) and one pass of the loop in the original's order (engine-loop §3,
/// timing-frame §2.1–§2.4). The new Phase-2 behaviour (film, pause, audio) is `FilmPlaybackTests`.
final class DeimosSessionTests: XCTestCase {
    private func assets() throws -> DeimosAssets { try TestAssets.loaded.get() }

    private func session(seed: UInt32 = 0x469c2, players: Int = 1, prefs: DeimosPrefs = .fresh) throws -> DeimosSession {
        try DeimosSession(assets: assets(), prefs: prefs, start: SessionStart(sector: 1, players: players, film: nil),
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
        case .particles: return "particles"
        case .pauseWait: return "pauseWait"
        }
    }

    /// Init ops (returned by pass 0, before its own `clearLayers`): `FUN_1000fbc0` jum2, `FUN_10009f00` back ← 0
    /// (`1000690c`), the score bar's level start with screen blits off (`10006914..10006934`), the first terrain
    /// blit at the window top 3120 (`10006974`); no present. The load pass and `no01` draw nothing at the start; the
    /// start's music (`[play(ammu), stop]`, then the engine level) leads pass 0's music, and pass 0's own end frame
    /// carries the particles op (`10030cd0`).
    func testInitOps() throws {
        let a = try assets()
        var s = try session()
        let out = s.pass(keys: HeldKeys())
        let first = out.ops.firstIndex(of: .clearLayers)!
        let initOps = Array(out.ops[..<first])

        let w = try TestWorld(assets: a, players: 1)
        var expected: [RenderOp] = [.loadTerrain(image: FourCC("jum2")!), .fill(.back, colour: 0)]
        expected += try ScoreBarDraw(assets: a).levelStartOps(state: w.bar)
        expected.append(Self.terrainBlit(top: 3120))

        XCTAssertEqual(initOps.count, expected.count)
        for (i, (got, want)) in zip(initOps, expected).enumerated() { XCTAssertEqual(got, want, "init op \(i)") }
        // Two scor loads, then P1 and P2 elements (restores from the save buffer).
        XCTAssertEqual(initOps.filter { if case .loadImage = $0 { return true } else { return false } }.count, 2)
        XCTAssertFalse(initOps.contains { if case .present = $0 { return true } else { return false } })
        XCTAssertFalse(initOps.contains { if case .screenBlit = $0 { return true } else { return false } })
        XCTAssertFalse(initOps.contains { if case .particles = $0 { return true } else { return false } })
        XCTAssertEqual(Array(out.music.prefix(3)), [.play(FourCC("ammu")!, loop: true), .stop, .level(100)])
        XCTAssertEqual(out.ops[first...].filter { if case .particles = $0 { return true } else { return false } }.count, 1)
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

    /// Pass 200: begin (`clearLayers`) → [tick: no ops] → draw world: the entity groups (`FUN_100345f0`: the one
    /// live `bu01` Buzzsaw — its shadow pass `bsba` (flags 2), then its sprite pass `bsba` glow + tint and `bsbu`),
    /// no blurs, P1's crosshair, shadow, sprite; then the score bar's weapon slots, dirty every tick because handler
    /// +0x08 is never cleared after level start — loose-ends-combat §6.4 — each restore, slot 0's icon, screen blit;
    /// the meters have settled) → end frame: layers 0–1, terrain blit, layers 2–5, particles, layers 6–15, limit,
    /// present. No sound or music that pass.
    func testSteadyPassOrder() throws {
        var s = try session()
        for _ in 0..<200 { _ = s.pass(keys: HeldKeys()) }
        let out = s.pass(keys: HeldKeys())
        XCTAssertEqual(out.ops.map(Self.kind),
                       ["clearLayers", "draw", "draw", "draw", "draw", "draw", "draw", "draw",
                        "copy", "draw", "screenBlit", "copy", "screenBlit", "copy", "screenBlit",
                        "flush0-1", "terrainBlit", "flush2-5", "particles", "flush6-15", "limit", "present"])
        let faces = out.ops.compactMap { if case let .draw(c) = $0 { return c.face.description } else { return nil } }
        XCTAssertEqual(faces, ["bsba", "bsba", "bsba", "bsbu", "pbta", "pl1o", "pl1o", "wesy"])
        XCTAssertEqual(s.game.world.groups.map(\.unit.description), ["PERM", "bu01"])
        XCTAssertEqual(out.ops.last, .present(.gameScreen))
        XCTAssertTrue(out.ticked)
        XCTAssertEqual(out.sounds, [])
        XCTAssertEqual(out.music, [])
        XCTAssertEqual(out.requests, [])
    }

    /// The scroll steps once per tick after the draw-side state of the tick: pass t blits from top 3119 − t. With no
    /// keys P1 loses its three lives (state 3 at passes 443, 760, 1022), leaves the game at 1084 (= G+0x34, the first
    /// no-player tick, `10006d5c..10006d60`), and the running flag clears at game time 1084 + 111 (`10006d68..
    /// 10006d98`): pass 1195 is the last (◇ stand-in 2). The scroll never pauses before then (level 1's first
    /// pausing controller, `01m1`, is created at 1660). Bound: 3125 passes.
    func testTerrainTopPerPass() throws {
        var s = try session()
        var end: Int?
        for t in 0..<3125 {
            let out = s.pass(keys: HeldKeys())
            let blit = out.ops.last(where: Self.isTerrainBlit)
            XCTAssertEqual(blit, Self.terrainBlit(top: 3119 - Int32(t)), "pass \(t)")
            if blit != Self.terrainBlit(top: 3119 - Int32(t)) { break }
            XCTAssertEqual(s.scroll.speed, 1, "pass \(t)")
            if out.sessionEnded { end = t; break }
        }
        guard let last = end else { return XCTFail("bound 3125 passes reached") }
        XCTAssertEqual(last, 1195)
        XCTAssertEqual(s.game.flags.gameOverStart, 1084)
        XCTAssertTrue(s.game.flags.noPlayerAlive)
        XCTAssertEqual(s.pass(keys: HeldKeys()).ops, [])
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

    /// The cursor: the front end hides it just before the game (`FUN_100234d0` step 2, `10023550 bl FUN_1000b6e0`
    /// → `HideCursor`); `FUN_100051a0` itself never touches it. The session's first pass carries `.hideCursor`; no
    /// later pass carries a request — not even the Esc pass (the front end's `InitCursor` after the game,
    /// `100238b4` / `10023ad0`, belongs to the menu, which Phase 1 replaces with an immediate new session).
    func testCursorHiddenAtSessionStart() throws {
        var s = try session()
        XCTAssertEqual(s.pass(keys: HeldKeys()).requests, [.hideCursor])
        for _ in 0..<10 { XCTAssertEqual(s.pass(keys: HeldKeys()).requests, []) }
        let end = s.pass(keys: HeldKeys(held: [0x35]))
        XCTAssertTrue(end.sessionEnded)
        XCTAssertEqual(end.requests, [])
    }

    /// Same seed + key script → identical outputs; another seed changes the outputs by the first spawn after the
    /// start: pass 56, the respawn tick, whose entry spawns `plen` (`10029e38..10029ed8`, P1 and P2) record their
    /// state sounds with drawn pitches. Before it the seed shows nowhere (the start's one draw, the P1 integrity
    /// tick, has no visible effect).
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
        XCTAssertTrue(a != c, "another seed changes the outputs")
        XCTAssertEqual(a.indices.first { a[$0] != c[$0] }, 56)
        let plen = FourCC("plen")!
        XCTAssertEqual(a[56].sounds.filter { $0.id == plen }.count, 2)
        XCTAssertNotEqual(a[56].sounds.filter { $0.id == plen }.map(\.pitch),
                          c[56].sounds.filter { $0.id == plen }.map(\.pitch))
        // The script moved the view: some terrain blit left differs from 32.
        XCTAssertTrue(a.contains { $0.ops.contains { op in
            if case .copy(from: .terrain, to: .back, let src?, _, _) = op { return src.left != 32 }
            return false
        } })
    }
    /// Byte pref 5 (interlacing) set: the level start suspends it (`1000693c..10006968`: game +0x0f = 1, pref 5
    /// cleared), so the first terrain blits are progressive; the appear (`10005990..100059b0`, pass 2) restores
    /// it before that pass's end-frame blit, which is interlaced from then on.
    func testInterlacePrefSuspendedUntilAppear() throws {
        var prefs = DeimosPrefs.fresh
        prefs.bytePrefs[5] = 1
        var s = try session(prefs: prefs)
        XCTAssertTrue(s.restoreInterlace)
        XCTAssertEqual(s.prefs.bytePrefs[5], 0)
        func blits(_ out: PassOutput) -> [Bool] {
            out.ops.compactMap { if case .copy(from: .terrain, to: .back, _, _, let i) = $0 { return i } else { return nil } }
        }
        XCTAssertEqual(blits(s.pass(keys: HeldKeys())), [false, false])   // init blit + pass 0
        XCTAssertEqual(blits(s.pass(keys: HeldKeys())), [false])
        XCTAssertEqual(blits(s.pass(keys: HeldKeys())), [true])           // pass 2: appear, pref 5 back
        XCTAssertFalse(s.restoreInterlace)
        XCTAssertEqual(s.prefs.bytePrefs[5], 1)
        XCTAssertEqual(blits(s.pass(keys: HeldKeys())), [true])
    }

    /// P2's seven key-table slots (`+0x14b8` + 7…13: kp8 kp4 kp6 kp5 End Fwd-Del PgDn) reach player 2 only, and
    /// P1's reach player 1 only — copied in life state 4 (after `entry_InitialDelay`).
    func testPlayerTwoKeySlots() throws {
        var s = try session(players: 2)
        for _ in 0..<60 { _ = s.pass(keys: HeldKeys()) }
        XCTAssertEqual(s.players.map(\.lifeState), [4, 4])
        _ = s.pass(keys: HeldKeys(held: [0x5B, 0x56, 0x58, 0x57, 0x77, 0x75, 0x79]))
        XCTAssertEqual(s.players[1].input.rawValue, 0x7F)
        XCTAssertEqual(s.players[0].input, [])
        _ = s.pass(keys: HeldKeys(held: [0x5B, 0x77]))
        XCTAssertEqual(s.players[1].input, [.up, .fireAir])
        _ = s.pass(keys: HeldKeys(held: [0x7E, 0x31]))
        XCTAssertEqual(s.players[0].input, [.up, .select])
        XCTAssertEqual(s.players[1].input, [])
    }

    /// Byte pref 8 (Esc-hold) on: `FUN_100307c0` runs twice per pass (begin frame, then the end-frame wrapper
    /// `10030590`), so the hold counter reaches 2k − 1 at pass k's begin and quits when it exceeds PermFloat 32
    /// (30): on the 16th held pass. Releasing Esc resets it.
    func testEscHoldPrefQuitsOnSixteenthHeldPass() throws {
        var prefs = DeimosPrefs.fresh
        prefs.bytePrefs[8] = 1
        var s = try session(prefs: prefs)
        let esc = HeldKeys(held: [0x35])
        for _ in 0..<10 { XCTAssertFalse(s.pass(keys: esc).sessionEnded) }
        XCTAssertFalse(s.pass(keys: HeldKeys()).sessionEnded)
        for k in 1...15 { XCTAssertFalse(s.pass(keys: esc).sessionEnded, "held pass \(k)") }
        let out = s.pass(keys: esc)
        XCTAssertTrue(out.sessionEnded)
        XCTAssertTrue(out.ticked)
        XCTAssertEqual(out.ops.last, .present(.gameScreen))
    }
}
