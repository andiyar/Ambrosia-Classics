import Foundation

/// The whole mutable simulation, one value (plan S2, invariant 13; DECISIONS D31.3). ★ LOCKED.
///
/// **This is the complete stored-field table.** Rule code lives in `extension GameState` methods (C8–C17,
/// C12) that take entity / player **indices**, re-read `world.entities[i]` / `players[i]` after any call
/// that may mutate the world, and never hold an `inout Entity` or `inout Player` across a `GameState` call.
/// A task alone in its wave may add a stored field here (listed in its PR notes); a task in a parallel wave
/// that finds one missing STOPs and reports. Step logs for order tests are closure parameters, never stored.
/// Session-only state — the frame controller, the console, the key table, the score-bar drawer — is the
/// session's (C18a), not the simulation's.
public struct GameState: Sendable {
    /// The decoded game data.
    public let assets: DeimosAssets
    /// The prefs (byte prefs, int prefs, key table): read by the rules (e.g. pref 5 interlace, pref 11).
    public var prefs: DeimosPrefs
    /// `_DAT_100e032c` — the game's RNG.
    public var rng: MSLRandom
    /// The game struct G's flags, counters and times.
    public var flags = GameFlags()
    /// G_Background.cc's scroll globals.
    public var scroll = ScrollState()
    /// G_EntityGroup.cc: the pool, groups, counters, pending level objects.
    public var world = EntityWorld()
    /// G+0x00 / G+0x04 — always two (index 0 = P1).
    public var players: [Player]
    /// The score bar's state.
    public var scoreBar: ScoreBarState
    /// G_Particle.cc (with its app-start tables).
    public var particles: ParticleSystem
    /// G_Debris.cc — the ground-obstacle rectangles `_DAT_100e01cc`.
    public var debris = DebrisList()
    /// G_MotionBlur.cpp's 1000-slot pool.
    public var blurs = MotionBlurPool()
    /// The notice slot (counts logic ticks).
    public var notice: NoticeSlot
    /// The message queue (counts presented frames).
    public var messages: MessageQueue
    /// The pass's sound and music cues, and the positional effects halt.
    public var cues = CueBuffer()
    /// The film being played back (`SessionStart.film`), nil when not a film session.
    public var film: FilmCursor? = nil
    /// The per-tick replay trace when one is recorded (H2), else nil.
    public var trace: TickTrace? = nil
    /// The level's media mask (C18a loads it at level start; C11b looks water up in it).
    public var mask = MediaMask()
    /// G+0x48…+0x168: the accuracy tally and mission bonus (C17).
    public var tally = TallyState()
    /// Render ops made during the tick — the terrain stamps of `FUN_10036610` step 2 / `destructDrawToTerrain`
    /// (C11b) — drained into the pass's ops before the world is drawn (C18a; leg A I-8, leg B I1).
    public var tickOps: [RenderOp] = []
    /// −0x6110: "Reached Entity Limit" was already reported this level (`FUN_10033220` `10033334..10033344`;
    /// cleared by `FUN_10032e60` `10032e88`).
    public var entityLimitWarned = false

    /// Two fresh players (`FUN_10026260`), a fresh world (`EntityWorld.init`, PERM created), empty buffers, the
    /// RNG seeded with `seed`. No behaviour beyond construction and reset: the session's set-up and level
    /// start (C18a) run `FUN_10026410`, `FUN_100064d0` and the rest.
    public init(assets: DeimosAssets, prefs: DeimosPrefs, seed: UInt32) {
        self.assets = assets
        self.prefs = prefs
        rng = MSLRandom(seed: seed)
        players = [Player(assets: assets), Player(assets: assets)]
        scoreBar = ScoreBarState(assets: assets)
        particles = ParticleSystem(floats: assets.floats)
        notice = NoticeSlot(floats: assets.floats)
        messages = MessageQueue(floats: assets.floats)
    }

    /// `FUN_10032e60` up to its last call: the entity-limit latch (`10032e88 stb r0,-0x6110(r2)`), then the
    /// world's level reset (`EntityWorld.levelReset`). The pending list `FUN_10035900(level)` is C8's.
    public mutating func levelResetEntities() {
        entityLimitWarned = false
        world.levelReset()
    }
}
