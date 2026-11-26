# Handoff — Ferazel's Wand, run 71 (2026-11-26)

**Seat:** Fable 5.2, started by another session; foreground only.
**Times:** started 2026-11-26 15:01, closed 20:35 (Sydney) — by day; one muted 30-second launch at 20:23.
**Context:** 116k at the start, 199k when the gates were done, about 228k at the close. Weekly limit at the
close: 71% Fable, 89% all models (64% and 80% at the start).

## What is now true
- **Level 22 "The Labyrinth" is open** (task 6A-L22, on main at db0e580). It is the biggest level yet: 510
  objects, dark, 190 small flying enemies, spinning blades, swinging maces, eight teleporters, Dimbo to talk to,
  and the game's only magic carpet, which can now be ridden in play. Talking to Dimbo there makes him appear back
  on level 11, as in the original (shown in a test that plays the conversation and then reopens level 11).
- **Every build task of Phase 6A is merged.** Playable levels: 1–5, 10, 11, 15, 18, 20, 21, 22. Only the phase
  end is left.
- **The only game-code change was adding 22 to the list of built levels.** Everything level 22 needs had been
  built by earlier runs.
- **One check was wrong, not the game.** A test that counts how many lights a level needs added them up object by
  object and got 225 for level 22, over the limit of 200. The original stops giving the small flying enemies a
  light once 150 are in use, and the port does the same, so the level really uses 168. The test now counts the way
  the game does, and every level's real count is pinned (D72.2).
- Two reviewers checked the level against the original. The second planted 50 deliberate bugs: 40 were caught by
  the new tests, 8 by older ones, 2 make no difference on this level, and 2 exposed missing checks that are now
  added. The fix round changed tests and notes only (proven: the code diff over it is empty).
- Numbers, all the seat's own runs at the merged code:

  | check | result |
  |---|---|
  | Core suite | 816 (814 passed, 0 failed, the 2 named opt-in skips) |
  | Windows-kit suite | 90 (88 passed, 0 failed, the 2 named skips) |
  | census, Mac app build, both Windows cross-builds, the Mac SDL build | all pass |
  | every-object sweep, 12 levels | 11,864 visits on each path, no problems |
  | random-play bot, 12 levels | 259,200 steps on each path, 0 failures |
  | level 22 start-up check | launched muted, stayed running 30 s, quit cleanly; picture unseen |

## Ben's ruling (D72.1) and what follows
Finish Phase 6A, then archive: the original author is selling an official remaster. Run 72 is the last run: the
phase end, an in-game level chooser, complete Mac and Windows builds with no public upload, then `STATUS: PAUSED`.
The full text is at the top of `docs/NEXT.md`.

## For run 72
- **The weekly limit is the first question.** It stood at 89% (all models) at this close and resets on
  2026-12-01 at 02:00 Sydney time. Run 72 is bigger than this run (which cost 9 points); the chip tells it to do
  nothing and wait if the limit cannot hold it.
- Proof B and the Mac SDL smoke are owed by day (not run on the 52 tests added since run 64).
- Level 22 is swept in two halves by offset (D72.4); the commands and times are in "As executed — 6A-L22".
- For the gate card's known deviations: a full light table shows an alert in the original and nothing in the
  port (D72.3).
- For the phase review: the bot's two paths differ by one death and two exits on twelve levels (they were equal
  on eleven); 0 failures on both; unexplained.
- Eyes on levels 20, 21 and 22 are still owed, and stay with Ben (D70.5).

## Left behind
- Nothing uncommitted. The run's worktree `inspiring-chatterjee-0957b6` and its build cache are removed; every
  scratch copy and log is deleted.
