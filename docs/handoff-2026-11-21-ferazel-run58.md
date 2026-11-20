# Handoff — Ferazel's Wand, attended run 58 (2026-11-21, 00:53 → 02:01, at night; both times from `date`)

**What happened.** The run started at night, so nothing could be launched. It did the one owed item that launches
nothing: the fix round of the wave's cross-check. **It is merged. Nothing in the game changed** — only tests and
comments. No fault was found in the game.

**What the fix round added.**
- Proof that Continue faces the player the right way on level 11 (a level that starts facing left), for three kinds
  of save.
- Proof, at the real settings of levels 10 and 11, of four behaviours: ice, damage from harmful ground, the river
  current pushing water particles, and lights drawn under water.
- Fourteen out-of-date comments corrected.

**Two things found on the way.**
- **The plan had level 10's settings wrong.** Level 10 has no ice setting, no damage setting and no current; the
  values the plan gave belong to level 11 only. The level data wins; level 10 is tested at its real zeros (D56.1).
- A helper wondered whether Walkers on harmful ground take the wrong damage. They do what the original does (D56.2).

**Checks.**

| check | result |
|---|---|
| whole Core test suite, seat's own run at 66875a3, five parts | 722 tests, 0 failed, the 2 expected skips |
| reviewer 1 (spec) | pass |
| reviewer 2 (quality, 33 planted bugs) | pass with fixes; its verified patch applied |
| ledger check | OK |
| HectorKit | main ef2c341, clean |
| Windows-side suite | not run (nothing it tests changed) |

**Still owed — both need daytime (09:00–21:00), in this order.**

| # | item | expected |
|---|---|---|
| 1 | the Windows test run under CrossOver, muted (Proof B) | 719 passed / 0 failed / 3 skipped of 722 |
| 2 | the Mac SDL smoke | exit 0 |

The two tasks (plants; rain and thunder) wait behind both.

**For the Coordinator.**
- **A run started at night has nothing left to do.** Runs 57 and 58 used up all the work that launches nothing. Start
  run 59 between 09:00 and about 18:00.
- **Proof B still cannot run in a session whose commands are cut off at ten minutes with background work off** (it is
  one 13-minute command). Q20 in `docs/QUESTIONS.md` asks Ben how to run it and has no answer. Run 59 needs that
  answer, or a session without the ten-minute cut-off, or it will stop at step 1.
- Run 57's handoff gave its end as "about 02:15"; this run's first `date` read 00:53, so that was an estimate.
- The new tests have never run under CrossOver. If Proof B fails in one of them, suspect the test first.

**Numbers.** Weekly usage 16% (all models), 22% (Fable). Seat's context: 117k at the start, 131k at the first
dispatch, 172k at the close. Worktree `blissful-gauss-7cdcd9` removed at the close.

## The brief for run 59 (rebuilt from nothing)

You are the orchestrator seat for Ferazel's Wand, run 59, in `/Users/andiyar/Developer/Ambrosia-Classics`. Read
`docs/NEXT.md` and run it; work in your own worktree. The state is in `docs/STATE.md` (the Ferazel block); the plan
is `docs/superpowers/plans/2026-11-04-ferazel-remainder.md`.

- **First:** check the hour with `date` (at night there is nothing to do — close with nothing changed); read Q20's
  answer in `docs/QUESTIONS.md` and check whether one command may run longer than ten minutes; read the weekly usage
  limit (above about 70%, no ⚑ task).
- **Do, in order:** (1) Proof B by day, muted — expect 719 / 0 / 3 / 0 of 722. (2) The Mac SDL smoke by day.
  (3) 6A-BG1c — the plants (Core 722 → 725). (4) 6A-RN ⚑ — rain, thunder, the side push (Core → 737, WinKit 84 → 85).
  Level 15 (6A-L15) is the run after, unless there is clearly room.
- **Start state:** main holds levels 10 and 11; Core suite 722, 0 failed, two opt-in skips (run 58, at 66875a3);
  WinKit 84; sweep and bot clean on seven levels, both shells (run 56); the wave's cross-check and its fix round done;
  the two launch checks owed.
- **Must not happen:** a task started while either owed check is open; a launch at night or unmuted; a pinned value
  moving unless a card names it; more than four heavy workers; a card's numbers trusted over the level data.
- **If you cannot run Proof B** (night, or the ten-minute cut-off with no answer to Q20): do nothing else, and close
  saying which of the two stopped you.
- **Done means:** the owed checks recorded, the tasks merged with their gates, STATE and NEXT updated, a handoff on
  main, main pushed.
