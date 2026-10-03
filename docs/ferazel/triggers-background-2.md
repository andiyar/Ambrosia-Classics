# Ferazel's Wand 1.0.3 — chains, see-saws, effects, timer digits, parallax sprites (part 2 of 2)

Code readings only; nothing behaviour-verified.

Date 2026-10-03. Sources, conventions and labels as part 1 (`triggers-background.md`). Scope of
this part: `.SetupChainSprite .HandleChainSprite .HitChainTileSprite .SetupSeeSawSegSprite
.HandleSeeSawSegSprite`; `.SetupEffectSprite .HandleEffectSprite .HitEffectSprite
.HitEffectTileSprite .HandleGeyserSegSprite`; `.SetupDigitSprite .anon_10060c78` (+
`.UpdateDigits`); `.SetupPxSprite .HandlePxSprite` (+ `.MTAddPxSprite`). Then the consolidated
NOT RESOLVED list, proposed physics §0 rows and corrections for both parts. ⚑ wave 2 (2026-10-04): §8 (placed
before §5 so the file still ends with the NR / §0 / corrections sections) closes INDEX item 22.

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

## 8. Wave 2 closures (2026-10-04)  ⚑ wave 2 (2026-10-04)

Code readings only; nothing behaviour-verified. Date 2026-10-04. Sources: raw listing
`ghidra/Ferazel_pef.disasm.txt` (every HIGH below cites it), both decompile dumps, data constants and
jump tables via `tools/pef.py` (`u32`), `tools/tocrefs.py`, and Python decodes of all 24 `Mlvl`
resources of `Ferazel's Wand World Data.rsrc` (records at body `+4+16·i`; tile maps at the offsets of
world-data §3.1). These sections sit before §5 so that the file still ends with NOT RESOLVED,
proposed fields and corrections; they close INDEX item 22.

### 8.1 Cannon leftovers: `+0x154 = 6`, type 90, re-entry  [HIGH]

| question | answer | evidence |
|---|---|---|
| cannon `+0x154 = 6` | **write-only.** Setup stores 0 (`10071910 stw r26,0x154` with `r26 = 0` from `10071768`), the capture stores 6 (`10075354..10075358`, after `bl .TurnIntoCannoned`). Every load of `+0x154` in the binary (`l* rX,0x154(rY)`, 58 sites, all listed by a raw grep) is in a routine that never runs on a cannon: the four in `.HandleBackgroundSprite` are the spike in-time `p3` (`100743ec`, `10074554`) and the cloud x0 (`10074c60`, `10074c84`, arm `10074be8..10074c14` = 0xb4a..0xb4d); `.HandleCannonedSprite`/`.TurnIntoCannoned` (`10058594..10058fac`) contain none; the rest are other classes' handlers and one stack slot in `.PaintFrameWrap` | raw grep; `10071910`, `10075358` |
| sprite type 90 in `.HandleCannonedSprite` | **player-shot id 0x5a** — thrown fire / Ziridium seeds (`.HandleItemUse`) and Ring-of-Smiting blasts (`.SmiteEnemies`), both spawned as `0x5a01`; `.SetupPlayerShotSprite` splits the spawn type into `+4 = (char)(type >> 8)` and `+0x170 = type & 0xff` (handler l. 4930–4931). No other sprite has type 90: of the 181 `.MTNewSprite` sites none passes a literal 0x5a, the only `0x5a01` spawns are `.HandleItemUse` (`1004d28c`) and `.SmiteEnemies` (`10052a6c`), and no placed class range (world-data §3.5) starts below 0x41f. On launch: `if (+4 == 0x5a) +0x110 = 0x15e` (`10058da4..10058db4`) — a launched seed falls with gravity 350 instead of its own 250 (spells-detail §3.1); other captive shots keep their gravity | `10058da8 cmpwi r0,0x5a`, `10058db0 li r0,0x15e` |
| who can capture a seed | a player shot touching a cannon whose p1 is not 105/106 is captured, not killed (`1007522c cmplw r4,r3; bne 10075344` → `.TurnIntoCannoned`); the 105/106 arm kills it (`1007525c..10075268`) | `10075194..10075230` |
| re-entry block `+0x130 < 0` | `.StandardSpriteHandles` adds 1 per call while negative (`10036894..100368a4`), so a launched sprite becomes capturable again 5 frames (player, `−5`) or 35 frames (others, `−35`) after launch — counted only while its handler calls `.StandardSpriteHandles` (all class handlers do; hazard 3) | `10036894` |

### 8.2 Passage / door-transit globals  [HIGH unless noted]

All four slots were followed from every TOC load (`tocrefs.py`) through the register to every store
and load (hazard 2):

| global | writers | readers | meaning |
|---|---|---|---|
| `*_DAT_100a06f0` (i16) | 0: `.ClearPlayerVars` (`1004ab40/1004ab4c`), `.SetupPlayerSprite` (`1004b2e0..1004b2ec`); +1 per contact frame and −22 at the jump: `.HitPlayerSprite` passage arm (`10057f68..10057f78`, `100581b4..100581bc`) | `.HandlePlayerSprite` `1004e66c..1004e678` (≠ 0 → `.HandleKeys` skipped, LEFT/RIGHT bytes `0x100a0730/0734` cleared, `vx = vy = 0`, `1004e694..1004e6ac`); `1004dda4..1004ddb0` (gates the `PTR_DAT_100a06bc = 3` trail write, INDEX 26); the passage arm itself (`10057f08`, `10057f2c`, `10057f7c`) | **door-transit counter / input lock** |
| `_DAT_100a05f8` (i16) | 0: `.ClearPlayerVars` (`1004ad34`); 1: passage arm at count 0 (`10057f3c..10057f4c`); −15 at the jump (`100581a8..100581b0`); +1 per frame while ≠ 0: `.HandlePlayerSprite` (`1004fe70..1004fe80`) | `.HandlePlayerSprite` `1004fddc..1004fe6c` (state branch) | **door walk animation counter**: n > 0 walk-in face `PICT 1033[min(n>>1, 5)]` (`_DAT_100a07a0`, `1004fe18..1004fe38`), n < 0 walk-out face `PICT 1030[min(|n|>>2, 2)]` (`_DAT_100a07ac`, `1004fe40..1004fe6c`); stops at 0 |
| `_DAT_100a0680` (i32, 24.8 px) | 0: `.ClearPlayerVars` (`1004ac24`), `.SetupPlayerSprite` (`1004af4c..1004af60`), passage arm at counts 21 (`10057f8c..10057f94`) and 22 (`10057fd4..10057fdc`); update in `.HandlePlayerSprite` through `r24` (loaded `1004d628`): `10051494..1005158c`, just before `bl .PlayerScroll` (`10051594`) | `.PlayerScroll` `1004c530/1004c574..1004c58c`: focus x = `playerX + (L >> 8)` | **camera horizontal look-ahead L** — rule below |
| `PTR_DAT_100a05f0` (i16) | 0: `.ClearPlayerVars` (`1004ad44`); 3: `.HitPlayerSprite` on Background 0x730..0x733 contact (`100583c8..100583dc`, with climb `_DAT_100a0758 = 0`); −1/frame to 0: `.HandlePlayerSprite` (`1004de9c..1004deb4`) | `.HitPlayerTileSprite` `10054f24..10054f30` (cling start requires 0) | **no-cling timer** (spike contact knocks the player off a wall for 3 frames) — confirms player-states §2 |

**Look-ahead rule** (`10051494..1005158c`, vx = player `+0x24`, F = facing `_DAT_100a5f5a`, 1 left / 2
right): vx > 0x100 → L += vx>>2, and again if L is still < 0 (double rate while swinging back), cap
+0x5000 (80 px); vx < −0x100 → mirror, floor −0x5000; otherwise (|vx| ≤ 0x100) F == 1 and L > 0 → L −=
0x200; F == 2 and L < 0 → L += 0x200 (both arms also clear byte `0x100a5114`, which the preceding code
sets to 1 every frame, `10051488..10051490`; its reader is camera code — NR 12). So while slow the
look-ahead only decays when it points against the facing (it may overshoot zero by < 0x200).

**Passage timeline** (one contact per frame; part 1 §2.11):

| frame of contact | counter `06f0` | `05f8` | event |
|---|---|---|---|
| 1 (UP required, `10057f18..10057f28`) | 0 → 1 | 1 | gamma fade-out 20 steps (`.GammaFadeOutAsync(0x14, …)`, `10057f50..10057f60`) |
| 2..20 | 2..20 | 2..20 (+1 per frame) | player frozen (input lock, v = 0) |
| 21 | 21 | 21 | look-ahead L = 0 |
| 22 | 22 → **−22** | 22 → **−15** | L = 0; p2 darkness rule; player moved to the idle-table entry whose `+0xe` equals rec(self).p1, keeping the offset (`10058038..10058180`, all 511 entries scanned, no early exit); `.HandleIdleSprites`, `.WrapDrawSprites`, `.RedrawEntireScrollGrid`, fade-in (`10058184..100581a0`) |
| next 15 frames | −21..−7 | −14..0 | walk-out faces; `05f8` stops at 0 |
| next 7 frames | −6..0 | 0 | still locked, standing face |
| — | 0 | 0 | input returns; a new transit needs UP again |

The recovery −22 → 0 is **not a timer**: it happens only on frames the player overlaps a 2900/2901
passage (the destination, because the player kept its offset and is frozen; both passages of a pair
have the same rect). If the player were not in contact the lock would never release [HIGH for the
code; MED that contact always holds — gravity is still applied after `vy = 0`, so a destination
passage placed in mid-air would let the player drop out of it; all 58 shipped passages pair with the
same type, census part 1 §2.11].

### 8.3 Idle sprites: entry layout and the (de)activation rule  [HIGH]

Idle table at `0x100ac02c` (`r2 + 0x47ec`), 0x220-byte entries; `.AddIdleSprite @ 10007d8c` scans 512
entries for a free one, `.HandleIdleSprites @ 100081ac` scans only **511** (`100083e8 cmpwi r30,0x1ff`)
— an entry 511 would never be activated (needs > 511 idle sprites; latent).

| entry off | content | writer |
|---|---|---|
| +0x0 | u8 used | AddIdleSprite 1; `.UpdateSprites` 0 when the sprite dies, via the sprite's `+0xa8` (main l. 5024–5027) [MED] |
| +0x4 | active sprite ptr (0 = idle) | IdleToActive / ActiveToIdle (`10007efc lwzu r3,0x4(r31)`) |
| +0x8 / +0xa / +0xc | type / x / y | ActiveToIdle `10007f9c..10007fb8` (from sprite +4/+0xc/+0xa) |
| +0xe | placement-record index | AddIdleSprite only (never rewritten — the passage/teleporter destination key) |
| +0x10..+0x17 | face bounds Rect (top, left, bottom, right) = face `+8..+0xf` (opaque bounds, sprites §2.1), or (0,0,0x40,0x40) without a face | ActiveToIdle `10007f20..10007f5c` |
| +0x18 / +0x1c / +0x20 | saved Handle / hit / tile-hit procs | ActiveToIdle `10007f70..10007f94` |
| +0x24..+0x21f | copy of sprite bytes `+0..+0x1fb` (so entry `+0x1ec/+0x1ee/+0x1f0/+0x1f2` = sprite `+0x1c8/+0x1ca/+0x1cc/+0x1ce`) | ActiveToIdle `10007fbc..10007fe0` (`lwzu/stwu` pre-increment: first store at entry+0x24 — hazard 1 checked) |

**Window** (`100081b4..10008284`): view origin (v, h) = `PTR_DAT_1009fe78`; rect
`(h − 24, v − 24, h + 632, v + 408)` united with the player's hot rect (player = `*_DAT_1009fdd8`),
then outset by 96 px on every side.

**Activation** (entry used, `+4 == 0`, type `+8 ≠ 0`; `10008294..1000832c`): test rect =
`(x + face.left − m_left, y + face.top − m_top, x + face.right + m_right, y + face.bottom + m_bottom)`
with the margins taken from the saved sprite copy (`+0x1c8` left, `+0x1ca` right, `+0x1cc` top,
`+0x1ce` bottom); `SectRect` with the window → `.IdleToActiveSprite`.
**Deactivation** (entry active, live sprite `+0x1c6 ≠ 0`; `10008334..100083e0`): the same rect built
from the **live** position and margins and the entry's saved face rect; no overlap → `.ActiveToIdleSprite(i, 1)`.
So activation and deactivation use one rule with no hysteresis; the margins enlarge the sprite's own
box; the window spans h −120..+728 and v −120..+504 from the view origin (plus the player box ±96). Trees' 0x80/0xa0 margins (part 1 §2.14)
keep them active up to 128/160 px further out. Spawned-at-once sprites (no idle entry) never go idle.

### 8.4 Wind: the source, orientation and shipped data  [HIGH]

**Source.** Wind is not a sprite: `.StandardSpriteHandles` (only when `+0x90 > 0`, `100369b0..100369b8`) reads the overlay map
(`hdr+0xb298`) at the sprite's centre cell `(+0x10 >> 5, +0xe >> 5)` (`100369c0..100369dc`): o1 = low
byte − 1 (`.GetFGOverlay1Tile`), o2 = high byte − 1 (`.GetFGOverlay2Tile`); wind iff `0 ≤ o1 ≤ 15`
(`100369e4..100369f4`) and `o2 > 0` (`10036a08..10036a0c`). No level-header field is involved.

**Orientation.** `dir = (o1 + 18) mod 36` (`10036a10..10036a38`, magic 0x38e38e39 = /36) →
`.LookupModedImpulse(dir, m)` (`100404a4`, jump table at `0x100a5724`); the result word is (v high,
h low). The four axis cases read from the table: dir 0 → h −= m (`10040e2c..10040e34`),
dir 9 → v += m (`100412dc..100412e4`), dir 18 → h += m (`100404cc..100404d4`), dir 27 → v −= m
(`1004097c..10040984`); intermediate cases use the cos/sin doubles of physics §6. The h part is added
to the **x position** (ramped over 33 frames, `10036b9c..10036c00`), the v part to **vy**
(`10036c0c..10036c14`); screen y grows downward (gravity is positive). Hence:

| o1 | dir | blows toward |
|---|---|---|
| 0 | 18 | right (0°) |
| k (1..15) | k + 18 | k·10° counter-clockwise from right |
| 9 | 27 | **straight up** |
| 12 | 30 | 120° (up-left) |
| 15 | 33 | 150° |
| < 0 or ≥ 16 | — | no wind (x ramp decays) |

Downward and leftward-down winds (160°..350°) cannot be expressed.

**Shipped data** (Python over the overlay map of all 24 levels; cells with 0 ≤ o1 ≤ 15 and o2 > 0):

| level | cells | (o1, o2) × count |
|---|---|---|
| 10 Unemployed In Greenland | 103 | (9,20) ×28, (9,50) ×71, (10,50) ×4 — all within cells x 222..234, y 28..43 |
| 20 Hangnabit | 2,899 | (9,50) ×2060, (9,70) ×726, (12,50) ×36, (6,50) ×23, (3,50) ×12, (5,50) ×12, (1,30) ×9, (2,50) ×7, (2,20) ×4, (4,40) ×4, (2,30) ×2, (3,30) ×2, (3,40) ×1, (7,50) ×1 |
| the other 22 | 0 | — |

2,885 of 3,002 wind cells (96 %) are o1 = 9 — updrafts — and level 20 holds the game's only hang-glider
pickup (rec 0, type 3050, at (1392, 256)), whose model gains height only from wind (spells-detail §5.3).
The code fixes the orientation by itself; the data agree. physics §6 "[MED] for orientation" → HIGH
(correction W1).

### 8.5 Record-p4 linkage: completeness, consumers, writers, p1 = 0 gates  [HIGH]

**Search.** Records sit at `hdr + 4 + 16·i`, p4 at `hdr + 16·i + 0xe`. In the raw listing every index
×16 is `rlwinm rD,rS,0x4,0x0,0x1b` (no `mulli …,0x10` exists; no other shift-by-4 form exists). A
script listed every such site followed within 10 instructions by a `+0xe` access (`lha/lhz/sth …,0xe(`
or `addi …,0xe` + `lhax/sthx`), with the provenance of the index register; plus every record-walking
loop (`addi rX,rX,0x10` with a `+0xe` access) and every `sthx`. Results:
- index = own `+0x48`: 46 sites (Setups/Handles reading or writing their own record);
- index = another record: **gate 2940** (p1, `1006f4f0..1006f514`), **blocks 1250..1279** (p2,
  `1006f74c..1006f778`), **spouts 1450..1453** (p1 and p2, `1006e914..1006e950`) — nothing else;
- record loops touching +0xe: only table initialisers (`.SetupLevelSprites` `10003d7c..10003dd0` clears a
  short array, not records); `.UpdateSprites`' six `sthx` write type/x/y only (`100098cc..10009968`).
Cross-record reads at p1..p3 (offsets 8/0xa/0xc) are only the gate/block/spout index fetches above
(other hits are type-indexed face tables and map-node lines).

**Every writer of a record's p4** (raw scan of every `sth …,0xe(`/`sthx`; the other `sth …,0xe(` sites store into the
game globals G (magic `G+0xe`) or a sprite's centre `+0xe`; all record writes are own-record): Button output
(`10071060..1007108c`), `.HitBonusSprite` for 1307 and 3100..3109 (`1005fdcc..1005fe48`),
`.HitPlayerSprite` conversation starters 2902..2909 (`10056fe0..1005708c`), one `.HandleBoxSprite` arm
that counts `+0x46` to 10 (`1006f268..1006f280`, the talker/balloon arm — Box reader's), plus the
save/restore block copies (engine §9). No routine writes another record's p4.

**Consequences for the shipped wiring** (fresh census, part 1 §1 corrected): all 24 buttons are
referenced; spouts reference buttons L4 30/31 (rec 28), 57 (rec 68), 63 (recs 67, 70); spouts 67/68/70
name record 0 as their second key and spout 183 names it twice (L4 rec 0 = type 1401, p4 0, no
writer → spout 183 can never fire).

**Gates 2940 with p1 = 0** read rec 0's p4 (no bounds/zero test: `1006f4f8 blt` only diverts negative p1):

| level | gates (rec) | record 0 | rec-0 p4 writer? | position |
|---|---|---|---|---|
| 18 Goblin Chief | 3, 4, 5, 6 | 2940 gate, p1 = −1 | none (a gate never writes its own p4) | x −32/−31 and 2047/2048 of a 64-tile (2048 px) level |
| 25 Manditraki Wizard | 3, 4, 5, 6 | 2940 gate, p1 = −1 | none | same |
| 45 The Dig | 81, 82, 83 | 1055 Xichron | none (Bonus p4 writer is 1307/3100.. only) | x −30 (48-tile level) |
| 62 Ends of the Earth | 0 | itself | none | (626, 1448), inside |
| 67 Xichra's Lair | 6..12 | 1208 fire | none | x −29..−28 and 893..900 of a 28-tile (896 px) level |

As written, all 19 are **permanently shut** gates (solid Box sprites at their placement). The design
intent (level-edge stoppers? 18 of 19 have their placement x at or within 32 px beyond the level's left
or right boundary) is **UNDETERMINABLE** from
code; the as-written behaviour above is what a replica must reproduce [HIGH as-written; LOW intent].

### 8.6 Effects with no spawner; Buttons 1323..1329  [HIGH]

**Effects 1202..1205, 1251, −1.** Every one of the 181 `bl .MTNewSprite` sites (`10033060`) was listed
with the setter of r3 (type) and r8 (Setup TV). The Effect Setup TV `0x100a2284` is held by exactly one
data word, TOC slot `0x1009fef8` (data scan), so effects are created only where r8 traces to that slot
(16 functions, part 2 §2.2). Their type arguments are literals {0, 2, 5, 0x410, 0x442, 0x4b1, 0x4b6,
0x4b7, 0x4ba, 0x4c4, 0xc1b, 0xc81, 0xcb2, 0xcb2+n} plus `.KillPlayerShot`'s register r23 ∈ {5, 2}
(`1005afb8..1005afc4`) and `.GenerateSprite`'s dead 0x726 path; no `bl .SetupEffectSprite` exists; no
`sth` to `+4` stores −1, 0x4b2..0x4b5 or 0x4e3 (raw scan of every `sth …,0x4(`). The only references
to those ids are the face loads in `.InitEffectSprite` (`10060550..100605b0`). So effects 1202..1205,
1251 and −1 are **dead in 1.0.3**: their Setup/Handle arms and faces exist, nothing creates them. Their
intended use is UNDETERMINABLE.

**Buttons 1323..1329** (part 1 §1): `.MTNewSprite` clears the slot (`bl 0x10099520` with r4 = 0x1fc,
`100331b8..100331c0`) before calling Setup (`10033210..1003321c`); `.SetupButtonSprite`'s switch sends
types ≥ 0x52b straight to the common tail (`10070d90..10070d98` → `10070df8`), so `+0x34..+0x3b` stay 0;
`.InitSprite` never writes the rect. The hit callback is installed, but `.MTCollideSprites` tests
overlap with Toolbox `SectRect` (`.TheSectRect` → `.SectRectFast` → `SectRect`), which is false for an
empty rect: never pressed, no face (`+0xc0 = 0`), drawn nothing. The Handle still runs the level/output
code: p4 = 0 after two frames, unless p4 ≠ 0 at the first frame and p1 == 1 (then level 10 is latched
and p4 stays 1) [HIGH arithmetic, part 1 §1 rules].

## 5. NOT RESOLVED (both parts)
1. Meaning of `s+0xb8` draw-effect modes (0x1 tint, 0x3/0x4 hurt flash, 0x8, 0x9, 0xb, 0xc
   lighting…) — readers in `.WrapDrawSprites` not decoded; tint ids 4/0xb/0xf/0x17/0x18 unnamed.
   ⚑ wave 2 (2026-10-04): belongs to INDEX item 15 (draw effects); not worked by this lane.
2. ~~Cannon re-entry: who brings a launched sprite's `s+0x130` back to ≥ 0; meaning of cannon
   `s+0x154 = 6`; identity of sprite type 90 (gets gravity 0x15e after launch).~~ → closed: §8.1
   (`.StandardSpriteHandles` +1/frame; `+0x154` write-only; type 90 = seed shot 0x5a) ⚑ wave 2 (2026-10-04)
3. ~~Passage counter `*_DAT_100a06f0` recovery from −22, `_DAT_100a05f8` (1 / −15),
   `_DAT_100a0680`; `PTR_DAT_100a05f0 = 3` on spike contact.~~ → closed: §8.2 (contact-frame
   recovery; walk animation counter; camera look-ahead; no-cling timer) ⚑ wave 2 (2026-10-04)
4. ~~Spawners of effects 1202..1205, 1251 and −1 (none via the `.SetupEffectSprite` TOC slot —
   could be passed in by a caller through a register).~~ → closed: §8.6 — none exist (all 181
   `.MTNewSprite` sites traced); dead in 1.0.3, intent UNDETERMINABLE ⚑ wave 2 (2026-10-04)
5. `.NewParticle` argument meanings; particle kinds 1/4/9 and geyser kinds 200+. ⚑ wave 2 (2026-10-04): belongs to
   INDEX items 15/28; not worked by this lane.
6. ~~Button types 1323..1329 hot-rect source (allocator state) — moot for the shipped data.~~ →
   closed: §8.6 (cleared by `.MTNewSprite`, empty rect, never pressed) ⚑ wave 2 (2026-10-04)
7. ~~Gate linkage completeness: only `* 0x10 + 0xe` read patterns were searched.~~ → closed: §8.5
   (raw search of every address form; a third consumer, the spouts 1450..1453, was found) ⚑ wave 2 (2026-10-04)
8. ~~Type 2940 with p1 = 0 reading record 0 — designer intent (permanently shut doors?). 2941 is out of
   this question: it never opens and is destroyed by damage-300 player hits (part 1 §1, raw
   1006f568–1006f5a8). ⚑ corrected (review 1b, 2026-10-03) #2.~~ → closed: §8.5 — as written permanently shut (no writer of record 0's p4 in any
   of the five levels); intent UNDETERMINABLE ⚑ wave 2 (2026-10-04)
9. ~~Exact `.HandleIdleSprites` activation rule for idle Background sprites (margins `+0x1c8..`
   apply to deactivation only; activation uses the idle entry's own margins).~~ → closed: §8.3 — the
   "entry's own margins" are the saved copies of the same `+0x1c8..+0x1ce`; one rule both ways ⚑ wave 2 (2026-10-04)
10. ~~Wind orientation (physics §6) — not settleable here: no sprite emits wind.~~ → closed: §8.4
   (overlay map; o1·10° counter-clockwise from right, 9 = up; shipped updrafts) ⚑ wave 2 (2026-10-04)
11. ~~`s+0x88` (set 0/1 by many Setups; read sites not traced).~~ Closed: light-overlay gate, sole
    reader `.WrapDrawSprites` `1001493c` (physics §0.1) ⚑ corrected (review 1c, 2026-10-03) #5.
12. ⚑ wave 2 (2026-10-04) (new, narrowed): the byte `0x100a5114` (direct `r2 − 0x272c`, not a TOC slot) is set
    to 1 every player frame (`10051488..10051490`) and cleared by the look-ahead decay arms (§8.2,
    `10051550..1005155c`, `10051578..10051580`); its only reader is `.FindUpperLeftCorner`
    (`1000b89c..1000b8a8`, inside a branch taken when a value it loads is within ±0x100). What that
    camera branch does was not decoded (engine §5 owner) [HIGH for the uses; meaning open].

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
| +0x96 / +0x98 | i16 | ⚑ wave 2 (2026-10-04): wind x-ramp counter 0..33 (+1 per wind frame, −1 per wind-free frame) / last full horizontal wind amount used by the ramp-down (`10036b9c..10036be0`, `10036c1c..`) [HIGH] |
| +0xa8 | i16 | ⚑ wave 2 (2026-10-04): idle-table entry index (`.IdleToActiveSprite` writes it; InitSprite −1; `.UpdateSprites` frees entry `+0` when the sprite dies) [MED: decompile; entry layout §8.3 HIGH] |
| +0x154 | i32 | ⚑ wave 2 (2026-10-04): cannon — 0 at Setup, 6 on capture, **never read** (§8.1); other classes use the slot as scratch [HIGH] |
| +0x1c6 / +0x1c8..+0x1ce | u8 / i16 | ⚑ wave 2 (2026-10-04) (extends the rows above): the margins enlarge the sprite's face-bounds box for **both** activation (saved copy in the idle entry) and deactivation (live), window = view ±120 px ∪ player box ±96 (§8.3) [HIGH] |

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

### 7.1 Wave 2 corrections (2026-10-04)  ⚑ wave 2 (2026-10-04)

| # | file § | old | new | evidence |
|---|---|---|---|---|
| W1 | physics.md §6 | "[MED] for orientation"; "Wind and currents" read from the overlay | orientation **HIGH**: o1 = k blows toward k·10° counter-clockwise from screen-right (0 right, 9 up, 12 up-left, 15 = 150°; nothing downward); the h part moves the **x position** (33-frame ramp), the v part is added to vy; the overlay drives wind only (water currents are `hdr+0x2714`, §2), in or out of liquid; shipped wind = levels 10 and 20 only, 96 % o1 = 9 updrafts | part 2 §8.4; jump table `0x100a5724` → `10040e2c`/`100412dc`/`100404cc`/`1004097c`; `10036b78..10036c14` |
| W2 | world-data-format.md §3.3 overlay row | "o1 0..15 → wind/current direction with strength o2" | add: direction = o1·10° CCW from right (9 = up), magnitude o2·14 per frame (×`+0x90`/256), test threshold o2·15; no "current" meaning | part 2 §8.4 |
| W3 | physics.md §0 `+0x1c6 / +0x1c8..+0x1ce` | "may go idle off-screen / idle-test margins" | add: used for activation (copied into the idle entry at `+0x1ec..+0x1f2`) and deactivation alike; window = view origin −24/+632 (h), −24/+408 (v), ∪ player hot rect, outset 96; `.HandleIdleSprites` scans 511 of the 512 entries | part 2 §8.3; `100081b4..100083f0` |
| W4 | engine.md §5 camera | focus x = `playerX + (_DAT_100a0680 >> 8)` (update rule not given) | add the update rule: vx > 0x100 → L += vx/4 (twice while L < 0), cap ±0x5000 (80 px); slow → decays 0x200/frame only while pointing against the facing; zeroed by passages at counts 21/22 | part 2 §8.2; `10051494..1005158c` |
| W5 | player-states.md §2 rows `_DAT_100a06f0`, `_DAT_100a05f8` | "1..0x16, then −0x16"; "walk-out (−15..0)" | the −0x16 is not timed: it rises +1 only on frames the player overlaps a passage (normally the destination); the walk-out ends 7 frames before input returns | part 2 §8.2 timeline |
| W6 | pickups-boxes.md §2.2 row 1450..1453 / enemy-shots-and-damage.md §1.4 (spouts) | spout keys p1/p2 named as "linked switch" records | add the census: L4 spouts 28 (p1 30, p2 31), 67/70 (63, 0), 68 (57, 0), 183 (0, 0); record 0 of level 4 is a 1401 with p4 0 and no writer → the p2 = 0 keys are inert and spout 183 never fires | part 2 §8.5 |
