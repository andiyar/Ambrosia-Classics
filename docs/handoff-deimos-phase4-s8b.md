# Handoff — Deimos Rising Phase 4, section S8b: goldens, stage, gate 4 (closed 2026-11-21)

Section S8b of `docs/superpowers/plans/2026-11-20-deimos-phase4.md` is done and on main. Seat: Fable 5.2; every
build and review leg was Opus 5.5. S8a and every earlier section were on main before the first dispatch. **Phase 4
is built; STOP for Ben's gate 4** ("cold start → game → scores → quit"), with gates 2 and 3 on the same app.

## What a player would notice
One change since S8a: **Command-Q now quits from the Caps Lock pause** (Ben's answer A5). In play it still does
nothing. Paused, it quits at once: it saves the settings and the high-score table as it stood, but **the game the
player was in the middle of earns no high score and opens no new sector** (what the OS X original does; Ben may
overturn it). The level select's own Caps Lock pause also takes Command-Q at once (before, it waited until Caps
Lock was released; the seat's call). A Command-Q pressed during play is never acted on at a later pause; a quit
asked by macOS (the Dock, a log-out) during a Caps Lock pause quits at once; a demo cannot be paused, so in a demo
Command-Q does nothing. Everything else is as S8a left it. The app is staged on the Desktop with the gate-4 card and
the controller guide (`Deimos Rising — GAMEPAD.md`) beside it.

## What landed (branch `claude/goofy-solomon-8176b0`, merged to main)

| Commit | What |
|---|---|
| `8d52eeb` | QP — Command-Q quits from a game's Caps Lock pause (a film cannot be paused); one pressed in play is dropped at the pause's flush and never remembered; the level select's pause leaves a Command-Q to the level select (`FrontEnd.swift`, `DeimosDriver.swift`, `DriverTests`, `FrontEndSkeletonTests`) |
| `e4c758b` | GD — eight front-end frame goldens in `Deimos/Core/Tests/DeimosRenderTests/FrontEndGoldenTests.swift` (below) |
| this commit | the gate-4 card (`Deimos/WHAT-TO-EXPECT.md`), `docs/STATE.md`, `docs/DECISIONS.md` D58, this handoff |

**The goldens** (each the replica's own frame hashed, backed by pixel checks read from the source images; they catch
change, not error — no picture of the original's screens exists):
1. Loading screen, two frames: a first launch (unit names showing) and a later launch (the four lines, all "Done").
2. Main menu, settled (copyright line, nothing lit).
3. Level select, three frames: settled, the accept flash, the fail flash ("Sector Not Reached").
4. High scores: the fresh default table.
5. Name entry: "DEIMOS_" with the cursor shown.
6. Credits: page one.
7. Configuration window, with one Geneva 9 glyph (an "S") pinned.
8. Controls window, Player 1 tab, with made-up pictures handed in.

**The card.** `Deimos/WHAT-TO-EXPECT.md` now leads with gate 4: what Phase 4 is and its launch status; ten steps to
try; Ben's answers as built (13 rows); every ruling the sessions made, numbered (60) and grouped by screen; the known
gaps and faults (15); what only his eyes can prove; the controller (pointing to `Deimos/GAMEPAD.md`); the hidden
switches and file locations. The gate-3 and gate-2 cards follow, trimmed where the front end replaced their
stand-ins (`-players` / `-sector` gone, Esc and game over back to the menu, keys now changeable).

## Gates, measured by the seat at the branch tip

| Gate | Result |
|---|---|
| G1 HectorKit zero-skip | executed 370, 0 failed, the 4 known Aki 1.1 data skips (kit main ef2c341, unchanged) |
| G2 `Deimos/Core` without replay and campaign tests | **491 / 0 / 0** (base 483 + 8 goldens = 491 expected) |
| G3 census | unchanged |
| G4 replay tests; `deimos-replay` de01–de04 | 4 / 0; four PASS lines, exit 0 |
| G5 builds | Deimos Debug and Release, Aki, BubbleTroubleX: all BUILD SUCCEEDED |
| G8 campaign, one test at a time | 3 / 0 (about 8 minutes for the longest) |
| G9 first launch (muted, daytime, Ben's say-so) | NOT DONE. The app has never been launched. The question (mailbox Q6: may the section launch it once, muted?) had no answer by the close, so its default applied: Ben launches it first |
| G12 the direct start | passes (inside G2) |

## What review caught
- **Command-Q from the pause:** both review legs passed it but found three behaviours no test pinned (a Command-Q pressed before the pause must not fire at it; a system quit request waiting at that moment must still quit; resume-first when the app is in the background). The fix round pinned all three and proved each with a deliberately broken build. The quality leg also found the level select's own pause held a Command-Q until Caps Lock was let go; the seat ruled it quits at once there too, like the game's pause (on the card for Ben).
- **The goldens:** every deliberate change to a screen was caught by its hash, but several of the "two pixel checks" only looked at background, and the name-entry frame showed a table the app can never show. The fix round rebuilt name entry through the real score insertion and put checks on drawn things (ship sprite, headings, the flash blend, the loading lines' text).
- **The fix rounds themselves had no second review pass** (the seat was near its cap); the seat re-ran every gate at the tip instead.

**The card review** (checked against the code) caught three wrong statements and a dozen smaller ones, all fixed in
the card fix round. First, the card said only the accuracy and funds cheats counted as cheating and suggested the
life and shield cheats to reach the finale; in the code every console cheat marks the game as cheated, and a cheated
game opens no sectors and makes no high score. Second, it never said that the very first launch opens full screen
(a new settings file has Full Screen ticked); the card now says so and how to get a window. Third, it said a quit
from the pause saves "settings and scores" without saying that the game in progress earns no high score and opens no
sector; every place now says so. Smaller fixes: the menu's volume keys are the letters ù and ä, not − and =; Cancel
is greyed when the settings window opens on Option at launch too; the missing pause cursor added to the gaps; the
later-launch and muted loading lines described truthfully; a mistyped `-film` quits after its alert; plain words for
the technical faults. The review confirmed the card's start-up order (the two logos, then the loading screen); the
plan's card and the S8a handoff had it the wrong way round (D58 departure 15).

## The cross-check
**Reduced, and Ben should know it.** The plan asks for one Fable cross-check over the whole phase's diff and the card. The seat started this section at 154k of its 300k cap (the reading list alone), so what it did itself was: re-run every gate from the branch tip (table above); audit this section's diff file by file (twelve files, all in the section's list plus the three the Command-Q change needed); look at the menu frame; read the card's outline. The card was checked line by line against the code by an Opus leg instead (it found one false claim and five missing items, all fixed). **Not done: a Fable read of the whole phase's diff.** Each earlier section had its own cross-check or two review legs. A fresh session can run the whole-phase read if Ben wants it before or after his gate.

## Staged
`~/Desktop/Deimos Rising.app`, with `Deimos Rising — WHAT-TO-EXPECT.md` and `Deimos Rising — GAMEPAD.md` beside it; the same three in `out/Deimos/` of the main checkout. Release build, ad-hoc signed, from the section's tip. Never launched.

## Left — precisely (carried from S8a; none blocks Ben's gate)
1. **A narrow fault, known:** with the erase question up, switch to another app and back; the leaving and returning
   events stay queued in the menu through the scores screen, and a Quit chosen afterwards flashes QUIT before the
   menu handles the queued "resume", leaving both suspended flags set. The test
   `testAppSwitchDuringEraseQuestionKeepsMusicPaused` still hands the events in the old order. The cause is in
   `FrontEnd/MainMenu.swift` (the menu's event queue across the scores call). Not fixed.
2. **The original's pause screen on leaving the app** (OS X build D11: effects stop, the Paused sound, the pause
   picture, the cursor shown) is not built; the game is only held still. It needs the frame controller's paused-frame
   hook to open the pause on a suspend without the Caps Lock notice, the same in the level select, and the app to
   keep passing until that frame reaches its wait. Following from it: a quit request from macOS during play waits
   until the player returns; the original's pause lets go, ends the game and quits. Also not built: the OS X build's
   cursor shown during a game's Caps Lock pause (`osx-build.md` D12; S0 handoff item 8).
3. **The OS X build's "Preferences…" menu-bar item and its Edit menu** are not built: Preferences needs a new shell
   event, which is a seam change.
4. From earlier handoffs, still open: the pressed 1 PLAYER / 2 PLAYER button drawn lit one or two passes too long on
   the way back (S3a item 3); the menu loading `back` into a level-map-sized save buffer (S3b follow-up);
   `FrontEndState.recordedFilmForTests` is unused and can go (S5); input on the pass where a screen that draws
   nothing finishes (S2).
5. Small: a key with no character is sent as a key event with character 0; the background pump's bound (2,400
   turns) assumes macOS does not slow the app's timer in the background; a quit request during the boot can play
   the logo sound in the background; no test for an unreadable settings file or for a sector chosen after a Quit at
   the level select.
6. **Not provable without a launch:** clicks and their scaling, full screen at launch, the alert above full screen,
   a real pad, the background quit, the look of everything.
7. New in S8b: (a) the whole-phase Fable cross-check (see above); (b) the first launch and whatever it shows; (c) `FrontEnd.levelSelectPaused` may never read true, because the paused flag is cleared before the wait, so the controller's "paused on the level select" layout may never apply (found by the fix leg, not fixed); (d) the menu's two volume keys are the characters ù and ä and change a stored value nothing applies to the sound, as read from the code (on the card); (e) the plan's gate-4 card and the S8a handoff had the start-up order wrong: the code shows the two logos first, then the loading screen.

## Worktree
`.claude/worktrees/goofy-solomon-8176b0` (branch `claude/goofy-solomon-8176b0`), removed at the close; it held this section's commits (all on main) and a staged copy of the app under `out/` (copied to the main checkout first). Build products were in the session's scratch folder.
