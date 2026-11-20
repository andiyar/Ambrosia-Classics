# Handoff — Deimos Rising Phase 4, section S5: Last Film and demos (closed 2026-11-20)

Seat: Claude Opus 5.5 (the plan's Opus tag). Helpers: Opus 5.5 (`fk-implementer`, `fk-reviewer`), foreground; one
implementer and two review legs (spec, then quality) per task. Section S5 of
`docs/superpowers/plans/2026-11-20-deimos-phase4.md` is done and on main.

## What a player would notice
Nothing yet: the app still opens straight into a game until S8a connects the mouse, the keys and the Last Film folder.
Underneath, every game played is recorded the way the original records it and kept as the Last Film; from the menu,
DEMOS or `D` plays the four demos in turn (the order lasts the app's whole life), `F` replays your last game, and a
mouse click or Esc ends a film. Other keys do nothing during a film, and Caps Lock does not pause it.

## What landed

| Commit | What |
|---|---|
| `b2fd7f1` | FR: the film recorder, the Last Film disk store, an optional second data folder for the tag index |
| `24764e3` | FR fix round: a test that the film records the current level (not the start level); unused code removed; the store refuses a file of the wrong size |
| `47b2a90` | DM: the demo cycle, the `F` key, the mouse ends a film |
| `6ce3227` | DM fix round: demos and `F` driven through the real menu and start/return; Caps Lock held during a film |

The recorder is byte-exact: a game fed demo 1's keys from seed 0x469c2 records demo 1's file, all 40,296 bytes.

## Gates, measured by the seat from the merge head (main merged in, S2, S3a and S4 included)

| Gate | Result |
|---|---|
| G2 `Deimos/Core` without the replay and campaign bundles | **433 / 0 / 0** (main 423 + FR 6 + DM 4) |
| G4 `DeimosReplayTests`; `deimos-replay --all` | **4 / 0**; four PASS lines, exit 0 (the recorder moves no film) |
| G8 `DeimosCampaignTests`, one test at a time | **3 / 0** (468 s, 291 s, 29 s) |
| G5 Deimos Debug and Release | both `** BUILD SUCCEEDED **` (Aki and BubbleTroubleX not built: no `project.yml` or kit change) |
| G12 the direct start | passes (inside G2) |
| G3 census, G7 layering, G10 clean tree | empty diff; prints nothing; clean |
| G1 | not run (no kit change) |

**G2 base for the next sections: 433** (plus whatever S6 adds when it merges).

## What the next sections need to know

- **The film leaves in the session's result** (`SessionResult.recordedFilm`, the full 0x9d68-byte image) for every
  non-film game, even one Esc'd before player 1 appeared (then frames are 0 and its replay ends at the first appear,
  as the original). The frame already keeps it in `state.lastFilm` and emits `saveLastFilm`.
- **`LastFilmFileStore`** (`DeimosHost/LastFilmStore.swift`) is the disk store of the frozen `LastFilmStore`
  protocol: `<root>/Local/film/Last Film[last].film`, root by default
  `~/Library/Application Support/Ambrosia Classics/Deimos Rising` (ruling 7). Nothing in the app uses it yet: **S8a**
  passes it to the driver and loads the assets with `DeimosAssets.load(dataDirectory:secondLocalRoot:)` pointed at the
  same root, so at the next launch the tag `last` finds the stored film over the shipped copy.
- **The mouse ends a film** from `HeldKeys.mouseButton`, sampled at the pass's start (the original reads the button
  live after the draw; at worst a film ends one pass late). **The app does not send the mouse button yet**
  (`Deimos/App/DeimosController.swift` ~286): S8a.
- `FrontEndState.recordedFilmForTests` (S1b's test-only field) is now unnecessary; its file is closed to S5. S8a may
  remove it.

## Departures from the card (the seat's rulings)

1. **Five existing tests outside the card's list were re-specified under their own names**, because the card changed
   what they pinned (they expected an empty recording, or Films as a stub):
   `DeimosSessionTests.testCursorHiddenAtSessionStart`, `FrontEndSkeletonTests.testStubScreensPassThrough` (twice: the
   Last Film lines, and the Films stub check dropped for a one-line note), `SessionResultTests
   .testSessionResultOnePlayerBothSlotsPresent`; plus one stale comment in `FilmPlaybackTests`. Expectations only; no
   names or counts changed.
2. **The demo-1 re-record test holds Esc with the last input byte**, not on the next frame as grounding B §8 worded it:
   the Esc pass still ticks and records (listing `1000591c` falls through to `10005920`), so this is the original's
   timing and gives the exact 4,810 frames. Grounding B §8's wording is loose, not the code.
3. **The two-player round trip ends in game over at 2,570 passes**, not the 3,000 the grounding suggested.
4. **The store type is `LastFilmFileStore`**: the frozen protocol already owns the name `LastFilmStore`.
5. **`DeimosAssets.load(dataDirectory:secondLocalRoot:)` is a separate overload** with no default, so it cannot clash
   with the app's own loader; every existing call is unchanged.

## Known and left (none blocks)

- The original cuts a tag name to 31 characters before looking for "Demo" (`FUN_10046510`, length 0x1f); the replica
  matches the whole name. No shipped tag is that long.
- An empty file named `Last Film[last].film` in the second folder hides the shipped copy and is then skipped, so `last`
  goes missing (the store writes atomically, so only a hand-made file can do this).
- The mouse test does not check that the ending pass draws the REPLAY banner; the order (check after the draw) is
  read from the listing, not pinned.
- `Films.swift` line 15 is over 120 characters (cosmetic).
- osx-build D13 (the OS X build keeps the pointer visible during a film) belongs to start/return / S8a, not built here.

## Worktree

`.claude/worktrees/sweet-grothendieck-34ce90` (branch `claude/sweet-grothendieck-34ce90`), removed at the close; it
held this section's four commits and three merges of main (all merged) and nothing else. Build products were in the
session scratch folder.
