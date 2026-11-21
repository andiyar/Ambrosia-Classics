# Handoff — Ferazel's Wand, attended run 60 (2026-11-21, 08:00 → 14:53; both times from `date`)

**What happened.** Ben answered Q20 ("a: run detached"), so the build is moving again. The run waited an hour for
09:00 (the two launch scripts refuse earlier by their own clock), ran the two checks owed since run 56, then built
two tasks of the next wave. Level 15 itself is not open yet.

| step | result |
|---|---|
| Q20 recorded (D59.1), the block lifted | done first |
| Windows test run under CrossOver, muted, started detached at 09:00 | 719 passed / 0 failed / 3 skipped / 0 crashed (of 722), 834 s |
| Mac SDL smoke, 09:15 | exit 0, main menu identical |
| Plants of levels 15 and 18 (6A-BG1c) | merged; Core suite 725 |
| Level 15's weather: rain, thunder, the looped rain sound, the side push (6A-RN ⚑) | merged; Core suite 737, Windows kit 85 |
| Level 15 opens (6A-L15) | **not started** — run 61's |

**What a player would notice.** Nothing yet: the rain and thunder are proven on a test stand-in for level 15, and
the level stays closed until the next task opens it. One small change does reach the game: plants now carry the
original's "one-way" mark, which nothing can observe.

**Wave 6A.2 is closed.** The wave's cross-check (run 57), its fix round (run 58) and now both launch checks are done.

**The two tasks, briefly.**
- Plants: 22 records on level 15 and 5 on level 18, counted from the data, all set up. Level 15 now refuses none of
  its 183 records; level 18 only the Chief. Two review legs, no must-fix.
- Rain: both review legs compared the rain routine with the original step by step and found no difference. The
  quality leg broke the code 76 ways; 5 breaks slipped past the tests, and the fix round added asserts for all 5.
  The original disagreed with the task card in four places and the original won each time (D59.3) — the one that
  matters next: a raindrop is not drawn on the frame it is made, so the rain picture is frame 2, and frame 1 is
  pinned beside it for the level-15 task to compare with. That card is amended.
- No pinned picture or state value moved in either task.

**Final numbers (the seat's own runs at e00db25, in the foreground, in parts).**

| check | value |
|---|---|
| Core suite | 737 = 569 rules + 168 render; 0 failed; the two opt-in skips by name |
| Windows-kit suite | 85; 0 failed; the two opt-in skips by name |
| Mac app build / Windows cross-builds | succeeded (the implementer's) |

**Why level 15 was not started.** A level task ends with the every-object sweep and the random-play bot over every
built level, and neither fits in one ten-minute command; Ben's Q20 answer covers the Windows test script only. The
seat's context was also at 200k of 300k. Run 61 runs those two checks one level at a time in the foreground
(D59.4). **Q21** (new, not blocking) asks Ben whether they may run detached instead.

**Things the next seat should know.**
- This run's rulings are **D59**, not D58: a Deimos session took D58 on main during the run. Two early commit
  messages (d82b2bf, b6aac58) and the 7bb1e1d message still say "D58"; the files are all corrected.
- A seat's suite part can run beside one working helper when both are sent in the same message; that is how this
  run fitted two tasks into one day.
- The render suite's F–L part took close to ten minutes; the level-15 task adds to it. Split it if it nears nine.
- Left open, all small: listed under "From run 60" in STATE's open carries.

**Numbers.** Weekly usage 30% (all models), 40% (Fable). Seat's context: 113k at the start, 153k before the first
dispatch, 200k after both tasks, about 235k at the close. Nine helpers, all Opus 5.5, all in the foreground.
Worktree `recursing-morse-414aa0` removed at the close (958 MB: this run's own checkout and its helpers' build
folders; nothing from another chain).

## The brief for run 61 (rebuilt from nothing)

You are the orchestrator seat for Ferazel's Wand, run 61, in `/Users/andiyar/Developer/Ambrosia-Classics`. Read
`docs/NEXT.md` and run it; work in your own worktree. The state is in `docs/STATE.md` (the Ferazel block); the plan
is `docs/superpowers/plans/2026-11-04-ferazel-remainder.md`.

- **First:** read `docs/QUESTIONS.md` "Open" for new answers (Q21: may the sweep and the bot run detached; Q18:
  Ben's Phase 5 verdict). Read the weekly usage limit (above about 70%, no ⚑ task) and your own context meter.
- **Do:** 6A-L15 — level 15 "Storm Valley" opens (Core suite 737 → 740, Windows kit 85 → 86), with its whole gate:
  the census, the new Windows reference test, then the every-object sweep and the random-play bot on all eight built
  levels (1–5, 10, 11, 15), both shells. With commands cut off at ten minutes and no answer to Q21, run the sweep and
  the bot one level at a time in the foreground; if one level cannot finish in ten minutes, stop there and say so.
  Only if there is clearly room afterwards: 6A-CH1 ⚑ (the Goblin Chief, part one).
- **Start state:** main holds levels 1–5, 10 and 11 playable, plus the plants and level 15's weather behind a closed
  level; Core suite 737 and Windows kit 85, 0 failed (run 60, at e00db25); the Windows test run and the smoke passed
  by day in run 60 and are next owed at the wave end after level 18; sweep and bot last clean on seven levels (run 56).
- **Must not happen:** the level task merged without its sweep and bot; a pinned value moving unless the card names
  it; the level-15 first frame compared with the wrong value (it is `49eddc24d9989d95`, tick 143); a launch at
  night or unmuted; more than four heavy workers; a card's numbers trusted over the level data or the original.
- **Done means:** the task merged with its gate, the sweep and bot summary lines recorded, STATE and NEXT updated,
  a handoff on main, main pushed.
