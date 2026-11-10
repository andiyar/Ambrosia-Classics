STATUS: CONTINUE

# NEXT — Ferazel's Wand, run 49: the Phase 6 planning run (LL, BOS, ENG, then the 6A plan)

You are the seat for **Ferazel's Wand** in Ambrosia Classics, repo `/Users/andiyar/Developer/Ambrosia-Classics`
(`$REPO`). Method: `~/Developer/Toolkits/fable-kit/orchestrator.md`. This is a planning run: research and a plan, no
game code. In your first message say which model you are and, in one sentence, what you will do first; then start.

**Authority:** `docs/superpowers/plans/2026-11-04-ferazel-remainder.md` — the one plan. This run's cards: "Wave 4 —
run 49 (planning run)" with `### Task LL`, `### Task BOS`, `### Task ENG`, `### Task P6A`, and the Wave 5 cards P6A
expands. Read also "0. The verification model", "Machine gates", "Invariants and hazards", "Stand-ins kept at the
Phase 5 end". Nothing else is a plan.

## Read first
1. `CLAUDE.md` (repo root).
2. `docs/STATE.md` — the Ferazel block: the live state, including what is **owed by day**. This chip holds no state.
3. `docs/QUESTIONS.md` "Open" — act first on any new text under an `Answer:` (Q18 is Ben's Phase 5 gate: notes become
   tasks in the 6A plan; a fail stops planning and becomes a fix wave) and record it in `docs/DECISIONS.md`.
4. `docs/handoff-2026-11-10-ferazel-run48.md` — "Owed".

## Reconcile first
- `git -C "$REPO" worktree list`, `git -C "$REPO" log --oneline -8 main`: main at or past run 48's close.
- G1 HectorKit per the plan's gate table.
- **The owed launch checks, only if the LAUNCH GUARD says day (09:00–20:59), muted:** follow the handoff's "Owed" 1–3
  (fresh stage, G9M, GW6, GWB, GW4R, cards updated, stage again). By night: leave them owed, say so in LOOP-LOG, and
  carry the item to the next chip. One heavy thing at a time.
- G2 is not re-run at the head unless a commit since run 48's close touched `Ferazel/` code (docs-only: skip, say so).

## This run
| task | what it must produce |
|---|---|
| **LL** | the later-level ledger + its checker script (levels 10–70: switches, types, resources, owners) |
| **BOS** | the boss contracts (Warrior, Chief, Wizard, Fire Guardians, Xichra) from the dump |
| **ENG** | the engine-feature contracts |
| **P6A** | the Phase 6A plan, expanded in the one plan file; two Opus legs + the Fable cross-check |

LL, BOS and ENG are research (`fk-implementer`, docs and one script only), each with two Opus review legs as its card
says; they touch different files, so they may run one after another or two at a time (never more). P6A needs all
three. If the context cap arrives before P6A, close after the research tasks and chain P6A as run 50.

## Binding rules
- Launch a build only **muted**, few and short, **never 21:00–09:00** — LAUNCH GUARD first. Headless work any hour.
- Game data and dumps are read-only: never edit `Resources/Ferazel/` or `ghidra/ferazel/`.
- Subagents: `fk-implementer` / `fk-reviewer`, **no `model` parameter** (Opus 5.5), except the one Fable cross-check
  of the 6A plan (a Fable seat does it itself; otherwise `fk-reviewer` with `model: "fable"`).
- Memory: this run needs no sweep or bot. If one is run: at most 4 workers, the 4 GB per-worker limit is never raised,
  stop with a plain `kill <script pid>` (never `-9`), and stop the outer shell too. Never two heavy things at once.
- Never wait silently; background long gates with a time limit of hours. Cap 300k of your own context (`get_usage`
  before each dispatch and at the close; at ~240k finish the task in flight and close).
- Dump beats bank beats plan. Explicit-path commits, no `git stash`, `git branch --show-current` before each commit.
- A gate card is checked against the level data (what is placed where, what is reachable), never copied from a plan.

## Close (in this order)
1. Merge to local main `--ff-only` by SHA.
2. "As executed" under each task card; rulings in `docs/DECISIONS.md` under the next free number; the new plan's
   choices for Ben's later read as one QUESTIONS item (does not block).
3. `docs/STATE.md`: replace the Ferazel block with today's state only; settled bits to the top of
   `docs/STATE-history.md`. One line in `docs/LOOP-LOG.md`. A short handoff. One memory note + index line.
4. Rebuild this file from nothing for the next run (the first 6A build wave, or P6A if it was not reached).
5. Push main, then start the next attended session (`start_session`, fresh context, brief "read docs/NEXT.md and run
   it") — unless a question only Ben can answer blocks the next step (then `STATUS: BLOCKED`, the item in QUESTIONS
   with `Blocks: everything`, no new session).
