STATUS: CONTINUE

# NEXT — Ferazel's Wand, run 53: the two owed launch checks, then 6A-TR, 6A-RP ⚑, 6A-BX1a

You are the seat for **Ferazel's Wand** in Ambrosia Classics, repo `/Users/andiyar/Developer/Ambrosia-Classics`
(`$REPO`). Method: `~/Developer/Toolkits/fable-kit/orchestrator.md`. This is a build run. In your first message say
which model you are and, in one sentence, what you will do first; then start.

**Authority:** `docs/superpowers/plans/2026-11-04-ferazel-remainder.md` — the one plan. This run's cards: `#### 6A-TR`,
`#### 6A-RP`, `#### 6A-BX1a` in "Wave 5 — Phase 6A", with that section's opening rules ("Every engine-feature task"),
"Verification-model additions for 6A" (the level fixture, the ladder, Gate-F, the ◈ rule) and "Execution order". The
seat reads the cards and the gate block (plan lines ~97–200) only; implementers read "0. The verification model",
"Invariants and hazards" and "Shared architecture" themselves. Nothing else is a plan.

## Read first
1. `CLAUDE.md` (repo root).
2. `docs/STATE.md` — the Ferazel block: the live state. This chip holds no state.
3. `docs/QUESTIONS.md` "Open" — act first on any new text under an `Answer:` (Q18 is Ben's Phase 5 gate: notes become
   tasks at the head of the 6A order; a fail stops the build and becomes a fix wave. Q19: his choices on the 6A plan)
   and record it in `docs/DECISIONS.md`.
4. `docs/DECISIONS.md` D49 (D46–D48 only where a card cites them) and `docs/handoff-2026-11-14-ferazel-run52.md`.

## Reconcile first
- `git -C "$REPO" worktree list`, `git -C "$REPO" log --oneline -8 main`: main at or past run 52's close. Other
  sessions (Deimos, Castles) also merge to local main: merge main into your branch before each `--ff-only`.
- G1 HectorKit per the plan's gate table.
- G2 at the head, once (background, 40-minute limit, from a `git archive` copy with
  `HECTORKIT_PATH=$HOME/Developer/HectorKit` set): 682, 0 failed, the two opt-in skips by name. This Mac has no
  `timeout` command — use the Bash tool's own timeout.
- **Owed from wave 6A.1, the first act if the run starts by day (09:00–20:59), muted, after the LAUNCH GUARD:** GWB
  Proof B (**679 / 0 / 3 / 0 of 682** at run 52's head — N is the Core total at the commit it runs on) and GW4R (the Mac SDL smoke). If the run starts at night they stay owed and are
  the first act of the next daytime run; record either way in STATE and LOOP-LOG. Wave 6A.1's cross-check is done.

## This run
| task | what it must produce | Core after |
|---|---|---|
| **6A-TR** | trees and their branches | 693 |
| **6A-RP** ⚑ | the river ripple (and the submerged-tint proof), with a header-patched fixture golden | 703 |
| **6A-BX1a** | Box scenery: decorations, outcrops, mushrooms, the graves' mirrored hot rect | 709 |

- **The level fixture is built** (6A-FX): its interface is in the plan's "As executed — 6A-FX". Every brief says: Render
  tests open through `LevelFixtureServices.open(…) -> (run, services)` and take frames with `firstPresentedFrame` /
  `step`; never build the patched data twice; never edit the fixture or an earlier task's leave-out list.
- Per task: one `fk-implementer`, then two Opus review legs (spec, then quality with a mutation table, told what leg 1
  found), a fix round, the seat's own G2 at merge. Brief each leg with the card, the document section and dump span the
  card cites, and the test names; do not pre-read source. One task at a time (TR, then RP, then BX1a).
- Reviewers write full findings to a scratch file **early, appending as they go**, run everything in the foreground,
  and hand back a verdict; the fix round reads the file and the leg's proposed-asserts patch. Each leg builds in its
  own `mktemp` copy (`git archive <sha> | tar -x`, `HECTORKIT_PATH` set).
- No golden of levels 1–5 and no earlier fixture golden may move in this run (level 21's fixture, level 10's strip —
  two frames — wind and cannons). A moved existing value is a STOP. A task's own new values re-measured in its fix round are
  not moves.
- A golden's start point must actually show the feature (run 52: the strip is not visible from level 10's start; the
  card's wind column could not hold the player). Tell the implementer to say so and choose a start that does, and
  leg 1 to rule on it.
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
4. Rebuild this file from nothing for the next run (run 54: 6A-BX1b, 6A-MC, then 6A-L10L11 ⚑ if the context
   allows; first whatever this run did not reach — a task, the owed launch checks).
5. Push main, then start the next attended session (`start_session`, fresh context, brief "read docs/NEXT.md and run
   it") — unless a question only Ben can answer blocks the next step (then `STATUS: BLOCKED`, the item in QUESTIONS
   with `Blocks: everything`, no new session).
