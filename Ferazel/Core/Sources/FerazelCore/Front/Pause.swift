import Foundation

/// What `.CheckGameLoopKeys` stopped the frame for (P1, `FrameSuspension.gameLoopKeys`). The flow runs it and resumes
/// with `GameLoopKeyAnswer`.
public enum GameLoopKeyEvent: Equatable, Sendable {
    /// ⌘Q (0x37 + 0x0c): "Are you sure you want to quit?" (DLOG 202).
    case confirmQuit
    /// ⌘W (0x37 + 0x0d, `escape` false) or Esc (0x35, `escape` true): "Are you sure you want to abort this game?".
    case confirmAbort(escape: Bool)
    /// ⌘P (0x37 + 0x23): `.Options` (DLOG 6900, O1).
    case options
    /// Caps Lock down (`.CapsLockDown()`, debounce `fe14` 0): `.Pause`'s entry is starting; the flow answers
    /// `.pausePaint` when it reaches `.PaintFrameWrap(1, 0)` (M l. 3190).
    case pause
    /// `.Pause`'s `.PaintFrameWrap(1, 0)` is drawn; the flow runs the rest of `.Pause` and answers `.pauseEnded`.
    case paused
    /// ⌘Q's OK tail is made (`.PaintFrameWrap(1, 1)`, `.UpdateStatusBar`): `.Quit` follows, which never returns — the
    /// frame is never resumed.
    case quit
}

/// The flow's answer to a `.gameLoopKeys` suspension, with the polled input at that moment.
public struct GameLoopKeyAnswer: Equatable, Sendable {
    public enum Reply: Equatable, Sendable {
        /// `.ConfirmAbortGameDialog`'s return: OK (true) or Cancel.
        case confirm(ok: Bool)
        /// `.Options` returned (the live prefs already written into the session).
        case optionsClosed
        /// `.Pause` reached its `.PaintFrameWrap(1, 0)`.
        case pausePaint
        /// `.Pause` returned; `aborted` = File ▸ Abort Game's OK inside it set `DAT_100a5106`.
        case pauseEnded(aborted: Bool)
    }

    public var reply: Reply
    /// The keys a nested `.PaintFrameWrap` reads (`.IsInputKeyPressed` is live in the original).
    public var keys: KeyState
    /// `.CapsLockDown()` for the Caps Lock test after a confirm.
    public var capsLock: Bool

    public init(reply: Reply, keys: KeyState = KeyState(), capsLock: Bool = false) {
        self.reply = reply
        self.keys = keys
        self.capsLock = capsLock
    }
}

/// `.CheckGameLoopKeys @ 10007684` (M l. 3861–4030; plan P1, engine §7.2, save-continue §6) — the key part. The
/// session calls it after `.PaintFrameWrap` and before `.UpdateSprites` (M l. 5251) and suspends the frame on a branch;
/// the flow (`LevelRun`) runs the modal.
///
/// Whole routine, in the binary's order: return at once while faded (`*_DAT_1009fde8`) or while an async fade runs
/// (`DAT_100a53d6 == 0`) — not even the counters run. ⌘ (0x37) held: S (0x01) → nothing; Q (0x0c) → the quit confirm;
/// W (0x0d) → the abort confirm; P (0x23) → `.Options`; else the ⌘⇧⌥;0 debug chord (out of scope, Rulings 1). Else Esc
/// (0x35) → the abort confirm; else the debug keys F11 / C+S / F5 (debug flag only — out of scope). Every confirm is
/// preceded by `.RestoreWindowBackground` (`DrawBlackLines` in graphics mode 3), `ShowCursorSafe`, `FlushEvents`,
/// `InputActivate(0, 0)`. Then the debounce counters `*_DAT_1009fddc` and `PTR_DAT_1009fe14` (−1 while > 0; neither is
/// ever set > 0 — BC15), then `CapsLockDown() && fe14 == 0` → `.Pause`.
///
/// The confirms' tails (the session's, `FerazelSession.resume`): ⌘Q / ⌘W / Esc OK → `.PaintFrameWrap(1, 1)` (a whole
/// drawn pass: Handles, collisions, erase), `DrawBlackLines` (mode 3), `DAT_100a5106 = 1`, `FlushEvents`,
/// `.UpdateStatusBar(0, 0, 0)` — and ⌘Q `.Quit`; ⌘Q / ⌘W Cancel → `.RedrawEntireScrollGrid`, `DrawBlackLines` (mode
/// 3), `.UpdateStatusBar(0, 0, 0)`; Esc Cancel → `.RedrawEntireScrollGrid`, `DrawBlackLines` (mode 3),
/// `.PaintFrameWrap(1, 1)`, `.UpdateStatusBar(0, 0, 0)`; ⌘P → `.SetScrollLocation`, `.RedrawEntireScrollGrid`,
/// `.UpdateStatusBar(0, 0, 0)`, `fe0c = 1`, `511e = 1`, `DrawBlackLines` (mode 3). DLOG 202's item-5 Save branch is
/// dead (BC26) and not built.
///
/// `DrawBlackLines` (graphics mode 3 only) is `DrawOp.drawBlackLines`: mode 3's copy skips the odd rows, so whatever was
/// drawn over the view there (a dialog in the original, the pause banner in both) stays until they are blackened.
public enum GameLoopKeys {
    /// 0x100a2ccd (the pstr `ParamText` gets; the same text as the map's 0x100a6d69).
    public static let quitText = WorldMapRun.quitText
    /// 0x100a2cec (`s_Are_you_sure_you_want_to_quit__A_100a2cce + 0x1e`; the map's 0x100a6d88).
    public static let abortText = WorldMapRun.abortText

    static let command = 0x37, keyS = 0x01, keyQ = 0x0c, keyW = 0x0d, keyP = 0x23, escape = 0x35

    /// The branch the polled keys take (nil = none of the built ones).
    public static func branch(_ keys: KeyState) -> GameLoopKeyEvent? {
        if keys.isPressed(command) {
            if keys.isPressed(keyS) { return nil }
            if keys.isPressed(keyQ) { return .confirmQuit }
            if keys.isPressed(keyW) { return .confirmAbort(escape: false) }
            if keys.isPressed(keyP) { return .options }
            return nil                                  // the debug chord (M l. 3938–3947): out of scope
        }
        if keys.isPressed(escape) { return .confirmAbort(escape: true) }
        return nil                                      // the debug keys (debug flag only): out of scope
    }

    /// `.RedrawGameArea @ 10042404` (M l. 37834ff): mode 3 with `5107` → `DrawBlackLines`, then `WrapCopyToScreen(…,
    /// line skip)`; else `WrapCopyToScreen(…, 0)` — the mode folded as `SavePointSave.redraw` does.
    static func redrawGameArea(h: Int, v: Int, prefs: FerazelPrefs) -> [DrawOp] {
        let backdrop = prefs.plainCopy == 0                                   // `cRam100a5107`
        let mode = Int(prefs.graphics) == 3 && !backdrop ? 1 : Int(prefs.graphics)
        let copy = DrawOp.copyToScreen(h: h, v: v, graphicsMode: mode, backdrop: backdrop)
        return Int(prefs.graphics) == 3 && backdrop ? [.drawBlackLines, copy] : [copy]
    }
}

/// `.Pause @ 10006078` (M l. 3136–3270; plan P1, engine §7.2, BC15) as a tick machine. The caller has checked the gate
/// (`DAT_100a53d6`) and runs it in three parts: `enter()` (up to `.PaintFrameWrap(1, 0)`), the paint (the session's, in
/// a level; none on the map — `fe2c` gates `.PaintFrameWrap` off), `painted(now:)`, then `tick` until `isDone`.
///
/// **Entry:** `InputActivate(0, 0)` (no InputSprocket), `ShowCursorSafe`, `SetWatchCursor`, snd **198** (`STPlayRegSound(
/// uRam100ab9bc, 100, 0x100)`, `FUN_10091748(0xc6)` M l. 350); not on the map (`*fe2c == 0`): `SetScreenClut(level
/// clut)`; `MTSetScreenPtrsToBackScreen`, `.PaintFrameWrap(1, 0)`, the status strip (16, 392)–(624, 480) copied from
/// the status-bar port onto the back screen, PICT **4921** into (207, 152)–(432, 248) (l, t, r, b) offset by the sprite
/// world's (+0x48, +0x46) — both 0, set once by `.MTInit` (M l. 30157–30159), no other writer — `MTRedraw`; the pause
/// flag `*_DAT_100a0050 = 1`, `*fe28 = 0`, voices 452 / 511 stopped (`*fe24`, `*fe20`), `*fe88 = 0`, `FadeAIFFMusic(0,
/// 1)` (24 ticks), `ShowTheMenuBar` + `DrawMenuBar`, `.UpdateMenus` (paused: New Game / Restore disabled, Abort Game
/// enabled), `ResetCursor`, `MTRedraw`, the sleep proc. One screen surface in the replica: the back-screen compositing
/// and the strip copy (the status bar is already on it) need no op [MED].
///
/// **Loop:** Caps Lock already up → the flag cleared, no loop. Else (`*fe38 = 1`) one poll per tick (`.CheckEvent` =
/// `WaitNextEvent(…, 1, …)` [MED: one tick]): the menu events (`.HandleMenuSelection`: File ▸ Abort Game → `.AbortGame`;
/// Game ▸ Music / Sound Effects → O1's toggles, paused); then the counter, from **10**: −1 while Caps Lock is up, the app
/// active (`DAT_100a5108`) and no sleep pending (`*fe40`, `.MySleepProc` — never in the replica), else **5**; unpause at
/// 0.
///
/// **Exit:** `SleepQRemove`; the system-volume sync (prefs +0x36 / +0x38 — never the Mac's volume, Known deviation 8);
/// the music flag changed during the pause → `SetMusicAIFFVolume(0)`, `SetAIFFMusic(5be0)` when on, then the volume
/// (V or 0) — **then** `FadeAIFFMusic(1, 2)` (48 ticks; the dump's order, the plan put the fade first);
/// `SwitchTo8BitColorMT` (nothing), `MTRedraw`, `fe14 = 0` (the caller's), `HideTheMenuBar`, `MTRedraw`, not on the map:
/// `.RedrawEntireScrollGrid`; `HideCursorSafe`, `fe0c = 1`, `511e = 1`, not on the map: `.RedrawGameArea`;
/// `InputActivate(1, 0)` (nothing).
public struct PauseRun {
    /// The menu items the pause loop acts on (A1b delivers them; New Game / Restore are disabled while paused).
    public enum MenuItem: Equatable, Sendable {
        /// File ▸ Abort Game (`.AbortGame @ 1000bec0`).
        case abortGame
        /// Game ▸ Music, ⌘M (`.ToggleMusic`).
        case music
        /// Game ▸ Sound Effects, ⌘F (`.ToggleSound`).
        case soundEffects
    }

    /// The scroll point a level's exit redraw uses (`PTR_DAT_1009fe78`).
    public struct Scroll: Equatable, Sendable {
        public var h: Int
        public var v: Int

        public init(h: Int, v: Int) {
            self.h = h
            self.v = v
        }
    }

    /// snd 198 (`uRam100ab9bc`).
    public static let sound: Int16 = 198
    /// PICT 4921 (0x1339) and its rect `SetRect(0xcf, 0x98, 0x1b0, 0xf8)`, offset by (+0x48, +0x46) = (0, 0).
    public static let banner: Int16 = 4921
    public static let bannerRect = Rect16(top: 0x98, left: 0xcf, bottom: 0xf8, right: 0x1b0)
    /// The counter's start and its reset (`sVar11`).
    public static let counterStart: Int16 = 10
    public static let counterReset: Int16 = 5

    /// `*PTR_DAT_1009fe2c`: on the map.
    public let onMap: Bool
    /// The live prefs, `fd20`, the sound scale and the music player while paused (O1's toggles act on them).
    public private(set) var live: PrefsToggles
    /// `*_DAT_100a0050`: the pause flag.
    public private(set) var paused = false
    /// `DAT_100a5106` set by `.AbortGame`'s OK while paused.
    public private(set) var aborted = false
    /// `sVar11`.
    public private(set) var counter: Int16 = PauseRun.counterStart
    /// The loop's polls so far.
    public private(set) var polls = 0
    /// `.Pause` has returned.
    public private(set) var isDone = false

    private let resources: FerazelResources
    private let levelClut: Int16?
    private let scroll: Scroll?
    private let files: FrontFiles?
    /// `cVar1`: prefs+0x0c at entry.
    private let musicAtEntry: UInt8

    private enum Stage: Equatable { case entry, musicOut, loop, musicIn, done }
    private var stage = Stage.entry
    private var blocking: TimelineRun?
    private var menu: MenuItem?
    private var confirming = false
    private var answer: Bool?

    /// - Parameters:
    ///   - prefs / music: the live prefs and the music player (`_DAT_1009fe44`, the QuickTime state).
    ///   - levelClut: the level's screen CLUT (`*_DAT_1009ff8c`); nil on the map.
    ///   - scroll: the level's scroll point for the exit redraw; nil on the map.
    ///   - files: the prefs file (`.ToggleMusic` / `.ToggleSound` re-read and write it).
    public init(resources: FerazelResources, onMap: Bool, prefs: FerazelPrefs, music: MusicFade, levelClut: Int16?,
                scroll: Scroll?, files: FrontFiles?) {
        self.resources = resources
        self.onMap = onMap
        live = PrefsToggles(live: prefs, music: music)
        self.levelClut = levelClut
        self.scroll = scroll
        self.files = files
        musicAtEntry = prefs.musicOn
    }

    /// Up to `.PaintFrameWrap(1, 0)` (M l. 3171–3189).
    public mutating func enter() -> FrontOutput {
        var out = FrontOutput(requests: [.showCursor])
        if live.live.soundOn != 0 {
            out.sounds.append(SoundCues.regSound(snd: Self.sound, priority: 100, volume: 0x100,
                                                 global: SoundCues.globalVolume(live.live)))
        }
        if !onMap, let c = levelClut { out.draws.append(.setScreenClut(id: c)) }
        out.present = !out.draws.isEmpty
        return out
    }

    /// After `.PaintFrameWrap(1, 0)` (M l. 3191–3204): the banner, the flag, the voices stopped, `FadeAIFFMusic(0, 1)`
    /// armed — its events come with the next `tick` (on this tick when ticked at `now`).
    public mutating func painted(now: UInt32) -> FrontOutput {
        var out = FrontOutput(present: true)
        if let size = ChapterScreenRun.frameSize(resources.resource(type: "PICT", id: Self.banner, chain: .frontEnd)?.data) {
            let source = Rect16(top: 0, left: 0, bottom: Int16(truncatingIfNeeded: size.height),
                                right: Int16(truncatingIfNeeded: size.width))
            out.draws.append(.copyPicture(id: Self.banner, chain: .frontEnd, source: source, dest: Self.bannerRect,
                                          forceClut: nil, transparent: false))
        }
        paused = true
        out.soundStops = [452, 511]
        out.soundStopAt = [0, 0]
        let t = live.music.fadeAIFFMusic(direction: 0, ticks: 1, prefs: live.live)
        blocking = t.isEmpty ? nil : TimelineRun(t, start: now)
        stage = .musicOut
        return out
    }

    /// A menu item chosen while the loop runs (taken at the next poll, as `.CheckEvent` would).
    public mutating func menuChosen(_ item: MenuItem) {
        guard stage == .loop, menu == nil else { return }
        menu = item
    }

    /// The Abort Game confirm was answered.
    public mutating func dialogDone(ok: Bool) {
        if confirming { answer = ok }
    }

    /// One tick at `now` with this tick's polled input.
    public mutating func tick(now: UInt32, input: FrontInput) -> FrontOutput {
        var out = FrontOutput()
        while !isDone {
            if var b = blocking {
                out.append(b.tick(now: now))
                guard b.isDone(now: now) else {
                    blocking = b
                    return out
                }
                blocking = nil
            }
            switch stage {
            case .entry:
                return out
            case .musicOut:
                // `ShowTheMenuBar`, `DrawMenuBar`, `.UpdateMenus`, `ResetCursor`, `MTRedraw`, `.MyInstallSleepProc`.
                out.requests.append(.showMenuBar)
                out.requests.append(updateMenus(live: true))
                out.present = true
                if !input.capsLock {
                    paused = false                                       // M l. 3211–3213
                    exit(now: now, out: &out)
                } else {
                    stage = .loop                                        // `*fe38 = 1`; the first poll next tick
                    return out
                }
            case .loop:
                guard poll(input: input, out: &out) else { return out }
                if !paused { exit(now: now, out: &out) } else { return out }
            case .musicIn:
                // `SwitchTo8BitColorMT`, `MTRedraw`, `fe14 = 0`, `HideTheMenuBar`, `MTRedraw`, the redraws, the cursor.
                out.requests.append(.hideMenuBar)
                out.requests.append(updateMenus(live: false))
                if !onMap, let s = scroll { out.draws.append(.redrawEntireScrollGrid(h: s.h, v: s.v)) }
                out.requests.append(.hideCursor)
                if !onMap, let s = scroll {
                    out.draws += GameLoopKeys.redrawGameArea(h: s.h, v: s.v, prefs: live.live)
                }
                out.present = true
                stage = .done
                isDone = true
            case .done:
                isDone = true
            }
        }
        return out
    }

    /// One loop pass: the menu event (a confirm blocks the pass until answered), then the counter. False while a
    /// confirm waits.
    private mutating func poll(input: FrontInput, out: inout FrontOutput) -> Bool {
        if let item = menu {
            switch item {
            case .abortGame:
                if !confirming {
                    // `FlushEvents`, `ShowCursorSafe`, `ParamText(abort)`, `.ConfirmAbortGameDialog`.
                    confirming = true
                    out.requests += [.showCursor, .dialog(.confirm(text: GameLoopKeys.abortText))]
                    return false
                }
                guard let ok = answer else { return false }
                confirming = false
                answer = nil
                // OK: `MTRedraw`, `DAT_100a5106 = 1`, the pause flag cleared; Cancel: `MTRedraw` (paused: nothing more).
                out.present = true
                if ok {
                    aborted = true
                    paused = false
                }
            case .music, .soundEffects:
                // `.ToggleMusic` / `.ToggleSound` (M l. 7105–7214): the record re-read, toggled, written back,
                // `.MakeCurrPrefs` (paused: the music is not restarted), `.UpdateMenus`.
                var record = files?.loadPrefs().map(FerazelPrefs.init(record:)) ?? FerazelPrefs()
                let o = item == .music ? live.toggleMusic(&record, paused: true)
                                       : live.toggleSound(&record, paused: true)
                try? files?.storePrefs(record.record())
                out.append(o)
                out.requests.append(updateMenus(live: true))
            }
            menu = nil
        }
        polls += 1
        // M l. 3217–3231 (`*fe40` — a sleep pending — is never set in the replica).
        let up = !input.capsLock && input.active
        if up && 0 < counter {
            counter -= 1
        } else {
            counter = Self.counterReset
        }
        if up && counter == 0 { paused = false }
        return true
    }

    /// M l. 3233–3257: the music restart when the flag changed, then `FadeAIFFMusic(1, 2)`.
    private mutating func exit(now: UInt32, out: inout FrontOutput) {
        if musicAtEntry != live.live.musicOn {
            var cues = live.setMusicVolume(0)
            if live.live.musicOn != 0 { cues += live.music.setAIFFMusic(Int(live.music.currentTrack)) }
            cues += live.setMusicVolume(live.live.musicOn == 0 ? 0 : MusicFade.fullVolume(live.live))
            out.music += cues
        }
        let t = live.music.fadeAIFFMusic(direction: 1, ticks: 2, prefs: live.live)
        blocking = t.isEmpty ? nil : TimelineRun(t, start: now)
        stage = .musicIn
    }

    /// `.UpdateMenus` (M l. 28763ff) as the menu state: paused enables, the check marks; `menusLive` while the loop
    /// runs (after it the bar is hidden).
    private func updateMenus(live menusLive: Bool) -> ShellRequest {
        .showMenuBarItems(MenuState(menusLive: menusLive, paused: true, musicOn: live.live.musicOn != 0,
                                    soundOn: live.live.soundOn != 0))
    }
}
