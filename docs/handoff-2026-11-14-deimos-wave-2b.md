# Handoff — 2026-11-14 — Deimos Rising: wave 2b done (per-tick update, Phase 2 session); next = wave 3

## Brief for the next session

Everything below this brief is the record of wave 2b. The live state is `docs/STATE.md` (the Deimos block).

```
You are the ORCHESTRATOR for Deimos Rising (Ambrosia Classics), wave 3 of the remainder plan — the rest of
Phase 2: C18b ∥ H2 first, then H3 ∥ A3, F1 only if the replay gate is red, then A4 (stage + gate card).
Repo "/Users/andiyar/Developer/Ambrosia-Classics". Method ~/Developer/Toolkits/fable-kit/orchestrator.md
(§0, §2 loop, §5 cap, §6 model policy). The seat model follows Ben's orchestrator rules, not this brief; say which
model you are in your first message, echo the mission in one sentence, say what you do first, start.

AUTHORITY: docs/superpowers/plans/2026-11-05-deimos-remainder.md on main, and nothing else. Read its headings
"Verification model (read first)" (incl. "G4 — the replay gate, and the miss path", "Standing rules for every
implementer", "Phase-2 stand-ins" — stand-ins 5 and 8 were corrected on 2026-11-14) and "Wave 3 — the rest of
Phase 2" (cards C18b, H2, H3, A3, F1, A4). The cards are complete there; do not open older plans or the audit.

READ FIRST: CLAUDE.md; docs/STATE.md (the Deimos block: grep -n -i deimos); this brief; the plan headings above;
the "As built — wave 2b" paragraph in docs/DECISIONS.md (grep -n "As built — wave 2b").

WHERE: your own session worktree, cut from LOCAL main (confirm `git merge-base --is-ancestor <main tip> HEAD`; if
it is behind, `git merge --ff-only main` inside the worktree — a new worktree is often cut from an old commit).
The plan's code block names an old worktree path in WT=...: use your own worktree path. An edit hook refuses
writes to the main checkout from a worktree session, so every file you or your agents change — docs included —
is changed in YOUR worktree and reaches main by merge (`git -C <main checkout> merge --no-ff <branch>`) at each
task close, gates re-run at the merge head. Never push.

ORDER AND SHARED FILES: C18b ∥ H2 may run at the same time ONLY if they cannot collide: both touch tests that use
`TestWorld`, and Package.swift belongs to H2 then H3, EntityDraw.swift to C18b, project.yml to A3. Two
implementers in one worktree commit on one branch — give each an explicit file list and explicit-path commits,
or run them one after the other if in doubt. H3 after H2 (Package.swift). A3 after H2.

TASKS (per task: one fk-implementer, then TWO fk-reviewer legs — spec, then quality, the second checking the
first — for every task, MAJOR or minor (house rule 2026-11-08; the cards' "one review leg" is superseded);
reviewers run the tests on their own scratch path, try mutants in a private `cp -R` copy of Deimos/Core with
HECTORKIT_PATH=/Users/andiyar/Developer/HectorKit and DEIMOS_DATA set, and re-read the listing addresses):
 C18b -> G2 336/0/0.   H2 -> G2 344/0/0.   H3 -> G2 stays 344; G4 = DeimosReplayTests 3/0 and the CLI line.
 A3 -> no tests; G5 builds.   A4 -> stage, gate card, late bank notes; its boot check (G9) opens a window.

GATES, as measured on 2026-11-14 at main after wave 2b (merge head 28194b9 + the docs close):
 G1 HectorKit zero-skip at kit main ef2c341: 370 executed (366 passed + 4 Aki 1.1 skips — a machine data path;
    record it, never "fix" it here). Count the `^Test Case` lines in the log (passed / failed / skipped).
 G2 Deimos/Core without DeimosReplayTests: 335/0/0 now -> 336 (C18b) -> 344 (H2).
 G3 data-census.md body unchanged; G5 Deimos, Aki, BubbleTroubleX `** BUILD SUCCEEDED **` (grep the line);
 G6 scope fence; G7 layering grep empty (add Sources/deimos-replay from H3 on); G10 clean tree; G11 bounded tests.
 G4 (from H3): never edit the expectation; a red gate follows the plan's miss path (H3 still merges with the
    gate "pending trace" in STATE, and you open F1).

CARRIED FROM WAVE 2B (act on these inside the cards, do not open a side task):
 - H2 owns the pause wait. Today the driver steps `.pauseWait` as a no-op (DeimosDriver.swift, marked "H2 builds
   the real pause wait"); with Caps Lock held the pause re-fires every pass (the pause screen clears the latch,
   the next begin frame sets it again) — H2 must close both. A pass that both pauses and ends the session carries
   pause -> resume -> stop with the pause's halt index kept, but `PassOutput` holds one halt, so the
   end-of-session halt after the wait (10005ad8) is missing on that pass, and resume/stop reach audio before the
   wait; H2 finishes it. H2's review legs re-read 10022f24..10022fb4 and 10005ac4..10005ae4 for this.
 - A film is NOT ended by keys (FUN_10048e60 = mouse button only). It ends when it runs out, on Esc, on level
   complete or game over. A3's `-film deNN` argument and A4's gate card must say that, not "any key".
 - As built by C12 / C18a: `updateWorld` takes `inputWithheld`; `groupCommands` is a GameState method;
   `playerCommands` takes `coinTally:` and `text:` (omitting `text:` silently drops the coin-tally text);
   `Player.sector` and `scoreBarIcons()` are gone (one source: `flags.sector`); `PlayerPhase1` passes an unread
   `sector: 0` until C18b deletes the file; `HeadlessRun.init(film:)` exists and is unused until H2.
 - An input-less player dies: lives lost at passes 443 / 760 / 1022, out of the game at 1084, session ends 1195.
   Any Phase-2 test that needs the level to run long must feed inputs or a film.
 - For A4's late bank notes (seat-run): no bank corrections were reported by C12 or C18a, but these plan/bank
   wordings were wrong and should get a note where the bank repeats them: "any key ends a film" (bank §7);
   "rule #17" (17 rules are numbered 0–16); the level-start order (scroll start 100067ec before the entity reset
   inside FUN_10032e60 at 100067f8; FrameKeys.startSession in the set-up, 100056ac); arming a spawn set draws
   R(DelayMin, DelayMax), not a fixed 0; the float at 0x100d6354 is 0.0; FUN_100475e0's second argument is
   allowMultiple.
 - Find functions in the dump by `// ==== FUN_xxxxxxxx @`, never by a card's line number.

BINDING RULES (each has bitten on this repo):
 - Every subagent is Opus 5.5: dispatch fk-implementer / fk-reviewer and OMIT the Agent `model` param.
 - Cap: 300k of your own context; read `get_usage` before each dispatch and at the close and say the figure. The
   required reading alone costs about 130k, and one MAJOR task with its legs and fix rounds about 35k, so start
   closing at ~240k: finish the task in flight, write the handoff, and START THE NEXT SESSION with the remainder
   (Ben, 2026-11-14: "when you run out of context, trigger the next session and keep on … until you reach a hard
   stop that needs input").
 - Tell every agent: fix rounds strengthen existing tests and keep the ladder count; an unexpected number is a
   STOP, never an edited expectation; one heavy process at a time, foreground, none left running at the report.
 - Never push (Ben pushes). Merging your own branch to LOCAL main is authorised at each task close.
 - Never git stash, reset or switch branches; never git add -A; explicit paths; trailer on every commit.
 - No app launches. A4's boot check (G9) opens a window and sound: it needs Ben's say-so — that is a hard stop;
   do everything else in A4 first, then ask him.
 - At most four heavy processes at once (swift test / xcodebuild); other projects' sessions also run tests on
   this Mac — check `pgrep -fl "swift-test|swift-build|xcodebuild"` and memory before a parallel fan-out.
 - Never patch HectorKit from this lane. Never touch Cythera or Ferazel files or their worktrees. Ferazel
   sessions write docs/STATE.md, docs/NEXT.md and docs/DECISIONS.md on main: edit only the Deimos block of STATE
   and the Deimos entries of DECISIONS, never docs/NEXT.md, and commit only your own paths.
 - Research data and dumps are read-only. No implementer edits docs/deimos/*; A4's late notes are seat-run.

CLOSE: STATE (the Deimos block, numbers as you measured them); DECISIONS as-built lines under the wave 2b
paragraph; memory file + index line; a new handoff built the same way for whatever remains (or, when A4 is
staged, the "level 1 plays" gate card for Ben); then START THE NEXT SESSION YOURSELF if work remains. Stop only
at a hard stop that needs Ben: a question only he can answer, A4's boot check, or his "level 1 plays" gate.
Closing message to Ben in plain English: what landed, the numbers before and after in a short table, what
review caught, what is next.
```

## Record — wave 2b (2026-11-14; Fable 5.2 in the seat, Opus 5.5 implementers and reviewers)

**What happened.** Both tasks closed and are merged into local main (nothing pushed). The core can now run a whole
level tick by tick in the original's order, play a demo film and pause; the app is not wired to it yet (wave 3).

| Gate | Before | After |
|---|---|---|
| HectorKit (ef2c341) | 370 executed (366 + 4 skips) | unchanged |
| Deimos/Core (no replay bundle) | 318 / 0 / 0 | 327 after Task 2.4, 335 after Task 2.5 |
| Census file body | — | unchanged |
| Deimos, Aki, BubbleTroubleX builds | — | three succeeded after each task |

**Task 2.4 — C12.** 8f3852b, review rounds eb9370d and 7755fb9, merge bcddbe6. Both review legs found the code
matching the listing at every step re-derived (step order, crosshair lock, both scroll-pausing controllers, the
world-update order, the reset keep-list, the coin-tally text, the nearest-player routine incl. `10005e68..84`).
Review caught missing tests only: five mutants survived at first (pre-controller state, blur draw order, player 2's
crosshair lock, the spawn-in re-stamp, plus an end-of-tick position that the test read from data instead of the
running game). Three are now pinned; two cannot be observed on shipped data and are guarded by census asserts
(see DECISIONS, as built wave 2b, item 4).

**Task 2.5 — C18a.** e64a1a2, review rounds acffd81 and 560f68c, merge 28194b9. Both legs agree the code follows
1.0.6 and the plan card was wrong in three places (what ends a film; where `startSession` runs; the level-start
order). Review caught: no test pinned "keys do not end a film"; Caps Lock would have crashed the app through the
driver until H2 (now a no-op); two frame checks silently repeated the game-over frame (now explicit); wrong
addresses in comments; a pause-and-quit pass dropped the music resume (fixed; one halt still missing, H2). Ten
reviewer mutants on the session were run; nine were caught at first, the tenth after the fix round. Leg 2
re-derived four frame checks (passes 56, 72, 600, 1195) with its own loop and a partial compositor: no bad pixel.

**Not independently confirmed.** The pan-240 frame check; pixels under translucent or scaled sprites and the score
bar in the frame checks (`coverRect` ignores scale > 1, up to about 2 px at pass 600); that the volume keys emit no
music cue (read, not tested); the last fix round (560f68c) had no second review leg — H2's legs re-read it.

**Follow-ups, not done here.** Stale comments outside the cards (`ScrollState.swift:79` "Phase 2",
`Removal.swift:59` naming); `MotionBlurPool.emit` copies +0x90 where the original does not, and blurs of
terrain-drawing objects go through `EntityDraw.entry` (neither reachable in shipped data); `docs/STATE.md` line ~57
(another game's block) still names the removed `inspiring-cannon` worktree.
