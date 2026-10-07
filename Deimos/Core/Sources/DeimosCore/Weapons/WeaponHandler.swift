import Foundation
import HectorResources

/// The weapon handler embedded at player +0x240 (G_WeaponHandler.cc; weapons-projectiles.md §2.2, plan C15).
/// Offsets are handler-relative (player offset = handler offset + 0x240). ★ LOCKED name (plan S2; moved here from
/// `Player.swift` by C15, fields grown).
///
/// Not kept (no reader anywhere in `0x1003a800..0x1003d030`, raw scan of `lbz/lwz/lhz` at these displacements):
/// +0x10 / +0x30 (bytes the reset sets 0 / 1, `1003b05c`, `1003b088`), +0x60 (second copy of the last air launch,
/// `1003bfd8`), +0x64 / +0x6c / +0x6d (zeroed / 0 / 1 on an air switch), +0x80 / +0x88 / +0x89 (the same on a ground
/// switch), aux record +0x0c / +0x14 / +0x15.
public struct WeaponHandler: Equatable, Sendable {
    /// One power-up block (weapons-projectiles §2.2): air +0x11…+0x2c, ground +0x31…+0x4c (same layout, +0x20).
    public struct PowerUpState: Equatable, Sendable {
        /// +0x11 / +0x31: 0 idle · 1 charging · 2 overloaded · 3 releasing.
        public var state: UInt8 = 0
        /// +0x14 / +0x34: the state's start tick (activation / overload / release).
        public var start: Int32 = 0
        /// +0x18 / +0x38: serial (+0x9c) of the activation entity; −1 after reset.
        public var serial: Int32 = -1
        /// +0x1c / +0x3c: tick of the last power-level step.
        public var lastStep: Int32 = 0
        /// +0x20 / +0x40: power level 0…max.
        public var level: Int32 = 0
        /// +0x24 / +0x44: power percent 0…100.
        public var percent: Float = 0
        /// +0x28 / +0x48: tick of the last release spawn (the activation tick until the first one).
        public var lastRelease: Int32 = 0
        /// +0x2c / +0x4c: consecutive ticks the fire button has been held (0 when up).
        public var held: Int32 = 0

        public init() {}
    }

    /// One auxiliary weapon record (24 bytes, `FUN_1003b180` `'AUX '`, `1003b2cc..1003b31c`). Unreachable with
    /// shipped data: only the unregistered debug command reaches `'AUX '` (weapons-projectiles §2.4, §4).
    public struct AuxRecord: Equatable, Sendable {
        /// +0x00: the weapon definition.
        public var weapon: WeaponDefinition
        /// +0x04 (+0x08 written with it): last launch tick.
        public var lastLaunch: Int32 = 0
        /// +0x10: launches since added — the aux launcher fires every record with a count ≥ 1 (`1003c9a4`).
        public var count: Int32 = 0

        public init(weapon: WeaponDefinition) { self.weapon = weapon }
    }

    /// +0x00 / +0x04: copy of the player's x, y (`FUN_1003bb00`, each active tick); 0.0 after reset.
    public var x: Float = 0
    public var y: Float = 0
    /// +0x08: "score-bar icons need rebuilding" — set by every reset `FUN_1003af90` and every select,
    /// cleared only by setup (hud-scorebar §6.1, loose-ends-combat §6.4).
    public var iconsDirty = false
    /// +0x09 / +0x0a / +0x0b: last tick's fire ground / fire air / select (`1003b9d4..1003b9e8`; edge detection).
    public var previousFireGround = false
    public var previousFireAir = false
    public var previousSelect = false
    /// +0x11…+0x2c: the air power-up.
    public var airPower = PowerUpState()
    /// +0x31…+0x4c: the ground power-up (unreachable with shipped data — Plasma Bomb has no power-up IDs).
    public var groundPower = PowerUpState()
    /// +0x50 / +0x54: pending air / ground weapon.
    public var pendingAir: WeaponDefinition?
    public var pendingGround: WeaponDefinition?
    /// +0x58: current air weapon.
    public var air = WeaponDefinition()
    /// +0x5c: last air launch tick.
    public var lastAirLaunch: Int32 = 0
    /// +0x68: air launches since the weapon was set (the air launcher runs only when ≥ 1, `1003c7bc`).
    public var airLaunches: Int32 = 0
    /// +0x70: the auxiliary weapons.
    public var aux: [AuxRecord] = []
    /// +0x74: current ground weapon.
    public var ground = WeaponDefinition()
    /// +0x78 / +0x7c: last bomb salvo start / last bomb launch tick (both refreshed per bomb).
    public var lastSalvo: Int32 = 0
    public var lastBomb: Int32 = 0
    /// +0x84: bombs still to launch in the current salvo.
    public var bombsPending: Int32 = 0
    /// +0x8c…: the crosshair sprite object. Constructed by the handler constructor `FUN_1003acc0`
    /// (`FUN_100125d0` → the `FUN_10012650` reset: layer `defa`); its +0x4c layer (handler +0xd8) becomes
    /// `plui` only in setup (`1003ae64`, `Player.setupHandler`). Face / frame = handler +0xa8 / +0xac.
    public var crosshair = GameObject()
    /// +0x120: crosshair shown — set on every handler tick (`1003b9ec`), never cleared (loose-ends-combat §6.2).
    public var crosshairShown = false
    /// +0x121: crosshair locked (over a ground target).
    public var crosshairLocked = false
    /// +0x122: owner player index (+0x14 of every spawn request).
    public var owner: Int8 = -1
    /// +0x124 / +0x128: flli 149 / 150 Crosshair_FadeIn / FadeOutPercentageRate (+0x128 has no reader).
    public var crosshairFadeInRate: Float = 0
    public var crosshairFadeOutRate: Float = 0

    public init() {}

    /// +0x24: the air power percent (score-bar power target, `FUN_1003bb20`).
    public var powerPercent: Float {
        get { airPower.percent }
        set { airPower.percent = newValue }
    }

    /// `FUN_1003bce0`: the pending air weapon, else the current one.
    public var effectiveAir: WeaponDefinition { pendingAir ?? air }

    /// `FUN_1003bab0 @ 1003bab0(h, locked)` (listing `1003bab0..1003baf0`): only when +0x120 — locked → frame =
    /// the ground weapon's `crosshairLockedFrame` (+0x174), +0x121 = 1; else `crosshairFrame` (+0x16c), +0x121 = 0.
    /// The face is not changed. Called with 0 at the end of every handler tick and by the reset; the entity update
    /// (`FUN_10033850`, C12) calls it with 1 over a ground target.
    public mutating func setCrosshairLock(_ locked: Bool) {
        guard crosshairShown else { return }                                 // 1003bab0..1003bab8
        if locked {
            crosshair.frame = ground.crosshairLockedFrame                    // 1003bac4..1003bad0
            crosshairLocked = true                                           // 1003bad4
        } else {
            crosshair.frame = ground.crosshairFrame                          // 1003badc..1003bae8
            crosshairLocked = false                                          // 1003baec
        }
    }

    /// `FUN_1003b180 @ 1003b180(h, type, def)` (listing `1003b180..1003b33c`). `PEAA`: def is the current air weapon
    /// → the pending switch is dropped; else air power-up idle → immediate (+0x58 = def, +0x68 = 0, pending 0);
    /// else pending. `PEAG` the same with +0x74 / +0x31 / +0x54 (+0x84 = 0). `'AUX '`: a record of that weapon ID
    /// is removed, else one is appended. Anything else (`IMEF`) is ignored. Weapons compare by tag ID (the
    /// original compares definition pointers; the master list holds one definition per ID).
    public mutating func switchWeapon(type: FourCC, to w: WeaponDefinition) {
        switch type {
        case FourCC("PEAA")!:                                                // 1003b244..1003b290
            if air.id == w.id {
                pendingAir = nil                                             // 1003b288..1003b28c
            } else if airPower.state == 0 {
                air = w                                                      // 1003b25c
                airLaunches = 0                                              // 1003b26c
                pendingAir = nil                                             // 1003b278
            } else {
                pendingAir = w                                               // 1003b280
            }
        case FourCC("PEAG")!:                                                // 1003b1f4..1003b240
            if ground.id == w.id {
                pendingGround = nil                                          // 1003b238..1003b23c
            } else if groundPower.state == 0 {
                ground = w                                                   // 1003b20c
                bombsPending = 0                                             // 1003b21c
                pendingGround = nil                                          // 1003b228
            } else {
                pendingGround = w                                            // 1003b230
            }
        case FourCC("AUX ")!:                                                // 1003b294..1003b31c
            if let k = aux.firstIndex(where: { $0.weapon.id == w.id }) {     // FUN_1003cbf0
                aux.remove(at: k)                                            // 1003b2b4
            } else {
                aux.append(AuxRecord(weapon: w))                             // 1003b2fc..1003b31c
            }
        default:
            break                                                            // 'IMEF' and the rest
        }
    }
}

/// The handler set-up, reset and the definition look-ups that need the game data (G_WeaponHandler.cc,
/// G_WeaponDefinitions.cc). Moved here from `Player.swift` by C15 (plan leg B I12); names unchanged.
extension Player {
    /// `FUN_1003ade0 @ 1003ade0(h, playerIdx, now, sector)` (weapons-projectiles §2.1, listing `1003ade0..
    /// 1003af8c`): pending air/ground 0, reset `FUN_1003af90(h, 0)`, `+0x08` = 0 (`1003ae34`), owner, `+0x124` /
    /// `+0x128` = flli 149/150, crosshair layer `plui` (`1003ae64`), the aux list emptied (`FUN_1003cb30`); ground =
    /// `FUN_1003cca0(1)` (first `DEAG` default) with +0x78 = +0x7c = now and +0x84 = 0; air = `FUN_1003cdb0(sector)`
    /// with +0x5c = now and +0x68 = 0. Either missing → the original's fatal assert (thrown here).
    mutating func setupHandler(now: Int32, sector: Int32) throws {
        handler.pendingAir = nil                                     // 1003ae18
        handler.pendingGround = nil                                  // 1003ae24
        resetHandler(levelStart: false, sector: sector)              // 1003ae28
        handler.iconsDirty = false                                   // 1003ae34
        handler.owner = index                                        // 1003ae3c
        handler.crosshairFadeInRate = assets.floats[149]             // 1003ae48
        handler.crosshairFadeOutRate = assets.floats[150]            // 1003ae5c
        handler.crosshair.layer = FourCC("plui")!                    // 1003ae64 (handler +0xd8)
        handler.aux = []                                             // 1003ae68..1003aec0 (new list / FUN_1003cb30)
        let weapons = assets.definitions.weapons
        guard let ground = weapons.first(where: { $0.default == FourCC("DEAG")! }) else {   // FUN_1003cca0(1)
            throw PlayerError.missingDefinition(type: "wede", id: "DEAG")
        }
        handler.ground = ground                                      // 1003aed4
        handler.lastSalvo = now                                      // 1003aee0
        handler.lastBomb = now                                       // 1003aee4
        handler.bombsPending = 0                                     // 1003aeec
        guard let air = Self.startWeapon(sector: sector, weapons: weapons) else {           // FUN_1003cdb0
            throw PlayerError.missingDefinition(type: "wede", id: "PEAA")
        }
        handler.air = air                                            // 1003af30
        handler.lastAirLaunch = now                                  // 1003af3c
        handler.airLaunches = 0                                      // 1003af48
    }

    /// `FUN_1003af90 @ 1003af90(h, arg)` (listing `1003af90..1003b170`; loose-ends-combat §6.2, §6.5): x, y = 0.0
    /// (`0x100d7270`); the previous-button bytes 0; `+0x08` = 1 (`1003afd4`); bomb timers and salvo 0; air launch
    /// time and count 0; every aux record's times and count 0; both power-up blocks idle (serial −1, percent 0.0);
    /// the pending ground applied (`FUN_1003b180(h, 'PEAG', …)`); with arg 1 (level start) the `PEAA` def whose
    /// minimum == sector (`FUN_1003cd30`) is equipped and the pending air dropped, otherwise (arg 0) the pending air
    /// is applied (`1003b0d4..1003b134`); `FUN_1003bab0(h, 0)`; crosshair visibility = 0.0, target 100.0, step
    /// `+0x124` (`1003b148..1003b15c`). `sector` = game +0x14 (`FUN_10005cd0` at `1003b0dc`), read only with arg 1;
    /// the respawn reset (arg 0) needs none.
    mutating func resetHandler(levelStart: Bool, sector: Int32 = 0) {
        handler.x = 0                                                // 1003afc0
        handler.y = 0                                                // 1003afc4
        handler.previousFireGround = false                           // 1003afc8
        handler.previousFireAir = false                              // 1003afcc
        handler.previousSelect = false                               // 1003afd0
        handler.iconsDirty = true                                    // 1003afd4
        handler.lastSalvo = 0                                        // 1003afd8
        handler.lastBomb = 0                                         // 1003afdc
        handler.bombsPending = 0                                     // 1003afe0
        handler.lastAirLaunch = 0                                    // 1003afec
        handler.airLaunches = 0                                      // 1003aff4
        for k in handler.aux.indices {                               // 1003b000..1003b050
            handler.aux[k].lastLaunch = 0
            handler.aux[k].count = 0
        }
        handler.airPower = WeaponHandler.PowerUpState()              // 1003b054..1003b084
        handler.groundPower = WeaponHandler.PowerUpState()           // 1003b088..1003b0a8
        if let g = handler.pendingGround {                           // 1003b0ac..1003b0d0
            handler.switchWeapon(type: FourCC("PEAG")!, to: g)
            handler.pendingGround = nil
        }
        if levelStart {
            if let w = assets.definitions.weapons.first(where: {     // 1003b0dc..1003b108 FUN_1003cd30
                $0.type == FourCC("PEAA")! && $0.minimumLevelAvailable == sector
            }) {
                handler.switchWeapon(type: FourCC("PEAA")!, to: w)
                handler.pendingAir = nil
            }
        } else if let w = handler.pendingAir {                       // 1003b110..1003b134
            handler.switchWeapon(type: FourCC("PEAA")!, to: w)
            handler.pendingAir = nil
        }
        handler.setCrosshairLock(false)                              // 1003b138..1003b140 FUN_1003bab0(h, 0)
        handler.crosshair.visibility = 0                             // 1003b148..1003b150
        handler.crosshair.visibilityTarget = 100                     // 1003b14c..1003b154
        handler.crosshair.visibilityStep = handler.crosshairFadeInRate   // 1003b158..1003b15c
    }

    /// `FUN_1003cdb0(L)`: among `PEAA` with min ≤ L ≤ max, the largest minimum (first wins ties).
    static func startWeapon(sector: Int32, weapons: [WeaponDefinition]) -> WeaponDefinition? {
        var best: WeaponDefinition?
        for w in weapons where w.type == FourCC("PEAA")!
            && w.minimumLevelAvailable <= sector && sector <= w.maximumLevelAvailable {
            if best == nil || w.minimumLevelAvailable > best!.minimumLevelAvailable { best = w }
        }
        return best
    }

    /// `FUN_1002adb0(type, cur, L)` — the select cycle (weapons-projectiles §1.3, HIGH): the matches are
    /// the definitions of `type` with min ≤ L ≤ max, in list order; `cur` none → the first; else the match
    /// after `cur`, wrapping to the first when `cur` is last or not a match; nil when nothing matches.
    static func nextWeapon(type: FourCC, after cur: FourCC, sector: Int32,
                           weapons: [WeaponDefinition]) -> WeaponDefinition? {
        let matches = weapons.filter {
            $0.type == type && $0.minimumLevelAvailable <= sector && sector <= $0.maximumLevelAvailable
        }
        guard let first = matches.first else { return nil }
        guard cur != .none, let i = matches.firstIndex(where: { $0.id == cur }), i + 1 < matches.count else {
            return first
        }
        return matches[i + 1]
    }

    /// `FUN_1003bb40 @ 1003bb40(handler, out[6])` (hud-scorebar §6, HIGH): {face, frame} of the effective
    /// air weapon, the next in the select cycle and the one after; a pair that repeats an earlier one
    /// (by face + frame) is `none`. `sector` = game +0x14 (`FUN_10005cd0` in `FUN_1003bb40`).
    public func scoreBarIcons(sector: Int32) -> [ScoreBarState.Icon] {
        let weapons = assets.definitions.weapons
        let peaa = FourCC("PEAA")!
        let cur = handler.effectiveAir
        func icon(_ w: WeaponDefinition) -> ScoreBarState.Icon {
            ScoreBarState.Icon(face: w.scoreBarPreviewFace, frame: w.scoreBarPreviewFrame)
        }
        let slot0 = icon(cur)
        let n1 = Self.nextWeapon(type: peaa, after: cur.id, sector: sector, weapons: weapons)
        let slot1 = n1.map(icon) ?? slot0
        if slot1 == slot0 { return [slot0, .none, .none] }
        let n2 = Self.nextWeapon(type: peaa, after: n1!.id, sector: sector, weapons: weapons)
        let slot2 = n2.map(icon) ?? slot0
        return [slot0, slot1, (slot2 == slot0 || slot2 == slot1) ? .none : slot2]
    }

    /// `scoreBarIcons(sector:)` at the sector given to `setup` — for the callers that pass none (◇ Phase-1 session).
    public func scoreBarIcons() -> [ScoreBarState.Icon] { scoreBarIcons(sector: sector) }
}
