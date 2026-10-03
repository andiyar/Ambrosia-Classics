# Ferazel's Wand 1.0.3 — bosses (3 of 3): Xichra's lair objects, CLUT animation, vestigial fields, loose ends

Code readings only; nothing behaviour-verified. Date 2026-10-04.
Sources: `ghidra/Ferazel_pef.decompiled.c` ("main dump"), `ghidra/Ferazel_handlers.decompiled.c` ("handler dump"), `ghidra/Ferazel_pef.disasm.txt` (raw, cited as bare addresses), `tools/const.py`, `tools/tocrefs.py`, and Python decodes of `Mlvl` 50/51/55/67 (World Data), `clut` 200/220/247/248 and `PICT` 380/385/387/1970–1990 (Backgrounds, Sprites).

Scope: INDEX item 19, i.e. the open rows of `bosses-2.md` NOT RESOLVED (2, 3, 5, 7, 8, 9, 10, 11, 12).
Section numbers continue from `bosses-2.md` (§5–§7). Conventions as `bosses.md` (velocities 1/256 px
per frame; "record k" = the 16-byte placement record at `hdr + 4 + 16·k`, p1..p4 at `hdr + 16·k + 8/0xa/0xc/0xe`).

---------------------------------------------------------------------------------------------

## 8. Xichra's lair (level 67): placements, cannons, minions, gates

### 8.1 `Mlvl` 67 placement census  [HIGH: Python over the 511 records]
Map 28 × 19 tiles = 896 × 608 px (`hdr+0xb280/0xb282`). Player start (x 467, y 620) (`hdr+0x2848/0x2846`).
Records 0..14 are the only non-empty ones. Records 400, 401 and 500 (the ones Xichra writes) are all-zero in the file.

| rec | flag | type | class | p1 | p2 | p3 | p4 | x | y | role |
|---|---|---|---|---|---|---|---|---|---|---|
| 0–3 | 1 | 1208 | Background | 1 | 0 | 0 | 0 | 0 / 96 / 800 / 704 | 364 | floor fire (triggers-background §2.4) |
| 4 | 1 | **1090** | Background | **0** | 0 | 0 | 0 | 386 | 601 | the level's only placed cannon: fixed, aim up (§8.2) |
| 5 | 1 | 1990 | Xichra | 0 | 0 | 0 | 0 | 342 | 78 | the boss (Setup moves it to (325, 72)) |
| 6–8 | 1 | 2940 | Box (gate) | 0 | 0 | 0 | 0 | −28/−29/−29 | 278/175/72 | left-edge gates (§8.5) |
| 9–12 | 1 | 2940 | Box (gate) | 0 | 0 | 0 | 0 | 893/900/894/894 | 278/279/195/86 | right-edge gates (§8.5) |
| 13 | **0** | 1487 | — | 0 | 0 | 0 | 0 | 428 | 319 | inactive (flag 0: never spawned) |
| 14 | **0** | 1485 | — | 0 | 0 | 0 | 0 | 309 | 335 | inactive |

The only Background types 0x442..0x44a in the level are record 4 (1090) and the two cannons that
`.SetupXichraSprite` spawns itself (§8.2). No record carries a cannon p1 ≠ 0.

### 8.2 The three cannons  [HIGH unless noted]
Cannon mechanics are triggers-background §2.2 (aim in 1/32 turns, 0 = up, clockwise; launch table
by aim/4; capture via `.HitBackgroundSprite` → `.TurnIntoCannoned`; 15-frame hold; fires on the first
frame with hold < 1 **and** aim mod 4 = 0). Applied to level 67:

| cannon | created by | type | record | sprite x, y | muzzle well (world, from the hot rect (53..97, 56..91)) | initial aim | mode before phase 3 | mode from phase 3 |
|---|---|---|---|---|---|---|---|---|
| R | placement | 1090 | 4 | 386, 601 | x 439..483, y 657..692 | 0 (up) | p1 = 0 fixed, S 9000 | unchanged |
| A | `.SetupXichraSprite` (`li r3,0x443` 1008df88, `li r7,0x190` 1008df9c) | 0x443 (1091) | **400** | −24, 260 | x 29..73, y 316..351 | 4 (up-right) | p1 = 0 fixed, S 9000 | p1 = 0x67: rotate **+2**/frame |
| B | `.SetupXichraSprite` (`li r3,0x449` 1008dfc0, `li r7,0x191` 1008dfd4) | 0x449 (1097) | **401** | 779, 262 | x 832..876, y 318..353 | 28 (up-left) | p1 = 0 fixed, S 9000 | p1 = 0x68: rotate **−2**/frame |

**Before phase 3.** The Background Setup reads p1 from records 400/401, which are zero in the file
(§8.1) and are written by no code before `.UpdateXichraCannons` (the other stores to a record's
p1 field are type-gated and hit the touched or own sprite's record: `.HitPlayerSprite` doors
0xb5e/0xb5f and the 0x429 arm, handler l. 3942/4196/4202, and the Crawler, l. 9731; grep of
`* 0x10 + 8) =` over both dumps) [MED for completeness]
→ the `p1 < 1` arm: `+0x164 = 9000` (handler l. 14054–14055), aim = `(type − 0x442)·4`, fixed with
`pos = 0.8·pos + 0.2·home` easing after recoil. Launch from A: (vx, vy) = (+0.707·9000, −0.707·9000) =
(+6363, −6363), i.e. 24.9 px/frame right and up; from B the mirror (−6363, −6363). Captives
fired with vy < 0 keep the velocity (the 0.7/0.55 damping applies only to vy > 0).

**`.UpdateXichraCannons` @ 1008e24c** (called once, on the phase 2 → 3 change, 1008e858), raw
1008e260..1008e358:

| write | cannon A | cannon B | effect |
|---|---|---|---|
| sprite type `+4` | 0x443 (`li r0,0x443` 1008e264, `sth` 1008e26c) | **0x444** (`li r6,0x444` 1008e268, `sth` 1008e284) | **none**: aim is set only in Setup (handler l. 14003/14053); `.HandleBackgroundSprite` (`cmpwi 0x44c` 10073b84, l. 14677–14678) and `.HitBackgroundSprite` (l. 15317) test only the range 0x442..0x44b; `.HandleCannonedSprite` reads the cannon's `+0x46`, `+0x164`, `+0x80`, position and record p1, never its type (handler l. 4640–4888). B therefore keeps aim 28 and its up-left face. |
| record p1 | 0x67 (`li r31,0x67` 1008e270, `sth r31,0x8(r6)` 1008e2b0) | 0x68 (`li r8,0x68` 1008e294, `sth` 1008e310) | the Handle's rotating arm (`cmpwi r4,0x65` 10073c7c) |
| record p2 | 15 (`li r0,0xf` 1008e274, `sth r0,0xa(r6)` 1008e2cc) | 15 (1008e32c) | pause after each move, frames |
| `+0xa6` | 0 (1008e2d4) | 0 (1008e334) | pause counter: 0 → start moving this frame |
| `+0x158` | 8 (`li r10,0x8` 1008e280, `stw` 1008e2dc) | 8 | frames per move |
| `+0x160` | 8 (1008e2e4) | 8 | frames left in the current move |
| `+0x15c` | **+2** (`li r7,0x2` 1008e288, 1008e2ec) | **−2** (`li r5,-0x2` 1008e29c) | aim step per frame |
| `+0x164` | 9000 (`li r9,0x2328` 1008e28c, 1008e2f4) | 9000 | launch speed (unchanged) |

These are exactly the values the Background Setup would give a placed cannon with p1 = 103/104,
p2 = 15, p3 = 2 (`+0x158 = 16 / |step|` = 8, handler l. 14077–14100) — a 180° move per cycle.

**Rotation from phase 3** (Handle raw 10073c98..10073d0c, l. 14718–14733): while `+0xa6 == 0`:
`aim += +0x15c`, `+0x160 −= 1`, at < 1 → `+0x160 = +0x158`, `+0xa6 = p2` (15); while `+0xa6 ≠ 0`:
`+0xa6 −= 1`, and when it reaches 0 snd 485 'cannon shift' (vol 0x41) unless already playing.
Aim wraps into 0..31 (l. 14755–14760). One cycle = 8 moving frames + 15 still frames = 23 frames:

| cannon | rests at (aim, launch direction) | sweeps through while moving |
|---|---|---|
| A (+2) | 4 up-right (+0.707S, −0.707S) ↔ 20 down-left-shallow (−0.8S, +0.35S) | 8 right, 12 down-right, 16 down (4 → 20); 24 left, 28 up-left, 0 up (20 → 36 ≡ 4) |
| B (−2) | 28 up-left (−0.707S, −0.707S) ↔ 12 down-right-shallow (+0.8S, +0.35S) | 24 left, 20 down-left, 16 down (28 → 12); 8 right, 4 up-right, 0 up (12 → −4 ≡ 28) |

Because aim stays even and the fire test needs aim mod 4 = 0, a loaded captive leaves within one
frame of its 15-frame hold expiring, in whatever of the 8 directions the cannon points then [HIGH
arithmetic]. Recoil (`pos −= 1.6·v`) applies (p1 ≥ 0) and the cannon eases back to `+0x14c/+0x150`
(its spawn point) every frame of either arm (l. 14737–14753).

**Record write-back.** A and B do not set `+0x188/+0x189/+0x18a`, so `.UpdateSprites` copies their
type/x/y into records 400/401 every frame (main l. 4959–4966; guard `+0x48 ∈ [0, 0x1ff)`); the
records' flag byte stays 0, so nothing respawns from them [HIGH reading; no gameplay effect].

**Record 4 (R)** sits below the map's last row (608): its muzzle well is y 657..692. The player
starts at (467 − 32, 620 − 32) = (435, 588) (`.NewGame` passes `x − 32, y − 32`, world-data
§3.2), directly above R's well (x 439..483). That the level opens with the player dropping into R
and being fired straight up (vy −9000) into the lair is [LOW: geometry only; the player's hot rect
and the bottom-row tiles were not checked].

### 8.3 Cannon-launched Fire seeds  [HIGH for the code; LOW for intent]
`.HandleCannonedSprite` special-cases a captive whose type is **0x5a**: `cmpwi r0,0x5a` 10058da8 →
`li r0,0x15e; sth r0,0x110(r19)` 10058db0..10058db4 (gravity 350 after the launch). Type 0x5a is a
player shot of spell id 0x5a — the thrown fire / Ziridium seeds (`MTNewSprite(0x5a01, …)` in
`.HandleItemUse`, main l. 44265; spells-detail §3.8) and the Ring-of-Smiting bolt (`.SmiteEnemies`, main l. 47036);
no `Mlvl` record has type 90 (census of all 24 levels). Player shots are captured by any cannon whose
record p1 is not 0x69/0x6a (`.HitBackgroundSprite` l. 15326–15350), so all three lair cannons
capture seeds. Id 0x5a is the only shot that lowers Xichra's phase counter (bosses-2 §6.5), so the
lair's cannons can lob it — LOW that this is the intended way to reach a Xichra swaying 220 px either
side of x 325 at y ≈ 72.

### 8.4 The phase-0 minions (type 0x6d6, record 500, p3 = 4)  [HIGH]
At state-0 frame 80 `.HandleXichraSprite` writes **record 500 p3 = 4** (`sth r5,0x1f4c(r4)` 1008ec8c;
0x1f4c = 500·16 + 0xc) and spawns two 0x6d6 sprites with `MTNewSprite(0x6d6, cx − 298 / cx + 82,
camTop − 110, layer 0x14, record 500 (`li r7,0x1f4` 1008ec88/1008ecc0), setup = TOC slot 0x1009ff24)`.
Slot 0x1009ff24 is the proc `.GenerateSprite` uses for types 0x6d6..0x6e9 (`lwz r10,-0x791c(r2)`
1000348c; `cmpwi 0x6d6`/`0x6e0` 10003808..1000381c; `tocrefs.py 1009ff24`: only these two loads),
i.e. the Walker Setup, so the minions are ordinary **Ax goblins (1750)** (enemies-ground §3.1, §3.6)
with record 500's params p1 = p2 = p4 = 0, p3 = 4:

| field | value | source |
|---|---|---|
| HP | **2000** (1750 at tier 4) | enemies-ground §3.1 tier table |
| `+0x158` | 4 | same |
| draw remap `+0xb8` | 0x10013 (tier-4 palette) | same |
| `+0x100` | **1** — Setup itself (`li r0,0x1; stw r0,0x100(r24)` 100676b8..100676bc) | readers `lwz r0,0x100` 100678bc (`.AxGoblinCoreLogic`: never flees) and 1006a628 (`.HitWalkerSprite`: immune to fire/trap Background sprites) |
| knockback | yes (p2 = 0) | enemies-ground §3.7 |
| idle margins | none (p4 = 0) — they are spawned active | §3.1 |
| layer | 4 from Setup, 11 every frame from the Handle (the 0x14 argument is overwritten) | enemies-ground §3.1/§3.2 |
| score on death | +800 (1750) | enemies-ground §2.5 |
| coins on burn-away | tier-4 table: 0 nothing / 10 coins / 20 one small bag / 30 2–4 small bags / 40 big bag | enemies-ground §3.8 |
| enemy-total count | not counted: `_DAT_1009fe8c` is set only around `.SetupLevelSprites` | bosses §1.2 |

Xichra's own `+0x100 = 1` stores (`stw r20,0x100(r4)` 1008ecc4 and `stw r20,0x100(r3)` 1008ece8,
r20 = 1 from `li r20,0x1` 1008ec64) both hit the **first** minion and are redundant: Setup already
set 1 on both because p3 = 4. So the "second minion misses `+0x100`" slip of bosses-2 §6.3 has no
effect. Both minions spawn ~110 px above the camera top and drop in (gravity 0x151). Phase 1 ends
when both have `+0xe9` set, i.e. after each has died **and** finished burning away (or was killed
outright for being ≥ 451 px / 351 px from the player; enemies-ground §3.8).

### 8.5 The lair gates (2940, p1 = 0)  [HIGH reading]
`.HandleBoxSprite` (handler l. 13234–13283): for p1 ≥ 0 the gate is open iff `record[p1].p4 == 1`.
All seven lair gates have p1 = 0 → they test **record 0**, the floor fire 1208 at x 0, whose p4 is 0
in the file. The only code that stores a record's p4 field stores its **own** record's: `.HandleButtonSprite`
(main l. 61805/61808, `iVar4 = own +0x48`), `.HitBonusSprite` (l. 53487, containers 0x51b / 0xc1c..0xc25),
`.HandleBoxSprite` (l. 60866) and the sign arm of `.HitPlayerSprite` (l. 49287) (grep of
`* 0x10 + 0xe) =` and of direct `hdr + 0xe` stores over the main dump; the only direct one, l. 7730,
is a prefs handle). A Background 1208 runs none of these, so record 0's p4 stays 0 and **the seven
gates never open**: they hold at their base y and form the left and right walls of the lair
[HIGH for the reading; MED for completeness of the writer grep; "intended as walls" LOW]. For the
other p1 = 0 gates of triggers-background §1 (levels 18, 25, 62: record 0 is itself a 2940 gate;
level 45: a 1055) the same argument needs the Box own-p4 arm (main l. 60866) ruled out for those
types — not checked here.

---------------------------------------------------------------------------------------------

## 9. CLUT animation — `hdr+0x2730..0x2736` and `.AnimateCLUT @ 1001180c`

### 9.1 Fields and census  [HIGH]
Read only by `.AnimateCLUT` (`lha` at 10011850..10011860; the sole `0x2730(` load in the raw listing);
written only by `.HandleXichraSprite` (six `sth …,0x2730(r3)`: 1008e6d0, 1008e778, 1008e878,
1008e9a0, 1008ea48, 1008ebcc).

| off | name | meaning |
|---|---|---|
| 0x2730 | mode | 1..7 select a colour formula (§9.2); 0 or ≥ 8: no change |
| 0x2732 | count | number of palette entries animated: indices `255 − count .. 254`; 0 → routine returns at once |
| 0x2734 | period | frames per wave cycle (modes 4/5/6 scale it) |
| 0x2736 | amplitude | wave amplitude in 16-bit colour units (mode 6 scales it) |

| level | mode | count (entries) | period | amp | level+sprite CLUT (`0x285e`) |
|---|---|---|---|---|---|
| 50 | 1 | 48 (207..254) | 180 | 12000 | 220 'Upper Fire Caverns + base' |
| 51 | 1 | 48 (207..254) | 56 | 12000 | 220 |
| 67 | 3 (then 3..7 by Xichra phase) | 16 (239..254) | 75 | 12000 | 248 'Throne Room + base' |
| the other 21 | 0 | 0 | 0 | 0 | — |

### 9.2 Algorithm  [HIGH: raw 1001180c..10011cd4]
Called once at level start (`bl` 10009fb8 in `.GameLoop`) and every painted frame
(`bl` 10011ef4 in `.PaintFrameWrap`).
1. `count == 0` → return (10011858/10011864).
2. Effective period P and amplitude A: mode 4 → P = ⌊period·0.8⌋, mode 5 → ⌊period·0.6⌋, mode 6 →
   ⌊period·0.3⌋ and A = ⌊amp·1.28⌋ (`lfd -0x6220/-0x6228/-0x6230/-0x6238`, doubles 0x100a1620 = 0.8,
   0x100a1618 = 0.6, 0x100a1610 = 0.3, 0x100a1608 = 1.28; `fctiwz` truncation; 10011868..1001193c).
3. Timer `t = *_DAT_100a00e8` (only user: `tocrefs.py 100a00e8`): `t += 1`; `t ≥ P` → 0
   (10011940..1001195c). Never reset elsewhere, so the phase carries over between levels.
4. Effect-level gate (prefs `+6`; 1 Enhanced, 2 Normal, 3 Reduced; save-continue §8.2): 3 → skip;
   2 → skip unless the frame counter `*_DAT_1009fd98 & 3 == 0` (every 4th frame); 1 → skip unless
   `*_DAT_1009fd30 == 0` (alternate frames; `.PaintFrameWrap` toggles it) (10011968..100119a4). The
   timer of step 3 advances regardless.
5. For i = 255 − count .. 254 (`subfic r0,r16,0xff` 100119a8, `cmpwi r31,0xff` 10011c8c), only when
   1 ≤ mode ≤ 7 (100119e4..100119f4): θ = t·360/P (`mulli 0x168; divw` 10011a18..10011a20),
   normalised to 0..359; base (R, G, B) = entry i of `*_DAT_1009ff8c` (`lhz 0xa/0xc/0xe`
   10011a28..10011a38) — the level+sprite CLUT `GetCTable(hdr+0x285e)` stored by `.SetupLevel`
   (`lha 0x285e` 10004524, `stw r3,0(r20)` 10004538, r20 = slot 0x1009ff8c); wave
   `w = (A·S[θ]) >> 16` with `S[θ] = −(int)(sin θ° · 256 · 256)` built once by `.MakeRadialTables`
   (1003d67c..1003d6a8: `bl sin`, `fmul 256`, `fmul 256`, `fctiwz`, `neg`; 256.0 = 0x100a18f0), so **w ≈ −A·sin θ**
   (10011a6c..10011a80: `mullw`, `srawi 8; addze`, `srawi 8`).
6. New colour (r16 = R, r5 = G, r4 = B; 10011a84..10011bec):

| mode | R' | G' | B' |
|---|---|---|---|
| 1 | max(R + w, 0) | G | B |
| 2 | R + (A − w) | G + (A − w) | B + (A − w) |
| common to 3..7 | let D = R + w − A (≤ R) and E = B + D | | |
| 3 | ⌊0.7·D⌋ | G | ⌊0.7·E⌋ |
| 4 | ⌊2.1·⌊0.7·D⌋⌋ + 7000 | ⌊0.5·⌊0.7·E⌋⌋ | 0 |
| 5 | ⌊2.5·⌊0.7·D⌋⌋ | 0 | 0 |
| 6 | g − FastRand(4000), all three, with g = (⌊0.7·D⌋ + ⌊0.7·E⌋ + G) / 3 (truncating) | same | same |
| 7 | 0 | G | 0 |

   Constants: 0.7 = 0x100a1600 (`lfd -0x6240`), 2.1 = 0x100a15f8, 0.5 = 0x100a15f0, 2.5 = 0x100a15e8;
   `addi r16,r16,0x1b58` 10011b64 (+7000); mode 6 `mulhw` by 0x55555556 (÷3) and `li r3,0xfa0; bl
   FastRand` 10011bc0..10011bc4. ⌊⌋ = `fctiwz` (toward zero). Each channel is clamped to 0..0xffff
   (10011bf0..10011c50) and stored into the working palette `*_DAT_1009fe94` (a `HandToHand` copy of
   the same CLUT, 10004578..1000459c).
7. `SetEntries(0, 255, palette)` (10011c94..10011ca8): the 8-bit screen palette is replaced, so every
   pixel on screen with one of those indices changes colour at once — tiles, parallax and sprites alike.

### 9.3 Level 67 on screen  [HIGH for the data; MED where noted]
Entries 239..254 of CLUT 248 (and of the level CLUT 247, identical there) are a **magenta ramp**
(R = B, G = 0): 239 (0xffff, 0, 0xffff), 240 0xdeb0/0xdeb7, 241 0xc6c6 … 253 0x2929, 254 black.
CLUT 200 ('base sprite clut') is black at 160..255, so converted sprites carry none of these
colours. Pixel census (Python decode of the PICTs' own colour tables; a pixel counts when its RGB
equals one of entries 239..253):

| art | role in level 67 | ramp pixels |
|---|---|---|
| PICT 387 (768×768) | PxBack tileset (`hdr+0x284c` = 387), the lair's back parallax | **87,020 (14.75 %)**, entries 241..253 |
| PICT 385 (768×60) | horizon strip (`hdr+0x2716`) | 60 (entry 251) |
| PICT 380 (256×384) | FG and BG tileset (`0x2850 = 0x2852 = 380`) | 0 |
| PICTs 1970–1977, 1980–1987, 1990 | Xichra body and wing | 0 |

The PxBack set is converted with the level CLUT 247 (`.LoadLevelTilesets` sets the conversion
CLUT to `PTR_DAT_1009ff4c` = `GetCTable(hdr+0x285c)`, main l. 1576–1584, because `hdr+0x26cc = 0`),
whose 239..253 hold the same magentas, so the ramp pixels keep indices 241..253 [MED: assumes the
Color Manager maps an exact colour to its own entry]. **So the animation recolours ~15 % of the
throne-room backdrop and nothing else** (black at 254 stays black except in mode 4, below).

Per Xichra phase (bosses-2 §6.3; phase 1 writes nothing, so mode 3 stays), with base A = 12000,
period 75 (simulated from the formula of §9.2; two extremes θ = 90°/270°):

| phase | mode | P (frames) | A | entry 239 (brightest) | entry 252 (dark) | look |
|---|---|---|---|---|---|---|
| 0, 1, 2 | 3 | 75 | 12000 | R 0x7192..0xb332, G 0, B 0xffff | R 0..0x226f, B 0x033e..0x44de | blue-violet backdrop, red component pulsing |
| 3 | 4 | 60 | 12000 | R 0xffff, G 0x9262..0xb332, B 0 | R 0..0x63a7, G 0x019f..0x226f | orange-yellow pulse; black entry 254 flickers to R 0x1b58 |
| 4 | 5 | 45 | 12000 | R 0xffff | R 0..0x5615 | pure red pulse, faster |
| 5 | 6 | 22 | 15360 | grey 0x7b32..0xb332 minus FastRand(4000) | grey 0..0x226f | grey, flickering (random every update) |
| 6 | 7 | 75 | 12000 | black | black | ramp goes black (G of the ramp is 0) |

Visible update rate: every frame's wave is computed, but the palette is pushed only on alternate
frames (Enhanced), every 4th (Normal) or never (Reduced) — §9.2 step 4.

### 9.4 Levels 50 and 51  [HIGH arithmetic]
Mode 1 on entries 207..254 of CLUT 220 (the fire-cavern reds/oranges): red channel `R − 12000·sin θ`,
floored at 0, G and B unchanged — a red-intensity pulse with period 180 frames (L50) / 56 frames (L51).
Which art uses those entries in L50/L51 was not counted (outside this lane).

---------------------------------------------------------------------------------------------

## 10. Vestigial fields and the type-write idiom

### 10.1 The Dillo template: Warrior/Wizard p2 = 150, `+0x14c..+0x168`, Warrior `+0x154`  [HIGH code; LOW origin]
The Setups of the Dillo, Warrior and Wizard open with the same sequence: `+0x14c = 0`, `+0xa6 =
FastRand(10)`, then **if record p2 == 0 write 150** (`lhau r0,0xa(r3)`; `li r0,0x96`; `sth`): Dillo
1008636c..1008637c, Warrior 10087a00..10087a0c, Wizard 1008c808..1008c818 (handler l. 19561–19563,
20090–20093, 22036–22039).
- The **Dillo** then uses p2: patrol bounds `+0x15c/+0x160 = x ∓ p2/2` (`lha r5,0xa(r5); srawi 1`
  100863a0..100863a8).
- The **Warrior** uses fixed bounds x ∓ 350, the **Wizard** x ∓ 256. Nothing reads the boss records'
  p2: the 110 `* 0x10 + 10)` reads in both dumps are in `.SetupProgrammedPath`, `.DoSetupPlatformSprite`,
  Crawler/Floater/Dillo/Box/Background Setups, `.HandleBoxSprite`, `.HandleBackgroundSprite`,
  `.HitWalkerSprite` (own record), `.HitPlayerSprite` (types 0x537, the passage arm and the 3249 exit;
  handler l. 3770/4323/4446) and `.UpdateXichraCannons` — all gated to other classes or types. The
  write is therefore inert, apart from being saved with the record block [HIGH for the reader list
  as a decompile grep; MED for completeness].
- Wizard: its own `+0x14c`, `+0x150`, `+0x15c`, `+0x160`, `+0x164`, `+0x168` are stored only in Setup
  (1008c798..1008c844) and never loaded by its Handle/Hit/Kill (raw scan 1008c5c8..1008d918; the
  `+0x160` accesses at 1008d06c/1008d520 are on the crate / the falling solid) [HIGH].
- Warrior: `+0x150` (−1) and `+0x164` (0) are never loaded (raw scan 100877d0..100888a0) [HIGH];
  **`+0x154`** is stored by `.WarriorLayEgg` (`stw r0,0x154(r3)` 10087b14, value 2) and
  `.RandomWarriorAttack` (10087bac, value 0) and never loaded. `.WarriorLayEgg` is instruction-for-
  instruction `.DilloLayEgg @ 1008678c` (`+0x154 = 2`, `+0xa6 = 5`, `+0x14c = FastRand(2) + 1`), and
  `.HandleDilloSprite` does read it (`lwz r0,0x154(r28); cmpwi r0,0x2` 10086dc0..10086dc4 → the egg
  drop, enemies-ground §6). The Warrior's Handle has no such test, so its "egg" roll only selects a
  walk/run cycle (bosses §2.2). Generic `+0x154` readers (`.HandlePxSprite`, enemy-shot, platform,
  rope, Box/Background handlers; the `.PaintFrameWrap` hit is a stack slot `0x154(r1)`) never run
  for a Warrior [HIGH].

### 10.2 Wizard state 11, `w[1]`, `w[4]`  [HIGH]
The Wizard's state switch has 13 arms (`cmplwi r0,0xc` 1008c940, `bctr` 1008c958), so state 11 has
code. Its writers of `+0xb0`: Setup 6 (1008c7c8); Handle 9 (1008c9d0), 2 (1008cad4), 6 (1008cca8,
1008cd50), `w[2]` (`lha r0,0x4(r26); sth r0,0xb0(r24)` 1008d0fc..1008d100), 10 (1008d12c), 4
(1008d348). `w[2]` (work block `+4`) has one store, `li r0,0xc; sth r0,0x4(r26)` 1008cabc..1008cac0,
made just before the state-2 store that alone leads to the `w[2]` copy. The work block is held only in
r26 (`lwz r26,0x9c(r3)` 1008c914; never copied or passed) and `+0x9c` is loaded nowhere else in the
Wizard code. Engine-wide, the stores of the constant 11 to a `+0xb0` are at 10072120 (Background
Setup), 1008263c/1008268c (`.HandleFrogSprite`) and 1008336c (`.HandleSalamanderSprite`) — each to its
own sprite; the other non-class `+0xb0` writers (`.InitSprite` 0, `.UpdateRadiusSprites` radial
children, `.HurtPlayer`, player-shot code, `.KillCrate`/`.HandleBoxSprite` new sprites) never take a
Wizard. **State 11 is unreachable.** Work block: `w[1]` (`+2`) has no access at all; `w[4]` (`+8`)
has exactly one load and one store, the increment itself (`lha r3,0x8(r26)` 1008cbf8, `sth r0,0x8(r26)`
1008cc00) — write-only.

### 10.3 Goblin Chief `+0xb2`  [HIGH code; LOW purpose]
Writers: Setup 0 (1008b664), Hit 1 (1008c178), Handle reset 0 (1008c014) and `+1` (1008c024).
Readers: only the Handle block 1008bfd4..1008c024: if `b2 > 0`, compute `(b2 − 1) >> 1` and run a
compare chain against 1, 0, 3 whose every branch lands on 1008c008 (`beq/bge/b 0x1008c008`) — an
**empty switch** the compiler kept — then `b2 ≥ 5 → 0`, else `b2 += 1`. No other function reads a
Chief's `+0xb2` (engine-wide `0xb2(` loads: class handlers of other classes, and three stack slots
`0xb2(r1)` in `.WrapLightFace`/blitters). So `+0xb2` is a 5-frame after-hit counter whose consumer
was removed — plausibly per-2-frame hurt faces [LOW].

### 10.4 The `type = type + 1; type = type − 1` idiom (Demon, HandleBurn, UpdateSprites)  [HIGH]
Three sites, same compiled shape `lha r3,4(rS); cmpwi r3,K; bne; addi r0,r3,1; sth r0,4(rS);
lha r3,4(rS); subi r0,r3,1; sth r0,4(rS)`:

| site | K | raw |
|---|---|---|
| `.HandleDemonSprite` | 0x780 | 1008a6e0..1008a6fc |
| `.HandleBurn` (just before calling the Kill proc) | 0x780 | 10043e90..10043eac |
| `.UpdateSprites` (every sprite, every frame) | 0x6ea | 10009860..1000987c |

Between the two stores there is no call and no branch, so no code can observe the transient
K + 1; the type ends where it started. The game's only asynchronous code is the sound layer
(`.STLoopCallBack` re-queues a sound, main l. 40968), which reads no sprite. Readers of the
Demon's (unchanged) type: `.HandleDemonSegs` gating and the Handle/Kill tests (`cmpwi 0x780` at
1008a24c, 1008a304, 1008af9c, 1008afb8, 1008b34c) and `.GenerateSprite`'s range test (100039fc).
**No-op as compiled**; a replica omits it. Why it exists is not recoverable from the binary
(CLOSED AS UNDETERMINABLE for intent).

---------------------------------------------------------------------------------------------

## 11. Level 55 never locks its arena  [HIGH]
`.PlayerConstraints @ 1004cb4c` (called from `.HandlePlayerSprite`, `bl` 100513b0) first clamps the
player's x to `[−64, mapWidth·32 − 32]` (`cmpwi r10,-0x40` 1004cb54; `lha r0,-0x4d80(r8)` after
`addis r8,r8,0x1` = `hdr+0xb280`, `rlwinm …,5`, `subi r0,r8,0x20`, `cmpw`, clamp 1004cb84..1004cbb4)
and only then runs the arena test (`hdr+0x2724`, l. 44035ff). Level 55 is 64 tiles wide → x ≤ 2016,
while its lock line is `|16000 − 60|` = 15940. The lock can never fire; the unlocked camera bound
`hi = 16000` also lies beyond the 2048-px map, and `hdr+0x272e = −448` is applied only when locked.
Level 55 geometry for reference: guardians at x 1095 (placed, rec 7) and 455 (partner), gate 2940
p1 = −1 at x 1174 (rec 4), exits 3249 at x −94 (rec 3) and 2036 (rec 12), player start x 786.
So the Fire Guardians fight is open-field; `hdr+0x2724 ≠ 0` matters only for the post-kill music
(bosses §1.4 step 3).

## 12. Small closures

### 12.1 Sound rate units (`.STPlay3DSoundPitched`)  [HIGH]
The rate argument is a 16.16 Fixed multiplier, 0x10000 = the sample's own pitch: `.STPlay3DSound`
stores `lis r0,0x1` (10047af0) into the same request slot `0x44(r1)` (10047afc) that the pitched
variant fills from its 5th argument (`stw r7,0x44(r1)` 10047bc4). The mixer `FUN_10091208` computes
the channel step `FixMul(FixDiv(sampleRate>>8, outputRate>>8), rate)` (`bl FixDiv` 1009138c,
`lwz r4,0x8(r22); bl FixMul` 1009139c..100913a4, again 10091420..10091424). So rate 78000 plays 1.19×
higher and shorter, 36000 at 0.55×; `.STPlay3DSoundRand` uses 60535 + FastRand(10000) = 0.92..1.08×.

### 12.2 Boss projectiles against tiles  [HIGH]
- 0x46a (fireball) and 0x71f (Warrior blade): `.HitEnemyShotTileSprite`, enemy-shots §1.2/§1.3:
  0x46a dies on its first FG hit and ignores BG/water (types 0x46a..0x46f skip the BG arm); 0x71f
  dies on its first counted wall hit (FG or BG kind < 100; `+0x150` starts 0).
- 0x77b (Chief boulder) has tile callback 0, and `.SeparateFromTiles2 @ 1003c804` returns at once
  for such a sprite (`lwz r0,0x1f8(r27); cmplwi; beq 0x1003cec8` 1003c86c..1003c874 → epilogue
  1003cec8), the only tile pass `.ApplyGravityAndSeparateFromTiles` runs (main l. 32941–32965). **The
  boulder passes through terrain**; it is removed only below `mapRows·32 + 32` (enemy-shots §1.2).

---------------------------------------------------------------------------------------------

## NOT RESOLVED
1. `+0xb8` draw modes 1, 0xb, 0xc and the flash buffer `*_DAT_100a0008` (bosses-2 NR 1) — not
   attempted here; it is INDEX item 15 (draw effects), whose lane owns the blitter
   (`.WrapDrawSprites` passes `+0xb8`, overridden by the hurt flash `0x30000+min(n,7)` /
   `0x40000+2n`, to `.WrapDrawFace` → `_BlitEncFaceX`, main l. 10308–10364).
2. Whether the player's hot rect actually falls into cannon R's well at level start (§8.2) — tried:
   geometry from the records and the start point only; the player's rect and the bottom-row tiles
   were not decoded.
3. Which art in levels 50/51 uses palette entries 207..254 (§9.4) — not counted.
4. Purpose of the type-write idiom (§10.4) and of the Chief's emptied `+0xb2` switch (§10.3) —
   undeterminable from code (author intent).

## Proposed additions to physics.md §0
None new. The cannon fields used in §8.2 (`+0x158` frames per move, `+0x15c` aim step, `+0x160`
frames left, `+0x164` launch speed, `+0xa6` pause) are already in triggers-background-2 §0.

## Corrections to the existing bank
In the wave-2 table at the end of `bosses-2.md` (Corrections to the existing bank, rows W1..W5):
world-data-format §3.2 (0x2730..0x2736), sprites-backgrounds-sounds §4 (`.AnimateCLUT`),
triggers-background §2.2 / -2 NR 2 (type 90), triggers-background §1 (level-67 gates), coverage §2.
