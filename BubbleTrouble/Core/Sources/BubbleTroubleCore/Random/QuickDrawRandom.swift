/// QuickDraw `Random()` — the only generator the game uses (`_Random` is an undefined import; its single
/// call site is `calll _Random` at 0000c4d9 inside `_GetRandomFast`).
///
/// ⚠️ Suspect #1 on any FILM divergence (Invariant 10, Diagnosis protocol). The algorithm is Apple's documented
/// Park–Miller step (Inside Macintosh), an external fact at **[LOW]** (NR-3): it cannot be read from the binary.
/// `step` is the single place the LCG lives; `GameRandom` takes it as a swappable function value.
public enum QuickDrawRandom {
    /// Park–Miller modulus 2^31 − 1.
    static let modulus: UInt64 = 0x7fff_ffff
    /// Park–Miller multiplier 7^5.
    static let multiplier: UInt64 = 16807

    /// randSeed = randSeed × 16807 mod (2^31 − 1); value = low 16 bits as Int16, 0x8000 → 0. [LOW] NR-3.
    public static func step(_ seed: UInt32) -> (seed: UInt32, value: Int16) {
        let raw = stepWithout8000Adjustment(seed)
        return (raw.seed, raw.value == Int16.min ? 0 : raw.value)
    }

    /// Diagnosis-only variant (no 0x8000 adjustment) — selected by btx-replay --rng-variant qd-no8000.
    public static func stepWithout8000Adjustment(_ seed: UInt32) -> (seed: UInt32, value: Int16) {
        let next = UInt32((UInt64(seed) * multiplier) % modulus)
        return (next, Int16(truncatingIfNeeded: next))
    }
}
