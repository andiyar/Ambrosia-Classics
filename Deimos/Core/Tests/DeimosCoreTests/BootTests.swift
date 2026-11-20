import XCTest
@testable import DeimosCore
import HectorResources

/// Phase 4 S6 BT — the boot `FUN_100000e0` (grounding A §1, §9a items 1 and 7; the same in the OS X build: X
/// `100000e0` matches L instruction for instruction but for TOC offsets, `osx-build.md` §2). The screen is stepped pass
/// by pass without a host; each pass is given the tick at which the host would begin it (the original's `TickCount`
/// read straight after a fade or a wait). Every loop names its bound and fails on it (G11).
final class BootTests: XCTestCase {
    private func assets() throws -> DeimosAssets { try TestAssets.loaded.get() }

    private static let full = MacRect(top: 0, left: 0, bottom: 480, right: 640)
    /// `pucr` (260 × 342) centred in the 640 × 480 back buffer (`FUN_1000a3b0`): left (640 − 260) / 2,
    /// top (480 − 342) / 2.
    private static let pucrRect = MacRect(top: 69, left: 190, bottom: 411, right: 450)
    private static let publ = SoundPlay.perm(FourCC("publ")!, priority: 0x32, volume: 100, allowMultiple: true)
    private static let inmu = MusicCue.play(FourCC("inmu")!, loop: true)
    /// The loading-line restore (`FUN_10009fd0(D+0x6c, D+0x68, bounds, bounds, 0)`): the whole save buffer → back.
    private static let restore = RenderOp.copy(from: .terrain, to: .back, src: full, dst: full, interlaced: false)
    /// Bound on the passes of one boot (six are expected).
    private static let maxPasses = 12

    // The pinned timeline: pass 1 at t0; the publisher logo's pass at T1 (after the 5-tick wait and the fade);
    // its hold's pass at T1 + 9 (after the 9-step fade-in); the developer logo's pass at T2; its hold's at T2 + 9.
    private static let t0: UInt32 = 1_000, t1: UInt32 = 1_040, t2: UInt32 = 1_400

    private struct Run {
        var boot = Boot()
        var state: FrontEndState
    }

    private func run(_ a: DeimosAssets, volume: Int32 = 100, pref2: UInt8 = 1,
                     launch: LaunchModifiers = LaunchModifiers(), sound: Bool = true) throws -> Run {
        var prefs = DeimosPrefs.fresh
        prefs.intPrefs[0] = volume
        prefs.bytePrefs[2] = pref2
        return Run(state: try FrontEndState(assets: a, prefs: prefs, launch: launch, soundAvailable: sound))
    }

    private func step(_ r: inout Run, _ t: UInt32, returned: ScreenResult? = nil) -> ScreenStep<ScreenDone> {
        r.boot.pass(keys: HeldKeys(), ticks: t, returned: returned, state: &r.state)
    }

    /// The five passes of a boot with no configuration window, at the pinned ticks (the hold passes at `hold1` /
    /// `hold2`); then the finishing pass. Returns the six steps.
    private func boot(_ r: inout Run, hold1: UInt32 = t1 + 9, hold2: UInt32 = t2 + 9) -> [ScreenStep<ScreenDone>] {
        var steps: [ScreenStep<ScreenDone>] = []
        for t in [Self.t0, Self.t1, hold1, Self.t2, hold2, hold2 + 5_000] {
            guard steps.count < Self.maxPasses else { XCTFail("more than \(Self.maxPasses) passes"); break }
            steps.append(step(&r, t))
            if steps.last?.finished != nil { break }
        }
        return steps
    }

    /// The ops of the developer-logo hold's pass after its fade in of `back`: the loading lines and their fade-out.
    private func loading(_ s: ScreenStep<ScreenDone>) -> [RenderOp] {
        guard let i = s.output.ops.lastIndex(of: .fade(.fromBlack, .fullScreen)) else {
            XCTFail("no fade in of the loading screen")
            return []
        }
        return Array(s.output.ops[(i + 1)...])
    }

    // MARK: - The loading lines the listing writes, from the shipped data

    private static let spriteNames = ["Video Grid", "Editor Utility", "Player 1 Orange", "Menu Buttons",
                                      "Menu Buttons Hilit", "Game Logo", "Menu Buttons", "Menu Buttons Hilit"]
    /// `gaso` 0…23 less its three `none` ids (`FUN_1001f950` false for `none`: no line), in order.
    private static let soundNames = ["Click", "Click", "Interface Click", "Transition", "Interface Click",
                                     "Lev Sel No Access", "Level End", "Interface Click", "Interface Click",
                                     "Level End", "Menu Button Rollover", "Lev Sel Select", "Lev Sel Change",
                                     "Lev Sel No Access", "Shield Warning", "Cash Bonus", "Weapon Switch",
                                     "Money Count", "No Bonus", "Accuracy Bonus", "Mission Accuracy"]
    private static let weaponNames = ["Air - Bacta Gun", "Air - Ion Cannon", "Air - Photon Beam", "Air - Rear Gun",
                                      "Ground - Plasma Bomb"]
    private static let playerNames = ["Player 1", "Player 2"]
    private static let doneLines = ["Loading Permanent Image:  Done", "Loading Permanent Sound:  Done",
                                    "Unpacking Unit:  Done", "Loading Weapon:  Done", "Loading Player:  Done"]

    /// Every `FUN_10023040` call of the boot, in order: (text, new line).
    private func script(_ a: DeimosAssets, sound: Bool) -> [(text: String, newLine: Bool)] {
        var calls: [(String, Bool)] = []
        func line(_ head: String, _ items: [String], _ done: String) {
            calls.append((head, true))
            calls += items.map { (head + $0, false) }
            calls.append((done, false))
        }
        line("Loading Permanent Image:  ", Self.spriteNames, Self.doneLines[0])
        if sound {
            line("Loading Permanent Sound:  ", Self.soundNames, Self.doneLines[1])
        } else {
            calls.append(("Loading Permanent Sound:  ", true))
            calls.append(("Sound System Not Available", false))
            calls.append((Self.doneLines[1], false))
        }
        let units = a.index.records(ofType: FourCC("unde")!).map(\.displayName)
        line("Unpacking Unit:  ", units, Self.doneLines[2])
        line("Loading Weapon:  ", Self.weaponNames, Self.doneLines[3])
        line("Loading Player:  ", Self.playerNames, Self.doneLines[4])
        return calls
    }

    /// Line i's record: format 0 `prog` at y 100 + 20·i (flli 64), shadows off.
    private static func record(_ a: DeimosAssets, _ i: Int, _ text: String, blend: Int32 = 0) -> TextRequest {
        var r = TextRequest(format: a.formats[0], text: text)
        r.format.locY = 100 + 20 * Int32(i)
        r.format.drawShadows = false
        r.format.blendAmount = blend
        return r
    }

    /// The ops of the calls (A §1 "Loading lines"): the whole back buffer restored, every line drawn — a new line's
    /// first draw being the one-element fade from blend 0x20, a rewrite drawn at once — and a full present.
    private func expected(_ a: DeimosAssets, _ text: TextLayout,
                          _ calls: [(text: String, newLine: Bool)]) -> [RenderOp] {
        var ops: [RenderOp] = []
        var texts: [String] = []
        for c in calls {
            ops.append(Self.restore)
            if c.newLine { texts.append("") }
            texts[texts.count - 1] = c.text
            for (i, s) in texts.enumerated() {
                if i == texts.count - 1 && c.newLine {
                    ops += ElementList.fadeOne(Self.record(a, i, s, blend: 0x20), text: text)
                } else {
                    ops += text.draw(Self.record(a, i, s)).map { .draw($0) }
                }
            }
            ops.append(.present(.fullScreen))
        }
        return ops
    }

    // MARK: - Tests

    /// A §1 in order, sound on and Command up (`100000e0`): the configuration window first when byte pref 2 is 0 or
    /// Option is held (`FUN_100047c0(1)`, then byte pref 2 ← 1); the 5-tick wait and the fade to black (mode 0); back ←
    /// black, `pucr` centred at (190, 69); the volume up then down (100 → 90, 95 → 90, 50 → 50, 0 → 0); T1; `publ`
    /// (0x32, 100, multiple); the fade in; the hold until `publ`'s voice ends (no floor, no cap); the fade; back ←
    /// black, PICT 1000 at (0, 0); `inmu` looping; T2; the fade in; the hold to T2 + 240; the fade; back ← black,
    /// `back` into the back buffer and the save buffer; the fade in; the loading lines; then the return, a pass later.
    func testBootSequenceOps() throws {
        let a = try assets()

        // The configuration window: byte pref 2 = 0, or Option held.
        for (pref2, option, label) in [(UInt8(0), false, "first launch"), (1, true, "Option held"),
                                       (0, true, "both")] {
            var r = try run(a, pref2: pref2, launch: LaunchModifiers(option: option))
            let first = step(&r, Self.t0)
            guard case let .call(screen) = first.next, case let .configDialog(dialog) = screen else {
                XCTFail("\(label): the configuration window is called first")
                continue
            }
            XCTAssertTrue(dialog.firstLaunch, "\(label): FUN_100047c0(1)")
            XCTAssertEqual(first.output, PassOutput(), "\(label): before the display")
            let back = step(&r, Self.t0, returned: .configDialog(false))
            XCTAssertEqual(back.output.ops, [.hostWait(.ticks(5)), .fade(.toBlack, .fullScreen)], label)
            XCTAssertNil(back.callee, label)
            XCTAssertEqual(r.state.prefs.bytePrefs[2], 1, "\(label): FUN_10004ab0(2, 1)")
        }

        var r = try run(a)
        let steps = boot(&r)
        XCTAssertEqual(steps.count, 6)
        guard steps.count == 6 else { return }
        for (i, s) in steps.enumerated() {
            XCTAssertNil(s.callee, "pass \(i + 1): no window when byte pref 2 is 1 and Option is up")
            XCTAssertEqual(s.output.requests, [], "pass \(i + 1)")
            XCTAssertEqual(s.finished != nil, i == 5, "pass \(i + 1)")
        }
        XCTAssertEqual(steps[0].output, PassOutput(ops: [.hostWait(.ticks(5)), .fade(.toBlack, .fullScreen)]))
        XCTAssertEqual(steps[1].output, PassOutput(ops: [.fill(.back, colour: 0),
                                                         .loadImage(image: FourCC("pucr")!, into: .back,
                                                                    dst: Self.pucrRect),
                                                         .fade(.fromBlack, .fullScreen)],
                                                   sounds: [Self.publ]))
        XCTAssertEqual(steps[2].output, PassOutput(ops: [.hostWait(.voiceEnd(FourCC("publ")!)),
                                                         .fade(.toBlack, .fullScreen), .fill(.back, colour: 0),
                                                         .drawPicture(id: 1000, into: .back, top: 0, left: 0)]))
        XCTAssertEqual(steps[3].output, PassOutput(ops: [.fade(.fromBlack, .fullScreen)], music: [Self.inmu]))
        let hold = steps[4].output
        XCTAssertEqual(Array(hold.ops.prefix(6)),
                       [.hostWait(.ticks(231)), .fade(.toBlack, .fullScreen), .fill(.back, colour: 0),
                        .loadImage(image: FourCC("back")!, into: .back, dst: Self.full),
                        .loadImage(image: FourCC("back")!, into: .terrain, dst: Self.full),
                        .fade(.fromBlack, .fullScreen)], "T2 + 240 − (T2 + 9) = 231")
        XCTAssertEqual(hold.sounds, [])
        XCTAssertEqual(hold.music, [])
        XCTAssertFalse(loading(steps[4]).isEmpty, "the loading lines follow in the same pass")
        XCTAssertEqual(steps[5].output, PassOutput(), "the return, after the loading lines' fade-out")
        XCTAssertEqual(r.state.prefs.intPrefs[0], 90, "the volume 100 → 90")
        XCTAssertEqual(r.state.prefs.bytePrefs[2], 1)

        // The hold to T2 + 240 when the pass comes late: no wait.
        var late = try run(a)
        let lateSteps = boot(&late, hold2: Self.t2 + 300)
        XCTAssertEqual(lateSteps.count, 6)
        if lateSteps.count == 6 { XCTAssertEqual(lateSteps[4].output.ops.first, .hostWait(.ticks(0))) }

        // The volume is quantised to a step of 10 below 100 (FUN_10047a30 then FUN_10047990).
        for (v, w) in [(Int32(100), Int32(90)), (95, 90), (50, 50), (0, 0), (91, 90)] {
            var q = try run(a, volume: v)
            _ = step(&q, Self.t0)
            _ = step(&q, Self.t1)
            XCTAssertEqual(q.state.prefs.intPrefs[0], w, "volume \(v)")
        }
    }

    /// The quiet launch (Command held at `1000016c`): no `publ` (`10000350`), the publisher logo held to T1 + flli 66
    /// (130) (`10000408..10000430`), no `inmu` (`10000480`); everything else as usual, the volume step included.
    func testBootQuietLaunch() throws {
        let a = try assets()
        var r = try run(a, launch: LaunchModifiers(command: true))
        let steps = boot(&r)
        XCTAssertEqual(steps.count, 6)
        guard steps.count == 6 else { return }
        XCTAssertEqual(steps[1].output.sounds, [], "no publ")
        XCTAssertEqual(steps[1].output.ops.last, .fade(.fromBlack, .fullScreen))
        XCTAssertEqual(steps[2].output.ops, [.hostWait(.ticks(121)), .fade(.toBlack, .fullScreen),
                                             .fill(.back, colour: 0),
                                             .drawPicture(id: 1000, into: .back, top: 0, left: 0)],
                       "T1 + 130 − (T1 + 9)")
        XCTAssertEqual(steps[3].output.music, [], "no inmu")
        XCTAssertEqual(steps[3].output.ops, [.fade(.fromBlack, .fullScreen)])
        XCTAssertEqual(steps[4].output.ops.first, .hostWait(.ticks(231)))
        for s in steps { XCTAssertEqual(s.output.sounds, []); XCTAssertEqual(s.output.music, []) }
        XCTAssertEqual(r.state.prefs.intPrefs[0], 90, "the volume step is not the quiet launch's")
        XCTAssertNotNil(steps[5].finished)

        // A late hold pass: the 130 are already over.
        var late = try run(a, launch: LaunchModifiers(command: true))
        let lateSteps = boot(&late, hold1: Self.t1 + 130)
        XCTAssertEqual(lateSteps.count, 6, "a late hold pass at T1 + 130: six passes")
        if lateSteps.count == 6 { XCTAssertEqual(lateSteps[2].output.ops.first, .hostWait(.ticks(0))) }
        var later = try run(a, launch: LaunchModifiers(command: true))
        let laterSteps = boot(&later, hold1: Self.t1 + 129)
        XCTAssertEqual(laterSteps.count, 6, "a late hold pass at T1 + 129: six passes")
        if laterSteps.count == 6 { XCTAssertEqual(laterSteps[2].output.ops.first, .hostWait(.ticks(1))) }
    }

    /// No sound system (`FUN_10047910` false): the volume keys do nothing (`FUN_10047a30` / `FUN_10047990` test it),
    /// `publ` is not loaded (`FUN_10047330`) so not played, the hold is the 130 ticks, not `publ`'s voice; `inmu` still
    /// goes (the music player has no such test, `FUN_10047f90`); the sound line reads "Sound System Not Available".
    func testBootNoSound() throws {
        let a = try assets()
        var r = try run(a, sound: false)
        let steps = boot(&r)
        XCTAssertEqual(steps.count, 6)
        guard steps.count == 6 else { return }
        XCTAssertEqual(steps[1].output.sounds, [], "no publ")
        XCTAssertEqual(steps[2].output.ops.first, .hostWait(.ticks(121)), "not publ's voice")
        XCTAssertFalse(steps[2].output.ops.contains(.hostWait(.voiceEnd(FourCC("publ")!))))
        XCTAssertEqual(steps[3].output.music, [Self.inmu])
        XCTAssertEqual(r.state.prefs.intPrefs[0], 100, "no volume step")
        let ops = loading(steps[4])
        let calls = script(a, sound: false)
        XCTAssertEqual(calls.count, 432 - 21 + 1)
        let lines = expected(a, r.state.text, calls)
        XCTAssertEqual(Array(ops.prefix(lines.count)), lines)
    }

    /// The loading lines (A §1; `FUN_10023040`, X `100233c0` the same but for a suspend/resume pump, D17): format 0
    /// `prog` (x 50, y 100, left), line i at y 100 + 20·i (flli 64); each call restores the whole back buffer from the
    /// save buffer, redraws every line and presents the full screen; a new line's first draw is the one-element fade
    /// (blend 0x20 → 32 passes, one tick apart); rewrites draw at once. Five lines: 8 images, 21 sounds (`gaso` less
    /// its three `none`), 386 units ("Unpacking Unit:  ", hard-coded), 5 weapons, 2 players — 422 names, 432 calls,
    /// one screen update each. Then `FUN_100232d0`: the list's fade-out — 16 passes in the OS X build (D1, X
    /// `100236c0` → `1000e180`).
    func testLoadingLines() throws {
        let a = try assets()
        var r = try run(a)
        let steps = boot(&r)
        guard steps.count == 6 else { return XCTFail("six passes") }
        let ops = loading(steps[4])
        let text = r.state.text

        XCTAssertEqual(a.formats[0].locX, 50)
        XCTAssertEqual(a.formats[0].locY, 100)
        let calls = script(a, sound: true)
        XCTAssertEqual(calls.count, 432)
        XCTAssertEqual(calls.filter(\.newLine).count, 5)
        XCTAssertEqual(calls[1].text, "Loading Permanent Image:  Video Grid", "the im08 name less \" IC\"")
        XCTAssertEqual(calls[33].text, "Unpacking Unit:  ", "two spaces")
        // The units' order, pinned apart from the index call `script` shares with the boot: the display names of
        // unde 0, 100, 250 and 385 as read from Resources/Deimos/Data/Paks/Game.pak's zip directory (`unzip -Z1`,
        // the `unde/` entries in order: ` NULL[NULL]`, `Juno Gun - Bullet Hi[jgbh]`, `Platform - Laser Bul[plbh]`,
        // `Random Bonus - Enemy[rben]`; the first and last also open and close the unde rows of
        // docs/deimos/data-census.md).
        XCTAssertEqual(calls[34].text, "Unpacking Unit:   NULL", "the first unde's display name")
        XCTAssertEqual(calls[134].text, "Unpacking Unit:  Juno Gun - Bullet Hi", "unde 100")
        XCTAssertEqual(calls[284].text, "Unpacking Unit:  Platform - Laser Bul", "unde 250")
        XCTAssertEqual(calls[419].text, "Unpacking Unit:  Random Bonus - Enemy", "the last unde (385)")

        let lines = expected(a, text, calls)
        XCTAssertEqual(ops.filter { $0 == .present(.fullScreen) }.count, 432, "one screen update per call")
        XCTAssertEqual(Array(ops.prefix(lines.count)), lines)

        // The first call: restore, the 32-pass fade of line 0 from blend 0x20, present.
        let first = ElementList.fadeOne(Self.record(a, 0, "Loading Permanent Image:  ", blend: 0x20), text: text)
        XCTAssertEqual(first.filter { if case .screenBlit = $0 { return true } else { return false } }.count, 32)
        XCTAssertEqual(first.filter { $0 == .hostWait(.ticks(1)) }.count, 31)
        XCTAssertEqual(Array(ops.prefix(first.count + 2)), [Self.restore] + first + [.present(.fullScreen)])
        // A rewrite of the same line: drawn at once.
        let second = [Self.restore] + text.draw(Self.record(a, 0, "Loading Permanent Image:  Video Grid")).map {
            RenderOp.draw($0) } + [.present(.fullScreen)]
        XCTAssertEqual(Array(ops[(first.count + 2)..<(first.count + 2 + second.count)]), second)

        // The end: the five finished lines fade out (16 passes, rate flli 160 = 1).
        let final = ElementList(Self.doneLines.enumerated().map { .text(Self.record(a, $0.offset, $0.element)) })
        let out = final.fadeOut(rate: ElementList.fadeRate(floats: a.floats), text: text, assets: a)
        XCTAssertEqual(out.filter { if case .screenBlit = $0 { return true } else { return false } }.count, 16 * 5)
        XCTAssertEqual(Array(ops.suffix(from: lines.count)), out, "the loading lines end with their fade-out")
        XCTAssertEqual(r.boot.lines.count, 0, "the list is freed (FUN_100253d0)")
    }
}
