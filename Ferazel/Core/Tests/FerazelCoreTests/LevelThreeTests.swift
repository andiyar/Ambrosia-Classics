import XCTest
import HectorResources
@testable import FerazelCore

/// LV3 (docs/plans/2026-10-24-ferazel-phase4.md): level 3 "Western Reaches" enterable — every one of its 216 records
/// sets up (the enemy face stubs Blob 1730 and Bat 1741, the decorations' faces, the retracting spikes 1840…1843), the
/// spikes' Handle with its idle-only sounds (`.HandleBackgroundSprite` M l. 63192–63276) and their arm in
/// `.HitPlayerSprite` (M l. 49743–49751), `BuiltLevels = 1...3`. Against the committed `Resources/Ferazel` (D26); a
/// missing data file is a FAILURE, never a skip.
final class LevelThreeTests: XCTestCase {

    private func resources() throws -> FerazelResources { try FerazelData.open(try FerazelData.dataDirectory()) }

    /// Level 3 with a 16×16 empty grid and the player spawned at (`px`, `py`) (as `ButtonGateTests.world`).
    private func world(px: Int = 100, py: Int = 200) throws -> (SpriteWorld, Int) {
        let w = SpriteWorld(level: try LevelFile.load(from: try resources(), level: 3))
        let empty = [UInt16](repeating: 0, count: 16 * 16)
        w.tiles = TileGrid(fg: TileMap(width: 16, height: 16, cells: empty), bg: TileMap(width: 16, height: 16, cells: empty),
                           fgKinds: Array(0..<0x60), bgKinds: [Int](repeating: 0, count: 0x60))
        let pid = try XCTUnwrap(Player.spawn(world: w, x: px, y: py))
        w.playerID = pid
        return (w, pid)
    }

    /// Record `i` with its params replaced, set up and inserted.
    private func add(_ w: SpriteWorld, record i: Int, p2: Int16? = nil, p3: Int16? = nil,
                     p4: Int16? = nil) throws -> Int {
        let q = w.records[i]
        let p = Placement(index: q.index, flag: q.flag, byte1: q.byte1, type: q.type, p1: q.p1, p2: p2 ?? q.p2,
                          p3: p3 ?? q.p3, p4: p4 ?? q.p4, y: q.y, x: q.x)
        return w.active.insert(try SetupFaces.setup(p, context: SetupFaces.Context(level: w.level, playerX: 0)).slot)
    }

    private func handle(_ w: SpriteWorld, _ id: Int) {
        w.player.cues = []
        BackgroundSprite.handle(world: w, id: id) { _ in 0x80 }
    }

    private func rect(_ l: Int, _ t: Int, _ r: Int, _ b: Int) -> IdleSprites.Rect {
        IdleSprites.Rect(top: t, left: l, bottom: b, right: r)
    }

    // MARK: -

    func testLevel3SetsUpEveryRecord() throws {
        let r = try resources()
        let L = try LevelFile.load(from: r, level: 3)
        XCTAssertEqual(L.activePlacements.count, 216)
        let c = SetupFaces.Context(level: L, playerX: SetupFaces.Context.levelStartPlayerX(L.header))
        // Every record sets up: no `notTranscribed` (nor any other refusal).
        var refused: [Int16] = []
        for p in L.activePlacements where (try? SetupFaces.setup(p, context: c)) == nil { refused.append(p.type) }
        XCTAssertEqual(refused, [])
        let sp = try SetupFaces.spawnLevelSprites(context: c) { _ in .noFace }
        XCTAssertEqual(sp.created.count, 216)
        XCTAssertEqual(sp.active.sprites.filter { $0.recordIndex >= 0 }.count + sp.idle.entries.compactMap { $0 }.count, 216)
        // The two spikes spawn now (`.GenerateSprite`: 0x730…0x733 → now).
        XCTAssertEqual(sp.active.sprites.filter { BackgroundSprite.spikes.contains($0.type) }.map(\.recordIndex).sorted(),
                       [160, 217])
        // The level's enemy total (`*_DAT_1009ffb4`): 8 Walkers, 2 Crawlers, 1 Frog, 12 Bats (0x6cc…0x6d5) and the
        // four Blobs (M l. 67728–67730) — 27.
        let classes = L.activePlacements.compactMap { SpriteClassTable.classify(type: $0.type, p1Negative: $0.p1 < 0)?.0 }
        XCTAssertEqual([.walker, .crawler, .frog, .bat, .blob, .roach].map { k in classes.filter { $0 == k }.count },
                       [8, 2, 1, 12, 4, 0])
        XCTAssertEqual(sp.tallies.enemies, 27)
        let session = try FerazelSession(resources: r, prefs: FerazelPrefs(), level: 3)
        XCTAssertEqual(session.tallies.enemies, 27)
        // Every enemy Setup sets `+0x1b5` (Walker M l. 57091–57093, Crawler 56237–56239, Frog 70213–70215, Bat 68282–
        // 68285, Blob 67728–67730); the tally counts each Setup once (27, above), not the flag.
        for k in [SpriteClass.walker, .crawler, .frog, .bat, .blob] {
            let recs = L.activePlacements.filter { SpriteClassTable.classify(type: $0.type, p1Negative: $0.p1 < 0)?.0 == k }
            XCTAssertEqual(try recs.map { try SetupFaces.setup($0, context: c).slot.countedInTotals },
                           [Bool](repeating: true, count: recs.count), "\(k)")
        }
        // The level-load bar (`.LoadCachedSpriteFaces` M l. 73769–73868) on a fresh cache: the sets the level's Setups
        // mark in registration order — Crawler 0x6ae, 0x6af, 0x6b1 (6 each), Walker 0x6a5 (8), 0x6a6 (6), 0x6a9 (3),
        // 0x6aa (2), 0x6ab (9), the mine cart 0xb72 (14), 0xb73 (21), the wall spikes 0x730 (12), Bat 0x6cc (11), Blob 0x6c2
        // (16), Frog 0x708 (8): 128 faces — then 16 singles (0x6a4, the decorations 0xafc, 0xafd, 0xb04, 0xb05, 0xb10,
        // 0xb1b, 0xb20, the outcrops 0xb34, 0xb35, the mushrooms 0xb43, 0xb44, 0xb6f, 0xb8a, the spikes' 0x732, 0x733):
        // n = 144, q = 288, 29 steps.
        var cache = CachedFaces()
        cache.enterLevel(screenClut: L.header.screenClut)
        let needed = CachedFaces.needed(by: session)
        XCTAssertEqual(needed.sets, [0x6a5, 0x6a6, 0x6a9, 0x6aa, 0x6ab, 0x6ae, 0x6af, 0x6b1, 0xb72, 0xb73, 0x730, 0x6cc,
                                     0x6c2, 0x708])
        XCTAssertEqual(needed.singles, [0x6a4, 0xafc, 0xafd, 0xb04, 0xb05, 0xb10, 0xb1b, 0xb20, 0xb34, 0xb35, 0xb43, 0xb44,
                                        0xb6f, 0xb8a, 0x732, 0x733])
        let bars = cache.load(needed: needed)
        XCTAssertEqual(bars.map { $0.0 }, [150, 156, 162, 170, 176, 179, 181, 190, 204, 225, 237, 248, 264, 272]
                        + Array(273...288))
        XCTAssertEqual(Set(bars.map { $0.1 }), [288])

        func entry(_ rec: Int) throws -> SetupFaces.Entry { try SetupFaces.setup(L.placements[rec], context: c) }
        func f(_ pict: Int16, _ i: Int = 0) -> FaceRef { FaceRef(pict: pict, index: i, set: .encoded) }
        // Blob 1730 (rec 15; `.SetupBlobSprite` M l. 67671–67736): layer 8, gravity 0xfa, HP 700, SetRect(0xe, 0xc, 0x2f,
        // 0x21), `+0x150 = −1`, `+0xb0 = 6`, `+0x46 = 2`, the cache face 0x6c2 cell 0, counted; inert (Ruling 3).
        var e = try entry(15)
        XCTAssertEqual([e.slot.layer, Int32(e.slot.gravity), Int32(e.slot.hp), e.slot.classWord150, Int32(e.slot.subtype),
                        Int32(e.slot.phase)], [8, 0xfa, 700, -1, 6, 2])
        XCTAssertEqual(e.slot.mode, 0)                                   // `+0xb8 = 0` for 0x6c2 (M l. 67707)
        XCTAssertEqual(e.slot.hotRect, rect(0xe, 0xc, 0x2f, 0x21))
        XCTAssertEqual([e.slot.countedInTotals, e.slot.hasHit], [true, false])
        XCTAssertEqual(e.slot.handler, .inert)
        XCTAssertEqual(e.slot.face, f(0x6c2))
        XCTAssertEqual(e.source, .setupCached)
        XCTAssertEqual(e.sheet, SetupFaces.Sheet(pict: 0x6c2, count: 16, cellWidth: 0x40, cellHeight: 0x2c, columns: 16,
                                                 clut: 200))
        // Bat 1741 (rec 189: p1 2, p2 340, p3 800): the 0x6cc… arm plus `+0x188`, `+0xa6 = 1`, gravity 0 and the
        // programmed path's mode 2 (`+0xf0` = 2, vx = p3); no draw.
        e = try entry(189)
        XCTAssertEqual([e.slot.keepRecord, e.slot.hasHit], [true, false])
        XCTAssertEqual([Int32(e.slot.counterA6), Int32(e.slot.gravity), e.slot.voicePitch, e.slot.vx, e.slot.vy,
                        Int32(e.slot.hp), Int32(e.slot.subtype), e.slot.layer], [1, 0, 2, 800, 0, 500, 7, 0xb])
        XCTAssertEqual(e.slot.face, f(0x6cc))
        XCTAssertEqual(e.source, .handle)
        // Decorations (pickups-boxes-2 §9): Red Ruins 2 (rec 154: p1 1 mirrored, p2 11 → `+0xb8 = 0x1000b`, p3 1 →
        // layer 10000), the pedestal 2832 (rec 144: the standable rect), a rock outcrop 2869 (rec 171: layer 0x96, its
        // cache in level 3's level+base CLUT 210) and the mushroom cluster 2884 (rec 159: layer 0x78).
        e = try entry(154)
        XCTAssertEqual([e.slot.mirrored, e.slot.oneWay], [true, true])
        XCTAssertEqual([Int64(e.slot.mode), Int64(e.slot.layer)], [0x1000b, 10000])
        XCTAssertEqual(e.sheet, .single(0xafd))
        e = try entry(144)
        XCTAssertEqual(e.slot.hotRect, rect(0xe, 4, 0x27, 0x45))
        XCTAssertEqual(e.sheet, .single(0xb10))
        e = try entry(171)
        XCTAssertEqual([e.slot.layer, Int32(e.source == .handle ? 1 : 0)], [0x96, 1])
        XCTAssertEqual(ColorLUT.screenClutId(L.header), 210)
        XCTAssertEqual(e.sheet, .single(0xb35, clut: 210))
        e = try entry(159)
        XCTAssertEqual([e.slot.layer], [0x78])
        XCTAssertEqual(e.sheet, .single(0xb44))
        for (rec, pict) in [(153, 0xafc), (162, 0xb04), (164, 0xb05), (169, 0xb1b), (172, 0xb34)] as [(Int, Int16)] {
            XCTAssertEqual(try entry(rec).sheet?.pict, pict, "rec \(rec)")
        }
        // On levels 1–2 the level+base CLUT is 202: the flag-1 caches keep the table's 202 there.
        let L1 = try LevelFile.load(from: r, level: 1)
        let c1 = SetupFaces.Context(level: L1, playerX: 0)
        let tunnel = try XCTUnwrap(L1.activePlacements.first { (3000...3005).contains($0.type) })
        XCTAssertEqual(try SetupFaces.setup(tunnel, context: c1).sheet?.clut, 202)
        // Each flag-1 group takes level 3's CLUT: a bridge 0x5b5, a plant 0xa96, a tunnel 0xbba, an outcrop 0xb25 (types
        // levels 1–2 place, set up here on level 3's header); a flag-0 decoration keeps 200.
        let anyRec = L.placements[144]
        for (type, clut) in [(0x5b5, 210), (0xa96, 210), (0xbba, 210), (0xb25, 210), (0xb1a, 200)] as [(Int16, Int16)] {
            let q = Placement(index: anyRec.index, flag: 1, byte1: 0, type: type, p1: 0, p2: 0, p3: 0, p4: 0, y: anyRec.y,
                              x: anyRec.x)
            XCTAssertEqual(try SetupFaces.setup(q, context: c).sheet?.clut, clut, "type \(type)")
        }
        // The spikes: the floor 1842 (rec 160) and the wall 1841 (rec 217), both p 0 — static (p2 0 → 32000), out
        // (frame 0: p4 0 < 32000), `+0x188`, HP 500, the base y; 1841 mirrored, faced from the set 0x730.
        e = try entry(160)
        XCTAssertEqual([e.slot.classWord150, e.slot.classWord154, Int32(e.slot.counterA6), Int32(e.slot.phase),
                        Int32(e.slot.hp), e.slot.classWord158], [32000, 0, 0, 0, 500, 930])
        XCTAssertEqual([e.slot.keepRecord, e.slot.mirrored, e.slot.hasHit], [true, false, false])
        XCTAssertEqual(e.slot.handler, .background)
        XCTAssertEqual(e.slot.hotRect, rect(0, 0, 0, 0))
        XCTAssertEqual(e.sheet, .single(0x732))
        e = try entry(217)
        XCTAssertEqual([e.slot.keepRecord, e.slot.mirrored], [true, true])
        XCTAssertEqual(e.slot.face, f(0x730, 0))
        XCTAssertEqual(e.slot.classWord158, 0)                           // the wall arms store no base y (M l. 61982ff)
        // The first frame: p4 < p2 → 0 (out), p4 ≥ p2 → 0xb (in) — the wall's face cell is that frame at its Setup.
        func spike(_ rec: Int, p2: Int16, p4: Int16, level: LevelFile? = nil) throws -> SetupFaces.Entry {
            let q = L.placements[rec]
            let p = Placement(index: q.index, flag: q.flag, byte1: q.byte1, type: q.type, p1: q.p1, p2: p2, p3: 30,
                              p4: p4, y: q.y, x: q.x)
            return try SetupFaces.setup(p, context: SetupFaces.Context(level: level ?? L, playerX: 0))
        }
        XCTAssertEqual(try [spike(160, p2: 60, p4: 59), spike(160, p2: 60, p4: 60), spike(217, p2: 60, p4: 59),
                            spike(217, p2: 60, p4: 60)].map { Int($0.slot.phase) }, [0, 0xb, 0, 0xb])
        XCTAssertEqual(try spike(217, p2: 60, p4: 60).slot.face, f(0x730, 0xb))
        XCTAssertEqual(try spike(217, p2: 60, p4: 60).faceIndex, 0xb)
        // hdr 0x26cd ≠ 0 → `+0xb8 = 0x10018`; then a water cell under (x >> 5, (y + 0xc) >> 5) → 0x90000 (patched data:
        // the spike moved onto the first dry BG tile of row 20, that tile's kind made water).
        let row = 20
        let col = try XCTUnwrap((0..<L.bg.width).first { k in
            let t = L.bgTile(col: k, row: row)
            return (0..<96).contains(t) && !LiquidTiles.range.contains(L.bgKind(tile: t))
        })
        let tile = L.bgTile(col: col, row: row)
        func spike(_ rec: Int, at level: LevelFile) throws -> SetupFaces.Entry {
            let q = L.placements[rec]
            let p = Placement(index: q.index, flag: q.flag, byte1: q.byte1, type: q.type, p1: 0, p2: 0, p3: 0, p4: 0,
                              y: Int16(row * 32 - 0xc), x: Int16(col * 32))
            return try SetupFaces.setup(p, context: SetupFaces.Context(level: level, playerX: 0))
        }
        func patched(_ bytes: [Int: [UInt8]]) throws -> LevelFile {
            var d = try XCTUnwrap(r.world.resource(type: "Mlvl", id: 3)).data
            for (o, b) in bytes { for (i, v) in b.enumerated() { d[d.startIndex + o + i] = v } }
            return try LevelFile(id: 3, data: d)
        }
        let icy = try patched([0x26cd: [1]])
        XCTAssertEqual(try spike(160, at: icy).slot.mode, 0x10018)
        XCTAssertEqual(try spike(160, at: L).slot.mode, 0)
        let wet = try patched([0x26cd: [1], 0x29a0 + 2 * tile: [0, 200]])
        XCTAssertEqual(try spike(160, at: wet).slot.mode, 0x90000)
        XCTAssertEqual(try spike(217, at: wet).slot.mode, 0x90000)
        XCTAssertEqual(e.sheet, SetupFaces.Sheet(pict: 0x730, count: 12, cellWidth: 0x18, cellHeight: 0x80, columns: 12,
                                                 clut: 200))
    }

    func testStaticSpikeHurts() throws {
        // L3 rec 160 (1842, p2 0): static and out. The dump's frame 0 is the most extended one (rect while frame < 2,
        // y = base + 2·frame) — the plan's "frame 11 (extended)" has it the wrong way round.
        let (w, pid) = try world()
        let k = try add(w, record: 160)
        let seed = w.rng.seed
        handle(w, k)
        var s = try XCTUnwrap(w.active.sprite(id: k))
        XCTAssertEqual([Int(s.counterA6), Int(s.phase), s.y, s.clip.bottom], [1, 0, 930, 0x14])
        XCTAssertEqual(s.hotRect, rect(0, 0, 0x80, 0x20))
        XCTAssertEqual(s.face, FaceRef(pict: 0x732, index: 0, set: .encoded))
        XCTAssertEqual([w.player.cues.count, Int(w.rng.seed)], [0, Int(seed)])

        // Touching it (the player's rect over the spike's): climb 0, the no-cling timer 3, `.HurtPlayer(0x70, blood 1,
        // 60, coins 0)` — the blood spray made, no coin lost — then invulnerable 30.
        let hr = try XCTUnwrap(w.active.sprite(id: pid)).hotRect
        w.active.update(id: pid) { $0.x = s.x + 0x20 - hr.left; $0.y = s.y + 8 - hr.top }
        w.player.climb = 1
        w.globals.coins = 10
        let hp = try XCTUnwrap(w.active.sprite(id: pid)).hp
        let sprites = w.active.sprites.count
        HitPlayerSprite.hit(w, player: pid, other: k)
        var p = try XCTUnwrap(w.active.sprite(id: pid))
        XCTAssertEqual([Int(hp - p.hp), Int(p.invulnerable), Int(w.player.noCling), Int(w.player.climb)], [0x70, 30, 3, 0])
        XCTAssertTrue(w.player.cues.contains { $0.snd == 508 })                // the hurt's cue (damage < 0xe0)
        XCTAssertGreaterThan(w.particles.counters.count, 0)                    // blood 1: `.BloodSpray`
        XCTAssertEqual(w.globals.coins, 10)                                    // coins 0: none lost
        XCTAssertFalse(w.player.cues.contains { $0.snd == 489 })
        XCTAssertEqual(w.active.sprites.count, sprites)
        // Again while invulnerable (the timer run down to 5): the climb and no-cling stores still happen; no hurt, and
        // the timer is not reset to 30.
        w.player.climb = 1
        w.player.noCling = 0
        w.player.cues = []
        w.active.update(id: pid) { $0.invulnerable = 5 }
        HitPlayerSprite.hit(w, player: pid, other: k)
        p = try XCTUnwrap(w.active.sprite(id: pid))
        XCTAssertEqual([Int(hp - p.hp), Int(p.invulnerable), Int(w.player.noCling), Int(w.player.climb)], [0x70, 5, 3, 0])
        XCTAssertEqual(w.player.cues, [])
        // The mirrored wall spike (rec 217, 1841): out, its rect SetRect(7, 0xc, 0x20, 0x74).
        let wall = try add(w, record: 217)
        handle(w, wall)
        XCTAssertEqual(try XCTUnwrap(w.active.sprite(id: wall)).hotRect, rect(7, 0xc, 0x20, 0x74))
        XCTAssertEqual(try XCTUnwrap(w.active.sprite(id: wall)).face, FaceRef(pict: 0x730, index: 0, set: .encoded))

        // As written, the static spike's counter reaches 32000 = p2 + p3 once: one frame in (458's idle-only call,
        // volume 0x41), then the wrap to 0 brings it out again with no call (frame 1 is not 0xb).
        w.active.update(id: k) { $0.counterA6 = 31999 }
        var rr = w.rng
        let centre = try XCTUnwrap(w.active.sprite(id: k)).centre
        let rate = rr.soundRate()
        handle(w, k)
        s = try XCTUnwrap(w.active.sprite(id: k))
        XCTAssertEqual([Int(s.counterA6), Int(s.phase), s.y, s.clip.bottom], [32000, 1, 932, 0x12])
        XCTAssertEqual(w.player.cues, [PlayerCue(call: .threeDRand, snd: 458, priority: 1, volume: 0x41, position: centre,
                                                 rate: rate)])
        XCTAssertEqual(w.rng.seed, rr.seed)
        handle(w, k)
        s = try XCTUnwrap(w.active.sprite(id: k))
        XCTAssertEqual([Int(s.counterA6), Int(s.phase), s.y], [0, 0, 930])
        XCTAssertEqual([w.player.cues.count, Int(w.rng.seed)], [0, Int(rr.seed)])
    }

    func testSpikeIdleOnlySound() throws {
        // A timed 0x732 (rec 160 with p2 60, p3 30, p4 70): in at its Setup (p4 ≥ p2 → frame 0xb).
        let (w, _) = try world()
        let k = try add(w, record: 160, p2: 60, p3: 30, p4: 70)
        XCTAssertEqual(try XCTUnwrap(w.active.sprite(id: k)).phase, 0xb)
        handle(w, k)                                                     // 71: in, already fully in — no call
        var s = try XCTUnwrap(w.active.sprite(id: k))
        XCTAssertEqual([Int(s.counterA6), Int(s.phase), s.y, s.clip.bottom], [71, 0xb, 952, 0])
        XCTAssertEqual(s.hotRect, rect(0, 0, 0, 0))
        XCTAssertEqual(w.player.cues, [])
        // The counter passes p2 + p3 = 90 → 0: out, at frame 0xb with 457 playing (`FUN_100916dc(457)` ≠ 0) → no call,
        // no draw; the frame steps to 10.
        w.active.update(id: k) { $0.counterA6 = 90 }
        w.voices = SoundVoices(playing: [457])
        var rr = w.rng
        handle(w, k)
        s = try XCTUnwrap(w.active.sprite(id: k))
        XCTAssertEqual([Int(s.counterA6), Int(s.phase), s.y], [0, 10, 950])
        XCTAssertEqual([w.player.cues.count, Int(w.rng.seed)], [0, Int(rr.seed)])
        // Idle: the call is made — `.STPlay3DSoundRand(457, 1, 0x41, centre)` and its R(10000).
        w.active.update(id: k) { $0.counterA6 = 90; $0.phase = 0xb }
        w.voices = SoundVoices()
        let centre = s.centre
        let rate = rr.soundRate()
        handle(w, k)
        XCTAssertEqual(w.player.cues, [PlayerCue(call: .threeDRand, snd: 457, priority: 1, volume: 0x41, position: centre,
                                                 rate: rate)])
        XCTAssertEqual(w.rng.seed, rr.seed)
        // Out to frame 0 one step a frame: the rect (0, 0, 0x80, 0x20) from frame 1; no further call.
        var frames: [Int] = [], rects: [Bool] = []
        for _ in 0..<10 {
            handle(w, k)
            s = try XCTUnwrap(w.active.sprite(id: k))
            frames.append(Int(s.phase))
            rects.append(s.hotRect == rect(0, 0, 0x80, 0x20))
            XCTAssertEqual(w.player.cues, [])
        }
        XCTAssertEqual(frames, [9, 8, 7, 6, 5, 4, 3, 2, 1, 0])
        XCTAssertEqual(rects, [false, false, false, false, false, false, false, false, true, true])
        // The ceiling 0x733 (same record retyped): y = base − 2·frame, the top clip = base − y; and the wall 0x730 at
        // frame 0 going in: 458 at volume 0x97, the face cell = frame, the wall rect while frame < 2.
        func retyped(_ type: Int16, p4: Int16) throws -> Int {
            let q = w.records[160]
            let p = Placement(index: q.index, flag: q.flag, byte1: q.byte1, type: type, p1: 0, p2: 60, p3: 30, p4: p4,
                              y: q.y, x: q.x)
            return w.active.insert(try SetupFaces.setup(p, context: SetupFaces.Context(level: w.level, playerX: 0)).slot)
        }
        let ceiling = try retyped(0x733, p4: 70)
        handle(w, ceiling)
        s = try XCTUnwrap(w.active.sprite(id: ceiling))
        XCTAssertEqual([s.y, s.clip.top, Int(s.phase)], [930 - 22, 22, 0xb])
        XCTAssertEqual(s.face, FaceRef(pict: 0x733, index: 0, set: .encoded))
        let wall = try retyped(0x730, p4: 59)
        XCTAssertEqual(try XCTUnwrap(w.active.sprite(id: wall)).phase, 0)
        let wc = try XCTUnwrap(w.active.sprite(id: wall)).centre
        let wrate = rr.soundRate()
        handle(w, wall)                                                  // 60: in, frame 0 → 458, then frame 1
        s = try XCTUnwrap(w.active.sprite(id: wall))
        XCTAssertEqual(w.player.cues, [PlayerCue(call: .threeDRand, snd: 458, priority: 1, volume: 0x97, position: wc,
                                                 rate: wrate)])
        XCTAssertEqual([Int(s.phase), s.y], [1, 930])
        XCTAssertEqual(s.face, FaceRef(pict: 0x730, index: 1, set: .encoded))
        XCTAssertEqual(s.hotRect, rect(0, 0xc, 0x13, 0x74))
        handle(w, wall)
        XCTAssertEqual(try XCTUnwrap(w.active.sprite(id: wall)).hotRect, rect(0, 0, 0, 0))
    }

    // MARK: - the map

    private final class NoFiles: FrontFiles {
        func loadPrefs() -> Data? { nil }
        func storePrefs(_ record: Data) throws {}
        func readSavedGame(_ ref: SavedGameRef) throws -> SaveBlock { throw SavedGameError.notASavedGame }
        func writeSavedGame(_ block: SaveBlock, to ref: SavedGameRef) throws(SaveWriteError) {}
    }

    private final class Levels: LevelServices {
        var prepared: [Int] = []
        func prepare(level: Int) throws -> LevelFaces { prepared.append(level); return LevelFaces() }
        func attach(lights: [SetupFaces.Light], tintTableDraws: [Int16]) throws {}
        func deathEffectStep(_ k: Int) throws {}
    }

    func testMapEntersLevel3() throws {
        let r = try resources()
        XCTAssertEqual(BuiltLevels.range, 1...3)
        /// New Game at level 2 (the hidden `FerazelLevel` switch), then level 2's exit `record` → the map's auto-walk;
        /// Return on the map. The flow and the dialogs asked on the way.
        func viaExit(_ record: Int, node level: Int) throws -> (GameFlow, Levels, [FerazelDialog]) {
            let levels = Levels()
            let flow = GameFlow(resources: r, prefs: FerazelPrefs(), seed: 1, files: NoFiles(), levels: levels)
            flow.startLevel = 2
            var t: UInt32 = 1000
            var asked: [FerazelDialog] = []
            func drive(_ keys: (GameFlow) -> [Int] = { _ in [] }, until: (GameFlow) -> Bool) {
                for _ in 0..<6000 {
                    if case .loading = flow.state { flow.loadFinished() }
                    let out = flow.tick(now: t, input: FrontInput(keys: KeyState(pressed: keys(flow))))
                    asked += out.requests.compactMap { if case .dialog(let d) = $0 { return d }; return nil }
                    t &+= 1
                    if until(flow) { return }
                }
                XCTFail("the flow did not reach the condition (state \(flow.state))")
            }
            drive { $0.state == .mainMenu }
            drive({ _ in [0x2d] }) { _ in true }
            drive { f in f.levelRun?.levelNumber == 2 && (f.levelRun?.iterations ?? 0) >= 45 }
            try touchExit(try XCTUnwrap(flow.levelRun?.session), record: record)
            drive { f in (f.worldMap.map { $0.iterations >= 2 && $0.walkStep == 0 && $0.result == nil }) ?? false }
            let m = try XCTUnwrap(flow.worldMap)
            XCTAssertEqual(m.cur, try XCTUnwrap(m.map.findCurrNode(level: Int16(level))).index)
            drive({ f in f.worldMap?.result == nil ? [0x24] : [] }) { f in
                f.worldMap == nil || !asked.isEmpty
            }
            if asked.isEmpty { drive { f in f.levelRun?.levelNumber == level && (f.levelRun?.iterations ?? 0) >= 2 } }
            return (flow, levels, asked)
        }
        // Exit p1 1 (record 39) → node 3 → Return → level 3 runs (its every record set up by the session).
        let (f3, l3, a3) = try viaExit(39, node: 3)
        XCTAssertEqual(a3, [])
        XCTAssertEqual(f3.levelRun?.levelNumber, 3)
        XCTAssertEqual(f3.levelRun?.session?.tallies.enemies, 27)
        XCTAssertEqual(l3.prepared, [2, 3])
        XCTAssertEqual(f3.levelNumber, 3)
        // Exit p1 2 (record 98) → node 4 → Return → "Level 4 is not built yet (Phases 4-6)." and no level run.
        let (f4, l4, a4) = try viaExit(98, node: 4)
        XCTAssertEqual(a4.last, .report(text: "Level 4 is not built yet (Phases 4-6)."))
        XCTAssertNil(f4.levelRun)
        XCTAssertEqual(l4.prepared, [2])
    }
}
