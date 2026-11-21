STATUS: CONTINUE

# NEXT — Ferazel's Wand, run 61: 6A-L15 (level 15 "Storm Valley" opens) with its whole gate; then 6A-CH1 ⚑ only if there is room

You are the seat for **Ferazel's Wand** in Ambrosia Classics, repo `/Users/andiyar/Developer/Ambrosia-Classics`
(`$REPO`). Method: `~/Developer/Toolkits/fable-kit/orchestrator.md`. This is a build run. In your first message say
which model you are and, in one sentence, what you will do first; then start. **If a Coordinator session started you,
its overrides win over this file** (who starts the next session, the handoff's name, foreground-only work, removing
your worktree).

**Authority:** `docs/superpowers/plans/2026-11-04-ferazel-remainder.md` — the one plan. This run's card:
`#### 6A-L15` in "Wave 5 — Phase 6A" (then `#### 6A-CH1`), with that section's opening rules ("Every engine-feature
task"), "Verification-model additions for 6A" (the level fixture, the kinds of golden, **Gate-L**, the wave end),
"The sweep's and the bot's budget as levels 10–22 join" and "Execution order". The seat reads the cards and the gate
block only; implementers read "0. The verification model", "Invariants and hazards" and "Shared architecture"
themselves. As a model of a level task read "As executed — 6A-L10L11". Nothing else is a plan.

## Read first
1. `CLAUDE.md` (repo root).
2. `docs/STATE.md` — the Ferazel block: the live state. This chip holds no state.
3. `docs/QUESTIONS.md` "Open" — act first on any new text under an `Answer:` and record it in `docs/DECISIONS.md`
   (Q18 is Ben's Phase 5 gate: notes become tasks at the head of the order; a fail stops the build and becomes a fix
   wave. **Q21: whether the sweep and the bot may run detached.** Q19: his choices on the 6A plan).
4. `docs/DECISIONS.md` D59, D56, D54, D53, D51 (D46–D49 only where a card cites them) and
   `docs/handoff-2026-11-21-ferazel-run60.md`.

## Before anything else
- **The weekly usage limit** (`get_usage`). Above about 70%, do not start a ⚑ task.
- **Your own context.** Read the meter before the first dispatch. Run 60 began at 113k, was at 153k before its first
  dispatch and at 200k after one minor and one ⚑ task (nine helper reports), before a 30k close.
- **How long one command may run.** `echo "$CLAUDE_CODE_DISABLE_BACKGROUND_TASKS"`: `1` means background work is off
  and a foreground command is cut off at ten minutes. Then:
  - the Core suite and the Windows-kit suite run in parts (below);
  - **the sweep and the bot run one level at a time, in the foreground** (D59.4), unless Q21's `Answer:` says they
    may run detached: `FERAZEL_VISIT_LEVELS=n tools/ferazel-visit-sweep.sh core`, then `… windows`, for each of the
    eight built levels (1–5, 10, 11, 15), and `FERAZEL_BOT_LEVELS=n tools/ferazel-random-play.sh core` / `windows`
    likewise. Read each script's header first for the exact variables and what a "quick mode" changes — the gate
    needs the full per-level budget, not the quick one. Add the per-level summary lines up and record them. Run 56's
    whole sweep was 1,192 s (core) + 1,409 s (windows) for seven levels, so most levels fit; **if one level's sweep
    cannot finish inside ten minutes, stop the level task's merge there and close with
    `STOPPED … — level N's sweep needs one command longer than ten minutes (Q21)`** — a level task is never merged
    without its gate, and the seat never goes around the ten-minute rule on its own.
  - Ben's Q20 answer ("a: run detached", D59.1) covers `tools/windows/proof-b-ferazel.sh` only. It is not owed in
    this run (next at the 6A.3 wave end, after 6A-L18).
- **No launch is owed.** Nothing in this run opens a window or plays a sound. If you do launch anything: muted, by
  day only (09:00–21:00), LAUNCH GUARD first; the two launch scripts refuse outside 09..20 on their own.

## Reconcile first
- `git -C "$REPO" worktree list`, `git -C "$REPO" log --oneline -8 main`: main at or past run 60's close. Other
  sessions (Deimos, Castles) also merge to local main: merge main into your branch before each `--ff-only`.
- G1 HectorKit per the plan's gate table (main ef2c341, clean, at run 60).
- G2 is not owed at the start (run 60's own, at e00db25: **737**, 0 failed, the two opt-in skips by name). At each
  merge it runs from a `git archive` copy with `HECTORKIT_PATH=$HOME/Developer/HectorKit` set. In the foreground it
  is five commands after one `swift build --build-tests`, each `swift test --skip-build --filter …`:
  `FerazelCoreTests` (about 95 s, 569), then `'FerazelRenderTests\.[A-C]'` (about 235 s, 26),
  `'FerazelRenderTests\.[D-E]'` (about 425 s, 18), `'FerazelRenderTests\.[F-L]'` (about 430 s, 53),
  `'FerazelRenderTests\.[M-Z]'` (about 140 s, 71). **Do not join A–C with D–E.** F–L is the part closest to ten
  minutes and 6A-L15 adds a level picture to it: if it passes nine minutes, split it (`[F-K]`, `L`). Each log ends
  with a second, empty bundle's "Executed 0 tests" — count the `Test Case` lines instead. This Mac has no `timeout`
  command — use the Bash tool's own timeout.
- GW2 (the WinKit number moves in this run): four commands after `swift build --build-tests` in `Ferazel/Windows` —
  `WinLevelReferenceTests` (2 today; about 315 s and it grows by a level), `'FerazelWinKitTests\.(B|F|T)'` (29,
  about 450 s), `'FerazelWinKitTests\.Win(D|F|G)'` (26, about 290 s), `'FerazelWinKitTests\.Win(O|R|S|V)'` (28,
  about 140 s). With three levels `WinLevelReferenceTests` may pass ten minutes: then run it one test at a time.
- **A seat's suite part may run beside ONE working helper**: send the helper's dispatch and the one test command in
  the same message (run 60 did this for every part; it saves about twenty minutes a task).

## This run, in this order

| task | what it must produce | Core after | WinKit after |
|---|---|---|---|
| **6A-L15** (minor; a level task, Gate-L) | level 15 "Storm Valley" opens: a player who leaves level 11 can play it, with the rain, the thunder and the side push | 740 | 86 |
| **6A-CH1** ⚑ (only if there is room) | the Goblin Chief: class, Init, Setup, Handle; the player's stagger arm | 752 | 86 |

- **6A-L15 first, with its whole gate (Gate-L):** Gate-F, G3 (the census), the new Windows reference test and the
  `-FerazelLevel` rows, the bot on the new level, then the full sweep and the full bot on **every built level, both
  shells** (see "How long one command may run"). Nothing else heavy while they run; at most 4 workers.
- **The card was amended in run 60:** level 15's real first frame is compared with 6A-RN's **frame-1 pin
  `49eddc24d9989d95` (tick 143)** — the first assert inside `testLevel15RainFeatureGolden`, the test this task
  deletes — not with the rain picture (`343813c4727ef0e0`, frame 2). As executed records "new = that value", or why
  not. The thunder picture (`597cd03adccc11ce`, tick 399) is kept.
- The card's "38 refused today" is out of date: since run 60 level 15 refuses **0 of 183** records.
- **6A-CH1 is run 62's** unless your context after 6A-L15 and its gate is under about 200k and it is still early in
  the day. A ⚑ task took run 60 about four hours of helper time (implementer 60 min, spec leg 18, quality leg 85, fix
  round 15, the seat's two suites 45). 6A-CH1 and 6A-CH2 are both ⚑; never two ⚑ tasks at once.
- **The level fixture is built**: its interface is in the plan's "As executed — 6A-FX". Never edit the fixture or an
  earlier task's leave-out list.
- Per task: one `fk-implementer`, then two Opus review legs (spec, then quality with a mutation table, told what leg 1
  found), a fix round, the seat's own G2 at merge (and GW2 when the WinKit number moves). Brief each leg with the
  card, the document sections and dump spans the card cites, and the test names; do not pre-read source.
- **The fix round** is a fresh `fk-implementer` briefed from the two review files and the reviewer's verified patch
  when background work is off (a resumed helper runs in the background); otherwise resume the first implementer.
- Reviewers write full findings to a scratch file **early, appending as they go**, run everything in the foreground,
  and hand back a verdict; leg 2 also writes a proposed-asserts patch and verifies it. Each leg builds in its own
  `mktemp` copy (`git archive <sha> | tar -x`, `HECTORKIT_PATH` set). Tell every helper to commit before it reports.
- **Check a card's numbers against the level data before briefing** (D56.1). Tell the implementer the data wins and
  to report any difference; where the dump and the card disagree, the dump wins (D59.3: four times in 6A-RN).
- **Pinned values.** Each card names what may change. Nothing else may move: levels 1–5's, 10's and 11's pictures and
  state pins, the Windows level references, every fixture picture, the two chapter cards — the values are in the
  plan's "Goldens" paragraph. A moved value the card does not name is a STOP.
- A picture's start point must actually show the feature (D51.1, D53.1), **proven inside the test by a twin with the
  feature off** (D54.2).
- **A review leg's new asserts go inside the card's named tests** (D51.2): the ladder is the card's number.
- After any commit that moves Core source or audit-test lines, run
  `python3 -I -B tools/ferazel/later-levels-ledger.py --check`; if it says a generated block is stale, `--write`, check
  again, and commit the ledger. Delete any `__pycache__` under `tools/ferazel/` and `docs/ferazel/tools/`.

## Binding rules
- Launch a build only **muted**, few and short, **never 21:00–09:00** — LAUNCH GUARD first. Headless work any hour.
- Game data and dumps are read-only: never edit `Resources/Ferazel/` or `ghidra/ferazel/`.
- Subagents: `fk-implementer` / `fk-reviewer`, **no `model` parameter** (Opus 5.5).
- Memory: at most 4 workers; never two heavy things at once; a sweep or bot is stopped with a plain
  `kill <script pid>` (never `-9`), the outer shell too; the 4 GB per-worker limit is never raised.
- Never wait silently. Cap 300k of your own context (`get_usage` before each dispatch and at the close; at ~240k
  finish the task in flight and close).
- Dump beats bank beats plan. Explicit-path commits, no `git stash`, `git branch --show-current` before each commit.

## Close (in this order)
1. Merge to local main `--ff-only` by SHA.
2. "As executed" under each card; the plan's "Goldens" paragraph gains new values; rulings in `docs/DECISIONS.md`
   under the next free number (D60).
3. `docs/STATE.md`: replace the Ferazel block with today's state only; settled bits to the top of
   `docs/STATE-history.md`. One line in `docs/LOOP-LOG.md`. A short handoff with the real start and end times from
   `date`. One memory note + index line.
4. Rebuild this file from nothing for the next run (run 62: what is left of 6A-L15, then 6A-CH1 ⚑ and 6A-CH2 ⚑, then
   6A-L18 with the wave 6A.3 end — Proof B by day, detached as D59.1 allows — per the plan's "Execution order").
5. Push main, then start the next attended session (`start_session`, fresh context, brief "read docs/NEXT.md and run
   it") — unless a Coordinator started you (then it starts the next one), or a question only Ben can answer blocks the
   next step (then `STATUS: BLOCKED`, the item in QUESTIONS with `Blocks: everything`, no new session).
