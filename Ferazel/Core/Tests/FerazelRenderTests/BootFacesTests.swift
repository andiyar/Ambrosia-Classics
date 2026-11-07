import XCTest
import FerazelCore
@testable import FerazelRender

/// The renderer loads every face the original loads at boot (`BootFaces`), then the level's caches — so no sprite Core
/// can make draws a face that is not loaded. The faces Core can reference are derived, not listed: every Setup sheet of
/// every placement in the shipped levels, every class sheet list Core declares, and every literal PICT in a
/// `FaceRef(pict:` / `Face(pict:` in Core's sources. A missing data file is a FAILURE, never a skip.
final class BootFacesTests: XCTestCase {
    nonisolated(unsafe) private static let resources = Result { try FerazelData.open(try FerazelData.dataDirectory()) }

    private static func sheet(_ loader: FaceSheet.Loader) -> SetupFaces.Sheet {
        switch loader {
        case .single(let pict): return .single(pict)
        case .set(let a):
            return SetupFaces.Sheet(pict: a.pict, count: a.count, cellWidth: a.cellWidth, cellHeight: a.cellHeight,
                                    columns: a.columns, clut: 200)
        }
    }

    /// Every sheet Core declares outside the per-placement Setups.
    private static var classSheets: [SetupFaces.Sheet] {
        BonusSprite.sheets + PlayerShot.sheets + EnemyShot.sheets + HeldItem.sheets + ButtonSprite.sheets
            + SetupFaces.boxChildSheets
            + SetupFaces.platformSheets + SetupFaces.backgroundSheets + SetupFaces.backgroundW2bSheets
            + Array(BoxSprite.spawnSheets) + Array(BonusSprite.dropSheets)
            + (FaceSheet.playerSheets + FaceSheet.gliderSheets).map(sheet)
    }

    /// The Setup sheets of every placement of `level` (the Setups not transcribed yet make none).
    private static func setupSheets(_ L: LevelFile) -> [SetupFaces.Sheet] {
        let ctx = SetupFaces.Context(level: L, playerX: SetupFaces.Context.levelStartPlayerX(L.header), effects: 1)
        return L.activePlacements.compactMap { try? SetupFaces.setup($0, context: ctx).sheet }
            + Array(BoxSprite.dropSheets(L.placements))
    }

    /// Core's `.swift` sources, read once: the number of files and every line with its `//` comment cut off. One code
    /// path on every platform, with no Foundation call Wine lacks (PB fix round 3): no directory enumerator (it reads
    /// file attributes — advapi32 under Wine), no regex (ICU) — only `contentsOfDirectory(atPath:)`,
    /// `fileExists(atPath:isDirectory:)` and `String(contentsOf:)`, which run green in Proof B elsewhere.
    private static let coreSources = Result { () throws -> (files: Int, lines: [String]) in
        let core = URL(fileURLWithPath: #filePath).resolvingSymlinksInPath().deletingLastPathComponent()
            .deletingLastPathComponent().deletingLastPathComponent().appendingPathComponent("Sources/FerazelCore")
        let fm = FileManager.default
        var files = 0, lines: [String] = [], folders = [core]
        while let dir = folders.popLast() {
            for name in try fm.contentsOfDirectory(atPath: dir.path).sorted() where !name.hasPrefix(".") {
                let url = dir.appendingPathComponent(name)
                var isDir: ObjCBool = false
                guard fm.fileExists(atPath: url.path, isDirectory: &isDir) else { continue }
                if isDir.boolValue { folders.append(url); continue }
                guard name.hasSuffix(".swift") else { continue }
                files += 1
                for line in try String(contentsOf: url, encoding: .utf8).split(separator: "\n") {
                    lines.append(String(line.split(separator: "//", maxSplits: 1, omittingEmptySubsequences: false)
                        .first ?? ""))
                }
            }
        }
        return (files, lines)
    }

    /// Every `Face(pict: <lit>` / `FaceRef(pict: <lit>` in `code` — `<lit>` one `0x…` hex or decimal literal, `Face`
    /// not preceded by a word character — followed (after optional whitespace) by a comma (a literal PICT, `computed`
    /// false) or by `+` / `&+` (a computed id `<lit> + <expr>`, `computed` true: `pict` is the base). Pure Swift over
    /// UTF-8 bytes.
    private static func facePictMatches(in code: String) -> [(pict: Int16, computed: Bool)] {
        let b = Array(code.utf8)
        func at(_ i: Int, _ s: String) -> Bool {
            let t = Array(s.utf8)
            return i + t.count <= b.count && b[i..<(i + t.count)].elementsEqual(t)
        }
        func isWord(_ c: UInt8) -> Bool {
            c >= 0x80 || c == 0x5f || (c >= 0x30 && c <= 0x39) || ((c | 0x20) >= 0x61 && (c | 0x20) <= 0x7a)
        }
        func digits(from i: Int, _ ok: (UInt8) -> Bool) -> Int {
            var j = i
            while j < b.count && ok(b[j]) { j += 1 }
            return j
        }
        let isDec: (UInt8) -> Bool = { $0 >= 0x30 && $0 <= 0x39 }
        let isHex: (UInt8) -> Bool = { isDec($0) || (($0 | 0x20) >= 0x61 && ($0 | 0x20) <= 0x66) }
        var out: [(pict: Int16, computed: Bool)] = [], i = 0
        while i < b.count {
            defer { i += 1 }
            guard at(i, "Face"), i == 0 || !isWord(b[i - 1]) else { continue }
            var j = i + 4
            if at(j, "Ref") { j += 3 }
            guard at(j, "(pict: ") else { continue }
            j += 7
            let value: Int?, end: Int
            if at(j, "0x"), digits(from: j + 2, isHex) > j + 2 {
                end = digits(from: j + 2, isHex)
                value = Int(String(decoding: b[(j + 2)..<end], as: UTF8.self), radix: 16)
            } else {
                end = digits(from: j, isDec)
                value = end > j ? Int(String(decoding: b[j..<end], as: UTF8.self)) : nil
            }
            var k = end
            while k < b.count && (b[k] == 0x20 || b[k] == 0x09) { k += 1 }
            guard let value, k < b.count else { continue }
            if b[k] == 0x2c {
                out.append((Int16(value), false))
            } else if at(k, "+") || at(k, "&+") {
                out.append((Int16(value), true))
            } else {
                continue
            }
            i = k
        }
        return out
    }

    /// The literal PICTs Core's sources face sprites with at run time (`FaceRef(pict: 0x…` / `Face(pict: 0x…`).
    private static func literalFacePicts() throws -> Set<Int16> {
        Set(try coreSources.get().lines.flatMap(facePictMatches).filter { !$0.computed }.map(\.pict))
    }

    /// The bases of the computed face ids Core's sources write (`FaceRef(pict: 0xc80 &+ k` / `Face(pict: 750 + item`).
    private static func computedFacePictBases() throws -> Set<Int16> {
        Set(try coreSources.get().lines.flatMap(facePictMatches).filter(\.computed).map(\.pict))
    }

    /// Every computed face id form `<base> + <expr>` Core writes, with the ids its class declares the expression takes.
    private static let computedFaceIds: [Int16: (what: String, picts: [Int16])] = [
        // `BoxSprite.createBalloon` (`.CreateBalloonSprite` M l. 59921–59966): the key's item icon 3200 + key, only for
        // keys 1…26 (its `0 < k && k < 0x1b` guard).
        0xc80: ("the thought balloon's key icon", (1...26).map { 0xc80 + Int16($0) }),
        // `HeldItem.face(item:)`: 750 + item, only where `HeldItem.facePicts` holds it (the singles `HeldItem.sheets`).
        750: ("the held item", HeldItem.sheets.map(\.pict)),
    ]

    /// `BootFaces` matches every other definition Core makes of the same PICT (cells, columns, CLUT), so the first
    /// definition the renderer loads is the one every reader expects.
    func testBootFacesAgreeWithEveryDeclaration() throws {
        let res = try Self.resources.get()
        let boot = Dictionary(uniqueKeysWithValues: BootFaces.sheets.map { ($0.pict, $0) })
        XCTAssertEqual(boot.count, BootFaces.sheets.count, "no PICT twice")
        var all = Self.classSheets
        for r in res.world.resources(of: "Mlvl") { all += Self.setupSheets(try LevelFile(resource: r)) }
        for s in all { if let b = boot[s.pict] { XCTAssertEqual(s, b, "PICT \(s.pict)") } }
        // ES: every enemy-shot boot set is a boot face; its level-load caches (0x46a, 0x77b) are not.
        for s in EnemyShot.sheets { XCTAssertEqual(boot[s.pict], s, "enemy shot PICT \(s.pict)") }
        for s in EnemyShot.cachedSheets { XCTAssertNil(boot[s.pict], "cache PICT \(s.pict)") }
        // WK1: the Walker Handles' four sets are level-load caches (`.CacheEncFaceSetFromPICT`, M l. 56757–56758,
        // 56762–56763), not boot faces, and no Setup-face table entry defines them otherwise; CR: so are the Crawler's
        // walk / jump / death sets (M l. 56142–56144) and the Roach's death set (M l. 64894); WK2: so are the Ax goblin's
        // walk / swing / jump / death sets (M l. 56764–56767).
        XCTAssertEqual(CachedFaces.handleSets.map(\.pict), [0x6a5, 0x6a6, 0x6aa, 0x6ab, 0x6ae, 0x6af, 0x6b1, 0x6b9,
                                                            0x6d7, 0x6d8, 0x6d9, 0x6da])
        // WK2: the 1750's single 0x6d6 is a level-load cache too (`.Cache1EncFaceFromPICT`, M l. 56756) — its Setup face.
        XCTAssertNil(boot[0x6d6])
        XCTAssertEqual(SetupFaces.sheet(pict: 0x6d6), .single(0x6d6))
        for s in CachedFaces.handleSets {
            XCTAssertNil(boot[s.pict], "cache PICT \(s.pict)")
            XCTAssertNil(SetupFaces.sheet(pict: s.pict), "cache PICT \(s.pict) in the Setup-face table")
        }
        // BA: `.InitBatSprite`'s five sets (M l. 68099–68103) are level-load caches, defined once — in the Setup-face
        // table, from which `CachedFaces.sheets(markedBy:)` takes their geometry; the spit 0x712 faces from the boot
        // singles 0x456 / 0x457 (the enemy-shot boot sets above), the coins from the boot set 0x516.
        for p: Int16 in [0x6cc, 0x744, 0x74d, 0x73a, 0x73b] {
            XCTAssertNil(boot[p], "Bat cache PICT \(p)")
            XCTAssertNotNil(SetupFaces.sheet(pict: p), "Bat cache PICT \(p) geometry")
            XCTAssertFalse(CachedFaces.handleSets.contains { $0.pict == p }, "Bat cache PICT \(p) defined twice")
        }
        XCTAssertNotNil(boot[0x456])
        XCTAssertNotNil(boot[0x457])
        XCTAssertNotNil(boot[0x516])
        // FR: `.InitFrogSprite`'s 0x708 and `.InitSalamanderSprite`'s 0x712 (M l. 70116, 70649) are level-load caches,
        // defined once in the Setup-face table; the spit 0x709 faces from the boot sets 0x454 / 0x455, the fireball
        // 0x712 from 0x456 / 0x457.
        for p in [FrogSalamander.frogSet, FrogSalamander.salamanderSet] {
            XCTAssertNil(boot[p], "cache PICT \(p)")
            XCTAssertNotNil(SetupFaces.sheet(pict: p), "cache PICT \(p) geometry")
            XCTAssertFalse(CachedFaces.handleSets.contains { $0.pict == p }, "cache PICT \(p) defined twice")
        }
        XCTAssertNotNil(boot[0x454])
        XCTAssertNotNil(boot[0x455])
        // BL: `.InitBlobSprite`'s 0x6c2 (M l. 67666) and `.InitCrabSprite`'s set 0x762 and single 0x767 (M l.
        // 73964–73965) are level-load caches, defined once in the Setup-face table; the spawned link type 0x767 faces
        // from that single.
        for p in [BlobCrab.blobSet, BlobCrab.clawSet, BlobCrab.linkFace] {
            XCTAssertNil(boot[p], "cache PICT \(p)")
            XCTAssertNotNil(SetupFaces.sheet(pict: p), "cache PICT \(p) geometry")
            XCTAssertFalse(CachedFaces.handleSets.contains { $0.pict == p }, "cache PICT \(p) defined twice")
        }
        XCTAssertEqual(SetupFaces.sheet(pict: BlobCrab.linkFace), .single(0x767))
        XCTAssertEqual(CachedFaces.sheets(markedBy: [BlobCrab.linkType]).map(\.pict), [0x762, 0x767])
        // GF: `.InitGremlinSprite`'s 0x6ea / 0x6eb / 0x6ec and `.InitFloaterSprite`'s 0x6f4 (M l. 69118–69120, 69825)
        // are level-load caches, defined once in the Setup-face table; the rider's shot 0x712 faces from the boot singles
        // 0x456 / 0x457 (above), the Wraith's bolt 0x6f4 from the enemy-shot boot set 0x45d. The 1790 variant's 0x6fe /
        // 0x6ff (M l. 69828–69829) are absent from the data and defined nowhere (the variant is refused).
        for p in [GremlinFloater.bodySet, GremlinFloater.backSet, GremlinFloater.riderSet, GremlinFloater.wraithSet] {
            XCTAssertNil(boot[p], "cache PICT \(p)")
            XCTAssertNotNil(SetupFaces.sheet(pict: p), "cache PICT \(p) geometry")
            XCTAssertFalse(CachedFaces.handleSets.contains { $0.pict == p }, "cache PICT \(p) defined twice")
        }
        for p: Int16 in [0x6fe, 0x6ff] {
            XCTAssertNil(res.resource(type: "PICT", id: p, chain: .frontEnd), "PICT \(p) absent")
            XCTAssertNil(SetupFaces.sheet(pict: p))
            XCTAssertNil(boot[p])
        }
        XCTAssertEqual(CachedFaces.sheets(markedBy: [Int16(0x6ea), 0x6f4, 0x6fe]).map(\.pict), [0x6ea, 0x6eb, 0x6ec, 0x6f4])
    }

    /// Levels 1–4: every boot face the data holds, every class sheet Core declares and every Setup sheet of the level's
    /// placements is loaded; and every literal PICT Core faces a sprite with is one of those or a per-level cache face
    /// `.LoadCachedSpriteFaces` loads for some level 1–4 (`CachedFaces.needed`) — a cache face is drawn only by the type
    /// whose Setup sheet carries it, which the first check covers on the levels that place it.
    func testEveryReferencedFaceIsLoaded() throws {
        let res = try Self.resources.get()
        let literals = try Self.literalFacePicts()
        let scanned = try Self.coreSources.get().files
        XCTAssertGreaterThanOrEqual(scanned, 100, "Core .swift files scanned (0 = the source walk found nothing)")
        XCTAssertGreaterThanOrEqual(literals.count, 15, "literal face PICTs in \(scanned) Core .swift files")
        let present: (Int16) -> Bool = { res.resource(type: "PICT", id: $0, chain: .frontEnd) != nil }
        let always = Set(BootFaces.sheets.map(\.pict) + Self.classSheets.map(\.pict))
        var cachedSomewhere = Set<Int16>()
        for level in BuiltLevels.range {
            let r = try FrameRenderer(resources: res, level: level, search: ColorSearch(model: .ruled, tieBreak: .lowest),
                                      dither: .errorDiffusion, text: StatusBarTests.BoxRasterizer(), prefs: FerazelPrefs())
            let loaded = r.sprites.faces.sheets
            for p in always.union(Self.setupSheets(r.level).map(\.pict)).sorted() where present(p) {
                XCTAssertNotNil(loaded[p], "level \(level): PICT \(p) (0x\(String(p, radix: 16))) not loaded")
            }
            // WK1: every cache face the level's Setups mark (`.LoadCachedSpriteFaces`) is loaded — the Walker Handles
            // face from the marked 0x6a5 / 0x6a6 (the 1700's, M l. 56966–56969) and 0x6aa / 0x6ab (the 1705's, M l.
            // 56977–56980), which no Setup sheet carries.
            let marked = CachedFaces.sheets(markedBy: r.level.activePlacements.map(\.type))
            let types = Set(r.level.activePlacements.map(\.type))
            if types.contains(Walker.thrower) {
                XCTAssertTrue(marked.contains(CachedFaces.handleSets[0]) && marked.contains(CachedFaces.handleSets[1]),
                              "level \(level): the 1700's walk / throw sets marked")
            }
            if types.contains(Walker.spearGuard) {
                XCTAssertTrue(marked.contains(CachedFaces.handleSets[2]) && marked.contains(CachedFaces.handleSets[3]),
                              "level \(level): the 1705's turn / thrust sets marked")
            }
            // CR: the Crawler Handle faces from 0x6ae / 0x6af / 0x6b1 (marked by its Setup, M l. 56188–56190), the Roach
            // Handle from 0x6b8 (its Setup sheet) and 0x6b9 (M l. 64931–64932); the ceiling face 0x6b0 is a boot single.
            if types.contains(CrawlerRoach.crawler) {
                XCTAssertTrue(CachedFaces.handleSets[4...6].allSatisfy(marked.contains), "level \(level): the Crawler's sets")
                XCTAssertNotNil(loaded[CrawlerRoach.ceilingFace], "level \(level): the ceiling face")
            }
            if types.contains(CrawlerRoach.roach) {
                XCTAssertTrue(marked.contains(CachedFaces.handleSets[7]), "level \(level): the Roach's death set")
                XCTAssertNotNil(loaded[CrawlerRoach.roachWalk], "level \(level): the Roach's walk set")
            }
            // BA: the Bat Handle faces every 1740-family type from the 0x6cc set its Setup marks (M l. 68286).
            if types.contains(where: { (0x6cc...0x6d5).contains($0) }) {
                XCTAssertTrue(marked.contains { $0.pict == Bat.batSet }, "level \(level): the bat set marked")
                XCTAssertEqual(loaded[Bat.batSet]?.arguments.count, 0xb, "level \(level): the bat set's 11 cells")
            }
            for sh in marked where present(sh.pict) {
                let a = loaded[sh.pict]?.arguments
                XCTAssertEqual(a.map { [$0.count, $0.cellWidth, $0.cellHeight, $0.columns] },
                               sh.single ? a.map { [$0.count, $0.cellWidth, $0.cellHeight, $0.columns] }
                                         : [sh.count, sh.cellWidth, sh.cellHeight, sh.columns],
                               "level \(level): marked cache PICT \(sh.pict) not loaded as marked")
                XCTAssertNotNil(a, "level \(level): marked cache PICT \(sh.pict) not loaded")
            }
            let s = try FerazelSession(resources: res, prefs: FerazelPrefs(), level: level, seed: 1,
                                       faceBounds: r.faceBounds)
            let needed = CachedFaces.needed(by: s)
            cachedSomewhere.formUnion(literals.filter { needed.sets.contains($0) || needed.singles.contains($0) })
        }
        for p in literals.subtracting(always).sorted() {
            XCTAssertTrue(cachedSomewhere.contains(p), "PICT \(p) (0x\(String(p, radix: 16))): a literal face no loader knows")
        }
    }

    /// RV (Q15 item 6): the computed face ids — every `<base> + <expr>` form Core's sources face a sprite with — each
    /// resolved by the ids its class declares (`computedFaceIds`), and on levels 1–4 every one the data holds is loaded.
    /// The same Wine-safe source walk and matcher as the literal scan.
    func testComputedFacePictsAreLoaded() throws {
        let res = try Self.resources.get()
        let bases = try Self.computedFacePictBases()
        XCTAssertGreaterThanOrEqual(try Self.coreSources.get().files, 100, "Core .swift files scanned")
        XCTAssertEqual(bases.sorted(), Self.computedFaceIds.keys.sorted(),
                       "every computed face id form in Core has its declared range, and every declared one is found")
        let present: (Int16) -> Bool = { res.resource(type: "PICT", id: $0, chain: .frontEnd) != nil }
        for (base, form) in Self.computedFaceIds {
            XCTAssertTrue(form.picts.contains(where: present), "\(form.what) (\(base) + …): the data holds none")
        }
        for level in BuiltLevels.range {
            let r = try FrameRenderer(resources: res, level: level, search: ColorSearch(model: .ruled, tieBreak: .lowest),
                                      dither: .errorDiffusion, text: StatusBarTests.BoxRasterizer(), prefs: FerazelPrefs())
            let loaded = r.sprites.faces.sheets
            for (base, form) in Self.computedFaceIds.sorted(by: { $0.key < $1.key }) {
                for p in form.picts where present(p) {
                    XCTAssertNotNil(loaded[p], "level \(level): \(form.what) PICT \(p) (\(base) + \(p - base)) not loaded")
                }
            }
        }
    }

    private static func fnv(_ bytes: some Sequence<UInt8>, _ h0: UInt64 = 0xcbf29ce484222325) -> UInt64 {
        var h = h0
        for b in bytes { h = (h ^ UInt64(b)) &* 0x100000001b3 }
        return h
    }

    /// RV (Q15 item 6): loading every boot face (b535527) moved no hot rect and no particle emitter's source face. Each
    /// level 1–4 session (the renderer's `faceBounds` and `particleFaces`, as the apps build it) at its start and after
    /// 30 and 120 idle frames: one row per active sprite (list order) and per idle entry — type, record, hot rect, the
    /// idle entry's face rect (`.ActiveToIdleSprite`), the face, its bounds (`faceBounds`) and its emitter face
    /// (`particleFaces.sprite`: frame, bounds, tokens, FNV-1a). The rows' count and FNV-1a are pinned from `b535527^`
    /// (the tree before the boot faces, measured with this same row text, 2026-10-30, loop run 37). No row differs.
    func testHotRectsAndEmittersUnchangedByBootFaces() throws {
        let res = try Self.resources.get()
        // (level, phase) → (rows, FNV-1a of the rows' text, one "\n" after each), measured at b535527^. WK1 (◈) re-pinned
        // the FNVs (row counts unchanged): `.SetupWalkerSprite` now sets the Walkers' hot rects and the Walker Handle
        // re-faces them; with the Walker's `forClass` row and Setup switched back off every b535527^ value returns. CR (◈)
        // re-pinned them again (counts unchanged): `.SetupCrawlerSprite` / `.SetupRoachSprite` set the hot rects (0x14,
        // 0xc, 0x2c, 0x21) / (0x23, 0x1b, 0x44, 0x2d) and their Handles re-face them; with the two `forClass` rows and the
        // Setups switched back off the WK1 values return (was L1 f478cf71be64b444 / fd95d79c159b3841 / 9a2c740b2d61f7a3,
        // L2 8667712c97eea1fa / d2ea580ff2c8d3ba / cc76204bbc1385bd, L3 9d0811a45f709596 / 9bcd46780b6ba8ea /
        // 50bcf3ea0ff24018, L4 fec73bab774581f5 / 9b87a71eafe9f70c / d53bf909322b2ca4). BA (◈) re-pinned L3 f30 / f120
        // (counts unchanged): level 3's path bat 1741 (rec 189) runs one Handle at frame 1 before it idles — its
        // animation takes `+0xa6` 1 → 2, face 0x6cc cell 0 → 1 (M l. 68826–68832), which its idle entry keeps; with that
        // one type's Handle switched back off (every other Bat's left on) the CR values return (was 0xd4f7e113045d39a2 /
        // 0x5a2e3d4e64f7c1ee). BL (run 44) re-pinned L3 f30 / f120 (counts unchanged): the level-3 Blob rec 15 runs one
        // Handle at start then idles (BL, run 44); with the Blob Handle stubbed (switch-off check) every old value
        // returned — was f30 0x07212368c70e3f4a, f120 0x521fd141e046a4d6; now 0x56a7ccb0dd544488 / 0xc43bacea46d2ff94.
        let pinned: [String: (rows: Int, fnv: UInt64)] = [
            "L1 init": (190, 0x157d6742ce800e1f), "L1 f30": (240, 0x8190d7eb68896260), "L1 f120": (240, 0xcda33ae9706a4618),
            "L2 init": (229, 0x8fb8d314f8d35783), "L2 f30": (278, 0x7e9c0511f07e745d), "L2 f120": (278, 0x35c9c2eb3280e4b0),
            "L3 init": (234, 0x9ee49e49aaa668a4), "L3 f30": (310, 0x56a7ccb0dd544488), "L3 f120": (310, 0xc43bacea46d2ff94),
            "L4 init": (264, 0x1d9360dec485c68b), "L4 f30": (342, 0x96ede8588083992a), "L4 f120": (342, 0xc6e32956a351c41f),
        ]
        func rect(_ x: IdleSprites.Rect) -> String { "(\(x.top),\(x.left),\(x.bottom),\(x.right))" }
        func emitter(_ f: ParticleFace?) -> String {
            guard let f else { return "nil" }
            let words = (f.frame + f.bounds).flatMap { [UInt8(truncatingIfNeeded: $0 >> 8), UInt8(truncatingIfNeeded: $0)] }
            return String(Self.fnv(words + f.tokens), radix: 16)
        }
        var measured: [String: (rows: Int, fnv: UInt64)] = [:]
        for level in 1...4 {
            let r = try FrameRenderer(resources: res, level: level, search: ColorSearch(model: .ruled, tieBreak: .lowest),
                                      dither: .errorDiffusion, text: StatusBarTests.BoxRasterizer(), prefs: FerazelPrefs())
            let faces = r.particleFaces
            let s = try FerazelSession(resources: res, prefs: FerazelPrefs(), level: level, seed: 1,
                                       faceBounds: r.faceBounds, particleFaces: faces)
            func face(_ ref: FaceRef?) -> String {
                ref.map { "\($0.pict):\($0.index) fb\(rect(r.faceBounds($0))) pf\(emitter(faces.sprite($0)))" } ?? "-"
            }
            func rows(_ phase: String) {
                let tag = "L\(level) \(phase)"
                var lines: [String] = []
                for (i, a) in s.world.active.sprites.enumerated() {
                    lines.append("\(tag) A\(i) t\(a.type) rec\(a.recordIndex) hot\(rect(a.hotRect)) \(face(a.face))")
                }
                for (e, x) in s.world.idle.entries.enumerated() {
                    guard let x else { continue }
                    let a = x.saved
                    lines.append("\(tag) I\(e) t\(a.type) rec\(a.recordIndex) hot\(rect(a.hotRect)) face\(rect(x.faceRect)) "
                                 + face(a.face))
                }
                measured[tag] = (lines.count, Self.fnv(lines.flatMap { Array(($0 + "\n").utf8) }))
            }
            rows("init")
            for f in 1...120 {
                _ = s.step(keys: KeyState())
                if f == 30 || f == 120 { rows("f\(f)") }
            }
        }
        XCTAssertEqual(measured.keys.sorted(), pinned.keys.sorted())
        for (k, want) in pinned.sorted(by: { $0.key < $1.key }) {
            XCTAssertEqual(measured[k]?.rows, want.rows, "\(k): rows")
            XCTAssertEqual(measured[k]?.fnv, want.fnv, "\(k): rows' FNV-1a (0x\(String(measured[k]?.fnv ?? 0, radix: 16)))")
        }
    }
}
