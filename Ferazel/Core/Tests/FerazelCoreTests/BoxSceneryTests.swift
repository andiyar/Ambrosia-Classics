import XCTest
@testable import FerazelCore

/// 6A-BX1a (docs/superpowers/plans/2026-11-04-ferazel-remainder.md `#### 6A-BX1a`; docs/ferazel/later-levels-ledger.md
/// §8(a), §1 finding 6, §6; docs/ferazel/phase6-engine-contracts.md §5): the Box scenery of levels 10–22 — the
/// decorations 2808, 2816, 2817, 2827, 2831, 2833, 2834, 2836, 2837, 2846, 2847, the rock outcrops 2850, 2852, 2857,
/// 2861 and the mushrooms 2872, 2873, 2875, 2876 (`.SetupBoxSprite` M l. 59641–59713): their faces in the Setup-face
/// table, their picture-cache singles marked, and the level-21 graves' hot rect mirrored by `.FlipHRect(+0x34, face
/// +6)` (M l. 59670–59673) with their contact arm (`.HitPlayerSprite` M l. 49278–49303). Records are read per record
/// through `SetupFaces.setup` (levels 15, 20, 21 and 22 hold other refused records, so no level is opened) or, for the
/// graves, on the level-21 fixture. A missing data file is a FAILURE, never a skip.
final class BoxSceneryTests: XCTestCase {

    private typealias Rect = IdleSprites.Rect

    private func resources() throws -> FerazelResources { try FerazelData.open(try FerazelData.dataDirectory()) }

    /// The 19 types (LL §8(a)), by kind.
    private static let decorations: [Int16] = [2808, 2816, 2817, 2827, 2831, 2833, 2834, 2836, 2837, 2846, 2847]
    private static let outcrops: [Int16] = [2850, 2852, 2857, 2861]
    private static let mushrooms: [Int16] = [2872, 2873, 2875, 2876]
    private static var all: [Int16] { decorations + outcrops + mushrooms }

    /// The later levels the world file holds in 10…22.
    private static let levels: [Int16] = [10, 11, 15, 18, 20, 21, 22]

    // MARK: - the Setups and their faces

    func testBoxSceneryFacesSetUp() throws {
        let r = try resources()
        var byLevel: [Int16: Int] = [:], byType: [Int16: Int] = [:]
        for level in Self.levels {
            let L = try LevelFile.load(from: r, level: level)
            let c = SetupFaces.Context(level: L, playerX: 0)
            for p in L.activePlacements where Self.all.contains(p.type) {
                byLevel[level, default: 0] += 1
                byType[p.type, default: 0] += 1
                let what = "L\(level) record \(p.index) type \(p.type)"
                let e: SetupFaces.Entry
                do { e = try SetupFaces.setup(p, context: c) } catch {
                    XCTFail("\(what): \(error)")
                    continue
                }
                let s = e.slot
                // The face per type: its own cache single (`.InitBoxSprite` M l. 58775–58827), the decorations under
                // flag 0 (clut 200) faced at Setup (`+0xc0 = cache[type − 0xaf5] + 4`, M l. 59648), the outcrops under
                // flag 1 (the level+base CLUT) and the mushrooms under flag 0, both faced by their Handle.
                let outcrop = Self.outcrops.contains(p.type), decoration = Self.decorations.contains(p.type)
                let clut = outcrop ? ColorLUT.screenClutId(L.header) : 200
                XCTAssertEqual(e.sheet, SetupFaces.Sheet.single(p.type, clut: clut), what)
                XCTAssertEqual(e.source, decoration ? .setupCached : .handle, what)
                XCTAssertEqual(e.faceIndex, 0, what)
                XCTAssertEqual(s.face, FaceRef(pict: p.type, index: 0, set: .encoded), what)
                XCTAssertEqual(e.spawn, .idle, what)
                XCTAssertEqual(e.spriteClass, .box, what)
                XCTAssertEqual(e.record, p, "\(what): nothing written back")
                XCTAssertEqual([s.hasHit, s.hasTileHit], [false, false], what)
                XCTAssertEqual(s.gravity, 0, what)
                if decoration {
                    // M l. 59642–59680: layer −1 (10000 with p3 ≠ 0), light overlay, one-way, mirrored with p1 ≠ 0.
                    XCTAssertEqual(s.layer, p.p3 != 0 ? 10000 : -1, what)
                    XCTAssertTrue(s.lightOverlay, what)
                    XCTAssertEqual(s.mirrored, p.p1 != 0, what)
                    XCTAssertEqual(s.oneWay, p.type != 2827, what)
                    switch p.type {
                    case 2827: XCTAssertEqual(s.hotRect, Rect(top: 0xd, left: 0xf, bottom: 0x28, right: 0x32), what)
                    case 2833, 2834, 2836: break                       // the graves: `testGraveHotRectFlip`
                    default:
                        // M l. 59646: the empty rect. With p1 ≠ 0 the dump's `.FlipHRect` (M l. 59670–59673) makes it
                        // (top 0, left w, bottom 0, right w), w = face `+6`; the port keeps (0, 0, 0, 0) — a RECORDED
                        // DEVIATION from the dump (6A-BX1a open carry): still empty, so no `SectRect` meets it, but the
                        // Box centre `+0x10` is x, not x + w. This pins the port's value, not the dump's.
                        XCTAssertEqual(s.hotRect, Rect(top: 0, left: 0, bottom: 0, right: 0),
                                       p.p1 != 0 ? "\(what): port deviation (the dump's is (0, w, 0, w))" : what)
                    }
                } else if outcrop {
                    // M l. 59684–59702: layer 0x96, no light overlay, the fixed rect (0x15, 0x14, 0x47, 0x54).
                    XCTAssertEqual(s.layer, 0x96, what)
                    XCTAssertFalse(s.lightOverlay, what)
                    XCTAssertTrue(s.oneWay, what)                                 // `+0x185 = 1` (M l. 59701)
                    XCTAssertEqual(s.hotRect, Rect(top: 0x14, left: 0x15, bottom: 0x54, right: 0x47), what)
                } else {
                    // M l. 59706–59712: layer 0x78, the empty rect.
                    XCTAssertEqual(s.layer, 0x78, what)
                    XCTAssertTrue(s.oneWay, what)                                 // `+0x185 = 1` (M l. 59710)
                    XCTAssertEqual(s.hotRect, Rect(top: 0, left: 0, bottom: 0, right: 0), what)
                }
            }
        }
        // ENG §7.2's BX1a column: 14 / 26 / 3 / 7 records; none on 18, 20, 22.
        XCTAssertEqual(byLevel, [10: 14, 11: 26, 15: 3, 21: 7])
        XCTAssertEqual(byType, [2808: 2, 2816: 9, 2817: 3, 2827: 1, 2831: 5, 2833: 1, 2834: 1, 2836: 1, 2837: 4,
                                2846: 2, 2847: 2, 2850: 1, 2852: 1, 2857: 2, 2861: 1,
                                2872: 6, 2873: 3, 2875: 2, 2876: 3])
        XCTAssertEqual(byType.values.reduce(0, +), 50)
        // Every face is in the Setup-face table.
        for t in Self.all { XCTAssertNotNil(SetupFaces.sheet(pict: t), "\(t)") }
    }

    // MARK: - the picture cache

    func testBoxSceneryCacheMarks() throws {
        // `.SetupBoxSprite` marks the single of the type's own picture: decorations `type·0x10 + 0x1009b4fd` (M l.
        // 59647), outcrops `_DAT_100a0a0c[type − 0xb22]` (M l. 59699), mushrooms `_DAT_100a0a08[type − 0xb36]` (M l.
        // 59709) — LL §6's singles (list positions, 1-based), the outcrops registered under flag 1 (M l. 58818–58823).
        let positions: [Int16: Int] = [2808: 13, 2816: 21, 2817: 22, 2827: 32, 2831: 36, 2833: 38, 2834: 39, 2836: 41,
                                       2837: 42, 2846: 51, 2847: 52, 2850: 81, 2852: 83, 2857: 88, 2861: 92,
                                       2872: 103, 2873: 104, 2875: 106, 2876: 107]
        XCTAssertEqual(Set(positions.keys), Set(Self.all))
        var scenery = Set<CachedFaces.RecordKey>()
        for t in Self.all {
            let k = CachedFaces.RecordKey.single(positions[t]! - 1)
            scenery.insert(k)
            XCTAssertEqual(CachedFaces.markedRecords(type: t), [k], "\(t)")
            XCTAssertEqual(CachedFaces.markedRecords(type: t, p1: 1), [k], "\(t) p1 1")
            XCTAssertEqual(CachedFaces.record(k).pict, t, "\(t)")
            XCTAssertEqual(CachedFaces.record(k).flag, Self.outcrops.contains(t) ? 1 : 0, "\(t)")
            XCTAssertTrue(CachedFaces.record(k).present, "\(t)")
            XCTAssertEqual(CachedFaces.marks(type: t).singles, [t], "\(t)")
            XCTAssertEqual(CachedFaces.marks(type: t).sets, [], "\(t)")
        }
        // No other type marks a scenery record.
        for t in Int16(0)...0x0d00 where !Self.all.contains(t) {
            XCTAssertTrue(Set(CachedFaces.markedRecords(type: t)).isDisjoint(with: scenery), "\(t)")
        }
        // Level by level, the singles the placed scenery marks (every record sets up, per record): LL §4 item 6.
        let r = try resources()
        let expected: [Int16: Set<Int16>] = [10: [2816, 2817, 2837, 2846, 2847, 2861],
                                             11: [2816, 2817, 2831, 2837, 2857, 2872, 2873, 2875, 2876],
                                             15: [2808, 2852], 21: [2827, 2831, 2833, 2834, 2836, 2850]]
        for level in Self.levels {
            let L = try LevelFile.load(from: r, level: level)
            let c = SetupFaces.Context(level: L, playerX: 0)
            var marked = Set<CachedFaces.RecordKey>()
            for p in L.activePlacements where Self.all.contains(p.type) {
                _ = try SetupFaces.setup(p, context: c)
                marked.formUnion(CachedFaces.markedRecords(type: p.type, p1: p.p1))
            }
            XCTAssertEqual(CachedFaces.Needed(records: marked).singles, expected[level] ?? [], "level \(level)")
            XCTAssertTrue(CachedFaces.Needed(records: marked).sets.isEmpty, "level \(level)")
        }
    }

    // MARK: - the graves (level 21, on the fixture)

    /// Level 21 with the 23 records later tasks build left out, by type (literal; never computed from what the port
    /// refuses): 6A-BX1b's faces and talkers 1061 ×14, 2921 ×2, 2962 ×1 (17) and the pipes 1490–1493 (6).
    private static let level21: [LevelFixture.LeaveOut] = [
        .type(1061), .type(2921), .type(2962),
        .type(1490), .type(1491), .type(1492), .type(1493),
    ]

    /// The three graves: record, type, p1 (World Data, level 21), the dump's rect (`SetRect(left, top, right,
    /// bottom)`, M l. 59658–59668) and the rect mirrored by the face width (`.FlipHRect`, M l. 59672).
    private static let graves: [(record: Int, type: Int16, p1: Int16, rect: Rect, mirrored: Rect)] = [
        (207, 2833, 260, Rect(top: 4, left: 5, bottom: 0x46, right: 0x3b), Rect(top: 4, left: 5, bottom: 0x46, right: 59)),
        (89, 2834, 261, Rect(top: 6, left: 2, bottom: 0x23, right: 0x1c), Rect(top: 6, left: 12, bottom: 0x23, right: 38)),
        (90, 2836, 1, Rect(top: 0xe, left: 0, bottom: 0x24, right: 0x1f), Rect(top: 0xe, left: 3, bottom: 0x24, right: 34)),
    ]

    /// Ticks `run` (headless) until `.SetupLevel` has built its session.
    private func session(_ run: LevelRun) throws -> FerazelSession {
        var t: UInt32 = 0
        while run.session == nil && t < 4000 {
            _ = try run.tick(now: t, input: FrontInput())
            t &+= 1
        }
        return try XCTUnwrap(run.session, "the level opened within 4000 ticks")
    }

    /// The level-21 fixture's session, the 23 records asserted.
    private func fixture() throws -> FerazelSession {
        let real = try LevelFile.load(from: try resources(), level: 21)
        let out = try LevelFixture.leftOut(real, Self.level21)
        XCTAssertEqual(out.count, 23)
        var byType: [Int16: Int] = [:]
        for i in out { byType[real.placements[i].type, default: 0] += 1 }
        XCTAssertEqual(byType, [1061: 14, 2921: 2, 2962: 1, 1490: 1, 1491: 3, 1492: 1, 1493: 1])
        let run = try LevelFixture.open(level: 21, leaveOut: Self.level21)
        do { return try session(run) } catch let e as SetupFaces.Error {
            XCTFail("level 21 refused a record the list does not leave out: " + LevelFixture.describe(e, level: real))
            throw e
        }
    }

    /// The live sprite of `record`: it is spawned idle (`.GenerateSprite`, 0xaf5…0xb35), so a `.HandleIdleSprites`
    /// pass around it brings it in (`.IdleToActiveSprite`: the saved Setup record as it was). A pass around another
    /// grave sends this one idle again (its old copy stays on the list with no Handle until `.UpdateSprites`).
    private func live(_ s: FerazelSession, record: Int) throws -> Int {
        let w = s.world
        func found() -> Int? {
            w.active.sprites.first { Int($0.recordIndex) == record && !$0.handleCleared }?.id
        }
        if let id = found() { return id }
        let e = try XCTUnwrap(w.idle.entries.compactMap { $0 }.first { Int($0.saved.recordIndex) == record },
                              "record \(record) idle")
        w.idle.handle(h: e.saved.x - 0x100, v: e.saved.y - 0x100, playerHotRect: nil, active: &w.active,
                      faceRect: { _ in .noFace })
        return try XCTUnwrap(found(), "record \(record) live")
    }

    /// Puts the player so that his hot rect's left edge (or right edge) is at the grave's x + `edge`, his top at the
    /// grave's rect top (`.MTCollideSpecialSprite` meets the `+0x34` rects plus positions).
    private func place(_ w: SpriteWorld, grave g: SpriteSlot, edge: Int, leftEdge: Bool) throws {
        let pid = try XCTUnwrap(w.playerID)
        let hot = try XCTUnwrap(w.active.record(id: pid)).hotRect
        w.active.update(id: pid) { p in
            p.x = g.x + edge - (leftEdge ? hot.left : hot.right)
            p.y = g.y + g.hotRect.top - hot.top
            p.x256 = Int32(p.x) << 8
            p.y256 = Int32(p.y) << 8
        }
    }

    /// The sprites the special pass meets the player with (no arm run).
    private func contacts(_ w: SpriteWorld) -> [Int] {
        var met: [Int] = []
        w.collideSpecial(hitPlayer: { _, _, o in met.append(o) }, hit: { _, _, _ in })
        return met
    }

    func testGraveHotRectFlip() throws {
        // The face width (`face +6`): the PICT frame's width, as the session reads it (`FerazelSession.frameRect`) —
        // Core's table of the six decorations with a non-empty rect (M l. 59650–59668) holds the same values.
        let r = try resources()
        let widths: [Int16: Int] = [0xb0b: 74, 0xb10: 54, 0xb11: 64, 0xb12: 40, 0xb13: 36, 0xb14: 34]
        for (t, wd) in widths {
            let f = FerazelSession.frameRect(FaceRef(pict: t, index: 0, set: .encoded), resources: r)
            XCTAssertEqual(f.right - f.left, wd, "\(t)")
            XCTAssertEqual(BoxSprite.decorationFaceWidths[t], wd, "\(t)")
        }
        XCTAssertEqual(BoxSprite.decorationFaceWidths.count, 6)
        // The mirror is `PlatformSprite.flipH` (the one port, 6A-TR), applied with p1 ≠ 0.
        for g in Self.graves {
            XCTAssertEqual(PlatformSprite.flipH(g.rect, widths[g.type]!), g.mirrored, "\(g.type)")
        }
        let s = try fixture()
        let w = s.world
        // The table's keys are exactly the decorations whose Setup gives a non-empty rect (M l. 59650–59668): a type
        // with a rect but no width would silently stay unmirrored.
        let empty = Rect(top: 0, left: 0, bottom: 0, right: 0)
        var withRect: Set<Int16> = []
        for t: Int16 in 0xaf5...0xb21 {
            let q = w.records[Self.graves[0].record]
            var d = SpriteSlot(type: t, x: 100, y: 100)
            BoxSprite.setup(&d, record: Placement(index: q.index, flag: q.flag, byte1: q.byte1, type: t, p1: 0, p2: 0,
                                                  p3: 0, p4: 0, y: 100, x: 100), level: w.level)
            if d.hotRect != empty { withRect.insert(t) }
        }
        XCTAssertEqual(withRect, Set(BoxSprite.decorationFaceWidths.keys))
        for g in Self.graves {
            let p = w.records[g.record]
            XCTAssertEqual([p.type, p.p1, p.p4], [g.type, g.p1, 0], "record \(g.record)")
            // Per record: the Setup's rect mirrored (2833's is symmetric in its 64-px face: 5…59 either way).
            let e = try SetupFaces.setup(p, context: SetupFaces.Context(level: w.level, playerX: 0))
            XCTAssertTrue(e.slot.mirrored, "\(g.type)")
            XCTAssertEqual(e.slot.hotRect, g.mirrored, "\(g.type)")
            // The same record unmirrored (p1 0) keeps the dump's rect.
            let p0 = Placement(index: p.index, flag: p.flag, byte1: p.byte1, type: p.type, p1: 0, p2: p.p2, p3: p.p3,
                               p4: p.p4, y: p.y, x: p.x)
            let e0 = try SetupFaces.setup(p0, context: SetupFaces.Context(level: w.level, playerX: 0))
            XCTAssertFalse(e0.slot.mirrored, "\(g.type)")
            XCTAssertEqual(e0.slot.hotRect, g.rect, "\(g.type) p1 0")
            // A negative p1 mirrors too: the dump tests p1 ≠ 0 (M l. 59670), not p1 > 0 (no such record is placed).
            let pn = Placement(index: p.index, flag: p.flag, byte1: p.byte1, type: p.type, p1: -1, p2: p.p2, p3: p.p3,
                               p4: p.p4, y: p.y, x: p.x)
            let en = try SetupFaces.setup(pn, context: SetupFaces.Context(level: w.level, playerX: 0))
            XCTAssertTrue(en.slot.mirrored, "\(g.type) p1 −1")
            XCTAssertEqual(en.slot.hotRect, g.mirrored, "\(g.type) p1 −1")
            // On the fixture: the spawned grave carries the mirrored rect.
            let id = try live(s, record: g.record)
            let grave = try XCTUnwrap(w.active.record(id: id))
            XCTAssertEqual(grave.type, g.type)
            XCTAssertTrue(grave.mirrored, "\(g.type)")
            XCTAssertEqual(grave.hotRect, g.mirrored, "\(g.type) on the fixture")
        }
        // Contact on the mirrored side: the player's left edge just inside the mirrored rect's right part, where the
        // unmirrored rect ends (2834: 28, 2836: 31) meets the grave; his right edge at the mirrored rect's left (12, 3),
        // inside the unmirrored rect, does not. 2833 is met on both sides alike.
        for (record, inside, outside) in [(89, 28, 12), (90, 31, 3)] {
            let id = try live(s, record: record)
            let grave = try XCTUnwrap(w.active.record(id: id))
            try place(w, grave: grave, edge: inside, leftEdge: true)
            XCTAssertTrue(contacts(w).contains(id), "record \(record): the mirrored side")
            try place(w, grave: grave, edge: outside, leftEdge: false)
            XCTAssertFalse(contacts(w).contains(id), "record \(record): the unmirrored side")
            try place(w, grave: grave, edge: outside + 1, leftEdge: false)
            XCTAssertTrue(contacts(w).contains(id), "record \(record): one pixel in")
        }
        let id = try live(s, record: 207)
        let grave = try XCTUnwrap(w.active.record(id: id))
        try place(w, grave: grave, edge: 58, leftEdge: true)
        XCTAssertTrue(contacts(w).contains(id))
        try place(w, grave: grave, edge: 6, leftEdge: false)
        XCTAssertTrue(contacts(w).contains(id))
        try place(w, grave: grave, edge: 5, leftEdge: false)
        XCTAssertFalse(contacts(w).contains(id))
    }

    func testGraveTalkersOpenConversations() throws {
        let r = try resources()
        for g in Self.graves {
            let s = try fixture()
            let w = s.world
            let id = try live(s, record: g.record)
            let grave = try XCTUnwrap(w.active.record(id: id))
            XCTAssertEqual(w.player.countdown06cc, 0)
            // Met on the mirrored side (`.MTCollideSpecialSprite` → `.HitPlayerSprite`'s sign / grave arm).
            try place(w, grave: grave, edge: g.mirrored.right - 1, leftEdge: true)
            let pid = try XCTUnwrap(w.playerID)
            var others: [Int] = []
            w.collideSpecial(hitPlayer: { w, p, o in
                if o == id { HitPlayerSprite.hit(w, player: p, other: o) } else { others.append(o) }
            }, hit: { _, _, _ in })
            XCTAssertNil(others.first { $0 == pid })
            // p4 ← 1 and the cooldown 0x5a (M l. 49286–49287) on every grave; p1 > 100 → `.Conversation(p1, +0x48,
            // the sprite)` (M l. 49297–49300); 2836's p1 1 opens none.
            XCTAssertEqual(w.player.countdown06cc, 0x5a, "\(g.type)")
            XCTAssertEqual(w.records[g.record].p4, 1, "\(g.type)")
            XCTAssertEqual([w.records[g.record].p1, w.records[g.record].p2, w.records[g.record].p3], [g.p1, 0, 0])
            if g.p1 > 100 {
                XCTAssertEqual(w.suspension, .conversation(id: g.p1, record: g.record, sprite: id), "\(g.type)")
                XCTAssertNoThrow(try Conversation.load(from: r, id: g.p1), "Mcnv \(g.p1)")
            } else {
                XCTAssertNil(w.suspension, "\(g.type)")
            }
            // A second contact in the cooldown does nothing more; nor with the cooldown run out and p4 1 (no UP).
            w.suspension = nil
            HitPlayerSprite.hit(w, player: pid, other: id)
            XCTAssertNil(w.suspension, "\(g.type): cooldown")
            XCTAssertEqual(w.player.countdown06cc, 0x5a)
            w.player.countdown06cc = 0
            HitPlayerSprite.hit(w, player: pid, other: id)
            XCTAssertNil(w.suspension, "\(g.type): p4 1, no UP")
            XCTAssertEqual(w.player.countdown06cc, 0, "\(g.type): p4 1, no UP")
            // The arm's own gates on this grave's live record, one at a time (M l. 49284–49300): p4 back to 0 so only
            // the gate under test can refuse.
            func setRecord(p1: Int16, p4: Int16) {
                let q = w.records[g.record]
                w.records[g.record] = Placement(index: q.index, flag: q.flag, byte1: q.byte1, type: q.type, p1: p1,
                                                p2: q.p2, p3: q.p3, p4: p4, y: q.y, x: q.x)
            }
            //   the cooldown alone: p4 0, cooldown running → nothing (no cooldown reset, p4 kept 0);
            setRecord(p1: g.p1, p4: 0)
            w.player.countdown06cc = 0x5a
            HitPlayerSprite.hit(w, player: pid, other: id)
            XCTAssertNil(w.suspension, "\(g.type): cooldown alone")
            XCTAssertEqual(w.records[g.record].p4, 0, "\(g.type): cooldown alone")
            //   p1 0 → nothing at all (no cooldown, p4 kept 0);
            setRecord(p1: 0, p4: 0)
            w.player.countdown06cc = 0
            HitPlayerSprite.hit(w, player: pid, other: id)
            XCTAssertEqual([w.player.countdown06cc, w.records[g.record].p4], [0, 0], "\(g.type): p1 0")
            XCTAssertNil(w.suspension, "\(g.type): p1 0")
            //   p1 100 → the cooldown and p4 but no conversation; p1 101 → `.Conversation(101, …)` (`cmpwi r3,0x64`).
            for (p1, talks) in [(Int16(100), false), (101, true)] {
                setRecord(p1: p1, p4: 0)
                w.player.countdown06cc = 0
                w.suspension = nil
                HitPlayerSprite.hit(w, player: pid, other: id)
                XCTAssertEqual([w.player.countdown06cc, w.records[g.record].p4], [0x5a, 1], "\(g.type): p1 \(p1)")
                XCTAssertEqual(w.suspension, talks ? .conversation(id: p1, record: g.record, sprite: id) : nil,
                               "\(g.type): p1 \(p1)")
            }
        }
    }

    // MARK: - ENG §5's unplaced Box pins

    /// Every placement (any flag) of every level of the world file.
    private func everyPlacement() throws -> [(level: Int16, p: Placement)] {
        let levels = try resources().world.resources(of: "Mlvl")
        XCTAssertEqual(levels.count, 24)
        var out: [(Int16, Placement)] = []
        for res in levels { for p in try LevelFile(resource: res).placements { out.append((res.id, p)) } }
        return out
    }

    func testRopeBridgeUnplaced() throws {
        // The rope bridge 1466 (0x5ba) and its face part 0x5bb: on no level of the 24, active or not; `.GenerateSprite`
        // (M l. 1890) adds the idle 0x5bb only for a placed 0x5ba, and nothing else spawns either. Kept refused at
        // Setup (no SetupFaces arm; `.GetRopeBridgeHeight` M l. 58875–58891 unbuilt).
        for (level, p) in try everyPlacement() {
            XCTAssertFalse(p.type == 0x5ba || p.type == 0x5bb, "level \(level) record \(p.index)")
        }
        XCTAssertEqual(SpriteClassTable.classify(type: 0x5ba, p1Negative: false)?.0, .box)
        let L = try LevelFile.load(from: try resources(), level: 21)
        let c = SetupFaces.Context(level: L, playerX: 0)
        let p = Placement(index: 7, flag: 1, byte1: 0, type: 0x5ba, p1: 0, p2: 0, p3: 0, p4: 0, y: 900, x: 3000)
        XCTAssertThrowsError(try SetupFaces.setup(p, context: c)) {
            XCTAssertEqual($0 as? SetupFaces.Error, .notTranscribed(type: 0x5ba))
        }
    }

    func testTableUnplaced() throws {
        // The table 0xb71 (2929; Box Setup M l. 59403, Handle M l. 60794): on no level of the 24 and no spawner —
        // kept refused at Setup (the furniture arm stops at 0xb70) and unrun at the Handle.
        for (level, p) in try everyPlacement() {
            XCTAssertNotEqual(p.type, 0xb71, "level \(level) record \(p.index)")
        }
        XCTAssertEqual(SpriteClassTable.classify(type: 0xb71, p1Negative: false)?.0, .box)
        let L = try LevelFile.load(from: try resources(), level: 21)
        let c = SetupFaces.Context(level: L, playerX: 0)
        let p = Placement(index: 7, flag: 1, byte1: 0, type: 0xb71, p1: 0, p2: 0, p3: 0, p4: 0, y: 900, x: 3000)
        XCTAssertThrowsError(try SetupFaces.setup(p, context: c)) {
            XCTAssertEqual($0 as? SetupFaces.Error, .notTranscribed(type: 0xb71))
        }
        XCTAssertFalse(BoxSprite.handleBuilt(0xb71))
    }
}
