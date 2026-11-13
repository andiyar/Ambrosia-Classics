STATUS: CONTINUE

# NEXT — Ferazel's Wand, run 52: the Warrior — 6A-W1 ⚑ ◈, 6A-W2 ⚑ ◈, then the wave 6A.1 end

You are the seat for **Ferazel's Wand** in Ambrosia Classics, repo `/Users/andiyar/Developer/Ambrosia-Classics`
(`$REPO`). Method: `~/Developer/Toolkits/fable-kit/orchestrator.md`. This is a build run. In your first message say
which model you are and, in one sentence, what you will do first; then start.

**Authority:** `docs/superpowers/plans/2026-11-04-ferazel-remainder.md` — the one plan. This run's cards: `#### 6A-W1`,
`#### 6A-W2` in "Wave 5 — Phase 6A", with that section's opening rules ("Every boss task"), "Verification-model
additions for 6A" (the ladder, Gate-B, "Wave end", the ◈ rule) and "Execution order"; the As-executed notes of 6A-CF
and 6A-FR (their `later:` items for 6A-W1). Read also "0. The verification model", "Machine gates",
"Invariants and hazards", "Shared architecture". Nothing else is a plan.

## Read first
1. `CLAUDE.md` (repo root).
2. `docs/STATE.md` — the Ferazel block: the live state. This chip holds no state.
3. `docs/QUESTIONS.md` "Open" — act first on any new text under an `Answer:` (Q18 is Ben's Phase 5 gate: notes become
   tasks at the head of the 6A order; a fail stops the build and becomes a fix wave. Q19: his choices on the 6A plan)
   and record it in `docs/DECISIONS.md`.
4. `docs/DECISIONS.md` D46, D47, D48 and `docs/handoff-2026-11-13-ferazel-run51.md`.

## Reconcile first
- `git -C "$REPO" worktree list`, `git -C "$REPO" log --oneline -8 main`: main at or past run 51's close.
- G1 HectorKit per the plan's gate table.
- G2 at the head, once (background, 40-minute limit, from a `git archive` copy): 633, 0 failed, the two opt-in skips by
  name.
- Read (do not re-review line by line) the two unreviewed commits of run 51 — `833506a` (the ledger check script) and
  `8c93e9e` (the regenerated ledger blocks) — they belong to the wave cross-check below.

## This run
| task | what it must produce | Core after |
|---|---|---|
| **6A-W1** ⚑ ◈ | the Warrior's real Handle replaces the stand-in: the crates, the decide, the walk and run, the swing and shot, the dying; it spawns the falling rocks | 642 |
| **6A-W2** ⚑ ◈ | the Warrior's Hit, Kill and the scripted fight (HP-0 and Kill frames measured and pinned) | 650 |

- Per task: one `fk-implementer`, then two Opus review legs (spec, then quality with a mutation table, told what leg 1
  found), a fix round, the seat's own G2 at merge. Brief each leg with the card, the document section and dump span the
  card cites, and the test names; do not pre-read source. W2 follows W1 (same files): never at once.
- Reviewers write full findings to a scratch file **early, appending as they go**, run everything in the foreground,
  and hand back a verdict; the fix round reads the file. Each leg builds in its own `mktemp` copy.
- ◈: only level 5's goldens may move, only for the Warrior, with the switch-off check by the implementer and by leg 1
  independently; every moved value old → new in the commit body and As executed. Any other moved value is a STOP.
- Gate-B: the bot's quick mode on level 5 (`FERAZEL_BOT_LEVELS=5 FERAZEL_BOT_MINUTES=1 tools/ferazel-random-play.sh
  core`), 0 failures, its `== core:` line recorded.
- **Wave 6A.1 end** (after W2 merges): G3; by day only, muted, after the LAUNCH GUARD — GWB Proof B (647 / 0 / 3 / 0
  of 650) and GW4R; then the Fable cross-check of the wave's whole diff (`6a196f2..HEAD`: BL, CF, FR, W1, W2, and the
  two unreviewed commits above) with its gate numbers, and its fix round. A launch gate owed by the night rule is the
  first act of the next run that starts by day; the cross-check may open run 53 when the context is spent.

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
4. Rebuild this file from nothing for the next run (run 53: 6A-FX, 6A-S8 ⚑, 6A-WD ◈; first whatever this run did
   not reach — a task, the wave's launch gates, the cross-check).
5. Push main, then start the next attended session (`start_session`, fresh context, brief "read docs/NEXT.md and run
   it") — unless a question only Ben can answer blocks the next step (then `STATUS: BLOCKED`, the item in QUESTIONS
   with `Blocks: everything`, no new session).
