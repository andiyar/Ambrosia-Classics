import Foundation
import HectorResources

/// The media mask lookup (sprite-sound-containers.md §3.1, gameplay-leftovers.md §7.4a; plan C11b).
///
/// Listing read: `FUN_1000fee0(&point) @ 1000fee0` (`1000fee0..1000ffb4`): r30 = 0 (`1000feec`); size (w, h) =
/// `FUN_1000a480(mask)`; col = x `divw` e, row = y `divw` e with e = `_DAT_100e0134` (`1000ff20..1000ff2c`, C
/// division toward zero); `0 ≤ col < w` and `0 ≤ row < h` (tested **after** the division, so −(e−1)…−1 fall into
/// cell 0) → the 16-bit cell at row·rowBytes + 2·col (`1000ff5c..1000ff88`) == 0x001f → 1 (`1000ff98`); else 0.
extension MediaMask {
    /// `FUN_1000fee0` — true (1, water) iff the mask cell under map point (x, y) is 0x001f. An unloaded mask
    /// (scale 0 or no cells) answers false: the original always has a mask at this point (`FUN_1000fbc0` at level
    /// start), and a `divw` by 0 must not trap here.
    public func isWater(x: Int32, y: Int32) -> Bool {
        guard scale != 0, !cells.isEmpty else { return false }
        let col = x / scale                                             // 1000ff28 divw.
        let row = y / scale                                             // 1000ff2c divw
        guard col >= 0, col < width, row >= 0, row < height else { return false }   // 1000ff38..1000ff58
        let k = Int(row) * Int(width) + Int(col)                        // 1000ff70..1000ff84
        guard cells.indices.contains(k) else { return false }
        return cells[k] == 0x001f                                       // 1000ff88..1000ff98
    }
}

/// The destruct/deletion spawn's media gate (damage-health-death.md §4.2; plan C11b).
///
/// Listing read: `FUN_10016880(e) @ 10016880` (`10016880..10016bc4`): unit not `isGroundBased` (+0x125) or
/// `doDeathSpawnOnAnyMedia` (+0x12b) → 1 (`10016898..100168b0`, `10016bac`). Else the point (`fctiwz(x)` + 32,
/// `fctiwz(y)` + `FUN_1000fec0()` = window top `0x100e5acc`) (`100168b4..100168f8`) → `FUN_1000fee0`: 0 → 1; 1 → the
/// water impact by `mediaImpactSize_ID` (+0x2e4; 0 or `none` → none): `tiny` O6, `smal` O7, `med ` O8, `larg` O9,
/// `smra` **draw `10016a24`** `R(0, 1)` ≠ 0 → O6 else O7, `mera` **draw `10016a64`** `R(0, 2)` 0 → O6, 1 → O7,
/// else O8, `lara` **draw `10016ac8`** `R(0, 1)` ≠ 0 → O8 else O9, any other → none; a non-`none` impact → the
/// template r2+0x180 with +0x00 the object, the position, +0x14 = +0xd8, +0x20 = e, +0x24 = +0x9c →
/// `FUN_10033220` (`10016b08..10016ba0`); returns 0 either way.
extension GameState {
    static let tiny = FourCC("tiny")!, smal = FourCC("smal")!, med = FourCC("med ")!, larg = FourCC("larg")!,
               smra = FourCC("smra")!, mera = FourCC("mera")!, lara = FourCC("lara")!

    /// `FUN_10016880(e)` — may entity `i`'s destruct / deletion spawn appear where it is? Over water it spawns the
    /// water impact instead and answers false.
    public mutating func mediaGate(_ i: Int) -> Bool {
        let u = assets.definitions.units[world.entities[i].unit]
        guard u.isGroundBased, !u.doDeathSpawnOnAnyMedia else { return true }   // 1001689c..100168b0
        let o = world.entities[i].object                                     // 100168b4..100168bc FUN_100128f0
        let x = EntityDraw.fctiwz(o.x) &+ 32                                 // 100168c4..100168d8
        let y = EntityDraw.fctiwz(o.y) &+ scroll.window.top                  // 100168dc..100168f8
        guard mask.isWater(x: x, y: y) else { return true }                  // 10016900..10016928
        func obj(_ k: Int) -> FourCC { assets.objects.indices.contains(k) ? assets.objects[k] : .none }
        let impact: FourCC                                                   // r6 = 'none' (10016930..10016934)
        switch u.mediaImpactSize {                                           // 1001692c..100169c8
        case Self.tiny: impact = obj(6)
        case Self.smal: impact = obj(7)
        case Self.med: impact = obj(8)
        case Self.larg: impact = obj(9)
        case Self.smra: impact = rng.range(Int32(0), 1) != 0 ? obj(6) : obj(7)      // 10016a1c..10016a58
        case Self.mera:                                                      // 10016a5c..10016abc
            switch rng.range(Int32(0), 2) {
            case 0: impact = obj(6)
            case 1: impact = obj(7)
            default: impact = obj(8)
            }
        case Self.lara: impact = rng.range(Int32(0), 1) != 0 ? obj(8) : obj(9)      // 10016ac0..10016af8
        default: impact = .none
        }
        if impact != .none {                                                 // 10016afc..10016b04
            spawn(childRequest(i, unit: impact))                             // 10016b08..10016ba0
        }
        return false
    }
}
