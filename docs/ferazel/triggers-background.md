# Ferazel's Wand 1.0.3 — switches, triggers, background sprites (part 1 of 2)

Code readings only; nothing behaviour-verified.

Date 2026-10-03. Sources: `ghidra/Ferazel_handlers.decompiled.c` ("handler dump", every
Setup/Handle/Hit callback), `ghidra/Ferazel_pef.decompiled.c` ("main dump"),
`ghidra/Ferazel_pef.disasm.txt` (raw disasm, cited as `@ 1007xxxx`), data-section constants via
`tools/const.py`, TOC slots resolved TOC word → TVector → code (`tools/pef.py` `u32`; method
INDEX §Provenance). Game data: `Ferazel's Wand World Data.rsrc` (`Mlvl` placements),
`Ferazel's Wand Sprites.rsrc` (PICT names/sizes), `Sounds.rsrc` (`snd ` names).
Labels as INDEX §Labels. Scope: class **Button** (1320..1329); class **Background**, every
type range of world-data-format.md §3.5; level exits, passages, cannons, springs (extension of
physics §8.3), hazards; cross-references for conversation/teleport triggers owned by the Box
class. Part 2 (`triggers-background-2.md`): chains and see-saw segments, the **Effect** class
(effect-id table), timer digits, parallax (`Px`) sprites, NOT RESOLVED, proposed §0 fields,
corrections.

Conventions: `rec(i).pN` = placement param N of record i (world-data §3.4; code reads
`hdr + i·16 + {8,10,0xc,0xe}` = p1..p4). `s+0xNN` sprite fields (physics §0). `SetRect(l,t,r,b)`
is QuickDraw order; the rect is stored at `s+0x34` as top,left,bottom,right. Velocities 1/256
px/frame. "snd N 'name'" = sound resource id and name, resolved by mapping `.InitSounds @ 10045838`
(`FUN_10091748(id)` → `*_DAT_… = handle`) to the TOC global the handler uses [HIGH for each
mapping cited].

## 0. Census of shipped placements (all 24 `Mlvl`, this session)

Python over every active record (`flag ≠ 0`), class by `tools/gensprite_map.py`; 1,298 records
are Background or Button. **Record byte +1 is 0 in every one of them**, and no Button/Background
routine reads it [HIGH for both]. Types absent from the shipped levels are not listed (none of
1098/1099, 1154..1159, 1483/1484/1489, 1855..1859, 2703/2704/2706..2709/2712/2715..2799,
2894..2899, 3000/3001/3003..3019, 3087..3089 is placed).

| type | n | levels | p1 | p2 | p3 | p4 | reading (§) |
|---|---|---|---|---|---|---|---|
| 1090 | 73 | 1,10,11,15,40,50,51,52,62,67 | −2..105 (7 vals) | 0..480 | 0..3600 | 0,1,200,400 | cannon, initial aim up (§2.2) |
| 1091..1097 | 11/20/2/23/6/31/5 | 10..62 | −2,−1,0,101,103,105 | 0..440 | 0..3000 | 0,200 | cannon, aim (type−1090)·45° |
| 1150/1151/1152/1153 | 30/11/7/9 | 15,30,31,40,50,62 | 0 | 0 | 0 | 0 | springs (§2.3) |
| 1208 | 89 | 40,50,51,62,67 | 0 (82), 1 (7) | 0 | 0 | 0 | floor fire (§2.4) |
| 1320 | 2 | 4,50 | 1 | 0 | 0 | 0 | switch (§1) |
| 1322 | 22 | 3,4,10,11,21,30,31,50,51,52,62 | 0 (11), 1 (11) | 0 | 0 | 0 | floor plate (§1) |
| 1480/1481/1482 | 6/1/3 | 20,22,30,50 | 0,10,11 | 0,140..182 | 0,1500 | 0 | swinging/circling bar (§2.5) |
| 1485 | 77 | 1,10,11,20,22,40 | 1,2,10,12,13,14 | 96..700 | 0..2600 | 0..700 | spiked ball (§2.5) |
| 1486/1487/1488 | 34/1/30 | 30,31 / 21 / 62 | 1,2,10,12,13 | 80..450 | 0..3000 | 0..400 | same family |
| 1840/1841 | 87/81 | 3..62 | 0 | 0,25..60 | 0..100 | 0..80 | wall spikes (§2.6) |
| 1842/1843 | 84/34 | 3..50 | 0 | 0..90 | 0..60 | 0..40 | floor / ceiling spikes |
| 1900..1903 | 18/35/18/29 | 22,30,31,45,62 | 0 | 0 | 0 | 0 | arrow traps (§2.8) |
| 2700..2714 | 45 total | 1,15,18,25 | 0/1 | 0,6,7,22 | 0/1 | 0 | plants (§2.9) |
| 2890..2893 | 44/44/32/44 | 20 | 0 | 0 | 0 | 0 | foreground clouds (§2.10) |
| 2900 | 54 | 2,4,10,11,21,30,50,51 | 3..314 (49 vals) | 0 | 0/1 | 0 | passage (§2.11) |
| 2901 | 4 | 62 | 112,113,116,225 | 0 | 0 | 0 | ornate passage |
| 3002 | 20 | 1,20,22 | 0 | 0 | 0 | 0 | wall tunnel (§2.12) |
| 3060 | 53 | 20,22,30,62 | 0,1,180 | 0 | 0 | 0 (22), 1 (31) | rotating sword (§2.13) |
| 3080..3086 | 4/5/5/7/4/4/2 | 10,11,15 | 0/1 | 0 | 0 | 0 | trees (§2.14) |
| 3249 | 48 | all but 67 | −1 (25), 0, 1, 2 | 0, 2 | 0 | 0 | level exit (§2.15) |

## 1. Class Button (types 1320..1329)  [HIGH unless noted]

Code: `.SetupButtonSprite @ 10070d30` (handler dump l. 13717–13754), `.HandleButtonSprite @
10070e60` (l. 13756–13830), `.HitButtonSprite @ 100710e4` (l. 13832–13858), `.InitButtonSprite
@ 10070c48` (main dump l. 47969–47986).

**Faces** (`.InitButtonSprite`): 1320 ← PICT 1320 (84×12, 6 cells 14×12), 1321 ← PICT 1321 (84×12,
6 cells 14×12), 1322 ← PICT 1322 (256×21, 8 cells 32×21). PICTs are unnamed. 1323..1329 get no
face and no hot rect from Setup (inert if placed; none are) [MED: relies on the allocator's rect
being empty].

**Hot rects** (Setup): 1320 `SetRect(0,−20,20,12)`; 1321 `SetRect(−4,0,16,12)`; 1322
`SetRect(8,4,24,20)`. Layer 1. Handler/hit installed: Handle = `.HandleButtonSprite` (TOC
0x100a0ac4), hit = `.HitButtonSprite` (TOC 0x100a0ac0). No tile callback.

**State.** `s+0x46` = press level 0..11; `s+0xa0` = last frame's level; `s+0xe4` first-frame flag.
- First Handle call: if `rec(self).p4 ≠ 0` → level = 10 (restores a pressed state from the live
  record / a saved game) (`li r0,0xa @ 10070eb8`).
- Every frame (skipped while `s+0xe9` kill or `s+0x1b2` set): unless (level ≥ 9 **and** p1 == 1)
  level −= 1 (`cmpwi r0,0x9 @ 10070ee4`, `cmpwi r0,0x1 @ 10070f00`); clamp 0..11
  (`li r0,0xb @ 10070f34`). Type 1322 additionally clamps the level to ≤ 9 (`@ 10070fe4`).
- Sound: when the level drops below the previous value and the previous value was 5 → snd 4705
  'buttonup1', vol 0x100, prio 10, positional (`cmpwi r3,0x5 @ 10070f4c`).
- **Output:** if 0 ≤ `s+0x48` < 0x200: `rec(self).p4 = (level ≥ 9) ? 1 : 0` (`cmpwi r0,0x9 @
  10071054`). The button's own record is the switch's output wire.
- Face: 1320/1321 cell `level >> 1` (0..5); 1322 cell `clamp(level − 2, 0, 7)`.

**What presses it** (`.HitButtonSprite`; neither party being killed):

| hitter's handler (`s+0x4c`, TOC slot → name) | effect |
|---|---|
| `.HandlePlayerSprite` (0x100a052c), `.HandlePlatformSprite` (0x100a0200), `.HandleBoxSprite` (0x100a0484), `.HandleStatueSprite` (0x100a01f8) | if level == 0 play snd 4704 'buttondown1'; level += 8 (`addi r0,r3,0x8 @ 10071174`) |
| `.HandleEnemyShotSprite` (0x100a0488), `.HandlePlayerShotSprite` (0x100a04e8) | snd 4704; level = 11 (`li r0,0xb @ 100711b0`) |
| anything else (enemies, effects, background) | nothing |

Net while standing on it: +8 − 1 = +7/frame → ≥ 9 on the second contact frame. Released: −1/frame
→ 11 → 8 in 3 frames (momentary). **p1 == 1 = latching**: once ≥ 9 the decrement stops for
good; the record's p4 stays 1 and is saved with the level's record block (engine §9) [HIGH].
Census: 1322 p1=1 ×11, p1=0 ×11; 1320 p1=1 ×2.

**Linkage (who reads a button).** Consumers name the button by its **placement record index**
and test `rec(index).p4 == 1`. Every `hdr + index·16 + 0xe` read whose index is not the reader's
own `s+0x48` was searched in both dumps (pattern `* 0x10 + 0xe`); exactly two consumers exist
[HIGH for the reads; MED for "only two" — a read through another pointer form would escape the
pattern]:

| consumer (Box class, owned by the Box reader) | code | rule |
|---|---|---|
| gate 2940 (0xb7c) — **not 2941**, see the next row | `.HandleBoxSprite` l. 13234–13280 | p1 ≥ 0: open ⇔ `rec(p1).p4 == 1`; p1 = −1: open ⇔ boss-defeated flag `*_DAT_1009fed0 == 1` (TOC users: the Setup and Kill routines of Warrior, Demon, Chief, Wizard, Xichra; `.KillDemon` sets it when its counter reaches 0, l. 21463; the other Kill writes per bosses.md §1.4, re-derived by review 1b, e.g. `.KillWarrior` 100887a4–100887fc [HIGH]); p1 = −2: open ⇔ countdown `iRam100a5110 > −20` (part 2 §4). Open: y −= 2 px/frame up to 100 px above its base `s+0x158`; closed: back down 2 px/frame |
| weakened ice wall 2941 (0xb7d) — destructible, never a switch gate. ⚑ corrected (review 1b, 2026-10-03) #2 | `.HandleBoxSprite` raw 1006f564–1006f5b0; `.HitPlayerShotSprite` handler l. 5665–5672 | the open flag r19 is forced 0 for type 0xb7d unconditionally (`1006f568 cmpwi r0,0xb7d` / `1006f574 li r19,0x0`), so p1 is never consulted; when HP `+0xa4 < 1` (1006f570–1006f57c) the face explodes (`.ExplodeFaceIntoParticles`, 1006f59c) and `+0xe9 = 1` (1006f5a8). Damage: each player shot whose `+0xa4 == 300` hitting a 2941 with `+0x116 < 1` takes **0x50** HP off it, sets `+0xaa = 10` and invul `+0x116 = 10`, plays a pitched 3D sound (pitch 35000), and the shot is killed. Initial HP 300 and the Ice-Pick identity of the damage-300 hit: pickups-boxes.md §2.4.4, spells-items.md (→ held-item-melee.md) [HIGH for the gate/damage code; MED for what carries damage 300] |
| block 1250..1279 (0x4e2..0x4ff) with p1 == 2 | `.HandleBoxSprite` l. 13306–13325 | solid + visible (rect (1,1,35,35), face) ⇔ `rec(p2).p4 == 1`, else rect empty and the "off" face |

Census of the wiring (all levels): **22 of 24 buttons are referenced** — 19 by exactly one 2940 gate
each; level 4 rec 57 by five 1250 blocks, level 4 rec 63 by four, level 11 rec 162 by five; 2
unreferenced (level 4 recs 30, 31). Every referencing gate has p1 > 0 and every block's p2 target is a
1320/1322 record [HIGH: fresh `Mlvl` census of all 24 levels]. ⚑ corrected (review 1b, 2026-10-03) #5
(was "19 of 24 — 15 by one gate, 2 by three blocks each"). Special gates: p1 = −1 in the boss levels 5, 18, 25, 55 (one each);
p1 = −2 once, level 40 rec 181, paired with the level's only 2907 timer trigger (rec 209, p1 = 300 →
a 5-minute clock). 2940 with p1 = 0 (19 records: L18 ×4, L25 ×4, L45 ×3, L62 ×1, L67 ×7) read
**record 0**, which in those levels is never a button → such gates stay shut unless record 0's p4 is 1
[HIGH reading; the "decorative/closed door" intent is LOW]. The 10 type-2941 records (L30 ×2, L31 ×5,
L62 ×3) also carry p1 = 0, but 2941 ignores p1 (row above): they are shoot-to-destroy ice walls.
⚑ corrected (review 1b, 2026-10-03) #2 (was "every 2941 reads record 0 and stays shut unless record 0's
p4 is 1").

## 2. Class Background

Code: `.SetupBackgroundSprite @ 10071710` (l. 13860–14618), `.HandleBackgroundSprite @
10073afc` (l. 14620–15295), `.HitBackgroundSprite @ 10075044` (l. 15297–15382),
`.InitBackgroundSprite @ 100711f0` (main l. 47988–48059), `.SetupTree @ 10072f50` (main l. 48061).
Spawn: idle (activated near the camera) except 1840..1843, 1480..1489, 2890..2899 (now), and
1090..1099 with p1 < 0 (now) (world-data §3.5) [HIGH].

### 2.1 Common Setup  [HIGH]
Defaults before the type switch (l. 13906–13918): layer `s+0x80` = 1, Handle =
`.HandleBackgroundSprite` (TOC 0x100a0480), **hit callback `s+0x5c` = 0, tile callback 0**,
`s+0xa4` = 6, `s+0xa6` = 3, position from the spawn point. Only cannons (1090..1098), springs
(1150..1153) and wall tunnels (3000..3009) install `.HitBackgroundSprite` (TOC 0x100a0ad4);
every other Background hazard is resolved by the **player's** `.HitPlayerSprite` when its
`(other)+0x4c == .HandleBackgroundSprite` (handler dump l. 4282–4471). The Setup type tree
handles only these sub-ranges (anything else falls through with no face, no rect, no callback —
inert): 1090..1098 (note `< 1099`, l. 13997), 1150..1153, 1208, 1211..1213, 1480..1489,
1840..1843, 1855..1856, 1900..1903, 2700..2799 (faces cached only for 2700..2729), 2890..2893,
2900, 2901, 3000..3009 (`< 0xbc2`), 3060, 3080..3087, 3249 [HIGH].

Frozen-water levels (`hdr+0x26cd ≠ 0`, levels 30/31) give springs and spikes draw effect
`s+0xb8 = 0x10018` (an icy tint); spikes whose base cell is a water tile get `0x90000` [HIGH for
the writes; MED for "draw effect" — `s+0xb8` is read by `.WrapDrawSprites` as
`mode<<16 | arg` and passed to the blitter, modes not decoded here].

### 2.2 Cannons 1090..1098  [HIGH arithmetic unless noted]
PICT 1090 (750×150, unnamed): 5 cells 150×150 cached as one set for all cannon types. Hot rect
`SetRect(0x35,0x38,0x61,0x5b)` (x 53..97, y 56..91: the muzzle well). Layer 1000. Hit = the
Background hit callback. Water: `s+0x16c` = 1 if the base cell is water → each frame
`s+0x11c = s+0x120 = 1` (submerged).

**Aim.** `s+0x46` = aim in 1/32 turns, 0 = up, increasing clockwise in face order; initial
`(type − 1090)·4` → 1090 up, 1091 up-right, 1092 right, 1093 down-right, 1094 down, 1095..1097
the mirrored left-hand aims. Drawing (l. 14763–14800): when `aim mod 4 == 0` face
`k = aim/4` (k ≥ 5 → face `8 − k` mirrored, `s+0x17e = 1`), no rotation; otherwise face 0 drawn
rotated by `s+0x1aa = 2·(((32 − aim)·180/16)/2 mod 180)` degrees [HIGH arithmetic; MED that
`s+0x1aa` is a rotation angle — it feeds the face's +0x1a in `.WrapDrawSprites`].

**Mode by p1** (Setup l. 13999–14125, Handle l. 14677–14800):

| p1 | behaviour | launch speed `s+0x164` |
|---|---|---|
| 0 | fixed; after recoil eases home: `pos = 0.8·pos + 0.2·home` per frame (doubles 0x100a1b18 = 0.8, 0x100a1b10 = 0.2) | 9000 (`li r0,0x2328 @ 10071c3c`) |
| −1 / −2 (or any p1 > 106) | moves on a programmed path (`.SetupProgrammedPath(s, −1, 0)`, physics §8.5: |p1| = 1 vertical, 2 horizontal; p2 travel px, p3 speed); start offset p4 px along the path, direction reversed when p4 == p2; spawned immediately | 8100 (`li r0,0x1fa4 @ 10071c48`) |
| 101 / 102 | rotates +1 / −1 1/32-turn per frame | p4: 0 → 9000, 1 → 7200 (`@ 10071a84`, `@ 10071a98`), else p4 raw |
| 103 / 104 | rotates +2 / −2 per frame | same |
| 105 / 106 | still; a player shot turns it (below) | same; Setup forces p2 = 4 if (105) or (106 and p2 == 0) |

Rotating cannons: a move lasts `s+0x158 = {4, 8, 16}[p3] / |step|` frames (p3 = 0/1/2 → 45°, 90°,
180° per move), then pauses `p2` frames (`s+0xa6`); when the pause ends snd 485 'cannon shift'
(vol 0x41) plays unless already playing. Census: p1=103 with (p2,p3) = (15,2)/(8,1)/(10,0)/(10,2);
p1=101 (15,0)/(10,1); p1=105 once.

**Shot-steered (105/106)** (`.HitBackgroundSprite` l. 15317–15345): a player shot touching the
cannon is killed (`KillPlayerShot(shot,0,1)`), snd 303 'metal hit' (vol 0xab); if the cannon is
at rest, a shot moving left (vx < 0) sets step −1, otherwise +1, for one 45° move — but type 105
only turns when aim > 24 or < 12 (left-moving shot) / aim > 23 or < 8 (right-moving shot); 106
always turns [HIGH].

**Capture** (`.HitBackgroundSprite` → `.TurnIntoCannoned @ 10058594`, main dump): any sprite
whose handler is not Background/Statue/Cannoned/Button/EnemyShot/Effect and whose type is not
1055, 1076, 1905, 1906, 2940, 1475, 1476, with `s+0x130 ≥ 0` — this includes the **player,
enemies, boxes** and player shots of non-105/106 cannons. The captive's handlers are saved
(`+0x1ec/+0x1f0/+0x1f4`) and replaced by `.HandleCannonedSprite @ 10058710`; it is pinned to the
cannon centre (`s+0x1e4` = cannon), velocity 0, light removed; snd 484 'cannon load' (vol 0x97);
cannon `s+0x154 = 6` [unused here]. Not captured: the dead player; a Bonus sprite with
`s+0x168 == 1`.

**Firing** (`.HandleCannonedSprite`, handler dump l. 4640–4888): hold timer `s+0x130 = 15`,
decremented per frame; for the player in a path cannon (p1 < 0) the last step (below 2) only
advances while **jump** (action 5) is held — the player chooses the moment. Fires on the first
frame with timer < 1 **and** `aim mod 4 == 0`. Launch vector with S = cannon `s+0x164`
(doubles 0x100a19e8 = 0.707, 0x100a19e0 = 0.235, 0x100a19d8 = 0.8, 0x100a19d0 = 0.35):

| aim/4 | 0 | 1 | 2 | 3 | 4 | 5 | 6 | 7 |
|---|---|---|---|---|---|---|---|---|
| vx | 0 | 0.707S | S | 0.8S | 0 | −0.8S | −S | −0.707S |
| vy | −S | −0.707S | −0.235S | 0.35S | S | 0.35S | −0.235S | −0.707S |

Then: three smoke effects (Effect type 1090, part 2 §2) at `centre + 1.5·v/256 − 24` (±rand 8);
cannon recoil `pos −= 1.6·v` (0x100a19b0 = 1.6) only when p1 ≥ 0; captive `pos += v`; if
vy > 0 the stored velocity is `vx·0.7, vy·0.55` (0x100a19a8, 0x100a19a0); snd 483 'cannon
shoot' (vol 0x100); original handlers restored; re-entry block `s+0x130 = −5` (player) /
`−35` (others) — HitBackground refuses captives with `s+0x130 < 0` [HIGH for the writes; the
re-increment of `s+0x130` was not traced — NOT RESOLVED]. Player: `_DAT_100a05b8 = 1` (the
launched flag, cleared on landing, physics §8.7), climb/other state globals cleared, camera
re-centred. A captive of type 90 gets gravity 0x15e [HIGH; identity of type 90 not resolved].

### 2.3 Springs 1150..1159 (extends physics §8.3)  [HIGH]
Faces: PICTs 1150, 1151, 1152 (240×60, 4 cells 60×60); 1153 reuses the 1152 sheet mirrored
(`s+0x17e = 1`). Hot rects: 1150 `(4,10,56,60)`, 1151 `(4,0,56,50)`, 1152 `(0,4,50,46)`,
1153 `(10,4,60,46)`. `s+0x1ba = 32000` (no clip). Hit = Background hit callback.
- **Cooldown resolved:** `.HandleBackgroundSprite` (l. 14805–14834) does `s+0x46 −= 1` every
  frame, clamped to 0..3, and shows face `s+0x46`. The hit sets 4 → faces 3,2,1,0 over the next
  four frames, the spring re-arms when 0.
- **Excluded hitter class resolved:** `PTR_PTR_100a0460` = TOC slot 0x100a0460 → TVector
  0x100a229c → `.HandleEffectSprite @ 10061160` — effects never trigger springs.
- **1154..1159 are inert**: no Setup branch (no rect, no face, no hit callback), no Handle branch
  — the "sound only" row of physics §8.3 is unreachable (and none is placed). ⚑ corrected (review 1c, 2026-10-03)
  (adjudication A4): confirmed from raw — Setup arms only for 0x47e..0x481 (`10071cc0`/`10071d14`/
  `10071d68`/`10071db8`, each `stw r30,0x5c`), 0x482..0x487 → `10072e8c` with default `+0x5c = 0`
  (`1007178c`); `.HitBackgroundSprite` `100750f4` tests the whole 0x47e..0x487 band but is never
  installed for 0x482.. [HIGH].

### 2.4 Fire 1208 (and 1211..1213)  [HIGH]
1208: two 16-cell sheets PICT 1208/1209 (1536×72, cells 96×72) alternated by parity of a
0..31 counter (`s+0x46`, face = sheet[c & 1][c >> 1]) → 32-frame loop. Hot rect `(7,36,89,72)`,
layer −32000 (`li r0,-0x7d00 @ 10071e3c`), `s+0xa4 = 0xe0`. p1 selects a tint: 1 → `0x10004`,
2 → `0x1000b`, 3 → `0x1000f`, 4 → `0x10017` (written to `s+0xb8`) and copied to `s+0x14c`.
1211/1212 (side fire, sheet PICT 1211 72×1536 = 16 cells 72×96; 1212 mirrored) rect
`(32,4,72,92)`, layer 32000; 1213 (ceiling fire, sheet PICT 1212 cells 96×72) rect
`(4,0,92,32)`, layer 32000; all three loop 16 frames. None of 1211..1213 is placed and no spawner
was found.

**Damage** (`.HitPlayerSprite` l. 4285–4289): types 1208, 1211..1213 call
`HurtPlayer(p, fire, 0xe0, blood 1, invul 0x3c, coins 0)` (`li r5,0xe0 @ 10057e64`) **unless**
the player holds the Fire Charm (item 0x18) **and** `p1 ≤ 0`. A tinted fire (p1 > 0, 7 placements
in level 62) burns through the Fire Charm [HIGH reading; "magic fire" naming LOW].

### 2.5 Bars and spiked balls 1480..1489 ("now" spawn)  [HIGH arithmetic; MED names]
Faces PICT 1480..1489 (one face per type; 1480..1484 128×100, 1485..1488 100×100). Hot rect
1480..1484 `(18,44,110,68)` (a 92×24 bar), 1485..1489 `(22,22,78,78)` (a 56×56 ball). No hit
callback. Mode `s+0xb0 = p1` (0 → 11); defaults written back into the record: p2 0 → 140, p3 0 →
30 (`@ 1007211c / 10072144 / 1007216c`).

| mode (p1) | motion | harmful (`s+0x170`) | solid |
|---|---|---|---|
| 1, 2 | programmed path (physics §8.5: 1 vertical / 2 horizontal; p2 travel, p3 speed), start offset p4; `.ApplyGravityAndSeparateFromTiles` each frame | 1 | yes (`s+0x185 = 0`) |
| 10 | circle: `.MakeRadial(s, x+50, y+50, r = p2, ω = p3, θ0 = p4)`; spins `s+0x1aa = θ + 90` | 1 | one-way flag set (`s+0x185 = 1`) → never `PlatformBounce`d |
| 11 | pendulum: `.MakeRadial(..., r = p2, ω0 = 0, θ0 = p4, g = p3)`, spun as mode 10 | 1 | same |
| 12 | pendulum seen edge-on (depth mode 1) | 1 while in front and depth term < 0x60 | same |
| 13 | circle seen edge-on (depth mode 1) | 1 while in front | same |
| 14 | horizontal carousel (depth mode 2) | 1 while in front | same |
| 3..9 | no motion branch | not set by Setup | yes |

Radial geometry (resolves part of NOT-RESOLVED 14; `.MakeRadial @ 1003d718`,
`.UpdateRadialPos @ 1003debc`, `.FindUpdatedRadialSpeed @ 1003dde4`): record R (0xa4 B,
`s+0x198`): R+0/+4 centre (24.8), R+0x14 angular speed (24.8 degrees/frame, i.e. ω = p3/256
°/frame), R+0x18 angle θ (24.8 °), R+0x1c/+0x20 radius (24.8), R+0x36 pendulum pull g, R+0x38
friction (speed·R+0x38/256 if > 0), R+0x3a depth mode. Position `x = cx + r·T_x[θ]`,
`y = cy + r·T_y[θ]` with tables built by `.MakeRadialTables @ 1003d5c4`:
`T_x = cos(θ)·65536`, `T_y = −sin(θ)·65536` (raw: `bl 0x1009f074` cos → store, `bl 0x1009f08c`
sin → `neg r0,r0 @ 1003d6a4` → store) — **θ = 90° is up, 270° down** [HIGH]. Pendulum:
for θ in 90..270 speed += g, otherwise −= g → oscillates about 270° (hanging down) [HIGH
arithmetic]. Depth modes 1/2 pin x (1) or y (2) to the centre, turn the other component into a
scale `s+0x1ae` and a shade `s+0xb8 = 0xc0000 + k·0x100` [MED], and switch the layer (front
0x7ef4 / behind −300) on R+0x40 < 0x80. Chain links: `.MakeRadiusSprites(s, p2/16 (≤ 24), 0,
type, 24, .SetupChainSprite)` with type 1436 in mode 14, else 1434 (part 2 §1). Example census:
1480 (10,150,1500,0) = radius 150, 5.86°/frame (61 frames/turn); 1480/1482 (11,140..182,0→30,0)
= pendulums with g = 30/256 °/frame².

**Damage** (`.HitPlayerSprite` l. 4293–4302): if player `s+0x116 == 0` and object `s+0x170 == 1`:
`HurtPlayer(p, obj, 0xe0, 1, 0x3c, coins 5)`, player `s+0x116 = 30` (`@ 10057eac..ec0`); then if
the object is not one-way, `.PlatformBounce` (physics §8.1) — modes 1/2 are solid hurting blocks
[HIGH].

### 2.6 Retracting spikes 1840..1843 ("now" spawn)  [HIGH]
Faces: 1840/1841 sheet PICT 1840 (288×128, 12 cells 24×128; 1841 = 1840 mirrored, wall spikes);
1842 PICT 1842 '!Retracting spikes floor' (128×24), 1843 PICT 1843 '!Retracting spikes ceiling'.
Params: p2 = out-time (0 → 32000 = always out), p3 = in-time, p4 = phase (initial counter).
Record write-back off (`s+0x188 = 1`). `s+0xa4 = 500`.

Cycle (Handle l. 14925–15011): counter `s+0xa6` += 1, wraps to 0 past p2 + p3. Counter < p2 →
**extending**: frame `s+0x46` −1/frame to 0 (snd 457 'spike emerge' when leaving frame 11);
else **retracting**: +1/frame to 11 (snd 458 'spike retract' when leaving frame 0). Volumes 0x97
for 1840/1841, 0x41 for 1842/1843. Initial frame 0 if p4 < p2 else 11.
- 1840/1841: face = cell `frame`; hot rect `(0,12,19,116)` (mirrored `(7,12,32,116)`) while
  frame < 2, else empty.
- 1842: y = base + 2·frame, clip height `s+0x1ba = max(0, 20 − 2·frame)` (sinks into the floor).
- 1843: y = base − 2·frame, top-skip `s+0x1bc = 2·frame` (withdraws into the ceiling).
- 1842/1843 hot rect `(0,0,128,32)` while frame < 2.

So a spike is dangerous only in its two most-extended frames. Census: 68 of 87 1840 and 59 of
81 1841 have p2 = 0 → static spikes; timed sets use (p2,p3) = (60,100)/(60,30)/(80,24)/(90,30),
p4 = 0/20/40/60/80 staggering.

**Damage** (`.HitPlayerSprite` l. 4453–4462): `_DAT_100a0758 = 0` (climb state off, physics §8.3),
`PTR_DAT_100a05f0 = 3` [meaning NOT RESOLVED]; if `s+0x116 == 0`: `HurtPlayer(0x70, blood 1,
0x3c, 0)`, `s+0x116 = 30` (`@ 100583f4..10058408`).

### 2.7 Water urchins 1855/1856  [HIGH; none placed]
PICT 1855 '!Water Urchin' (41×24) / 1856 '!Water Urchin 2' (34×28); random mirror (FastRand(100)
> 50); rects `(4,4,36,20)` / `(4,4,30,24)`; Handle sets `s+0x11c = 1` each frame. Damage: if
`s+0x116 == 0`: `HurtPlayer(0x38, 1, 0x3c, 0)`, `s+0x116 = 40` (`@ 10058438..1005844c`).
1857..1859: no Setup branch (inert).

### 2.8 Arrow traps 1900..1903  [HIGH arithmetic]
Faces PICT 1900 (552×92, 6 cells 92×92; 1901 = 1900 mirrored), 1902, 1903. Rect `(32,32,60,60)`,
no hit callback; touching the trap does nothing (`.HitPlayerSprite` Background branch has no
case for it). p1 = reload frames (0 → 45, `@ 10072928`), p2 = detection half-width px (0 → 50,
`@ 10072950`), both written back to the record.

State `s+0x46` (Handle l. 15077–15240): 0..16 animate (face `state>>2`), 17 = armed: count
`s+0xa6` down to 0, then test the player centre (`_DAT_1009fd94/90`) against the trap centre:

| type | fires | trigger zone |
|---|---|---|
| 1900 | right | |py − cy| < p2 and px > cx |
| 1901 | left | |py − cy| < p2 and px < cx |
| 1902 | up | |px − cx| < p2 and py ≤ cy + 35 |
| 1903 | down | |px − cx| < p2 and py > cy |

On trigger: face 5, state 18; next frame snd 499 'ArrowShootSound' (vol 0xab) and
`MTNewSprite(type + 5, x + dx, y + dy, layer 11, −1, .SetupEnemyShotSprite)` — arrow types 1905
(→), 1906 (←), 1907 (↑), 1908 (↓), PICTs 60×8 / 8×60 — with velocity ±0x1000 (16 px/frame,
`li r0,0x1000 @ 10074a98`); (dx,dy) = (32,42), (−32,42), (42,−32), (42,32). Then 8 frames of
state 19, back to state 0 with `s+0xa6 = p1`. Initial state 16 with `s+0xa6 = p1`. The arrow's
damage belongs to the EnemyShot class.

### 2.9 Plants and moss 2700..2799  [HIGH]
Faces PICT 2700..2729 (names 'Leafy Small Plant 1', 'Wavy Small Plant 1', 'Mini Hanging Vine 1',
'Mossy Patch greenish' …), one per type, cached 30 entries only. No rect (the `switch` on
2827/2832..2836 inside this branch is unreachable — those types never enter it), no callbacks,
gravity 0, layer −100. p1 ≠ 0 → mirrored; p2 ≠ 0 → `s+0xb8 = 0x10000 + p2` (census tints 6, 7,
22); p3 ≠ 0 → layer 10000 (in front of the player). Pure decoration.

### 2.10 Foreground clouds 2890..2899 ("now")  [HIGH]
Faces PICT 2890 (unnamed), 2891 '*Cloud 2', 2892 '*Cloud 3', 2893 '*Cloud 4' (only these four
have faces). No rect/callbacks, layer 0x7ef4 (front), `s+0xb8 = 0xb0004`. p1 = x-parallax factor
/256 (0 → 270 + FastRand(60), `@ 10072ba4/10072bb4`), p2 = y factor (0 → p1). Per frame:
`x = 256·viewX + x0 − (256·viewX·p1 >> 8)` (24.8), same for y with viewY and p2 (view =
`PTR_DAT_1009fe78` (v,h)); a factor of exactly 0 pins the cloud to its world spot. With the
default 270..329 the cloud scrolls 1.05–1.29× the camera — a near-foreground layer. All 164 are on
level 20 (Hangnabit) with zero params. `s+0x15c = FastRand(50)` has no reader.

### 2.11 Passages 2900/2901 (doors within a level)  [HIGH unless noted]
Faces: PICT 2900 'Passage' (68×87), 2901 'Passage (Ornate)' (90×111). Rects `(32,40,36,87)` /
`(44,40,46,100)` (thin vertical threshold strips). 2900 is drawn only when p3 == 0 (p3 = 1 → invisible
passage). No hit callback.

Trigger (`.HitPlayerSprite` l. 4304–4392): while overlapping, first frame requires **UP**
(action 2); counter `*_DAT_100a06f0` +1/frame; at 0: `_DAT_100a05f8 = 1` and a 20-step gamma
fade-out; at 22 the player is moved: the destination is the **idle-table entry whose record index
equals p1** (idle table `DAT_100ac02c`, 0x220-byte entries, +0 used, +0xa x, +0xc y, +0xe record
index — `.AddIdleSprite @ 10007d8c`), keeping the player's offset from the passage; camera snapped
(`view = player − (322, 192)`, 90 `.FindUpperLeftCorner` passes), fade-in, `_DAT_100a05f8 = −15`,
counter `= −22` [the counter's recovery to 0 and `_DAT_100a05f8`'s meaning are NOT RESOLVED].
**p1 = the paired passage's record index**: census 54/54 (2900) and 4/4 (2901) p1 values point
at a record of the same type [HIGH]. **p2 = ambient darkness override** (`hdr+0x2706`,
world-data §3.2): −1 → restore the level default `G+0x22` and clear `G+0x20`; 10 → 0 (full light);
other ≠ 0 → that darkness, `G+0x20 = 1`; 0 → unchanged (all shipped p2 are 0).

### 2.12 Wall tunnels 3000..3009  [HIGH arithmetic; MED purpose]
PICT 3000..3009 'HPassage, n tiles' (n = type − 2999; 128+32(n−1) × 128); faces cached for
3000..3005 only. Rect `(−8,−10, 136+32k, 150)` (k = type − 3000), layer 0, hit = Background
callback. Hit (`.HitBackgroundSprite` l. 15368–15378): any non-Background hitter gets a window
`+0x1be = x+38`, `+0x1c0 = x+89+32k`, `+0x1c4 = y−54`, `+0x1c2 = y+189`. `.StandardSpriteCleanup`
(main l. 32443–32470) then clips that sprite every frame while it is inside the window: left of
the window's middle → visible width `s+0x1b8 = left − x`; else left skip `s+0x1b6 = right − x`
(both clamped to the face width; reset each frame by `.StandardSpriteHandles`). Sprites passing
through vanish behind the tunnel section. 3010..3019 have no branch. Census: only 3002 (20, mostly
The Labyrinth).

### 2.13 Rotating sword 3060  [HIGH]
PICT 3060 '!Rotating sword' (187×187), rect `(5,5,181,181)`, no hit callback. Angle `s+0x46`
starts at **p2**, += **p3** degrees per frame (0 → 8, `@ 10072c68`), wraps 0..359, drawn rotated
(`s+0x1aa`), lit. **p4 == 0 → clip height 94 px** (`li r0,0x5e @ 10074d64`; the lower half hidden,
a blade rising out of the floor); p4 = 1 full. p1 has no reader (census values 1, 180 are
inert). Damage (`.HitPlayerSprite` l. 4394–4441): segment from `(cx + 16 cos θ, cy − 16 sin θ)`
to `(cx + 88 cos θ, cy − 88 sin θ)` (0x100a19f8 = 16, 0x100a19f0 = 88; tables
`_DAT_100a0168` cos, `_DAT_100a0164` sin, built in `.BuildTintTable`) tested against the player's
hot rect shrunk 6 px top / 8 px bottom (`.SectRectLineSeg`); on a hit vx is temporarily set to
±0x8fc away from the hub and `HurtPlayer(0x70, 0, 0x3c, coins 0 (51%) or 4)`, vx restored. No
`s+0x116` gate in this branch. Only one blade segment is tested [HIGH].

### 2.14 Trees 3080..3087  [HIGH arithmetic]
PICT 3080..3087 '*Tree, slight tilt' … '*Tree, horizontal trunk'. No rect/callbacks; layer 30000
(3087: −10); p1 = mirror; idle margins `+0x1c8/+0x1ca/+0x1cc = 0x80`, `+0x1ce = 0xa0` (keeps the
big sprite active further off-screen, `.HandleIdleSprites` main l. 4302–4316). First Handle
calls `.SetupTree`, which spawns invisible Box-class **branch solids** (type 3080, layer 11, rect
= branch rect relative to their own origin; mirrored with the tree):

| tree | branch rects (l,t,r,b relative to the tree face) |
|---|---|
| 3080 | (98,12,180,36) (16,49,102,74) (148,75,214,95) |
| 3081 | (39,11,110,21) (108,31,175,44) (8,59,92,80) (142,70,215,89) |
| 3082 | (66,16,140,35) (150,14,208,35) (20,52,92,73) (192,48,253,68) |
| 3083 | (67,13,150,29) (52,72,109,95) (129,62,188,76) (10,111,68,132) (97,125,165,152) |
| 3087 | one type-3081 solid (11,27,386,70) |
| 3084..3086 | none (bare trees) |

3083 stores its fifth branch into `s+0x1d4` over the first [harmless; HIGH]. Branch collision is
Box-class code.

### 2.15 Level exit 3249  [HIGH]
No face (`s+0xc0 = 0`), rect `(12,12,84,84)`. Touch (`.HitPlayerSprite` l. 4443–4451): snd 421
'teleport out', exit index `uRam100a5116 = p1`, second exit `_DAT_100a5118 = p2` if ≠ 0, level
complete `*_DAT_100a0088 = 1`. The exit index selects which `Mmap` link of the current node is
unlocked (world-data §4.2); −1 unlocks nothing (25 of 48 exits).

## 3. Triggers outside the Background class (cross-reference only)

These answer the brief's trigger questions but are Box-class code (other reader): conversation
starters 2902..2909 (except 2907) and 2833..2836 — first touch (p4 == 0) or UP, shared 90-frame
cooldown `PTR_DAT_100a06cc`, sets p4 = 1; 2902 shows `STR# 500` string p1, others call
`.Conversation(Mcnv p1, …)` when p1 > 100 (l. 3990–4012); **NPC talkers 2951..2969** call
`.Conversation(Mcnv p1)` unconditionally (no > 100 test) when `s+0xb0 == 0`, cooldown 150
(l. 3910–3920). Census: every talker/plaque p1 > 100 is an existing `Mcnv` id (2906 ×4, 2951..2965
×20, 2833/2834) [HIGH]. The boss calls `.Conversation(250/251/252)` itself (`.HandleXichraSprite`).
2907 = countdown timer start (part 2 §4). Teleporters 1060..1062 use the passage mechanism above
(destination = idle entry with record index = p1; mosaic transition, 120 camera passes;
l. 4117–4180). Save point 1065 (l. 4181–). Nothing in the Background or Button class acts as a
camera lock or a wind source: wind is the overlay-tile layer only (physics §6), so its MED
orientation **cannot be settled from the sprite side**.
