import XCTest
import HectorResources
@testable import FerazelCore

/// F1 (docs/plans/2026-10-10-ferazel-phase2.md): `.FastRand @ 100340e0` (decompile l. 31282–31313, raw
/// `1003411c..100341b8`) and the draws the level-1 Setups make in `.SetupLevelSprites` spawn order (the plan's
/// "F1 ⚑ FastRand sites" note), against the committed `Resources/Ferazel` (D26). A missing data file is a FAILURE.
final class FastRandTests: XCTestCase {

    private func resources() throws -> FerazelResources { try FerazelData.open(try FerazelData.dataDirectory()) }

    /// The binary's step is Park–Miller: 16807·s mod (2³¹ − 1) (probe C `C_fastrand.py`).
    func testParkMillerEquivalence() {
        var r = FastRand(seed: 1)
        var s: Int64 = 1
        for i in 0..<200_000 {
            _ = r.next(1)
            s = s * 16807 % 0x7fff_ffff
            if Int64(r.seed) != s { XCTFail("step \(i): \(r.seed) ≠ \(s)"); return }
        }
    }

    func testSeedOneSequence() {
        var r = FastRand(seed: 1)
        var states: [Int32] = []
        var out: [Int16] = []
        for _ in 0..<10 {
            out.append(r.next(100))
            states.append(r.seed)
        }
        XCTAssertEqual(out, [25, 23, 67, 4, 71, 85, 55, 3, 18, 1])
        XCTAssertEqual(Array(states.prefix(3)), [0x41a7, 0x10d6_3af1, 0x60b7_acd9])
    }

    /// lo == 0x8000 → the result is 0 (raw `10034180..10034188`), the stored seed keeps the 0x8000.
    func testLow8000Quirk() {
        var r = FastRand(seed: 0x2b6c_fbb6)
        XCTAssertEqual(r.next(100), 0)
        XCTAssertEqual(r.seed, 0x0001_8000)                    // without the quirk: (100 · 0x8000) >> 16 = 50
    }

    /// R(1) = 0 always but still advances the seed; n == 0 reseeds from Time + Ticks (l. 31296–31299).
    func testROneAdvances() {
        var r = FastRand(seed: 1)
        XCTAssertEqual(r.next(1), 0)
        XCTAssertEqual(r.seed, 0x41a7)
        XCTAssertEqual(r.next(100), 23)
        var copy = r
        let expected = Int32(copy.next(10000)) + 0xec77              // `.STPlay3DSoundRand` raw `10047d60..10047d90`
        XCTAssertEqual(r.soundRate(), expected)
        XCTAssertEqual(r.seed, copy.seed)

        var c = FastRand(seed: 1, clock: { (secondsSince1904: 0xd000_0000, ticks: 0x3000_0005) })
        _ = c.next(0)
        XCTAssertEqual(c.seed, FastRand.clockSeed(secondsSince1904: 0xd000_0000, ticks: 0x3000_0005))
        XCTAssertEqual(c.seed, Int32(bitPattern: 0x0000_0005))   // the 32-bit add wraps
    }

    /// The level-1 Setups draw 256 times under seed 1 (plan F1 ⚑ note: 43 coins × 4, 10 secret triggers × 1, the
    /// money bag × 2, 3 rock piles × 1, 22 torches × 2, the sphere × 2, the item × 2, 7 Walkers × 3 — the
    /// torches' pass first). The first coin (1055, record 10, spawn #36) takes draw 48: `+0x46` = R(19) = 3.
    func testLevel1SetupDrawCount() throws {
        let session = try FerazelSession(resources: try resources(), prefs: FerazelPrefs(), level: 1, seed: 1)
        var r = FastRand(seed: 1)
        var n = 0
        while r.seed != session.seedAfterSetups && n < 100_000 {
            _ = r.next(1)
            n += 1
        }
        XCTAssertEqual(n, 256)
        let idle = session.idle.entries.compactMap { $0 }
        let coin = try XCTUnwrap(idle.first { $0.saved.type == 1055 })
        XCTAssertEqual(coin.saved.recordIndex, 10)
        XCTAssertEqual(coin.saved.phase, 3)
        // The item (3204, record 68): `+0x46` = R(16) = 6, the `BonusHandle.twinkle` start phase.
        let item = try XCTUnwrap(idle.first { $0.saved.type == 3204 })
        XCTAssertEqual(item.saved.phase, 6)
    }

    /// E2 Part A (plan F1 ⚑ note, "Orchestrator carry → E2"): after `.SetupLevelSprites` the level start draws, in
    /// order, (1) `.RedrawEntireScrollGrid` in `.SetupLevel` (l. 2582) — 0: the grid's `.WrapDrawFace` words are 9
    /// and ≥ 0x14 (raw `100139b4`, `1001394c`, `10013b14`), and `.BlitEncFaceDiffuse` (the four FastRand sites
    /// `10029b64/7c`, `10029e5c/74`) is reached only for mode 5 (`cmpwi r23,0x5` raw `1002d130`); (2) `.AnimateCLUT`
    /// (l. 9062, R(4000) per animated entry, raw `10011bc4`) — 0 on levels 1 and 2 (header 0x2732 = 0); (3)
    /// `.BuildTintTable` table 0xa, B then R per entry 0..0xfe (raw `10021d04/14`, l. 18258–18259) — 510 R(5000);
    /// (4) `.SetScrollLocation` + `.RedrawEntireScrollGrid` in `.GameLoop` (l. 5210–5211) — 0, as (1).
    func testLevelStartDrawsAfterSetups() throws {
        let res = try resources()
        let s = try FerazelSession(resources: res, prefs: FerazelPrefs(), level: 1, seed: 1)
        XCTAssertEqual(s.seedAfterSetups, 0x3577_f881)                     // 16807^256 mod (2^31 − 1)
        var r = FastRand(seed: s.seedAfterSetups)
        let replay = (0..<510).map { _ in r.next(5000) }
        XCTAssertEqual(s.tintTableDraws, replay)
        XCTAssertEqual(Array(s.tintTableDraws.prefix(4)), [4854, 3275, 106, 4033])   // B, R of entry 0, then entry 1
        XCTAssertEqual(s.rngSeed, r.seed)
        XCTAssertEqual(s.rngSeed, 0x2c1b_1519)                             // 16807^766 mod (2^31 − 1)
        for level in [1, 2] {
            let h = try LevelFile.load(from: res, level: Int16(level)).header
            XCTAssertEqual(h.clutAnimCount, 0, "level \(level)")
        }
        // `.AnimateCLUT`'s draw count: header 0x2732 entries when 0x2730 == 6 and the Effects gate passes.
        XCTAssertEqual(FerazelSession.animateCLUTDraws(mode: 6, count: 3, effects: 1, frameCounter: 0, parity: false), 3)
        XCTAssertEqual(FerazelSession.animateCLUTDraws(mode: 6, count: 3, effects: 1, frameCounter: 0, parity: true), 0)
        XCTAssertEqual(FerazelSession.animateCLUTDraws(mode: 6, count: 3, effects: 2, frameCounter: 1, parity: false), 0)
        XCTAssertEqual(FerazelSession.animateCLUTDraws(mode: 6, count: 3, effects: 3, frameCounter: 0, parity: false), 0)
        XCTAssertEqual(FerazelSession.animateCLUTDraws(mode: 5, count: 3, effects: 1, frameCounter: 0, parity: false), 0)
        XCTAssertEqual(FerazelSession.animateCLUTDraws(mode: 6, count: 0, effects: 1, frameCounter: 0, parity: false), 0)
    }

    func testSessionDeterministic() throws {
        let res = try resources()
        let a = try FerazelSession(resources: res, prefs: FerazelPrefs(), level: 1, seed: 1)
        let b = try FerazelSession(resources: res, prefs: FerazelPrefs(), level: 1, seed: 1)
        for i in 0..<60 {
            let k = KeyState()
            XCTAssertEqual(a.step(keys: k), b.step(keys: k), "frame \(i)")
        }
        XCTAssertEqual(a.rngSeed, b.rngSeed)
        let c = try FerazelSession(resources: res, prefs: FerazelPrefs(), level: 1, seed: 2)
        func firstCoin(_ s: FerazelSession) -> Int16? {
            s.idle.entries.compactMap { $0 }.first { $0.saved.type == 1055 }?.saved.phase
        }
        XCTAssertNotNil(firstCoin(a))
        XCTAssertNotEqual(firstCoin(a), firstCoin(c))
    }
}
