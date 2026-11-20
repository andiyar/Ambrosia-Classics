# Handoff — Ferazel's Wand, attended run 57 (2026-11-21, 00:42 → about 02:15, at night)

**What happened.** The run started at night, so nothing could be launched and no new task could start. It did the one
owed item that launches nothing: the seat's own cross-check of everything built since the level fixture (runs 52–56,
through levels 10 and 11). **Result: pass with fixes — no fault found in the game.** What it found is missing tests,
four out-of-date comments and seven pinned values the plan had not listed. No code changed; no test suite was run
(main's game code is the same as at run 56's close, whose numbers stand).

**What the cross-check looked at, and found clean.**
- The test counts match the plan's ladder (557 rules + 165 drawing = 722; Windows side 84).
- Every pinned picture value in STATE is in the tests; levels 1–5's values did not move; the two retired pictures are gone.
- The level fixture and its leave-out list were not touched after their own task.
- Everything that asks "is this level built?" reads the one list; nothing in shipped code branches on a level number.
- The worry carried from run 56 — continuing a saved game on level 11 might face the player the wrong way — is not a
  fault. The port does what the original does: a save made by finishing a level takes the facing from the level; a
  save made at a save point keeps the saved facing. What is missing is a test.

**Not done — owed, in this order.**

| # | item | when it may run |
|---|---|---|
| 1 | the cross-check's fix round (tests and comments only) | any hour |
| 2 | the Windows test run under CrossOver, muted (Proof B) — expect 719 passed / 0 failed / 3 skipped of 722 | 09:00–21:00 |
| 3 | the Mac SDL smoke | 09:00–21:00 |

The two tasks (plants; rain and thunder) wait behind all three.

**Why the fix round was not run here.** Reading the wave's diff took the seat's own context from 116k to 227k of the
300k cap. A fix round needs an implementer, two review legs, the whole suite and a close — about 90k. The findings are
written down in full (the plan, under "Wave 6A.2 — the Fable cross-check"), so the next seat reads no diff.

**The fix round's three items.**
1. Prove Continue's facing on level 11 (a level that starts the player facing left), for both kinds of save.
2. Prove four things at the real settings of levels 10 and 11: ice, landing damage, the river current's effect on
   water particles, and lights drawn under water. Today the tests only check that the settings were read.
3. Four comments still give "levels 1–4" or "1–5" as the reason something is unbuilt.

**Two things the Coordinator should know.**
- **Proof B still cannot run in a session whose commands are cut off at ten minutes with background work off.** It is
  one 13-minute command. Q20 in `docs/QUESTIONS.md` asks Ben how to run it (recommended: let that one script run
  detached). Until there is an answer, a session in that position does the fix round and then stops at Proof B.
- **Items 2 and 3 need a run that is awake between 09:00 and 21:00.** A run started now can do item 1 only.

**Numbers.** None new. HectorKit main ef2c341, clean. Weekly usage 15% (all models), 21% (Fable).

**Seat's context:** 116k at the start, 227k after the diff, about 250k at the close.

## The brief for run 58 (rebuilt from nothing)

You are the orchestrator seat for Ferazel's Wand, run 58, in `/Users/andiyar/Developer/Ambrosia-Classics`. Read
`docs/NEXT.md` and run it; work in your own worktree. The state is in `docs/STATE.md` (the Ferazel block); the plan is
`docs/superpowers/plans/2026-11-04-ferazel-remainder.md`.

- **First:** read the weekly usage limit (above about 70%, no ⚑ task), check the hour, read Q20's answer in
  `docs/QUESTIONS.md`, and check whether one command may run longer than ten minutes.
- **Do, in order:** (1) the cross-check's fix round — one `fk-implementer`, two `fk-reviewer` legs, tests and comments
  only, the three items listed in the plan under "Wave 6A.2 — the Fable cross-check"; any hour; then your own whole
  Core suite (722, in five foreground parts) and the merge. (2) Proof B by day, muted — expect 719 / 0 / 3 / 0 of 722.
  (3) The Mac SDL smoke by day. (4) 6A-BG1c — the plants (Core 722 → 725). (5) 6A-RN ⚑ — rain, thunder, the side push
  (Core → 737, WinKit 84 → 85). Level 15 (6A-L15) is the run after, unless there is clearly room.
- **Start state:** main holds levels 10 and 11; Core suite 722, 0 failed, two opt-in skips; WinKit 84; sweep and bot
  clean on seven levels, both shells (run 56); the wave's cross-check done; its fix round and the two launch checks owed.
- **Must not happen:** a task started while any of the three owed items is open; a launch at night or unmuted; a
  pinned value moving unless a card names it; a new test method in the fix round; a game-code change in the fix round
  (an assert that shows the game wrong is a STOP); more than four heavy workers.
- **If you cannot run Proof B** (night, or the ten-minute cut-off with no answer to Q20): do item 1, record it, and
  close there, saying which of the two stopped you.
- **Done means:** the owed items recorded, the tasks merged with their gates, STATE and NEXT updated, a handoff on
  main, main pushed.
