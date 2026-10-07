import Foundation
import HectorResources

/// The fields of the game struct G (`*(r2−0x7360)` = `PTR_DAT_100defd0`, 0x180 bytes, zeroed once) that are
/// flags, counters and times (scoring-bonuses.md §1.2, level-scroll-objects.md §8, loose-ends-session.md
/// §4, messages-notices-console.md §5). ★ LOCKED (plan S2). The players (+0x00/+0x04) are
/// `GameState.players`; the accuracy tally (+0x48…+0x168) is `TallyState`. Not kept: +0x0e (stopped by the
/// unregistered-level limit — this is the registered game) and +0x24 (the attract-mode demo counter —
/// Phase 4's front end). Defaults are the zeroed struct, except +0x28.
public struct GameFlags: Equatable, Sendable {
    /// +0x08: the session is running (the `FUN_100051a0` loop condition).
    public var running = false
    /// +0x09: level complete (tallies done) → `FUN_10007170` advances.
    public var levelComplete = false
    /// +0x0a: no player alive (game over in progress).
    public var noPlayerAlive = false
    /// +0x0b: this level ended at 100 % ground accuracy (`10007388`).
    public var perfectThisLevel = false
    /// +0x0c: accuracy reward armed for this level (copied from +0x0b at level start).
    public var rewardArmed = false
    /// +0x0d: all levels completed (finale).
    public var allLevels = false
    /// +0x0f: byte pref 5 (interlacing) was suspended at level start; restored at appear (`10005990..100059b0`).
    public var restoreInterlace = false
    /// +0x10: levels started this session.
    public var levelsStarted: Int32 = 0
    /// +0x14: current sector (1–12).
    public var sector: Int32 = 0
    /// +0x18: current level tag (`none` = no more levels).
    public var level: FourCC = .none
    /// +0x1c: game time — logic ticks since level start (reset to 0 by every level start).
    public var gameTime: Int32 = 0
    /// +0x20: a film is playing.
    public var filmPlaying = false
    /// +0x21: players in this game (1 or 2) — stored by the session set-up (`10005548`, `10005770`), read for
    /// each player's setup (`10005868 lbz r5,0x21(r29)` → `FUN_10026410`, player +0xcd).
    public var numPlayers: UInt8 = 0
    /// +0x28: draw entity shadows — read by `FUN_10006220` (`10006220..1000623c`: 1 before the console
    /// exists, else G+0x28), the gate of every shadow pass; the console setup stores 1 and only the
    /// unregistered SHADOWS command flips it (sprite-geometry-draw.md §5.1).
    public var drawShadows = true
    /// +0x29 / +0x2c: the level end was handled / its game time.
    public var levelEndHandled = false
    public var levelEndTime: Int32 = 0
    /// +0x30: frames presented — the begin-frame result stored every pass (`10005910 stw r3,0x30(r29)`;
    /// timing-frame.md §2.2).
    public var framesPresented: Int32 = 0
    /// +0x34: game time of the first no-player tick (`10006d60`/`10006d78`); running clears at > start + 110.
    public var gameOverStart: Int32 = 0
    /// +0x38: the game has appeared (fade-in done).
    public var appeared = false
    /// +0x39: level ending (passed to the player update as its last argument).
    public var levelEnding = false
    /// +0x3c / +0x40: ground-accuracy units created / destroyed this level.
    public var groundCreated: Int32 = 0
    public var groundDestroyed: Int32 = 0
    /// +0x44: levels finished at exactly 100 % this game.
    public var perfectLevels: Int32 = 0
    /// +0x16c / +0x170 / +0x174 / +0x178 / +0x17c: console cheat uses — `life`, `funds`, `score`, `shields`,
    /// `mult` (zeroed at game start by `FUN_10007130`).
    public var cheatLife: Int32 = 0
    public var cheatFunds: Int32 = 0
    public var cheatScore: Int32 = 0
    public var cheatShields: Int32 = 0
    public var cheatMult: Int32 = 0
    /// "P1 active": the `FUN_100051a0` stack byte (`r1+0x3b`) passed by pointer to `FUN_10006b50`, set at
    /// `10006bc4` on the first tick P1 is in life state 4 (`10006bb0 FUN_10026c60(P1, 4)`), before the player
    /// loop, and never reset within the session; passed as `FUN_10028170`'s 2nd argument (the lives-decrement
    /// gate — loose-ends-session.md §4, HIGH). Cleared at session set-up (`10005618 stb r0,0x3b(r1)`).
    public var p1Active = false
    /// "Game-over notice spawned": the `FUN_100051a0` stack byte `r1+0x3a` (cleared at session set-up,
    /// `10005620`), passed by pointer as `FUN_10006b50`'s 3rd argument (`100059c8`; r27 there). On the first
    /// no-player tick it is 0 → `nogo` is spawned, +0x34 = game time and the byte = 1 (`10006c88..10006d60`);
    /// on later no-player ticks the running flag clears at game time > +0x34 + flli 13 (`10006d68..10006d98`).
    /// Never reset within the session.
    public var gameOverNoticed = false

    public init() {}
}
