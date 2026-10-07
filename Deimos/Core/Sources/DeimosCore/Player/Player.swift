import Foundation
import HectorResources

/// The shared G_GameObject part of the player, of every entity and of the crosshair sprite object
/// (sprite-geometry-draw.md §2.1, player-physics.md §1). Defaults are `FUN_10012650`'s reset
/// (micro-wave-2026-10-06.md §3.6, listing `10012650..10012748`); +0x64 (glow-tint colour) and the hit-glow
/// level/step/colour (+0x78/+0x7c/+0x80) are not reset by it and start at the constructor's zero here.
/// Two distinct effects (sprite-geometry-draw §4.2–§4.3): the **glow triple** +0x58/+0x5c/+0x60 (ramped by
/// `FUN_10012750`, drawn as the second, **tint pass** in colour +0x64) and the **hit glow** +0x74 (third pass).
public struct GameObject: Equatable, Sendable {
    /// +0x00 / +0x04: centre x, y in game-area coordinates (single precision).
    public var x: Float = 0
    public var y: Float = 0
    /// +0x10 / +0x14: velocity, px per tick.
    public var vx: Float = 0
    public var vy: Float = 0
    /// +0x18: pans with the horizontal view offset (draw x −= `_DAT_100e0144`, the scroll offset).
    public var pansWithView = true
    /// +0x19: air (1) / ground (0) — the shadow style for layer `defa`.
    public var air = true
    /// +0x1a: adjustShadowLocForScaling.
    public var adjustShadowForScaling = false
    /// +0x1c / +0x20: sprite group / frame.
    public var face: FourCC = .none
    public var frame: Int32 = 0
    /// +0x24 / +0x28: scaled frame w′, h′; +0x2c / +0x30: half (C division) — `FUN_10012940`.
    public var scaledWidth: Int32 = 0
    public var scaledHeight: Int32 = 0
    public var halfWidth: Int32 = 0
    public var halfHeight: Int32 = 0
    /// +0x34: size dirty (cleared by `FUN_10012940`).
    public var sizeDirty = true
    /// +0x35: draw immediately (skip the render queue).
    public var drawNow = false
    /// +0x36: draw into the terrain buffer.
    public var drawToTerrain = false
    /// +0x37 / +0x38: draw-sprite / draw-shadow pass selectors.
    public var drawSprite = true
    public var drawShadow = true
    /// +0x3c..+0x48: clip rect, default {0, 0, 480, 416}.
    public var clip = MacRect(top: 0, left: 0, bottom: 480, right: 416)
    /// +0x4c: draw-layer 4CC (`defa` after reset).
    public var layer: FourCC = FourCC("defa")!
    /// +0x54: hide the normal sprite pass.
    public var hideSprite = false
    /// +0x58 / +0x5c / +0x60: the glow triple — current / target / step (%), drawn by the tint pass.
    public var glow: Float = 0
    public var glowTarget: Float = 0
    public var glowStep: Float = 0
    /// +0x64: the tint pass's colour (x1R5G5B5).
    public var glowTintColour: UInt16 = 0
    /// +0x68 / +0x6c / +0x70: the visibility ramp — current / target / step (%).
    public var visibility: Float = 100
    public var visibilityTarget: Float = 100
    public var visibilityStep: Float = 0
    /// +0x74 / +0x78 / +0x80: the hit glow (not the glow triple) — on / level (alpha) / colour.
    public var hitGlowOn = false
    public var hitGlowLevel: Int32 = 0
    public var hitGlowColour: UInt16 = 0
    /// +0x75 / +0x7c: the hit glow's phase — 1 = level falling 32 → 4, 0 = rising back to 32 (toggled by
    /// `FUN_10012c10` `10012c4c..10012c58` / `10012c88..10012c94`) — and its step per tick (`FUN_10012bc0`
    /// `10012bf0 stb r6,0x75`, `10012bf4 stw r5,0x7c`). Like +0x78/+0x80, not reset by `FUN_10012650`.
    public var hitGlowFalling = false
    public var hitGlowStep: Int32 = 0
    /// +0x84 / +0x88 / +0x8c: scale current / target / step.
    public var scale: Float = 1
    public var scaleTarget: Float = 1
    public var scaleStep: Float = 0

    public init() {}

    /// `FUN_10012750 @ 10012750` — the visibility ramp then the glow-triple ramp, per tick [HIGH, listing
    /// `10012750..10012838`; gameplay-leftovers.md §2.1]. Each: `fcmpo cur, target`; cur > target →
    /// cur −= step (`fsubs`), cur < 0.0 → 0.0 (floor `r2−0x7248` → 0.0), cur < target → target;
    /// cur < target → cur += step (`fadds`), cur > target → target; equal → unchanged. Single precision.
    public mutating func stepRamps() {
        Self.ramp(&visibility, visibilityTarget, visibilityStep)     // 10012750..100127c4
        Self.ramp(&glow, glowTarget, glowStep)                       // 100127c8..10012838
    }

    private static func ramp(_ cur: inout Float, _ target: Float, _ step: Float) {
        if cur > target {
            cur = cur - step
            if cur < 0 { cur = 0 }
            if cur < target { cur = target }
        } else if cur < target {
            cur = cur + step
            if cur > target { cur = target }
        }
    }

    /// `FUN_10012840 @ 10012840` — the scale ramp (+0x84 toward +0x88 by +0x8c, clamped at the target;
    /// sets +0x34 whenever it moves). A no-op at scale 1.0 = target 1.0 (the player in Phase 1).
    public mutating func stepScale() {
        if scale > scaleTarget {                                     // 10012848 fcmpo; ble
            sizeDirty = true
            scale = scale - scaleStep
            if scale < scaleTarget { scale = scaleTarget }
        } else if scale < scaleTarget {                              // 10012880 bgelr
            sizeDirty = true
            scale = scale + scaleStep
            if scale > scaleTarget { scale = scaleTarget }
        }
    }

    /// `FUN_10012bc0 @ 10012bc0(obj, colour, step, force)` — start the hit glow (listing `10012bc0..10012bfc`):
    /// already on and not `force` → nothing; else on, level 32, falling, step, colour.
    public mutating func startHitGlow(colour: UInt16, step: Int32, force: Bool) {
        if hitGlowOn && !force { return }                            // 10012bc0..10012bdc
        hitGlowOn = true                                             // 10012be4
        hitGlowLevel = 32                                            // 10012be8..10012bec
        hitGlowFalling = true                                        // 10012bf0
        hitGlowStep = step                                           // 10012bf4
        hitGlowColour = colour                                       // 10012bf8
    }

    /// `FUN_10012c10 @ 10012c10` — the hit-glow tick (listing `10012c10..10012c9c`, unsigned compares):
    /// falling → level −= step; level (unsigned) < 4 → 4 and rising. Rising → level += step; level
    /// (unsigned) > 32 → 32, falling again and the glow off.
    public mutating func stepHitGlow() {
        guard hitGlowOn else { return }                              // 10012c10..10012c18
        if hitGlowFalling {
            hitGlowLevel = hitGlowLevel &- hitGlowStep               // 10012c28..10012c34
            if UInt32(bitPattern: hitGlowLevel) >= 4 { return }      // 10012c3c cmplwi; bgelr
            hitGlowLevel = 4                                         // 10012c44..10012c48
            hitGlowFalling = false                                   // 10012c4c..10012c58 (cntlzw toggle)
        } else {
            hitGlowLevel = hitGlowLevel &+ hitGlowStep               // 10012c60..10012c6c
            if UInt32(bitPattern: hitGlowLevel) <= 32 { return }     // 10012c74 cmplwi; blelr
            hitGlowLevel = 32                                        // 10012c7c..10012c80
            hitGlowFalling = true                                    // 10012c88..10012c94
            hitGlowOn = false                                        // 10012c98
        }
    }

    /// `FUN_10012940 @ 10012940` — half-size refresh, only when +0x34 is set: face `none` → 0, 0;
    /// else w′, h′ from the frame (`FUN_10019ca0(face, frame, scale)`; +0x50 is 0 for the player and the
    /// crosshair) and half = C division by 2 (`rlwinm; add; srawi`); clears +0x34. `frameSize` returns the
    /// frame's (w′, h′) at `scale` — scale 1.0 throughout Phase 1.
    public mutating func refreshSize(_ frameSize: (FourCC, Int32, Float) -> (Int32, Int32)) {
        guard sizeDirty else { return }                              // 10012954
        if face == .none {                                           // 10012960..1001296c
            halfWidth = 0; halfHeight = 0
        } else {
            (scaledWidth, scaledHeight) = frameSize(face, frame, scale)
            halfWidth = scaledWidth / 2                              // 100129a8..100129bc
            halfHeight = scaledHeight / 2                            // 100129c0..100129d0
        }
        sizeDirty = false
    }
}

/// The player object (G_Player.cc, 0x36c bytes; player-physics.md §1). Field comments cite the original
/// offsets. Obfuscated stores (lives +0x1524dcef, money +0xb2cce, score +0x5532a3e — integer, lossless)
/// are kept plain; the shield's float obfuscation is lossy and is reproduced (`shield`).
/// ★ LOCKED name (plan S2). The update is `GameState.updatePlayer(_:input:)` (PlayerUpdate.swift, C14); the ◇ Phase-1
/// stub `updatePhase1` (PlayerPhase1.swift) stays until C18b deletes it.
public struct Player: Sendable {
    let assets: DeimosAssets

    /// +0x00…+0x93: the G_GameObject part.
    public var object = GameObject()
    /// +0x94: the `plde` definition (`pl01` / `pl02` by PermObjectID index).
    public var definition = PlayerDefinition()
    /// +0x98: lives (stored + 0x1524dcef in the original).
    public var lives: Int32 = 0
    /// +0x9c / +0xa0: next extra-life threshold / step.
    public var extraLifeThreshold: Int32 = 0
    public var extraLifeStep: Int32 = 0
    /// +0xa4: max speed (`active_DefaultMaxSpeed`).
    public var maxSpeed: Float = 0
    /// +0xa8: shield, stored as shield + 1324366.0 (single precision, `FUN_10027560` `fadds`).
    public private(set) var shieldStored: Float = Player.shieldBias
    /// +0xac: money (stored + 0xb2cce).
    public var money: Int32 = 0
    /// +0xb0: score (stored + 0x5532a3e).
    public var score: Int32 = 0
    /// +0xb4: score multiplier.
    public var multiplier: UInt8 = 1
    /// +0xb8: serial of the multiplier indicator unit, −1 none (constructor `100262d8`; `FUN_10029fe0`;
    /// scoring-bonuses §1.1). Declared by C7 (field only).
    public var multiplierIndicator: Int32 = -1
    /// +0xbd: cheated this game — set by every console cheat (`bl 0x10029bf0` with r4 = 1,
    /// `0x10008118–0x100091bc`; scoring-bonuses §1.1); 0 from the constructor (`100262e0`). Declared by C7
    /// (field only; C19 sets it).
    public var cheated = false
    /// +0xc0: level reference (game +0x18) given at level start.
    public var levelRef: FourCC = .none
    /// +0xc4: in game (not eliminated).
    public var inGame = false
    /// +0xc5: appear fade running.
    public var appearing = false
    /// +0xc6 / +0xc8: life state 0..4 and the time it was entered (`FUN_10026c80`).
    public var lifeState: UInt8 = 0
    public var stateEntered: Int32 = 0
    /// +0xcc: player index 0/1 (−1 = unused). +0xcd: players in this game.
    public var index: Int8 = -1
    public var playerCount: UInt8 = 1
    /// +0xce / +0xcf: invulnerable / sticky.
    public var invulnerable = false
    public var invulnerableSticky = false
    /// +0xd0: hit this level. +0xd1: shield warning shown.
    public var hitThisLevel = false
    public var shieldWarningShown = false
    /// +0xd4: tick of the last banking-frame opportunity.
    public var lastBankingTick: Int32 = 0
    /// +0x1fc…+0x202: this tick's input bytes (up, right, down, left, fire ground, fire air, select),
    /// as the film byte's bits.
    public var input: PlayerInput = []
    /// +0x204 / +0x208: last accepted hit / last spawn-on-hit tick.
    public var lastHit: Int32 = 0
    public var lastHitSpawn: Int32 = 0
    /// +0x20c: crosshair forward adjustment 0…80.
    public var crosshairAdjust: Int32 = 0
    /// +0x210 / +0x211 / +0x214 / +0x218 / +0x21c / +0x220: overload warning active, phase, glow, last
    /// flash, interval, count (cleared by `FUN_10026ea0`; never started in Phase 1).
    public var overloadActive = false
    public var overloadPhase: UInt8 = 0
    public var overloadGlow: Float = 0
    public var overloadLast: Int32 = 0
    public var overloadInterval: Int32 = 0
    public var overloadCount: Int32 = 0
    /// +0x234 / +0x238: integrity-check tick (= level start + R(400, 2000), P1 only) and pass count.
    public var integrityCheckTick: Int32 = 0
    public var integrityPasses: Int32 = 0
    /// +0x240: the weapon handler.
    public var handler = WeaponHandler()
    /// The sector given to `setup` — a per-player copy of game +0x14 (`FUN_10005cd0`) kept only for callers that
    /// pass no sector: the ◇ Phase-1 session (`DeimosSession`, deleted by C18b), `levelStart` / `scoreBarIcons()`
    /// without a `sector:` argument and `ScoreBarState` without one. The original reads G+0x14 everywhere: every
    /// `GameState` path passes `flags.sector` (C15 review); not a model of any original field.
    public var sector: Int32 = 1

    /// pf[2] (`0x100d6fc8` + 8): the shield obfuscation bias.
    static let shieldBias: Float = 1_324_366.0

    /// `FUN_10026260` (constructor, `FUN_100125d0` → `FUN_10012650` reset): lives 0, money 0, score 0,
    /// index 0xff, players 1, shield stored 0.
    public init(assets: DeimosAssets) {
        self.assets = assets
        shield = 0
    }

    /// `FUN_10027540` (get: `stored − 1324366.0`, `fsubs`) / `FUN_10027560` (set: `1324366.0 + v`, `fadds`).
    public var shield: Float {
        get { shieldStored - Self.shieldBias }
        set { shieldStored = Self.shieldBias + newValue }
    }

    /// `FUN_10026410 @ 10026410(player, index, numPlayers, now, sector)` — the Phase-1 subset
    /// (player-physics §7, listing `10026434..10026990`): `+0xcd`, `+0xcc`; plde = PermObjectID index
    /// (`pl01`/`pl02`); `+0xc4` = 0, then 1 for index 0, or for both when `numPlayers ≠ 1`
    /// (`10026820..10026878`); lives `FUN_10026cc0(p, sector == 1)` = `life_NumInitial` (3) at sector 1
    /// else 1, threshold `life_InitialRequiredScore` (not in game: lives stay the constructor's 0); money 0,
    /// score 0, multiplier 1; shield `FUN_10027400(p, 1)` = `defaultShieldPercentage` (100; 0 when not in
    /// game); handler setup `FUN_1003ade0`; max speed; `FUN_10027400(p, 0)` (hit timers); cheated flag 0;
    /// overload cleared `FUN_10026ea0`; state 2 at now with the input bytes cleared if in game
    /// (`10026918..10026934`), else state 1. The permanent unit loads and the `+0x23c` integrity flag are
    /// not modelled. Throws when a definition is missing (the original's fatal "GAME DATA INCORRECT").
    public mutating func setup(index: Int, players: Int, sector: Int, now: Int32 = 0) throws {
        playerCount = UInt8(truncatingIfNeeded: players)             // 10026434
        self.index = Int8(truncatingIfNeeded: index)                 // 10026438
        self.sector = Int32(sector)
        guard assets.objects.indices.contains(index) else { throw PlayerError.invalidIndex(index) }
        let id = assets.objects[index]                               // 1002645c / 1002646c: PermObjectID 0 / 1
        guard let plde = assets.definitions.players.first(where: { $0.id == id }) else {
            throw PlayerError.missingDefinition(type: "plde", id: id.description)
        }
        definition = plde                                            // 10026490
        inGame = false                                               // 100264d8
        if players != 1 || index == 0 {                              // 10026820..10026878
            inGame = true
            lives = sector == 1 ? plde.lifeNumInitial : 1            // FUN_10026cc0
            extraLifeThreshold = plde.lifeInitialRequiredScore
            extraLifeStep = 0
        }
        money = 0                                                    // 10026880 FUN_10027580
        score = 0                                                    // 1002688c FUN_100299c0
        multiplier = 1                                               // 10026898 FUN_10029fd0
        resetShield(full: true)                                      // 100268a8 FUN_10027400(p, 1)
        try setupHandler(now: now, sector: Int32(sector))            // 100268c0 FUN_1003ade0
        maxSpeed = plde.activeDefaultMaxSpeed                        // 100268cc FUN_10026cb0
        resetShield(full: false)                                     // 100268dc FUN_10027400(p, 0)
        cheated = false                                              // 100268ec FUN_10029bf0(p, 0)
        clearOverload()                                              // 10026904 FUN_10026ea0
        if inGame {
            setLifeState(2, now: now)                                // 10026924
            input = []                                               // 10026934 FUN_1000cd90(+0x1fc, 7)
        } else {
            setLifeState(1, now: now)                                // 1002694c
        }
    }

    /// `FUN_100269a0 @ 100269a0(player, levelRef, now)` (player-physics §4.2; listing `100269c4..10026af0`):
    /// returns at once when not in game. Else `+0xd0` = 0; handler reset `FUN_1003af90(h, 1)`; `+0xc5` = 0;
    /// `+0xc0` = levelRef; ship sprite `FUN_10029f10`; size `FUN_10012940`; start position, velocity 0,
    /// crosshair adjust 0, overload cleared `FUN_10026b10`; **state 2 at now** (`10026a20`); glow off
    /// `FUN_10012c00`; money 0; money counter reset (`FUN_10027630` — modelled by `GameState.playerLevelStart` on `TallyState.coin`); shield
    /// `FUN_10027400(p, 1)`; overload cleared; appear fade = flli 163/164/165 (`10026a6c..10026a98`); then
    /// exactly one `FUN_10046580(400, 2000)` (`10026a9c`), whose result only P1 keeps: `+0x234` = now + R,
    /// `+0x238` = 0 (`10026ab4 extsb.; bne`; the registration reads `FUN_1007ec40…` are not modelled).
    /// `sector` = game +0x14 for the reset's `FUN_1003cd30`; nil → the copy given to `setup` (Phase-1 callers).
    public mutating func levelStart(now: Int32, rng: inout MSLRandom, levelRef: FourCC = .none,
                                    sector: Int32? = nil) {
        guard inGame else { return }                                 // 100269c4..100269cc
        hitThisLevel = false                                         // 100269d4
        resetHandler(levelStart: true, sector: sector ?? self.sector)   // 100269e0 FUN_1003af90(h, 1)
        appearing = false                                            // 100269ec
        self.levelRef = levelRef                                     // 100269f4
        resetShipSprite()                                            // 100269f8 FUN_10029f10
        refreshSize()                                                // 10026a04 FUN_10012940
        placeAtStart()                                               // 10026a10 FUN_10026b10
        setLifeState(2, now: now)                                    // 10026a24
        object.hitGlowOn = false                                     // 10026a30 FUN_10012c00
        money = 0                                                    // 10026a3c FUN_10027580
        resetShield(full: true)                                      // 10026a58 FUN_10027400(p, 1)
        clearOverload()                                              // 10026a64 FUN_10026ea0
        setAppearFade()                                              // 10026a6c..10026a98
        let r = rng.range(Int32(400), Int32(2000))                             // 10026a9c..10026aa4
        if index == 0 {                                              // 10026aac..10026ab8
            integrityCheckTick = now &+ r                            // 10026ae4..10026aec
            integrityPasses = 0                                      // 10026af0
        }
    }

    // MARK: - Helpers (original functions)

    /// `FUN_10026c80`: state and entry time.
    mutating func setLifeState(_ s: UInt8, now: Int32) {
        lifeState = s
        stateEntered = now
    }

    /// `FUN_10027400(p, full)`: not in game → shield 0; else if `full` → `defaultShieldPercentage`
    /// (int → float); then last hit / last spawn 0, `+0xd1` = 0 (`10027414..10027478`).
    mutating func resetShield(full: Bool) {
        if !inGame {
            shield = 0
        } else if full {
            shield = Float(definition.defaultShieldPercentage)
        }
        lastHit = 0
        lastHitSpawn = 0
        shieldWarningShown = false
    }

    /// `FUN_10026ea0`: overload cleared, `+0x54` = 0, glow triple 0.0, glow-tint colour 0x7fff.
    mutating func clearOverload() {
        overloadActive = false; overloadPhase = 0; overloadGlow = 0
        overloadLast = 0; overloadInterval = 0; overloadCount = 0
        object.hideSprite = false
        object.glow = 0; object.glowTarget = 0; object.glowStep = 0
        object.glowTintColour = 0x7fff
    }

    /// `FUN_10029f10` → `FUN_10029f60`: face = the effective air weapon's appearance for this index
    /// (`+0x144` P1, `+0x148` P2), `+0x34` = 1; then frame 0, `+0xd4` = 0, `+0x4c` = `play`.
    mutating func resetShipSprite() {
        refreshFaceFromWeapon()                                      // 10029f24 FUN_10029f60
        object.frame = 0                                             // 10029f30
        lastBankingTick = 0                                          // 10029f3c
        object.layer = FourCC("play")!                               // 10029f40
    }

    /// `FUN_10029f60 @ 10029f60` — face = the effective air weapon's appearance for this index (`+0x144`
    /// P1, `+0x148` P2; any other index leaves the face), `+0x34` = 1. Also called by the player update when
    /// the handler tick reports a select (`10029104..10029118`; C15's `tickWeapons` calls it).
    mutating func refreshFaceFromWeapon() {
        let w = handler.effectiveAir                                 // 10029f78 FUN_1003bce0
        switch index {                                               // 10029f80..10029fb0
        case 0: object.face = w.player1AppearanceFace
        case 1: object.face = w.player2AppearanceFace
        default: break
        }
        object.sizeDirty = true                                      // 10029fb4..10029fb8
    }

    /// `FUN_10026b10`: solo start (`entry_soloStartX/Y`) when `+0xcd == 1`, else the multi start; int →
    /// float (`fsubs` of the 2^52+2^31 bias, single); velocity (0, 0); crosshair adjust 0; overload cleared.
    mutating func placeAtStart() {
        if playerCount == 1 {
            object.x = Float(definition.entrySoloStartX)
            object.y = Float(definition.entrySoloStartY)
        } else {
            object.x = Float(definition.entryMultiStartX)
            object.y = Float(definition.entryMultiStartY)
        }
        object.vx = 0; object.vy = 0
        crosshairAdjust = 0
        clearOverload()
    }

    /// Appear fade = flli 163 Player_Appears_Initial / 164 Required / 165 Delta.
    mutating func setAppearFade() {
        object.visibility = assets.floats[163]
        object.visibilityTarget = assets.floats[164]
        object.visibilityStep = assets.floats[165]
    }

    /// `FUN_10012940` on the ship.
    mutating func refreshSize() {
        let a = assets
        object.refreshSize { Self.frameSize(a, $0, $1, $2) }
    }

    /// `FUN_10019ca0(face, frame, scale)` as far as Phase 1 needs it: the decoded frame's size at scale 1.0
    /// (the scaled rule `trunc(w·s)` is sprite-geometry-draw §3.3). A group that fails to decode, or a frame
    /// out of range, gives 0 × 0. Passed as a non-escaping closure (no per-tick closure allocation).
    static func frameSize(_ assets: DeimosAssets, _ face: FourCC, _ frame: Int32, _ scale: Float) -> (Int32, Int32) {
        guard let g = try? assets.spriteGroup(face), g.frames.indices.contains(Int(frame)) else { return (0, 0) }
        let f = g.frames[Int(frame)]
        if scale == 1 { return (Int32(f.width), Int32(f.height)) }
        return (Int32(Float(f.width) * scale), Int32(Float(f.height) * scale))
    }
}

public enum PlayerError: Error, Equatable, Sendable {
    case missingDefinition(type: String, id: String)
    /// `setup` index outside the PermObjectID list (the original indexes it unchecked).
    case invalidIndex(Int)
}
