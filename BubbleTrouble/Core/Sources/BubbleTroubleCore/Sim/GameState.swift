import Foundation

/// The whole simulation state: every global the original's game loop reads or writes, the entity arrays at their
/// original capacities and slot order (Invariant 8), and the RNG threaded through all of it. Each original function
/// becomes one `GameState` method in a file named after its domain; level construction lives in `LevelBuild.swift`.
///
/// Every stored property is declared here (Swift extensions cannot add stored properties — plan §Task 4.1).
public struct GameState: Sendable {
    public static let enemyCapacity = 30, blockCapacity = 35, balloonCapacity = 30, bonusCapacity = 2
    /// `_gBonus_RandDriftTable` (0x37700–0x3772a: 21 shorts).
    public static let bonusDriftCount = 21
    /// `jewel` (up to 4 jewels × (col,row) bytes).
    public static let jewelCapacity = 4

    // MARK: Session

    public internal(set) var config: SessionConfig
    /// `gGameMode`.
    public internal(set) var mode: GameMode
    /// QuickDraw's `randSeed` + `_GetRandomFast`, seeded once by `newGame` (Research note 3).
    public internal(set) var rng: GameRandom
    /// `gFrameCounter` — UInt16, wraps (`&+= 1`), zeroed by `_NewLevel` (Invariant 9).
    public internal(set) var frame: UInt16
    /// `gStackLevel` (`_GetLevel` / `_GetCurrLevelNum`).
    public internal(set) var level: Int

    // MARK: Level data

    /// `gMaze` — the live maze.
    public internal(set) var maze: Maze
    /// `gMazeCopy` — the MAZE as loaded (read by `_RegenerateBlocks`).
    public internal(set) var mazeCopy: Maze
    /// `level` — the working copy of the LEVL record with `_LoadLevel`'s clamps applied to w6/w12; the enemy pool
    /// words w18…w23 are mutated at run time.
    public internal(set) var levelRecord: LevelRecord

    // MARK: Entities

    public internal(set) var hero: Hero
    /// `enemy` — 30 slots.
    public internal(set) var enemies: [Enemy]
    /// `gREGCHECK1registered` — one `RT3_IsRegistered()` byte per enemy slot, written by `_InitEnemies`, read by
    /// `_ProcessEnemies`.
    public internal(set) var enemyRegistered: [Bool]
    /// `block` — 35 slots.
    public internal(set) var blocks: [Block]
    /// `gBalloons` — 30 slots.
    public internal(set) var balloons: [Balloon]
    /// `bonus` — 2 slots.
    public internal(set) var bonus: [BonusBubble]
    /// `_gBonus_RandDriftTable` — 21 × `GetRandomFast(0,4)` per level.
    public internal(set) var bonusDrift: [Int16]
    /// `_gBonus_RandDriftIndex` (wraps 21).
    public internal(set) var bonusDriftIndex: Int
    /// `gHurtBlock` — 50 redraw entries (draw only).
    public internal(set) var hurtBlocks: [HurtBlock]

    // MARK: Cosmetic pools (they consume RNG)

    public internal(set) var stars: StarPool
    public internal(set) var airBubbles: AirBubblePool
    public internal(set) var points: PointPool
    public internal(set) var splats: SplatPool

    // MARK: Score, lives, multiplier, EXTRA

    /// `gStackScore`.
    public internal(set) var score: Int32
    /// `gNextExtraLifeScore` (10000, then 40000, +40000 …).
    public internal(set) var nextExtraLifeScore: Int32
    /// `gStackLives`.
    public internal(set) var lives: Int16
    /// `gBonusMultiplier` 1…5.
    public internal(set) var multiplier: Int16
    /// `gMultiplier_Animate` / `_gMultiplier_Timer` / `_gMultiplier_AnimCounter` (`_Multiplier_Process` flash only).
    public internal(set) var multiplierAnimating: Bool
    public internal(set) var multiplierTimer: UInt16
    public internal(set) var multiplierAnimCounter: Int16
    /// `_gExtra_E`, `_X`, `_T`, `_R`, `_A`.
    public internal(set) var extraLetters: [Bool]
    /// `gEXTRA_Animate` / `_gEXTRA_Timer` / `_gEXTRA_AnimCounter`.
    public internal(set) var extraAnimating: Bool
    public internal(set) var extraTimer: UInt16
    public internal(set) var extraAnimCounter: Int16

    // MARK: Time bonus

    /// `_gTimeBonus`.
    public internal(set) var timeBonus: Int32
    /// `_gTimeBonusTimer`.
    public internal(set) var timeBonusTimer: UInt16
    /// `_gTimeBonus_FlashBonus` / `_gTimeBonus_FlashTimer` (display flash; no RNG).
    public internal(set) var timeBonusFlash: Bool
    public internal(set) var timeBonusFlashTimer: UInt16

    // MARK: Jewels and blocks

    /// `gNumJewels` (LEVL w12 clamped 3…4).
    public internal(set) var numJewels: Int
    /// `gJewelFound`.
    public internal(set) var jewelFound: Bool
    /// (`gTargetJewelXLoc`, `gTargetJewelYLoc`); `nil` = (0xff, 0xff) as set by `_PositionJewels`.
    public internal(set) var targetJewel: CellRef?
    /// `gJewelCount`.
    public internal(set) var jewelCount: Int
    /// `gJewelsDone`.
    public internal(set) var jewelsDone: Bool
    /// `gJewelAnimDir` (true = 1, counting up).
    public internal(set) var jewelAnimDir: Bool
    /// `jewel` — the placed jewels' cells, by jewel index (4 entries; unused ones stay (0,0)).
    public internal(set) var jewelCells: [CellRef]
    /// `gNumNormalBlocks` — 100 after `_ResetBlocks` (C6); recounted each frame while > 0.
    public internal(set) var numNormalBlocks: Int16
    /// `_gNumActiveBlocks`.
    public internal(set) var numActiveBlocks: Int

    // MARK: Enemies and balloons

    /// `gNumEnemiesActive` (`char`).
    public internal(set) var numEnemiesActive: Int8
    /// `gNumEnemiesSquished` (`char`).
    public internal(set) var numEnemiesSquished: Int8
    /// `_gBalloons_NumActive`.
    public internal(set) var numActiveBalloons: Int
    /// `_gBonus_NumEnemiesSquishedAtOnce` (zeroed by `_Bonus_Init` on level 1 only).
    public internal(set) var bonusSquishedAtOnce: Int16
    /// `gEnemy_LastColour` (1 after `_InitEnemies`).
    public internal(set) var enemyLastColour: Int8
    /// `gAIRegistered` = `RT3_GetLicenseCode() != 0`, set by `_DrawMaze` (gates the unregistered `(0,7)` dummy draw).
    public internal(set) var aiRegistered: Bool

    // MARK: Loop state

    /// `gIsEndOfLevel`.
    public internal(set) var isEndOfLevel: Bool
    /// `gEndOfLevelTime`.
    public internal(set) var endOfLevelTime: UInt16
    /// `_PlayGame`'s loop-local `first` (70-frame first appearance instead of 60).
    public internal(set) var firstAppearance: Bool
    /// `gPlayGame` — false once a stop fired (takes effect at the next loop top).
    public internal(set) var playing: Bool
    /// `_gLevelForEffect` — 50 (process start) until the first state-2 `_ProcessHero` latches `_Get13To22()`.
    public internal(set) var levelForEffect: Int
    /// `gHero_Up/Down/Left/Right/PushKeyPressed` — written only by `_CheckHeroMovement`, persisting across frames
    /// (`gHero_MoveKeyDown` = any direction held; computed in `Input.swift`).
    public internal(set) var heroKeys: FilmSample
    /// Set by `_HeroCaught` during a frame; the frame step clears it at the top of each frame (Task 10 report).
    public internal(set) var heroCaughtThisFrame: Bool
    /// Every stop reason that fired (Invariant 14).
    public internal(set) var pendingStops: Set<StopReason>
    /// `_gShowWhichNotice` / `_gLastNoticeShown` / `_gEraseNotice` (`Session/NoticeBoard.swift`, C4's transcription).
    public internal(set) var notices: NoticeBoard

    // MARK: Sound (`Sounds.swift`; plan 2026-10-04 btx-playable C2)

    /// `_delayedSound` — the 5-entry delayed-sound queue of `_PlayMySnd @ 00026a7b` /
    /// `_Sounds_CheckDelayedSounds @ 000268a1`; emptied only by `_Sounds_InitDelayedSounds` (`_NewLevel`).
    var delayedSounds: [DelayedSound]
    /// This frame's `ST_PlaySound` calls in order — cleared at the top of `stepFrame`, copied into `FrameReport.sounds`.
    var soundsThisFrame: [SoundCue]

    /// An empty world: all slots free, zero tables, RNG seeded with `seed` through `config.rngStep`, frame 0.
    init(config: SessionConfig, mode: GameMode, seed: UInt32) {
        self.config = config
        self.mode = mode
        rng = GameRandom(seed: seed, step: config.rngStep)
        frame = 0
        level = 0
        let empty = try! Maze(data: Data(count: Maze.byteCount))      // 176 bytes: cannot throw
        maze = empty
        mazeCopy = empty
        levelRecord = try! LevelRecord(data: Data(count: LevelRecord.byteCount))   // 64 bytes: cannot throw
        hero = Hero()
        enemies = Array(repeating: Enemy(), count: Self.enemyCapacity)
        enemyRegistered = Array(repeating: false, count: Self.enemyCapacity)
        blocks = Array(repeating: Block(), count: Self.blockCapacity)
        balloons = Array(repeating: Balloon(), count: Self.balloonCapacity)
        bonus = Array(repeating: BonusBubble(), count: Self.bonusCapacity)
        bonusDrift = Array(repeating: 0, count: Self.bonusDriftCount)
        bonusDriftIndex = 0
        hurtBlocks = Array(repeating: HurtBlock(), count: HurtBlock.capacity)
        stars = StarPool()
        airBubbles = AirBubblePool()
        points = PointPool()
        splats = SplatPool()
        score = 0
        nextExtraLifeScore = 0
        lives = 0
        multiplier = 0
        multiplierAnimating = false
        multiplierTimer = 0
        multiplierAnimCounter = 0
        extraLetters = Array(repeating: false, count: 5)
        extraAnimating = false
        extraTimer = 0
        extraAnimCounter = 0
        timeBonus = 0
        timeBonusTimer = 0
        timeBonusFlash = false
        timeBonusFlashTimer = 0
        numJewels = 0
        jewelFound = false
        targetJewel = nil
        jewelCount = 0
        jewelsDone = false
        jewelAnimDir = false
        jewelCells = Array(repeating: CellRef(col: 0, row: 0), count: Self.jewelCapacity)
        numNormalBlocks = 0
        numActiveBlocks = 0
        numEnemiesActive = 0
        numEnemiesSquished = 0
        numActiveBalloons = 0
        bonusSquishedAtOnce = 0
        enemyLastColour = 0
        aiRegistered = false
        isEndOfLevel = false
        endOfLevelTime = 0
        firstAppearance = true
        playing = false
        levelForEffect = 50          // `__data` 0x34254 = 0x32
        heroKeys = FilmSample(up: false, down: false, left: false, right: false, push: false)
        heroCaughtThisFrame = false
        pendingStops = []
        delayedSounds = Array(repeating: DelayedSound(), count: Self.delayedSoundCapacity)
        soundsThisFrame = []
        notices = NoticeBoard()
    }

    /// What the cosmetic pools read from the hero record (`HeroAnchor`); `_Bubbles` writes `lastBubbleFrame` back.
    var heroAnchor: HeroAnchor {
        get {
            HeroAnchor(state: hero.state, aligned: hero.aligned, facing: hero.facing, rect: hero.rect,
                       lastBubbleFrame: hero.lastBubbleFrame)
        }
        set { hero.lastBubbleFrame = newValue.lastBubbleFrame }
    }
}
