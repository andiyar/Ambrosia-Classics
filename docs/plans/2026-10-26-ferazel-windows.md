# Ferazel's Wand on Windows — Phase W plan (contracts, not code)

> **For agentic workers:** use `superpowers:subagent-driven-development`. One Opus `fk-implementer` + one Opus
> `fk-reviewer` per task (two review legs on ⚑ MAJOR). Contracts, not code (Ben's rule, memory
> `feedback-plans-carry-contracts-not-code`): each task names the files, the behaviour, the tests and the acceptance
> numbers; the implementer writes the code test-first. **Launches (D42, Ben's Q12 as amended): only muted, never
> 21:00–09:00.** Every step that runs a build — Proof B in CrossOver, the staged zip's boot in a clean CrossOver bottle,
> the Mac staged app's G9, the Mac SDL development build run with dummy drivers — is a loop gate, but each one (i) uses
> the mute switch, (ii) is preceded by `date +%H` in 09..20 — otherwise the step is skipped and the run writes "boot
> check owed (night rule)" in LOOP-LOG and on the gate card, and (iii) is few and short. No mute switch → no launch.
> The switches: the Mac app's `-FerazelMute YES` (built and headlessly tested in WF1; no Mac app launch before it
> merges); in CrossOver the no-sound driver through `HECTOR_SDL_AUDIO_DRIVER=dummy` (exists today in HectorSDL and
> `run-in-crossover.sh`; Proof B's script forces it) plus the game's own `--mute` (WF3).

**Goal:** a Windows build of Ferazel's Wand that does what the Mac app does today (Phase 4 as built: levels 1–4, front
end, saves, map, spells, items, controller) — cross-compiled on this Mac, staged as a zip under `out/` (never
published), checked muted by day by the loop (Proof B, the staged boot), with the checks only a person can make (sound,
feel, a real PC) on the gate card for Ben and Andrew.

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
finds `ferazel-census` beside the `.xctest` bundle (`:19`) and without `.exe` — on Windows the test runner is a renamed
`.exe`, not a bundle; `CensusTests.swift:132–133` compares the child's stdout byte for byte with the in-process render
(Windows text-mode stdout may write CRLF); `FerazelDataTests.swift:36` makes symbolic links (Windows needs a privilege;
Wine varies); `FerazelCensus.swift:63,560–561` make **five** `replacingOccurrences` calls, which trap in
Foundation-on-Windows on non-ASCII strings past ~64 bytes (D19.5). Review leg A (2026-10-26) re-measured GW1: **~19 s**,
exit 1 on the `setenv`/`unsetenv` lines; with a `_putenv_s` shim exit 0 and both `.exe` lines.

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
| WF0 | 490 (2 test files + census source edited, no test added) | — |
| WF1 ⚑ | 490 | **17** |
| WF2 | 490 | **27** (+10) |
| WF3 ⚑ | 490 | **46** (+19) |
| WF5 | 490 | **54** (+8) |
| WF4a | 490 | **65** (+11) |
| WF4b ⚑ | 490 | **77** (+12) |
| WF6 | 490 | 77 |

**Proof B (GWB, a muted daytime loop gate from WF0's run on; also on the gate card for Ben/Andrew):** the Core suite
cross-built and run in CrossOver with the no-sound driver — **490 passed / 0 failed / 0 skipped / 0 crashed (of 490)**.
No skip rule is planned: data tests get the data through `FERAZEL_DATA` (Windows path), `CensusTests` finds
`docs/ferazel/data-census.md` through the copy's repo layout, WF0 removes the known Windows differences (environment,
symbolic links, the census binary's location and name, CRLF, the five replaces). The suite runs **once, whole**; per
class only after a crash, to find it. Any miss becomes a WF0-style parity task with a ruling, as BTX's 260-of-261 was
(D18.1) — or, if the implementer cannot remove a difference, WF0 names a skip rule with its exact count and the
expected line changes to it. A count other than 490 in the `--list-tests` line is itself a finding.

## Gates (copy literally; `$WT` = the run's worktree)

Mac gates kept from `docs/NEXT.md` GATES: **G1** HK untouched (`git -C ~/Developer/HectorKit status --porcelain` empty;
`log --oneline -1` = 35a85ba), **G2** Core 490/0, **G3** census `Totals: items 1,108 decoded, failures 0` (WF0 — it edits
the census — and every wave end), **G5** Ferazel app `** BUILD SUCCEEDED **` (every task touching `Ferazel/App`,
`Ferazel/Shared` or `project.yml`, and every wave end), **G6** scope fence ⊆ the task's Files, **G7** layering, **G10**
clean tree, and **G9M** — G9 with the mute switch (WF6 only, below). GW1–GW5, GW-symlinks and G-MUTE are build-only
and run at any hour; the **launch gates** (GWB, GW6, G9M, GW4R) run only by day and muted (D42), each behind the same guard:

```sh
# LAUNCH GUARD — before every launch gate; outside 09..20 skip the gate and write "boot check owed (night rule)"
h=$(date +%H); (( 10#$h >= 9 && 10#$h <= 20 )) && echo "launch ok ($h)" || echo "boot check owed (night rule) ($h)"
```

```sh
WT=$PWD; SCRATCH=$(mktemp -d)
WINB=$HOME/Developer/Toolchains/windows-cross/build/ferazel   # NEVER the default root: build.sh:47 names the scratch dir
                                                              # after the package folder, and BTX's packages are also
                                                              # called Core and Windows (Ruling 19)
# GW1 Core + its tests cross-build for Windows (build only; GWB is what runs them): exit 0, then 2
WIN_BUILD_ROOT="$WINB" "$WT/tools/windows/build.sh" "$WT/Ferazel/Core" all --tests > "$SCRATCH/gw1.log" 2>&1; echo $?
grep -cE '/(FerazelCorePackageTests|ferazel-census)\.exe$' "$SCRATCH/gw1.log"
# GW2 the Windows package's macOS-hosted tests: first number = the ladder's, second = 0
cd "$WT/Ferazel/Windows" && swift test > "$SCRATCH/fw.log" 2>&1; grep -cE "^Test Case '.*' (passed|failed|skipped) \(" "$SCRATCH/fw.log"; grep -cE "^Test Case '.*' (failed|skipped) \(" "$SCRATCH/fw.log"
# GW3 (from WF3) the game cross-builds and links for Windows (build only): exit 0, then 1
WIN_BUILD_ROOT="$WINB" "$WT/tools/windows/build.sh" "$WT/Ferazel/Windows" FerazelWin --sdl > "$SCRATCH/gw3.log" 2>&1; echo $?
grep -cE '/FerazelWin\.exe$' "$SCRATCH/gw3.log"
# GW4 (from WF3) the Mac SDL development build compiles: last line "Build complete!" (or "Compiling …" free of errors)
cd "$WT/Ferazel/Windows" && swift build --product FerazelWin 2>&1 | tail -n 1
# G7W layering for the new code: empty (CoreTextRasterizer is the one guarded Mac-only file)
grep -rlE '^import (AppKit|Carbon|CoreGraphics|CoreText|AVFoundation|Metal|QuartzCore|SwiftUI|UIKit|HectorShell|HectorSDL|CSDL3)' \
  "$WT/Ferazel/Shared" "$WT/Ferazel/Windows/Sources/FerazelWinKit" | grep -v '/CoreTextRasterizer\.swift$'
# GW-symlinks (zsh: ${f:t} is zsh's basename): every Ferazel/Shared file has its FerazelWinKit symlink, mode 120000 (empty output)
zsh -c 'for f in "$1"/Ferazel/Shared/*.swift; do n=${f:t}; git -C "$1" ls-files -s "Ferazel/Windows/Sources/FerazelWinKit/$n" | grep -q "^120000" || echo "missing $n"; done' _ "$WT"
# G-MUTE (from WF1) the Mac's one audio-output open and its beeps sit behind the mute switch: 1, then 1
grep -rn 'ShellMixer(' "$WT/Ferazel/App" "$WT/Ferazel/Shared" | wc -l   # the one call, inside the factory WF1 gates (comments say `ShellMixer.init`)
grep -rn 'NSSound\.beep()' "$WT/Ferazel/App" | wc -l                                           # the one call, inside the gated beeper
# GW5 (WF6 and every phase end) stage: exit 0; PE subsystem 2 (Windows GUI); the zip's file list = the script's manifest
"$WT/tools/windows/stage-ferazel-win.sh" --no-desktop; echo $?          # a zsh script: run directly, never `bash …`
"$HOME/Developer/Toolchains/windows-cross/swift-6.4.0-RELEASE.xctoolchain/usr/bin/llvm-objdump" -p "$WT/out/Windows/Ferazel's Wand/Ferazel's Wand.exe" \
  | awk '/^Subsystem/ {print $2}'                                       # 2 (stage-btx.sh:184's check; grep prints 3 lines)
diff <(zipinfo -1 "$WT/out/Windows/Ferazel's Wand (Windows).zip" | grep -v '/$' | grep -vx 'MANIFEST.txt' | sort) \
     <(sort "$WT/out/Windows/Ferazel's Wand/MANIFEST.txt")              # empty (folder entries and the manifest itself filtered)
```

Launch gates (each after the LAUNCH GUARD; skipped by night with the "boot check owed" line):

```sh
# GWB Proof B (from WF0's run; every wave end that touches Core or Windows): last line, run once whole
"$WT/tools/windows/proof-b-ferazel.sh"          # proof-b: 490 passed / 0 failed / 0 skipped / 0 crashed (of 490)
# GW4R (from WF3) the Mac SDL development build, headless, dummy drivers (a launch by seat ruling): exit 0; log line
#      ends "video=dummy audio=dummy"; the dump's FNV = WF2's recorded main-menu FNV
#      (run only through the smoke script, which refuses without the guard and dummy drivers)
"$WT/tools/windows/smoke-ferazel-win.sh" --mac-only
# GW6 (WF6) the staged zip boots in a clean CrossOver bottle, muted: "main menu: identical", "new game: identical", exit 0
"$WT/tools/windows/smoke-ferazel-win.sh"
# G9M (WF6) the Mac staged app boots MUTED: pid line after 5 s, second pgrep empty, no new crash log
APP="$WT/out/Ferazel/Ferazel's Wand.app"; open -n "$APP" --args -FerazelMute YES; sleep 5; pgrep -fl "Ferazel's Wand" | cut -c1-100; osascript -e 'tell application "Ferazel'"'"'s Wand" to quit'; sleep 2; pgrep -fl "Ferazel's Wand"; ls -t ~/Library/Logs/DiagnosticReports | head -n 3
```

`proof-b-ferazel.sh` and `smoke-ferazel-win.sh` **refuse to run** (exit 64, one line saying why) unless
`HECTOR_SDL_AUDIO_DRIVER=dummy` is what they pass (they set it themselves and check it) and `date +%H` is in 09..20;
the smoke's Mac half also refuses unless it passes `--mute` and the dummy drivers. G9M never runs without
`--args -FerazelMute YES`. Implementers run their task's gates; reviewers re-run them independently (reviewers build in a
`mktemp` copy with their own `WIN_BUILD_ROOT`, never the seat's) — reviewers re-run launch gates only under the guard.

## Rulings (D43 — seat, under D34's plan authority; Ben reads later)

1. **One neutral shell half, shared by symlink.** The platform-neutral part of `FerazelController` (boot, renderers,
   segment routing, present, level services, load servicing, settings) and all of `FerazelAudio` move to
   `Ferazel/Shared/`, compiled by the Mac target and symlinked into `FerazelWinKit`. *Why:* D41's lockstep — a Phase 5
   change to what the shell does must land once, not twice; BTX's "port, don't share" (D15.5) existed only because Ben
   was playtesting that Mac app; here the Mac app's behaviour is held by G2/G5 and reviewers read the move line by line.
   *Rejected:* a copy-port (drifts); a new target in `Ferazel/Core` (Core's 490 ladder and G7 would carry shell code).
2. **Text without CoreText = BTX's baked format and rasterizer, copy-adapted, baked from the Mac's own CoreText path.**
   BTX learned that CoreText places glyphs at fractional pen positions and snaps each to a few subpixel phases, with
   kerning and ligatures, so one bitmap per glyph cannot match it (`BubbleTroubleX/Windows/Sources/BTXWinKit/BTXFont.swift:3–30`);
   its format (per glyph: f64 advance + phase segments → de-duplicated bitmaps; kerning pairs; ligatures) and
   `BitmapFontRasterizer` reproduce every string CoreText draws exactly. Ferazel's Mac rasterizer draws whole lines
   through `CTLineDraw` and then, below the smoothing threshold, cuts the composed coverage to 0/255
   (`Ferazel/App/CoreTextRasterizer.swift:46–75`), so the Windows rasterizer composes the line BTX's way and applies
   **the same cut after composition**, never per glyph. `fz-bake-font` (Mac, BTX `btx-bake-font` shape) resolves fonts
   only through the very `CoreTextRasterizer` the Mac app uses (moved to Shared, Mac-only by `#if canImport(CoreText)`)
   and bakes, per face the game draws, every MacRoman character's phase segments, advance and line metrics, kerning
   pairs and ligatures, plus `fontInfo`; `charWidth` = the Mac's rounding of the baked f64 advance. Faces (the only text
   sites — `StatusBar.swift:152,196–197,217–218`, `ConversationRun.swift:474,488,505`): Times 12 bold, Geneva 9 plain,
   Geneva 8 bold, Times 18 plain; plus the dialog face (WF4a) = **font 0, face 1** (the UI font, bold) through
   `CoreTextRasterizer` — the only route it has (its families are 2/3/4/20/21/22, and 0/1 resolve to the UI font,
   `CoreTextRasterizer.swift:24–35`), standing in for the Mac's `.boldSystemFont(ofSize: 12)` (`ClassicFont`,
   `DialogViews.swift:12–13`, which tries Charcoal, then Chicago, by `NSFont` name); if the two differ, ◇W13. **No string cache and no ±1 px bar**: BTX's way places
   fractional advances itself (leg B measured digit advances Times bold 12 = 6.0, Geneva 9 = 5.9985, Geneva bold 8 =
   5.332 — the Geneva ones are not whole pixels). **Measured equal on the Mac, byte for byte against
   `CoreTextRasterizer`:** every glyph, every string the game draws from a closed set (level names, `"x"`), the score /
   coin strings and the Geneva item-count strings; end-to-end frame-index equality on the level-1 golden route and the
   sign/conversation route (FNV of the 640×480 indices, baked vs CoreText); a staleness test (fresh bake = committed
   files). If the item-count strings are not exact BTX's way, the closed set of count strings the game can show is
   baked whole as a fallback for those strings only (recorded in D43) — never a tolerance. Classic Times/Geneva (D39,
   Q8) later = re-bake.
3. **Saved-game panels → the native Windows Open / Save dialogs** (comdlg32 `GetOpenFileNameW` / `GetSaveFileNameW`
   through Swift's `WinSDK`, Explorer style, in the executable under `#if os(Windows)`; no HectorKit change). *Why:* Ben's
   Q3 (2) chose the platform's own panels on the Mac; this is the same choice on Windows; it is modal and synchronous like
   `NSSavePanel.runModal` (`FerazelController.swift:569–605`), so the flow is held still the same way. Title = the
   prompt, default name = the flow's, made Windows-legal (Ruling 10). Start folder as the Mac: the **Save** dialog's is
   the saves folder, created first (`files.ensureFolder()`, `:579`); the **Open** dialog starts there only when it
   already exists and never creates it (`:598`). The Mac Save panel's message line (`panel.message = r.message`, `:576`,
   DITL 1003 item 13's text) has no place in the Windows dialog (no message area in `GetSaveFileNameW`) — dropped, ◇W9.
   *Rejected:* the original's Standard File (DITL 1003/1500) drawn in-window (faithful look, but a file browser to build
   and Ben chose modern panels on the Mac) — owner choice, Questions WQ2; SDL3's file dialog (HectorSDL would need a
   change, and it is asynchronous).
4. **The original's dialogs drawn in-window** (D15.3, BTX W6): DLOG 202 confirm, 200 report/error, 6900 Options, 600
   Credits — modal over the canvas, the flow not ticking meanwhile, behaviour per `Ferazel/App/Dialogs/*` (itself the
   transcription), look per the Mac's classic style (`DialogViews.swift:1–20`: black outlines on the `dctb` grey,
   system font 12, OK ring), not BTX's; the text in the baked dialog face, font 0 face 1 at 12 pt (Ruling 2). Code: adapted copies of BTXWinKit's `DialogRenderer` / `DialogWindow` /
   `DialogSystem` (BTX's package untouched — its types are BTX-bound: `BTXPrefs`, `ArtBank`, its `SoundCue`). **Scale:**
   on the Mac each dialog is its own 1× window with sharp Retina text, centred over the game but not scaled with it
   (`FerazelCarbonDialog.swift:314–319`, `FerazelDialogs.open`); on Windows the dialog is drawn into the 640×480 picture
   and scales with the game (up to 3×, 1× baked glyphs enlarged) — the BTX W6 precedent, ◇W10, Questions WQ7.
5. **No menu bar** (D21, re-ruled for Ferazel as design §7.4 promised). MBAR 128's commands stay reachable exactly as
   their ⌘ keys are on the Mac: **Ctrl alone** (no Shift, Alt or Windows key — the Mac takes a shortcut only with ⌘ and
   no other modifier, `FerazelMenus.swift:132–133`) + a letter acts as the menu pick only where the Mac's menus are live
   (`MenuState.menusLive` — main menu and pause). The letters come from the MENU resources' key equivalents, as the Mac
   builds them (`MenuTemplate.Item.keyEquivalent`, `FerazelMenus.swift:88`) — never a hard-coded list (today they read
   N / O / W / Q / M / F / P). The Mac's enable rules (`:114–121`) and the main menu's letter fall-through (`:130–152`)
   move to `Ferazel/Shared/FerazelMenuRules.swift` so both shells use one rule; elsewhere Ctrl+letter reaches the game as ⌘+letter in the polled keys, as on the Mac (a level's ⌘Q/⌘W/⌘P).
   A taken shortcut never enters the held keys (on the Mac the menu consumes the key-down). About has no shortcut (as
   D21): Credits stays on the main menu. Check marks have nowhere to show (the pause banner is the original's).
6. **Keys** (D18.5 map, unchanged HectorSDL): Ctrl = ⌘, Alt = ⌥, Windows key = ⌃, right-hand modifiers folded to the
   left ones (`FerazelController.swift:384–392`, moved to Shared). Keypad defaults kept (SDL reports keypad scancodes
   0x52–0x5C, `SDLKeymap.swift:64–67`); Num Lock behaviour on a real keyboard is on Ben's card. Remapping = the Options
   dialog, as the Mac. Key names in Options come from `HectorInput.ShellKeyCharacters` (US layout) — the Mac asks the
   live layout (`FerazelController.swift:303–322`) ◇.
7. **Gamepad** (D37): `SDLHost.padState()` → `ShellPadTranslator` with `FerazelPadLayout.mapping(keys:context:dialogUp:)`
   each poll, merged into the held keys and the Caps Lock latch exactly as HectorShell's `ShellView.pollKeyState` does
   for the Mac (BTX: the merge in `WinGameDriver.swift:~360–370`, `pollPad`); with a confirm/report up, pad Return/Esc
   answer it (the Mac's `padKeyPanel` rule, `FerazelController.swift:722–735`).
8. **Clock:** ticks = `SDLClock.nanoseconds` × 60 / 10⁹ (absolute, `UInt32` wrap like `ShellClock.ticks()`); the loop
   wakes every 1/240 s (`SDLClock.sleepPrecise`) and runs the flow at most once per new tick, never while a dialog or a
   file dialog is up — the Mac's `idleFired` (`:325–352`). The 30-step cap and 2-tick cadence stay Core's (Q9: keep the
   speed); the shell adds no cap of its own.
9. **Quit:** the window's close button, Alt+F4 and the taskbar's Close arrive as SDL's quit event = the Mac's Dock Quit
   (D40): `GameFlow.systemQuit()` — a level running free asks "Are you sure you want to quit?", elsewhere the queued
   quit event as the original. The close button itself is new: the Mac window has none (`FerazelController.swift:187–189`,
   `[.titled, .miniaturizable]`) and SDL's window always has one — ◇W11. A quit that arrives before the flow exists ends
   at once, as the Mac's `applicationShouldTerminate` does (`:659`). **Logoff / shutdown** must never be held by the
   confirm (the Mac answers a session-ending quit with `.terminateNow`, `:660`; D40): WF3 reads how SDL 3.4.16 reports a
   Windows logoff (`WM_QUERYENDSESSION` / `WM_ENDSESSION`) and records it in D43 — if SDL gives a distinguishable event,
   it quits at once; if it arrives as the plain quit event, the confirm may show and Windows ends the process after its
   own timeout, which loses nothing (`.Quit` writes no prefs) — accepted and named in ◇W11. The flow's `.quit` request
   ends the loop, stops audio, exits 0.
10. **Prefs and saves:** `%APPDATA%\Ambrosia Classics\Ferazel's Wand\` holds the prefs file (`PrefsFile.fileName`, the
    same 0x942-byte record the Mac writes) and is the saves dialogs' start folder; never `UserDefaults` (D16.3). The Mac
    SDL development build uses `~/Library/Application Support/Ambrosia Classics/Ferazel's Wand (SDL)/` (never the Mac
    app's folder; BTX `WinPrefsFile.swift:24` shape); `--prefs FILE` / `--saves DIR` override. A default save name is
    made Windows-legal: each of `\ / : * ? " < > |` and control characters → `-`, trailing dots/spaces dropped, a
    reserved device name (CON, PRN, AUX, NUL, COM1–9, LPT1–9) gets `_` appended; no extension is added (the Mac's files
    have none; Core refuses a non-save with the original's text) — WQ6.
11. **Hidden switches:** `-FerazelLevel N`, `-ColorTieBreak lowest`, `-MacGamma YES`, `-FerazelMute YES` on the command
    line, for one launch, parsed with the Mac's `UserDefaults` argument-domain semantics (`FerazelController.swift:174–185`:
    integer, exact `"lowest"`, bool) by one shared `FerazelSettings.parse(lookup:)`. `UserDefaults` reads strings
    loosely (a bool from "y" / "t" / a leading digit, an integer from "2abc" → 2); WF1 measures `UserDefaults`'
    argument-domain answers on the Mac for those cases and pins them as rows of the parse table, so Windows reads every
    value as the Mac does. No persistent store on Windows. No single-instance guard: a second launch on Windows is a
    second game (the Mac opens a save in the running app) — ◇W12.
12. **Data:** `Data\` beside the exe = `Resources/Ferazel/` unchanged (six `.rsrc` + `Ferazel's Wand Music\`, D10, design
    l. 119) + `Fonts\*.fzfont`; `--data DIR` overrides; the start-up check names any missing file in a message box and
    the log (BTX `WinStartup.swift:17`). No `Decoded\` (no codec pictures). The message box shows in Release too, where
    the Mac shows its alert only in DEBUG builds (`FerazelController.swift:100–108`) — justified: the Mac's data sits
    sealed inside the app bundle, while `Data\` lies loose beside the exe and is lost by copying the exe alone, and a
    GUI-subsystem exe that exits silently tells the player nothing (BTX W7 did the same). Never in `--frames` mode.
13. **Audio:** music on a `PCMMixer(voices: 1, outputRate: 48000)` through one `SDLAudioOut`; the Sound Tool (a
    `PCMPullSource` at 22,050 Hz, `SoundTool.swift:42,52`) through a second `SDLAudioOut` — SDL3 mixes the two logical
    streams on the default device (`shim.h:162–168` opens one per call), as the Mac's `ShellMixer.attachStream` puts it
    beside the voice. Cue order, the music track rule and volumes are the shared `FerazelAudio`. Mute: Ruling 20.
14. **Window:** the 640×480 game screen alone (D21), title "Ferazel's Wand", opening at the largest whole scale k ≤ 3
    whose window fits the usable area (the Mac rule, `:193–205`), HectorSDL's resizable integer-fit window on black
    (◇ the Mac's is fixed; HectorSDL always opens resizable, `SDLHost.swift:43`). Full screen = **Alt+Enter** (the Mac's
    ⌃⌘F would be Win+Ctrl+F, a Windows system key, and Ctrl+F is ⌘F = Sound Effects) — eaten by the shell. Cursor
    hide/show honoured only over the canvas, focused, no modal up (`:624–635`). `.hideMenuBar`/`.showMenuBar` ignored.
15. **D42 as amended — launches muted, by day, few and short.** Proof B (GWB), the Mac SDL development build's headless
    run (GW4R — a launch by seat ruling, though it opens no window and plays nothing), the staged zip's boot in a clean
    CrossOver bottle (GW6) and the Mac staged app's boot (G9M) are **loop gates**, each behind the LAUNCH GUARD
    (`date +%H` in 09..20, else skipped with "boot check owed (night rule)" in LOOP-LOG and on the gate card — the
    first daytime run does it) and the mute switch; the scripts refuse to run otherwise. Proof B runs the whole suite
    once; per class only after a crash. GW1–GW5 (build, macOS-hosted tests, stage) run at any hour. Proof B's and the
    smoke's scripts also stay on the gate card for Ben and Andrew.
16. **Lockstep (D41) — the standing contract for Phase 5 onward** (copied into every later plan's preamble):
    (a) a task that changes what the Mac app shows or does — `Ferazel/App`, `Ferazel/Shared`, a new `ShellRequest` /
    `FerazelDialog` case, a new text face, a new data file — carries its Windows side in the same task (FerazelWinKit /
    FerazelWin change + GW2 tests + GW3), and its Files list names both; (b) a Core-only task runs GW1, GW2 and GW3 and
    G5 — a Core API change can break the shared files, the Windows package or the Mac app without touching them (the
    run-25 lesson); (c) a change to `Ferazel/Shared` is reviewed for
    both shells; (d) a text-path change re-runs `fz-bake-font` and commits the `.fzfont` files (the staleness test fails
    otherwise); (e) every phase end stages both builds (`tools/stage-ferazel.sh` + `tools/windows/stage-ferazel-win.sh`)
    with ONE gate card that has a Mac part and a Windows part, and the Fable phase review covers both diffs.
17. **No HectorKit change.** Everything new is Classics-side; G1 stays 35a85ba, floor 361. (A later wish — a fixed-size
    window, layout-aware key names via SDL — would be an HK task under NEXT AUTHORIZATIONS.)
18. **Foundation-on-Windows traps (D19.5, D16, BTX W7):** Windows-run code never calls `replacingOccurrences`
    (pure-Swift replace, BTX `TextReplace.swift` shape), never `.macOSRoman`, never `UserDefaults`; the GUI-subsystem
    exe never touches `FileHandle.standardError` or `NSLog` (they trap with no console) — reports go through C stdio
    (`fputs` to stderr, silently dropped without a console) and the log file, as BTX
    (`BubbleTroubleX/Windows/Sources/BubbleTroubleXWin/main.swift:26–28`); while the window is dragged or resized Windows'
    modal move/size loop blocks the poll, so the executable installs HectorSDL's live-redraw handler and steps the game
    from inside it (BTX `main.swift:313–318`).
19. **Build-root isolation:** every Ferazel cross-build passes `WIN_BUILD_ROOT=$WIN_CROSS/build/ferazel` (scripts set it
    themselves) — `build.sh:47` would otherwise share `build/Core` / `build/Windows` with BTX's packages. The stage
    script uses its own folders too (`$WIN_CROSS/work/stage-ferazel`, `$WIN_CROSS/build/stage-ferazel`): `stage-btx.sh`
    deletes `build/stage` and `work/stage-btx` (`:72,180`), and `build/ferazel` is the gates' root, never wiped by staging.
20. **Mute (D42) and determinism.** *Mac:* `-FerazelMute YES` (argument domain, like the other hidden switches) or
    `FERAZEL_MUTE=1` in the environment, read by the shared `FerazelSettings.parse`; when set, no `ShellMixer` is created
    (the only audio-output open is `FerazelController.swift:121` `try? ShellMixer(voices: 1)`; `FerazelAudio` already runs
    silent with no mixer, `FerazelAudio.swift:35–39`) and the system beeps are suppressed
    (`FerazelDialogs.swift:62,103,185`, `CreditsDialog.swift:79`). *Windows:* `--mute` (or `FERAZEL_MUTE=1`) forces the
    SDL audio driver hint to `dummy` before audio opens (BTX `BubbleTroubleXWin/main.swift:127–130`;
    `HECTOR_SDL_AUDIO_DRIVER=dummy` already maps through `SDLHost.applyDriverOverridesFromEnvironment()`,
    `HectorKit/SDL/…/SDLHost.swift:91–96`, and `run-in-crossover.sh:40–46` refuses without it) and suppresses
    `MessageBeep`; the launch log prints `audio=<driver>`. *Determinism:* muted play sees "no sound playing"
    (`LevelRun.swift:406,456,670` read `input.playing`), which changes level logic against an unmuted run — fine for
    boot checks. Headless `--frames` dumps on both builds therefore open **no audio device at all** and drain the Sound
    Tool through a **silent mixer** once per game tick, so `playing` follows the sounds as with real output. The drain
    is fixed: 22,050 Hz / 60 = 367.5 output frames per tick, so the silent mixer **accumulates the fractional frames**
    (a running total of 22,050 × ticks / 60, drained to its whole part each tick → 367, 368, 367, 368 …, starting with
    367 on the first tick) — both builds compute "playing" from the same frame count. The game's two clocks are pinned
    too: the flow's RNG is seeded from the wall clock at launch (`FerazelController.swift:136`
    `FastRand.clockSeed(…)`, taken by `GameFlow.init`'s `seed`, `GameFlow.swift:263–268`) and `dateTime`
    (`GetDateTime`) is the live clock (`FerazelController.swift:141`), so in `--frames` mode the seed is a fixed
    constant (`--seed N` overrides it; default = the fixed seed WF1's tests use) and `dateTime` is a scripted clock (a
    fixed start + the elapsed game ticks / 60). Only then are dumps deterministic and comparable Mac ↔ Windows (GW4R,
    GW6). The interactive game keeps the wall-clock seed and live `dateTime`, as the Mac.

## Tasks

Every brief tells the implementer: work in the run's worktree; read the cited lines first; the Mac app's behaviour must
not change (G2 490/0 and G5 on every task that touches it); run a built executable only through a launch gate — muted,
behind the LAUNCH GUARD, few and short (D42); never `swift run`, never `open` outside G9M.

### WF0 — Core cross-compiles with its tests; Proof B

- **Goal:** de-risk the toolchain first: GW1 green, and Proof B green with the known Windows differences fixed.
- **Files:** `Ferazel/Core/Tests/FerazelCoreTests/FerazelDataTests.swift:36–44`; `Ferazel/Core/Tests/FerazelRenderTests/CensusTests.swift:18–23,125–136`;
  `Ferazel/Core/Sources/FerazelRender/Census/FerazelCensus.swift:63,560–561`; new `tools/windows/proof-b-ferazel.sh`;
  `tools/windows/README.md` (a "Ferazel's Wand" section).
- **Contracts:** (1) the environment override in `FerazelDataTests` uses a test helper that sets/unsets the variable so
  `ProcessInfo.processInfo.environment` sees it on both platforms (`setenv`/`unsetenv` on Darwin; on Windows the CRT's
  `_putenv_s` / `_wputenv_s`, which also update the Win32 block — leg A measured GW1 green with a `_putenv_s` shim;
  that is build-proved only: if Proof B shows `ProcessInfo.processInfo.environment` does not see the override, the
  helper uses `SetEnvironmentVariableW` (WinSDK) instead, or as well) — Mac behaviour identical; (2) on Windows that test links the data files with hard links (`FileManager.linkItem`),
  falling back to copies, instead of symbolic links — same assertions; (3) `censusBinary()` on Windows finds
  `ferazel-census.exe` in the running executable's folder (the Windows runner is a renamed `.exe`, not an `.xctest`
  bundle, `CensusTests.swift:19`); on the Mac it stays the bundle's folder; (4) the child-output comparisons
  (`:132–133` and every other compare of `runCensus` stdout) drop `\r` from the child's output on Windows only — the
  Mac comparison unchanged; (5) the census's **five** `replacingOccurrences` calls (`:63` two, `:560–561` three) go
  through a pure-Swift replace — the Mac census stdout byte-identical (G3 + `CensusTests` unchanged); (6)
  `proof-b-ferazel.sh` (zsh) = `proof-b.sh`'s shape for Ferazel: copies `Ferazel/Core` + `docs/ferazel/data-census.md`
  under `$WIN_CROSS/work/proof-b-ferazel/` laid out like the repo, symlinks HectorKit at `work/HectorKit` (shared with
  BTX's script — same target), builds with `WIN_BUILD_ROOT=$work/build`, exports `FERAZEL_DATA` as a `Z:\…` path to
  `Resources/Ferazel` and `HECTOR_SDL_AUDIO_DRIVER=dummy HECTOR_SDL_VIDEO_DRIVER=dummy`, runs the whole suite **once**
  through `run-in-crossover.sh` (`--class NAME` re-runs one class, for use only after a crash) with
  **`WIN_RUN_TIMEOUT=3600`** set for that run — the runner's default watchdog is 900 s (`tools/windows/README.md:19`,
  `run-in-crossover.sh:72`), G2 alone takes ~7 min on the Mac and CrossOver is slower, and a watchdog kill (exit 124)
  must never read as "all crashed": a 124 is reported as "timed out", not as a count. It prints the
  `proof-b: passed / failed / skipped / crashed (of N)` line. It **refuses** (exit 64, one line) unless `date +%H` is
  in 09..20 and the audio driver it passes is `dummy`. Never touches the repo's copy. If a Windows difference cannot be
  removed, the implementer names a skip rule with its exact count instead, and the expected line changes to it (D43).
- **Tests:** none added; G2 **490/0** (Mac) proves the edits kept every test.
- **Acceptance:** GW1 → `0` then `2` (~20 s warm); G2 490/0; G3 1,108/0; G6 = the Files; G10; `zsh -n` on the script;
  the guard checked with `proof-b-ferazel.sh --check-guard` (evaluates the hour and the driver, builds and runs
  nothing; no hour override exists) → by night exit 64 "refused (night rule)", by day exit 0, and with
  `HECTOR_SDL_AUDIO_DRIVER=wasapi` in the caller's environment it still reports `dummy` (the script sets the driver,
  never inherits it); **GWB** (behind the LAUNCH GUARD) → `490 passed / 0 failed / 0
  skipped / 0 crashed (of 490)`, or by night "boot check owed (night rule)" and the first daytime run does it. README
  states the expected line and **the measured wall time of the whole-suite run** (also recorded in the plan's
  as-executed notes); if it comes near 3,600 s the timeout is raised there, never the suite split.

### WF1 ⚑ MAJOR — The shared shell half; the Mac mute switch; the FerazelWindows package

- **Goal:** one neutral driver both shells call; the Mac's mute switch (D42) built and tested headlessly; the Windows
  package exists and tests it on the Mac.
- **Files:** new `Ferazel/Shared/FerazelDriver.swift`, `Ferazel/Shared/FerazelAudio.swift` (moved from
  `Ferazel/App/FerazelAudio.swift`, git mv), `Ferazel/App/FerazelController.swift` (the moved parts become calls; the
  mixer factory and beeper wired), `Ferazel/App/` one small file for `extension ShellMixer: FerazelMixer` (or inside the
  controller), `Ferazel/App/Dialogs/FerazelDialogs.swift:62,103,185` + `Ferazel/App/Dialogs/CreditsDialog.swift:79`
  (beeps through the gated beeper), `project.yml` (Ferazel target: `- path: Ferazel/Shared`; add the HectorAudio product
  only if the compiler asks), new `Ferazel/Windows/Package.swift` (BTX `Package.swift` shape: `../Core` products
  FerazelCore + FerazelRender, `../../../HectorKit` products HectorResources/HectorGraphics/HectorAudio/HectorInput —
  the same path identity Core uses; the SDL dependency arrives in WF3), symlinks
  `Ferazel/Windows/Sources/FerazelWinKit/{FerazelDriver,FerazelAudio}.swift`, `Ferazel/Windows/Tests/FerazelWinKitTests/*`.
- **Contracts:** `FerazelDriver` (`@MainActor final class`, Foundation + FerazelCore/Render only) takes over, with the
  same order and results: the boot in `applicationDidFinishLaunching` (`:98–171` minus the window/menus/dialogs/timer —
  resources open, `ColorSearch(.exactNearest, tieBreak)`, surface under clut 0x321, the two `ScreenRenderer`s, the map
  renderer, `TextLayout.conversationText`, prefs load-or-store-defaults, the clock seed, `GameFlow`, `startLevel`;
  injected by the shell: the **text renderer** (`TextRasterizer` — the Mac passes its `CoreTextRasterizer`, Windows its
  baked one from WF2), the **seed** (the Mac passes `FastRand.clockSeed(…)` as today; headless `--frames` a fixed
  one, Ruling 20), the `keyCharacter` / `dateTime` hooks, the **mixer factory** `() -> FerazelMixer?` and the
  **beeper** `() -> Void`); one tick (`:325–352`: flow tick, `configureLevelRun` `:396–402`, `draw(segments)`
  `:405–436` with `isConversationOp` `:440–446`, the audio apply, prefs to the renderers, `serviceLoad` / `loadSounds` /
  `loadFaces` `:451–492`) returning `present` and the requests for the shell to honour; `present` (`:497–509`) as both
  the Mac's ARGB words and the RGBA bytes `SDLHost.present(rgba:)` takes, MacGamma applied to the palette;
  `dialogPicture` (`:279–299`) as RGBA bytes + size (the Mac wraps them in a `CGImage`); `LevelServices` (`:760–782`);
  `keyMapCode` (`:384–392`); `FerazelSettings.parse(lookup:environment:)` for the hidden keys (`:174–185`; the Mac's
  lookup reads `UserDefaults.standard`) **plus `mute`** (Ruling 20: `-FerazelMute` bool by the same semantics, or
  `FERAZEL_MUTE=1`). **Mute:** when `mute` is set the driver never calls the mixer factory (so the Mac creates no
  `ShellMixer` — `FerazelController.swift:121` is the factory's one body, G-MUTE) and the beeper does nothing (every
  `NSSound.beep()` goes through it). **Headless frames** (Ruling 20): the driver also offers a silent mixer
  (`FerazelMixer`, no device) that drains the Sound Tool once per game tick, for the `--frames` dumps of both builds —
  by Ruling 20's rule: 22,050 / 60 = 367.5 frames per tick, fractional frames accumulated (367, 368, 367, 368 …,
  first tick 367), never rounded per tick.
  `FerazelAudio` unchanged in logic over `protocol FerazelMixer { load, play, stop(voice:), stopAll, setVolume,
  attach(stream: SoundTool) }`; its `NSLog` becomes an injected log closure. The App keeps only AppKit/HectorShell
  work. A failure the Mac turned into `fail(…)` stays the shell's.
- **Tests (+17, FerazelWinKitTests, real data via `FerazelData.dataDirectory()`, a fake mixer, a fixed clock and a
  named stub text renderer `StubGlyphRasterizer` — fixed-width solid boxes, so frame FNVs here pin the driver, not the
  text; WF2 re-measures the text frames with real glyphs):** settings parse table (absent, "2", "9", "0", "lowest",
  "LOWEST", "YES", "1", "true", "NO", and the loose cases "y", "t", "2abc" with the values `UserDefaults`' argument
  domain gives on the Mac, measured by the implementer and recorded; `-FerazelMute YES` / `NO`, `FERAZEL_MUTE=1` / `0`
  / absent); boot to the main menu in a fixed tick count and the presented RGBA FNV there (self-measured, recorded in
  the commit body and D43 — the tick count also sets the smoke's frame counts, WF6); MacGamma on = LUT through the
  palette; New Game (held N) reaches level 1's popup and its first presented frame FNV (stub text);
  `isConversationOp` table; `keyMapCode` table; audio apply order (stops before play i; `onlyIfIdle`; trailing stops);
  `resolveTrack` (−1, 0, 33, 21 → 20, 27 → 26, none → nil); music cue sequence on the fake mixer; `loadSounds` with F1
  (`only` = the four ids); `loadFaces` progress count 25; `prepare`/`attach` through the driver; `dialogPicture` under
  the current clut; the symlink-coverage test (every `Ferazel/Shared/*.swift` has its FerazelWinKit symlink); **mixer
  factory calls counted** (muted: 0 through boot + New Game; unmuted: exactly 1); **beeper gated** (muted: a refused
  dialog's beep reaches the injected beeper 0 times; unmuted: 1); **silent mixer drain** (a cue's `playing` turns false
  after the tick its samples run out, the same tick on every run; the per-tick drain over 4 ticks is 367, 368, 367, 368
  and over 60 ticks totals 22,050).
- **Acceptance:** G2 490/0; G5 SUCCEEDED; GW2 **17/0**; G-MUTE `1` / `1`; G7 + G7W empty; GW-symlinks empty; G6; G10.
  Both review legs read the `FerazelController` diff as a move (nothing re-ordered); one leg builds the app and diffs
  the App's symbol list for anything lost. No launch in WF1 (the switch is proved headlessly; G9M first uses it in WF6).

### WF2 — Baked text (Ruling 2)

- **Files:** `git mv Ferazel/App/CoreTextRasterizer.swift Ferazel/Shared/` + whole-file `#if canImport(CoreText)`;
  its FerazelWinKit symlink; new `Ferazel/Windows/Sources/FerazelWinKit/{FZFont,BakedTextRasterizer}.swift`
  (copy-adapted from BTX `BTXFont.swift` / `BitmapFontRasterizer.swift`), `Ferazel/Windows/Sources/fz-bake-font/main.swift`
  (Mac-only body under `#if canImport(CoreText)`, BTX `btx-bake-font` shape), `Ferazel/Windows/Resources/Fonts/*.fzfont`
  (committed), `Package.swift` (the baker product), tests.
- **Contracts:** `.fzfont` = BTX's documented `.btxfont` layout (`BTXFont.swift:11–30`) under the magic `FZF1`, with
  the face (family, size, QuickDraw face bits) and `fontInfo` (ascent/descent/widMax/leading) added: per glyph its f64
  advance, line metrics and phase segments → de-duplicated coverage bitmaps (found by bisection, as BTX's baker),
  kerning pairs, ligatures. **No string cache.** The baker resolves fonts only through `CoreTextRasterizer` (no second
  CoreText path). `fz-bake-font` is its own module, so the class is `internal` today (`CoreTextRasterizer.swift:13`,
  `final class`, implicit init) and invisible to it once symlinked: WF2 makes the class, an explicit `public init()`
  and every member the baker uses (`rasterize` `:46`, `charWidth` `:80`, `fontInfo` `:90`, `smoothingThreshold` `:19`,
  and whatever the bisection needs) `public` — access only, behaviour-neutral (G5 holds, the Mac app's text
  unchanged). `BakedTextRasterizer: TextRasterizer` (`TextRasterizer.swift:11–34`): `rasterize` composes the line
  BTX's way (fractional pen, phase segment per glyph, kerning, ligatures) into a coverage mask in the Mac's frame
  (`-pad`, `-above`, `pad = 2`, `CoreTextRasterizer.swift:57–60`) and **then** applies the Mac's 0/255 cut below the
  smoothing threshold (`:73`) to the composed mask; `charWidth` = the Mac's rounding of the baked advance; `fontInfo`
  from the file; an unbaked face → empty mask + one log line. The closed string set (level names from where
  `StatusBarState.levelName` is filled — the implementer finds and cites it — and `"x"`) is a test fixture, not a
  cache. If the Geneva item-count strings do not come out exact, the closed set of count strings the game can show is
  baked whole for those strings only (recorded in D43); there is no tolerance bar. This task also re-measures WF1's
  stub-text frames with real glyphs: the baked-text main-menu and level-1 FNVs are recorded in the commit body and
  D43 and become WF3's reference.
- **Tests (+10; the CoreText oracle ones are Mac-only by `#if canImport(CoreText)`), every comparison byte for byte
  against `CoreTextRasterizer`:** every face × every MacRoman character (mask, offsets, `charWidth`) and `fontInfo`;
  the closed string set (level names, `"x"`); score/coin strings 0…99,999 sampled (1,000 seeded + edges) in Times 12
  bold; Geneva 9 and Geneva bold 8 item-count strings (every count the game can show); kerning and ligature pairs the
  faces have; staleness (fresh bake == committed bytes); format round trip; unbaked face; the face set the game asks
  for (a recording rasterizer driven through the status bar and the conversation layout) ⊆ baked; level-1 golden route
  frame indices baked = CoreText and the sign-frame route (`c8e41941c1e4d6da`'s scenario) baked = CoreText (one test,
  two routes, FNV).
- **Acceptance:** GW2 **27/0**; G2 490/0; G5 (the App lost a file to Shared); GW1; G7W; G6; G10.

### WF3 ⚑ MAJOR — FerazelWin: the game on HectorSDL; the Windows mute switch

- **Files:** `Ferazel/Windows/Package.swift` (+ `../../../HectorKit/SDL`, executable `FerazelWin`); new
  `Sources/FerazelWin/main.swift` (SDL glue only, BTX `BubbleTroubleXWin/main.swift` shape);
  `Sources/FerazelWinKit/{WinGame,WinInput,WinShortcuts,WinFiles,WinArgs,WinStartup,WinKeyScript,WinDialogs,WinFilePanels,WinAudioDriver}.swift`
  (`WinKeyScript` adapted from BTX `WinInput.swift:26–170` — `WinKeyNames` `:26–55` with `WinKeyScript` `:74–170`, the
  script needs the names; `WinDialogs` / `WinFilePanels` are protocols with stub answers here); new
  `Ferazel/Shared/FerazelMenuRules.swift` + symlink; `Ferazel/App/FerazelMenus.swift:44–46,114–152` (calls the shared
  rules; behaviour identical); new `tools/windows/smoke-ferazel-win.sh` (zsh; its Mac half only — `--mac-only`; it
  refuses like Proof B's script and passes `--mute` + dummy drivers itself).
- **Contracts:** Rulings 5–14 and 18–20 as written: the loop and ticks (8); `FrontInput` from SDL events — held Mac key
  codes through `keyMapCode`, Caps Lock from the poll's modifier state, mouse in canvas pixels via
  `SDLLayout.logicalPoint` (nil off the canvas), button, active = focus, `playing` from the audio (`:357–363`); the pad
  (7); the requests (`:513–529`: cursor, menu-bar ignored, `showMenuBarItems` → shortcut state, dialog → `WinDialogs`,
  put/get file → `WinFilePanels`, quit); shortcuts (5), Alt+Enter (14); quit (9, including a quit before the flow
  exists → exit 0 at once, and the logoff reading recorded); files + args (10–12); audio (13); **mute (20):**
  `WinAudioDriver.hint(arguments:environment:)` — a pure function: `--mute` or `FERAZEL_MUTE=1` → `dummy`, else
  `HECTOR_SDL_AUDIO_DRIVER` as given, else none — applied with override priority before any audio opens, after
  `SDLHost.applyDriverOverridesFromEnvironment()`; muted, `MessageBeep` is never called; the launch log line prints
  `video=<driver> audio=<driver>` (BTX `main.swift:308–311`). GUI-subsystem traps (18): stderr through C stdio, the
  log file, never `FileHandle.standardError`/`NSLog`; the live-redraw handler during drag/resize. Start-up: missing
  data → message box (never in `--frames` mode) + `Ferazel's Wand.log` beside the prefs, exit 1; window (14). Headless
  mode for the launch gates and the tests: `--frames N` (N loop iterations of exactly 1/240 s each — N/4 game ticks),
  `--dump f.ppm` (the last presented 640×480), `--keys FILE` (BTX script syntax), in-memory prefs unless `--prefs`,
  dummy SDL drivers forced in-process, **no audio device: the shared silent mixer drains the Sound Tool once per tick**
  (Ruling 20), no pad, and **both clocks pinned** (Ruling 20): the flow's seed = a fixed constant (`--seed N`
  overrides; default = WF1's test seed) instead of `FastRand.clockSeed`, and `dateTime` = a scripted clock (fixed
  start + elapsed ticks / 60) instead of the wall clock — so the same `--frames`/`--keys` run gives the same dump on
  the Mac SDL development build and on Windows, at any time of day (GW4R's and GW6's comparisons rest on this). Stubs: every dialog answers its default (Cancel / OK for reports / prefs unchanged / credits
  closed); file panels answer cancelled.
- **Tests (+19, scripted host, no SDL):** the main-menu RGBA FNV equals WF2's baked-text value (the loop adds nothing);
  240 Hz iterations → one flow step per new 60 Hz tick; right-hand modifiers folded; shortcut table over `MenuState`
  (Ctrl alone takes, Ctrl+Shift / Ctrl+Alt do not; main-menu letters fall through; paused enables Abort; modal blocks
  all; letters read from the MENU resources); a taken shortcut not in the held keys; Alt+Enter eaten; Caps Lock latch;
  pad merge (D37 sample: south = jump in a level, + toggles Caps Lock, − held 1 s = Esc); quit event → `systemQuit` (a
  level running free shows the confirm request next tick); a quit before the flow exists ends at once (exit 0, no
  confirm); cursor rule; `WinFiles` folder from `APPDATA` (set / unset → error message); args (hidden keys incl.
  `-FerazelMute`, `--data`, `--prefs`, `--mute`, a trailing path); **audio driver hint table** (`--mute` → dummy;
  `FERAZEL_MUTE=1` → dummy; `HECTOR_SDL_AUDIO_DRIVER=wasapi` + `--mute` → dummy; neither → none; muted → the beeper
  count 0); start-up missing list; `FerazelMenuRules` table = the Mac's old rules; key script parse; New Game via
  script reaches level 1 with WF2's baked-text level-1 FNV; **`--frames` determinism** (two scripted New Game runs whose
  host wall clocks differ give the same seed, the same `dateTime` readings and the same dump FNV; `--seed N` is the
  seed the flow gets).
- **Acceptance:** GW2 **46/0**; GW3 `0` / `1`; GW4; G5 (FerazelMenus); G2 490/0; GW1; G7/G7W; G6; G10; grep: no
  `FileHandle.standardError` / `NSLog` under `Ferazel/Windows/Sources`; **GW4R** (behind the LAUNCH GUARD; the smoke
  script's Mac half — WF3 writes `tools/windows/smoke-ferazel-win.sh` with only `--mac-only` working, WF6 adds the
  CrossOver half): exit 0, `audio=dummy`, the main-menu dump's FNV = WF2's; by night "boot check owed (night rule)".

### WF5 — Saved games on Windows (Ruling 3, 10)

- **Files:** `Sources/FerazelWin/WinFileDialogs.swift` (`#if os(Windows)`: `GetSaveFileNameW` / `GetOpenFileNameW`,
  `OFN_EXPLORER | OFN_OVERWRITEPROMPT | OFN_PATHMUSTEXIST | OFN_FILEMUSTEXIST (open) | OFN_NOCHANGEDIR`, owner
  `GetActiveWindow()`; Mac SDL build: `--save-as FILE` / `--open FILE` answers, else cancelled);
  `Sources/FerazelWinKit/{WinFileRequests,WinFilePanels}.swift`; `WinGame.swift` (open-document at launch); tests.
- **Contracts:** `WinFileRequests` builds the request from `PutFileRequest` (`ShellRequest.swift:34–44`) / the get
  prompt: title, start folder (Save: created first, as `:579`; Open: only when it exists, never created, as `:598`),
  Windows-legal default name (Ruling 10), "All files (*.*)" filter; the `PutFileRequest.message` line is not shown
  (◇W9); the answer → `GameFlow.fileDone(.chosen(SavedGameRef(url:displayName:)))` or `.cancelled` (`:569–605`); input
  state captured
  before the dialog is flushed after it (no stuck keys). A save-game path given on the command line (Explorer "Open
  with" / a file dropped on the exe) → `GameFlow.openDocument` once the flow exists — the Mac's Finder open (`:678–686`).
- **Tests (+8):** name sanitising table (each illegal char, trailing dot/space, CON, `com3`, empty → the flow's default
  unchanged when legal); request fields from a `PutFileRequest`; Save's start folder created when missing; Open's start
  folder used only when it exists and never created; answer mapping (chosen / cancelled); stuck-key flush; a launch
  path opens the document at the menu pass; a round trip through `WinFiles` with the real codecs (save block written,
  read back equal).
- **Acceptance:** GW2 **54/0**; GW3; GW4; GW1; G2 490/0; G6; G10.

### WF4a — In-window dialogs I: DLOG 202 and 200 (Ruling 4)

- **Files:** `Sources/FerazelWinKit/{DialogRenderer,DialogWindow,DialogSystem}.swift` (adapted from BTXWinKit's three
  files), `WinDialogs.swift` (real implementation for `.confirm` / `.report` / `.error`), the dialog face added to the
  baker as **font 0, face 1, 12 pt** (the bold UI font through `CoreTextRasterizer` — its only route, Ruling 2; the
  stand-in for the Mac's `ClassicFont` pick, `DialogViews.swift:12–13`: Charcoal 12, else Chicago 12, else
  `.boldSystemFont(ofSize: 12)` by `NSFont` name; where the two differ — family, or the width test below — ◇W13 is
  kept and recorded in D43), its `.fzfont`, `Sources/FerazelWin/main.swift` (the `MessageBeep` beeper,
  gated by mute), tests, `Tests/Goldens/Dialog-202.ppm`, `Dialog-200.ppm`.
- **Contracts:** layout from the original DLOG/DITL via Core's R1 template parsers (as `FerazelCarbonDialog` builds
  them), centred over the canvas and drawn into the 640×480 picture (scaled with the game, Ruling 4, ◇W10); `^0`/`^1`
  params (`.error` puts `NumToString(code)` in `^1`) substituted with the pure-Swift replace and MacRoman through
  `HectorResources.MacRoman` — the Mac's `FerazelCarbonDialog.swift:34` (`.macOSRoman`) and `:169–171`
  (`replacingOccurrences`) are exactly the traps of Ruling 18 and must not be copied; OK ring (InsetRect −4, pen 3,
  oval 15); Return/Enter → the default item through **the OK button's 8-tick flash** (hilited, 8 ticks, unhilited, then
  the hit; keys and clicks do nothing while it flashes — `FerazelCarbonDialog.swift:279–291`, `handleKeyDown` `:302`),
  Esc → Cancel on 202; clicks outside the dialog do nothing but beep (the injected beeper: `MessageBeep` on Windows,
  silent on the Mac SDL build, never when muted); pad Return/Esc reach it (Ruling 7); answers → `GameFlow.dialogDone`
  (`showDialog`, `FerazelController.swift:533–556`); the flow does not tick while one is up.
- **Tests (+11):** layout rects from DITL 202/200; params; keyboard answers; the OK flash (8 ticks, then the answer;
  a key or click during the flash ignored); mouse track (press-drag-out-release = nothing); pad answers; outside click
  (beeper called once unmuted, 0 muted); the flow holds still; goldens 202 and 200 (self-derived, shown to Ben on the
  card); dialog-face widths within 1 px of the Mac's `NSFont` measure (Mac-only oracle).
- **Acceptance:** GW2 **65/0**; GW3; GW4; GW1; G2; G6; G10.

### WF4b ⚑ MAJOR — In-window dialogs II: Options (6900) and Credits (600)

- **Files:** `Sources/FerazelWinKit/{WinPrefsDialog,WinCreditsDialog}.swift`, `DialogWindow.swift` (popup, checkbox,
  key-capture items), tests, `Tests/Goldens/Dialog-6900.ppm`.
- **Contracts:** behaviour per `Ferazel/App/Dialogs/PrefsDialogView.swift` over `GameFlow.prefsDialog` (the O1 model:
  every control, key capture with the original's refusals — the A key "already used", the Music checkbox and popup
  acting at once through `MusicCue`s), OK/Cancel → `dialogDone`; Credits per `CreditsDialog.swift` over
  `GameFlow.credits` (`CreditsScroll` timing, PICT under the current clut via `FerazelDriver.dialogPicture`, a click
  closes). Options and Credits take no pad keys (D37).
- **Tests (+12):** every Options control's model effect; key capture accept; key capture refuse ("already used");
  music cues act at once; Cancel restores; OK returns `.ok`; credits scroll position at fixed ticks; credits close on
  click; credits picture under the current clut (`dialogPicture`); golden 6900; the ⌘P path from a level opens it
  (scripted); Options and Credits ignore pad keys (D37).
- **Acceptance:** GW2 **77/0**; GW3; GW4; GW1; G2; G6; G10.

### WF6 — Stage both builds; boot both muted by day; the Windows gate card (phase-end run)

- **Files:** new `tools/windows/stage-ferazel-win.sh` (zsh, adapted from `stage-btx.sh`: committed-content check and
  stamp, release cross-build with `WIN_BUILD_ROOT` (Ruling 19) and its own work/build folders
  (`$WIN_CROSS/work/stage-ferazel`, `$WIN_CROSS/build/stage-ferazel` — never `build/stage`, `work/stage-btx` or
  `build/ferazel`), `/SUBSYSTEM:WINDOWS /ENTRY:mainCRTStartup` with `stage-btx.sh:184–185`'s awk subsystem check,
  `windres` manifest + icon + version info — the icon from `Ferazel/App/AppIcon.icon/Assets/ferazel.png` (512 px)
  resized with `sips` to the `.ico` sizes (there is no `.icns` for `iconutil`), the PE import walk for DLLs, `Data\` =
  `Resources/Ferazel` + `Fonts`, `WHAT-TO-EXPECT.txt` with BOM + CRLF, writes `MANIFEST.txt` (the zip's file list,
  files only, itself excluded), `out/Windows/Ferazel's Wand/` + `out/Windows/Ferazel's Wand (Windows).zip`, files at the
  zip root, Desktop copies unless `--no-desktop`); `tools/windows/smoke-ferazel-win.sh` (WF3's Mac half + the CrossOver
  half: the staged exe in a clean bottle, `HECTOR_SDL_AUDIO_DRIVER=dummy HECTOR_SDL_VIDEO_DRIVER=dummy` and `--mute`,
  a main-menu `--frames A --dump` and a New Game `--frames B --keys` run, each `cmp` against the Mac SDL build's dump
  of the same run; A and B derived from WF1's measured boot-to-menu tick count — `--frames` counts 1/240 s iterations,
  so A = 4 × (that tick count + a 60-tick margin), B likewise to level 1's first frame — never guessed; it refuses
  like Proof B's script); new `Ferazel/WINDOWS-WHAT-TO-EXPECT.md` (the card below); `tools/windows/README.md`;
  `Ferazel/WHAT-TO-EXPECT.md` (one "Windows" pointer line).
- **Contract:** stage both builds: `bash tools/stage-ferazel.sh` (Mac) and `tools/windows/stage-ferazel-win.sh`; then,
  behind the LAUNCH GUARD, **G9M** (the Mac staged app, `-FerazelMute YES`), **GW6** (the staged zip in a clean
  CrossOver bottle, muted) and **GWB** once more — each once, short; by night all three are skipped and LOOP-LOG + the
  card say "boot check owed (night rule)", the first daytime run does them. The Fable phase review over
  `git diff f7fd4ce..HEAD` + the card; fixes; re-stage (re-boot only if the fixes touched what boots); QUESTIONS gate
  card item. Brew `sdl3` on this Mac is **3.4.18**, the Windows pin is **3.4.16** (`tools/windows/env.sh:10` says they
  are equal) — GW6's `cmp` against the Mac SDL dump compares game pictures, which SDL does not draw, so a mismatch is a
  finding, not a version excuse; the README records the difference.
- **Acceptance:** GW5 (exit 0; subsystem `2`; manifest diff empty); GW1–GW4; G1, G2 490/0, G3, G5, G7/G7W, G-MUTE,
  G10; by day G9M (pid line, clean quit, no new crash log), GW6 (`main menu: identical`, `new game: identical`, exit 0),
  GWB 490/0. LOOP-LOG: "Windows staged; booted muted (Mac + CrossOver), Proof B 490/0" — or "staged; boot check owed
  (night rule)".

## Stand-ins kept (◇, named) at the phase's end

| ◇ | What Windows lacks | Why / who replaces it |
|---|---|---|
| ◇W1 | Options' key names from the US layout (`ShellKeyCharacters`), not the live Windows layout | HectorSDL exposes no layout query; an HK task if Ben wants it (WQ5) |
| ◇W2 | The window is resizable (integer-fit on black); the Mac's is fixed | HectorSDL always opens resizable (WQ4) |
| ◇W3 | Native Windows file dialogs where the original had Standard File | Ruling 3 (WQ2) |
| ◇W4 | No About item (Credits is on the main menu); no check marks | D21 |
| ◇W5 | The loop's runs are muted and in CrossOver only: nobody has heard the Windows build or run it on a real PC; a boot skipped by night stays owed until a daytime run | D42 (Ben's ear, Andrew's PC) |
| ◇W6 | Every Mac stand-in of Phase 4 (enemies still, levels 5+ refused, underwater tint, shield crouch face — Phase 5/6) | the Phase 4 card's table; lockstep carries them |
| ◇W7 | No installer, no signing, no file association; SmartScreen "Run anyway" | D19.6, D20/D34 (publishing is Ben's) |
| ◇W8 | Geneva item counts baked as whole strings — only if WF2 found BTX's composition not exact for them | Ruling 2 (recorded in D43 if used) |
| ◇W9 | The Save dialog shows no message line (the Mac panel's `message`, DITL 1003 item 13's text) | `GetSaveFileNameW` has no message area (Ruling 3) |
| ◇W10 | Dialogs drawn inside the game picture and scaled with it (1× glyphs enlarged); the Mac's are separate sharp 1× windows | BTX W6 precedent (Ruling 4, WQ7) |
| ◇W11 | The window has a close button (the Mac's has none); a Windows logoff may meet the quit confirm if SDL reports it as a plain quit | SDL windows always have one; nothing is lost (Ruling 9) |
| ◇W12 | No single-instance guard: a second launch is a second game (the Mac opens a save in the running app) | Ruling 11 |
| ◇W13 | Dialog text in the baked bold UI font (font 0 face 1, via CoreText) — only if it differs from the Mac's `ClassicFont` pick (Charcoal / Chicago by name, else `.boldSystemFont(ofSize: 12)`) | Ruling 2, WF4a (recorded in D43 if kept) |

## The Windows gate card — Ben and Andrew (WF6 writes it as `Ferazel/WINDOWS-WHAT-TO-EXPECT.md` + a QUESTIONS item)

**The loop booted both builds muted, by day (D42):** G9M (Mac staged app), GW6 (the staged zip in a clean CrossOver
bottle) and Proof B — results here; or "boot check owed (night rule)" if the run fell at night, done by the first
daytime run. Nobody has heard it yet. Ben or Andrew, on this Mac (optional, daytime; both scripts force the no-sound
driver and refuse 21:00–09:00):
1. `tools/windows/proof-b-ferazel.sh` → last line `proof-b: 490 passed / 0 failed / 0 skipped / 0 crashed (of 490)`.
2. `tools/windows/smoke-ferazel-win.sh` → `main menu: identical`, `new game: identical`, exit 0.
On a Windows 10/11 PC (or CrossOver), from the unzipped `Ferazel's Wand (Windows)` folder:
3. First launch (SmartScreen: More info → Run anyway): logo, title music, main menu — no console window, no error box.
4. Keyboard: keypad 4/6/8/5 move with Num Lock on **and** off; Shift / Alt / Ctrl act as Shift / Option / ⌘; Caps Lock
   pauses; Esc asks to abort; Ctrl+P opens Options (drawn inside the window); Alt+Enter full screen and back.
5. New Game → level 1 plays as on the Mac: music, effects, the status bar text, a sign's text smoothed like the Mac's.
6. A save point: the Windows Save dialog opens in `%APPDATA%\Ambrosia Classics\Ferazel's Wand\` with the game's name;
   Restore Game (Ctrl+O at the menu, or Continue) opens it again and the level resumes.
7. Options: remap a key, toggle music (acts at once), OK; quit and relaunch — the prefs held.
8. A controller (Xbox / Switch Pro / PlayStation): the Mac's layout (D37), + pauses, − held 1 s = Esc.
9. Close button (new on Windows — the Mac window has none) while a level runs free → "Are you sure you want to quit?"
   (Cancel plays on); at the main menu it quits. Log off with the game running: Windows is not held up for long.
10. `"Ferazel's Wand.exe" -FerazelLevel 3` from a command prompt → New Game starts at level 3.
Pass looks like: the Mac build's behaviour on Windows, sound by ear, dialogs by eye. Notes become a named wave.

## Questions for Ben (non-blocking; the seat copies them to QUESTIONS; execution does not wait — D34)

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
- **WQ7 — dialogs on Windows:** on the Mac the original's dialogs are separate windows with sharp text at their own
  size; on Windows they are drawn inside the game picture. (a) inside the window, enlarged with the game (BTX did the
  same); (b) inside the window but always at the original size, centred; (c) separate windows like the Mac (a
  HectorKit change). **Default (a).** Blocks: nothing.
(WQ1 — may the loop run Proof B — was answered by D42 as amended: yes, muted, by day; withdrawn.)

## Execution order (one loop run each; the cap rule: 2 tasks, 3 when at most one is ⚑)

| run | unit | why this order |
|---|---|---|
| 32 | **WF0, WF1 ⚑** | toolchain first (GWB by day); the shared half + the Mac mute switch before anything uses them (WF1 stays one task — seat ruling on the Fable round — so it runs with WF0 only) |
| 33 | **WF2, WF3 ⚑** | text needs only WF1; the game + the Windows mute switch (GW4R by day) takes WF2's baked-text FNVs as its reference |
| 34 | **WF5, WF4a, WF4b ⚑** | the file dialogs (WF5 needs WF3's executable), the dialog foundation, then the two rich dialogs (three tasks, one ⚑) |
| 35 | **WF6** phase end | stage both, boot both muted by day (G9M, GW6, GWB), Fable phase review, card → QUESTIONS; then the Phase 5 plan (lockstep from its first task) |

A run that reaches a launch gate between 21:00 and 09:00 skips it, finishes everything else, writes "boot check owed
(night rule)", and NEXT carries the owed gate to the first daytime run, which does it before its own tasks.

## Orchestration notes

- **Toolchain:** installed at `~/Developer/Toolchains/windows-cross/` (Swift 6.4.0, SDL3 3.4.16, winsysroot, runtime
  DLLs); brew `sdl3` is on the Mac for GW4; `x86_64-w64-mingw32-windres` (brew `mingw-w64`, needed by the stage
  script as by `stage-btx.sh:96–97`) is at `/opt/homebrew/bin` (checked 2026-10-26). Brew `sdl3` is 3.4.18, the
  Windows pin 3.4.16 (`env.sh:10` claims equal — the README is corrected in WF6). **No installs** (NEXT
  AUTHORIZATIONS): if a tool has gone missing, stage with `--no-icon` where possible and record it in QUESTIONS.
- **Build roots:** always `WIN_BUILD_ROOT=…/build/ferazel` (seat, implementers) and a `mktemp` root for reviewers;
  leg A measured GW1 at ~19 s (2026-10-26); GW3 adds the SDL package — expect minutes cold, not hours. Run gates in
  the foreground (no background agents in loop runs).
- **HectorKit path:** `Ferazel/Windows/Package.swift` reaches HectorKit at `../../../HectorKit` (in a worktree:
  `.claude/worktrees/HectorKit` → `~/Developer/HectorKit`); never create a self-link (runs 28/29 lesson). HK must stay
  35a85ba (G1).
- **Symlinks:** create with `ln -s ../../../Shared/X.swift` inside `FerazelWinKit/` and `git add` them; check mode
  120000 (GW-symlinks). They break in a Git-for-Windows checkout with `core.symlinks=false` — the README says so (BTX
  precedent); every build here is on the Mac.
- **Run what you build only through a launch gate (D42):** `FerazelWin`, the test `.exe` and `run-in-crossover.sh`
  run only inside `proof-b-ferazel.sh` / `smoke-ferazel-win.sh` (which refuse without the no-sound driver and outside
  09..20), the staged Mac app only through G9M with `-FerazelMute YES`; never `swift run`, never an ad-hoc launch,
  never a launch to "just look". Few and short: Proof B once whole, per class only after a crash. `swift test` of
  FerazelWinKit runs at any hour: its tests use a scripted host and a fake or silent mixer, open no window and no audio
  device — a test that would touch SDL or audio is a review failure.
- **Mac app safety:** WF1, WF2, WF3 touch `Ferazel/App` / `project.yml`; G5 every time; Ben may be playing the staged
  Phase 4 build — the staged `~/Desktop` app is replaced only in WF6.
- **Reviews:** two Opus legs on WF1, WF3, WF4b; one on the others; the phase-end Fable leg in run 35 (D34). The plan
  itself: two Opus legs (one against BTX's Windows code + `tools/windows/`, one against Ferazel's App + design +
  rulings), then one FABLE-GRADE leg, before run 32 (NEXT.md).
- **Carries into Phase 5:** Ruling 16 verbatim in its preamble; its Files lists name the Windows side.

## Review record

| step | what | result |
|---|---|---|
| draft | f00efc4 | — |
| Opus leg A | against BTX's Windows code + `tools/windows/` | PASS WITH FIXES |
| Opus leg B | against Ferazel's App + design + rulings | PASS WITH FIXES |
| fixes | 5bfc50a (both legs' findings, plus Ben's Q12 as amended → D42) | applied |
| FABLE-GRADE gate | G2 490/0; GW1 exit 1 at `FerazelDataTests.swift:41,43,44` as predicted; 7 findings | PASS WITH FIXES |
| Fable round | this commit: headless dumps pin the seed and `dateTime` (Ruling 20, WF1, WF3 + a test, ladder +1 from WF3 on); Proof B's `WIN_RUN_TIMEOUT=3600` + measured time (WF0); runs re-cut 32 = WF0 + WF1, 33 = WF2 + WF3, 34 = WF5 + WF4a + WF4b, 35 = WF6 (WF1 kept one task, seat); `CoreTextRasterizer` made `public` for the baker (WF2); dialog face = font 0 face 1 (Rulings 2/4, WF4a, ◇W13); silent-mixer drain 367/368 accumulated (Ruling 20, WF1 test); `SetEnvironmentVariableW` fallback (WF0) | applied |
