# Deimos Rising — from today to the release — implementation plan (2026-11-24)

> **This file is the authority for all remaining Deimos Rising work; every earlier Deimos plan is history.**
> The design it builds is `docs/superpowers/specs/2026-11-05-deimos-remainder-design.md` (sections "What is being
> built" and "The shape of the whole program"). Live numbers are in `docs/STATE.md`, "Deimos Rising".
>
> House method: `~/Developer/Toolkits/fable-kit/orchestrator.md`. Per task: one `fk-implementer`, then two
> `fk-reviewer` legs (spec, then quality, each checking the other), no `model` parameter (both agents pin Opus 5.5).
> The seat (Fable unless a section says otherwise) reviews nothing per task; its one cross-check is at each phase
> end, over the phase's whole change and its gate card, before staging. Contracts here, not code.
>
> **Nothing in this plan starts until Ben approves it.** No session chains into a build from the planning session.

**Goal:** Deimos Rising finished and public: the Mac app and a Windows build, both the whole game as 1.0.6 played on
Mac OS X, released as `deimos-1.0` (notarized Mac DMG, Windows zip), with every open research item ruled closed.

## Where the game stands (the seat's reading, 2026-11-24)

Built, merged and staged as one Mac app: data loading, the look, the gameplay, the twelve-sector campaign with one or
two players and the finale, and the whole front end (boot, menu, level select, scores, name entry, demos, Last Film,
credits, both settings windows, a controller, quit with save). A keyboard fault Ben found on his first play (another
app's shortcut stole the keyboard in full screen) is fixed and restaged.

| Check | Today |
|---|---|
| `Deimos/Core` tests, without the replay and campaign bundles | 511 passed, 0 failed, 0 skipped |
| Replay tests; the four demo films | 4 / 0; four PASS lines |
| Campaign tests | 3 / 0 |
| The shared library (HectorKit) | 370 tests run, none failed |

## What stands between today and "done"

| # | What | Why it is on the list | Phase |
|---|---|---|---|
| 1 | Ben's play gates 2 (level 1 plays), 3 (the campaign), 4 (the front end), and his replay of the keyboard fix | never yet judged; his notes become fixes | 5 |
| 2 | Eight known faults and untested paths the Phase 4 closing review found | found, not fixed | 5 |
| 3 | Four things the OS X build does that the port does not: the pause when you leave the app, the cursor during a pause, the Preferences… menu item, the Edit menu | the game is to match the original; these are known gaps on the gate card | 5 |
| 4 | Small code and test follow-ups carried since Phases 2–4 | each is a line in STATE | 5 |
| 5 | Winning sector 12 by destroying the end boss has never been run by a machine | the campaign test outlasts the boss on a timer instead | 5 |
| 6 | Records that are now wrong (research notes, comments, two handoffs), and tidying the committed decompile files | the next reader is misled; a public repo carries home-folder paths | 5 |
| 7 | The whole-game comparison of the OS 9 build (what the research describes) with the OS X build (what Ben played) | Ben: "Yes, after Phase 4". Only the front end has been compared | 6 |
| 8 | The research notes' open items, and 134 places where two research files rate one fact differently | a finished project has none open | 6 |
| 9 | The Windows build | Ben's ruling of 2026-10-06: done = the whole game, Mac and Windows | 7 |
| 10 | The app icon in the current macOS style | every public build has one (Aki, Bubble Trouble X) | 8 |
| 11 | The public release | notarized DMG, Windows zip, copies kept, README | 8 |

**Dropped, and why.** The level editor, registration, the website link's browser dialog, the original's own gamepad
windows and its HID bundle (the seat's ruling, on the gate card for Ben to overturn), the debug-only console commands, an iPad build and remastered art stay out (the design's
scope; Ben's answers of 2026-11-20). A second controller for player 2 stays out (it needs a HectorKit change Ben has
not asked for). "Attract mode" is not owed: the original starts no demo by itself. The research items #14, #62 and
#64 are already closed. A game started above sector 1 having no finale is the original's rule, not a gap.

## Phases at a glance

| Phase | Name | Sessions (estimate) | Needs Ben | Ends with |
|---|---|---|---|---|
| 5 | Loose ends on the Mac | 3, plus the fix wave his notes need | his three gates and the keyboard replay | a restaged app; gates 2–4 closed |
| 6 | The two builds compared | 2 research and ruling, plus 1–2 if play differs | nothing to start; he reads the result | a restaged app if anything changed, with a card of what changed |
| 7 | Windows | 4 | a tester on a real PC | both builds staged; the Windows gate |
| 8 | Release | 2 | the icon pick; trying the downloaded build; "publish" | `deimos-1.0` public |

**Order.** Phase 5's tasks other than the gate-notes slot, and Phase 6's research, do not wait for Ben's play.
Tasks that share a file run one after another, in this order: 5-QF → 5-SM → 5-BK → 5-PS → 5-DOC (its comment edits
land after the code tasks that touch the same files) → 6-CMP (it needs the files 5-DOC commits). 5-BK touches
only the campaign tests and may run beside any of them. 5-GN's cards and 6-FX's cards run one after another when
they share a file. Phase 6's fixes land before Phase 7's second task, so Windows is built on settled rules;
Phase 7's first task (the cross-build proof) starts after 5-PS. Phase 8 starts only when gates
2, 3 and 4 and the Windows gate are closed. A session is one orchestrator seat, cap 300k of its own context, sized
to close near 240k; it reads the meter with `get_usage` before every dispatch and says the figure.

**Lockstep, from the day the Windows build exists:** every later task that changes what the Mac app shows or does
carries its Windows side in the same task, and every phase end stages both builds with one card.

---

## Verification model (read first)

| Rule | What it means here |
|---|---|
| Machine gates close alone; Ben closes the honesty gate | "done" is always "machine gates green; Ben's gate pending" until he has played |
| Numbers from your own run | the seat re-runs the count at the merge head; a helper's figure is never relayed |
| Reviewers run things | each review leg runs the task's tests on its own scratch build folder and re-derives two or three rules from the dump or listing; reading the diff alone is not a review |
| Diagnosis before dispatch, to file and line | "investigate and fix" is never a helper's task; a gate note is traced to a cause by the seat first |
| STOP on any unexpected number | report it; never edit an expectation. A card that changes play on purpose (5-GN, 6-FX) lists, before dispatch, the pinned values it expects to move; only an unlisted move is a STOP. A demo film that stops matching follows the film rule under Phase 6 |
| Scope fence | changed paths are a subset of the task's Files; an extra file is scope creep until shown to be a call site |
| Explicit-path commits | never `git add -A`, never a bare `git stash`; the helper's trailer on every commit |
| Bounded tests | every loop names a bound and fails on reaching it |
| No launches, no sound | no task launches an app or plays sound. The one boot check per stage is muted, never between 21:00 and 09:00, with Ben's say-so |
| Disk | every helper deletes its scratch build folders, copies and snapshots when its check has passed; a retired worktree's Xcode DerivedData folder goes with it |
| Heavy processes | at most four on the machine in total (`swift-test`, `swift-build`, `xcodebuild`, a CrossOver run); at most two per section |

### Gates

| # | Gate | Expected |
|---|---|---|
| G1 | HectorKit zero-skip at kit main | the kit's figure that day (370 executed on `ef2c341`, of which 4 are the Aki 1.1 data skips); recorded, never "fixed" here |
| G2 | `Deimos/Core` without the replay and campaign bundles | main's count when the task merges plus the task's delta; 0 failed, 0 skipped. Base **511** |
| G3 | the census file's body unchanged | empty diff |
| G4 | `DeimosReplayTests`; `deimos-replay --all` | **4 / 0** (5 / 0 after task 5-SM); four `PASS` lines, exit 0 |
| G5 | Deimos builds, Debug and Release; when `project.yml` or HectorKit changed, also Aki, AkiPad, BubbleTroubleX and Ferazel | `** BUILD SUCCEEDED **` |
| G6 | scope fence | changed paths within the task's Files |
| G7 | layering | the grep prints nothing |
| G8 | `DeimosCampaignTests`, one test at a time | **3 / 0** (4 / 0 after task 5-BK); at phase ends and where a card says |
| G9 | the staged app boots (stage tasks only; muted, daytime, Ben's say-so) | a pid; a clean quit; no new crash report |
| G10 | clean tree | nothing but untracked files |
| G12 | the direct start | `--filter "DeimosHostTests.DriverTests/testDirectStartMatchesBareSession"` passes |
| GW1 | Core and its tests cross-build for Windows (from 7-W0) | the build ends without error |
| GW2 | `DeimosWinKit` tests on the Mac (from 7-W1) | the ladder in Phase 7; 0 failed |
| GW3 | `DeimosWin` cross-builds (from 7-W2) | the build ends without error |
| GWB | Proof B: the Core suite run in CrossOver, muted (phase ends from 7 on) | every test passed or skipped by name; 0 failed, 0 crashed |

```sh
WT=<your worktree>; S=<your scratchpad>; C="$WT/Deimos/Core"
# G1
HECTORKIT_TEST_LOG="$S/hk.log" HECTORKIT_DATA_AKI11="$WT/Resources/Aki/1.1.0.app/Contents/Resources" /Users/andiyar/Developer/HectorKit/tools/check-zero-skip.sh 2>&1 | /usr/bin/tail -n 1
# G2
cd "$C" && swift test --scratch-path "$S/build-<task>" --skip DeimosReplayTests --skip DeimosCampaignTests > "$S/g2.log" 2>&1
/usr/bin/grep -cE "^Test Case '.*' (passed|failed|skipped) \(" "$S/g2.log"; /usr/bin/grep -cE "^Test Case '.*' (failed|skipped) \(" "$S/g2.log"
# G3
git -C "$WT" diff --stat "$(git -C "$WT" merge-base HEAD main)" -- docs/deimos/data-census.md
# G4
cd "$C" && swift test --scratch-path "$S/build-replay" --filter DeimosReplayTests > "$S/g4.log" 2>&1
/usr/bin/grep -cE "^Test Case '.*' passed \(" "$S/g4.log"; swift run --scratch-path "$S/build-replay" deimos-replay --all | /usr/bin/tail -n 4
# G5
cd "$WT" && xcodegen generate && for c in Debug Release; do xcodebuild -scheme Deimos -configuration "$c" -derivedDataPath "$S/dd" build 2>&1 | /usr/bin/tail -n 1; done
# G7
/usr/bin/grep -rnE "^import (AppKit|UIKit|SwiftUI|CoreGraphics|CoreText|ImageIO|AVFoundation|QuartzCore|HectorGraphics|HectorShell)" "$C/Sources/DeimosCore" "$C/Sources/DeimosRender" "$C/Sources/DeimosHost" "$C/Sources/DeimosAudio" "$C/Sources/deimos-replay"
# G8  (one test per command; count "passed (" anywhere on a line: the longest test's line lands mid-line)
cd "$C" && swift test --scratch-path "$S/build-camp" --filter "DeimosCampaignTests/<test name>" > "$S/g8-<n>.log" 2>&1; /usr/bin/grep -cE "Test Case '.*' passed \(" "$S/g8-<n>.log"
# G10
git -C "$WT" status --porcelain | /usr/bin/grep -v '^??'
```

**What no machine check proves:** how any screen looks; the feel of fades and waits; pitch direction and the music
level against the effects; a real controller in the hand; that the full-screen keyboard reclaim wins on real
hardware; the settings file against one the original wrote (none exists); anything on a real Windows PC.

### Standing rules for every implementer

1. **Layering.** `DeimosCore`: Foundation, HectorResources, HectorAudio, HectorInput (itself Foundation-only). `DeimosRender`: Foundation, DeimosCore.
   `DeimosAudio`: those plus Synchronization. `DeimosHost`: Foundation and the three. Only `Deimos/App`, and from
   Phase 7 `Deimos/Shared` and `Deimos/Windows`, may import HectorGraphics, HectorShell or HectorSDL. Windows traps,
   in every layer below the shells and in `Deimos/Shared`: no `String.Encoding.macOSRoman`, no `UserDefaults`, no `replacingOccurrences`, no
   Foundation `String.contains` on a hot path (it traps under Wine), no writes to stderr in a GUI build.
2. **Transcribe, don't reinvent.** Every behaviour cites its listing address or bank section. Where the bank and a
   listing disagree, the listing wins: STOP and report. Where the OS 9 and OS X builds differ, build what the OS X
   build does in the front end (Ben played it), and in the game as Phase 6 rules row by row (the film rule); read `docs/deimos/osx-build.md` and, once Phase 6 has written it, `osx-build-game.md`.
3. **No modern affordances.** Nothing the original did not have, except the hidden switches that already exist
   (`-film deNN`, `-mute`, `-keylog`) and the controller.
4. **Data in git; tests never skip.** A missing file is a failure that names the path.
5. **Every random draw at its original site, in the original order,** even when its result is thrown away.
6. **Float fidelity.** `Float` where the listing uses single-precision instructions; fused multiply-adds stay fused;
   float-to-int truncates toward zero; tests pin floats by bit pattern.
7. **Seams grow by addition only.** Adding a case updates every exhaustive switch in the same commit.
8. **`GameState` storage rule.** Rule methods take indices and re-read after any call that may change the world; no
   `inout Entity` or `inout Player` is held across a `GameState` call.
9. **Landmines.** `swift test` prints no package total: count `Test Case` lines. Quote every path. `grep` and `tail`
   may be shell functions: use `/usr/bin/grep`; there is no `timeout` binary. Never write an unquoted word starting
   with `=` in a shell call. Confirm a new DECISIONS number against `main` at commit. The app's settings domain
   `com.ambrosiaclassics.deimos` and its Application Support folder hold Ben's play: never clear them.
10. **Where the oracles are.** OS 9 build: C dump `ghidra/deimos/Deimos_pef.decompiled.c`; listing
    `~/Developer/Ghidra/deimos/proj/disasm-review3-all.txt` (committed under `ghidra/deimos/` by task 5-DOC). OS X
    build: `ghidra/deimos/Deimos_osx.disasm.txt`, `.functions.txt`, `.data.txt`. Decoded unit files:
    `~/Developer/Ghidra/deimos/proj/data/Game/unde/`. Static initialisers rewrite templates before `main`: use
    runtime values (the draw template's clip is {0, 0, 480, 416}; spawn-request templates carry −1 at +0x24).

Path shorthand: `Core/` = `Deimos/Core/Sources/DeimosCore/`, `Host/` = `Deimos/Core/Sources/DeimosHost/`,
`FE/` = `Core/FrontEnd/`, `T/` = `Deimos/Core/Tests/`, `App/` = `Deimos/App/`.

---

## Phase 5 — loose ends on the Mac

Three sections that need nothing from Ben (5B, 5C, then 5A), then the slot for his notes (5D) and the stage
(5E). The running order is in "Order" above; no two of these sections run at once, except 5-BK.

### Section 5A — records and housekeeping (docs only; an Opus seat may hold it)

- **5-DOC — the records put right** (no tests; G3, G5, G6, G10). **Files:** `docs/deimos/INDEX.md`,
  `docs/deimos/front-end.md`, `docs/deimos/display-window-present.md`, `docs/handoff-deimos-phase4-s6.md`,
  `docs/handoff-deimos-phase4-s8a.md`, `ghidra/deimos/*`, `ghidra/README.md`, `docs/deimos/*.md` (paths only), the earlier Deimos plans (one header
  line each), comment-only edits in
  `App/DeimosController.swift`, `FE/SessionResult.swift`, `Core/Seams/ShellRequest.swift`, `FE/Credits.swift`,
  `FE/Boot.swift`, `Core/Game/DeimosPrefs.swift`, `Core/Game/ScrollState.swift`,
  `Core/Combat/Removal.swift`.
  **Contract:** (a) the bank says the level select's right-hand preview never draws its hover outline; the listing
  gives that draw the full 640×480 clip and the port draws it: correct INDEX item 59 and close it. (b) The bank's
  credits text still has a blank last page; the data has ten pages and no blank one. (c) The bank gives element
  fades 32 steps with no note that the OS X build takes 16. (d) "Full Screen does nothing" is true of the OS 9 build
  only. (e) The two handoffs and the controller file's header give the start-up order backwards: it is publisher's
  logo, developer's logo, loading lines, menu. (f) Stale comments: the pause-quit result "never set"; About
  "disabled during a game"; a Quit during the credits "acts when they end"; "every unit name is shown"; the key-slot
  meanings marked low confidence (they are settled: fire air, fire ground, select); `ScrollState.step`'s "Phase 2";
  the stale one in `Removal.swift` (the comment the Phase 3 close listed). (g) Commit the OS 9 listing **and its data image** (`~/Developer/Ghidra/deimos/proj/mem/100de330.bin`)
  under `ghidra/deimos/` and name both in `ghidra/README.md`; replace home-folder paths with `~` in the OS 9
  analysis log `ghidra/deimos/analyze-Deimos_pef.log` and in the twelve bank files under `docs/deimos/` that name
  `/Users/andiyar` (other games' logs are a repo-wide chore, listed in the handoff, not done here); correct the
  Ghidra version `ghidra/README.md` names to the one the logs record. (h) Each earlier Deimos plan (`docs/plans/2026-10-0*-deimos-*.md`,
  `docs/superpowers/plans/2026-11-14-deimos-phase3.md`) gets the one-line "Superseded by" header if it lacks one. Every corrected bank line is a dated ⚑ note with its address, the bank's own append rule.
  **Done:** each of (a)–(h) shown by a grep in the report; two review legs split the list between them and check
  every note against the listing.

### Section 5B — known faults and small follow-ups

- **5-QF — the closing review's faults** (+6 → **517**). **Files:** `FE/LevelSelect.swift`, `FE/Scores.swift`,
  `FE/MainMenu.swift`, `FE/Boot.swift`, `FE/ControlsDialog.swift`, `FE/ConfigDialog.swift`, `FE/FrontEnd.swift`,
  `App/DeimosController.swift`, `Core/Input/DeimosPadLayout.swift`, `Host/ShellGlue.swift`, `Host/DeimosDriver.swift`,
  `Deimos/Core/Sources/DeimosAudio/DeimosAudioEngine.swift`, `Deimos/GAMEPAD.md`, `Deimos/WHAT-TO-EXPECT.md`, their test files under `T/`.
  **Contract:**
  1. *Command-Q on the level select.* Today a remembered "quit" is never cleared when a game starts, so the next
     game earns no score, the first pause quits, and the app quits back at the menu. First re-read the OS X level
     select and game start (the quit flag's every reader and writer) to HIGH confidence; build exactly what it
     shows. If the re-read confirms today's behaviour, the code stays and the gate card says in plain words that
     the game will not score (Ben may overturn: question 3). Test:
     `testQuitOnLevelSelectThenStart` pins whichever is read.
  2. *A macOS quit or log-out while paused on the level select with the app in the background* quits at once, as
     the card already promises for every pause. Test: `testBackgroundQuitDuringLevelSelectPause`.
  3. *The start-up cannot hang.* The publisher's logo waits for its sound to end. If the sound output is lost
     during it, the audio engine reports the loss and the driver ends its wait-for-the-sound on that report (the seat's ruling: a port hazard the original could not meet; nothing changes while
     sound works). Command-Q during the boot stays ignored, as the original, unless Ben answers
     otherwise (question 9). Test:
     `testLogoWaitEndsWhenOutputIsLost`.
  4. *The hollow test.* "A screen reached in the middle of a pass sees none of that pass's queued input" must fail
     when the rule is broken: re-specify it under its existing name (no count change) against the real level select, and show
     the mutant failing in the report. In the same test file, check end to end against the real menu → credits and
     menu → scores chains which screen gets the input on a pass where a screen that draws nothing finishes, and pin
     it in the existing test for that rule.
  5. *About on the scores screen.* Read what the OS X scores screen does with the About command and build that.
     Test: `testScoresScreenAbout`.
  6. *Two untested paths:* Save in the controls window then Cancel in the settings window
     (`testControlsSaveThenConfigCancel`); binding two keys that have no name in the original's key list
     (`testUnnamedKeysMayDuplicate`, as the OS X build allows).
  7. *The background-quit flags.* A macOS quit while the app is in the background at the menu leaves both
     "suspended" flags set on the way out; clear them as the resume path does, and hand the existing test its
     events in the order the app really produces (re-specified under its name).
  8. *The controller's paused layout.* It never switches on, because the pause clears its flag before the app
     looks. Default (question 4): the pad behaves as the keyboard does (held buttons act when the pause ends); remove the dead
     layout, re-specify the one test that pins behaviour the app never reaches, and correct `Deimos/GAMEPAD.md`
     and the card. If Ben answers that held buttons should do nothing on resume, build that instead.
  **Done:** the six new tests pass; items 4, 7 and 8 show their re-specified tests failing on a mutant.
  **Gate:** G2 = 517, G4, G5, G7, G12.

- **5-SM — small follow-ups** ⚑ MAJOR (+6 → **523**; replay bundle 4 → **5**). **Files:** `Host/HeadlessRunner.swift`,
  `Host/FilmLookup.swift` (moved to `Core/FilmLookup.swift`), `Host/ShellGlue.swift`,
  `Deimos/Core/Sources/deimos-replay/main.swift`, `FE/LevelSelect.swift`, `FE/ControlsDialog.swift`,
  `Core/Game/PrefsFile.swift`, `FE/ElementList.swift`, `FE/NameEntry.swift`,
  `Deimos/Core/Sources/DeimosAudio/DeimosAudioEngine.swift`, `Core/Effects/MotionBlurPool.swift`, `FE/MainMenu.swift`, `FE/Boot.swift`,
  `Host/PrefsStore.swift`, `FE/FrontEnd.swift`, `App/DeimosController.swift`, tests under `T/`.
  **Contract:** (1) a failed `--frames` write no longer hides a film's result line (`testFramesWriteFailureKeepsResult`, in the replay bundle, the only one that can reach the tool: G4 becomes 5 / 0);
  (2) `HeadlessRunner` returns a named error, not a trap, on an end no rule explains
  (`testUnexplainedEndIsAnError`); (3) the four private film lookups inside the core test bundle use the shared
  lookup, which moves from the host layer into `DeimosCore` so the core tests can reach it (no count change); (4) `MotionBlurPool.emit` — read the listing for the field at +0x90 and copy it or not
  as read (`testBlurCopiesStampTime` either way); (5) a key with no character: read what the OS X key reader sends; the fix and its test land in 7-W1, where
  the key reader first becomes reachable by a test; (6) the background pump's bound is named and `testBackgroundQuitPumpStops` is re-specified to fail on reaching it
  (no count change);
  (7) the logo sound stops on a quit during the boot, if the listing stops it (`testQuitDuringBootStopsLogoSound`
  pins what is read); (8) an unreadable settings file starts fresh without a crash
  (`testUnreadableSettingsFileStartsFresh`); (9) the menu loads its background into a buffer sized as the listing
  sizes it (read first; a mismatch is fixed with the existing menu tests re-pinned, no new test); (10) the pressed 1 PLAYER / 2 PLAYER button is lit for the
  passes the listing gives on the way back (re-pin the existing test); (11) delete
  `FrontEndState.recordedFilmForTests`; (12) the closing review's smallest items, each read against the OS X
  listing and built as read, pinned by re-specifying the nearest existing test unless a number is given: key codes
  from 0x80 up are stored in the settings file at the width the original stores them; the controls window's
  slot-count guard is restored; a negative blend in a fade is an error, not a trap; the level select's three
  silent fallbacks become named errors; the held-arrow and auto-repeat paths in name entry get one test
  (`testNameEntryAutoRepeat`); the audio engine's fading flag and stop-with-fade get one
  (`testMusicFadeFlagAndStop`, in the audio tests).
  **Done:** each of (1)–(12) shown by its test or by the listing address that says "already right".
  **Gate:** G2 = 523, G4 = 5 / 0, G5, G7, G12.

- **5-BK — the end boss, beaten** (campaign bundle 3 → **4**). **Files:** `T/DeimosCampaignTests/*`.
  **Contract:** a bounded headless run of sector 12 inside a game begun at sector 1 (the finale's condition: sector 12 must count as the
  twelfth level started; the test sets that count and builds the carried player state — weapons, lives — itself,
  saying in a comment what it built, and does not replay sectors 1–11), bounded at 20,000 passes, that
  destroys the end boss (unit `be02`, which the sector-12 controller waits on; `docs/deimos/bosses.md` and
  `loose-ends-session.md`, "the finale") and reaches the finale through the kill, not through the controller's
  timer. The run may switch on the game's own invulnerability cheat through the console, as a player could
  (`messages-notices-console.md`, "The cheat word"); it says so in its name: `testSector12WonByDestroyingTheBoss`.
  It asserts the kill tick, the chain of finale groups in order, the tally wait and the mission bonus.
  **Gate:** G8 = 4 / 0. If the boss cannot be destroyed inside the bound, STOP: that is a finding, not a test to weaken.

### Section 5C — what the OS X build does that the port does not

- **5-PS — ⚑ MAJOR — the pause on leaving the app, the cursor, the menu bar** (+9 → **532**). **Files:**
  `Core/Game/FrameKeys.swift`, `Core/Game/DeimosSession.swift`, `FE/FrontEnd.swift`, `FE/LevelSelect.swift`,
  `FE/MainMenu.swift`, `Core/Seams/*` (additions only), `Host/DeimosDriver.swift`, `Host/HeadlessRunner.swift`,
  `Deimos/Core/Sources/DeimosRender/DeimosRenderer.swift` (switch arms only), `App/DeimosController.swift`,
  `Deimos/WHAT-TO-EXPECT.md`, tests under `T/`.
  **Read first:** `docs/deimos/osx-build.md`, "Differences": the items "The pause and the level select listen for
  app switching and Quit", "Leaving the app pauses the game", "The pause shows the cursor during a game", "Films
  keep the cursor, until an app switch", "The menu bar is built once, and differently", "Preferences… in the
  application menu opens the configuration dialog"; then the OS X listing at the addresses those items give.
  **Contract:** (1) leaving the app during a game enters the game's own pause, with the pause screen and sound the
  frame controller's paused-frame hook gives (today the game is only held still); coming back ends that pause on
  the next idle pass unless Caps Lock is on, as the OS X build does. A macOS quit that arrives while the game is
  paused in the background goes through the pause: the game ends with no high score and the app quits (today it
  waits for the player's return). The level select does what the OS X build does: its own per-frame pump takes the
  switch (music paused, no pause screen); the pause screen opens only if the switch arrives after the pump and
  before the frame's check. Whether entering the pause drops the waiting suspend event (and so whether the music
  pauses) is built as read; if the listing cannot settle it, the suspend still runs (the seat's ruling, on the
  card). A demo cannot take the Caps Lock pause, but an app switch during a demo opens the
  pause as in a game. (2) The cursor is shown while a game is paused and hidden again on resume; a demo keeps the
  cursor until an app switch, shows it while away, and hides it for the rest of that film on return. (3) The application menu gains Preferences… (Command-comma), which
  runs the menu's PREFERENCES action and does on every other screen what the listing shows (including nothing).
  In the OS X build the menu bar is seen only in a window; in full screen it is hidden, and whether Command-comma
  still acts there is read from the listing first and built as read (if the listing cannot settle it: it acts, the
  seat's ruling, said on the card). (4) The Edit menu is present with the items the OS X build's menu resource
  lists, each inert or live as read. (5) "Set Gamepad Controls…" stays hidden and the original's gamepad windows
  stay unbuilt (the seat's ruling of 2026-11-20, on the card for Ben to overturn).
  **Tests (9):** `testLeavingAppEntersPause` · `testReturnEndsPauseUnlessCapsLock` ·
  `testBackgroundQuitDuringGameQuitsViaPause` · `testLevelSelectSuspendOnLeave` · `testDemoOnAppSwitch` ·
  `testCursorShownWhilePaused` · `testDemoKeepsCursorUntilSwitch` · `testPreferencesCommandOpensConfig` ·
  `testPreferencesCommandElsewhere`.
  **Done:** the nine tests pass; the card's lines for the pause, the cursor and the menu bar are rewritten.
  **Gate:** G2 = 532, G4, G5, G7, G8 (the pause path is in every game), G12. Any of the eight front-end goldens
  that moves is a STOP unless the card above explains it.

### Section 5D — the slot for Ben's notes (content unknown until he plays)

Opens when Ben has played the staged app and written notes for any of gates 2, 3, 4 or the keyboard replay.

- **5-GN — the fix wave.** The seat reads his notes word for word and turns each into one row: what he saw, on
  which screen or sector; the cause traced to a file and line and to a listing address (or "the port matches the
  listing: the original did this too", shown with the address); the fix; the test that will pin it. Rows that are
  his choices rather than faults (the card's numbered rulings he wants changed; the controller's button mapping, which
  he said may need work; his four named gate-3 questions:
  the flip pitch, sector 12 ending with the boss alive, his own overload while invulnerable, player 2's keys) are
  built as he says. **The rows are written into this section of this file as task cards before any dispatch**, each
  with Files, Contract, Tests, the pinned values it expects to move, and its gates (G2 continuing the ladder from
  the count then on main, G4, G5, G7, G12, and G8 for every card that changes play). One review leg reads the card
  set against its evidence before the first dispatch. One implementer
  and two review legs per card; cards on the same file run one after another. More than eight cards is a second
  section. A note no one can trace is not guessed at: the seat asks Ben for the keys he pressed or a screen
  recording, and the hidden key log (`-keylog`) exists for exactly that.
- If his keyboard replay shows the full-screen reclaim does not hold, that is the first card, and moving the reclaim
  into HectorKit (so Aki and Bubble Trouble X get it) is offered to him as its own task, not done here.

### Section 5E — stage and gate

- **5-ST — restage, the card, the cross-check.** **Files:** `Deimos/WHAT-TO-EXPECT.md`, `Deimos/GAMEPAD.md`,
  `docs/STATE.md`, `docs/DECISIONS.md`, a handoff. Run G1–G5, G7, G8, G10, G12 at the merge head. The seat's one
  cross-check reads the phase's whole change and the card. Then `tools/stage-deimos.sh` (the app and its card to
  the worktree's `out/Deimos/` and the Desktop), then a copy of `out/Deimos/` to the main checkout's `out/Deimos/`. The card, in Ben's plain English: what changed since the
  app he last played, one line each; what is new to try (leave the app mid-game, Preferences…, the cursor in a pause); every seat ruling for him to overturn; what no machine could prove.
  **STOP for Ben.** Phase 5 closes when he has passed gates 2, 3 and 4, or passed them with notes that 5-GN has
  built and he has seen.

**Gate card for Phase 5** (the 5-ST implementer may tighten the wording, not the content):
1. Play level 1: does it play like Deimos? (gate 2, unchanged from the card on the Desktop today)
2. Play on through the sectors, one and two players: does the campaign play like Deimos? (gate 3)
3. Cold start to the menu, a game, the scores, quit and reopen: does the front end work like Deimos? (gate 4)
4. Bombs in full screen: do the arrow keys keep working? (the keyboard fix)
5. New since last time: switch to another app in the middle of a game — the game freezes with its Paused sound
   and the cursor shows; come back and it carries on (with Caps Lock on it stays paused). In a window (untick Full
   Screen in the settings, relaunch) the menu bar has Preferences… and an Edit menu; in full screen try
   Command-comma.
6. Anything from your earlier notes: each is listed with what was changed.

---

## Phase 6 — the two builds compared

The app file holds two complete games: the Mac OS 9 build, which all the research describes, and the Mac OS X
build, which Ben played. An earlier pass paired 955 of the OS 9 build's 979 functions with their OS X partners and
found 906 identical instruction for instruction; it then read only the front-end ones. This phase reads the rest.

**The rule the seat sets (Ben may overturn: question 5):** where the two builds differ
in what the player sees, hears or can do, the port follows the OS X build, in the game as it already does in the
front end. **The film rule:** the four demo films are the proof of the game's rules. A change made to follow the
OS X build lands only if all four films still replay to their stored scores. A film checks only its final score,
so each card also shows that the changed function runs in at least one film (a call count) and compares the
replay trace before and after; if no film reaches the function, the campaign run (G8) is the witness. If a film
stops matching, it is first traced to its first diverging pass and both review legs re-check the transcription
against the OS X listing. Only then does the port keep the OS 9 rule for that one function — recorded in the
comparison file as a departure from what Ben played — and the item goes to Ben as a question that blocks nothing.

### Section 6A — the comparison (research; an Opus seat may hold it)

- **6-CMP — every differing function, read** (no Swift, no test count). **Files:** `docs/deimos/osx-build-game.md`
  (new), `ghidra/deimos/tools/pair-builds.py` (new: the pairing pass, committed this time), `docs/deimos/INDEX.md`
  (its topical-files row).
  **Contract:** rebuild the pairing as `docs/deimos/osx-build.md`, "The two builds, the files, the method"
  describes (normalise each instruction, resolve imports and data references through each build's own data image,
  align in address order), as a committed script whose output states its counts; the counts must reproduce 955
  paired and 906 identical, or the difference is explained. Then, for **every pair whose bodies differ and that the
  front-end address table does not already cover, every unpaired OS 9 function, and every unpaired OS X function that lies inside the game's address range
  or is called from a paired game function** (the OS X build's library code beyond that — about 1,700 functions —
  gets one row per library range, by name), one row:
  both addresses; the function's role from `function-roles.md`; what differs, read by hand in both listings;
  one class — *compiler only* (same behaviour: register choice, a rounding instruction with no effect on any
  reachable value, a constant read from another pool slot with the same bits), *plumbing* (Carbon in place of the
  classic Toolbox, with the same result), *play* (a different number, order, branch or timing in the game),
  *look or sound*; the confidence; and for the last two classes, the exact rule in the OS X build with its
  addresses. The three the earlier pass saw in passing are rows like any other: the heading function (four
  single-precision roundings gone), the two entity-group rules (an integer-to-float conversion changed), the
  cyclic-motion start (a float constant from another pool offset). A "compiler only" verdict on a float change
  must show why no reachable value differs, or it is classed *play*.
  It also answers, from the OS X listing, three items the bank left open: whether anything reads the third integer
  setting (value 50, no reader in the OS 9 build); what the volume keys do under OS X (they skip the hardware call
  and the on-screen message); which physical keys the menu's two volume characters are.
  **Done:** the file exists with every row classed; two review legs each re-read a third of the rows of their own
  choosing in both listings, and between them every *play* and *look or sound* row; their disagreements are settled
  from the listing by the seat. **Gate:** G6, G10.

### Section 6B — rulings and fixes

- **6-RUL — the seat rules each row** and writes one task card per *play* or *look or sound* row **into this
  section of this file** before any dispatch: Files, the OS X rule with its addresses, tests that pin it by bit
  pattern, the pinned values it expects to move, the G2 figure continuing the ladder, and the film rule above as
  the card's gate. One review leg reads the card set against the comparison file before the first dispatch. Rows of the first two
  classes need no card. No rows of the last two classes means no cards, said in the handoff.
- **6-FX-n — one card per row** (a slot; the count is the comparison's). One implementer and two legs each; G2, G4
  (the film rule), G5, G7, G12, and G8 for every *play* row. More than six cards is a second section.
- **6-BANK — the research bank closed** (+1 → the ladder's next figure). **Files:** `docs/deimos/INDEX.md` and the
  topical files it points at, `ghidra/deimos/tools/critic3-lowlist.py` (new), one new test file under `T/DeimosCensusTests/`.
  **Contract:** every item under INDEX "NOT RESOLVED" that is not struck through gets exactly one ending, written
  as a dated note: *closed* with the evidence (the tick rate: Ben's 60 Hz ruling of 2026-10-07; the plates' colour cut: shown at
  gate 1 without objection; items 14 and 62, closed in their text, are struck through); *inert* (a data key or setting no code reads in either build — the third integer setting and the unread rest of
  the settings block, the weapon keys
  with no consumer, the `invulnerableUntil…` unit keys, the circular-burst flag — shown by a search of both
  listings); *Ben's ear or eye* (pitch direction, which his gate-3 answer on the flip pitch closes; the music level against
  the effects; invulnerability carried between sectors; particle shades), which goes on the final card and is
  closed by his word; or *will not chase*, with the reason (who fills
  the entity pool's slots: object addresses only, nothing a player or a film can see; the last-digit agreement of
  the maths library's arctangent and the random state before the first draw: the four films are the witness).
  Item 61 (an entity flagged deleted earlier in a pass is still visited by that pass) is settled from the data:
  one census test, `testNoPausingControllerDiesBeforeItsUpdate`, proves or refutes that any shipped pausing
  controller can be destroyed before its own update in list order; if one can, STOP — it is a play question for
  6-RUL. The 134 cross-file label mismatches (one fact given two confidence labels in two files) are regenerated
  as a list (the checker `critic3-lowlist.py` lives in `~/Developer/Ghidra/deimos/proj/`; commit it under
  `ghidra/deimos/tools/` first) and made to agree, the listing-backed label winning. **Done:** the section has no unstruck item
  without an ending; the mismatch list is empty; G2 +1.
- **6-ST — restage if any game code changed** (as 5-ST: gates, the seat's cross-check, stage, card). The card
  lists each change in a sentence a player would recognise ("enemy groups turn a hair differently, as the OS X
  build did") and says which demo films proved it. If Windows exists by then, both builds (lockstep). **STOP for
  Ben** only if something he can see or feel changed; otherwise the card rides with the next stage.

**Gate card for Phase 6:** "Nothing you should notice has changed" or the list of what has; the question that
blocks nothing: follow the OS X build in play too?

---

## Phase 7 — Windows

**Shape (the seat's rulings; the Bubble Trouble X and Ferazel Windows builds are the pattern).** The game, its
drawing, its sound mixing, every screen and both settings windows already live in the Foundation-only core, and
the text is the game's own bitmap fonts, so the Windows shell is thin: no baked fonts, no drawn-dialog work.
- `Deimos/Shared/` holds the neutral half of today's Mac app; the Mac app and a new package `Deimos/Windows`
  compile the same files (one git symlink per file, as Ferazel).
- `Deimos/Windows` = `DeimosWinKit` (Foundation-only logic, tested on the Mac) and the executable `DeimosWin` on
  HectorSDL. No HectorKit change; if one is needed, STOP and ask.
- A 640×480 picture at whole-number scale on black; Alt+Enter for full screen; the first launch is full screen as
  on the Mac. The clock is SDL's, turned into 60 Hz ticks.
- Keys: Ctrl stands for Command, Alt for Option, in play and at launch (Alt held at launch opens the settings).
  The controls window shows the original's key names. Ctrl+Q is Command-Q with the Mac's rules; the window's close
  button and Alt+F4 act as Ctrl+Q (the Mac close button's rule); a log-off is the Mac's system quit request
  (remembered until the menu, at once from a pause), except that Windows cannot be told "not now" for long: if the
  system insists, the settings and scores are saved and the game quits (the seat's ruling, on the Windows card).
- There is no menu bar on Windows: F1 is "About Deimos Rising…" (the credits), Ctrl+comma is Preferences…. The
  menu's rule that ignores the mouse in the top 22 pixels (the Mac menu bar's height) is switched off on Windows,
  where no bar covers them.
- The "erase all scores?" question and the two data alerts are native Windows message boxes (Ben chose native
  alerts on the Mac).
- Settings and Last Film live in `%APPDATA%\Ambrosia Classics\Deimos Rising\`, in the original's file layout. The
  data folder sits beside the exe, unchanged from `Resources/Deimos/`.
- The controller goes through the kit's pad translator and the port's own layout, one pad.
- Hidden switches as on the Mac: `--film deNN`, `--mute` (SDL's dummy audio). Headless `--frames` opens no window
  and no audio device.
- Every launch by a session is muted and in the daytime; the stage and smoke scripts refuse otherwise.

| Task | What | Count |
|---|---|---|
| 7-W0 ⚑ | the core cross-builds and its tests run under CrossOver | Core unchanged; Proof B first run |
| 7-W1 ⚑ | the shared half and the launch-argument parser | WinKit 0 → **16** |
| 7-W2 ⚑ | the game on SDL | WinKit → **38** |
| 7-W3 | the Windows-only edges: questions, alerts, About, Preferences…, pad, quit paths | WinKit → **53** |
| 7-W4 | reference pictures, stage, smoke, the Windows card; phase end | WinKit → **63** |

- **7-W0 — ⚑ MAJOR — the core on Windows.** **Files:** `tools/windows/proof-b-deimos.sh` (new), `tools/windows/README.md`,
  and only those `Deimos/Core` sources and test files a Windows trap forces, plus `Deimos/Core/Package.swift` for
  platform conditions (each named in the report; behaviour unchanged, G2 and G4 prove it). Known sites to start
  from: `TagName.swift` and `TagIndex.swift` (string searches), `FE/MainMenu.swift` (`replacingOccurrences`), and
  eight test files that call `.contains("…")` on a string. **Contract:** `tools/windows/build.sh Deimos/Core all --tests` ends clean (GW1); the script copies
  the package and the data it reads to the cross-build work folder, builds the tests, runs each test class in
  CrossOver muted and tallies (GWB), refusing between 21:00 and 09:00. The replay bundle and one campaign test (`testEverySectorReachesItsEnd`) are in
  the run, each as its own separately timed step with its own watchdog (the campaign test takes about eight
  minutes natively, so the script runs detached only if Ben allows it: question 10; until then it runs the
  campaign step last and reports a timeout as "not run", never as a pass): the four films must reach their stored scores on Windows too — float fidelity under another compiler
  target is the risk this task exists to find. **Done:** GW1; GWB = every Core test passed or skipped by name with
  the reason written beside it; the four films PASS under CrossOver. A float mismatch is a STOP for the seat.

- **7-W1 — ⚑ MAJOR — the shared half.** **Files:** `Deimos/Shared/*` (new), `App/*`, `project.yml`,
  `Deimos/Windows/Package.swift` and `Sources/DeimosWinKit/*` (the symlinks), `Deimos/Windows/Tests/DeimosWinKitTests/*`.
  **Contract:** move out of `App/DeimosController.swift` everything that is not AppKit, with no behaviour change on
  the Mac (two legs read it as a move; the Mac app's eight front-end goldens, G4 and G12 are unchanged): reading
  the app's resource file and decoding its pictures for Core; starting the audio engine as one pull source; the
  classic Mac character codes for typed keys, through a fixed Unicode-to-Mac-Roman table in place of today's
  Foundation encoding call (which traps on Windows); turning held keys, the mouse point and buttons, and a pad into the
  core's input; the suspend and cursor decisions; the question and quit bookkeeping; and the launch-argument
  parser, which gets its first tests. The Mac controller keeps windows, menus, alerts, events and the key log.
  **Tests (16):** five on the argument parser (each hidden switch, a bad film name's refusal, an unknown switch,
  the mute environment variable, the order of precedence); four on character codes (letters, Return and Escape,
  the two volume characters and every other byte above 0x7F, a key with no character); three on input assembly (held keys, mouse scaling to
  640×480, pad into keys with the pad switched off while the controls window is up); two on picture decoding
  (the developer logo's size and two pixels; a missing picture is a named error); two on suspend and cursor
  decisions. **Gate:** G2 unchanged, G4, G5 (all five schemes: `project.yml` changes), G7, G12, GW2 = 16.

- **7-W2 — ⚑ MAJOR — the game on SDL.** **Files:** `Deimos/Windows/Sources/DeimosWinKit/Win*.swift`,
  `Sources/DeimosWin/main.swift`, tests. **Contract:** `WinGame` owns the driver and the front end exactly as the
  Mac controller does and exposes one step per SDL frame; SDL scancodes map to the Mac key codes the settings file
  stores (so a settings file moves between the two systems) and to the classic character codes; the window, scale
  and full-screen rules of the shape above; audio as the kit's SDL output pulling the game's one source; the
  settings and Last Film paths; the data folder beside the exe, with the same refusal alert text as the Mac when
  it is missing; the mute switch and the headless frames mode with a fixed seed and clock. Also builds on the Mac
  against Homebrew's SDL as the development build.
  **Tests (+22 → 38):** the scancode table against the original's key list (4: every named key to its Mac code,
  the way back, the modifiers, an unknown scancode); the tick clock (3: nanoseconds to ticks, a stall capped as
  the Mac caps it, a clock that steps backwards); whole-number scale and letterbox (5, one per window size);
  mouse mapping through the scale (2); the two file paths (2); a missing data folder (1); the frames mode's cold
  start to the menu in ticks equal to the Mac's cold-start timeline test (1); the direct start through `WinGame`
  matching a bare session over 3,200 passes (1, the Windows twin of G12); mute opens no device (1); full-screen
  toggle keeps the game's state (1); a settings file written by the Mac build reads back the same (1).
  **Gate:** GW2 = 38, GW3, G2 unchanged, G7.

- **7-W3 — the Windows-only edges.** **Files:** `DeimosWinKit/Win{Questions,Alerts,Shortcuts,Pad,Quit}.swift`,
  `DeimosWin/main.swift`, `FE/MainMenu.swift` (one switch for the 22-pixel rule, default as the Mac), tests.
  **Contract:** the erase question and the two refusal alerts as message boxes answering the core's question seam;
  F1, Ctrl+comma, Ctrl+Q, Alt+F4, the close button and log-off, Ctrl+Q, Alt+F4 and the close button with the Mac's Command-Q rules (ignored in play,
  quit from a pause), a log-off with the Mac's system-quit rules (remembered in play and elsewhere until the menu,
  at once from a pause); Alt at launch; the pad; losing and regaining focus and
  minimising as the Mac's leave and return, including Phase 5's pause; the 22-pixel hover rule off.
  **Tests (+15 → 53):** each driven through `WinGame` headless: the erase question answered yes and no (2); the
  two refusal alerts (2); F1 (1); Ctrl+comma (1); Ctrl+Q in play, in a pause, at the menu and on the level select (4); the close button
  (1); a log-off (1); Alt at launch (1); the pad switched off in the controls window (1); focus lost and regained
  in a game (1). In Core: `testMenuHoverTopStripLiveOnWindows` and its Mac twin (+2 on G2, re-stated at merge).
  **Gate:** GW2 = 53, GW3, G2 +2, G4, G7.

- **7-W4 — pictures, stage, smoke, phase end.** **Files:** `Deimos/Windows/Tests/…/WinReferenceTests.swift`,
  `tools/windows/stage-deimos-win.sh`, `tools/windows/smoke-deimos-win.sh`, `Deimos/WINDOWS-WHAT-TO-EXPECT.md`,
  `docs/STATE.md`, `docs/DECISIONS.md`, a handoff. **Contract:** ten reference tests: the eight front-end screens
  and two level-1 frames drawn through `WinGame` hash to the same values as the Mac's goldens (the pictures are
  the core's; a difference is a shell fault). The stage script builds Release, gathers the exe, the Swift and SDL
  DLLs and the data into one folder, refuses a dirty tree or a stale build, and zips it. The smoke script runs the
  staged exe in a clean CrossOver bottle, muted, in the daytime: cold start to the menu, a demo for 300 ticks,
  quit; exit 0 and the menu frame's hash. Then the phase end: every Mac gate, GW1–GW3, GWB, the seat's cross-check
  over the phase's whole change and both cards, then both builds staged (`out/Deimos/`, `out/Deimos-Windows/`, the
  Desktop, and copies in the main checkout's `out/`). With Ben's say-so only, the zip goes up as the GitHub pre-release `deimos-windows-test-1` for his
  tester, with its checksum, and both are copied to the main checkout's `releases/deimos-windows-test-1/`.
  **Gate:** GW2 = 63; smoke exit 0. **STOP for Ben.**

**Gate card for Phase 7 — "does it play the same on a PC"** (for whoever plays on real Windows 10 or 11):
1. Unzip, double-click `Deimos Rising.exe`: logos with sound, loading lines, the menu with music.
2. Play level 1 with the keyboard; bombs on Alt; pause with Caps Lock.
3. Alt+Enter leaves and enters full screen; Alt+Tab away mid-game pauses it.
4. A controller, if one is to hand (`GAMEPAD.md`).
5. Preferences: change a key, quit, start again: the key, the volume and the scores are still there.
6. F1 shows the credits; Ctrl+Q quits from the menu.
7. Not certain, please say: sound crackle or delay; the speed of the game against the Mac; anything that looks
   stretched or blurred.

---

## Phase 8 — the release

Starts only when gates 2, 3, 4 and the Windows gate are closed and Phases 5–7 are merged and pushed.

- **8-IC — the icon.** **Files:** `Deimos/App/AppIcon.icon` (new), `project.yml`, the Windows `.ico` in
  `Deimos/Windows/Resources/`, `tools/windows/stage-deimos-win.sh` (it embeds the icon, as the Bubble Trouble X
  stage does). **Contract:** an Icon Composer document made from the original's own icon art
  (the app's 128-pixel icon, already in the repo, upscaled as Aki's was), three or four previews rendered to
  `out/Deimos/icon-previews/` for Ben to pick from. The Windows exe carries the same art. **Done:** the previews exist; G5 (all five schemes); the pick is
  Ben's and blocks only the release build.
- **8-PK — the package script and the notes.** **Files:** `tools/package-deimos-release.sh` (new, in the shape of
  `tools/package-btx-release.sh`), `docs/release/deimos-1.0.md`, `docs/release/deimos-1.0-MANIFEST.sha256`,
  `Deimos/App/Info.plist` (the build number), `README.md`.
  **Contract:** from a clean checkout: Release build, universal; the original 1.0.6 data copied in unchanged and
  checked against a pinned manifest three times (assembled, signed, inside the mounted DMG); signed inside-out
  with the hardened runtime as "Developer ID Application: Benjamin Thomas (5W72UJL332)"; notarized and stapled,
  app and DMG, by calling `~/Developer/Toolkits/notarize-kit/` (profile `oniarm64-notarize`), never
  re-implementing it; the Windows zip from the Phase 7 stage script at the same commit; a gate summary printed at
  the end. The script asserts no hidden switch is on by default and that the bundle holds no font file at all (the
  settings windows' Geneva 9 strike is compiled into the code; Ben's ruling of 2026-10-25 lets Apple's classic
  system fonts ship). The notes say, in plain words: what this is; what was tested and on what (this Mac and macOS; Windows by
  the tester; Intel and older macOS untested); the known differences from the original (the registered build with
  no registration; no level editor; the port's own controller support; the settings and Last Film folders); how
  the hidden switches work. `README.md`'s Deimos section is rewritten from "planned" to what the game is now,
  with the badges; the download links are added only at 8-RC, on Ben's word. A dry run without `--notarize` proves the script end to end.
  **Done:** the dry run's gate summary; the manifest matches `Resources/Deimos/`.
- **8-RV — the closing review** (the seat's last cross-check, before any release build). The whole Deimos change
  since Phase 4's closing review, the two cards, the notes, STATE and the bank's INDEX, read against this plan:
  every task's Done met or its change owned in a handoff; every gate re-run at the release commit (G1–G5, G7, G8,
  G10, G12, GW1–GW3, GWB, both smokes); no ◇ stand-in, no "known gap" line left on a card that is not a ruling Ben
  has seen. Findings are fixed (lockstep) and re-reviewed before 8-RC.
- **8-RC — release candidate to release.** Run the package script with notarization; upload the DMG, the zip and
  their checksums as a **draft** GitHub release `deimos-1.0`; copy the exact files to the main checkout's
  `releases/deimos-1.0/` the same session. **STOP for Ben:** he downloads the DMG in a browser and opens it (the
  only true test of notarization), plays a level, and says "publish". Publishing, and only then pointing the
  README's Deimos section, badge and download list at the release, are done on his word.
- **8-CL — close out.** STATE's Deimos block becomes "1.0 released", with the next-release recipe (bump the build
  number, the package command); settled history moves to `docs/STATE-history.md`; a final handoff; the memory
  index entry; every Deimos worktree and its DerivedData folder removed; `out/` trimmed to the released stage. **Done:** STATE, the handoff and the memory entry exist; `git worktree
  list` shows no Deimos worktree.

**Gate card for Phase 8:** the icon previews (pick one); the downloaded DMG opens without a warning beyond the one
macOS always shows; the game plays; "publish".

---

## Questions for Ben (also in `docs/QUESTIONS.md` under "Deimos Rising", as DQ1–DQ11, each with what it blocks; the planning session wrote them there)

| # | Question | Default the plan builds | Blocks |
|---|---|---|---|
| 1 | Is this plan approved to start? | — | everything |
| 2 | Your play of the staged app: gates 2, 3 and 4, and whether the arrow keys survive bombs in full screen | — | the fixes your notes need, Phase 5's close, and the release; nothing else |
| 3 | Command-Q on the level select: keep whatever the OS X build did (it seems to make the next game score nothing), or drop the Command-Q once you choose a sector, or quit at once? | what the OS X build did, re-read first | nothing |
| 4 | A controller button held through a pause: act the moment the pause ends (as a held key does), or do nothing until pressed again? | as a held key | nothing |
| 5 | Where the OS 9 and OS X builds differ in the game itself, follow the OS X build you played, provided the four demo films still play out right? | yes | nothing |
| 6 | Windows: may a test build go up as a GitHub pre-release for your tester when Phase 7 ends? | ask again at the phase end | only the upload |
| 11 | Windows: should the controls window show Mac key names ("option", "command") or Windows ones ("Alt", "Ctrl")? | Mac names | nothing |
| 7 | The icon: pick one of the previews when they exist | — | the release build only |
| 8 | Release Mac and Windows together as `deimos-1.0`? | together | nothing until Phase 8 |
| 9 | During the start-up logos, should Command-Q quit? (Today it is ignored, as the original.) | ignored | nothing |
| 10 | May the Deimos Windows test script run detached, as you allowed for Ferazel's? (It takes longer than the ten minutes one command may run, so it would run in the background.) | yes | only the campaign step of the Windows test run |

## Self-review (the seat, after writing; revised after both review legs and the seat's cross-check)

- **Coverage.** Each of the eleven rows of "What stands between today and done" has a task: 1 → 5-GN, 5-ST;
  2 → 5-QF; 3 → 5-PS; 4 → 5-SM; 5 → 5-BK; 6 → 5-DOC; 7 → 6-CMP, 6-RUL, 6-FX; 8 → 6-BANK; 9 → 7-W0 … 7-W4;
  10 → 8-IC; 11 → 8-PK, 8-RV, 8-RC, 8-CL.
- **The design's scope against the build.** Twelve sectors, units and weapons, tallies, the finale, one and two
  players, the front end, the console's ten commands: built (Phases 1–4). Windows and the release: Phases 7, 8.
- **Every open line of STATE's Deimos block is placed:** the narrow fault, the pause screen, Preferences… and
  Edit, the cursor in a pause, the lit button, the menu's buffer, the input-on-the-last-pass item (5-QF item 4),
  the small ones and the closing review's smallest items (5-SM); the bank's items and mismatches (5-DOC, 6-BANK); the end boss (5-BK); the feel of sectors
  5–12, sound reaching the speakers, frame checks under translucent draws (no machine can: Ben's gates).
- **Two slots have no content yet by design:** 5-GN (his notes) and 6-FX (the comparison's rows). Each says who
  writes its cards, where, and before what.
- **Ladder:** Core 511 → 517 (5-QF) → 523 (5-SM) → 532 (5-PS) → +n (5-GN, as written then) → +n (6-FX) → +1
  (6-BANK) → +2 (7-W3). Campaign 3 → 4 (5-BK). Replay 4 → 5 (5-SM). WinKit 0 → 16 → 38 → 53 → 63. Where two
  sections merge in another order, each task's figure is main's count at its merge plus its own delta.
