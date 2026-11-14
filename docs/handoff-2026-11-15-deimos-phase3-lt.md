# Handoff — 2026-11-15 — Deimos Rising: Phase 3 planned, the level transition built; next = carry-over, two players, the finale

## Brief for the next session

Everything below this brief is the record. The live state is `docs/STATE.md` (the Deimos block).

```
You are the ORCHESTRATOR for Deimos Rising (Ambrosia Classics), Phase 3 (the campaign), from task CR onward:
CR -> TP -> FN (wave 3.2), then CS -> AP (wave 3.3), then ST (stage + gate-3 card).
Repo "/Users/andiyar/Developer/Ambrosia-Classics". Method ~/Developer/Toolkits/fable-kit/orchestrator.md (§0, §2
loop, §5 cap, §6 model policy). Say which model you are in your first message, echo the mission in one sentence,
say what you do first, start.

AUTHORITY: docs/superpowers/plans/2026-11-14-deimos-phase3.md on main (D50), with its two grounding appendices in
the same folder (A = transitions + carry/reset + Swift seams; B = two players, finale, sectors 2–12, the sweep,
the app). Read the plan whole (it is short) — the gates table, the rulings, "Corrections to the appendices" (it
WINS over the appendices), the waves, and the cards. From docs/superpowers/plans/2026-11-05-deimos-remainder.md
read only "Standing rules for every implementer" and the gates code block. Task LT is DONE and merged.

READ FIRST: CLAUDE.md; docs/STATE.md (grep -n -i deimos); this brief; the plan; "As built — Phase 3" in
docs/DECISIONS.md (grep -n "As built — Phase 3"). Appendices: hand the relevant sections to agents; read them
yourself only where a ruling needs it.

WHERE: your own session worktree, cut from LOCAL main (confirm `git merge-base --is-ancestor <main tip> HEAD`;
if behind, `git merge --ff-only main` in the worktree). An edit hook refuses writes to the main checkout: edit in
your worktree, merge with `git -C /Users/andiyar/Developer/Ambrosia-Classics merge --no-ff <branch>` at each task
close, gates re-run at the merge head. Never push.

TASKS (per task: one fk-implementer, then TWO fk-reviewer legs — spec, then quality, the second told what the
first found; reviewers run the tests on their own scratch path and try mutants in a private `cp -R` copy with
HECTORKIT_PATH=/Users/andiyar/Developer/HectorKit and DEIMOS_DATA set, and re-read the listing addresses):
 CR -> G2 360/0.   TP -> 367/0.   FN -> 372/0.   CS -> G2 372, new bundle DeimosCampaignTests 3/0.
 AP -> no new tests; builds.   ST -> stage, gate-3 card, bank notes; its boot check opens a window.
 One at a time in a shared worktree (two implementers there compile each other's half-written tests).

GATES, as measured on 2026-11-15 at main after LT:
 G1 HectorKit zero-skip at ef2c341: 370 executed (366 passed + 4 Aki 1.1 skips — record, never fix here).
 G2 Deimos/Core `--skip DeimosReplayTests --skip DeimosCampaignTests`: 352/0/0 now.
 G4 DeimosReplayTests 4/0 and `deimos-replay --all` four PASS lines, exit 0 — any change is a STOP.
 G3 census body unchanged; G5 Deimos, Aki, BubbleTroubleX build; G7 layering grep empty (incl. deimos-replay);
 G10 clean tree; G11 bounded tests.

CARRIED FROM LT (act on these inside the cards):
 - As built: `GameState.levelStart(film:)` is the level start's state part (called by session set-up and by
   `levelCompleteStep`); `DeimosSession.levelStartOps()` is the drawing part; `GameState` holds `levels` (a shared
   `LevelSet`, loaded once and handed to restarted sessions through `DeimosSession.init(… levels:)`),
   `levelInfo` and `fadeToBlackCues`; the driver sends a pass's cues in two halves around a fade to black and
   calls `transitionFadeEnded(ticks:)`; `HeadlessRunner` has a campaign-end reason; `DeimosDriver.session` is an
   internal `var` (tests reach it with `@testable import`).
 - EVERY CR test goes through `levelCompleteStep` on a real transition, never a direct call to the level start:
   two LT review mutants (sector set after the players' level start; reward flag never set) were only visible
   that way. LT's own tests now pin both; CR pins the rest of the table.
 - Reach a level end in a test by poking state (appendix A §6: `game.scroll.progress = 3599`) with players kept
   alive as the existing level-end tests do; an input-less player dies about 34 s in.
 - The finale's sounds are one tick later than appendix B says (plan, "Corrections" item 1; about 80 % sure):
   FN's implementer re-reads `10033b64..10033d6c` first and STOPs if the listing disagrees.
 - AP must also change the driver's restart (today always sector 1, DeimosDriver.swift ~231) to restart at the
   launch's sector; the plan's AP card says so.
 - A bare game state loads the twelve levels on its first level start and traps if they fail; a session
   validates at set-up. A session start costs about 70 ms in a debug build (first load); restarts reuse the set.
 - Tidy-ups not done (fold into CS if cheap, else leave): `levelStart` and `LevelSet` could move to their own
   file; `fadeToBlackCues` would sit better with the cue buffer (a locked file).

BINDING RULES (each has bitten on this repo):
 - Every subagent is fk-implementer / fk-reviewer with NO `model` param.
 - Cap: 300k of your own context unless Ben sets another figure IN YOUR SESSION — and if he does, work up to
   that figure before handing over (2026-11-14: a seat stopped at 311k of a 500k cap because its wave had ended;
   Ben: "when we approach, trigger next session and launch. This was LITERALLY my message."). Read `get_usage`
   before each dispatch and at the close and say the figure.
 - Machine load: at most four heavy processes in total; count with
   `pgrep -x "swift-test|swift-build|xcodebuild" | wc -l` (never `pgrep -fl`). Tell every agent it is a hard rule.
 - Tell every agent: fix rounds strengthen existing tests and keep the ladder count; an unexpected number is a
   STOP, never an edited expectation; one heavy process at a time, foreground, none left running at the report.
 - Never push. Never git stash / reset / switch branches; never git add -A; explicit paths; trailer on commits.
 - No app launches. ST's boot check opens a window and sound: Ben's say-so only (muted, daytime).
 - Never patch HectorKit, Cythera, Ferazel, Aki or Bubble Trouble. Ferazel and Cythera sessions write
   docs/STATE.md, docs/NEXT.md, docs/DECISIONS.md on main: edit only Deimos's block and entries, never NEXT.md.
 - Research data and dumps are read-only; ST's bank notes are seat-run.
 - Messages to Ben in plain English: what happened before part names; numbers in a short table. Pass counts
   convert to seconds at 30 a second.

IF BEN'S PHASE 2 VERDICT HAS ARRIVED (STATE, DECISIONS, or a message): read it first; his notes become a fix wave
before CR, under the Phase 2 cards' Files.

CLOSE: STATE (the Deimos block), DECISIONS as-built lines under "As built — Phase 3", memory file + index line,
a new handoff built the same way (or, when ST is staged, the gate-3 card for Ben), then START THE NEXT SESSION
YOURSELF if work remains. Hard stops: a question only Ben can answer; ST's boot check; his gates.
```

## Record (2026-11-14 → 15; Fable 5.2 in the seat, Opus 5.5 implementers and reviewers)

**What happened after the wave 3 close.** Ben pointed out the seat had stopped at 311k of the 500k he had set, so
the same session went on: it planned the campaign and built the plan's first and largest task.

1. **The Phase 3 plan** (`docs/superpowers/plans/2026-11-14-deimos-phase3.md`, D50). Two read-only researchers
   grounded it in the listing; two reviewers then checked it. Finding: nearly all of the campaign is already built —
   the one real gap was moving from one level to the next. The reviewers caught that the plan had not pinned how the
   level start is split, that the transition sound would have been cut off at the finale, a file missing from one
   task's list, and that the finale's sounds are a tick later than the research said.
2. **The level transition (task LT).** 6d4bee9, fix round 45a70ff. A finished level now stops the music, plays the
   transition sound through a half-second fade to black, and starts the next sector inside the same game; after
   sector 12 the session ends. Both review legs passed it; a 300-pass comparison showed the first level byte-identical
   to before; nine deliberate bugs were tried and the tests now catch all nine (two only after the fix round).

| Check | Before LT | After LT |
|---|---|---|
| Deimos core tests | 344 / 0 / 0 | 352 / 0 / 0 |
| Demo-film replay tests | 4 / 0 | 4 / 0, same four scores |
| Deimos, Aki, BubbleTroubleX builds | — | all three succeed |
| HectorKit (ef2c341) | 370 executed (366 + 4 skips) | unchanged |

**Not independently confirmed.** Nothing has been launched: the staged Phase 2 app on the Desktop predates LT (it
still restarts at the end of level 1); the transition has been seen only by tests. Release-build cost of the level
load was not measured (debug: about 60 ms, once per launch).

**Waiting on Ben (unchanged):** the muted boot check of the staged Phase 2 app, and his "level 1 plays" verdict.
