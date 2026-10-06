import Foundation
import HectorResources

/// A weapon definition (`wede`, G_WeaponDefinitions.cc; bank weapons-projectiles.md §1, data-tags.md
/// §6; sizeof 0x208), parsed as `FUN_1002b8e0` → defaults `FUN_1002b2a0` → `FUN_1002ba00`. Fields in
/// reader call order (naming as `UnitDefinition`). Defaults: the ten IDs at +0x130 +0x144 +0x148
/// +0x168 +0x170 +0x180 +0x1cc +0x1dc +0x1ec +0x1fc are `none`, the selection sound is
/// {none, 100, 100, 100, 1.0, 1.0}; everything else — including `type` and `default` — is zero
/// (`FourCC(rawValue: 0)`).
public struct WeaponDefinition: Sendable, Equatable {
    public static let magic: UInt32 = 0x4996_02d2
    public static let zeroID = FourCC(rawValue: 0)

    /// One spawn record (0x34 bytes, `FUN_1004d320(0x34)`, defaults `FUN_1002c490`).
    public struct Spawn: Sendable, Equatable {
        /// `#spawn_Name_STR` (+0x00, ≤ 0x20)
        public var name: String = ""
        /// `#spawn_Unit_ID` (+0x20)
        public var unit: FourCC = .none
        /// `#spawn_XLoc_INT` (+0x24)
        public var xLoc: Int32 = 0
        /// `#spawn_YLoc_INT` (+0x28)
        public var yLoc: Int32 = 0
        /// `#spawn_SetHeading_BOOL` (+0x2c)
        public var setHeading = false
        /// `#spawn_Angle_INT` (+0x30), brought into [0, 360) at parse: +360 if negative, −360 if > 359,
        /// then 0 if still out of range.
        public var angle: Int32 = 0

        public init() {}
    }

    /// A power-up block: `#powerup_Air_*` (+0x1c8…+0x1e4) or `#powerup_Ground_*` (+0x1e8…+0x204), keys
    /// in this order. The ground block's `OverloadTime` (+0x1f8) IS parsed (`addi r6,r31,0x1f8` before
    /// the INT reader at PEF data-fork offset 0x2ea6c); the bank's "no reader" for it is the run-time
    /// consumer column (weapons-projectiles.md §1.2).
    public struct PowerUp: Sendable, Equatable {
        public var timeUntilActivation: Int32 = 0
        public var activationSpawn: FourCC = .none
        public var timeBetweenPowerLevelChanges: Int32 = 0
        public var maxPowerLevel: Int32 = 0
        public var overloadTime: Int32 = 0
        public var releaseSpawn: FourCC = .none
        public var timeBetweenReleaseSpawns: Int32 = 0
        public var doReleaseOnMaxPowerLevel = false

        public init() {}
    }

    /// +0x004: the wede tag ID.
    public var id: FourCC = .none
    /// `#type_ID` (+0x008): `PEAA` air, `PEAG` ground, `SPEC`
    public var type: FourCC = WeaponDefinition.zeroID
    /// `#default_ID` (+0x00c): `DEAA` / `DEAG` / `none`
    public var `default`: FourCC = WeaponDefinition.zeroID
    /// `#name_STR` (+0x010, ≤ 0x20)
    public var name: String = ""
    /// `#description1_STR` (+0x030, ≤ 0x80)
    public var description1: String = ""
    /// `#description2_STR` (+0x0b0, ≤ 0x80)
    public var description2: String = ""
    /// `#scoreBarPreviewFace_ID` (+0x130; sprite-checked)
    public var scoreBarPreviewFace: FourCC = .none
    /// `#scoreBarPreviewFrame_INT` (+0x134)
    public var scoreBarPreviewFrame: Int32 = 0
    /// `#maxAllowed_INT` (+0x138)
    public var maxAllowed: Int32 = 0
    /// `#minimumLevelAvailable_INT` (+0x13c)
    public var minimumLevelAvailable: Int32 = 0
    /// `#maximumLevelAvailable_INT` (+0x140); a value < 1 becomes 9999 right after the read
    /// (`lwz r0,0x140 · cmpwi r0,0 · bgt · li r0,9999 · stw r0,0x140`, PEF data-fork offset 0x2e244 —
    /// verified for this task; the bank's "`< 1` → 9999" applies to the maximum only).
    public var maximumLevelAvailable: Int32 = 0
    /// `#player1AppearanceFace_ID` (+0x144; sprite-checked)
    public var player1AppearanceFace: FourCC = .none
    /// `#player2AppearanceFace_ID` (+0x148; sprite-checked)
    public var player2AppearanceFace: FourCC = .none
    /// `#playerGlow_COLOR` (+0x14c)
    public var playerGlow: UInt16 = 0
    /// `#selectionSound_*` (+0x150, sound record)
    public var selectionSound = SoundRecord()
    /// `#crosshairFace_ID` (+0x168; sprite-checked)
    public var crosshairFace: FourCC = .none
    /// `#crosshairFrame_INT` (+0x16c)
    public var crosshairFrame: Int32 = 0
    /// `#crosshairLockedFace_ID` (+0x170; sprite-checked)
    public var crosshairLockedFace: FourCC = .none
    /// `#crosshairLockedFrame_INT` (+0x174)
    public var crosshairLockedFrame: Int32 = 0
    /// `#crosshairXOffset_INT` (+0x178)
    public var crosshairXOffset: Int32 = 0
    /// `#crosshairYOffset_INT` (+0x17c)
    public var crosshairYOffset: Int32 = 0
    /// `#crosshairSpawnOnActivation_ID` (+0x180)
    public var crosshairSpawnOnActivation: FourCC = .none
    /// `#numAmmoInPack_INT` (+0x184)
    public var numAmmoInPack: Int32 = 0
    /// `#ammoWarnAtCount_INT` (+0x188)
    public var ammoWarnAtCount: Int32 = 0
    /// `#ammoWarning_STR` (+0x18c, ≤ 0x20)
    public var ammoWarning: String = ""
    /// `#autoRepeat_BOOL` (+0x1ac)
    public var autoRepeat = false
    /// `#delayBetweenLaunches_INT` (+0x1b0)
    public var delayBetweenLaunches: Int32 = 0
    /// `#delayBetweenLoadLaunches_INT` (+0x1b4)
    public var delayBetweenLoadLaunches: Int32 = 0
    /// `#shieldIncrease_INT` (+0x1b8)
    public var shieldIncrease: Int32 = 0
    /// `#livesIncrease_INT` (+0x1bc)
    public var livesIncrease: Int32 = 0
    /// `#invulnerableForTime_INT` (+0x1c0)
    public var invulnerableForTime: Int32 = 0
    /// +0x1c4: the spawn list; `#spawn_NumUnitsToSpawn_INT` records, file order (the count is not stored).
    public var spawns: [Spawn] = []
    /// `#powerup_Air_*` (+0x1c8)
    public var powerupAir = PowerUp()
    /// `#powerup_Ground_*` (+0x1e8)
    public var powerupGround = PowerUp()
    /// Non-fatal log lines (missing sprite resets). Not part of the original's struct.
    public var notes: [String] = []

    public init() {}

    /// Parse one `wede` tag: de-obfuscated only if `#type_ID` is not found in the raw bytes. Strict mode
    /// is ON for `wede` (`FUN_1002b8e0`: `1002b994 li r4,1; bl 0x1002c4d0`), so any non-STR token error is
    /// the original's fatal "A Weapon Definition file contained incorrect or missing data."
    /// (`1002b9bc–1002b9d4`, string `0x100ea3e9`) — reported in `errors` (the keys, then that line), never
    /// thrown. Strict mode is a sticky global (`FUN_1002c4d0` sets it; nothing here clears it); `leve`
    /// neither sets nor checks it.
    public static func parse(id: FourCC, text raw: [UInt8], spriteExists: (FourCC) -> Bool)
        -> (WeaponDefinition, errors: [String]) {
        var p = DefinitionReader(DefinitionReader.plainText(raw, unlessContains: "#type_ID"))
        var w = WeaponDefinition()
        var notes: [String] = []
        w.id = id
        p.id(&w.type, "#type_ID")
        p.id(&w.default, "#default_ID")
        p.str(&w.name, "#name_STR", maxLength: 0x20)
        p.str(&w.description1, "#description1_STR", maxLength: 0x80)
        p.str(&w.description2, "#description2_STR", maxLength: 0x80)
        p.id(&w.scoreBarPreviewFace, "#scoreBarPreviewFace_ID")
        DefinitionReader.checkSprite(&w.scoreBarPreviewFace, spriteExists, notes: &notes)
        p.int(&w.scoreBarPreviewFrame, "#scoreBarPreviewFrame_INT")
        p.int(&w.maxAllowed, "#maxAllowed_INT")
        p.int(&w.minimumLevelAvailable, "#minimumLevelAvailable_INT")
        p.int(&w.maximumLevelAvailable, "#maximumLevelAvailable_INT")
        if w.maximumLevelAvailable <= 0 { w.maximumLevelAvailable = 9999 }
        p.id(&w.player1AppearanceFace, "#player1AppearanceFace_ID")
        DefinitionReader.checkSprite(&w.player1AppearanceFace, spriteExists, notes: &notes)
        p.id(&w.player2AppearanceFace, "#player2AppearanceFace_ID")
        DefinitionReader.checkSprite(&w.player2AppearanceFace, spriteExists, notes: &notes)
        p.color(&w.playerGlow, "#playerGlow_COLOR")
        p.sound(&w.selectionSound, "selectionSound")
        p.id(&w.crosshairFace, "#crosshairFace_ID")
        DefinitionReader.checkSprite(&w.crosshairFace, spriteExists, notes: &notes)
        p.int(&w.crosshairFrame, "#crosshairFrame_INT")
        p.id(&w.crosshairLockedFace, "#crosshairLockedFace_ID")
        DefinitionReader.checkSprite(&w.crosshairLockedFace, spriteExists, notes: &notes)
        p.int(&w.crosshairLockedFrame, "#crosshairLockedFrame_INT")
        p.int(&w.crosshairXOffset, "#crosshairXOffset_INT")
        p.int(&w.crosshairYOffset, "#crosshairYOffset_INT")
        p.id(&w.crosshairSpawnOnActivation, "#crosshairSpawnOnActivation_ID")
        p.int(&w.numAmmoInPack, "#numAmmoInPack_INT")
        p.int(&w.ammoWarnAtCount, "#ammoWarnAtCount_INT")
        p.str(&w.ammoWarning, "#ammoWarning_STR", maxLength: 0x20)
        p.bool(&w.autoRepeat, "#autoRepeat_BOOL")
        p.int(&w.delayBetweenLaunches, "#delayBetweenLaunches_INT")
        p.int(&w.delayBetweenLoadLaunches, "#delayBetweenLoadLaunches_INT")
        p.int(&w.shieldIncrease, "#shieldIncrease_INT")
        p.int(&w.livesIncrease, "#livesIncrease_INT")
        p.int(&w.invulnerableForTime, "#invulnerableForTime_INT")
        let count = p.count("#spawn_NumUnitsToSpawn_INT")
        var k: Int32 = 0
        while k < count {
            var s = Spawn()
            p.str(&s.name, "#spawn_Name_STR", maxLength: 0x20)
            p.id(&s.unit, "#spawn_Unit_ID")
            p.int(&s.xLoc, "#spawn_XLoc_INT")
            p.int(&s.yLoc, "#spawn_YLoc_INT")
            p.bool(&s.setHeading, "#spawn_SetHeading_BOOL")
            p.int(&s.angle, "#spawn_Angle_INT")
            if s.angle < 0 { s.angle += 360 } else if s.angle > 359 { s.angle -= 360 }
            if s.angle < 0 || s.angle > 359 { s.angle = 0 }
            w.spawns.append(s)
            k += 1
        }
        readPowerUp(&w.powerupAir, &p, "Air")
        readPowerUp(&w.powerupGround, &p, "Ground")

        var errors = p.errors
        if !errors.isEmpty { errors.append("A Weapon Definition file contained incorrect or missing data.") }
        w.notes = notes
        return (w, errors)
    }

    private static func readPowerUp(_ b: inout PowerUp, _ p: inout DefinitionReader, _ side: String) {
        p.int(&b.timeUntilActivation, "#powerup_\(side)_TimeUntilActivation_INT")
        p.id(&b.activationSpawn, "#powerup_\(side)_ActivationSpawn_ID")
        p.int(&b.timeBetweenPowerLevelChanges, "#powerup_\(side)_TimeBetweenPowerLevelChanges_INT")
        p.int(&b.maxPowerLevel, "#powerup_\(side)_MaxPowerLevel_INT")
        p.int(&b.overloadTime, "#powerup_\(side)_OverloadTime_INT")
        p.id(&b.releaseSpawn, "#powerup_\(side)_ReleaseSpawn_ID")
        p.int(&b.timeBetweenReleaseSpawns, "#powerup_\(side)_TimeBetweenReleaseSpawns_INT")
        p.bool(&b.doReleaseOnMaxPowerLevel, "#powerup_\(side)_DoReleaseOnMaxPowerLevel_BOOL")
    }
}
