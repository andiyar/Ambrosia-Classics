# Ferazel's Wand 1.0.3 — physics: integration, tile collision, player movement, damage, enemies

Register: code readings only; **nothing behaviour-verified**. Labels per claim (INDEX §Labels).
Units: px; velocities and accelerations in **1/256 px per frame**, one frame = one `.GameLoop`
iteration (≤ 30.08 Hz, engine.md §4). Sprite record offsets are `s+0x..` (0x1fc-byte sprite).
Player-handler code lives in the supplementary dump (`.HandlePlayerSprite @ 1004d5fc`,
`.HitPlayerSprite @ 100556f4`, `.HitPlayerTileSprite @ 10054ca8`), the rest in the main dump.

## 0. Sprite fields used by physics  [HIGH unless noted]

| off | type | meaning (writer/reader) |
|---|---|---|
| +0x04 | i16 | type — **except player shots**: `.SetupPlayerShotSprite` rewrites it to the spell id (`(char)(type>>8)`) and moves the power to +0x170 for the shot's whole life (§7; spells-items.md §2) ⚑ corrected (review 2026-10-03) #3 |
| +0x06/+0x08 | i16 | y/x copy (old position; set with +0xa/+0xc each integration step) |
| +0x0a/+0x0c | i16 | y/x integer position (top-left of the face cell) |
| +0x0e/+0x10 | i16 | centre y/x of the hot rect (`.CalcCenterPos`) |
| +0x14/+0x1c | i32 | x/y in 24.8 fixed point |
| +0x24/+0x2c | i32 | vx/vy (1/256 px/frame) |
| +0x34..+0x3a | Rect | hot rect relative to the face cell (top,left,bottom,right) |
| +0x46 | i16 | per-class scratch (rope rider offset, spring cooldown, platform/crumble counters — §8) ⚑ corrected (review 2026-10-03) #2 |
| +0x48 | i16 | placement-record index (written `*(short *)(s+0x48) = recIndex` at the end of `.GenerateSprite`; −1 = no record, the sentinel `.SetupProgrammedPath`/`.DoSetupPlatformSprite` test; read by the `.UpdateSprites` write-back and by the `.HitPlayerSprite` sign/trigger param reads — world-data §3.4 "records are live" depends on it) ⚑ corrected (review 2026-10-03) #7 |
| +0x4c | proc | per-frame handler (Setup replaces itself with Handle) |
| +0x5c | proc | sprite-sprite hit callback; +0x1f8 tile-hit callback |
| +0x68 | ptr | next in active list |
| +0x80 | i32 | layer (MTNewSprite arg) [MED] |
| +0xa4 | i16 | hit points (`.HurtSprite`) |
| +0xaa | i16 | hurt-flash frames; +0x116 invulnerability frames |
| +0xce | u8 | ground/surface kind under the sprite this frame (0 = airborne) |
| +0xcf | u8 | ceiling kind hit this frame |
| +0xd8 | i16 | surface material = FG kind / 100 of the tile stood on (1..), 0 = plain (`.WallBounce`) |
| +0xdc | ptr | platform sprite being ridden |
| +0xe9 | u8 | kill request (handled by `.UpdateSprites`) |
| +0x110 | i16 | gravity per frame |
| +0x112 | i16 | slipperiness value (ice) |
| +0x11c/+0x120 | i32 | water contact: `surfaceY − y − face top inset`, clamped ≥ 1 while in water (so 1 = fully submerged, larger = visible top that far above the surface), 0 = not in water / previous frame's (fix-pass reading of `.HandleUnderWater`, §5.1) [MED] |
| +0x128 | i16 | water kind (BG kind − 200) |
| +0x138 / +0x13a / +0x13c | i16 | push mass (a sideways push by a mover adds `mover+0x13c · (+0x138 · Δvx >> 8) >> 8` to this vx) / landing sag (`vy += landing vy · +0x13a >> 8` when landed on at vy > 0x200) / pusher factor — `.RectBounce`, `.PlatformBounce` (§8.1) [HIGH arithmetic, MED names] ⚑ corrected (review 2026-10-03) #2 |
| +0x170 | i32 | player shot: **power** (`type & 0xff`; `.SetupPlayerShotSprite`, handler dump l. 4929) ⚑ corrected (review 2026-10-03) #3 |
| +0x17e | u8 | facing left |
| +0x185 | u8 | one-way top: `.RectBounce` skips side/underside resolution and lands a mover only if its previous-frame bottom was above the top (+8 px slack, +0x20 on sloped tops) (§8.1) ⚑ corrected (review 2026-10-03) #2 |
| +0x186 | u8 | "ridden this frame" (set by `.PlatformBounce`/`.RopeCollide`, cleared by the owner's handler) ⚑ corrected (review 2026-10-03) #2 |
| +0x194 | i32 | jump bonus lent to a rider: `.HandleKeys` copies the ridden sprite's +0x194 into the jump base J of §4 (`*piVar12 = *(int *)(platform + 0x194)`, main dump l. 44901/44937) ⚑ corrected (review 2026-10-03) #2 |
| +0x19e / +0x1a0 | i16 | buoyancy strength (0 = sinks) / float-line offset (`.HandleFlotation`, §8.6) ⚑ corrected (review 2026-10-03) #7 |
| +0x1e8 | proc | surface-height function of a ridable non-flat top, called through ptr-glue `FUN_1009f80c` with (sprite, x offset); ropes get TOC slot `_DAT_100a0ce4` (→ `.GetRopeHeight` [MED: TVector→name link not decoded]) (§8.2) ⚑ corrected (review 2026-10-03) #2 |

## 1. `.LoadLevelPhysics @ 1000332c` — loaded, never read  [HIGH]

```c
if (*(short*)(hdr+0x2860) != 0) { G40[0..4] = hdr[0x2862,0x2864,0x2866,0x2868,0x286a]; return; }
G40[0]=0x32; G40[1]=0x46; G40[2]=0xf5; G40[3]=0xfc; G40[4]=0x96;   // 50,70,245,252,150
```
`G40` = the 10-byte global at 0x10225730 (TOC slot `_DAT_1009ff40`). A scan of every
`lwz rD,-0x7900(r2)` in the code section (the only way PPC code loads that TOC slot) finds one
hit, inside `.LoadLevelPhysics` itself (`tools/tocrefs.py 1009ff40` → `0x10003330`), and no other
TOC slot points into 0x10225730..0x10225739 (scan of the TOC words, this session). hdr+0x2860
is 0 in all 24 levels. **The per-level physics table is vestigial in 1.0.3**: the five values
are written and never read [HIGH; residual risk: an address formed by arithmetic from an
unrelated base — none seen]. Every constant below is hard-coded in the handlers.

## 2. Generic integration helpers  [HIGH]

- `.ApplyGravityAndSeparateFromTiles @ 100375b0` (most non-player sprites): `g = s+0x110`; in
  water (`s+0x11c ≠ 0`) `g = (int)(g · 0.7)` but at least 0x100 (double at 0x100a1938 = 0.7);
  `s+0xce = 0`; separate; `vy += g`; `x += vx`; then `y += vy` in sub-steps of at most 0xc00
  (12 px), calling `.SeparateFromTiles2` after each step; then refresh integer and centre
  positions.
- `.ApplySpeedAndSeparateFromTiles @ 1004b83c` (player): `x += vx`; `y += vy` in sub-steps of
  0x400 (4 px) while `vy > 0x400`, stopping early when a collision changed vy; separate after
  each.
- `.ApplyFriction(s, f)`: move vx toward 0 by `f`, no overshoot.
- `.AccelerateSprite(s, ax, ay, maxX, maxY)`: in water (`+0x11c` or `+0x120`) all four args ×0.8
  (double 0x100a1928 = 0.8); `vx += ax; vy += ay`; clamp |vx| ≤ maxX and |vy| ≤ maxY when non-zero.
- `.SetSpriteSpeed(s, vx, vy)`: ×0.8 in water.
- `.EnforceMaxSpeed(s, m)`: scales the vector so the larger axis is ≤ m.
- `.AccelerateBasedOnSlope @ 10037350 (s, a, max)`: in water a,max ×0.8; if standing on a
  slope kind (`s+0xce`) and pushing uphill, the accel **and** the cap are multiplied:
  kind 0xc (a<0) or 0xf (a>0) → ×0.707; 0x20..0x21 (a<0) or 0x22..0x23 (a>0) → ×0.923;
  0x2c..0x2d (a<0) or 0x2e..0x2f (a>0) → ×0.382 (floats 0x100a1920/191c/1918, read with
  `tools/const.py`); `vx += a`; clamp |vx| ≤ cap. (So the slope families are 45°, ~22.5° and
  ~67.5° — cos values; the 0x24..0x2b family has no uphill penalty.)
- `.HurtSprite @ 10037034 (s, dmg, kvx, kvy, invul, flash)`: only if `dmg>0`, `hp>0`,
  invulnerability `s+0x116 == 0`: `hp −= dmg; vx += kvx; vy += kvy; s+0x116 = invul;
  s+0xaa = flash`; returns 1.
- `.StandardSpriteHandles @ 10036854` (start of most handlers): count down +0x116/+0xaa; reset
  per-frame contact fields; **water current**: if `s+0x118 < 0x1d` and in water and kind 0 and
  `s+0x8a`: ramp a counter +0x94 up to 33 and push `x += hdr[0x2714]·n/33` (full push after 33
  frames, decays when out); **wind** (§6); carry with a ridden platform `s+0xdc` (x by the
  platform's dx, y snapped on top +1 px).

## 3. Tile collision

### 3.1 Neighbourhood and dispatch (`.SeparateFromTiles2 @ 1003c804`)  [HIGH]
Only sprites with a tile callback (`s+0x1f8`) collide. The 3×3 cells around the hot-rect centre
(`cx>>5, cy>>5` ±1) are tested in the order centre, then (−1,−1)…; for each cell:
- FG tile `t`, kind `k = FGkind(t)`; if `k ≠ −1` and the sprite's hot rect intersects the
  tile's **FG hot rect** (table §3.2, indexed by tile `t`), call
  `tileHit(s, (cellY·32, cellX·32), k, 1)`. Before that, if `s+0xeb` (can-crunch) is set,
  every crunch-direction nibble > 0 in the 2×2 block up-left of the cell whose 32×32 box at
  (+16,+16) intersects the sprite → `tileHit(s, pos, dir, 2)`.
- BG tile kind `kb = BGkind(t)`; if `kb ≠ 0` and the sprite intersects the full 32×32 cell →
  `tileHit(s, pos, kb, 0)`.
(The second 9-cell loop gated by `s+0xe4` computes rects and discards them — dead code.)

### 3.2 FG hot rects (`.InitTileHotRects @ 10002824`)  [HIGH]
Per FG tile, from `kind mod 100` (`SetRect(l,t,r,b)` arguments, tile-local px):

| kind mod 100 | rect (l,t,r,b) | shape |
|---|---|---|
| 0 | 0,0,16,32 | left half |
| 1 | 0,0,32,16 | top half |
| 2 | 16,0,32,32 | right half |
| 3 | 0,16,32,48 | floor: from half height down into the next row |
| 4 | 0,16,16,32 | bottom-left quarter |
| 5 | 0,0,16,16 | top-left quarter |
| 6 | 16,0,32,16 | top-right quarter |
| 7 | 16,16,32,48 | bottom-right quarter, extended down |
| 0x2d | 0,0,16,48 | left half extended |
| 0x2f | 16,0,32,48 | right half extended |
| other (incl. <0, 8..0x2c, 0x2e, ≥0x30) | 0,0,32,48 | full, extended 16 px down |

A second 64-entry table at +0xc (`DAT_100a4794`, by kind 0..63) and a 96-entry table at
`DAT_100a4314` (inset 6 px for 3..5, else 2 px) are built but their readers were not traced
[NOT RESOLVED].

### 3.3 Kind semantics (`.HitPlayerTileSprite` → `.WallBounce @ 10037a54`)  [MED overall]
- FG kinds are reduced `mod 100`; the hundreds digit (1, 2, …) becomes the **surface
  material** `s+0xd8` when the sprite is resolved against the tile [HIGH]. Material 2 = damaging surface:
  every frame the player stands on it while not invulnerable (and not dying) costs
  `hdr+0x270e` HP (default 0x70), sets 60 invulnerability frames, 18 flash frames and the
  hurt-stun counter `_DAT_100a0748` (also set by `.HurtPlayer`); material 3 = ice: ground deceleration `(256 − hdr+0x2710)·800 >> 8` and `s+0x112 =
  hdr+0x2710 >> 4` (used to slide down 0x20.. slopes) [HIGH, `.HandlePlayerSprite`].
- `.WallBounce(s, kind, tilePos, …, bounce)` resolves the hot rect against the shape:
  kind 0: push right of x+16; 1: push below y+16, sets ceiling `+0xcf`; 2: push left of x+16;
  3: put the hot-rect bottom on y+16 and set ground `+0xce = 3` when falling; 4–7: quarter
  blocks choosing the shallower axis; 8–0xb: L-shaped two-rect blocks; 0x20/0x21 and
  0x22/0x23: two-tile 1:2 slopes (surface height interpolated `(sprite x − tile x)/2`,
  clamped 0..16 / 16..32), standing sets `vy = |vx|/2 + 0x100` and `+0xce`; further cases
  0xc..0x1f, 0x24..0x2f, 0x32..0x3b exist (63 cases total) [HIGH for the cases quoted; the
  rest NOT RESOLVED]. Kind 0x3c is treated as kind 3 shifted 8 px up. Kinds outside 0..0x3c
  are ignored.
- BG kinds (`param_4 == 0`): `< 100` → `.WallBounce` (solid like FG); `100..199` →
  `.WallBounceBG(kind−100)` (a separate solver; one-way/background ledges by name) [LOW for
  "one-way"]; `200..209` → water of kind `kind−200` (`.IsWaterTile`, `.GetWaterTileKind`) →
  `.HandleUnderWater`; `600, 601` ignored [HIGH for dispatch].
- Crunch tiles (`param_4 == 2`, `.CrunchTile`): the player breaks them when falling faster than
  0x9c4 (2500 → 9.8 px/frame) with the spin flag; bounce if not broken (`.RectBounceFake2`) and
  stay in spin while DOWN is held [HIGH].

### 3.4 Wall cling / climb  [HIGH]
In `.HitPlayerTileSprite`, kind (mod 100) and input decide a cling: moving left (vx<0) with LEFT
held (or already climbing) into kind 0, or into kind 4/0x14/0x2d when the sprite's bottom is
below the tile's mid line, or kind 5 within 4 px; mirror for right with kinds 2, 7/0x13/0x2f,
6. Cling requires not on ground, not in the 0x588 state, no glider; it sets the climb state
`_DAT_100a0758 = 1`, zeroes vx/vy, faces the wall; at a wall top with an empty cell above, a
"pull-up" (`_DAT_100a06a0 = 1`) starts, else the player is pushed down 1000/256 px.

## 4. Player movement constants (`.HandleKeys @ 10052ac0`, `.HandlePlayerSprite`)  [HIGH]

Action indices as engine.md §7.1 (0 L, 1 R, 2 U, 3 D, 4 run, 5 jump, 6 use).

| quantity | value (1/256 px/frame) | ≈ px/frame | where / condition |
|---|---|---|---|
| gravity, normal | 0x1b8 = 440 | 1.72 | `s+0x110` set every frame |
| gravity, swimming or deep water | 0x50 = 80 | 0.31 | `_DAT_100a0714 ≠ 0` or depth == 1 |
| gravity, spin jump | 0x118 = 280 | 1.09 | spin flag `PTR_DAT_100a0668` |
| gravity, feather-fall power-up | 0x40 = 64, vy clamped ≤ 0x352 = 850 | 3.3 max | `PTR_DAT_100a062c` |
| terminal fall speed | 12000 | 46.9 | clamp after gravity; vy 0 is bumped to 1 |
| walk accel (from rest / turning) | 0x14f = 335 | 1.31 | `.AccelerateBasedOnSlope`, ground |
| walk accel (already moving that way, or ice) | 0x104 = 260 | 1.02 | |
| walk max | 0x76c = 1900 | 7.42 | `_DAT_100a600a` |
| run accel turn / continue | 500 / 300 | 1.95 / 1.17 | RUN held |
| run max | 0xc80 = 3200 | 12.5 | `_DAT_100a600c` |
| double-speed power-up max walk / run | 0xd82 = 3458 / 0x15e0 = 5600 | 13.5 / 21.9 | `PTR_DAT_100a0620` |
| ground deceleration (no input) | 800; 300 while hurt-stunned (`_DAT_100a0748`); ice formula §3.3 | 3.1 | |
| air drag (no input) | 100; 600 in state `_DAT_100a0588` (= **on a rope**: the byte `.RopeCollide` sets to 1, §8.2 — fix-pass reading [HIGH for the write, MED that this is its only meaning]); 20 on the glider | 0.39 | |
| air control | ±0x14a = 330 per frame up to walk/run max | | not on ground, not swimming |
| air control in `_DAT_100a0588` state | ±1000 per frame, clamp ±0x960 = 2400 | | |
| swim horizontal | ±0xd2 = 210 up to ±0x76c | | `_DAT_100a0714 ≠ 0` |
| jump impulse | `vy = 0; vy += J + (−0xc80 − ((|vx| + 0x4e2) >> 3))`, cap 8000 | −13.1 at rest | J = `_DAT_100a0678`: carried platform vy, or −0x898 (−2200) with High Jump |
| jump hold | the impulse is re-applied each frame JUMP is held, while the counter (6 on ground, 3 when leaving a rope/ladder) > 0 | | `_DAT_100a0764` |
| swim stroke | `−0x640 − ((|vx|+200)>>3)`, halved on later strokes, cap 2000; gravity 0x50 | | in water |
| spin jump | DOWN + JUMP with counter 1..6 → spin flag, sound | | |
| wall-climb vertical | vy = −1000 (UP) / +1000 (DOWN) / 0, or ±0x578 = 1400 with Double Speed | 3.9 | climb state `_DAT_100a0758 ≠ 0` (§3.4) |
| wall jump | JUMP while clinging: vx = +0x8ca if the wall side `PTR_DAT_100a074c` is 1 else −0x8ca; vy = 0 (−0x8cb when the counter is 3) | 8.8 | |
| magic-carpet ride (ridden sprite type 0x438/0x439) | the **carpet's** vx ±0x140/frame (cap ±0xc80), vy ±0x100/frame (cap ±4000) from the arrows; player vx forced 0 | | `PTR_DAT_100a05a4` |

Additional rules read in `.HandlePlayerSprite`:
- Deep "type 5" liquid (`s+0x128 == 5`) scales max walk/run by submersion:
  `f = (bodyHeight − depthClamp)·256/bodyHeight`, `max = 0x76c − f·0x3b6>>8` (walk),
  `0xc80 − f·0x640>>8` (run); vertical speed × **0.65** (`dRam100a1a30`; `tools/const.py 100a1a30` →
  bytes `3fe4cccccccccccd`, f64 0.65) [HIGH] ⚑ corrected (review 2026-10-03) #6. Kind 5 is desert **quicksand** by where it
  occurs (§5.1) [MED].
- Level side-push hdr+0x272c (−320 in level 15): airborne vx drifts by v up to 5·v; grounded
  x += v/4 per frame [HIGH].
- Camera look-ahead and focus: engine.md §5.
- Hot rect: `(l,t,r,b) = (0x26,0x22,0x3e,0x55)` = 24×51 px inside the 100×120 cell; crouching
  with a shield changes it; on the glider `(0x37,0x3e,0x63,0x61)`.

## 5. Health, hazards, death

### 5.1 Values  [HIGH]
- Health: `G+4` and the player's `s+0xa4`; max `G+0xa` (start 560 = 0x230). Magic `G+0xe`, max
  `G+0xc` (start 560). Bars are value>>3 px, max 196 px (`.UpdateHealthMagic`).
- Breath (oxygen): `G+6`, never above health; refilled on surfacing. While
  `.ShouldEmitBubbles` is true it drops 1/frame (8/frame in kind-5 liquid); at 0 (and not
  invulnerable) a 30-frame (15 in kind 5) countdown `G+8`, then breath sound, **−0x70 HP**,
  `+0x116 = 0x28` (40 invulnerability frames), countdown re-armed, repeating. Arithmetic:
  `.HandlePlayerSprite`, handler dump lines 2461–2487 (function-relative 1810–1836); the
  countdown is re-armed to 0x1e when the gate is false (l. 2743) [HIGH] ⚑ corrected (review 2026-10-03) #11.
  `.ShouldEmitBubbles @ 1004ba14` is **not** "underwater" in general: it returns 1 iff the
  player is not dying and `0 < s+0x120 < 0xf` (previous frame's `+0x11c`). `.HandleUnderWater`
  computes `+0x11c = surfaceY − s+0x0a − face top inset` clamped ≥ 1, i.e. the height of the
  sprite's visible top above the water line, 1 when fully under — so the gate is "visible top
  less than 15 px above the surface or below it" [MED: face-inset meaning of `*(short*)s+0xc0`
  inferred]. (Fix-pass note: this also makes §0's "+0x11c depth below surface" read as
  "top-above-surface, clamped ≥1"; physics §4's "depth == 1" = fully submerged.)
- Liquids (`s+0x128` = BG water kind − 200), after 2 frames inside: kind 0 hurts only on levels
  with hdr+0x26cd ≠ 0 (30, 31 — the "freezing-cold water" levels); kinds 1 and 2 always hurt:
  −0x70 HP, 60 invulnerability frames, 13 flash frames, cooldown `_DAT_100a06d8 = 35` frames,
  only while HP > 4; kind 3 heals per frame: breath +8, HP +4, magic +4 up to max (the
  manual's "Ziridium Brine"); kind 5 is the slow-sinking liquid of §4 [HIGH for arithmetic].
  With a walk-on power-up active, a water cell whose kind equals the power-up's kind is
  resolved as solid floor 16 px higher instead (`.HitPlayerTileSprite`) [HIGH]. Kind names:
  0 water, 1 acid, 2 lava by the power-up order (spheres 1331 Solid Water, 1332 Solid Acid,
  1333 Solid Lava → kinds 0,1,2; `.HitPlayerSprite` handler dump l. 3755 (function line 601)
  `PTR_DAT_100a063c = type − 0x533`) [MED]. Level census (reviewer's Python over the
  `0x29a0` BG-kind tables × BG maps, REVIEW-2026-10-03 #8; not re-run in the fix pass): kind 2
  occurs **only** in the fire levels 50/51/52/55 (693/1205/394/52 cells) → lava; kind 0 is River
  of Fears' 6,144 cells plus the two `0x26cd = 1` ice levels → water; kind 5 occurs only in 22/40/45
  (The Labyrinth, Parched Earth, The Dig) → desert **quicksand**; kind 3 (heals) is small pools in
  22 levels. Labels: 0 water / 2 lava / 5 quicksand [HIGH on code + census]; 1 acid [MED,
  power-up order only] ⚑ corrected (review 2026-10-03) #8.
- `.HurtPlayer @ 1005473c (p, attacker, dmg, blood, invul, coinsLost)`: `HurtSprite(p, dmg,
  attacker.vx, −1000, invul, 12)`; on a hit: if a Multi Crystal (item 0x13) is held, 4 crystal
  shards fly and a 15-frame timer later removes one crystal; climb/spin/pull-up states end;
  scream sound by damage (< 0xe0 vs larger); `coinsLost` (randomised ±1 when > 2, capped at
  `G+0x10`) coins are subtracted and spawned as 0x516 pickups.
- Damaging surface / ice: §3.3. Fire sprites 0x4b8, 0x4bb..0x4bd: −0xe0 unless Fire Charm (item
  0x18); lava/acid pools (Box class 0x5a0, mode `s+0x14c` 1/2): −0x70 / −0x150 unless the
  matching walk-on power-up or (lava) Fire Charm (`.HitPlayerSprite`).
- Death power-up sphere (0x53b): −0x380 HP.

### 5.2 Death sequence  [HIGH]
When HP ≤ 0 the dying counter `_DAT_100a069c` runs (animation frames, hot rect drifts 2 px/frame
after frame 8). At frame 80 (100 if `PTR_DAT_100a0560`): if the Resurrection Necklace (0x17) is
held, not on the glider, not killed by the debug key, and inside the map → revive: counter back
to 30, revive animation, at the end HP = breath = max, necklace removed, 60 invulnerability
frames; otherwise `DAT_100a5106 = 1` ends `.GameLoop` → `.DeathEffect` (engine.md §6).

## 6. Wind and currents  [HIGH for arithmetic; [MED] for orientation]
Overlay layer o1 in 0..15 at the sprite's centre cell with strength o2 > 0 (`.StandardSpriteHandles`):
`dir = (o1 + 18) mod 36`; `.LookupModedImpulse(dir, o2·15)` gives a vector from a 36-entry
10°-step table (dir 0 = (−m, 0), dir 1 = (−0.985m, +0.174m), …; doubles at 0x100a1890..18c8);
if the sprite is not already moving faster than the impulse in that direction, a second
lookup with `o2·14` (scaled by `s+0x90/256` when < 255) is applied: x += ramped (over 33 frames)
horizontal part, vy += vertical part; flag `s+0x92` set. Water current: §2.

## 7. Enemies (classes from world-data-format.md §3.5)  [MED]

Callbacks per class (`.Setup…/.Handle…/.Hit…/.Hit…Tile…/.Kill…`, addresses in
`tools/targets.txt`). Values read from each Setup (several HP values = variants selected by
type/params, conditions not traced):

| class | HP (`+0xa4`) values in Setup | gravity `+0x110` | hot rect (first SetRect) |
|---|---|---|---|
| Walker (goblins, 1700..1769) | 500, 2000, 1500 | 0x151 = 337 | (0x28,10,0x3c,0x46) |
| Crawler (1712) | 1000, 500, 300, 1600 | ±0x151 (−337 = ceiling crawler) | (0x14,0xc,0x2c,0x21) |
| Roach (1720) | 200 | 0x151 | (0x23,0x1b,0x44,0x2d); vx 0x4b0 |
| Blob (1730..) | 1500, 700, 1100, 2000 | 0xfa | (0xe,0xc,0x2f,0x21) |
| Bat / insect swarms | 100, 200 | 0 | varies |
| Gremlin (1770..) | 500 | 0 | (0x28,0x26,0x59,0x50) |
| Floater (1780..) | 500 | 0 | (0x17,2,0x38,0x5c) |
| Frog (1800..) | 500, 350, 1000 | 0x8c | (0xb,0x14,0x48,0x49) |
| Salamander (1810..) | 500 | 0x8c | (0xe,0x14,0x42,0x49) |
| Warrior (boss, 1820) | 1200, 2000 | 0x122 | (0x1a,0x17,0x4a,0x3a) |
| Wizard (boss, 1830) | 1200, 1000 | 0x122 | (0x42,0x1e,0x7c,0x7e) |
| Dillo (armadillopine, 1870..) | 500, 1100 | 0x122 | (0x1a,0x17,0x4a,0x3a) |
| Crab (1890..) | 1000 | 0 | (0x18,0x18,0x4c,0x4c) |
| Chief (goblin chief boss, 1910) | 1200, 2000 | 0x276 | (0x5e,0x55,0xa5,0xd4) |
| Demon (fire guardians, 1920) | 1000, 2000 | 0 | (0x1a,0x17,0x4a,0x3a) |
| Xichra (final boss, 1990) | 5000 | 0 | (0x5c,0x3a,0x93,0x90) |

Behaviour patterns (patrol/turn rules, attack timers, projectile types) are in the 22
`.Handle<Class>Sprite` routines (e.g. `.HandleWalkerSprite` 763 lines, `.AxGoblinCoreLogic`,
`.RandomDilloAttack`, `.RandomWarriorAttack`, `.ShootSpines`, `.HandleDemonSegs`,
`.UpdateXichraCannons`) — **NOT RESOLVED** in this pass. Shared facts: enemies hit by a player
shot whose `+0x04 == 1` call `.TurnIntoStatue` (120-frame statue, handlers swapped to the statue
set) [HIGH, 12 call sites found by a `bl` scan]. `+0x04` of a player shot is the **spell id**,
not the spawn type `id·256+power`: `.SetupPlayerShotSprite @ 1005925c` does
`*(uint *)(s+0x170) = type & 0xff; *(short *)(s+4) = (char)(type >> 8)` (handler dump
l. 4929–4930) before anything reads it, so the statue test means "Statue spell (id 1)" and a
replica must store the id in +4 and the power in +0x170 ⚑ corrected (review 2026-10-03) #3. The Statue/Box/Platform classes
set `+0x185` (one-way top, §8.1) [MED].

## 8. Non-enemy sprite physics: solids, ropes, springs, paths, platforms, flotation, landing, panting

⚑ corrected (review 2026-10-03) #2 — this section did not exist; the review found ropes, springs,
platforms, flotation and the landing/breathing routines absent from the bank. Read in the fix
pass from both dumps (main-dump line numbers unless "handler dump"). Units as §0.

### 8.1 Sprite-vs-sprite solids: `.PlatformBounce @ 100377c4` → `.RectBounce @ 1003e490`  [HIGH arithmetic; MED field names]
Called by 19 hit callbacks (`find_func.py '_PlatformBounce\('` on the handler dump):
`.HitPlayerSprite` (4), `.HitPlayerShotSprite`, `.HitEnemyShotSprite` (2), `.HitPlatformSprite`,
`.HitBoxSprite` (12), and one each in the Crawler, Walker, Roach, Blob, Bat, Gremlin, Floater,
Frog, Salamander, Dillo, Warrior, Chief, Wizard, Xichra Hit routines. Arguments
`(mover, solid, centre or NULL, bounce factor f, mover rect, bounce flag)`.
- If the solid has a surface function (`solid+0x1e8`, §8.2), its hot-rect top is temporarily
  replaced by `fn(solid, moverCentreX − solid.x)`; if the mover's rect then misses the solid's
  rect there is no contact. The original top is restored afterwards.
- `.RectBounce` intersects the two hot rects and decides the side from the mover's
  **previous-frame** position (`pos − v>>8`) against the solid's centre lines:
  from above → if `vy > 0`: `vy = 0` (bounce flag: `vx = vx·f>>8, vy = −vy·f>>8`), mover
  bottom placed on the solid top, **returns 1**; from below → if `vy < 0` same zero/bounce,
  mover top placed under the solid, **returns 2**; from a side → if moving into it `vx = 0`
  (or bounce), x snapped, and if `solid+0x138 > 0` the solid is pushed
  `vx += mover+0x13c · (solid+0x138 · (mover.vx − solid.vx) >> 8) >> 8`; returns 0.
  Sloped tops: when `solid+0xd2/+0xd4 ≠ −1000` they are the left/right surface heights, the top
  is interpolated across the rect width, the landing slack is 0x20 px (else 8), and a landing
  sets the mover's slope `+0xd6 = ((d2 − d4) ± 1)·256 / width`.
  One-way solids (`+0x185`): only the from-above case, and only if the mover's previous bottom
  was within the slack of the top.
- `.PlatformBounce` on a landing (return 1, bounce flag clear): mover `+0xd0 = 1` if the solid
  is one-way; with a surface function `+0xd6 = −0x100 / 0 / +0x100` by `vx < −0x100 / |vx| ≤
  0x100 / vx > 0x100`; the mover's x is restored (landing never shoves sideways); mover
  `+0xcd = 1`, ground kind `+0xce = 3`, ridden sprite `+0xdc = solid`; solid `+0xe0 = mover`
  (rider) and `+0x186 = 1` (ridden this frame); if `solid+0x13a > 0` and the landing vy > 0x200
  the solid sags: `solid.vy += vy·solid+0x13a >> 8`. Return 2 sets the mover's ceiling flag
  `+0xcf = 1`. Riding (carry by the platform's dx, y snapped on top) is `.StandardSpriteHandles`
  (§2).

### 8.2 Ropes (class Rope, types 3020..3039; `.RopeCollide @ 1004c82c`, `.HandleRopeSprite @ 10084c1c`)  [HIGH arithmetic unless noted]
Setup (`.SetupRopeSprite`, `.SetupRopeSegArray @ 100843ac`): span = record param3 − param1,
end-height difference `+0x410a` = param4 − param2 (so the params read as the two end points
(x1,y1),(x2,y2) [MED]); a 0x4130-byte block at `+0x9c` holds per-pixel base (`+0x108`) and
dynamic (`+0x2108`) sag samples, sampled every `seg` px; span rounded to a multiple of `seg`;
hot rect = span × height, extended 16 px up and 40 px down; `+0x1e8` = TOC `_DAT_100a0ce4`
(the height function). Base sag at the centre = `rest`, shaped `rest·(h² − d²)/h²`.

| type | rest sag `+0x4114` | ridden max `+0x4118` | `+0x411c` (f32) | ease `+0x4120 = +0x4124` | seg `+0x410c` | contact sounds |
|---|---|---|---|---|---|---|
| 3020 (0xbcc) | 0xe00 (14 px) | 0x1a00 (26 px) | 1.0 | 0.4 | 20 px | set `_DAT_100a0304` |
| 3021 (0xbcd) | 0xa00 (10 px) | 0x2c00 (44 px) | 1.4 | 0.4 | 20 px | set `_DAT_100a0304` |
| 3022 (0xbce) | 0xc00 (12 px) | 0x1800 (24 px) | 1.4 | 0.4 | 24 px | set `_DAT_100a0300` |
| 3023..3039 | — no arm in `.SetupRopeSegArray`: block left as allocated | | | | | NOT RESOLVED |

(Floats `0x100a1be8` f32 = 1.4, `0x100a1bec` = 0.4, `0x100a1bf8` = 1.0, `tools/const.py`.)
- `.GetRopeHeight(rope, i)`: i clamped to `0..span−1`; `(base + dyn) >> 8` at i, linearly
  interpolated between the samples at multiples of `seg`.
- `.HandleRopeSprite` per frame: not ridden → every dynamic sample and the sag `+0x154` are
  multiplied by 0.4 (zeroed when unchanged); ridden → target `T = max·(h² − |h − i|²)/h²`
  (h = span/2, i = rider offset `+0x46`); `+0x154` moves 0.4 of the way to T per frame, snapping
  within 0x100; the dynamic samples become `+0x154 · (1 − (dist/sideLength)^p)` on each side via
  `.glue::pow` [MED: the exponent argument is hidden by the decompiler; `+0x411c` is the only
  candidate]. Then the segment sprites (type 600, one per `seg`) are placed on the curve with a
  face chosen from the local slope clamped ±14 px (`_DAT_100a0d04/08` tables built in
  `.InitRopeSprite`) [MED]. `+0x186` cleared at the end.
- `.RopeCollide` (from `.HandlePlayerSprite`, handler dump l. 852, every frame while not dying,
  right after `_DAT_100a0584 = _DAT_100a0588; _DAT_100a0588 = 0`): walks the list at
  `_DAT_1009ff58+0x5c`; for each sprite whose handler is `PTR_PTR_100a04f0` (the TVector
  `.SetupRopeSprite` installs) and type 3020..3039, if the player's centre x is strictly inside
  the rope's rect: `i = cx − rope.x ± 7` (+7 facing right, −7 facing left); no `+0x1e8` → the
  scan stops; `surf = rope.y + height(i)`.
  - Not on a rope last frame: grab iff `surf ≤ y+16 < surf+0x40` and the previous frame's
    `y+16` (`y − vy>>8 + 16`) was above `surf`; jump-hold counter `_DAT_100a0764 = 0`; landing
    sound (random of 3; vol 0x69 for 3022, 0x5f otherwise).
  - On this same rope last frame: jump-hold counter `= 6`; stays on.
  - DOWN held → not attached (drop through).
  - Attach: `_DAT_100a0718 = 0`, current rope `_DAT_100a0580 = rope`, on-rope `_DAT_100a0588 = 1`,
    player `y = surf − 16`, `vy = 0`, rope `+0x46 = i`, rope `+0x186 = 1`; footstep sound when
    the walk-animation state `_DAT_100a058c` is 1 or 8 (vol 0x4b for 3022, else 0x41).
  While on a rope the player is "airborne" for the §4 table (drag 600, air control ±1000).
- `.GetRopeBridgeHeight @ 1006b3d8`: `table[clamp(i, 0, 0x10b)]` from `_DAT_100a0a00`; the
  sprite that installs it was not found [NOT RESOLVED].

### 8.3 Springs (`.SuperSpring @ 10074e60`, Background types 1150..1159)  [HIGH arithmetic]
`.HitBackgroundSprite` (handler dump): on overlap with a spring (type 0x47e..0x487) player
shots are killed (`KillPlayerShot(shot,1,1)`) and enemy shots killed; then, if the hitter is not
itself a spring, the spring's cooldown `+0x46 == 0`, the hitter is not being killed and its
handler is not `PTR_PTR_100a0460` (one excluded class, unidentified): spring `+0x46 = 4`,
`SuperSpring(spring, hitter)` (cooldown decrement not traced — NOT RESOLVED). `SuperSpring`:
spring sound `_DAT_100a02f8` (restarted, vol 0x100) only if the spring centre is within 300 px
horizontally and 200 px vertically of the view centre (`PTR_DAT_1009fe78` + (0x130, 0xd0));
spring `+0x1c2 = 32000` [MED: animation timer]; then

| type | hitter vx | hitter vy | other writes |
|---|---|---|---|
| 1150 (0x47e) | += 0 | **= −0x2292** (−8850 → −34.6 px/frame) | `_DAT_100a0678 = 1`, `_DAT_100a0718 = 2` |
| 1151 (0x47f) | += 0 | = +0xa28 (+2600, downward) | `_DAT_100a0678 = 1` |
| 1152 (0x480) | = +0x1900 (6400) | = −0xd48 (−3400) | if the hitter's handler is `PTR_PTR_100a052c` (player [MED]): climb `_DAT_100a0758 = 0`, `_DAT_100a05b8 = 1` |
| 1153 (0x481) | = −0x1900 | = −0xd48 | same |
| 1154..1159 | += 0 | += 0 | sound only |

`_DAT_100a05b8` (the "launched" flag) is cleared by the next landing (§8.7).

### 8.4 `.FootPressure @ 100431ec` — ground hugging (not pressure plates)  [HIGH arithmetic; MED purpose]
Called from `.HandleKeys` (l. 44512, 44570: on the ground with LEFT/RIGHT held, `_DAT_100a0718 ==
0`, no Double Speed, `PTR_DAT_100a04d8 == 0`) and `.HandleBoxSprite` (handler dump l. 13374).
- Not riding (`+0xdc == 0`), not on a one-way top (`+0xd0 == 0`), ground kind `+0xce` not
  4/7/0x13/0x14, and not moving **uphill** (vx ≤ 0 excludes kinds 0xc, 0x20, 0x21, 0x2c, 0x2d,
  0x32..0x35; vx > 0 excludes 0xf, 0x22, 0x23, 0x2e, 0x2f, 0x36..0x39): `y(24.8) += |vx|` —
  the sprite is pressed into the floor by its horizontal speed every frame, so tile separation
  keeps it glued to down-slopes instead of launching off them.
- Riding a sloped top (`+0xd6 ≠ 0`): `d = |vx·slope| >> 8`; against the slope sign `y −= d`
  (uncapped), with it `y += min(d, 0x800)`. Returns the applied delta.

### 8.5 Programmed paths (`.SetupProgrammedPath @ 10044c58`, `.HandleProgrammedPath @ 10044fe8`; Background, Bat, Gremlin)  [HIGH arithmetic]
Mode `m = |param1|` (`+0xf0`; 100..199 → m − 100 and the radial start phase is dropped);
speed `+0xfc = param3`.
- m = 1 vertical shuttle: bounds `+0x100 = y + 8·speed`, `+0x104 = y + 256·param2 − 8·speed`
  (24.8; param2 = travel in px); `vy = speed`, `+0x13a = 0`. m = 2: the same on x, `vx = speed`.
  Per frame: direction `+0xf8 = +1`: past `+0x104` → −1, else `v += speed>>4` then clamp
  `v ≤ speed`; direction −1 mirrored against `+0x100`. (Ease-in at 1/16 of speed per frame,
  reversal at the bounds; the 8·speed margin absorbs the turn-around overshoot [MED purpose].)
- m = 3 floater: hot rect `SetRect(7,0,0x46,0x1e)`, buoyancy `+0x19e = 0x50`, gravity 0x15e,
  `+0x13a = 0x2d`, `+0x138 = 0x3c`; moved by §8.6 in water.
- m = 10/11 circular: `.MakeRadial(s, cx, cy, radius = param2, phase = param3, speed = param4,
  0 | 0x1e, …)`, optional spokes `.MakeRadiusSprites(s, param2/14, …)`; per frame `vx = vy = 0`,
  `.UpdateRadialPos`, `.UpdateRadiusSprites(s,0,0)` (radial geometry NOT RESOLVED).
- All modes zero `+0x194`.

### 8.6 Flotation and quicksand (`.HandleUnderWater @ 10042e30`, `.HandleFlotation @ 10042d04`)  [HIGH]
`.HandleUnderWater` is every tile-hit callback's water branch (21 callers). It finds the
surface row by walking up while the BG tile is water (kinds 200..209), sets `+0x11c` (§0), the
kind `+0x128`, splashes on entry (`+0x120 == 0`), and:
- **kind 5 (quicksand)**: per frame `+0x144 += 0xc0`, `y += 1 px`; floor line = entry surface
  `+0x148` + `+0x144>>8`; if the hot-rect bottom has reached the floor line and `vy ≥ 1`:
  bottom placed on it, `vy = 0`, ground kind `+0xce = 3` (the sprite stands on a sinking floor);
  moving up (`vy < 0`) pulls `+0x144` back to at most `bottom + 8 − surface` (≥ 0).
- if `+0x19e > 0`: `.HandleFlotation(s, surfaceY)`: target `= surfaceY + s+0x1a0 − hot-rect
  vertical midpoint`; `b = min(s+0x19e, 0x15e)`, negated when the target is above the sprite;
  `vy += b`; then `vy ×= 0.93` when `b ≤ 0` (rising) or `×= 0.86` (sinking) — doubles
  `0x100a17f0` = 0.93, `0x100a17f8` = 0.86 (`tools/const.py`); if `y == target` and
  `|vy| < 0x46` → `vy = 0`, y snapped.
Buoyant sprites: path m = 3 (0x50), Platform mode 3 raft (0x50), mode 4 ice floe (0x3c, float
offset 10), type 0x58c springboard (0x168, own call), type 0x6a4 in the Platform handler (grows
+1 with probability ½ per frame up to 0x50). `.HandlePlayerSprite` writes the player's
`+0x19e` at 6 sites — not traced [NOT RESOLVED].

### 8.7 `.CheckGroundCeilingHitEffects @ 100544d8` — landing/bump effects (player)  [HIGH]
Called from `.HitPlayerTileSprite` (3) and `.HitPlayerSprite` (1); skipped on the glider
(`_DAT_100a05e0`). `.HandlePlayerSprite` latches each frame: previous ground kind
`_DAT_100a0738`, impact speed `_DAT_100a0660 = vy` before movement, and clears the landed /
bumped latches `_DAT_100a0724/_DAT_100a0720` before `.ApplySpeedAndSeparateFromTiles`
(handler dump l. 1184, 1197, 1357–1360).
- Landing (now `+0xce ≠ 0`, airborne last frame, not yet latched): latch; if not in water last
  frame and impact > 0x400 → dust sprite 0x4b1 at (x+0x18, y+0x53), layer 0xb; clear
  `_DAT_100a05b8`; `v = impact >> 7`, 0 if < 0x30, cap 100; stop sounds `_DAT_100a03f8` and
  `_DAT_100a03cc` if playing; then on a 0x58c springboard: sound `_DAT_100a0280` vol 0x55 if
  impact > 0x578; elsewhere `v == 0`: `_DAT_100a0284` vol 0x3c if impact > 700 (not from
  water); `v > 0`: `_DAT_100a0288` vol `2v + 0x14` (not from water). The routine writes no HP
  (no fall damage here).
- Ceiling bump (not latched, not dying, `+0xcf` set): latch, sound `_DAT_100a0408` vol 0xa0.

### 8.8 `.HandleBreathing @ 1004bb44` — panting cadence (not oxygen)  [HIGH; raw disasm checked]
From `.HandlePlayerSprite` (handler dump l. 1396) unless dying. Exertion `E = _DAT_100a06a4`
(i16): +1 per walking frame, +3 per running frame [MED: walk/run attribution of the two
`.HandleKeys` sites], +8 per jump / swim stroke (`.HandleKeys`),
+0x19 per cast (`.CastSpell`), +0x50 per hit (`.HurtPlayer`); −2 per frame while > 0.
- If oxygen `G+6 <` health `G+4`: `f = (1.0 − (float)G+4) · 400.0`; if `E + f < 220.0`,
  `E = (i16)(E + f)` (floats `0x100a1a48` = 1.0, `0x100a1a44` = 400.0, `0x100a1a40` = 220.0;
  raw `1004bbc4 lfs f1,-0x5df8(r2)` … `fsubs f4,f1,f4; fmuls f4,f4,f2; fadds; fcmpo; fctiwz;
  sth`). As written `f ≤ 0` for any health ≥ 1 and the 16-bit store wraps, so while oxygen is
  below health E is driven negative and wraps through the i16 range (intended formula was
  probably a ratio — LOW; a replica of 100% reproduces the wrap).
- `E` capped at 600; level `L = clamp((min(E,600) − 100) >> 6, 2, 6)`; the period counter
  `_DAT_100a06b0` decrements; at ≤ 0 it reloads with `9 − L` frames (7 calm … 3 exhausted) and,
  unless (chest frame `PTR_DAT_100a04fc == 1` and `E < 0xa0` and previous phase ≥ 2), the phase
  `sRam100a5f5e` advances; at phase 2: `.ShouldEmitBubbles` and oxygen > 0 → `.EmitBubble`
  (sprite 0x410 ±16 px ahead, not in kind 5); else oxygen > 0 → breath sound (`_DAT_100a0400`
  when the period < 4, else `_DAT_100a03fc`, vol 0x37). Phase wraps after 5 (6-phase cycle);
  chest frame = triangle (0,1,2,3,2,1) of the phase when not bubbling, else 2; `_DAT_100a06a8`
  = phase.

### 8.9 Platforms (class Platform, types 0x578..0x595; `.DoSetupPlatformSprite @ 10062098`, `.HandlePlatformSprite @ 100635b4`)  [HIGH arithmetic; MED names]
`.HandlePlatformSprite` runs `.DoSetupPlatformSprite` on its first frame (`+0x17c`). Mode
`+0xb0` = type for 0x582..0x585 and 0x58c, else record param1 (100..199 → −100, radial phase
dropped); speed `+0x14c` = param3; default hot rect `(0x10,6,0x3d,0x1e)`; face from the
0x578 set by type.

| mode | setup | per frame |
|---|---|---|
| 1 / 2 | vertical / horizontal shuttle exactly as §8.5 (bounds `+0x150/+0x154`, initial offset param4·256, `vy`/`vx = speed`); mode 1 `+0x13a = 0` | §8.5 shuttle rule (direction in `+0xa6`); mode 2 also springs back to its record y: when sagged below it, `vy > 0` → `vy >>= 1` and once ≤ 0x80 it becomes −0x80, else `vy −= 0x40` down to −0x180; above it y snaps to the record y |
| 5 / 6, 7 / 8 | → 1 / 2 with `+0x13a = 0`, `+0x15c = 1` (7/8 also `+0x158 = 1`) | not ridden → velocity × 0.4 per frame (`dRam100a1a70` = 0.4); ridden → shuttle; 5/6 move only while ridden, 7/8 keep `+0x186` once ridden (run on) |
| 3 | raft: rect `(6,5,0x4c,0x1e)`, buoyancy 0x50, gravity 0x15e, `+0x13a = 0x2d`, `+0x138 = 0x3c` | gravity only when not in water; tilt: rider dx/5 (sign-inverted) as a target, `+0x46` eases ±2/frame, `+0x1aa` = angle mod 360; friction 100 |
| 4 | ice floe [MED: the Ice-Wall link is inferred from the spell's 0x57c spawn and the melt timer; who sets mode 4 on a code-spawned floe was not traced]: `+0x16c == 0` → rect `(0,0,0x28,0x31)`, gravity 0x15e, `+0x13a = 0x16`, buoyancy 0x3c, float offset 10; else rect `(0,3,0x28,0x18)`, no gravity; `+0x138 = 0x3c` | gravity when not in water; friction 100; lifetime `+0xa6` counts down, flashes below 0x2d, at 0 explodes into particles and dies |
| 10 / 11 | single circular platform: `.MakeRadial(s, x+0x28, y+0x14, r = param2, phase = param3, speed = param4, 0 / 0x1e)`; spokes `param2/14` of type 0x596 | `vx = vy = 0`; `.UpdateRadialPos`; no tile collision |
| 20 / 21 / 22 | wheel of 3 / 2 / 4 platforms (two/one/three extra `MTNewSprite`s) at 0/120/240, 0/180, 0/90/180/270°; spokes `param2/12` (20) or `/14` | turns only while ridden: `.RadialWheelStep(s, 0x100)`; siblings' angle = own + 0x7800/0xf000, 0xb400, 0x5a00/0xb400/0x10e00 (degrees·256) |
| 30 | pair at 0/180° with chain spokes (type 0x59b, `param2/16`), `+0x150 = 0` | ridden → `.RadialWheelStep(s, +0x150)`; free → angular speed (`+0x198 → +0x14`) drifts ±0x18/frame back toward the hanging angle (balance swing) |
| 50 | sinking platform: count `+0xa6 = param2` (0 → 2), depth `+0x150 = param3` (0 → 2000 px), home `+0x15c = y` | gravity+tiles each frame; armed: count decrements while ridden, at ≤ 0 gravity ramps +0x1e/frame to 400, else `vy = g = 0`; past home + depth → return: `vy −= 0x32`/frame to −0x200 until back at home, re-armed |
| 51 | crumbling platform: count `param2` (0 → 2), gone-time `param3` (0 → 0x2d) | ridden frames count down; then a 19-frame break-up (sound on frame 1, pitched `0x10000 + param4·0xf3b` when param4 ≠ 0; tint stages at 6/10/14), hot rect emptied after step 18; when the break-up counter passes `param3` it re-forms over 12 frames and re-arms (param3 = −1: re-forms straight after the break-up) |
| 52 | blinking platform: phase `+0xa6 = param4`, on-time `param2` (0 → 32000), cycle `param3` | `+0xa6` cycles 0..param3; inside the on-time `+0x46` falls to 0 else rises to 0x14; tint stages at 2/6/10/14; ≥ 0x13 → hot rect empty (intangible) |
| type 0x582 / 0x583 (catapult, faces left for 0x583) | mass 0x8c, friction `+0x114 = 0x3c`, gravity 300, rect `(0x20,0x9c,0xa6,0xb8)` mirrored about 0xd8; child seat 0x584 | when the seat is ridden a 19-step face script runs (table at `0x100a6314`: 1,1,2,2,1,0,3,4,5,6,6,5,5,4,4,3,3,0,0; sounds at steps 0 and 6); while the face is 5 the seat's rider gets `vx ± 6000` (by facing) and `vy −= 0x9c4`; the player rider gets `+0x14c = 1`; seat placed per face at (2,0x80) (3,0x89) (5,0x92) (0x23,0x36) (0x78,0x19) (0x96,0x11) (0xc1,0x15) |
| type 0x584 | catapult seat: one-way (`+0x185 = 1`), rect `(0,0,0x18,0x18)`, no face, no hit callback | — |
| type 0x585 | rect `(0,0,0x2d,0x5c)`, solid, no face, no hit callback | — |
| type 0x58c (springboard) | children 0x58d (base) and 0x58e (gauge); rect `(5,0,0x2d,0x32)`, buoyancy 0x168, gravity 100, `+0x13a = 0x50`; rest line `+0x150 = top + 0xe` | above the rest line `vy += (rest − y)·16` (or `+600` when above the top and rising); between the rest line and top + 0x28 → `.HandleFlotation` (exactly at rest with `abs(vy) < 0xdc` → still) [MED: the decompile shows the call with one argument]; deeper → clamped at top + 0x28, vy reflected upward; ridden below rest → jump bonus `+0x194 = −0x80·min(depression, 0x1c)` (up to −0xe00, used by §0 +0x194); rect bottom shrinks with depression; gauge frame by depth |

Integration: modes < 10 and types ≥ 0x58c add v to position themselves; modes < 10 then
`.SeparateFromTiles2`; 0x582/0x583 `.ApplyFriction(+0x114)` + `.ApplyGravityAndSeparateFromTiles`;
other radial modes only separate. `.HitPlatformSprite` (the platform's own hit callback) was not
read [NOT RESOLVED].
