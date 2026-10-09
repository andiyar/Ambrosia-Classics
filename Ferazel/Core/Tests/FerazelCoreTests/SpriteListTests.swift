import XCTest
import HectorResources
@testable import FerazelCore

/// R4 (docs/plans/2026-10-06-ferazel-phase1.md): level 1's placed sprites in the faces their class Setups leave
/// (`SetupFaces`, Research note 15), the layer-sorted active list (`.MTInsertSprite @ 10032f1c`, physics §0 `+0x80`,
/// platforms-ropes-radial-2 §8.2), the `.SetupLevelSprites` spawn passes (world-data §3.4) and the idle table
/// (`.HandleIdleSprites @ 100081ac`, triggers-background-2 §8.3), against the committed `Resources/Ferazel` (D26).
/// A missing data file is a FAILURE, never a skip.
final class SpriteListTests: XCTestCase {

    private func resources() throws -> FerazelResources { try FerazelData.open(try FerazelData.dataDirectory()) }

    private func context() throws -> (FerazelResources, SetupFaces.Context) {
        let r = try resources()
        let level = try LevelFile.load(from: r, level: 1)
        return (r, SetupFaces.Context(level: level, playerX: SetupFaces.Context.levelStartPlayerX(level.header)))
    }

    private func entry(_ c: SetupFaces.Context, record: Int) throws -> SetupFaces.Entry {
        try SetupFaces.setup(c.level.placements[record], context: c)
    }

    // MARK: - SetupFaces

    func testSetupFacesLevel1Types() throws {
        let (r, c) = try context()
        let active = c.level.activePlacements
        XCTAssertEqual(active.count, 162)
        let types = Set(active.map(\.type))
        XCTAssertEqual(types.count, 42)   // Research note 15 (p02)
        var entries: [SetupFaces.Entry] = []
        for p in active { entries.append(try SetupFaces.setup(p, context: c)) }   // none unmapped, none refused
        XCTAssertEqual(Set(entries.map(\.type)), types)

        // Every sheet a level-1 entry names is a PICT on its chain.
        for sheet in Set(entries.compactMap(\.sheet)) {
            XCTAssertNotNil(r.resource(type: "PICT", id: sheet.pict, chain: .frontEnd), "PICT \(sheet.pict)")
        }

        // Spot checks, one per Setup arm met on level 1 (decompile: `.SetupBackgroundSprite` l. 61919–62678,
        // `.SetupBonusSprite` 52338–52804, `.SetupBoxSprite` 58892–59730, `.SetupPlatformSprite` 54497–54536,
        // `.SetupWalkerSprite` 56898–57100, `.SetupCrawlerSprite` 56153–56246, `.SetupRoachSprite` 64899–64957).
        func check(_ record: Int, type: Int16, layer: Int32, mode: UInt32, mirrored: Bool = false, light: Bool,
                   pict: Int16?, index: Int = 0, source: SetupFaces.FaceSource, clut: Int16 = 200,
                   line: UInt = #line) throws {
            let e = try entry(c, record: record)
            XCTAssertEqual(e.type, type, line: line)
            XCTAssertEqual(e.slot.layer, layer, "layer", line: line)
            XCTAssertEqual(e.slot.mode, mode, "mode", line: line)
            XCTAssertEqual(e.slot.mirrored, mirrored, "+0x17e", line: line)
            XCTAssertEqual(e.slot.lightOverlay, light, "+0x88", line: line)
            XCTAssertFalse(e.slot.dynamicLight, "+0x89", line: line)
            XCTAssertEqual(e.slot.margins, SpriteSlot.Margins(), "margins", line: line)
            XCTAssertEqual(e.sheet?.pict, pict, "sheet", line: line)
            XCTAssertEqual(e.faceIndex, index, "face", line: line)
            XCTAssertEqual(e.source, source, "source", line: line)
            if let s = e.sheet { XCTAssertEqual(s.clut, clut, "conversion CLUT", line: line) }
            let p = c.level.placements[record]
            XCTAssertEqual(e.slot.x, Int(p.x), line: line); XCTAssertEqual(e.slot.y, Int(p.y), line: line)
            XCTAssertEqual(e.slot.face == nil, source == .none, line: line)
        }
        // Background: cannon 1090 (layer 1000, face from the aim), mace 1485 (cache 1480+5), plants (cache 0xa8c+i,
        // CLUT flag 1 → level+base 202; p1 mirrors, p2 tints, p3 → layer 10000), tunnel 3002, exit 3249 (no face).
        try check(41, type: 1090, layer: 1000, mode: 0, light: true, pict: 1090, source: .handle)
        try check(16, type: 1485, layer: 1, mode: 0, light: false, pict: 1485, source: .setupCached)
        try check(139, type: 2710, layer: -100, mode: 0x10006, light: true, pict: 2710, source: .setupCached, clut: 202)
        try check(140, type: 2710, layer: -100, mode: 0x10007, mirrored: true, light: true, pict: 2710,
                  source: .setupCached, clut: 202)
        try check(145, type: 2713, layer: -100, mode: 0x10016, mirrored: true, light: true, pict: 2713,
                  source: .setupCached, clut: 202)
        try check(56, type: 3002, layer: 0, mode: 0, light: true, pict: 3002, source: .setupCached, clut: 202)
        try check(66, type: 3249, layer: 1, mode: 0, light: true, pict: nil, source: .none)
        // Bonus (layer 1): faces from the Handle except the item 3204.
        try check(10, type: 1055, layer: 1, mode: 0, light: false, pict: 1057, source: .handle)
        try check(131, type: 1059, layer: 1, mode: 0, light: false, pict: nil, source: .none)
        try check(154, type: 1292, layer: 1, mode: 0, light: false, pict: 1292, source: .handle)
        try check(4, type: 1303, layer: 1, mode: 0, light: true, pict: 1303, source: .handle)
        try check(3, type: 1307, layer: 1, mode: 0, light: false, pict: 1307, source: .handle)
        try check(2, type: 1335, layer: 1, mode: 0, light: false, pict: 1335, source: .handle)
        try check(68, type: 3204, layer: 1, mode: 0, light: false, pict: 3204, source: .setup)
        // Box (layer 2 unless the arm says): teleporter, save point p1, chest, bridge, decorations, outcrop, mushrooms,
        // sign, door, furniture, NPCs, crates.
        try check(126, type: 1062, layer: 2, mode: 0, light: true, pict: 1062, source: .setup)
        try check(24, type: 1065, layer: 2, mode: 0, light: true, pict: 1065, source: .setup)
        try check(23, type: 1308, layer: 0, mode: 0, light: true, pict: 1308, source: .setup)
        try check(87, type: 1464, layer: 0, mode: 0, light: true, pict: 1464, source: .handle, clut: 202)
        try check(158, type: 2842, layer: 10000, mode: 0, mirrored: true, light: true, pict: 2842, source: .setupCached)
        try check(160, type: 2842, layer: 10000, mode: 0x10016, light: true, pict: 2842, source: .setupCached)
        try check(78, type: 2870, layer: 120, mode: 0, light: true, pict: 2870, source: .handle)
        try check(1, type: 2902, layer: 0, mode: 0, light: true, pict: 2902, source: .setup)
        try check(55, type: 2910, layer: 0, mode: 0, light: true, pict: 2910, source: .setup)
        try check(0, type: 2922, layer: 0, mode: 0, light: true, pict: 2922, source: .handle)
        try check(157, type: 2951, layer: 0, mode: 0, light: true, pict: 2951, source: .handle)
        try check(31, type: 3090, layer: 2, mode: 0, light: true, pict: 3090, source: .setup)
        // Outcrop 2853: `.GetAmbDarkVal(x, y)` > 4 → 0x10006, > 7 → 0x10007 (header 0x2706 = 5 ≠ 0).
        let outcrop = try entry(c, record: 74)
        let D = c.level.lightByte(col: 3037 >> 5, row: 512 >> 5)
        XCTAssertEqual(D, 7)
        XCTAssertEqual(outcrop.slot.mode, 0x10006)
        // The thresholds (`> 4`, `> 7`), from literal values: an outcrop on a cell of each darkness 4, 5, 7, 8.
        for (dark, mode) in [(4, UInt32(0)), (5, 0x10006), (7, 0x10006), (8, 0x10007)] {
            let cellAt = (0..<Int(c.level.header.gridHeight)).lazy.flatMap { r in
                (0..<Int(c.level.header.gridWidth)).lazy.map { (col: $0, row: r) }
            }.first { c.level.lightByte(col: $0.col, row: $0.row) == dark }
            let at = try XCTUnwrap(cellAt, "a cell of darkness \(dark)")
            let p = Placement(index: 74, flag: 1, byte1: 0, type: 2853, p1: 0, p2: 0, p3: 0, p4: 0,
                              y: Int16(at.row * 32), x: Int16(at.col * 32))
            XCTAssertEqual(try SetupFaces.setup(p, context: c).slot.mode, mode, "darkness \(dark)")
        }
        XCTAssertEqual(outcrop.slot.layer, 150)
        XCTAssertFalse(outcrop.slot.lightOverlay)
        XCTAssertEqual(outcrop.sheet?.clut, 202)
        // Platform: layer −1, face from `.DoSetupPlatformSprite` = set 1400 (10 × 80×41) cell type − 1400.
        try check(25, type: 1400, layer: -1, mode: 0, light: true, pict: 1400, index: 0, source: .handle)
        try check(14, type: 1402, layer: -1, mode: 0, light: true, pict: 1400, index: 2, source: .handle)
        // Walker: layer 4; mirrored while the player is left of x + 50; tier p3 = 1 → 0x10010; 1705 / 1760 sets.
        try check(17, type: 1700, layer: 4, mode: 0x10010, mirrored: true, light: true, pict: 1700,
                  source: .setupCached)
        try check(26, type: 1705, layer: 4, mode: 0, mirrored: true, light: true, pict: 1705, source: .setupCached)
        try check(73, type: 1760, layer: 4, mode: 0, mirrored: true, light: true, pict: 1760, source: .setupCached)
        // Crawler p1 = 0: Setup's face slot is PICT 1500, which no file holds (0); the Handle's ceiling face 1712
        // (layer 11). Roach: cached set 1720 (layer 11).
        try check(9, type: 1712, layer: 11, mode: 0, light: true, pict: 1712, source: .handle)
        // Crawler tiers p2 (literal: 1 → 0x10002, 2 → 0x10003, 3 → 0x1000f; enemies-ground §4).
        for (tier, mode) in [(Int16(1), UInt32(0x10002)), (2, 0x10003), (3, 0x1000f)] {
            let p = Placement(index: 9, flag: 1, byte1: 0, type: 1712, p1: 0, p2: tier, p3: 0, p4: 0, y: 452, x: 1340)
            XCTAssertEqual(try SetupFaces.setup(p, context: c).slot.mode, mode, "tier \(tier)")
        }
        // The lights the Setups add (`.AddLight`; prefs Effects 1): torch 1307 light 801 192×192 at (x + 5, y + 8),
        // colour 0x16 (p3 = 0); Xichron 1055 light 822 52×52 at (+16, +16), 0x16 — only with Effects 1; money bag
        // 1292 light 822, colour 99 (Effects 1); sphere 1335 and item 3204 light 810 72×72, colour 99, ungated.
        XCTAssertEqual(try entry(c, record: 3).light, SetupFaces.Light(pict: 801, width: 192, height: 192,
                                                                       x: 633 + 5, y: 322 + 8, colour: 0x16))
        XCTAssertEqual(try entry(c, record: 10).light, SetupFaces.Light(pict: 822, width: 52, height: 52,
                                                                        x: 3188 + 16, y: 430 + 16, colour: 0x16))
        XCTAssertEqual(try entry(c, record: 154).light?.colour, 99)
        XCTAssertEqual(try entry(c, record: 2).light, SetupFaces.Light(pict: 810, width: 72, height: 72,
                                                                       x: 1953 + 16, y: 758 + 16, colour: 99))
        XCTAssertEqual(try entry(c, record: 68).light, SetupFaces.Light(pict: 810, width: 72, height: 72,
                                                                        x: 291 + 16, y: 123 + 12, colour: 99))
        XCTAssertEqual(try entry(c, record: 3).light?.radius, 96)
        XCTAssertNil(try entry(c, record: 4).light)
        let reduced = SetupFaces.Context(level: c.level, playerX: c.playerX, effects: 3)
        XCTAssertNil(try SetupFaces.setup(c.level.placements[10], context: reduced).light)
        XCTAssertNil(try SetupFaces.setup(c.level.placements[154], context: reduced).light)
        XCTAssertNotNil(try SetupFaces.setup(c.level.placements[3], context: reduced).light)
        // Every one of them, in `.AddLight` order: 22 torches + 43 Xichrons + 1 bag + 1 sphere + 1 item (Effects 1);
        // 22 + 1 + 1 with Effects 3. The Xichron gate (< 150 lights) never closes on level 1.
        XCTAssertEqual(try SetupFaces.spawnLevelSprites(context: c) { _ in .noFace }.lights.count, 22 + 43 + 1 + 1 + 1)
        XCTAssertEqual(try SetupFaces.spawnLevelSprites(context: reduced) { _ in .noFace }.lights.count, 22 + 1 + 1)
        XCTAssertEqual(try SetupFaces.setup(c.level.placements[10], context: c, lightsInUse: 150).light, nil)
        try check(15, type: 1720, layer: 11, mode: 0, light: true, pict: 1720, source: .setupCached)

        // Sheet arguments (Init<Class>Sprite calls).
        XCTAssertEqual(SetupFaces.sheet(pict: 1400), SetupFaces.Sheet(pict: 1400, count: 10, cellWidth: 0x50,
                                                                      cellHeight: 0x29, columns: 10, clut: 200))
        XCTAssertEqual(SetupFaces.sheet(pict: 1307), SetupFaces.Sheet(pict: 1307, count: 6, cellWidth: 10,
                                                                      cellHeight: 0x1c, columns: 6, clut: 200))
        XCTAssertEqual(SetupFaces.sheet(pict: 1705), SetupFaces.Sheet(pict: 1705, count: 3, cellWidth: 0xcc,
                                                                      cellHeight: 0x59, columns: 1, clut: 200))
        XCTAssertEqual(SetupFaces.sheet(pict: 2910)?.count, 6)
        XCTAssertEqual(SetupFaces.sheet(pict: 1090)?.cellWidth, 0x96)

        // The Setup modes level 1 stores, and the gate-card list (faces Phase 1 does not compute).
        let modes = Set(entries.map(\.slot.mode))
        XCTAssertTrue(modes.isSubset(of: [0, 0x10006, 0x10007, 0x10010, 0x10016, 0x90000]), "\(modes)")
        XCTAssertTrue(entries.allSatisfy { !$0.slot.dynamicLight })   // no `+0x89` on level 1: modes 0xb/0xc unreached
        let gate = Set(entries.filter { $0.source == .handle }.map(\.type))
        XCTAssertEqual(gate, [1090, 1055, 1292, 1303, 1307, 1335, 1464, 2853, 2870, 2871, 2874, 2883, 2922, 2924,
                              2927, 2951, 2952, 1400, 1401, 1402, 1403, 1712])
    }

    // MARK: - ActiveList

    func testActiveListLayerOrder() {
        var list = ActiveList()
        func add(_ type: Int16, _ layer: Int32) { list.insert(SpriteSlot(type: type, x: 0, y: 0, layer: layer)) }
        add(1, 5)
        add(2, -3)    // < head → new head
        add(3, 5)     // tie: after the existing 5
        add(4, 0)     // between −3 and the 5s
        add(5, -3)    // tie with the head: after it
        add(6, 10)    // tail
        add(7, -500)  // new head
        XCTAssertEqual(list.sprites.map(\.type), [7, 2, 5, 4, 1, 3, 6])
        XCTAssertEqual(list.sprites.map(\.layer), [-500, -3, -3, 0, 5, 5, 10])
        // `.MTInsertSprite` compares the head, then each `next` (raw 10032f44 / 10032f80, `bge` on equal): an
        // unsorted list (a direct +0x80 store does not re-sort) is walked, not re-sorted.
        let id = list.sprites[3].id
        list.update(id: id) { $0.layer = 100 }   // a direct store, as `.HandleStatueSprite` does
        add(8, 6)
        XCTAssertEqual(list.sprites.map(\.type), [7, 2, 5, 8, 4, 1, 3, 6])   // before the first next above 6
        XCTAssertEqual(list.remove(id: id)?.type, 4)
        XCTAssertEqual(list.sprites.map(\.type), [7, 2, 5, 8, 1, 3, 6])
        XCTAssertNil(list.sprite(id: id))
    }

    func testSpawnOrderLevel1() throws {
        let (_, c) = try context()
        let spawned = try SetupFaces.spawnLevelSprites(context: c) { _ in .noFace }
        let order = spawned.created.map { c.level.placements[$0] }
        XCTAssertEqual(order.count, 162)
        XCTAssertEqual(order.prefix(22).map(\.type), Array(repeating: 1307, count: 22))
        XCTAssertEqual(order.dropFirst(22).prefix(7).map(\.type), [1402, 1403, 1400, 1400, 1400, 1401, 1401])
        XCTAssertFalse(order.dropFirst(29).contains { $0.type == 1307 || (1400...1429).contains($0.type) })
        for group in [Array(order.prefix(22)), Array(order.dropFirst(22).prefix(7)), Array(order.dropFirst(29))] {
            XCTAssertEqual(group.map(\.index), group.map(\.index).sorted())
        }
        XCTAssertEqual(order.map(\.index), c.level.spawnOrder.map(\.index))
        // Spawned now (`MTNewSprite`, inserted by the Setup's layer): 7 platforms (−1), then 1335, 1485, 1485 (1).
        XCTAssertEqual(spawned.active.sprites.map(\.type), [1402, 1403, 1400, 1400, 1400, 1401, 1401, 1335, 1485, 1485])
        XCTAssertEqual(spawned.active.sprites.map(\.recordIndex), [14, 21, 25, 40, 47, 57, 58, 2, 16, 44])
        // Queued idle (`.AddIdleSprite`: first free entry), in creation order: the 22 torches take entries 0..21.
        let idle = spawned.idle.entries.compactMap { $0 }
        XCTAssertEqual(idle.count, 152)
        XCTAssertEqual(idle.prefix(22).map(\.saved.type), Array(repeating: 1307, count: 22))
        XCTAssertEqual(idle.map(\.saved.recordIndex), order.filter { p in
            SpriteClassTable.classify(type: p.type, p1Negative: p.p1 < 0)?.1 == .idle
        }.map { Int16($0.index) })
        XCTAssertTrue(idle.allSatisfy { $0.activeID == nil })
        // An idle sprite's Setup ran with layer argument 1 (`.AddIdleSprite` → `MTNewSprite(…, 1, …)`), then its
        // own layer: the torch keeps the Bonus default 1, a plant −100.
        XCTAssertEqual(idle[0].saved.layer, 1)
    }

    // MARK: - IdleSprites

    func testIdleActivationRule() throws {
        typealias R = IdleSprites.Rect
        // Window at view (h, v) = (100, 50), no player: (h − 24, v − 24, h + 632, v + 408) outset by 96 →
        // left −20, top −70, right 828, bottom 554.
        let w = IdleSprites.window(h: 100, v: 50, playerHotRect: nil)
        XCTAssertEqual(w, R(top: -70, left: -20, bottom: 554, right: 828))
        // The player's hot rect is united in before the outset.
        XCTAssertEqual(IdleSprites.window(h: 100, v: 50, playerHotRect: R(top: 600, left: 900, bottom: 650, right: 950)),
                       R(top: -70, left: -20, bottom: 746, right: 1046))

        var list = ActiveList()
        var idle = IdleSprites()
        let face = R(top: 4, left: 2, bottom: 30, right: 20)
        let ref = FaceRef(pict: 1, index: 0, set: .encoded)   // a face, so going idle re-reads this rect
        // A: its box starts 10 px past the right edge; a left margin of 10 does not reach (rects are half-open),
        // 11 does. B: same place, margin 11. C: type 0 never activates. D: `+0x1c6 = 0` never goes idle.
        var a = SpriteSlot(type: 10, x: 828 - 2 + 10, y: 100, layer: 3, face: ref)
        a.margins = .init(left: 10)
        var b = a; b.type = 11; b.margins = .init(left: 11)
        var c = a; c.type = 0; c.margins = .init(left: 500)
        var d = SpriteSlot(type: 12, x: 300, y: 100, layer: 3, face: ref); d.mayIdle = false
        let ia = idle.add(a, faceRect: face), ib = idle.add(b, faceRect: face), ic = idle.add(c, faceRect: face)
        let id = idle.add(d, faceRect: face)
        XCTAssertEqual([ia, ib, ic, id], [0, 1, 2, 3])
        let first = idle.handle(h: 100, v: 50, playerHotRect: nil, active: &list) { _ in face }
        XCTAssertEqual(first.activated, [1, 3])
        XCTAssertEqual(list.sprites.map(\.type), [11, 12])
        // The other direction, one rule (no hysteresis): move B 1 px further right → idle again; D never.
        let bid = try XCTUnwrap(idle.entries[1]?.activeID)
        list.update(id: bid) { $0.x += 1 }
        let did = try XCTUnwrap(idle.entries[3]?.activeID)
        list.update(id: did) { $0.x += 5000 }
        let second = idle.handle(h: 100, v: 50, playerHotRect: nil, active: &list) { _ in face }
        XCTAssertEqual(second.deactivated, [1])
        XCTAssertEqual(list.sprites.map(\.type), [12])
        XCTAssertNil(try XCTUnwrap(idle.entries[1]).activeID)
        XCTAssertEqual(try XCTUnwrap(idle.entries[1]).saved.x, 828 - 2 + 11)   // `.ActiveToIdleSprite` saves the live position
        // The same rule vertically: the box's top on the window's bottom edge (half-open: no overlap), a top margin of
        // 1 → active.
        var e = SpriteSlot(type: 13, x: 300, y: 554 - 4, layer: 0, face: ref); e.margins = .init(top: 1)
        _ = idle.add(e, faceRect: face)
        XCTAssertEqual(idle.handle(h: 100, v: 50, playerHotRect: nil, active: &list) { _ in face }.activated, [4])
        // Right and bottom margins: boxes whose right / bottom edge sits on the window's left (−20) / top (−70) edge;
        // a margin of 1 reaches in, the twins without one stay idle.
        let leftOf = SpriteSlot(type: 14, x: -20 - 20, y: 100, layer: 0, face: ref)
        let above = SpriteSlot(type: 15, x: 300, y: -70 - 30, layer: 0, face: ref)
        var leftM = leftOf; leftM.margins = .init(right: 1)
        var aboveM = above; aboveM.margins = .init(bottom: 1)
        for sprite in [leftOf, leftM, above, aboveM] { _ = idle.add(sprite, faceRect: face) }
        XCTAssertEqual(idle.handle(h: 100, v: 50, playerHotRect: nil, active: &list) { _ in face }.activated, [6, 8])
        // The last entry (511) is never scanned (`100083e8 cmpwi r30,0x1ff`).
        var full = IdleSprites()
        for k in 0..<IdleSprites.capacity {
            XCTAssertEqual(full.add(SpriteSlot(type: 20, x: 0, y: 0), faceRect: face), k)
        }
        XCTAssertNil(full.add(SpriteSlot(type: 20, x: 0, y: 0), faceRect: face))   // table full
        var none = ActiveList()
        XCTAssertEqual(full.handle(h: 0, v: 0, playerHotRect: nil, active: &none) { _ in face }.activated.count, 511)
        XCTAssertNil(try XCTUnwrap(full.entries[511]).activeID)
    }

    func testIdleWindowAtStartLevel1() throws {
        let (r, c) = try context()
        // `.ActiveToIdleSprite`'s face rect at `.AddIdleSprite` time: face +8 (the opaque bounds) when +0xc0 is set,
        // else (0, 0, 0x40, 0x40). On a level's first load the class caches are not loaded yet (`.LoadCachedSpriteFaces`
        // runs after `.SetupLevelSprites`, decompile l. 2526, 2537), so a cached face is the placeholder PICT 150
        // (64×64, `.InitSprites` l. 112–113). Here each face is taken at its full frame — the opaque bounds lie inside
        // it — and the check below shows the frame never reaches past the window, so the bounds cannot change the count.
        func frame(_ e: SetupFaces.Entry) throws -> IdleSprites.Rect {
            switch e.source {
            case .none, .handle: return IdleSprites.Rect(top: 0, left: 0, bottom: 0x40, right: 0x40)
            case .setupCached: return try picFrame(r, SetupFaces.placeholderPict)
            case .setup:
                let s = try XCTUnwrap(e.sheet)
                return s.single ? try picFrame(r, s.pict) : IdleSprites.Rect(top: 0, left: 0, bottom: s.cellHeight,
                                                                             right: s.cellWidth)
            }
        }
        var frames: [Int16: IdleSprites.Rect] = [:], sources: [Int16: SetupFaces.FaceSource] = [:]
        var spawned = try SetupFaces.spawnLevelSprites(context: c) { e in
            let f = (try? frame(e)) ?? IdleSprites.Rect(top: 0, left: 0, bottom: 0, right: 0)
            frames[e.slot.recordIndex] = f
            sources[e.slot.recordIndex] = e.source
            return f
        }
        // The player at its start (header 0x2848 − 32, 0x2846 − 32) = (83, 143), hot rect (+0x34) 34, 38, 85, 62
        // (`.SetupPlayerSprite`'s SetRect(0x26, 0x22, 0x3e, 0x55); sprites-backgrounds §5).
        let player = IdleSprites.Rect(top: 143 + 34, left: 83 + 38, bottom: 143 + 85, right: 83 + 62)
        let window = IdleSprites.window(h: 0, v: 10, playerHotRect: player)
        XCTAssertEqual(window, IdleSprites.Rect(top: -110, left: -120, bottom: 514, right: 728))
        let result = spawned.idle.handle(h: 0, v: 10, playerHotRect: player, active: &spawned.active) { _ in
            IdleSprites.Rect(top: 0, left: 0, bottom: 0x40, right: 0x40)
        }
        let records = try result.activated.map { try XCTUnwrap(spawned.idle.entries[$0]).saved.recordIndex }
        // Self-derived from the transcribed rule (margins all 0 on level 1): the 13 records of the margin-free point
        // test with the 96-px outset (plan Research note 16).
        XCTAssertEqual(records.sorted(), [1, 3, 4, 6, 22, 52, 68, 78, 131, 157, 158, 159, 160])
        XCTAssertEqual(result.activated.count, 13)
        XCTAssertEqual(result.deactivated, [])
        // The faced ones (2902 ×2, 3204, the placeholder-faced 2842 ×3): the whole frame inside the window's right and
        // bottom edges, so any non-empty opaque bounds inside it intersect too. The faceless ones use the exact rect.
        for rec in records where sources[rec] == .setup || sources[rec] == .setupCached {
            let p = c.level.placements[Int(rec)], f = try XCTUnwrap(frames[rec])
            XCTAssertLessThanOrEqual(Int(p.x) + f.right, window.right, "record \(rec)")
            XCTAssertLessThanOrEqual(Int(p.y) + f.bottom, window.bottom, "record \(rec)")
        }
        XCTAssertEqual(spawned.active.sprites.count, 10 + 13)
    }

    /// A PICT's picFrame (bytes 2…9 of the resource: top, left, bottom, right) at the origin.
    private func picFrame(_ r: FerazelResources, _ id: Int16) throws -> IdleSprites.Rect {
        let res = try XCTUnwrap(r.resource(type: "PICT", id: id, chain: .frontEnd), "PICT \(id)")
        let b = [UInt8](res.data)
        func i16(_ o: Int) -> Int { Int(Int16(bitPattern: UInt16(b[o]) << 8 | UInt16(b[o + 1]))) }
        let top = i16(2), left = i16(4)
        return IdleSprites.Rect(top: 0, left: 0, bottom: i16(6) - top, right: i16(8) - left)
    }
}
