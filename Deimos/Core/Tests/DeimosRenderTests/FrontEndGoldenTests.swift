import XCTest
import HectorResources
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
    private func image(_ id: String) throws -> TGAImage {
        let index = try ShippedAssets.get().index
        guard let r = index.record(type: FourCC("im16")!, id: FourCC(id)!) else {
            throw DeimosAssetsError.missingTag(type: "im16", id: id)
        }
        return try TGAImage(data: index.data(for: r))
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
        dump(screen, name)
        XCTAssertEqual(h, expected, "golden \(name): 0x\(String(h, radix: 16))", file: file, line: line)
    }

    private func dump(_ s: Pixmap555, _ name: String) {
        guard let folder = ProcessInfo.processInfo.environment["DEIMOS_FRAME_DUMP"], !folder.isEmpty else { return }
        let dir = URL(fileURLWithPath: folder, isDirectory: true).appendingPathComponent("front-end", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        var bytes = Array("P6\n\(s.width) \(s.height)\n255\n".utf8)
        bytes.reserveCapacity(bytes.count + 3 * s.pixels.count)
        for p in s.pixels {
            for c in [(p >> 10) & 31, (p >> 5) & 31, p & 31] { bytes.append(UInt8((c << 3) | (c >> 2))) }
        }
        try? Data(bytes).write(to: dir.appendingPathComponent("\(name).ppm"))
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
    /// Fresh prefs, sound on, no resource fork (the first launch's configuration window, called inside the first pass,
    /// finishes at once without its resources and draws nothing).
    func testGoldenLoadingScreen() throws {
        let goldens: [Bool: UInt64] = [true: 0x8125_7f2c_fe53_c80a, false: 0x68eb_9c48_4401_256c]
        let presentsAt: [Bool: Int] = [true: 135, false: 44]
        let a = try ShippedAssets.get()
        let back = try image("back")
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
            for op in out.ops {                                         // bounded by the pass's own ops
                run.painter.apply(op)
                if op == .present(.fullScreen) {
                    n += 1
                    if n == presentsAt[first] { shot = run.painter.screen; break }
                }
            }
            let screen = try XCTUnwrap(shot, "\(label): update \(presentsAt[first]!) not reached")
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
        golden(p.screen, "level-select-fail", goldens["level-select-fail"]!)
    }

    /// The high scores, through the front end: the settled menu, then `S` on the next pass (the SCORES flash, the
    /// menu's fade-out, the scores screen's entry chained in the same pass). The frame after that pass: `back`, the
    /// fresh prefs' default table (`DeimosPrefs.fresh`: 15 rows, "Name" / "Score" / "Sector"), no row lit.
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
        assertSource(screen, try image("back"), [(5, 5), (634, 474), (5, 474), (634, 5)], "scores")
        golden(screen, "scores", 0xe358_623a_a035_cfff)
    }

    /// Name entry (stepped directly; player 1, row 3, fresh prefs, `fromGame`): the entry pass at tick 1,000; at
    /// 1,001 twenty Backspaces clear the pre-filled "Player 1" and "DEIMOS" is typed (the cursor hidden by the keys);
    /// at 1,032 the blink (30 ticks after the last key, 10 after the last flip) shows the cursor. The frame after that
    /// pass: row 3 lit with player 1's ship, its name "DEIMOS_" — cursor SHOWN.
    func testGoldenNameEntry() throws {
        let a = try ShippedAssets.get()
        let p = Painter(a)
        var state = try FrontEndState(assets: a, prefs: .fresh)
        var e = NameEntry(player: 0, slot: 3, prefs: .fresh)
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
        let screen = p.screen
        assertSource(screen, try image("back"), [(5, 5), (634, 474), (5, 474), (634, 5)], "name entry")
        golden(screen, "name-entry", 0x0e27_d358_3cb3_4d93)
    }

    /// The credits, through the front end: the settled menu, About (the menu bar's) on the next pass (the menu's
    /// fade-out, the credits' entry chained: `back`, a full present), then one more pass: the first timeout reads page
    /// one and fades it in (16 passes, X D1). The frame after that pass: page one fully faded in.
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
        assertSource(screen, try image("back"), [(5, 5), (634, 474), (5, 474), (634, 5)], "credits")
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
