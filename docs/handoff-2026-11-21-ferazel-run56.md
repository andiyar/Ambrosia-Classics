# Handoff — Ferazel's Wand, attended run 56 (second start; 2026-11-20 18:44 → 2026-11-21 about 01:00)

**What happened.** Levels 10 "Unemployed In Greenland" and 11 "River of Fears" are open — the first new levels a
player can reach since level 5. Beat the Warrior, leave level 5, the chapter card shows, and the game goes on: the
horizon strip, wind, rotating cannons, trees, the river and its ripple, the swarms and bats, the talking Nimbo on
level 11. Level 10 leads to level 11. The next places on the map (15 and 18) still say they are not built.

| task | what it is | commits |
|---|---|---|
| 6A-L10L11 ⚑ | levels 10 and 11 enterable, Mac and Windows | 92e3128, ledger bc4ba4b, fix ae3a20e |

No game code needed fixing: the task widened the list of built levels and proved the two levels with tests. Every
record on both levels sets up (312 and 397), and nothing on them reached code that is not built.

**Not done — three things are owed, first in run 57, by day.** The run's checks finished at 00:37, and nothing may be
launched between 21:00 and 09:00. The plan covers this case (its "Wave end" line; D54.5):

1. the Windows test run under CrossOver, muted (Proof B) — expected 719 passed / 0 failed / 3 skipped of 722;
2. the Mac SDL smoke;
3. the Fable cross-check of the whole wave's diff (the level fixture through levels 10 and 11).

**One thing the Coordinator should know before starting run 57.** Proof B is one whole run of about 13 minutes or
more and cannot be split. A seat whose commands are cut off at ten minutes, with background work off, cannot run it.
Run 57 needs either background work allowed for that one script, or your word on how to run it — and it must start
by day (09:00–21:00), early enough for the checks.

**How the task went.** One implementer (78 minutes), two Opus review legs, one fix round by a fresh implementer from
the reviewer's ready-made patch. No blockers, no must-fix. Both legs said mergeable after fixes.

| planted bugs | caught | harmless | slipped (in scope) | slipped after the fix round | slipped, out of scope |
|---|---|---|---|---|---|
| 68 | 44 | 2 | 17 | 0 | 5 (carried in STATE) |

None of the slips exposed a fault in the game; each was a gap in the tests. One of the five carried ones may be a real
fault and is marked so in STATE: continuing from a save made on level 11 may not face the player left.

**What review changed.**
- On Windows the very first level frame is all black on both levels (the fade-in). The tests now also pin the first
  fully faded-in frame, and the first frame that provably shows the level's feature.
- The frame first chosen to show level 11's ripple turned out to be identical to a game with the ripple switched off.
  The test now finds the first frame that really differs (9,131 bytes) and pins that one.
- One existing drawing-audit test assumed things true only of levels 1–5; it was adjusted as narrowly as possible
  (D54.1). Levels 1–5's rows are untouched.
- The card expected a link from each swarm member to its parent; the original has none. The test pins what the
  original does (D54.3).

**New pinned pictures.**

| picture | value |
|---|---|
| level 10, first frame (Mac) | `e76116216b6d605` |
| level 11, first frame (Mac) | `5d78b001424a6898` |
| Windows, both levels, first frame (black) | `742a0703fa4da325` |
| Windows level 10: strip showing / faded in | `e8f72bddcaf3b7a1` / `17aa796b2ef29b5` |
| Windows level 11: ripple showing / faded in | `f8032383209e56e0` / `d02281f5e0d7cdca` |

Retired, as the card says: level 10's wind and rotating-cannon feature pictures. Nothing else moved.

**Numbers (the seat's own runs, on the finished code).**

| check | result | time |
|---|---|---|
| Core suite at the start (main 4d9e147) | 716, 0 failed | — |
| Core suite after the task | 722, 0 failed, the two opt-in skips | rules 97 s, render 20 min |
| Windows-side suite | 84, 0 failed, the two opt-in skips | 20 min |
| data census | 1,108 items, 0 failures | — |
| object sweep, 7 levels, Mac shell | 6,324 visits, 0 problems | 1,192 s |
| object sweep, 7 levels, Windows shell | 6,324 visits, 0 problems | 1,409 s |
| random-play bot, Mac shell | 151,200 steps, 0 failures | 73 s |
| random-play bot, Windows shell | 151,200 steps, 0 failures | 86 s |
| Mac app build (on the merged branch) | succeeded | — |

The three Windows build checks are the implementer's (all passed).

**Method notes for the next seat.**
- Background work was off. The Core render tests needed four commands, not three: the first two letter groups
  together now pass ten minutes. The split that works is in the next chip.
- The sweep fits the foreground as four commands a shell (levels 1–2, 3–5, 10, 11). The bot is quick: all seven
  levels in one command, about 80 seconds.
- The sweep costs about 0.2 seconds a visit, twice the plan's old estimate: at twelve levels, about 80 minutes for
  both shells.
- Context: 150k before the first dispatch, 172k after both reviews, about 200k before the close.
- Main moved twice during the run (Deimos sessions); neither merge touched Ferazel.

## The brief for run 57 (rebuilt from nothing)

You are the orchestrator seat for Ferazel's Wand, run 57, in `/Users/andiyar/Developer/Ambrosia-Classics`. Read
`docs/NEXT.md` and run it; work in your own worktree. The state is in `docs/STATE.md` (the Ferazel block), the plan is
`docs/superpowers/plans/2026-11-04-ferazel-remainder.md`.

- **First:** read the weekly usage limit (above about 70%, no ⚑ task), check the hour (the first three items need
  09:00–21:00), and check whether one command may run longer than ten minutes (Proof B needs about 13).
- **Do, in order:** (1) Proof B by day, muted — expect 719 / 0 / 3 / 0 of 722; (2) the Mac SDL smoke; (3) your own
  cross-check of wave 6A.2's whole diff (`520590c^..` main), with one fix round if it finds anything; (4) 6A-BG1c —
  the plants (Core 722 → 725); (5) 6A-RN ⚑ — rain, thunder, the side push (Core → 737, WinKit 84 → 85). Level 15
  (6A-L15, with the full sweep and bot) is run 58's unless there is clearly room.
- **Start state:** main holds levels 10 and 11; Core suite 722, 0 failed, two opt-in skips; WinKit 84; sweep and bot
  clean on seven levels, both shells; HectorKit ef2c341 clean; the two launch checks and the cross-check owed.
- **Per task:** one `fk-implementer`, two `fk-reviewer` legs (spec, then quality with planted bugs), a fix round, your
  own whole-suite run, then merge to local main by fast-forward.
- **Must not happen:** a task started while the wave end is owed; a launch at night or unmuted; an existing pinned
  value moving unless the card names it; more than four heavy workers; a level task split from its gate.
- **Done means:** the owed checks recorded, the tasks merged with their gates, STATE and NEXT updated, a handoff on
  main, main pushed.
