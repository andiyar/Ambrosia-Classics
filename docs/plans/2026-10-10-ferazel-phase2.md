# Plan — Ferazel's Wand Phase 2 "Ferazel moves": the player, tiles, liquids, platforms, sound — 2026-10-10

> Status: **DRAFT for Ben's approval** (planner Opus 5.5, 2026-10-10; review ledger at the end). Implements
> `docs/plans/2026-10-06-ferazel-design.md` (APPROVED) **§8 Phase 2 only**, written against what Phase 1 landed
> (Classics main ee690ab, D26 as-built C0…A2, D32 gate PASSED).
> **Format (Ben, 2026-10-03): CONTRACTS, not code.** Files, public names (signatures only where they pin a seam),
> behaviour with bank + dump anchors, test names verbatim with the number each checks and where it came from, gate
> commands, commit messages. No implementations.
> **Numbers:** every expected value is from a planner probe run on this machine on 2026-10-10 (cited "probe A/B/C:
> file") or from the bank with its section and label, or is hand arithmetic shown inline. Probes + four research
> digests (not committed): `$PROBES` = this session's scratchpad `probes/` and `digest-{A-player,B-world,C-camera-fx}.md`.
> Where a probe or the dump disagrees with the bank, **the dump wins** (Ben 2026-10-07, "follow the binary") and
> "Bank corrections to append" says so with the raw address.

**Goal.** Ferazel moves the way the original moves on levels 1 "A Scent Of Peril" and 2 "Central Caverns":
`.HandlePlayerSprite @1004d5fc` in full for every state those levels reach (walk, run, jump, spin, fall, land, crouch,
cling, climb, pull-up, swim, hurt, dying), tile collision with every `.WallBounce`/`.WallBounceBG` kind, liquids
(water, acid, healing brine, current, flotation, drowning), the movers he meets (platforms incl. radial rotors and
wheels, spiked pendulums, cannons, trampolines, bridges, pushable crates/boulder, passages, the wall tunnel), splash
particles and the water effects, every sound cue the movement makes through the original's 8-voice Sound Tool mixer,
and the camera as read (`.PlayerScroll @1004c528`). Ropes and springs (same phase, design §8) are built and
synthetically tested — **neither is placed on levels 1–2** (first rope L3, first spring L15; probe B `probe_all.out`).
Ben's gate: **feel on levels 1–2.**

**Scope rulings (D33, recorded at merge):**
- **Ben, 2026-10-10:** (1) level 1's exit loads the level it unlocks straight away (level 1 → 2) **and** a hidden
  launch switch `-FerazelLevel N` / `defaults write com.ambrosiaclassics.ferazel FerazelLevel N` starts on level N —
  both ◇ stubs, replaced by Phase 3's stage-complete + world map; (2) on death: dying animation + the original border
  wipe `.DeathEffect`, then **restart the current level from its start with fresh globals** (◇ stub for Phase 3's
  menu/Continue; no invented checkpoints).
- **Seat, under the 100 % rule (design §8 row 2 = "Ferazel moves"):** everything that moves or hurts the player on
  levels 1–2 is Phase 2 — platforms (modes 1, 2, 3, 10, 11, 20 + the rest of the class for free), 1480–1489 radial
  bars/balls, cannons 1090–1098, trampolines 1470, Box solids + crate/boulder pushing, passages 2900/2901, wall
  tunnels 3000–3009, damaging FG surfaces, liquids, drowning. Enemies (Walker/Crawler/Roach/Bat/Frog) stay in their
  Setup faces with **no Handle and no contact damage** (Phase 5); Bonus pickups are not collected and the 5 coins a
  pendulum hit costs are recorded but not spawned (Phase 4 class); teleporters, save points, doors, NPCs, signs are
  solids only (mechanisms Phases 3–4); Caps Lock pause and Esc stay Phase 3.
- **Keys:** the original defaults only (engine §7.1: keypad 4/6/8/5 move, Shift run, Option jump, ⌘ use, keypad 7/9
  items). Phase 1's arrow-key stub is removed with `CameraFocusDriver`. Rebinding is Phase 3's Options dialog.

**Architecture (design §3, unchanged).** `FerazelCore` (Foundation + HectorResources) gains the sprite physics world,
the player, tile collision, liquids, movers, particles' state, `FastRand`, sound-cue arithmetic, camera; `FerazelRender`
gains the draw-effect modes the movers need, particle/water-effect drawing, the death wipe, gamma steps and a
Foundation-only **Sound Tool mixer** (a `PCMPullSource`); `Ferazel/App` wires sounds, level switching and the restart.
**HectorKit is not touched** (`ShellMixer.attachStream(_ source: any PCMPullSource)` exists, HK main 0c65dcb, floor 328).

**Tech:** Swift 6.4 / Xcode 27 beta, SwiftPM tools 6.0, XCTest, macOS 15, xcodegen. Python only as the planner's probe.

**Paths:**
```
WT      = /Users/andiyar/Developer/Ambrosia-Classics/.claude/worktrees/<lane worktree>   (branched from Classics main)
HK      = /Users/andiyar/Developer/HectorKit   (main 0c65dcb, zero-skip FLOOR 328 — read-only for this phase)
SCRATCH = the executing session's scratchpad directory
DUMPS   = $WT/ghidra/ferazel/Ferazel_pef.decompiled.c (88,106 lines, contains every handler; "M l. N" below),
          Ferazel_handlers.decompiled.c, Ferazel_pef.disasm.txt ("raw XXXXXXXX") — committed; regenerate only with
          ghidra/regen-ferazel.sh. Bank tools: run docs/ferazel/tools/*.py with FZ_PEF=ghidra/ferazel/Ferazel_pef
          (the default path moved 2026-10-08).
```

---

## Verification model (read first)

**Machine gates — executors close these alone** (copy literally):

| # | gate | command | expected |
|---|---|---|---|
| G1 | HectorKit untouched | `git -C ~/Developer/HectorKit status --porcelain; git -C ~/Developer/HectorKit log --oneline -1` | empty; `0c65dcb` or a later main the orchestrator pulled (never written by this phase) |
| G2 | `Ferazel/Core` suite | `cd "$WT/Ferazel/Core" && swift test > "$SCRATCH/fz.log" 2>&1; grep -cE "^Test Case '.*' (passed\|failed\|skipped) \(" "$SCRATCH/fz.log"; grep -cE "^Test Case '.*' (failed\|skipped) \(" "$SCRATCH/fz.log"` | the task's ladder total, then `0` |
| G3 | census unchanged | `cd "$WT/Ferazel/Core" && swift build -c release --product ferazel-census > /dev/null && "$(swift build -c release --show-bin-path)/ferazel-census" "$WT/Resources/Ferazel" > "$SCRATCH/census.md"; echo $?; tail -n 1 "$SCRATCH/census.md"` + `testStdoutEqualsCommittedCensus` green (Phase 1 G3) | `0`, `Totals: items 1,108 decoded, failures 0` |
| G5 | app builds | `cd "$WT" && xcodegen generate && xcodebuild -scheme Ferazel build 2>&1 \| tail -n 1` | `** BUILD SUCCEEDED **`. Aki/BTX/Deimos only if `project.yml` changes (memory: no cross-app builds for game-only tasks) |
| G6 | scope fence | `git -C "$WT" diff --name-only <task base>..HEAD` | ⊆ the task's **Files** (+ `docs/DECISIONS.md` / bank file named by the task) |
| G7 | layering | as Phase 1 G7 (both greps empty; `Sources/ferazel-census` excluded) | empty |
| G9 | staged app boots (A4) | Phase 1 G9 (pid, clean quit, no new crash report). Agents cannot screenshot on this machine | a pid; clean quit; no crash report |
| G10 | clean tree per commit | `git -C "$WT" status --porcelain \| grep -v '^??'` | empty |

**Test ladder (`Ferazel/Core`, cumulative, canonical merge order; STOP if different):** base **102** →
F1 **108** → F2 **116** → F3 **126** → P1 **138** → P2 **147** → P3 **157** → P4 **167** → P5 **175** → W1 **183**
→ W2 **191** → W3 **199** → W4 **205** → E1 **213** → E2 **221** → S1 **228** → S2 **233** → G1 **237**. Merged in
another order: previous total + the task's N.

**Goldens that move (◈).** Phase 1's goldens (`testFirstFrameGoldenLevel1` `9db8f32f7e3d88b4`,
`…HighestTieBreak` `b80b0efd384ffdb9`, `testPanFrameGoldens` `f6296c7e706130f3` / `e7a951e3eafca30a` /
`3c5aee2b87819db6`) were measured with Phase-1 stubs. Only tasks marked **◈** may change a golden, only for the reason
the task names, in the same commit, recording `old → new` and the reason in the commit body; the reviewer re-runs
twice for determinism. Any other golden change is a STOP (Invariant 10).

**Honesty gate (Ben only):** the Phase 2 gate card ("What Ben checks"). Completion is phrased "machine gates green;
Ben's gate pending".

**What the machine does NOT prove:** the feel (timing at 30 Hz, jump arcs, camera ease) — only that the arithmetic is
the binary's; MED readings on the gate card; the RNG stream (the original seeds from the clock — no capture can be
matched, only the call order); audio loudness on modern output.

---

## Non-negotiable invariants

1. **Layering** — Phase 1 Invariant 1 unchanged. The Sound Tool mixer lives in FerazelRender, Foundation-only, and
   conforms to HectorAudio's `PCMPullSource`; only `Ferazel/App` touches `ShellMixer`.
2. **Transcribe, don't reinvent.** Every behaviour cites its bank section and the dump (M line / raw address). A
   contract here never overrides the dump: if they disagree, STOP and report; the orchestrator rules under "follow the
   binary" and records a bank correction.
3. **Call order is behaviour.** The frame order is `.GameLoop`/`.PaintFrameWrap`'s (digest A §1.1, C §2.2):
   `FindUpperLeftCorner` → draw (tiles, lights, `.HandleLights`, `.WrapDrawWaterEffects`, `.WrapDrawSprites`, drawn
   frames only: `.DrawParticles`, copy, `.EraseParticles`) → parity flip → `.HandleIdleSprites` → `.MTHandleSprites`
   (active-list order, `next` loaded **before** each handler, M l. 30171) → `.MTCollideSprites` → the player special
   pass `.MTCollideSpecialSprite(player, .HitPlayerSprite)` → `.HandleParticles` → `.WrapEraseSprites` → status bar.
   `.StandardSpriteHandles` zeroes per-frame fields (`+0x11c`, clips, `+0x180`, `+0xd8`, `+0x140`), so every read
   depends on its position relative to SSH (INDEX reviewer notes).
4. **One RNG stream.** `FastRand` (F1) is one session-owned stream consumed in the binary's call order from level start
   (Setups first, then per frame). Tests seed it explicitly (seed 1 unless named); the app seeds from the clock like
   `.InitAppGlobals` (M l. 334). Every `STPlay3DSoundRand` draws its `FastRand(10000)` **even with sound off** (raw
   `10047d60..10047d90`).
5. **Fixed point as the binary.** Positions 24.8 (`+0x14` x, `+0x1c` y), velocities 1/256 px/frame, angles deg·256;
   every `(int)` of a double truncates toward zero (fctiwz); f32 constants are applied as f32 then widened, exactly as
   the dump (digest A §3.1 note). `>>` on negatives is arithmetic (srawi) where the dump uses `srawi`, C division
   (truncation) where it divides.
6. **Stubs are named.** Rows of `.HandlePlayerSprite` that belong to later phases (digest A §1.2 "later") are no-ops
   whose flags stay 0 because their writers do not exist yet; each is listed in the code as `// later: <phase>` and is
   never "simplified" away. The ◇ stubs of this phase: `LevelFlow` (exit → next level, restart after death), the
   `FerazelLevel` switch, inert enemy/Bonus Handles, unspawned coin pickups.
7. **No modern affordances.** No coyote time, jump buffer, input smoothing, camera smoothing beyond the binary's,
   collision "fixes", or audio normalisation. The left/right asymmetry, the double-handled pendulum frame, the
   un-clamped shuttle overshoot and the first-frame radial position are behaviour.
8. **Data in git, tests never skip** (Phase 1 Invariant 5).
9. **Seam types are LOCKED** (design §3): cases and fields may be **added**, never renamed or retyped. This phase adds
   (S3 below) and nothing else.
10. **STOP on any unexpected number** — test totals, hashes, census lines, probe numbers. Report; never edit an
    expectation or the code to make them agree.
11. **Commits.** Explicit paths only; never `git add -A`/`.`; never `git stash`; verify `git branch --show-current`
    before every commit; trailer `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`. G10 after each commit.
12. ⚠️ **Landmines.** Phase 1 Invariant 11 (a)–(d) still apply. (e) D-numbers collide: this plan's rulings are
    **D33** (D31 is on the unmerged `deimos-phase2` branch, D32 is Ferazel's Phase 1 gate) — confirm on `origin/main`
    at commit time, renumber in the same commit if taken. (f) The bank's wave-1 "handler dump l. N" numbers are **not**
    a fixed offset from the current dump (drifts 43744 → 43755 across `.HandlePlayerSprite`): use M lines / raw
    addresses from this plan. (g) One session cannot write a second worktree (PreToolUse hook); parallel lanes in one
    worktree use their own `swift test --scratch-path`.

### Hazards for every implementer (read before any dump reading)
Phase 1 plan "Hazards for every R implementer" applies verbatim (`lwzu/stwu` +8 loops; a TOC-load count is not a write
count; SSH zeroes per-frame fields; the signed-compare idiom). Added for Phase 2:
- **Live key reads.** `.HandleKeys` and `.HitPlayerTileSprite` call `IsInputKeyPressed` at each test; Core reads one
  `InputActions` snapshot per step (equivalent: keys cannot change inside a frame) [MED, gate card 12].
- **Globals vs fields.** Most player state lives in globals (`_DAT_100a0xxx`), not the sprite record; model them in
  `PlayerState` under the binary's names (as comments) so a reviewer can grep the address.
- **Entry rect.** `.SeparateFromTiles2` computes the hot rect once before its 9-cell loop (M 35206–35209) [MED].

---

## Shared architecture (LOCKED — every task codes against these names)

### S1. Package `Ferazel/Core` — unchanged targets
New source folders only: `Sources/FerazelCore/{Random,Physics,World/Movers,Player,Particles,Sound,Flow}/`,
`Sources/FerazelRender/{Effects,Sound}/`; new test files named per task. No new target (Landmine c does not arise).

### S2. FerazelCore public surface added this phase (★ LOCKED after Phase 2; ◇ = Phase-2 stub, replaced later)
- ★ `FastRand` (F1) — `struct FastRand { var seed: Int32; init(seed: Int32); mutating func next(_ n: Int16) -> Int16;
  static func clockSeed(secondsSince1904: UInt32, ticks: UInt32) -> Int32 }`.
- ★ `SpriteSlot` gains the physics record (F2): `x256/y256` (+0x14/+0x1c), `vx/vy` (+0x24/+0x28 as the binary names
  them), `gravity` (+0x110), `hotRect` (+0x34), `centre` (+0xe/+0x10), `drawnX/drawnY` (+0xc6/+0xc4), `groundKind`
  (+0xce), `ceilingHit` (+0xcf), `onSprite` (+0xcd), `oneWayLanded` (+0xd0), `material` (+0xd8), `ridden` (+0xdc, an
  id), `rider` (+0xe0), `ridingLatch` (+0x186), `oneWay` (+0x185), `sag` (+0x13a), `pushMass` (+0x138), `pushForce`
  (+0x13c), `waterRow` (+0x11c, existing), `lastWater` (+0x120), `waterKind` (+0x128), `underwaterDone` (+0x140),
  `invulnerable` (+0x116), `flash` (+0xaa), `flashTable` (+0x1b4), `hp` (+0xa4), `buoyancy` (+0x19e), `floatOffset`
  (+0x1a0), `reentry` (+0x130), `occluder` (+0x1be..+0x1c4), `siblings` (+0x1d4/+0x1d8), `radial` (`Radial?`, +0x198
  block), `handler: SpriteHandler`, plus `scratch: [Int: Int32]` **forbidden** — every field a task needs is named.
  Field list is open to additions by later tasks (Invariant 9); each addition names its offset.
- ★ `enum SpriteHandler { case player, platform, chain, background, box, effect, rope, ropeSegment, inert }` — `inert`
  = Phase 4/5 classes (Bonus, enemies): no Handle, no hit callback, still drawn, idled and erased.
- ★ `SpriteWorld` (F2, `Session/SpriteWorld.swift`) — owns `ActiveList`, `IdleSprites`, `FastRand`, `GameGlobals`,
  the level, `PlayerState`; `func handleSprites()` (`.MTHandleSprites`: walk with next pre-loaded),
  `func collideSprites()` (`.MTCollideSprites`), `func collideSpecial()` (player pass), `changeLayer(id:layer:)`
  (`.MTChangeSpriteLayer` with the no-op guard), `newSprite(type:x:y:layer:handler:) -> Int?` (`.MTNewSprite`).
- ★ `TileSolver` (F3, `Physics/`): `TileHotRects` (`.InitTileHotRects`), `wallBounce(kind:…)`, `wallBounceBG(…)`,
  `separateFromTiles(_ id:, pass:)` (`.SeparateFromTiles2 @1003c804`), `applySpeedAndSeparate(_ id:)`
  (`.ApplySpeedAndSeparateFromTiles @1004b83c`), `applyGravityAndSeparate`, `applyFriction`, `enforceMaxSpeed`,
  `accelerateSprite`, `accelerateBasedOnSlope` — each with a tile-callback closure per handler.
- ★ `Player` (P1–P4, `Player/`): `PlayerState` (every Phase-2 global of digest A §1–§5 under its binary address),
  `Player.handle(world:keys:)` (= `.HandlePlayerSprite`, the 42-row order of digest A §1.2), `HandleKeys`,
  `PlayerTiles` (`.HitPlayerTileSprite`), `PlayerLiquids` (`.HandleUnderWater` player side, breath, drowning),
  `HitPlayerSprite` (the special pass arms built this phase). Replaces ◇ `PlayerPose` (deleted in P3).
- ★ `PlayerScroll` (P5, `Camera/PlayerScroll.swift`) — replaces ◇ `CameraFocusDriver` (deleted in P5); `Camera`
  gains the snap-veto inputs (riding `_DAT_1009fd34`, water `+0x11c/+0x120`).
- ★ Movers (`World/Movers/`): `Radial` (W1, tables + `.MakeRadial/.UpdateRadialPos/.FindUpdatedRadialSpeed/
  .RadialWheelStep/.BounceRadial`), `PlatformSprite` (W1), `ChainSprite` (W1), `BackgroundSprite` (W2: 1480–1489,
  cannons, tunnels, springs, passages, plants re-face), `BoxSprite` (W3: rects/one-way, common tail, trampoline),
  `RopeSprite` (W3).
- ★ `Particles` (E1, `Particles/`): `ParticlePool` (2000 × record, hint/count/hwm), `ParticleLife` (Core-side zero
  table), `Splash`, `BloodSpray`, `WaterEffects` (`.FillCachedTileArray`, `.WrapDrawWaterEffects` emission).
- ★ `SoundCues` (S1, `Sound/`): `.STPlayRegSound/…Pitched/.STPlay3DSound/…Pitched/…Rand` arithmetic,
  `CalcStereoVolume`, `PEDistance`, the snd-slot table (digest C §4.3).
- ◇ `LevelFlow` (W4, `Flow/LevelFlow.swift`): `next(level:exit:map:) -> Int?` (`Mmap` node links, world-data §4.2),
  restart-after-death; emits `ShellRequest.loadLevel`.
- ★ `FerazelSession` — `init(resources:prefs:level:seed:faceBounds:)` (`seed: Int32 = 1` added); `step(keys:)` runs
  the Invariant-3 order through `SpriteWorld`.

### S3. Seam additions (cases/fields ADDED only; Invariant 9)
```swift
// DrawOp — new cases, at their .PaintFrameWrap call sites
case wrapDrawWaterEffects([WaterFaceDraw])     // before .wrapDrawSprites (M l. 9200–9230); E1
case drawParticles([ParticleDraw])             // drawn frames only, before .copyToScreen (M l. 9433); E1
case eraseParticles                            // drawn frames only, after .copyToScreen (M l. 9449); E1
case deathEffect(step: Int)                    // .DeathEffect @10005270 step 0..49; E2
case gammaStep(numerator: Int, denominator: Int) // GammaFadeOut/InAsync step (lighting-tables §10); E2 (passages)
// SpriteDraw — new fields (defaults keep Phase-1 values): rotation (+0x1aa, 0), scale (+0x1ae, 0x100),
//   flash (+0xaa, 0), flashTable (+0x1b4, 0), occluder (+0x1be..+0x1c4, nil)                       ; E2
// SoundCue — new field: onlyIfIdle: Bool = false     (FUN_100916dc gates)                       ; S1
// FrameOps — new field: soundStops: [Int16] = []      (FUN_10091504)                             ; S1
// ShellRequest — new cases: loadLevel(Int), deathEffect                                          ; W4
// WaterFaceDraw = {cellX, cellY, tile, waterKind} ; ParticleDraw = {slot, kind (signed), age, shape, v, h}
```

### S4. FerazelRender additions
`ParticleRenderer` (E1: draw/erase/colour rows/colour-0 kill report), `WaterFaceBlitter` (E1), `SpriteBlitter` modes
3/4 (hurt flash), 6 + water split, 9, scale (`.BlitEncFaceScale`), rotation (`.BlitEncFaceRot`), the occluder clip (E2),
`DeathEffect` (E2), `ScreenGamma` (E2), `SoundTool` (S2: `final class SoundTool: PCMPullSource`), `FrameRenderer`
loads every player sheet of digest A §2.3 and the mover sheets (P3, W1–W3 add their PICTs to its load list).

### S5. App
`FerazelController` (A3): keys from `FerazelPrefs.keys` only; `FrameOps.sounds`/`soundStops` → `SoundTool`
(`ShellMixer.attachStream`); `ShellRequest.loadLevel` → rebuild session + renderer; `.deathEffect` → run the wipe on a
1-tick cadence (≥ 1 tick per step, as `.DeathEffect`); `FerazelLevel` default/launch arg; seed from the clock.

---

## Tasks

Legend as Phase 1: ⚑ MAJOR = **two Opus review legs** (spec compliance, then quality); minor = one Opus leg. "→ N" =
ladder total after the task. Every task: G2, G6, G7, G10; G3 once at each wave end; G5 from A3 on (and in any task
that touches `Ferazel/App`). **All implementers and reviewers are Opus 5.5 (Ben 2026-10-07; no Fable legs).** Each
task's precondition: read the named bank sections, then **re-read the named dump ranges** before writing code.

### Wave 2.0 — foundations

#### F1 — minor — `FastRand` + the Setup draws (→ 108)
- **Files:** `Sources/FerazelCore/Random/FastRand.swift`; `Sources/FerazelCore/Sprites/SetupFaces.swift` (the draws
  only); `Sources/FerazelCore/Session/FerazelSession.swift` (seed parameter); `Tests/FerazelCoreTests/FastRandTests.swift`.
- **Contract:** `.FastRand @100340e0` (M l. 31282–31313, raw `1003411c..100341b8`): seed `_DAT_100a17e8`;
  n ≠ 0 → seed = 16807·seed mod (2³¹−1); lo = seed & 0xffff; **lo == 0x8000 → returns 0** (seed keeps it);
  result = (Int16)((n·lo) >> 16). `clockSeed` = Time + Ticks (M l. 334). The level-1 Setups draw as the binary does,
  in `.SetupLevelSprites` spawn order (R4's [MED] list, meanings digest C §3.2): Xichron `1005db3c/4c/60` R(19) →
  `+0x46`, R(6)+0x1c → `+0x112`, R(3)+2 → `+0x114`; every Bonus `1005e8c0` R(60) → `+0x14c`; torch `1005df24`
  −R(10)−5; Walker `1006740c`, `10067760` R(70)+0x78, `10067780` R(400)+1000. Fields not drawn by Phase 1 are added to
  `SpriteSlot` by name. Draws are consumed even where the field is unused until a later phase.
- **Tests (6):** `testParkMillerEquivalence` (200,000 steps from seed 1 = 16807·s mod 0x7fffffff; probe C
  `C_fastrand.py`) · `testSeedOneSequence` (R(100)×10 = 25, 23, 67, 4, 71, 85, 55, 3, 18, 1; states 0x41a7,
  0x10d63af1, 0x60b7acd9) · `testLow8000Quirk` (seed 0x2b6cfbb6 → state 0x00018000 → R(100) = 0) · `testROneAdvances`
  (R(1) = 0, next R(100) from seed 1 = 23) · `testLevel1SetupDrawCount` (the number of draws the level-1 Setups consume
  and the first Xichron's `+0x46` under seed 1 — self-derived, recorded, reviewer re-derives by hand from the spawn
  order) · `testSessionDeterministic` (two sessions, seed 1, 60 frames, identical `FrameOps`).
- **Commit:** `FerazelCore: FastRand (Park–Miller, lo 0x8000 quirk) + the level-1 Setup draws; session seed; 6 tests`.

#### F2 — ⚑ MAJOR — Sprite physics world and the rider contract (→ 116)
- **Files:** `Sources/FerazelCore/Sprites/{SpriteSlot,ActiveList}.swift`, `Sources/FerazelCore/Session/SpriteWorld.swift`,
  `Sources/FerazelCore/Physics/{StandardSprite,RectBounce}.swift`; `Tests/FerazelCoreTests/SpriteWorldTests.swift`.
- **Contract:** S2 `SpriteSlot` fields + `SpriteHandler`; `SpriteWorld` passes (Invariant 3; PR2 §8.1–§8.4);
  `.MTChangeSpriteLayer` **no-op when the layer is unchanged** (raw `100332a0..100332a8`) and re-insert otherwise — a
  sprite moved during the handle pass to a layer above everything is reached again (handled twice that frame);
  `.MTNewSprite` slot/insert rule (R4's insert); `.StandardSpriteHandles` (M l. 32440–32610: invul/flash countdowns,
  `+0xcd = +0xce`, `+0x92 = 0`, re-entry `+0x130` count-up, water current (§3.4 of digest B: `+0x118 < 0x1d`, last
  frame in kind 0, `+0x8a`; counter `+0x94` to 33, push `cur·n/33` C-division, none while riding), `+0x120 = +0x11c`
  then `+0x11c = 0`, wind, **carry** (`+0xdc`: x += (solid.x − solid.drawnX)·256, y += (solid.y − solid.drawnY)·256 +
  0x100, children carried), `+0xd8 = 0`, `+0x140 = 0`) and `.StandardSpriteCleanup` (M l. 32627–32700: centre, `+0xdc`
  clear, `+0xe0` unless `+0x186`, occluder clip, exit-splash hook for E1); `.PlatformBounce @100377c4` (M l.
  32985–33078) + `.RectBounce` (landing needs mover vy > 0, M l. 36296–36300; one-way slack 8 / 0x20 sloped, l.
  36247; mover x restored on landing; `+0xcd = 1`, `+0xce = 3`, `+0xdc = solid`, solid `+0xe0`, `+0x186`; sag solid
  vy += vy·`+0x13a` >> 8 when entry vy > 0x200; side push `solid.vx += F·(mass·(mover.vx − solid.vx) >> 8) >> 8`);
  `.ApplyFriction`, `.EnforceMaxSpeed`. `inert` sprites skip handle and hit. The Phase-1 session keeps working (its
  stub pose is a `player`-handled slot until P3).
- **Tests (8):** `testChangeLayerSameLayerIsNoOp` · `testChangeLayerToFrontReHandlesInSameFrame` (handled ×2) ·
  `testRectBounceLandingNeedsPositiveVy` (vy 0x1b8 lands → 1; −0x100 → 0) · `testOneWaySlackIs8` (previous bottom 8 px
  below the top lands, 9 does not) · `testLandingSagAdds13aShare` (entry vy 0x400, `+0x13a` 0x50 → solid vy +320) ·
  `testLandingRestoresMoverX` · `testCarryAddsDrawnDeltaPlusOnePixel` (+5 px since draw → rider +5 px x, +1 px y) ·
  `testCurrentRampsOver33Frames` (550: 16, 33, 50, 66, 83 … 533 at n 32, 550 from n 33; 0 while riding). Sources:
  digest B §2.1, §3.4 (M lines above).
- **Commit:** `FerazelCore: sprite physics world — handle/collide passes, layer change guard, StandardSpriteHandles/Cleanup, PlatformBounce, carry; 8 tests`.

#### F3 — ⚑ MAJOR — Tile solver: `.SeparateFromTiles2`, `.WallBounce`, `.WallBounceBG` (→ 126)
- **Files:** `Sources/FerazelCore/Physics/{TileHotRects,WallBounce,WallBounceBG,SeparateFromTiles,Integrate}.swift`;
  `Sources/FerazelCore/World/LevelHeader.swift` (rename the doc of 0x270e only — see Bank corrections A10);
  `Tests/FerazelCoreTests/TileSolverTests.swift`.
- **Contract:** physics §2–§3, player-states-2 §9–§14, digest A §4.1–§4.4. `.SeparateFromTiles2 @1003c804` (M l.
  35130ff.): writes `+8/+0xc`, `+6/+0xa` from 24.8 **at entry to every call** (raw `1003c82c..1003c844`), clears
  `+0x181`; cell = hot-rect centre / 32 (trunc); order (c,r), (c−1,r−1), (c,r−1), (c+1,r−1), (c−1,r), (c+1,r),
  (c−1,r+1), (c,r+1), (c+1,r+1); entry hot rect computed once [MED]; FG kind ≠ −1 ∧ rect meets the tile's FG hot rect
  → crunch nibbles (if `+0xeb`) then `callback(kind, 1)`; BG kind ≠ 0 ∧ full cell meets → `callback(kind, 0)`.
  `.WallBounce` full table (hundreds → material; `k < 0 ∨ k > 0x3c` → no collision; centring except 0, 2, 8, 0xb,
  0xd, 0xe, 0x24..0x2b; 0x3c = kind 3 at Y−8; kinds 4–7 revert to the call's entry position; slopes land
  `vy = |vx| + 0x100` / `|vx|/2 + 0x100` / `2|vx| + 0x100`; 0x2c..0x2f set `+0xce` even rising; ice once per frame
  `+0x181` with f64 slide factors 7.07/3.82/9.23/2.86; `+0xd8 = material` if > 0). `.WallBounceBG` (one-way floors
  `Bprev ≤ Y+17`, slopes `Bprev ≤ Y+s+3`, ceilings two-way, `+0xd0 = 1`, position re-synced). `.ApplySpeedAndSeparate
  FromTiles @1004b83c` (M l. 43183): x += vx; vy ≤ 0x400 → one step + separate, then **vy == 0 ∧ `+0xce` == 0 ∧
  climb == 0 → jump counter 0** (raw `1004b998..1004b9c8`, returned to the caller as a flag); vy > 0x400 → 0x400 steps
  with a separation after each, stop when vy changes, remainder + one more separation. `.AccelerateSprite`
  (×0.8 when `+0x11c ∨ +0x120`, M l. 32768), `.AccelerateBasedOnSlope` (f32 0.707/0.923/0.382 by kind; ×0.8 tests
  `+0x11c` only, M l. 32853 — never fires for the player, Bank correction A5).
- **Tests (10):** `testKind3FloorLandsOnlyFalling` (bottom = Y+16, vy 0, `+0xce` 3; rising passes) ·
  `testKind0WallPush` (moving left into kind 0: left edge X+16, vx 0, no `+0xce`) · `testSlope45LandingVy` (kind 0xc,
  vx 1000 → vy 1256, `+0xce` 0xc) · `testKind2cSnapsWhileRising` (vy −500 → `+0xce` 0x2c, vy 2|vx| + 0x100) ·
  `testKind3cIsFloor8pxHigher` · `testNoCollisionKinds` (0x30, 0x31, 0x3a, 0x3b, 80..95, 0x4e → no effect) ·
  `testOneWayLandsOnlyFromAbove` (BG 103: Bprev Y+17 lands, Y+18 passes, `+0xd0` 1; BG ceiling two-way) ·
  `testRestoreUsesCallEntryPosition` (kinds 4–7) · `testApplySpeedStepsOf0x400` (vy 0x1000 → 4 sub-steps, stops at the
  landing step) · `testSlopeFactorsF32` (kind 0xf accel (int)(335·0.707f) = 236, cap (int)(1900·0.707f) = 1343; 1:2
  309/1753; 2:1 127/725 — probe A `misc.out`).
- **Commit:** `FerazelCore: tile solver — SeparateFromTiles2 (9-cell, entry rect), WallBounce kinds + materials, WallBounceBG one-way, ApplySpeedAndSeparateFromTiles; 10 tests`.

### Wave 2.1 — the player (lane A: P1 → P2 → P3 → P4; lane B: P5 after P2)

#### P1 — ⚑ MAJOR — Player motion: `.HandleKeys` movement + the frame skeleton (→ 138)
- **Files:** `Sources/FerazelCore/Player/{PlayerState,Player,HandleKeys}.swift`; `Tests/FerazelCoreTests/PlayerMotionTests.swift`.
- **Contract:** `PlayerState` (S2) initialised as `.SetupPlayerSprite @1004aefc` + `.ClearPlayerVars @1004aa48` (layer
  10, type 0x45, gravity 0x1b8, hot rect (0x26,0x22,0x3e,0x55) = 24×51 at centre offset (50, 59), HP/breath from `G`,
  F from `G+0x16`, breath phase 3, climb phase 1, the start position x−32+50 / y−32+59 for the globals). `Player.handle`
  = digest A §1.2 rows 1–42 in order, rows marked "later" as named no-ops (Invariant 6). `.HandleKeys @10052ac0` (M l.
  47047–47884) steps 3, 6–9 of digest A §5.2: L/R block gated by **climb == 0 ∧ crouch depth == 0** (M l. 47360) and
  the USE/item/teleporter tests (all false in Phase 2); ground walk accel 0x14f from rest / 0x104 continuing, run
  0x1f4 / 0x12c, max 0x76c / 0xc80, **RIGHT adds +0x14a in every non-cling state while vx < airMax** (raw `100539a4`),
  LEFT only in plain air (raw `10053780`); rope ±1000 clamp ±0x960; swim ±0xd2; air drag 100 every airborne frame;
  ground decel 800 (300 stunned); gravity 0x1b8 / swim 0x50 / water-spin 0x118 / rope 0; submerged brake vy −= 0x200
  when > 0x6a4 (raw `1004daec..1004db10`); terminal 12000; vy 0 → 1; jump impulse `J − 0xc80 − ((|vx| + 0x4e2) >> 3)`
  cap 8000, sustain while counter 1..5, counter 6 ground / 3 cling / 0 air via the else-refill (no auto-repeat, no
  coyote, no buffer); **the JUMP arm is gated by shield raise `PTR_DAT_100a05e8` < 1** (raw `10052ae8`, `10053ec8`);
  DOWN block sets spin when 0 < counter < 6 **before** the JUMP arm (no mid-air refill); wall jump vx ±0x8ca; climb
  ±1000 with the pre-move ease ±100; exertion +1 walk (< 0xb9) / +3 run / +8 jump; facing rule digest A §5.3. Tile
  callback = a test double until P2.
- **Tests (12, synthetic on a flat kind-3 floor; probe A `kinematics.out`, `jumpcycle.out`):**
  `testWalkRightFromRestReachesMaxIn4` (vx 665, 1255, 1845, 1900) · `testWalkLeftFromRestReachesMaxIn8` (−335, −595,
  −855, −1115, −1375, −1635, −1895, −1900) · `testRunRightOvershootsThenClamps` (830, 1460, 2090, 2720, 3350, 3200) ·
  `testStopFromWalkAndRun` (1100, 300, 0 / 2400, 1600, 800, 0) · `testTurnRightFromWalkMax` (−435, 230, 820, 1410,
  2000, 1900) · `testAirHoldRightOscillates` (from 1900: 1800, 2030, 1930, 1830, 2060, 1960, 1860, 2090) ·
  `testAirCoastToZeroIn19` · `testJumpImpulseAtRestWalkRun` (−3356 / −3593 / −3756) · `testFullJumpApex` (held 6:
  apex −25752/256 = 100.59 px at frame 12) · `testTapJumpApex` (held 1: −11172 = 43.64 px; first descending frame 8) ·
  `testNoAutoRepeatOrMidAirSpinRefill` (JUMP held through a landing: counter stays 0 until released; DOWN+JUMP in the
  air does not refill) · `testTerminalVelocityAndZeroBump` (12000 on frame 28 from vy 1; −440 + 440 → 1).
- **Commit:** `FerazelCore: player motion — HandleKeys movement, gravity/drag/decel, jump impulse and sustain, PlayerState; 12 tests`.

#### P2 — ⚑ MAJOR — `.HitPlayerTileSprite`: landing, ceiling, cling, pull-up, crunch call (→ 147)
- **Files:** `Sources/FerazelCore/Player/{PlayerTiles,GroundCeilingEffects}.swift`, `Sources/FerazelCore/Player/Player.swift`;
  `Tests/FerazelCoreTests/PlayerTileTests.swift`.
- **Contract:** `.HitPlayerTileSprite @10054ca8` (M l. 48113–48358) for FG/BG/crunch/water dispatch (digest A §4.3);
  three separation passes per frame (pre-move row 13, move row 22, end row 35 = the only water pass); cling on kinds
  0/5 (left) and 2/6 (right), ledge kinds {4, 0x14, 0x2d}/{7, 0x13, 0x2f} with the dy tests; gate `0738 == 0`, not
  rope, no-cling 0; first cling frame → jump counter 0 + snd 455 (3D-rand); pull-up start `(y+59−4) − (Y+16) < 1` with
  empty cell above (snd 416 vol 0xab), 20 frames, then x ±0x2000, y −0x1600, crouch 2, `+0xce = 1`; occupied above → y
  += 1000, vy 0; post-jump guard `04d8` = 2 skips FG resolution; crunch call `.CrunchTile` (triggers-background-2 §2.3
  — the tile change itself is in this task: kind 3 collapse via its overlay sprite, kind 1 crack) with the 0.9 bounce
  and cooldown 5. `.CheckGroundCeilingHitEffects @100544d8` (M l. 47885–47954): landing latch; dust sprite **0x4b1** at
  (x+0x18, (y>>8)+0x53) layer 0xb when dry and impact > 0x400 (the Effect class Handle is built here: 6 frames, PICT
  1201); v = impact>>7, < 0x30 → 0, cap 100; stop 414 and 427; **601** prio 0x14 vol 0x3c when v == 0 ∧ impact > 700 ∧
  dry; **600** prio 0x14 vol 2v+0x14 when v > 0 ∧ dry; ceiling **404** prio 0x14 vol 0xa0 once per latch. Cues are
  recorded as `PlayerCue` values (S1 turns them into `SoundCue`s).
- **Tests (9; probe A `jumpcycle.out`):** `testFullJumpLandsFrame24` (impact 4564 → v 35 → 601, dust) ·
  `testTapJumpLandsFrame15` (impact 2804 → 601, dust) · `testHardLandingVolumes` (6400 → 600 vol 120; 20000 → vol 220) ·
  `testClingOnKind0` (climb 1, F 1, counter 0, 455, v = 0) · `testLedgePullUp` (20 frames, then ∓32 px x, −22 px y,
  crouch 2) · `testPostJumpGuardSkipsFG` (off on the jump frame and the next, on after) · `testHeadBonkOncePerAirtime`
  (404 once until the latch clears) · `testHeadBumpZeroesJumpCounter` · `testCrunchKind3Collapses` (level 1 cols
  119..121 row 36: the reading's frame count and resulting tile, self-derived from triggers-background-2 §2.3 and the
  dump, recorded).
- **Commit:** `FerazelCore: player tile callback — landing/ceiling effects, cling, pull-up, crunch tiles, dust sprite; 9 tests`.

#### P3 — minor — Player states and faces (replaces ◇ `PlayerPose`) (→ 157) ◈
- **Files:** `Sources/FerazelCore/Player/{PlayerStates,Breathing}.swift`, delete `Sources/FerazelCore/Player/PlayerPose.swift`,
  `Sources/FerazelCore/Session/FerazelSession.swift`, `Sources/FerazelRender/Frame/FrameRenderer.swift` (player sheet
  list), `Tests/FerazelCoreTests/{PlayerStateTests,SessionTests}.swift`, `Tests/FerazelRenderTests/FrameGoldenTests.swift` (◈).
- **Contract:** state selection M l. 45220–46196, first match wins (digest A §2): dying, hurt-stun, rope (W3 hooks it),
  swim, cling/climb/pull-up, grounded (crouch, walk/run with footsteps, stand/turn/uphill 1004, fidget), airborne (air
  counter buckets, spin 1025, tumble 1015 only from its later-phase writers); glider/spirit/boss-grab/door/melee as
  never-taken stubs. Faces per digest A §2.3 (1003, 1004, 1010, 1011, 1012, 1013, 1020, 1022 150×120, 1023 120×120,
  1024, 1025, 1027, 1028, 1029, 1030, 1016/1017). **The jump frame is drawn grounded** (`0738` latched before
  `.HandleKeys`). `.HandleBreathing` (physics-sprites §8.8, M l. 43367: calm breathing **holds at chest frame 1**),
  invulnerability blink `+0xb8 = 0x10006` on parity frames while `+0x116 ≥ 15` and not stunned (0x10009 if > 60), draw
  offsets row 36, facing `+0x17e = (F ≠ 2) XOR turn`. Footsteps: phase 6/0x16 walk, 6/0x10 run, index += R(2)+1 wrap −4,
  snd 410+i prio 1 vol 0x55/0x78, in liquid 454 3D-rand vol 0x2a. Fidget R(60) on reset. `FrameRenderer` loads every
  player sheet. SessionTests' six Phase-1 tests keep their names; `testWalkCycleFaces`, `testRunCycleFaces`,
  `testTurnSequence` now drive the real player (their face sequences are the binary's and do not change: first walk
  frame 1020[7]); `testPlayerStartPose` unchanged. ◈ `testPanFrameGoldens` changes (the player walks instead of the
  focus stub): new hashes recorded.
- **Tests (10; probe A `jumpfaces.out`):** `testJumpFrameDrawnGrounded` (frame 1 `1003[chest]`; air counter 1..10,
  10, 11 …; faces 1010[0,1,1,2,2,3,3,4,4,4,4,4,…], 1010[5] from frame 18) · `testWalkFootstepFrames` (steps on frames 5
  and 13, then every 8) · `testRunFootstepFrames` (frames 2, 9, 14, 21) · `testTurnFromRest` (1030[0],[1],[2],[1],[0],
  mirror 1,1,1,0,0) · `testFirstFidgetAt150` (frame 150 1029[0]; m 8 → [2]; m 107 → [5]; m 156 → idle 0, fidgets 1) ·
  `testSecondFidgetSet` (fidgets 3: 1028[(m mod 20)>>1]; m 241 → idle −R(60)) · `testHurtStunFaces` (1013 0,1,2,3,3,
  3,3,3,2,1 then 0) · `testDyingFacesAndEnd` (1022[c/3] for c < 30, [9] after; game-over flag on frame 80, 100 if died
  in liquid; hot rect drift ±2 from c 9) · `testBreathingCalmHoldsAtChest1` (E 0 → period 7, phase 3→4→5, holds) ·
  `testInvulBlinkParity`.
- **Commit:** `FerazelCore: player states and faces (HandlePlayerSprite state selection), breathing, footsteps; PlayerPose stub removed; 10 tests`.

#### P4 — minor — Liquids, hazards, breath, death (→ 167)
- **Files:** `Sources/FerazelCore/Player/PlayerLiquids.swift`, `Sources/FerazelCore/Physics/{UnderWater,Flotation}.swift`,
  `Sources/FerazelCore/Player/Player.swift`; `Tests/FerazelCoreTests/LiquidHazardTests.swift`.
- **Contract:** `.HandleUnderWater @10042e30` (M l. 38125–38221; liquid = BG 200..209, `.IsWaterTile` l. 38223;
  surface = top of the consecutive liquid column above; `+0x11c = surfaceY − y − inset` ≥ 1, inset = the face's
  first i16 [MED]; `+0x128`; entry splash hook (E1); quicksand kind 5 path built as read though unused on L1/L2;
  flotation if `+0x19e`; `+0x140`). `.HandleFlotation` (M l. 38075–38123: f64 0.93 / 0.86 at `0x100a17f0/f8`, settle
  `|vy| < 0x46`). Player: liquid counter (third frame), kinds 1/2 (and 0 on `0x26cd` levels) HP −0x70 if HP > 4,
  invul 60, flash 13, cooldown 35, snd 407; kind 3 heals breath +8, HP +4, magic +4, snd 803 only-if-idle, stopped
  when nothing heals; near-surface band `0 < +0x120 ≤ 0x15`; swim state entry/stroke (stroke impulse `J − 0x640 −
  ((|vx|+200)>>3)`, ×0.8, halved/quartered rules, cap 2000, snd 497); breath while bubbling −1 (−8 kind 5), drowning
  countdown 30 (15) → HP −0x70, invul 0x28, snd 443; refill +8 to HP; bubble timer `R(0x96)+200` → `.EmitBubble`
  (sprite 0x410, snd 415, Effect class) ; material-2 surface (`+0xd8 == 2`, M l. 45106–45123): damage hdr 0x270e (0
  → 0x70), stun 1, snd 450, invul 60, flash 18; below the map `y > h·32 + 100` → HP 0; death trigger (HP < 1, not dying,
  not stunned) → snd 417, dying; dying ends → `G` game-over flag (`DAT_100a5106`) for W4.
- **Tests (10; probes A `breath.out`, `misc.out`, B `probe_liquids.out`):** `testLiquidCensusLevels1And2` (L1 kind 0
  268 / kind 1 24; L2 433 / 114 / kind 3 12) · `testSurfaceRowWalk` (L2 raft pool: hit row 18 → surfaceY 544) ·
  `testDrownFromFullBreath` (hits on frames 590, 660, 730, 800, 870; trigger 870) · `testBreathRefill` ·
  `testDamagingSurface203` (hits 1, 61, 121, 181, 241; trigger 250) · `testAcidFromThirdFrame` (frames 1–2 none, −112
  on 3, invul 60, cooldown 35, flash 13; HP 4 → none) · `testHealingPool` · `testSwimStrokeImpulse` (at rest −1625 ×0.8
  → −1300) · `testSubmergedBrake` (vy 2000 → 1800 then +80) · `testBelowMapKills` (L1: y > 1700 → HP 0, trigger next
  frame).
- **Commit:** `FerazelCore: liquids (HandleUnderWater, flotation), acid/heal/drowning, damaging surfaces, below-map death, death trigger; 10 tests`.

#### P5 — minor — `.PlayerScroll` (replaces ◇ `CameraFocusDriver`) (→ 175) ◈
- **Files:** `Sources/FerazelCore/Camera/{PlayerScroll,Camera}.swift`, delete `Sources/FerazelCore/Camera/CameraFocusDriver.swift`,
  `Sources/FerazelCore/Session/FerazelSession.swift`, `Sources/FerazelCore/Player/Player.swift` (look-ahead rows);
  `Tests/FerazelCoreTests/{PlayerScrollTests,SessionTests}.swift`, `Tests/FerazelRenderTests/FrameGoldenTests.swift` (◈).
- **Contract:** digest C §1 (raw `1004c528..1004c808`, M l. 43754–43851): focusX = playerX + (L >> 8) (srawi); band
  (scrollV+16, scrollH, scrollV+288, scrollH+608), `PtInRect`; path A freeze, path B exact follow, path C ease (down
  `max(Δ/6, 6)`; up `max((focus − groundY)/7, 5)` — divides by the distance to **groundY**); latch `DAT_100a5f58`
  (1 at ClearPlayerVars), easing `_DAT_100a06dc`, groundY `_DAT_100a0740` written when on ground/riding/clinging.
  Look-ahead L (M l. 46393–46421): ±vx>>2 (doubled when reversing), cap ±0x5000, decay ∓0x200 only against F with
  `snapArmed = 0`, overshoot kept. `Camera` takes `snapArmed` and the riding/water snap vetoes. `testCameraStartScroll`
  keeps (0, 0) and v 10 on the 24th call (regression; R5 measured). ◈ `testPanFrameGoldens` re-derived again if P3
  merged first (the camera now follows the walking player).
- **Tests (8; digest C §1.5 hand arithmetic):** `testGroundedExactFollow` (PS1) · `testJumpFreeze` (PS2) ·
  `testFallEaseDown` (PS3: 208, 214, then 228) · `testLandHigherEaseUp` (PS4: 202, 195, 189, 184, 179, 174, 169, 164,
  159, 154, 150) · `testOutOfBandSnaps` (PS5: 300) · `testLookAheadWalkCapsAt80` (LA1: +1, +18 at n 10, +79 at 43, +80
  at 44) · `testLookAheadReversal` (LA3: L 530 at frame 21, −420 at 22, −895 → −4 at 23) · `testLookAheadDecayOvershoot`
  (LA4 0x300 → 0x100 → −0x100 stays; LA5 no decay with the facing).
- **Commit:** `FerazelCore: PlayerScroll (freeze/follow/ease, look-ahead) replaces the Phase-1 focus driver; camera snap vetoes; 8 tests`.

### Wave 2.2 — the world (lanes: W1 ∥ W2 ∥ W3 after P2; W4 after W1–W3)

#### W1 — ⚑ MAJOR — Platform class, radial geometry, chain spokes, siblings (→ 183) ◈
- **Files:** `Sources/FerazelCore/World/Movers/{Radial,PlatformSprite,ChainSprite}.swift`,
  `Sources/FerazelCore/Sprites/SetupFaces.swift` (platform Setups hand over to the class), `Sources/FerazelCore/Player/HitPlayerSprite.swift`
  (Platform arm), `Sources/FerazelRender/Frame/FrameRenderer.swift` (sheets 0x578, 0x2c7, 0x599, 0x59b, 0x582 …);
  `Tests/FerazelCoreTests/PlatformTests.swift`, `Tests/FerazelRenderTests/FrameGoldenTests.swift` (◈).
- **Contract:** physics-sprites §8.9, platforms-ropes-radial §1–§2, -2 §8–§9, digest B §2.2. `.SetupPlatformSprite
  @10061f94` (layer −1, `+0xc0 = 0` → **frame 1 draws no platform**, one-way, sag 0x50, `+0xa6 = 1`), first handler
  `.DoSetupPlatformSprite @10062098` (mode p1, face set 0x578 + (type − 0x578)·0x34, rect (0x10,6,0x3d,0x1e)),
  `.HandlePlatformSprite @100635b4` every mode (1/2 shuttles **without a clamp after the step** — raw `10063754..1006376c`,
  `10063790..100637ac`; mode-2 vertical spring-back; 3 raft (flotation, gravity 0x15e only when last frame dry, tilt
  toward the rider ±2/frame, `+0x89` dynamic light); 10/11/13 radial (`.UpdateRadialPos`, pendulum g); 20 three-wheel
  with two siblings at the list tail, damp 0xf7, driver slaves angle/speed/hub position; 4–8, 30, 50–52, catapult and
  springboard transcribed as read though not on L1/L2), `.HitPlatformSprite`, `.HitPlatformTileSprite` (+
  `.BounceRadial` once per frame, cooldown −5 on self + siblings; the `+0x1d4` sibling write bug kept). Radial tables
  `cosT[i] = (int)(float)(256·cos θ·256)`, `sinT[i] = −(int)(float)(256·sin θ·256)`, θ = 2π·i/360, **π = 3.1415926535**;
  first-handler centre not pre-computed (MED quirk kept). Chain spokes 0x596 (`.SetupChainSprite @100652c0`, layer −2,
  face 0x599[angle/6], spoke k at (n−1−k)/n of the radius), created in the platform's first handler. Platform arm of
  `.HitPlayerSprite` (M l. 49123–49149) + spiked underside 0x57d. ◈ `testFirstFrameGoldenLevel1` (+ highest) change:
  the binary draws no platform on frame 1 (Phase 1 drew Setup faces); new hashes recorded.
- **Tests (8; probe B `probe_platforms.out`, `probe_radial.out`):** `testRadialTablesMatchBinary` (cosT[0] 65536,
  cosT[1] 65526, cosT[60] 32768, sinT[90] −65536) · `testShuttleL1Rec25` (x 297, 302, 307; range 284..599; period 158) ·
  `testShuttleNoClampOvershoot` (L2 rec 3: vy reaches −1471) · `testMode2SpringBackTrace` ((320,160), (480,−128),
  (352,−192), (160,−192), (0,−192)) · `testMode10RotorL1Rec57` (frames 2..4 at (2349,1033), (2349,1031), (2349,1029);
  0x16800/500 = 184.3 frames per turn) · `testMode11PendulumL1Rec14` (speed −30, −60, −90; sign changes on frames 78,
  157) · `testWheelRiddenStep` (driver speed −87, angle 92073, hub vx 86; sibling S1 angle 30549) ·
  `testSpokeAndSiblingCounts` (L1 35 spokes + 2 siblings; L2 40 + 4; spokes at layer −2 before every platform).
- **Commit:** `FerazelCore: Platform class (all modes), radial geometry, chain spokes, wheel siblings; frame 1 draws no platform (golden ◈); 8 tests`.

#### W2 — ⚑ MAJOR — Background movers: 1480–1489, cannons, tunnels, passages, springs, re-faces (→ 191)
- **Files:** `Sources/FerazelCore/World/Movers/BackgroundSprite.swift`, `Sources/FerazelCore/Sprites/SetupFaces.swift`,
  `Sources/FerazelCore/Player/HitPlayerSprite.swift` (Background arm), `Sources/FerazelRender/Frame/FrameRenderer.swift`
  (sheets 1480–1489, 1434, 3000+, 2700+); `Tests/FerazelCoreTests/BackgroundMoverTests.swift`.
- **Contract:** triggers-background §2.2/§2.3/§2.5/§2.11, -2 §8.2, digest B §2.3, §2.6, §2.7. `.SetupBackgroundSprite`
  (M l. 62312–62420; record p2 0 → 140, p3 0 → 30 **written back**; modes 10..14; spokes 0x59a `p2/16`) and
  `.HandleBackgroundSprite` (M l. 63136–63186; **face re-set every frame from the cache** — resolves the Phase-1
  placeholders of 1485, 2710, 2713, 2714, 3002; mode 12 harmful **iff 0x60 ≤ D < 0x80** (raw `100743a4..100743bc`),
  layer 0x7ef4 in front / −300 behind through the F2 guard → **double-handled frame**); spokes 0x59a (`.HandleChainSprite`
  M l. 55990–56005: layer = scale − 0x100 every frame). Pendulum hit (M l. 49583–49592): `HurtPlayer(…, 0xe0, blood,
  invul 0x3c, coins 5)` then `+0x116 = 0x1e` — `.HurtPlayer` built here (knockback, stun, blood spray hook for E1,
  snd per S1, coins recorded in `PlayerState.coinsLost`, not spawned). Cannons 1090–1098 (speed 9000 for p1 0, M l.
  62114; `.HitBackgroundSprite` → `.TurnIntoCannoned` M l. 49930; `.HandleCannonedSprite` M l. 49976: hold 15, fire
  when aim mod 4 == 0, v (0, −9000) for aim 0, `+0x130 = −5`, `_DAT_100a05b8 = 1`, recoil, snd 484/483; smoke =
  Effect sprites with their FastRand draws). Wall tunnel 3000–3009 (occluder window M l. 63730–63740, never reset).
  Springs 1150–1153 (`.SuperSpring` M l. 63564, cooldown, snd 493). Passages 2900/2901 (`.HitPlayerSprite` M l.
  49594–49690, triggers-background-2 §8.2 timeline: UP on first contact, 20-step gamma fade-out, 22 frozen frames,
  move to the partner keeping the offset, camera snap + 90 `.FindUpperLeftCorner` passes, fade-in, walk-out faces
  1030/1033) — emits `DrawOp.gammaStep` (E2 executes it).
- **Tests (8; probe B `probe_1485.out`):** `testPendulumHarmfulBand` · `testPendulumL1HarmfulFrames` (rec 16: 37–39,
  106–109; rec 44: 32–35, 110–112) · `testPendulumDoubleHandleFrames` (rec 16: 37, 184; rec 44: 1, 110, 257) ·
  `testPendulumRecordDefaults` (p2 0 → 140, p3 0 → 30 written back; L1 recs keep r 120, g 30) ·
  `testPendulumHitCosts224And5Coins` (HP −224, `+0x116` 30 after) · `testCannonP0LaunchUp` (v (0, −9000) after 15 hold
  frames; `+0x130` −5) · `testWallTunnelWindowL1` (x 4441..4556, y 1011..1254) · `testPassagePairsLevel2` (43↔44,
  166↔167, 171↔172; partner position keeps the offset; 20 fade steps + 22 frozen frames).
- **Commit:** `FerazelCore: Background movers — radial bars/balls (harmful band, double-handled frame), cannons, wall tunnels, passages, springs, HurtPlayer; 8 tests`.

#### W3 — minor — Box solids, trampoline, pushing, ropes (→ 199)
- **Files:** `Sources/FerazelCore/World/Movers/{BoxSprite,RopeSprite}.swift`, `Sources/FerazelCore/Sprites/SetupFaces.swift`,
  `Sources/FerazelCore/Player/{HitPlayerSprite,Player}.swift` (Box arm, `.RopeCollide` hook); `Tests/FerazelCoreTests/BoxRopeTests.swift`.
- **Contract:** pickups-boxes §2.1–§2.2, digest B §2.4–§2.5, physics-sprites §8.2, platforms-ropes-radial §3.
  `.SetupBoxSprite` rects/one-way/layers for every Box type on L1/L2 (digest B §2.5 table; mechanisms deferred) and
  the common `.HandleBoxSprite` tail (friction, `.FootPressure`, `EnforceMaxSpeed(0x1838)`,
  `.ApplyGravityAndSeparateFromTiles`, `BoxCleanUp`) so crates 3090/3092 (mass 0x78, friction 0x5a, gravity 0x100) and
  the boulder 1070 (mass 0x8c, friction 0x46) push, fall and roll; the Box arm of `.HitPlayerSprite` (M l.
  49308–49362) up to the mechanism branches; trampoline 1470 (`+0x46 = 1` per landing; entry vy ≥ 0xa5b → vy =
  max(−6500, −(vy + 0.6·g)), snd 604, air counter 1, `+0xce = 0`; face squash 1, 2, 3, 0). Ropes 3020–3022 complete
  (`.SetupRopeSprite` M l. 71078, seg array, `.GetRopeHeight`, `.HandleRopeSprite` M l. 71506, `.RopeCollide` M l. 43863
  from the player, idle callbacks, segments type 600, creak cues) and the rope state of P3's selection.
- **Tests (8):** `testBridgeIsTwoWaySolid` (1461/1464 `+0x185` 0; rects (6,0,0x9e,0x18) / (8,0,0x8c,0x28)) ·
  `testTrampolineBounce` (entry 4096, g 440 → −4360; 2650 → stands; 7000 → −6500) · `testTrampolineFaceSquash` (1, 2, 3,
  0; held at 1 while stood on) · `testSignStandableOnlyWith15c` · `testCratePushedBySideContact` (F 0x80, mass 0x78,
  Δvx 0x400 → +240) · `testRopeSagCentre3022` (span 240: rest sag 0xc00, 10 segments) · `testRopeGrabWindow`
  (`surf ≤ y+16 < surf+0x40`, previous above) · `testReversedRopeIsDead` (L3 rec 145, span −173: no segments).
- **Commit:** `FerazelCore: Box solids + push/fall tail, trampoline, ropes; 8 tests`.

#### W4 — minor — Level 2 Setups, level flow, restart (→ 205)
- **Files:** `Sources/FerazelCore/Sprites/SetupFaces.swift`, `Sources/FerazelCore/Flow/LevelFlow.swift`,
  `Sources/FerazelCore/Seams/ShellRequest.swift`, `Sources/FerazelCore/Session/FerazelSession.swift`,
  `Sources/FerazelRender/Frame/FrameRenderer.swift` (L2 sheets); `Tests/FerazelCoreTests/LevelFlowTests.swift`.
- **Contract:** the 21 level-2 types Phase 1 never transcribed (probe B `probe_l2_newtypes.out`: 1056, 1058, 1070,
  1332, 1341, 1408, 1461, 1462, 1470, 1740, 1800, 2848, 2849, 2900, 2911, 2925, 2926, 2928, 2932, 2954, 3205) get their
  Setup faces/fields (movers already handed to W1–W3; enemies/Bonus `inert`, R4's rules incl. sheet CLUTs). Exit 3249
  (`.HitPlayerSprite` M l. 49733–49741: snd 421, exit = p1) → `LevelFlow.next` (`Mmap 200` node `links[exit]`; p1 −1 →
  no level) → `ShellRequest.loadLevel(next)`. Game-over flag (P4) → `ShellRequest.deathEffect` then, when the shell
  reports the wipe done, `loadLevel(current)` with fresh `G` (◇, Ben D33). Music restarts with the level.
- **Tests (6):** `testLevel2SessionBuilds` (212 active records, no throw) · `testLevel2Header` (pattern 509 period 6,
  music 3, start (901, 256), chapter 0) · `testLevel1ExitLeadsTo2` (rec 66 p1 0 → node 1 link 0 → 2) ·
  `testLevel2ExitsUnlock` (p1 −1 → nil, 1 → 3, 2 → 4) · `testDeathRequestsWipeThenRestart` · `testRestartFreshGlobals`
  (HP 560, magic 560, breath 560, start position).
- **Commit:** `FerazelCore: level-2 Setups, exit → next level and death → restart (Phase-2 stubs, D33); 6 tests`.

### Wave 2.3 — effects and sound (E2 and S2 may start in wave 2.0 lane B: Render-only)

#### E1 — ⚑ MAJOR — Particles, splash, water effects (→ 213) ◈
- **Files:** `Sources/FerazelCore/Particles/{ParticlePool,ParticleLife,Splash,BloodSpray,WaterEffects}.swift`,
  `Sources/FerazelCore/Seams/{DrawOp,ParticleDraw,WaterFaceDraw}.swift`, `Sources/FerazelCore/Session/FerazelSession.swift`,
  `Sources/FerazelRender/Effects/{ParticleRenderer,WaterFaceBlitter}.swift`, `Sources/FerazelRender/Frame/FrameRenderer.swift`;
  `Tests/FerazelCoreTests/ParticleTests.swift`, `Tests/FerazelRenderTests/{ParticleRenderTests,FrameGoldenTests}.swift` (◈).
- **Contract:** particles §1–§5, digest C §2. Pool 2000 × 32 B; `.NewParticle @10031e68` (scan from hint, hint = i,
  count +1, hwm max); `.HandleParticles @10031828` (motion, age > 120 kill, hint = min(hint, i), hwm −1 only when
  i == hwm); colour-0 kill in `.DrawParticles` counts −2 and happens **only on drawn iterations**; `ParticleLife` zero
  table in Core, Render cross-checks it against its resolved rows. `.Splash(s, 3/4) @10042874` (sound gate, columns
  x+left−4 … x+right+3, R(500), R(200), R(1) per column, three particles each — player 96); `.BloodSpray @100549f4`
  (40 particles). `.FillCachedTileArray @10010d30` (11 ints × 21 × 14) and `.WrapDrawWaterEffects @10011258` emission
  (bubbles for BG kinds 201–204 with the row-vs-pixel gate quirk [MED], current motes for 200/203/205 with
  vx = current ± (R(|c|/2) − |c|/4), wind dust) and its **Enhanced water-face draw** (Effects == 1, parity frames,
  hdr 0x26c6 == 0, mode 0x60000 + waterKind) via `WaterFaceDraw`. Seams S3. ◈ level-1 goldens change (motes, acid
  bubbles, water faces on parity frames): new hashes recorded.
- **Tests (8):** `testAllocationHint` (slots 0,1,2; hint 2, count 3, hwm 2; kill 1 → hint 1, count 2; kill 2 → hwm 1)
  · `testColourKillCountsTwice` · `testSkippedDrawNoColourKill` · `testParticleMotion` (NewParticle(200, 150, (100, 50),
  2, −154, −502, 0, 1): x 12646, y 25098, vy −352, age 1; drawn at (49, 98)) · `testSplashLevel1` (seed 1, vx 0x200,
  vy 0x800: 96 particles; first column vx −154, vy0 −902) · `testMoteVelocityLevel1` (550 ± 137, kind −210, shape 7) ·
  `testLifeTableMatchesRows` (Render: Core zeros == resolved rows on all 16 level CLUTs, lowest; highest differs only on
  CLUT 222) · `testWaterFaceParity` (Effects 1: water faces on alternate drawn frames only).
- **Commit:** `Particles: pool, splash, blood spray, water effects (motes, bubbles, Enhanced water faces); DrawOp particle/water cases; 8 tests`.

#### E2 — ⚑ MAJOR — Draw additions: hurt flash, water split, scale, rotation, occluder, death wipe, gamma (→ 221)
- **Files:** `Sources/FerazelRender/Frame/SpriteBlitter.swift`, `Sources/FerazelRender/Effects/{DeathEffect,ScreenGamma}.swift`,
  `Sources/FerazelRender/Frame/FrameRenderer.swift`, `Sources/FerazelCore/Seams/{SpriteDraw,DrawOp}.swift`,
  `Sources/FerazelCore/Sprites/{SpriteSlot,ActiveList}.swift` (fields → `SpriteDraw`); `Tests/FerazelRenderTests/DrawEffectTests.swift`.
- **Contract:** draw-effects §1.1 steps 3–5, §2 (modes 3/4 hurt flash through `+0xaa`/`+0x1b4`, mode 6 + the water split
  at `+0x11c`, mode 9, mode 0xc with scale, `.BlitEncFaceScale`, `.BlitEncFaceRot`), the occluder clip
  (`.StandardSpriteCleanup` M l. 32669–32700), `wrapEraseSprites` for rotated/scaled/split sprites (lifts R4's
  refusals for these modes only; 0xa, 0xb, 0xd, 0xe stay refused by name). `.DeathEffect @10005270` (50 steps,
  i += 4 to 200, four 4-px rects closing in over 16..624 × 8..392 with pattern `qd+0xba`, `GammaFadeOutAsync(0x30)`).
  `ScreenGamma` (lighting-tables §10) applied to the CLUT in `IndexedFrame.rgba(through:)` — presentation only, like the
  app's MacGamma.
- **Tests (8; draw-effects goldens self-derived and recorded):** `testFullySubmergedDrawsMode6` (`+0x11c` 1 → one draw
  0x60000 + kind) · `testPartialWaterSplit` (`+0x11c` 20 → rows 0..19 mode m, rest ripple) · `testHurtFlashTables`
  (`+0xaa` 13 → tables 7,7,7,7,7,7,7,6,5,4,3,2,1) · `testScaledFace` (1485 at scale 149 and 254: footprint and FNV) ·
  `testRotatedFace` (raft tilt ±n°: FNV) · `testOccluderClipsFace` · `testDeathEffectSteps` (50 steps; step k rects
  at 8+4k / 392−4k / 16+4k / 624−4k; last at 196) · `testGammaStepScalesCLUT`.
- **Commit:** `FerazelRender: hurt flash, water split/ripple, scale, rotation, occluder clip, DeathEffect wipe, screen gamma steps; 8 tests`.

#### S1 — minor — Sound cues in Core (→ 228)
- **Files:** `Sources/FerazelCore/Sound/{SoundCues,StereoVolume,SoundSlots}.swift`, `Sources/FerazelCore/Seams/{SoundCue,FrameOps}.swift`,
  `Sources/FerazelCore/Session/FerazelSession.swift`; `Tests/FerazelCoreTests/SoundCueTests.swift`.
- **Contract:** digest C §4.2–§4.4 (M l. 40605–41010). Global volume prefs+0xe·0x1c (7 → 196). `.STPlayRegSound`:
  each side ((vol·196)>>8)>>1; `…Pitched`: not halved, rate given; `.STPlay3DSound`: `CalcStereoVolume` then halved;
  `…3DSoundPitched`: not halved, pos (0,0) → 0x80/0x80, dropped if L+R < 0x14; `…3DSoundRand`: rate R(10000) + 0xec77,
  **R drawn before the sound-on gate**. `CalcStereoVolume @10047738`: ears (scrollH+200, scrollV+192) and (scrollH+408,
  scrollV+192), `PEDistance` = max + min/3, g = d ≤ 1024 ? (1024 − d)>>3 : 0, spread s = 2|L−R| + (2|L−R|>>1), clamp
  0..256. Sound off (prefs+0xb 0) → no cue. Every `PlayerCue`/mover cue of P1–W4 becomes a `SoundCue` at its call
  site, in call order; stops (`FUN_10091504`) → `FrameOps.soundStops`; only-if-idle (`FUN_100916dc`) → `onlyIfIdle`.
- **Tests (7; digest C §4.5):** `testJumpCue` (414, prio 1, 59/59, 0x10000) · `testLandingCues` (impact 0x2000 → 600
  prio 20 56/56; 0x1000 → 601 22/22; 0x2b0 → none) · `testFootstepVolumes` (walk 32/32, run 45/45) ·
  `testStereoCentre` (view centre vol 0x100: 3D 88/88, Pitched 176/176) · `testStereoLeftEar` (128/18) ·
  `test3DRandConsumesWhenSoundOff` · `testHurtSmallCues` (508 at 0x97 → 115/115 rate 65000 + R(10000); then 401/402/403
  by R(3) at 0xab → 65/65).
- **Commit:** `FerazelCore: Sound Tool cue arithmetic (Reg/Pitched/3D/Rand, CalcStereoVolume), cues at every Phase-2 call site, stops and only-if-idle; 7 tests`.

#### S2 — ⚑ MAJOR — The Sound Tool mixer (FerazelRender) (→ 233)
- **Files:** `Sources/FerazelRender/Sound/SoundTool.swift`; `Tests/FerazelRenderTests/SoundToolTests.swift`.
- **Contract:** digest C §4.1 (`ST_Open(8, 1, 22050)` M l. 8282; play list `FUN_10091208` M l. 78231–78325; stereo mix
  `FUN_10091ddc` M l. 78660–78710): **16-entry priority list, only the first 8 mixed**; insert rule (priority 0 → 1;
  clamp L/R to 0x80; skip entries with higher priority or louder L+R; insert, shift, 16th drops; full and unbeaten →
  dropped); per output sample signed 8-bit × vol >> 7 per side, summed, **clipped ±127**, 8-bit offset stereo at 22050
  Hz; 16.16 step = FixMul(FixDiv(sndRate, 22050), rate) with the 2-tap average when the source did not advance;
  `stop(snd)`, `isPlaying(snd)`. Conforms to `PCMPullSource` (HectorAudio) delivering the kit's sample format; reads
  PCM from `SoundBank` (no re-decode). Thread-safe the way BTX's K3 lesson requires (no real-time crash smokes in
  review — memory).
- **Tests (5):** `testEightAudible` (9th entry silent until one ends) · `testInsertRule` (equal priority louder goes
  first; lower appended; 17th dropped) · `testUnityAndClip` (0x80 passes samples unchanged; two full-scale voices clip
  at ±127) · `testPitchStep` (22050 Hz at 0x10000 → step 1.0; 11025 Hz → 0.5 with the 2-tap average) ·
  `testStopAndOnlyIfIdle`.
- **Commit:** `FerazelRender: Sound Tool mixer — 16-entry list, 8 audible, insert rule, ±127 clip, 22050 Hz, PCMPullSource; 5 tests`.

### Wave 2.4 — goldens, app, stage

#### G1 — minor — Phase 2 goldens (→ 237)
- **Files:** `Tests/FerazelRenderTests/Phase2GoldenTests.swift`.
- **Contract:** scripted input files are not added; each test builds its key script inline. All NEW measurements
  (self-derived, `.ruled`, error diffusion, tie-break lowest, seed 1), recorded on first green, re-run twice by the
  reviewer.
- **Tests (4):** `testLevel2FirstFrameGolden` · `testLevel1JumpAndLandGolden` (stand 10, jump held 6, 30 frames: FNV
  of frame hashes + final player (x, y)) · `testLevel1SwimGolden` (walk right into the first water body, cols 56..81
  row 19: frame-hash FNV, entry splash count 96) · `testLevel1ScriptedPlayGolden` (600 frames of a fixed walk/run/jump
  script: hash of frame hashes, cue list hash, final state).
- **Commit:** `FerazelRender: Phase 2 goldens (level 2 frame 1, jump, swim, 600-frame scripted play); 4 tests`.

#### A3 — ⚑ MAJOR — App: original keys, sound, level switch, restart
- **Files:** `Ferazel/App/{FerazelController,FerazelAudio}.swift`.
- **Contract:** keys = `FerazelPrefs.keys` only (keypad 4/6/8/5, Shift, Option, ⌘, keypad 7/9; Phase 1's arrows gone
  with `CameraFocusDriver`); right Shift/Option/⌘ fold as before. `SoundTool` attached with `ShellMixer.attachStream`
  beside the music voice; `ops.sounds` in order, `ops.soundStops`, `onlyIfIdle` against the mixer; prefs sound volume 7.
  `ShellRequest.loadLevel(n)` → stop sounds, rebuild session (seed continues from the stream — the original never
  reseeds) + renderer + lights, prepare + play music. `.deathEffect` → run `DeathEffect` steps 0..49 at ≥ 1 tick each,
  then tell the session (W4). `FerazelLevel` (`UserDefaults` / `-FerazelLevel N`, 1 when absent or outside the 24
  shipped levels) — Ben D33. Seed = `FastRand.clockSeed` at launch. ⌘Q/⌘W keep their menu meaning [LOW, gate card].
  Debug alert unchanged.
- **Gate:** G5 (Ferazel). **Commit:** `Ferazel app: original keys only, Sound Tool effects, level switching (exit, FerazelLevel), death wipe + restart`.

#### A4 — minor — Stage + WHAT-TO-EXPECT + the Phase 2 gate card
- **Files:** `Ferazel/WHAT-TO-EXPECT.md` (rewritten for Phase 2; fixes the stale "MacGamma not built" lines),
  `tools/stage-ferazel.sh` (only if needed).
- **Gate:** G1, G2 = 237/0, G3, G5, G9. **STOP for Ben.** **Commit:** `WHAT-TO-EXPECT: Phase 2 gate card (feel on levels 1–2)`.

---

## What Ben checks — the Phase 2 gate card ("feel on levels 1–2")

Play levels 1 and 2 with the keypad (4/6 walk, 8 up/climb, 5 down/crouch, Shift run, Option jump), side by side with
the Let's Play (https://www.youtube.com/watch?v=ESuyxMUEzDw) and longplays. `-FerazelLevel 2` starts on level 2.
1. **Walk and run** — speed, how fast he gets going and stops. Built as the binary: **right reaches full walking speed in
   4 frames, left in 8** (an extra push only to the right, raw `100539a4`), and running right overshoots for one frame.
   Wrong would look like: left and right feeling the same, or a slide when you let go.
2. **Jump** — height (full jump ≈ 100 px, tap ≈ 44 px), hang time, landing (≈ 0.8 s for a full jump at 30 Hz). No
   coyote time, no jump buffer, no repeat when Option is held. The take-off frame still shows him standing.
3. **Spin (5 + Option)** — only from the ground, a wall or the water; it does not extend a jump in mid-air (the bank
   said it did; the binary says no).
4. **Walls** — clinging, climbing (8/5), wall jump, pulling up over a ledge.
5. **Slopes, ledges, one-way ledges** — walking up/down slopes (right climbs faster than left), dropping through
   nothing, landing on one-way ledges from above only.
6. **Camera** — while jumping from flat ground the view does not follow upward; falling below where you stood eases down;
   landing higher eases up; it looks up to 80 px ahead in the direction you walk and keeps that when you stop.
7. **Water** (level 1 has five pools, the first at x ≈ 1800–2600) — splash on entry and exit, swimming strokes, the
   drift of the current (level 1 only), bubbles, breath running out: hits every ~2.3 s once breath is gone.
8. **Acid and the damaging floor** (level 1: the acid pool at the far right, 18 damaging floor cells; level 2: four
   acid pools, 74 cells) — hurt flash, a groan/ouch, the knock-back stun.
9. **Healing brine** (level 2, 12 cells) — health and magic fill with the "fill-up" sound.
10. **Platforms** — sliding platforms (one on level 1 dips when you land on it and springs back), the rotor pair and the
    pendulum platform near x 2300 / 3200, the three-wheel near x 1850; on level 2 the rafts float and tilt under you,
    and the wheels turn when you ride them. Note: a platform never shows on the very first frame (the original's).
11. **Spiked pendulums** (level 1, x ≈ 2660 and 2760) — they hurt only in a narrow band just in front of the bottom of
    the swing (follow the binary; the bank had the band reversed). Coins you would lose are not dropped yet (Phase 4).
12. **Cannons** (level 1, three) — climb in, get fired straight up.
13. **Crates, the boulder (level 2), trampolines (level 2), bridges** — push, fall, bounce.
14. **Passages (level 2, three pairs)** — press 8 at one: fade out, come out at the partner, fade in.
15. **Death** — the dying animation, the border wipe, then the level restarts (stand-in for Phase 3's menu).
16. **Level 1 → 2** — touching the exit loads level 2 at once (stand-in for Phase 3's stats screen + world map).
17. **Sound** — footsteps, jump, landings (soft/hard), head bonk, splash, swim, groan/ouch, drown choke, fill-up, cannon,
    trampoline, passages. 8 voices at most, 8-bit at 22,050 Hz like the original's Sound Tool — slightly gritty on
    purpose. Wrong would look like: sounds cut off oddly, wrong side in stereo, too loud/quiet next to the music.
18. **Water look** (MED) — on level 1 the water now shows drifting motes and the acid bubbles, and water-covered ground
    shimmers every other frame (the binary's "Enhanced" water faces; Phase 1 didn't draw them).
19. **Breathing** (MED) — when he has been still a while, his chest stops moving (the binary holds the calm breath at one
    frame).
20. **Coins/Xichrons** spin out of step with each other now (their random start phase is modelled).
Known stand-ins/deviations: enemies stand still and are harmless (Phase 5); pickups, chests, doors, teleporters, save
points, signs and NPCs are only solid (Phases 3–4); Caps Lock / Esc do nothing (Phase 3); ⌘ is the use-item key and also
the Mac's ⌘Q/⌘W (the original asked "are you sure?"); random numbers start from the clock as the original's did, so no
two runs are identical. Ropes and springs are built but there are none on levels 1–2 (first rope level 3, first spring
level 15).

---

## Execution order

| wave | lane A | lane B | review legs (all Opus) |
|---|---|---|---|
| 2.0 | F1 → F2 ⚑ → F3 ⚑ | S2 ⚑ (Render-only), E2 ⚑ after F2's fields | F1 one; F2, F3, S2, E2 two each |
| 2.1 | P1 ⚑ → P2 ⚑ → P3 → P4 | P5 (after P2) | P1, P2 two; P3, P4, P5 one |
| 2.2 | W1 ⚑ | W2 ⚑ ∥ W3 (after P2) | W1, W2 two; W3 one |
| 2.3 | W4 → E1 ⚑ | S1 | W4, S1 one; E1 two |
| 2.4 | G1 → A3 ⚑ → A4 | — | G1, A4 one; A3 two; then Ben |

- Orchestrator sessions are 2–3 tasks (fable-kit §5): suggested sessions **[F1 F2 F3] [S2 E2] [P1 P2] [P3 P4 P5]
  [W1 W2 W3] [W4 E1 S1] [G1 A3 A4]**. Each ends with merge to main, STATE, handoff, chip.
- File overlaps that force order: `FerazelSession.swift` (F1, P3, P5, W4, E1, S1), `FrameRenderer.swift` (P3, W1, W2,
  W4, E1, E2), `SetupFaces.swift` (F1, W1–W4), `HitPlayerSprite.swift` (W1–W4), `SpriteDraw.swift`/`DrawOp.swift`
  (E1, E2). Parallel lanes rebase; the orchestrator merges in the canonical order or adjusts the ladder by N.
- ◈ goldens: P3, P5, W1, E1 (and the ladder's G1 adds new ones). A lane that merges out of order re-derives.

---

## Pre-execution self-audit

1. **Design §8 Phase 2 row coverage.** `.HandlePlayerSprite` in full (P1–P4; later-phase rows stubbed by name) ✅; tile
   collision and `.WallBounce` kinds (F3, P2) ✅; liquids (P4, E1) ✅; ropes (W3, synthetic) ✅; springs (W2, synthetic)
   ✅; platforms (W1) ✅; hazards (P4 surfaces/acid/drowning, W2 pendulums) ✅; health/breath (P4) ✅; landing/splash
   particles (P2 dust sprite, E1 splash) ✅; camera as read (P5) ✅. Gate "feel on levels 1–2": level 2 loads (W4) ✅,
   1 → 2 (W4, A3) ✅. Sound for the movement (S1, S2, A3) ✅.
2. **Phase-1 carries.** Camera look-ahead → P5 ✅; FastRand fidget reset + Setup FastRand calls [MED] → F1, P3 ✅;
   sprite 0x4c4, chapter screen, `_FadeAIFFMusic(1,4)` → Phase 3 (unchanged, front end) ✅; table 0148 / mode 0xb →
   still refused (not on L1/L2) ✅; hidden Mac-gamma toggle → **already built** (b269a02); A4 fixes the stale
   WHAT-TO-EXPECT lines ✅; light-24 table over-light [MED] → not Phase 2 (a render reading; carried in STATE) ✅.
3. **Placeholder scan.** Self-derived numbers are named as such (F1 draw count, P2 crunch frames, E2 face FNVs, all
   goldens) and re-derived by a second run; every other number is a probe or bank figure.
4. **Ladder arithmetic.** 102 + 6 + 8 + 10 + 12 + 9 + 10 + 10 + 8 + 8 + 8 + 8 + 6 + 8 + 8 + 7 + 5 + 4 = 237 ✅ (test
   names counted per task above).
5. **Type-name consistency.** `FastRand`, `SpriteWorld`, `SpriteHandler`, `TileSolver`, `PlayerState`, `Player`,
   `PlayerScroll`, `Radial`, `PlatformSprite`, `ChainSprite`, `BackgroundSprite`, `BoxSprite`, `RopeSprite`,
   `ParticlePool`, `ParticleLife`, `SoundTool`, `LevelFlow`, `DeathEffect`, `ScreenGamma` — each defined once (S2/S4)
   and used with that name. Seam additions only in S3.
6. **Rulings.** Ben's two (level switch, restart) → D33; seat scope rulings → D33; follow-the-binary corrections → the
   bank files below, each by the task that first relies on it.
7. **Risk.** Biggest: P1–P3 are one handler split three ways (state shared through `PlayerState`); the reviewer of P3
   re-runs P1/P2's tests. Second: RNG call order — F1's draw count and E1's splash numbers pin it.

---

## Open questions for Ben

None open. Asked and ruled 2026-10-10 (D33): reaching level 2 (exit loads it + hidden `FerazelLevel` switch); death
(wipe, then restart the level). He also asked whether the world map is being built — yes, Phase 3 (D26 order).

---

## Bank corrections to append (each as a ⚑ planner-probe note in the named file, by the task named)

From digest A §9.1 (player): A1 player-states §2/§5.1, player-states-2 corrections, physics §4 — JUMP gated by shield
raise `PTR_DAT_100a05e8` (raw `10052ae8`, `10053ec8..10053ed0`) (P1). A2 player-states §5.4 — no mid-air spin refill
(raw `10053cec..10053d28` before `10053fc4`) (P1). A3 physics §2 — head bump zeroes the jump counter (raw
`1004b998..1004b9c8`) (F3). A4 player-states §1 — submerged brake (raw `1004daec..1004db10`) (P1). A5 physics §2 —
`.AccelerateBasedOnSlope` ×0.8 tests `+0x11c` only, never fires for the player (M l. 32853) (F3). A6 player-states-2
§9.2 — kinds 4–7 revert to the call's entry position (raw `1003c82c`) (F3). A7 player-states §4 — L/R also needs crouch
depth 0 (M l. 47360) (P1). A8 physics-sprites §8.8 — exertion attribution MED → HIGH (P1). A9 player-states §3 — jump
frame drawn grounded MED → HIGH (P3). A10 world-data §3.2 0x270e — damaging-surface damage, not landing damage (M l.
45106–45123; also `LevelHeader` doc) (F3). A11 physics-sprites §8.8 — calm breathing holds at chest frame 1 (M l.
43367) (P3). A12 physics §3.1 — entry rect not refreshed [MED] (F3). A13 INDEX provenance — `tools/pef.py` needs
`FZ_PEF=ghidra/ferazel/Ferazel_pef` (F1).
From digest B §7.1 (world): B1 physics-sprites §8.9/§8.5 — platform shuttles have no clamp (W1). B2 triggers-background
§2.5 — mode-12 harmful band 0x60 ≤ D < 0x80 (W2). B3 platforms-ropes-radial-2 §8.2 — `.MTChangeSpriteLayer` no-op
guard + double handling (F2). B4 physics §5.1 — liquid census by level (P4). B5 pickups-boxes §2.2 — bridges two-way,
no hit callback (W3). B6 new MED readings: radial first-frame centre, mode-2 dead writes (W1).
From digest C §9: C1 sprites-backgrounds-sounds §6.2 — **8 audible voices** over a 16-entry list, ±127 clip (S2). C2
§6.3 — `…Pitched` not halved; `…3DSoundRand` draws before the gate (S1). C3 engine §5 — the three-path focus-y machine,
up-ease divides by focus − groundY (P5). C4 particles §1.1/§5.1 — hint = min(hint, i); `200 → 199` substitution dead;
row-vs-pixel gate (E1). C5 particles NR 4 closed (E1). C6 R4's Setup FastRand meanings (F1). C7 physics-sprites §8.7 —
landing stops voices 414 and 427 (P2).

---

## Research notes (where every number came from)

All probes ran 2026-10-10 against `Resources/Ferazel` and the committed dumps. Digest A (player): `kinematics.py`,
`jumpcycle.py`, `jumpfaces.out`, `breath.py`, `misc.py`, `fastrand.py`, `level_kinds.py`, `snd_names.py`,
`const-out.txt`. Digest B (world): `probe_levels`, `probe_liquids`, `probe_all`, `probe_platforms`, `probe_radial`,
`probe_1485`, `probe_l2_newtypes`. Digest C (camera/fx): `C_fastrand.py`, `sndmap.py`, `lvlhdr.py`, `water.py`,
`white.py`, `exits.py`, `l2probe/` (a scratch SwiftPM exe on Ferazel/Core: `FerazelSession(level: 2)` throws
`notTranscribed(type: 2848)` today). Level identities: `Mlvl` id = level number; L1 "A Scent Of Peril" 162 active
records / 42 types, L2 "Central Caverns" 212 / 40, both 200×50 cells.

---

## Review ledger

(filled by the review leg)
