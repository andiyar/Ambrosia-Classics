import XCTest
import HectorResources  // not in Package.swift's list: it reaches this target through DeimosCore (as DeimosHostTests/LastFilmStoreTests.swift)
@testable import DeimosCore
@testable import DeimosRender

/// Phase 4 S8b GD — the front end's frame goldens (plan "Verification model (additions)", "Frame goldens"; the S8b
/// card). No picture of the original's screens exists (grounding A §10), so each golden is the replica's own frame:
/// FNV-1a 64 over the 640 × 480 screen (`fnv1a64`, the method of `LevelOneFrameTests`), self-derived by running
/// (HectorKit ef2c341, Classics 8d52eeb + this file) and confirmed over two separate `swift test` processes. They catch change, not error — Ben's eyes are the only proof a
/// screen looks right. Each golden is backed by pixel checks whose expected values are read here from the source
/// images and data (the `back`, `lese` TGAs, sprite frames, the Geneva 9 table, the handed-in pictures), never from
/// the rendered frame.
///
/// The screens run their real code, through the front end where practical (boot, menu, scores, credits, both settings
/// windows, from a fresh `FrontEnd`); the level select and name entry are stepped directly as their own tests step them
/// (`LevelSelectTests`, `NameEntryTests`): the level select's flash and message are named from its own state, and
/// name entry is reached in the app only from a finished game. Every op goes through one `DeimosRenderer` as the host
/// would execute it: fades stepped through all their levels; `.hostWait`, `.limit` skipped (nothing here is timed).
/// With `DEIMOS_FRAME_DUMP` set to a folder, each golden frame is written to `<folder>/front-end/<name>.ppm`.
/// Every loop names its bound and fails on it (G11).
final class FrontEndGoldenTests: XCTestCase {

    // MARK: - Harness

    /// A missing data file: the test fails naming the path (standing rule 4: never a skip).
    private struct MissingFile: Error, CustomStringConvertible {
        let path: String
        var description: String { "missing data file: \(path)" }
    }

    /// The app's resource fork as the shell hands it in (`Resources/Deimos/Deimos Rising.rsrc`, `DialogResources`).
    private static let fork: Result<[ShellResourceKey: [UInt8]], Error> = Result {
        let url = try DeimosData.dataDirectory().deletingLastPathComponent().appendingPathComponent("Deimos Rising.rsrc")
        guard FileManager.default.fileExists(atPath: url.path) else { throw MissingFile(path: url.path) }
        return try DialogResources.readFork(Array(Data(contentsOf: url)))
    }

    /// An `im16` TGA straight from the decoder (independent of the renderer).
    private func image(_ id: String) throws -> TGAImage { try image(FourCC(id)!) }

    private func image(_ id: FourCC) throws -> TGAImage {
        let index = try ShippedAssets.get().index
        guard let r = index.record(type: FourCC("im16")!, id: id) else {
            throw DeimosAssetsError.missingTag(type: "im16", id: id.description)
        }
        return try TGAImage(data: index.data(for: r))
    }

    /// The game's blend kernel as documented (blit-pixel-rules §2; `Blend555`), written out here: per 5-bit channel
    /// ⌊(a_c·w + b_c·(32 − w)) / 32⌋, bit 15 clear. `COST` (`CostRect`) blends the destination at w with its colour.
    private static func blend(_ pa: UInt16, _ pb: UInt16, w: Int) -> UInt16 {
        var out: UInt16 = 0
        for shift: UInt16 in [10, 5, 0] {
            let ca = Int((pa >> shift) & 31), cb = Int((pb >> shift) & 31)
            out |= UInt16((ca * w + cb * (32 - w)) / 32) << shift
        }
        return out
    }

    /// Inside `request`'s laid-out bounds (`TextLayout` over the format read from the data — not the frame), at least
    /// one pixel differs from `base` and is the text's own colour: a colourising format's colour (its blend 0, so a
    /// glyph's opaque pixel is that colour exactly), else the font frame's own pixel at that place (an opaque glyph
    /// pixel, the glyph placed as the layout places it). Returns the matching pixels.
    @discardableResult
    private func assertTextDrawn(_ screen: Pixmap555, _ request: TextRequest, unlike base: (Int, Int) -> UInt16,
                                 _ label: String, file: StaticString = #filePath, line: UInt = #line) throws -> Int {
        let a = try ShippedAssets.get()
        let text = try TextLayout(assets: a)
        let (b, glyphs) = text.layout(request, draw: true)
        XCTAssertTrue(b.left < b.right && b.top < b.bottom, "\(label): bounds \(b)", file: file, line: line)
        var expected: [Int: UInt16] = [:]                            // y·640 + x → the text's colour there
        if request.format.coloriseDo {
            XCTAssertEqual(request.format.blendAmount, 0, "\(label): an opaque format", file: file, line: line)
            for y in Int(b.top)..<Int(b.bottom) {
                for x in Int(b.left)..<Int(b.right) { expected[y * 640 + x] = request.format.coloriseColor }
            }
        } else {
            let font = try a.spriteGroup(text.font)
            for g in glyphs {
                let f = font.frames[g.frame]
                let map = try XCTUnwrap(f.alphaMap, "\(label): glyph frame \(g.frame) has an alpha map", file: file,
                                        line: line)
                let left = Int(g.x) - f.width / 2, top = Int(g.y) - f.height / 2
                for j in 0..<f.height {
                    for i in 0..<f.width where map[j * f.width + i] == 0 {
                        expected[(top + j) * 640 + left + i] = f.pixels[j * f.width + i]
                    }
                }
            }
        }
        var found = 0
        for y in max(0, Int(b.top))..<min(480, Int(b.bottom)) {
            for x in max(0, Int(b.left))..<min(640, Int(b.right)) {
                if let c = expected[y * 640 + x], screen[x, y] == c, screen[x, y] != base(x, y) { found += 1 }
            }
        }
        XCTAssertGreaterThan(found, 0, "\(label): no pixel of the text's colour inside \(b)", file: file, line: line)
        return found
    }

    /// Executes ops on a renderer the way the host does (`HeadlessRun.apply`): a fade stepped through all its
    /// levels, the host's waits skipped. A Caps Lock wait is never reached by these screens: it fails.
    private final class Painter {
        let renderer: DeimosRenderer
        init(_ assets: DeimosAssets) { renderer = DeimosRenderer(assets: assets) }

        func apply(_ ops: [RenderOp]) { for op in ops { apply(op) } }

        func apply(_ op: RenderOp) {
            switch op {
            case let .fade(kind, present):
                renderer.fadeBegin(kind)
                let levels = kind == .fromBlack ? DisplayBuffers.fromBlackLevels : DisplayBuffers.toBlackLevels
                for a in levels { renderer.fadeStep(kind, a: a, present: present) }
                renderer.fadeEnd()
            case .limit, .hostWait:
                break
            case .pauseWait:
                XCTFail("a Caps Lock wait: no golden screen reaches one")
            default:
                renderer.apply(op)
            }
        }

        var screen: Pixmap555 { renderer.screen }
    }

    /// A boot-entry `FrontEnd` whose every pass is painted. `ticks` is the next pass's TickCount.
    private struct FrontEndRun {
        var fe: FrontEnd
        let painter: Painter
        var ticks: UInt32 = 1_000

        init(assets: DeimosAssets, prefs: DeimosPrefs, firstLaunch: Bool,
             shellResources: [ShellResourceKey: [UInt8]] = [:]) throws {
            fe = try FrontEnd(assets: assets, prefs: prefs, shellResources: shellResources, firstLaunch: firstLaunch)
            painter = Painter(assets)
        }

        /// One front-end pass at `ticks`, painted; then the clock moves on `advance` ticks.
        @discardableResult
        mutating func pass(_ keys: HeldKeys = HeldKeys(), advance: UInt32 = 2) -> PassOutput {
            let out = fe.pass(keys: keys, ticks: ticks)
            painter.apply(out.ops)
            ticks &+= advance
            return out
        }

        /// The real boot, every pass at one tick (as `BootTests` / `MainMenuTests` run it), until the main menu is the
        /// top screen: six passes, the sixth the boot's return chained into the menu's entry. Bound: 10 passes.
        @discardableResult
        mutating func bootToMenu() -> Int {
            var n = 0
            for _ in 0..<10 where fe.screens.last != .mainMenu {
                pass(advance: 0)
                n += 1
            }
            XCTAssertEqual(fe.screens, [.mainMenu], "bound: the menu is not up within 10 boot passes")
            ticks &+= 2
            return n
        }
    }

    /// Fresh prefs with byte pref 2 = 1: the boot does not open the configuration window (it has, at an earlier
    /// launch), so a test that hands in the resource fork boots straight to the menu.
    private static var bootedPrefs: DeimosPrefs {
        var p = DeimosPrefs.fresh
        p.bytePrefs[2] = 1
        return p
    }

    private static func key(_ c: UInt8, _ code: UInt16) -> HeldKeys {
        HeldKeys(keyEvents: [KeyEvent(charCode: c, keyCode: code)])
    }

    /// The golden, printed for re-derivation, dumped when asked, and asserted.
    private func golden(_ screen: Pixmap555, _ name: String, _ expected: UInt64,
                        file: StaticString = #filePath, line: UInt = #line) {
        let h = fnv1a64(screen)
        print("GD golden \(name): 0x\(String(h, radix: 16))")
        dump(screen, name, file: file, line: line)
        XCTAssertEqual(h, expected, "golden \(name): 0x\(String(h, radix: 16))", file: file, line: line)
    }

    /// Only with `DEIMOS_FRAME_DUMP` set; a dump asked for that cannot be written fails the test.
    private func dump(_ s: Pixmap555, _ name: String, file: StaticString = #filePath, line: UInt = #line) {
        guard let folder = ProcessInfo.processInfo.environment["DEIMOS_FRAME_DUMP"], !folder.isEmpty else { return }
        let dir = URL(fileURLWithPath: folder, isDirectory: true).appendingPathComponent("front-end", isDirectory: true)
        var bytes = Array("P6\n\(s.width) \(s.height)\n255\n".utf8)
        bytes.reserveCapacity(bytes.count + 3 * s.pixels.count)
        for p in s.pixels {
            for c in [(p >> 10) & 31, (p >> 5) & 31, p & 31] { bytes.append(UInt8((c << 3) | (c >> 2))) }
        }
        do {
            try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
            try Data(bytes).write(to: dir.appendingPathComponent("\(name).ppm"))
        } catch {
            XCTFail("frame dump \(name) into \(dir.path): \(error)", file: file, line: line)
        }
    }

    /// Screen pixels at `points` equal the source image's pixels there (a 640 × 480 image copied 1:1 to the screen).
    private func assertSource(_ screen: Pixmap555, _ img: TGAImage, _ points: [(Int, Int)], _ label: String,
                              file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertEqual([img.width, img.height], [640, 480], "\(label): a full-screen picture", file: file, line: line)
        for (x, y) in points {
            XCTAssertEqual(screen[x, y], img.pixels[y * img.width + x], "\(label) (\(x), \(y))", file: file, line: line)
        }
    }

    /// Every pixel of sprite frame `frame` of `face` whose alpha map is 0 (opaque) equals the frame's own pixel on the
    /// screen, the frame centred on (`cx`, `cy`) at scale 1 (`EntityDraw` / `SpriteBlitter`). Returns the pixels checked.
    @discardableResult
    private func assertSprite(_ screen: Pixmap555, _ face: FourCC, frame: Int, cx: Int, cy: Int, _ label: String,
                              file: StaticString = #filePath, line: UInt = #line) throws -> Int {
        let f = try ShippedAssets.get().spriteGroup(face).frames[frame]
        let map = try XCTUnwrap(f.alphaMap, "\(label): an alpha map", file: file, line: line)
        let left = cx - f.width / 2, top = cy - f.height / 2
        var checked = 0
        for j in 0..<f.height {
            for i in 0..<f.width where map[j * f.width + i] == 0 {
                if screen[left + i, top + j] != f.pixels[j * f.width + i] {
                    XCTFail("\(label) (\(i), \(j)): \(screen[left + i, top + j]) ≠ \(f.pixels[j * f.width + i])",
                            file: file, line: line)
                    return checked
                }
                checked += 1
            }
        }
        XCTAssertGreaterThan(checked, 20, "\(label): opaque pixels checked", file: file, line: line)
        return checked
    }

    // MARK: - The goldens

    /// The loading screen, the boot's fifth pass (`BootTests.testLoadingLines`): `back` restored, every line redrawn,
    /// a full present per loading update. Two frames, each taken right after the n-th full present of that pass:
    /// - **first launch** (`FrontEnd(… firstLaunch: true)`, no settings file existed): the 135th update — lines
    ///   "Loading Permanent Image:  Done", "Loading Permanent Sound:  Done" and "Unpacking Unit:  Juno Gun - Bullet
    ///   Hi" (unde 100, the update `BootTests` pins at call 134);
    /// - **a later launch** (`firstLaunch: false`): the 44th and last update, before the fade-out — four lines, images,
    ///   sounds, weapons, players, each ending "Done".
    /// Fresh prefs, sound on, no resource fork. The app hands the fork in, but it cannot change these frames, so it is
    /// left out: with it, the first launch's configuration window (called inside the first pass) would open and wait
    /// for a click — not a one-line change, and it would move the pass count — while the window's pixels are gone
    /// before the loading screen (pass 5 fills the back buffer black, loads `back` into the back and save buffers
    /// whole, and every loading update restores the whole back buffer before it draws); Save on fresh settings
    /// changes no pref the loading lines read. Without it the window finishes at once and draws nothing.
    ///
    /// The lines: the boot frees its element list at the end of the same pass (`Boot.loadingLines`, `FUN_100253d0`),
    /// so at the shot it cannot be read back; instead the update that ends at the shot (from the previous present) is
    /// matched op for op with the list's records as `Boot.line` keeps them — format 0, Loc Y 100 + flli 64 · i, blend
    /// 0 — built here from the `inte` strings: the restore, every line drawn, the present.
    func testGoldenLoadingScreen() throws {
        let goldens: [Bool: UInt64] = [true: 0x8125_7f2c_fe53_c80a, false: 0x68eb_9c48_4401_256c]
        let presentsAt: [Bool: Int] = [true: 135, false: 44]
        let a = try ShippedAssets.get()
        let back = try image("back")
        let inte = try a.interfaceStrings().lines
        func string(_ n: Int) -> String { inte.indices.contains(n) ? MacRoman.decode(inte[n]) : "" }
        let shown: [Bool: [String]] = [true: [string(7), string(9), "Unpacking Unit:  Juno Gun - Bullet Hi"],
                                       false: [string(7), string(9), string(13), string(15)]]
        for first in [true, false] {
            let label = first ? "loading-first-launch" : "loading-later-launch"
            var run = try FrontEndRun(assets: a, prefs: .fresh, firstLaunch: first)
            for _ in 0..<4 { run.pass(advance: 0) }                     // the four passes before the loading lines
            XCTAssertEqual(run.fe.screens, [.boot], label)
            let out = run.fe.pass(keys: HeldKeys(), ticks: run.ticks)  // pass 5: painted op by op below
            let presents = out.ops.filter { $0 == .present(.fullScreen) }.count
            XCTAssertEqual(presents, first ? 432 : 44, "\(label): one full present per loading update")
            var n = 0
            var shot: Pixmap555?
            var update: ArraySlice<RenderOp> = []
            var previous = -1                                           // the op index of the previous present
            for (i, op) in out.ops.enumerated() {                       // bounded by the pass's own ops
                run.painter.apply(op)
                if op == .present(.fullScreen) {
                    n += 1
                    if n == presentsAt[first] { shot = run.painter.screen; update = out.ops[(previous + 1)...i]; break }
                    previous = i
                }
            }
            let screen = try XCTUnwrap(shot, "\(label): update \(presentsAt[first]!) not reached")

            // The lines on screen: three on the first launch, the third the unit line; four on a later one, each
            // finished ("… Done").
            let lines = shown[first]!
            XCTAssertEqual(lines.count, first ? 3 : 4, label)
            if first {
                XCTAssertEqual(Array(lines[0...1]), ["Loading Permanent Image:  Done", "Loading Permanent Sound:  Done"])
                XCTAssertTrue(lines[2].hasPrefix("Unpacking Unit:"), label)
            } else {
                XCTAssertTrue(lines.allSatisfy { $0.hasSuffix("Done") }, "\(label): \(lines)")
            }
            let f0 = a.formats[0]
            let records = lines.enumerated().map { i, t -> TextRequest in
                var r = TextRequest(format: f0, text: t)
                r.format.locY = f0.locY &+ Int32(i) &* EntityDraw.fctiwz(a.floats[0x40])
                r.format.drawShadows = false
                r.format.blendAmount = 0
                return r
            }
            let bounds = EntityDraw.backBufferBounds
            let expected = [RenderOp.copy(from: .terrain, to: .back, src: bounds, dst: bounds, interlaced: false)]
                + records.flatMap { run.fe.state.text.draw($0).map { RenderOp.draw($0) } } + [.present(.fullScreen)]
            XCTAssertTrue(records.allSatisfy { !run.fe.state.text.draw($0).isEmpty }, "\(label): every line draws")
            XCTAssertEqual(Array(update), expected, "\(label): the update draws exactly these \(lines.count) lines")
            // `back` where no line reaches (lines from x 50, y 100 + 20·i).
            assertSource(screen, back, [(20, 20), (620, 460), (600, 40), (10, 300)], label)
            // A line was drawn over it: the first line's row differs from `back` somewhere.
            XCTAssertTrue((100..<112).contains { y in (50..<300).contains { screen[$0, y] != back.pixels[y * 640 + $0] } },
                          "\(label): the first line is drawn")
            golden(screen, label, goldens[first]!)
        }
    }

    /// The main menu, settled: the front end's sixth pass (the boot's return chained into the menu's entry): `back`,
    /// the 16-pass element fade-in, the redraw, a full present. No hover (no mouse), nothing lit. The bottom line is
    /// the copyright line ("COPYRIGHT 2001-2003 …"), not the registration banner: the flip comes 240 ticks later.
    func testGoldenMenu() throws {
        let a = try ShippedAssets.get()
        var run = try FrontEndRun(assets: a, prefs: .fresh, firstLaunch: false)
        XCTAssertEqual(run.bootToMenu(), 6, "the menu's entry on the sixth pass")
        let s = run.fe.state
        XCTAssertNil(s.menuLit, "nothing lit")
        XCTAssertEqual(s.menuElements.count, 9)
        guard s.menuElements.count == 9 else { return }
        XCTAssertEqual(MacRoman.decode(s.menuElements.elements[8].record.text),
                       "COPYRIGHT 2001-2003 SWOOP SOFTWARE & AMBROSIA SOFTWARE, INC.", "the bottom line: copyright")
        let screen = run.painter.screen
        // `back` away from the nine elements (logo 241…399 × 47…156, buttons x 272…368, web and copyright rows).
        assertSource(screen, try image("back"), [(20, 20), (600, 300), (100, 470), (630, 5)], "menu")
        // The logo (`gasp 5` `galo` frame 0, centre (320, 101), alpha 0 at rest): its opaque pixels as in the sprite.
        XCTAssertEqual(s.menuElements.elements[0].record.format.blendAmount, 0)
        try assertSprite(screen, a.sprites[5], frame: 0, cx: 320, cy: 101, "menu logo")
        golden(screen, "menu", 0xf439_3047_73aa_8d88)
    }

    /// The level select (stepped directly; fresh prefs: only sector 1 reached), two-tick frames from tick 1,000. Three
    /// frames:
    /// - **settled:** the first live frame after the entry and its fade-in, no input — previews 12 | 1 | 2, START;
    /// - **accept flash:** player 1's select held on the next frame accepts sector 1; the frame at flash step 6 (mode 1,
    ///   alpha 22, scale 2.0, the zoom's peak), green wash over the middle preview;
    /// - **fail flash:** from a fresh entry, → to sector 2 (not reached), a frame with no input, select held: refused;
    ///   the frame at fail-flash step 4 (mode 2, alpha 20, scale 2.0), "Sector Not Reached" showing.
    func testGoldenLevelSelect() throws {
        let goldens: [String: UInt64] = ["level-select": 0xe459_1aff_b033_b447,
                                         "level-select-accept": 0xc538_29cc_2237_22d9,
                                         "level-select-fail": 0x9734_5315_3b09_1c25]
        let a = try ShippedAssets.get()
        let lese = try image("lese")
        let select: UInt16 = 0x31, right: UInt16 = 0x7c               // fresh P1 keys: Space, →

        struct Run {
            var screen = LevelSelect()
            var state: FrontEndState
            var t: UInt32 = 1_000
        }
        func step(_ r: inout Run, _ p: Painter, _ keys: HeldKeys = HeldKeys()) -> ScreenStep<Int?> {
            let s = r.screen.pass(keys: keys, ticks: r.t, returned: nil, state: &r.state)
            p.apply(s.output.ops)
            r.t &+= 2
            return s
        }
        func ended(_ s: ScreenStep<Int?>) -> Bool { if case .finish = s.next { return true } else { return false } }
        func checks(_ screen: Pixmap555, _ label: String) throws {
            assertSource(screen, lese, [(10, 10), (630, 470), (5, 400), (630, 20)], label)
            // The `<` arrow (gasp 6 `mebu` frame 12 at (128, 228), queued last on layer 15, alpha 0).
            try assertSprite(screen, a.sprites[6], frame: 12, cx: 128, cy: 228, "\(label): the < button")
        }

        // Settled.
        var p = Painter(a)
        var run = Run(state: try FrontEndState(assets: a, prefs: .fresh))
        XCTAssertFalse(ended(step(&run, p)), "entry")
        XCTAssertFalse(ended(step(&run, p)), "first live frame")
        XCTAssertEqual(run.screen.previews.map(\.sector), [12, 1, 2])
        XCTAssertEqual(run.screen.flash, LevelSelect.Flash())
        try checks(p.screen, "level-select")

        // One pixel of the middle preview (sector 1), its picture decoded here. It lies on a row the video grid drawn
        // over the previews skips whole (gasp 0 `vigr` frame flli 84, tiled from the rect's top left at its own size;
        // a map row whose first entry is 1000 draws nothing, `UnscaledLeaves`): the first such row at or below a
        // quarter of the rect's height, mid-width — above the START button over the rect's centre — read from the grid
        // frame's own map.
        let mid = run.screen.previews[1]
        let pic = try image(mid.image)
        XCTAssertEqual([pic.width, pic.height], [Int(mid.width), Int(mid.height)], "the preview rect is its picture's")
        let grid = try a.spriteGroup(a.sprites[0]).frames[Int(EntityDraw.fctiwz(a.floats[84]))]
        let gridMap = try XCTUnwrap(grid.alphaMap, "the grid frame's map")
        let r = mid.rect
        let px = Int(r.left) + pic.width / 2
        var py = Int(r.top) + pic.height / 4
        func gridRowSkipped(_ y: Int) -> Bool { gridMap[((y - Int(r.top)) % grid.height) * grid.width] == 1000 }
        for _ in 0..<grid.height where !gridRowSkipped(py) { py += 1 }     // bound: one tile's height
        XCTAssertTrue(gridRowSkipped(py) && py < Int(r.bottom), "a skipped grid row inside the preview")
        let source = pic.pixels[(py - Int(r.top)) * pic.width + (px - Int(r.left))]
        XCTAssertEqual(p.screen[px, py], source, "the middle preview at (\(px), \(py)): its picture's pixel")
        let settled = p.screen
        golden(p.screen, "level-select", goldens["level-select"]!)

        // Accept: select held, then flash steps 1…6. Bound: 6 steps.
        let go = step(&run, p, HeldKeys(held: [select]))
        XCTAssertEqual(run.screen.flash.mode, 1, "accepted")
        XCTAssertTrue(go.output.sounds.contains(SoundPlay.perm(a.sounds[12], priority: 0x32, volume: 100,
                                                               allowMultiple: true)), "lsse")
        var last: ScreenStep<Int?>?
        for _ in 1...6 { last = step(&run, p) }
        XCTAssertFalse(last.map(ended) ?? true)
        XCTAssertEqual(run.screen.flash.mode, 1)
        XCTAssertEqual(run.screen.flash.alpha, 22, "step 6")
        XCTAssertEqual(run.screen.flash.scale, 2.0, "the peak")
        XCTAssertTrue(last?.output.ops.contains(.scaledCopy(image: run.screen.previews[1].image, into: .back,
                                                            dst: MacRect(top: -77, left: 173, bottom: 535, right: 465),
                                                            clip: run.screen.previews[1].rect)) ?? false,
                      "the zoom at 2.0")
        try checks(p.screen, "level-select-accept")
        // The same pixel: the zoomed picture (`FUN_1001d1b0` point-sampled, source column srcW·(x − left) / width,
        // row srcH·(y − top) / height over the zoom's rect) under the `COST` flash over the preview rect, format 27
        // `lsca`'s colour at its blend + 6 (one step a frame), blended as documented.
        let zoom = MacRect(top: -77, left: 173, bottom: 535, right: 465)
        let sx = pic.width * (px - Int(zoom.left)) / Int(zoom.right - zoom.left)
        let sy = pic.height * (py - Int(zoom.top)) / Int(zoom.bottom - zoom.top)
        let lsca = a.formats[27]
        XCTAssertTrue(lsca.coloriseDo)
        XCTAssertEqual(Int(lsca.blendAmount) + 6, 22, "step 6's alpha from the format")
        XCTAssertEqual(p.screen[px, py], Self.blend(pic.pixels[sy * pic.width + sx], lsca.coloriseColor, w: 22),
                       "the accept flash at (\(px), \(py)): source (\(sx), \(sy)) under lsca at 22")
        golden(p.screen, "level-select-accept", goldens["level-select-accept"]!)

        // Fail.
        p = Painter(a)
        run = Run(state: try FrontEndState(assets: a, prefs: .fresh))
        _ = step(&run, p)
        _ = step(&run, p, HeldKeys(held: [right]))
        _ = step(&run, p)
        XCTAssertEqual(run.screen.previews[1].sector, 2)
        XCTAssertFalse(run.screen.previews[1].reachable)
        let no = step(&run, p, HeldKeys(held: [select]))
        XCTAssertTrue(no.output.sounds.contains(SoundPlay.perm(a.sounds[14], priority: 0x32, volume: 100,
                                                               allowMultiple: true)), "lsna")
        for _ in 1...4 { last = step(&run, p) }                         // bound: 4 steps
        XCTAssertFalse(last.map(ended) ?? true)
        XCTAssertEqual(run.screen.flash.mode, 2)
        XCTAssertEqual(run.screen.flash.alpha, 20, "step 4")
        XCTAssertEqual(run.screen.flash.scale, 2.0, "the peak")
        XCTAssertTrue(run.screen.message.active)
        XCTAssertEqual(MacRoman.decode(run.screen.message.text), "Sector Not Reached")
        try checks(p.screen, "level-select-fail")
        // The message (pgsl 4) in format 24 `lsna` (sector 2 not reached) with format 26 `lsfa`'s colourise, colour
        // and blend — read from the data, laid out here: drawn where the settled frame had sector 1's name.
        let lsfa = a.formats[26]
        XCTAssertTrue(lsfa.coloriseDo)
        var message = TextRequest(format: a.formats[24], text: Array(a.gameStrings[4].prefix { $0 != 0 }))
        message.format.coloriseDo = true
        message.format.coloriseColor = lsfa.coloriseColor
        message.format.blendAmount = lsfa.blendAmount
        XCTAssertEqual(MacRoman.decode(message.text), "Sector Not Reached")
        try assertTextDrawn(p.screen, message, unlike: { settled[$0, $1] }, "level-select-fail: the message")
        golden(p.screen, "level-select-fail", goldens["level-select-fail"]!)
    }

    /// The high scores, through the front end: the settled menu, then `S` on the next pass (the SCORES flash and the
    /// menu's fade-out; the menu calls the scores, but that pass drew, so the chain stops there), then the scores
    /// screen's entry on the pass after. The frame after the entry pass: `back`, the fresh prefs' default table
    /// (`DeimosPrefs.fresh`: 15 rows, "Name" / "Score" / "Sector"), no row lit.
    func testGoldenScores() throws {
        let a = try ShippedAssets.get()
        var run = try FrontEndRun(assets: a, prefs: .fresh, firstLaunch: false)
        run.bootToMenu()
        run.pass(Self.key(0x53, 0x01))                                  // 'S': the flash drew, the chain stops
        XCTAssertEqual(run.fe.screens, [.mainMenu, .scores], "S calls the scores")
        run.pass()                                                      // the scores screen's entry
        XCTAssertEqual(run.fe.state.prefs.highScores, DeimosPrefs.fresh.highScores, "the default table")
        XCTAssertEqual(run.fe.state.prefs.highScoreNames, DeimosPrefs.fresh.highScoreNames)
        let screen = run.painter.screen
        let back = try image("back")
        assertSource(screen, back, [(5, 5), (634, 474), (5, 474), (634, 5)], "scores")
        // Drawn text, laid out from the data: the "Name" heading (format 10, colourised) and row 0's name (format 13
        // at Loc Y flli 77, the font's own colours).
        try assertTextDrawn(screen, TextRequest(format: a.formats[10], text: "Name"),
                            unlike: { back.pixels[$1 * 640 + $0] }, "scores: the Name heading")
        var row0 = TextRequest(format: a.formats[13], text: DeimosPrefs.fresh.highScoreNames[0])
        row0.format.locY = EntityDraw.fctiwz(a.floats[77])
        try assertTextDrawn(screen, row0, unlike: { back.pixels[$1 * 640 + $0] }, "scores: row 0's name")
        golden(screen, "scores", 0xe358_623a_a035_cfff)
    }

    /// Name entry (stepped directly; fresh prefs): as the app reaches it, through the score-table insertion
    /// (`StartReturn.table` → `HighScoreTable.insert`, `FUN_100214c0`): a one-player game's result — player 1 12,500
    /// with sector 3 (`le02`, "Darius") its last level, player 2's slot present with 0 — into the fresh table: row 3,
    /// the rows below shifted down one, the last dropped; then `NameEntry(player: 0, slot: 3, prefs: <the inserted
    /// table>)`, `fromGame`, as the table step builds it for one qualifier. The entry pass at tick 1,000; at 1,001
    /// twenty Backspaces clear the pre-filled "Player 1" and "DEIMOS" is typed (the cursor hidden by the keys); at
    /// 1,032 the blink (30 ticks after the last key, 10 after the last flip) shows the cursor. The frame after that
    /// pass: row 3 lit with player 1's ship, its name "DEIMOS_" — cursor SHOWN.
    func testGoldenNameEntry() throws {
        let a = try ShippedAssets.get()
        let p = Painter(a)
        var state = try FrontEndState(assets: a, prefs: .fresh)
        let result = SessionResult(end: .gameOver, isFilm: false, startSector: 1, present: [true, true],
                                   scores: [12_500, 0], levels: [a.levelOrder.level(sector: 3), .none],
                                   allLevels: false, cheated: false)
        let insertion = HighScoreTable.insert(result, into: state.prefs, assets: a)
        XCTAssertEqual(insertion.slots, [3, nil], "12,500 ranks between 13,000 and 12,000; player 2 does not qualify")
        let table = insertion.prefs, fresh = DeimosPrefs.fresh
        XCTAssertEqual([String(table.highScores[3]), table.highScoreNames[3], table.highScoreSectorNames[3]],
                       ["12500", "Player 1", "Darius"], "row 3")
        XCTAssertEqual(Array(table.highScores[0..<3]), Array(fresh.highScores[0..<3]), "rows 0–2 kept")
        XCTAssertEqual(Array(table.highScores[4..<15]), Array(fresh.highScores[3..<14]), "shifted; row 14 dropped")
        XCTAssertEqual(Array(table.highScoreNames[4..<15]), Array(fresh.highScoreNames[3..<14]))
        XCTAssertEqual(Array(table.highScoreSectorNames[4..<15]), Array(fresh.highScoreSectorNames[3..<14]))
        var e = NameEntry(player: 0, slot: 3, prefs: table)
        let typed = Array(repeating: KeyEvent(charCode: 0x08, keyCode: 0x33), count: 20)
            + "DEIMOS".utf8.map { KeyEvent(charCode: $0, keyCode: 0) }
        for (t, keys) in [(UInt32(1_000), HeldKeys()), (1_001, HeldKeys(keyEvents: typed)), (1_032, HeldKeys())] {
            let s = e.pass(keys: keys, ticks: t, returned: nil, state: &state)
            XCTAssertNil(s.finished, "tick \(t): still typing")
            p.apply(s.output.ops)
        }
        XCTAssertTrue(e.editing)
        XCTAssertEqual(MacRoman.decode(e.buffer), "DEIMOS")
        XCTAssertEqual(MacRoman.decode(e.list.elements[4 + 4 * 3].record.text), "DEIMOS_", "the cursor shown")
        XCTAssertEqual(MacRoman.decode(e.list.elements[6 + 4 * 3].record.text), "Darius", "row 3's sector")
        let screen = p.screen
        assertSource(screen, try image("back"), [(5, 5), (634, 474), (5, 474), (634, 5)], "name entry")
        // Player 1's ship beside the row (gaob 0 → its player definition's high-score sprite and frame), centred on
        // the symbol's place as the layout puts it: x flli 80, y = flli 77 + 3 · flli 76 + flli 81.
        let def = try XCTUnwrap(a.definitions.players.first { $0.id == a.objects[0] }, "player 1's definition")
        let f = a.floats
        let rowY = EntityDraw.fctiwz(f[77]) + 3 * EntityDraw.fctiwz(f[76])
        try assertSprite(screen, def.spriteHighScore, frame: Int(def.spriteHighScoreFrame),
                         cx: Int(EntityDraw.fctiwz(f[80])), cy: Int(rowY + EntityDraw.fctiwz(f[81])),
                         "name entry: player 1's ship")
        golden(screen, "name-entry", 0xeabb_bed8_55a2_da9f)
    }

    /// The credits, through the front end: the settled menu, About (the menu bar's) on the next pass (the menu's
    /// fade-out; the menu calls the credits, but that pass drew, so the chain stops there), the credits' entry on the
    /// pass after (`back`, a full present), then one more pass: the first timeout reads page one and fades it in (16
    /// passes, X D1). The frame after that pass: page one fully faded in.
    func testGoldenCredits() throws {
        let a = try ShippedAssets.get()
        var run = try FrontEndRun(assets: a, prefs: .fresh, firstLaunch: false)
        run.bootToMenu()
        run.pass(HeldKeys(events: [.aboutChosen]))                      // the fade-out drew, the chain stops
        XCTAssertEqual(run.fe.screens, [.mainMenu, .credits], "About calls the credits")
        run.pass()                                                      // the credits' entry
        let page = run.pass()
        XCTAssertEqual(page.ops.filter { $0 == .hostWait(.ticks(60)) }.count, 1, "the 60-tick gap before page one")
        XCTAssertEqual(page.ops.filter { $0 == .hostWait(.ticks(1)) }.count, 15, "page one's 16-pass fade-in")
        XCTAssertEqual(run.fe.screens, [.mainMenu, .credits])
        let screen = run.painter.screen
        let back = try image("back")
        assertSource(screen, back, [(5, 5), (634, 474), (5, 474), (634, 5)], "credits")
        // Page one's title, read from `stli cred`: page one's lines run to the first "<page " line; the first holding
        // "<title>" is drawn in format 8 `crti` with the text after the tag, at Loc Y flli 74 + flli 75 · (its line).
        let cred = try a.credits().lines
        func find(_ tag: String, _ s: [UInt8]) -> Int? {
            let t = Array(tag.utf8)
            guard s.count >= t.count else { return nil }
            return (0...(s.count - t.count)).first { s[$0..<($0 + t.count)].elementsEqual(t) }
        }
        var title: TextRequest?
        for (k, l) in cred.prefix(64).enumerated() {                    // bound: 64 lines
            if l.isEmpty || find("<page ", l) != nil { break }
            if let at = find("<title>", l) {
                var t = TextRequest(format: a.formats[8], text: Array(l[(at + 7)...]))
                t.format.locY = EntityDraw.fctiwz(a.floats[74]) &+ Int32(k) &* EntityDraw.fctiwz(a.floats[75])
                title = t
                break
            }
        }
        let pageTitle = try XCTUnwrap(title, "page one has a <title> line")
        try assertTextDrawn(screen, pageTitle, unlike: { back.pixels[$1 * 640 + $0] }, "credits: page one's title")
        golden(screen, "credits", 0xbda0_d9e0_0fcd_3f1a)
    }

    /// The configuration window (DLOG/DITL 190), through the front end with the resource fork handed in: the settled
    /// menu, `P` on the next pass (the PREFERENCES flash, then `ConfigDialog(firstLaunch: false)` chained: the picture
    /// under the window saved, the window drawn, its rect blitted). The frame after that pass: the window centred over
    /// the menu, fresh settings, Save the default, Revert grey. Plus Geneva 9's `S` pinned bit by bit, and found on
    /// the screen at the start of the Save button's title.
    func testGoldenConfigWindow() throws {
        let a = try ShippedAssets.get()
        let res = try Self.fork.get()
        var run = try FrontEndRun(assets: a, prefs: Self.bootedPrefs, firstLaunch: false, shellResources: res)
        run.bootToMenu()
        run.pass(Self.key(0x50, 0x23))                                  // 'P': the flash drew, the chain stops
        XCTAssertEqual(run.fe.screens, [.mainMenu, .configDialog], "P calls the configuration window")
        run.pass()                                                      // the window's opening pass
        let screen = run.painter.screen

        // Geneva 9 `S` (0x53), as Apple's strike holds it.
        let font = DialogFont.geneva9
        let g = font.glyph(0x53)
        let bitmap = [".###.",
                      "#...#",
                      "#....",
                      ".###.",
                      "....#",
                      "#...#",
                      ".###."]
        XCTAssertEqual([g.advance, g.left, g.top, g.width], [6, 0, -7, 5], "S: advance, left, top, width")
        XCTAssertEqual(g.rows.count, bitmap.count)
        for (i, row) in bitmap.enumerated() where i < g.rows.count {
            let bits = (0..<5).map { g.rows[i] & (0x8000 >> UInt16($0)) != 0 ? "#" : "." }.joined()
            XCTAssertEqual(bits, row, "S row \(i)")
        }

        // On the screen: item 1 "Save" (DITL 190), centred in DLOG 190's rect (the window's own placement).
        let dlog = try DialogTemplate.load(190, from: res)
        let ditl = try DialogItemList.load(dlog.itemsID, from: res)
        let content = DialogDraw.centred(dlog.bounds)
        let save = try XCTUnwrap(ditl[1])
        XCTAssertEqual(MacRoman.decode(save.text), "Save")
        XCTAssertEqual(save.kind, .button)
        let r = DialogDraw.offset(save.rect, by: MousePoint(h: content.left, v: content.top))
        // This position repeats the window's own centring rule (title centred in the button, baseline from the line
        // height); the independent check is the glyph's bits, pinned above from Apple's strike.
        let x = r.left + (r.right - r.left - font.width(save.text)) / 2
        let baseline = r.top + (r.bottom - r.top - font.lineHeight) / 2 + font.ascent
        for (i, row) in bitmap.enumerated() {
            for (k, ch) in row.enumerated() {
                let px = Int(x + g.left) + k, py = Int(baseline + g.top) + i
                XCTAssertEqual(screen[px, py], ch == "#" ? DialogDraw.Colour.text : DialogDraw.Colour.white,
                               "Save's S at (\(px), \(py))")
            }
        }
        // Outside the window: the menu's `back`.
        let frame = DialogDraw.frameRect(content: content)
        let outside = [(20, 20), (600, 300), (630, 5), (60, 460)]
        for (px, py) in outside {
            XCTAssertFalse(DialogDraw.contains(frame, MousePoint(h: Int32(px), v: Int32(py))), "(\(px), \(py)) outside")
        }
        assertSource(screen, try image("back"), outside, "config window")
        golden(screen, "config-window", 0x31a7_474c_d484_cbd7)
    }

    /// The controls window (DLOG/DITL 191), Player 1 tab: as `testGoldenConfigWindow`, then on the next pass a click
    /// (pressed and released in the pass) on "Set Controls…" (item 18): the configuration window calls
    /// `ControlsDialog()`, whose opening pass draws over it (it saves nothing). The frame after that pass: both windows,
    /// the controls window on top, Player 1's fresh keys, field 5 focused.
    ///
    /// **The pictures are made up.** PICT 190–197 come from the shell in the app (HectorKit decodes them); this target
    /// has no PICT decoder and must not gain one, so the test hands in deterministic patterns instead — each picture
    /// the size of its DITL 191 item, pixel (x, y) = (id·977 + x·31 + y·131) & 0x7FFF; PICT 194 (which DITL 191 does
    /// not use) 16 × 16. The golden therefore pins the window's drawing, not the real artwork.
    func testGoldenControlsWindow() throws {
        let res = try Self.fork.get()
        var a = try ShippedAssets.get()
        let dlog = try DialogTemplate.load(191, from: res)
        let ditl = try DialogItemList.load(dlog.itemsID, from: res)
        func pattern(_ id: Int16, _ w: Int, _ h: Int) throws -> ShellPicture {
            let px = (0..<(w * h)).map { UInt16((Int(id) * 977 + ($0 % w) * 31 + ($0 / w) * 131) & 0x7FFF) }
            return try XCTUnwrap(ShellPicture(width: w, height: h, pixels: px), "PICT \(id)")
        }
        let pictureItems = ditl.items.filter { $0.kind == .picture }
        XCTAssertEqual(pictureItems.compactMap(\.resourceID).sorted(), [190, 191, 192, 193, 195, 196, 197])
        var pictures: [Int16: ShellPicture] = [194: try pattern(194, 16, 16)]
        for item in pictureItems {
            let id = try XCTUnwrap(item.resourceID)
            pictures[id] = try pattern(id, Int(item.rect.right - item.rect.left), Int(item.rect.bottom - item.rect.top))
        }
        a.shellPictures = pictures

        var run = try FrontEndRun(assets: a, prefs: Self.bootedPrefs, firstLaunch: false, shellResources: res)
        run.bootToMenu()
        run.pass(Self.key(0x50, 0x23))                                  // 'P': the flash drew, the chain stops
        XCTAssertEqual(run.fe.screens, [.mainMenu, .configDialog])
        run.pass()                                                      // the configuration window's opening pass
        let configDLOG = try DialogTemplate.load(190, from: res)
        let configItems = try DialogItemList.load(configDLOG.itemsID, from: res)
        let configContent = DialogDraw.centred(configDLOG.bounds)
        let setControls = try XCTUnwrap(configItems[18])
        XCTAssertEqual(MacRoman.decode(setControls.text), "Set Controls…")
        let sc = DialogDraw.offset(setControls.rect, by: MousePoint(h: configContent.left, v: configContent.top))
        let at = MousePoint(h: (sc.left + sc.right) / 2, v: (sc.top + sc.bottom) / 2)
        run.pass(HeldKeys(mouse: at, mouseButton: false, mouseDowns: [at]))
        XCTAssertEqual(run.fe.screens, [.mainMenu, .configDialog, .controlsDialog], "Set Controls… opens the window")
        // The window's own state, read off the front end's stack (private: through `Mirror`): Player 1's tab up,
        // field 5 focused and shown selected.
        let stack = try XCTUnwrap(Mirror(reflecting: run.fe).children.first { $0.label == "stack" }?.value
                                  as? [FrontEndScreen], "the front end's screen stack")
        guard case let .controlsDialog(dialog)? = stack.last else { return XCTFail("the controls window on top") }
        XCTAssertEqual(dialog.phase, .running)
        XCTAssertEqual(dialog.player, 0, "the Player 1 tab is up")
        XCTAssertEqual(dialog.tabNames.first.map { MacRoman.decode($0) }, "Player 1")
        XCTAssertEqual(dialog.focus, 5, "keys go to field 5")
        XCTAssertEqual(dialog.shown, 5, "field 5 shown selected")
        let screen = run.painter.screen

        // Each picture at its item's top left, at its own size: two of its pixels (the handed-in source image).
        let content = DialogDraw.centred(dlog.bounds)
        for item in pictureItems {
            let id = try XCTUnwrap(item.resourceID)
            let pic = try XCTUnwrap(pictures[id])
            let r = DialogDraw.offset(item.rect, by: MousePoint(h: content.left, v: content.top))
            for (i, j) in [(0, 0), (pic.width / 2, pic.height / 2)] {
                XCTAssertEqual(screen[Int(r.left) + i, Int(r.top) + j], pic.pixels[j * pic.width + i],
                               "PICT \(id) (\(i), \(j))")
            }
        }
        // Outside both windows: the menu's `back`.
        let outside = [(20, 20), (630, 5), (10, 470)]
        for (px, py) in outside {
            let p = MousePoint(h: Int32(px), v: Int32(py))
            XCTAssertFalse(DialogDraw.contains(DialogDraw.frameRect(content: content), p), "(\(px), \(py)) outside")
            XCTAssertFalse(DialogDraw.contains(DialogDraw.frameRect(content: configContent), p), "(\(px), \(py)) outside")
        }
        assertSource(screen, try image("back"), outside, "controls window")
        golden(screen, "controls-window", 0x802d_803f_54f8_106c)
    }
}
