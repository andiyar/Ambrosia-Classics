STATUS: CONTINUE

# NEXT — Ferazel's Wand, run 70: the magic carpet (6A-CP)

You are the seat for **Ferazel's Wand** in Ambrosia Classics, repo `/Users/andiyar/Developer/Ambrosia-Classics`
(`$REPO`). Method: `~/Developer/Toolkits/fable-kit/orchestrator.md`. In your first message say which model you are
and, in one sentence, what you will do first; then start. **If a Coordinator session started you, its overrides win
over this file** (who starts the next session, the handoff's name, foreground-only work, removing your worktree,
its mailbox for questions).

**Authority:** `docs/superpowers/plans/2026-11-04-ferazel-remainder.md` — the one plan. This run's card:
`#### 6A-CP` in "Wave 5 — Phase 6A", with that section's opening rules, "Verification-model additions for 6A"
(the gate bundles: **Gate-F** for a type task; the level fixture), and "Execution order". The seat reads the card
and the gate block only; implementers read "0. The verification model", "Invariants and hazards" and "Shared
architecture" themselves. The model for a type task on a fixture is "As executed — 6A-PS" (run 68). Nothing else
is a plan.

## Read first
1. `CLAUDE.md` (repo root).
2. `docs/STATE.md` — the Ferazel block: the live state. This chip holds no state.
3. The Coordinator mailbox `~/.claude/coordinator-notes/ferazel-6A-mailbox.md` — **Q1** (what a lit blade on
   level 20 shows). "Plain and unlit" is built (D67.1, D68.2). If Ben answered otherwise, his answer becomes a task
   at the head of this run; record it in `docs/DECISIONS.md`. The next free question number there is Q2.
4. `docs/QUESTIONS.md` "Open" — act first on any new text under an `Answer:` (Q18 is Ben's Phase 5 gate: notes
   become tasks at the head of the order; a fail stops the build. Q21: may the sweep and bot run detached. Q19).
5. `docs/DECISIONS.md` **D70** (run 69), D69, D68, D67, D64, D62, D61, D59 (D59.1: the one script that may run
   detached), D54, D51, and `docs/handoff-2026-11-25-ferazel-run69.md`.

## Before anything else
- **The weekly usage limit** (`get_usage`). Run 69 closed at about 40% Fable, 55% all models; the week resets on
  2026-12-01 at 02:00 Sydney time. If a task cannot be finished inside the limit, do not start it.
- **Your own context.** Read the meter before every dispatch. Run 69 (a level task) went from 119k at the start to
  203k when its gates were done and about 235k at the close; run 68's type task took 127k to 200k. **This run is
  6A-CP alone.** At about 240k finish the task in flight and close; do not start 6A-L22.
- **How long one command may run.** `echo "$CLAUDE_CODE_DISABLE_BACKGROUND_TASKS"`: `1` means background work is
  off and a foreground command is cut off at ten minutes. Every suite runs in parts (below). Only
  `tools/windows/proof-b-ferazel.sh` may run detached (D59.1).
- **One heavy command a message** (D70.6): several Bash calls sent in one message run at the same time. Chain
  short parts inside one command with `;` only when their times sum well under ten minutes.
- **The time of day** (`date`). No boot check is owed by a launch: levels 20 and 21 were launched muted on
  2026-11-25 and stayed running. What is owed is **eyes on them** — the seat's request to look at the game's window
  was declined (D70.5), so do not ask again and do not look for another way; it stays with Ben. 6A-CP opens no
  level, so it has no boot check of its own.

## Reconcile first
- `git -C "$REPO" worktree list`, `git -C "$REPO" log --oneline -8 main`: main at or past run 69's close (63183f8
  plus its docs commits). Other sessions (Deimos, Castles) also merge to local main: merge main into your branch
  before each `--ff-only`, and check the next free D-number at the close (D71 unless another project took it).
- G1 HectorKit per the plan's gate table (main ef2c341, clean, at run 69). A worktree needs the untracked link
  `../HectorKit → ~/Developer/HectorKit` beside it, or `HECTORKIT_PATH=$HOME/Developer/HectorKit`.
- G2 is not owed at the start (run 69's own, at 63183f8: **800**, 0 failed, the two opt-in skips by name). At each
  merge it runs from a `git archive` copy with `HECTORKIT_PATH` set. After one `swift build --build-tests` in
  `Ferazel/Core`, each part is `swift test --skip-build --filter …` (run 69's times):

  | part | tests | time |
  |---|---:|---:|
  | `--filter FerazelCoreTests` | 622 | 131 s |
  | `--filter 'FerazelRenderTests\.[A-C]'` | 27 | 315 s |
  | `--filter 'FerazelRenderTests\.[D-E]' --skip DrawModeAuditTests` | 16 | 56 s |
  | `--filter 'FerazelRenderTests\.[F-K]'` | 41 | 239 s |
  | `--filter 'FerazelRenderTests\.(LevelFixtureRenderTests\|LevelFrameGoldenTests\|LightingTests)'` | 16 | 108 s |
  | `--filter 'FerazelRenderTests\.LevelSweepTests'` | 3 | 301 s |
  | `--filter 'FerazelRenderTests\.[M-Z]'` | 71 + the 2 skips | 151 s |
  | `FERAZEL_AUDIT_LEVELS=1,2,3,4,5 … --filter DrawModeAuditTests/testEveryWrittenModeIsDrawable` | 1 of the 2 | 204 s |
  | `FERAZEL_AUDIT_LEVELS=1,2,3,4,5 … --filter DrawModeAuditTests/testEveryRefusalIsUnreachable` | the other | 202 s |
  | `FERAZEL_AUDIT_LEVELS=10,11,15 … --filter DrawModeAuditTests/testEveryWrittenModeIsDrawable` | (the same) | about 360 s |
  | `FERAZEL_AUDIT_LEVELS=10,11,15 … --filter DrawModeAuditTests/testEveryRefusalIsUnreachable` | (the same) | 353 s |
  | `FERAZEL_AUDIT_LEVELS=18 … --filter DrawModeAuditTests` (both tests) | (the same) | 84 s |
  | `FERAZEL_AUDIT_LEVELS=20 … --filter DrawModeAuditTests` (both tests) | (the same) | 196 s |
  | `FERAZEL_AUDIT_LEVELS=21 … --filter DrawModeAuditTests` (both tests) | (the same) | 116 s |

  The carpet's 12 tests land in the rules part (11, `CarpetTests`) and the F–K part (1, `FeatureGoldenTests`).
  Each log ends with a second, empty bundle's "Executed 0 tests" — count the `Test Case … passed` lines. A wrong
  filter runs zero tests and still exits 0. This Mac has no `timeout` command.
- GW2 (**89**, unchanged by 6A-CP): after `swift build --build-tests` in `Ferazel/Windows` —
  `'FerazelWinKitTests\.B'` (10, 310 s), `'FerazelWinKitTests\.(F|T)'` (19, 168 s),
  `'FerazelWinKitTests\.Win(D|F|G)'` (26, 307 s), `'FerazelWinKitTests\.Win(O|R|S|V)'` (26 + the 2 skips, 149 s),
  and `WinLevelReferenceTests` one test a command (`--filter WinLevelReferenceTests/testLevel10FirstFrameReference`
  and so on; levels 10 / 11 / 15 / 18 / 20 / 21: 175 / 154 / 124 / 127 / 126 / 99 s; three fit one command).
- G3, G5, GW1, GW3, GW4: the plan's §0 command block, from the archive copy. G5 needs HectorKit beside the copy:
  `ln -s ~/Developer/HectorKit <copy's parent>/HectorKit` (the project file points at `../HectorKit`), and
  `-derivedDataPath` in the scratch folder. Run 69: all five took under two minutes together.
- **A seat's command may run beside ONE working helper**: send the helper's dispatch and the one command in the
  same message, from the seat's own `git archive` copy (never in the worktree a helper builds in). A command that
  includes a cold release build beside a building helper can pass ten minutes (run 69's first sweep did).
  **A fix round that changes source voids every gate run before it** (D69.5); one held to tests and comments must
  be proven so (D68.5).
- A small script that runs one part and prints only `passed / failed / skipped / exit / time` keeps each gate
  command to one line of the seat's context (write your own in the scratch folder; end a chain with `; true`, or
  the script's last test makes the whole command look failed). `rm -rf` on a path built from a shell variable is
  refused by the app unless written `"${S:?}/name"`.

## This run

| step | what it must produce | Core after | WinKit after |
|---|---|---|---|
| **6A-CP** | the magic carpet (types 1080 / 1081), the player's built half proven | 812 | 89 |

- **Every Core number is two above the original plan** (D68.1, D69.1); the plan's ladder, cards and execution
  table already show the new numbers.
- **6A-CP:** Gate-F (no full sweep or bot is owed: no built level holds a carpet — check that against the level
  data before briefing; if a built level does, the gate grows). Contract: ENG §2.11, read in full by the
  implementer. The only shipped carpet is on level 22 (placement 486, p2 0: it never counts down, flashes or
  bursts — those arms are tested on made-up carpets). Fixture: level 22 with nothing left out and the player's
  start moved beside placement 486. The card names `DrawModeAuditTests.swift` for three mode words and
  `CachedFacesTests.swift` for level 22's re-derived count: those are named moves; nothing else may move.
- **Check a card's numbers against the level data before briefing** (D56.1), and **check any "first", "only" or
  "never" in a note against the data too** (D70.2: run 68's "first level with the darkness switch on" was wrong and
  cost a review finding). Card file anchors (`:NNN`) are stale in every card of this wave; dump citations have been
  off by one or two several times. The data wins; the dump beats the card.
- **One task at a time:** one `fk-implementer`, then two Opus review legs (spec, then quality with a mutation
  table, told what leg 1 found), a fix round, the seat's own gates at the merge.
- Brief each leg with the card, the document sections and dump spans the card cites, and the test names; do not
  pre-read source. Tell every helper: foreground only (never start a build in the background), ten-minute cut,
  the audit only by level group, commit before reporting, delete every copy and log before reporting, never
  launch the game.
- **The fix round** is a fresh `fk-implementer` briefed from the two review files and the reviewer's verified
  patch. If it is held to tests and comments, say so and prove it afterwards (the non-comment diff of
  `Ferazel/Core/Sources`, `Ferazel/App` and `Ferazel/Windows/Sources` over the fix round is empty). Comment edits
  in audited source files keep the line count.
- Reviewers write full findings to a scratch file **early, appending as they go**, and hand back a verdict; leg 2
  also writes a proposed-asserts patch and verifies it. Each leg builds in its own `mktemp` copy.
- **The audit test pins**, per level, how often the held item is drawn under water with kind 0 (level 2: 39,
  level 18: 7, others 0), which light proof each "no light" level stands on (18: D64.1's; 20: D67.1's; level 21
  needs none), and a census of refusals per file (`SetupFaces.swift` `Error.notTranscribed` is 14 since D69.3). A
  task that adds or removes a refusal moves that count by a named, explained edit (D67.3) — the carpet's Setup
  removes a `// later` arm, so expect one.
- **A helper whose edit is refused as outside its fence** reports it; the seat rules and a fix round makes the
  change with the ruling in its brief (D54.1, D61.1, D62.1, D64.1, D67.3, D69.2). The seat does not make the edit.
- **The ledger script models built types by hand** (`tools/ferazel/later-levels-ledger.py`): its `--check` proves
  line anchors only. Building 1080 / 1081 needs the script given a built arm — ask the implementer to say what the
  regenerated ledger changed, and rule the script into the fence (D69.2).
- **Pinned values.** Each card names what may change. Nothing else may move: the pictures and state pins of levels
  1–5, 10, 11, 15, 18, 20 and 21, the Windows level references, every fixture picture, the two chapter cards, the
  Chief's fight frames (111 / 1602 / 1710) and wake-up frames. A moved value the card does not name is a STOP.
- A picture's start point must actually show the feature (D51.1, D53.1), proven inside the test by a twin with the
  feature off (D54.2). A review leg's new asserts go inside the card's named tests (D51.2).
- After any commit that moves Core source or audit-test lines, run
  `python3 -I -B tools/ferazel/later-levels-ledger.py --check`; if stale, `--write`, check again, commit the ledger.
  Delete any `__pycache__` under `tools/ferazel/` and `docs/ferazel/tools/`.

## After this run
6A-L22 "The Labyrinth" (a level task: Gate-L, the full sweep and bot on twelve levels — run 69's group times on
eleven are in STATE and in "As executed — 6A-L21"; it also owns showing that its conversation 221 arms level 11's
record 283 in play, D70.1), then the phase end (6A-END: Proof B by day — watch `testBladeArmEndpoints` under Wine;
it has not run on any test added since run 64 — both builds staged, one gate card) and Ben's gate. **Not yet in
the plan** (STATE's run-68 carry, [MED]): a short reading of what a level restart does to the touch areas of the
other types that measure themselves from a cached picture — the 6A-END seat should rule whether it is a task
before the phase review.

## Binding rules
- Launch a build only **muted**, few and short, **never 21:00–09:00** — LAUNCH GUARD first. Headless work any hour.
- Game data and dumps are read-only: never edit `Resources/Ferazel/` or `ghidra/ferazel/`.
- Subagents: `fk-implementer` / `fk-reviewer`, **no `model` parameter** (Opus 5.5).
- Memory: at most 4 workers; never two heavy things at once; a sweep or bot is stopped with a plain
  `kill <script pid>` (never `-9`), the outer shell too; the 4 GB per-worker limit is never raised.
- Disk: delete every copy, build folder and log as soon as its check has passed; remove your worktree at the close.
- Never wait silently. Cap 300k of your own context (`get_usage` before each dispatch and at the close).
- Dump beats bank beats plan. Explicit-path commits, no `git stash`, `git branch --show-current` before each commit.

## Close (in this order)
1. Merge to local main `--ff-only` by SHA.
2. "As executed" under each card; the plan's "Goldens" paragraph gains new values; rulings in `docs/DECISIONS.md`
   under the next free number.
3. `docs/STATE.md`: replace the Ferazel block with today's state only; settled bits to the top of
   `docs/STATE-history.md`. One line in `docs/LOOP-LOG.md`. A short handoff with the real start and end times from
   `date`. A memory note only if the run taught a new standing rule (D62.6).
4. Rebuild this file from nothing for the next run (the tasks left of this wave, per the plan's "Execution order").
5. Push main, then start the next attended session (`start_session`, fresh context, brief "read docs/NEXT.md and run
   it") — unless a Coordinator started you (then it starts the next one), or a question only Ben can answer blocks the
   next step (then `STATUS: BLOCKED`, the item in QUESTIONS with `Blocks: everything`, no new session).
