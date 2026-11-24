STATUS: CONTINUE

# NEXT — Ferazel's Wand, run 67: level 20 "Hangnabit" opens (6A-L20), then 6A-PS if the context holds

You are the seat for **Ferazel's Wand** in Ambrosia Classics, repo `/Users/andiyar/Developer/Ambrosia-Classics`
(`$REPO`). Method: `~/Developer/Toolkits/fable-kit/orchestrator.md`. In your first message say which model you are
and, in one sentence, what you will do first; then start. **If a Coordinator session started you, its overrides win
over this file** (who starts the next session, the handoff's name, foreground-only work, removing your worktree,
its mailbox for questions).

**Authority:** `docs/superpowers/plans/2026-11-04-ferazel-remainder.md` — the one plan. This run's cards:
`#### 6A-L20` (with "Run 66's notes for this card") and `#### 6A-PS` in "Wave 5 — Phase 6A", with that section's
opening rules, "Verification-model additions for 6A" (the gate bundles: **Gate-L** for the level task, **Gate-F**
for 6A-PS), "Execution order" and "The sweep's and the bot's budget as levels 10–22 join". The seat reads the
cards and the gate block only; implementers read "0. The verification model", "Invariants and hazards" and "Shared
architecture" themselves. The model for a level task is "As executed — 6A-L18" (run 64); for what level 20's
features measured, "As executed — 6A-CL / 6A-BD / 6A-MP" (run 66). Nothing else is a plan.

## Read first
1. `CLAUDE.md` (repo root).
2. `docs/STATE.md` — the Ferazel block: the live state. This chip holds no state.
3. The Coordinator mailbox `~/.claude/coordinator-notes/ferazel-6A-mailbox.md` — **Q1** (what a lit blade on
   level 20 shows). If Ben answered, his answer replaces D67.1's default; record it in `docs/DECISIONS.md`.
4. `docs/QUESTIONS.md` "Open" — act first on any new text under an `Answer:` (Q18 is Ben's Phase 5 gate: notes
   become tasks at the head of the order; a fail stops the build. Q21: may the sweep and bot run detached. Q19).
5. `docs/DECISIONS.md` **D67** (run 66), D64 (level 18's audit proofs, the model for level 20's), D62, D61, D59
   (D59.1: the one script that may run detached), D54, D51, and `docs/handoff-2026-11-24-ferazel-run66.md`.

## Before anything else
- **The weekly usage limit** (`get_usage`). Run 66 closed at 29% Fable, 39% all models; the week resets on
  2026-12-01 at 02:00 Sydney time. If a task cannot be finished inside the limit, do not start it.
- **Your own context.** Read the meter before every dispatch. A session starts near 124k before any work. Run 66
  spent about 30k a task (five helper reports and one merge's twenty gate commands). A level task adds the sweep
  and the bot on ten levels (about fifteen more commands a shell): expect 6A-L20 alone to take 50–60k. At about
  240k finish the task in flight and close.
- **How long one command may run.** `echo "$CLAUDE_CODE_DISABLE_BACKGROUND_TASKS"`: `1` means background work is
  off and a foreground command is cut off at ten minutes. Every suite runs in parts (below). Two short parts may
  share a command only when their times sum well under ten minutes. Only `tools/windows/proof-b-ferazel.sh` may
  run detached (D59.1).
- **The time of day** (`date`). 6A-L20's card may owe a muted launch check (see Gate-L and D42): launches only
  muted, never 21:00–09:00; if the hour forbids it, write "boot check owed (night rule)" and go on.

## Reconcile first
- `git -C "$REPO" worktree list`, `git -C "$REPO" log --oneline -8 main`: main at or past run 66's close. Other
  sessions (Deimos, Castles) also merge to local main: merge main into your branch before each `--ff-only`, and
  check the next free D-number at the close (D68 unless another project took it).
- G1 HectorKit per the plan's gate table (main ef2c341, clean, at run 66).
- G2 is not owed at the start (run 66's own, at 771e1e4: **791**, 0 failed, the two opt-in skips by name). At each
  merge it runs from a `git archive` copy with `HECTORKIT_PATH=$HOME/Developer/HectorKit` set. After one
  `swift build --build-tests` in `Ferazel/Core`, each part is `swift test --skip-build --filter …` (run 66's
  times):

  | part | tests | time |
  |---|---:|---:|
  | `--filter FerazelCoreTests` | 615 | 119 s |
  | `--filter 'FerazelRenderTests\.[A-C]'` | 27 | 280 s |
  | `--filter 'FerazelRenderTests\.[D-E]' --skip DrawModeAuditTests` | 16 | 55 s |
  | `FERAZEL_AUDIT_LEVELS=1,2,3,4,5 … --filter DrawModeAuditTests/testEveryWrittenModeIsDrawable` | 1 | 208 s |
  | `FERAZEL_AUDIT_LEVELS=10,11,15 …` the same test | (the same 1) | 338 s |
  | `FERAZEL_AUDIT_LEVELS=18 …` the same test | (the same 1) | 40 s |
  | `FERAZEL_AUDIT_LEVELS=1,2,3,4,5 … --filter DrawModeAuditTests/testEveryRefusalIsUnreachable` | 1 | 196 s |
  | `FERAZEL_AUDIT_LEVELS=10,11,15 …` the same test | (the same 1) | 339 s, once 449 s |
  | `FERAZEL_AUDIT_LEVELS=18 …` the same test | (the same 1) | 44 s |
  | `--filter 'FerazelRenderTests\.[F-K]'` | 42 | 247 s |
  | `--filter 'FerazelRenderTests\.L'` | 17 | 330 s |
  | `--filter 'FerazelRenderTests\.[M-Z]'` | 70 + the 2 skips | 161 s |

  **Level 20 joins the audit: give it its own group (`FERAZEL_AUDIT_LEVELS=20`), never add it to 10,11,15** (that
  group has already touched 449 s). The `\.L` part gains the new level's tests: time it early and split it if it
  nears seven minutes. Each log ends with a second, empty bundle's "Executed 0 tests" — count the
  `Test Case … passed` lines. A wrong filter runs zero tests and still exits 0. This Mac has no `timeout` command.
- GW2 (**87** → 88 with 6A-L20): after `swift build --build-tests` in `Ferazel/Windows` —
  `'FerazelWinKitTests\.B'` (10, 325 s), `'FerazelWinKitTests\.(F|T)'` (19, 178 s),
  `'FerazelWinKitTests\.Win(D|F|G)'` (26, 307 s), `'FerazelWinKitTests\.Win(O|R|S|V)'` (26 + the 2 skips, 149 s),
  and `WinLevelReferenceTests` one test a command (levels 10 / 11 / 15 / 18: 189 / 166 / 122 / 123 s; level 20's new).
- G5 from an archive copy needs HectorKit beside the copy: `ln -s ~/Developer/HectorKit <copy's parent>/HectorKit`
  (the project file points at `../HectorKit`), and `-derivedDataPath` in the scratch folder.
- **A seat's command may run beside ONE working helper**: send the helper's dispatch and the one command in the
  same message.
- A small script that runs one part and prints only `passed / failed / skipped / exit / time` keeps each gate
  command to one line of the seat's context (write your own in the scratch folder).

## This run

| step | what it must produce | Core after | WinKit after |
|---|---|---|---|
| **6A-L20** | level 20 "Hangnabit" enterable, with D67.1 built first | 794 | 88 |
| **6A-PS** (only if the context holds) | the pipes' level spawn | 795 | 88 |

- **6A-L20 has one piece the card did not foresee (D67.1) — brief it as part of the task, built and tested before
  the level is added to the built list:** on level 20 the map has no lighting, and a blade lit by a light made
  during play (the player's shot within about 36 px of a hub; Gremlin drops, explosions, opened Box items) makes
  the original read leftover memory. Today the port refuses that draw, and a refused draw ends the game in the
  app. The ruling: draw the blade plain and unlit there (the F 0 draw), a named known deviation — unless Ben's
  mailbox answer says otherwise. It needs its own test, a line in the plan's "Known deviations added by 6A", and
  the audit's proof for level 20 (run 64's "no dynamic-light sprite can exist here" does not hold on this level;
  D64.1 is the model for writing a replacement). This widens the card's Files (the place the draw word is formed,
  or the blitter's refusal): say so in the brief as the seat's ruling.
- **Also known for 6A-L20 (run 66's findings):** the 328 cloud draws are the level's draws 2…329 (one draw comes
  first); the clouds' frame-1 picture shows loaded faces where the original's first load shows a placeholder, and
  the blade's Setup slot carries a face the original does not set at Setup — both can show in the level's first
  frame, so the implementer must check them against the dump before pinning it; the mace picture is deleted and
  its trace gains record 267; the level's load bar was last re-derived as `[16, 57, 114, 16]`.
- **One task at a time:** one `fk-implementer`, then two Opus review legs (spec, then quality with a mutation
  table, told what leg 1 found), a fix round, the seat's own gates at the merge. Gate-L adds to Gate-F: G3, the
  new Windows reference, and **the full sweep and bot on ten levels, both shells** — one level group a command;
  split the Windows-path sweep of levels 3 and 4 into one level a command (together they took 509 s in run 64).
  Commands and budget: the plan's "The sweep's and the bot's budget" and "As executed — 6A-L18".
- Brief each leg with the card, the document sections and dump spans the card cites, and the test names; do not
  pre-read source. Tell every helper: foreground only, ten-minute cut, the audit only by level group, commit before
  reporting, delete every copy and log before reporting.
- **The fix round** is a fresh `fk-implementer` briefed from the two review files and the reviewer's verified
  patch. If it is held to tests and comments, say so and prove it afterwards (the non-comment diff of
  `Ferazel/Core/Sources` over the fix round is empty). Comment edits in audited source files keep the line count.
- Reviewers write full findings to a scratch file **early, appending as they go**, and hand back a verdict; leg 2
  also writes a proposed-asserts patch and verifies it. Each leg builds in its own `mktemp` copy.
- **Check a card's numbers against the level data before briefing** (D56.1), or tell the implementer plainly that
  they are unchecked. Card file anchors (`:NNN`) are stale in every card of this wave; dump citations have been off
  by one several times. The data wins; the dump beats the card.
- **The audit test pins, per level, how often the held item is drawn under water with kind 0** (level 2: 39,
  level 18: 7, others 0) and a census of refusals per file (`SetupFaces.swift` `Error.notTranscribed` is 13 after
  run 66). A task that removes a refusal moves that count by a named, explained edit (D67.3).
- **A helper whose edit is refused as outside its fence** reports it; the seat rules and a fix round makes the
  change with the ruling in its brief (D54.1, D61.1, D62.1, D64.1, D67.3). The seat does not make the edit.
- **Pinned values.** Each card names what may change. Nothing else may move: the pictures and state pins of levels
  1–5, 10, 11, 15 and 18, the Windows level references, every fixture picture, the two chapter cards, the Chief's
  fight frames (111 / 1602 / 1710) and wake-up frames. A moved value the card does not name is a STOP.
- A picture's start point must actually show the feature (D51.1, D53.1), proven inside the test by a twin with the
  feature off (D54.2). A review leg's new asserts go inside the card's named tests (D51.2).
- After any commit that moves Core source or audit-test lines, run
  `python3 -I -B tools/ferazel/later-levels-ledger.py --check`; if stale, `--write`, check again, commit the ledger.
  Delete any `__pycache__` under `tools/ferazel/` and `docs/ferazel/tools/`.

## After this run
6A-PS (if not done), 6A-L21 "Obfuscation & Edification", 6A-CP (the magic carpet), 6A-L22 "The Labyrinth", the
phase end (6A-END: Proof B by day — watch `testBladeArmEndpoints` under Wine — both builds staged, one gate card)
and Ben's gate.

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
