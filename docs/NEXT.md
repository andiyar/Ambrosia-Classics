STATUS: CONTINUE

# NEXT — Ferazel's Wand, run 64: 6A-L18 (level 18 "Goblin Chief" opens) and the wave 6A.3 end

You are the seat for **Ferazel's Wand** in Ambrosia Classics, repo `/Users/andiyar/Developer/Ambrosia-Classics`
(`$REPO`). Method: `~/Developer/Toolkits/fable-kit/orchestrator.md`. This is a build run with a wave end. In your first
message say which model you are and, in one sentence, what you will do first; then start. **If a Coordinator session
started you, its overrides win over this file** (who starts the next session, the handoff's name, foreground-only work,
removing your worktree).

**Authority:** `docs/superpowers/plans/2026-11-04-ferazel-remainder.md` — the one plan. This run's card:
`#### 6A-L18` in "Wave 5 — Phase 6A" (then `#### 6A-CL`, a later run's), with that section's opening rules,
"Verification-model additions for 6A" (the gate bundles: **Gate-L** for a level task, **Wave end**), "The sweep's and
the bot's budget as levels 10–22 join" and "Execution order". The seat reads the cards and the gate block only;
implementers read "0. The verification model", "Invariants and hazards" and "Shared architecture" themselves. As
models read "As executed — 6A-L15" (the last level opened, run 61) and "As executed — 6A-CH1" and "— 6A-CH2" (the
boss this level holds). Nothing else is a plan.

## Read first
1. `CLAUDE.md` (repo root).
2. `docs/STATE.md` — the Ferazel block: the live state. This chip holds no state.
3. `docs/QUESTIONS.md` "Open" — act first on any new text under an `Answer:` and record it in `docs/DECISIONS.md`
   (Q18 is Ben's Phase 5 gate: notes become tasks at the head of the order; a fail stops the build and becomes a fix
   wave. Q21: whether the sweep and the bot may run detached. Q19: his choices on the 6A plan).
4. `docs/DECISIONS.md` D62, D61 (D61.3 above all: this task re-measures the Chief's four headless frames), D60, D59
   (D59.1: the one script that may run detached), D54, D51, and the newest `docs/handoff-*-ferazel-run63.md`.

## Before anything else
- **The time of day** (`date`). The wave end needs daylight: the Windows test run and the smoke are launches, muted,
  **09:00–21:00 only**. The level task itself is headless and may run at any hour. If you start at night, build and
  gate the level, and leave the wave end's two daytime checks as the first act of the next run that starts by day
  (the plan's "Wave end" rule allows exactly that) — say so in STATE, NEXT and the handoff.
- **The weekly usage limit** (`get_usage`). Above about 70%, do not start the wave end's cross-check. (Run 63 closed
  near 50% all models, 60% Fable; the week resets on 2026-11-24 at 02:00 Sydney time.)
- **Your own context.** Read the meter before every dispatch. Run 63 began at 114k, was at 140k before its first
  dispatch and about 200k at its close, after one ⚑ task (four helper reports) and seventeen suite commands.
- **How long one command may run.** `echo "$CLAUDE_CODE_DISABLE_BACKGROUND_TASKS"`: `1` means background work is off
  and a foreground command is cut off at ten minutes. Then every suite runs in parts (below), **never two parts
  chained in one command**. Only `tools/windows/proof-b-ferazel.sh` may run detached (D59.1).

## Reconcile first
- `git -C "$REPO" worktree list`, `git -C "$REPO" log --oneline -8 main`: main at or past run 63's close. Other
  sessions (Deimos, Castles) also merge to local main: merge main into your branch before each `--ff-only`, and
  check the next free D-number at the close (D63 unless another project took it).
- G1 HectorKit per the plan's gate table (main ef2c341, clean, at run 63).
- G2 is not owed at the start (run 63's own, at f523e2a: **760**, 0 failed, the two opt-in skips by name). At each
  merge it runs from a `git archive` copy with `HECTORKIT_PATH=$HOME/Developer/HectorKit` set (game data is in git,
  so the copy is complete). After one `swift build --build-tests` in `Ferazel/Core`, each part is its own command,
  `swift test --skip-build --filter …` (run 63's times):

  | part | tests | time |
  |---|---:|---:|
  | `--filter FerazelCoreTests` | 591 | 109 s |
  | `--filter 'FerazelRenderTests\.[A-C]'` | 27 | 260 s |
  | `--filter 'FerazelRenderTests\.[D-E]' --skip DrawModeAuditTests` | 16 | 55 s |
  | `FERAZEL_AUDIT_LEVELS=1,2,3,4,5 … --filter DrawModeAuditTests/testEveryWrittenModeIsDrawable` | 1 | 191 s |
  | `FERAZEL_AUDIT_LEVELS=10,11,15 …` the same test | (the same 1) | 335 s |
  | `FERAZEL_AUDIT_LEVELS=1,2,3,4,5 … --filter DrawModeAuditTests/testEveryRefusalIsUnreachable` | 1 | 209 s |
  | `FERAZEL_AUDIT_LEVELS=10,11,15 …` the same test | (the same 1) | 348 s |
  | `--filter 'FerazelRenderTests\.[F-K]'` | 38 | 193 s |
  | `--filter 'FerazelRenderTests\.L'` | 15 | 300 s |
  | `--filter 'FerazelRenderTests\.[M-Z]'` | 69 + the 2 skips | 162 s |

  **When level 18 opens, add `FERAZEL_AUDIT_LEVELS=18` as its own command for each of the two audit tests** (the
  `10,11,15` groups are already near six minutes). The `\.L` part gains level 18's picture test: time it early and
  split it if it nears seven minutes.
  Each log ends with a second, empty bundle's "Executed 0 tests" — count the `Test Case … passed` lines instead. A
  wrong filter runs zero tests and still exits 0. This Mac has no `timeout` command — use the Bash tool's own timeout.
- GW2 (86 → **87** in this run): after `swift build --build-tests` in `Ferazel/Windows` —
  `'FerazelWinKitTests\.B'` (10, 317 s), `'FerazelWinKitTests\.(F|T)'` (19, 177 s),
  `'FerazelWinKitTests\.Win(D|F|G)'` (26, 338 s), `'FerazelWinKitTests\.Win(O|R|S|V)'` (26 + the 2 skips, 143 s),
  and `WinLevelReferenceTests` one test a command: `WinLevelReferenceTests/testLevel10FirstFrameReference`,
  `…Level11…`, `…Level15…` (170 / 153 / 123 s), and the new `…Level18…`.
- **A seat's command may run beside ONE working helper**: send the helper's dispatch and the one command in the same
  message.

## This run

| task | what it must produce | Core after | WinKit after |
|---|---|---|---|
| **6A-L18** | level 18 "Goblin Chief" can be entered; its first picture pinned on both paths; the Chief's wake-up frame on the real level measured; every object visited and the bot run on all nine levels | 764 | 87 |
| wave 6A.3 end | the census, the Windows test run by day, the smoke by day, the Fable cross-check of the wave's whole diff | 764 | 87 |

- **6A-L18 with Gate-L**: one `fk-implementer`, then two Opus review legs (spec, then quality with a mutation table,
  told what leg 1 found), a fix round, the seat's own G2 and GW2 at the merge, G3, then the full sweep and bot.
- **Known before you brief (from runs 62 and 63):**
  - **D61.3:** `testChiefFirstJumpAfterLock` pins four frames measured headless (lock 111, awake 121, first jump 176,
    landing 212). With real pictures his wake rectangle is his picture's, not a whole cell, so they may differ. This
    task re-measures them with pictures and **may move those four values, and only those** — old → new in the commit
    body and As executed.
  - Run 63's scripted fight already runs with real pictures through `LevelFixtureServices` (arena lock on frame 111;
    health 0 on 1602; Kill on 1710). Those are pinned and may not move: if opening the level moves them, STOP.
  - The picture loader now loads his four level-coloured sets under colour table 224 (D62.1). Level 18's first
    picture is the first to show the level through it.
  - **The bot's quick mode on level 18** is owed by 6A-CH1 and 6A-CH2 (Gate-B) and is made here:
    `FERAZEL_BOT_LEVELS=18 FERAZEL_BOT_MINUTES=1 tools/ferazel-random-play.sh core`, 0 failures, its `== core:` line
    recorded.
  - The card says 34 records with 6 refused "before 6A-BG1c": the plants and the Chief are built now, so expect 0
    refused. The data wins; the implementer reports any difference.
- **The full check after the level opens**, under the ten-minute limit (D59.4 / D60.4): the sweep one level group a
  command — `JOBS=4 FERAZEL_VISIT_LEVELS=<ids> tools/ferazel-visit-sweep.sh core`, then `… windows` — with the groups
  `1,2` / `3,4` / `5` / `10` / `11` / `15` / `18`. The bot as one command a shell: `JOBS=4
  tools/ferazel-random-play.sh core`, then `windows` (80 s, 95 s at eight levels). Add the `== core:` /
  `== windows:` lines up and record them. The sweep may run beside the review legs at the task commit **only if** the
  fix round is then held to tests and comments and `git diff` proves it touched no game source; otherwise run it
  again.
- **The wave 6A.3 end** (by day): G3; Proof B detached as D59.1 allows — `tools/windows/proof-b-ferazel.sh`, expected
  **761 passed / 0 failed / 3 skipped / 0 crashed (of 764)**; the smoke (GW4R); then **your own cross-check** — the
  one review the Fable seat does itself — over the whole wave's diff (6A-BG1c, 6A-RN, 6A-L15, 6A-CH1, 6A-CH2,
  6A-L18) and its gate numbers, before the next wave's first task. Findings go to one fix round. If the context is
  spent, the cross-check opens the next run.
- Brief each leg with the card, the document sections and dump spans the card cites, and the test names; do not
  pre-read source.
- **The fix round** is a fresh `fk-implementer` briefed from the two review files and the reviewer's verified patch
  when background work is off (a resumed helper runs in the background). If it is held to tests, comments and tool
  scripts, say so in its brief and prove it afterwards with `git diff <task commit> -- Ferazel/Core/Sources`.
- Reviewers write full findings to a scratch file **early, appending as they go**, run everything in the foreground,
  and hand back a verdict; leg 2 also writes a proposed-asserts patch and verifies it. Each leg builds in its own
  `mktemp` copy (`git archive <sha> | tar -x`, `HECTORKIT_PATH` set). Tell every helper to commit before it reports.
- **Check a card's numbers against the level data before briefing** (D56.1), or tell the implementer plainly that
  they are unchecked. The data wins; where the dump and the card disagree, the dump wins (ten times in runs 60–63).
- **A helper whose edit is refused as outside its fence** reports it; the seat rules (D54.1, D61.1, D62.1) and the
  fix round makes the change with the ruling written in its brief. The seat does not make the edit for it.
- **Pinned values.** Each card names what may change. Nothing else may move: the pictures and state pins of levels
  1–5, 10, 11 and 15, the Windows level references, every fixture picture, the two chapter cards, the Chief's fight
  frames — the values are in the plan's "Goldens" paragraph and the "As executed" notes. A moved value the card (or
  D61.3) does not name is a STOP.
- A picture's start point must actually show the feature (D51.1, D53.1), **proven inside the test by a twin with the
  feature off** (D54.2).
- **A review leg's new asserts go inside the card's named tests** (D51.2): the ladder is the card's number.
- After any commit that moves Core source or audit-test lines, run
  `python3 -I -B tools/ferazel/later-levels-ledger.py --check`; if it says a generated block is stale, `--write`, check
  again, and commit the ledger. Delete any `__pycache__` under `tools/ferazel/` and `docs/ferazel/tools/`.

## After this run
Wave 6A.4 "Hangnabit to the Labyrinth": 6A-CL, 6A-BD, 6A-MP (clouds, the rotating blade, programmed maces), then
levels 20, 21 and 22, then the phase end (6A-END) and Ben's gate card. Never two ⚑ tasks at once.

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
2. "As executed" under the card; the plan's "Goldens" paragraph gains new values; rulings in `docs/DECISIONS.md`
   under the next free number.
3. `docs/STATE.md`: replace the Ferazel block with today's state only; settled bits to the top of
   `docs/STATE-history.md`. One line in `docs/LOOP-LOG.md`. A short handoff with the real start and end times from
   `date`. A memory note only if the run taught a new standing rule (D62.6).
4. Rebuild this file from nothing for the next run (wave 6A.4's first tasks per the plan's "Execution order"; or the
   wave 6A.3 end's daytime checks first, if they are still owed).
5. Push main, then start the next attended session (`start_session`, fresh context, brief "read docs/NEXT.md and run
   it") — unless a Coordinator started you (then it starts the next one), or a question only Ben can answer blocks the
   next step (then `STATUS: BLOCKED`, the item in QUESTIONS with `Blocks: everything`, no new session).
