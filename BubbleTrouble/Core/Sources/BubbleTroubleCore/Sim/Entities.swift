// Entity records of the simulation, one stored property per field of the original's slot layout that any code
// path reads or writes (plan §Task 4.1: every field Tasks 5a–11 need is declared HERE — Swift extensions cannot add
// stored properties). Offsets are the original's; names are the seat's. Widths mirror the original (`char` → Int8,
// `short` → Int16, frame stamps → UInt16, flag bytes → Bool). Licence/anti-crack copies the replica does not model
// (license name/copies/code words, magic constants) are omitted — they consume no RNG in the modelled licence state.
//
// Pool resets in the original clear only the slot's first byte (`_ResetBlocks`, `_InitEnemies`, `_Balloons_Init`);
// the replica's resets do the same (only `state`), so stale fields survive exactly as they do in the original.

/// A maze cell reference (col 0…15, row 0…10), `char` like the original's jewel/target bytes.
public struct CellRef: Equatable, Hashable, Sendable {
    public var col: Int8
    public var row: Int8

    public init(col: Int8, row: Int8) {
        self.col = col
        self.row = row
    }
}

/// Why a demo (or the replica) stops at the top of the next loop iteration (plan Invariant 14).
public enum StopReason: Hashable, Sendable {
    case countExhausted, heroDeathAnimationDone, levelCompleted, gameOverNoLives
    /// The original would quit here (NR-7 / C11 `_LocationErrorInt`, `_LoadLevel`'s `_LocationError(0x7de,1)`,
    /// `_ResetHeroPosition`'s "can't find good starting loc").
    case originalWouldAbort(String)
}

/// The hero record (`hero`, hero-and-input.md §0; `_InitHero @ 000217b3`, `_ResetHeroPosition @ 0002165f`,
/// `_ProcessHero @ 00022de0`).
public struct Hero: Equatable, Sendable {
    /// +0x02: 1 appearing, 2 playing, 3 caught ("ouch"), 4 dying.
    public var state: Int16 = 0
    /// +0x04: frame the state started.
    public var stateStart: UInt16 = 0
    /// +0x0c: last hero-bubble launch frame (`_Bubbles` reads and writes it).
    public var lastBubbleFrame: UInt16 = 0
    /// +0x14: top, left, bottom, right.
    public var rect = QDRect(top: 0, left: 0, bottom: 0, right: 0)
    /// +0x1c: previous rect (copied from `rect` by `_DrawHeroToComp`).
    public var prevRect = QDRect(top: 0, left: 0, bottom: 0, right: 0)
    /// +0x24: licence-valid flag (1 after `_ResetHeroLives`; recomputed while dying).
    public var licenceValid = false
    /// +0x26: facing / movement direction 1…4 (3 = left after `_ResetHeroPosition`).
    public var facing: Direction = .left
    /// +0x28: column.
    public var col: Int8 = 0
    /// +0x34: row.
    public var row: Int8 = 0
    /// +0x35: aligned (both offsets 0).
    public var aligned = false
    /// +0x36: x offset inside the move, −40…40.
    public var xOffset: Int16 = 0
    /// +0x38: y offset inside the move, −40…40.
    public var yOffset: Int16 = 0
    /// +0x3a: `RT3_IsRegistered()` copy (the turn `(0,1)` draw result is used only when this is 0).
    public var registered = false
    /// +0x3c: sprite set (1 idle, 2 up, 3 down, 4 left, 5 right, 6 push, 7 death).
    public var spriteSet: Int16 = 0
    /// +0x3e: sprite frame (also the death-animation step in state 4).
    public var spriteFrame: Int16 = 0
    /// +0x40: push/pop animation active (input frozen).
    public var frozen = false
    /// +0x42: push/pop freeze counter (also the death-animation tick in state 4).
    public var freezeCounter: Int16 = 0
    /// +0x46: push/pop freeze duration (2 push, 5 pop).
    public var freezeDuration: Int16 = 0
    /// +0x48: death-animation counter.
    public var deathCounter: Int16 = 0
    /// +0x4a: visible (cleared by `_HeroCaught(2)`; gates the state-4 death bubbles).
    public var visible = false
    /// +0x4b: death bubbles emitted.
    public var deathBubblesEmitted = false
    /// +0x4c: trapped in a balloon.
    public var trapped = false
    /// +0x4e: trap start frame.
    public var trapStart: UInt16 = 0
    /// +0x50: invisibility bonus active.
    public var invisible = false
    /// +0x51: draw-transparent toggle (invisibility blink).
    public var drawTransparent = false
    /// +0x52: invisibility start frame.
    public var invisibleStart: UInt16 = 0
    /// +0x5c: invisibility blink counter (toggle every 3 calls).
    public var blinkCounter: Int16 = 0
    /// +0x5e: invisibility blink toggle.
    public var blinkToggle = false
    /// +0x5f: speed-up active — never enabled in the shipped build.
    public var speedUp = false
    /// +0x60: speed-up start frame.
    public var speedUpStart: UInt16 = 0
    /// +0x62: speed-up blink counter.
    public var speedUpBlinkCounter: Int16 = 0
    /// +0x64: speed-up blink toggle.
    public var speedUpBlinkToggle = false
    /// +0x66: speed, px/frame (5).
    public var speed: Int16 = 0

    public init() {}
}

/// One enemy slot (`enemy`, 30 × 0x5c; enemies-ai.md §0; `_CheckNewEnemies @ 000124fa` + folded `_NewEnemy`).
public struct Enemy: Equatable, Sendable {
    /// +0x00: 0 free, 1 active, 2 egg (pre-flash), 3 egg (flashing), 4 (tested, never set), 5 frozen, 6 in a balloon.
    public var state: UInt8 = 0
    /// +0x02: state-start frame.
    public var stateStart: UInt16 = 0
    /// +0x04: read by `_Balloons_CaptureAllEnemies @ 000240dd` into the new balloon's `+0x22`; no writer found in the
    /// decompile (zero in a fresh process).
    public var unknown04: UInt8 = 0
    /// +0x10: type 1 piranha, 2 eel, 3 shark, 4 starfish.
    public var type: Int8 = 0
    /// +0x12: top, left, bottom, right.
    public var rect = QDRect(top: 0, left: 0, bottom: 0, right: 0)
    /// +0x1a: previous rect.
    public var prevRect = QDRect(top: 0, left: 0, bottom: 0, right: 0)
    /// +0x22: licence-valid flag (1 in the modelled licence state — Research note 6).
    public var licenceValid = true
    /// +0x23: direction 1…4; `nil` = 0 (none, cleared while deciding).
    public var direction: Direction? = nil
    /// +0x24: column.
    public var col: Int8 = 0
    /// +0x30: row.
    public var row: Int8 = 0
    /// +0x31: aligned (both coordinates multiples of 40).
    public var aligned = false
    /// +0x32: x remainder mod 40.
    public var xOffset: Int8 = 0
    /// +0x38: y remainder mod 40.
    public var yOffset: Int8 = 0
    /// +0x3a: sprite set = type id (0x1b piranha, 0x1c eel, 0x1d shark, 0x1e starfish; 0x20 in a balloon).
    public var spriteSet: Int16 = 0
    /// +0x3c: "tier", 4 for real enemies.
    public var tier: Int16 = 0
    /// +0x3e: anti-crack marker (0x14 at spawn, 0x17 at hatch).
    public var marker: Int16 = 0
    /// +0x40: animation frame.
    public var animFrame: Int16 = 0
    /// +0x42: written 1 by `_NewEnemy`; no reader found.
    public var unknown42: UInt8 = 0
    /// +0x43: balloon index holding it (−1 none).
    public var balloonIndex: Int8 = -1
    /// +0x44: post-hatch delay counter (the flag clears when it exceeds 15).
    public var postHatchCounter: Int16 = 0
    /// +0x46: drawn.
    public var drawn = false
    /// +0x47: dead (slot freed in the draw pass).
    public var dead = false
    /// +0x48: "stuck" counter (random walk).
    public var stuck: Int16 = 0
    /// +0x4a: paused — does not move this frame.
    public var paused = false
    /// +0x4b: post-hatch delay flag (no AI while set).
    public var postHatchDelay = false
    /// +0x4c: animation tick.
    public var animTick: Int8 = 0
    /// +0x4e: speed counter (the shark's step counter; the piranha keeps its speed here).
    public var speedCounter: Int16 = 0
    /// +0x50: speed, px/frame.
    public var speed: Int16 = 0
    /// +0x52: action wait counter.
    public var actionWait: Int16 = 0
    /// +0x58: pending action (1 push, 2 pop, 3 balloon, 4 wait; 0 none).
    public var pendingAction: Int16 = 0
    /// +0x5a: frame of the last pop/push/balloon (the spawn frame initially).
    public var lastPop: UInt16 = 0

    public init() {}
}

/// One block slot (`block`, 35 × 0x34; bubbles-items-scoring.md §1; `_NewBlock @ 0001b94b`, `_MoveBlock @ 0001cccb`,
/// `_ProcessBlocks @ 0001d2b8`).
public struct Block: Equatable, Sendable {
    /// +0x00: 0 free, 1 active, 2 popping, 3 static (lit dynamite, egg), 4 egg about to pop.
    public var state: UInt8 = 0
    /// +0x02: start frame.
    public var startFrame: UInt16 = 0
    /// +0x04: type (cell code: 10/15/16/20/30/40/52/60).
    public var type: UInt8 = 0
    /// +0x06: rect.
    public var rect = QDRect(top: 0, left: 0, bottom: 0, right: 0)
    /// +0x0e: previous rect.
    public var prevRect = QDRect(top: 0, left: 0, bottom: 0, right: 0)
    /// +0x16: direction (`nil` = 0, static blocks).
    public var direction: Direction? = nil
    /// +0x17: column.
    public var col: Int8 = 0
    /// +0x18: row.
    public var row: Int8 = 0
    /// +0x19: aligned.
    public var aligned = false
    /// +0x1a: moves (1) or static (0).
    public var moving = false
    /// +0x1b: x offset (±40).
    public var xOffset: Int8 = 0
    /// +0x1c: y offset (±40).
    public var yOffset: Int8 = 0
    /// +0x1d: enemies squished by this block so far (the chain count n).
    public var squishCount: Int8 = 0
    /// +0x1e: sprite set.
    public var spriteSet: Int16 = 0
    /// +0x20: sprite frame (pop step, fuse step, squash step, egg type).
    public var frame: Int16 = 0
    /// +0x22: jewel/cluster column (types 20/30 only).
    public var jewelCol: Int8 = 0
    /// +0x23: jewel/cluster row (types 20/30 only).
    public var jewelRow: Int8 = 0
    /// +0x24: egg sprite toggle (egg ↔ bubble every 9 frames while state 3).
    public var eggToggle = false
    /// +0x26: animation counter (cluster, fuse, egg toggle).
    public var animCounter: Int16 = 0
    /// +0x28: retire flag (slot freed in the draw pass).
    public var retired = false
    /// +0x29: enemy index (egg blocks).
    public var enemy: Int8 = 0
    /// +0x2a: egg pop delay (15).
    public var eggPopDelay: Int16 = 0
    /// +0x2c: bouncing now (blue/purple squash).
    public var bouncing = false
    /// +0x2e: bounces done.
    public var bounces: Int16 = 0
    /// +0x30: bounce (squash) step.
    public var bounceStep: Int16 = 0

    public init() {}
}

/// One balloon slot (`gBalloons`, 30 × 0x2c at 0x379e0; `_Balloons_New @ 000237f9`, `_Balloons_Process @ 00024394`,
/// `_Balloons_CaptureHero @ 00023cbb`, `_Balloons_CaptureAllEnemies @ 000240dd`).
public struct Balloon: Equatable, Sendable {
    /// +0x00: 0 free, 1 flying, 2 holding, 3 popping.
    public var state: UInt8 = 0
    /// +0x02: start frame.
    public var startFrame: UInt16 = 0
    /// +0x04: animation timer (frame of the last step).
    public var animTimer: UInt16 = 0
    /// +0x06: animation period (`GetRandomFast(4,7)`).
    public var animPeriod: Int16 = 0
    /// +0x08: rect.
    public var rect = QDRect(top: 0, left: 0, bottom: 0, right: 0)
    /// +0x10: previous rect.
    public var prevRect = QDRect(top: 0, left: 0, bottom: 0, right: 0)
    /// +0x18: direction (the shark's, or the hero's facing for capture-all); `nil` = 0.
    public var direction: Direction? = nil
    /// +0x1a: sprite set (0x31 flying, 0x32 holding).
    public var spriteSet: Int16 = 0
    /// +0x1c: sprite frame.
    public var frame: Int16 = 0
    /// +0x1e: counter (box growth / flash / pop steps).
    public var counter: Int16 = 0
    /// +0x20: visible (cleared once the rect leaves 0…640 × 0…440; not restored).
    public var visible = false
    /// +0x21: dead (slot freed in the draw pass).
    public var dead = false
    /// +0x22: capture kind (0x46 hero, 0x50 enemy; capture-all copies the enemy's `+0x04`).
    public var captureKind: UInt8 = 0
    /// +0x23: holder (enemy slot; −1 = the hero).
    public var holder: Int8 = 0
    /// +0x24: collision box (17×17 in front while flying; grows once — C4).
    public var box = QDRect(top: 0, left: 0, bottom: 0, right: 0)

    public init() {}
}

/// One bonus-bubble slot (`bonus`, 2 × 0x28 at 0x376a0; `_Bonus_Init @ 00019734`, `_Bonus_Process @ 0001a92b`).
public struct BonusBubble: Equatable, Sendable {
    /// +0x00: armed this level.
    public var armed = false
    /// +0x01: dead (slot freed in the draw pass).
    public var dead = false
    /// +0x02: popped (floating up after collection).
    public var popped = false
    /// +0x03: visible.
    public var visible = false
    /// +0x04: type 1…14 (3 → 14, 5…8 → 9…13 at init).
    public var type: Int16 = 0
    /// +0x06: rect (starts (440, left, 480, left + 40)).
    public var rect = QDRect(top: 0, left: 0, bottom: 0, right: 0)
    /// +0x0e: previous rect.
    public var prevRect = QDRect(top: 0, left: 0, bottom: 0, right: 0)
    /// +0x16: index into `_gBonus_SnakingLUT` (19 entries).
    public var snakeIndex: Int16 = 0
    /// +0x18: rise speed (2).
    public var riseSpeed: Int16 = 0
    /// +0x1a: icon sprite set (0x1a).
    public var iconSet: Int16 = 0
    /// +0x1c: icon frame (= type; type 14: 0xe + value index).
    public var iconFrame: Int16 = 0
    /// +0x1e: shell animation timer.
    public var animTimer: UInt16 = 0
    /// +0x20: shell frame (1…3).
    public var shellFrame: Int16 = 0
    /// +0x22: time value for type 14 (500…5000); −1 otherwise.
    public var timeValue: Int16 = 0
    /// +0x24: launch frame (set for both slots, armed or not).
    public var launchFrame: UInt16 = 0
    /// +0x26: popped frame (= frame at init; the float-up clock after collection).
    public var poppedFrame: UInt16 = 0

    public init() {}
}

/// One "hurt block" redraw entry (`gHurtBlock`, 50 × 0xc at 0x37760; `_NewHurtBlock @ 0001b6d0`,
/// `_DrawHurtBlocksToComp @ 0001b8b1` which draws and clears every active entry — draw only, no RNG).
public struct HurtBlock: Equatable, Sendable {
    public static let capacity = 50
    /// +0x00: active.
    public var active = false
    /// +0x02: top (row · 40).
    public var top: Int16 = 0
    /// +0x04: left (col · 40).
    public var left: Int16 = 0
    /// +0x06: column.
    public var col: Int8 = 0
    /// +0x07: row.
    public var row: Int8 = 0
    /// +0x08: sprite set.
    public var spriteSet: Int16 = 0
    /// +0x0a: sprite frame (LEVL w3 for bubbles, w4 for jewels/clusters, 1 for dynamite).
    public var frame: Int16 = 0

    public init() {}
}
