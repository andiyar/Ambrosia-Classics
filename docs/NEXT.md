STATUS: CONTINUE

# NEXT — Ferazel's Wand, run 50: the owed launch checks, then the Phase 6A plan (P6A)

You are the seat for **Ferazel's Wand** in Ambrosia Classics, repo `/Users/andiyar/Developer/Ambrosia-Classics`
(`$REPO`). Method: `~/Developer/Toolkits/fable-kit/orchestrator.md`. This is a planning run: no game code. In your
first message say which model you are and, in one sentence, what you will do first; then start.

**Authority:** `docs/superpowers/plans/2026-11-04-ferazel-remainder.md` — the one plan. This run's card: `### Task P6A`
(with the As-executed notes under LL, BOS and ENG just above it) and the "Wave 5 — Phase 6A" cards it replaces. Read
also "0. The verification model", "Machine gates", "Invariants and hazards", "Shared architecture", "Stand-ins kept at
the Phase 5 end". Nothing else is a plan.

## Read first
1. `CLAUDE.md` (repo root).
2. `docs/STATE.md` — the Ferazel block: the live state, including what is **owed by day**. This chip holds no state.
3. `docs/QUESTIONS.md` "Open" — act first on any new text under an `Answer:` (Q18 is Ben's Phase 5 gate: notes become
   tasks at the head of the 6A plan; a fail stops planning and becomes a fix wave) and record it in `docs/DECISIONS.md`.
4. `docs/DECISIONS.md` D46 (the research rulings) and `docs/handoff-2026-11-11-ferazel-run49.md`.

## Reconcile first
- `git -C "$REPO" worktree list`, `git -C "$REPO" log --oneline -8 main`: main at or past run 49's close.
- G1 HectorKit per the plan's gate table.
- **The owed launch checks, only if the LAUNCH GUARD says day (09:00–20:59), muted:** follow
  `docs/handoff-2026-11-10-ferazel-run48.md` "Owed" 1–3 (fresh stage, G9M, GW6, GWB, GW4R, cards updated, stage again).
  One heavy thing at a time; background Proof B with a time limit of hours. By night: leave them owed, say so in
  LOOP-LOG, carry the item to the next chip.
- G2 is not re-run at the head unless a commit since run 48's close touched `Ferazel/` code (docs-only: skip, say so).

## This run
| task | what it must produce |
|---|---|
| **P6A** | the Phase 6A plan, expanded in place in the one plan file ("Wave 5 — Phase 6A": the cards replaced by bite-sized tasks); two Opus review legs, then the Fable cross-check |

- The planner is one `fk-implementer` (Opus). Its inputs are the three research documents under `docs/ferazel/` —
  `later-levels-ledger.md`, `phase6-boss-contracts.md`, `phase6-engine-contracts.md`. **It starts from each document's
  closing "Corrections to the plan's cards (for the 6A planner)" and from the engine document's ordered 6A task list**,
  and applies D46 (one owner per type; 6A-FB folded into 6A-CF; feature goldens on a test-only level fixture; measured
  frames). The seat does not read the research documents whole: it briefs with section names.
- The plan carries contracts, not code: per task Files / Contract (document section + dump lines) / Tests (names + the
  number each pins) / Gate / Commit; the 6A ladder from Core 620 and WinKit 82; execution order with the tasks grouped
  into runs (2 a run, 3 when at most one is ⚑); stand-ins; known deviations; the gate card's outline; the sweep's and
  bot's time and memory budget as levels 10–22 join (Ben's RAM rule). First tasks: 6A-BL, then 6A-CF, then the rocks
  and the Warrior.
- Review: leg 1 checks the plan against the three documents and the P6A card (every type, switch and routine of levels
  10–22 owned exactly once; every level task after the features its data switches on); leg 2 checks that each task is
  buildable as written (files exist, test names unique, ladder arithmetic, lockstep). Have each leg write its full
  findings to a scratch file and hand back a verdict; the fix round reads the files.
- The Fable cross-check of the plan: a Fable seat does it itself, after the fix round; otherwise `fk-reviewer` with
  `model: "fable"`.
- The plan's choices that Ben may want to see go into one QUESTIONS item for his later read (does not block).

## Binding rules
- Launch a build only **muted**, few and short, **never 21:00–09:00** — LAUNCH GUARD first. Headless work any hour.
- Game data and dumps are read-only: never edit `Resources/Ferazel/` or `ghidra/ferazel/`.
- Subagents: `fk-implementer` / `fk-reviewer`, **no `model` parameter** (Opus 5.5), except the one Fable cross-check.
- Memory: at most 4 workers; never two heavy things at once (Proof B is heavy); a sweep or bot is stopped with a plain
  `kill <script pid>` (never `-9`), the outer shell too; the 4 GB per-worker limit is never raised.
- Never wait silently. Cap 300k of your own context (`get_usage` before each dispatch and at the close; at ~240k
  finish the task in flight and close).
- Dump beats bank beats plan. Explicit-path commits, no `git stash`, `git branch --show-current` before each commit.
  Never commit `docs/ferazel/tools/__pycache__/`.

## Close (in this order)
1. Merge to local main `--ff-only` by SHA.
2. "As executed" under the P6A card; rulings in `docs/DECISIONS.md` under the next free number; the QUESTIONS item.
3. `docs/STATE.md`: replace the Ferazel block with today's state only; settled bits to the top of
   `docs/STATE-history.md`. One line in `docs/LOOP-LOG.md`. A short handoff. One memory note + index line.
4. Rebuild this file from nothing for the next run (the first 6A build wave: 6A-BL and 6A-CF; or the plan's review
   legs if they were not reached).
5. Push main, then start the next attended session (`start_session`, fresh context, brief "read docs/NEXT.md and run
   it") — unless a question only Ben can answer blocks the next step (then `STATUS: BLOCKED`, the item in QUESTIONS
   with `Blocks: everything`, no new session).
