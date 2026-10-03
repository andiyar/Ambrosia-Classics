# Ferazel's Wand 1.0.3 — physics (part 2): non-enemy sprite physics (§8)

Register: code readings only; **nothing behaviour-verified**. Labels per claim (INDEX §Labels).
Units, field names and §0–§7 as in `physics.md` (part 1). This file holds physics.md **§8
unchanged in numbering** (§8.1–§8.9): it was moved here, text kept, by the deepening synthesis pass
(2026-10-03) when physics.md passed the ~650-line split rule, so every "physics §8.x" reference in
the bank resolves here. Deepening corrections are marked `⚑ corrected (deepening 2026-10-03)` in
place, with pointers to the new files (platforms-ropes-radial.md, triggers-background*.md,
player-states*.md, spells-detail.md).

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
(x1,y1),(x2,y2) [MED]; ⚑ corrected (deepening 2026-10-03): HIGH — absolute end points, the record sits at their
midpoint − 6; two shipped ropes are reversed and dead, platforms-ropes-radial §3.3, §3.6); a 0x4130-byte block at `+0x9c` holds per-pixel base (`+0x108`) and
dynamic (`+0x2108`) sag samples, sampled every `seg` px; span rounded to a multiple of `seg`;
hot rect = span × height, extended 16 px up and 40 px down; `+0x1e8` = TOC `_DAT_100a0ce4`
(the height function). Base sag at the centre = `rest`, shaped `rest·(h² − d²)/h²`.

| type | rest sag `+0x4114` | ridden max `+0x4118` | `+0x411c` (f32) | ease `+0x4120 = +0x4124` | seg `+0x410c` | contact sounds |
|---|---|---|---|---|---|---|
| 3020 (0xbcc) | 0xe00 (14 px) | 0x1a00 (26 px) | 1.0 | 0.4 | 20 px | set `_DAT_100a0304` |
| 3021 (0xbcd) | 0xa00 (10 px) | 0x2c00 (44 px) | 1.4 | 0.4 | 20 px | set `_DAT_100a0304` |
| 3022 (0xbce) | 0xc00 (12 px) | 0x1800 (24 px) | 1.4 | 0.4 | 24 px | set `_DAT_100a0300` |
| 3023..3039 | — no arm in `.SetupRopeSegArray`: block left as allocated | | | | | ~~NOT RESOLVED~~ ⚑ armless and unplaced (platforms-ropes-radial §3.2) |

(Floats `0x100a1be8` f32 = 1.4, `0x100a1bec` = 0.4, `0x100a1bf8` = 1.0, `tools/const.py`.)
- `.GetRopeHeight(rope, i)`: i clamped to `0..span−1`; `(base + dyn) >> 8` at i, linearly
  interpolated between the samples at multiples of `seg`.
- `.HandleRopeSprite` per frame: not ridden → every dynamic sample and the sag `+0x154` are
  multiplied by 0.4 (zeroed when unchanged); ridden → target `T = max·(h² − |h − i|²)/h²`
  (h = span/2, i = rider offset `+0x46`); `+0x154` moves 0.4 of the way to T per frame, snapping
  within 0x100; the dynamic samples become `+0x154 · (1 − (dist/sideLength)^p)` on each side via
  `.glue::pow` [MED: the exponent argument is hidden by the decompiler; `+0x411c` is the only
  candidate] ⚑ corrected (deepening 2026-10-03): exponent = `+0x411c` for the ridden curve (raw `10084f34`) and 2.0 for
  the static curve, which also carries the end-height ramp (platforms-ropes-radial §3.4) [HIGH]. Then the segment sprites (type 600, one per `seg`) are placed on the curve with a
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
  sprite that installs it was not found [NOT RESOLVED]. ⚑ corrected (deepening 2026-10-03): Box type 1466 (0x5ba, rope
  bridge, unplaced) sets `+0x1e8` to it; `.InitBoxSprite` fills the table (platforms-ropes-radial
  §3.7, pickups-boxes corr. 9).

### 8.3 Springs (`.SuperSpring @ 10074e60`, Background types 1150..1159)  [HIGH arithmetic]
`.HitBackgroundSprite` (handler dump): on overlap with a spring (type 0x47e..0x487) player
shots are killed (`KillPlayerShot(shot,1,1)`) and enemy shots killed; then, if the hitter is not
itself a spring, the spring's cooldown `+0x46 == 0`, the hitter is not being killed and its
handler is not `PTR_PTR_100a0460` (one excluded class, unidentified): spring `+0x46 = 4`,
`SuperSpring(spring, hitter)` (cooldown decrement not traced — NOT RESOLVED). ⚑ corrected (deepening 2026-10-03): the
excluded class is **Effect** (`.HandleEffectSprite`); `.HandleBackgroundSprite` decrements `+0x46`
1/frame clamped 0..3 and shows it as the face (re-armed 4 frames after a hit, 1150..1153 only)
(triggers-background §2.3, platforms-ropes-radial §4). `SuperSpring`:
spring sound `_DAT_100a02f8` (restarted, vol 0x100) only if the spring centre is within 300 px
horizontally and 200 px vertically of the view centre (`PTR_DAT_1009fe78` + (0x130, 0xd0));
spring `+0x1c2 = 32000` [MED: animation timer] ⚑ corrected (deepening 2026-10-03): `+0x1c2` is an occluder-rect edge
(default 32000), so this is a no-op reset, not a timer (platforms-ropes-radial §4,
triggers-background-2 §6); then

| type | hitter vx | hitter vy | other writes |
|---|---|---|---|
| 1150 (0x47e) | += 0 | **= −0x2292** (−8850 → −34.6 px/frame) | `_DAT_100a0678 = 1`, `_DAT_100a0718 = 2` |
| 1151 (0x47f) | += 0 | = +0xa28 (+2600, downward) | `_DAT_100a0678 = 1` |
| 1152 (0x480) | = +0x1900 (6400) | = −0xd48 (−3400) | if the hitter's handler is `PTR_PTR_100a052c` (player [MED]): climb `_DAT_100a0758 = 0`, `_DAT_100a05b8 = 1` |
| 1153 (0x481) | = −0x1900 | = −0xd48 | same |
| 1154..1159 | += 0 | += 0 | sound only — ⚑ unreachable: no Setup branch, no hit callback, none placed (triggers-background §2.3) |

`_DAT_100a05b8` (the "launched" flag) is cleared by the next landing (§8.7).
⚑ corrected (deepening 2026-10-03): `_DAT_100a0678` is the jump base J of §4 (spring: J = 1 mainly keeps the camera tracking
the launched player, platforms-ropes-radial §4 [MED purpose]); `_DAT_100a0718` is the player's
**air-animation counter** (player-states §3.12): 0 on the ground, spring 1150 sets 2, a catapult
8. The platforms file's reading "launch latch that never decays" is refuted by raw stores of 0
through a register in `.HandlePlayerSprite` (`1004d648` loads the slot into r27; `sth …,0(r27)` at
`100500c4`, `100505d4`, `1005073c`) — synthesis ledger A1.

### 8.4 `.FootPressure @ 100431ec` — ground hugging (not pressure plates)  [HIGH arithmetic; MED purpose]
Called from `.HandleKeys` (l. 44512, 44570: on the ground with LEFT/RIGHT held, `_DAT_100a0718 ==
0` (= air-animation counter 0, §8.3 ⚑ corrected (deepening 2026-10-03)), no Double Speed, `PTR_DAT_100a04d8 == 0`) and `.HandleBoxSprite` (handler dump l. 13374).
- Not riding (`+0xdc == 0`), not on a one-way top (`+0xd0 == 0`), ground kind `+0xce` not
  4/7/0x13/0x14, and not moving **uphill** (vx ≤ 0 excludes kinds 0xc, 0x20, 0x21, 0x2c, 0x2d,
  0x32..0x35; vx > 0 excludes 0xf, 0x22, 0x23, 0x2e, 0x2f, 0x36..0x39): `y(24.8) += |vx|` —
  the sprite is pressed into the floor by its horizontal speed every frame, so tile separation
  keeps it glued to down-slopes instead of launching off them.
- Riding a sloped top (`+0xd6 ≠ 0`): `d = |vx·slope| >> 8`; against the slope sign `y −= d`
  (uncapped), with it `y += min(d, 0x800)`. Returns the applied delta.

### 8.5 Programmed paths (`.SetupProgrammedPath @ 10044c58`, `.HandleProgrammedPath @ 10044fe8`; Background, Bat, Gremlin)  [HIGH arithmetic]
Mode `m = |param1|` (`+0xf0`; 100..199 → m − 100 and the radial start phase is dropped
— ⚑ corrected (deepening 2026-10-03): it is the radial **speed** that is dropped, see m = 10/11);
speed `+0xfc = param3`.
- m = 1 vertical shuttle: bounds `+0x100 = y + 8·speed`, `+0x104 = y + 256·param2 − 8·speed`
  (24.8; param2 = travel in px); `vy = speed`, `+0x13a = 0`. m = 2: the same on x, `vx = speed`.
  Per frame: direction `+0xf8 = +1`: past `+0x104` → −1, else `v += speed>>4` then clamp
  `v ≤ speed`; direction −1 mirrored against `+0x100`. (Ease-in at 1/16 of speed per frame,
  reversal at the bounds; the 8·speed margin absorbs the turn-around overshoot [MED purpose].)
- m = 3 floater (a path mode, unrelated to the Floater enemy class — enemies-flyers corr. 5): hot rect `SetRect(7,0,0x46,0x1e)`, buoyancy `+0x19e = 0x50`, gravity 0x15e,
  `+0x13a = 0x2d`, `+0x138 = 0x3c`; moved by §8.6 in water.
- m = 10/11 circular: `.MakeRadial(s, cx, cy, radius = param2, ~~phase = param3, speed = param4~~,
  0 | 0x1e, …)`, optional spokes `.MakeRadiusSprites(s, param2/14, …)`; per frame `vx = vy = 0`,
  `.UpdateRadialPos`, `.UpdateRadiusSprites(s,0,0)` (radial geometry NOT RESOLVED).
  ⚑ corrected (deepening 2026-10-03): **param3 = angular speed** (1/256 °/frame; 0 for the 1xx form), **param4 = start
  angle** (°); the `0x1e` is the pendulum pull, so **m = 11 is a pendulum** hanging at 270°; the
  spokes branch is never taken (every caller passes spoke type −1). Raw: `.MakeRadial`
  `1003d730/1003d734` (r7 → r25 → R+0x14, r8 → r26 → R+0x18 ·256), caller `10062508..1006254c`
  (p3 → r7, p4 → r8). Radial geometry, tables, wheels, wall bounce: platforms-ropes-radial §1;
  m = 10/11 for Background maces: triggers-background corr. (physics §8.5 row).
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
`+0x19e` at 6 sites — not traced [NOT RESOLVED]. ⚑ corrected (deepening 2026-10-03): 3 stores + 3 loads; the stores are in
the death/revive sequence — the body floats (platforms-ropes-radial §5, player-states §3.2).

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
0x578 set by type. ⚑ corrected (deepening 2026-10-03): the 1xx form drops the radial **speed** (and pins a wheel's hub);
**every platform is one-way by default**; 0x57d (1405) is a damaging platform (hurts from below,
enemy-shots-and-damage §3.2); 0x582/0x583 with p1 = 2 are not solid to the player; types
0x586..0x58b and 0x58f..0x595 have no arm (face index past the set). Per-type table, census and
visual-stage fields `+0x88`/`+0xb8`: platforms-ropes-radial §2.1–§2.9.

| mode | setup | per frame |
|---|---|---|
| 1 / 2 | vertical / horizontal shuttle exactly as §8.5 (bounds `+0x150/+0x154`, initial offset param4·256, `vy`/`vx = speed`); mode 1 `+0x13a = 0` | §8.5 shuttle rule (direction in `+0xa6`); mode 2 also springs back to its record y: when sagged below it, `vy > 0` → `vy >>= 1` and once ≤ 0x80 it becomes −0x80, else `vy −= 0x40` down to −0x180; above it y snaps to the record y |
| 5 / 6, 7 / 8 | → 1 / 2 with `+0x13a = 0`, `+0x15c = 1` (7/8 also `+0x158 = 1`) | not ridden → velocity × 0.4 per frame (`dRam100a1a70` = 0.4); ridden → shuttle; 5/6 move only while ridden, 7/8 keep `+0x186` once ridden (run on) |
| 3 | raft: rect `(6,5,0x4c,0x1e)`, buoyancy 0x50, gravity 0x15e, `+0x13a = 0x2d`, `+0x138 = 0x3c` | gravity only when not in water; tilt: rider dx/5 (sign-inverted) as a target, `+0x46` eases ±2/frame, `+0x1aa` = angle mod 360; friction 100 |
| 4 | ice floe [MED: the Ice-Wall link is inferred from the spell's 0x57c spawn and the melt timer; who sets mode 4 on a code-spawned floe was not traced] ⚑ HIGH: the Ice Wall shot code writes `+0xb0 = 4`, `+0xa6 = 0xb4` after `MTNewSprite`; `+0x16c` 1/2 = wall ledges (spells-detail §3.4, platforms-ropes-radial §2.4): `+0x16c == 0` → rect `(0,0,0x28,0x31)`, gravity 0x15e, `+0x13a = 0x16`, buoyancy 0x3c, float offset 10; else rect `(0,3,0x28,0x18)`, no gravity; `+0x138 = 0x3c` | gravity when not in water; friction 100; lifetime `+0xa6` counts down, flashes below 0x2d, at 0 explodes into particles and dies |
| 10 / 11 | single circular platform: `.MakeRadial(s, x+0x28, y+0x14, r = param2, ~~phase = param3, speed = param4~~ ⚑ speed = param3, start angle = param4, 0 / 0x1e)` (11 = pendulum, §8.5); spokes `param2/14` of type 0x596 | `vx = vy = 0`; `.UpdateRadialPos`; no tile collision |
| 20 / 21 / 22 | wheel of 3 / 2 / 4 platforms (two/one/three extra `MTNewSprite`s) at 0/120/240, 0/180, 0/90/180/270°; spokes `param2/12` (20) or `/14` | turns only while ridden: `.RadialWheelStep(s, 0x100)`; siblings' angle = own + 0x7800/0xf000, 0xb400, 0x5a00/0xb400/0x10e00 (degrees·256) — ⚑ plus 0xf7/256 speed damping, a rolling hub (`hvx = −speed`) and a wall bounce (`.BounceRadial`) (platforms-ropes-radial §1.5, §1.6, §2.7) |
| 30 | pair at 0/180° with chain spokes (type 0x59b, `param2/16`), `+0x150 = 0` | ridden → `.RadialWheelStep(s, +0x150)`; free → angular speed (`+0x198 → +0x14`) drifts ±0x18/frame back toward the hanging angle (balance swing) — ⚑ a **see-saw**: 0x59b are the rideable segments, the arm is limited to ±45° (bounce 0x60/256), the ridden segment sets the lever `+0x150 = (n−k−1)·256/n`, free it drifts back to **level** (0°/180°); the arm has an empty rect and no face (platforms-ropes-radial §2.3, triggers-background-2 §1) |
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
read [NOT RESOLVED]. ⚑ corrected (deepening 2026-10-03): `.HitPlatformSprite` and `.HitPlatformTileSprite`:
platforms-ropes-radial §2.6, §2.7; walker corpse 0x6a4 as a platform: §2.5.
