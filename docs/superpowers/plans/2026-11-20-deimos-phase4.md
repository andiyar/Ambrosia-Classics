# Deimos Rising — Phase 4, the front end — implementation plan (2026-11-20)

> **This file is the authority for Phase 4.** It is built from the "Phase 4 — the front end (cards)" paragraph of
> `docs/superpowers/plans/2026-11-05-deimos-remainder.md` (that file's "Verification model (read first)" — gates,
> standing rules for every implementer, landmines, listing hazards — applies here unchanged and is NOT repeated: read
> it) and from the Phase 3 plan's additions (`2026-11-14-deimos-phase3.md`: G8, the four-heavy-process cap). Four
> grounding appendices sit beside this plan and carry every address a card cites:
> **A** = `2026-11-20-deimos-phase4-grounding-A.md` (boot, main menu, level select, credits, fades, pause);
> **B** = `…-grounding-B.md` (starting a game and coming back, scores, name entry, demo films, Last Film, quit, mouse);
> **C** = `…-grounding-C.md` (the settings file, the two settings windows, the controller, the two builds);
> **D** = `…-grounding-D.md` (the stand-in sweep S1–S30, the Swift seams, how the work is cut).
>
> House method: `~/Developer/Toolkits/fable-kit/orchestrator.md`, run under a Coordinator
> (`project-planning.md` §4–§6a). Per task: one `fk-implementer`, then two `fk-reviewer` legs (spec, then quality), no
> `model` param. Contracts here, not code. Helpers run in the foreground.

**Goal:** the app starts as 1.0.6 does — loading screen, logos, main menu — and from the menu you can start a one- or
two-player game through the level select, come back to the high scores and the menu, watch a demo, replay your last
game, read the credits, change the settings and the keys, play with a controller, and quit with everything saved.

**What Phase 4 is, in one paragraph.** The game itself is finished (Phases 1–3). Today the app opens straight into a
game and starts another when one ends. Phase 4 puts the original's screens around the game. One new piece carries
all of it: a `FrontEnd` state machine in `DeimosCore` that owns the screens, creates each game session and takes its
result back; the driver calls the front end instead of a session. Everything else is one screen or one file format
at a time, each on its own files, most of them provable by machine as lists of draw, sound and wait steps.

**Two things the grounding found that change the cards of the remainder plan:**
1. **There is no attract mode that starts by itself.** Demos start only from the DEMOS button or the `D` key; the
   counter `G+0x24` only picks which demo is next (B §0). "Last Film" has no button: it is the `F` key (B §0).
2. **The app file holds two builds** — the Mac OS 9 build (called **L** below; everything in `docs/deimos/` and the
   committed dump describes it) and the Mac OS X build (**X**, at data-fork offset 0xf67c0), which is what Ben played
   (D30). They were compared only for input, the two settings windows and the settings file (C §0). Section S0 puts X
   on file and compares the front-end functions; a whole-game comparison is outside Phase 4 (question 1).

## Verification model (additions)

| # | Gate | Expected |
|---|---|---|
| G1 | HectorKit zero-skip at kit main | the kit's figure that day (370 executed on ef2c341 = 366 + 4 Aki 1.1 skips), recorded, never "fixed" here |
| G2 | `Deimos/Core` without `DeimosReplayTests` and `DeimosCampaignTests` | **main's count when the section merges + the section's deltas**, 0 failed (base **372** at main 68b93b6; the phase ends at **477**) |
| G3 | census file body unchanged | empty diff |
| G4 | `DeimosReplayTests`; `deimos-replay --all` | **4 / 0**; four `PASS` lines, exit 0 — any change is a STOP |
| G5 | Deimos builds (Debug and Release); Aki and BubbleTroubleX only when `project.yml` or HectorKit changed | `** BUILD SUCCEEDED **` |
| G6 | scope fence | changed paths ⊆ the task's Files |
| G7 | layering grep | prints nothing |
| G8 | `DeimosCampaignTests`, one test at a time | **3 / 0** — run at the close of S1b, S5 and S8b only |
| G9 | staged app boots (S8b only; muted, daytime, with Ben's say-so) | a pid; clean quit; no crash report |
| G10 | clean tree | nothing but `??` |
| G11 | bounded tests | every loop names a bound and fails on it |
| G12 | **the direct start** (from S1b on, for good) | `DeimosHostTests.testDirectStartMatchesBareSession`: a headless driver started with the front end's direct start (sector 1, one player, seed 0x469c2) yields the same `TickTrace` rows over 3,200 passes as a bare `DeimosSession` stepped by the test |

**The ladder is per section, not one chain,** because sections run side by side: a section's G2 is main's count at
the moment it merges plus its own deltas, and its handoff records the figure it measured. If a named test already
exists on main it is re-specified under its name and the delta drops by one: say so, never rename.

**Heavy processes:** a section runs at most **two** at a time (`swift-test`, `swift-build`, `xcodebuild`), so two
sections side by side stay inside the machine's cap of four. No task launches the app or plays sound; G9 is the only
launch and needs Ben's say-so.

**Frame goldens.** No picture of the original's screens exists anywhere (A §10). Goldens are the replica's own
frames (FNV-1a 64 over the pixmap, the method of `LevelOneFrameTests`), backed by pixel checks read straight from
the source images. They catch change, not error: **Ben's eyes are the only proof a screen looks right.**

**What the machine does NOT prove in this phase:** how any screen looks; the feel of the fades and waits; the mix of
menu music and effects; typing a name; a real controller in the hand; the settings file against one the original
wrote (none exists on this Mac or in the archive, C §1b).

## Rulings this plan proceeds on (the seat's, 2026-11-20; each is on the gate-4 card for Ben to overturn)

1. **`FrontEnd` lives in `DeimosCore`** and owns the session (B §6 option A, D Part 3 option a): testable headless,
   and Windows gets it for free. The driver's only client is the front end.
2. **The locked seams grow by addition** (standing rule 7), all in S1a's first task and nowhere else — the list is in
   that card. A later task that finds a seam missing STOPs; the seat adds it as a micro-commit on main first.
3. **No demo starts by itself**; DEMOS / `D` cycles de01 → de02 → de03 → de04; `F` replays the last game. As the original.
4. **The registered build's layout:** no REGISTER button, no advertisement screen, no unregistered cut-off (A §2.1, B §1b).
5. **Where the two builds differ, the front end follows X** (the OS X build Ben played). S0 closes before any
   screen is built, so each screen task reads `docs/deimos/osx-build.md` first and builds what X does.
6. **The settings file** keeps the original's 0x34f0-byte layout and scrambling and lives at
   `~/Library/Application Support/Ambrosia Classics/Deimos Rising/Deimos Rising Preferences` (design 2026-10-06 §7.5).
   Read at boot, written when fresh and **at quit only**, as the original; high scores therefore reach disk at quit.
7. **Last Film** is saved under the same folder (`Local/film/Last Film[last].film`) at the end of every non-film
   game; within one run the front end replays it from memory, and at the next launch a second tag-index root finds it.
8. **The two settings windows are drawn by the game** through the same draw path as every other screen (so Windows
   reuses them), not by AppKit controls. Their look is question 6.
9. **Pictures from the app's resource fork** (the developer logo PICT 1000; the controls window's PICTs 190–197) are
   decoded by the shell with HectorKit — the App now, the Windows shell later — and handed to Core as plain images at
   start-up. Core never decodes a PICT (it may not import HectorGraphics); headless tests hand in made-up images.
10. **Launch switches:** `-players` and `-sector` are deleted from the app when start-and-return lands (S3a). The
    front end keeps an internal "direct start" (used by tests and by `-film`). `-film deNN` stays as a hidden switch
    (the fallback check for the replay gate on Ben's cards): it plays the film after the boot and returns to the menu
    as a demo does; a bad value shows the refusal alert in Release too. `-debugCapsLock` stays DEBUG-only, fixed.
11. **The menu's volume keys** change the volume as in the game; whether the click sounds is read from the listing
    by the menu task (A §9a item 8) and built as read.
12. **"About Deimos Rising…" in the app menu opens the credits screen** and is disabled during a game; File ▸ Quit
    is the app menu's Quit. As the original's menu bar (C §5).
13. **"Full Screen (Takes Effect on Relaunch)"** does what S0 reads X doing with it (X `10000230`); if that cannot
    be read, it is inert, as in L.
14. **Level select gets a bare `GameState` of its own** to run the frame controller, the console and the pause
    (A §7), so `FrameKeys` and `Console` keep their signatures and no gameplay file changes.
15. **Original quirks replicated, not guarded:** the right-hand level preview never shows its hover strip; NO ACCESS
    appears for a locked sector; the publisher logo holds until its sound ends, with no time limit; the accept flash's
    last step is never shown; a blank eleventh credits page; a demo started by a click makes the copyright line flip at
    once on return; Esc out of a game still reaches the high-score table; the two two-player table quirks (B §2b); a
    name left empty becomes "Jar Jar Must Die" (B §2c).
16. **Tests live in the existing bundles** (`DeimosCoreTests`, `DeimosHostTests`, `DeimosRenderTests`); no new target.
17. **The controller** follows D36/D37: a fixed layout by button position, in `DeimosCore/Input/DeimosPadLayout.swift`;
    one pad, player 1; plus = pause, minus = Esc (held one second in play, at once elsewhere — so minus ends a demo
    and leaves the level select). The original's own gamepad windows (DITL 192/193) are not built, and "Set Gamepad
    Controls…" is hidden, as X hides it when its gamepad layer is absent. Button choices are question 5.

## Questions for Ben (sent through the Coordinator 2026-11-20; the plan proceeds on the default)

| # | Question | Default the plan builds | Blocks |
|---|---|---|---|
| 1 | Run a whole-game comparison of the OS 9 and OS X builds as its own research job? | yes, outside Phase 4 | nothing here |
| 2 | Whose name does "this copy is registered to …" show? | built as one constant, shown as "AMBROSIA CLASSICS" until he says | nothing (one-line change) |
| 3 | The website line: light up and do nothing on a click, or the original's "open the browser" dialog? | lights up, click does nothing | nothing |
| 4 | Command-Q in the middle of a game (the original ignored it there) | quits at once, saving settings and scores | nothing |
| 5 | Controller: buttons (bottom = fire air, left = fire ground, top and right = select); two pads for two players (needs a HectorKit change); the original's gamepad windows; a way to start 2 PLAYER from the pad | as listed; one pad; not built; 2 PLAYER needs the keyboard or mouse | nothing |
| 6 | Look and place of the two settings windows (he saw the OS X Aqua look; the two volume controls' art is missing from the shipped file) | classic grey Mac look as Ferazel's, plain sliders, centred on the game's 640×480 picture | nothing |
| 7 | Loading screen: show each of about 425 item names for one screen update, or only the five lines? | every name, one per update | nothing |
| 8 | The "erase all scores?" question and the two data alerts: a normal macOS alert, as the original used the system's, or drawn by the game? | a normal macOS alert | nothing |

## Corrections to the cards of the remainder plan (this section wins)

- "Attract mode" = the DEMOS button and `D` key (ruling 3). INDEX #62 is closed by A §3.4. INDEX #14 is closed by C §3b.
- Level select runs on the frame controller (two-tick frames); every other screen counts ticks (A §3, risk 9).
- The `ghidra/deimos-proj/` path the older plans cite does not exist in a worktree: the L listing is
  `~/Developer/Ghidra/deimos/proj/disasm-review3-all.txt`; the dump is `ghidra/deimos/Deimos_pef.decompiled.c`.
- The level-1 music "stand-in" (remainder stand-in 4) is the original's own branch for "no music playing"
  (P3 correction 5). The session start gains a "music already playing" flag, default false, so every existing test
  holds; the level select passes true.

## Sections and running order

A section is one orchestrator session (cap 300k; sized to close near 240k). **Every section's first build task starts
only after Phase 3 wave 3.4 is merged to main** — check `git log main --oneline | /usr/bin/grep "wave 3.4 closed"`
(68b93b6) before the first dispatch, and that every section under Needs has its handoff file on main. Each section
works in its own worktree from main, merges to local main at its close and writes the handoff file named here.
**At most two sections run at once.**

| Order | Section | Seat | Needs merged first | May run beside | Handoff it writes |
|---|---|---|---|---|---|
| 1 | **S0** the OS X build on file; bank corrections | Opus | wave 3.4 | S1a | `docs/handoff-deimos-phase4-s0.md` |
| 1 | **S1a** seams and the element list | Fable | wave 3.4 | S0 | `docs/handoff-deimos-phase4-s1a.md` |
| 2 | **S1b** the front end's frame | Fable | S1a | S0 | `docs/handoff-deimos-phase4-s1b.md` |
| 3 | **S2** main menu, credits | Fable | S0, S1b | S4 | `docs/handoff-deimos-phase4-s2.md` |
| 3 | **S4** settings file, high scores, name entry | Opus | S0, S1b | S2 | `docs/handoff-deimos-phase4-s4.md` |
| 4 | **S3a** starting a game and coming back | Fable | S2, S4 | S5 | `docs/handoff-deimos-phase4-s3a.md` |
| 4 | **S5** Last Film and demos | Opus | S0, S1b | S3a, or S2/S4 if only one of them is running | `docs/handoff-deimos-phase4-s5.md` |
| 5 | **S3b** level select | Opus | S3a | S6 or S7 | `docs/handoff-deimos-phase4-s3b.md` |
| 5 | **S6** boot; the configuration window | Fable | S0, S1b | S3b, or any one of S2–S5 | `docs/handoff-deimos-phase4-s6.md` |
| 6 | **S7** the controls window; the controller | Opus | S6 | S3b | `docs/handoff-deimos-phase4-s7.md` |
| 7 | **S8a** the app | Fable | S0–S7 (all) | — | `docs/handoff-deimos-phase4-s8a.md` |
| 8 | **S8b** goldens, stage, gate 4 | Fable | S8a | — | `docs/handoff-deimos-phase4-s8b.md` |

Disjointness rests on three rules. **(1) S1b creates every screen's file as a stub with a frozen entry signature,
and after S1b a screen task edits only its own files** (listed per section). **(2) Closed files:** `FE/FrontEnd.swift`,
`FE/FrontEndWaits.swift`, `FE/SessionResult.swift`, every file under `Core/Seams/`, `Host/DeimosDriver.swift`,
`Package.swift`, `project.yml` and everything under `Deimos/App` are closed to every section but the ones that name
them. **(3)** `DeimosSession.swift`, `GameState.swift`, `PlayerUpdate.swift`, `Film.swift`, `TagIndex.swift` and
`DeimosAssets.swift` belong to S5 alone after S1b.

**Where the phase ends:** S8b stages the app and writes the gate-4 card; the seat's one cross-check runs over the
whole phase's diff and the card before staging; then **STOP for Ben's gate 4** ("cold start → game → scores → quit").
If Ben's notes from gate 2 or gate 3 arrive meanwhile, their fix wave is its own section and Phase 4 sections merge
main before their next task.

Path shorthand: `Core/` = `Deimos/Core/Sources/DeimosCore/`, `Host/` = `Deimos/Core/Sources/DeimosHost/`,
`Render/` = `Deimos/Core/Sources/DeimosRender/`, `T/` = `Deimos/Core/Tests/`, `FE/` = `Core/FrontEnd/` (new).

---

## S0 — the OS X build on file; bank corrections — Seat: Opus

**Files it may touch:** `ghidra/deimos/**`, `ghidra/README.md`, `docs/deimos/*.md`, `docs/deimos/INDEX.md`. No Swift.
**Needs:** wave 3.4. **Handoff:** `docs/handoff-deimos-phase4-s0.md`.

- **OX — the OS X fragment, committed.** First step: state that wave 3.4 is on main. Extract fragment 2 of the
  app's data fork (offset 0xf67c0, 1,035,460 bytes; C §0), disassemble it headless with Ghidra as C's leg did, into
  `~/Developer/Ghidra/deimos/` and a committed copy under `ghidra/deimos/`, with a `regen` recipe in
  `ghidra/README.md` (house rule: no dump only in a worktree or scratchpad). The installed Ghidra has no decompiler
  for this Mac: the product is a listing and a symbol dump. **Bar:** the listing is on main; a search of it finds code
  at the addresses C cites (`1004cdf0`, `100435d0`, `10011240`); the recipe re-runs clean.
- **CMP — the front-end functions, L against X.** For each function the appendices cite for a screen (menu
  `FUN_100229a0`, start/return `FUN_100234d0`, level select `FUN_1002e310`, scores `FUN_10021950` / `FUN_100214c0` /
  `FUN_10021bd0`, credits `FUN_10025b90`, boot `FUN_100000e0`, demo choice `FUN_100069b0`, pause `FUN_10022ef0`, film
  record and save, the configuration dialog), find its X counterpart and compare size, call list and constants. New
  file `docs/deimos/osx-build.md`: an L ↔ X address table and every difference with both addresses, each marked
  "changes what Phase 4 builds" or not. Also read C §6a items 1, 2 and 5 (what X does with the Full Screen byte —
  ruling 13) as far as the listing allows. **Bar:** every function named has a row; two review legs each re-derive
  three rows. Differences are reported, never acted on here.
- **BK — bank corrections** (seat-run, one commit): the lists in A §11 (10), B §9 (6), C §8 (6) and the list in
  `docs/handoff-2026-11-20-deimos-phase4-plan.md`; INDEX #62 and #14 closed. **Bar:** each note cites its address.

## S1a — seams and the element list — Seat: Fable

**Files:** `Core/Seams/{HeldKeys,MusicCue,ShellRequest,RenderOp,PassOutput}.swift`; `FE/SessionResult.swift`,
`FE/FrontEndWaits.swift`, `FE/ElementList.swift` (new); `Core/Game/DeimosSession.swift` (builds the result; the
"music already playing" flag); `Core/Game/DeimosAssets.swift` (additive: `stli inte` and `cred` accessors; a table
of shell-supplied pictures, empty by default); `Host/{DeimosDriver,HeadlessRunner}.swift` (the new waits and the quit
end only — the driver still drives a session); `Render/DeimosRenderer.swift` and `Deimos/Core/Sources/DeimosAudio/*`
only for a new op, stop-with-fade and "voice ended"; every file with an exhaustive switch over a seam;
`T/DeimosCoreTests/{Seams,SessionResult,FrontEndElements}Tests.swift` (new), `T/DeimosHostTests/DriverTests.swift`.
**Needs:** wave 3.4. **Handoff:** `docs/handoff-deimos-phase4-s1a.md` (the final seam signatures, in full).

- **SK-a — ⚑ MAJOR — the seam additions (+7).** First step: state that wave 3.4 is on main.
  - **Contract (ruling 2; A §7; B §1c, §5; D Part 2 §3, §7):** every addition keeps old call sites compiling.
    - `HeldKeys`: mouse position, button down, mouse-down events; auto-repeat marked on typed characters; menu
      commands arriving from the shell (About chosen, Quit chosen, a Quit request from the system); suspend and resume.
    - `MusicCue`: stop-with-fade. `ShellRequest`: About enabled / disabled, quit now, save Last Film (bytes), ask a
      two-button question (question 8). (`showCursor` already exists.)
    - Host waits the driver runs as it runs fades today: a number of ticks; until a named voice ends; until a click
      or key; the answer to a question. Input arriving during a wait is queued.
    - `RenderOp`: draw a shell-supplied picture (ruling 9); anything the element list needs.
    - `SessionResult`, built when a session ends: B §1c's fields (both slots "present" even with one player; scores;
      each player's level; all-levels; cheated) **plus** the kind of end (game over, Esc, finale, film ran out or was
      stopped, film failed to load), whether it was a film, the start sector, and the recorded film (empty until S5).
    - `HeadlessRunner` gains the quit end. The session start gains "music already playing" (default false).
  - **Tests (7):** `testHeldKeysMouseDefaultsUp` · `testSessionResultOnePlayerBothSlotsPresent` ·
    `testSessionResultAfterFinale` · `testSessionResultCheated` · `testMusicAlreadyPlayingOnlyStops` · in
    `DriverTests`: `testDriverRunsHostWaits` (fake clock; input queued, not dropped) · `testVoiceEndWaitReleases`.
  - **Gate:** G2 = **379 / 0**; **G4 unchanged**; G5 (Deimos), G7. Two legs; leg 2 runs mutants (a wait that drops
    queued input; slot-present false for an absent player 2; the flag's default flipped).
- **EL — the element list and its fades (+5 → 384), after SK-a.**
  - **Contract (A §5.2, §7; `text-metrics-lists.md` §3):** the list of text and sprite elements with bounds and hit
    rectangles that the menu, credits, loading lines and scores share; fade in (32 passes, level 31 … 0), fade out
    (1 … 32), one-element fade; text alpha = max(level, own), sprite alpha = level; an empty list fades in 0 passes.
  - **Tests (5):** `testElementFades` · `testElementBounds` · `testElementHitRects` · `testOneElementFade` ·
    `testEmptyListFadesInZeroPasses`. **Gate:** G2 = **384 / 0**.
  - **As built (S1a close, 2026-11-20; `docs/handoff-deimos-phase4-s1a.md`):** the fades follow X under ruling 5 —
    **16 passes** (in 30, 28 … 0; out 2, 4 … 32; `osx-build.md` D1), not the 32 above. A sixth test,
    `testElementDrawOnce`, pins a draw-once the later screens need, so S1a closed at **385** and the phase ends at
    **478**. SK-a also added a beep request, the scaled copy, a music-fade wait and key codes (the handoff lists all).

## S1b — the front end's frame — Seat: Fable

**Files:** `FE/FrontEnd.swift` and one stub file per screen (new: `Boot.swift`, `MainMenu.swift`, `StartReturn.swift`,
`LevelSelect.swift`, `Scores.swift`, `NameEntry.swift`, `Credits.swift`, `Films.swift`, `ConfigDialog.swift`,
`ControlsDialog.swift`); `Host/{DeimosDriver,HeadlessRunner}.swift`; `Core/Game/{DeimosSession,FrameController,FrameKeys}.swift`
(the cursor hide; the quit request inside the Caps Lock wait); `Deimos/App/{DeimosController,DeimosMain}.swift` only
to keep the app compiling and behaving as today; `T/DeimosCoreTests/{FrontEndSkeleton,DeimosSession}Tests.swift`,
`T/DeimosHostTests/DriverTests.swift`. **Needs:** S1a. **Handoff:** `docs/handoff-deimos-phase4-s1b.md` (it must list
each screen's frozen entry signature and what its stub does — every later section builds from that list).

- **SK-b — ⚑ MAJOR — `FrontEnd`, the stubs, the driver (+7 → 391), alone in its section.** First step: state that
  wave 3.4 and S1a are on main.
  - **Contract (B §1, §5, §6; D Part 2 §7, Part 3):** a `FrontEnd` value in Core is the driver's only client. It
    holds: the live prefs, the demo counter, the menu-music flag, the quit and leave flags, the copyright clock (it
    outlives a demo), sound available, suspended, the launch modifiers (Command, Option), the registered name, the
    last recorded film, and the current screen. A screen is a resumable sequence of steps built on S1a's waits.
  - Stores are handed in, not built here: two small protocols (settings; Last Film) with do-nothing defaults. On
    "save Last Film" the driver calls the store; at shutdown the driver returns the live prefs for the settings store.
  - **The stubs.** Each screen file holds a pass-through with its final entry signature: boot → menu; the menu stub
    starts a game; start/return runs the session and comes back; scores, name entry, credits, films and the two
    windows return at once. **The direct start** (ruling 10): an entry that skips boot and menu and starts a game
    with a given player count, sector, seed and optional film, then starts again when it ends — this is today's
    behaviour, and the app uses it for every launch until S2 lands, so the app behaves as today. All existing driver
    tests are re-pointed to it (same names and count; `driver.session` stays as a forwarding accessor — rule 7).
  - The driver's own restart block is deleted. The cursor hide moves to the front end (D S17;
    `testCursorHiddenAtSessionStart` re-specified, same name). A quit request that arrives inside the Caps Lock wait
    ends the session (D S14; controller `+2`).
  - **Tests (7):** `testStubScreensPassThrough` · `testTickWaitYieldsAndResumes` · `testEventWaitQueuesAndFlushes` ·
    `testQuitRequestReachesFrontEnd` · `testPrefsCarriedThroughSessions` · `testQuitInsideCapsLockWait` · in
    `DriverTests`: `testDirectStartMatchesBareSession` (G12).
  - **Gate:** G2 = **391 / 0**; **G4 unchanged**; G12; G5 (Deimos Debug and Release); G7; G8 at the close. Two legs;
    leg 2 runs mutants (the direct start ignoring its sector; prefs not returned; a stub that swallows the quit).

## S2 — main menu, credits — Seat: Fable

**Files:** `FE/MainMenu.swift`, `FE/Credits.swift`, `Deimos/App/DeimosController.swift` (one change: a launch with no
switch now uses the normal start, not the direct start), `T/DeimosCoreTests/{MainMenu,Credits}Tests.swift` (new).
**Needs:** S0, S1b. **Handoff:** `docs/handoff-deimos-phase4-s2.md`.

- **MM — ⚑ MAJOR — the main menu (+8).** First step: state that wave 3.4, S0 and S1b are on main; read the menu's
  rows in `docs/deimos/osx-build.md`.
  - **Contract (A §2, §6; `front-end.md` §2):** the registered layout (ruling 4) and its element centres; the idle
    pass; the copyright line flipping to the registered banner strictly after 240 ticks, its clock reset by a click,
    a key, suspend and resume (question 2); hover sound once per entry, none for the logo or inside the menu-bar
    strip; click tracking while the button stays down; every key of `front-end.md` §2.8 with its click sound and
    10-tick flash (`F`: no flash); the volume keys (ruling 11); the website line (question 3); suspend and resume;
    the menu-music rule (resume if the stream still plays, else `inmu` from the start). Leaving: the QUIT button
    leaves at once; `Q`, File ▸ Quit and a system Quit flash QUIT for 10 ticks first; then the element fade-out and
    the music stop-with-fade, and the front end reports "done". Button actions call the other screens' entries.
    Before coding, read A §9a items 4, 6 and 8 from the listing and report them.
  - After this task a launch shows the stub boot and then the menu; 1 PLAYER and 2 PLAYER start sector 1 through
    the start/return stub.
  - **Tests (8):** `testMenuLayout` · `testCopyrightFlip` · `testMenuHover` · `testMenuKeys` ·
    `testMenuClickTracking` · `testMenuSuspendResume` · `testMenuMusicResumeOrRestart` · `testMenuQuitSequence`
    (assertions: A §10). **Gate:** G2 = base **+ 8**; G4, G12 unchanged; G5; G7.
- **CR — credits (+2), after MM.** **Contract (A §4):** ten pages and the blank eleventh, their times, 60-tick gaps,
  the first page at +92; a click leaves with the click sound, `N` starts a game, any other key leaves. Read A §9a
  item 5 first. **Tests (2):** `testCreditsPaging` · `testCreditsExits`. **Gate:** G2 = base **+ 10**.

## S4 — settings file, high scores, name entry — Seat: Opus

**Files:** `Core/Game/PrefsFile.swift` (new; the codec beside the locked `DeimosPrefs`), `Host/PrefsStore.swift`
(new: the settings store of S1b's protocol — given a folder, never a fixed path), `FE/Scores.swift`,
`FE/NameEntry.swift`, `Core/Game/HighScoreTable.swift` (new),
`T/DeimosCoreTests/{PrefsFile,HighScore,NameEntry,ScoresScreen}Tests.swift` (new),
`T/DeimosHostTests/PrefsStoreTests.swift` (new). **Needs:** S0, S1b. **Handoff:** `docs/handoff-deimos-phase4-s4.md`.

- **PF — the settings file (+7).** First step: state that wave 3.4, S0 and S1b are on main.
  **Contract (C §1a, §1b):** a byte-exact codec for the 0x34f0 record that keeps the raw image so unread bytes
  survive; the scrambling of names and scores; names decoded before the version test; a missing or wrong-version file
  gives the fresh record, which is written at once; a short file with the right version is accepted, as the original
  (read C §6a item 3 first to learn what fills the rest). No `UserDefaults`, no `String.Encoding.macOSRoman`.
  **Tests (7):** `testFreshPrefsFileImage` · `testPrefsRoundTrip` · `testVersionMismatchIsFresh` ·
  `testNameObfuscationOverStrlen` · `testNamesDecodedBeforeVersionCheck` · `testStoreWritesFreshAtOnce` ·
  `testStoreRoundTripOnDisk` (a temporary folder). **Gate:** G2 = base **+ 7**.
- **HS — the table and name entry (+7), after PF.** **Contract (B §2a–§2d):** insertion with both two-player quirks
  and "a tie ranks below"; name entry for player 1 then player 2: 20 characters, auto-repeat, the blinking cursor,
  the easter-egg names, an empty name; the scores screen; its erase question through the question wait (question 8),
  which also resets both player names. Read B §7a item 3 first. **Tests (7):** `testInsertTwoPlayerQuirks` ·
  `testInsertTieRanksBelow` · `testNameEntryEggs` · `testNameEntryTwentyCharsAndRepeat` · `testNameEntryCursorBlink` ·
  `testEraseResetsPlayerNames` · `testScoresScreenLayout`. **Gate:** G2 = base **+ 14**.

## S3a — starting a game and coming back — Seat: Fable

**Files:** `FE/StartReturn.swift`, `Deimos/App/{DeimosMain,DeimosController}.swift` **only** to delete `-players`
and `-sector`, `T/DeimosCoreTests/StartReturnTests.swift` (new). **Needs:** S2, S4.
**Handoff:** `docs/handoff-deimos-phase4-s3a.md`.

- **SR — ⚑ MAJOR — start and return (+7).** First step: state that wave 3.4, S2 and S4 are on main; read the
  start/return rows in `docs/deimos/osx-build.md`.
  - **Contract (B §1a–§1e):** menu button or key → the start sequence in the original's order (level select through
    its entry — still the stub, which returns sector 1); session end → the return sequence of B §1b by the result's
    kind of end (game over, Esc, finale, level select cancelled, film, film failed to load): fades of 33 and 9, the
    `back` picture, `tran` or not, the menu-music flag or not — so menu music plays on under a film; the post-game
    gates of B §1d (best sector into pref 3; the table path into S4's insertion and name entry). Read B §7a items
    4–6 first.
  - **Tests (7):** `testStartSequence` · `testReturnAfterGameOverSequence` · `testEscStillEntersHighScores` ·
    `testFilmReturnKeepsMenuMusic` · `testCancelledLevelSelectNoFadeOut` · `testFinaleSetsBestSectorTwelve` ·
    `testPostGameGatesTable` (one table test that carries B §8's rows: a later start writes no pref and no table; a
    cheat skips the gates; best minus one without the finale). **Gate:** G2 = base **+ 7**; G4, G12 unchanged; G5; G7.

## S5 — Last Film and demos — Seat: Opus

**Files:** `Core/Film.swift`, `Core/Game/FilmRecorder.swift` (new), `Core/Game/GameState.swift` (one stored field),
`Core/Player/PlayerUpdate.swift` (the recording point only, `1002a40c..1002a42c`), `Core/Game/DeimosSession.swift`
(creating the recorder at set-up, the mouse-button film end at ~298–301, filling the result's film — nothing else),
`Core/TagIndex.swift` and `Core/Game/DeimosAssets.swift` (an optional second root, default none),
`Host/LastFilmStore.swift` (new: the Last Film store of S1b's protocol), `FE/Films.swift`,
`T/DeimosCoreTests/{FilmRecorder,Films}Tests.swift` (new), `T/DeimosHostTests/LastFilmStoreTests.swift` (new).
**Needs:** S0, S1b. **Handoff:** `docs/handoff-deimos-phase4-s5.md`.

- **FR — ⚑ MAJOR — the recorder (+6).** First step: state that wave 3.4, S0 and S1b are on main.
  **Contract (B §4a–§4c; ruling 7):** every non-film session records both players' input, score and current level
  each tick in life state 4, to the format of B §4a, capped at 20,000 ticks; the film leaves in the session's
  result. Read B §7a items 1 and 2 first.
  **Tests (6):** `testRecordReproducesDemo01` (the strongest pin: a session fed demo 01's keys records demo 01's
  40,296 bytes) · `testRecordRoundTrip` · `testFramesCapTwentyThousand` · `testNoRecordInFilm` ·
  `testEmptyFilmEndsAtFirstAppear` · `testLastFilmOverridesShippedCopy` (store → second root).
  **Gate:** G2 = base **+ 6**; **G4 unchanged (4 / 0)** — the recorder must not move a film; G12; G8 at the close.
- **DM — demos and the F key (+4), after FR.** **Contract (B §3):** the demo cycle and its counter, which lasts the
  app's life; `F` plays the film held in memory, else the one on disk; the mouse button ends a film in that pass; no
  key but Esc does. **Tests (4):** `testDemoCycleOrderAndWrap` · `testMouseButtonEndsFilm` · `testKeysDoNotEndFilm` ·
  `testEscEndsFilm`. **Gate:** G2 = base **+ 10**; G4.

## S3b — level select — Seat: Opus

**Files:** `FE/LevelSelect.swift`, `Render/LevelSelectDraw.swift` (new: the opaque scaled copy and the video-grid
tiler), `T/DeimosCoreTests/LevelSelectTests.swift`, `T/DeimosRenderTests/LevelSelectDrawTests.swift` (new).
**Needs:** S3a. **Handoff:** `docs/handoff-deimos-phase4-s3b.md`.

- **LS — ⚑ MAJOR — level select (+8).** First step: state that wave 3.4 and S3a are on main; read the level-select
  rows in `docs/deimos/osx-build.md`.
  - **Contract (A §3, all five parts; ruling 14):** three previews, START or NO ACCESS by pref 3, the description
    text, the video grid, the hover strip with its right-hand quirk, move with wrap and the change sound, accept by
    player 1's fire or select keys or a press on the middle preview (Return is not an accept), the accept flash (16
    frames, last one unshown) and the fail flash with its 40-frame message, Esc at once or on the 16th held frame by
    pref 8, Caps Lock pause, `ammu`, and "music already playing" passed to the session; all on two-tick frames.
    Read A §9a items 2 and 3 first and report the draw order before coding. If the bare `GameState` of ruling 14
    cannot carry the frame controller without touching a closed file, STOP.
  - **Tests (8):** `testLevelSelectInitial` · `testLevelSelectUnlock` · `testLevelSelectMoveEdgeAndWrap` ·
    `testAcceptFlash` · `testFailFlash` · `testLevelSelectEsc` · `testHoverStripRightPreviewRejected` ·
    `testLevelSelectPause`. **Gate:** G2 = base **+ 8**; G4, G12; G5; G7. Leg 2 runs mutants (ticks for frames;
    flash 17 steps; right strip drawn; NO ACCESS never shown).

## S6 — boot; the configuration window — Seat: Fable

**Files:** `FE/Boot.swift`, `FE/ConfigDialog.swift`, `Core/Resources/DialogResources.swift` (new: a
Foundation-only reader for DLOG, DITL, STR#, `tab#`), `FE/DialogDraw.swift` (new: the drawn controls),
`tools/stage-deimos.sh` and `project.yml` (stage `Deimos Rising.rsrc` into the app),
`T/DeimosCoreTests/{Boot,DialogResources,ConfigDialog}Tests.swift` (new). **Needs:** S0, S1b.
**Handoff:** `docs/handoff-deimos-phase4-s6.md` (it must describe the drawn-control helpers S7 reuses).

- **BT — boot (+4).** First step: state that wave 3.4, S0 and S1b are on main. **Contract (A §1; ruling 9):** the
  loading screen and its five lines (question 7), the publisher logo held until its sound ends, the developer logo
  (a shell-supplied picture) with `inmu`, every fade, the quiet launch (Command held) and the no-sound path, the
  configuration window first when the settings ask for it or Option is held (both read from the front end's state).
  Read A §9a items 1 and 7 first.
  **Tests (4):** `testBootSequenceOps` · `testBootQuietLaunch` · `testBootNoSound` · `testLoadingLines`.
  **Gate:** G2 = base **+ 4**; G5 with Aki and BubbleTroubleX (`project.yml` changed).
- **DG — ⚑ MAJOR — the configuration window (+9), after BT.** **Contract (C §2; rulings 5, 8, 13, 17):** the
  resource reader; the window's twenty items from DITL 190 with their rectangles and texts; each item's setting;
  Defaults, Revert, Cancel and Save as C describes; no Cancel on a first launch; items greyed or hidden as X does;
  the two volume controls as sliders (question 6). **First step, before any code:** report how the window's text
  (Geneva 9) and controls will be drawn within Core's allowed imports — Ferazel's precedent is
  `Ferazel/Core/Sources/FerazelCore/Front/{PrefsDialogModel,DialogResources}.swift`; if no route exists without a
  HectorKit change, STOP and the seat rules.
  **Tests (9):** `testDITL190Parse` · `testConfigItemToggles` · `testDefaultsResetsKeysNotBytes9to11` ·
  `testCancelRestoresSnapshotIncludingKeys` · `testRevertGreysUntilChange` · `testFirstLaunchHasNoCancel` ·
  `testGreyingFollowsOSX` · `testVolumeSliderPins` · `testBootDialogRuleByte2AndOption`.
  **Gate:** G2 = base **+ 13**; G7.

## S7 — the controls window; the controller — Seat: Opus

**Files:** `FE/ControlsDialog.swift`, `Core/Input/DeimosPadLayout.swift` (new), `Deimos/Core/Package.swift`
(HectorInput for DeimosCore — the only Package change in the phase), `Core/Game/KeyTable.swift` (comments and the
slot pin only), `T/DeimosCoreTests/{ControlsDialog,PadLayout}Tests.swift` (new). **Needs:** S6.
**Handoff:** `docs/handoff-deimos-phase4-s7.md`.

- **CW — the controls window (+8).** First step: state that wave 3.4 and S6 are on main. **Contract (C §3, §3a,
  §3b; the X listing from S0; ruling 9 for its eight pictures):** DITL 191's seventeen items, the Player 1 / Player 2
  tab, key capture and key names from STR# 130, focus moving and wrapping, a key already used by either player
  refused with a beep, Caps Lock never bound, Save writes both sets into the live prefs, Cancel none.
  **Tests (8):** `testDITL191Parse` · `testCaptureNamesFromSTR130` · `testFocusAdvancesAndWraps` ·
  `testDuplicateAcrossPlayersRefused` · `testSameKeyInSameFieldAccepted` · `testModifiersOnlyLeftFour` ·
  `testTabSwitchRefillsFocus5` · `testSaveWritesBothSetsCancelNone`. **Gate:** G2 = base **+ 8**.
- **GP — the controller layout (+5), after CW.** **Contract (C §4; ruling 17):** the table of C §4 with question
  5's defaults; the play layout follows the live key set; a button held across a change of context does not fire.
  **Tests (5):** `testPlayLayoutFollowsKeySet` · `testOutOfPlayArrowsReturnEsc` · `testPlusIsCapsLockLatch` ·
  `testMinusHoldInPlayAtOnceElsewhere` · `testHeldButtonAcrossContextChangeDoesNotFire`.
  **Gate:** G2 = base **+ 13**; G5 with Aki and BubbleTroubleX (Package changed).

## S8a — the app — Seat: Fable

**Files:** `Deimos/App/*`, `project.yml`, `Host/DeimosDriver.swift`, `T/DeimosHostTests/{DriverTests,AppLifecycleTests}.swift`,
`Deimos/GAMEPAD.md` (new), any `FE/` file for an FX fix. **Needs:** S0–S7, all of them.
**Handoff:** `docs/handoff-deimos-phase4-s8a.md`.

- **AW — ⚑ MAJOR — the app (+3 host tests).** First step: state that wave 3.4 and every earlier section are on main.
  **Contract (D Part 2 §8, S15–S17, S25–S30; C §4, §5; rulings 9, 10, 12, 13):** mouse position, button and clicks
  into `HeldKeys`; typed characters with auto-repeat; the menu bar and its two commands; every quit path saves the
  settings (question 4); the settings and Last Film folder handed to the two stores, and the second tag-index root;
  the PICTs decoded and handed to Core; launch modifiers read at launch; the cursor, About, quit and question
  requests honoured (question 8); full screen at launch as ruling 13; the pad mapping assigned before each poll;
  `-film` and `-debugCapsLock` as ruling 10; the two data alerts through the shared refusal helper.
  **Tests (3):** `testQuitWritesSessionChanges` · `testFilmSwitchReturnsToMenu` · `testColdStartTimeline`
  (the whole cold start to the menu in ticks, A §1 and `front-end.md`'s worked example).
  **Gate:** G5 (all three apps); G2 = base **+ 3**; G4; G12. No launch.
- **FX — stragglers from S0's comparison** (only if a difference marked "changes what Phase 4 builds" was not built
  by its screen task): one task per screen file, tests re-specified under their names. At most three; more is a STOP
  and a new section. None found = said so in the handoff.

## S8b — goldens, stage, gate 4 — Seat: Fable

**Files:** `T/DeimosRenderTests/FrontEndGoldenTests.swift` (new), `tools/stage-deimos.sh`, `Deimos/WHAT-TO-EXPECT.md`,
`docs/deimos/*` (late bank notes), `docs/STATE.md`, `docs/DECISIONS.md`. **Needs:** S8a.
**Handoff:** `docs/handoff-deimos-phase4-s8b.md`.

- **GD — goldens (+8 → 477).** First step: state that wave 3.4 and S8a are on main. `testGoldenLoadingScreen` ·
  `testGoldenMenu` · `testGoldenLevelSelect` · `testGoldenScores` · `testGoldenNameEntry` · `testGoldenCredits` ·
  `testGoldenConfigWindow` · `testGoldenControlsWindow`, each a self-derived hash plus two pixel checks read from
  the source image. **Gate:** G2 = **477 / 0**.
- **ST — stage and the gate-4 card.** G1, G2 = 477, G3, G4, G5, G8, G12; then the seat's one cross-check over the
  phase's diff and the card; then staging (`tools/stage-deimos.sh` → `out/Deimos/`, `~/Desktop`); G9 only muted, in
  the daytime, with Ben's say-so. WHAT-TO-EXPECT in Ben's plain English: what Phase 4 is; rulings 1–17; the eight
  questions and what was built for each; what is still a stand-in (none planned — list any that remain); that
  coming back from another app shows the held picture at once (D S29); `GAMEPAD.md`. Late bank notes in one commit.
  **STOP for Ben.**

**The gate-4 card — "cold start → game → scores → quit"** (the ST implementer may tighten wording, not content)

1. **Starting up:** a loading screen with five lines, the publisher's logo with its sound, the developer's logo as
   the menu music starts, then the menu. Wrong: a game starting by itself, silence, a logo cut short.
2. **The menu:** buttons that light up and click under the mouse — 1 PLAYER, 2 PLAYER, PREFERENCES, SCORES, DEMOS,
   QUIT — and keys that do the same jobs: 1, N or Return; 2; P; H or S; D; Q. The bottom line changes every four
   seconds. Nothing starts if you leave it alone.
3. **Level select:** three previews, left and right to move, START on a sector you have reached and NO ACCESS on
   one you have not; a flash and zoom when you accept, a red message when you cannot.
4. **Coming back:** after game over, Esc or the finale: black, the background, the high-score table if you earned a
   place, then the menu with its music. Type your name; an empty name is a joke from the original.
5. **Demos and your last game:** DEMOS plays the four films in turn; a click or Esc ends one; F replays your last game.
6. **Credits** (About Deimos Rising… in the menu bar), page by page.
7. **Settings:** the PREFERENCES button, or Option held at launch; change the keys for both players in the controls
   window.
8. **A controller:** see `GAMEPAD.md`.
9. **Quit and reopen:** your scores, best sector, keys and volume are still there.
10. **Not certain:** how every screen looks against your memory (no picture of the original exists); the feel of
    the fades; the look of the two settings windows; anything where the OS X build differed from the OS 9 one we read.

---

## Self-review (the seat, after writing; revised after the two review legs)

- Every card of the remainder plan's Phase 4 paragraph has a task: boot and logos (BT), main menu (MM), level select
  and its flash (LS), scores and name entry (HS), credits (CR), attract mode and Last Film (DM, FR), prefs file (PF),
  configuration dialog (DG), controls window (CW), controller (GP), mouse in `HeldKeys` (SK-a, AW).
- Every stand-in of D Part 1 is placed: S1–S5 SR; S6, S7 LS and ruling 10; S8 the correction above and LS; S9, S10,
  S18 DM, SR and ruling 10; S11 PF and AW; S13 SK-a and DM; S14 SK-b; S15, S16 SK-a and AW; S17 SK-b; S19 FR; S20
  SK-a; S21 ruling 11; S22 BT; S23 the screens; S24 CW; S25 GP and AW; S26, S27 AW (ruling 10); S28 kept
  DEBUG-only; S29 on the card (ST); S30 S6 and AW. S12 was closed in Phase 3.
- The review legs' 37 findings are folded in: the skeleton split in two; the stub flow replaced by a direct start
  that stays; the result record and the seam list completed; the PICT route ruled; S0 moved ahead of every screen;
  the last section split; four rulings made conditional or turned into questions.
- Not planned here on purpose: the original's own gamepad windows; two pads; the whole-game comparison of the two
  builds; Windows (Phase 5).
