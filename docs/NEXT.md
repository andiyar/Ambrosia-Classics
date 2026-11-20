STATUS: CONTINUE — Q20 answered (a: run detached; D58.1), run 60 in progress

# NEXT — Ferazel's Wand, run 60: the wave 6A.2 end (two launch checks, by day), then 6A-BG1c and 6A-RN ⚑

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
   tasks at the head of the order; a fail stops the build and becomes a fix wave. Q19: his choices on the 6A plan;
   **Q20: how Proof B runs when one command is cut off at ten minutes**) and record it in `docs/DECISIONS.md`.
4. `docs/DECISIONS.md` D57, D56, D55, D54, D53 and D51 (D46–D49 only where a card cites them) and
   `docs/handoff-2026-11-21-ferazel-run59.md`.

## Before anything else — three checks, each can end the run at once
- **The hour** (`date`). Both owed items launch a build: 09:00–21:00 only (D42). No task (BG1c, RN) may start until
  both are done (the plan's "Wave end" line). **At night there is nothing this run may do: change nothing, write a
  two-line handoff saying so, and close.** Runs 57 and 58 used up the headless work. **Both scripts refuse by the
  clock outside 09..20 and have no override** — a "go" from Ben before 09:00 cannot make them run, and the seat never
  edits or goes around that guard (D57.2). Run 59 started at 07:56 on Ben's word and could launch nothing.
- **Whether one command can run longer than ten minutes.** Proof B is ONE whole run of about 13 minutes or more
  (`tools/windows/proof-b-ferazel.sh`, no argument; its `--class` form is only for finding a crash) and cannot be
  split. Read Q20's `Answer:` first — it says how to run it. With no answer, background work off and a foreground
  command cut off at ten minutes, you cannot run it (run 59 stopped here; D57): close with
  `STOPPED … — Proof B needs one command longer than ten minutes (Q20)`. You may still do item 2 (the smoke) first
  if the hour allows it. If the answer is (c) and Ben has pasted the script's last line, check it reads
  `719 passed / 0 failed / 3 skipped / 0 crashed (of 722)` and that main's game code has not moved since, and record it.
- **The weekly usage limit** (`get_usage`). Above about 70%, do not start a ⚑ task: do the owed items and the small
  task only, or stop with nothing changed, and say so.
- **Your own context.** Read the meter before the first dispatch. Run 58 began at 117k and was at 150k after a whole
  fix round (four helper reports).

## Reconcile first
- `git -C "$REPO" worktree list`, `git -C "$REPO" log --oneline -8 main`: main at or past run 59's close (records only
  since run 58; tests and comments only since ae3a20e: 66875a3). Other sessions (Deimos, Castles) also merge to local main: merge main into
  your branch before each `--ff-only`.
- G1 HectorKit per the plan's gate table (main ef2c341, clean, at run 58).
- G2 is not owed at the start (run 58's own, at 66875a3: **722**, 0 failed, the two opt-in skips by name). At each
  merge it runs from a `git archive` copy with `HECTORKIT_PATH=$HOME/Developer/HectorKit` set. In the foreground it
  is five commands after one `swift build --build-tests`, each `swift test --skip-build --filter …`:
  `FerazelCoreTests` (93 s, 557), then `'FerazelRenderTests\.[A-C]'` (232 s, 26), `'FerazelRenderTests\.[D-E]'`
  (422 s, 18), `'FerazelRenderTests\.[F-L]'` (416 s, 51), `'FerazelRenderTests\.[M-Z]'` (136 s, 70). **Do not join
  A–C with D–E: together they pass ten minutes.** Each log ends with a second, empty bundle's "Executed 0 tests" —
  read the line above it. You may run these beside ONE working helper. This Mac has no `timeout` command — use the
  Bash tool's own timeout.

## This run, in this order
1. **Proof B, by day, muted** (LAUNCH GUARD first; the script mutes itself): expect
   `proof-b: 719 passed / 0 failed / 3 skipped / 0 crashed (of 722)`. Nothing else heavy beside it. Run 58's new
   asserts have never run under Wine: a failure in `LevelTenTests`, `LevelElevenTests` or `RippleTests` is most likely
   a Wine gap in a new assert (see the plan's Proof-B rules), not a game fault — fix the test, re-run.
2. **The Mac SDL smoke, by day:** `tools/windows/smoke-ferazel-win.sh --mac-only` — exit 0, a line ending
   `video=dummy audio=none`.
Record both under the plan's bullet "Wave 6A.2 — the Fable cross-check" and in STATE's numbers table.

The wave's Fable cross-check (run 57, D55) and its fix round (run 58, D56) are done: do not repeat them.

| task | what it must produce | Core after | WinKit after |
|---|---|---|---|
| **6A-BG1c** (minor) | the plants of levels 15 and 18 set up and drawn | 725 | 84 |
| **6A-RN** ⚑ | rain, thunder and the side push (level 15's weather), proven on a test fixture | 737 | 85 |

- Both are feature tasks (**Gate-F**): no full sweep or bot (those follow a level task). BG1c before RN (RN's fixture
  needs the plants built); never at once.
- **6A-L15** (level 15 opens; Core 740, WinKit 86; a level task with the full sweep and bot, Gate-L) is run 61's unless
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
- **Check a card's numbers against the level data before briefing** (D56.1: the plan had level 10's header values
  wrong). Tell the implementer the data wins and to report any difference.
- **Pinned values.** Each card names what may change. Nothing else may move: levels 1–5's, 10's and 11's pictures and
  state pins, the Windows level references, every fixture picture, the two chapter cards — the values are in the
  plan's "Goldens" paragraph. A moved value the card does not name is a STOP.
- A picture's start point must actually show the feature (D51.1, D53.1), **proven inside the test by a twin with the
  feature off** (D54.2) — a frame chosen by camera position or table values alone is not proof.
- **A review leg's new asserts go inside the card's named tests** (D51.2): the ladder is the card's number.
- After any commit that moves Core source or audit-test lines, run
  `python3 -I -B tools/ferazel/later-levels-ledger.py --check`; if it says a generated block is stale, `--write`, check
  again, and commit the ledger. Its anchors match comment wording: a reworded comment can need a one-line anchor
  change in the script. Delete any `__pycache__` under `tools/ferazel/` and `docs/ferazel/tools/`.

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
   under the next free number (D58).
3. `docs/STATE.md`: replace the Ferazel block with today's state only; settled bits to the top of
   `docs/STATE-history.md`. One line in `docs/LOOP-LOG.md`. A short handoff with the real start and end times from
   `date`. One memory note + index line.
4. Rebuild this file from nothing for the next run (run 61: what is left of the owed items and of BG1c / RN, then
   6A-L15 with its full sweep and bot, per the plan's "Execution order").
5. Push main, then start the next attended session (`start_session`, fresh context, brief "read docs/NEXT.md and run
   it") — unless a Coordinator started you (then it starts the next one), or a question only Ben can answer blocks the
   next step (then `STATUS: BLOCKED`, the item in QUESTIONS with `Blocks: everything`, no new session).
