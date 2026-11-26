STATUS: CONTINUE

# NEXT — Ferazel's Wand, run 72 part 2: Proof B, the phase review, both builds, the gate, then the archive

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
> 4. **Ben, 2026-11-26 (D73.4):** a session he starts runs whatever the weekly limit says. Read the limit
>    (`get_usage`) and say the figure, but do not stop for it.

You are the seat for **Ferazel's Wand** in Ambrosia Classics, repo `/Users/andiyar/Developer/Ambrosia-Classics`
(`$REPO`). Method: `~/Developer/Toolkits/fable-kit/orchestrator.md`. In your first message say which model you are
and, in one sentence, what you will do first; then start. **If a Coordinator or another session started you, its
overrides win over this file.**

**Work in the worktree `$REPO/.claude/worktrees/gracious-volhard-286877`** (branch `claude/gracious-volhard-286877`).
It is run 72's: main is at b7be967 (the chooser, pushed); the branch is ahead of main by the 6A card (4b06fc9) and
part 1's docs. Its `.build` folders are warm. If the app gives you a different worktree, do the work in that one
all the same (`git -C`), and remove both at the archive.

**Authority:** `docs/superpowers/plans/2026-11-04-ferazel-remainder.md` — `#### 6A-END`, `#### LC` and its "As
executed — LC" (part 1's gates, commands and times), "0. The verification model", as changed by the ruling above.

## Read first
1. `CLAUDE.md` (repo root); `docs/STATE.md` — the Ferazel block (its top bullets are part 1's close).
2. `docs/handoff-2026-11-27-ferazel-run72-part1.md`; `docs/DECISIONS.md` **D73**, D72, D70.5 (never ask to look at
   the game's window), D69.5, D59.1.
3. `docs/QUESTIONS.md` "Open" — act first on any new text under an `Answer:`.

## What part 1 finished (do not redo unless source changes)
The level chooser (L on the main menu), its two reviews and fix round; the relabel sweep; the 6A card's text in
both files with four `<<SEAT: …>>` placeholders; and every headless gate at b7be967: G2 823 (821 / 0 / 2), GW2 91
(89 / 0 / 2), G3, G5, GW1, GW3, GW4, the full sweep (11,864 visits, rows 0, both paths) and the bot (259,200
steps, failures 0, both paths). **These hold while no source file changes** (D69.5): a docs or card commit voids
nothing; a source fix voids the gates it touches.

## Before anything else
- **The time of day** (`date`). Steps 1, 4 and 5 below launch something: **09:00–21:00 only, muted, LAUNCH GUARD
  first.** If you are started at night: do step 2 (the review) and any fix round it needs, then **stop with one
  line saying the launches and the archive wait for 09:00** — do not stage, do not archive with boot checks owed.
  Ben or the parent session wakes you by day.
- **Your own context**: read the meter before every dispatch; cap 300k.
- `echo "$CLAUDE_CODE_DISABLE_BACKGROUND_TASKS"`: `1` = a foreground command is cut at ten minutes; suites in
  parts, the sweep a level group a command, the bot a shell a command; only Proof B may run detached (D59.1).
  One heavy command a message.

## This run, in order
1. **By day: Proof B** (`tools/windows/proof-b-ferazel.sh`, muted, detached allowed): expect **820 passed / 0
   failed / 3 skipped / 0 crashed (of 823)**. It has not run on the 59 tests added since run 64 — watch
   `testBladeArmEndpoints` (exact cos/sin under Wine) and `LevelChooserTests`' no-L digest (it hashes Swift's
   printed output; if Wine disagrees, the fix is a structural comparison, a tests-only round). Then **the Mac SDL
   smoke** (`tools/windows/smoke-ferazel-win.sh --mac-only`). A failure is a fix task before anything else.
2. **The Fable cross-check** (your one review; any hour): the whole 6A diff, Mac and Windows —
   `git diff e9183ce..HEAD` (e9183ce is the game code the last stages were built from, the Phase 5 end; confirm
   in `docs/STATE-history.md`) — and the card in both files. It is large: read it by area (`--stat` first, then
   the source folders one at a time; tests by name and count, not line by line). It also reads the small carry:
   the bot's two paths differ by one death and two exits on twelve levels (44 / 43, 387 / 385; equal on eleven).
   Opus implementers fix its findings; a fix that changes source re-runs the gates it voids.
3. **Fill the card's four placeholders** in both files (results of step 1 and, after step 4, of step 5; where the
   builds are; the commit). The staging scripts refuse while one remains, so fill the two start-up lines with what
   the checks will be and correct them if a check surprises you — or stage, check, then amend and re-stage; choose
   the cheaper and say which.
4. **Stage both builds** from the final commit (`tools/stage-ferazel.sh`, `tools/windows/stage-ferazel-win.sh`;
   GW5). The Mac app goes to `out/Ferazel/` and the Desktop; **the Windows zip and its `.sha256` are copied to
   `releases/<a new folder>/` in the MAIN checkout** — no GitHub release, no upload, no tag pushed.
5. **By day: G9M** (the staged Mac app boots muted) and **GW6** (the CrossOver smoke of the staged zip).
6. **The card goes to QUESTIONS** as a new item (the 6A gate, Mac and Windows) — it does not block the archive.
   Close Q19 and Q21 as "paused" (D72.1 (c)); leave Q18 open.
7. **Archive.** Rebuild this file as `STATUS: PAUSED` with a short "how to resume" (the next step would be the 6B
   planning run, P6B; what is staged and where; what is owed — Ben's Q18 and 6A gates, eyes on levels 20–22, the
   open carries in STATE, D73.3's unread item). STATE's Ferazel block: paused, why, where everything is; settled
   bits to the top of `docs/STATE-history.md`. Remove every Ferazel worktree and its DerivedData folder (STATE
   lists them; `git worktree list`; leave other projects' worktrees alone; if the app refuses a delete, say which
   and where). The handoff is the archive note. A memory note that Ferazel is paused and why. One LOOP-LOG line.
   Merge to main `--ff-only`, push. **Start no next session.**

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

## Close
"As executed" under the 6A-END card; any rulings as D74 (check it is free); then step 7. If the context cap or
the night rule stops you before the archive, rebuild this file for what is left and say so in one line.
