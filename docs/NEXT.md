STATUS: CONTINUE

# NEXT — Ferazel's Wand, run 71: level 22 "The Labyrinth" (6A-L22)

> **Ben's ruling, 2026-11-26 — finish Phase 6A, then archive (this overrides the plan where they differ).**
> The original author is selling an official remaster (https://mixedmetaphor.itch.io/ferazels-wand), so Ferazel
> stops at the 6A phase end. The project is paused, not cancelled: Ben resumes if the remaster disappoints.
> 1. **This run (71) is unchanged:** 6A-L22 alone. At its close, record this ruling as the next free D-number,
>    carry this whole block to the top of the next chip, and start run 72 as usual.
> 2. **Run 72 = 6A-END, with three changes.**
>    (a) **A level chooser, before staging.** Ben: "we may want a way to skip between the levels as the progression
>    won't exist." Today only the hidden `FerazelLevel` launch switch does this. Add a way inside the game, on both
>    Mac and Windows, to start any built level (1–5, 10, 11, 15, 18, 20, 21, 22) without a command line — a named,
>    listed departure from the original, built through `GameFlow.startLevel`, as its own small task (one
>    implementer, two review legs). Say how to use it on both what-to-expect cards.
>    (b) **Complete builds for both platforms**, staged for Ben and for Andrew. **No GitHub release and no public
>    upload:** the Windows zip and its checksum go to `releases/` in the main checkout only; Ben sends it himself.
>    (c) **No 6B planning run and no next session.** After the cross-check and the tidy, archive: `STATUS: PAUSED`
>    as the first line of this file with a short "how to resume" (the next step is the 6B planning run, P6B);
>    STATE's Ferazel block says paused and why; the Ferazel worktrees and their DerivedData folders are removed;
>    the handoff is the archive note. Everything else (the plan, the RE bank, the ledger, the dumps) stays as it is.
> 3. Open questions that only matter to 6B or later (Q19, Q21, …) are closed as "paused", not asked.

You are the seat for **Ferazel's Wand** in Ambrosia Classics, repo `/Users/andiyar/Developer/Ambrosia-Classics`
(`$REPO`). Method: `~/Developer/Toolkits/fable-kit/orchestrator.md`. In your first message say which model you are
and, in one sentence, what you will do first; then start. **If a Coordinator session started you, its overrides win
over this file** (who starts the next session, the handoff's name, foreground-only work, removing your worktree,
its mailbox for questions).

**Authority:** `docs/superpowers/plans/2026-11-04-ferazel-remainder.md` — the one plan. This run's card:
`#### 6A-L22` in "Wave 5 — Phase 6A", with that section's opening rules, "Verification-model additions for 6A"
(the gate bundles: **Gate-L** for a level task), "The sweep's and the bot's budget" and "Execution order". The seat
reads the card and the gate block only; implementers read "0. The verification model", "Invariants and hazards" and
"Shared architecture" themselves. The model for a level task is "As executed — 6A-L21" (run 69): it holds the
sweep's level groups, the bot's commands and their times. Nothing else is a plan.

## Read first
1. `CLAUDE.md` (repo root).
2. `docs/STATE.md` — the Ferazel block: the live state. This chip holds no state.
3. The Coordinator mailbox `~/.claude/coordinator-notes/ferazel-6A-mailbox.md` — Q1 is answered and recorded
   (D71.5); act on any newer `A` or `NOTE`. The next free question number there is Q2.
4. `docs/QUESTIONS.md` "Open" — act first on any new text under an `Answer:` (Q18 is Ben's Phase 5 gate: notes
   become tasks at the head of the order; a fail stops the build. Q21: may the sweep and bot run detached. Q19).
5. `docs/DECISIONS.md` **D71** (run 70), D70 (D70.1: this task owns showing that conversation 221 arms level 11's
   record 283 in play), D69, D68, D67, D64, D62, D61, D59 (D59.1: the one script that may run detached; D59.4 and
   D60.4: how the sweep and bot are split), D54, D51, and `docs/handoff-2026-11-26-ferazel-run70.md`.

## Before anything else
- **The weekly usage limit** (`get_usage`). Run 70 closed at about 55% Fable, 72% all models; the week resets on
  2026-12-01 at 02:00 Sydney time. A level task with its sweep and bot cost run 69 about 15 points of the
  all-models figure. If the task cannot be finished inside the limit, do not start it: close with
  `STATUS: BLOCKED` and say so.
- **Your own context.** Read the meter before every dispatch. Run 69 (the last level task) went from 119k at the
  start to 203k when its gates were done and about 235k at the close. **This run is 6A-L22 alone.** At about 240k
  finish the task in flight and close; do not start 6A-END.
- **How long one command may run.** `echo "$CLAUDE_CODE_DISABLE_BACKGROUND_TASKS"`: `1` means background work is
  off and a foreground command is cut off at ten minutes. Every suite runs in parts (below); the sweep one level
  group a command, the bot one command a shell. Only `tools/windows/proof-b-ferazel.sh` may run detached (D59.1).
- **One heavy command a message** (D70.6). **Chain parts in one command only when their usual times sum under
  about six minutes** (D71.6): with other projects building on this Mac a part can run a third slower.
- **The time of day** (`date`). Level 22 opening owes a boot check: launched **muted**, by day only (never
  21:00–09:00), LAUNCH GUARD first. Record it as "started and stayed running" — the seat's request to look at the
  game's window was declined (D70.5): do not ask again and do not look for another way; eyes on levels 20, 21 and
  22 stay with Ben. At night, write "boot check owed (night rule)" and carry it to 6A-END.

## Reconcile first
- `git -C "$REPO" worktree list`, `git -C "$REPO" log --oneline -8 main`: main at or past run 70's close (651314e
  plus its docs commits). Other sessions (Deimos, Castles) also merge to local main: merge main into your branch
  before each `--ff-only`, and check the next free D-number at the close (D72 unless another project took it).
- G1 HectorKit per the plan's gate table (main ef2c341, clean, at run 70). A worktree needs the untracked link
  `../HectorKit → ~/Developer/HectorKit` beside it, or `HECTORKIT_PATH=$HOME/Developer/HectorKit`.
- G2 is not owed at the start (run 70's own, at 651314e: **812**, 0 failed, the two opt-in skips by name). At the
  merge it runs from a `git archive` copy with `HECTORKIT_PATH` set. After one `swift build --build-tests` in
  `Ferazel/Core`, each part is `swift test --skip-build --filter …` (run 70's times, on a busy Mac):

  | part | tests | time |
  |---|---:|---:|
  | `--filter FerazelCoreTests` | 633 | 136 s |
  | `--filter 'FerazelRenderTests\.[A-C]'` | 27 | 424 s (315 on a quiet Mac) — alone in its command |
  | `--filter 'FerazelRenderTests\.[D-E]' --skip DrawModeAuditTests` | 16 | 55 s |
  | `--filter 'FerazelRenderTests\.[F-K]'` | 42 | 258 s |
  | `--filter 'FerazelRenderTests\.(LevelFixtureRenderTests\|LevelFrameGoldenTests\|LightingTests)'` | 16 | 104 s |
  | `--filter 'FerazelRenderTests\.LevelSweepTests'` | 3 | 298 s |
  | `--filter 'FerazelRenderTests\.[M-Z]'` | 71 + the 2 skips | 164 s |
  | `FERAZEL_AUDIT_LEVELS=1,2,3,4,5 … --filter DrawModeAuditTests/testEveryWrittenModeIsDrawable` | 1 of the 2 | 191 s |
  | `FERAZEL_AUDIT_LEVELS=1,2,3,4,5 … --filter DrawModeAuditTests/testEveryRefusalIsUnreachable` | the other | 202 s |
  | `FERAZEL_AUDIT_LEVELS=10,11,15 … --filter DrawModeAuditTests/testEveryWrittenModeIsDrawable` | (the same) | 369 s |
  | `FERAZEL_AUDIT_LEVELS=10,11,15 … --filter DrawModeAuditTests/testEveryRefusalIsUnreachable` | (the same) | 377 s |
  | `FERAZEL_AUDIT_LEVELS=18 … --filter DrawModeAuditTests` (both tests) | (the same) | 87 s |
  | `FERAZEL_AUDIT_LEVELS=20 … --filter DrawModeAuditTests` (both tests) | (the same) | 203 s |
  | `FERAZEL_AUDIT_LEVELS=21 … --filter DrawModeAuditTests` (both tests) | (the same) | 115 s |

  Level 22 adds its own audit group (`FERAZEL_AUDIT_LEVELS=22`, time unknown: 510 records, the biggest level yet —
  run it one test a command the first time). Its 4 new tests land in the rules part and the L classes. Each log
  ends with a second, empty bundle's "Executed 0 tests" — count the `Test Case … passed` lines. A wrong filter
  runs zero tests and still exits 0. This Mac has no `timeout` command.
- GW2 (**89 → 90**): after `swift build --build-tests` in `Ferazel/Windows` — `'FerazelWinKitTests\.B'` (10,
  333 s), `'FerazelWinKitTests\.(F|T)'` (19, 174 s), `'FerazelWinKitTests\.Win(D|F|G)'` (26, 304 s),
  `'FerazelWinKitTests\.Win(O|R|S|V)'` (26 + the 2 skips, 141 s), and `WinLevelReferenceTests` one test a command
  (`--filter WinLevelReferenceTests/testLevel10FirstFrameReference` and so on; levels 10 / 11 / 15 / 18 / 20 / 21:
  169 / 153 / 121 / 121 / 133 / 107 s; three fit one command), plus the new `testLevel22FirstFrameReference`.
- G3, G5, GW1, GW3, GW4: the plan's §0 command block, from the archive copy. G5 needs HectorKit beside the copy:
  `ln -s ~/Developer/HectorKit <copy's parent>/HectorKit`, and `-derivedDataPath` in the scratch folder
  (`WIN_BUILD_ROOT` there too). Run 70: G3 + G5 + GW4 took 78 s together, GW1 + GW3 41 s.
- **The full sweep and bot (Gate-L), twelve levels, both paths:** the level groups, the exact commands and run
  69's times on eleven levels are in "As executed — 6A-L21" and in STATE's numbers table. At most 4 workers, one
  group a command, nothing else heavy running (no helper building beside it). The quick mode on level 22 first
  (`FERAZEL_BOT_LEVELS=22 FERAZEL_BOT_MINUTES=1 tools/ferazel-random-play.sh core`), 0 failures.
- **A seat's command may run beside ONE working helper**: send the helper's dispatch and the one command in the
  same message, from the seat's own `git archive` copy (never in the worktree a helper builds in).
  **A fix round that changes source voids every gate run before it** (D69.5); one held to tests and comments must
  be proven so (D68.5, D71.4).
- A small script that runs one part and prints only `passed / failed / skipped / exit / time` keeps each gate
  command to one line of the seat's context (write your own in the scratch folder; end a chain with `; true`).
  `rm -rf` on a path built from a shell variable is refused by the app unless written `"${S:?}/name"`; in zsh a
  glob that matches nothing aborts the whole command, so quote it or delete by exact name.

## This run

| step | what it must produce | Core after | WinKit after |
|---|---|---|---|
| **6A-L22** | level 22 "The Labyrinth" opens; the built-level list holds every level through the Goblin Chief | 816 | 90 |

- **Every Core number is two above the original plan** (D68.1, D69.1); the plan's ladder, cards and execution
  table already show the new numbers.
- **6A-L22:** Gate-L. Contract: the ledger's §4 "Level 22" (`docs/ferazel/later-levels-ledger.md`), read by the
  implementer. The card says "52 refused today … the carpet 1": **that figure is old** — the regenerated ledger
  now shows 0 refused records on level 22 (the blades, maces, faces, talkers and the carpet are all built since).
  Check the ledger's level-22 section and the level data before briefing; any record still refused is a STOP for
  the task that owns its type.
- **Things this level is the first to show, each to be looked at by the implementer and the reviewers:**
  - **The carpet in real play** (placement 486, at (7849, 2017)): its picture is stored at Setup where the
    original sets it on the first Handle and draws nothing for a frame (run 70's carry). Say whether the carpet
    can be on screen on level 22's first frames from the real start; if it can, that is a finding to rule.
  - **Conversation 221** (Dimbo, type 2956): its actions 9 and 10, and that it arms level 11's record 283 in play
    (D70.1) — the card's `testDimboConversationActions`.
  - **The blades' bottom clip** (p4 0) on screen; the blade's Setup slot carries a face the original does not set
    (run 66's carry: "check again on level 22").
  - The level-22 load bar: `CachedFacesTests` now pins [36, 176, 352, 36] (set #27 marked by the carpet); the
    card's `testLevel22SetsUpEveryRecord` must equal it "as last re-derived".
- **Check a card's numbers against the level data before briefing** (D56.1), and **check any "first", "only" or
  "never" in a note against the data too** (D70.2). Card file anchors (`:NNN`) are stale in every card of this
  wave. The data wins; the dump beats the card.
- **One task at a time:** one `fk-implementer`, then two Opus review legs (spec, then quality with a mutation
  table, told what leg 1 found), a fix round, the seat's own gates at the merge.
- Brief each leg with the card, the document sections and dump spans the card cites, and the test names; do not
  pre-read source. Tell every helper: foreground only (never start a build in the background), ten-minute cut,
  the audit only by level group, commit before reporting, delete every copy and log before reporting, never
  launch the game. An implementer's brief names its co-author line (`Claude Opus 5.5`).
- **The fix round** is a fresh `fk-implementer` briefed from the two review files and the reviewer's verified
  patch. If it is held to tests and comments, say so and prove it afterwards (the non-comment diff of
  `Ferazel/Core/Sources`, `Ferazel/App` and `Ferazel/Windows/Sources` over the fix round is empty). Comment edits
  in audited source files keep the line count.
- Reviewers write full findings to a scratch file **early, appending as they go**, and hand back a verdict; leg 2
  also writes a proposed-asserts patch and verifies it. Each leg builds in its own `mktemp` copy.
- **The audit test pins**, per level, how often the held item is drawn under water with kind 0 (level 2: 39,
  level 18: 7, others 0), which light proof each "no light" level stands on (18: D64.1's; 20: D67.1's; level 21
  needs none — say what level 22 needs, from its own light bytes), and a census of refusals per file
  (`SetupFaces.swift` `Error.notTranscribed` is 14, unchanged by the carpet — D71.2). A task that adds or removes
  a refusal moves that count by a named, explained edit (D67.3).
- **A helper whose edit is refused as outside its fence** reports it; the seat rules and a fix round makes the
  change with the ruling in its brief (D54.1, D61.1, D62.1, D64.1, D67.3, D69.2, D71.3). The seat does not make
  the edit.
- **Pinned values.** The card names what may change (the built-level list and the tests pinned to it). Nothing
  else may move: the pictures and state pins of levels 1–5, 10, 11, 15, 18, 20 and 21, the Windows level
  references, every fixture picture (the carpet's `ec4f4abda0acfd79` included), the two chapter cards, the Chief's
  fight frames (111 / 1602 / 1710) and wake-up frames. A moved value the card does not name is a STOP.
- A picture's start point must actually show the feature (D51.1, D53.1), proven inside the test by a twin with the
  feature off (D54.2). A review leg's new asserts go inside the card's named tests (D51.2).
- After any commit that moves Core source or audit-test lines, run
  `python3 -I -B tools/ferazel/later-levels-ledger.py --check`; if stale, `--write`, check again, commit the ledger.
  Delete any `__pycache__` under `tools/ferazel/` and `docs/ferazel/tools/`.

## After this run
6A-END, the phase end: Proof B by day (watch `testBladeArmEndpoints` under Wine; it has not run on any of the 46
tests added since run 64), the Mac SDL smoke, the relabel sweep, both builds staged, one gate card, the Fable
cross-check over the whole 6A diff, then Ben's gate. **Not yet in the plan** (STATE's run-68 carry, [MED]): a short
reading of what a level restart does to the touch areas of the other types that measure themselves from a cached
picture — the 6A-END seat should rule whether it is a task before the phase review.

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
2. "As executed" under the card; the plan's "Goldens" paragraph gains new values; rulings in `docs/DECISIONS.md`
   under the next free number.
3. `docs/STATE.md`: replace the Ferazel block with today's state only; settled bits to the top of
   `docs/STATE-history.md`. One line in `docs/LOOP-LOG.md` (the sweep's and bot's summary lines in it). A short
   handoff with the real start and end times from `date`. A memory note only if the run taught a new standing rule.
4. Rebuild this file from nothing for the next run (6A-END, per the plan's "Execution order").
5. Push main, then start the next attended session (`start_session`, fresh context, brief "read docs/NEXT.md and run
   it") — unless a Coordinator started you (then it starts the next one), or a question only Ben can answer blocks the
   next step (then `STATUS: BLOCKED`, the item in QUESTIONS with `Blocks: everything`, no new session).
