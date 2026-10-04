// Pause (plan 2026-10-04 btx-playable C4 item 7, amendment R8; FI §3g), transcribed from `_PlayGame @ 00018247`
// (00018a7e `_PauseKey` test → `_PrepareNotice(3)`; 00018f24 `_PauseGame(previousNotice, deactivated)` after the
// frame) and `_PauseGame @ 0001767b`.
//
// `_PauseKey @ 00019475` = `_GameKeyDown(0x39)`: GetKeys reports Caps Lock's LOCK STATE, so the game stays paused while
// Caps Lock is engaged (Q3 default). Never in demo. App deactivation (event kind 2 → `local_ea`) also pauses; such a
// pause ends only on reactivation with Caps Lock off (`local_61`).
//
// Cheat typing (the "OOGLE" hash buffer, its effects and their cue sites): `Cheats.swift` (C8).

/// One `_PauseGame` stay.
struct PauseState {
    /// `_PauseGame`'s first argument: the notice to restore on exit (`_GetCurrentNotice()` before `_PrepareNotice(3)`).
    let previousNotice: Int
    /// `local_61`: a Caps-Lock-off null event may end the pause (false while entered by / still in a deactivation).
    var mayResume: Bool
    /// `_PauseGame`'s cheat buffer `local_2b`, "OOGLE" at entry.
    var cheatBuffer: [UInt8] = Cheats.bufferSeed
    /// The matched cheat site's remaining calls (`Cheats.Effect.steps`).
    var steps: [CheatStep] = []
    /// A `_Delay` in progress: the pause loop is blocked until TickCount reaches this.
    var waitUntil: UInt32?
    /// Characters typed while a `_Delay` blocks the loop: still in the event queue, handled after it.
    var backlog: [UInt8] = []

    /// A cheat's `_Delay`s are still running (events — keys, the Caps-Lock-off null event — wait).
    var cheatScriptBusy: Bool { waitUntil != nil || !steps.isEmpty || !backlog.isEmpty }

    init(previousNotice: Int, deactivated: Bool) {
        self.previousNotice = previousNotice
        mayResume = !deactivated
    }

    /// `_PauseGame` entry (00017695…): `_InGameSuspend` when deactivated (shell-side), `_DisableAboutMenu`,
    /// `ST_HaltSound`, `_PauseMusic` if playing, snd 22 (0x16, 30, 0), `_SetMyCCursor(200)`, re-associate the mouse +
    /// `_SetMouse(gSavedMousePosition)` (the position saved when the game began — R8's restore happens HERE, at entry),
    /// `_ShowMyCursor`, Prefs + Full Screen enabled.
    static func entryOutput(musicPlaying: Bool) -> SessionOutput {
        var out = SessionOutput()
        out.requests = [.disableAbout(true), .haltAllSound]
        if musicPlaying { out.music.append(.pause) }
        out.sounds.append(SoundCue(slot: 0x16, priority: 0x1e, delayFrames: 0))         // _PauseGame "Stretch Bounce"
        out.requests += [.setCursor(id: 200), .restoreMousePosition, .showCursor, .enableMenus(true)]
        return out
    }

    /// `_PauseGame` exit: `_ResumeMusic` (when loaded: resume, and `_StartMusic` if the channel is not playing — so a
    /// pause taken while the music was stopped, e.g. during the death sequence, starts it), `_EnableAboutMenu`, Prefs
    /// + Full Screen disabled, the cursor warped to the screen centre (shell) and hidden, `_CompToScreen` over the
    /// whole screen. (`_PrepareNotice(previous)` is the caller's.)
    static func exitOutput(musicLoaded: Bool, musicPlaying: Bool) -> SessionOutput {
        var out = SessionOutput()
        if musicLoaded {
            out.music.append(.resume)
            if !musicPlaying { out.music.append(.start) }
        }
        out.requests = [.disableAbout(false), .enableMenus(false), .hideCursor]
        out.drawOps = [.compToScreen(QDRect(top: 0, left: 0, bottom: 480, right: 640))]
        return out
    }
}
