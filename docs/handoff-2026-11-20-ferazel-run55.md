# Handoff — Ferazel's Wand, attended run 55 (2026-11-20)

**What happened.** One task merged, the first of the two the chip offered. The second (opening levels 10 and 11) was
not started, on purpose. Nothing is visible to a player yet: no level past 5 opens until levels 10 and 11 do, which is
the next task.

| task | what it is | commits |
|---|---|---|
| 6A-MC | the six conversations of levels 10–22 run to their end with the right portraits; the two chapter cards (before level 10 and before level 22) draw | b999329, fix 988a1e1 |

It is a proving task: three new tests, and no game code needed changing — the conversation code and the chapter-card
screen were already right for these levels.

**Why the run stopped after one task.** The account's weekly usage limit was already at 87% when the run started and
reached 92% mid-run (it resets 2026-11-23, 15:00 UTC). Opening levels 10 and 11 is the largest task of the wave and
its long checks may not be split from it, so starting it risked being cut off half-way. It goes whole to run 56.

**How the task went.** One implementer, two Opus review legs, one fix round. No blockers. Both legs said mergeable.

| planted bugs | caught | harmless | slipped (in scope) | after the fix round |
|---|---|---|---|---|
| 79 | 54 | 9 | 14 | 1, held by an older test (the text typer skipping letters) |

Two more slipped bugs were in the card's fade-in and wait, which an older test already catches. No existing picture or
pinned value moved. No ruling was needed, so there is no new DECISIONS entry.

**New pinned pictures.**

| picture | value |
|---|---|
| chapter card before level 10 | `f33072b0df2cab4d` |
| chapter card before level 22 | `517ec825dbca68cc` |

**Numbers (the seat's own runs).**

| when | commit | Core suite |
|---|---|---|
| start | 158d668 | 713, 0 failed |
| after the task | 988a1e1 | 716, 0 failed |

The two opt-in skips by name each time. The Mac app build and the three Windows build checks are the implementer's
(all passed). WinKit, the census, the sweep, the bot and the launch checks were not re-run (tests only; none owed).

**Method notes for the next seat.**
- Background work was off. The whole suite ran as four foreground commands after one build. Running the head-of-run
  suite beside the working helpers (one command beside each dispatch) saved about twenty minutes.
- The fix round by a fresh implementer, briefed from the two review files and the reviewer's ready-made patch, worked
  again.
- Context: 127k before the first dispatch, 169k after the first review, about 215k at the close.
- The sweep and the bot can each be narrowed to one level and one shell a command, so the level task's long checks can
  run in the foreground; the next chip spells it out. Proof B's length in the foreground is the one unknown.
- Small carries are in `docs/STATE.md` ("From run 55").

## The brief for run 56 (rebuilt from nothing)

You are the orchestrator seat for Ferazel's Wand, run 56, in `/Users/andiyar/Developer/Ambrosia-Classics`. Read
`docs/NEXT.md` and run it; work in your own worktree. The state is in `docs/STATE.md` (the Ferazel block), the plan is
`docs/superpowers/plans/2026-11-04-ferazel-remainder.md`.

- **First:** read the weekly usage limit. If it is above about 70%, do not start the task: say so and stop with
  nothing changed. (It resets 2026-11-23, 15:00 UTC.)
- **Do:** 6A-L10L11 ⚑, alone — levels 10 and 11 open (Core 716 → 722, WinKit 82 → 84) — with its whole gate: the
  census, the two Windows reference tests, the quick bot on each new level, the full sweep and bot on every built
  level and both shells, then the wave 6A.2 end (Proof B and the Mac SDL smoke by day, muted; the Fable cross-check
  of the wave's diff, which may open run 57 if the context is spent).
- **Start state:** main holds run 55's task; Core suite 716, 0 failed, two opt-in skips; HectorKit ef2c341 clean; no
  launch check owed until the wave end.
- **Per task:** one `fk-implementer`, two `fk-reviewer` legs (spec, then quality with planted bugs), a fix round, your
  own whole-suite run, then merge to local main by fast-forward.
- **Must not happen:** an existing pinned value moving unless the card names it; a launch at night or unmuted; more
  than four heavy workers; the level task split from its gate or started when it cannot finish.
- **Done means:** the task merged with its gate, STATE and NEXT updated, a handoff on main, main pushed.
