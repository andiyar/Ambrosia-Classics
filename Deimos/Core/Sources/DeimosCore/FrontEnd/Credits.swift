import Foundation
import HectorResources

/// The credits — `FUN_10025b90('cred')` as the OS X build runs it (X `10025f50`, the same code but for the event reader,
/// D24, and the element fades' 16 passes, D1; grounding A §4, §6; `front-end.md` §6; Phase 4 S2 CR): pages of the
/// `stli cred` lines, each faded in, held for its time, faded out, with a 60-tick gap; a click or a key leaves.
///
/// **Frozen entry.** `init()` — the original's one argument is the string list `'cred'` (`DeimosAssets.credits()`).
/// **Returns** how it was left: `.newGame` for `N` (its caller `FUN_10025060` then starts a one-player game,
/// `100250a8`), else `.leave`.
///
/// **How it is built.** One pass is one turn of the original's loop (L `10025d00..10025f98`, X `100260c0..10026358`),
/// which never waits for an event:
/// - **Entry** (`10025b90..10025cf4`): back ← black (`FUN_10009f00`), the `back` TGA into the back buffer, the back
///   buffer → the save buffer over {0, 0, flli 53, flli 52} = {0, 0, 480, 640}, a full present (`FUN_1000bc60`), the
///   window made current (no op), FlushEvents (the pass's input is dropped), a new empty list of its own; page time 0,
///   timer = now. The menu has already faded its own list out (`FUN_10025060`).
/// - **One turn:** the music service (the host's); when `TickCount > timer + time` (unsigned, the sum wrapping;
///   `10025d18 cmplw; ble`): the fade-out of the page (`FUN_1000df00`, none for an empty list), the list freed
///   (`FUN_100260b0`), the 60-tick wait (`10025d50 FUN_10049820(0x3c)`); then, while lines remain, the next page is
///   read (`readPage`) and faded in (`FUN_1000db90`), and timer = now (`10025f7c`) — here the next pass's tick, the
///   tick after those waits (the frame reads no `TickCount` at a pass's last op: the next pass's `ticks` is its first
///   reading after the fade-in, and the driver begins that pass on its next poll, so a page can start up to one tick
///   late; a sum of the pass's own waits would drop the host's real lateness, which the original's `TickCount`
///   keeps); or, when none remain, the return (below). Otherwise one event (`10025f8c FUN_10048c90`):
///   1 mouseDown → `incl` (gaso 2, 0x32, 100, 1), `.leave`; 2 keyDown / 3 autoKey → `incl`, `N` / `n` → `.newGame`,
///   any other → `.leave`; anything else (0, 4) nothing. The reader takes every mouseDown as code 1 — it never asks
///   where (no `FindWindow` / `MenuSelect`; L `10048c90`, X `10049f60`, the same after the call, D24) — so a click in
///   the menu bar leaves the credits like any click and About is never chosen. The shell's menu is the shell's, so
///   `ShellEvent.aboutChosen` is read as that click; the shell's other events are not the reader's (a menu Quit
///   only sets the frame's quit flag).
/// - **Input only between timeouts:** a pass that turns the page reads no event; what arrived before it waits in the
///   screen's queue, and what arrives during its fades and wait reaches the next pass (the driver queues it) — where
///   the original reads it, after the fade-in, in the same turn.
/// - **Leaving** (`10026040..10026088`): the fade-out of the page and the list freed; the return on the next pass,
///   after the fade's waits (so a caller's cues follow the fade). At the natural end the list is already empty.
///
/// **A §9a item 5, read:** the reader `FUN_10002e50` returns false for an EMPTY line (L `10002fa8 cmplwi r29,0; beq
/// 10002fec` → r24 = 0; X the same at `10002fa8`), not only past the end. The shipped `cred` has an empty line 99,
/// inside page 10: page 10's read stops there (L `10025d88`, X `10026148`: bVar2 = 0), page 10 is shown with the time
/// still held from page 9 (420), and its `<page 420>` (line 100) and the trailing empty line 101 are never read. The
/// next timeout fades page 10 out, waits 60 and returns `.leave` with no sound (`10025d60 beq 0x10026040`; the exit's
/// fade-out finds the list empty). There is no blank eleventh page.
public struct Credits: Sendable {
    public enum Exit: Equatable, Sendable {
        case leave
        case newGame
    }

    public typealias Result = Exit

    /// One event the reader returns (its codes 1–3).
    enum Event: Equatable, Sendable {
        case click
        case key(UInt8)
    }

    enum Phase: Equatable, Sendable {
        case entry
        case running
        /// The fade-out has run: return on this pass.
        case leaving(Exit)
    }

    private(set) var phase = Phase.entry
    /// The page on screen (`r24`, the credits' own list — not the menu's).
    private(set) var page = ElementList()
    /// `local_284[0]`: the page's time in ticks, as `%i` read it (0 before the first page; kept when a page has no
    /// `<page n>` line).
    private(set) var time: UInt32 = 0
    /// The tick the page came up.
    private(set) var timer: UInt32 = 0
    /// The next `cred` line to read.
    private var line = 0
    /// bVar2 (`r27`): lines remain.
    private var more = true
    /// A page has just been faded in: the timer is the next pass's tick.
    private var timerOnNextPass = false
    private var lines: [[UInt8]] = []
    private var queue: [Event] = []

    public init() {}

    public mutating func pass(keys: HeldKeys, ticks: UInt32, returned: ScreenResult?,
                              state: inout FrontEndState) -> ScreenStep<Result> {
        var out = PassOutput()
        switch phase {
        case .entry:
            enter(ticks: ticks, state: state, &out)
            return .stay(out)
        case let .leaving(exit):
            return .finish(exit)                                        // FUN_100008b0, FUN_10020e00: frees
        case .running:
            break
        }
        queue += keys.events.filter { $0 == .aboutChosen }.map { _ in Event.click }   // a menu-bar mouseDown
        queue += keys.keyEvents.map { Event.key($0.charCode) }
        queue += keys.mouseDowns.map { _ in Event.click }
        if timerOnNextPass {                                            // 10025f7c: timer = TickCount, then the read
            timerOnNextPass = false
            timer = ticks
        } else if ticks > timer &+ time {                               // 10025d00..10025d1c
            return turnPage(state: state, &out)
        }
        guard !queue.isEmpty else { return .stay(out) }                 // 10025f8c FUN_10048c90: one event
        let exit: Exit
        switch queue.removeFirst() {
        case .click:                                                    // 10025fb8..10025fd4
            exit = .leave
        case let .key(c):                                               // 10025fd8..10026038: 'n', 'N'
            exit = c == 0x6e || c == 0x4e ? .newGame : .leave
        }
        out.sounds.append(SoundPlay.perm(state.assets.sounds[2], priority: 0x32, volume: 100, allowMultiple: true))
        leave(exit, state: state, &out)
        return .stay(out)
    }

    // MARK: - Entry, pages, leaving

    private mutating func enter(ticks: UInt32, state: FrontEndState, _ out: inout PassOutput) {
        let a = state.assets
        let screen = MacRect(top: 0, left: 0, bottom: EntityDraw.fctiwz(a.floats[53]),
                             right: EntityDraw.fctiwz(a.floats[52]))
        out.ops.append(.fill(.back, colour: 0))                         // FUN_10009f00(D+0x68, black)
        out.ops.append(.loadImage(image: Self.back, into: .back, dst: screen))   // FUN_10020da0 + FUN_10009fd0
        out.ops.append(.copy(from: .back, to: .terrain, src: screen, dst: screen, interlaced: false))
        out.ops.append(.present(.fullScreen))                           // FUN_1000bc60
        queue = []                                                      // FUN_10048e30 FlushEvents
        lines = (try? a.credits())?.lines ?? []
        page = ElementList()                                            // FUN_1004d320(0xc) + FUN_10000890
        line = 0
        more = true
        time = 0
        timer = ticks                                                   // 10025cec
        phase = .running
    }

    /// The timeout (`10025d24..10025f7c`): fade the page out, free it, wait 60; then the next page and its fade-in,
    /// or — no lines left — the return.
    private mutating func turnPage(state: FrontEndState, _ out: inout PassOutput) -> ScreenStep<Result> {
        let rate = ElementList.fadeRate(floats: state.assets.floats)
        out.ops += page.fadeOut(rate: rate, text: state.text, assets: state.assets)
        page = ElementList()                                            // FUN_100260b0
        out.ops.append(.hostWait(.ticks(Self.gap)))                     // FUN_10049820(0x3c)
        guard more else {                                               // 10025d60 → 10026040: the list is empty
            phase = .leaving(.leave)
            return .stay(out)
        }
        readPage(state: state)
        out.ops += page.fadeIn(rate: rate, text: state.text, assets: state.assets)
        timerOnNextPass = true
        return .stay(out)
    }

    /// The read loop (`10025d68..10025f54`): lines from `line` on, until a `<page ` line (its number, after the first
    /// white-space byte up to `>`, read with `%i` as the page's time) or a line the reader refuses (empty or past the
    /// end: `more` = false). A line holding `<title>` → format 8 `crti` with the text after the tag; any other →
    /// format 9 `crno` with the whole line; Loc Y (`+0x104`) = flli 74 + flli 75·k, Loc X the format's.
    private mutating func readPage(state: FrontEndState) {
        let a = state.assets
        var y = EntityDraw.fctiwz(a.floats[74])
        let dy = EntityDraw.fctiwz(a.floats[75])
        while let text = Self.read(lines, line) {                       // FUN_10002e50('cred', line, buf, 0x100)
            line += 1
            if Self.find(Self.pageTag, in: text) != nil {               // 10025d9c strstr "<page "
                if let n = Self.pageTime(text) { time = UInt32(bitPattern: n) }
                return
            }
            var f: TextFormat
            let body: [UInt8]
            if let at = Self.find(Self.titleTag, in: text) {           // 10025ed0 strstr "<title>"
                f = a.formats[8]
                body = Array(text[(at + Self.titleTag.count)...])
            } else {
                f = a.formats[9]
                body = text
            }
            f.locY = y
            page.append(.text(TextRequest(format: f, text: body)))     // FUN_100009e0
            y &+= dy
        }
        more = false                                                    // 10025d88
    }

    /// `10026040..10026088`: the fade-out of the page, the list freed; the return on the next pass.
    private mutating func leave(_ exit: Exit, state: FrontEndState, _ out: inout PassOutput) {
        out.ops += page.fadeOut(rate: ElementList.fadeRate(floats: state.assets.floats), text: state.text,
                                assets: state.assets)
        page = ElementList()
        phase = .leaving(exit)
    }

    // MARK: - The string reads

    /// `FUN_10002e50(list, i, buf, 0x100)`: line `i`, at most 255 bytes; nil when it is empty or there is no such line
    /// (`10002fa8 cmplwi r29,0; beq` → false).
    static func read(_ lines: [[UInt8]], _ i: Int) -> [UInt8]? {
        guard lines.indices.contains(i), !lines[i].isEmpty else { return nil }
        return Array(lines[i].prefix(0xff))
    }

    /// `strstr`: the offset of `tag` in `text`.
    static func find(_ tag: [UInt8], in text: [UInt8]) -> Int? {
        guard text.count >= tag.count else { return nil }
        return (0...(text.count - tag.count)).first { text[$0..<($0 + tag.count)].elementsEqual(tag) }
    }

    /// `10025dc0..10025e70`: after the first byte of ctype class 6 (`10025de8 rlwinm. …,0x1d,0x1e`; MSL's white space:
    /// tab, LF, VT, FF, CR, space — MED, the class table itself was not read) the rest (`FUN_10046510`, ≤ 255), cut at
    /// the first `>`, read by `sscanf("%i")`; nil when it reads nothing (the time is then kept).
    static func pageTime(_ text: [UInt8]) -> Int32? {
        guard let w = text.firstIndex(where: isSpace) else { return nil }
        var s = Array(text[(w + 1)...].prefix(0xff))
        if let gt = s.firstIndex(of: 0x3e) { s = Array(s[..<gt]) }
        return scanInt(s)
    }

    /// `%i`: white space skipped, a sign, then `0x` hexadecimal, `0` octal or decimal; nil when no digit is read.
    /// The value wraps to 32 bits.
    static func scanInt(_ s: [UInt8]) -> Int32? {
        var i = s.startIndex
        while i < s.endIndex, isSpace(s[i]) { i += 1 }
        var negative = false
        if i < s.endIndex, s[i] == 0x2b || s[i] == 0x2d {
            negative = s[i] == 0x2d
            i += 1
        }
        var base: UInt32 = 10
        var digits = 0
        var value: UInt32 = 0
        if i < s.endIndex, s[i] == 0x30 {
            base = 8
            digits = 1
            i += 1
            if i + 1 < s.endIndex, s[i] == 0x78 || s[i] == 0x58, hexDigit(s[i + 1]) != nil {
                base = 16
                i += 1
            }
        }
        while i < s.endIndex, let d = hexDigit(s[i]), d < base {
            value = value &* base &+ d
            digits += 1
            i += 1
        }
        guard digits > 0 else { return nil }
        return Int32(bitPattern: negative ? 0 &- value : value)
    }

    private static func isSpace(_ c: UInt8) -> Bool { c == 0x20 || (0x09...0x0d).contains(c) }

    private static func hexDigit(_ c: UInt8) -> UInt32? {
        switch c {
        case 0x30...0x39: return UInt32(c - 0x30)
        case 0x41...0x46: return UInt32(c - 0x41 + 10)
        case 0x61...0x66: return UInt32(c - 0x61 + 10)
        default: return nil
        }
    }

    static let back = FourCC("back")!
    /// `10025d4c li r3,0x3c`.
    static let gap: UInt32 = 60
    /// `_DAT_100e01c0` → `0x100e9130`.
    static let pageTag = Array("<page ".utf8)
    /// `_DAT_100e01bc` → `0x100e9128`.
    static let titleTag = Array("<title>".utf8)
}
