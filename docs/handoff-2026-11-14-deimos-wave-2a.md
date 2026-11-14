# Handoff — 2026-11-14 — Deimos Rising: wave 2a done (fix round, merge, bank notes); next = wave 2b

## Brief for the next session

Everything below this brief is the record of wave 2a. The live state is `docs/STATE.md` (the Deimos block).

```
You are the ORCHESTRATOR for Deimos Rising (Ambrosia Classics), wave 2b of the remainder plan: Task 2.4 (C12 —
the entity update, the world update, the entity draw) and then Task 2.5 (C18a — DeimosSession Phase 2: the loop,
film playback, pause). Both are MAJOR, each alone in its wave, one after the other.
Repo "/Users/andiyar/Developer/Ambrosia-Classics". Method ~/Developer/Toolkits/fable-kit/orchestrator.md
(§0, §2 loop, §5 cap, §6 model policy). The seat model follows Ben's orchestrator rules, not this brief; say which
model you are in your first message, echo the mission in one sentence, say what you do first, start.

AUTHORITY: docs/superpowers/plans/2026-11-05-deimos-remainder.md on main, and nothing else. Read its headings
"Verification model (read first)" (incl. "Standing rules for every implementer" and "Phase-2 stand-ins") and
"Wave 2b" (Tasks 2.4, 2.5, "Close of wave 2b"). The cards are complete there; do not open older plans,
hand-overs or the audit.

READ FIRST: CLAUDE.md; docs/STATE.md (the Deimos block: grep -n -i deimos); this brief; the plan headings above.

WHERE: your own session worktree, cut from main (confirm `git merge-base --is-ancestor <main tip> HEAD`; if it
is behind, `git merge --ff-only main` inside the worktree). The plan's code block names an old worktree path in
WT=...: use your own worktree path instead. An edit hook refuses writes to the main checkout from a worktree
session, so every file you or your agents change — docs included — is changed in YOUR worktree and reaches main
by merge. Task commits land on your session branch; at the close of each task (all legs merged and green) merge
your branch --no-ff into LOCAL main from the main checkout (`git -C <main checkout> merge --no-ff <branch>`),
then re-run the gates there. Never push.

TASKS (per task: one fk-implementer, then TWO fk-reviewer legs — spec, then quality, the second checking the
first; reviewers run the tests on their own scratch path, try mutants in a private `cp -R` copy of Deimos/Core
with HECTORKIT_PATH=/Users/andiyar/Developer/HectorKit and DEIMOS_DATA set, and re-read the listing addresses):
 2.4 C12 -> G2 327/0/0.   2.5 C18a -> G2 335/0/0.   Copy commands from the plan's code block.

GATES, as measured on 2026-11-14 at main after wave 2a:
 G1 HectorKit zero-skip at kit main ef2c341: 370 executed (366 passed + 4 Aki 1.1 skips — a machine data path;
    record it, never "fix" it here). `tail -n 1` of the script prints a skip line, not a total: count the
    `^Test Case` lines in the log (passed / failed / skipped).
 G2 Deimos/Core without DeimosReplayTests: 318/0/0 now -> 327 after 2.4 -> 335 after 2.5
 G3 data-census.md body unchanged; G5 Deimos, Aki, BubbleTroubleX `** BUILD SUCCEEDED **` (grep the line —
    `tail -n 1` prints an empty line); G6 scope fence; G7 layering grep empty; G10 clean tree; G11 bounded tests.

CARRIED FROM WAVE 2A (act on these inside the cards, do not open a side task):
 - Bank note row 44 was corrected in review: with no player, a FLEEING unit keeps its flee point (the branch at
   1001535c / 10015380 exits before the store at 100153c8/d0); only a non-fleeing unit stores (0, 0). Read the
   "Swift check for row 44" line in the record below before C12 touches the motion controller.
 - Plan card dump-line numbers for the tallies are off against the committed dump (real lines: tally function
   4679–4896; coin tally 23482 / 23493 / 23536–39). Find functions by `// ==== FUN_xxxxxxxx @`, not by line.
 - `Player.sector` got one more reader (PlayerPhase1, the not-level-start path, value unused); C18a retires the
   field as its card says.

BINDING RULES (each has bitten on this repo):
 - Every subagent is Opus 5.5: dispatch fk-implementer / fk-reviewer and OMIT the Agent `model` param.
 - Cap: 300k of your own context; read `get_usage` before each dispatch and at the close and say the figure;
   start closing at ~240k. If the cap nears mid-wave, finish the task in flight, write the handoff, and START
   THE NEXT SESSION with the remainder (Ben, 2026-11-14: "when you run out of context, trigger the next session
   and keep on … until you reach a hard stop that needs input").
 - Never push (Ben pushes). Merging your own branch to LOCAL main is authorised at each task close.
 - Never git stash, reset or switch branches; never git add -A; explicit paths; trailer on every commit.
 - No app launches (G5 builds only; a launch opens a window and sound — Ben's say-so only).
 - At most four heavy processes at once (swift test / xcodebuild); other projects' sessions also run tests on
   this Mac — check `pgrep -fl "swift-test|xcodebuild"` and memory before a parallel fan-out.
 - Never patch HectorKit from this lane. Never touch Cythera or Ferazel files or their worktrees. Ferazel
   sessions write docs/STATE.md, docs/NEXT.md and docs/DECISIONS.md on main: edit only the Deimos block of STATE
   and the Deimos entries of DECISIONS, never docs/NEXT.md, and commit only your own paths.
 - Research data and dumps are read-only (ghidra/deimos/Deimos_pef.decompiled.c, ghidra/deimos-proj/
   disasm-review3-all.txt). No implementer edits docs/deimos/*; bank corrections found go in the report and are
   appended at the Phase 2 close (the A4 card).

CLOSE: STATE (the Deimos block, numbers as you measured them); DECISIONS as-built lines under D31 (the plan's
"Close of wave 2b"); memory file + index line; a new handoff whose brief for Wave 3 (C18b ∥ H2 first, then H3 ∥
A3, F1 if the replay gate is red, A4) is built the same way from the plan's "Wave 3" heading; then START THE
NEXT SESSION YOURSELF and keep the chain going wave after wave. Stop only at a hard stop that needs Ben: a
question only he can answer, a launch that needs his say-so (A4's boot check), or his "level 1 plays" gate.
Closing message to Ben in plain English: what landed, the numbers before and after in a short table, what
review caught, what is next.
```

## Record — wave 2a (2026-11-14; Fable 5.2 in the seat, Opus 5.5 implementers and reviewers)

**What happened.** Ben said "go Deimos". The old branch worktree was gone (2026-11-08 disk cleanup), so the session
worktree `deimos-wave-2a-953a07` (branch `claude/deimos-wave-2a-953a07`, cut from `deimos-phase2` 55cb145) stood in
for it. All three tasks closed; nothing pushed.

| Gate | Before | After |
|---|---|---|
| HectorKit (ef2c341) | 370 executed (366 + 4 skips) | unchanged |
| Deimos/Core (no replay bundle) | 313 / 0 / 0 | 318 / 0 / 0 (branch tip, merge head, and after the notes) |
| Census file body | — | unchanged |
| Deimos, Aki, BubbleTroubleX builds | — | three succeeded |
| Bank correction markers | 0 | 53 |

**Task 2.1 — fix round.** Commits a49c920 (world/motion/state, +2), 72787a8 (audio/level-end/seams, +2), 50a4249
(combat/player/weapons, +1), 9fd798c (review round: comment wording, test hardening; no behaviour change). Two
review legs per family; all passed. Review caught: comments that contradicted the listing (the weapon reset "always
reads" the sector — it reads it only at level start; "five" spawn templates where the binary has seven; the
`consuming` mixer comment overstated what Swift enforces); two address typos in a test comment; a test line that
would crash instead of fail; an unasserted claim in a test. Five mutants were run by reviewers in private copies;
every one was caught by the new or strengthened tests. Known and accepted: the free-hint default of 0 cannot be
observed by a test (the world's init already resets it); the "data byte" comment the card asked for was already
correct since e0736fc. Callers of the weapon reset outside the card's file list were touched for the one new
argument only (PlayerLife, PlayerPhase1, WeaponTests); two comment-only touches outside the list (SpawnRequest,
Console) came from review.

**Task 2.2 — merge.** 91982ac on local main (`--no-ff`). Conflicts as expected: `docs/STATE.md` (main's kept whole —
the file was restructured since October) and `docs/DECISIONS.md` (D31 placed between D30 and D32). Local branch
`deimos-phase2` deleted; `origin/deimos-phase2` left for Ben. The merge was committed before the merge-head gates
ran (other sessions commit on main; an open merge state is a hazard) — the gates then passed.

**Task 2.3 — bank corrections.** bc46291 (53 notes, one INDEX ledger row each) plus the review-fix commit 77543c9. Two reviewers split the rows 1–27 / 28–53 and opened every cited address.
Rows 1–27: none wrong. Rows 28–53: row 44 was wrong as the plan worded it (corrected, see the brief); row 29
misleading (same bytes as the existing table, reworded); rows 39, 46, 49 tightened; three plan dump-line numbers
were off (the notes cite the real lines). Not independently confirmed, left marked as such in the notes or here:
row 8's le07 count, row 19's "every id is among the 96", row 20's "dead in shipped data", row 24's up-arrow and
FPS-clip clauses, row 31 at speeds 0.75 and 7.0 (a re-derivation gave 39 and 47 against the bank's 35 and 41 —
libm-dependent), row 46's uninitialised-stack reading, the PERM clauses of rows 32 and 35.

**Deviations from the brief, stated.** The brief asked for one review leg per task; the 2026-11-08 house rule asks
for two. Task 2.1 got two legs per family (spec, then quality checking the first). Task 2.3 got two reviewers
covering disjoint halves (full coverage of all 53, but not a second look at the same rows). The Task 2.3 agents
wrote `docs/deimos/` directly in the main checkout (subagents are not bound by the worktree edit hook); later
sessions should keep all edits in their own worktree.

**Swift check for row 44.** The fix implementer read the replica: `Units/Motion.swift:82–96` already matches the listing (the flee and
delete exits leave before the target store). Its corrected note goes further than the reviewer asked: on the
fall-through the nearest-player routine writes the (0, 0) default and then overwrites it from uninitialised stack
(`10005e68..84`). That last clause was written after the review legs and has **not** been re-checked by a reviewer —
C12's review legs should open `10005e68..84` when they reach the motion controller.

**Follow-ups, not done here.** No Deimos listing is committed (`ghidra/deimos-proj` is a symlink to
`~/Developer/Ghidra/`); the sound-library addresses cited in bank notes 9, 10, 13–16 appear in no listing on disk,
only in the decompile. `docs/STATE.md` line ~57 (another game's block) still names the removed `inspiring-cannon`
worktree as Ben's.
