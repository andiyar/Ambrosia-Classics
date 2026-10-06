import Foundation
import HectorResources

/// A player definition (`plde`, G_PlayerDefinitions.cc; bank unit-def-struct.md §9, sizeof 0x108,
/// 57 keys), parsed as `FUN_10039cf0` → defaults → `FUN_10039e70`. Fields in reader call order
/// (naming and types as `UnitDefinition`); defaults: 11 IDs `none`, the sound record
/// {none, 100, 100, 100, 1.0, 1.0}, everything else 0. File order ≠ offset order in two places (the
/// score-bar Power sprite is read before Shield; `entry_InvulnerabilityTime` last of the entry group).
/// Three `_INT` keys are written as floats in the shipped files (`<100.000000>`, `<15.000000>`):
/// `%i` reads the leading integer (plan Known delta 5).
public struct PlayerDefinition: Sendable, Equatable {
    public static let magic: UInt32 = 0x4996_02d2

    /// +0x004: the plde tag ID.
    public var id: FourCC = .none
    /// `#name_STR` (+0x008)
    public var name: String = ""
    /// `#spriteHighScore_ID` (+0x028)
    public var spriteHighScore: FourCC = .none
    /// `#spriteHighScoreFrame_INT` (+0x02c)
    public var spriteHighScoreFrame: Int32 = 0
    /// `#spriteScoreBar_ID` (+0x030)
    public var spriteScoreBar: FourCC = .none
    /// `#spriteScoreBarFrame_INT` (+0x034)
    public var spriteScoreBarFrame: Int32 = 0
    /// `#spriteScoreBarPower_ID` (+0x040)
    public var spriteScoreBarPower: FourCC = .none
    /// `#spriteScoreBarPowerFrame_INT` (+0x044)
    public var spriteScoreBarPowerFrame: Int32 = 0
    /// `#spriteScoreBarShield_ID` (+0x038)
    public var spriteScoreBarShield: FourCC = .none
    /// `#spriteScoreBarShieldFrame_INT` (+0x03c)
    public var spriteScoreBarShieldFrame: Int32 = 0
    /// `#defaultShieldPercentage_INT` (+0x048)
    public var defaultShieldPercentage: Int32 = 0
    /// `#shieldWarningPercentage_INT` (+0x04c)
    public var shieldWarningPercentage: Int32 = 0
    /// `#shieldBaseHitPercentage_INT` (+0x050)
    public var shieldBaseHitPercentage: Int32 = 0
    /// `#shieldHitDelay_INT` (+0x054)
    public var shieldHitDelay: Int32 = 0
    /// `#hitGlowColor_COLOR` (+0x058)
    public var hitGlowColor: UInt16 = 0
    /// `#hitGlowSpeed_INT` (+0x05c)
    public var hitGlowSpeed: Int32 = 0
    /// `#life_MaxNum_INT` (+0x060)
    public var lifeMaxNum: Int32 = 0
    /// `#life_NumInitial_INT` (+0x064)
    public var lifeNumInitial: Int32 = 0
    /// `#life_InitialRequiredScore_INT` (+0x068)
    public var lifeInitialRequiredScore: Int32 = 0
    /// `#life_AdditionalRequiredScore_INT` (+0x06c)
    public var lifeAdditionalRequiredScore: Int32 = 0
    /// `#life_Spawn_ID` (+0x070)
    public var lifeSpawn: FourCC = .none
    /// `#waitingTime_INT` (+0x074)
    public var waitingTime: Int32 = 0
    /// `#filmIntroTime_INT` (+0x078)
    public var filmIntroTime: Int32 = 0
    /// `#introTime_INT` (+0x07c)
    public var introTime: Int32 = 0
    /// `#gameOverTime_INT` (+0x080)
    public var gameOverTime: Int32 = 0
    /// `#dyingTime_INT` (+0x084)
    public var dyingTime: Int32 = 0
    /// `#finalDyingTime_INT` (+0x088)
    public var finalDyingTime: Int32 = 0
    /// `#entry_soloStartX_INT` (+0x090)
    public var entrySoloStartX: Int32 = 0
    /// `#entry_soloStartY_INT` (+0x094)
    public var entrySoloStartY: Int32 = 0
    /// `#entry_multiStartX_INT` (+0x098)
    public var entryMultiStartX: Int32 = 0
    /// `#entry_multiStartY_INT` (+0x09c)
    public var entryMultiStartY: Int32 = 0
    /// `#entry_Spawn_ID` (+0x0a0)
    public var entrySpawn: FourCC = .none
    /// `#entry_StartVelocityX_FLOAT` (+0x0a4)
    public var entryStartVelocityX: Float = 0
    /// `#entry_StartVelocityY_FLOAT` (+0x0a8)
    public var entryStartVelocityY: Float = 0
    /// `#entry_TargetVelocityX_FLOAT` (+0x0ac)
    public var entryTargetVelocityX: Float = 0
    /// `#entry_TargetVelocityY_FLOAT` (+0x0b0)
    public var entryTargetVelocityY: Float = 0
    /// `#entry_VelocityDelta_FLOAT` (+0x0b4)
    public var entryVelocityDelta: Float = 0
    /// `#entry_InitialDelay_INT` (+0x0b8)
    public var entryInitialDelay: Int32 = 0
    /// `#entry_InvulnerabilityTime_INT` (+0x08c)
    public var entryInvulnerabilityTime: Int32 = 0
    /// `#death_Spawn_ID` (+0x0bc)
    public var deathSpawn: FourCC = .none
    /// `#death_Duration_INT` (+0x0c0)
    public var deathDuration: Int32 = 0
    /// `#active_MoneyCounterSpawn_ID` (+0x0c4)
    public var activeMoneyCounterSpawn: FourCC = .none
    /// `#active_SpawnOnHit_ID` (+0x0c8)
    public var activeSpawnOnHit: FourCC = .none
    /// `#active_ShieldWarningObject_ID` (+0x0cc)
    public var activeShieldWarningObject: FourCC = .none
    /// `#active_DefenceBonusObject_ID` (+0x0d0)
    public var activeDefenceBonusObject: FourCC = .none
    /// `#active_DefaultMaxSpeed_FLOAT` (+0x0d4)
    public var activeDefaultMaxSpeed: Float = 0
    /// `#active_VelocityDelta_FLOAT` (+0x0d8)
    public var activeVelocityDelta: Float = 0
    /// `#powerupOverload_NumWarnings_INT` (+0x0dc)
    public var powerupOverloadNumWarnings: Int32 = 0
    /// `#powerupOverload_InitialTimeBetweenWarnings_INT` (+0x0e0)
    public var powerupOverloadInitialTimeBetweenWarnings: Int32 = 0
    /// `#powerupOverload_MinimumTimeBetweenWarnings_INT` (+0x0e4)
    public var powerupOverloadMinimumTimeBetweenWarnings: Int32 = 0
    /// `#powerupOverload_WarningFadePercent_FLOAT` (+0x0e8)
    public var powerupOverloadWarningFadePercent: Float = 0
    /// `#powerupOverload_Hilite_COLOR` (+0x0ec)
    public var powerupOverloadHilite: UInt16 = 0
    /// `#powerupOverloadSound_ID` + 5 (+0x0f0, sound record 0x18)
    public var powerupOverloadSound: SoundRecord = SoundRecord()
    /// Non-fatal log lines (missing sprite resets). Not part of the original's struct.
    public var notes: [String] = []

    public init() {}

    /// Parse one `plde` tag: always de-obfuscated; strict mode — any non-STR token error is the
    /// original's fatal "A Player Definition file contained incorrect or missing data." (reported in
    /// `errors`, after the keys, never thrown). Each of the four sprite IDs is checked right after it
    /// is read (`FUN_1001fbe0`): unknown → logged + `none` (the original also loads it at once; not here).
    public static func parse(id: FourCC, text raw: [UInt8], spriteExists: (FourCC) -> Bool)
        -> (PlayerDefinition, errors: [String]) {
        var p = DefinitionReader(DeimosText.decodeCString(raw))
        var d = PlayerDefinition()
        d.id = id
        p.str(&d.name, "#name_STR", maxLength: 0x20)
        p.id(&d.spriteHighScore, "#spriteHighScore_ID")
        DefinitionReader.checkSprite(&d.spriteHighScore, spriteExists, notes: &d.notes)
        p.int(&d.spriteHighScoreFrame, "#spriteHighScoreFrame_INT")
        p.id(&d.spriteScoreBar, "#spriteScoreBar_ID")
        DefinitionReader.checkSprite(&d.spriteScoreBar, spriteExists, notes: &d.notes)
        p.int(&d.spriteScoreBarFrame, "#spriteScoreBarFrame_INT")
        p.id(&d.spriteScoreBarPower, "#spriteScoreBarPower_ID")
        DefinitionReader.checkSprite(&d.spriteScoreBarPower, spriteExists, notes: &d.notes)
        p.int(&d.spriteScoreBarPowerFrame, "#spriteScoreBarPowerFrame_INT")
        p.id(&d.spriteScoreBarShield, "#spriteScoreBarShield_ID")
        DefinitionReader.checkSprite(&d.spriteScoreBarShield, spriteExists, notes: &d.notes)
        p.int(&d.spriteScoreBarShieldFrame, "#spriteScoreBarShieldFrame_INT")
        p.int(&d.defaultShieldPercentage, "#defaultShieldPercentage_INT")
        p.int(&d.shieldWarningPercentage, "#shieldWarningPercentage_INT")
        p.int(&d.shieldBaseHitPercentage, "#shieldBaseHitPercentage_INT")
        p.int(&d.shieldHitDelay, "#shieldHitDelay_INT")
        p.color(&d.hitGlowColor, "#hitGlowColor_COLOR")
        p.int(&d.hitGlowSpeed, "#hitGlowSpeed_INT")
        p.int(&d.lifeMaxNum, "#life_MaxNum_INT")
        p.int(&d.lifeNumInitial, "#life_NumInitial_INT")
        p.int(&d.lifeInitialRequiredScore, "#life_InitialRequiredScore_INT")
        p.int(&d.lifeAdditionalRequiredScore, "#life_AdditionalRequiredScore_INT")
        p.id(&d.lifeSpawn, "#life_Spawn_ID")
        p.int(&d.waitingTime, "#waitingTime_INT")
        p.int(&d.filmIntroTime, "#filmIntroTime_INT")
        p.int(&d.introTime, "#introTime_INT")
        p.int(&d.gameOverTime, "#gameOverTime_INT")
        p.int(&d.dyingTime, "#dyingTime_INT")
        p.int(&d.finalDyingTime, "#finalDyingTime_INT")
        p.int(&d.entrySoloStartX, "#entry_soloStartX_INT")
        p.int(&d.entrySoloStartY, "#entry_soloStartY_INT")
        p.int(&d.entryMultiStartX, "#entry_multiStartX_INT")
        p.int(&d.entryMultiStartY, "#entry_multiStartY_INT")
        p.id(&d.entrySpawn, "#entry_Spawn_ID")
        p.float(&d.entryStartVelocityX, "#entry_StartVelocityX_FLOAT")
        p.float(&d.entryStartVelocityY, "#entry_StartVelocityY_FLOAT")
        p.float(&d.entryTargetVelocityX, "#entry_TargetVelocityX_FLOAT")
        p.float(&d.entryTargetVelocityY, "#entry_TargetVelocityY_FLOAT")
        p.float(&d.entryVelocityDelta, "#entry_VelocityDelta_FLOAT")
        p.int(&d.entryInitialDelay, "#entry_InitialDelay_INT")
        p.int(&d.entryInvulnerabilityTime, "#entry_InvulnerabilityTime_INT")
        p.id(&d.deathSpawn, "#death_Spawn_ID")
        p.int(&d.deathDuration, "#death_Duration_INT")
        p.id(&d.activeMoneyCounterSpawn, "#active_MoneyCounterSpawn_ID")
        p.id(&d.activeSpawnOnHit, "#active_SpawnOnHit_ID")
        p.id(&d.activeShieldWarningObject, "#active_ShieldWarningObject_ID")
        p.id(&d.activeDefenceBonusObject, "#active_DefenceBonusObject_ID")
        p.float(&d.activeDefaultMaxSpeed, "#active_DefaultMaxSpeed_FLOAT")
        p.float(&d.activeVelocityDelta, "#active_VelocityDelta_FLOAT")
        p.int(&d.powerupOverloadNumWarnings, "#powerupOverload_NumWarnings_INT")
        p.int(&d.powerupOverloadInitialTimeBetweenWarnings, "#powerupOverload_InitialTimeBetweenWarnings_INT")
        p.int(&d.powerupOverloadMinimumTimeBetweenWarnings, "#powerupOverload_MinimumTimeBetweenWarnings_INT")
        p.float(&d.powerupOverloadWarningFadePercent, "#powerupOverload_WarningFadePercent_FLOAT")
        p.color(&d.powerupOverloadHilite, "#powerupOverload_Hilite_COLOR")
        p.sound(&d.powerupOverloadSound, "powerupOverloadSound")
        var errors = p.errors
        if !errors.isEmpty { errors.append("A Player Definition file contained incorrect or missing data.") }
        return (d, errors)
    }
}
