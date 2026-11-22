STATUS: CONTINUE

# NEXT — Ferazel's Wand, run 65: the wave 6A.3 cross-check, then wave 6A.4 begins (6A-CL, 6A-BD, 6A-MP)

You are the seat for **Ferazel's Wand** in Ambrosia Classics, repo `/Users/andiyar/Developer/Ambrosia-Classics`
(`$REPO`). Method: `~/Developer/Toolkits/fable-kit/orchestrator.md`. This run opens with a review, then builds. In your
first message say which model you are and, in one sentence, what you will do first; then start. **If a Coordinator
session started you, its overrides win over this file** (who starts the next session, the handoff's name,
foreground-only work, removing your worktree).

**Authority:** `docs/superpowers/plans/2026-11-04-ferazel-remainder.md` — the one plan. This run's cards:
`#### 6A-CL`, `#### 6A-BD`, `#### 6A-MP` in "Wave 5 — Phase 6A", with that section's opening rules ("Every
engine-feature task"), "Verification-model additions for 6A" (the level fixture; the gate bundles: **Gate-F**;
**Wave end**) and "Execution order". The seat reads the cards and the gate block only; implementers read
"0. The verification model", "Invariants and hazards" and "Shared architecture" themselves. As models read
"As executed — 6A-RN" (the last engine feature built on a fixture, run 60) and "As executed — 6A-L18" (run 64).
Nothing else is a plan.

## Read first
1. `CLAUDE.md` (repo root).
2. `docs/STATE.md` — the Ferazel block: the live state. This chip holds no state.
3. `docs/QUESTIONS.md` "Open" — act first on any new text under an `Answer:` and record it in `docs/DECISIONS.md`
   (Q18 is Ben's Phase 5 gate: notes become tasks at the head of the order; a fail stops the build and becomes a fix
   wave. Q21: whether the sweep and the bot may run detached. Q19: his choices on the 6A plan).
4. `docs/DECISIONS.md` D63 (D63.6 above all: the blade task meets a case the original itself gets wrong), D62, D61,
   D59 (D59.1: the one script that may run detached), D54, D51, and `docs/handoff-2026-11-22-ferazel-run64.md`.

## Before anything else
- **The weekly usage limit** (`get_usage`). Run 64 closed at 75% Fable, about 60% all models; the week resets on
  2026-11-24 at 02:00 Sydney time. The cross-check below is the Fable-heavy part and it must come before 6A-CL. Do
  it lean (the diff by file, the review findings, the gate numbers — not whole sources). If the limit is so close
  that you cannot finish it, close with that as your reason rather than skip it.
- **Your own context.** Read the meter before every dispatch. Run 64 began at 116k, was at 148k before its first
  dispatch and about 230k at its close, after one task (five helper reports) and about forty gate commands.
- **How long one command may run.** `echo "$CLAUDE_CODE_DISABLE_BACKGROUND_TASKS"`: `1` means background work is off
  and a foreground command is cut off at ten minutes. Then every suite runs in parts (below), **never two parts
  chained in one command**. Only `tools/windows/proof-b-ferazel.sh` may run detached (D59.1).
- **The time of day** (`date`). Nothing in this run needs a launch: the three tasks are headless (Gate-F), and wave
  6A.3's launch checks were done in run 64.

## Reconcile first
- `git -C "$REPO" worktree list`, `git -C "$REPO" log --oneline -8 main`: main at or past run 64's close. Other
  sessions (Deimos, Castles) also merge to local main: merge main into your branch before each `--ff-only`, and
  check the next free D-number at the close (D64 unless another project took it).
- G1 HectorKit per the plan's gate table (main ef2c341, clean, at run 64).
- G2 is not owed at the start (run 64's own, at a66d567: **764**, 0 failed, the two opt-in skips by name). At each
  merge it runs from a `git archive` copy with `HECTORKIT_PATH=$HOME/Developer/HectorKit` set (game data is in git,
  so the copy is complete). After one `swift build --build-tests` in `Ferazel/Core`, each part is its own command,
  `swift test --skip-build --filter …` (run 64's times):

  | part | tests | time |
  |---|---:|---:|
  | `--filter FerazelCoreTests` | 593 | 110 s |
  | `--filter 'FerazelRenderTests\.[A-C]'` | 27 | 273 s |
  | `--filter 'FerazelRenderTests\.[D-E]' --skip DrawModeAuditTests` | 16 | 53 s |
  | `FERAZEL_AUDIT_LEVELS=1,2,3,4,5 … --filter DrawModeAuditTests/testEveryWrittenModeIsDrawable` | 1 | 188 s |
  | `FERAZEL_AUDIT_LEVELS=10,11,15 …` the same test | (the same 1) | 331 s |
  | `FERAZEL_AUDIT_LEVELS=18 …` the same test | (the same 1) | 40 s |
  | `FERAZEL_AUDIT_LEVELS=1,2,3,4,5 … --filter DrawModeAuditTests/testEveryRefusalIsUnreachable` | 1 | 191 s |
  | `FERAZEL_AUDIT_LEVELS=10,11,15 …` the same test | (the same 1) | 335 s |
  | `FERAZEL_AUDIT_LEVELS=18 …` the same test | (the same 1) | 44 s |
  | `--filter 'FerazelRenderTests\.[F-K]'` | 38 | 186 s |
  | `--filter 'FerazelRenderTests\.L'` | 17 | 357 s |
  | `--filter 'FerazelRenderTests\.[M-Z]'` | 69 + the 2 skips | 152 s |

  The `\.L` part is the longest: if a task adds a test whose class starts with L, time it early and split the part.
  New feature pictures land in `FeatureGoldenTests` (the F–K part): split that part if it nears seven minutes.
  Each log ends with a second, empty bundle's "Executed 0 tests" — count the `Test Case … passed` lines instead. A
  wrong filter runs zero tests and still exits 0. This Mac has no `timeout` command — use the Bash tool's own timeout.
- GW2 (**87**, unchanged by this run's three tasks): after `swift build --build-tests` in `Ferazel/Windows` —
  `'FerazelWinKitTests\.B'` (10, 348 s), `'FerazelWinKitTests\.(F|T)'` (19, 173 s),
  `'FerazelWinKitTests\.Win(D|F|G)'` (26, 312 s), `'FerazelWinKitTests\.Win(O|R|S|V)'` (26 + the 2 skips, 147 s),
  and `WinLevelReferenceTests` one test a command: `…/testLevel10FirstFrameReference`, `…Level11…`, `…Level15…`,
  `…Level18…` (172 / 152 / 121 / 125 s).
- **A seat's command may run beside ONE working helper**: send the helper's dispatch and the one command in the same
  message.

## This run

| step | what it must produce | Core after | WinKit after |
|---|---|---|---|
| **the wave 6A.3 cross-check** | the Fable seat's own review of the wave's whole diff and gate numbers; findings to one fix round | 764 | 87 |
| **6A-CL** | clouds, on a level-20 fixture | 771 | 87 |
| **6A-BD** | the rotating blade and the segment test | 784 | 87 |
| **6A-MP** | programmed-path maces, modes 1 and 2 | 791 | 87 |

- **The cross-check first, before any task** (the plan's "Wave end" rule; the one review the Fable seat does
  itself). The wave is 6A-BG1c, 6A-RN, 6A-L15, 6A-CH1, 6A-CH2, 6A-L18: `git diff 66875a3 a66d567` (66875a3 is the
  last commit before 6A-BG1c's work — confirm with `git log`), read by file with the six "As executed" notes and
  D59–D63 beside it. Its gate numbers are in STATE's table, all taken at a66d567. Look hardest at what no single
  task's reviewers could see: things two tasks both touched (the picture loader, the draw-mode audit's rows and its
  two new proofs from run 64, the Smite list, `LevelRun`), stand-ins left behind, and comments that still promise
  work a later task already did. Findings go to **one** fix round (an `fk-implementer`), reviewed by one Opus leg,
  then G2 and GW2 in parts if any source or test moved.
- **Then the three tasks, in the card order, one at a time** (each measures on a fixture the one before it defines —
  never two at once): one `fk-implementer`, then two Opus review legs (spec, then quality with a mutation table,
  told what leg 1 found), a fix round, the seat's own G2 and GW2 at the merge. Gate-F: no sweep or bot is owed
  (no level opens), and nothing is launched.
- **Known before you brief 6A-BD (D63.6):** level 20's light grid is all −1 (19,200 cells), and its 28 blades
  (type 3060) take their brightness from the cell they sit on. The original then draws with the word `0xbff00 + F`,
  which reads its grey-pull table far before the table's start (`.BlitEncFaceTransClip`, M l. 23277–23286): there
  is no defined picture to copy. The blade task must find out what the original actually shows there (the bytes it
  reads are whatever sits before the table — look at what that memory is in the dump's data section), and you rule
  what the port draws before the fixture's picture is measured. If only Ben can say, queue it in QUESTIONS and build
  the rest of the card around it. Run 64's audit proof for such levels ("no dynamic-light sprite can exist here")
  will not hold on level 20 and will need its own replacement when 6A-L20 opens the level — not in this run.
- Brief each leg with the card, the document sections and dump spans the card cites, and the test names; do not
  pre-read source.
- **The fix round** is a fresh `fk-implementer` briefed from the two review files and the reviewer's verified patch
  when background work is off (a resumed helper runs in the background). If it is held to tests, comments and tool
  scripts, say so in its brief and prove it afterwards with `git diff <task commit> -- Ferazel/Core/Sources`.
- Reviewers write full findings to a scratch file **early, appending as they go**, run everything in the foreground,
  and hand back a verdict; leg 2 also writes a proposed-asserts patch and verifies it. Each leg builds in its own
  `mktemp` copy (`git archive <sha> | tar -x`, `HECTORKIT_PATH` set). Tell every helper to commit before it reports.
- **Check a card's numbers against the level data before briefing** (D56.1), or tell the implementer plainly that
  they are unchecked. The data wins; where the dump and the card disagree, the dump wins (eleven times in runs 60–64).
- **A helper whose edit is refused as outside its fence** reports it; the seat rules (D54.1, D61.1, D62.1, D63.1) and
  a fix round makes the change with the ruling written in its brief. The seat does not make the edit for it.
- **Pinned values.** Each card names what may change. Nothing else may move: the pictures and state pins of levels
  1–5, 10, 11, 15 and 18, the Windows level references, every fixture picture, the two chapter cards, the Chief's
  fight frames (111 / 1602 / 1710) and wake-up frames. A moved value the card does not name is a STOP.
- A picture's start point must actually show the feature (D51.1, D53.1), **proven inside the test by a twin with the
  feature off** (D54.2).
- **A review leg's new asserts go inside the card's named tests** (D51.2): the ladder is the card's number.
- After any commit that moves Core source or audit-test lines, run
  `python3 -I -B tools/ferazel/later-levels-ledger.py --check`; if it says a generated block is stale, `--write`, check
  again, and commit the ledger. A task that builds a type the script still calls refused must give the script a
  built arm (D61.1). Delete any `__pycache__` under `tools/ferazel/` and `docs/ferazel/tools/`.
- **If the context will not hold all three tasks**, finish the one in flight at about 240k and close; the rest head
  the next run.

## After this run
Level 20 "Hangnabit" (6A-L20, with the full sweep and bot on ten levels — split the Windows-path sweep of levels 3
and 4 into one level a command: together they took 509 s in run 64), then 6A-PS, 6A-L21, 6A-CP, 6A-L22, the phase
end (6A-END) and Ben's gate card.

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
   under the next free number.
3. `docs/STATE.md`: replace the Ferazel block with today's state only; settled bits to the top of
   `docs/STATE-history.md`. One line in `docs/LOOP-LOG.md`. A short handoff with the real start and end times from
   `date`. A memory note only if the run taught a new standing rule (D62.6).
4. Rebuild this file from nothing for the next run (the tasks left of this wave, then 6A-L20, per the plan's
   "Execution order").
5. Push main, then start the next attended session (`start_session`, fresh context, brief "read docs/NEXT.md and run
   it") — unless a Coordinator started you (then it starts the next one), or a question only Ben can answer blocks the
   next step (then `STATUS: BLOCKED`, the item in QUESTIONS with `Blocks: everything`, no new session).
