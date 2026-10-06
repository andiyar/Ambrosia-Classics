# Deimos Rising 1.0.6 — unit movement, headings, animation stepping, spawn-set emission

Reader A, wave 1 (2026-10-03). Code readings only; nothing is behaviour-verified. Scope: the
address range `0x10012300–0x10018740` (G_GameObject / G_Entity neighbourhood, 63 `FUN_`), plus the
callees they need: `FUN_10005d40` (nearest player), `FUN_1000fed0`/`FUN_10010220` (scroll delta)
and the trig module `FUN_10042920…FUN_100431e8`. OUT: `FUN_10014f10` damage, `FUN_10016300`
destroy, `FUN_10016880` water impact (damage/death reader); `FUN_10017cb0` spawn-timer init,
`FUN_10034ee0`, `FUN_10037130/7230/7350` owner lock/link/orbit, `FUN_10037930`/`FUN_10037b50`
spawn placement and initial motion (spawn reader — only read here where they fix a convention).
Conventions as in engine-loop.md (`PermFloat(n)` = `FUN_10020250(n)` = flli item n). Listings
come from `DisasmFuncs.java` on a private project copy (`$W/work-units`, outputs
`$W/disasm-units*.txt`). Constants: `python3 -c "import struct;d=open('$W/mem/100de330.bin','rb').read();c=open('$W/mem/10000000.bin','rb').read();…"`
reading the TOC slot `0x100e6330+off`, then the pointee (addresses < `0x100de330` live in the
code image); every resolved value below names its slot.

**Answer up front.**
- NOT-RESOLVED #19's premise is wrong: the three "movement executors" are three different
  things. `FUN_10015930` = sprite **animation stepper**; `FUN_10015280` = the **motion
  controller** (target, range trigger, hunt/hold/flee/cyclic/constrain → velocity);
  `FUN_10015b40` = rotate-to-target **plus the per-tick spawn-set emitter**. They are not
  alternatives: `FUN_10033850` calls all three every tick, in a fixed order (§1). The position
  integrator is `FUN_10012ca0` (also the off-screen cull).
- Units: position = sprite **centre**, float **game-area pixels** (x 0..416, y 0..480, screen-
  relative); velocity = float **pixels per logic tick**; acceleration/`*Delta` = px/tick per tick.
  Ground (non-`air `) entities also move down by the scroll delta each tick (1 px when scrolling).
- Heading: **integer compass degrees** at entity `+0x138` (0 = up, 90 = right, clockwise),
  converted to an internal angle `h' = 180 − h (mod 360)` whose direction vector is
  `(sin h', cos h')` → velocity `= speed·(sin h, −cos h)` in screen coordinates. sin and cos come
  from two 360-entry float tables built at start-up (BSS `0x10106790` sin, `0x10106d30` cos).
- Speeds are **per axis** in hunt/hold/flee (bang-bang ±Delta per axis, each axis clamped to
  ±MaxSpeed — diagonal pursuit is up to √2 faster); along a heading in plain "move" states
  (ramp from current speed to `stateMaxSpeed` by `stateDelta_FLOAT` per tick).

## 1. Per-tick motion order inside `FUN_10033850` (entity update) [HIGH]
For each live entity whose spawn-in delay has expired (waves-and-enemies.md §3 steps 1–4 first),
dump lines (`find_func.py --func FUN_10033850`, the block after `LAB_10033d70`):
```c
FUN_10015930(iVar15,param_1);                       // 1 animation step
if (piVar9[9] < 1) { … } else FUN_10015550(…);       // 2 rules (state+0x24 = active rule count)
… visibility/tint/scale targets, FUN_10012750, FUN_10012840, FUN_10012940, FUN_10012c10 …
FUN_10015280(iVar15,param_1,local_167,&local_168);  // 3 motion controller -> velocity
cVar10 = FUN_10012ca0(iVar15,0x80,1);               // 4 integrate + cull (128 px margin)
if (cVar10 == '\0') { +0xcb = 1; +0xd9 = 0xff; }    //   off-field -> silent delete
else { if (state+0x32e) FUN_10037130(…);            // 5 LockToOwnerLoc   (spawn reader)
       if (state+0x32f) FUN_10037230(…);            //   LinkToOwnerLoc
       if (state+0x330) FUN_10037350(…);            //   OrbitOwner
       FUN_10015b40(iVar15,param_1);                // 6 rotate-to-target + spawn sets
       … player collision (step 8 of waves §3) … }
```
Consequences: velocity is updated before position each tick; owner lock/link/orbit run after
integration and may overwrite the integrated position (handoff to the spawn reader); a state
change by the range trigger in step 3 takes effect on velocity in the same tick (§5). The game
loop runs the scroll (`FUN_10010000`) and the players before `FUN_10033850` (engine-loop.md §3),
so entities see this tick's scroll delta and this tick's player positions. [HIGH — dump order;
the `FUN_10010000`→entities order is engine-loop.md's HIGH reading]

## 2. Coordinates, units, heading, trig

### 2.1 Position and velocity [HIGH]
`FUN_10012ca0(entity, margin, mode) @ 10012ca0` (only caller `FUN_10033850`, args `0x80, 1`):
```
10012cc0  lbz r0,0x19(r3)        ; air flag
10012cc8  bne 0x10012d00         ; air -> skip scroll follow
10012ccc  bl 0x1000fed0          ; pixels scrolled this tick (int)
10012cec  lfs f0,0x4(r30) … fadds f0,f0,f1 ; stfs f0,0x4(r30)   ; y += scrolled
10012d00  lfs f1,0x0(r30) ; lfs f0,0x10(r30) ; fadds ; stfs f0,0x0(r30)  ; x += vx
10012d14  lfs f1,0x4(r30) ; lfs f0,0x14(r30) ; fadds ; stfs f0,0x4(r30)  ; y += vy
```
- `FUN_1000fed0` returns `_DAT_100e0130`, written only by `FUN_10010220` as
  `oldTop − newTop` (0 when scrolling is stopped) → the scroll delta of this tick, 1 px normally.
  Entity `+0x19` = `(spawn record +8 == 'air ')` (`FUN_10035cd0`: `*(bool *)(iVar3 + 0x19) =
  *(int *)(param_2 + 8) == 0x61697220`) — same flag that picks draw layer 7 vs 3 (engine-loop
  §5). So **ground units ride the terrain; air units do not**. [HIGH for the arithmetic; MED for
  which record `param_2` is]
- Velocity is added once per call, one call per logic tick ⇒ **px/tick**. At the limiter's
  ≈30 ticks/s (engine-loop.md §4, FPS_Delay 2 Mac ticks) 6 px/tick ≈ 180 px/s. [HIGH px/tick;
  MED for the per-second figure, which depends on frame rate and the game-speed divider]
- Position is the sprite centre: bounding box `FUN_10012ad0 @ 10012ad0` = `x∓hw, y∓hh` with
  `hw = +0x2c`, `hh = +0x30` (`FUN_10012940`: `+0x2c = frameW/2`, `+0x30 = frameH/2`, integer
  division); `FUN_10012a00` writes the same box as a Mac `Rect` (top,left,bottom,right).
  Game-area coordinates: the cull and on-screen tests compare against PermFloat 54
  `VisibleGameWidth` = 416 and 55 `VisibleGameHeight` = 480 directly (§7), and ground units shift
  by the scroll delta, so y is **screen-relative**, not map-relative. [HIGH]

### 2.2 Heading convention [HIGH]
- Entity `+0x138` (int) = compass heading in degrees, written only at spawn (`FUN_10035cd0`,
  `FUN_10037b50` — `10037e10 stw r0,0x138(r30)` from `initialHeading +0x1a4` ± tolerance). No
  motion code rewrites it, so a non-rotating unit keeps its spawn facing for the animation row
  (§8). [HIGH — `find_func.py '0x138\) ='` → only those two game functions in the range of interest]
- `FUN_10043040(&h) @ 10043040` converts compass → internal:
  ```
  10043058  cmpwi r3,0xb4 ; bgt 0x10043074
  10043060  subi r3,r3,0xb4 ; bl 0x1004ee30      ; abs(h-180)   (h <= 180)
  10043074  subfic r0,r3,0x21c                   ; 540-h        (h > 180)
  ```
  i.e. `h' = (180 − h) mod 360` (an involution). `FUN_1004ee30` = `abs`.
- `FUN_10042b80(h', speed, out) @ 10042b80`: `out = (speed·S[h'], speed·C[h'])` —
  `10042ba4 bl 0x10042f00 ; fmuls f0,f31,f1 ; stfs f0,0x0(r31)` then
  `10042bb8 bl 0x10042ee0 ; fmuls ; stfs f0,0x4(r31)`. `FUN_10042b30` = same with speed 1.
- Hence velocity for compass heading h: `(speed·sin h, −speed·cos h)`; h = 0 → (0, −s) = up the
  screen, 90 → right, 180 → down, 270 → left. Data check: Shuriken `initialHeading_INT 180`,
  first state "Move South…". [HIGH]
- Heading to a point, `FUN_10042ad0(x, y, tx, ty) @ 10042ad0` → `FUN_10043090(a = x−tx,
  b = y−ty)` (`10042ad4 subf r7,r5,r3`, `10042adc subf r0,r6,r4`): `t = atan2(b, a)` in integer
  degrees from the atan table (octant fold at `1004317c..100431cc`), result `t − 90` wrapped to
  0..359 (`100431d0 subic. r3,r3,0x5a`). Target straight up (a=0, b>0) → 0; to the right → 90 —
  the same compass convention. Precision: table index `trunc(100·min/max)` (`10043100 lfd
  f0,0x40(r5)` = 100.0), so ≈ 0.6° steps near 0°, values truncated to whole degrees. [HIGH]
- Heading from a vector, `FUN_10042cd0(&v)`: internal convention (`(0,+)`→0, `(+,0)`→90,
  `(0,−)`→180, `(−,0)`→270, else libm `atan` ·57.2957…, truncated to int; 360 → 0). Used only by
  the state-entry velocity setup (§4) and burst/implode spawn. [MED — decompile + constants
  `0x100d7318` = {0.017453, 0.0, 180.0, 90.0, 270.0}; listing not checked]

### 2.3 Trig/sqrt tables (`FUN_10042920 @ 10042920`, start-up) [HIGH]
| table | slot | address | contents | evidence |
|---|---|---|---|---|
| atan | r2−0x6e24 | `0x101172d0` (BSS) | 1024 ints, `trunc(atan(0.01·i)·57.2957795)` | `10042978..100429b4`, consts at `0x100d732c` = {0.01, 57.2957795, 2^52+2^31} |
| sqrt | r2−0x6e28 | `0x101072d0` (BSS) | 16384 floats, `sqrt(i)` | `100429cc..10042a00` `bl 0x100d576c` (= `sqrt` glue) |
| cos  | r2−0x6e30 | `0x10106d30` (BSS) | 360 floats, `cos(i·0.017453f)` | `10042a38 bl 0x100d5784` (`cos`) → `stfs f0,0x0(r30)` (r30 = r26 = slot −0x6e30) |
| sin  | r2−0x6e34 | `0x10106790` (BSS) | 360 floats, `sin(i·0.017453f)` | `10042a4c bl 0x100d579c` (`sin`) → `stfs f0,0x0(r31)` (r31 = r25 = slot −0x6e34) |
Glue names from the dump headers (`// ==== cos @ 100d5784`, `// ==== sin @ 100d579c`); the
degree→radian factor is `*(float*)0x100d7318` = 0.017453 (slot r2−0x6e2c). Accessors:
`FUN_10042ee0(h)` = C[h], `FUN_10042f00(h)` = S[h], both map h = 360 → 0 (`cmpwi r3,0x168`),
no other range check. `FUN_10042f20(n)` = `n < 0x4000 ? sqrtTable[n] : (float)sqrt(n)`; every
distance in this file is `FUN_10042f20(trunc(dx²+dy²))`. The tables are not in the data image
(they are BSS); a replica computes them identically. [HIGH]

## 3. Entity fields used by motion (entity = 0x1ec-ish object, base `G_GameObject` 0x94 bytes)
| off | type | meaning | key / writer | evidence |
|---|---|---|---|---|
| +0x00/+0x04 | f32 | x, y (centre, game-area px) | `FUN_10012910` set, `FUN_100128d0` get | §2.1 listing [HIGH] |
| +0x10/+0x14 | f32 | vx, vy (px/tick) | §4/§5 writers | `10012d08 lfs f0,0x10(r30)` [HIGH] |
| +0x19 | u8 | air (1) / ground (0) | `FUN_10035cd0` | §2.1 [HIGH] |
| +0x1c / +0x20 | ID / int | sprite face ID / current frame | `stateSpriteFace_ID` +0x304, `FUN_100146f0` | §8 [HIGH] |
| +0x24/+0x28, +0x2c/+0x30 | int | frame w/h, half w/h | `FUN_10012940` | dump [MED — sprite callee unread] |
| +0x34 / +0x50 | u8 / ptr | frame-dirty flag / frame pointer (`FUN_10019ad0(face, frame)`) | §8 | [MED] |
| +0x58/5c/60, +0x68/6c/70, +0x84/88/8c | f32 | tint, visibility, scale: current / target / step | `FUN_10012750`, `FUN_10012840` approach target by step | dump [MED] |
| +0x74..+0x80 | u8,u8,int,int,u16 | hit-glow on, direction, level (32→4→32), step, colour | `FUN_10012bc0` start, `FUN_10012c10` tick, `FUN_10012c00` off | dump [MED] |
| +0x94 / +0xa8 | ptr / int | unit def / current state index | | bank [HIGH] |
| +0xbc | int | game time of the last frame step / turn | §8 | [HIGH] |
| +0xc0 / +0xc1 / +0xc2 | u8 | anim playing backwards / is rotating / anim stopped (rule #10) | §8 | [HIGH] |
| +0xc3 | u8 | has spawn sets (gate of the emitter) | §9 | `10015b6c lbz r0,0xc3(r30)` [HIGH read; writer not read] |
| +0xc4 | int | rotation-pause countdown | `TimeToPauseRotationAfterSpawning` | §9 [HIGH] |
| +0xc8 | u8 | animates (`face ≠ none && FrameDelta > 0`) | `FUN_100146f0` | [HIGH] |
| +0xcc | u8 | **fleeing** | set by `FUN_10017510`, cleared by `FUN_100146f0` | §6 [HIGH] |
| +0x100/+0x104 | f32 | velocity at spawn (copy) | `FUN_10037b50` | [HIGH, not used in range] |
| +0x108/+0x10c | f32 | desired velocity | §4, `FUN_10017c40`, `FUN_10016fe0` | [HIGH] |
| +0x110/+0x114 | f32 | per-axis acceleration | §4, §5 | [HIGH] |
| +0x118 | s8 | tracked player number, −1 = none | `FUN_10015280` from `FUN_10005d40` | §5 [HIGH] |
| +0x11c/+0x120 | f32 | target point (nearest player, or flee point) | §5, §6 | [HIGH] |
| +0x138 | int | compass heading | §2.2 | [HIGH] |
| +0x13c / +0x13d | u8 | `isStationary` / `enableTerrainEffects` (level object flags via group) | `FUN_10035cd0` | [HIGH] |
| +0x19c+4s | list | per-state spawn-set runtime records (0x18 bytes each) | `FUN_100144a0` allocs | §9 [HIGH] |
Init values: `FUN_100142f0` (entity reset) sets `+0x118 = −1`, target/velocity copies from
`_DAT_100df134` = (0,0), `+0xa8 = −1`, `+0xf8 = 'none'`; base `FUN_10012650` sets air=1,
draw layer `defa`, sprite `none`. [HIGH — dump]

## 4. Velocity set-up on state entry (`FUN_100146f0` block `10014bac..10014d7c`) [HIGH]
When a state is entered (spawn: `param_2 = 1`; later transitions: 0), unless the **new** state has
`LockToOwnerLoc` (+0x32e) — which zeroes v, accel and desired (`10014bc0..10014bd8`):
```
10014be4  bl 0x10042c90              ; s = |v| = sqrt(vx²+vy²)  (libm, float)
          heading h' = spawn: FUN_10043040(+0x138)            (10014bec..10014bfc)
                   later: old state OrbitOwner ? +0xe0 : FUN_10042cd0(&v)   (10014cc0..10014cd8)
10014c04  lfs f30,0x458(r28)         ; M = new stateMaxSpeed_FLOAT
10014c08  fcmpo f31,f30 … fsubs      ; diff = |M − s|
10014c1c  lfs f1,0x45c(r28)          ; D = new stateDelta_FLOAT ; f1 = min(D, diff)
10014c2c  fcmpo f30,f31 ; ble        ; s1 = (M > s) ? s + f1 : s − f1
10014c48  bl 0x10042b80              ; tmp = s1·dir(h')
10014c64  stfs f0,0x110(r31)         ; accel.x = tmp.x − vx ; accel.y (0x114) = tmp.y − vy
10014c7c  bl 0x10042b80 (f1 = M, r5 = r31+0x108) ; desired = M·dir(h')
```
- So a plain moving state "ramps the speed by `stateDelta_FLOAT` per tick toward
  `stateMaxSpeed_FLOAT`, along heading h'". Exact replica semantics: `accel` is a constant vector
  computed **once** at entry; `FUN_10017a10` (§5.6) adds it every tick, clamping each axis so it
  never passes `desired`. If v was not already along h' the first tick also snaps the direction
  (accel contains the full correction) and later ticks add that same vector — replicate as written.
- `D = 0` (common: Shuriken state 0) ⇒ accel = (s·dir − v) = 0 when v ∥ dir ⇒ the unit keeps its
  spawn speed forever, even if `MaxSpeed` differs.
- The OrbitOwner test reads the **old** state (`100147d0..100147f8`: state from `+0xa8` before
  it is overwritten; `lwz r26,0xe0(r31)` keeps the orbit angle). Heading source for the spawn
  entry is the compass `+0x138` converted; for later entries it is the current velocity's angle
  (zero velocity → 0 → "down").
- Then: new `stateFlee_ID` (+0x320) ≠ `none` → `FUN_10017510(entity, fleeID)` (§6); else if the
  entity is fleeing and the **old** state's flee ID ≠ none → fleeing := 0 (`10014d7c..10014db4`).
- Other entry effects in the same function: state lookup is by name over all states with **no
  break** — duplicate names resolve to the highest index (`100147ac or r28,r18,r18` inside the
  loop); state timer `Random(OnTimerMin, OnTimerMax)` (`+0xb8`); frame `Random(SpriteFrameMin,
  Max)` or, if `initialHeadingSetInEditor` (+0x124), the frame matching `+0x138` (`FUN_10016230`);
  `+0xc0 = DoAnimateBackwards`; on spawn also visibility/tint/scale from the state and unit
  (`initialScalePercent ± tolerance/2`); counter trigger (`OnCounter` +0x3b4 → `OnCounterChangeTo`
  +0x51c, recursive). Pickup units (`pickup_Type_ID` `grnd`/`air `/`spec` → `PEAG`/`PEAA`/`SPEC`)
  take their sprite from the weapon table unless `Pickup_DoNotChangeAppearance`. [HIGH for the
  velocity block (listing); MED for the rest (dump only)]

## 5. Motion controller `FUN_10015280(entity, gameTime, &del, &destroy) @ 10015280` [HIGH]
Listing `10015280..1001554c`:
1. **Fleeing** (`+0xcc`): `FUN_10016cc0` (seek, flee speeds) then `FUN_100172d0` (turn toward the
   flee point) and return — no player search, no range trigger, no constrain, no cyclic.
2. `FUN_10005d40(entity, &target, &dist, &playerNo)` (§5.1). No active player →
   `+0x118 = −1`, then in this order: `DeleteOnNoActivePlayers` (+0x350) → delete;
   `DestructOnNoActivePlayers` (+0x351) → destroy; unit `fleesNorthOnNoActivePlayers` (+0x126) →
   `FUN_10017510(e,'nora')`; `fleesSouthOnNoActivePlayers` (+0x127) → `'sora'`; each returns.
   Otherwise fall through (with an undefined target — see NOT RESOLVED 3).
3. `CyclicMotion` (+0x34a) → `FUN_10016fe0` (§5.5). Unit `constrainInGameArea` (+0x11d) →
   `FUN_10016da0` (§5.7).
4. `+0x11c/+0x120 = target`, `+0x118 = playerNo` (`100153c8..100153d8`).
5. If a player exists: **range trigger** — `OnRange_FLOAT` (+0x44c) == 0.0 or `dist ≥ OnRange`
   (`100153f8 fcmpo f0,f1 ; bge`) → `hunt = Hunts (+0x349)`. Else (`dist < OnRange`, strict):
   `OnRangeChangeTo_STR` (+0x55c) `"Delete"` → del; `"Destroy"` → destroy; non-empty and ≠
   `"none"` (slot r2−0x7204 → `0x100d6804` "none") → `FUN_100146f0` (state change, may del/destroy);
   then re-read the state; new state `ReverseDirectionOnReaction` (+0x34b) → `FUN_10017c40(e,
   &target, dist)`. Then (new or unchanged state) `HoldPositionToTarget` (+0x34c) →
   `FUN_10017b70` and `hunt = 0`; else `hunt = Hunts`. A target name that matches no state
   (shipped data uses `"No State"`) does nothing.
6. `!fleeing && hunt` → `FUN_10016cc0` (seek); else `FUN_10017a10` (ramp to desired).
Constants: `"Delete"`/`"Destroy"` at `r2+0x3c4+0x4e/+0x55` = `0x100e6742/0x100e6749`; 0.0 at
`*(double*)(0x100d6ca4+8)` (slot r2−0x7208).

### 5.1 Nearest player `FUN_10005d40(e, &tgt, &dist, &no) @ 10005d40` [HIGH]
For players 0,1 (`r27` walks the player table, slot r2−0x7360) that are in state 4 (`FUN_10026c60
(p,4)` = `p+0xc6 == 4`, "active"): `d = FUN_10042f20(trunc((px−x)² + (py−y)²))`; keep the first,
replace only on strictly smaller d (`10005e40 fcmpo f0,f31 ; bge`) ⇒ **ties go to player 1**.
Returns found?; `tgt` = that player's position, `dist` = d, `no` = `FUN_10026c90(p)` = player
`+0xcc` = player number (`FUN_10026410`: "Setting Up Player %i" prints `+0xcc`) or −1.

### 5.2 Seek / hunt `FUN_10016cc0 @ 10016cc0` [HIGH]
```
10016cdc  bne 0x10016cec        ; fleeing?  M,D = FleeSpeed +0x460, FleeDelta +0x464
10016ce0  lfs f3,0x458(r4) ; lfs f2,0x45c(r4)   ; else M = MaxSpeed, D = Delta
10016cfc  fcmpo x, tx ; bge -> ax = −D  else ax = +D      (y the same with ty)
10016d3c  vx += ax ; clamp vx to [−M, +M] ; vy += ay ; clamp vy to [−M, +M]
```
Bang-bang per axis, ties (`x == tx`) accelerate negative. No damping: the unit overshoots and
oscillates about the target on each axis. Speed cap is per axis.

### 5.3 Hold position `FUN_10017b70 @ 10017b70` [HIGH]
Same shape with `HoldMaxSpeed` (+0x450) / `HoldDelta` (+0x454) and the **opposite** sign:
`x < tx → ax = −HoldDelta`, else `+HoldDelta` (`10017b98 bge`, `10017b9c fneg`) — accelerates
away from the target while inside `OnRange`.

### 5.4 Reverse on reaction `FUN_10017c40(e, &tgt, f1 = dist) @ 10017c40` [HIGH]
`d = tgt − pos`; if dist ≠ 0 (`10017c50 fcmpu`) `d /= dist`; `desired = −d·MaxSpeed`
(`10017c84..10017ca0`). Only sets the desired velocity (reached via §5.6 next ticks). No shipped
state sets `ReverseDirectionOnReaction` (census: 0 of 1167).

### 5.5 Cyclic motion `FUN_10016fe0 @ 10016fe0` [HIGH]
Every tick **two RNG draws** (replay-relevant):
```
10017008  lfsx f0 = MaxSpeed ; fctiwz -> m = trunc(MaxSpeed)
10017018  r3 = m/2 (C division) ; r4 = m ; bl 0x10046580       ; a = RandomRange(m/2, m)
10017040  li r3,1 ; li r4,0x64 ; bl 0x10046580                 ; b = RandomRange(1, 100)
10017088  L = a + b / 100.0                                    ; (0x100d6c8c+0x10 = 100.0)
```
then per axis: `v > L → v = L, accel = −accel`; `v < −L → v = −L, accel = −accel`; `v += accel`;
`desired = v`. With accel from §4 (e.g. a state entered from rest gets `accel = (0, D)` — heading 0,
i.e. along +y) this makes the velocity sweep back and forth between ±L, L re-drawn every tick.
Then §5.6 runs (desired = v, no change). Used by 40 states (cash pickups "Grow and Wait", …).

### 5.6 Ramp to desired `FUN_10017a10 @ 10017a10` [HIGH]
`isStationary` (+0x13c) → v, desired, accel := (0,0) (`10017a20..10017a3c`, slot r2−0x71fc →
`0x100d67f4` = 0.0). Else if `OrbitOwner` (+0x330): `vx` steps toward `MaxSpeed` by `Delta`
(clamped) — vx is used as the orbit rate by `FUN_10037350` (spawn reader). Else per axis:
`v < desired → v += accel, clamp to ≤ desired`; `v > desired → v += accel, clamp to ≥ desired`;
equal → unchanged (`10017a6c..10017b14`). Sign of accel is whatever §4/§5.5 left.

### 5.7 Constrain in game area `FUN_10016da0 @ 10016da0` [HIGH]
Bounce (negate v, accel and desired on that axis, and place on the edge):
```
10016dec  lfs f1,0xc(r30)  ; −32.0   x < −32         → x = −32          (centre, no half-width)
10016e64  x + hw > W + 32                            → x = W − hw + 32
10016ee4  y − hh < 0.0                               → y = hh
10016f68  y + hh > H                                 → y = H − hh
```
(W, H = PermFloat 54/55 truncated; table `0x100d6c8c` = {0, 360, 1, −32, 100, 0.5}, slot
r2−0x71f8). Asymmetry (left edge uses the centre, right edge the sprite edge) is in the code.
Runs before the integration of the same tick, so the bounce acts on last tick's position.

### 5.8 Range test `FUN_10017ef0(e, range, &tgt, &no) @ 10017ef0` (rule conditions #8/#9) [HIGH]
`FUN_10005d40` then `found && range ≠ 0 && dist < (float)range` (`10017f50 fcmpo f2,f0 ;
bge`). Range = rule `+0x84` (= state `+0xac + r·0x88`, `#stateRuleRange_INT`). Caller
`FUN_10015550` cases 8/9 (dump; jump-table targets are not in the linear listing).

## 6. Flee targets `FUN_10017510(entity, code) @ 10017510` [HIGH]
Sets fleeing `+0xcc = 1` first (`1001753c stb r3,0xcc(r30)`), then the target point by code
(4CC compare tree `10017538..1001762c`; `R(a,b)` = float RandomRange `FUN_100465e0(0.0, b)`,
lower bound `*(float*)0x100d6c8c` = 0.0; `W`,`H` = PermFloat 54/55 = 416/480; flli 14/15/16/17 =
`Game_EntityFlee North/South/West/East Location` = −1000 / 2000 / −1000 / 2000):
| code | target x | target y | shipped uses |
|---|---|---|---|
| `nora` | R(0,W) | −1000 | 5 + unit flag fleesNorth |
| `sora` | R(0,W) | 2000 | 4 + fleesSouth |
| `noce` / `soce` | W·0.5 | −1000 / 2000 | 1 / 3 |
| `wece` / `eace` | −1000 / 2000 | H·0.5 | 0 |
| `wera` / `eara` | −1000 / 2000 | R(0,H) | 0 |
| `cega` | W·0.5 | H·0.5 | 3 |
| `opve` | R(0,W) | y > H/2 ? −1000 : 2000 | 0 |
| `opho` | x > W/2 ? −1000 : 2000 | R(0,H) | 0 |
| `rave` | R(0,W) | RandomRange(0,1)==0 ? 2000 : −1000 | 1 |
| `raho` | RandomRange(0,1)==0 ? −1000 : 2000 | R(0,H) | 0 |
Draw order: int draw (rave/raho) before the float draw; x before y. Unknown code (incl. `none`)
→ only the fleeing flag. Evidence lines: `opve` `100177c4 fmuls f1,f1,f2 ; fcmpo y,H·0.5 ; ble`
(≤ → south `li r3,0xf`, else north `li r3,0xe`); `opho` `10017850 fcmpo x,W·0.5 ; ble` (≤ → east
0x11, else west 0x10); `rave` `100178d0 cmpwi r3,0 ; beq` (0 → `li r3,0xf`); `raho` 0 → 0x10.
Shipped census: `grep -h '#stateFlee_ID' $W/data/Game/unde/*.txt | sort | uniq -c` → none 1150,
nora 5, sora 4, soce 3, cega 3, rave 1, noce 1. A fleeing entity seeks the point with
`FleeSpeed`/`FleeDelta` (§5.2) until culled 128 px outside the field (§7) or until a state
change clears the flag (§4). [HIGH]

## 7. Culling and on-screen tests [HIGH]
`FUN_10012ca0(e, m=128, mode=1)` returns 1 (keep) iff, after integrating:
`x + hw ≥ −m` (`10012da0 fcmpo ; blt`), `x − hw ≤ W + m` (`10012dd4 ; bgt`), **`y ≥ −m`** (centre,
no half-height: `10012df0 fcmpo f3,f0` with f3 = y), `y − hh ≤ H + m` (`10012e2c ; ble`); else the
caller deletes silently. Mode 0 (`x+hw ≥ −32`, `x−hw ≤ W+32`, `y+hh ≥ 0`, `y−hh ≤ H`) has no
caller. `FUN_10016bd0(e) @ 10016bd0` = centre on screen: `0 ≤ x ≤ trunc(W)` and
`0 ≤ y ≤ trunc(H)` (`10016bf4..10016c90`); callers: spawn-set `Don'tSpawnOffscreen` (§9) and
`FUN_100353e0` (rule #5 "No Destroyable Ground Entities Are Active").

## 8. Animation stepping and turning

### 8.1 `FUN_10015930(entity, gameTime) @ 10015930` — animation step [HIGH]
Runs if `+0xc8` (animates), `FrameDelta` (+0x31c) > 0, **not** `DoRotateToTarget` (+0x303), and
`gameTime > +0xbc + FrameDelay (+0x318)` (`10015990 cmpw r31,r0 ; ble`). Row of frames:
```
10015998  lwz r0,0x138(r30)          ; compass heading
100159c4  lfs f0,0x4(r3)             ; 360.0  (slot r2−0x71f8 -> 0x100d6c8c+4)
100159dc  fdivs ; fmuls ; fctiwz     ; dir = trunc(NumDirections · h / 360)
10015a00  mullw r3,r0,r3             ; base = dir · FramesPerDirection ; last = base + FPD − 1
```
`ContinuousFrameRandomisation` (+0x302) → `frame = RandomRange(base, last)` (`10015a0c bl
0x10046580`, one draw per step). Else repeat `FrameDelta` times (stop early when stopped):
forward (`+0xc0 == 0`): at `last` → if `!DoLoopAnimation` (+0x301) stopped (`+0xc2 = 1`), elif
`!DoAnimateBackwards` (+0x300) wrap to `base`, else reverse (`+0xc0 = 1`, frame = last−1); else
frame+1. Backward: at `base` → not looping: stopped; `!DoAnimateBackwards`: frame = last; else
`+0xc0 = 0`, frame = base+1; else frame−1. Then `+0xbc = gameTime`, dirty, frame pointer
re-fetched. "Animation has stopped" (rule #10) = `+0xc2`, cleared on state entry. Note: the frame
range ignores `SpriteFrameMin/Max` (those only seed the frame at entry).

### 8.2 Turn toward target `FUN_100172d0(e, gameTime) @ 100172d0` and gate `FUN_10017150` [HIGH]
Only for `DoRotateToTarget` states (else `+0xc1 = 0`, return 1). Needs a target: fleeing, or
`+0x118 ≠ −1` (`10017328 lbz r0,0x118 ; cmpwi r0,-0x1`); sets `+0xc1 = 1`. When `gameTime >
+0xbc + FrameDelay`: `want = FUN_10042ad0(x, y, tx, ty)` (ints, compass); target frame
`FUN_10016230(want)`; if ≠ current frame: `cur = heading-of-frame` (as `FUN_100161c0`),
`d = want − cur` wrapped to [−180, 180]; `d ≤ 0` → frame −1 repeated `FramesPerDirection` times
(wrap below 0 to `NumDirections·FPD − 1`), else +1 repeated FPD times (wrap to 0) — one direction
step per turn; `+0xbc = gameTime`. `FUN_10017150` (first call of `FUN_10015b40`) suppresses the
turn while `+0xc4 > 0` (decremented each tick) or while any `PauseAnyRotationWhileSpawning`
spawn set is mid-volley (`0 < remaining < volleyCount`). Called from §5 step 1 (fleeing) and §9;
the second call in a tick fails the strict time test, so at most one step per tick.
Helpers: `FUN_100161c0(e)` = heading of the current frame: `NumDirections == 1 ? frame·(360/FPD)
: max(frame/FPD, 0)·(360/NumDirections)` (integer divisions); `FUN_10016230(e, h)` = frame for
heading h: `n = h / (360/NumDir)` rounded half-up (0.5 = `*(double*)(0x100d6ca4+16)`), `n < 0 →
NumDir−1`, `n > NumDir−1 → 0`, × FPD. Quirk: §8.1 truncates, §8.2 rounds. [HIGH listing for
`FUN_100172d0` gates; HIGH for the helper arithmetic] ⚑ corrected (micro-wave, 2026-10-06) #§3.2:
`FUN_10016230` read in the listing (`10016230..100162f4`): NumDir ≤ 0 → 1; `step = 360/NumDir` is C
integer division (n = 7 → 51); the quotient `(float)h / (float)step` is **single precision**
(`fdivs`), `k = trunc` (`fctiwz`), +1 if `q − k ≥ 0.5`; for h < 0 the fraction is ≤ 0, so negatives
truncate toward 0 (micro-wave-2026-10-06.md §3.2) — was "MED for the helper arithmetic (dump)".

## 9. Spawn-set emitter `FUN_10015b40(entity, gameTime) @ 10015b40` (handoff → spawn reader)
This is the per-tick executor of the state's spawn sets (INDEX #20 names `FUN_10036cf0`; see
⚑ conflict 2). Gate `+0xc3`. Per spawn set i (definition `state+0x5dc` list, runtime record
`+0x19c[state]` list item i: `[0]` rate, `[1]` last volley time, `[2]` remaining, `[3]` volley
size, `[4]` inter-entity countdown, `+0x14` active), skipped when `Spawn_ID` (+0x20) = none,
inactive, `rate < 0`, or fleeing without `SpawnIfFleeing` (+0x50):
- `Don'tSpawnOffscreen` (+0x47) and a volley not yet started (`remaining > 0 && remaining ≥
  size`) and entity not on screen (§7) → `remaining = 0`, skip (`10015c2c..10015c6c`).
- `remaining > 0`: countdown−− (if > 0); when ≤ 0: `remaining−−`, countdown =
  `RandomRange(DelayBetweenMin +0x3c, Max +0x40)`, **emit one** (`10015c70..10015cc4`).
- `remaining ≤ 0`: not `RepeatSpawns` (+0x46) → inactive. Else when `gameTime ≥ last + rate`:
  `last = gameTime`, then draws in this order: countdown = R(DelayBetween), size =
  R(NumInVolleyMin +0x34, Max +0x38), remaining = size, rate = R(RateMin +0x2c, Max +0x30);
  `PauseAnyRotationWhileSpawning` → `+0xc4 = max(+0xc4, TimeToPause +0x4c)`. No emission this
  tick (`10015ce0..10015d58`).
- Emission: spawned unit def `FUN_1003d550(id, +0x98)`; if it is a `terrainEffect` unit (+0x132)
  it needs `!isStationary && enableTerrainEffects` (`10015d8c..10015dac`). Position:
  `AdjustOffsetForUnitRotation` (+0x44): `h = FUN_100161c0(e)` (+ `HeadingDegrees` +0x54 if
  `SetHeading` +0x51, wrap > 359), `dx = trunc(ox·cos h − oy·sin h)`, `dy = trunc(ox·sin h +
  oy·cos h)` (`10016070..100160f0`; `f31 = C[h]`, `f1 = S[h]`), pos = entity + (dx,dy); else
  `AbsoluteCoordinates` (+0x45) → pos = (XOffset, YOffset); else pos = entity + offset. If the
  spawned unit has `adjustInitialLocForOwnerScale` (+0x12e) and entity scale (+0x84) ≠ 1.0, the
  offsets are multiplied by the scale (`10015e40..10015ec4`, `10015fd0..10016064`). Request
  (template 0x2c bytes at `r2+0x180`): unit, x, y, SetHeading flag (+0xd), heading (+0x10),
  `e+0xd8` (+0x14), `StationaryOption`/`TerrainEffectsOption` (+0x1c/+0x1d), owner `e` (+0x20),
  `e+0x9c` (+0x24) → `FUN_10033220(req, 0, unitDef)`.
[HIGH for control flow, field offsets and the rotation formula (listing); MED for the meaning of
runtime words not initialised here (`FUN_10017cb0`, spawn reader)]

## 10. Every function in range (role table input)
| function | role | conf | evidence |
|---|---|---|---|
| `FUN_100125b0` | static init of a 2-word global (`0x100e6194`) | HIGH | dump — ⚑ corrected (review wave 3, 2026-10-06) #L: was LOW on dump; = TU init writing only the `"nonenone"` pair `0x100e618c` +8/+0xc ← 0 (`100125b0..100125c8`), static-init-audit.md §3 table A (listing + interpreter); function-roles.md row |
| `FUN_100125d0` | G_GameObject ctor (`+8 = 1234567890` magic, `FUN_10012650`) | MED | dump, callers ctor-shaped |
| `FUN_10012610` | G_GameObject dtor (free if flag > 0) | MED | dump |
| `FUN_10012650` | G_GameObject reset (pos/vel 0, air=1, sprite none, layer `defa`, vis/tint/scale defaults) | HIGH | dump — ⚑ corrected (micro-wave, 2026-10-06) #§3.6: listing in micro-wave-2026-10-06.md §3.6 (function-roles.md row). Was MED |
| `FUN_10012750` | step visibility (+0x68→+0x6c by +0x70) and tint (+0x58→+0x5c by +0x60), floor at table[0] | MED | dump |
| `FUN_10012840` | step scale +0x84→+0x88 by +0x8c, sets dirty | MED | dump |
| `FUN_100128c0` | empty stub | HIGH | dump `return;` |
| `FUN_100128d0` | get position (x,y) | MED | dump, §5.1 — ⚑ label audit (review wave 1) |
| `FUN_100128f0` | get position as two outs | MED | dump — ⚑ label audit (review wave 1) |
| `FUN_10012910` | set position (x,y) | MED | dump `*param_1 = *param_2` — ⚑ label audit (review wave 1) |
| `FUN_10012930` | set position from f1,f2 | MED | dump (float args dropped) |
| `FUN_10012940` | refresh frame size + half size when dirty | MED | dump |
| `FUN_10012a00` | bounding Rect (t,l,b,r) | HIGH | dump |
| `FUN_10012ad0` | bounding box (l,t,r,b) | HIGH | dump |
| `FUN_10012ba0` | get frame w,h | MED | dump — ⚑ label audit (review wave 1) |
| `FUN_10012bc0` / `FUN_10012c00` / `FUN_10012c10` | hit glow start / stop / tick (32↔4 by step) | MED | dump; callers damage/pickup |
| `FUN_10012ca0` | **integrate position (+scroll for ground) and cull** | HIGH | §2.1, §7 |
| `FUN_10012f20` | draw object if visibility > 0 (shadow then sprite) | MED | dump |
| `FUN_10012fa0`, `FUN_10013460` | draw / draw shadow | — | not re-read (bank rows stand) |
| `FUN_10014060`, `FUN_100140b0` | 4CC↔string | — | not re-read |
| `FUN_10014120` | static init: draw-command template `0x100e63e4` (+0x04/+0x08 ← 0, clip +0x20..+0x2c ← {0, 0, 480, 416}, +0x38..+0x44 ← 0) and `r2+0x100` +0x08/+0x0c ← 0 | HIGH | raw listing `10014120..10014194` (`$W/disasm-units.txt`) — ⚑ corrected (review wave 2, 2026-10-03) #C1: was LOW "static init (entity globals)"; sprite-geometry-draw.md §3.1 |
| `FUN_100141a0` | G_Entity ctor | MED | dump (calls 125d0, 142f0) |
| `FUN_10014290` | G_Entity dtor | MED | dump |
| `FUN_100142f0` | G_Entity reset (§3 init values) | MED | dump — ⚑ label audit (review wave 1) |
| `FUN_100144a0` | bind unit def; allocate per-state spawn runtime lists (0x18 each, "newSpawnInfoPtr"); `drawLayer hud ` → +0x18 = 0 | MED | dump strings G_Entity.cc — ⚑ label audit (review wave 1) |
| `FUN_10014650` | current state pointer | HIGH | bank |
| `FUN_10014670` | enter first state flagged `UseThisStateOnWeaponPowerupRelease` (+0x355) | HIGH | dump `0x835` = 0x4e0+0x355 — ⚑ label audit (review wave 1) — ⚑ corrected (micro-wave, 2026-10-06) #§3.3: listing in micro-wave-2026-10-06.md §3.3 (function-roles.md row). The state is entered **by its name** (`stateName_STR`) via `FUN_100146f0`; duplicate names would pick the last match (none in shipped data). Was MED |
| `FUN_100146f0` | change state by name + velocity set-up (§4) | HIGH | listing |
| `FUN_10015280` | **motion controller** (§5) | HIGH | listing |
| `FUN_10015550` | evaluate 5 rules | — | bank row stands |
| `FUN_10015930` | **animation step** (§8.1) | HIGH | listing |
| `FUN_10015b40` | **rotate gate + spawn-set emitter** (§9) | HIGH | listing |
| `FUN_100161c0` | heading of current frame | MED | dump |
| `FUN_10016230` | frame for heading | HIGH | dump — ⚑ corrected (micro-wave, 2026-10-06) #§3.2: listing in micro-wave-2026-10-06.md §3.2 (function-roles.md row). Rounding is single precision; negative quotients truncate toward 0. Was MED |
| `FUN_10016bd0` | centre on screen | HIGH | listing |
| `FUN_10016cc0` | seek target (hunt/flee) | HIGH | listing |
| `FUN_10016da0` | constrain/bounce in game area | HIGH | listing |
| `FUN_10016fe0` | cyclic motion | HIGH | listing |
| `FUN_10017150` | rotation-pause gate → `FUN_100172d0` | HIGH | dump + listing callers |
| `FUN_100172d0` | turn sprite toward target | HIGH | listing |
| `FUN_10017510` | flee target by code | HIGH | listing |
| `FUN_10017a10` | ramp velocity to desired / stationary / orbit rate | HIGH | listing |
| `FUN_10017b70` | hold position (accelerate away) | HIGH | listing |
| `FUN_10017c40` | reverse on reaction (desired = −unit·MaxSpeed) | HIGH | listing |
| `FUN_10017e10` | free a spawn runtime list | MED | dump |
| `FUN_10017e70` | enter first state flagged `UseThisStateOnShieldDepletion` (+0x356) | HIGH | dump `0x836` |
| `FUN_10017ef0` | player within range (rule #8/#9) | HIGH | listing |
| `FUN_10017f80` | static init (incl. spawn-request template `0x100e64b0`) | MED | dump |
| `FUN_10018070` / `FUN_100180e0` | Notice module start (registers console command `NOTICE`) / stop | MED | strings "Notice", "NOTICE", "Displays a text message…" |
| `FUN_10018130` | notice state reset (colour 'CEGA' default) | MED | dump |
| `FUN_100181e0` | post / clear a notice (text ≤ 0x3f, sound block, fade flags) | MED | dump; callers destroy/console |
| `FUN_10018320` | notice tick: sound on first show, PermFloat 71/72/73 appearance time, fade in/out | MED | dump |
| `FUN_100184b0` | draw current notice text | MED | dump (`FUN_1000d130(0x31)`, `FUN_1000d380`) |
| `FUN_10018670` | static init (notice globals) | HIGH | dump — ⚑ corrected (review wave 3, 2026-10-06) #L: was LOW on dump; TU init of the notice module (D/P/T/S templates), static-init-audit.md §3 table A (listing + interpreter); function-roles.md row |

## Worked example — Shuriken (`shur`, 17 placements; 10–11 per group)
Data (`grep -nE '#(initial|state(Name|OnRange|OnTimer|MaxSpeed|Delta|Flee|Hunts|NumDir|FramesPer|FrameDel|DoLoop))' "$W/data/Game/unde/Shuriken[shur].unde.txt"`):
`initialHeading_INT 180`, tolerance 0, `initialSpeedMin/Max 5.0/7.0`, air. States used below:
| state | MaxSpeed | Delta | Hunts | OnRange → | timer → |
|---|---|---|---|---|---|
| Move South, Wait Range, RULE | 7.0 | 0.0 | F | 140 → RULE - Wait Anim Done | 50–60 → Hunt Player, Wait Range |
| RULE - Wait Anim Done | 6.0 | 0.25 | T | — | rule "Animation Has Stopped" → Open |
| Open | 6.0 | 0.25 | T | — | 5 → Savage Players |
| Savage Players | 9.0 | 0.45 | T | — | 90–110 → Retreat |
| Retreat | 7.0 | 0.4 | F | flee `soce`, FleeSpeed 8.0, FleeDelta 0.15 | — |
Scenario: emitted by `07s1` at absolute (208, −100) (waves §4), one player alive at its start
point (208, 330), speed draw = 6.0.
1. Spawn: compass 180 → `h' = 180 − 180 = 0`; v = 6·(S[0], C[0]) = (0, 6) (down). State-0 entry
   (`param_2 = 1`): s = 6, M = 7, D = 0 → step = min(0, 1) = 0 → s1 = 6 → accel = 6·(0,1) −
   (0,6) = (0,0); desired = (0,7). Each tick `FUN_10017a10`: vy 6 < 7 → vy += 0 → stays **6 px/tick**.
2. Range: the range test runs before integration in the same update (§1), so at the test of
   update n the centre is at y = −100 + 6(n−1); `dist = sqrt(trunc(0² + (330 − y)²)) = 430 −
   6(n−1)`; n = 49 → 142 (not < 140), **n = 50 → 136 < 140** → "RULE - Wait Anim Done" (the 50–60-tick
   timer would fire one or more ticks later, so the range trigger wins). Update 1 is the first
   update the entity gets; whether that is its spawn tick is open (spawn-and-waves.md NR 4), so the
   trigger tick may shift by one more. [MED] ⚑ corrected (review wave 1, 2026-10-03) #M4: was
   "before update n the centre is at y = −100 + 6n … n = 49 → 136" (off by one update).
3. Entry (`param_2 = 0`): h' = angle of (0,6) = 0; s = 6 = M → step 0, s1 = 6 → accel 0, desired
   (0,6). Same tick, new state Hunts → `FUN_10016cc0` with M 6, D 0.25: x = 208 = tx → **tie →
   ax = −0.25**; y = 194 < 330 → ay = +0.25 → v = (−0.25, 6.25) → vy clamped to 6 → v = (−0.25,
   6); integrate → (207.75, 200). Next tick x < tx → ax = +0.25 → vx = 0; then +0.25, … the x
   axis dithers around 208 while vy holds 6 until y passes 330 (then ay = −0.25 per tick: it
   takes 48 ticks to reverse vy from +6 to −6 — the overshoot is ≈ 6²/(2·0.25) = 72 px).
4. Animation (NumDirections 1, FPD 6, FrameDelay 0, FrameDelta 1, loop F): dir = trunc(1·180/360)
   = 0, base 0, last 5; frames 0→5 one per tick; the step that finds frame == 5 sets
   "stopped"; rules run after the animation in the same tick → "Open" ~6 ticks after entry.
5. "Savage Players": entry recomputes accel/desired from the current v; hunting with M 9, D 0.45 —
   per-axis cap 9, i.e. up to 12.7 px/tick diagonally.
6. "Retreat": `stateFlee_ID soce` → fleeing, target (416·0.5, 2000) = (208, 2000); from then on
   `FUN_10016cc0` with M 8, D 0.15 toward y = 2000 until `y > 480 + 128` → silent delete.
[MED as a whole — every step is a HIGH reading above, but the scenario (speed draw, spawn-delay
offset, which of timer/range fires first for a given member) is constructed, not observed]

## NOT RESOLVED (this file)
1. ~~`FUN_10042cd0` (heading of a vector) not listing-checked: the octant constants are resolved
   but the branch directions are from the dump (MED). Settles: read `10042cd0..` listing.~~ → ⚑ corrected (review wave 3, 2026-10-06) #S: loose-ends-combat.md §1.2: full branch walk of `FUN_10042cd0` (listing `10042cd0..10042e8c`) (critic wave 3 §3).
2. Writer of entity `+0xc3` (spawn-set gate) and initial values of the 0x18-byte spawn runtime
   record — presumably `FUN_10017cb0` (spawn reader's scope).
3. No-player fall-through in `FUN_10015280`: the target written to `+0x11c/+0x120` is read from
   `FUN_10005d40`'s uninitialised stack slot (`10005e68..10005e84` with r23 = −1 → `r1+0x3c`).
   Unobservable while `+0x118 = −1` gates the turn and seek is not called with it — except a
   cyclic/constrained/Hunts state with no player: Hunts is skipped (`hunt` is only set when a
   player exists), so believed harmless. A replica can store (0,0). → ⚑ corrected (wave 3+4, 2026-10-04) (critic O6): closed —
   the stale target is never read (only readers `FUN_10016cc0`/`FUN_100172d0`, both gated); the next tick with a
   player overwrites it (gameplay-leftovers.md §7.3).
4. ~~Which spawn record supplies `+8` for the air flag in `FUN_10035cd0` (`param_2`): level object
   group vs unit def (`FUN_10033850` also tests `unit+8 == 'grnd'`). Spawn reader.~~ → ⚑ corrected (review wave 3, 2026-10-06) #S: loose-ends-combat.md §7.4 (which record supplies the air flag) (critic wave 3 §3).
5. `FUN_10012940` frame size source `FUN_10019ca0`/`FUN_10019c10` (U_Sprite, not read) — half
   sizes assumed = frame cell size / 2.
6. ~~Exact per-second speeds: depend on the game-speed divider whose writer is unresolved (INDEX #12).~~ → ⚑ corrected (review wave 3, 2026-10-06) #C8: timing-frame.md §3: there is no divider writer — the game always runs at "Normal"; per-second speeds follow from 30.07 ticks/s (timing-frame.md §4) (#C8, critic wave 3 §3).
7. Owner lock/link/orbit (`FUN_10037130/7230/7350`) overwrite position after integration; their
   use of `vx` as orbit rate (§5.6) and of `+0xe0` (§4) — spawn reader.
8. Notice module (`FUN_10018070…FUN_100184b0`) read only at MED; fade arithmetic not checked.

## Role-table rows (for merge)
| function | module | role | conf | evidence |
|---|---|---|---|---|
| `FUN_10012ca0` | G_GameObject (span) | integrate position: ground `y += scroll delta`; `x += vx; y += vy`; cull with margin (128) | HIGH | listing `10012cc0..10012e30` (units-movement.md §2.1, §7) |
| `FUN_10012910` | G_GameObject (span) | set position (x,y) | MED | dump; callers `FUN_10037930`, `FUN_10028170` — ⚑ label audit (review wave 1) |
| `FUN_100128d0` | G_GameObject (span) | get position | MED | dump — ⚑ label audit (review wave 1) |
| `FUN_10012ad0` | G_GameObject (span) | bounding box from centre ± half size | HIGH | dump — ⚑ label audit (review wave 1): HIGH kept — listing evidence in damage-health-death.md role rows |
| `FUN_10012650` | G_GameObject (span) | object reset (air=1, layer `defa`, sprite none) | HIGH | dump — ⚑ corrected (micro-wave, 2026-10-06) #§3.6: listing in micro-wave-2026-10-06.md §3.6 (function-roles.md row). Was MED |
| `FUN_100142f0` | G_Entity.cc (span) | entity reset (target none `+0x118=−1`, velocities 0) | MED | dump — ⚑ label audit (review wave 1) |
| `FUN_100144a0` | G_Entity.cc | bind unit def; allocate per-state spawn runtime lists | MED | strings `newSpawnInfoPtr`, `G_Entity.cc` — ⚑ label audit (review wave 1) |
| ⚑ corrected `FUN_100146f0` | G_Entity.cc | change state by name (last match wins) + velocity ramp set-up (accel = s1·dir − v, desired = MaxSpeed·dir) + flee start/stop | HIGH | listing `10014bac..10014db4`; was MED "change state by name" |
| `FUN_10014670` | G_Entity.cc (span) | enter `UseThisStateOnWeaponPowerupRelease` state | HIGH | dump `+0x835` — ⚑ label audit (review wave 1) — ⚑ corrected (micro-wave, 2026-10-06) #§3.3: listing in micro-wave-2026-10-06.md §3.3 (function-roles.md row). The state is entered **by its name** (`stateName_STR`) via `FUN_100146f0`; duplicate names would pick the last match (none in shipped data). Was MED |
| `FUN_10017e70` | G_Entity.cc (span) | enter `UseThisStateOnShieldDepletion` state | HIGH | dump `+0x836`; caller `FUN_10014f10` — ⚑ label audit (review wave 1): HIGH kept — listing evidence in damage-health-death.md role rows |
| `FUN_10015280` | G_Entity.cc (span) | motion controller: nearest player, no-player actions, cyclic, constrain, OnRange trigger, hold/hunt/ramp | HIGH | listing `10015280..1001554c` |
| `FUN_10015930` | G_Entity.cc (span) | sprite animation step (row from heading, loop/ping-pong/stop, random frames) | HIGH | listing `10015930..10015b20` |
| `FUN_10015b40` | G_Entity.cc (span) | rotation gate + per-tick spawn-set emitter (rate/volley/delay, rotated/absolute offsets) → `FUN_10033220` | HIGH | listing `10015b40..100161b0` |
| `FUN_10016cc0` | G_Entity.cc (span) | seek target: per-axis ±Delta, clamp ±MaxSpeed (flee speeds when fleeing) | HIGH | listing |
| `FUN_10016da0` | G_Entity.cc (span) | constrainInGameArea bounce | HIGH | listing |
| `FUN_10016fe0` | G_Entity.cc (span) | cyclic motion (2 RNG draws/tick) | HIGH | listing |
| `FUN_10017a10` | G_Entity.cc (span) | ramp velocity to desired; stationary zero; orbit rate | HIGH | listing |
| `FUN_10017b70` | G_Entity.cc (span) | hold position (accelerate away, HoldMaxSpeed/HoldDelta) | HIGH | listing |
| `FUN_10017c40` | G_Entity.cc (span) | reverse on reaction (desired = −dir·MaxSpeed) | HIGH | listing |
| ⚑ corrected `FUN_10017510` | G_Entity.cc (span) | flee target by 4CC code (13 codes), sets fleeing | HIGH | listing; was MED "flee targets" |
| `FUN_100172d0` | G_Entity.cc (span) | turn sprite one direction step toward target | HIGH | listing |
| `FUN_10017150` | G_Entity.cc (span) | rotation-pause gate (spawning) | HIGH | dump + listing |
| `FUN_10017ef0` | G_Entity.cc (span) | nearest active player within range (strict <) | HIGH | listing |
| `FUN_10016bd0` | G_Entity.cc (span) | entity centre on screen | HIGH | listing |
| `FUN_100161c0` | G_Entity.cc (span) | heading of current frame | MED | dump |
| `FUN_10016230` | G_Entity.cc (span) | frame for heading (rounded) | HIGH | dump — ⚑ corrected (micro-wave, 2026-10-06) #§3.2: listing in micro-wave-2026-10-06.md §3.2 (function-roles.md row). Rounding is single precision; negative quotients truncate toward 0. Was MED |
| `FUN_10005d40` | G_Game (span) | nearest active player: pos, distance, player number (ties → player 1) | HIGH | listing `10005d40..10005ec0` |
| ⚑ corrected `FUN_10026c90` | G_Player.cc (span) | get player number (`+0xcc`) | HIGH | dump one-liner; `FUN_10026410` "Setting Up Player %i"; was described as "player hit" in waves §3 step 8 / INDEX #24 — ⚑ label audit (review wave 1): HIGH kept — listing evidence in player-physics.md role rows |
| `FUN_10042920` | trig (span) | build atan/sqrt/sin/cos tables | HIGH | listing; glue `cos`/`sin`/`atan`/`sqrt` |
| `FUN_10042ad0` / `FUN_10043090` | trig | heading (compass int) from two points | HIGH | listing |
| `FUN_10042ee0` / `FUN_10042f00` | trig | cos / sin of int degrees (table) | HIGH | listing |
| `FUN_10042b80` / `FUN_10042b30` | trig | vector = speed·(sin h', cos h') | HIGH | listing |
| `FUN_10042f20` | trig | sqrt(int) via table < 16384 | HIGH | listing |
| `FUN_10043040` | trig | compass ↔ internal heading (180 − h) | HIGH | listing |
| `FUN_1000fed0` | G_Background (span) | pixels scrolled this tick | MED | dump; writer `FUN_10010220` — ⚑ label audit (review wave 1) |
| `FUN_10018070`…`FUN_100184b0` | Notice (strings) | notice start/stop/reset/post/tick/draw (see §10) | MED | strings + dump |
| `FUN_100125d0` / `FUN_100141a0` | G_GameObject / G_Entity | constructors | MED | dump |

## INDEX updates (for merge)
- **#19 closed** → units-movement.md §1 (call order, the three functions are animation / motion
  controller / spawn emitter), §2 (px/tick, centre position, compass heading, trig tables), §4–§6.
- **#20 narrowed** → the per-tick spawn-set executor is `FUN_10015b40` (§9: rate, volley,
  delay, offsets, absolute coordinates, rotation, scale, SetHeading); the record initialiser
  `FUN_10017cb0` remains with the spawn reader. ⚑ conflict: INDEX #20, waves-and-enemies.md §3
  step 9, §4 and §8 item 2 name `FUN_10036cf0` as the spawn-set executor; its head (read here,
  MED) is an entity-vs-entity collision loop over all groups testing `harmlessToPlayers`
  (+0x11a), `playerProjectile` (+0x11b), `canBeHitByPlayerProjectile` (+0x11c) and same layer.
- **#22 narrowed** → `FUN_10017ef0` resolved (§5.8: nearest active player, `dist < range`,
  range ≠ 0). `FUN_10034ee0`, `FUN_10035070` remain (spawn reader).
- **#24 corrected** → `FUN_10026c90` is a player-number getter (HIGH, §5.1); the player-hit call
  in `FUN_10033850` step 8 is `FUN_10027100(player)` (LOW — call position; bank row says "player
  hit spawn delay"). ⚑ conflict with waves-and-enemies.md §3 step 8.
- waves-and-enemies.md §8 item 1 closed by the same sections; key-name note: the bank's
  "Delta 0x45c" is `#stateDelta_FLOAT` (the brief's "stateSpeedDelta").
