import Foundation
import HectorResources

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
    /// The twelve levels' definitions and media masks (plan LT): loaded and validated by `loadLevels` at the
    /// session's set-up, so the level start inside a pass cannot fail; a bare game state loads them on its first
    /// level start.
    public var levels = LevelSet()
    /// The level info `FUN_10011fd0` fills (`FUN_100051a0`'s `auStack_7e0`, `FUN_100064d0`'s `param_2`): the level
    /// start replaces it with the started level's (`10006588` / `100065dc`); the appear plays its music (+0x27c).
    public var levelInfo = LevelDefinition()
    /// Where this pass's transition fade to black fell in `cues` (`levelCompleteStep`); the session moves it into
    /// `PassOutput.fadeToBlackAt` with the cues (plan LT).
    public var fadeToBlackCues: CueMark? = nil

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

    /// Loads and validates the twelve levels (`LevelSet(assets:)`) — the session's set-up calls it, throwing there.
    public mutating func loadLevels() throws {
        levels = try LevelSet(assets: assets)
    }
}

/// The levels of `LevelOrder` (`FUN_10011de0` = 12), sector 1 first: each one's `leve` definition (what
/// `FUN_10011fd0` fills the level info with) and its media mask (`FUN_1000fbc0`'s `_DAT_100e0138` / `_DAT_100e0134`)
/// — decoded once, so the level start that `FUN_10007170` runs inside a pass (`1000725c`) cannot fail (plan LT).
public struct LevelSet: Sendable {
    /// Index `sector − 1`.
    public private(set) var definitions: [LevelDefinition] = []
    /// Index `sector − 1`.
    public private(set) var masks: [MediaMask] = []

    /// Empty: not loaded yet.
    public init() {}

    /// Every sector of the order: its level tag must name a `leve` definition (`SessionError.noLevel(sector:)` — the
    /// original's `10011da4` fatal error) and the definition's media mask must decode.
    public init(assets: DeimosAssets) throws {
        for (i, tag) in assets.levelOrder.levels.enumerated() {
            guard tag != .none, let info = assets.definitions.levels.first(where: { $0.id == tag }) else {
                throw SessionError.noLevel(sector: i + 1)
            }
            definitions.append(info)
            masks.append(try Self.loadMask(info, assets: assets))
        }
    }

    public var isEmpty: Bool { definitions.isEmpty }

    /// `FUN_1000fbc0`'s media mask: `info.mediaMask` (`+0x280`) as an im16 TGA, row-major top-down
    /// (`cells.count == width × height`, the index rule of `MediaMask.isWater`); `_DAT_100e0134` = map width / mask
    /// width (`divw`), where the map width is the background rect's right edge (the dimension check at `1000fbc0`
    /// requires the map image to match it).
    static func loadMask(_ info: LevelDefinition, assets: DeimosAssets) throws -> MediaMask {
        let type = FourCC("im16")!
        guard let r = assets.index.record(type: type, id: info.mediaMask) else {
            throw DeimosAssetsError.missingTag(type: "im16", id: info.mediaMask.description)
        }
        let tga = try TGAImage(data: assets.index.data(for: r))
        let w = Int32(tga.width), h = Int32(tga.height)
        return MediaMask(width: w, height: h, cells: tga.pixels, scale: w > 0 ? info.background.right / w : 0)
    }
}
