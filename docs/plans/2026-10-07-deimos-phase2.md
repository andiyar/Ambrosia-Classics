# Plan — Deimos Rising Phase 2: level 1 plays (gate 2) — 2026-10-07

> Status: **DRAFT — not yet reviewed** (planner: Claude Opus 5.5, 2026-10-07). Implements
> `docs/plans/2026-10-06-deimos-design.md` §8 **Phase 2 only**, under Ben's rulings **D27** (whole game; feel oracle =
> longplays + his eyes), D29 (layers, render model, seams LOCKED) and **D30** (gate 1 passed; `TickRate.osx` 60 Hz).
> Reviews are **Opus only** (Ben, 2026-10-07): ⚑ MAJOR = two Opus legs (spec compliance, then quality); minor = one.
> Fable only for the whole-phase final review if the orchestrator asks for it.
> **Format (Ben, 2026-10-03): CONTRACTS, not code** — files, public names (signatures only where they pin a seam),
> behaviour with bank anchors (file § or listing address), test names verbatim with the number each checks and its
> source, gate commands, commit messages. No implementations.
> **Numbers:** from the bank (file § + label), a listing address in `$LISTING`, or a planner probe run on this machine
> on 2026-10-07 over the committed `Resources/Deimos` (cited "probe pNN", Research notes). Self-derived goldens are
> named as such. Where a probe and the bank disagree, the probe wins and "Bank corrections" says so.
> **D-number:** this plan reserves **D31** "Deimos Rising build: Phase 2 rulings (seat)" — renumber at commit time if
> taken on `main` (D23/D24 and D28/D29 collided before).

**Goal.** Sector 1, Mariner Valley (`le07`), plays as the original: the 38 placements spawn at their rows, the two
`Level` controllers pause the scroll and throw Buzzsaw waves, the ship flies, fires the Ion Cannon (tap and power-up
with overload), drops Plasma Bombs at the crosshair, collides, takes hits, dies, respawns and loses lives; kills score
(× multiplier), coins and pickups collect, random bonuses roll, particles/debris/motion blur show, notices and
messages appear, the level ends at the top of the map with "Sector Secured", the accuracy and coin tallies and the
defence bonus; sound effects through the game's own 16-voice mixer and the level music; Caps Lock pause, Esc,
`-`/`=` volume, F6 interlace, the `~` console with the commands 1.0.6 registers. **Machine gate:** the shipped demo
film `de01` (which records `le07`, probe p11) replays headless and its player-1 score is **25,050 at its 4,809th
recorded tick**. **Ben's gate:** he plays level 1 — "does it play like Deimos".

**Scope.** Design §8 Phase 2. Not in scope (Phase 3+): sectors 2–12 as a campaign (the engine is data-driven and runs
any level, but level complete ends the session — ◇ S9), the level transition fade/next sector, two-player play in the
app (the logic is per player and tested; the app starts one player), the finale, front end, attract mode, high
scores, the prefs file, the configuration/controls dialogs, Windows.

**Architecture (design §3, D29.1).** `Deimos/Core` grows: **DeimosCore** (rules — units, combat, player, weapons,
effects state, notices, console; all simulation state in one value `GameState`), **DeimosRender** (+ particle stamps),
new **DeimosAudio** (Foundation + DeimosCore + HectorAudio + Synchronization — the game's 16-voice effects mixer and
the music streamer behind one pull source; ruling below), **DeimosHost** (driver: pause yield, cue routing, typed
keys; public `HeadlessRunner`, `FilmReplay`, `ReplayTrace`), new executable **`deimos-replay`** (the score-trace tool).
**Deimos/App** plays the PCM stream through the new kit stream voice (K2). HectorKit gains one additive API (K2).

**DeimosAudio ruling (design-review M6) — recommend a separate target, and why.** (1) Threading: the mixer is pulled
on the audio thread and must be `Sendable` behind a `Mutex`; DeimosRender is a single-threaded executor of `RenderOp`s
— mixing the two models in one library muddies both. (2) Portability: the Windows shell (Phase 5) links the same
target unchanged behind `SDLAudioOut(source:)`; it needs no pixels. (3) Test isolation and compile time: audio tests
(PCM, IMA, ranking) do not rebuild the blitters. (4) The design's "Render owns every pixel and every PCM sample" only
said where audio could live; nothing in DeimosRender is shared with audio. Rejected: mixer in DeimosRender (layering-
legal but conflates threading models); mixer in DeimosCore (Core would own wall-clock state and real-time locks;
it must stay a pure function of ticks).

**Tech:** Swift 6.4 / Xcode 27, SwiftPM tools 6.0, XCTest, macOS 15 deployment, xcodegen (`project.yml` is truth).
Python 3 only as the planner's probe tool (never a build or test dependency).

**Paths:**
```
WT      = /Users/andiyar/Developer/Ambrosia-Classics/.claude/worktrees/<lane worktree>   (branch deimos-phase2, from main)
HK      = /Users/andiyar/Developer/HectorKit        (main 522feb8, zero-skip FLOOR 316 at plan time; Cythera's K1 is
                                                    pending at 8040b86 / floor 322 — K2's floor is relative, invariant 8)
HKWT    = /Users/andiyar/Developer/HectorKit-worktrees/deimos-k2   (branch deimos-k2, K2 only)
LISTING = /Users/andiyar/Developer/Ghidra/deimos/proj/disasm-review3-all.txt  (+ mem/10000000.bin code,
          mem/100de330.bin data; r2 = 0x100e6330). There is NO decompile.
GUIDE   = /Users/andiyar/Developer/Ambrosia/Resources/ambrosia-extracted/Action-Adventure/DeimosRising/
          Deimos Rising 1.0.6 (volume)/Deimos Rising/Deimos Rising Player Guide/Deimos Guide.html   (cite only)
SCRATCH = the executing session's scratchpad directory (logs, dumps, builds; never the repo)
```

---

## Verification model (read first)

**Machine gates — executors close these alone** (copy literally):

| # | gate | command | expected |
|---|---|---|---|
| G1 | HectorKit zero-skip (K2) | `HECTORKIT_TEST_LOG="$SCRATCH/hk.log" "$HKWT/tools/check-zero-skip.sh" 2>&1 \| tail -n 1` | `PASS: zero skips, zero failures, executed N == floor N`, N = (floor on HK main at the rebase) + 4 (= 320 if main is still 316; 326 if Cythera's K1 landed first) |
| G1b | HectorSDL suite (K2) | `cd "$HKWT/SDL" && swift test 2>&1 \| grep -cE "^Test Case '.*' passed"` and `… failed` | previous SDL total + 1, then `0` |
| G2 | `Deimos/Core` suite | `cd "$WT/Deimos/Core" && swift test --scratch-path "$SCRATCH/build-<task>" > "$SCRATCH/dm.log" 2>&1; grep -cE "^Test Case '.*' (passed\|failed\|skipped) \(" "$SCRATCH/dm.log"; grep -cE "^Test Case '.*' (failed\|skipped) \(" "$SCRATCH/dm.log"` | the task's ladder total, then `0` |
| G3 | census unchanged | `testStdoutEqualsCommittedCensus` green inside G2; `git -C "$WT" diff --stat main -- docs/deimos/data-census.md` | empty |
| G4 | **de01 replay (the Phase 2 machine gate)** | `cd "$WT/Deimos/Core" && swift run --scratch-path "$SCRATCH/build-replay" deimos-replay de01` | last line `de01 le07 seed 0x469c2: score 25050 at tick 4809 (end: <reason>) PASS` — rule G4 below |
| G5 | apps build | `cd "$WT" && xcodegen generate && for s in Deimos Aki BubbleTroubleX; do xcodebuild -scheme "$s" build 2>&1 \| tail -n 1; done` | `** BUILD SUCCEEDED **` ×3 |
| G6 | scope fence | `git -C "$WT" diff --name-only <task base>..HEAD` | ⊆ the task's **Files** (+ `docs/DECISIONS.md` where the task says so) |
| G7 | layering | `grep -rnE "^import (AppKit\|UIKit\|SwiftUI\|CoreGraphics\|CoreText\|ImageIO\|AVFoundation\|QuartzCore\|HectorGraphics\|HectorShell)" "$WT/Deimos/Core/Sources/"{DeimosCore,DeimosRender,DeimosHost,DeimosAudio,deimos-replay}` | empty (`import Synchronization` is allowed — stdlib, Windows-safe) |
| G8 | kit game-agnostic (K2) | `grep -rniE "deimos\|ambrosia" "$HKWT/Sources" "$HKWT/SDL/Sources" --include=*.swift \| grep -v HectorTestSupport` | empty |
| G9 | staged app boots (A4) | `open "$WT/out/Deimos/Deimos Rising.app"; sleep 8; pgrep -x "Deimos Rising"; osascript -e 'quit app "Deimos Rising"'; ls -t ~/Library/Logs/DiagnosticReports \| head -3` | a pid; clean quit; no new crash report naming the app |
| G10 | clean tree per commit | `git -C "$WT" status --porcelain \| grep -v '^??'` | empty after every commit |
| G11 | no hangs | every test that runs passes, a driver or a mixer has an explicit bound (`maxPasses`, `maxIdleCalls`, `maxFrames`) and `XCTFail`s on reaching it; `swift test` runs only on the task's own `--scratch-path` | a hung test is a FAIL of the task, never "re-run" |

**G4 — the replay gate, and the rule when it misses.** FILMs can predate the code or data they ship with (BTX lesson,
memory "FILMs predate 1.1"). Probe p12 shows `de01–de04` were saved (ZIP mtime 2001-12-03 13:39–14:02) **after** every
`unde`/`leve`/`wede`/`plde`/`flli`/`idli` entry in `Game.pak` (newest 2001-12-02 16:11) — they match the shipped
*data*; the shipped *binary* is 1.0.6 (built 2004-01-02), so code drift 1.0 → 1.0.6 is the remaining risk.
1. **PASS** = the replay's P1 decoded score after the tick that consumed film byte index 4808 (cursor becomes 4809) is
   25,050, and the session then ends within one tick by film end (cursor > frames, `FUN_10009750`) or level complete
   (`FUN_10007170`, film branch). `deimos-replay` prints the end reason.
2. **MISS** → never edit expectations. `deimos-replay de01 --trace "$SCRATCH/de01.csv"` writes one row per tick
   (H2 `ReplayTrace`). The executor reports the **first divergence tick T**: the earliest trace event a reviewer cannot
   justify from the bank/listing (an unexplained death, a spawn at an unexpected row, a kill whose score is not the
   unit's `score_INT × multiplier`, a draw-count step at a site the bank does not list, the scroll freezing at an
   unexpected top). The partial-progress numbers reported with every run: end reason, cursor at session end vs 4,809,
   P1 deaths (tick, cause), score at cursor 1,000 / 2,000 / 3,000 / 4,000 / 4,809, game time of level end, accuracy
   %, money at the coin tally, multiplier history.
3. A divergence is a **bug** until two Opus reviewers have each re-read the listing at every address the trace's
   event at T depends on and agree the replica follows 1.0.6 exactly. Only then may it be recorded as **"de01
   predates the 1.0.6 code"**: Ben watches the replay (`-film de01`, S9 ◇) against his memory/longplays; the gate then
   lands as **"traced to first divergence T, ruled"** in D31 (seat) with Ben told. `de02–de04` are run by the same
   tool as information (they are Phase 3 gates); agreement or disagreement across the four is evidence for the ruling.

**Test ladder (`Deimos/Core`, cumulative, canonical merge order; STOP if different):** baseline **189** (Phase 1,
D29 as built) → C0 **195** → A1 **203** → C13 **211** → C16 **217** → A2 **223** → R4 **226** → C7 **234** → C8
**244** → C9 **253** → C10 **262** → C14 **272** → C11 **282** → C15 **291** → C17 **299** → C19 **308** → C12
**315** → C18 **323** → H2 **331** → H3 **334**. Lanes may merge in another order inside a wave: expected total =
previous total + the task's N. Re-pointed Phase-1 tests keep their names and count (C18). HectorKit: K2 **+4** main
(G1), **+1** SDL (G1b).

**Honesty gate (Ben only):** the gate card (A4). Completion is phrased "machine gates green; Ben's gate pending".

**What the machine does NOT prove:** pitch direction (Q2), music loudness (Q3), the volume law under an app gain (Q4),
the 24→16 sprite colour cut (Phase 0 note 15, still MED), particle colours (§2.7 arithmetic re-derived, look is
Ben's), MathLib last-ulp agreement of the trig tables (INDEX #45 — the replay is the only machine witness), whether
the original could tear (it could; whole-frame presents, design §7.1).

---

## Non-negotiable invariants

1. **Layering (HectorKit D6, D12, D29.1).** DeimosCore: Foundation + HectorResources + HectorAudio. DeimosRender:
   Foundation + DeimosCore. **DeimosAudio: Foundation + DeimosCore + HectorAudio + Synchronization.** DeimosHost:
   Foundation + DeimosCore + DeimosRender + DeimosAudio. `deimos-replay`: Foundation + the four. `Deimos/App` alone
   imports AppKit / HectorShell / AVFoundation. Windows traps (D18/W0.5): no `String.Encoding.macOSRoman`, no
   `UserDefaults` below the App.
2. **Kit stays game-agnostic** (G8). K2's doc comments describe pull streams, never a game.
3. **Transcribe, don't reinvent.** Every behaviour cites its bank section or listing address; a contract here never
   overrides the bank — if they disagree, STOP and report (the listing settles it; record a bank correction).
4. **No modern affordances** (CLAUDE.md). Phase 2's only additions are the ◇ stand-ins of S9 and design §7's
   deviations; each is on the gate card.
5. **Data in git, tests never skip** (D24.3). A missing file is a FAILURE naming the path.
6. **Every RNG draw at its original site, in the original order** (engine-loop §9; spawn-and-waves §9;
   particles-debris-blur §1; sound-music §8.6). Per tick the order is the `FUN_10006b50` call order (listing-read
   here, Research p15); per entity the `FUN_10033850` order (waves-and-enemies §3, units-movement §1); per spawned
   member the `FUN_10035cd0` order (spawn-and-waves §3.2). A draw is made even when its result is discarded (refused
   requests, muted sound — sound-music §8.6). The pre-seed `FUN_10046580(400, 2000)` at the top of `FUN_100051a0`
   stays unmodelled (it precedes `srand`; Phase 1 invariant 6).
7. **Float fidelity.** Single precision (`Float`) wherever the listing has `fadds/fsubs/fmuls/fdivs`; **`fmadds`/
   `fmsubs`/`fnmsubs` are fused (one rounding) — use `addingProduct`/`fma`, never `a*b + c`** (placement
   `10037960..10037b20`, rotated offsets `10016070..100160f0`, mode-2 α); `fctiwz` = truncate toward zero; int → float
   via the 0x43300000 magic is exact. Double only where the listing uses `fmul`/`fdiv` then `frsp`.
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
    (d) D-numbers collide: confirm D31 on `main` at commit. (e) Decode sprite groups and sounds once per test process
    (static caches); never decode all 2,554 frames or a whole music track in a unit test. (f) A Phase-1 implementer's
    unguarded test hung another's run (handoff 2026-10-07) — G11.
12. **Seams are additive only** (D29.1): S3 lists the Phase 2 additions; no existing case, field or signature is renamed
    or removed. Adding a `RenderOp` case updates every exhaustive switch in the same commit (C0).

---

## Hazards for every implementer reading the listing (from the bank; read before any listing work)

- **No decompile exists.** Cite listing addresses only; bank lines that cite "the dump" are re-read in the listing when
  a test pins them. Listing + memory images: `~/Developer/Ghidra/deimos/proj/`.
- **Static initialisers rewrite templates before `main`** (INDEX #56, static-init-audit §5): spawn-request templates
  `0x100e64b0` / `0x100eb41c` / `0x100ecd14` have **+0x24 = −1** at runtime (image 0); the draw template clip is
  {0,0,480,416}. Use runtime values.
- **The `lwzu/stwu` +8 copy-loop trap** (hud-scorebar §4: `0x100eb228`, not `…224`) — any struct copy loop
  `subi r5,r7,0x4` hides +4/+8.
- **Signed-compare idiom** `eqv; subfc; rlwinm; addze; rlwinm` = signed `rB < rA` (timing-frame §7); `FUN_10009750`'s
  `xor; srawi; and; subf; rlwinm` = signed `a > b` (loose-ends-session §7).
- **Trig tables are computed at start-up by MathLib** (`FUN_10042920`, BSS — units-movement §2.3): sin/cos 360 floats,
  atan 1024 ints, sqrt 16384 floats. The replica computes them with Foundation; the argument precision (float
  `i·0.017453f` or double) is read at `10042a00..10042a60` before coding (C7 precondition). A last-ulp mismatch would
  surface only as a replay divergence (INDEX #45) — the trace rule G4.2 covers it.
- **Same-pass semantics.** Lists are appended at the tail (`FUN_100009e0`, INDEX #38) and iterated by re-reading the
  count: an entity or group created during a pass is processed by the same pass (loose-ends-combat §4.5); a deleted
  entity is only flagged (`+0xcb`) and reaped by `FUN_10036610` after the entity loop.

---

## Shared architecture (LOCKED — every task codes against these names)

### S1. Package `Deimos/Core`
`Package.swift` gains, task by task: **A1** library product + target `DeimosAudio` (deps `DeimosCore`, HectorAudio)
and test target `DeimosAudioTests` (`DeimosAudio`, `DeimosCore`); **H2** adds `DeimosAudio` to the deps of
`DeimosHost` and `DeimosHostTests`; **H3** adds executable `deimos-replay` (deps `DeimosHost`, `DeimosRender`,
`DeimosAudio`, `DeimosCore`) and test target `DeimosReplayTests` (`deimos-replay`, `DeimosHost`, `DeimosCore`).
New Core sources go under `Sources/DeimosCore/{Math,Units,Combat,Effects,Weapons,Player,Game,Audio}/`.

### S2. DeimosCore public surface (★ LOCKED after Phase 2 · ◇ Phase-2 stand-in)
- ★ **`GameState`** (C7, `Game/GameState.swift`) — the whole mutable simulation, one value: `assets` (let), `prefs`,
  `rng: MSLRandom`, `flags: GameFlags` (the G struct, scoring-bonuses §1.2 + level-scroll-objects §8 tables: running
  +0x08, levelComplete +0x09, noPlayerAlive +0x0a, allLevels +0x0d, levelsStarted +0x10, sector +0x14, level +0x18,
  gameTime +0x1c, filmPlaying +0x20, levelEndHandled +0x29, levelEndTime +0x2c, appeared +0x38, levelEnding +0x39,
  groundCreated +0x3c, groundDestroyed +0x40, perfectLevels +0x44, the accuracy-tally fields +0x48…+0x160, reward-armed
  +0x0c, cheat counters +0x16c…+0x17c), `scroll: ScrollState`, `world: EntityWorld`, `players: [Player]` (2),
  `scoreBar: ScoreBarState`, `particles: ParticleSystem`, `debris: DebrisList`, `blurs: MotionBlurPool`, `notice:
  NoticeSlot`, `messages: MessageQueue`, `cues: CueBuffer`, `film: FilmCursor?`, `trace: TickTrace?`, `mask` (the
  level's media mask, loaded with the map). Every rule
  module is an `extension GameState` in its own file (disjoint files per task). No module keeps its own copy of
  `rng` or `gameTime`.
- ★ `Trig` (C7, `Math/Trig.swift`) — the start-up tables and helpers: `sin(_:)`/`cos(_:)` (`FUN_10042f00`/`ee0`, 360 →
  0), `internalHeading(_ compass:)` (`FUN_10043040`), `vector(heading:speed:)` (`FUN_10042b80`), `headingTo(...)`
  (`FUN_10042ad0` → `FUN_10043090`), `headingOf(vx:vy:)` (`FUN_10042cd0`), `root(_ n: Int32) -> Float`
  (`FUN_10042f20`), `distance(...)` (`FUN_10042e90` = root(trunc(dx²+dy²))).
- ★ `Entity` (C7; `GameObject` + the entity fields of spawn-and-waves §1.3, units-movement §3, damage §2–§3: unit
  index, state index, serial +0x9c, group id +0xa0, spawn-in countdown +0xb0, state start +0xa4, timer +0xb8, flags
  +0xc1…+0xda, owner +0x140/+0x144, owner player +0xd8, killer +0xd9, shields +0x134, last hit +0xb4, per-state spawn
  records +0x19c, heading +0x138, velocity copies +0x100…+0x114, flee target +0x11c/+0x120, orbit +0xdc/+0xe0,
  offsets +0x124…+0x130, sound counters +0xe4/+0xe8/+0x14c, particle bursts +0xf0/+0xf4, blur +0xec); `EntityGroup`
  (0xbc record, §1.2); `EntityWorld` (pool of 1000 slots with the free hint of micro-wave §3.7, serial counter from
  1000, group-id counter from 20000000, the PERM group first, the active group list, the pending level-object list,
  the "notice shown once" list, `groundCount` mirror).
- ★ `SpawnRequest` (C7; the 0x2c record of spawn-and-waves §1.1 / weapons-projectiles §3.1 with the runtime +0x24 = −1)
  and `SpawnResult` (`{entity index, serial}` — `FUN_10035cd0`'s out-param).
- ★ `CueBuffer` (C0, `Audio/CueBuffer.swift`) — the pass's `[SoundCue]`, `[MusicCue]`, `haltEffects`, `masterVolume`;
  `SoundPlay.record(_:allowMultiple:rng:)` = `FUN_100475e0` (volume = MinVolume twice — no draw; pitch =
  `rng.range(minPitch, maxPitch)`; nothing when the id is `none`), `SoundPlay.perm(_:priority:volume:allowMultiple:)`
  = `FUN_10047670` (pitch 1.0, no draw).
- ★ `ParticleSystem`, `DebrisList`, `MotionBlurPool` (C13); `NoticeSlot`, `MessageQueue` (C16); `WeaponHandler`
  moves to `Weapons/WeaponHandler.swift` (C15, same name, fields grow); `Console`, `FrameKeys` (C19); `FilmCursor`
  (C7: the film plus a cursor per player; `next(player:)` = `FUN_100097a0` — the byte at the cursor, 0 past the
  recording, cursor + 1; `finished` = `FUN_10009750`, signed P1 cursor > frames) and `TickTrace` (C7 declares the row
  shape; C18 records it).
- ★ `Player` gains the full field set of player-physics §1 (C14). ◇ `Player.updatePhase1` stays as a wrapper until
  C18 switches the session to `GameState.updatePlayer(_:input:)`, then C18 deletes `PlayerPhase1.swift`.
- ★ `EntityDraw.playerCommands(_:hOffset:floats:) -> [DrawCommand]` (C12; the carry "playerOps return type": every
  entity-draw builder returns `[DrawCommand]`; C18 wraps them as `.draw` and deletes `playerOps`).

### S3. Seam additions (additive only; C0 unless named)
Notation: the new cases and stored fields are added to the existing declarations (Swift extensions cannot add
them); defaults keep every existing initialiser call compiling.
```swift
extension RenderOp {   // new cases
    case particles([ParticleStamp])        // FUN_10043ba0 at 10030cd0: written into the back buffer between flush 2…5 and 6…15
    case pauseWait(PresentKind)            // FUN_10030870 → FUN_10022ef0: blocking; the host waits for Caps Lock up, then presents
}
public struct ParticleStamp: Equatable, Sendable { public var x, y: Int32; public var core, fringe: UInt16; public var fade: Int32 }   // top-left, §2.9
extension PassOutput { public var haltEffects: Bool /* FUN_100476a0 */; public var masterVolume: Int32? /* int pref 0 after -/= */ }   // defaults false / nil
extension HeldKeys { public var typed: [UInt8] }   // key-down charCodes (Mac Roman, no auto-repeat) since the last pass — GetOSEvent for the console; default []
extension MSLRandom { public private(set) var draws: UInt64 }   // rand() calls since srand (trace only)
extension DeimosAssets { public let unitIndex: [FourCC: Int] }   // unde tag → definitions.units index (FUN_1003d2f0 / FUN_1003d550)
extension DeimosSession { public mutating func pass(keys: HeldKeys, ticks: UInt32) -> PassOutput }   // C18: ticks = TickCount at begin frame (FPS monitor FUN_10030640 only); pass(keys:) = ticks 0
```
`SoundCue`, `MusicCue`, `ShellRequest`, `DrawCommand`, `SessionStart` are unchanged (SessionStart.film is used from C18).

### S4. DeimosRender additions (R4)
`DeimosRenderer.apply(.particles(stamps))` — the 7×7 stamp of particles-debris-blur §2.9 into the back buffer;
`.pauseWait` is the host's (precondition, like `.fade`/`.limit`).

### S5. DeimosAudio public surface (A1, A2)
```swift
public protocol DeimosAudioSink: AnyObject, Sendable {    // what the driver feeds, in pass order
    func apply(sounds: [SoundCue], music: [MusicCue], haltEffects: Bool, masterVolume: Int32?)
}
public final class DeimosAudioEngine: DeimosAudioSink, PCMPullSource {   // PCMPullSource = K2
    public init(index: TagIndex, assets: DeimosAssets) throws      // preloads every soun effect (sound-music §2.3 step 4)
    public let outputRate: Double                                  // 44100 (FUN_100d1400)
    public func render(into: UnsafeMutableBufferPointer<Float>, frames: Int)   // audio thread: interleaved stereo float32
}
```
Internals (A1/A2, not LOCKED): `IMAContinuous` (the load-time conversion + decoder), `EffectMixer` (16 voices, 8
audible, 1024-frame blocks), `MusicStream`, all state under one `Mutex`.

### S6. DeimosHost additions (H2, H3)
`DeimosDriver.init(assets:prefs:rate:start:audio:)` (`audio: (any DeimosAudioSink)?` = nil keeps every Phase-1 test);
`public struct HeadlessRunner` (logic-only or rendering; `init(assets:start:seed:prefs:)`, `init(assets:film:)`,
`mutating func run(maxPasses:) -> ReplayResult`); `public struct FilmReplay` (`static func run(film:assets:trace:) ->
ReplayResult`); `ReplayResult` (`endReason` `.filmEnd/.levelComplete/.gameOver/.bound`, `cursor`, `scoreAtFrames:
Int32?`, `passes`); `ReplayTrace` (CSV writer of `TickTrace` rows).

### S7. App + `project.yml` (A3)
`project.yml` Deimos target gains `{ package: DeimosCore, product: DeimosAudio }`. `DeimosController` creates the
`DeimosAudioEngine`, attaches it with `ShellMixer.attachStream(_:)` (K2), feeds key-down characters and Caps Lock into
`HeldKeys`, and hands the engine to the driver.

### S8. K2 — HectorKit surface (additive)
```swift
// HectorAudio (Foundation-only)
public protocol PCMPullSource: Sendable {
    var outputRate: Double { get }
    func render(into buffer: UnsafeMutableBufferPointer<Float>, frames: Int)   // interleaved stereo float32, frames × 2
}
extension PCMMixer: PCMPullSource {}                                            // it already has both members
// HectorShell (macOS)
extension ShellMixer { public func attachStream(_ source: any PCMPullSource) -> Int; public func detachStream(_ id: Int); public func setStreamPaused(_ id: Int, _ paused: Bool) }
// HectorSDL (SDL package)
extension SDLAudioOut { public convenience init(source: any PCMPullSource) throws }   // init(mixer:) becomes init(source: mixer)
```
The stream voice is one `AVAudioSourceNode` in the source's format (44.1 kHz stereo float) into the main mixer, which
converts to the device rate (sound-music §8: device plumbing is implementation detail). The render block calls the
source directly (no lock in the kit); the source owns its own thread safety.

### S9. ◇ Phase-2 stand-ins (each on the gate card; each replaced by a named later phase)
1. **Level complete** (`flags.levelComplete` with a player alive) ends the session like the film branch of
   `FUN_10007170`; the driver starts a new game at sector 1 (Phase 3: fade to black, next sector).
2. **Game over** (`nogo`, 110 ticks) ends the session; new game at sector 1 (Phase 4: scores, menu).
3. **Esc** ends the session; new game at sector 1 (Phase 4: menu). The Esc latch (D29 as built) now clears on a
   release seen by **any** `idle` call (carry: final-review note, H2).
4. **Level-start music**: the original stops the level-select `ammu` at level 1's load and starts `mu03` at the
   appear tick (sound-music §6.4); with no level select the session emits `[.play(ammu, loop: true), .stop]` at load
   (net silence) — Phase 4 makes `ammu` real.
5. **Film launch argument** `-film deNN` (A3) plays a demo in the app (Ben's fallback oracle, G4.3) with the original's
   film rules (any key ends it, `REPLAY` banner, no level music); Phase 4's attract mode replaces it. The menu's
   `inmu` that the original keeps playing under a film is absent until Phase 4.
6. **Prefs live in memory only** — F6 (pref 5), `FPS` (pref 9), `supermunki` (pref 11) and the volume (int pref 0)
   persist across ◇ restarts (H2) but not across launches (carry: Phase-4 prefs file, C1 review m3 — Phase 2 does not
   need it; carried forward explicitly).
7. **One player** in the app; two-player games are Phase 3 (the rules are tested for both indices).
8. A film is not ended by the mouse (`FUN_10048e60` also tests the button) — `HeldKeys` carries no mouse (Phase 4).

---

## Tasks

Legend: ⚑ MAJOR = two Opus review legs (spec compliance, then quality; report everything with confidence); minor =
one leg. "+N" = new `Test Case`s. Every task: G6, G7, G10, G11, plus the gates named. Every task's PR notes list
each listing address it read and anything it found MED.

### K2 — ⚑ MAJOR — HectorKit: pull-PCM stream voice (+4 main, +1 SDL)
- **Files ($HKWT):** `Sources/HectorAudio/PCMPullSource.swift` (new), `Sources/HectorAudio/PCMMixer.swift` (conformance
  only), `Sources/HectorShell/ShellMixer.swift`, `SDL/Sources/HectorSDL/SDLAudioOut.swift`,
  `Tests/HectorAudioTests/PCMPullSourceTests.swift` (new), `Tests/HectorShellTests/ShellMixerStreamTests.swift` (new),
  `SDL/Tests/HectorSDLTests/SDLHostSmokeTests.swift` (one test), `tools/check-zero-skip.sh` (FLOOR),
  `docs/DECISIONS.md` (next free HectorKit D-number), `docs/STATE.md` (one line).
- **Contract:** S8 exactly. `attachStream` returns a stream id; streams render after voices into the main mixer; a
  paused stream renders silence and keeps the source untouched (the source is not called); `detachStream` removes
  the node; the render block never allocates; offline manual rendering works for tests (the existing `ShellMixer`
  offline init). `SDLAudioOut.init(source:)` pulls `source.render` in ≤ `chunkFrames` chunks exactly as `init(mixer:)`
  did (which now forwards). Real-time safety notes in doc comments; no game names (G8). Memory rule: no real-time audio
  crash smokes in review (BTX playable lane) — reviewers use the offline path.
- **Tests (4 main):** `testPCMMixerIsAPullSource` (a `PCMMixer` passed as `any PCMPullSource` renders bit-identically to a
  direct `render(into:frames:)` call on a twin mixer) · `testStreamRendersSourceOffline` (offline 44100
  Hz: a source writing a ramp is heard at the main mixer output, frame-aligned) · `testPausedStreamIsSilentAndUncalled`
  · `testDetachStopsCalls`. **SDL (1):** `testAudioOutAcceptsPullSource` (opens with a closure source, start/stop).
- **Gate:** G1 (new floor = rebase floor + 4), G1b, G8; Aki + BTX `xcodebuild` against it (G5). Rebase, re-gate,
  `git push origin HEAD:main`, clean `pull --ff-only` in `~/Developer/HectorKit`.
- **Commit:** `HectorAudio/HectorShell/HectorSDL: PCMPullSource + ShellMixer stream voice + SDLAudioOut(source:); floor <N>`.

### C0 — minor — Seam additions, sound-cue builders, draw counter, unit index; D31 (→ 195, +6)
- **Files:** `Sources/DeimosCore/Seams/{RenderOp,PassOutput,HeldKeys}.swift`, `Sources/DeimosCore/Seams/ParticleStamp.swift`
  (new), `Sources/DeimosCore/Game/{MSLRandom,DeimosAssets}.swift`, `Sources/DeimosCore/Audio/{CueBuffer,SoundPlay}.swift`
  (new), `Sources/DeimosRender/DeimosRenderer.swift` (the two new `case` arms only: `.particles` → empty body with a
  "R4" comment, `.pauseWait` → the host precondition), `Tests/DeimosCoreTests/Phase2SeamTests.swift` (new),
  `docs/DECISIONS.md`.
- **Contract:** S3 and the `CueBuffer`/`SoundPlay` lines of S2. `SoundPlay.record`: listing `10047600–1004764c` —
  `id == none` → no draw, no cue; else volume = `R(min, min)` (no draw), priority = `Priority & 0xFF`, pitch =
  `rng.range(MinPitch, MaxPitch)` (draw unless equal), cue appended. `unitIndex` built once in `DeimosAssets.load`.
  **DECISIONS D31** "Deimos Rising build: Phase 2 rulings (seat)": DeimosAudio target (the ruling above), S3 additions,
  cue routing at pass begin (H2), S9 stand-ins, the button mapping pinned to the guide (p17), Q2–Q4 built on their
  defaults (Q5 not reachable in Phase 2), the G4 rule incl. "predates the code", prefs file stays Phase 4.
- **Tests (6):** `testPassOutputAdditiveDefaults` (haltEffects false, masterVolume nil, typed []; the two new
  `RenderOp` cases round-trip `Equatable`) · `testRandomDrawCounter` (srand(1): `range(10, 11)` = 10 from rand 16838
  (p08), draws 1; `range(5, 5)` and `range(1.0, 1.0)` leave draws at 1) · `testSoundRecordDrawsPitchOnly` (srand(1),
  record `exsl` MinVol 100 MaxVol 70 Prio 0x132 pitch 0.50–0.55 → cue volume 100, priority 0x32, pitch 0.5256935
  (float32 bits exact; p13), draws 1; id `none` → no cue, draws 0; sound-music §2.3) · `testPermSoundNoDraw` (gaso 18
  `wesw`, 75, 100, true → pitch 1.0, draws 0; sound-music §7) · `testUnitIndex` (386 entries; `bu01` → "Buzzsaw Mk 1";
  `none` absent; data-census) · `testButtonMappingMatchesGuideAndFilms` (KeyTable slot bits up, left, right, down,
  fireAir, fireGround, select; ⌘ → fireAir, ⌥ → fireGround, Space → select per the guide's Default Controls; film
  census: ticks with bit 6 set de01 0, de02 15, de03 26, de04 3 — select appears only in sectors with ≥ 2 air weapons,
  weapons-projectiles §2.4 table; p11/p17).
- **Gate:** G2 = **195/0**, G5 (DeimosRender still builds). **Commit:** `DeimosCore: Phase 2 seam additions (particles, pauseWait, haltEffects, masterVolume, typed keys), CueBuffer + SoundPlay, draw counter, unit index; DECISIONS D31; 6 tests`.

### A1 — ⚑ MAJOR — DeimosAudio: the continuous-IMA conversion and the 16-voice effects mixer (→ +8, canonical 203)
- **Precondition:** read `FUN_100d1d90` (the ima4 → continuous conversion, sound-music §2.2 is MED on the dump) and
  `FUN_100d32d0` (`100d32d0–100d3528`) in `$LISTING`; record the exact nibble order, the dropped word, the
  index/predictor clamps and the accumulator arithmetic as doc comments. STOP if §2.2/§3.2 disagree.
- **Files:** `Package.swift` (S1: `DeimosAudio` product + target, `DeimosAudioTests`);
  `Sources/DeimosAudio/{IMAContinuous,EffectMixer,Voice}.swift`; `Tests/DeimosAudioTests/EffectMixerTests.swift`.
- **Contract (sound-music §2.2–§3.2, HIGH unless marked):** load = `{'asnd', sampleCount = (bytes − bytes/34)·2, rate,
  'mIMA'}` stream; decoder carries predictor/index across packets (index clamp 0…88, predictor ±32767); voice list of
  16 × the §3 voice struct; insertion `FUN_100d18d0` (priority 0 → 1, gains clamp 0x80, first slot whose (priority,
  L+R) the new voice equals-or-beats on **both** keys, refusal at 16 when below all, the 16th overwritten when count ≥
  16); gain per side `trunc(128·volume/100)` (single precision, `10047dcc..10047e0c`); `step = FixMul(FixDiv(44100,
  rate), pitch16.16)` with `pitch16.16 = trunc(65536·pitch)`; per voice `FUN_100d32d0`: `acc += step>>4` per input
  sample, `n = (acc>>12) − (prev>>12)` outputs by linear interpolation from the previous sample, `sample·g >> 7`,
  saturating ±32767 mix; only voices `i < numChannels` (flli 38 = 8) are written, the rest advance silently; finished
  voices removed after each 1024-frame block (`FUN_100d1cf0`) — the mixer always works in 1024-frame blocks at 44.1 kHz
  internally whatever the pull size; `allowMultiple == false` and the record's last-started voice alive → no start
  (`FUN_100476e0` semantics incl. the id/data/0 match of `FUN_100d1b30`). `stopAll` = `FUN_100d1be0(0)`.
- **Tests (8):** `testContinuousConversion` (`icbu`: P = 239 packets → sampleCount 15,774 = 66·P; the first packet's
  header word dropped; nibbles swapped per byte; sound-music §2.2 worked example) · `testIMADecodeClamps` ·
  `testVolumeToGain` (100 → 128, 90 → 115, 80 → 102, 75 → 96, 70 → 89, 50 → 64; §2.3) · `testInsertionRanking`
  (worked example: `cabo` (70, 256) then `exsl` (50, 256) then `icre` (50, 256) → [cabo, icre, exsl]; then `icbu`
  (45, 230) ×2 → [cabo, icre, exsl, icbu₂, icbu₁]; §3.1 + worked example) · `testSixteenVoicesEvictOrRefuse` ·
  `testOnlyTopEightAudible` (voice 9 contributes 0 until a higher voice ends, then enters mid-sample; §3.2) ·
  `testPitchIsSpeedInverse` (a 44.1 kHz sound at pitch 2.0 yields 2× the output frames, at 0.5 half; §3.2, Q2
  default) · `testAllowMultipleFalseBlocksRestart` (§2.4).
- **Gate:** G2 = previous + **8** (canonical **203**). **Commit:** `DeimosAudio: continuous IMA conversion + the game's 16-voice/8-audible ranked effects mixer (1024-frame blocks); 8 tests`.

### C13 — minor — Particles, debris, motion blur (→ +8, canonical 211) — after C0
- **Files:** `Sources/DeimosCore/Effects/{ParticleSystem,DebrisList,MotionBlurPool}.swift`;
  `Tests/DeimosCoreTests/EffectsTests.swift`.
- **Contract (particles-debris-blur, HIGH unless marked):** `ParticleSystem` — app-start tables (`FUN_10044630`: 100 ×
  [R(0,416), R(0,480), R(0,3)] from LCG state 1, then the two `R(0,99)` start indices — §1 #1/#2, computed with a
  private `MSLRandom(seed: 1)`, never the game's), `emit(_ req:, rng: inout MSLRandom)` = `FUN_10043340` (§2.2–§2.7:
  type table, one `R(0,4)` per particle **at the call**, colour variants, index advance `idx ≥ 99 → 0`), `update(scrollDelta:)`
  = `FUN_100438c0` (§2.8: delay, ground scroll, drag 0.96 per axis, kill bounds, fade +1 → dies on the 33rd update),
  `stamps(hOffset:) -> [ParticleStamp]` = `FUN_10043ba0` visibility rules (§2.9); `levelReset` (§2.1). `DebrisList`
  (§3: add, ride the scroll, inclusive hit test, reset per level). `MotionBlurPool` (§4: 1000 slots, the cached-index
  quirk, emit copies a `GameObject` with +0x1a/+0x38 forced 0 and visibility Initial/Delta, update removes below 0.0,
  draw = `EntityDraw.entry` per blur in list order).
- **Tests (8):** `testBurstCountsAndDraws` (`tiny` 5, `smal` 10, `med ` 20, `larg` 40 draws; `meci` ring flag; unknown
  ID → no group, no draw; §2.3) · `testColourVariants` (request 0x7FFF: core channels 30, 27, 23, 19, 16 and fringe 18,
  16, 14, 11, 9 for variants 0…4 → variant 0 core 0x7BDE, fringe 0x4A52; §2.7, probe p14 — re-derive from
  `10043518..1004373c`, STOP if different) · `testParticleUpdateDragAndLife` (|v| × 0.96 per update; fade 0 → 32 over
  32 updates, removed on the 33rd; kill at x < −32 or x + 7 > 448 or y < 0 or y + 7 > 480; §2.8) ·
  `testStartIndicesFromSeedOne` (burst index 50, ring index 79 after the 302 app-start draws; §2.5, MED → this test
  pins the reading) · `testStampWeights` (the §2.9 table at fade 0, 6, 7, 32 incl. the centre snapping back at 7) ·
  `testDebrisRidesScrollAndBlocks` (§3, inclusive on all four sides) · `testMotionBlurLifetime` (Initial 50 / Delta 10
  → drawn on 6 updates, then freed; pool refuses the 1001st; §4.3–§4.4) · `testStampsSkipDelayedAndOutside` (§2.9: a
  group with delay > 0 draws nothing; sx ≥ 0, sx + 7 < 416, sy ≥ 0, sy + 7 < 480 with sx = x − hOffset, top-left anchored).
- **Gate:** G2 = previous + **8** (canonical **211**). **Commit:** `DeimosCore: particles (emit draws, drag, fade, stamps), debris obstacles, motion-blur pool; 8 tests`.

### C16 — minor — Notices and the message queue (→ +6, canonical 217)
- **Files:** `Sources/DeimosCore/Game/{NoticeSlot,MessageQueue}.swift`; `Tests/DeimosCoreTests/NoticeMessageTests.swift`.
- **Contract (messages-notices-console §1–§4, HIGH):** `MessageQueue` — record (§2.1), `post(text:type:upper:readout:)`
  (§2.2: cap flli 24 = 20, the new message is dropped, sticky prepend / normal append), `age(frame:)` (§2.3: opaque
  for flli 25 = 60 frames, fade += flli 26 = 1, delete at 32, **one deletion per frame then stop**), `drawCommands`
  (§2.4: formats 35/36/37 by type, newest at Loc_Y, older +20 px each, BlendAmount = fade, strip blend = fade + 16 off
  above 32, +0x10c = 15, +0x10d = 1, +0x110 = 0) via `TextLayout`. Messages count **presented frames** (fc+8).
  `NoticeSlot` (§4.1–§4.3: post/clear, tick once per new game time — delay, sound block played through
  `SoundPlay.record` at the first visible tick, fade-in 2/tick, auto-clear at start + flli 71 = 60, fade-out 4/tick;
  draw format 49 with the slot's alignment; notices count **logic ticks**).
- **Tests (6):** `testMessageLifetime92Frames` (opaque frames 0…60, deleted on frame 92; §2.3) · `testMessageCapDropsNew`
  (21st post ignored; §2.2) · `testOneDeletionPerFrame` · `testMessageLayoutNewestOnTop` (three normal messages:
  newest at Loc_Y 10, then 30, 50; formats by type; §2.4) · `testNoticeFadeHoldFade` (fade-in 32 → 0 in 16 ticks,
  clear requested at start + 61, fade-out 0 → 32 in 8 ticks; §4.3) · `testPressCapsLockNoticeOpaqueAtOnce` (fade-in
  off → alpha 0 at once; alignment `CEGA` for the game loop's fc+4 = 1; §4.4).
- **Gate:** G2 = previous + **6** (canonical **217**). **Commit:** `DeimosCore: notice slot and message queue (aging per frame, notices per tick); 6 tests`.

### A2 — minor — DeimosAudio: music streamer, master gain, the engine (→ +6, canonical 223) — after A1
- **Files:** `Sources/DeimosAudio/{MusicStream,DeimosAudioEngine}.swift`; `Tests/DeimosAudioTests/MusicEngineTests.swift`.
- **Contract (sound-music §4, §6; S5):** `MusicStream` plays a `soun` music tag (`mu03`, `ammu`, `inmu` — AIFC ima4
  stereo; census) decoded with the kit's `IMA4` (Apple's decoder = the Sound Manager's) packet by packet from the pak
  byte range, looping the whole SSND seamlessly (§6.3), resampled linearly to 44.1 kHz if the file rate differs;
  `.play` restarts from 0, `.stop` disposes, `.pause`/`.resume` freeze/continue the position (§6.5); level amp `min(255,
  m·fade >> 8)` with `m` from `MusicCue.level` and fade 0x100 → gain `amp/255` (**Q3 default 255**). Master gain =
  `clamp(trunc(128·v/100), 0, 128)/128` (`FUN_10047b80`) applied to effects **and** music (**Q4 default**: the OS 9
  device volume as an app gain; v 0 = silent but everything still runs, §4.3). `haltEffects` = `stopAll` (music
  untouched, §6.5). `DeimosAudioEngine` routes `apply(...)` in argument order; `render` mixes effects + music under
  one `Mutex`, never allocates. Effects preload: every `soun` tag in the index that passes `DeimosSound`'s effect gate.
- **Tests (6):** `testMusicAmpFullScale255` (int pref 1 = 100 → m 128 → amp 128 → gain 128/255; §6.2) ·
  `testMusicLoopsSeamlessly` (a synthetic 2-packet AIFC: frame after the last = frame 0) · `testMusicPauseFreezes` ·
  `testMasterGainScalesAll` (v 50 → 64/128 on effects and music; v 0 → silence with positions advancing) ·
  `testHaltEffectsKeepsMusic` · `testEngineIsAPullSource` (outputRate 44100; `render` fills 2·frames floats; requires K2
  on HK main — if K2 has not landed, this test waits for it: A2 merges after K2).
- **Gate:** G2 = previous + **6** (canonical **223**). **Commit:** `DeimosAudio: music streamer (seamless loop, pause, ampCmd level), master gain, DeimosAudioEngine pull source; 6 tests`.

### R4 — minor — Render: particle stamps (→ +3, canonical 226) — after C0
- **Files:** `Sources/DeimosRender/{DeimosRenderer,ParticleStamps}.swift`; `Tests/DeimosRenderTests/ParticleStampTests.swift`.
- **Contract (particles-debris-blur §2.9, HIGH):** each stamp writes the 7×7 weight pattern at (trunc sx, trunc sy)
  top-left into the back buffer: `dst' = (dst·w + col·(32 − w)) >> 5` in the spread-555 form `(c & 0x7c1f) | (c &
  0x3e0) << 15` (core for D/E/X, fringe for A/B/C); nothing else; `.pauseWait` → precondition (host's).
- **Tests (3):** `testStampKernelSpread555` (dst 0x7FFF, core 0, w 16 → 0x3DEF per channel; the spread form keeps
  fields apart) · `testStampPatternAtFade0And7` · `testPauseWaitIsHostOnly`.
- **Gate:** G2 = previous + **3** (canonical **226**). **Commit:** `DeimosRender: particle stamps (7×7 spread-555 blend); 3 tests`.

### C7 — ⚑ MAJOR — Trig, the entity world and `GameState` (→ +8, canonical 234) — after C13, C16
- **Precondition:** read `FUN_10042920` (`10042978..10042a60`: argument precision of the sin/cos/atan builds),
  `FUN_10043090` (`100430a0..100431d0`: atan octant fold), `FUN_100385d0`/`FUN_10038810` (micro-wave §3.7),
  `FUN_10032e60` (`10032f88..1003305c`); record as doc comments.
- **Files:** `Sources/DeimosCore/Math/Trig.swift`, `Sources/DeimosCore/Units/{Entity,EntityGroup,EntityWorld,SpawnRequest}.swift`,
  `Sources/DeimosCore/Game/{GameState,GameFlags,FilmCursor,TickTrace}.swift`; `Tests/DeimosCoreTests/{TrigTests,EntityWorldTests}.swift`.
- **Contract:** S2 for `GameState`, `GameFlags`, `Trig`, `Entity`, `EntityGroup`, `EntityWorld`, `SpawnRequest`.
  Trig per units-movement §2.2–§2.3 and loose-ends-combat §1 (compass 0 = up, 90 = right; velocity `(s·sin h, −s·cos
  h)`; `FUN_10043040` involution; `root(n)` = table for n < 0x4000 else `sqrt`); world per spawn-and-waves §1.2–§1.3,
  §8 (`FUN_10032e60` level reset: free groups, PERM first with id 20000000, group ids from 20000000, serials from
  1000, ground count 0, pending list built by C8) and the iteration rule of Hazards (index loops re-reading counts).
  `GameState.init(assets:prefs:seed:)` builds two `Player`s, a fresh world and buffers; no behaviour beyond reset.
  `FilmCursor` and `TickTrace` as S2 (data shape + the two film functions).
- **Tests (8):** `testTrigTablesAsRead` (S[0] = 0, C[0] = 1, S[90] = 1, C[180] = −1 as the read precision gives them;
  `sin(360)` = `sin(0)`) · `testCompassToInternal` (0 → 180, 90 → 90, 180 → 0, 270 → 270, 359 → 181; heading 180
  speed 6 → (0, 6), heading 0 speed 10 → (0, −10); units-movement §2.2, worked Shuriken step 1) · `testHeadingToPoint`
  (target above → 0, right → 90, below → 180, left → 270; §2.2) · `testDistanceTruncatesSquare` (dist((0,0),(3,4)) = 5;
  ((0,0),(0.5,0.9)) = root(1) = 1; spawn-and-waves §6) · `testLevelResetIds` (PERM id 20000000 unit `PERM`; next
  group 20000001; next serial 1000; §1.2) · `testPoolCapAndHint` (1000 live → the next allocation fails; freeing slot k
  makes the next allocation slot k; micro-wave §3.7) · `testPermMembershipRule` (1 member, no owner → PERM (+0xa4 = 1,
  +0xa8 += 1); 2 members → a new group; PERM persists empty, a normal group is freed at live < 1; §1.2) ·
  `testSamePassAppendIsVisited` (an entity appended during an index walk is visited by the same walk; INDEX #38).
- **Gate:** G2 = previous + **8** (canonical **234**). **Commit:** `DeimosCore: trig tables + heading helpers, entity world (pool, ids, PERM, groups), SpawnRequest, GameState/GameFlags; 8 tests`.

### C8 — ⚑ MAJOR — Spawning: request → group → members, state entry, level objects (→ +10, canonical 244)
- **Precondition:** read `FUN_10033220` (`10033240..10033600`), `FUN_100369f0` (`10036a04..`), `FUN_10035cd0`
  (`10035d54..10036100`), `FUN_10037930`, `FUN_10037b50`, `FUN_10037ed0`, `FUN_100146f0` (`100148dc..10014dc0`),
  `FUN_10017cb0`, `FUN_10017510` (flee draws), `FUN_10035900`, `FUN_10033090` and `FUN_1000fa10`; record each draw
  site with its address in the doc comments (the replay audit trail).
- **Files:** `Sources/DeimosCore/Units/{Spawn,StateEntry,LevelObjects}.swift` (all `extension GameState`);
  `Tests/DeimosCoreTests/SpawnTests.swift`.
- **Contract:** spawn-and-waves §3.1 order (size and appears draws **before** the refusals: players-active,
  doNotSpawnIfTypeAlreadyExists, cap `live + n < 1001` with the once-per-level "Reached Entity Limit" message, then
  deleteExisting…, group creation (§1.2), y conversion for req+0x0c (`y − top`), members, entry notice
  `FUN_100380e0`); §3.2 per-member order D1 → placement → initial motion → `FUN_100146f0(state 0)` (timer → frame →
  scale tolerance → velocity set-up (units-movement §4) → owner init `FUN_10033600` → flee point → `FUN_10017cb0`) →
  group delay `R(gdMin, gdMax)` (first member included) → cyclic start (§3.4); shields by sector (damage §3, the cap
  only in the increment branch, single precision); ground-accuracy create count (`FUN_100061e0`); `+0x19` air flag;
  §2.2 state-entry arming (rate → volley → delay; first volley armed on entry; `+0xc4` set unconditionally). State
  entry also: enterCount[state] += 1, soundCount = 0 (sound-music §5, MED → read), burst count +0xf4 = 0, state start
  = now. Level objects: `FUN_10035900` pending list (ground x −32.0, yLoc as map row), `FUN_10033090(row)` (file
  order, unconditional unlink), `FUN_1000fa10` load pass (rows 3600 … top − 64).
- **Tests (10):** `testGroupSizeAndAppearsDraws` (min′ = min(max(min, 1), max); `R(min′, max)` only when ≠; per-member
  `R(0, 100)` only when appears ∉ {0, 100}; draw counts match an independent in-test LCG; §3.1) ·
  `testShurikenRequestFiftyOneDraws` (srand(1), one active player, `shur` at absolute (208, −100): first draw `R(10,
  11)` = 10 → 1 + 5·10 = **51** draws; per member R(0,359), F(5,7), R(50,60), R(0,5), R(9,16) in that order; spawn-and-
  waves worked example step 5) · `testRefusedRequestStillDrawsSize` (no active player → 1 draw, no members; §3.1) ·
  `testPlacementRadialAndRect` (radial: heading draw then optional radius `F(0, |xMax|)`, x = gx + sin·r fused; rect:
  int x then int y; waves-and-enemies §4) · `testInitialMotionBranches` (stationary → (0,0) no draw; heading branch;
  hunter aims at the player nearer (208, 0), ties → P1; burst/implode y negated; mult ≠ 1 scales; §3.3) ·
  `testCyclicStartDraws` (5 draws + the conditional 6th when y > 120; velocity normalised × {1.0, 1.4}; §3.4) ·
  `testStateEntryArmsSpawnSets` (`07s1` S2 set: rate `R(120,125)`, volley 1, delay 0 → remaining 1 on entry; `none`
  set inert; §2.2) · `testShieldsBySector` (`plla` sector 1 → 2.5999999f; `bsgr` 4.0 + 0.4 at sector 3 →
  4.8000002f; a base-only unit ignores sector; damage §3; p13) · `testFirstLevelObjectSpawnRow` (le07: `bsgr` (y 2978)
  is requested at game time **77** as a group at (371, −64): t = 3055 − y, ground x − 32, y − top = −64;
  level-scroll-objects §6.2–§6.4, p16) · `testLoadPassBand` (rows 3056…3600 spawn at load: le07 none (max yLoc 2978);
  all 12 levels together **13** of 565 placements; level-scroll-objects §2 census).
- **Gate:** G2 = previous + **10** (canonical **244**). **Commit:** `DeimosCore: spawn requests, member creation in FUN_10035cd0 draw order, state entry + spawn-set arming, level objects (pending list, spawn row, load pass); 10 tests`.

### C9 — ⚑ MAJOR — Motion and animation (→ +9, canonical 253) — ∥ C10, C14
- **Precondition:** read `FUN_10015280` and its callees (`FUN_10016cc0`, `FUN_10017b70`, `FUN_10017c40`, `FUN_10016fe0`,
  `FUN_10017a10`, `FUN_10016da0`, `FUN_10017ef0`), `FUN_10015930`, `FUN_100172d0`/`FUN_10017150`, `FUN_10016230`,
  `FUN_100161c0`, `FUN_10037130/7230/7350`, `FUN_10036930`; the cull `FUN_10012ca0` mode 1 is listing-read in this plan
  (Bank corrections 1).
- **Files:** `Sources/DeimosCore/Units/{Motion,Animation,OwnerLinks}.swift` (all `extension GameState`);
  `Tests/DeimosCoreTests/MotionTests.swift`.
- **Contract (units-movement §1–§8, spawn-and-waves §4, HIGH):** motion controller → velocity (seek/hunt per-axis
  bang-bang, hold, reverse, cyclic, ramp to desired, constrain, range trigger — a range trigger changes state through
  C8's state entry **inside** the controller call); `integrateAndCull(margin: 128)` (`FUN_10012ca0` mode 1: ground y +=
  scroll delta, x += vx, y += vy, then in-bounds iff `x + hw ≥ −128 && x − hw ≤ 544 && y ≥ −128 && y − hh ≤ 608` —
  out → silent delete, +0xcb = 1, +0xd9 = 0xff); animation step; rotation gate + turn; heading → frame
  (micro-wave §3.2); facing from frame; lock → link → orbit (each gated by its state flag) and the owner copies.
- **Tests (9):** `testIntegrateGroundRidesScroll` (ground y += delta before velocity; air not; §2.1) ·
  `testCullBoundsMode1` (hw = hh = 10: x −138 in, −138.5 out; x 554 in, 554.5 out; y −128 in, −128.5 out — **no
  half-height on the top test**; y 618 in, 618.5 out; listing `10012d48..10012e38`, p18) · `testShurikenHoldsSixDown`
  (state 0: s 6, M 7, D 0 → vy stays 6; worked Shuriken 1) · `testRangeTriggerOnUpdate50` (from (208, −100) at 6 px/tick
  toward a player at (208, 330): update 49 distance 142, update 50 distance 136 < 140 → "RULE - Wait Anim Done";
  worked Shuriken 2) · `testHuntTieGoesNegative` (x == tx → ax = −D; v (−0.25, 6) then vx 0; worked Shuriken 3) ·
  `testAnimationStopsOnLastFrame` (1 direction, FPD 6, delay 0, delta 1, no loop: frames 0…5, stopped on the step
  that finds 5; worked Shuriken 4) · `testHeadingToFrame` (n 8: h 22 → 0, h 23 → 1, h 350 → 0 (k 8 > 7); n 7 →
  step 51; micro-wave §3.2) · `testLockLinkOrbit` (lock: pos = owner + offset; link: pos −= ownerLast − ownerNow;
  orbit: angle += trunc(vx) deg/tick, radius = trunc(dist); spawn-and-waves §4) · `testFleeTargets` (`soce` → (208,
  2000); the random-axis codes draw `F(0, 416)` or `F(0, 480)`; units-movement §6, engine-loop §9).
- **Gate:** G2 = previous + **9** (canonical **253**). **Commit:** `DeimosCore: motion controller, integrate + 128-px cull, animation/turning, owner lock/link/orbit; 9 tests`.

### C10 — ⚑ MAJOR — State machine: timer, the 17 rules, spawn-set executor, power-up release (→ +9, canonical 262) — ∥ C9, C14
- **Precondition:** read `FUN_10015550` (incl. `10015754..100158d4`), `FUN_10034ee0`, `FUN_10035070`, `FUN_100351f0`,
  `FUN_100352f0`, `FUN_100353e0` (micro-wave §3.1), `FUN_10015b40` (`10015c08..10016188`), `FUN_10014670`,
  `FUN_10034ce0`, and the timer step in `FUN_10033850` (`10033c58..10033d70`, the "re-read state" `goto`).
- **Files:** `Sources/DeimosCore/Units/{StateTimer,Rules,SpawnSets,PowerupRelease}.swift`; `Tests/DeimosCoreTests/StateMachineTests.swift`.
- **Contract:** timer step (waves-and-enemies §3 step 4: `gameTime == start + timer`; `Delete` silent, `Destroy` →
  C11's destroy, `none`/empty → no change, else enter by name with now); rules (§3 table, the 17 strings, unit `none`
  inert, first true rule wins; callee semantics spawn-and-waves §6 + micro-wave §3.1: #0 needs spawned-in + +0xc1,
  range inclusive; #2 without +0xc1; #4 counts pending members; #5 needs on-screen; #6 = !#4 && !#5; #8 strict and
  range ≠ 0; #14 ==, #15 <, #16 > signed); the pause flag (bosses §2.2: read after a timer switch, before rules);
  spawn-set executor (spawn-and-waves §2.3–§2.5: skip rules, Don'tSpawnOffscreen, countdown/issue, re-arm draw order
  delay → volley → rate, positions incl. absolute and rotated (fused), request fields); power-up release
  (`FUN_10034ce0(now, serial)` → `FUN_10014670`: first state flagged +0x355, entered by name, start = now; micro-wave §3.3).
- **Tests (9):** `testTimerTargets` (Delete: +0xcb, killer 0xff, not destroyed; Destroy → destroyed; "none" → stays;
  name → state switch at now) · `testTimerFiresAtStartPlusDraw` · `testRuleTable` (17 strings → 0…16; unknown →
  disabled; first true wins) · `testCountRulesSigned` (count 2 vs range 2: #14 true, #15/#16 false; count 1: #15 true;
  micro-wave §3.1) · `testNoDestroyableGroundNeedsOnScreen` (a counted ground entity at x 420 does not block #5, at x
  400 it does; bosses worked example step 4) · `testTrackingVersusActive` (#0 false without +0xc1, #2 true; ranges
  inclusive; #8 strict) · `testPauseFlagFromNewState` (a timer switch into a pausing state pauses the same tick; a rule
  that deletes still leaves that tick paused; bosses §2.2) · `testShurikenControllerThreeGroups` (`07s1` with an active
  player: S2 issues exactly **3** `shur` requests at T0, T0 + r1 + 1, T0 + r1 + r2 + 1 with r ∈ [120, 125]; no
  request on a re-arm tick; spawn-and-waves worked example step 3) · `testPowerupReleaseState` (`icpo` with its serial →
  "_Powerup Release, Dwindle & Del" at now; weapons worked example 4a).
- **Gate:** G2 = previous + **9** (canonical **262**). **Commit:** `DeimosCore: state timer, the 17 rule conditions, spawn-set executor, power-up release state; 9 tests`.

### C14 — ⚑ MAJOR — The player, complete (→ +10, canonical 272) — ∥ C9, C10
- **Precondition:** read `FUN_10028170` (`10028f30..100298a8`), `FUN_1002a150`, `FUN_1002a3a0`, `FUN_10029cc0`,
  `FUN_100269a0`, `FUN_10026410`, `FUN_10027100`, `FUN_10027e50` (order listing-read in this plan — Bank corrections 2),
  `FUN_10029a10`, `FUN_10026cc0`, `FUN_10026d70`, `FUN_10029b20`, `FUN_10029fe0`, `FUN_10026ee0`, `FUN_10027490`,
  `FUN_10027de0`; and how `FUN_10006b50` sets the "P1 active" gate flag passed as `FUN_10028170`'s 2nd argument (player
  NR 6, MED) — record or STOP.
- **Files:** `Sources/DeimosCore/Player/{Player,PlayerUpdate,PlayerLife,PlayerScoring}.swift` (`Player.swift` grows
  fields; the rest `extension GameState`); `Tests/DeimosCoreTests/PlayerTests.swift`. (`PlayerPhase1.swift` untouched —
  C18 deletes it.)
- **Contract (player-physics §1–§8, scoring-bonuses §3–§5, damage §5):** `updatePlayer(_ i:, input:)` in the
  `FUN_10028170` order (§2: defence bonus → life state → input (`FUN_1002a3a0`, state 4 only, read **after** the
  life-state step of the same tick: the film's next byte via `GameState.film` when a film plays, else the keys'
  `PlayerInput` passed in) → second fade → overload warnings → ramps → +0xc5 → size/blink → state 4:
  weapon handler call site (C15 fills; until then a no-op hook), velocity, banking, integrate, view shift, clamps, handler
  position, crosshair); hits `FUN_10027100`; death `FUN_10027e50` (Bank corrections 2 order: owned entities via the
  world → death spawn → displayed shield/power 0.0 → coins 50/10/5/1 → money 0 → state 3 → invulnerable → multiplier
  reset); respawn `FUN_10029cc0` (`plen` entry spawn, multiplier indicator, weapon reset hook); level start
  `FUN_100269a0` (incl. its `R(400, 2000)` for every in-game player); setup `FUN_10026410` (lives 3 at sector 1 else 1);
  `addScore` `FUN_10029a10` (multiplier, strict-> threshold, raw branch); lives, multiplier, money; shield storage
  biased by +1324366.0.
- **Tests (10):** `testHoldUpTenTicks` (vy −1.6, −3.2, −4.8, −6.4, −7.8 …; y 328.4, 325.2, 320.4, 314.0, 306.2, 298.4,
  290.6, 282.8, 275.00006, 267.20007; released: rest at 252.0 on tick 15; player worked example) · `testClampToArea`
  (x − hw < −32 → x = hw − 32, vx 0; y − hh < 13 → y = 13 + hh; bottom pins; §2.3) · `testCrosshairAdjust` (down +
  pinned: +3 to 80; else −4 to 0; cy floored at half-height; §2.6) · `testSevenFullHitsDestroy` (100 → 85 → … → 10 → −5:
  dies on the 7th; a hit landing on exactly 0 survives; `now ≥ last + 1`; §3) · `testShieldEighthPercent` (set 33.3 →
  reads 33.25; damage §5.1; p13) · `testDeathOrder` (money 67 → coin requests `calg` `cals` `casg` `cass` `cass` after
  the `death_Spawn_ID` request; displayed shield/power 0.0; state 3 at now; invulnerable; multiplier 2 → indicator
  deleted, 1; Bank corrections 2) · `testDyingAndRespawn` (80 ticks, 40 when lives == 1; lives decremented at the end;
  respawn at (208, 330), shield 100, state 4, invulnerable cleared at enter + 61; §4) · `testExtraLifeThresholds`
  (lives at > 10000, > 40000, > 80000, > 130000; one life per call; raw add sets step = score + 10000; scoring §3) ·
  `testMultiplierSteps` (1 → 2 → 3 → 4 → 5 → 10 → 10; `mux2…muxx` indicator at the ship; reset on death; §4) ·
  `testDefenceBonusOnce` (level ending + not hit → `nodb` + 2000 × sector × multiplier once; a hit forfeits; §6.1).
- **Gate:** G2 = previous + **10** (canonical **272**). **Commit:** `DeimosCore: player update in FUN_10028170 order, hits, death, respawn, level start, setup, score/lives/multiplier/money; 10 tests`.

### C11 — ⚑ MAJOR — Combat: collisions, damage, destruction, removal, pickups (→ +10, canonical 282) — ∥ C15, C17, C19
- **Precondition:** read `FUN_10042f80`, the player-collision blocks of `FUN_10033850` (`10033894–100339c4`,
  `10034088–1003430c`), the obstacle block (`100344ec–1003456c`), `FUN_10036cf0` (`10036d64–100370f0`), `FUN_10014f10`
  (`10014f10–1001527c`), `FUN_10016300` (`10016300–10016528` + the bonus ladder), `FUN_10016880`, `FUN_10017e70`,
  `FUN_10036610`, `FUN_10036120`, `FUN_100363c0`, `FUN_100364f0`, `FUN_10034b90`, `FUN_10034de0`, `FUN_10036be0`,
  `FUN_10037580`.
- **Files:** `Sources/DeimosCore/Combat/{Collision,Damage,Destruction,Removal,Pickups,MediaMask}.swift`;
  `Tests/DeimosCoreTests/CombatTests.swift`.
- **Contract (damage-health-death §1–§6, loose-ends-combat §3–§4, scoring §7, HIGH):** circle test strict, radius =
  half bbox height (signed int division); player ↔ entity (§2.3 gates, ram 100 credited to the player index, then the
  player takes `damage_FLOAT`, pickups via `FUN_10037580` + `+0xca`); entity ↔ ground obstacle (§2.4); entity ↔ entity
  (§2.5 candidate rules, mutual damage, the B-side `passHitsToOwner` copy-paste bug kept, stop when A deleted); hittable
  flag (§2.6); damage (§3 steps 1–13, hit delay per victim, on-hit state change, glow, hit particles, shield sounds,
  collision spawns); destroy (§4.1 order incl. the random-bonus ladder of scoring §7 with the reward-armed rule);
  media gate (§4.2: map point (trunc x + 32, trunc y + top) looked up in the level's mask (`jut2`, 96×720 for the
  480×3600 map: index x / 5, y / 5, water iff the element is exactly 0x001f — sprite-sound-containers §3.1 HIGH;
  mask row 0 = map top, MED as for the map), `smra`/`mera`/`lara` draws); shield-depletion
  state (`FUN_10017e70`); sweep and `FUN_10036120` (accuracy decrement, terrain stamp, owner destruction, deletion
  spawn, children, group kills, coins, PERM rule); direct removers.
- **Tests (10):** `testCircleStrict` (dist == rA + rB → no hit) · `testPlayerRamDealsHundred` (entity −100 credited to
  player 0; player −15·damage; a ram kill scores `score_INT`; §2.3) · `testHitDelayPerVictim` (hits at t and t+1 → one
  accepted; t+2 → second; §3 step 2) · `testBuzzsawDiesToOneIonHit` (`bu01` 0.4 − `icb ` 0.4 = 0.0 ≤ 0 → destroyed, 50
  to the killer; bosses table) · `testPlatformSevenBombHits` (`plla` 2.5999999 → 2.2, 1.8, 1.4, 1.0, 0.6, 0.2, −0.2:
  destroyed on the 7th 0.4 hit (2 ticks apart), 0 points, 2 × `cass` coins; bosses table) ·
  `testShotResolvesPairOnce` (the shot's update finds the enemy; the enemy's update does not find the shot; layers must
  match; the B-side passHits redirect targets A's owner — none for player shots; §2.5) · `testDestroyOrder` (glow off →
  obstacle (ground only) → destruct particles (draws) → destruct spawn (media gate) → notice → sound → flags → accuracy
  count → `R(0, 100)` bonus roll last; §4.1) · `testRandomBonusLadder` (r 69 → `rb01`, 70 → `rb02`, 97 → `rb08`, 98 at
  sector 1 → `rb08`, 98 at sector 3 → `rb09`; reward armed and r < 10 → `rb06` once; scoring §7) ·
  `testGroupKillCoin` (a `bu01` group whose last member is killed by a player → one `cass`; a timer death of the last
  member → none; PERM members never; §4.3) · `testPickups` (`coin` value → money + glow; `exli` +1 life capped 10 with
  `noel`; `mult` step; `shie` + value clamped 0…100; refused while invulnerable only for `air `/`grnd`; §6).
- **Gate:** G2 = previous + **10** (canonical **282**). **Commit:** `DeimosCore: collisions (player/obstacle/entity), damage + hit delay, destruction + random bonus, removal sweep + coins, pickups, media gate; 10 tests`.

### C15 — ⚑ MAJOR — Weapon handler, launchers, crosshair, score-bar weapon state (→ +9, canonical 291) — ∥ C11, C17, C19
- **Precondition:** read `FUN_1003b3c0` (`1003b404..1003b9ec`), `FUN_1003bf80`, `FUN_1003bff0`, `FUN_1003c0d0`,
  `FUN_1003beb0`, `FUN_1003b180`, `FUN_1003af90`, `FUN_1003ade0`, `FUN_1003c4f0`, `FUN_1003c7a0`, `FUN_1003bab0`,
  `FUN_1003bb40`, `FUN_1002adb0`, `FUN_1003cd30`/`cdb0`/`cca0`.
- **Files:** `Sources/DeimosCore/Weapons/{WeaponHandler,Launchers,PowerUp}.swift` (the struct moves out of
  `Player/Player.swift` — C15 edits `Player.swift` only to delete it), `Sources/DeimosCore/Player/PlayerUpdate.swift`
  (the handler call site only), `Sources/DeimosCore/ScoreBar/ScoreBarState.swift` (power target = handler percent,
  icon rebuild); `Tests/DeimosCoreTests/WeaponTests.swift`.
- **Contract (weapons-projectiles §2–§4, loose-ends-combat §6, HIGH):** per-tick order §2.3 (held counters → release →
  air power-up → ground power-up (dead with data) → select on its rising edge (suppresses that tick's air shot, `wesw`
  prio 75) → bombs → store buttons + crosshair → launch ground, air, aux → unlock crosshair); return codes 1/2 to the
  player (overload start / cancel); fire rate + edge; switching + pending; availability by sector; power-up machine
  §2.5; bombs §2.7 (salvo min(sector, 8), `delayBetweenLoadLaunches + 1` spacing); launchers §3.2 (ground speed ratio
  `max(0, trunc(h.y − cy)) / |crosshairYOffset|`, crosshair spawn on activation); icons (current/pending, next, after;
  repeats → none); crosshair fade (flli 149/150) and locked frame hook (`FUN_1003bab0`, set by C12).
- **Tests (9):** `testIonShotSpawns` (sector 1, ship (208, 330): `icb ` (203, 330), `icbf` (208, 322), `icb ` (212,
  330), owner 0; worked example 2) · `testAirEdgeAndCooldown` (fresh press needed; spacing 5 ticks; a press inside the
  cooldown is lost; §2.4) · `testPowerUpActivationAndLevels` (held from t: `icpo` at t + 14; level k at T0 + 3k; 100 %
  at T0 + 60; level 21 clamps to 20 and keeps charging; worked example 3) · `testOverloadTimeline` (return 1 at T0 + 181;
  warnings with `wewa` at S+9, +17, +24, +30, +36, +42, +48; death at S+54; worked 4b, player §6.2) ·
  `testReleaseStream` (release at r with level 20: 20 `icps` at r, r+2 … r+38; idle at r+40; return 2 cancels the
  warning; worked 4a) · `testSelectCycleBySector` (sector 1: select finds nothing, no switch, no sound; sector 2: Ion →
  Bacta then the select tick fires no air shot; §2.4 table) · `testBombSalvo` (sector 1 → 1 bomb; sector 5 → 5 at t,
  t+2, t+4, t+6, t+8; next salvo needs a press after the last + 4; §2.7, worked) · `testBombSpeedRatio` (adj 0 → 1.0;
  adj 40 → 81/121 = 0.669 → 4.02 px/tick; §3.2) · `testScoreBarPowerAndIcons` (power meter follows the handler percent;
  sector 1 icons `wesy` 0, none, none; sector 2 Ion current → Ion, Bacta, none; hud §6).
- **Gate:** G2 = previous + **9** (canonical **291**). **Commit:** `DeimosCore: weapon handler (fire, select, power-up/overload, bombs), launchers, crosshair, score-bar power + icons; 9 tests`.

### C17 — ⚑ MAJOR — End of level: tallies, level complete, game over (→ +8, canonical 299) — ∥ C11, C15, C19
- **Precondition:** read `FUN_100072c0`, `FUN_100075e0` **states 1–5, 7, 9** (MED in scoring §6.4 — record each wait
  and its flli), `FUN_10027670`, `FUN_10027930`, `FUN_10027db0`, `FUN_10007d60`, `FUN_10007170` (`10007194..10007268`)
  and the level-end / game-over branches of `FUN_10006b50` (`10006c4c..10006ff4`).
- **Files:** `Sources/DeimosCore/Game/{Tallies,LevelEnd}.swift` (`extension GameState`); `Tests/DeimosCoreTests/LevelEndTests.swift`.
- **Contract (scoring-bonuses §6, level-scroll-objects §8 "Level end", engine-loop §3):** first level-end tick: `nole`
  (or `noal`) at (208, 240) if someone is alive, every in-game player invulnerable (`FUN_10027de0(p, 1, 0)`), tier
  (§6.3); later ticks: accuracy tally (§6.4, every wait strict → N+1 frames, payments every 3rd frame to both players,
  overshoot kept), then per player coin setup + tally (§6.5, `p1mc` at (105, 248), y + 70 for a stacked second
  counter), then `levelComplete`; the tally text draw (`FUN_10007d60`, format 53) and the coin-tally text draw
  (player draw, Bank corrections 3 — C12 builds it); game over (no player in game → `nogo`, session stops after flli 13
  = 110 ticks); level complete → film: session ends; ◇ S9.1 otherwise.
- **Tests (8):** `testAccuracyTiers` (100 % → 5000; ≥ 95 2000; ≥ 90 1000; 94.99 → 1000; ≥ 85 500; ≥ 80 250; < 80 0;
  created 0 → 0 %; §6.3) · `testTallyOvershoot` (tier 250 at sector 1 → pays 300 in steps of 100; §6.4) ·
  `testAccuracyTallyTimeline` (the state waits as read; total ticks from the first level-end tick to tally done
  pinned to the reading) · `testCoinBonusSteps` (money 30 → 30 payments of 100 = 3000; money 60 → 50 payments of 120 =
  6000; × multiplier; every 3rd frame; §6.5) · `testMissionBonusNeedsAllLevels` (one 100 % level → `perfectLevels` 1 ≠
  12 → no 1,000,000; §6.4) · `testLevelEndSequenceOrder` (`nole` request, invulnerability, tier, then tally, coins,
  `levelComplete`; listing order Research p15) · `testGameOverStopsAfter110` · `testLevelCompleteEndsFilmSession`.
- **Gate:** G2 = previous + **8** (canonical **299**). **Commit:** `DeimosCore: end of level (Sector Secured, accuracy tier + tally, coin bonus), game over, level complete; 8 tests`.

### C19 — ⚑ MAJOR — Begin-frame keys and the console (→ +9, canonical 308) — ∥ C11, C15, C17
- **Precondition:** read `FUN_10030360` (`100303a0..10030564`), `FUN_10030910`, `FUN_10030640`, `FUN_10030870`,
  `FUN_1002d1a0`, `FUN_1002d230`, `FUN_1002d410`, `FUN_1002d770`, the ten registered handlers (messages §5.2) and the
  `FUN_100051a0` registration block (`1000527c..100054f4`).
- **Files:** `Sources/DeimosCore/Game/{FrameKeys,Console,Cheats}.swift`, `Sources/DeimosCore/Game/FrameController.swift`
  (FPS monitor fields); `Tests/DeimosCoreTests/{FrameKeysTests,ConsoleTests}.swift`.
- **Contract (timing-frame §2.1, §2.6; messages-notices-console §2.5, §5; sound-music §4.3; front-end §8):** Caps Lock
  (pressed, not paused, not a film → paused + "Press Caps Lock" notice; the end-frame wrapper then yields
  `.pauseWait(.gameScreen)`, emits `haltEffects`, `incl` (gaso 8, prio 50), `MusicCue.pause`; on resume
  `MusicCue.resume`, notice clear, paused 0); `-`/`=` edge-triggered ±10 clamped 0…100 → `masterVolume`, `incl`
  (gaso 7, prio 100, vol 100) and the message (pgsl 21/22/23) — **Q4 default: the OS 9 path** (the OS X gate
  `FUN_100461b0` is taken as false); F6 toggles byte pref 5 with pgsl 17/18 + gaso 7; FPS monitor (`ticks` from S3's
  `pass(keys:ticks:)`) and the pref-9 counter text (formats 39/40); console: open on `~` (flush typed queue, gaso 1),
  one typed char per frame, 30-char cap and 120-frame expiry → Return, up-arrow recall, backspace, `~` sets the redraw
  flag, execute (uppercased name, exact match over the registered ten, `Unknown Command` type 1, result sounds
  gaso 4/5), input withheld while open, draw (formats 33/34, fade-out 4/frame); cheats (gate order, counters, limits,
  texts, gaso 22/5, effects through C14's player API, `+0xbd` cheated).
- **Tests (9):** `testCapsLockPauses` (pass emits the notice, then `.pauseWait(.gameScreen)`, haltEffects, gaso 8,
  music pause; no pause in a film; front-end §8) · `testVolumeKeys` (50 `-` → 40 "Sound Volume     40%"; 0 → "Sound
  Volume     OFF"; 100 `=` stays 100; gaso 7 prio 100; masterVolume set; edge only) · `testF6Interlace` ("Interlacing
  ON" from 0, pref 5 toggled) · `testFPSCounterText` (pref 9: 31 frames in a > 60-tick window → "31" in format 39; 29 →
  format 40; timing-frame §2.6) · `testConsoleTyping` (open discards earlier typed chars; 30-char cap forces execute;
  120 frames idle executes; backspace; `~` not appended) · `testRegisteredCommandsOnly` (FPS, VERSION, VERS,
  SUPERMUNKI, LIFE, ACCURACY, FUNDS, SCORE, SHIELDS, MULT accepted; SHADOWS → "Unknown Command" type 1) ·
  `testCheatWordAndGate` (`supermunki` → byte pref 11 = 1, "Cheat Codes Allowed"; cheats silent while pref 11 = 0; in
  a film "Not During a Film, Buddy!") · `testCheatLimits` (life 1, funds 3 (+20 money), score 2 (× multiplier), shields
  1, mult 1, accuracy unlimited; refusals "Tut tut!  What a greedy piggy!" etc.; gaso 22/5; messages §5.4) ·
  `testVersionText` ("Version: 1.0.6, Jan  2 2004, 11:55:08").
- **Gate:** G2 = previous + **9** (canonical **308**). **Commit:** `DeimosCore: begin-frame keys (Caps Lock pause, volume, F6, FPS monitor) and the console with the 1.0.6 commands + cheats; 9 tests`.

### C12 — ⚑ MAJOR — The entity update (`FUN_10033850`) and the entity draw (→ +7, canonical 315)
- **Precondition:** read `FUN_10033850` end to end (`10033850..100345d8`) and record the step order with addresses as
  the doc comment (waves-and-enemies §3, units-movement §1, damage §2.3–§2.5, particles §2.6, sound-music §5,
  bosses §2.2); read where it calls `FUN_1003bab0(h, 1)` (crosshair lock, weapons §2.8 MED) and the ground-accuracy test
  `FUN_1003bab0`'s caller condition — record or STOP; read `FUN_100345f0` (`10034a98–10034b5c`) and `FUN_100298c0`
  (`100298c0..100299b8`, Bank corrections 3).
- **Files:** `Sources/DeimosCore/Units/EntityUpdate.swift` (`extension GameState`), `Sources/DeimosCore/Draw/EntityDraw.swift`;
  `Tests/DeimosCoreTests/{EntityUpdateTests,EntityDrawTests}.swift` (EntityDrawTests: existing tests kept, new ones added).
- **Contract:** `updateEntities() -> Bool` (pause) = `FUN_10033850`: the per-tick player-collision cache, then per
  entity in group order: spawn-in countdown (state start re-stamped while counting) → state particles → state sound →
  timer → rules → pause flag → visibility/tint/scale targets + ramps + size + blink → motion → integrate/cull → lock/
  link/orbit → spawn sets → player collision → motion blur (the `R(Min, Max)` draw before the interval test) → crosshair
  lock test → obstacle → entity ↔ entity; then the sweep. `groupCommands(hOffset:)` = `FUN_100345f0` (per group: shadow
  pass for `castsShadows` members, then sprite pass of every spawned member; no debug labels). `playerCommands` (S2) =
  `FUN_100298c0` incl. the coin-tally text. `playerOps` stays as a wrapper (C18 removes it).
- **Tests (7):** `testUpdateStepOrder` (a synthetic entity with every feature records the step sequence above) ·
  `testMidControllerPausesScroll` (le07 data, only `01m1` placed: created at game time **1660** at (134, −64); pause
  state at **1840**; scroll top frozen at **1279** for game times 1841…2640 (**800** ticks); top **1278** at 2641; level
  end at game time **3918**; bosses §2.1–§2.3, p16) · `testBridgeControllerPausesAtTop346` (only `01b1`: created
  **2543**, S2 at 2583 spawns `tapu` at absolute (480, 140) heading 285, S1 at **2773**, frozen from 2774 at top
  **346**; bosses worked example) · `testCrosshairLock` (as read) · `testGroupShadowThenSpritePass` · `testPlayerCommandsAndCoinTallyText`
  (state 4: crosshair, shadow, sprite; tally state ≠ 0 and alpha < 32 → format 30 `plmc` text, layer 15, Loc_Y + the
  stacked offset; `10029930..100299a0`) · `testBlurEmittedEveryTickWithZeroInterval` (Min = Max = 0 → no draw, a blur
  every tick, drawn after groups; particles §4.3–§4.4).
- **Gate:** G2 = previous + **7** (canonical **315**). **Commit:** `DeimosCore: entity update in FUN_10033850 order + sweep, entity group draw, player commands with the coin-tally text; 7 tests`.

### C18 — ⚑ MAJOR — `DeimosSession` Phase 2: the whole loop, film playback, trace (→ +8, canonical 323)
- **Precondition:** read `FUN_100051a0` (`10005738..10005ae4`: set-up, film branch `FUN_100069b0`, loop body, film
  overlay `10005a1c..10005aa0` incl. the REPLAY format and position, end-of-session stop/halt), `FUN_100064d0` in full
  (`100064d0..10006984`), `FUN_10006b50` (order listing-read, Research p15), `FUN_10007070` (Phase-1 bank correction
  2), `FUN_10030bc0` (`10030bec..10030dc4`), `FUN_1002a3a0`, `FUN_100097a0`, `FUN_10009750`.
- **Files:** `Sources/DeimosCore/Game/DeimosSession.swift`, delete
  `Sources/DeimosCore/Player/PlayerPhase1.swift`, `Sources/DeimosCore/Draw/EntityDraw.swift` (remove `playerOps` only);
  `Tests/DeimosCoreTests/{DeimosSessionTests,PlayerPhase1Tests,EntityDrawTests,FilmPlaybackTests}.swift`,
  `Tests/DeimosRenderTests/LevelOneFrameTests.swift`.
- **Contract:** the session holds a `GameState` plus the frame controller, console and key state. `init` =
  `FUN_100051a0` set-up (seed = `start.film?.seed ?? seed`; sector from the film's level via `LevelOrder.sector(of:)`;
  players from the film) then `FUN_100064d0` (game time 0, counters, sector/level, music `[.play(ammu), .stop]` when
  not a film (S9.4), players' level start (draws), message/debris/particle/blur/notice resets, scroll level start,
  `FUN_10032e60` + pending list, load pass, `Notice_Level_NN` (`no01`, 0 draws) at (208, 240) with req+0x0c = 0,
  black fill, score bar, first terrain blit). `pass(keys:ticks:)`: begin frame (C19) → tick: appear check (level music
  `.play(level music, loop: true)` then the fade — not in a film) → update world in the `FUN_10006b50` listing order
  (p15) → level complete (`FUN_10007170`) → game time + 1 → draw world (groups → blurs → players → tally text → notice →
  score bar) → film banner → end frame (messages → FPS counter → console → flush 0–1 → terrain → flush 2–5 →
  `.particles` → flush 6–15 → limit → present) → pause wait (C19). Film: P1/P2 input from the film while state 4
  (cursor++; the byte at cursor == frames is read, zero), session ends when cursor > frames (checked after every draw)
  or any key is held. Session end (not film): `haltEffects`, `MusicCue.stop`. `trace` rows when enabled.
  **Phase-1 tests re-pointed (counts unchanged):** `PlayerPhase1Tests` (8) call `updatePlayer` with no entities (same
  numbers); `DeimosSessionTests` (7): `testInitOps` and `testSteadyPassOrder` gain the new ops, `testDeterministicReplay`
  now asserts a different seed **changes** the outputs by the first spawn; `LevelOneFrameTests` (7): oracles mask every
  drawn command's rect, goldens **re-derived** (self-derived, recorded with the HectorKit + Classics SHAs, re-derived by
  the second review leg); `EntityDrawTests` uses `playerCommands`. `HeadlessRun` (test helper) gains `init(film:)`
  (carry: film/start params) — seed, sector and players from the film.
- **Tests (8):** `testLevelStartDrawsAndOrder` (de01 seed: after `init` the RNG has made exactly 1 draw (P1 `R(400,
  2000)` = 1446, p08); `no01` group at (208, 240); music `[play(ammu), stop]`; level-scroll §8) · `testUpdateWorldOrder`
  (the p15 call order, observed through a per-pass step log) · `testAppearStartsLevelMusic` (game time 2: `.play(mu03,
  loop: true)` before `.fade`; a film emits no music; sound-music §6.4, micro-wave §6) · `testFilmInputsAndEnd`
  (inputs come from the film only in state 4; the replay runs frames + 1 input ticks and ends; timing-frame §7) ·
  `testReplayBanner` ("REPLAY" drawn every pass of a film session, as read) · `testDrawAndEndFrameOrder` (the op-kind
  order above incl. `.particles` between the two flushes) · `testTraceRows` (one row per ticked pass: game time,
  cursor, P1 state/score/lives/shield/money/multiplier, draws, entities, groups, scroll top, paused, levelEnding) ·
  `testSessionEndHaltsAudio` (Esc: `haltEffects` + `MusicCue.stop`).
- **Gate:** G2 = previous + **8** (canonical **323**), G3, G5. **Commit:** `DeimosCore: DeimosSession Phase 2 — full level start, update/draw/end frame in the original order, film playback, tick trace; Phase-1 tests re-pointed; 8 tests`.

### H2 — ⚑ MAJOR — DeimosHost: driver Phase 2 + headless runner + replay trace (→ +8, canonical 331)
- **Files:** `Package.swift` (S1 H2 line), `Sources/DeimosHost/{DeimosDriver,HeadlessRunner,FilmReplay,ReplayTrace}.swift`;
  `Tests/DeimosHostTests/{DriverTests,ReplayHarnessTests}.swift` (DriverTests: existing kept).
- **Contract:** S6. Driver: `pass(keys:ticks:)` with the current ticks; a pass's cues go to `audio` in order when the
  pass begins (sounds, music, haltEffects, masterVolume — the original issues them inside the tick; ≤ one frame early,
  disclosed nowhere because inaudible); **`.pauseWait(p)`** yields until an `idle` sees `capsLock == false`, then
  `present(p)`; typed characters: `idle(seconds:keys:)` accumulates `keys.typed` across calls and hands the queue to
  the next pass; **Esc latch** clears when **any** `idle` sees Esc up (carry, final-review note); ◇ restarts keep the
  ended session's prefs (S9.6); level complete / game over end the session like Esc (S9.1–2). `HeadlessRunner` (logic
  only unless asked to render; bounded by `maxPasses`), `FilmReplay` (seed/sector/players from the film, keys empty,
  stops at session end or the bound; `scoreAtFrames` = P1 score after the pass whose cursor reached frames),
  `ReplayTrace` (CSV, one row per `TickTrace`, header fixed).
- **Tests (8):** `testPauseWaitHoldsUntilCapsUp` · `testCuesRoutedAtPassBegin` (a recording sink sees the pass's cues
  in order, once) · `testTypedQueueAcrossIdleCalls` · `testEscLatchClearsOnSubPassRelease` (Esc down at pass k, up and
  down again within one pass: the second press restarts once; fails on the Phase-1 driver) ·
  `testPrefsSurviveRestart` (F6 then Esc → the new session has pref 5 set) · `testHeadlessRunnerFromFilm` (de01 →
  sector 1, seed 0x469c2, 1 player) · `testFilmReplayEndsOnePastLastByte` (a synthetic 10-frame film ends after 11
  input ticks with reason `.filmEnd`) · `testReplayTraceCSVHeader`.
- **Gate:** G2 = previous + **8** (canonical **331**). **Commit:** `DeimosHost: driver Phase 2 (pause wait, audio cue routing, typed keys, Esc latch on any idle, prefs carry), HeadlessRunner, FilmReplay, ReplayTrace; 8 tests`.

### H3 — minor — `deimos-replay` and the de01 gate (→ +3, canonical 334)
- **Files:** `Package.swift` (S1 H3 line), `Sources/deimos-replay/main.swift`, `Tests/DeimosReplayTests/ReplayGateTests.swift`.
- **Contract:** `deimos-replay <film tag>… [--trace file.csv] [--frames dir --every N] [--all]` — loads the committed
  data (`DEIMOS_DATA` overrides), replays each film with `FilmReplay` (rendering only with `--frames`, PPM like R3's
  dump), prints per film the G4 line plus the partial-progress numbers of G4.2; `--all` = de01–de04 (de02–de04 print
  `INFO`, never `PASS`/`FAIL`). Exit 0 iff de01 passes.
- **Tests (3):** `testDemo01ReachesScore25050AtTick4809` (**G4**: score 25,050 at cursor 4,809, end within one tick;
  `maxPasses` 20,000; engine-loop §7, Film census) · `testReplayIsDeterministic` (two runs → identical trace hash) ·
  `testCLISummaryLine` (format of the G4 line).
- **Gate:** G2 = **334/0** and G4 PASS. Under G4.3 only, the orchestrator re-specifies `testDemo01…` in D31 (it then
  pins the ruled divergence tick and the replica's own score, self-derived and re-derived by the second leg) — never
  skipped, never silently edited. **Commit:** `deimos-replay: film replay + per-tick score trace; the de01 gate (25,050 at 4,809); 3 tests`.

### A3 — ⚑ MAJOR — App: audio, typed keys, Caps Lock, film argument (no tests) — needs K2 on HK main, A2, H2
- **Files:** `project.yml` (S7), `Deimos/App/{DeimosController,DeimosMain}.swift`.
- **Contract:** `DeimosAudioEngine` created at launch (failure → silent, like `FUN_10047160`'s non-fatal path) and
  attached with `ShellMixer.attachStream`; the driver gets it as `audio`; the stream is paused while the app is
  suspended (D29 as built) and resumed after. Key-down characters (no repeats) go into `HeldKeys.typed`; Caps Lock state
  into `capsLock`; `-`, `=`, F6, `~`, Esc reach the session as held codes. ◇ `-film deNN` (S9.5) starts a film session.
  No new menus.
- **Gate:** G5, then a manual 30-second smoke by the implementer (sound on fire, music at appear, Caps Lock pause/resume
  stops and resumes music) recorded in the PR notes. **Commit:** `Deimos app: audio through the kit stream voice, typed keys + Caps Lock, -film argument; project.yml DeimosAudio`.

### A4 — minor — Stage + the gate card
- **Files:** `Deimos/WHAT-TO-EXPECT.md` (and `tools/stage-deimos.sh` only if staging needs a change).
- **Contract:** the Phase 1 staging (A2 of Phase 1) unchanged; WHAT-TO-EXPECT = what Phase 2 is and is not, the keys,
  the S9 stand-ins, design §7 deviations, the G4 result line, and the gate card below verbatim.
- **Gate:** G1 on HK main, G2 = **334/0**, G3, G4, G5, G9. **STOP for Ben.** **Commit:** `Deimos: Phase 2 staged — WHAT-TO-EXPECT (gate 2 card)`.

---

## What Ben checks — Phase 2 gate card ("does it play like Deimos")

Open `~/Desktop/Deimos Rising.app`; play Mariner Valley; compare with a longplay. Each line: what you'll see or hear,
and what would be wrong.
1. **Enemies and ground targets** appear as the map scrolls: Buzzsaw waves, two Bonus Stations, laser platforms, a
   pulse tank, geysers, a secret. Wrong: things popping in on screen (they enter 64 px above the top), ground units
   sliding against the map (they ride it).
2. **Two scroll stops.** About 61 s in, the map stops for ~27 s while Buzzsaw groups come down from the top; near the
   end it stops again ("Level 1 - Bridge") until you destroy every ground target on screen or ~27 s pass.
3. **Your ship** accelerates and drifts to a stop (no inertia beyond one step per tick), banks, slides 32 px under the
   side borders, can't go above the top 13 px.
4. **Ion Cannon:** tap = a pair of bullets + flash (max ~6 shots/s, each needs a fresh press); hold ~0.5 s = power-up
   charging (meter fills in 2 s), release = a stream of power shots; hold ~6 s = overload flashes and the ship blows up
   at ~8 s. **Plasma Bomb** (Option) lands on the crosshair 121 px ahead; down at the bottom edge pulls the crosshair in.
   **Select** (Space) does nothing in sector 1 (only one air weapon).
5. **Hits and death:** 7 full hits kill; ship explodes, coins spill, 2.7 s (last life 1.3 s) then you re-enter
   invulnerable for 2 s. Game over after the last life → the game starts again (◇).
6. **Score / coins / multiplier:** kills × multiplier; coins and pickups; extra life at 10,000 / 40,000 / 80,000.
7. **Level end:** "Sector Secured", ground-accuracy tally with ticking count, coin bonus, the defence bonus if you
   were never hit; then the game starts again at sector 1 (◇ — the campaign is Phase 3).
8. **Sound:** effects from the game's own mixer (at most 8 at once); the level music starts as the screen fades in.
   **Q2 (pitch):** bullet impacts `exsl` play short and high (speed = 1/pitch, as the code). If the longplay's impacts
   are deep and slow, say "flip pitch". **Q3 (music level):** music sits about half as loud as a full-volume effect
   (full scale 255). Too quiet? Say so.
9. **Volume keys `-`/`=`** (Q4): ±10 % with a click and a "Sound Volume 40%" message, applied as the app's own volume
   (your Mac's volume is never touched); the game starts at 50 % (the original's default) — quieter than you might
   expect.
10. **Caps Lock** pauses ("Press Caps Lock" notice; sound cut, music frozen) until released. **F6** toggles interlacing
    with a message. **`~`** opens the console: `FPS`, `VERSION`, `supermunki` then the cheats (`life`, `score`,
    `funds`, `shields`, `mult`, `accuracy`). **Esc** starts level 1 again (◇).
11. **Particles, wrecks and trails:** debris bursts in the unit's colours (each 3 px right/below of centre — a quirk we
    copy), stopped tanks become obstacles, bullet trails on some units.
12. **Not yet certain (MED):** the 24→16 sprite colour cut (gate 1, unchanged), particle colour shades, the "Press
    Caps Lock" notice placement, tally waits, the FPS counter showing 31, the crosshair "locked" frame timing.
13. **Demo replay (fallback oracle):** `open -a "Deimos Rising" --args -film de01` plays the shipped demo (no music —
    ◇ the menu music is Phase 4). Machine result: <G4 line>. If it misses, does the ship do what the demo pilot meant
    to do?
Q5 (invulnerability carry-over) is not reachable until level 2 (Phase 3).

---

## Execution order

| wave | HectorKit | lane Core | lane Audio/Render | lane Host/App | review legs (Opus) |
|---|---|---|---|---|---|
| 2.0 | K2 (push, pull --ff-only) | C0 | A1 | — | K2 two; C0 one; A1 two |
| 2.1 | — | C13 ∥ C16 | A2 (after K2 lands) ∥ R4 | — | one each |
| 2.2 | — | C7 ⚑ | — | — | two |
| 2.3 | — | C8 ⚑ | — | — | two |
| 2.4 | — | C9 ⚑ ∥ C10 ⚑ ∥ C14 ⚑ | — | — | two each |
| 2.5 | — | C11 ⚑ ∥ C15 ⚑ ∥ C17 ⚑ ∥ C19 ⚑ | — | — | two each |
| 2.6 | — | C12 ⚑ | — | — | two |
| 2.7 | — | C18 ⚑ | — | — | two |
| 2.8 | — | — | — | H2 ⚑ | two |
| 2.9 | — | — | — | H3 ∥ A3 ⚑ | H3 one; A3 two |
| 2.10 | — | — | — | A4 → Ben | one |

- **Disjoint files** inside a wave (each task's Files): 2.0 C0 owns `Seams/*`, `MSLRandom`, `DeimosAssets`,
  `Audio/*`, one switch in `DeimosRenderer.swift`; A1 owns `Package.swift` + `Sources/DeimosAudio/*`. 2.1 C13
  `Effects/*`; C16 `Game/{NoticeSlot,MessageQueue}`; A2 `DeimosAudio/{MusicStream,DeimosAudioEngine}`; R4
  `DeimosRender/{DeimosRenderer,ParticleStamps}` (after C0's switch arm). 2.4 C9 `Units/{Motion,Animation,OwnerLinks}`;
  C10 `Units/{StateTimer,Rules,SpawnSets,PowerupRelease}`; C14 `Player/*` except `PlayerPhase1.swift`. 2.5 C11
  `Combat/*`; C15 `Weapons/*` + `Player.swift` (delete the struct) + `PlayerUpdate.swift` (call site) +
  `ScoreBarState.swift`; C17 `Game/{Tallies,LevelEnd}`; C19 `Game/{FrameKeys,Console,Cheats,FrameController}`.
  Shared files are owned by exactly one task per wave: `Package.swift` (A1 → H2 → H3), `DeimosSession.swift` (C18
  only), `project.yml` (A3 only), `EntityDraw.swift` (C12, then C18).
- Cross-task calls go through `extension GameState` methods named in each contract; a task that needs a later task's
  behaviour calls a named hook that the later task fills (C14's weapon-handler call site → C15; C14's film input →
  C18's `FilmCursor`; C11's crosshair lock → C12).
- One Opus implementer per task (`fk-implementer`), own `--scratch-path`; the orchestrator merges, re-runs G1–G11 at
  the merge head, updates STATE, ends each session with a handoff + `spawn_task` chip (2–3 tasks per session; MAJOR
  tasks ≈ one seat each — memory "2 MAJOR tasks ≈ 190k seat").

---

## Pre-execution self-audit

1. **Scope coverage (design §8 Phase 2 row + brief).** Unit system: states/timer (C10), 17 rules (C10), spawn sets
   (C8 arming, C10 executor), motion (C9), culling (C9), groups/PERM (C7), owner links (C9) ✅. Collision/damage/
   destruction (C11) ✅. Player physics + respawn + death (C14) ✅. Five weapons + power-ups/overload + bombs + crosshair
   lock (C15, C12) ✅. Pickups/coins/multiplier (C11, C14) ✅. Particles/debris/blur (C13, C12, R4) ✅. Notices/
   messages (C16) ✅. Scroll pauses (C10, C12) and level end + tallies (C17) ✅. Effects mixer + music (A1, A2) + K2 ✅.
   Pause, Esc, `-`/`=`/F6, console + cheats (C19, H2) ✅. Machine gate de01 (H3, G4) ✅.
2. **Carries placed.** `HeadlessRun` film/start params → C18 (test helper) + H2 (`HeadlessRunner`) ✅. `playerOps`
   return type → C12 (`playerCommands`) + C18 (switch, delete) ✅. Esc latch eats sub-pass releases → H2
   (`testEscLatchClearsOnSubPassRelease`) ✅. P1 button mapping → C0 (guide + film census test, D31) ✅. Phase-4 prefs
   file → carried forward explicitly (S9.6) ✅. DeimosAudio decision → A1 + ruling above ✅.
3. **Ladder arithmetic.** C0 6, A1 8, C13 8, C16 6, A2 6, R4 3, C7 8, C8 10, C9 9, C10 9, C14 10, C11 10, C15 9, C17 8,
   C19 9, C12 7, C18 8, H2 8, H3 3 = **145** → 189 + 145 = **334** ✅. K2 +4 / +1 ✅.
4. **Numbers re-derived by probe** (Research notes): de01–de04 headers and input census (p11), provenance (p12), RNG
   values and float32 results (p13), colour variants (p14), the `FUN_10006b50` order (p15), placement rows and the two
   controller timelines (p16), the guide's controls (p17), the cull bounds (p18) ✅. From bank worked examples
   verbatim: hold-up table, Shuriken, Ion Cannon, sector-1 boss table, accuracy/coin arithmetic, voice ranking ✅.
   Self-derived only: the re-derived Phase-1 frame goldens (C18), the trace hash (H3), timing values marked "as read".
5. **RNG order** (invariant 6) is owned per site: C8 (creation), C9 (flee), C10 (re-arm, executor), C11 (media,
   bonus), C13 (particles), C0 (pitch), C14 (level start) — each task's precondition records its addresses ✅.
6. **Risks.** The film may predate the 1.0.6 code (G4.2–G4.3 rule) ✅; trig last-ulp (Hazards, G4) ✅; D-number
   collision (landmine d) ✅; real-time audio in review (K2 offline tests) ✅; long critical path C7 → C8 → C9/C10/C14 →
   C11/C15/C17/C19 → C12 → C18 → H2 → H3 (10 waves; Audio/Render/Kit lanes run beside it) ✅.

---

## Open questions for Ben (the build proceeds on the defaults; all on the gate card)

- **Q2 — pitch direction** (design §11.2, INDEX #49): default **as the code** — speed = 1/pitch.
- **Q3 — music loudness** (§11.3, INDEX #50): default **full scale 255** — music at 128/255 of a full effect.
- **Q4 — volume keys** (§11.4, INDEX #44/#52): default **the OS 9 behaviour as an app gain** (`-`/`=` ±10, click,
  message; start at the original's 50 %).
- **Q5 — invulnerability carry-over** (§11.5): default **as read**; not reachable in Phase 2.
- **New, only if G4 misses:** "the demo was recorded on an earlier build" — Ben's eyes on `-film de01` decide (G4.3).

---

## Bank corrections to append (each as a ⚑ planner-probe note in the named file; no bank file is edited by this plan)

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
   `flli`/`idli` 2001-11-12, `wede`/`plde` 2001-10-14 — the demos postdate every game-data entry; the binary is 1.0.6
   (2004-01-02). `Local/film/Last Film[last].film` is byte-identical to `de01`.

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
  its last recorded tick is game time ≈ 4,865, while the level end falls between game time 3,919 and ≈ 4,719
  (3,118 + `01m1`'s fixed 800-tick pause + 1…801 ticks of `01b1`'s), so the gate almost certainly includes the
  tallies and the defence/coin bonuses. A film session ends at
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
- **Not settled here (left to task preconditions):** the trig build precision (C7), the mask scale of the media test
  (C11), `FUN_100075e0` states 1–5/7/9 (C17), the crosshair-lock call site (C12), the "P1 active" gate flag (C14), the
  REPLAY banner format/position (C18). Each task records its reading; anything still MED goes on the gate card.
