# Handoff — Deimos Rising Phase 4, section S2: main menu, credits (closed 2026-11-20)

Seat: Claude Fable 5.2. Helpers: Opus 5.5 (`fk-implementer`, `fk-reviewer`), foreground. Section S2 of
`docs/superpowers/plans/2026-11-20-deimos-phase4.md` is done and on main. **S3a may start once S4 is also on main.**

## What a player would notice
Nothing yet. The app still opens straight into a game (see departure 1). Underneath, the main menu and the credits
screen are now the original's, driven and proved by tests; they appear on screen when the app section (S8a) connects
the mouse and keyboard to the front end.

## What landed

| Commit | What |
|---|---|
| `efc5271` | MM: the main menu (layout, idle pass, copyright flip, hover, click tracking, keys, suspend/resume, menu music, the three ways out) |
| `d902691` | MM fix round: the app left on its present start; four untested paths pinned; quit sequences counted exactly |
| `c8268eb` | CR: the credits screen |
| `e34fcb3` | fix round 2: the entry flush drops only what the original's does; input kept on a return pass; right Command; six untested paths pinned |
| `49d8cfb` | fix round 3: a queued About is flushed as a click; the menu's and credits' string lists must load |

Reviews: MM spec leg, MM quality leg, CR spec leg, CR quality leg (which also re-checked fix round 2); the seat's
cross-check at the merge head. Mutation runs: 22 + 10 on the menu, 13 + 7 on credits; every survivor on a reachable
path is now pinned by a named test.

## Gates, measured by the seat from the merge head

| Gate | Result |
|---|---|
| G2 `Deimos/Core` without the replay and campaign bundles | **402 / 0 / 0** (392 + 8 + 2) |
| G4 `DeimosReplayTests`; `deimos-replay --all` | **4 / 0**; four PASS lines, exit 0 |
| G5 Deimos Debug and Release | both `** BUILD SUCCEEDED **` (Aki and BubbleTroubleX not built: no `project.yml` or kit change) |
| G12 the direct start matches a bare session | passes (inside G2) |
| G3 census, G6 scope, G7 layering, G10 clean tree | empty diff; five files (see departure 2); prints nothing; clean |
| G1, G8 | not run (no kit change; G8 is for S1b, S5 and S8b) |

Main was merged in first (Ferazel-only commits since the section began; nothing of Deimos moved).

**G2 base for the next sections: 402** (392 + 8 menu + 2 credits). The phase's end figure does not move.

## What was read from the original (the three open facts of grounding A §9a, and one correction)

- **Item 4, lit and normal button art:** each lit frame is 5–6 px wider than its normal frame and the same height
  (25). No flicker; a lit button keeps the mouse 2–3 px past its normal edge. Built as the art is.
- **Item 6, the Command-key menu-title flash:** 5 ticks inside the event pump in both builds (L `10049080`,
  X `1004a3e0`); X builds the menu bar once (D7). Not modelled in Core: the Mac's own menu bar does it.
- **Item 8, the volume keys:** they skip the click sound and the flash in both builds (L `10023b3c`, X `10023f2c`).
  Built that way (settles ruling 11).
- **Item 5, the credits' last page — the plan was wrong.** The line reader returns "no line" for ANY empty line
  (L and X `10002fa8`). `stli cred` has 102 lines; line 99 is empty and sits inside page ten. So page ten ("Testers",
  lines 85–98) ends there and stays up for page nine's 420 ticks; the last `<page 420>` line and the trailing empty
  line are never read. Then fade-out, a 60-tick wait, and the return, with no sound. **There is no blank eleventh
  page.** Confirmed independently by the spec review leg.

## Departures from the plan's card (the seat's rulings; for the gate-4 card where marked)

1. **The app file was not changed** (the card named one change: a launch with no switch boots to the menu). The app
   does not yet send the front end mouse positions, mouse-downs or key events, and does not act on its quit request,
   so the menu could not be used and main would have stopped being playable. **S8a makes the switch together with
   the input wiring.** S3a's "delete `-players` and `-sector` from the app" has the same dependency. The
   Coordinator was told.
2. **`FrontEndSkeletonTests.swift` was edited** though it is outside S2's file list: three tests that assumed the
   placeholder menu starts a game by itself now press `1` (a shared helper), their quit cases count the real
   sequence (exactly 5 passes), and the credits placeholder check was removed (`CreditsTests` owns it). No assertion
   about a running game, quit or prefs was weakened. **S4 and later sections will meet the same test** when their
   screens stop finishing at once (`testStubScreensPassThrough` still checks Scores, NameEntry, LevelSelect, Films
   and the two windows as placeholders): remove your own screen's line there, nothing else.
3. **For the gate-4 card — no blank eleventh credits page** (above). Plan ruling 15 lists it as a quirk; it does not
   exist in either build.
4. **For the gate-4 card — element fades take 16 steps, not 32,** in the OS X build (`osx-build.md` D1), so the first
   credits page is fully in at entry + 76 ticks, not + 92, and a full run of the credits is about 3,660 ticks.
5. **The quit flag is kept at menu entry** though both builds clear it there (X `10022be8`): in the original a Quit
   chosen during the boot is still waiting in the event queue and the menu then reads it; here the frame has already
   turned it into the flag.
6. **A Quit chosen during the credits takes effect when the credits end** (up to about a minute). The OS X build
   probably loses that Quit altogether (medium confidence). Left for Ben's card with question 4 (Command-Q in a game).
7. **Each credits page can start up to one tick late** (about 10 ticks over the run): the frame reads the clock at
   the start of a pass, never at the end of a fade.

## How the two screens sit in the frame (for S3a, S5, S6, S8a)

- **The menu owns the fades around every screen it calls.** Before a call it fades `state.menuElements` out; after
  SCORES and credits it flushes keys and clicks, redraws the background and fades back in. After a game, a demo or
  the settings window it does NOT flush (the original does not), so input typed on the return pass reaches the menu.
- **The flush drops keys, mouse-downs and a menu-bar About** (a click in the OS X build, D23); it lets suspend,
  resume and the system Quit request through, as `FlushEvents(0xffff)` does.
- **What the menu calls:** `StartReturn(mode: .play, players: 1 or 2)`; `ConfigDialog(firstLaunch: false)`;
  `Scores()`; `Films(kind: .demo)` for DEMOS / `D`; `Films(kind: .lastFilm)` for `F`; `Credits()`; and, when
  `Scores` or `Credits` returns `.newGame`, a one-player game. The `-film` argument plays once as soon as the menu
  is up. None of the frozen entries changed.
- **Shared state the menu uses:** `menuElements`, `menuLit`, `menuMusic`, `copyrightClock`, `quit`, `leave`,
  `suspended`, `musicAlive`; the banner name is `FrontEndState.registeredName`.
- **Credits** reads the click, any key, and About as a click; it leaves the menu music alone.

## Known and left (none blocks the next sections)

- **For S8a:** after a system Quit arrives while the app is suspended, the menu clears the shared suspended flag but
  the driver keeps its own (a closed file, no channel). A later suspend then skips the music pause and a later
  resume resumes the music once more. Unreachable until the app sends the menu events; fix in the driver when S8a
  opens it.
- **For S8a:** the menu-bar strip is taken as 22 px high (the OS X menu bar; medium confidence).
- **For S8a:** the tests of "input kept on a return pass" call the menu directly; through the frame, input on the
  pass where a callee that draws nothing finishes goes to that callee. Check it end to end once real screens exist.
- A resume and a suspend arriving in the same pass would leave the music playing while suspended; the app sends at
  most one per pass.
- The order of queued events across kinds (About, then keys, then clicks) is fixed by the input seam, not by arrival:
  a click followed by `N` during a credits page change starts a game where the original would leave.
- Option-click on SCORES (erase all scores) is S4's.
- Credits' page-number reader handles hex, octal, negative and missing numbers as the original's `sscanf` does;
  the shipped data never uses them, so those branches have no test.

## Worktree

`.claude/worktrees/nice-cerf-6df5b0` (branch `claude/nice-cerf-6df5b0`), removed at the close; it held this section's
five commits and the merge (all on main) and nothing else. Build products were in a temporary folder outside it.
