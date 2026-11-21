# Handoff — Ferazel's Wand, attended run 63 (2026-11-22 01:26 → 05:15; both times from `date`)

**What happened.** The Goblin Chief's second half is built: he can be hit, hurt, crushed and killed, and a scripted
fight on his level is won. One major task, merged with its checks. Nothing was launched (it was night).

| step | result |
|---|---|
| The Goblin Chief, part two (6A-CH2) | merged to main at f523e2a |
| Mac-side test suite | 760 tests, 0 failed (was 752) |
| Windows-kit test suite | 86 tests, 0 failed (unchanged) |
| Every-object sweep, random-play bot | not owed: no level opened, and the Chief is on no open level |
| Level 18 opens (6A-L18), and the end of this group of levels | **not started** — run 64's |

**What a player would notice.** Nothing yet. The Chief now takes 20 Fireball hits, flashes and bleeds when hurt, can
be crushed, and dies in a burn that opens the arena gate and changes the music — but his level (18) is still closed.

**How the task went.**
- The plan's suggested way to fight him loses: Ferazel dies about 16 seconds in with the Chief at half health. The
  builder worked out what wins, using keys only: stand close when he is in the right-hand lane (his near boulder
  flies past) and cast straight; otherwise stand back, lob the Fireball, and jump the far boulders; hop each time he
  lands so the shake never staggers you. He dies on frame 1710 (under half a minute of play).
- The first review read the code against the original line by line and found no difference. It also confirmed that
  the fight script only presses keys.
- The second review broke the code 107 ways. The tests caught 76; 15 breaks change nothing a player could see; 16
  slipped past, and the fix round added a check for each. None exposed a fault in the game itself. The worst slip:
  the check that he bleeds when hit was testing nothing.
- The original beat the notes twice: a Smite seed never hurts him on this level, and his saved record is cleared by
  a different flag than the notes said. The notes are corrected.
- Two edits were outside what the task was allowed to touch, and I ruled both in (D62): the picture loader had to
  learn to load his four death and throwing picture sets, and two older tests counted a list that grew by one.

**Left for later, in order of weight.**
- The Chief's wake-up and first-jump moments from run 62 were measured without real pictures; the level-18 task
  re-measures them (D61.3).
- The wave end after level 18 needs daylight (the Windows test run and the smoke are launches, 09:00–21:00 only).
- Small items are under "From run 63" in STATE's open carries.

**Things the next seat should know.**
- First dispatch to merge took 3 h 45 min: build 73 min, reviews 28 and 55, fix round 5, my own suites 62.
- The suite parts and their new times are in the chip. The longest single command is 348 s.
- When level 18 opens, give it its own audit group (the 10, 11, 15 group is already near six minutes).
- I wrote no memory note (D62.6): the run taught no new standing rule and the memory index is over its size limit.

**Numbers.** Weekly usage 50% (all models), 60% (Fable). Seat's context: 114k at the start, 140k before the first
dispatch, 196k at the close. Four helpers, all Opus 5.5, all in the foreground. Worktree `zealous-bartik-85e6f8`
removed at the close (this run's own checkout and build folders; nothing from another chain).

## The brief for run 64 (rebuilt from nothing)

You are the orchestrator seat for Ferazel's Wand, run 64, in `/Users/andiyar/Developer/Ambrosia-Classics`. Read
`docs/NEXT.md` and run it; work in your own worktree. The state is in `docs/STATE.md` (the Ferazel block); the plan
is `docs/superpowers/plans/2026-11-04-ferazel-remainder.md`.

- **First:** check the time (`date`) — the wave end's two launch checks need daylight. Read `docs/QUESTIONS.md`
  "Open" for new answers (Q18: Ben's Phase 5 verdict; Q21: may the sweep and the bot run detached). Read the weekly
  usage limit and your own context meter.
- **Do:** 6A-L18 — level 18 "Goblin Chief" opens (Core suite 760 → 764, Windows kit 86 → 87): one implementer, two
  review legs, a fix round, your own run of both suites, the census, then the every-object sweep and the bot on all
  nine levels, one level group a command. It re-measures the Chief's four wake-up frames with real pictures (the
  only pinned values it may move). Then the wave end: the Windows test run by day (detached, D59.1), the smoke by
  day, and your own cross-check of the whole wave's diff.
- **Start state:** main holds levels 1–5, 10, 11 and 15 playable and the Chief built whole but unreachable; Core
  suite 760 and Windows kit 86, 0 failed (run 63, at f523e2a); sweep and bot clean on all eight levels, both paths
  (run 61); the Windows test run and the smoke last passed by day in run 60.
- **Must not happen:** two suite parts chained in one command; a pinned value moving unless the card or D61.3 names
  it (the fight's frames 1602 and 1710 stay); a launch at night or unmuted; more than four heavy workers; a card's
  numbers trusted over the level data or the original; the seat making an edit a helper was refused.
- **Done means:** the level merged with its gates, the wave end closed or its daytime checks named as owed, STATE and
  NEXT updated, a handoff on main, main pushed.
