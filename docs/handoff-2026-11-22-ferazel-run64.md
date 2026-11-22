# Handoff — Ferazel's Wand, attended run 64 (2026-11-22 05:17 → 11:43; both times from `date`)

**What happened.** Level 18 "Goblin Chief" is open: a player can walk into the arena, be locked in and fight the
Chief. One task, merged with all its checks. The wave's daytime launch checks were also done (muted, after 11:00).

| step | result |
|---|---|
| Level 18 opens (6A-L18) | merged to main at a66d567 |
| Mac-side test suite | 764 tests, 0 failed (was 760) |
| Windows-kit test suite | 87 tests, 0 failed (was 86) |
| Every-object sweep, nine levels, both game paths | 7,192 visits each, 0 problems |
| Random-play bot, nine levels, both game paths | 194,400 steps each, 0 failures |
| Data census | 1,108 items, 0 failures |
| Windows test run (CrossOver, muted, 11:20) | 761 passed / 0 failed / 3 skipped / 0 crashed (of 764) |
| Smoke check (muted, 11:40) | passed, main menu identical |
| My own cross-check of the whole wave | **not done — it opens run 65** |

**What a player would notice.** A ninth playable level. Entering level 18 shows the river rippling; walking left
locks the arena and wakes the Chief, who can now be fought and killed.

**How the task went.**
- The builder opened the level with a one-line change to the game; everything else is tests.
- One standing check failed on the new level, and it was the check that was out of date, not the game. Level 18 is
  the first level whose map has "no light" cells. A few kinds of object (rafts, rolling boulders, maces, blades)
  take their brightness from the cell under them, and on such a cell they would ask for a drawing the renderer
  cannot make. The check used to say "no level has such cells". The first review read the original and showed that
  none of those objects can ever exist on level 18. I ruled the proof rewritten to say exactly that (D63.1), and
  the second review broke the new proof on purpose four ways; it failed each time, as it should.
- The same check was too strict about the dagger Ferazel holds; the original always draws it the same way.
- The second review planted 37 bugs: 29 caught, 5 that change nothing a player could see, 3 that slipped. None
  showed a fault in the game. One test comparison could never fail; it can now.
- The Chief's wake-up with real pictures is three frames later than the earlier measurement without them (he wakes
  on frame 124, first jumps on 179). Both sets of numbers are now pinned, each where it is true.
- The random-play bot reaches the Chief on one of its four quick runs, fights and dies once; the other three wander
  out of the exit beside the start. I accepted that as the meeting the plan asks for (D63.3).

**Left for later, in order of weight.**
- **My cross-check of the wave** (plants, rain, level 15, the Chief, level 18). Weekly Fable usage was 77% and my
  context 231k at the close, so it opens run 65, before the next task — the plan allows that.
- **Level 20's blades will hit the "no light" case for real.** The original itself reads outside its own table
  there, so there is nothing defined to copy. The blade task (6A-BD, next run) needs a ruling on what to draw
  (D63.6). It may become a question for Ben.
- Small items are under "From run 64" in STATE's open carries.

**Things the next seat should know.**
- First dispatch to merge took about six hours: build 44 min, first review 30, audit fix 45, second review 77,
  last fix 27, my own suites and sweeps about 2 h.
- The Windows test run now takes about 19 minutes (it was 14).
- The longest single command was 509 s (the Windows-path sweep of levels 3 and 4): one level a command next time.
- No memory note written (D63.7).

**Numbers.** Weekly usage 61% (all models), 77% (Fable). Seat's context: 116k at the start, 148k before the first
dispatch, 231k at the close. Five helpers, all Opus 5.5, all in the foreground. Worktree `vigilant-haslett-eeec5a`
removed at the close (1.6 GB: this run's own checkout and build folders; nothing from another chain).

## The brief for run 65 (rebuilt from nothing)

You are the orchestrator seat for Ferazel's Wand, run 65, in `/Users/andiyar/Developer/Ambrosia-Classics`. Read
`docs/NEXT.md` and run it; work in your own worktree. The state is in `docs/STATE.md` (the Ferazel block); the plan
is `docs/superpowers/plans/2026-11-04-ferazel-remainder.md`.

- **First:** read the weekly usage limit (77% Fable at run 64's close; it resets 2026-11-24 02:00 Sydney time) and
  your own context meter. Read `docs/QUESTIONS.md` "Open" for new answers (Q18: Ben's Phase 5 verdict).
- **Do, in this order:** (1) your own cross-check of wave 6A.3's whole diff (`git diff 66875a3 a66d567`, with the
  six "As executed" notes and D59–D63), findings to one fix round; (2) 6A-CL, clouds (Core suite 764 → 771);
  (3) 6A-BD, the rotating blade (→ 784) — rule first on what the port draws where the original reads outside its
  light table (D63.6); (4) 6A-MP, programmed maces (→ 791). One task at a time: one implementer, two review legs, a
  fix round, your own run of both suites in parts. The Windows kit stays at 87. Nothing in this run is launched and
  no sweep or bot is owed.
- **Start state:** main holds levels 1–5, 10, 11, 15 and 18 playable; Core suite 764 and Windows kit 87, 0 failed;
  sweep and bot clean on nine levels, both paths; the Windows test run 761 of 764 and the smoke passed by day — all
  at a66d567 (run 64).
- **Must not happen:** a task started before the cross-check; two suite parts chained in one command; two of the
  three tasks built at once; a pinned value moving that the card does not name; a launch at night or unmuted; more
  than four heavy workers; a card's numbers trusted over the level data or the original; the seat making an edit a
  helper was refused.
- **Done means:** the cross-check's findings fixed, each finished task merged with its gates, STATE and NEXT
  updated, a handoff on main, main pushed.
