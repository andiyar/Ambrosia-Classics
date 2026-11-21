STATUS: CONTINUE

# NEXT — Ferazel's Wand, run 63: 6A-CH2 ⚑ (the Goblin Chief, part two: he can be hit and killed; the fight)

You are the seat for **Ferazel's Wand** in Ambrosia Classics, repo `/Users/andiyar/Developer/Ambrosia-Classics`
(`$REPO`). Method: `~/Developer/Toolkits/fable-kit/orchestrator.md`. This is a build run. In your first message say
which model you are and, in one sentence, what you will do first; then start. **If a Coordinator session started you,
its overrides win over this file** (who starts the next session, the handoff's name, foreground-only work, removing
your worktree).

**Authority:** `docs/superpowers/plans/2026-11-04-ferazel-remainder.md` — the one plan. This run's card:
`#### 6A-CH2` in "Wave 5 — Phase 6A" (then `#### 6A-L18`), with that section's opening rules ("Every
engine-feature task"), "Verification-model additions for 6A" (the gate bundles: **Gate-B** for a boss task, Gate-L
for a level task, the wave end; "Burns end only with face pixels"), "The sweep's and the bot's budget as levels
10–22 join" and "Execution order". The seat reads the cards and the gate block only; implementers read "0. The
verification model", "Invariants and hazards" and "Shared architecture" themselves. As models read "As executed —
6A-CH1" (the first half of this boss, run 62) and "As executed — 6A-W2" (the Warrior's Hit, Kill and scripted
fight). Nothing else is a plan.

## Read first
1. `CLAUDE.md` (repo root).
2. `docs/STATE.md` — the Ferazel block: the live state. This chip holds no state.
3. `docs/QUESTIONS.md` "Open" — act first on any new text under an `Answer:` and record it in `docs/DECISIONS.md`
   (Q18 is Ben's Phase 5 gate: notes become tasks at the head of the order; a fail stops the build and becomes a fix
   wave. Q21: whether the sweep and the bot may run detached. Q19: his choices on the 6A plan).
4. `docs/DECISIONS.md` D61, D60, D59, D54, D51, D49 (D49.1 above all: how the Chief's fight is won is found by the
   build, not taken from the contract) and the newest `docs/handoff-*-ferazel-run62.md`.

## Before anything else
- **The weekly usage limit** (`get_usage`). Above about 70%, do not start a ⚑ task. (Run 62 closed at 45% all
  models, 55% Fable; the week resets on 2026-11-24 at 02:00 Sydney time.)
- **Your own context.** Read the meter before every dispatch. Run 62 began at 115k, was at 140k before its first
  dispatch and 205k at its close, after one small task and one ⚑ task (six helper reports).
- **How long one command may run.** `echo "$CLAUDE_CODE_DISABLE_BACKGROUND_TASKS"`: `1` means background work is off
  and a foreground command is cut off at ten minutes. Then every suite runs in parts (below), **never two parts
  chained in one command**. Only `tools/windows/proof-b-ferazel.sh` may run detached (D59.1); it is not owed in this
  run.
- **No launch is owed.** Nothing in this run opens a window or plays a sound. If you do launch anything: muted, by
  day only (09:00–21:00), LAUNCH GUARD first; the two launch scripts refuse outside 09..20 on their own.

## Reconcile first
- `git -C "$REPO" worktree list`, `git -C "$REPO" log --oneline -8 main`: main at or past run 62's close. Other
  sessions (Deimos, Castles) also merge to local main: merge main into your branch before each `--ff-only`, and
  check the next free D-number at the close (D62 unless another project took it).
- G1 HectorKit per the plan's gate table (main ef2c341, clean, at run 62).
- G2 is not owed at the start (run 62's own, at d7dc0ad: **752**, 0 failed, the two opt-in skips by name). At each
  merge it runs from a `git archive` copy with `HECTORKIT_PATH=$HOME/Developer/HectorKit` set (game data is in git,
  so the copy is complete). After one `swift build --build-tests` in `Ferazel/Core`, each part is its own command,
  `swift test --skip-build --filter …` (run 62's times):

  | part | tests | time |
  |---|---:|---:|
  | `--filter FerazelCoreTests` | 584 | 107 s |
  | `--filter 'FerazelRenderTests\.[A-C]'` | 26 | 277 s |
  | `--filter 'FerazelRenderTests\.[D-E]' --skip DrawModeAuditTests` | 16 | 58 s |
  | `FERAZEL_AUDIT_LEVELS=1,2,3,4,5 … --filter DrawModeAuditTests/testEveryWrittenModeIsDrawable` | 1 | 205 s |
  | `FERAZEL_AUDIT_LEVELS=10,11,15 …` the same test | (the same 1) | 364 s |
  | `FERAZEL_AUDIT_LEVELS=1,2,3,4,5 … --filter DrawModeAuditTests/testEveryRefusalIsUnreachable` | 1 | 215 s |
  | `FERAZEL_AUDIT_LEVELS=10,11,15 …` the same test | (the same 1) | 367 s |
  | `--filter 'FerazelRenderTests\.[F-K]'` | 38 | 192 s |
  | `--filter 'FerazelRenderTests\.L'` | 15 | 313 s |
  | `--filter 'FerazelRenderTests\.[M-Z]'` | 69 + the 2 skips | 148 s |

  6A-CH2 adds its scripted fight to `BossKillLevelRunTests` (the `[A-C]` part, already 277 s): time that part
  early, and split it (`\.A`, `\.B`, `\.C`) if it nears seven minutes. When level 18 opens (6A-L18) the two
  `10,11,15` audit commands grow: make 18 its own group.
  Each log ends with a second, empty bundle's "Executed 0 tests" — count the `Test Case … passed` lines instead.
  This Mac has no `timeout` command — use the Bash tool's own timeout.
- GW2 (the WinKit number does not move in 6A-CH2; run it once at the merge): after `swift build --build-tests` in
  `Ferazel/Windows` — `'FerazelWinKitTests\.B'` (10, 301 s), `'FerazelWinKitTests\.(F|T)'` (19, 168 s),
  `'FerazelWinKitTests\.Win(D|F|G)'` (26, 318 s), `'FerazelWinKitTests\.Win(O|R|S|V)'` (26 + the 2 skips, 154 s),
  and `WinLevelReferenceTests` one test a command: `WinLevelReferenceTests/testLevel10FirstFrameReference`,
  `…Level11…`, `…Level15…` (185 / 159 / 138 s).
- **A seat's command may run beside ONE working helper**: send the helper's dispatch and the one command in the same
  message.

## This run

| task | what it must produce | Core after | WinKit after |
|---|---|---|---|
| **6A-CH2** ⚑ | the Goblin Chief can be hit, hurt, crushed and killed; his three pieces; his record follows him; the level-18 gate opens and the music changes at the Kill; the scripted fight on level 18, measured and pinned | 760 | 86 |

- **6A-CH2 ⚑ with Gate-B**: one `fk-implementer`, then two Opus review legs (spec, then quality with a mutation
  table, told what leg 1 found), a fix round, the seat's own G2 and GW2 at the merge. Level 18 is not in the built
  list yet, so Gate-B's bot check moves to 6A-L18.
- **D49.1 comes first inside the task:** the contract's fight script (walk left to the lock, then tap toward him and
  cast the Fireball every 16th frame) is a starting point only. The implementer first finds from the dump and the
  level-18 data how this fight is won, then writes its own script under D49.1's rules (seed 1, keys only, decided
  from what a player can see, deterministic, written out in the test). If the card's script cannot win, that is a
  finding to report, not a STOP.
- **Known before you brief (from run 62):**
  - The renderer cannot yet load the Chief's flag-1 picture sets 0x777–0x77a. The scripted fight runs with real
    pictures (`LevelFixtureServices`) and his death ends in a burn that needs them, but the card's Files name no
    renderer file. Tell the implementer to report what it needs; rule it in if it is the minimal loader change
    (D54.1 / D61.1's form) and name it in As executed.
  - The Chief's wake and first-jump frames pinned in `testChiefFirstJumpAfterLock` (lock 111, awake 121, jump 176,
    landing 212) were measured headless. With real pictures they may differ; a fight measured through
    `LevelFixtureServices` uses the real ones. Those four pins may move only in 6A-L18 (D61.3) — in 6A-CH2 they stay.
  - `Smite.swift:16` still calls him inert: the card's Smite edit fixes it.
  - The ledger script already calls the Chief built ("Hit + Kill 6A-CH2"): reword its remark once they are.
- **6A-L18 is a later run's**, with the wave 6A.3 end. Never two ⚑ tasks at once. Run 62's ⚑ task took 3 h 25 min
  from first dispatch to merge (implementer 69 min, spec leg 15, quality leg 44, fix round 15, the seat's suites 62).
- **The level fixture is built**: its interface is in the plan's "As executed — 6A-FX". Never edit the fixture or an
  earlier task's leave-out list.
- Brief each leg with the card, the document sections and dump spans the card cites, and the test names; do not
  pre-read source.
- **The fix round** is a fresh `fk-implementer` briefed from the two review files and the reviewer's verified patch
  when background work is off (a resumed helper runs in the background); otherwise resume the first implementer.
  If it is held to tests, comments and tool scripts, say so in its brief and prove it afterwards with
  `git diff <task commit> -- Ferazel/Core/Sources` (D61.4).
- Reviewers write full findings to a scratch file **early, appending as they go**, run everything in the foreground,
  and hand back a verdict; leg 2 also writes a proposed-asserts patch and verifies it. Each leg builds in its own
  `mktemp` copy (`git archive <sha> | tar -x`, `HECTORKIT_PATH` set). Tell every helper to commit before it reports.
- **Check a card's numbers against the level data before briefing** (D56.1). Tell the implementer the data wins and
  to report any difference; where the dump and the card disagree, the dump wins (eight times in runs 60 to 62).
- **A helper whose edit is refused as outside its fence** reports it; the seat rules (D54.1, D60.1, D61.1) and the
  fix round makes the change with the ruling written in its brief. The seat does not make the edit for it.
- **Pinned values.** Each card names what may change. Nothing else may move: the pictures and state pins of levels
  1–5, 10, 11 and 15, the Windows level references, every fixture picture, the two chapter cards — the values are in
  the plan's "Goldens" paragraph — and the Chief's measured frames in "As executed — 6A-CH1". A moved value the card
  does not name is a STOP.
- A picture's start point must actually show the feature (D51.1, D53.1), **proven inside the test by a twin with the
  feature off** (D54.2).
- **A review leg's new asserts go inside the card's named tests** (D51.2): the ladder is the card's number.
- After any commit that moves Core source or audit-test lines, run
  `python3 -I -B tools/ferazel/later-levels-ledger.py --check`; if it says a generated block is stale, `--write`, check
  again, and commit the ledger. Delete any `__pycache__` under `tools/ferazel/` and `docs/ferazel/tools/`.

## When the level task comes (6A-L18, the run after)
Gate-L, then the wave 6A.3 end. The full check after a level opens, under the ten-minute limit (D59.4 / D60.4): the
sweep one level group a command — `JOBS=4 FERAZEL_VISIT_LEVELS=<ids> tools/ferazel-visit-sweep.sh core`, then
`… windows` — with the groups `1,2` / `3,4` / `5` / `10` / `11` / `15` / `18` (run 61's `3,4,5` took 492 s on the
Windows path: it is split here). The bot as one command a shell: `JOBS=4 tools/ferazel-random-play.sh core`, then
`windows` (80 s, 95 s at eight levels). Add the `== core:` / `== windows:` lines up and record them. The sweep may run
beside the review legs at the task commit **only if** the fix round is then held to tests and comments and `git diff`
proves it touched no game source; otherwise run it again. 6A-L18 also re-measures the Chief's wake and first-jump
frames with real pictures (D61.3) and makes the bot checks 6A-CH1 and 6A-CH2 owe. The wave end needs daylight:
Proof B detached (D59.1), the smoke, then the Fable cross-check over the wave's whole diff.

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
   `date`. One memory note + index line.
4. Rebuild this file from nothing for the next run (6A-L18 with the wave 6A.3 end — Proof B by day, detached as
   D59.1 allows — per the plan's "Execution order").
5. Push main, then start the next attended session (`start_session`, fresh context, brief "read docs/NEXT.md and run
   it") — unless a Coordinator started you (then it starts the next one), or a question only Ben can answer blocks the
   next step (then `STATUS: BLOCKED`, the item in QUESTIONS with `Blocks: everything`, no new session).
