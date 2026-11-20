# Handoff — Deimos Rising Phase 4, section S8a: the app (closed 2026-11-20)

Section S8a of `docs/superpowers/plans/2026-11-20-deimos-phase4.md` is done and on main. Seat: Fable 5.2; every
build and review leg was Opus 5.5. Wave 3.4 and every earlier section (S0–S7) were on main before the first
dispatch. **S8b may start.**

## What a player would notice
The app now starts as the original does: a loading screen, the publisher's logo with its sound, the developer's logo
as the menu music starts, then the main menu. From the menu the mouse and the keys reach everything that Phase 4
built: a one- or two-player game through the level select, the high scores and name entry on the way back, the demos,
the last game's replay (F), the credits (About Deimos Rising… in the menu bar), the settings window and the controls
window, a controller, and Quit, which saves the settings and the scores. **Nobody has seen any of this yet: the app
has not been launched** (the plan's rule; the first launch is S8b's, muted, in the daytime, with Ben's say-so).

## What landed (branch `claude/confident-lumiere-30c7fe`, merged to main)
Two tasks, each one build leg, a spec review and a quality review, with fix rounds.

**CR — three of Ben's rulings, in Core** (commits 02ea9f6, 6eb79fa, bf0c6ac):
- **The "erase high scores?" question** (mailbox A1 a): Option held and a click on SCORES asks it as a normal macOS
  alert, erases on "Erase", then opens the scores as usual. Mouse only, left Option only, as the original
  (L `10022d9c..10022de4`).
- **Unit names on the first launch only** (mailbox A3): `FrontEnd(… firstLaunch:)`; the app passes "no settings file
  existed" (`PrefsStore.fileExisted`). A later launch shows four lines (images, sounds, weapons, players).

  | Loading-screen updates | First launch | Later launch |
  |---|---|---|
  | with sound | 432 | 44 |
  | without sound | 412 | 24 |

  The menu is up on the sixth front-end pass either way.
- **Command-Q in a game is ignored** (Ben's answer to question 4). By screen:

  | Screen | Command-Q / the menu-bar Quit / the close button | macOS asking to quit (Dock, log-out) |
  |---|---|---|
  | main menu | quits (the QUIT flash, then saves) | quits |
  | level select | quits | quits |
  | everything else (boot, game, pause, film, scores, name entry, credits, both settings windows) | nothing | remembered; quits when the menu is next up; lets a Caps Lock pause go |

**AW — the app** (5e164fe, da04ab2, 812a0e4, 6668ad3; fixes 6f48f07, 1dde879, e589057, 5cb0a19, 8b58927):
- A plain launch boots to the menu. **`-players` and `-sector` are deleted** (mailbox A1 b). `-film deNN` stays
  (plays after the boot, returns to the menu; a bad value shows the refusal alert in Release too). `-debugCapsLock`
  stays DEBUG-only.
- Mouse position, button and clicks (in the game's 640×480 picture at any window size or full screen), key events
  with auto-repeat, typed characters, Option at launch, About, Quit, leaving and returning, and the alert's answer all
  reach the front end. Every shell request is honoured: cursor, About on/off, quit, save Last Film, ask, beep.
- The settings folder and the Last Film folder are the ruled ones (rulings 6, 7); every quit path saves once.
- The app reads `Deimos Rising.rsrc`, hands its resources to Core and decodes PICT 1000 and 190–197 with HectorKit.
- Full screen at launch as ruling 13; if full screen cannot be entered the window is still shown.
- **The controller:** the layout is chosen before each poll by the screen on top; held pad buttons make no key
  repeats; **the pad is switched off while the controls window is up** (seat's ruling, so a pad press cannot be
  bound as a key). `Deimos/GAMEPAD.md` is written for a player.
- **A new launch switch `-mute`** (or the environment variable `DEIMOS_MUTE`): opens no sound output and takes the
  original's own no-sound path, so the publisher logo does not wait for a sound that never ends. This is what S8b's
  muted first launch uses. It is a different boot from a real one (no logo sound, fewer loading lines).
- **Leaving the app holds a running game** until you return (the driver starts no new frame while away; OS X build
  D11, the driver's part only — see "Left").
- New file `Deimos/Core/Sources/DeimosHost/ShellGlue.swift` holds the app logic a test can reach (pad context,
  pictures, the background-quit pump). `FrontEnd.swift` gained read-only properties (`levelSelectPaused`,
  `quitRequestPending`), no frozen signature changed. `project.yml`: the Deimos app now links HectorGraphics and
  HectorInput. HectorKit itself is unchanged.

## Gates, measured by the seat at the branch tip (main had not moved: base a5e5e71)
| Gate | Result |
|---|---|
| G2 `Deimos/Core` without replay and campaign tests | **483 / 0 / 0** (base 467; +7 CR, +9 AW) |
| G4 replay tests; `deimos-replay` de01–de04 | 4 / 0; four PASS lines |
| G5 builds | Deimos Debug and Release, Aki, BubbleTroubleX: all BUILD SUCCEEDED |
| G7 layering grep | prints nothing |
| G10 clean tree | clean |
| G12 the direct start | passes |

G8 (campaign) was not run: the plan runs it at S1b, S5 and S8b only. G1 (HectorKit) was not run: the kit is unchanged.

**The ladder for S8b:** the base is **483**, not 469. With the eight goldens the phase ends at **491**, not the
plan's 477. The sixteen new tests: `testScoresClickWithOptionAsksErase`, `testScoresKeyWithOptionDoesNotAsk`,
`testLaterLaunchSkipsUnitNames`, `testFileExistedReportsFirstLaunch`, `testQuitChosenIgnoredInGame`,
`testQuitRequestedWaitsForMenu`, `testQuitChosenAtMenuStillQuits`, `testQuitWritesSessionChanges`,
`testFilmSwitchReturnsToMenu`, `testColdStartTimeline`, `testAppSwitchDuringEraseQuestionKeepsMusicPaused`,
`testBackgroundQuitPumpStops`, `testLeavingTheAppPausesTheGame`, `testBackgroundQuitWhilePausedQuits`, and two
helper tests in `AppLifecycleTests` (pad context and keys; pictures). Re-specified under their names (CR):
`testQuitRequestReachesFrontEnd`, `testQuitInsideCapsLockWait`.

## FX — stragglers from S0's comparison
None was built as its own task. Two differences of the OS X build surfaced and are listed under "Left".

## What review caught
- Switching apps while the erase question was up would have restarted the music early (fixed in the driver).
- A quit request from macOS arriving while the game was in the background at the level select would have left the
  game running unseen, reading the mouse (fixed: the background pump stops, and gets no live input).
- Quit from the Dock while paused in the background did not quit (fixed).

## For the gate-4 card (S8b: carry each of these; Ben may overturn each)
1. **Command-Q while PAUSED does nothing.** The OS X build probably lets it quit there (medium confidence). Mailbox
   Q5 (a), no answer yet.
2. **A quit request from macOS is remembered** until the menu; the original loses it on the scores, name entry,
   credits and loading screens. Mailbox Q5 (b), no answer yet.
3. **On the scores, name entry and credits screens the OS X build reads Command-Q as a plain "q" key** (closes an
   any-key screen, types a q in a name). The replica drops it.
4. **"About Deimos Rising…" is never greyed**, as the OS X build (its D9) — plan ruling 12 said greyed in a game.
   An About chosen in the middle of a game does nothing.
5. **The window has a close button**, which acts as Command-Q (so it does nothing in a game). The original window
   had none.
6. **While a log-out or shut-down is asked for, the app always answers "not now"** and quits by itself once the menu
   is up; macOS may need the log-out asked again.
7. **`-mute` exists** (see above).
8. **The pad is off in the controls window.**
9. The cold-start test pins the tick at which the menu appears (946 / 822 / 749 by case); those figures are the
   replica's own at its 4 ms polling, only their lower bounds come from the original.

## Left — precisely (none blocks S8b's goldens; a follow-up section or a fix wave)
1. **A narrow fault, known:** with the erase question up, switch to another app and back; the leaving and returning
   events stay queued in the menu through the scores screen, and a Quit chosen afterwards flashes QUIT before the
   menu handles the queued "resume", leaving both suspended flags set. Found when a test was made to hand events in
   the app's real order; the test `testAppSwitchDuringEraseQuestionKeepsMusicPaused` still hands them the old way.
   The cause is in `FrontEnd/MainMenu.swift` (the menu's event queue across the scores call). Not fixed.
2. **The original's pause screen on leaving the app** (OS X build D11: effects stop, the Paused sound, the pause
   picture, the cursor shown) is not built; the game is only held still. It needs the frame controller's
   paused-frame hook (`FrameKeys.endFrameWrapper` / `pauseScreen`) to open the pause on a suspend without the Caps
   Lock notice, the same in the level select, and the app to keep passing until that frame reaches its wait.
   Following from it: a quit request from macOS during play waits until the player returns; the original's pause
   lets go, ends the game and quits.
3. **The OS X build's "Preferences…" menu-bar item and its Edit menu** are not built: Preferences needs a new shell
   event, which is a seam change.
4. From earlier handoffs, still open: the pressed 1 PLAYER / 2 PLAYER button drawn lit one or two passes too long on
   the way back (S3a item 3); the menu loading `back` into a level-map-sized save buffer (S3b follow-up);
   `FrontEndState.recordedFilmForTests` is unused and can go (S5); input on the pass where a screen that draws
   nothing finishes (S2).
5. Small: a key with no character is sent as a key event with character 0; the background pump's bound (2,400
   turns) assumes macOS does not slow the app's timer in the background; a quit request during the boot can play
   the logo sound in the background; no test for an unreadable settings file or for a sector chosen after a Quit
   at the level select.
6. **Not provable without a launch:** clicks and their scaling, full screen at launch, the alert above full screen,
   a real pad, the background quit, the look of everything.

## Brief for S8b (goldens, stage, gate 4) — from nothing
You are the orchestrator for section S8b of Deimos Rising Phase 4 in `~/Developer/Ambrosia-Classics`. Read
`CLAUDE.md`, `docs/STATE.md`, the plan `docs/superpowers/plans/2026-11-20-deimos-phase4.md` (verification model,
rulings, the "S8b" section and the gate-4 card under it), this file, and the whole mailbox
`~/.claude/coordinator-notes/deimos-phase4-mailbox.md` once (Ben's answers; Q5 from S8a may have an answer by now —
if it has, it is a small change in `FrontEnd/FrontEnd.swift` and the driver's pause predicate, to do before the
goldens). Method: `~/Developer/Toolkits/fable-kit/orchestrator.md` under the Coordinator's overrides.

- **GD — eight goldens** in a new `Deimos/Core/Tests/DeimosRenderTests/FrontEndGoldenTests.swift`, as the plan
  lists them. **Gate G2 = 491 / 0** (base 483). Add what earlier sections asked of the goldens: one accept and one
  fail flash frame of the level select (S3b); a glyph of the Geneva 9 font through `testGoldenConfigWindow` (S6).
  For the loading screen say which launch the golden shows (first launch lists unit names; a later one has four
  lines). Pictures for the two settings windows come from `ShellGlue` / `DeimosAssets.shellPictures`; headless tests
  hand in made-up images or read `Resources/Deimos/Deimos Rising.rsrc`.
- **ST — stage and the gate-4 card.** Gates G1, G2 = 491, G3, G4, G5, G8 (campaign, one test at a time), G12; then
  the Fable cross-check over the whole phase's diff and the card; then `tools/stage-deimos.sh` → `out/Deimos/` and
  the Desktop. **G9, the first launch ever of this front end, only muted (`-mute`), in the daytime, with Ben's
  say-so**; expect first-launch faults that no test could see (the "Not provable" list above) and budget a fix round.
  `Deimos/WHAT-TO-EXPECT.md` in Ben's plain English: the plan's card, rulings 1–17, the eight questions with what was
  built (question 4 is now "ignored, as the original"; question 7 is now "first launch only"), the gate-4 card items
  from every handoff (S2, S3a, S3b, S4, S5, S6, S7 and the nine above), the "Left" list above, `Deimos/GAMEPAD.md`,
  and the S3b correction (the right-hand preview does draw its hover outline). Update `docs/STATE.md` and
  `docs/DECISIONS.md`. Then STOP for Ben's gate 4.
- The plan's "phase ends at 477" and "five lines" on the gate-4 card's first step are stale: 491, and four lines
  after the first launch.

## Worktree
`.claude/worktrees/confident-lumiere-30c7fe` (branch `claude/confident-lumiere-30c7fe`), removed at the close; it
held this section's commits (all on main) and nothing else. Build products were in a temporary folder outside it.
