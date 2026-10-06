import XCTest
@testable import DeimosCore
@testable import DeimosRender

/// A headless session: `DeimosSession` passes executed by a `DeimosRenderer` — fades stepped through all their
/// levels, `limit` ignored (no clock). When `DEIMOS_FRAME_DUMP` names a folder, the screen after the passes a test
/// marks (plus every 50th) is written to `<folder>/<label>/pass-NNNN.ppm` (binary P6, 8-bit `(c<<3)|(c>>2)`).
struct HeadlessRun {
    var session: DeimosSession
    let renderer: DeimosRenderer
    /// The index of the next pass (pass 0 is the first `pass` call; it carries the level-start ops).
    private(set) var next = 0
    let label: String
    let dumpPasses: Set<Int>

    init(label: String, dump: Set<Int> = [], seed: UInt32 = 0x469c2) throws {
        let assets = try ShippedAssets.get()
        session = try DeimosSession(assets: assets, prefs: .fresh,
                                    start: SessionStart(sector: 1, players: 1, film: nil), seed: seed)
        renderer = DeimosRenderer(assets: assets)
        self.label = label
        dumpPasses = dump
    }

    /// Run one pass. `fadeScreen` sees the screen after every fade step.
    @discardableResult
    mutating func pass(keys: HeldKeys = HeldKeys(), fadeScreen: ((Pixmap555) -> Void)? = nil) -> PassOutput {
        let out = session.pass(keys: keys)
        for op in out.ops { apply(op, fadeScreen: fadeScreen) }
        dumpIfAsked(next)
        next += 1
        return out
    }

    /// Run passes until `next == n + 1` (pass `n` done); returns the last pass's output.
    @discardableResult
    mutating func run(through n: Int, keys: (Int) -> HeldKeys = { _ in HeldKeys() }) -> PassOutput? {
        var last: PassOutput?
        while next <= n { last = pass(keys: keys(next)) }
        return last
    }

    func apply(_ op: RenderOp, fadeScreen: ((Pixmap555) -> Void)? = nil) {
        switch op {
        case let .fade(kind, present):
            renderer.fadeBegin(kind)
            let levels = kind == .fromBlack ? DisplayBuffers.fromBlackLevels : DisplayBuffers.toBlackLevels
            for a in levels {
                renderer.fadeStep(kind, a: a, present: present)
                fadeScreen?(renderer.screen)
            }
            renderer.fadeEnd()
        case .limit:
            break
        default:
            renderer.apply(op)
        }
    }

    private func dumpIfAsked(_ n: Int) {
        guard let folder = ProcessInfo.processInfo.environment["DEIMOS_FRAME_DUMP"], !folder.isEmpty,
              dumpPasses.contains(n) || n % 50 == 0 else { return }
        let dir = URL(fileURLWithPath: folder, isDirectory: true).appendingPathComponent(label, isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let s = renderer.screen
        var bytes = Array("P6\n\(s.width) \(s.height)\n255\n".utf8)
        bytes.reserveCapacity(bytes.count + 3 * s.pixels.count)
        for p in s.pixels {
            for c in [(p >> 10) & 31, (p >> 5) & 31, p & 31] { bytes.append(UInt8((c << 3) | (c >> 2))) }
        }
        try? Data(bytes).write(to: dir.appendingPathComponent(String(format: "pass-%04d.ppm", n)))
    }
}

/// FNV-1a 64 over the pixels, each as two bytes, low byte first.
func fnv1a64(_ p: Pixmap555) -> UInt64 {
    var h: UInt64 = 0xcbf2_9ce4_8422_2325
    for v in p.pixels {
        h = (h ^ UInt64(v & 0xff)) &* 0x0000_0100_0000_01b3
        h = (h ^ UInt64(v >> 8)) &* 0x0000_0100_0000_01b3
    }
    return h
}

/// The level-1 images straight from the decoders (independent of the renderer).
enum Level1Images {
    static func tga(_ id: String) -> Result<TGAImage, Error> {
        Result {
            let index = try ShippedAssets.get().index
            guard let r = index.record(type: FourCC("im16")!, id: FourCC(id)!) else {
                throw DeimosAssetsError.missingTag(type: "im16", id: id)
            }
            return try TGAImage(data: index.data(for: r))
        }
    }
    static let jum2 = tga("jum2")
    static let scor = tga("scor")
    static let pl1o: Result<SpriteGroup, Error> = Result { try ShippedAssets.get().spriteGroup(FourCC("pl1o")!) }
}

/// R3 — the level-1 frames: pixel oracles read from `jum2` / `scor` / `pl1o` directly, plus self-derived goldens
/// (plan R3; Verification model).
final class LevelOneFrameTests: XCTestCase {

    private static let gameClip = MacRect(top: 0, left: 0, bottom: 480, right: 416)
    private static let leftKey: UInt16 = 0x7B   // fresh prefs key table slot 1 (P1 left)

    private func draws(_ out: PassOutput) -> [DrawCommand] {
        out.ops.compactMap { if case let .draw(c) = $0 { return c } else { return nil } }
    }

    /// A generous back-buffer rect around a game-area sprite command (its frame size, unscaled, + 2 px).
    private func coverRect(_ c: DrawCommand, _ assets: DeimosAssets) throws -> MacRect {
        let f = try assets.spriteGroup(c.face).frames[c.frame]
        let hw = Int32(f.width) / 2 + 2, hh = Int32(f.height) / 2 + 2
        return MacRect(top: c.y - hh, left: c.x - hw, bottom: c.y + hh, right: c.x + hw)
    }

    private func inside(_ r: MacRect, _ x: Int, _ y: Int) -> Bool {
        x >= r.left && x < r.right && y >= r.top && y < r.bottom
    }

    /// `⌊c·a/32⌋` per 5-bit channel.
    private func darken(_ p: UInt16, _ a: UInt16) -> UInt16 {
        let r = ((p >> 10) & 31) * a / 32, g = ((p >> 5) & 31) * a / 32, b = (p & 31) * a / 32
        return (r << 10) | (g << 5) | b
    }

    /// Pass 200: every game-area screen pixel outside the sprites equals the map at window top 2919 (3119 − 200),
    /// source column 32 + x; borders black; and the level-start anchor back(0,0) = jum2(32, 3120) = 0x1040.
    func testTerrainOracle() throws {
        let jum2 = try Level1Images.jum2.get()
        XCTAssertEqual(jum2.width, 480); XCTAssertEqual(jum2.height, 3600)
        let assets = try ShippedAssets.get()

        // Anchor: only the init ops (before pass 0's own clearLayers).
        var anchor = try HeadlessRun(label: "anchor")
        let first = anchor.session.pass(keys: HeldKeys())
        for op in first.ops.prefix(while: { $0 != .clearLayers }) { anchor.apply(op) }
        XCTAssertEqual(anchor.renderer.buffer(.terrain).width, 480)
        XCTAssertEqual(anchor.renderer.buffer(.terrain).height, 3600)
        XCTAssertEqual(jum2.pixels[3120 * 480 + 32], 0x1040)
        XCTAssertEqual(anchor.renderer.buffer(.back)[0, 0], 0x1040)

        var run = try HeadlessRun(label: "terrain", dump: [200])
        let out = try XCTUnwrap(run.run(through: 200))
        let covers = try draws(out).filter { $0.clip == Self.gameClip }.map { try coverRect($0, assets) }
        XCTAssertGreaterThanOrEqual(covers.count, 3, "crosshair, shadow, ship")
        let screen = run.renderer.screen
        var checked = 0
        for y in 0..<480 {
            for x in 0..<416 where !covers.contains(where: { inside($0, x, y) }) {
                XCTAssertEqual(screen[32 + x, y], jum2.pixels[(2919 + y) * 480 + 32 + x], "(\(x), \(y))")
                checked += 1
                if screen[32 + x, y] != jum2.pixels[(2919 + y) * 480 + 32 + x] { return }
            }
            for x in 0..<32 { XCTAssertEqual(screen[x, y], 0) }
            for x in 608..<640 { XCTAssertEqual(screen[x, y], 0) }
        }
        XCTAssertGreaterThan(checked, 416 * 480 * 9 / 10)
    }

    /// Pass 200: the score bar (screen x 448…607) equals `scor` outside the element rects; a P1 score-glyph
    /// pixel with map 0 is 0x4B7C.
    func testScoreBarOracle() throws {
        let scor = try Level1Images.scor.get()
        XCTAssertEqual(scor.width, 160); XCTAssertEqual(scor.height, 480)
        let assets = try ShippedAssets.get()
        var run = try HeadlessRun(label: "scorebar", dump: [200])
        let initOps = run.pass().ops
        run.run(through: 200)
        let screen = run.renderer.screen
        let locals = run.session.scoreBar.records.prefix(2).flatMap(\.localRects)
        var checked = 0
        for y in 0..<480 {
            for x in 0..<160 where !locals.contains(where: { inside($0, x, y) }) {
                XCTAssertEqual(screen[448 + x, y], scor.pixels[y * 160 + x], "bar (\(x), \(y))")
                checked += 1
                if screen[448 + x, y] != scor.pixels[y * 160 + x] { return }
            }
        }
        XCTAssertGreaterThan(checked, 160 * 480 / 2)

        // The P1 score element: the draws between its restore copy (dst = buffer rect 0) and the next copy.
        let p1 = run.session.scoreBar.records[0]
        let start = try XCTUnwrap(initOps.firstIndex {
            if case let .copy(from: .scoreSave, to: .back, _, dst, _) = $0 { return dst == p1.bufferRects[0] }
            return false
        })
        let glyphs = initOps[(start + 1)...].prefix { if case .draw = $0 { return true } else { return false } }
            .compactMap { if case let .draw(c) = $0 { return c } else { return nil } }
        XCTAssertEqual(glyphs.count, 7, "\"%0.7i\" of 0")
        var found = 0
        for g in glyphs {
            let f = try assets.spriteGroup(g.face).frames[g.frame]
            let left = Int(g.x) - f.width / 2, top = Int(g.y) - f.height / 2
            for j in 0..<f.height {
                for i in 0..<f.width {
                    let zero = f.alphaMap.map { $0[j * f.width + i] == 0 } ?? (f.pixels[j * f.width + i] != f.key)
                    guard zero else { continue }
                    XCTAssertEqual(screen[left + i + 32, top + j], 0x4B7C, "glyph \(g.face) (\(i), \(j))")
                    found += 1
                }
            }
        }
        XCTAssertGreaterThan(found, 0)
    }

    /// Pass 200: ship pixels with map 0 equal `pl1o` frame 0; shadow pixels with map 0 (scaled sampling of the
    /// shadow command) not under the ship equal the terrain darkened to ⌊c·20/32⌋.
    func testShipAndShadowOracle() throws {
        let jum2 = try Level1Images.jum2.get()
        let pl1o = try Level1Images.pl1o.get()
        let assets = try ShippedAssets.get()
        var run = try HeadlessRun(label: "ship", dump: [200])
        let out = try XCTUnwrap(run.run(through: 200))
        let all = draws(out).filter { $0.clip == Self.gameClip }
        let ship = try XCTUnwrap(all.first { $0.face == pl1o.id && $0.flags & 2 == 0 })
        let shadow = try XCTUnwrap(all.first { $0.face == pl1o.id && $0.flags & 2 != 0 })
        let others = try all.filter { $0.face != pl1o.id }.map { try coverRect($0, assets) }
        XCTAssertEqual(ship.frame, 0)
        XCTAssertEqual(ship.x, 208); XCTAssertEqual(ship.y, 330)
        XCTAssertEqual(ship.scale, 1); XCTAssertEqual(ship.flags, 0)
        XCTAssertEqual(shadow.alpha, 20); XCTAssertEqual(shadow.scale, 0.5)
        let screen = run.renderer.screen

        let f = pl1o.frames[0]
        let map = try XCTUnwrap(f.alphaMap)
        let sl = Int(ship.x) - f.width / 2, st = Int(ship.y) - f.height / 2
        let shipRect = MacRect(top: Int32(st), left: Int32(sl), bottom: Int32(st + f.height), right: Int32(sl + f.width))
        var shipChecked = 0
        for j in 0..<f.height {
            for i in 0..<f.width where map[j * f.width + i] == 0 && !others.contains(where: { inside($0, sl + i, st + j) }) {
                XCTAssertEqual(screen[32 + sl + i, st + j], f.pixels[j * f.width + i], "ship (\(i), \(j))")
                shipChecked += 1
            }
        }
        XCTAssertGreaterThan(shipChecked, 100)

        // Shadow: W = w·0.5, w′ = trunc(W), left = trunc(X − 0.5·W); sx = (w·(dx − left)) div w′ (blit-pixel-rules §5).
        let sf = pl1o.frames[shadow.frame]
        let smap = try XCTUnwrap(sf.alphaMap)
        let fw = Float(sf.width) * shadow.scale, fh = Float(sf.height) * shadow.scale
        let w2 = Int(fw), h2 = Int(fh)
        let left = Int((Float(shadow.x) - 0.5 * fw).rounded(.towardZero))
        let top = Int((Float(shadow.y) - 0.5 * fh).rounded(.towardZero))
        let windowTop = 3119 - 200
        var shadowChecked = 0
        for dy in 0..<h2 {
            for dx in 0..<w2 {
                let sx = sf.width * dx / w2, sy = sf.height * dy / h2
                let x = left + dx, y = top + dy
                guard smap[sy * sf.width + sx] == 0, !inside(shipRect, x, y),
                      !others.contains(where: { inside($0, x, y) }) else { continue }
                let terrain = jum2.pixels[(windowTop + y) * 480 + 32 + x]
                XCTAssertEqual(screen[32 + x, y], darken(terrain, 20), "shadow (\(dx), \(dy))")
                shadowChecked += 1
            }
        }
        XCTAssertGreaterThan(shadowChecked, 50)
    }

    /// Pass 2: the fade from black presents 9 game-layout screens — the first all black, the last the back buffer
    /// as pass 1 left it (screen x 32…639 ← back x 0…607; x 0…31 untouched, black).
    func testFadeFromBlackFrames() throws {
        var run = try HeadlessRun(label: "fade", dump: [1, 2])
        run.run(through: 1)
        let back1 = run.renderer.buffer(.back)
        var screens: [Pixmap555] = []
        let out = run.pass(fadeScreen: { screens.append($0) })
        XCTAssertTrue(out.ops.contains(.fade(.fromBlack, .gameLayout)))
        XCTAssertEqual(screens.count, 9)
        XCTAssertTrue(screens[0].pixels.allSatisfy { $0 == 0 }, "a = 0: black")
        let last = try XCTUnwrap(screens.last)
        for y in 0..<480 {
            for x in 0..<32 { XCTAssertEqual(last[x, y], 0) }
            for x in 0..<608 where last[32 + x, y] != back1[x, y] {
                XCTFail("last step (\(x), \(y)): \(last[32 + x, y]) ≠ \(back1[x, y])"); return
            }
        }
        // A middle step is ⌊c·a/32⌋ of the snapshot (a = 16).
        for (x, y) in [(10, 10), (200, 300), (500, 100)] {
            XCTAssertEqual(screens[4][32 + x, y], darken(back1[x, y], 16))
        }
    }

    /// Self-derived goldens (FNV-1a 64, `fnv1a64`), seed 0x469c2, no keys: the screen after passes 2, 56, 72, 105,
    /// 600, 3118, 3200 and the back buffer after pass 0. Derived on the first green run at HectorKit 522feb8,
    /// Classics bc8c170 + this task's R3 tree (the commit that adds this test); a second review leg re-derives them.
    func testFrameGoldens() throws {
        let screenGoldens: [Int: UInt64] = [
            2: 0xa50b_449b_e758_b51e, 56: 0x9eb1_3d84_ae09_d2de, 72: 0x13a4_433f_7799_2d00,
            105: 0x2295_e00a_698a_ad11, 600: 0xea78_2812_091d_0229,
            3118: 0x2397_7d31_af56_be4a, 3200: 0x2397_7d31_af56_be4a,   // the window stops at top 1 from pass 3118
        ]
        let backGolden0: UInt64 = 0x9527_86d1_5e67_2e50
        var run = try HeadlessRun(label: "goldens", dump: Set(screenGoldens.keys).union([0]))
        run.run(through: 0)
        var got: [String] = []
        let back0 = fnv1a64(run.renderer.buffer(.back))
        got.append("back 0: 0x\(String(back0, radix: 16))")
        XCTAssertEqual(back0, backGolden0, "back after pass 0")
        for n in screenGoldens.keys.sorted() {
            run.run(through: n)
            let h = fnv1a64(run.renderer.screen)
            got.append("screen \(n): 0x\(String(h, radix: 16))")
            XCTAssertEqual(h, screenGoldens[n], "screen after pass \(n)")
        }
        print("R3 goldens:", got.joined(separator: ", "))
    }

    /// Left held for passes 200…240: the view offset steps −1 per pass to −32 at pass 231; the ship banks to frame 3
    /// from pass 204; the terrain source column is offset + 32 (oracle at pass 240); screen golden self-derived as
    /// `testFrameGoldens`.
    func testPanAndBankGolden() throws {
        let golden240: UInt64 = 0x0c99_1372_56a0_bc44   // self-derived: HectorKit 522feb8, Classics bc8c170 + R3
        let assets = try ShippedAssets.get()
        let jum2 = try Level1Images.jum2.get()
        var run = try HeadlessRun(label: "pan", dump: Set(200...240))
        run.run(through: 199)
        XCTAssertEqual(run.session.scroll.offset, 0)
        var out: PassOutput?
        for t in 200...240 {
            out = run.pass(keys: HeldKeys(held: [Self.leftKey], capsLock: false))
            XCTAssertEqual(run.session.scroll.offset, Int32(max(199 - t, -32)), "offset after pass \(t)")
            let frame = run.session.players[0].object.frame
            if t >= 204 { XCTAssertEqual(frame, 3, "frame at pass \(t)") } else { XCTAssertNotEqual(frame, 3, "pass \(t)") }
        }
        let covers = try draws(XCTUnwrap(out)).filter { $0.clip == Self.gameClip }.map { try coverRect($0, assets) }
        let screen = run.renderer.screen
        let top = 3119 - 240, column = Int(run.session.scroll.offset) + 32
        XCTAssertEqual(column, 0)
        for y in 0..<480 {
            for x in 0..<416 where !covers.contains(where: { inside($0, x, y) }) {
                if screen[32 + x, y] != jum2.pixels[(top + y) * 480 + column + x] {
                    XCTFail("pan oracle (\(x), \(y))"); return
                }
            }
        }
        let h = fnv1a64(screen)
        print("R3 pan golden: 0x\(String(h, radix: 16))")
        XCTAssertEqual(h, golden240)
    }
}
