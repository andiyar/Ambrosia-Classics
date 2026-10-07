# Plan — Deimos Rising Phase 2: level 1 plays (gate 2) — 2026-10-07

> Status: **REVIEWED (two Opus legs) — ACCEPT_WITH_FIXES, fixes applied** (planner: Claude Opus 5.5, 2026-10-07;
> leg A fidelity 1 Critical / 9 Important / 15 Minor, 85 claims PASS; leg B executability 2 Critical / 17 Important /
> 16 Minor; one fix pass, one finding rejected — record in `docs/plans/2026-10-07-deimos-phase2-REVIEW.md`).
> Implements `docs/plans/2026-10-06-deimos-design.md` §8 **Phase 2 only**, under Ben's rulings **D27** (whole game;
> feel oracle = longplays + his eyes), D29 (layers, render model, seams LOCKED) and **D30** (gate 1 passed; Ben plays
> on Mac OS X; `TickRate.osx` 60 Hz).
> Reviews of tasks are **Opus only** (Ben, 2026-10-07): ⚑ MAJOR = two Opus legs (spec compliance, then quality);
> minor = one. Fable only for a whole-phase final review if the orchestrator asks for it.
> **Format (Ben, 2026-10-03): CONTRACTS, not code** — files, public names (signatures only where they pin a seam),
> behaviour with bank anchors (file § or listing address), test names verbatim with the number each checks and its
> source, gate commands, commit messages. No implementations.
> **Numbers:** from the bank (file § + label), a listing address, or a planner/reviewer probe run on this machine on
> 2026-10-07 over the committed `Resources/Deimos` (cited "probe pNN", Research notes). Self-derived goldens and
> "as read" values are named as such and are re-derived independently by the task's first review leg.
> **D-number:** this plan reserves **D31** "Deimos Rising build: Phase 2 rulings (seat)" (free on `origin/main`
> b4616d0 at the fix pass; renumber at commit time if taken).

**Goal.** Sector 1, Mariner Valley (`le07`), plays as the original: the 38 placements spawn at their rows, the two
`Level` controllers pause the scroll and throw Buzzsaw waves, the ship flies, fires the Ion Cannon (tap and power-up
with overload), drops Plasma Bombs toward the crosshair, collides, takes hits, dies, respawns and loses lives; kills
score (× multiplier), coins and pickups collect, random bonuses roll, particles/debris/wreck stamps/motion blur show,
notices and messages appear, the level ends at the top of the map with "Sector Secured", the accuracy and coin
tallies and the defence bonus; sound effects through the game's own 16-voice mixer and the level music; Caps Lock
pause, Esc, `-`/`=`, F6 interlace, the `~` console with the commands 1.0.6 registers. **Machine gate (G4):** the
shipped demo film `de01` (which records `le07`, probe p11) replays headless and its player-1 score is **25,050 when
the replay reads its 4,809th recorded input**. **Ben's gate:** he plays level 1 — "does it play like Deimos".

**Scope.** Design §8 Phase 2. Not in scope (Phase 3+): sectors 2–12 as a campaign (the engine is data-driven and runs
any level, but level complete ends the session — ◇ S9), the level-transition fade and next sector, two-player play in
the app (the logic is per player and tested; the app starts one player), the finale, front end, attract mode, high
scores, the prefs file, the configuration/controls dialogs, Windows.

**Architecture (design §3, D29.1).** `Deimos/Core` grows: **DeimosCore** (rules — units, combat, player, weapons,
effects state, notices, console; all simulation state in one value `GameState`), **DeimosRender** (+ particle stamps),
new **DeimosAudio** (Foundation + DeimosCore + HectorAudio + Synchronization — the game's 16-voice effects mixer and
the music streamer behind one pull source; ruling below), **DeimosHost** (driver: pause yield, cue routing, typed
keys; public `HeadlessRunner`, `FilmReplay`, `ReplayTrace`), new executable **`deimos-replay`** (the score-trace tool).
**Deimos/App** plays the PCM stream through the new kit stream voice (K2). HectorKit gains one additive API (K2) and
one target edge (HectorShell → HectorAudio).

**DeimosAudio ruling (design-review M6) — a separate target, and why.** (1) Threading: the mixer is pulled on the audio
thread and must be `Sendable` behind a `Mutex`; DeimosRender is a single-threaded executor of `RenderOp`s. (2)
Portability: the Windows shell (Phase 5) links the same target unchanged behind `SDLAudioOut(source:)`; it needs no
pixels. (3) Test isolation and compile time. (4) Nothing in DeimosRender is shared with audio. Rejected: mixer in
DeimosRender (conflates threading models); mixer in DeimosCore (Core would own wall-clock state and real-time locks;
it must stay a pure function of ticks).

**Tech:** Swift 6.4 / Xcode 27, SwiftPM tools 6.0, XCTest, macOS 15 deployment, xcodegen (`project.yml` is truth).
Python 3 only as the planner's probe tool (never a build or test dependency).

**Paths:**
```
WT      = /Users/andiyar/Developer/Ambrosia-Classics/.claude/worktrees/<lane worktree>   (branch deimos-phase2, from main)
HK      = /Users/andiyar/Developer/HectorKit        (main 4ca2e18 — Cythera K1 landed — zero-skip FLOOR 322)
HKWT    = /Users/andiyar/Developer/HectorKit-worktrees/deimos-k2   (branch deimos-k2, K2 only)
LISTING = /Users/andiyar/Developer/Ghidra/deimos/proj/disasm-review3-all.txt  (range 10000000-1004b400 only)
          + mem/10000000.bin (code), mem/100de330.bin (data; r2 = 0x100e6330). There is NO decompile.
LISTX   = the mixer-library listings beyond that range, same folder: disasm-review2.txt (FUN_100d32d0 at line 21693),
          disasm-w2s8.txt, disasm-w2s8b.txt (FUN_100d18d0, FUN_100d21a0, FUN_100d1cf0); FUN_100d1d90 has NO listing —
          disassemble it first with DisasmRange.java (same folder; headless form in docs/deimos/INDEX.md "Tools")
GUIDE   = /Users/andiyar/Developer/Ambrosia/Resources/ambrosia-extracted/Action-Adventure/DeimosRising/
          Deimos Rising 1.0.6 (volume)/Deimos Rising/Deimos Rising Player Guide/Deimos Guide.html   (cite only)
SCRATCH = the executing session's scratchpad directory (logs, dumps, builds; never the repo)
```

---

## Verification model (read first)

**Machine gates — executors close these alone.** Expected values here; the commands are in the code block below
(copy them literally — real `|`, never the table).

| # | gate | expected |
|---|---|---|
| G1 | HectorKit zero-skip (K2) | `PASS: zero skips, zero failures, executed 326 == floor 326` (main floor 322 + K2's 4; if main moved again: rebase floor + 4) |
| G1b | HectorSDL suite (K2) | previous SDL total + 1 passed, 0 failed |
| G2 | `Deimos/Core` suite **without** `DeimosReplayTests` | the task's ladder total, then `0` |
| G3 | census unchanged | `testStdoutEqualsCommittedCensus` green inside G2; the diff against the merge-base is empty |
| G4 | **de01 replay (the Phase 2 machine gate)** | `DeimosReplayTests` 3 passed / 0 failed, and the CLI's last line `de01 le07 seed 0x469c2: score 25050 at read 4809 (end: <reason>) PASS` — rule G4 below |
| G5 | apps build | `** BUILD SUCCEEDED **` ×3 (Deimos, Aki, BubbleTroubleX); K2 adds AkiPad on an iOS simulator (×4) |
| G6 | scope fence | changed paths ⊆ the task's **Files** (+ `docs/DECISIONS.md` where the task says so) |
| G7 | layering | no output (`import Synchronization` is allowed — stdlib, Windows-safe) |
| G8 | kit game-agnostic (K2) | no output |
| G9 | staged app boots (A4) | a pid; clean quit; no new crash report naming the app |
| G10 | clean tree per commit | no output |
| G11 | no hangs | every test that runs passes, a driver, a world loop or a mixer names an explicit bound (`maxPasses`, `maxIdleCalls`, a fake-clock cap, `maxFrames`) and `XCTFail`s on reaching it; `swift test` only on the task's own `--scratch-path`; a hung test FAILS the task |

```sh
# G1  (K2)
HECTORKIT_TEST_LOG="$SCRATCH/hk.log" "$HKWT/tools/check-zero-skip.sh" 2>&1 | tail -n 1
# G1b (K2)
cd "$HKWT/SDL" && swift test > "$SCRATCH/sdl.log" 2>&1; grep -cE "^Test Case '.*' passed \(" "$SCRATCH/sdl.log"; grep -cE "^Test Case '.*' failed \(" "$SCRATCH/sdl.log"
# G2
cd "$WT/Deimos/Core" && swift test --scratch-path "$SCRATCH/build-<task>" --skip DeimosReplayTests > "$SCRATCH/dm.log" 2>&1
grep -cE "^Test Case '.*' (passed|failed|skipped) \(" "$SCRATCH/dm.log"; grep -cE "^Test Case '.*' (failed|skipped) \(" "$SCRATCH/dm.log"
# G3
git -C "$WT" diff --stat "$(git -C "$WT" merge-base HEAD origin/main)" -- docs/deimos/data-census.md
# G4  (from H3 on)
cd "$WT/Deimos/Core" && swift test --scratch-path "$SCRATCH/build-replay" --filter DeimosReplayTests > "$SCRATCH/g4.log" 2>&1
grep -cE "^Test Case '.*' passed \(" "$SCRATCH/g4.log"; grep -cE "^Test Case '.*' (failed|skipped) \(" "$SCRATCH/g4.log"
swift run --scratch-path "$SCRATCH/build-replay" deimos-replay de01 | tail -n 1
# G5
cd "$WT" && xcodegen generate && for s in Deimos Aki BubbleTroubleX; do xcodebuild -scheme "$s" build 2>&1 | tail -n 1; done
xcodebuild -scheme AkiPad -destination 'generic/platform=iOS Simulator' build 2>&1 | tail -n 1     # K2 only
# G6
git -C "$WT" diff --name-only <task base>..HEAD
# G7
grep -rnE "^import (AppKit|UIKit|SwiftUI|CoreGraphics|CoreText|ImageIO|AVFoundation|QuartzCore|HectorGraphics|HectorShell)" "$WT/Deimos/Core/Sources/DeimosCore" "$WT/Deimos/Core/Sources/DeimosRender" "$WT/Deimos/Core/Sources/DeimosHost" "$WT/Deimos/Core/Sources/DeimosAudio" "$WT/Deimos/Core/Sources/deimos-replay"
# G8  (K2)
grep -rniE "deimos|ambrosia" "$HKWT/Sources" "$HKWT/SDL/Sources" --include=*.swift | grep -v HectorTestSupport
# G9  (A4)
open "$WT/out/Deimos/Deimos Rising.app"; sleep 8; pgrep -x "Deimos Rising"; osascript -e 'quit app "Deimos Rising"'; ls -t ~/Library/Logs/DiagnosticReports | head -3
# G10
git -C "$WT" status --porcelain | grep -v '^??'
```

**G4 — the replay gate, and the miss path (orchestrator ruling 5).** FILMs can predate the code or data they ship
with (BTX lesson). Probe p12: `de01–de04` were saved (ZIP mtime 2001-12-03 13:39–14:02) **after** every game-data
entry the replay reads (`unde`/`leve`/`wede`/`plde`/`flli`/`idli`, newest 2001-12-02 16:11; only the `stli` string
lists are newer); the binary is 1.0.6 (2004-01-02), so code drift 1.0 → 1.0.6 is the remaining risk.
1. **PASS** = P1's decoded score **at the instant the replay's film read consumes byte index 4808** (cursor 4808 →
   4809) is 25,050. That is exactly what the recorder stored: `FUN_10009830` is called from `FUN_1002a3a0` at
   `1002a42c`, step 3 of `FUN_10028170` — mid-tick, before P2, the score bar, the tallies (`10006f58`, `10006ff4`) and
   the entity update (`1000702c`) of that tick (leg A I-3). `FilmCursor.score(player: 0, atRead: 4808)` returns it (C7 `readScores`, fix(C7) 0b2093a — the read at cursor 4809 is one tick later; written by
   C14's input step). The CLI also prints the end-of-pass score and the end reason.
2. **Landing.** H3 lands `DeimosReplayTests` as the gate (a separate bundle, excluded from G2 by `--skip`, so G2's
   ladder stays green). If G4 is red, H3 still merges with the gate recorded **"pending trace"** in STATE, and the
   orchestrator opens **F1** (below). Never edit the expectation; never skip the test.
3. **F1 — replay triage (orchestrator-owned, conditional).** `deimos-replay de01 --trace "$SCRATCH/de01.csv"` writes
   one row per tick (H2 `ReplayTrace`). The orchestrator (or an implementer it briefs) finds the **first divergence
   tick T**: the earliest trace event a reviewer cannot justify from the bank/listing (an unexplained death, a spawn
   at an unexpected row, a kill whose score is not the unit's `score_INT × multiplier`, a draw-count step at a site the
   bank does not list, the scroll freezing at an unexpected top). Reported with every run: end reason, cursor at
   session end vs 4,809, P1 deaths (tick, cause), score at reads 1,000 / 2,000 / 3,000 / 4,000 / 4,809, game time of
   the level end, accuracy %, money at the coin tally, multiplier history. Each fix is committed as
   `fix(<task id>): …` by an implementer working under **that task's Files**, reviewed by one Opus leg, G2 + G4 re-run.
4. A divergence is a **bug** until two Opus reviewers have each re-read the listing at every address the event at T
   depends on and agree the replica follows 1.0.6 exactly. Only then may it be recorded as **"de01 predates the 1.0.6
   code"**: A4 stages with the gate "pending trace", Ben watches `-film de01` (S9.5) against his memory/longplays
   (gate card line 13); D31 records the ruling and re-specifies `testDemo01…` to pin the ruled divergence tick and
   the replica's own score (self-derived, re-derived by a second leg). `de02–de04` run with `--all` as information;
   agreement or disagreement across the four is evidence for the ruling.

**Test ladder (`Deimos/Core` G2, cumulative, canonical merge order; STOP if different):** baseline **189** (Phase 1 as
built; leg B re-ran it: 189/0) → C0 **195** → A1 **203** → C13 **211** → C16 **217** → A2 **224** → R4 **227** → C7
**235** → C8 **246** → C9 **256** → C10 **265** → C14 **275** → C11a **281** → C15 **290** → C19 **299** → C11b
**305** → C17 **313** → C12 **321** → C18a **329** → C18b **330** → H2 **338**. H3 adds **3** to the separate G4
bundle (`DeimosReplayTests`), so G2 stays **338**. Lanes may merge in another order inside a wave: expected total =
previous total + the task's N. Re-pointed Phase-1 tests keep their names and count (C18a/C18b: PlayerPhase1Tests 7,
DeimosSessionTests 11, LevelOneFrameTests 6, EntityDrawTests 5). HectorKit: K2 **+4** main (G1 = 326), **+1** SDL.

**Honesty gate (Ben only):** the gate card (A4). Completion is phrased "machine gates green; Ben's gate pending".

**What the machine does NOT prove:** pitch direction (Q2), music loudness (Q3), the volume-key behaviour (Q4), the
24→16 sprite colour cut (Phase 0 note 15, still MED), particle colours (arithmetic re-derived, look is Ben's), MathLib
last-ulp agreement of the trig tables (INDEX #45 — the replay is the only machine witness), whether the original could
tear (it could; whole-frame presents, design §7.1).

---

## Non-negotiable invariants

1. **Layering (HectorKit D6, D12, D29.1).** DeimosCore: Foundation + HectorResources + HectorAudio. DeimosRender:
   Foundation + DeimosCore. **DeimosAudio: Foundation + DeimosCore + HectorAudio + Synchronization.** DeimosHost:
   Foundation + DeimosCore + DeimosRender + DeimosAudio. `deimos-replay`: Foundation + the four. `Deimos/App` alone
   imports AppKit / HectorShell / AVFoundation. Windows traps (D18/W0.5): no `String.Encoding.macOSRoman`, no
   `UserDefaults` below the App.
2. **Kit stays game-agnostic** (G8). K2's doc comments describe pull streams, never a game.
3. **Transcribe, don't reinvent.** Every behaviour cites its bank section or listing address; a contract here never
   overrides the bank — if they disagree, STOP and report (the listing settles it). **Bank corrections go in the PR
   notes only; no implementer edits `docs/deimos/*`** — task B1 appends them all at the end (leg B I16).
4. **No modern affordances** (CLAUDE.md). Phase 2's only additions are the ◇ stand-ins of S9 and design §7's
   deviations; each is on the gate card.
5. **Data in git, tests never skip** (D24.3). A missing file is a FAILURE naming the path. Each test target has its
   own data locator / static asset cache (`RealData`, `ShippedAssets` are per-target helpers — new targets
   `DeimosAudioTests`, `DeimosReplayTests` declare their own; leg B m11).
6. **Every RNG draw at its original site, in the original order** (engine-loop §9; spawn-and-waves §9;
   particles-debris-blur §1; sound-music §8.6; units-movement §5.5, §8.1). Per tick: the `FUN_10006b50` call order
   (p15). Per entity: the `FUN_10033850` order (C12's contract). Per spawned member: the `FUN_10035cd0` order
   (spawn-and-waves §3.2). Draw owners: C0 (pitch), C8 (creation, state entry, flee point), **C9 (random animation
   frames `FUN_10015930` `10015a0c`, cyclic motion `FUN_10016fe0` `10017024`/`10017054`)**, C10 (spawn-set re-arm),
   C11b (media impacts, random bonus), C13 (particles), C14 (level start). A draw is made even when its result is
   discarded (refused requests, muted sound). The pre-seed `FUN_10046580(400, 2000)` at the top of `FUN_100051a0`
   stays unmodelled (it precedes `srand`).
7. **Float fidelity.** `Float` wherever the listing has `fadds/fsubs/fmuls/fdivs`; **`fmadds`/`fmsubs`/`fnmsubs` are
   fused (one rounding) — `addingProduct`/`fma`, never `a*b + c`** (placement `100379cc..10037a0c`, rotated offsets
   `10016070..100160f0`, mode-2 α); `fctiwz` = truncate toward zero; int → float via the 0x43300000 magic is exact.
   Tests pin float results by **bit pattern** (or a literal that round-trips to the same bits).
8. **HectorKit floor-delta rule.** K2 works in `$HKWT` (branch `deimos-k2`), rebases onto `origin/main` immediately
   before the fast-forward push, re-runs G1 on the rebased tree and sets `FLOOR` to the printed total. Classics
   consumes HectorKit only from `~/Developer/HectorKit` main after a clean `pull --ff-only`, through the
   `.claude/worktrees/HectorKit` symlink (D1).
9. **STOP on any unexpected number** (counts, hashes, totals, scores, pixels). Report the output; never edit an
   expectation.
10. **Commits:** explicit paths only (never `git add -A` / `.`, never `git stash`); trailer on every commit, both repos:
    `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`. G10 after each.
11. ⚠️ **Landmines.** (a) `swift test` has no package total — count `^Test Case` lines (G2). (b) SwiftPM rejects a target
    with no sources — `Package.swift` grows task by task (A1, H2, H3 own it, sequentially). (c) Quote every path.
    (d) D-numbers collide: confirm D31 with `git show origin/main:docs/DECISIONS.md` at commit. (e) Decode sprite
    groups and sounds once per test process; never decode all 2,554 frames or a whole music track in a unit test.
    (f) A Phase-1 implementer's unguarded test hung another's run — G11. (g) Markdown tables escape `|` — copy
    commands from code blocks only (leg B C1).
12. **Seams are additive only** (D29.1): S3 lists the Phase 2 additions; nothing is renamed or removed; every existing
    public `DeimosSession`/`DeimosDriver` property used by tests stays (as a forwarding accessor if its storage
    moves). Adding a `RenderOp` case updates every exhaustive switch in the same commit (C0: `DeimosRenderer.apply`,
    `DeimosSessionTests.kind`).
13. **`GameState` storage rule (orchestrator ruling 3).** C7 declares the complete stored-field table of S2 (incl.
    placeholder sub-structs). Rule methods are `extension GameState` methods that take **entity/player indices** and
    re-read `world.entities[i]` / `players[i]` after any call that may mutate the world; **no `inout Entity` (or
    `inout Player`) is held across a `GameState` call** (exclusivity, and spawns append mid-pass). A task **alone in
    its wave** may add a stored field to C7's files (listed in its PR notes); a task in a **parallel wave** that finds a
    field missing STOPs and reports — the orchestrator adds it as a micro-commit before continuing the wave.
14. **Hook stubs.** Where an earlier task must call behaviour a later task owns, the earlier task creates the later
    task's file with a stub body marked `// ◇ stub — <later task> fills`; ownership of that file passes to the later
    task (always a later wave): `Combat/Destruction.swift` (C10 → C11b), `Weapons/WeaponTick.swift` (C14 → C15).

---

## Hazards for every implementer reading the listing (from the bank; read before any listing work)

- **No decompile exists.** Cite listing addresses only; bank lines that cite "the dump" are re-read in the listing when
  a test pins them. The mixer library (`0x100cc000…`) is outside `$LISTING` — use `$LISTX`.
- **Static initialisers rewrite templates before `main`** (INDEX #56, static-init-audit §5): spawn-request templates
  `0x100e64b0` / `0x100eb41c` / `0x100ecd14` have **+0x24 = −1** at runtime (image 0); the draw template clip is
  {0,0,480,416}. Use runtime values.
- **The `lwzu/stwu` +8 copy-loop trap** (hud-scorebar §4: `0x100eb228`, not `…224`).
- **Signed-compare idioms** `eqv; subfc; rlwinm; addze; rlwinm` = signed `rB < rA` (timing-frame §7); `FUN_10009750`'s
  `xor; srawi; and; subf; rlwinm` = signed `a > b` (loose-ends-session §7).
- **Trig tables are computed at start-up by MathLib** (`FUN_10042920`, BSS — units-movement §2.3): sin/cos 360 floats,
  atan 1024 ints, sqrt 16384 floats. The replica computes them with Foundation; the argument precision is read at
  `10042a00..10042a60` first (C7). A last-ulp mismatch surfaces only as a replay divergence (INDEX #45, G4.3).
- **Same-pass semantics.** Lists are appended at the tail (`FUN_100009e0`, INDEX #38) and iterated by re-reading the
  count: an entity or group created during a pass is processed by the same pass (loose-ends-combat §4.5); a deleted
  entity is only flagged (`+0xcb`) and reaped by `FUN_10036610` after the entity loop.
- **`AllowOnlyOneInstance`** (`10033bf8–10033c14`) would make a logic-tick decision depend on the audio thread
  (`FUN_100476e0`). It is dead in shipped data (6 states, all with sound `none`; sound-music §5). **Core treats it as
  "not playing"**, guarded by a data-census assertion (C12), so no task wires Core to the mixer.

---

## Shared architecture (LOCKED — every task codes against these names)

### S1. Package `Deimos/Core`
`Package.swift` gains, task by task: **A1** library product + target `DeimosAudio` (deps `DeimosCore`, HectorAudio)
and test target `DeimosAudioTests` (`DeimosAudio`, `DeimosCore`); **H2** adds `DeimosAudio` to the deps of
`DeimosHost` and `DeimosHostTests`; **H3** adds executable `deimos-replay` (deps `DeimosHost`, `DeimosRender`,
`DeimosAudio`, `DeimosCore`) and test target `DeimosReplayTests` (`deimos-replay`, `DeimosHost`, `DeimosCore`).
New Core sources go under `Sources/DeimosCore/{Math,Units,Combat,Effects,Weapons,Player,Game,Audio}/`.

### S2. DeimosCore public surface (★ LOCKED after Phase 2 · ◇ Phase-2 stand-in)
- ★ **`GameState`** (C7, `Game/GameState.swift`) — the whole mutable simulation, one value. **Complete stored-field
  table (C7 declares every one; invariant 13):** `assets` (let), `prefs: DeimosPrefs`, `rng: MSLRandom`, `flags:
  GameFlags`, `scroll: ScrollState`, `world: EntityWorld`, `players: [Player]` (2), `scoreBar: ScoreBarState`,
  `particles: ParticleSystem`, `debris: DebrisList`, `blurs: MotionBlurPool`, `notice: NoticeSlot`, `messages:
  MessageQueue`, `cues: CueBuffer`, `film: FilmCursor?`, `trace: TickTrace?`, `mask: MediaMask` (C7 type: the raw
  96×720 grid + scale; C11b adds the lookup), `tally: TallyState` (C7 creates `Game/TallyState.swift` with the
  accuracy-tally fields of scoring-bonuses §1.2 G+0x48…+0x160 as plain stored values; C17 owns the file afterwards and
  may add fields while alone in its file), **`tickOps: [RenderOp]`** (render ops made during the tick — terrain stamps
  of `FUN_10036610` step 2 and `stateDrawToTerrain` — drained into the pass's ops before draw world; leg A I-8, leg B
  I1), `entityLimitWarned: Bool` (the once-per-level "Reached Entity Limit"). Step logs for order tests are an
  optional closure parameter of the orchestrating methods, never stored.
- ★ `GameFlags` (C7) — the G struct fields (scoring-bonuses §1.2, level-scroll-objects §8): running +0x08,
  levelComplete +0x09, noPlayerAlive +0x0a, perfectThisLevel +0x0b, rewardArmed +0x0c, allLevels +0x0d,
  levelsStarted +0x10, sector +0x14, level +0x18, gameTime +0x1c, filmPlaying +0x20, levelEndHandled +0x29,
  levelEndTime +0x2c, **gameOverStart +0x34** (`10006d60`/`10006d78`), appeared +0x38, levelEnding +0x39,
  groundCreated +0x3c, groundDestroyed +0x40, perfectLevels +0x44, cheat counters +0x16c…+0x17c, and **`p1Active`**
  (the `FUN_10006b50` local set at `10006bb0` from `FUN_10026c60(P1, 4)`, passed as `FUN_10028170`'s 2nd argument;
  set before the player loop and never reset within the tick — loose-ends-session §4, HIGH).
- ★ `Trig` (C7, `Math/Trig.swift`) — the start-up tables and helpers: `sin(_:)`/`cos(_:)` (`FUN_10042f00`/`ee0`, 360 →
  0), `internalHeading(_ compass:)` (`FUN_10043040`), `vector(heading:speed:)` (`FUN_10042b80`), `headingTo(...)`
  (`FUN_10042ad0` → `FUN_10043090`), `headingOf(vx:vy:)` (`FUN_10042cd0`), `root(_ n: Int32) -> Float`
  (`FUN_10042f20`), `distance(...)` (`FUN_10042e90` = root(trunc(dx²+dy²))).
- ★ `Entity` (C7) — `GameObject` + **one stored field per named offset** of spawn-and-waves §1.3, units-movement §3,
  damage-health-death §2–§3, sound-music §5, particles-debris-blur §2.6/§4.3, loose-ends-combat §4.2 (C7 builds the
  table; every offset the bank names is a field, with the offset in its doc comment): unit index, state index, serial
  +0x9c, group id +0xa0, spawn countdown +0xb0, state start +0xa4, timer +0xb8, animation +0xbc/+0xc0/+0xc2, flags
  +0xc1…+0xda, owner +0x140/+0x144, owner player +0xd8, killer +0xd9, shields +0x134, last hit +0xb4, last on-hit change
  +0xfc, collision spawn +0xd0/+0xd4, per-state spawn records +0x19c, heading +0x138, velocity copies +0x100…+0x114,
  flee target +0x11c/+0x120, orbit +0xdc/+0xe0, offsets +0x124…+0x130, sound counters +0xe4/+0xe8/+0x14c, particle
  bursts +0xf0/+0xf4, blur +0xec, hittable +0xac, has-depletion-state +0xcd, collected +0xca, stationary/terrain
  +0x13c/+0x13d/+0x13e, terrain-stamp +0x36. `EntityGroup` (0xbc record, §1.2); `EntityWorld` (pool of 1000 slots
  with the free hint of micro-wave §3.7, serial counter from 1000, group-id counter from 20000000, the PERM group
  first, the active group list, the pending level-object list, the "notice shown once" list, `groundCount` mirror).
- ★ `SpawnRequest` (C7; the 0x2c record of spawn-and-waves §1.1 / weapons-projectiles §3.1 with the runtime +0x24 = −1)
  and `SpawnResult` (`{entity index, serial}` — `FUN_10035cd0`'s out-param).
- ★ `CueBuffer` (C0, `Audio/CueBuffer.swift`) — the pass's `[SoundCue]`, `[MusicCue]`, **`haltEffectsAt: Int?`** (the
  index into the sound list at which `FUN_100476a0` ran — sounds before it are cut, sounds from it on start after the
  halt; leg A I-6); `SoundPlay.record(_:allowMultiple:rng:)` = `FUN_100475e0` (listing
  `10047600–1004764c`: id `none` → no draw, no cue; volume = `R(min, min)` — no draw; priority = `Priority & 0xFF`;
  pitch = `rng.range(minPitch, maxPitch)`); `SoundPlay.perm(_:priority:volume:allowMultiple:)` = `FUN_10047670`
  (pitch 1.0, no draw). The `min(P, 100)` clamp of `FUN_10047bf0` step 3 is the mixer's (A1).
- ★ `ParticleSystem`, `DebrisList`, `MotionBlurPool` (C13); `NoticeSlot`, `MessageQueue` (C16); `WeaponHandler`
  moves to `Weapons/WeaponHandler.swift` (C15, same name, fields grow); `Console`, `FrameKeys` (C19); `FilmCursor` (C7: the film, a cursor per player, **`scoreAtRead`** per player (the score
  at the last read — G4.1); `next(player:)` = `FUN_100097a0` — the byte at the cursor, 0 past the recording, cursor +
  1; `finished` = `FUN_10009750`, signed P1 cursor > frames) and `TickTrace` (C7 declares the row shape; H2 records it).
- ★ `Player` gains the full field set of player-physics §1 (C14). ◇ `Player.updatePhase1` stays as a wrapper until
  C18b deletes `PlayerPhase1.swift` (C18a switches the session to `GameState.updatePlayer(_:input:)`).
- ★ `EntityDraw.playerCommands(_:hOffset:floats:) -> [DrawCommand]` (C12; the carry "playerOps return type": every
  entity-draw builder returns `[DrawCommand]`; C18a wraps them as `.draw`, C18b deletes `playerOps`).

### S3. Seam additions (additive only; C0 unless named)
Notation: the new cases and stored fields are added to the existing declarations (Swift extensions cannot add them);
defaults keep every existing initialiser call compiling.
```swift
// RenderOp — new cases
case particles([ParticleStamp])        // FUN_10043ba0 at 10030cd0: written into the back buffer between flush 2…5 and 6…15
case pauseWait(PresentKind)            // FUN_10030870 → FUN_10022ef0: blocking; the host waits for Caps Lock up, then presents
public static func isHostOp(_ op: RenderOp) -> Bool   // true for .fade, .limit, .pauseWait (DeimosRenderer.apply traps on them)
public struct ParticleStamp: Equatable, Sendable { public var x, y: Int32; public var core, fringe: UInt16; public var fade: Int32 }   // top-left, §2.9
// PassOutput — new fields (defaults nil)
public var haltEffectsAt: Int?          // index into `sounds` where FUN_100476a0 ran
// HeldKeys — new field (default [])
public var typed: [UInt8]               // key-down Mac charCodes since the last pass, no auto-repeat (GetOSEvent keyDown — C19 pins the codes)
// MSLRandom — new field
public private(set) var draws: UInt64   // rand() calls since srand; reset by init/srand; EXCLUDED from == (custom Equatable)
// DeimosAssets — new field
public let unitIndex: [FourCC: Int]     // unde tag → definitions.units index (FUN_1003d2f0 / FUN_1003d550)
// DeimosSession — new method (C18a)
public mutating func pass(keys: HeldKeys, ticks: UInt32) -> PassOutput   // ticks = TickCount at begin frame (FPS monitor only); pass(keys:) = ticks 0
```
`SoundCue`, `MusicCue`, `ShellRequest`, `DrawCommand`, `SessionStart` are unchanged (SessionStart.film is used from C18a).

### S4. DeimosRender additions (R4)
`DeimosRenderer.apply(.particles(stamps))` — the 7×7 stamp of particles-debris-blur §2.9 into the back buffer;
`.pauseWait` traps like `.fade`/`.limit` (`RenderOp.isHostOp`).

### S5. DeimosAudio public surface (A1, A2)
```swift
public protocol DeimosAudioSink: AnyObject, Sendable {    // what the driver feeds, in pass order
    func apply(sounds: [SoundCue], music: [MusicCue], haltEffectsAt: Int?)
}
public final class DeimosAudioEngine: DeimosAudioSink, PCMPullSource {   // PCMPullSource = K2
    public init(assets: DeimosAssets) throws                    // preloads every soun effect from assets.index (sound-music §2.3 step 4)
    public let outputRate: Double                               // 44100 (FUN_100d1400)
    public func render(into: UnsafeMutableBufferPointer<Float>, frames: Int)   // audio thread: interleaved stereo float32, never allocates
}
```
Internals (A1/A2, not LOCKED): `IMAContinuous`, `EffectMixer` (16 voices, 8 audible, 1024-frame blocks),
`MusicStream` (non-allocating ima4 packet decoder), all shared state under one `Mutex`. There is no master gain: the app
plays at unity and the OS volume controls apply (Q4 RULED by Ben 2026-10-07, D31).

### S6. DeimosHost additions (H2, H3)
`DeimosDriver.init(assets:prefs:rate:start:audio:)` (`audio: (any DeimosAudioSink)? = nil` keeps every Phase-1
test); `public struct HeadlessRunner` (logic-only or rendering; `init(assets:start:seed:prefs:)`,
`init(assets:film:)`, `mutating func run(maxPasses:) -> ReplayResult`); `public struct FilmReplay` (`static func
run(film:assets:trace:maxPasses:) -> ReplayResult`); `ReplayResult` (`endReason` `.filmEnd/.levelComplete/.gameOver/
.bound`, `cursor`, `scoreAtRead4808: Int32?` (from `FilmCursor.score(player: 0, atRead: 4808)`), `endScore`, `passes`); `ReplayTrace`
(records a `TickTrace` row per ticked pass from the session's public state; CSV writer, header fixed).

### S7. App + `project.yml` (A3)
`project.yml` Deimos target gains `{ package: DeimosCore, product: DeimosAudio }`. `DeimosController` creates the
`DeimosAudioEngine`, attaches it with `ShellMixer.attachStream(_:)` (K2), feeds key-down characters (mapped to Mac
charCodes, C19 table) and Caps Lock into `HeldKeys`, and hands the engine to the driver.

### S8. K2 — HectorKit surface (additive + one target edge)
```swift
// HectorAudio (Foundation-only)
public protocol PCMPullSource: Sendable {
    var outputRate: Double { get }
    func render(into buffer: UnsafeMutableBufferPointer<Float>, frames: Int)   // interleaved stereo float32, frames × 2
}
extension PCMMixer: PCMPullSource {}                                            // it already has both members
// HectorShell (macOS + iOS) — Package.swift: HectorShell now depends on HectorAudio
extension ShellMixer { public func attachStream(_ source: any PCMPullSource) -> Int; public func detachStream(_ id: Int); public func setStreamPaused(_ id: Int, _ paused: Bool) }
// HectorSDL (SDL package)
public init(source: any PCMPullSource) throws                 // SDLAudioOut: designated; AudioPump(source:)
public convenience init(mixer: PCMMixer) throws              // forwards to init(source:)
```
The stream voice is one `AVAudioSourceNode` **in the source's format** (`source.outputRate`, stereo float) into the
main mixer, which converts to the device rate. `connect(at:)`/`reconfigure` rewire stream nodes with **their own
rate** on a device change (voices keep the hardware rate). The render block is built in a `nonisolated static` func
(the existing `makeSourceNode` main-actor note), pulls the source into a **preallocated interleaved scratch** (an
`@unchecked Sendable` box sized to `maximumFramesToRender`, chunk loop if more) and deinterleaves into the node's
buffers — no allocation, no lock in the kit; the source owns its own thread safety. A paused stream writes silence
and does not call the source.

### S9. ◇ Phase-2 stand-ins (each on the gate card; each replaced by a named later phase)
1. **Level complete** (`flags.levelComplete` with a player alive) ends the session like the film branch of
   `FUN_10007170`; the driver starts a new game at sector 1 (Phase 3: fade to black, next sector).
2. **Game over** (`nogo`; the running flag clears on game time `gameOverStart + 111`) ends the session; new game at
   sector 1 (Phase 4: scores, menu).
3. **Esc** ends the session; new game at sector 1 (Phase 4: menu). The Esc latch (D29 as built) now clears on a
   release seen by **any** `idle` call (carry: final-review note, H2).
4. **Level-start music**: the original stops the level-select `ammu` at level 1's load and starts `mu03` at the
   appear tick (sound-music §6.4); with no level select a non-film session emits `[.play(ammu, loop: true), .stop]` at
   load (net silence) — Phase 4 makes `ammu` real.
5. **Film launch argument** `-film deNN` (A3) plays a demo in the app (Ben's fallback oracle, G4.4) with the original's
   film rules (any key ends it, `REPLAY` banner, no level music). The menu's `inmu` that the original keeps playing
   under a film is absent until Phase 4's attract mode replaces this argument.
6. **Prefs live in memory only** — F6 (pref 5), `FPS` (pref 9), `supermunki` (pref 11) and the volume (int pref 0)
   persist across ◇ restarts (H2) but not across launches (carry: Phase-4 prefs file, C1 review m3 — Phase 2 does not
   need it; carried forward explicitly).
7. **One player** in the app; two-player games are Phase 3 (the rules are tested for both indices).
8. A film is not ended by the mouse (`FUN_10048e60` also tests the button) — `HeldKeys` carries no mouse (Phase 4).

---

## Tasks

Legend: ⚑ MAJOR = two Opus review legs (spec compliance, then quality; report everything with confidence); minor =
one leg. "+N" = new `Test Case`s. Every task: G6, G7, G10, G11, plus the gates named. Every task's PR notes list each
listing address it read, every bank correction it found (invariant 3) and anything still MED.

### K2 — ⚑ MAJOR — HectorKit: pull-PCM stream voice (+4 main, +1 SDL)
- **Files ($HKWT):** `Package.swift` (HectorShell → HectorAudio dependency), `Sources/HectorAudio/PCMPullSource.swift`
  (new), `Sources/HectorAudio/PCMMixer.swift` (conformance only), `Sources/HectorShell/ShellMixer.swift`,
  `SDL/Sources/HectorSDL/SDLAudioOut.swift`, `Tests/HectorAudioTests/PCMPullSourceTests.swift` (new),
  `Tests/HectorShellTests/ShellMixerStreamTests.swift` (new), `SDL/Tests/HectorSDLTests/SDLHostSmokeTests.swift` (one
  test), `tools/check-zero-skip.sh` (FLOOR), `docs/DECISIONS.md` (next free HectorKit D-number: the API and the new
  HectorShell → HectorAudio edge), `docs/STATE.md` (one line).
- **Contract:** S8 exactly. `attachStream` returns a stream id; streams render into the main mixer beside the voices;
  a paused stream is silent and its source is not called; `detachStream` removes the node; offline manual rendering
  works for tests (the existing offline init). `SDLAudioOut.init(source:)` pulls in ≤ `chunkFrames` chunks exactly as
  `init(mixer:)` did. Doc comments describe real-time safety, no game names (G8). Review uses the offline path only (no
  real-time audio smokes — BTX playable lane).
- **Tests (4 main):** `testPCMMixerIsAPullSource` (a `PCMMixer` passed as `any PCMPullSource` renders bit-identically
  to a direct `render(into:frames:)` on a twin mixer) · `testStreamRendersSourceOffline` (offline 44100 Hz: a source
  writing a ramp is heard at the main mixer output, frame-aligned) · `testPausedStreamIsSilentAndUncalled` ·
  `testDetachStopsCalls`. **SDL (1):** `testAudioOutAcceptsPullSource` (opens with a test source, start/stop).
- **Gate:** G1 (326), G1b, G8, G5 incl. AkiPad (iOS simulator — HectorShell now pulls HectorAudio on iOS). Rebase,
  re-gate, `git push origin HEAD:main`, clean `pull --ff-only` in `~/Developer/HectorKit`.
- **Commit:** `HectorAudio/HectorShell/HectorSDL: PCMPullSource + ShellMixer stream voice + SDLAudioOut(source:); floor 326`.

### C0 — minor — Seam additions, sound-cue builders, draw counter, unit index; D31 (→ 195, +6)
- **Files:** `Sources/DeimosCore/Seams/{RenderOp,PassOutput,HeldKeys}.swift`, `Sources/DeimosCore/Seams/ParticleStamp.swift`
  (new), `Sources/DeimosCore/Game/{MSLRandom,DeimosAssets}.swift`, `Sources/DeimosCore/Audio/{CueBuffer,SoundPlay}.swift`
  (new), `Sources/DeimosRender/DeimosRenderer.swift` (the two new `case` arms only: `.particles` → empty body marked
  "R4", `.pauseWait` joins the `.fade, .limit` trap), `Tests/DeimosCoreTests/DeimosSessionTests.swift` (the `kind(_:)`
  arms only), `Tests/DeimosCoreTests/Phase2SeamTests.swift` (new), `docs/DECISIONS.md`.
- **Contract:** S3 and the `CueBuffer`/`SoundPlay` lines of S2. `unitIndex` built once in `DeimosAssets.load`.
  **DECISIONS D31** "Deimos Rising build: Phase 2 rulings (seat)": DeimosAudio target (the ruling above), S3 additions,
  `GameState` storage rule and hook stubs (invariants 13–14), cue routing at pass begin with the positional halt (H2),
  S9 stand-ins, the button mapping pinned to the guide (p17), Q2/Q3 built on their defaults, **Q4 RULED by Ben: the Mac OS X behaviour, no
  in-game volume — unity gain, the OS controls the level** (C19), Q5 not reachable, the G4 rule incl. "pending trace", F1 and
  "predates the code", bank corrections owned by B1, prefs file stays Phase 4.
- **Tests (6):** `testPassOutputAdditiveDefaults` (haltEffectsAt nil, typed []; the new `RenderOp`
  cases round-trip `Equatable`; `isHostOp` true for `.fade`, `.limit`, `.pauseWait`, false for `.present`) ·
  `testRandomDrawCounter` (srand(1): `range(10, 11)` = 10 from rand 16838 (p08), draws 1; `range(5, 5)` and `range(1.0,
  1.0)` leave draws at 1; `srand` resets to 0; two generators equal in state but not in `draws` compare `==`) ·
  `testSoundRecordDrawsPitchOnly` (srand(1), record `exsl` MinVol 100 MaxVol 70 Prio 0x132 pitch 0.50–0.55 → cue
  volume 100, priority 0x32, pitch **bit pattern 0x3f0693da** (0.52569354; leg A I-7), draws 1; id `none` → no cue,
  draws 0; sound-music §2.3) · `testPermSoundNoDraw` (gaso 18 `wesw`, 75, 100, true → pitch 1.0, draws 0) ·
  `testUnitIndex` (386 entries; `bu01` → "Buzzsaw Mk 1"; `none` absent) · `testButtonMappingMatchesGuideAndFilms`
  (KeyTable slot bits up, left, right, down, fireAir, fireGround, select; ⌘ → fireAir, ⌥ → fireGround, Space → select
  per the guide's Default Controls; film census: ticks with bit 6 set de01 0, de02 15, de03 26, de04 3; p11/p17).
- **Gate:** G2 = **195/0**, G5. **Commit:** `DeimosCore: Phase 2 seam additions (particles, pauseWait, positional halt, typed keys), CueBuffer + SoundPlay, draw counter, unit index; DECISIONS D31; 6 tests`.

### A1 — ⚑ MAJOR — DeimosAudio: the continuous-IMA conversion and the 16-voice effects mixer (→ +8, canonical 203)
- **Precondition:** disassemble `FUN_100d1d90` with `DisasmRange.java` (it has no listing; `$LISTX`) and read it
  together with `FUN_100d32d0` (disasm-review2.txt line 21693 / disasm-w2s8b.txt), `FUN_100d18d0`, `FUN_100d21a0`,
  `FUN_100d1cf0`, `FUN_100d1b30`, `FUN_100d1be0` and `FUN_10047bf0` (`10047c54`); record the nibble order, the
  dropped word, the index/predictor clamps and the accumulator arithmetic as doc comments. STOP if sound-music
  §2.2/§3.2 disagree (§2.2 is MED on the dump).
- **Files:** `Package.swift` (S1 A1 line); `Sources/DeimosAudio/{IMAContinuous,EffectMixer,Voice}.swift`;
  `Tests/DeimosAudioTests/{EffectMixerTests,AudioTestData}.swift` (its own data locator — invariant 5).
- **Contract (sound-music §2.2–§3.2, HIGH unless marked):** load = `{'asnd', sampleCount = (bytes − bytes/34)·2, rate,
  'mIMA'}` stream; decoder carries predictor/index across packets (index clamp 0…88, predictor ±32767); 16 voices of
  the §3 struct; insertion `FUN_100d18d0` (priority = `min(P & 0xFF, 100)` (`10047c54`), 0 → 1; gains clamp 0x80;
  first slot whose (priority, L+R) the new voice equals-or-beats on **both** keys; refusal at 16 when below all; the
  16th overwritten when count ≥ 16); gain per side `trunc(128·volume/100)` (single precision, `10047dcc..10047e0c`);
  `step = FixMul(FixDiv(44100, rate), pitch16.16)`, `pitch16.16 = trunc(65536·pitch)`; per voice `FUN_100d32d0` (`acc
  += step>>4` per input sample, `n = (acc>>12) − (prev>>12)` linear-interpolated outputs, `sample·g >> 7`, saturating
  ±32767 mix); only voices `i < numChannels` (flli 38 = 8) are written, the rest advance silently; finished voices
  removed after each 1024-frame block (`FUN_100d1cf0`) — 1024-frame blocks at 44.1 kHz internally whatever the pull
  size; `allowMultiple == false` and the record's last-started voice alive → no start (`FUN_100476e0` with the
  id/data/0 match of `FUN_100d1b30`); `stopAll` = `FUN_100d1be0(0)`.
- **Tests (8):** `testContinuousConversion` (`icbu`: P = 239 → sampleCount 15,774 = 66·P; header word dropped; nibbles
  swapped per byte) · `testIMADecodeClamps` · `testVolumeToGain` (100 → 128, 90 → 115, 80 → 102, 75 → 96, 70 → 89,
  50 → 64; §2.3) · `testInsertionRanking` (`cabo` (70, 256), `exsl` (50, 256), `icre` (50, 256) → [cabo, icre, exsl];
  then `icbu` (45, 230) ×2 → [cabo, icre, exsl, icbu₂, icbu₁]; priority 150 clamps to 100; §3.1 + worked example) ·
  `testSixteenVoicesEvictOrRefuse` · `testOnlyTopEightAudible` (voice 9 contributes 0 until a higher voice ends, then
  enters mid-sample; §3.2) · `testPitchIsSpeedInverse` (pitch 2.0 → 2× output frames, 0.5 → half; Q2 default) ·
  `testAllowMultipleFalseBlocksRestart` (§2.4). All bounded by `maxFrames`.
- **Gate:** G2 = previous + **8** (canonical **203**). **Commit:** `DeimosAudio: continuous IMA conversion + the game's 16-voice/8-audible ranked effects mixer (1024-frame blocks); 8 tests`.

### C13 — minor — Particles, debris, motion blur (→ +8, canonical 211) — after C0
- **Files:** `Sources/DeimosCore/Effects/{ParticleSystem,DebrisList,MotionBlurPool}.swift`;
  `Tests/DeimosCoreTests/EffectsTests.swift`.
- **Contract (particles-debris-blur, HIGH unless marked):** `ParticleSystem` — app-start tables (`FUN_10044630`: 100 ×
  [R(0,416), R(0,480), R(0,3)] from LCG state 1, then the two `R(0,99)` start indices — §1 #1/#2, a private
  `MSLRandom(seed: 1)`, never the game's), `emit(_ req:, rng: inout MSLRandom)` = `FUN_10043340` (§2.2–§2.7: type
  table, one `R(0,4)` per particle **at the call**, colour variants, index advance `idx ≥ 99 → 0`),
  `update(scrollDelta:)` = `FUN_100438c0` (§2.8), `stamps(hOffset:) -> [ParticleStamp]` = `FUN_10043ba0` visibility
  (§2.9); `levelReset`. `DebrisList` (§3). `MotionBlurPool` (§4: 1000 slots, the cached-index quirk, emit copies a
  `GameObject` with +0x1a/+0x38 forced 0 and visibility Initial/Delta, update removes below 0.0, draw = the existing
  `EntityDraw.entry` per blur in list order).
- **Tests (8):** `testBurstCountsAndDraws` (`tiny` 5, `smal` 10, `med ` 20, `larg` 40 draws; `meci` ring flag; unknown
  ID → no group, no draw; §2.3) · `testColourVariants` (request 0x7FFF: core 30, 27, 23, 19, 16 and fringe 18, 16, 14,
  11, 9 for variants 0…4 → variant 0 core 0x7BDE, fringe 0x4A52; §2.7, p14 — re-derive from `10043518..1004373c`, STOP
  if different) · `testParticleUpdateDragAndLife` (× 0.96 per axis per update; fade 0 → 32 over 32 updates, removed on
  the 33rd; kill at x < −32, x + 7 > 448, y < 0, y + 7 > 480; §2.8) · `testStartIndicesFromSeedOne` (burst 50, ring 79
  after the 302 app-start draws; §2.5) · `testStampWeights` (the §2.9 table at fade 0, 6, 7, 32 incl. the centre
  snapping back at 7) · `testDebrisRidesScrollAndBlocks` (§3, inclusive) · `testMotionBlurLifetime` (50/10 → drawn on 6
  updates, then freed; the 1001st refused; §4.3–§4.4) · `testStampsSkipDelayedAndOutside` (§2.9).
- **Gate:** G2 = previous + **8** (canonical **211**). **Commit:** `DeimosCore: particles (emit draws, drag, fade, stamps), debris obstacles, motion-blur pool; 8 tests`.

### C16 — minor — Notices and the message queue (→ +6, canonical 217)
- **Files:** `Sources/DeimosCore/Game/{NoticeSlot,MessageQueue}.swift`; `Tests/DeimosCoreTests/NoticeMessageTests.swift`.
- **Contract (messages-notices-console §1–§4, HIGH):** `MessageQueue` — record (§2.1), `post` (§2.2: cap flli 24 = 20,
  the new message dropped, sticky prepend / normal append), `age(frame:)` (§2.3: opaque flli 25 = 60 frames, fade +=
  flli 26 = 1, delete at 32, **one deletion per frame then stop**), `drawCommands` (§2.4) via `TextLayout`; messages
  count **presented frames**. `NoticeSlot` (§4.1–§4.3: post/clear, tick once per new game time — delay, sound through
  `SoundPlay.record` at the first visible tick, fade-in 2/tick, auto-clear at start + flli 71 = 60, fade-out 4/tick;
  draw format 49); notices count **logic ticks**.
- **Tests (6):** `testMessageLifetime92Frames` · `testMessageCapDropsNew` · `testOneDeletionPerFrame` ·
  `testMessageLayoutNewestOnTop` (three normal messages at Loc_Y 10, 30, 50, newest on top; §2.4) ·
  `testNoticeFadeHoldFade` (fade-in 32 → 0 in 16 ticks, clear at start + 61 (strict `>`), fade-out 0 → 32 in 8
  ticks) · `testPressCapsLockNoticeOpaqueAtOnce` (fade-in off → alpha 0; alignment `CEGA` for fc+4 = 1; §4.4).
- **Gate:** G2 = previous + **6** (canonical **217**). **Commit:** `DeimosCore: notice slot and message queue (aging per frame, notices per tick); 6 tests`.

### A2 — minor — DeimosAudio: music streamer, the engine (→ +7, canonical 224) — after A1 and K2 on HK main
- **Files:** `Sources/DeimosAudio/{MusicStream,DeimosAudioEngine}.swift`; `Tests/DeimosAudioTests/MusicEngineTests.swift`.
- **Contract (sound-music §4, §6; S5):** `MusicStream` plays a `soun` music tag (`mu03`, `ammu`, `inmu` — AIFC ima4
  stereo) from the pak byte range with a **non-allocating Apple-ima4 packet decoder inside DeimosAudio** (34-byte
  packets per channel decoded on demand into a buffer preallocated at `.play`; the kit's `IMA4` is the oracle in tests
  — leg B I9 ruling (a)), looping the whole SSND seamlessly (§6.3), linear resampling to 44.1 kHz if the file rate
  differs; `.play` restarts from 0, `.stop` disposes, `.pause`/`.resume` freeze/continue (§6.5); level amp `min(255,
  m·fade >> 8)` with fade 0x100 → gain `amp/255` (**Q3 default 255**). No master gain: `FUN_10047b80`'s OS-volume write did nothing audible on Mac OS X, so effects and music play at unity
  and the OS volume controls apply (Q4 RULED by Ben 2026-10-07, D31). `apply` order: start `sounds[0..<k]`, `stopAll` effects when `haltEffectsAt = k`,
  start `sounds[k...]`, then music cues. `render` mixes under one `Mutex`, never allocates.
  Effects preload: every `soun` tag in `assets.index` that passes `DeimosSound`'s effect gate.
- **Tests (7):** `testMusicAmpFullScale255` (int pref 1 = 100 → m 128 → amp 128 → gain 128/255; §6.2) ·
  `testMusicLoopsSeamlessly` (a synthetic 2-packet AIFC: frame after the last = frame 0) ·
  `testMusicDecoderMatchesKitIMA4` (the synthetic AIFC and `mu03`'s first 4 packets: bit-identical to the kit's `IMA4`) ·
  `testMusicPauseFreezes` · `testUnityGainNoMasterVolume` (Q4 ruled: a full-scale effect and music render at unity — no
  gain stage exists; `DeimosAudioSink.apply` has no volume parameter) · `testPauseClickSurvivesHalt` (`apply(sounds: [a, incl], haltEffectsAt: 1)`: `a`
  is cut, `incl` plays; leg A I-6) · `testEngineIsAPullSource` (outputRate 44100; `render` fills 2·frames floats).
- **Gate:** G2 = previous + **7** (canonical **224**). **Commit:** `DeimosAudio: music streamer (non-allocating ima4, seamless loop, pause, level), unity gain (Q4), positional halt, DeimosAudioEngine pull source; 7 tests`.

### R4 — minor — Render: particle stamps (→ +3, canonical 227) — after C0
- **Files:** `Sources/DeimosRender/{DeimosRenderer,ParticleStamps}.swift`; `Tests/DeimosRenderTests/ParticleStampTests.swift`.
- **Contract (particles-debris-blur §2.9, HIGH):** each stamp writes the 7×7 weight pattern at (trunc sx, trunc sy)
  top-left into the back buffer: `dst' = (dst·w + col·(32 − w)) >> 5` in the spread-555 form `(c & 0x7c1f) | (c &
  0x3e0) << 15`; **core for E and X, fringe for A, B, C and D** (listing row 2 col 2 `10044014..10044034` blends the
  fringe; the core spread starts at `10044040`; leg A I-5).
- **Tests (3):** `testStampKernelSpread555` (dst 0x7FFF, colour 0, w 16 → 0x3DEF) · `testStampPatternAtFade0And7` (D
  pixels take the fringe colour) · `testIsHostOpMatchesRendererTraps` (every op with `isHostOp` false is applied
  without trapping on a fresh renderer; the three host ops are not sent).
- **Gate:** G2 = previous + **3** (canonical **227**). **Commit:** `DeimosRender: particle stamps (7×7 spread-555 blend); 3 tests`.

### C7 — ⚑ MAJOR — Trig, the entity world and `GameState` (→ +8, canonical 235) — alone in wave 2.2
- **Precondition:** read `FUN_10042920` (`10042978..10042a60`: argument precision of the sin/cos/atan builds),
  `FUN_10043090` (`100430a0..100431d0`), `FUN_100385d0`/`FUN_10038810` (micro-wave §3.7), `FUN_10032e60`
  (`10032f88..1003305c`); record as doc comments.
- **Files:** `Sources/DeimosCore/Math/Trig.swift`, `Sources/DeimosCore/Units/{Entity,EntityGroup,EntityWorld,SpawnRequest}.swift`,
  `Sources/DeimosCore/Game/{GameState,GameFlags,FilmCursor,TickTrace,TallyState,MediaMask}.swift`;
  `Tests/DeimosCoreTests/{TrigTests,EntityWorldTests}.swift`.
- **Contract:** S2 for `GameState` (the complete stored-field table), `GameFlags`, `Trig`, `Entity` (the per-offset
  field table), `EntityGroup`, `EntityWorld`, `SpawnRequest`, `FilmCursor`, `TickTrace` (row shape), `TallyState`
  (stored fields only), `MediaMask` (grid + scale only). Trig per units-movement §2.2–§2.3 and loose-ends-combat §1;
  world per spawn-and-waves §1.2–§1.3, §8; the iteration rule of Hazards; the index-based API of invariant 13.
  `GameState.init(assets:prefs:seed:)` builds two `Player`s, a fresh world and buffers; no behaviour beyond reset.
- **Tests (8):** `testTrigTablesAsRead` (S[0] = 0, C[0] = 1, S[90], C[180] bit patterns as the read precision gives
  them — re-derived by review leg 1; `sin(360)` = `sin(0)`) · `testCompassToInternal` (0 → 180, 90 → 90, 180 → 0,
  270 → 270, 359 → 181; heading 180 speed 6 → (6·S[0], 6·C[0]) = (0, 6) exactly; heading 0 speed 10 → (10·S[180],
  10·C[180]) from the read tables, vy = −10 within the table's value — leg B I11) · `testHeadingToPoint` (above → 0,
  right → 90, below → 180, left → 270) · `testDistanceTruncatesSquare` (dist((0,0),(3,4)) = 5; ((0,0),(0.5,0.9)) =
  root(1) = 1) · `testLevelResetIds` (PERM id 20000000 unit `PERM`; next group 20000001; next serial 1000) ·
  `testPoolCapAndHint` (1000 live → the next allocation fails; freeing slot k makes the next allocation slot k) ·
  `testPermMembershipRule` (1 member, no owner → PERM; 2 members → a new group; PERM persists empty) ·
  `testSamePassAppendIsVisited` (an entity appended during an index walk is visited by the same walk; INDEX #38).
- **Gate:** G2 = previous + **8** (canonical **235**). **Commit:** `DeimosCore: trig tables + heading helpers, entity world (pool, ids, PERM, groups), SpawnRequest, GameState with its full stored-field table; 8 tests`.

### C8 — ⚑ MAJOR — Spawning: request → group → members, state entry, flee point, level objects (→ +11, canonical 246) — alone in wave 2.3
- **Precondition:** read `FUN_10033220` (`10033240..10033600`), `FUN_100369f0`, `FUN_10035cd0` (`10035d54..10036100`),
  `FUN_10037930`, `FUN_10037b50`, `FUN_10037ed0`, `FUN_100146f0` (`100148dc..10014dc0`), `FUN_10017cb0`, `FUN_10017510`
  (C8 owns the flee point), `FUN_10035900`, `FUN_10033090`, `FUN_1000fa10`; record each draw site with its address.
- **Files:** `Sources/DeimosCore/Units/{Spawn,StateEntry,FleePoint,LevelObjects}.swift` (`extension GameState`);
  `Tests/DeimosCoreTests/SpawnTests.swift`.
- **Contract:** spawn-and-waves §3.1 order (size and appears draws **before** the refusals: players-active,
  doNotSpawnIfTypeAlreadyExists, cap `live + n < 1001` with `entityLimitWarned`, then deleteExisting…, group creation,
  y conversion `y − top` for req+0x0c, members, entry notice `FUN_100380e0`); §3.2 per-member order D1 → placement →
  initial motion → `FUN_100146f0(state 0)` (timer → frame → scale tolerance → velocity set-up (units-movement §4) →
  owner init `FUN_10033600` → flee point `FUN_10017510` → `FUN_10017cb0`) → group delay `R(gdMin, gdMax)` (first member
  included) → cyclic start (§3.4); shields by sector (damage §3); ground-accuracy create count; `+0x19`; state entry
  also enterCount[state] += 1, soundCount = 0 (sound-music §5), +0xf4 = 0, state start = now. Level objects:
  `FUN_10035900` pending list (ground x −32.0; optional test-only placement filter), `FUN_10033090(row)` (file order,
  unconditional unlink), `FUN_1000fa10` load pass. Test helper: an explicit scroll-step loop owned by this task's test
  file (advance, then `spawnRow(top − 64)`), bounded.
- **Tests (11):** `testGroupSizeAndAppearsDraws` (§3.1; counts match an in-test LCG) · `testShurikenRequestFiftyOneDraws`
  (srand(1), one active player, `shur` at absolute (208, −100): first draw `R(10, 11)` = 10 → **51** draws, per member
  R(0,359), F(5,7), R(50,60), R(0,5), R(9,16); worked example step 5) · `testRefusedRequestStillDrawsSize` (no active
  player → 1 draw) · `testPlacementRadialAndRect` (fused `fmadds`; waves-and-enemies §4) · `testInitialMotionBranches`
  (§3.3) · `testCyclicStartDraws` (5 draws + the 6th when y > 120; §3.4) · `testStateEntryArmsSpawnSets` (`07s1` S2:
  rate `R(120,125)`, volley 1, delay 0, remaining 1; §2.2) · `testShieldsBySector` (`plla` sector 1 → bits of 2.6f
  (2.5999999); `bsgr` sector 3 → bits of 4.8000002; p13) · `testFleeTargets` (`soce` → (208, 2000); random-axis codes
  draw `F(0, 416)` or `F(0, 480)`; units-movement §6, engine-loop §9) · `testFirstLevelObjectSpawnRow` (le07: `bsgr`
  (y 2978) requested at step **77** as a group at (371, −64); level-scroll-objects §6.2–§6.4, p16; loop bound 200) ·
  `testLoadPassBand` (le07 none; all 12 levels **13** of 565 placements).
- **Gate:** G2 = previous + **11** (canonical **246**). **Commit:** `DeimosCore: spawn requests, member creation in FUN_10035cd0 draw order, state entry + spawn-set arming, flee points, level objects; 11 tests`.

### C9 — ⚑ MAJOR — Motion and animation (→ +10, canonical 256) — ∥ C10, C14
- **Precondition:** read `FUN_10015280` and its callees (`FUN_10016cc0`, `FUN_10017b70`, `FUN_10017c40`, `FUN_10016fe0`
  (`10017024`, `10017054` draws), `FUN_10017a10`, `FUN_10016da0`, `FUN_10017ef0`), `FUN_10015930` (`10015a0c` draw),
  `FUN_100172d0`/`FUN_10017150`, `FUN_10016230`, `FUN_100161c0`, `FUN_10037130/7230/7350`, `FUN_10036930`.
- **Files:** `Sources/DeimosCore/Units/{Motion,Animation,OwnerLinks}.swift` (`extension GameState`);
  `Tests/DeimosCoreTests/MotionTests.swift`.
- **Contract (units-movement §1–§8, spawn-and-waves §4, HIGH):** motion controller → velocity (seek/hunt per-axis
  bang-bang, hold, reverse, **cyclic (two draws per tick: `a = R(trunc(Max)/2, trunc(Max))`, `b = R(1,100)`, `L = a +
  b/100.0`, per-axis bounce at ±L — §5.5)**, ramp, constrain, range trigger — a range trigger enters the state through
  C8's state entry inside the controller call); `integrateAndCull(margin: 128)` (`FUN_10012ca0` mode 1, Bank
  corrections 1); animation step (`FUN_10015930`, incl. `ContinuousFrameRandomisation` → `R(base, last)` on every step
  the gate passes, §8.1); rotation gate + turn; heading → frame (micro-wave §3.2); facing; lock → link → orbit and
  the owner copies `FUN_10036930`.
- **Tests (10):** `testIntegrateGroundRidesScroll` · `testCullBoundsMode1` (hw = hh = 10: x −138 in, −138.5 out; x 554
  in, 554.5 out; y −128 in, −128.5 out — no half-height on the top test; y 618 in, 618.5 out; p18) ·
  `testShurikenHoldsSixDown` · `testRangeTriggerOnUpdate50` (update 49 distance 142, update 50 distance 136 < 140) ·
  `testHuntTieGoesNegative` · `testAnimationStopsOnLastFrame` · `testRandomFrameDrawsEveryStep` (`plsh` "Expand, Play
  Sound" (FPD 8, FrameDelay 0) makes one `R(0, 7)` per tick; a state whose base == last makes none; leg A C-1) ·
  `testCyclicMotionTwoDrawsPerTick` (draw count and values against an in-test LCG; bounce at ±L; leg A I-2) ·
  `testHeadingToFrame` (n 8: h 22 → 0, 23 → 1, 350 → 0; n 7 → step 51) · `testLockLinkOrbit`.
- **Gate:** G2 = previous + **10** (canonical **256**). **Commit:** `DeimosCore: motion controller incl. cyclic draws, integrate + 128-px cull, animation with random frames, turning, owner links; 10 tests`.

### C10 — ⚑ MAJOR — State machine: timer, the 17 rules, spawn-set executor, power-up release (→ +9, canonical 265) — ∥ C9, C14
- **Precondition:** read `FUN_10015550` (`10015754..100158d4`), `FUN_10034ee0`, `FUN_10035070`, `FUN_100351f0`,
  `FUN_100352f0`, `FUN_100353e0`, `FUN_10015b40` (`10015c08..10016188`), `FUN_10014670`, `FUN_10034ce0`, the timer
  step in `FUN_10033850` (`10033c58..10033d70`, the "re-read state" branch).
- **Files:** `Sources/DeimosCore/Units/{StateTimer,Rules,SpawnSets,PowerupRelease}.swift`,
  `Sources/DeimosCore/Combat/Destruction.swift` (**hook stub** `destroyEntity(_ i: Int, killer: Int8)` — sets +0xcb,
  +0xd9, +0xda only; C11b fills; invariant 14); `Tests/DeimosCoreTests/StateMachineTests.swift`.
- **Contract:** timer step (waves-and-enemies §3 step 4: `gameTime == start + timer`; `Delete` silent, `Destroy` →
  `destroyEntity`, `none`/empty → no change, else enter by name with now); rules (the 17 strings, unit `none` inert,
  first true rule wins; spawn-and-waves §6 + micro-wave §3.1 semantics); the pause flag read after a timer switch and
  before the animation and rules (bosses §2.2); spawn-set executor (spawn-and-waves §2.3–§2.5, re-arm draws delay →
  volley → rate, absolute and rotated positions, fused); power-up release (micro-wave §3.3).
- **Tests (9):** `testTimerTargets` (Delete: +0xcb, killer 0xff, not destroyed; Destroy → the hook is called with killer
  0xff; "none" → stays; name → switch at now) · `testTimerFiresAtStartPlusDraw` · `testRuleTable` · `testCountRulesSigned`
  (count 2 vs range 2: #14 true; count 1: #15 true) · `testNoDestroyableGroundNeedsOnScreen` (x 420 does not block #5,
  x 400 does) · `testTrackingVersusActive` · `testPauseFlagFromNewState` · `testShurikenControllerThreeGroups` (`07s1`
  S2 issues exactly **3** `shur` requests at T0, T0 + r1 + 1, T0 + r1 + r2 + 1; bound 400 ticks) ·
  `testPowerupReleaseState`.
- **Gate:** G2 = previous + **9** (canonical **265**). **Commit:** `DeimosCore: state timer, the 17 rule conditions, spawn-set executor, power-up release state, destroy hook stub; 9 tests`.

### C14 — ⚑ MAJOR — The player, complete (→ +10, canonical 275) — ∥ C9, C10
- **Precondition:** read `FUN_10028170` (`10028f30..100298a8`), `FUN_1002a150`, `FUN_1002a3a0` (`1002a414..1002a42c`),
  `FUN_10029cc0`, `FUN_100269a0`, `FUN_10026410`, `FUN_10027100`, `FUN_10027e50` (Bank corrections 2), `FUN_10029a10`,
  `FUN_10026cc0`, `FUN_10026d70`, `FUN_10029b20`, `FUN_10029fe0`, `FUN_10026ee0`, `FUN_10027490`, `FUN_10027de0`. The
  "P1 active" gate is settled (loose-ends-session §4; `GameFlags.p1Active`).
- **Files:** `Sources/DeimosCore/Player/{Player,PlayerUpdate,PlayerLife,PlayerScoring}.swift`,
  `Sources/DeimosCore/Weapons/WeaponTick.swift` (**hook stub** `tickWeapons(_ i: Int, input:) -> Int` returning 0; C15
  fills); `Tests/DeimosCoreTests/PlayerTests.swift`. (`PlayerPhase1.swift` untouched.)
- **Contract (player-physics §1–§8, scoring-bonuses §3–§5, damage §5):** `updatePlayer(_ i:, input:)` in the
  `FUN_10028170` order (defence bonus → life state → input (`FUN_1002a3a0`, state 4 only, after the life-state step of
  the same tick: a playing film's next byte via `film.next(player:)`, **calling `film.next(player:score:)` so `readScores[i][cursor]` = the decoded score
  at that read** (G4.1), else the keys' `PlayerInput`) → second fade → overload warnings → ramps → +0xc5 → size/blink →
  state 4: `tickWeapons`, velocity, banking, integrate, view shift, clamps, handler position, crosshair); hits
  `FUN_10027100`; death `FUN_10027e50` (Bank corrections 2 order); respawn `FUN_10029cc0`; level start `FUN_100269a0`
  (incl. `R(400, 2000)` per in-game player); setup `FUN_10026410`; `addScore` `FUN_10029a10`; lives, multiplier, money;
  shield storage biased by +1324366.0.
- **Tests (10):** `testHoldUpTenTicks` (computed in `Float`: vy −1.6, −3.2, −4.8, −6.4, −7.8 cap …; y 328.4,
  **325.19998**, 320.4, 314.0, 306.2, **298.40002, 290.60004, 282.80005, 275.00006, 267.20007**; released: rest at
  **252.00006** on tick 15 — bit patterns pinned; leg A m3) · `testClampToArea` · `testCrosshairAdjust` ·
  `testSevenFullHitsDestroy` · `testShieldEighthPercent` (33.3 → 33.25) · `testDeathOrder` (money 67 → `calg` `cals`
  `casg` `cass` `cass` after the death spawn; displayed shield/power 0.0; state 3; invulnerable; multiplier reset) ·
  `testDyingAndRespawn` · `testExtraLifeThresholds` · `testMultiplierSteps` · `testDefenceBonusOnce`.
- **Gate:** G2 = previous + **10** (canonical **275**). **Commit:** `DeimosCore: player update in FUN_10028170 order (film read stores the recorder's score), hits, death, respawn, level start, setup, score/lives/multiplier/money; 10 tests`.

### C11a — ⚑ MAJOR — Combat I: collisions, damage, hit delay, shield-depletion, pickups (→ +6, canonical 281) — ∥ C15, C19
- **Precondition:** read `FUN_10042f80`, the player-collision blocks of `FUN_10033850` (`10033894–100339c4`,
  `10034088–1003430c`), the obstacle block (`100344ec–1003456c`), `FUN_10036cf0` (`10036d64–100370f0`), `FUN_10014f10`
  (`10014f10–1001527c`), `FUN_10017e70`, `FUN_10037580`.
- **Files:** `Sources/DeimosCore/Combat/{Collision,Damage,Pickups}.swift`; `Tests/DeimosCoreTests/CombatTests.swift`.
- **Contract (damage-health-death §1–§3, §6; loose-ends-combat §3):** circle test strict, radius = half bbox height
  (signed int division); player ↔ entity (§2.3; ram 100 credited to the player index, then the player takes
  `damage_FLOAT`; pickups via `FUN_10037580`, then `destroyEntity` + `+0xca`); entity ↔ ground obstacle (§2.4); entity
  ↔ entity (§2.5, the B-side `passHitsToOwner` bug kept, stop when A deleted); hittable flag (§2.6); damage (§3 steps
  1–13, step 9b → `destroyEntity` or `FUN_10017e70`; hit particles via C13; shield sounds via `SoundPlay`).
- **Tests (6):** `testCircleStrict` · `testPlayerRamDealsHundred` · `testHitDelayPerVictim` (t and t+1 → one; t+2 →
  second) · `testBuzzsawDiesToOneIonHit` (`bu01` 0.4 − `icb ` 0.4 = 0.0 ≤ 0 → 50 to the killer, `destroyEntity`
  called) · `testShotResolvesPairOnce` · `testPickups` (`coin`, `exli` capped 10 with `noel`, `mult`, `shie` clamped
  0…100; `air `/`grnd` refused while invulnerable).
- **Gate:** G2 = previous + **6** (canonical **281**). **Commit:** `DeimosCore: collisions (player/obstacle/entity), damage + hit delay, shield-depletion state, pickups; 6 tests`.

### C15 — ⚑ MAJOR — Weapon handler, launchers, crosshair, score-bar weapon state (→ +9, canonical 290) — ∥ C11a, C19
- **Precondition:** read `FUN_1003b3c0` (`1003b404..1003b9ec`), `FUN_1003bf80`, `FUN_1003bff0`, `FUN_1003c0d0`,
  `FUN_1003beb0`, `FUN_1003b180`, `FUN_1003af90`, `FUN_1003ade0`, `FUN_1003c4f0`, `FUN_1003c7a0`, `FUN_1003bab0`,
  `FUN_1003bb40`, `FUN_1002adb0`, `FUN_1003cd30`/`cdb0`/`cca0`.
- **Files:** `Sources/DeimosCore/Weapons/{WeaponHandler,WeaponTick,Launchers,PowerUp}.swift` (the struct and the
  handler helpers `setupHandler`, `resetHandler`, `startWeapon`, `nextWeapon`, `scoreBarIcons` move out of
  `Player/Player.swift` — C15 edits `Player.swift` to move or change them; leg B I12),
  `Sources/DeimosCore/Player/Player.swift`, `Sources/DeimosCore/ScoreBar/ScoreBarState.swift` (power target = handler
  percent, icon rebuild); `Tests/DeimosCoreTests/WeaponTests.swift`.
- **⚑ Amendment (wave 2.4 reviews):** Files += `Player/{PlayerLife,PlayerUpdate}.swift` limited to the overload paths
  (`overloadTick`, `startOverload`, the start gate) — `testOverloadTimeline` exercises them; no other wave-2.5 task
  touches those files. Contract += `tickWeapons` must call `players[i].refreshFaceFromWeapon()` before returning when
  the weapon switched (the stub's dropped `switched` out-parameter), and stores the previous-fire bytes +0x9/+0xa/+0xb
  (1003b9d4); C14's stub body (Phase-1 crosshair update 1003b9ec..1003ba30) is replaced.
- **Contract (weapons-projectiles §2–§4, loose-ends-combat §6, HIGH):** `tickWeapons` in the §2.3 order; return codes
  1/2 to the player; fire rate + edge; switching + pending; availability by sector; power-up machine §2.5; bombs §2.7;
  launchers §3.2; icons; crosshair fade (flli 149/150) and the locked frame setter `FUN_1003bab0` (called by C12).
- **Tests (9):** `testIonShotSpawns` (`icb ` (203, 330), `icbf` (208, 322), `icb ` (212, 330), owner 0) ·
  `testAirEdgeAndCooldown` (spacing 5) · `testPowerUpActivationAndLevels` (t + 14; T0 + 3k; 100 % at T0 + 60; clamp at
  20) · `testOverloadTimeline` (T0 + 181; warnings S+9 … S+48; death S+54) · `testReleaseStream` (r … r+38, idle r+40)
  · `testSelectCycleBySector` · `testBombSalvo` (sector 1 → 1; sector 5 → 5 at t … t+8) · `testBombSpeedRatio` (81/121
  → 4.02 px/tick) · `testScoreBarPowerAndIcons`.
- **Gate:** G2 = previous + **9** (canonical **290**). **Commit:** `DeimosCore: weapon handler (fire, select, power-up/overload, bombs), launchers, crosshair, score-bar power + icons; 9 tests`.

### C19 — ⚑ MAJOR — Begin-frame keys and the console (→ +9, canonical 299) — ∥ C11a, C15
- **Precondition:** read `FUN_10030360` (`100303a0..10030564`), `FUN_10030910`, `FUN_10030640`, `FUN_10030870`,
  `FUN_10022ef0`, `FUN_100461b0`, `FUN_1002d1a0`, `FUN_1002d230`, `FUN_1002d410`, `FUN_1002d770`, the ten registered
  handlers and the `FUN_100051a0` registration block (`1000527c..100054f4`).
- **Files:** `Sources/DeimosCore/Game/{FrameKeys,Console,Cheats,FrameController}.swift`;
  `Tests/DeimosCoreTests/{FrameKeysTests,ConsoleTests}.swift`.
- **Contract (timing-frame §2.1, §2.6; messages-notices-console §2.5, §5; sound-music §4; front-end §8):** `FrameKeys`
  returns a value (`FrameKeysResult`: pause started, volume change, interlace toggled, quit) — C18a turns it into
  ops/cues. Caps Lock (pressed, not paused, not a film → paused + "Press Caps Lock" notice; the end-frame wrapper's
  pause = `haltEffects` at the current sound index, gaso 8 `incl` prio 50, `MusicCue.pause`, `.pauseWait(.gameScreen)`;
  resume: `MusicCue.resume`, notice clear). **Volume keys — Q4 RULED by Ben 2026-10-07 (D31): the Mac OS X behaviour only** (`FUN_100461b0` true — what Ben
  played, D30): `-`/`=` still change int pref 0 by ∓10 (clamped 0…100) but emit **no** gain change, no click, no
  message; the game plays at full level and the OS volume controls apply. The OS 9 branch is not built.
  F6 toggles byte pref 5 with pgsl 17/18 + gaso 7. FPS monitor (`ticks`) and
  the pref-9 counter text (formats 39/40). Console: open on `~` (flush typed queue, gaso 1), one char per frame, the
  **charCode table** (up-arrow 0x1E, backspace 0x08, Return 0x0D, line feed 0x0A; no auto-repeat — leg B m15), 30-char
  cap and 120-frame expiry → Return, recall, `~` sets the redraw flag, execute (uppercased name over the ten,
  `Unknown Command` type 1, gaso 4/5), input withheld while open, draw (formats 33/34, fade-out 4/frame); cheats.
- **Tests (9):** `testCapsLockPauseResult` (FrameKeys result: pause started, notice posted, the halt/`incl`/music-pause
  cue sequence; none in a film; leg B I6) · `testVolumeKeysOSX` (50 `-` → pref 40, no cue, no message; 100 `=` stays 100; 0 `-` stays 0; edge only) · `testF6Interlace` ("Interlacing      ON" (6 spaces) from 0) · `testFPSCounterText` (31
  frames → "31" in format 39; 29 → format 40) · `testConsoleTyping` · `testRegisteredCommandsOnly` ·
  `testCheatWordAndGate` · `testCheatLimits` · `testVersionText` ("Version: 1.0.6, Jan  2 2004, 11:55:08").
- **Gate:** G2 = previous + **9** (canonical **299**). **Commit:** `DeimosCore: begin-frame keys (Caps Lock pause, volume keys as on OS X (pref only), F6, FPS monitor) and the console with the 1.0.6 commands + cheats; 9 tests`.

### C11b — ⚑ MAJOR — Combat II: destruction, random bonus, media gate, removal sweep, terrain stamps (→ +6, canonical 305) — ∥ C17
- **Precondition:** read `FUN_10016300` (`10016300–10016528` + the bonus ladder to `1001685c`), `FUN_10016880`,
  `FUN_1000fee0`, `FUN_10036610`, `FUN_10036120`, `FUN_100363c0`, `FUN_100364f0`, `FUN_10034b90`, `FUN_10034de0`,
  `FUN_10036be0`, and the terrain-stamp path (`FUN_10012f20` with +0x36, sprite-geometry-draw §3.2).
- **Files:** `Sources/DeimosCore/Combat/{Destruction,Removal,MediaGate}.swift` (Destruction takes over C10's stub);
  `Tests/DeimosCoreTests/DestructionTests.swift`.
- **⚑ Amendment (wave 2.4 reviews, orchestrator 2026-10-07):** Files += `Player/PlayerLife.swift` (deletion only) and
  `Units/Spawn.swift` (the `removeEntities(ofUnit:ownedBy:)` stub tail only). Move C14's `destroyEntitiesOwned(byPlayer:)`,
  `removeEntity(serial:)` and `removeMemberStub` into `Combat/Removal.swift` under the same names (call sites in
  `killPlayer` / `showMultiplierIndicator` unchanged) and wire them and C8's tail to the real `FUN_10036120`; keep the
  walkers' counts snapshotted once (10034bc0 / 10034c14). `destroyEntity` gains/keeps the `now` argument per fix(C10).
- **Contract (damage-health-death §4, scoring §7, spawn-and-waves §5):** destroy (§4.1 order incl. the random-bonus
  ladder with the reward-armed rule); media gate (§4.2: map point (trunc x + 32, trunc y + top), mask index x / 5, y /
  5, water iff 0x001f — sprite-sound-containers §3.1 HIGH, row order MED as for the map; `smra`/`mera`/`lara` draws);
  sweep + `FUN_10036120` (accuracy decrement, **terrain stamp: `destructDrawToTerrain` → the entity's draw commands with
  the terrain flag appended to `tickOps`** (leg A I-8), owner destruction, deletion spawn, children, group kills,
  coins, PERM rule); direct removers.
- **Tests (6):** `testDestroyOrder` (glow off → obstacle (ground) → particles → spawn (media gate) → notice → sound →
  flags → accuracy count → `R(0, 100)` last) · `testRandomBonusLadder` (69 → `rb01`, 70 → `rb02`, 97 → `rb08`, 98 at
  sector 1 → `rb08`, at sector 3 → `rb09`; reward armed + r < 10 → `rb06` once) · `testPlatformSevenBombHits` (`plla`
  shields bits of 2.5999999 → 2.1999998, 1.7999998, 1.3999999, 0.9999999, 0.5999999, 0.1999999, then the 7th hit stores
  **0.0** (clamped) and destroys; 0 points; 2 × `cass` coins from the sweep; leg A m3) · `testGroupKillCoin` ·
  `testMediaGateWater` (a ground unit dying over a 0x001f mask cell spawns its water impact (`smra` → one `R(0, 1)`)
  and suppresses its destruct spawn) · `testDrawToTerrainStampsIntoTickOps` (a `plla` wreck adds terrain-flagged draws
  to `tickOps` during the sweep).
- **Gate:** G2 = previous + **6** (canonical **305**). **Commit:** `DeimosCore: destruction + random bonus, media gate, removal sweep + coins, terrain stamps into tickOps; 6 tests`.

### C17 — ⚑ MAJOR — End of level: tallies, level complete, game over (→ +8, canonical 313) — ∥ C11b
- **Precondition:** read `FUN_100072c0`, `FUN_100075e0` **states 1–5, 7, 9** (MED — record each wait and its flli),
  `FUN_10027670`, `FUN_10027930`, `FUN_10027db0`, `FUN_10007d60`, `FUN_10007170` (`10007194..10007268`), the level-end
  and game-over branches of `FUN_10006b50` (`10006c4c..10006ff4`).
- **Files:** `Sources/DeimosCore/Game/{Tallies,LevelEnd,TallyState}.swift` (TallyState taken over from C7);
  `Tests/DeimosCoreTests/LevelEndTests.swift`.
- **Contract (scoring-bonuses §6, level-scroll-objects §8, engine-loop §3):** first level-end tick (`nole`/`noal` at
  (208, 240) if someone is alive, players invulnerable, tier §6.3); later ticks: accuracy tally (§6.4), coin setup +
  tally per player (§6.5, `p1mc` at (105, 248)), then `levelComplete`; tally text draw `FUN_10007d60` (format 53);
  game over (`nogo`; running cleared when `gameTime > gameOverStart + 110`, i.e. on start + 111 — `10006d8c`); level
  complete → film: running cleared; ◇ S9.1 otherwise.
- **Tests (8):** `testAccuracyTiers` · `testTallyOvershoot` (tier 250 at sector 1 pays 300) · `testAccuracyTallyTimeline`
  (as read; re-derived by review leg 1) · `testCoinBonusSteps` (money 30 → 30 × 100; 60 → 50 × 120) ·
  `testMissionBonusNeedsAllLevels` · `testLevelEndSequenceOrder` (p15 order) · `testGameOverStopsOnStartPlus111` ·
  `testLevelCompleteClearsRunningInFilm` (GameFlags only; the pass-level check is C18a's — leg B I6).
- **Gate:** G2 = previous + **8** (canonical **313**). **Commit:** `DeimosCore: end of level (Sector Secured, accuracy tier + tally, coin bonus), game over, level complete; 8 tests`.

### C12 — ⚑ MAJOR — The entity update, the world update and the entity draw (→ +8, canonical 321) — alone in wave 2.7
- **Precondition:** read `FUN_10033850` end to end (`10033850..100345d8`) and record the step order with addresses as
  the doc comment; read the `FUN_1003bab0(h, 1)` call site and its condition (weapons §2.8 MED — record or STOP);
  `FUN_100345f0` (`10034a98–10034b5c`); `FUN_100298c0` (`100298c0..100299b8`, Bank corrections 3); `FUN_10006b50`
  (p15).
- **Files:** `Sources/DeimosCore/Units/EntityUpdate.swift`, `Sources/DeimosCore/Game/UpdateWorld.swift` (`extension
  GameState`), `Sources/DeimosCore/Draw/EntityDraw.swift`; `Tests/DeimosCoreTests/{EntityUpdateTests,EntityDrawTests}.swift`
  (EntityDrawTests: existing 5 kept, new ones added).
- **⚑ Amendment (wave 2.4 reviews):** per entity, call C9's `rotationGate` (`FUN_10017150`, only caller 10015b64,
  before the +0xc3 test) and then C10's `runSpawnSets` (which starts at 10015b6c); pass the state read before the
  motion controller (r18 from 10033e08) into `followOwner` / `copyFromOwner`; keep ONE nearest-player helper —
  delete the private nearest-player copy in `Units/Rules.swift` (line range moved after fix(C10) f1366d5 — re-find it) in
  favour of C9's `Motion.swift` one (Files += `Units/Rules.swift`, that deletion only). Act on `updateMotion`'s
  delete/destroy outcome, and turn an `integrateAndCull` false into the silent delete (+0xcb = 1, +0xd9 = 0xff).
  The same pre-controller state goes into C11a's `collideWithPlayers` and the entity↔entity Collides gate (10034580)
  (fix(C11a)); C12 calls `updateHittable` at 10033ea0 itself and names C11a's entry points (`collideWithPlayers`, the
  FUN_10036cf0 entity scan, the obstacle block) at their listing positions in FUN_10033850. The player ram also
  redirects to the owner when the state has passHitsToOwner (10034228) — C11a contract gap, built as the listing.
- **Contract:** `updateEntities(log:) -> Bool` (pause) = `FUN_10033850`: the per-tick player-collision cache, then per
  entity in group order: spawn-in countdown (state start re-stamped while counting) → state particles → state sound
  (AllowOnlyOneInstance = not playing) → timer (re-read the state) → **pause flag (`10033d70`)** → **animation step
  (`10033d8c`)** → **rules (`10033db0`)** → visibility/tint/scale targets + ramps + size + blink → owner copy
  `FUN_10036930` (`10033f58`) → destruct-if-scrolling (+0x352, `10033f5c`) → motion → integrate/cull → lock/link/orbit
  → spawn sets → player collision → motion blur (the `R(Min, Max)` draw before the interval test) → crosshair lock →
  obstacle → entity ↔ entity; then the sweep (leg A C-1, I-1, m8). `updateWorld(inputs:log:)` = `FUN_10006b50` in
  the p15 order (input → notices → debris → particles → blurs → players → score bar → game over → scroll step →
  level end → tallies → coins → entities → pause/resume) — C18a's pass calls it (leg B I7). `groupCommands(hOffset:)` =
  `FUN_100345f0` (per group: shadow pass, then sprite pass; entities with +0x36 target the terrain buffer, layers
  0–1). `playerCommands` = `FUN_100298c0` incl. the coin-tally text. `playerOps` stays as a wrapper (C18b removes it).
- **Tests (8):** `testUpdateStepOrder` (a synthetic entity records the order above; plus the census assertion: every
  state with `AllowOnlyOneInstance` has sound `none`) · `testUpdateWorldOrder` (the p15 order through `log`) ·
  `testMidControllerPausesScroll` (le07 filtered to `01m1`, via `updateWorld`: created **1660** at (134, −64); pause
  state **1840**; top frozen at **1279** for 1841…2640 (**800** ticks); **1278** at 2641; level end **3918**; bound
  4,200) · `testBridgeControllerPausesAtTop346` (filtered to `01b1`: created **2543**, `tapu` at absolute (480, 140)
  heading 285 at 2583, S1 at **2773**, frozen from 2774 at **346**) · `testCrosshairLock` (as read; re-derived by leg 1)
  · `testGroupShadowThenSpritePass` · `testPlayerCommandsAndCoinTallyText` · `testBlurEmittedEveryTickWithZeroInterval`.
- **Gate:** G2 = previous + **8** (canonical **321**). **Commit:** `DeimosCore: entity update in FUN_10033850 order + sweep, world update in FUN_10006b50 order, entity group draw, player commands with the coin-tally text; 8 tests`.

### C18a — ⚑ MAJOR — `DeimosSession` Phase 2: the loop, film playback (→ +8, canonical 329) — alone in wave 2.8
- **Precondition:** read `FUN_100051a0` (`10005738..10005ae4`: set-up, film branch `FUN_100069b0`, loop body, film
  overlay `10005a1c..10005aa0` — the REPLAY banner is format **0x26 = 38**, GameString 9, +0x244 = 15, +0x245 = 1,
  +0x248 = 0, `10005a50..10005a9c`, **not drawn on the pass that ends the film** (`10005a48 → 10005aa4`) — leg A m15),
  `FUN_100064d0` (`100064d0..10006984`), `FUN_10007070`, `FUN_10030bc0` (`10030bec..10030dc4`), `FUN_10009750`.
- **Files:** `Sources/DeimosCore/Game/DeimosSession.swift`; `Tests/DeimosCoreTests/{DeimosSessionTests,FilmPlaybackTests}.swift`,
  `Tests/DeimosRenderTests/LevelOneFrameTests.swift`.
- **⚑ Amendment (wave 2.4 reviews):** set `GameState.film` and `flags.filmPlaying` together (PlayerUpdate yields no
  input when the flag is set without a film); send `MusicCue.level(pref music volume)` at session start (A2 review m4 —
  the engine starts at the pref-100 level).
  **Pause (C19 reviews, orchestrator ruling):** the pause pass's music ends at `.pause`; C19's `PauseScreen.musicAfterWait`
  (`[.resume]`) becomes the FIRST music cue of the next pass (that pass begins only after the host's `.pauseWait` and
  present — ≤ one frame late, inaudible; LOCKED seams unchanged). `FrameKeysResult.volume` never becomes a gain cue
  (D31). Console open withholds input only on tick frames (1004aa20) per C19's result. Call C19's level-transition
  reset (FUN_100302e0 pieces) where FUN_10007170 runs.
  **One sector source (C15 reviews):** Files += `ScoreBar/ScoreBarState.swift` — `levelStart` / `update` take `sector:` and
  pass it to `scoreBarIcons(sector:)` (callers TestWorld, DeimosSession); set `flags.sector` from the film/start; then
  retire the Phase-1 `Player.sector` copy.
- **Contract:** the session holds a `GameState`, the frame controller, console and key state; **every existing public
  property** (`gameTime`, `appeared`, `sector`, `rng`, `running`, `scoreBar`, `scroll`, `players`, …) stays as a
  forwarding accessor (invariant 12; DriverTests/LevelOneFrameTests read them). `init` = `FUN_100051a0` set-up (seed =
  `start.film?.seed ?? seed`; sector from the film's level; players from the film) then `FUN_100064d0` (music `[.play(
  ammu), .stop]` when not a film (S9.4); players' level start (draws); resets; scroll level start incl. the mask;
  `FUN_10032e60` + pending list; load pass; `no01` (0 draws) at (208, 240); black fill; score bar; first terrain blit;
  ). `pass(keys:ticks:)`: begin frame (`FrameKeys`, console) → tick: appear check
  (level music then the fade — not in a film) → `updateWorld` → level complete → game time + 1 → **`tickOps`** → draw
  world (groups → blurs → players → tally text → notice → score bar) → film banner → end frame (messages → FPS counter
  → console → flush 0–1 → terrain → flush 2–5 → `.particles` → flush 6–15 → limit → present) → pause (FrameKeys result
  → halt index, `incl`, music pause, `.pauseWait(.gameScreen)`). Film: inputs from the film (C14), session ends when
  `film.finished` (checked after every draw) or any key is held. Session end (not film): `haltEffectsAt` = current
  index, `MusicCue.stop`. **Re-pointed (counts unchanged):** `DeimosSessionTests` (11 — `testInitOps` and
  `testSteadyPassOrder` gain the new ops; `testDeterministicReplay` asserts a different seed **changes** the outputs
  by the first spawn); `LevelOneFrameTests` (6 — oracles mask every drawn command's rect; goldens **re-derived**,
  recorded with the HectorKit + Classics SHAs, re-derived by the second leg; `HeadlessRun` gains `init(film:)` (carry:
  film/start params) and steps `.pauseWait` as a no-op).
- **Tests (8):** `testLevelStartDrawsAndOrder` (a **non-film** start seeded 0x469c2: after `init` the RNG has made 1
  draw (`R(400, 2000)` = 1446); `no01` at (208, 240); music `[play(ammu), stop]`; leg A m10) · `testAppearStartsLevelMusic`
  (game time 2: `.play(mu03, loop: true)` before `.fade`; a film emits no music) · `testFilmInputsAndEnd` (inputs only
  in state 4; frames + 1 input ticks then end; bound frames + 200) · `testReplayBanner` (format 38 every film pass
  except the ending one) · `testDrawAndEndFrameOrder` (incl. `tickOps` before draw world and `.particles` between the
  flushes) · `testCapsLockPassSequence` (the pause pass: notice drawn, present, halt index before `incl`,
  `.pauseWait(.gameScreen)` last) · `testLevelCompleteEndsFilmSession` (pass-level: `sessionEnded` on the tick
  `levelComplete` is set in a film) · `testSessionEndHaltsAudio` (Esc: `haltEffectsAt` + `MusicCue.stop`).
- **Gate:** G2 = previous + **8** (canonical **329**), G3, G5. **Commit:** `DeimosCore: DeimosSession Phase 2 — full level start, update/draw/end frame in the original order, film playback, pause; Phase-1 session and frame tests re-pointed; 8 tests`.

### C18b — minor — Phase-1 stub removal and the early de01 check (→ +1, canonical 330) — ∥ H2
- **Files:** delete `Sources/DeimosCore/Player/PlayerPhase1.swift`; `Sources/DeimosCore/Draw/EntityDraw.swift`
  (remove `playerOps`); `Tests/DeimosCoreTests/{PlayerPhase1Tests,TestWorld,EntityDrawTests}.swift`,
  `Tests/DeimosCoreTests/EarlyReplayTests.swift` (new).
- **Contract:** `PlayerPhase1Tests` (7) and `TestWorld` (used by ScoreBarStateTests, ScoreBarDrawTests,
  TextLayoutTests, EntityDrawTests) call `updatePlayer`; same numbers. **Early warning (leg B I17; not a gate):** run
  the de01 session logic-only to game time 1,700 (bound 2,000 passes) and print a first-divergence report (deaths,
  draws per 100 ticks, spawns by game time).
- **Tests (1):** `testEarlyDemo01Report` (asserts only data-driven facts that hold whatever the pilot does: the
  `bsgr` group is requested at game time **77** at (371, −64); `01m1` is created at **1660** (no unit can pause the
  scroll before it — p16); prints the report).
- **Gate:** G2 = previous + **1** (canonical **330**). **Commit:** `DeimosCore: remove the Phase-1 player stub and playerOps; early de01 report; 1 test`.

### H2 — ⚑ MAJOR — DeimosHost: driver Phase 2 + headless runner + replay trace (→ +8, canonical 338) — ∥ C18b
- **Files:** `Package.swift` (S1 H2 line), `Sources/DeimosHost/{DeimosDriver,HeadlessRunner,FilmReplay,ReplayTrace}.swift`;
  `Tests/DeimosHostTests/{DriverTests,ReplayHarnessTests}.swift` (DriverTests: existing kept).
- **⚑ Amendment (C19 reviews):** a driver test proves the audio sink receives `.resume` only after Caps Lock goes up (the
  pass after the wait); across an app suspend/resume during the wait, music stays paused (the original's pause flag
  r2−0x617b blocks the resume handler 10023e7c).
- **Contract:** S6. Driver: `pass(keys:ticks:)`; a pass's cues go to `audio` when the pass begins (sounds with the halt
  index, music — the original issues them inside the tick; ≤ one frame early, inaudible);
  **`.pauseWait(p)`** yields until an `idle` sees `capsLock == false`, then `present(p)`; typed characters accumulate
  across `idle` calls into the next pass; **Esc latch** clears when **any** `idle` sees Esc up (carry); ◇ restarts keep
  the ended session's prefs (S9.6); level complete / game over end the session like Esc. `HeadlessRunner` (logic only
  unless asked to render; `maxPasses`), `FilmReplay` (seed/sector/players from the film; `scoreAtRead4808` from
  `FilmCursor.score(player: 0, atRead: 4808)`), `ReplayTrace` (a `TickTrace` row per ticked pass: game time, cursor, P1
  state/score/lives/shield/money/multiplier, draws, entities, groups, scroll top, paused, levelEnding; CSV).
- **Tests (8):** `testPauseWaitHoldsUntilCapsUp` (fake-clock cap 120 s) · `testCuesRoutedAtPassBegin` (a recording sink
  sees each pass's cues once, in order, with the halt index) · `testTypedQueueAcrossIdleCalls` ·
  `testEscLatchClearsOnSubPassRelease` (fails on the Phase-1 driver) · `testPrefsSurviveRestart` (F6 then Esc → the
  carried prefs value has pref 5 set; asserted on the carried prefs, not mid level-start — leg B m16) ·
  `testHeadlessRunnerFromFilm` (de01 → sector 1, seed 0x469c2, 1 player) · `testFilmReplayEndsOnePastLastByte` (a
  synthetic 10-frame film ends after 11 input ticks, `.filmEnd`) · `testReplayTraceCSVHeader`.
- **Gate:** G2 = previous + **8** (canonical **338**). **Commit:** `DeimosHost: driver Phase 2 (pause wait, audio cue routing, typed keys, Esc latch on any idle, prefs carry), HeadlessRunner, FilmReplay, ReplayTrace; 8 tests`.

### H3 — minor — `deimos-replay` and the de01 gate (→ G4 bundle 3)
- **Files:** `Package.swift` (S1 H3 line), `Sources/deimos-replay/main.swift`,
  `Tests/DeimosReplayTests/{ReplayGateTests,ReplayTestData}.swift` (own data locator).
- **Contract:** `deimos-replay <film tag>… [--trace file.csv] [--frames dir --every N] [--all]` — committed data
  (`DEIMOS_DATA` overrides); per film the G4 line plus the G4.3 progress numbers; `--all` = de01–de04 (de02–de04
  print `INFO`). Exit 0 iff de01 passes.
- **Tests (3, G4 bundle):** `testDemo01ReachesScore25050AtRead4809` (**G4**: `scoreAtRead4808` = 25,050; `maxPasses`
  20,000) · `testReplayIsDeterministic` (two runs to game time 1,000 → identical trace hash) · `testCLISummaryLine`.
- **Gate:** G2 = **338/0**; G4 (green, or recorded "pending trace" → F1 — G4.2). **Commit:** `deimos-replay: film replay + per-tick score trace; the de01 gate (25,050 at read 4,809); 3 tests`.

### A3 — ⚑ MAJOR — App: audio, typed keys, Caps Lock, film argument (no tests) — needs K2 on HK main, A2, H2
- **Files:** `project.yml` (S7), `Deimos/App/{DeimosController,DeimosMain}.swift`.
- **Contract:** `DeimosAudioEngine` created at launch (failure → silent, like `FUN_10047160`'s non-fatal path) and
  attached with `ShellMixer.attachStream`; the driver gets it as `audio`; the stream is paused while the app is
  suspended. Key-down characters (no repeats) mapped to Mac charCodes per C19's table (NSEvent 0xF700-range arrows →
  0x1C–0x1F; delete → 0x08; return → 0x0D) into `HeldKeys.typed`; Caps Lock into `capsLock`. ◇ `-film deNN`.
- **Gate:** G5, plus machine-observable checks (leg B I13): a DEBUG-only counter of cues routed and frames rendered by
  the engine (the SDLAudioOut `framesRendered` pattern), logged; a 30-second launch shows both counters rising and
  the `.pauseWait` path reached with Caps Lock simulated through `HeldKeys` in a DEBUG hook. Audible checks are Ben's
  (gate card). **Commit:** `Deimos app: audio through the kit stream voice, typed keys + Caps Lock, -film argument; project.yml DeimosAudio`.

### A4 — minor — Stage + the gate card
- **Files:** `Deimos/WHAT-TO-EXPECT.md` (and `tools/stage-deimos.sh` only if staging needs a change).
- **Contract:** staging unchanged; WHAT-TO-EXPECT = what Phase 2 is and is not, the keys, the S9 stand-ins, design §7
  deviations, the G4 line (or "pending trace" with the F1 status), and the gate card below verbatim.
- **Gate:** G1 on HK main, G2 = **338/0**, G3, G4 (or pending trace), G5, G9. **STOP for Ben.** **Commit:** `Deimos: Phase 2 staged — WHAT-TO-EXPECT (gate 2 card)`.

### F1 — conditional — replay triage (orchestrator-owned; only if G4 is red)
G4.3–G4.4. Fix commits `fix(<task>): …` under that task's Files, one Opus leg each, G2 + G4 re-run after each.

### B1 — docs — bank corrections (orchestrator-run, after A4)
- **Files:** `docs/deimos/*.md` named in "Bank corrections to append" plus every correction in the Phase 2 PR notes,
  `docs/deimos/INDEX.md` (one line each).
- **Contract:** append each as a ⚑ note in its topical file (INDEX append rule); no other task edits the bank.
- **Commit:** `docs(deimos): Phase 2 bank corrections`.

---

## What Ben checks — Phase 2 gate card ("does it play like Deimos")

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
   power-up charging (meter fills in 2 s), release = a stream of power shots; hold ~6.5 s = overload flashes and the ship
   blows up at ~8.3 s. **Plasma Bomb** (Option) flies 114 px up toward the crosshair 121 px ahead, then bursts; down at
   the bottom edge pulls the crosshair in. **Select** (Space) does nothing in sector 1 (only one air weapon).
5. **Hits and death:** 7 full hits kill; the ship explodes, coins spill, 2.7 s (last life 1.3 s) then you re-enter
   invulnerable for 2 s. Game over after the last life → the game starts again (◇).
6. **Score / coins / multiplier:** kills × multiplier; coins and pickups; extra life at 10,000 / 40,000 / 80,000.
7. **Level end:** "Sector Secured", ground-accuracy tally with ticking count, coin bonus, the defence bonus if you
   were never hit; then the game starts again at sector 1 (◇ — the campaign is Phase 3). Wrecked platforms and tanks
   stay painted into the map.
8. **Sound:** effects from the game's own mixer (at most 8 at once); the level music starts as the screen fades in.
   **Q2 (pitch):** bullet impacts `exsl` play short and high (speed = 1/pitch, as the code). If the longplay's impacts
   are deep and slow, say "flip pitch". **Q3 (music level):** music sits about half as loud as a full-volume effect
   (full scale 255). Too quiet? Say so.
9. **Volume keys `-`/`=` (Q4, your ruling):** as on Mac OS X — they do nothing you can hear and show no message; the
   game plays at full level and your Mac's own volume controls set the loudness.
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
Q5 (invulnerability carry-over) is not reachable until level 2 (Phase 3).

---

## Execution order

| wave | HectorKit | lane Core | lane Audio/Render | lane Host/App/docs | review legs (Opus) |
|---|---|---|---|---|---|
| 2.0 | K2 (push, pull --ff-only) | C0 | A1 | — | K2 two; C0 one; A1 two |
| 2.1 | — | C13 ∥ C16 | A2 (after K2 on main) ∥ R4 | — | one each |
| 2.2 | — | C7 ⚑ | — | — | two |
| 2.3 | — | C8 ⚑ | — | — | two |
| 2.4 | — | C9 ⚑ ∥ C10 ⚑ ∥ C14 ⚑ | — | — | two each |
| 2.5 | — | C11a ⚑ ∥ C15 ⚑ ∥ C19 ⚑ | — | — | two each |
| 2.6 | — | C11b ⚑ ∥ C17 ⚑ | — | — | two each |
| 2.7 | — | C12 ⚑ | — | — | two |
| 2.8 | — | C18a ⚑ | — | — | two |
| 2.9 | — | C18b | — | H2 ⚑ | C18b one; H2 two |
| 2.10 | — | — | — | H3 ∥ A3 ⚑ | H3 one; A3 two |
| (F1) | — | — | — | replay triage, only if G4 red | one per fix |
| 2.11 | — | — | — | A4 → Ben | one |
| 2.12 | — | — | — | B1 (orchestrator) | — |

- **Disjoint files inside a wave** (each task's Files; a split pair never shares a wave or a file): 2.0 C0 `Seams/*`,
  `MSLRandom`, `DeimosAssets`, `Audio/*`, one switch in `DeimosRenderer.swift`, `DeimosSessionTests` (`kind`); A1
  `Package.swift` + `DeimosAudio/*` + `DeimosAudioTests/*`. 2.1 C13 `Effects/*`; C16 `Game/{NoticeSlot,MessageQueue}`; A2
  `DeimosAudio/{MusicStream,DeimosAudioEngine}`; R4 `DeimosRender/{DeimosRenderer,ParticleStamps}`. 2.4 C9
  `Units/{Motion,Animation,OwnerLinks}`; C10 `Units/{StateTimer,Rules,SpawnSets,PowerupRelease}` + the
  `Combat/Destruction.swift` stub; C14 `Player/{Player,PlayerUpdate,PlayerLife,PlayerScoring}` + the
  `Weapons/WeaponTick.swift` stub. 2.5 C11a `Combat/{Collision,Damage,Pickups}`; C15 `Weapons/*`, `Player.swift`,
  `ScoreBarState.swift`; C19 `Game/{FrameKeys,Console,Cheats,FrameController}`. 2.6 C11b
  `Combat/{Destruction,Removal,MediaGate}`; C17 `Game/{Tallies,LevelEnd,TallyState}`. 2.9 C18b (Core stub removal +
  Core tests) ∥ H2 (`Package.swift`, `DeimosHost/*`, `DeimosHostTests/*`). 2.10 H3 (`Package.swift` after H2,
  `deimos-replay`, `DeimosReplayTests`) ∥ A3 (`project.yml`, `Deimos/App/*`).
- **Shared files, one owner per wave:** `Package.swift` (A1 → H2 → H3), `DeimosSession.swift` (C18a only),
  `project.yml` (A3), `EntityDraw.swift` (C12 → C18b), `Player.swift` (C14 → C15), GameState files (C7; later only
  under invariant 13).
- Cross-task calls go through `extension GameState` methods named in each contract and the two hook stubs (invariant
  14); C12's crosshair lock and world update use C15's and C17's named methods.
- One Opus implementer per task (`fk-implementer`), own `--scratch-path`; the orchestrator merges, re-runs G1–G11 at
  the merge head, updates STATE, ends each session with a handoff + `spawn_task` chip (2–3 tasks per session; MAJOR
  tasks ≈ one seat each).

---

## Pre-execution self-audit

1. **Scope coverage.** Unit system: timer (C10), 17 rules (C10), spawn sets (C8 arming, C10 executor), motion +
   animation (C9), culling (C9), groups/PERM (C7), owner links (C9) ✅. Collision/damage (C11a), destruction/removal/
   terrain stamps (C11b) ✅. Player physics + respawn + death (C14) ✅. Weapons + power-ups/overload + bombs +
   crosshair lock (C15, C12) ✅. Pickups/coins/multiplier (C11a, C11b, C14) ✅. Particles/debris/blur (C13, C12, R4) ✅.
   Notices/messages (C16) ✅. Scroll pauses (C10, C12) and level end + tallies (C17) ✅. Effects mixer + music (A1, A2) +
   K2 ✅. Pause, Esc, `-`/`=`/F6, console + cheats (C19, C18a, H2) ✅. Machine gate de01 (H3, G4; early check C18b) ✅.
2. **Carries placed.** `HeadlessRun` film/start params → C18a (test helper) + H2 (`HeadlessRunner`) ✅. `playerOps`
   return type → C12 (`playerCommands`) + C18b (delete) ✅. Esc latch eats sub-pass releases → H2 ✅. P1 button mapping →
   C0 + D31 ✅. Phase-4 prefs file → carried forward (S9.6) ✅. DeimosAudio decision → A1 + ruling ✅.
3. **Ladder arithmetic.** C0 6, A1 8, C13 8, C16 6, A2 7, R4 3, C7 8, C8 11, C9 10, C10 9, C14 10, C11a 6, C15 9,
   C19 9, C11b 6, C17 8, C12 8, C18a 8, C18b 1, H2 8 = **149** → 189 + 149 = **338** (G2) ✅; H3 3 in the G4 bundle ✅.
   K2 +4 (326) / +1 ✅.
4. **Numbers re-derived by probe** (Research notes p11–p18; leg A re-ran every one) ✅. Float pins are bit patterns
   where the leg A emulator gave non-round values (pitch 0x3f0693da; hold-up; platform shields) ✅. Self-derived or
   "as read": re-derived Phase-1 goldens (C18a), trace hash (H3), trig bits (C7), tally timeline (C17), crosshair lock
   (C12), REPLAY banner geometry (C18a) — each re-derived by the task's first review leg ✅.
5. **RNG order** (invariant 6) owned per site incl. C9's animation and cyclic draws; each task's precondition records
   its addresses ✅.
6. **Risks.** The film may predate the 1.0.6 code (G4.2–G4.4, F1) ✅; trig last-ulp ✅; D-number collision ✅; real-time
   audio in review (offline paths, A3 counters) ✅; long critical path C7 → C8 → wave 2.4 → 2.5 → 2.6 → C12 → C18a → H2 →
   H3 (Audio/Render/Kit lanes beside it), with the early de01 report at C18b ✅.

---

## Open questions for Ben (the build proceeds on the defaults; all on the gate card)

- **Q2 — pitch direction** (design §11.2, INDEX #49): default **as the code** — speed = 1/pitch.
- **Q3 — music loudness** (§11.3, INDEX #50): default **full scale 255** — music at 128/255 of a full effect.
- **Q4 — volume keys** (§11.4, INDEX #44/#52): **RULED by Ben 2026-10-07 (D31): the Mac OS X behaviour** — keys
  silent, no in-game volume, unity gain; the OS volume controls apply ("can't we just have the game default to 100% and
  use the system controls?").
- **Q5 — invulnerability carry-over** (§11.5): default **as read**; not reachable in Phase 2.
- **Only if G4 misses:** "the demo was recorded on an earlier build" — Ben's eyes on `-film de01` decide (G4.4).

---

## Bank corrections to append (task B1 appends them, with every correction from the Phase 2 PR notes; no implementer edits the bank)

1. **level-scroll-objects.md §7 / units-movement.md §2.1** (cull, "exact mode-1 expression not settled", MED): listing
   `10012d48..10012e38` — `FUN_10012ca0(e, m, 1)` keeps the entity iff `x + hw ≥ −m`, `x − hw ≤ W + m`, **`y ≥ −m`
   (no half-height)**, `y − hh ≤ H + m` (W 416, H 480, float compares of int conversions); mode 0 (`10012e3c..10012f00`)
   uses `x + hw ≥ C+0xc`, `x − hw ≤ W + 32`, `y + hh ≥ C+0`, `y − hh ≤ H` (C = `*(r2−0x7240)`). MED → HIGH.
2. **damage-health-death.md §5.3** (death, MED decompile): listing `10027e74..10028150` — `FUN_10034b90` →
   `death_Spawn_ID` request (`10027f18`) → shields zeroed if not in game → `+0x204/+0x208/+0xd1` = 0 → **displayed
   shield and power set to 0.0** (`FUN_10031710`/`FUN_10031760` at `10027f4c`/`10027f5c`, value `0x100d6fc8`+0 = 0.0
   — new) → coin loops 50/10/5/1 (`10028044…100280ec`) → money 0 → state 3 → `+0xce` → multiplier check and reset.
   MED → HIGH.
3. **micro-wave-2026-10-06.md §3.9** (player draw): `FUN_100298c0` continues after the sprite pass
   (`10029930..100299a0`): if coin-tally state `+0xd8 ≠ 0` and alpha `+0xe0 < 32` → text format 30 (`li r3,0x1e`;
   `Player_MoneyCount` `plmc`) with the text at `+0xec`, BlendAmount = alpha, +0x10c = 15, +0x10d = 1, +0x110 = 0,
   Loc_Y += `+0x1f8`, drawn by `FUN_1000d380` — the coin tally's text is drawn by the player draw (state 4 only).
   Also corroborates INDEX #62's 0-based `idli gate` → format indexing (format 30 = `plmc`, 27/28 = `lsca`/`lscf`).
4. **engine-loop.md §3 / bosses.md §2.1** (`FUN_10006b50` order, callee roles MED): the listing's call sequence is
   `10006b7c` input clear → `10006b84` console-open test → `10006b94` ISp read → `10006bb0` P1 state == 4 →
   `10006bd0` notices → `10006bd8` debris → `10006be0` particles → `10006be8` blurs → `10006c14` players (loop) →
   `10006c34` score bar → `10006c4c…10006d6c` game-over path (`nogo`) → `10006d9c` scroll step → `10006dd4…10006f44`
   first level-end tick (`noal`/`nole`, `FUN_10027de0`, `FUN_100072c0`) → `10006f58` accuracy tally → `10006f7c…
   10006ff4` coin bonus → `1000702c` entities → `1000703c`/`10007048` scroll pause/resume. Order HIGH.
5. **INDEX #14 / timing-frame.md §6 / engine-loop.md §8** (button slots, LOW): the guide's "Default Controls" table
   (GUIDE): Fire Air Weapon = Command, Select Air Weapon = Space Bar, Fire Ground Weapon = Alt/Option, Esc, Caps Lock,
   F6, Tilde — pins slots 4/5/6 = fire air / fire ground / select (cite only). Film census: the select bit (bit 6)
   appears in de02 (15 ticks, sector 2), de03 (26, sector 3), de04 (3, sector 4) and never in de01 (sector 1, one air
   weapon) — consistent with bit 6 = select.
6. **engine-loop.md §7 / data-census.md** (film provenance, new): `Game.pak` ZIP mtimes — `de01` 2001-12-03 13:39,
   `de02` 13:51, `de03` 13:58, `de04` 14:02; newest `unde` 2001-12-02 16:11 (`07e1`), `leve` 2001-12-02 12:47 (`le09`),
   `flli`/`idli` 2001-11-12, `wede`/`plde` 2001-10-14 — the demos postdate every game-data entry the replay reads; only
   the `stli` string lists are newer (`Attributions[cred]` 2002-05-01 10:38 — strings, no replay effect); the binary is
   1.0.6 (2004-01-02). `Local/film/Last Film[last].film` is byte-identical to `de01`.
7. **bosses.md worked example table / player-physics.md worked example** (float32 shortening, leg A m3): the platform
   shields are 2.5999999, 2.1999998, 1.7999998, 1.3999999, 0.9999999, 0.5999999, 0.1999999, then −0.2000001 computed but
   **0.0 stored** (damage §3 step 4 clamp); the hold-up y column is 325.19998 at tick 2, 298.40002 / 290.60004 /
   282.80005 at ticks 6–8, and the rest position is 252.00006, not 252.0.
8. **units-movement.md §5.5 / §8.1 vs engine-loop.md §9** (RNG consumer table): the cyclic-motion draws (`FUN_10016fe0`
   `10017024`, `10017054`, two per tick per cyclic entity) and the random-frame draw (`FUN_10015930` `10015a0c`, per
   animation step with `ContinuousFrameRandomisation`) are per-tick consumers missing from engine-loop §9's per-entity
   order; in le07 they are reached by 30 cyclic coin states and the `plsh` player-shield states (leg A C-1, I-2).

---

## Research notes (planner probes, 2026-10-07, `$SCRATCH/planner/*.py` over the committed data; not committed)

- **p11 — the four demo films** (`film.py`; `Film` decoder agrees with Phase 0's `testFourDemosAndLastFilm`):
  | film | level (sector) | seed | P1 frames | score | bit ticks L/R/U/D/FG/FA/SEL | first non-zero input | last non-zero |
  |---|---|---|---|---|---|---|---|
  | de01 | le07 (1) | 0x469c2 (289,218) | 4,809 | 25,050 | 1233/1204/1102/1306/318/2025/0 | 47 (left) | 4784 |
  | de02 | le06 (2) | 0x4f655 | 8,357 | 116,180 | 2161/2162/1760/1877/863/3361/15 | 43 | 8321 |
  | de03 | le02 (3) | 0x54c83 | 10,058 | 57,520 | 2592/2575/2101/2386/687/4372/26 | 37 | 10044 |
  | de04 | le08 (4) | 0x5afed | 5,649 | 24,670 | 1490/1463/1213/1304/514/2250/3 | 37 | 5606 |
  All version 0x2715 (the 1.0.6 loader's), one player, header pad zero, P2 block empty. Film ticks count **active
  (state 4) ticks only** (loose-ends-session §7): de01's tick 0 is game time 56 when the ship never dies. de01's last
  24 recorded ticks carry no input — consistent with the ship idling through the end-of-level tallies; with no deaths
  its last recorded tick is game time exactly 56 + 4,808 = **4,864**, while the level end falls in [3,919, 4,718]
  (3,118 + `01m1`'s fixed 800-tick pause + 1…800 ticks of `01b1`'s — its timer deletes it at T0 + 1030 without a
  paused tick; leg A m4), so the gate almost certainly includes the tallies and the defence/coin bonuses. A film session ends at
  level complete (`FUN_10007170`), so the recording's stored level `le07` means the recorder's game ended in le07 or
  during le06's 55-tick entry (not recorded).
- **p12 — provenance:** see Bank corrections 6.
- **p13 — RNG and float32 values** (MSL LCG + float32 emulation): srand(1): `R(10, 11)` = 10 (rand 16838); `F(0.50,
  0.55)` = 0.5256935; `F(0.8, 1.2)` = 1.0055482 (= Phase 1 p08); seed 0x469c2 first rands 26662, 28174, 2951, 23987,
  25976. Shields: 2.6f = 2.5999999; 4.0 + 0.4·2 = 4.8000002; player shield 33.3 stored with the +1324366.0 bias reads
  33.25. `0x100d6fc8` = {0.0, 100.0, 1324366.0, 1.0}.
- **p14 — particle colour variants** (§2.7 arithmetic in float32, c = 31 on all channels): c16 63487; core 30, 27, 23,
  19, 16; fringe 18, 16, 14, 11, 9 (5-bit) → variant 0 core 0x7BDE, fringe 0x4A52. To be re-derived from the listing
  (C13).
- **p15 — `FUN_10006b50` call order:** Bank corrections 4 (listing bl scan `10006b50..10007070`).
- **p16 — le07 placements and controllers:** 38 placements of 11 units (`bu01` 21, `plla` 4, `bsgr` 3, `bsat` 2, `geys`
  2, `01b1`, `01m1`, `gebd`, `grob`, `sels`, `tapu`); spawn game time t = 3055 − yLoc with no earlier pause (first:
  `bsgr` y 2978 → t 77; `01m1` y 1395 → 1660; `01b1` y 512 → 2543; last `bu01` y 149 → 2906 + pauses). `01m1`: group 1,
  delay 0, timers 180 → "Pause 30 secs, spawn Buzzsaws" (pause, 800 → Delete, set `bu01` rate 100–115); `01b1`: timers
  40 → "Spawn Tank, Wait" 190 → "Pause Until RULE…" (pause, 800 → Delete, rule #5 → Delete). `no01`: every range
  closed → 0 draws at level start.
  **Reachability** (`reach2.py`, transitive over every `*_ID` in `unde`, from the placements + `pl01` + `aiic` + `plbo`
  + the engine's `gaob` roots): **102 units / 209 states** of 386 / 1,167; **38 effect sounds** of 96 (+ the `gaso`
  set); 64 spawn sets; live rules only 4 (`01b1` #5, `gebd` #14, `pllc`/`tapc` #2); pickups `coin`, `exli`, `shie`,
  `mult`; 3 hunting states, 30 cyclic, 2 orbit, 57 lock, 0 link, 2 pause, 3 blur (all 0/0), 2 random-bonus droppers, 3
  obstacle makers; air weapons at sector 1: Ion Cannon only. So de01 exercises a quarter of the unit data; every
  mechanism in the task list is generic, and de02–de04 (`--all`) exercise more.
- **p17 — the guide's Default Controls:** Bank corrections 5.
- **p18 — `FUN_10012ca0` mode 1:** Bank corrections 1.
- **Settled at the review fix pass:** the REPLAY banner (format 38, +0x244 15 / +0x245 1 / +0x248 0, not drawn on the
  ending pass — leg A m15), the "P1 active" gate (`10006bb0`, loose-ends-session §4), the media-mask scale (÷5,
  sprite-sound-containers §3.1), the stamp D-pixel colour (fringe — leg A I-5), the G4 sampling instant (leg A I-3).
- **Still left to task preconditions:** the trig build precision (C7), `FUN_100075e0` states 1–5/7/9 (C17), the
  crosshair-lock call site (C12), `FUN_100d1d90` (no listing — disassemble first, A1). Each task records its reading;
  anything still MED goes on the gate card.
