# Handoff — Ferazel's Wand, run 68 (2026-11-25)

**Seat:** Fable 5.2, started by the Coordinator; foreground only; nothing launched (the whole run was at night).
**Times:** started 2026-11-25 03:15, closed 05:51 (Sydney).
**Context:** 127k at the start, 179k when the task merged, about 200k at the close. Weekly limit at the close:
37% Fable, 50% all models.

## What is now true
- **The enemy pipes are set up by the level itself** (task 6A-PS, on main at ed50fba). These are the pipes that
  push enemies out; they are first placed on level 21, which is not open yet, so nothing a player can reach today
  has changed. No built level holds a pipe.
- **A level restart is handled as the original does it.** The first reviewer found, and the second proved, that
  the original measures a pipe from its real picture when a level is restarted and from a 64 × 64 stand-in on a
  first load, so an enemy comes out of a pipe 16 pixels further right after a restart. That was built in the fix
  round, with its own test.
- A pipe that would make an enemy type the port has not built is now refused loudly instead of quietly skipped.
- Numbers, all the seat's own runs at the merged commit, all after the fix round:

  | check | result |
  |---|---|
  | Core suite | 797 (795 passed, 0 failed, the 2 named opt-in skips) |
  | Windows-kit suite | 88 (86 passed, 0 failed, the 2 named skips) |
  | Mac app build, both Windows cross-builds, the Mac SDL build | all succeed |
  | visit sweep and random-play bot | not run (not owed: no built level changed; run 67's stand) |

- No picture or state value of any level moved.

## Rulings (D69)
1. The restart fix has its own test, so the Core count is 797, one above the card's 796; every later number in
   the plan was moved up by one again (level 21 → 800, the carpet → 812, the phase ends at 816).
2. The fix round was allowed to touch the session file and the ledger script.
3. An unbuilt pipe child is refused at the level spawn (the audit's refusal count for that file 13 → 14).
4. The card's "child across the pipe's idling" does not exist: pipes are never idled.
5. A fix round that changes source voids every gate run before it.
6. Level 21 was not started: the context was past the mark NEXT sets for starting a level task.

## Open
- **Mailbox Q1** (what a lit blade on level 20 shows) is still unanswered; "plain and unlit" stands.
- **Owed by day:** the muted boot check of level 20 (owed since run 67).
- **A new carry worth a look [MED]:** the same restart rule may apply to other object types that measure
  themselves from a loaded picture. Only the pipes were read and built. It is in STATE and in NEXT's "After this
  run"; it is not yet a task in the plan.
- Small carries are in STATE under "From run 68".

## Housekeeping
- Run 68's worktree `brave-cori-3f4ae7` is removed at the close (see the closing message for its size).
- Run 67's folder `Aki/.claude/worktrees/exciting-panini-fdb834` still holds about 560 MB (unregistered; the app
  refused the delete) — remove by hand.
- Every scratch copy, build folder and log this run made is deleted.

## The brief for the next run (run 69)
Read `docs/NEXT.md` in `/Users/andiyar/Developer/Ambrosia-Classics` and run it. It is one task: **6A-L21 —
level 21 "Obfuscation & Edification" opens** (Core 797 → 800, Windows-kit 88 → 89), a level task with the full
sweep and bot on eleven levels on both paths. The plan is
`docs/superpowers/plans/2026-11-04-ferazel-remainder.md` (the card `#### 6A-L21`; the model is "As executed —
6A-L20"; what the level's pipes do is in "As executed — 6A-PS"). Live state is the Ferazel block of
`docs/STATE.md`; this run's rulings are D69 in `docs/DECISIONS.md`. Known in advance: level 21 is the first
built level with the darkness switch at 2, so the draw audit's light proofs may need a ruled change; the insects
(type 1860) are first placed there; record 283 must be shown to appear on a revisit; the live-enemy count starts
at 42 because of the six pipes. Do not start the magic carpet in the same run. Helpers are `fk-implementer` /
`fk-reviewer` with no model parameter; foreground only; questions for Ben go to the Coordinator mailbox (next
free number Q2).
