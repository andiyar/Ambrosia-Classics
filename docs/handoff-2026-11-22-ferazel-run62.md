# Handoff — Ferazel's Wand, attended run 62 (2026-11-21 21:24 → 2026-11-22 01:25; both times from `date`)

**What happened.** The Goblin Chief's first half is built, and the one slow test that threatened the ten-minute
limit is split. Two tasks, both merged with their checks. Nothing was launched (it was night).

| step | result |
|---|---|
| The slow audit test takes the level filter | merged (05b3276); 544 s as one command, now 215 s and 367 s |
| The Goblin Chief, part one (6A-CH1) | merged to main at d7dc0ad |
| Mac-side test suite | 752 tests, 0 failed (was 740) |
| Windows-kit test suite | 86 tests, 0 failed (unchanged) |
| Every-object sweep, random-play bot | not owed: no level opened, and the Chief is on no open level |
| The Goblin Chief, part two (6A-CH2) | **not started** — it is run 63's |

**What a player would notice.** Nothing yet. The Chief now waits for his arena to lock, jumps between three lanes,
lands with a screen shake that can stagger Ferazel, and throws one or two boulders after each landing — but his
level (18) is not open, and he cannot be hurt until part two.

**How the Chief task went.**
- The first review read the code against the original line by line and found no difference.
- The second review broke the code 142 ways. The tests caught 124; 8 breaks change nothing a player could see; 10
  slipped past, and the fix round added a check for each. None exposed a fault in the game itself. The most visible
  slip: nothing checked which way he faces when he starts throwing.
- The original beat the task's notes once more: the notes said his first jump comes 56 frames after the arena
  locks. On level 18 he is asleep (off screen) when it locks, and the count only runs while he is awake, so the jump
  comes later (frame 176, not 167).
- One edit was outside what the task was allowed to touch: the script that keeps the list of what is built still
  called the Chief unbuilt. The implementer reported it instead of editing; I ruled it in (D61.1) and the fix round
  made it.

**Left for later, in order of weight.**
- The Chief's wake-up and first-jump moments were measured without real pictures. With pictures they may shift by a
  few frames; the level-18 task re-measures them (D61.3).
- The picture loader cannot yet load four of the Chief's picture sets. Part two's fight test needs them, and the
  task card names no loader file — expect to rule that in.
- Small items are under "From run 62" in STATE's open carries.

**Things the next seat should know.**
- Starting a major task at 21:55 worked: first dispatch to merge took 3 h 25 min (build 69 min, reviews 15 and 44,
  fix round 15, my own suites 62).
- The suite parts and their times are in the chip. The longest single command is now 367 s.
- The Windows-kit level-picture tests are named `testLevel10FirstFrameReference` and so on; a wrong filter runs
  zero tests and still exits 0 — always read the passed count.
- I ran my suites after the fix round, at the final commit, having first confirmed the fix round changed only
  comments in game source.

**Numbers.** Weekly usage 45% (all models), 55% (Fable). Seat's context: 115k at the start, 140k before the first
dispatch, 205k at the close. Six helpers, all Opus 5.5, all in the foreground: audit-filter build 28 min and review
12 min; Chief build 69 min, spec review 15 min, quality review 44 min, fix round 15 min. Worktree
`zen-hamilton-a3370d` removed at the close (this run's own checkout and build folders; nothing from another chain).

## The brief for run 63 (rebuilt from nothing)

You are the orchestrator seat for Ferazel's Wand, run 63, in `/Users/andiyar/Developer/Ambrosia-Classics`. Read
`docs/NEXT.md` and run it; work in your own worktree. The state is in `docs/STATE.md` (the Ferazel block); the plan
is `docs/superpowers/plans/2026-11-04-ferazel-remainder.md`.

- **First:** read `docs/QUESTIONS.md` "Open" for new answers (Q18: Ben's Phase 5 verdict; Q21: may the sweep and
  the bot run detached). Read the weekly usage limit (above about 70%, no major task) and your own context meter.
- **Do:** 6A-CH2 — the Goblin Chief, part two: he can be hit, hurt, crushed and killed, the level-18 gate opens and
  the music changes when he dies, and a scripted fight on level 18 is measured and pinned (Core suite 752 → 760,
  Windows kit stays 86). One implementer, two review legs, a fix round, then your own run of both suites. The
  implementer first works out from the original and the level data how the fight is actually won (D49.1).
- **Start state:** main holds levels 1–5, 10, 11 and 15 playable and the Chief's first half built but unreachable;
  Core suite 752 and Windows kit 86, 0 failed (run 62, at d7dc0ad); sweep and bot clean on all eight levels, both
  paths (run 61); the Windows test run and the smoke last passed by day in run 60 and are next owed at the wave end
  after level 18.
- **Must not happen:** two suite parts chained in one command; two major tasks at once; a pinned value moving
  unless the card names it (the Chief's four measured frames stay until the level-18 task); a launch at night or
  unmuted; more than four heavy workers; a card's numbers trusted over the level data or the original; the seat
  making an edit a helper was refused.
- **Done means:** the task merged with its gates, STATE and NEXT updated, a handoff on main, main pushed.
