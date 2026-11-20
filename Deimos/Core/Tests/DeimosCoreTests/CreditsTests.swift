import XCTest
@testable import DeimosCore
import HectorResources

/// Phase 4 S2 CR — the credits `FUN_10025b90('cred')` as the OS X build runs it (X `10025f50`; grounding A §4, §6,
/// §10; `front-end.md` §6; `osx-build.md` D1, D24). The screen is stepped pass by pass without a host; `step(_:)`
/// plays the host's part for the clock: a pass's ops end after its tick waits, and the next pass begins at that tick
/// (or one tick on, after a pass with no wait) — the original's `TickCount` read straight after a fade or a wait.
/// Every loop names its bound and fails on it (G11).
final class CreditsTests: XCTestCase {
    private func assets() throws -> DeimosAssets { try TestAssets.loaded.get() }

    private static let full = MacRect(top: 0, left: 0, bottom: 480, right: 640)
    /// The ten pages' titles (`<title>` lines 0, 8, 15, 19, 25, 42, 53, 61, 68, 85).
    private static let titles = ["Swoop Software", "Additional Unit Art", "Music", "Mac OS X Support", "Geek Support",
                                 "Ambrosia Software", "Special Thanks", "Chief Testers", "Testers", "Testers"]
    /// How long each page stays up: its `<page n>` line's n — except page 10, whose build stops at the empty line 99
    /// before its `<page 420>` (line 100) is read, and which keeps page 9's 420 (the stale time).
    private static let times: [UInt32] = [200, 210, 120, 120, 420, 300, 240, 240, 420, 420]
    /// The number of lines on each page (the `cred` lines between two `<page>` lines; page 10: lines 85–98).
    private static let counts = [7, 6, 3, 5, 16, 10, 7, 6, 16, 14]
    /// The pages' length in ticks bounds every run here (≈ 3,700 ticks from entry to the end; G11).
    private static let maxTicks: UInt32 = 6_000

    private static func incl(_ a: DeimosAssets) -> SoundCue {
        SoundPlay.perm(a.sounds[2], priority: 0x32, volume: 100, allowMultiple: true)
    }
    private static func key(_ c: UInt8, repeating: Bool = false) -> HeldKeys {
        HeldKeys(keyEvents: [KeyEvent(charCode: c, keyCode: 0, autoRepeat: repeating)])
    }
    private static let click = HeldKeys(mouseDowns: [MousePoint(h: 320, v: 240)])

    private func tickWaits(_ ops: [RenderOp]) -> UInt32 {
        ops.reduce(0) { if case let .hostWait(.ticks(n)) = $1 { return $0 + n } else { return $0 } }
    }

    private struct Run {
        var credits = Credits()
        var state: FrontEndState
        var t: UInt32
    }

    /// A fresh state and a credits screen whose entry pass ran at `t0`; the next pass is due at `t0 + 1`.
    private func entered(_ a: DeimosAssets, t0: UInt32 = 10_000, keys: HeldKeys = HeldKeys()) throws
        -> (run: Run, entry: ScreenStep<Credits.Exit>) {
        var run = Run(state: try FrontEndState(assets: a, prefs: .fresh, soundAvailable: true), t: t0)
        let entry = step(&run, keys)
        return (run, entry)
    }

    /// One pass at `run.t`; then the clock moves to the tick at which the host would begin the next pass.
    private func step(_ run: inout Run, _ keys: HeldKeys = HeldKeys()) -> ScreenStep<Credits.Exit> {
        let s = run.credits.pass(keys: keys, ticks: run.t, returned: nil, state: &run.state)
        let waits = tickWaits(s.output.ops)
        run.t &+= waits == 0 ? 1 : waits
        return s
    }

    /// Step with no input until a pass's ops hold the 60-tick wait (a page change); that pass is returned, the clock
    /// at the pass after it. Fails on the bound.
    private func toPageChange(_ run: inout Run, bound: UInt32) -> (tick: UInt32, step: ScreenStep<Credits.Exit>)? {
        while run.t < bound {
            let at = run.t
            let s = step(&run)
            if s.output.ops.contains(.hostWait(.ticks(60))) { return (at, s) }
            if s.finished != nil { XCTFail("finished at \(at) before a page change"); return nil }
        }
        XCTFail("no page change before tick \(bound)")
        return nil
    }

    // MARK: - Paging

    /// The pages (A §4; `FUN_10025b90`, X `10025f50`): the entry (back ← black, `back`, back → save {0, 0, 480, 640},
    /// a full present, FlushEvents, an empty list, page time 0, timer = now); on the first turn strictly after
    /// timer + time: the fade-out of the page (none for the empty list), the 60-tick wait (`FUN_10049820(0x3c)`), the
    /// next page's lines read up to a `<page n>` line — `<title>` lines in format 8 `crti` (the text after the tag),
    /// the rest in format 9 `crno`, x 120 (the format's), y = flli 74 (130) + flli 75 (16)·k — its fade-in (16 passes in
    /// X, D1), timer = now, time = n. A §9a item 5: the reader `FUN_10002e50` returns false for an EMPTY line (L
    /// `10002fa8 cmplwi r29,0; beq 10002fec` → r24 = 0; X the same at `10002fa8`), and line 99 — inside page 10 — is
    /// empty: page 10's build stops there, it is shown for the stale 420, and the next timeout fades it out, waits 60
    /// and leaves (`.leave`, no sound; the exit fade-out finds the list empty). No blank eleventh page. The first page
    /// is fully in at entry + 1 + 60 + 15 = +76 in X (L's 32-pass fade: +92).
    func testCreditsPaging() throws {
        let a = try assets()
        let rate = ElementList.fadeRate(floats: a.floats)
        let e: UInt32 = 10_000
        // The entry's FlushEvents: a click, a key and the menu bar's About (read as a click) are all dropped.
        let early = HeldKeys(mouseDowns: [MousePoint(h: 320, v: 240)], keyEvents: [KeyEvent(charCode: 0x4e, keyCode: 0)],
                             events: [.aboutChosen])
        var (run, entry) = try entered(a, t0: e, keys: early)
        let state0 = run.state
        XCTAssertEqual(entry.output.ops, [.fill(.back, colour: 0),
                                          .loadImage(image: FourCC("back")!, into: .back, dst: Self.full),
                                          .copy(from: .back, to: .terrain, src: Self.full, dst: Self.full,
                                                interlaced: false),
                                          .present(.fullScreen)])
        XCTAssertEqual(entry.output.sounds, [])
        XCTAssertEqual(entry.output.music, [])
        XCTAssertEqual(entry.output.requests, [])
        XCTAssertNil(entry.finished)
        XCTAssertNil(entry.callee)
        XCTAssertEqual(run.credits.page.count, 0, "an empty list")

        let lines = try a.credits().lines
        XCTAssertEqual(lines[99], [], "the empty line inside page 10")
        XCTAssertEqual(MacRoman.decode(lines[100]), "<page 420>", "never read")

        var previous = ElementList()
        var shown: UInt32 = e                                           // the timer; page time 0 at entry
        var time: UInt32 = 0
        for p in 0..<10 {
            guard let (at, change) = toPageChange(&run, bound: e + Self.maxTicks) else { return }
            XCTAssertEqual(at, shown + time + 1, "page \(p + 1): built on the first turn strictly after timer + time")
            let page = run.credits.page
            XCTAssertEqual(change.output.ops, previous.fadeOut(rate: rate, text: run.state.text, assets: a)
                           + [.hostWait(.ticks(60))] + page.fadeIn(rate: rate, text: run.state.text, assets: a),
                           "page \(p + 1): fade-out, 60-tick wait, fade-in")
            XCTAssertEqual(change.output.sounds, [], "page \(p + 1): the input before the first page was flushed")
            XCTAssertNil(change.finished)
            XCTAssertEqual(page.count, Self.counts[p], "page \(p + 1): its lines")
            for (k, el) in page.elements.enumerated() {
                XCTAssertTrue(el.isText)
                var f = a.formats[k == 0 ? 8 : 9]
                XCTAssertEqual(f.locX, 120)
                f.locY = 130 + 16 * Int32(k)
                XCTAssertEqual(el.record.format, f, "page \(p + 1) line \(k): crti for the title, else crno")
                XCTAssertFalse(MacRoman.decode(el.record.text).contains("<"), "no tag is drawn")
            }
            XCTAssertEqual(page.elements.first?.record.text, Array(Self.titles[p].utf8), "page \(p + 1) title")
            // The pass after the fade-in sets the timer (TickCount after FUN_1000db90).
            shown = run.t
            XCTAssertEqual(shown, at + (p == 0 ? 0 : 15) + 60 + 15)
            if p == 0 { XCTAssertEqual(shown, e + 76, "the first page is in at entry + 76 (X; L: + 92)") }
            time = Self.times[p]
            previous = page
        }
        let last = run.credits.page
        XCTAssertEqual(last.elements[1].record.text, [0x20])
        XCTAssertEqual(MacRoman.decode(last.elements[13].record.text), "Stuart \"h'biki\" Willis",
                       "page 10 ends at line 98")

        // Page 10 held the stale 420; then its fade-out and the 60-tick wait — and no eleventh page.
        guard let (end, exit) = toPageChange(&run, bound: e + Self.maxTicks) else { return }
        XCTAssertEqual(end, shown + 420 + 1)
        XCTAssertEqual(exit.output.ops, last.fadeOut(rate: rate, text: run.state.text, assets: a)
                       + [.hostWait(.ticks(60))])
        XCTAssertEqual(exit.output.sounds, [], "the end of the credits plays no sound")
        XCTAssertNil(exit.finished)
        XCTAssertEqual(run.credits.page.count, 0)
        let done = step(&run)
        XCTAssertEqual(done.finished, .leave)
        XCTAssertEqual(done.output, PassOutput(), "the exit fade-out finds the list empty")
        XCTAssertLessThan(run.t, e + Self.maxTicks)
        XCTAssertEqual(run.state.menuElements, state0.menuElements, "the credits keep a list of their own")
    }

    // MARK: - Exits

    /// The way out (A §4; X `10026348..10026468`): the event reader (`FUN_10048c90`, X `10049f60`, D24) is read once
    /// per turn, only between timeouts — the fades and the 60-tick wait leave events queued. Code 1 (mouseDown) →
    /// `incl` (gaso 2, 0x32, 100, 1), `.leave`; codes 2–3 (keyDown, autoKey) → `incl`, `N` / `n` → `.newGame`, any other
    /// key → `.leave`. The reader takes every mouseDown as code 1 without asking where (no `MenuSelect`; L `10048c90`,
    /// X `10049f60`), so a menu-bar click leaves like any click: the menu bar's About (`ShellEvent.aboutChosen`) is
    /// read as that click; the shell's other events are not the reader's. Then the fade-out of the page and, on the
    /// next pass (after the fade's waits), the return.
    func testCreditsExits() throws {
        let a = try assets()
        let rate = ElementList.fadeRate(floats: a.floats)
        let bound: UInt32 = 10_000 + Self.maxTicks

        /// Credits whose first page is up (the pass after its fade-in is next).
        func onPageOne() throws -> Run? {
            var (run, _) = try entered(a)
            guard toPageChange(&run, bound: bound) != nil else { return nil }
            XCTAssertEqual(run.credits.page.count, 7)
            return run
        }

        for (keys, expected, label) in [(Self.click, Credits.Exit.leave, "click"),
                                        (Self.key(0x4e), .newGame, "N"), (Self.key(0x6e), .newGame, "n"),
                                        (Self.key(0x78), .leave, "x"), (Self.key(0x0d), .leave, "Return"),
                                        (Self.key(0x71, repeating: true), .leave, "an auto-key q"),
                                        (HeldKeys(events: [.aboutChosen]), .leave, "the menu bar's About")] {
            guard var run = try onPageOne() else { return }
            _ = step(&run)                                              // the timer pass
            let page = run.credits.page
            let out = step(&run, keys)
            XCTAssertEqual(out.output.sounds, [Self.incl(a)], label)
            XCTAssertEqual(out.output.ops, page.fadeOut(rate: rate, text: run.state.text, assets: a), label)
            XCTAssertEqual(out.output.music, [], label)
            XCTAssertNil(out.finished, "\(label): the return follows the fade-out")
            let done = step(&run, Self.key(0x4e))
            XCTAssertEqual(done.finished, expected, label)
            XCTAssertEqual(done.output, PassOutput(), label)
        }

        // A click queued during the page change (the fades and the wait) is read on the turn after the fade-in.
        do {
            var (run, _) = try entered(a)
            let first = step(&run, Self.click)                          // entry + 1: the page change
            XCTAssertTrue(first.output.ops.contains(.hostWait(.ticks(60))))
            XCTAssertEqual(first.output.sounds, [], "no input is read during the change")
            XCTAssertNil(first.finished)
            let page = run.credits.page
            XCTAssertEqual(page.count, 7)
            let read = step(&run)
            XCTAssertEqual(read.output.sounds, [Self.incl(a)])
            XCTAssertEqual(read.output.ops, page.fadeOut(rate: rate, text: run.state.text, assets: a))
            XCTAssertEqual(step(&run).finished, .leave)
        }

        // One event a turn, in order: the first key decides; the shell's other events and a release do nothing.
        do {
            guard var run = try onPageOne() else { return }
            let quiet = step(&run, HeldKeys(mouse: MousePoint(h: 1, v: 1),
                                            events: [.quitChosen, .quitRequested, .suspend, .resume]))
            XCTAssertEqual(quiet.output, PassOutput(), "not the reader's events")
            XCTAssertNil(quiet.finished)
            let two = HeldKeys(keyEvents: [KeyEvent(charCode: 0x78, keyCode: 0), KeyEvent(charCode: 0x4e, keyCode: 0)])
            XCTAssertEqual(step(&run, two).output.sounds, [Self.incl(a)])
            XCTAssertEqual(step(&run).finished, .leave, "x came first")
        }

        // A key before the first page (the entry tick's turn: now ≤ timer + 0): nothing to fade; the click sound.
        do {
            var (run, _) = try entered(a)
            run.t -= 1                                                  // the same tick as the entry
            let out = step(&run, Self.key(0x4e))
            XCTAssertEqual(out.output.sounds, [Self.incl(a)])
            XCTAssertEqual(out.output.ops, [], "an empty list fades out at once")
            XCTAssertEqual(step(&run).finished, .newGame)
        }
    }
}
