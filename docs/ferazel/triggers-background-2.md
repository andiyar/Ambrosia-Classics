# Ferazel's Wand 1.0.3 — chains, see-saws, effects, timer digits, parallax sprites (part 2 of 2)

Code readings only; nothing behaviour-verified.

Date 2026-10-03. Sources, conventions and labels as part 1 (`triggers-background.md`). Scope of
this part: `.SetupChainSprite .HandleChainSprite .HitChainTileSprite .SetupSeeSawSegSprite
.HandleSeeSawSegSprite`; `.SetupEffectSprite .HandleEffectSprite .HitEffectSprite
.HitEffectTileSprite .HandleGeyserSegSprite`; `.SetupDigitSprite .anon_10060c78` (+
`.UpdateDigits`); `.SetupPxSprite .HandlePxSprite` (+ `.MTAddPxSprite`). Then the consolidated
NOT RESOLVED list, proposed physics §0 rows and corrections for both parts.

## 1. Chain links and see-saw segments  [HIGH arithmetic unless noted]

None of these types is placed in a level; they are spawned by `.MakeRadiusSprites @ 1003d854`
for a radial parent (Background 1480..1489, part 1 §2.5; Platform class via
`.DoSetupPlatformSprite`, Platform reader). `.MakeRadiusSprites(parent, n, layer, type, spacing,
setup)`: n ≤ 24 links, stored at radial record R+0x44.. (R = `parent+0x198`), each link
`+0x1d4 = parent`, `+0x14c = i`, `+0x150 = n`, `+0x154 = radius`. `.UpdateRadiusSprites @ 1003da00`
places link i (0..n−1) at `centre + (i/n)·r·(cos θ, −sin θ) − spacing/2` (spacing R+0x34) and
writes the link's `+0xb0 = θ` (flat) or `−90` plus an interpolated scale `+0x1ae` and shade
`+0xb8` (depth modes) [HIGH for the writes; MED for "shade"].

| type | PICT (Sprites) | setup / handle | rect | per frame |
|---|---|---|---|---|
| 1430 (0x596) | 1433 (160×96 = 60 cells 16×16) | `.SetupChainSprite` / `.HandleChainSprite` | (0,0,16,16) | face = `+0xb0 / 6` (0..59; ≥ 60 → 0, < 0 → 59), `+0x88 = 1` |
| 1434 (0x59a) | 1434 (24×24) | same | (0,0,24,24) | rotation `+0x1aa = (+0xb0 + 90) mod 360`; layer = `+0x1ae − 256`; lit (`+0x89 = 1`) when scale == 0x100 |
| 1436 (0x59c) | 1436 (24×24) | same | (0,0,16,16) | as 1434 without the lit test |
| 1435 (0x59b) | 1435 (24×1080 = 45 cells 24×24) | `.SetupSeeSawSegSprite` / `.HandleSeeSawSegSprite` | (0,0,24,88) | below |

Chains (`.SetupChainSprite @ 100652c0`, handler dump l. 9306–9323; `.HandleChainSprite @
10065374`, l. 9325–9377) have no hit callback and do **not** call `.StandardSpriteHandles` — no
physics, no collision; their tile callback `.HitChainTileSprite @ 10065798` (l. 9468–9482) only
runs `.HandleUnderWater` on water tiles. Users: Background 1480..1488 (types 1434, or 1436 in
mode 14, spacing 24); platforms (1430 with spacing 16, count p2/14) [HIGH for the Background
call, l. 14301–14365].

See-saw segment (`.SetupSeeSawSegSprite @ 10065508`, l. 9380–9404; `.HandleSeeSawSegSprite @
100655c8`, l. 9406–9466): one-way top (`+0x185 = 1`), no hit callback, tile callback as chains,
`+0xd2 = +0xd4 = 87`. Per frame: fold the angle a = `+0xb0` (a > 180 → 360 − a, mirror; a > 89 →
179 − a, toggle mirror) → face `a/2` (0..44), `+0x17e` = mirror. If ridden (`+0x186`) and
`+0xb2 == 1`: the ride flag moves to the parent (`+0x1d4`) and the parent's
`+0x150 = ((n − (i+1))·256)/n` — the rider's lever position along the arm. When the folded angle
is ≥ 6° the segment is tile-separated with its rect bottom temporarily `max(88 − +0xd2,
88 − +0xd4) + 8` (`+0xd2/+0xd4` rewritten by `.UpdateRadiusSprites(parent, 1, y)`). The see-saw
physics itself (platform mode 30 in `.DoSetupPlatformSprite`, two arms at θ 0 and 180) is
Platform-class. Limits are written into the radial block after `.MakeRadial`: record arm
`+0x2c = 0x2d` (45°), `+0x2e = 0x13b` (315°); sibling arm `+0x2c = 0xe1` (225°), `+0x2e = 0x87` (135°);
bounce `+0x30 = 0x60` on both [HIGH: raw 1006308c–100630ec] — same as platforms-ropes-radial.md §1.8.
⚑ corrected (review 1b, 2026-10-03) #10 (only the sibling pair was cited before).

## 2. Effect class (`.SetupEffectSprite @ 10060680`, `.HandleEffectSprite @ 10061160`)

Code: handler dump l. 7830–8004 (Setup), 8042–8303 (Handle), 8305–8312 (`.HitEffectSprite` —
empty), 8314–8345 (`.HitEffectTileSprite`); faces `.InitEffectSprite @ 10060378` (main
l. 45811–45858). Effects are spawned by code (`MTNewSprite(id, x, y, layer, −1, SetupEffect)`;
the TOC slot of `.SetupEffectSprite` is 0x1009fef8, referenced by 16 functions,
`tools/tocrefs.py 1009fef8`). The `type → Effect` arm of `.GenerateSprite` (type 1830) is dead
(world-data §3.5), so **no effect is placed in a level** [HIGH].

### 2.1 Common Setup  [HIGH]
Layer 11, Handle `.HandleEffectSprite` (TOC 0x100a0460), hit `.HitEffectSprite` (no-op), tile hit
`.HitEffectTileSprite`, rect (16,16,32,32), `+0xa6 = 3`, face 0, `+0xe4 = 1`, `+0x13e = 0`.
**Explosion package** — every id except 1201..1206, 1220, 1040, 1430, 1251, 1210, 3099, 1440,
1435, 1830 and ids ≥ 3200: 45 particles `NewParticle(kind, 150, centre, 1 + rand 2, rand(2000) −
1000, rand(2000) − 1000, 0, 1)` with kind 4 for ids 5 and 1090, 9 for id 2, else 1 (centre
(x+16, y+24); big explosion (x+32, y+48)); then a smoke plume (id 1206) 90 px above if prefs+0x06
== 1 and fewer than 3 plumes exist (not for 1207, 1090, −1); then a light
(`.AddLight(light face PICT 813, centre, …, 0x16)` → `+0x9a`) unless id 1090 [HIGH reading;
MED for the `NewParticle` argument names; prefs+0x06 = the detail popup of engine §8, so plumes
are a high-detail feature, MED].

`.HitEffectTileSprite` (param 4 = tile layer class [MED]): class 1 and id 3099 → `.WallBounce(…,
0x80, …, 0x80)`, `+0x16c` += 1 per bounce; class 0 and a water tile → `.HandleUnderWater`; class
2 and `+0xeb ≠ 0` → `.CrunchTile` (breaks crunchable foreground tiles).

### 2.2 Effect id table  [HIGH unless noted]
Faces are PICTs in `Ferazel's Wand Sprites`; "life" counts `.HandleEffectSprite` frames (one per
`.GameLoop` iteration). Every effect integrates `x += vx, y += vy` after its branch.

| id | PICT / cells | life and look | special | spawned by |
|---|---|---|---|---|
| 0 | 1200 'explosion' 13×(48×48) | 26 frames, face `n>>1`, untinted | explosion package; light schedule (below) | `.KillPlayerShot` (spell-shot death puff), `.KillEnemyShot` (enemy shot 1810) |
| 1..15 | 1200 | as 0, draw effect `0x10000 + id` (tinted explosion) | id 2: particle kind 9; id 5: kind 4 | 2: `.HitPlayerShotSprite`, `.HitPlayerShotTileSprite`, `.KillPlayerShot` (shot id 4); 5: `.KillPlayerShot` default, `.HandlePlayerShotSprite` |
| 1040 (0x410) | 1040 'bubble' 4×(8×8) | loops faces `n>>1` (8-frame cycle); vy = −500 (−1.95 px/frame); dies (light removed) once `+0x11c == 0` (out of water) | rect (0,−10,8,−2) | `.EmitBubble` |
| 1090 (0x442) | 1200 | 26 frames, draw effect 0x10005; layer 32700 | particles kind 4, no light, no plume | `.HandleCannonedSprite` (×3 per shot), `.KillPlayerShot` and `.KillEnemyShot` (bomb debris, rand start frame 0..6), `.KillCrate` |
| 1201 (0x4b1) | 1201 'dust cloud' 6×(56×8) | 6 frames then killed | — | `.CheckGroundCeilingHitEffects` (landing, physics §8.7) |
| 1202..1204 | 1202 (8×20), 1203 (5×16), 1204 (4×12) | static face; killed when y > viewY + 384 | — | **no spawner found** |
| 1205 (0x4b5) | none | invisible, draw effect 0xb0004, killed after 33 frames | — | **no spawner found** |
| 1206 (0x4b6) | 1206 34×(64×116) | 34 frames, draw effect 0xb0004, then plume counter −1 | smoke plume | the explosion package |
| 1207 (0x4b7) | 1207 'big explosion' 13×(96×96) | 26 frames, gravity + tile separation | rect (8,8,88,88), `+0xeb = 2` (crunches tiles); **hurts the player** while frame ≤ 7 (below) | `.KillPlayerShot` (shot id 90), `.KillEnemyShot` (enemy shots 1762, 1875), `.KillCrate` (explosive crate, p1 == 2), `.HandleXichraSprite` |
| 1210 (0x4ba) | 1210 'crumble overlay' 3×(32×32) | tile-crumble overlay (§2.3) | layer 50 | `.MakeCrunchSprite` (from `.CrunchTile`) |
| 1220 (0x4c4) | 1220 11×(24×24) | countdown display (§3) | layer 0x7fff; owns six 1221 digit sprites | `.GameLoop` (once per level) |
| 1251 (0x4e3) | 1251 6×(36×36) | 12 frames, face `n>>1` | — | **no spawner found** |
| 1440 (0x5a0) | faces set by the column from the Box geyser sheet (`_DAT_100a0a14`) | geyser column segment: handler `.HandleGeyserSegSprite` (empty — the column moves it), no hit/tile callbacks, rect (4,24,16,32), layer 1 | hurts like a liquid of kind `+0x14c` (below) | `.HandleGeyserColumn @ 1006cf7c` (Box class) |
| 1830 (0x726) | light face PICT 830 (64×16) | stationary light, colour = record p1 | — | `.GenerateSprite` arm (dead) |
| 3099 (0xc1b) | 3099 16×(24×24), 8 per row | 8-frame loop, variant row 2 if `+0x14c` (51 %); gravity 0x5a plus tile gravity; killed after 4 tile bounces; with prefs+0x06 == 1 fades by bounces (0 → none, 1 → 0xb0001, 2 → 0xb0000, ≥ 3 → 0xb0002) | rect (10,10,14,14) | `.KillCrate` (16 debris, 4×4 grid, speed 650..799 away from the crate centre, vy −(1400 − rand 600)) |
| 3201 (0xc81) | 1200 | as id 0 but no particles/light (id ≥ 3200) | — | `.KillCrate` for crate type 3092 |
| 3250 (0xcb2) / 3250+n | balloon face (`_DAT_100a0a90`) / item icon PICT 3200+n | no animation (id ≥ 3250 skips every branch) | layers 100 / 101 | `.CreateBalloonSprite` (Box class thought balloon, n = 1..26) |
| −1 | 1200 | 26 frames; light added by Setup but never stepped | — | none found |

Light schedule for the 26-frame explosions (`PTR_DAT_100a088c` = light PICTs 810..813, 72×72):
start 813; frame 2 → 812, 4 → 811, 6 → 810, 14 → 811, 17 → 812, 20 → 813, 23 → removed —
the glow swells and fades [HIGH].

**Effect damage** (`.HitPlayerSprite` l. 4473–4500): (a) id 1207 (handler Effect) while
`+0x46 ≤ 7`; (b) ~~**any**~~ any **non-Box** sprite of type 1440 with `+0x14c ≥ 1` — geyser segments copy `+0x14c`
from their column. ⚑ corrected (review 1c, 2026-10-03) (adjudication A2; synthesis ledger A2): the Box/SeeSaw arm of `.HitPlayerSprite` (`10056b2c..10057860`, entered at `10056b18` on TOC −0x73bc / −0x7678) leaves by 25 branches, all to the epilogue `1005855c`; this hazard arm (`10058458..10058494`) is entered only from `10057e00` on the non-Box path, so a Box-class 1440
never reaches the test (enemy-shots-and-damage §3.4 was right) [HIGH]. Damage `0x70`, or `0x150` when `+0x14c == 2`; skipped for kind 1 if the
walk-on power-up 1 is active, for kind 2 if power-up 2 is active or the Fire Charm (item 0x18)
is held; then `HurtSprite(player, dmg, ±300 (away), −0x640, 0x3c, 12)` and hurt-stun
`_DAT_100a0748 = 1` — **no coin loss** (HurtSprite, not HurtPlayer) [HIGH].

### 2.3 Crumble overlay 1210  [HIGH writes; MED for the caller's protocol]
`.MakeCrunchSprite @ 1004481c (tx, ty, hp)`: effect 1210 at `(tx·32+16, ty·32+16)` layer 50,
`+0xa4 = +0x14c = hp`, `+0x154 = tx`, `+0x158 = ty`, registered in a 40-slot table at 0x100a53d8
(`+0x150` = slot; full → the slot-0 sprite is killed and replaced). `.CrunchTile @ 10044928`
creates it with hp 2 and sets `+0x15c` (tile kind) and the arming fields. Per frame: `+0x46`
delay counts down; when `+0x16c == 1` and `+0x46 == 0`, hp −= 1; face = `+0x14c − hp` (0..2,
otherwise `ReportError("Crunch sprite face out of range")`). At hp < 1: killed, slot freed; if
hp == 0 and armed: snd 424 'rock crush', `.DestroyCrunchTile(tx, ty, +0x15c, 1, 1, 0)` and the
tile is logged in the game globals (count `G+0xad6` < 20000: `G+0x12d8+n` = level byte,
`G+0x60f8+4n` = ty, `G+0x60fa+4n` = tx) for re-application on revisits (engine §9).

## 3. Countdown timer and digit sprites  [HIGH]

Clock `iRam100a5110` (frames). `.GameLoop` (main l. 5149–5151) spawns effect 1220 once per level
start (layer 800) and sets the clock to −30; every loop iteration `if (clock > −30) clock −= 1`
(l. 5202). Start: Box trigger 2907 (`.HitPlayerSprite` l. 3982–3986) when its `+0xa6 == 0`:
`+0xa6 = 100`, snd 442 'drown warning' pitched 44000, **clock = p1·30 − 1**. One shipped use:
level 40 rec 209, p1 = 300 (5:00), driving the p1 = −2 gate (part 1 §1, open while clock > −20).
(Debug key code 0x78 subtracts 30 while > 0 — `.HandleKeys` l. 44262, out of scope.)

Display (`.UpdateDigits @ 10060d04`, main l. 45860–45982; Setup of 1220 allocates a 0x1c-byte
block at `+0x9c` holding six effect sprites of id 1221 created with `.SetupDigitSprite @
10060c0c` — layer 0x7fff, handler `.anon_10060c78` = `.StandardSpriteHandles` + cleanup only):
- clock < −29 → all seven faces hidden. Otherwise t = max(0, clock + 29); s = t/30;
  minutes m = min(9, s/60), s mod 60; sub = (t mod 30)·2.
- Positions (all at view top + 10): x = viewX + 12 (+0 minutes, the 1220 sprite), +15 ':',
  +30 tens of s, +51 units of s, +66 ':', +81 tens of sub, +102 units of sub. Faces from PICT
  1220 (24×24 cells 0..9, cell 10 = ':'). Draw effects cleared every frame.
- When the clock is a whole multiple of 30: tick sound — snd 429 'Tick 2' if the units digit is
  even, else snd 428 'Tick 1' (vol 0x46, pitch 80000).

So the readout is M:SS:ff where ff counts 0..58 in steps of 2 (half-frames per second at 30
fps) [HIGH arithmetic; "ff" naming LOW].

## 4. Parallax strip sprites (`Px`)  [HIGH arithmetic]

Code: `.MTAddPxSprite @ 1003359c` (main l. 30769–30842), `.SetupPxSprite @ 10033418` /
`.HandlePxSprite @ 10033378` (handler dump l. 37–80), `.MTHandlePxSprites @ 10033798`,
`.MTKillPxSprites @ 100334b8`. Not pixel effects: a horizon strip drawn as sprites.
- `.SetupLevel` (main l. 2252–2268), when `hdr+0x2716 ≠ 0`, opens `Ferazel's Wand Backgrounds`
  and calls `.MTAddPxSprite(hdr+0x2716 PICT id, hdr+0x2718 x-factor, hdr+0x271a y)` [the
  enclosing condition `*psVar6 == _DAT_100a267e && !DAT_100a267d` not decoded].
- One face is loaded (sprite CLUT if `hdr+0x26cc`); copies k = 0..N with
  `N = ⌊((fx·W·32) >> 8) / 768⌋ + 1` (W = `hdr+0xb280` tiles), capped at 31 sprites total, each
  `MTNewSprite(0, 0, 0, layer −500, −1, .SetupPxSprite)` with `+0x14c = 768·k`, `+0x150 = y`,
  `+0x154 = fx`, `+0x158 = hdr+0xb26c` (the PxBack y factor).
- Setup: empty rect, `+0x48 = 0x1ff`, `+0xea = 1`, type forced to 1, no callbacks, draw effect
  0x80000.
- Handle: `x = x0 − (viewX·fx >> 8) + viewX`, `y = y0 − (viewY·fy >> 8) + viewY + 232` — on-screen
  the strip moves at fx/256 and fy/256 of the camera.

| level | PICT (Backgrounds, 768 wide) | fx | y | fy (`b26c`) |
|---|---|---|---|---|
| 10 | 265 (768×30) | 128 | 222 | 56 |
| 30 | 275 (768×44) | 128 | 227 | 136 |
| 40, 45 | 315 (768×33) | 128 | 48 | 22, 10 |
| 62 | 345 (768×46) | 128 | 116 | 43 |
| 67 | 385 (768×60) | 128 | 16 | 256 |
| others | none (0x2716 = 0) | | | |

## 5. NOT RESOLVED (both parts)
1. Meaning of `s+0xb8` draw-effect modes (0x1 tint, 0x3/0x4 hurt flash, 0x8, 0x9, 0xb, 0xc
   lighting…) — readers in `.WrapDrawSprites` not decoded; tint ids 4/0xb/0xf/0x17/0x18 unnamed.
2. Cannon re-entry: who brings a launched sprite's `s+0x130` back to ≥ 0; meaning of cannon
   `s+0x154 = 6`; identity of sprite type 90 (gets gravity 0x15e after launch).
3. Passage counter `*_DAT_100a06f0` recovery from −22, `_DAT_100a05f8` (1 / −15),
   `_DAT_100a0680`; `PTR_DAT_100a05f0 = 3` on spike contact.
4. Spawners of effects 1202..1205, 1251 and −1 (none via the `.SetupEffectSprite` TOC slot —
   could be passed in by a caller through a register).
5. `.NewParticle` argument meanings; particle kinds 1/4/9 and geyser kinds 200+.
6. Button types 1323..1329 hot-rect source (allocator state) — moot for the shipped data.
7. Gate linkage completeness: only `* 0x10 + 0xe` read patterns were searched.
8. Type 2940 with p1 = 0 reading record 0 — designer intent (permanently shut doors?). 2941 is out of
   this question: it never opens and is destroyed by damage-300 player hits (part 1 §1, raw
   1006f568–1006f5a8). ⚑ corrected (review 1b, 2026-10-03) #2.
9. Exact `.HandleIdleSprites` activation rule for idle Background sprites (margins `+0x1c8..`
   apply to deactivation only; activation uses the idle entry's own margins).
10. Wind orientation (physics §6) — not settleable here: no sprite emits wind.
11. ~~`s+0x88` (set 0/1 by many Setups; read sites not traced).~~ Closed: light-overlay gate, sole
    reader `.WrapDrawSprites` `1001493c` (physics §0.1) ⚑ corrected (review 1c, 2026-10-03) #5.

## 6. Proposed additions to physics.md §0

| off | type | meaning (writer/reader) |
|---|---|---|
| +0x46 | i16 | (extends the row) button press level 0..11; spring cooldown = face 0..3; cannon aim in 1/32 turns; spike frame 0..11; arrow-trap state 0..19; sword angle °; effect frame counter |
| +0x89 | u8 | lit by the light map: `.WrapDrawSprites` calls `GetLightTile`/`GetFakeLight` and writes `+0xb8 = 0xc0000 + …` (main l. 10282–10297) |
| +0x9a | i16 | light id (`.AddLight` / `.ChangeLightFace` / `.RemoveLight`; −1 none) |
| +0x9c | ptr | per-sprite allocated block (timer: six digit sprites) |
| +0xa0 | i32 | previous frame's `+0x46` (button release sound) |
| +0xb0 | i16 | radial angle (°) written into chain/see-saw links by `.UpdateRadiusSprites`; Background 1480.. mode |
| +0xb8 / +0xbc | i32 | draw effect `mode<<16 | arg` (Setups; read by `.WrapDrawSprites` l. 10246; hurt flash overrides with 3/4) / last frame's copy |
| +0xc0 | ptr | current face record (`+6` = face width) |
| +0xe4 | u8 | first-frame-done flag (button) |
| +0xeb | u8 | crunches tiles on tile contact (big explosion = 2) |
| +0x130 | i32 | cannon hold timer while cannoned; negative after launch = cannon re-entry block |
| +0x14c..+0x16c | i32 | per-class scratch (cannon home x/y, speeds, pause, launch speed `+0x164`, in-water `+0x16c`; spike p1..p3; cloud factors; effect bounce count `+0x16c`; crunch hp base/slot/tile) |
| +0x170 | i32 | (Background 1480..) harmful flag — distinct from the player-shot power at the same offset |
| +0x17c | u8 | tree branches built |
| +0x187 / +0x198 | u8 / ptr | radial record allocated / radial record R (0xa4 B, part 1 §2.5) |
| +0x1aa | i16 | draw rotation in degrees (copied to the face's +0x1a) |
| +0x1ae | i16 | draw scale, 0x100 = 1.0 (InitSprite) |
| +0x1b6 / +0x1b8 | i16 | left-skip columns / ~~visible width~~ **right edge** (face-local px); reset to 0 / 32000 by `.StandardSpriteHandles` each frame — ⚑ corrected (review 1c, 2026-10-03) #6 (adjudication A10): edges, not extents; `.WrapDrawSprites` `1001461c..10014684` draws cols `min(+0x1b8, w) − +0x1b6`, rows `min(+0x1ba, h) − +0x1bc` (physics §0.1) |
| +0x1ba / +0x1bc | i16 | ~~visible height~~ **bottom edge** (InitSprite 32000) / top-skip rows (⚑ corrected (review 1c, 2026-10-03) #6) |
| +0x1be / +0x1c0 / +0x1c2 / +0x1c4 | i16 | wall-tunnel window xmin / xmax / ymax / ymin (InitSprite 32000) — ⚑ corrected (review 1c, 2026-10-03) #7 (adjudication A11): order confirmed, raw `10036f20..10036f58` [HIGH] |
| +0x1c6 | u8 | may go idle off-screen (InitSprite 1) |
| +0x1c8 / +0x1ca / +0x1cc / +0x1ce | i16 | idle-test margins left / right / top / bottom (`.HandleIdleSprites` main l. 4302–4316) |
| +0x1d4..+0x1e0 | ptr | linked sprites (radial parent, see-saw twin, tree branches, balloon) |
| +0x1e4 | ptr | the cannon this sprite is loaded in |
| +0x1ec / +0x1f0 / +0x1f4 | proc | saved Handle / hit / tile-hit while cannoned |

## 7. Corrections to the existing bank

| file § | old reading | new reading | evidence |
|---|---|---|---|
| physics §8.3 | excluded hitter class `PTR_PTR_100a0460` unidentified; cooldown decrement not traced | `PTR_PTR_100a0460` → `.HandleEffectSprite` (effects never trigger springs); `.HandleBackgroundSprite` decrements `+0x46` 1/frame clamped 0..3 and uses it as the face → 4-frame cooldown | TOC 0x100a0460 → TV 0x100a229c → 0x10061160; handler dump l. 14805–14834 |
| physics §8.3 | 1154..1159: "sound only" | inert: no Setup branch (no rect, face or hit callback), no Handle branch; none placed | l. 13958–14160 type tree |
| physics §8.5 | m = 10/11: `.MakeRadial(s, cx, cy, radius = param2, phase = param3, speed = param4, 0 \| 0x1e, …)` | param3 → R+0x14 = **angular speed** (1/256 °/frame; dropped for 110/111), param4 → R+0x18 = **start angle** (°); the 0x1e is R+0x36 = pendulum pull → **m = 11 is a pendulum** hanging at 270° (angles: 90° up, tables cos / −sin) | `.MakeRadial @ 1003d718` field writes; `.UpdateRadialPos` R+0x18 += R+0x14; `.FindUpdatedRadialSpeed`; `neg r0,r0 @ 1003d6a4` |
| physics §5.1 | "lava/acid pools (Box class 0x5a0, mode s+0x14c 1/2)" | the same branch hits for any **non-Box** sprite of type 1440 with `+0x14c ≥ 1` (⚑ corrected (review 1c, 2026-10-03) (adjudication A2): the Box arm returns first, raw `10056b2c..10057860` → `1005855c`; hazard arm only from `10057e00`) — i.e. the Effect-class geyser segments that copy `+0x14c` from the geyser column; damage via `HurtSprite` (no coins); also effect 1207 hurts 0x70 while frame ≤ 7 | `.HitPlayerSprite` l. 4473–4500; `.HandleGeyserColumn` main l. 47594 (`+0x14c` copy) ~~[MED that the Box 1440 itself is a pool]~~ [HIGH] |
| physics §5.1 | fire −0xe0 unless Fire Charm | unless Fire Charm **and** the fire's p1 ≤ 0 (tinted fires p1 1..4 ignore the charm) | l. 4285–4289 |
| world-data §3.2 | 0x2716/18/1a "parallax sprite: PICT id, ?, ?" | PICT id in the Backgrounds file / x-parallax factor (/256) / base y (+232) of a 768-px strip tiled across the level | part 2 §4 |
| any synthesis text (INDEX, physics) that carries 2941 with the 2940 switch rule (physics §0 `+0x1b4` row already names the 2941 ice wall correctly) | 2941 = switch gate wired like 2940, open ⇔ `rec(p1).p4 == 1` | 2941 = destructible weakened ice wall: open flag forced 0, −0x50 HP per player shot with `+0xa4 == 300`, invul 10, explodes at HP < 1 (review 1b #2) | raw 1006f568–1006f5a8; handler l. 5665–5672 |
| world-data §3.4 | NOT RESOLVED 1 (params) for Background/Button | resolved per type in part 1; record byte +1 is 0 in every Background/Button record and unread | census + Setup reads |
| world-data §3.5 | Background ranges 1090..1099, 1855..1859, 2700..2799, 2890..2899, 3000..3019 | Setup handles only 1090..1098, 1855..1856, 2700..2729 (faces), 2890..2893 (faces), 3000..3009; the rest are inert | part 1 §2.1 |
| engine §9 / NOT-RESOLVED 14 | crunch pair "(y,x)" rests on unread callee arg order | confirmed: `.CrunchTile` unpacks a QuickDraw Point (h low, v high) and calls `GetFGCrunchDirTile(h>>5, v>>5)`; `.MakeCrunchSprite(tx, ty)` places at `(tx·32+16, …)` via `MTNewSprite(type, x, y)`; the log writes `G+0x60fa ← tx`, `G+0x60f8 ← ty` → pair = (y at +0x60f8, x at +0x60fa) [HIGH] | main l. 38976–38982 (`.CrunchTile`), 38911–38950 (`.MakeCrunchSprite`); handler dump l. 8132–8133 |
| INDEX NOT-RESOLVED 14 | radial geometry; spring cooldown; excluded class | radial record layout and tables resolved (part 1 §2.5); cooldown and class resolved (above); `.RadialWheelStep`, `.BounceRadial` remain | — |
