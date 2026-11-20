STATUS: CONTINUE

# NEXT — Ferazel's Wand, run 56: 6A-L10L11 ⚑ alone, with the wave 6A.2 end

You are the seat for **Ferazel's Wand** in Ambrosia Classics, repo `/Users/andiyar/Developer/Ambrosia-Classics`
(`$REPO`). Method: `~/Developer/Toolkits/fable-kit/orchestrator.md`. This is a build run. In your first message say
which model you are and, in one sentence, what you will do first; then start. **If a Coordinator session started you,
its overrides win over this file** (who starts the next session, the handoff's name, foreground-only work, removing
your worktree).

**Authority:** `docs/superpowers/plans/2026-11-04-ferazel-remainder.md` — the one plan. This run's card:
`#### 6A-L10L11` in "Wave 5 — Phase 6A", with that section's opening rules ("Every level task"),
"Verification-model additions for 6A" (the level fixture, the three kinds of golden, **Gate-L**, the wave end),
"Execution order" and "The sweep's and the bot's budget as levels 10–22 join". The seat reads the card and the gate
block (plan lines ~97–200) only; implementers read "0. The verification model", "Invariants and hazards" and "Shared
architecture" themselves. Nothing else is a plan.

## Read first
1. `CLAUDE.md` (repo root).
2. `docs/STATE.md` — the Ferazel block: the live state. This chip holds no state.
3. `docs/QUESTIONS.md` "Open" — act first on any new text under an `Answer:` (Q18 is Ben's Phase 5 gate: notes become
   tasks at the head of the 6A order; a fail stops the build and becomes a fix wave. Q19: his choices on the 6A plan —
   choice (1) decides how much sweeping 6A-L10L11 owes) and record it in `docs/DECISIONS.md`.
4. `docs/DECISIONS.md` D53 and D51 (D46–D49 only where the card cites them) and
   `docs/handoff-2026-11-20-ferazel-run55.md`.

## Before anything else: the weekly usage limit
Read it with `get_usage`. Run 55 stopped after one small task because it stood at 92% (it resets 2026-11-23, 15:00
UTC). This run's task is the largest of the wave: one implementer on a ⚑ task, two review legs, a fix round, and about
two hours of machine checks. **If the limit is above about 70% when you start, do not start the task**: tell the
session that started you (or Ben) and stop with nothing changed — a level task cut off half-way is worse than one not
started.

## Reconcile first
- `git -C "$REPO" worktree list`, `git -C "$REPO" log --oneline -8 main`: main at or past run 55's close. Other
  sessions (Deimos, Castles) also merge to local main: merge main into your branch before each `--ff-only`.
- G1 HectorKit per the plan's gate table.
- G2 at the head, once, from a `git archive` copy with `HECTORKIT_PATH=$HOME/Developer/HectorKit` set: **716**, 0
  failed, the two opt-in skips by name. If background work is off, run it as four foreground commands after one
  `swift build --build-tests`, each with `swift test --skip-build --filter …`: `FerazelCoreTests` (about a minute,
  551), then `'FerazelRenderTests\.[A-E]'` (about 8 minutes, 44), `'FerazelRenderTests\.[F-L]'` (about 5, 51),
  `'FerazelRenderTests\.[M-Z]'` (about 2, 70); add the four counts. You may run these beside ONE working helper (the
  plan's memory rule allows the suite beside one implementer), which saves about twenty minutes. This Mac has no
  `timeout` command — use the Bash tool's own timeout.
- **A launch check is owed at this run's end** (wave 6A.2's end): Proof B, by day (09:00–21:00), muted, and the Mac
  SDL smoke. Start early enough in the day that the task and its checks finish before 21:00.

## This run
| task | what it must produce | Core after | WinKit after |
|---|---|---|---|
| **6A-L10L11** ⚑ (alone, with the wave end) | levels 10 and 11 open — the first new levels a player can see; their first-frame pictures, Mac and Windows | 722 | 84 |

- **It is a level task (Gate-L)**: besides the feature gate it owes the census, the two new Windows reference tests
  (so the WinKit suite must run: 84), the quick bot on each new level, then the full object sweep and the random-play
  bot on every built level and both shells, then (wave end) Proof B and the Mac SDL smoke by day, then the Fable
  cross-check of the whole wave's diff (6A-FX … 6A-L10L11). Never split the task from its gate.
- **Settle how the long checks run before you dispatch.** If background work is off, one command is cut off at ten
  minutes. Both scripts can be narrowed, so a foreground plan exists (run 55 read the scripts; it did not try it):
  - sweep: `FERAZEL_VISIT_LEVELS=<one level> tools/ferazel-visit-sweep.sh core`, then the same with `windows` — one
    level and one shell a command (7 levels × 2 shells), `JOBS` at most 4; each level id must already be in the
    built-level list. Add the visit counts yourself: the plan expects 6,324 a shell, rows 0.
  - bot: `FERAZEL_BOT_LEVELS=<one level> tools/ferazel-random-play.sh core` / `windows` the same way (4 seeds × 3
    minutes a level over 4 workers); the plan expects 151,200 steps a shell, failures 0. Record each `in W s`.
  - Build the scripts' release products once first with a small narrowed run, so no later command spends its ten
    minutes building.
  - The WinKit suite takes about 13 minutes whole: split it by `--filter` as the Core suite is split.
  - Proof B is meant to run once, whole. Find out how long it takes (run 53 ran Proof B and the smoke together in 13
    minutes) and whether its script can be split; **if it cannot fit a foreground command, ask the session that
    started you before starting the task**, rather than starting and stalling.
  - Nothing else heavy runs beside the sweep, the bot, a suite or Proof B.
- **The level fixture is built**: its interface is in the plan's "As executed — 6A-FX". Render tests open through
  `LevelFixtureServices.open(…) -> (run, services)` and take frames with `firstPresentedFrame` / `step`; never build the
  patched data twice; never edit the fixture or an earlier task's leave-out list.
- One `fk-implementer`, then two Opus review legs (spec, then quality with a mutation table, told what leg 1 found), a
  fix round, the seat's own G2 at merge. Brief each leg with the card, the document sections and dump spans the card
  cites, and the test names; do not pre-read source.
- **The fix round** is a fresh `fk-implementer` briefed from the two review files and the reviewer's patch when
  background work is off (a resumed helper runs in the background); otherwise resume the first implementer.
- Reviewers write full findings to a scratch file **early, appending as they go**, run everything in the foreground,
  and hand back a verdict; leg 2 also writes a proposed-asserts patch and verifies it. Each leg builds in its own
  `mktemp` copy (`git archive <sha> | tar -x`, `HECTORKIT_PATH` set).
- **Pinned values.** The card names what may change: the two feature pictures it deletes (wind, rotating cannons), and
  the tests pinned to the built-level list, each re-derived (the card lists them). Nothing else may move: levels 1–5's
  pictures and state pins, the other fixture pictures (level 21's fixture; level 10's strip, two frames; the tree;
  level 11's ripple `c92fbe9fb87250c3`), the two chapter cards (`f33072b0df2cab4d`, `517ec825dbca68cc`). A moved value
  the card does not name is a STOP.
- A picture's start point must actually show the feature (D51.1, D53.1). **Level 11's own first frame will not show the
  ripple** — that is expected; the fixture picture stays the ripple's proof, and the Windows reference test holds the
  level to the first frame that does show it (the card says how). Tell the implementer and leg 1.
- **A review leg's new asserts go inside the card's named tests** (D51.2): the ladder is the card's number.
- After any commit that moves Core source lines, run `python3 -I -B tools/ferazel/later-levels-ledger.py --check`; if
  it says a generated block is stale, `--write`, check again, and commit the ledger. The scripts leave `__pycache__`
  folders under `tools/ferazel/` and `docs/ferazel/tools/`: delete them, never commit one.

## Binding rules
- Launch a build only **muted**, few and short, **never 21:00–09:00** — LAUNCH GUARD first. Headless work any hour.
- Game data and dumps are read-only: never edit `Resources/Ferazel/` or `ghidra/ferazel/`.
- Subagents: `fk-implementer` / `fk-reviewer`, **no `model` parameter** (Opus 5.5).
- Memory: at most 4 workers; never two heavy things at once; a sweep or bot is stopped with a plain
  `kill <script pid>` (never `-9`), the outer shell too; the 4 GB per-worker limit is never raised.
- Never wait silently. Cap 300k of your own context (`get_usage` before each dispatch and at the close; at ~240k
  finish the task in flight and close). Run 55's measure: 127k before the first dispatch (the chip, STATE, the cards,
  the gate block), about 45k for one small task (four briefs, four reports, the suite runs), about 25k for the close.
  A level task with its gate will cost more — it is this run's only task for that reason.
- Dump beats bank beats plan. Explicit-path commits, no `git stash`, `git branch --show-current` before each commit.
  After any plan edit that renames a card, run the ledger `--check`.

## Close (in this order)
1. Merge to local main `--ff-only` by SHA.
2. "As executed" under the card (with the measured sweep and bot times, replacing the budget paragraph's estimates, and
   the render half's time); the plan's "Goldens" paragraph gains the wave's new values; rulings in `docs/DECISIONS.md`
   under the next free number.
3. `docs/STATE.md`: replace the Ferazel block with today's state only; settled bits to the top of
   `docs/STATE-history.md`. One line in `docs/LOOP-LOG.md` (with the sweep and bot summary lines). A short handoff.
   One memory note + index line.
4. Rebuild this file from nothing for the next run (run 57: the wave's Fable cross-check first if this run did not
   reach it, then 6A-BG1c and 6A-RN ⚑ per the plan's "Execution order").
5. Push main, then start the next attended session (`start_session`, fresh context, brief "read docs/NEXT.md and run
   it") — unless a Coordinator started you (then it starts the next one), or a question only Ben can answer blocks the
   next step (then `STATUS: BLOCKED`, the item in QUESTIONS with `Blocks: everything`, no new session).
