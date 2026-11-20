import Foundation
import HectorResources

/// The main menu — `FUN_100229a0` as the OS X build runs it (X `10022bb0`; grounding A §2, §6; `front-end.md` §2;
/// `osx-build.md` D1, D7, D15, D16, D23; Phase 4 S2 MM). The registered build's layout (ruling 4: no REGISTER button,
/// no advertisement).
///
/// **Frozen entry.** `init(film:)` — `film` is played as soon as the menu is up, as the DEMOS button plays a demo
/// (the hidden `-film` switch, ruling 10); nil for a normal launch. **Returns** nothing (`ScreenDone`): the menu has
/// been left (b9), and the front end then shuts down (`FUN_10000630`) and asks the shell to quit. Its buttons and
/// keys call the other screens: start/return (1 PLAYER, 2 PLAYER), the configuration window, scores, films (DEMOS,
/// `D`, `F`), credits; the shared state (b6, b8, b9, b7, the copyright clock, the element list and its lit index) is
/// `FrontEndState`'s.
///
/// **How it is built.** The original's loop never waits for an event; here one pass of the screen is one turn of
/// that loop (A §2.2), and each blocking part becomes ops with host waits or a pass of its own:
/// - **Entry** (`10022a00..10022a50`; draw menu X `10023800`, D7: no menu bar): t0 = now; the buttons
///   (`FUN_10023fd0`) and the element list with its hit rects (`FUN_10025420`); FlushEvents; `back` into the back and
///   save buffers, every button unlit, the element fade-in (`FUN_1000db90`, 16 passes in X, D1), the redraw; a full
///   present; InitCursor (`.showCursor`); b6 = 0. b9 is cleared; b8 is kept — the only way it is set before the menu
///   is a Quit that the original would still hold queued for this loop's event pump.
/// - **One turn** (`10022a5c..10022e94`): (1) b9 → leave; (2) the suspend / resume edge (the original's window
///   collapse check; here the shared `suspended` flag, which the driver's `suspend()` / `resume()` also set);
///   (3) not suspended: b8 → the QUIT flash, b8 = 0 (the rest of the turn runs on the next pass, after the flash's
///   wait); the copyright flip strictly after t0 + flli 68; b6 → resume the stream or play `inmu`; b8 clear and the
///   mouse outside the menu-bar strip → hover; (4) redraw if dirty; (5) one event, dispatched.
/// - **Events** are the pass's queued input, kept in arrival order per kind (the shell's events, then key events,
///   then mouse-downs) and handed out one per turn, as the pump returns one per call. The frame has already applied
///   a Quit (b8) and a suspend / resume (b7) when they arrived; the menu treats b7 as unchanged until it dispatches
///   a queued suspend or resume (the original clears b7 only there). A screen the menu calls never sees the input
///   still queued here, so the OS events (keys, clicks) are dropped when the menu calls one — as that screen's own
///   FlushEvents or event loop would have taken them; the shell's events stay.
/// - **Click tracking** (`FUN_10024a50`): the StillDown loop runs one turn per pass while `mouseButton` holds.
///
/// Not built here (not this card's): the Option-click erase question on SCORES (`front-end.md` §2.7 — the table
/// erase is S4's), the website dialog (question 3: the web line lights up and a click does nothing), the
/// Command-key menu-title flash (`10049080`: the shell's menu bar flashes its own title; Core gets the command).
public struct MainMenu: Sendable {
    public typealias Result = ScreenDone

    public let film: Film?
    private var filmPlayed = false

    /// The copyright line the menu draws: the binary's string at `0x100e8dcf`, decoded with `FUN_10046470`
    /// (`front-end.md` §2.1; the `inte` line 1 copyright, "2001-2002", is loaded but never drawn).
    static let copyright = "COPYRIGHT 2001-2003 SWOOP SOFTWARE & AMBROSIA SOFTWARE, INC."
    /// `GetMBarHeight()` on Mac OS X (22): the hover-dead strip is (top, left, MBarHeight, right) of the 640×480
    /// screen rect, inclusive (`display-window-present.md` §7, `10022c1c..10022c64`). MED: a runtime OS value.
    static let menuBarHeight: Int32 = 22
    /// `FUN_10048120(1)`'s spin bound (`1004819c`).
    static let musicStopTicks: UInt32 = 600
    static let screen = MacRect(top: 0, left: 0, bottom: 480, right: 640)
    /// The left and right Command keys (`cmdKey` in the event's modifiers: either one).
    static let commandKeys: Set<UInt16> = [0x37, 0x36]

    /// One button record (`FUN_10024430`, 0x124 bytes): id `+0x000`, text `+0x001`, hit rect `+0x104…+0x110`,
    /// sprites `+0x114` / `+0x118`, frame `+0x11c`, lit `+0x120`, dirty `+0x121`, type `+0x122`.
    struct Button: Equatable, Sendable {
        enum Kind: Equatable, Sendable {
            case sprite, logo, web, copyright                   // types 0, 1, 2, 3
        }
        var id: Int
        var kind: Kind
        var text: [UInt8]
        var normal: FourCC
        var lit: FourCC
        var frame: Int
        var rect = MacRect(top: 0, left: 0, bottom: 0, right: 0)
        var hilited = false
        var dirty = true
    }

    /// One queued event (the pump's codes 2, 4–8).
    enum Event: Equatable, Sendable {
        case shell(ShellEvent)
        case key(KeyEvent, command: Bool)
        case click(MousePoint)
    }

    /// What the menu does when a screen it called returns.
    enum After: Equatable, Sendable {
        /// A key's action: the clock restarts after it (`10022e20`).
        case key
        /// A click's action (the clock restarted before it, `10022d50`), or the `-film` film.
        case click
        /// PREFERENCES (`FUN_10024e40`): b6 = 1.
        case prefs(key: Bool)
        /// SCORES (`FUN_10024e70`) / About (`FUN_10025060`): `N` there starts a one-player game, then the tail.
        case scores(key: Bool)
        case credits(key: Bool)
        /// The one-player game from the scores or credits screen has returned: the tail.
        case tail(key: Bool)
    }

    enum Phase: Equatable, Sendable {
        case entry
        case idle
        /// The QUIT flash ran (its wait ends the pass): the rest of that turn runs next.
        case afterQuitFlash
        case tracking(id: Int, rect: MacRect)
        case waiting(After)
        /// The fade-out has run: free, stop the music, return.
        case leaving
    }

    private(set) var buttons: [Button] = []
    private(set) var phase = Phase.entry
    private var queue: [Event] = []
    /// `bVar3`: the copyright line shows the banner (odd flips).
    private var banner = false
    /// The shared suspended flag as the last turn saw it (the edge, step 2).
    private var lastSuspended = false
    /// A key's action ended with a screen fade-in (the scores / credits tail): the clock restarts on the next pass,
    /// when the original's `TickCount` after the tail is read.
    private var clockOnNextPass = false

    public init(film: Film? = nil) {
        self.film = film
    }

    public mutating func pass(keys: HeldKeys, ticks: UInt32, returned: ScreenResult?,
                              state: inout FrontEndState) -> ScreenStep<Result> {
        var out = PassOutput()
        switch phase {
        case .entry:
            enqueue(keys)                                               // what reached the pump before the entry …
            enter(ticks: ticks, state: &state, &out)                    // … which its FlushEvents drops
            return .stay(out)
        case .leaving:
            // 10022a3c..10022a44: free the button and element lists; FUN_10048120(1): stop with fade, spin ≤ 600.
            buttons = []
            state.menuElements = ElementList()
            state.menuLit = nil
            out.music.append(.stopWithFade)
            out.ops.append(.hostWait(.musicStopped(maxTicks: Self.musicStopTicks)))
            return .finish(ScreenDone(), out)
        case let .waiting(after):
            // The input of a pass whose first step is this return arrived after the called screen ended: it waits
            // for the menu's pump (the actions FUN_10024d80 / db0 / de0 / e10 / e40 flush nothing after their
            // screen), unless the return's own FlushEvents (the SCORES / About tail) or the next call drops it.
            enqueue(keys)
            return back(after, returned: returned, ticks: ticks, state: &state, &out)
        case .idle, .afterQuitFlash, .tracking:
            break
        }
        enqueue(keys)
        if clockOnNextPass {
            clockOnNextPass = false
            state.copyrightClock = ticks
        }
        switch phase {
        case let .tracking(id, rect):
            return track(id: id, rect: rect, keys: keys, ticks: ticks, state: &state, &out)
        case .afterQuitFlash:
            phase = .idle
            return turnRest(keys: keys, ticks: ticks, state: &state, &out)
        default:
            return turn(keys: keys, ticks: ticks, state: &state, &out)
        }
    }

    // MARK: - Entry and leaving

    private mutating func enter(ticks: UInt32, state: inout FrontEndState, _ out: inout PassOutput) {
        state.copyrightClock = ticks                                    // t0 = TickCount
        state.leave = false                                             // b9 = 0
        banner = false
        // FUN_10023fd0: logo, 1 PLAYER … QUIT (mebu frames 0, 1, 2, 4, 5, 6), no REGISTER (registered), web, copyright.
        let a = state.assets
        let mebu = a.sprites[3], mebh = a.sprites[4], galo = a.sprites[5]
        buttons = [Button(id: 0, kind: .logo, text: [], normal: galo, lit: galo, frame: 0)]
        for (i, frame) in [0, 1, 2, 4, 5, 6].enumerated() {
            buttons.append(Button(id: i + 1, kind: .sprite, text: [], normal: mebu, lit: mebh, frame: frame))
        }
        let web = (try? a.interfaceStrings())?.lines.first ?? []
        buttons.append(Button(id: 8, kind: .web, text: web, normal: .none, lit: .none, frame: 0))
        buttons.append(Button(id: 9, kind: .copyright, text: Self.bytes(Self.copyright), normal: .none, lit: .none,
                              frame: 0))
        layout(&state)                                                  // FUN_10025420
        flushEvents()                                                   // FUN_10048e30 FlushEvents
        // FUN_10023410 (X 10023800: no DrawMenuBar, D7).
        out.ops.append(.loadImage(image: Self.back, into: .back, dst: Self.screen))
        out.ops.append(.loadImage(image: Self.back, into: .terrain, dst: Self.screen))
        unhiliteAll(&state)                                             // FUN_10024a00(0)
        out.ops += state.menuElements.fadeIn(rate: ElementList.fadeRate(floats: a.floats), text: state.text, assets: a)
        redraw(force: false, state: &state, &out)                       // FUN_10024810(0)
        out.ops.append(.present(.fullScreen))                           // FUN_1000bc60
        out.requests.append(.showCursor)                                // FUN_1000b780 InitCursor
        state.menuMusic = false                                         // b6 = 0
        lastSuspended = state.suspended
        phase = .idle
    }

    /// b9 (`10022a20..10022a38`): present, the element fade-out (`FUN_10025890`); the rest on the next pass, after
    /// the fade's waits. The registered build returns there (no advertisement).
    private mutating func leave(state: inout FrontEndState, _ out: inout PassOutput) -> ScreenStep<Result> {
        out.ops.append(.present(.fullScreen))
        out.ops += state.menuElements.fadeOut(rate: ElementList.fadeRate(floats: state.assets.floats),
                                              text: state.text, assets: state.assets)
        phase = .leaving
        return .stay(out)
    }

    // MARK: - One turn of the loop

    private mutating func turn(keys: HeldKeys, ticks: UInt32, state: inout FrontEndState,
                               _ out: inout PassOutput) -> ScreenStep<Result> {
        if state.leave { return leave(state: &state, &out) }           // (1) b9
        if let film, !filmPlayed {                                      // ruling 10's -film, once the menu is up
            filmPlayed = true
            return call(.startReturn(StartReturn(mode: .demo, players: 1, film: film)), after: .click, &out)
        }
        // (2) The suspend / resume edge (10022a64..10022aa4): a resume not carried by a queued event.
        if lastSuspended && !state.suspended && !queue.contains(.shell(.resume)) {
            resumeWork(state: &state, &out)
        }
        lastSuspended = state.suspended
        // (3) b8 → the QUIT flash (10022ab8..10022ad4).
        if !suspended(state), state.quit {
            quitFlash(state: &state, &out)
            state.quit = false
            phase = .afterQuitFlash
            return .stay(out)
        }
        return turnRest(keys: keys, ticks: ticks, state: &state, &out)
    }

    /// Step 3 from the flip on, then steps 4 and 5.
    private mutating func turnRest(keys: HeldKeys, ticks: UInt32, state: inout FrontEndState,
                                   _ out: inout PassOutput) -> ScreenStep<Result> {
        let a = state.assets
        if !suspended(state) {
            // The flip (10022ad8..10022b88): TickCount > t0 + flli 68, unsigned (the sum wrapping).
            let flip = UInt32(bitPattern: EntityDraw.fctiwz(a.floats[68]))
            if state.copyrightClock &+ flip < ticks {
                banner.toggle()
                state.copyrightClock = ticks
                setText(9, banner ? bannerText(state) : Self.bytes(Self.copyright))   // FUN_10024cb0(9, …)
                redraw(force: true, state: &state, &out)                // FUN_10024810(1)
            }
            // b6 (10022b9c..10022bd8): resume a living stream, else inmu from the start.
            if state.menuMusic {
                state.menuMusic = false
                state.copyrightClock = ticks
                out.music.append(state.musicAlive ? .resume : .play(Self.inmu, loop: true))
            }
            // Hover (10022be0..10022c90): b8 clear and the mouse outside the menu-bar strip.
            if !state.quit && !Self.inMenuBarStrip(keys.mouse) {
                _ = hover(keys.mouse, state: &state, &out)
            }
        }
        redraw(force: false, state: &state, &out)                       // (4) FUN_10024810(0)
        guard !queue.isEmpty else { return .stay(out) }                 // (5) FUN_10048f30: one event
        let event = queue.removeFirst()
        return dispatch(event, keys: keys, ticks: ticks, state: &state, &out)
    }

    /// b7 as the menu sees it: a queued suspend or resume not yet dispatched has not changed it yet.
    private func suspended(_ state: FrontEndState) -> Bool {
        for case let .shell(e) in queue {
            if e == .resume { return true }
            if e == .suspend { return false }
        }
        return state.suspended
    }

    // MARK: - Dispatch (10022c98..10022e94)

    private mutating func dispatch(_ event: Event, keys: HeldKeys, ticks: UInt32, state: inout FrontEndState,
                                   _ out: inout PassOutput) -> ScreenStep<Result> {
        switch event {
        case .shell(.aboutChosen):                                      // FUN_10023330(1) → FUN_10025060
            return action(9, fromKey: false, state: &state, &out)
        case .shell(.quitChosen):                                       // FUN_10023330(2): b8 — set by the frame
            return .stay(out)
        case .shell(.quitRequested):                                    // code 8: resume if suspended; b8 (the frame)
            if state.suspended {
                // Known limit (S8a): the driver's own suspended flag stays set, so its next suspend() is skipped and
                // its next resume() resumes the music once more.
                state.suspended = false
                lastSuspended = false                                   // the edge: this resume is done here
                resumeWork(state: &state, &out)
            }
            return .stay(out)
        case .shell(.suspend):                                          // code 7: FUN_10023da0, t0 = now (b7 is
            state.copyrightClock = ticks                                // the frame's, the music pause the driver's)
            return .stay(out)
        case .shell(.resume):                                           // code 6: FUN_10023e10, t0 = now
            resumeWork(state: &state, &out)
            state.copyrightClock = ticks
            return .stay(out)
        case .shell(.answer):
            return .stay(out)
        case let .key(k, command):
            if command { return .stay(out) }                            // code 5: the menu bar's (the shell's)
            return key(k.charCode, ticks: ticks, state: &state, &out)   // code 4
        case let .click(p):                                             // code 2, sub 2
            guard !state.quit else { return .stay(out) }
            let id = hover(p, state: &state, &out)                      // FUN_10024530(where)
            guard id != -1, let b = buttons.first(where: { $0.id == id }) else { return .stay(out) }
            if b.kind != .logo { out.sounds.append(sound(2, state)) }   // FUN_10024a50: incl unless the logo
            phase = .tracking(id: id, rect: b.rect)
            return track(id: id, rect: b.rect, keys: keys, ticks: ticks, state: &state, &out)
        }
    }

    /// One turn of `FUN_10024a50`'s StillDown loop, or its end: every element unlit, then — released inside the
    /// rect taken at the press — t0 = now and the action.
    private mutating func track(id: Int, rect: MacRect, keys: HeldKeys, ticks: UInt32, state: inout FrontEndState,
                                _ out: inout PassOutput) -> ScreenStep<Result> {
        if keys.mouseButton {
            if Self.inside(keys.mouse, rect) { hilite(id, true, &state) } else { unhiliteAll(&state) }
            redraw(force: false, state: &state, &out)
            return .stay(out)
        }
        unhiliteAll(&state)
        phase = .idle
        guard Self.inside(keys.mouse, rect) else { return .stay(out) }
        state.copyrightClock = ticks                                    // 10022d50
        return action(id, fromKey: false, state: &state, &out)
    }

    /// `FUN_10023b00(char)` (`front-end.md` §2.8; L `10023b10..10023d7c`, X `10023ef0..10024170`), then t0 = now
    /// (after the action: when a called screen returns).
    private mutating func key(_ c: UInt8, ticks: UInt32, state: inout FrontEndState,
                              _ out: inout PassOutput) -> ScreenStep<Result> {
        func flashThen(_ id: Int) -> ScreenStep<Result> {
            out.sounds.append(sound(2, state))                          // incl (0x4b, 100, 0)
            flash(id, state: &state, &out)                              // FUN_100246c0
            return action(id, fromKey: true, state: &state, &out)
        }
        switch c {
        case 0x31, 0x4e, 0x6e, 0x0d, 0x0a: return flashThen(1)          // 1 N n Return 0x0A
        case 0x32: return flashThen(2)
        case 0x50, 0x70: return flashThen(3)                            // P p (then FUN_10025920: nothing for them)
        case 0x48, 0x68, 0x53, 0x73: return flashThen(4)                // H h S s
        case 0x44, 0x64: return flashThen(5)                            // D d
        case 0x46, 0x66:                                                // F f: the click, no flash, Last Film
            out.sounds.append(sound(2, state))
            return call(.films(Films(kind: .lastFilm)), after: .key, &out)
        case 0x51, 0x71:                                                // Q q: b8 only
            state.quit = true
        case 0x9d:                                                      // FUN_10025920 → FUN_10047990: no click
            if state.soundAvailable { _ = FrameKeys.volumeDown(&state.prefs) }
        case 0x8a:                                                      // → FUN_10047a30
            if state.soundAvailable { _ = FrameKeys.volumeUp(&state.prefs) }
        default:                                                        // R r (no button 7), O o, anything else
            break
        }
        state.copyrightClock = ticks
        return .stay(out)
    }

    /// The button actions (`front-end.md` §2.7).
    private mutating func action(_ id: Int, fromKey: Bool, state: inout FrontEndState,
                                 _ out: inout PassOutput) -> ScreenStep<Result> {
        let done: After = fromKey ? .key : .click
        switch id {
        case 1: return call(.startReturn(StartReturn(mode: .play, players: 1)), after: done, &out)   // FUN_10024d80
        case 2: return call(.startReturn(StartReturn(mode: .play, players: 2)), after: done, &out)   // FUN_10024db0
        case 3: return call(.configDialog(ConfigDialog(firstLaunch: false)), after: .prefs(key: fromKey), &out)
        case 4:                                                         // FUN_10024e70
            wrapperHead(state: &state, &out)
            return call(.scores(Scores()), after: .scores(key: fromKey), &out)
        case 5: return call(.films(Films(kind: .demo)), after: done, &out)                          // FUN_10024de0
        case 6: state.leave = true                                      // QUIT: b9
        case 9:                                                         // FUN_10025060: About
            wrapperHead(state: &state, &out)
            return call(.credits(Credits()), after: .credits(key: fromKey), &out)
        default: break                                                  // 0 logo; 8 the web line (question 3)
        }
        return .stay(out)
    }

    /// A called screen has returned.
    private mutating func back(_ after: After, returned: ScreenResult?, ticks: UInt32, state: inout FrontEndState,
                               _ out: inout PassOutput) -> ScreenStep<Result> {
        phase = .idle
        switch after {
        case .key:
            state.copyrightClock = ticks
        case .click:
            break
        case let .prefs(key):
            state.menuMusic = true                                      // FUN_10024e40: b6 = 1
            if key { state.copyrightClock = ticks }
        case let .scores(key):
            if case .scores(.newGame)? = returned {
                return call(.startReturn(StartReturn(mode: .play, players: 1)), after: .tail(key: key), &out)
            }
            wrapperTail(key: key, state: &state, &out)
        case let .credits(key):
            if case .credits(.newGame)? = returned {
                return call(.startReturn(StartReturn(mode: .play, players: 1)), after: .tail(key: key), &out)
            }
            wrapperTail(key: key, state: &state, &out)
        case let .tail(key):
            wrapperTail(key: key, state: &state, &out)
        }
        return .stay(out)
    }

    /// Call `screen`; the menu resumes in `after` when it returns. The OS events still queued here are dropped.
    private mutating func call(_ screen: FrontEndScreen, after: After,
                               _ out: inout PassOutput) -> ScreenStep<Result> {
        flushEvents()
        phase = .waiting(after)
        return .call(screen, out)
    }

    /// `FUN_10024e70` / `FUN_10025060` before their screen: present, the element fade-out.
    private func wrapperHead(state: inout FrontEndState, _ out: inout PassOutput) {
        out.ops.append(.present(.fullScreen))
        out.ops += state.menuElements.fadeOut(rate: ElementList.fadeRate(floats: state.assets.floats),
                                              text: state.text, assets: state.assets)
    }

    /// … and after it (X: no DrawMenuBar, D7): FlushEvents, `back` into both buffers, every button unlit, the
    /// element fade-in (of the list as last built), the redraw, a full present.
    private mutating func wrapperTail(key: Bool, state: inout FrontEndState, _ out: inout PassOutput) {
        flushEvents()
        out.ops.append(.loadImage(image: Self.back, into: .back, dst: Self.screen))
        out.ops.append(.loadImage(image: Self.back, into: .terrain, dst: Self.screen))
        unhiliteAll(&state)
        out.ops += state.menuElements.fadeIn(rate: ElementList.fadeRate(floats: state.assets.floats),
                                             text: state.text, assets: state.assets)
        redraw(force: false, state: &state, &out)
        out.ops.append(.present(.fullScreen))
        if key { clockOnNextPass = true }
    }

    /// The resume handler's menu part (`FUN_10023e10`, X `10024200`): the cursor; no present (X, D15); b6 = 1. b7 and
    /// the music resume are the frame's and the driver's.
    private func resumeWork(state: inout FrontEndState, _ out: inout PassOutput) {
        out.requests.append(.showCursor)
        state.menuMusic = true
    }

    // MARK: - Buttons

    /// `FUN_10024530(point)`: light the element under the point (`mbro`, gaso 11 (0x4b, 100, 0), on lighting, not for
    /// the logo), unlight the others; the id of the last element under it, or −1.
    private mutating func hover(_ p: MousePoint?, state: inout FrontEndState, _ out: inout PassOutput) -> Int {
        var id = -1
        for i in buttons.indices {
            if Self.inside(p, buttons[i].rect) {
                id = buttons[i].id
                if !buttons[i].hilited {
                    buttons[i].hilited = true
                    buttons[i].dirty = true
                    if buttons[i].kind != .logo { out.sounds.append(sound(11, state)) }
                }
            } else if buttons[i].hilited {
                buttons[i].hilited = false
                buttons[i].dirty = true
            }
        }
        state.menuLit = lit
        return id
    }

    /// `FUN_10024900(id, on)`: every button dirty; `id` set to `on`, every other unlit.
    private mutating func hilite(_ id: Int, _ on: Bool, _ state: inout FrontEndState) {
        for i in buttons.indices {
            buttons[i].dirty = true
            buttons[i].hilited = buttons[i].id == id ? on : false
        }
        state.menuLit = lit
    }

    /// `FUN_10024a00(0)`.
    private mutating func unhiliteAll(_ state: inout FrontEndState) {
        hilite(-1, false, &state)
    }

    private var lit: Int? { buttons.firstIndex(where: \.hilited) }

    /// `FUN_100246c0(id)`: when the button exists — unlight all, light it, redraw, wait flli 61 (10) ticks, unlight
    /// it, redraw.
    private mutating func flash(_ id: Int, state: inout FrontEndState, _ out: inout PassOutput) {
        guard buttons.contains(where: { $0.id == id }) else { return }
        unhiliteAll(&state)
        hilite(id, true, &state)
        redraw(force: false, state: &state, &out)
        out.ops.append(.hostWait(.ticks(UInt32(bitPattern: EntityDraw.fctiwz(state.assets.floats[61])))))
        hilite(id, false, &state)
        redraw(force: false, state: &state, &out)
    }

    /// `FUN_10024f90`: `incl`, then the flash of QUIT (id 6), then b9.
    private mutating func quitFlash(state: inout FrontEndState, _ out: inout PassOutput) {
        out.sounds.append(sound(2, state))
        flash(6, state: &state, &out)
        state.leave = true
    }

    /// `FUN_10024810(force)`: when forced or any button is dirty (every dirty flag cleared), restore the whole back
    /// buffer from the save buffer, rebuild the list (`FUN_10025420`), draw it once (`FUN_100258e0`), present.
    private mutating func redraw(force: Bool, state: inout FrontEndState, _ out: inout PassOutput) {
        guard !buttons.isEmpty else { return }
        var draw = force
        for i in buttons.indices where buttons[i].dirty {
            draw = true
            buttons[i].dirty = false
        }
        guard draw else { return }
        out.ops.append(.copy(from: .terrain, to: .back, src: nil, dst: nil, interlaced: false))
        layout(&state)
        out.ops += state.menuElements.drawOnce(restoreText: false, present: false, text: state.text,
                                               assets: state.assets)
        out.ops.append(.present(.fullScreen))
    }

    /// `FUN_10025420`: one element per button in list order — sprite buttons format 5 / 6 (`inbn` / `inbh`) at
    /// (fctiwz(F52) / 2, fctiwz(F62) + i·fctiwz(F63)) with the normal / lit sprite; the logo format 7 at x =
    /// fctiwz(F52) / 2 (y from the format) with its normal sprite in both states; the web line format 1 / 2, the
    /// copyright format 3 / 4 — and each button's hit rect = its element's bounds (`FUN_1000da50`).
    private mutating func layout(_ state: inout FrontEndState) {
        let a = state.assets
        let x = EntityDraw.fctiwz(a.floats[52]) / 2
        let y0 = EntityDraw.fctiwz(a.floats[62]), dy = EntityDraw.fctiwz(a.floats[63])
        var list = ElementList()
        for (i, b) in buttons.enumerated() {
            switch b.kind {
            case .sprite:
                var f = a.formats[b.hilited ? 6 : 5]
                f.locX = x
                f.locY = y0 &+ Int32(i) &* dy
                list.append(.sprite(b.hilited ? b.lit : b.normal, frame: b.frame, record: TextRequest(format: f, text: [])))
            case .logo:
                var f = a.formats[7]
                f.locX = x
                list.append(.sprite(b.normal, frame: b.frame, record: TextRequest(format: f, text: [])))
            case .web:
                list.append(.text(TextRequest(format: a.formats[b.hilited ? 2 : 1], text: b.text)))
            case .copyright:
                list.append(.text(TextRequest(format: a.formats[b.hilited ? 4 : 3], text: b.text)))
            }
        }
        state.menuElements = list
        for i in buttons.indices { buttons[i].rect = list.bounds(of: i, text: state.text, assets: a) }
        state.menuLit = lit
    }

    /// `FUN_10024cb0(id, text)`.
    private mutating func setText(_ id: Int, _ text: [UInt8]) {
        guard text.count <= 0xff, let i = buttons.firstIndex(where: { $0.id == id }) else { return }
        buttons[i].text = text
    }

    /// `FUN_10010e90` for the registered build with fewer than two copies: pgsl 35 "THIS COPY IS REGISTERED TO %s",
    /// the name upper-cased (question 2: `FrontEndState.registeredName`).
    private func bannerText(_ state: FrontEndState) -> [UInt8] {
        let format = state.assets.gameString(35) ?? "THIS COPY IS REGISTERED TO %s"
        return Self.bytes(format.replacingOccurrences(of: "%s", with: state.registeredName.uppercased()))
    }

    // MARK: - Helpers

    private mutating func enqueue(_ keys: HeldKeys) {
        queue += keys.events.map(Event.shell)
        let command = !keys.held.isDisjoint(with: Self.commandKeys)
        queue += keys.keyEvents.map { Event.key($0, command: command) }
        queue += keys.mouseDowns.map(Event.click)
    }

    /// `FlushEvents(0xffff, 0)` (`FUN_10048e30`): the keys and mouse-downs go; the shell's events stay queued, as
    /// FlushEvents leaves suspend, resume and Apple Events in the queue.
    private mutating func flushEvents() {
        queue.removeAll { if case .shell = $0 { return false } else { return true } }
    }

    private func sound(_ i: Int, _ state: FrontEndState) -> SoundCue {
        SoundPlay.perm(state.assets.sounds[i], priority: 0x4b, volume: 100, allowMultiple: false)
    }

    /// The rect test of `FUN_10024530` / `FUN_10024a50`: inclusive on all four sides. No point (outside the picture)
    /// is inside nothing.
    static func inside(_ p: MousePoint?, _ r: MacRect) -> Bool {
        guard let p else { return false }
        return p.h >= r.left && p.h <= r.right && p.v >= r.top && p.v <= r.bottom
    }

    static func inMenuBarStrip(_ p: MousePoint?) -> Bool {
        inside(p, MacRect(top: screen.top, left: screen.left, bottom: menuBarHeight, right: screen.right))
    }

    static func bytes(_ s: String) -> [UInt8] { MacRoman.encode(s, lossy: true) ?? [] }

    static let back = FourCC("back")!
    static let inmu = FourCC("inmu")!
}
