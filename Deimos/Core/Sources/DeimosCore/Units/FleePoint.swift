import Foundation
import HectorResources

/// `FUN_10017510(e, code) @ 10017510` — the flee target (units-movement.md §6, HIGH; listing `10017510..
/// 10017a04`, read for C8, which owns it — plan review m5). Fleeing +0xcc = 1 **first** (`1001753c`), then
/// the target point +0x11c/+0x120 by the 4CC compare tree (`10017538..1001762c`). W, H = PermFloat 54/55
/// (416, 480); the flee edges are PermFloat 14/15/16/17 (north −1000, south 2000, west −1000, east 2000);
/// F(0, b) = `FUN_100465e0(0.0, b)` (lower bound `*(float*)0x100d6c8c` = 0.0); `·0.5` = `fmuls` by
/// `*(float*)0x100d6ca0` = 0.5. Draw sites:
/// | code | x | y | draws (address) |
/// |---|---|---|---|
/// | `nora` / `sora` | F(0, W) | north / south | `10017644` / `10017678` |
/// | `noce` / `soce` | W·0.5 | north / south | — |
/// | `wece` / `eace` | west / east | H·0.5 | — |
/// | `wera` / `eara` | west / east | F(0, H) | `100176bc` / `100176f0` |
/// | `cega` | W·0.5 | H·0.5 | — |
/// | `opve` | F(0, W) | y > H·0.5 → north, else south | `100177e4` / `10017818` |
/// | `opho` | x > W·0.5 → west, else east | F(0, H) | `10017880` / `100178b0` |
/// | `rave` | F(0, W) | `R(0,1)` ≠ 0 → north, else south | `100178c8` then `100178ec` / `10017920` |
/// | `raho` | `R(0,1)` ≠ 0 → east, else west | F(0, H) | `10017948` then `10017980` / `100179b0` |
/// Any other code (`none` included) sets only the fleeing flag. Within a code x is written before y, and the
/// int draw precedes the float draw.
extension GameState {
    public mutating func setFleePoint(_ i: Int, code: FourCC) {
        world.entities[i].fleeing = true                                       // 1001753c
        let w = assets.floats[54], h = assets.floats[55]
        let north = assets.floats[14], south = assets.floats[15]
        let west = assets.floats[16], east = assets.floats[17]
        let half: Float = 0.5
        var x: Float? = nil, y: Float? = nil
        switch code {
        case FourCC("nora")!: x = rng.range(Float(0), w); y = north                     // 10017630..1001765c
        case FourCC("sora")!: x = rng.range(Float(0), w); y = south                     // 10017664..10017690
        case FourCC("wera")!: x = west; y = rng.range(Float(0), h)                      // 10017698..100176c4
        case FourCC("eara")!: x = east; y = rng.range(Float(0), h)                      // 100176cc..100176f8
        case FourCC("noce")!: x = w * half; y = north                                   // 10017700..10017724
        case FourCC("soce")!: x = w * half; y = south                                   // 1001772c..10017750
        case FourCC("wece")!: x = west; y = h * half                                    // 10017758..1001777c
        case FourCC("eace")!: x = east; y = h * half                                    // 10017784..100177a8
        case FourCC("opve")!:                                                           // 100177b0..10017830
            let ey = world.entities[i].object.y
            x = rng.range(Float(0), w)
            y = ey > h * half ? north : south
        case FourCC("opho")!:                                                           // 10017838..100178b8
            let ex = world.entities[i].object.x
            x = ex > w * half ? west : east
            y = rng.range(Float(0), h)
        case FourCC("rave")!:                                                           // 100178c0..10017938
            let r = rng.range(Int32(0), 1)
            x = rng.range(Float(0), w)
            y = r != 0 ? north : south
        case FourCC("raho")!:                                                           // 10017940..100179b8
            let r = rng.range(Int32(0), 1)
            x = r != 0 ? east : west
            y = rng.range(Float(0), h)
        case FourCC("cega")!: x = w * half; y = h * half                                // 100179c0..100179ec
        default: break                                                         // 100179f0
        }
        if let x { world.entities[i].targetX = x }
        if let y { world.entities[i].targetY = y }
    }
}
