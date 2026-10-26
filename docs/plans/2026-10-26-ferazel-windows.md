# Ferazel's Wand on Windows — Phase W plan (contracts, not code)

> **For agentic workers:** use `superpowers:subagent-driven-development`. One Opus `fk-implementer` + one Opus
> `fk-reviewer` per task (two review legs on ⚑ MAJOR). Contracts, not code (Ben's rule, memory
> `feedback-plans-carry-contracts-not-code`): each task names the files, the behaviour, the tests and the acceptance
> numbers; the implementer writes the code test-first. **The loop never launches anything** (D42): no `open`, no
> CrossOver/Wine run of any build (game, test executable, smoke), nothing that opens a window or plays a sound.

**Goal:** a Windows build of Ferazel's Wand that does what the Mac app does today (Phase 4 as built: levels 1–4, front
end, saves, map, spells, items, controller) — cross-compiled on this Mac, staged as a zip under `out/` (never
published), with every Windows check that needs a running build handed to Ben as a script on the gate card.

**Starts from:** `main` **f7fd4ce** (Ben's Q12 night-rule commit on top of run 30's close 02015a7; Phase 4 machine-closed
at 4bca4bd). Ferazel/Core **490/0**, census **1,108/0**, Ferazel BUILD SUCCEEDED, HectorKit **35a85ba** clean, floor
**361**. **Rulings land in D43** (D42 = Ben's Q12). Phase name: **Phase W** (D41 moved design §8 row 7's Windows half
forward; Phase 7 keeps only the notarized DMG and whatever Windows work is left).

**Model:** `docs/plans/2026-10-06-btx-windows.md` (BTX W0–W7) and what it left in the tree — `tools/windows/`
(toolchain pins, `build.sh`, `proof-b.sh`, `run-in-crossover.sh`, `stage-btx.sh`, README traps), HectorKit `HectorSDL`
(`~/Developer/HectorKit/SDL`), `HectorAudio.PCMMixer` / `PCMPullSource`, `HectorInput.ShellPadTranslator`, and
`BubbleTroubleX/Windows/` (BTXWinKit: driver, key script, prefs file, start-up checks, in-window dialogs, baked fonts).
Reuse, don't rebuild; **no HectorKit change** (Ruling 17).

## Planner's measurement (2026-10-26, build only)

`WIN_BUILD_ROOT=/tmp/… tools/windows/build.sh Ferazel/Core all --tests` with the installed toolchain: **every Core and
Render source and `ferazel-census` compile for Windows as they are** (`ferazel-census.exe` linked; `FerazelRenderTests`
compiled), the one blocker is `Ferazel/Core/Tests/FerazelCoreTests/FerazelDataTests.swift:41,43,44` (`setenv` /
`unsetenv` are POSIX — not in the Windows CRT module). Core is already Foundation + HectorKit only (G7), MacRoman goes
through `HectorResources.MacRoman` everywhere (`FerazelPrefs.swift:197,202`, `SaveName.swift:19,51,53`,
`LevelFile.swift:200`, `TextRasterizer.swift:33`, `ScreenRenderer.swift:209`), no `UserDefaults` in Core (the game's
prefs are a file, `PrefsFile`), and the data has **no QuickTime-JPEG pictures** (`docs/ferazel/data-census.md` names no
codec) — so BTX's W0.5 predecode is not needed. Risks Proof B could still show (pre-empted in WF0): `CensusTests.swift:18–23`
looks for `ferazel-census` without `.exe`; `FerazelDataTests.swift:36` makes symbolic links (Windows needs a privilege;
Wine varies); `FerazelCensus.swift:63,560–561` call `replacingOccurrences`, which traps in Foundation-on-Windows on
non-ASCII strings past ~64 bytes (D19.5).

## Architecture

```
Ferazel/Core (unchanged packages; Foundation + HectorKit)      FerazelCore · FerazelRender · ferazel-census
Ferazel/Shared/   NEW — platform-neutral shell half, Foundation + FerazelCore/Render only, compiled by BOTH shells
   FerazelDriver.swift      boot, renderers, segment routing, present → RGBA, level services, load servicing, settings
   FerazelAudio.swift       moved from App: cue order, music track rule, over a `FerazelMixer` protocol
   FerazelMenuRules.swift   MBAR 128 enable rules + ⌘-key fall-through (from FerazelMenus)
   CoreTextRasterizer.swift moved from App, whole file `#if canImport(CoreText)` (Mac only; the bake oracle)
Ferazel/App/      Mac shell (AppKit + HectorShell): window, menus, dialogs, panels, cursor, quit events, pad poll
Ferazel/Windows/  NEW SwiftPM package "FerazelWindows" (platforms macOS 26 = HectorSDL's floor; BTX shape)
   FerazelWinKit   Foundation-only library: symlinks to every Ferazel/Shared file + the Windows-only logic
                   (loop, input, shortcuts, files, args, start-up, baked text, in-window dialogs) — swift-test-able on the Mac
   FerazelWin      thin executable: HectorSDL glue + Win32 file dialogs (`#if os(Windows)`)
   fz-bake-font    Mac-only executable: bakes Resources/Fonts/*.fzfont from the Mac's own CoreText path
```

The Mac app keeps its behaviour byte for byte; it calls `Ferazel/Shared` for the neutral half (Ruling 1). Files are
shared by **per-file git symlinks** into `FerazelWinKit` (BTX D36's `BTXPadLayout.swift` precedent, `tools/windows/README.md`
"Gamepad"), and the Xcode target compiles `Ferazel/Shared` directly (`project.yml` source path).

## Ladder

| after | Ferazel/Core (`swift test`, G2) | FerazelWinKit (`cd Ferazel/Windows && swift test`, GW2) |
|---|---|---|
| start | 490 | — (package does not exist) |
| WF0 | 490 (3 test files + census source edited, no test added) | — |
| WF1 ⚑ | 490 | **14** |
| WF2 | 490 | **24** (+10) |
| WF3 ⚑ | 490 | **40** (+16) |
| WF5 | 490 | **48** (+8) |
| WF4a | 490 | **58** (+10) |
| WF4b ⚑ | 490 | **70** (+12) |
| WF6 | 490 | 70 |

**Proof B (Ben's script, not a loop gate):** the Core suite cross-built and run in CrossOver —
**490 passed / 0 failed / 0 skipped / 0 crashed (of 490)**. No skip rule is planned: data tests get the data through
`FERAZEL_DATA` (Windows path), `CensusTests` finds `docs/ferazel/data-census.md` through the copy's repo layout, WF0
removes the three known Windows differences. Any miss Ben reports becomes a WF0-style parity task with a ruling, as
BTX's 260-of-261 was (D18.1). A count other than 490 in the `--list-tests` line is itself a finding.

## Gates (copy literally; `$WT` = the run's worktree)

Mac gates kept from `docs/NEXT.md` GATES: **G1** HK untouched (`git -C ~/Developer/HectorKit status --porcelain` empty;
`log --oneline -1` = 35a85ba), **G2** Core 490/0, **G3** census `Totals: items 1,108 decoded, failures 0` (WF0 — it edits
the census — and every wave end), **G5** Ferazel app `** BUILD SUCCEEDED **` (every task touching `Ferazel/App`,
`Ferazel/Shared` or `project.yml`, and every wave end), **G6** scope fence ⊆ the task's Files, **G7** layering, **G10**
clean tree. **No G9 and no launch step anywhere in this phase** (D42). New gates — all build-only:

```sh
WT=$PWD; SCRATCH=$(mktemp -d)
WINB=$HOME/Developer/Toolchains/windows-cross/build/ferazel   # NEVER the default root: build.sh:47 names the scratch dir
                                                              # after the package folder, and BTX's packages are also
                                                              # called Core and Windows (Ruling 19)
# GW1 Core + its tests cross-build for Windows (build only; never run): exit 0, then 2
WIN_BUILD_ROOT="$WINB" "$WT/tools/windows/build.sh" "$WT/Ferazel/Core" all --tests > "$SCRATCH/gw1.log" 2>&1; echo $?
grep -cE '/(FerazelCorePackageTests|ferazel-census)\.exe$' "$SCRATCH/gw1.log"
# GW2 the Windows package's macOS-hosted tests: first number = the ladder's, second = 0
cd "$WT/Ferazel/Windows" && swift test > "$SCRATCH/fw.log" 2>&1; grep -cE "^Test Case '.*' (passed|failed|skipped) \(" "$SCRATCH/fw.log"; grep -cE "^Test Case '.*' (failed|skipped) \(" "$SCRATCH/fw.log"
# GW3 (from WF3) the game cross-builds and links for Windows (build only): exit 0, then 1
WIN_BUILD_ROOT="$WINB" "$WT/tools/windows/build.sh" "$WT/Ferazel/Windows" FerazelWin --sdl > "$SCRATCH/gw3.log" 2>&1; echo $?
grep -cE '/FerazelWin\.exe$' "$SCRATCH/gw3.log"
# GW4 (from WF3) the Mac SDL development build compiles (never run): last line "Build complete!" (or "Compiling …" free of errors)
cd "$WT/Ferazel/Windows" && swift build --product FerazelWin 2>&1 | tail -n 1
# G7W layering for the new code: empty (CoreTextRasterizer is the one guarded Mac-only file)
grep -rlE '^import (AppKit|Carbon|CoreGraphics|CoreText|AVFoundation|Metal|QuartzCore|SwiftUI|UIKit|HectorShell|HectorSDL|CSDL3)' \
  "$WT/Ferazel/Shared" "$WT/Ferazel/Windows/Sources/FerazelWinKit" | grep -v '/CoreTextRasterizer\.swift$'
# GW-symlinks: every Ferazel/Shared file has its FerazelWinKit symlink, mode 120000 (empty output)
for f in "$WT"/Ferazel/Shared/*.swift; do n=${f:t}; git -C "$WT" ls-files -s "Ferazel/Windows/Sources/FerazelWinKit/$n" | grep -q '^120000' || echo "missing $n"; done
# GW5 (WF6 and every phase end) stage: exit 0; PE subsystem 2 (Windows GUI); the zip's file list = the script's manifest
bash "$WT/tools/windows/stage-ferazel-win.sh" --no-desktop; echo $?
"$HOME/Developer/Toolchains/windows-cross/swift-6.4.0-RELEASE.xctoolchain/usr/bin/llvm-objdump" -p "$WT/out/Windows/Ferazel's Wand/Ferazel's Wand.exe" | grep -i subsystem
diff <(zipinfo -1 "$WT/out/Windows/Ferazel's Wand (Windows).zip" | sort) <(sort "$WT/out/Windows/Ferazel's Wand/MANIFEST.txt")   # empty
```

Implementers run their task's gates; reviewers re-run them independently (reviewers build in a `mktemp` copy with
their own `WIN_BUILD_ROOT`, never the seat's).

## Rulings (D43 — seat, under D34's plan authority; Ben reads later)

1. **One neutral shell half, shared by symlink.** The platform-neutral part of `FerazelController` (boot, renderers,
   segment routing, present, level services, load servicing, settings) and all of `FerazelAudio` move to
   `Ferazel/Shared/`, compiled by the Mac target and symlinked into `FerazelWinKit`. *Why:* D41's lockstep — a Phase 5
   change to what the shell does must land once, not twice; BTX's "port, don't share" (D15.5) existed only because Ben
   was playtesting that Mac app; here the Mac app's behaviour is held by G2/G5 and reviewers read the move line by line.
   *Rejected:* a copy-port (drifts); a new target in `Ferazel/Core` (Core's 490 ladder and G7 would carry shell code).
2. **Text without CoreText = glyphs baked from the Mac's own CoreText path.** `fz-bake-font` (Mac) runs the very
   `CoreTextRasterizer` the Mac app uses (moved to Shared, Mac-only by `#if canImport(CoreText)`) and writes, per face
   the game draws, every byte 0x00–0xFF's coverage mask, `charWidth`, plus `fontInfo`, and a whole-string cache for the
   closed status-bar strings (every level name the data holds, `"x"`). Faces (the only text sites —
   `StatusBar.swift:152,196–197,217–218`, `ConversationRun.swift:474,488,505`): Times 12 bold, Geneva 9 plain, Geneva 8
   bold, Times 18 plain; plus the dialog face (WF4). **Measured equal on the Mac:** byte-for-byte equality with
   CoreText for every glyph, width and cached string; end-to-end frame-index equality on the level-1 golden route and
   the sign/conversation route (FNV of the 640×480 indices, baked vs CoreText); a staleness test (fresh bake = committed
   files) so any later change to the Mac's text path fails the Windows suite until re-baked. Strings outside the cache
   (score, coin and item counts) compose glyph by glyph on whole-pixel advances; WF2 measures them against CoreText
   (exact expected — Times digits are tabular at a whole-pixel advance below the 14 pt smoothing threshold; if not, the
   BTX W2 bar applies: width ±1 px, ≤ 2 % of touched pixels, recorded). Classic Times/Geneva (D39, Q8) later = re-bake.
3. **Saved-game panels → the native Windows Open / Save dialogs** (comdlg32 `GetOpenFileNameW` / `GetSaveFileNameW`
   through Swift's `WinSDK`, Explorer style, in the executable under `#if os(Windows)`; no HectorKit change). *Why:* Ben's
   Q3 (2) chose the platform's own panels on the Mac; this is the same choice on Windows; it is modal and synchronous like
   `NSSavePanel.runModal` (`FerazelController.swift:570–608`), so the flow is held still the same way. Title = the
   prompt, start folder = the saves folder (created first), default name = the flow's, made Windows-legal (Ruling 10).
   *Rejected:* the original's Standard File (DITL 1003/1500) drawn in-window (faithful look, but a file browser to build
   and Ben chose modern panels on the Mac) — owner choice, Questions WQ2; SDL3's file dialog (HectorSDL would need a
   change, and it is asynchronous).
4. **The original's dialogs drawn in-window** (D15.3, BTX W6): DLOG 202 confirm, 200 report/error, 6900 Options, 600
   Credits — modal over the canvas, the flow not ticking meanwhile, behaviour per `Ferazel/App/Dialogs/*` (itself the
   transcription), look per the Mac's classic style (`DialogViews.swift:1–20`: black outlines on the `dctb` grey,
   system font 12, OK ring), not BTX's. Code: adapted copies of BTXWinKit's `DialogRenderer` / `DialogWindow` /
   `DialogSystem` (BTX's package untouched — its types are BTX-bound: `BTXPrefs`, `ArtBank`, its `SoundCue`).
5. **No menu bar** (D21, re-ruled for Ferazel as design §7.4 promised). MBAR 128's commands stay reachable exactly as
   their ⌘ keys are on the Mac: Ctrl+N / O / W / Q / M / F / P act as the menu pick only where the Mac's menus are live
   (`MenuState.menusLive` — main menu and pause), with the Mac's enable rules (`FerazelMenus.swift:114–121`) and the
   main menu's letter fall-through (`:130–152`), moved to `Ferazel/Shared/FerazelMenuRules.swift` so both shells use one
   rule; elsewhere Ctrl+letter reaches the game as ⌘+letter in the polled keys, as on the Mac (a level's ⌘Q/⌘W/⌘P).
   A taken shortcut never enters the held keys (on the Mac the menu consumes the key-down). About has no shortcut (as
   D21): Credits stays on the main menu. Check marks have nowhere to show (the pause banner is the original's).
6. **Keys** (D18.5 map, unchanged HectorSDL): Ctrl = ⌘, Alt = ⌥, Windows key = ⌃, right-hand modifiers folded to the
   left ones (`FerazelController.swift:384–392`, moved to Shared). Keypad defaults kept (SDL reports keypad scancodes
   0x52–0x5C, `SDLKeymap.swift:64–67`); Num Lock behaviour on a real keyboard is on Ben's card. Remapping = the Options
   dialog, as the Mac. Key names in Options come from `HectorInput.ShellKeyCharacters` (US layout) — the Mac asks the
   live layout (`FerazelController.swift:303–322`) ◇.
7. **Gamepad** (D37): `SDLHost.padState()` → `ShellPadTranslator` with `FerazelPadLayout.mapping(keys:context:dialogUp:)`
   each poll, merged into the held keys and the Caps Lock latch exactly as HectorShell's `ShellView.pollKeyState` does
   for the Mac (BTX: `WinGameDriver.swift:146–148`); with a confirm/report up, pad Return/Esc answer it (the Mac's
   `padKeyPanel` rule, `FerazelController.swift:722–739`).
8. **Clock:** ticks = `SDLClock.nanoseconds` × 60 / 10⁹ (absolute, `UInt32` wrap like `ShellClock.ticks()`); the loop
   wakes every 1/240 s (`SDLClock.sleepPrecise`) and runs the flow at most once per new tick, never while a dialog or a
   file dialog is up — the Mac's `idleFired` (`:325–355`). The 30-step cap and 2-tick cadence stay Core's (Q9: keep the
   speed); the shell adds no cap of its own.
9. **Quit:** the window's close button, Alt+F4 and the taskbar's Close arrive as SDL's quit event = the Mac's Dock Quit
   (D40): `GameFlow.systemQuit()` — a level running free asks "Are you sure you want to quit?", elsewhere the queued
   quit event as the original. Windows ending the session kills the process; `.Quit` writes no prefs, so nothing is lost
   (the D40 logout case). The flow's `.quit` request ends the loop, stops audio, exits 0.
10. **Prefs and saves:** `%APPDATA%\Ambrosia Classics\Ferazel's Wand\` holds the prefs file (`PrefsFile.fileName`, the
    same 0x942-byte record the Mac writes) and is the saves dialogs' start folder; never `UserDefaults` (D16.3). The Mac
    SDL development build uses `~/Library/Application Support/Ambrosia Classics/Ferazel's Wand (SDL)/` (never the Mac
    app's folder; BTX `WinPrefsFile.swift:24` shape); `--prefs FILE` / `--saves DIR` override. A default save name is
    made Windows-legal: each of `\ / : * ? " < > |` and control characters → `-`, trailing dots/spaces dropped, a
    reserved device name (CON, PRN, AUX, NUL, COM1–9, LPT1–9) gets `_` appended; no extension is added (the Mac's files
    have none; Core refuses a non-save with the original's text) — WQ6.
11. **Hidden switches:** `-FerazelLevel N`, `-ColorTieBreak lowest`, `-MacGamma YES` on the command line, for one
    launch, parsed with the Mac's `UserDefaults` argument-domain semantics (`FerazelController.swift:174–185`: integer,
    exact `"lowest"`, bool) by one shared `FerazelSettings.parse(lookup:)`. No persistent store on Windows.
12. **Data:** `Data\` beside the exe = `Resources/Ferazel/` unchanged (six `.rsrc` + `Ferazel's Wand Music\`, D10, design
    l. 119) + `Fonts\*.fzfont`; `--data DIR` overrides; the start-up check names any missing file in a message box and
    the log (BTX `WinStartup.swift:17`). No `Decoded\` (no codec pictures).
13. **Audio:** music on a `PCMMixer(voices: 1, outputRate: 48000)` through one `SDLAudioOut`; the Sound Tool (a
    `PCMPullSource` at 22,050 Hz, `SoundTool.swift:42,52`) through a second `SDLAudioOut` — SDL3 mixes the two logical
    streams on the default device (`shim.h:162–168` opens one per call), as the Mac's `ShellMixer.attachStream` puts it
    beside the voice. Cue order, the music track rule and volumes are the shared `FerazelAudio`. **Mute switch** (Ben's
    amended Q12): `--mute`, and `HECTOR_SDL_AUDIO_DRIVER=dummy` (CrossOver strips `SDL_*`), open no audio device.
14. **Window:** the 640×480 game screen alone (D21), title "Ferazel's Wand", opening at the largest whole scale k ≤ 3
    whose window fits the usable area (the Mac rule, `:193–205`), HectorSDL's resizable integer-fit window on black
    (◇ the Mac's is fixed; HectorSDL always opens resizable, `SDLHost.swift:43`). Full screen = **Alt+Enter** (the Mac's
    ⌃⌘F would be Win+Ctrl+F, a Windows system key, and Ctrl+F is ⌘F = Sound Effects) — eaten by the shell. Cursor
    hide/show honoured only over the canvas, focused, no modal up (`:624–637`). `.hideMenuBar`/`.showMenuBar` ignored.
15. **D42 holds:** Proof B, a muted CrossOver run of the game and the first boot are **scripts Ben runs**, listed with
    their expected output on the gate card; the loop's Windows gates are GW1–GW5 (build, macOS-hosted tests, stage).
16. **Lockstep (D41) — the standing contract for Phase 5 onward** (copied into every later plan's preamble):
    (a) a task that changes what the Mac app shows or does — `Ferazel/App`, `Ferazel/Shared`, a new `ShellRequest` /
    `FerazelDialog` case, a new text face, a new data file — carries its Windows side in the same task (FerazelWinKit /
    FerazelWin change + GW2 tests + GW3), and its Files list names both; (b) a Core-only task needs only GW1 (and GW3 when
    it adds a seam case the shells switch over — the run-25 lesson); (c) a change to `Ferazel/Shared` is reviewed for
    both shells; (d) a text-path change re-runs `fz-bake-font` and commits the `.fzfont` files (the staleness test fails
    otherwise); (e) every phase end stages both builds (`tools/stage-ferazel.sh` + `tools/windows/stage-ferazel-win.sh`)
    with ONE gate card that has a Mac part and a Windows part, and the Fable phase review covers both diffs.
17. **No HectorKit change.** Everything new is Classics-side; G1 stays 35a85ba, floor 361. (A later wish — a fixed-size
    window, layout-aware key names via SDL — would be an HK task under NEXT AUTHORIZATIONS.)
18. **Foundation-on-Windows traps (D19.5, D16):** Windows-run code never calls `replacingOccurrences` (pure-Swift
    replace, BTX `TextReplace.swift` shape), never `.macOSRoman`, never `UserDefaults`.
19. **Build-root isolation:** every Ferazel cross-build passes `WIN_BUILD_ROOT=$WIN_CROSS/build/ferazel` (scripts set it
    themselves) — `build.sh:47` would otherwise share `build/Core` / `build/Windows` with BTX's packages.

## Tasks

Every brief tells the implementer: work in the run's worktree; read the cited lines first; the Mac app's behaviour must
not change (G2 490/0 and G5 on every task that touches it); never run a built executable, never CrossOver (D42).

### WF0 — Core cross-compiles with its tests; Proof B script (Ben's)

- **Goal:** de-risk the toolchain first: GW1 green, and Proof B ready for Ben with the known Windows differences fixed.
- **Files:** `Ferazel/Core/Tests/FerazelCoreTests/FerazelDataTests.swift:36–44`; `Ferazel/Core/Tests/FerazelRenderTests/CensusTests.swift:18–23`;
  `Ferazel/Core/Sources/FerazelRender/Census/FerazelCensus.swift:63,560–561`; new `tools/windows/proof-b-ferazel.sh`;
  `tools/windows/README.md` (a "Ferazel's Wand" section).
- **Contracts:** (1) the environment override in `FerazelDataTests` uses a test helper that sets/unsets the variable so
  `ProcessInfo.processInfo.environment` sees it on both platforms (`setenv`/`unsetenv` on Darwin; on Windows the CRT's
  `_wputenv_s`, which also updates the Win32 block) — Mac behaviour identical; (2) on Windows that test links the data
  files with hard links (`FileManager.linkItem`), falling back to copies, instead of symbolic links — same assertions;
  (3) `censusBinary()` appends `.exe` on Windows; (4) the census's three replaces go through a pure-Swift replace — the
  Mac census stdout byte-identical (G3 + `CensusTests` unchanged); (5) `proof-b-ferazel.sh` = `proof-b.sh`'s shape for
  Ferazel: copies `Ferazel/Core` + `docs/ferazel/data-census.md` under `$WIN_CROSS/work/proof-b-ferazel/` laid out like
  the repo, symlinks HectorKit at `work/HectorKit` (shared with BTX's script — same target), builds with
  `WIN_BUILD_ROOT=$work/build`, exports `FERAZEL_DATA` as a `Z:\…` path to `Resources/Ferazel`,
  `HECTOR_SDL_AUDIO_DRIVER=dummy HECTOR_SDL_VIDEO_DRIVER=dummy`, runs per class through `run-in-crossover.sh`, prints the
  `passed / failed / skipped / crashed (of N)` line. Never touches the repo's copy. **The implementer writes it and
  checks it with `zsh -n` only — it is never run by the loop.**
- **Tests:** none added; G2 **490/0** (Mac) proves the edits kept every test.
- **Acceptance:** GW1 → `0` then `2`; G2 490/0; G3 1,108/0; G6 = the Files; G10. README states Proof B's expected line
  `490 passed / 0 failed / 0 skipped / 0 crashed (of 490)`.

### WF1 ⚑ MAJOR — The shared shell half; the FerazelWindows package

- **Goal:** one neutral driver both shells call; the Windows package exists and tests it on the Mac.
- **Files:** new `Ferazel/Shared/FerazelDriver.swift`, `Ferazel/Shared/FerazelAudio.swift` (moved from
  `Ferazel/App/FerazelAudio.swift`, git mv), `Ferazel/App/FerazelController.swift` (the moved parts become calls),
  `Ferazel/App/` one small file for `extension ShellMixer: FerazelMixer` (or inside the controller), `project.yml`
  (Ferazel target: `- path: Ferazel/Shared`; add the HectorAudio product only if the compiler asks), new
  `Ferazel/Windows/Package.swift` (BTX `Package.swift` shape: `../Core` products FerazelCore + FerazelRender,
  `../../../HectorKit` products HectorResources/HectorGraphics/HectorAudio/HectorInput — the same path identity Core
  uses; the SDL dependency arrives in WF3), symlinks `Ferazel/Windows/Sources/FerazelWinKit/{FerazelDriver,FerazelAudio}.swift`,
  `Ferazel/Windows/Tests/FerazelWinKitTests/*`.
- **Contracts:** `FerazelDriver` (`@MainActor final class`, Foundation + FerazelCore/Render only) takes over, with the
  same order and results: the boot in `applicationDidFinishLaunching` (`:98–171` minus the window/menus/dialogs/timer —
  resources open, `ColorSearch(.exactNearest, tieBreak)`, surface under clut 0x321, the two `ScreenRenderer`s, the map
  renderer, `TextLayout.conversationText`, prefs load-or-store-defaults, the clock seed, `GameFlow`, `startLevel`,
  `keyCharacter` / `dateTime` hooks injected by the shell); one tick (`:325–355`: flow tick, `configureLevelRun`
  `:396–403`, `draw(segments)` `:405–438` with `isConversationOp` `:440–447`, the audio apply, prefs to the renderers,
  `serviceLoad`/`loadSounds`/`loadFaces` `:451–495`) returning `present` and the requests for the shell to honour;
  `present` (`:497–511`) as both the Mac's ARGB words and the RGBA bytes `SDLHost.present(rgba:)` takes, MacGamma
  applied to the palette; `dialogPicture` (`:279–301`) as RGBA bytes + size (the Mac wraps them in a `CGImage`);
  `LevelServices` (`:760–782`); `keyMapCode` (`:384–392`); `FerazelSettings.parse(lookup:)` for the three hidden keys
  (`:174–185`; the Mac's lookup reads `UserDefaults.standard`). `FerazelAudio` unchanged in logic over
  `protocol FerazelMixer { load, play, stop(voice:), stopAll, setVolume, attach(stream: SoundTool) }`; its `NSLog`
  becomes an injected log closure. The App keeps only AppKit/HectorShell work. A failure the Mac turned into
  `fail(…)` stays the shell's.
- **Tests (+14, FerazelWinKitTests, real data via `FerazelData.dataDirectory()`, a fake mixer and a fixed clock):**
  settings parse table (absent, "2", "9", "0", "lowest", "LOWEST", "YES", "1", "true", "NO"); boot to the main menu in
  a fixed tick count and the presented RGBA FNV there (self-measured, recorded in the commit body and D43);
  MacGamma on = LUT through the palette; New Game (held N) reaches level 1's popup and its first presented frame FNV;
  `isConversationOp` table; `keyMapCode` table; audio apply order (stops before play i; `onlyIfIdle`; trailing stops);
  `resolveTrack` (−1, 0, 33, 21 → 20, 27 → 26, none → nil); music cue sequence on the fake mixer; `loadSounds` with
  F1 (`only` = the four ids); `loadFaces` progress count 25; `prepare`/`attach` through the driver; `dialogPicture`
  under the current clut; the symlink-coverage test (every `Ferazel/Shared/*.swift` has its FerazelWinKit symlink).
- **Acceptance:** G2 490/0; G5 SUCCEEDED; GW2 **14/0**; G7 + G7W empty; GW-symlinks empty; G6; G10. Both review legs
  read the `FerazelController` diff as a move (nothing re-ordered); one leg builds the app and diffs the App's symbol
  list for anything lost.

### WF2 — Baked text (Ruling 2)

- **Files:** `git mv Ferazel/App/CoreTextRasterizer.swift Ferazel/Shared/` + whole-file `#if canImport(CoreText)`;
  its FerazelWinKit symlink; new `Ferazel/Windows/Sources/FerazelWinKit/{FZFont,BakedTextRasterizer}.swift`,
  `Ferazel/Windows/Sources/fz-bake-font/main.swift` (Mac-only body under `#if canImport(CoreText)`, BTX
  `btx-bake-font` shape), `Ferazel/Windows/Resources/Fonts/*.fzfont` (committed), `Package.swift` (the baker product),
  tests.
- **Contracts:** `.fzfont` = documented little-endian binary (`FZF1`, version, family/size/face, ascent/descent/leading,
  256 entries of left/top/width/height/advance + coverage, then the string cache: count, each MacRoman bytes + mask).
  The baker resolves fonts only through `CoreTextRasterizer` (no second CoreText path). `BakedTextRasterizer:
  TextRasterizer` (`TextRasterizer.swift:11–34`): `rasterize` = cache hit, else glyphs composed at whole-pixel
  `charWidth` advances; `charWidth`/`fontInfo` from the table; an unbaked face → empty mask + one log line. The level
  names come from where `StatusBarState.levelName` is filled (the implementer finds and cites it).
- **Tests (+10; the CoreText oracle ones are Mac-only by `#if canImport(CoreText)`):** every face × every byte equal
  (mask, offsets, `charWidth`), `fontInfo` equal; every cached string equal; score/coin strings 0…99,999 sampled (1,000
  seeded + edges) composed vs CoreText — exact, or the measured bar recorded; staleness (fresh bake == committed bytes);
  format round trip; unbaked face; the face set the game asks for (a recording rasterizer driven through the status bar
  and the conversation layout) ⊆ baked; level-1 golden route frame indices baked = CoreText (FNV); the sign-frame route
  (`c8e41941c1e4d6da`'s scenario) baked = CoreText.
- **Acceptance:** GW2 **24/0**; G2 490/0; G5 (the App lost a file to Shared); GW1; G7W; G6; G10.

### WF3 ⚑ MAJOR — FerazelWin: the game on HectorSDL

- **Files:** `Ferazel/Windows/Package.swift` (+ `../../../HectorKit/SDL`, executable `FerazelWin`); new
  `Sources/FerazelWin/main.swift` (SDL glue only, BTX `BubbleTroubleXWin/main.swift` shape);
  `Sources/FerazelWinKit/{WinGame,WinInput,WinShortcuts,WinFiles,WinArgs,WinStartup,WinKeyScript,WinDialogs,WinFilePanels}.swift`
  (`WinKeyScript` adapted from BTX `WinInput.swift:74–170`; `WinDialogs` / `WinFilePanels` are protocols with stub
  answers here); new `Ferazel/Shared/FerazelMenuRules.swift` + symlink; `Ferazel/App/FerazelMenus.swift:44–46,114–152`
  (calls the shared rules; behaviour identical).
- **Contracts:** Rulings 5–14 as written: the loop and ticks (8); `FrontInput` from SDL events — held Mac key codes
  through `keyMapCode`, Caps Lock from the poll's modifier state, mouse in canvas pixels via `SDLLayout.logicalPoint`
  (nil off the canvas), button, active = focus, `playing` from the audio (`:357–382`); the pad (7); the requests
  (`:513–531`: cursor, menu-bar ignored, `showMenuBarItems` → shortcut state, dialog → `WinDialogs`, put/get file →
  `WinFilePanels`, quit); shortcuts (5), Alt+Enter (14); quit (9); files + args (10–12); audio + mute (13); start-up:
  missing data → message box (never in `--frames` mode) + `Ferazel's Wand.log` beside the prefs, exit 1; window (14).
  Headless mode for Ben's scripts and the tests: `--frames N` (N loop iterations of exactly 1/240 s each), `--dump
  f.ppm` (the last presented 640×480), `--keys FILE` (BTX script syntax), in-memory prefs unless `--prefs`, dummy SDL
  drivers forced in-process, no pad. Stubs: every dialog answers its default (Cancel / OK for reports / prefs
  unchanged / credits closed); file panels answer cancelled.
- **Tests (+16, scripted host, no SDL):** the main-menu RGBA FNV equals WF1's (the loop adds nothing); 240 Hz
  iterations → one flow step per new 60 Hz tick; right-hand modifiers folded; shortcut table over `MenuState`
  (main-menu letters fall through, paused enables Abort, modal blocks all); a taken shortcut not in the held keys;
  Alt+Enter eaten; Caps Lock latch; pad merge (D37 sample: south = jump in a level, + toggles Caps Lock, − held 1 s =
  Esc); quit event → `systemQuit` (a level running free shows the confirm request next tick); cursor rule; `WinFiles`
  folder from `APPDATA` (set / unset → error message); args (hidden keys, `--data`, `--prefs`, `--mute`, a trailing
  path); start-up missing list; `FerazelMenuRules` table = the Mac's old rules; key script parse; New Game via script
  reaches level 1 with the same FNV as WF1's test.
- **Acceptance:** GW2 **40/0**; GW3 `0` / `1`; GW4; G5 (FerazelMenus); G2 490/0; GW1; G7/G7W; G6; G10.

### WF5 — Saved games on Windows (Ruling 3, 10)

- **Files:** `Sources/FerazelWin/WinFileDialogs.swift` (`#if os(Windows)`: `GetSaveFileNameW` / `GetOpenFileNameW`,
  `OFN_EXPLORER | OFN_OVERWRITEPROMPT | OFN_PATHMUSTEXIST | OFN_FILEMUSTEXIST (open) | OFN_NOCHANGEDIR`, owner
  `GetActiveWindow()`; Mac SDL build: `--save-as FILE` / `--open FILE` answers, else cancelled);
  `Sources/FerazelWinKit/{WinFileRequests,WinFilePanels}.swift`; `WinGame.swift` (open-document at launch); tests.
- **Contracts:** `WinFileRequests` builds the request from `PutFileRequest` (`ShellRequest.swift:34–44`) / the get
  prompt: title, start folder (created), Windows-legal default name (Ruling 10), "All files (*.*)" filter; the answer
  → `GameFlow.fileDone(.chosen(SavedGameRef(url:displayName:)))` or `.cancelled` (`:570–608`); input state captured
  before the dialog is flushed after it (no stuck keys). A save-game path given on the command line (Explorer "Open
  with" / a file dropped on the exe) → `GameFlow.openDocument` once the flow exists — the Mac's Finder open (`:678–686`).
- **Tests (+8):** name sanitising table (each illegal char, trailing dot/space, CON, `com3`, empty → the flow's default
  unchanged when legal); request fields from a `PutFileRequest`; start folder created; answer mapping (chosen /
  cancelled); stuck-key flush; a launch path opens the document at the menu pass; a round trip through `WinFiles` with
  the real codecs (save block written, read back equal).
- **Acceptance:** GW2 **48/0**; GW3; GW4; GW1; G2 490/0; G6; G10.

### WF4a — In-window dialogs I: DLOG 202 and 200 (Ruling 4)

- **Files:** `Sources/FerazelWinKit/{DialogRenderer,DialogWindow,DialogSystem}.swift` (adapted from BTXWinKit's three
  files), `WinDialogs.swift` (real implementation for `.confirm` / `.report` / `.error`), the dialog face added to the
  baker (Ruling 2: the Mac's `ClassicFont` rule, `DialogViews.swift:9–20` — Charcoal 12, else Chicago 12, else bold
  system 12, resolved through CoreText), its `.fzfont`, tests, `Tests/Goldens/Dialog-202.ppm`, `Dialog-200.ppm`.
- **Contracts:** layout from the original DLOG/DITL via Core's R1 template parsers (as `FerazelCarbonDialog` builds
  them), centred over the canvas; `^0`/`^1` params (`.error` puts `NumToString(code)` in `^1`); OK ring (InsetRect −4,
  pen 3, oval 15); Return/Enter → item 1, Esc → Cancel on 202; clicks outside the dialog do nothing but beep
  (`MessageBeep` on Windows, silent on the Mac SDL build); pad Return/Esc reach it (Ruling 7); answers →
  `GameFlow.dialogDone` (`:533–557`); the flow does not tick while one is up.
- **Tests (+10):** layout rects from DITL 202/200; params; keyboard answers; mouse track (press-drag-out-release =
  nothing); pad answers; outside click; the flow holds still; goldens 202 and 200 (self-derived, shown to Ben on the
  card); dialog-face widths within 1 px of the Mac's `NSFont` measure (Mac-only oracle).
- **Acceptance:** GW2 **58/0**; GW3; GW4; GW1; G2; G6; G10.

### WF4b ⚑ MAJOR — In-window dialogs II: Options (6900) and Credits (600)

- **Files:** `Sources/FerazelWinKit/{WinPrefsDialog,WinCreditsDialog}.swift`, `DialogWindow.swift` (popup, checkbox,
  key-capture items), tests, `Tests/Goldens/Dialog-6900.ppm`.
- **Contracts:** behaviour per `Ferazel/App/Dialogs/PrefsDialogView.swift` over `GameFlow.prefsDialog` (the O1 model:
  every control, key capture with the original's refusals — the A key "already used", the Music checkbox and popup
  acting at once through `MusicCue`s), OK/Cancel → `dialogDone`; Credits per `CreditsDialog.swift` over
  `GameFlow.credits` (`CreditsScroll` timing, PICT under the current clut via `FerazelDriver.dialogPicture`, a click
  closes). Options and Credits take no pad keys (D37).
- **Tests (+12):** every Options control's model effect; key capture accept / refuse ("already used"); music cues act
  at once; Cancel restores; OK returns `.ok`; credits scroll position at fixed ticks; credits close on click; golden
  6900; the ⌘P path from a level opens it (scripted).
- **Acceptance:** GW2 **70/0**; GW3; GW4; GW1; G2; G6; G10.

### WF6 — Stage both builds; the Windows gate card (phase-end run)

- **Files:** new `tools/windows/stage-ferazel-win.sh` (adapted from `stage-btx.sh`: committed-content check and stamp,
  release cross-build with `WIN_BUILD_ROOT` (Ruling 19), `/SUBSYSTEM:WINDOWS /ENTRY:mainCRTStartup`, `windres`
  manifest + icon (from `Ferazel/App/AppIcon.icon`'s art) + version info, the PE import walk for DLLs, `Data\` =
  `Resources/Ferazel` + `Fonts`, `WHAT-TO-EXPECT.txt` with BOM + CRLF, writes `MANIFEST.txt` (the zip's file list),
  `out/Windows/Ferazel's Wand/` + `out/Windows/Ferazel's Wand (Windows).zip`, files at the zip root, Desktop copies
  unless `--no-desktop`); new `tools/windows/smoke-ferazel-win.sh` (Ben's: muted CrossOver run of the staged exe in a
  clean bottle, `--frames 600 --dump` and `--frames 1500 --keys` New Game, each `cmp` against the Mac SDL build's
  dump — written, `zsh -n` checked, **never run by the loop**); new `Ferazel/WINDOWS-WHAT-TO-EXPECT.md` (the card
  below); `tools/windows/README.md`; `Ferazel/WHAT-TO-EXPECT.md` (one "Windows" pointer line).
- **Contract:** stage both builds: `bash tools/stage-ferazel.sh` (Mac; staging only, no G9) and the Windows script;
  the Fable phase review over `git diff f7fd4ce..HEAD` + the card; fixes; re-stage; QUESTIONS gate card item.
- **Acceptance:** GW5 (exit 0; `Subsystem … 2`/`Windows GUI`; manifest diff empty); GW1–GW4; G1, G2 490/0, G3, G5,
  G7/G7W, G10. LOOP-LOG: "Windows staged; not launched by the loop (D42); Ben's first launch is the boot check".

## Stand-ins kept (◇, named) at the phase's end

| ◇ | What Windows lacks | Why / who replaces it |
|---|---|---|
| ◇W1 | Options' key names from the US layout (`ShellKeyCharacters`), not the live Windows layout | HectorSDL exposes no layout query; an HK task if Ben wants it (WQ5) |
| ◇W2 | The window is resizable (integer-fit on black); the Mac's is fixed | HectorSDL always opens resizable (WQ4) |
| ◇W3 | Native Windows file dialogs where the original had Standard File | Ruling 3 (WQ2) |
| ◇W4 | No About item (Credits is on the main menu); no check marks | D21 |
| ◇W5 | Nothing ever ran on Windows or in CrossOver by the loop: Proof B, the smoke and the first boot are Ben's | D42 |
| ◇W6 | Every Mac stand-in of Phase 4 (enemies still, levels 5+ refused, underwater tint, shield crouch face — Phase 5/6) | the Phase 4 card's table; lockstep carries them |
| ◇W7 | No installer, no signing, no file association; SmartScreen "Run anyway" | D19.6, D20/D34 (publishing is Ben's) |
| ◇W8 | Score/coin text composed glyph by glyph, unless WF2 measured it exact | Ruling 2 |

## The Windows gate card — Ben and Andrew (WF6 writes it as `Ferazel/WINDOWS-WHAT-TO-EXPECT.md` + a QUESTIONS item)

**Not launched by the loop (D42); Ben's first launch is the boot check.** Ben, on this Mac (optional, daytime, muted):
1. `tools/windows/proof-b-ferazel.sh` → last line `proof-b: 490 passed / 0 failed / 0 skipped / 0 crashed (of 490)`.
2. `tools/windows/smoke-ferazel-win.sh` → `main menu: identical`, `new game: identical`, exit 0 (muted by
   `HECTOR_SDL_AUDIO_DRIVER=dummy`).
On a Windows 10/11 PC (or CrossOver), from the unzipped `Ferazel's Wand (Windows)` folder:
3. First launch (SmartScreen: More info → Run anyway): logo, title music, main menu — no console window, no error box.
4. Keyboard: keypad 4/6/8/5 move with Num Lock on **and** off; Shift / Alt / Ctrl act as Shift / Option / ⌘; Caps Lock
   pauses; Esc asks to abort; Ctrl+P opens Options (drawn inside the window); Alt+Enter full screen and back.
5. New Game → level 1 plays as on the Mac: music, effects, the status bar text, a sign's text smoothed like the Mac's.
6. A save point: the Windows Save dialog opens in `%APPDATA%\Ambrosia Classics\Ferazel's Wand\` with the game's name;
   Restore Game (Ctrl+O at the menu, or Continue) opens it again and the level resumes.
7. Options: remap a key, toggle music (acts at once), OK; quit and relaunch — the prefs held.
8. A controller (Xbox / Switch Pro / PlayStation): the Mac's layout (D37), + pauses, − held 1 s = Esc.
9. Close button during play → "Are you sure you want to quit?" (Cancel plays on); at the main menu it quits.
10. `"Ferazel's Wand.exe" -FerazelLevel 3` from a command prompt → New Game starts at level 3.
Pass looks like: the Mac build's behaviour on Windows, sound by ear, dialogs by eye. Notes become a named wave.

## Questions for Ben (non-blocking; the seat copies them to QUESTIONS; execution does not wait — D34)

- **WQ1 — may the loop run headless Windows test executables in CrossOver (Proof B) by day, muted?** Your amended Q12
  on `main` (0e45326, f7fd4ce: muted launches by day, never 21:00–09:00) came after D42 was written; this plan follows
  D42 as recorded. Options: (a) no — Ben runs the scripts; (b) Proof B only (no window, no sound); (c) Proof B and the
  muted smoke. **Default (a).** Blocks: nothing.
- **WQ2 — saved-game files on Windows:** (a) the native Windows Open/Save dialogs (as the Mac uses its own);
  (b) the original's Standard File drawn inside the window; (c) a fixed saves folder with an in-window list.
  **Default (a).** Blocks: nothing.
- **WQ3 — full-screen key:** (a) Alt+Enter; (b) F11; (c) both. **Default (a).** Blocks: nothing.
- **WQ4 — window:** (a) resizable, whole-number scaling on black (HectorSDL today); (b) fixed like the Mac (a small
  HectorKit change). **Default (a).** Blocks: nothing.
- **WQ5 — key names in Options:** (a) US-layout names; (b) the PC's own layout (HectorKit change). **Default (a).**
  Blocks: nothing.
- **WQ6 — saved-game file names:** (a) no extension, as the Mac; (b) add `.fwsg` so Explorer can tell them apart.
  **Default (a).** Blocks: nothing.

## Execution order (one loop run each; the cap rule: 2 tasks, 3 when at most one is ⚑)

| run | unit | why this order |
|---|---|---|
| 32 | **WF0, WF1 ⚑, WF2** | toolchain first; the shared half before anything uses it; text needs only WF1 |
| 33 | **WF3 ⚑, WF5** | the game, then its file dialogs (WF5 needs WF3's executable) |
| 34 | **WF4a, WF4b ⚑** | the dialog foundation, then the two rich dialogs |
| 35 | **WF6** phase end | stage both, Fable phase review, card → QUESTIONS; then the Phase 5 plan (lockstep from its first task) |

## Orchestration notes

- **Toolchain:** installed at `~/Developer/Toolchains/windows-cross/` (Swift 6.4.0, SDL3 3.4.16, winsysroot, runtime
  DLLs); brew `sdl3` is on the Mac for GW4; `x86_64-w64-mingw32-windres` (brew `mingw-w64`, needed by the stage
  script as by `stage-btx.sh:96–97`) is at `/opt/homebrew/bin` (checked 2026-10-26). **No installs** (NEXT
  AUTHORIZATIONS): if a tool has gone missing, stage with `--no-icon` where possible and record it in QUESTIONS.
- **Build roots:** always `WIN_BUILD_ROOT=…/build/ferazel` (seat, implementers) and a `mktemp` root for reviewers; a
  cold GW1 is ~5–10 min, GW3 similar — run gates in a background Bash while a foreground reviewer reads.
- **HectorKit path:** `Ferazel/Windows/Package.swift` reaches HectorKit at `../../../HectorKit` (in a worktree:
  `.claude/worktrees/HectorKit` → `~/Developer/HectorKit`); never create a self-link (runs 28/29 lesson). HK must stay
  35a85ba (G1).
- **Symlinks:** create with `ln -s ../../../Shared/X.swift` inside `FerazelWinKit/` and `git add` them; check mode
  120000 (GW-symlinks). They break in a Git-for-Windows checkout with `core.symlinks=false` — the README says so (BTX
  precedent); every build here is on the Mac.
- **Never run what you build:** not `FerazelWin`, not the test `.exe`, not `swift run`, not `run-in-crossover.sh`, not
  the Proof B or smoke scripts (D42). `swift test` of FerazelWinKit is allowed: its tests use a scripted host and a fake
  mixer, open no window and no audio device — a test that would touch SDL or audio is a review failure.
- **Mac app safety:** WF1, WF2, WF3 touch `Ferazel/App` / `project.yml`; G5 every time; Ben may be playing the staged
  Phase 4 build — the staged `~/Desktop` app is replaced only in WF6.
- **Reviews:** two Opus legs on WF1, WF3, WF4b; one on the others; the phase-end Fable leg in run 35 (D34). The plan
  itself: two Opus legs (one against BTX's Windows code + `tools/windows/`, one against Ferazel's App + design +
  rulings), then one FABLE-GRADE leg, before run 32 (NEXT.md).
- **Carries into Phase 5:** Ruling 16 verbatim in its preamble; its Files lists name the Windows side.
