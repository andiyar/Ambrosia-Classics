@testable import AkiCore

/// Test-only seeded generator (P2.3): standard SplitMix64, so deals are reproducible in tests.
/// The app passes `SystemRandomNumberGenerator`; the original's `srand(TickCount())` is unreproducible.
struct SplitMix64: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) { state = seed }

    mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }
}

/// Test-only scripted generator (P2.3): returns `values` in order and traps when exhausted, so a test
/// both pins every draw and proves no extra draw happened (`consumed`).
struct ScriptedRNG: RandomNumberGenerator {
    private let values: [UInt64]
    private(set) var consumed: Int = 0

    init(_ values: [UInt64]) { self.values = values }

    mutating func next() -> UInt64 {
        guard consumed < values.count else { preconditionFailure("ScriptedRNG exhausted after \(consumed) values") }
        defer { consumed += 1 }
        return values[consumed]
    }
}
