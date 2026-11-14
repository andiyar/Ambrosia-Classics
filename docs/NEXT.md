STATUS: CONTINUE

# NEXT — Ferazel's Wand, run 53: the two owed launch checks, then 6A-FX, 6A-S8 ⚑, 6A-WD ◈

You are the seat for **Ferazel's Wand** in Ambrosia Classics, repo `/Users/andiyar/Developer/Ambrosia-Classics`
(`$REPO`). Method: `~/Developer/Toolkits/fable-kit/orchestrator.md`. This is a build run. In your first message say
which model you are and, in one sentence, what you will do first; then start.

**Authority:** `docs/superpowers/plans/2026-11-04-ferazel-remainder.md` — the one plan. This run's cards: `#### 6A-FX`,
`#### 6A-S8`, `#### 6A-WD` in "Wave 5 — Phase 6A", with that section's opening rules ("Every engine-feature task"),
"Verification-model additions for 6A" (the level fixture, the ladder, Gate-F, the ◈ rule) and "Execution order". The
seat reads the cards and the gate block (plan lines ~97–200) only; implementers read "0. The verification model",
"Invariants and hazards" and "Shared architecture" themselves. Nothing else is a plan.

## Read first
1. `CLAUDE.md` (repo root).
2. `docs/STATE.md` — the Ferazel block: the live state. This chip holds no state.
3. `docs/QUESTIONS.md` "Open" — act first on any new text under an `Answer:` (Q18 is Ben's Phase 5 gate: notes become
   tasks at the head of the 6A order; a fail stops the build and becomes a fix wave. Q19: his choices on the 6A plan)
   and record it in `docs/DECISIONS.md`.
4. `docs/DECISIONS.md` D47, D48, D49 and `docs/handoff-2026-11-14-ferazel-run52.md`.

## Reconcile first
- `git -C "$REPO" worktree list`, `git -C "$REPO" log --oneline -8 main`: main at or past run 52's close. Other
  sessions (Deimos, Castles) also merge to local main: merge main into your branch before each `--ff-only`.
- G1 HectorKit per the plan's gate table.
- G2 at the head, once (background, 40-minute limit, from a `git archive` copy with
  `HECTORKIT_PATH=$HOME/Developer/HectorKit` set): 650, 0 failed, the two opt-in skips by name. This Mac has no
  `timeout` command — use the Bash tool's own timeout.
- **Owed from wave 6A.1, the first act if the run starts by day (09:00–20:59), muted, after the LAUNCH GUARD:** GWB
  Proof B (**647 / 0 / 3 / 0 of 650**) and GW4R (the Mac SDL smoke). If the run starts at night they stay owed and are
  the first act of the next daytime run; record either way in STATE and LOOP-LOG. Wave 6A.1's cross-check is done.

## This run
| task | what it must produce | Core after |
|---|---|---|
| **6A-FX** | the level fixture: a test-only way to open a later level with its unbuilt types left out | 652 |
| **6A-S8** ⚑ | the horizon strip (draw mode 8), proved on the fixture with a feature golden | 663 |
| **6A-WD** ◈ | wind cells; may move 6A-S8's level-10 strip golden only, with the switch-off check | 672 |

- Per task: one `fk-implementer`, then two Opus review legs (spec, then quality with a mutation table, told what leg 1
  found), a fix round, the seat's own G2 at merge. Brief each leg with the card, the document section and dump span the
  card cites, and the test names; do not pre-read source. One task at a time (FX before S8 before WD).
- Reviewers write full findings to a scratch file **early, appending as they go**, run everything in the foreground,
  and hand back a verdict; the fix round reads the file and the leg's proposed-asserts patch. Each leg builds in its
  own `mktemp` copy (`git archive <sha> | tar -x`, `HECTORKIT_PATH` set).
- No golden of levels 1–5 may move in this run (they are each feature task's switch-off check). A moved value outside
  a card's named ◈ is a STOP.
- After any commit that moves Core source lines, run `python3 -I -B tools/ferazel/later-levels-ledger.py --check`; if
  it says a generated block is stale, `--write`, check again, and commit the ledger (line anchors only).
- A subagent that stops for a ruling is resumed with `SendMessage` to its id, not replaced.

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
4. Rebuild this file from nothing for the next run (run 54: 6A-RC, 6A-TR, 6A-RP ⚑; first whatever this run did not
   reach — a task, the owed launch checks).
5. Push main, then start the next attended session (`start_session`, fresh context, brief "read docs/NEXT.md and run
   it") — unless a question only Ben can answer blocks the next step (then `STATUS: BLOCKED`, the item in QUESTIONS
   with `Blocks: everything`, no new session).
