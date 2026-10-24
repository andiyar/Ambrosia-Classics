import Foundation

/// The saved-game globals `.SaveSG` and `.OpenSG` share (S1): what the flow hands a `LevelRun` and reads back after it.
public struct SaveGameState: Equatable, Sendable {
    /// `*PTR_DAT_1009fe00`: something was saved or loaded this game (`.AskToContinue` shows nothing without it).
    public var savedThisGame: Bool
    /// `*_DAT_1009fd54`: the saved-game file is known — with prefs+1 ("Reuse saved game files") the next save skips
    /// the dialog.
    public var saveFileKnown: Bool
    /// `_DAT_1009fd18`: the last Standard File reply (the file last saved or opened).
    public var lastReply: SavedGameRef?

    public init(savedThisGame: Bool = false, saveFileKnown: Bool = false, lastReply: SavedGameRef? = nil) {
        self.savedThisGame = savedThisGame
        self.saveFileKnown = saveFileKnown
        self.lastReply = lastReply
    }
}

/// `.SaveSG(prompt) @ 10048294` (M l. 41179ff; save-continue §3.1 + BC6, BC23) as a machine the flow drives across the
/// Standard File panel and the error report:
/// - the old prefs+0x42 name kept (`CopyPString`);
/// - reuse (`prompt == 0 ∧ fd54`) → the reply `fd18`, no dialog; else the `^0` text ("at a checkpoint on level " /
///   "at the beginning of level " + n) is built and `ParamText`ed — DITL 1003 has no `^0`, so it is never shown and
///   not built here — `.IncrementLastSGString` on prefs+0x42 (so the shown default is already incremented), then
///   `CustomPutFile("Please name your saved game.", prefs+0x42, DITL 1003)` → `PutFileRequest`;
/// - a good reply, **in this order** (raw `100483a8`, `100483e0`, `100483f8`, `10048418`): `fd54 = 1` and the reply →
///   `fd18`; `FSpDelete` of the target; the reply's name → prefs+0x42; `.UpdateSGString` (every save, reuse included:
///   `.InitPrefs` re-reads the prefs file, +0x42 copied in, the record written, `.MakeCurrPrefs`); then `FSpCreate(…'Msct', 'FWSg')`,
///   `AddResource`, `WriteResource` (`FrontFiles.writeSavedGame`); success → `fe00 = 1`, result 1;
/// - Cancel → the old name back (the only path that restores it), result 0;
/// - a write error → `ReportError(text, code)` (`SavedGameFile.writeErrorReport`; the code is in r4 at all four calls,
///   raw `1004851c` `extsh r4,r25`), result 0 — with the state the order leaves: the old file deleted, the new name in
///   prefs (and the prefs file), reuse armed (`fd54 = 1`), kept as the original.
///
/// Deviation [LOW]: the replica's `FSpDelete` is inside `FrontFiles.writeSavedGame` (`SavedGameFile.write` removes
/// the old file first), so it happens after `.UpdateSGString` rather than before it — the file system sees the same
/// end state on every path; only the prefs write's failure (ignored by both) could tell them apart.
public struct SaveSG {
    /// What the flow must do next.
    public enum Step: Equatable, Sendable {
        /// Show the save panel; answer with `fileDone`.
        case putFile(PutFileRequest)
        /// Show the error report; answer with `reportDone`.
        case report(FerazelDialog)
        /// `.SaveSG` returned this (1 = written).
        case done(saved: Bool)
    }

    /// "Please name your saved game." (pstr `0x100a58b4`).
    public static let prompt = "Please name your saved game."

    public private(set) var state: SaveGameState
    /// The live prefs (`_DAT_1009fe44`).
    public private(set) var prefs: FerazelPrefs
    /// Set when `.UpdateSGString`'s `.MakeCurrPrefs` ran (the flow passes it on as `FrontOutput.prefs`).
    public private(set) var madeCurrent = false
    /// The music cues `.MakeCurrPrefs` made (only when the stored music flag differs from the applied one).
    public private(set) var music: [MusicCue] = []
    private var oldName: String

    public init(state: SaveGameState, prefs: FerazelPrefs) {
        self.state = state
        self.prefs = prefs
        oldName = prefs.savedGameName
    }

    /// The call: `prompt` = `SaveSG`'s argument (`.SavePointSave` passes prefs+1 == 0). `message` is DITL 1003's
    /// static text (`putFileMessage`).
    public mutating func start(prompt: Bool, message: String, block: SaveBlock, files: FrontFiles?,
                               musicFade: inout MusicFade) -> Step {
        // GameFlow always hands its `FrontFiles` to the `LevelRun` it builds (S1 fix round); a run without one (a Core
        // test that never reaches a save point) must not pretend a save was written.
        guard let files else { preconditionFailure("a save point needs the file seam (LevelRun(files:))") }
        oldName = prefs.savedGameName
        if !prompt, state.saveFileKnown, let reply = state.lastReply {
            return goodReply(reply, block: block, files: files, musicFade: &musicFade)
        }
        prefs.incrementSavedGameName()
        return .putFile(PutFileRequest(prompt: Self.prompt, defaultName: prefs.savedGameName, message: message))
    }

    /// The panel's answer.
    public mutating func fileDone(_ result: FileResult, block: SaveBlock, files: FrontFiles?,
                                  musicFade: inout MusicFade) -> Step {
        switch result {
        case .cancelled:
            prefs.savedGameName = oldName
            return .done(saved: false)
        case .chosen(let reply):
            guard let files else { preconditionFailure("a save point needs the file seam (LevelRun(files:))") }
            return goodReply(reply, block: block, files: files, musicFade: &musicFade)
        }
    }

    /// The error report was dismissed: `.SaveSG` returns 0.
    public func reportDone() -> Step { .done(saved: false) }

    private mutating func goodReply(_ reply: SavedGameRef, block: SaveBlock, files: FrontFiles,
                                    musicFade: inout MusicFade) -> Step {
        state.saveFileKnown = true
        state.lastReply = reply
        prefs.savedGameName = reply.displayName
        updateSGString(files: files, musicFade: &musicFade)
        do {
            try files.writeSavedGame(block, to: reply)
        } catch {
            let r = SavedGameFile.writeErrorReport(osErr: error.osErr)
            return .report(.error(text: r.message, code: error.osErr))
        }
        state.savedThisGame = true
        return .done(saved: true)
    }

    /// `.UpdateSGString @ 1000e118` (M l. 7155ff): `.SetPrefFile` + `.InitPrefs` (the stored record, or the defaults),
    /// prefs+0x42 copied into it, `ChangedResource` + `WriteResource`, `.MakeCurrPrefs` (the record → the live prefs;
    /// not paused — a save runs inside a frame). The applied music flag `fd20` is the live +0x0c (every
    /// `.MakeCurrPrefs` leaves them equal), so the music part acts only when the file's flag differs.
    private mutating func updateSGString(files: FrontFiles, musicFade: inout MusicFade) {
        var record = files.loadPrefs().map(FerazelPrefs.init(record:)) ?? FerazelPrefs()
        record.savedGameName = prefs.savedGameName
        try? files.storePrefs(record.record())
        var toggles = PrefsToggles(live: prefs, music: musicFade)
        let out = toggles.makeCurrPrefs(record, paused: false)
        prefs = toggles.live
        musicFade = toggles.music
        music += out.music
        madeCurrent = true
    }

    /// DITL 1003 (`CustomPutFile`'s dialog, `.PromptPutFile` raw `10042590` `li r6,0x3eb`) item 13's static text —
    /// "Your saved game will reflect your position as of the most recent checkpoint." (empty when the resource is
    /// absent).
    public static func putFileMessage(resources: FerazelResources) -> String {
        guard let d = try? DialogItemList.load(from: resources, id: 1003), d.items.count >= 13 else { return "" }
        return d.items[12].text ?? ""
    }
}

/// `.SavePointSave @ 1000c104` (M l. 6322–6499; save-continue §2.2 + BC23) — the flow's part of a save point, between
/// the session's suspension and its `resume`.
enum SavePointSave {
    /// The block written at that moment (raw `1000c104..1000c2d8`, after `InputActivate(0, 0)` and
    /// `FlushEvents(0xff7f)` — nothing to do in Core): SV1's writer with the stamp, `GetDateTime`, the player's whole-
    /// pixel x / y of this frame's handler pass (`*fe68` / `*fe64`, sign-extended), the live G and records.
    static func write(_ save: inout SaveBlock, session s: FerazelSession, stamp: UInt32, date: UInt32) {
        var g = s.world.globals
        save.savePointSave(level: Int16(s.levelNumber), x: s.world.player.pixelX, y: s.world.player.pixelY,
                           stamp: stamp, date: date, globals: &g, records: s.world.records)
        s.world.globals = g
    }

    /// After `.SaveSG` (raw `1000c804..1000c888`): `MTRedraw` (the window from the back screen — the replica's panel
    /// never covers the canvas: a present only), then — not paused (`*_DAT_100a0050 == 0`, always inside a frame) —
    /// `RedrawEntireScrollGrid`, `ResetCursor` (no op), `HideCursorSafe`, `fe0c = 1`, `511e = 1` (no Core reader),
    /// `RedrawGameArea` (M l. 6491, raw `1000c870`: `DrawBlackLines` in graphics mode 3 with `5107`, M l. 37849, then
    /// `.WrapCopyToScreen` at the scroll point — `GameLoopKeys.redrawGameArea`, P1 review fix), `UpdateStatusBar(0, 0,
    /// 0)` (M l. 6492; HU: its key step reads `keys`, the tick's poll).
    static func redraw(session s: FerazelSession, prefs: FerazelPrefs, keys: KeyState = KeyState()) -> FrontOutput {
        let h = s.camera.scrollH, v = s.camera.scrollV
        let draws = [.redrawEntireScrollGrid(h: h, v: v)] + GameLoopKeys.redrawGameArea(h: h, v: v, prefs: prefs)
        let bar = s.updateStatusBar(.savePointSave, keys: keys)              // its snd 442 at the call (M l. 4492)
        return FrontOutput(draws: draws + bar.draws, sounds: bar.sounds,
                           requests: [.hideCursor], present: true)
    }
}
