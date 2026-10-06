# Ferazel's Wand 1.0.3: platforms, ropes, radial geometry, springs (physics §8 remainder)

Code readings only; nothing behaviour-verified.
Date 2026-10-03. Sources: main dump `ghidra/Ferazel_pef.decompiled.c` ("main l. N"), handler dump
`ghidra/Ferazel_handlers.decompiled.c` ("handler l. N"), raw disassembly `ghidra/Ferazel_pef.disasm.txt`
(addresses), data constants via `docs/ferazel/tools/const.py`, TOC/TVector names via `tools/pef.py`
`tocfunc()` and `tools/tocrefs.py`, placements from `Ferazel's Wand World Data.rsrc` `Mlvl` records
(walker copied from `tools/rsrc_census.py`, decoding per world-data-format.md §3.4).

Scope (INDEX NOT-RESOLVED 14 and part of 5): radial geometry (`.MakeRadialTables`, `.MakeRadial`,
`.UpdateRadialPos`, `.FindUpdatedRadialSpeed`, `.RadialWheelStep`, `.BounceRadial`,
`.MakeRadiusSprites`, `.UpdateRadiusSprites`, `.SetRadiusSpritesEffect`); `.SetupPlatformSprite`,
`.DoSetupPlatformSprite` per type, `.HitPlatformSprite`, `.HitPlatformTileSprite`, see-saw/chain spoke
sprites; who sets mode 4 on the ice floe; the `+0x88`/`+0xb8` visual fields; the rope routines and types
3020..3039, the sag exponents, the `.GetRopeBridgeHeight` installer; the spring leftovers
(`+0x46` cooldown, `PTR_PTR_100a0460`, `_DAT_100a0718`, `_DAT_100a0678`); the player's `+0x19e`;
`.GetFGCrunchDirTile` arg order; the hot-rect tables at `DAT_100a4794+0xc` and `DAT_100a4314`.
Placement censuses for Platform, Rope and spring types.
⚑ wave 2 (2026-10-04): continued in `platforms-ropes-radial-2.md` (§8 frame order and active list,
§9 sibling order, §10 globals, §11 `+0x190` / frozen platform, §12 wall-ice faces).

Units as physics.md: px; 24.8 fixed point for positions and velocities ("1/256 px"); angles in
**degrees·256** ("1/256°"); one frame = one `.GameLoop` iteration. Rects in `SetRect` argument order
(left, top, right, bottom) unless stated. Record params: p1..p4 = rec +4/+6/+8/+0xa (world-data §3.4).

---

## 1. Radial geometry (shared by platforms, programmed paths, Background maces)

### 1.1 Tables: `.MakeRadialTables @ 1003d5c4` (main l. 35463)  [HIGH]
Built once (flag `*_DAT_100a00e4`). For i = 0..359: θ = 2.0·π·i / 360.0 (doubles `0x100a1970` = 2.0,
`0x100a18e8` = 3.1415926535, `0x100a18e0` = 360.0), then
`cosT[i] = (int)(float)(256·cos θ·256)`, `sinT[i] = −(int)(float)(256·sin θ·256)` (`0x100a18f0` = 256.0;
raw `1003d65c fmul; fmul; frsp; fctiwz` — truncation of the single-rounded product).
`cosT` = table at TOC slot `_DAT_100a021c` (raw `lwz r30,-0x7624(r2)`), `sinT` (already negated, so
"up" on screen is positive angle) = `_DAT_100a00e0` (`-0x7760`).

### 1.2 Radial block (`+0x198` → 0xa4-byte `NewPtrClear` block; `+0x187` = has-radial)  [HIGH]
`.MakeRadial(s, cx, cy, r, speed, angle, g, damp, hubDamp, persp) @ 1003d718` (main l. 35507; raw
argument registers r3..r10 + stack halfwords at caller sp+0x3a/+0x3e, checked at 1003d718..1003d81c).
Does nothing if `+0x187` is already set.

| block off | type | meaning | init |
|---|---|---|---|
| +0x00 / +0x04 | i32 24.8 | hub centre x / y | cx·256, cy·256 |
| +0x08 / +0x0c | i32 | hub velocity x / y (added to the hub each frame) | 0 |
| +0x10 | i32 | hub-velocity damping /256 (applied when > 0); also "hub may roll" when < 0x100 (§1.5) | hubDamp |
| +0x14 | i32 | angular speed, 1/256° per frame | speed |
| +0x18 | i32 | angle, 1/256°, wrapped to [0, 0x16800) | angle·256 |
| +0x1c, +0x20 | i32 | radius·256 (+0x20 is the one read) | r·256 |
| +0x2c / +0x2e | i16 | angle limits max° / min° (both 0 = none) | 0 |
| +0x30 | i16 | limit bounce /256 | 0 |
| +0x32 | i16 | spoke count (≤ 0x18) | `.MakeRadiusSprites` |
| +0x34 | i16 | spoke face size (px) | `.MakeRadiusSprites` |
| +0x36 | i16 | "gravity" toward 270° (1/256° per frame²) | g |
| +0x38 | i16 | angular-speed damping /256 (applied when > 0) | damp |
| +0x3a | i16 | projection: 0 = plane circle, 1 = x fixed (depth = cos part), 2 = y fixed (depth = sin part) | persp |
| +0x3c | i16 | current draw scale /256 (persp ≠ 0) | 0x100 |
| +0x3e | i16 | far-side scale floor (150) | 0x96 |
| +0x40 | i16 | depth·256 (persp ≠ 0) | — |
| +0x44 + 4k | ptr | spoke sprites (spoke k stored at +0x40 + 4(n−k)) | `.MakeRadiusSprites` |

### 1.3 Per frame: `.UpdateRadialPos @ 1003debc` (main l. 35790; raw 1003debc..1003e304)  [HIGH]
1. `speed = FindUpdatedRadialSpeed(block, angle, speed, 0, 0)` (§1.4); `angle += speed`.
2. `hubX += hvx; hubY += hvy`; if `+0x10 > 0`: `hvx = hvx·(+0x10) >> 8` (set to 0 if unchanged),
   `hvy = hvy·(+0x10) >> 8`.
3. Angle wrapped into [0, 0x16800) by ±0x16800 loops.
4. Limits (only if `+0x2c` or `+0x2e` ≠ 0), raw 1003dffc..1003e0d4: if max > min the test side is
   `angle > 180°`, else `angle < 180°`; on the test side, `angle > max·256` → angle = max·256;
   otherwise `angle < min·256` → angle = min·256; a clamp sets `speed = −(speed·(+0x30) >> 8)`.
   (Max 45 / min 315 thus confines the angle to ±45° about 0°; max 225 / min 135 to ±45° about 180°.)
5. `a = angle >> 8` reduced to 0..359; `R = +0x20 >> 8`; `dx = ((R·cosT[a]) / 256) >> 8`,
   `dy = ((R·sinT[a]) / 256) >> 8` (first divide truncates toward 0 — `srawi; addze`; second is an
   arithmetic shift).
6. `persp = 0`: the sprite's hot-rect centre is put on the circle:
   `x = (hubX>>8) + dx − (s+0x10 − s+0xc)`, `y = (hubY>>8) + dy − (s+0xe − s+0xa)`.
   `persp ≠ 0`: depth `D = dx·256` (persp 1) or `dy·256` (persp 2), `f = (R256 − D) / (2.0·R256)`
   (R256 = `+0x20`; float); `+0x40 = (i16)(256.0·f)`; scale `= (i16)(255.0 − f·(256 − +0x3e))`
   → `+0x3c` and `s+0x1ae`; `s+0xb8 = ((i16)(0.05·256f) << 8) + 0xc0000` (draw effect 0xc,
   "lighting" level 0..12, §2.9); persp 1 keeps x = hub, y = hub + dy; persp 2 keeps y = hub,
   x = hub + dx (f32 `0x100a18d4` = 256.0, `0x100a18d0` = 255.0, f64 `0x100a18d8` = 0.05).
7. `s+0x14 = x·256`, `s+0x1c = y·256` (sub-pixel position discarded).

### 1.4 `.FindUpdatedRadialSpeed(block, angle, speed, wheel, noDamp) @ 1003dde4` (main l. 35753)  [HIGH]
Raw 1003dde4..1003de8c. With `g = +0x36 > 0` and `a = angle >> 8`: `speed += g` when
90 ≤ a ≤ 270, else `speed −= g` (a < 90 is first mapped to 360) — a constant-magnitude pull toward
270° (straight down, since sinT is negated), i.e. a **triangle-wave pendulum**, not a sine one.
Then if `+0x38 > 0` and `noDamp == 0`: `speed = speed·(+0x38) >> 8`. If `wheel ≠ 0` the wheel term of
§1.5 is added (never — `.UpdateRadialPos` passes 0).

### 1.5 Ridden wheels: `.RadialWheelStep(s, k) @ 1003e3e8` (main l. 35951)  [HIGH]
`speed += (mod(a)·k) >> 8` with `.FindRadWheelStepSpeedMod @ 1003e32c` (main l. 35918; raw constants
0x5a, 0xb4, 0x10e, 0x168): **mod(a) = a − 90 for a < 180, 270 − a for a ≥ 180** (−90 at 0°, 0 at 90°
and 270°, +90 at 180°; a triangular −90·cos). Then if `+0x10 < 0x100`: `hvx = −speed` — the hub
**rolls** sideways with the rotation (CCW → left), damped by `+0x10` each frame (§1.3 step 2).

### 1.6 Wall bounce: `.BounceRadial(s, tileCentreX) @ 10061ac8` (main l. 45984)  [HIGH]
No-op for s = 0. `speed = (int)(speed·−0.75)`, magnitude raised to 0x100 if below (sign kept, 0 →
+0x100); `hvx` the same; `hvy = (int)(hvy·−0.75)` (f64 `0x100a1a80` = −0.75, raw `10061b00 fmul;
fctiwz`). Then if `s+0x10 ≤ tileCentreX`: speed = +|speed|, hvx = −|hvx| (roll away to the left),
else speed = −|speed|, hvx = +|hvx|.

### 1.7 Spokes: `.MakeRadiusSprites(s, n, ?, type, size, setupTV) @ 1003d854` (main l. 35543)  [HIGH]
n capped at 0x18; `+0x32 = n`, `+0x34 = size`; n sprites `MTNewSprite(type, s.x, s.y, layer, −1,
setupTV)`, spoke k stored at `+0x40 + 4(n−k)`, `spoke+0x1d4 = s`, `+0x14c = k`, `+0x150 = n`,
`+0x154 = R`. `.UpdateRadiusSprites(s, slopeMode, base) @ 1003da00` (main l. 35607) walks j = 0..n−1
over `+0x44+4j` (= spoke k = n−1−j) and places it at `hub + (dx·j)/n − size/2`,
`hub + (dy·j)/n − size/2` (C division; dx/dy as §1.3 step 5) — spoke k sits at fraction (n−1−k)/n of
the radius. persp = 0: `spoke+0xb0 = a` (degrees, used for its face, §2.3). persp ≠ 0: the projected
axis is zeroed, `spoke+0x1ae = s0 + (j·2(+0x3c − s0))/n` with s0 = (+0x3e + 0x100)/2, `spoke+0x88 = 0`,
`spoke+0xb8` = effect 0xc with level `(i16)(0.05·((+0x40·j)/n + ((n−j)·0xc0)/n))`, `spoke+0xb0 = −90`.
slopeMode ≠ 0 (see-saw only, base 0x4b): `t = (dy·size)/dx`, every spoke gets left/right surface
heights `+0xd2 = base + size/2 − t/2 + t`, `+0xd4 = base + size/2 − t/2` (the sloped-top fields of
physics §8.1). `.SetRadiusSpritesEffect(s, w) @ 1003d980` writes w into every spoke's `+0xb8`.

### 1.8 Users of the radial code  [HIGH]
| user | centre | params → radial | spokes |
|---|---|---|---|
| Platform modes 10/11 (`.DoSetupPlatformSprite`, main l. 46348–46384; raw 100624c8..10062644) | (x+0x28, y+0x14) | r = p2, **speed = p3** (0 in the p1 = 110/111 form), **angle = p4°**, g = 0 / 0x1e, damp 0, hub 0 | p2/14 × type 0x596 (chain), size 0x10; `+0x1f8 = 0` (no tile callback) |
| Platform modes 20/21/22 (main l. 46312–46504) | same | r = p2, speed 0, angle 0/120/240, 0/180, 0/90/180/270, g 0, damp 0xf7, hub 0xf7 (0x100 in the 120..122 form) | p2/12 (20) or p2/14 × 0x596 |
| Platform mode 30 see-saw (main l. 46211–46255; raw 10062ecc..10063060) | same | r = p2, speed 0, angle 0 and 180 (sibling), damp 0xf7, hub 0x100; limits set after: record platform max 45 / min 315, sibling max 225 / min 135, bounce 0x60 | p2/16 × type 0x59b (see-saw segments, setup `.SetupSeeSawSegSprite`), size 0x18 |
| Programmed paths m = 10/11 (`.SetupProgrammedPath`, main l. 39126–39151; raw 10044e6c..10044f40) — Background, Bat, Gremlin | hot-rect centre (+0x10, +0xe) | r = p2, speed = p3 (0 in the 1xx form), angle = p4, g 0 / 0x1e | none: every caller passes spoke type −1 (handler l. 14013, 14284, 16518, 16562, 17385) |
| Background types 0x5c8..0x5d1 (1480..1489) modes 10..14 (`.SetupBackgroundSprite`, handler l. 14303–14360) | (x+0x32, y+0x32) | modes 10/13/14: r = p2, speed = p3, angle = p4; 11/12: speed 0, angle = p4, g = p3; persp = 1 for 12/13, 2 for 14; p1 = 0 → 11, p2 = 0 → 140, p3 = 0 → 30 written **into the record** | p2/16 (p2/20 for type ≥ 0x735) × 0x59a (0x59c for mode 14), size 0x18 |

Background radial behaviour beyond the geometry (damage etc.) is the Background reader's.

---

## 2. Platforms (class Platform, types 0x578..0x595 = 1400..1429)

### 2.1 `.SetupPlatformSprite @ 10061f94` (handler l. 8347)  [HIGH]
`InitSprite`; handler `+0x4c = _DAT_100a0200` (= `.HandlePlatformSprite`), hit `+0x5c` =
`.HitPlatformSprite`, tile hit `+0x1f8` = `.HitPlatformTileSprite` (TVectors resolved with
`tocfunc`); `+0x80 = −1`; position from the spawn copy (`+8`, `+6`); **`+0x185 = 1` — every platform
is one-way by default** (jump-through from below; physics §8.1); `+0x190 = 0`; gravity 0; landing sag
`+0x13a = 0x50`; `+0xa6 = 1` unless type 0x6a4 (§2.5); `+0x188 = 1` (no record write-back of the
position); `+0x17c = 0` (`.DoSetupPlatformSprite` runs on the first handler frame); empty hot rect.

### 2.2 `.DoSetupPlatformSprite @ 10062098` per type  [HIGH unless noted]
Mode `+0xb0` = type for 0x582..0x585 and 0x58c, else p1 (100..199 → −100 and the **angular speed /
wheel hub roll** are dropped, not the phase; correction of physics §8.5/§8.9). Face `+0xc0 =
set0x578 + (type − 0x578)·0x34`, the set being `LoadEncFaceSetFromPICT(0x578, 10 faces, 0x50×0x29)`
(`.InitPlatformSprite`, main l. 46065). `+0x14c = p3`. Default rect (0x10,6,0x3d,0x1e).

| type | role | notes |
|---|---|---|
| 0x578..0x581 (1400..1409) | generic platform, face 0..9 | behaviour = mode p1 (physics §8.9; radial modes §2.3) |
| 0x57a (1402) | as above | riding it suppresses a camera adjustment in `.FindUpperLeftCorner` (main l. 6005) [MED purpose] |
| 0x57c (1404) | as above; also the ice-floe/ice-wall type spawned by spell 3 (§2.4) | radial spokes get effect `0x10018` (`.SetRadiusSpritesEffect`) |
| 0x57d (1405) | **spiked underside**: `.HitPlayerSprite` (handler l. 3846) after the PlatformBounce: if the player's centre y ≥ the platform's centre y or `vy < −0x200`, the player is not invulnerable and not riding it → sound `_DAT_100a02dc`, HP −0x70, 60 invulnerability frames, 12 flash frames | shipped ×9 (levels 50, 62, 70), modes 1/2 |
| 0x582 / 0x583 (1410/1411) | catapult (physics §8.9) | `.HitPlayerSprite` skips the player collision entirely when p1 == 2 (handler l. 3841) — the level-4 catapult (p1 = 2) is walk-through |
| 0x584 (1412) | catapult seat (child), one-way, rect (0,0,0x18,0x18), no face, no hit callback | spawned only by 0x582/0x583 |
| 0x585 (1413) | rect (0,0,0x2d,0x5c), not one-way, no face, no hit callback | no spawner found, no placement |
| 0x586..0x58b, 0x58f..0x595 | **no type arm**: mode = p1, face index 14..19 / 23..29 lies past the 10-face set | only 0x591 (1425) is placed, as mode 30 whose own face is cleared every frame (§2.3) |
| 0x58c (1420) | springboard (physics §8.9) + children 0x58d base, 0x58e gauge (setup = Platform TVector `_DAT_1009ff2c`) | gauge draw: §2.9 |

### 2.3 Radial platform modes per frame (`.HandlePlatformSprite`, handler l. 8424–8650)  [HIGH]
- **10/11** (l. 8542): cooldown `+0xa6` (negative → +1 per frame, else 0); `vx = vy = 0`;
  `.UpdateRadialPos`; `.UpdateRadiusSprites(s,0,0)`; `+0x194 = 0`. Mode 10 = constant rotation at p3
  (1/256°/frame); mode 11 = triangle pendulum (g 0x1e, undamped) started at p4° with zero speed.
  No tile collision (`+0x1f8 = 0`).
- **20/21/22** wheels (l. 8553–8650): cooldown as above; if ridden (`+0x186`) and `+0xa6 ≥ 0`:
  `+0xb2 = 1`, `.RadialWheelStep(s, 0x100)`; update; `+0x186 = 0`; if `+0xb2 == 1` (this platform is
  the driver): every sibling gets `+0xb2 = 0`, angle = own + 0x7800/0xf000 (20), 0xb400 (21),
  0x5a00/0xb400/0x10e00 (22), the same speed and hub. Damping 0xf7/256 per frame on speed; the hub rolls
  (§1.5) and, via `.SeparateFromTiles2` → `.HitPlatformTileSprite` (§2.7), bounces off walls.
- **30 see-saw** (l. 8424–8478): `vx = vy = 0`, cooldown; if ridden and `+0xa6 ≥ 0`: `+0xb2 = 1`,
  `.RadialWheelStep(s, +0x150)` (lever factor written by the ridden segment, below); update;
  `.UpdateRadiusSprites(s, 1, 0x4b)`; if driver and (not ridden or `+0x150 == 0`): drift toward level —
  record platform: angle in (0x200, 0xb400) → speed −= 0x18, in (0xb400, 0x16600) → += 0x18;
  sibling (`+0x48 == −1`): angle < 0xb200 → += 0x18, > 0xb600 → −= 0x18; then the sibling is slaved
  (angle + 0xb400, speed, hub; ⚑ wave 2 (2026-10-04): hub position only, not hub velocity; list order and the
  one-frame lead of later siblings, the n+2 see-saw latency: platforms-ropes-radial-2 §9). Every frame `+0x186 = 0`, `+0x194 = 0`, **face `+0xc0 = 0`** (the arm is
  drawn only by its segments); its own hot rect is empty. ⚑ corrected (review 1c, 2026-10-03)
  (adjudication B23): settled for this file against physics §8.9's "hanging angle" — raw free arm
  `10063db4..10063e44` (`lis 1; subi 0x4e00` = 0xb200; > 0xb600 → −0x18), limits 0xe1/0x87 = 180 ± 45 [HIGH].
  **See-saw segment** type 0x59b (`.SetupSeeSawSegSprite` handler l. 9380, `.HandleSeeSawSegSprite`
  l. 9406): one-way, rect (0,0,0x18,0x58), `+0xd2 = +0xd4 = 0x57`; face from the 45-face set 0x59b by
  the angle folded to 0..89 (÷2), mirrored by `+0x17e`. When the player touches it (`.HitPlayerSprite`
  handler l. 3858, hitter handler `_DAT_100a01c8` = `.HandleSeeSawSegSprite`: player centre x within
  the segment's rect) the segment gets `+0xb2 = 1` and
  `_DAT_100a067c = 1` (⚑ wave 2 (2026-10-04): write-only, no reader — platforms-ropes-radial-2 §10.2); when it is then ridden it marks its arm ridden and writes the arm's
  `+0x150 = ((n − (k+1))·256)/n` = the segment's distance fraction from the pivot (lever).
  While tilted more than 5°, the segment separates from tiles with a temporarily lowered rect bottom.
- **Chain spokes** type 0x596 (`.HandleChainSprite`, handler l. 9325): face = set 0x599 (60 faces
  16×16) index `angle/6` (0..59), `+0x88 = 1`. Types 0x59a/0x59c (Background maces' chains): face by
  type, layer `+0x1ae − 0x100`, rotation `+0x1aa = (angle + 90) mod 360`, `+0x88 = 0`.

### 2.4 Who sets mode 4 on a spell-spawned floe  [HIGH]
The spawner itself, after `MTNewSprite` returns (MTNewSprite clears the 0x1fc struct and runs the
setup proc immediately — `.MTNewSprite @ 10033060`, main l. 30596; the record index is −1 so
`.DoSetupPlatformSprite` keeps `+0xb0`):
- `.HandlePlayerShotSprite` (handler l. 5415–5427): an Ice-Wall shot (spell id 3) entering plain
  water (`+0x128 == 0`) → `MTNewSprite(0x57c, x−10, cy−4, layer 2, −1, Platform)`, `+0xa6 = 0xb4`
  (180-frame lifetime), `+0xb0 = 4`, `+0x13a = 4` (dead write: the first-frame setup sets 0x16);
  `+0x16c = 0` → floe face/rect.
- `.HitPlayerShotTileSprite` (handler l. 5761–5776): the same shot hitting a solid tile →
  0x57c at (tileX − 0x17) with `+0x16c = 1`, or (tileX + 0xf) with `+0x16c = 2` (wall-ice faces 1/2 of
  set 0x2c7, rect (0,3,0x28,0x18), no gravity) ~~[MED: which contact side selects 1 vs 2]~~ ⚑ wave 2 (2026-10-04): HIGH — face 1 = ledge merging into a
  wall on its right (kinds 2/6/7), face 2 = on its left (kinds 0/4/5), PICT 711 decoded (platforms-ropes-radial-2 §12); `+0xa6 = 0xb4`,
  `+0xb0 = 4`.

### 2.5 Walker corpse as a platform (type 0x6a4)  [HIGH]
`.HandleWalkerSprite` (handler l. 10540–10552): a dead walker (state 4) that is in water after its
death timer passes 0x32 gets handler `_DAT_100a0200` (Platform), rect (0x10,0x35,0x42,0x47), float
offset `+0x1a0 = −6`, one-way, `+0x17c = 1` (no Platform setup), `+0x13a = 0x20`, `+0x138 = 0x3c`. Its
`+0xb0` is already 4, so it runs the mode-4 branch with no lifetime (`+0xa6 = 0`); buoyancy grows +1
with probability ½ per frame to 0x50 (physics §8.6). ⚑ wave 2 corr (2026-10-04) EG2 #3: water reaches it
through the Walker tile callback kept in `+0x1f8` → `.HandleUnderWater` → `.HandleFlotation`;
equilibrium `y = surface − 68` (hot rect 3 px submerged); no lifetime — the corpse floats permanently
(`1006a9ec..1006aa10`, `10043070..10043084`, `10064ad0`; enemies-ground-2 §1). ⚑ corrected (review 1d, 2026-10-03) #5: its
gravity test (`100649c4`, `+0x11c == 0 ∧ +0x120 == 0`, previous-frame water contact) is the one
branch shared with raft mode 3 and floe mode 4 (`1006496c`/`10064974`/`10064980` → `10064988`) —
physics-sprites §8.9.

### 2.6 `.HitPlatformSprite(self, other) @ 10064d94` (handler l. 9148)  [HIGH]
- `other` is a player shot (handler `.HandlePlayerShotSprite`) with id 1 (Statue): shot killed,
  `self+0x190 = 0`, `.TurnIntoStatue(self)`. (⚑ wave 2 (2026-10-04): `+0x190` is store-only in the whole binary;
  the frozen platform: platforms-ropes-radial-2 §11.)
- `other` is a Platform-handled sprite: unless both are modes 3/4 (rafts/floes) or both are
  0x582..0x585 (catapult parts): `PlatformBounce(self, other, own rect centre, 0, own rect, 0)` — the
  platform is the mover; a springboard (0x58c) uses `+0x154` as its vy for the call.
- Anything else: nothing (other classes collide in their own Hit callbacks).

### 2.7 `.HitPlatformTileSprite(s, tilePos, kind, layer) @ 10064f04` (handler l. 9192)  [HIGH]
- Mode 4 on an FG hit (layer 1): rect temporarily `(0,−6,0x28,6)` — floes collide with tiles by a
  12-px band at their top line, then the rect is restored.
- FG (layer 1): `.WallBounce(..., bounce)` with bounce 0x80; 0 for a 0x58c moving with `|+0x154| <
  0x200`; 0x20 for mode 50. On contact: modes 10..0x1d restore the pre-separation position and, if
  `+0xa6 == 0` and `+0x180 == 0`: `+0xb2 = 1`, every linked sibling (`+0x1d4..+0x1e0`) gets cooldown
  `+0xa6 = −5` (and the `+0xb2 = 0` write always lands on `+0x1d4` — source bug, raw 100650e4/
  10065108/1006512c), own `+0xa6 = −5`, `.BounceRadial` on self and siblings with
  tileCentreX = tilePos.x + 16; `+0x180 = 1` (cleared again by `.StandardSpriteHandles` every frame,
  main l. 32233 — at most one bounce per frame). Mode 50: state 0xb (return), y −= 1.
- BG kinds < 100 → `.WallBounce(…, 0)`, 100..199 → `.WallBounceBG(kind−100)`, water kinds →
  `.HandleUnderWater` unless `+0x140`.
In practice only modes 20..22 reach the bounce (10/11 have no tile callback; 30 and 50 are excluded
from `.SeparateFromTiles2`).

### 2.8 Visual-stage fields  [HIGH for writes and dispatch; MED for blend percentages]
| field | meaning (reader) |
|---|---|
| `+0x88` u8 | draw the light overlay (`.WrapLightFace`) after the face when set, unless the effect mode is 0xe (`.WrapDrawSprites @ 100144c8`, main l. 10334). `.InitSprite` sets 1. |
| `+0x89` u8 | per-frame dynamic lighting: `+0xb8 = light·256 + 0xc0000 + fakeLight` (l. 10286–10297) — set by the raft (mode 3) together with `+0x88 = 0` |
| `+0xb8` i32 | **draw-effect word** `mode<<16 | arg` passed to `.WrapDrawFace` → `.BlitEncFaceX @ 1002c908` (main l. 26913–27050): 0 plain; 5 diffuse; 6 water ripple; 8 behind tiles; ~~0xa clipped draw (arg = clip)~~ 0xa **vertical squash** by arg/256, raw copy (`10027614..10027630`); 0xb **translucent**, arg selects the blend table 0 → `_DAT_100a015c`, 1 → `0158`, 2 → `0154`, 3 → `0150`, 4 → `014c`, 5 → `0160`, ≥0x80 → `0144 + (arg−0x80)·0x1000`; 0xd translucent ripple; ~~0xe mask-only~~ 0xe solid silhouette in palette index arg; ≥0x14 tile blend; `.BlitEncFaceSpecial*` implements only 1, 3, 4, 6/9, 0xc (jump table `0x100a3d64`); 2, 7, 0xf, 0x10..0x13 read an undefined table and are never written (draw-effects §2) ⚑ wave 2 corr (2026-10-04) DE #5. Hurt flash overrides it with `0x30000 + n` / `0x40000 + 2n` (l. 10272–10281). |
| `+0x1ba` / `+0x1bc` i16 | bottom / top draw clip in face rows (32000 = none, 0 = invisible) |
| `+0x1ae` / `+0x1aa` i16 | draw scale /256 / rotation degrees (`.BlitEncFaceScale`/`Rot`) |

Blend tables (`.BuildTintTable`, main l. 17743–17815): 0x015c = ½·A + ½·B, 0x0158 = ¾·A + ¼·B,
0x0154 = ¼·A + ¾·B per RGB channel (A = row colour, B = column colour). ~~[MED: which operand is the
sprite pixel not traced …]~~ ⚑ wave 2 corr (2026-10-04) DE #6: row = sprite pixel, column = background
(or the parallax pixel where the mask is 0xff) (`10027fe0..10028054`; draw-effects §2.7) [HIGH] — so
level 1 is the most opaque and level 2 the most transparent, as the crumble/reform order implies.

Stage sequences (handler l. 8670–8810, 9055–9073, 8990–9008):
- mode 51 crumble, counter `+0x46`: > 2 → `+0x88 = 0`; > 6 → `0xb0001`; > 10 → `0xb0000`; > 14 →
  `0xb0002`; > 18 → empty rect and `+0x1ba = 0` (gone). Re-form: rect back at once, > 4 → `0xb0002`,
  `+0x1ba = 32000`; > 8 → `0xb0000`; > 12 → effect 0, `+0x88 = 1`, re-armed.
- mode 52 blink, `+0x46` ramps 0..0x14: > 2 → effect 0, `+0x1ba = 32000`, `+0x88 = 1`; > 6 →
  `0xb0001`, `+0x88 = 0`; > 10 → `0xb0000`; > 14 → `0xb0002`; ≥ 0x13 → empty rect, `+0x1ba = 0`.
- mode 4 floe, lifetime `+0xa6 < 0x2d`: face reset, `+0x88 = 1`, effect 0 or `0xb0000` on frames where
  `*_DAT_1009fd30 ≠ 0` ~~[MED: that global as a flash phase]~~ ⚑ wave 2 (2026-10-04): HIGH — `_DAT_1009fd30` is the frame
  parity (1, 0, 1, … per frame), so a 2-frame translucent blink (platforms-ropes-radial-2 §10.1).
- springboard gauge 0x58e: fill `q = ((top+0x2d − y') << 8)/0x2d`; q < 11 → no face; else face 0x58e
  with effect `0xa0000 + q` when q < 0xfb, else 0.

### 2.9 Census: shipped Platform placements (24 `Mlvl`, 169 records)  [HIGH]
Record byte +1 is 0 in every Platform, Rope and spring record.

| type | p1 (mode) | n | levels | p2 | p3 | p4 |
|---|---|---|---|---|---|---|
| 1400 | 1 | 8 | 2,21,22 | travel 140..420 | speed 1400..2400 | 0 |
| 1400 | 2 | 22 | 1,2,3,22,40,51 | 100..300 | 1000..2000 | 0/50/130 |
| 1400 | 6 / 7 / 8 | 2 / 1 / 1 | 21 / 50 / 50 | 1940..2060 / 180 / 1740 | 1270..1536 / 512 / 1024 | 0 / 0 / 1735 |
| 1400 | 51 | 5 | 21 | 0 | 0 | pitch 1..5 |
| 1400 | 52 | 20 | 50,52 | on 25/30 | cycle 60..180 | phase 0..120 |
| 1401 | 1 / 10 / 52 | 2 / 4 / 19 | 4 / 1,2,3 / 10,21 | 80,200 / r 60,140 / 25 | 1000 / speed 500 / 125,250 | 0 / 0..180 / 0..175 |
| 1402 | 1 / 11 | 6 / 7 | 15 / 1,4 | 200,300 / r 100..180 | 1000,1600 / 0 | 0,180 / 0,180 |
| 1403 | 7 / 10 / 20 / 52 | 2 / 3 / 5 / 7 | 21 / 4 / 1,2,3,21 / 5,55 | 630 / r 100 / r 55..65 / 30 | 1536 / 1000 / 0 / 90 | 630 / 0,120,240 / 0 / 0..67 |
| 1404 | 1 / 2 / 6 / 7 / 11 | 8/8/1/3/7 | 30,31 | | | |
| 1405 (spiked) | 1 / 2 | 3 / 6 | 70 / 50,62 | 120..700 | 1200..2000 | 0,200 |
| 1407 / 1408 | 3 (raft) | 2 / 10 | 10 / 2,50,51 | 0 | 0 | 0 |
| 1410 (catapult) | 1, 2 | 3 | 4 (p1 2), 10, 21 | 0 | 0 | 0 |
| 1420 (springboard) | — | 2 | 3 | 0 | 0 | 0 |
| 1425 | 30 (see-saw) | 2 | 3 | r 140, 190 | 0 | 0 |

Unused in shipped data: modes 4 (from records), 5, 21, 22, 50, every 1xx form, types 1406, 1409,
1411..1419, 1421..1424, 1426..1429.

---

## 3. Ropes (class Rope, types 3020..3039)

### 3.1 Setup, idle, segments  [HIGH]
`.SetupRopeSprite @ 10083f20` (handler l. 19089): handler `.HandleRopeSprite`, no hit / tile
callbacks, `+0xa4 = 6` (inert: no hit callback), `+0x80 = 1`, `+0x188 = 1`, `+0x46 = 0`, `+0xa6 = 4`,
idle extents `+0x1c8 = +0x1ca = (p3 − p1)/2`, `+0x1ce = 0x40` (read by `.HandleIdleSprites @ 100081ac`),
`+0x1d0 = 0x3c` (no reader found), active→idle callback `+0x54 = .RopeIdleize`, idle→active
`+0x58 = .RopeDeIdleize` (TVectors `PTR_PTR_100a0d00` / `0cfc`; dispatched by
`.ActiveToIdleSprite`/`.IdleToActiveSprite`, main l. 4141/4231). `.RopeIdleize` kills the segment and
two end sprites and sets `+0x170 = 0` (no animation); `.RopeDeIdleize` recreates them
(`.MakeRopeSegSprites`), `+0x186 = 1`, `+0x170 = 1`. Segments: type 600, `.SetupRopeSegSprite`
(`+0xa4 = 400`, handler `.HandleRopeSegSprite` = Standard handles/cleanup only), one per seg plus two
end sprites at (x − seg, y − seg/2) and (x + span, y + dy − seg/2) that are never given a face.

### 3.2 Types one by one (`.SetupRopeSegArray @ 100843ac`, main l. 52036)  [HIGH]
Block `+0x9c` (0x4130 bytes, `NewPtrClear` via `.AllocateGameMem`).

| type | seg | rest sag | ridden max | dyn exponent `+0x411c` | decay/ease | segment faces `+0x4128` | landing / step volume |
|---|---|---|---|---|---|---|---|
| 3020 | 20 | 0xe00 | 0x1a00 | 1.0 (`0x100a1bf8`) | 0.4 / 0.4 | PICT 0x28a set (30 faces 20×20) | 0x5f / 0x41, sounds `_DAT_100a0304` |
| 3021 | 20 | 0xa00 | 0x2c00 | 1.4 (`0x100a1be8`) | 0.4 / 0.4 | PICT 0x28c set (30 × 20×20) | 0x5f / 0x41, `0304` |
| 3022 | 24 | 0xc00 | 0x1800 | 1.4 | 0.4 / 0.4 | PICT 0x292 set (30 × 24×24) | 0x69 / 0x4b, `_DAT_100a0300` |
| 3023..3039 | — | — | — | — | — | — | **confirmed: no arm** |

All three also write `+0x4110 = 15`, `+0x410e = seg` and a second face `+0x412c` — write-only
(raw: only the three stores each at 10084440..1008459c). PICT 0x289 is loaded into `PTR_DAT_100a0d18`
and never read. For 3023..3039 the zeroed block gives seg 0 and the `divw` at 100845f8 divides by
zero (undefined on PPC); none is placed (§3.6), so a replica may reject them.

### 3.3 Position and span  [HIGH]
`span = p3 − p1`, `dy = +0x410a = p4 − p2`, `nSeg = (span + seg/2)/seg` (truncating), span rounded to
`nSeg·seg`; `x = recX + (span₀ − span)/2 − span/2`, `y = recY − dy/2` (raw 10084610..100846b4);
hot rect (0, min(0,dy) − 16, span, max(0,dy) + 40); `+0x1e8 = .GetRopeHeight` (TOC `_DAT_100a0ce4` →
TVector `0x100a24cc` → 10084264, now resolved). The census shows the editor's convention: p1..p4 are the
two absolute end points and the record x/y is their midpoint − 6 (all 49 ropes: x − mid ∈ {−6, −6.5},
y − mid ∈ {−6, −6.5}); the code only uses differences and centres the rope on the record position.

### 3.4 Sag curves  [HIGH]
Base (static), every pixel j: with `m = span/2` (rider slot `+0x46` at setup):
`base[j] = (int)( R·(1 − (|m−j| / side)^2.0) + (h1·256·(span−j))/span + (h2·256·j)/span )`, side = m on
the left, span − m on the right, R = rest sag, h1 = `+0x4108` = 0, h2 = dy; single-precision `pow`
with **exponent 2.0** (double `0x100a1be0`, raw 10084840 `lfd f2,-0x5c60(r2)` before `bl pow`
10084864/100849a0). `base[span] = base[span+1] = dy·256`. Initial `+0x154 = R`, `+0x46 = 0`.
Dynamic (`.HandleRopeSprite`, handler l. 19259), only at multiples of seg:
- not ridden: `dyn[j] = (int)((float)dyn[j]·decay)`, 0 if unchanged; `+0x154` likewise;
- ridden by a rider at i = `+0x46`: `T = max·(h² − |h−i|²)/h²` (h = span/2, integer); `+0x154` eases
  0.4 of the way to T and snaps within 0x100; `dyn[i] = (i16)+0x154`; left of i:
  `dyn[j] = (int)(sag·(1 − ((i−j)/i)^p))`, right: `(1 − ((j−i)/(span−i))^p)`, **p = `+0x411c`** (raw
  10084f34 `lfs f2,0x411c(r3)` → `bl pow` 10084f54; second loop 10085008); the seg+2 samples from span
  on are zeroed.

### 3.5 Segment placement (handler l. 19437–19490; tables `.InitRopeSprite`, main l. 51895, raw 10083a94..)  [HIGH]
For segment k (x = rope.x + k·seg): `s = (i16(dyn[(k+1)seg]) − i16(dyn[k·seg]) + i16(base[(k+1)seg]) −
i16(base[k·seg])) >> 8`; `s' = clamp(s, −14, 14)`; face index `s' ≥ 0 ? s' : 14 + |s'|`; y offset
`−15 + (s' >> 1)` px for s' ≥ 0, `−15 − (|s'| >> 1)` px for s' < 0 (tables `_DAT_100a0d08[i] =
(15 − (i>>1))·256`, `_DAT_100a0d04[i] = (15 − ((i−14)>>1))·256` for i ≥ 15, minus 0x1e00); plus
`(s − 14)·256` when s > 14; `seg.y = rope.y·256 + base[k·seg] + dyn[k·seg] + offset`.

### 3.6 Census (49 placements) and reversed ropes  [HIGH]
3020 ×20 (levels 10, 11, 50, 51, 52), 3021 ×5 (70), 3022 ×24 (3, 10, 11, 21, 22, 52); no 3023..3039.
Spans 139..537 px, |dy| ≤ 73 px. **Two ropes are authored right-to-left** (p1 > p3): level 11 record 76
(3020, span −238) and level 3 record 145 (3022, span −173). With a negative span: nSeg < 0 (no
segments), the hot rect has right < left so `.RopeCollide`'s strict inside test never passes (dead rope;
only the two faceless end sprites exist), and `.SetupRopeSegArray` stores `base[m]`, `base[span]`,
`base[span+1]` at negative indices — three words written up to 0x370 bytes before the block (heap
corruption in the original; a replica need not reproduce it).

### 3.7 `.GetRopeBridgeHeight @ 1006b3d8` and its installer  [HIGH]
TVector `0x100a235c`, TOC slot `PTR_PTR_100a09f8`, referenced only by `.SetupBoxSprite` raw 1006bf64:
**type 0x5ba (1466, Box class)** sets `+0x1e8` to it, rect (−16, 50, 284, 120), one-way off, no
gravity; `.GenerateSprite` also queues idle sprite 0x5bb (the face-only foreground part, layer 0x32).
The table `_DAT_100a0a00` (0x10c i16) is built in `.InitBoxSprite` (main l. 47443–47478; raw
1006b24c..1006b390): all 50, then for segment k = 0..14 and i = 16k..16k+15:
`table[i + 8] = (int)(P[k]·(1 − f) + P[k+1]·f)`, `f = (i − 16k)/(268.0·0.0625)` = (i−16k)/16.75
(floats `0x100a1b00` = 268.0, `0x100a1afc` = 0.0625, `0x100a1af8` = 1.0; the store is `sth r0,0x10(r6)`
= +8 entries), with control points `P` = i16 at `0x100a671c`: 50, 58, 63, 66, 69, 70, 71, 72, 72, 71, 70,
69, 67, 64, 59, 50. Height(i) = `table[clamp(i, 0, 0x10b)]` (surface y offset 50..72 below the sprite
top; a fixed, non-dynamic sag). **No shipped placement of 1466** (census) — the routine is dead in
shipped content.

---

## 4. Springs (Background types 1150..1159): the leftovers  [HIGH unless noted]
- **Excluded class**: `PTR_PTR_100a0460` = `.HandleEffectSprite` (Effect class) — effects never trigger
  springs. Also not triggered by another spring (`PTR_PTR_100a0480` = `.HandleBackgroundSprite` with a
  spring type), by a sprite being killed, or while the cooldown is non-zero (`.HitBackgroundSprite`,
  handler l. 15357–15368). Player shots touching a spring are killed (`KillPlayerShot(…,1,1)`), enemy
  shots (`PTR_PTR_100a0488` = `.HandleEnemyShotSprite`) killed.
- **Cooldown**: set to 4 on trigger; `.HandleBackgroundSprite` (handler l. 14805–14833) decrements
  `+0x46` by 1 per frame clamped to 0..3 and uses it as the face index (compression frames; tables
  `_DAT_100a0b08` for 1150, `0b04` for 1151, `0b00` for 1152/1153 with 1153 mirrored) — re-armed 4
  handler frames after a hit ~~[MED: hit/handle order within a frame]~~ (⚑ wave 2 (2026-10-04): HIGH — all handlers run
  before all hit callbacks, so a spring fired in frame n can fire again in frame n+4; platforms-ropes-radial-2 §8.1). **Only 1150..1153 decrement**;
  ~~1154..1159 would fire once per life (and are unplaced).~~ ⚑ corrected (review 1c, 2026-10-03)
  (adjudication A4; synthesis ledger A4): 1154..1159 are **inert** — `.SetupBackgroundSprite`'s tree
  (`100717cc..10071804`) has arms only for 0x47e..0x481 (`10071cc0`/`10071d14`/`10071d68`/`10071db8`,
  each `stw r30,0x5c`); 0x482..0x487 fall through to `10072e8c` with the default `+0x5c = 0`
  (`1007178c`), so they get no hit callback and can never reach `.SuperSpring` (triggers-background
  §2.3). Unplaced [HIGH].
- **`_DAT_100a0678` (global 0x102bb7a4, i32) = the jump base J** of physics §4. Writers: `.ClearPlayerVars`,
  `.HandlePlayerSprite` (handler l. 916: 0 when on the ground or `*psVar26 ≠ 0`, ~~not frozen~~ ⚑ wave 2 (2026-10-04): and not riding a sprite (`*PTR_DAT_100a0558 == 0`);
  `*psVar26` = the climb flag `_DAT_100a0758`, raw `1004dc54..1004dc84`, platforms-ropes-radial-2 §10.3; l. 919:
  −0x898 with High Jump), `.HandleKeys` (= ridden sprite's `+0x194` at a jump), `.SuperSpring` (1 for
  1150/1151). Readers: `.HandleKeys` jump impulse; `.PlayerScroll` (main l. 43151, 43160): J ≠ 0
  forces the "snap camera y to target" branch. So the spring's J = 1 adds 1/256 px/frame to a jump
  but chiefly keeps the camera tracking the launched player until the next landing clears J [MED purpose].
- **`_DAT_100a0718` (global 0x102bb7ee, i16) = the player's air animation counter** (player-states.md
  §2, §3.12), not a sticky latch. ⚑ corrected (review 1b, 2026-10-03) #1. Writers: 0 by `.ClearPlayerVars`
  (from `.SetupPlayerSprite`) and `.RopeCollide` (rope attach); 1 by `.HitPlayerSprite` (two bounce
  sites, handler l. 4070, 4095) and `.HandleKeys` (raw 10054030, a jump with key 2 held in the swim/leap
  block); 2 by spring 1150. `.HandlePlayerSprite` loads the slot **once** into r27
  (`1004d648 lwz r27,-0x7128(r2)`; r27 is never reassigned in the function) and stores through r27
  all function long, so the TOC-load count (tocrefs) under-counts its writers: `li r0,0 … sth r0,0(r27)`
  at **100500c4, 10050250, 100505d4, 1005073c** (grounded / rope / swim / cling branches) zero it on
  every such frame; the per-frame airborne counter logic (+1 / +2 / = 18 / = 26 / ≤ 15) is
  10050308–10050444; 8 on a catapult launch at 1004e64c (player `+0x14c == 1`, handler l. 1192).
  Reads (`.HandleKeys` raw 10053668, 100538c8, 10054144): `== 0` gates `.FootPressure` (physics §8.4)
  and, at a jump, switching to the jump face `*_DAT_100a07e4` with `+0xce = 0`. So `.FootPressure`
  ground-hugging is skipped only on airborne frames and the first landing frame [HIGH for the stores;
  MED for the first-landing frame: rests on `.HandleKeys` running before the grounded clear in the same
  frame, not re-derived here]; it is never disabled for good. The spring's 2 is a non-zero air-face seed.
- **`.SuperSpring` `+0x1c2 = 32000`** is on the spring and is an occluder-rect edge
  (`+0x1be/+0x1c0/+0x1c2/+0x1c4`, consumed by `.StandardSpriteCleanup`, main l. 32445; default
  32000 from `.InitSprite`) — effectively a no-op reset, not an animation timer [MED].
- Census: 1150 ×30 (levels 15, 30, 31, 40, 50, 62), 1151 ×11, 1152 ×7, 1153 ×9; all params 0; 1154..1159
  unplaced.

## 5. The player's `+0x19e` (buoyancy)  [HIGH]
`.HandlePlayerSprite` has 3 stores (raw 1004f5b4, 1004f7c4, 1004f880; the "6 sites" of physics §8.6
counted reads and the `+0x1a0` stores too): during the dying sequence (counter `_DAT_100a069c` 1..29)
in both the glider branch (handler l. 1678) and the normal branch (l. 1740): `+0x19e += 1 +
(counter & 1)`, `+0x1a0 = −22`; set to 0 when the Resurrection-Necklace revive starts (l. 1761). A live
player's `+0x19e` is 0 (`.InitSprite`), so only the corpse floats. Readers: `.HandleUnderWater` →
`.HandleFlotation` (main l. 37989, 37862) and the player's own gravity gate (handler l. 1215,
raw 1004e728): gravity is skipped while in water (`+0x120 ≠ 0`) with `+0x19e ≠ 0`.

## 6. `.GetFGCrunchDirTile` argument order  [HIGH]
`.GetFGCrunchDirTile(a, b) @ 1003bf40` (raw 1003bf40..1003bfd0): `ConstrainXY(a, b, hdr+0xb280 − 1,
hdr+0xb282 − 1)` clamps a to the grid width and b to the height, then reads
`FG[b·width + a]` → **(x, y) in tile units**. `.SetupLevel` (raw 10004850..1000487c) calls it and
`.DestroyCrunchTile` with `r3 = G[0x60fa+4i]`, `r4 = G[0x60f8+4i]`, so each saved crunch pair is
**+0 = y (row), +2 = x (column)** — engine.md §9's "(y,x)" is confirmed and can be relabelled HIGH.
`.DestroyCrunchTile(x, y, …)` explodes/reshapes the 2×2 block (x..x+1, y..y+1).

## 7. Hot-rect tables of INDEX NOT-RESOLVED 5  [HIGH]
Raw 10002a4c..10002c10 (`.InitTileHotRects`): table `0x100a4794` has stride 0x14; its rect at **+4** is
per FG tile (96 entries), its rect at **+0xc** per kind 0..63 (the "second table"). The table at
`0x100a4314` has stride 0xc, rect at +4, 96 entries: (6,6,26,26) for i = 3..5, else (2,2,30,30).
Readers (every r2-relative reference, `subi rX,r2,0x30ac` / `0x352c`; no TOC slot points into either):
- `.SeparateFromTiles2` 1003cb20: the +4 rect indexed by **tile** (the live FG test, physics §3.1).
- `.SeparateFromTiles2` 1003ce74..1003ceb4: the **+0xc rect indexed by kind** — inside the second
  9-cell loop gated by `s+0xe4`, whose results are stored to the stack and discarded (dead code).
- `.WallBounce` 10037b8c (kind mod 100 < 0x30) and `.WallBounceBG` 1003a3a0 (kind < 0x3d): the **+4
  per-tile rect indexed by kind** — an early-out "tilePos + rect ∩ sprite rect empty → return 0". So
  these solvers test against the hot rect of FG *tile number = kind*, not the kind's own shape; a replica
  must index the per-tile table by kind here to be exact.
- `0x100a4314`: written by `.InitTileHotRects` only; no reader (the neighbouring r2−0x3530 users read
  a 4-byte word at 0x100a4310). Unused.

---

## NOT RESOLVED
1. ~~Pixel semantics of draw-effect modes 1..4, 7, 9, 0xc, 0x10..0x13 (`.BlitEncFaceSpecial*`), so what
   `0x10018` on 0x57c spokes looks like; which blend operand is the sprite pixel (§2.8).~~ → closed:
   draw-effects §2 (pixel rules; 0x10018 = mode 1, table 0x18, colours lighting-tables §3) and §2.7
   (row = sprite) ⚑ wave 2 corr (2026-10-04) DE #5, #6
2. ~~`_DAT_1009fd30` (floe flash phase?), `_DAT_100a067c` (set when the player touches a see-saw
   segment; reader not traced), `*psVar26` in the J reset (handler l. 915).~~ → closed: platforms-ropes-radial-2
   §10 (frame parity; write-only; climb flag) — ⚑ wave 2 (2026-10-04)
3. ~~`+0x190` on platforms (cleared before `.TurnIntoStatue`; meaning) and what `.TurnIntoStatue` does to a
   platform.~~ → closed: platforms-ropes-radial-2 §11 — ⚑ wave 2 (2026-10-04)
4. ~~Within-frame order of sibling wheel/see-saw updates (a slaved sibling may lead or lag one frame of
   speed depending on list order).~~ → closed: platforms-ropes-radial-2 §8–§9 — ⚑ wave 2 (2026-10-04)
5. ~~Whether `_DAT_100a0718` really never clears in play~~ — closed: it is zeroed every grounded / rope /
   swim / cling frame through r27 (§4). ⚑ corrected (review 1b, 2026-10-03) #1, #12 — no play-check
   needed.
6. ~~Which contact side gives the wall-ice face 1 vs 2 (§2.4).~~ → closed: platforms-ropes-radial-2 §12 — ⚑ wave 2 (2026-10-04)

## Proposed additions to physics.md §0
| off | type | meaning |
|---|---|---|
| +0x54 / +0x58 | proc | active→idle / idle→active callbacks (`.ActiveToIdleSprite`, `.IdleToActiveSprite`); ropes: `.RopeIdleize` / `.RopeDeIdleize` |
| +0x88 | u8 | draw the light overlay (`.WrapLightFace`); default 1 |
| +0x89 | u8 | dynamic lighting each frame into `+0xb8` |
| +0x9c | ptr | per-class block (rope: 0x4130-byte sag block) |
| +0xb0 / +0xb2 | i16 | class mode (platform: p1 or type) / sub-state (platform 50/51/52 state 10/0xb; radial "driver" flag); spokes: `+0xb0` = angle |
| +0xb8 | i32 | draw-effect word `mode<<16 | arg` (§2.8) |
| +0x14c..+0x15c | i32 | per-class params (platform: speed/bounds/flags; rope: span `+0x14c`, nSeg `+0x150`, sag `+0x154`; spoke: index/count/radius) |
| +0x16c | i32 | platform mode 4 face variant (0 floe, 1/2 wall ice) |
| +0x170 | i32 | rope animated flag (also player-shot power, as already noted) |
| +0x17c | u8 | first-frame setup done |
| +0x180 | u8 | radial wall-bounce latch |
| +0x187 / +0x198 | u8 / ptr | has radial block / radial block (§1.2) |
| +0x1aa / +0x1ae | i16 | draw rotation (degrees) / draw scale /256 |
| +0x1b6 / +0x1b8 / +0x1ba / +0x1bc | i16 | draw clips (left, right, bottom, top) |
| +0x1be / +0x1c0 / +0x1c2 / +0x1c4 | i16 | occluder rect in world px (StandardSpriteCleanup → clips) |
| +0x1c6, +0x1c8/+0x1ca/+0x1cc/+0x1ce | u8, i16 | idle-able flag; idle extents left/right/top/bottom |
| +0x1d4..+0x1e0 | ptr | linked sprites (siblings, children, parent) |

## Corrections to the existing bank
1. physics.md §8.5 and §8.9 (modes 10/11, "100..199 → −100 … radial phase dropped"; "phase = param3,
   speed = param4"): **speed = p3, start angle = p4°**; the 1xx form zeroes the speed (and for wheels pins
   the hub). Evidence: `.MakeRadial` stores r7 → +0x14 (speed) and r8·256 → +0x18 (angle) (raw
   1003d7ac..1003d7ec); callers pass r7 = p3-or-0, r8 = p4 (raw 1006252c/1006254c, 10044eb8/10044ed4).
   The `0 / 0x1e` argument is the pendulum gravity `+0x36`.
2. physics.md §8.5: "optional spokes `.MakeRadiusSprites(s, param2/14, …)`" — never taken: every caller
   passes spoke type −1.
3. physics.md §8.9 row 20/21/22: add the 0xf7 speed damping, the rolling hub (`hvx = −speed`, damped
   0xf7) and the wall bounce (§1.5, §1.6, §2.7).
4. physics.md §8.9 row 30: not "chain spokes … drifts back toward the hanging angle". 0x59b are
   see-saw segments (the rideable surfaces); the arm's angle is limited to ±45° (bounce 0x60/256);
   the rider's segment sets the lever `+0x150 = (n−k−1)·256/n`; free, it drifts back to **level**
   (0°/180°) at ±0x18; the arm itself has an empty rect and no face (§2.3).
5. physics.md §8.9 type table: types 0x586..0x58b and 0x58f..0x595 have no arm (face index past the
   set); 0x57d is a damaging platform; 0x582/0x583 with p1 = 2 are not solid to the player; every
   platform is one-way by default (§2.1, §2.2).
6. physics.md §8.9 mode 4: "who sets mode 4 … was not traced" → the spawners write `+0xb0 = 4`,
   `+0xa6 = 0xb4` after `MTNewSprite` (§2.4); the Ice-Wall link is now HIGH.
7. physics.md §8.2: the `.glue::pow` exponent is `+0x411c` for the ridden curve (HIGH, raw 10084f34) and
   2.0 for the static curve (raw 10084840); the static curve also carries the end-height ramp
   (§3.4); the `+0x1e8` → `.GetRopeHeight` link is HIGH (also physics §0 +0x1e8 row); the params are the
   absolute end points and the record sits at their midpoint − 6 (§3.3); 3023..3039 confirmed armless and
   unplaced; two shipped ropes are reversed and dead (§3.6).
8. physics.md §8.2 last bullet: installer of `.GetRopeBridgeHeight` = Box type 0x5ba (1466), unplaced
   (§3.7).
9. physics.md §8.3: excluded class = Effect (`.HandleEffectSprite`); cooldown decrement found (only
   1150..1153); `+0x1c2` is an occluder edge, not an animation timer; meanings of `_DAT_100a0678` (J)
   and `_DAT_100a0718` per §4 = the air animation counter (player-states.md §2/§3.12), zeroed every
   grounded/rope/swim/cling frame (raw 100500c4/10050250/100505d4/1005073c through r27 loaded once at
   1004d648). ⚑ corrected (review 1b, 2026-10-03) #1 — the earlier "launch latch, never decays" reading
   came from counting TOC loads and is withdrawn.
10. physics.md §8.6 last sentence: the player's `+0x19e` is written only by the death/revive sequence
    (3 stores), §5.
11. engine.md §9 crunch pairs: "(y,x)" upgrade to HIGH (§6).
12. physics.md §3.2 last paragraph / INDEX NOT-RESOLVED 5 (tables part): resolved per §7, including that
    `.WallBounce`/`.WallBounceBG` index the per-tile rect by kind.
13. physics.md §8.3/§8.4 (for the consolidated pass): name `_DAT_100a0718` "air animation counter";
    `.FootPressure` runs whenever it is 0, i.e. on every grounded frame except the first landing frame —
    slope-hugging is never disabled for good. (Review 1b #1.)
14. ⚑ wave 2 (2026-10-04) (moved after 13 — ⚑ corrected (review 2g, 2026-10-04) #7): further corrections (frame order, layers, `.HitPlayerSprite` reached only through
    `.MTCollideSpecialSprite`) are in platforms-ropes-radial-2 "Corrections to the existing bank".
