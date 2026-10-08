# Ferazel's Wand 1.0.3 — lighting, tint/remap tables, blend faces, flame, gamma fades

Code readings only; nothing behaviour-verified. Date 2026-10-04. Sources: `ghidra/Ferazel_pef.decompiled.c`, `ghidra/Ferazel_handlers.decompiled.c`, `ghidra/Ferazel_pef.disasm.txt`, `tools/const.py` on `ghidra/Ferazel_pef`, and Python decodes of the `clut`/`PICT`/`Mlvl` resources in `$FW` (Backgrounds, Sprites, World Data, app fork).

Lane L1 of wave 2. Closes INDEX item **10** and the colour part of item **15** (tables
2/3/4/0xb/0xc/0xf/0x10..0x15/0x17/0x18). Labels as in INDEX. Addresses: `10xxxxxx` = raw listing;
`r2±x` = TOC-relative (r2 = 0x100a7840); "slot" = TOC word, "global" = the address the slot holds.

## 1. Which colours the tables are built from

### 1.1 Globals  [HIGH]
TOC words resolved with `pef.py` (word + 0x1009f840):

| slot (r2 off) | global | contents | set by |
|---|---|---|---|
| `1009ff8c` (−0x78b4) | `101e8f9c` | level+base CLUT = `GetCTable(hdr+0x285e)`, 0 → 202 | `.SetupLevel` (main l. 2301–2318) |
| `1009fe94` (−0x79ac) | `101e8f98` | **working copy** of that CLUT (`HandToHand`), the one `.AnimateCLUT` edits | `.SetupLevel` l. 2320–2329 |
| `1009feb0` (−0x7990) | `101e8f88` | alt CLUT `hdr+0x271c` (0 in all 24 levels) | `.SetupLevel` l. 2333–2340 |
| `100a0038` | `101e8f8c` | `clut 801` "System CLUT" (light-face conversion) | `.InitAppGlobals` l. 358 |
| `100a0074` | `101e8f7c` | `clut 198` "cooling map clut" | `.InitAppGlobals` l. 420 |
| `100a0020` / `100a001c` | | `clut 200` / `199` | `.InitAppGlobals` l. 404/412 |

`clut` 198/199/200/801 are byte-identical in the app fork and the Backgrounds file (Python compare) [HIGH].

### 1.2 Screen CLUT and the colour search  [HIGH for the calls; LOW for the index chosen]
`.SetScreenClut(c) @ 1000faa8`: rewrites every entry's value field to its index, `SetEntries(−1,0xff)`,
`CTabChanged`, **`MakeITable(c, nil, 0)`**, `.CopyScreenClut`, `.ChangeBlitPortClut`. Every table
builder maps a computed `RGBColor` with **`Color2Index`** (glue `1009f1ac`, e.g. `10020c48`), i.e. the
QuickDraw inverse table of the current device built from the level+base CLUT by that `MakeITable`.
The search rule lives in ROM: resolution `res = 0` means the device's preferred resolution, and the
nearest-colour rule inside `MakeITable` is not in this binary → NOT RESOLVED 1. ⚑ corrected (review
2c, 2026-10-04) #4: **the bank's one `Color2Index` model is stated in particles §4.3** — exact nearest
RGB, ties → lowest index; it is a **model; several steps may differ**, and every chosen index is
[LOW]; the requested RGB beside it is the exact formula output [HIGH]. The "→idx" cells of this file
were computed before that ruling with a 4-bit inverse-table model (request quantised to 4 bits per
channel, bit-replicated); its agreement with the exact search over sprite indices 0..0x9f is 39/160
(table 0xe, dark) to 153/160 (table 0xc) (a 5-bit table: 66..157/160). Review 2c's spot re-runs
agree under both (tint 1 @06 → 4c, 0xc @2a → 87, 3 @61 → 32) except water table 0 @9e: 49 under
4-bit, **84** exact — both are given in §4; the other cells were not re-run.

`.CopyScreenClut @ 1000fa10` copies `(ctSize+1)·8` bytes from the main device's CLUT handle start
(header + entries 0..254) into the window port CLUT [HIGH, `1000fa4c..1000fa5c`].
`.ChangeBlitPortClut(port, c) @ 100349c4` copies RGB of entries `0 .. ctSize−1` (**0..254**, the
loop is `i < ctSize`, `10034a38 lha 6; cmpw; blt`) then copies the **seed** of `c` into the port CLUT
(`10034a44..10034a4c`) so CopyBits sees identical seeds and never translates [HIGH].

### 1.3 When the tables are built  [HIGH]
- `.SetupLevel`: `.InitLighting` (only on a tileset reload; zeroes 11 tables of dark slabs 0 and 1,
  harmless) → … → `SetScreenClut(level+base)` → **`.CalcLightingTable`** (l. 2571–2573). Lighting and
  ambient tables use the **unanimated** `1009ff8c` CLUT.
- `.GameLoop` (once per level entry, before the frame loop, l. 5206–5208): `.AnimateCLUT` (one step)
  → **`.BuildTintTable`** (which ends with `.BuildWaterTintTable`, `.BuildTranslucTable`,
  `.BuildPosterizationTable`, `.BuildReddenTable`, `10022b18..10022b24`) → `.BuildReddenTable`
  again. Tint, water, redden and translucency tables use the **working copy** `1009fe94`.
- `.BuildSineTable` (`.InitAppGlobals` l. 550) is not a colour table.

### 1.4 Which CLUT the computed colours use, and how much the level matters
**CLUT 202 'base + earthcav'**: the default when `hdr+0x285e = 0` (`GetCTable(0xca)`), used by
levels 1 and 2, and its entries 0x00..0xa0 equal `clut 200` (the sprite conversion CLUT), so the
source colours of sprite pixels are exact. Python census of the 23 "+ base" CLUTs: entries
**0x00..0x9f are identical to `clut 200` in every one** (0xff too; 0xa0 only in 202); 0xa0..0xfe are
the level's own colours [HIGH, data]. So for a sprite pixel the *requested* colour is
level-independent, but the *chosen* index can land in 0xa0..0xfe and differ by level. Number of
sprite indices (of 160) whose mapped RGB differs across the 16 CLUTs the shipped levels use
(202, 210, 212, 214, 216, 218, 220, 222, 224, 228, 236, 238, 240, 242, 246, 248), res-4 model [LOW]:
1:138 2:32 3:76 4:77 5:87 6:97 7:111 8:62 9:55 0xb:106 0xc:157 0xd:66 0xe:76 0x16:71 0x10:3 0x11:12,
and **0 for the fixed-index tables 0xf, 0x12, 0x14, 0x15, 0x17, 0x18** (0x13: 1, its `0xa0` entry —
`clut[0xa0]` is 000000 in 202, 191919 in 210, ffff4a in 214, f7f7f7 in 224, …).

### 1.5 `.AnimateCLUT @ 1001180c` (header 0x2730 mode, 0x2732 count n, 0x2734 period P, 0x2736 amplitude A)
Not a rotation: a sinusoidal modulation of the **n entries `0xff−n .. 0xfe`** of the working copy.
Per call [HIGH, `10011850..10011cb0`, constants `100a1600..100a1620`]:
```
if n == 0: return
P' = P·0.8 (mode 4) | P·0.6 (mode 5) | P·0.3 and A' = A·1.28 (mode 6) | P   (trunc; 100a1620/1618/1610/1608)
c += 1; if c >= P': c = 0                               // global at slot r2−0x7758
skip the rest if prefs+6 (Effects) == 3, or == 2 and frame&3 != 0, or == 1 and flag r2−0x7b10 set
ph = (c·360)/P' wrapped to 0..359                       // same phase for every entry
s  = (A' · sinT[ph]) >>8 >>8   (each shift rounds toward 0; sinT = −sin·65536, platforms §1.1)
for i in 0xff−n .. 0xfe:  (R,G,B) = level+base[i]
  mode 1: R += s, ≥0                          mode 2: d = s−A'; R,G,B −= d   (brighten by 0..2A')
  mode 3..7: R1 = R + s − A';  B1 = B + R1;  R = trunc(0.7·R1); B = trunc(0.7·B1)   (100a1600)
     mode 4: R = trunc(2.1·R)+7000, G = trunc(0.5·B), B = 0     mode 5: R = trunc(2.5·R), G = B = 0
     mode 6: R=G=B = (R+G+B)/3 − FastRand(4000)                   mode 7: R = B = 0
  clamp each to 0..0xffff, store into working copy; then SetEntries(0, 0xff, copy)
```
Shipped use: levels 50/51 mode 1, n 48 (entries 0xcf..0xfe), P 180/56, A 12000 — a red pulse on
the lava colours; level 67 mode 3, n 16 (0xef..0xfe), P 75, A 12000 (Python dump of `Mlvl`) [HIGH].

### 1.6 `.AltClutMod @ 10004134`
As sprites §4 states (entries 0xa0..0xfe, `c' = clamp(c + 2·alt[lum>>8].c − 0x8000)`); dead in the
shipped data (`hdr+0x271c = 0` in all 24 levels; the alt CLUTs 300 'Blue tinge altClut orig', 301
'Gold tinge altClut', 302 'Purply tinge altClut', 401 'bluepurp ting' exist unused) [HIGH].

## 2. The draw-mode word `+0xb8 = mode<<16 | arg` → table

### 2.1 Dispatch  [HIGH]
`.BlitEncFaceX @ 1002c908` routes modes 5, 6, 8, 0xb, 0xd, 0xe, ≥0x14 (or a rotated/scaled face) to
dedicated blitters and **every other mode** to `.BlitEncFaceSpecial{NoClipX,ClipX}` /
`.BlitEncFaceFlip{NoClip,Clip}Special`. Those four pick the per-pixel 256-byte remap table with a
13-entry jump table (NoClipX: `100276b8 cmplwi 0xc; bgt`; table at `100a3d98`, targets read with
`pef.py`):

| mode | table base (TOC) | index | built by | used for |
|---|---|---|---|---|
| 1 | `_DAT_100a0140` (−0x7700) | `arg·0x100` | `.BuildTintTable` (§3) | class tints `0x1000k` |
| 3 | `_DAT_100a0178` (−0x76c8) | `arg·0x100`, arg 0..7 | `.BuildReddenTable` A (§5) | hurt flash, `+0x1b4 == 0` |
| 4 | `_DAT_100a0174` (−0x76cc) | `arg·0x100`, arg 0..14 even | `.BuildReddenTable` B (§5) | hurt flash, `+0x1b4 ≠ 0` |
| 6, 9 | `_DAT_100a0170` (−0x76d0) | `arg·0x100` (water kind) | `.BuildWaterTintTable` (§4) | 9 = whole sprite, 6 = submerged part (ripple blitter) |
| 0xc | `_DAT_100a0130` (−0x7710) if `arg&0xff == 0`, else `_DAT_100a0134` (−0x770c) | `(char)(arg>>8)·0x100` / `(char)(arg>>8)·0x6e00 + (arg&0xff)·0x100` | `.CalcLightingTable` (§7) | dynamic light |
| 0, 2, 5, 7, 8, 0xb, > 0xc | **none** | — | — | the table register keeps the caller's r7 (the width argument) |
| 0xa | none — **vertical squash**, pixels copied raw: explicit `sVar9 == 10` arms in `.BlitEncFaceSpecialClipX` (`100275d4 cmpwi r25,0xa`; accumulator `li r6,0x100` `100271f0`; `10027614..10027630`); draw-effects §2.6 is authoritative ⚑ corrected (review 2c, 2026-10-04) #2 | — | — | springboard gauge, platform child |

The same switch is in `.BlitEncFaceRot`, `.BlitEncFaceScale` and the flip variants (decompile)
[MED for those three]. So modes 2, 7, 0xf..0x13 would remap through whatever the table register
holds (NoClipX: r7 = width; ClipX, jump table `100a3d64`, default: r5 = the caller's source-offset
Point). Mode 0xa does not: its jump-table entry is the default, but ClipX handles it in its own
arms as a vertical squash (draw-effects §2.6) ⚑ corrected (review 2c, 2026-10-04) #2. Census of every `+0xb8` store in both dumps: constants are modes 1, 8, 9, 0xb;
computed values are 5 (`sparkle + 0x50000`, handlers l. 2591), 0xc (§2.2 and
`.UpdateRadiusSprites` `…·0x100 + 0xc0000`, main l. 35903), `0x10000 + var` (tier tables), and — 3/4 (hurt flash) and 6 (submerged rows) are draw-time substitutes, never stored (`100146f0..10014728` has no `+0xb8` store; draw-effects §2.1, physics §0.1; ⚑ corrected (review 2i, 2026-10-04) #2) —
**`0xa0000 + d`, d = 11..250, on the platform child `+0x1d8`** (`.HandlePlatformSprite`, handlers
l. 9010) — ~~the only stored mode without a table (NOT RESOLVED 9)~~ a vertical squash by d/256
(draw-effects §2.6) ⚑ corrected (review 2c, 2026-10-04) #2, #6 [HIGH census]. Modes 2, 7,
0xf..0x13 are never stored; "0x10..0x13 blends" in physics §0 are mode-1 *table* numbers.
`.SetRadiusSpritesEffect(s, 0x10018)` gives radial spokes tint table 0x18 (main l. 54626 ff.).

### 2.2 Computed modes in `.WrapDrawSprites @ 100144c8`  [HIGH]
- Hurt flash: `n = min(+0xaa, 7)`; `+0x1b4 == 0` → `0x30000 + n`, else `0x40000 + 2n` (overrides
  `+0xb8` for the draw only; `100146f0..10014728`, `addis 3` / `addis 4`).
- Dynamic light (`+0x89 ≠ 0`): `D = .GetLightTile(tile of +0x10, tile of +0xe)`, `F = .GetFakeLight(…)`;
  `D > 0 or F > 0` → `+0xb8 = D·0x100 + 0xc0000 + F` else 0 (`10014788..100147bc`, `rlwinm 8; addis 0xc`).
  **D is signed**: `.GetLightTile @ 1003c2b4` returns `(BG cell >> 8 & 0xff) − 1` (`1003c328`,
  `1003c340 subi 1`), i.e. −1 where the light byte is 0. Then `D·0x100 + 0xc0000 = 0xbff00`: the
  draw becomes **mode 0xb** with arg `0xff00 + F` (negative as a short) whenever `F > 0`. Light byte 0
  covers whole maps in levels 18, 20, 25, 45, 52, 67, 70; level 30 has 1600 cells of byte 255
  (D = 254 → `(char)0xfe = −2` slab) (Python census of BG maps) [HIGH arithmetic + data; visible
  result NOT RESOLVED 3]. `+0x89` is set only by platform, chain, box and background handlers
  (handlers l. 9057, 9363, 12502, 13231, 14904, 15259) [HIGH].
- `+0x11c ≥ 1` (partly submerged): the lower part is drawn as mode `0x60000 + +0x128` (water kind).

## 3. Tint bank — mode 1, `_DAT_100a0140 + k·0x100` (global `101e05c2`, 25 tables)

### 3.1 Algorithm  [HIGH, each row's raw range]
`src[i]` = working-copy entry i (R,G,B 16-bit). `lum = (R+G+B)/3` via `mulhw 0x55555556`
(truncating). "→idx" = `Color2Index` of the RGB (§1.2). Tables 0..0xf are first filled with the
identity (`100213e0..10021474`), so entries a loop skips stay identity; table 0 is never overwritten.

| k | entries | per-entry rule | raw |
|---|---|---|---|
| 0 | — | identity | `100213fc` |
| 1 | 0..0xfe | (min(lum+10000, 0xffff), 0, 0) | `10021558..100215dc` (`addi 0x2710`) |
| 2 | 0..0xfe | lum+10000 ≤ 0xffff: (lum+10000, same, 0); else (0xffff, 0xffff, min(4·(lum+10000−0xffff), 0xffff)) | `10021600..100216b0` |
| 3 | 0..0xfe | (0, lum>>1, min(2·lum, 0xffff)) | `100216d4..10021770` |
| 4 | 0..0xfe | (R>>1, G>>1, min(2·lum, 0xffff)) | `10021794..1002181c` |
| 5 | 0..0xfe | grey min(lum+16000, 0xffff) | `10021840..100218bc` (`addi 0x3e80`) |
| 6 | 0..0xff | (R>>1, G>>1, B>>1) | `100218d0..10021934` |
| 7 | 0..0xff | (R>>2, G>>2, B>>2) | `10021948..100219ac` |
| 8 | 0..0xfe | each ·1.5, clamp (`100a1728`) | `10021aac..10021b94` |
| 9 | 0..0xfe | each ·2.5, clamp (`100a16a8`) | `10021bbc..10021ca4` |
| 0xa | 0..0xfe | (FastRand(5000), lum, FastRand(5000)) — B drawn first, then R; **re-randomised every level** | `10021cc0..10021d44` |
| 0xb | 0..0xfe | grey lum | `10021d60..10021dcc` |
| 0xc | 0..0xfe | (0xffff, lum, 0) | `10021df0..10021e60` |
| 0xd | 0..0xff | (R, (G+0xffff)>>1, (B+0xffff)>>1) | `10021e74..10021edc` |
| 0xe | 0..0xff | ((lum + lum>>1)>>1, (lum>>1 + lum>>2)>>1, 0) — sepia | `10021ef8..10021f80` |
| 0xf | 0..0xff | **fixed index** by `lum>>12`: 0,1→0x43; 2,3→0x8d; 4,5→0x8c; 6,7→0x8b; 8,9→0x8a; 10,11→0x89; 12,13→0x88; 14..16→0x8d | `10021fd8..10022048`, jt `100a3cec` |
| 0x10 | 0..0xff | sel only: (trunc(1.7·lum) **mod 0x10000**, trunc(1.2·lum) mod 0x10000, 0) — no clamp, `sth` | `1002208c..10022198` (`100a16a0`, `100a1698`) |
| 0x11 | 0..0xff | sel only: (0, clamp(trunc(2.5·(lum−8000)), 0, 65535), min(trunc(1.7·lum), 65535)) | `100221cc..10022324` |
| 0x12 | 0..0xff | sel only: x = clamp(2·lum − 0x4000, 0, 0xffff); `x>>12`: 0→0x9f; 1,2→0x83; 3,4→0x82; 5,6→0x81; 7,8→0x80; 9,10→0x7f; 11,12→0x7e; 13,14→0x7d; 15,16→0x7c | `10022348..10022460`, jt `100a3ca8` |
| 0x13 | 0..0xff | sel only: same x; 0→0xff; 1→0xa0; 2,3→0x8d; 4,5→0x8c; 6,7→0x8b; 8,9→0x8a; 10,11→0x89; 12..16→0x88 | store `100225b4`, jt `100a3c64` |
| 0x14 | 0..0xff | sel only: same x; `x>>13`: 0,1→0x7b; 2→0x7a; 3→0x79; 4→0x78; 5→0x77; 6→0x67; 7,8→0x66 | `100225f8..10022738`, jt `100a3c40` |
| 0x15 | 0..0xff | sel only: 0x9f − x/0x1a2c (→ 0x96..0x9f) | `10022764..10022840` (`mulhw 0x4e407f29; srawi 11`) |
| 0x16 | 0..0xff | each ·0.75, no clamp needed (`100a16b0`) | `100219cc..10021a84` |
| 0x17 | 0..0xff | **all** indices: x = clamp(2·lum − 32000); `x>>12`: 0→0xff; 1→0x35; 2,3→0x76; 4,5→0x75; 6,7→0x74; 8,9→0x73; 10,11→0x72; 12,13→0x71; 14..16→0x2a | `100228a8 subic 0x7d00`, jt `100a3bfc` |
| 0x18 | 0..0xff | **all** indices, mapping of 0x12 | store `10022a24`, jt `100a3bb8` |

"sel" = indices **0x24, 0x3b, 0x3f, 0x40, 0x4e, 0x53, 0x57, 0x5b, 0x71..0x76**; every other index maps
to itself (the store uses the loop index, e.g. `10022094 extsh r3,r20` → `10022180 stb r3,0x1000`)
[HIGH]. In CLUT 200 those are 7f0040, 4040ff, 404000, 4000ff, 00ff00 ×4 and the olive ramp
6b9c30..2f4c17 (the Walker body colours by name of the tables' use, enemies-ground §3.1) [HIGH data].
Fixed-index outputs are themselves base-palette ramps (CLUT 200): 0x88..0x8d magenta ffaefe..540353,
0x7c..0x83 teal 93ddd5..193834, 0x66/0x67/0x77..0x7b browns, 0x97..0x9f greys e6e6e6..191919
(table 0x15 reaches 0x96 = 00ff00 filler only for x ≥ 60300, i.e. lum ≥ 0x95c6),
0x71..0x76 olive, 0x35 004000, 0x2a 40bf00, 0x43 400040 [HIGH data].

### 3.2 Computed colours, CLUT 202 (requested RGB → chosen index, its RGB)  [requested HIGH; chosen LOW]
Columns = source index `rgb`. Fixed-index tables show only "→idx".

| k | 00 `ffffff` | 06 `ff7f7f` | 0e `bfff00` | 1d `7f7fff` | 2a `40bf00` | 31 `007f00` | 61 `cf9b00` | 71 `6b9c30` | 88 `ffaefe` | 9a `999999` | 9e `333333` |
|---|---|---|---|---|---|---|---|---|---|---|---|
| 1 | ff0000→4c da0000 | d10000→4c | bc0000→4d bb0000 | d10000→4c | 7c0000→ae 970000 | 510000→44 400000 | a00000→aa b20300 | 8f0000→ae | ff0000→4c | c00000→4c | 5a0000→44 |
| 2 | ffff9c→01 ffff7f | d1d100→85 ffdf00 | bcbc00→11 bfbf00 | d1d100→85 | 7c7c00→1f 7f7f00 | 515100→6f 525200 | a0a000→11 | 8f8f00→1f | ffff2c→02 ffff00 | c0c000→11 | 5a5a00→6f |
| 3 | 007fff→2f 007fff | 0055ff→32 0040ff | 004aff→32 | 0055ff→32 | 002aaa→47 0000b6 | 001554→84 11114c | 003cf2→32 | 0034d0→33 0040bf | 0072ff→2f | 004cff→32 | 001966→49 00006d |
| 4 | 7f7fff→1d 7f7fff | 7f3fff→20 7f40ff | 5f7fff→36 407fff | 3f3fff→3b 4040ff | 205faa→3c 4040bf | 003f54→fd 003e61 | 674df2→20 | 354ed0→3c | 7f57ff→20 | 4c4cff→3b | 191966→49 |
| 5 | ffffff→00 | e8e8e8→97 e6e6e6 | d3d3d3→97 | e8e8e8→97 | 939393→9a 999999 | 686868→9c 666666 | b7b7b7→99 b3b3b3 | a6a6a6→99 | ffffff→00 | d8d8d8→97 | 717171→b0 75767c |
| 6 | 7f7f7f→b0 75767c | 7f3f3f→b2 665436 | 5f7f00→6e 6b6b00 | 3f3f7f→3d 40407f | 205f00→76 2f4c17 | 003f00→35 004000 | 674d00→77 634a00 | 354e18→76 | 7f577f→21 7f407f | 4c4c4c→c1 404146 | 191919→e5 101010 |
| 7 | 3f3f3f→9e 333333 | 3f1f1f→d2 291818 | 2f3f00→7a 332800 | 1f1f3f→dd 181b21 | 102f00→7b 211900 | 001f00→ed 081008 | 332600→7a | 1a270c→7b | 3f2b3f→cb 31292a | 262626→d7 212121 | 0c0c0c→60 000000 |
| 8 | ffffff→00 | ffbfbf→8e eaeaa9 | ffff00→02 | bfbfff→98 cccccc | 60ff00→27 40ff00 | 00bf00→2e 00bf00 | ffe900→85 ffdf00 | a1ea48→10 bfbf40 | ffffff→00 | e6e6e6→97 | 4c4c4c→c1 |
| 9 | ffffff→00 | ffffff→00 | ffff00→02 | ffffff→00 | a0ff00→0e bfff00 | 00ff00→4e | ffff00→02 | ffff78→01 ffff7f | ffffff→00 | ffffff→00 | 808080→9b 808080 |
| 0xa | (r, ff, r) | (r, aa, r) | (r, 95, r) | (r, aa, r) | (r, 55, r) | (r, 2a, r) | (r, 79, r) | (r, 68, r) | (r, e4, r) | (r, 99, r) | (r, 33, r) |
| 0xb | ffffff→00 | aaaaaa→99 b3b3b3 | 959595→9a 999999 | aaaaaa→99 | 555555→b9 4f5157 | 2a2a2a→d7 212121 | 797979→b0 | 686868→9c 666666 | e4e4e4→97 | 999999→9a | 333333→9e |
| 0xc | ffff00→02 ffff00 | ffaa00→86 ff9f00 | ff9500→86 | ffaa00→86 | ff5500→87 ff3f00 | ff2a00→87 | ff7900→09 ff7f00 | ff6800→09 | ffe400→85 ffdf00 | ff9900→86 | ff3300→87 |
| 0xd | ffffff→00 | ffbfbf→8e eaeaa9 | bfff7f→0f bfbf7f | 7fbfff→1a 7fbfff | 40df7f→26 40ff80 | 00bf7f→2d 00bf55 | cfcd7f→0f | 6bce98→7e 71aea7 | ffd7ff→00 | 99cccc→7c 93ddd5 | 339999→38 407f7f |
| 0xe | bf5f00→18 bf4000 | 7f3f00→6a 812200 | 6f3700→78 563d00 | 7f3f00→6a | 3f1f00→6d 2e0c00 | 1f0f00→ef 070002 | 5a2d00→6b 651b00 | 4e2700→6c 4a1300 | ab5500→ad a15500 | 733900→6a | 261300→7b 211900 |
| 0xf | →8d 540353 | →89 fe0bfa | →8a d409d0 | →89 | →8c 7f057d | →8d | →8b a907a7 | →8b | →8d | →8a | →8d |
| 0x16 | bfbfbf→99 b3b3b3 | bf5f5f→17 bf4040 | 8fbf00→11 bfbf00 | 5f5fbf→3c 4040bf | 308f00→74 476c21 | 005f00→f7 005200 | 9b7400→65 9a7400 | 507524→73 537c26 | bf82be→13 bf7fbf | 737373→b0 | 262626→d7 |
| 0x17 | →2a 40bf00 | →71 6b9c30 | →72 5f8c2b | →71 | →76 2f4c17 | →ff 000000 | →74 476c21 | →75 3b5c1c | →2a | →72 | →ff |
| 0x18 | →7c 93ddd5 | →7c | →7d 82c6be | →7c | →81 3c6762 | →83 193834 | →7e 71aea7 | →7f 5f9690 | →7c | →7c | →83 |

Tables 0x10..0x15 on the selected indices (all other indices unchanged):

| k | 24 `7f0040` | 3b `4040ff` | 3f `404000` | 40 `4000ff` | 4e `00ff00` | 71 `6b9c30` | 72 `5f8c2b` | 73 `537c26` | 74 `476c21` | 75 `3b5c1c` | 76 `2f4c17` |
|---|---|---|---|---|---|---|---|---|---|---|---|
| 0x10 gold | 6c4c00→77 634a00 | d99900→a3 e69900 | 483300→79 453500 | b58000→a6 c08600 | 916600→66 8d6a00 | b07c00→a7 b77400 | 9e6f00→66 | 8b6200→66 | 785500→68 735600 | 654700→77 | 533a00→78 563d00 |
| 0x11 cyan | 00516c→f8 004e6a | 00f2d9→25 40ffff | 001c48→4a 000049 | 00bcb5→2c 00bfaa | 008791→ea 09849a | 00b6b0→2c | 009a9e→ea | 007e8b→f1 00778d | 006378→f5 005c73 | 004765→fc 004264 | 002c53→84 11114c |
| 0x12 teal | →82 2b4f4b | →7e 71aea7 | →83 193834 | →7f 5f9690 | →81 3c6762 | →7f | →80 4e7f79 | →81 | →82 | →82 | →83 |
| 0x13 magenta | →8d 540353 | →88 ffaefe | →a0 (level) | →8a d409d0 | →8b a907a7 | →8a | →8b | →8b | →8c 7f057d | →8d | →8d |
| 0x14 brown | →7b 211900 | →67 806000 | →7b | →78 563d00 | →79 453500 | →78 | →79 | →79 | →7a 332800 | →7b | →7b |
| 0x15 grey | →9d 4c4c4c | →98 cccccc | →9f 191919 | →9a 999999 | →9b 808080 | →9a | →9b | →9c 666666 | →9d | →9d | →9e 333333 |

(The 0x10/0x11 requested colours for these indices stay below 0x10000, so the missing clamp of
table 0x10 does not bite on them; it would for lum > 0x9696.) Generator: the arithmetic above, run
in Python on `clut 202` from `Ferazel's Wand Backgrounds.rsrc` (scratchpad model, not committed).

## 4. Water tables — modes 6/9, `_DAT_100a0170 + w·0x100` (global `101e1fc2`)  [HIGH]
`.BuildWaterTintTable @ 100203dc`, entries **0..0xff** (`cmpwi r0,0xff; ble` at `100204bc`,
`10020698`, `10020778`, `10020848`, `10020a08`) ⚑ corrected (review 2c, 2026-10-04) #1. w = liquid kind (`+0x128`): 0 water, 1 acid,
2 lava, 3 healing brine, 5 quicksand (physics §5).

| w | rule (per channel, then `Color2Index`) | raw |
|---|---|---|
| 0 | (R>>1, G>>1, min(2·lum, 0xffff)) (= tint 4) | `100203f0..100204b8` |
| 1 | L = lum; t = (2·⌊L·0x5f00/0xffff⌋, 2·⌊L·0x8d00/0xffff⌋, 2·⌊L·0x2c00/0xffff⌋) each ≤ 0xffff; out = trunc(0.15·c + 0.85·t) | `100204c0..10020694` (`100a1708`, `100a1700`) |
| 2 | (trunc(0.7·min(2·lum, 0xffff)), G>>2, B>>3) | `10020698..10020774` (`100a16f8`) |
| 3 | v = min(min(2·lum, 0xffff) + 4000, 0xffff): (v, G>>2, v) | `1002077c..10020844` (`addi 0xfa0`) |
| 4 | **never written** | — |
| 5 | (trunc(0.25·R)+29998.08, trunc(0.25·G)+24760.32, trunc(0.25·B)+10475.52) truncated, clamped 0..0xffff | `1002084c..10020a04` (`100a16f0/16e8/16e0/16d8`) |

⚑ corrected (review 2c, 2026-10-04) #1: ~~entry 0xff of every water table … turns white~~ — every
water loop is `ble`, so entry 0xff **is** written like the others: `clut[0xff]` = 000000, so table 0
maps 0xff → **0x60 black** (lowest of the duplicate blacks, NR 2); a black sprite pixel stays black
under water tint 0 [HIGH]. Only **table 4 is never written**: the globals lie in the zero-filled part
of the data section (offset 0x142782 > initialised 0x8169, INDEX provenance), so all of table 4 maps
to index 0 (white). Kind 4 does not occur in the shipped maps
(physics §5 census) [HIGH by reference].

Computed, CLUT 202 (requested → idx RGB) [requested HIGH; chosen LOW]:

| w | 00 `ffffff` | 06 `ff7f7f` | 0e `bfff00` | 1d `7f7fff` | 31 `007f00` | 61 `cf9b00` | 71 `6b9c30` | 88 `ffaefe` | 9a `999999` | 9e `333333` |
|---|---|---|---|---|---|---|---|---|---|---|
| 0 | 7f7fff→1d 7f7fff | 7f3fff→20 7f40ff | 5f7fff→36 407fff | 3f3fff→3b 4040ff | 003f54→fd 003e61 | 674df2→20 | 354ed0→3c 4040bf | 7f57ff→20 | 4c4cff→3b | 191966→49 00006d (4-bit) / **84** 11114c (exact, §1.2) |
| 1 | c7ff71→01 ffff7f | 91b244→10 bfbf40 | 7ab22b→71 6b9c30 | 7eb258→71 | 1a3a0c→35 004000 | 6b8823→72 5f8c2b | 517825→73 537c26 | b6ef68→0f bfbf7f | 77a643→71 | 273716→cd 2d2d1c |
| 2 | b33f1f→18 bf4000 | b31f0f→a8 b50e00 | b33f00→18 | b31f1f→a8 | 3b1f00→6d 2e0c00 | a92600→69 9c2900 | 912706→69 | b32b1f→a8 | b32613→a8 | 470c06→44 400000 |
| 3 | ff3fff→89 fe0bfa | ff1fff→89 | ff3fff→89 | ff1fff→89 | 641f64→8d 540353 | ff26ff→89 | df27df→8a d409d0 | ff2bff→89 | ff26ff→89 | 760c76→8c 7f057d |
| 5 | b5a068→0f bfbf7f | b58048→15 bf7f40 | a5a028→10 bfbf40 | 958068→9b 808080 | 758028→72 5f8c2b | a98728→63 b58700 | 908734→1e 7f7f40 | b58c68→14 bf7f7f | 9b874f→1e | 816d35→1e |

The tile path uses the same tables: FG/overlay tiles in water with `hdr+0x26c6` set (level 11) are
drawn mode 9 with `w` (sprites §3.1), and `.BlitEncFaceTileBlendSpecial` passes its blend result
through table `w` (§8) [HIGH].

## 5. Hurt-flash tables — `.BuildReddenTable @ 1001ff1c`  [HIGH]
Source: working copy (`1001ff34 lwz −0x79ac`). Divisions are `srawi; addze` (toward zero; all
operands ≥ 0 here).
```
A (mode 3), _DAT_100a0178 + n·0x100, n = 0..7, all 256 entries:      (1001ff50..10020040)
  L2 = (2·lum) & 0xfffe            // rlwinm 1,0x10,0x1e at 1001ffac: bit 16 dropped → wraps for lum ≥ 0x8000
  R = ((n+1)·L2 >> 3) + ((7−n)·R >> 3);  G = (7−n)·G >> 3;  B = (7−n)·B >> 3
  entry 0xff forced to 0xff                                         (10020008..10020014)
B (mode 4), _DAT_100a0174 + n·0x100, n = 0..15, all 256 entries:     (10020058..1002015c)
  s = lum + 0xffff;  k = (n+1)·((s>>1) & 0xffff) >> 4
  R = k + ((15−n)·R >> 4);  G = k + ((15−n)·G >> 4);  B = ((n+1)·(s>>2) >> 4) + ((15−n)·B >> 4)
```
So A blends toward red `2·lum` with weight (n+1)/8 — bright colours (lum ≥ 0x8000) wrap to a dark
red; B blends toward pale yellow ((lum+0xffff)/2, same, (lum+0xffff)/4) with weight (n+1)/16.
Mode 3 uses n = hurt counter (0..7), mode 4 uses 2n (0..14), §2.2. Computed (CLUT 202):

| table | 00 `ffffff` | 06 `ff7f7f` | 0e `bfff00` | 1d `7f7fff` | 31 `007f00` | 61 `cf9b00` | 71 `6b9c30` | 88 `ffaefe` | 9a `999999` | 9e `333333` |
|---|---|---|---|---|---|---|---|---|---|---|
| A0 | ffdfdf→97 e6e6e6 | ea6f6f→06 | addf00→11 bfbf00 | 7a6fdf→1d | 0a6f00→f3 006d00 | d48800→a3 e69900 | 78892a→72 | f898de→88 | 8c8686→9b | 392c2c→cc 312921 |
| A3 | ff7f7f→06 ff7f7f | aa3f3f→17 bf4040 | 757f00→1f 7f7f00 | 6a3f7f→21 7f407f | 2a3f00→7a 332800 | e14d00→87 ff3f00 | 9d4e18→af 8f3d00 | e3577f→0a ff407f | 664c4c→b4 605044 | 4c1919→6c 4a1300 |
| A7 | ff0000→4c da0000 | 540000→44 400000 | 2a0000→6d 2e0c00 | 540000→44 | 540000→44 | f20000→4c | d00000→4c | c80000→4c | 330000→44 | 660000→6b 651b00 |
| B0 | fffff7→00 | fd847e→06 | c0fc06→0e | 8484f6→1d | 098004→31 | ce9d05→61 | 6f9e32→71 | feb2f5→88 | 9c9c96→9a | 393934→9e |
| B6 | ffffc7→97 e6e6e6 | eda476→03 ffbf7f | c4e82c→0e | a4a4be→99 b3b3b3 | 418920→73 537c26 | c7aa29→61 | 8ba642→71 | f9ccc3→97 | b0b083→0f bfbf7f | 60603e→b2 665436 |
| B14 | ffff87→01 ffff7f | d7cf6b→0f bfbf7f | c9cd5e→10 bfbf40 | cfcf73→0f | 8b9345→1e 7f7f40 | bdba58→10 | afb257→10 | f2ed81→01 | c9c969→0f | 93934b→1e |

(A7 on white: 2·0xffff & 0xfffe = 0xfffe → red ff; on 06 `ff7f7f` lum 0xaaaa → 0x15554 & 0xfffe =
0x5554 → dark red 540000: the wrap is visible in the table above.)

## 6. Two-colour tables, translucency (mode 0xb) and the rest of `.BuildTintTable`

### 6.1 Pair tables `T[src·0x100 + dst]` (256×256, row = sprite pixel, column = screen pixel)
| global (TOC) | rule (each channel, then `Color2Index`) | raw | label |
|---|---|---|---|
| `_DAT_100a0160` (−0x76e0) | min(src+dst, 0xffff) — additive | `10020b94..10020c80` | HIGH |
| `_DAT_100a015c` (−0x76e4) | (src+dst)>>1 | `10020c88..10020d54` | HIGH |
| `_DAT_100a0158` (−0x76e8) | src>>1 + src>>2 + dst>>2 (¾ src) | `10020d5c..10020e48` | HIGH |
| `_DAT_100a0154` (−0x76ec) | src>>2 + dst>>1 + dst>>2 (¼ src) | `10020e54..10020f40` | HIGH |
| `_DAT_100a0150` (−0x76f0) | (dst + lum(src))>>1 — dst averaged with src's grey | `10020f4c..10021030` | MED |
| `_DAT_100a014c` (−0x76f4) | L = lum(src), w = max(L,1): ⌊(L/2+32000)·w/0xffff⌋ + ⌊dst·(0xffff−w)/0xffff⌋ — "glow" | `1002103c..1002119c` (`addi 0x7d00`) | MED |
| `_DAT_100a0144` (−0x76fc), 16×16×256 | `[a·0x1000 + b·0x100 + i]`: w = max(a·0x1000,1): clamp(⌊b·0x1000·w/0xffff⌋ + ⌊c_i·(0xffff−w)/0xffff⌋) — pixel i pulled toward grey level b by a/16 | `10021250..100213d8` | MED |
| `_DAT_100a0148` (−0x76f8), 255 B | brightness level of index i: clamp(lum/3072 − 2, 0, 15) (`mulhw 0x2aaaaaab; srawi 9`) | `100211a8..10021248` | HIGH |

`.BlitEncFaceTransClip @ 10027d04` (mode 0xb; also `…TransFlipClip`, `…TransRippleClip` for 0xd)
picks the table by arg (`10027d3c..10027df8`) [HIGH]: **0 → avg, 1 → ¾ sprite, 2 → ¼ sprite,
3 → `0150`, 4 → glow `014c`, 5 → additive `0160`, anything else → `0144 + (arg−0x80)<<12`**; for
arg ≥ 0x80 the sprite pixel is first replaced by its brightness level (`_DAT_100a0148`), giving
"screen pulled toward grey(level·0x1000) by (arg−0x80)/16". Per pixel `out = T[src·0x100 + d]`, where
d = the screen pixel, or — where the second buffer holds 0xff (no FG there) — the parallax row
contents from `.CalcPxRowContents` [MED, decompile l. 23415–23456]. The shipped stores are
0xb0000/1/2 (trails, blinks), 0xb0004 and 0xb0005 (census §2.1), i.e. 50 %, 75 %, 25 %, glow,
additive. Particles use `0130`, `0154/0158/015c` (`.DrawParticles @ 10031aa4`, TOC loads) [HIGH loads].

### 6.2 Other outputs of the builders
- `0x100a39b6`, 512 B filled with 0x0d (`10020a78..10020b0c`; Ghidra labels it inside the "Light
  overflow!" string); also `stb 0xd` by the Trans blitters (`10027d74`) and `.CalcPxRowContents`
  (`10027ab4`) [HIGH]; meaning NOT RESOLVED 5.
- cos/sin tables, 360 doubles each, `cos(i°)` → `_DAT_100a0168` global `101e6908`, `sin(i°)` →
  `_DAT_100a0164` (`10020b10..10020b8c`, π `100a16c8`, 2.0 `100a16c0`, 360 `100a16b8`) — rotation
  blitters and `.HitPlayerSprite` [HIGH].
- **Built but never read** (only TOC load of each slot is its builder; `tocrefs.py` plus a scan of
  every TOC word for pointers into `101e0000..101e9000`): `_DAT_100a0138` (11 tables
  c + k·2500, `10022a44..10022b14`), `_DAT_100a013c` (256 doubled-identity shorts), `_DAT_100a017c`
  (`.BuildTranslucTable`: 16 tables, grey of c + k·0x800), `_DAT_100a0180`
  (`.BuildPosterizationTable`: lum>>12 clamped 15, from the *level* CLUT) [HIGH for "no reader"].

## 7. Lighting

### 7.1 Darkness source  [HIGH]
Per-cell darkness **D = BG-map cell high byte − 1** (`.GetLightTile @ 1003c2b4`). `.GetAmbDarkVal
@ 1001aaf8` returns 0 unless `hdr+0x2706 ≠ 0`, else `GetLightTile(x>>5, y>>5)`. So `hdr+0x2706` is an
**enable**, not the darkness value. Census (Python, BG maps): levels 1, 2, 3, 4, 10, 21, 22 carry
bytes 1..12/14/15/16 (D 0..15) with `0x2706` = 5,1,1,5,1,2,2; level 31 has `0x2706` = 1 and all bytes
1 (D 0, no effect); levels 5, 11, 15, 40, 50, 51, 55, 62 all 1; 18, 20, 25, 45, 52, 67, 70 all 0;
level 30 = 1 ×14400 and **255 ×1600** (only reachable through the sprite path, §2.2).

### 7.2 `.CalcAmbientDarken(c, L, D) @ 1001ab74`  [HIGH, `1001ab74..1001ac9c`]
Single precision (`fsubs/fdivs/fmuls`), constants 1.0f `100a1670`, 10.0f `100a1674`, 0.0625f `100a1678`:
```
if D == 0: return c unchanged
f = 1 − (L+1)/10;  s = D/16
each channel: c = (uint16) trunc(c − f·(c·s))     // fctiwz then sth: stored mod 0x10000
```
L = 9 removes the darkening; **L = 10 gives f = −0.1, a brightening by D/160 that wraps** for
channels above 65535/(1+D/160) (e.g. white at D = 15 → 0x17fe = 171717).

### 7.3 Tables  [HIGH, `1001acc4..1001bbb0`]
- Ambient `_DAT_100a0130` (global `10169d6c`): `[D·0x100 + i] = Color2Index(darken(c_i, 0, D))`,
  D = 0..15, from the level+base CLUT (`1001ad04 lwz −0x78b4`). Per step D the colour scales by
  (1 − 0.9·D/16): white → f1f1f1 (D 1), b7b7b7 (5), 6f6f6f (10), 272727 (15).
- Light `_DAT_100a0134` (global `100fbd6c`, 16 × 0x6e00 B): `[D·0x6e00 + t·0x100 + i]`, t = 0..109 =
  `g·11 + k` (colour group g 0..9, intensity k 0..10). With d = `darken(c_i, k, D)`:

| g (t) | AddLight colour | rule on d (int adds clamp at 0xffff unless noted) | constants (raw) |
|---|---|---|---|
| 0 (0x00) | 0 | + 1900·k each | `addi 0x76c` `1001ae88` |
| 1 (0x0b) | — | ·(1 − 0.09k), ≤ 0 → 0 | `100a1650` `1001aef8 fnmsub` |
| 2 (0x16) | 0x16 | R + 2200k, G + 1100k | `mulli 0x898/0x44c` `1001b070` |
| 3 (0x21) | 0x21 | R + 500k, G + 1000k, B + 3000k | `mulli 0x1f4/0x3e8/0xbb8` `1001b1bc` |
| 4 (0x2c) | 0x2c | R + 3000k, G − 300k, B − 300k (≥ 0) | `mulli 0xbb8/0x12c` `1001b2d4` |
| 5 (0x37) | 0x37 | R·(1+0.025k) + 1250k, G·(1+0.05k) + 2500k, B·(1+0.01k), clamp 0..0xffff | `fmadd` `1001b454..1001b45c`, `mulli 0x4e2/0x9c4` |
| 6 (0x42) | 0x42 | R + 1500k; **G + 1500k only clamped ≥ 0 → wraps** (`1001b690 cmpwi 0; ble`); B − 300k ≥ 0 | `mulli 0x5dc/0x12c` `1001b614` |
| 7 (0x4d) | 0x4d | R·(1+0.05k) + 2000k, G·(1+0.025k), B·(1+0.1k) + 4000k | `mulli 0x7d0/0xfa0` `1001b750` |
| 8 (0x58) | — | d only (darkness reduced by k) | `1001b938` |
| 9 (0x63) | 99 | ·(1 + 0.1k), clamp | `1001b9e0..1001ba2c` |

Requested colours (D = 0 / 5 / 15) for white `ffffff`, k = 0, 5, 10, group order 0..9:
D 0: ffffff ffffff ffffff · ffffff 8c8c8c 191919 · ffffff×3 · ffffff×3 · ffffff fffafa fff4f4 · ffffff×3 ·
ffffff ff1dfa ff3af4 (group 6: G wraps) · ffffff×3 · ffffff×3 · ffffff×3.
D 5: k 0 = b7b7b7 in every group; group 0 k 5 ffffff, **k 10 525252** (wrap at L = 10, then +19000);
group 3 k 10 1b2f7d; group 9 k 10 0f0f0f [HIGH arithmetic]. So the core (k = 10) of every light turns
near-white pixels dark wherever D ≥ 1; with D = 0 the darken step is skipped and nothing wraps.

### 7.4 Lights  [HIGH unless marked]
200 slots × 0x30 at `_DAT_100a0128` (`.AddLight @ 1001bc08` … `.RemoveAllLights @ 1001bf18`):
+0 active, +1 new, +2 remove-pending, +4 face, +8 previous face, +0xc/+0xe y/x (Point), +0x10/+0x12
previous, +0x14 radius = face width/2 (`face+0x50 >> 1`), +0x18 colour (= g·11, table above), +0x1c/+0x20
x/y ·256, +0x24/+0x28 vx/vy, +0x2c y-acceleration (`.HandleLights @ 1001bff0` integrates; a
removed slot clears on the next pass). `.ChangeLightColor` sets +0x18 (shots: 0x42 on hit, 0x4d/0x21/0x42
on kill, 0 when cannoned) [MED names of the calling contexts].
Light faces: `.Load1LightFaceFromPICT @ 1002ff1c` = `.Load1PlainFaceFromPICT` with conversion CLUT
801. The light PICTs (Sprites 801, 802, 806, 810–814, 820, 821, 830, …) are authored in the System
palette's grey ramp: pixels are 0 (white = no light) or **0xf5..0xff** (eeeeee … 000000), black most
frequent at the core (Python PICT decode: PICT 801 has 12206 px of 0xff, 9551 of 0) [HIGH data].

Per-pixel compositing (`.BlitLightOverFaceClip @ 1001d8e8`, raw `1001db64..1001db90`):
```
p = light-face pixel under this screen pixel
p == 0 or outside the face: out = Ambient[D][dst]                    // _DAT_100a0130 + D·0x100
else:                      out = Light[D][p + colour − 0xf5][dst]    // intensity k = p − 0xf5 (0..10)
```
`.BlitAfterLightOverFaceClip` (2nd and later lights on the same face) uses the D = 0 slab and treats
p == 0 as 0xf5 (k 0) (decompile l. 210–212) [MED]. `.DrawLightOverFace @ 1001cf38` (sprites, via
`.WrapLightFace`; gated by `+0x88`, physics §0.1) walks the 200 slots, applies the first light whose
face rect meets the sprite with the "first" blitter and the rest with "after"; if none and
`hdr+0x2706 > 0`, `.BlitAmbDarkenOverFace*` (ambient only). A partly submerged sprite is split at
`+0x11c` and the lower part blitted with the ripple flag [MED]. Tiles: `.DrawLightsOntoTiles @
1001c8e4` = clear op grid, `.CalcLightOps` (lights whose old or new rect changed → per-tile op lists,
20×13 grid of 0x54-byte cells, `.AddLightOp @ 1001c2c0`), `.DrawLightOps` (redraw BG, FG, overlay of
each marked tile, then `.DrawLightOp*Tile` → `.DrawLightOpOverTile @ 1001cc70` with the same
first/after blitters and an ambient fallback) [MED].

### 7.5 Fake light for sprites `.GetFakeLight @ 1001d708`  [HIGH]
First active light (slot order) whose radius `+0x14 > 32` and whose face rect contains the sprite's
centre: `v = 11 − (PEDistance(dx,dy)·11)/radius` (`1001d864..1001d86c`), accepted if 0 ≤ v ≤ 11
(`1001d874..1001d880`), result `v + colour`. **v = 11 (distance < radius/11) indexes the next
group's k = 0 entry** (for colour 0: the g 1 "×1.0" table, i.e. no light at the very centre).
⚑ corrected (review 2c, 2026-10-04) #3: colour **99** (`li r8,0x63` at `1005dea4`, `1005e50c`,
`1005e5b4`) with v = 11 gives t = 110 = 0x6e00/0x100, i.e. the **next D slab's** t = 0 (group 0,
k 0 = `darken(c, 0, D+1)`, the ambient look of D+1); at D = 15 that is slab 16 = `0x100fbd6c +
0x6e000` = `0x10169d6c`, the start of the ambient table `_DAT_100a0130` (its D = 0 slab) — defined
memory, not undefined [HIGH arithmetic]. The
bounding pre-test compares |c − light.x| with `light.x + radius + w/2` (adds the light's own
coordinate) and so almost never rejects [MED].

## 8. FG blend faces  [HIGH]
`.ProcessFGBlendTileFaces @ 10001400` runs `.ProcessFGBlendTileFace @ 1002a6b0` on each of the 96
faces of PICT 185, rewriting copy-run pixels to weights (`1002a71c..1002a77c`): 0, 0x97, 0x98 → 3;
0x99..0x9b → 2; 0x9c..0x9e → 1; everything else (1..0x96, ≥ 0x9f) → 0. Skip runs stay transparent.
`.BlitEncFaceTileBlend @ 1002a810` (raw `1002a8cc..1002a944`), d = screen pixel (FG/BG already drawn),
p = pattern-tile pixel (plain face `DAT_100a5004[pattern]`, same row/column):

| weight | out | table |
|---|---|---|
| skip | d | — |
| 0 | p | — |
| 1 | ¼ d + ¾ p | `_DAT_100a0154[d·0x100 + p]` |
| 2 | ½ d + ½ p | `_DAT_100a015c` |
| 3 | ¾ d + ¼ p | `_DAT_100a0158` |

In CLUT 200 the weight colours are white/e6e6e6/cccccc (3), b3b3b3/999999/808080 (2),
666666/4c4c4c/333333 (1): the blend artwork is a grey mask, light = keep the tile. Mode `0x14<<16 |
pattern` (dry) → this blitter; `(0x15+w)<<16` (water kind w) with `hdr+0x26c6 ≠ 0` →
`.BlitEncFaceTileBlendSpecial @ 1002aa00`, identical then remapped through water table w; with
`0x26c6 == 0` the dry blitter is used (`.BlitEncFaceX`, main l. 24986–24993).

## 9. Flame layer and cooling map  [HIGH unless marked]
State (0x2c B, `.FlameCreate(f, rect 640×100, min 0xce, max 0xfe) @ 10085300`): rect, frame counter
+8, rowBytes +0xc, min +0xe, max +0x10, buffers A +0x20 / B +0x24, cooling map +0x28; pixmaps are
**101** rows. Create fills row 100 of A and B with `max − Random()%8` (0xf7..0xfe, never rewritten
later — the permanent hot source) and randomises the cooling buffer (4×4 blocks of `Random()%16`),
which `.LoadCoolingMap @ 10000924` then overwrites with PICT 198 drawn through `clut 198`: indices
0..16 = white → black grey ramp (`clut 198` entries 0x11..0xff are 05ff05 filler) [HIGH data].
`.FlameUpdate(f, rise)` calls `.FlameUp(src = B, dst = A, cool, frame, rowBytes, 100, min, rise)`
then swaps A/B; `.FlameUp @ 100857e0`:
```
dec[v] = (frame % (v+1) == 0) ? 1 : 0                   for v = 0..255
clampT[t] = min if t < min + 0x100 else t & 0xff        (rebuilt when min changes; global 100a12b0)
off = rise·rowBytes;  coolRow0 = rise·rowBytes·(frame % 100)   (rise 0: map fixed; 1: map scrolls up, wraps)
for each byte position q of rows 0..(100−rise−1):
  s = src[q+off−1] + src[q+off+1] + src[q+off−rowBytes] + src[q+off+rowBytes]
  dst[q] = clampT[(s >> 2) − dec[cool[(coolRow0 + q) mod (100·rowBytes)]] + 0x100]
```
i.e. 4-neighbour average of the row below (rise = 1, fire climbs one row per update) or of the
same row (rise = 0), minus 1 every (v+1)-th frame where v is the cooling-map grey (white cools every
frame, black every 17th), floored at 0xce [HIGH logic; MED for the exact wrap of the cooling pointer,
`10085c00..` second loop]. Feeding: `.FlameAddLine(f, row) @ 10085560` writes runs of 1..15 px
(length `Random() & 0xf`) with start value `min + 2(max−min)/3 + Random() % ((max−min)/3)`
incremented per pixel up to max, and value − 1 on the row above; `.FlameAddSpark(f, x, y, v)` sets one
pixel and (y ≠ top, v > min) v − 1 above. Per frame (`.PaintFrameWrap` l. 9232–9247): `hdr+0x2722 = 1`
(level 52): AddLine(bottom−1), Spark(FastRand(640), FastRand(96), 0xfe), Update(rise 1); `= 2`
(level 55): AddLine(bottom−3), Update(1), Update(0). `.SetupLevel` pre-runs 60 (mode 1) or 59
(mode 2) AddLine+Update(1) pairs [MED: loop start value read in the decompile only]. Enemy shots add sparks `0xe6 + …` (`.HandleEnemyShotSprite`).
Values 0xce..0xfe are indices into CLUT 222 'Upper Fire Caverns flame + base' (both levels use it).
Display: `.DoubleBlitPPCParallaxOneLayerFire @ 10018dd4` copies flame pixels wherever the second
buffer byte is 0xff (no FG) and the normal layer elsewhere; mode ≠ 2 offsets each row by the 70-entry
sine table `_DAT_100a00c4` [MED].

## 10. Gamma fades and screen tint
All go through the bundled Monitor Tool; `MT_FadeToColor(dev, color, pct, ms, linear) @ 10093304`
clones the **current** gamma, targets the saved original (color = nil) or `ColorGamma(color)`, and
blends `cur = start + f·(target − start)` with f = pct·elapsed/ms (linear flag: f%; every game call
passes linear = 1); ms = 0 → one immediate step [MED: library internals from the decompile].
Consequence: repeated zero-duration calls **compound** (each starts from the current gamma).

| routine | arithmetic (raw) | effective curve / duration |
|---|---|---|
| `.GammaFadeIn(n) @ 10035444` | k = 0, s, 2s … ≤ 100 with s = max(100/(3n), 1); each tick `FadeToColor(nil, min(k·3n/100,100), 0, 1)`, waits one `TickCount`; then 100 % (`10035450..10035538`) | ⌊100/s⌋+1 ticks, compounding; brightness before the final snap: n 3 → 31 % (10 ticks), 6 → 85 % (21), 8 → 96 % (26), 15/20/35 → 100 % (51/101/101) |
| `.GammaFadeInSlow(n) @ 10035584` | one timed call, ms = max(33n, 100), then 100 % (`100355c8..10035610`) | linear; n = 0x37 (ChapterScreen) → 1815 ms |
| `.GammaFadeOut(n, rgb) @ 10035310` | `MT_FadeCustom(0, 100, ms, .TintFadeProc, 3)`, ms = trunc(0.7·55·trunc(2.3·n)) (`100a1940`, `100a1938`, `mulli 0x37`); stores rgb for the async fade (`100353e4..10035404`) | n 3 → 230 ms, 6 → 500, 10 → 885, 12 → 1039, 30 → 2656 |
| `.TintFadeProc @ 10034f40` (handlers dump) | per gamma colour entry, t = pct/100: mode 3 B·(1−t), G·max(1−1.35t, 0), R·max(1−2.5t, 0); modes 0/1/2 keep R/G/B ·(1−t) and the other two ·max(1−2t, 0) (`10034fd8..10035268`, `100a1960`, `100a1958`, `100a1970`) | fade-out goes red-first, then green, blue last |
| `.GammaFadeOutAsync(N, rgb) @ 100356c0` / `.GammaFadeInAsync(N) @ 1003565c` + `.HandleAsyncGammaFade @ 10035788` (per frame) | frame j = 0..N: `FadeToColor(rgb or nil, j·100/N, 0, 1)`; after j = N the end state is set (`100357d8..100358cc`) | N+1 frames, compounding: N = 40 → 31 % at frame 5, 77 % at 10, 97 % at 15 |
| `.FinalGammaFadeIn @ 10035918` | `FadeToColor(nil, 100, 0, 1)` | instant |
| `.TintScreen(rgb, pct) @ 10034e88` | `FadeToColor(rgb·65536 or nil, pct, 1 ms, 1)`; nil → 100 % back to normal | liquid tint below |

Liquid screen tint (`.HandlePlayerSprite`, handlers l. 2704–2730) [MED]: while 1 ≤ `+0x11c` ≤ 9,
`TintScreen(colour, 15)` with kind 0 → (0,0,64000), 1 → (0,64000,0), 2 → (64000,0,0), other kinds →
black; cleared with `TintScreen(nil)` when `+0x11c` is 0 or > 10.

## NOT RESOLVED
1. **Exact index chosen by `Color2Index`.** The inverse-table resolution (`MakeITable(c, nil, 0)` →
   device preference) and the nearest rule are ROM code. Tried: res-4, res-5 and exact-nearest
   models (agreement figures §1.2); every "→idx" cell is LOW. The requested RGB values are exact.
   The bank's single model and label live in particles §4.3 ⚑ corrected (review 2c, 2026-10-04) #4.
2. Ties between duplicate CLUT colours (00ff00 at 0x4e..0x5f and 0x8f..0x96; three blacks 0x60,
   0xa0 (202), 0xff): the model takes the lowest index; QuickDraw's choice is not in the binary.
3. What a `+0x89` sprite looks like when D = −1 (mode 0xb, arg 0xff00+F → table pointer
   `_DAT_100a0144 + (arg−0x80)·0x1000`, negative) or D = 254 (level 30): for unrotated faces the
   Trans blitter reads ~1.5 MB before the table; for rotated faces (`.BlitEncFaceRot`) the mode is
   outside its switch and the table register is uninitialised. Arithmetic HIGH; the pixels are
   undefined memory — not determinable from code (CLOSED AS UNDETERMINABLE for the colours).
4. ~~Whether any sprite face contains index 0xff (turns white under water tint, §4). Not checked:
   needs a census of every converted face, beyond this lane.~~ Moot: entry 0xff of the water tables
   is written (all five loops `ble`, `100204bc`, `10020698`, `10020778`, `10020848`, `10020a08`); table
   0 maps it to 0x60 black (§4) ⚑ corrected (review 2c, 2026-10-04) #1.
5. The 512-byte 0x0d fill at `0x100a39b6` (§6.2): readers are `.CalcPxRowContents` and the Trans
   blitters; its meaning (a row-cache tag?) was not traced.
6. `PEDistance @ 10047648` metric (used by the fake-light falloff) — not read. Tried: only its call
   site in `.GetFakeLight` (`1001d864..1001d86c`). ⚑ corrected (review 2c, 2026-10-04) #5
7. Flag at TOC −0x7b10 that suppresses `.AnimateCLUT` when Effects = 1 — not identified. Tried: its
   test inside `.AnimateCLUT` (§1.5) only. ⚑ corrected (review 2c, 2026-10-04) #5
8. Monitor Tool gamma-ramp integer details (8- vs 16-bit device ramps, rounding of decreases) —
   library code, read only at decompile level. Tried: the decompile of `MT_FadeToColor` (§10).
   ⚑ corrected (review 2c, 2026-10-04) #5
9. ~~Mode 0xa (`.HandlePlatformSprite` child `+0x1d8`, arg = distance·256/45 clamped 11..250; 0 below
   11): … `.BlitEncFaceSpecialClipX` has no case 10 … not determinable from code.~~ → closed:
   ClipX has explicit `sVar9 == 10` arms (`100275d4 cmpwi r25,0xa`; `li r6,0x100` `100271f0`;
   `10027614..10027630`): a vertical squash by arg/256 with pixels copied raw — draw-effects §2.6
   ⚑ corrected (review 2c, 2026-10-04) #2. (Tried before the review: both jump tables and the
   decompile of the four Special blitters; the jump-table default hid the explicit arms.)
10. `.UpdateRadiusSprites` stores mode 0xc with a computed darkness byte (main l. 35903); its range
   (whether it exceeds the 16 ambient slabs) was not evaluated. Tried: the store itself (§2.1
   census); its inputs were not bounded. ⚑ corrected (review 2c, 2026-10-04) #5

## Proposed additions to physics.md §0
| field | type | meaning | label |
|---|---|---|---|
| +0xb8 | i32 | `mode<<16 | arg`; modes with a remap table: 1 tint bank k, 3/4 hurt flash, 6/9 water kind, 0xc light (`D<<8 | t`); 0xb translucent (arg 0 ½, 1 ¾, 2 ¼, 3 grey-avg, 4 glow, 5 additive, ≥ 0x80 grey-pull); 8 behind tiles; 0xe solid colour arg&0xff; 5 diffuse; 0xd ripple-translucent; ≥ 0x14 tile blend; 0xa (platform child, arg 11..250) = vertical squash, raw copy — ⚑ corrected (review 2c, 2026-10-04) #2: defer to draw-effects §2 for the mode list (merged into physics §0.1). Modes 2, 7, 0xf..0x13 are never stored | HIGH (§2, §6.1) |
| +0x89 | u8 | sample the light map each draw: `+0xb8 = D·0x100 + 0xc0000 + fakeLight`, D = BG-cell light byte − 1 (signed; −1 turns the word into mode 0xb) | HIGH (§2.2) |

## Corrections to the existing bank
| # | file § | old | new | evidence |
|---|---|---|---|---|
| 1 | sprites-backgrounds-sounds §3.2 | "mixes the pattern tile through these weights [MED: the mixing arithmetic not read]" | weight 0 → pattern, 1 → ¼ screen + ¾ pattern, 2 → ½/½, 3 → ¾ screen + ¼ pattern, via pair tables `0154/015c/0158` [HIGH] | `1002a8cc..1002a944`; this file §8 |
| 2 | sprites §4 (Lighting bullet) | "ambient darkness hdr+0x2706"; "all index→index tables [MED … NOT RESOLVED]" | darkness = BG-cell high byte − 1, `hdr+0x2706` only enables it; algorithms transcribed (this file §3–§7); posterization yields levels 0..15 not indices, and the posterization, transluc, `0138` and `013c` tables have no reader | `1003c2b4..1003c340`; tocrefs |
| 3 | sprites §4 (`.AnimateCLUT` bullet) | "cycles a CLUT range [MED]" | sinusoidal modulation of entries `0xff−n..0xfe` by mode (§1.5); no cycling [HIGH] | `10011850..10011cb0` |
| 4 | sprites §4.1 | "[MED: per-pixel rule not transcribed]" | rule in this file §9 | `100857e0..` |
| 5 | world-data-format §3.2 row 0x2706 | "ambient darkness (0..5)" | enable flag for per-cell darkness (values 1, 2, 5 all just enable) | `.GetAmbDarkVal @ 1001aaf8`; §7.1 |
| 6 | world-data-format §3.2 row 0x2730..0x2736 | "(mode, first index, count?, period 12000)" | (mode, count n of entries before 0xff, period P frames, amplitude A = 12000) | `10011850..10011860`; §1.5 |
| 7 | physics §0 `+0xb8` row | "0xb fade/blink … 0x10..0x13 blends"; "Pixel semantics NOT RESOLVED" | 0x10..0x13 are mode-1 table numbers, not modes; mode 0xb = translucent with arg-selected pair table; pixel semantics in this file §2–§6 | §2.1 census; `10027d3c..10027df8` |
| 8 | enemies-water-cave §0.2 | "[MED: the palette in force when `.BuildTintTable` runs is assumed to be CLUT 200; table colours not rendered]" | built from the level+base working copy (indices 0..0x9f equal CLUT 200 in every level); colours rendered in this file §3.2 | §1.3, §1.4 |

## ⚑ Corrections (C4 review, 2026-10-07; Ben: follow the binary)
The text above stands; these notes override it where they differ. Transcribed in `FerazelCore.TableRequests` [HIGH].
1. **§4 water 1 — 32-bit overflow.** L·m is a 32-bit product (`10020548 mulli 0x5f00`, `1002054c mullw r7,r5,r28`
   with r28 = 0x8d00, `10020554 mulli 0x2c00`) divided by 0xffff **signed** (`mulhw` 0x80008001; `add`; `srawi 0xf`;
   add the sign bit — `10020550`, `10020558`, `1002055c`; = truncating signed division for every 32-bit operand).
   L·0x8d00 wraps negative for **L ≥ 59,494**; the `cmpw ≤ 0xffff` clamps (`10020594..100205bc`) do not fire, the
   negative t is converted signed (`xoris 0x8000`), and `fctiwz` + `sth` keep the low 16 bits. CLUT 202 w1 @00
   (white) = `c7e6 62e5 7133`, high bytes **c76271** (§4's table prints c7ff71).
2. **§6.1 glow `014c` — 32-bit overflow.** `100210e0 mullw` (L>>1 + 0x7d00)·w wraps for **lum(src) ≥ 40,932**;
   `100210ec`, `100210f0`, `10021148 mullw` dst·(0xffff−w) wrap when the product ≥ 2^31, i.e. dst ≥ ⌈2^31/(0xffff−w)⌉ —
   possible for **every lum(src) ≤ 32,766** (w ≤ 32,766; at w = 32,766 only dst = 0xffff wraps, at w = 1 every dst ≥ 0x8002).
   Each quotient is signed (`100210f4..10021160`), the sums are `sth`'d unclamped: white src → `fcfe` on every
   channel (unwrapped `fcff`); black src over white → `fffd` (unwrapped `fffe`). Note L>>1 is taken from L, not w.
3. **§6.1 grey-pull `0144` — 32-bit overflow.** `100212bc mullw r23,r5` = b·0x1000·a·0x1000 = a·b·2^24 wraps for
   **a·b ≥ 128**; `100212cc..100212d4 mullw` c·(0xffff−w) also wrap for a ≤ 7 and a large channel (a = 0 → w = 1: c ≥ 0x8002; a = 1: c ≥ 0x888a; a = 7: c ≥ 0xe390).
   The signed quotients are summed and then clamped 0..0xffff (`1002132c..10021378`), so wrapped cells clamp to 0 (or land low):
   (a, b) = (15, 15) on white → 0 (unwrapped `f0ff`); (0, 15) on white → 0 (unwrapped `fffe`).
4. **Fused multiply-adds.** Water 1 is `fmul` 0.85·t then `fmadd` 0.15·c + that (`10020620`, `1002063c`,
   `1002064c`; f28 = 0.15 @`100a1708`, f31 = 0.85 @`100a1700`). Light groups: 1 `fnmsub` m = 1 − 0.09·k
   (`1001aef8`); 5 `fmadd` multipliers (`1001b454..1001b45c`) and integer terms (`1001b4dc`, `1001b508`); 7
   multipliers (`1001b794..1001b79c`) and terms (`1001b81c`, `1001b858`); 9 multiplier (`1001ba2c`); f64 constants
   `100a1628` 0.1, `1630` 0.01, `1638` 0.05, `1640` 0.025, `1650` 0.09. A single rounding, not two.
5. **§7.3 group 1 — `frsp` before truncation.** v·m is rounded to single (`1001af78`, `1001af90`, `1001af94`),
   compared with 0, and the single is truncated (`fctiwz 1001af9c`). Over every v 0..0xffff and k 0..10 this changes
   no output against truncating the double (measured, 0 differences).

## ⚑ Phase-1 note (R2, 2026-10-09; plan R2 precondition; Ben: follow the binary)
How per-cell darkness and lights reach **tiles** — §7.4 documents only the op path; the main path is inside
`.RedrawScrollGrid`. `ghidra/ferazel/Ferazel_pef.decompiled.c` line numbers, raw addresses from `Ferazel_pef.disasm.txt`.
Transcribed in `FerazelRender.LightRenderer` + `TileGridRenderer` (R2). Every link below was raw-read: **[HIGH]**
unless marked.
1. **Per cell, inside `.RedrawScrollGrid @ 10013498`** (l. 9464–10088), each call gated `param_2 == 0 &&
   prefs+6 (Effects) ≠ 3` (`lha r0,6(r16); cmpwi r0,3; beq`, e.g. `100137ac..100137b4`), all into port `0004`:
   `.LightAnyBGTile(b, pt, 0004, 10)` right after the BG face is drawn and bool-stamped — `100137c8` (FG face
   transparent, l. 9919) / `10013c70` (no FG, l. 10002); BG not drawn (opaque FG) → no BG light. `.LightAnyFGTile(t,
   b, pt, 0004, 10) @ 10014054` after all FG/blend/water/pattern draws (`10013d64`, l. 10020) — FG face t for every
   t ≥ 0, so the pattern cell (t = 95) is lit through FG face 95's copy runs; both of its branches pass the same
   arguments. `.LightAnyFGOverlayFGTile(o2) @ 100141cc` / `…BGTile @ 10014264` after the overlay draw (`10013ec0` /
   `10013ee4`, l. 10044/10047). Each → `.WrapLightTile(face, 0004, Point(0,0), pt, 0x20, 0x20, pt, 10) @ 10016c8c`
   (the `.WrapDrawTile` cull, then **one** `.DrawLightOverTile` at the ring position — no wrapped copies; a 32-px cell
   never straddles the 640×416 ring). The `(0,0)` Points `_DAT_100a1584..15b8` are zero bytes with no TOC store.
2. **`.DrawLightOverTile @ 1001c934`** (l. 14858–14969): D = `.GetAmbDarkVal(x, y) @ 1001aaf8` (`1001c97c`) stored in
   `_DAT_100a011c`; the last argument 10 (`1001c98c cmplwi r0,0xa`) sets mode 1 and clears the "skip unchanged" flag
   (`1001c998/1001c99c`; tested `1001c9f4`), so **every** active slot with a face is tried. A light whose face rect
   (`face+0x58`, (0,0,h,w)) at (x_l − r, y_l − r) meets the tile face's bounds `+0x08` at (x, y) (`SectRect`
   `1001caec`) is blitted — first `.BlitLightOverFaceClip` (`1001cb50`), later ones `.BlitAfterLightOverFaceClip`
   (`1001cb84`) — at light offset (y − (y_l − r), x − (x_l − r)). No light met and **D ≠ 0** (`1001cc04 extsh.;
   beq`): `.BlitAmbDarkenOverFaceNoClip @ 1001e6a0` (`1001cc2c`) — every port pixel under a copy run of the face
   becomes `ambient[D][pixel]`; the face's pixels are not read, skip runs untouched (l. 16079–16215).
3. **`.BlitLightOverFaceClip` per run** (raw `1001db20..1001dbb8`): with r29 = light row + 1, `cmpwi r29,1; ble` and
   `cmpw r29,+0x54; bge` send the run to ambient slab D — so the light face's **first and last rows are never
   used** (§7.4's rule holds only for light rows 1 … h − 2); so does a run starting at a light column ≥ the width.
   Else per pixel: column < 0 or ≥ width → ambient; p = 0 → ambient; else `light[D][(p + (colour & 0xff) − 0xf5)·0x100
   + dst]`. `.BlitAfterLightOverFaceClip` (l. 15606–15845): slab 0 (`_DAT_100a0134`, no D), p = 0 read as 0xf5,
   pixels in light columns outside 0 … w − 1 or rows < 0 left alone, the blit ends at the first row ≥ h (§7.4's MED
   → HIGH).
4. **`.DrawLightsOntoTiles @ 1001c8e4`** (called by `.PaintFrameWrap` after `.SetScrollLocation` when Effects ≠ 3,
   l. 9202–9203) = `FUN_1001c1cc` (clears flag byte and count of the 20×13 cells, l. 14557–14600) → `.CalcLightOps
   @ 1001c45c` → `.DrawLightOps @ 1001c6f4`. `.CalcLightOps`: view = SetRect((h>>5)·32, (v>>5)·32, +640, +416);
   per active slot, `.HasLightChanged @ 1001c390` (changed unless y, x, face, colour `+0x18` vs `+0x1a` are as
   before and `+1` is 0 — radius not compared); rect = current face rect (unchanged) or current ∪ previous (`+8`,
   `+0x10/+0x12`, radius `+0x16`) (changed); cells **left>>5 … right>>5 × top>>5 … bottom>>5, both edges inclusive**
   (`1001c694/1001c6a8 ble`) → `.AddLightOp @ 1001c2c0` (grid-relative, dropped outside 0…19 × 0…12; flag |= changed;
   no bound on the 8 index slots of a 0x54-byte cell). `.DrawLightOps`: per cell with its flag set and (t ≠ −1 ||
   b ≥ 0 || o2 ≠ −1 — o2 is read only when o1 > 99, else r21 keeps the last o2 read [MED: its value on entry]),
   **no clear**: `.PlainWrapBGTile @ 10012ea8`, `.DrawLightOpBGTile @ 100131e8`, `.PlainWrapFGTile @ 10012ab4`,
   `.DrawLightOpFGTile @ 100132a0`, `.PlainWrapFGOverlayTile @ 10012f84`, `.DrawLightOpFGOverlayTile @ 10013358`,
   `.WrapRectBlitX(0004 → 000c, cell)` (`1001c7d8..1001c880`). `.PlainWrapFGTile` is **not** the grid's FG rule: in
   water with `0x26c6` = 0 the FG-water face is drawn for any t (not only 0 ≤ k < 95) and **before** the blend; it
   ends with the FG bool stamp into `0008` when the BG face is transparent. `.PlainWrapFGOverlayTile` tints o2 < 95
   through water table w whenever the cell is water (no `0x26c6` test) and stamps nothing. `.WrapLightOpTile @
   10016d80` does draw the wrapped copies. `.DrawLightOpOverTile @ 1001cc70` uses the cell's op list (lights `+4`,
   `+0xc`, `+0x14`), first/after as above; none met and `hdr+0x2706 > 0` (`1001cec4`): `.BlitAmbDarkenOverFaceClip
   @ 1001e1ac` (`1001cef0`) through slab D — **D = 0 included** (slab 0 = `Color2Index` of the CLUT's own colours).
5. **Level-1 start: nothing from the op path.** No slot is active, so the op grid stays empty and `.DrawLightOps`
   draws nothing; the start frame's darkness is entirely step 2's ambient fallback (D = light byte − 1, 0 … 10 in
   the window, enable 5). R2 self-derived (`.ruled`, `.errorDiffusion`, Effects 1, scroll (0, 10)): frame FNV-1a 64
   `97fa2462814fd12a`, 199,164 of the 266,240 drawn view pixels changed vs the Effects-3 frame `8e7a06f030d78d4a`
   (mask unchanged `e5437bb66513def6`).
6. **Edges.** D = −1 (light byte 0 with darkness enabled) reads the 256 bytes before `_DAT_100a0130` = the light
   table's last row (`100fbd6c + 16·0x6e00 = 10169d6c`; slab 15, t 109) [HIGH arithmetic]; no shipped level enables
   darkness over a 0 byte (§7.1). Light faces: `.Load1LightFaceFromPICT @ 1002ff1c` swaps `*_DAT_1009ff94` to clut 801
   around `.Load1PlainFaceFromPICT @ 1002fe68` (`.NewBlitPort` w × h, `DrawPicture` into (0,0,h,w)); of its 12 call
   sites (l. 50257–56147) 11 match their PICT's frame and `(806, 84, 84)` (`.InitBonusSprite`, l. 52306) has
   `DrawPicture` shrink the 192×192 PICT — QuickDraw's stretch is ROM code, refused in the replica [LOW].
