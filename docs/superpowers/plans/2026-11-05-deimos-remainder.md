# Deimos Rising — the remainder — implementation plan (2026-11-05; made self-contained 2026-11-08)

> **This file is the authority for the remaining work; the earlier plans and the audit are history.** Every task still
> to do is written here in full, with the audit's corrections already in its text. The design it builds is
> `docs/superpowers/specs/2026-11-05-deimos-remainder-design.md` (referenced by section heading only).
>
> House method: `~/Developer/Toolkits/fable-kit/orchestrator.md`. One `fk-implementer` and at least one `fk-reviewer`
> per task (two for ⚑ MAJOR), no `model` param — every subagent is Opus 5.5 by the agents' own pin (Ben's rule,
> 2026-10-07, restated 2026-11-05). Steps use `- [ ]` checkboxes.

**Goal:** finish Phase 2 (level 1 plays; the de01 demo-film replay is the machine gate) from where branch
`deimos-phase2` stopped, then the campaign, the front end and Windows, each as its own plan when its turn comes.

**Architecture (unchanged):** `DeimosCore` holds the whole simulation as one `GameState` value, and every game rule is
a method on it that takes entity or player indices; `DeimosRender`, `DeimosAudio` and `DeimosHost` are thin shells
around it; only `Deimos/App` touches AppKit. The next wave joins the pieces already built (C12: the per-tick entity
and world update; C18a: the session loop) once the audit's fix round has landed and the research bank is corrected.

**Tech stack:** Swift 6.4 / Xcode 27 beta, SwiftPM tools 6.0, XCTest, xcodegen; HectorKit as a local path dependency
(`../../../HectorKit` from `Deimos/Core`, i.e. the `.claude/worktrees/HectorKit` symlink in a worktree), built against
HectorKit **main** from now on (Ben's ruling, 2026-11-05).

---

## Verification model (read first)

| Rule | What it means here |
|---|---|
| **Machine gates close alone; Ben closes the honesty gate** | every task names its gate and expected number below; "done" is phrased "machine gates green; Ben's gate pending" |
| **Numbers from your own run** | never relay a subagent's count; re-run G2 at the merge head yourself |
| **Reviewers run things** | each review leg runs the task's tests on its own `--scratch-path` and re-derives two or three rules from the dump or listing; a diff-only review is not a review |
| **Diagnosis before dispatch, to file:line** | every task below carries anchors; "investigate and fix" is never a subagent task |
| **STOP on any unexpected number** | report it; never edit an expectation — for the replay gate, a miss follows the miss path under G4 below, never a changed number |
| **Scope fence + diff audit** | `git diff --name-only <base>..HEAD` ⊆ the task's Files; an extra file is scope creep until proven a call site |
| **Explicit-path commits, trailer** | never `git add -A`, never `git stash`; `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>` on every commit |
| **Cap** | 300k of the seat's own context (orchestrator.md §5); waves 2a and 2b are one session each; say the meter before each dispatch |
| **Bounded tests** | every loop names `maxPasses` / a bound and fails on it (G11); own `--scratch-path` per agent |

### Gates (copy the commands from the code block; the table holds the expected values)

| # | Gate | Expected |
|---|---|---|
| G1 | HectorKit zero-skip at the checkout Classics builds against | `executed 370` on kit main ef2c341 (366 passed + 4 skipped — the 4 Aki 1.1 census tests skip because `HECTORKIT_DATA_AKI11` is not a directory on this machine; a kit-side data path, not a Deimos matter; record it, do not "fix" it in this lane) |
| G2 | `Deimos/Core` suite without `DeimosReplayTests` | the ladder total below, then `0` |
| G3 | census unchanged | the `data-census.md` diff against the merge base is empty (the census test inside G2 also compares the file's body with the census output) |
| G4 | de01 replay (from H3) | `DeimosReplayTests` 3 passed / 0 failed, and the CLI's last line `de01 le07 seed 0x469c2: score 25050 at read 4809 (end: <reason>) PASS` — rules under "G4 — the replay gate" |
| G5 | apps build | `** BUILD SUCCEEDED **` for Deimos, Aki, BubbleTroubleX (after `xcodegen generate`) |
| G6 | scope fence | changed paths ⊆ Files |
| G7 | layering | the grep prints nothing (`import Synchronization` is allowed — stdlib, Windows-safe) |
| G9 | staged app boots (A4 only) | a pid; clean quit; no new crash report naming the app |
| G10 | clean tree | `git status --porcelain` without `??` prints nothing |
| G11 | no hangs | every test that runs a driver, a world loop or a mixer names an explicit bound (`maxPasses`, `maxIdleCalls`, a fake-clock cap, `maxFrames`) and `XCTFail`s on reaching it; a hung test fails the task |

```sh
WT=/Users/andiyar/Developer/Ambrosia-Classics/.claude/worktrees/inspiring-cannon-e97ccd   # wave 2a Task 2.1; later tasks use the main checkout or a fresh worktree from main
S=<your scratchpad>
# G1
HECTORKIT_TEST_LOG="$S/hk.log" /Users/andiyar/Developer/HectorKit/tools/check-zero-skip.sh 2>&1 | tail -n 1
# G2
cd "$WT/Deimos/Core" && swift test --scratch-path "$S/build-<task>" --skip DeimosReplayTests > "$S/dm-<task>.log" 2>&1
/usr/bin/grep -cE "^Test Case '.*' (passed|failed|skipped) \(" "$S/dm-<task>.log"; /usr/bin/grep -cE "^Test Case '.*' (failed|skipped) \(" "$S/dm-<task>.log"
# G3
git -C "$WT" diff --stat "$(git -C "$WT" merge-base HEAD main)" -- docs/deimos/data-census.md
# G4  (from H3 on)
cd "$WT/Deimos/Core" && swift test --scratch-path "$S/build-replay" --filter DeimosReplayTests > "$S/g4.log" 2>&1
/usr/bin/grep -cE "^Test Case '.*' passed \(" "$S/g4.log"; /usr/bin/grep -cE "^Test Case '.*' (failed|skipped) \(" "$S/g4.log"
swift run --scratch-path "$S/build-replay" deimos-replay de01 | tail -n 1
# G5
cd "$WT" && xcodegen generate && for s in Deimos Aki BubbleTroubleX; do xcodebuild -scheme "$s" build 2>&1 | tail -n 1; done
# G6
git -C "$WT" diff --name-only <task base>..HEAD
# G7
/usr/bin/grep -rnE "^import (AppKit|UIKit|SwiftUI|CoreGraphics|CoreText|ImageIO|AVFoundation|QuartzCore|HectorGraphics|HectorShell)" "$WT/Deimos/Core/Sources/DeimosCore" "$WT/Deimos/Core/Sources/DeimosRender" "$WT/Deimos/Core/Sources/DeimosHost" "$WT/Deimos/Core/Sources/DeimosAudio"   # add "$WT/Deimos/Core/Sources/deimos-replay" from H3 on
# G9  (A4 only; opens a window — muted, and only with Ben's say-so)
open "$WT/out/Deimos/Deimos Rising.app"; sleep 8; pgrep -x "Deimos Rising"; osascript -e 'quit app "Deimos Rising"'; ls -t ~/Library/Logs/DiagnosticReports | head -3
# G10
git -C "$WT" status --porcelain | /usr/bin/grep -v '^??'
```

**Test ladder (G2, cumulative):** branch tip **313** (measured 2026-11-05) → Task 2.1 fix round **318** (five new
tests; nine existing tests strengthened keep their names) → Tasks 2.2 and 2.3 unchanged → C12 **+9 = 327** → C18a
**+8 = 335** → C18b **+1 = 336** → H2 **+8 = 344**. H3 adds 3 to the separate G4 bundle (`DeimosReplayTests`), so
G2 stays **344**. Re-pointed older tests keep their names and counts: `PlayerPhase1Tests` 7, `DeimosSessionTests` 11,
`LevelOneFrameTests` 6, `EntityDrawTests` 5.

### G4 — the replay gate, and the miss path

Demo films can predate the code or data they ship with (the Bubble Trouble lesson). Here the four films de01–de04
were saved (ZIP times 2001-12-03 13:39–14:02) **after** every game-data entry the replay reads (newest 2001-12-02
16:11; only the string lists are newer); the binary is 1.0.6 (2004-01-02), so code drift from 1.0 to 1.0.6 is the
remaining risk.
1. **PASS** = player 1's decoded score **at the instant the replay's film read consumes byte index 4808** (cursor 4808
   → 4809) is 25,050. That is exactly what the recorder stored: `FUN_10009830` is called from `FUN_1002a3a0` at
   `1002a42c`, step 3 of `FUN_10028170` — mid-tick, before player 2, the score bar, the tallies (`10006f58`,
   `10006ff4`) and the entity update (`1000702c`) of that tick. `FilmCursor.score(player: 0, atRead: 4808)` returns
   it (the read at cursor 4809 is one tick later). The CLI also prints the end-of-pass score and the end reason.
2. **Landing.** H3 lands `DeimosReplayTests` as the gate (a separate bundle, excluded from G2 by `--skip`, so G2 stays
   green). If G4 is red, H3 still merges with the gate recorded **"pending trace"** in STATE, and the seat opens F1.
   Never edit the expectation; never skip the test.
3. **Triage (F1).** `deimos-replay de01 --trace "$S/de01.csv"` writes one row per tick. The seat (or an implementer it
   briefs) finds the **first divergence tick T**: the earliest trace event a reviewer cannot justify from the bank or
   listing (an unexplained death, a spawn at an unexpected row, a kill whose score is not the unit's `score_INT ×
   multiplier`, a draw-count step at a site the bank does not list, the scroll freezing at an unexpected top).
   Reported with every run: end reason, cursor at session end vs 4,809, player 1 deaths (tick, cause), score at reads
   1,000 / 2,000 / 3,000 / 4,000 / 4,809, game time of the level end, accuracy %, money at the coin tally, multiplier
   history. Each fix is committed as `fix(<task>): …` by an implementer working under **that task's Files**, reviewed
   by one Opus leg, G2 + G4 re-run.
4. A divergence is a **bug** until two Opus reviewers have each re-read the listing at every address the event at T
   depends on and agree the replica follows 1.0.6 exactly. Only then may it be recorded as **"de01 predates the 1.0.6
   code"**: A4 stages with the gate "pending trace", Ben watches `-film de01` against his memory and longplays (gate
   card line 13), DECISIONS records his ruling, and `testDemo01…` is re-specified to pin the ruled divergence tick and
   the replica's own score (self-derived, re-derived by a second leg). de02–de04 run with `--all` as information;
   agreement or disagreement across the four is evidence for the ruling.

**What the machine does NOT prove** (Ben's ear and eye, on the gate card): pitch direction, music loudness, the
volume-key behaviour, the 24→16 sprite colour cut, particle colours, last-ulp agreement of the start-up trig tables
(the replay is the only machine witness), whether the original could tear (it could; whole-frame presents).

### Standing rules for every implementer (the ones that bind the remaining tasks)

1. **Layering.** DeimosCore: Foundation + HectorResources + HectorAudio. DeimosRender: Foundation + DeimosCore.
   DeimosAudio: Foundation + DeimosCore + HectorAudio + Synchronization. DeimosHost: Foundation + DeimosCore +
   DeimosRender + DeimosAudio (from H2). `deimos-replay`: Foundation + the four. `Deimos/App` alone imports AppKit /
   HectorShell / AVFoundation. Windows traps: no `String.Encoding.macOSRoman`, no `UserDefaults` below the App.
2. **Transcribe, don't reinvent.** Every behaviour cites its bank section or listing address; if the bank and the
   listing disagree, the listing settles it — STOP and report. **No implementer edits `docs/deimos/*`** except Task
   2.3's; a correction found later goes in the task's report and the seat appends it at the Phase 2 close (A4 card).
3. **No modern affordances** (CLAUDE.md). Phase 2's only additions are the ◇ stand-ins listed below; each is on the
   gate card.
4. **Data in git, tests never skip.** A missing file is a FAILURE naming the path. Each test target has its own data
   locator / static asset cache; the new `DeimosReplayTests` declares its own.
5. **Every RNG draw at its original site, in the original order.** Per tick: the `FUN_10006b50` call order (C12's
   world-update contract). Per entity: the `FUN_10033850` order (C12's entity-update contract). Per spawned member:
   the `FUN_10035cd0` order. A draw is made even when its result is discarded (refused requests, muted sound). The
   pre-seed `FUN_10046580(400, 2000)` at the top of `FUN_100051a0` stays unmodelled (it precedes `srand`).
6. **Float fidelity.** `Float` wherever the listing has `fadds/fsubs/fmuls/fdivs`; `fmadds`/`fmsubs`/`fnmsubs` are
   fused (one rounding) — `addingProduct`/`fma`, never `a*b + c`; `fctiwz` = truncate toward zero; tests pin float
   results by **bit pattern** (or a literal that round-trips to the same bits).
7. **Seams are additive only.** Nothing public is renamed or removed except where a card says so; every existing
   public `DeimosSession`/`DeimosDriver` property used by tests stays (as a forwarding accessor if its storage
   moves). Adding a `RenderOp` case updates every exhaustive switch in the same commit.
8. **`GameState` storage rule.** Rule methods are `extension GameState` methods that take entity/player indices and
   re-read `world.entities[i]` / `players[i]` after any call that may mutate the world; **no `inout Entity` (or
   `inout Player`) is held across a `GameState` call** (exclusivity, and spawns append mid-pass). A task alone in its
   wave may add a stored field (listed in its report); a task in a parallel wave that finds a field missing STOPs and
   reports — the seat adds it as a micro-commit first.
9. **Landmines.** `swift test` prints no package total — count `^Test Case` lines (G2). SwiftPM rejects a target with
   no sources — `Package.swift` grows task by task (H2 then H3, never in parallel). Quote every path. Confirm a new
   DECISIONS number against `main` at commit (numbers collide). Decode sprite groups and sounds once per test
   process; never decode all 2,554 frames or a whole music track in a unit test. Markdown tables escape `|` — copy
   commands from code blocks only. `grep` and `tail` may be shell functions in agent shells: use `/usr/bin/grep`;
   there is no `timeout` binary (use a perl alarm). Reviewers run mutants in the foreground.
10. **Listing hazards.** The committed dump is `ghidra/deimos/Deimos_pef.decompiled.c` on main (blocks
    `// ==== FUN_xxxxxxxx @ … ====`; the branch worktree lacks it — read main's copy); the listing is
    `ghidra/deimos-proj/disasm-review3-all.txt`; decoded units are in `~/Developer/Ghidra/deimos/proj/data/Game/unde/`.
    Static initialisers rewrite the spawn-request templates before `main`: `0x100e64b0` / `0x100eb41c` / `0x100ecd14`
    have **+0x24 = −1** at runtime; the draw template clip is {0,0,480,416} — use runtime values. Lists are appended
    at the tail and iterated by re-reading the count: an entity or group created during a pass is processed by the
    same pass; a deleted entity is only flagged (+0xcb) and reaped after the entity loop. `AllowOnlyOneInstance`
    (`10033bf8–10033c14`) would make a logic decision depend on the audio thread; it is dead in shipped data (6
    states, all with sound `none`), so **Core treats it as "not playing"**, guarded by a census assertion (C12).

### Phase-2 stand-ins (◇; each on the gate card; each replaced by a named later phase)

1. **Level complete** (`flags.levelComplete` with a player alive) ends the session like the film branch of
   `FUN_10007170`; the driver starts a new game at sector 1 (Phase 3: fade to black, next sector).
2. **Game over** (`nogo`; the running flag clears at game time `gameOverStart + 111`) ends the session; new game at
   sector 1 (Phase 4: scores, menu).
3. **Esc** ends the session; new game at sector 1 (Phase 4: menu). The Esc latch clears on a release seen by **any**
   `idle` call (H2).
4. **Level-start music:** the original stops the level-select music `ammu` at level 1's load and starts `mu03` at the
   appear tick; with no level select, a non-film session emits `[.play(ammu, loop: true), .stop]` at load (net
   silence) — Phase 4 makes `ammu` real.
5. **Film launch argument** `-film deNN` (A3) plays a demo in the app (Ben's fallback oracle for G4) with the
   original's film rules (`REPLAY` banner, no level music; **corrected 2026-11-14, wave 2b:** a film ends when it runs
   out, on Esc through the begin frame (`10005904`), on level complete or game over — **other keys do not end it**; the
   original also ends it on the mouse button, see 8). The menu music `inmu` that the original
   keeps playing under a film is absent until Phase 4's attract mode replaces this argument.
6. **Prefs live in memory only** — F6 (pref 5), `FPS` (pref 9), `supermunki` (pref 11) and the volume (int pref 0)
   persist across ◇ restarts (H2) but not across launches (Phase 4 writes the prefs file).
7. **One player** in the app; two-player games are Phase 3 (the rules are tested for both indices).
8. A film is not ended by the mouse — `HeldKeys` carries no mouse (Phase 4). **Corrected 2026-11-14:** `FUN_10048e60`
   tests the mouse button and nothing else (`10048e6c`); it is the original's only "skip the film" input besides Esc.

### The review, measured (2026-11-05, the seat's own runs)

| Suite | Passed / failed / skipped |
|---|---|
| branch `Deimos/Core` vs HectorKit main ef2c341 | 313 / 0 / 0 |
| branch `Deimos/Core` vs the pinned HectorKit e595472 (through a `HectorKit`-named symlink to the `deimos-k2` worktree) | 313 / 0 / 0 — identical |
| main `Deimos/Core` (= `Deimos/DeimosCore`, a symlink) | 189 / 0 / 0 |
| HectorKit zero-skip at e595472 | executed 328 = 324 + 4 skipped (Aki 1.1 data), 0 failed |
| HectorKit zero-skip at ef2c341 | executed 370 = 366 + 4 skipped (same), 0 failed |

Branches and worktrees: `deimos-phase2` (44 commits past merge base cc84fb0, tip adea0e3; pushed; main has touched
nothing under `Deimos/` since), worktree `.claude/worktrees/inspiring-cannon-e97ccd`; the Ferazel worktrees are not
ours (do not touch); HectorKit worktree `~/Developer/HectorKit-worktrees/deimos-k2` at e595472 (merged into kit main;
removable).

### Done before this plan (on branch `deimos-phase2`; not repeated here)

K2 (kit pull-stream voice), C0, A1, C13, C16, A2, R4, C7, C8, C9, C10, C14, C11a, C15, C19, C11b, C17 — 313/0/0; the
three review legs wave 2.6 still owed are discharged by the 2026-11-05 audit, whose corrections are Task 2.1 below.

---

## Waves

| Wave | What | Where | Sessions |
|---|---|---|---|
| 1 Audit | five read-only Opus reviewers over the 44 commits against the spec | done in the re-planning pass | — |
| **2a** | 2.1 the fix round → 2.2 merge `deimos-phase2` to main → 2.3 bank corrections | branch worktree, then main | 1 |
| **2b** | 2.4 C12 → 2.5 C18a | a fresh worktree from main | 1 |
| 3 | C18b ∥ H2 → H3 ∥ A3 → (F1) → A4 → Ben's gate 2 | cards below | 1–2 |
| 4 | Phase 3 campaign | cards; its own plan after Phase 2 closes | — |
| 5 | Phase 4 front end | cards | — |
| 6 | Phase 5 Windows + release | cards | — |

Each session runs one wave and starts the next session at its close (CLAUDE.md, sessions chain), unless a question
only Ben can answer blocks.

---

## Wave 2a

### Task 2.1 — The fix round (discharges the three owed review legs)

Three implementers, one per family, disjoint files, own `--scratch-path`; one review leg each that runs the tests and
re-reads every listing address the fix cites. Work in the branch worktree (`git branch --show-current` =
`deimos-phase2` before every commit; never reset or switch it). Line numbers are the branch tip's (2026-11-05);
re-find by name if they moved. All paths below are under `Deimos/Core/`.

**Family A — world, motion, state.**
Files: `Sources/DeimosCore/Units/{EntityWorld,Rules,SpawnSets,Motion}.swift`,
`Tests/DeimosCoreTests/{EntityWorldTests,SpawnTests,MotionTests,StateMachineTests}.swift`.
- [ ] `EntityWorld.swift:47` — `freeHint` default **0** (the pool reset stores 0 at `10038450`; every reachable world
  already has 0).
- [ ] `EntityWorld.swift` doc comment on the data byte the old note flagged — it says the byte is 0; the original stores
  **1** there. Doc line only, no behaviour change (seat's ruling 2026-11-08; the old follow-up note had no home).
- [ ] `Rules.swift:172-178` `isOnScreen` — write the two x tests as the listing's negated compares (`!(x < 0)`,
  `!(x > W)`, `10016bf4..10016c3c`) so a NaN x passes as in the original; y tests unchanged.
- [ ] `SpawnSets.swift:40` — add `k < st.spawnSets.count` to the loop guard (it indexes without a bound today).
- [ ] `Motion.swift:25-27, 34, 45` — doc lines: "two draws unless trunc(MaxSpeed) = 0 (no shipped cyclic state is
  below 1: 40 cyclic states, max speeds 1, 2, 4)"; "0.0 is the original's initial distance, `0x100d6354`" (not a
  placeholder).
- [ ] Tests, failing first: `testPoolCapAndHint` also pins +0xb8, +0x100…+0x114, +0x138 left stale by the reset (only
  +0x134 is pinned today) · **new** `testSpawnDrawSitesInOrder` (a unit with `initialScalePercentTolerance ≠ 0`, a
  random-axis flee code and an armed spawn set in state 0, cyclic start: the draw sequence size → appears → placement
  → scale tolerance (`10014b14`) → flee (`10014d90`) → arming (`10017cb0`) → group delay → cyclic, against an in-test
  LCG; 17 shipped units draw the tolerance) · **new** `testTypeExistsRefusal` (a deleted, unreaped member still
  refuses after the size draw) · `testLoadPassBand` pins the per-level literals 2, 1, 2, 1, 3, 0, 0, 0, 0, 1, 2, 1
  (today it mirrors the code) · `testCullBoundsMode1` with unequal half sizes hw 10, hh 14 ·
  `testShurikenControllerThreeGroups` pins 1000, 1125, 1245 for seed 0x469c2 (today it reads the rates from the code).
- [ ] G2 (family filter) = previous + 2; commit `fix(audit): world/motion/state — free hint 0, NaN-x on-screen test,
  spawn-set bound, motion docs; spawn draw-order and type-exists tests`.

**Family B — combat, player, weapons.**
Files: `Sources/DeimosCore/Combat/Removal.swift`, `Sources/DeimosCore/Weapons/WeaponHandler.swift`,
`Sources/DeimosCore/Player/Player.swift` (doc only), `Tests/DeimosCoreTests/{PlayerTests,DestructionTests}.swift`.
- [ ] `Removal.swift:199, 201, 220, 228-230` — inline `removeMemberStub` as `removeMember(..., byPlayer: false)` and
  delete it; `Removal.swift:68` doc line: the deletion template (`r2+0x50ec`) equals the shared template (the static
  initialisers leave the seven spawn templates differing only by +0x24 = −1, which `SpawnRequest.template` carries).
- [ ] `WeaponHandler.swift:201` — `resetHandler(levelStart:sector:)` with `sector` **required**, no default 0
  (`1003b0dc` reads G+0x14); update the callers.
- [ ] `Player.swift:228-232` — doc: `sector` is retired by C18a; `scoreBarIcons(sector:)` is the API.
- [ ] Tests, failing first: **new** `testOwnerDestructionPrecedesDeathSpawn` (a player-owned unit with
  `canBeDestroyedOnOwnerDestruction` dies, with its draws, before the death spawn — `10027e70..10027e74`) ·
  `testDeathOrder` called with `now ≠ gameTime`, asserting the state-entry time · `testDestroyOrder` replays the RNG
  on a copy (as `testMediaGateWater` does) and pins the bonus draw · `testPlatformSevenBombHits` reads `plbo`'s
  `damage_FLOAT` and asserts 0.4f instead of hard-coding it.
- [ ] G2 (family filter) = previous + 1; commit `fix(audit): combat/player/weapons — removeMemberStub inlined, sector
  required in resetHandler, docs; owner-destruction order test, death/destroy/platform tests strengthened`.

**Family C — audio, end of level, seams.**
Files: `Sources/DeimosAudio/{DeimosAudioEngine,EffectMixer}.swift`, `Sources/DeimosCore/Seams/HeldKeys.swift`,
`Tests/DeimosAudioTests/MusicEngineTests.swift`, `Tests/DeimosCoreTests/LevelEndTests.swift`.
- [ ] `DeimosAudioEngine.swift:83-86` — `init(effects: consuming EffectMixer)` (a caller that kept its mixer could
  force a copy-on-write on the audio thread); `EffectMixer.swift:74-82` — move `@discardableResult` below the doc
  comment; `HeldKeys.swift:11` — the stale "C19 pins the codes" doc line names `Console`'s pinned codes instead.
- [ ] Tests, failing first: `testEngineIsAPullSource` asserts the preload count 96 (an internal count accessor) ·
  **new** `testTallyTextRequest` (the accuracy tally's text record, `Game/Tallies.swift:353`: nil at state 0 and at
  alpha 32; at state 2 with alpha 29: format 0x35, +0x10c 15, +0x10d 1, +0x110 0, +0x114 = alpha — dump
  `FUN_10007d60`) · `testLevelEndSequenceOrder` / `testGameOverStopsOnStartPlus111` / `testCoinBonusSteps` assert the
  spawn positions (208, 240) for `nogo` and `nole`, (105, 248) and +70 stacked for `p1mc`/`p2mc` · **new**
  `testAllLevelsNoticeAtSectorTwelve` (sector = levelsStarted = 12 through `levelEndStep` → `.notice(noal)` and
  `allLevels`) · `testLevelCompleteClearsRunningInFilm` posts a message and opens the console before, and asserts both
  cleared after (`FUN_100302e0`).
- [ ] G2 (family filter) = previous + 2; commit `fix(audit): audio/level-end/seams — consuming mixer init, attribute
  order, HeldKeys doc; tally-text and all-levels tests, end-of-level positions asserted`.

- [ ] **Close:** the seat re-runs G2 at the branch tip: **318 / 0 / 0**; G6 per family; G7; STATE one line.

### Task 2.2 — Merge `deimos-phase2` into main

**Files:** none of Deimos's; `docs/STATE.md`, `docs/DECISIONS.md` (the conflict resolution only).

- [ ] **Step 0:** the branch worktree must be clean before the merge and its removal: `git -C "$WT" status
  --porcelain` prints nothing (the seat commits the line-1 "superseded" note on the October Phase 2 plan on the branch,
  explicit path, before Task 2.1 — `git worktree remove` refuses a dirty worktree).
- [ ] **Step 1:** in the **main checkout** (`/Users/andiyar/Developer/Ambrosia-Classics`, on `main`; never in the branch
  worktree, never `git stash`): `git merge --no-ff deimos-phase2`. Expected conflicts: `docs/STATE.md` (keep main's
  header and the other games' lines; take the branch's Deimos Phase 2 paragraph, then edit it to the post-fix-round
  numbers) and possibly `docs/DECISIONS.md` (D31 is free on main: D30 is followed by D32 — keep the branch's D31 block
  in numeric place; nothing else conflicts).
- [ ] **Step 2:** G2 at the merge head in the main checkout (`--scratch-path "$S/build-merge"`): **318**, 0 failed. G3.
  G5 (Deimos, Aki, BubbleTroubleX build after `xcodegen generate` — the first app build against current HectorKit; a
  failure here is a kit-drift finding: STOP and report, do not patch the kit from this lane).
- [ ] **Step 3:** commit the merge with the message `Merge deimos-phase2: Phase 2 waves 2.0–2.6 + the audit fix round
  (G2 318/0/0)`. Do not push (Ben pushes).
- [ ] **Step 4:** remove the worktree (`git worktree remove .claude/worktrees/inspiring-cannon-e97ccd`) and delete the
  local branch only after Step 2 is green; leave `origin/deimos-phase2` for Ben to delete after the push.

### Task 2.3 — Bank corrections (docs)

**Files:** `docs/deimos/{sound-music,messages-notices-console,particles-debris-blur,loose-ends-combat,units-movement,
spawn-and-waves,weapons-projectiles,damage-health-death,micro-wave-2026-10-06,engine-loop,bosses,timing-frame,
level-scroll-objects,player-physics,scoring-bonuses,sprite-geometry-draw,data-census}.md`, `docs/deimos/INDEX.md` (one
line per note). Main checkout, after Task 2.2.

**The list (53 notes).** Each is one `⚑ corrected (Phase 2, 2026-11)` note in the named file and section, citing the
address given. Where a row names a second file in brackets, that file gets a one-line cross-reference without the
marker (so the marker count stays one per row). "MED → HIGH" means raise the section's confidence tag in the same note.

| # | File, section | Correction (address) |
|---|---|---|
| 1 | level-scroll-objects §7 (+ units-movement §2.1) | cull, MED → HIGH: `FUN_10012ca0(e, m, 1)` keeps the entity iff `x + hw ≥ −m`, `x − hw ≤ W + m`, **`y ≥ −m` (no half-height)**, `y − hh ≤ H + m` (W 416, H 480, float compares of int conversions; `10012d48..10012e38`); mode 0 (`10012e3c..10012f00`) uses `x + hw ≥ C+0xc`, `x − hw ≤ W + 32`, `y + hh ≥ C+0`, `y − hh ≤ H` (C = `*(r2−0x7240)`) |
| 2 | damage-health-death §5.3 | death order, MED → HIGH (`10027e74..10028150`): `FUN_10034b90` → `death_Spawn_ID` request (`10027f18`) → shields zeroed if not in game → +0x204/+0x208/+0xd1 = 0 → **displayed shield and power set to 0.0** (`FUN_10031710`/`FUN_10031760` at `10027f4c`/`10027f5c`, value `0x100d6fc8` = 0.0 — new) → coin loops 50/10/5/1 (`10028044…100280ec`) → money 0 → state 3 → +0xce → multiplier check and reset |
| 3 | micro-wave-2026-10-06 §3.9 | player draw: `FUN_100298c0` continues after the sprite pass (`10029930..100299a0`): if coin-tally state +0xd8 ≠ 0 and alpha +0xe0 < 32 → text format 30 (`li r3,0x1e`; `plmc`) with the text at +0xec, BlendAmount = alpha, +0x10c = 15, +0x10d = 1, +0x110 = 0, Loc_Y += +0x1f8, drawn by `FUN_1000d380` (state 4 only); corroborates INDEX #62's 0-based format indexing (30 = `plmc`, 27/28 = `lsca`/`lscf`) |
| 4 | engine-loop §3 (+ bosses §2.1) | `FUN_10006b50` call order, HIGH: `10006b7c` input clear → `10006b84` console-open test → `10006b94` ISp read → `10006bb0` P1 state == 4 → `10006bd0` notices → `10006bd8` debris → `10006be0` particles → `10006be8` blurs → `10006c14` players (loop) → `10006c34` score bar → `10006c4c…10006d6c` game over (`nogo`) → `10006d9c` scroll step → `10006dd4…10006f44` first level-end tick (`noal`/`nole`, `FUN_10027de0`, `FUN_100072c0`) → `10006f58` accuracy tally → `10006f7c…10006ff4` coin bonus → `1000702c` entities → `1000703c`/`10007048` scroll pause/resume |
| 5 | timing-frame §6 (+ engine-loop §8; INDEX #14) | button slots, cite only: the guide's Default Controls (Fire Air = Command, Select Air = Space, Fire Ground = Option, Esc, Caps Lock, F6, Tilde) pin slots 4/5/6 = fire air / fire ground / select; film census: the select bit (bit 6) appears in de02 (15 ticks), de03 (26), de04 (3) and never in de01 (one air weapon) |
| 6 | engine-loop §7 (+ data-census, **header only**) | film provenance: `Game.pak` ZIP times de01 2001-12-03 13:39, de02 13:51, de03 13:58, de04 14:02; newest `unde` 2001-12-02 16:11 (`07e1`), `leve` 12:47 (`le09`), `flli`/`idli` 2001-11-12, `wede`/`plde` 2001-10-14; only the `stli` string lists are newer (`cred` 2002-05-01); binary 1.0.6 (2004-01-02); `Local/film/Last Film[last].film` is byte-identical to de01 |
| 7 | bosses worked example (+ player-physics worked example) | float32 values: platform shields 2.5999999, 2.1999998, 1.7999998, 1.3999999, 0.9999999, 0.5999999, 0.1999999, then −0.2000001 computed but **0.0 stored** (the damage clamp); hold-up y 325.19998 at tick 2, 298.40002 / 290.60004 / 282.80005 at ticks 6–8, rest 252.00006 not 252.0 |
| 8 | engine-loop §9 (+ units-movement §5.5, §8.1) | RNG consumers missing from §9's per-entity order: cyclic motion `FUN_10016fe0` (`10017024`, `10017054`, two per tick per cyclic entity) and the random frame `FUN_10015930` (`10015a0c`, per animation step with `ContinuousFrameRandomisation`); in le07 reached by 30 cyclic coin states and the `plsh` player-shield states |
| 9 | sound-music §3.2 (lines in §3.2 and the worked example) | predictor and mix clamp is −32768…32767, not ±32767 (`100d33b4`, `100d3440`, `100d3470`) |
| 10 | sound-music §2.2 | IMA difference = (16m+8)·step>>6 = ⌊(2m+1)·step/8⌋, not the reference shift-sum (nibble 7 at step 7 → 13, not 11) |
| 11 | sound-music §2.2 | "differences from a reference ima4 decode are rounding-level": per sample yes, but with no re-sync they accumulate over the whole sound; the drop/swap rows MED → HIGH (`FUN_100d1d90`) |
| 12 | sound-music §2.2 | the 2·P tail is not a held, slowly decaying DC level: nibble 0 adds ⌊step/8⌋ per sample while the index falls, so the level creeps upward until step < 8, then holds |
| 13 | sound-music (mixer section) | position accumulator/prev reset to 0 at every 1024-frame block (`100d32e4`/`ec`): the fraction is lost; early exit on buffer full leaves `last` stale |
| 14 | sound-music (mixer section) | FixMul/FixDiv truncate, overflow → 0xFFFFFFFF; the voice-id counter starts at 1 (`100d1520`); divisions are unsigned (`divwu`) |
| 15 | sound-music §2 (sample loading) | bytes = SSND size − 8 − offset (`100d2674`), not COMM packets; drop k%17; nibble swap 0xF0F0/0x0F0F; the ima gate also requires COMM sampleSize 16 (`100d1db4`) |
| 16 | sound-music (voice insertion) | priority compare unsigned, gain sum signed; a full list drops the 16th |
| 17 | sound-music §6 (music) | the music level m starts at 0x100 (`0x100e072e`), fade 0x100 — confirmed in the data image |
| 18 | sound-music §6.3 | loop: the shipped tracks' SSND body = packets × 68 exactly; carry vs reset is identical for all three tracks (its NOT RESOLVED item has no audible consequence) |
| 19 | sound-music NOT RESOLVED (+ INDEX #51) | closed for shipped data: all 96 effects are preloaded and every gaso and SoundRecord id (and `publ`) is among them |
| 20 | messages-notices-console §4.3 | with delay > 0 the notice is drawable on the tick its delay hits 0, but the start reset and sound come one tick later (`10018360`) — dead in shipped data |
| 21 | messages-notices-console §4.3 | the notice tick stores lastTick BEFORE the active test (store `10018350`, test `10018358`) |
| 22 | messages-notices-console §2.4 | pass 2's j counts normal entries only (`1002e134`); the strip blend is fade + 16 for messages, while the notice adds its alpha to the template value |
| 23 | messages-notices-console §2.2 | uppercase = MSL `toupper`, which uppercases Mac Roman (class table `0x100f0f94` bit 0x40, map `0x100f1194`): 55 bytes change, 29 of them high bytes |
| 24 | messages-notices-console (console section) | the console reset clears the draw flag (the bank says sets); an unknown command is not saved for recall and plays no sound; up-arrow keeps old bytes past the end; the FPS draw never sets keep-template-clip |
| 25 | timing-frame (FPS monitor) | the FPS init writes 30 into the frame counter too, so the first window shows 30 + N, not 31 |
| 26 | particles-debris-blur §4.4 | blur 50/10: in the list for 6 draw passes, 5 visible (the 6th has visibility 0.0 and is skipped by `FUN_10012f20`'s ≤ 0 test, `10012f40..48`) |
| 27 | particles-debris-blur §4.2 | the motion-blur limit (`10046ef4`) posts "Reached Motion Blur Limit", type 1 |
| 28 | particles-debris-blur (pool reset) | `FUN_10046d30` clears all 1000 slots (25 × 40) |
| 29 | particles-debris-blur §2.9 | the stamp offsets +2 core / +4 fringe are relative to r6 = particle slot + 4 (`10043c80`) |
| 30 | units-movement §2.3 | trig build: sin/cos argument fl32(0x3c8efa35·i) → double → float; atan = trunc(atan(0.01i)·57.2957795) with the truncated constant → atan[100] = 44, up-right heading 46; sqrt = (float)sqrt((double)(float)n); all entries far from rounding edges |
| 31 | loose-ends-combat §1.3 | the round-trip quirk headings number 34, not 30 |
| 32 | micro-wave-2026-10-06 §3.7 | the pool reset sets the free hint to 0, not −1 (`10038450`); the PERM path overwrites PERM's position; `headingTo` of the same point → 270 |
| 33 | units-movement §3 | the reset `FUN_100142f0` does NOT reset +0xb8, +0x100…+0x114, +0x134, +0x138 (the velocity copies stay) |
| 34 | loose-ends-combat §4.2 | "zeroes +0xac…+0xda" is too loose — the exact stores are `100143c8..10014478` |
| 35 | units-movement §3 | field widths: +0xd8, +0xd9, +0x118 are sign-extended bytes; +0x134 float, +0x138 int, +0xdc float, +0xe0 int; PERM's +0x9c/+0xa0 are garbage until its first request; +0xbd is the cheated flag |
| 36 | units-movement (helpers) | `FUN_10042bf0` unit-vector helper: the x term is trunc(dx)·dx |
| 37 | spawn-and-waves §3.2 | the state-0 entry at spawn does **not** call `FUN_10033600` at `10014d74` — the spawning branch jumps to `10014d7c` (`10014c84 b`); `FUN_10035cd0` calls it once, after state entry (`10035fb4`); the state entry at spawn reads its "old state" from a zeroed header (harmless) |
| 38 | spawn-and-waves §4 | `FUN_100146f0` calls `FUN_10033600` only when not spawning, the new state is not LockToOwnerLoc, **and +0xa0 ≠ −1** (`10014d64..10014d6c`) |
| 39 | spawn-and-waves (type-exists check) | the type-already-exists check counts deleted-but-unreaped members |
| 40 | spawn-and-waves §2.5 | the rotated offset uses facing + HeadingDegrees when SetHeading (`10015f8c…10015fb4`), not facing alone |
| 41 | units-movement §5.7 | the right-edge bounce uses the full scaled width +0x24 (`10016e28`), not half |
| 42 | units-movement §1 | lock/link/orbit (`1003401c..54`) is gated on the state read before the motion controller (r18 from `10033e08`) |
| 43 | units-movement §8.1 | the random-frame draw at `10015a0c` happens even when the stopped flag is set, if its gate passes (`10015a08..10015a18`) |
| 44 | units-movement §6 | with no player, the flee target is stored as (0, 0) |
| 45 | damage-health-death (on-hit state change) | `FUN_10014f10` keeps the old state pointer after an on-hit state change (glow, sound and collision spawn use the pre-change state); `FUN_10036cf0` reads the counts once |
| 46 | weapons-projectiles (overload) | the overload flash ramps the glow at +0x58, not +0x214 (+0x214 is only ever 0.0); a refused indicator spawn stores uninitialised stack at +0xb8 — the replica stores −1 (disclosed) |
| 47 | weapons-projectiles worked example 4a | the release stream goes idle at r+39 (the level ≤ 0 test `1003c35c..64` precedes the timing `1003c368`), not r+40 |
| 48 | weapons-projectiles (select) | in sector 1, select always plays `wesw` (gaso 0x12, 0x4b, 100, 1) |
| 49 | scoring-bonuses §6.4 | tally waits `timer + N < now` → N + 1 ticks; state 0 returns done; state 6 pays on its first tick (the timer holds the level-end time), nothing left → state 7 with no wait; states 8/10 stay done; state 9 alpha 0, entering 10 alpha 32 + text "" |
| 50 | scoring-bonuses §6.4 | raise states 1–5, 7, 9 from MED to HIGH (dump lines 4679–4945) |
| 51 | scoring-bonuses §6.4 table | `moco` (gaso 20) plays on the exits of states 1, 2 **and 3**; state 8's mission sound is **priority** 100 as well as volume 100 (`FUN_10047670(id, 100, 100, 0)`, dump line 4907) |
| 52 | scoring-bonuses §6.5 | the coin tally also plays `moco` on the exits of states 2 and 3 (dump lines 23472, 23486); `FUN_10029a10` in state 6 is called even when the player is out of the game (only the money −1 is gated) |
| 53 | sprite-geometry-draw §3.2 | the +0x90 "last stamp time" is initialised to 0 by the object init `FUN_10012650` (`1001273c`) and written only by the terrain-path sprite stamp (`100132a4`); a state with `stateDrawToTerrain` makes the draw pass stamp every tick (`10034b54`), so a same-tick sweep stamp fails the test |

- [ ] **Step 1:** one implementer appends each note in its file's section with the listing address (or dump line)
  given; one INDEX line per note (the INDEX append rule). **`data-census.md`: the note goes above the file's first
  `---` rule only** — everything after that rule must stay byte-equal to the census tool's output (the census test in
  G2 compares them). The October phase plan is history and is not corrected.
- [ ] **Step 2:** `/usr/bin/grep -c "⚑ corrected (Phase 2, 2026-11)" docs/deimos/*.md` — the counts sum to **53**;
  G2 at main = **318 / 0 / 0** (the census test reads `data-census.md`); G3 is not run here (this task edits the file's
  header on purpose).
- [ ] **Step 3:** one review leg: for each note, open the cited address in the committed dump or the listing and
  confirm the sentence; report any it cannot confirm.
- [ ] **Step 4:** commit `docs(deimos): Phase 2 bank corrections (53 notes)`; STATE one line.

---

## Wave 2b (a fresh worktree from main after Task 2.2)

### Task 2.4 — C12: the entity update, the world update, the entity draw (⚑ MAJOR, two legs; alone in its wave)

**Precondition (leg 1 and the implementer, before code):** read `FUN_10033850` end to end (`10033850..100345d8`; dump
block at `ghidra/deimos/Deimos_pef.decompiled.c:30665`) and record the step order with addresses as the doc comment;
read the `FUN_1003bab0(h, 1)` call site and its condition (weapons-projectiles §2.8 rates it MED — record the condition
in the doc comment, or STOP); `FUN_100345f0` (`10034a98–10034b5c`; dump line 31166); `FUN_100298c0`
(`100298c0..100299b8`); `FUN_10006b50` (dump line 4222); `FUN_10012650`'s store list (`10012674..1001273c`) to confirm
the `Entity` reset's keep-list.

**Files** (under `Deimos/Core/`):
- Create `Sources/DeimosCore/Units/EntityUpdate.swift` (`extension GameState`: `updateEntities`)
- Create `Sources/DeimosCore/Game/UpdateWorld.swift` (`extension GameState`: `updateWorld`)
- Modify `Sources/DeimosCore/Draw/EntityDraw.swift:199-223` (`entry` stays; add `playerCommands` and `groupCommands`;
  keep `playerOps` as a wrapper calling `playerCommands` — C18b deletes it)
- Modify `Sources/DeimosCore/Units/Rules.swift:184-204` — delete the private `ruleWithinRangeOfPlayer` and
  `ruleNearestActivePlayerDistance`; rules #8/#9 call `Units/Motion.swift:50` `playerWithinRange(_:range:)` and rule
  #17 `:35` `nearestActivePlayer(to:)` (one nearest-player helper; the two were proven equivalent on 200,000 cases).
  The `range != 0` guard stays at the dispatch, as at `100157d0`. `closestActivePlayer` in Spawn is a different
  function (`FUN_10005ed0`) and stays.
- Modify the `GameObject` declaration (`Sources/DeimosCore/Player/Player.swift`) — add `lastStampTime` (+0x90)
- Modify `Sources/DeimosCore/Combat/Removal.swift:242-246` `terrainStamp` — test `lastStampTime < now`
- Create `Tests/DeimosCoreTests/EntityUpdateTests.swift`; modify `Tests/DeimosCoreTests/EntityDrawTests.swift` (5
  existing kept)

**Contract — `updateEntities(log:) -> Bool` (returns the pause flag) = `FUN_10033850`.** The entity loop iterates with
`Units/EntityWorld.swift:161` `Walk` (it re-reads both counts, so an entity appended during the pass is visited by the
same pass — `100345a0`/`100345c0`). Per entity, in group order, these steps and calls (all exist on the branch):

| Step (listing) | Call |
|---|---|
| per-tick player cache (`10033894..100339c4`), once before the loop | `Combat/Collision.swift:72` `playerCollisionCache()` |
| spawn-in countdown (state start re-stamped while counting); state particles | fields on `Entity`; `ParticleSystem.emit` |
| state sound (`10033c3c`) | `SoundPlay.record` into `cues` with its one pitch draw, every entity every tick; `AllowOnlyOneInstance` = not playing (census-asserted) |
| timer (`10033c58..10033d70`, re-read the state after) | `Units/StateTimer.swift:25` `stepStateTimer(_:now:)`, `:53` `removeByStateMachine` |
| pause flag (`10033d70`) | `Units/StateTimer.swift:70` `pausesScrolling(_:)` → `scroll.pause()` / `resume()` (`Game/ScrollState.swift:93/98`) |
| animation (`10033d8c`) | `Units/Animation.swift:24` `stepAnimation(_:now:)` |
| rules (`10033db0`) | `Units/Rules.swift:60` `applyRules(_:now:)` |
| visibility/tint/scale targets and ramps, size, blink | the `GameObject` ramp helpers already used by the particle and player code |
| hittable (`10033ea0`) | `Combat/Collision.swift:97` `updateHittable(_:)` |
| **read the state now — `st0` (r18 at `10033e08`)** | `world.entities[i].stateIndex` before the motion controller |
| owner copy (`10033f58`), destruct-if-scrolling +0x352 (`10033f5c`) | `Units/OwnerLinks.swift:89` `copyFromOwner(_:state: st0)` |
| motion → delete/destroy outcome | `Units/Motion.swift:70` `updateMotion(_:now:) -> StateEntryOutcome`; act on the outcome |
| integrate + cull (false → silent delete: +0xcb = 1, +0xd9 = 0xff) | `Units/Motion.swift:278` `integrateAndCull(_:margin:)` |
| lock/link/orbit with `st0` | `Units/OwnerLinks.swift:78` `followOwner(_:state: st0)` |
| rotation gate (`10015b64`, before the +0xc3 test) then spawn sets (`10015b6c`) | `Units/Animation.swift:75` `rotationGate(_:now:)`; `Units/SpawnSets.swift:34` `runSpawnSets(_:now:)` |
| player collision with `st0` (`10034068..10034314`; the ram already redirects to the owner when the state has passHitsToOwner, `10034228`, built at `Combat/Collision.swift:145-153`) | `Combat/Collision.swift:120` `collideWithPlayers(_:state: st0, cache:…)` |
| motion blur (the `R(Min, Max)` draw before the interval test) | `Effects/MotionBlurPool.swift:74` `emit`; on `.refused(postLimitMessage: true)` post "Reached Motion Blur Limit" through `MessageQueue.post(text:kind:uppercase:readout:)` with the original's arguments (type 1, 1, 0) (`10046ef4..10046f04`) |
| crosshair lock (`100343ac..100344e8`; the `FUN_1003bab0(h, 1)` call site — condition recorded or STOP) | `Weapons/WeaponHandler.swift:109` `setCrosshairLock(_:)` |
| obstacle (`100344ec..1003456c`) | `Combat/Collision.swift:166` `collideWithObstacles(_:)` |
| entity ↔ entity gate (`10034580`) with `st0` (the `FUN_10036cf0` scan) | `Combat/Collision.swift:182` `entityCollisionStep(_:state: st0, now:)` |
| after the loop: the sweep | `Combat/Removal.swift:38` `sweepDeleted()` |

**The terrain stamp time.** `GameObject.lastStampTime` (+0x90) is initialised to 0 (as `FUN_10012650` does at
`1001273c`) and written by every terrain-path sprite stamp (`100132a4`). C12 is alone in its wave, so it may add the
field. Two shipped units draw to terrain every tick — Bomb Crater `bocr` and Tank Tracks `tatr` (reachable in level 1
through plasma bombs) — so the group draw's terrain branch (`10034b28..10034b5c`) stamps entities whose
`drawToTerrain` (+0x36) is set, and `terrainStamp` refuses when `lastStampTime ≥ now` instead of "always true".

**`updateWorld(inputs:log:)` = `FUN_10006b50`**, in this order: input clear (`10006b7c`) → console-open test
(`10006b84`) → ISp read (`10006b94`) → `p1Active` = player 1 in state 4 (`10006bb0`; set before the player loop and
never reset within the tick) → notices (`10006bd0`) → debris (`10006bd8`) → particles (`10006be0`) → blurs
(`10006be8`) → players (`10006c14`, `Player/PlayerUpdate.swift:28` `updatePlayer(_:input:)`) → score bar (`10006c34`) →
game over (`10006c4c…10006d6c`, `Game/LevelEnd.swift:51` `gameOverStep`) → scroll step (`10006d9c`,
`ScrollState.swift:80` `step()`) → first level-end tick (`10006dd4…10006f44`, `LevelEnd.swift:73`
`levelEndStep(atEnd:)`) → accuracy tally (`10006f58`, `Game/Tallies.swift:126`) → coin bonus (`10006f7c…10006ff4`,
`Tallies.swift:250`, `:276`) → entities (`1000702c`, `updateEntities`) → scroll pause/resume (`1000703c`/`10007048`).
C18a's pass calls it.

**`groupCommands(hOffset:)` = `FUN_100345f0`:** per group a shadow pass, then a sprite pass; entities with +0x36 set
target the terrain buffer (layers 0–1) and stamp as above.

**`playerCommands(_:hOffset:floats:) -> [DrawCommand]` = `FUN_100298c0`** (every entity-draw builder returns
`[DrawCommand]`; C18a wraps them as `.draw`): the existing state-4 sprite pass, then the **coin-tally text**
(`10029930..100299a0`): if the player's coin-tally state (+0xd8) ≠ 0 and its alpha (+0xe0) < 32 → a text request in
format **30** (`plmc`) with the player's coin-tally text (+0xec), BlendAmount = alpha, +0x10c = 15, +0x10d = 1,
+0x110 = 0, Loc_Y += +0x1f8, drawn as `FUN_1000d380` draws. This is not the accuracy tally's text
(`Tallies.swift:353` `tallyTextRequest`, format 0x35), which C18a's draw world places after the players.

- [ ] **Step 1: failing tests first:** `testUpdateStepOrder` (a synthetic entity records the order above through
  `log`, incl. the state-sound pitch draw; an entity appended mid-update is visited; plus the census assertion: every
  state with `AllowOnlyOneInstance` has sound `none`) · `testUpdateWorldOrder` (the order above through `log`) ·
  `testMidControllerPausesScroll` (le07 filtered to `01m1`, via `updateWorld`: created **1660** at (134, −64); pause
  state **1840**; top frozen at **1279** for 1841…2640 (**800** ticks); **1278** at 2641; level end **3918**; bound
  4,200) · `testBridgeControllerPausesAtTop346` (filtered to `01b1`: created **2543**; `tapu` at absolute (480, 140)
  heading 285 at 2583; S1 at **2773**; frozen from 2774 at **346**) · `testCrosshairLock` (as read; leg 1 re-derives)
  · `testGroupShadowThenSpritePass` · `testPlayerCommandsAndCoinTallyText` (format 30, the fields above, nil when the
  state is 0 or alpha is 32) · `testBlurEmittedEveryTickWithZeroInterval` · `testDrawPassStampThenSweepSameTick` (a
  crater stamped by the draw pass and swept in the same tick draws a normal sprite the second time; at game time 0 the
  sweep stamp is also refused). Run `swift test --filter EntityUpdateTests --scratch-path "$S/build-c12"`: all fail
  for "no such method".
- [ ] **Step 2: implement** `EntityUpdate.swift` with the step order as the doc comment, each step citing its address;
  `UpdateWorld.swift`; `EntityDraw.playerCommands` / `groupCommands`; the `lastStampTime` field and the
  `terrainStamp` test; the Rules.swift deletion.
- [ ] **Step 3: G2** = previous + 9 = **327**, 0 failed; G6 (the Files above); G7.
- [ ] **Step 4: commit** `DeimosCore: entity update in FUN_10033850 order + sweep, world update in FUN_10006b50 order,
  entity group draw incl. the terrain branch + lastStampTime, player commands with the coin-tally text; 9 tests`.
- [ ] **Step 5: two review legs.** Leg 1 (listing/dump): re-derive the step order from the `FUN_10033850` block and
  the two controller timelines by hand (the `01m1` numbers from `le07`'s placement y 1395 and its timers 180 / 800);
  confirm `FUN_10012650`'s store list against the `Entity` reset. Leg 2 (spec/tests/seams): `st0` reaches all four
  calls (owner copy, follow, player collision, entity collision), one nearest-player helper, the silent delete, the
  crosshair-lock condition recorded, the blur-limit message, `Walk` iteration, G6 clean, bounds on every loop.

### Task 2.5 — C18a: `DeimosSession` Phase 2 — the loop, film playback, pause (⚑ MAJOR, two legs; alone)

**Precondition:** read `FUN_100051a0` (`10005738..10005ae4`: set-up, film branch `FUN_100069b0`, loop body, film
overlay `10005a1c..10005aa0` — the REPLAY banner is format **0x26 = 38**, GameString 9, +0x244 = 15, +0x245 = 1, +0x248
= 0, `10005a50..10005a9c`, **not drawn on the pass that ends the film**, `10005a48 → 10005aa4`), `FUN_100064d0`
(`100064d0..10006984` — leg 1 records the level-start call order), `FUN_10007070` (dump line 4446), `FUN_10030bc0`
(`10030bec..10030dc4`), `FUN_10009750`.

**Files** (under `Deimos/Core/`):
- Modify `Sources/DeimosCore/Game/DeimosSession.swift` (whole file; 255 lines on the branch — the Phase-1 loop, kept as
  the shape: `init` → `levelStart` → `pass` = `beginFrame` → `tick` → `drawWorld` → `endFrame`)
- Modify `Sources/DeimosCore/ScoreBar/ScoreBarState.swift` (`levelStart` / `update` take `sector:` and pass it to
  `scoreBarIcons(sector:)`, `Weapons/WeaponHandler.swift:268`); retire `Player/Player.swift:232` `sector` (its last
  reader is `ScoreBarState`; `WeaponHandler.swift:285` `scoreBarIcons()` goes with it) — one sector source,
  `flags.sector`, set from the film or the start
- Tests: `Tests/DeimosCoreTests/DeimosSessionTests.swift` (11, re-pointed, names kept), new
  `Tests/DeimosCoreTests/FilmPlaybackTests.swift`, `Tests/DeimosRenderTests/LevelOneFrameTests.swift` (6, goldens
  re-derived and recorded with the HectorKit + Classics SHAs), `Tests/DeimosCoreTests/TestWorld.swift` (its `tick`
  calls `scoreBar.update(players:sector:)`), `Tests/DeimosCoreTests/WeaponTests.swift:312` (re-pointed off
  `Player.sector`)

**Contract.** The session holds a `GameState` (`Game/GameState.swift`), the frame controller, the console
(`Game/Console.swift`) and key state; every existing public property (`gameTime`, `appeared`, `sector`, `rng`,
`running`, `scoreBar`, `scroll`, `players`, …) stays as a forwarding accessor (driver and frame tests read them).

`init` = `FUN_100051a0` set-up (seed = `start.film?.seed ?? seed`; sector from the film's level; players from the
film; `GameState.film` **and** `flags.filmPlaying` set together — `PlayerUpdate` yields no input when the flag is set
without a film), then `FUN_100064d0` in its order: music `[.play(ammu, loop: true), .stop]` when not a film
(stand-in 4), then `MusicCue.level(int pref 1)` as the next music cue (the engine starts at the pref-100 level, so the
session must send the real one); the accuracy counters' reset (`Game/TallyState.swift:59` `reset()` = `FUN_10007280`)
and the ground-count reset (`FUN_10007150`); each in-game player's `Player/PlayerLife.swift:31` `playerLevelStart`
(its draws; it resets the coin tally); `levelResetEntities` (`GameState.swift:71`); the scroll level start incl. the
mask load — `MediaMask` from the level's media TGA as a tight row-major array (`cells.count == width × height`; the
index rule of `Combat/MediaGate.swift:19` depends on it); `Units/LevelObjects.swift:25` `levelStartEntities` (+ the
pending list); the load pass (`:81`); `no01` (0 draws) at (208, 240); black fill; score bar; first terrain blit;
`FrameKeys.startSession` (`Game/FrameKeys.swift:74`).

`pass(keys:ticks:)`: `FrameKeys.beginFrame` (`:99`; console open withholds input only on tick frames, `1004aa20`) →
tick: appear check (level music `.play(mu03, loop: true)` then the fade; not in a film) → `updateWorld` (Task 2.4) →
level complete (`Game/LevelEnd.swift:125` `levelCompleteStep`, with `FrameKeys.levelTransitionReset` `:89` — the
`FUN_100302e0` pieces — where `FUN_10007170` runs) → game time + 1 → drain `tickOps` → draw world (groups → blurs →
players → **accuracy tally text** (`Game/Tallies.swift:364` `tallyTextCommands`, `FUN_10007070`) → notice → score
bar) → film banner (format 38, not on the pass that ends the film) → end frame (messages → FPS counter `:246` →
console → flush 0–1 → terrain → flush 2–5 → `.particles` → flush 6–15 → limit → present) →
`FrameKeys.endFrameWrapper` (`:192`): on pause = halt index, `incl`, `MusicCue.pause`, `.pauseWait(.gameScreen)`.
The pause pass's music ends at `.pause`; `PauseScreen.musicAfterWait` (`[.resume]`) goes **first in the next pass's
music** (that pass begins only after the host's wait and present — at most one frame late, inaudible).
`FrameKeysResult.volume` never becomes a gain cue (Ben's ruling, 2026-10-07: the volume keys do nothing audible, as on
Mac OS X). Every end-of-level, notice, message, console, FPS and tally draw step has its slot in the pass as listed.

**Cues: one holder.** The pass **moves** `game.cues` (`Game/GameState.swift:40`) into the `PassOutput` (`sounds`,
`music`, `haltEffectsAt`) and clears it; nothing else holds cues across passes.

**Film:** inputs from the film (`readPlayerInput`); the session ends when `film.finished` (checked after every draw) or
any key is held (**wrong — corrected 2026-11-14 by both review legs: keys do not end a film; see stand-ins 5 and 8;
as built the film ends on finished, Esc, level complete or game over**). **Session end (not film):** `haltEffectsAt` = current index, `MusicCue.stop`.

**Re-pointed (counts unchanged):** `DeimosSessionTests` (11 — `testInitOps` and `testSteadyPassOrder` gain the new
ops; `testDeterministicReplay` asserts a different seed **changes** the outputs by the first spawn);
`LevelOneFrameTests` (6 — oracles mask every drawn command's rect; goldens re-derived, recorded with the HectorKit +
Classics SHAs, re-derived by the second leg; `HeadlessRun` gains `init(film:)` and steps `.pauseWait` as a no-op).

- [ ] **Step 1: failing tests first:** `testLevelStartDrawsAndOrder` (non-film start seeded 0x469c2: after `init` the
  RNG has made one draw, `R(400, 2000)` = 1446; `no01` at (208, 240); music `[play(ammu), stop]` then
  `.level(int pref 1)`; the accuracy tally clean and the ground counts 0) · `testAppearStartsLevelMusic` (game time 2:
  `.play(mu03, loop: true)` before `.fade`; a film emits no music) · `testFilmInputsAndEnd` (inputs only in state 4;
  frames + 1 input ticks then end; bound frames + 200) · `testReplayBanner` (format 38 every film pass except the
  ending one) · `testDrawAndEndFrameOrder` (`tickOps` before draw world; the tally text after the players and before
  the notice; `.particles` between the flushes) · `testCapsLockPassSequence` (the pause pass: notice drawn, present,
  halt index before `incl`, `.pauseWait(.gameScreen)` last; the halt index survives the cue move and a second pass
  starts with empty cues) · `testLevelCompleteEndsFilmSession` (`sessionEnded` on the tick `levelComplete` is set in a
  film) · `testSessionEndHaltsAudio` (Esc: `haltEffectsAt` + `MusicCue.stop`). Plus a mask-load assertion
  (`cells.count == width × height`) inside `testLevelStartDrawsAndOrder`.
- [ ] **Step 2: implement** the session as the contract; keep every listing address in the doc comments as the Phase-1
  file does.
- [ ] **Step 3: G2** = previous + 8 = **335**, 0 failed (re-pointed suites keep 11, 6, 7); G3; G5; G6; G7.
- [ ] **Step 4: commit** `DeimosCore: DeimosSession Phase 2 — full level start, update/draw/end frame in the original
  order, film playback, pause; Phase-1 session and frame tests re-pointed; 8 tests`.
- [ ] **Step 5: two review legs.** Leg 1 re-derives the loop order from `FUN_100051a0` (`10005738..10005ae4`) and
  `FUN_10030bc0` (`10030bec..10030dc4`), records `FUN_100064d0`'s order, and re-derives the six frame goldens with its
  own compositor; leg 2 checks the forwarding accessors, the one sector source, the one cue holder, the pause music
  order, the film-end rules, bounds.

### Close of wave 2b
- [ ] G1 (370 executed, 4 skipped as recorded), G2 = **335 / 0 / 0**, G3, G5, G7 at the merge head on main.
- [ ] STATE, DECISIONS as-built notes under D31, handoff, memory; the next session's brief for Wave 3 (C18b ∥ H2
  first).

---

## Wave 3 — the rest of Phase 2

Shared files, one owner at a time: `Package.swift` (H2 → H3), `EntityDraw.swift` (C18b), `project.yml` (A3).

### C18b — minor — Phase-1 stub removal and the early de01 check (+1 → 336) — ∥ H2
- **Files:** delete `Sources/DeimosCore/Player/PlayerPhase1.swift`; `Sources/DeimosCore/Draw/EntityDraw.swift`
  (remove `playerOps`); `Tests/DeimosCoreTests/{PlayerPhase1Tests,TestWorld,EntityDrawTests}.swift`,
  `Tests/DeimosCoreTests/EarlyReplayTests.swift` (new).
- **Contract:** `PlayerPhase1Tests` (7) and `TestWorld` (used by ScoreBarStateTests, ScoreBarDrawTests,
  TextLayoutTests, EntityDrawTests) call `updatePlayer`; same numbers. **Early warning (not a gate):** run the de01
  session logic-only to game time 1,700 (bound 2,000 passes) and print a first-divergence report (deaths, draws per
  100 ticks, spawns by game time).
- **Tests (1):** `testEarlyDemo01Report` (asserts only data-driven facts that hold whatever the pilot does: the `bsgr`
  group is requested at game time **77** at (371, −64); `01m1` is created at **1660** — no unit can pause the scroll
  before it; prints the report).
- **Gate:** G2 = previous + **1**. **Commit:** `DeimosCore: remove the Phase-1 player stub and playerOps; early de01
  report; 1 test`. One review leg.

### H2 — ⚑ MAJOR — DeimosHost: driver Phase 2 + headless runner + replay trace (+8 → 344) — ∥ C18b
- **Files:** `Package.swift` (add `DeimosAudio` to the deps of `DeimosHost` and `DeimosHostTests`),
  `Sources/DeimosHost/{DeimosDriver,HeadlessRunner,FilmReplay,ReplayTrace}.swift`;
  `Tests/DeimosHostTests/{DriverTests,ReplayHarnessTests}.swift` (DriverTests: existing kept).
- **Surface:** `DeimosDriver.init(assets:prefs:rate:start:audio:)` (`audio: (any DeimosAudioSink)? = nil` keeps every
  Phase-1 test); `public struct HeadlessRunner` (logic-only or rendering; `init(assets:start:seed:prefs:)`,
  `init(assets:film:)`, `mutating func run(maxPasses:) -> ReplayResult`); `public struct FilmReplay` (`static func
  run(film:assets:trace:maxPasses:) -> ReplayResult`); `ReplayResult` (`endReason` `.filmEnd/.levelComplete/.gameOver/
  .bound`, `cursor`, `scoreAtRead4808: Int32?` from `FilmCursor.score(player: 0, atRead: 4808)`, `endScore`,
  `passes`); `ReplayTrace` (records a `TickTrace` row per ticked pass from the session's public state; CSV writer,
  fixed header).
- **Contract:** driver `pass(keys:ticks:)`; **each pass's `sounds` / `music` / `haltEffectsAt` go to
  `DeimosAudioSink.apply` when the pass begins** (today nothing calls `apply`; the original issues them inside the
  tick — at most one frame early, inaudible). **`.pauseWait(p)`** yields until an `idle` sees `capsLock == false`, then
  `present(p)`; the sink receives `.resume` only after Caps Lock goes up (the pass after the wait); across an app
  suspend/resume during the wait, music stays paused (the original's pause flag r2−0x617b blocks the resume handler
  `10023e7c`). Typed characters accumulate across `idle` calls into the next pass; the **Esc latch** clears when
  **any** `idle` sees Esc up; ◇ restarts keep the ended session's prefs (stand-in 6); level complete / game over end
  the session like Esc (stand-ins 1–3). `HeadlessRunner` (logic only unless asked to render; `maxPasses`),
  `FilmReplay` (seed/sector/players from the film), `ReplayTrace` (a row per ticked pass: game time, cursor, P1
  state/score/lives/shield/money/multiplier, draws, entities, groups, scroll top, paused, levelEnding).
- **Tests (8):** `testPauseWaitHoldsUntilCapsUp` (fake-clock cap 120 s; `.resume` reaches the sink only after Caps Lock
  up; a suspend/resume during the wait leaves music paused) · `testCuesRoutedAtPassBegin` (a recording sink sees each
  pass's cues once, in order, with the halt index) · `testTypedQueueAcrossIdleCalls` ·
  `testEscLatchClearsOnSubPassRelease` (fails on the Phase-1 driver) · `testPrefsSurviveRestart` (F6 then Esc → the
  carried prefs value has pref 5 set; asserted on the carried prefs, not mid level-start) ·
  `testHeadlessRunnerFromFilm` (de01 → sector 1, seed 0x469c2, 1 player) · `testFilmReplayEndsOnePastLastByte` (a
  synthetic 10-frame film ends after 11 input ticks, `.filmEnd`) · `testReplayTraceCSVHeader`.
- **Gate:** G2 = previous + **8** = **344**. **Commit:** `DeimosHost: driver Phase 2 (pause wait, audio cue routing,
  typed keys, Esc latch on any idle, prefs carry), HeadlessRunner, FilmReplay, ReplayTrace; 8 tests`. Two review legs.

### H3 — minor — `deimos-replay` and the de01 gate (G4 bundle 3)
- **Files:** `Package.swift` (executable `deimos-replay`, deps `DeimosHost`, `DeimosRender`, `DeimosAudio`,
  `DeimosCore`; test target `DeimosReplayTests`, deps `deimos-replay`, `DeimosHost`, `DeimosCore`),
  `Sources/deimos-replay/main.swift`, `Tests/DeimosReplayTests/{ReplayGateTests,ReplayTestData}.swift` (own data
  locator).
- **Contract:** `deimos-replay <film tag>… [--trace file.csv] [--frames dir --every N] [--all]` — committed data
  (`DEIMOS_DATA` overrides); per film the G4 line plus the triage progress numbers (G4 step 3); `--all` = de01–de04
  (de02–de04 print `INFO`). Exit 0 iff de01 passes.
- **Tests (3, G4 bundle):** `testDemo01ReachesScore25050AtRead4809` (G4: `scoreAtRead4808` = 25,050; `maxPasses`
  20,000) · `testReplayIsDeterministic` (two runs to game time 1,000 → identical trace hash) · `testCLISummaryLine`.
- **Gate:** G2 = **344 / 0**; G4 green, or recorded "pending trace" → F1 (G4 step 2); G7 incl. `deimos-replay`.
  **Commit:** `deimos-replay: film replay + per-tick score trace; the de01 gate (25,050 at read 4,809); 3 tests`. One
  review leg.

### A3 — ⚑ MAJOR — App: audio, typed keys, Caps Lock, film argument (no tests) — after H2
- **Files:** `project.yml` (the Deimos target gains `{ package: DeimosCore, product: DeimosAudio }`),
  `Deimos/App/{DeimosController,DeimosMain}.swift`.
- **Contract:** `DeimosAudioEngine` created at launch (failure → silent, like `FUN_10047160`'s non-fatal path) and
  attached with `ShellMixer.attachStream(_:)`; the driver gets it as `audio`; the stream is paused while the app is
  suspended (`setStreamPaused`). Key-down characters (no repeats) mapped to Mac charCodes per the console's table
  (NSEvent 0xF700-range arrows → 0x1C–0x1F; delete → 0x08; return → 0x0D) into `HeldKeys.typed`; Caps Lock into
  `capsLock`. ◇ `-film deNN` (stand-in 5).
- **Gate:** G5, plus machine-observable checks: a DEBUG-only counter of cues routed and frames rendered by the engine
  (the SDL audio-out `framesRendered` pattern), logged; a 30-second launch shows both counters rising and the
  `.pauseWait` path reached with Caps Lock simulated through `HeldKeys` in a DEBUG hook. **The launch opens a window
  and plays sound: run it muted, and only with Ben's say-so.** Audible checks are Ben's (gate card). **Commit:**
  `Deimos app: audio through the kit stream voice, typed keys + Caps Lock, -film argument; project.yml DeimosAudio`.
  Two review legs.

### F1 — conditional — replay triage (seat-owned; only if G4 is red)
G4 steps 3–4. Fix commits `fix(<task>): …` under that task's Files, one Opus leg each, G2 + G4 re-run after each.

### A4 — minor — Stage, the gate card, and the late bank notes
- **Files:** `Deimos/WHAT-TO-EXPECT.md` (and `tools/stage-deimos.sh` only if staging needs a change); `docs/deimos/*.md`
  + `docs/deimos/INDEX.md` for the bank corrections reported by C12 onwards (one `⚑ corrected (Phase 2, 2026-11)` note
  each, seat-run, separate commit `docs(deimos): Phase 2 late bank corrections (<n> notes)`).
- **Contract:** staging unchanged (`out/Deimos/`, then `~/Desktop`); WHAT-TO-EXPECT = what Phase 2 is and is not, the
  keys, the ◇ stand-ins above, the design's deviations (spec "Faithful, rulings, switches"), the G4 line (or "pending
  trace" with the F1 status), and the gate card below verbatim.
- **Gate:** G1 on HK main, G2 = **344 / 0**, G3, G4 (or pending trace), G5, G9 (muted, with Ben's say-so). **STOP for
  Ben.** **Commit:** `Deimos: Phase 2 staged — WHAT-TO-EXPECT (gate 2 card)`.

**The gate card (copy verbatim into WHAT-TO-EXPECT) — "does it play like Deimos"**

Open `~/Desktop/Deimos Rising.app`; play Mariner Valley; compare with a longplay. Each line: what you'll see or hear,
and what would be wrong.
1. **Enemies and ground targets** appear as the map scrolls: Buzzsaw waves, **five Bonus Stations**, four laser
   platforms, a pulse tank, geysers, a secret. Wrong: things popping in on screen (they enter 64 px above the top),
   ground units sliding against the map (they ride it).
2. **Two scroll stops.** About 61 s in, the map stops for ~27 s while Buzzsaw groups come down from the top; near the
   end it stops again ("Level 1 - Bridge") until you destroy every ground target on screen or ~27 s pass.
3. **Your ship** accelerates and drifts to a stop, banks, slides 32 px under the side borders, can't go above the top
   13 px.
4. **Ion Cannon:** tap = a pair of bullets + flash (max ~6 shots/s, each needs a fresh press); hold ~0.5 s =
   power-up charging (meter fills in 2 s), release = a stream of power shots; hold ~6.5 s = overload flashes and the
   ship blows up at ~8.3 s. **Plasma Bomb** (Option) flies 114 px up toward the crosshair 121 px ahead, then bursts;
   down at the bottom edge pulls the crosshair in. **Select** (Space) does nothing in sector 1 (only one air weapon).
5. **Hits and death:** 7 full hits kill; the ship explodes, coins spill, 2.7 s (last life 1.3 s) then you re-enter
   invulnerable for 2 s. Game over after the last life → the game starts again (◇).
6. **Score / coins / multiplier:** kills × multiplier; coins and pickups; extra life at 10,000 / 40,000 / 80,000.
7. **Level end:** "Sector Secured", ground-accuracy tally with ticking count, coin bonus, the defence bonus if you
   were never hit; then the game starts again at sector 1 (◇ — the campaign is Phase 3). Wrecked platforms and tanks
   stay painted into the map.
8. **Sound:** effects from the game's own mixer (at most 8 at once); the level music starts as the screen fades in.
   **Pitch question:** bullet impacts `exsl` play short and high (speed = 1/pitch, as the code). If the longplay's
   impacts are deep and slow, say "flip pitch". **Music-level question:** music sits about half as loud as a
   full-volume effect (full scale 255). Too quiet? Say so.
9. **Volume keys `-`/`=` (your ruling, 2026-10-07):** as on Mac OS X — they do nothing you can hear and show no
   message; the game plays at full level and your Mac's own volume controls set the loudness.
10. **Caps Lock** pauses ("Press Caps Lock" notice; sound cut, the pause click, music frozen) until released. **F6**
    toggles interlacing with a message. **`~`** opens the console: `FPS`, `VERSION`, `supermunki` then the cheats
    (`life`, `score`, `funds`, `shields`, `mult`, `accuracy`). **Esc** starts level 1 again (◇).
11. **Particles, wrecks and trails:** debris bursts in the unit's colours (each 3 px right/below of centre — a quirk we
    copy), stopped tanks become obstacles, bullet trails on some units.
12. **Not yet certain (MED):** the 24→16 sprite colour cut (gate 1, unchanged), particle colour shades, the "Press
    Caps Lock" notice placement, tally waits, the FPS counter showing 31, the crosshair "locked" frame timing.
13. **Demo replay (fallback oracle):** `open -a "Deimos Rising" --args -film de01` plays the shipped demo (no music —
    ◇ the menu music is Phase 4). Machine result: <G4 line, or "pending trace" + the first divergence tick>. If it is
    pending: does the ship do what the demo pilot meant to do, up to that tick and after?
Invulnerability carry-over between levels is not reachable until level 2 (Phase 3).

---

## Phase 3 — the campaign (cards for its own plan)

| Card | What | Proof |
|---|---|---|
| P3.1 level transition | `levelCompleteStep` runs the fade to black (host op), `FrameKeys.levelTransitionReset`, `FUN_100064d0` for sector + 1 inside the same `GameState`; sector 13 → `none` → session end | a two-level headless run: game time resets, levels started = 2, `flags.sector` = 2 |
| P3.2 carry/reset table | lives, next-life score, score carry; coins reset; weapons re-picked (`FUN_1003af90`); dead players stay out; invulnerability carry-over as read (Ben's eyes decide) | tests per row of level-scroll-objects §8's table |
| P3.3 two players | key set 2, duo start positions, shared view shift, two-player score bar | de02–de04 are one-player; two-player by tests + Ben |
| P3.4 finale | `noal` → `12gc` → `miof`/`aieg` chain; 1,200-frame tally wait; mission bonus; `G+0x0d` | the loose-ends-session §5.3 timeline (HIGH) |
| P3.5 replays | `deimos-replay --all` gates: de02 116,180 @ 8,357; de03 57,520 @ 10,058; de04 24,670 @ 5,649 | G4-style bundle |
| P3.6 stage | the campaign in the app; gate 3 card | Ben plays through |

Note for P3: the effect gate and the music fallback differ from the original only for data shapes no shipped file
has; record it on the Phase 3 card, no code change.

## Phase 4 — the front end (cards)

Boot and logos · main menu · level select (+ its accept/fail flash, whose start values are INDEX #62) · scores + name
entry · credits · attract mode + Last Film save · prefs file + configuration dialog (DITL 190) + controls window (DITL
191, drawn by the replica — the default the build proceeds on) · a game controller mapped to the original's keys, with
the controls window (Ben's ruling, 2026-11-05) · mouse in `HeldKeys`. Proof: per-screen goldens, the cold-start
timeline, Ben's gate 4.

## Phase 5 — Windows + release (card)

`Deimos/Windows` on HectorSDL (Ferazel's Phase W shape); drawn dialog; brother's test build; notarized DMG + zip.

---

## Self-review (the seat, after writing; revised 2026-11-08)

- Every task still to do is in this file in full: Tasks 2.1–2.5, C18b, H2, H3, A3, F1, A4 (with the gate card); the
  research-bank corrections are listed in Task 2.3 (53). Nothing current needs the October Phase 2 plan, its
  hand-overs or the audit.
- Spec coverage: the spec's "rest of Phase 2" list ↔ Tasks 2.4, 2.5 and the Wave 3 cards ✅; its Phases 3–5 ↔ the cards
  ✅; its seat rulings ↔ Task 2.1 (the audit stands in for the owed legs), Task 2.3 (bank corrections now, not at the
  end), Task 2.2 (merge after the fix round), G1 (kit main) ✅.
- Names: `updateEntities`, `updateWorld`, `playerCommands`, `groupCommands`, `levelCompleteStep`,
  `levelTransitionReset`, `startSession`, `endFrameWrapper`, `nearestActivePlayer`, `playerWithinRange`,
  `tallyTextRequest`, `tallyTextCommands` — all exist on the branch or are created by the card that names them ✅.
- Corrected on 2026-11-08: C12's coin-tally text is the player draw's own format-30 text, not the accuracy tally's
  `tallyTextRequest` (format 0x35), which C18a draws; Task 2.3's file list gains `sprite-geometry-draw.md`; the
  census file takes its note in the header only.
