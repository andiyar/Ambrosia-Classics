STATUS: CONTINUE

# NEXT — Ferazel's Wand, run 51: the first 6A build run — 6A-BL, 6A-CF ⚑, 6A-FR

You are the seat for **Ferazel's Wand** in Ambrosia Classics, repo `/Users/andiyar/Developer/Ambrosia-Classics`
(`$REPO`). Method: `~/Developer/Toolkits/fable-kit/orchestrator.md`. This is a build run. In your first message say
which model you are and, in one sentence, what you will do first; then start.

**Authority:** `docs/superpowers/plans/2026-11-04-ferazel-remainder.md` — the one plan. This run's cards: `#### 6A-BL`,
`#### 6A-CF`, `#### 6A-FR` in "Wave 5 — Phase 6A", with that section's opening rules, "Verification-model additions
for 6A" (the ladder, Gate-F) and "Execution order". Read also "0. The verification model", "Machine gates",
"Invariants and hazards", "Shared architecture". Nothing else is a plan.

## Read first
1. `CLAUDE.md` (repo root).
2. `docs/STATE.md` — the Ferazel block: the live state. This chip holds no state.
3. `docs/QUESTIONS.md` "Open" — act first on any new text under an `Answer:` (Q18 is Ben's Phase 5 gate: notes become
   tasks at the head of the 6A order; a fail stops the build and becomes a fix wave. Q19: his choices on the 6A plan)
   and record it in `docs/DECISIONS.md`.
4. `docs/DECISIONS.md` D46, D47 and `docs/handoff-2026-11-11-ferazel-run50.md`.

## Reconcile first
- `git -C "$REPO" worktree list`, `git -C "$REPO" log --oneline -8 main`: main at or past run 50's close.
- G1 HectorKit per the plan's gate table.
- G2 at the head, once (background, 40-minute limit, from a `git archive` copy): 620, 0 failed, the two opt-in skips by
  name — the first build run since run 48.

## This run
| task | what it must produce | Core after |
|---|---|---|
| **6A-BL** | the built-level list replaces the range; the scripts read it from one source | 622 |
| **6A-CF** ⚑ | the whole picture-cache registration list, keyed by record, the fireball records with it | 628 |
| **6A-FR** | the falling rocks' player arm | 633 |

- Per task: one `fk-implementer`, then two Opus review legs (spec, then quality with a mutation table, told what leg 1
  found), a fix round, the seat's own G2 at merge. Brief each leg with the card, the document section and dump span the
  card cites, and the test names; do not pre-read source.
- Reviewers write full findings to a scratch file and hand back a verdict; the fix round reads the file. Each leg
  builds in its own `mktemp` copy.
- No golden may move in this run (◈ is on no task here): any moved value is a STOP.
- No launch is planned: this run ends no wave (Proof B and the Fable cross-check come at run 52's end, wave 6A.1).

## Binding rules
- Launch a build only **muted**, few and short, **never 21:00–09:00** — LAUNCH GUARD first. Headless work any hour.
- Game data and dumps are read-only: never edit `Resources/Ferazel/` or `ghidra/ferazel/`.
- Subagents: `fk-implementer` / `fk-reviewer`, **no `model` parameter** (Opus 5.5).
- Memory: at most 4 workers; never two heavy things at once; a sweep or bot is stopped with a plain
  `kill <script pid>` (never `-9`), the outer shell too; the 4 GB per-worker limit is never raised.
- Never wait silently. Cap 300k of your own context (`get_usage` before each dispatch and at the close; at ~240k
  finish the task in flight and close — a task not reached moves to the next chip).
- Dump beats bank beats plan. Explicit-path commits, no `git stash`, `git branch --show-current` before each commit.
  Never commit a `__pycache__` folder. After any plan edit that renames a card, run
  `python3 -I -B tools/ferazel/later-levels-ledger.py --check`.

## Close (in this order)
1. Merge to local main `--ff-only` by SHA.
2. "As executed" under each card; rulings in `docs/DECISIONS.md` under the next free number.
3. `docs/STATE.md`: replace the Ferazel block with today's state only; settled bits to the top of
   `docs/STATE-history.md`. One line in `docs/LOOP-LOG.md`. A short handoff. One memory note + index line.
4. Rebuild this file from nothing for the next run (run 52: 6A-W1 ⚑ ◈ and 6A-W2 ⚑ ◈, the end of wave 6A.1; or the
   tasks this run did not reach, first).
5. Push main, then start the next attended session (`start_session`, fresh context, brief "read docs/NEXT.md and run
   it") — unless a question only Ben can answer blocks the next step (then `STATUS: BLOCKED`, the item in QUESTIONS
   with `Blocks: everything`, no new session).
