# Handoff — 2026-11-14 — Deimos Rising: wave 3 done (Phase 2 built and staged); next = the Phase 3 plan

## Brief for the next session

Everything below this brief is the record of wave 3. The live state is `docs/STATE.md` (the Deimos block).

```
You are the ORCHESTRATOR / PLANNER for Deimos Rising (Ambrosia Classics): write the Phase 3 plan — the campaign
(levels 2–12, level transitions, carry-over, two players, the finale, the film gates, staging) — as its own plan.
Repo "/Users/andiyar/Developer/Ambrosia-Classics". Method ~/Developer/Toolkits/fable-kit/orchestrator.md (§0, §5
cap, §6 model policy) and the house planning rules (plans carry contracts, not code; a phase plan is written by
the Fable seat; say which model you are in your first message, echo the mission in one sentence, start).

WHAT EXISTS: Phase 2 ("level 1 plays") is built, merged to LOCAL main (not pushed — Ben pushes) and staged on
Ben's Desktop with its gate page. Ben's "level 1 plays" verdict and a muted boot check are QUEUED for him; they do
not block planning. If his verdict has arrived (STATE, DECISIONS, or a message), read it first: notes from his
gate become the first wave of your plan.

READ FIRST: CLAUDE.md; docs/STATE.md (grep -n -i deimos); this brief; in
docs/superpowers/plans/2026-11-05-deimos-remainder.md the headings "Verification model (read first)" (gates,
standing rules, stand-ins) and "Phase 3 — the campaign (cards for its own plan)"; the design
docs/superpowers/specs/2026-11-05-deimos-remainder-design.md (by section heading, only what the cards cite);
"As built — wave 3" in docs/DECISIONS.md (grep -n "As built — wave 3"). Bank files only as a card names them
(level-scroll-objects.md §8, loose-ends-session.md §5.3). Never whole code files: ground by grep.

DELIVERABLE: docs/superpowers/plans/2026-11-14-deimos-phase3.md — self-contained, in the remainder plan's shape:
verification model + gates with expected numbers, a test ladder from Deimos/Core 344 and DeimosReplayTests 4,
waves with cards (Files, Contract, Tests by name, Gate, Commit), parallel-safety notes, the gate-3 card for Ben.
Ground every card in the listing/bank before writing it (dispatch fk-reviewer legs, no `model` param, as
read-only researchers for address ranges if you need them); have the finished plan reviewed by TWO fk-reviewer
legs (spec vs the cards and the design; then a data-reality leg that checks the plan's claims against the
decompile and the level data) and fix what they find. Record the plan in DECISIONS (a new D-number confirmed
against main at commit) and the Deimos block of STATE.

FACTS THE PLAN MUST BUILD ON (measured 2026-11-14):
 - Gates at main after wave 3: G1 HectorKit ef2c341 370 executed (366 + 4 Aki 1.1 skips — record, never fix
   here); G2 Deimos/Core without DeimosReplayTests 344/0/0; G4 DeimosReplayTests 4/0 and
   `deimos-replay --all` four PASS lines, exit 0; G5 Deimos, Aki, BubbleTroubleX build; G7 layering grep empty
   incl. Sources/deimos-replay.
 - Card P3.5 is ALREADY DONE: de02 116,180 @ 8,357, de03 57,520 @ 10,058, de04 24,670 @ 5,649 are asserted
   (`testDemos02To04ReachTheirStoredScores`). So levels le06, le02, le08 (sectors 2, 3, 4) already run headless
   to the films' ends with the right scores — single levels started from a film, not reached by a transition.
   The plan should say what that does and does not prove for P3.1/P3.2.
 - A film that ends restarts the same film in the app (stand-in until Phase 4). de01's score freezes 43 reads
   before its last byte; no film witnesses the mid-tick score-capture instant or an extra-life threshold moved by
   5,000 (unit tests must).
 - The game runs one tick per pass at 30 passes a second on the OS X rate.
 - Not modelled until Phase 4: the mouse button ending a film; the quit flag inside the Caps Lock wait.
 - Follow-ups a Phase 3 card may absorb: the film lookup by tag is written four times (deimos-replay main.swift,
   ReplayTestData.swift, ReplayHarnessTests.swift, App DeimosController.swift) and belongs in DeimosHost or Core;
   a failed `--frames` write can hide a film's result line; `HeadlessRunner.reason()` traps on an end no rule
   explains (level transitions add new ends — P3.1 must revisit it).
 - Find functions in the dump by `// ==== FUN_xxxxxxxx @`, never by line number. The listing is
   /Users/andiyar/Developer/Ghidra/deimos/proj/disasm-review3-all.txt (not in the worktree).

BINDING RULES (each has bitten on this repo):
 - Your own session worktree, cut from LOCAL main: confirm `git merge-base --is-ancestor <main tip> HEAD`, else
   `git merge --ff-only main` first. An edit hook refuses writes to the main checkout: edit in your worktree and
   merge with `git -C /Users/andiyar/Developer/Ambrosia-Classics merge --no-ff <branch>`. Never push.
 - Every subagent is fk-implementer / fk-reviewer with NO `model` param. Cap: 300k of your own context unless
   Ben sets another figure in the session; read `get_usage` before each dispatch and at the close.
 - Machine load: at most four heavy processes in total; count with
   `pgrep -x "swift-test|swift-build|xcodebuild" | wc -l` (`pgrep -fl` over-counts wrapper shells and reported a
   false 15 in wave 3). A planning session should need almost none.
 - No app launches. Never git stash / reset / switch branches; explicit-path commits; trailer on every commit.
 - Ferazel sessions write docs/STATE.md, docs/NEXT.md, docs/DECISIONS.md on main: edit only Deimos's block and
   entries, never docs/NEXT.md. Research data and dumps are read-only.
 - Messages to Ben in plain English: what happened before part names; numbers in a short table.

CLOSE: the plan merged to local main; STATE + DECISIONS; memory file + index line; a handoff whose brief runs
Phase 3's first wave; then START THE NEXT SESSION YOURSELF (Ben, 2026-11-14: sessions chain until a hard stop
that needs him). Hard stops: a question only Ben can answer; anything that launches the app.
```

## Record — wave 3 (2026-11-14; Fable 5.2 in the seat, Opus 5.5 implementers and reviewers; cap set to 500k by Ben)

**What happened.** The rest of Phase 2 is built, merged into local main (nothing pushed) and staged. The app plays
level 1 with sound; the machine check — replaying the game's own demo films — passed at the first run, so the
replay triage task was never opened.

| Check | Before | After |
|---|---|---|
| Deimos core tests | 335 / 0 / 0 | 344 / 0 / 0 |
| Demo-film replay tests | none | 4 / 0 (all four shipped films) |
| HectorKit (ef2c341) | 370 executed (366 + 4 skips) | unchanged |
| Census file body | — | unchanged |
| Deimos, Aki, BubbleTroubleX builds | — | all three succeed |

| Demo film | Recorded score | Ours |
|---|---|---|
| de01 (level 1) | 25,050 | 25,050 |
| de02 (sector 2) | 116,180 | 116,180 |
| de03 (sector 3) | 57,520 | 57,520 |
| de04 (sector 4) | 24,670 | 24,670 |

**Tasks.** Stub removal and the early film report: 84ac96b, fix e1fe3b6. Host driver, headless runner, replay,
trace: 626ce91, fix cf72ebe; both merged as 3570cc3. Replay tool and gate: 0db6216, fix 3b8c4d1. App wiring:
5fa5445, fixes f98105e and d3a46bc. Gate page: 8e1dda7, fixes fdee6d0, b677675, 644865e. Bank notes 2d79551. Merged
as 05083af. Staged with `tools/stage-deimos.sh` at 22:28 (Release build; nothing launched).

**What review caught.**
- An old test expected the ship not to move on the tick it becomes active — true only of the deleted stand-in.
  The listing shows the original reads input that same tick; the test now pins both cases.
- The new early-film test checked a position on a copy of the game, so a bug in the real run survived; it now
  compares the whole world.
- The replay runner called any unexplained ending "film ended"; fixed.
- The first demo film alone cannot see a multiplier bug or a lost extra life. The other three are now real checks
  (a seat ruling beyond the plan's card; the card is corrected).
- The replay tool could print PASS on a run that hit its safety bound, and a failed trace write hid the result.
- The app dropped keys the original console would have received; it opened the sound device before decoding; it
  left the stream attached at quit; it froze effects in the background where the original pauses only music.
- The gate page said an idle ship dies in 17 seconds (it is 34 — the seat's brief was wrong), gave a film
  command that does nothing if the app is open, and asked Ben a question the original already answers.
- The seat's own load counter over-counted other projects' jobs (15 for 3), which blocked one reviewer's mutants
  for 45 minutes; corrected, and the mutants were then run in the fix round.

**Not independently confirmed.** Sound reaching the speakers (an offline probe of the same audio graph pulled the
stream correctly; no session launched the app); A3's 30-second launch check and A4's boot check (both need Ben's
say-so); the mid-tick score-capture instant (the listing only); "about 61 s in" on gate-card line 2.

**The deferred muted boot check, when Ben says so** (daytime, system output muted): Debug build with
`-debugCapsLock 20` — within 30 s the log shows frames rendered rising about 44,100 a second and cues rising; Caps
Lock DOWN then "pause routed"; 4 s later UP then "resume routed". Switch away: music pauses, effects finish; come
back: music resumes. `-film de01`: REPLAY banner, no level music. `-film zz99`: quits at once. Release build
(`~/Desktop/Deimos Rising.app`): opens, no debug lines, clean quit, no crash report. Unmute afterwards.

**Follow-ups, not done here.** Listed in STATE (the Deimos block, "Open").
