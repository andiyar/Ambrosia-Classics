# Ferazel's Wand 1.0.3 — graphics & sound resources (Sprites / Backgrounds / Titles / Sounds)

Register: code readings + data decodes; **nothing behaviour-verified**. Labels `[HIGH]`/`[MED]`/
`[LOW]` per claim (definitions in INDEX). `$FW` = the `files/` folder (see world-data-format.md).
Resource census (every type, count, size range) is in INDEX.

## 1. Everything is a QuickDraw `PICT`; the engine converts at load time  [HIGH]

There is no custom sprite/tile container on disk. Every tile set, sprite sheet, HUD piece,
title and background is a plain `PICT` (version 2, `0x0011 02ff` opcode header) in one of the
resource files, cut into a grid at load time and re-encoded in memory:

```
$ xxd -s 0x628b3f -l 32 "$FW/Ferazel's Wand Backgrounds.rsrc"      # PICT 200 body
00628b3f: 025c 0000 0000 0180 0100 0011 02ff 0c00  .\..............
00628b4f: fffe 0000 0048 0000 0048 0000 0000 0000  .....H...H......
```
→ picSize 0x025c (16-bit field, truncated), picFrame (0,0,384,256) = 256 wide × 384 high, then
`0011 02ff` (version 2) `0c00 fffe` (extended header, 72 dpi). Frame sizes of all 584 Sprites,
113 Backgrounds and 67 Titles PICTs were listed in this session (Python, resource-map walk);
the ones the loaders depend on are cited below.

Resource-file chain (engine.md §2): Sprites is the current file after `.OpenResourceFiles`
(chain Sprites → Sounds → Titles → app); `Ferazel's Wand Backgrounds` is opened on top during
`.SetupLevel`/`.LoadLevelTilesets`, and the World Data file on top of that for ids > 0
(`.SetResWorldFile`) [HIGH]. Which file supplies a given id is therefore "first file in that
chain that has it".

## 2. Loaders (all in the main dump)

| loader @ addr | args (as called) | result | label |
|---|---|---|---|
| `.LoadEncFaceSetFromPICT @ 1002ef2c` | (pict, count, cellW, cellH, cols, maskFirst, maskLast, cacheId, flip) | `count` faces of 0x34 B; cell `i` = rect (`(i%cols)·w`, `(i/cols)·h`, +w, +h) | [HIGH] |
| `.Load1EncFaceFromPICT @ 1002eafc` | (pict, mask?, cacheId, flip) | one face = whole PICT frame | [HIGH] |
| `.LoadEncWaterFaceSetFromPICT @ 1002f528` | same as set | per cell, the FG-water-mask tile of the cell's FG **kind** is stamped (`.BlitEncBoolTile`) into the cell before encoding | [MED: purpose "water version of FG tiles" inferred from names] |
| `.LoadPlainFaceSetFromPICT @ 1002fab8` / `.Load1PlainFaceFromPICT` | (pict, count, w, h, cols, out[]) | un-encoded 8-bit pixmaps (parallax, pattern tiles) | [HIGH] |
| `.Load1LightFaceFromPICT @ 1002ff1c` | (pict, w, h) | plain face drawn through CLUT 801 ("System CLUT", `_DAT_100a0038`) | [HIGH] |
| `.LoadFlipFaceSetFromPICT`, `.Load1FlipFaceFromPICT` | flip arg = 1 | mirrored sets | [MED] |
| `.CacheEncFaceSetFromPICT @ 10089250` + `.LoadCachedSpriteFaces` | (slot, pict, …) | deferred per-level loading of big sheets | [MED] |

Conversion path [HIGH]: `GetPicture(id)`; if the frame fits in 640×416 it is drawn into the
shared back port `_DAT_100a000c` after `ChangeBlitPortClut(port, *_DAT_1009ff94)`, else a
temporary 8-bit `NewGWorld` with CTable `*_DAT_1009ff94` is made; `DrawPicture` then remaps
the PICT into that 8-bit palette (QuickDraw colour matching); each cell is RLE-encoded by
`.EncodeRect`. So **the pixel indices of every face depend on the CLUT that is current in
`_DAT_1009ff94` at load time** (sprite CLUT 200 by default, the level CLUTs for tiles; §4).
A cached-face path reads pre-encoded `'McSp'` resources instead when `PTR_DAT_1009fcd4 == 0` and
a cache id is passed; no `McSp` resources ship (census) → unused [HIGH].

### 2.1 Face record (0x34 bytes)  [HIGH]

| off | type | meaning |
|---|---|---|
| 0x00 | Rect | frame rect (0,0,h,w) — `+4 = h`, `+6 = w` |
| 0x08 | Rect | tight bounds of opaque pixels (top, left−1, bottom+1, right+2; clamped ≥0) |
| 0x10 | Handle | encoded data (§2.2) |
| 0x14 | RgnHandle | mask region (`BuildMaskRegion`) only for indices in [maskFirst, maskLast] |
| 0x18 | u8 | 1 if any pixel 0 (transparent) was seen |
| 0x1a, 0x1e | i16 | 0 |
| 0x1c | i16 | 0x100 (scale 1.0?) [MED] |
| 0x20..0x2c | | 0 |
| 0x30 | i16 | source PICT id |

### 2.2 Encoded face ("sprite RLE data")  [HIGH]

`.EncodeRect @ 1002dd70` writes, and `.BlitEncFaceNoClipX @ 10024da8` (and ~60 sibling
blitters) read:
```
+0x00 Rect  frame (0,0,h,w)
+0x08 Rect  bounds (as face +0x08)
+0x10 tokens, big-endian u32: op = t>>24, n = t & 0xFFFFFF
   op 1  new row; n = byte length of this row's tokens that follow (clip blitters skip rows with it)
   op 3  skip n pixels (transparent run; pixel value 0 is transparent)
   op 2  copy n pixel bytes that follow, then pad to a 4-byte boundary
   op 0  end of face
   op ≥4 → DebugStr "Encountered a bad token in sprite RLE data!"
```
Encoder buffer size `4·h + 3·w·h + 0x14` (min 0x1000), shrunk with `SetHandleSize` at the end
[HIGH]. No worked byte dump: encoded faces exist only in RAM (made from PICT pixels at run
time); the PICT pixel data itself is standard QuickDraw PackBits.

## 3. Tile sets (Backgrounds file; ids from `Mlvl`, world-data-format.md §3.2)  [HIGH]

`.LoadLevelTilesets @ 10003098`, all with 32×32 cells, 8 per row unless noted:

| set | loader | count | sheet | default id | notes |
|---|---|---|---|---|---|
| BG | `.LoadBGTileset @ 10001e50` | 96 | 256×384 | 180 | encoded; loaded with `*_DAT_1009ff94 = *_DAT_1009ff8c` (level+base CLUT) |
| FG | `.LoadFGTileset @ 10001f2c` | 96 | 256×384 | 181 | encoded |
| FG water | `.LoadFGWaterTileset @ 10002008` | 96 | same id as FG | 181 | §2 water stamping |
| FG pattern | `.LoadFGPatternTileset @ 100020ec` | 64 | 256×256 | 206 | loaded twice: encoded set (`_DAT_1009ff84`) **and** plain faces (`DAT_100a5004[64]`) |
| PxBack | `.LoadPxBackTileset @ 1000224c` | 36 of 128×128, 6 per row | 768×768 | 5000 (512×768 in Sprites) | plain; uses sprite CLUT if hdr+0x26cc |
| PxMid | `.LoadPxMidTileset @ 10002344` | 12 of 128×128, 6 per row, **two sheets** id and id+1 | 768×256 each | none (0) | plain; sheet id = image (0 = transparent) into `DAT_100a4fa4[12]`, id+1 = mask (0 = opaque, 0xFF = clear) into `DAT_100a4fd4[12]` (rendering-omnipx-titles §1.2) ⚑ wave 2 corr (2026-10-04) RO #10 |

Fixed sets loaded once (`.InitGameGlobals @ 10001498`):
- FG water mask: `PICT 183` (0xb7), 96 cells 32×32 (Sprites file, 256×384) → `_DAT_1009ff98`.
- FG blend: `PICT 185` (0xb9), 96 cells → `_DAT_1009ffc8`, then `.ProcessFGBlendTileFaces`.

Sheet sizes check against the census: every FG/BG id used by the 24 levels is 256×384, every
pattern id 256×256, every PxBack id 768×768 (257 is 768×708, short by half a row — cells 30..35
partially outside the frame [MED: effect on the last row not traced]), every PxMid pair 768×256
[HIGH, census lines + Mlvl field census]. `PICT 208` (768×256) is not referenced (level 1's
PxMid is 0) [HIGH].

Worked decode: level 1 FG = `PICT 200`, frame 256×384 (bytes above) → 8 columns × 12 rows =
96 cells; FG tile `t` is cell (`t%8`, `t/8`), e.g. tile 13 = pixels x 160..191, y 32..63.

### 3.1 FG drawing rule (`.PlainWrapFGTile @ 10012ab4`)  [HIGH]
For FG tile `t` (0..95; −1 = empty) at cell (x,y), with BG water kind `w` (BG kind 200..209 →
w = kind−200, else −1):
1. `t < 95`: draw FG face `t`; if the cell is water and hdr+0x26c6 == 0 also draw the FG-water
   face `t` with water tint `w`; if hdr+0x26c6 ≠ 0 draw face `t` tinted instead.
2. Then if `k = FGkind(t) mod 100` is in 0..94: draw **blend** face `k` combined with the
   **pattern** tile at (x,y) — mode `(w+0x15)<<16 | patternIndex`. ⚑ wave 2 corr (2026-10-04) P2 W3: FG kinds 0x4e/0x4f exist
   only for this blend step (no collision); BG kinds 400..495 have no reader (player-states-2 §12).
3. `t == 95`: draw the pattern tile for (x,y) (plain, or tinted if submerged and 0x26c6).
4. If the BG tile's face has transparency (`face+0x18`), the FG face is also blitted as a
   boolean mask into the second buffer (`_DAT_100a0008`).

Pattern tile index (`.GetFGPatternTile @ 1003c0b8`): `(x mod 8) + 8·(y mod 8)` (floor mod),
or `(x mod 6) + 8·(y mod 6)` when hdr+0x26cb ≠ 0; > 63 is a fatal "bad FGPattern" [HIGH].

### 3.2 Blend faces (`.ProcessFGBlendTileFace @ 1002a6b0`)  [HIGH]
Walks the encoded tokens of each of the 96 blend faces and rewrites every copied pixel value
`v` to a 2-bit weight: `v == 0 || 0x97 ≤ v ≤ 0x98 → 3`; `1 ≤ v ≤ 0x96 → 0`; `0x99..0x9b → 2`;
`0x9c..0x9e → 1`; `v ≥ 0x9f → 0`. (`v` are indices in the CLUT current at load time.) The
blend blitter `.BlitEncFaceTileBlend` mixes the pattern tile through these weights: ~~[MED: the
mixing arithmetic not read]~~ weight 0 → pattern, 1 → ¼ screen + ¾ pattern, 2 → ½/½, 3 → ¾ screen +
¼ pattern, via the pair tables `0154/015c/0158` (raw `1002a8cc..1002a944`; lighting-tables §8) [HIGH]
⚑ wave 2 corr (2026-10-04) LT #1.

### 3.3 Overlay tiles (`.PlainWrapFGOverlayTile @ 10012f84`)  [HIGH]
Overlay cell o1 = 100 → FG face o2; o1 = 101 → BG face o2; o2 ≥ 95 → pattern tile; drawn tinted
when the cell is water. (o1 < 100 is the wind field, physics.md §6.)

## 4. Palettes / CLUT handling

- 8-bit indexed throughout; the screen CLUT is swapped per context with `.SetScreenClut`, and
  off-screen ports are re-tagged with `.ChangeBlitPortClut` [HIGH].
- Level CLUTs (Backgrounds file): `hdr+0x285c` (e.g. 201 'earthcav') and `hdr+0x285e` (e.g.
  202 'base + earthcav'); the second is the screen CLUT during play and the conversion CLUT of
  BG tiles (`_DAT_1009ff8c`); defaults 201/202 when 0 [HIGH, `.SetupLevel`]. Naming pattern
  "<theme>" / "<theme> + base" holds for 201..248 (census): the "+ base" CLUTs add the sprite
  colours ("base sprite clut" 200) [LOW: inferred from names].
- Sprites are converted with CLUT 200 "base sprite clut" (`GetCTable(200)` at boot into
  `_DAT_1009ff94` and `_DAT_100a0020`); CLUT 199 "base sprite clut grays" for the status bar
  [HIGH for the loads; [MED] for the per-face CLUT at load time].
- `.AltClutMod @ 10004134` (only when hdr+0x271c names an alt CLUT; 0 in all 24 levels): for
  entries 0xa0..0xfe of the level+base CLUT, `lum = (r+g+b)/3 >> 8` (clamped 1..0xfe), then each
  channel `c' = clamp(c + 2·alt[lum].c − 0x8000, 0, 0xffff)` (overlay-style tint), then
  `SetScreenClut` [HIGH].
- `.AnimateCLUT` (hdr+0x2730..0x2736) ~~cycles a CLUT range [MED]~~ is not a cycle: a sine-wave
  recolour of entries `255 − count .. 254` (`0xff−n..0xfe`) of the level+sprite working CLUT by a
  per-mode formula, pushed to the screen with `SetEntries`, rate-gated by the Effects level (raw
  `1001180c..10011cd4`; lighting-tables §1.5, bosses-3 §9.2) [HIGH] ⚑ wave 2 corr (2026-10-04) LT #3 =
  B3 #W2.
- Lighting: `.CalcLightingTable` builds 8-bit remap tables (light faces from
  `Load1LightFaceFromPICT`), `.BuildTintTable`, `.BuildWaterTintTable`, `.BuildReddenTable`,
  `.BuildTranslucTable`, `.BuildPosterizationTable`. ⚑ wave 2 corr (2026-10-04) LT #2: per-cell
  darkness = BG-map cell high byte − 1, `hdr+0x2706` only **enables** it (`1003c2b4..1003c340`); the
  algorithms are transcribed in lighting-tables §3–§7 (chosen indices LOW, particles §4.3); the
  posterization table yields levels 0..15, not indices, and the posterization, transluc, `0138` and
  `013c` tables have **no reader** (tocrefs) [HIGH].

### 4.1 Cooling map / flame layer  [HIGH for the load]
`.LoadCoolingMap @ 10000924`: draws `PICT 198` (Sprites, 608×96) through CLUT 198 "cooling map
clut" into a 640×100 port and copies it into the flame engine's cooling buffer
(`_DAT_100a0070 + 0x1c`). The flame engine (`.FlameCreate(…, 640×100, 0xce, 0xfe)`,
`.FlameAddLine`, `.FlameAddSpark`, `.FlameUpdate`, `.FlameUp`) is a classic "fire" cellular
effect drawn on levels with hdr+0x2722 ≠ 0 (52, 55) — per-pixel rule (`.FlameUp @ 100857e0`) in
lighting-tables §9 ⚑ wave 2 corr (2026-10-04) LT #4.

## 5. Sprite sheets (Sprites file)

Each sprite class's `.Init<Class>Sprite` loads its sheets once at boot with fixed cell sizes;
examples [HIGH, call arguments]:

| class | PICT (id) | cells | cell w×h | cols | sheet in census |
|---|---|---|---|---|---|
| player | 1003 (0x3eb) | 4 | 100×120 | 4 | 400×120 |
| player | 1010 (0x3f2) | 10 | 100×120 | 10 | 1000×120 |
| player | 1020 (0x3fc) | 16 | 100×120 | 4 | 400×480 |
| player | 1022 (0x3fe) | 10 | 150×120 | 10 | 1500×120 |
| player (cached) | 1050..1053 (0x41a..) | 4–6 | 160×160 | 3–4 | 1050: 480×320 |
| player shot | 1100/1101 'fireball right/left' | 6 | 24×15 | 1 | 24×90 |
| bonus | 1057 (0x421) | 10 | 32×32 | 10 | 320×32 |
| bonus | 1058 (0x422) | 10 | 32×32 | 10 | 320×32 |

Player face sets: 30+ sheets 0x3eb..0x40f, all 100×120 cells except 0x3fe (150×120) and
0x3ff (120×120) (`.InitPlayerSprite @ 1004a284`). Sprite type numbers and PICT ids coincide
for many classes (e.g. bonus type 1307 ↔ `PICT 1307` 60×28) [LOW: naming convention only].
Per-sprite **hot rect** is set by each Setup routine with `SetRect(sprite+0x34, l, t, r, b)`
relative to the face's top-left — e.g. the player `SetRect(+0x34, 0x26,0x22,0x3e,0x55)` =
x 38..62, y 34..85 within the 100×120 cell [HIGH]; crouch/shield variants change it
(physics.md). Tile hot rects (`.InitTileHotRects`) → physics.md §3. Kick rects
(`.InitPlayerKickRects @ 10000408`): 36 rects of ≈8×12 around a 64×64 box, one per 10°
(`SetRect` list, quoted coordinates in the dump) — used by the dagger/kick hit test [MED]. ⚑ corrected (deepening 2026-10-03): the table (0x1024b394, TOC slot
0x100a0078) is written by `.InitPlayerKickRects` and **read by nothing** — enemy-shots-and-damage.md
corrections #1, labelled [HIGH] by that reader (one TOC load in the whole code section; residual
risk: an arithmetic address); melee hits use the held-item sprite's face rect (pickups-boxes.md §3.1).
Per-class hot rects, faces and sheets of every sprite class are now in the class files (index:
coverage.md §1); the draw-effect word `+0xb8` and its NOT-RESOLVED modes: physics.md §0.1.

## 6. Sounds

### 6.1 `snd ` resources (Sounds file)  [HIGH]
172 `snd `, all format 1, one modifier, **one** `bufferCmd` (0x8051) pointing at an 8-bit
offset-binary sampled-sound header (encode 0); rates: 138 × 22050 Hz, 33 × 11025 Hz,
1 × 22254.5 Hz (Python decode of every header, this session).
```
$ xxd -s 0xbae5 -l 48 "$FW/Ferazel's Wand Sounds.rsrc"         # snd 128 'soft impact'
0000bae5: 0001 0001 0005 0000 00a0 0001 8051 0000  .............Q..
0000baf5: 0000 0014 0000 0000 0000 22c0 5622 0000  ..........".V"..
0000bb05: 0000 22be 0000 22bf 003c 8282 8182 8182  .."..."..<......
```
→ format 1, 1 modifier (synth 5 = sampledSynth, init 0xa0), 1 command 0x8051 param2 0x14 →
header at +0x14: dataPtr 0, length 0x22c0 = 8896 samples, rate 0x56220000 = 22050.0 Hz,
loop 0x22be..0x22bf, encode 0, baseFreq 0x3c; samples `82 82 81 …`.

### 6.2 Loading and the mixer ("Sound Tool")  [MED]
`.InitSounds @ 10045838` loads ~140 ids (300..304, 401..511, 600..615, 700..704, 800..805,
4704, 4705, …) through `FUN_10091748(id)` [HIGH]: `GetResource('snd ', id)`, find the sampled
header (`FUN_100922d8`), allocate `ceil(n/1024)·1024 + 0x40c`, write `'asnd'`, block count,
the header's rate, then the samples **minus 0x80** (signed 8-bit) [HIGH]. Playback
`FUN_10091208(req)`: 16 voices, request {sound, ?, rate 0x10000, …, priority (+0x14), left
(+0x18) and right (+0x1a) volume clamped to 0x80}; a new sound displaces the first voice whose
priority is ≤ its own and whose summed volume is ≤ its own; pitch = `FixMul(soundRate /
outputRate, req.rate)` [MED: mixer output path (`SndPlayDoubleBuffer`) not transcribed].
Helpers ⚑ wave 2 corr (2026-10-04) EG2 #2: `FUN_100916dc(x)` = number of voices playing sound/voice `x`
(0 = all) (`100916dc..10091744`); `FUN_10091504(x)` = stop all voices matching `x`, calling each
voice's completion proc (`10091504..100916c8`) (enemies-ground-2 §3) [HIGH].
Volume knob: `iRam100a510c` (global volume) × per-call volume >> 8 [HIGH].

### 6.3 Positional sound  [HIGH]
`.STPlay3DSound(snd, prio, vol, pos(v,h)) @ 10047ac0` → `.CalcStereoVolume @ 10047738`:
two "ears" at view (scrollX+200, scrollY+192) and (scrollX+408, scrollY+192);
`d = .PEDistance(|dx|,|dy|) = max + min/3`; ear gain `g = (1024−d)>>3` (0 beyond 1024 px);
`L = g_l·vol>>7`, `R = g_r·vol>>7`; the louder side is boosted and the quieter cut by
`2.5·|L−R|` (`s = 2·diff; s += s>>1`); clamp each to 0..256; finally halved before the voice
request. Sound off (prefs+0xb == 0) → no play.
`.STPlayRegSound(snd, prio, vol)` plays centred: both channels `(vol·globalVol>>8)>>1` [HIGH].
`.UpdateDynamicSounds`/`.STPlayLoopedSound` keep looping sounds positioned [MED].
⚑ wave 2 corr (2026-10-04) EF W3: `.STPlay3DSoundPitched(snd, prio, vol, pos, rate)` differs from `.STPlay3DSound`: the stereo
pair is **not halved**, a position of exactly (0,0) plays centred at 0x80/0x80 without attenuation, and
the request is dropped when L + R < 0x14 (`10047b8c..10047c5c`). `.STPlay3DSoundRand @ 10047d44` =
Pitched with rate `FastRand(10000) + 0x10000 − 0x1389` = 60535..70534 in 16.16 (×0.924..×1.076;
`10047d60..10047d90`) — enemies-flyers §7.2 [HIGH].

### 6.4 Music
Separate QuickTime AIFC files — world-data-format.md §1.

## 7. Titles file  [HIGH for ids/sizes; use sites partial]
67 PICTs + 16 CLUTs (census). Used ids found in code: 128 loading screen (non-640×480), 131
splash/publisher logo, 136 loading screen at 640×480, 132 status bar (640×88), 133 HUD piece
(196×45), 138 death/continue screen (`.AskToContinue` draws 0x8a), 140 (320×110),
141 (stats bar strip 52×714, world-data-format.md §4.3), 142 (320×64), 159/161/162 victory, 4921 pause
banner, 4985 (`0x1379`, 32×28, continue-dialog cursor) [HIGH for each `GetPicture`/`DrawPICT`
call cited]. ⚑ wave 2 corr (2026-10-04) RO #9: every id is now mapped (rendering-omnipx-titles §4.1/§4.2):
140 = stage-complete panel, 142 = loading popup, 133 = health/magic HUD; PICT 137, 4951..4955,
4961..4965 and CLUTs 288..290 and 729 have **no reference**; CLUT 131 is loaded twice and never read.
CLUTs 281..287 are the chapter screens, 260 victory, 132 death, 128 splash, 130 main menu (names in
census).

## ⚑ Corrections (C5 review, 2026-10-07; follow the binary)

Read against `ghidra/Ferazel_pef.decompiled.c` (Ferazel 1.0 PEF) by the C5 review and applied under Ben's
2026-10-07 "follow the binary" precedent. Existing text above is left as written; these supersede it.

1. **FG and FG-water convert under the level CLUT `0x285c` (0 → 201), not level+base.** `.SetupLevel`
   l. 2287–2297 loads `PTR_DAT_1009ff4c` ← `GetCTable(0x285c)` (0 → 201) and l. 2301–2318 `_DAT_1009ff8c` ←
   `GetCTable(0x285e)` (0 → 202). `.LoadLevelTilesets` sets the conversion CLUT `*_DAT_1009ff94` to the level
   CLUT on entry (l. 1576–1577); `.LoadBGTileset` switches to `ff8c` and restores it (l. 950–955);
   `.LoadFGTileset` and `.LoadFGWaterTileset` never touch `ff94` (l. 970–1031); `.LoadFGPatternTileset` switches
   to `ff8c` (l. 1049). So BG and pattern are level+base (202 for level 1), FG and FG-water the level CLUT (201).
2. **The fixed sets 183 (FG water mask) and 185 (FG blend) convert under clut 199.** `.InitAppGlobals`
   l. 412–413 loads `_DAT_100a001c` ← `GetCTable(199)`; `.InitGameGlobals` sets `*_DAT_1009ff94 = *_DAT_100a001c`
   before both loads (l. 827, l. 840). The lighting-tables §8 blend-weight mapping (0x97/0x98 → 3, 0x99..0x9b → 2,
   0x9c..0x9e → 1) is therefore in CLUT-199 indices. 183 is a 1-bit BitMap and bypasses the search either way.
3. **PxBack/PxMid with header `0x26cc` set use the `0x285e` level+base CLUT** (`*_DAT_1009ff8c`;
   `.LoadPxBackTileset` l. 1094–1096, `.LoadPxMidTileset` l. 1128–1130), otherwise the level CLUT. "Sprite CLUT"
   for this flag (§3, bosses-3 "level+sprite") is loose wording for the level+base CLUT.
4. **`.RedrawScrollGrid` is strip-incremental, and draws into port `0004`** (R1, 2026-10-07; both Opus review legs
   re-read it). `.SetScrollLocation @10012848` redraws only the newly exposed row/column strips (l. 9506–9539, old h for
   the row strip, old v for the column strip); the whole 21×14 window is drawn only by `.RedrawEntireScrollGrid
   @10013fd0` (level start, l. ~3265, 3914, 6259). Every blit is culled against `fe78` (x ≤ h+0x260, y ≤ v+0x180,
   fixed 0x20 cell), so 260 cells draw at scroll (0, 10). Tiles go into port `0004`; `.WrapRectBlitX` (raw
   10013f90) copies them to `000c`. Mask port `0008`: no per-frame fill; each redrawn cell writes 0xFF (100246b4,
   10024738) and 0x00 into `0004` (10023260, 10023378; constant 0x100a1690 = 0.0); the FG boolean stamp writes 0x00
   (100230bc, 10023148).
5. **Blend cells use the overwritten FG kind table** — `.LookupFGTileKind @10041fe8` reads the table
   `.LoadTileDefinitions @10041dcc` rewrites for tiles 80..95 (kind = tile): level 1 has **1,560** blend-face cells,
   not the 1,335 the planner counted with the raw table (plan Research note 8).
6. **Overlay cells in `.RedrawScrollGrid` draw the pattern only for o2 == 95 and never water-tint it.** §3.3's
   "o2 ≥ 95 → pattern, tinted in water" describes `.PlainWrapFGOverlayTile`, a different call site. Equivalent on the
   shipped data (max o2 = 95 on all 24 levels).
7. **(R4, 2026-10-09) Sprite sheets' conversion CLUT:** boot-loaded sheets and cached-flag-0 sheets convert under clut
   **200**; cached-flag-1 sheets (plants, wall tunnels, 1464, outcrops) under clut **202** = level + base (`1008901c`).
   The OmniPx strip face with hdr 0x26cc unset converts under **200** (decompile l. 2273). At Setup the cached faces
   are the PICT 150 placeholder (l. 73900–73950, after l. 2537); what re-faces them is not yet read.
