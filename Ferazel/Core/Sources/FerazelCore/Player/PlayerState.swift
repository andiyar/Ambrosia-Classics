import Foundation

/// One sound call the player code made this frame (plan Invariant 4): the snd id (the `_DAT_100a0xxx` slot's sound,
/// pickups-boxes-2 §1 table — 414 = `a03f8`, 427 = `a03cc`, 497 = `a02e8`, 509 = `a02b4`, 604 = `a027c`), the
/// priority and volume as passed, the 3D position word (`+0xe`/`+0x10` of the sprite named) and the rate a
/// `.STPlay3DSoundRand` drew **at its call site** (`FastRand.soundRate()`, even with sound off; raw
/// `10047d60..10047d90`). S1 turns these into `SoundCue`s (volume/stereo arithmetic only — no draws).
public struct PlayerCue: Equatable, Sendable {
    /// Which Sound Tool entry the original called.
    public enum Call: Equatable, Sendable {
        /// `.STPlayRegSound(snd, prio, vol)`.
        case reg
        /// `.STPlay3DSoundRand(snd, prio, vol, pos)` — `rate` holds the drawn `FastRand(10000) + 0xec77`.
        case threeDRand
        /// `.STPlay3DSound(snd, prio, vol, pos) @ 10047ac0` — no draw (its callees are `10047738` and the play list
        /// `10091208`). P2: the crunch sounds 423 / 424 (`.CrunchTile`, the crumble overlay's Handle).
        case threeD
        /// `if (FUN_100916dc(snd)) FUN_10091504(snd)`: stop the sound if it is playing.
        case stopIfPlaying
        /// `FUN_10091504(snd)` with no playing test (P4: row 17's healing sound 803 when nothing heals, l. 44879–44883).
        case stop
        /// `.STPlay3DSoundPitched(snd, prio, vol, pos, rate) @ 10047b8c` — no draw; `rate` holds the caller's pitch
        /// (W1: the crumbling platform's 461 with p4 ≠ 0, `p4·0xf3b + 0x10000`).
        case threeDPitched
        /// `.STPlayRegSoundPitched(snd, prio, vol, rate)` — no draw inside; `rate` holds the caller's pitch, which
        /// `.HurtPlayer` draws at its call site (W2a: 508 at `FastRand(10000) + 65000` / `+ 50000`, l. 48053–48067).
        case regPitched
    }

    public var call: Call
    public var snd: Int16
    public var priority: Int16
    public var volume: Int16
    /// The 3D position (`*(int *)(sprite + 0xe)`: y = `+0xe`, x = `+0x10`); nil for the non-3D calls.
    public var position: SpriteSlot.Point?
    /// The rate drawn at the call site (`.threeDRand`), or the caller's pitch (`.threeDPitched`).
    public var rate: Int32?
    /// `if (!FUN_100916dc(snd)) play(…)`: the call is made only while the sound is not playing (`.CrunchTile`'s 423,
    /// raw `10044a50..10044a74`; S1 maps it to `SoundCue.onlyIfIdle`).
    public var onlyIfIdle: Bool

    public init(call: Call, snd: Int16, priority: Int16 = 0, volume: Int16 = 0, position: SpriteSlot.Point? = nil,
                rate: Int32? = nil, onlyIfIdle: Bool = false) {
        self.call = call
        self.snd = snd
        self.priority = priority
        self.volume = volume
        self.position = position
        self.rate = rate
        self.onlyIfIdle = onlyIfIdle
    }
}

/// The player's globals (plan S2, P1a; player-states §2). The original keeps almost all player state in globals, not
/// in the sprite record; each is named here by the TOC slot the decompiler prints (`_DAT_100a0758` = the slot at
/// 0x100a0758 holding a pointer to the global) so a reviewer can grep the address. Defaults are `.ClearPlayerVars
/// @ 1004aa48` (decompile l. 42499–42778): every global 0 except climb phase `_DAT_100a5f54` 1, bubble timer
/// `_DAT_100a5f56` 0x28, `DAT_100a5f58` 1, breath phase `uRam100a5f5e` 3, `uRam100a5fd4` 1, potion item
/// `_DAT_100a5fd6` −1, melee item `_DAT_100a5fd8` −1, and the max speeds `_DAT_100a600a/600c/600e/6010` =
/// 0x76c/0xc80/0x76c/0xc80. `.SetupPlayerSprite` then sets the facing (`Player.spawn`).
///
/// Only the globals the P1a rows read or write are kept; later tasks add theirs under their addresses
/// (P2 cling/landing latches, P3 faces and breathing, P4 liquids, P5 the camera).
public struct PlayerState: Equatable, Sendable {
    // MARK: identity and position copies

    /// `PTR_DAT_100a0558`: the sprite ridden this frame (`s+0xdc` copied at Handle entry; nil = 0).
    public var ridden: Int?
    /// `PTR_DAT_100a0554`: last frame's ridden sprite (the 0x6a4 ride-on sound fires on a change from 0).
    public var lastRidden: Int?
    /// `PTR_DAT_100a05a4`: riding a magic carpet (ridden type 0x438/0x439).
    public var carpet = false
    /// `*_DAT_1009fd34` (u8): the camera's one-shot snap veto (P5), read and cleared by `.FindUpperLeftCorner`'s snap
    /// test. Two writers set it: riding a sprite (row 3, decompile l. 44542, `Player.riding`) and the level side push
    /// while grounded or riding (row 37, l. 46363, `Player.sidePush`).
    public var cameraSnapVeto = false
    /// `*_DAT_1009fe68` / `*_DAT_1009fe64`: the player's whole-px x / y (`.SetupPlayerSprite`; rewritten by
    /// `.ApplySpeedAndSeparateFromTiles` and the Handle's position row).
    public var pixelX: Int16 = 0
    public var pixelY: Int16 = 0
    /// `*_DAT_1009fd44` / `*_DAT_1009fd40`: the camera focus `.FindUpperLeftCorner` reads. `.SetupPlayerSprite` sets
    /// it to the sprite origin (`+8` / `+6`); `.PlayerScroll` (P5) moves it every Handle.
    public var focusX: Int16 = 0
    public var focusY: Int16 = 0
    /// `*_DAT_1009fd94` / `*_DAT_1009fd90`: the hot-rect centre x / y (`.GameLoop`: origin + 0x32 / + 0x3b; the
    /// Handle's position row: `+0x10` / `+0xe`).
    public var centreX: Int16 = 0
    public var centreY: Int16 = 0
    /// `*_DAT_100a0740`: the centre y while grounded / riding / clinging / `_DAT_100a05a0` (the camera's ground y, P5).
    public var groundCentreY: Int16 = 0
    /// `*_DAT_1009fd3c` / `PTR_DAT_100a04c8`: vx / vy copied at the end of the Handle.
    public var lastVX: Int32 = 0
    public var lastVY: Int32 = 0

    // MARK: camera (P5; `.PlayerScroll @ 1004c528`, the look-ahead row l. 46393–46422)

    /// `*_DAT_100a0680` (i32, 24.8 px): the horizontal look-ahead L (0 at `.ClearPlayerVars` / `.SetupPlayerSprite`).
    public var lookAhead: Int32 = 0
    /// `uRam100a5114` (u8): the camera's 16-px snap armed — set by every look-ahead row, cleared while L decays
    /// against the facing; read by `.FindUpperLeftCorner`. No `.ClearPlayerVars` write: true before the first Handle
    /// (as `Camera`'s default).
    public var snapArmed = true
    /// `DAT_100a5f58` (u8): the focus-y latch (1 at `.ClearPlayerVars`): set when an ease reaches its target, cleared
    /// by the jump freeze; while set the focus y follows exactly.
    public var scrollLatch = true
    /// `*_DAT_100a06dc` (u8): the focus y is easing (0 at `.ClearPlayerVars`).
    public var scrollEasing = false
    /// `PTR_DAT_1009fe78` = (v, h): the scroll point `.PlayerScroll` builds its band from. `Camera` owns it; the
    /// session copies it here after each `.FindUpperLeftCorner`.
    public var scrollH = 0
    public var scrollV = 0

    // MARK: facing and idle

    /// `_DAT_100a5f5a`: facing, 1 left / 2 right. `_DAT_100a5f5c`: last frame's (copied at Handle entry).
    public var facing: Int16 = 0
    public var lastFacing: Int16 = 0
    /// `PTR_DAT_100a06c4`: draw mirrored during the turn (cleared at Handle entry; P3 sets it).
    public var turnMirror = false
    /// `_DAT_100a068c` / `_DAT_100a0688`: idle frames / fidgets played.
    public var idle: Int16 = 0
    public var fidgets: Int16 = 0

    // MARK: speeds

    /// `_DAT_100a600a` / `600c`: ground walk / run max; `600e` / `6010`: air walk / run max.
    public var maxWalk: Int16 = 0x76c
    public var maxRun: Int16 = 0xc80
    public var airWalk: Int16 = 0x76c
    public var airRun: Int16 = 0xc80
    /// `PTR_DAT_100a0620`: Double Speed active. `PTR_DAT_100a0638`: High Jump active. `PTR_DAT_100a062c`: Feather
    /// Fall active. // later: Phase 4 (power-ups — their `.TickTock` timers have no Phase-2 writer; stay false).
    public var doubleSpeed = false
    public var highJump = false
    public var featherFall = false
    /// `_DAT_100a0694`: the ice deceleration (0 off ice; `(0x100 − hdr 0x2710)·800 >> 8`, at least 1, on material 3).
    public var ice: Int16 = 0
    /// `_DAT_100a072c`: the run flag. `_DAT_100a0730` / `_DAT_100a0734`: LEFT / RIGHT walking input this frame.
    public var runFlag = false
    public var walkLeft = false
    public var walkRight = false

    // MARK: states

    /// `_DAT_100a069c`: dying counter (0 alive; row 41's death trigger sets 1, P4).
    public var dying: Int16 = 0
    /// `_DAT_100a05e0`: on the glider. // later: Phase 4 (spells).
    public var glider = false
    /// `_DAT_100a05d8`: glider pitch (−5…5); `_DAT_100a05d4`: glider exit counter. // later: Phase 4.
    public var gliderPitch: Int16 = 0
    public var gliderExit: Int16 = 0
    /// `PTR_DAT_100a0668` / `_DAT_100a0664`: spin flag / spin frame (0…7).
    public var spin = false
    public var spinFrame: Int16 = 0
    /// `_DAT_100a0714`: swim counter (0 not swimming, 1 idle, 3… stroke).
    public var swim: Int16 = 0
    /// `_DAT_100a05fc`: near the liquid surface (`0 < +0x120 ≤ 0x15`, liquid ≠ 5).
    public var nearSurface = false
    /// `_DAT_100a0588` / `_DAT_100a0584`: on a rope now / last frame (`.RopeCollide` sets it, W3).
    public var rope = false
    public var lastRope = false
    /// `_DAT_100a0580`: the rope the player is on (an `ActiveList` id; `.RopeCollide` writes it, W3).
    public var currentRope: Int?
    /// `_DAT_100a0758` / `PTR_DAT_100a0754`: climb (wall cling) this frame / last frame. // P2's tile callback sets it.
    public var climb: Int16 = 0
    public var lastClimb: Int16 = 0
    /// `PTR_DAT_100a074c`: the wall side (1 = wall on the left, 2 = right).
    public var wallSide: Int16 = 0
    /// `_DAT_100a06a0`: pull-up counter (0, 1…20). `_DAT_100a5f54`: climb animation phase (1…12).
    public var pullUp: Int16 = 0
    public var climbPhase: Int16 = 1
    /// `_DAT_100a0748`: hurt-stun counter (`.HurtPlayer` sets 1, W2a).
    public var stun: Int16 = 0
    /// `_DAT_100a071c`: crouch depth (0…4). `PTR_DAT_100a05e8` / `_DAT_100a05e4`: shield raise / extension.
    public var crouch: Int16 = 0
    public var shieldRaise: Int16 = 0
    public var shieldExtension: Int16 = 0
    /// `_DAT_100a0718`: the air animation counter (P3 updates it in the airborne state; 0 until then).
    public var airCounter: Int16 = 0
    /// `_DAT_100a05b8` / `_DAT_100a05b4`: launched tumble flag / tumble frame.
    public var launched = false
    public var tumbleFrame: Int16 = 0
    /// `_DAT_100a06f0`: door transit counter (input lock) — the passage arm of `.HitPlayerSprite` (W2b).
    public var doorTransit: Int16 = 0
    /// `PTR_DAT_100a0700`: teleporter charge. // later: Phase 3 (teleporters).
    public var teleporterCharge: Int16 = 0
    /// `_DAT_100a05b0`: potion drink counter; `_DAT_100a0570`: boss-grab counter; `_DAT_100a0578` / `_DAT_100a0574`:
    /// spirit-form timer / transition. // later: Phase 4–5 (no Phase-2 writer).
    public var potion: Int16 = 0
    public var bossGrab: Int16 = 0
    public var spiritTimer: Int32 = 0
    public var spiritTransition: Int16 = 0

    // MARK: jump

    /// `_DAT_100a0764`: the jump counter (6 grounded, 3 clinging, 0 airborne — the JUMP arm's else-refill).
    public var jumpCounter: Int16 = 0
    /// `_DAT_100a0678`: the jump base J (0; a ridden platform's `+0x194`; −0x898 with High Jump).
    public var jumpBase: Int32 = 0
    /// `PTR_DAT_100a04d8`: the post-jump guard (2 frames; P2 skips FG resolution while it is set).
    public var postJumpGuard: Int16 = 0
    /// `PTR_DAT_100a06b8`: the spin-refill cooldown (20). `_DAT_100a05f4`: the swim-stroke cooldown (12).
    public var spinCooldown: Int16 = 0
    public var strokeCooldown: Int16 = 0
    /// `_DAT_100a06a4`: exertion (+8 per jump / stroke here; +1 / +3 per walk / run frame in the L/R block, P1b;
    /// `.HandleBreathing` spends it, P3).
    public var exertion: Int16 = 0
    /// `_DAT_100a0738`: the ground kind at the pre-move pass (`s+0xce`, 3 while riding).
    public var groundLast: UInt8 = 0
    /// `_DAT_100a0660`: vy before the move (the landing impact, P2).
    public var impact: Int32 = 0
    /// `_DAT_100a0724` / `_DAT_100a0720`: the landed / bumped latches (cleared before the move; P2 sets them).
    public var landedLatch = false
    public var bumpedLatch = false
    /// `_DAT_100a05f8`: the row-33 animation counter whose arm precedes the rope / swim / cling arms (set by
    /// `.HitPlayerSprite`'s passage arm, l. 49599 / 49680 — W2b): the door walk-in (> 0) / walk-out (< 0) faces.
    public var animation05f8: Int16 = 0
    /// `PTR_DAT_100a0670`: the standing flag (the cling / stun arms clear it; P3 reads it).
    public var standing0670 = false
    /// `PTR_DAT_100a0648` / `PTR_DAT_100a063c`: the walk-on-liquid power-up and its liquid kind — `.HitPlayerTileSprite`
    /// turns a matching BG water cell into an FG kind-3 floor 16 px up. // later: Phase 4 (no Phase-2 writer).
    public var walkOnLiquid = false
    public var walkOnLiquidKind: Int16 = 0

    // MARK: casting and items (read by the climb and JUMP gates)

    /// `PTR_DAT_100a06e0`: no cast began in this `.HandleKeys` call (set 1 at its top).
    public var noCastBegan = false
    /// `_DAT_100a06d4` / `_DAT_100a06d0`: wand phase (0…7) / wand-held counter. // later: Phase 4 (spells).
    public var wandPhase: Int16 = 0
    public var wandHeld: Int16 = 0
    /// `_DAT_100a0760` / `_DAT_100a075c`: the USE debounces.
    public var useDebounce = false
    public var useItemHeld = false

    // MARK: per-frame counters (row 13)

    /// `PTR_DAT_100a06bc` (no reader) / `PTR_DAT_100a06c0` (`+0x116` copy).
    public var newHit: Int16 = 0
    public var lastInvulnerable: Int16 = 0
    /// `PTR_DAT_100a060c`: crunch-bounce cooldown. `PTR_DAT_100a05c4`, `PTR_DAT_100a05a8`, `PTR_DAT_1009fdbc`,
    /// `_DAT_1009fdb8`, `PTR_DAT_1009fda8`: countdowns. `_DAT_100a0684`: save-point hold (toward 0). `PTR_DAT_100a05f0`:
    /// no-cling timer. `_DAT_100a059c`: carpet-steering lock. `_DAT_100a073c`: the item-0x13 countdown.
    public var crunchCooldown: Int16 = 0
    public var countdown05c4: Int16 = 0
    public var countdown05a8: Int16 = 0
    public var countdownFDBC: Int16 = 0
    public var countdownFDB8: Int16 = 0
    public var countdownFDA8: Int16 = 0
    public var savePointHold: Int16 = 0
    public var noCling: Int16 = 0
    public var carpetLock: Int16 = 0
    public var countdown073c: Int16 = 0
    /// `PTR_DAT_100a0610` (decremented every frame, no floor) / `PTR_DAT_100a0614` (= `0610 ≥ 1`).
    public var countdown0610: Int16 = 0
    public var flag0614 = false
    /// `_DAT_100a06d8`, `PTR_DAT_100a06cc`: countdowns. `_DAT_100a067c`: see-saw touch (write-only).
    public var countdown06d8: Int16 = 0
    public var countdown06cc: Int16 = 0
    public var seeSawTouch = false
    /// `PTR_DAT_100a0704`: the end separation pass is running (the only pass that processes water, P2/P4).
    public var waterPass = false
    /// `_DAT_100a05a0`: cleared before the end pass.
    public var flag05a0 = false
    /// `PTR_DAT_100a055c`: the dying draw offset flag (cleared after the end pass).
    public var flag055c = false
    /// `_DAT_100a0744` / `PTR_DAT_100a0674`: the stillness counter / standing still.
    public var stillness: Int16 = 0
    public var standingStill = false
    /// `PTR_DAT_100a0590` / `_DAT_100a05bc`: the riding ramps (0…0x1b by 2, 0…8).
    public var rideRamp: Int16 = 0
    public var rideRamp2: Int16 = 0
    /// `PTR_DAT_100a05ec` (0…0x1f) / `_DAT_100a057c` (0…0x167, +2): the free-running counters at the Handle's end.
    public var counter05ec: Int16 = 0
    public var angle057c: Int16 = 0
    /// `PTR_DAT_100a04cc`: the "stood on a BG one-way top" timer.
    public var oneWayTimer: Int8 = 0

    // MARK: state selection, faces and breathing (P3; row 33 l. 45219–46196, `.HandleBreathing`, row 36)

    /// `PTR_DAT_100a06c8`: the turn countdown (4 → 0 over the five turn frames).
    public var turnCountdown: Int16 = 0
    /// `_DAT_100a0728`: walking last frame (the first walking frame sets the phase `+0x46` to 0xc).
    public var walking = false
    /// `PTR_DAT_100a04fc`: the chest frame (index into 1003) — `.HandleBreathing` writes it, the stand entry sets 3.
    public var chestFrame: Int16 = 0
    /// `_DAT_100a06b0` / `_DAT_100a06a8`: the breathing period counter / last frame's breath phase.
    public var breathPeriod: Int16 = 0
    public var lastBreathPhase: Int16 = 0
    /// `PTR_DAT_100a0710`: the footstep index into the 4-sound table `_DAT_100a025c` (410…413).
    public var footstep: Int16 = 0
    /// `_DAT_100a058c`: the rope walk counter (0…15; the rope state, `PlayerStates`; `.RopeCollide` reads it, W3).
    /// `_DAT_100a0768`: the last cast was V Blade (alternate cast faces). // later: Phase 4 (spells) — no Phase-2 writer.
    public var ropeWalk: Int16 = 0
    public var vBladeCast = false
    /// `_DAT_100a0698`: the melee / throw counter (`.HandleItemUse`). // later: Phase 4 (no Phase-2 writer).
    public var itemUse: Int16 = 0
    /// `PTR_DAT_100a0594`: the necklace revive counter. `PTR_DAT_100a0560`: died in liquid (the dying arm ends at
    /// 100, not 80; row 41's death trigger writes it, P4). // later: Phase 4 (revive).
    public var revive: Int16 = 0
    public var diedInLiquid = false
    /// `PTR_DAT_100a0538`: row 17's liquid-contact counter (0 out of the liquid, +1 per frame up to 2; acid and healing
    /// act from the third frame). `PTR_DAT_100a06f4`: the `.EmitBubble` cooldown (2 after a bubble). Both 0 after
    /// `.ClearPlayerVars`. P4.
    public var liquidCounter: Int16 = 0
    public var bubbleCooldown: Int16 = 0
    /// `DAT_100a5106`: the game-over flag the dying arm sets when it ends (`.GameLoop` leaves its loop; W4 restarts).
    public var gameOver = false
    /// `PTR_DAT_100a070c` / `PTR_DAT_100a0708`: touching a teleporter this frame / the teleporter fires.
    /// // later: Phase 3 (teleporters) — no Phase-2 writer of 070c.
    public var teleporterTouch = false
    public var teleporterFire = false
    /// `PTR_DAT_100a0644`, `PTR_DAT_100a0634`, `PTR_DAT_100a0628`, `PTR_DAT_100a061c`: the power-up tint flags paired
    /// with walk-on-liquid / High Jump / Feather Fall / Double Speed in row 36. // later: Phase 4 (`.TickTock`).
    public var tint0644 = false
    public var tint0634 = false
    public var tint0628 = false
    public var tint061c = false
    /// `_DAT_100a065c`: the held-item sprite (`.SetupPlayerSprite`'s `MTNewSprite(100, 0, 0, 0x14, 0x1ff, …)`).
    public var heldItem: Int?
    /// `PTR_DAT_100a051c`: the five trail records `{sprite, 0, −1, −1, 0}` (`.SetupPlayerSprite`'s loop); the
    /// sprites are type 1, layer 9 (`.SetupTrailSprite`). `.DoubleSpeedTrail` // later: Phase 4.
    public var trail: [Int?] = []

    // MARK: ClearPlayerVars' non-zero globals with no P1a reader (kept for the later rows)

    /// `uRam100a5f5e`: breath phase (3). `_DAT_100a5f56`: bubble timer (0x28). `DAT_100a5f58` (1) is `scrollLatch`.
    /// `uRam100a5fd4` (1).
    public var breathPhase: Int16 = 3
    public var bubbleTimer: Int16 = 0x28
    public var flag5fd4: Int16 = 1
    /// `_DAT_100a5fd6` / `_DAT_100a5fd8`: potion / melee item id (−1).
    public var potionItem: Int16 = -1
    public var meleeItem: Int16 = -1

    // MARK: crunch tiles (P2; `.CrunchTile`, `.MakeCrunchSprite`, `.DestroyCrunchTile`)

    /// The 40-slot crumble-overlay table at `0x100a53d8` (`.ClearCrunchSprites` / `.FindCrunchSprite` /
    /// `.MakeCrunchSprite`): an overlay sprite id per slot (nil = 0). A global, kept here with the player's.
    public var crunchSprites = [Int?](repeating: nil, count: 0x28)
    /// `*_DAT_100a00f4`: the water-effects tile cache is valid (`.FillCachedTileArray` sets it; `.DestroyCrunchTile`
    /// clears it; `.WrapDrawWaterEffects` refills when clear — E1b).
    public var tileCacheValid = false

    /// The coins `.HurtPlayer` knocked out of the player (W2a; l. 48078–48103): the count taken from `G+0x10`, summed
    /// over the level. The original makes a Bonus 0x516 per coin (`MTNewSprite(0x516, …, 0x14, −1, .SetupBonusSprite)`);
    /// // later: Phase 4 (Bonus pickups) spawns them — until then they are only counted, and the Bonus Setup's own
    /// `FastRand` draws between each coin's draws are not made (the stream diverges after a coin-losing hit).
    public var coinsLost: Int16 = 0

    /// The sound calls made since the last `drainFrameOutputs()`, in call order — by the player's Handle and tile
    /// callback and by the Effect Handles (the crumble overlay's 424).
    public var cues: [PlayerCue] = []
    /// The map changes made since the last `drainFrameOutputs()`, in call order (`DrawOp.setTile`, one per
    /// `.SetFGTile` / `.SetFGCrunchDirTile` write — from the player's tile callback or the overlay's Handle).
    public var tileOps: [DrawOp] = []

    /// Hands over and clears `cues` and `tileOps`. The frame driver calls it once per frame after the whole
    /// `.MTHandleSprites` pass (plan P2 review ruling 1: the outputs are filled by several Handles, so no single Handle
    /// may clear them; the session wiring is P3's — "⚑ P2 carry → P3").
    public mutating func drainFrameOutputs() -> (cues: [PlayerCue], tileOps: [DrawOp]) {
        defer {
            cues = []
            tileOps = []
        }
        return (cues, tileOps)
    }

    /// `.ClearPlayerVars`' state.
    public init() {}
}
