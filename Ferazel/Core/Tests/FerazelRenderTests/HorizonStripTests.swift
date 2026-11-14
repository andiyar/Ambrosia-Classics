import XCTest
import HectorResources
@testable import FerazelCore
@testable import FerazelRender

/// 6A-S8 (docs/superpowers/plans/2026-11-04-ferazel-remainder.md `#### 6A-S8`; docs/ferazel/phase6-engine-contracts.md
/// §2.1): the horizon strip — its sprites on the six levels that switch it on (10, 30, 40, 45, 62, 67; the five that
/// cannot open in 6A by header only), the Handle run twice a frame, the face from the Backgrounds file under the
/// colour table `.MTAddPxSprite` sees, draw mode 8 (`.BlitEncFaceBehindTilesNoClip` / `…Clip`, the mask pass after
/// it), and the level-10 fixture's frame. A missing data file is a FAILURE, never a skip.
final class HorizonStripTests: XCTestCase {

    /// Level 10's leave-out list (6A-S8; LL §4 "Level 10", ENG §7.2): its 31 refused records — the same literal list as
    /// `HorizonStripSetupTests.level10` (the Render target cannot see a Core test's list). Never computed from what the
    /// port refuses today; 6A-WD reuses it unchanged.
    static let level10: [LevelFixture.LeaveOut] = [
        // The trees (6A-TR): 3080 ×2, 3081 ×4, 3082 ×4, 3083 ×3.
        .type(3080), .type(3081), .type(3082), .type(3083),
        // The Box scenery (6A-BX1a): 2816 ×5, 2817, 2837 ×3, 2846 ×2, 2847 ×2, 2861.
        .type(2816), .type(2817), .type(2837), .type(2846), .type(2847), .type(2861),
        // The rotating cannons (6A-RC): 1097 ×1, and the 1090 records 89 (p1 101), 200 and 250 (p1 103).
        .type(1097), .record(89), .record(200), .record(250),
    ]

    /// The fixture's player start for the frame tests (`LevelRun`'s `start:` override — the fixture's own parameter).
    /// At the header's start (54, 838) the player stands in a closed cave at the map's left edge and the strip's rows
    /// (screen y 454 − (V·56 >> 8), V ≈ 630) fall behind solid tiles: no strip pixel reaches the screen in 6,000 idle
    /// ticks. At (600, 1150) — open air in the same left part of the map (tile column 18, row 35) — the first view's
    /// strip rows cross open sky.
    static let stripStart = (x: 600, y: 1150)

    /// The test colour model (`LevelFixtureServices.prepare`'s).
    static let search = ColorSearch(model: .ruled, tieBreak: .lowest)

    private func base() throws -> FerazelResources { try LevelFixture.base.get() }

    private func at(_ port: [UInt8], _ v: Int, _ h: Int) -> UInt8 { port[v * FramePorts.width + h] }

    // MARK: - Core records on the six levels

    func testStripCopiesPerLevel() throws {
        let r = try base()
        let face = { (p: Int16) in FaceRef(pict: p, index: 0, set: .backgroundsSingle) }
        // (level, PICT, x factor, y, PxBack y factor, sprites, the CLUT the face converts under)
        let rows: [(Int, Int16, Int16, Int16, Int16, Int, Int16)] = [
            (10, 265, 128, 222, 56, 9, 200), (30, 275, 128, 227, 136, 12, 200), (40, 315, 128, 48, 22, 12, 200),
            (45, 315, 128, 48, 10, 3, 200), (62, 345, 128, 116, 43, 9, 240), (67, 385, 128, 16, 256, 2, 200),
        ]
        for (level, pict, fx, y, yb, count, clut) in rows {
            let file = try LevelFile.load(from: r, level: Int16(level))
            let h = file.header
            XCTAssertEqual([h.stripPict, h.stripFactor, h.stripBaseY, h.pxBackYFactor], [pict, fx, y, yb], "L\(level)")
            XCTAssertEqual(h.omniPxMode, 0, "L\(level): `.SetupOmniPx` returns before its CLUT store (M l. 13172)")
            let w = SpriteWorld(level: file)
            let made = PxSprites.create(header: h, resources: r, clut: PxSprites.setupLevelClut, world: w)
            XCTAssertEqual(made.ids, Array(1...count), "L\(level)")
            XCTAssertEqual(made.outcome, .added(faceClut: clut), "L\(level)")
            XCTAssertEqual(made.table.spriteCount, Int16(count))
            XCTAssertEqual(made.table.faceCount, 1)
            XCTAssertEqual(made.table.faces[0], face(pict))
            // Entry = count + k with the count already advanced (M l. 30904): every other entry.
            XCTAssertEqual(made.table.sprites, (0..<32).map { $0 % 2 == 0 && $0 / 2 < count ? $0 / 2 + 1 : nil }, "L\(level)")
            XCTAssertEqual(w.active.sprites.map(\.id), Array(1...count))
            for (k, id) in made.ids.enumerated() {
                let s = try XCTUnwrap(w.active.record(id: id))
                XCTAssertEqual([s.classTimer, s.classWord150, s.classWord154, s.classWord158],
                               [Int32(768 * k), Int32(y), Int32(fx), Int32(yb)], "L\(level) sprite \(k)")
                XCTAssertEqual(s.face, face(pict))
                XCTAssertEqual(s.layer, -500)
                XCTAssertEqual(s.mode, 0x80000)
            }
            // All six PICTs are in the Backgrounds file.
            XCTAssertNotNil(r.backgrounds.resource(type: "PICT", id: pict), "L\(level)")
        }
        // Level 10's count is what `setupLevel` makes on the fixture (headless, through `LevelRun`).
        let run = try LevelFixture.open(level: 10, leaveOut: Self.level10)
        var now: UInt32 = 0
        while run.session == nil && now < 2000 { _ = try run.tick(now: now, input: FrontInput()); now += 1 }
        XCTAssertEqual(try XCTUnwrap(run.session).horizonStrip.ids.count, 9)

        // Levels 1–5 (the switch-off check): header 0x2716 = 0 — no add, no sprite, no face, no `.backgroundsSingle`.
        for level in 1...5 {
            let file = try LevelFile.load(from: r, level: Int16(level))
            XCTAssertEqual(file.header.stripPict, 0, "L\(level)")
            let w = SpriteWorld(level: file)
            let made = PxSprites.create(header: file.header, resources: r, clut: 200, world: w)
            XCTAssertNil(made.outcome)
            XCTAssertEqual(made.table, PxSprites.Table())
            XCTAssertTrue(w.active.sprites.isEmpty)
        }

        // The asserts the build adds (ENG §2.1): the whole add skipped at face count ≥ 31 (M l. 30884) — no sprite, no
        // face, no CLUT swap (level 62's header, which would swap).
        let l10 = try LevelFile.load(from: r, level: 10), l62 = try LevelFile.load(from: r, level: 62)
        for (file, faces) in [(l10, Int16(31)), (l62, 31), (l62, 40)] {
            var t = PxSprites.Table()
            t.faceCount = faces
            var clut: Int16 = 200
            let w = SpriteWorld(level: file)
            XCTAssertEqual(t.add(pict: file.header.stripPict, fx: 128, y: 1, header: file.header,
                                 resources: r, clut: &clut, world: w), .skipped)
            XCTAssertEqual(clut, 200)
            XCTAssertTrue(w.active.sprites.isEmpty)
            XCTAssertEqual(t.spriteCount, 0)
            XCTAssertEqual(t.faceCount, faces)
        }
        var t30 = PxSprites.Table()
        t30.faceCount = 30
        var c30: Int16 = 200
        XCTAssertEqual(t30.add(pict: 265, fx: 128, y: 222, header: l10.header, resources: r, clut: &c30,
                               world: SpriteWorld(level: l10)), .added(faceClut: 200))
        XCTAssertEqual(t30.faceCount, 31)
        XCTAssertEqual(t30.faces[30], face(265))
        // The cap min(N, 31 − count) re-read each pass, the entry count + k (M l. 30897–30904): from a count of 25,
        // N = 8 makes k = 0…3 (cap 6, 5, 4, 3) at entries 25, 27, 29, 31; the count ends at 29.
        var t25 = PxSprites.Table()
        t25.spriteCount = 25
        var c25: Int16 = 200
        let w25 = SpriteWorld(level: l10)
        XCTAssertEqual(t25.add(pict: 265, fx: 128, y: 222, header: l10.header, resources: r, clut: &c25,
                               world: w25), .added(faceClut: 200))
        XCTAssertEqual(t25.spriteCount, 29)
        XCTAssertEqual(t25.sprites.indices.filter { t25.sprites[$0] != nil }, [25, 27, 29, 31])
        XCTAssertEqual(w25.active.sprites.map(\.classTimer), [0, 768, 1536, 2304])
        // From an even count (24) the cap's 31 shows: k = 0…3 (cap 7, 6, 5, 4 → k = 4 fails 3 < 4) at entries 24 … 30,
        // the count 28 (a cap of 32 would make a fifth copy, count 29).
        var t24 = PxSprites.Table()
        t24.spriteCount = 24
        var c24: Int16 = 200
        XCTAssertEqual(t24.add(pict: 265, fx: 128, y: 222, header: l10.header, resources: r, clut: &c24,
                               world: SpriteWorld(level: l10)), .added(faceClut: 200))
        XCTAssertEqual(t24.spriteCount, 28)
        XCTAssertEqual(t24.sprites.indices.filter { t24.sprites[$0] != nil }, [24, 26, 28, 30])
        // `+0x150` and `+0x154` are the routine's arguments (`.SetupLevel` passes hdr 0x271a / 0x2718), not header reads:
        // fx 64, y 7 → N = ⌊((64·360·32) >> 8) / 768⌋ + 1 = 4, five copies, each (7, 64).
        var targ = PxSprites.Table()
        var carg: Int16 = 200
        let warg = SpriteWorld(level: l10)
        _ = targ.add(pict: 265, fx: 64, y: 7, header: l10.header, resources: r, clut: &carg, world: warg)
        XCTAssertEqual(warg.active.sprites.map { [$0.classWord150, $0.classWord154] }, Array(repeating: [7, 64], count: 5))
        // A failed spawn (`.MTNewSprite` finds no record) still advances the count (M l. 30917): 697 records in use →
        // three copies made, six refused, the count 9, entries 0, 2, 4 set and 6 … 16 left 0.
        let full = SpriteWorld(level: l10)
        for _ in 0..<697 { full.newSprite(type: 1, x: 0, y: 0, layer: 0, handler: .inert) }
        let partial = PxSprites.create(header: l10.header, resources: r, clut: 200, world: full)
        XCTAssertEqual(partial.table.spriteCount, 9)
        XCTAssertEqual(partial.table.sprites.indices.filter { partial.table.sprites[$0] != nil }, [0, 2, 4])
        XCTAssertEqual(full.refusedSpawns, 6)
        XCTAssertEqual(partial.outcome, .added(faceClut: 200))
        // `.MTKillPxSprites` first: a table that held sprites kills them and starts again from 0.
        let again = PxSprites.create(header: l10.header, resources: r, clut: 200, world: full,
                                     table: partial.table)
        XCTAssertEqual(again.table.spriteCount, 9)
        XCTAssertEqual(again.table.faceCount, 1)
        for id in partial.ids { XCTAssertNil(full.active.sprite(id: id)) }
    }

    func testHandlePxSpriteRunsTwice() throws {
        let res = try LevelFixture.resources(level: 10, leaveOut: Self.level10)
        let s = try FerazelSession(resources: res, prefs: FerazelPrefs(), level: 10, hostedByLevelRun: true)
        let ids = s.horizonStrip.ids
        XCTAssertEqual(ids.count, 9)
        func expected(_ id: Int, h: Int, v: Int) throws -> (Int, Int) {
            let r = try XCTUnwrap(s.world.active.record(id: id))
            let p = PxSprites.Sprite(x0: Int(r.classTimer), y0: Int(r.classWord150), fx: Int(r.classWord154),
                                     fy: Int(r.classWord158)).position(h: h, v: v)
            return (p.x, p.y)
        }
        func positions() -> [[Int]] {
            ids.map { id in s.world.active.record(id: id).map { [$0.x, $0.y] } ?? [Int.min, Int.min] }
        }
        func garble() { for id in ids { s.world.active.update(id: id) { $0.x = -1234; $0.y = -4321 } } }
        // At creation `.MTNewSprite`'s pixel copies (x into +0xc then y over it, +0xa untouched): (0, 0).
        XCTAssertEqual(positions(), Array(repeating: [0, 0], count: 9))
        // The camera pass: `.FindUpperLeftCorner` (here the level start's) ends with `.MTHandlePxSprites` (M l. 6235)
        // — every strip sprite at the new scroll point, before any sprite pass.
        garble()
        _ = s.startOps()
        XCTAssertEqual(positions(), try ids.map { try expected($0, h: s.camera.scrollH, v: s.camera.scrollV) }.map { [$0.0, $0.1] })
        XCTAssertNotEqual(positions()[1], [-1234, -4321])
        // The sprite pass: with the strip table emptied (so the camera pass reaches nothing) one iteration still moves
        // them — `.HandlePxSprite` is each strip sprite's Handle in `.MTHandleSprites`.
        let table = s.horizonStrip.table
        s.horizonStrip.table = PxSprites.Table()
        garble()
        _ = s.step(keys: KeyState())
        XCTAssertEqual(positions(), try ids.map { try expected($0, h: s.camera.scrollH, v: s.camera.scrollV) }.map { [$0.0, $0.1] })
        s.horizonStrip.table = table
        // Both in one iteration, the second wins: the sprite pass at one scroll, then the camera pass at another.
        for id in ids { PxSprites.handle(world: s.world, id: id, h: 100, v: 50) }
        XCTAssertEqual(positions(), try ids.map { try expected($0, h: 100, v: 50) }.map { [$0.0, $0.1] })
        PxSprites.handleAll(world: s.world, table: table, h: 300, v: 80)
        XCTAssertEqual(positions(), try ids.map { try expected($0, h: 300, v: 80) }.map { [$0.0, $0.1] })
        // Copy k: x = 768k − (300·128 >> 8) + 300 = 768k + 150; y = 222 − (80·56 >> 8) + 80 + 232 = 517.
        XCTAssertEqual(positions().map { $0[0] }, (0..<9).map { 768 * $0 + 150 })
        XCTAssertEqual(Set(positions().map { $0[1] }), [517])
        // The camera pass skips an entry whose record's Handle `+0x4c` is 0.
        s.world.active.update(id: ids[0]) { $0.handleCleared = true }
        PxSprites.handleAll(world: s.world, table: table, h: 0, v: 0)
        XCTAssertEqual(positions()[0], [150, 517])
        XCTAssertEqual(positions()[1], [768, 454])
    }

    // MARK: - The face: the Backgrounds file, the colour table

    /// Backgrounds PICT `pict` through `.Load1EncFaceFromPICT` under clut `clut` (the test colour model).
    private func backgroundsFace(_ pict: Int16, clut: Int16, file: ResourceCollection? = nil) throws -> EncodedFace {
        let r = try base()
        let res = try XCTUnwrap((file ?? r.backgrounds).resource(type: "PICT", id: pict))
        let picture = try ConvertedPicture(source: try PictureSource(resource: res),
                                           clut: try ColorLUT.load(id: clut, from: r, chain: .level),
                                           search: Self.search, dither: .errorDiffusion)
        return try FaceSheet(picture: picture, loader: .single(pict: pict)).faces[0]
    }

    func testStripFaceUsesBackgroundsFile() throws {
        let r = try base()
        let (_, services) = try LevelFixtureServices.open(level: 10, leaveOut: Self.level10)
        _ = try services.prepare(level: 10)
        let renderer = try XCTUnwrap(services.renderer)
        let strip = try XCTUnwrap(renderer.sprites.faces.face(FaceRef(pict: 265, index: 0, set: .backgroundsSingle)))
        // The Backgrounds file's PICT 265, converted under clut 200 (`*_DAT_1009ff94` = `*_DAT_100a0020` =
        // `GetCTable(200)`, M l. 2273, 404–405) — not under the level+base CLUT `*_DAT_1009ff8c` (214 on level 10).
        XCTAssertEqual(ColorLUT.screenClutId(renderer.level.header), 214)
        XCTAssertEqual(strip, try backgroundsFace(265, clut: 200))
        XCTAssertNotEqual(strip.data, try backgroundsFace(265, clut: 214).data)
        XCTAssertEqual(PxSprites.faceClut(header: renderer.level.header, pointer: PxSprites.setupLevelClut), 200)
        // The Sprites file also holds a PICT 265 — byte for byte the same resource (measured; ENG §2.1 expected another
        // picture), so on level 10 the two loaders would agree; the other five strip PICTs exist only in the
        // Backgrounds file, where `.MTAddPxSprite` reads them (a Sprites-chain `.encoded` load would find none).
        XCTAssertEqual(try XCTUnwrap(r.sprites.resource(type: "PICT", id: 265)).data,
                       try XCTUnwrap(r.backgrounds.resource(type: "PICT", id: 265)).data)
        for p: Int16 in [275, 315, 345, 385] {
            XCTAssertNil(r.resource(type: "PICT", id: p, chain: .frontEnd), "PICT \(p) on the Sprites chain")
            XCTAssertNotNil(r.backgrounds.resource(type: "PICT", id: p))
        }
        XCTAssertEqual([strip.width, strip.height], [768, 30])
        // `.encoded` 265 is not the strip's face: no sheet of level 10 loads PICT 265 (the store keys the strip single
        // apart, so it is never served for an `.encoded` ref).
        XCTAssertNil(renderer.sprites.faces.face(FaceRef(pict: 265, index: 0, set: .encoded)))
        // The face bounds Core is handed read the same face.
        let b = renderer.faceBounds(FaceRef(pict: 265, index: 0, set: .backgroundsSingle))
        XCTAssertEqual([b.top, b.left, b.bottom, b.right],
                       [Int(strip.bounds.top), Int(strip.bounds.left), Int(strip.bounds.bottom), Int(strip.bounds.right)])
    }

    func testStripFaceClutOnLevel62() throws {
        let r = try base()
        let l62 = try LevelFile.load(from: r, level: 62)
        let h = l62.header
        XCTAssertEqual(h.pxUsesLevelBaseClut, 1)
        XCTAssertEqual(ColorLUT.screenClutId(h), 240)
        // From the header alone: the face converts under the level+base CLUT (header `0x26cc` ≠ 0, M l. 30885–30886).
        let made = PxSprites.create(header: h, resources: r, clut: PxSprites.setupLevelClut,
                                    world: SpriteWorld(level: l62))
        XCTAssertEqual(made.outcome, .added(faceClut: 240))
        XCTAssertEqual(made.ids.count, 9)
        // `*_DAT_1009ff94` swapped for the load and restored after it (M l. 30886, 30919).
        var t62 = PxSprites.Table()
        var c62: Int16 = 200
        XCTAssertEqual(t62.add(pict: 345, fx: 128, y: 116, header: h, resources: r, clut: &c62,
                               world: SpriteWorld(level: l62)), .added(faceClut: 240))
        XCTAssertEqual(c62, 200, "restored")
        XCTAssertEqual(PxSprites.faceClut(header: h, pointer: 200), 240)
        let face = try XCTUnwrap(FrameRenderer.stripFace(level: l62, resources: r, search: Self.search,
                                                         dither: .errorDiffusion)).faces[0]
        XCTAssertEqual(face, try backgroundsFace(345, clut: 240))
        XCTAssertNotEqual(face.data, try backgroundsFace(345, clut: 200).data)

        // A face that does not load (the PICT absent from every file of the chain `GetPicture` searches):
        // `.ReportError(…, 0)` and nothing else (M l. 30888–30891) — no sprite, no face entry, and the pointer left
        // swapped to the level+base CLUT (the restore of M l. 30919 is in the success branch). The renderer loads no
        // face for it either.
        let missing: Int16 = 0x7ff0
        XCTAssertNil(PxSprites.facePicture(missing, resources: r))
        XCTAssertNil(r.resource(type: "PICT", id: missing, chain: .level))
        let mlvl = try XCTUnwrap(r.world.resource(type: "Mlvl", id: 62))
        var d = mlvl.data
        d[d.startIndex + 0x2716] = UInt8(missing >> 8)
        d[d.startIndex + 0x2717] = UInt8(missing & 0xff)
        let patched = try LevelFile(id: 62, data: d)
        let w = SpriteWorld(level: patched)
        let failed = PxSprites.create(header: patched.header, resources: r, clut: 200, world: w)
        XCTAssertEqual(failed.outcome, .faceLoadFailed)
        XCTAssertNil(failed.faceClut)
        XCTAssertEqual(failed.table, PxSprites.Table())
        XCTAssertTrue(w.active.sprites.isEmpty)
        var tf = PxSprites.Table()
        var cf: Int16 = 200
        XCTAssertEqual(tf.add(pict: missing, fx: 128, y: 116, header: patched.header, resources: r, clut: &cf,
                              world: SpriteWorld(level: patched)), .faceLoadFailed)
        XCTAssertEqual(cf, 240, "left swapped, as written")
        XCTAssertNil(try FrameRenderer.stripFace(level: patched, resources: r, search: Self.search, dither: .errorDiffusion))
        // On a `0x26cc` = 0 level the failed load leaves the pointer as it was.
        let mlvl10 = try XCTUnwrap(r.world.resource(type: "Mlvl", id: 10))
        var d10 = mlvl10.data
        d10[d10.startIndex + 0x2716] = UInt8(missing >> 8)
        d10[d10.startIndex + 0x2717] = UInt8(missing & 0xff)
        let p10 = try LevelFile(id: 10, data: d10)
        var t10 = PxSprites.Table()
        var c10: Int16 = 200
        XCTAssertEqual(t10.add(pict: missing, fx: 128, y: 222, header: p10.header, resources: r, clut: &c10,
                               world: SpriteWorld(level: p10)), .faceLoadFailed)
        XCTAssertEqual(c10, 200)

        // `GetPicture` searches down the chain (M l. 28038): a PICT the Backgrounds file lacks is found in the next
        // file — PICT 5000 is the Sprites file's only. Core makes the strip and the renderer loads the Sprites picture
        // (under clut 200, header `0x26cc` = 0 on level 10).
        let other: Int16 = 5000
        XCTAssertNil(r.backgrounds.resource(type: "PICT", id: other))
        XCTAssertNotNil(r.sprites.resource(type: "PICT", id: other))
        d10[d10.startIndex + 0x2716] = UInt8(other >> 8)
        d10[d10.startIndex + 0x2717] = UInt8(other & 0xff)
        let s10 = try LevelFile(id: 10, data: d10)
        let found = PxSprites.create(header: s10.header, resources: r, clut: 200, world: SpriteWorld(level: s10))
        XCTAssertEqual(found.outcome, .added(faceClut: 200))
        XCTAssertEqual(found.ids, Array(1...9))
        let sFace = try XCTUnwrap(FrameRenderer.stripFace(level: s10, resources: r, search: Self.search,
                                                          dither: .errorDiffusion)).faces[0]
        XCTAssertEqual(sFace, try backgroundsFace(other, clut: 200, file: r.sprites))
    }

    // MARK: - Draw mode 8 (synthetic faces)

    private enum Tok { case skip(Int), copy([UInt8]), bad(UInt8) }

    /// A face of `rows` (each row's token stream; the row token's payload is the row's byte length), `width` wide.
    private func face(_ rows: [[Tok]], width: Int) -> EncodedFace {
        func u32(_ op: UInt8, _ n: Int) -> [UInt8] { [op, UInt8(n >> 16 & 0xff), UInt8(n >> 8 & 0xff), UInt8(n & 0xff)] }
        var d: [UInt8] = []
        for row in rows {
            var body: [UInt8] = []
            for t in row {
                switch t {
                case .skip(let n): body += u32(3, n)
                case .copy(let b): body += u32(2, b.count) + b + [UInt8](repeating: 0, count: (4 - b.count & 3) & 3)
                case .bad(let op): body += u32(op, 0)
                }
            }
            d += u32(1, body.count) + body
        }
        d += u32(0, 0)
        let rect = EncodedFace.Rect(top: 0, left: 0, bottom: Int16(rows.count), right: Int16(width))
        return EncodedFace(frame: rect, bounds: rect, data: d, hasTransparentPixel: true, sourceId: 9100)
    }

    /// Ports with `frame` / `mask` bytes written at row `v`, columns `h…`.
    private func ports(frame: [(Int, Int, [UInt8])], mask: [(Int, Int, [UInt8])], fill: UInt8 = 0x55,
                       maskFill: UInt8 = 0xff) -> FramePorts {
        var p = FramePorts(fill: fill)
        p.mask = [UInt8](repeating: maskFill, count: p.mask.count)
        for (v, h, b) in frame { for (k, x) in b.enumerated() { p.frame[v * FramePorts.width + h + k] = x } }
        for (v, h, b) in mask { for (k, x) in b.enumerated() { p.mask[v * FramePorts.width + h + k] = x } }
        return p
    }

    private func row(_ p: [UInt8], _ v: Int, _ h: Int, _ n: Int) -> [UInt8] {
        Array(p[(v * FramePorts.width + h)..<(v * FramePorts.width + h + n)])
    }

    func testModeEightWordAddCarries() throws {
        let f = face([[.copy([0, 0, 0, 1, 0x10, 0x20, 0x30, 0x40])], [.copy([0x80, 0, 0, 0])], [.copy([9, 9, 9, 9])]],
                     width: 8)
        for clip in [false, true] {
            var p = ports(frame: [(10, 100, [0x00, 0x01, 0xff, 0xff, 0x01, 0x02, 0x03, 0x04]), (11, 100, [0x80, 0, 0, 0]),
                                  (12, 100, [1, 2, 3, 4])],
                          mask: [(10, 104, [0xff, 0, 0xff, 0]), (12, 100, [0, 0, 0, 0])])
            SpriteBlitter.behindTilesWalk(f, src: (0, 0), dst: (10, 100), w: 8, h: 3, clip: clip, frame: &p.frame,
                                          mask: p.mask)
            // A 32-bit big-endian add where the mask word ≠ 0: 0x0001ffff + 0x00000001 = 0x00020000 (the carry crosses
            // two bytes); 0x01020304 + (0x10203040 & 0xff00ff00) = 0x11023304.
            XCTAssertEqual(row(p.frame, 10, 100, 8), [0x00, 0x02, 0x00, 0x00, 0x11, 0x02, 0x33, 0x04], "clip \(clip)")
            // The carry out of the top byte is lost: 0x80000000 + 0x80000000 = 0.
            XCTAssertEqual(row(p.frame, 11, 100, 4), [0, 0, 0, 0], "clip \(clip)")
            // Mask word 0: the frame word is left alone.
            XCTAssertEqual(row(p.frame, 12, 100, 4), [1, 2, 3, 4], "clip \(clip)")
            // Nothing else moved, and the walk never writes the mask.
            XCTAssertEqual(row(p.frame, 10, 96, 4), [0x55, 0x55, 0x55, 0x55])
            XCTAssertEqual(row(p.frame, 10, 108, 4), [0x55, 0x55, 0x55, 0x55])
        }
        // The add equals a copy only where the frame byte is 0 under a 0xff mask byte.
        var z = ports(frame: [(20, 0, [0, 0, 0, 0])], mask: [])
        SpriteBlitter.behindTilesWalk(face([[.copy([0xde, 0xad, 0xbe, 0xef])]], width: 4), src: (0, 0), dst: (20, 0),
                                      w: 4, h: 1, clip: false, frame: &z.frame, mask: z.mask)
        XCTAssertEqual(row(z.frame, 20, 0, 4), [0xde, 0xad, 0xbe, 0xef])
    }

    func testModeEightTailBytes() throws {
        let f = face([[.copy([1, 1, 1, 1, 0x00, 0x01, 0x05])],
                      [.copy([7, 8, 9])],
                      [.copy([0x42]), .skip(1), .copy([0x43])],
                      [.copy([9, 9, 9, 9]), .bad(4), .copy([9])],
                      [.copy([0x77, 0x77, 0x77, 0x77])]], width: 7)
        for clip in [false, true] {
            var p = ports(frame: [(30, 50, [0, 0, 0, 0, 0xff, 0xff, 0x10]), (31, 50, [1, 1, 1]), (32, 50, [0x10, 0x10, 0x10]),
                                  (33, 50, [0, 0, 0, 0, 0]), (34, 50, [0, 0, 0, 0])],
                          mask: [(31, 50, [0, 0xff, 0]), (32, 50, [0, 0xff, 0xff])])
            SpriteBlitter.behindTilesWalk(f, src: (0, 0), dst: (30, 50), w: 7, h: 5, clip: clip, frame: &p.frame,
                                          mask: p.mask)
            // One group, then the 2-byte tail on 16 bits (0xffff + 0x0001 wraps to 0 — no carry into the group before),
            // then the last byte **copied** (0x05, not 0x10 + 0x05) under a non-zero mask byte.
            XCTAssertEqual(row(p.frame, 30, 50, 7), [1, 1, 1, 1, 0, 0, 0x05], "clip \(clip)")
            // A 3-byte run: the tail's mask half-word 0x00ff ≠ 0 → 0x0101 + (0x0708 & 0x00ff) = 0x0109; the last byte's
            // mask is 0 → left.
            XCTAssertEqual(row(p.frame, 31, 50, 3), [1, 9, 1], "clip \(clip)")
            // A 1-byte run under a 0 mask byte is left; after the skip, under 0xff, copied.
            XCTAssertEqual(row(p.frame, 32, 50, 3), [0x10, 0x10, 0x43], "clip \(clip)")
            // A token > 3: `DebugStr` and return (M l. 22357 clipped, 22544 unclipped) — the row's draws before it
            // stay, nothing after it is drawn.
            XCTAssertEqual(row(p.frame, 33, 50, 5), [9, 9, 9, 9, 0], "clip \(clip)")
            XCTAssertEqual(row(p.frame, 34, 50, 4), [0, 0, 0, 0], "clip \(clip)")
        }
    }

    func testModeEightClipped() throws {
        let W = FramePorts.width
        // Left and top clip: dst (−1, −3) → source row 1, column 3 at port (0, 0). Face row 0 is past the top clip:
        // skipped by its row token's payload.
        let ramp = (1...10).map { UInt8($0) }
        let f = face([[.copy([0xee, 0xee, 0xee, 0xee])],
                      [.copy(ramp)],
                      [.copy(Array(repeating: 1, count: 10))],
                      [.copy([0x21, 0x22, 0x23, 0x24, 0x25, 0x26, 0x27, 0x28, 0x29, 0x2a])],
                      [.copy([0xaa, 0xbb]), .skip(1), .copy([0x31, 0x32, 0x33, 0x34])]], width: 10)
        var p = ports(frame: [(1, 0, Array(repeating: 0xff, count: 10))], mask: [], fill: 0)
        SpriteBlitter.behindTilesWalk(f, src: (0, 0), dst: (-1, -3), w: 10, h: 5, clip: true, frame: &p.frame,
                                      mask: p.mask)
        // A run crossing the left clip starts at the clip column: dest, mask and source advanced by 3.
        XCTAssertEqual(row(p.frame, 0, 0, 8), [4, 5, 6, 7, 8, 9, 10, 0])
        // ... and **groups from the clip column**: 0xffffffff + 0x01010101 = 0x01010100, then the 2-byte tail
        // 0xffff + 0x0101 = 0x0100, then the last byte copied. (Grouped from the run start, column 3 would be the
        // last byte of a group — 0x00 — instead.)
        XCTAssertEqual(row(p.frame, 1, 0, 8), [1, 1, 1, 0, 1, 0, 1, 0xff])
        // The source pad uses the full run length (10 → 2), so the next row reads aligned.
        XCTAssertEqual(row(p.frame, 2, 0, 8), [0x24, 0x25, 0x26, 0x27, 0x28, 0x29, 0x2a, 0])
        // A run wholly left of the clip is skipped (its pad included); the next run draws from its own start.
        XCTAssertEqual(row(p.frame, 3, 0, 5), [0x31, 0x32, 0x33, 0x34, 0])
        XCTAssertEqual(row(p.frame, 4, 0, 4), [0, 0, 0, 0], "no row past the face")
        XCTAssertFalse(p.frame.contains(0xee), "the clipped-off top row is never drawn")
        XCTAssertFalse(p.frame.contains(0xaa) || p.frame.contains(0xbb))

        // Right and bottom clip: an 11-pixel run at column 634 draws columns 0…5 (a group and a 2-byte tail), skips
        // the overhang after the tails, pads by the full run (11 → 1); a run wholly past the right limit is skipped;
        // rows past the port's bottom are never reached.
        let g = face([[.copy((1...11).map { UInt8($0) })],
                      [.copy([0x51, 0x52])],
                      [.skip(7), .copy([0x61, 0x62]), .skip(1)],
                      [.copy([0x71])]], width: 11)
        var q = ports(frame: [], mask: [], fill: 0)
        SpriteBlitter.behindTilesWalk(g, src: (0, 0), dst: (413, 634), w: 11, h: 4, clip: true, frame: &q.frame,
                                      mask: q.mask)
        XCTAssertEqual(row(q.frame, 413, 634, 6), [1, 2, 3, 4, 5, 6])
        XCTAssertEqual(row(q.frame, 414, 0, 4), [0, 0, 0, 0], "nothing spills into the next port row")
        XCTAssertEqual(row(q.frame, 414, 634, 6), [0x51, 0x52, 0, 0, 0, 0])
        XCTAssertEqual(row(q.frame, 415, 634, 6), [0, 0, 0, 0, 0, 0], "a run wholly past the right limit")
        XCTAssertEqual(q.frame.filter { $0 != 0 }.count, 8, "row 3 is below the port (416 rows)")
        XCTAssertEqual(q.frame.count, W * FramePorts.height)

        // One run crossing BOTH edges (dst h −3, a 6-column window: left clip 3, right limit 6): columns 3…5 drawn, the
        // overhang skipped, the source padded by the full run (10 → 2), so the next row reads aligned.
        let k = face([[.copy((1...10).map { UInt8($0) })], [.copy([0x21, 0x22, 0x23, 0x24])]], width: 10)
        var e = ports(frame: [], mask: [], fill: 0)
        SpriteBlitter.behindTilesWalk(k, src: (0, 0), dst: (50, -3), w: 6, h: 2, clip: true, frame: &e.frame, mask: e.mask)
        XCTAssertEqual(row(e.frame, 50, 0, 4), [4, 5, 6, 0])
        XCTAssertEqual(row(e.frame, 51, 0, 4), [0x24, 0, 0, 0])
        // The port's last row (415) is drawn; the row below it is not reached.
        let last = face(Array(repeating: [Tok.copy([0x61, 0x62])], count: 3), width: 2)
        var lp = ports(frame: [], mask: [], fill: 0)
        SpriteBlitter.behindTilesWalk(last, src: (0, 0), dst: (414, 10), w: 2, h: 3, clip: true, frame: &lp.frame,
                                      mask: lp.mask)
        XCTAssertEqual(row(lp.frame, 414, 10, 2), [0x61, 0x62])
        XCTAssertEqual(row(lp.frame, 415, 10, 2), [0x61, 0x62])
        XCTAssertEqual(lp.frame.filter { $0 != 0 }.count, 4)
    }

    func testModeEightMaskPassZeroes() throws {
        let f = try TileGridTests.Fixture()
        // A 6×4 face: pixel (r, c) = 0x20 + 6r + c, (0, 0) and (2, 5) transparent.
        let w = 6, h = 4
        let px = (0..<h).flatMap { r in (0..<w).map { c in [(0, 0), (2, 5)].contains { $0 == (r, c) } ? 0 : UInt8(0x20 + 6 * r + c) } }
        let face = try FaceEncoder.encode(pixels: px, width: w, height: h,
                                          rect: EncodedFace.Rect(top: 0, left: 0, bottom: Int16(h), right: Int16(w)),
                                          sourceId: 9102)
        let b = SpriteBlitter(level: f.level, tables: f.tables, faces: SpriteBlitter.Faces(sheets: [:]), effects: 3)
        var outs: [Bool: FramePorts] = [:]
        for flip in [false, true] {
            var p = FramePorts(fill: 0)
            p.mask = [UInt8](repeating: 0xff, count: p.mask.count)
            p.mask[201 * FramePorts.width + 102] = 0                     // a tile already drawn under face (1, 2)
            try b.blitEncFaceX(face, src: (0, 0), dst: (200, 100), w: w, h: h, word: 0x80000, flip: flip, rotation: 0,
                               scale: 0x100, ports: &p)
            outs[flip] = p
        }
        let plain = try XCTUnwrap(outs[false]), mirrored = try XCTUnwrap(outs[true])
        for r in 0..<h {
            for c in 0..<w {
                let o = (200 + r) * FramePorts.width + 100 + c
                let src = px[r * w + c]
                // The colour pass: the add into a 0 frame under 0xff (a copy), nothing under the drawn tile.
                XCTAssertEqual(plain.frame[o], (r, c) == (1, 2) ? 0 : src, "(\(r), \(c))")
                // The mask pass: 0 under the silhouette (mode < 0x14, ≠ 0xd), 0xff elsewhere.
                XCTAssertEqual(plain.mask[o], src != 0 || (r, c) == (1, 2) ? 0 : 0xff, "(\(r), \(c))")
                // Mode 8 ignores the mirror flag (raw `1002cf5c..1002cfa4`): the colour pass is the same flipped; the
                // mask pass that follows does flip (`.BlitEncBoolFaceFlipNoClip`, as written).
                XCTAssertEqual(mirrored.frame[o], plain.frame[o], "(\(r), \(c)) flipped colour")
                let m = px[r * w + (w - 1 - c)]
                XCTAssertEqual(mirrored.mask[o], m != 0 || (r, c) == (1, 2) ? 0 : 0xff, "(\(r), \(c)) flipped mask")
            }
        }
        // The clipped variant (the face past the left edge) masks the same way.
        var p = FramePorts(fill: 0)
        p.mask = [UInt8](repeating: 0xff, count: p.mask.count)
        try b.blitEncFaceX(face, src: (0, 0), dst: (10, -2), w: w, h: h, word: 0x80000, flip: false, rotation: 0,
                           scale: 0x100, ports: &p)
        XCTAssertEqual(row(p.frame, 11, 0, 4), [0x28, 0x29, 0x2a, 0x2b])
        XCTAssertEqual(row(p.mask, 11, 0, 4), [0, 0, 0, 0])
        XCTAssertEqual(row(p.mask, 10, 0, 4), [0, 0, 0, 0])
        XCTAssertEqual(row(p.mask, 12, 0, 5), [0, 0, 0, 0xff, 0xff])
    }

    // MARK: - The level-10 fixture's frame

    /// One fixture tick with its sprite pass split around the strip: the level draws up to `.wrapDrawSprites`, then
    /// `beforeSprites(ports)`, the strip's draws (the head of the list), `strip(frameBefore, frameAfter, scroll)`, the
    /// other sprites, the rest. Returns whether the tick presented a frame (as `LevelFixtureServices.step`).
    static func splitStep(_ run: LevelRun, _ services: LevelFixtureServices, now: UInt32,
                          beforeSprites: (FramePorts) -> Void = { _ in },
                          strip: ([UInt8], [UInt8], (h: Int, v: Int)) -> Void = { _, _, _ in }) throws -> Bool {
        let out = try run.tick(now: now, input: FrontInput())
        var presented = false
        for g in out.segments where g.target == .level {
            let r = try XCTUnwrap(services.renderer)
            var batch: [DrawOp] = []
            func flush() throws {
                if !batch.isEmpty { try r.apply(FrameOps(draws: batch)) }
                batch = []
            }
            for op in g.output.draws {
                guard case .wrapDrawSprites(let draws) = op else { batch.append(op); continue }
                try flush()
                beforeSprites(r.ports)
                let n = draws.prefix { $0.face.set == .backgroundsSingle }.count
                XCTAssertFalse(draws.dropFirst(n).contains { $0.face.set == .backgroundsSingle }, "the strip leads")
                let before = r.ports.frame
                try r.apply(FrameOps(draws: [.wrapDrawSprites(Array(draws.prefix(n)))]))
                strip(before, r.ports.frame, r.scroll)
                try r.apply(FrameOps(draws: [.wrapDrawSprites(Array(draws.dropFirst(n)))]))
            }
            try flush()
            presented = presented || g.output.draws.contains { if case .copyToScreen = $0 { return true }; return false }
        }
        return presented
    }

    /// Whether ring offset `o` of a frame port is inside the view at scroll (h, v) (608 × 384 from (h, v)).
    static func inView(_ o: Int, scroll: (h: Int, v: Int)) -> Bool {
        let rx = o % FramePorts.width, ry = o / FramePorts.width
        func mod(_ a: Int, _ m: Int) -> Int { let r = a % m; return r < 0 ? r + m : r }
        return mod(rx - scroll.h, FramePorts.width) < 0x260 && mod(ry - scroll.v, FramePorts.height) < 0x180
    }

    /// The first presented frame in which the strip changed a frame byte inside the view (`FeatureGoldenTests`'
    /// definition); every presented frame before it and it checked by `eachPresented(frameBeforeSprites, mask)`.
    static func firstStripFrame(_ run: LevelRun, _ services: LevelFixtureServices, limit: UInt32 = 6000,
                                eachPresented: (_ frame: [UInt8], _ mask: [UInt8]) -> Void = { _, _ in })
        throws -> (ticks: UInt32, fnv: UInt64, changed: Int) {
        var now: UInt32 = 0
        while now < limit {
            var pre: FramePorts?
            var changed = 0
            let presented = try splitStep(run, services, now: now, beforeSprites: { pre = $0 }) { a, b, scroll in
                for o in a.indices where a[o] != b[o] && inView(o, scroll: scroll) { changed += 1 }
            }
            now += 1
            guard presented, let p = pre else { continue }
            eachPresented(p.frame, p.mask)
            if changed > 0, let r = services.renderer {
                return (now, LevelFixtureServices.fnv1a(r.screen.pixels), changed)
            }
        }
        throw LevelFixtureServices.FrameFailure(now: now, description: "no strip pixel on screen within \(limit) ticks")
    }

    func testFrameIsZeroUnderOpenMaskOnLevel10() throws {
        let (run, services) = try LevelFixtureServices.open(level: 10, leaveOut: Self.level10, start: Self.stripStart)
        var frames = 0, open = 0, nonZero = 0
        _ = try Self.firstStripFrame(run, services) { frame, mask in
            frames += 1
            for o in frame.indices where mask[o] == 0xff {
                open += 1
                if frame[o] != 0 { nonZero += 1 }
            }
        }
        // Before every sprite pass up to the first one that puts a strip pixel on screen, every frame byte under a
        // 0xff mask byte is 0 — so there mode 8's add is a copy (draw-effects §2.5's inference, made checkable).
        XCTAssertGreaterThan(frames, 0)
        XCTAssertGreaterThan(open, 0)
        XCTAssertEqual(nonZero, 0)
    }
}
