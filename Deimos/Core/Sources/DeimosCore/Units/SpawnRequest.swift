import Foundation
import HectorResources

/// The 0x2c-byte spawn request, argument of `FUN_10033220` (spawn-and-waves.md §1.1, weapons-projectiles
/// §3.1, loose-ends-combat §4.3–§4.4; HIGH). ★ LOCKED (plan S2). The defaults are the **runtime** template:
/// all five templates (`0x100e3ca4` game, `0x100e64b0` spawn sets, `0x100e91d4` player, `0x100eb41c` level
/// objects, `0x100ecd14` weapons) hold `'none'`, zeros, +0x14 = 0xff and +0x28 = 1.0f in the image, and
/// their static initialisers set +0x24 = −1 before `main` (static-init-audit.md §3, §5; INDEX #56).
public struct SpawnRequest: Equatable, Sendable {
    /// +0x00: the unit ID to spawn (`none` → assert in `FUN_10033220`).
    public var unit: FourCC = .none
    /// +0x04 / +0x08: the group position (float).
    public var x: Float = 0
    public var y: Float = 0
    /// +0x0c: y is a map row → group y = trunc(y) − window top (`10033524..10033570`).
    public var yIsMapRow = false
    /// +0x0d / +0x10: heading supplied (spawn set `SetHeading`) / that heading in compass degrees.
    public var headingSupplied = false
    public var heading: Int32 = 0
    /// +0x14: the owning player (−1 = 0xff none) → entity +0xd8.
    public var player: Int8 = -1
    /// +0x18: the editor heading (level `headingDegrees`) → group +0xb4.
    public var editorHeading: Int32 = 0
    /// +0x1c / +0x1d: stationary / terrain-effects options → group +0xb8/+0xb9, entity +0x13c/+0x13d.
    public var stationary = false
    public var terrainEffects = false
    /// +0x20: the owner entity (a pool slot; nil = null pointer) → entity +0x140.
    public var owner: Int? = nil
    /// +0x24: the owner's serial → entity +0x144 (−1 at run time).
    public var ownerSerial: Int32 = -1
    /// +0x28: speed multiplier for `FUN_10037b50` (1.0; only the ground launcher writes another value).
    public var speedMultiplier: Float = 1

    /// The runtime template.
    public init() {}

    public init(unit: FourCC, x: Float, y: Float) {
        self.unit = unit
        self.x = x
        self.y = y
    }

    /// The runtime value of every request template.
    public static let template = SpawnRequest()
}

/// `FUN_10035cd0`'s out-parameter: the created member's pool slot and serial (+0x9c).
public struct SpawnResult: Equatable, Sendable {
    public var entity: Int
    public var serial: Int32

    public init(entity: Int, serial: Int32) {
        self.entity = entity
        self.serial = serial
    }
}
