import XCTest
@testable import FerazelCore
@testable import FerazelRender

/// DA (docs/plans/2026-10-30-ferazel-phase5.md, Q15 item 2; Invariant 8, Ruling 6): the standing draw-mode audit.
///
/// 1. `testEveryWrittenModeIsDrawable` — for every level in `BuiltLevels.range`, every draw input Core can write
///    (`SpriteDraw` mode word, rotation, scale, mirror, the dynamic-light byte case, water kind, clip, backdrop mode,
///    OmniPx mode) is drawn by `SpriteBlitter` / `FrameRenderer` with no refusal: every value of every row of
///    `writers` (one row per writer site in `Sources/FerazelCore`, file:line — a source scan fails on a writer without
///    a row, or a row whose line no longer writes; each row's values are checked against the literals and pins of
///    the lines it cites), under every transform the renderer builds for it, on screen (each probe reaches its mode
///    read — a non-empty window in view, proved by a control word's refusal); every clip edge value of the clip rows;
///    each placement's Setup (run once, moved to (100, 100)); and a 2,000-step scripted run of the level through
///    `LevelRun` + `FrameRenderer`, whose every drawn value must also be one the table names.
/// 2. `testEveryRefusalIsUnreachable` — every `throw` in `Sources/FerazelRender` and in `Sources/FerazelCore` (what a
///    level frame can propagate; counted per file and thrown name; a new throw without a row fails) with the reason it
///    cannot be reached on a level frame of a built level, each reason checked by code (the writer table, the data,
///    the level headers, the routing, the combinations' guards in the source).
///
/// **Maintained by every task** that adds a writer of a draw input or a Core / renderer throw (Invariant 8): add its
/// row here in the same task. When a row's line moves, the failure prints the scanned `file:line` to paste.
///
/// Proof B runs this file under Wine: the source scan walks directories with `contentsOfDirectory` /
/// `fileExists(atPath:isDirectory:)` and matches in pure Swift (as `BootFacesTests`) — no directory enumerator, no
/// regex, no file attributes, no Foundation substring search or trim (`contains(String)`, `trimmingCharacters` trap
/// under Wine: `has` / `trim` below) — and the class is not main-actor isolated. A missing data file is a FAILURE.
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

    /// Whether `code` holds `sub`: a plain UTF-8 search (Foundation's `contains(String)` traps under Wine).
    static func has(_ code: String, _ sub: String) -> Bool {
        let c = Array(code.utf8), p = Array(sub.utf8)
        guard !p.isEmpty else { return true }
        guard c.count >= p.count else { return false }
        for i in 0...(c.count - p.count) where c[i] == p[0] {
            var k = 1
            while k < p.count && c[i + k] == p[k] { k += 1 }
            if k == p.count { return true }
        }
        return false
    }

    /// The openers enclosing `lines[i]`, innermost first (trimmed): each line above it indented less than the last.
    static func enclosing(_ lines: [SourceLine], _ i: Int) -> [String] {
        func indent(_ s: String) -> Int { s.prefix { $0 == " " }.count }
        var depth = indent(lines[i].code), out: [String] = []
        var k = i - 1
        while k >= 0 && depth > 0 {
            let t = trim(lines[k].code)
            if !t.isEmpty && indent(lines[k].code) < depth {
                out.append(t)
                depth = indent(lines[k].code)
            }
            k -= 1
        }
        return out
    }

    /// `code` without its leading and trailing spaces and tabs (no Foundation trim).
    static func trim(_ code: String) -> String {
        var s = Substring(code)
        while let f = s.first, f == " " || f == "\t" { s.removeFirst() }
        while let l = s.last, l == " " || l == "\t" { s.removeLast() }
        return String(s)
    }

    /// The fields of `code` assigned as `.<field> <op>` (op `=`, `+=`, `-=`, `&+=`, `&-=`, `|=`, `&=`; not `==`), any
    /// spacing (`s.mode=0x20000` too).
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
                guard j == c.count || (!isWord(c[j]) && c[j] != ".") else { continue }
                while j < c.count && (c[j] == " " || c[j] == "\t") { j += 1 }
                for op in ["&+=", "&-=", "+=", "-=", "|=", "&=", "="] {
                    let o = Array(op)
                    guard j + o.count <= c.count, Array(c[j..<(j + o.count)]) == o,
                          j + o.count == c.count || c[j + o.count] != "=" else { continue }
                    out.append(f)
                    break
                }
            }
        }
        return out
    }

    // MARK: - The writer table (Invariant 8: one row per writer site, kept by every task that adds one)

    /// The draw inputs Core writes (the clip edges as `clip.<edge>`; `clip` a whole-struct write). The face (`FaceRef`)
    /// is not a row: every face a sprite can be given must be loaded, and that is `Check.facesLoaded` (each Setup's
    /// face, every face the scripted run draws, no `faceNotLoaded` refusal) with BootFacesTests' whole-set census.
    enum Input: String, Sendable, CaseIterable {
        case mode, rotation, scale, mirrored, flash, flashTable, waterKind, clip
        case clipTop = "clip.top", clipLeft = "clip.left", clipBottom = "clip.bottom", clipRight = "clip.right"
    }

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
        /// A clip edge 0…the drawn face's width (an occluder's edge, clamped to the face).
        case faceWidth
    }

    struct Writer: Sendable {
        let site: String
        let input: Input
        let values: Values
        /// The sprites the site writes (for the combinations the renderer refuses by design).
        let who: [String]
        /// The lines (besides the site's) whose literals give the values — `N` in the site's file or `file:N` — when the
        /// site assigns a variable (`checkSources`).
        let at: [String]
        /// Code the cited lines must hold: the constants a range or derived value is computed from (`checkSources`).
        let pins: [String]
    }

    private static func W(_ site: String, _ input: Input, _ values: Values, _ who: String..., at: [String] = [],
                          pins: [String] = []) -> Writer {
        Writer(site: site, input: input, values: values, who: who, at: at, pins: pins)
    }

    /// The scanned files and fields whose writes are not a sprite draw input, with the reason.
    static let notDrawInputs: [(file: String, field: Input, why: String)] = [
        ("Particles/ParticlePool.swift", .mode, "a particle record's erase mode (`ParticleRenderer`, no refusal)"),
        ("Session/FerazelSession.swift", .flash, "`world.flash` / `LevelCarry.flash`: the screen flash, not +0xaa"),
    ]

    static let dynamicLit = ["platform.raft", "box.boulder", "background.maceBall", "chain.maceChain"]

    static let writers: [Writer] = [
        W("Items/HeldItem.swift:111", .mirrored, .copy, "heldItem"),
        W("Particles/WaterEffects.swift:144", .waterKind, .levelLiquid, "waterFace", pins: ["UnderWater.waterKind("]),
        // EC: the burn-away's top clip (`.HandleBurn` `+0x1bc = +0x1a2`: from the opaque top, one row or `+0x8d + 1` a
        // frame, up to one past the opaque bottom — any face's height; a top past the face draws nothing).
        W("Particles/Burn.swift:60", .clipTop, .range(1...0x100), "any", at: ["45", "50"],
          pins: ["s.burnRow = top", "s.burnRow &+= 1"]),
        // EC: the ground enemies' liquid hurt flash (`EnemyCommon.liquids`: 0xc for the Walker in water, else 0x11).
        W("World/Enemies/EnemyCommon.swift:248", .flash, .range(0xc...0x11), "walker", "crawler", "roach", "dillo",
          "blob", at: ["233", "238", "239", "240"], pins: ["(0xc, 0x96, 0xc)", "(0x13, 100, 0x11)"]),
        // ES: the enemy shots — the egg's random facing (`R(100) > 0x32`) and its flash every 45 frames, the Warrior
        // shot's facing by vx, the Wraith shot's tint by age (`.HandleEnemyShotSprite` M l. 51711–51723).
        // BA: the Bat class — the spitters' tint 0x1000c (0x6ce / 0x73c retyped), the insects' 0xb0004, the swarm
        // centre's 0x10009 (it has no face), the chasers' facing and the path bats' (by vx in mode 2, else the player's
        // side), the members' facing by the player's side, the insect body's copies of its head's flip and bottom clip,
        // the liquid hurt flash 0x11 (`.HandleBatSprite` M l. 68527–68540).
        W("World/Enemies/Bat.swift:117", .mode, .words([0x1000c]), "bat"),
        W("World/Enemies/Bat.swift:141", .mode, .words([0x1000c]), "bat"),
        W("World/Enemies/Bat.swift:200", .mode, .words([0xb0004]), "bat.insect"),
        W("World/Enemies/Bat.swift:354", .mode, .words([0x10009]), "bat.swarm"),
        W("World/Enemies/Bat.swift:258", .mirrored, .copy, "bat.insectBody"),
        // The head's bottom clip is `.StandardSpriteHandles`' 32000 (no Bat routine or pipe child writes another yet).
        W("World/Enemies/Bat.swift:259", .clipBottom, .range(32000...32000), "bat.insectBody",
          at: ["Physics/StandardSprite.swift:36"]),
        W("World/Enemies/Bat.swift:306", .mirrored, .flags([true]), "bat"),
        W("World/Enemies/Bat.swift:308", .mirrored, .flags([false]), "bat"),
        W("World/Enemies/Bat.swift:317", .mirrored, .flags([true]), "bat"),
        W("World/Enemies/Bat.swift:320", .mirrored, .flags([false]), "bat"),
        W("World/Enemies/Bat.swift:330", .flash, .range(0x11...0x11), "bat"),
        W("World/Enemies/Bat.swift:384", .mirrored, .flags([false, true]), "bat"),
        W("World/Enemies/Bat.swift:623", .mirrored, .flags([false, true]), "bat.swarmMember"),
        // FR: the Frog's p1 tints (`.SetupFrogSprite` M l. 70185–70206) and its spit's (M l. 70292–70315), the dead
        // water blocks' hurt flash 0x11 (M l. 70261, 70731), both classes' facing by the player's side.
        W("World/Enemies/FrogSalamander.swift:88", .mode, .words([0]), "frog"),
        W("World/Enemies/FrogSalamander.swift:89", .mode, .words([0x1000c]), "frog"),
        W("World/Enemies/FrogSalamander.swift:90", .mode, .words([0x10017]), "frog"),
        W("World/Enemies/FrogSalamander.swift:91", .mode, .words([0x1000f]), "frog"),
        W("World/Enemies/FrogSalamander.swift:92", .mode, .words([0x1000b]), "frog"),
        W("World/Enemies/FrogSalamander.swift:160", .flash, .range(0x11...0x11), "frog"),
        W("World/Enemies/FrogSalamander.swift:271", .mirrored, .flags([false, true]), "frog"),
        W("World/Enemies/FrogSalamander.swift:318", .mode, .words([0x1000f]), "enemyShot.frogSpit"),
        W("World/Enemies/FrogSalamander.swift:322", .mode, .words([0x1000c]), "enemyShot.frogSpit"),
        W("World/Enemies/FrogSalamander.swift:324", .mode, .words([0x10017]), "enemyShot.frogSpit"),
        W("World/Enemies/FrogSalamander.swift:326", .mode, .words([0x1000b]), "enemyShot.frogSpit"),
        W("World/Enemies/FrogSalamander.swift:361", .flash, .range(0x11...0x11), "salamander"),
        W("World/Enemies/FrogSalamander.swift:398", .mirrored, .flags([false, true]), "salamander"),
        W("World/Enemies/FrogSalamander.swift:443", .mirrored, .flags([false, true]), "salamander"),
        // BL: the Blob's type tints (`.SetupBlobSprite` M l. 67699–67718), its facing by the player's side and state 6's
        // face-left (M l. 67792–67797, 67886), the dead puddle's flash reset and translucency steps (`.HandleDeadBlobSprite`
        // M l. 67744, 67749–67757); the Crab's water tint on the claw and the links (`.SetupCrabSprite` M l. 74054–74065),
        // the 0x763's flip and the claw's face rotation, the angle wrapped into 0…359 (`.HandleCrabSprite` M l.
        // 74230–74256).
        W("World/Enemies/BlobCrab.swift:66", .mode, .words([0x1000c]), "blob"),
        W("World/Enemies/BlobCrab.swift:67", .mode, .words([0]), "blob"),
        W("World/Enemies/BlobCrab.swift:68", .mode, .words([0x10004]), "blob"),
        W("World/Enemies/BlobCrab.swift:69", .mode, .words([0x1000f]), "blob"),
        W("World/Enemies/BlobCrab.swift:113", .mirrored, .flags([true]), "blob"),
        W("World/Enemies/BlobCrab.swift:115", .mirrored, .flags([false]), "blob"),
        W("World/Enemies/BlobCrab.swift:197", .mirrored, .flags([false]), "blob"),
        W("World/Enemies/BlobCrab.swift:245", .flash, .range(0...0), "blob.dead"),
        W("World/Enemies/BlobCrab.swift:248", .mode, .words([0xb0001]), "blob.dead"),
        W("World/Enemies/BlobCrab.swift:249", .mode, .words([0xb0000]), "blob.dead"),
        W("World/Enemies/BlobCrab.swift:250", .mode, .words([0xb0002]), "blob.dead"),
        W("World/Enemies/BlobCrab.swift:368", .mode, .words([0x90000]), "crab"),
        W("World/Enemies/BlobCrab.swift:392", .mode, .words([0x90000]), "crab.link"),
        W("World/Enemies/BlobCrab.swift:479", .mirrored, .flags([true]), "crab"),
        W("World/Enemies/BlobCrab.swift:480", .rotation, .range(0...359), "crab", at: ["473", "475"],
          pins: ["(Int(s.phase) + 0xb4) % 0x168", "s.phase &+= 0x168", "s.phase &-= 0x168"]),
        W("World/Enemies/BlobCrab.swift:482", .rotation, .range(0...359), "crab", at: ["473", "475"],
          pins: ["s.rotation = s.phase", "s.phase &+= 0x168", "s.phase &-= 0x168"]),
        // GF: the Gremlin — the back layer's 0xb0000 (`.SetupGremlinSprite` M l. 69214), the body's dead water flash
        // 0x11, its facing by the player's side or (path mode 2) by vx, the back layer's and the mounted rider's copies
        // of the body's facing, flash, tint and burn row (the rider's less 0x1b; M l. 69395–69420); the rider's shot's
        // flip and face rotation 0xdc / 0x140 (M l. 69611–69617). The Wraith: its facing, the fade-in / fade-out tints
        // 0xb0002 / 0xb0000 / 0xb0001 and 0, the hurt flash 10 (`.HandleFloaterSprite` M l. 69916–70020,
        // `.HitFloaterSprite` M l. 70058).
        W("World/Enemies/GremlinFloater.swift:113", .mode, .words([0xb0000]), "gremlin.back"),
        W("World/Enemies/GremlinFloater.swift:192", .flash, .range(0x11...0x11), "gremlin"),
        W("World/Enemies/GremlinFloater.swift:207", .mirrored, .flags([true]), "gremlin"),
        W("World/Enemies/GremlinFloater.swift:209", .mirrored, .flags([false]), "gremlin"),
        W("World/Enemies/GremlinFloater.swift:242", .mirrored, .flags([false, true]), "gremlin"),
        W("World/Enemies/GremlinFloater.swift:266", .mirrored, .copy, "gremlin.back"),
        W("World/Enemies/GremlinFloater.swift:268", .clipTop, .range(0...0x100), "gremlin.back",
          at: ["Particles/Burn.swift:60", "Physics/StandardSprite.swift:34"], pins: ["c.clip.top = t.clip.top", "s.clip.top = Int(s.burnRow)", "s.clip.top = 0"]),
        W("World/Enemies/GremlinFloater.swift:273", .mirrored, .copy, "gremlin.rider"),
        W("World/Enemies/GremlinFloater.swift:274", .flash, .copy, "gremlin.rider"),
        W("World/Enemies/GremlinFloater.swift:275", .mode, .copy, "gremlin.rider"),
        W("World/Enemies/GremlinFloater.swift:276", .clipTop, .range(1...0x100 - 0x1b), "gremlin.rider",
          at: ["Particles/Burn.swift:60"], pins: ["if 0x1b < t.clip.top { c.clip.top = t.clip.top - 0x1b }", "s.clip.top = Int(s.burnRow)"]),
        W("World/Enemies/GremlinFloater.swift:474", .mirrored, .flags([true]), "enemyShot.spit"),
        W("World/Enemies/GremlinFloater.swift:475", .rotation, .range(0xdc...0xdc), "enemyShot.spit"),
        W("World/Enemies/GremlinFloater.swift:477", .rotation, .range(0x140...0x140), "enemyShot.spit"),
        W("World/Enemies/GremlinFloater.swift:695", .mirrored, .flags([false, true]), "floater"),
        W("World/Enemies/GremlinFloater.swift:713", .mode, .words([0xb0002, 0xb0000, 0xb0001]), "floater"),
        W("World/Enemies/GremlinFloater.swift:716", .mode, .words([0]), "floater"),
        W("World/Enemies/GremlinFloater.swift:726", .mode, .words([0xb0001, 0xb0000, 0xb0002]), "floater"),
        W("World/Enemies/GremlinFloater.swift:729", .mode, .words([0]), "floater"),
        W("World/Enemies/GremlinFloater.swift:733", .mode, .words([0]), "floater"),
        W("World/Enemies/GremlinFloater.swift:781", .flash, .range(10...10), "floater"),
        // DL: the Dillo — 1871's grey tint 0x1000b (`.SetupDilloSprite` M l. 72340), its facing draw (M l. 72368), the
        // walk's turn at the bounds (M l. 72595–72601) and the roll's facing by the player's side (M l. 72522–72524); the
        // roll's spin angle `+0x1aa` ± 15 a frame, wrapped into 0…359, and its clear in the uncurl (M l. 72635, 72723–72739);
        // the spines' `+0xb8` 0 / 0x1000b (`.ShootSpines` M l. 72400–72409) and the 1871 egg's 0x1000b (M l. 72696).
        W("World/Enemies/Dillo.swift:70", .mode, .words([0x1000b]), "dillo"),
        W("World/Enemies/Dillo.swift:92", .mirrored, .flags([false, true]), "dillo"),
        W("World/Enemies/Dillo.swift:162", .mirrored, .flags([false]), "dillo"),
        W("World/Enemies/Dillo.swift:164", .mirrored, .flags([true]), "dillo"),
        W("World/Enemies/Dillo.swift:222", .rotation, .range(0...0), "dillo"),
        W("World/Enemies/Dillo.swift:305", .mode, .words([0x1000b]), "enemyShot.egg"),
        W("World/Enemies/Dillo.swift:325", .rotation, .range(0...359), "dillo", at: ["320", "323"],
          pins: ["s.rotation = Int16(truncatingIfNeeded: a)", "a = h16(a - 0x168)", "a = h16(a + 0x168)"]),
        W("World/Enemies/Dillo.swift:354", .mode, .words([0, 0x1000b]), "enemyShot.spine", at: ["337"],
          pins: ["let mode: UInt32 = walker ? 0 : 0x1000b"]),
        W("World/Enemies/Dillo.swift:394", .mirrored, .flags([false, true]), "dillo"),
        W("World/Enemies/EnemyShot.swift:154", .mirrored, .flags([false, true]), "enemyShot.egg"),
        W("World/Enemies/EnemyShot.swift:314", .mode, .words([0xb0002, 0xb0000, 0xb0001, 0]), "enemyShot.wraith"),
        W("World/Enemies/EnemyShot.swift:339", .mirrored, .flags([false, true]), "enemyShot.warrior"),
        W("World/Enemies/EnemyShot.swift:348", .flash, .range(5...5), "enemyShot.egg"),
        // WK1: the Walker — `.SetupWalkerSprite`'s flip (0x6e0 always, the others by the player's x) and tier tint
        // (`+0xb8` 0x10010…0x10015 by record p3), the 1700's facing, the 1705's turn, the 1760 death entry's inverted
        // flip, and the damaging-surface flash 0x12.
        // CR: the Crawler's tier tint (`+0xb8` by record p2: 0, 0x10002, 0x10003, 0x1000f) and its facing by the
        // player's x; the Roach's patrol facing.
        W("World/Enemies/CrawlerRoach.swift:71", .mode, .words([0, 0x10002, 0x10003, 0x1000f]), "crawler",
          at: ["90", "91", "92", "93"]),
        W("World/Enemies/CrawlerRoach.swift:248", .mirrored, .flags([true]), "crawler"),
        W("World/Enemies/CrawlerRoach.swift:250", .mirrored, .flags([false]), "crawler"),
        W("World/Enemies/CrawlerRoach.swift:401", .mirrored, .flags([true]), "roach"),
        W("World/Enemies/CrawlerRoach.swift:405", .mirrored, .flags([false]), "roach"),
        W("World/Enemies/Walker.swift:93", .mirrored, .flags([false, true]), "walker"),
        W("World/Enemies/Walker.swift:105", .mirrored, .flags([true]), "walker"),
        W("World/Enemies/Walker.swift:108", .mirrored, .flags([true]), "walker"),
        W("World/Enemies/Walker.swift:111", .mirrored, .flags([true]), "walker"),
        // WK2: the 1750 Setup's flip (M l. 57008–57010), the 1760's facing (M l. 58024–58029), the Ax goblin's facing
        // (M l. 58295–58306) and its jump's flip (M l. 57213–57218) — the same unflipped / flipped sheet cells.
        W("World/Enemies/Walker.swift:115", .mirrored, .flags([true]), "walker"),
        W("World/Enemies/Walker.swift:518", .mirrored, .flags([false, true]), "walker"),
        W("World/Enemies/AxGoblin.swift:157", .mirrored, .flags([false, true]), "walker"),
        W("World/Enemies/AxGoblin.swift:159", .mirrored, .flags([false, true]), "walker"),
        W("World/Enemies/AxGoblin.swift:161", .mirrored, .flags([false, true]), "walker"),
        W("World/Enemies/AxGoblin.swift:280", .mirrored, .flags([false, true]), "walker"),
        W("World/Enemies/Walker.swift:123", .mode, .words([0x10010, 0x10011, 0x10012, 0x10013, 0x10014, 0x10015]),
          "walker", at: ["61", "62", "63", "64", "65", "66"]),
        W("World/Enemies/Walker.swift:309", .mirrored, .flags([false]), "walker"),
        W("World/Enemies/Walker.swift:311", .mirrored, .flags([true]), "walker"),
        W("World/Enemies/Walker.swift:435", .mirrored, .flags([false, true]), "walker"),
        W("World/Enemies/Walker.swift:445", .mirrored, .flags([false]), "walker"),
        W("World/Enemies/Walker.swift:449", .mirrored, .flags([false]), "walker"),
        W("World/Enemies/Walker.swift:452", .mirrored, .flags([true]), "walker"),
        W("World/Enemies/Walker.swift:457", .mirrored, .flags([true]), "walker"),
        W("World/Enemies/Walker.swift:649", .mirrored, .flags([false, true]), "walker"),
        W("World/Enemies/Walker.swift:684", .flash, .range(0x12...0x12), "walker"),
        W("Physics/StandardSprite.swift:32", .flash, .range(0...0x1d), "any", pins: ["if s.flash > 0 { s.flash -= 1 }"]),
        // `.StandardSpriteHandles`' per-frame reset, then the occluder's clip, each edge clamped to 0…the face width
        // (the right edge 32000 when past it) on the next lines when the sprite has a face (no face, no draw).
        W("Physics/StandardSprite.swift:34", .clipTop, .range(0...0), "any"),
        W("Physics/StandardSprite.swift:35", .clipLeft, .range(0...0), "any"),
        W("Physics/StandardSprite.swift:36", .clipBottom, .range(32000...32000), "any"),
        W("Physics/StandardSprite.swift:37", .clipRight, .range(32000...32000), "any"),
        W("Physics/StandardSprite.swift:136", .clipRight, .faceWidth, "any", at: ["138", "139"],
          pins: ["if faceWidth(f) < s.clip.right { s.clip.right = 32000 }", "if s.clip.right < 0 { s.clip.right = 0 }"]),
        W("Physics/StandardSprite.swift:138", .clipRight, .range(32000...32000), "any"),
        W("Physics/StandardSprite.swift:139", .clipRight, .range(0...0), "any"),
        W("Physics/StandardSprite.swift:142", .clipLeft, .faceWidth, "any", at: ["145", "146"],
          pins: ["if fw < s.clip.left { s.clip.left = fw }", "if s.clip.left < 0 { s.clip.left = 0 }"]),
        W("Physics/StandardSprite.swift:145", .clipLeft, .faceWidth, "any", pins: ["s.clip.left = fw"]),
        W("Physics/StandardSprite.swift:146", .clipLeft, .range(0...0), "any"),
        W("Physics/UnderWater.swift:63", .waterKind, .levelLiquid, "any", pins: ["waterKind(w.tiles.bgKind("]),
        W("Player/GroundCeilingEffects.swift:290", .mode, .words([0xb0004]), "effect.plume"),
        W("Player/GroundCeilingEffects.swift:367", .mode, .words([0xb0001]), "effect.debris"),
        W("Player/GroundCeilingEffects.swift:368", .mode, .words([0]), "effect.debris"),
        W("Player/GroundCeilingEffects.swift:369", .mode, .words([0xb0000]), "effect.debris"),
        W("Player/GroundCeilingEffects.swift:370", .mode, .words([0xb0002]), "effect.debris"),
        W("Player/GroundCeilingEffects.swift:402", .mode, .wordRange(0x10001...0x1000f), "effect.explosion",
          pins: ["0 < p.type && p.type < 0x10", "p.mode = 0x10000 + UInt32(p.type)"]),
        W("Player/GroundCeilingEffects.swift:403", .mode, .words([0x10005]), "effect.explosion"),
        W("Player/HitPlayerSprite.swift:99", .flash, .range(0xc...0xc), "player"),
        W("Player/HitPlayerSprite.swift:915", .flash, .range(0x1e...0x1e), "player"),
        // `.HurtSprite`'s callers: the player's two (0xc) and, from WK1, the Walker's Hit and its `.HurtGoblin`s (8).
        W("Player/HitPlayerSprite.swift:1227", .flash, .range(8...0xc), "player", "walker", "crawler", "roach", "bat",
          "bat.swarmMember", "frog", "salamander", "blob",
          at: ["1048", "1186", "1209", "World/Enemies/Walker.swift:827", "World/Enemies/Walker.swift:851",
               "World/Enemies/Walker.swift:856", "World/Enemies/CrawlerRoach.swift:453",
               "World/Enemies/CrawlerRoach.swift:459", "World/Enemies/CrawlerRoach.swift:480",
               "World/Enemies/CrawlerRoach.swift:486", "World/Enemies/Bat.swift:662", "World/Enemies/Bat.swift:699",
               "World/Enemies/FrogSalamander.swift:502", "World/Enemies/FrogSalamander.swift:513",
               "World/Enemies/FrogSalamander.swift:552", "World/Enemies/BlobCrab.swift:291"],
          pins: ["flash: 0xc", "flash: 8", "flash: 10"]),
        W("Player/Player.swift:126", .mirrored, .flags([false, true]), "player"),
        W("Player/Player.swift:332", .mirrored, .flags([false, true]), "player"),
        W("Player/Player.swift:873", .mode, .words([0x10008, 0x10009]), "player", at: ["872"]),
        W("Player/Player.swift:878", .mode, .words([0xb0005, 0xb0001]), "player", at: ["876"]),
        W("Player/PlayerLiquids.swift:55", .flash, .range(0xd...0xd), "player"),
        W("Player/PlayerLiquids.swift:78", .flash, .range(0x12...0x12), "player"),
        W("Player/PlayerState.swift:280", .mirrored, .copy, "player.shadowRing"),
        W("Player/PlayerStates.swift:133", .mirrored, .flags([false, true]), "player"),
        W("Player/PlayerStates.swift:295", .mirrored, .copy, "player.mistBody"),
        // The power tints, or the mode it had (walk-on-liquid kinds other than 0…2 store nothing).
        W("Player/PlayerStates.swift:841", .mode, .words([0, 0x1000a, 0x10004, 0x10001, 0x1000c, 0x10003, 0x10008]),
          "player", at: ["821", "827", "830", "833", "836", "839"]),
        W("Player/PlayerStates.swift:855", .mode, .words([0x10006]), "player"),
        W("Player/PlayerStates.swift:858", .mode, .words([0x10009]), "player"),
        W("Player/PlayerStates.swift:869", .mode, .words([0]), "player"),
        W("Player/PlayerStates.swift:880", .mode, .wordRange(0x50000...0x5000f), "player", at: ["876", "877", "878"],
          pins: ["if 0xf < k { k = 0xf }", "if k < 0 { k = 0 }", "UInt32(truncatingIfNeeded: Int(k) + 0x50000)"]),  // k 0…15
        W("Player/PlayerTiles.swift:131", .mirrored, .flags([false, true]), "player"),
        W("Player/PowerUps.swift:109", .mirrored, .copy, "player.trail"),
        W("Player/PowerUps.swift:112", .mode, .words([0xb0002, 0xb0000, 0xb0001, 0]), "player.trail",
          at: ["99", "100", "101", "102"]),
        W("Player/ShadowDouble.swift:156", .mirrored, .copy, "player.shadowDouble"),
        W("Player/ShadowDouble.swift:157", .mode, .words([0x1000b]), "player.shadowDouble",
          at: ["Player/ShadowDouble.swift:13"]),
        W("Session/FerazelSession.swift:211", .mirrored, .copy, "player.shadowRing"),
        W("Shots/CastSpell.swift:164", .mirrored, .flags([false]), "shot"),
        // 10·dir, dir 0…0x23, only for a shot with gravity (`0 < +0x110`: ids 0, 1, 3, 4, 7 and the seed 0x5a); the
        // followers take their main's angle (the orb 0x50 has gravity 0, PlayerShot.setup, so its followers get 0).
        W("Shots/PlayerShot.swift:313", .rotation, .range(0...350), "shot.gravity", at: ["312"],
          pins: ["if 0x23 < dir { dir -= 0x24 }", "Int16(dir * 10)"]),
        W("Shots/PlayerShot.swift:342", .rotation, .range(0...350), "shot.gravity", at: ["341"],
          pins: ["let angle = s.rotation", "$0.rotation = angle"]),
        W("Shots/PlayerShot.swift:449", .mode, .words([0]), "shot.orb"),
        W("Shots/PlayerShot.swift:450", .mode, .words([0x10008]), "shot.orb"),
        W("Shots/PlayerShot.swift:451", .mode, .words([0x10009]), "shot.orb"),
        W("Shots/PlayerShot.swift:457", .mode, .words([0xb0002]), "shot.orb"),
        W("Shots/PlayerShot.swift:458", .mode, .words([0xb0000]), "shot.orb"),
        W("Shots/PlayerShot.swift:459", .mode, .words([0xb0001]), "shot.orb"),
        W("Shots/PlayerShot.swift:460", .mode, .words([0]), "shot.orb"),
        W("Shots/PlayerShot.swift:474", .mode, .words([0x10004]), "shot.gravity"),        // the seed (gravity 0xfa)
        W("Shots/PlayerShotHits.swift:109", .mode, .words([0x10004]), "shot.gravity"),    // the seed
        W("Shots/PlayerShotHits.swift:221", .flash, .range(10...10), "box"),
        W("Sprites/SetupFaces.swift:396", .mirrored, .flags([true]), "background.plant"),
        W("Sprites/SetupFaces.swift:397", .mode, .placedTint(0xa8c...0xaef), "background.plant",
          pins: ["if p.p2 != 0 { s.mode = UInt32(truncatingIfNeeded: Int(p.p2) + 0x10000) }"]),
        W("Sprites/SetupFaces.swift:454", .mode, .words([0x90000]), "box.teleporter"),
        W("Sprites/SetupFaces.swift:476", .mode, .words([0x90000]), "box.chest"),
        W("Sprites/SpriteSlot.swift:602", .mode, .words([0]), "platform.raft", "box.boulder", "background.maceBall",
          "chain.maceChain"),
        W("Sprites/SpriteSlot.swift:604", .mode, .levelLight, "platform.raft", "box.boulder", "background.maceBall",
          "chain.maceChain", pins: ["mode = UInt32(truncatingIfNeeded: L * 0x100 + 0xc0000 + F)"]),
        // (angle >> 8) + 0x5a with the angle wrapped into 0…0x167ff (`RadialMotion.updatePosition`), − 360 once.
        W("World/Movers/BackgroundSprite.swift:194", .rotation, .range(0...359), "background.maceBall", at: ["192", "193"],
          pins: ["UInt32(bitPattern: c.radial?.angle ?? 0) >> 8) &+ 0x5a", "if 0x167 < r { r &-= 0x168 }"]),
        W("World/Movers/BackgroundSprite.swift:273", .clipBottom, .range(32000...32000), "background.spring"),
        W("World/Movers/BackgroundSprite.swift:280", .mode, .words([0x10018]), "background.spring"),  // hdr 0x26cd ≠ 0
        W("World/Movers/BackgroundSprite.swift:340", .mirrored, .flags([false]), "background.cannon"),
        W("World/Movers/BackgroundSprite.swift:342", .mirrored, .flags([true]), "background.cannon"),
        W("World/Movers/BackgroundSprite.swift:345", .mirrored, .flags([false]), "background.cannon"),
        W("World/Movers/BackgroundSprite.swift:350", .mirrored, .flags([false]), "background.cannon"),
        W("World/Movers/BackgroundSprite.swift:352", .mirrored, .flags([true]), "background.cannon"),
        W("World/Movers/BackgroundSprite.swift:355", .rotation, .range(0...0), "background.cannon"),
        W("World/Movers/BackgroundSprite.swift:357", .mode, .words([0]), "background.cannon"),
        W("World/Movers/BackgroundSprite.swift:362", .mirrored, .flags([false]), "background.cannon"),
        // r = ((0x20 − aim)·0xb4 / 16) / 2 for aim 1…31 not ≡ 0 mod 4 → 5…174, doubled: 10…348.
        W("World/Movers/BackgroundSprite.swift:364", .rotation, .range(10...348), "background.cannon",
          at: ["359", "360", "363"], pins: ["0x20 - aim)) * 0xb4", "(u / 16) / 2", "if 0xb3 < r { r -= 0xb4 }",
                                            "c.rotation = r << 1"]),
        W("World/Movers/BackgroundSprite.swift:379", .mirrored, .flags([true]), "background.spring"),
        // ES: the dart traps' Handle arm (1901 mirrored; built as read — their Setup arm is refused, none on 1–5).
        W("World/Movers/BackgroundSprite.swift:426", .mirrored, .flags([true]), "background.dartTrap"),
        W("World/Movers/BackgroundSprite.swift:816", .mirrored, .flags([false, true]), "background.smoke"),
        W("World/Movers/BackgroundSprite.swift:874", .mirrored, .flags([true]), "background.spike"),
        W("World/Movers/BackgroundSprite.swift:882", .mode, .words([0x10018]), "background.spike"),   // hdr 0x26cd ≠ 0
        W("World/Movers/BackgroundSprite.swift:884", .mode, .words([0x90000]), "background.spike"),
        // The retracting spikes (0x732 / 0x733): f = the phase 0…0xb.
        W("World/Movers/BackgroundSprite.swift:924", .clipBottom, .range(0...0x14), "background.spike",
          at: ["915", "918"], pins: ["} else if s.phase < 0xb {", "max(0, 0x14 - f * 2)"]),
        W("World/Movers/BackgroundSprite.swift:928", .clipTop, .range(0...0x16), "background.spike",
          at: ["915", "918", "927"], pins: ["} else if s.phase < 0xb {", "s.y = h(base - f * 2)", "h(base - s.y)"]),
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
        W("World/Movers/BoxSprite.swift:204", .mirrored, .flags([false]), "box.bridge"),
        W("World/Movers/BoxSprite.swift:209", .mirrored, .flags([true]), "box.bridge"),
        W("World/Movers/BoxSprite.swift:212", .mirrored, .flags([true]), "box.bridge"),
        W("World/Movers/BoxSprite.swift:252", .mirrored, .flags([true]), "box.door"),
        W("World/Movers/BoxSprite.swift:298", .flashTable, .flags([true]), "box.iceWall"),
        W("World/Movers/BoxSprite.swift:308", .clipTop, .range(4...4), "box.gate"),
        W("World/Movers/BoxSprite.swift:314", .mode, .words([0x10018]), "box.gate"),          // hdr 0x26cd ≠ 0
        W("World/Movers/BoxSprite.swift:346", .mode, .words([0xb0001]), "box.lantern"),
        W("World/Movers/BoxSprite.swift:386", .mirrored, .flags([true]), "box.decoration"),
        W("World/Movers/BoxSprite.swift:390", .mode, .placedTint(0xaf5...0xb21), "box.decoration",
          pins: ["if p.p2 != 0 { s.mode = UInt32(truncatingIfNeeded: Int(p.p2) + 0x10000) }"]),
        W("World/Movers/BoxSprite.swift:400", .mode, .words([0x10006]), "box.outcrop"),
        W("World/Movers/BoxSprite.swift:401", .mode, .words([0x10007]), "box.outcrop"),
        W("World/Movers/BoxSprite.swift:402", .mode, .words([0xb0005]), "box.outcrop"),
        W("World/Movers/BoxSprite.swift:542", .mode, .words([0xb0002, 0xb0000, 0xb0001]), "box.trunk"),
        W("World/Movers/BoxSprite.swift:583", .mirrored, .flags([true]), "box.statue"),
        W("World/Movers/BoxSprite.swift:637", .waterKind, .copy, "box.cart"),
        // The hovering rock (`+0x160 < 0`): see `hoverUnreachable` — a separate sprite state from the roll (:643).
        W("World/Movers/BoxSprite.swift:670", .mode, .words([0xb0000, 0xb0002]), "box.boulder.hover"),
        W("World/Movers/BoxSprite.swift:672", .mode, .words([0xb0002, 0]), "box.boulder.hover"),
        W("World/Movers/BoxSprite.swift:676", .mode, .words([0]), "box.boulder.hover"),
        W("World/Movers/BoxSprite.swift:691", .rotation, .range(0...359), "box.boulder", at: ["689", "690"],
          pins: ["while s.phase < 0 { s.phase &+= 0x168 }", "while 0x167 < s.phase { s.phase &-= 0x168 }"]),
        // The gate's clip: `+0x158 − y` (0…100 in 2-pixel steps: up while < 100 open, down while > 0 shut) + 7, + 0x20.
        W("World/Movers/BoxSprite.swift:804", .clipTop, .range(7...139), "box.gate",
          at: ["783", "786", "787", "788", "802", "803"],
          pins: ["if 0 < above { step = 0x200 }", "} else if above < 100 {", "step = -0x200",
                 "Int16(truncatingIfNeeded: g.y) &+ 7", "if p2 != 0 { c &+= 0x20 }"]),
        W("World/Movers/BoxSprite.swift:1058", .mirrored, .copy, "box.balloon"),
        // PI: an emerging pipe child's clip edge (`.HandleBoxSprite` M l. 60706–60740: (pipe + 7 or + 0x1d) − child,
        // below 1 → 0): within the child's hot rect plus 3 px a step for at most `+0x154` steps — under 0x100 for the
        // shipped children (1700, 1705, 1730, 1860); the release (M l. 60751–60755) reopens all four edges.
        W("World/Movers/BoxSprite.swift:947", .clipBottom, .range(0...0x100), "pipe.child", at: ["943"],
          pins: ["edge(h(s.y) + 7 - h(k.y))", "v < 1 ? 0"]),
        W("World/Movers/BoxSprite.swift:950", .clipTop, .range(0...0x100), "pipe.child", at: ["943"],
          pins: ["edge(h(s.y) + 0x1d - h(k.y))", "v < 1 ? 0"]),
        W("World/Movers/BoxSprite.swift:953", .clipLeft, .range(0...0x100), "pipe.child", at: ["943"],
          pins: ["edge(h(s.x) + 0x1d - h(k.x))", "v < 1 ? 0"]),
        W("World/Movers/BoxSprite.swift:956", .clipRight, .range(0...0x100), "pipe.child", at: ["943"],
          pins: ["edge(h(s.x) + 7 - h(k.x))", "v < 1 ? 0"]),
        W("World/Movers/BoxSprite.swift:962", .clipRight, .range(32000...32000), "pipe.child"),
        W("World/Movers/BoxSprite.swift:963", .clipBottom, .range(32000...32000), "pipe.child"),
        W("World/Movers/BoxSprite.swift:964", .clipLeft, .range(0...0), "pipe.child"),
        W("World/Movers/BoxSprite.swift:965", .clipTop, .range(0...0), "pipe.child"),
        // GY: the geyser head's tint by liquid kind (`.HandleGeyserColumn` M l. 59811–59821: kind 1 → 0x10017, 0 → 0, 2 →
        // 0x1000c — mode-1 remaps through tint tables 0x17 / 0xc; kinds 3 / 4 unchanged), the segments' copy of it (M l.
        // 59842) and the top segment's clipped rows `+0x1bc` = 32·n − h_px, 0…31 (M l. 59844–59850).
        W("World/Movers/Geyser.swift:248", .mode, .words([0x10017]), "box.geyserHead"),
        W("World/Movers/Geyser.swift:250", .mode, .words([0]), "box.geyserHead"),
        W("World/Movers/Geyser.swift:252", .mode, .words([0x1000c]), "box.geyserHead"),
        W("World/Movers/Geyser.swift:283", .mode, .copy, "geyserSegment"),
        W("World/Movers/Geyser.swift:284", .clipTop, .range(0...31), "geyserSegment", at: ["278"],
          pins: ["(n << 5) - hpx", "i == n - 1"]),
        // (subtype + 0x5a) % 360, subtype a spoke's degrees 0…359 or −90 (`Radial.updateSpokes`) → 0…359.
        W("World/Movers/ChainSprite.swift:51", .rotation, .range(0...359), "chain.maceChain", at: ["49"],
          pins: ["Int(s.subtype) + 0x5a", "a % 0x168"]),
        W("World/Movers/ChainSprite.swift:103", .mirrored, .flags([false, true]), "chain.seeSawSegment"),
        W("World/Movers/PlatformSprite.swift:322", .mirrored, .flags([true]), "platform.catapult"),
        W("World/Movers/PlatformSprite.swift:603", .mode, .words([0xb0001]), "platform.blink"),
        W("World/Movers/PlatformSprite.swift:604", .mode, .words([0xb0000]), "platform.blink"),
        W("World/Movers/PlatformSprite.swift:605", .mode, .words([0xb0002]), "platform.blink"),
        W("World/Movers/PlatformSprite.swift:612", .clipBottom, .range(0...0), "platform.blink"),
        W("World/Movers/PlatformSprite.swift:640", .mode, .words([0xb0002]), "platform.blink"),
        W("World/Movers/PlatformSprite.swift:641", .clipBottom, .range(32000...32000), "platform.blink"),
        W("World/Movers/PlatformSprite.swift:643", .mode, .words([0xb0000]), "platform.blink"),
        W("World/Movers/PlatformSprite.swift:645", .mode, .words([0]), "platform.blink"),
        W("World/Movers/PlatformSprite.swift:701", .mode, .words([0]), "platform.blink"),
        W("World/Movers/PlatformSprite.swift:702", .clipBottom, .range(32000...32000), "platform.blink"),
        W("World/Movers/PlatformSprite.swift:706", .mode, .words([0xb0001]), "platform.blink"),
        W("World/Movers/PlatformSprite.swift:709", .mode, .words([0xb0000]), "platform.blink"),
        W("World/Movers/PlatformSprite.swift:710", .mode, .words([0xb0002]), "platform.blink"),
        W("World/Movers/PlatformSprite.swift:715", .clipBottom, .range(0...0), "platform.blink"),
        W("World/Movers/PlatformSprite.swift:868", .mode, .words([0]), "platform.gauge"),
        W("World/Movers/PlatformSprite.swift:870", .mode, .wordRange(0xa000b...0xa00fa), "platform.gauge", at: ["866"],
          pins: ["if q < 0xb {", "g.mode = q < 0xfb ? UInt32(bitPattern: q &+ 0xa0000) : 0"]),
        // The raft's tilt (`tail`, subtype 3 only), wrapped into 0…359.
        W("World/Movers/PlatformSprite.swift:928", .rotation, .range(0...359), "platform.raft", at: ["927"],
          pins: ["if r < 0 { r += 0x168 }"]),
        // The floe's last 0x2c frames (`+0xa6` in 1…0x2c): subtypes 4 / 0x6a4 (`PlayerShot.floe` / `ledge` set
        // `+0xa6 = 0xb4`); the raft (subtype 3) has `+0xa6 = 0` from its Setup arm and no writer after it.
        W("World/Movers/PlatformSprite.swift:950", .mode, .words([0xb0000, 0]), "platform.floe"),
        // 255 − f·(0x100 − 0x96), f ∈ [0, 1] → 149…255 (the ball); the spokes 203 + J·(drawScale − 203)·2 / n.
        W("World/Movers/Radial.swift:213", .scale, .range(0x95...0xff), "radial.persp", at: ["210", "211", "212"],
          pins: ["Double(Float(255.0) - f * Float(0x100 - Int32(b.farScale)))", "b.drawScale = scale"]),
        W("World/Movers/Radial.swift:215", .mode, .radialLight, "radial.persp", at: ["208", "214"],
          pins: ["Float(256.0) * f", "fctiwz(0.05 * Double(f3))", "Int32(level) &* 0x100 &+ 0xc0000"]),
        W("World/Movers/Radial.swift:263", .mode, .words([0x10018]), "radial.spokes",   // its one caller (PlatformSprite)
          at: ["World/Movers/PlatformSprite.swift:122"]),
        W("World/Movers/Radial.swift:297", .scale, .range(0x5f...0x133), "radial.persp", at: ["294", "295", "296"],
          pins: ["Int32(b.farScale) + 0x100", "u / 2", "(Int32(b.drawScale) - Int32(s0)) * 2", "(J * span) / n"]),
        W("World/Movers/Radial.swift:302", .mode, .radialLight, "radial.persp", at: ["300", "301"],
          pins: ["((n - J) * 0xc0) / n", "fctiwz(0.05 * Double(mix))", "Int32(level) &* 0x100 &+ 0xc0000"]),
        W("World/Movers/StatueSprite.swift:50", .mode, .words([0x1000b]), "statue"),
        W("World/Movers/StatueSprite.swift:55", .mode, .words([0]), "statue"),
        W("World/Movers/StatueSprite.swift:61", .mode, .copy, "statue"),     // the sprite's own mode, restored
    ]

    /// Every writer site the scan finds: `file:line` and the field.
    private static func scannedWriters() throws -> [(site: String, input: Input, code: String)] {
        let fields = Input.allCases.map(\.rawValue)
        var out: [(String, Input, String)] = []
        for l in try coreLines.get() where !l.file.hasPrefix("Seams/") {
            var found = assignedFields(l.code, fields)
            if l.file == "Sprites/SpriteSlot.swift",
               Self.trim(l.code).hasPrefix("mode = ") { found.append("mode") }
            for f in found {
                guard let input = Input(rawValue: f) else { continue }
                if notDrawInputs.contains(where: { $0.file == l.file && $0.field == input }) { continue }
                out.append(("\(l.file):\(l.line)", input, Self.trim(l.code)))
            }
        }
        return out
    }

    /// The integer literals of `code` (hex or decimal; not a digit run inside a name, nor a float's).
    static func intLiterals(_ code: String) -> [Int] {
        let c = Array(code.utf8)
        func digit(_ b: UInt8) -> Bool { b >= 48 && b <= 57 }
        func hexDigit(_ b: UInt8) -> Int? {
            if digit(b) { return Int(b) - 48 }
            if b >= 97 && b <= 102 { return Int(b) - 87 }
            if b >= 65 && b <= 70 { return Int(b) - 55 }
            return nil
        }
        func name(_ b: UInt8) -> Bool { b == 95 || b == 46 || digit(b) || (b | 0x20 >= 97 && b | 0x20 <= 122) }
        var out: [Int] = [], i = 0
        while i < c.count {
            guard digit(c[i]), i == 0 || !name(c[i - 1]) else { i += 1; continue }
            var v = 0, j = i
            if c[i] == 48 && i + 1 < c.count && c[i + 1] == 120 {
                j = i + 2
                while j < c.count, let d = hexDigit(c[j]) ?? (c[j] == 95 ? -1 : nil) { if d >= 0 { v = v * 16 + d }; j += 1 }
            } else {
                while j < c.count && (digit(c[j]) || c[j] == 95) { if c[j] != 95 { v = v * 10 + Int(c[j]) - 48 }; j += 1 }
                if j + 1 < c.count && c[j] == 46 && digit(c[j + 1]) {     // a float: skipped
                    j += 1
                    while j < c.count && digit(c[j]) { j += 1 }
                    i = j
                    continue
                }
            }
            out.append(v)
            i = j
        }
        return out
    }

    /// Each row against the source it cites: the site's line (and `at`) hold every `pins` string; a word row's words
    /// are exactly the mode-word literals (≥ 0x10000) there, plus 0 as a literal; a one-value range's value is a
    /// literal there; a flag row's line assigns that literal (`= true` / `= false`, 1 for `flashTable`) or neither when
    /// it writes both; every derived row (ranges, light words, tints, liquids, face widths) carries its pins.
    static func sourceMismatches() throws -> [String] {
        var code: [String: String] = [:]
        for l in try coreLines.get() { code["\(l.file):\(l.line)"] = l.code }
        var out: [String] = []
        for w in writers {
            let file = String(w.site.split(separator: ":").first ?? "")
            let sites = [w.site] + w.at.map { has($0, ":") ? $0 : "\(file):\($0)" }
            let lines = sites.map { code[$0] ?? "" }
            for (site, line) in zip(sites, lines) where trim(line).isEmpty { out.append("\(w.site): \(site) holds no code") }
            for p in w.pins where !lines.contains(where: { has($0, p) }) { out.append("\(w.site): no `\(p)`") }
            let literals = Set(lines.flatMap(intLiterals))
            switch w.values {
            case .words(let ws):
                for x in ws where !literals.contains(Int(x)) { out.append("\(w.site): \(hex(x)) is not in the source") }
                for v in literals.sorted() where v >= 0x10000 && !ws.contains(UInt32(truncatingIfNeeded: v)) {
                    out.append("\(w.site): the source writes \(hex(UInt32(truncatingIfNeeded: v))), not in the row")
                }
            case .range(let r) where r.lowerBound == r.upperBound:
                if !literals.contains(r.lowerBound) { out.append("\(w.site): \(r.lowerBound) is not in the source") }
            case .flags(let f):
                let own = lines[0]
                if w.input == .flashTable {
                    if f != [true] || !literals.contains(1) { out.append("\(w.site): flashTable \(f)") }
                } else {
                    let t = has(own, "= true"), u = has(own, "= false")
                    if (f == [true] && !t) || (f == [false] && !u) || (f.count == 2 && (t || u)) {
                        out.append("\(w.site): flags \(f) against `\(trim(own))`")
                    }
                }
            case .copy: break
            default:
                if w.pins.isEmpty { out.append("\(w.site): a derived row with no pins") }
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
        case .copy, .range, .flags, .levelLiquid, .faceWidth: return []
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
        /// Every face the run drew.
        var faces: Set<FaceRef> = []
        /// Level starts (`LevelServices.prepare`, a new renderer each), the `.wrapEraseSprites` the last one applied,
        /// and its ripple phase at the end.
        var prepares = 0, erasesSinceStart = 0
        var finalPhase: Int32 = 0
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
    /// PT: the throwing calls a skipped op's arm may make (`skippedOpsCannotThrow`).
    static let skippedTries = ["copyToScreen": ["try parallax.copyToScreen("],
                               "copyMaskToScreen": ["try parallax.copyMaskToScreen("],
                               "drawLightsOntoTiles": ["try grid.drawLightsOntoTiles("]]

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
        case .omniPx: "omniPx"
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
        private(set) var prepares = 0
        var deathSteps: Set<Int> = []
        init(_ resources: FerazelResources) { self.resources = resources }
        func prepare(level: Int) throws -> LevelFaces {
            let r = try FrameRenderer(resources: resources, level: level, search: DrawModeAuditTests.search,
                                      dither: .errorDiffusion, text: StatusBarTests.BoxRasterizer(), prefs: FerazelPrefs())
            renderer = r
            prepares += 1
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
            if services.prepares != seen.prepares {
                seen.prepares = services.prepares
                seen.erasesSinceStart = 0
            }
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
                do {
                    try r.apply(FrameOps(draws: ops))
                    for op in ops { if case .wrapEraseSprites = op { seen.erasesSinceStart += 1 } }
                } catch {
                    seen.refusals.append("tick \(seen.ticks): \(error)")
                }
            }
            if !seen.refusals.isEmpty { break }
        }
        seen.deathSteps = services.deathSteps
        seen.finalPhase = services.renderer?.sprites.ripplePhase ?? 0
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
                s.faces.insert(d.face)
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
        /// Draws and erases `d` at scroll (h, v); nil when drawn, else the refusal.
        mutating func draw(_ d: SpriteDraw, h: Int = 0, v: Int = 0) -> String? {
            do {
                try blitter.wrapDrawSprites([d], h: h, v: v, ports: &ports)
                // No grid re-stamp: the erase leaves the mask 0xff under the face again.
                try blitter.wrapEraseSprites([DrawModeAuditTests.erased(d)], h: h, v: v, ports: &ports)
            } catch {
                return "\(error)"
            }
            return nil
        }

        /// Whether `d` at scroll (h, v) reaches its mode read: a face call with a non-empty window that `.Wrap*Face`'s
        /// view test passes (`SpriteBlitter.wrap`; its ring position then passes `blitEncFaceX`'s entry test).
        func reaches(_ d: SpriteDraw, h: Int = 0, v: Int = 0) -> Bool {
            guard let face = blitter.faces.face(d.face) else { return false }
            return SpriteBlitter.faceCalls(d, face: face).calls.contains { c in
                c.w > 0 && c.h > 0 && c.dstH + c.w >= h && c.dstV + c.h >= v && c.dstH <= h + 0x260
                    && c.dstV <= v + 0x180
            }
        }

        /// The control: `d` with the unwritten mode word 0x20000 (no flash, light, water or seed) must be refused —
        /// proof that a draw at this place and transform reaches the mode read.
        mutating func controlRefused(_ d: SpriteDraw, h: Int = 0, v: Int = 0) -> Bool {
            var c = d
            c.mode = 0x20000
            c.flash = 0
            c.lightOverlay = false
            c.waterRow = 0
            c.randomSeed = nil
            guard let e = draw(c, h: h, v: v) else { return false }
            return DrawModeAuditTests.has(e, "mode")
        }
    }

    /// `.InitSprite`'s clip (`SpriteSlot.clip`, `.StandardSpriteHandles`' reset): the whole face.
    static let openClip = SpriteClip(left: 0, right: 32000, bottom: 32000, top: 0)

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
        // Every probe has the whole face (`openClip`), reaches its mode read (checked), and each place / transform is
        // proved once by the control draw.
        var proved = Set<String>()
        func put(_ d0: SpriteDraw, _ label: String, h: Int = 0, v: Int = 0) {
            var d = d0
            if d.clip == SpriteClip() { d.clip = openClip }
            guard pad.reaches(d, h: h, v: v) else {
                failures.append("level \(a.level.number) \(label): culled before the mode read")
                return
            }
            let key = "\(d.face) \(d.x) \(d.y) \(d.mirrored) \(d.rotation) \(d.scale) \(h) \(v)"
            if !proved.contains(key) {
                proved.insert(key)
                if !pad.controlRefused(d, h: h, v: v) {
                    failures.append("level \(a.level.number) \(label): the control draw was not refused")
                }
            }
            if let e = pad.draw(d, h: h, v: v) { failures.append("level \(a.level.number) \(label): \(e)") }
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
            // Across the ring's right and bottom edges (scroll 0x40: 620 % 640 + width > 640, 392 % 416 + 56 > 416).
            put(SpriteDraw(face: small, x: 0x26c, y: 0x188, mode: word, randomSeed: seed), "\(site) word \(hex(word)) wrapped",
                h: 0x40, v: 0x40)
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
        // Every clip edge value of every clip row, the other edges open, under one word of each mode the level's rows
        // write, mirrored or not, and rotated / scaled when a row transforms the sprite ("any": every sprite). A
        // window the edge empties draws nothing (the blitters' `w > 0, h > 0`); the face is the wide one.
        var firstOfMode: [Int: UInt32] = [:]
        for word in wordSite.keys.sorted() where firstOfMode[modeOf(word)] == nil { firstOfMode[modeOf(word)] = word }
        let transformedWho = Set(transformedSprites)
        let wideWidth = r.sprites.faces.face(wide)?.width ?? 0
        var clipDrawn = 0
        // Each edge's values over its rows (a range over 8 values: its ends and every 4th; over 32, every 16th), with
        // whether a row transforms them.
        var edges: [Input: [Int: Bool]] = [:]
        for w in writers where has(w.input.rawValue, "clip.") {
            let values: [Int]
            switch w.values {
            case .range(let x):
                let step = x.count > 32 ? 16 : x.count > 8 ? 4 : 1
                values = Array(stride(from: x.lowerBound, to: x.upperBound, by: step)) + [x.upperBound]
            case .faceWidth: values = [0, 1, wideWidth / 2, wideWidth - 1, wideWidth]
            default: failures.append("\(w.site): a clip row with no values"); continue
            }
            let transforms = w.who.contains("any") || w.who.contains(where: transformedWho.contains)
            for v in values { edges[w.input, default: [:]][v] = (edges[w.input]?[v] ?? false) || transforms }
        }
        for (input, values) in edges.sorted(by: { $0.key.rawValue < $1.key.rawValue }) {
            for (v, transforms) in values.sorted(by: { $0.key < $1.key }) {
                var clip = openClip
                switch input {
                case .clipTop: clip.top = v
                case .clipLeft: clip.left = v
                case .clipBottom: clip.bottom = v
                default: clip.right = v
                }
                for (m, word) in firstOfMode.sorted(by: { $0.key < $1.key }) {
                    let seed: Int32? = m == 5 ? 1 : nil
                    for mirrored in m == 0xa ? [false] : [false, true] {
                        var shapes: [(Int16, Int16)] = [(0, 0x100)]
                        if transforms && transformSafe.contains(m) { shapes += [(90, 0x100), (0, 0x5f), (359, 0x133)] }
                        for (rot, sc) in shapes {
                            let d = SpriteDraw(face: wide, x: 100, y: 100, mode: word, mirrored: mirrored, clip: clip,
                                               lightOverlay: true, rotation: rot, scale: sc, randomSeed: seed)
                            if pad.reaches(d) { clipDrawn += 1 }
                            if let e = pad.draw(d) {
                                failures.append("level \(a.level.number) \(input.rawValue) \(v) word "
                                                + "\(hex(word)) mirrored \(mirrored) rotation \(rot) scale \(sc): \(e)")
                            }
                        }
                    }
                }
            }
        }
        if clipDrawn == 0 { failures.append("level \(a.level.number): no clip probe reached its mode read") }
        return failures
    }

    /// The sprites some rotation or scale row writes with a value other than none.
    static var transformedSprites: [String] {
        writers.filter { w in
            guard w.input == .rotation || w.input == .scale, case .range(let r) = w.values else { return false }
            return r != (0...0) && r != (0x100...0x100)
        }.flatMap(\.who)
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
        // Every row's values are the source's (a changed constant fails here).
        let mismatches = try Self.sourceMismatches()
        XCTAssertTrue(mismatches.isEmpty, "rows whose values the source does not write:\n"
                      + mismatches.map { "  " + $0 }.joined(separator: "\n"))

        let audits = try Self.audits.get()
        try check(.skippedOpsCannotThrow, audits)
        for (a, failures) in zip(audits, try Self.drawn.get()) {
            let n = a.level.number, L = a.level.file
            // The backdrop and OmniPx inputs: the level's header names the backdrop the renderer draws.
            XCTAssertLessThanOrEqual(L.header.flameMode, 0, "level \(n): the Fire backdrop")
            XCTAssertEqual(L.header.parallaxRipple, 0, "level \(n): the backdrop ripple")
            // OX: OmniPx modes 2 / 4 / 5 draw (the port as PxBack slot 0); the rest are refused at level open.
            XCTAssertTrue([0, 2, 4, 5].contains(L.header.omniPxMode), "level \(n): OmniPx \(L.header.omniPxMode)")

            // Every row's values, under every transform the renderer builds for them.
            XCTAssertTrue(failures.isEmpty, "\(failures.count) refused:\n" + failures.prefix(20).joined(separator: "\n"))

            // Every Setup's own draw (each placement once), moved on screen at (100, 100) (at its level point it is
            // culled before the mode is read), drawn and erased; its values named by the table. Each reaches its mode
            // read (a non-empty window in view), proved by the control word's refusal.
            let modeRows = Self.writers.filter { $0.input == .mode }
            func named(_ w: UInt32) -> Bool { modeRows.contains { Self.writes($0.values, a.level, w) } }
            var pad = Pad(a.level.renderer)
            for e in a.setups {
                guard var d = e.slot.draw else { continue }
                d.x = 100
                d.y = 100
                let label = "level \(n) Setup \(Self.hex(UInt32(UInt16(bitPattern: e.type))))"
                XCTAssertTrue(pad.reaches(d), "\(label): culled before the mode read")
                XCTAssertTrue(pad.controlRefused(d), "\(label): the control draw was not refused")
                if let error = pad.draw(d) { XCTFail("\(label): \(error)") }
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
        /// PT: a kept `precondition` (not a throw) whose condition no data file can break — its inputs are the code's
        /// own constants or buffers it sized itself (the row's `why` says which).
        case trapUnreachable = "trap: unreachable from any data"
    }

    enum Check: Hashable {
        case writtenWordsDraw, untransformableNotTransformed, gaugeNotMirrored, mode5Seeded, facesLoaded, facesNarrow
        case noCopyAfterCopy, parallaxAttached, pxBackSlotsLoaded, lightBytesInRange, lightIndexInRange
        case headerFlame, headerRipple, levelsLoad, lightSlotsFit, tintDraws510, attachedBeforeApply, levelClut
        case deathSteps, waterTilesInSheet, levelOpsRouted, skippedOpsCannotThrow, ripplePhaseHours
        case rotationRanges, notNamedByLevelFrame(String)
        case headerCamera, coreNotNamed(String), callersTry([String])
        case waterKindsInTables, overlaysInSet, pxMidSlotsLoaded, headerOmniPxStrip, omniPxPortDraws
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
        // PT: the renderer's traps a level's data can reach, now refusals (the skipped copy / light ops reach them
        // too: `skippedOpsCannotThrow` admits those calls because these checks read the data, not the run).
        R("Frame/ParallaxBlitter.swift", "Refusal.cellSlot", 1, .dataAbsent,
          [.pxBackSlotsLoaded, .pxMidSlotsLoaded, .omniPxPortDraws],
          "every PxBack cell of every built level names a loaded slot (OmniPx's 0 included), and every PxMid cell of a "
          + "level with header 0x3268 = 1 names a loaded image and mask slot; OX: OmniPx's base cells 6…14 (all "
          + "`6 + (c >> 1)` can name, c ≤ 0x11) are loaded slots on level 5"),
        R("Frame/TileGridRenderer.swift", "Refusal.waterTable", 1, .dataAbsent, [.waterKindsInTables],
          "no built level has a BG tile of kind 206…209 (water tables 6…9, never built by the original)"),
        R("Frame/LightRenderer.swift", "Refusal.darkness", 2, .dataAbsent, [.lightBytesInRange],
          "the tile light pass's D is a light byte, 0…15 on every built level (the ambient rows)"),
        R("Frame/LightRenderer.swift", "Refusal.lightIndex", 1, .dataAbsent, [.lightBytesInRange, .lightIndexInRange],
          "the tile light pass's index stays in the table: D 0…15, light-face pixels 0 or 0xf5…0xff, colours ≤ 99"),
        R("Frame/LightRenderer.swift", "Refusal.overlay", 1, .dataAbsent, [.overlaysInSet],
          "every overlay cell of every built level with o1 > 99 has o1 100 or 101 and o2 inside that face set"),
        R("Frame/StatusBar.swift", "StatusBarError.backSize", 1, .loadsClean, [.levelsLoad],
          "PICT 132 is 640×88 (every built level's renderer builds its status bar)"),
        // PT: the kept traps — their conditions read only the code's constants or buffers the code sized.
        R("Color/InverseTable.swift", "precondition", 1, .trapUnreachable, [],
          "inverse-table bits come from a `ColorSearch.Model` the shells pick in code (`.exactNearest`; `.ruled` "
          + "uses 4), never from a file"),
        R("Color/ColorSearch.swift", "precondition", 1, .trapUnreachable, [], "the same model bits"),
        R("Frame/Mosaic.swift", "precondition", 1, .trapUnreachable, [],
          "both buffers are the renderer's fixed 640×480 port and screen"),
        R("Frame/ParallaxBlitter.swift", "precondition", 4, .trapUnreachable, [],
          "the slot array the init builds (60 entries); each face a `PlainFaceSheet` cell cut at the fixed 128×128 "
          + "arguments (whatever the PICT, `ConvertedPicture.cell` returns w·h bytes); the fixed 640×416 ports and "
          + "640×480 screen"),
        R("Frame/SpriteBlitter.swift", "preconditionFailure", 1, .trapUnreachable, [],
          "`background`'s fetch: set on the line above it or it threw"),
        R("Frame/TextRasterizer.swift", "precondition", 1, .trapUnreachable, [],
          "a rasterizer's mask: both shells' rasterizers allocate exactly width × height bytes"),
        R("Effects/DeathEffect.swift", "precondition", 1, .trapUnreachable, [.deathSteps],
          "k is `LevelRun`'s loop counter 0…49 (`FrameRenderer.deathEffectStep` also refuses before it)"),
        R("Faces/LightFaces.swift", "precondition", 1, .trapUnreachable, [],
          "`LightFace.load`'s pixels: the converted picture at its own size (`ConvertedPicture` throws on a count "
          + "mismatch) or the w × h sample; w and h are Core's light-face constants, never a file's"),
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
        R("Screens/ScreenRenderer.swift", "Refusal.levelOp", 18, .offLevelFrame, [.levelOpsRouted],
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
        R("Faces/FaceSheet.swift", "refuse", 6, .loadsClean, [.levelsLoad, .omniPxPortDraws],
          "face-set arguments (OX: the OmniPx faces 6200 / 6201 / 6300 / 6301 load under level 5's CLUT)"),
        R("Faces/FaceSheet.swift", "FaceSheetError.cellOutOfRange", 1, .loadsClean, [.levelsLoad], "face-set load"),
        R("Faces/FaceSheet.swift", "FaceSheetError.singleFrameNotAtOrigin", 1, .loadsClean, [.levelsLoad],
          "face load"),
    ]

    /// Every `throw` in `Sources/FerazelCore` — what `LevelRun.tick` (and `FrameRenderer`'s Core calls, the CLUT and
    /// level loads) can propagate out of a level frame — with the reason it is not reached on a built level.
    static let coreRefusals: [Refusal] = [
        R("Camera/Camera.swift", "Error.arenaBound", 1, .headerZero, [.headerCamera],
          "header `arenaBound` = 0 on every built level"),
        R("Camera/Camera.swift", "Error.autoScroll", 1, .headerZero, [.headerCamera],
          "header `autoScrollEnable` = 0 on every built level"),
        R("Color/ColorLUT.swift", "ColorLUTError.truncated", 2, .loadsClean, [.levelsLoad, .levelClut],
          "`FrameRenderer.init` loads the level CLUT and 801 for every built level; `.setScreenClut` reloads only the "
          + "id its tables were built for (the `screenClut` refusal guards it first)"),
        R("Color/ColorLUT.swift", "ColorLUTError.unexpectedFlags", 1, .loadsClean, [.levelsLoad, .levelClut],
          "the same CLUT loads"),
        R("Color/ColorLUT.swift", "ColorLUTError.missing", 1, .loadsClean, [.levelsLoad, .levelClut], "the same CLUT loads"),
        R("Color/ColorLUT.swift", "ColorLUTError.entryCount", 1, .loadsClean, [.levelsLoad, .levelClut],
          "the same CLUT loads"),
        R("Data/FerazelData.swift", "FerazelDataError.missing", 5, .offLevelFrame, [.coreNotNamed("FerazelData")],
          "opening the data folder (the shells, at launch)"),
        // PT (audit ruling 9): the backdrops the renderer does not draw yet, refused at level open (`setupLevel`,
        // before the session) — `GameFlow` reports a level-run error as the level-load error, never a quit.
        R("Front/LevelRun.swift", "LevelOpenRefusal.omniPxMode", 1, .headerZero, [.headerOmniPxStrip],
          "header 0x26c7 = 0 on every built level (rain / interlace modes 1, 3, 6, 7, ≥ 8 refused until 6A-RN)"),
        R("Front/LevelRun.swift", "LevelOpenRefusal.horizonStrip", 1, .headerZero, [.headerOmniPxStrip],
          "header 0x2716 = 0 on every built level (the horizon strip, levels 10, 30, 40, 45, 62, 67, until 6A-S8)"),
        R("Front/DialogResources.swift", "WorldDataError.missing", 1, .byConstruction,
          [.callersTry(["DialogTemplate.load(", "DialogItemList.load(", "ControlTemplate.load(", "MenuTemplate.load(",
                        "MenuBarTemplate.load("])],
          "the shells' dialogs and menus; Core's one use (the save error's text) is a `try?`"),
        R("Saves/SavedGameFile.swift", ".notASavedGame", 2, .offLevelFrame, [.coreNotNamed("SavedGameFile.read(")],
          "opening a saved game file: the shells' Open (Core never calls it)"),
        R("Session/FerazelSession.swift", "SessionError.noPlayerRecord", 1, .loadsClean, [.levelsLoad],
          "the session is built at each level start, every built level's run included"),
        R("Sprites/SetupFaces.swift", "Error.unmapped", 1, .loadsClean, [.levelsLoad],
          "every active placement of every built level sets up (the audit runs each one, and the level start does)"),
        R("Sprites/SetupFaces.swift", "Error.notTranscribed", 14, .loadsClean, [.levelsLoad], "the same Setups"),
        R("Sprites/SetupFaces.swift", "Error.autoScrollSprites", 1, .headerZero, [.headerCamera],
          "header `autoScrollEnable` = 0 on every built level"),
        R("World/Movers/BonusSprite.swift", "SetupFaces.Error.notTranscribed", 2, .loadsClean,
          [.levelsLoad, .callersTry(["BonusSprite.setup("])],
          "placements set up clean; the in-play spawns (drops, chests, crates) call it with `try?` / `try!` for types "
          + "it never refuses (0xc25, items past the table)"),
        R("World/Conversation.swift", "WorldDataError.wrongLength", 1, .byConstruction,
          [.callersTry(["Conversation.load("])], "the level's one loader (`ConversationRun`) is a `try?`"),
        R("World/Conversation.swift", "WorldDataError.missing", 1, .byConstruction,
          [.callersTry(["Conversation.load("])], "the same `try?`"),
        R("World/LevelFile.swift", "WorldDataError.missing", 1, .loadsClean, [.levelsLoad],
          "every built level's Mlvl loads; `.setTile` re-parses the same bytes with one FG cell changed"),
        R("World/LevelFile.swift", "WorldDataError.wrongLength", 2, .loadsClean, [.levelsLoad], "the same Mlvl"),
        R("World/LevelFile.swift", "WorldDataError.truncated", 1, .loadsClean, [.levelsLoad], "the same Mlvl"),
        R("World/LevelFile.swift", "WorldDataError.badDimensions", 1, .loadsClean, [.levelsLoad], "the same Mlvl"),
        R("World/StringList.swift", "WorldDataError.missing", 1, .loadsClean, [.levelsLoad],
          "the session's STR# 500 (the signs) at level start"),
        R("World/WorldFile.swift", "WorldDataError.missing", 1, .loadsClean, [.levelsLoad], "Mwld at level start"),
        R("World/WorldFile.swift", "WorldDataError.wrongLength", 1, .loadsClean, [.levelsLoad], "Mwld at level start"),
        R("World/WorldMap.swift", "WorldDataError.missing", 1, .loadsClean, [.levelsLoad], "the session's Mmap"),
        R("World/WorldMap.swift", "WorldDataError.wrongLength", 1, .loadsClean, [.levelsLoad], "the session's Mmap"),
    ]

    /// PT: every kept trap in `lines` — (file, `precondition` / `preconditionFailure`) → count, as a throw is counted.
    private static func scannedTraps(_ lines: [SourceLine]) -> [String: Int] {
        var out: [String: Int] = [:]
        for l in lines {
            let c = Array(l.code)
            for name in ["precondition", "preconditionFailure"] {
                let pat = Array(name + "(")
                var i = 0
                while i + pat.count <= c.count {
                    defer { i += 1 }
                    guard Array(c[i..<(i + pat.count)]) == pat, i == 0 || !isWord(c[i - 1]) else { continue }
                    out["\(l.file) \(name)", default: 0] += 1
                }
            }
        }
        return out
    }

    /// Every `throw <name>` in `lines`: (file, name) → count.
    private static func scannedThrows(_ lines: [SourceLine]) -> [String: Int] {
        var out: [String: Int] = [:]
        for l in lines {
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
        for (module, lines, rows) in [("FerazelRender", try Self.renderLines.get(), Self.refusals),
                                      ("FerazelCore", try Self.coreLines.get(), Self.coreRefusals)] {
            // FerazelRender's kept traps are counted with its throws (PT): a new trap without a row fails as a throw.
            let traps = module == "FerazelRender" ? Self.scannedTraps(lines) : [:]
            let scanned = Self.scannedThrows(lines).merging(traps) { a, b in a + b }
            let table = Dictionary(rows.map { ("\($0.file) \($0.thrown)", $0.count) }, uniquingKeysWith: +)
            XCTAssertEqual(table.count, rows.count, "\(module): a refusal row twice")
            for (key, n) in scanned.sorted(by: { $0.key < $1.key }) where table[key] != n {
                XCTFail("\(module) throw \(key): \(n) in the source, \(table[key].map(String.init) ?? "no row") in the table")
            }
            for key in table.keys.sorted() where scanned[key] == nil {
                XCTFail("\(module) row \(key): no such throw in the source")
            }
            XCTAssertEqual(scanned.values.reduce(0, +), rows.map(\.count).reduce(0, +), module)
        }

        let audits = try Self.audits.get()
        var checks: [Check] = []
        for r in Self.refusals + Self.coreRefusals { for c in r.checks where !checks.contains(c) { checks.append(c) } }
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
            let transformed = Set(Self.transformedSprites)
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
            // (`classWord160`, also named `stepX`) is set only by `PlayerShot.setup` (0 or 10, on shots) and
            // `EnemyShot.shieldBlock` (1, on a Wraith shot — ES) and counted up only inside the hover branch itself
            // (`BoxSprite.boulder`) — never made negative.
            var writes: [String] = []
            for l in core where !Self.assignedFields(l.code, ["classWord160", "stepX"]).isEmpty {
                writes.append("\(l.file) \(Self.trim(l.code))")
            }
            // WK2: the Ax goblin's jump budget (`.AxGoblinCoreLogic`, made negative by its retreats) — written only on the
            // sprite `AxGoblin.arm` runs for, a Walker 0x6d6 (`Walker.handle`'s exact-type arm), never on a Box.
            // BA: the 1850 family's background flag (`.SetupBatSprite` 0 / 1 by the record p1 sign, M l. 68263–68275) —
            // on Bat sprites only, never negative. DL: the Dillo's right patrol bound (`.SetupDilloSprite` M l. 72363–72368) — on
            // Dillo sprites only.
            XCTAssertEqual(writes.filter { !$0.hasPrefix("World/Enemies/AxGoblin.swift ") }.sorted(),
                           ["Shots/PlayerShot.swift s.stepX = sx",
                            "World/Enemies/Bat.swift s.classWord160 = 0",
                            "World/Enemies/Bat.swift s.classWord160 = 1",
                            "World/Enemies/Dillo.swift s.classWord160 = x + w",
                            "World/Enemies/EnemyShot.swift u.classWord160 = 1",
                            "World/Movers/BoxSprite.swift s.classWord160 &+= 1"], "\(c): +0x160 writers")
            let axCallers = core.filter { Self.has($0.code, "AxGoblin.") }.map { "\($0.file) \(Self.trim($0.code))" }
            XCTAssertEqual(axCallers, ["World/Enemies/Walker.swift case axGoblin: AxGoblin.arm(w, id: id)"],
                           "\(c): the Ax goblin's code runs only from the Walker Handle's 0x6d6 arm")
            // The floe's 0xb word (`platform.floe`, PlatformSprite.swift:950) and the raft's tilt (:928) never meet: the
            // tilt is written only for subtype 3 inside `tail`, the word only while `+0xa6` > 0; the raft's Setup arm
            // (`case 3:`) sets `+0xa6 = 0`, and after Setup `tail` only counts it down and the hit callbacks set −5
            // (subtype 3 runs no other Handle arm). The floe and ledge spawns set `+0xa6 = 0xb4` with subtype 4.
            let plat = core.filter { $0.file == "World/Movers/PlatformSprite.swift" }
            func at(_ lines: [SourceLine], _ code: String) -> [Int] { lines.indices.filter { Self.trim(lines[$0].code) == code } }
            let tilt = at(plat, "c.rotation = r"), word = at(plat, "c.mode = parity ? 0xb0000 : 0")
            XCTAssertEqual(tilt.count, 1, "\(c): the raft's tilt")
            XCTAssertEqual(word.count, 1, "\(c): the floe's word")
            for i in tilt { XCTAssertTrue(Self.enclosing(plat, i).contains("if mode == 3 {"), "\(c): tilt outside subtype 3") }
            for i in word {
                XCTAssertTrue(Self.enclosing(plat, i).contains("if let s = w.active.record(id: id), 0 < s.counterA6 {"),
                              "\(c): the floe's word outside +0xa6 > 0")
            }
            let raftArm = at(plat, "s.counterA6 = 0").filter { Self.enclosing(plat, $0).first == "case 3:" }
            XCTAssertEqual(raftArm.count, 1, "\(c): the raft's Setup arm sets +0xa6 = 0")
            let tail = at(plat, "static func tail(_ w: SpriteWorld, id: Int, solver: TileSolver) {")
            XCTAssertEqual(tail.count, 1, "\(c): `tail`")
            let afterSetup = plat[(tail.first ?? plat.count)...].filter { !Self.assignedFields($0.code, ["counterA6"]).isEmpty }
            XCTAssertEqual(afterSetup.map { Self.trim($0.code) },
                           ["c.counterA6 -= 1", "x.counterA6 = -5", "w.active.update(id: o) { $0.counterA6 = -5 }",
                            "w.active.update(id: id) { $0.counterA6 = -5 }"], "\(c): +0xa6 after Setup")
            let shot = core.filter { $0.file == "Shots/PlayerShot.swift" }
            for f in ["static func floe(_ w: SpriteWorld, x: Int, y: Int) {",
                      "static func ledge(_ w: SpriteWorld, x: Int, y: Int, variant: Int32) {"] {
                guard let i = at(shot, f).first else { XCTFail("\(c): \(f)"); continue }
                let body = shot[i...].prefix(9).map { Self.trim($0.code) }
                XCTAssertTrue(body.contains("p.counterA6 = 0xb4") && body.contains("p.subtype = 4"), "\(c): \(f)")
            }
            // The orb (`shot.orb`, modes 0xb at PlayerShot.swift:457–459) is never rotated: the shots' rotation writers
            // are only a main shot's own (:313, inside `0 < s.gravity`) and its followers' copy of the main's angle
            // (:342); the orb's Setup arm sets gravity 0, and every shot gravity write is in `PlayerShot.setup`.
            let own = "w.active.update(id: id) { $0.rotation = Int16(dir * 10) }"
            let copy = "for f in followers(s).compactMap({ $0 }) { w.active.update(id: f) { $0.rotation = angle } }"
            let rotations = core.filter { $0.file.hasPrefix("Shots/") && !Self.assignedFields($0.code, ["rotation"]).isEmpty }
            XCTAssertEqual(rotations.map { "\($0.file) \(Self.trim($0.code))" },
                           ["Shots/PlayerShot.swift " + own, "Shots/PlayerShot.swift " + copy], "\(c): shot rotations")
            for k in at(shot, own) {
                XCTAssertTrue(Self.enclosing(shot, k).contains("if let s = w.active.record(id: id), 0 < s.gravity {"),
                              "\(c): a shot rotation outside gravity > 0, line \(shot[k].line)")
            }
            for k in at(shot, copy) {
                XCTAssertEqual(k > 0 ? Self.trim(shot[k - 1].code) : "", "let angle = s.rotation", "\(c): the copy")
            }
            XCTAssertEqual(at(shot, "s.gravity = 0").filter { Self.enclosing(shot, $0).first == "case orb:" }.count, 1,
                           "\(c): the orb's gravity 0")
            let setupFn = "static func setup(_ w: SpriteWorld, _ s: inout SpriteSlot) {"
            for (k, l) in shot.enumerated() where !Self.assignedFields(l.code, ["gravity"]).isEmpty {
                XCTAssertTrue(Self.enclosing(shot, k).contains(setupFn), "\(c): shot gravity written at line \(l.line)")
            }
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
            for l in core where Self.has(l.code, ".wrapDrawSprites(") {
                built += 1
                XCTAssertTrue(Self.has(l.code, ".wrapDrawSprites(diffuseSeeds("), "\(c): \(l.file):\(l.line)")
            }
            XCTAssertGreaterThan(built, 0)
            for a in audits { XCTAssertEqual(a.seen.mode5Unseeded, 0, "\(c): level \(a.level.number)") }
        case .facesLoaded:
            for a in audits {
                let faces = a.level.renderer.sprites.faces
                for e in a.setups {
                    if let f = e.slot.face { XCTAssertNotNil(faces.face(f), "\(c): level \(a.level.number) \(f)") }
                }
                XCTAssertTrue(a.seen.refusals.allSatisfy { !Self.has($0, "faceNotLoaded") })
                for f in a.seen.faces { XCTAssertNotNil(faces.face(f), "\(c): level \(a.level.number) run face \(f)") }
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
            XCTAssertTrue(lines.contains { Self.has($0.code, "sprites.parallax = parallax") }, "\(c)")
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
                XCTAssertFalse(a.seen.refusals.contains { Self.has($0, "tintTableNotBuilt") })
            }
        case .levelClut:
            for a in audits {
                XCTAssertEqual(a.level.renderer.tables.screenClutId, ColorLUT.screenClutId(a.level.file.header),
                               "\(c): level \(a.level.number)")
            }
            XCTAssertEqual(LevelRunOutput.target(of: .setScreenClut(id: 281), levelClut: 202, owner: .level), .screen)
        case .deathSteps:
            XCTAssertEqual(DeathEffect.steps, 50)
            let lines = core.filter { $0.file == "Front/LevelRun.swift" && Self.has($0.code, "while deathStep < ") }
            XCTAssertEqual(lines.map { Self.trim($0.code) }, ["while deathStep < 50 {"])
            for a in audits { XCTAssertTrue(a.seen.deathSteps.allSatisfy { (0..<50).contains($0) }) }
        case .waterTilesInSheet:
            XCTAssertTrue(core.contains { $0.file == "Particles/WaterEffects.swift"
                && Self.has($0.code, "if tile < 0x5f && e.isWater != 0") }, "\(c): the tile guard")
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
                .omniPx(.update(OmniPxFrame(omniPxMode: 2, baseCell: 6, faces: []))),
            ]
            XCTAssertEqual(levelOps.count, 18)
            for op in levelOps + [.omniPx(.turnOn(omniPxMode: 2))] {
                for owner in [LevelRunTarget.level, .screen] {
                    XCTAssertEqual(LevelRunOutput.target(of: op, levelClut: 202, owner: owner), .level, "\(c): \(op)")
                }
            }
            for a in audits { XCTAssertEqual(a.seen.levelOpsOffLevel, [], "\(c): level \(a.level.number)") }
        case .skippedOpsCannotThrow:
            // Each skipped op's arm in `FrameRenderer.apply` (from its `case .<op>` to the next line indented no
            // deeper) holds no `try` — but the calls `skippedTries` names (PT): their throws are census rows whose
            // checks read the level data, not the run (`Refusal.cellSlot`, the light pass's `Refusal.darkness` /
            // `lightIndex` / `overlay`, the grid's `Refusal.waterTable`), so skipping the op loses no refusal.
            let lines = render.filter { $0.file == "Frame/FrameRenderer.swift" }
            func indent(_ s: String) -> Int { s.prefix { $0 == " " }.count }
            func admitted(_ code: String, _ op: String) -> Bool {
                (Self.skippedTries[op] ?? []).contains { Self.has(code, $0) }
            }
            var tries = 0
            for op in Self.skippedOps {
                var arms = 0
                for (i, l) in lines.enumerated() {
                    let t = Self.trim(l.code)
                    guard t.hasPrefix("case ." + op + "(") || t.hasPrefix("case ." + op + ":")
                            || t.hasPrefix("case ." + op + " ") || t.hasPrefix("case ." + op + ",") else { continue }
                    arms += 1
                    let d = indent(l.code)
                    XCTAssertFalse(Self.has(l.code, "try "), "\(c): \(op) at line \(l.line)")
                    for m in lines[(i + 1)...] {
                        let u = Self.trim(m.code)
                        if !u.isEmpty && indent(m.code) <= d { break }
                        guard Self.has(m.code, "try ") else { continue }
                        if admitted(m.code, op) { tries += 1; continue }
                        XCTFail("\(c): \(op)'s arm, line \(m.line)")
                    }
                }
                XCTAssertGreaterThan(arms, 0, "\(c): no `case .\(op)` arm")
            }
            // Each admitted call is made (the mosaic copy and the plain copy: two `copyToScreen` arms).
            XCTAssertEqual(tries, 4, "\(c): the admitted calls")
        case .ripplePhaseHours:
            // 0x200 + 0x100·k stays non-negative for k < 2^23 − 2 frames: over 77 hours at 30 frames a second in one
            // level (a level start resets it: one renderer per level start).
            XCTAssertEqual(SpriteBlitter(level: audits[0].level.file, tables: audits[0].level.renderer.tables,
                                         faces: SpriteBlitter.Faces(sheets: [:])).ripplePhase, 0x200)
            let frames = (Int(Int32.max) - 0x200) / 0x100
            XCTAssertGreaterThanOrEqual(frames / 30 / 3600, 77)
            // In code: the phase starts at 0x200, its only writes are + 0x100 in the `.wrapEraseSprites` arm and
            // `setTile`'s hand-over to the rebuilt blitter; a renderer is built at each level start (`setupLevel`'s one
            // `services.prepare`). In the run: one renderer per level start, its phase 0x200 + 0x100 per erase applied.
            let blitter = render.filter { $0.file == "Frame/SpriteBlitter.swift" }
            XCTAssertTrue(blitter.contains { Self.trim($0.code) == "public var ripplePhase: Int32 = 0x200" }, "\(c): start")
            var writes: [String] = []
            for (k, l) in render.enumerated() where !Self.assignedFields(l.code, ["ripplePhase"]).isEmpty {
                writes.append("\(l.file) \(Self.trim(l.code))")
                if Self.has(l.code, "&+= 0x100") {
                    XCTAssertTrue(Self.enclosing(render, k).first.map { $0.hasPrefix("case .wrapEraseSprites(") } ?? false,
                                  "\(c): the step outside the erase arm")
                }
            }
            XCTAssertEqual(writes, ["Frame/FrameRenderer.swift sprites.ripplePhase &+= 0x100",
                                    "Frame/FrameRenderer.swift blitter.ripplePhase = sprites.ripplePhase"], "\(c)")
            let run = core.filter { $0.file == "Front/LevelRun.swift" }
            let prepares = run.indices.filter { Self.has(run[$0].code, "services.prepare(level:") }
            XCTAssertEqual(prepares.count, 1, "\(c): one level-start renderer")
            for k in prepares {
                XCTAssertTrue(Self.enclosing(run, k).contains { $0.hasPrefix("private func setupLevel(") }, "\(c)")
            }
            for a in audits {
                let s = a.seen
                XCTAssertEqual(s.prepares, s.restarts + 1, "\(c): level \(a.level.number) renderers")
                XCTAssertGreaterThan(s.erasesSinceStart, 0, "\(c): level \(a.level.number)")
                XCTAssertEqual(s.finalPhase, 0x200 &+ 0x100 &* Int32(s.erasesSinceStart), "\(c): level \(a.level.number)")
            }
        case .rotationRanges:
            for w in Self.writers where w.input == .rotation {
                guard case .range(let r) = w.values else { XCTFail("\(c): \(w.site)"); continue }
                XCTAssertTrue(r.lowerBound >= 0 && r.upperBound <= 359, "\(c): \(w.site)")
            }
        case .waterKindsInTables:
            // `water(w)`, w = BG kind − 200 for kinds 200…209 (`.RedrawScrollGrid`, `.PlainWrapFG(Overlay)Tile`): every
            // BG cell's kind of every built level leaves w inside the tables built (0…5).
            for a in audits {
                let L = a.level.file, n = a.level.renderer.tables.water.count
                XCTAssertEqual(n, 6, "\(c): level \(a.level.number) water tables")
                var kinds = Set<Int>()
                for row in 0..<L.bg.height {
                    for col in 0..<L.bg.width { kinds.insert(L.bgKind(tile: L.bgTile(col: col, row: row))) }
                }
                for k in kinds where LiquidTiles.range.contains(k) {
                    XCTAssertLessThan(k - 200, n, "\(c): level \(a.level.number) BG kind \(k)")
                }
            }
        case .overlaysInSet:
            // `overlayFace(o1:o2:)` (`.DrawLightsOntoTiles`, `.PlainWrapFGOverlayTile`): o1 > 99 → 100 / 101, o2 in
            // that set.
            for a in audits {
                let L = a.level.file, sets = a.level.renderer.grid.sets
                for row in 0..<L.overlay.height {
                    for col in 0..<L.overlay.width {
                        let o1 = L.overlay1(col: col, row: row)
                        guard o1 > 99 else { continue }
                        let o2 = L.overlay2(col: col, row: row)
                        let n = o1 == 100 ? sets.fg.faces.count : o1 == 101 ? sets.bg.faces.count : 0
                        XCTAssertTrue((0..<n).contains(o2),
                                      "\(c): level \(a.level.number) (\(col), \(row)) o1 \(o1) o2 \(o2)")
                    }
                }
            }
        case .pxMidSlotsLoaded:
            // A mid row (`xmRows[r] ≠ 0 && 0x3268 == 1`) reads the image and mask slots of the PxMid cells.
            for a in audits where a.level.file.header.pxMidEnable == 1 {
                let L = a.level.file, p = a.level.renderer.parallax
                for row in 0..<L.pxMid.height {
                    for col in 0..<L.pxMid.width {
                        let cell = L.pxMidTile(col: col, row: row)
                        for slot in [ParallaxBlitter.midImageBase + cell, ParallaxBlitter.midMaskBase + cell] {
                            XCTAssertTrue((0..<ParallaxBlitter.slotCount).contains(slot) && p.slotLoaded[slot],
                                          "\(c): level \(a.level.number) PxMid (\(col), \(row)) slot \(slot)")
                        }
                    }
                }
            }
        case .omniPxPortDraws:
            // OX: OmniPx's port on level 5 (mode 2; level 25's mode 5 shares the base path): every base cell the
            // counter can name (6 + (c >> 1), c reset above 0x11 before the copy: 6…14) is a loaded PxBack slot, and
            // every face `.SetupOmniPx` loads for modes 2 / 4 / 5 loads under the level+sprite CLUT and draws into the
            // port — the level start's turn-on, then one update per base cell with all four faces, no refusal.
            let r = try OmniPxTests.level5Renderer().renderer
            for cell in 6...14 {
                XCTAssertTrue(r.parallax.slotLoaded[ParallaxBlitter.backBase + cell], "\(c): level 5 base cell \(cell)")
            }
            let picts = OmniPx.facePicts(omniPxMode: 2) + OmniPx.facePicts(omniPxMode: 5)
            XCTAssertEqual(Set(picts), [6200, 6201, 6300, 6301], "\(c)")
            XCTAssertEqual(OmniPx.facePicts(omniPxMode: 4), OmniPx.facePicts(omniPxMode: 2), "\(c)")
            var ops: [DrawOp] = [.omniPx(.turnOn(omniPxMode: 2))]
            for cell in 6...14 {
                let faces = picts.map { OmniPxFrame.Face(pict: $0, x: -(cell * 7), y: -(cell * 5)) }
                ops.append(.omniPx(.update(OmniPxFrame(omniPxMode: 2, baseCell: cell, faces: faces))))
            }
            XCTAssertNoThrow(try r.apply(FrameOps(draws: ops)), "\(c)")
            XCTAssertEqual(r.executed, [.omniPxOn(2)] + Array(repeating: .omniPx(4), count: 9), "\(c)")
        case .headerOmniPxStrip:
            // Every built level opens: OmniPx 0 / 2 / 4 / 5 (built: 0; level 5's 2 arrives with LV5) and no horizon strip.
            for a in audits {
                let h = a.level.file.header
                XCTAssertTrue([0, 2, 4, 5].contains(h.omniPxMode),
                              "\(c): level \(a.level.number) OmniPx \(h.omniPxMode)")
                XCTAssertEqual(h.stripPict, 0, "\(c): level \(a.level.number) strip")
                XCTAssertNoThrow(try LevelRun.refuseUndrawnHeader(h), "\(c): level \(a.level.number)")
            }
            // A synthetic header (level 1's Mlvl, one byte changed) is refused by value.
            let mlvl = try XCTUnwrap(res.world.resources(of: "Mlvl").first { $0.id == 1 })
            func header(_ patch: (inout Data) -> Void) throws -> LevelHeader {
                var d = mlvl.data
                patch(&d)
                return try LevelFile(id: 1, data: d).header
            }
            for m: UInt8 in [0, 1, 2, 3, 4, 5, 6, 7, 8, 0xff] {
                let h = try header { $0[$0.startIndex + 0x26c7] = m }
                if [0, 2, 4, 5].contains(m) {
                    XCTAssertNoThrow(try LevelRun.refuseUndrawnHeader(h), "\(c): OmniPx \(m)")
                } else {
                    XCTAssertThrowsError(try LevelRun.refuseUndrawnHeader(h), "\(c): OmniPx \(m)") {
                        XCTAssertEqual($0 as? LevelOpenRefusal, .omniPxMode(m))
                    }
                }
            }
            let strip = try header { $0[$0.startIndex + 0x2716] = 0x13; $0[$0.startIndex + 0x2717] = 0x88 }
            XCTAssertThrowsError(try LevelRun.refuseUndrawnHeader(strip), "\(c): strip") {
                XCTAssertEqual($0 as? LevelOpenRefusal, .horizonStrip(0x1388))
            }
            // In code: `setupLevel` refuses before `services.prepare` (no renderer, no session); `GameFlow`'s level arm
            // catches a tick's error as `levelFailed` (the level-load report —
            // `GameFlowGameTests.testNewGameStartsLevel1` drives a patched header to it).
            let run = core.filter { $0.file == "Front/LevelRun.swift" }
            let refuse = run.indices.filter { Self.trim(run[$0].code) == "try Self.refuseUndrawnHeader(h)" }
            let prepare = run.indices.filter { Self.has(run[$0].code, "services.prepare(level:") }
            XCTAssertEqual(refuse.count, 1, "\(c): the level-open call")
            if let r = refuse.first, let p = prepare.first {
                XCTAssertLessThan(r, p, "\(c): refused before the renderer")
                XCTAssertTrue(Self.enclosing(run, r).contains { $0.hasPrefix("private func setupLevel(") }, "\(c)")
            }
            let flow = core.filter { $0.file == "Front/GameFlow.swift" }.map { Self.trim($0.code) }
            let tick = flow.firstIndex(of: "emit(try run.tick(now: now, input: input), &out)")
            XCTAssertNotNil(tick, "\(c): GameFlow's level tick")
            if let t = tick {
                XCTAssertEqual(Array(flow[(t + 1)...].prefix(2)), ["} catch {", "levelFailed = true"], "\(c)")
            }
        case .headerCamera:
            for a in audits {
                XCTAssertEqual(a.level.file.header.arenaBound, 0, "\(c): \(a.level.number)")
                XCTAssertEqual(a.level.file.header.autoScrollEnable, 0, "\(c): \(a.level.number)")
            }
        case .coreNotNamed(let type):
            // Only the type's own file names it in Core (and nothing on FerazelRender's level frame).
            let named = core.filter { Self.has($0.code, type) }.map(\.file)
            XCTAssertLessThanOrEqual(Set(named).count, 1, "\(c): named in \(Set(named).sorted())")
            for l in render where ["Frame/", "Effects/", "Faces/", "Color/"].contains(where: { l.file.hasPrefix($0) }) {
                XCTAssertFalse(Self.has(l.code, type), "\(c): \(l.file):\(l.line)")
            }
        case .callersTry(let calls):
            // Every Core call (not a declaration) is `try?` / `try!`, or the placement Setup's own `try`.
            var n = 0
            for l in core {
                for call in calls where Self.has(l.code, call) && !Self.has(l.code, "func ") {
                    n += 1
                    let ok = Self.has(l.code, "try?") || Self.has(l.code, "try!")
                        || (l.file == "Sprites/SetupFaces.swift" && call == "BonusSprite.setup(")
                    XCTAssertTrue(ok, "\(c): \(l.file):\(l.line)")
                }
            }
            XCTAssertGreaterThan(n, 0, "\(c): no caller")
        case .notNamedByLevelFrame(let type):
            // The level frame's code — `FrameRenderer` and what it calls (Frame/, Effects/, Faces/, Color/) — never
            // names the type.
            for l in render where ["Frame/", "Effects/", "Faces/", "Color/"].contains(where: { l.file.hasPrefix($0) }) {
                XCTAssertFalse(Self.has(l.code, type), "\(c): \(l.file):\(l.line)")
            }
        }
    }
}
