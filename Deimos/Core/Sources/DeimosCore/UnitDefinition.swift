import Foundation
import HectorResources

/// A unit definition (`unde`, G_UnitDefinitions.cc; bank unit-def-struct.md §2–§6), parsed exactly as
/// `FUN_1003fc50` → `FUN_1003e1e0` (defaults) → `FUN_1003fda0` / `FUN_10040920` (parse) does.
///
/// Fields are the bank's key tables **in reader call order** (the P@ listing addresses, sorted; that
/// order IS the parse because the U_Token cursor only moves forward). Field name = key minus its type
/// suffix, lowerCamel (underscores and the apostrophe dropped); type per suffix (STR → String, ID →
/// FourCC, INT → Int32, FLOAT → Float, BOOL → Bool, COLOR → UInt16 x1R5G5B5); the six keys of a sound
/// record form one `SoundRecord`. Defaults are the `D@` column (`FUN_1003e1e0`). The no-key regions
/// of the 0x7a60 struct (unit-def-struct.md NOT RESOLVED 1, incl. the 15 reserved `none` ID slots)
/// are not modelled.
///
/// Derived fields: `id` (the tag ID, +0x004), `layer` (+0x008, `grnd` iff `isGroundBased` else
/// `air `), `version` (+0x00c, 10000), `hasDataError` (+0x010, the token error flag),
/// `hasOwnerLinkedState` (+0x011).
public struct UnitDefinition: Sendable, Equatable {
    public static let magic: UInt32 = 0x4996_02d2
    public static let fileDataVersion: Int32 = 10000
    /// `kG_UnitDef_MaxNumStates` — the master-list check (`FUN_1003d0a0`), not a parser cap.
    public static let maxNumStates = 20
    public static let ground = FourCC("grnd")!
    public static let air = FourCC("air ")!

    public var id: FourCC = .none
    public var layer: FourCC = UnitDefinition.air
    public var version: Int32 = UnitDefinition.fileDataVersion
    public var hasDataError = false
    public var hasOwnerLinkedState = false

    /// `#name_STR` (+0x018)
    public var name: String = ""
    /// `#familyName_STR` (+0x058)
    public var familyName: String = ""
    /// `#description_STR` (+0x098)
    public var description: String = ""
    /// `#numInGroupMin_INT` (+0x194)
    public var numInGroupMin: Int32 = 1
    /// `#numInGroupMax_INT` (+0x198)
    public var numInGroupMax: Int32 = 1
    /// `#groupDelayMin_INT` (+0x19c)
    public var groupDelayMin: Int32 = 0
    /// `#groupDelayMax_INT` (+0x1a0)
    public var groupDelayMax: Int32 = 0
    /// `#appearsPercent_INT` (+0x1c0)
    public var appearsPercent: Int32 = 100
    /// `#deleteExistingEntitiesOfThisTypeOwnedByPlayer_BOOL` (+0x119)
    public var deleteExistingEntitiesOfThisTypeOwnedByPlayer: Bool = false
    /// `#doNotSpawnIfTypeAlreadyExists_BOOL` (+0x118)
    public var doNotSpawnIfTypeAlreadyExists: Bool = false
    /// `#harmlessToPlayers_BOOL` (+0x11a)
    public var harmlessToPlayers: Bool = false
    /// `#playerProjectile_BOOL` (+0x11b)
    public var playerProjectile: Bool = false
    /// `#canBeHitByPlayerProjectile_BOOL` (+0x11c)
    public var canBeHitByPlayerProjectile: Bool = false
    /// `#terrainEffect_BOOL` (+0x132)
    public var terrainEffect: Bool = false
    /// `#constrainInGameArea_BOOL` (+0x11d)
    public var constrainInGameArea: Bool = false
    /// `#castsShadows_BOOL` (+0x11e)
    public var castsShadows: Bool = false
    /// `#adjustShadowLocForScaling_BOOL` (+0x12c)
    public var adjustShadowLocForScaling: Bool = false
    /// `#randomiseInitialLoc_BOOL` (+0x12d)
    public var randomiseInitialLoc: Bool = false
    /// `#adjustInitialLocForOwnerScale_BOOL` (+0x12e)
    public var adjustInitialLocForOwnerScale: Bool = false
    /// `#initiallyHuntsClosestPlayer_BOOL` (+0x11f)
    public var initiallyHuntsClosestPlayer: Bool = false
    /// `#hittableWhenInvisible_BOOL` (+0x121)
    public var hittableWhenInvisible: Bool = false
    /// `#initialHeadingSetInEditor_BOOL` (+0x124)
    public var initialHeadingSetInEditor: Bool = false
    /// `#fleesNorthOnNoActivePlayers_BOOL` (+0x126)
    public var fleesNorthOnNoActivePlayers: Bool = false
    /// `#fleesSouthOnNoActivePlayers_BOOL` (+0x127)
    public var fleesSouthOnNoActivePlayers: Bool = false
    /// `#collidesWithGroundObstacles_BOOL` (+0x128)
    public var collidesWithGroundObstacles: Bool = false
    /// `#canBeSpawnedOnlyWhenPlayersActive_BOOL` (+0x12a)
    public var canBeSpawnedOnlyWhenPlayersActive: Bool = false
    /// `#usePreviewAppearanceInPlacementEditor_BOOL` (+0x12f)
    public var usePreviewAppearanceInPlacementEditor: Bool = false
    /// `#allowStationaryOptionInPlacementEditor_BOOL` (+0x130)
    public var allowStationaryOptionInPlacementEditor: Bool = false
    /// `#includeInAirAccuracyCount_BOOL` (+0x133)
    public var includeInAirAccuracyCount: Bool = false
    /// `#includeInGroundAccuracyCount_BOOL` (+0x134)
    public var includeInGroundAccuracyCount: Bool = false
    /// `#editorPreviewSpriteFace_ID` (+0x2d4)
    public var editorPreviewSpriteFace: FourCC = .none
    /// `#editorPreviewSpriteFrame_INT` (+0x1bc)
    public var editorPreviewSpriteFrame: Int32 = 0
    /// `#pickup_Type_ID` (+0x4d4)
    public var pickupType: FourCC = .none
    /// `#pickup_MultiplierSpawn_ID` (+0x4d8)
    public var pickupMultiplierSpawn: FourCC = .none
    /// `#pickup_Value_INT` (+0x4dc)
    public var pickupValue: Int32 = 0
    /// `#destructSpawn_ID` (+0x478)
    public var destructSpawn: FourCC = .none
    /// `#destructSound_ID` + 5 (+0x4bc, sound record 0x18)
    public var destructSound: SoundRecord = SoundRecord()
    /// `#destructParticle_ID` (+0x47c)
    public var destructParticle: FourCC = .none
    /// `#destructParticleColor_COLOR` (+0x480)
    public var destructParticleColor: UInt16 = 0
    /// `#destructNotice_STR` (+0x482)
    public var destructNotice: String = ""
    /// `#destructNumCoinsToRelease_INT` (+0x4a4)
    public var destructNumCoinsToRelease: Int32 = 0
    /// `#destructCoin_ID` (+0x4a8)
    public var destructCoin: FourCC = .none
    /// `#destructCoinOnGroupKill_ID` (+0x4ac)
    public var destructCoinOnGroupKill: FourCC = .none
    /// `#destructDestroyChildren_BOOL` (+0x4b0)
    public var destructDestroyChildren: Bool = false
    /// `#destructDeleteChildren_BOOL` (+0x4b1)
    public var destructDeleteChildren: Bool = false
    /// `#destructDrawToTerrain_BOOL` (+0x4b2)
    public var destructDrawToTerrain: Bool = false
    /// `#destructReleaseRandomBonus_BOOL` (+0x4b4)
    public var destructReleaseRandomBonus: Bool = false
    /// `#destructCreateObstacle_BOOL` (+0x4b3)
    public var destructCreateObstacle: Bool = false
    /// `#shields_MaxAmount_FLOAT` (+0x444)
    public var shieldsMaxAmount: Float = 0
    /// `#shields_LevelIncrement_FLOAT` (+0x440)
    public var shieldsLevelIncrement: Float = 0
    /// `#shields_BaseAmount_FLOAT` (+0x43c)
    public var shieldsBaseAmount: Float = 0
    /// `#score_INT` (+0x4b8)
    public var score: Int32 = 0
    /// `#damage_FLOAT` (+0x274)
    public var damage: Float = 0
    /// `#initialVisibilityPercent_INT` (+0x1b4)
    public var initialVisibilityPercent: Int32 = 100
    /// `#initialScalePercent_INT` (+0x1ac)
    public var initialScalePercent: Int32 = 100
    /// `#initialScalePercentTolerance_INT` (+0x1b0)
    public var initialScalePercentTolerance: Int32 = 0
    /// `#drawLayer_ID` (+0x2e0)
    public var drawLayer: FourCC = .none
    /// `#entryNotice_STR` (+0x324)
    public var entryNotice: String = ""
    /// `#entryNoticeDelay_INT` (+0x1b8)
    public var entryNoticeDelay: Int32 = 0
    /// `#displayNoticeOnceOnly_BOOL` (+0x120)
    public var displayNoticeOnceOnly: Bool = false
    /// `#entryNoticeSound_ID` + 5 (+0x424, sound record 0x18)
    public var entryNoticeSound: SoundRecord = SoundRecord()
    /// `#hitParticles_ID` (+0x2d8)
    public var hitParticles: FourCC = .none
    /// `#hitParticleDoCircularBurst_BOOL` (+0x131)
    public var hitParticleDoCircularBurst: Bool = false
    /// `#hitParticlesColor_COLOR` (+0x17e)
    public var hitParticlesColor: UInt16 = 0
    /// `#shieldSound_ID` + 5 (+0x448, sound record 0x18)
    public var shieldSound: SoundRecord = SoundRecord()
    /// `#unshieldedSound_ID` + 5 (+0x460, sound record 0x18)
    public var unshieldedSound: SoundRecord = SoundRecord()
    /// `#deletionSpawn_ID` (+0x2dc)
    public var deletionSpawn: FourCC = .none
    /// `#xOffsetMin_FLOAT` (+0x25c)
    public var xOffsetMin: Float = 0
    /// `#xOffsetMax_FLOAT` (+0x260)
    public var xOffsetMax: Float = 0
    /// `#yOffsetMin_FLOAT` (+0x264)
    public var yOffsetMin: Float = 0
    /// `#yOffsetMax_FLOAT` (+0x268)
    public var yOffsetMax: Float = 0
    /// `#initialHeading_INT` (+0x1a4)
    public var initialHeading: Int32 = 0
    /// `#initialHeadingTolerance_INT` (+0x1a8)
    public var initialHeadingTolerance: Int32 = 0
    /// `#useOwnerHeading_BOOL` (+0x129)
    public var useOwnerHeading: Bool = false
    /// `#initialSpeedMin_FLOAT` (+0x26c)
    public var initialSpeedMin: Float = 0
    /// `#initialSpeedMax_FLOAT` (+0x270)
    public var initialSpeedMax: Float = 0
    /// `#doBurst_BOOL` (+0x122)
    public var doBurst: Bool = false
    /// `#doImplode_BOOL` (+0x123)
    public var doImplode: Bool = false
    /// `#isGroundBased_BOOL` (+0x125)
    public var isGroundBased: Bool = false
    /// `#doDeathSpawnOnAnyMedia_BOOL` (+0x12b)
    public var doDeathSpawnOnAnyMedia: Bool = false
    /// `#mediaImpactSize_ID` (+0x2e4)
    public var mediaImpactSize: FourCC = .none
    /// `#numStates_INT` (+0x014; default 1, always overwritten — §2.4)
    public var numStates: Int32 = 1
    /// The states as read (`numStates` of them; no cap — §2.5). The original's slots
    /// `numStates..<20` hold `UnitState.defaults(index:)`.
    public var states: [UnitState] = []
    /// Non-fatal log lines the parse would print (missing sprite resets, unused state timers, spawn
    /// sets with spawn `none`), in order. Not part of the original's struct.
    public var notes: [String] = []

    public init() {}

    /// Parse one `unde` tag. `text` = the entry's raw bytes; they are de-obfuscated only if
    /// `#name_STR` is not found in them (plan Research note 11). Strict mode (`FUN_1002c4d0(…, 1)`) is
    /// on: any non-STR token error is the original's fatal load error ("A Unit Definition file
    /// contained incorrect or missing data." + shutdown) — reported in `errors` (the keys, then that
    /// line), never thrown. A `numStates` outside 0…20 adds the original's log line — naming the tag
    /// FILE (`FUN_10002420('unde', id)` = record +0x110, passed in as `tagName`), not `#name_STR` — and
    /// assert text (`FUN_1003d0a0`, `1003d1d0–1003d218`).
    ///
    /// Post-parse fix-ups (§2.6). In the original each sits at a point in the read sequence; this port
    /// applies some of them later, which is observationally identical because no later read depends on
    /// them:
    /// - `editorPreviewSpriteFace` / each `stateSpriteFace` naming no sprite group → `none` (logged);
    /// - `shieldsMaxAmount < shieldsBaseAmount` → max = base (the original: right after
    ///   `shields_BaseAmount`, `100403a8`; here after `numStates`);
    /// - per state `stateOnTimerMax < stateOnTimerMin` → max = min (the original: right after the
    ///   `stateOnTimerMax` read and BEFORE `stateOnTimerChangeTo`, `10040a18–10040a28`; here after
    ///   `stateOnTimerChangeTo`); then max > 0 with an empty `stateOnTimerChangeTo` → note + both timers 0
    ///   (`10040a48–10040aa0`);
    /// - any owner bool (state +0x324…+0x330) TRUE in any read state → `hasOwnerLinkedState`;
    /// - `layer` from `isGroundBased`.
    /// `notes` also carries the original's two FYI lines: destroy-children without delete-children
    /// (right after `destructCreateObstacle`, `10040318–10040358`) and delete/destroy-children with no
    /// state that spawns (after the state loop, `10040844–100408fc`). Each NOTE/FYI line is followed in
    /// the original by `    Unit File:  "<tag file>"` (`0x100ee29e`); those second lines are dropped here.
    /// `numRules > 5` is read as the original does (the cursor advances through every rule) but rules
    /// past slot 4 — which the original writes over state+0x2d0… — are not stored; reported in
    /// `notes` as this port's own line (not a token error).
    public static func parse(id: FourCC, text raw: [UInt8], spriteExists: (FourCC) -> Bool,
                             tagName: String = "") -> (UnitDefinition, errors: [String]) {
        let text = DefinitionReader.plainText(raw, unlessContains: "#name_STR")
        var p = DefinitionReader(text)
        var u = UnitDefinition()
        var notes: [String] = []
        u.id = id

        p.str(&u.name, "#name_STR", maxLength: 0x40)
        p.str(&u.familyName, "#familyName_STR", maxLength: 0x40)
        p.str(&u.description, "#description_STR", maxLength: 0x80)
        p.int(&u.numInGroupMin, "#numInGroupMin_INT")
        p.int(&u.numInGroupMax, "#numInGroupMax_INT")
        p.int(&u.groupDelayMin, "#groupDelayMin_INT")
        p.int(&u.groupDelayMax, "#groupDelayMax_INT")
        p.int(&u.appearsPercent, "#appearsPercent_INT")
        p.bool(&u.deleteExistingEntitiesOfThisTypeOwnedByPlayer, "#deleteExistingEntitiesOfThisTypeOwnedByPlayer_BOOL")
        p.bool(&u.doNotSpawnIfTypeAlreadyExists, "#doNotSpawnIfTypeAlreadyExists_BOOL")
        p.bool(&u.harmlessToPlayers, "#harmlessToPlayers_BOOL")
        p.bool(&u.playerProjectile, "#playerProjectile_BOOL")
        p.bool(&u.canBeHitByPlayerProjectile, "#canBeHitByPlayerProjectile_BOOL")
        p.bool(&u.terrainEffect, "#terrainEffect_BOOL")
        p.bool(&u.constrainInGameArea, "#constrainInGameArea_BOOL")
        p.bool(&u.castsShadows, "#castsShadows_BOOL")
        p.bool(&u.adjustShadowLocForScaling, "#adjustShadowLocForScaling_BOOL")
        p.bool(&u.randomiseInitialLoc, "#randomiseInitialLoc_BOOL")
        p.bool(&u.adjustInitialLocForOwnerScale, "#adjustInitialLocForOwnerScale_BOOL")
        p.bool(&u.initiallyHuntsClosestPlayer, "#initiallyHuntsClosestPlayer_BOOL")
        p.bool(&u.hittableWhenInvisible, "#hittableWhenInvisible_BOOL")
        p.bool(&u.initialHeadingSetInEditor, "#initialHeadingSetInEditor_BOOL")
        p.bool(&u.fleesNorthOnNoActivePlayers, "#fleesNorthOnNoActivePlayers_BOOL")
        p.bool(&u.fleesSouthOnNoActivePlayers, "#fleesSouthOnNoActivePlayers_BOOL")
        p.bool(&u.collidesWithGroundObstacles, "#collidesWithGroundObstacles_BOOL")
        p.bool(&u.canBeSpawnedOnlyWhenPlayersActive, "#canBeSpawnedOnlyWhenPlayersActive_BOOL")
        p.bool(&u.usePreviewAppearanceInPlacementEditor, "#usePreviewAppearanceInPlacementEditor_BOOL")
        p.bool(&u.allowStationaryOptionInPlacementEditor, "#allowStationaryOptionInPlacementEditor_BOOL")
        p.bool(&u.includeInAirAccuracyCount, "#includeInAirAccuracyCount_BOOL")
        p.bool(&u.includeInGroundAccuracyCount, "#includeInGroundAccuracyCount_BOOL")
        p.id(&u.editorPreviewSpriteFace, "#editorPreviewSpriteFace_ID")
        p.int(&u.editorPreviewSpriteFrame, "#editorPreviewSpriteFrame_INT")
        p.id(&u.pickupType, "#pickup_Type_ID")
        p.id(&u.pickupMultiplierSpawn, "#pickup_MultiplierSpawn_ID")
        p.int(&u.pickupValue, "#pickup_Value_INT")
        p.id(&u.destructSpawn, "#destructSpawn_ID")
        p.sound(&u.destructSound, "destructSound")
        p.id(&u.destructParticle, "#destructParticle_ID")
        p.color(&u.destructParticleColor, "#destructParticleColor_COLOR")
        p.str(&u.destructNotice, "#destructNotice_STR", maxLength: 0x20)
        p.int(&u.destructNumCoinsToRelease, "#destructNumCoinsToRelease_INT")
        p.id(&u.destructCoin, "#destructCoin_ID")
        p.id(&u.destructCoinOnGroupKill, "#destructCoinOnGroupKill_ID")
        p.bool(&u.destructDestroyChildren, "#destructDestroyChildren_BOOL")
        p.bool(&u.destructDeleteChildren, "#destructDeleteChildren_BOOL")
        p.bool(&u.destructDrawToTerrain, "#destructDrawToTerrain_BOOL")
        p.bool(&u.destructReleaseRandomBonus, "#destructReleaseRandomBonus_BOOL")
        p.bool(&u.destructCreateObstacle, "#destructCreateObstacle_BOOL")
        if u.destructDestroyChildren && !u.destructDeleteChildren {
            notes.append("\n    FYI: A Unit Definition wishes to destroy Children on destruction, but NOT delete "
                         + "willing Children on deletion.")
        }
        p.float(&u.shieldsMaxAmount, "#shields_MaxAmount_FLOAT")
        p.float(&u.shieldsLevelIncrement, "#shields_LevelIncrement_FLOAT")
        p.float(&u.shieldsBaseAmount, "#shields_BaseAmount_FLOAT")
        p.int(&u.score, "#score_INT")
        p.float(&u.damage, "#damage_FLOAT")
        p.int(&u.initialVisibilityPercent, "#initialVisibilityPercent_INT")
        p.int(&u.initialScalePercent, "#initialScalePercent_INT")
        p.int(&u.initialScalePercentTolerance, "#initialScalePercentTolerance_INT")
        p.id(&u.drawLayer, "#drawLayer_ID")
        p.str(&u.entryNotice, "#entryNotice_STR", maxLength: 0x100)
        p.int(&u.entryNoticeDelay, "#entryNoticeDelay_INT")
        p.bool(&u.displayNoticeOnceOnly, "#displayNoticeOnceOnly_BOOL")
        p.sound(&u.entryNoticeSound, "entryNoticeSound")
        p.id(&u.hitParticles, "#hitParticles_ID")
        p.bool(&u.hitParticleDoCircularBurst, "#hitParticleDoCircularBurst_BOOL")
        p.color(&u.hitParticlesColor, "#hitParticlesColor_COLOR")
        p.sound(&u.shieldSound, "shieldSound")
        p.sound(&u.unshieldedSound, "unshieldedSound")
        p.id(&u.deletionSpawn, "#deletionSpawn_ID")
        p.float(&u.xOffsetMin, "#xOffsetMin_FLOAT")
        p.float(&u.xOffsetMax, "#xOffsetMax_FLOAT")
        p.float(&u.yOffsetMin, "#yOffsetMin_FLOAT")
        p.float(&u.yOffsetMax, "#yOffsetMax_FLOAT")
        p.int(&u.initialHeading, "#initialHeading_INT")
        p.int(&u.initialHeadingTolerance, "#initialHeadingTolerance_INT")
        p.bool(&u.useOwnerHeading, "#useOwnerHeading_BOOL")
        p.float(&u.initialSpeedMin, "#initialSpeedMin_FLOAT")
        p.float(&u.initialSpeedMax, "#initialSpeedMax_FLOAT")
        p.bool(&u.doBurst, "#doBurst_BOOL")
        p.bool(&u.doImplode, "#doImplode_BOOL")
        p.bool(&u.isGroundBased, "#isGroundBased_BOOL")
        p.bool(&u.doDeathSpawnOnAnyMedia, "#doDeathSpawnOnAnyMedia_BOOL")
        p.id(&u.mediaImpactSize, "#mediaImpactSize_ID")
        // Read into an uninitialised stack local and then stored (P@10040808, `stw r0,0x14` @10040818):
        // a miss leaves garbage in the original (already the fatal load error); this port stores 0.
        u.numStates = p.count("#numStates_INT")

        // Unit fix-ups placed by the listing: the preview face check follows its read (P@100400ec), the
        // shields clamp follows shields_BaseAmount (100403a8). Moved here; no later read depends on them.
        DefinitionReader.checkSprite(&u.editorPreviewSpriteFace, spriteExists, notes: &notes)
        if u.shieldsMaxAmount < u.shieldsBaseAmount { u.shieldsMaxAmount = u.shieldsBaseAmount }

        var s = 0
        while s < Int(u.numStates) {
            var state = UnitState.defaults(index: s)
            UnitState.parse(&state, &p, spriteExists: spriteExists, notes: &notes)
            if state.hasOwnerBool { u.hasOwnerLinkedState = true }
            u.states.append(state)
            s += 1
        }

        if (u.destructDestroyChildren || u.destructDeleteChildren) && !u.states.contains(where: { !$0.spawnSets.isEmpty }) {
            notes.append("\n    FYI: A Unit Definition wishes to delete and/or destroy willing Children, but does not spawn.")
        }

        u.layer = u.isGroundBased ? ground : air
        var errors = p.errors
        if !errors.isEmpty {
            u.hasDataError = true
            errors.append("A Unit Definition file contained incorrect or missing data.")
        }
        if u.numStates < 0 || u.numStates > Int32(maxNumStates) {
            errors.append("\nERROR:  incorrect number of states (\(u.numStates)) in Unit Def \"\(tagName)\"")
            errors.append("unitPtr->fileData.numStatesUsed > 0 and unitPtr->fileData.numStatesUsed <= kG_UnitDef_MaxNumStates")
        }
        u.notes = notes
        return (u, errors)
    }
}

/// One unit state (sizeof 0x5e0; unit-def-struct.md §4), fields in reader call order (`FUN_10040920`).
/// Defaults `FUN_1003e3d0`; state 0's name defaults to "State 1".
public struct UnitState: Sendable, Equatable {
    public static let ruleSlots = 5

    /// `#stateName_STR` (+0x49c)
    public var stateName: String = ""
    /// `#stateOnRange_FLOAT` (+0x44c)
    public var stateOnRange: Float = 0
    /// `#stateOnRangeChangeTo_STR` (+0x55c)
    public var stateOnRangeChangeTo: String = ""
    /// `#stateOnHitChangeTo_STR` (+0x59c)
    public var stateOnHitChangeTo: String = ""
    /// `#stateOnHitChangeStateDelay_INT` (+0x3b8)
    public var stateOnHitChangeStateDelay: Int32 = 0
    /// `#stateOnTimerMin_INT` (+0x3ac)
    public var stateOnTimerMin: Int32 = 0
    /// `#stateOnTimerMax_INT` (+0x3b0)
    public var stateOnTimerMax: Int32 = 0
    /// `#stateOnTimerChangeTo_STR` (+0x4dc)
    public var stateOnTimerChangeTo: String = ""
    /// `#stateOnCounter_INT` (+0x3b4)
    public var stateOnCounter: Int32 = 0
    /// `#stateOnCounterChangeTo_STR` (+0x51c)
    public var stateOnCounterChangeTo: String = ""
    /// `#stateSpriteFace_ID` (+0x304)
    public var stateSpriteFace: FourCC = .none
    /// `#stateSpriteFrameMin_INT` (+0x30c)
    public var stateSpriteFrameMin: Int32 = 0
    /// `#stateSpriteFrameMax_INT` (+0x310)
    public var stateSpriteFrameMax: Int32 = 0
    /// `#stateUseParentDirection_BOOL` (+0x324)
    public var stateUseParentDirection: Bool = false
    /// `#stateRequiredVisibilityPercent_INT` (+0x3c4)
    public var stateRequiredVisibilityPercent: Int32 = 100
    /// `#stateVisibilityDeltaPercent_INT` (+0x3c8)
    public var stateVisibilityDeltaPercent: Int32 = 0
    /// `#stateRequiredScalePercent_INT` (+0x3bc)
    public var stateRequiredScalePercent: Int32 = 100
    /// `#stateScaleDeltaPercent_INT` (+0x3c0)
    public var stateScaleDeltaPercent: Int32 = 0
    /// `#stateTintPercent_INT` (+0x3cc)
    public var stateTintPercent: Int32 = 0
    /// `#stateTintDeltaPercent_INT` (+0x3d0)
    public var stateTintDeltaPercent: Int32 = 0
    /// `#stateTintColor_COLOR` (+0x332)
    public var stateTintColor: UInt16 = 0
    /// `#stateDoColorise_BOOL` (+0x34d)
    public var stateDoColorise: Bool = false
    /// `#stateNumDirections_INT` (+0x308)
    public var stateNumDirections: Int32 = 0
    /// `#stateFramesPerDirection_INT` (+0x314)
    public var stateFramesPerDirection: Int32 = 0
    /// `#stateFrameDelay_INT` (+0x318)
    public var stateFrameDelay: Int32 = 0
    /// `#stateFrameDelta_INT` (+0x31c)
    public var stateFrameDelta: Int32 = 0
    /// `#stateDoAnimateBackwards_BOOL` (+0x300)
    public var stateDoAnimateBackwards: Bool = false
    /// `#stateDoLoopAnimation_BOOL` (+0x301)
    public var stateDoLoopAnimation: Bool = false
    /// `#stateContinuousFrameRandomisation_BOOL` (+0x302)
    public var stateContinuousFrameRandomisation: Bool = false
    /// `#stateDoRotateToTarget_BOOL` (+0x303)
    public var stateDoRotateToTarget: Bool = false
    /// `#stateMaxSpeed_FLOAT` (+0x458)
    public var stateMaxSpeed: Float = 0
    /// `#stateDelta_FLOAT` (+0x45c)
    public var stateDelta: Float = 0
    /// `#stateHoldMaxSpeed_FLOAT` (+0x450)
    public var stateHoldMaxSpeed: Float = 0
    /// `#stateHoldDelta_FLOAT` (+0x454)
    public var stateHoldDelta: Float = 0
    /// `#stateFlee_ID` (+0x320)
    public var stateFlee: FourCC = .none
    /// `#stateFleeSpeed_FLOAT` (+0x460)
    public var stateFleeSpeed: Float = 0
    /// `#stateFleeDelta_FLOAT` (+0x464)
    public var stateFleeDelta: Float = 0
    /// `#stateEntrySound_ID` + 5 (+0x000, sound record 0x18)
    public var stateEntrySound: SoundRecord = SoundRecord()
    /// `#stateSoundLoopDelay_INT` (+0x01c)
    public var stateSoundLoopDelay: Int32 = 0
    /// `#stateSoundMaxNumToPlay_INT` (+0x020)
    public var stateSoundMaxNumToPlay: Int32 = 1
    /// `#stateSoundLoop_BOOL` (+0x018)
    public var stateSoundLoop: Bool = false
    /// `#stateSoundAllowOnlyOneInstance_BOOL` (+0x019)
    public var stateSoundAllowOnlyOneInstance: Bool = false
    /// `#stateSoundRepeatOnStateChange_BOOL` (+0x01a)
    public var stateSoundRepeatOnStateChange: Bool = false
    /// `#invulnerableUntilAllChildrenDestroyed_BOOL` (+0x325)
    public var invulnerableUntilAllChildrenDestroyed: Bool = false
    /// `#invulnerableUntilOwnerDestroyed_BOOL` (+0x326)
    public var invulnerableUntilOwnerDestroyed: Bool = false
    /// `#useOwnersVisibility_BOOL` (+0x327)
    public var useOwnersVisibility: Bool = false
    /// `#useOwnersScale_BOOL` (+0x328)
    public var useOwnersScale: Bool = false
    /// `#canBeDestroyedOnOwnerDestruction_BOOL` (+0x329)
    public var canBeDestroyedOnOwnerDestruction: Bool = false
    /// `#canBeDeletedOnOwnerDeletion_BOOL` (+0x32a)
    public var canBeDeletedOnOwnerDeletion: Bool = false
    /// `#passHitsToOwner_BOOL` (+0x32b)
    public var passHitsToOwner: Bool = false
    /// `#visuallyReflectOwnerHits_BOOL` (+0x32c)
    public var visuallyReflectOwnerHits: Bool = false
    /// `#destroyOwnerOnDestruction_BOOL` (+0x32d)
    public var destroyOwnerOnDestruction: Bool = false
    /// `#collision_Spawn_ID` (+0x2e0)
    public var collisionSpawn: FourCC = .none
    /// `#collision_RepeatSpawns_BOOL` (+0x2e4)
    public var collisionRepeatSpawns: Bool = false
    /// `#collision_SpawnDelay_INT` (+0x2e8)
    public var collisionSpawnDelay: Int32 = 0
    /// `#state_MotionBlur_Required_BOOL` (+0x2ec)
    public var stateMotionBlurRequired: Bool = false
    /// `#state_MotionBlur_AllowGlowDrawing_BOOL` (+0x2ed)
    public var stateMotionBlurAllowGlowDrawing: Bool = false
    /// `#state_MotionBlur_MinTimeBetweenBlurs_INT` (+0x2f0)
    public var stateMotionBlurMinTimeBetweenBlurs: Int32 = 0
    /// `#state_MotionBlur_MaxTimeBetweenBlurs_INT` (+0x2f4)
    public var stateMotionBlurMaxTimeBetweenBlurs: Int32 = 0
    /// `#state_MotionBlur_InitialVisibilityPercent_FLOAT` (+0x2f8)
    public var stateMotionBlurInitialVisibilityPercent: Float = 0
    /// `#state_MotionBlur_VisibilityDeltaPercent_FLOAT` (+0x2fc)
    public var stateMotionBlurVisibilityDeltaPercent: Float = 0
    /// `#stateParticles_ID` (+0x2d0)
    public var stateParticles: FourCC = .none
    /// `#stateParticlesColor_COLOR` (+0x2d4)
    public var stateParticlesColor: UInt16 = 0
    /// `#stateParticlesRepeat_BOOL` (+0x2d6)
    public var stateParticlesRepeat: Bool = false
    /// `#stateParticles_RepeatDelay_INT` (+0x2d8)
    public var stateParticlesRepeatDelay: Int32 = 0
    /// `#stateParticles_MaxNumBursts_INT` (+0x2dc)
    public var stateParticlesMaxNumBursts: Int32 = 0
    /// `#statePauseVerticalScrolling_BOOL` (+0x346)
    public var statePauseVerticalScrolling: Bool = false
    /// `#stateCollides_BOOL` (+0x347)
    public var stateCollides: Bool = false
    /// `#stateInvulnerable_ShieldsDoNotDepleteOnCollision_BOOL` (+0x348)
    public var stateInvulnerableShieldsDoNotDepleteOnCollision: Bool = false
    /// `#statePickup_DoNotChangeAppearanceOnStateChange_BOOL` (+0x357)
    public var statePickupDoNotChangeAppearanceOnStateChange: Bool = false
    /// `#stateHunts_BOOL` (+0x349)
    public var stateHunts: Bool = false
    /// `#stateCyclicMotion_BOOL` (+0x34a)
    public var stateCyclicMotion: Bool = false
    /// `#stateHoldPositionToTarget_BOOL` (+0x34c)
    public var stateHoldPositionToTarget: Bool = false
    /// `#stateReverseDirectionOnReaction_BOOL` (+0x34b)
    public var stateReverseDirectionOnReaction: Bool = false
    /// `#stateIsTargetable_BOOL` (+0x34e)
    public var stateIsTargetable: Bool = false
    /// `#stateCollidesWithPlayers_BOOL` (+0x34f)
    public var stateCollidesWithPlayers: Bool = false
    /// `#stateLockToOwnerLoc_BOOL` (+0x32e)
    public var stateLockToOwnerLoc: Bool = false
    /// `#stateLinkToOwnerLoc_BOOL` (+0x32f)
    public var stateLinkToOwnerLoc: Bool = false
    /// `#stateOrbitOwner_BOOL` (+0x330)
    public var stateOrbitOwner: Bool = false
    /// `#stateDeleteOnNoActivePlayers_BOOL` (+0x350)
    public var stateDeleteOnNoActivePlayers: Bool = false
    /// `#stateDestructOnNoActivePlayers_BOOL` (+0x351)
    public var stateDestructOnNoActivePlayers: Bool = false
    /// `#stateDestructIfVerticalScrollingNotPaused_BOOL` (+0x352)
    public var stateDestructIfVerticalScrollingNotPaused: Bool = false
    /// `#stateDrawToTerrain_BOOL` (+0x353)
    public var stateDrawToTerrain: Bool = false
    /// `#stateDoNotGlowOnCollision_BOOL` (+0x354)
    public var stateDoNotGlowOnCollision: Bool = false
    /// `#stateUseThisStateOnShieldDepletion_BOOL` (+0x356)
    public var stateUseThisStateOnShieldDepletion: Bool = false
    /// `#stateUseThisStateOnWeaponPowerupRelease_BOOL` (+0x355)
    public var stateUseThisStateOnWeaponPowerupRelease: Bool = false
    /// `stateNumSpawnSets_INT` (read after `collision_SpawnDelay`, key without `#`; not stored by the
    /// original — the list length is the count).
    public var spawnSets: [SpawnSet] = []
    /// `#stateNumRules_INT` (stack local in the original, not stored).
    public var numRules: Int32 = 0
    /// +0x024: the number of rules read whose unit ≠ `none` (`10041788`).
    public var activeRuleCount: Int32 = 0
    /// +0x028: exactly 5 slots (§5).
    public var rules: [UnitRule] = Array(repeating: UnitRule(), count: UnitState.ruleSlots)

    public init() {}

    /// The state defaults for slot `index` ("State 1" for slot 0, `D@1003e390`).
    public static func defaults(index: Int) -> UnitState {
        var s = UnitState()
        if index == 0 { s.stateName = "State 1" }
        return s
    }

    /// Any owner-linked bool (+0x324…+0x330) set — the condition for unit +0x11.
    var hasOwnerBool: Bool {
        stateUseParentDirection || invulnerableUntilAllChildrenDestroyed || invulnerableUntilOwnerDestroyed
            || useOwnersVisibility || useOwnersScale || canBeDestroyedOnOwnerDestruction
            || canBeDeletedOnOwnerDeletion || passHitsToOwner || visuallyReflectOwnerHits
            || destroyOwnerOnDestruction || stateLockToOwnerLoc || stateLinkToOwnerLoc || stateOrbitOwner
    }

    static func parse(_ s: inout UnitState, _ p: inout DefinitionReader, spriteExists: (FourCC) -> Bool,
                      notes: inout [String]) {
        p.str(&s.stateName, "#stateName_STR", maxLength: 0x40)
        p.float(&s.stateOnRange, "#stateOnRange_FLOAT")
        p.str(&s.stateOnRangeChangeTo, "#stateOnRangeChangeTo_STR", maxLength: 0x40)
        p.str(&s.stateOnHitChangeTo, "#stateOnHitChangeTo_STR", maxLength: 0x40)
        p.int(&s.stateOnHitChangeStateDelay, "#stateOnHitChangeStateDelay_INT")
        p.int(&s.stateOnTimerMin, "#stateOnTimerMin_INT")
        p.int(&s.stateOnTimerMax, "#stateOnTimerMax_INT")
        p.str(&s.stateOnTimerChangeTo, "#stateOnTimerChangeTo_STR", maxLength: 0x40)
        // 10040a18 (before the ChangeTo read in the original): max < min → max = min;
        // 10040a48–10040aa0: a running timer with no target → note, both 0.
        if s.stateOnTimerMax < s.stateOnTimerMin { s.stateOnTimerMax = s.stateOnTimerMin }
        if s.stateOnTimerMax > 0 && s.stateOnTimerChangeTo.isEmpty {
            notes.append("\n    NOTE: A Unit Definition has an unused State Change Timer.")
            s.stateOnTimerMin = 0
            s.stateOnTimerMax = 0
        }
        p.int(&s.stateOnCounter, "#stateOnCounter_INT")
        p.str(&s.stateOnCounterChangeTo, "#stateOnCounterChangeTo_STR", maxLength: 0x40)
        p.id(&s.stateSpriteFace, "#stateSpriteFace_ID")
        DefinitionReader.checkSprite(&s.stateSpriteFace, spriteExists, notes: &notes)
        p.int(&s.stateSpriteFrameMin, "#stateSpriteFrameMin_INT")
        p.int(&s.stateSpriteFrameMax, "#stateSpriteFrameMax_INT")
        p.bool(&s.stateUseParentDirection, "#stateUseParentDirection_BOOL")
        p.int(&s.stateRequiredVisibilityPercent, "#stateRequiredVisibilityPercent_INT")
        p.int(&s.stateVisibilityDeltaPercent, "#stateVisibilityDeltaPercent_INT")
        p.int(&s.stateRequiredScalePercent, "#stateRequiredScalePercent_INT")
        p.int(&s.stateScaleDeltaPercent, "#stateScaleDeltaPercent_INT")
        p.int(&s.stateTintPercent, "#stateTintPercent_INT")
        p.int(&s.stateTintDeltaPercent, "#stateTintDeltaPercent_INT")
        p.color(&s.stateTintColor, "#stateTintColor_COLOR")
        p.bool(&s.stateDoColorise, "#stateDoColorise_BOOL")
        p.int(&s.stateNumDirections, "#stateNumDirections_INT")
        p.int(&s.stateFramesPerDirection, "#stateFramesPerDirection_INT")
        p.int(&s.stateFrameDelay, "#stateFrameDelay_INT")
        p.int(&s.stateFrameDelta, "#stateFrameDelta_INT")
        p.bool(&s.stateDoAnimateBackwards, "#stateDoAnimateBackwards_BOOL")
        p.bool(&s.stateDoLoopAnimation, "#stateDoLoopAnimation_BOOL")
        p.bool(&s.stateContinuousFrameRandomisation, "#stateContinuousFrameRandomisation_BOOL")
        p.bool(&s.stateDoRotateToTarget, "#stateDoRotateToTarget_BOOL")
        p.float(&s.stateMaxSpeed, "#stateMaxSpeed_FLOAT")
        p.float(&s.stateDelta, "#stateDelta_FLOAT")
        p.float(&s.stateHoldMaxSpeed, "#stateHoldMaxSpeed_FLOAT")
        p.float(&s.stateHoldDelta, "#stateHoldDelta_FLOAT")
        p.id(&s.stateFlee, "#stateFlee_ID")
        p.float(&s.stateFleeSpeed, "#stateFleeSpeed_FLOAT")
        p.float(&s.stateFleeDelta, "#stateFleeDelta_FLOAT")
        p.sound(&s.stateEntrySound, "stateEntrySound")
        p.int(&s.stateSoundLoopDelay, "#stateSoundLoopDelay_INT")
        p.int(&s.stateSoundMaxNumToPlay, "#stateSoundMaxNumToPlay_INT")
        p.bool(&s.stateSoundLoop, "#stateSoundLoop_BOOL")
        p.bool(&s.stateSoundAllowOnlyOneInstance, "#stateSoundAllowOnlyOneInstance_BOOL")
        p.bool(&s.stateSoundRepeatOnStateChange, "#stateSoundRepeatOnStateChange_BOOL")
        p.bool(&s.invulnerableUntilAllChildrenDestroyed, "#invulnerableUntilAllChildrenDestroyed_BOOL")
        p.bool(&s.invulnerableUntilOwnerDestroyed, "#invulnerableUntilOwnerDestroyed_BOOL")
        p.bool(&s.useOwnersVisibility, "#useOwnersVisibility_BOOL")
        p.bool(&s.useOwnersScale, "#useOwnersScale_BOOL")
        p.bool(&s.canBeDestroyedOnOwnerDestruction, "#canBeDestroyedOnOwnerDestruction_BOOL")
        p.bool(&s.canBeDeletedOnOwnerDeletion, "#canBeDeletedOnOwnerDeletion_BOOL")
        p.bool(&s.passHitsToOwner, "#passHitsToOwner_BOOL")
        p.bool(&s.visuallyReflectOwnerHits, "#visuallyReflectOwnerHits_BOOL")
        p.bool(&s.destroyOwnerOnDestruction, "#destroyOwnerOnDestruction_BOOL")
        p.id(&s.collisionSpawn, "#collision_Spawn_ID")
        p.bool(&s.collisionRepeatSpawns, "#collision_RepeatSpawns_BOOL")
        p.int(&s.collisionSpawnDelay, "#collision_SpawnDelay_INT")
        let numSpawnSets = p.count("stateNumSpawnSets_INT")
        var k: Int32 = 0
        while k < numSpawnSets {
            var set = SpawnSet()
            SpawnSet.parse(&set, &p)
            if set.stateSpawnSetSpawn == .none {
                notes.append("\n    NOTE: A Unit Spawn Set has an unused Unit ID.  Suggest you delete the Spawn Set.")
            }
            s.spawnSets.append(set)
            k += 1
        }
        p.bool(&s.stateMotionBlurRequired, "#state_MotionBlur_Required_BOOL")
        p.bool(&s.stateMotionBlurAllowGlowDrawing, "#state_MotionBlur_AllowGlowDrawing_BOOL")
        p.int(&s.stateMotionBlurMinTimeBetweenBlurs, "#state_MotionBlur_MinTimeBetweenBlurs_INT")
        p.int(&s.stateMotionBlurMaxTimeBetweenBlurs, "#state_MotionBlur_MaxTimeBetweenBlurs_INT")
        p.float(&s.stateMotionBlurInitialVisibilityPercent, "#state_MotionBlur_InitialVisibilityPercent_FLOAT")
        p.float(&s.stateMotionBlurVisibilityDeltaPercent, "#state_MotionBlur_VisibilityDeltaPercent_FLOAT")
        p.id(&s.stateParticles, "#stateParticles_ID")
        p.color(&s.stateParticlesColor, "#stateParticlesColor_COLOR")
        p.bool(&s.stateParticlesRepeat, "#stateParticlesRepeat_BOOL")
        p.int(&s.stateParticlesRepeatDelay, "#stateParticles_RepeatDelay_INT")
        p.int(&s.stateParticlesMaxNumBursts, "#stateParticles_MaxNumBursts_INT")
        p.bool(&s.statePauseVerticalScrolling, "#statePauseVerticalScrolling_BOOL")
        p.bool(&s.stateCollides, "#stateCollides_BOOL")
        p.bool(&s.stateInvulnerableShieldsDoNotDepleteOnCollision, "#stateInvulnerable_ShieldsDoNotDepleteOnCollision_BOOL")
        p.bool(&s.statePickupDoNotChangeAppearanceOnStateChange, "#statePickup_DoNotChangeAppearanceOnStateChange_BOOL")
        p.bool(&s.stateHunts, "#stateHunts_BOOL")
        p.bool(&s.stateCyclicMotion, "#stateCyclicMotion_BOOL")
        p.bool(&s.stateHoldPositionToTarget, "#stateHoldPositionToTarget_BOOL")
        p.bool(&s.stateReverseDirectionOnReaction, "#stateReverseDirectionOnReaction_BOOL")
        p.bool(&s.stateIsTargetable, "#stateIsTargetable_BOOL")
        p.bool(&s.stateCollidesWithPlayers, "#stateCollidesWithPlayers_BOOL")
        p.bool(&s.stateLockToOwnerLoc, "#stateLockToOwnerLoc_BOOL")
        p.bool(&s.stateLinkToOwnerLoc, "#stateLinkToOwnerLoc_BOOL")
        p.bool(&s.stateOrbitOwner, "#stateOrbitOwner_BOOL")
        p.bool(&s.stateDeleteOnNoActivePlayers, "#stateDeleteOnNoActivePlayers_BOOL")
        p.bool(&s.stateDestructOnNoActivePlayers, "#stateDestructOnNoActivePlayers_BOOL")
        p.bool(&s.stateDestructIfVerticalScrollingNotPaused, "#stateDestructIfVerticalScrollingNotPaused_BOOL")
        p.bool(&s.stateDrawToTerrain, "#stateDrawToTerrain_BOOL")
        p.bool(&s.stateDoNotGlowOnCollision, "#stateDoNotGlowOnCollision_BOOL")
        p.bool(&s.stateUseThisStateOnShieldDepletion, "#stateUseThisStateOnShieldDepletion_BOOL")
        p.bool(&s.stateUseThisStateOnWeaponPowerupRelease, "#stateUseThisStateOnWeaponPowerupRelease_BOOL")
        s.numRules = p.count("#stateNumRules_INT")
        var r: Int32 = 0
        while r < s.numRules {
            var rule = UnitRule()
            UnitRule.parse(&rule, &p)
            if rule.stateRuleUnit != .none { s.activeRuleCount += 1 }
            if Int(r) < ruleSlots { s.rules[Int(r)] = rule }
            r += 1
        }
        if s.numRules > Int32(ruleSlots) {
            notes.append("numRules \(s.numRules) > 5: rules 5… overrun state+0x2d0 in the original (not replicated)")
        }
    }
}

/// One rule slot (sizeof 0x88; unit-def-struct.md §5). File order per rule: Name (read into a stack
/// buffer and discarded), Unit, Range, Condition, Action (the Action key is stored without `#`).
public struct UnitRule: Sendable, Equatable {
    /// `#stateRuleUnit_ID` (+0x00)
    public var stateRuleUnit: FourCC = .none
    /// `#stateRuleRange_INT` (+0x84)
    public var stateRuleRange: Int32 = 0
    /// `#stateRuleCondition_STR` (+0x04, ≤ 0x40)
    public var stateRuleCondition: String = ""
    /// `stateRuleAction_STR` (+0x44, ≤ 0x40) — the target state name
    public var stateRuleAction: String = ""

    public init() {}

    static func parse(_ r: inout UnitRule, _ p: inout DefinitionReader) {
        var discarded = ""
        p.str(&discarded, "#stateRuleName_STR", maxLength: 0x40)
        p.id(&r.stateRuleUnit, "#stateRuleUnit_ID")
        p.int(&r.stateRuleRange, "#stateRuleRange_INT")
        p.str(&r.stateRuleCondition, "#stateRuleCondition_STR", maxLength: 0x40)
        p.str(&r.stateRuleAction, "stateRuleAction_STR", maxLength: 0x40)
    }
}

/// One spawn set (sizeof 0x5c; unit-def-struct.md §6), fields in reader call order. Defaults
/// `FUN_1003e490` (volley 1/1). A spawn set whose spawn is `none` is logged and kept.
public struct SpawnSet: Sendable, Equatable {
    /// `#stateSpawnSetName_STR` (+0x000)
    public var stateSpawnSetName: String = ""
    /// `#stateSpawnSetSpawn_ID` (+0x020)
    public var stateSpawnSetSpawn: FourCC = .none
    /// `#stateSpawnSetXOffset_INT` (+0x024)
    public var stateSpawnSetXOffset: Int32 = 0
    /// `#stateSpawnSetYOffset_INT` (+0x028)
    public var stateSpawnSetYOffset: Int32 = 0
    /// `#stateSpawnSetAdjustOffsetForUnitRotation_BOOL` (+0x044)
    public var stateSpawnSetAdjustOffsetForUnitRotation: Bool = false
    /// `#stateSpawnSet_AbsoluteCoordinates_BOOL` (+0x045)
    public var stateSpawnSetAbsoluteCoordinates: Bool = false
    /// `#stateSpawnSetRateMin_INT` (+0x02c)
    public var stateSpawnSetRateMin: Int32 = 0
    /// `#stateSpawnSetRateMax_INT` (+0x030)
    public var stateSpawnSetRateMax: Int32 = 0
    /// `#stateSpawnSetNumInVolleyMin_INT` (+0x034)
    public var stateSpawnSetNumInVolleyMin: Int32 = 1
    /// `#stateSpawnSetNumInVolleyMax_INT` (+0x038)
    public var stateSpawnSetNumInVolleyMax: Int32 = 1
    /// `#stateSpawnSetDelayBetweenEntitiesMin_INT` (+0x03c)
    public var stateSpawnSetDelayBetweenEntitiesMin: Int32 = 0
    /// `#stateSpawnSetDelayBetweenEntitiesMax_INT` (+0x040)
    public var stateSpawnSetDelayBetweenEntitiesMax: Int32 = 0
    /// `#stateSpawnSetRepeatSpawns_BOOL` (+0x046)
    public var stateSpawnSetRepeatSpawns: Bool = false
    /// `#stateSpawnSetDon'tSpawnOffscreen_BOOL` (+0x047)
    public var stateSpawnSetDontSpawnOffscreen: Bool = false
    /// `#stateSpawnSetPauseAnyRotationWhileSpawning_BOOL` (+0x048)
    public var stateSpawnSetPauseAnyRotationWhileSpawning: Bool = false
    /// `#stateSpawnSetTimeToPauseRotationAfterSpawning_INT` (+0x04c)
    public var stateSpawnSetTimeToPauseRotationAfterSpawning: Int32 = 0
    /// `#stateSpawnSetSpawnIfFleeing_BOOL` (+0x050)
    public var stateSpawnSetSpawnIfFleeing: Bool = false
    /// `#stateSpawnSet_StationaryOption_BOOL` (+0x058)
    public var stateSpawnSetStationaryOption: Bool = false
    /// `#stateSpawnSet_TerrainEffectsOption_BOOL` (+0x059)
    public var stateSpawnSetTerrainEffectsOption: Bool = false
    /// `#stateSpawnSetSetHeading_BOOL` (+0x051)
    public var stateSpawnSetSetHeading: Bool = false
    /// `#stateSpawnSetHeadingDegrees_INT` (+0x054)
    public var stateSpawnSetHeadingDegrees: Int32 = 0

    public init() {}

    static func parse(_ set: inout SpawnSet, _ p: inout DefinitionReader) {
        p.str(&set.stateSpawnSetName, "#stateSpawnSetName_STR", maxLength: 0x20)
        p.id(&set.stateSpawnSetSpawn, "#stateSpawnSetSpawn_ID")
        p.int(&set.stateSpawnSetXOffset, "#stateSpawnSetXOffset_INT")
        p.int(&set.stateSpawnSetYOffset, "#stateSpawnSetYOffset_INT")
        p.bool(&set.stateSpawnSetAdjustOffsetForUnitRotation, "#stateSpawnSetAdjustOffsetForUnitRotation_BOOL")
        p.bool(&set.stateSpawnSetAbsoluteCoordinates, "#stateSpawnSet_AbsoluteCoordinates_BOOL")
        p.int(&set.stateSpawnSetRateMin, "#stateSpawnSetRateMin_INT")
        p.int(&set.stateSpawnSetRateMax, "#stateSpawnSetRateMax_INT")
        p.int(&set.stateSpawnSetNumInVolleyMin, "#stateSpawnSetNumInVolleyMin_INT")
        p.int(&set.stateSpawnSetNumInVolleyMax, "#stateSpawnSetNumInVolleyMax_INT")
        p.int(&set.stateSpawnSetDelayBetweenEntitiesMin, "#stateSpawnSetDelayBetweenEntitiesMin_INT")
        p.int(&set.stateSpawnSetDelayBetweenEntitiesMax, "#stateSpawnSetDelayBetweenEntitiesMax_INT")
        p.bool(&set.stateSpawnSetRepeatSpawns, "#stateSpawnSetRepeatSpawns_BOOL")
        p.bool(&set.stateSpawnSetDontSpawnOffscreen, "#stateSpawnSetDon'tSpawnOffscreen_BOOL")
        p.bool(&set.stateSpawnSetPauseAnyRotationWhileSpawning, "#stateSpawnSetPauseAnyRotationWhileSpawning_BOOL")
        p.int(&set.stateSpawnSetTimeToPauseRotationAfterSpawning, "#stateSpawnSetTimeToPauseRotationAfterSpawning_INT")
        p.bool(&set.stateSpawnSetSpawnIfFleeing, "#stateSpawnSetSpawnIfFleeing_BOOL")
        p.bool(&set.stateSpawnSetStationaryOption, "#stateSpawnSet_StationaryOption_BOOL")
        p.bool(&set.stateSpawnSetTerrainEffectsOption, "#stateSpawnSet_TerrainEffectsOption_BOOL")
        p.bool(&set.stateSpawnSetSetHeading, "#stateSpawnSetSetHeading_BOOL")
        p.int(&set.stateSpawnSetHeadingDegrees, "#stateSpawnSetHeadingDegrees_INT")
    }
}
