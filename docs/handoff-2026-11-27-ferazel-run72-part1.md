# Handoff — Ferazel's Wand, run 72 part 1 (2026-11-27)

**Seat:** Fable 5.2, started by another session; foreground only.
**Times:** started 2026-11-26 20:59, closed 2026-11-27 about 01:30 (Sydney) — night; nothing was launched.
**Context:** 106k at the start, 216k when the checks were done. Weekly limit: 89% → 92% (all models), 72% → 74% Fable.
The chip said to wait for the weekly reset; Ben said to proceed (D73.4).

## What is now true
- **The level chooser is on main (b7be967, pushed).** On the main menu, press **L**: a message box says "New Game
  will start at level 3, Western Reaches. Press L again for the next level." Each press steps to the next built
  level (1, 2, 3, 4, 5, 10, 11, 15, 18, 20, 21, 22, then 1 again); New Game then starts there. Same on Windows.
  It lasts until the game quits. Loading a saved game ignores it. A gamepad cannot press L.
- It was built by one helper and checked by two. The second planted 29 deliberate bugs: the tests caught 25, and
  the two gaps that mattered are closed by new tests. The fix round changed tests and comments only.
- **Stale "to do later" notes in the code are corrected** (six of them), and the two documents that still called
  the magic carpet unbuilt are fixed.
- **The 6A card is written** in both files (4b06fc9, on branch `claude/gracious-volhard-286877`, not yet on main).
  Four lines are placeholders (`<<SEAT: …>>`) for results that need a launch; the staging scripts refuse to run
  until they are filled.
- **Every check that needs no launch passed at b7be967:**

  | check | result |
  |---|---|
  | Game-side suite | 823 (821 passed, 0 failed, the 2 named skips) |
  | Windows-side suite | 91 (89 passed, 0 failed, the 2 named skips) |
  | census, Mac app build, both Windows cross-builds, Mac SDL build | all pass |
  | every-object sweep, 12 levels | 11,864 visits on each path, no problems |
  | random-play bot, 12 levels | 259,200 steps on each path, 0 failures |

## Why it stopped here
Two things. The four start-up checks may only run between 09:00 and 21:00, and it was night. And the whole-phase
review, which comes before staging, would not fit in this seat's remaining context. So nothing was staged: part 2
stages once, after the review, with the launch results on the card inside the builds.

## For part 2 (the chip is `docs/NEXT.md`)
- Work in this same worktree and branch (`gracious-volhard-286877`); it holds the card commit and the docs of
  this close. Its `.build` folders are warm at b7be967.
- The part-runner pattern that kept each check to one line: a small script that runs
  `swift test --skip-build --filter …`, logs to a file, and prints only passed / failed / skipped / exit / time.
  The filters and times are in the plan's "As executed — LC" and "As executed — 6A-L22".
- The first Proof B run on the chooser's "no L" digest test is the one to watch (D73, the plan's LC note).
- The run-68 reading (touch areas after a level restart) is ruled "not built; a named open item" (D73.3).

## Left behind
- Nothing uncommitted. Scratch copies, build folders and logs made by this session are deleted.
- The worktree `gracious-volhard-286877` stays for part 2, which removes it at the archive.
