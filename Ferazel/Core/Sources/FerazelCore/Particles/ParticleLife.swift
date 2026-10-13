import Foundation

/// The colour-0 ages of `.InitParticleColors @ 100306b4`'s rows `row[kind][age]` (TOC `100a01a8`, 256 × 120 bytes;
/// particles §4.1–§4.3), which `.DrawParticles` turns into kills (§3.1 step 3) — the Core side of the rows. Core has
/// no colours, so it keeps only where a row is 0 (plan E1a: FerazelRender builds the rows themselves and
/// cross-checks them, E1b). Every row is zeroed first (`100306f0..10030780`); a recipe's 0 is either a direct store
/// of index 0 or a request for clut 801 entry 0 (white), which `Color2Index` answers with index 0 (entry 0 of every
/// level CLUT is white, §4.1) [MED: the exact match; HIGH for the data]. Every built row is non-zero up to its first
/// 0 and zero after it, so a row is one number: `life` = its first zero age (120 = none before the age limit).
///
/// Per kind (t = age, s = t >> 1; raw ranges §4.2):
/// - 1 (`10030790..10030858`): e 0xe1 > 0xdf → e 0 at s ≥ 12 → **24**; 13 (`10030d74..10030e60`, the same entry walk,
///   red/blue swapped only when e ≠ 0) → **24**.
/// - 2 (`1003087c..100308e0`): `0xd7 + ((t − 20) >> 1)` > 0xdf → e 0 at t ≥ 38 → **38**.
/// - 4 (`10030a04..10030a54`): `0xf6 + s` > 0xfd → e 0 at s ≥ 8 → **16**.
/// - 9 (`10030b98..10030c50`): `(int)(1.5·t)` ≥ 0x13 → a direct 0 at t ≥ 13 → **13**.
/// - 10 (`10030cc0..10030cf8`): a direct 0 at t ≥ 17 → **17**. 11 (`10030c68..10030ca8`): t / 3 ≥ 5 → **15**.
/// - 12 (`10030d10..10030d5c`): t ≥ 0x13 → **19**. 210 / 211 (`100311fc..10031324`): t ≥ 0x15 → **21**.
/// - 220 (`10031578..10031630`): entry 0xff at t ≥ 12 → a direct 0 → **12**; 221 / 222 (`10031644..10031728`): s ≥ 6
///   → **12**; 223 (`1003173c..100317bc`): s ≥ 11 → **22**.
/// - Never 0 (**120**): 3, 5, 6, 7, 8, 199, 200, 201, 202, 203, 205, 213, 215 (its index-0 result is replaced by
///   0x96 for s < 20; the s ≥ 20 entries repeat the s = 19 request, not white).
/// - Not built (**0**, all-zero rows — such a particle dies at its first draw): 0, 14…198, 204, 206…209, 212, 214,
///   216…219, 224…255.
public enum ParticleLife {
    /// `.DrawParticles`' age limit: age ≥ 0x78 → colour 0 (raw `10031b64..10031b6c`).
    public static let ageLimit: Int16 = 0x78

    /// The first zero age of row `kind` (0…255).
    public static let life: [Int16] = {
        var l = [Int16](repeating: 0, count: 0x100)
        for k in [3, 5, 6, 7, 8, 199, 200, 201, 202, 203, 205, 213, 215] { l[k] = 120 }
        l[1] = 24
        l[13] = 24
        l[2] = 38
        l[4] = 16
        l[9] = 13
        l[10] = 17
        l[11] = 15
        l[12] = 19
        l[210] = 21
        l[211] = 21
        l[220] = 12
        l[221] = 12
        l[222] = 12
        l[223] = 22
        return l
    }()

    /// `row[k][age] == 0` for k = 0…255, age = 0…119.
    public static func isZero(kind k: Int, age: Int16) -> Bool {
        age >= life[k]
    }

    /// `.DrawParticles`' colour test (raw `10031b50..10031b94`) on a stored kind and an age ≥ 1: k = `-kind` when
    /// negative (`neg`, then `extsh`); age ≥ 0x78 → 0; k < 0x100 → the row; else `k − 0x100`, low byte only.
    public static func colourIsZero(kind: Int16, age: Int16) -> Bool {
        if age >= ageLimit { return true }
        let k = kind < 0 ? 0 &- kind : kind
        if k < 0x100 {
            // −0x8000 negates to itself (`extsh`): the original indexes before the table; no emitter stores it.
            guard k >= 0 else { return true }
            return isZero(kind: Int(k), age: age)
        }
        return (Int(k) - 0x100) & 0xff == 0
    }
}
