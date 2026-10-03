# Deimos Rising 1.0.6 — spawn sets, entity groups, owner relations, rule callees

Scope (reader B, wave 1, 2026-10-03): G_EntityGroup.cc, address range `0x10032e60–0x10039280`
(every function listed in `$W/inventory.txt` for that span), plus the G_Entity.cc functions the
spawn-set path forced me into: `FUN_10015b40` (the **real** spawn-set executor — see §2),
`FUN_10017cb0` (spawn-set init), `FUN_10017150` (rotation gate), `FUN_100144a0` (per-entity
spawn records), `FUN_10017ef0` (range rule), and the RNG-relevant parts of `FUN_100146f0`.
OUT: the collision/damage steps of `FUN_10033850` (damage reader), `FUN_100345f0` (scoring
reader), `FUN_10033090` (level/scroll reader); damage arithmetic `FUN_10014f10`, shape test
`FUN_10042f80`, destruction `FUN_10016300`, movement `FUN_10015930`/`FUN_10015280`.
Evidence: decompile dump `ghidra/Deimos_pef.decompiled.c`; raw PPC listing
`$W/disasm-spawn.txt` (my run: `analyzeHeadless $W/work-spawn … DisasmFuncs.java` over all 48
range functions minus the two excluded + `FUN_10017cb0 FUN_100146f0 FUN_10017ef0 FUN_10015b40
FUN_10017150 FUN_100172d0 FUN_100144a0 FUN_10016bd0 FUN_100161c0 …`); constants from
`$W/mem/10000000.bin` (pointers at `0x100d7xxx` resolve into the CODE image, not the data image);
shipped data from `$W/data/Game/{unde,leve}`. `R(a,b)` = `FUN_10046580` int RandomRange,
`F(a,b)` = `FUN_100465e0` float RandomRange (engine-loop.md §9; neither draws when a == b).

**Answer up front.** `FUN_10036cf0` is **not** the spawn-set executor — it is entity-vs-entity
(player side vs enemy side) collision with mutual damage (§7). The spawn-set executor is
`FUN_10015b40 @ 10015b40` (in the G_Entity span; the bank had it as a "movement executor"),
called once per tick for every live, non-culled entity. A spawn set fires **volleys**: the first
volley is armed at state entry (no initial wait), members of a volley are issued every
`max(DelayBetweenEntities,1)` ticks, and the next volley is armed `Rate` ticks after the previous
one was armed. Each "member" is a full spawn **request** (`FUN_10033220`), i.e. a whole group of
the spawned unit (its `numInGroupMin/Max`, `groupDelay`, placement…). Positions are in screen
space (same space as entity positions); `AbsoluteCoordinates` means the offset IS the screen
position. Both `PERM` compares are the **permanent entity group** (group 0, id 20000000) which
holds every single-entity spawn without a non-PERM owner and is never freed when empty.

## 1. Structures

### 1.1 Spawn request (0x2c bytes, argument of `FUN_10033220`)
Template for spawn-set requests = 0x2c bytes at `r2+0x180` = `0x100e64b0` (data image:
`6e6f6e65 00000000 00000000 00000000 00000000 ff000000 … 3f800000`); level requests use the
template at `0x100eb41c` (`FUN_10033090` uses r2+0x50ec; bytes identical to `0x100e64b0`;
initialised by `FUN_10039100`). ⚑ corrected (review wave 1, 2026-10-03) #M3: was `0x100eb420` (level-scroll-objects.md §6.3 has it right).
| off | type | meaning | evidence |
|---|---|---|---|
| +0x00 | 4CC | unit ID to spawn (`none` → assert) | `10033240 lwz r3,0x0(r3)`, 33220 assert line 0x194 |
| +0x04/+0x08 | float | x, y of the group | `FUN_10015b40` `10015e34/3c stfs …,0x3c/0x40(r1)` (req at r1+0x38) |
| +0x0c | byte | y is a MAP row → group y = trunc(y) − window top `_DAT_100e5acc` (`FUN_1000fec0`) | `10033524 lbz r0,0xc(r24)` … `10033558 subf; neg` ; level reader `FUN_10033090` sets 1, spawn sets leave the template's 0 |
| +0x0d | byte | heading supplied (spawn set `SetHeading`) | `10016148 stb r3,0x45(r1)`; `10033580 lbz r0,0xd(r24)` |
| +0x10 | int | supplied heading (degrees) | `10016154 stw r0,0x48(r1)`; `100335b0 lwz r8,0x10(r24)` |
| +0x14 | s8 | owning player (−1 none) → entity +0xd8 | `10016174 stb r0,0x4c(r1)` from spawner +0xd8 |
| +0x18 | int | editor heading (level `headingDegrees`) → group +0xb4 | `10033594 lwz r8,0x18(r24)` |
| +0x1c/+0x1d | byte | stationary / terrain-effects option → group +0xb8/+0xb9, entity +0x13c/+0x13d | `1001617c/84 stb …,0x54/0x55(r1)`; `10035f20..34` |
| +0x20/+0x24 | ptr/int | owner entity / owner entity id → entity +0x140/+0x144 | `10016158 stw r30,0x58(r1)`, `1001616c stw r0,0x5c(r1)` |
| +0x28 | float | speed multiplier for `FUN_10037b50` (template 1.0) | `10035f44 lfs f1,0x28(r22)` |
[HIGH — listing lines above; caller `FUN_10015b40` traced]

### 1.2 Entity group (0xbc) and the PERM group
| off | meaning | evidence |
|---|---|---|
| +0x08 | magic 0x499602d2 (1234567890), checked by `FUN_100355b0` (entities carry it too) | decompile |
| +0x94 | group id (counter `_DAT_100e0208`, starts 20000000 = `lis r3,0x131` + 0x2d00) | `10032f88` |
| +0x98 | unit ID, or `PERM` (0x5045524d) for the permanent group | `10032fec lis r3,0x5045; addi r0,r3,0x524d; stw r0,0x98(r29)` |
| +0x9c/+0xa0 | group position x / y (float) | `FUN_10033220` |
| +0xa4 | members requested (group size n) | `FUN_10033220`; `10036194..a4` |
| +0xa8 | live members (decremented by `FUN_10036120`) | `10036378..80` |
| +0xac | members destroyed (not merely deleted) | `10036194..9c` |
| +0xb0 | member list | — |
| +0xb4/+0xb8/+0xb9 | editor heading / stationary / terrain options of the request | `FUN_10033220` |
- `FUN_10032e60` (level init) creates the PERM group first in the active list
  (`_DAT_100e0228`), id 20000000, sizes 0. [HIGH — listing `10032fec..1003305c`]
- `FUN_10033220`: if the request yields exactly **1** member and (no owner, or the owner's group
  id +0xa0 == 20000000), the entity is added to the PERM group (`*(perm+0xa4) = 1;
  *(perm+0xa8) += 1`); otherwise a new 0xbc group is appended. [MED — decompile; branch
  `iVar2 == 1 && (req[8]==0 || owner+0xa0 == 20000000)`]
- `FUN_10036120` returns "group now empty" only when `+0xa8 < 1` **and** the group is not
  `PERM`; `FUN_10036610` then frees it. The PERM group therefore persists all level. A PERM
  member's death never awards `destructCoinOnGroupKill_ID` (`+0x98 != PERM` test). [HIGH —
  `10036294 lwz r3,0x98(r25)`, `10036390 lwz r3,0x98(r25)`]
- Entity ids: counter `_DAT_100e0204` starts at 1000 (`10032f90 li r3,0x3e8`). [HIGH]

### 1.3 Entity pool and entity fields used here
`FUN_10038390` (startup) preallocates **1000 entities of 0x1ec bytes**; table `_DAT_100df44c`
= {+0 free-slot hint, +4 live count, then 1000 × {u8 inUse, int index, ptr}}. `FUN_100385d0`
allocates (hint, else first free; refuses at 1000 live), `FUN_10038810` frees (hint = index),
`FUN_10038450` clears flags at level init, `FUN_10038540` disposes all. [MED — decompile only;
no RNG involved]
| entity off | meaning | evidence |
|---|---|---|
| +0x00/+0x04 | x, y (float, screen space) | `FUN_100128d0` copy |
| +0x2c/+0x30 | half width / half height (int) — bounding box `FUN_10012ad0` | decompile |
| +0x84 | current scale (1.0 = unscaled) | `10015e48 lfs f5,0x84(r30)` vs 1.0 |
| +0x94 / +0x9c / +0xa0 | unit def / entity id / group id | `FUN_10035cd0` |
| +0xa8 | current state index | `FUN_10014650` |
| +0xc1 | "tracking a target" (set by rotate-to-target `FUN_100172d0`) | §6 |
| +0xc3 | current state has ≥ 1 spawn set | `FUN_10017cb0` `10017d0c stb r0,0xc3(r28)` |
| +0xc4 | rotation-pause countdown | §2.4 |
| +0xcb / +0xd9 / +0xda | deleted flag / killer player (−1) / destroyed flag | `FUN_10016300` writes |
| +0xcc | fleeing | `10015c14 lbz r0,0xcc(r30)` |
| +0xd8 | owning player (−1 none) | |
| +0xdc / +0xe0 | orbit radius (float) / orbit angle (int deg) | §4 |
| +0x124/+0x128 | offset from owner; +0x12c/+0x130 owner's last position | §4 |
| +0x13c / +0x13d | stationary / terrain effects (from request +0x1c/+0x1d; +0x13c also set on ground-obstacle stop) | `10035f2c/34` |
| +0x13e | unit has ≥ 1 spawn set in any state (gates destruct-children) | `FUN_100144a0` |
| +0x140/+0x144 | owner entity / owner id (link valid iff ptr ≠ 0, ids equal, owner not deleted: `FUN_10036ab0`) | |
| +0x19c + s·4 | per-state list of 0x18-byte spawn records (20 lists) | `FUN_100144a0` |
Unit def: +0x04 = unit ID (`FUN_1003fda0` `*(param_3+4) = id`), +0x08 = layer `'air '` if
`isGroundBased` (+0x125) is FALSE else `'grnd'` (loader `FUN_1003fc50`, dump l.38126–32). [MED]

## 2. Spawn sets (state keys `stateSpawnSet*`, 0x5c records at state+0x5dc)

### 2.1 Per-entity spawn record (0x18 bytes)
Created by `FUN_100144a0` (unit assignment) for every spawn set of every state, zeroed
(`FUN_1000cd90(p,0x18)`); sets entity +0x13e = 1. [MED — G_Entity, decompile]
| off | meaning |
|---|---|
| +0x00 | rate: ticks from one volley's arm to the next (`< 0` → set inert) |
| +0x04 | tick of the last arm |
| +0x08 | requests still to issue in the current volley |
| +0x0c | size of the current volley |
| +0x10 | countdown to the next request |
| +0x14 | active (byte) |
[HIGH — offsets from both listings below]

### 2.2 State entry: `FUN_10017cb0(entity, now) @ 10017cb0`
Called by `FUN_100146f0` (every state change, including state 0 at creation) after the timer,
sprite-frame, scale and flee draws. For each set i of the new state, in list order:
- `Spawn_ID == none` → rec = {rate 0, last now, active 0}; entity +0xc4 = 0.
- else `rate = R(RateMin,RateMax)` (0x2c/0x30) → `last = now` → `volley = R(NumInVolleyMin,Max)`
  (0x34/0x38) → `active = rate ≥ 0 && volley > 0` → `remaining = volley` →
  `delay = R(DelayBetweenEntitiesMin,Max)` (0x3c/0x40) → entity +0xc4 = `TimeToPauseRotation…`
  (0x4c) **unconditionally** (the `PauseAnyRotation` flag is not tested here; the last set in
  the list wins).
- entity +0xc3 = (number of sets > 0).
So **the first volley is armed immediately on entry** (remaining = volley). [HIGH — listing
`10017d5c lwz r3,0x2c(r27); lwz r4,0x30(r27); bl 0x10046580; stw r3,0x0(r26); stw r29,0x4(r26)`,
`10017d74 lwz r3,0x34(r27) … stw r3,0xc(r26)`, `10017da8 stb r3,0x14(r26)`, `10017db0 stw
r0,0x8(r26)`, `10017db4 lwz r3,0x3c(r27) … stw r3,0x10(r26)`, `10017dc8 lwz r0,0x4c(r27); stw
r0,0xc4(r28)`; list = `unit + s·0x5e0 + 0xabc` = state+0x5dc]
⚑ corrected: function-roles had it MED "init state spawn-set timers".

### 2.3 Per tick: `FUN_10015b40(entity, now) @ 10015b40` — the executor
Called from `FUN_10033850` for every entity that passed the spawn-in delay, rules, movement and
the 128-px off-screen cull, right after the owner lock/link/orbit updates (§4) — i.e. once per
live entity per tick, using the already-updated position. First it calls `FUN_10017150` (§2.4);
returns at once if entity +0xc3 == 0. Then for each set i in list order (record from
`+0x19c + state·4`):
1. Skip if `Spawn_ID == none`, or `!active`, or `rate < 0`, or (entity fleeing +0xcc and
   `!SpawnIfFleeing` 0x50) — a skipped set's counters do not advance.
2. `Don'tSpawnOffscreen` (0x47): if `remaining > 0 && remaining ≥ volleySize` (volley not yet
   started) and the spawner is not on screen (`FUN_10016bd0`: `0 ≤ x ≤ trunc(VisibleGameWidth
   416)` and `0 ≤ y ≤ trunc(VisibleGameHeight 480)`, inclusive) → `remaining = 0` (whole volley
   cancelled), next set.
3. If `remaining > 0`: `if delay > 0: delay −= 1`; if still `delay > 0` → next set; else
   **issue one request**: `remaining −= 1`, `delay = R(DelayMin, DelayMax)`.
4. Else (`remaining ≤ 0`): if `!RepeatSpawns` (0x46) → `active = 0` (set dead until the state
   is re-entered); else if `now ≥ last + rate` → **re-arm**: `last = now`,
   `delay = R(DelayMin,DelayMax)`, `volley = R(VolMin,VolMax)`, `remaining = volley`,
   `rate = R(RateMin,RateMax)`; if `PauseAnyRotationWhileSpawning` (0x48) and
   `TimeToPause (0x4c) > entity+0xc4` → `entity+0xc4 = TimeToPause`. **No request is issued on
   the re-arm tick.**
[HIGH — listing: `10015c08 lwz r0,0x0(r29); cmpwi; blt` (rate<0 skip), `10015c14 lbz
r0,0xcc(r30) … 10015c20 lbz r0,0x50(r28)`, `10015c2c lbz r0,0x47(r28)` … `10015c44 lwz
r0,0xc(r29); cmpw r3,r0; blt` … `bl 0x10016bd0` … `stw r0,0x8(r29)`, `10015c80..cc`
(countdown/issue, `lwz r3,0x3c(r28); lwz r4,0x40(r28); bl 0x10046580`), `10015cc8 lbz
r0,0x46(r28)`, `10015ce0..d58` (re-arm: draws at `10015d00` delay, `10015d14` volley,
`10015d30` rate; `10015d3c lbz r0,0x48(r28) … lwz r3,0x4c(r28) … stw r3,0xc4(r30)`)]

Timing consequences (exact, from the above): within a volley consecutive requests are
`max(d,1)` ticks apart (a countdown of 0 is not decremented but is re-tested only next tick).
After a re-arm at tick A the first request comes at `A + max(d,1)`. For the volley armed by
`FUN_10017cb0` the countdown starts with the first executor call after entry; when the state
change itself happened earlier in the same `FUN_10033850` pass (timer step 4 or a rule — both
precede the executor), a delay of 0 or 1 issues the first request **on the entry tick**.
Re-arm is measured from the previous arm, not from volley completion; if a volley lasts longer
than `rate` the next one is armed on the tick after it completes. [HIGH — derived from the
listing; caller order in `FUN_10033850` dump lines 237–307]

### 2.4 Rotation gate `FUN_10017150 @ 10017150`
If the state's `stateDoRotateToTarget` (0x303) is FALSE: entity +0xc1 = 0, nothing else.
Otherwise: decrement +0xc4 toward 0; rotation (`FUN_100172d0`, rotate sprite frame toward the
target point +0x11c/+0x120 every `stateFrameDelay` ticks) is suppressed while +0xc4 > 0 or
while any set with `PauseAnyRotationWhileSpawning` is mid-volley (`0 < remaining <
volleySize`). Shipped data: `PauseAnyRotation…` TRUE in 0 of 532 sets, `TimeToPause…` ≠ 0 in 0
sets (Python census over `$W/data/Game/unde/*.txt`), so this path is inert in the stock game.
[MED — decompile + listing offsets `1001725c lbz r0,0x48(r25)`, `10017268/74 lwz …,0x8/0xc(r3)`;
`FUN_100172d0` body not fully read]

### 2.5 Where a request goes (position, heading) — inside `FUN_10015b40`
Copy template (§1.1), `req.unit = Spawn_ID`, unit def `u = FUN_1003d550(Spawn_ID,
entity+0x98)` (spawner's unit cache, then global list; may be 0 → `FUN_10033220` looks it up and
prints "ERROR: Couldn't get the Unit…" if missing). If `u` exists and `u.terrainEffect` (0x132)
is set, the request is made only when the spawner is **not** stationary (+0x13c == 0) **and**
has terrain effects (+0x13d ≠ 0). [HIGH — `10015d8c lbz r0,0x132(r29)`, `10015d98 lbz
r0,0x13c(r30)`, `10015da4 lbz r0,0x13d(r30)`]

Let `s = entity+0x84` (scale) and `scaled = (s ≠ 1.0 && u && u.adjustInitialLocForOwnerScale
(0x12e))`; `X, Y` = `XOffset/YOffset` (ints, 0x24/0x28):
- `AdjustOffsetForUnitRotation` (0x44) FALSE:
  - `AbsoluteCoordinates` (0x45) FALSE: `pos = spawner + (scaled ? (X·s, Y·s) : (X, Y))`.
  - `AbsoluteCoordinates` TRUE: `pos = (X, Y)` — screen coordinates (y relative to the visible
    top; the template's +0x0c = 0 means no map conversion). The scaled sum is computed first and
    then overwritten.
- `AdjustOffsetForUnitRotation` TRUE (Absolute ignored): `h = FUN_100161c0(spawner)` = facing
  from the sprite frame (`numDirections == 1 ? frame·(360/framesPerDir) : (frame/framesPerDir)·
  (360/numDirections)`); if `SetHeading` (0x51) `hd = h + HeadingDegrees` (one `−360` if > 359).
  With `c = FUN_10042ee0(h)`, `n = FUN_10042f00(h)` and `(X', Y') = scaled ? (X·s, Y·s) : (X, Y)`:
  `dx = trunc(X'·c − Y'·n)`, `dy = trunc(X'·n + Y'·c)`; `pos = spawner + (dx, dy)` (note: the
  rotation uses the facing **without** HeadingDegrees).
- `req.heading(+0x10)` = `hd` in the rotated+SetHeading case, else `HeadingDegrees`;
  `req+0x0d` = `SetHeading`; owner = spawner (+0x20/+0x24); player = spawner +0xd8; stationary /
  terrain = `StationaryOption` (0x58) / `TerrainEffectsOption` (0x59). Then
  `FUN_10033220(&req, 0, u)`.
[HIGH for the arithmetic — listing `10015e18 lbz r0,0x44(r28)`, `10015e24 lbz r0,0x45(r28)`,
`10015e40 lfs f0,0x8(r27)` (1.0 at `0x100d6c8c+8`) `fcmpu … f5=0x84(r30)`, `10015e5c lbz
r0,0x12e(r29)`, `10015f34..74` (absolute: `fsubs` of the int→float magic only), `10015f80 bl
0x100161c0`, `10015f88 lbz r0,0x51(r28)` … `cmpwi r19,0x167` … `subi r19,r19,0x168`,
`10016070..100160f0` (`fmsubs f3,f4,f31,f3` = X·c − Y·n, `fmadds f0,f2,f1,f0` = X·n + Y·c,
`fctiwz` both), `10016140..88`. MED that `FUN_10042ee0`/`FUN_10042f00` are cos/sin (empty
decompiles = table lookups; the rotation form fixes which is which only up to that naming)]

### 2.6 Key → executor behaviour (closes NOT-RESOLVED #20)
| key (record off) | behaviour | label |
|---|---|---|
| `stateSpawnSetName_STR` 0x00 | label only; never read by init or executor | HIGH (no load of +0x00 in either listing) |
| `Spawn_ID` 0x20 | unit requested; `none` → set inert | HIGH |
| `XOffset/YOffset` 0x24/0x28 (INT) | offset from spawner, or absolute screen pos, or rotated offset (§2.5) | HIGH |
| `RateMin/Max` 0x2c/0x30 | ticks between volley **arms**; drawn at entry and at each re-arm; < 0 disables | HIGH |
| `NumInVolleyMin/Max` 0x34/0x38 | requests per volley (each request = one whole group of the unit); ≤ 0 at entry disables | HIGH |
| `DelayBetweenEntitiesMin/Max` 0x3c/0x40 | countdown before each request, redrawn after each; effective gap `max(d,1)` | HIGH |
| `AdjustOffsetForUnitRotation` 0x44 | rotate offset by spawner facing; ignores Absolute | HIGH |
| `_AbsoluteCoordinates` 0x45 | offset = screen position | HIGH |
| `RepeatSpawns` 0x46 | FALSE → one volley per state entry | HIGH |
| `Don'tSpawnOffscreen` 0x47 | cancel a whole volley if spawner off screen at its start | HIGH |
| `PauseAnyRotationWhileSpawning` 0x48 | suppress rotate-to-target mid-volley; raise +0xc4 at re-arm | MED |
| `TimeToPauseRotationAfterSpawning` 0x4c | +0xc4 countdown (set at entry for every set, at re-arm only with 0x48) | HIGH (writes) / MED (effect) |
| `SpawnIfFleeing` 0x50 | without it a fleeing spawner's sets freeze | HIGH |
| `SetHeading` 0x51 / `HeadingDegrees` 0x54 | members get this heading (+ facing if rotated) instead of the unit's default (§3.2) | HIGH |
| `_StationaryOption` 0x58 | members stationary: zero velocity, no speed draw | HIGH |
| `_TerrainEffectsOption` 0x59 | members' terrain-effects flag (+0x13d) | HIGH (write) / LOW (consumer) |
Shipped census (532 sets): Absolute 144, Rotation 73, Repeat 218, Don'tSpawnOffscreen 52,
SetHeading 78, SpawnIfFleeing 2, TerrainEffects 16, Stationary 0, volley > 1 in 80, delay > 0 in
121, one set with `NumInVolleyMin ≤ 0` (never fires). [HIGH — Python over decoded files]

## 3. Request → group → members (refinements to waves-and-enemies.md §4)

### 3.1 `FUN_10033220` order of checks
`n = FUN_100369f0(u)` (size and appearsPercent draws) **first**; only then the refusals:
`canBeSpawnedOnlyWhenPlayersActive` (needs `DAT_100e0214 && FUN_10006110() &&
!FUN_10005cf0()`), `doNotSpawnIfTypeAlreadyExists` (`FUN_10036af0` = first live entity of that
unit), cap `live + n < 1001`. So a refused request **still consumes its size/appears draws**.
Then `deleteExistingEntitiesOfThisTypeOwnedByPlayer` (0x119, only if req player ≠ −1 →
`FUN_10036be0`: every entity of that unit owned by that player is removed via
`FUN_10036120(g,e,0,0)`), tracked-unit debug print (`FUN_100377f0`), group creation (§1.2), y
conversion (§1.1), members (`FUN_10035bf0`), entry notice (`FUN_100380e0`, §8). [HIGH for the
order — listing `100332c0 bl 0x100369f0` precedes `100332cc lbz r0,0x112(r27)` (= unit+0x12a);
MED for the player-active predicate's callees]
Group size: `R(min', max)` with `min' = min(max(numInGroupMin,1), numInGroupMax)` (args in
r3/r4 confirmed: `10036a04 lwz r3,0x194(r3); lwz r4,0x198(r27) … bl 0x10046580`), no draw when
equal; then per member `R(0,100)` unless `appearsPercent` ∈ {0,100}. [HIGH — ⚑ corrected: the
bank said MED "arguments dropped"]

### 3.2 Per-member creation `FUN_10035cd0` — exact order (replay)
1. Allocate from the pool, append to the group list, `FUN_100144a0` (spawn records).
2. Owner/player/ids/flags; shields by sector (waves-and-enemies.md §3).
3. Heading: if the heading flag (`param_6` = req+0x0d ? 1 : unit `initialHeadingSetInEditor`)
   is clear → +0x138 = `initialHeading`; else `h = heading arg` (req+0x10 if req+0x0d, else
   req+0x18) and, if `initialHeadingTolerance ≠ 0`, `h += R(−(tol/2), tol/2)` (tol/2 truncated
   toward 0), wrap once, out-of-range → 0. **Draw D1 (int, conditional).**
4. +0x13c/+0x13d from the request; `FUN_10037930` placement (**D2**: int x then int y, or int
   heading + optional float radius — waves-and-enemies.md §4).
5. `FUN_10037b50(group, e, flag, h, owner, f1 = req+0x28)` (**D3/D4**, §3.3).
6. `FUN_100146f0(e, 1, state 0)`: timer `R(OnTimerMin,Max)` → sprite frame `R(FrameMin,Max)`
   (only if the unit is not a pickup and not `initialHeadingSetInEditor`) → scale tolerance draw
   (if `initialScalePercentTolerance ≠ 0`) → flee point (float draws, if `stateFlee_ID ≠ none`)
   → `FUN_10017cb0` (per set: rate, volley, delay). (**D5…**)
7. `FUN_10033600` (no draws); group spawn-in delay: `R(groupDelayMin, groupDelayMax)` added to the
   running sum (args `10035fb8 lwz r3,0x19c(r31); lwz r4,0x1a0(r31)`), no draw when equal; the
   **first** member also gets a draw (sum starts at 0 in `FUN_10035bf0`, `10035c20 stw
   r0,0x38(r1)`).
8. If state 0 has `stateCyclicMotion` (0x34a): `FUN_10037ed0` (§3.4).
[HIGH — listing `10035ec8..10035f1c` (D1: `rlwinm r0,r3,0x1,0x1f,0x1f; add; srawi r4,r0,0x1;
neg r3,r4; bl 0x10046580`), `10035f38 bl 0x10037930`, `10035f44 lfs f1,0x28(r22) … bl
0x10037b50`, `10035f74 bl 0x100146f0`, `10035fb4 bl 0x10033600`, `10035fc8 bl 0x10046580`,
`10035ffc lbz r0,0x34a(r20) … bl 0x10037ed0`; step 6 internal order now also listing-checked
(HIGH): `FUN_100146f0` `100148dc bl 0x10046580` timer → `100149f0 bl 0x10046580` frame →
`10014b14 bl 0x10046580` scale tolerance → `10014c48…10014d5c` 4× `bl 0x10042b80` (velocity set-up,
no draws) → `10014d74 bl 0x10033600` → `10014d90 bl 0x10017510` (flee point: the float/int draws)
→ `10014dc0 bl 0x10017cb0` (spawn sets)] ⚑ corrected (review wave 1, 2026-10-03) #M10: step 6 order was "from the decompile, MED".
⚑ corrected: engine-loop.md §9 lists the per-entity order as placement → speed → heading
tolerance → state-0 timer; it misses D1 (before placement), the other state-0 draws, the
group-delay draw and `FUN_10037ed0`, and the `FUN_10037b50` tolerance draw happens only in its
default-heading branch (§3.3).

### 3.3 Initial motion `FUN_10037b50 @ 10037b50` (MED → HIGH)
Args `(group r25, entity r30, flag r26, heading r28, owner r27, mult f30)`.
- Entity stationary (+0x13c): velocity +0x10/+0x14 and copies +0x108/+0x10c, +0x110/+0x114 =
  (0,0) (`0x100d7194` = 0.0, 0.0). **No draws.**
- Else `speed = F(initialSpeedMin 0x26c, initialSpeedMax 0x270)` (float draw unless equal), then:
  1. `flag` or `initialHeadingSetInEditor` (0x124): velocity = `FUN_10042b80(norm(heading),
     speed)` (heading already tolerance-adjusted in §3.2 step 3). No draw.
  2. else `initiallyHuntsClosestPlayer` (0x11f): target = closest active player
     (`FUN_10005ed0`), default `(VisibleGameWidth·0.5, 0.0)`, and if no player
     `(VisibleGameWidth·0.5, −100.0)`; velocity = unit(target − pos)·speed (`FUN_10042bf0`);
     +0x138 untouched. No draw.
  3. else `doBurst` (0x122) / `doImplode` (0x123): `d = pos − groupPos` (burst) or
     `groupPos − pos` (implode); `(ux,uy) = FUN_10042bf0(d)`; velocity = `(ux·speed,
     −(uy·speed))` (**y negated**); +0x138 = `FUN_10042cd0(velocity)` normalised. No draw.
  4. else (default): `h = useOwnerHeading (0x129) && owner ? FUN_100161c0(owner) :
     initialHeading`; only when `h` came from `initialHeading` and `initialHeadingTolerance ≠
     0`: `h += R(−(tol/2), tol/2)`, wrap, out-of-range → 0. +0x138 = h; velocity =
     `FUN_10042b80(norm(h), speed)`.
- If `mult ≠ 1.0` velocity ·= mult. Then +0x100/+0x104 = +0x108/+0x10c = velocity,
  +0x110/+0x114 = 0.0.
[HIGH — listing `10037b70 lbz r0,0x13c(r4)`, `10037bbc lfs f1,0x26c(r29); lfs f2,0x270(r29);
bl 0x100465e0`, `10037bcc rlwinm. r0,r26` / `10037bd8 lbz r0,0x124(r29)`, `10037be4 lbz
r0,0x11f(r29)`, `10037c0c lfs f2,0x0(r31)` (0.5) `10037c14 lfs f0,0x10(r31)` (0.0) `10037c3c lfs
f0,0x14(r31)` (−100.0), `10037c88/94 lbz r0,0x122/0x123(r29)`, `10037d28 fneg f0,f0`,
`10037d4c lbz r0,0x129(r29)`, `10037d9c..e04` (tolerance), `10037e58 lfs f0,0x18(r31)` (1.0);
table `0x100d7204` = 0.5, 0.7, 0.9, 32.0, 0.0, −100.0, 1.0, 1.4, 100.0 (code image)]
Caller traced: `FUN_10035cd0` only.

### 3.4 Cyclic-motion start velocity `FUN_10037ed0 @ 10037ed0`
`mag = R(0,1) ? 1.0 : 1.4`; `a = R(1,4)`; `f = R(1,100)/100.0`; `vx = a + f`; `if R(0,1): vx =
−vx`; `vy = R(1,4) + f` (same f); `if y > trunc(VisibleGameHeight)/4 (toward 0) && R(0,1): vy =
−vy`; `len = FUN_10042f20(trunc(vx²+vy²))` (sqrt); velocity = `(vx/len·mag, vy/len·mag)` →
+0x10/+0x14, +0x100.., +0x108..; +0x110/+0x114 = `0.2·vx/len`, `0.2·vy/len`. **5 draws + 1
conditional.** [HIGH — listing `10037efc li r3,0; li r4,1; bl 0x10046580`, `10037f20 li r3,1;
li r4,4`, `10037f40 li r3,1 … li r4,0x64`, `10037f6c lfs f0,0x20(r30)` (100.0), `10037f70..8c`
(0,1), `10037fa0..a8` (1,4), `10037fe4 li r3,0x37; bl 0x10020250` … `srawi r0,r0,0x2; addze`
… `fcmpo; ble` … `1003802c li r3,0; li r4,1`, `10038068 lfd f0,0x18(r31)` (0.2); MED that
`FUN_10042f20` = sqrt for inputs ≤ 0x3fff (table path not decompiled)]

## 4. Owner relations (state keys `LockToOwnerLoc` 0x32e, `LinkToOwnerLoc` 0x32f, `OrbitOwner` 0x330)
"Owner position" = the owner entity's position if the link (+0x140/+0x144) is valid, else the
owning player's position (`FUN_10006090(player,&pos)`) if +0xd8 ≠ −1, else nothing happens.
- Init `FUN_10033600 @ 10033600` (called at creation by `FUN_10035cd0`, and by `FUN_100146f0`
  on later state changes **only when the new state is not LockToOwnerLoc**): offset
  +0x124/+0x128 = 0, owner-last +0x12c/+0x130 = 0; if any of the three flags and an owner
  position exists: owner-last = owner pos; Orbit → offset = self − owner, radius +0xdc =
  `(float)trunc(dist(owner,self))`, angle +0xe0 = `FUN_10042ad0(trunc ox,oy,sx,sy)` normalised
  (`FUN_10043040`); Lock → offset = self − owner. [HIGH — listing `10033628..34` zeroing,
  `10033644/50/5c lbz r0,0x330/0x32e/0x32f`, `10033740 bl 0x10042e90; fctiwz; … stfs
  f0,0xdc(r31)`, `100337b8 bl 0x10042ad0; stw r3,0xe0(r31)`; the fcmpo/bge pairs compute
  self − owner on both branches]
- Lock `FUN_10037130`: if owner pos ≠ own pos → `pos = owner + offset`. [HIGH — `100371fc..214`
  `fadds f1,f3,f1` (owner.x + 0x124)]
- Link `FUN_10037230`: `pos −= (ownerLast − ownerNow)` (rides the owner's motion on top of its
  own), ownerLast = ownerNow. [HIGH — `100372d4..324`]
- Orbit `FUN_10037350`: if owner pos ≠ own pos: radius == 0.0 → `pos = owner + offset`; else
  `step = trunc(entity+0x10)`; step == 0 → `pos = owner + offset`; else angle += step (wrap
  0..359), `pos = owner + FUN_10042b80(angle, radius)`; then offset = self − owner. So the
  orbit's angular speed is the first velocity float, in **degrees per tick**. [HIGH for the
  code — `10037420 lfs f0,0xdc(r31)`, `1003743c lfs f0,0x10(r31); fctiwz`, `10037454..84`,
  `10037494 bl 0x10042b80`; MED for the meaning of entity +0x10 (movement reader)]
- Order per tick in `FUN_10033850`: Lock, then Link, then Orbit (each gated by its state flag),
  then the spawn-set executor. [HIGH — dump lines 298–307]
- Quirk: entering a Lock state by a state change keeps whatever +0x124/+0x128 hold (0 after any
  non-owner state, since `FUN_10033600` zeroes them) → such an entity snaps onto its owner.
  [MED — `FUN_100146f0` decompile branch]
- `FUN_10036930(e, owner, vis, scale, hits)`: copies owner visibility +0x68 (`useOwnersVisibility`
  0x327), scale +0x34/+0x84/+0x88/+0x8c (`useOwnersScale` 0x328) and hit-glow +0x74..+0x80
  (`visuallyReflectOwnerHits` 0x32c). [MED — decompile; caller args from `FUN_10033850`]

## 5. Removal, children, PERM (`FUN_10036610`, `FUN_10036120`)
`FUN_10036610 @ 10036610` (end of every `FUN_10033850` pass) — for every entity with +0xcb:
1. `includeInGroundAccuracyCount` (0x134) → live ground-target count `_DAT_100e0218 −= 1`
   (incremented in `FUN_10035cd0`).
2. `destructDrawToTerrain` (0x4b2) → +0x36 = 1, +0x35 = 0, +0x38 = `castsShadows`;
   `FUN_10012f20` (stamp into the terrain).
3. destroyed (+0xda) and state `destroyOwnerOnDestruction` (0x32d) and owner link valid →
   `FUN_10016300(owner, killer +0xd9, now)`.
4. `deletionSpawn_ID` (0x2dc) ≠ none and **not** destroyed and `FUN_10016880(e)` → request at the
   entity's position (owner = this entity, player = +0xd8).
5. `FUN_10036120(group, e, destroyed, killer ≠ −1)`; unlink; return to pool; if the group is now
   empty (and not PERM) free it and stop scanning it.
`FUN_10036120(group, e, destroyed, byPlayer) @ 10036120`: if e +0x13e: `destructDestroyChildren`
(0x4b0, only if destroyed) → `FUN_100363c0` (children = entities whose owner id +0x144 == e's
id with state `canBeDestroyedOnOwnerDestruction` 0x329 → removed as destroyed);
`destructDeleteChildren` (0x4b1) → `FUN_100364f0` (`canBeDeletedOnOwnerDeletion` 0x32a →
deleted). If destroyed: group kills +0xac += 1. If destroyed and byPlayer and not
pickup-collected (+0xca): `destructNumCoinsToRelease` (0x4a4) requests of `destructCoin_ID`
(0x4a8) at e; and if the group is not PERM and kills == size (+0xa4), one
`destructCoinOnGroupKill_ID` (0x4ac). If destroyed: `FUN_10016300(e, …)` (no-op if already
flagged). Then +0xcb = 1, live −= 1. [HIGH — listing `1003614c lbz r0,0x13e(r4)`, `10036164
lbz r0,0x4b0(r31); … bl 0x100363c0`, `10036178 lbz r0,0x4b1(r31); … bl 0x100364f0`,
`10036194..a4`, `100361c4 lbz r0,0xca(r26)`, `100361d0..84` coin loop, `10036294 lwz
r3,0x98(r25)` PERM, `100362ac lwz r24,0x4ac(r31)`, `10036368 bl 0x10016300`, `10036374 stb
r0,0xcb(r26)`]
Direct removers (call `FUN_10036120` at once): `FUN_10034b90(player)` (player gone: that
player's entities destroyed if 0x329 else deleted if 0x32a; caller `FUN_10027e50`),
`FUN_10034de0(id)` (delete entity by id; callers `FUN_10027e50`, `FUN_10029fe0`),
`FUN_10036be0(unit, player, destroyed)`. `FUN_10034ce0(now, id)` finds entity `id` (serial
+0x9c) and calls `FUN_10014670(entity, now)`, which enters the first state flagged
`UseThisStateOnWeaponPowerupRelease` (state +0x355) with `now` as the state-start time (4th
argument of `FUN_100146f0`, stored at +0xa4); callers weapon handler `FUN_1003b3c0`,
`FUN_1003c0d0` (pass the game time). [HIGH — listing `10034d8c lwz r0,0x9c(r3); cmpw r0,r25`,
`10034d98 or r4,r24,r24; bl 0x10014670` (r24 = arg 1); `FUN_10014670` dump `FUN_100146f0(param_1,
0, state+0x49c, param_2, …)`, `FUN_100146f0` dump `*(param_1+0xa4) = param_4`] ⚑ corrected (review wave 1, 2026-10-03) (conflict):
was "`FUN_10034ce0(stateName, id)` switches entity `id` to a named state" [MED];
weapons-projectiles.md §2.3 had it right.

## 6. Rule condition callees (closes NOT-RESOLVED #22)
- `FUN_10034ee0(unitID, pos, range)` — "Is Tracking Player": true iff some entity of that unit
  (unit +0x04) has finished its spawn-in delay (+0xb0 ≤ 0), has +0xc1 set, and (range == 0 or
  `dist(pos, entity) ≤ range`, inclusive). +0xc1 = 1 only while the entity's state has
  `stateDoRotateToTarget` and (not fleeing) it has a target player (+0x118 ≠ −1)
  (`FUN_100172d0` `1001731c..48`); cleared when the state does not rotate. `unitID == none`
  → false. [HIGH — listing `10034f04 subis r0,r21,0x6e6f; cmplwi r0,0x6e65`, `10034f98 lwz
  r0,0x4(r4); cmpw r0,r21`, `10034fa4 lwz r0,0xb0(r3); cmpwi; bgt`, `10034fb0 lbz r0,0xc1(r3)`,
  `10034fbc cmpwi r23,0x0; beq →true`, `10034fd4 bl 0x10042e90 … 10035000 fcmpo cr0,f1,f2;
  cror eq,lt,eq` (dist ≤ range)]
- `FUN_10035070` — "Is Active": the same without the +0xc1 test (any spawned entity of that
  unit, within range if range ≠ 0, inclusive). [HIGH — same listing shape, `10035184 fcmpo;
  10035188 cror eq,lt,eq`, no `lbz 0xc1`]
- `FUN_10017ef0(entity, range, …)` — "Within Range of a Player": `FUN_10005d40` (distance to the
  nearest player, unread) and `range ≠ 0` and `dist < range` (**strict**). [HIGH for the test —
  `10017f24 cmpwi r30,0x0`, `10017f50 fcmpo cr0,f2,f0; bge → false`; MED for `FUN_10005d40`]
- Distance = `FUN_10042e90` = `FUN_10042f20(trunc(dx²+dy²))` — the squared distance is
  truncated to int before the root. [MED — decompile]

## 7. `FUN_10036cf0` (⚑ corrected; was "state spawn sets executor" LOW)
Entity-vs-entity collision with mutual `damage_FLOAT` (0x274) through `FUN_10014f10`, called
from `FUN_10033850` for entities whose state `Collides`. Covered by the damage reader
(damage-health-death.md); one detail from my listing for their cross-check: when the struck
entity B has `passHitsToOwner` (0x32b), the redirect goes to the **attacker A's** owner
(`10037064 lbz r0,0x32b(r3)` (B's state) then `10037074 lwz r5,0x140(r17)` and `100370b4 lwz
r3,0x140(r17)`, r17 = A). That looks like an original copy-paste bug. [HIGH for those lines]
**Consequence** (traced in the fix pass): player shots carry no owner (request template
`0x100ecd14` +0x20/+0x24 = 0, not written by `FUN_1003c4f0`/`FUN_1003c7a0`), so the redirect
never fires and a turret or bubble with `passHitsToOwner` hit by a player shot takes the damage on
its own shields; only ramming reaches the owner (bosses.md §3.5). ⚑ corrected (review wave 1, 2026-10-03) #I1

## 8. Remaining range functions
| function | role | label |
|---|---|---|
| `FUN_10032e60` | level start (caller `FUN_100064d0`): clear entity-limit flag, `FUN_10038450`, free groups (`FUN_10035b00`), new active list, clear and recreate the "shown once" notice list `_DAT_100e0224`, group ids 20000000, entity ids 1000, ground count 0, create PERM group, `FUN_10035900(level)` | HIGH (listing constants §1.2) |
| `FUN_10035580` | number of active groups | MED |
| `FUN_100355b0` | debug: integrity check / dump of all groups and entities (magic 0x499602d2; "Permanent Entity Group…"); no direct callers | MED |
| `FUN_10035810` | free the pending level-object list `_DAT_100e022c` | MED |
| `FUN_10035b00` | free all groups and the active list | MED |
| `FUN_10036ab0` | owner link valid ({ptr,id}, not deleted) | HIGH (decompile = listing pattern in 7130/7230/7350) |
| `FUN_10036af0` | first live entity of a unit (`doNotSpawnIfTypeAlreadyExists`) | MED |
| `FUN_10037580` | pickup effect by `pickup_Type_ID` (`grnd`/`air ` weapon power-up via `FUN_10027dd0`, `coin`, `exli`, `shie`, `mult`); returns 0 if refused | MED |
| `FUN_100377f0` | debug "Tracked Entity … Spawned [by …]" notice when the spawned unit == `_DAT_100e020c` | MED |
| `FUN_100380e0` | entry notice: if `entryNotice_STR ≠ none` and (not `displayNoticeOnceOnly` (0x120) or not yet shown) → queue with `entryNoticeDelay` (0x1b8) and `entryNoticeSound` block (0x424..) via `FUN_100181e0` | MED |
| `FUN_10038230` / `FUN_100382f0` | notice-shown list lookup / add (63-char copy) | MED |
| `FUN_10038390` / `FUN_10038450` / `FUN_10038540` / `FUN_100385d0` / `FUN_10038810` | entity pool: build / reset / dispose / allocate / free (§1.3) | MED |
| `FUN_10039100` | static init of the level request template `0x100eb41c` (⚑ corrected #M3: was `0x100eb420`) and other templates (caller `FUN_10000000`) | LOW |
| `FUN_100391f0` / `FUN_10039230` | load / unload "Player Definition" (`FUN_1003a870`/`FUN_1003a900`, `FUN_10039280`/`FUN_10039c00`) — start of the G_PlayerDefinitions span, not EntityGroup | LOW |
| `FUN_10033090`, `FUN_10033850`, `FUN_100345f0` | excluded (other readers) | not read |
| `FUN_100351f0`, `FUN_100352f0`, `FUN_100353e0`, `FUN_10035900`, `FUN_10037930` | as in the bank (glanced: 352f0 tests `includeInAirAccuracyCount` 0x133, 353e0 0x134) | unchanged |
"Not read" in range: none beyond the three excluded functions.

## 9. RNG draw order (film replay)
| function | draws, in order | notes |
|---|---|---|
| `FUN_100369f0` | `R(min',max)` size; then per member `R(0,100)` (appears ∉ {0,100}) | before any refusal in `FUN_10033220` |
| `FUN_10035cd0` per member | D1 heading tol (int, cond.) → `FUN_10037930` → `FUN_10037b50` → `FUN_100146f0` state 0 → group delay `R(gdMin,gdMax)` → `FUN_10037ed0` (cond.) | members in order; requests inside `FUN_10036120`/`FUN_10015b40` nest here |
| `FUN_10037930` | rect: int x, int y (each only if its range open); radial: `R(0,359)`, then `F(0,|xMax|)` if randomise | bank §4 |
| `FUN_10037b50` | `F(speedMin,speedMax)` (skipped if stationary) → `R(−tol/2,tol/2)` only in the default-heading branch | |
| `FUN_10037ed0` | `R(0,1)`, `R(1,4)`, `R(1,100)`, `R(0,1)`, `R(1,4)`, [`R(0,1)` if y > H/4] | |
| `FUN_100146f0` (out of range) | timer, frame, scale tol, flee (inside `FUN_10017510`), then `FUN_10017cb0` | HIGH — listing `100148dc`, `100149f0`, `10014b14`, `10014d90`, `10014dc0` (⚑ corrected #M10: was MED) |
| `FUN_10017cb0` per set | rate → volley → delay | |
| `FUN_10015b40` per set | in-volley: delay; re-arm: **delay → volley → rate** (reverse of entry order); a request's own draws happen immediately, before the next set | |
| `FUN_10036120` | coin requests, then group-kill coin request (each a full `FUN_10033220`) | |
| `FUN_10032e60`, §4–§7 functions, `FUN_10034ee0`, `FUN_10035070`, `FUN_10017ef0` | none | |
Observation outside scope (for the damage/level reader): `FUN_10033850` draws `R(0x2f0,0x2f4)`
(`state_MotionBlur_Min/MaxTimeBetween`) every tick for each entity whose state has
`MotionBlur_Required` and a sprite (dump lines ~382–385). [MED — decompile only]

## Worked example — `Level 7 - Start 1 [07s1]` in `Level 12 [le12]`
Data (`grep` of `$W/data/Game/unde/Level 7 - Start 1[07s1].unde.txt`, `Shuriken[shur]…`,
`leve/Level 12[le12].leve.txt`): placement `07s1 grnd x 210 y 2892 heading 0`, not stationary.
07s1: group 1–1, groupDelay 0–0, offsets 0, speed 0–0, heading 0 ± 0. States (exec order):
S0 "Wait Until Pausing" timer 180; S1 "Pause Scrolling, Wait" 20–30 (pause); S2 "Pause, Spawn
Shurikens" 300 (pause, set A); S3 "Pause" 220; S4 "Spawn Shurikens" 500 (set A); S5 "Pause,
Wait, Delete" 130–140 → Delete. Set A: `shur` at (208, −100), Absolute TRUE, Rotation FALSE,
Rate 120–125, Volley 1–1, Delay 0–0, Repeat TRUE, Offscreen FALSE, SetHeading FALSE.
Shuriken: group 10–11, groupDelay 9–16, appears 100, offsets x ±60 y ±20, randomise FALSE,
heading 180 ± 0, speed 5–7, not hunting/burst, `canBeSpawnedOnlyWhenPlayersActive` TRUE;
state 0 "Move South, Wait Range, RULE" timer 50–60, frames 0–5, scale tol 0, flee none, no sets.

1. The controller's own spawn (scroll row `top − 64 == 2892`) costs **0 draws** (every range
   closed). Its state start = creation tick P.
2. P+180: S1, one draw `R(20,30) = a`; scrolling stops. T0 = P+180+a: S2 entered by the timer
   step; `FUN_10017cb0`: rate r1 = `R(120,125)` (1 draw), volley 1, delay 0, remaining 1.
3. Same tick T0, executor: remaining 1, delay 0 → **request 1 at T0**. Then re-arm at T0+r1
   (draw r2), request 2 at T0+r1+1; re-arm at T0+r1+r2 (draw r3), request 3 at T0+r1+r2+1 ∈
   [T0+241, T0+251]; the next arm would be ≥ T0+360 > T0+300, when S3 replaces the state (S3 has
   no sets, +0xc3 = 0). → **3 Shuriken groups** in S2.
4. S4 at T1 = T0+520: requests at T1, T1+r1+1, … ; the k-th at `T1 + Σ_{i<k} r_i + 1`. The 5th
   needs `Σ4 r ≤ 498` (the state ends at T1+500, before that tick's executor): 4 or 5 groups,
   5 except when Σ4 ∈ {499, 500} (5 of 1296 equally likely combinations). S5 at T1+500 (draw
   `R(130,140) = b`), Delete at T1+500+b; scrolling resumes. Total pause ≈ a + 300 + 220 + 500
   + b = 1170–1190 ticks.
5. Each request (screen pos (208, −100), owner = controller, player −1, heading arg unused):
   draws `R(10,11) = n`; then for each member k: (D1 none — flag = shur
   `initialHeadingSetInEditor` FALSE) → placement radial (both ranges open): `R(0,359) = h_k`,
   pos = (208 + cx(h_k)·60, −100 + cy(h_k)·20) (on the ellipse; randomise FALSE so no float) →
   speed `F(5.0,7.0)` → default heading 180, tol 0 (no draw) → state 0: timer `R(50,60)`, frame
   `R(0,5)` → group delay `R(9,16)` added to the running sum. **= 1 + 5n draws per group (51 or
   56)**, consumed even if no player is active (the size draw precedes the refusal; then members
   are not created and only the size draw happens).
6. Members appear one at a time: member k becomes live after `Σ_{j≤k} R(9,16)` ticks (first
   after 9–16), i.e. 10–11 Shurikens trickle in over 90–176 ticks, each moving at heading 180
   with speed 5–7 from its ellipse point.
[HIGH for the executor arithmetic and draw counts — §2–§3 listings; MED for heading 180 =
"south" (FUN_10042b80 axis convention unread); the shipped Rate/Volley values are file values]
⚑ corrected: waves-and-enemies.md §4 described this as "emits a Shuriken group … every ~2 s for
300 ticks … for 500 more"; the exact count is 3 groups in S2 and 5 (rarely 4) in S4, the first
of each on the entry tick, each group 10–11 Shurikens staggered 9–16 ticks.

## NOT RESOLVED (this file)
1. Possible double bookkeeping: entities removed by a direct remover (`FUN_100363c0`,
   `FUN_100364f0`, `FUN_10034b90`, `FUN_10034de0`, `FUN_10036be0`) get `FUN_10036120` once
   immediately and — since it sets +0xcb — again in the reaper `FUN_10036610`, which would
   double the kill count, coin requests and the `+0xa8` decrement. Settle by checking whether
   `FUN_10016880`/`FUN_10038810` or list removal guards it, or by a runtime trace.
2. `FUN_10042ee0`/`FUN_10042f00`/`FUN_10042b30`/`FUN_10042b80` trig tables: which is cos/sin and
   the heading axis convention (0° = north? 180° = south?). Settle by dumping the table the
   helpers index (code image) and one call with a known heading.
3. Entity +0x10/+0x14 (velocity vs speed/heading pair) — needed for the orbit angular speed
   (§4). Owned by the movement reader (`FUN_10015930`/`FUN_10015280`).
4. Same-tick processing of entities spawned during `FUN_10033850` (groups appended to the active
   list are reached in the same pass since the loop re-reads the count; PERM-group children are
   appended behind the current index). Exact effect on the first update tick is unverified.
5. ~~`FUN_100146f0` internal draw order (timer → frame → scale tol → flee → spawn sets) is from the
   decompile only~~ → listing-confirmed (§3.2 step 6) ⚑ corrected (review wave 1, 2026-10-03) #M10. Still open: the
   scale-tolerance draw's arguments are dropped by the decompiler (presumably `R(−tol/2, …)`).
6. `FUN_10005ed0` (closest active player) and `FUN_10005d40` (nearest-player distance) bodies.
7. Consumer of entity +0x13d (terrain-effects option) and `FUN_10016880` (deletion-spawn gate).
8. `req+0x28` speed multiplier: which callers pass a value ≠ 1.0 (weapon launcher `FUN_1003c4f0`?).

## Role-table rows (for merge)
| `FUN_10015b40` | G_Entity.cc (span) | ⚑ corrected — **state spawn-set executor** (+ rotation gate call): per set volley arm/countdown/issue, positions (absolute / relative / rotated, owner scale), request to `FUN_10033220` (was listed among movement executors, NOT-RESOLVED #19) | HIGH | disasm (spawn-and-waves.md §2.3, §2.5) |
| `FUN_10017cb0` | G_Entity.cc (span) | ⚑ corrected — state-entry spawn-set init: rate, volley, delay draws; first volley armed at entry; +0xc4 = TimeToPause (was MED "init state spawn-set timers") | HIGH | disasm §2.2 |
| `FUN_10017150` | G_Entity.cc (span) | rotate-to-target gate: +0xc4 countdown, PauseAnyRotation mid-volley block, then `FUN_100172d0` | MED | read §2.4 |
| `FUN_100172d0` | G_Entity.cc (span) | rotate sprite frame toward target point (+0x11c/+0x120) every FrameDelay; sets +0xc1 tracking flag | MED | read §6 |
| `FUN_100144a0` | G_Entity.cc (span) | assign unit to entity: unit cache +0x98, per-state spawn-record lists +0x19c (0x18 each), +0x13e | MED | read §2.1 |
| `FUN_10016bd0` | G_Entity.cc (span) | spawner on screen: 0 ≤ x ≤ VisibleGameWidth, 0 ≤ y ≤ VisibleGameHeight | HIGH | disasm §2.3 |
| `FUN_100161c0` | G_Entity.cc (span) | facing in degrees from sprite frame / directions | HIGH | read + disasm use §2.5 |
| `FUN_10017ef0` | G_Entity.cc (span) | rule "within range of a player": nearest-player dist < range (strict), range ≠ 0 | HIGH | disasm §6 |
| `FUN_10036cf0` | G_EntityGroup.cc | ⚑ corrected — entity-vs-entity collision (player side vs enemy side, same layer) with mutual `damage_FLOAT` via `FUN_10014f10`; passHitsToOwner bug (B's flag redirects to A's owner) (was LOW "state spawn sets executor") | HIGH | disasm §7 |
| `FUN_10034ee0` | G_EntityGroup.cc | rule "Is Tracking Player": live entity of unit with +0xc1, dist ≤ range (0 = any) | HIGH | disasm §6 |
| `FUN_10035070` | G_EntityGroup.cc | rule "Is Active": live entity of unit, dist ≤ range (0 = any) | HIGH | disasm §6 |
| `FUN_10036610` | G_EntityGroup.cc | per-tick reaper of +0xcb entities: ground count, draw-to-terrain, destroy owner, deletion spawn, `FUN_10036120`, free entity/empty non-PERM group | HIGH | disasm §5 |
| `FUN_10036120` | G_EntityGroup.cc | remove entity from group: destroy/delete children, kill count, destruct coins, group-kill coin (non-PERM), destruction, live count; returns empty-non-PERM | HIGH | disasm §5 |
| `FUN_100363c0` | G_EntityGroup.cc | destroy children with canBeDestroyedOnOwnerDestruction | MED | read §5 |
| `FUN_100364f0` | G_EntityGroup.cc | delete children with canBeDeletedOnOwnerDeletion | MED | read §5 |
| `FUN_10034b90` | G_EntityGroup.cc | player gone: destroy/delete entities owned by that player | MED | read §5 |
| ⚑ corrected `FUN_10034ce0` | G_EntityGroup.cc | find entity by serial → `FUN_10014670(entity, now)` (enter its UseThisStateOnWeaponPowerupRelease state) | HIGH | listing `10034d8c`, `10034d98`; callers `FUN_1003b3c0`, `FUN_1003c0d0` — ⚑ corrected (review wave 1, 2026-10-03) (conflict): was "set named state on entity by id" MED |
| `FUN_10034de0` | G_EntityGroup.cc | delete entity by id | MED | read §5 |
| `FUN_10036be0` | G_EntityGroup.cc | remove entities of unit owned by player (deleteExisting…) | MED | read §3.1 |
| `FUN_10036af0` | G_EntityGroup.cc | first live entity of a unit | MED | read |
| `FUN_10036ab0` | G_EntityGroup.cc | owner link valid | MED | read §1.3 — ⚑ label audit (review wave 1) |
| `FUN_10036930` | G_EntityGroup.cc | copy owner visibility / scale / hit glow | MED | read §4 |
| `FUN_10033600` | G_EntityGroup.cc | owner-relative init: offset, orbit radius/angle, owner last pos | HIGH | disasm §4 |
| `FUN_10037130` | G_EntityGroup.cc | LockToOwnerLoc: pos = owner + offset | HIGH | disasm §4 |
| `FUN_10037230` | G_EntityGroup.cc | LinkToOwnerLoc: pos += owner displacement | HIGH | disasm §4 |
| `FUN_10037350` | G_EntityGroup.cc | OrbitOwner: angle += trunc(+0x10) deg/tick at radius | HIGH | disasm §4 |
| `FUN_10037b50` | G_EntityGroup.cc (span) | ⚑ corrected — initial motion: stationary / supplied heading / hunt closest / burst-implode (y negated) / default heading ± tolerance; speed F(min,max); × req multiplier (was MED) | HIGH | disasm §3.3 |
| `FUN_10037ed0` | G_EntityGroup.cc | cyclic-motion start velocity (5–6 int draws) | HIGH | disasm §3.4 |
| `FUN_10032e60` | G_EntityGroup.cc | level start: reset groups, notice list, id counters, create PERM group, pending list | HIGH | disasm §8 |
| `FUN_100355b0` | G_EntityGroup.cc | debug integrity check / dump (no direct callers) | MED | read |
| `FUN_10035580` | G_EntityGroup.cc | active group count | MED | read |
| `FUN_10035810` | G_EntityGroup.cc | free pending level-object list | MED | read |
| `FUN_10035b00` | G_EntityGroup.cc | free all groups | MED | read |
| `FUN_10037580` | G_EntityGroup.cc | apply pickup by pickup_Type_ID | MED | read |
| `FUN_100377f0` | G_EntityGroup.cc | debug tracked-entity spawn notice | MED | read |
| `FUN_100380e0` | G_EntityGroup.cc | entry notice (once-only list, delay, sound) | MED | read |
| `FUN_10038230` | G_EntityGroup.cc | notice already shown? | MED | read |
| `FUN_100382f0` | G_EntityGroup.cc | add shown notice | MED | read |
| `FUN_10038390` | G_EntityGroup.cc | build entity pool (1000 × 0x1ec) | MED | read |
| `FUN_10038450` | G_EntityGroup.cc | reset entity pool flags | MED | read |
| `FUN_10038540` | G_EntityGroup.cc | dispose entity pool | MED | read |
| `FUN_100385d0` | G_EntityGroup.cc | allocate pooled entity | MED | read |
| `FUN_10038810` | G_EntityGroup.cc (span) | free pooled entity | MED | read |
| `FUN_10039100` | ~after G_EntityGroup | static init of request templates | LOW | read |
| `FUN_100391f0` | ~after G_EntityGroup | load Player Definition | LOW | strings |
| `FUN_10039230` | ~after G_EntityGroup | unload Player Definition | LOW | strings |
| `FUN_100369f0` | G_EntityGroup.cc | ⚑ corrected — size draw args confirmed `R(min',max)` (was "arguments dropped … MED" in waves §4) | HIGH | disasm §3.1 |

## INDEX updates (for merge)
- **#20 closed** — spawn-set executor is `FUN_10015b40` (not `FUN_10036cf0`); every
  `stateSpawnSet*` key resolved: spawn-and-waves.md §2.2–§2.6.
- **#22 closed** — `FUN_10034ee0`, `FUN_10035070`, `FUN_10017ef0`: §6 (residual: `FUN_10005d40`
  body, NOT RESOLVED 6 here).
- **#19 narrowed** — `FUN_10015b40` is the spawn-set executor, not a movement executor; #19 now
  covers only `FUN_10015930`, `FUN_10015280` (+ this file's NR 3).
- Corrections to merge: waves-and-enemies.md §3 step 7/9 (`FUN_10036cf0` is collision; spawn
  sets run in step 7 via `FUN_10015b40`), §4 worked example counts and group-size/delay draw
  args (HIGH), §8 items 2 and 4 (closed); engine-loop.md §9 per-entity draw order (§3.2 here);
  function-roles rows above (`⚑ corrected`).
- New NOT-RESOLVED candidates: this file's NR 1 (double bookkeeping) and NR 2 (trig/heading axis).
