import XCTest
@testable import FerazelCore

/// 6A-TR (docs/superpowers/plans/2026-11-04-ferazel-remainder.md `#### 6A-TR`; docs/ferazel/phase6-engine-contracts.md
/// §2.4 and §5): the trees 0xc08…0xc0f (3080–3087) — the Setup arm of `.SetupBackgroundSprite` (M l. 62597–62617),
/// the Handle arm (M l. 63538–63546), `.SetupTree` (M l. 62679–62886) planting the invisible branches, and the branch
/// arms of `.HandleBoxSprite` for Box 0xc08 / 0xc09 (M l. 60941–60947, 61067–61075). Trees are read per record from
/// levels 10, 11 and 15 through `SetupFaces.setup` (no level opened), or made synthetically on level 10's world. The
/// face widths come from the PICT frames (`FerazelSession.frameRect`, the session's `faceWidth`). A missing data file is
/// a FAILURE, never a skip.
final class TreeTests: XCTestCase {

    private typealias Rect = IdleSprites.Rect

    private func resources() throws -> FerazelResources { try FerazelData.open(try FerazelData.dataDirectory()) }

    /// Level 10's world, nothing in it.
    private func world() throws -> SpriteWorld {
        SpriteWorld(level: try LevelFile.load(from: try resources(), level: 10))
    }

    /// The session's face width (face `+6`): the PICT frame's width.
    private func widths() throws -> (FaceRef) -> Int {
        let r = try resources()
        return { FerazelSession.frameRect($0, resources: r).right }
    }

    private func rec(_ type: Int16, p1: Int16 = 0, index: Int = 7, x: Int16 = 3000, y: Int16 = 900) -> Placement {
        Placement(index: index, flag: 1, byte1: 0, type: type, p1: p1, p2: 0, p3: 0, p4: 0, y: y, x: x)
    }

    /// The tree of record `p` set up (`SetupFaces.setup`), its record put into the live table (where the Handle reads
    /// p1 every frame) and inserted.
    private func tree(_ w: SpriteWorld, _ p: Placement) throws -> Int {
        let e = try SetupFaces.setup(p, context: SetupFaces.Context(level: w.level, playerX: 0))
        w.records[p.index] = e.record
        return w.active.insert(e.slot)
    }

    /// ENG §2.4's table (`SetRect`'s left, top, right, bottom as the dump passes them, M l. 62683–62886) and the slot
    /// each spawn's pointer goes to (0 `+0x1d4`, 1 `+0x1d8`, 2 `+0x1dc`, 3 `+0x1e0`) — written out here, not read from
    /// the port.
    private static let table: [Int16: [(l: Int, t: Int, r: Int, b: Int, slot: Int)]] = [
        0xc08: [(0x62, 0xc, 0xb4, 0x24, 0), (0x10, 0x31, 0x66, 0x4a, 1), (0x94, 0x4b, 0xd6, 0x5f, 2)],
        0xc09: [(0x27, 0xb, 0x6e, 0x15, 0), (0x6c, 0x1f, 0xaf, 0x2c, 1), (8, 0x3b, 0x5c, 0x50, 2),
                (0x8e, 0x46, 0xd7, 0x59, 3)],
        0xc0a: [(0x42, 0x10, 0x8c, 0x23, 0), (0x96, 0xe, 0xd0, 0x23, 1), (0x14, 0x34, 0x5c, 0x49, 2),
                (0xc0, 0x30, 0xfd, 0x44, 3)],
        0xc0b: [(0x43, 0xd, 0x96, 0x1d, 0), (0x34, 0x48, 0x6d, 0x5f, 1), (0x81, 0x3e, 0xbc, 0x4c, 2),
                (10, 0x6f, 0x44, 0x84, 3), (0x61, 0x7d, 0xa5, 0x98, 0)],
        0xc0f: [(0xb, 0x1b, 0x182, 0x46, 0)],
    ]

    /// The tree's four pointer slots `+0x1d4…+0x1e0`.
    private func slots(_ s: SpriteSlot) -> [Int?] {
        [s.siblings.first, s.siblings.second, s.siblings.third, s.siblings.fourth]
    }

    /// The sprites made since `before` (ids only grow), in creation order.
    private func made(_ w: SpriteWorld, since before: Set<Int>) -> [SpriteSlot] {
        w.active.sprites.filter { !before.contains($0.id) }.sorted { $0.id < $1.id }
    }

    // MARK: - the Setup arm (M l. 62597–62617)

    func testTreeSetupFields() throws {
        let r = try resources()
        // Every placed tree, per record: levels 10, 11 and 15 (ENG §2.4's census: 13, 8 and 10 records).
        var seen: [Int: Int] = [:]
        for level: Int16 in [10, 11, 15] {
            let L = try LevelFile.load(from: r, level: level)
            let c = SetupFaces.Context(level: L, playerX: 0)
            for p in L.activePlacements where BackgroundSprite.trees.contains(p.type) {
                seen[Int(level), default: 0] += 1
                let e = try SetupFaces.setup(p, context: c)
                let s = e.slot
                let what = "L\(level) record \(p.index)"
                // The common head (`setupCommon`, M l. 61966–61977), then the arm: margins `+0x1ca = +0x1c8 = +0x1cc =
                // 0x80`, `+0x1ce = 0xa0`; `+0x17c = 0`; layer 30000; `+0x17e = (byte) p1`; `+0x88 = 0`; `+0x5c = +0x1f8 =
                // 0`; empty rect.
                XCTAssertEqual(s.handler, .background, what)
                XCTAssertEqual(s.margins, SpriteSlot.Margins(left: 0x80, right: 0x80, top: 0x80, bottom: 0xa0), what)
                XCTAssertFalse(s.setupDone, what)
                XCTAssertEqual(s.layer, 30000, what)
                XCTAssertEqual(s.mirrored, p.p1 != 0, what)
                XCTAssertFalse(s.lightOverlay, what)
                XCTAssertEqual([s.hasHit, s.hasTileHit], [false, false], what)
                XCTAssertEqual(s.hotRect, Rect(top: 0, left: 0, bottom: 0, right: 0), what)
                XCTAssertEqual([Int(s.counterA6), Int(s.hp)], [3, 6], what)
                // `LAB_10072efc`: the 24.8 position from the spawn copy.
                XCTAssertEqual([s.x256, s.y256], [Int32(p.x) << 8, Int32(p.y) << 8], what)
                // Spawned idle (`.GenerateSprite`, 0xc08…0xc11); `+0xc0` left 0 — the Handle faces it from the cache
                // (the entry names that face, `.handle`), converted under the level+base CLUT (flag 1).
                XCTAssertEqual(e.spawn, .idle, what)
                XCTAssertEqual(e.source, .handle, what)
                XCTAssertEqual(e.faceIndex, 0, what)
                XCTAssertEqual(e.sheet, SetupFaces.Sheet.single(p.type, clut: ColorLUT.screenClutId(L.header)), what)
                XCTAssertEqual(e.record, p, "\(what): nothing written back")
                XCTAssertTrue(e.children.isEmpty, "\(what): the Setup plants nothing")
            }
        }
        XCTAssertEqual(seen, [10: 13, 11: 8, 15: 10])
        // 0xc0f (placed nowhere): layer −10 (M l. 62613–62615). The mirror is the low byte of p1 (`(char)` of the
        // short, M l. 62606): 0x100 is not mirrored, 0x101 and −255 (0xff01) are.
        let w = try world()
        let c = SetupFaces.Context(level: w.level, playerX: 0)
        XCTAssertEqual(try SetupFaces.setup(rec(0xc0f), context: c).slot.layer, -10)
        for t in Int16(0xc08)...0xc0e { XCTAssertEqual(try SetupFaces.setup(rec(t), context: c).slot.layer, 30000) }
        for (p1, m): (Int16, Bool) in [(0, false), (1, true), (0x100, false), (0x101, true), (-255, true), (-256, false)] {
            XCTAssertEqual(try SetupFaces.setup(rec(0xc09, p1: p1), context: c).slot.mirrored, m, "p1 \(p1)")
        }
    }

    // MARK: - the Handle and `.SetupTree`

    func testTreePlantsBranchesOnFirstHandle() throws {
        let w = try world()
        let width = try widths()
        // The counts by tree: 3 / 4 / 4 / 5 for 0xc08…0xc0b, none for 0xc0c…0xc0e (no arm), one for 0xc0f.
        let counts: [Int16: Int] = [0xc08: 3, 0xc09: 4, 0xc0a: 4, 0xc0b: 5, 0xc0c: 0, 0xc0d: 0, 0xc0e: 0, 0xc0f: 1]
        for (k, t) in (Int16(0xc08)...0xc0f).enumerated() {
            // Two positions per tree: each rect is offset by the tree's `+0xc` / `+0xa` (M l. 62703).
            for (x, y): (Int16, Int16) in [(3000, 900), (1201, -40)] {
                let p = rec(t, index: 10 + k, x: x, y: y)
                let id = try tree(w, p)
                let before = Set(w.active.sprites.map(\.id))
                BackgroundSprite.handle(world: w, id: id, faceWidth: width)
                let s = try XCTUnwrap(w.active.sprite(id: id))
                let kids = made(w, since: before)
                XCTAssertEqual(kids.count, counts[t], "tree \(t)")
                guard kids.count == (Self.table[t] ?? []).count else { continue }   // a failure, never a crash
                XCTAssertTrue(s.setupDone, "`+0x17c = 1` (M l. 62694)")
                // The face from the cache (M l. 62695–62696, 63541–63542) and the mirror from the record (M l. 63544).
                XCTAssertEqual(s.face, FaceRef(pict: t, index: 0, set: .encoded))
                XCTAssertFalse(s.mirrored)
                // Every rect constant: the child's spawn at (left, top) + the tree's position, its hot rect the rect back
                // at the origin (`+0x34/+0x38`, after each spawn), record −1, never counted.
                for (i, b) in (Self.table[t] ?? []).enumerated() {
                    let kid = kids[i]
                    let what = "tree \(t) at (\(x), \(y)) branch \(i)"
                    XCTAssertEqual(kid.type, t == 0xc0f ? 0xc09 : 0xc08, what)
                    XCTAssertEqual([kid.x, kid.y], [Int(x) + b.l, Int(y) + b.t], what)
                    XCTAssertEqual([kid.oldPosition.x, kid.oldPosition.y], [Int(x) + b.l, Int(y) + b.t], what)
                    XCTAssertEqual(kid.hotRect, Rect(top: 0, left: 0, bottom: b.b - b.t, right: b.r - b.l), what)
                    XCTAssertEqual(kid.recordIndex, -1, what)
                    XCTAssertFalse(kid.countedInTotals, what)
                }
                // Each slot holds the last spawn written to it (0xc0b's fifth overwrites `+0x1d4`).
                var want: [Int?] = [nil, nil, nil, nil]
                for (i, b) in (Self.table[t] ?? []).enumerated() { want[b.slot] = kids[i].id }
                XCTAssertEqual(slots(s), want, "tree \(t)")
                // The next Handle plants nothing (`+0x17c` set), and re-reads the face and the mirror every frame: a
                // record p1 changed since, a face cleared since, are set again (M l. 63541–63545).
                w.records[p.index] = rec(t, p1: 1, index: p.index, x: x, y: y)
                w.active.update(id: id) { $0.face = nil }
                let count = w.active.sprites.count
                BackgroundSprite.handle(world: w, id: id, faceWidth: width)
                XCTAssertEqual(w.active.sprites.count, count, "tree \(t): planted once")
                let again = try XCTUnwrap(w.active.sprite(id: id))
                XCTAssertEqual(again.face, FaceRef(pict: t, index: 0, set: .encoded))
                XCTAssertTrue(again.mirrored)
                XCTAssertEqual(slots(again), want)
            }
        }
        // `.SetupTree` stores the face itself before planting (M l. 62695–62696): a mirrored tree whose slot holds another
        // face (here the cannon set's) flips by the tree face's width, not that one's.
        let p = rec(0xc08, p1: 1, index: 40)
        let id = try tree(w, p)
        w.active.update(id: id) { $0.face = FaceRef(pict: 0x442, index: 0, set: .encoded) }
        let before = Set(w.active.sprites.map(\.id))
        BackgroundSprite.handle(world: w, id: id, faceWidth: width)
        XCTAssertEqual(made(w, since: before).first?.x, 3000 + 226 - 0xb4, "flipped by 0xc08's 226, not 0x442's 150")
    }

    func testTreeFifthBranchOverwritesFirstSlot() throws {
        let w = try world()
        let id = try tree(w, rec(0xc0b, x: 500, y: 700))
        let before = Set(w.active.sprites.map(\.id))
        BackgroundSprite.handle(world: w, id: id, faceWidth: try widths())
        let kids = made(w, since: before)
        XCTAssertEqual(kids.count, 5)
        guard kids.count == 5 else { return }
        let s = try XCTUnwrap(w.active.sprite(id: id))
        // `+0x1d4` = the fifth spawn (M l. 62765–62770): the first spawn's pointer is lost, the sprite itself lives on.
        XCTAssertEqual(slots(s), [kids[4].id, kids[1].id, kids[2].id, kids[3].id])
        XCTAssertNotNil(w.active.sprite(id: kids[0].id), "the first branch stays, unreferenced")
        XCTAssertFalse(slots(s).contains(kids[0].id))
        XCTAssertEqual([kids[0].x, kids[0].y, kids[4].x, kids[4].y], [500 + 0x43, 700 + 0xd, 500 + 0x61, 700 + 0x7d])
    }

    func testTreeBranchesMirror() throws {
        let width = try widths()
        // The face widths (PICT frames, ENG §2.4): 0xc08 226, 0xc09 227, 0xc0a 264, 0xc0b 198, 0xc0f 414.
        let w0: [Int16: Int] = [0xc08: 226, 0xc09: 227, 0xc0a: 264, 0xc0b: 198, 0xc0f: 414]
        for (t, v) in w0 { XCTAssertEqual(width(FaceRef(pict: t, index: 0, set: .encoded)), v, "PICT \(t)") }
        // `.FlipHRect(r, w)` (M l. 39474–39491): left = w − left, right = w − right (`.FlipHCoord`, M l. 39466–39469),
        // swapped when right < left — always, for a non-empty rect; an empty one (left = right) is left as it is, and a
        // rect wider than w goes negative (16-bit).
        XCTAssertEqual(PlatformSprite.flipH(Rect(top: 1, left: 10, bottom: 2, right: 30), 100),
                       Rect(top: 1, left: 70, bottom: 2, right: 90))
        XCTAssertEqual(PlatformSprite.flipH(Rect(top: 0, left: 40, bottom: 0, right: 40), 100),
                       Rect(top: 0, left: 60, bottom: 0, right: 60))
        XCTAssertEqual(PlatformSprite.flipH(Rect(top: 0, left: 30, bottom: 0, right: 10), 100),
                       Rect(top: 0, left: 70, bottom: 0, right: 90), "right < left before the flip: ordered after it, no swap")
        XCTAssertEqual(PlatformSprite.flipH(Rect(top: 0, left: 0xb, bottom: 0, right: 0x182), 200),
                       Rect(top: 0, left: 200 - 0x182, bottom: 0, right: 200 - 0xb))
        // Each tree with p1 ≠ 0: every branch rect flipped by the tree face's width before the offset; the hot rect (at
        // the origin) keeps its size.
        let w = try world()
        for (k, t) in [Int16(0xc08), 0xc09, 0xc0a, 0xc0b, 0xc0f].enumerated() {
            let fw = w0[t]!
            let id = try tree(w, rec(t, p1: 1, index: 20 + k, x: 2000, y: 600))
            let before = Set(w.active.sprites.map(\.id))
            BackgroundSprite.handle(world: w, id: id, faceWidth: width)
            let kids = made(w, since: before)
            let rows = Self.table[t] ?? []
            XCTAssertEqual(kids.count, rows.count)
            guard kids.count == rows.count else { continue }
            for (i, b) in rows.enumerated() {
                let what = "mirrored tree \(t) branch \(i)"
                XCTAssertEqual([kids[i].x, kids[i].y], [2000 + fw - b.r, 600 + b.t], what)
                XCTAssertEqual(kids[i].hotRect, Rect(top: 0, left: 0, bottom: b.b - b.t, right: b.r - b.l), what)
            }
            XCTAssertTrue(try XCTUnwrap(w.active.sprite(id: id)).mirrored)
        }
        // The shipped mirrored trees that plant (ENG §2.4): level 10's records 0 (0xc0a) and 35 (0xc08), level 11's 31
        // (0xc0b) — their first branch, read per record.
        let r = try resources()
        for (level, index, t): (Int16, Int, Int16) in [(10, 0, 0xc0a), (10, 35, 0xc08), (11, 31, 0xc0b)] {
            let L = try LevelFile.load(from: r, level: level)
            let p = L.placements[index]
            XCTAssertEqual([p.type, p.p1], [t, 1], "L\(level) record \(index)")
            let wl = SpriteWorld(level: L)
            let id = try tree(wl, p)
            let before = Set(wl.active.sprites.map(\.id))
            BackgroundSprite.handle(world: wl, id: id, faceWidth: width)
            let first = try XCTUnwrap(made(wl, since: before).first)
            let b = Self.table[t]![0]
            XCTAssertEqual([first.x, first.y], [Int(p.x) + w0[t]! - b.r, Int(p.y) + b.t], "L\(level) record \(index)")
        }
        do {
            // The Handle's re-read (M l. 63543–63544) is `(char)` of the record's p1, as at Setup: 0x100 is not mirrored,
            // 0x101 and −255 are. A tree with no branches (0xc0c), so the mirror is all that changes.
            let w = try world()
            let p = rec(0xc0c, index: 50)
            let id = try tree(w, p)
            let width = try widths()
            for (p1, m): (Int16, Bool) in [(0x100, false), (0x101, true), (-255, true), (-256, false), (1, true), (0, false)] {
                w.records[p.index] = rec(0xc0c, p1: p1, index: p.index)
                BackgroundSprite.handle(world: w, id: id, faceWidth: width)
                XCTAssertEqual(try XCTUnwrap(w.active.sprite(id: id)).mirrored, m, "p1 \(p1)")
            }
        }
        do {
            // `.SetupTree` runs before the Handle re-reads `+0x17e` (M l. 63538–63546): a record whose p1 changed since the
            // Setup plants with the Setup's mirror (here unflipped), and only then is the tree mirrored from the record.
            let w = try world()
            let p = rec(0xc08, index: 51, x: 3000, y: 900)
            let id = try tree(w, p)
            w.records[p.index] = rec(0xc08, p1: 1, index: p.index, x: 3000, y: 900)
            let before = Set(w.active.sprites.map(\.id))
            BackgroundSprite.handle(world: w, id: id, faceWidth: try widths())
            XCTAssertEqual(made(w, since: before).first?.x, 3000 + 0x62, "planted unflipped (the Setup's mirror)")
            XCTAssertTrue(try XCTUnwrap(w.active.sprite(id: id)).mirrored, "then mirrored from the record")
        }
    }

    // MARK: - the branches (Box 0xc08 / 0xc09)

    func testBranchBoxArm() throws {
        let w = try world()
        // Every frame (M l. 60941–60947 / 61067–61075): `+0x5c = 0`, `+0xc0 = 0`, `+0x1f8 = 0`, gravity 0; one-way 1 for
        // 0xc08, **0** for 0xc09 (0xc0f's long branch is solid).
        for (t, oneWay): (Int16, Bool) in [(BoxSprite.branch, true), (BoxSprite.solidBranch, false)] {
            let id = try XCTUnwrap(BoxSprite.newBranch(w, type: t, x: 800, y: 400))
            w.active.update(id: id) { s in
                s.face = FaceRef(pict: 0x426, index: 0, set: .encoded)
                s.oneWay = !oneWay
            }
            BoxSprite.handle(world: w, id: id)
            let s = try XCTUnwrap(w.active.sprite(id: id))
            XCTAssertEqual([s.hasHit, s.hasTileHit], [false, false], "branch \(t)")
            XCTAssertNil(s.face, "branch \(t)")
            XCTAssertEqual(s.gravity, 0, "branch \(t)")
            XCTAssertEqual(s.oneWay, oneWay, "branch \(t)")
            XCTAssertEqual([s.x, s.y], [800, 400], "branch \(t): never falls")
            // Again: the arm runs every frame.
            w.active.update(id: id) { s in s.oneWay = !oneWay; s.gravity = 0x151 }
            BoxSprite.handle(world: w, id: id)
            let again = try XCTUnwrap(w.active.sprite(id: id))
            XCTAssertEqual([again.oneWay ? 1 : 0, Int(again.gravity)], [oneWay ? 1 : 0, 0], "branch \(t)")
        }
        // 0xc0f spawns its one branch as type 0xc09 and stores the child's `+0x185 = 0` itself (M l. 62879–62885) —
        // the one-way flag is already 0 then (`.SetupBoxSprite`'s head leaves `.InitSprite`'s 0), as the 0xc09 arm keeps
        // it. The hot rect: 0x182 − 0xb = 375 wide, 0x46 − 0x1b = 43 high.
        let id = try tree(w, rec(0xc0f, x: 100, y: 200))
        let before = Set(w.active.sprites.map(\.id))
        BackgroundSprite.handle(world: w, id: id, faceWidth: try widths())
        let kids = made(w, since: before)
        XCTAssertEqual(kids.map(\.type), [BoxSprite.solidBranch])
        guard kids.count == 1 else { return }
        XCTAssertFalse(kids[0].oneWay)
        XCTAssertEqual(kids[0].hotRect, Rect(top: 0, left: 0, bottom: 43, right: 375))
        XCTAssertEqual(try XCTUnwrap(w.active.sprite(id: id)).siblings.first, kids[0].id)
        // 0xc0f (3087) is placed on no level (ENG §5): its tree and its solid branch are reached only here.
        let r = try resources()
        let levels = r.world.resources(of: "Mlvl")
        XCTAssertEqual(levels.count, 24)
        for res in levels {
            let L = try LevelFile(resource: res)
            XCTAssertFalse(L.activePlacements.contains { $0.type == 0xc0f }, "level \(res.id)")
        }
    }

    func testBranchLayerIsTwo() throws {
        let w = try world()
        // A layer-10 sprite (the player's layer) and the tree (30000): the branches made with the layer argument 0xb get
        // layer 2 from `.SetupBoxSprite`'s head (M l. 58939) before the insert (M l. 30719) — in the list ahead of both.
        let player = w.active.insert(SpriteSlot(type: 69, x: 0, y: 0, layer: 10))
        let id = try tree(w, rec(0xc09))
        let before = Set(w.active.sprites.map(\.id))
        BackgroundSprite.handle(world: w, id: id, faceWidth: try widths())
        let kids = made(w, since: before)
        XCTAssertEqual(kids.count, 4)
        XCTAssertEqual(Set(kids.map(\.layer)), [2], "layer 2, not 0xb")
        let order = w.active.sprites.map(\.id)
        let p = try XCTUnwrap(order.firstIndex(of: player)), tr = try XCTUnwrap(order.firstIndex(of: id))
        for k in kids {
            let i = try XCTUnwrap(order.firstIndex(of: k.id))
            XCTAssertLessThan(i, p, "branch before the layer-10 sprite")
            XCTAssertLessThan(i, tr, "branch before its tree")
        }
        // The branch Box arm never changes the layer.
        for k in kids { BoxSprite.handle(world: w, id: k.id) }
        XCTAssertEqual(Set(kids.compactMap { w.active.sprite(id: $0.id)?.layer }), [2])
    }

    func testBranchFirstHandleNextFrame() throws {
        let w = try world()
        let id = try tree(w, rec(0xc08, x: 3000, y: 900))
        var handled: [Int] = []
        let width = try widths()
        func pass() {
            handled = []
            _ = w.handleSprites { w, i in
                handled.append(i)
                guard let s = w.active.record(id: i) else { return }
                switch s.handler {
                case .background: BackgroundSprite.handle(world: w, id: i, faceWidth: width)
                case .box: BoxSprite.handle(world: w, id: i)
                default: break
                }
            }
        }
        // The planting frame: the tree's Handle makes three branches, inserted ahead of it (layer 2 < 30000), so the walk
        // (its saved `next`, M l. 30716–30719) never reaches them this frame.
        pass()
        XCTAssertEqual(handled, [id])
        let kids = w.active.sprites.filter { $0.type == BoxSprite.branch && $0.handler == .box }
        XCTAssertEqual(kids.count, 3)
        // For the rest of the planting frame each is a solid Box in `.SetupBoxSprite`'s head state (M l. 58936–58947):
        // the Box Handle, its hit and tile callbacks, `+0xa6 = 3`, gravity 0x151, HP 600, not one-way, no face; then the
        // tail (M l. 59722–59727): 24.8 from `+8` / `+6`, `+0xa/+0xc` = `+6/+8`, `+0x13c = 0x80`.
        for k in kids {
            XCTAssertEqual(k.handler, .box)
            XCTAssertEqual([k.hasHit, k.hasTileHit, k.oneWay], [true, true, false])
            XCTAssertEqual([Int(k.counterA6), Int(k.gravity), Int(k.hp), Int(k.pushForce)], [3, 0x151, 600, 0x80])
            XCTAssertNil(k.face)
            XCTAssertEqual([k.x256, k.y256], [Int32(k.oldPosition.x) << 8, Int32(k.oldPosition.y) << 8])
            XCTAssertEqual([k.x, k.y], [k.oldPosition.x, k.oldPosition.y])
        }
        // The next frame: each branch's first Handle (before the tree's) — one-way, no face, no callbacks, no gravity.
        pass()
        XCTAssertEqual(handled, kids.map(\.id) + [id])
        for k in kids {
            let s = try XCTUnwrap(w.active.sprite(id: k.id))
            XCTAssertEqual([s.hasHit, s.hasTileHit, s.oneWay], [false, false, true])
            XCTAssertEqual(s.gravity, 0)
            XCTAssertEqual([s.x, s.y], [k.x, k.y], "stands where it was planted")
        }
        XCTAssertEqual(w.active.sprites.filter { $0.type == BoxSprite.branch && $0.handler == .box }.count, 3, "planted once")
    }

    func testTreeNoFreeRecordDropsStores() throws {
        // `.MTNewSprite` with all 700 records in use returns 0 (Ruling 16): `.SetupTree` stores 0 into the slot and its
        // hot-rect writes through it are dropped; the stores after (the next branch, the Handle's face and mirror) are
        // still made.
        for free in 0...2 {
            let w = try world()
            let id = try tree(w, rec(0xc08, p1: 1))
            for i in 0..<(SpriteWorld.recordCount - 1 - free) {
                _ = w.active.insert(SpriteSlot(type: 0x426, x: 10 * i, y: 0))
            }
            XCTAssertEqual(w.active.sprites.count, SpriteWorld.recordCount - free)
            let before = Set(w.active.sprites.map(\.id))
            BackgroundSprite.handle(world: w, id: id, faceWidth: try widths())
            let kids = made(w, since: before)
            XCTAssertEqual(kids.count, free, "\(free) free")
            XCTAssertEqual(w.refusedSpawns, 3 - free)
            guard kids.count == free else { continue }                     // a failure, never a crash
            let s = try XCTUnwrap(w.active.sprite(id: id))
            XCTAssertEqual(slots(s), (0..<4).map { $0 < free ? kids[$0].id : nil }, "\(free) free")
            XCTAssertTrue(s.setupDone)
            XCTAssertEqual(s.face, FaceRef(pict: 0xc08, index: 0, set: .encoded))
            XCTAssertTrue(s.mirrored)
            // The made branches got their hot rects; no other sprite was written.
            for (i, k) in kids.enumerated() {
                let b = Self.table[0xc08]![i]
                XCTAssertEqual(k.hotRect, Rect(top: 0, left: 0, bottom: b.b - b.t, right: b.r - b.l))
            }
            XCTAssertTrue(w.active.sprites.filter { $0.type == 0x426 }.allSatisfy {
                $0.hotRect == Rect(top: 0, left: 0, bottom: 0, right: 0)
            })
        }
        do {
            // 0xc0b with four free records: the first four branches are made, the fifth spawn returns 0 and `.SetupTree`
            // stores that 0 into `+0x1d4` over the first branch's pointer (M l. 62765–62770; Ruling 16) — the slot is
            // written even when the spawn fails.
            let w = try world()
            let id = try tree(w, rec(0xc0b, index: 52, x: 500, y: 700))
            for i in 0..<(SpriteWorld.recordCount - 1 - 4) { _ = w.active.insert(SpriteSlot(type: 0x426, x: 10 * i, y: 0)) }
            let before = Set(w.active.sprites.map(\.id))
            BackgroundSprite.handle(world: w, id: id, faceWidth: try widths())
            let kids = made(w, since: before)
            XCTAssertEqual(kids.count, 4)
            XCTAssertEqual(w.refusedSpawns, 1)
            guard kids.count == 4 else { return }
            XCTAssertEqual(slots(try XCTUnwrap(w.active.sprite(id: id))), [nil, kids[1].id, kids[2].id, kids[3].id])
        }
    }

    // MARK: - the picture cache (`_DAT_100a0ae0`)

    func testTreeCacheMarks() throws {
        // `.SetupBackgroundSprite` marks `_DAT_100a0ae0[type − 0xc08]` (`rec + 1 = 1`, M l. 62603): the single of the
        // tree's own picture, registered by `.InitBackgroundSprite` (M l. 61889–61895) under flag 1 — LL §6 singles
        // #137–#144.
        for t in Int16(0xc08)...0xc0f {
            let k = CachedFaces.RecordKey.single(136 + Int(t - 0xc08))
            XCTAssertEqual(CachedFaces.markedRecords(type: t), [k], "\(t)")
            XCTAssertEqual(CachedFaces.record(k).pict, t)
            XCTAssertEqual(CachedFaces.record(k).flag, 1)
            XCTAssertTrue(CachedFaces.record(k).present)
            XCTAssertEqual(CachedFaces.marks(type: t).singles, [t])
        }
        // No other type marks a tree record.
        let trees = Set((136..<144).map { CachedFaces.RecordKey.single($0) })
        for t in Int16(0)...0x0d00 where !BackgroundSprite.trees.contains(t) {
            XCTAssertTrue(Set(CachedFaces.markedRecords(type: t)).isDisjoint(with: trees), "\(t)")
        }
        // Level by level, the records the placed trees mark (every tree sets up, per record): 10 and 11 the four
        // 0xc08…0xc0b, 15 the three 0xc0c…0xc0e.
        let r = try resources()
        for (level, picts): (Int16, Set<Int16>) in [(10, [0xc08, 0xc09, 0xc0a, 0xc0b]), (11, [0xc08, 0xc09, 0xc0a, 0xc0b]),
                                                     (15, [0xc0c, 0xc0d, 0xc0e])] {
            let L = try LevelFile.load(from: r, level: level)
            let c = SetupFaces.Context(level: L, playerX: 0)
            var marked = Set<CachedFaces.RecordKey>()
            for p in L.activePlacements where BackgroundSprite.trees.contains(p.type) {
                _ = try SetupFaces.setup(p, context: c)
                marked.formUnion(CachedFaces.markedRecords(type: p.type, p1: p.p1))
            }
            XCTAssertEqual(CachedFaces.Needed(records: marked).singles, picts, "level \(level)")
        }
    }

    // MARK: - ENG §5

    func testUnplacedBackgroundArms() throws {
        // Background 0x73f / 0x740 and their `.HitPlayerSprite` arm (M l. 49753–49760: `HurtPlayer(0x38, 1, 0x3c)`,
        // `+0x116 = 0x28`) are placed on no level of the world file — kept refused at Setup and unrun at the Handle.
        let r = try resources()
        let levels = r.world.resources(of: "Mlvl")
        XCTAssertEqual(levels.count, 24)
        for res in levels {
            let L = try LevelFile(resource: res)
            XCTAssertFalse(L.activePlacements.contains { $0.type == 0x73f || $0.type == 0x740 }, "level \(res.id)")
        }
        let w = try world()
        let c = SetupFaces.Context(level: w.level, playerX: 0)
        for t: Int16 in [0x73f, 0x740] {
            XCTAssertEqual(SpriteClassTable.classify(type: t, p1Negative: false)?.0, .background)
            XCTAssertThrowsError(try SetupFaces.setup(rec(t), context: c)) {
                XCTAssertEqual($0 as? SetupFaces.Error, .notTranscribed(type: t))
            }
            XCTAssertTrue(BackgroundSprite.isUnbuiltArm(t))
        }
        // The trees are no longer an unbuilt arm.
        for t in BackgroundSprite.trees { XCTAssertFalse(BackgroundSprite.isUnbuiltArm(t), "\(t)") }
    }
}
