import XCTest
@testable import FerazelCore
@testable import FerazelRender

/// DA (docs/plans/2026-10-30-ferazel-phase5.md, Q15 item 2; Invariant 8, Ruling 6): the standing draw-mode audit.
///
/// 1. `testEveryWrittenModeIsDrawable` — for every level in `BuiltLevels.range`, every draw input Core can write
///    (`SpriteDraw` mode word, rotation, scale, mirror, the dynamic-light byte case, water kind, clip, backdrop mode,
///    OmniPx mode) is drawn by `SpriteBlitter` / `FrameRenderer` with no refusal: every value of every row of
///    `writers` (one row per writer site in `Sources/FerazelCore`, file:line — a source scan fails on a writer without
///    a row, or a row whose line no longer writes), under every transform the renderer builds for it; each placement's
///    Setup (run once); and a 2,000-step scripted run of the level through `LevelRun` + `FrameRenderer`, whose every
///    drawn value must also be one the table names.
/// 2. `testEveryRefusalIsUnreachable` — every `throw` in `Sources/FerazelRender` (counted per file and thrown name;
///    a new throw without a row fails) with the reason it cannot be reached on a level frame of a built level, each
///    reason checked by code (the writer table, the data, the level headers, the routing).
///
/// **Maintained by every task** that adds a writer of a draw input or a renderer throw (Invariant 8): add its row here
/// in the same task. When a row's line moves, the failure prints the scanned `file:line` to paste.
///
/// Proof B runs this file under Wine: the source scan walks directories with `contentsOfDirectory` /
/// `fileExists(atPath:isDirectory:)` and matches in pure Swift (as `BootFacesTests`) — no directory enumerator, no
/// regex, no file attributes — and the class is not main-actor isolated. A missing data file is a FAILURE.
final class DrawModeAuditTests: XCTestCase {
    nonisolated(unsafe) private static let resources = Result { try FerazelData.open(try FerazelData.dataDirectory()) }

    // MARK: - Sources

    struct SourceLine: Sendable {
        /// The path below `Sources/<module>/`, e.g. `World/Movers/BoxSprite.swift`.
        let file: String
        let line: Int
        /// The line with its `//` comment cut off.
        let code: String
    }

    /// Every line of the module's `.swift` files (sorted paths), comments cut — `BootFacesTests.coreSources`' walk.
    private static func sources(_ module: String) throws -> [SourceLine] {
        let root = URL(fileURLWithPath: #filePath).resolvingSymlinksInPath().deletingLastPathComponent()
            .deletingLastPathComponent().deletingLastPathComponent().appendingPathComponent("Sources/\(module)")
        let fm = FileManager.default
        var out: [SourceLine] = [], folders: [(URL, String)] = [(root, "")]
        while let (dir, prefix) = folders.popLast() {
            var files: [(URL, String)] = []
            for name in try fm.contentsOfDirectory(atPath: dir.path).sorted() where !name.hasPrefix(".") {
                let url = dir.appendingPathComponent(name)
                var isDir: ObjCBool = false
                guard fm.fileExists(atPath: url.path, isDirectory: &isDir) else { continue }
                if isDir.boolValue { folders.append((url, prefix + name + "/")); continue }
                if name.hasSuffix(".swift") { files.append((url, prefix + name)) }
            }
            for (url, rel) in files {
                let text = try String(contentsOf: url, encoding: .utf8)
                for (i, line) in text.split(separator: "\n", omittingEmptySubsequences: false).enumerated() {
                    let code = line.split(separator: "//", maxSplits: 1, omittingEmptySubsequences: false).first ?? ""
                    out.append(SourceLine(file: rel, line: i + 1, code: String(code)))
                }
            }
        }
        return out
    }

    private static let coreLines = Result { try sources("FerazelCore") }
    private static let renderLines = Result { try sources("FerazelRender") }

    private static func isWord(_ c: Character) -> Bool { c == "_" || c.isLetter || c.isNumber }

    /// The fields of `code` assigned as `.<field> <op> ` (op `=`, `+=`, `-=`, `&+=`, `&-=`, `|=`, `&=`; not `==`).
    static func assignedFields(_ code: String, _ fields: [String]) -> [String] {
        let c = Array(code)
        var out: [String] = []
        for f in fields {
            let pat = Array("." + f)
            var i = 0
            while i + pat.count <= c.count {
                defer { i += 1 }
                guard Array(c[i..<(i + pat.count)]) == pat else { continue }
                var j = i + pat.count
                guard j == c.count || !isWord(c[j]) else { continue }
                var k = j
                while k < c.count && c[k] == " " { k += 1 }
                guard k > j else { continue }
                j = k
                for op in ["&+=", "&-=", "+=", "-=", "|=", "&=", "="] {
                    let o = Array(op)
                    guard j + o.count < c.count, Array(c[j..<(j + o.count)]) == o, c[j + o.count] == " " else { continue }
                    out.append(f)
                    break
                }
            }
        }
        return out
    }

    // MARK: - The writer table (Invariant 8: one row per writer site, kept by every task that adds one)

    enum Input: String, Sendable { case mode, rotation, scale, mirrored, flash, flashTable, waterKind }

    enum Values: Sendable {
        /// Mode words.
        case words([UInt32])
        case wordRange(ClosedRange<UInt32>)
        /// `SpriteSlot.applyDynamicLight`: 0xc0000 + L·0x100 + F, L the level's light bytes (`.GetLightTile`, every
        /// cell), F = `.GetFakeLight` 0…110 (DK's derivation: k 0…11 + a slot colour ≤ 99); L < 1 ∧ F < 1 → 0.
        case levelLight
        /// The Radial perspective words 0xc0000 + L·0x100, L = (int)(0.05·256·f) with f ∈ [0, 1] → 0…12.
        case radialLight
        /// 0x10000 + p2 of the level's active placements of these types with p2 ≠ 0 (the data decides).
        case placedTint(ClosedRange<Int16>)
        /// A value another row writes, or the sprite's own earlier value — no new value.
        case copy
        /// Rotation (degrees), scale (/256) or flash frames.
        case range(ClosedRange<Int>)
        case flags([Bool])
        /// `UnderWater.waterKind`: the level's liquid BG kinds − 200 (written only on a liquid cell).
        case levelLiquid
    }

    struct Writer: Sendable {
        let site: String
        let input: Input
        let values: Values
        /// The sprites the site writes (for the combinations the renderer refuses by design).
        let who: [String]
    }

    private static func W(_ site: String, _ input: Input, _ values: Values, _ who: String...) -> Writer {
        Writer(site: site, input: input, values: values, who: who)
    }

    /// The scanned files and fields whose writes are not a sprite draw input, with the reason.
    static let notDrawInputs: [(file: String, field: Input, why: String)] = [
        ("Particles/ParticlePool.swift", .mode, "a particle record's erase mode (`ParticleRenderer`, no refusal)"),
        ("Session/FerazelSession.swift", .flash, "`world.flash` / `LevelCarry.flash`: the screen flash, not +0xaa"),
    ]

    static let dynamicLit = ["platform.raft", "box.boulder", "background.maceBall", "chain.maceChain"]

    static let writers: [Writer] = [
        W("Items/HeldItem.swift:111", .mirrored, .copy, "heldItem"),
        W("Particles/WaterEffects.swift:144", .waterKind, .levelLiquid, "waterFace"),
        W("Physics/StandardSprite.swift:32", .flash, .range(0...0x1d), "any"),
        W("Physics/UnderWater.swift:63", .waterKind, .levelLiquid, "any"),
        W("Player/GroundCeilingEffects.swift:280", .mode, .words([0xb0004]), "effect.plume"),
        W("Player/GroundCeilingEffects.swift:357", .mode, .words([0xb0001]), "effect.debris"),
        W("Player/GroundCeilingEffects.swift:358", .mode, .words([0]), "effect.debris"),
        W("Player/GroundCeilingEffects.swift:359", .mode, .words([0xb0000]), "effect.debris"),
        W("Player/GroundCeilingEffects.swift:360", .mode, .words([0xb0002]), "effect.debris"),
        W("Player/GroundCeilingEffects.swift:392", .mode, .wordRange(0x10001...0x1000f), "effect.explosion"),
        W("Player/GroundCeilingEffects.swift:393", .mode, .words([0x10005]), "effect.explosion"),
        W("Player/HitPlayerSprite.swift:87", .flash, .range(0xc...0xc), "player"),
        W("Player/HitPlayerSprite.swift:902", .flash, .range(0x1e...0x1e), "player"),
        W("Player/HitPlayerSprite.swift:1182", .flash, .range(0xc...0xc), "player"),     // `HurtSprite.apply`'s one caller
        W("Player/Player.swift:126", .mirrored, .flags([false, true]), "player"),
        W("Player/Player.swift:332", .mirrored, .flags([false, true]), "player"),
        W("Player/Player.swift:873", .mode, .words([0x10008, 0x10009]), "player"),
        W("Player/Player.swift:878", .mode, .words([0xb0005, 0xb0001]), "player"),
        W("Player/PlayerLiquids.swift:55", .flash, .range(0xd...0xd), "player"),
        W("Player/PlayerLiquids.swift:78", .flash, .range(0x12...0x12), "player"),
        W("Player/PlayerState.swift:280", .mirrored, .copy, "player.shadowRing"),
        W("Player/PlayerStates.swift:133", .mirrored, .flags([false, true]), "player"),
        W("Player/PlayerStates.swift:295", .mirrored, .copy, "player.mistBody"),
        // The power tints, or the mode it had (walk-on-liquid kinds other than 0…2 store nothing).
        W("Player/PlayerStates.swift:836", .mode, .words([0, 0x1000a, 0x10004, 0x10001, 0x1000c, 0x10003, 0x10008]),
          "player"),
        W("Player/PlayerStates.swift:850", .mode, .words([0x10006]), "player"),
        W("Player/PlayerStates.swift:853", .mode, .words([0x10009]), "player"),
        W("Player/PlayerStates.swift:864", .mode, .words([0]), "player"),
        W("Player/PlayerStates.swift:875", .mode, .wordRange(0x50000...0x5000f), "player"),   // the sparkle, k 0…15
        W("Player/PlayerTiles.swift:131", .mirrored, .flags([false, true]), "player"),
        W("Player/PowerUps.swift:109", .mirrored, .copy, "player.trail"),
        W("Player/PowerUps.swift:112", .mode, .words([0xb0002, 0xb0000, 0xb0001, 0]), "player.trail"),
        W("Player/ShadowDouble.swift:156", .mirrored, .copy, "player.shadowDouble"),
        W("Player/ShadowDouble.swift:157", .mode, .words([ShadowDouble.tint]), "player.shadowDouble"),
        W("Session/FerazelSession.swift:204", .mirrored, .copy, "player.shadowRing"),
        W("Shots/CastSpell.swift:164", .mirrored, .flags([false]), "shot"),
        // 10·dir, dir 0…0x23, only for a shot with gravity (`0 < +0x110`: ids 0, 1, 3, 4, 7 and the seed 0x5a); the
        // followers take their main's angle (the orb 0x50 has gravity 0, PlayerShot.setup, so its followers get 0).
        W("Shots/PlayerShot.swift:313", .rotation, .range(0...350), "shot.gravity"),
        W("Shots/PlayerShot.swift:342", .rotation, .range(0...350), "shot.gravity"),
        W("Shots/PlayerShot.swift:449", .mode, .words([0]), "shot.orb"),
        W("Shots/PlayerShot.swift:450", .mode, .words([0x10008]), "shot.orb"),
        W("Shots/PlayerShot.swift:451", .mode, .words([0x10009]), "shot.orb"),
        W("Shots/PlayerShot.swift:457", .mode, .words([0xb0002]), "shot.orb"),
        W("Shots/PlayerShot.swift:458", .mode, .words([0xb0000]), "shot.orb"),
        W("Shots/PlayerShot.swift:459", .mode, .words([0xb0001]), "shot.orb"),
        W("Shots/PlayerShot.swift:460", .mode, .words([0]), "shot.orb"),
        W("Shots/PlayerShot.swift:474", .mode, .words([0x10004]), "shot.gravity"),        // the seed (gravity 0xfa)
        W("Shots/PlayerShotHits.swift:109", .mode, .words([0x10004]), "shot.gravity"),    // the seed
        W("Shots/PlayerShotHits.swift:210", .flash, .range(10...10), "box"),
        W("Sprites/SetupFaces.swift:353", .mirrored, .flags([true]), "background.plant"),
        W("Sprites/SetupFaces.swift:354", .mode, .placedTint(0xa8c...0xaef), "background.plant"),
        W("Sprites/SetupFaces.swift:399", .mode, .words([0x90000]), "box.teleporter"),
        W("Sprites/SetupFaces.swift:417", .mode, .words([0x90000]), "box.chest"),
        W("Sprites/SetupFaces.swift:477", .mirrored, .flags([false, true]), "walker"),
        W("Sprites/SetupFaces.swift:486", .mirrored, .flags([true]), "walker"),
        W("Sprites/SetupFaces.swift:488", .mirrored, .flags([true]), "walker"),
        W("Sprites/SetupFaces.swift:491", .mode, .words([0x10010]), "walker"),
        W("Sprites/SetupFaces.swift:492", .mode, .words([0x10011]), "walker"),
        W("Sprites/SetupFaces.swift:493", .mode, .words([0x10012]), "walker"),
        W("Sprites/SetupFaces.swift:494", .mode, .words([0x10013]), "walker"),
        W("Sprites/SetupFaces.swift:495", .mode, .words([0x10014]), "walker"),
        W("Sprites/SetupFaces.swift:496", .mode, .words([0x10015]), "walker"),
        W("Sprites/SetupFaces.swift:514", .mode, .words([0x10003]), "crawler"),
        W("Sprites/SetupFaces.swift:515", .mode, .words([0x1000f]), "crawler"),
        W("Sprites/SetupFaces.swift:516", .mode, .words([0x10002]), "crawler"),
        W("Sprites/SetupFaces.swift:575", .mode, .words([0]), "blob"),
        W("Sprites/SetupFaces.swift:599", .mode, .words([0]), "frog"),
        W("Sprites/SetupFaces.swift:600", .mode, .words([0x1000c]), "frog"),
        W("Sprites/SetupFaces.swift:601", .mode, .words([0x10017]), "frog"),
        W("Sprites/SetupFaces.swift:602", .mode, .words([0x1000f]), "frog"),
        W("Sprites/SetupFaces.swift:603", .mode, .words([0x1000b]), "frog"),
        W("Sprites/SpriteSlot.swift:443", .mode, .words([0]), "platform.raft", "box.boulder", "background.maceBall",
          "chain.maceChain"),
        W("Sprites/SpriteSlot.swift:445", .mode, .levelLight, "platform.raft", "box.boulder", "background.maceBall",
          "chain.maceChain"),
        // (angle >> 8) + 0x5a with the angle wrapped into 0…0x167ff (`RadialMotion.updatePosition`), − 360 once.
        W("World/Movers/BackgroundSprite.swift:190", .rotation, .range(0...359), "background.maceBall"),
        W("World/Movers/BackgroundSprite.swift:276", .mode, .words([0x10018]), "background.spring"),  // hdr 0x26cd ≠ 0
        W("World/Movers/BackgroundSprite.swift:336", .mirrored, .flags([false]), "background.cannon"),
        W("World/Movers/BackgroundSprite.swift:338", .mirrored, .flags([true]), "background.cannon"),
        W("World/Movers/BackgroundSprite.swift:341", .mirrored, .flags([false]), "background.cannon"),
        W("World/Movers/BackgroundSprite.swift:346", .mirrored, .flags([false]), "background.cannon"),
        W("World/Movers/BackgroundSprite.swift:348", .mirrored, .flags([true]), "background.cannon"),
        W("World/Movers/BackgroundSprite.swift:351", .rotation, .range(0...0), "background.cannon"),
        W("World/Movers/BackgroundSprite.swift:353", .mode, .words([0]), "background.cannon"),
        W("World/Movers/BackgroundSprite.swift:358", .mirrored, .flags([false]), "background.cannon"),
        // r = ((0x20 − aim)·0xb4 / 16) / 2 for aim 1…31 not ≡ 0 mod 4 → 5…174, doubled: 10…348.
        W("World/Movers/BackgroundSprite.swift:360", .rotation, .range(10...348), "background.cannon"),
        W("World/Movers/BackgroundSprite.swift:375", .mirrored, .flags([true]), "background.spring"),
        W("World/Movers/BackgroundSprite.swift:723", .mirrored, .flags([false, true]), "background.smoke"),
        W("World/Movers/BackgroundSprite.swift:781", .mirrored, .flags([true]), "background.spike"),
        W("World/Movers/BackgroundSprite.swift:789", .mode, .words([0x10018]), "background.spike"),   // hdr 0x26cd ≠ 0
        W("World/Movers/BackgroundSprite.swift:791", .mode, .words([0x90000]), "background.spike"),
        W("World/Movers/BonusSprite.swift:130", .mode, .words([0]), "bonus"),
        W("World/Movers/BonusSprite.swift:388", .mode, .words([0x10008]), "bonus"),
        W("World/Movers/BonusSprite.swift:389", .mode, .words([0x10009]), "bonus"),
        W("World/Movers/BonusSprite.swift:390", .mode, .words([0]), "bonus"),
        W("World/Movers/BonusSprite.swift:407", .mode, .words([0x10001]), "bonus"),
        W("World/Movers/BonusSprite.swift:416", .mode, .words([0xb0001]), "bonus"),
        W("World/Movers/BonusSprite.swift:417", .mode, .words([0xb0000]), "bonus"),
        W("World/Movers/BonusSprite.swift:418", .mode, .words([0xb0002]), "bonus"),
        W("World/Movers/BonusSprite.swift:420", .mode, .words([0]), "bonus"),
        W("World/Movers/BonusSprite.swift:448", .mode, .words([0xb0000, 0]), "bonus"),
        W("World/Movers/BonusSprite.swift:581", .mode, .words([0]), "bonus"),
        W("World/Movers/BonusSprite.swift:582", .mode, .words([0xb0001]), "bonus"),
        W("World/Movers/BonusSprite.swift:583", .mode, .words([0xb0000]), "bonus"),
        W("World/Movers/BonusSprite.swift:584", .mode, .words([0xb0002]), "bonus"),
        W("World/Movers/BonusSprite.swift:602", .mode, .words([0]), "bonus"),
        W("World/Movers/BoxSprite.swift:195", .mirrored, .flags([false]), "box.bridge"),
        W("World/Movers/BoxSprite.swift:200", .mirrored, .flags([true]), "box.bridge"),
        W("World/Movers/BoxSprite.swift:203", .mirrored, .flags([true]), "box.bridge"),
        W("World/Movers/BoxSprite.swift:243", .mirrored, .flags([true]), "box.door"),
        W("World/Movers/BoxSprite.swift:289", .flashTable, .flags([true]), "box.iceWall"),
        W("World/Movers/BoxSprite.swift:305", .mode, .words([0x10018]), "box.gate"),          // hdr 0x26cd ≠ 0
        W("World/Movers/BoxSprite.swift:337", .mode, .words([0xb0001]), "box.lantern"),
        W("World/Movers/BoxSprite.swift:377", .mirrored, .flags([true]), "box.decoration"),
        W("World/Movers/BoxSprite.swift:381", .mode, .placedTint(0xaf5...0xb21), "box.decoration"),
        W("World/Movers/BoxSprite.swift:391", .mode, .words([0x10006]), "box.outcrop"),
        W("World/Movers/BoxSprite.swift:392", .mode, .words([0x10007]), "box.outcrop"),
        W("World/Movers/BoxSprite.swift:393", .mode, .words([0xb0005]), "box.outcrop"),
        W("World/Movers/BoxSprite.swift:498", .mode, .words([0xb0002, 0xb0000, 0xb0001]), "box.trunk"),
        W("World/Movers/BoxSprite.swift:535", .mirrored, .flags([true]), "box.statue"),
        W("World/Movers/BoxSprite.swift:589", .waterKind, .copy, "box.cart"),
        // The hovering rock (`+0x160 < 0`): see `hoverUnreachable` — a separate sprite state from the roll (:643).
        W("World/Movers/BoxSprite.swift:622", .mode, .words([0xb0000, 0xb0002]), "box.boulder.hover"),
        W("World/Movers/BoxSprite.swift:624", .mode, .words([0xb0002, 0]), "box.boulder.hover"),
        W("World/Movers/BoxSprite.swift:628", .mode, .words([0]), "box.boulder.hover"),
        W("World/Movers/BoxSprite.swift:643", .rotation, .range(0...359), "box.boulder"),     // wrapped into 0…359
        W("World/Movers/BoxSprite.swift:866", .mirrored, .copy, "box.balloon"),
        // (subtype + 0x5a) % 360, subtype a spoke's degrees 0…359 or −90 (`Radial.updateSpokes`) → 0…359.
        W("World/Movers/ChainSprite.swift:51", .rotation, .range(0...359), "chain.maceChain"),
        W("World/Movers/ChainSprite.swift:103", .mirrored, .flags([false, true]), "chain.seeSawSegment"),
        W("World/Movers/PlatformSprite.swift:322", .mirrored, .flags([true]), "platform.catapult"),
        W("World/Movers/PlatformSprite.swift:600", .mode, .words([0xb0001]), "platform.blink"),
        W("World/Movers/PlatformSprite.swift:601", .mode, .words([0xb0000]), "platform.blink"),
        W("World/Movers/PlatformSprite.swift:602", .mode, .words([0xb0002]), "platform.blink"),
        W("World/Movers/PlatformSprite.swift:637", .mode, .words([0xb0002]), "platform.blink"),
        W("World/Movers/PlatformSprite.swift:640", .mode, .words([0xb0000]), "platform.blink"),
        W("World/Movers/PlatformSprite.swift:642", .mode, .words([0]), "platform.blink"),
        W("World/Movers/PlatformSprite.swift:698", .mode, .words([0]), "platform.blink"),
        W("World/Movers/PlatformSprite.swift:703", .mode, .words([0xb0001]), "platform.blink"),
        W("World/Movers/PlatformSprite.swift:706", .mode, .words([0xb0000]), "platform.blink"),
        W("World/Movers/PlatformSprite.swift:707", .mode, .words([0xb0002]), "platform.blink"),
        W("World/Movers/PlatformSprite.swift:865", .mode, .words([0]), "platform.gauge"),
        W("World/Movers/PlatformSprite.swift:867", .mode, .wordRange(0xa000b...0xa00fa), "platform.gauge"),
        // The raft's tilt (`tail`, subtype 3 only), wrapped into 0…359.
        W("World/Movers/PlatformSprite.swift:925", .rotation, .range(0...359), "platform.raft"),
        // The floe's last 0x2c frames (`+0xa6` in 1…0x2c): subtypes 4 / 0x6a4 (`PlayerShot.floe` / `ledge` set
        // `+0xa6 = 0xb4`); the raft (subtype 3) has `+0xa6 = 0` from its Setup arm and no writer after it.
        W("World/Movers/PlatformSprite.swift:947", .mode, .words([0xb0000, 0]), "platform.floe"),
        // 255 − f·(0x100 − 0x96), f ∈ [0, 1] → 149…255 (the ball); the spokes 203 + J·(drawScale − 203)·2 / n.
        W("World/Movers/Radial.swift:213", .scale, .range(0x95...0xff), "radial.persp"),
        W("World/Movers/Radial.swift:215", .mode, .radialLight, "radial.persp"),
        W("World/Movers/Radial.swift:263", .mode, .words([0x10018]), "radial.spokes"),   // its one caller (PlatformSprite)
        W("World/Movers/Radial.swift:297", .scale, .range(0x5f...0x133), "radial.persp"),
        W("World/Movers/Radial.swift:302", .mode, .radialLight, "radial.persp"),
        W("World/Movers/StatueSprite.swift:50", .mode, .words([0x1000b]), "statue"),
        W("World/Movers/StatueSprite.swift:55", .mode, .words([0]), "statue"),
        W("World/Movers/StatueSprite.swift:61", .mode, .copy, "statue"),     // the sprite's own mode, restored
    ]

    /// Every writer site the scan finds: `file:line` and the field.
    private static func scannedWriters() throws -> [(site: String, input: Input, code: String)] {
        let fields = ["mode", "rotation", "scale", "mirrored", "flash", "flashTable", "waterKind"]
        var out: [(String, Input, String)] = []
        for l in try coreLines.get() where !l.file.hasPrefix("Seams/") {
            var found = assignedFields(l.code, fields)
            if l.file == "Sprites/SpriteSlot.swift",
               l.code.trimmingCharacters(in: .whitespaces).hasPrefix("mode = ") { found.append("mode") }
            for f in found {
                guard let input = Input(rawValue: f) else { continue }
                if notDrawInputs.contains(where: { $0.file == l.file && $0.field == input }) { continue }
                out.append(("\(l.file):\(l.line)", input, l.code.trimmingCharacters(in: .whitespaces)))
            }
        }
        return out
    }

    // MARK: - The values, per level

    struct Level {
        let number: Int
        let file: LevelFile
        let renderer: FrameRenderer
        let lightBytes: Set<Int>
        let liquidKinds: Set<Int16>
    }

    /// The mode words of a mode row on `L`.
    static func words(_ v: Values, _ l: Level) -> [UInt32] {
        switch v {
        case .words(let w): return w
        case .wordRange(let r): return Array(r)
        case .levelLight:
            var out: Set<UInt32> = [0]
            // F's read is in range iff the light row L·0x6e00 + F·0x100 is (`special`'s guard, monotone in L and F):
            // the corners and a spread decide; every L the level holds.
            for L in l.lightBytes { for F in [0, 1, 55, 109, 110] where L >= 1 || F >= 1 {
                out.insert(UInt32(truncatingIfNeeded: L * 0x100 + 0xc0000 + F))
            } }
            return out.sorted()
        case .radialLight: return (0...12).map { UInt32(0xc0000 + $0 * 0x100) }
        case .placedTint(let types):
            return Set(l.file.activePlacements.filter { types.contains($0.type) && $0.p2 != 0 }
                .map { UInt32(truncatingIfNeeded: Int($0.p2) + 0x10000) }).sorted()
        case .copy, .range, .flags, .levelLiquid: return []
        }
    }

    /// Whether a mode row on `l` writes `word` (its whole value set, not the sample `words` draws).
    static func writes(_ v: Values, _ l: Level, _ word: UInt32) -> Bool {
        let m = modeOf(word), L = Int(Int8(truncatingIfNeeded: word >> 8)), F = Int(word & 0xff)
        switch v {
        case .levelLight:
            return word == 0 || (m == 0xc && l.lightBytes.contains(L) && (0...110).contains(F) && (L >= 1 || F >= 1))
        case .radialLight: return m == 0xc && F == 0 && (0...12).contains(L)
        default: return words(v, l).contains(word)
        }
    }

    static func modeOf(_ w: UInt32) -> Int { Int(Int32(bitPattern: w) >> 16) }

    /// The modes `table(mode:)` serves under a transform (`SpriteBlitter.table`); every other mode is refused rotated
    /// or scaled, and 0xa (no mode-10 arm in the flip twins) mirrored.
    static let transformSafe: Set<Int> = [0, 1, 3, 4, 6, 9, 0xc]

    // MARK: - The per-level audit (built once, shared by both tests)

    struct Seen {
        var steps = 0, restarts = 0, ticks = 0
        var modes: Set<UInt32> = [], rotations: Set<Int16> = [], scales: Set<Int16> = [], waterKinds: Set<Int16> = []
        var waterFaces: Set<Int16> = [], waterFaceKinds: Set<Int16> = [], lightColours: Set<Int16> = []
        var mode5Unseeded = 0, levelOpsOffLevel: [String] = [], refusals: [String] = []
        var deathSteps: Set<Int> = []
        /// `FerazelSession.tintTableDraws.count` of every session the run hosted.
        var tintDraws: Set<Int> = []
    }

    struct Audit {
        let level: Level
        /// The Setup of every active placement, run once (`SetupFaces.setup`).
        let setups: [SetupFaces.Entry]
        let seen: Seen
    }

    /// The ops `FrameRenderer.apply` executes with no `try` in their arm (checked in `testEveryRefusalIsUnreachable`):
    /// the run skips them to stay fast — they cannot refuse.
    static let skippedOps = ["copyToScreen", "copyMaskToScreen", "drawLightsOntoTiles", "statusBar", "mosaic",
                             "drawParticles", "eraseParticles", "drawBlackLines", "gammaStep"]

    /// The op's case name (a switch: `String(describing:)` of a sprite list is far too slow for the run).
    static func name(_ op: DrawOp) -> String {
        switch op {
        case .setScreenClut: "setScreenClut"
        case .drawPicture: "drawPicture"
        case .redrawScrollGrid: "redrawScrollGrid"
        case .redrawEntireScrollGrid: "redrawEntireScrollGrid"
        case .setDrawnScroll: "setDrawnScroll"
        case .drawLightsOntoTiles: "drawLightsOntoTiles"
        case .wrapDrawSprites: "wrapDrawSprites"
        case .copyToScreen: "copyToScreen"
        case .copyMaskToScreen: "copyMaskToScreen"
        case .changeLightFace: "changeLightFace"
        case .wrapEraseSprites: "wrapEraseSprites"
        case .statusBar: "statusBar"
        case .gammaStep: "gammaStep"
        case .setTile: "setTile"
        case .wrapDrawWaterEffects: "wrapDrawWaterEffects"
        case .drawParticles: "drawParticles"
        case .eraseParticles: "eraseParticles"
        case .drawBlackLines: "drawBlackLines"
        case .lightTable: "lightTable"
        case .mosaic: "mosaic"
        case .fillRect: "fillRect"
        case .copyPicture: "copyPicture"
        case .drawFace: "drawFace"
        case .drawLine: "drawLine"
        case .drawText: "drawText"
        case .restoreView: "restoreView"
        case .screenGamma: "screenGamma"
        }
    }

    /// `FerazelDriver`'s `LevelServices` (Ferazel/Shared/FerazelDriver.swift), headless.
    final class Services: LevelServices {
        let resources: FerazelResources
        private(set) var renderer: FrameRenderer?
        private(set) var first: FrameRenderer?
        var deathSteps: Set<Int> = []
        init(_ resources: FerazelResources) { self.resources = resources }
        func prepare(level: Int) throws -> LevelFaces {
            let r = try FrameRenderer(resources: resources, level: level, search: DrawModeAuditTests.search,
                                      dither: .errorDiffusion, text: StatusBarTests.BoxRasterizer(), prefs: FerazelPrefs())
            renderer = r
            if first == nil { first = r }
            return LevelFaces(faceBounds: r.faceBounds, particleFaces: r.particleFaces, diffuseRandoms: r.diffuseRandoms,
                              diffuseRandomsAt: r.diffuseRandomsAt)
        }
        func attach(lights: [SetupFaces.Light], tintTableDraws: [Int16]) throws {
            guard let r = renderer else { throw FrameRenderer.Refusal.tintTableNotBuilt }
            try r.addLights(lights)
            try r.buildTintTable(tintTableDraws)
        }
        func deathEffectStep(_ k: Int) throws {
            guard renderer != nil else { throw FrameRenderer.Refusal.tintTableNotBuilt }
            guard (0..<DeathEffect.steps).contains(k) else { throw FrameRenderer.Refusal.deathEffectStep(k) }
            deathSteps.insert(k)
        }
    }

    /// `LevelSweepTests`' search (the ruled model, lowest tie-break).
    static let search = ColorSearch(model: .ruled)
    static let runSteps = 2000

    /// The scripted input of tick t: blocks of 8 ticks — two of game keys from a fixed stream, one with every key up,
    /// one with Return (a conversation's menu confirm) — so modals, signs and conversations move on.
    struct Script {
        var rng = FastRand(seed: 8)
        var keys = KeyState()
        mutating func input(_ t: Int) -> FrontInput {
            if t % 8 == 0 {
                keys = KeyState()
                switch (t / 8) % 4 {
                case 0, 1: for c in FerazelPrefs.defaultKeys where rng.next(3) == 0 { keys.press(Int(c)) }
                case 2: break
                default: keys.press(0x24)
                }
            }
            return FrontInput(keys: keys)
        }
    }

    private static func audit(level number: Int) throws -> Audit {
        let res = try resources.get()
        let prefs = FerazelPrefs()
        let services = Services(res)
        var seen = Seen()
        var script = Script()
        var t: UInt32 = 0
        func newRun() throws -> LevelRun {
            try LevelRun(resources: res, prefs: prefs, level: number, seed: 1, carry: LevelCarry(), save: SaveBlock(),
                         fade: ScreenFade(), music: MusicFade(), services: services,
                         sounds: StageSounds(prefs: prefs, lengths: [:]), files: SweepFiles())
        }
        var run = try newRun()
        while seen.steps < runSteps && seen.ticks < runSteps * 6 {
            if run.end != nil {
                seen.restarts += 1
                run = try newRun()
            }
            let out: LevelRunOutput
            do { out = try run.tick(now: t, input: script.input(seen.ticks)) } catch {
                seen.refusals.append("tick \(seen.ticks): \(error)")
                break
            }
            t &+= 1
            seen.ticks += 1
            seen.steps += run.lastSteps.count
            if let session = run.session { seen.tintDraws.insert(session.tintTableDraws.count) }
            for q in out.merged.requests {
                switch q {
                case .putFile, .getFile: run.fileDone(.cancelled)
                case .dialog: run.dialogDone(.ok)
                default: break
                }
            }
            for g in out.segments {
                guard g.target == .level else {
                    for op in g.output.draws where LevelRunOutput.target(of: op, levelClut: -1, owner: .screen) == .level
                        && !Self.isClut(op) { seen.levelOpsOffLevel.append(name(op)) }
                    continue
                }
                for op in g.output.draws { observe(op, &seen) }
                guard let r = services.renderer else { continue }
                let ops = g.output.draws.filter { !skippedOps.contains(name($0)) }
                do { try r.apply(FrameOps(draws: ops)) } catch {
                    seen.refusals.append("tick \(seen.ticks): \(error)")
                }
            }
            if !seen.refusals.isEmpty { break }
        }
        seen.deathSteps = services.deathSteps
        let r = try XCTUnwrap(services.first)
        let L = r.level
        var bytes = Set<Int>(), liquids = Set<Int16>()
        for row in 0..<L.bg.height {
            for col in 0..<L.bg.width {
                bytes.insert(L.lightByte(col: col, row: row))
                let k = L.bgKind(tile: L.bgTile(col: col, row: row))
                if UnderWater.isWaterTile(k) { liquids.insert(UnderWater.waterKind(k)) }
            }
        }
        let ctx = SetupFaces.Context(level: L, playerX: SetupFaces.Context.levelStartPlayerX(L.header),
                                     effects: prefs.effects)
        let setups = try L.activePlacements.map { try SetupFaces.setup($0, context: ctx) }
        return Audit(level: Level(number: number, file: L, renderer: r, lightBytes: bytes, liquidKinds: liquids),
                     setups: setups, seen: seen)
    }

    private static func isClut(_ op: DrawOp) -> Bool { if case .setScreenClut = op { true } else { false } }

    private static func observe(_ op: DrawOp, _ s: inout Seen) {
        switch op {
        case .wrapDrawSprites(let ds):
            for d in ds {
                s.modes.insert(d.mode)
                s.rotations.insert(d.rotation)
                s.scales.insert(d.scale)
                if d.waterRow >= 1 && !d.noWaterSplit { s.waterKinds.insert(d.waterKind) }
                if modeOf(d.mode) == 5 && d.randomSeed == nil { s.mode5Unseeded += 1 }
            }
        case .wrapDrawWaterEffects(let list):
            for f in list { s.waterFaces.insert(f.tile); s.waterFaceKinds.insert(f.waterKind) }
        case .lightTable(let table):
            for slot in table.slots where slot.active { s.lightColours.insert(slot.colour) }
        default: break
        }
    }

    nonisolated(unsafe) private static let audits = Result { try BuiltLevels.range.map { try audit(level: $0) } }

    // MARK: - Drawing one value

    /// A slot carrying `d` as its last-frame draw, for `.WrapEraseSprites`.
    private static func erased(_ d: SpriteDraw) -> SpriteSlot {
        var s = SpriteSlot(type: 1, x: d.x, y: d.y, face: d.face)
        s.mode = d.mode
        s.mirrored = d.mirrored
        s.clip = d.clip
        s.lightOverlay = d.lightOverlay
        s.waterRow = Int32(d.waterRow)
        s.rotation = d.rotation
        s.scale = d.scale
        s.flash = d.flash
        s.flashTable = d.flashTable
        s.waterKind = d.waterKind
        s.noWaterSplit = d.noWaterSplit
        s.recordDrawn()
        return s
    }

    /// The level's sprite blitter as `FrameRenderer.apply` arms it (parallax attached), with its own ports — the mask
    /// 0xff so mode 0xb reads the backdrop under every pixel.
    struct Pad {
        var blitter: SpriteBlitter
        var ports = FramePorts()
        init(_ r: FrameRenderer) {
            blitter = r.sprites
            blitter.parallax = r.parallax
            ports.mask = [UInt8](repeating: 0xff, count: ports.mask.count)
        }
        /// Draws and erases `d`; nil when drawn, else the refusal.
        mutating func draw(_ d: SpriteDraw) -> String? {
            do {
                try blitter.wrapDrawSprites([d], h: 0, v: 0, ports: &ports)
                // No grid re-stamp: the erase leaves the mask 0xff under the face again.
                try blitter.wrapEraseSprites([DrawModeAuditTests.erased(d)], h: 0, v: 0, ports: &ports)
            } catch {
                return "\(error)"
            }
            return nil
        }
    }

    /// The widest loaded face (the transforms' and the erase twins' bound) and a small one, by PICT order.
    private static func probeFaces(_ r: FrameRenderer) -> [FaceRef] {
        var wide: (FaceRef, Int)?, small: (FaceRef, Int)?
        for (pict, s) in r.sprites.faces.sheets.sorted(by: { $0.key < $1.key }) {
            for (i, f) in s.faces.enumerated() where f.height > 4 {
                let ref = FaceRef(pict: pict, index: i, set: .encoded)
                if f.width > (wide?.1 ?? -1) { wide = (ref, f.width) }
                if f.width >= 0x18 && f.width < (small?.1 ?? Int.max) { small = (ref, f.width) }
            }
        }
        return [wide?.0, small?.0].compactMap { $0 }
    }

    /// Every value of every row drawn on `a`'s level (each distinct value once), under each transform the renderer
    /// builds for its mode; the refusals, labelled by a row that writes the value.
    static func drawWriters(_ a: Audit) -> [String] {
        let r = a.level.renderer
        var pad = Pad(r)
        var failures: [String] = []
        let faces = probeFaces(r)
        guard let wide = faces.first, let small = faces.last else { return ["level \(a.level.number): no probe face"] }
        func put(_ d: SpriteDraw, _ label: String) {
            if let e = pad.draw(d) { failures.append("level \(a.level.number) \(label): \(e)") }
        }
        var wordSite: [UInt32: String] = [:], rotations: [Int: String] = [:], scales: [Int: String] = [:]
        var flashes: [Int: String] = [:], kinds: String?
        for w in writers {
            switch (w.input, w.values) {
            case (.mode, _): for word in words(w.values, a.level) where wordSite[word] == nil { wordSite[word] = w.site }
            case (.rotation, .range(let x)): for v in x where rotations[v] == nil { rotations[v] = w.site }
            case (.scale, .range(let x)): for v in x where scales[v] == nil { scales[v] = w.site }
            case (.flash, .range(let x)): for v in x where v > 0 && flashes[v] == nil { flashes[v] = w.site }
            case (.waterKind, .levelLiquid): kinds = kinds ?? w.site
            default: break
            }
        }
        for (word, site) in wordSite.sorted(by: { $0.key < $1.key }) {
            let m = modeOf(word), seed: Int32? = m == 5 ? 1 : nil
            // The squash (0xa) has no flipped arm: unmirrored, on the small face (q only changes the squash).
            put(SpriteDraw(face: small, x: 100, y: 100, mode: word, lightOverlay: true, randomSeed: seed),
                "\(site) word \(hex(word))")
            put(SpriteDraw(face: small, x: 0x26c, y: 0x188, mode: word, randomSeed: seed), "\(site) word \(hex(word)) wrapped")
            guard m != 0xa else { continue }
            for mirrored in [false, true] {
                put(SpriteDraw(face: wide, x: 100, y: 100, mode: word, mirrored: mirrored, lightOverlay: true,
                               randomSeed: seed), "\(site) word \(hex(word)) mirrored \(mirrored)")
            }
            guard transformSafe.contains(m) else { continue }
            for mirrored in [false, true] {
                for rot: Int16 in [90, 359] {
                    put(SpriteDraw(face: wide, x: 120, y: 100, mode: word, mirrored: mirrored, rotation: rot),
                        "\(site) word \(hex(word)) rotation \(rot)")
                }
                for sc: Int16 in [0x5f, 0x133] {
                    put(SpriteDraw(face: wide, x: 120, y: 100, mode: word, mirrored: mirrored, scale: sc),
                        "\(site) word \(hex(word)) scale \(sc)")
                }
            }
        }
        for (rot, site) in rotations.sorted(by: { $0.key < $1.key }) {
            for mirrored in [false, true] {
                put(SpriteDraw(face: small, x: 120, y: 100, mirrored: mirrored, rotation: Int16(rot)),
                    "\(site) rotation \(rot)")
            }
            if rot % 45 == 1 || rot == 359 {
                put(SpriteDraw(face: wide, x: 120, y: 100, mode: 0xc0000, mirrored: true, rotation: Int16(rot)),
                    "\(site) rotation \(rot) wide")
            }
        }
        for (sc, site) in scales.sorted(by: { $0.key < $1.key }) {
            put(SpriteDraw(face: small, x: 120, y: 100, mode: 0xc0000, scale: Int16(sc)), "\(site) scale \(sc)")
            if sc % 32 == 0 || sc == 0x133 {
                for mirrored in [false, true] {
                    put(SpriteDraw(face: wide, x: 120, y: 100, mode: 0xc0000, mirrored: mirrored, scale: Int16(sc)),
                        "\(site) scale \(sc) wide")
                }
            }
        }
        for (n, site) in flashes.sorted(by: { $0.key < $1.key }) {
            for table: UInt8 in [0, 1] {
                for rot: Int16 in [0, 90] {
                    put(SpriteDraw(face: wide, x: 120, y: 100, rotation: rot, flash: Int16(n), flashTable: table),
                        "\(site) flash \(n) table \(table) rotation \(rot)")
                }
            }
        }
        if let site = kinds {
            for k in a.level.liquidKinds.sorted() {
                for row in [1, 5] {
                    for mirrored in [false, true] {
                        for rot: Int16 in [0, 90] {
                            put(SpriteDraw(face: wide, x: 120, y: 100, mirrored: mirrored, lightOverlay: true,
                                           waterRow: row, rotation: rot, waterKind: k),
                                "\(site) water kind \(k) row \(row) rotation \(rot)")
                        }
                    }
                }
            }
        }
        return failures
    }

    /// `drawWriters` of every built level, once for both tests.
    nonisolated(unsafe) private static let drawn = Result { try audits.get().map(drawWriters) }

    static func hex(_ w: UInt32) -> String { "0x" + String(w, radix: 16) }

    // MARK: - testEveryWrittenModeIsDrawable

    func testEveryWrittenModeIsDrawable() throws {
        // The table and the scan agree: every writer site has its row, every row's line still writes its field.
        let scanned = try Self.scannedWriters()
        let rows = Set(Self.writers.map { "\($0.site) \($0.input.rawValue)" })
        XCTAssertEqual(rows.count, Self.writers.count, "a writer row twice")
        let found = Set(scanned.map { "\($0.site) \($0.input.rawValue)" })
        let missing = scanned.filter { !rows.contains("\($0.site) \($0.input.rawValue)") }
        XCTAssertTrue(missing.isEmpty, "writers without a row (add them to `writers`):\n"
                      + missing.map { "  \($0.site) .\($0.input.rawValue)   \($0.code)" }.joined(separator: "\n"))
        let stale = Self.writers.filter { !found.contains("\($0.site) \($0.input.rawValue)") }
        XCTAssertTrue(stale.isEmpty, "rows whose line writes no such field (moved? re-scan):\n"
                      + stale.map { "  \($0.site) .\($0.input.rawValue)" }.joined(separator: "\n"))

        let audits = try Self.audits.get()
        try check(.skippedOpsCannotThrow, audits)
        for (a, failures) in zip(audits, try Self.drawn.get()) {
            let n = a.level.number, L = a.level.file
            // The backdrop and OmniPx inputs: the level's header names the backdrop the renderer draws.
            XCTAssertLessThanOrEqual(L.header.flameMode, 0, "level \(n): the Fire backdrop")
            XCTAssertEqual(L.header.parallaxRipple, 0, "level \(n): the backdrop ripple")
            XCTAssertEqual(L.header.omniPxMode, 0, "level \(n): OmniPx")

            // Every row's values, under every transform the renderer builds for them.
            XCTAssertTrue(failures.isEmpty, "\(failures.count) refused:\n" + failures.prefix(20).joined(separator: "\n"))

            // Every Setup's own draw (each placement once), drawn and erased; its values named by the table.
            let modeRows = Self.writers.filter { $0.input == .mode }
            func named(_ w: UInt32) -> Bool { modeRows.contains { Self.writes($0.values, a.level, w) } }
            var pad = Pad(a.level.renderer)
            for e in a.setups {
                guard let d = e.slot.draw else { continue }
                if let error = pad.draw(d) { XCTFail("level \(n) Setup \(Self.hex(UInt32(UInt16(bitPattern: e.type)))): \(error)") }
                XCTAssertTrue(named(d.mode),
                              "level \(n) type \(e.type): Setup word \(Self.hex(d.mode)) has no writer row")
            }

            // The scripted run: drawn with no refusal; every drawn value is one the table names.
            let s = a.seen
            XCTAssertTrue(s.refusals.isEmpty, "level \(n) run: \(s.refusals.prefix(5))")
            XCTAssertEqual(s.steps >= Self.runSteps, true, "level \(n): \(s.steps) steps in \(s.ticks) ticks")
            for w in s.modes where !named(w) {
                XCTFail("level \(n) run: mode word \(Self.hex(w)) has no writer row")
            }
            let rotations = Set(Self.writers.filter { $0.input == .rotation }.flatMap { w -> [Int] in
                if case .range(let r) = w.values { return Array(r) } else { return [] } })
            for r in s.rotations where r != 0 && !rotations.contains(Int(r)) {
                XCTFail("level \(n) run: rotation \(r) outside every writer row's range")
            }
            let scales = Set(Self.writers.filter { $0.input == .scale }.flatMap { w -> [Int] in
                if case .range(let r) = w.values { return Array(r) } else { return [] } })
            for v in s.scales where v != 0x100 && !scales.contains(Int(v)) {
                XCTFail("level \(n) run: scale \(v) outside every writer row's range")
            }
            for k in s.waterKinds.union(s.waterFaceKinds) where !a.level.liquidKinds.contains(k) {
                XCTFail("level \(n) run: water kind \(k) is not a liquid of the level")
            }
            XCTAssertEqual(s.mode5Unseeded, 0, "level \(n): a mode-5 draw with no seed")
        }
    }

    // MARK: - The refusal table

    enum Reason: String {
        /// No writer produces the input (the writer table, drawn in test 1, never reaches the refused arm).
        case noWriter = "no writer"
        /// The data the throw needs is absent from the built levels (checked over the shipped files).
        case dataAbsent = "data absent"
        /// A level-header value the built levels hold 0 (or ≤ 0).
        case headerZero = "header value 0"
        /// Thrown while a level's faces / tables load, which every built level does without error (checked) — the
        /// shells catch a load error as "the level could not be loaded", never a quit.
        case loadsClean = "loads clean"
        /// Not on a level frame: the type is never reached from `FrameRenderer` (checked by name).
        case offLevelFrame = "not on a level frame"
        /// Unreachable by the code's own construction (checked).
        case byConstruction = "by construction"
        /// Reachable only after the stated play time in one level (counter wrap).
        case timeBound = "time bound"
    }

    enum Check: Hashable {
        case writtenWordsDraw, untransformableNotTransformed, gaugeNotMirrored, mode5Seeded, facesLoaded, facesNarrow
        case noCopyAfterCopy, parallaxAttached, pxBackSlotsLoaded, lightBytesInRange, lightIndexInRange
        case headerFlame, headerRipple, levelsLoad, lightSlotsFit, tintDraws510, attachedBeforeApply, levelClut
        case deathSteps, waterTilesInSheet, levelOpsRouted, skippedOpsCannotThrow, ripplePhaseHours
        case rotationRanges, notNamedByLevelFrame(String)
    }

    struct Refusal {
        let file: String
        /// The thrown name (`Refusal.mode`, `failure`, `refuse`, …).
        let thrown: String
        let count: Int
        let reason: Reason
        let checks: [Check]
        let why: String
    }

    private static func R(_ file: String, _ thrown: String, _ count: Int, _ reason: Reason, _ checks: [Check],
                          _ why: String) -> Refusal {
        Refusal(file: file, thrown: thrown, count: count, reason: reason, checks: checks, why: why)
    }

    /// Every `throw` in `Sources/FerazelRender`, by file and thrown name, with its count.
    static let refusals: [Refusal] = [
        // SpriteBlitter (draw-effects §1–§2): the sprite pass.
        R("Frame/SpriteBlitter.swift", "Refusal.faceNotLoaded", 2, .dataAbsent, [.facesLoaded],
          "every face a Setup, the run or a class declares is loaded (BootFacesTests holds the whole set)"),
        R("Frame/SpriteBlitter.swift", "Refusal.diffuseSeed", 1, .noWriter, [.mode5Seeded],
          "every `.wrapDrawSprites` Core builds goes through `FerazelSession.diffuseSeeds`, which seeds each mode-5 draw"),
        R("Frame/SpriteBlitter.swift", "Refusal.mode", 11, .noWriter,
          [.writtenWordsDraw, .untransformableNotTransformed, .gaugeNotMirrored, .lightBytesInRange],
          "every written word draws (test 1): no writer of modes 2, 7, 8, 0xd, 0xe, ≥ 0xf; a 0xb arg's table read in "
          + "range; tint subs ≤ 24 (placements' p2 included); modes 5 / 0xa / 0xb never on a rotated or scaled "
          + "sprite, 0xa never mirrored; light index ≥ 0x6f000 needs F ≥ 126 (DK: F max 110); A14 (light byte −1 → "
          + "0xbff00 + F) needs a BG cell with light byte −1, none in a built level"),
        R("Frame/SpriteBlitter.swift", "Refusal.darkness", 1, .dataAbsent, [.lightBytesInRange],
          "mode 0xc's L is a light byte (0…15 on every built level, `applyDynamicLight`) or a Radial depth band 0…12"),
        R("Frame/SpriteBlitter.swift", "Refusal.translucency", 3, .byConstruction,
          [.parallaxAttached, .pxBackSlotsLoaded, .headerFlame, .facesNarrow, .noCopyAfterCopy],
          "the parallax is attached on every sprite pass; every PxBack cell's slot is loaded and no level has the "
          + "Fire backdrop; no face is over 301 px wide; `FaceEncoder` never emits a copy run after a copy run"),
        R("Frame/SpriteBlitter.swift", "failure", 1, .dataAbsent,
          [.lightBytesInRange, .lightIndexInRange, .ripplePhaseHours],
          "the light pass's carried refusals: darkness D is a light byte 0…15 on every built level; the light index "
          + "stays in the table (light-face pixels 0 or 0xf5…0xff, colours ≤ 99); the ripple phase (below)"),
        R("Frame/SpriteBlitter.swift", "Refusal.transform", 3, .byConstruction, [.facesNarrow],
          "every loaded face is ≤ 0x100 wide, so the 256-entry erase tables and `rotWalk`'s column tables hold it"),
        R("Frame/SpriteBlitter.swift", "Refusal.ripplePhase", 1, .timeBound, [.ripplePhaseHours],
          "the phase starts at 0x200 per level and grows by 0x100 a frame: negative only after 2^23 frames"),
        R("Frame/SpriteBlitter.swift", "Refusal.rotation", 2, .noWriter, [.rotationRanges],
          "every rotation writer stays in 0…359 (360 − r when mirrored is 1…359)"),
        // ParallaxBlitter (rendering-omnipx-titles §1.6): at level open.
        R("Frame/ParallaxBlitter.swift", "Refusal.fireVariant", 1, .headerZero, [.headerFlame],
          "header 0x2722 ≤ 0 on every built level (levels 52, 55 only)"),
        R("Frame/ParallaxBlitter.swift", "Refusal.ripple", 1, .headerZero, [.headerRipple],
          "header 0x26ca = 0 on every built level (levels 11, 18 only)"),
        // FrameRenderer.
        R("Frame/FrameRenderer.swift", "WorldDataError.missing", 1, .loadsClean, [.levelsLoad],
          "every built level's Mlvl is in the data"),
        R("Frame/FrameRenderer.swift", "Refusal.lightSlotsFull", 1, .dataAbsent, [.lightSlotsFit],
          "the Setup lights of every built level fit the 200 slots (the run's own adds included)"),
        R("Frame/FrameRenderer.swift", "Refusal.tintTableDraws", 1, .byConstruction, [.tintDraws510],
          "the session always takes `.BuildTintTable`'s 510 draws"),
        R("Frame/FrameRenderer.swift", "Refusal.deathEffectStep", 1, .byConstruction, [.deathSteps],
          "`LevelRun.deathEffect` asks k = 0…49 only"),
        R("Frame/FrameRenderer.swift", "Refusal.tintTableNotBuilt", 1, .byConstruction, [.attachedBeforeApply],
          "`LevelRun` attaches the lights and the tint table before its first level op"),
        R("Frame/FrameRenderer.swift", "Refusal.screenClut", 1, .byConstruction, [.levelClut],
          "`LevelRunOutput` routes `.setScreenClut` to the level renderer only for the level CLUT its tables use"),
        R("Effects/WaterFaceBlitter.swift", "FrameRenderer.Refusal.waterFaceTile", 1, .byConstruction,
          [.waterTilesInSheet], "Core hands tiles 0…0x5e (`WaterEffects`, tile < 0x5f, kind ≥ 0) and every FG-water "
          + "sheet holds them"),
        // The front end's renderers, the map, sound, the census: never on a level frame.
        R("Screens/ScreenRenderer.swift", "Refusal.levelOp", 17, .offLevelFrame, [.levelOpsRouted],
          "`LevelRunOutput.target` sends every level op to the level renderer"),
        R("Screens/MapRenderer.swift", "FaceSheetError.cellOutOfRange", 1, .offLevelFrame,
          [.notNamedByLevelFrame("MapRenderer")], "the world map's renderer"),
        R("Screens/MapRenderer.swift", "Refusal.unexpected", 2, .offLevelFrame,
          [.notNamedByLevelFrame("MapRenderer")], "the world map's renderer"),
        R("Audio/SoundBank.swift", "SoundBankError.unparsable", 1, .offLevelFrame,
          [.notNamedByLevelFrame("SoundBank")], "sound loading (the shells' mixer)"),
        R("Audio/SoundBank.swift", "SoundBankError.unexpectedFormat", 1, .offLevelFrame,
          [.notNamedByLevelFrame("SoundBank")], "sound loading"),
        R("Audio/SoundBank.swift", "SoundBankError.unexpectedModifierCount", 1, .offLevelFrame,
          [.notNamedByLevelFrame("SoundBank")], "sound loading"),
        R("Audio/SoundBank.swift", "SoundBankError.unexpectedCommandCount", 1, .offLevelFrame,
          [.notNamedByLevelFrame("SoundBank")], "sound loading"),
        R("Audio/SoundBank.swift", "SoundBankError.notOffsetBinary", 1, .offLevelFrame,
          [.notNamedByLevelFrame("SoundBank")], "sound loading"),
        R("Audio/MusicTrack.swift", "MusicTrackError.missing", 1, .offLevelFrame,
          [.notNamedByLevelFrame("MusicTrack")], "music loading (the shells' player)"),
        R("Audio/MusicTrack.swift", "MusicTrackError.notIMA4", 1, .offLevelFrame,
          [.notNamedByLevelFrame("MusicTrack")], "music loading"),
        R("Census/FerazelCensus.swift", "FerazelDataError.missing", 2, .offLevelFrame,
          [.notNamedByLevelFrame("FerazelCensus")], "the census tool"),
        R("Census/FerazelCensus.swift", "WorldDataError.missing", 3, .offLevelFrame,
          [.notNamedByLevelFrame("FerazelCensus")], "the census tool"),
        R("Census/FerazelCensus.swift", "PictureSourceError.unsupported", 1, .offLevelFrame,
          [.notNamedByLevelFrame("FerazelCensus")], "the census tool"),
        // The face, picture and light-face loaders: a level's set-up (renderer init, the Setup lights, a
        // `.changeLightFace`'s light face, PICT 129), which loads clean for every built level.
        R("Faces/BlendFaces.swift", "FaceDecodeError.truncated", 2, .loadsClean, [.levelsLoad], "face decode"),
        R("Faces/LightFaces.swift", "LightFaceError.scaled", 1, .loadsClean, [.levelsLoad], "light-face load"),
        R("Faces/PictureSource.swift", "PictureSourceError.undecodable", 1, .loadsClean, [.levelsLoad], "PICT load"),
        R("Faces/PictureSource.swift", "PictureSourceError.unsupported", 4, .loadsClean, [.levelsLoad], "PICT load"),
        R("Faces/PictureSource.swift", "PictureSourceError.missing", 1, .loadsClean, [.levelsLoad], "PICT load"),
        R("Faces/EncodedFace.swift", "FaceDecodeError.malformed", 6, .loadsClean, [.levelsLoad], "face decode"),
        R("Faces/EncodedFace.swift", "FaceDecodeError.truncated", 2, .loadsClean, [.levelsLoad], "face decode"),
        R("Faces/EncodedFace.swift", "FaceDecodeError.badToken", 1, .loadsClean, [.levelsLoad], "face decode"),
        R("Faces/ConvertedPicture.swift", "ConvertedPictureError.pixelCountMismatch", 1, .loadsClean, [.levelsLoad],
          "picture conversion"),
        R("Faces/ConvertedPicture.swift", "ConvertedPictureError.noColorTableEntry", 2, .loadsClean, [.levelsLoad],
          "picture conversion"),
        R("Faces/FaceEncoder.swift", "FaceEncodeError.pixelCountMismatch", 1, .loadsClean, [.levelsLoad],
          "face encode"),
        R("Faces/FaceEncoder.swift", "FaceEncodeError.rectTooLarge", 1, .loadsClean, [.levelsLoad], "face encode"),
        R("Faces/TileSets.swift", "PictureSourceError.missing", 1, .loadsClean, [.levelsLoad], "tile-set load"),
        R("Faces/FaceSheet.swift", "refuse", 6, .loadsClean, [.levelsLoad], "face-set arguments"),
        R("Faces/FaceSheet.swift", "FaceSheetError.cellOutOfRange", 1, .loadsClean, [.levelsLoad], "face-set load"),
        R("Faces/FaceSheet.swift", "FaceSheetError.singleFrameNotAtOrigin", 1, .loadsClean, [.levelsLoad],
          "face load"),
    ]

    /// Every `throw <name>` in FerazelRender: (file, name) → count.
    private static func scannedThrows() throws -> [String: Int] {
        var out: [String: Int] = [:]
        for l in try renderLines.get() {
            let c = Array(l.code)
            let pat = Array("throw ")
            var i = 0
            while i + pat.count <= c.count {
                defer { i += 1 }
                guard Array(c[i..<(i + pat.count)]) == pat, i == 0 || !isWord(c[i - 1]) else { continue }
                var j = i + pat.count, name = ""
                while j < c.count && (isWord(c[j]) || c[j] == ".") { name.append(c[j]); j += 1 }
                out["\(l.file) \(name)", default: 0] += 1
            }
        }
        return out
    }

    // MARK: - testEveryRefusalIsUnreachable

    func testEveryRefusalIsUnreachable() throws {
        let scanned = try Self.scannedThrows()
        let table = Dictionary(Self.refusals.map { ("\($0.file) \($0.thrown)", $0.count) }, uniquingKeysWith: +)
        XCTAssertEqual(table.count, Self.refusals.count, "a refusal row twice")
        for (key, n) in scanned.sorted(by: { $0.key < $1.key }) where table[key] != n {
            XCTFail("throw \(key): \(n) in the source, \(table[key].map(String.init) ?? "no row") in the table")
        }
        for key in table.keys.sorted() where scanned[key] == nil { XCTFail("row \(key): no such throw in the source") }
        XCTAssertEqual(scanned.values.reduce(0, +), Self.refusals.map(\.count).reduce(0, +))

        let audits = try Self.audits.get()
        var checks: [Check] = []
        for r in Self.refusals { for c in r.checks where !checks.contains(c) { checks.append(c) } }
        for c in checks { try check(c, audits) }
    }

    /// One reason, checked by code.
    private func check(_ c: Check, _ audits: [Audit]) throws {
        let res = try Self.resources.get()
        let core = try Self.coreLines.get(), render = try Self.renderLines.get()
        switch c {
        case .writtenWordsDraw:
            for f in try Self.drawn.get() { XCTAssertTrue(f.isEmpty, "\(c): \(f.prefix(5))") }
        case .untransformableNotTransformed:
            // Modes the transformed blitters have no table for, on a sprite some rotation / scale row writes.
            let transformed = Set(Self.writers.filter { w in
                guard w.input == .rotation || w.input == .scale, case .range(let r) = w.values else { return false }
                return r != (0...0) && r != (0x100...0x100)
            }.flatMap(\.who))
            for a in audits {
                for w in Self.writers where w.input == .mode {
                    let modes = Set(Self.words(w.values, a.level).map(Self.modeOf))
                    guard !modes.isSubset(of: Self.transformSafe) else { continue }
                    for who in w.who where transformed.contains(who) {
                        XCTFail("\(c): \(w.site) writes modes \(modes.sorted()) on \(who), which a row rotates or scales")
                    }
                }
            }
            // The hovering rock (`box.boulder.hover`, `+0x160 < 0`) is a state no boulder reaches: `+0x160`
            // (`classWord160`, also named `stepX`) is set only by `PlayerShot.setup` (0 or 10, on shots) and counted
            // up only inside the hover branch itself (`BoxSprite.boulder`) — never made negative.
            var writes: [String] = []
            for l in core where !Self.assignedFields(l.code, ["classWord160", "stepX"]).isEmpty {
                writes.append("\(l.file) \(l.code.trimmingCharacters(in: .whitespaces))")
            }
            XCTAssertEqual(writes.sorted(), ["Shots/PlayerShot.swift s.stepX = sx",
                                             "World/Movers/BoxSprite.swift s.classWord160 &+= 1"], "\(c): +0x160 writers")
        case .gaugeNotMirrored:
            let mirrored = Set(Self.writers.filter { w in
                guard w.input == .mirrored else { return false }
                if case .flags(let f) = w.values { return f.contains(true) }
                return true
            }.flatMap(\.who))
            for w in Self.writers where w.input == .mode {
                guard case .wordRange(let r) = w.values, Self.modeOf(r.lowerBound) == 0xa else { continue }
                for who in w.who { XCTAssertFalse(mirrored.contains(who), "\(c): \(who) is mirrored and carries mode 0xa") }
            }
        case .mode5Seeded:
            var built = 0
            for l in core where l.code.contains(".wrapDrawSprites(") {
                built += 1
                XCTAssertTrue(l.code.contains(".wrapDrawSprites(diffuseSeeds("), "\(c): \(l.file):\(l.line)")
            }
            XCTAssertGreaterThan(built, 0)
            for a in audits { XCTAssertEqual(a.seen.mode5Unseeded, 0, "\(c): level \(a.level.number)") }
        case .facesLoaded:
            for a in audits {
                let faces = a.level.renderer.sprites.faces
                for e in a.setups {
                    if let f = e.slot.face { XCTAssertNotNil(faces.face(f), "\(c): level \(a.level.number) \(f)") }
                }
                XCTAssertTrue(a.seen.refusals.allSatisfy { !$0.contains("faceNotLoaded") })
            }
        case .facesNarrow:
            for a in audits {
                for (pict, s) in a.level.renderer.sprites.faces.sheets {
                    for f in s.faces { XCTAssertLessThanOrEqual(f.width, 0x100, "\(c): PICT \(pict)") }
                }
            }
        case .noCopyAfterCopy:
            for a in audits {
                for (pict, s) in a.level.renderer.sprites.faces.sheets {
                    for f in s.faces {
                        var p = 0, last: UInt8 = 0, bad = 0
                        while p + 4 <= f.data.count {
                            let tok = f.data[p]
                            let n = Int(f.data[p + 1]) << 16 | Int(f.data[p + 2]) << 8 | Int(f.data[p + 3])
                            p += 4
                            if tok == 0 { break }
                            if tok == 2 {
                                if last == 2 { bad += 1 }
                                p += (n + 3) & ~3
                            }
                            last = tok
                        }
                        XCTAssertEqual(bad, 0, "\(c): PICT \(pict)")
                    }
                }
            }
        case .parallaxAttached:
            let lines = render.filter { $0.file == "Frame/FrameRenderer.swift" }
            XCTAssertTrue(lines.contains { $0.code.contains("sprites.parallax = parallax") }, "\(c)")
        case .pxBackSlotsLoaded:
            for a in audits {
                let L = a.level.file, p = a.level.renderer.parallax
                XCTAssertGreaterThanOrEqual(L.header.pxBackYFactor, 0, "\(c): level \(a.level.number) yb")
                for row in 0..<L.pxBack.height {
                    for col in 0..<L.pxBack.width {
                        let slot = ParallaxBlitter.backBase + L.pxBackTile(col: col, row: row)
                        XCTAssertTrue((0..<ParallaxBlitter.slotCount).contains(slot) && p.slotLoaded[slot],
                                      "\(c): level \(a.level.number) PxBack (\(col), \(row)) slot \(slot)")
                    }
                }
                XCTAssertTrue(p.slotLoaded[ParallaxBlitter.backBase], "\(c): slot 0 (OmniPx's `.GetPxBackTile` 0)")
            }
        case .lightBytesInRange:
            // `.GetLightTile` over every cell (the reads clamp to the grid): D for the light pass, L for the dynamic
            // light — 0…15 (the ambient rows), so no darkness refusal and no A14 word 0xbff00 + F.
            for a in audits {
                let ambient = a.level.renderer.tables.ambient.count
                for b in a.level.lightBytes {
                    XCTAssertTrue((0..<ambient).contains(b), "\(c): level \(a.level.number) light byte \(b)")
                }
            }
        case .lightIndexInRange:
            // `lightBlit`: light[D·0x6e00 + (p + colour − 0xf5)·0x100 + d] with D 0…15 needs p + colour − 0xf5 in
            // 0…109 — light-face pixels 0 (ambient) or 0xf5…0xff and colours 0…99 (DK: every colour writer ≤ 99).
            for site in LightFace.callSites {
                let f = try LightFace.load(pict: site.pict, width: site.width, height: site.height, from: res,
                                           search: Self.search)
                for p in Set(f.pixels) { XCTAssertTrue(p == 0 || p >= 0xf5, "\(c): light face \(site.pict) pixel \(p)") }
            }
            for a in audits {
                let setup = Set(a.setups.compactMap { $0.light?.colour })
                for colour in setup.union(a.seen.lightColours.map(Int.init)) {
                    XCTAssertTrue((0...99).contains(colour), "\(c): level \(a.level.number) colour \(colour)")
                }
            }
        case .headerFlame:
            for a in audits { XCTAssertLessThanOrEqual(a.level.file.header.flameMode, 0, "\(c): \(a.level.number)") }
        case .headerRipple:
            for a in audits { XCTAssertEqual(a.level.file.header.parallaxRipple, 0, "\(c): \(a.level.number)") }
        case .levelsLoad:
            // Every built level's renderer was built (faces, tile sets, tables, parallax, status bar), its Setup lights
            // and tint table attached and PICT 129 drawn by the run; every `.Load1LightFaceFromPICT` site loads.
            XCTAssertEqual(audits.map(\.level.number), Array(BuiltLevels.range))
            for a in audits { XCTAssertTrue(a.seen.refusals.isEmpty, "\(c): level \(a.level.number) \(a.seen.refusals)") }
            for site in LightFace.callSites {
                XCTAssertNoThrow(try LightFace.load(pict: site.pict, width: site.width, height: site.height, from: res,
                                                    search: Self.search), "\(c): \(site)")
            }
        case .lightSlotsFit:
            for a in audits {
                XCTAssertLessThan(a.setups.compactMap(\.light).count, LightTable.slotCount, "\(c): \(a.level.number)")
            }
        case .tintDraws510:
            for a in audits { XCTAssertEqual(a.seen.tintDraws, [0xff * 2], "\(c): level \(a.level.number)") }
        case .attachedBeforeApply:
            for a in audits {
                XCTAssertTrue(a.level.renderer.tintTableBuilt, "\(c): level \(a.level.number)")
                XCTAssertFalse(a.seen.refusals.contains { $0.contains("tintTableNotBuilt") })
            }
        case .levelClut:
            for a in audits {
                XCTAssertEqual(a.level.renderer.tables.screenClutId, ColorLUT.screenClutId(a.level.file.header),
                               "\(c): level \(a.level.number)")
            }
            XCTAssertEqual(LevelRunOutput.target(of: .setScreenClut(id: 281), levelClut: 202, owner: .level), .screen)
        case .deathSteps:
            XCTAssertEqual(DeathEffect.steps, 50)
            let lines = core.filter { $0.file == "Front/LevelRun.swift" && $0.code.contains("while deathStep < ") }
            XCTAssertEqual(lines.map { $0.code.trimmingCharacters(in: .whitespaces) }, ["while deathStep < 50 {"])
            for a in audits { XCTAssertTrue(a.seen.deathSteps.allSatisfy { (0..<50).contains($0) }) }
        case .waterTilesInSheet:
            XCTAssertTrue(core.contains { $0.file == "Particles/WaterEffects.swift"
                && $0.code.contains("if tile < 0x5f && e.isWater != 0") }, "\(c): the tile guard")
            for a in audits {
                let n = a.level.renderer.grid.sets.fgWater.sheet.faces.count
                XCTAssertGreaterThanOrEqual(n, 0x5f, "\(c): level \(a.level.number)")
                for t in a.seen.waterFaces { XCTAssertTrue((0..<0x5f).contains(t), "\(c): tile \(t)") }
            }
        case .levelOpsRouted:
            let levelOps: [DrawOp] = [
                .redrawScrollGrid(h: 0, v: 0), .redrawEntireScrollGrid(h: 0, v: 0), .setDrawnScroll(h: 0, v: 0),
                .drawLightsOntoTiles, .wrapDrawSprites([]), .copyToScreen(h: 0, v: 0, graphicsMode: 1, backdrop: true),
                .copyMaskToScreen(h: 0, v: 0, graphicsMode: 1, backdrop: true), .mosaic(cell: 2, graphicsMode3: false),
                .changeLightFace(slot: 0, pict: 0x32a, width: 0x48, height: 0x48), .lightTable(LightTable()),
                .wrapEraseSprites(sprites: [], h: 0, v: 0), .statusBar(StatusBarState()), .setTile(col: 0, row: 0, fg: 0),
                .wrapDrawWaterEffects([]), .drawParticles([]), .eraseParticles, .drawBlackLines,
            ]
            XCTAssertEqual(levelOps.count, 17)
            for op in levelOps {
                for owner in [LevelRunTarget.level, .screen] {
                    XCTAssertEqual(LevelRunOutput.target(of: op, levelClut: 202, owner: owner), .level, "\(c): \(op)")
                }
            }
            for a in audits { XCTAssertEqual(a.seen.levelOpsOffLevel, [], "\(c): level \(a.level.number)") }
        case .skippedOpsCannotThrow:
            // Each skipped op's arm in `FrameRenderer.apply` (from its `case .<op>` to the next line indented no
            // deeper) holds no `try`.
            let lines = render.filter { $0.file == "Frame/FrameRenderer.swift" }
            func indent(_ s: String) -> Int { s.prefix { $0 == " " }.count }
            for op in Self.skippedOps {
                var arms = 0
                for (i, l) in lines.enumerated() {
                    let t = l.code.trimmingCharacters(in: .whitespaces)
                    guard t.hasPrefix("case ." + op + "(") || t.hasPrefix("case ." + op + ":")
                            || t.hasPrefix("case ." + op + " ") || t.hasPrefix("case ." + op + ",") else { continue }
                    arms += 1
                    let d = indent(l.code)
                    XCTAssertFalse(l.code.contains("try "), "\(c): \(op) at line \(l.line)")
                    for m in lines[(i + 1)...] {
                        let u = m.code.trimmingCharacters(in: .whitespaces)
                        if !u.isEmpty && indent(m.code) <= d { break }
                        XCTAssertFalse(m.code.contains("try "), "\(c): \(op)'s arm, line \(m.line)")
                    }
                }
                XCTAssertGreaterThan(arms, 0, "\(c): no `case .\(op)` arm")
            }
        case .ripplePhaseHours:
            // 0x200 + 0x100·k stays non-negative for k < 2^23 − 2 frames: over 77 hours at 30 frames a second in one
            // level (a level start resets it: one renderer per level start).
            XCTAssertEqual(SpriteBlitter(level: audits[0].level.file, tables: audits[0].level.renderer.tables,
                                         faces: SpriteBlitter.Faces(sheets: [:])).ripplePhase, 0x200)
            let frames = (Int(Int32.max) - 0x200) / 0x100
            XCTAssertGreaterThanOrEqual(frames / 30 / 3600, 77)
        case .rotationRanges:
            for w in Self.writers where w.input == .rotation {
                guard case .range(let r) = w.values else { XCTFail("\(c): \(w.site)"); continue }
                XCTAssertTrue(r.lowerBound >= 0 && r.upperBound <= 359, "\(c): \(w.site)")
            }
        case .notNamedByLevelFrame(let type):
            // The level frame's code — `FrameRenderer` and what it calls (Frame/, Effects/, Faces/, Color/) — never
            // names the type.
            for l in render where ["Frame/", "Effects/", "Faces/", "Color/"].contains(where: { l.file.hasPrefix($0) }) {
                XCTAssertFalse(l.code.contains(type), "\(c): \(l.file):\(l.line)")
            }
        }
    }
}
