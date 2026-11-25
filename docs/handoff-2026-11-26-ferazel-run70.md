# Handoff — Ferazel's Wand, run 70 (2026-11-26)

**Seat:** Fable 5.2, started by the Coordinator; foreground only.
**Times:** started 2026-11-25 20:59, closed 2026-11-26 00:20 (Sydney) — night; nothing launched.
**Context:** 118k at the start, 159k when the reviews were in, about 210k at the close. Weekly limit at the close:
55% Fable, 72% all models (46% and 60% at the start).

## What is now true
- **The magic carpet is built** (task 6A-CP, on main at 651314e). Touch the rolled carpet and it unrolls into a
  flying platform, rises for 14 frames, sinks and settles, and the player steers it. The game's only carpet is on
  level 22, which is not open yet, so nobody can ride it in play until run 71. That one flies for ever; carpets
  with a ride count (they count down, flash and burst) exist only as made-up test carpets.
- The player's side of the carpet was already built. It was not changed; it was checked against the original and
  is now held by tests.
- Two reviewers read the new code against the original line by line and found no code fault. The second planted
  45 deliberate bugs: 31 were caught, 3 behave the same as correct code, and 11 exposed missing checks — all 11
  are now added. The fix round changed tests and notes only (proven: the code diff over it is two comment lines).
- Numbers, all the seat's own runs at the merged commit:

  | check | result |
  |---|---|
  | Core suite | 812 (810 passed, 0 failed, the 2 named opt-in skips) |
  | Windows-kit suite | 89 (87 passed, 0 failed, the 2 named skips) |
  | census, Mac app build, both Windows cross-builds, the Mac SDL build | all pass |

- No sweep or bot was owed: no open level holds a carpet (checked against the level data first).
- No picture or state value of any open level moved. The one named move: level 22's load-bar count in a test
  (35 → 36 picture records, because the carpet's pictures are now loaded).

## Rulings (D71)
1. The carpet's picture test pins the first frame that **shows** the unrolled carpet, one frame later than the
   plan's wording: the original draws each frame before objects act, so the frame right after the touch still
   shows the rolled carpet.
2. The count of "not built yet" refusals in one source file stays 14; the chip expected it to drop. The carpet
   had been refused by a shared catch-all that four other unbuilt objects still reach.
3. A comment in a file the task may not change can be corrected when the task makes it false — comment only.
4. The fix round was tests and notes only, proven; every test was still run at the final commit.
5. **Ben's answer to mailbox Q1, word for word: "A: plain, unlit".** That is what is built for a lit blade on
   level 20. Recorded; the question is closed and off STATE's waiting list.
6. With other projects building on this Mac a test part can run a third slower; two parts chained in one command
   came within 12 seconds of the ten-minute cut. Chain only short parts.

## Open
- **Owed:** somebody's eyes on levels 20 and 21 (Ben's); the Windows test run under CrossOver and the Mac SDL
  smoke at the wave end, by day.
- Waiting on Ben: Q18 (the Phase 5 gate) and the older open items in QUESTIONS.md. Nothing new was asked; the
  mailbox's next free number is still Q2.
- Small carries are in STATE under "From run 70". The one worth a look in run 71: the carpet's picture is set one
  frame earlier than in the original. It cannot be seen from level 22's real start (the carpet is off screen),
  but the level-22 task should confirm that.

## Housekeeping
- Run 70's worktree `focused-jennings-d776d7` is removed at the close. It held the branch checkout and two build
  folders (414 MB and 313 MB), 970 MB in all. It had no Xcode build cache of its own (the app build ran in the
  scratch folder and was deleted).
- The seat's test copy (1.1 GB) and every log are deleted. The implementer's report, the two review files and the
  reviewer's patch stay in the session's scratch folder until a restart.
- Run 67's folder `Aki/.claude/worktrees/exciting-panini-fdb834` still holds about 560 MB — remove by hand.

## The brief for the next run (run 71)
Read `docs/NEXT.md` in `/Users/andiyar/Developer/Ambrosia-Classics` and run it. It is one task: **6A-L22 — level
22 "The Labyrinth" opens** (Core 812 → 816, Windows-kit 89 → 90), a level task: the built-level list gains 22, four
new tests and one Windows picture, then the full sweep and random-play bot over twelve levels on both paths. The
plan is `docs/superpowers/plans/2026-11-04-ferazel-remainder.md` (the card `#### 6A-L22`; the model for a level
task, with the sweep's level groups and times, is "As executed — 6A-L21"). Live state is the Ferazel block of
`docs/STATE.md`; this run's rulings are D71 in `docs/DECISIONS.md`. The card's "52 refused today" is old: the
ledger now shows none refused on level 22 — check it and the level data before briefing. Level 22 is where the
carpet is first met in play, and where its conversation 221 must be shown to arm level 11's record 283 (D70.1).
A boot check is owed when the level opens: muted, by day only; at night carry it to the phase end. Do not ask to
look at the game window (declined in run 69; it stays with Ben). Do not start the phase end in the same run.
Helpers are `fk-implementer` / `fk-reviewer` with no model parameter; foreground only, one heavy command a
message; questions for Ben go to the Coordinator mailbox (next free number Q2).
