# Handoff — Ferazel's Wand, run 47 resumed (2026-11-10): the sweep leak, then the close

Written by the run 47 seat (Fable) when it passed its 300k context cap. The successor session finishes run 47 from here.
Work in this worktree, branch `claude/ferazel-run-47-e0431c`. Read `CLAUDE.md`, then this file; nothing else first.

## Where things stand
- **Local main = a023930** (OX merged, not pushed). **This branch = LV5 on top** (1d907fc, aafa17d, 0f7d839) plus one
  WIP commit holding run 47's close documents. LV5 is implemented, passed both Opus review legs and its fix round, and
  the seat's own full suite at 0f7d839 was **619 = 486 + 133, 0 failed, the two opt-in skips by name**; GW1 0/2,
  GW3 0/1, GW4R main menu identical, G7/G7b/G8/G7W/GW-symlinks empty, G-MUTE 1/1 (all at 0f7d839, 2026-11-08).
- **Owed before LV5 merges and run 47 closes:** the visit sweep and the random-play bot on levels 1–5 (`both`), and
  Proof B (expected 616 / 0 / 3 / 0 of 619).
- **The close documents are drafted in the WIP commit** with three placeholders to fill from your own runs —
  `@@SWEEP@@`, `@@BOT@@`, `@@PROOFB@@` — and `@@MAIN@@` (the pushed SHA): `docs/STATE.md` (Ferazel block),
  `docs/LOOP-LOG.md` (last line), `docs/handoff-2026-11-08-ferazel-run47.md`. Also drafted: the OX and LV5 As-executed
  notes in the plan, the run 47 As-built paragraph in D44 (`docs/DECISIONS.md`), bank corrections, `docs/NEXT.md`
  re-seeded for run 48 (`STATUS: CONTINUE`), `docs/progress-for-andrew-2026-11-08.md` (Ben asked for it; plain English;
  check its claims against your gate results before the close, and rename it to today's date if you change it).
  Amend these drafts for what happened on 2026-11-10 (this file's story); do not rewrite them from nothing.

## What happened on 2026-11-08 and 2026-11-10 — the seat panicked Ben's Mac twice
The wave-end chain `tools/ferazel-visit-sweep.sh both` took the Mac down both times (panic reports
`/Library/Logs/DiagnosticReports/panic-full-2026-11-08-144722` and `…-2026-11-10-084815`): four `xctest` workers at
36–40 GB each on a 64 GB machine, then a watchdog timeout. Diagnosed safely on 2026-11-10 (one worker, killed past 3 GB):

| one worker | memory |
|---|---|
| Core path (`FerazelRenderTests.VisitSweepTests`), level 4, 1,000 visits | flat ~140 MB |
| Core path, level 5, all 128 visits | flat ~130 MB |
| Windows path (`FerazelWinKitTests.WinVisitSweepTests`), levels 1, 4, 5 | ~70 MB gained per visit; 3 GB after ~40 visits |
| Windows path at 2d82e7e (before run 47) | the same — run 47 did not introduce it |

**Cause:** every visit on the Windows path builds a fresh `WinGame`, and a finished game is never freed. `leaks` on the
live worker shows root cycles `LevelRun --services--> FerazelDriver --flow--> GameFlow` (which owns the `LevelRun`), and
`FerazelDriver.configuredRun --> LevelRun` (`Ferazel/Shared/FerazelDriver.swift:105` `flow`, `:124` `configuredRun`;
`LevelRun.swift:199` `services`). The Core-path sweep mirrors the driver in its own test code and does not leak. Players
are unaffected (one game per process). The Windows and Shared sources have not changed since 2026-10-30, so the leak is
old; the per-game size grew with Phase 5 until four workers no longer fit (an inference, not measured). The sweep
script's only guard is a free-memory wait before a worker starts; nothing watches a running worker. The bot
(`tools/ferazel-random-play.sh`, `WinRandomPlayTests`) uses the same path and is unmeasured.

## Ben's instruction (2026-11-10): "Yes, fix both"
1. **Break the ring when a game ends** so each finished game is freed (the shared driver's or `WinGame`'s shutdown —
   the smallest change that does it; both shells use `Ferazel/Shared`, so lockstep (c) applies: reviewed for both, G5 and
   GW1–GW4 run), with a test that a finished game is actually released (a weak reference going nil), in WinKit.
2. **A hard per-worker memory limit in both scripts** (`tools/ferazel-visit-sweep.sh`, `tools/ferazel-random-play.sh`):
   a watchdog that samples each running worker (`ps -o rss`, and `top -l 1 -pid … -stats mem` for the footprint
   including compressed pages), kills it past a limit (default a few GB, overridable), and writes a failure row so the
   exit code is non-zero. The plan's memory rule and the script header get the new rule.
Method as always: one `fk-implementer`, then two Opus review legs (spec, then quality), no `model` parameter. A new test
function moves the WinKit ladder 81 → 82: record it in the plan's gate table, STATE and the chip (and Proof B's N is
the Core ladder, unchanged).

## Hard safety rules for this session (do not relax them)
- **Never run the sweep or the bot at full width until one guarded worker has shown flat memory on the Windows path**
  after the fix. The guarded runners used for the diagnosis are saved beside this group's notes:
  `…/side-session-notes/local_ba78f64c-bbb1-4599-b524-5870fffd4bbc/ferazel-guarded-sweep-core.sh` and
  `ferazel-guarded-sweep-windows.sh` (usage: `<levels> <visit limit> <max MB> <max seconds> <tag>`; they need their `S=`
  scratch path edited to your own scratchpad). The leak checker's raw output is `ferazel-win-sweep-leaks-2026-11-10.txt`
  there. Tell every subagent the same rule in its brief: no sweep, no bot, no whole suite; filtered classes only.
- After any unexplained session death, read `/Library/Logs/DiagnosticReports/panic-full-*` before re-running anything.
- Another session (Castles) runs heavy tests on this Mac: at most one heavy thing of ours at a time, 4 workers at most.
- Launches muted only; never 21:00–09:00 (Ben waived the morning limit for 2026-11-10 only).

## Then close run 47 (the order in the old chip, `git show 2d82e7e:docs/NEXT.md`, section "Close")
G2 at the final head from a `git archive` copy (619 expected; WinKit 82 if the release test is a new function); GE both
shells on levels 1–5 through the now-guarded scripts; Proof B; merge to local main `--ff-only`; fill the placeholders;
commit the documents with explicit paths; push main; update the memory note
`ferazel-run47-ox-lv5-2026-11-08.md`; then **start run 48** ("read docs/NEXT.md and run it", fresh context, same seat
model) — Ben, 2026-11-10: "and then trigger the next one please". The finished worktrees `ferazel-run-44-7428b3` and
`ferazel-run-45-f94cf1` could not be removed (the app refused); leave them for Ben.
