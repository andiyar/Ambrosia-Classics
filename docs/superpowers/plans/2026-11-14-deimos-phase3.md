# Deimos Rising — Phase 3, the campaign — implementation plan (2026-11-15)

> **This file is the authority for Phase 3.** It is built from the "Phase 3 — the campaign" cards of
> `docs/superpowers/plans/2026-11-05-deimos-remainder.md` (that file's "Verification model (read first)" — gates,
> standing rules for every implementer, landmines, listing hazards — applies here unchanged and is NOT repeated: read
> it). Two grounding appendices sit beside this plan and carry every address a card cites:
> **A** = `2026-11-14-deimos-phase3-grounding-A.md` (the level transition, the carry/reset table, the Swift seams);
> **B** = `2026-11-14-deimos-phase3-grounding-B.md` (two players, the finale, sectors 2–12 readiness, the sweep, the
> app). `2026-11-14-deimos-phase3-sweep.py` is B's data-closure script (information; the Swift census in CS replaces it).
>
> House method: `~/Developer/Toolkits/fable-kit/orchestrator.md`. Per task: one `fk-implementer`, then two
> `fk-reviewer` legs (spec, then quality), no `model` param. Contracts here, not code.

**Goal:** a game started at sector 1 plays through all twelve sectors to the finale, for one or two players, exactly
as 1.0.6 does; the session then ends and (◇ until Phase 4's front end) a new game starts.

**What Phase 3 is, in one paragraph.** Almost everything is already built and tested: every unit, weapon, pickup,
rule and tally used by sectors 2–12 runs on the one generic machine that passed Phase 2, and the films of sectors 2, 3
and 4 replay to the original's scores. Two players and the finale already work in the core. **The one real gap is the
move from one level to the next inside a session** (today a finished level ends the session — stand-in 1). The rest of
the phase is proof: tests for carry-over, for two players and for the finale; a machine sweep of the eight sectors no
film covers; a way to start a two-player game before the menu exists; staging and Ben's gate 3.

## Verification model (additions to the remainder plan's)

| # | Gate | Expected |
|---|---|---|
| G1 | HectorKit zero-skip at kit main | `executed 370` on ef2c341 (366 passed + 4 Aki 1.1 skips) — or the kit's figure that day, recorded, never "fixed" here |
| G2 | `Deimos/Core` without `DeimosReplayTests` and `DeimosCampaignTests` | the ladder below, then `0` |
| G3 | census file body unchanged | empty diff |
| G4 | `DeimosReplayTests` | **4 passed / 0**; `deimos-replay --all` prints four `PASS` lines, exit 0 (unchanged by this phase — any change is a STOP) |
| G5 | Deimos, Aki, BubbleTroubleX build | `** BUILD SUCCEEDED **` ×3 |
| G6 | scope fence | changed paths ⊆ the card's Files |
| G7 | layering grep (incl. `Sources/deimos-replay`) | prints nothing |
| G8 | `DeimosCampaignTests` (from CS) | **3 passed / 0** |
| G9 | staged app boots (ST only; muted, daytime, Ben's say-so) | a pid; clean quit; no crash report |
| G10 | clean tree | nothing but `??` |
| G11 | bounded tests | every loop names a bound and fails on it |

G2 command: `swift test --scratch-path "$S/build-<task>" --skip DeimosReplayTests --skip DeimosCampaignTests`, counting
`^Test Case` lines as in the remainder plan. G8 command: the same with `--filter DeimosCampaignTests`. Heavy processes: at most four on the machine in total; count with
`pgrep -x "swift-test|swift-build|xcodebuild" | wc -l` (never `pgrep -fl`, which over-counts wrapper shells).

**Test ladder (G2, cumulative):** **344** (measured 2026-11-14) → LT **+8 = 352** (6 core + 2 host) → CR **+8 = 360** → TP **+7 = 367** →
FN **+5 = 372**. AP adds no tests (the app has no test target). CS adds the separate bundle `DeimosCampaignTests` (3). Re-specified tests keep their
names and counts.

**What the machine does NOT prove in this phase** (Ben's hands and eyes, on the gate-3 card): no film crosses a level
boundary, plays sectors 5–12, fires the Photon Beam, has two players, or reaches the finale (appendix B §3 "Films").
Transitions, carry-over, two players and the finale are proved by unit tests read from the listing, by the god-mode
sweep (a smoke check, not fidelity), and by Ben playing.

### Rulings this plan proceeds on (the seat's, 2026-11-15; each is on the gate-3 card for Ben to overturn)

1. **`-players 2` and `-sector N`** — two ◇ launch arguments beside `-film`, standing in for the original's menu
   until Phase 4: the 2 PLAYER button (or the `2` key), and the level select (which lets you start at any sector up
   to the best one reached; a start above sector 1 has one life, as the original). Restarts keep both. Without
   `-sector`, every look at a late sector would mean playing all the earlier ones first — the console has no level skip.
2. **Player 2's keys are the prefs defaults** read from the binary (keypad 8 / 4 / 6 / 5 = up / left / right / down,
   End = fire, Forward Delete = bomb, Page Down = select; appendix B §1a). Where OS X 1.0.6 actually consumed them is
   unread (INDEX #14). A laptop keyboard has none of these keys; remapping is Phase 4's controls window.
3. **After the finale the session ends and a new game starts at sector 1** (◇, like game over and Esc) — the original
   went to the high-score check and the menu (Phase 4). There is no credits screen after the finale in 1.0.6.
4. **Every level after the first runs one game-time step later than level 1** (its first tick is at game time 1) —
   this is the original (`100059e0..100059f0`), not a bug to fix. Pinned by a test.
5. **The level start's state lives in `GameState`; its drawing stays with the session** (the design choice LT builds
   on — see the LT card). 
6. **Original quirks replicated, not guarded:** the stale multiplier-indicator serial carried into the next level;
   a player caught dying at the transition is revived without losing the life (appendix A §2, §5 items 5–6).

## Corrections to the appendices (found by the plan's two review legs; **this section wins over the appendices**)

1. **Finale sounds are one tick later than appendix B says** (B §2c, §7 "FIN-a"). A state entered by its timer plays
   its entry sound on the NEXT tick: the sound step (`10033b64..10033c54`) runs before the timer step
   (`10033c58..10033d6c`) and state entry (`FUN_100146f0`) plays nothing. So: the first `acbo` at T0 (the notice
   enters state 0 at spawn); the other fourteen at **T0+6k+1** (T0+7 … T0+85); `leen` at **T0+103**. Unchanged (the
   spawn executor runs after the timer in the same pass): `12gc` at T0+90, Scale Out T0+92, the explosions requested
   T0+95, flags at 395 / 464 / 534 / 604 and 675 / 744 / 814 / 884, `12gc` deleted T0+955, the tally step at T0+1201.
   The leg's confidence is about 80 %: FN's implementer re-reads those two address ranges first, and if the listing
   says otherwise STOPs with what it shows.
2. **Game time at the session's end after the finale is 1, not 0** (B §7 "FIN-b" says 0): the level start sets 0 and
   the loop adds 1 before the pass ends (A §1a step 4).
3. **Sector 4 keeps whatever air weapon the player last selected** — even the Ion Cannon, which is outside sector 4's
   own range; A §4's "holds the Rear Gun in sector 4 like a direct start" is wrong (no weapon has minimum level 4, so
   the slot is untouched). The test row "sector 4 keeps" stands.
4. **There is one air-weapon slot and no inventory**: Select cycles the air weapons the current sector allows.
5. A §1a wording: `FUN_10047f80` returns "music playing" (the `ammu` branch runs when nothing plays — same effect);
   the console reset is passed the word loaded from controller + 8.

## Waves

| Wave | Tasks | Notes |
|---|---|---|
| 3.1 | **LT** (⚑ MAJOR, alone) | restructures the session's level start; everything else waits for it |
| 3.2 | **CR**, **TP**, **FN** | tests-first tasks in disjoint test files; **one at a time in a shared worktree** (two implementers there compile each other's half-written test files and the counts drift) — or in parallel only if each works in its own private clone and the seat cherry-picks |
| 3.3 | **CS** then **AP** | CS owns `Package.swift`, DeimosHost and `TickTrace.swift`; AP owns the app files only |
| 3.4 | **ST** | stage, gate-3 card, late bank notes; then Ben's gate 3 |

If Ben's Phase 2 verdict arrives with notes, a fix wave for them runs first, as wave 3.0, under the Phase 2 cards' Files.

---

### LT — ⚑ MAJOR — the level transition (+8 → 352) — alone in its wave

- **Files:** `Sources/DeimosCore/Game/{LevelEnd,DeimosSession,FrameKeys,GameFlags,GameState}.swift`,
  `Sources/DeimosCore/Seams/PassOutput.swift`; `Sources/DeimosHost/{HeadlessRunner,DeimosDriver}.swift`;
  `Tests/DeimosCoreTests/LevelTransitionTests.swift` (new), `Tests/DeimosCoreTests/LevelEndTests.swift`,
  `Tests/DeimosHostTests/{ReplayHarnessTests,DriverTests}.swift`. Any other call site is named in the report.
- **Design (pinned — ruling 5):** the level start is split. Its **state part** (flags, the sector + 1 / `none` branch,
  players, lists, scroll, entity world, load pass, the level notice, the music cues) becomes a `GameState` method
  that `levelCompleteStep` calls directly, with the twelve levels' definitions and masks held by the game state
  (loaded and validated at session init). Its **drawing part** (load terrain and mask into the renderer, fill back,
  the score bar's level start, the first terrain draw) stays in `DeimosSession`, which emits those ops in the same
  pass when it sees the game state has started a level. So a bare `GameState` can cross a transition in a test (the
  existing `LevelEndTests` world, `testNoReseedBetweenLevels`, and every CR test rely on this), and the session's
  first level uses the same two halves.
- **Contract (appendix A §1, §3 — read both in full first):**
  - On the pass where the tallies finish, a NON-film session with a player in game no longer ends. In the original's
    order (`FUN_10007170`, `10007200..1000725c`): music stop → `tran` (PermSound 3, priority 75, volume 100, multiple)
    → `.fade(.toBlack, .gameLayout)` → clear level-complete and level-ending flags → `FrameKeys.levelTransitionReset`
    (incl. the layer clear at `100302f4`: emit it or record why it is a no-op) → the level start for sector + 1 inside
    the same `GameState`. Film and no-player branches are unchanged.
  - The level start gains the later-level branch (`10006594..100066c8`): sector = sector(tag) + 1; above the level
    count (12) the level becomes `none`; **levels started += 1 before the `none` test**; level `none` = music
    `.resume`, running cleared, return before any player or world reset. Otherwise `flags.sector` is set before the
    players' level start, and the session's level info is replaced by the new level's (it becomes mutable; the public
    name stays — standing rule 7) so the appear tick plays the new level's music tag.
  - **Op order within the transition pass:** that tick's terrain stamps → the fade to black → the level-start ops
    (load terrain and mask, fill back, score-bar level start, first terrain draw) → draw world → end frame with **no
    present** (appeared is 0). Stamps must never land on the new map.
  - **Game time:** the level start sets 0, then the loop's `+= 1` leaves **1** at the end of the transition pass; the
    new level's first tick runs at 1 and it appears on its second tick (ruling 4). Do not "correct" this.
  - RNG: no re-seed; the only draws between the two levels are the players' level-start draws (P1 then P2, in-game
    players only), then the load-pass spawns and the level notice (appendix A §1c).
  - Level data: the level start can throw (definition, mask) inside a non-throwing pass — validate all twelve levels'
    definitions and masks at session init (throwing there), so a mid-session start cannot fail.
  - Host: `HeadlessRunner`'s end reasons gain the campaign end (level `none` after the last sector); a mid-run
    transition is not an end.
  - **Driver — cues around the fade.** Today the driver hands a pass's sounds, music and effects halt to the sink
    when the pass begins (`DeimosDriver.swift` ~309, ~330–341). On a transition pass that would start the new
    level's cues about half a second early, and on the finale's last pass it would start `tran` and halt it in the
    same call, so it would never be heard — the original plays it through the fade. `PassOutput` gains an additive
    marker for where the fade to black falls in the pass's cue lists (as H2 did for the pause); the driver sends the
    cues before the marker at pass begin and the rest — the new level's cues, or the end-of-session halt and stop —
    only when the fade's last step has been presented. Characters typed while the fade runs are dropped (the
    original flushes events after the fade, `10030328`). The frame controller's reset uses the tick at which the
    fade ended, not the pass-begin tick. For the two host tests the driver's session becomes settable from tests
    (`internal(set)`, reached with `@testable import`), so a test can put the level one tick from its end.
- **Tests (8, names verbatim; appendix A §6 gives the six core tests' assertions and addresses):**
  `testTransitionPassStartsNextSector` · `testTransitionOpOrder` · `testTransitionCues` ·
  `testNextLevelAppearsOnItsSecondTick` · `testNoReseedBetweenLevels` · `testSectorTwelveCompleteEndsSession` · and in
  `DriverTests`: `testTransitionCuesSplitAroundFade` (a recording sink: stop and `tran` before the fade's first step,
  the new level's cues after its last; at the campaign end `tran` is not halted before the fade finishes) ·
  `testTypedKeysDroppedAcrossTransitionFade`.
  Re-specify (same names, same count): `LevelEndTests.testLevelCompleteClearsRunningInFilm` (its non-film case now
  continues into sector 2) and the non-film case in `ReplayHarnessTests` (~lines 92–98).
- **Gate:** G2 = **352 / 0**; **G4 unchanged (4 / 0, four PASS lines)** — a film session must behave exactly as before;
  G3, G5, G7. **Commit:** `DeimosCore: the level transition — fade to black, sector + 1 in the same game, level none
  ends the session; cues split around the fade; 8 tests`. Two review legs; leg 1 re-reads `10007170..1000725c` and `100064d0..100066c8`, leg 2
  re-derives the +1 game-time fact and the op order independently and runs mutants (stamps after the load; level
  start before the fade; game time reset after the tick; levels started incremented after the `none` test; re-seed; the new level's cues sent at pass begin).

### CR — the carry/reset table (+8 → 360) — after LT

- **Files:** `Tests/DeimosCoreTests/CarryResetTests.swift` (new). Source files only if a row fails — then STOP and
  report the row, the address and the minimal fix; the seat rules (appendix A says the rules are already built:
  `Player.levelStart`, `playerLevelStart`, `resetHandler`, the score-bar level start).
- **Contract:** one test per group of rows of appendix A §2's table, each poking player 1 (and 2) before the
  transition and asserting after it. The table in appendix A, not the bank's §8, is the reference (the bank omits
  five rows and has one wrong; ST corrects the bank).
- **Tests (8):** `testLivesScoreThresholdCarry` · `testMoneyAndCounterReset` ·
  `testMultiplierCarriesAndIndicatorOnRespawn` · `testShieldRefilledPowerUpsIdle` ·
  `testAirWeaponForcedAtSectorsTwoThreeFive` · `testInvulnerabilityCarriesIntoNextLevel` · `testDeadPlayerStaysOut` ·
  `testPerLevelCountersReset` (assertions and addresses: appendix A §6).
- **Gate:** G2 = **360 / 0**. **Commit:** `DeimosCore: carry and reset across a level transition, row by row; 8 tests`.

### TP — two players in the core (+7 → 367) — after CR

- **Files:** `Tests/DeimosCoreTests/TwoPlayerTests.swift` (new). Source files only on a failing fact — STOP and report.
- **Contract (appendix B §1):** the core already starts, reads, updates and draws two players; these tests pin the
  duo behaviours no test covers yet.
- **Tests (7):** `testDuoViewShiftDoublesAndCancels` · `testDuoRespawnAtMultiStart` · `testDuoOneOutGameContinues` ·
  `testDuoBothOutGameOver` · `testDuoLevelStartDrawsPerInGamePlayer` · `testDuoScoreBarBothActive` ·
  `testDuoMissionBonusPaysBoth` (assertions and addresses: appendix B §7 "2P-a").
- **Gate:** G2 = previous + **7**. **Commit:** `DeimosCore: two players — shared view shift, respawn, one out, both
  out, score bar, mission bonus; 7 tests`.

### FN — the finale (+5 → 372) — after TP

- **Files:** `Tests/DeimosCoreTests/FinaleTests.swift` (new; all five tests). Source files only on a failing fact — STOP and report.
- **Contract (appendix B §2):** the trigger, the 1,200-tick wait and the mission bonus are built; these tests pin the
  whole chain on sector 12's real data and the session end that LT made possible.
- **Tests (5):** `testFinaleTimelineFromNoal` (the T0-relative timeline of appendix B §7 "FIN-a" **as corrected above, item 1**, god mode,
  bound 3,000) · `testFinaleEndsSessionAfterTally` (game time 1 at the end — correction 2) · `testAllLevelsFlagSurvivesToSessionEnd` ·
  `testTwelveGcExplosionSetHasNoDelay` (the data pin that closes INDEX #64) ·
  `testHospitalKillSubtractsMultipliedScore` (−10,000 × multiplier, no extra-life change; the score bar's negative
  form). Also asserted inside `testFinaleEndsSessionAfterTally` or the CR tests, wherever it fits without a new test:
  the revive-without-losing-a-life quirk of ruling 6 (a player dying at the transition).
- **Gate:** G2 = **372 / 0**. **Commit:** `DeimosCore: the finale on sector 12's data,
  the session end after it, the hospital penalty; 5 tests`.

### CS — the campaign sweep (bundle `DeimosCampaignTests`, 3) — after wave 3.2

- **Files:** `Package.swift` (test target `DeimosCampaignTests`, deps `DeimosHost`, `DeimosCore`);
  `Tests/DeimosCampaignTests/{CampaignSweepTests,CampaignTestData}.swift` (own data locator; a missing file fails);
  `Sources/DeimosCore/Game/TickTrace.swift` (a locked seam file: its row gains the sector, additively),
  `Sources/DeimosHost/{ReplayTrace,HeadlessRunner}.swift` and `Tests/DeimosHostTests/ReplayHarnessTests.swift` (a
  sector column in the trace — the CSV header test is updated in the same commit, count unchanged);
  `Sources/DeimosHost/FilmLookup.swift` (new: the film lookup by tag, today written four times) with its three
  non-app users re-pointed (`Sources/deimos-replay/main.swift`, `Tests/DeimosReplayTests/ReplayTestData.swift`,
  `Tests/DeimosHostTests/ReplayHarnessTests.swift`).
- **Contract (appendix B §4):** a machine smoke check for the sectors no film covers. It drives `DeimosSession`
  directly from the test target; **god mode** (in-game players forced invulnerable each tick) and a deterministic
  scripted pilot (both fire buttons held, a left/right sweep, a periodic select) — stated in the test as a smoke
  check, not a fidelity proof. A Swift census computes each level's unit closure from the definitions.
- **Tests (3, G8):** `testEverySectorReachesItsEnd` (sectors 1–12 each from a direct start, passive and scripted,
  bound 16,000 passes: no trap, the level end is reached, the transition to the next sector happens — or for 12 the
  campaign end; every spawned unit is in that level's closure) · `testCampaignOneToTwelve` (one scripted run from
  sector 1, bound 150,000: levels started 13, the all-levels flag, session end) · `testTwoPlayerCampaignStart` (a
  two-player sector-1 run through the first transition, with a variant where player 2 is out).
- **Gate:** G2 unchanged; **G8 = 3 / 0**; G4 unchanged; G7. An unreached level end or a spawn outside the closure is a
  finding to report with the trace, never a relaxed assertion. **Commit:** `DeimosCampaignTests: every sector to its
  end, the campaign 1 → 12, a two-player start; trace sector column; one film lookup; 3 tests`.

### AP — the app: start with two players, start at a sector (no tests) — after CS

- **Files:** `Deimos/App/{DeimosMain,DeimosController}.swift` (the app's film lookup re-pointed to `FilmLookup`).
- **Contract:** ◇ `-players 2` and ◇ `-sector N` (1–12) (ruling 1) parsed beside `-film`, feeding the session start;
  a bad value fails the way a bad film tag does; with `-film` both are ignored (the film carries its own). Restarts
  keep both (the driver already keeps the start). No app change is needed for transitions themselves.
- **Gate:** G2 unchanged (**372 / 0**); G5 (Debug and Release). No launch. **Commit:** `Deimos app: -players 2 and
  -sector N until the menu exists`. Two review legs, by reading and building.

### ST — stage, the gate-3 card, the late bank notes

- **Files:** `Deimos/WHAT-TO-EXPECT.md`; `docs/deimos/*.md` + `INDEX.md` (seat-run, one commit
  `docs(deimos): Phase 3 bank corrections (<n> notes)`): `level-scroll-objects.md` §8 (the six disagreements of
  appendix A §2), `loose-ends-session.md` §5.3 (appendix B §2c), INDEX #64 closed, "3055 − Y holds for the first level
  only", and the finale sound ticks of correction 1 (never the uncorrected "T0 … T0+84").
- **Contract:** staging unchanged (`tools/stage-deimos.sh` → `out/Deimos/`, `~/Desktop`). WHAT-TO-EXPECT in Ben's plain
  English: what Phase 3 is and is not; the stand-ins that remain (game over, Esc and now the finale each start a new
  game; `-film`; `-players 2`; `-sector N`; prefs in memory); the remainder plan's "Note for P3" (the effect gate and
  the music fallback differ from the original only for data shapes no shipped file has — one plain sentence under
  "differs on purpose"); that sounds at a level change are sent around the fade as the original does; rulings 1–6; the machine results (G4 four films; G8 the sweep, with
  the honest limit that it is a god-mode smoke check); and the gate card below.
- **Gate:** G1, G2 = **372 / 0**, G3, G4 = 4 / 0, G5, G8 = 3 / 0, G9 (muted, daytime, with Ben's say-so). **STOP for
  Ben.** **Commit:** `Deimos: Phase 3 staged — WHAT-TO-EXPECT (gate 3 card)`.

**The gate-3 card — "does the campaign play like Deimos"** (the ST implementer may tighten wording, not content)

Open `~/Desktop/Deimos Rising.app`; play from Mariner Valley. The console's cheats are there if you want to get
through quickly. Each line: what you'll see or hear, and what would be wrong.
1. **Between levels:** when the tallies finish, the music stops, a transition sound plays through a fade to black of
   about half a second, and the next sector fades in with its level notice and the level music. Wrong: a
   pause, a flash of the old level, sound cut off, or the game starting again at sector 1.
2. **What you keep:** lives, score, the next-extra-life mark and your multiplier carry over. Wrong: any of them reset.
3. **What resets:** coins go back to zero (after their bonus was paid), the shield is full again, power-ups are idle.
4. **Weapons:** entering sector 2 gives you the Bacta Gun, sector 3 the Rear Gun, sector 5 the Photon Beam; elsewhere
   you keep the one you last selected. There is one air-weapon slot: Select (Space) cycles the air weapons the
   current sector allows. The weapon and item icons in the side panel follow the sector.
5. **Invulnerable at the start of a new level:** after the first level you re-enter each level unable to be hit for
   about two seconds (carried from the level end, as the original's code reads). On level 1 you do not. If your
   memory says otherwise, say so.
6. **A player who is out stays out** in a two-player game; the other plays on.
7. **Two players:** `open ~/Desktop/"Deimos Rising.app" --args -players 2` (quit first). To start at a later sector
   add `-sector 7` (any of 1–12; one life, as the original's level select gives you). Player 2 uses the keypad
   8 / 4 / 6 / 5 to move, End to fire, Forward Delete to bomb, Page Down to select — the original's defaults; a laptop
   keyboard has none of these (the controls window is Phase 4). Both ships start side by side; steering the same way
   slides the view twice as fast, opposite ways cancel. Player 2's panel sits below player 1's. Question for you:
   are those the keys you remember? Does player 2 still respond while player 1 holds Command?
8. **Sectors 5–12:** new enemies and set pieces, the Photon Beam, and in sectors 7 and 12 a hospital that costs
   10,000 × your multiplier if you destroy it. No demo film covers these sectors: your eyes are the check.
9. **The finale (sector 12, reached from a sector-1 start):** the "all levels" notice flashes fifteen times with a
   sound each; about ten seconds of explosions; four irises open twice with storms of coins and bonuses until about
   half a minute in; the tallies begin about forty seconds after the notice. If every level was at 100 % ground
   accuracy, a mission bonus follows: ten payments of 100,000. Then the transition sound, black, and a new game
   starts (a stand-in: the original went to the high scores and the menu, which are Phase 4).
10. **Not yet certain:** the feel of the eight uncovered sectors; the mix during the finale's explosions; player 2's
    real keys on Mac OS X; anything from the Phase 2 card you have not yet ruled on.

---

## Self-review (the seat, after writing)

- Every card names its Files, Contract, Tests by name, Gate and Commit; assertions and addresses live in the two
  appendices by section so an implementer needs the card, one appendix and the remainder plan's verification model.
- The remainder plan's card P3.5 (film gates for de02–de04) was completed in Phase 2 (wave 3); it is G4 here.
- Spec vs data checked by the grounding legs: sector order and tags, weapon ranges, the finale chain and its timings,
  the transition's address-by-address order; the +1 game-time fact and the bank's wrong rows are stated, not assumed.
- Not planned here on purpose: high scores, name entry, the level select, Last Film recording, the menu, prefs on
  disk, the controls window, a controller (all Phase 4); Windows (Phase 5).
