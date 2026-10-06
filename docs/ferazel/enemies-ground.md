# Ferazel's Wand 1.0.3 — ground enemies: Walker (goblins), Crawler, Roach, Dillo

Code readings only; nothing behaviour-verified. Date 2026-10-03. Sources: handler dump
`ghidra/Ferazel_handlers.decompiled.c` ("h. l. N"), main dump `ghidra/Ferazel_pef.decompiled.c`
("m. l. N"), raw disasm `ghidra/Ferazel_pef.disasm.txt` (addresses), data constants via
`tools/const.py`, TVector targets via the TOC (`word + 0x1009f840` → TVector → code), sound ids by
matching each sound TOC slot's global against the `FUN_10091748(id)` stores in `.InitSounds`
(`.InitSounds @ 10045838`, m. l. 39508; 129 id↔global pairs matched by regex, every id cited here among them), level census over all 24 `Mlvl` placement blocks (Python,
this session, world-data §3.4 layout). Labels per INDEX. Units per physics.md (px; velocities
1/256 px/frame; frames ≈ 1/30 s). `S` = the enemy sprite, `P` = the player.
⚑ wave 2 (2026-10-04): continued in **`enemies-ground-2.md`** (corpse raft, Crawler/Roach `+0xa6`,
sound-voice helpers, `_DAT_1009fe8c`, enemy-pipe Walkers, Dillo crush mark).

**Scope.** Class Walker (types 1700..1709, 1750..1769), Crawler (1712), Roach (1720), Dillo
(1870..1879). Handlers: `.SetupWalkerSprite @ 10067318` (h. l. 10055–10257),
`.HandleWalkerSprite @ 100683b8` (h. l. 10258–11222), `.HitWalkerSprite @ 1006a260` (h. l.
11223–11328), `.HitWalkerTileSprite @ 1006a740` (h. l. 11329–11391), `.SetupCrawlerSprite @
100659a0` (h. l. 9485–9578), `.HandleCrawlerSprite @ 10065c00` (h. l. 9579–9852),
`.HandleStatueSprite @ 100664a8` (h. l. 9853–9887), `.HitCrawlerSprite @ 100665bc` (h. l.
9888–10014), `.HitCrawlerTileSprite @ 10066aa4` (h. l. 10015–10054), `.SetupRoachSprite @
10077914` (h. l. 15634–15692), `.HandleRoachSprite @ 10077a88` (h. l. 15693–15851),
`.HitRoachSprite @ 1007801c` (h. l. 15852–15931), `.HitRoachTileSprite @ 10078384` (h. l.
15932–15971), `.SetupDilloSprite @ 1008622c` (h. l. 19498–19587), `.HandleDilloSprite @
1008697c` (h. l. 19588–19897), `.HitDilloSprite @ 10087334` (h. l. 19898–19963), `.KillDillo @
100875bc` (h. l. 19964–19987), `.HitDilloTileSprite @ 1008763c` (h. l. 19988–20022). Main-dump
helpers: `.TurnIntoStatue @ 10043138` (m. l. 38018), `.InitCrawlerSprite` (46640), `.KillCrawler`
(46670), `.InitWalkerSprite` (46693), `.STPlay3DSoundPitchedGob` (46720),
`.STPlay3DSoundRandGob` (46733), `.GoblinHurtCry` (46749), `.GoblinRandomCry` (46795),
`.AxGoblinCoreLogic @ 10067840` (46845), `.PopupGoblinCoins @ 10067edc` (47092),
`.HurtGoblin @ 1006a128` (47251), `.KillWalker @ 1006a6cc` (47285), `.InitRoachSprite` (49254),
`.KillRoach` (49267), `.InitDilloSprite` (52780), `.ShootSpines @ 1008648c` (52795),
`.DilloLayEgg` (52887), `.RandomDilloAttack @ 100867fc` (52902); contact damage in
`.HitPlayerSprite` (h. l. 4224–4282, 4512–4625).

**Reading trap (for reviewers).** Ghidra renders the PPC signed-compare idiom
`eqv rT,rA,rB; subfc rD,rA,rB; rlwinm rT,rT,1,31,31; addze rT,rT; rlwinm rT,rT,0,31,31`
(result = `rB < rA` signed) as `(uint)(x <= y) - (~(int)(x ^ y) >> 0x1f) & 1`. The expression
is correct, but its second term is −1 whenever the operands have the same sign, so the first term
read alone gives the **opposite** answer in the normal case. Every such expression below was
resolved from the raw disasm (100694dc, 100679a0, 100863f4, 10086870).

## 1. Census of the shipped placements  [HIGH: Python over all 24 `Mlvl`]

Only 8 types of the 4 classes occur; record byte +1 is 0 in all 225 records and none of the
handlers below reads it (grep of every `hdr + idx·16 + k` access in the listed functions: k ∈
{4, 8, 10, 0xc, 0xe} only) [HIGH].

| type | n | levels (count) | params p1 p2 p3 p4 (count) |
|---|---|---|---|
| 1700 | 47 | 1(2) 2(6) 3(2) 4(5) 10(2) 11(4) 21(5) 22(4) 30(2) 31(3) 45(1) 50(2) 51(5) 52(4) | p1 ∈ {0: 9, 1: 38}; p2 = 1 ×3 (level 2); p3 0×30, 1×8, 3×5, 4×2, 6×2; p4 0 |
| 1705 | 37 | 1(4) 2(6) 3(6) 4(1) 10(1) 11(4) 21(5) 22(3) 31(4) 51(3) | p1 p2 0; p3 0×25, 1×4, 3×7, 5×1; p4 0 |
| 1750 | 50 | 10(8) 11(6) 15(9) 22(2) 30(6) 31(7) 45(4) 62(8) | p1 = 1 ×1 (level 10, no effect); p3 0×14, 1×5, 3×13, 4×8 (all of level 62), 5×1, 6×9 |
| 1760 | 24 | 1(1) 4(5) 10(1) 11(3) 15(1) 21(4) 22(2) 30(2) 51(5) | p1 = 1 ×1 (level 4: bomb thrower); p3 0×17, 1×4, 3×2, 6×1; p4 = 1 ×2 (level 30) |
| 1712 | 31 | 1(3) 2(11) 3(2) 4(6) 10(2) 11(1) 21(3) 22(3) | all 0 (every Crawler starts on the ceiling, HP 500) |
| 1720 | 16 | 1(5) 2(3) 4(5) 21(3) | all 0 (patrol width defaults to 170) |
| 1870 | 19 | 15(7) 22(12) | all 0 (patrol width 150; roll attack disabled) |
| 1871 | 1 | 22(1) | all 0 |

Records with flag 0 but these types: level 1 rec 28 (1712), level 45 recs 272/273/275–278 (1705)
— not spawned.

## 2. Shared machinery

### 2.1 Damage dealt to the player (contact)  [HIGH]
~~`.MTCollideSprites` calls both hit callbacks for intersecting hot rects … The damage is applied by
`.HitPlayerSprite`~~ ⚑ wave 2 corr (2026-10-04) ES2 #W1: the player's `+0x5c` is 0 (`1004af44`/`1004afd4`),
so `.MTCollideSprites` only calls the other sprite's callback; **`.HitPlayerSprite`** runs only in the
later `.MTCollideSpecialSprite` pass (no distance gate, list order; `10007c38`/`10007c64`,
`10032bdc..10032ed8`; enemy-shots-and-damage-2 §4.2), keyed on the other sprite's handler `+0x4c`, then `.HurtPlayer(P, S, dmg, blood, invul, coinsLost)`, which does
nothing if `S.hp < 1` (except enemy shots/boxes; m. l. 45076) — so dead or dying enemies never hurt.

| attacker | dmg | invul frames | coins lost | evidence |
|---|---|---|---|---|
| Walker (any type) | 0x70 = 112 | 0x3c = 60 (**0x24 = 36 for type 1750**) | 3 if `FastRand(100) > 80`, else 0 | default `iVar37 = 0x70`, h. l. 4513; type tests 4603/4606; raw 10057b64–10057ba4 |
| Crawler, Roach | 0x38 = 56 | 60 | 0 | h. l. 4541; raw 10057a20–10057a38 |
| Dillo 1870 | 0xe0 = 224 | 60 | 4 if `FastRand(100) > 60`, else 0 | h. l. 4265–4275; raw 10057d84–10057dc8 (blood flag 0) |
| Dillo 1871 | 0x1c0 = 448 | 60 | 6 | raw 10057dd0–10057df0 |
| Dillo 1872..1879 | none | | | branch returns |

Blood flag = 1 for the Walker/Crawler/Roach path, 0 for the Dillo. `.ShieldBlock` runs first on the
Walker/Crawler/Roach path (h. l. 4523) but not on the Dillo path [HIGH]. Projectiles: §7.

### 2.2 Statue spell (id 1) and `.HandleStatueSprite`  [HIGH]
`.TurnIntoStatue` (m. l. 38018): plays snd 302 'statue hit' (vol 0x32), saves `+0x4c/+0x5c/+0x1f8`
into `+0x1ec/+0x1f0/+0x1f4`, `+0xb8` into `+0x134`, sets `+0x130 = 0x78` (120 frames), vx = vy = 0,
handlers → `.HandleStatueSprite` / `.HitBoxSprite` / `.HitBoxTileSprite` (TOC slots 100a01f8 /
01f4 / 01f0). `.HandleStatueSprite` each frame: adds a light once (`*_DAT_100a099c` = light face
from PICT 820, param 0x21), `+0xb8 = 0x1000b` (draw through colour-remap table 11), `+0x130 −= 1`,
v = 0 (no gravity), layer 2; in the last 20 frames the remap is dropped on odd counts (blink); at 0:
handlers and `+0xb8` restored, **HP −= 200**, light removed. The statue is a full solid for other
sprites (Box hit callbacks; `.HitPlayerSprite` `PlatformBounce`s on it, h. l. 4216) and **does not
set `+0x185`** (no one-way top). The 200-HP thaw penalty is the only "damage" of the Statue spell
on these classes: the shot's own `+0xa4` (200) is never applied (the Hit routines branch to
`.TurnIntoStatue` instead of `.HurtSprite`).

### 2.3 Common hit tests  [HIGH]
A **player shot** counts only when its `+0xa6 == 0` (melee = the held-item sprite temporarily
given `.HandlePlayerShotSprite`, id 100, dmg 100/200/300 by weapon — m. l. 43547ff). A stab lands once per
target although the target's Hit routine runs **twice** per strike frame (the pair is visited both ways): the
second call is the one refused by the invulnerability the first set (held-item-melee §4.1, ⚑ wave 2 corr (2026-10-04) HM W2). Crushing:
when `S` is the mover against a Statue or Box sprite and `.PlatformBounce` returns 2 (contact from
below, physics §8.1): Crawler/Roach/Dillo die if the solid's `vy > 0` or `S` stands on ground
(`hp = 0`, `+0x150 = 0x16`); Walker dies if the solid is not one-way (`+0x185 == 0`) and its type is
not 0x5d2..0x5d6 (enemy pipes); the Walker also tests `.HandlePlatformSprite` solids (raw
1006a520–1006a574). Environmental hazards (`HurtSprite`/`HurtGoblin` 100 dmg, kvy −1000, invul 4,
flash 8 or 10): Effect sprite 0x4b7 with `+0x46 < 8` (all four classes except Dillo), Box 0x5a0
(~~lava/acid pool~~ geyser base or segment, ⚑ corrected (deepening 2026-10-03, geysers.md corr.)) in mode `+0x14c` 1 or 2 (Walker, Roach; Crawler tests `+0x14c == 1 || +0x150 ==
2` — field mismatch, h. l. 9971, raw 1006687c [HIGH as read; intent LOW]).

### 2.4 Liquids (after `.ApplyGravityAndSeparateFromTiles`)  [HIGH]
Gate: `+0x11c ≠ 0` and ((`+0x11c == 1` and kind `+0x128 == 0`) or kind > 0), i.e. fully under plain
water, or touching any other liquid.

| class | kind 0 water | kind 1 (acid) | kind 2 (lava) | kind 3 (brine) | other |
|---|---|---|---|---|---|
| Walker | −150, invul 12, flash 12 | −100, invul 19, flash 17 | same | +4/frame up to 500 | kinds ≥ 4: nothing |
| Crawler | nothing | −100, invul 19, flash 17 | same | +4 up to 500 | |
| Roach | −100, invul 19, flash 17 (every kind incl. 3) | same | same | same (hurts) | |
| Dillo | nothing | nothing | −100, invul 19, flash 17 | +4 up to 500 | |

Each hit plays snd 701 'Crawler Ouch' (vol 0x55); re-hits when `+0x116` has counted down to 0.
Walker also takes **`hdr+0x270e`** HP (raw, no 0 → 0x70 fallback; invul 20, flash 18) whenever its
surface material `+0xd8 == 2` and `+0x116 == 0` and HP > 0 (h. l. 11204–11209). The heal cap is a
hard 500 regardless of the class's starting HP.

### 2.5 Death bookkeeping  [HIGH]
`+0x1b5` = "counts for the enemies-defeated stat", set in every Setup here when the global
`*_DAT_1009fe8c` is non-zero (it is set around `.SetupLevelSprites`, m. l. 2521–2527 [MED]), which
also increments the live-enemy count `*_DAT_1009ffb4`. The Kill routines (once, `+0xe9 == 0`):
count −1, `G + 0x306 + 2·level += 1` (world-data §4.3), `+0xe9 = 1`; Crawler/Roach/Dillo also set
`+0xea = 1` (`.UpdateSprites` then clears the placement record's active byte, m. l. 4936).
Score (`G+0`): Walker 1700 +500, 1705 +600, 1750 +800, 1760 +400 (at the moment of death, raw
10069b70/10069cbc/10069d68/10069e88); Crawler +500; Roach +500 + 100 (`.KillRoach`) = 600;
Dillo +1500 (`.KillDillo`, at the end of the burn).
**Burn-away**: Walker (after its death animation) and Dillo set `+0x1a2 = 1`; the engine's
`.HandleBurn` (from `.StandardSpriteCleanup`, m. l. 32435/38539) ~~erases one face row per frame~~
⚑ wave 2 corr (2026-10-04) DE #7: hides the face by a top clip (`+0x1bc = row`) advancing `+0x8d + 1` rows
per frame from the opaque top, while `.BurnFaceRow` spawns particles along each consumed row (it erases
nothing; `10043e5c..10043e64`, `100438c4..10043974`), and calls the class Kill proc `+0x50` (KillWalker /
KillDillo) when `+0x1a2` passes the opaque bottom `face+0xc` (draw-effects §4.2) [HIGH].
**Idle margins**: `+0x1c8/+0x1ca/+0x1cc/+0x1ce` widen the rect `.HandleIdleSprites` tests before
returning an active sprite to idle (m. l. 4302–4311) [MED: names].

### 2.6 Sounds used  [HIGH: InitSounds pairing; names = `snd ` resource names]

| id | name | used by |
|---|---|---|
| 302 | statue hit | TurnIntoStatue |
| 303 | metal hit | 1705 guard block, Dillo armour block |
| 304 | swoosh big | 1705 thrust, 1760 throw |
| 414 | jump | 1750 jump, Dillo jump |
| 463 | dillo shoot | ShootSpines |
| 465 / 466 / 467 / 468 / 469 | goblingrowl1 / goblingrowl2 / goblintaunt / goblinhurt / goblindie | goblin cries |
| 498 | Egg Drop | Dillo egg |
| 601 | hit ground soft | Walker landing (prev vy > 2000) |
| 610 / 611 / 612 | axgoblinjumproar / axgoblinhit1 / axgoblinhit2 | 1750 |
| 700 / 701 / 702 / 703 | Crawler jump / Crawler Ouch / Crawler uh oh / crawler death | Crawler; Ouch/death shared by all |
| 704 | throw | 1700 throw; 1750 swing (pitch 45000) |

Goblin voice: `+0xf0 = 2·FastRand(0x5fff) + 0xbfff` per goblin (Setup, raw 1006740c–10067424);
`.STPlay3DSoundPitchedGob(S, snd, prio, vol, pos, p)` plays at pitch `+0xf0 + p − 0xffff`
(0x10000 = 1.0) [HIGH]. `.GoblinRandomCry` (every frame unless dying): if `FastRand(500) == 50`
and none of 465/466/467 is playing (`FUN_100916dc` ~~[MED: "is playing"]~~ ⚑ wave 2 (2026-10-04):
HIGH, voice count, global over all goblins — enemies-ground-2 §3): r = FastRand(100) drawn
first — r < 41 → 467 vol 0xab; 41..70 → 466 vol 0x55; ≥ 71 → 465 vol 0x55; pitch 55000 +
FastRand(10000). `.GoblinHurtCry`: r ≥ 86 → 465, 71..85 → 466, 56..70 → 468, else silent; vol
0xab; pitch 65000+/65000+/55000+ FastRand(10000); stops 465/466/468 first (`FUN_10091504`
~~[MED: "stop"]~~ ⚑ wave 2 (2026-10-04): HIGH, stops every voice of that sound in the level —
enemies-ground-2 §3).

## 3. Walker (types 1700..1709, 1750..1769)

### 3.1 Setup  [HIGH: raw 10067318–10067818]
Common: layer 4 (handler re-sets 11 every frame), `+0x158 = 8`, gravity `+0x110 = 0x151`, HP 500,
`+0x14c = 120 + FastRand(70)`, `+0x150 = −1`, `+0x154 = 1000 + FastRand(400)` (`+0x150/+0x154` have
no reader in Walker code), Kill proc `+0x50 = .KillWalker`. Initial state `+0xb0`: 2 for 1700 and
1750, else 5; 1750..1759 then overwritten to 1. `+0x17e` (flip) = 1 for 1760 only, then per type:

| type(s) | face / sheet | flip rule | hot rect `SetRect(l,t,r,b)` |
|---|---|---|---|
| 1700 | PICT 1700 | `P.x < S.x + 50` → 1 | (0x28,10,0x3c,0x46) |
| 1705 | PICT 1705 frame 0 | same | (0x4c,10,0x7c,0x47) |
| 1750..1759 | PICT 1750 | same | (0x5e,0x23,0x7f,0x5c) |
| 1760..1769 | PICT 1760 frame 0 | `S.x + 50 < P.x` → 1 (sheet faces left) | (0x17,0x1e,0x38,0x55) |
| 1701..1704, 1706..1709 | PICT 1700 | none | none (zero rect) |

**Tier = param 3** (`hdr+idx·16+0xc`), selects HP, `+0x158` (1700 throw cooldown base), the remap
`+0xb8` (low word = colour-remap table, `.WrapDrawFace` mode 1, table built in `.BuildTintTable`
[MED: colours not decoded]) and the coin table (§3.6). HP column "1750" applies to type 1750
exactly (`== 0x6d6`), "others" to every other type, including 1751..1759:

| p3 | `+0x158` | HP 1750 | HP others | `+0xb8` | extra |
|---|---|---|---|---|---|
| 0 / ≥7 | 8 | 500 | 500 | 0 | |
| 1 | 16 | 500 | 250 | 0x10010 | |
| 2 | 6 | 1200 | 675 | 0x10011 | |
| 3 | 13 | 1680 | 950 | 0x10012 | |
| 4 | 4 | 2000 | 1500 | 0x10013 | `+0x100 = 1`: immune to fire/trap Background sprites, never flees |
| 5 | 10 | 1500 | 850 | 0x10014 | |
| 6 | 6 | 1350 | 750 | 0x10015 | |

Param 4 ≠ 0 → idle margins `+0x1c8..+0x1ce = 0x5f4` (1524 px; stays active far off-screen).
Param 1: 1700 "never walk" when 1 (§3.3); 1760 projectile type = `0x6e1 + p1` (§3.5). Param 2 ≠ 0:
no knockback from player/enemy shots (§3.7). Faces (`.InitWalkerSprite`, `(PICT, frames, w×h)`
[MED: arg order as in sprites §5]): 1701 walk (8, 100×80), 1702 throw (6, 100×80), 1704 death (8,
94×80), 1706 turn (2, 204×89), 1707 thrust (9, 204×89), 1751 walk (8, 216×110), 1752 swing (6),
1753 jump (3), 1754 death (6), 1760 sheet (9, 84×92).

### 3.2 Per-frame frame of `.HandleWalkerSprite`  [HIGH]
Return if `+0xe9` or `+0x1b2`. `.StandardSpriteHandles`. First frame (`+0x17c == 0`): `+0xb4 = 3`
(flip 0) or −3. Layer 11. `+0x170 > 0` → `+0x16c = 0`, `+0x170 −= 1` (wall-hit lockout).
`.GoblinRandomCry` unless state 4. Type dispatch on **exact** type 1700 / 1705 / 1750 / 1760 (other
types skip to the tail: they fall, take hazards, and never die — no death branch, §3.8). Tail
(h. l. 11058ff): HP < 1 and state ≠ 4 → death entry (§3.8); `+0x16c = 0`;
`.ApplyGravityAndSeparateFromTiles`; landing (on ground now, `+0xcd == 0`): 1750 in state 6 → `+0xa6
= 2 + FastRand(4)`, `+0x46 = 0`, face 1750; previous-frame vy `+0x30 > 2000` → snd 601 pitched
40000 + FastRand(4000); liquids/material (§2.4); burn-row trigger for coins (§3.6); 1700 airborne
and not dying → face 1701 frame 6.

### 3.3 Type 1700 — thrower  [HIGH]
- **State 2 (stand/throw)**, on ground: target x = `P.x + d` if `P.x < S.x`, else `P.x − d`
  (`d = +0x14c`, 120..189). If `|S.cx − target| > 25` and param 1 ≠ 1 → state 1, `+0x46 = 0`.
  Else face 1700, vx halves; if cooldown `+0xa6 == 0`: face 1702 frame `+0x46>>1`, `+0x46++`; at 8:
  snd 704, `+0xa6 = +0x158 + FastRand(26)`, spawn **EnemyShot type = flip (0 or 1)** at
  (`S.x + 10 + (flip == 0 ? 80 : 0)`, `S.y + 20`), layer 0, vx `±(0x618 + FastRand(0x1c2))`
  (1560..2009, sign = facing), vy `−(0x334 + FastRand(0x1c2))` (−820..−1269); if `FastRand(100) >
  90`: |vx| += FastRand(1400), vy −= FastRand(1400) (raw 10068610–10068760). While the cooldown
  runs: `+0xa6−−`, the throw animation finishes (`+0x46` to 11, then 0, face 1700).
- **State 1 (walk)**, on ground: same target; outside ±25 px → `SetSpriteSpeed(±1000, 0x200)`
  toward it; the 16-step walk counter `+0x46` (face 1701 frame `>>1`) runs backwards when walking
  away from the facing direction (moonwalk-correct). Inside ±25: if `+0x46` is 0 or 3 → state 2,
  speed 0; otherwise the counter keeps stepping (vx unchanged) until it is.
- Facing (not dying): `+0x17e = (P.x < S.cx)`.

### 3.4 Type 1705 — spear guard  [HIGH]
Never walks. Friction each frame: |vx| ≤ 0x80 → 0, else ×0.9 if p3 < 3, ×0.7 if p3 ≥ 3
(doubles 0x100a1ab8 = 0.9, 0x100a1ab0 = 0.7).
- **State 5 (guard)**: `+0xb2++`; idle face cycle on 1705 frames by `+0xb2>>2` (0,1,2,1), then
  `+0xb2 = −(60 + FastRand(60))` (frame 1 while negative). Turning: `+0xb4` walks one step per frame
  toward +3 (P right) or −3 (P left), skipping 0; while |b4| < 3 the face is 1706 frame |b4|−1
  and flip = (`+0xb2 < 0`); at ±3 the flip is set (0 at +3, 1 at −3) and face 1705 frame 0.
  **Attack trigger**: `|S.cx − P.x| < 120`, `|P.y − S.cy| < 100`, P in front (flip 1 and P left
  with b4 = −3, or flip 0 and P right with b4 = 3) → state 2, `+0xb2 = 0`.
- **State 2 (thrust)**: idx = `+0xb2>>1`; at `+0xb2 == 6` snd 304; at 16 spawn **EnemyShot 0x6a9**
  at (`S.cx − 80·flip`, `S.cy − 10`), vx = flip ? −3000 : +3000 (raw 10069084–100690bc); face 1707
  frame idx (idx < 9), `17 − idx` (9..11), 0 (12); at idx ≥ 13 → state 5, `+0xb2 = 0`. 26 frames.
- **Guard block**: in state 5 every player or enemy shot that would hurt it (and is not id/type
  0x5a = fire/Ziridium seeds) is destroyed with snd 303 and `+0xb2 = 0` — no damage. The Statue
  test precedes the block, so Statue works in any state (§3.7).

### 3.5 Type 1760 — boulder thrower  [HIGH]
Friction as 1705's ×0.7 branch. **State 5**: `+0xb2++`; blink: when `+0xb4 < −20` face 1760 frame
8, else frame 0, and `FastRand(25) == 1` with `+0xb4 ≥ 0` sets `+0xb4 = −28` (8-frame blink);
flip = (`S.cx < P.x`); if `|S.cx − P.x| < 500` and `+0xb2 ≥ 0` → state 2, `+0xb2 = 0` (no vertical
test). **State 2**: idx = `+0xb2>>1` (face 1760 frame idx); at `+0xb2 == 6` snd 304; at 8 spawn
**EnemyShot `0x6e1 + param1`** (1761 'goblin boulders' / 1762 'bomb boulder') at
(`S.cx ∓ 28 − 16` (−28 when flip 0), `S.cy − 38`), layer `S+1`, shot `+0xa6 = −30`, vy
`−(0x6a4 + FastRand(0x28a))` (−1700..−2349), vx `−(0x514 + FastRand(0x28a))` (−1300..−1949),
negated when flip ≠ 0 (raw 100699f4–10069a3c). idx ≥ 9 → state 5, `+0xb2 = −(40 + FastRand(80))`.

### 3.6 Type 1750 — Ax goblin (`.AxGoblinCoreLogic`)  [HIGH; name MED: error string
"Ax goblin error!" at 0x100a63b0 and snd 610–612 'axgoblin…']
States (`switch` h. l. 10833): 0/3/5 → `.ReportError("Ax goblin error!")`.
- **1 (walk)**, on ground: dir = right iff `P.x < S.cx` (raw 100694dc), inverted when `+0xb2 == 1`
  (so b2 = 1 **advances**, b2 = 2 **retreats**) and again when fleeing (`+0xb6 == 3`, `+0x174 ==
  0`); `SetSpriteSpeed(±0x578, 0x200)` (±1400); walk face 1751 by `+0x46>>1` (16 steps); then
  CoreLogic.
- **2 (swing)**: gravity 0x151, face 1750, vx halves; face by `+0x46`: 0 → 1750, 1–2/3–4/5–6/7–8/
  9–11/12–17 → 1752 frames 0..5. Cooldown `+0xa6` → when 0: `+0x46++`; at 5 snd 704 at pitch
  45000; at 8 `+0xa6 = 10 + FastRand(12)` and spawn **EnemyShot 0x6d6** (axe hitbox) at
  (`S.x + (flip ? 3 : 0x99)`, `S.y + 0x2c`), layer 0, no velocity. During the cooldown the
  animation continues (`+0x46` > 14 → 0 and CoreLogic).
- **6 (airborne)**: rising (vy < 0, `+0x46 < 8`) `+0x46++`, falling fast (vy > 2000, `> 1`) `−−`; face
  1753 frame `(+0x46−1)/3`; air steering: vx moves toward `+0x168` by `|+0x168|/6` per frame; on
  ground: face 1750, vx 0, `+0xa6 > 0` → `+0x170 = 50` and `+0xa6−−`, else CoreLogic. (`+0x46 < 0`
  → count up, at 0 vy = −5000: no writer of a negative value found — dead.)
- **4 (dying)** §3.8. **7** → CoreLogic (no writer — dead).
- Facing (not 4, not mid-swing): flip = (b2 == 2) if `S.cx < P.x`, (b2 ≠ 2) if `P.x < S.cx`;
  inverted while fleeing.

**`.AxGoblinCoreLogic`** (m. l. 46845; raw 10067840–10067e9c). Timers: `+0x160` (<0 → +1),
`+0x164` (>0 → −1), `+0x174` (<0 → +1). Target T: the player (`+0xb6 = 0`, `+0x174 = 0`) unless
(HP ≤ 200 and `+0x174 == 0` and `+0x100 == 0` and `|S.cx − P.x| < 600`) or the player's health
`G+4 ≤ 0`, in which case T = (±32000, ±32000) on the far side from the player and `+0xb6 = 3`
(flee). With `dx = |T.x − S.cx|`, `blocked = +0x16c > 0` (wall hits counted by
`.HitWalkerTileSprite`, §3.7), `wallJump = dx ≥ 110 && blocked`:
1. `dx < 110` or blocked:
   a. `|T.y − S.cy| < 40`, `dx < 110`, not fleeing, not wallJump → **swing**: state 2, b2 = 1,
      `+0x46 = 0`, `+0x160 = +0x164 = 0`.
   b. else if `T.y < S.cy + 25` (target not below) or wallJump: if `0 ≤ +0x160 < 3` → **jump**:
      b2 = 1, flip = (T.x ≥ S.cx) (overwritten by the tail facing rule the same frame), snd 414 (prio 0x14, vol 0x55, pitch 40000+FastRand(4000)),
      FastRand(100) > 80 → snd 610 (vol 0xab); state 6, `+0x46 = 0`; vy = wallJump ? −2000 −
      FastRand(3000) : −50·(S.cy − T.y) − FastRand(600), clamped to [−6250, −4800]; vx =
      wallJump ? ±(3..5)·325 toward T : ((S.cy − T.y)/10)·(T.x − S.cx) + FastRand(400) − 200;
      vx and `+0x168` clamped to ±4200; airborne; `+0x160++`. Else if `+0x160 ≥ 0` (3 jumps used)
      → state 1, b2 = 2 (retreat) with `+0x164 = 30`, `+0x160 = −30 − FastRand(20)`; when fleeing
      `+0x164 = 70`, `+0x160 = −70 − FastRand(20)`, `+0x174 = −120 − FastRand(60)` (flee
      suppressed for 120..179 frames).
   c. else (target lower): r = FastRand(100); `+0x164 = 30`, `+0x160 = −30 − FastRand(20)`;
      r ≤ 10 → hop with b2 = 2, 11..20 → hop with b2 = 1 (state 6, vy −2500 − FastRand(3000)
      clamped to [−6000, −4000], vx kept); 21..60 → state 1 b2 1; ≥ 61 → state 1 b2 2.
2. else if `+0x164 == 0` → state 1, b2 = 1 (advance).

### 3.7 Being hit (`.HitWalkerSprite`, h. l. 11223)  [HIGH]
Other = player shot with `+0xa6 == 0`, or enemy shot with `+0xa6 > 2` and type ≠ `S.type`
(goblin friendly fire; a fresh 1760 boulder is harmless for ~33 frames; the 1750 axe hitbox
0x6d6 has `+0xa6 = 3` and `+0xa4 = 0x70`, so it hurts other goblin types at once; thrown 0/1 have
`+0xa4 = 0` and `.HurtSprite` ignores dmg < 1; 0x6a9 lives 2 frames, never > 2):
- shot id 1 (player) → `KillPlayerShot(1,1)`, `.TurnIntoStatue`.
- else if not dying: 1705 in state 5 and shot type ≠ 0x5a → block (§3.4). Else kvx = param 2 == 0 ?
  `shot.vx/3` : 0, and /3 again for 1750; `HurtSprite(S, shot.+0xa4, kvx, −1000, invul 4, flash 8)`;
  on a hit: n = max(1, dmg/100); `.GoblinHurtCry`; shot killed; `BloodSpray(S, shot, 40n,
  50n + 350, 150n, 2)`; HP > 0 → snd 701 vol 0x55.
- Statue / Box / Platform solids → crush (§2.3).
- Effect 0x4b7 (`+0x46 < 8`) or Box 0x5a0 mode 1/2 → `HurtGoblin(100)`. Background 0x4b8, 0x5c8..
  0x5d1 with `+0x170 == 1`, or 0x730..0x735, only if `+0x100 == 0` (tier ≠ 4) → `HurtGoblin(100)`,
  or 0x113 = 275 for 0x730..0x735. `.HurtGoblin` = `HurtSprite(dmg, 0, −1000, 4, 8)` +
  `GoblinHurtCry` + (1750: FastRand(100) ≥ 76 → snd 611, 51..75 → 612, pitch +0xf0 ± 5000) +
  `BloodSpray(S, other, 40, 400, 150, 2)` + snd 701 if alive.

`.HitWalkerTileSprite` (h. l. 11329): debug no-clip (flag `*_DAT_100a0064` + key 0x32) skips all.
FG hit (`param_4 == 1`): `.WallBounce`; if it returned non-zero, `+0x170 == 0` and the kind is a
wall in the facing direction — kinds 0–2; 4 / 9 / 0x1b / 0x14 facing right (flip 0); 7 / 10 / 0x1c
/ 0x13 facing left; 5 facing left with `param_2 + 16 < S.cx`; 7 facing right with `S.cx < param_2
+ 16`; 0x20..0x23 any — then `+0x16c++` [HIGH as code; MED that these kinds are walls/slopes,
physics §3.3]. Else kind < 100 `.WallBounce`, < 200 `.WallBounceBG(kind − 100)`, else water tiles →
`.HandleUnderWater` (unless `+0x140`). Crawler, Roach and Dillo tile routines are the same without
the wall counter.

### 3.8 Death, corpse, coins  [HIGH]
Entry (HP < 1, state ≠ 4; h. l. 11058–11171): `+0xb2 = 0`, state 4, death cry
(`FastRand(100) < 51` → 469 at 55000+, else 465 at 50000+, vol 0xab), `+0x15c = 0`, score (§2.5),
face = death sheet frame 0, plus per type: **1700** rect reset, top += 0x28, flip 0 → left −= 16,
x −= 24; flip 1 → right += 16, x += 24. **1705** rect = 1700's, type := 1700, x += 35 (flip 0) or 75,
top += 0x28. **1760** rect = 1700's, type := 1700, flip inverted, y += 20, x −= 25 (new flip 0) or
+= 15, top += 0x2a. **1750** keeps its type, face 1754. (1705/1760 thus die as 1700 corpses; the 1700 path sets `+0xea = 1` every frame, so the record's
active byte is cleared at once.)
Animation: 1700 path — face PICT 1704 frame min(b2/3, 7), at b2 == 22 vy −= 800, layer 1,
`+0xea = 1`, vx: |vx| ≤ 128 → 0 else ×0.9; 1750 path — face 1754 frame min(b2/4, 5), vy −= 800 at
b2 == 20, same friction. Once `+0xb2 > 50` (1700 path) / `> 60` (1750): if `S` is in water (`+0x11c` or
`+0x120`, 1700 path only; ⚑ corrected (review 1c, 2026-10-03) (adjudication B4 tail): the read at
`10068adc` precedes the Walker's tile pass, so `+0x11c` is already zeroed and the test runs on `+0x120`
— the previous frame's contact, a harmless one-frame lag) the corpse **becomes a floating platform**: counted as killed,
`+0x4c = .HandlePlatformSprite`, rect (0x10,0x35,0x42,0x47), float line `+0x1a0 = −6`, one-way
`+0x185 = 1`, `+0x13a = 0x20`, `+0x138 = 0x3c` (§8.1 fields) — the player can ride it (h. l.
10541–10552). ⚑ wave 2 (2026-10-04): it **floats**, permanently, hot rect 3 px under the surface
(`y = surface − 68`); water reaches it through the kept tile callback `.HitWalkerTileSprite` →
`.HandleUnderWater` → `.HandleFlotation` — enemies-ground-2 §1 [HIGH]. Otherwise `+0x15c++` per frame, at > 2 burn starts (`+0x1a2 = 1`), the record's
active byte is cleared, and if the player is ≥ 451 px (x) or ≥ 351 px (y) away the sprite is
killed at once (`.KillWalker`), else it burns away (§2.5).
**`.PopupGoblinCoins`** fires once when the burn row `+0x1a2 == face.rect.top + 18` (raw
1006a07c–1006a0a0). From the face rect's centre (flipped), weights by **param 3**:

| p3 | nothing | 2–4 coins 0x516 | 1 small bag 0x50c | 2–4 small bags | 1 big bag 0x50d |
|---|---|---|---|---|---|
| 0 | 70 | 30 | 8 | 0 | 0 |
| 1 | 70 | 30 | 0 | 0 | 0 |
| 2 | 35 | 35 | 20 | 10 | 0 |
| 3, 5 | 20 | 30 | 30 | 20 | 0 |
| 4 | 0 | 10 | 20 | 30 | 40 |
| 6 | 20 | 30 | 40 | 10 | 0 |

r = FastRand(total); the bands are tested from the top (big bag first) with strict `>`, so the
"nothing" band is one value wider and the big-bag band one narrower than the weights [HIGH].
Pickups: layer 0x14, re-centred, vy −2000 − FastRand(1000), multiples vx FastRand(2000) − 1000,
`+0xb0 = 0xc`. Pickup values: spells-items §3 (0x516 coin, 0x50c +5, 0x50d +25).

## 4. Crawler (type 1712)  [HIGH: raw 100659a0–10065b98, 10065c00–10066470]

Setup: layer 11, `+0xa6 = 3` (⚑ wave 2 (2026-10-04): first-leap delay — enemies-ground-2 §2),
`+0xb2 = −1`, `+0x15c = 300` (flee HP), `+0x150 = −1`, rect
(0x14,0xc,0x2c,0x21). **Param 1 = 0** → state 0 (ceiling), gravity −0x151, face slot 0 of
`PTR_DAT_100a09b0`; ≠ 0 → state 2 (floor), gravity 0x151, slot 1. Those slots are loaded from
PICT 1500..1503, which exist in **no** shipped resource file (Sprites/Backgrounds/Titles/app/World
Data PICT lists, this session); the Handle replaces the face on its first frame [HIGH absence;
MED harmless]. **Param 2** = tier:

| p2 | HP (`+0xa4`, max `+0x154`) | speed cap `+0x158` | flee HP `+0x15c` | `+0xb8` |
|---|---|---|---|---|
| 0 | 500 | 1200 | 300 | 0 |
| 1 | 300 | 850 | 100 | 0x10002 |
| 2 | 1000 | 1550 | 300 | 0x10003 |
| 3 | 1600 | 2000 | 200 | 0x1000f |
| < 0, ≥ 4 | 0 | 0 | 300 | 0 (dies at once) |

Faces (`.InitCrawlerSprite`): 1712 single (ceiling), 1710 walk (6,
64×44), 1711 jump (6), 1713 death (6); lights 820/821.
- **State 0 (ceiling)**: gravity −0x151 (held against the ceiling); vx halves; face 1712;
  drops (state 1) when `|S.cx − P.x| < 140` and P is below within 219 px (`S.cy − P.y < 0`,
  |·| ≤ 219), or when HP ≤ max − 100.
- **State 1 (falling)**: writes **param 1 := 1 into the live record** (a reload respawns it on
  the floor); gravity 0x151; on ground → state 2.
- **State 2 (floor)**: walk face 1710 by `+0x46>>1` (12 steps; not advanced while airborne showing
  1711 frame 5 — nothing sets that frame [LOW: dead]). On ground: P more than 60 px right/left →
  `AccelerateBasedOnSlope(±250, cap +0x158)`; `+0xa6` counts down; at 0 with `+0xb2 == −1` and
  `|dx| < 70`, `|dy| < 100` → `+0xb2 = 5` (wind-up: face 1711 frame min(6 − b2, 4), vx held at 0
  around the integration); `+0xb2` reaches 0 → **leap**: snd 700, vy = −2000 − FastRand(1000), vx
  += −(FastRand(500) + `+0x158`) capped `2·+0x158`, sign flipped toward the player if `S.cx <
  P.x`; `+0xa6 = 10 + FastRand(10)`; `+0xb2 = −1`. HP ≤ `+0x15c` (and not winding up) → state 3.
- **State 3 (flee)**: on ground with `+0xa6 == 0`: hop vy −900 − FastRand(400), vx −0x6a4 −
  FastRand(800) capped 2000, flipped to point away from P, stored in `+0x14c`; `+0xa6 = 20 +
  FastRand(30)`. Airborne: vx = `+0x14c`. On ground: vx halves while still moving away (vx < 0 with
  P to the right, vx > 300 with P to the left), else `+0xa6−−`.
- **Facing**: `+0x17e = 1` when `S.cx < P.x`.
- **Death** (HP < 1 → state 4): `+0x5c = 0`, counter `+0x150` 1, 2, …; face 1713 frame
  min((c − 2)/2, 5); vx ×0.97; at c > 21: snd 703, `.KillCrawler`, score +500, 2–4 coins 0x516 at
  (cx − 4, cy − 4) layer 2 (vy −1400 − FastRand(1600), vx FastRand(1000) − 500), 100 particles
  `NewParticle(2, 0x50, (cy + 6, cx − 1), 4, FastRand(600) − 300, −350 − FastRand(700), 0, 1)`.
  A crush sets c = 22 (dies next frame).
**Hit** (h. l. 9888): player shot → shot killed first (`KillPlayerShot(0,0)`), then Statue (id 1) or
`HurtSprite(dmg, 0.65·shot.vx, −1000, invul 4, flash 10)`; `BloodSpray(40, 400, 150, 2)`; HP < 201
→ snd 702 'uh oh' (also on the killing hit), else snd 701. A follow-up "set vx = 0.9·shot.vx"
block compares |S.vx| with itself and never runs (raw 1006668c–100666c0) [HIGH]. No reaction to
enemy shots or Background fire.

## 5. Roach (type 1720)  [HIGH: raw 10077914–10077a50, 10077a88–10077fe8]

Setup: layer 11, `+0xa6 = 3`, state 2, gravity 0x151, HP 200, face PICT 1720 frame 0, rect
(0x23,0x1b,0x44,0x2d), `+0x150 = −1`, home `+0x154 = S.x` (spawn left edge), **vx = 0x4b0**,
**param 3 = patrol width; 0 → writes 170 (0xaa) into the record**. Faces: 1720 walk (6, 100×54),
1721 death (6).
- Walk face 1720 by `+0x46>>1` (12 steps), every frame.
- **State 2 (patrol)**, on ground: w = p3/2 (85). `S.cx < home − w` → accelerate +100 (cap 1200),
  `+0x17e = 1`; `S.cx > home + w` → −100, `+0x17e = 0`; inside the band: flag 0 and vx > −1200 →
  −100; flag 1 and vx > 1200 → +100 (clamps to 1200) — rightward travel coasts inside the band,
  leftward travel keeps accelerating [HIGH as code]. `+0xa6` counts down (no reader; ⚑ wave 2
(2026-10-04): its only readers are in unreachable state 3 — enemies-ground-2 §2).
- State 3 (hop-flee, same arithmetic as the Crawler's) is entered only from state 3 itself (HP <
  3) — **unreachable** [HIGH].
- Death and crush exactly as the Crawler (death sheet 1721), score +500, plus +100 in
  `.KillRoach` → **600**.
- **Hit**: player shot killed first; Statue; else `HurtSprite(dmg, (short)(shot.vx>>1), −1000, 4,
  8)`; Effect 0x4b7 / Box 0x5a0 → 100 with kvx = other.vx>>1; snd 702 if HP < 3, else 701.
- Liquids: every liquid hurts (§2.4) — a submerged roach dies in 2 hits.

## 6. Dillo (types 1870..1879; "armadillopine")  [HIGH: raw 1008622c–10086454, 1008697c–
10087330; name MED (bank)]

Setup: layer 8, gravity 0x122, HP **1870 → 500; 1871 → 1100 with `+0xb8 = 0x1000b`** (remap 11,
the statue-grey table); other types HP 0 (die on the first frame); max `+0x168 = HP`; `+0x188 = 1`
(**no record write-back**: always respawns at its placement, `.UpdateSprites` m. l. 4924); rect
(0x1a,0x17,0x4a,0x3a); state 6, `+0x46 = 2`, `+0xa6 = FastRand(10)`; **param 2 = patrol width,
0 → writes 150 into the record**; bounds `+0x15c = S.x − w/2`, `+0x160 = S.x + w/2`; flip =
`FastRand(100) > 50` (raw 100863f4); Kill proc `.KillDillo`. Faces (`.InitDilloSprite`): 1870 walk
(6, 100×80), 1871 curl (5), 1872 death (5), 1873 jump (2) — both types use them.
`+0x17e = 1` means moving/facing **right** (walk vx = flip ? +v : −v).
- **State 6 (idle)**: face 1870 frame 0; vx ×0.5; `+0xa6` counts down; at < 1: r = FastRand(100),
  t = FastRand(16) − (HP·100/max) + 92 (raw 10086a28–10086a6c). **r > t → walk** (state 7,
  `+0x46 = 1`, `+0xa6 = 2 + FastRand(3)` cycles; FastRand(100) > 100 − t → fast (`+0x14c = 1`)
  else slow (`0`) and then FastRand(100) > 80 → `.DilloLayEgg`, which here only makes the walk
  fast for 5 cycles); turn: `S.x > +0x160` → flip 0, `S.x < +0x15c` → flip 1. **Else →
  `.RandomDilloAttack`.** A healthy dillo almost always walks; attack odds rise as HP falls.
- **State 7 (walk)**: slow: face 1870 frame `+0x46>>1`, vx ±0x400 (1024), cycle = 11 steps; fast:
  face frame `+0x46`, vx ±0x800 (2048), cycle = 5 steps. Per cycle `+0xa6−−`; outside the bounds →
  `+0xa6 = 0`; at 0 → state 6, `+0xa6 = 8 + FastRand(20)`.
- **`.RandomDilloAttack`** → state 8, `+0x46 = +0xb2 = 0`; r = FastRand(100): if r > 75 and
  **param 1 ≠ 0** → mode 3 (roll): flip = (`S.cx < P.x`), `+0x14c` = 1 (width < 150) or 2, +1 if
  flip; else r ≤ 35 → mode 0 (spines), 36..50 → `.DilloLayEgg` (mode 2, `+0xa6 = 5`), ≥ 51 →
  mode 1 (jump); modes 0/1 `+0xa6 = 16`; `+0x14c = 1 + FastRand(2)` (modes 0–2). Mode in `+0x154`.
  Shipped dillos have p1 = 0: 36 % spines, 15 % egg, 49 % jump, never roll.
- **State 8** (vx ×0.5 each frame): b2 = 0 curl (face 1871 frame `+0x46>>1`, at `+0x46 > 8` → b2 =
  1, `+0x14c++`); b2 = 1: face 1871 frame 4 while `+0xa6 < 16`; `+0xa6−−`; at < 1 and `+0x14c > 1`
  run the mode: **0** face 1871 frame 3, `+0xa6 = 16`, `.ShootSpines(S, 0)`; **1** face 1873 frame
  1, b2 = 3, vy = −0xed8 (−3800), snd 414 (prio 0x14, vol 0xab, pitch 75000+FastRand(4000));
  **2** snd 498 (pitch 63000+), face 1871 frame 3, `+0x14c = 0`, spawn **EnemyShot 0x753 (egg)**
  behind the dillo (x = flip 0 ? S.x + face.right − 23 : S.x + face.left + 5, y = cy − 8, layer
  S−1), vx = flip 0 ? +0x200 : −0x200, vy −800, egg `+0xa4` = 224 (1870) / 448 + remap 11 (1871);
  **3** roll: `+0x164 = 15`, vx = ±(int)(150.796447·15) = ±2261 (double 0x100a1c08), spin angle
  `+0x1aa` ±15° per frame; `+0x14c` drops by one per full turn (24 frames). Then `+0x14c −= 1`;
  ≤ 0 → b2 = 2. So spines fire 1–2 volleys 16 frames apart, one egg, 1–2 jumps, 1–3 roll turns.
  b2 = 3 (airborne): face 1873 frame 1 rising / 0 falling; at the apex (vy < 0 ≤ vy + gravity)
  `.ShootSpines(S, 1)`; on landing → b2 = 1. b2 = 2 uncurl: face 1871 frame `+0x46>>1`,
  `+0x46−−`, roll fields cleared; < 0 → state 6, `+0xa6 = 12 + FastRand(30)` (the `+0x14c == 2 →
  6 + FastRand(12)` arm is unreachable here).
- **`.ShootSpines(S, extra)`** (m. l. 52795): snd 463; EnemyShot **0x754** spines, speed v =
  0x900 (1870) / 0xbb3 (1871), damage `+0xa4` 0x38 / 0xe0, `+0xb8` 0 / 0x1000b; d = (int)(0.7·v)
  = 1612 / 2096 (double 0x100a1c20):

| # | offset from centre | vx, vy | `+0x46` |
|---|---|---|---|
| 1 | (−10, −8) | −v, 0 | 0 |
| 2 | (+10, −8) | +v, 0 | 4 |
| 3 | (−7, −15) | −d, −d | 1 |
| 4 | (+7, −15) | +d, −d | 3 |
| 5 | (0, −18) | 0, −v | 2 |
| 6 (extra) | (−7, −15) | −d, +d | 7 |
| 7 (extra) | (+7, −15) | +d, +d | 5 |

- **Death**: HP < 1 → state 4, `+0x46 = +0xa6 = 0`, snd 703; vx ×0.9; face 1872 frame
  min(`+0x46`, 14)/3; `+0xa6++`; at 45 burn starts; `.KillDillo` at the end of the burn (+1500).
  Crush sets HP 0 (its `+0x150 = 0x16` has no Dillo reader).
- **Hit** (h. l. 19898): only player shots (`+0xa6 == 0`) while HP > 0. **Vulnerable only in
  states 6/7 and only from the front** (shot left of S with flip 0, or right of S with flip 1);
  then shot killed, Statue (id 1) or `HurtSprite(dmg, (short)(shot.vx>>1), −1000, invul 2, flash
  8)`, BloodSpray, snd 702 (HP < 201) / 701, and **`.RandomDilloAttack`** (retaliation, resets any
  walk). Otherwise the shot is killed (`KillPlayerShot(0,1)`) with snd 303 'metal hit' — this
  includes the Statue spell. No reaction to enemy shots, effects or Background fire.

## 7. Projectiles spawned (EnemyShot class, `.SetupEnemyShotSprite @ 1005ba5c`)  [HIGH for the
values set here; flight/tile behaviour belongs to the EnemyShot reading]

`MTNewSprite(type, x, y, layer, recIndex = −1, setup)` (arg order from the `MTNewSprite` body:
`+0x80 = layer`, `+0x48 = recIndex`; it clears all 0x1fc bytes first). Common setup: `+0x46 =
FastRand(5)`, gravity 0xaf, `+0x90 = 0x100`, `+0x8c = 1`, `+0xa6 = 0` then +1 per frame.

| type | from | setup (h. l. 5871ff) | damage to P (`.HitPlayerSprite`) |
|---|---|---|---|
| 0 / 1 | 1700 | rect (8,8,0x10,0x10), gravity 0xaf; face PICT 1703 (8 × 24×24), `+0x46` ++ (0) / −− (1): spin | 0x38, invul 60 |
| 0x6a9 | 1705 | layer 0x14, rect (0,0,0x5a,0xe), gravity 0, life `+0x14c = 2` frames, no face | 0x70, invul 60 |
| 0x6d6 | 1750 | rect (0,0,0x3c,0x18), no face, `+0xa6 = 3` (held: +1 then −1 per frame), HP 0x70, gravity 0xaf | 0x70, invul **36** |
| 0x6e1 / 0x6e2 | 1760 (p1 0/1) | rect (8,8,0x18,0x18), gravity 300, HP 200, `+0x150 = −2 − FastRand(2)` (13 %: further −(3 − FastRand(5))), `+0xeb = 1`; faces PICT 1761 / 1762 (8 × 32×32) | ~~0x38~~ none on contact: `.HitEnemyShotSprite` kills the bomb in the main pass (`1005c9dc..1005caac` → `1005cd28`/`1005cd7c`) before the player pass; the hurt comes from shards 0x6e6 (0x38) / explosion 0x4b7 (0x70) (enemy-shots-and-damage-2 §4.3) ⚑ wave 2 corr (2026-10-04) ES2 #W3 |
| 0x753 | Dillo egg | rect (4,0,0x14,0xe), `+0x46 = 6`, flip random, `+0x15c = 0xf0` (240) | its `+0xa4` (224/448), coins 5 |
| 0x754 | spines | rect (8,3,10,8), layer 0xc, gravity 0; face PICT 1876 (8 × 18×18) by `+0x46` | its `+0xa4` (56/224); none while its gravity > 0; coins 5 if 224 |

Coins-lost rule for shots is the general one (`0x70` → 3 at FastRand(100) > 80; > 0x70 → 5). Each
damaging shot is then `.KillEnemyShot`ed.

## 8. Variants not placed  [HIGH as code]
1701..1704, 1706..1709, 1751..1759, 1761..1769 spawn Walker sprites that no Handle branch drives
(exact-type dispatch): they fall, take hazard damage and can be shot, but on HP < 1 nothing
switches them to state 4 — they stay as frozen, harmless (HP ≤ 0 → `.HurtPlayer` ignores them)
sprites. 1751..1759 additionally get the 1750 sheets/rect and state 1. Dillo 1872..1879 have HP 0.

## NOT RESOLVED
1. Colours of remap tables 0x10..0x15 (Walker tiers), 2/3/0xf (Crawler tiers) and 0xb (statue,
   Dillo 1871): `.BuildTintTable` builds luminance-based remaps over selected CLUT indices; not
   decoded. ⚑ wave 2 (2026-10-04): INDEX item 15, another lane — not attempted by L7.
2. ~~`.BloodSpray` argument meaning; `.HandleBurn` rate details beyond "one row per frame".
   ⚑ wave 2 (2026-10-04): INDEX item 15, another lane.~~ → closed: `.BloodSpray` = (victim, attacker,
   count, speed, spread, kind), the spray aims back toward the attacker (particles §5.3, `100425f8..10042828`)
   ⚑ wave 2 corr (2026-10-04) PA #7; burn rate `+0x8d + 1` rows/frame (draw-effects §4.2) ⚑ wave 2 corr
   (2026-10-04) DE #7.
3. ~~EnemyShot flight, tile and expiry behaviour for 0/1, 0x6a9, 0x6d6, 0x6e1/0x6e2 (bomb), 0x753
   (egg hatching? `+0x15c = 240`), 0x754.~~ → closed: enemies-ground-2 §5 (pointer to
   enemy-shots-and-damage §1.2–§1.6; 0x753 is a 240-frame bomb, not an egg).
4. ~~`HandlePlatformSprite` behaviour for a 1700-type corpse (no platform mode set; `+0x19e`
   buoyancy left 0) — does it float or sink?~~ → closed: enemies-ground-2 §1 (floats; buoyancy ramps
   0 → 0x50 from conversion).
5. ~~Which global `_DAT_1009fe8c` is exactly (set non-zero during level setup [MED]).~~ → closed:
   enemies-ground-2 §4 (load-time counting window, raw `10004da4..10004dc0`).
6. ~~`FUN_100916dc` / `FUN_10091504` = "sound playing" / "stop sound" [MED].~~ → closed:
   enemies-ground-2 §3 (voice count / voice stop, HIGH).
7. ~~Crawler/Roach `+0xa6` initial 3 and Roach `+0xa6` countdown have no consumer in state 2.~~ →
   closed: enemies-ground-2 §2 (Crawler: live cooldown incl. the initial 3; Roach: write-only)
   ⚑ wave 2 (2026-10-04) (EG2 corr #1, own row; marker added by the fix pass).
8. (wave 2) Further open rows for this file live in enemies-ground-2.md NOT RESOLVED.

## Proposed additions to physics.md §0
- `+0x30` i32 previous-frame vy (copied with +0x18/+0x20/+0x28 in `.WrapDrawSprites`, m. l. 10348).
- `+0xcd` u8 previous-frame ground flag (copy of `+0xce` in `.StandardSpriteHandles`); also set 1 by
  `.PlatformBounce` on a landing (`100379c4`) — both readings hold (physics §0.1, synthesis ledger A5).
- `+0xb0` i16 behaviour state; `+0xb2`, `+0xb4`, `+0xb6` i16 per-class sub-state/counters
  (Walker: b4 turn counter, b6 = 3 flee).
- `+0xb8` i32 draw effect: high word mode (1 = colour remap table `low`, 3/4 hurt flash, 0xc
  lighting), low word parameter (`.WrapDrawFace`).
- `+0xea` u8 clear the placement record's active byte (`.UpdateSprites`).
- `+0xf0` i32 goblin voice pitch offset base.
- `+0x100` i32 Walker tier-4 flag (fire-immune, no flee).
- `+0x130` i32 statue timer; `+0x134` saved `+0xb8`; `+0x1ec/+0x1f0/+0x1f4` saved handlers.
- `+0x14c..+0x174` per-class scratch (Walker: 0x14c throw distance, 0x158 throw cooldown base,
  0x15c dead-frame counter, 0x160 jump budget, 0x164 walk timer, 0x168 airborne target vx,
  0x16c wall-hit count, 0x170 wall-hit lockout, 0x174 flee lockout; Crawler: 0x14c airborne vx,
  0x150 death counter, 0x154 max HP, 0x158 speed cap, 0x15c flee HP; Dillo: 0x14c count,
  0x154 attack mode, 0x15c/0x160 patrol bounds, 0x164 roll step, 0x168 max HP).
- `+0x188` u8 suppress record write-back; `+0x1a2` i16 burn row; `+0x1aa` i16 rotation (degrees);
  `+0x1b5` u8 counts for the kill stat; `+0x1c8..+0x1ce` idle-test margins; `+0x1c6` u8 may go idle.

## Corrections to the existing bank
1. physics.md §7 table, Walker row "HP 500, 2000, 1500": HP is selected by **param 3** and
   type (1750 vs others): 500/500/1200/1680/2000/1500/1350 vs 500/250/675/950/1500/850/750 for p3
   0..6 (§3.1; raw 10067608–10067758). Also hot rects differ per type (1705, 1750, 1760).
2. physics.md §7, Crawler "HP 1000, 500, 300, 1600; ±0x151": HP by **param 2** (0 → 500, 1 → 300,
   2 → 1000, 3 → 1600); gravity sign by **param 1** (0 → −0x151 ceiling). Dillo "500, 1100": by type
   (1870 / 1871).
3. physics.md §7 "The Statue/Box/Platform classes set `+0x185`": the Statue state does **not**
   (`.TurnIntoStatue`/`.HandleStatueSprite` never write it; full solid via Box callbacks).
4. spells-items.md §2.1 Statue row "damage 200": for these classes the shot damage is never applied;
   the statue costs the target **200 HP on thaw** (hard-coded in `.HandleStatueSprite`). The Dillo
   blocks Statue from behind/when curled.
5. INDEX NOT-RESOLVED 1 (params) — resolved for Walker/Crawler/Roach/Dillo (§1, §3.1, §4–§6);
   record byte +1 unread by these classes. NOT-RESOLVED 6 — closed for these four classes.
6. Evidence for item 3 (review 1a #5, adj. 2): the Statue does **not** set `+0x185` — no `0x185` store in `100664a8–100665bc` (`.HandleStatueSprite`) or `10043138–100431c4` (`.TurnIntoStatue`); thaw `lha 0xa4; subi 0xc8; sth` at `1006656c–10066574`; `+0x130 = 0x78`, `+0x134 ← +0xb8` at `10043194–1004319c`.
7. physics.md §7 Bat row "HP 100, 200" (review 1a #5, adj. 3): 1740 family **500** (`1007dcbc cmpwi 0x6d6; bge` → `1007dcc0 li 0x1f4`), 1850 family 100 (`1007dde0 li 0x64`), insects 200 (`1007e144 li 0xc8`); Floater row rect (0x17,2,0x38,0x5c) → shipped 1780 (0x23,1,0x3e,0x4b) at `10081550–1008155c`.
8. physics.md §2 water gravity `max(0.7·g, 0x100)` — add the caveat (review 1a #2, adjudication 4): taken only when `+0x11c ≠ 0` at the routine's entry (`lwz 0x11c @100375c8`), before its own `SeparateFromTiles2` (`bl 1003c804 @10037624`); `.StandardSpriteHandles` zeroes `+0x11c` each frame (`100368d4 … 100369ac`), so every sprite's first call uses dry gravity; only a second same-frame call (Frog) or a direct `+0x11c` writer (Bonus 1055 in-water flag, 1350 air bubble) takes the 0x100 branch.
9. spells-items.md §2.1 (review 1a adjudication 1) — names only: id 2 "Ice Crystals" (cost 10, gravity 0, unholdable), id 3 "Ice Wall" (cost 0x1e `1005213c`, dmg 0x12c `10052138`, floes `1005a2e4–1005a30c`, ledges `1005b2c4/1005b2f4`), id 7 second Ice-Wall icon (cost 0xc, dmg 0x96, gravity 0xfa, no floe); PICT 700 captions 0..11 = Fireball, Statue, Ice Crystals, Ice Wall, Tree Trunk, Boomerang, VBlade, Ice Wall, DensityBall, Sandstorm, EnergyBolt, Ice Shards.
