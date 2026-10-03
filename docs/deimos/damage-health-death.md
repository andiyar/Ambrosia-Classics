# Deimos Rising 1.0.6 — collisions, damage, shields, death and destruction

**Scope.** Three things. (1) The math/collision module `0x10042100–0x100432d0`: every function
in it, including the collision test `FUN_10042f80`. (2) The collision steps of the entity update
`FUN_10033850`: player↔entity, entity↔ground obstacle, and the call into the entity↔entity
(projectile) test `FUN_10036cf0`. (3) Damage and death: entity damage `FUN_10014f10`, destroy
`FUN_10016300`, water impact `FUN_10016880`, player hit `FUN_10027100`, the accessors
`FUN_10026c90`/`FUN_10026c10`, the shield-depletion state switch `FUN_10017e70`, the pickup
dispatcher `FUN_10037580`, the deletion sweep `FUN_10036610`/`FUN_10036120` (coins, group kill,
owner destruction) and player death `FUN_10027e50` (what it does to the hit path only).
**OUT (handed off):** how the random bonus is chosen inside `FUN_10016300` (scoring reader;
only the moment it is invoked is described here); the player state machine, the lives
arithmetic and respawn `FUN_1002a150`/`FUN_10029cc0` (player reader; only the hook is
described); movement executors; how the spawn sets execute. Code readings only, nothing
behaviour-verified. `$W` = `/Users/andiyar/ghidra-proj-deimos`. Raw listings:
`$W/disasm-dmg.txt` and `$W/disasm-dmg2.txt` (DisasmFuncs.java, run against the private copy
`$W/work-dmg`). Constants were resolved with a Python reader over `$W/mem/10000000.bin` and
`$W/mem/100de330.bin` (command in §0).

**Answer up front.** There are no pixel masks and no per-pixel collision. Every hit is first an
inclusive bounding-box overlap and then a **circle test**. Each circle's radius is **half the
bounding-box HEIGHT**. Damage is the *other* party's unit-def `damage_FLOAT` (+0x274). A
player ramming an enemy deals a flat 100 (flli 161). Entity shields are one float at
entity+0x134. They hit 0 → destroy, unless the unit has a `UseThisStateOnShieldDepletion` state.
A victim accepts a hit only when `now > lastHit + 1` (flli 167), so it can take at most one
hit every 2 ticks. That limit is per victim, so a second bullet in the same window is spent
without effect. Player shields are a percentage stored as a float biased by +1324366.0, which
in effect rounds them to 1/8 %. Each hit costs `damage_FLOAT × shieldBaseHitPercentage`
(15). The player dies only when shields fall **below** 0.

## 0. Constant resolution
Command (scratchpad `rd.py`: read big-endian u32/f32/f64 from the two images; data image for
≥ 0x100de330, code image below):
```
python3 -c "from rd import *; p=u32(0x100df510); print([f64(p+8*i) for i in range(9)])"
```
| TOC slot | → | values | used by |
|---|---|---|---|
| `0x100df4fc` (r2−0x6e34) | `0x10106790` | float[360] **sin(h°)** | `FUN_10042f00` |
| `0x100df500` (r2−0x6e30) | `0x10106d30` | float[360] **cos(h°)** | `FUN_10042ee0` |
| `0x100df504` (r2−0x6e2c) | `0x100d7318` | 0.0174533, 0.0, 180.0, 90.0, 270.0, 1.035 | deg→rad, `FUN_10042cd0` axis cases |
| `0x100df508` (r2−0x6e28) | `0x101072d0` | float[16384] **sqrt(i)** | `FUN_10042f20`, `FUN_10042f80` |
| `0x100df50c` (r2−0x6e24) | `0x101172d0` | int[1024] `trunc(atan(0.01·i)·57.2957795)` | `FUN_10043090` |
| `0x100df510` (r2−0x6e20) | `0x100d732c` | 0.01, 57.2957795, 2⁵²+2³¹, 57.29577951, 180, 360, 270, 0.0, 100.0 | table init / int→float bias |
| `0x100df440` | `0x100d7204` | 0.5, 0.7, 0.9, 32.0, 0.0 … | player radius factor (0.5) |
| `0x100df448` | `0x100d7228` | bias, **100.0**, 0.0, 0.2 | visibility threshold |
| `0x100df128` (r2−0x7208) | `0x100d6ca4` | bias, **0.0**, 0.5 | entity shield compares |
| `0x100df138` (r2−0x71f8) | `0x100d6c8c` | **0.0**, 360.0, 1.0, −32.0 | shield clamp value |
| `0x100df2f8` (r2−0x7038) | `0x100d6fdc` | bias, 100.0, **0.0** | player compares |
| `0x100df304` (r2−0x702c) | `0x100d6fc8` | 0.0, 100.0, **1324366.0** (+8) | player shield bias |
| `0x100df12c` (r2−0x7204) | `0x100d6804` | `"none"` | destructNotice compare |
Glue: `0x100d5754 atan`, `0x100d576c sqrt`, `0x100d5784 cos`, `0x100d579c sin` (dump headers
`// ==== cos @ 100d5784 ====` etc.). [HIGH — image bytes]

## 1. The math/collision module (0x10042100–0x100432d0)
No strings. Called from many modules. The inventory brackets it as "~after G_UnitDefinitions";
it is a math module (proposed name `U_Math` — LOW, name pattern only).

| function | role | label | evidence |
|---|---|---|---|
| `FUN_10042920 @ 10042920` | builds the tables at app start: atan int[1024] (`i ≤ 0x3ff`), sqrt float[16384], cos/sin float[360]; sets `DAT_100e0265=1` | HIGH | listing `10042970–100429bc` (`bl atan … fmul f0,f1,f0 (×57.2957795); fctiwz; stw`), `100429cc–10042a00` (`bl sqrt; frsp; stfs`, `cmpwi r31,0x4000`), `10042a18–10042a6c` (`fmuls f30,f31,f0` = i·0.0174533; `bl cos`→r30=0x100df500 table, `bl sin`→r31=0x100df4fc table, `cmpwi r25,0x168`); only caller `FUN_100000e0` (app init) |
| `FUN_10042a90` | tears the tables down (`FUN_1003a900`, clears the flag) | MED | decompile; caller `FUN_10000630` |
| `FUN_10042f20 @ 10042f20` | `sqrtI(n)`: `n < 0x4000` → table[n], else libm `sqrt((double)n)` → float | HIGH | listing `10042f24 cmpwi r3,0x4000; bge; lfsx f1,r4,r0` / `bl 0x100d576c; frsp` |
| `FUN_10042e90 @ 10042e90` | distance between two float points = `sqrtI(trunc(dx²+dy²))` | HIGH | listing `fsubs/fmuls/fmadds; fctiwz; bl 0x10042f20`; callers `FUN_10033600`, `FUN_10034ee0` (tracking rule), `FUN_10035070` (active rule) |
| `FUN_10042c90` | vector length, libm `sqrt(x²+y²)` | HIGH | listing `10042c9c–10042cb8`; caller `FUN_100146f0` |
| `FUN_10042f00 @ 10042f00` | `sin(h)` table lookup, h==360 → 0 | HIGH | `cmpwi r3,0x168; …; lwz r4,-0x6e34(r2); lfsx f1` |
| `FUN_10042ee0 @ 10042ee0` | `cos(h)` table lookup, h==360 → 0 | HIGH | same with `-0x6e30(r2)` |
| `FUN_10042b30 @ 10042b30` | heading → unit vector **(x, y) = (sin h, cos h)** (heading 0 = +y, down the screen) | HIGH | `bl 0x10042f00; stfs f1,0x0(r31); bl 0x10042ee0; stfs f1,0x4(r31)`; caller `FUN_10037930` (group placement) |
| `FUN_10042b80 @ 10042b80` | `speed·(sin h, cos h)` (f1 = speed) | HIGH | `fmuls f0,f31,f1` ×2; callers `FUN_100146f0`, `FUN_10037350`, `FUN_10037b50` |
| `FUN_10042bf0 @ 10042bf0` | normalise (x,y) by `sqrtI(trunc(trunc(x)·x + y²))`. **Quirk: x is squared as trunc(x)·x** | HIGH | `fctiwz f1,f30` → int(x) → float; `fmadds f0,f1,f30,f0`; `fdivs` ×2; caller `FUN_10037b50` |
| `FUN_10043090 @ 10043090` | heading from (dx=f1, dy=f2) using the table: `a = |atanT[clamp(int(100·min/max),0,1023)]|`; if \|dx\|<\|dy\| a = 90−a; then dx<0&dy≥0 → 180−a, dx<0&dy<0 → a+180, dx≥0&dy<0 → −a; result `(a−90) mod 360` | HIGH | listing `10043090–100431e8` (`lfd f0,0x40(r5)`=100.0, `subfic r3,r3,0x5a`, `subfic …0xb4`, `addi …0xb4`, `neg`, `subic. r3,r3,0x5a; addi …0x168`) |
| `FUN_10042ad0 @ 10042ad0` | heading from int points: `FUN_10043090(x1−x2, y1−y2)` | HIGH | `subf r7,r5,r3; subf r0,r6,r4; … bl 0x10043090`; callers `FUN_100172d0`, `FUN_10033600` |
| `FUN_10043040 @ 10043040` | mirror heading `h' = (180 − h) mod 360` (`h ≤ 180 → abs(h−180)`, else `540−h`) | HIGH | `cmpwi r3,0xb4; subi r3,r3,0xb4; bl 0x1004ee30` (abs, decompiled `(x>>31^x)-(x>>31)`); `subfic r0,r3,0x21c` |
| `FUN_10042cd0` | heading of a float vector via libm atan; axis cases from the `0x100d7318` table: (0,0)/(0,+y) → 0, (0,−y) → 180, (+x,0) → 90, (−x,0) → 270; first quadrant `atan(x/y)·57.2958`; ≥360 → 0 | MED | decompile + table; full branch listing not walked; callers `FUN_100146f0`, `FUN_10037b50` |
| `FUN_10042f80 @ 10042f80` | **circle overlap test** (§2.1) | HIGH | listing below |
| `FUN_100426e0` | writes a data file in `Data` (type/creator `Data`/`Deim`); "FILE ERROR: Could not create new…", "Data Saved: %s"; used by the units-cache writer | MED | decompile strings; caller `FUN_10041e40` (cache builder) |
| `FUN_100428b0` | static initialiser: copies three constant records into globals `0x100ecfc8…0x100ed008` | LOW | decompile; caller `FUN_10000000` |
| `FUN_100431f0` | an init routine: `FUN_1003a870(…)`, `FUN_10044630()`, then **two `RandomRange(0,99)`** into `_DAT_100e026c`/`_DAT_100e0268`, then `FUN_1002d080` | LOW (role) / HIGH (RNG calls in the decompile) | caller `FUN_100000e0` (app init). These are RNG consumers at app init (engine-loop.md §9 handoff) — ⚑ corrected (wave 2, 2026-10-03): particle module init; 302 draws (300 in `FUN_10044630` + 2), all before any `srand`; see particles-debris-blur.md §1 |
| `FUN_10043280` | the teardown paired with `FUN_100431f0` (`FUN_10044550`) | LOW | decompile; caller `FUN_10000630` |

Heading convention check [MED]. `FUN_10042b30` and `FUN_10042cd0` agree: heading h ↔ vector
(sin h, cos h). For that same vector `FUN_10043090` returns `−h`. The caller `FUN_10033600`
(dump l. 30641–30643) follows `FUN_10042ad0(p1,p2)` with `FUN_10043040`, giving
`180 − (−h) = h + 180`. That is the heading of p2 − p1, so the composition is consistent. The
caller in `FUN_10017150` (l. 13621) uses `FUN_10042ad0` without the mirror. Movement reader:
check its sign. ⚑ corrected (wave 2, 2026-10-03): the convention is settled — compass h (data keys, `+0x138`,
`FUN_10043090`/`FUN_10042ad0` results) vs internal h' = (180 − h) mod 360 (`FUN_10042b30/2b80`
input, `FUN_10042cd0` output); `FUN_10017150` is the rotation gate that calls `FUN_100172d0`
(turn toward target), not a spawn-set reader — see loose-ends-combat.md §1.3, §7.1.

## 2. Collision tests

### 2.1 `FUN_10042f80(posA r3, —r4, posB r5, rA f1, rB f2) → bool` [HIGH]
```
10042f9c  lfs f3,0x4(r3) / lfs f0,0x4(r5) / fsubs f2,f3,f0      dy
10042fa4  lfs f1,0x0(r3) / lfs f0,0x0(r5) / fsubs f1,f1,f0      dx
10042fb4  fmuls f0,f2,f2 / fmadds f0,f1,f1,f0 / fctiwz f0,f0    d2 = trunc(dx²+dy²)
10042fc8  cmpwi r0,0x4000 / bge → sqrt((double)d2) else lfsx table[d2]
1004300c  fadds f0,f30,f31 / fcmpo cr0,f1,f0 / mfcr / rlwinm r3,r0,1,31,31   return dist < rA+rB
```
r4 is never read. The comparison is **strict** (CR0 LT bit). The distance is `sqrt` of the
*truncated* integer d², so sub-pixel offsets are lost. Callers: `FUN_10033850` (player),
`FUN_10036cf0` (entity↔entity).

### 2.2 Bounding boxes [HIGH]
Entity half-size: `+0x2c` = width/2 and `+0x30` = height/2, as ints. `FUN_10012940` writes
them from `U_Sprite_GetDimensions` (`FUN_10019ca0(sprite +0x1c, frame +0x20, &wh +0x24)`):
`+0x2c = w/2`, `+0x30 = h/2` (int division) [MED — the scale argument f1 of FUN_10019ca0 was
not read]. Two rect builders read the entity position float `+0x00/+0x04` and the half-size:
- `FUN_10012ad0(e, &l, &t, &r, &b)`: `l = trunc(x − hw)`, `t = trunc(y − hh)`, `r = trunc(x + hw)`,
  `b = trunc(y + hh)` (listing `10012ad0–10012b98`: `lwz r8,0x2c(r3) … fsubs … fctiwz … stw r0,0(r4)`,
  `0x30` → r5, `fadds` → r6/r7).
- `FUN_10012a00(e, int rect[4])`: the same values in **Mac Rect order** `{top, left, bottom,
  right}` (listing: `stw r0,0x4(r4)` = x−hw, `0x0(r4)` = y−hh, `0xc(r4)` = x+hw, `0x8(r4)` = y+hh).

### 2.3 Player ↔ entity (`FUN_10033850`, listing `10033894–100339c4`, `10034088–1003430c`) [HIGH]
Once per tick, before the entity loop, for each player slot p = 0,1 (`FUN_10005d20(p)`):
- the slot counts only if the player state (+0xc6) == 4 (`bl 0x10026c60` with `li r4,0x4`).
  For counted slots the tick caches: rect `FUN_10012a00`, crosshair `+0x2cc`, the ground-accuracy
  flag `+0x361`, position, and **radius = (bottom − top) × 0.5** (float, `subf r0,r5,r4 …
  lfs f0,0x0(r15)` = 0.5, `fmuls`).
- r24 = `trunc(flli 54 VisibleGameWidth) + 32` = 448; r23 = `trunc(flli 55)` = 480.

Each entity (spawned in, not deleted after movement) is tested if **all** of these hold:
`count of active players > 0`; state `Collides` (+0x347); unit **not** `harmlessToPlayers`
(+0x11a); state `CollidesWithPlayers` (+0x34f); entity rect `right ≥ −32`, `left ≤ 448`,
`bottom ≥ 0`, `top ≤ 480` (`cmpwi r0,-0x20; blt`, `cmpw r0,r24; bgt`, `cmpwi r0,0; blt`,
`cmpw r0,r23; bgt`). Visibility (+0xac) is **not** checked here.
Then, per active player while the entity is not deleted:
1. inclusive AABB: `e.bottom ≥ p.top`, `e.top ≤ p.bottom`, `e.right ≥ p.left`, `e.left ≤ p.right`.
2. circle: `FUN_10042f80(playerPos, —, entityPos, f1 = playerRadius, f2 = (e.bottom − e.top)/2)`.
   The entity radius uses C signed division (`rlwinm r0,r3,1,31,31; add; srawi r0,r0,1` at
   `10034188`).
3. hit, and the unit's `pickup_Type_ID` (+0x4d4) **is `none`**:
   - the entity takes **flli 161 `Player_ImpactDamageToEntities` = 100**, credited to that
     player's index (`bl 0x10026c90` → r5; `li r3,0xa1; bl 0x10020250` → f1; `bl 0x10014f10`).
     If the state has `passHitsToOwner` (+0x32b) and the owner is alive (`FUN_10036ab0(e+0x140)`),
     the owner (`e+0x140`) takes it instead.
   - then the player takes the unit's **`damage_FLOAT`**: `100342c0 lfs f1,0x274(r31); … bl
     0x10027100` (§5).
   - if the player is no longer in state 4 (`bl 0x10026c50; cmplwi r0,0x4`), that slot drops out
     for the rest of this tick (`stb 0,0(r16); subi r22,r22,1`).
4. hit, and the unit **is a pickup**: `FUN_10037580(player, entity)` (§6). If it returns true, the
   entity is destroyed with `killer = player index` (`bl 0x10016300`) and `entity+0xca = 1`
   ("collected" — this stops its coin release, §4.3).
The ramming damage goes through the normal damage path, so a ramming kill **scores**
(`FUN_10014f10` → `FUN_10006190(player, score_INT)`).

### 2.4 Entity ↔ ground obstacle (`FUN_10033850` `100344ec–1003456c`) [HIGH]
If `entity+0x13c == 0` (not already stopped/stationary), `entity+0x19 == 0` (the entity's group
is not on the `air ` layer: `FUN_10035cd0` sets `*(bool*)(e+0x19) = group.layer == 'air '`, dump
l. 32223) and the unit has `collidesWithGroundObstacles` (+0x128):
`FUN_1002a830(rect)` tests the entity's Mac rect against every rect in the debris list
`_DAT_100e01cc`. The test is inclusive on all four sides (decompile `deb.top ≤ e.bottom &&
e.top ≤ deb.bottom && deb.left ≤ e.right && e.left ≤ deb.right`) [MED for the inequalities —
decompile only]. On a hit: velocity `+0x10/+0x14 = 0.0` (`lfs f1,0x0(r14)` ← `{0,0}` at
`0x100d7194`), `+0x13c = 1` (stopped for good), and if `destructCreateObstacle` (+0x4b3) the
entity's own rect is appended to the debris list (`bl 0x1002a6d0`). Stopped tanks therefore
become obstacles themselves, and a queue forms behind them.
Other writers of the debris list: `FUN_10016300` (destroyed units with destructCreateObstacle
that were not spawned on the air layer, §4.1) and `FUN_10035cd0` (spawned already stationary,
`+0x13c` from spawn request +0x1c, with destructCreateObstacle; dump l. 32238) [MED].
`FUN_1002a6d0` allocates a 0x10-byte rect ("newDebris", G_Debris.cc). [HIGH]

### 2.5 Entity ↔ entity — `FUN_10036cf0(A, now) @ 10036cf0` [HIGH]
⚑ conflict: the bank calls this the "state spawn sets executor" (function-roles.md §1 LOW;
waves-and-enemies.md §3 step 9, §4, §8 #2; INDEX #20). It is not. It is the entity-vs-entity
collision and mutual-damage pass. It reads no spawn-set list. The per-tick spawn-set executor is
`FUN_10015b40` (spawn-and-waves.md §2.3); `FUN_10017150` (its first callee) reads state+0x5dc only
to hold **rotation** while a `PauseAnyRotationWhileSpawning` volley is mid-way — it is the
rotation gate, not a spawn-set reader [HIGH — listing `10017180 lbz r0,0x303(r31)`, `10017210
lwz r3,0x5dc(r31)`, `1001725c lbz r0,0x48(r25)`, `10017268–1001727c` 0 < left < volley, `100172a4
bl 0x100172d0`]. ⚑ corrected (review wave 1, 2026-10-03) (conflict): was "The runtime reader of state+0x5dc is `FUN_10017150` …
[LOW — one grep hit]".
Called from `FUN_10033850` (`1003458c … bl 0x10036cf0`), last in the entity's update, when the
entity is not deleted and its state `Collides` (+0x347). A = the entity being updated.
- A gate: if A is a `playerProjectile` (+0x11b), it needs `A.bottom ≥ 0` (`10036d64–10036d78`).
- For every entity B in every group, B is a candidate if **all** of these hold (listing
  `10036e18–10036ebc`):
  B's state `Collides`; B not deleted (+0xcb); **B+0xac set** (§2.6); `B+0x9c ≠ A+0x9c`
  (different entity serial); **same layer**: `B.unit+8 == A.unit+8`; **exactly one** of A/B
  is `harmlessToPlayers` (`10036e58–10036e7c`); B spawned in (`B+0xb0 ≤ 0`); and
  - if A is a playerProjectile: `B.canBeHitByPlayerProjectile` (+0x11c);
  - else: `B.canBeHitByPlayerProjectile && B.playerProjectile`.
  If B is a playerProjectile, it also needs `B.bottom ≥ 0`.
- inclusive AABB (`10036ef8–10036f34`), then the circle test with `rA = (A.b − A.t)/2`,
  `rB = (B.b − B.t)/2` (signed int division, `10036f60–10036fb0`).
- hit:
  1. **A takes `B.unit.damage_FLOAT`**, credited to `B+0xd8` (owner player index):
     `1003704c lfs f1,0x274(r4); lbz r5,0xd8(r19); bl 0x10014f10`. If A's state has
     `passHitsToOwner` and A's owner is alive (`A+0x140` non-null, `A+0x144 == owner+0x9c`,
     owner not deleted), A's owner takes it.
  2. **B takes `A.unit.damage_FLOAT`**, credited to `A+0xd8` (`100370d8 lfs f1,0x274(r27); lbz
     r5,0xd8(r17)`). If **B's** state has `passHitsToOwner`, the code tests and damages **A's**
     owner (`10037074 lwz r5,0x140(r17)` … `100370b4 lwz r3,0x140(r17)`), not B's. The listing
     carries this copy-paste bug; a 100 % replica keeps it. **Consequence:** a player shot is
     always A (next paragraph) and carries no owner (spawn-request template `0x100ecd14`
     +0x20 = 0, +0x24 = −1 (static init `FUN_1003ce60`, static-init-audit.md §5.2; ⚑ corrected (wave 3+4, 2026-10-04): was "+0x20/+0x24 = 0"
     from the data image); neither launcher `FUN_1003c4f0`/`FUN_1003c7a0` writes them), so the
     redirect never fires and a `passHitsToOwner` turret/bubble struck by a player shot takes the
     damage on its **own** shields (`100370d8–100370e8`); bubbles with 0.0 shields swallow it (§3).
     Only ramming (§2.3, the entity's own `+0x140`) passes damage to the owner. See bosses.md §3.5
     for the per-turret numbers. ⚑ corrected (review wave 1, 2026-10-03) #I1.
  3. if A is now deleted, stop scanning (`100370f0 lbz r0,0xcb(r17); bne exit`).
Layer: unit+8 is set after parsing in `FUN_1003fc50`: `'grnd'` if `isGroundBased` (+0x125)
else `'air '` (`1003fd20 lbz r0,0x125(r30); beq; lis r3,0x6772; addi r0,r3,0x6e64; stw r0,0x8(r30)`).
Air shots therefore never touch ground units, and the reverse holds too.

Consequence for the shipped data [HIGH — data + rule]. A player shot (`harmless TRUE,
playerProjectile TRUE, canBeHit FALSE`, e.g. `icb `, `plbo`) finds an enemy (`harmless FALSE,
canBeHit TRUE`) from the shot's own update. The enemy's update does **not** find the shot:
that would need the shot's `canBeHit`. So each pair is resolved once, in group-list order.

### 2.6 "Hittable" flag `entity+0xac` [HIGH]
Written every tick in `FUN_10033850`: `10033ea0 li r0,1; stb r0,0xac(r19); lfs f1,0x68(r19);
fcmpo f1,100.0; bge keep; lbz r0,0x121(r31); bne keep; stb 0,0xac(r19)`. It is set iff
visibility (+0x68) ≥ 100.0, or the unit has `hittableWhenInvisible` (+0x121). It is first set
at spawn by `FUN_10035cd0` from `initialVisibilityPercent` with the same rule (dump l. 32175–32181)
[MED]. Only the entity↔entity B side reads it.

## 3. Entity shields and damage — `FUN_10014f10(e r3, damage f1, — r4, killer r5, now r6) → f1` [HIGH]
Shield field: **entity+0x134 (float)**. It is written only at spawn (`FUN_10035cd0`) and here
(grep of `0x134)` / `[0x4d]` over the dump; the other hits are unrelated structs). Spawn value
(listing `10035e50–10035eb0`): `s = base(+0x43c)`. If `increment(+0x440) > 0.0`:
`s = s + increment × (float)(sector − 1)` (`fmuls`, `fadds` — single precision), then
`if s > max(+0x444): s = max`. The cap is applied **only inside the increment branch**.
Census (Python over 386 unit files): all **27** units with an increment are `isGroundBased`.
No air unit scales by sector. `Twin Gun` (12.0 + 0.4, max 12.0) is pinned at 12.0. [HIGH]

Listing walk (`10014f10–1001527c`):
| step | code | meaning |
|---|---|---|
| 1 | `lbz r0,0xcb(r3); bne exit` | deleted → ignore |
| 2 | `li r3,0xa7; bl PermFloat; fctiwz; lwz r0,0xb4(r26); add; cmpw r28,r0; ble exit` | **hit delay**: accept only if `now > lastHit(+0xb4) + trunc(flli 167 Entity_HitDelay = 1)` |
| 3 | `stw r28,0xb4(r26)` | lastHit = now |
| 4 | `fsubs f0,f2,f30; stfs 0x134` / `fcmpo …; bge; fmr f0,f31 (0.0); stfs` | `old = s; s = old − damage; if s < 0.0: s = 0.0` |
| 5 | `fsubs f31,f2,f0` | return value = `old − s` (damage absorbed; no caller reads it) |
| 6 | `cror eq,lt,eq … rlwinm r0,r0,3,31,31; … bne exit` | if `old ≤ 0.0` → stop (already dead) |
| 7 | `lbz r0,0x348(r30); beq; stfs f2,0x134(r26)` | state `Invulnerable_ShieldsDoNotDepleteOnCollision` → `s = old` |
| 8 | `lwz r3,0x3b8(r30) … lbz 0x59c … lwz r0,0xfc(r26); add; cmpw r28,r0; ble` → `stw r28,0xfc; bl 0x100146f0` | `OnHitChangeStateDelay ≠ 0` and `OnHitChangeTo` non-empty and `now > lastHitStateChange(+0xfc) + delay` → change to that state; if that deleted the entity → stop |
| 9 | `lfs f1,0x134; fcmpo 0.0; cror eq,lt,eq; bne alive` | **if s ≤ 0.0 → death branch** |
| 9a | `lwz r4,0x4b8(r29); or r3,r27; li r5,0; bl 0x10006190` | score `score_INT` to player `killer` (ignored unless 0 ≤ killer < 2: `FUN_10006190` decompile) |
| 9b | `lbz r0,0xcd(r26); bne → bl 0x10017e70` else `bl 0x10016300(e, killer, now)` | shield-depletion state if the unit has one, else destroy |
| 10 | `lbz r0,0x354(r30); bne; li r4,0x7fff; li r5,6; li r6,0; bl 0x10012bc0` | alive: hit glow white (0x7fff) speed 6, unless `DoNotGlowOnCollision` |
| 11 | `lwz r6,0x2d8(r29)` ≠ none → `bl 0x10043340` | `hitParticles_ID`, colour +0x17e, ground flag = (unit+8 == 'grnd') |
| 12 | state +0x348 == 0 → sound `shieldSound_ID` (+0x448); else `unshieldedSound_ID` (+0x460) | as the listing reads (`10015128` / `1001514c`) |
| 13 | `lwz r3,0x2e0(r30)` ≠ none, (`collision_RepeatSpawns` +0x2e4 or `+0xd4 == 0`), `now ≥ +0xd0 + collision_SpawnDelay (+0x2e8)` → `bl 0x10033220`; `+0xd0 = now; +0xd4++` | collision spawn at the entity position; owner byte +0xd8, parent = e, serial +0x9c |

`FUN_10017e70(e, now)` [HIGH]: walks states 0..numStates−1 and switches (`FUN_100146f0`) to the
**first** state whose `UseThisStateOnShieldDepletion` (state+0x356 ≡ unit+0x836+s·0x5e0) is set
(`10017e88 addi r0,r5,0x836; lbzx`). `entity+0xcd` = "unit has such a state": it is cleared, then
set if any state has the flag, in `FUN_10035cd0` (`10035dac stb r5,0xcd(r28)` … `10035dcc
stb r0,0xcd(r28)`). Shields stay at 0 and nothing resets them, so step 6 rejects every later
hit. Such an entity can no longer be damaged or scored again and must end by timer/rule.
Entities with base shields 0 (e.g. `grob` Ground Obstacle, FX units) can never be damaged. [HIGH]

Hit-delay consequences [HIGH]: (a) one victim takes ≤ 1 hit per 2 ticks. (b) The delay belongs
to the victim. The attacker still takes its own damage (it has its own +0xb4), so a second
bullet arriving in the delay window dies without effect. (c) `+0xb4` starts at 0
(`FUN_100142f0` entity reset, dump l. 11838) [MED].

## 4. Destruction and deletion

### 4.1 `FUN_10016300(e, killer r4, now r5) @ 10016300` [HIGH — listing `10016300–10016528`]
1. already deleted → return. `FUN_10012c00(e)` clears the glow (+0x74 = 0).
2. `e+0x19 == 0` (not spawned on the air layer) and `destructCreateObstacle` (+0x4b3) →
   its Mac rect joins the debris list.
3. `destructParticle_ID` (+0x47c) ≠ none → particles, colour +0x480, ground flag by unit layer.
4. `destructSpawn_ID` (+0x478) ≠ none **and** `FUN_10016880(e)` true → spawn request (pos,
   owner byte +0xd8, parent e, serial +0x9c).
5. `destructNotice_STR` (+0x482) non-empty and ≠ `"none"` → `FUN_100181e0(notice, now)`.
6. `destructSound_ID` (+0x4bc) ≠ none → play.
7. `+0xcb = 1` (deleted), `+0xd9 = killer` (0xff from timer/rule `Destroy`, `FUN_10033850` passes
   `0xffffffff`), `+0xda = 1` (destroyed, as opposed to silently deleted).
8. `includeInGroundAccuracyCount` (+0x134) → `FUN_10006200()` (game +0x40 ++; scoring handoff).
9. `destructReleaseRandomBonus` (+0x4b4) → **random bonus** (`li r3,0; li r4,0x64; bl
   0x10046580` = RandomRange(0,100) then the flli 209–219 ladder). Handoff to the scoring reader.
No score is awarded here. The score comes from `FUN_10014f10` step 9a (damage kills only;
timer/rule `Destroy` gives none). Coins are not released here either (§4.3).

### 4.2 `FUN_10016880(e) → bool` "may the destruct/deletion spawn appear here?" [HIGH — listing]
- returns **1** at once if the unit is not `isGroundBased` (+0x125) or has
  `doDeathSpawnOnAnyMedia` (+0x12b) (`100168a4 beq 0x10016bac` → `li r31,1`).
- else it tests the map point `(trunc(x) + 32, trunc(y) + FUN_1000fec0())` with `FUN_1000fee0`
  (media mask, sprite-sound-containers.md §3.1; +32 = left border; `FUN_1000fec0` returns the
  scroll offset [MED]): result 0 (land) → return 1. Result 1 (water) → spawn a water impact
  and return **0** (the normal spawn is suppressed). Any other result → 0.
- impact unit by `mediaImpactSize_ID` (+0x2e4), idli objects 6–9 = `MediaImpact_Water_Tiny/
  Small/Medium/Large`: `tiny`→6, `smal`→7, `med `→8, `larg`→9, `smra`→RandomRange(0,1): 0→7, 1→6;
  `mera`→RandomRange(0,2): 0→6, 1→7, 2→8; `lara`→RandomRange(0,1): 0→9, 1→8; `none`/0 → no impact
  (but still returns 0). RNG consumers: `smra`, `mera`, `lara` (`bl 0x10046580` at `10016a24`,
  `10016a64`, `10016ac8`).
Callers: `FUN_10016300` (destructSpawn) and `FUN_10036610` (deletionSpawn).

### 4.3 Deletion sweep `FUN_10036610` + `FUN_10036120(group, e, destroyed, byPlayer)` [MED — decompile; FUN_10036120 listing partly checked]
`FUN_10036610` runs once per tick **after** the whole entity loop (`100345d4 bl 0x10036610`)
[HIGH]. For each entity with +0xcb set:
- `includeInGroundAccuracyCount` → live ground-target counter `_DAT_100e0218 −= 1` (incremented
  at spawn in `FUN_10035cd0`).
- `destructDrawToTerrain` (+0x4b2) → the sprite is stamped into the terrain (`FUN_10012f20`).
- destroyed (+0xda) and the state has `destroyOwnerOnDestruction` (+0x32d) and the owner is
  alive → `FUN_10016300(owner, e.killer, FUN_10005ce0())` (the chain passes the killer on).
- **not** destroyed (silent delete) and `deletionSpawn_ID` (+0x2dc) ≠ none and
  `FUN_10016880` → spawn it.
- `FUN_10036120(group, e, destroyed = +0xda, byPlayer = (+0xd9 ≠ 0xff))`, then unlink/free;
  the group is freed when empty unless its type is `'PERM'`.

`FUN_10036120` (listing `10036120–100361e8`): if `e+0x13e` (has children — LOW meaning) →
`destructDestroyChildren` (+0x4b0, only if destroyed) → `FUN_100363c0`; `destructDeleteChildren`
(+0x4b1) → `FUN_100364f0`. If destroyed: `group+0xac += 1`, and a group kill is
`group+0xac == group+0xa4`. If **byPlayer && destroyed && e+0xca == 0** (not a collected
pickup): spawn `destructNumCoinsToRelease` (+0x4a4) × `destructCoin_ID` (+0x4a8). If also a
group kill and the group is not `'PERM'`: one `destructCoinOnGroupKill_ID` (+0x4ac). So the
group coin needs the **last** member to be killed by a player, while earlier members count
even if they died to timers. It then calls `FUN_10016300` again, which is a no-op because +0xcb
is already set.

## 5. Player shields, hit, death

### 5.1 Representation [HIGH]
- **Shields** live at `player+0xa8` as `float(percent + 1324366.0)`. Get `FUN_10027540`:
  `lfs f1,0xa8(r3); lfs f0,0x8(r4); fsubs f1,f1,f0`. Set `FUN_10027560`: `fadds f0,f0,f1;
  stfs f0,0xa8(r3)` (r4 = `lwz -0x702c(r2)` → `0x100d6fc8`, +8 = 1324366.0). Floats between 2²⁰
  and 2²¹ have an ulp of 0.125, so **every stored shield value is rounded to a multiple of
  1/8 %**.
- Lives at `player+0x98 = lives + 0x1524dcef` (`FUN_1002a150`, `FUN_10026d70`) [MED].
- Player state byte `+0xc6`: 4 = active (the only state that can be hit), 3 = dying (set by
  death), 1 = out (after the last life; `FUN_1002a150`). `FUN_10026c60(p,s)` = `(+0xc6 == s)`,
  `FUN_10026c50` = `+0xc6` [HIGH accessors; MED state names].
- `FUN_10026c90` = `player+0xcc` = **player index** (0/1). It is used as the scoring index
  (r5 of `FUN_10014f10`), as the owner byte of player spawns, and by `FUN_10006190` to index the
  player table. ⚑ corrected — not "player takes hit". [HIGH]
- `FUN_10026c10` = `player+0xc4`, the "player is in the game" flag. It is set at game start,
  cleared after `gameOverTime` in state 1, and gates the lives decrement, extra lives
  (`FUN_10026d70`), shield pickups (`FUN_10027490`) and death-time invulnerability [MED].
- `FUN_10027dd0` = `player+0xce`, the **invulnerable** flag. It is set on death if +0xc4
  (`FUN_10027e50`) and cleared in state 4 only once `entry_InvulnerabilityTime` (plde +0x8c) has
  passed since the state started (+0xc8, `FUN_1002a150` tail; state switch `1002a18c cmpwi
  r0,0x3` … `1002a1a8 cmpwi r0,0x5; bge exit` → state 4 falls to `1002a1e8 lbz r0,0xce(r29)`,
  clear at `1002a214`). ⚑ corrected (review wave 1, 2026-10-03) #M1: was "cleared in states 4/5". The cheat/debug latch `+0xcf`
  comes from `FUN_10027de0` [MED].
- plde offsets used here (literal reader-call offsets in `FUN_10039e70`; key_offsets.py missed
  this reader form): `defaultShieldPercentage +0x48`, `shieldWarningPercentage +0x4c`,
  `shieldBaseHitPercentage +0x50`, `shieldHitDelay +0x54`, `hitGlowColor +0x58`, `hitGlowSpeed
  +0x5c`, `life_MaxNum +0x60`, `life_NumInitial +0x64`, `life_Spawn_ID +0x70`, `dyingTime +0x84`,
  `finalDyingTime +0x88`, `entry_InvulnerabilityTime +0x8c`, `death_Spawn_ID +0xbc`,
  `active_SpawnOnHit_ID +0xc8`, `active_ShieldWarningObject_ID +0xcc`,
  `active_DefenceBonusObject_ID +0xd0`. [HIGH for the eight read in the FUN_10027100 listing
  (+0x4c…+0x5c, +0xc8, +0xcc); MED for the rest — decompile only]

### 5.2 `FUN_10027100(player r3, — r4, now r5; damage f1) @ 10027100` [HIGH — listing `10027100–100273f0`]
⚑ corrected: this is the player's hit handler. The bank calls it "player hit spawn delay".
Its only caller is `FUN_10033850` §2.3, with f1 = the entity's `damage_FLOAT`.
1. `lbz r0,0xc6(r3); cmplwi r0,4; bne exit` — only active players.
2. `lwz r0,0x54(r4) (shieldHitDelay); add r0,r5(+0x204),r0; cmpw r29,r0; blt exit`: accept iff
   `now ≥ lastHit(+0x204) + shieldHitDelay` (**≥**; the entity rule is >). Then `+0x204 = now`.
3. if **not** invulnerable (`bl 0x10027dd0; bne skip`): `loss = damage × (float)shieldBaseHitPercentage`
   (`lwz r0,0x50(r4) … fmuls f31,f30,f0`), `shields = get − loss` (`fsubs f1,f1,f31`). If
   `loss > 0.0` → `+0xd0 = 1` ("was hit" — a defence-bonus input, scoring handoff).
   Then `set(shields)`.
4. `get < 0.0` (`fcmpo f1,0.0; bge alive`) → **death** `FUN_10027e50(player, now)`; return.
   Exactly 0 % survives.
5. alive: glow `FUN_10012bc0(player, hitGlowColor +0x58, hitGlowSpeed +0x5c, 0)` (even when
   invulnerable).
6. if `damage > 0.0`:
   - `active_SpawnOnHit_ID` (+0xc8) ≠ none and `now ≥ +0x208 + trunc(flli 162
     Player_DelayBetweenHitSpawns = 10)` → `+0x208 = now`; spawn it at the player, owner byte = index.
   - if `+0xd1 == 0` and `shields ≤ (float)shieldWarningPercentage (+0x4c)` (`cror eq,lt,eq`):
     spawn `active_ShieldWarningObject_ID` (+0xcc) if ≠ none, then `+0xd1 = 1`. The warning fires
     once per life; `+0xd1` is reset on respawn (`FUN_1002a150`) and on death (`FUN_10027e50`).

### 5.3 Death `FUN_10027e50(player, now)` [MED — decompile]
`FUN_10034b90(index)`: every entity owned by this player (+0xd8 == index) whose state has
`canBeDestroyedOnOwnerDestruction` (+0x329) is destroyed (`FUN_10036120(…,1,0)`, no coins). With
`canBeDeletedOnOwnerDeletion` (+0x32a) it is deleted instead. Then: spawn `death_Spawn_ID`
(+0xbc). If `+0xc4 == 0` the shields are zeroed. Clear `+0x204/+0x208/+0xd1`. **Carried coins
are dropped as coin units** (`coins = +0xac − 0xb2cce`; greedy 50/10/5/1 → idli objects 2/3/4/5
per unit), then `coins = 0`. `+0xc6 = 3` (dying), `+0xc8 = now`. If `+0xc4`: `+0xce = 1`
(invulnerable through respawn). If the score multiplier byte `+0xb4 ≠ 1`: remove the multiplier
entity (`FUN_10034de0(+0xb8)`) and reset it to 1.
The **powerup overload** also kills: `FUN_10026ee0` calls `FUN_10027e50` once the warning count
reaches `powerupOverload_NumWarnings` (weapon reader).
Lives / respawn hook (player reader): in state 3, `FUN_1002a150` waits `finalDyingTime`
(+0x88) when `lives == 1`, else `dyingTime` (+0x84). Then it sets `lives = max(lives − 1, 0)`
(only if its `param_3` and `+0xc4`). If lives < 1: state 1. Else: respawn `FUN_10029cc0` and set
shields to `defaultShieldPercentage` (if +0xc4, else 0) [MED].

## 6. Pickups — `FUN_10037580(player, e) → bool` [HIGH — listing `10037580–100376f0`]
Dispatch on `pickup_Type_ID` (+0x4d4). The return value says whether the pickup is consumed:
| type | action | returns |
|---|---|---|
| `air ` / `grnd` | weapon pickup is refused while the player is invulnerable (`bl 0x10027dd0; beq` → keep 1, else 0); the weapon swap itself happens elsewhere (LOW) | 0 if invulnerable |
| `coin` | if `pickup_Value_INT` (+0x4dc) ≠ 0: `FUN_100275b0` (add coins) + glow 0x7fff/6 | 1 |
| `exli` | `FUN_10026d70(player, 1)` extra life (capped at `life_MaxNum`; `life_Spawn_ID`) | 1 |
| `mult` | `FUN_10029b20` (multiplier) | 1 |
| `shie` | `FUN_10027490(player, f1 = (float)pickup_Value_INT)` → `shields += value` if +0xc4 and value ≠ 0 (cap not read) | 1 |
| `spec` / other | nothing | 1 |

## Worked example
**A. Flipper Mk 2 (`fl02`, air) hit by the default air weapon.** The Ion Cannon (`aiic`,
`DEAA`) fires `icb ` ×2 (x −5 and +4) plus a flash `icbf` every 4 ticks
(`delayBetweenLaunches 4`). Unit values (`grep` of the decoded files in `$W/data/Game/unde`):
| unit | layer | harmless | playerProj | canBeHit | shields | damage | score |
|---|---|---|---|---|---|---|---|
| `icb ` Ion Cannon Bullet | air | TRUE | TRUE | FALSE | 0.4 | 0.4 | 0 |
| `fl02` Flipper Mk 2 | air | FALSE | FALSE | TRUE | 0.8 (+0, max 1.0) | 1.0 | 80 |
- Collision: only the bullet's update finds the Flipper (§2.5). Same layer, harmless differ, A
  is a playerProjectile and B canBeHit. The radii are half of each sprite's bounding-box height.
- Bullet 1 hits at tick t. The bullet takes 1.0 → 0.4 − 1.0 < 0 → destroyed (spawns `icbh`). The
  Flipper takes 0.4 → 0.8f − 0.4f = **0.4** (float32 exact), and `+0xb4 = t`.
- Bullet 2 of the same volley touches in tick t or t+1: the Flipper refuses (`now > t + 1` is
  false) and bullet 2 dies anyway.
- The next volley arrives at about t+4 > t+1: 0.4 − 0.4 = 0 → ≤ 0 → `FUN_10006190(player, 80)`
  (× the multiplier), then `FUN_10016300`. `destructCoin_ID none`, so no single coin. If this
  was the group's last member and a player killed it → one `cass` coin.
- **Shots to kill: 2 effective hits in every sector** (air units have no increment). In practice
  that is two volleys, because the second bullet of a volley is wasted by the hit delay.
- Ramming instead: the Flipper takes 100 → dies and scores 80. The player takes
  `1.0 × 15 = 15 %` (100 → 85).

**B. Sector scaling — `tala` Tank - Laser (ground) under the default ground weapon** (Plasma
Bomb `plbo`, `DEAG`: ground layer, damage 0.4, collides only in its 1-tick `Dwindle & Delete`
state). Tank shields `min(3.5 + 0.4·(sector−1), 5.0)` (§3), computed in float32 (Python/numpy
emulating `fmuls/fadds/fsubs`):
| sector | 1 | 2 | 3 | 4 | ≥ 5 |
|---|---|---|---|---|---|
| shields | 3.5 | 3.9000001 | 4.3000002 | 4.6999998 | 5.0 (capped) |
| bombs to kill (0.4 each, last one brings s ≤ 0) | 9 | 10 | 11 | 12 | 13 |
Kill → 300 points, one `cass` coin (`destructNumCoinsToRelease 1`), wreck obstacle
(`destructCreateObstacle TRUE`), `destructSpawn tdes` unless over water (§4.2). Caveat: the tank
spawns a turret child ("Spawn Turret & Cap Children"). If the turret is hittable and passes hits
to its owner, a bomb that overlaps both still lands once per 2 ticks on the tank (hit delay is
per victim) [MED — turret def not traced].

**C. Player shield arithmetic** (`shieldBaseHitPercentage 15`, start 100 %, death at < 0,
1/8 % grid): damage 1.0 → 85, 70, 55, 40, 25, 10, −5 → **dies on hit 7**; damage 2.0 → dies on
hit 4; damage 0.4 (6 %) → dies on hit 17 (after 16 hits: 4 %). Hits are at least
`shieldHitDelay = 1` tick apart.

## NOT RESOLVED (this file)
1. `FUN_10019ca0` (`U_Sprite_GetDimensions`) scale argument and the frame sizes. Collision
   radii in pixels per unit need them (sprite plate frame rects ×, possibly, `+0x84` scale).
2. Value of `entity+0xd8` (owner index) for enemy-spawned entities. It is copied from spawn
   request +0x14 (`FUN_10035cd0`). Is it always outside 0..1, so that enemy-shot kills never
   score? Read `FUN_10033220` callers' request templates (`0x100e64bc…`, `0x100eb420…`).
3. `entity+0x13e` ("has children") writer `FUN_100142f0` l. 11933 — not read.
4. The weapon-pickup (`air `/`grnd`) swap and the shield-pickup cap (`FUN_10027490` listing) —
   player/weapon reader.
5. ~~The ground-accuracy crosshair rectangle in step 9 (`FUN_1003bab0`): decompile reads
   `left ≤ cx < right && top ≤ cy < bottom` (strict upper bound), for ground, non-harmless,
   canBeHit, `IsTargetable` units only — listing not checked; scoring reader.~~ → ⚑ corrected (wave 3+4, 2026-10-04) (critic O7):
   listing-confirmed half-open `l ≤ cx < r`, `t ≤ cy < b`; the test is in `FUN_10033850` `100343ac..100344e8`
   (gameplay-leftovers.md §7.4b).
6. ~~`FUN_1000fec0` = scroll offset used by the water test (MED). Also the return codes of
   `FUN_1000fee0` other than 0/1.~~ → ⚑ corrected (wave 3+4, 2026-10-04) (critic O7): `FUN_1000fee0` returns only 0/1;
   `FUN_1000fec0` = window top `0x100e5acc` (HIGH) (gameplay-leftovers.md §7.4a).
7. `FUN_100431f0`'s two `RandomRange(0,99)` at app init: are they before `srand`, and do they
   matter for film replay? (engine reader). ⚑ corrected (wave 2, 2026-10-03): closed — 302 draws, all before
   `srand`, no replay effect (particles-debris-blur.md §1).
8. The motion-blur trail (`FUN_10033850` step 9, state +0x2ec) draws `RandomRange(min +0x2f0,
   max +0x2f4)` per entity per tick while enabled. It is an RNG consumer that the engine-loop.md
   §9 table should list (dump l. 31047; listing not walked). ⚑ corrected (wave 2, 2026-10-03): closed — the draw is
   real but every shipped blur state has 0/0, so it never draws (particles-debris-blur.md §1, §4.4).
9. `FUN_10042cd0` full branch listing; `FUN_10017150` heading sign (see §1). ⚑ corrected (wave 2, 2026-10-03): closed
   — full listing walk and convention in loose-ends-combat.md §1.2–§1.3.
10. Behaviour gates for Ben's eyes: the second-bullet waste (§3), the `passHitsToOwner` B-side
    bug (§2.5 — now traced: player shots land on the turret's own shields; only its visible
    effect is left for Ben), and ramming scoring (§2.3). ⚑ corrected (review wave 1, 2026-10-03) #I1

## Role-table rows (for merge)
| `FUN_10042f80` | U_Math (LOW name) | circle overlap: trunc(dx²+dy²) → sqrt table/libm; dist < rA+rB (strict) | HIGH | listing 10042f9c–10043018; callers FUN_10033850, FUN_10036cf0 |
| `FUN_10042920` | U_Math | build atan int[1024], sqrt float[16384], cos/sin float[360] tables | HIGH | listing; caller FUN_100000e0 |
| `FUN_10042a90` | U_Math | free math tables | MED | decompile |
| `FUN_10042f20` | U_Math | sqrtI(n): table if n<16384 else libm | HIGH | listing |
| `FUN_10042e90` | U_Math | point distance sqrtI(trunc(d²)) | HIGH | listing; callers FUN_10034ee0, FUN_10035070, FUN_10033600 |
| `FUN_10042c90` | U_Math | vector length (libm) | HIGH | listing |
| `FUN_10042f00` | U_Math | sin(h) table | HIGH | listing r2−0x6e34 |
| `FUN_10042ee0` | U_Math | cos(h) table | HIGH | listing r2−0x6e30 |
| `FUN_10042b30` | U_Math | heading → (sin h, cos h) | HIGH | listing |
| `FUN_10042b80` | U_Math | speed·(sin h, cos h) | HIGH | listing |
| `FUN_10042bf0` | U_Math | normalise (x², with trunc(x)·x quirk) | HIGH | listing 10042c1c–10042c44 |
| `FUN_10043090` | U_Math | table-atan heading (a−90 mod 360) | HIGH | listing |
| `FUN_10042ad0` | U_Math | heading from two int points | HIGH | listing |
| `FUN_10043040` | U_Math | mirror heading 180−h mod 360 | HIGH | listing |
| `FUN_10042cd0` | U_Math | heading of float vector (libm atan, axis table) | MED | decompile |
| `FUN_100426e0` | ? | write data file in Data folder (units cache helper) | MED | strings; caller FUN_10041e40 |
| `FUN_100428b0` | ? | static initialiser copying constant records | LOW | decompile |
| `FUN_100431f0` | ? | init: two RandomRange(0,99) + FUN_1002d080 | LOW | decompile; caller FUN_100000e0 |
| `FUN_10043280` | ? | teardown for FUN_100431f0 | LOW | decompile |
| `FUN_10014f10` | | damage entity: hit delay flli167 (>), shields +0x134 −= dmg, invuln restore, on-hit state, ≤0 → score+destroy/depletion state, glow/particles/sound/collision spawn | HIGH | listing 10014f10–1001527c |
| `FUN_10016300` | | destroy entity: obstacle, particles, destructSpawn (media-gated), notice, sound, flags cb/d9/da, ground-kill count, random bonus | HIGH | listing |
| `FUN_10016880` | | media gate for death/deletion spawns + water impact by mediaImpactSize | HIGH | listing |
| ⚑ corrected `FUN_10027100` | G_Player | player takes hit: shieldHitDelay (≥), loss=dmg×shieldBaseHitPercentage, death <0, glow, SpawnOnHit (flli162), shield warning | HIGH | listing; was "player hit spawn delay" MED |
| ⚑ corrected `FUN_10026c90` | G_Player | player index (+0xcc) | HIGH | 1-line accessor; uses; was "player takes hit" LOW — ⚑ label audit (review wave 1): HIGH kept — listing evidence in player-physics.md role rows |
| ⚑ corrected `FUN_10026c10` | G_Player | player in-game flag (+0xc4) | MED | accessor + writers; was "player is alive" LOW |
| `FUN_10026c60` | G_Player | player state == s (+0xc6) | MED | accessor — ⚑ label audit (review wave 1) |
| `FUN_10026c50` | G_Player | player state (+0xc6) | MED | accessor — ⚑ label audit (review wave 1) |
| `FUN_10027540` | G_Player | get shields (+0xa8 − 1324366.0) | HIGH | listing |
| `FUN_10027560` | G_Player | set shields (+0xa8 = v + 1324366.0) | HIGH | listing |
| `FUN_10027dd0` | G_Player | player invulnerable flag (+0xce) | HIGH | accessor — ⚑ label audit (review wave 1): HIGH kept — listing evidence in player-physics.md role rows |
| `FUN_10027e50` | G_Player | player death: owned entities, death spawn, coin drop, state 3, multiplier reset | MED | decompile (was "coin unit selection") |
| ⚑ corrected `FUN_10036cf0` | G_EntityGroup | entity↔entity collision + mutual damage_FLOAT (layer, harmless XOR, playerProjectile/canBeHit, AABB, circle) | HIGH | listing; was "state spawn sets executor" LOW |
| `FUN_10037580` | G_EntityGroup | pickup dispatcher by pickup_Type_ID | HIGH | listing |
| `FUN_10017e70` | | switch to first UseThisStateOnShieldDepletion state | HIGH | listing |
| `FUN_10036610` | G_EntityGroup | end-of-tick deletion sweep (ground count, terrain stamp, owner destroy, deletionSpawn) | MED | decompile; call at 100345d4 |
| `FUN_10036120` | G_EntityGroup | remove entity: children, group-kill count, coins, group coin | MED | decompile + partial listing |
| `FUN_10034b90` | G_EntityGroup | destroy/delete entities owned by a player | MED | decompile |
| `FUN_10036ab0` | G_EntityGroup | owner link valid (ptr, serial, not deleted) | MED | decompile 1-liner — ⚑ label audit (review wave 1) |
| `FUN_10012ad0` | | entity bounds l,t,r,b (trunc) | HIGH | listing |
| `FUN_10012a00` | | entity bounds Mac rect {t,l,b,r} | HIGH | listing |
| `FUN_10012940` | | half-size from sprite frame dims /2 | MED | decompile |
| `FUN_10012bc0` | | start hit glow (colour, speed, 32) unless active | HIGH | listing |
| `FUN_1002a830` | G_Debris | rect vs debris list (inclusive) | MED | decompile |
| `FUN_1002a6d0` | G_Debris | add debris rect | MED | decompile + assert string — ⚑ label audit (review wave 1) |

## INDEX updates (for merge)
- **#24 closed** → this file §2.1 (`FUN_10042f80` = circle test, not pixel/shape), §3
  (`FUN_10014f10`), §5.2 (`FUN_10026c90` is an accessor; the player hit is `FUN_10027100`).
- **#20 ⚑ conflict / narrowed:** `FUN_10036cf0` is entity↔entity collision (§2.5), not the
  spawn-set executor. The executor is `FUN_10015b40`; `FUN_10017150` is its rotation gate (HIGH,
  §2.5) ⚑ corrected (review wave 1, 2026-10-03) (conflict): was "The runtime spawn-set reader is `FUN_10017150` (LOW)". waves-and-enemies.md
  §3 step 8 ("pixel/shape test") and step 9/§4/§8 #2 need the same correction.
- **#7 narrowed:** the plde key→offset subset in §5.1 (literal offsets in `FUN_10039e70`).
- **#26 touched only:** the random bonus is invoked from `FUN_10016300` step 9; the coin
  release and group-kill coin conditions are in §4.3; `+0xd0` "was hit" is a defence-bonus input.
- waves-and-enemies.md §4 "MED for which component of `FUN_10042b30`'s vector is x" → HIGH:
  x = sin h, y = cos h (§1).
- New items: NOT RESOLVED 2, 7, 8 above (owner index of enemy spawns; init-time and
  motion-blur RNG consumers).
