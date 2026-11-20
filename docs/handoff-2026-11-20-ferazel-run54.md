# Handoff — Ferazel's Wand, attended run 54 (2026-11-20)

**What happened.** Three tasks merged, all three the chip offered. Nothing is visible to a player yet: no level past 5
opens until levels 10 and 11 do (the task after next).

| task | what it is | commits |
|---|---|---|
| 6A-RP | the river backdrop of levels 11 and 18 ripples; the underwater tint proven against the original | dea9c0b, fix 5cbade1 |
| 6A-BX1a | the scenery of levels 10–22 (decorations, outcrops, mushrooms); the three graves on level 21 are touched from the correct, mirrored side | b944bf5, fix f0c6bed |
| 6A-BX1b | teleporters on levels 21 and 22, furniture, and three characters who each open the right conversation | aae8457, fix 0c44f1a |

**How the tasks went.** Each: one implementer, two Opus review legs, one fix round. No blockers anywhere. The reviewers
planted bugs to test the tests:

| task | planted | caught | harmless | slipped through | after the fix round |
|---|---|---|---|---|---|
| 6A-RP | 68 | 58 | 6 | 4 | 0 |
| 6A-BX1a | 90 | 84 | 1 | 5 | 0 |
| 6A-BX1b | 48 | 47 | 0 | 1 | 0 |

No existing picture or pinned value moved, except the one count the third card named (level 22's load bar: one more
cached picture).

**Rulings (D53).** The ripple's picture starts Ferazel low on level 11, because from the level's own start the camera
never shows a rippling row — so level 11's own first frame will not show the ripple either. One recorded difference
from the original: decorations placed mirrored that have nothing to touch keep an all-zero rectangle where the original
stores a mirrored empty one; nothing reads it, and matching it would move two pinned level 1–5 values. The plan's
sentence that every level 1–5 decoration has an empty rectangle was wrong (one type has a real one) and is corrected.

**Numbers (the seat's own runs).**

| when | commit | Core suite |
|---|---|---|
| start | c47416e | 693, 0 failed |
| after the ripple | c84c46c | 703, 0 failed |
| after the scenery | 8968f2e | 709, 0 failed |
| after the teleporters and characters | 579b17f | 713, 0 failed |

The two opt-in skips by name each time. WinKit, the census and the launch checks were not re-run (nothing they cover
changed; none owed): see `docs/STATE.md`.

**Method notes for the next seat.**
- Background work was off. The whole suite ran as four foreground commands after one build (rules half about 1
  minute; render classes A–E about 8, F–L about 5, M–Z about 2).
- A fix round was done by a fresh implementer briefed from the two review files and the reviewer's ready-made patch,
  because a resumed helper runs in the background. It worked well each time.
- Context: 142k before the first dispatch, about 25k a task, about 25k for the close.
- **Weekly usage limit: 87% (all models), 89% (Fable) at the close; resets 2026-11-23.** A run started before then may
  be cut off.
- **6A-L10L11 needs a decision before it starts**: its gate includes the full object sweep and the random-play bot on
  every built level, which take far longer than the ten minutes one foreground command gets. The next chip says to
  settle how they run first, or to ask.

## The brief for run 55 (rebuilt from nothing)

You are the orchestrator seat for Ferazel's Wand, run 55, in `/Users/andiyar/Developer/Ambrosia-Classics`. Read
`docs/NEXT.md` and run it; work in your own worktree. The state is in `docs/STATE.md` (the Ferazel block), the plan is
`docs/superpowers/plans/2026-11-04-ferazel-remainder.md`.

- **Do:** 6A-MC (prove the conversations and chapter cards of levels 10–22; Core 713 → 716). Then, only if the context,
  the clock and the weekly limit allow the whole of it with its gate: 6A-L10L11 ⚑ (levels 10 and 11 open; Core → 722),
  with the wave 6A.2 end (the full sweep and bot on every built level, then Proof B by day, muted).
- **Start state:** main holds run 54's three tasks; Core suite 713, 0 failed, two opt-in skips; HectorKit ef2c341
  clean; no launch check owed until the wave end.
- **Per task:** one `fk-implementer`, two `fk-reviewer` legs (spec, then quality with planted bugs), a fix round, your
  own whole-suite run, then merge to local main by fast-forward.
- **Must not happen:** an existing pinned value moving unless a card names it; a launch at night or unmuted; more than
  four heavy workers; a level task split from its gate.
- **Done means:** the tasks merged with their gates, STATE and NEXT updated, a handoff on main, main pushed.
