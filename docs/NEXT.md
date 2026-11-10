STATUS: CONTINUE

# NEXT — Ferazel's Wand, run 48: A5 + the Fable cross-check = the Phase 5 machine end

You are the seat for **Ferazel's Wand** in Ambrosia Classics, repo `/Users/andiyar/Developer/Ambrosia-Classics`
(`$REPO`). Method: `~/Developer/Toolkits/fable-kit/orchestrator.md`. You run this one wave, close it, and — because the
run after this one is the Phase 6 planning run, which does not wait for Ben — start the next session. In your first message say which model you are and, in
one sentence, what you will do first; then start.

**Authority:** `docs/superpowers/plans/2026-11-04-ferazel-remainder.md` — the one plan. This run's cards: `#### A5` and
"#### The Phase 5 gate card" under "Wave 3 — run 47: OX → LV5 …; run 48: A5 + the Fable phase review", plus "Stand-ins
kept at the Phase 5 end" and "Known deviations". Read also "0. The verification model", "Machine gates", "Invariants
and hazards". Nothing else is a plan.

## Read first
1. `CLAUDE.md` (repo root).
2. `docs/STATE.md` — the Ferazel block: the live state. This chip holds no state.
3. `docs/QUESTIONS.md` "Open" — act first on any new text under an `Answer:` and record it in `docs/DECISIONS.md`.
4. The plan headings above; the As-executed notes under `#### OX` and `#### LV5` (run 47's rulings and stand-ins — the
   gate card names them).

## Reconcile first
- `git -C "$REPO" worktree list`, `git -C "$REPO" log --oneline -8 main`: main at or past run 47's close. Finished
  worktrees `ferazel-run-44-7428b3`, `ferazel-run-45-f94cf1`, `ferazel-run-47-e0431c` — remove if clean (the app may
  refuse; then leave them for Ben).
- G1 HectorKit per the plan's gate table (follow kit main; a new SHA and its zero-skip count go into STATE and LOOP-LOG).
- G2 once at the head: **619** total = 617 passed + the 2 opt-in skips by name, 0 failed (486 + 133). Any other number:
  STOP, reconcile, record.

## This run
| task | what it must do | Core after |
|---|---|---|
| **A5** minor | the three standing checks, the `later: Phase 5` relabel sweep (everything Phase 5 built loses its label; Phase 6 stand-ins keep theirs), both builds staged (`tools/stage-ferazel.sh`, `tools/windows/stage-ferazel-win.sh`), the smoke script reading the Windows references from the test file, ONE gate card (Mac part + Windows part) written from the plan's card into `docs/QUESTIONS.md` | 619 |
| **Fable cross-check, Phase 5 end** | after A5's two Opus legs: one `fk-reviewer` with `model: "fable"`, read-only, the whole Phase 5 diff (Mac + Windows, from the Phase 4 end to A5) and the gate card; findings → one tests-only fix round, behaviour findings → rulings in DECISIONS | 619 |

Phase 5 then closes on the machine side only: "machine gates green; Ben's gate pending". **STOP for Ben's gate is NOT a
stop of the chain:** run 49 (Phase 6 research + the 6A plan) does not wait for his verdict.

## Gates (commands in the plan's "Machine gates"; numbers as of run 47's close)
| gate | expected |
|---|---|
| at the head | G2 619 · GW2 82 · G3 1,108 / 0 · HectorKit ef2c341, zero-skip 370 |
| G2 / GW2 after A5 | 619 / 82; 0 failed; exactly the opt-in names |
| Phase end | G3; GE `both` on levels 1–5 (sweep + bot exit 0); GWB by day **616 / 0 / 3 / 0 (of 619)**; GW4R; GW5 (stage, any hour), GW6 and G9M by day, MUTED, after the LAUNCH GUARD |
| ◈ | A5 is not ◈: any moved golden or `BootFacesTests` pin is a STOP |

## Binding rules
- Launch a build only **muted**, few and short, **never 21:00–09:00** — LAUNCH GUARD first; by night write "boot check
  owed (night rule)". Headless tests any hour.
- Game data and dumps are read-only: never edit `Resources/Ferazel/` or `ghidra/ferazel/`.
- Subagents: `fk-implementer` / `fk-reviewer`, **no `model` parameter** (Opus 5.5), except the one Fable cross-check
  above; foreground. Two Opus legs per task (spec, then quality with a mutation table, told what the first found); a
  fix-round leg re-runs `DrawModeAuditTests` whenever a source file gained or lost a line (run 47 lesson).
- Memory: the sweep and the bot now kill any worker past `MAX_WORKER_MB` (4096) and write a `memory` row (exit 1) —
  never raise the limit, a memory row is a leak to fix; stop a background run with `kill <script pid>`. Still:
  never two heavy suites at once; at most 4 test workers; one seat gate run in a `git archive` copy beside one
  working implementer, or two review legs alone; each leg in its own `mktemp` copy.
- Never wait silently; background long gates. Cap 300k of your own context (`get_usage` before each dispatch and at the
  close; at ~240k finish the task in flight and close).
- Never edit a golden or an expectation to make a number agree — STOP, reconcile, record. Dump beats bank beats plan.
- Explicit-path commits, no `git stash`, `git branch --show-current` before each commit. Push main at the close.

## Close (in this order)
1. Merge A5 to local main `--ff-only` by SHA.
2. "As executed" under the A5 card; the Phase 5 "As built" paragraph in `docs/DECISIONS.md` (the phase's machine close);
   bank corrections appended to the named bank file.
3. `docs/STATE.md`: replace the Ferazel block with today's state only; settled bits to the top of `docs/STATE-history.md`.
   One line in `docs/LOOP-LOG.md`. A short handoff `docs/handoff-<date>-ferazel-run48.md`. One memory note + index line.
4. Rebuild this file from nothing for run 49 (the planning run: tasks LL, BOS, ENG, then P6A — the plan's "Wave 4").
5. Push main, then start the next attended session (`start_session`, fresh context, brief "read docs/NEXT.md and run
   it") — unless a question only Ben can answer blocks the next step (then `STATUS: BLOCKED`, the item in QUESTIONS with
   `Blocks: everything`, no new session).
