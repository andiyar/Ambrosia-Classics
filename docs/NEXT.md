STATUS: CONTINUE

# NEXT — Ferazel's Wand, run 55: 6A-MC, then 6A-L10L11 ⚑ with the wave 6A.2 end if the context allows

You are the seat for **Ferazel's Wand** in Ambrosia Classics, repo `/Users/andiyar/Developer/Ambrosia-Classics`
(`$REPO`). Method: `~/Developer/Toolkits/fable-kit/orchestrator.md`. This is a build run. In your first message say
which model you are and, in one sentence, what you will do first; then start. **If a Coordinator session started you,
its overrides win over this file** (who starts the next session, the handoff's name, foreground-only work, removing
your worktree).

**Authority:** `docs/superpowers/plans/2026-11-04-ferazel-remainder.md` — the one plan. This run's cards: `#### 6A-MC`
and `#### 6A-L10L11` in "Wave 5 — Phase 6A", with that section's opening rules ("Every engine-feature task"),
"Verification-model additions for 6A" (the level fixture, the three kinds of golden, Gate-F and **Gate-L**, the ◈ rule),
"Execution order" and "The sweep's and the bot's budget as levels 10–22 join". The seat reads the cards and the gate
block (plan lines ~97–200) only; implementers read "0. The verification model", "Invariants and hazards" and "Shared
architecture" themselves. Nothing else is a plan.

## Read first
1. `CLAUDE.md` (repo root).
2. `docs/STATE.md` — the Ferazel block: the live state. This chip holds no state.
3. `docs/QUESTIONS.md` "Open" — act first on any new text under an `Answer:` (Q18 is Ben's Phase 5 gate: notes become
   tasks at the head of the 6A order; a fail stops the build and becomes a fix wave. Q19: his choices on the 6A plan —
   choice (1) decides how much sweeping 6A-L10L11 owes) and record it in `docs/DECISIONS.md`.
4. `docs/DECISIONS.md` D53 and D51 (D46–D49 only where a card cites them) and
   `docs/handoff-2026-11-20-ferazel-run54.md`.

## Reconcile first
- `git -C "$REPO" worktree list`, `git -C "$REPO" log --oneline -8 main`: main at or past run 54's close. Other
  sessions (Deimos, Castles) also merge to local main: merge main into your branch before each `--ff-only`.
- G1 HectorKit per the plan's gate table.
- G2 at the head, once, from a `git archive` copy with `HECTORKIT_PATH=$HOME/Developer/HectorKit` set: **713**, 0
  failed, the two opt-in skips by name. If background work is off, run it as four foreground commands after one
  `swift build --build-tests`, each with `swift test --skip-build --filter …`: `FerazelCoreTests` (about a minute),
  then `'FerazelRenderTests\.[A-E]'` (about 8 minutes), `'FerazelRenderTests\.[F-L]'` (about 5), `'FerazelRenderTests\.[M-Z]'`
  (about 2); add the four counts. This Mac has no `timeout` command — use the Bash tool's own timeout.
- **A launch check is owed at wave 6A.2's end** (after 6A-L10L11): Proof B, by day (09:00–21:00), muted.

## This run
| task | what it must produce | Core after |
|---|---|---|
| **6A-MC** | the conversations and chapter cards of levels 10–22, proven (two chapter-card pictures) | 716 |
| **6A-L10L11** ⚑ (if the context allows; alone, with the wave end) | levels 10 and 11 open — the first new levels a player can see; their first-frame pictures, Mac and Windows | 722 |

- **6A-L10L11 is a level task (Gate-L)**: besides the feature gate it owes the census, the new Windows reference tests,
  the quick bot on each new level, then the full sweep and bot on every built level, then (wave end) Proof B. The full
  sweep and bot take far longer than ten minutes. **If background work is off in your session, settle before you
  dispatch how they will run** (for example one level and one shell per foreground command, at most 4 workers, nothing
  else heavy at the same time) — and if you cannot make that fit, ask the session that started you before starting the
  task, rather than starting it and stalling. If the context or the clock does not allow the whole of it, do 6A-MC
  only and leave 6A-L10L11 to run 56 whole: never split a level task from its gate.
- **The level fixture is built**: its interface is in the plan's "As executed — 6A-FX". Render tests open through
  `LevelFixtureServices.open(…) -> (run, services)` and take frames with `firstPresentedFrame` / `step`; never build the
  patched data twice; never edit the fixture or an earlier task's leave-out list.
- Per task: one `fk-implementer`, then two Opus review legs (spec, then quality with a mutation table, told what leg 1
  found), a fix round, the seat's own G2 at merge. Brief each leg with the card, the document section and dump span the
  card cites, and the test names; do not pre-read source. One task at a time.
- **The fix round** is a fresh `fk-implementer` briefed from the two review files and the reviewer's patch when
  background work is off (a resumed helper runs in the background); otherwise resume the first implementer.
- Reviewers write full findings to a scratch file **early, appending as they go**, run everything in the foreground,
  and hand back a verdict; leg 2 also writes a proposed-asserts patch. Each leg builds in its own `mktemp` copy
  (`git archive <sha> | tar -x`, `HECTORKIT_PATH` set).
- No existing pinned value may move in this run unless a card names it: levels 1–5's pictures and state pins, and the
  fixture pictures (level 21's fixture; level 10's strip — two frames — wind, cannons, the tree; level 11's ripple
  `c92fbe9fb87250c3`). A moved existing value is a STOP. A task's own new values re-measured in its fix round are not
  moves.
- A picture's start point must actually show the feature (D51.1, D53.1). **Level 11's own first frame will not show the
  ripple** — that is expected; the fixture picture stays the ripple's proof. Tell the implementer and leg 1.
- **A review leg's new asserts go inside the card's named tests** (D51.2): the ladder is the card's number.
- After any commit that moves Core source lines, run `python3 -I -B tools/ferazel/later-levels-ledger.py --check`; if
  it says a generated block is stale, `--write`, check again, and commit the ledger. A task that builds a type the
  ledger calls refused also gives the script a built arm for it. The scripts leave `__pycache__` folders under
  `tools/ferazel/` and `docs/ferazel/tools/`: delete them, never commit one.

## Binding rules
- Launch a build only **muted**, few and short, **never 21:00–09:00** — LAUNCH GUARD first. Headless work any hour.
- Game data and dumps are read-only: never edit `Resources/Ferazel/` or `ghidra/ferazel/`.
- Subagents: `fk-implementer` / `fk-reviewer`, **no `model` parameter** (Opus 5.5).
- Memory: at most 4 workers; never two heavy things at once; a sweep or bot is stopped with a plain
  `kill <script pid>` (never `-9`), the outer shell too; the 4 GB per-worker limit is never raised.
- Never wait silently. Cap 300k of your own context (`get_usage` before each dispatch and at the close; at ~240k
  finish the task in flight and close — a task not reached moves to the next chip). Run 54's measure: 142k before the
  first dispatch (the chip, STATE, three cards, the head suite), then about 25k a task (four briefs and four reports),
  and about 25k for the close — three small tasks fitted. A level task with its gate will cost more.
- **The account's weekly limit**: read it in `get_usage` at the start and tell Ben if it is above 85%. At run 54's
  close it stood at 87% (all models) and 89% (Fable), resetting 2026-11-23 — a run started before the reset may be
  cut off; say so at once if it is that high when you start.
- Dump beats bank beats plan. Explicit-path commits, no `git stash`, `git branch --show-current` before each commit.
  After any plan edit that renames a card, run the ledger `--check`.

## Close (in this order)
1. Merge to local main `--ff-only` by SHA.
2. "As executed" under each card; rulings in `docs/DECISIONS.md` under the next free number.
3. `docs/STATE.md`: replace the Ferazel block with today's state only; settled bits to the top of
   `docs/STATE-history.md`. One line in `docs/LOOP-LOG.md`. A short handoff. One memory note + index line.
4. Rebuild this file from nothing for the next run (run 56: whatever this run did not reach first; then 6A-BG1c and
   6A-RN ⚑ per the plan's "Execution order").
5. Push main, then start the next attended session (`start_session`, fresh context, brief "read docs/NEXT.md and run
   it") — unless a Coordinator started you (then it starts the next one), or a question only Ben can answer blocks the
   next step (then `STATUS: BLOCKED`, the item in QUESTIONS with `Blocks: everything`, no new session).
