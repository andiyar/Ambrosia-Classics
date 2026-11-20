# Handoff — Ferazel's Wand, attended run 59 (2026-11-21, 07:56 → 07:58; both times from `date`)

**What happened.** The run stopped at its first step and changed nothing in the game. No build was launched, no
test suite was run, no helper was dispatched. Only the records moved.

**Why it stopped.** Two things, either one enough:

| # | what | detail |
|---|---|---|
| 1 | The Windows test run cannot run in this kind of session | It is one command of 13 minutes or more. Sessions the Coordinator starts have background work off and each command is cut off at ten minutes. Q20 asks Ben how it should run; it has no answer. |
| 2 | Both check scripts refuse before 09:00 on their own | They read the clock and exit unless the hour is 09 to 20. There is no override. Measured at 07:58: refused, "hour 07". |

**Ben's words** (07:56, to the Coordinator): "hoested by my own petartd. it's fine, go." Recorded in D57. They lift
the wait for 09:00; they do not answer Q20, and they cannot make the scripts run early. The seat did not edit or go
around the clock check: it is Ben's launch rule (D42) written into the scripts.

**Why the run did not wait an hour to do the smoke alone.** The smoke is the small check; the Windows test run is the
one that holds up the build. Closing at once puts the one question in front of Ben while he is at the keyboard.

**The one question for Ben (Q20, now "Blocks: everything").** How may the 13-minute Windows test run be run?
- **a** — the session starts that one script detached and watches its log (recommended);
- **b** — the Coordinator runs it itself by day;
- **c** — Ben runs it once after 09:00 and pastes the last line under Q20's `Answer:`:
  `cd ~/Developer/Ambrosia-Classics && tools/windows/proof-b-ferazel.sh`

**Still owed — both by day (09:00–21:00), in this order, before any task.**

| # | item | expected |
|---|---|---|
| 1 | the Windows test run under CrossOver, muted (Proof B) | 719 passed / 0 failed / 3 skipped of 722 |
| 2 | the Mac SDL smoke | exit 0 |

**For the Coordinator.**
- **Do not start run 60 until Q20 has an answer** (or you can give the session commands longer than ten minutes).
  `docs/NEXT.md` is `STATUS: BLOCKED`. A run started without one will stop exactly as this one did.
- **Start it at 09:00 or later, and before about 18:00.** Ben's word cannot move the scripts' clock check.
- If Ben answers **b**, the command is `tools/windows/proof-b-ferazel.sh` (no argument) from the main checkout,
  by day, nothing else heavy beside it; record its last line under Q20.

**Numbers.** Weekly usage 19% (all models), 28% (Fable). Seat's context: 111k at the start, about 135k at the close.
No memory note written (nothing new that the repo does not now record). Worktree `quirky-galileo-f0da25` removed at
the close (241 MB, this run's own checkout, no build output).

## The brief for run 60 (rebuilt from nothing)

You are the orchestrator seat for Ferazel's Wand, run 60, in `/Users/andiyar/Developer/Ambrosia-Classics`. Read
`docs/NEXT.md` and run it; work in your own worktree. The state is in `docs/STATE.md` (the Ferazel block); the plan
is `docs/superpowers/plans/2026-11-04-ferazel-remainder.md`.

- **First:** read Q20's `Answer:` in `docs/QUESTIONS.md`. With no answer and commands cut off at ten minutes, stop
  at once with nothing changed. Check the hour with `date`: the two check scripts only run from 09:00 to 20:59 and
  cannot be overridden. Read the weekly usage limit (above about 70%, no ⚑ task).
- **Do, in order:** (1) the Windows test run by day, muted, the way Q20's answer says — expect 719 / 0 / 3 / 0 of
  722. (2) The Mac SDL smoke by day. (3) 6A-BG1c — the plants of levels 15 and 18 (Core 722 → 725). (4) 6A-RN ⚑ —
  rain, thunder, the side push (Core → 737, WinKit 84 → 85). Level 15 (6A-L15) is the run after, unless there is
  clearly room.
- **Start state:** main holds levels 10 and 11; Core suite 722, 0 failed, two opt-in skips (run 58, at 66875a3);
  WinKit 84; sweep and bot clean on seven levels, both shells (run 56); the wave's cross-check and its fix round
  done; the two launch checks owed. Run 59 changed records only.
- **Must not happen:** a task started while either owed check is open; a launch at night or unmuted; the scripts'
  clock check edited or bypassed; a pinned value moving unless a card names it; more than four heavy workers; a
  card's numbers trusted over the level data.
- **Done means:** the owed checks recorded, the tasks merged with their gates, STATE and NEXT updated, a handoff on
  main, main pushed.
