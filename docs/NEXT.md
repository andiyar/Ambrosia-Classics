STATUS: CONTINUE

# NEXT — Ferazel's Wand, run 72: the 6A phase end (6A-END), the level chooser, both builds, then the archive

> **Ben's ruling, 2026-11-26 — finish Phase 6A, then archive (this overrides the plan where they differ; D72.1).**
> The original author is selling an official remaster (https://mixedmetaphor.itch.io/ferazels-wand), so Ferazel
> stops at the 6A phase end. The project is paused, not cancelled: Ben resumes if the remaster disappoints.
> 1. **Run 71 is done:** 6A-L22 alone, merged; the ruling is recorded as D72.1.
> 2. **This run (72) = 6A-END, with three changes.**
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
and, in one sentence, what you will do first; then start. **If a Coordinator or another session started you, its
overrides win over this file.**

**Authority:** `docs/superpowers/plans/2026-11-04-ferazel-remainder.md` — the one plan, as changed by the ruling
above. This run's card: `#### 6A-END` in "Wave 5 — Phase 6A", with "The 6A gate card" outline, "0. The verification
model" (the gate table and its command block: GWB, GW4R, GW5, GW6, G9M, LAUNCH GUARD) and "Verification-model
additions for 6A". The model for gate times and commands is "As executed — 6A-L22" (run 71). Nothing else is a plan.

## Read first
1. `CLAUDE.md` (repo root).
2. `docs/STATE.md` — the Ferazel block: the live state. This chip holds no state.
3. `docs/QUESTIONS.md` "Open" — act first on any new text under an `Answer:` (Q18 is Ben's Phase 5 gate: notes
   become tasks at the head of the order; a fail stops the build).
4. `docs/DECISIONS.md` **D72** (run 71 and the ruling), D71, D70 (D70.5: never ask to look at the game's window),
   D69.5, D68.5, D59.1, D54, D51, and `docs/handoff-2026-11-26-ferazel-run71.md`.

## Before anything else
- **The weekly usage limit** (`get_usage`). Run 71 closed at **89% all models**, 71% Fable; the week resets on
  **2026-12-01 at 02:00 Sydney time**. Run 71 (one level task with its sweep and bot) cost 9 points. This run is
  bigger: a small build task with two reviews, the full sweep and bot again, Proof B, two stages and a Fable review
  of the whole phase — expect 20 to 30 points. **If the limit cannot hold it, do nothing:** say in one line that
  the run waits for the reset, leave this file as it is, and end. Do not start part of it and stall.
- **Your own context.** Read the meter before every dispatch. Cap 300k. Run 71 went from 116k at the start to
  199k when its gates were done. If the cap comes before the archive, close the step in flight, rebuild this file
  for the remainder (the ruling block carried whole) and start one more attended session; otherwise no next session.
- **How long one command may run.** `echo "$CLAUDE_CODE_DISABLE_BACKGROUND_TASKS"`: `1` means background work is
  off and a foreground command is cut off at ten minutes. Every suite runs in parts; the sweep one level group a
  command (**level 22 in two halves**: `FERAZEL_VISIT_OFFSETS=on,left`, then `right,above`, D72.4); the bot one
  command a shell. Only `tools/windows/proof-b-ferazel.sh` may run detached (D59.1).
- **One heavy command a message** (D70.6); chain parts only when their usual times sum under six minutes (D71.6).
- **The time of day** (`date`). Proof B, the Mac SDL smoke, the CrossOver smoke of the staged zip and the muted
  boot of the staged Mac app are **by day only (09:00–21:00), muted, LAUNCH GUARD first**. Start this run in the
  morning if you can choose. A launch is recorded as "started and stayed running"; never ask to look at the window.

## Reconcile first
- `git -C "$REPO" worktree list`, `git -C "$REPO" log --oneline -8 main`: main at or past run 71's close (db0e580
  plus its docs commits). Other sessions (Deimos, Castles) also merge to local main: merge main into your branch
  before each `--ff-only`, and check the next free D-number at the close (D73 unless another project took it).
- G1 HectorKit per the plan's gate table (main ef2c341, clean, at run 71). A worktree needs the untracked link
  `../HectorKit → ~/Developer/HectorKit` beside it, or `HECTORKIT_PATH=$HOME/Developer/HectorKit`.
- The suites' parts, their filters and run 71's times are in STATE's numbers table and "As executed — 6A-L22".
  After one `swift build --build-tests`, each part is `swift test --skip-build --filter …`. Each log ends with a
  second, empty bundle's "Executed 0 tests" — count the `Test Case … passed` lines. A wrong filter runs zero tests
  and still exits 0. This Mac has no `timeout` command. A small script that runs one part and prints only
  `passed / failed / skipped / exit / time` keeps each gate to one line of your context.
- G3, G5, GW1, GW3, GW4: the plan's §0 command block, from a `git archive` copy with a `HectorKit` link beside it
  and `-derivedDataPath` / `WIN_BUILD_ROOT` in the scratch folder.
- `rm -rf` on a path built from a shell variable is refused by the app unless written `"${S:?}/name"`; in zsh a
  glob that matches nothing aborts the whole command.

## This run, in order

1. **By day, first: what is owed from the wave.** Proof B (`tools/windows/proof-b-ferazel.sh`, muted, detached
   allowed): expect **813 passed / 0 failed / 3 skipped / 0 crashed (of 816)** at main. It has not run on the 52
   tests added since run 64 — watch `testBladeArmEndpoints` (exact cos/sin values under Wine). The Mac SDL smoke
   (`tools/windows/smoke-ferazel-win.sh --mac-only`). A failure is a fix task before anything else.
2. **Rule on the one unplanned reading** (STATE's run-68 carry, [MED]): what a level restart does to the touch
   areas of the other types that measure themselves from a cached picture. With the project pausing, the default is
   to leave it as a named open item in the archive note, not to build it. Say which you chose and why.
3. **The level chooser (task LC — new, from the ruling; write its card under 6A-END in the plan before briefing).**
   - What it is: a way inside the game, on Mac and on Windows, to start any built level without a command line.
     The list comes from `BuiltLevels.list` (never a second copy); the start goes through `GameFlow.startLevel`,
     as the `FerazelLevel` switch does. Read how that switch reaches `GameFlow` on both shells before choosing
     the shape. The seat picks the smallest shape that both shells share (for example a key on the main menu that
     opens a plain list) and records it as a ruling; it is a **named, listed departure from the original** on the
     gate card, and nothing of the original's screens or keys may change for a player who never uses it.
   - One `fk-implementer`, then two Opus review legs (spec, then quality with a mutation table, told what leg 1
     found), a fix round, the seat's own gates. Tests on both sides (Core / shared and WinKit); the ladder rises
     from 816 / 90 by the task's count, and Proof B's expected total rises with the Core count.
   - **Pinned values:** nothing existing may move — every level's pictures and state pins, the Windows references,
     the fixture pictures, the chapter cards, the main menu's reference pictures in both smoke checks. A moved
     value is a STOP.
   - It changes source, so **every gate run before it is void** (D69.5): run steps 4–6 after it is merged.
4. **The relabel sweep** (the card's point 2): no `// later:` in `Ferazel/Core/Sources` names a merged task; a
   comment-only commit, proven so. The engine contract §2.11 and the ledger's §9 line still call the carpet
   unbuilt (run 70's carry) — correct both.
5. **The gates at the final commit:** G1; G2 and GW2 in parts; G3; G5; GW1–GW4; then the full sweep and bot on
   twelve levels, both paths (GE) — every one green; **a non-zero exit stops the phase end** (each row becomes a
   fix task, nothing is staged). Summary lines go on the card and in LOOP-LOG.
6. **Stage both builds** (`tools/stage-ferazel.sh`, `tools/windows/stage-ferazel-win.sh`; GW5), then by day: the
   muted boot of the staged Mac app (G9M), the CrossOver smoke of the staged zip (GW6), Proof B at the staged head
   if the chooser moved Core. The Mac app goes to `out/Ferazel/` and the Desktop as before; **the Windows zip and
   its `.sha256` are copied to `releases/<a new folder>/` in the MAIN checkout** — no GitHub release, no upload,
   no tag pushed. Say on the card where both are.
7. **One gate card, two files** (`Ferazel/WHAT-TO-EXPECT.md`, `Ferazel/WINDOWS-WHAT-TO-EXPECT.md`), from the
   plan's outline, every point checked against the level data: what is new through the Goblin Chief, **how to use
   the level chooser**, the known deviations (number 7 the lit blade; add the full light table, D72.3; add the
   chooser as a departure), what nobody has seen yet (levels 20, 21, 22 — Ben's eyes), and the stand-ins.
8. **The Fable cross-check** (your one review): the whole 6A diff (`git diff <phase-start SHA>..HEAD`, Mac and
   Windows — the phase-start SHA is in the plan's 6A opening or STATE-history) and the card. It also reads run
   71's small carry: the bot's two paths differ by one death and two exits on twelve levels. Opus implementers
   fix its findings; a fix that changes source re-runs the gates it voids and re-stages.
9. **The card goes to QUESTIONS** as a new item (the 6A gate, Mac and Windows) — it does not block the archive.
   Close Q19 and Q21 as "paused" (D72.1 (c)); leave Q18 open.
10. **Archive.** Rebuild this file as `STATUS: PAUSED` with a short "how to resume" (the next step is the 6B
    planning run, P6B: the Wave 6 cards expanded as 6A's were; what is staged and where; what is owed — Ben's Q18
    and 6A gates, eyes on levels 20–22, the open carries in STATE). STATE's Ferazel block: paused, why, where
    everything is. Remove every Ferazel worktree and its DerivedData folder (STATE lists them; `git worktree list`;
    leave other projects' worktrees alone; if the app refuses a delete, say which and where). The handoff is the
    archive note. A memory note that Ferazel is paused and why. Push main. **Start no next session.**

## Binding rules
- Launch a build only **muted**, few and short, **never 21:00–09:00** — LAUNCH GUARD first. Headless work any hour.
- Game data and dumps are read-only: never edit `Resources/Ferazel/` or `ghidra/ferazel/`.
- Subagents: `fk-implementer` / `fk-reviewer`, **no `model` parameter** (Opus 5.5). Tell every helper: foreground
  only, the ten-minute cut, the audit only by level group and one test a command, commit before reporting, delete
  every copy and log before reporting, never launch the game. An implementer's brief names its co-author line
  (`Claude Opus 5.5`). Reviewers write findings to a scratch file early and build in their own `mktemp` copy.
- A helper whose edit is refused as outside its fence reports it; the seat rules and a fix round makes the change.
  The seat does not make the edit. A fix round held to tests and comments is proven so by the empty source diff.
- Memory: at most 4 workers; never two heavy things at once; a sweep or bot is stopped with a plain
  `kill <script pid>` (never `-9`), the outer shell too; the 4 GB per-worker limit is never raised.
- Disk: delete every copy, build folder and log as soon as its check has passed; remove your worktree at the close.
- After any commit that moves Core source or audit-test lines, run
  `python3 -I -B tools/ferazel/later-levels-ledger.py --check`; if stale, `--write`, check again, commit the ledger.
- Never wait silently. Dump beats bank beats plan. Explicit-path commits, no `git stash`,
  `git branch --show-current` before each commit.

## Close (in this order)
1. Merge to local main `--ff-only` by SHA after each verified step.
2. "As executed" under the 6A-END card and the chooser's card; rulings in `docs/DECISIONS.md` under the next free
   number.
3. `docs/STATE.md`: the Ferazel block replaced with the paused state only; settled bits to the top of
   `docs/STATE-history.md`. One line in `docs/LOOP-LOG.md`. The handoff (the archive note) with the real start and
   end times from `date`.
4. This file rebuilt as `STATUS: PAUSED` (step 10 above).
5. Push main. No next session — unless the context cap forced a split (then one more attended session, as above).
