# Handoff — Deimos Rising Phase 4, section S3a: starting a game and coming back (closed 2026-11-20)

Seat: Claude Fable 5.2. Helpers: Opus 5.5 (`fk-implementer`, `fk-reviewer`), foreground. Section S3a of
`docs/superpowers/plans/2026-11-20-deimos-phase4.md` is done and on main. **S3b (level select) may start.**

## What a player would notice
Nothing yet: the app still opens straight into a game. Underneath, choosing 1 PLAYER or 2 PLAYER on the menu now runs
the original's start (the menu fades out, the transition sound, a fade to black, the level-select music, the level
select) and a game's end runs the original's way back (fade out, the menu background fades in, the high-score entry
when a score makes the table, the menu fades back in and its music restarts). It appears on screen when the app
section (S8a) connects the mouse and keyboard to the front end.

## What landed

| Commit | What |
|---|---|
| `6907645` | SR: the start and return sequences in `FE/StartReturn.swift`; 7 tests in `StartReturnTests` |
| `aa321ca` | SR fix round: the sector-2 boundary, the unlit button, grounding B's worked example and a game that cannot be built are now pinned; a bounds guard |

One implementer, two review legs (spec against both builds' listings; quality with 38 mutations, 33 caught, the two
reachable survivors now pinned), one fix round, and the seat's cross-check (the code read against grounding B §1a–§1d;
every gate re-measured by the seat).

## Gates, measured by the seat at the branch tip (main had not moved)

| Gate | Result |
|---|---|
| G2 `Deimos/Core` without the replay and campaign bundles | **423 / 0 / 0** (416 + 7) |
| G4 `DeimosReplayTests`; `deimos-replay --all` | **4 / 0**; four PASS lines, exit 0 |
| G5 Deimos Debug and Release | both `** BUILD SUCCEEDED **` (Aki, BubbleTroubleX not built: no `project.yml` or kit change) |
| G12 the direct start matches a bare session | passes (inside G2) |
| G3 census, G7 layering, G10 clean tree | empty diff; prints nothing; clean |
| G6 scope | `StartReturn.swift`, `StartReturnTests.swift`, plus `FrontEndSkeletonTests.swift` (below) |
| G1, G8 | not run (no kit change; G8 is for S1b, S5 and S8b) |

**G2 base for the next sections: 423** (S5 adds its own; whoever merges second measures the sum).

## Two parts of S3a NOT done — open items for S8a (waiting on Ben, mailbox Q1)

1. **`-players` and `-sector` are still in the app** (plan ruling 10 and the S3a Files line say S3a deletes them). The
   app cannot reach the menu until S8a wires its input, so deleting them now would leave no way to start a two-player
   game or a later sector. The Coordinator put this to Ben and told S3a to leave the switches in place if no answer
   came before the close; none came. **S8a deletes them together with the input wiring**, unless Ben says otherwise.
2. **The "erase high scores?" question is still not asked by the menu** (the S2 handoff left it to S3a; it lives in
   `FE/MainMenu.swift`, which is not in S3a's file list). Same instruction from the Coordinator, same outcome.
   What to build is in the S2 handoff ("Left for S3a") and the S4 handoff ("The seat's ruling"): on a SCORES click with
   Option held (mouse only), suspend, ask `HighScoreTable.eraseQuestion(_:)`, apply `HighScoreTable.erase(_:answer:)`,
   resume, then the SCORES action as today.

## How start-and-return was built (what the next reader needs)

- **Frozen entries unchanged:** `StartReturn(mode:players:film:)`, `StartReturn(direct:)`, the pass signature, the
  result (`SessionResult?`, nil when the level select was cancelled). The direct start behaves exactly as before.
- **The start, pass by pass:** (1) play only: menu music paused, cursor hidden; present; the menu's elements fade out.
  (2) the transition sound, fade to black. (3) play: music stopped, the level-select music started looping, the level
  select called; a film: its game starts. The game after a level select starts with "music already playing".
- **The way back:** the gates, then (a game ran) the 33-step fade to black, the `back` picture, the 9-step fade in.
  Then either the table path (transition sound, insertion, name entry — `player2Slot` set when both players placed —
  cursor, menu fade-in, one more pass for the second flush) or the plain path (transition sound unless a film, menu
  fade-in, cursor). The menu-music flag is set on every path but a film's, so menu music plays on under a film.
- **The gates** follow the listing: best sector into pref 3 only for a game from sector 1 that was not cheated, not a
  film and not quit; the finale gives 12, otherwise best minus one, at least 1. Esc still reaches the table.
- **Follows the OS X build:** no About on/off, no menu-bar rebuild, no hidden cursor for a film (`osx-build.md` D7, D9, D13).
- **Last Film is not saved here.** One comment in `comeBack` marks where the original does it; S5 owns it.
- **A game that cannot be built** (no original counterpart): from the menu a play game returns as if the level select
  were cancelled, a film as if its film failed to load.

## Departures and known differences (for the gate-4 card where marked; none blocks the next sections)

1. **`FrontEndSkeletonTests.swift`** (not in S3a's file list) was edited, as S2 and S4 did: its helpers step through
   the longer start and return, the cursor check moved to the start's first pass, the music reference gained the
   start's stop and level-select music. No assertion about a running game, quit or prefs was weakened; one helper now
   accepts up to four passes for the return where it asserted one (the exact count is pinned in `StartReturnTests`).
2. **For the gate-4 card — keys typed during the fades on the way back are dropped** when no score made the table; the
   original's menu would read them afterwards. The frame hands a pass's input only to that pass's first step.
3. **For the gate-4 card — after a click on 1 PLAYER or 2 PLAYER, the pressed button is drawn lit for one or two
   passes longer on the way back** than in the original (which rebuilds the list unlit at once). Keys are unaffected.
   The fix is in `MainMenu.swift` (rebuild the list when a click's tracking unlights the button); for S8a or a fix wave.
4. The cursor is shown in the same pass as the menu's fade-in, so before it; the original shows it after. S2's convention.
5. The table condition tests the cheat and the quit flag a second time, as the listing does (`1002383c`, `1002385c`),
   though the gates already cover both.

## For S3b (level select) — the brief

You own `FE/LevelSelect.swift` (today a stub that returns sector 1) and the files the plan's S3b section lists; read
that section, the plan's verification model and rulings 14 and 15, grounding A §7, and `docs/deimos/osx-build.md`.
What start-and-return gives you and expects back:
- It calls `LevelSelect()` on the pass after the fade to black, with the level-select music (`ammu`) already started
  and the screen black. It expects `.levelSelect(sector)` back: a sector number, or nil for Esc (cancelled).
- On nil it stops the music, fades the `back` picture in with no fade-out, and returns to the menu. On a sector it
  starts the game with "music already playing"; a sector above 1 turns the post-game gates off (no pref 3, no table).
- When your screen stops finishing at once, `FrontEndSkeletonTests.testStubScreensPassThrough` still lists LevelSelect
  as a placeholder: remove your own line there, nothing else. `StartReturnTests` drives the stub's sector 1; if your
  real screen needs input to return, the tests' helper that steps through the level select will need the key press
  (expect to touch `StartReturnTests.swift` and the skeleton helpers for that, and say so).
- G2 base is 423 plus whatever S5 has merged; measure it.

## Worktree

`.claude/worktrees/peaceful-leakey-1dc149` (branch `claude/peaceful-leakey-1dc149`), removed at the close; it held this
section's two commits and this handoff (all on main) and nothing else. Build products were in the session scratch folder.
