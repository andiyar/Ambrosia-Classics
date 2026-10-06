# Ferazel's Wand 1.0.3 — spell system, player projectiles, hang glider (detail)

Code readings only; nothing behaviour-verified.
Date 2026-10-03. Sources: main dump `ghidra/Ferazel_pef.decompiled.c` ("main l."), handler dump
`ghidra/Ferazel_handlers.decompiled.c` ("handler l."), raw disassembly `ghidra/Ferazel_pef.disasm.txt`
(addresses), data constants via `tools/const.py`, TOC users via `tools/tocrefs.py`, resource forks
via `tools/rsrc_census.py` (PICTs rendered with `sips` for viewing only).
Scope: (a) spell id → name from strings/UI art; (b) `.CastSpell` and the casting trigger/animation;
(c) player shots — `.SetupPlayerShotSprite`, `.HandlePlayerShotSprite`, `.HitPlayerShotSprite`,
`.HitPlayerShotTileSprite`, `.KillPlayerShot`, incl. the non-spell shots 0x3c/0x50/0x5a;
(d) the hang glider. Extends `spells-items.md` §2/§2.1 (read it first); field names per
`physics.md` §0. Velocities in 1/256 px per frame, frames at ≤ 30 Hz (engine.md §4).

## 1. Spell ids → names (closes the spell half of INDEX NOT-RESOLVED 11)

**String census** [HIGH, negative]: `STR# 300`/`400` (app: warnings/fatal errors), `STR# 500`
(World Data: signs), `STR# 1000` (level names), the Documentation `STR#`/`STR ` resources, and every
`DITL`/`DLOG` item text in the app fork contain **no spell or item names** and there is **no
spell-select or inventory dialog** (DITLs: warp, prefs, keyboard, sound, save, sign, game over,
CD, res-switch, generic). Names live only in art and in the manual.

**HUD spell art** [HIGH that the art carries these labels — PICT 700/702 rendered independently in
review 1a with the same captions; HIGH that label i = spell id i for ids 0..7: icon column = id
(`.UpdateItemStat`, below) and the code identities agree — id 3 cost 0x1e `1005213c`, dmg 0x12c
`10052138`, floe only on `+4 == 3` `1005a2e4–1005a30c`, scroll 2→3 `10056520–1005652c`, HUD rewrite
`10009174–1000918c`] ⚑ corrected (review 1a, 2026-10-03) #6:
`.InitAppGlobals` (main l. 475–482) loads four HUD strips into off-screen ports — big item icons
`PICT 702` (1215×47), small item icons `PICT 703` (621×46), big **spell** icons `PICT 700`
(1215×47), small spell icons `PICT 701` (621×46). `.UpdateItemStat` (main l. 4639–4804) blits the
selected slot's big icon from `(45·id, 0, 45·id+44, 47)` of 700/702 to (0xd7,0x1e)–(0x103,0x4d),
and each inventory slot's small icon `(23·id, 23..46)` (selected: row `0..23`, the green-framed
variant) of 701/703 into a 15-column grid at x `0x10a + 23·col`, y `0x1f + 23·row`. So icon
column = id. The 27 big spell icons carry baked-in captions:

| id | caption in `PICT 700` | code identity (this file) | manual (`TEXT 132`) |
|---|---|---|---|
| 0 | Fireball | §3 | "The Fireball Spell" (starting spell, arcs with gravity) |
| 1 | Statue | enemies' Hit routines petrify on id 1 | "The Statue Spell" |
| 2 | **Ice Crystals** | cut: rewritten to 3 at pickup **and on every HUD redraw** (§1.1) | — |
| 3 | Ice Wall | floes on water, ledges on walls (§3.4) | "The Ice Wall Spell" (floes on water / platforms against a wall) |
| 4 | Tree Trunk | plants a trunk where it lands (§3.5) | "The Tree Trunk Spell" |
| 5 | Boomerang | homes back after 12 frames, refund on catch | "The Boomerang Spell" |
| 6 | VBlade | up + down blades (second half is shot 0x3c) | "The V Blade Spell" |
| 7 | **Ice Wall** (same icon as 3) | Ice-Wall face, no floes/ledges (§3.6) | — |
| 8, 9, 10, 11 | DensityBall, Sandstorm, EnergyBolt, Ice Shards | no code: `.CastSpell`'s switch is `cmplwi r24,7` (0x10051e28) | — |
| 12..26 | Fireball (placeholder copies) | — | — |

So **id 2 = "Ice Crystals"** and **id 7 = a second "Ice Wall"** [HIGH: art captions, review 1a
adjudication 1 ⚑ corrected (review 1a, 2026-10-03) #6 — was MED], neither in the manual's six. The
same art method settles the item ids (correction C9): `PICT 702` captions ids 0..11 = Dagger,
**Steel Key**, Gold Key, Plat. Key, Magic Ptn., Health Ptn., Fire Seeds, Locket, Hammer, Poppy Muffin,
Alg. Piece, Alg. Frame [HIGH for the art; rendered in review 1a] ⚑ corrected (review 1a, 2026-10-03) #6.

### 1.1 Spell 2 can never stay in the inventory  [HIGH]
`.UpdateItemStat` main l. 4713–4715 (raw 0x10009178–0x1000918c): for every slot,
`if (id == 2 && slot+8 /*spell*/ != 0) id = 3`. Together with the pickup rewrite (spells-items §3,
2000+2 → 3) a held spell 2 is turned into Ice Wall at the next status-bar draw. Its shot code
(§3.3) is still complete and reachable only between a grant and the next HUD update.

## 2. Casting: trigger, animation, cost, power

### 2.1 Trigger (`.HandleKeys @ 10052ac0`, main l. 44404–44445)  [HIGH]
`.HandleKeys` is called from `.HandlePlayerSprite` (handler l. 1199) only while `_DAT_100a06f0 == 0`,
and returns early while `|PTR_DAT_100a0700| > 30`, while the potion-drink counter
`_DAT_100a05b0 > 0` (which also zeroes the wand step and crouch), and while `_DAT_100a0570 > 0`.
⚑ wave 2 (2026-10-04): the gates are the door-transit lock, the teleporter charge, the potion drink and the
boss-grab counter — writers, readers and raw addresses in spells-detail-2 §1 [HIGH].
Then, each frame:
1. If USE (action 6) is up, **or** the selected slot is not a spell (`slot+8 == 0`), **or** the
   shield is raised (`*PTR_DAT_100a05e8 > 0`, the block counter of `.ShieldBlock`), the USE latch
   `_DAT_100a0760` is cleared and nothing else happens here.
2. Otherwise the idle counters `_DAT_100a0688/_DAT_100a068c` are zeroed and, **only if the latch
   is clear** (a fresh press — no autofire) and the mist-potion states are off
   (`_DAT_100a0578 == 0 && _DAT_100a0574 == 0`):
   - magic `G+0xe < 1` → selection jumps to the first slot holding item 0 or 0x15 (dagger /
     Vorpal Dirk), `.MoveSelectedItemToFront`, `.UpdateStatusBar(1,1,0)`;
   - else latch = 1, `_DAT_100a075c = 1` (⚑ wave 2 (2026-10-04): that write is dead — the item block entered
     later in the same call clears it because the selected slot is a spell, spells-detail-2 §1); if the wand step `_DAT_100a06d4` is 0 → cast flag
     `_DAT_100a06ec = 1`, step = 3, `PTR_DAT_100a06e0 = 0`; if the step is 3 (wand still raised) →
     cast flag = 1; **steps 1, 2, 4, 5, 6 swallow the press** (latch set, no cast);
     `.MoveSelectedItemToFront`.
No condition tests swimming, the glider, ropes or climbing: casting is allowed in all of them
(their effects are in §2.3 and §3.7).

### 2.2 Wand animation and the cast frame (`.HandlePlayerSprite`, handler l. 1398–1432)  [HIGH]
Step `_DAT_100a06d4`, hold counter `_DAT_100a06d0` (raw 0x1004eca4–0x1004ed54):
- cast flag set: step += 1; **step == 4 → `.CastSpell(player)` if magic `G+0xe > 0`**; step > 6 →
  flag cleared, step = 3. Because `.HandleKeys` runs earlier in the same handler (step 0 → 3),
  the cast happens **on the frame of the key press**; steps 5, 6, then 3 follow.
- step == 3: hold += 1; at 18 → step 2; next frame (hold still 18) step 2 → 1; then step 1 →
  0 and hold = 0. Any other step zeroes hold.
- So: press → shot that frame; the wand stays raised 18 frames after the swing (a press then
  re-casts immediately); it lowers over 2 frames (presses swallowed); minimum interval between
  casts = 4 frames plus one released frame for the latch.
- A second arming path (`PTR_DAT_100a06e8`, step counts to 3 then sets the flag) is **dead**:
  `tools/tocrefs.py 100a06e8` finds only `.ClearPlayerVars` and the two reads here.

Casting faces (all 100×120 cells; frame = step − 1 unless stated) [HIGH for the selection,
MED for which pose is drawn]: standing/air `PICT 1014` (`_DAT_100a07d4`, handler l. 2289–2290);
V Blade pose `PICT 1032` (`_DAT_100a07a4`, when `_DAT_100a0768 = 1`, which `.CastSpell` sets only
for spell 6); wall-climb `PICT 1031` (`_DAT_100a07a8`, frame = step, 6 → 5, handler l. 2028–2038);
rope `PICT 1016` (`_DAT_100a0798`, frame = step, only at |vx| ≤ 0x80, not for V Blade, l. 1952–1959);
glider `PICT 1053` (§5.3). Swimming shows no cast pose (l. 1971–2004). Wall-climb input during a
cast (main l. 44774–44812): with step ≥ 4 UP/DOWN are ignored; with step 1..3 UP/DOWN give `vy = 0`
while `PTR_DAT_100a06e0 == 0` (cast-start frame) or the hold < 5, otherwise they cancel the pose
(step = 0) and climb normally.

### 2.3 `.CastSpell @ 10051d1c` (main l. 43746–44071)  [HIGH; raw 0x10051d1c–0x10052964 checked]
Per cast, before the switch: power `p = 1 + count(item 0x13)`, but `p = count` while the
crystal-loss timer `_DAT_100a073c > 1` (the crystal about to be lost does not count); spawn type
`id·256 + p`; carried speed `c = |ridden.vx|` only when on the magic carpet (`PTR_DAT_100a05a4`
and ridden sprite `PTR_DAT_100a0558 ≠ 0`), else 0; offsets `(gx, gy) = (0x1e, 0x23)` on the glider,
`gy = 8` on a rope (overrides); exertion `_DAT_100a06a4 += 0x19` (the panting counter of
physics.md §8.8); `_DAT_100a0768 = 0`. Sound: `snd 300` "Fireball" for **every** spell
(`_DAT_100a0424`, loaded by `.InitSounds` via `GetResource('snd ',300)`), `.STPlay3DSoundRand`
= volume 0x100, pitch `0xec77 + rand(10000)` (≈ 0.92..1.08).

| id | cost `G+0xe −=` | damage `+0xa4` | spawn (x, y) relative to player cell (crouch y) | vx before facing | vy |
|---|---|---|---|---|---|
| 0 | 8 | 100 | (x+0x26+gx, y+0x33+gy) (y+0x42+gy) | `|pvx/2| + rand(100) + c + 0xd2f` | `pvy/2` |
| 1 | 0x20 | 200 | same | same | same |
| 2 | 10 | 100 | same | same | same |
| 3 | 0x1e | 300 | same | same | same |
| 4 | 8 | 100 | same | same | same |
| 5 | 8 | 100 | (x+0x26+gx, y+0x20+gy) (y+0x32+gy) | `|pvx/2| + rand(100) + c + 0xed8` | `pvy/2 − 0x80` |
| 6 | 8 | 150 + 150 | upper: (cx−20+gx, y+0x2a+gy) (y+0x34+gy); lower (type `0x3c00+p`): (cx−20+gx, y+0x34+gy) (y+0x39+gy) | `rand(256) − 0x80` each | upper −4000, lower +4000 |
| 7 | 0xc | 150 | as id 0 | as id 0 | as id 0 |

(`pvx/pvy` player velocity, `cx` = player centre x `+0x10`; the lower V Blade gets its 150 by an
explicit store, the upper one by the common store.) Then, **for the first shot only**: UP held →
`vy −= 0x5dc, vx −= 0x2ee`; ids 0, 1, 3, 4 → `vy −= 0x5dc` (`−1000` while crouching); `vy +=
rand(75) − 40`; facing = player `+0x17e`, inverted while wall-climbing with wall side 1 or 2
(`_DAT_100a0758 ≠ 0`, `PTR_DAT_100a074c − 1 < 2`); facing left → `vx = −vx`. The lower V Blade
keeps its raw `rand(256)−0x80` vx and +4000 vy (no UP, no jitter, no facing flip).
Magic is decremented **without a floor**; `.CastSpell` runs only when magic > 0, so magic can
reach `1 − cost` [HIGH]. The switch has no case above 7 (an id > 7 would store the damage through
a null shot pointer) [HIGH, unreachable in shipped play].

**Shadow Double copy** (power-up 1330 active, `_DAT_100a0658 = double sprite`) [HIGH, raw
0x10052700–0x10052930]: for the first shot (and the lower V Blade if any) a copy of type
`id·256 + 1` (always power 1) is spawned at the shot's spawn point shifted by
`double.pos − player.pos`; vx = the shot's pre-flip vx, negated if the double faces left;
`vy = shot.vy − 0x44c` if the double's replayed history frame is "on the ground, not on a
platform" (history ring `PTR_DAT_100a0520`, entry `(PTR_DAT_100a0590>>1)`, byte +4 — written at
handler l. 2863–2869) and the shot's gravity > 0, else `shot.vy`. **Its `+0xa4` is never set** (no
`sth …,0xa4` on it in the raw), so double shots deal **0 damage** (`.HurtSprite` ignores dmg ≤ 0);
they still petrify (id 1), freeze water / build ledges (id 3) and plant trunks (id 4).

### 2.4 What "power" (`+0x170`) does  [HIGH]
Power affects **only damage and the visual stack**; not speed, size, range, hit rect or cost.
1. **Damage ×p**: on the shot's second handler frame (age `+0x14c` goes −1 → 0 → 1; handler
   l. 5323–5333, raw `mullw` at 0x10059fc0) `+0xa4 *= p`. p is clamped to ≤ 5 in Setup, so the
   maximum is ×5 (Fireball 500, Ice Wall 1500, V Blade 750 per half). A shot that hits on its
   first frame deals the base damage ~~[MED: depends on whether a shot spawned during the player's
   handler is handled that same frame]~~ [HIGH] ⚑ wave 2 (2026-10-04): creation-frame hits always deal base damage;
   a frame-2 hit is multiplied only if the shot was already handled in its creation frame, which
   happens iff the sprite after the player in the active list has layer ≤ 11 (spells-detail-2 §4; rule:
   enemy-shots-and-damage-2 §4.2 item 1, player-states §9.1, ⚑ wave 2 corr (2026-10-04) P1 W1) —
   assuming no sprite *before* the player carries a current layer > 11 (insertion walks from the
   head, `10032f68..10032f9c`; direct `+0x80` stores do not re-sort) ⚑ corrected (review 2f, 2026-10-04) #1.
2. **Follower stack**: Setup spawns `p − 1` followers (≤ 4) of type `id << 8` (power 0). Power-0
   sprites get no sprite-hit callback, no tile callback, gravity 0 (Setup l. 4991–4996). Each frame
   the main shot places follower k (k = 1..4, pointers `+0x1d4/+0x1d8/+0x1dc/+0x1e0`; the decompile's
   `puVar10[-1]` loop hides that the first pointer lands in `+0x1d4` — raw 0x10059598..0x10059628)
   at `main + off − k·step`, with `step = (10, 0)` for ids 6/0x3c (side by side) and `(0, 6)` for the
   rest (stacked vertically), `off = (p−1)·step/2` (`+0x168/+0x16c`), and copies its vx and draw
   angle. The main sprite is drawn at `+off` with its hot rect shifted back by `off`, so the **hit
   rect stays at the stack centre** (handler l. 5093–5106, 5483–5547).
3. Followers still carry the player-shot handler (`+0x4c`) and `+0xa6 = 0`, and
   `.MTCollideSprites` (main l. 30210–30333) calls the *enemy's* hit callback against any overlapping
   sprite. Enemy Hit routines test only `+0x4c == HandlePlayerShot && +0xa6 == 0` (e.g.
   `.HitCrawlerSprite`, handler l. 9888ff), so a follower that touches an enemy is consumed
   (`.KillPlayerShot(f,0,0)`), **petrifies it if id 1**, and deals 0 damage [HIGH for the code
   path; MED that this is what play shows].

## 3. Player-shot flight, per id

### 3.1 Setup (`.SetupPlayerShotSprite @ 1005925c`, handler l. 4890–5053)  [HIGH; raw checked]
Common: `+0xeb` (can-crunch) = 1, `+0x46 = rand(5)` (first anim frame), layer 0xb, Handle/Hit/
HitTile = `.HandlePlayerShotSprite`/`.HitPlayerShotSprite`/`.HitPlayerShotTileSprite`, `+0xa6 = 0`,
`+0x90 = 0x100` (full wind), crunch strength `+0x158 = 1`, hot rect `SetRect(8,3,15,12)`, then the
id/power split, face 0, `+0xe4 = 1`, age `+0x14c = −1`.

| id | hot rect `SetRect(l,t,r,b)` | gravity `+0x110` | extra |
|---|---|---|---|
| 0, 1, 3, 4 | (8,3,15,12) | 0xfa | — |
| 2 | (8,3,15,12) | 0 | — |
| 5 | (10,10,22,22) | 0 | — |
| 6 | (8,8,24,32) | 0 | — |
| 7 | (6,6,22,22) | 0xfa | — |
| 0x3c | (−10,0,24,6) | 0 | — |
| 0x50 | (0,0,20,20) | 0 | `+0xa4 = 300`, hits left `+0x168 = 3`, `+0x16c = rand(14)`, **no tile callback** |
| 0x5a | (2,−6,10,6) | 0xfa | crunch strength `+0x158 = 2` |
| power 0 (followers) | per id | forced 0 | no hit, no tile callback |

### 3.2 Per-frame (`.HandlePlayerShotSprite @ 10059704`, handler l. 5056–5569)  [HIGH unless noted]
Order: return if dying; `.StandardSpriteHandles` (wind, currents); un-shift the stack; age
`+0x14c` += 1 up to 200 (**no lifetime** — a shot lives until a kill rule fires); from age ≥ 1 the
id branch below; on age 1 (power > 0) the damage multiply and the light; `vy += gravity; x += vx;
y += vy` (no terminal speed, no sub-steps); `.ChangeLightSpeed`; `.SeparateFromTiles2` for every id
< 100 (and type 100 with `+0x158 > 0`); liquid rule; level-bottom rule (`y > hdr+0xb282 · 32` →
kill flag); positions; draw angle `+0x1aa = 10·dir` for gravity shots (dir 0..35 from the
previous position `+0xc4` toward the current, +18 when vx < 0) [MED: `+0xc4` = previous position];
place the followers.

| id | face set (`.InitPlayerShotSprite`, main l. 45338) | anim | per-frame extra | light on age 1 (`.AddLight`, colour) |
|---|---|---|---|---|
| 0 | `PICT 1100`/`1101` 'fireball right/left' (6 × 24×15), by sign of vx | 6 frames, 1/frame | **none** | 0x16 at (x+0xc+vx>>8, y+8) |
| 1 | `PICT 1102`/`1103` (6 × 24×15) | 6 | none | 0x21 |
| 2 | `PICT 1104`/`1105` (6 × 24×15) | 6 | 2 particles/frame `NewParticle(200, 0xfa, pos+(10+r6, 5+r6), 1+r2, vx r400−200−s+0x86, vy max(0, r400−200−s+0x84))` | 0x21 |
| 3 | `PICT 1115` (6 × 28×28) | 6 | 5 particles/frame `NewParticle(3, 0x15e, pos+(10+r6, 5+r6), 1+r2, r400−200−s+0x86, r800+vy−400)` | 0x4d |
| 4 | **none** (face stays 0) | — | 7 particles/frame `NewParticle(9, 0, pos+(9+r8, 4+r8), 1+r2, r400−200−s+0x86, r400−200)` — the spell is drawn only as particles | 0x42 |
| 5 | `PICT 1113` (6 × 32×32) | 6 | age > 12: steer toward player centre (y−4): `FUN_1003f218(s, dir, 800)`, `.EnforceMaxSpeed(s, 0x1450)` | 0x16 at (+0x10, +0x10) |
| 6 | `PICT 1114` frames 0..9 (32×40) | 10 | kill when centre y is > 500 px from playerY `_DAT_1009fd90` | 0x2c, light face `PICT 822` at (+0x10, +0x14) |
| 0x3c | `PICT 1114` frames 10..19 | 10 | same ±500 rule | 0x2c as id 6 |
| 7 | `PICT 1115` (the Ice Wall face) | 6 | none | 0x21 at (+0xe, +0xe) |
| 0x50 | `PICT 1118` (single 20×20) | — | 16-step tint cycle `+0xb8` (0 / 0x10008 / 0x10009); spawn/hit flash `+0x164 < 0` counts up with tints 0xb0002/0xb0000/0xb0001 | none |
| 0x5a | `PICT 1116` (8 × 12×12) | 8 | `+0xa4 = 800`, or 0x578 (1400) with tint 0x10004 when `+0xf4` (Ziridium); `+0xa6 = 0`; invisible if `+0xf0 ≠ 0` | none |

Light face is `PICT 810` (72×72) except ids 6/0x3c; lights are added only if the face passes the
on-screen test (`face+0xe ≤ s+0x1b6 || s+0x1b8 ≤ face+0xa` → skip) ~~[MED: fields not decoded] and
removed when the shot leaves it~~ ⚑ wave 2 (2026-10-04): it is a **wall-tunnel** test, not an on-screen test — face
`+0xa/+0xe` = opaque-bounds left/right, `+0x1b6/+0x1b8` = the tunnel clip; the light is skipped at age 1
or removed at frame end (for good) only while the shot is entirely hidden in a tunnel (spells-detail-2 §2) [HIGH]. `NewParticle(a, b, pos, size, vx, vy, c, f)`: ~~the meanings of
`a`/`b` (colour/kind? gravity?) are not decoded here [LOW]~~ a = colour kind, b = gravity per frame, size =
shape code, c = delay, f = collision mode (`10031ed4..10031f18`, `10031898..100318a4`; particles §2, §4)
[HIGH] ⚑ wave 2 corr (2026-10-04) PA #3; `s+0x84/+0x86` are zeroed in Setup.
`FUN_1003f218` is an unnamed callee (accelerate along a 36-step direction) ~~[MED]~~ [HIGH] ⚑ wave 2 (2026-10-04): adds an
impulse of 800 to the velocity in 10° direction `dir` (0 left, 9 down, 18 right, 27 up; raw jump table
`0x100a5694`), aimed at 4 px above the player's centre, then per-axis cap 0x1450 (spells-detail-2 §3).

**Liquids** (handler l. 5414–5444) [HIGH]: if the shot is in liquid (`+0x11c > 0`, set via the tile
callback's `.HandleUnderWater`) and its id < 100 and ≠ 6: effect sprite type 5 at (x−8, y−12) with
its light switched off, kill flag, followers killed; and if id == 3 and the liquid kind
`+0x128 == 0` (water) → ice floe (§3.4). So every shot fizzles on touching water, lava, acid or
quicksand — **except the upper V Blade (6)**; the lower half 0x3c and thrown seeds 0x5a do die
(seeds fizzle without exploding). Casting while submerged produces a shot that dies the same
frame (an Ice Wall cast under water makes a floe on the spot).

### 3.3 Tile hits (`.HitPlayerShotTileSprite @ 1005b0bc`, handler l. 5697–5868)  [HIGH]
Ignored when debug mode and key 0x32 is held, or when dying. Ids 6/0x3c react **only to crunch
cells** (`param_4 == 2`): V Blades pass through solid tiles and crunch breakable ones without
dying. Others:
- FG tile (`param_4 == 1`, not type 100, not 0x50): `.WallBounce(s, kind, …, bounce = 0xa0 for
  0x5a else 0, …, bounceFlag = (id == 0x5a))`; on contact: id 3 → ledge (§3.4); id 4 standing on
  ground (`+0xce ≠ 0`) → trunk (§3.5); else kill via `.KillPlayerShot(s,1,1)`, except seeds which
  bounce (normal speed ×−0xa0/256, tangential ×0xa0/256 = 0.625, `.WallBounce` case arithmetic,
  `.WallBounce @ 10037a54` cases 0/1, main l. 32854ff) and are killed only once `|vy| < 0x200` after a contact.
- BG kind < 100: `.WallBounce` as above, then kill (seeds: same slow rule).
- BG kind 100..199: `.WallBounceBG(kind−100)`; on contact id 4 on ground spawns a trunk bottom
  0x2c8 at (cx−8, cy−6) with `+0xa6 = 0x78` (no sparkle/sound), then kill (all ids, seeds slow rule).
- BG kind ≥ 200 that `.IsWaterTile`: `.HandleUnderWater` (if `+0x140 == 0`) → liquid rule §3.2.
- crunch cell (`param_4 == 2`): `.CrunchTile(pos, +0x158)`; ~~if it broke~~ if the cell was processed (return ≠ 0:
  broke, cracked or resisted; `1005b5f8..1005b62c`, player-states-2 §13 ⚑ wave 2 corr (2026-10-04) P2 W2) → kill (not 6/0x3c).
  Crunch strength: spells 1, seeds 2 (held Ice Pick 4 — items reader).

### 3.4 Ice Wall (id 3): floes and wall ledges — who sets platform mode 4  [HIGH]
The **shot code itself** writes the platform mode: after `MTNewSprite(0x57c, …, layer 2,
SetupPlatformSprite)` it stores `+0xb0 = 4`, `+0xa6 = 0xb4` (lifetime 180 frames). Because a
code-spawned sprite has `+0x48 = −1` and 0x57c is not one of the fixed-mode types,
`.DoSetupPlatformSprite` keeps `+0xb0` (main dump `.DoSetupPlatformSprite` lines 29–40) and its
mode-4 branch uses `+0x16c` to pick the variant (face = `PICT 711` 'frozen water platform',
3 × 40×24, frame `+0x16c`):
- **water floe** (handler l. 5421–5428): on liquid kind 0, at (x−10, cy−4), `+0x16c = 0`, also
  `+0x13a = 4` (overwritten to 0x16 by DoSetup): floats (gravity 0x15e, buoyancy 0x3c, float
  offset 10, rect (0,0,0x28,0x31)) — physics.md §8.9 mode 4.
- **wall ledge** (l. 5761–5776): when `.WallBounce` reports contact with FG kind 2 (right-half
  wall) or kind 6/7 with vx stopped → ledge at (tileX − 0x17, cy), `+0x16c = 1`; kind 0, or 4/5
  with vx stopped → at (tileX + 0xf, cy), `+0x16c = 2`. Ledges have no gravity, rect
  (0,3,0x28,0x18). The test uses the raw FG kind, so walls whose kind carries a material hundred
  (≥ 100) get no ledge [MED]. Floor/ceiling contacts make nothing. The shot is then killed (§3.7).
Lifetime/flash/explode at `+0xa6` → physics.md §8.9 [HIGH there].

### 3.5 Tree Trunk (id 4)  [HIGH arithmetic; trunk behaviour belongs to the Box reader]
- Landing on an FG floor (`+0xce ≠ 0` after the contact): trunk bottom 0x2c8 (Box class) at
  (cx−8, cy−6), `+0xa6 = 0x78 + frameParity` (`*_DAT_1009fd30`, the 0/1 byte toggled each paint in
  `.PaintFrameWrap`, main l. 9400–9404); effect sprite type 2 at (trunk x−6, y−9), `+0x46 = 8`,
  light colour 0x42; `snd 302` 'statue hit' at 0x100; shot kill flag set directly (no
  `.KillPlayerShot`, so followers are **not** killed — they fly on, invisible, emitting
  particles ~~[MED]~~ [HIGH] ⚑ wave 2 (2026-10-04): horizontally at the main's last vx, through walls (no tile
  interaction), until an enemy consumes them; they can press Buttons; same for the level-bottom and
  V-Blade ±500 kills (spells-detail-2 §5)).
- Hitting a trunk sprite (Box class, type 0x2c8/0x2c9; `.HitPlayerShotSprite` handler l. 5630–5654):
  follow `+0x1d4` up to the top segment, add segment 0x2c9 at (top.x, top.y−16), link it
  (`top+0x1d4`), its `+0xa6 = 0x78 + parity`, raise the old top's `+0xa6` to ≥ 0x23; same effect,
  light and sound; shot killed directly. Other ids pass through trunks with no effect.
- Trunk sprites (`.HandleBoxSprite`, handler l. 11485–11498, 13651–13653): bottom 0x2c8 gravity
  0x15e, rect (3,4,0x1d,0x18); segment 0x2c9 gravity 0, rect (3,3,0x1d,0x15); a segment that lands
  becomes a bottom.

### 3.6 Spell 7 ("Ice Wall" #2)  [HIGH for code; HIGH for the art caption (PICT 700), name absent from the manual] ⚑ corrected (review 1a, 2026-10-03) #6
Cost 12, damage 150, Ice-Wall face, 16×16 hot rect, gravity 250, no arc bonus, no particles,
light 0x21, and **no floe/ledge** (those test `+4 == 3` only). Plain impact (effect type 5). Not
granted by the debug kit; whether any shipped scroll grants it is the scroll-census reader's.

### 3.7 Sprite hits and kills
`.HitPlayerShotSprite @ 1005a7fc` (handler l. 5572–5694), `other` = the touched sprite [HIGH]:
| condition | result |
|---|---|
| other is the player, id 5, age > 10 | Boomerang caught: kill (and followers), **magic += 8, no max clamp** |
| other is an enemy shot of type 0x77b | `snd 303` 'metal hit' vol 0xab; `.KillPlayerShot(s,0,1)` |
| id 0x50 vs any enemy shot | `snd 303` vol 0x55; `.KillPlayerShot(orb,1,1)`; `.KillEnemyShot(other)` |
| id 0x50 vs type 0xb7c | nothing |
| Box 0x2c8/0x2c9 | id 4 → trunk growth (§3.5); others nothing |
| Effect class or `HandleEffectSprite` / `PTR_PTR_100a0460` | nothing |
| Bonus types 0x517/0x51b with `+0xb0 ≠ 0`, id ≠ 0x50 | `.KillPlayerShot(s,1,1)` |
| Statue or Box class, no one-way top (`+0x185 == 0`) and no surface fn (`+0x1e8 == 0`) | if other is type 0xb7d, not invulnerable, and `s+0xa4 == 300` → other HP −0x50, flash/invul 10, `snd 419` 'dagger hit' pitched 35000; then `.KillPlayerShot(s,1,1)` |
| Statue/Box with a one-way top or surface fn | `.PlatformBounce`; on contact kill |
| Crawler class | `.KillPlayerShot(s,0,0)` (the Crawler's own Hit does the damage) |
Damage to enemies is applied by the **enemy's** Hit routine: `.HurtSprite(enemy, shot+0xa4,
knock vx = shot.vx·k, −1000, invul 4, flash 10)` and `.KillPlayerShot(shot,0,0)`; id 1 →
`.TurnIntoStatue` **instead of** damage (Crawler sample, handler l. 9888ff; the 12 statue sites:
physics.md §7). The bosses have no statue branch, so Statue hits them for 200·p [MED: per-boss
Hit routines are the enemy readers'].

`.KillPlayerShot(s, sound, effect) @ 1005ac34` (main l. 45377–45521) [HIGH; raw checked]: kills the
followers; no effect sprite when the face is ~~off-screen~~ entirely hidden in a wall tunnel ⚑ wave 2 (2026-10-04)
(the clip fields are this frame's only when called from a sprite collision; from the tile callback they
read 0/32000 except on the age-1 frame — spells-detail-2 §2). id 0: `snd 301` 'fireball hit new'
(Rand), effect type 0 at (x−8, y−12). ids 1–7, 0x3c: `snd 301`, effect type 5 (type 2 for id 4)
at (x−5, y−12), light colour 0x21 (1, 2), 0x4d (3), 0x42 (4), unchanged for 5–7 (reads an
uninitialised register when `effect == 0` [MED]). 0x50: hits left −1; at 0 `snd 424` 'rock crush'
+ `.ExplodeFaceIntoParticles(face, pos, 2,1,7,0x50,0x65)` and die, else `snd 423` 'rock crack'.
0x5a: `snd 435` 'explosion', `_DAT_100a00fc = 3`, `_DAT_1009ffa0 = 0x14` [LOW: screen shake
3 px × 20 frames], big explosion 0x4b7 ('big explosion' `PICT 1207`) at (x−42, y−42) layer 0xc
(tint 0x10004 if Ziridium), and unless `+0xf0`: 8 fragments 0x442 from a 4×4 grid (every second
cell) flung outward at `400 + rand(150)`, `+0x46 = rand(7)`. Types > 100 (the held melee item
while swinging, `.HandleItemUse` main l. 43598): `snd 419` at 0xab if `+0xa6 == 0`, then
`+0xa6 = −6` (6-frame re-hit guard) [MED]. ⚑ corrected (deepening 2026-10-03, held-item-melee.md corr. 1; raw verified by review 1c): the held item is
type **100**, `.KillPlayerShot` returns at once for it (`cmpwi r0,0x64; beq` `1005ac64..1005ac68`), and the
> 100 arm (`1005accc..1005ad08`) is unreachable — no player shot has `+0x04 > 100`; one hit per target
comes from the target's invulnerability [HIGH].

### 3.8 Non-spell player shots
- **0x3c is the V Blade's lower half** (spawned only by `.CastSpell` case 6), not a thrown item.
- **0x50 = Pentashield orb** (`.UpdatePentSprites @ 1004ce64`, main l. 43477–43546): spawned as
  `0x5001` (power 1), layer player+1, record index 0x1ff, `+0x164 = −10` (spawn flash); each frame
  angle += speed (mod 0x16800 = 360·256), placed on radius `+0xc` of its slot around the player's
  centre (−10,−10) [HIGH]. Damage 300, 3 hits, no tiles, no gravity, no light; destroys enemy
  shots on contact (§3.7).
- **0x5a = thrown fire / Ziridium seeds** (`.HandleItemUse`, frame 5, main l. 43612–43632):
  `0x5a01` from the held item's centre (−4 y); vx 0x60e (negated, x +12 px when facing left) +
  player vx; vy −0x60e + player vy if falling; gravity 0xfa; bounce 0.625 until `|vy| < 0x200` →
  explode (§3.7); damage 800/1400. **Ring of Smiting** (`.SmiteEnemies`, main l. 44074–44137)
  spawns a `0x5a01` (with `+0xf0 = 0`) on the centre of up to 16 sprites of the 16 enemy classes.

## 4. MP regeneration  [HIGH]
No passive regeneration exists. Magic rises only by pickups (spells-items §3), the magic
potion/max-upgrade, the Boomerang refund (+8), the debug F1 key, and **standing in liquid kind 3**
(`+0x128 == 3`, after 2 frames of contact; handler l. 1112–1144): breath +8, HP +4 and magic +4
per frame up to their maxima (`G+0xa`, `G+0xc`), with looping `snd` `_DAT_1009fe5c` [MED: kind 3
is a healing pool by effect].

## 5. Hang glider (closes INDEX NOT-RESOLVED 7)

### 5.1 State  [HIGH]
`_DAT_100a05e0` glider on; `_DAT_100a05d4` phase (>0 deploying, 0 gliding, <0 stowing);
`_DAT_100a05d8` pitch −5..5; `_DAT_100a05d0` turn counter; `_DAT_100a05dc` loop-anim counter;
`PTR_DAT_100a05c8` ground-contact frames; `PTR_DAT_100a05cc` dive counter 0..30;
`PTR_DAT_100a05c4` re-pickup cooldown. All zeroed by `.ClearPlayerVars`; the flag also by
`.SetupPlayerSprite`. Faces (`.InitPlayerSprite`, cached 160×160 cells): `PICT 1050` deploy/turn
(`_DAT_100a0778`), `1051` 4-frame glide loop (`0774`), `1052` pitch (`0770`: up 0..2, down 3..5),
`1053` casting (`076c`).

### 5.2 Pickup and deploy  [HIGH]
Touching Bonus type 3050 (0xbea, `$Hang Glider`) with the cooldown at 0 (and the usual Bonus
gates `+0xa6 == 0 && +0xb0 == 0`, not dying; handler l. 3627–3644): pickup removed, glider on,
phase 1, ground count 0, **player snapped to the pickup's position**, face 1050[0], rect
(0x37,0x3e,99,0x6e). Each glider frame the rect is (0x37,0x3e,0x63,0x61) (l. 1479). Deploy
(l. 1628–1659): phase 1 → `vy = 0`, gravity 0; phases 1..23: vx = 0, face 1050[phase>>2], phase+1,
gravity −0x78 once phase > 16; phase 24: gravity += 0x1e per frame while < 100, then phase 0. Net:
16 frames hanging still, 7 frames rising (−120/frame²), 8 ramp frames → glides off with
vy ≈ −720 [HIGH arithmetic].

### 5.3 Gliding (phase 0)  [HIGH; raw 0x1004db58–0x1004dc54, 0x10053a10–0x10053ac4]
- **Steering** (`.HandleKeys` main l. 44587–44609, only while HP > 0 and not item-using): LEFT
  `vx −= 0x96` if vx > −0xc80; RIGHT `vx += 0x96` if vx < 0xc80 (LEFT wins). Pushing against the
  facing past |vx| > 0x300 starts a turn: counter ±12. UP: pitch −1 (≥ −5); DOWN: pitch +1 (≤ 5);
  neither: pitch decays 1 toward 0. JUMP is ignored (l. 44818), wall cling is disabled
  (handler l. 3011), idle/landing effects skipped.
- **Gravity and wind scale by pitch** (handler l. 879–910; C integer division truncating):

| pitch | gravity `+0x110` | wind scale `+0x90` | effective wind (`.StandardSpriteHandles` scales only when `+0x90 < 0xff`) |
|---|---|---|---|
| −5..−1 (nose up) | 20, 40, 47, 50, 52 | 506, 381, 339, 318, 306 | full (same as level) |
| 0 | 60 | 256 | full |
| +1..+5 (nose down) | 72, 75, 80, 90, 120 | 212, 201, 183, 146, 36 | ×0.83, 0.79, 0.71, 0.57, 0.14 |
  (Swimming/deep-liquid gravity 0x50 and rope 0 are set earlier in the same block; feather fall
  `gravity 0x40, vy ≤ 0x352` still applies afterward when falling, l. 921–928.)
- **Speed limits**: `vy ≤ 2000` (l. 1495, while alive); `vy ≥ −0x9c4` (`.PlayerConstraints`, main
  l. 43382); air drag 0x14 per frame toward 0 (l. 1252–1262), on the ground too.
- **Dive / pull-up** (l. 1508–1546, only when no turn is running and the wand step < 3): pitch
  4..5 → dive counter +1 (≤ 30) and `vx ±= 0x50` in the facing direction up to ±0xc80; pitch 1..3
  with a dive counter c > 0 → `vy += trunc(−0x640·c/30)` per frame (raw `mulli −0x640`, magic /30);
  the counter resets only at pitch 0. So releasing DOWN after a full dive gives up to 3 frames of
  −1600 lift (then the −2500 floor).
- **No stall**: gravity is ≥ 20 at every pitch, so the glider always sinks in still air; height is
  gained only from updrafts (wind, physics §6, vy impulse unscaled by the nose-up settings) or the
  dive pull-up [HIGH arithmetic; "no stall" is an absence finding].
- **Faces**: loop 1051[(c>>3)] (c 0..31); pitch faces 1052; casting 1053[step−3] for steps 3..6;
  turning: counter decays 1/frame, face 1050[|t|>>1 capped 5] (or [5−that] for < 3), facing flips
  at |t| < 6, at 0 → 1051[0].
- **Casting**: allowed; spawn offset +30 x, +35 y (§2.3). While the wand step ≥ 3 the dive
  acceleration and pull-up are suspended (they sit in the `step < 3` branch).

### 5.4 Landing and stowing  [HIGH]
Ground contact (`+0xce` or `+0xcd` set, not riding a platform `+0xdc`): count +1, `vx = trunc(vx·0.5)`
(`dRam100a1a28` = 0.5, const.py), `vy = 0x100`; airborne or on a platform → count 0 (so a moving
platform never ends the glide). Count > 12 at phase 0 → phase −23 (l. 1492). Stowing (l. 1595–1627):
face 1050[|phase|>>2], vx = 0, gravity 0, vy = 0x100, y −= 2 px while phase < −16; at phase 0:
a glider pickup 0xbea (`.SetupBonusSprite`, layer 2) is dropped at the player's position, cooldown
180 frames, glider off, gravity 0x1b8, **x += 30 px, y += 32 px** (10 px if `PTR_DAT_100a04cc` — ⚑ wave 2 (2026-10-04): the 15-frame "landed on a
BG-tile surface" timer, spells-detail-2 §1),
standard face and rect (0x26,0x22,0x3e,0x55).
- **No other cancel**: the only writers of `_DAT_100a05e0` are `.ClearPlayerVars`,
  `.SetupPlayerSprite`, this stow, and the pickup (`tools/tocrefs.py 100a05e0`); water, damage and
  ropes do not end a glide.
- **Death while gliding skips the Resurrection Necklace** (handler l. 1705, 1791:
  `glider ≠ 0 → DAT_100a5106 = 1`, the no-necklace path) [MED: physics §5.2 meaning of the flag].
- **Latent**: `+0x90` is left at the last airborne pitch value after stowing (only the glider and
  death write it after `.SetupPlayerSprite`'s 0x100), so landing nose-down leaves the player with
  reduced wind until the sprite is re-set up [HIGH for the writes; MED for the visible effect].
- `.PlayerScroll` treats the glider like a jump/rope state for the camera (main l. 43151–43166) [MED].

## NOT RESOLVED
1. ~~The meaning of `NewParticle` args 1/2 (colour? gravity?)~~ (closed: particles §2 ⚑ wave 2 corr
   (2026-10-04) PA #3) and of `s+0x84/+0x86` offsets in shot particles (always 0, enemies-flyers §7.1); effect-sprite types 0/2/5/0x442 visuals (effects reader). ⚑ wave 2 (2026-10-04): INDEX items 15/28
   (carried as spells-detail-2 NR 1); not this lane.
2. ~~On-screen test fields `s+0x1b6/+0x1b8` and face `+0xa/+0xe` that gate lights and impact effects.
   (Narrowed: `+0x1b6/+0x1b8` are the left/right draw-clip edges in face-local px, physics §0.1 —
   ⚑ corrected (review 1c, 2026-10-03) #6.)~~ → closed: spells-detail-2 §2 (wall-tunnel visibility test) ⚑ wave 2 (2026-10-04)
3. ~~`_DAT_100a06f0`, `PTR_DAT_100a0700`, `_DAT_100a0570` (HandleKeys gates); `PTR_DAT_100a04cc`
   (stow drop 10 vs 32 px); `+0xcd` (second ground-contact byte); `_DAT_100a075c` reader.~~ → closed:
   spells-detail-2 §1 ⚑ wave 2 (2026-10-04). (`+0xcd`
   closed: grounded at frame start or landed on a sprite this frame — physics §0.1, synthesis ledger A5,
   raw `100368c4..c8` / `100379c4`.)
4. ~~Enemy shot 0x77b's identity; Box 0xb7c/0xb7d (2940/2941) roles; Bonus 0x517/0x51b `+0xb0`.~~ →
   closed by reference: spells-detail-2 §6 ⚑ wave 2 (2026-10-04)
5. ~~`FUN_1003f218` (Boomerang steering) internals; whether same-frame handling of new shots occurs
   (affects first-frame damage and follower lag by one frame).~~ → closed: spells-detail-2 §3, §4 (no
   follower lag exists) ⚑ wave 2 (2026-10-04)
6. ~~Whether a shipped scroll grants spell 7 (scroll-census reader).~~ → closed: none does (INDEX 11,
   pickups-boxes §1.7) ⚑ wave 2 (2026-10-04)
7. ~~Trunk `+0xa6` use (Box reader); `.TurnIntoStatue` duration vs power (statue reader).~~ → closed by
   reference: spells-detail-2 §6 (lifetime; statue fixed 120 frames, power-independent) ⚑ wave 2 (2026-10-04)
8. ~~Orphaned followers (Tree Trunk direct kills) and reuse of a dead follower's slot by a new sprite
   while the main shot still writes to it — code allows both; effect in play unverified [LOW].~~ →
   closed as code reading: spells-detail-2 §5 (four orphaning paths, orphan behaviour, allocator
   condition for reuse); how often reuse happens in play stays open there (NR 3) ⚑ wave 2 (2026-10-04)

## Proposed additions to physics.md §0
| off | type | meaning |
|---|---|---|
| +0x90 | i16 | wind scale: wind impulse ×`+0x90/256` when < 0xff, full at ≥ 0xff, wind off at ≤ 0 (player 0x100; glider §5.3; death 0) |
| +0x14c | i32 | player shot: age, −1 at Setup, +1/frame to 200 |
| +0x158 | i32 | crunch strength passed to `.CrunchTile` (shots 1, seeds 2, Ice Pick 4) |
| +0x160/+0x164 | i32 | shot follower step x/y (0x50: `+0x164` = flash timer) |
| +0x168/+0x16c | i32 | shot stack offset x/y (0x50: hits left / tint phase; platform 0x57c: `+0x16c` floe variant 0/1/2) |
| +0x1aa | i16 | draw angle in degrees (10·direction) |
| +0x1d4..+0x1e0 | ptr ×4 | shot followers; trunk chain link (`+0x1d4` = segment above) |
| +0xf0 / +0xf4 | i32 | seed: no-fragments/invisible flag / Ziridium flag |
| +0x9a | i16 | light handle (`.AddLight` result, −1 none) |

## Corrections to the existing bank
| # | file § | old reading | new reading | evidence |
|---|---|---|---|---|
| C1 | spells-items §2.1 ids 2, 7 | "(unnamed, not in the manual)" | names only (review 1a adj. 1): 2 = "Ice Crystals" (cost 10, gravity 0, unholdable), 3 = "Ice Wall" (floes/ledges), 7 = second "Ice Wall" icon (cost 0xc, dmg 0x96, gravity 0xfa, no floe); PICT 700 captions 0..11 = Fireball, Statue, Ice Crystals, Ice Wall, Tree Trunk, Boomerang, VBlade, Ice Wall, DensityBall, Sandstorm, EnergyBolt, Ice Shards [HIGH, review 1a] | §1 |
| C2 | spells-items §2.1 id 2 | "a scroll of id 2 is converted to id 3 on pickup" | also **every HUD redraw** rewrites any held spell 2 to 3 | main l. 4713–4715, raw 0x10009188 |
| C3 | spells-items §2.1 row 0x3c / §2 "non-spell player shots 0x3c, 0x50, 0x5a (thrown held items)" | 0x3c a thrown item | 0x3c = V Blade lower half; 0x50 = Pentashield orb; 0x5a = seeds and Smiting blasts | §3.8 |
| C4 | spells-items §2.1 row 0 | Fireball "particles" | Fireball emits no particles in flight; ids 2/3/4 do (2/5/7 per frame); id 4 has **no face** | handler l. 5157–5229 |
| C5 | spells-items §2 item 6 | double's copy "with the same velocity" | power 1, **0 damage**, vy −0x44c when the double's replayed frame is grounded and the shot has gravity, vx sign from the double's facing | §2.3, raw 0x10052700ff; ⚑ corrected (review 1c, 2026-10-03) (adjudication B21): confirmed from raw — copy type id·256+1 (10052714..1005272c), no `+0xa4` store on the copy (only 0x50 arm at 1005949c) [HIGH] |
| C6 | spells-items §2 item 7 | trailing copies spaced 6/10 px | followers are power-0, harmless, repositioned each frame; hit rect stays at the stack centre; followers can still petrify | §2.4; ⚑ corrected (review 1c, 2026-10-03) (adjudication B22): confirmed — follower type = id<<8, power 0 (100595b0..100595e0), `+0xa4 = 0` after the first-frame `mullw` (10059fc0) [HIGH] |
| C7 | spells-items §2 items 1–2 | "if magic is 0 …"; "animation counter reaches 4" | `G+0xe < 1`; cast is on the press frame; presses at wand steps 1/2/4–6 are swallowed; shield raised blocks; fresh press required | §2.1–2.2 |
| C8 | physics.md §8.9 mode 4 | "[MED: … who sets mode 4 on a code-spawned floe was not traced]" | the shot code writes `+0xb0 = 4`; DoSetup keeps it (`+0x48 = −1`); `+0x16c` 1/2 = wall ledges from Ice Wall — HIGH | §3.4 |
| C9 | spells-items §4 items | 0x12 "Hammer?", 0x14 not seen | HUD `PICT 702` captions (and Sprites PICTs 3200+id): 7 Locket, **8 Hammer**, 9 Poppy Muffin, 0xa Alg. Piece, 0xb Alg. Frame, 0xc Algernon, 0xd Gwendolyn, **0x12 Ice Pick**, **0x14 Light Orb**; PICT 702 ids 0..11 also give **1 Steel Key**, 5 Health Ptn. [HIGH for ids 0..11 art, review 1a; MED for 0x12/0x14 (PICT 3200+id names)] | §1 |
| C10 | physics.md §4 glider | "air drag 20 on the glider"; glider hot rect | drag also on the ground; full glider model §5 (pitch gravity, wind scale, vy cap 2000, floor −2500) | §5 |
| C11 | physics.md §7 (review 1a #5, adj. 2–3) | Bat "HP 100, 200"; "Statue/Box/Platform set +0x185"; Floater rect (0x17,2,0x38,0x5c) | Bat 1740 family 500 (`1007dcc0`), 1850 family 100 (`1007dde0`), insects 200 (`1007e144`); the Statue does **not** set `+0x185` (no store in `100664a8–100665bc`, `10043138–100431c4`; thaw −200 `1006656c–10066574`, `+0x130 = 0x78` `10043194`); shipped 1780 rect (0x23,1,0x3e,0x4b) `10081550–1008155c` | enemies-flyers, enemies-water-cave |
| C12 | physics.md §2 water gravity (review 1a #2, adj. 4) | `max(0.7·g, 0x100)` in water | only when `+0x11c ≠ 0` at entry (`100375c8`); zeroed per frame (`100369ac`), so a first call each frame uses dry gravity; only a second same-frame call (Frog) or a direct `+0x11c` writer (Bonus 1055, 1350) takes the 0x100 branch | enemies-water-cave §0.1 |
| — | (wave 2) | — | ⚑ wave 2 (2026-10-04): wave-2 corrections (S1..S4) are in spells-detail-2 "Corrections to the existing bank" | — |
