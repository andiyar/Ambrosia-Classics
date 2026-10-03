# Ferazel's Wand 1.0.3 — pickups (class Bonus), boxes / crates / doors (class Box), held items

Code readings only; nothing behaviour-verified. Date 2026-10-03.
Sources: `ghidra/Ferazel_handlers.decompiled.c` ("handler dump", every Setup/Handle/Hit/HitTile
callback), `ghidra/Ferazel_pef.decompiled.c` ("main dump"), raw disassembly
`ghidra/Ferazel_pef.disasm.txt` (addresses), data constants via `tools/const.py`, placement census
over all 24 `Mlvl` records (Python over the §3.4 record layout, `tools/gensprite_map.py` for the
class), PICT names from `Ferazel's Wand Sprites.rsrc`, `STR# 500` (World Data), manual TEXT 131/132.
Scope: class **Bonus** (`.SetupBonusSprite @ 1005d988`, `.HandleBonusSprite @ 1005e934`,
`.HitBonusSprite @ 1005fd38`, `.HitBonusTileSprite @ 1006010c`, `.KillBonus @ 10060024`,
`.InitBonusSprite @ 1005d4f0`) and the pickup arms of `.HitPlayerSprite @ 100556f4`; class **Box**
(`.SetupBoxSprite @ 1006b43c`, `.HandleBoxSprite @ 1006d878`, `.HitBoxSprite @ 10070024`,
`.HitBoxTileSprite @ 10070718`, `.KillCrate @ 1006fa98`, `.KillBox @ 100705f0`,
`.InitBoxSprite @ 1006aa5c`) and the Box arm of `.HitPlayerSprite`; the **held item**
(`.SetupHeldItemSprite @ 1004bdd0`, `.HandleHeldItemSprite @ 1004be74`, `.HandleItemUse @ 1004d054`,
`.SetHeldItemPos @ 1004bf2c`) and the non-spell shot ids 0x3c/0x50/0x5a.

Wave 2 (2026-10-04): loose ends (sound ids, `+0x168`, gate globals, faces, carpet, stalactites, conversations,
per-type decoration rows) are in **`pickups-boxes-2.md`**; in-place changes here carry ⚑ wave 2 (2026-10-04).

Conventions. `pN` = placement param N = record `+4/+6/+8/+0xa` = `hdr + 16·idx + 8/0xa/0xc/0xe`
(world-data §3.4; the code reads `*(short *)(*(int *)*_DAT_100a0058 + idx*0x10 + 8..0xe)`).
`SetRect(l,t,r,b)` is the Toolbox call; the hot rect is stored at `+0x34` as (top,left,bottom,right)
(physics §0). `G` = game globals (`_DAT_1009ffc0`, engine §9). TOC slots holding callbacks were
resolved slot → TVector (word + 0x1009f840) → code address → traceback name; e.g.
`PTR_PTR_100a047c` = `.HandleBonusSprite`, `PTR_PTR_100a0484` = `.HandleBoxSprite`,
`PTR_PTR_100a04e8` = `.HandlePlayerShotSprite`, `PTR_PTR_100a052c` = `.HandlePlayerSprite`,
`_DAT_100a0200` = `.HandlePlatformSprite`, `PTR_PTR_100a01f8` = `.HandleStatueSprite`,
`_DAT_100a01c8` = `.HandleSeeSawSegSprite`, `PTR_PTR_100a0460` = `.HandleEffectSprite`,
`PTR_PTR_100a04f8` = `.HandleHeldItemSprite`, `PTR_PTR_100a0830` = `.SetupEnemyShotSprite`,
`_DAT_1009fef8` = `.SetupEffectSprite`, `_DAT_1009ff38` = `.SetupBonusSprite`,
`_DAT_1009ff34` = `.SetupBoxSprite` [HIGH: data-section words read with `pef.py`].
A "frame" is one `.GameLoop` iteration (≤ 30 Hz). Velocities in 1/256 px per frame.

## 1. Class Bonus

### 1.1 Common setup and per-frame tail  [HIGH]
`.SetupBonusSprite` (handler dump l. 6563–7028): `InitSprite`; layer `+0x80 = 1`; `+0x4c` Handle,
`+0x5c` HitBonus, `+0x1f8` HitBonusTile, `+0x50` KillBonus; `+0xa6 = 0`; gravity `+0x110 = 0x151`
(337) unless a type arm overrides; `+0x9a = −1` (no light); if the record index is valid,
`+0x168 = p4` (~~no reader of a Bonus `+0x168` found in the four Bonus routines or the pickup arms~~ read by
`.TurnIntoCannoned`: p4 = 1 → never loaded into a cannon, pickups-boxes-2 §2 ⚑ wave 2 (2026-10-04));
tail (l. 7019–7026): `+0x14c = FastRand(60)` (light-flicker timer), fixed-point position from the
integer one, `CalcCenterPos`, `+0xe4 = 1`. For 1055/1056, 1290..1293 and 1300/1301 a light is
attached only when prefs `+0x06 == 1` (1055/1056 also need the light count `_DAT_100a0124 < 150`);
the other types always get one. `_DAT_1009fe44` is the 0x942-byte prefs copy (main dump l. 7196
`BlockMoveData(*prefs, _DAT_1009fe44, 0x942)`; engine §8 row 0x06).

`.HandleBonusSprite` (l. 7030–7666) returns at once if `+0xe9` (dying) or `+0x1b2`; runs
`StandardSpriteHandles`; a negative `+0xa6` counts up by 1 per frame; type arm; then the tail
(l. 7643–7666): horizontal **friction** `vx → toward 0 by +0x114` per frame (clamped at 0);
`ApplyGravityAndSeparateFromTiles` if `+0x110 > 0` **and** the type is not 0x517/0x41f/0x420;
`StandardSpriteCleanup`; the light follows the centre (except 0x51b and 0xc1c..0xc25).
No sinusoidal bob exists in these routines: a pickup either hangs still (gravity 0) or falls,
bounces and slides to rest; the only motion when resting is the face animation [HIGH for the four
routines; `StandardSpriteHandles` itself is physics §2].

Tile contact (`.HitBonusTileSprite`, l. 7762–7830): skipped entirely while the debug no-clip key
(`_DAT_100a0064` and key 0x32) is held. FG tiles → `.WallBounce(…, bounce f)` with f = 0x80
(default), 0x40 (money bags 0x50c/0x50d), 0xe0 (crystal shards 0x4bf..0x4c1); FG kind 0x67 is
passed through while moving up (vy < 0). A money bag landing with |vy| > 0x100 plays a random-pitch
3D sound (`_DAT_100a0300`, vol 0x55). BG kinds < 100 → WallBounce, 100..199 → WallBounceBG,
≥ 200 water → `HandleUnderWater` unless `+0x140`. `param_4 == 2` clears `+0x118`.

Sprite-sprite (`.HitBonusSprite`, l. 7669–7760): non-container bonuses rest on boxes and
platforms: if the other sprite is a Platform or Box (not the player), the bonus is a non-scroll,
non-item type (`< 2000` or `> 0xc80`), and the other is not type 0x51c (chest),
`PlatformBounce(bonus, other, centre, f, rect, f == 0)` with f = 0x80, or 0 (no bounce) when the
bonus's `vy < 0x180`. Items 0xc81..0xcb0 also qualify (they are `> 0xc80`).

### 1.2 Pickup gate (`.HitPlayerSprite`, handler dump l. 3270–3283)  [HIGH]
`.HitPlayerSprite(player, other)` returns at once if `*_DAT_100a069c > 0` (~~unnamed global~~ the dying counter, pickups-boxes-2 §3 ⚑ wave 2 (2026-10-04)), or if
the Mist timer `*_DAT_100a0578 > 0` and `other` is not a Bonus. A Bonus is collected only if its
**`+0xa6 == 0` and `+0xb0 == 0`**. `+0xb0` is therefore a *pickup delay*: drops set it to 12
(`li r0,0xc; sth r0,0xb0` at `1006e7a4` chest, `1006fe78` crate; `.HurtPlayer` coins, main dump
l. 45187) and the per-type arms decrement it once per frame (0x50a..0x50d, 0x516/0x518/0x519/0x51a,
spheres, 0x53c/0x53d, scrolls, items — the `LAB_1005f808` path); 0x514/0x515 zero it every frame
(l. 7264–7265), so their delay is void; **0x41f/0x420 never decrement it** (latent: a Xichron spawned
with a delay could never be collected; no shipped drop does that, §1.9).

### 1.3 Type table (setup, motion, effect on touch)
Names: PICT names in `Ferazel's Wand Sprites.rsrc` (quoted), manual TEXT 131/132 (italic words)
[MED for names]. Face sets from `.InitBonusSprite` (main dump l. 45700–45775): `LoadEncFaceSetFromPICT
(id, frames, w, h, …)`. Effects are `.HitPlayerSprite` arms, line numbers given [HIGH arithmetic].

| type | name / face | setup (rect = SetRect l,t,r,b; gravity) | anim / light | touch effect |
|---|---|---|---|---|
| 69 (0x45) | Mist body (spawned by `.HandlePlayerSprite`, handler dump l. 1831) | rect 0x23,0x23,0x41,0x50; face = player face +0x9c | Handle returns at once | if Mist timer ≤ 0x167: timer = −1, `_DAT_100a0574 = 14`, `PTR_DAT_100a05a8 = 6`, sound `_DAT_100a03e0`, body killed, player teleported to the stored body x/y (`PTR_DAT_100a04d4/04d0`), v = 0 (l. 3308–3329) |
| 1055 (0x41f) | *gold Xichron* ("golden spiders"); face set **PICT 1057** (10 frames 32×32) — PICT 1055 'Bonus crystal' is never loaded | rect 2,−4,0x12,0x10 (Handle resets it to 2,2,0x1e,0x1e each frame); gravity 0 and never applied; `+0x46 = rand(19)`, `+0x112 = 0x1c+rand(6)`, `+0x114 = 2+rand(3)`; in water at spawn → `+0x15c = 1` → `+0x11c/+0x120 = 1` each frame | frame `+0x46>>1`, `+0x46` 0..19; light 0x16 if lights on and light count `_DAT_100a0124 < 150` | score +10, Xichrons `G+0x14` +1, sound `_DAT_100a02d4` vol 0x55, KillBonus via `+0x50` (`lwz r12,0x50(r30)` at `100559e8`); burst `ExplodeFaceIntoParticles` (detail by prefs+6); at ≥ 100: **`G+0x14 = 0`** (`li r0,0; sth r0,0(r24)` at `10055ac4..acc`), two sounds, +1 item 0x16 (Red Xichron) in the first slot that is empty or already holds item 0x16, count ≤ 99, status bar refresh (l. 3343–3407) |
| 1056 (0x420) | big Xichron, same face; `+0xb8 = 0x10001` each frame | as 1055 | light 0x2c | score +1000, `G+0x14` +100, two pitched coin sounds, then as 1055 (so 99+100 → 0: the excess is lost) |
| 1057 (0x421) | — | never spawned by `.GenerateSprite`; Setup would fall to the item default | | none |
| 1058 (0x422) | invisible trigger | rect 0,0,0x60,0x60; gravity 0; no hit/tile callbacks; no face | | `G+0xad8 + 2·p1 = p2` (or 1 if p2 = 0), KillBonus (l. 3330–3341) |
| 1059 (0x423) | invisible **secret-area** trigger | as 1058; counted (`+0x1b5 = 1`, `_DAT_1009ffac`++) while `.SetupLevelSprites` runs | | if p1 ≠ 0 sound `_DAT_100a02c4`; KillBonus → secrets found `G+0x496+2L` +1 (§1.10) (l. 3299–3305) |
| 1290 (0x50a) | '$Big magic crystal' | rect 2,0xe,0x12,0x1e; gravity 0x151, **0 if p1 ≠ 0**; `+0x46 = rand(10)`, `+0x112 = 0x1c+rand(6)`, `+0x114 = 10` | 11-step glint: `+0xb8` 0x10008/0x10009 on steps 2..7; light 0x37 | score +100, magic `G+0xe` +0x2a0 (≤ max `G+0xc`), sound `puVar22` (l. 3409–3419) |
| 1291 (0x50b) | '$Big health crystal' | as 1290 | as 1290; light 0x21 | score +100, `G+4` +0x2a0, `G+6` +0x2a0, player `+0xa4` +0xe0, each clamped to max `G+0xa` (l. 3428–3449) |
| 1292 (0x50c) | '$Moneybag, small' | rect 6,0xc,0x1a,0x12; gravity 0x151; `+0x46 = −5−rand(10)`, `+0x112 = 0`, `+0x114 = 0x32` | 41-step glint; light 99 | score +25, coins `G+0x10` +5, coin sound + pitched 3D sound (l. 3421–3427) |
| 1293 (0x50d) | '$Moneybag, big' | rect 2,0xc,0x1e,0x18; as 1292 | as 1292 | score +100, coins +25, three sounds (l. 3285–3297) |
| 1300 (0x514) | 'magic bonus' green crystal (6 frames 18×20) | rect 2,−4,0x12,0x10; gravity 0x151; `+0x46 = rand(4)` | 6-frame loop; light 0x37; `+0xa6 = +0xb0 = 0` every frame | score +25, magic +0xe0 (≤ max), sound vol 0xab (l. 3473–3482) |
| 1301 (0x515) | blue crystal (6 frames) | as 1300 | light 0x21 | score +25, player `+0xa4` +0xe0, breath `G+6` +0xe0, `G+8 = 30`, clamps, then `G+4 = +0xa4` (l. 3483–3499) |
| 1302 (0x516) | coin (9 frames 10×10) | rect 2,−4,8,7; gravity 0x151; `+0x46 = rand(9)` | 18-step loop | score +5, coins +1 (l. 3465–3471) |
| 1303 (0x517) | rock pile container (PICT 1303) | rect 2,−8,0x1c,0xb; gravity never applied | static | none (pickup arm absent); opened by a shot, §1.5 |
| 1305 / 1306 (0x519/0x51a) | 'gold coins' / 'Platinum coins' (PICT 1309/1310 face sets) | as 1302 | as 1302 | score +5, coins +10 / +100 (l. 3457–3463, 3501–3507) |
| 1307 (0x51b) | flickering torch container (PICT 1307, 6 frames 10×28) | rect −4,−2,0xe,0x1e; gravity 0; `+0x12c = 1`; `+0xb0 = 1` if p4 = 0, else `+0xb0 = 0` and no hit callback; light 0x16 (p3 = 0) or 0x58 (p3 ≠ 0) | 6-frame loop, random spark particle 1/30 frames; light flicker | opened by a shot, §1.5 |
| 1330..1339 | spheres, §1.6 | rect 0,0,0x20,0x1b; gravity 200, **0 if p1 ≠ 0**; light 99 | visible while `+0xa6 < 1`: 6-step `+0xb8`/light cycle; hidden while `+0xa6 > 0` | §1.6 |
| 1340 / 1341 (0x53c/0x53d) | max-health / max-magic upgrade (6 frames 44×42) | rect 4,8,0x28,0x1e; gravity 0; light 0x4d / 0x21; `+0x15c = rand(16)` | ping-pong 0..5..0 over 20 steps; light face cycle | score +2000, sound vol 0xab, gamma flash, blocking ~0.5 s animation: max (HP `G+0xa` / magic `G+0xc`) +0x70 in 8-steps, HP or magic refilled, `G+8 = 8` for 1340 (l. 3520–3625) |
| 1350 (0x546) | 'Air Bubble' | rect 8,8,0x18,0x18; gravity 0; `+0x12c = 1`; `+0x188 = 1` | `+0x11c = 1` every frame | breath `G+6` +0x230 (≤ `G+4`), sound `_DAT_100a0370` (l. 3510–3518) |
| 2000..2049 | spell scroll (PICT 2000, one face) | rect 4,4,0x1c,0x1c; gravity 0; light 99; `+0x46 = rand(16)` | light cycle only | §1.7 |
| 3050 (0xbea) | '$Hang Glider' | rect 0x47,0x44,0x5a,0x6d; gravity 0; `+0x188 = +0x18b = 1` | static | only if `PTR_DAT_100a05c4 == 0`: glider mode on (`_DAT_100a05e0 = 1`, `_DAT_100a05d4 = 1`, `PTR_DAT_100a05c8 = 0`), player moved onto the glider's position, player face/rect switched (rect 0x37,0x3e,99,0x6e) (l. 3627–3646) |
| 3100..3109 | candelabra / light containers ('Standing Candelabra, Regular' …, 'Horned Skull Light'; faces `_DAT_100a08a4[type−3100]`) | rect = 16×16 around a per-type flame point; gravity 0; `+0xb0 = 1` if p4 = 0 else 0 + no hit; light 99 (3103: 0x4d, 3107: 0x37, 3108: 0x42) | flame particles while `+0xb0 == 1` (one per frame; every other frame at prefs+6 = 3; two at prefs+6 = 1) | opened by a shot, §1.5 |
| 3200..3248 | items, §1.8 (face `_DAT_100a08a0[type−3200]` = PICT 3200+id) | rect 4,4,0x1c,0x18 + per-type trims; gravity 200, **0 if p1 ≠ 0**; `+0x114 = 6`; light 99 (0x21 for 3223/3225/3226, 0x2c for 3206/3224, 0x4d for 3219) | static | §1.8 |
| 1215..1218 (0x4bf..0x4c2) | Multi Crystal shards (PICT 1215, 4 frames 16×17) — spawned by `.HurtPlayer` | layer = player layer + 1; gravity 0x151; `+0xa6 = −40` | frames by `+0xa6` (−13/−9/−5 thresholds), die at 0 | never collectable (`+0xa6 ≠ 0` while alive; 0x4bf returns explicitly, l. 3451) |

Sounds are TOC handles (`*_DAT_100a02d4` etc.); ~~the `snd ` ids behind them are NOT RESOLVED here~~ every
handle → id, and every pickup/box sound site: pickups-boxes-2 §1 ⚑ wave 2 (2026-10-04).

### 1.4 Gravity / float rule summary  [HIGH]
Floating (gravity 0): 1055, 1056, 1058, 1059, 1303, 1307, 1340, 1341, 1350, scrolls, 3050, 3100..3109.
Falling 0x151: 1290/1291 (unless p1 ≠ 0), 1292, 1293, 1300..1302, 1305, 1306. Falling 200: spheres
and items (unless p1 ≠ 0 → float). So **p1 of a sphere, item or big crystal = "hang in the air"**.
Census: 1291 ×4, 1290 ×2, 1293 ×1, 1334 ×1, 1335 ×6, 1337 ×5, 1338 ×1, 1339 ×8, 1340 ×2, 1341 ×1,
3204 ×1, 3206 ×1, 3214, 3215, 3219 ×5, 3223 ×1, 3224 have p1 = 1.

### 1.5 Containers: 1303 rock pile, 1307 torch, 3100..3109 candelabras  [HIGH]
`.HitBonusSprite` l. 7694–7735: when hit by a **player shot** (`other+0x4c` = HandlePlayerShot)
whose id `+4 ≠ 0x50` (Pentashield orbs never open them) and whose `+0xa6 == 0`:
- 1307 and 3100..3109: if `+0xb0 == 0` (already spent) nothing happens (the shot is not consumed);
  else `+0xb0 = 0`, hot rect zeroed, and **record p4 = 1** — persisted, so Setup restores it spent
  (no hit callback, no sparks) after any checkpoint resume. 1303: KillBonus (destroyed; record
  cleared by `.UpdateSprites`).
- The shot is killed (`KillPlayerShot(shot,1,1)`), score `G+0` += 150 (`addi r0,r3,0x96` at
  `1005fe78`), and one crystal is spawned with `MTNewSprite(type, centreX−9, centreY−9, layer 2,
  −1, SetupBonusSprite)` and `vy = −2000 − FastRand(1000)`: type **0x514 (magic)** if
  `(HP<<8)/maxHP > (magic<<8)/maxMagic` and `HP > 0x25`, else **0x515 (health)**
  (`cmpw r28,r25; ble` / `cmpwi r0,0x25; bgt` at `1005fe74..1005fe8c`). Each container therefore
  yields exactly one crystal per visit. Manual: "flickering torches … contain magical crystals";
  sign STR# 500 #12: "Sparkly torches and rock piles contain bonuses. Shoot them…".

### 1.6 Power-up spheres 1330..1339 — the sphere is not consumed  [HIGH]
`.HitPlayerSprite` switch l. 3741–3830 (effects as spells-items §5). After the arm,
**`sphere+0xa6 = duration`** (`sth r24,0xa6(r30)` at `100569e0`); the sphere is *not* killed
(except 1339 Death). `.HandleBonusSprite` (l. 7570–7612) then hides it (face 0, light off) and
counts `+0xa6` down; at 0 it reappears and can be taken again (gate §1.2). Durations:
1330 / 1331..1333 / 1334 / 1337: 600; 1336: 900; 1335: **p2 = 0 → 32000, p2 ≠ 0 → 450**
(`lha r0,0xa(r3)` p2, `li r24,0x7d00` / `li r24,0x1c2` at `10056800..10056814`); 1338: 32000;
1339: 0 (killed; HP −0x380). 32000 frames ≈ 17.7 min: in practice once per visit. Spheres are never
removed from the record, so a checkpoint resume or revisit brings every sphere back at `+0xa6 = 0`.
Census: 1335 has p2 = 1 in 2 placements (both p1 = 1).

### 1.7 Scrolls (2000..2049) and NOT-RESOLVED 11 (spells 2 and 7)  [HIGH]
`.HitPlayerSprite` l. 3648–3686: spell id = p1 for type 2000, else type − 2000; first slot that is
empty or already holds that spell (slot flag `+8 ≠ 0`); slot id = spell, **then `if id == 2 →
id = 3`** (`cmpwi r0,0x2; li r0,0x3; sth` at `10056520..1005652c`); flag = 1; count untouched (no
stacking); sound `_DAT_100a02cc`; selection highlight `PTR_DAT_1009fda8 = 0x20` on that slot;
status bar refresh. Shipped placements — only type 2000 is placed (5 records, p2..p4 = 0):

| level | record | p1 | spell learned |
|---|---|---|---|
| 3 Western Reaches | 146 | 1 | 1 (Statue) |
| 10 Unemployed In Greenland | 263 | 5 | 5 (Boomerang) |
| 18 Goblin Chief | 21 | 4 | 4 (Tree Trunk) |
| 31 Iceconoclasm | 2 | **2** | **3 (Ice Wall)** after the conversion |
| 50 Fire In The Hole | 342 | 6 | 6 (V Blade) |

No placement of 2001..2049, and no record of any class carries 2000..2049 as a crate/chest drop
param (census: values 2000..2099 appear only as Platform/Background motion params). **Spell 2 is
never granted as 2** (the only 2-scroll becomes Ice Wall) and **spell 7 is never granted** by any
shipped scroll or drop. ~~Conversations (`Mcnv`) were not checked as a grant path (out of scope).~~ No
conversation action can grant a spell (pickups-boxes-2 §8 ⚑ wave 2 (2026-10-04)).

### 1.8 Items 3200..3248 (item id = type − 3200)  [HIGH arithmetic; names MED, ids 0..11 HIGH for the art (PICT 702)]
`.HitPlayerSprite` l. 3688–3739: 3221 first `RemoveItem(0)` (one dagger), 3215 first
`RemoveItem(0xe)`; first slot empty or holding this item id (flag 0); count +3 for 3206 (fire
seeds) else +1, ≤ 99; flag 0; sound `_DAT_100a02c0`; highlight as scrolls. The face is
`_DAT_100a08a0[id]` = PICT 3200+id (`InitBonusSprite` loads 27 faces 0xc80+i), so the PICT names
name the item ids:

| id | PICT 3200+id name | id | PICT name | id | PICT name |
|---|---|---|---|---|---|
| 0 | (no PICT 3200; dagger) | 9 | '$Poppyseed Muffin' | 18 | **'$Ice Pick'** |
| 1 | (unnamed PICT) — **Steel Key** (PICT 702 caption) | 10 | '$Algernon Piece' | 19 | '$Multiplier Crystal' |
| 2 | 'Gold Key' | 11 | '$Algernon Frame' | 20 | **'$Light Orb'** |
| 3 | 'Platinum Key' | 12 | '$Algernon' | 21 | '$Vorpal Dirk' |
| 4 | 'magic ptn' | 13 | '$Gwendolyn' | 22 | '$Xichron' (red) |
| 5 | (unnamed; health potion) | 14 | '$Wooden Shield' | 23 | '$Rez Necklace' |
| 6 | 'Fire seeds' | 15 | '$Magic Shield' | 24 | '$Fire Charm' |
| 7 | '$Locket' | 16 | '$Gold Ring' (Smiting) | 25 | '$Mist Potion' |
| 8 | **'$Hammer'** | 17 | '$Green Ring' (Escape) | 26 | (unnamed; Ziridium seeds) |

PICT 702 (item icon sheet, rendered in review 1a) captions ids 0..11: Dagger, **Steel Key**, Gold
Key, Plat. Key, Magic Ptn., Health Ptn., Fire Seeds, Locket, Hammer, Poppy Muffin, Alg. Piece, Alg.
Frame — so item 1 is the **Steel Key** and item 5 the **Health Potion** [HIGH for the art captions;
ids 12..26 keep the PICT 3200+id names, MED] ⚑ corrected (review 1a, 2026-10-03) #6.

Placed items (type: count, levels): 3204 magic potion 2 (1,3); 3205 health potion 2 (2,40); 3206
fire seeds 28 (20,21,22,45,52); 3214 wooden shield 1 (5); 3215 magic shield 1 (25); 3216 gold ring
15; 3217 green ring 2 (10,51); 3219 multiplier crystal 35; 3223 rez necklace 11; 3224 fire charm 1
(55); 3226 ziridium seeds 2 (30). Keys 3201..3203 are never placed loose: they come only from chests
and crates (§2.4.1–2.4.2). Items 7..13, 18, 20, 22 are not placed and not dropped by any shipped
chest/crate ~~(conversations not checked)~~; conversations grant items 3, 4, 5, 6, 17, 18, 26 — among them
the otherwise unobtainable 18 Ice Pick (pickups-boxes-2 §8 ⚑ wave 2 (2026-10-04), reachability MED).

### 1.9 Dropped bonuses  [HIGH]
- Player hurt (`.HurtPlayer`, main dump l. 45175–45200): coins lost `n` = min(param, `G+0x10`);
  n × 0x516 at the player's centre ± rand(8), layer 0x14, `+0xb0 = 12`, `vx = ±(600+rand(0x640))`,
  `vy = −2000 − rand(0xdac)`, **`+0x16c = −240`** (`li r0,-0xf0; stw r0,0x16c` at `10054c58`).
  `.HandleBonusSprite` (l. 7307–7320): `+0x16c` counts up; from −45 the coin blinks
  (`+0xb8 = 0xb0000` on frames where the byte `_DAT_1009fd30` ≠ 0); at 0 KillBonus. Any coin-type
  bonus whose y exceeds the level height (`hdr+0xb282` rows · 32) is killed.
- Multi Crystal loss (l. 45085–45122): 4 shards 0x4bf..0x4c2 (table row above).
- Containers (§1.5), chests and crates (§2.4.1–2.4.2).

### 1.10 Persistence and level statistics  [HIGH]
`.UpdateSprites` (main dump l. 4899–) writes each live sprite's type/x/y back into its record and
clears the record's active byte when the sprite dies, except: `+0x188` set → no write-back and no
clear on the first death frames; `+0x18b` set → no clear on the final one. Consequences for
pickups (all ordinary pickups die with `+0xe9 = 1`): every collected Xichron, crystal, coin, item,
scroll, upgrade, trigger and rock pile is gone for good once its record snapshot is saved (engine §9:
checkpoint or level end); a fallen pickup keeps its fallen position. Exceptions: **spheres** are
never killed (§1.6); the **hang glider** (`+0x188 = +0x18b = 1`) keeps its record and original
position, so it is back after any reload; the **air bubble** (`+0x188` only) keeps its original
position but its record is cleared at the final kill.
Stats: during `.SetupLevelSprites` the flag `*_DAT_1009fe8c = 1` (main dump l. 2521–2527); Setup
then marks 1055/1056 (`_DAT_1009ffb0`++) and 1059 (`_DAT_1009ffac`++) with `+0x1b5 = 1`; on a first
visit `.SetupLevel` copies those counts into `G+0x7b6+2L` and `G+0x87e+2L` (l. 2533–2535).
`.KillBonus` (main dump l. 45777–45808), when the sprite is not already dying and `+0x1b5`, moves one
unit from the pending count to **`G+0x3ce+2L` (Xichrons collected; 1055 and 1056 count 1 each)** or
**`G+0x496+2L` (secrets found; 1059)**. Dropped Xichrons are never counted (`+0x1b5` only set during
level setup). By elimination the third pair `G+0x306`/`G+0x6ee` is enemies [MED].

### 1.11 Census (active records, Bonus class)  [HIGH]
1055 ×1944 (20 levels) · 1056 ×11 · 1058 ×2 (L2 p1=1; L40 p1=3 p2=1) · 1059 ×236 (p1 0 ×121, 1
×115) · 1290 ×69 (L45 ×52) · 1291 ×56 (p4 = 1 ×5, ~~no reader~~ L40, the no-cannon flag, pickups-boxes-2 §2 ⚑ wave 2 (2026-10-04)) · 1292 ×9 · 1293 ×31 · 1303 ×54
(L1,2,4,10,11) · 1307 ×224 (p3 = 1 ×23) · spheres 1330 ×1, 1331 ×2, 1332 ×2, 1333 ×2, 1334 ×8,
1335 ×23, 1336 ×1, 1337 ×12, 1338 ×7, 1339 ×10 ~~(all L45)~~ (only 1339 is L45-only; levels per type in
pickups-boxes-2 corrections P1 ⚑ wave 2 (2026-10-04)) · 1340 ×8 · 1341 ×8 · 1350 ×6 · 2000 ×5 ·
3050 ×1 (L20) · 3100 ×23 · 3101 ×9 · 3102 ×10 · 3103 ×4 · 3106 ×3 · 3107 ×2 · 3108 ×12 · items §1.8.
Record byte +1 is 0 in every Bonus and Box record, and no Bonus/Box routine reads it.

## 2. Class Box

### 2.1 Defaults and per-frame tail  [HIGH]
`.SetupBoxSprite` (l. 11409–12245): `InitSprite`; layer `+0x80 = 2`; `+0x4c` HandleBox,
`+0x5c` HitBox, `+0x1f8` HitBoxTile; `+0xa6 = 3`; gravity 0x151; **HP `+0xa4 = 600`**; then the type
arm; tail (l. 12239–12244): fixed-point position, `+0x13c = 0x80` (pusher factor, physics §8.1).
`.HandleBoxSprite` (l. 12248–13397) returns if dying or `+0x1b2`; `StandardSpriteHandles`;
`+0x182 = 0`; type arm; tail (l. 13370–13396): `ApplyFriction(+0x114)`; `FootPressure` when
grounded last frame (`+0xcd`, not 0x438/0x439); `EnforceMaxSpeed(0x1838)`; `y += vy`;
`ApplyGravityAndSeparateFromTiles` when gravity ≠ 0 (always for 0x438/0x439); mine-cart children
follow; `BoxCleanUp` (`.BoxUW`: splash when entering water; `.BoxClean`: centre, `+0xdc = 0`,
`+0xd6 = 0`).

Player vs Box (`.HitPlayerSprite` l. 3859–4220): special arms first (below), then — except signs
etc. 0xb56..0xb5d without `+0x15c` — `PlatformBounce(player, box, …, 0)`: boxes are solids the
player stands on and pushes (a side push moves the box if its push mass `+0x138 > 0`, physics
§8.1). Landing results (return 1) feed the geyser, trampoline, spin-stomp, teleporter and save-point
arms. Box vs Box/Statue/Platform (`.HitBoxSprite` l. 13470–13530): mutual `PlatformBounce` in an
order chosen from the grounded flags `+0xce` (the grounded one is the solid), then height, then
speed; `+0x182` latches the pair for the frame; geyser pieces are always the solid. NPC types
0xb87..0xbb7 and blocks 0x4e2..0x4ff ignore all sprite contacts in `.HitBoxSprite`; a player
shot hitting any Box is resolved in `.HitPlayerShotSprite` (killed on contact, or bounced off a
one-way/surface-function box); only crates (§2.4.1), 2932 and 2941 take shot damage.

### 2.2 Box type table (all ranges routed to Box by `.GenerateSprite`)  [HIGH unless noted]

| types (dec) | what (evidence) | setup | behaviour |
|---|---|---|---|
| 712 / 713 (0x2c8/0x2c9) | **Tree Trunk** segments (PICT 712/713; spawned only by spell 4) | 712: gravity 0x15e, rect 3,4,0x1d,0x18; 713: gravity 0, rect 3,3,0x1d,0x15 | §2.4.9 |
| 1060..1062 | 'teleporter', 'Teleporter 2/3' | gravity 0, one-way top `+0x185`, rect 0,−4,0x20,0x1a; `+0xb8 = 0x90000` if in water | §2.4.7 |
| 1065 | 'save point' (3 frames 0x54×100) | face frame = p1; gravity 0; one-way; rect 0x21,0x3f,0x33,99 | §2.4.8 |
| 1070..1072 | boulders (PICT 1070, 'Boulder 2', 'Boulder 3') | push mass `+0x138 = 0x8c`, friction `+0x114 = 0x46`, `+0x112 = 0x14`, gravity 0x100, `+0x90 = 0x100`, `+0x1c8..+0x1ce = 0x80`, rect 4,0,0x1c,0x1c | rolls: `+0x46` += distance·360/0x6900 (≈ 33 px diameter), `+0x1aa` = draw angle; tile hit at \|vy\| > 0x1ff bounces 0x3c with a thud (> 0x300) |
| 1075 / 1076 (0x433/0x434) | falling rocks (PICT 1070 face; not placed; dropped by Warrior / Wizard (`+0x160 = −52`) / Xichra — pickups-boxes-2 §5 ⚑ wave 2 (2026-10-04)) | as boulders | `+0x160 < 0`: inert, blinking, counting up; at 0 gravity 0x96 and collisions on. Hits the player from above at vy ≥ 600: `HurtPlayer(p, rock, 0x38 / 0x70, 1, 0x1e / 0x3c, 0)` then `KillBox`; also `KillBox` on an FG tile hit at \|vy\| > 0x1ff (l. 3883–3898, 13616–13634) |
| 1080 / 1081 (0x438/0x439) | ~~crumbling ledge~~ **magic carpet**, dormant / flying (PICT 1080, 6 frames 113×24; pickups-boxes-2 §4.3 ⚑ wave 2 (2026-10-04)) | lifetime `+0x14c = p2·30` (−1 if p2 = 0 → never), `+0xb8 = p1 + 0x10000`, gravity 0, one-way; 1080 rect 0x34,4,0x35,0xc (1 px wide) and no tile hits; 1081 rect 0x12,4,0x5b,0x12 | §2.4.6 |
| 1250..1279 (0x4e2..0x4ff) | switch blocks (PICT 1250, 21 frames 36×36; off face PICT 1252) | snapped to 8 px; rect 1,1,0x23,0x23; HP 1; gravity 0; no sprite/tile callbacks; layer `−(2y + x)`; `+0x14c = p1`; 1270 animated | §2.4.5 |
| 1308 (0x51c) | chest (PICT 1308, 4 frames 33×31) | layer 0, gravity 0, one-way, rect 0,7,0x1c,0x1e, no hit callback, `+0xa6 = 4` | §2.4.2 |
| 1440..1449 (0x5a0..0x5a9) | geysers (PICT 1440..1442 face caches) | 1440..1444 → type 0x5a0 with kind `+0x14c = type−1440`; ~~1445..1449~~ 1445..1448 → 0x5a5 (+ two 0x5a0 children at x+0x48, x+0x90; 1449 = 0x5a9 takes the head arm first — ⚑ corrected (review 1c, 2026-10-03) #11, geysers.md §1); height `+0x154 = p1<<8` (default 0x6400), on `+0x158 = p2` (60), off `+0x15c = p3` (60), phase `+0xa6 = p4` (⚑ corrected (deepening 2026-10-03, geysers.md corr.): p4 is overwritten every frame by `C mod (p2+p3+1)` before any read — inert; raw 1006bcf4 vs 1006df90); 0x44-byte column buffer `+0x9c` | `HandleGeyserColumn` (not read here). Column pieces 0x5a9 hurt a lander (§2.4.10) [MED]. → geysers.md (§3 cycle, §4 column, §7 contacts) |
| 1450..1453 (0x5aa..0x5ad) | boulder spouts (PICT 1450, 4 frames 32×32) | layer 10, gravity 0 | when record[p1].p4 = 1 or record[p2].p4 = 1 (Button records, §2.4.5): every 50+rand(30) frames `MTNewSprite(0x6e1 + p4, …, SetupEnemyShotSprite)` — 0x6e1 'goblin boulders', 0x6e2 'bomb boulder' — with vx/vy: 1450 rand(300)−150 / rand(400); 1451 same / −3000−rand(300); 1452 +(0xaf0+rand(600)) / −(500+rand(700)); 1453 mirrored (l. 12706–12770) |
| 1460..1467 (0x5b4..0x5bb) | bridges ('Bridge - Wooden - Full', '… Left half', 'Bridge - Stone', …, 'Bridge - Rope') | gravity 0, layer 0, no hit callback; 1462/1465 are flipped halves; 1466 rope bridge has surface fn `+0x1e8 = .GetRopeBridgeHeight`; 1467 a layer-50 decoration | static solids; rect per type (l. 11704–11751) |
| 1470 (0x5be) | trampoline (PICT 1470, 4 frames 56×54) | layer 0x3c, gravity 0, one-way, rect 7,0x10,0x2c,0x37 | §2.4.11 |
| 1475 / 1476 (0x5c3/0x5c4) | spiked balls (face from cache `PTR_DAT_100a09f4+0x70`, ~~PICT NOT RESOLVED~~ **PICT 1487**, pickups-boxes-2 §4.1 ⚑ wave 2 (2026-10-04)) | rect 0x16,0x16,0x4e,0x4e; gravity 0x100; one-way; `+0x14c = 1`; 1475 `+0xa6 = 30` | touch: `HurtPlayer(p, ball, 0xa8, 1, 0x3c, coins 0 (51 %) or 5)` (l. 3899–3908). Tile bounce f = 0x40; a hard landing (\|vy\| > 0x300 for 1475) costs a bounce `+0x14c`; 1476 with no bounces left passes through tiles and is killed 0x1a0 px below the camera when vy > 0x5dc |
| 1490..1493 (0x5d2..0x5d5) | '!Enemy pipe facing up/down/right/left' | layer 1, gravity 0, no callbacks; spawned type `+0x15c = p1`; interval `+0xa6 = Deviation(p2)` (p2 = 0 → 100 written back); Setup generates one p1 sprite and kills it at once (face preload) [MED for purpose] | when no child is out: `GenerateSprite(p1, …, rec 0x200, now)`; the child slides out 3 px/frame with a clip edge (`+0x1b6..+0x1bc`) until its own length/3+4 frames, sound at frame 3; when it dies a new interval starts (l. 12842–12987) |
| 2805..2849 (0xaf5..0xb21) | decorations ('*Ziridium Mine Stuff' … '*Scraggly Vines 2') | no callbacks; rect 0 (except 2827, 2832..2836 graves/pedestal); one-way (not 2827); layer −1 (`p3 ≠ 0` → 10000, foreground); `p1 ≠ 0` → flipped; `p2 ≠ 0` → `+0xb8 = p2 + 0x10000` | static; graves 2833..2836 talk (§2.3); per-type reading and census: pickups-boxes-2 §9 ⚑ wave 2 (2026-10-04) |
| 2850..2869 (0xb22..0xb35) | ~~unnamed statues/props~~ rock outcrops, standable; no param read (pickups-boxes-2 §9 ⚑ wave 2 (2026-10-04)) | layer 0x96, rect 0x15,0x14,0x47,0x54, one-way; `+0xb8` 0x10006 / 0x10007 by ambient darkness > 4 / > 7; 2856: 0xb0005 | static |
| 2870..2889 (0xb36..0xb49) | ~~small props~~ mushroom clusters, intangible (pickups-boxes-2 §9 ⚑ wave 2 (2026-10-04)) | layer 0x78, rect 0, one-way | static |
| 2902..2909 (0xb56..0xb5d) | 'Sign', 'Book', 2904, 'Wall Map', 'Steel Plaque', 2907 timer, … | gravity 0, layer 0, one-way, no callbacks; 2902/2907 rect 4,7,0x22,0x1f and `+0x15c = 1` (standable) | §2.3 |
| 2910 / 2911 (0xb5e/0xb5f) | 'Door right' (6 frames 60×88) / mirrored | gravity 0, layer 0; rect 0,−0x40,0x18,0x98 (24 × 216 px; 2911: 0x24,−0x40,0x3c,0x98, flipped) | §2.4.3 |
| 2920..2928 | 'Bale of hay', 'Crate', 'Barrel', 'Barstool', chairs, tables | gravity 0, layer 0, per-type rect; 2922..2925 one-way | static furniture (not breakable) |
| 2929 (0xb71) | table in three parts | two child 0xb71 sprites (layers 100 and 1) | static |
| 2930 / 2931 | 'Mine cart' + 'minecar wheel' | push mass 0xa0, gravity 0x208, friction 6, children 0xb72 (layer 100) and 0xb73 | pushable; face by ground kind under it; wheel frame advances by vx>>9 (l. 13089–13157) |
| 2932 / 2933 (0xb74/0xb75) | ~~hanging object~~ **stalactite** (body PICT 2933, 24 × 32×54; stub PICT 2932, 12 × 32×20) ⚑ wave 2 (2026-10-04) | frame p1; HP p2 (default 150); `+0x14c = p3` (0x40); `+0x150 = p4` (100) (both unread); ~~child 0xb74 with a 0xb75 face~~ the placed body has the PICT 2933 face, its record-less child the PICT 2932 stub (pickups-boxes-2 §4.2) | a player shot subtracts its damage and shakes it `+0xa6 = d/20 + rand(d/40)` frames; at HP < 1 gravity 0xfa (falls); never hurts the player directly (pickups-boxes-2 §4.2) |
| 2940 / 2941 (0xb7c/0xb7d) | gate / weakened ice wall | rect 0,0,0x20,0x74; gravity 0; 2941 HP 300 and `+0x1b4 = 1` | §2.4.4 |
| 2951..2969 (0xb87..0xb99) | NPCs ('Geroditus', 'merchant', 'Limping Habnabit', …) | one-way, gravity 0; face/rect from a per-type cache; 2957 p3 ≠ 0 → faces left | §2.3 |
| 3070 (0xbfe) | snowball (PICT 3070..3072) | size `+0x14c = p1<<8` (default 0x20 px), max `+0x150 = min(p2,0x60)<<8` (default 0x60); mass 0x8c, friction 0x46, gravity 0x100 | rolls like a boulder and **grows**: `+0x14c += \|vx\|>>5` up to the max; rect = square from that size (half-side `size>>9`, ×0.8 while rolling); face 3070 / 3071 / 3072 by size with a draw scale `+0x1ae` (l. 13168–13232) |
| 3090..3092 (0xc12..0xc14) | '$Crate - bonus', '$Crate - question mark', '$Crate - exclamation point' | **HP 5**, `+0x88 = 1`, mass 0x78, friction 0x5a, gravity 0x100, `+0x90 = 0x100`, rect 4,0,0x23,0x20, `+0x14c = p1` | §2.4.1 |

### 2.3 Talkers and triggers in the Box arm of `.HitPlayerSprite`  [HIGH]
NPCs 2951..2969: if `+0xb0 == 0` and the global cooldown `PTR_DAT_100a06cc == 0`: cooldown 150,
`Conversation(p1, recIdx, npc)` (l. 3910–3921). 2907: if `+0xa6 == 0`: `+0xa6 = 100`, pitched sound
44000, timer `iRam100a5110 = p1·30 − 1` (l. 3982–3987). Signs/books 2902..2909 (not 2907) and
graves 2833..2836, on UP or first touch (p4 = 0), p1 ≠ 0, cooldown 0: cooldown 90, p4 = 1; 2902 with
p1 > 0 shows `STR# 500` string p1 titled "Wooden Sign"; others with p1 > 100 run `Conversation`
(l. 3989–4016) — already in world-data §3.4.

### 2.4 Mechanisms

#### 2.4.1 Crates 3090..3092 and `.KillCrate` drops  [HIGH]
Damage: a player shot with `+0xa6 == 0` subtracts its `+0xa4` (every spell does ≥ 100, the dagger
stab 100) and is killed; explosion effect 0x4b7 subtracts 10 (`.HitBoxSprite` l. 13436–13462);
a **spin-jump landing** (`PTR_DAT_100a0668`, physics §4) at player vy > 0x9c4 with spin cooldown
`PTR_DAT_100a060c == 0` and crate p4 ≠ 1 subtracts 100 (blocks 1250..1279: 1, with a sound); the
player rebounds with `vy = −|0.9·vy|` (`dRam100a1a20` = −0.9), keeps spinning if JUMP is held,
cooldown 5 (l. 4074–4115). HP ≤ 0 → `.KillCrate` from the shot path or from `.HandleBoxSprite`
(l. 13296–13302). Stacking/pushing: ordinary pushable solid (mass 0x78), layer re-sorted every
frame by `−(2y + x)`.
`.KillCrate` (main dump l. 47784–47929) **does nothing unless HP ≤ 0** (`lha r0,0xa4; cmpwi r0,0;
bgt` at `1006fab8..fac0`). It sets `+0xea = +0xe9 = 1` (record cleared → the crate never returns),
plays `_DAT_100a02fc`, throws 16 debris effects 0xc1b (and 16 × 0xc81 for 3092, or 8 × 0x442 dust
otherwise) outward from the bottom centre, then by **p1**:
- p1 = 2: **explosive** — sound `_DAT_1009fdec` and effect 0x4b7 at (centreX−0x30, centreY−0x36)
  (the effect's damage is the Effect reader's; it hits other crates for 10). No drop.
- p1 = 0 or 1: drop **p2 × p3** (p3 = 0 is written back as 1). Bonus types 1290..1293, 1055, 1300,
  1301, 1302, 1305, 1306, 1340, 1341 → `MTNewSprite(p2, x+0x16, y+0x15, layer 0x14, SetupBonus)`,
  re-centred, `vy = −2000 − rand(1000)`, `vx = rand(800) − 400` unless p3 == 1, `+0xb0 = 12`; any
  other p2 > 0 → `GenerateSprite(p2, x+0x16, y+0x15, rec 0x200, now, layer+1)` re-centred (items
  ≥ 3200 get gravity 0x151 and the same velocities; 1740 bats get random v and `+0xa6`). p1 = 0
  and 1 behave identically here.
- any other p1: nothing dropped.
The HitBoxTile "explode on landing at vy > 0x4b0 when p1 = 2" call (l. 13608–13611) is dead because
KillCrate's HP guard returns (HP is 5).
Census (98 placements of p1/p2/p3): no drop ×29 (incl. L62 recs 200/201 p1 = 1, p2 = 0) · 1290 ×18 ·
1291 ×20 · 1292 ×3 · 1293 ×10 · 1335 Invincibility sphere ×2 (L50, L52) · **1731 Blob enemy ×8
(L31)** · 3201 ×1 (L31) · 3202 ×1 (L50) · 3203 ×1 (L62) · 3206 ×4 · 3219 ×6 · 3223 ×2 ·
explosive (p1 = 2) ×22 (3091 ×9 in L22, 3092 ×10, 3090 ×3) · **L30 recs 256/265/266 have
p1 = 1290, p2 = 1/2 → drop nothing** (shifted params, reproduce as shipped).
Spawned with record index 0x200, a sphere/item reads its "record" at `hdr+0x2008..` (past the 511
records); that header area is zero in every level (`0x1ff4..0x25c3`, world-data §3.2), so a crate
sphere falls (p1 = 0) and an Invincibility sphere from a crate hides for 32000 [MED: in-memory copy
assumed identical].

#### 2.4.2 Chests 1308  [HIGH]
Closed face while p3 > 0, open face (frame 3) when p3 = 0. Locked = p1 ≠ 0, key item `|p1|`; while
locked and closed, the player within 0x4b px on both axes gets a balloon (`.CreateBalloonSprite`:
sprite 0xcb2 + the key's item face, ids 1..26 only). Opening (`.HitPlayerSprite` l. 3958–3980): on
any player contact while `+0x46 == 0`, if unlocked or `HaveItem(|p1|)` (item slot, flag 0) **and
p3 > 0**: `RemoveItem(|p1|)` if locked (the record's p1 is *not* cleared), sound `_DAT_100a03a0`,
`+0x46 = 1`. `.HandleBoxSprite` l. 12319–12407: lid frames `+0x46/3` up to 11; `+0xa6` −1 per
frame; at 0 with p3 > 0: one `MTNewSprite(p2, x+0x10, y+0xd, player layer+1, SetupBonusSprite)`
(**always the Bonus Setup**, whatever p2 is), re-centred, light removed if p3 > 2, `vy = −2000 −
rand(1000)`, `vx = rand(800) − 400`, gravity 0x151 if 0, `+0xb0 = 12`; `+0xa6 = 4`; **p3 −= 1 in the
record** (`li r0,0xc; sth 0xb0` / `li r0,4; sth 0xa6` / `subi; sth 0xc` at `1006e7a4..1006e7d0`).
So one item every 4 frames until empty; an emptied chest is persistently open and cannot be re-used.
Census: 30 chests (L1,2,3,4,11,21,51); drops 1305 ×{6,4,5,5,3,5,5,5,10}, 1302 ×{20,12,10,8,25,20,10,30},
1293 ×10, 1300 ×4, 1291, 3205, 3206 ×2, keys 3201 ×5, 3202 ×3; one locked chest (L1 rec 38, key 1).

#### 2.4.3 Doors 2910/2911 and keys  [HIGH]
`.HitPlayerSprite` l. 3923–3956: key needed = `|p1|` (0 = unlocked). If needed and not held
(`.HaveItem`, item slots only) nothing happens. If held: `RemoveItem(key)` (count −1), **record
p1 = 0** (persistently unlocked), sound `_DAT_100a03a8`; if unlocked already: sound `_DAT_100a03a4`.
Then 2910 opens (`+0x46 = 1`) only if the player's vx > 0, 2911 only if vx < 0 — the door is pushed
open in its facing direction. `.HandleBoxSprite` l. 13022–13088: face frame `|+0x46|>>1`; while
closed and locked the key balloon shows within 0x4b px; `+0x46` +1 per frame; at 7 the hot rect is
zeroed (passable); at ≥ 11 it stays 10 and **record p4 = 1**; p4 = 1 at load → open at once.
Key placements vs doors (key id: door levels / key sources): 1: L2, 4, 11, 21, 31 / chests L1, 2, 4,
11, 21, crate L31 · 2: L1, 2, 21, 50 / chests L1, 2, 21, crate L50 · 3: L3, 62 / crate L62 ~~only~~ and conversation `Mcnv` 205 in L3 (pickups-boxes-2 §8 ⚑ wave 2 (2026-10-04), reachability MED).
Keys are global inventory, so a key can be spent in a later level. Selecting a key shows the
"You don't need to select keys" hint (spells-items §4).

#### 2.4.4 Gates 2940 and weakened ice walls 2941  [HIGH]
`.HandleBoxSprite` l. 13234–13294. Open condition from p1: p1 ≥ 0 → record[p1].p4 == 1 (a Button);
p1 = −1 → `*_DAT_1009fed0 == 1` (set by `.KillDemon`, handler dump l. 21463); p1 = −2 → a test on the
2907 timer `uRam100a5110` (decompiled `(t < 0xffffffed) − (~(t ^ 0xffffffec) >> 31) & 1`; meaning
NOT RESOLVED). Open → rises 2 px/frame (`vy` step 0x200 in fixed point) until 100 px above its
start `+0x158`; closed → sinks back; a looping sound while moving; draw clip `+0x1bc = start − y + 7`
(+0x20 if p2 ≠ 0). 2941 never opens: it is broken only by a **player shot with damage exactly 300**
(`cmpwi r0,0x12c` at `1005ab7c`; `.HitPlayerShotSprite` l. 5663–5672): HP −0x50 (`subi r4,r4,0x50`
at `1005ab94`), flash/invuln 10; HP 300 → 4 hits. Damage 300 = the **Ice Pick** stab (§3) or an Ice
Wall shot at power 1; a Multi-Crystal-boosted shot (600, 900 …) does nothing. At HP < 1 it shatters
(particles, pitched sound `_DAT_100a01e0`). Manual: "The Ice Pick will allow Ferazel to break through
weakened ice cavern walls without magic." 2941 is placed only in L30, 31, 62 (10).

#### 2.4.5 Switch blocks 1250..1279 and Button links  [HIGH arithmetic; MED for "pressed"]
`.HandleBoxSprite` l. 13306–13322: when p1 = 2 the block is solid and visible only while
record[p2].p4 == 1 (else rect zeroed and the PICT 1252 outline face). All 14 placements (L4, L11)
have p1 = 2, p2 = a Button record (1320/1322), p4 = 1; p4 = 1 also disables the spin-stomp, and
1250..1279 ignore shots, so shipped blocks are indestructible. The same "record[N].p4 == 1"
test drives spouts 1450..1453 and gates 2940; that a Button writes its own p4 = 1 when pressed is
the Button reader's to confirm.

#### 2.4.6 ~~Crumbling ledge~~ Magic carpet 1080/1081  [HIGH arithmetic; ~~MED purpose~~ purpose from the decoded art and the riding code, pickups-boxes-2 §4.3 ⚑ wave 2 (2026-10-04)]
1080 is dormant; the player touching it (`.HitBoxSprite` l. 13541–13547) turns it into 1081 with
`+0x46 = 2`, tile hits on, `+0x15c = 30`, not one-way. While `+0x15c > 0` it wobbles (vy ±0x1e,
vx 0, no tile hits). Afterwards it is a one-way ledge; once ridden (`+0x186`) its lifetime
`+0x14c` counts down; every 4th global frame with `+0xa6 < 1` it flashes (`+0xb8 = 0x10009`, 10 or
30 frames apart); at 0 it is destroyed with particles. vx damped by 0x80/frame, vy ×0.8 per frame.
One placement (L22, p = 0 → lifetime −1 → never crumbles).

#### 2.4.7 Teleporters 1060..1062  [HIGH arithmetic; MED for the UP flag]
`.HitPlayerSprite` l. 4117–4179, after a landing: `PTR_DAT_100a070c = 1`; if the flag
`PTR_DAT_100a0708` is set (~~presumably UP~~ the teleport-fire pulse at charge 80, pickups-boxes-2 §3 ⚑ wave 2 (2026-10-04)): sound, mosaic out, find the idle-sprite table entry
(`DAT_100ac02c`, 0x200 × 0x220 bytes; entry +0xe = record index, +0xa/+0xc = x/y at queueing,
`.AddIdleSprite` main dump l. 4062–4115) whose record index == **p1**, move the player to that x/y
plus the player's offset from this teleporter, recentre the camera (120 `FindUpperLeftCorner` steps),
mosaic in, `PTR_DAT_100a0700 = −59`. Census: p1 pairs point at each other (e.g. L22 412↔411).

#### 2.4.8 Save point 1065  [HIGH arithmetic; LOW for the gate byte]
`.HitPlayerSprite` l. 4181–4219, in the **Box arm** (entered on handler == Box, `lwz r3,−0x73bc(r2)`
at `10056b18`) after `PlatformBounce` returns 1 (a **landing**; touching from the side does nothing),
type test `cmpwi r3,0x429` at `10057714`. No `+0xa6`/`+0xb0` gate applies (`.SetupBoxSprite` sets
`+0xa6 = 3`; that gate is the Bonus pickup gate, §1.2) — merged with save-continue §2.1, which
carries the step table with raw addresses ⚑ corrected (review 1a, 2026-10-03) #3, #9. Then only if the byte `0x100a53d6` ≠ 0 (also tested by
`.Pause` and `.CheckGameLoopKeys`; ~~meaning NOT RESOLVED~~ = no asynchronous gamma fade running, pickups-boxes-2 §3 ⚑ wave 2 (2026-10-04)) and p1 == 0: `_DAT_100a0684 += 2`; at
≥ 16 it becomes −150; p1 = facing+1 (lit face), `G+0x16` = facing, `.SavePointSave`; on failure p1
reverts to 0; on success two sounds and a gamma flash. A lit save point (p1 ≠ 0) never saves again.

#### 2.4.9 Tree Trunk (spell 4)  [HIGH]
A spell-4 shot landing on an FG floor spawns 712 at (centreX−8, centreY−6), layer 2, lifetime
`+0xa6 = byte _DAT_1009fd30 + 120` (on a BG ledge: 120), plus effect 2 with light 0x42
(`.HitPlayerShotTileSprite` l. 5792–5845). A spell-4 shot hitting a trunk sprite walks the
`+0x1d4` chain to the top segment, spawns 713 at (x, y−16) linked as its `+0x1d4`, lifetime
`byte + 120` (`addi r0,r3,0x78` at `1005a9d4`), and raises the previous top's lifetime to ≥ 35
(l. 5631–5655). `.HandleBoxSprite` l. 12416–12440: lifetime −1 per frame, blink `+0xb8` 0xb0001
(< 23), 0xb0000 (< 21), 0xb0002 (< 11), killed at < 1. A 713 that lands on ground becomes 712 with
gravity 0 (`.HitBoxTileSprite`). Trunks are ordinary solids for the player (Box arm).

#### 2.4.10 Geyser column hazard 0x5a9  [MED] → ⚑ corrected (deepening 2026-10-03, geysers.md corr.): one head 0x5a9 per column, created and moved by `.HandleGeyserColumn` [HIGH] (geysers.md §4, §7)
A player landing on a 0x5a9 piece with kind `+0x14c` 1 takes `HurtSprite(p, 0x70, ±400, −0x640,
0x3c, 0xc)` unless the Solid Acid sphere is active (`PTR_DAT_100a0648` and liquid 1); kind 2 takes
0x150 unless Solid Lava (liquid 2) or the Fire Charm (item 0x18) is held (l. 4023–4052); kind
names from spells-items §5 liquid kinds.

#### 2.4.11 Trampoline 1470  [HIGH]
On a landing with player vy ≥ 0xa5b: `vy = max(−6500, −(vy + 0.6·gravity))` (`dRam100a1a10` = 0.6,
`dRam100a1a08` = −6500), sound `_DAT_100a027c`, `_DAT_100a0718 = 1`, player airborne; the
trampoline plays its 4-frame squash (l. 4054–4072, 12773–12780).

## 3. Held item, thrown items and non-spell shot ids

### 3.1 The held-item sprite  [HIGH]
`.SetupPlayerSprite` creates one held-item sprite (`MTNewSprite(100, 0, 0, 0x14, 0x1ff,
SetupHeldItemSprite)`, handler dump l. 305; pointer `_DAT_100a065c`). Setup: type 100, layer 0x14,
no hit/tile callbacks, rect −2,2,0x1a,0x16. `.HandleHeldItemSprite`: v = 0, keeps type 100 and
layer 0x14, rect = ~~the face's rect inset 1 px horizontally~~ ⚑ corrected (review 1d, 2026-10-03)
#C3: the face's `+8` rect with left +1 / right −1 (raw `1004bec4–1004bee8`), which is the item's
**exact opaque bounding box**, and it is **not mirrored** when facing left — the hit box sits
+10 / 8 / 2 px further out than the drawn dagger / Dirk / Ice Pick [MED] → held-item-melee §1.5;
negative `+0xa6` counts up (nothing
writes it non-zero, so the boss/container gate `+0xa6 == 0` always passes for a stab — full read of the
held item, swing, placement and strike in **held-item-melee.md** §1; ⚑ corrected (review 1c, 2026-10-03) #10).
`.HandleItemUse` (main dump l. 43547–43650) runs each frame of a USE animation with counter
`c = _DAT_100a0698` stepping 1,2,3,4,5,−5,−4,…: player face = use frame `|c|−1` (crouch set when
crouching); held face = item `_DAT_100a5fd8`'s face (none if −1); **for c ≥ 3 the held sprite
becomes a player shot** (Handle = HandlePlayerShot, Hit = HitPlayerShot, HitTile =
HitPlayerShotTile) and is inert otherwise; position `.SetHeldItemPos`: x offset 0x2d/0x35/0x42/0x47/
0x54 and y offset 0x1e/0x1c/0x18/0x16/0x11 for |c| = 1/2/3/4/5 (+0xc y when crouching), + 0x16 y,
mirrored as `100 − off` and −0x20 when facing left; it inherits the player's water contact.
Damage `+0xa4`: item 0 dagger 100; 0x15 Vorpal Dirk 200 (`+0x158 = 1`, `+0xeb = 1`); **0x12 Ice
Pick 300** (`+0x158 = 4`, `+0xeb = 1`). `KillPlayerShot` ignores type 100, so a stab is never
consumed. No carry/lift-and-throw of boxes or pickups exists in the routines read: the player only
pushes boxes (§2.1) ~~[MED for the absence; `.HandlePlayerSprite` was not read whole]~~
⚑ corrected (review 1d, 2026-10-03) #C4: [HIGH for the item path — the USE-item switch has no case
that attaches a Box or Bonus; MED only as a global absence] → held-item-melee §1.9.

### 3.2 Thrown seeds, shot id 0x5a  [HIGH]
At c == 5 with item 6 (fire seeds) or 0x1a (Ziridium seeds) in use: `MTNewSprite(0x5a01, held
centre x, centre y − 4, layer 11, −1, SetupPlayerShotSprite)` (id 0x5a, power 1), `vx = 0x60e`
(mirrored left with x +0xc px), `vy = −0x60e`, plus the player's vx and any downward player vy;
Ziridium sets shot `+0xf4 = 1`; the in-use item resets to −1. The seed bounces on tiles and is only
killed by a tile hit at |vy| < 0x200 (`.HitPlayerShotTileSprite` l. 5777–5790). `.KillPlayerShot`
(main dump l. 45377–): id 0x5a → sound `_DAT_1009fdec`, screen shake (`_DAT_100a00fc = 3`,
`_DAT_1009ffa0 = 0x14`), explosion effect 0x4b7 at (x−0x2a, y−0x2a) tinted `+0xb8 = 0x10004` for
Ziridium, 8 dust effects 0x442 unless `+0xf0`.

### 3.3 Non-spell shot ids  [HIGH]
| id | what | source |
|---|---|---|
| 0x3c | **V Blade's second (downward) shot**, not an item | `.CastSpell` case 6: `MTNewSprite(power + 0x3c00, …)` (main dump l. 43948/43954) |
| 0x50 | **Pentashield orb** (one per shield; orbit table entry: angle step 0xa00, radius 0x30, spacing 360°/n) | `.UpdatePentSprites` `MTNewSprite(0x5001, 0, 0, layer+1, 0x1ff, SetupPlayerShotSprite)`, `+0x164 = −10` (l. 43477–43545); `KillPlayerShot` decrements `+0x168` and pops it at < 1; it cannot open containers (§1.5) and kills enemy shots it touches |
| 0x5a | thrown fire / Ziridium seeds | §3.2 |
| 100 | the held-item stab while c ≥ 3 | §3.1 |

## NOT RESOLVED
1. ~~`snd ` resource ids behind the TOC sound handles (`_DAT_100a02d4`, `_DAT_100a02cc`, …).~~ → closed: pickups-boxes-2 §1 ⚑ wave 2 (2026-10-04)
2. ~~Readers of Bonus `+0x168` (= p4) and the meaning of p4 = 1 on five 1291 placements.~~ → closed: pickups-boxes-2 §2 ⚑ wave 2 (2026-10-04)
3. ~~Gate byte `0x100a53d6` (save points, Pause, CheckGameLoopKeys); `_DAT_100a069c` (blocks every
   player contact); `PTR_DAT_100a0708` (teleport trigger, presumably UP);~~ → closed: pickups-boxes-2 §3 ⚑ wave 2 (2026-10-04); ~~the 2940 p1 = −2 timer test~~
   (closed: open ⇔ countdown `iRam100a5110 > −20`, raw `1006f538..1006f560`, triggers-background §1 —
   synthesis ledger B8).
4. ~~`HandleGeyserColumn` geometry and which liquid each geyser kind is; 0x5a9 creation~~ → closed by
   geysers.md §1 (kinds 0 water / 1 acid / 2 lava), §4 (column geometry, head 0x5a9 created by the
   column) (review 1a #4). ⚑ corrected (review 1c, 2026-10-03) #10.
5. ~~Face PICT of the spiked balls 1475/1476 (cache `PTR_DAT_100a09f4+0x70`); purpose of the 2932
   hanging object and whether it hurts when it falls; 1080's 1-px dormant rect intent.~~ → closed: pickups-boxes-2 §4 ⚑ wave 2 (2026-10-04)
6. ~~Who sets a falling rock's `+0x160 < 0` (1075/1076 are never placed; spawner not found here).~~ → closed: pickups-boxes-2 §5 ⚑ wave 2 (2026-10-04)
7. ~~Whether `Mcnv` conversations grant spells or items (merchants sell potions per the manual).~~ → narrowed: pickups-boxes-2 §8 ⚑ wave 2 (2026-10-04)
   (items yes, spells never; line reachability stays with INDEX item 3)
8. ~~Door `+0xa0` cleared by `.HitBoxSprite` for non-pickup contacts.~~ → closed: dead write, pickups-boxes-2 §6 ⚑ wave 2 (2026-10-04)
9. ~~Effect 0x4b7's damage to enemies~~ ~~/player~~ ~~(Effect class reader).~~ → closed: pickups-boxes-2 §7 ⚑ wave 2 (2026-10-04) (Player side closed:
   enemy-shots-and-damage §3.4, triggers-background-2 §2.2 — 0x70 while frame ≤ 7.)

## Proposed additions to physics.md §0
| off | type | meaning (this file) |
|---|---|---|
| +0x112 | i16 | (refines "slipperiness") also a one-shot horizontal kick in `.WallBounce`: `vx += 7.07·(+0x112)` on certain shape contacts, latched by `+0x181` (main dump l. 33288–33297, `dRam100a1910` = 7.07) [MED for which shapes] |
| +0x114 | i16 | friction: Bonus vx decays by it per frame (tail of HandleBonus); Box passes it to `ApplyFriction` |
| +0xa6 | i16 | Bonus: sphere hidden/respawn timer (> 0), shard life (< 0); Box: per-type timer (chest drop, door, trunk life) |
| +0xb0 | i16 | Bonus: pickup delay (> 0 blocks pickup); containers: 1 = unopened |
| +0xb8 | i32 | draw-effect word `mode<<16 \| arg` (0x1000N tints, 0xb000N blink states, 0x90000 underwater) [LOW for semantics] |
| +0x14c | i32 | Bonus: light-flicker timer; Box: per-type (crate p1, ledge lifetime, geyser kind, spiked-ball bounces, snowball radius) |
| +0x15c | i32 | Bonus: in-water-at-spawn (Xichron), light phase (upgrades); Box: signs "standable", ledge wobble, pipe spawn type |
| +0x160 | i32 | falling-rock dormant counter (< 0) |
| +0x168 | i32 | Bonus: p4 copy |
| +0x16c | i32 | dropped-coin lifetime (counts up from −240) |
| +0x182 | u8 | Box: box-box contact handled this frame |
| +0x188 / +0x18b | u8 | keep record: no write-back and no record clear on death / no clear on the final kill frame |
| +0x1aa / +0x1ae | i16 | draw rotation angle (boulder, snowball) / draw scale (snowball) |
| +0x1b5 | u8 | counted in the level totals (Xichron 1055/1056, secret 1059) |
| +0x1d4 / +0x1d8 | ptr | child sprites (balloon, next trunk segment, extra geysers, cart parts, pipe child) |
| +0xea | u8 | killed-for-good (crate); `.UpdateSprites` clears the record when set |

## Corrections to the existing bank
(wave-2 rows P1–P9: `pickups-boxes-2.md` corrections table) ⚑ wave 2 (2026-10-04)
1. spells-items §3 row 1055: the animated art is **PICT 1057** (10 frames 32×32); PICT 1055 'Bonus
   crystal' is never loaded by `.InitBonusSprite` (main dump l. 45711–45775). Row "every 100
   Xichrons": the counter is **set to 0**, not reduced by 100 (`10055ac4..acc`), so a 1056 taken at
   99 loses 99. [HIGH]
2. spells-items §4: item **0x12 is the Ice Pick** (PICT 3218 '$Ice Pick'; damage 300 = ~~the only
   damage that breaks 2941 ice walls~~ one of the 300-damage player shots that break 2941 ice walls — the
   test is `shot+0xa4 == 300` on any player shot, so the Ice Wall spell at power 1 and the Pentashield orb
   0x50 qualify too (⚑ corrected (review 1c, 2026-10-03) #2; handler l. 5663–5672, raw 10052648,
   1005949c); manual TEXT 132), not "Hammer?"; 'Hammer' is item 8 (PICT
   3208). Item **0x14 is the Light Orb** (PICT 3220). Items 7..13 are named Locket, Hammer, Poppyseed
   Muffin, Algernon Piece, Algernon Frame, Algernon, Gwendolyn (§1.8). [MED names, HIGH id↔PICT]
3. spells-items §2.1 "no shipped scroll was checked" → closed: the five shipped scrolls teach
   1, 5, 4, 3 (as 2→3), 6; spells 2 and 7 are never granted by scrolls or drops (§1.7). [HIGH]
4. spells-items §2.1 last row: 0x3c is V Blade's lower shot and 0x50 the Pentashield orb, not
   held/thrown items; the stab is type 100; 0x5a is the thrown seed (§3.3). [HIGH]
5. spells-items §5: a sphere is not consumed; its `+0xa6` duration is a hidden/respawn timer, and
   Invincibility's 32000 depends on **p2 = 0** (p2 ≠ 0 → 450) (§1.6). [HIGH]
6. spells-items §3 containers: Pentashield orbs (shot id 0x50) and shots with `+0xa6 ≠ 0` do not
   open them; 1307/3100..3109 persist as spent via record p4 = 1, 1303 is destroyed (§1.5). [HIGH]
7. spells-items §3 row 1057/1058/1059: 1057 is never spawned; 1059 is the **secret** counter
   (§1.10). world-data §4.3 "[MED: which counter is which not traced]" → `G+0x3ce` Xichrons,
   `G+0x496` secrets [HIGH], `G+0x306` enemies [MED, by elimination].
8. world-data §3.4 NOT-RESOLVED 1 (record byte +1): 0 in every Bonus and Box record and unread by
   these classes; per-class params for Bonus and Box are tabulated above (§1.3, §2.2).
9. INDEX NOT-RESOLVED 14 "the installer of `.GetRopeBridgeHeight`": `.SetupBoxSprite` installs it
   as the surface function `+0x1e8 = PTR_PTR_100a09f8` for type 1466 (0x5ba) rope bridges (handler
   dump l. 11738–11742) [HIGH]; the table `_DAT_100a0a00` is filled by `.InitBoxSprite` (0x10c
   shorts set to 0x32, then 15 segments of 16 interpolated from `DAT_100a671c`, main dump
   l. 47444–47478) [MED: the interpolation constants not resolved].
10. save-continue.md §2.1 (wave-1a sibling, already fixed there): 1065 is gated by the Box arm +
   PlatformBounce landing (`10056b18`, `10057714`), not by `+0xa6 == 0 && +0xb0 == 0` (Bonus gate).
   Any existing-bank text that says save points fire "on touch" should say "on landing". [HIGH]
11. physics.md §7 (review 1a #5, adj. 2–3): Bat HP → 1740 family 500 (`1007dcc0 li 0x1f4`), 1850
   family 100 (`1007dde0`), insects 200 (`1007e144`); "Statue/Box/Platform set +0x185" → the Statue
   does **not** (no `0x185` store in `100664a8–100665bc` / `10043138–100431c4`) — Box does (§2.2);
   Floater rect → shipped 1780 (0x23,1,0x3e,0x4b) at `10081550–1008155c`.
12. physics.md §2 water gravity (review 1a #2, adj. 4): `max(0.7·g, 0x100)` applies only when
   `+0x11c ≠ 0` at the routine's entry (`100375c8`); `+0x11c` is zeroed each frame (`100369ac`), so a
   sprite's first call uses dry gravity. Bonus 1055 (in-water flag) and 1350 (air bubble) write
   `+0x11c` directly and are the exceptions that can see it on a first call [MED: not traced past the
   write].
13. spells-items.md §2.1 (review 1a adj. 1): names only — id 2 "Ice Crystals", id 3 "Ice Wall", id 7
   second Ice-Wall icon (PICT 700 captions); §4 items: id 1 "Steel Key", id 5 "Health Potion" (PICT
   702 captions, §1.8).
