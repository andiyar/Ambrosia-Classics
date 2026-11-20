STATUS: CONTINUE

# NEXT — Ferazel's Wand, run 57: the wave 6A.2 end (two launch checks, the Fable cross-check), then 6A-BG1c and 6A-RN ⚑

You are the seat for **Ferazel's Wand** in Ambrosia Classics, repo `/Users/andiyar/Developer/Ambrosia-Classics`
(`$REPO`). Method: `~/Developer/Toolkits/fable-kit/orchestrator.md`. This is a build run. In your first message say
which model you are and, in one sentence, what you will do first; then start. **If a Coordinator session started you,
its overrides win over this file** (who starts the next session, the handoff's name, foreground-only work, removing
your worktree).

**Authority:** `docs/superpowers/plans/2026-11-04-ferazel-remainder.md` — the one plan. This run's cards:
`#### 6A-BG1c` and `#### 6A-RN` in "Wave 5 — Phase 6A", with that section's opening rules ("Every engine-feature
task"), "Verification-model additions for 6A" (the level fixture, the kinds of golden, **Gate-F**, the wave end) and
"Execution order". The seat reads the cards and the gate block (plan lines ~97–200) only; implementers read "0. The
verification model", "Invariants and hazards" and "Shared architecture" themselves. Nothing else is a plan.

## Read first
1. `CLAUDE.md` (repo root).
2. `docs/STATE.md` — the Ferazel block: the live state. This chip holds no state.
3. `docs/QUESTIONS.md` "Open" — act first on any new text under an `Answer:` (Q18 is Ben's Phase 5 gate: notes become
   tasks at the head of the order; a fail stops the build and becomes a fix wave. Q19: his choices on the 6A plan) and
   record it in `docs/DECISIONS.md`.
4. `docs/DECISIONS.md` D54, D53 and D51 (D46–D49 only where a card cites them) and
   `docs/handoff-2026-11-21-ferazel-run56.md`.

## Before anything else
- **The weekly usage limit:** read it with `get_usage`. Above about 70%, do not start a ⚑ task: do the owed checks and
  the small task only, or stop with nothing changed, and say so.
- **The hour.** The first three items below need daylight: nothing may be launched outside 09:00–21:00. If you start
  at night, say so and stop with nothing changed (`STOPPED … — started at night; the owed launch checks need 09:00–21:00`):
  no task may start while the wave end is owed (the plan's "Wave end" line).
- **Whether one command can run longer than ten minutes.** Proof B is ONE whole run of about 13 minutes or more
  (`tools/windows/proof-b-ferazel.sh`, no argument; its `--class` form is only for finding a crash) and cannot be
  split. If background work is off and a foreground command is cut off at ten minutes, you cannot run it as written:
  ask the session that started you how it wants Proof B run before doing anything else; if it cannot answer, close
  with `STOPPED … — Proof B needs one command longer than ten minutes`. Do not start a task around an owed Proof B.

## Reconcile first
- `git -C "$REPO" worktree list`, `git -C "$REPO" log --oneline -8 main`: main at or past run 56's close. Other
  sessions (Deimos, Castles) also merge to local main: merge main into your branch before each `--ff-only`.
- G1 HectorKit per the plan's gate table.
- G2 at the head, once, from a `git archive` copy with `HECTORKIT_PATH=$HOME/Developer/HectorKit` set: **722**, 0
  failed, the two opt-in skips by name. In the foreground it is five commands after one `swift build --build-tests`,
  each `swift test --skip-build --filter …`: `FerazelCoreTests` (97 s, 557), then `'FerazelRenderTests\.[A-C]'` (240 s,
  26), `'FerazelRenderTests\.[D-E]'` (424 s, 18), `'FerazelRenderTests\.[F-L]'` (417 s, 51),
  `'FerazelRenderTests\.[M-Z]'` (137 s, 70). **Do not join A–C with D–E: together they pass ten minutes.** You may run
  these beside ONE working helper. This Mac has no `timeout` command — use the Bash tool's own timeout.

## This run, in this order
1. **Proof B, by day, muted** (LAUNCH GUARD first; the script mutes itself): expect
   `proof-b: 719 passed / 0 failed / 3 skipped / 0 crashed (of 722)`. Nothing else heavy beside it.
2. **The Mac SDL smoke, by day:** `tools/windows/smoke-ferazel-win.sh --mac-only` — exit 0, a line ending
   `video=dummy audio=none`.
3. **The Fable cross-check of wave 6A.2** (your one review this run; no helper): the whole diff
   `git diff 520590c^ main -- Ferazel tools docs/ferazel` (6A-FX … 6A-L10L11, runs 52–56) and the wave's gate numbers in
   STATE. Look for what no single task's review could see: a pinned value that moved without its card naming it, a
   fixture leave-out list that a later task changed, stale "levels 1–5" assumptions now that the list is wider, the
   five test gaps run 56 carried (STATE "From run 56" — the first, Continue from a level-11 save ignoring the facing,
   may be a real fault). Findings go to one fix round by an `fk-implementer` with two Opus legs, before the next task;
   record the result under the plan's Wave 5 heading and in LOOP-LOG.

| task | what it must produce | Core after | WinKit after |
|---|---|---|---|
| **6A-BG1c** (minor) | the plants of levels 15 and 18 set up and drawn | 725 | 84 |
| **6A-RN** ⚑ | rain, thunder and the side push (level 15's weather), proven on a test fixture | 737 | 85 |

- Both are feature tasks (**Gate-F**): no full sweep or bot (those follow a level task). BG1c before RN (RN's fixture
  needs the plants built); never at once.
- **6A-L15** (level 15 opens; Core 740, WinKit 86; a level task with the full sweep and bot, Gate-L) is run 58's unless
  your context after RN is under about 200k and it is still early in the day — a level task is never split from its
  gate or started when it cannot finish.
- **The level fixture is built**: its interface is in the plan's "As executed — 6A-FX". Render tests open through
  `LevelFixtureServices.open(…) -> (run, services)` and take frames with `firstPresentedFrame` / `step`; never build
  the patched data twice; never edit the fixture or an earlier task's leave-out list.
- Per task: one `fk-implementer`, then two Opus review legs (spec, then quality with a mutation table, told what leg 1
  found), a fix round, the seat's own G2 at merge (and GW2 when the WinKit number moves: four commands —
  `WinLevelReferenceTests` 315 s, `'FerazelWinKitTests\.(B|F|T)'` 448 s, `'FerazelWinKitTests\.Win(D|F|G)'` 292 s,
  `'FerazelWinKitTests\.Win(O|R|S|V)'` 139 s). Brief each leg with the card, the document sections and dump spans the
  card cites, and the test names; do not pre-read source.
- **The fix round** is a fresh `fk-implementer` briefed from the two review files and the reviewer's verified patch
  when background work is off (a resumed helper runs in the background); otherwise resume the first implementer.
- Reviewers write full findings to a scratch file **early, appending as they go**, run everything in the foreground,
  and hand back a verdict; leg 2 also writes a proposed-asserts patch and verifies it. Each leg builds in its own
  `mktemp` copy (`git archive <sha> | tar -x`, `HECTORKIT_PATH` set).
- **Pinned values.** Each card names what may change. Nothing else may move: levels 1–5's, 10's and 11's pictures and
  state pins, the Windows level references, every fixture picture, the two chapter cards — the values are in the
  plan's "Goldens" paragraph. A moved value the card does not name is a STOP.
- A picture's start point must actually show the feature (D51.1, D53.1), **proven inside the test by a twin with the
  feature off** (D54.2) — a frame chosen by camera position or table values alone is not proof.
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
  finish the task in flight and close). Run 56's measure: 150k before the first dispatch (the chip, STATE, the gate
  block, the card), about 60k for one ⚑ level task with its whole gate (three briefs, four reports, about thirty
  check commands), about 30k for the close. A helper's long silence is normal: run 56's implementer took 78 minutes,
  its quality leg 103.
- Dump beats bank beats plan. Explicit-path commits, no `git stash`, `git branch --show-current` before each commit.

## Close (in this order)
1. Merge to local main `--ff-only` by SHA.
2. "As executed" under each card; the plan's "Goldens" paragraph gains new values; rulings in `docs/DECISIONS.md`
   under the next free number (D55).
3. `docs/STATE.md`: replace the Ferazel block with today's state only; settled bits to the top of
   `docs/STATE-history.md`. One line in `docs/LOOP-LOG.md`. A short handoff. One memory note + index line.
4. Rebuild this file from nothing for the next run (run 58: what is left of BG1c / RN, then 6A-L15 with its full
   sweep and bot, per the plan's "Execution order").
5. Push main, then start the next attended session (`start_session`, fresh context, brief "read docs/NEXT.md and run
   it") — unless a Coordinator started you (then it starts the next one), or a question only Ben can answer blocks the
   next step (then `STATUS: BLOCKED`, the item in QUESTIONS with `Blocks: everything`, no new session).
