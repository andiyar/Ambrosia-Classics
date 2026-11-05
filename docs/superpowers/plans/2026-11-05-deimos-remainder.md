# Deimos Rising — the remainder — implementation plan (2026-11-05)

> **For agentic workers:** REQUIRED SUB-SKILL: `superpowers:subagent-driven-development` (the house overlay is
> `~/Developer/Toolkits/fable-kit/orchestrator.md`). One `fk-implementer` and one `fk-reviewer` per task, no `model`
> param (Opus 5.5 by the agents' own pin; Ben 2026-10-07: Opus only). Steps use `- [ ]` checkboxes.
>
> Spec: `docs/superpowers/specs/2026-11-05-deimos-remainder-design.md`. Audit (Wave 1, done in the pass that wrote
> this plan): `docs/superpowers/audits/2026-11-05-deimos-phase2-audit.md`. The Phase 2 plan
> (`docs/plans/2026-10-07-deimos-phase2.md`, on branch `deimos-phase2` until the merge) stays the **authority for the
> contracts** of every remaining Phase 2 task; this plan says what to do next, in what order, with what is known now.

**Goal:** finish Phase 2 (level 1 plays, the de01 film replay gate) from where branch `deimos-phase2` stopped, then the
campaign, the front end and Windows, each as its own plan when its turn comes.

**Architecture:** unchanged (D29.1, D31.1): `DeimosCore` holds one `GameState` value and every rule as an index-taking
method on it; `DeimosRender`, `DeimosAudio`, `DeimosHost`, thin shells. The next wave joins the already-built pieces
(C12: the entity and world update; C18a: the session loop) after the owed reviews are discharged and the research
bank is corrected.

**Tech stack:** Swift 6.4 / Xcode 27 beta, SwiftPM tools 6.0, XCTest, xcodegen; HectorKit as a local path dependency
(`../../../HectorKit` from `Deimos/Core`, i.e. the `.claude/worktrees/HectorKit` symlink in a worktree).

---

## Verification model (fable-kit; read first)

| Rule | What it means here |
|---|---|
| **Machine gates close alone; Ben closes the honesty gate** | every task names its gate and expected number below; "done" is phrased "machine gates green; Ben's gate pending" |
| **Numbers from your own run** | never relay a subagent's count; re-run G2 at the merge head yourself |
| **Reviewers run things** | each review leg runs the task's tests on its own `--scratch-path` and re-derives two or three rules from the dump or listing; a diff-only review is not a review |
| **Diagnosis before dispatch, to file:line** | every task below carries anchors; "investigate and fix" is never a subagent task |
| **STOP on any unexpected number** | report it; never edit an expectation (D31.10 for the replay gate) |
| **Scope fence + diff audit** | `git diff --name-only <base>..HEAD` ⊆ the task's Files; an extra file is scope creep until proven a call site |
| **Explicit-path commits, trailer** | never `git add -A`, never `git stash`; `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>` on implementer commits |
| **Cap** | 300k of the seat's own context (orchestrator.md §5); the next wave is two sessions (2a, 2b); say the meter before each dispatch |
| **Bounded tests** | every loop names `maxPasses` / a bound and fails on it (G11); own `--scratch-path` per agent |

### Gates (copy the commands from the code block; the table holds the expected values)

| # | Gate | Expected |
|---|---|---|
| G1 | HectorKit zero-skip at the checkout Classics builds against | `executed 370` on current main (366 passed + 4 skipped — the 4 Aki 1.1 census tests skip because `HECTORKIT_DATA_AKI11` is not a directory on this machine; a kit-side data path, not a Deimos matter; record it, do not "fix" it in this lane) |
| G2 | `Deimos/Core` suite without `DeimosReplayTests` | the ladder total below, then `0` |
| G3 | census unchanged | the `data-census.md` diff against the merge base is empty |
| G4 | de01 replay (from H3) | `DeimosReplayTests` 3/0 and `score 25050 at read 4809` — D31.10 miss path |
| G5 | apps build | `** BUILD SUCCEEDED **` for Deimos, Aki, BubbleTroubleX (after xcodegen) |
| G6 | scope fence | changed paths ⊆ Files |
| G7 | layering | the grep prints nothing |
| G10 | clean tree | `git status --porcelain` without `??` prints nothing |
| G11 | no hangs | every loop bounded; a hung test fails the task |

```sh
WT=/Users/andiyar/Developer/Ambrosia-Classics/.claude/worktrees/inspiring-cannon-e97ccd   # wave 2a; wave 2b uses a fresh worktree from main
S=<your scratchpad>
# G1
HECTORKIT_TEST_LOG="$S/hk.log" /Users/andiyar/Developer/HectorKit/tools/check-zero-skip.sh 2>&1 | tail -n 1
# G2
cd "$WT/Deimos/Core" && swift test --scratch-path "$S/build-<task>" --skip DeimosReplayTests > "$S/dm.log" 2>&1
/usr/bin/grep -cE "^Test Case '.*' (passed|failed|skipped) \(" "$S/dm.log"; /usr/bin/grep -cE "^Test Case '.*' (failed|skipped) \(" "$S/dm.log"
# G3
git -C "$WT" diff --stat "$(git -C "$WT" merge-base HEAD main)" -- docs/deimos/data-census.md
# G5
cd "$WT" && xcodegen generate && for s in Deimos Aki BubbleTroubleX; do xcodebuild -scheme "$s" build 2>&1 | tail -n 1; done
# G6
git -C "$WT" diff --name-only <task base>..HEAD
# G7
/usr/bin/grep -rnE "^import (AppKit|UIKit|SwiftUI|CoreGraphics|CoreText|ImageIO|AVFoundation|QuartzCore|HectorGraphics|HectorShell)" "$WT/Deimos/Core/Sources/DeimosCore" "$WT/Deimos/Core/Sources/DeimosRender" "$WT/Deimos/Core/Sources/DeimosHost" "$WT/Deimos/Core/Sources/DeimosAudio"
# G10
git -C "$WT" status --porcelain | /usr/bin/grep -v '^??'
```

**Test ladder (G2, cumulative):** branch tip **313** (measured 2026-11-05) → fix round 2.1 **318** (five new tests;
nine existing tests strengthened keep their names) → bank corrections 2.3 unchanged → C12 **+9 = 327** (the plan's
eight plus the same-tick stamp test) → C18a **+8 = 335** → C18b **+1** → H2 **+8** = **344**; H3 adds 3 to the
separate G4 bundle.

### The review, measured (2026-11-05, the seat's own runs)

| Suite | Passed / failed / skipped |
|---|---|
| branch `Deimos/Core` vs HectorKit main ef2c341 | 313 / 0 / 0 |
| branch `Deimos/Core` vs the pinned HectorKit e595472 (through a `HectorKit`-named symlink to the `deimos-k2` worktree) | 313 / 0 / 0 — identical |
| main `Deimos/Core` (= `Deimos/DeimosCore`, a symlink) | 189 / 0 / 0 |
| HectorKit zero-skip at e595472 | executed 328 = 324 + 4 skipped (Aki 1.1 data), 0 failed |
| HectorKit zero-skip at ef2c341 | executed 370 = 366 + 4 skipped (same), 0 failed |

Branches and worktrees: `deimos-phase2` (44 commits past merge base cc84fb0; pushed; main has touched nothing under
`Deimos/` since), worktree `.claude/worktrees/inspiring-cannon-e97ccd`; `loop/42-…` is Ferazel's (do not touch);
HectorKit worktree `~/Developer/HectorKit-worktrees/deimos-k2` at e595472 (merged into kit main; removable).

---

## Waves

| Wave | What | Where | Sessions |
|---|---|---|---|
| **1 Audit** | five read-only Opus reviewers over the 44 commits against the spec; rulings | done in the re-planning pass → the audit file | (this pass) |
| **2a** | 2.1 the fix round from the audit's rulings (discharges the three owed legs) → 2.2 merge `deimos-phase2` to main → 2.3 bank corrections | branch worktree, then main | 1 |
| **2b** | 2.4 C12 → 2.5 C18a | a fresh worktree from main | 1 |
| 3 | C18b ∥ H2 → H3 ∥ A3 → (F1) → A4 → Ben's gate 2 | cards §Wave 3 | 1–2 |
| 4 | Phase 3 campaign | cards; its own plan after Phase 2 closes | — |
| 5 | Phase 4 front end | cards | — |
| 6 | Phase 5 Windows + release | cards | — |

The fresh orchestrator's scope is **waves 2a and 2b only** (the handoff fences it). Ben says go.

---

## Wave 2a

### Task 2.1 — The fix round from the audit (discharges C11b legs 1–2 and C17 leg 2)

The audit file (`docs/superpowers/audits/2026-11-05-deimos-phase2-audit.md`, "Rulings", owner **2.1**) is the
brief; its five reports give the `File:line` and the listing address for each row. Three implementers, one per
family, disjoint files, own `--scratch-path`; one review leg each. Line numbers are the branch tip's (2026-11-05).

**Family A — world, motion, state (audit rows 2·5, 2·7, 2·12, 2·14, 2·19, 3·4, 3·6, 3·11, 3·16, 3·17, 3·19).**
Files: `Deimos/Core/Sources/DeimosCore/Units/{EntityWorld,Rules,SpawnSets,Motion}.swift`,
`Tests/DeimosCoreTests/{EntityWorldTests,SpawnTests,MotionTests,StateMachineTests}.swift`.
- [ ] `EntityWorld.swift:47` — `freeHint` default 0 (the reset stores 0 at `10038450`).
- [ ] `Rules.swift:172-178` `isOnScreen` — write the two x tests as the listing's negated compares (`!(x < 0)`,
  `!(x > W)`, `10016bf4..10016c3c`) so a NaN x passes as in the original; y tests unchanged.
- [ ] `SpawnSets.swift:40` — add `k < st.spawnSets.count` to the loop guard.
- [ ] `Motion.swift:25-27, 34, 45` — doc lines: "two draws unless trunc(MaxSpeed) = 0 (no shipped cyclic state is
  below 1)"; "0.0 is the original's initial distance, `0x100d6354`".
- [ ] Tests, failing first: `testPoolCapAndHint` also pins +0xb8, +0x100…+0x114, +0x138 stale after reset ·
  **new** `testSpawnDrawSitesInOrder` (a unit with `initialScalePercentTolerance ≠ 0`, a random-axis flee code and an
  armed spawn set in state 0, cyclic start: the draw sequence size → appears → placement → scale tolerance
  (`10014b14`) → flee (`10014d90`) → arming (`10017cb0`) → group delay → cyclic, against an in-test LCG) · **new**
  `testTypeExistsRefusal` (a deleted, unreaped member still refuses after the size draw) · `testLoadPassBand` pins
  the per-level literals 2, 1, 2, 1, 3, 0, 0, 0, 0, 1, 2, 1 · `testCullBoundsMode1` with hw 10, hh 14 ·
  `testShurikenControllerThreeGroups` pins 1000, 1125, 1245 for seed 0x469c2.
- [ ] G2 (family filter) = previous + 2; commit `fix(audit): world/motion/state — rows 2·5 2·7 2·12 2·14 2·19 3·4 3·6
  3·11 3·16 3·17 3·19`.

**Family B — combat, player, weapons (audit rows 4·3, 4·5, 4·6, 4·9, 4·13, 4·19 doc, 4·20, 4·23).**
Files: `Sources/DeimosCore/Combat/Removal.swift`, `Sources/DeimosCore/Weapons/WeaponHandler.swift`,
`Sources/DeimosCore/Player/Player.swift` (doc only), `Tests/DeimosCoreTests/{PlayerTests,DestructionTests}.swift`.
- [ ] `Removal.swift:199, 201, 220, 228-230` — inline `removeMemberStub` as `removeMember(..., byPlayer: false)` and
  delete it; `Removal.swift:68` doc line: the deletion template (`r2+0x50ec`) equals the shared template (static-init
  audit: the seven spawn templates differ only by +0x24 = −1, which `SpawnRequest.template` carries).
- [ ] `WeaponHandler.swift:201` — `resetHandler(levelStart:sector:)` with `sector` required (`1003b0dc` reads G+0x14);
  update the callers.
- [ ] `Player.swift:228-232` — doc: `sector` is retired by C18a; `scoreBarIcons(sector:)` is the API.
- [ ] Tests, failing first: **new** `testOwnerDestructionPrecedesDeathSpawn` (a player-owned unit with
  `canBeDestroyedOnOwnerDestruction` dies, with its draws, before the death spawn — `10027e70..10027e74`) ·
  `testDeathOrder` called with `now ≠ gameTime`, asserting the state-entry time · `testDestroyOrder` replays the
  RNG on a copy and pins the bonus draw · `testPlatformSevenBombHits` reads `plbo`'s `damage_FLOAT` and asserts 0.4f.
- [ ] G2 (family filter) = previous + 1; commit `fix(audit): combat/player/weapons — rows 4·3 4·5 4·6 4·9 4·13 4·19 4·20 4·23`.

**Family C — audio, end of level, seams (audit rows 1·19, 1·23, 1·26, 5·4, 5·5, 5·7, 5·8, 5·10).**
Files: `Sources/DeimosAudio/{DeimosAudioEngine,EffectMixer}.swift`, `Sources/DeimosCore/Seams/HeldKeys.swift`,
`Tests/DeimosAudioTests/MusicEngineTests.swift`, `Tests/DeimosCoreTests/LevelEndTests.swift`.
- [ ] `DeimosAudioEngine.swift:83-86` — `init(effects: consuming EffectMixer)`; `EffectMixer.swift:74-82` — the
  attribute below the doc comment; `HeldKeys.swift:11` — name `Console`'s pinned codes.
- [ ] Tests, failing first: `testEngineIsAPullSource` asserts the preload count 96 (an internal count accessor) ·
  **new** `testTallyTextRequest` (nil at state 0 and at alpha 32; the record at state 2 with alpha 29: format 0x35,
  +0x10c 15, +0x10d 1, +0x110 0, +0x114 = alpha — dump `FUN_10007d60`) · `testLevelEndSequenceOrder` /
  `testGameOverStopsOnStartPlus111` / `testCoinBonusSteps` assert the spawn positions (208, 240) for `nogo` and
  `nole`, (105, 248) and +70 stacked for `p1mc`/`p2mc` · **new** `testAllLevelsNoticeAtSectorTwelve` (sector =
  levelsStarted = 12 through `levelEndStep` → `.notice(noal)` and `allLevels`) · `testLevelCompleteClearsRunningInFilm`
  posts a message and opens the console before, asserts both cleared after (`FUN_100302e0`).
- [ ] G2 (family filter) = previous + 2; commit `fix(audit): audio/level-end/seams — rows 1·19 1·23 1·26 5·4 5·5 5·7 5·8 5·10`.

- [ ] **Close:** the seat re-runs G2 at the branch tip: **318 / 0 / 0**; G6 per family; G7; STATE one line.

### Task 2.2 — Merge `deimos-phase2` into main

**Files:** none of Deimos's; `docs/STATE.md`, `docs/DECISIONS.md` (the conflict resolution only).

- [ ] **Step 1:** in the **main checkout** (`/Users/andiyar/Developer/Ambrosia-Classics`, on `main`; never in the branch
  worktree, never `git stash`): `git merge --no-ff deimos-phase2`. Expected conflicts: `docs/STATE.md` (keep main's
  header and Ferazel lines; take the branch's Deimos Phase 2 paragraph, then edit it to the post-fix-round numbers) and
  possibly `docs/DECISIONS.md` (D31 is free on main: D30 is followed by D32 — keep the branch's D31 block in numeric
  place; nothing else conflicts).
- [ ] **Step 2:** G2 at the merge head in the main checkout (`--scratch-path "$S/build-merge"`): the Task 2.1 total,
  0 failed. G3. G5 (Deimos, Aki, BubbleTroubleX build after `xcodegen generate` — this is the first app build against
  current HectorKit; a failure here is a kit-drift finding: STOP and report, do not patch the kit from this lane).
- [ ] **Step 3:** commit the merge with the message `Merge deimos-phase2: Phase 2 waves 2.0–2.6 + the audit fix round
  (G2 <n>/0/0)`. Do not push (Ben pushes).
- [ ] **Step 4:** remove the worktree (`git worktree remove .claude/worktrees/inspiring-cannon-e97ccd`) and delete the
  local branch only after Step 2 is green; leave `origin/deimos-phase2` for Ben to delete after the push.

### Task 2.3 — Bank corrections (docs; was B1)

**Files:** `docs/deimos/{sound-music,messages-notices-console,particles-debris-blur,loose-ends-combat,units-movement,
spawn-and-waves,weapons-projectiles,damage-health-death,micro-wave-2026-10-06,engine-loop,bosses,timing-frame,
level-scroll-objects,player-physics,scoring-bonuses,data-census}.md`, `docs/deimos/INDEX.md` (one line per note).

The list: the Phase 2 plan's "Bank corrections to append" (8 items) and the handoff's "Bank corrections collected
for B1" (the C7, C8, C9, C10, C11a, C13, C14, C15, C16, C17, C19, A1, A2 blocks in
`docs/handoff-2026-10-07-deimos-phase2-waves.md`), plus every correction the audit's reports add (the audit file,
"Bank corrections found by the audit").

- [ ] **Step 1:** one implementer; for each item append a `⚑ corrected (Phase 2, 2026-11)` note in the named file's
  section with the listing address the handoff cites; one INDEX line per note (the INDEX append rule). Where the
  handoff says "fix plan wording" (the C13 "6 updates → 5 visible" item, the C15 "r+40 → r+39" item), edit the Phase 2
  plan's text too (it is on main after Task 2.2).
- [ ] **Step 2:** `/usr/bin/grep -c "⚑ corrected (Phase 2, 2026-11)" docs/deimos/*.md` — the count equals the number of
  items in the list (write the number into the commit message).
- [ ] **Step 3:** one review leg: for each note, open the cited address in the committed dump
  (`ghidra/deimos/Deimos_pef.decompiled.c`, blocks `// ==== FUN_xxxxxxxx @ … ====`) or the listing
  (`ghidra/deimos-proj/disasm-review3-all.txt`) and confirm the sentence; report any it cannot confirm.
- [ ] **Step 4:** commit `docs(deimos): Phase 2 bank corrections (<n> notes)`; STATE one line.

## Wave 2b (a fresh worktree from main after Task 2.2)

### Task 2.4 — C12: the entity update, the world update, the entity draw (⚑ MAJOR, two legs; alone in its wave)

The contract is the Phase 2 plan's C12 section with its ⚑ amendment folded in; the anchors below are the branch tip's
(line numbers may drift by the fix round; re-find by name).

**Files:**
- Create `Deimos/Core/Sources/DeimosCore/Units/EntityUpdate.swift` (`extension GameState`: `updateEntities`)
- Create `Deimos/Core/Sources/DeimosCore/Game/UpdateWorld.swift` (`extension GameState`: `updateWorld`)
- Modify `Deimos/Core/Sources/DeimosCore/Draw/EntityDraw.swift:199-223` (`entry` stays; add `playerCommands`; keep
  `playerOps` as a wrapper calling it — C18b deletes it)
- Modify `Deimos/Core/Sources/DeimosCore/Units/Rules.swift:184-204` — delete the private `ruleWithinRangeOfPlayer` and
  `ruleNearestActivePlayerDistance` and route rule #17 through `Units/Motion.swift:35` `nearestActivePlayer(to:)` /
  `:50` `playerWithinRange(_:range:)` (one nearest-player helper, the amendment)
- Create `Deimos/Core/Tests/DeimosCoreTests/EntityUpdateTests.swift`; modify `Tests/DeimosCoreTests/EntityDrawTests.swift`
  (5 existing kept)

**What C12 calls (all exist on the branch; the entity step order is `FUN_10033850`, dump block at
`ghidra/deimos/Deimos_pef.decompiled.c:30665`, listing `10033850..100345d8`):**

| Step (listing) | Call |
|---|---|
| per-tick player cache (`10033894..100339c4`) | `Combat/Collision.swift:72` `playerCollisionCache()` |
| spawn-in countdown; state particles; state sound (AllowOnlyOneInstance = not playing, census-asserted) | fields on `Entity`; `ParticleSystem.emit`; `SoundPlay.record` into `cues` |
| timer (`10033c58..10033d70`, re-read the state) | `Units/StateTimer.swift:25` `stepStateTimer(_:now:)`, `:53` `removeByStateMachine` |
| pause flag (`10033d70`) | `Units/StateTimer.swift:70` `pausesScrolling(_:)` → `scroll.pause()` / `resume()` (`Game/ScrollState.swift:93/98`) |
| animation (`10033d8c`) | `Units/Animation.swift:24` `stepAnimation(_:now:)` |
| rules (`10033db0`) | `Units/Rules.swift:60` `applyRules(_:now:)` |
| visibility/tint/scale ramps, size, blink | the `GameObject` ramp helpers already used by C9/C14 |
| hittable (`10033ea0`) | `Combat/Collision.swift:97` `updateHittable(_:)` |
| **read the state now — `st0` (r18 at `10033e08`)** | `world.entities[i].stateIndex` before the controller |
| owner copy (`10033f58`), destruct-if-scrolling +0x352 (`10033f5c`) | `Units/OwnerLinks.swift:89` `copyFromOwner(_:state: st0)` |
| motion → delete/destroy outcome | `Units/Motion.swift:70` `updateMotion(_:now:) -> StateEntryOutcome`; act on it |
| integrate + cull (false → silent delete: +0xcb = 1, +0xd9 = 0xff) | `Units/Motion.swift:278` `integrateAndCull(_:margin:)` |
| lock/link/orbit with `st0` | `Units/OwnerLinks.swift:78` `followOwner(_:state: st0)` |
| rotation gate (`10015b64`) then spawn sets (`10015b6c`) | `Units/Animation.swift:75` `rotationGate(_:now:)`; `Units/SpawnSets.swift:34` `runSpawnSets(_:now:)` |
| player collision with `st0` (`10034068..10034314`; ram redirects to the owner when the state has passHitsToOwner, `10034228`) | `Combat/Collision.swift:120` `collideWithPlayers(_:state: st0, cache:…)` |
| motion blur (the `R(Min, Max)` draw before the interval test) | `Effects/MotionBlurPool.swift:74` `emit` |
| crosshair lock (`100343ac..100344e8`; the `FUN_1003bab0(h, 1)` call site is **MED** — record the condition in the doc comment or STOP) | `Weapons/WeaponHandler.swift:109` `setCrosshairLock(_:)` |
| obstacle (`100344ec..1003456c`) | `Combat/Collision.swift:166` `collideWithObstacles(_:)` |
| entity ↔ entity gate (`10034580`) with `st0` | `Combat/Collision.swift:182` `entityCollisionStep(_:state: st0, now:)` |
| the sweep | `Combat/Removal.swift:38` `sweepDeleted()` |

**Added by the audit (rulings 1·25, 2·15, 2·26, 3·1, 4·1, 4·2, 4·15, 4·17, 5·3):**
- the entity loop iterates with `Units/EntityWorld.swift:160` `Walk` (re-reads both counts; an entity appended during
  the pass is visited by it — `100345a0`/`100345c0`); `testUpdateStepOrder` appends an entity mid-update and asserts
  it is visited;
- the state-sound step (`10033c3c`, sound-music §5): `SoundPlay.record` into `cues` with its one pitch draw, per
  entity per tick, `AllowOnlyOneInstance` = not playing; the order test counts the draw;
- `GameObject` gains `lastStampTime` (+0x90; init 0 by `FUN_10012650` at `1001273c`; written by every terrain-path
  sprite stamp at `100132a4`) — C12 is alone in its wave, so it may add the field (invariant 13); the group draw's
  terrain branch (`10034b28..10034b5c`) stamps entities whose `drawToTerrain` (+0x36) is set (bomb craters `bocr`, tank
  tracks `tatr`), and `Combat/Removal.swift:242-246` `terrainStamp` tests `lastStampTime < now` instead of "always
  true"; **new test** `testDrawPassStampThenSweepSameTick` (a crater stamped by the draw pass and swept in the same
  tick draws a normal sprite the second time; at game time 0 the sweep stamp is also refused);
- leg 1 re-reads `FUN_10012650`'s store list (`10012674..1001273c`) and confirms `Entity` reset's keep-list;
- the dedupe: delete `Rules.swift:184-203`, route rules #8/#9 through `playerWithinRange` (the `range != 0` guard
  stays at the dispatch as at `100157d0`);
- the "Reached Motion Blur Limit" message: when `MotionBlurPool.emit` returns `.postLimitMessage`, post `(text, 1, 1,
  0)` through `MessageQueue.post` (`10046ef4..10046f04`);
- struck: "the player ram also redirects to the owner" — already built at `Combat/Collision.swift:145-153`.

`updateWorld(inputs:log:)` = `FUN_10006b50` in the order of the plan's Bank correction 4 (dump block at line 4222):
input clear → console-open test → ISp read → `p1Active` → notices → debris → particles → blurs → players
(`Player/PlayerUpdate.swift:28` `updatePlayer(_:input:)`) → score bar → game over (`Game/LevelEnd.swift:51`
`gameOverStep`) → scroll step (`ScrollState.swift:80` `step()`) → level end (`LevelEnd.swift:73` `levelEndStep(atEnd:)`)
→ accuracy tally (`Game/Tallies.swift:126`) → coin bonus (`:250`, `:276`) → entities (`updateEntities`) → pause/resume
(`1000703c`/`10007048`). `groupCommands(hOffset:)` = `FUN_100345f0` (dump block at line 31166): per group a shadow
pass then a sprite pass; entities with +0x36 set target the terrain buffer (layers 0–1). `playerCommands` =
`FUN_100298c0` incl. the coin-tally text (`Tallies.swift:353` `tallyTextRequest()`).

- [ ] **Step 1: failing tests first** (names verbatim from the Phase 2 plan): `testUpdateStepOrder` (a synthetic entity
  records the order above through `log`; plus the census assertion: every state with `AllowOnlyOneInstance` has sound
  `none`) · `testUpdateWorldOrder` · `testMidControllerPausesScroll` (le07 filtered to `01m1`: created **1660** at
  (134, −64); pause state **1840**; top frozen at **1279** for 1841…2640; **1278** at 2641; level end **3918**; bound
  4,200) · `testBridgeControllerPausesAtTop346` (filtered to `01b1`: created **2543**; `tapu` at (480, 140) heading 285
  at 2583; S1 at **2773**; frozen from 2774 at **346**) · `testCrosshairLock` (as read; leg 1 re-derives) ·
  `testGroupShadowThenSpritePass` · `testPlayerCommandsAndCoinTallyText` · `testBlurEmittedEveryTickWithZeroInterval`.
  Run `swift test --filter EntityUpdateTests --scratch-path "$S/build-c12"`: all fail for "no such method".
- [ ] **Step 2: implement** `EntityUpdate.swift` with the step order as the doc comment, each step citing its address;
  `UpdateWorld.swift`; `EntityDraw.playerCommands`; the Rules.swift deletion.
- [ ] **Step 3: G2** = previous + 9, 0 failed; G6 (the files above plus `Units/Entity.swift` for the field and
  `Combat/Removal.swift:242-246` for the stamp test); G7.
- [ ] **Step 4: commit** `DeimosCore: entity update in FUN_10033850 order + sweep, world update in FUN_10006b50 order,
  entity group draw incl. the terrain branch + lastStampTime, player commands with the coin-tally text; 9 tests`.
- [ ] **Step 5: two review legs.** Leg 1 (listing/dump): re-derive the step order from the dump block at line 30665 and
  the two controller timelines by hand (the `01m1` numbers above from `le07`'s placement y 1395 and its timers 180 /
  800); leg 2 (spec/tests/seams): every amendment item present (st0 into four calls, one nearest-player helper, the
  silent delete, the crosshair-lock condition recorded), G6 clean, bounds on every loop.

### Task 2.5 — C18a: `DeimosSession` Phase 2 — the loop, film playback, pause (⚑ MAJOR, two legs; alone)

**Files:**
- Modify `Deimos/Core/Sources/DeimosCore/Game/DeimosSession.swift` (whole file; 255 lines on the branch — the Phase-1
  loop, kept as the shape: `init` → `levelStart` → `pass` = `beginFrame` → `tick` → `drawWorld` → `endFrame`)
- Modify `Deimos/Core/Sources/DeimosCore/ScoreBar/ScoreBarState.swift` (`levelStart` / `update` take `sector:` and pass
  it to `scoreBarIcons(sector:)`, `Weapons/WeaponHandler.swift:268`); retire `Player.swift:232` `sector` (its last
  reader is `ScoreBarState`; `WeaponHandler.swift:285` `scoreBarIcons()` goes with it)
- Tests: `Tests/DeimosCoreTests/DeimosSessionTests.swift` (11, re-pointed, names kept), new
  `Tests/DeimosCoreTests/FilmPlaybackTests.swift`, `Tests/DeimosRenderTests/LevelOneFrameTests.swift` (6, goldens
  re-derived and recorded with the HectorKit + Classics SHAs), `Tests/DeimosCoreTests/TestWorld.swift` (its `tick` calls
  `scoreBar.update(players:sector:)`)

**Contract** (Phase 2 plan C18a + its amendment): the session holds a `GameState` (`Game/GameState.swift`), the frame
controller, the console (`Game/Console.swift`) and key state; every existing public property (`gameTime`, `appeared`,
`sector`, `rng`, `running`, `scoreBar`, `scroll`, `players`) stays as a forwarding accessor. `init` = `FUN_100051a0`
set-up (seed = `start.film?.seed ?? seed`; sector from the film's level; `GameState.film` **and** `flags.filmPlaying`
set together) then `FUN_100064d0`: music `[.play(ammu, loop: true), .stop]` when not a film (S9.4), then
`MusicCue.level(int pref 1)` (A2 review m4); players' level start (`Player/PlayerLife.swift:31`); `levelResetEntities`
(`GameState.swift:71`); the mask load; `Units/LevelObjects.swift:25` `levelStartEntities`; load pass (`:81`); `no01`
at (208, 240); black fill; score bar; first terrain blit; `FrameKeys.startSession` (`Game/FrameKeys.swift:74`).
`pass(keys:ticks:)`: `FrameKeys.beginFrame` (`:99`; console open withholds input only on tick frames) → tick: appear
check (level music `.play(mu03, loop: true)` then the fade, not in a film) → `updateWorld` (Task 2.4) → level complete
(`Game/LevelEnd.swift:125` `levelCompleteStep`, with `FrameKeys.levelTransitionReset` `:89` where `FUN_10007170` runs)
→ game time + 1 → drain `tickOps` → draw world (groups → blurs → players → tally text → notice → score bar) → film
banner (format 38, not on the pass that ends the film) → end frame (messages → FPS counter `:246` → console → flush
0–1 → terrain → flush 2–5 → `.particles` → flush 6–15 → limit → present) → `FrameKeys.endFrameWrapper` (`:192`): pause
= halt index, `incl`, `MusicCue.pause`, `.pauseWait(.gameScreen)`; `PauseScreen.musicAfterWait` goes **first in the
next pass's music**. Film: inputs from the film (C14's `readPlayerInput`); the session ends when `film.finished` or
any key is held. Session end (not film): `haltEffectsAt` = current index, `MusicCue.stop`.

**Added by the audit (rulings 1·15, 1·24, 4·11, 4·19, 5·1, 5·2, 5·open):**
- the level start calls, in `FUN_100064d0`'s order (leg 1 reads `100064d0..10006984` and records it): the accuracy
  counters' reset (`Game/TallyState.swift:59` `reset()` = `FUN_10007280`, the ground-count reset = `FUN_10007150`),
  then each in-game player's `Player/PlayerLife.swift:31` `playerLevelStart` (which resets the coin tally);
  `testLevelStartDrawsAndOrder` asserts the tally is clean and the ground counts are 0 after `init`;
- the pass **moves** `game.cues` (`Game/GameState.swift:40`) into the `PassOutput` (`sounds`, `music`,
  `haltEffectsAt`) and clears it — one holder; `testCapsLockPassSequence` asserts the halt index survives the move
  and that a second pass starts empty;
- `MusicCue.level(int pref 1)` is the first music cue after `[.play(ammu), .stop]` at a non-film start (asserted in
  `testLevelStartDrawsAndOrder`);
- the mask load: `MediaMask` from the level's media TGA as a tight row-major array; the load test asserts
  `cells.count == width × height` (the index rule of `Combat/MediaGate.swift:19` depends on it);
- every end-of-level, notice, message, console, FPS and tally draw step has its slot in the pass (audit 5·2's list);
  the tally text (`Game/Tallies.swift:364`) is drawn after the players and before the notice (`FUN_10007070`, dump
  line 4446);
- `Player.sector` (`Player/Player.swift:232`) retired with the Phase-1 session; `WeaponTests.swift:312` re-pointed.

- [ ] **Step 1: failing tests first** (names verbatim): `testLevelStartDrawsAndOrder` (non-film start seeded 0x469c2:
  one draw after `init` = 1446; `no01` at (208, 240); music `[play(ammu), stop]`) · `testAppearStartsLevelMusic`
  (game time 2: `.play(mu03, loop: true)` before `.fade`; a film emits no music) · `testFilmInputsAndEnd` (inputs only
  in state 4; frames + 1 input ticks then end; bound frames + 200) · `testReplayBanner` · `testDrawAndEndFrameOrder`
  (`tickOps` before draw world; `.particles` between the flushes) · `testCapsLockPassSequence` (notice drawn, present,
  halt index before `incl`, `.pauseWait(.gameScreen)` last) · `testLevelCompleteEndsFilmSession` ·
  `testSessionEndHaltsAudio`. Re-point the 11 `DeimosSessionTests` (`testInitOps`, `testSteadyPassOrder` gain the new
  ops; `testDeterministicReplay` asserts a different seed changes the outputs by the first spawn) and the 6
  `LevelOneFrameTests` (oracles mask every drawn command's rect; `HeadlessRun` gains `init(film:)` and steps
  `.pauseWait` as a no-op).
- [ ] **Step 2: implement** the session as the contract; keep every listing address in the doc comments as the Phase-1
  file does.
- [ ] **Step 3: G2** = previous + 8, 0 failed (counts of the re-pointed suites unchanged: 11, 6, 7); G3; G5; G6; G7.
- [ ] **Step 4: commit** `DeimosCore: DeimosSession Phase 2 — full level start, update/draw/end frame in the original
  order, film playback, pause; Phase-1 session and frame tests re-pointed; 8 tests`.
- [ ] **Step 5: two review legs.** Leg 1 re-derives the loop order from `FUN_100051a0` (`10005738..10005ae4`) and
  `FUN_10030bc0` (`10030bec..10030dc4`) and re-derives the six frame goldens with its own compositor; leg 2 checks the
  forwarding accessors, the one sector source, the pause music order, the film-end rules, bounds.

### Close of wave 2b
- [ ] G1 (370 executed, 4 skipped as recorded), G2 = **335 / 0 / 0**, G3, G5, G7 at the merge head on main.
- [ ] STATE, DECISIONS as-built notes under D31, handoff, memory; the chip for Wave 3 (C18b ∥ H2 first).

---

## Wave 3 — the rest of Phase 2 (cards; expand from the Phase 2 plan's sections when the wave opens)

| Card | Files | Acceptance |
|---|---|---|
| C18b | delete `Player/PlayerPhase1.swift`; `EntityDraw.playerOps` removed; `PlayerPhase1Tests` (7) and `TestWorld` call `updatePlayer`; `EarlyReplayTests.testEarlyDemo01Report` | +1; `bsgr` group at game time 77 at (371, −64); `01m1` created at 1660 |
| H2 | `DeimosHost/{DeimosDriver,HeadlessRunner,FilmReplay,ReplayTrace}.swift`; `Package.swift` (DeimosHost → DeimosAudio); `DriverTests` kept + `ReplayHarnessTests` | +8 (the plan's eight names); the driver feeds each pass's `sounds`/`music`/`haltEffectsAt` to `DeimosAudioSink.apply` at pass begin (audit 1·24 — today nothing calls `apply`); `.resume` only after Caps Lock up; music stays paused across a suspend during the wait |
| H3 | `deimos-replay` executable; `DeimosReplayTests` (own data locator) | G4 bundle 3; the G4 line; D31.10 miss path |
| A3 | `project.yml` (+ DeimosAudio); `Deimos/App/{DeimosController,DeimosMain}.swift` | G5; DEBUG counters rise in a 30-second launch (launched only with Ben's say-so: it opens a window) |
| F1 | conditional: fixes as `fix(<task>)` under that task's Files | G2 + G4 re-run after each |
| A4 | `Deimos/WHAT-TO-EXPECT.md`; stage to `~/Desktop` | G9 boots; **STOP for Ben** (gate 2 card = the Phase 2 plan's) |

## Phase 3 — the campaign (cards for its own plan)

| Card | What | Proof |
|---|---|---|
| P3.1 level transition | `levelCompleteStep` runs the fade to black (host op), `FrameKeys.levelTransitionReset`, `FUN_100064d0` for sector + 1 inside the same `GameState`; sector 13 → `none` → session end | a two-level headless run: game time resets, levels started = 2, `flags.sector` = 2 |
| P3.2 carry/reset table | lives, next-life score, score carry; coins reset; weapons re-picked (`FUN_1003af90`); dead players stay out; invulnerability as read (Q5) | tests per row of level-scroll-objects §8's table |
| P3.3 two players | key set 2, duo start positions, shared view shift, two-player score bar | de02–de04 are one-player; two-player by tests + Ben |
| P3.4 finale | `noal` → `12gc` → `miof`/`aieg` chain; 1,200-frame tally wait; mission bonus; `G+0x0d` | the loose-ends-session §5.3 timeline (HIGH) |
| P3.5 replays | `deimos-replay --all` gates: de02 116,180 @ 8,357; de03 57,520 @ 10,058; de04 24,670 @ 5,649 | G4-style bundle |
| P3.6 stage | the campaign in the app; gate 3 card | Ben plays through |

## Phase 4 — the front end (cards)

Boot and logos · main menu · level select (+ #62 flash) · scores + name entry · credits · attract mode + Last Film
save · prefs file + configuration dialog (DITL 190) + controls window (DITL 191, Q8) · gamepad (Q-E) · mouse in
`HeldKeys`. Proof: per-screen goldens, the cold-start timeline, Ben's gate 4.

## Phase 5 — Windows + release (card)

`Deimos/Windows` on HectorSDL (Ferazel's Phase W shape); drawn dialog; brother's test build; notarized DMG + zip.

---

## Self-review (the seat, after writing)

- Spec coverage: §4's left-over list ↔ Tasks 2.4, 2.5 and the Wave 3 cards ✅; §5 ↔ the Phase 3–5 cards ✅; §7's
  rulings ↔ Tasks 2.1 (ruling 1), 2.3 (ruling 2), 2.2 (Q-A), G1 (ruling 4) ✅.
- Placeholders: Task 2.1's content is the audit's rulings table by design (the audit precedes execution) ✅.
- Names: `updateEntities`, `updateWorld`, `playerCommands`, `groupCommands`, `levelCompleteStep`,
  `levelTransitionReset`, `startSession`, `endFrameWrapper`, `nearestActivePlayer`, `playerWithinRange` — all exist on
  the branch or are the Phase 2 plan's names ✅.
