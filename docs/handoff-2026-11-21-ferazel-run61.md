# Handoff — Ferazel's Wand, attended run 61 (2026-11-21, 14:55 → 21:23; both times from `date`)

**What happened.** Level 15 "Storm Valley" is open. One task, with its whole check, and nothing launched.

| step | result |
|---|---|
| Level 15 opens (6A-L15) | merged to main at b4482a1 |
| Mac-side test suite | 740 tests, 0 failed (was 737) |
| Windows-kit test suite | 86 tests, 0 failed (was 85) |
| Every-object sweep, 8 levels | 7,056 visits on each of the Mac and Windows game paths, 0 problems |
| Random-play bot, 8 levels | 172,800 steps on each path, 0 failures |
| Data census | 1,108 items decoded, 0 failures |
| The Goblin Chief, part one (6A-CH1) | **not started** — the level's check ended at 21:20; that task takes about four hours |

**What a player would notice.** Leaving level 10 by its second exit now leads into Storm Valley: rain falling,
thunder with a flash, the rain sound, and a wind that pushes Ferazel sideways, with Gremlins, a Dillo, Frogs, crates
and springs. Its exits unlock two further map nodes that still say "not built".

**How the task went.**
- The level's first picture is exactly the value the rain task predicted (`49eddc24d9989d95`).
- The original disagreed with the task card three times and the original won: the Gremlin never goes to sleep when
  off screen, so there was nothing to test about its parts "waking"; level 15 is reached from level 10, not 11; and
  none of the level's 183 objects is refused any more (the card said 38).
- The quality review broke the code 83 ways. The tests caught 72; 5 breaks change nothing a player could see; 4
  slipped past and the fix round added checks for all 4; 2 are caught by older tests. No break exposed a fault in
  the game itself. One check it found could never have failed (it was reading the Frog instead of the Frog's spit).
- One existing check needed a change the task was not allowed to make: the audit that plays each level with
  scripted keys ran out of time on level 15, because the wind keeps blowing the scripted player back out of the
  level's entrance. Both reviews confirmed the wind matches the original. I ruled the larger time budget in (D60.1)
  and the fix round made it.
- That same audit was 552 s long against a 600 s limit, so it can now be run in level groups (D60.2).

**Left for the next run, in order of weight.**
- The audit's *second* test has the same problem and no level filter yet: 543 s alone. It is the first, small task
  of run 62. One more level and the suite cannot be run under the ten-minute limit.
- The scripted audit sees little of level 15 (7 of its 38 kinds of object), since the wind sends the player home.
  The sweep and the bot do cover the level; a later start point for the audit would close the gap.
- Small items are listed under "From run 61" in STATE's open carries.

**Things the next seat should know.**
- Never chain two suite parts in one command: I lost one part to the ten-minute cut-off that way.
- The sweep ran in the slots beside the two review legs and the fix round (one command each), at the task's game
  code. That is only sound because the fix round touched no game source, which `git diff` confirmed (D60.4).
- The bot does not need splitting by level: 80 s and 95 s for all eight.
- A helper whose edit is refused as outside its fence reports it; the seat rules and the fix round makes the
  change. The seat does not make the edit itself.
- Q21 (may the sweep and bot run detached) is still open and no longer pressing.

**Numbers.** Weekly usage 40% (all models), 50% (Fable). Seat's context: 123k at the start, 147k before the first
dispatch, 207k after the task and its gate. Four helpers, all Opus 5.5, all in the foreground: implementer 105 min,
spec review 32 min, quality review 89 min, fix round 19 min. Worktree `dazzling-hodgkin-f960ff` removed at the close
(1.5 GB: this run's own checkout and its build folders; nothing from another chain).

## The brief for run 62 (rebuilt from nothing)

You are the orchestrator seat for Ferazel's Wand, run 62, in `/Users/andiyar/Developer/Ambrosia-Classics`. Read
`docs/NEXT.md` and run it; work in your own worktree. The state is in `docs/STATE.md` (the Ferazel block); the plan
is `docs/superpowers/plans/2026-11-04-ferazel-remainder.md`.

- **First:** read `docs/QUESTIONS.md` "Open" for new answers (Q18: Ben's Phase 5 verdict; Q21: may the sweep and
  the bot run detached). Read the weekly usage limit (above about 70%, no ⚑ task) and your own context meter.
- **Do, in order:** (1) a small tests-only task: give the draw-mode audit's second test,
  `testEveryRefusalIsUnreachable`, the same opt-in level filter (`FERAZEL_AUDIT_LEVELS`) its first test got in run
  61, so no command of the suite is near ten minutes; (2) 6A-CH1 ⚑ — the Goblin Chief, part one (Core suite 740 →
  752, Windows kit stays 86), with one implementer, two review legs, a fix round and the seat's own suite run.
- **Start state:** main holds levels 1–5, 10, 11 and 15 playable; Core suite 740 and Windows kit 86, 0 failed (run
  61, at b4482a1); sweep and bot clean on all eight levels, both paths (run 61); the Windows test run and the smoke
  last passed by day in run 60 and are next owed at the wave end after level 18.
- **Must not happen:** two suite parts chained in one command; two ⚑ tasks at once; a pinned value moving unless
  the card names it; a launch at night or unmuted; more than four heavy workers; a card's numbers trusted over the
  level data or the original; the seat making an edit a helper was refused.
- **Done means:** the tasks merged with their gates, STATE and NEXT updated, a handoff on main, main pushed.
