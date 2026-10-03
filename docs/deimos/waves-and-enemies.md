# Deimos Rising 1.0.6 — levels, "waves", unit definitions, weapons, scoring

Code readings only; nothing is behaviour-verified. Conventions as in pak-format.md. `$D` =
output dir of `list_paks.py --decode`; decoded text files are `<entry>.txt`.

**Answer up front.** There is no wave script language. A level (`leve`) is a flat list of
placed units (type, layer, x, y, heading, 2 flags) that spawn when the scroll reaches their y.
Everything else — formations, timed waves, scroll pauses, bosses — is data inside the unit
definitions (`unde`): each unit is a state machine (≤20 named states) whose states have timers,
range/hit/counter triggers, up to 5 rules and any number of spawn sets that emit other units.
Level-specific choreography is done by invisible controller units of family `Level`
(53 definitions, e.g. `07s1` "Level 7 - Start 1") placed in the level like any enemy.

## 1. Level files (`leve`, 12 entries, G_Level.cc)

Parser `FUN_100122f0(buf, levelInfo, objectList) @ 100122f0` (key table from
`python3 docs/deimos/tools/key_offsets.py ghidra/Deimos_pef.decompiled.c FUN_100122f0`):
| key | type | dest offset | notes |
|---|---|---|---|
| `#name_STR` | STR ≤0x20 | +0x000 | display name |
| `#indentifier_STR` (sic) | STR ≤0x40 | +0x020 | matched by the level-order table (engine-loop.md §6) |
| `#description_STR` | STR ≤0x100 | +0x078 | |
| `#copyright_STR` | STR ≤0x100 | +0x178 | |
| `#background_RECT` | RECT | +0x060 | text (left,top,right,bottom) = `0, 0, 480, 3600` in all 12 |
| `#backgroundImage_ID` | ID | +0x070 | `im16` map 480×3600 |
| `#previewImage_ID` | ID | +0x074 | `im16` 146×306 |
| `#music_ID` | ID | +0x27c | `mu03` in all 12 |
| `#mediaMask_ID` | ID | +0x280 | `im16` 96×720 |
| `#briefing_ID` | ID | +0x284 | `none` in all 12 |
| `#numObjects_INT` | INT | +0x278 | then that many objects: |
| `#unit_ID` | ID | obj+0x00 | must exist as a `unde` tag (`FUN_10001f20(0x756e6465,id)`), else the object is dropped and the count decremented |
| `#layer_ID` | ID | obj+0x04 | `air ` or `grnd` |
| `#xLoc_INT` | INT | obj+0x08 | map x 0..480 |
| `#yLoc_INT` | INT | obj+0x0c | map y 0..3600 (0 = top) |
| `#headingDegrees_INT` | INT | obj+0x10 | |
| `#isStationary_BOOL` | BOOL | obj+0x14 | |
| `#enableTerrainEffects_BOOL` | BOOL | obj+0x15 | |
Level object = 0x18-byte record allocated per object (`FUN_1004d320(0x18)`) and linked into
`objectList`. [HIGH — reader calls + allocation size]

Worked decode — `xxd -l 64 "$D/Game/leve/Level 07[le07].leve"`:
```
00000000: cd19 e929 a90a caba dafd 3c2b e9d8 6919  ...)......<+..i.
00000010: a9d8 fd9a e939 39a9 681c 5fcd 6919 b9a9  .....99.h._.i...
```
`cd`→`#`, `19`→`n`(0x6e), `e9`→`a`, `29`→`m`, `a9`→`e`, `0a`→`_`, `ca ba da`→`S T R`,
`fd`→space, `3c`→`<`, `2b e9 d8 69 19 a9 d8`→`Mariner`, … `1c 5f`→`>` LF. Decoded head:
```
#name_STR <Mariner Valley>
#indentifier_STR <Lucena>
#description_STR <Jungle combat over the Mariner Valley forestation project.>
#copyright_STR <Map by Sheryn Wareing.>
#background_RECT <0, 0, 480, 3600>
#backgroundImage_ID <jum2>
#previewImage_ID <jup2>
#music_ID <mu03>
#mediaMask_ID <jut2>
#briefing_ID <none>
#numObjects_INT <38>
#unit_ID <plla>
#layer_ID <grnd>
#xLoc_INT <126>
#yLoc_INT <2563>
```
[HIGH — bytes + cipher of pak-format.md §3]

Spawning (engine-loop.md §5): an object spawns when the scroll row `top − 64` equals its yLoc
(`FUN_10033090`); `grnd` objects get x −= 32 (`FUN_10035900`); each object becomes an "entity
group" (0xbc bytes) holding the unit, position, heading and the two flags. [HIGH]

Placement census (Python over the 12 decoded levels): 565 placements (`grnd` 353, `air ` 212),
114 distinct unit IDs; per level 38–67 objects (`#numObjects_INT` equals the `#unit_ID` count in
every file). Selected placements (count, family, name, `score_INT`, shields base+increment/level,
group min–max, states) — ⚑ corrected (review 2026-10-03) #13: this was headed "Most placed" but skipped `sess` 11,
`sels` 10, `geys` 9, `bsat` 9 (added below) while listing `popu` 8, `hosp` 2, `bacc` 2; it is a
selection (every id with ≥ 9 placements, plus `popu`/`hosp`/`bacc` for interest), not a top-N.
Largest ids not listed: `scre` 8, `ns02`/`pola`/`ssat` 7, `plla` 6 (`Counter` over
`#unit_ID <…>` in the 12 decoded levels):
| id | n | family / name | score | shields | group | states |
|---|---|---|---|---|---|---|
| fl02 | 51 | Flipper / Flipper Mk 2 | 80 | 0.8 | 8–9 | 6 |
| blha | 37 | BlackHawk | 90 | 0.8 | 6–7 | 7 |
| grob | 33 | Ground Obstacle | 0 | 0 | 1 | 1 |
| bsde | 31 | Bonus Station - Desert | 0 | 4.0+0.4 | 1 | 1 |
| flip | 27 | Flipper | 80 | 0.8 | 8–9 | 3 |
| bu01 | 27 | Buzzsaw Mk 1 | 50 | 0.4 | 5–6 | 3 |
| bsgr | 25 | Bonus Station - Grass | 0 | 4.0+0.4 | 1 | 1 |
| tala | 21 | Tank - Laser | 300 | 3.5+0.4 | 1 | 1 |
| shur | 17 | Shuriken | 90 | 0.4 | 10–11 | 7 |
| s2f1 | 16 | Screw Mk 2 - Formation 1 | 0 | 0 | 1 | 1 |
| sc03 | 14 | Screw Mk 3 | 80 | 0.8 | 6–7 | 5 |
| bu02 | 13 | Buzzsaw Mk 2 | 60 | 0.5 | 6–7 | 3 |
| sess | 11 | Secret / Secret - Small Shields | 0 | 0.4 | 1 | 1 |
| sels | 10 | Secret / Secret - Large Silver | 0 | 0.4 | 1 | 1 |
| papu | 10 | Panzer - Pulse | 0 | 6.0+0.4 | 1 | 1 |
| car2 | 10 | Cap - Radar Mk 2 | 500 | 12.0 | 1 | 1 |
| pasc | 10 | Panzer - Scatter | 400 | 4.5+0.4 | 1 | 1 |
| sggr | 10 | Swivel Gun - Green | 500 | 3.0+0.4 | 1 | 4 |
| geys | 9 | Geyser | 0 | 0.4 | 1 | 1 |
| bsat | 9 | Bonus Station - All Terrain | 0 | 4.0+0.4 | 1 | 1 |
| bala | 9 | Base - Laser | 500 | 6.0+0.4 | 1 | 1 |
| popu | 8 | Popup | 0 | 7.0+0.4 | 1 | 10 |
| hosp | 2 | Hospital | −10000 | 0.4 | 1 | 1 |
| bacc | 2 | Baccula | 10000 | 1.0 | 7–8 | 1 |
53 placements are `Level`-family controllers (one to five per level, ids `NNs#`/`NNm#`/`NNe#`/
`NNp#`/`NNb#` = start/mid/end/pause/bridge). [HIGH — tool output; full list reproducible with the
script in the INDEX tools list]

## 2. Unit definitions (`unde`, 386 entries, G_UnitDefinitions.cc)

Census (Python over decoded files): 386 files, 222 distinct keys, 60 families (largest: `Level`
53, `Notice` 16, `Screw` 14, `Random Bonus` 12, `Twin Gun` 11, `Player` 11).
`#numStates_INT` distribution: 1×128, 2×91, 3×37, 4×59, 5×18, 6×19, 7×10, 8×8, 9×6, 10×2,
11×1, 12×5, 13×1, 14×1. Spawn sets per state: 0×788, 1×285, 2×64, 3×11, 4×15, 6×2, 7×2.
Rules per state: always 5 (1167 states). [HIGH — tool output]

Loader `FUN_1003fc50(i)` → parser `FUN_1003fda0(id, buf, unitDef) @ 1003fda0` (top level, 102
reader calls) → `FUN_10040920(buf, unitDef, stateIndex, &cursor) @ 10040920` per state.
- The text may be plain or obfuscated: decoded only if `strstr(buf,"#name_STR")` fails. [HIGH]
- States: `numStates` stored at unit+0x14; valid 1..20 (`0x14`), else "incorrect number of
  states" + assert. State `s` lives at `unit + 0x4e0 + s*0x5e0` (`FUN_10040920` line
  `iVar5 = param_2 + param_3 * 0x5e0 + 0x4e0`; same expression in `FUN_10014650`, the
  "current state" accessor). [HIGH]
- Spawn sets: 0x5c-byte records in a linked list at state+0x5dc. [HIGH]
- Rules: unit ID at state+0x28+r*0x88, condition string +0x2c, action (target state name)
  +0x6c, range +0xac, r = 0..4; `#stateRuleName_STR` is read into a scratch buffer and
  discarded; state+0x24 = number of rules whose unit ID ≠ `none`. [HIGH]

Key → offset tables (tool output of `key_offsets.py … FUN_1003fda0 FUN_10040920`; names are
Ghidra's 32-char label truncations; unit offsets from the unit-def base, state offsets from the
state base, spawn-set offsets from the 0x5c record):
⚑ corrected (review 2026-10-03) #12: the tool's regex used to match only `s__key…` labels (key strings that Ghidra
labelled with a double underscore) and silently skipped `s_key…` labels, so in `FUN_10040920` it
did not print `#stateNumSpawnSets_INT` and `#stateRuleAction_STR` (→ `iVar4 + 0x6c`, dump line
38531); the rule-action offset +0x6c below had come from `FUN_10015550`, not from the tool.
Fixed (`s__?` + strip either prefix) and re-run over `FUN_100122f0 FUN_1003fda0 FUN_10040920
FUN_1002ba00 FUN_10039e70` — delta (old 356 lines → new 358):
```
299a300
>   INT   &local_64  #stateNumSpawnSets_INT
356a358
>   STR      0x06c  #stateRuleAction_STR
```
No other parser output changed (the `wede`/`plde`/`leve`/unit-level tables are as before).

Unit level (in parse order):
```
name_STR 0x018 · familyName_STR 0x058 · description_STR 0x098 · numInGroupMin_INT 0x194
numInGroupMax_INT 0x198 · groupDelayMin_INT 0x19c · groupDelayMax_INT 0x1a0 · appearsPercent_INT 0x1c0
deleteExistingEntitiesOfThisType… 0x119 · doNotSpawnIfTypeAlreadyExists 0x118 · harmlessToPlayers 0x11a
playerProjectile 0x11b · canBeHitByPlayerProjectile 0x11c · terrainEffect 0x132 · constrainInGameArea 0x11d
castsShadows 0x11e · adjustShadowLocForScaling 0x12c · randomiseInitialLoc 0x12d
adjustInitialLocForOwnerScale 0x12e · initiallyHuntsClosestPlayer 0x11f · hittableWhenInvisible 0x121
initialHeadingSetInEditor 0x124 · fleesNorthOnNoActivePlayers 0x126 · fleesSouthOnNoActivePlayers 0x127
collidesWithGroundObstacles 0x128 · canBeSpawnedOnlyWhenPlayersActive 0x12a
usePreviewAppearanceInPlacement… 0x12f · allowStationaryOptionInPlacement… 0x130
includeInAirAccuracyCount 0x133 · includeInGroundAccuracyCount 0x134 · editorPreviewSpriteFace_ID 0x2d4
editorPreviewSpriteFrame_INT 0x1bc · pickup_Type_ID 0x4d4 · pickup_MultiplierSpawn_ID 0x4d8
pickup_Value_INT 0x4dc · destructSpawn_ID 0x478 · destructSound_ID 0x4bc (+Min/MaxVolume 0x4c0/4c4,
Priority 0x4c8, Min/MaxPitch 0x4cc/4d0) · destructParticle_ID 0x47c · destructParticleColor 0x480
destructNotice_STR 0x482 · destructNumCoinsToRelease_INT 0x4a4 · destructCoin_ID 0x4a8
destructCoinOnGroupKill_ID 0x4ac · destructDestroyChildren 0x4b0 · destructDeleteChildren 0x4b1
destructDrawToTerrain 0x4b2 · destructReleaseRandomBonus 0x4b4 · destructCreateObstacle 0x4b3
shields_MaxAmount 0x444 · shields_LevelIncrement 0x440 · shields_BaseAmount 0x43c · score_INT 0x4b8
damage_FLOAT 0x274 · initialVisibilityPercent 0x1b4 · initialScalePercent 0x1ac (+Tolerance 0x1b0)
drawLayer_ID 0x2e0 · entryNotice_STR 0x324 · entryNoticeDelay 0x1b8 · displayNoticeOnceOnly 0x120
entryNoticeSound_ID 0x424 (+0x428..0x438) · hitParticles_ID 0x2d8 · hitParticleDoCircularBurst 0x131
hitParticlesColor 0x17e · shieldSound_ID 0x448 (+0x44c..0x45c) · unshieldedSound_ID 0x460 (+0x464..0x474)
deletionSpawn_ID 0x2dc · x/yOffsetMin/Max 0x25c/0x260/0x264/0x268 · initialHeading 0x1a4
initialHeadingTolerance 0x1a8 · useOwnerHeading 0x129 · initialSpeedMin/Max 0x26c/0x270 · doBurst 0x122
doImplode 0x123 · isGroundBased 0x125 · doDeathSpawnOnAnyMedia 0x12b · mediaImpactSize_ID 0x2e4
numStates_INT -> unit+0x14
```
State level:
```
stateEntrySound_ID 0x000 (+MinVol 0x004, MaxVol 0x008, Priority 0x00c, Min/MaxPitch 0x010/0x014)
stateSoundLoop 0x018 · AllowOnlyOneInstance 0x019 · RepeatOnStateChange 0x01a · SoundLoopDelay 0x01c
SoundMaxNumToPlay 0x020 · [active rule count 0x024] · [rules 0x028 + r*0x88] · stateParticles_ID 0x2d0
stateParticlesColor 0x2d4 · ParticlesRepeat 0x2d6 · Particles_RepeatDelay 0x2d8 · Particles_MaxNumBursts 0x2dc
collision_Spawn_ID 0x2e0 · collision_RepeatSpawns 0x2e4 · collision_SpawnDelay 0x2e8
MotionBlur_Required 0x2ec · AllowGlowDrawing 0x2ed · Min/MaxTimeBetween 0x2f0/0x2f4
InitialVisibility 0x2f8 · VisibilityDelta 0x2fc · DoAnimateBackwards 0x300 · DoLoopAnimation 0x301
ContinuousFrameRandomisation 0x302 · DoRotateToTarget 0x303 · stateSpriteFace_ID 0x304
NumDirections 0x308 · SpriteFrameMin/Max 0x30c/0x310 · FramesPerDirection 0x314 · FrameDelay 0x318
FrameDelta 0x31c · stateFlee_ID 0x320 · UseParentDirection 0x324 · invulnerableUntilAllChildrenDestroyed 0x325
invulnerableUntilOwnerDestroyed 0x326 · useOwnersVisibility 0x327 · useOwnersScale 0x328
canBeDestroyedOnOwnerDestruction 0x329 · canBeDeletedOnOwnerDeletion 0x32a · passHitsToOwner 0x32b
visuallyReflectOwnerHits 0x32c · destroyOwnerOnDestruction 0x32d · LockToOwnerLoc 0x32e
LinkToOwnerLoc 0x32f · OrbitOwner 0x330 · stateTintColor 0x332 · DoColorise 0x34d
PauseVerticalScrolling 0x346 · Collides 0x347 · Invulnerable_ShieldsDoNotDeplete 0x348 · Hunts 0x349
CyclicMotion 0x34a · ReverseDirectionOnReaction 0x34b · HoldPositionToTarget 0x34c · IsTargetable 0x34e
CollidesWithPlayers 0x34f · DeleteOnNoActivePlayers 0x350 · DestructOnNoActivePlayers 0x351
DestructIfVerticalScrollingNotPaused 0x352 · DrawToTerrain 0x353 · DoNotGlowOnCollision 0x354
UseThisStateOnWeaponPowerupRelease 0x355 · UseThisStateOnShieldDepletion 0x356
Pickup_DoNotChangeAppearance 0x357 · OnTimerMin/Max 0x3ac/0x3b0 · OnCounter 0x3b4
OnHitChangeStateDelay 0x3b8 · RequiredScale 0x3bc · ScaleDelta 0x3c0 · RequiredVisibility 0x3c4
VisibilityDelta 0x3c8 · TintPercent 0x3cc · TintDelta 0x3d0 · OnRange_FLOAT 0x44c · HoldMaxSpeed 0x450
HoldDelta 0x454 · MaxSpeed 0x458 · Delta 0x45c · FleeSpeed 0x460 · FleeDelta 0x464 · stateName_STR 0x49c
OnTimerChangeTo_STR 0x4dc · OnCounterChangeTo_STR 0x51c · OnRangeChangeTo_STR 0x55c
OnHitChangeTo_STR 0x59c · [spawn-set list 0x5dc]
```
Spawn set (0x5c record): `Name_STR 0x00 · Spawn_ID 0x20 · XOffset 0x24 · YOffset 0x28 ·
RateMin/Max 0x2c/0x30 · NumInVolleyMin/Max 0x34/0x38 · DelayBetweenEntitiesMin/Max 0x3c/0x40 ·
AdjustOffsetForUnitRotation 0x44 · AbsoluteCoordinates 0x45 · RepeatSpawns 0x46 ·
Don'tSpawnOffscreen 0x47 · PauseAnyRotationWhileSpawning 0x48 · TimeToPauseRotationAfterSpawning
0x4c · SpawnIfFleeing 0x50 · SetHeading 0x51 · HeadingDegrees 0x54 · StationaryOption 0x58 ·
TerrainEffectsOption 0x59`.
[HIGH for the unit and spawn-set tables (literal `dest + off` arguments); HIGH for the state
table — cross-checked against the consumer `FUN_10033850`, which reads `piVar9[0xb4]`=0x2d0
particles, `piVar9[0xb6/0xb7]`=0x2d8/0x2dc, `*piVar9`=0x000 entry sound, `piVar9+0x137`=0x4dc
timer target, `+0x346` pause-scrolling (its return value), `+0x352` destruct-if-not-paused]

## 3. Entity update and the state machine (G_EntityGroup.cc `FUN_10033850 @ 10033850`)

Per tick, for every entity group and entity (code reading, trimmed to the decision points):
1. Spawn-in delay: entity+0xb0 counts down; nothing happens until ≤ 0.
2. State particles: if `stateParticles_ID` ≠ none and (not repeating and none emitted yet, or
   repeating and `gameTime ≥ last + RepeatDelay`) and (`MaxNumBursts`==0 or below it) → emit.
3. State entry sound (`stateEntrySound_ID` ≠ none): play once, or looped every
   `SoundLoopDelay` ticks up to `SoundMaxNumToPlay`, skipping if `AllowOnlyOneInstance` and the
   sound is still playing (`FUN_100476e0`).
4. Timer: when `gameTime == stateStart(+0xa4) + timer(+0xb8)` — the timer is drawn from
   `[stateOnTimerMin, Max]` (`FUN_10046580`, see `FUN_100146f0`) — the target
   `stateOnTimerChangeTo_STR` is applied: `"Delete"` → remove silently (flags +0xcb, +0xd9);
   `"Destroy"` → `FUN_10016300` (destruction: score/coins/spawns/bonus); empty or equal to
   `_DAT_100df43c` = **`"none"`** → no change; otherwise `FUN_100146f0` switches to the
   state with that NAME. ⚑ corrected (review 2026-10-03) #7: the string was NOT RESOLVED; memory image
   `0x100df43c → 0x100d71ac → "none"` (TOC slot r2−0x6ef4; the same compare appears in
   `FUN_100146f0`, dump line 33494). [HIGH]
5. If the state has active rules (+0x24 ≥ 1) → `FUN_10015550` (below), which may switch state.
6. `statePauseVerticalScrolling` of any updated entity makes `FUN_10033850` return 1 → the
   caller stops the scroll this tick (`FUN_1000ffe0`), else scroll resumes (`FUN_1000ffc0`).
7. Visibility/tint/scale targets set from the state; movement `FUN_10015930`/`FUN_10015280`/
   `FUN_10015b40` (not read); ground-obstacle collision; owner link/lock/orbit
   (`FUN_10037130/7230/7350`); off-screen culling `FUN_10012ca0(entity, 0x80, 1)` (128-px margin);
   `stateDestructIfVerticalScrollingNotPaused` → destroy when scrolling resumes.
8. Player collision (state `Collides` + `CollidesWithPlayers`, unit not `harmlessToPlayers`,
   entity inside the game area with 32-px slack): bounding boxes, then `FUN_10042f80`
   (pixel/shape test, not read) → if the unit is not a pickup (`pickup_Type_ID` == none):
   player takes the hit (`FUN_10026c90`), entity takes `Player_ImpactDamageToEntities` (flli 161
   = 100) via `FUN_10014f10`; pickups go to `FUN_10037580` and are destroyed on success.
9. Motion-blur trail emission, ground-accuracy crosshair test (`FUN_1003bab0`), obstacle
   creation, spawn sets `FUN_10036cf0(entity, gameTime)` for colliding entities.
[MED overall — control flow read; most callees unnamed; step 4 "Delete"/"Destroy" strings HIGH]

Rules `FUN_10015550 @ 10015550`: for r = 0..4, skip if rule unit = `none`; the unit must exist
("FILE: Unknown Rule Unit ID"); the condition string is looked up in a fixed 17-entry table
(64-byte stride at `PTR_s_Is_Tracking_Player_100df120`, strings read from `0x100d6824`), unknown
→ "Unknown Rule Unit Condition" and the rule is disabled; if the condition holds, switch to the
state named by the action (`FUN_100146f0(entity,0,rule+0x6c,…)`) and stop evaluating:
| # | condition string | test (code) |
|---|---|---|
| 0 | Is Tracking Player | `FUN_10034ee0(ruleUnit, pos, range)` |
| 1 | Is Not Tracking Player | not #0 |
| 2 | Is Active | `FUN_10035070(ruleUnit, pos, range)` |
| 3 | Is Not Active | not #2 |
| 4 | No Destroyable Air Entities Are Active | `!FUN_100352f0()` |
| 5 | No Destroyable Ground Entities Are Active | `!FUN_100353e0()` |
| 6 | No Destroyable Air or Ground Entities Are Active | #4 and #5 |
| 7 | No Players Are Active | `!FUN_10006110()` |
| 8 | This Entity is Within Range of a Player | `FUN_10017ef0(entity, range, …)` (range ≠ 0) |
| 9 | This Entity is Not Within Range of a Player | not #8 (range ≠ 0) |
| 10 | This Entity's Animation Has Stopped | entity+0xc2 |
| 11 | This Entity's Visibility is at Required Level | entity+0x68 == +0x6c |
| 12 | This Entity's Tint is at Required Level | +0x58 == +0x5c |
| 13 | This Entity's Scale is at Required Level | +0x84 == +0x88 |
| 14 | Number of This Type of Entity Active | `count(ruleUnit) == range` (`FUN_100351f0`) |
| 15 | Are Fewer of These Entities Active | `count(ruleUnit) < range` (signed) |
| 16 | Are More of These Entities Active | `count(ruleUnit) > range` (signed) |
[HIGH for table and dispatch, and for #15/#16; MED for the semantics of callees #0/#2/#8 (unread)]
⚑ corrected (review 2026-10-03) #6 (was "direction of #15/#16 is LOW — branch-free sign idiom"). Decompiled idiom:
```c
case 0xf:  u = count ^ range;  u = ((int)u >> 1) - (u & range) >> 0x1f;          // logical >>31
case 0x10: u = ((int)(count ^ range) >> 1) - ((count ^ range) & count) >> 0x1f;
```
Exhaustive check (Python, signed 32-bit, all pairs from −40..40 ∪ {±1000, ±2³¹ edge values},
7569 pairs): case 15 ≡ `count < range`, case 16 ≡ `count > range`, 0 mismatches.
Shipped usage (`grep` census of `#stateRuleCondition_STR` with a non-empty value): Is Tracking
Player 2773 (almost all inert defaults with unit `none`), Is Not Active 67, Is Active 52, No
Destroyable Ground Entities Are Active 41, Number of This Type… 17, No Players Are Active 15,
Animation Has Stopped 6, No Destroyable Air… 2, Are Fewer… 1. Actions: `Delete` 2812 (defaults),
plus named states (`Pause Scrolling, Wait, Delete` 26, …).

Shields at spawn (`FUN_10035cd0`, line ~32186 of the dump):
```c
      *(undefined4 *)(iVar3 + 0x134) = *(undefined4 *)(iVar10 + 0x43c);     // base
      if (dVar11 < (double)*(float *)(iVar10 + 0x440)) {                    // increment > 0.0
        iVar4 = FUN_10005cd0();                                             // sector number
        *(float *)(iVar3 + 0x134) = base + increment * (float)(iVar4 - 1);
        if (*(float *)(iVar10 + 0x444) < *(float *)(iVar3 + 0x134)) = max;  // cap
```
→ **shields = min(base + increment × (sector − 1), max)**, sector = game struct +0x14
(1-based position in the level-order table). `dVar11 = pdVar2[2]` = 0.0 (double table at
`0x100d7228` = 4503601774854144.0, 100.0, 0.0, 0.2). This is the only per-level difficulty
scaling found; no difficulty option exists in prefs/strings. [HIGH for the formula; MED that
+0x14 is 1-based sector — set from `FUN_10011e30()` in `FUN_100051a0`]

## 4. Worked example of a "wave": `Level 7 - Start 1` (`07s1`)
`grep -nE '#(stateName_STR|stateOnTimer…|stateSpawnSetSpawn_ID|…)' "$D/Game/unde/…[07s1].unde.txt"`:
```
#stateName_STR <Wait Until Pausing>        timer 180..180 -> "Pause Scrolling, Wait"
#stateName_STR <Pause Scrolling, Wait>     timer 20..30   -> "Pause, Spawn Shurikens"   PauseVerticalScrolling TRUE
#stateName_STR <Pause, Spawn Shurikens>    timer 300      -> "Pause"   spawn set: shur at (208,-100) absolute, every 120..125 ticks, 1 per volley
#stateName_STR <Pause, Wait, Delete>       timer 130..140 -> Delete
#stateName_STR <Pause>                     timer 220      -> "Spawn Shurikens"
#stateName_STR <Spawn Shurikens>           timer 500      -> "Pause, Wait, Delete"  spawn set as above
```
Placed once, in le12 (sector 7 — the controller names use sector numbers). Reading: 180 ticks after placement the controller stops the scroll and, while stopped, emits a
Shuriken group at the top centre (208 = 416/2) every ~2 s for 300 ticks, pauses 220, emits for
500 more, waits 130–140 and deletes itself (scrolling resumes). The file lists 6 states; the
order of state 4/5 in the file differs from execution order because transitions are by name.
[MED — semantics of RateMin/Max and AbsoluteCoordinates from key names + this consistent
example; the spawn-set executor `FUN_10036cf0` was not read]
Groups (`FUN_10033220` spawn request → `FUN_100369f0` size → `FUN_10035bf0` → `FUN_10035cd0`
per member):
- size: `min = max(numInGroupMin, 1)`, clamped to `numInGroupMax`; if min ≠ max a random draw
  (`FUN_10046580()` — arguments dropped by the decompiler, presumably (min, max)) [MED];
  then each of the n members is removed unless `appearsPercent == 100`, or
  `appearsPercent != 0 && appearsPercent >= Random(0,100)` [HIGH];
- members are created at once but each gets a spawn countdown (entity+0xb0) equal to the running
  sum of `groupDelayMin` (if min == max) or `Random(groupDelayMin, groupDelayMax)` — i.e. a
  staggered column [HIGH; the random's args dropped → MED for its range];
- every member starts in the unit's first state (`FUN_100146f0(…, unit + 0x97c, …)`;
  0x97c = 0x4e0 + 0x49c = state 0 `stateName_STR`) [HIGH];
- member placement `FUN_10037930(group, entity) @ 10037930`, called unconditionally by
  `FUN_10035cd0` for every created entity (before `FUN_10037b50` initial speed/heading and the
  state-0 entry). Offsets are relative to the group position (`group+0x9c`, `+0xa0`); unit fields
  `xOffsetMin +0x25c, xOffsetMax +0x260, yOffsetMin +0x264, yOffsetMax +0x268` (key_offsets.py),
  `randomiseInitialLoc +0x12d`:
  - if `xMin == xMax` **or** `yMin == yMax` (rectangular mode): `x = gx + (xMin == xMax ? xMin :
    RandomRange(trunc(min(xMin,xMax)), trunc(max(xMin,xMax))))`, then `y` the same way with the
    y pair (int `FUN_10046580`; x drawn before y);
  - else (both ranges open — radial mode): `h = RandomRange(0, 359)` (int), `(cx, cy) =
    FUN_10042b30(h)` (direction vector of heading h); if `randomiseInitialLoc` is FALSE the member
    is placed **on** the ellipse `x = gx + cx·|xMax|, y = gy + cy·|yMax|`; if TRUE, `r =
    FloatRandomRange(0.0, |xMax|)` (`FUN_100465e0`, f1 = `*(float*)(0x100d7204+0x10)` = 0.0) and
    `x = gx + cx·r, y = gy + cy·r` (a disc of radius |xOffsetMax|; yOffsetMax unused);
    xMin/yMin are not used in radial mode;
  - result written by `FUN_10012910(entity, &pos)` (set position).
  [HIGH — disassembly `10037960..10037b20`: `lfs f1,0x25c(r31) … fcmpu … beq` mode test,
  `li r3,0x0; li r4,0x167; bl 0x10046580` heading, `lbz r0,0x12d(r31)` flag,
  `fabs f0,f31 (|+0x260|); lfs f1,0x10(r3); frsp f2,f0; bl 0x100465e0` radius,
  `fmadds f0,f3,f1,f0` = cx·r + gx; MED for which component of `FUN_10042b30`'s vector is x
  (its helpers `FUN_10042f00`/`FUN_10042ee0` decompile empty — table lookups not read)]
  ⚑ corrected (review 2026-10-03) #2: closes NOT RESOLVED #21 (INDEX) / §8 item 3 below.
- `doNotSpawnIfTypeAlreadyExists` (+0x118) suppresses the request if one exists;
  `canBeSpawnedOnlyWhenPlayersActive` (+0x12a) needs an active player [HIGH];
- hard cap: a request is refused when live entities + n ≥ 1001 ("Reached Entity Limit",
  `< 0x3e9`) [HIGH].

## 5. Player definitions (`plde`, 2 entries)
Player 1 / 2 differ only in name, sprite frames (0/1), `entry_multiStartX_INT` (104/312) and
money-counter unit (`p1mc`/`p2mc`) (`diff` of the decoded files). Values (Player 1):
lives: `life_MaxNum 10`, `life_NumInitial 3`, `life_InitialRequiredScore 10000`,
`life_AdditionalRequiredScore 30000`; shields: `defaultShieldPercentage 100`,
`shieldWarningPercentage 15`, `shieldBaseHitPercentage 15`, `shieldHitDelay 1`; entry:
`entry_soloStartX/Y 208/330`, `entry_multiStartX/Y 104/330`, `entry_StartVelocityY -7.2`,
`entry_VelocityDelta 0.05`, `entry_InitialDelay 55`, `entry_InvulnerabilityTime 60`; timings:
`waitingTime 60`, `filmIntroTime 60`, `introTime 56`, `gameOverTime 20`, `dyingTime 80`,
`finalDyingTime 40`, `death_Duration 90`; movement: `active_DefaultMaxSpeed 7.8`,
`active_VelocityDelta 1.6`; overload warning: 8 warnings, interval 8→3. [HIGH — file values;
the parser `FUN_10039e70`'s offsets and the movement/acceleration code (`FUN_10028170`) are
NOT RESOLVED]

## 6. Weapons (`wede`, 5 entries; G_WeaponDefinitions.cc / G_WeaponHandler.cc)
| file | type | default | levels | delay | spawns | power-up max / overload |
|---|---|---|---|---|---|---|
| Air - Ion Cannon `aiic` | PEAA | DEAA | 1–3 | 4 | 3 | 20 / 180 |
| Air - Bacta Gun `aibg` | PEAA | none | 2–9999 | 5 | 8 | 20 / 180 |
| Air - Rear Gun `airg` | PEAA | none | 3–9999 | 8 | 1 | 12 / 180 |
| Air - Photon Beam `aipb` | PEAA | none | 5–9999 | 8 | 1 | 22 / 0 |
| Ground - Plasma Bomb `plbo` | PEAG | DEAG | 0–9999 | 4 | 2 | — |
(`grep` of the decoded files.) `PEAA`/`PEAG` = air/ground weapon type; `DEAA`/`DEAG` mark the
default air/ground weapon (`FUN_1003cca0` tests DEAA/DEAG; `FUN_1003cd30/cdb0` test PEAA).
"GAME DATA INCORRECT. No default Ground Weapon for Level %i" / "No suitable Air Weapon for
Level %i" (G_WeaponHandler.cc) show availability is filtered by level with
`minimumLevelAvailable`/`maximumLevelAvailable`. Guide cross-check (cite): Ion Cannon is the
default; Photon Beam "cannot be overloaded" ↔ `powerup_Air_OverloadTime 0`. Bombs:
`WepHandler_DefaultNumBombs` 1, `WepHandler_MaxNumBombs` 8 (flli 151/152, `FUN_1003beb0`).
[HIGH for values; MED for type/default semantics; weapon firing/power-up code NOT RESOLVED]

## 7. Scoring
- Kill score: when a unit is destroyed by a player (`FUN_10014f10` damage path),
  `FUN_10006190(player, unit.score_INT (+0x4b8), 0)` → `FUN_10029a10(player, pts, raw=0)`,
  which multiplies by the player's bonus multiplier byte (+0xb4) unless raw. [MED]
- Score storage is obfuscated in memory: player+0xb0 holds score + 0x5532a3e
  (`FUN_10029a10`: `iVar1 = *(int *)(param_1 + 0xb0) + -0x5532a3e + iVar1; … = iVar1 + 0x5532a3e`);
  coins at player+0xac hold count + 0xb2cce. [HIGH]
- Extra lives (`FUN_10029a10`): when score > threshold (+0x9c): +1 life; threshold +=
  `life_AdditionalRequiredScore` (playerDef+0x6c) + step (+0xa0); step += flli 182 (10000).
  ⚑ corrected (review 2026-10-03) #14: this life check runs only when `raw == 0`. The `raw` branch (`param_3 ≠ 0`,
  `pts > 0`) awards no life but **overwrites** the step: `step(+0xa0) = newScore + flli 182`
  (`FUN_10020250(0xb6); *(int *)(param_1 + 0xa0) = iVar1 + (int)in_f1;`, iVar1 = new decoded
  score). A replica of the threshold logic must carry this write. [HIGH — read]
  Initial threshold/step values NOT RESOLVED (set outside this function); with threshold 10000
  and step 0 this yields 10000, 40000, 80000, 130000, … — the guide's "10,000 then 30,000 …
  then another 40,000" wording is compatible only if read as increments. [MED]
- End-of-level coin bonus (`FUN_10027670`): coinValue = flli 171 (100) if flli 170 == 0 else
  sector × flli 171; bonus = coins × coinValue (player+0x1f0); the tally animation step
  (player+0x1f4) = max(bonus × flli 200 (0.02), flli 199 (100)). [MED]
- Ground accuracy (`FUN_100072c0`, `FUN_100075e0`): tiers every flli 188 (5) percent worth
  5000/2000/1000/500/250/0 (flli 189–194); 100 % = `Game_GroundAccuracyCount_MissionBonus`
  100000 (flli 205) + sound `miac`. [MED — consumers identified by flli keys, arithmetic not read]
- Random bonus on destruction (`FUN_10016300`): cumulative percent table flli 209–217
  (70,78,82,84,87,91,95,98,100) selects idli objects 25–34 `RandomBonus_1..10`; flli 218 (10)
  and 219 (3: minimum level for the highest bonus) also read. [MED]
- Penalties/bonuses from data: Hospital `score_INT -10000`; Baccula 10000;
  `Player_DefenceBonusBaseAmount` 2000 (flli 184, "Shield Bonus" for no damage, per guide). [HIGH
  values / LOW for the defence-bonus formula]

## 8. NOT RESOLVED (this file)
1. Movement model: `stateMaxSpeed/Delta/HoldMaxSpeed/Hunts/CyclicMotion/Flee*` executors
   (`FUN_10015930`, `FUN_10015280`, `FUN_10015b40`) — speeds' units (px/tick) unconfirmed.
2. Spawn-set executor `FUN_10036cf0` (rate, volley, delay, offsets, absolute coords, heading).
3. ~~Group member placement offsets (`xOffsetMin/Max`, `yOffsetMin/Max`, `randomiseInitialLoc`).~~
   Resolved — §4 "member placement" (`FUN_10037930`). ⚑ corrected (review 2026-10-03)
4. Rule condition callees `FUN_10034ee0` (tracking), `FUN_10035070` (active), `FUN_10017ef0`.
5. ~~`_DAT_100df43c` string compared in the timer step (likely the "no change" marker).~~
   Resolved — `"none"`, §3 step 4. ⚑ corrected (review 2026-10-03)
6. Collision shape test `FUN_10042f80`; damage formula `FUN_10014f10` (uses flli 167
   Entity_HitDelay) and player hit `FUN_10026c90` (shield % per hit).
7. Player physics and crosshair (`FUN_10028170`), weapon fire/power-up/overload logic.
   (Partly read since: the input→velocity block of `FUN_10028170`, engine-loop.md §8; the air
   power-up/overload state machine `FUN_1003c0d0` and the launch function `FUN_1003c4f0` are
   identified in function-roles.md §1 but their arithmetic is not written up.) ⚑ corrected (review 2026-10-03)
8. Initial extra-life threshold/step; exact coin-bonus and accuracy arithmetic.
9. Whether `numStates`>14 or rule counts other than 5 occur in any mod data (engine allows 1–20
   states; rules loop reads `#stateNumRules_INT` but the evaluator scans exactly 5).
