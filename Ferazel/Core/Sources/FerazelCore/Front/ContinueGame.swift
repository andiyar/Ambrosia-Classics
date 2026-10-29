import Foundation

/// F1b: `.ContinueGame(reply) @ 1000d004` (M l. 6663–7102; bank save-continue §3.4, §4) — the **default branch** only:
/// `fd5c` is set to 1 before the test and the replica always opens its default world, so the fallback branch (the
/// world named in the save, its stamp check, its `GammaFadeOut(6)` / PICT 129 / `.HideTheMenuBar` at M l. 6874–6878 and
/// its single `.GameLoop`) never runs.
///
/// `FlushEvents`, `MTShowWindow`, `.InitGameGlobals`, `.OpenSG(reply)` (`reply` nil — the menu's Continue, the File
/// menu's Restore — → `GammaFadeIn(0x14)` only when the screen is faded, then `PromptGetFile("Please select the saved
/// game from which you would like to continue.")` (0x100a59db): `ShellRequest.getFile`; else the given reply, `fd18`
/// when `fd48` is set). A cancel → `MTRedraw`, return (nothing reported); a file without `'FWSg' 0` → "Sorry, this does
/// not appear to be a saved game file." (`SavedGameError`, SV2); success → `fd18 ← reply`, `fe00 = 1`, `fd54 = 1`.
/// Then `MTRedraw`, `KillAllSprites`, `fd5c = 1`, level ← save+8, G ← save+0x18, `*fd28 = 1` (write-only); the
/// refusals, each its own `ReportDialog` (+4 == 1 → the preview text 0x100a2ec9; +5 == 1 → the demo text 0x100a2f33;
/// level > 0x4f → the demo text again), any → `MTRedraw`, return. The default branch: `.InitMapLevelNames`,
/// `OpenDefaultWorldLevel(level)` — **design §9 (d), D35:** no `Mlvl` → "An unexpected error occurred -- the level could
/// not be loaded from the world file!" (0x100a2e76, `.NewGame`'s text — the original dereferences nil here) and back to
/// the menu; save+6 == 0 → `G+0x16 ← hdr[0x26c8]` (raw `1000d684/88`), else the snapshot copied into the level (x/y +6)
/// — `LevelRun`'s revisit restore (`hasSnapshot[L] == 1`, which every snapshot save sets); **no world-stamp check**;
/// `FadeAIFFMusic(0, 2)` + `ShutDownAIFFMusic` once (M l. 7040–7041), `5106 = 0`, `0088 = 0`; the loop body is only
/// `ResetCursor` + `.GameLoop(save+0xc, save+0x10, 0, 0)` + the map logic (no per-level music fade, no `G+0x16`
/// refresh); the death test reads `ffa8` (`NewGame.swift`'s `afterLoop`).
extension GameFlow {
    /// 0x100a59db.
    public static let continuePrompt = "Please select the saved game from which you would like to continue."
    /// 0x100a2ec9.
    public static let previewRefusal =
        "Sorry, this saved game was saved with a preview version of Ferazel and can not be used with this version."
    /// 0x100a2f33.
    public static let demoRefusal =
        "Sorry, this saved game was saved with a demo version of Ferazel and can not be used with this version."
    /// `0x4f < save+8`: a level only the full version has.
    static let lastDemoLevel: Int16 = 0x4f

    /// `.ContinueGame(reply)` (nil = `0`: ask for the file).
    func continueGame(_ reply: SavedGameRef?, _ out: inout FrontOutput) {
        state = .continueGame
        menuLoopListening(false, &out)                                  // the menu loop left (A1b)
        run([
            { f, now, _, out in
                // `FlushEvents(0xff7f, 0)`, `MTShowWindow`, `.InitGameGlobals` (M l. 6705–6707), then `.OpenSG`.
                f.flushEvents()
                f.initGameGlobals()
                f.fileAnswer = nil
                if let reply {
                    f.fileAnswer = .chosen(reply)
                } else if f.fade.faded {
                    f.gammaFadeIn(now, &out, 0x14)                       // `if (*fde8) GammaFadeIn(0x14)`
                }
            },
            { f, _, _, out in
                guard f.fileAnswer == nil else { return }
                out.requests.append(.getFile(prompt: Self.continuePrompt))
                f.wait = .file
            },
            { f, _, _, out in f.openSG(&out) },
        ])
    }

    /// `.OpenSG`'s read (bank §3.4).
    private func openSG(_ out: inout FrontOutput) {
        let answer = fileAnswer
        fileAnswer = nil
        guard case .chosen(let ref) = answer else {
            continueReturns(&out)                                       // `sfGood` 0: return 0
            return
        }
        do {
            let block = try files.readSavedGame(ref)
            saveBlock = block
            opened(ref)
            run([{ f, _, _, out in f.continueLoaded(&out) }])
        } catch {
            let e = error as? SavedGameError ?? .notASavedGame
            // `ResError() ≠ 0` after the close comes after the reply, `fe00` and `fd54` are stored.
            if e == .openFailed { opened(ref) }
            report(e.message, &out)
            run([{ f, _, _, out in f.continueReturns(&out) }])
        }
    }

    /// `fd18 ← reply`, `*fe00 = 1`, `*fd54 = 1`.
    private func opened(_ ref: SavedGameRef) {
        lastReply = ref
        savedThisGame = true
        saveFileKnown = true
    }

    /// `MTRedraw`; return to the menu loop.
    private func continueReturns(_ out: inout FrontOutput) {
        out.present = true
        state = .mainMenu
        menuLoopListening(true, &out)
    }

    /// M l. 6712–6744: the block taken in, the refusals, the default branch.
    private func continueLoaded(_ out: inout FrontOutput) {
        // `MTRedraw`, `KillAllSprites`, `*fd5c = 1`, `_DAT_100ab9ba = *feac = save+8`, G ← save+0x18, `*fd28 = 1`.
        out.present = true
        defaultWorld = 1
        levelNumber = Int(saveBlock.level)
        globals = saveBlock.globals
        let preview = saveBlock.preview == 1
        let demo = saveBlock.demo == 1
        let full = saveBlock.level > Self.lastDemoLevel
        var items: [Work] = []
        if preview { items.append { f, _, _, out in f.report(Self.previewRefusal, &out) } }
        if demo { items.append { f, _, _, out in f.report(Self.demoRefusal, &out) } }
        if full { items.append { f, _, _, out in f.report(Self.demoRefusal, &out) } }
        items.append { f, _, _, out in
            if preview || demo || full {
                f.continueReturns(&out)
                return
            }
            f.defaultBranch(&out)
        }
        run(items)
    }

    /// The default branch (M l. 6916–7041) up to the loop.
    private func defaultBranch(_ out: inout FrontOutput) {
        // `.InitMapLevelNames`, `OpenDefaultWorldLevel(*feac)`.
        guard let h = try? LevelFile.load(from: resources, level: Int16(truncatingIfNeeded: levelNumber)).header else {
            report(Self.levelLoadError, &out)                           // design §9 (d), D35
            run([{ f, _, _, out in
                f.state = .mainMenu
                f.menuLoopListening(true, &out)
            }])
            return
        }
        // ◇ D35: a saved game naming a level the replica cannot run yet (an original save from level 5 on) gets the
        // not-built report and the menu, as New Game's map does — never a level with unbuilt sprites (gap ledger #1).
        // A level missing from the world file keeps the original's load error above.
        guard BuiltLevels.range.contains(levelNumber) else {
            report(BuiltLevels.notBuiltReport(levelNumber), &out)
            run([{ f, _, _, out in
                f.state = .mainMenu
                f.menuLoopListening(true, &out)
            }])
            return
        }
        if saveBlock.isCheckpoint == 0 { globals.startFacing = Int16(h.startFacingLeft) }
        run([
            { f, now, _, out in
                f.block(f.toggles.music.fadeAIFFMusic(direction: 0, ticks: 2, prefs: f.toggles.live), now, &out)
            },
            { f, _, _, out in
                out.music += f.toggles.music.shutDown()
                f.loopEnded = false                                     // `DAT_100a5106 = 0`, `*0088 = 0`
                f.levelComplete = false
                f.run(f.loopIteration(continuing: true))
            },
        ])
    }
}
