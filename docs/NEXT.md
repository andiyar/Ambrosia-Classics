STATUS: CONTINUE

# NEXT — Ferazel's Wand, run 62: the audit's second test gets its level filter (small), then 6A-CH1 ⚑ (the Goblin Chief, part one)

You are the seat for **Ferazel's Wand** in Ambrosia Classics, repo `/Users/andiyar/Developer/Ambrosia-Classics`
(`$REPO`). Method: `~/Developer/Toolkits/fable-kit/orchestrator.md`. This is a build run. In your first message say
which model you are and, in one sentence, what you will do first; then start. **If a Coordinator session started you,
its overrides win over this file** (who starts the next session, the handoff's name, foreground-only work, removing
your worktree).

**Authority:** `docs/superpowers/plans/2026-11-04-ferazel-remainder.md` — the one plan. This run's card:
`#### 6A-CH1` in "Wave 5 — Phase 6A" (then `#### 6A-CH2`, `#### 6A-L18`), with that section's opening rules ("Every
engine-feature task"), "Verification-model additions for 6A" (the gate bundles: **Gate-B** for a boss task, Gate-L
for a level task, the wave end), "The sweep's and the bot's budget as levels 10–22 join" and "Execution order". The
seat reads the cards and the gate block only; implementers read "0. The verification model", "Invariants and
hazards" and "Shared architecture" themselves. As a model of a boss task read "As executed — 6A-W1" and "6A-W2"; of
a ⚑ task under the ten-minute limit, "As executed — 6A-RN". Nothing else is a plan.

## Read first
1. `CLAUDE.md` (repo root).
2. `docs/STATE.md` — the Ferazel block: the live state. This chip holds no state.
3. `docs/QUESTIONS.md` "Open" — act first on any new text under an `Answer:` and record it in `docs/DECISIONS.md`
   (Q18 is Ben's Phase 5 gate: notes become tasks at the head of the order; a fail stops the build and becomes a fix
   wave. Q21: whether the sweep and the bot may run detached. Q19: his choices on the 6A plan).
4. `docs/DECISIONS.md` D60, D59, D54, D51, D49 (the Chief; D46–D48 only where a card cites them) and
   `docs/handoff-2026-11-21-ferazel-run61.md`.

## Before anything else
- **The weekly usage limit** (`get_usage`). Above about 70%, do not start a ⚑ task. (Run 61 closed at 40% all models,
  50% Fable; the week resets on 2026-11-24 at 02:00 Sydney time.)
- **Your own context.** Read the meter before the first dispatch. Run 61 began at 123k, was at 147k before its first
  dispatch and 207k after one minor level task with its whole gate (four helper reports), before the close.
- **How long one command may run.** `echo "$CLAUDE_CODE_DISABLE_BACKGROUND_TASKS"`: `1` means background work is off
  and a foreground command is cut off at ten minutes. Then every suite runs in parts (below), **never two parts
  chained in one command** (run 61 lost a part that way), and the sweep runs one level group a command. Only
  `tools/windows/proof-b-ferazel.sh` may run detached (D59.1); it is not owed in this run.
- **No launch is owed.** Nothing in this run opens a window or plays a sound. If you do launch anything: muted, by
  day only (09:00–21:00), LAUNCH GUARD first; the two launch scripts refuse outside 09..20 on their own.

## Reconcile first
- `git -C "$REPO" worktree list`, `git -C "$REPO" log --oneline -8 main`: main at or past run 61's close. Other
  sessions (Deimos, Castles) also merge to local main: merge main into your branch before each `--ff-only`, and
  check the next free D-number at the close (Deimos took D58 during run 60).
- G1 HectorKit per the plan's gate table (main ef2c341, clean, at run 61).
- G2 is not owed at the start (run 61's own, at b4482a1: **740**, 0 failed, the two opt-in skips by name). At each
  merge it runs from a `git archive` copy with `HECTORKIT_PATH=$HOME/Developer/HectorKit` set (game data is in git,
  so the copy is complete). After one `swift build --build-tests` in `Ferazel/Core`, each part is its own command,
  `swift test --skip-build --filter …` (run 61's times):

  | part | tests | time |
  |---|---:|---:|
  | `--filter FerazelCoreTests` | 572 | 118 s |
  | `--filter 'FerazelRenderTests\.[A-C]'` | 26 | 263 s |
  | `--filter 'FerazelRenderTests\.[D-E]' --skip DrawModeAuditTests` | 16 | 55 s |
  | `FERAZEL_AUDIT_LEVELS=1,2,3,4,5 … --filter DrawModeAuditTests.testEveryWrittenModeIsDrawable` | 1 | 197 s |
  | `FERAZEL_AUDIT_LEVELS=10,11,15 …` the same test | (the same 1) | 351 s |
  | `--filter DrawModeAuditTests --skip testEveryWrittenModeIsDrawable` | 1 | **543 s — see the first task** |
  | `--filter 'FerazelRenderTests\.[F-K]'` | 38 | 260 s |
  | `--filter 'FerazelRenderTests\.L'` | 15 | 307 s |
  | `--filter 'FerazelRenderTests\.[M-Z]'` | 69 + the 2 skips | 163 s |

  Each log ends with a second, empty bundle's "Executed 0 tests" — count the `Test Case … passed` lines instead.
  This Mac has no `timeout` command — use the Bash tool's own timeout.
- GW2 (the WinKit number does not move in 6A-CH1; run it once at the merge): after `swift build --build-tests` in
  `Ferazel/Windows` — `'FerazelWinKitTests\.(B|F|T)'` (29, **514 s: split it** into two commands before it grows),
  `'FerazelWinKitTests\.Win(D|F|G)'` (26, 319 s), `'FerazelWinKitTests\.Win(O|R|S|V)'` (26 + the 2 skips, 154 s),
  and `WinLevelReferenceTests` one test a command (levels 10 / 11 / 15: 175 / 158 / 128 s).
- **A seat's command may run beside ONE working helper**: send the helper's dispatch and the one command in the same
  message. Run 61 used those slots for the sweep.

## This run, in this order

| task | what it must produce | Core after | WinKit after |
|---|---|---|---|
| **AF** (small, tests only; not on the plan's ladder) | the draw-mode audit's second test, `testEveryRefusalIsUnreachable`, honours `FERAZEL_AUDIT_LEVELS` exactly as the first test does since run 61 (D60.2), so no single command of the suite is near ten minutes | 740 | 86 |
| **6A-CH1** ⚑ | the Goblin Chief: class, Init, Setup, Handle; the player's stagger arm | 752 | 86 |

- **AF first.** It took 543 s alone in run 61; any slower and the gate cannot run. One `fk-implementer`, one
  `fk-reviewer` (a tests-only change with no card: one leg is enough; say so in As executed). Rules as run 61's
  filter: unset = every built level and every assert; two filtered runs that name every level between them lose no
  assert; an id outside the built list fails the test. File: `Ferazel/Core/Tests/FerazelRenderTests/
  DrawModeAuditTests.swift` only (plus the ledger if `--check` goes stale). Record it under D60.2's "still owed".
- **Then 6A-CH1 ⚑** with Gate-B: one `fk-implementer`, then two Opus review legs (spec, then quality with a mutation
  table, told what leg 1 found), a fix round, the seat's own G2 at merge. The Chief's level (18) is not in the built
  list yet, so Gate-B's bot check moves to 6A-L18 (the plan's Gate-B line). D49.1: the Chief's starting fight script
  is unproven — 6A-CH2 first finds how that fight is won.
- **6A-CH2 ⚑ is a later run's**, and 6A-L18 after it with the wave 6A.3 end. Never two ⚑ tasks at once. A ⚑ task
  took run 60 about four hours of helper time; start one only if the run began by early afternoon or you are content
  to close late.
- **The level fixture is built**: its interface is in the plan's "As executed — 6A-FX". Never edit the fixture or an
  earlier task's leave-out list.
- Brief each leg with the card, the document sections and dump spans the card cites, and the test names; do not
  pre-read source.
- **The fix round** is a fresh `fk-implementer` briefed from the two review files and the reviewer's verified patch
  when background work is off (a resumed helper runs in the background); otherwise resume the first implementer.
- Reviewers write full findings to a scratch file **early, appending as they go**, run everything in the foreground,
  and hand back a verdict; leg 2 also writes a proposed-asserts patch and verifies it. Each leg builds in its own
  `mktemp` copy (`git archive <sha> | tar -x`, `HECTORKIT_PATH` set). Tell every helper to commit before it reports.
- **Check a card's numbers against the level data before briefing** (D56.1). Tell the implementer the data wins and
  to report any difference; where the dump and the card disagree, the dump wins (seven times in runs 60 and 61).
- **A helper whose edit is refused as outside its fence** reports it; the seat rules (D54.1, D60.1) and the fix
  round makes the change with the ruling written in its brief. The seat does not make the edit for it.
- **Pinned values.** Each card names what may change. Nothing else may move: the pictures and state pins of levels
  1–5, 10, 11 and 15, the Windows level references, every fixture picture, the two chapter cards — the values are in
  the plan's "Goldens" paragraph. A moved value the card does not name is a STOP.
- A picture's start point must actually show the feature (D51.1, D53.1), **proven inside the test by a twin with the
  feature off** (D54.2).
- **A review leg's new asserts go inside the card's named tests** (D51.2): the ladder is the card's number.
- After any commit that moves Core source or audit-test lines, run
  `python3 -I -B tools/ferazel/later-levels-ledger.py --check`; if it says a generated block is stale, `--write`, check
  again, and commit the ledger. Delete any `__pycache__` under `tools/ferazel/` and `docs/ferazel/tools/`.

## When a level task comes (6A-L18, not this run)
The full check after a level opens, under the ten-minute limit (run 61's form, D59.4 / D60.4): the sweep one level
group a command — `JOBS=4 FERAZEL_VISIT_LEVELS=<ids> tools/ferazel-visit-sweep.sh core`, then `… windows` — with the
groups `1,2` / `3,4,5` / `10` / `11` / `15` (+ the new level alone); the longest was 492 s (`3,4,5`, Windows path:
split it next time). The bot as one command a shell: `JOBS=4 tools/ferazel-random-play.sh core`, then `windows`
(80 s, 95 s). Add the `== core:` / `== windows:` lines up and record them. The sweep may run beside the review legs
at the task commit **only if** the fix round is then held to tests and comments and `git diff` proves it touched no
game source; otherwise run it again.

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
   under the next free number (D61 unless another project took it).
3. `docs/STATE.md`: replace the Ferazel block with today's state only; settled bits to the top of
   `docs/STATE-history.md`. One line in `docs/LOOP-LOG.md`. A short handoff with the real start and end times from
   `date`. One memory note + index line.
4. Rebuild this file from nothing for the next run (what is left of 6A-CH1, then 6A-CH2 ⚑, then 6A-L18 with the
   wave 6A.3 end — Proof B by day, detached as D59.1 allows — per the plan's "Execution order").
5. Push main, then start the next attended session (`start_session`, fresh context, brief "read docs/NEXT.md and run
   it") — unless a Coordinator started you (then it starts the next one), or a question only Ben can answer blocks the
   next step (then `STATUS: BLOCKED`, the item in QUESTIONS with `Blocks: everything`, no new session).
