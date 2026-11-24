# Handoff — Ferazel's Wand, run 69 (2026-11-25)

**Seat:** Fable 5.2, started by the Coordinator; foreground only.
**Times:** started 2026-11-25 05:52, closed 10:50 (Sydney) — night into day.
**Context:** 119k at the start, 203k when the gates were done, about 240k at the close. Weekly limit at the close:
40% Fable, 54% all models.

## What is now true
- **Level 21 "Obfuscation & Edification" is open** (task 6A-L21, on main at 63183f8). It is a dark level with six
  pipes that push enemies out, insects, fourteen teleporters, graves that talk, and blinking and crumbling
  platforms. Playable levels on main are now 1–5, 10, 11, 15, 18, 20 and 21.
- The only game-code change is the list of built levels gaining 21. Everything the level needs was already built.
- Two reviewers passed it with test-only fixes. The second planted 42 deliberate bugs: 36 were caught, 4 behave
  the same as correct code on this level's data, and 2 exposed missing checks, which are now added.
- Numbers, all the seat's own runs at the merged commit:

  | check | result |
  |---|---|
  | Core suite | 800 (798 passed, 0 failed, the 2 named opt-in skips) |
  | Windows-kit suite | 89 (87 passed, 0 failed, the 2 named skips) |
  | census, Mac app build, both Windows cross-builds, the Mac SDL build | all pass |
  | visit sweep, 11 levels | 9,824 visits on each path, no failures |
  | random-play bot, 11 levels | 237,600 steps on each path, no failures |

- No picture or state value of any other level moved.
- **Levels 20 and 21 were launched muted by day and both stayed running** with no crash. Nobody saw the picture:
  the seat's request to look at the game window was declined. **Eyes on both levels are still owed.**

## Rulings (D70)
1. Record 283 is level 11's, armed by a level-22 conversation — not level 21's, as an old note said. Its
   reappearing on a revisit is now proven on level 11.
2. Level 21 is not the first built level with the darkness setting on (levels 1–4 and 10 have it too); the old
   note was wrong. No change to the draw audit was needed.
3. The fix round changed tests and comments only, proven by an empty source diff.
4. The Windows picture reference for level 21 has no "darkness off" twin; the Mac picture carries it.
5. A boot check the seat cannot look at is recorded as "started and stayed running", never as "seen".
6. One heavy command a message: five sent together ran at once (all passed, one ran slow).

## Open
- **Mailbox Q1** (what a lit blade on level 20 shows) is still unanswered; "plain and unlit" stands.
- **Owed:** somebody's eyes on levels 20 and 21; the Windows test run under CrossOver and the Mac SDL smoke at the
  wave end, by day.
- Small carries are in STATE under "From run 69".

## Housekeeping
- Run 69's worktree `focused-moser-e73dfb` is removed at the close (it held the branch checkout and two build
  folders, 1.3 GB).
- Every scratch copy, build folder and log this run made is deleted; the two review files and the reviewer's patch
  stay in the session's scratch folder until a restart.
- Run 67's folder `Aki/.claude/worktrees/exciting-panini-fdb834` still holds about 560 MB — remove by hand.

## The brief for the next run (run 70)
Read `docs/NEXT.md` in `/Users/andiyar/Developer/Ambrosia-Classics` and run it. It is one task: **6A-CP — the
magic carpet** (Core 800 → 812, Windows-kit stays 89), a type task built and tested on a stand-in copy of level 22
(the only level with a carpet; level 22 itself is not open yet). The plan is
`docs/superpowers/plans/2026-11-04-ferazel-remainder.md` (the card `#### 6A-CP`; the model for a type task is
"As executed — 6A-PS"). Live state is the Ferazel block of `docs/STATE.md`; this run's rulings are D70 in
`docs/DECISIONS.md`. Its gate has no full sweep or bot unless a built level turns out to hold a carpet — check the
level data first. Do not start level 22 in the same run. Do not ask to look at the game window: that was declined
in run 69 and stays with Ben. Helpers are `fk-implementer` / `fk-reviewer` with no model parameter; foreground
only, one heavy command a message; questions for Ben go to the Coordinator mailbox (next free number Q2).
