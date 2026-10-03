# Ferazel's Wand 1.0.3 — particle system (pool, `.NewParticle`, colour rows, emitters)

Code readings only; nothing behaviour-verified. Date 2026-10-04.
Sources: `ghidra/Ferazel_pef.decompiled.c` ("main l. N"), `ghidra/Ferazel_handlers.decompiled.c` ("handler l. N"), raw listing `ghidra/Ferazel_pef.disasm.txt` (addresses), `tools/const.py`/`tocrefs.py`, and Python decodes of `clut` 801/202/214/220 (+ the other 15 "+ base" CLUTs) from `Ferazel's Wand Backgrounds.rsrc` and of `Mlvl` +0x285c/+0x285e/+0x2706 from `Ferazel's Wand World Data.rsrc`.

Units: positions are stored as px·256; velocities and gravity are 1/256 px per frame (per frame²).
Points are packed `(v << 16) | h` (QuickDraw order: v = y, h = x). R(n) = `.FastRand(n)` = 0..n−1
(R(1) = 0 but still advances the seed, main l. 31282–31313).

## 1. Pool and record

### 1.1 Globals  [HIGH]
All five are static arrays/shorts in the zero-initialised data section (TOC words read with
`const.py`; pool and colour table sizes are the gaps between the targets). Only the five particle
routines load these TOC slots (`tocrefs.py`: 100a019c also `.HitPlayerSprite` 10055a1c/10055a5c).

| TOC slot | target | meaning | evidence |
|---|---|---|---|
| `100a01ac` | `0x1024b564`, 2000 × 0x20 = 64000 B | the pool | `cmpwi 0x7d0` at 10031eb0, 10030674; record stride `rlwinm …,0x5` 10031e90, `addi 0x20` 10031a58 |
| `100a01a8` | `0x1025af64`, 256 × 120 B = 0x7800 | colour rows: `row[kind][age]` | `mulli r3,r3,0x78` 10031b7c; filled by `.InitParticleColors` |
| `100a019c` | i16 | live count | `+1` 10031f20–10031f28; `−1` 10031a28–10031a34, 10031ba4–10031bac **and again** 10031bc0–10031bcc |
| `100a01a0` | i16 | first-free hint (search start) | NewParticle 10031e84 / 10031f1c; lowered on every kill (10031a18–10031a24, 10031bb0–10031bbc) |
| `100a01a4` | i16 | high-water index (loops run 0..hwm) | NewParticle raises it 10031f2c–10031f38; a kill at index == hwm lowers it by one (10031a38–10031a48) |

`.InitParticles @ 1003062c` (called from `.SetupLevel`, `bl` at 10004fc0, after `SetScreenClut`)
clears only byte +0 of all 2000 records (10030648–10030678) and then calls `.InitParticleColors`
(1003067c). It does **not** reset the count, hint or high-water mark [HIGH: no other store to the
three shorts exists — the TOC slots are loaded only by the routines listed above].

### 1.2 Record (32 bytes)  [HIGH]

| off | type | meaning | written by (raw) |
|---|---|---|---|
| +0x00 | u8 | alive | NewParticle `stbx r12(=1)` 10031ed0; cleared 10031a10, 10031b9c |
| +0x02 | i16 | age; starts at −arg7 (delay), +1 every frame | `neg r9; sth r9,0x2` 10031ed4/10031edc; `addi 1` 10031a4c–10031a54 |
| +0x04 | i16 | shape code (arg 4) — §3.2 | `sth r6,0x4` 10031ee8 |
| +0x06 | i16 | colour kind (arg 1) — §4 | `sth r3,0x6` 10031ef4 |
| +0x08 | i16 | gravity (arg 2), added to vy each frame | `sth r4,0x8` 10031ef8 |
| +0x0c | i32 | vx (arg 5, sign-extended from 16 bits) | `extsh r9,r7; stw r9,0xc` 10031ee4/10031f0c |
| +0x10 | i32 | vy (arg 6, from 16 bits) | `extsh r7,r8; stw r7,0x10` 10031eec/10031f10 |
| +0x14 | i32 | x·256 (h of arg 3) | `lha r27,0x22(r1)` 10031e80, `rlwinm …,8` 10031ee0, `stw 0x14` 10031efc |
| +0x18 | i32 | y·256 (v of arg 3) | `lha r3,0x20(r1)` 10031f00, `stw 0x18` 10031f08 |
| +0x1c | u8 | blend mode — always 0 | `stb r6(=0),0x1c` 10031f14 — the only store in the binary that reaches the pool (the other `stb …,0x1c` at 1004d3ac is a sprite) |
| +0x1d | u8 | erase mode returned by the last draw (0 none, 1, 2) | 10031c0c, 10031c98, 10031cc0, 10031ce8, 10031d18 |
| +0x1e | u8 | collision mode (arg 8) — §2.2 | `stb r10,0x1e` 10031f18 |

### 1.3 Allocation  [HIGH]
`.NewParticle` scans indices from `*hint` to 1999 for the first record with byte +0 == 0
(10031e84–10031eb4); none → returns −1 and nothing is created (callers ignore the result). Found
slot i: fill the record (§1.2), `hint = i` (the slot just taken), `count += 1`, `hwm = max(hwm, i)`,
return i. Because Init does not reset `hint`, slots below a stale hint stay unused until a kill
lowers it.

### 1.4 Count drift (a replica must copy it)  [HIGH arithmetic; MED consequence]
A particle killed by `.DrawParticles` for a zero colour (§3.1) decrements the count **twice**
(10031ba8 and 10031bc8, both `sth` to `0(r27)` = 100a019c); `.HandleParticles` kills decrement once.
Every kind whose colour row reaches 0 before age 120 (most kinds, §4.3) dies that way, and Init never
resets the count, so the i16 drifts downward through the session (it wraps to +32767 after −32768).
Its only other reader is the Xichron-pickup burst choice in `.HitPlayerSprite` (main l. 48653–48661:
`prefs+6 == 1 && count < 1000` → (1,1,1), `== 2 && count < 1500` → (2,1,7), else (2,2,7)): while the
count is negative the first two gates always pass; after a wrap they fail until it drifts back.
(save-continue.md §8.2 reads it as "count = live particles" [MED] — see Corrections #6.)

## 2. `.NewParticle @ 10031e68` — the arguments  [HIGH]

`NewParticle(kind, gravity, pos, shape, vx, vy, delay, mode)` = r3..r10.

| # | reg | name | meaning |
|---|---|---|---|
| 1 | r3 | kind | colour source (§4): 1..255 → colour row `row[kind][age]`; ≥ 256 → fixed palette index `kind − 256`; negative → \|kind\| as above **and** the colour is passed through the ambient light table (§3.1) |
| 2 | r4 | gravity | added to vy every frame after the move (1/256 px/frame²); may be negative (buoyant bubbles) |
| 3 | r5 | pos | packed Point (v, h) in level pixels |
| 4 | r6 | shape | pixel footprint code 0..7 (§3.2); **4 = 1 px wide × 2 px tall** |
| 5 | r7 | vx | 1/256 px/frame, 16-bit |
| 6 | r8 | vy | 1/256 px/frame, 16-bit, + = down |
| 7 | r9 | delay | start age = −delay. Positive → the particle waits `delay` frames frozen and invisible. **Negative → pre-aged**: it starts at age −delay, so it lives only 120 + delay frames and enters its colour row part-way (used by `.ExplodeFaceIntoParticles`, `.BurnFaceRow`, Gremlin saddle blood) |
| 8 | r10 | mode | collision rule (§2.2) |

### 2.1 Motion (`.HandleParticles @ 10031828`, last in the sprite phase)  [HIGH]
For every alive record 0..hwm: if age ≥ 0: `x += vx; y += vy; vy += gravity` (10031878–100318a4),
then the mode test (§2.2) at the new position, then `age > 120 → die` (100319f4–10031a00). Then
(alive or just killed, any age) `age += 1` (10031a4c). Delayed particles (age < 0) neither move nor
die. A particle created during the sprite phase therefore moves once before it is first drawn.

### 2.2 Collision modes (tile = `.GetFGTile(x >> 5, y >> 5)`, FG tile 0..95 or −1)  [HIGH]

| mode | dies when | raw |
|---|---|---|
| 0 (and any other value) | only by age / colour | — |
| 1 | FG tile **> 0x50**; or FG ≤ 0x50, the BG cell is water (`.IsWaterTile`) and **vy > 0x2ee** (falling into liquid at ≥ 751) | 10031978–100319f0 |
| 2 | FG tile **≥ 0x50** and age > 1 | 100318a8–100318ec |
| 3 | always, unless FG < 0x50 and the BG cell is water (bubbles: die on leaving liquid or touching FG ≥ 0x50) | 100318f4–10031970 (`cmpwi −2; ble` is never taken for age ≥ 0) |

FG tile numbering (bits 0–7 − 1) is world-data-format.md §3.3 (tiles 80..95 = the last two rows of the
FG sheet) [MED for what those rows are].

## 3. Drawing

### 3.1 `.DrawParticles @ 10031aa4`  [HIGH]
Frame order (`.PaintFrameWrap`): … `.WrapDrawSprites`, rain (`.GenerateRain` 10011ef0, only when
hdr+0x26c7 == 1, 10011ee4), `.AnimateCLUT`, flame layer, **`.DrawParticles` (10012700)**,
`.UpdateOmniPx`, `.WrapCopyToScreen`, **`.EraseParticles` (100127c0)**, then the sprite phase
(`.HandleIdleSprites`, `.HandleSprites`), **`.HandleParticles` (100127dc)**, `.WrapEraseSprites`
(main l. 9433–9455). Particles are therefore drawn over every sprite, tile and the flame layer of the
frame, into the back buffer only, and erased again after the copy to screen.

Per alive record with **age > 0** (10031b00–10031b08; age 0 is never drawn):
1. `k = |kind|` (10031b5c). `lit = kind < 0 && prefs+6 ≠ 3` (10031b3c–10031b4c; prefs+6 = the
   Enhanced/Normal/Reduced detail popup, save-continue.md).
2. Colour `c`: age ≥ 120 → 0; else k < 256 → `row[k][age]` (10031b74–10031b84); else `k − 256`
   (10031b8c). Only the low byte is used.
3. `c == 0` → kill (count −2, §1.4; hint/hwm as in §1.1) and draw nothing (10031b98–10031be4).
   **A colour row's first 0 is therefore the particle's lifetime.**
4. lit → `c' = lightTable[hdr+0x2706][c]` (`lbzx r3,r19,…` 10031cf0–10031d0c; r19 = TOC 100a0130,
   built by `.CalcLightingTable`, hdr+0x2706 = per-level ambient value: 5 in levels 1/4, 2 in 21/22,
   1 in 2/3/10/31, 0 elsewhere — Mlvl decode) [HIGH for the index; table contents not decoded here].
5. `+0x1c` blend 1/2/3 → translucency tables 100a0158/100a015c/100a0154 indexed `c·256 + screen
   pixel` (10031c14–10031ce8). **Dead**: +0x1c is always 0 (§1.2).
6. `+0x1d = .WrapDrawParticle(c, shape, (v, h))` (10031bfc–10031c0c).

### 3.2 `.WrapDrawParticle @ 10015948` — shapes and clipping  [HIGH]
View origin `(V, H)` = `PTR_DAT_1009fe78`. Rejected unless `h + 2 ≥ H`, `v + 2 ≥ V`, `h ≤ H + 0x260`,
`v ≤ V + 0x180` (1001596c–100159b4); then `h < H → h = H`, `v < V → v = V` (a particle up to 2 px
left/above the view is drawn on the edge, 100159b8–100159d0); then wrapped into the 640×416 scroll
buffer (`h mod 0x280`, `v mod 0x1a0`, 100159d4–10015a1c) and rejected if outside `0..0x27e × 0..0x19e`
(shapes 3/5/6: `0..0x27c × 0..0x19c`) — no wrap-around split (10015a20–10015a8c). Jump table at
r2 − 0x3f6c = 100a38d4 (words 0x15f88, 0x15ce8, 0x15acc, 0x15e48, 0x15b60, 0x15be4, 0x15db8,
0x15d2c → code 10015f88 …):

| shape | footprint (columns × rows; `#` drawn) | case address |
|---|---|---|
| 0, > 7 | nothing (returns 0) | 10015f88 / 10015ab4 |
| 1 | 1 × 1 | 10015ce8 |
| 2 | 2 × 2 | 10015acc |
| 3 | 4 × 4 rounded: `.##.` / `####` / `####` / `.##.` (12 px) | 10015e48 |
| 4 | 1 × 2 (vertical pair) | 10015b60 |
| 5 | 2 × 4 | 10015be4 |
| 6 | 4 × 1 | 10015db8 |
| 7 | 2 × 1 | 10015d2c |

All pixels get the same index `c`. Mask rule, second buffer `_DAT_100a0008` (engine.md §2): if every
covered mask byte is 0xff → draw, set them to 0, return 1; if every covered byte is 0 → draw, return 2;
mixed → not drawn, return 0 (e.g. 10015b60–10015bdc). Shape 1 tests one byte and returns 2 for any
value ≠ 0xff, so it is never suppressed (10015ce8–10015d28).

### 3.3 `.EraseParticles @ 10031d6c`  [HIGH]
For alive records with age > 0: `+0x1d == 1` → `FUN_10015fb8(shape, pos)`: same clip/clamp/wrap,
copies the footprint's pixels from the third buffer `_DAT_100a0004` into the draw buffer
`_DAT_100a000c` and sets the mask bytes back to 0xff (case 1: main l. 11168–11174); `+0x1d == 2` →
`FUN_10016440`: same copy, mask untouched. Shape 3 restores the full 4×4 square in mode 2
(`FUN_10016440` case 3, main l. 11326ff.). [MED: what buffers 0004/0008 hold between frames is
engine-side — the routines only show "restore from 0004, mask 0xff = restorable".]

## 4. Colour rows (`.InitParticleColors @ 100306b4`)

### 4.1 Sources  [HIGH]
- Every row is first zeroed (256 × 120, 100306f0–10030780). Unbuilt kinds (0, 14..198, 204, 206..209,
  212, 214, 216..219, 224..255) stay all-0 → **such a particle dies at its first draw** (e.g. bubbles
  or splashes of a liquid BG kind 204 or 206..209 are invisible). Built but never emitted: 8, 211.
- RGB sources: `ColorSpec` entries of CLUT handle `_DAT_100a0038` = **`clut` 801 "System CLUT"**
  (`GetCTable(0x321)` 10000b68, stored via r21 = TOC 100a0038 at 10000b74; byte-identical copies in the
  app and Backgrounds files; it is the standard Mac 8-bit system palette: entry 0 white, 0..214 the
  6×6×6 cube, 0xd7..0xdf red ramp, 0xf6..0xfd greys, 0xff black). Address `*h + 8·e + 10` = rgb of
  entry e.
- Each RGB goes through `Color2Index` (`bl 0x1009f1ac`) against the **current screen CLUT**, which at
  that moment is the level's "+ base" CLUT (`Mlvl` +0x285e, default 202; `.SetupLevel` main
  l. 2568–2572: `SetScreenClut(*_DAT_1009ff8c)` then `.InitParticles`). The rows are rebuilt each level.
- Some rows store palette indices directly (no Color2Index).
- Entries 0..159 and 255 are identical in all 16 "+ base" CLUTs used by the 24 levels (Python decode);
  160..254 are the level's own colours. A row whose indices are < 160 looks the same everywhere.
- Entry 0 of every level CLUT is white, so a row step that asks Color2Index for clut-801 entry 0
  (white) yields index 0 = end of life (rows 1, 2, 4, 13) [HIGH for the data; MED that Color2Index
  returns 0 for exact white — it is the exact match].

Notation below: `t` = age (0..119), `s = t >> 1`; "e" = clut-801 entry; RGB 16-bit.

### 4.2 Recipes  [HIGH: raw ranges cited]

| kind | row store | recipe | raw |
|---|---|---|---|
| 1 | `stb …,0x78` | e by s: 0–1 → 3 (FFFF/FFFF/6666), 2–3 → 5 (yellow), 4 → 0xb, 5 → 0x11, 6 → 0x17, 7 → 0x1d (orange→red), 8..11 → `0xd7 + 2(s−7)` (0xd9, 0xdb, 0xdd, 0xdf dark reds), s ≥ 12 → e 0 (white → index 0) | 10030790–10030858 |
| 2 | `0xf0` | t ≤ 20 → e 0xd7 (EEEE/0/0); t > 20 → `0xd7 + ((t−20)>>1)`, > 0xdf → e 0 | 1003087c–100308e0 |
| 3 | `0x168` | e by **t**: <4 → 0x78, <8 → 0x7e, <12 → 0xa8, else 0xeb; then **r = g>>1, g = g>>2**, b kept (violet-blue) | 10030904–100309e0 (`srawi 1` 100309c4, `sraw 2` 100309d0) |
| 4 | `0x1e0` | e = 0xf6 + s (greys light→dark), > 0xfd → e 0 | 10030a04–10030a54 |
| 5 | `0x258` | constant (0, 37000, 58000) | 10030a6c–10030aa0 |
| 6 | `0x2d0` | constant (0, 0x70e4, 0xcabc) | 10030ab8–10030aec |
| 7 | `0x348` | constant (0, 10000, 0x83a4) | 10030b04–10030b38 |
| 8 | `0x3c0` | constant (0, 7000, 22000) — no emitter uses kind 8 | 10030b50–10030b80 |
| 9 | `0x438` | `u = (int)(1.5·t)` (const 100a17b8 = 1.5); u ≤ 18: r = (20−u)·0xc80, g = (int)(0.75·r) (100a17b0), b = 0; else index 0 | 10030b98–10030c50 |
| 10 | `0x4b0` | **index** `0x9f − t` (t ≤ 8), `0x9f − (16 − t)` (t ≤ 16), else 0 (grey ramp out and back) | 10030cc0–10030cf8 |
| 11 | `0x528` | **index** `0x89 + t/3` while t/3 ≤ 4, else 0 (magenta ramp) | 10030c68–10030ca8 |
| 12 | `0x5a0` | t ≤ 18: (0, (20−t)·0x1900, 0); else 0 (green fade) | 10030d10–10030d5c |
| 13 | `0x618` | kind 1's entry sequence with **red and blue swapped** when e ≠ 0 (blue/cyan flame) | 10030d74–10030e60 (swap 10030e44–10030e50) |
| 199 | `0x5d48` | s ≤ 20: b = (20−s)·950 + 46000, r = g = (4−s)·9600 for s ≤ 4 else 0; s > 20: (0, 0, 46000) | 10030e78–10030eec |
| 200 | `0x5dc0` | e by **s**: <4 → 0x78, <8 → 0x7e, <12 → 0xa8, else 0xeb; b += 10000 if b < 55000. (A first write by **t** at 10030994 is overwritten by this second loop, 10030f04–10030fa8.) | 10030f04–10030fa8 |
| 201 | `0x5e38` | **index** `0x71 + min(t/5, 3)` | 10030fc0–10030ffc |
| 202 | `0x5eb0` | r = s ≤ 10 ? (10−s)·0xaf0 + 32000 : 32000; **g = (int)(0.4·r)** (100a17a8); b = 0 | 10031014–10031098 |
| 203 | `0x5f28` | r = as 202, g = 0, b = r (magenta) | 100310b0–10031108 |
| 205 | `0x6018` | s < 10: f = (10−s)/10 (f32), f < 0.68 → 0.68; RGB = (48384f, 39936f, 16896f); s ≥ 10 → the s = 9 value (f = 0.68) | 10031120–100311e4 (consts 100a1788/1780/1778, 100a1798, lfs 100a1790) |
| 210 | `0x6270` | t ≤ 10: b = 32000 + 0xc80·t, r = g = t > 2 ? (t−2)·0x1194 : 0; 11..20: b = (20−t)·0xc80 + 32000, r = g = t < 18 ? (18−t)·0x1194 : 0; else 0 (blue flash) | 100311fc–1003129c |
| 211 | `0x62e8` | t ≤ 10: (0, 32000 + 0xc80·t, 0); 11..20: (0, (20−t)·0xc80 + 32000, 0); else 0 (green flash; no emitter) | 100312b4–10031324 |
| 213 | `0x63d8` | **index** by s mod 8: 0x89, 8a, 8b, 8c, 8d, 8c, 8b, 8a (jump table r2−0x2720, in order) | 1003133c–100313dc |
| 215 | `0x64c8` | s < 20: u = \|10 − s\|, f = u/10 + 0.2 (f32), f < 0.8 → 0.8, RGB = (48384f, 39936f, 16896f) clamped 0..0xffff; index 0 → 0x96; s ≥ 20: the s = 19 value (f = 1.1) (pulsing gold) | 100313f0–10031564 |
| 220 | `0x6720` | e by **t**: <4 → 0x78, <8 → 0x7e, <12 → 0xa8 (b += 10000 if < 55000); t ≥ 12 → index 0 | 10031578–10031630 |
| 221 | `0x6798` | s ≤ 5: (0, (5−s)·0x1900 + 32000, 0); else 0 | 10031644–100316ac |
| 222 | `0x6810` | s ≤ 5: ((5−s)·0x1900 + 32000, 0, 0); else 0 | 100316c0–10031728 |
| 223 | `0x6888` | s ≤ 10: r = b = s ≤ 5 ? (5−s)·0x1900 + 32000 : 32000, g = s ≤ 2 ? (2−s)·0x1900 : 0; else 0 | 1003173c–100317bc |

### 4.3 Resolved colours on the default CLUT 202  [MED]
Python model of the recipes above + nearest-RGB (Euclidean, 16-bit) Color2Index against `clut` 202.
MED because QuickDraw's Color2Index goes through the device inverse table (default 4-bit resolution);
a 4-/5-bit-cell model gives the same index except where noted in §4.4. "life" = first age whose
colour is 0 (the particle is drawn at ages 1..life−1; 120 = runs to the age limit). "level-dependent"
= some other "+ base" CLUT resolves differently (the recipe is fixed; the screen index is not).

| kind | look | life | resolved index = colour at sample ages (CLUT 202) | level-dependent |
|---|---|---|---|---|
| 1 | fire: white-yellow → yellow → orange → dark red | 24 | t1 1 #FFFF7F · t4 2 #FFFF00 · t8 4 #FFBF00 · t12 9 #FF7F00 · t16 77 #BB0000 · t20 68 #400000 | yes |
| 2 | blood red, darkening at the end | 38 | t1–23 76 #DA0000 · t24 77 #BB0000 · t30 174 #970000 | yes |
| 3 | violet-blue | 120 | t1 59 #4040FF · t4 64 #4000FF · t8+ 69 #0000FF | no |
| 4 | grey smoke, light → dark | 16 | t1 151 #E6E6E6 · t2 153 #B3B3B3 · t8 176 #75767C · t12 193 #404146 | yes |
| 5 | light blue (rain tail) | 120 | 47 #007FFF | no |
| 6 | mid blue (rain) | 120 | 51 #0040BF | CLUT 224 only |
| 7 | dark blue (rain head) | 120 | 52 #00407F | CLUT 224 only |
| 9 | yellow-orange spark, fading | 13 | t1 161 #F1AA00 · t2 97 #CF9B00 · t4 99 #B58700 · t8 119 #634A00 · t12 224 #181208 | yes |
| 10 | grey dark → white → dark | 17 | t1 158 #333333 · t4 155 #808080 · t8 151 #E6E6E6 · t16 159 #191919 | no (indices) |
| 11 | magenta, darkening | 15 | t1 137 #FE0BFA · t4 138 #D409D0 · t8 139 #A907A7 · t12 141 #540353 | no |
| 12 | green fading | 19 | t1–11 78 #00FF00 · t12 46 #00BF00 · t16 246 #005C00 | yes |
| 13 | blue flame: cyan → blue → dark blue | 24 | t1 37 #40FFFF · t8 43 #00BFFF · t12 47 #007FFF · t16 71 #0000B6 · t20 74 #000049 | 228, 238 |
| 199 | water bubble: pale → blue | 120 | t1 29 #7F7FFF · t4 59 #4040FF · t8 69 #0000FF · t12 70 #0000DB · t30+ 71 #0000B6 | no |
| 200 | water: pale blue → blue | 120 | see §4.4 | 242 only |
| 201 | acid: olive green, darkening | 120 | see §4.4 (base indices 113–116) | no |
| 202 | lava: orange → dark orange | 120 | see §4.4 | yes |
| 203 | magenta | 120 | t1 137 #FE0BFA · t2 138 #D409D0 · t12 139 #A907A7 · t16+ 140 #7F057D | 248 |
| 205 | sand / tan | 120 | t1 21 #BF7F40 · t4+ 30 #7F7F40 | 210, 212, 228, 238, 246 |
| 210 | blue flash (water-current mote) | 21 | t1 72 #000092 · t4 60 #4040BF · t8 28 #6040DE · t16 60 · t20 73 #00006D | 224, 236, 242 |
| 213 | magenta cycle | 120 | 137/138/139/140/141 cycling every 2 frames | no |
| 215 | gold pulse | 120 | t1 16 #BFBF40 · t4 21 #BF7F40 · t8–30 30 #7F7F40 · t40+ 16 #BFBF40 | 210, 214, 228, 238 |
| 220 | blue glow | 12 | t1–7 29 #7F7FFF · t8 59 #4040FF | 242 |
| 221 | green glow | 12 | t1 78 #00FF00 · t4 46 #00BF00 · t8 240 #009408 | yes |
| 222 | red glow | 12 | t1 76 #DA0000 · t4 77 #BB0000 · t8 174 #970000 | yes |
| 223 | magenta glow | 22 | t1 137 #FE0BFA · t2 138 · t8 139 · t12+ 140 #7F057D | 248 |
| ≥ 256 | fixed index `kind − 256` | 120 | (face pixels in §5.2) | — |

### 4.4 Geyser kinds 200–202 (closes geysers.md NR 1)  [HIGH for recipe and data bytes; MED for the index pick]
Geyser liquid kind 0 water → particle kind 200, 1 acid → 201, 2 lava → 202 (geysers.md §4). Shipped
geysers: kind 0 on level 10 (screen `clut` 214 "forest 1 new + base"); kind 2 on levels 50/51 (`clut`
220 "Upper Fire Caverns + base"); kind 1 unplaced. Ages are those on which the particle is drawn
(it starts at age −R(10), §2).

| kind | level CLUT | ages | requested RGB | index → on-screen RGB |
|---|---|---|---|---|
| 200 | 214 (and 202, 220) | 1–7 | e 0x78 (6666/9999/FFFF) | 29 = (32639, 32639, 65535) #7F7FFF |
| | | 8–15 | e 0x7e (6666/6666/FFFF) | 29 #7F7FFF |
| | | 16–23 | e 0xa8 (3333/3333/FFFF) | 59 = (16448, 16448, 65535) #4040FF |
| | | 24–119 | e 0xeb + 10000 (0/0/EEEE) | **69 = (0, 0, 65535) #0000FF** by nearest RGB; 70 = (0, 0, 56173) #0000DB under a 4-/5-bit inverse-table model |
| 201 | any (base entries) | 1–4 / 5–9 / 10–14 / 15–119 | — (indices) | 113 #6B9C30 / 114 #5F8C2B / 115 #537C26 / 116 #476C21 |
| 202 | 220 (levels 50/51) | 1 | (60000, 24000, 0) | 194 = (61423, 21074, 0) #EF5200 |
| | | 2–7 | (57200..51600, ·0.4, 0) | 197 = (54998, 21074, 0) #D65200 |
| | | 8–9 | (48800, 19520, 0) | 24 = (49087, 16448, 0) #BF4000 |
| | | 10–13 | (46000..43200, ·0.4, 0) | 198 = (44461, 16962, 0) #AD4200 (4-bit model: 24 at ages 10–11) |
| | | 14–19 | (40400..34800, ·0.4, 0) | 199 = (38036, 14649, 0) #943900 (4-/5-bit model: 188 #8C3110 at 18–19) |
| | | 20–119 | (32000, 12800, 0) | 106 = (33153, 8738, 0) #812200 (4-bit model: 188) |
| 202 | 214 (for comparison) | 1 / 2–13 / 14–17 / 18+ | as above | 135 #FF3F00 / 24 #BF4000 / 105 #9C2900 / 106 #812200 |

So 202 is **orange** (green = 0.4·red), not pure red; geyser spray lives the full 120 frames unless it
hits FG > 0x50 or falls into liquid (mode 1).

## 5. Emitters — every call site

41 direct `bl 0x10031e68` sites exist and no data word holds the code offset 0x31e68 (no
transition vector, so no indirect calls; same check for the four helpers below) [HIGH]; there are
17 `.BloodSpray`, 13 `.ExplodeFaceIntoParticles`, 2 `.BurnFaceRow` and 1 `.ParticleGlow` sites. Columns: kind / gravity / shape / delay / mode; velocities in 1/256 px/frame.

### 5.1 Direct `.NewParticle` sites  [HIGH for the constants at the cited `li`; MED for "what it is"]

| caller @ bl | kind | grav | shape | delay | mode | pos, velocity, count | represents |
|---|---|---|---|---|---|---|---|
| `.GenerateRain` 10010b80 / 10010c18 / 10010ca0 | heavy drop (R(2)==0): 7, 6, 5; light: 7, 7, 6 | 0 | heavy 5, light 4 | 0 | 1 | columns from H + R(50), step R(200)+50, to H + 0x294; at the view top; heavy (−1200, 3600) with the 2nd/3rd particle at v+4/v+8, h−1/h−2; light (−700, 2100) at v+2/v+4, h−1 with 50 % each (10010b18–10010ca0) | rain streak (3 stacked pixels, dark head) |
| `.WrapDrawWaterEffects` 10011258 | −(BG water kind), 200 → 199 | −5 (cell +0x14 = 3) / −20 (1, 2) / 0 (4) | 2 | 0 | 3 | per visible liquid cell with cell record +0x14 in 1..4, chance 18 % (24 % Enhanced) ÷ (cell +0x28 − 4) when > 4; h = cell x + 4 + R(24), v = cell +0x24; vy −300 − R(200) or −500 − R(300) (10011160–10011258) | rising bubbles (lit by ambient) |
| same 100113f4 | −(BG kind + 10) for BG kinds 200/203/205 → −210/−213/−215 | 0 | 7; 1 if no current; 4 for 205 | 0 | 3 | chance 22 % (28 % Enhanced); pos cell + 2 + R(28) each axis; vx = current hdr+0x2714 ± (R(\|c\|/2) − \|c\|/4) (0 for 203); vy 0, or 0xa0 + R(64) for 205 (10011270–100113f4) | floating current motes |
| same 1001167c | 10 | 0 | 7 (wind dir o1 ∈ 0–2, 16–20, 34–35), 4 (7–11, 25–29), else 1 or 2 (hdr+0x26c9); 49 % replaced by the last diagonal choice (an uninitialised stack short until one is made) | 0 | 2 | wind cells (overlay o1 0..35, strength o2): chance min(o2/2 + 20, 65) %; velocity `.LookupModedImpulse((o1+18) mod 36, 15·o2 + R(o2))`; pos cell + 3 + R(27) (main l. 8840–8873) | wind dust (grey blink) |
| `.BloodSpray` 10042828 | arg | 190 | 4 | i>>3/4/5 | 1 | §5.3 | blood |
| `.Splash` 10042ad8 / b00 / b28 (enter, mode 3) and 10042c50 / c78 / ca0 (leave, mode 4) | surface BG kind (min 200) / `+0x12a + 200` | 150 | 2, 4, 1 | 0, 1, 2 | 1 | §5.4 | splash |
| `.ExplodeFaceIntoParticles` 100435bc / 100436a0 / 100436ec | −(pixel + 256) / −(pixel + 256) / 1 | arg + R(30) / + R(12) / + R(12) | arg / arg / 1 + R(2) | pre-aged / pre-aged / R(5) | 1 | §5.2 | face bursts |
| `.BurnFaceRow` 10043974 / 100439ec | arg (1 or 13) / 4 | 20 − R(25) | random / 2 | 2 − R(12) | 0 | §5.5 | burn-away embers / smoke |
| `.ParticleGlow` 10043bfc | `+0x1a6` | 0 | 1 | 2 + R(5) | 0 | §5.6 | power-up glow |
| `.HandlePlayerShotSprite` 10059a30 / 10059b28 / 10059c04 | 200 / 3 / 9 | 250 / 350 / 0 | 1 + R(2) | 0 | 1 | spells 2 / 3 / 4, 2 / 5 / 7 per frame; positions and velocities spells-detail.md §3.2 table | Ice Crystals trail (water blue) / Ice Wall (violet) / Tree Trunk (orange sparks, its only visible part) |
| `.HandleEnemyShotSprite` 1005c714 | 1 | 190 | 1 + R(2) | 0 | 1 | shot 0x46a when hdr+0x2722 == 0: 5 + R(3) per frame at (x + vx/256 + 6 + R(36), y + vy/256 + 6 + R(36)), v = 0 (main l. 51832–51844) | Demon/Wizard fireball fire |
| `.HandleBonusSprite` 1005f3f0 / 1005f44c / 1005f4b0 | 1; 11 for 3103; 12 for 3107 | 0 | 1 + R(2) | 0 | 1 | candelabras 3100..3109 while `+0xb0 == 1`: one per frame at the type's flame point (2 on Enhanced; every other frame on Reduced); vx R(1000) − 500, vy R(1000) − 500 (vy drawn first) (handler l. 7337–7457) | candle flame |
| same 1005f53c / 5b0 / 624 / 698 | 1 | 0 | 1 | 0 | 0 | kind-1 candelabras: one per extra wick point, h + R(3) − 1, (0, −50 − R(100)) | wick smoke-flame |
| same 1005f7d4 | 1 | 180 | 4 | 0 | 1 | torch 1307 with R(30) == 1: (y+8, x+4), vx R(600) − 300, vy R(600) (falls) | torch spark |
| `.SetupEffectSprite` 10060924 | 1; 4 for ids 5/1090; 9 for id 2 | 150 | 1 + R(2) | 0 | 1 | 45 at (x+16, y+24) (big explosion 0x4b7: +32/+48), vx R(2000) − 1000, vy R(2000) − 1000 (vy drawn first) — triggers-background-2.md §2.1 | explosion |
| `.HandleCrawlerSprite` 10066328, `.HandleRoachSprite` 10077f44 | 2 | 80 | 4 | 0 | 1 | 100 at death (cy + 6, cx − 1), vx R(600) − 300, vy −350 − R(700) (vy drawn first) (enemies-ground.md; Roach handler l. 15827–15831) | death blood |
| `.HandleBatSprite` 1007f0a8 / 1007f154, `.HandleGremlinSprite` 100800a4 / 10080150 | 2 | 120 | 4 | 0 | 1 | N = 170 (Enhanced) else 100 (handler l. 17044–17049, 17628–17633) at (cy + R(6) − 3, cx + R(6) − 3) for the Bat, (cy + 16 + R(6), cx + R(6) − 3) for the Gremlin rider: vx R(650) − 325, vy −850 − R(700) − R(200) (vy draws first); plus N/8 at vx R(900) − 450, vy −850 − R(900) − R(300) (handler l. 17064–17083, 17643–17661) | death blood |
| `.HandleGremlinSprite` 10080ce4 | 2 | 100 | 4 | R(3), or −50 − R(70) when that is 0 | 1 | rider-less saddle: 8 + R(5) per frame; vx = body vx ± 400 (−400 when `+0x17e == 0`) + R(60) − 30, vy = body vy − 450 + R(60) − 30 (10080bb4–10080ce4) — the pre-aged third start at age 50..119, past row 2's end (38), and die unseen at their first draw | saddle blood |
| `.HandleGeyserColumn` 1006d394 / 1006d4e0 | `+0x14c + 200` | 190 | 4 | R(10) | 1 | geysers.md §4 item 5 | geyser spray |

### 5.2 `.ExplodeFaceIntoParticles @ 10043448` (face, pos, xStep, yStep, shape, gravity, style)  [HIGH]
Walks the face's encoded token stream (`**(face+0x10) + 0x10`; op = word >> 24: 0 end, 1 next row,
2 = n literal pixels (padded to 4), 3 = skip n). Rows: row 0 is used; at each row token, if the row
counter < 1 the next row is used and the counter = yStep; counter −= 1 → rows 0, 1, 1 + yStep, …
Pixels: within a used row, each literal pixel decrements a column counter that is **not** reset per
row; when it is < 1 a particle is emitted and the counter = xStep − 1 (`subi r21,r5,1` 100434e0).
Position = the pixel's level position (pos + column, row). Face centre `(pos.v + (face+8 + face+0xc)/2,
pos.h + (face+0xa + face+0xe)/2)`.

| style | kind | gravity | velocity | delay → life | raw |
|---|---|---|---|---|---|
| 100 | −(pixel + 256): the face's own colour, ambient-lit | g + R(30) | vx R(100) − 50, vy 40 − R(750) | −(98 − R(20)) → starts at age 79..98, lives 22..41 frames | 10043550–100435bc (RNG order R(20), R(750), R(100), R(30)) |
| 101 | −(pixel + 256) | g + R(12) | radial: vx 50·(h − cH) + R(60) − 30, vy 50·(v − cV) + R(60) − 30 | −(104 − R(16)) → age 89..104, lives 16..31 | 10043604–100436a0 (R(60), R(60), R(16), R(12)) |
| 102 | 1 (fire) | g + R(12) | radial as 101; shape 1 + R(2) (shape arg ignored) | R(5) | 100436ac–100436ec (R(60), R(60), R(5), R(2), R(12)) |

Callers (args xStep, yStep, shape, gravity, style; raw `li` lines before each `bl`):

| site | args | what |
|---|---|---|
| `.ExplodeCrunchedTile` 1004456c | 2,2,2,100,100 | crunched FG tile (FG face set `_DAT_1009ff88`) |
| `.ShieldBlock` 10055654 | 1,1,1,100,101 | Magical Shield reflecting shot 0x6f4 (first reflection) |
| `.HitPlayerSprite` 10055a48 / 10055a88 / 10055ab0 | 1,1,1,40,101 / 2,1,7,40,101 / 2,2,7,40,101 | Xichron pickup burst by detail and the drifting count (§1.4) |
| `.KillPlayerShot` 1005ae04 | 2,1,7,80,101 | spell shot dying after its hit counter (spells-detail §3) |
| `.KillEnemyShot` 1005cf4c / 1005cf84 / 1005cfe4 | 1,1,1,100,100 / 1,1,1,0,101 / 2,2,2,150,102 | 0x754 and 0x76c..0x775 / 0x6f4 / 0x46a fireball (main l. 52060–52088) |
| `.HandlePlatformSprite` 10064b0c | 1,2,4,50,100 | ice floe 0x57c lifetime `+0xa6` ending (platforms-ropes-radial §2.4) [MED identity] |
| `.HandleBoxSprite` 1006de24 / 1006f59c | 1,2,4,100,100 / 2,2,2,50,100 | crumbling ledge 1081 at lifetime 0 (pickups-boxes §2.4.6) / ice wall 2941 at HP < 1 |
| `.KillBox` 10070668 | 2,2,2,100,100 | box destroyed |

### 5.3 `.BloodSpray @ 100425f8` (victim, attacker, count, speed, spread, kind)  [HIGH]
1. Both hot rects (`+0x34..+0x3a` offset by `+0xc`/`+0xa`) are intersected (`.SectRectFast`
   10042674); no overlap → nothing.
2. Start point = centre of the overlap (100426a4–100426f0).
3. `dir = .FindDesiredDirectionGeneric(victim centre +0xe, attacker centre)` = the 10° sector of
   attacker → victim (convention enemies-flyers.md §0; confirmed for the up-left quadrant from the
   decompile, main l. 37458ff.) → `FUN_100417bc(dir, speed)` → (x, y) along it (100426f4–10042724);
   both **negated** (`fneg` 10042738/1004273c): the mean velocity points from the victim **back
   toward the attacker**, magnitude `speed`.
4. For i = 0..count−1: the point moves halfway to the victim centre (`h = (h + cx) >> 1`,
   `v = (v + cy) >> 1`, 100427a0–100427e4 — the first particle sits midway, later ones converge on the
   centre); `vy = −y + R(spread) − spread/2` (drawn first), `vx = −x + R(spread) − spread/2`;
   delay `i >> 3` if count ≤ 150, `i >> 4` if ≤ 300, else `i >> 5` (batches of 8/16/32 per frame);
   `NewParticle(kind, 190, pt, 4, vx, vy, delay, 1)` (10042764–10042828).

| caller (bl) | count, speed, spread, kind |
|---|---|
| `.HurtPlayer` 100549f4 | 40, 500, 150, 2 |
| Crawler 10066744 / 10066998, Roach 100780dc / 10078264, Bat 1007f5fc, Swarm member 1007f7f8, Gremlin 10080e28, Frog 10082a10 / 10082b84, Salamander 100835e4, Dillo 10087444, Chief 1008c190 | 40, 400, 150, 2 |
| `.HurtGoblin` 1006a1f8 | n = 1 (`li r0,1` 1006a1d8): 40, 400, 150, 2 |
| Walker 1006a48c, Xichra 1008ff48 | n = max(1, dmg/100): 40n, 50n + 350, 150n, 2 |
| Blob 1007d7a4 | 40, 400, 150, **0xc9 = 201** (olive green, level-invariant) |

With the common (40, 400, 150, 2): 5 frames of 8 particles, 1×2 px, blood red #DA0000 darkening to
#970000 at ages 24–37, base speed 1.56 px/frame toward the attacker ± 0.29 px/frame per axis,
gravity 0.74 px/frame².

### 5.4 `.Splash @ 10042874` (sprite, 3 = enter / 4 = leave)  [HIGH]
Only when `+0x13e ≠ 0` and the sprite has a face. Kind: entering = the BG kind of the topmost liquid
cell above the sprite (raised to 200 if lower); leaving = `+0x12a + 200`, and only when the hot rect is
> 16 px wide and vy < −0x4b0. For every pixel column h from `x + rect.left − 4` to `x + rect.right + 3`
(step 1: the `+ R(1)` is always 0), at the surface y (leaving: y − 4):
`vx = R(500) − 250 − vx_s/16`, `vy0 = −600 − R(200) − vy_s/8`, then three particles
`(kind, 150, pt, 2, vx, vy0 + 400, 0, 1)`, `(…, 4, vx, vy0 + 200, 1, 1)`, `(…, 1, vx, vy0, 2, 1)`
(10042a58–10042b3c). Sound conditions: main l. 38019–38026.

### 5.5 `.BurnFaceRow @ 100437d8` and `.HandleBurn` styles  [HIGH; shape-0 case MED]
`.HandleBurn` (10043db8–10043e64) per frame runs `+0x8d + 1` rows; each: `+0x1a2 += 1`,
`BurnFaceRow(face, pos, 2, row, flip +0x17e, kind)` with **kind 1 (fire), or 13 (blue flame) when
`+0x8e ≠ 0`** — the "styles 1 vs 0xd" of INDEX item 15 are particle kinds; on Enhanced with R(100) > 50
and `+0x8d == 0` a second pass with step 1. BurnFaceRow emits on face row `row` only, every
`step`-th literal pixel (counter carried along the row): position (v + R(4), h); delay `2 − R(12)`
(up to 9 frames pre-aged); shape by R(100) = r: r ≥ 87 → 5, 26..86 → 2, 13..25 → 4, 1..12 → 1, r = 0 →
r28 unchanged (the previous emission's shape; for the first emission it is the caller's r28 = the
kind: 1 → 1×1, 13 → nothing drawn); gravity 20 − R(25); vx R(50) − 25; vy −500 − R(150); mode 0
(100438c8–10043974). With R(5) == 1 also a smoke particle `(4, 20 − R(25), pt, 2, ±(250 + R(200)),
−300 − R(250), same delay, 0)` (sign + when R(100) ≤ 50) (100439ec).

### 5.6 `.ParticleGlow @ 10043ad0` (face, pos, kind, chance%, flip)  [HIGH]
From `.StandardSpriteCleanup` (`bl` 10036f0c) every frame for sprites with `+0x1a8 ≠ 0`. For the first
and last pixel of every literal run of the face (the outline): RNG R(4), R(5), R(100) (discarded),
R(150); `vx = 120 + R(150)`, negated when the pixel is left of the face centre; if R(100) ≤ chance:
`NewParticle(kind, 0, (v + R(4), h), 1, vx, 40 − R(80), 2 + R(5), 0)` (10043b7c–10043bfc). Only the
player sets the fields (handler l. 2509–2564): Solid-liquid spheres → kind `0xdc + liquid` (220 blue
water, 221 green acid, 222 red lava), chance 8; three other timed power-ups → 0xdf (223, tints
0x10008/0x10003) or 9 (tint 0x1000c), chance 8; no effect → both 0. Hurt flash: on frames where the
parity flag `_DAT_1009fd30` ≠ 0, `+0x116 ≥ 15` and the `psVar25` counter is 0, tint 0x10006, and if
also `+0x116 > 60` tint 0x10009 with kind 220, chance 16; with `+0x116` 15..60 the two fields keep
their previous values (handler l. 2509–2564) [MED for the flag/counter meanings].

## NOT RESOLVED
1. Exact `Color2Index` result where the nearest-RGB and inverse-table models differ (kind 200 old age
   69 vs 70; kind 202 on CLUT 220 at ages 10–11 and 18+). Tried: nearest Euclidean, 4-bit and 5-bit
   cell-centre models (Python). Settling it needs a Color Manager `MakeITable` reimplementation or a
   capture from the original running on 8-bit Mac OS.
2. Contents of the ambient light table `_DAT_100a0130` (what negative kinds look like on levels with
   hdr+0x2706 ≠ 0) — `.CalcLightingTable` not transcribed (engine NR).
3. What the off-screen buffers 0004/0008 hold between frames (the mask rule in §3.2 is mechanical);
   engine-side.
4. `.WrapDrawWaterEffects` cell-record fields (+0x8, +0xc, +0x10, +0x14, +0x24, +0x28 from
   `.FillCachedTileArray`) are named by offset only; the bubble/mote conditions are HIGH as arithmetic,
   MED as meaning.
5. The initial value of the wind-dust shape stack short (§5.1 row `1001167c`) before the first
   diagonal emission — uninitialised stack; on a level whose wind cells are all horizontal/vertical it
   is whatever the frame left there (0 or > 7 draws nothing).

## Proposed additions to physics.md §0
| field | type | meaning | evidence |
|---|---|---|---|
| +0x8d | u8 | burn rows per frame − 1 (`.HandleBurn` loop bound) | 10043e68–10043e78 |
| +0x8e | u8 | burn style: ≠ 0 → particle kind 13 (blue flame), else 1 | 10043db8–10043dcc |
| +0x1a6 | i16 | glow particle kind (`.ParticleGlow`) | 10036f0c caller, handler l. 2519–2563 |
| +0x1a8 | i16 | glow chance per outline pixel per frame, % (0 = off) | same |

## Corrections to the existing bank
| # | file § | old | new | evidence |
|---|---|---|---|---|
| 1 | geysers.md §4 item 5, NR 1 | "arg 4 = 4 [NOT RESOLVED meaning]"; "202 RGB red `(10 − age/2)·0xaf0 + 32000`, blue 0" | arg 4 is the **shape code: 4 = 1 px wide × 2 px tall** (§3.2). Kind 202 has **green = 0.4·red** (orange). Kind 200's ramp is by age>>1 (entries switch at ages 8/16/24; the by-age first write is overwritten). Exact colours §4.4. NR 1 closed (index-pick caveat in our NR 1) | 10015b60 jump-table case 4; 10031048–10031098 (`lfd 100a17a8` = 0.4); 10030994 vs 10030fa8 |
| 2 | enemies-flyers.md §3.6 | "N × NewParticle(2, 0x78, …) + N/8 larger ones" | the N/8 are the **same 1×2 shape**, faster: vx R(900) − 450, vy −850 − R(900) − R(300) (vs R(650) − 325, −850 − R(700) − R(200)) | `li r6,0x4` 1007f148 / 10080144; handler l. 17074–17083 |
| 3 | spells-detail.md §3.2 table note, NR 1 | "`NewParticle(a, b, pos, size, vx, vy, c, f)`: meanings of a/b not decoded [LOW]" | a = colour kind (§4), b = gravity per frame, size = shape code, c = delay, f = collision mode (§2) | NewParticle 10031ed4–10031f18; HandleParticles 10031898–100318a4 |
| 4 | triggers-background-2.md §2.1, NR 5 | "MED for the `NewParticle` argument names"; "particle kinds 1/4/9 … not decoded" | argument names confirmed HIGH; kind 1 = fire ramp (24 frames), 4 = grey smoke (16), 9 = yellow-orange spark (13), 200+ = liquids (§4.2–4.4) | as #3 |
| 5 | enemies-water-cave.md §3.4, NR 4 (part) | "kind 0xc9 … [MED: slime-coloured]" | kind 201 = palette indices 113–116, olive green #6B9C30 → #476C21, identical on every level | 10030fc0–10030ffc; clut decode §4.1 |
| 6 | save-continue.md §8.2 prefs table +0x06 | "count `*_DAT_100a019c` < 1000 [MED: count = live particles]" | it is the live-particle counter, but it is never reset per level and colour-0 deaths decrement it twice, so it drifts negative (and can wrap) — the < 1000 / < 1500 gates are not a live-count test in practice | §1.4 (10031ba8, 10031bc8; no other writer) |
| 7 | enemies-ground.md NR 2 | "`.BloodSpray` argument meaning" | closed: (victim, attacker, count, speed, spread, kind), §5.3 — spray aims back toward the attacker | 100425f8–10042828 |
