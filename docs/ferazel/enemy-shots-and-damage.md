# Ferazel's Wand 1.0.3 — enemy projectiles, cannons/statues/trails, and the player's damage intake

Code readings only; nothing behaviour-verified. Date 2026-10-03.
Sources: `ghidra/Ferazel_handlers.decompiled.c` ("handler dump l. N"), `ghidra/Ferazel_pef.decompiled.c`
("main dump l. N"), raw disassembly `ghidra/Ferazel_pef.disasm.txt` (addresses `1005xxxx`), data
constants via `tools/const.py`, TOC-slot → TVector → code resolution with `tools/pef.py`
(`word + 0x1009f840` = TVector, `TVector[0] + 0x10000000` = code), sound ids from `.InitSounds`
(main dump) + `snd ` names from the Sounds file, PICT sizes/names from the Sprites file.
Scope: (a) EnemyShot class — `.SetupEnemyShotSprite @ 1005ba5c`, `.HandleEnemyShotSprite @
1005bffc`, `.HitEnemyShotSprite @ 1005c9a8`, `.HitEnemyShotTileSprite @ 1005d034`, plus
`.InitEnemyShotSprite @ 1005b670`, `.KillEnemyShot @ 1005cc08` and every spawn site;
(b) `.TurnIntoCannoned`/`.HandleCannonedSprite`, `.TurnIntoStatue`/`.HandleStatueSprite`,
`.SetupTrailSprite`/`.HandleTrailSprite`, `.SetupShadowSprite`/`.HandleShadowSprite`;
(c) `.HitPlayerSprite @ 100556f4` except the Bonus arm (pickups/power-ups → spells-items.md §3,
§5), with `.HurtPlayer @ 1005473c`, `.ShieldBlock @ 10055434`, `.HurtSprite @ 10037034`.
Units as physics.md (px; velocities 1/256 px per frame). Labels per INDEX.md.

Class handlers are identified by TOC slot (the decompiler names the slot, not the routine):

| TOC slot | routine | | TOC slot | routine |
|---|---|---|---|---|
| 0x100a0488 | `.HandleEnemyShotSprite` | | 0x100a04a4 | `.HandleGremlinSprite` |
| 0x100a0830 | `.SetupEnemyShotSprite` (passed to `MTNewSprite`) | | 0x100a04a8 | `.HandleFrogSprite` |
| 0x100a052c | `.HandlePlayerSprite` | | 0x100a04ac | `.HandleFloaterSprite` |
| 0x100a04e8 | `.HandlePlayerShotSprite` | | 0x100a04b0 | `.HandleDemonSprite` |
| 0x100a047c | `.HandleBonusSprite` | | 0x100a04b4 | `.HandleDilloSprite` |
| 0x100a0200 | `.HandlePlatformSprite` | | 0x100a04b8 | `.HandleCrawlerSprite` |
| 0x100a0484 | `.HandleBoxSprite` | | 0x100a04bc | `.HandleChiefSprite` |
| 0x100a01c8 | `.HandleSeeSawSegSprite` | | 0x100a04c0 | `.HandleBlobSprite` |
| 0x100a01f8 | `.HandleStatueSprite` | | 0x100a04c4 | `.HandleBatSprite` |
| 0x100a0480 | `.HandleBackgroundSprite` | | 0x100a046c | `.HandleCrabSprite` |
| 0x100a0460 | `.HandleEffectSprite` | | 0x100a0470 | `.HandleSwarmMemberSprite` |
| 0x100a0490 | `.HandleWizardSprite` | | 0x100a0498 | `.HandleWalkerSprite` |
| 0x100a0494 | `.HandleWarriorSprite` | | 0x100a049c | `.HandleSalamanderSprite` |
| 0x100a045c | `.HandleCannonedSprite` | | 0x100a0900 | `.HandleGeyserSegSprite` |
| 0x100a04a0 | `.HandleRoachSprite` | | 0x100a0ac4 | `.HandleButtonSprite` |

[HIGH: each resolved through the TVector; e.g. `0x100a0488 → word 0x29fc → TV 0x100a223c → 0x1005bffc`.]

## 1. The EnemyShot class

### 1.1 Lifecycle  [HIGH]
- No placement records use the class: every enemy shot is created by `MTNewSprite(type, x, y,
  layer, −1, SetupEnemyShot)` from a spawner (§1.4). `MTNewSprite` zero-clears the 0x1fc record,
  writes type/position/layer and **calls the Setup immediately** (main dump `.MTNewSprite`
  l. 30596–30685, `FUN_1009f80c(pcVar4)`), so the spawner's velocity/field writes that follow it
  override Setup.
- `.SetupEnemyShotSprite` (handler dump l. 5871–6041; disasm 1005ba5c–1005bfd0): `.InitSprite`;
  `+0x84 = +0x86 = 0`; `+0x46 = FastRand(5)`; handlers Handle/Hit/HitTile; `+0xa6 = 0`;
  `+0x90 = 0x100`; **gravity `+0x110 = 0xaf`** (175) unless the type arm overrides; `+0xc0 = 0`;
  `+0x8c = 1`; per-type arm (table §1.2); finally `+0xc ← +8`, `+0xa ← +6`, fixed-point x/y from
  them.
- `.HandleEnemyShotSprite` (l. 6043–6337), per frame unless `+0xe9` (killed) or `+0x1b2`:
  `StandardSpriteHandles`; `+0xa6 += 1` (age, all types; disasm 1005c050); if `+0x14c > 0`:
  `−1`, kill at 0 (lifetime); type 1: `+0x46 −= 1`, type 0: `+0x46 += 1`; per-type animation
  (§1.2); `ApplyGravityAndSeparateFromTiles` (physics §2); `+0x154 −= 1` if > 0; **kill if
  `y > mapRows·32`** (`hdr+0xb282 << 5`); `StandardSpriteCleanup`; **kill if more than 1000 px
  left of the camera's left edge or more than 1000 px right of its right edge**
  (`camX − x ≥ 1001`, or `x − (camX + 640) > 1000`; camera x = `PTR_DAT_1009fe78+2`).
- Death is always `.KillEnemyShot` (main dump l. 45573–45694) or a direct `+0xe9 = 1`.

### 1.2 Type table (every type the Setup/Handle/Hit switches name)  [HIGH unless marked]

Hot rect = `SetRect(+0x34, l, t, r, b)` arguments (cell-local px). "dies on wall" = the bounce
counter `+0x150` starts at 0 so the first counted wall hit kills (§1.3). Damage = what
`.HitPlayerSprite` passes to `.HurtPlayer` (§3.5).

| type | made by | hot rect (l,t,r,b) → w×h | gravity | layer | faces (PICT, cells) | life / death | damage |
|---|---|---|---|---|---|---|---|
| 0, 1 | Walker 0x6a4 axe throw (type = thrower's facing byte) | default 8,8,16,16 → 8×8 | 0xaf | 0 | 0x6a7, 8 × 24×24; frame +1/−1 per frame (type 0/1), wraps 0..7 | dies on wall | 0x38 |
| 0x46a | Demon, Wizard, Xichra fireball | 6,6,0x2a,0x1a → 36×20 | 0 | 8 | 0x46a, 6 × 48×48, cycles 0..5 | dies on first **FG** hit; ignores BG tiles/water; sound 301 on death | 0x70 |
| 0x46b, 0x46c | ~~**no spawner found** (literal scan)~~ **no spawner exists**: every type passed to `MTNewSprite(…, SetupEnemyShot)` is resolved in enemy-shots-and-damage-2 §4.1 ⚑ wave 2 (2026-10-04) | 8,8,0x38,0x32 → 48×42 | 0 | 8 | PICT **0x46a** loaded at 64×64 (sic, disasm 1005b994/1005b9c4; PICTs 0x46b/0x46c 384×64 exist unused) | as 0x46a | 0x70 / 0xa8 |
| 0x6a9 | Walker 0x6a9 sword swing | 0,0,0x5a,0xe → 90×14 | 0 | 0x14 | none (`+0xc0 = 0` every frame) | `+0x14c = 2` → killed by the 2nd Handle | 0x70 |
| 0x6d6 | Walker 0x6d6 swing | 0,0,0x3c,0x18 → 60×24 | 0xaf (not cleared) | 0 | none | `+0xa6 = 3`, Handle does `+1` then `−1` → **never times out** (disasm 1005c050 vs 1005c0d4); dies on first wall/floor hit | 0x70, invul **0x24** |
| 0x6e1 | Walker 0x6e0 (param 1 = 0), box launchers | 8,8,0x18,0x18 → 16×16 | 300 | thrower+1 | 0x6e1 'goblin boulders', 8 × 32×32, cycles | bounces (§1.3), then splits into 3..5 × 0x6e6 | ~~0x38~~ **none on contact**: its own callback kills it before `.HitPlayerSprite` can see it; the shards hurt (enemy-shots-and-damage-2 §4.3) ⚑ wave 2 (2026-10-04) |
| 0x6e2 | Walker 0x6e0 (param 1 = 1), box launchers (param 4 = 1) | as 0x6e1 | 300 | thrower+1 | 0x6e2 'bomb boulder' | as 0x6e1 + explosion 0x4b7 at (x−32,y−32) + snd 435 | ~~0x38 (+ explosion §3.4)~~ none on contact; shards 0x38 or the explosion 0x70 (enemy-shots-and-damage-2 §4.3) ⚑ wave 2 (2026-10-04) |
| 0x6e6 | `.KillEnemyShot` of 0x6e1/0x6e2 | 6,6,10,10 → 4×4 | 0xaf | parent's | 0x6e6, 8 × 16×16, cycles | `+0x150 = +0x154 = 1` → dies on the first wall hit after its first frame | 0x38, only while `+0x164 ≤ 1` (age counter, Handle `+1`/frame) |
| 0x6f4 | Floater/'Wraith' 0x6f4 | 5,5,0x12,0xc → 13×7 | 0 | 0 | 0x45d, 15 × 24×24, cycles 0..14; tint 0xb0002/0xb0000/0xb0001 for age <3/<5/<7 | homing (§1.5); dies on wall | 0x70 |
| 0x709 | Frog | 8,3,0xf,0xc → 7×9 | 0 | frog+1 | 0x455 (vx ≤ 0) / 0x454 (vx > 0), 6 × 24×15 | dies on wall | 0x38 |
| 0x712 | Salamander, Bat, Gremlin | 8,3,0xf,0xc → 7×9 | 0 | spawner±1 | 0x457 (vx ≤ 0) / 0x456, 6 × 24×15; `+0x88 = 0` each frame | dies on wall; death: snd 301 + Effect type 0 at (x−8, y−12) | 0x38 |
| 0x71f | Warrior | 0x12,0x12,0x1e,0x1e → 12×12 | 0 | 0 | 0x71f, 16 × 48×48; facing `+0x17e = (vx ≤ 0)` | dies on wall | 0x70 |
| 0x753 | Dillo egg-bomb, Xichra drop | 4,0,0x14,0xe → 16×14 | **0x100 forced each frame** | 0 / 9 | 0x753 single 24×20 | fuse `+0x15c = 240` frames; flash (`+0xaa = 5`) every 45 frames; explodes (§1.6) | `+0xa4` (0xe0 / 0x1c0) |
| 0x754 | Dillo `.ShootSpines` | 8,3,10,8 → 2×5 | 0 | 0xc | 0x754 '18x18', 8 × 18×18, frame = direction | dies on wall; particles | `+0xa4` (0x38 / 0xe0) |
| 0x771/0x772 | Background traps 0x76c/0x76d; Xichra | 2,−4,0x3a,4 → 56×8 | 0 | 0xb / 0x4b0 | single 0x771/0x772 (60×8) | dies on wall (Xichra's: pass walls, §1.3) | `+0xa4` = 0x38 (trap) / 0x70 (Xichra) |
| 0x773/0x774 | Background traps 0x76e/0x76f | 0,0xc,8,0x30 → 8×36 | 0 | 0xb | single 0x773/0x774 (8×60) | dies on wall | `+0xa4` = 0x38 |
| 0x77b | Chief boulder | 0x20,0x20,0x50,0x38 at spawn, then per frame from the face rect inset (+4 top, +4 left, −3 bottom, −4 right) | 0x140 | chief−1 | 0x77b, 16 × 112×112, spins | **no tile collision** (`+0x1f8 = 0`); killed at `y > mapRows·32+32` | 0x70; **not destroyed** by the hit (§3.5) |
| anything else | (none found) | default 8,8,16,16 | 0xaf | — | 0x6a7 set, frame static | dies on wall | 0x38 |

Notes [HIGH]: Setup also sets `+0xa4` — 0x6e1/0x6e2: 200; 0x6d6, 0x6f4: 0x70; 0x753: 0x1c0;
0x771..0x774: 0x38; 0x709: **none** — the `0x709 → +0xa4 = 0x38` arm (l. 5948) is unreachable
(an earlier `== 0x709` arm, disasm 1005bbd0, wins; the second compare at 1005bcb4 is dead). Setup
sets `+0xeb = 1` (crunch callbacks) on 0x6e1/0x6e2 and `+0x88 = 0` on 0x6f4/0x46a..0x46c. The
type numbers deliberately reuse the spawner's type space: 0x6a9/0x6d6 are also Walker types,
0x6f4 the Wraith, 0x709 a Frog-range type, 0x712 the Salamander type, 0x71f Warrior range,
0x753/0x754 Dillo range, 0x771..0x774 the dart-trap range, 0x77b Chief range — class is decided by
`+0x4c`, never by the type alone.

### 1.3 Tile and sprite collisions  [HIGH]
`.HitEnemyShotTileSprite(s, pos, kind, layer)` (l. 6396–6560), skipped entirely when `+0x16c ≠ 0`
(set only on Xichra's darts → they fly through walls) or when the debug key 0x32 is held with the
debug flag:
- **FG** (`layer == 1`), only while `+0x154 == 0`: `fast = |vx| ≥ 0x1195 || |vy| ≥ 0x1965`;
  `.WallBounce(s, kind, pos, centre, 0xa0, hotRect, 0, 1)` (0xa0 = restitution 160/256, enemy-shots-and-damage-2 §4.6 ⚑ wave 2 (2026-10-04)); if it collided: type 0x753 → if
  `|vy| < 300` it stops (`vx = vy = 0`, gravity 0x200); other types → 0x6e1/0x6e2 play snd 436
  'Object Hit' (vol 0x55, random pitch); `+0x150 += 1` (once per frame: `+0x154 = 1`, re-armed
  by Handle); **kill when `+0x150 ≥ 0` or `fast`**.
- **BG / crunch** (`layer ≠ 1`), types outside 0x46a..0x46f only: kind < 100 → same as FG without
  the `+0x154` gate; 100..199 → `.WallBounceBG(kind−100)` treated as a hit every time; ≥ 200 →
  water: `.HandleUnderWater` if `+0x140 == 0`. Crunch callbacks (`layer 2`, only for `+0xeb`
  bombs) carry the direction nibble 1..15 as `kind`, so they bounce like FG kinds 1..15 (no
  crunching here) [HIGH reading; LOW intent].
- Bounce budget of 0x6e1/0x6e2: `+0x150 = −2 − FastRand(2)`, and when `FastRand(100) > 0x56`
  (13 %) `+0x150 += FastRand(5) − 3` → start value −6..−1: 1–6 counted hits, typically 2–3
  (disasm 1005bb3c–1005bb98).

`.HitEnemyShotSprite(shot, other)` (l. 6340–6393), no-op once killed:
- other = **player**: kills the shot unless its type is one of 0x6e6, 0x709, 0x712, 0x76c..0x775,
  0x6f4, 0x753, 0x754, 0x71f, 0, 1, 0x77b, 0x46a..0x46c (and never 1/0x6a9/0x6d6). Other =
  **player shot**: kills 0x6e1/0x6e2/0x753 (they explode). (The player's own callback kills most
  shots anyway, §3.5.)
- other = Platform type 0x584: `.PlatformBounce` (the shot rests on it).
- other = Statue, or Box outside 0x5aa..0x5b3 (so launchers don't eat their own bombs), and
  `+0x16c == 0`: if the solid is not one-way (`+0x185 == 0`) and has no surface function
  (`+0x1e8 == 0`) → kill (except 0x6e6); else `.PlatformBounce`, kill if it reports a contact.

### 1.4 Spawn sites and launch velocities  [HIGH unless marked]
All via `MTNewSprite(…, SetupEnemyShot)`; the TOC slot 0x100a0830 is loaded at exactly 17 sites
(`tools/tocrefs.py 100a0830`).

| spawner (handler dump l.) | type | trigger | position | velocity / speed | disasm |
|---|---|---|---|---|---|
| Walker 0x6a4 (10437–10465) | 0/1 (= its `+0x17e`) | anim step `+0x46 == 8` (snd 704 'throw'); next throw after `+0x158 + FastRand(26)` | x + 10 (+0x50 when `+0x17e == 0`), y + 0x14 | `+0x17e == 0`: vx +(0x618 + R(0x1c2)), else −(…); vy −(0x334 + R(0x1c2)); 9 % (`R(100) > 0x5a`, only when `+0x17e == 0`) vx += R(0x578), vy −= R(0x578) | — |
| Walker 0x6a9 (10712–10725) | 0x6a9 | attack counter `+0xb2 == 0x10` (snd 304 at 6) | cx − 0x50·`+0x17e`, cy − 10 | vx +3000 when `+0x17e == 0`, else −3000 | 100690b4/100690bc |
| Walker 0x6e0 (10795–10812) | 0x6e1 + record param 1 | `+0xb2 == 8` | cx − 0x10 + (−0x1c if `+0x17e == 0` else +0x1c), cy − 0x26 | vx −(0x514 + R(0x28a)) when `+0x17e == 0`, else +(…); vy −(0x6a4 + R(0x28a)); `+0xa6 = −30` (unused by the shot) | — |
| Walker 0x6d6 (10918–10930) | 0x6d6 | anim `+0x46 == 8` (snd 704 pitched 45000 at 5); repeat after 10 + R(12) | x + 0x99 (right) / x + 3, y + 0x2c | none | — |
| Box 0x5aa..0x5ad launchers (12706–12760) | 0x6e1 + own param 4 | timer `+0xa6` reaches 0 **and** the record named by param 1 or param 2 has param 4 == 1 (a linked switch; census and the inert p = 0 keys: pickups-boxes §2.2 row 1450..1453, ⚑ wave 2 corr (2026-10-04) T2 W6); re-arm 50 + R(30) | own x, y | 0x5aa: vx R(300)−150, vy R(400); 0x5ab: vx R(300)−150, vy −3000−R(300); 0x5ac: vx 0xaf0+R(600), vy −(500+R(700)); 0x5ad: mirror of 0x5ac | bl 1006e9a0/ea00/ea64/eacc; 1006ea40, 1006ea84 |
| Background traps 0x76c..0x76f (15174–15210) | type + 5 | sight line: player within ±`+0x150` of the trap's axis and in front, at step 0x12 (snd 499 'ArrowShootSound') | trap + (±0x20/0x2a) | 0x76c→0x771 vx +0x1000; 0x76d→0x772 −0x1000; 0x76e→0x773 vy −0x1000; 0x76f→0x774 vy +0x1000 | 10074a98…10074af4 |
| Bat (17020–17038) | 0x712 | `+0x14c == 1` bats, cooldown `+0x154` 0, `|playerCy − cy| < 30` | cx − 0xc, cy − 7 | vx −0x708 when `+0x17e == 0`, else +0x708; vy = bat vy / 4; cooldown 60 + R(75). Also adds vx to the shot's **integer** x and bat vy to its integer y (unit mismatch, overwritten by the next integration) [HIGH code; LOW intent] | 1007eec4/1007eed0 |
| Gremlin (17760–17777) | 0x712 | `+0x154 == 7` (fire-hiss snd 495/496 at 1) | x + 4, y + 6 | impulse 0x708 in direction `+0x158` (36-step table, physics §6) + vx of `+0x1d4`; hot-rect bottom −3; dir 4 → facing 1, `+0x1aa = 0xdc`; dir 0xe → `+0x1aa = 0x140` (draw rotation 220° / 320°, enemy-shots-and-damage-2 §4.5 ⚑ wave 2 (2026-10-04)) | 100804f0 |
| Floater/Wraith (18121–18132) | own type (0x6f4 in all 7 placements) | step `== 0x1d` (snd 504 'elecshot') | x + 6/0x5e − 0xc, y + 10 | at rest; `+0x15c` = direction to player (unused by the handler) | — |
| Frog (18397–18429) | 0x709 | attack `+0x46 == 6` | cx + 0x5a·`+0x17e` − 0x2d, cy − 0x14 | vx −2000 when `+0x17e == 0`, else +2000; tint by frog `+0x15c`: 1 → 0x1000c (and `+0xa4 ×2`), 2 → 0x10017, 3 → 0x1000f (`×4`), 4 → 0x1000b (`×3`) — the multipliers act on `+0xa4 = 0` and the damage path never reads it: **dead** | 1008270c/10082718 |
| Salamander (18860–18872) | 0x712 | attack `+0x46 == 0xc` | cx + 0x3c·`+0x17e` − 0x2d, cy − 0x19 | vx −2000 when `+0x17e == 0`, else +2000 | 10083410/1008341c |
| Dillo (19715–19745) | 0x753 | attack mode 2 (snd 498 'Egg Drop') | face-rect edge, cy − 8 | vx +0x200 when `+0x17e == 0`, else −0x200 (opposite convention); vy −0x320; `+0xa4` 0xe0 (dillo 0x74e) else 0x1c0 + tint 0x1000b | 10086f44 |
| Dillo `.ShootSpines` (main 52796–52880) | 0x754 ×5 (×7) | mode 0 (5 spines); apex of a jump (7) | around cx/cy | speed v = 0x900 (type 0x74e, `+0xa4 0x38`) or 0xbb3 (`+0xa4 0xe0`, tint 0x1000b); dirs: left, right (vy 0), up-left/up-right (±0.7v, −0.7v; 0.7 = `_DAT_100a1c20`), up (0, −v); the 7-spine call adds down-left/down-right (±0.7v, +0.7v). Snd 463 'dillo shoot' | 100864c0/100864d8 |
| Warrior (20238–20252) | 0x71f | attack `+0x46 == 9` (snd 704 at 7) | cx ∓ 0x30 − 0x18 (−0x30 when `+0x17e == 0`), cy − 0x25 | vx −0xb00 when `+0x17e == 0`, else +0xb00 | 100882f4 |
| Demon (21101–21130) | 0x46a | attack `+0x46 == 4` | x + 0x60·facing + 8, y + 0x28 | from rest, one impulse 0x708 toward the player (snd 300 'Fireball') | 1008abc0 |
| Chief (21617–21660) | 0x77b | `+0x46 == 7` (snd 704 pitched) | x − 0x11 / x + 0xa1, y + 0x33 | vx +(4000 + R(500)), vy −(1200 + R(150)); if `|playerCx − cx| < 240`: vx ×0.8, vy = +2000; finally vx negated when `+0x17e == 0`. (A second branch for `< 155` px sets vy 0xc80 but is unreachable — disasm 1008be24–1008be38.) Start frame 15 | 1008bd9c, 1008bdb4, 1008bdec |
| Wizard (22166–22195) | 0x46a ×3 | `+0x46 == 8` (snd 300) | cx − 0x18, cy − 0x18 | (0x1194, 0), (0x1068, −0x5dc), (0xce4, −0xbb8), vx negated when `+0x17e == 0` | 1008ce80, 1008ced4, 1008cf28 |
| Xichra `.DoXichraShot(n)` (main 53749–53785) | 0x46a ×n | fight script (n = 3 at step 0xc) | cx − 0x18, cy − 0x18 | aimed at the player; shot i offset by (i − n/2) × 10°; impulse 0xa28, or 0x10c2 when Xichra-data byte +0x13 is set (snd 300) | 1008e488/1008e49c |
| Xichra drops (23093–23128) | 0x753 / Box 0x5c4 / Box 0x434, or dart pair 0x771+0x772 | fight script | across the arena | darts: vx +0x1068 / −0x1068, `+0xa4 = 0x70`, `+0x16c = 1`, layer 0x4b0 | 1008f1ec/1008f234 |

R(n) = `FastRand(n)` (0..n−1). `+0x17e` is the spawner's facing byte; which screen direction it
means differs per class (its sheet orientation), so the sign rule is given raw. Positions/triggers
are given for orientation; the per-class readers own the state machines that reach these steps.

### 1.5 Homing (0x6f4)  [HIGH]
While age `+0xa6 < 20`, each frame: `dir = FindDesiredDirectionGeneric((playerCy + 8,
playerCx), (y + 0xc, x + 0xc))`, then `FUN_1003f218(s, dir, 0x8c)` — that routine **adds** an
impulse of the given magnitude in one of 36 ten-degree directions (same table as physics §6) to
vx/vy. The shot is spawned at rest, so it accelerates toward the player for 20 frames (|v| ≤
20·0x8c = 2800) and then coasts straight (disasm 1005c2bc `li 0x8c`). The ordering
"(target, from)" of `FindDesiredDirectionGeneric` is read from this and the Xichra call [MED].

### 1.6 Kill effects (`.KillEnemyShot`, main dump l. 45573–45694)  [HIGH]
- 0x6e1/0x6e2: spawn `FastRand(3) + 3` shards 0x6e6 (3..5) at (x + R(16), y + R(16)); shard i
  (1-based): `vx = parent vx + R(200i) − 100i`, `vy = parent vy + R(200i) − 100i`; each shard
  `+0x154 = +0x150 = 1`. Then 0x6e1: removed; 0x6e2: snd 435 'explosion' + Effect 0x4b7 'big
  explosion' at (x − 0x20, y − 0x20), layer 0xc.
- 0x712: snd 301 + Effect type 0 at (x − 8, y − 0xc), layer 0xb.
- 0x753: snd 435 + Effect 0x4b7 at (x − 0x2a, y − 0x2a); then a 4×4 grid (8 px pitch) around
  (x − 4, y − 10) where every 2nd cell (8 in all) gets an Effect 0x442 at (cell − 0x18) with an
  impulse of 400 + R(150) pointing from the shot centre to the cell and frame R(7).
- 0x76c..0x775 and 0x754: face exploded into particles (`ExplodeFaceIntoParticles(…,1,1,1,100,100)`).
- 0x6f4: particles (…,1,1,1,0,0x65). 0x46a: snd 301 pitched 44000 + R(13000), particles
  (…,2,2,2,0x96,0x66). Everything else: just removed.
- The routine does not test `+0xe9`; when two callbacks both reach it in one frame (§3.1), a
  0x6e1/0x6e2 would split twice — ~~whether that ordering occurs depends on active-list order
  [NOT RESOLVED]~~ ⚑ wave 2 (2026-10-04): never against the player (the player has no hit callback, enemy-shots-and-damage-2 §4.2);
  only a box-launcher bomb touching a Pentashield orb can split twice, and no shipped level holds
  both (enemy-shots-and-damage-2 §4.3) [HIGH code; HIGH census].

## 2. Cannons, statues, trails, shadow double

### 2.1 Being fired from a cannon  [HIGH arithmetic; MED for "cannon" naming]
Cannons are Background types 0x442..0x44b (1090..1099; 116 placements). `.HitBackgroundSprite`
(handler dump l. 15297ff) loads the touching sprite unless it is Background, Statue, already
Cannoned, Button, EnemyShot or Effect, or of type 0x41f/0x434/0x771/0x772/0xb7c/0x5c3/0x5c4, or
its `+0x130 < 0`. A player shot instead bounces off cannons whose record param 1 is 0x69/0x6a
(turning them) — other reader's scope.
`.TurnIntoCannoned(s, cannon) @ 10058594` (main dump l. 45292–45335): refused for a dead player
(`s == player && hp ≤ 0`) and for a Bonus with `+0x168 == 1`; snd 484 'cannon load' (vol 0x97);
saves `+0x4c/+0x5c/+0x1f8` to `+0x1ec/+0x1f0/+0x1f4`; `+0x130 = 15`; handler := Cannoned, hit
and tile callbacks cleared, v = 0, `+0x1e4 = cannon`, centre snapped to the cannon's centre,
light removed; player → `_DAT_100a05b8 = 1`. The cannon gets `+0x154 = 6`.
`.HandleCannonedSprite` (handler dump l. 4640–4887), every frame:
- invisible (`+0xc0 = 0`), centre kept on the cannon, v = 0, layer 2; player: in-cannon flag
  `_DAT_100a05a0 = 1`, camera follows, a dead player (`hp < 1`) fires at once (`+0x130 = −1`),
  `.DoubleSpeedTrail` keeps running.
- countdown `+0x130 −= 1`; **for the player in a cannon whose record param 1 < 0, the last step
  (from 1) only happens while JUMP (action 5) is held** — the player chooses when to fire.
- fire when `+0x130 < 1` **and** the cannon's frame `+0x46` is a multiple of 4: speed
  `s = cannon+0x164`, direction `d = cannon+0x46 >> 2`:

| d | 0 | 1 | 2 | 3 | 4 | 5 | 6 | 7 |
|---|---|---|---|---|---|---|---|---|
| (vx, vy) | (0, −s) | (0.707s, −0.707s) | (s, −0.235s) | (0.8s, 0.35s) | (0, s) | (−0.8s, 0.35s) | (−s, −0.235s) | (−0.707s, −0.707s) |

  (doubles 0x100a19e8 = 0.707, 19e0 = 0.235, 19d8 = 0.8, 19d0 = 0.35.)
- `+0x130 = −5` (player) / −35 (others) — `StandardSpriteHandles` counts a negative `+0x130` up
  to 0, so this is a re-load grace period (the load test requires `+0x130 ≥ 0`).
- muzzle smoke: three Effect 0x442 at `cannonC + 1.5·v/256 − 24` (doubles 19c8 = 1.5, 19c0 =
  1/256, 19b8 = 24), two jittered ±R(8), random facing, frame R(4); recoil when cannon param 1
  ≥ 0: cannon position −= 1.6·v (19b0 = 1.6).
- a fired sprite of type 0x5a (player shot spell id 0x5a — the thrown seeds, spells-items §4)
  gets gravity 0x15e; the sprite is moved one step (x += vx, y += vy); if `vy > 0`, vx ×0.7,
  vy ×0.55 (19a8, 19a0); velocity set; snd 483 'cannon shoot'; handlers restored. Player:
  `_DAT_100a05b8 = 1`, launch face `_DAT_100a079c + _DAT_100a05b4·0x34`, climb/spin flags 0.

### 2.2 Statue spell (`.TurnIntoStatue @ 10043138`, `.HandleStatueSprite @ 100664a8`)  [HIGH]
`TurnIntoStatue(s)` (main dump l. 38018–38043; 12 call sites, physics §7): snd 302 'statue hit'
(vol 0x32); saves the three procs to `+0x1ec/+0x1f0/+0x1f4` and the tint `+0xb8` to `+0x134`;
`+0x130 = 0x78` (120); handler := Statue, hit := `.HitBoxSprite`, tile-hit := `.HitBoxTileSprite`
(it behaves as a Box: solid, can crush); v = 0.
`HandleStatueSprite` (handler dump l. 9853–9884): adds a light once (`.AddLight(…, 0x21)`); tint
0x1000b; `+0x130 −= 1`; v = 0 (no gravity: a statue hangs where it was hit); layer 2; for the
last 19 frames the tint is dropped on odd counts (blink); at `+0x130 < 1`: procs and tint
restored, **`hp −= 200`** (no death test here — the restored handler sees it), light removed.
The player stands on statues (`.HitPlayerSprite` Statue arm = `.PlatformBounce`, §3.2).

### 2.3 Double-speed trail (`.SetupTrailSprite @ 1004b3b4`, `.DoubleSpeedTrail @ 1004d370`)  [HIGH]
`.SetupPlayerSprite` creates five trail sprites (type 1, record index 0x1ff, layer player−1) and a
5-entry history (16 B each: sprite ptr +0, face +4, (y,x) +8, facing +0xc) at `PTR_DAT_100a051c`.
`HandleTrailSprite` = `StandardSpriteHandles` + `StandardSpriteCleanup` only. Each frame
`.DoubleSpeedTrail` shifts the history (entry 4 ← current face/position/facing); when Double
Speed is active (`PTR_DAT_100a0620`) trail i uses entry `s = (i>>1)+2` — even i at that entry,
odd i at the midpoint of entries s and min(s+1, 4) — with tint i0 0xb0002, i1 0xb0000, i2 0xb0001,
i3/i4 0; otherwise their faces are cleared. Tint meanings (fade levels) [LOW]. ⚑ corrected (review
1d, 2026-10-03) #C7: trail 4 = the current pose (on the player); history entries 0/1 are recorded
but never shown [HIGH] → held-item-melee §3.

### 2.4 Shadow double (`.SetupShadowSprite @ 1004b7d4`, `.HandleShadowSprite @ 1004b4f0`)  ~~[MED]~~ [HIGH unless noted] ⚑ corrected (review 1d, 2026-10-03) #C6
The Shadow-Double power-up (spells-items §5) makes `.HandlePlayerSprite` spawn sprite 0x1b39 with
this Setup (handler dump l. 929–940; killed when the flag clears). No hit/tile callbacks.
`.HandlePlayerSprite` records a 14-entry pose history (16 B: (y,x) +0, on-ground +4, face +8,
facing +0xc; newest at +0xd0) unless `PTR_DAT_100a0674` is set (l. 2793–2869), and moves a
replay index `PTR_DAT_100a0590` (0..0x1b, step 2) down toward 0 (13 frames behind) normally and up
to 0x1b (in step) while the player rides a sprite (`PTR_DAT_100a0558` = ridden sprite, handler dump
l. 742) (l. 2772–2790). `HandleShadowSprite`
draws entry `index>>1` with tint 0x1000b, swapping in alternative faces while casting
(`_DAT_100a06d4`, `_DAT_100a06d0`) or with `.ShadowBob` bobbing (`_DAT_100a05c0`, table at
`DAT_100a5fda`) [HIGH arithmetic, ~~MED meanings of the flags~~ flags named, enemy-shots-and-damage-2 §4.7 ⚑ wave 2 (2026-10-04)]. ⚑ corrected (review 1d, 2026-10-03)
#C6: face rule — not casting: crouch face if the player crouches and the entry is grounded, else the
entry's face while moving, bobbing entry face when still and airborne, breathing face (bob reset)
when still and grounded; casting: cast face from the player's current wand phase. Its hot rect is
never set (empty) → **it collides with nothing**; only the 0-damage `.CastSpell` copies act. While
the player is still nothing is recorded, so the double freezes 13 moving frames behind ["still"
flag compares against the last drawn position, whose draw-routine writer is MED]. In the last 210 of its 600 frames it is killed and re-spawned every 15 frames
(blink). `.ShadowBob`: 24-short table ±10 px, 47-frame cycle; the re-sync search compares the same
`table[phase]` (byte index `phase·2`, overrunning past phase 24) 24 times → phase 46 or 0 — a
shipped bug to reproduce [HIGH] → held-item-melee §2.

## 3. The player's damage intake — `.HitPlayerSprite @ 100556f4`

### 3.1 How it is called  [HIGH] ⚑ wave 2 (2026-10-04) (corrected: the player is not a callback sprite of `.MTCollideSprites`)
~~`.MTCollideSprites @ 100326cc` (main dump l. 30181–30335) tests every active sprite with a hit
callback against every other (…), and for each intersecting pair calls **both** callbacks
(A(B), then B(A) if B has one); with several partners the nearest is processed first.~~
The player's hit callback `+0x5c` is **0** (`.SetupPlayerSprite` `li r31,0` 1004af44 → `stw r31,0x5c`
1004afd4; `.HandlePlayerSprite` re-zeroes it, 1004f55c/1004f794), so `.MTCollideSprites` only ever
calls the *other* sprite's callback with the player as partner. **`.HitPlayerSprite` is reached only
through `.MTCollideSpecialSprite(player, HitPlayerSprite)`**, a second pass that `.HandleSprites`
runs after `.MTCollideSprites` (raw 10007c30/10007c38/10007c64; the TVector slot 0x1009fdd4 is
loaded only at 10007c60). Exact passes, order and the active-list rule: enemy-shots-and-damage-2 §4.2. `.HitPlayerSprite`
itself never checks the partner's `+0xe9`; the special pass skips killed partners when it gathers
them [HIGH; consequences enemy-shots-and-damage-2 §4.3].

### 3.2 Gate and dispatch order  [HIGH]
`.HitPlayerSprite(player, other)` (handler dump l. 3155–4637):
1. dying (`_DAT_100a069c > 0`) → nothing. Spirit form (Mist potion, `_DAT_100a0578 > 0`) →
   only Bonus sprites are processed.
2. Bonus with `+0xa6 == 0 && +0xb0 == 0` → pickup arm (l. 3282–3832; spells-items §3/§5).
3. **Platform** (l. 3834–3858): types 0x582/0x583 whose record param 1 == 2 are ignored; else
   `.PlatformBounce`; then type **0x57d** (1405, 9 placements): if the player's centre y ≥ the
   platform's, or `vy < −0x200`, and `+0x116 ≤ 0` and not riding it → snd 450 'Big ouch',
   **hp −= 0x70 directly** (no knockback, no coins), `+0x116 = 60`, `+0xaa = 12` (disasm
   10056a98–10056b04). Otherwise `.CheckGroundCeilingHitEffects` (physics §8.7).
4. **Box or SeeSaw segment** (l. 3859–4214) — §3.3.
5. **Statue** (l. 4216–4223): `.PlatformBounce` only.
6. Sprites whose handler is **not** Crawler, Roach, EnemyShot, Walker, Warrior, Gremlin, Demon,
   Chief, Wizard, Frog, Bat, Blob or SwarmMember (l. 4224–4511) — §3.4.
7. The listed enemy classes and every EnemyShot — the generic path §3.5.

### 3.3 Box / SeeSaw arm  [HIGH arithmetic; MED for object names]
Damage-relevant cases (Box types are placed or thrown by Xichra):

| type | condition | effect | disasm |
|---|---|---|---|
| 0x433 (falling object, small) | `+0x160 ≥ 0`, its centre above the player's, its `vy > 599` | `HurtPlayer(0x38, blood, invul 30, coins 0)` + `.KillBox` | 10056c50 |
| 0x434 (falling object, large; Xichra drop) | same; `+0x160 < 0` → arm skipped entirely | `HurtPlayer(0x70, blood, 60, 0)` + `.KillBox` | 10056cac |
| 0x5c3/0x5c4 (1475 placed ×13; Xichra drop 0x5c4) | any contact | `HurtPlayer(0xa8, blood, 60, coins R(100)<51 ? 0 : 5)` | 10056d0c |
| 0x5a9 (geyser head, spawned by `.HandleGeyserColumn`) | `.PlatformBounce` returned 1 and liquid kind `+0x14c > 0` | kind 1: immune while the Solid-Acid power-up is active (`PTR_DAT_100a0648` and `PTR_DAT_100a063c == 1`), else 0x70; kind 2: 0x150, immune with Solid-Lava (`063c == 2`) or a held Fire Charm (inventory scan for item 0x18 with slot byte +0xb == 0); `HurtSprite(dmg, kvx ±400 away from it, kvy −0x640, invul 60, flash 12)`, hurt-stun on success | 1005725c |

Non-damage cases in the same arm, listed so a replica keeps the dispatch order (owned by the Box
reader): 0x434 with `+0x160 < 0` return; 0xb87..0xb99 conversations (cooldown `PTR_DAT_100a06cc =
150`); 0xb5e/0xb5f key doors; 0x51c chest/lever; 0xb5b timer trigger (`iRam100a5110 = param1·30 −
1`); signs 0xb56..0xb5d and 0xb11..0xb14 on UP or param4 == 0 (`STR# 500`); then `.PlatformBounce`
(abort unless it returns 1); 0x5a9 above; 0x5be spring (`vy = max(−6500, −vy − 0.6·gravity)`
when `vy ≥ 0xa5b`, snd 604); **crate stomp** (below); 0x424..0x426 teleporters; 0x429 save point.

**Stomp = crates only** [HIGH]: when the spin flag `PTR_DAT_100a0668` is set, the crate's HP > 0,
the stomp cooldown `PTR_DAT_100a060c == 0`, the player falls faster than 0x9c4 (disasm 10057374)
and the crate's record param 4 ≠ 1: types 0x4e2..0x4ff lose 1 HP (snd 423 'rock crack'),
0xc12..0xc1b lose 100 HP; the player rebounds with `vy = −|0.9·vy|` (double 0x100a1a20 = −0.9);
holding DOWN keeps the spin (snd 427 'player magic spin'), otherwise it ends; cooldown 5 frames.
**No enemy class reacts to the player's body**: `PTR_PTR_100a052c` (the player handler) appears in
no enemy Hit routine (scan of both dumps: only SuperSpring, HitPlayerShot, HitEnemyShot, HitBonus,
HitBox 0x438, HitButton). Enemies are damaged only by player shots, the held weapon (§5
correction 1), statues/boxes, explosions and liquids.

### 3.4 Hazard arm (step 6)  [HIGH]
| other | condition | damage call | disasm |
|---|---|---|---|
| Salamander (body) | always | `HurtPlayer(0x70, no blood, 60, coins R(100)<81 ? 0 : 3)` | 10057cc0 |
| Floater/Wraith | its `+0x46 > 12` | same as Salamander | 10057d1c |
| Crab | always | `HurtPlayer(0x70, 0, 60, R(100)<61 ? 0 : 3)` | 10057d6c |
| Dillo 0x74e | always | `HurtPlayer(0xe0, 0, 60, R(100)<61 ? 0 : 4)` | 10057dc8 |
| Dillo 0x74f | always | `HurtPlayer(0x1c0, 0, 60, 6)` | 10057df0 |
| Dillo, other types | — | nothing | |
| Background fire 0x4b8, 0x4bb..0x4bd | unless the Fire Charm is held **and** its `+0x14c ≤ 0` | `HurtPlayer(0xe0, blood, 60, 0)`, then continues below | 10057e74 |
| Background 0x5c8..0x5d1 | player `+0x116 == 0` and its `+0x170 == 1` | `HurtPlayer(0xe0, blood, 60, 5)` then `+0x116 = 30` (overrides 60); solid via `.PlatformBounce` unless one-way | 10057ebc |
| Background 0xbf4 'Rotating sword' (53 placements) | player hot rect (top +6, bottom −8) crosses the blade segment from radius 16 to 88 px at angle `+0x46` (tables `_DAT_100a0168`/`_DAT_100a0164`; doubles 0x100a19f8 = 16, 19f0 = 88) | sword vx temporarily ±0x8fc (away side) so the knockback pushes the player away; `HurtPlayer(0x70, 0, 60, R(100)<51 ? 0 : 4)` | 10058338 |
| Background 0x730..0x733 (1842/1843 'Retracting spikes floor/ceiling') | player `+0x116 == 0` | climb state 0, `PTR_DAT_100a05f0 = 3`; `HurtPlayer(0x70, blood, 60, 0)`, then `+0x116 = 30` | 10058404 |
| Background 0x73f/0x740 ('Water Urchin', none placed) | player `+0x116 == 0` | `HurtPlayer(0x38, blood, 60, 0)`, then `+0x116 = 40` | 10058448 |
| other Background types | — | exits (0xcb1), door 0xb54/0xb55 (fade + relocate) — not damage | |
| Effect 0x4b7 'big explosion' | its frame `+0x46 ≤ 7` | `HurtSprite(0x70, kvx ±300 away, kvy −0x640, invul 60, flash 12)`, hurt-stun | 10058540 |
| any sprite of type 0x5a0 (the geyser column segments, `.HandleGeyserSegSprite`) | liquid kind `+0x14c ≥ 1` | kind 1: 0x70, immune with Solid-Acid; kind 2: 0x150, immune with Solid-Lava or `HasItem(0x18)`; other kinds 0x70; `HurtSprite(dmg, ±300, −0x640, 60, 12)`, hurt-stun | 10058540 |

The explosion and geyser paths use `.HurtSprite` directly: no scream, no coin loss, no Multi-Crystal
loss. Box-class 0x5a0 sprites (~~pools~~ the geyser bases — no pool object exists, ⚑ corrected (deepening 2026-10-03, geysers.md corr.)) never reach this row — the Box arm takes them first. ⚑ corrected (review 1c, 2026-10-03) (adjudication A2): confirmed from raw — the Box/SeeSaw arm of `.HitPlayerSprite` (`10056b2c..10057860`, entered at `10056b18` on TOC −0x73bc / −0x7678) leaves by 25 branches, all to the epilogue `1005855c`; the hazard arm (`10058458..10058494`) is entered only from `10057e00` on the non-Box path [HIGH].

### 3.5 Generic enemy / enemy-shot path (step 7, l. 4512–4637; disasm 10057968–10057bcc)  [HIGH]
1. Return (no damage) if: type 0x76c..0x775 or 0x754 with gravity `+0x110 > 0` (i.e. a dart or
   spine after a shield reflection); EnemyShot 0x77b with `+0x14c ≠ 0` (never true: nothing writes a 0x77b's `+0x14c`, enemy-shots-and-damage-2 §4.1 ⚑ wave 2 (2026-10-04)); `.ShieldBlock` (§3.6)
   succeeds; type 0x6e6 with `+0x164 ≥ 2`; type 0x74d; types 0x73a..0x73e with `+0x160 ≠ 0`.
2. Damage by class (defaults: 0x70, invul 60): Gremlin 0xe0; Crawler, Roach, Bat, Blob 0x38;
   Warrior, Frog, Wizard, Chief 0x70; Walker, Demon, SwarmMember (no entry) 0x70; EnemyShot by type
   (§1.2 column): 0x46a/0x46b 0x70, 0x46c 0xa8, 0x6f4 0x70, 0x71f 0x70, 0x77b 0x70, 0x753/0x754
   and 0x771..0x774 the shot's `+0xa4`, all others 0x38 (for 0x6e1/0x6e2 and 0x46b/0x46c this arm
   is dead, enemy-shots-and-damage-2 §4.1/enemy-shots-and-damage-2 §4.3 ⚑ wave 2 (2026-10-04)).
3. Type overrides for any class: 0x6a9 → 0x70; 0x6d6 → 0x70 with **invul 0x24** (36) — this also
   hits the Walker *body* of type 0x6d6.
4. Coins lost: damage == 0x70 → 3 when `FastRand(100) > 80` (19 %), else 0; damage > 0x70 → 5;
   less → 0. Blood spray always on.
5. `HurtPlayer(player, other, dmg, 1, invul, coins)`; if it hit and `other` is an EnemyShot,
   `_DAT_100a0570 = 0` (an input-lock timer that `.HandleKeys` honours; ~~its setter not found~~ set by the Chief/Xichra landing stagger, enemy-shots-and-damage-2 §4.4 ⚑ wave 2 (2026-10-04)).
6. If `other` is an EnemyShot: 0x77b → `+0x15c = 1` (spin reverses), `vx ×= −0.15`
   (0x100a1a00), gravity set to 0x15e only if it was ≤ 0; **every other shot is killed, whether or
   not damage landed** (invulnerable players still absorb shots).

### 3.6 `.ShieldBlock(player, shot) @ 10055434` (main dump l. 45206–45290)  [HIGH]
Only for EnemyShot partners. `ax = shot cx − (shot vx >> 8)` (last frame's x). Side 2 (right) if
`ax > player.x + hot.right − 10`, side 1 (left) if `ax < player.x + hot.left + 10`. Blocks when a
side matched, it equals the facing `_DAT_100a5f5a` (1 left, 2 right; written by `.HandleKeys`),
and the shield counter `PTR_DAT_100a05e8 > 2` (raised); the counter is set to 7. Then, with snd
303 'metal hit':
- darts 0x76c..0x775 and spines 0x754: reflected — `vx ×= −0.38`, `vy ×= −0.38` (0x100a1a18),
  `vy −= 1500`, gravity 0x100 (so §3.5 step 1 makes them harmless thereafter); with the Magical
  Shield (item 0xf) also `+0x1a2 = 1` ~~[MED: presumably "hurts enemies now"; reader not traced]~~.
  ⚑ corrected (review 1c, 2026-10-03) #3 (adjudication A12): `+0x1a2` is the ordinary **burn-away row**, not a reflection flag — `.ShieldBlock` stores 1 (`10055550`, gated `bl 0x1004c0e0` = `.HasItem(0xf)`); `.HandleEnemyShotSprite` calls `.StandardSpriteCleanup` (`1005c844`), the only caller of `.HandleBurn` (`10036ed0 lha 0x1a2; cmpwi 0; beq` → `10036ee0 bl 0x10043cd8`). A Magical-Shield-reflected dart/spine therefore **burns away** from row 1 and dies through its `+0x50` Kill callback [HIGH].
- 0x6f4 with the Magical Shield: once (`+0x160 == 0`): vx, vy negated, `vy += 0x140`,
  `+0x160 = 1`, particles. Without it, 0x6f4 is destroyed.
- every other shot: `.KillEnemyShot`.
Returns 1 (block) → no damage. A shield never stops enemy bodies or hazards.

### 3.7 `.HurtPlayer(p, attacker, dmg, blood, invul, coins) @ 1005473c` (main dump l. 45048–45204)  [HIGH]
1. If the attacker's HP < 1 and it is neither EnemyShot nor Box → returns 0 (dead enemies are
   harmless; disasm 10054768–10054798).
2. `HurtSprite(p, dmg, kvx = (short)attacker.vx, kvy = −1000, invul, flash 12)` (disasm 100547a4
   `extsh r5` of the low half of the 32-bit vx). `.HurtSprite`: only when `dmg > 0`, `hp > 0` and
   `+0x116 == 0`: `hp −= dmg; vx += kvx; vy += kvy; +0x116 = invul; +0xaa = flash`. **The
   horizontal knockback is the attacker's own velocity** (a standing enemy gives none; the sword
   fakes ±0x8fc); vertical is always −1000. If it did not apply, nothing below happens.
3. Multi Crystal (item 0x13, not for Blob attackers or Background 0x730..0x733): `_DAT_100a073c =
   15` (after 15 frames one crystal is removed in `.HandlePlayerSprite`), snd 507 'crystalbreak',
   HUD slot flash (`PTR_DAT_1009fda8 = 15`), four Bonus-class shards 0x4bf..0x4c2 from the player's
   centre quadrants: `vy = −0x4b0 − R(0x708)`, `vx = |player vx|/4 − R(300)`, replaced by
   `600 − R(200)` when its magnitude < 500, negated when the player faces right.
4. State: `_DAT_100a059c = 5` (5-frame lock on steering a ridden 0x438/0x439 Box — `.HandleKeys`
   skips its ±0x140 L/R push while > 0); when riding one (`PTR_DAT_100a05a4`; the ridden sprite
   is `PTR_DAT_100a0558`, copied from the player's `+0xdc`) its upward vy is zeroed; `_DAT_100a05b0 = 0`, **hurt-stun
   `_DAT_100a0748 = 1`**, spin flag 0, pull-up 0, climb 0, panting `_DAT_100a06a4 += 0x50`.
5. Blood: `.BloodSpray(p, attacker, 0x28, 500, 0x96, 2)` when `blood`.
6. Sound: dmg < 0xe0 → snd 508 'hurtthud' (vol 0x97, pitch 65000 + R(10000)) + one of 403/402/401
   'Ouch 3/2/1' by `FastRand(3)` (vol 0xab); dmg ≥ 0xe0 → snd 450 'Big ouch' + 508 twice (pitch
   50000 + R, 65000 + R).
7. Coins: if `coins > 2`, `coins += FastRand(3) − 1`; capped at `G+0x10`; subtracted; snd 489
   ('chaincreak1', the coin sound set at `_DAT_100a0300`) once; each coin is a Bonus 0x516 at
   (cx + R(8) − 8, cy + R(8) − 2) with `+0xb0 = 12` (the pickup arm needs `+0xb0 == 0`),
   `vx = ±(600 + R(0x640))`, `vy = −2000 − R(0xdac)`, `+0x16c = −240`.
8. Returns 1.

### 3.8 After the hit: invulnerability, stun, death  [HIGH]
- `+0x116` (invulnerability) and `+0xaa` (flash) count down 1/frame in `.StandardSpriteHandles`,
  called by `.HandlePlayerSprite` (handler dump l. 929). While `+0x116 ≥ 15` the player is tinted
  0x10006 on alternate frames (frame-parity flag `_DAT_1009fd30`), 0x10009 above 60 (l. 2510–2565)
  [MED for the visual meaning].
- Hurt-stun `_DAT_100a0748`: while > 0, `.HandlePlayerSprite` (l. 1890–1916) skips normal control,
  shows hurt frames from `_DAT_100a07d8` (counter 1..4 → frames 0..3, 5..7 → 3, 8..10 → 3,2,1),
  and increments; after 10 it resets to 0. During it the ground deceleration is 300 instead of 800
  (l. 1269–1300), so knockback slides further.
- Death: the frame `hp < 1` while not dying and the stun is 0 (l. 2694–2704): dying counter
  `_DAT_100a069c = 1`, snd 417 'death', `PTR_DAT_100a0560` = in water (physics §5.2: frame 80 or
  100). `.HurtPlayer` itself never kills.
- Other damage routes (not via `.HitPlayerSprite`): breath, liquids and damaging surfaces
  (physics §5.1, §3.3), the Death sphere (spells-items §5). `.HurtPlayer` has exactly 14 call
  sites, all in `.HitPlayerSprite` (`bl 0x1005473c` count in the disasm = 14).

## 4. Wave 2 (2026-10-04) — continued in `enemy-shots-and-damage-2.md`
§4.1 the complete enemy-shot spawn set (0x46b/0x46c dead; 0x77b `+0x14c` never written) · §4.2 the
three collision passes and the active-list order rule (the player is reached only by
`.MTCollideSpecialSprite`) · §4.3 bombs, double split, 0x6a9 · §4.4 `_DAT_100a0570` · §4.5 `+0x1aa` ·
§4.6 `.WallBounce` restitution · §4.7 shadow flags · §4.8 names, frog tint. ⚑ wave 2 (2026-10-04)

## NOT RESOLVED
1. ~~Who spawns enemy shots 0x46b/0x46c (no literal found; a computed type is possible) and whether
   their faces from PICT 0x46a at 64×64 would ever show.~~ → closed: enemy-shots-and-damage-2 §4.1 (no spawner;
   dead types) ⚑ wave 2 (2026-10-04)
2. ~~Writer of 0x77b's `+0x14c` (the "harmless while ≠ 0" test) — none found; 0 at spawn.~~ → closed:
   enemy-shots-and-damage-2 §4.1 (never written; the test is dead) ⚑ wave 2 (2026-10-04)
3. ~~Setter of `_DAT_100a0570` (input-lock zeroed by enemy-shot hits).~~ → closed: enemy-shots-and-damage-2 §4.4
   (Chief 24 / Xichra 20 landing stagger) ⚑ wave 2 (2026-10-04)
4. ~~Meaning of `+0x1a2` (Magical-Shield reflection flag) and~~ ~~`+0x1aa` (Gremlin spit, 0xdc/0x140).~~
   (`+0x1a2` closed: burn row, §3.6 ⚑ corrected (review 1c, 2026-10-03) #3.) → closed: enemy-shots-and-damage-2 §4.5
   (`+0x1aa` = draw rotation in degrees) ⚑ wave 2 (2026-10-04)
5. ~~The frog `+0x15c` source (probably placement param 1, census values 0/1/2/4).~~ → closed:
   enemy-shots-and-damage-2 §4.8 (= p1, 10081fe0–10081ff4) ⚑ wave 2 (2026-10-04)
6. ~~Active-list order between the player and shots, hence whether a bomb can split twice (§1.6)
   and whether 0x6a9 (2-frame life) is ever collidable twice.~~ → closed: enemy-shots-and-damage-2 §4.2 (rule),
   §4.3 (no double split in shipped levels; 0x6a9 collidable in one frame) ⚑ wave 2 (2026-10-04)
7. ~~`.WallBounce`'s use of the 0xa0 argument (assumed restitution 160/256).~~ → closed: enemy-shots-and-damage-2 §4.6 ⚑ wave 2 (2026-10-04)
8. ~~Names of 0x57d (platform hurting from below), 0x433/0x434, 0x5c3/0x5c4, 0x5c8..0x5d1.~~ →
   closed: enemy-shots-and-damage-2 §4.8 (names MED, from decoded faces and sibling files) ⚑ wave 2 (2026-10-04)
9. ~~Shadow-double flags `PTR_DAT_100a0674`, `_DAT_100a06d0/06d4` (why riding a sprite re-syncs the
   double).~~ → closed: enemy-shots-and-damage-2 §4.7 (flags HIGH; the riding intent LOW) ⚑ wave 2 (2026-10-04)
10. New wave-2 items: enemy-shots-and-damage-2 NOT RESOLVED.

## Proposed additions to physics.md §0
| off | type | meaning (writer/reader) |
|---|---|---|
| +0x88 | u8 | cleared by several handlers each frame (0x712 shots, shadow, trail) ~~[draw/collide flag?]~~ — ⚑ corrected (review 1c, 2026-10-03) #5: light-overlay gate, not a collision flag (sole reader `.WrapDrawSprites` `1001493c`, physics §0.1) |
| +0x8c | u8 | set 1 by `.SetupEnemyShotSprite` [unknown] |
| +0xa6 | i16 | enemy shot: age (+1/frame); 0x6d6: intended lifetime; Bonus/power-up: duration |
| +0xb8 | i32 | tint mode (0x1000b statue/strong variant, 0x10006 invuln blink, 0xb000n trail fade) [MED] |
| +0x130 | i32 | statue/cannon countdown; negative = post-cannon grace counted up by `StandardSpriteHandles` |
| +0x134 | i32 | saved tint while a statue |
| +0x14c | i32 | enemy shot lifetime (kill at 0); liquid kind on geysers/pools |
| +0x150 | i32 | enemy shot bounce counter (kill when ≥ 0 after a wall hit) |
| +0x154 | i32 | enemy shot one-frame bounce lockout |
| +0x15c | i32 | 0x753 fuse; 0x77b spin direction; Wraith's aim |
| +0x160 | i32 | 0x6f4 reflected-once flag; falling-box arm flag (0x433/0x434) |
| +0x164 | i32 | 0x6e6 age; cannon launch speed |
| +0x16c | i32 | enemy shot: pass through walls and solids; coin: −240 |
| +0x1a2 | i16 | ~~reflected by the Magical Shield~~ burn-away row; `.ShieldBlock` starts the burn on a Magical-Shield reflection (§3.6) ⚑ corrected (review 1c, 2026-10-03) #3 |
| +0x1e4 | ptr | cannon holding this sprite |
| +0x1ec / +0x1f0 / +0x1f4 | proc | saved Handle / Hit / HitTile while a statue or in a cannon |

## Corrections to the existing bank
(wave-2 rows W1–W7: `enemy-shots-and-damage-2.md` corrections table) ⚑ wave 2 (2026-10-04)
1. **sprites-backgrounds-sounds.md §5 and spells-items.md §4 (melee)** — old: the 36 kick rects
   "used by the dagger/kick hit test [MED]" / "are the swing arc positions [MED]". New: the table
   at 0x1024b394 (TOC slot 0x100a0078) is written by `.InitPlayerKickRects` and **read by nothing**:
   `tocrefs.py 100a0078` → only 0x10000410, and no other TOC word points into
   0x1024b394..0x1024b4b3 (scan this session). Melee hits come from the held-item sprite, whose hot
   rect is its face rect (`.HandleHeldItemSprite`, handler dump l. 620–647) and which carries the
   player-shot handlers while stabbing (`.HandleItemUse`). Residual risk as for LoadLevelPhysics
   (an arithmetic address). [HIGH]
2. **physics.md §5.1 "lava/acid pools (Box class 0x5a0, mode s+0x14c 1/2)"** — new: two arms.
   Geyser-column segments of type 0x5a0 under `.HandleGeyserSegSprite` (created by
   `.HandleGeyserColumn` with the Effect setup, which installs that handler for type 0x5a0) hurt on
   contact with knockback ±300; the Box-class geyser head 0x5a9 hurts when stood on with
   knockback ±400. Both: kind 1 → 0x70, kind 2 → 0x150, `HurtSprite`, invul 60, flash 12, kvy
   −0x640. Box-class 0x5a0 sprites never hurt (§3.3/§3.4). [HIGH]
3. **physics.md §5.1 fire sprites** — the Fire Charm protects only while the fire sprite's
   `+0x14c ≤ 0`; damage via `HurtPlayer(0xe0, blood, 60, 0)`. [HIGH]
4. **physics.md §5.1 `.HurtPlayer`** — add: refused when the attacker is dead (HP < 1) unless
   EnemyShot/Box; kvx is the attacker's vx (low 16 bits, sign-extended); Multi-Crystal loss skipped
   for Blob and Background 0x730..0x733; coin count randomised to n−1..n+1 only when n > 2; it sets
   `_DAT_100a059c = 5`, panting +0x50 and ends spin/pull-up/climb. [HIGH]
5. **physics.md §3.3** "hurt-stun counter `_DAT_100a0748`" — it is a 10-frame stun: control
   skipped, hurt animation, ground deceleration 300; death waits for it (§3.8). [HIGH]
6. **physics.md §7** "statue: 120-frame statue, handlers swapped to the statue set" — add: the
   swapped hit/tile callbacks are the Box ones, the statue is frozen in place (no gravity), blinks
   for the last 19 frames, and **costs the sprite 200 HP when it ends**. [HIGH]
7. **spells-items.md §4 item 0xf "reflects shots [LOW]"** — any raised shield reflects darts and
   spines and destroys other shots; the Magical Shield additionally reflects the Wraith's 0x6f4
   (once) and marks reflected darts/spines (`+0x1a2`). [HIGH] ⚑ corrected (review 1c, 2026-10-03) #3:
   the "mark" is the burn row — those darts/spines burn away (§3.6).
8. **physics.md §7 table** — add contact damage per class (§3.4/§3.5): Gremlin 0xe0;
   Crawler/Roach/Bat/Blob 0x38; Walker/Warrior/Frog/Wizard/Chief/Demon/Swarm/Salamander/Crab 0x70;
   Wraith 0x70 only while its `+0x46 > 12`; Dillo 0xe0/0x1c0 by type. [HIGH]
9. physics.md §7 "Statue/Box/Platform set `+0x185`" (review 1a #5, adj. 2): the Statue does **not** set `+0x185` — no `0x185` store in `100664a8–100665bc` (`.HandleStatueSprite`) or `10043138–100431c4` (`.TurnIntoStatue`); thaw `lha 0xa4; subi 0xc8; sth` at `1006656c–10066574`; `+0x130 = 0x78`, `+0x134 ← +0xb8` at `10043194–1004319c`.
10. physics.md §7 Bat row "HP 100, 200" (review 1a #5, adj. 3): 1740 family **500** (`1007dcbc cmpwi 0x6d6; bge` → `1007dcc0 li 0x1f4`), 1850 family 100 (`1007dde0 li 0x64`), insects 200 (`1007e144 li 0xc8`); Floater row rect (0x17,2,0x38,0x5c) → shipped 1780 (0x23,1,0x3e,0x4b) at `10081550–1008155c`.
11. physics.md §2 water gravity `max(0.7·g, 0x100)` — add the caveat (review 1a #2, adjudication 4): taken only when `+0x11c ≠ 0` at the routine's entry (`lwz 0x11c @100375c8`), before its own `SeparateFromTiles2` (`bl 1003c804 @10037624`); `.StandardSpriteHandles` zeroes `+0x11c` each frame (`100368d4 … 100369ac`), so every sprite's first call uses dry gravity; only a second same-frame call (Frog) or a direct `+0x11c` writer (Bonus 1055 in-water flag, 1350 air bubble) takes the 0x100 branch.
12. spells-items.md §2.1 (review 1a adjudication 1) — names only: id 2 "Ice Crystals" (cost 10, gravity 0, unholdable), id 3 "Ice Wall" (cost 0x1e `1005213c`, dmg 0x12c `10052138`, floes `1005a2e4–1005a30c`, ledges `1005b2c4/1005b2f4`), id 7 second Ice-Wall icon (cost 0xc, dmg 0x96, gravity 0xfa, no floe); PICT 700 captions 0..11 = Fireball, Statue, Ice Crystals, Ice Wall, Tree Trunk, Boomerang, VBlade, Ice Wall, DensityBall, Sandstorm, EnergyBolt, Ice Shards.
