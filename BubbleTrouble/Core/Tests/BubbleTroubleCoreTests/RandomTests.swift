import BubbleTroubleCore
import Synchronization
import XCTest

/// Task 1 — RNG: QuickDraw `Random`, `_GetRandomFast`, session latches
/// (docs/plans/2026-10-03-btx-core-and-film-harness.md §Task 1; Research notes "RNG" 1–2, 4).
///
/// The `Random()` step is Apple's documented Park–Miller LCG with the 0x8000 → 0 adjustment —
/// an external fact at [LOW] (NR-3). Reference values below are the plan's own computation, not an
/// oracle trace; the `_GetRandomFast` arithmetic is the decompile's (`_GetRandomFast @ 0000c4cc`).
final class RandomTests: XCTestCase {

    /// Research note 2: seed 1 → (seed 16807, value 16807), then (282475249, 15089 = 0x3af1).
    func testStepFromSeedOne() {
        let first = QuickDrawRandom.step(1)
        XCTAssertEqual(first.seed, 16807)
        XCTAssertEqual(first.value, 16807)
        let second = QuickDrawRandom.step(first.seed)
        XCTAssertEqual(second.seed, 282_475_249)
        XCTAssertEqual(second.value, 15089)
    }

    /// Research note 2: seed 32768 → seed 550731776 (0x20d38000); low word 0x8000 is returned as 0
    /// by the documented step [LOW], and as −32768 by the diagnosis-only variant.
    func testStepMaps0x8000ToZero() {
        let adjusted = QuickDrawRandom.step(32768)
        XCTAssertEqual(adjusted.seed, 550_731_776)
        XCTAssertEqual(adjusted.value, 0)
        let raw = QuickDrawRandom.stepWithout8000Adjustment(32768)
        XCTAssertEqual(raw.seed, 550_731_776)
        XCTAssertEqual(raw.value, -32768)
    }

    /// Research note 2: FILM 1 seed 0x004642a0 (u32 at FILM+4) → 5764, 13963, 4202, −22575, −23569;
    /// seeds 0x04c01684, 0x5f06368b, 0x10e7106a, 0x31e6a7d1, 0x1e13a3ef (504603631 after 5 draws).
    func testFilm1SeedFirstFiveRandoms() {
        var rng = GameRandom(seed: 0x0046_42a0)
        var values: [Int16] = []
        var seeds: [UInt32] = []
        for _ in 0..<5 {
            values.append(rng.random())
            seeds.append(rng.seed)
        }
        XCTAssertEqual(values, [5764, 13963, 4202, -22575, -23569])
        XCTAssertEqual(seeds, [0x04c0_1684, 0x5f06_368b, 0x10e7_106a, 0x31e6_a7d1, 0x1e13_a3ef])
        XCTAssertEqual(rng.seed, 504_603_631)
        XCTAssertEqual(rng.drawCount, 5)
    }

    /// Research note 1, `_GetRandomFast @ 0000c4cc`:
    /// `p = (hi - lo + 1) * (Random() & 0xffff); if (0x7fffffff < p) p += 0xffff; return lo + ((int)p >> 16) & 0xffff;`
    func testFastMappingWithStubbedStep() {
        func fast(_ lo: Int, _ hi: Int, raw: UInt16) -> Int {
            let value = Int16(bitPattern: raw)
            var rng = GameRandom(seed: 7, step: { seed in (seed, value) })
            return rng.fast(lo, hi)
        }
        XCTAssertEqual(fast(0, 6, raw: 0xffff), 6)
        XCTAssertEqual(fast(0, 6, raw: 0), 0)
        XCTAssertEqual(fast(40, 480, raw: 0xffff), 480)
        XCTAssertEqual(fast(1, 750, raw: 0x8000), 376)
        // n = 0x10000, r = 0x8000 → p = 0x80000000 > 0x7fffffff → += 0xffff → arithmetic >> 16 = −32768,
        // (0 + −32768) & 0xffff = 32768: the branch no game range reaches, kept and pinned here.
        XCTAssertEqual(fast(0, 0xffff, raw: 0x8000), 32768)
    }

    /// FILM 1 level construction starts the first jewel with `fast(1,14)`, `fast(1,9)` → 2, 2
    /// (values 5764 and 13963 from the FILM 1 seed). Cross-check: six `(1,14)` draws are [2, 3, 1, 10, 9, 10].
    func testFilm1FirstJewelStart() {
        var rng = GameRandom(seed: 0x0046_42a0)
        XCTAssertEqual(rng.fast(1, 14), 2)
        XCTAssertEqual(rng.fast(1, 9), 2)

        var six = GameRandom(seed: 0x0046_42a0)
        XCTAssertEqual((0..<6).map { _ in six.fast(1, 14) }, [2, 3, 1, 10, 9, 10])
    }

    /// Research note 4: `_Interface` calls `_Get0To6` then `_Get13To22` (each `if (val == 99) val =
    /// GetRandomFast(0,6)` resp. `(0xd,0x16)`) before any game. From process seed 1: u = 1, L = 15 [LOW].
    func testSessionLatchesFromSeedOne() {
        let derived = SessionLatches.derive(processSeed: 1)
        XCTAssertEqual(derived, SessionLatches(u: 1, L: 15))
        XCTAssertEqual(derived, SessionLatches.fromProcessSeedOne)
    }

    /// Every `Random()` counts once, whether reached via `fast` or `random`; the injected step is the one used.
    func testDrawCountCountsEveryRandom() {
        let calls = CallCounter()
        var rng = GameRandom(seed: 100, step: { seed in
            calls.increment()
            return (seed &+ 1, 0x1234)
        })
        _ = rng.fast(0, 6)
        _ = rng.random()
        _ = rng.fast(1, 14)
        _ = rng.random()
        _ = rng.fast(40, 480)
        XCTAssertEqual(rng.drawCount, 5)
        XCTAssertEqual(calls.value, 5)
        XCTAssertEqual(rng.seed, 105, "the custom step advanced the seed")
        XCTAssertEqual(rng.random(), 0x1234, "the custom step's value is returned")
    }
}

/// Thread-safe counter so the `@Sendable` stub step can record its calls under Swift 6.
private final class CallCounter: Sendable {
    private let count = Mutex(0)
    func increment() { count.withLock { $0 += 1 } }
    var value: Int { count.withLock { $0 } }
}
