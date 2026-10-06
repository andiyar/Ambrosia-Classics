# Deimos Rising 1.0.6 — sprite, image, sound and music containers

Code readings only. Conventions as in pak-format.md. Raw entries extracted with
`python3 docs/deimos/tools/list_paks.py "$G/ Data/Paks" --decode $D` (`$D` = any scratch dir;
entries land at `$D/<Pak>/<entry name>`).

## 1. Image decoding is QuickTime's, not the game's

⚑ corrected (wave 3+4, 2026-10-04): `FUN_10021190` below imports **sprite plates only** (sole
caller the group loader `FUN_10018d20`, GWorld depth from the caller); TGAs (`im16`) import through the
U_Image path `FUN_10020e60` → `FUN_10020f00`, which takes the depth from the file and shares the same
QuickTime sequence and warnings — so the claims below hold; only the function attribution changes
(sprite-manager-resource-image.md §6.1).

`FUN_10021190(id, depth, kind) @ 10021190` (M_Image.cc by assert `s_M_Image_cc_100e882e`):
```c
  uVar4 = 0x696d3136;                                            // 'im16'
  if ((param_3 == 0x47494620) || (... (param_3 == 0x424d5020))) { // 'GIF ' or 'BMP '
    uVar4 = 0x696d3038;                                          // 'im08'
  }
  iVar1 = FUN_10002a20(uVar4,param_1);                           // tag bytes as a Handle
    sVar3 = .glue::OpenADefaultComponent(0x67726970,param_3,&local_34);  // 'grip', subtype
      iVar2 = .glue::GraphicsImportSetDataHandle(local_34,iVar1);
        sVar3 = .glue::GraphicsImportGetImageDescription(local_34,&local_38);
          if ((param_3 == 0x54474120) && (*(short *)(*local_38 + 0x52) != 0x10)) {  // TGA must be 16-bit
            ... "FILE WARNING: unsupported pixel depth (%i) in file \"%s\""
            FUN_100099c0(iVar5,(int)*(short *)(*local_38 + 0x20),(int)*(short *)(*local_38 + 0x22),
                         param_2,0);                               // GWorld w,h,depth
            iVar2 = .glue::GraphicsImportSetGWorld(local_34,uVar4,0);
              iVar2 = .glue::GraphicsImportDraw(local_34);
```
Claims:
- `im08` entries are GIF files and `im16` entries are TGA files, both decoded by the QuickTime
  graphics importer (`'grip'` component, subtype `'GIF '`/`'TGA '`) and drawn into an off-screen
  pixel buffer of the caller-chosen depth (8 or 16). [HIGH]
- A TGA whose image description depth (`+0x52`) is not 16 only produces a warning. [HIGH]
- 16-bit buffers are QuickDraw 16-bit direct pixels (x1-r5-g5-b5, big-endian in memory) — the
  standard GWorld format; the media-mask compare below (`== 0x1f` = pure blue) is consistent.
  [MED — GWorld format not read in this binary; inferred from the 0x1f/0x7fff values]
- `FUN_10020da0(img, id, 'TGA ')` / `FUN_10020e60` are the U_Image wrappers used by level and
  interface code (`FUN_1000fbc0`, `FUN_100000e0`, `FUN_100234d0`). [MED] ⚑ corrected (wave 3+4, 2026-10-04): `FUN_10020e60` →
  `FUN_10020f00` is the TGA importer (HIGH, sprite-manager-resource-image.md §6.1).

## 2. `im08` — sprite plates (GIF89a, colour plate "IC" + alpha plate "IA")

### 2.1 Pairing
`FUN_10018d20(id) @ 10018d20` (U_Sprite.cc) loads one sprite group:
```c
      local_188 = param_1;
      FUN_1000cd60(auStack_17c,&local_188,4);
      FUN_100463b0(auStack_17c);                         // upper-case the 4 chars
      FUN_1000cd60(&local_188,auStack_17c,4);
      ...
      iVar5 = FUN_10021190(local_188,8,0x47494620);      // ALPHA plate, 8-bit, by UPPER id
        FUN_1000a480(iVar5,&local_18c,&local_190);       // alpha w,h
        FUN_1000a4a0(iVar5,&local_194,&local_198);       // alpha base, rowBytes
        iVar6 = FUN_10021190(param_1,0x10,0x47494620);   // COLOUR plate, 16-bit, by given id
          uVar1 = *(undefined2 *)(local_1a4 + 4);        // colour pixel (2,0) = transparent key
          if ((local_19c != local_18c) || (local_1a0 != local_190)) { ... "Sprite color and alpha plates are not equal size"
          FUN_1001f140(local_194,local_198,local_18c,local_190,iVar4);   // scan ALPHA plate -> rect list
          iVar8 = FUN_10021190(local_188,0x10,0x47494620);               // ALPHA plate again, 16-bit
          ... per rect: copy alpha16 + colour16 rect, FUN_1001d780(w,h,uVar1) -> encoded frame
```
- A sprite group with ID `abcd` = colour plate tag `abcd` + alpha plate tag `ABCD` (upper-cased
  by `FUN_100463b0`, a ctype-table toupper). [HIGH for the call sequence; MED that
  `FUN_100463b0` is toupper — it maps through table `_DAT_100dea6c` when ctype bit 0x40 is set]
- Data check (tool, Python over the decoded set): 125 `IC` plates, 125 `IA` plates; every IC id
  is lower-case and {upper(IC ids)} == {IA ids} → `True`. [HIGH — tool output]
- Both plates must have identical width/height (fatal data error otherwise). [HIGH]
- The 16-bit pixel at (x=2, y=0) of the COLOUR plate is passed to the frame encoder as
  `uVar1` — the transparent colour key. Frames are NOT RLE-encoded: `FUN_1001d780` stores the raw
  RGB555 frame plus an optional per-pixel alpha map (§2.3a). [HIGH — encoder and blitter read]
  ⚑ corrected (review 2026-10-03) (fix pass, from review #9: was "RLE-encoded … [MED — encoder not read]").

### 2.2 Plate layout (frame cells) — `FUN_1001f140/1f1c0/1f340/1f4e0/1f540/1f5b0` (U_SpritePlate.cc)
Scan runs on the 8-bit ALPHA plate (indices after QuickTime's draw into an 8-bit GWorld):
- Key pixels on row 0: `p[0]` = (0,0) cell fill colour, `p[1]` = (1,0) grid colour; asserts
  `p[0] != p[1]` and `p[1] != p[2]` (`FUN_1001f1c0`, lines 0x6b/0x71), width ≥ 3, height ≥ 2.
- Strips: from row 1 down, a strip is a run of rows whose column-0 pixel is not the grid colour
  (`FUN_1001f4e0`); strips are separated by grid rows.
- Cells: within a strip, a cell is a run of columns containing no grid pixel in the strip rows
  (`FUN_1001f540`).
- Frame: `FUN_1001f5b0` trims the cell's rows/columns that are entirely the cell's own top-left
  colour (the fill colour), giving width `w` and height `h`; an all-fill cell is skipped.
- Rect (Mac Rect order top,left,bottom,right — confirmed by `width = r[3]-r[1]`,
  `height = r[2]-r[0]` in `FUN_10018d20`) from `FUN_1001f340`:
  ```c
            param_10[1] = iVar3 + 1;                                  // left  = cellLeft+1
            *param_10 = iVar4 + (local_48[0] - local_54) + -1;        // top   = stripTop+stripH-h-1
            param_10[3] = param_10[1] + local_50;                     // right = left + w
            param_10[2] = *param_10 + local_54;                       // bottom= top + h
  ```
  i.e. the frame is taken bottom-left-anchored inside the cell with a 1-pixel inset; the trimmed
  size decides w,h. Frames are numbered in scan order (strips top→bottom, cells left→right).
  [HIGH for the arithmetic]
- Data check: re-implementing the scan in Python (`python3 docs/deimos/tools/plate_frames.py $D`; RGB compare
  instead of 8-bit indices) over all 125 alpha plates gives 2554 frames; for 2550 of them the
  bottom-left-anchored rect equals the trimmed bounding box; the 4 exceptions are all in
  `Glows IA[GLOW].gif`. [HIGH — tool output; the 8-bit-index vs RGB difference is LOW risk]
- Limits: frame width/height ≤ `kU_Sprite_MaxDimensions` (`*_DAT_100df180`, values NOT
  RESOLVED); fewer than 0xFFFF frames.

### 2.3 Worked decode — `Bomb Crater` (tag `bocr` / `BOCR`)
Command: `xxd -l 48 "$D/Game/im08/Bomb Crater IC[bocr].gif"`:
```
00000000: 4749 4638 3961 3700 1500 f200 0000 de00  GIF89a7.........
00000010: ff00 ff00 00ff 1010 1000 0000 0000 0000  ................
00000020: 0000 0000 0021 f904 0000 0000 002c 0000  .....!.......,..
```
`GIF89a`, width `0x0037`=55, height `0x0015`=21, flags `0xf2` (global colour table, 2^(2+1)=8
entries), palette: 0 `(0,222,0)` green, 1 `(255,0,255)` magenta, 2 `(0,0,255)` blue,
3 `(16,16,16)` near-black, 4–7 black. Command: `xxd -l 64 "$D/Game/im08/Bomb Crater IA[BOCR].gif"`
→ 55×21, flags `0xf3` (16 entries): 0 white … 8 `(140,140,140)`, 9 `(255,0,255)` magenta,
10–11 greys, 12 `(0,0,255)` blue, 13 black.
Pixel indices (Python/PIL dump of the colour plate, `#` = n/a), rows 0–4 and 18–20:
```
row 0  2102222222222222222222222222222222222222222222222222222   (0,0)=blue fill, (1,0)=magenta grid, (2,0)=green key
row 1  1111111111111111111111111111111111111111111111111111111   grid row
row 2  2122222222222222222212222222222222222212222222222222221   1-px blue inset
row 3  2120000000033330000212000000330030000212222222222222221
row 4  2120000033333330000212000000033333000212222222222222221
row18  2120000333330000000212000000000000000212000003300000021
row19  2122222222222222222212222222222222222212222222222222221
row20  1111111111111111111111111111111111111111111111111111111
```
Strip = rows 2..19 (h=18). Cells: col 0 (all blue → skipped), cols 2–19, 21–37, 39–53.
Frames (from the alpha plate, scan of §2.2): `(top,left,bottom,right)` = (3,3,19,19) 16×16,
(3,22,19,37) 15×16, (7,40,19,53) 13×12 — the third frame's top 4 rows are fill (blue) and it
sits on the cell bottom. In the colour plate green (index 0) is the transparent key, `3` the
crater colour; the alpha plate carries per-pixel opacity as grey levels where white = fully
transparent (white sits exactly where the colour plate is green). [HIGH for geometry; HIGH for
"white = transparent / darker = more opaque" — now read in the blend code, §2.3a: transparency =
the alpha pixel's 5-bit RED channel] ⚑ corrected (review 2026-10-03) (was MED — inferred from the plates).

### 2.3a Encoded frame and alpha blend (U_SpriteBlit.cc) — added in the 2026-10-03 fix pass
Encoder `FUN_1001d780(w, h, key) @ 1001d780` (called per frame rect from `FUN_10018d20` after the
frame is copied from the colour plate into the "encodingBuffer" `_DAT_100e0188` and from the
16-bit ALPHA plate (`ABCD`, "alphaBuffer16bppPtr") into the "alphaAnalysisBuffer" `_DAT_100e0184`
— names from the assert strings): block = 0x18-byte header + w·h RGB555 pixels + (optional)
w·h u16 alpha values:
| off | field |
|---|---|
| 0x00 | magic `0x499602d2` |
| 0x04 / 0x08 | w / h |
| 0x0c | 0x10 (depth) |
| 0x10 | u16 colour key |
| 0x12 | byte: has alpha map |
| 0x14 | offset of the alpha map (= 0x18 + 2·w·h) or 0 |
Alpha map `FUN_1001eec0(key) @ 1001eec0`, per alpha-buffer pixel `p`:
```c
      if (*puVar4 == param_1)          uVar2 = 0x20;              // alpha pixel == key -> transparent
      else { uVar2 = *puVar4 >> 10 & 0x1f;                         // RED 5-bit channel
             if (uVar2 < 0x1f) { bVar1 = true; bVar6 = true; }     // row / frame has visible pixels
             else uVar2 = 0x20; }                                  // red 31 (white) -> transparent
      ...
    if (!bVar1) *puVar8 = 1000;                                    // first entry of an empty row
  if (!bVar6) { free; return 0; }                                  // no alpha map: colour-key only
```
Blit (plain variant `FUN_1001d9f0 @ 1001d9f0`; clipped/scaled/tinted variants `FUN_1001db50`,
`1001dd20`, `1001df00`, `1001e0d0/e2b0/e4f0/e770`, `1001a6f0/aa90` share the scheme): without an
alpha map — or when the global `DAT_100e0181` is 0 — copy every pixel ≠ key. With the map, per
row: first value 1000 → skip the row; per pixel `a` (mode 0 — ⚑ corrected (wave 3+4, 2026-10-04): modes 1 and 3 add the
command alpha, α = min(a + p, 32), and mode 2 uses α = trunc(a + 0.032·p²); blit-pixel-rules.md §2–§3):
0x20 → skip, 0 → copy, else
`dst = (dst·a + src·(32 − a)) / 32` per 5-bit channel (packed-channel multiply, `>> 5`).
→ **transparency a ∈ 0..32 = red channel of the 16-bit alpha plate: black = opaque, white (31) =
fully transparent, greys blend** — the plate reading of §2.3 confirmed. [HIGH — read]
Draw dispatcher `FUN_10019570 @ 10019570` (U_Sprite.cc, "Sprite Draw: encoded data" errors)
picks the blitter from the draw command's flag word (`&1`, `&2`, `&4` → modes 1/2/3, each with a
visibility/blend argument `param_1[7]`, 32 = invisible → nothing drawn), the clipped variant when
the frame crosses the clip rect, the `FUN_1001a6f0/aa90` path when the command's float `+0x18` ≠
`*_DAT_100df188` (presumably a scale ≠ 1.0 — ~~constant not resolved~~ → ⚑ corrected (review wave 3, 2026-10-06) #S: the TOC slot `0x100df188` points to `0x100d6d34` = f32 1.0 (then 100.0, 0.5), so the test is scale ≠ 1.0 (`100195d0`; blit-pixel-rules.md §0, §1.1)); draw type `COST`
(0x434f5354) is not a sprite but a translucent solid-colour rectangle (`FUN_1001ec80`, same
`(dst·a + colour·(32−a))/32` blend). [HIGH for the dispatch; MED for the per-flag names]
~~Still open: who sets `DAT_100e0181` (alpha drawing on/off; no named write in the dump).~~ → ⚑ corrected (wave 3+4, 2026-10-04):
only the debugOnly ALPHA console handler (`1001f060`), never registered, so it stays 1 all session
(blit-pixel-rules.md §6).

### 2.4 Sprite census
`list_paks.py --images` (GIF/TGA headers): 250 GIF entries (248 Game.pak + 2 Interface.pak),
45 TGA entries. 2554 frames total across the 125 groups (§2.2 tool). The Sprite Groups Cache
(`"Sprite Groups Cache"`, `FUN_1001b040/1b590`) and Units Cache (`G_UnitDefinitions.cc`) are
load-time caches written next to the data — not part of the original data. [MED]
⚑ corrected (wave 3+4, 2026-10-04): the Sprite Groups Cache format, load policy, reader `FUN_1001b040`
and writer `FUN_1001b390`/`FUN_1001b590` are now written out (sprite-manager-resource-image.md §4); the
cache is used on Mac OS X only and its date is never compared [HIGH].

## 3. `im16` — 16-bit TGA images (backgrounds, maps, masks, interface)

TGA header (18 bytes, little-endian), every shipped `im16`:
| off | size | field | value |
|---|---|---|---|
| 0 | 1 | ID length | 0 |
| 1 | 1 | colour-map type | 0 |
| 2 | 1 | image type | 2 (uncompressed true-colour) |
| 3 | 5 | colour-map spec | 0 |
| 8 | 4 | x/y origin | 0,0 |
| 12 | 2 | width | |
| 14 | 2 | height | |
| 16 | 1 | bits per pixel | 16 |
| 17 | 1 | descriptor | `0x01` (1 attribute bit, bit 5 = 0 ⇒ rows stored bottom-up) |
Pixels: `w*h` little-endian u16, A1R5G5B5. Some files carry a 26-byte TGA 2.0 footer
(`…TRUEVISION-XFILE.\0`): `Background[back]`, `Menu[menu]` (614444 = 18+614400+26) and every
`Preview` (89396 = 18+89352+26). [HIGH — tool output of `list_paks.py --images` and `tail -c 26 | xxd`]

Sizes by role (tool census):
| role | count | size | per level |
|---|---|---|---|
| `… Map[xxm#]` terrain | 12 | 480×3600 (3456018 B) | `#backgroundImage_ID` |
| `… Media[xxt#]` media mask | 12 | 96×720 | `#mediaMask_ID` |
| `… Preview[xxp#]` | 12 | 146×306 | `#previewImage_ID` |
| `Scorebar[scor]` | 1 | 160×480 | |
| `Level Selection[lese]`, `Advertisment[adve]`, `Developer Credit[decr]`, `Background[back]`, `Menu[menu]` | 5 | 640×480 | |
| `Publisher Credit[pucr]` 260×342, `Editor Panel[edpa]` 112×480, `Editor Background[BIGR]` 284×173 | 3 | | |

Worked decode — Command: `xxd -l 64 "$D/Game/im16/Canyon 1 Media[cat1].TGA"`:
```
00000000: 0000 0200 0000 0000 0000 0000 6000 d002  ............`...
00000010: 1001 ff7f ff7f ff7f ff7f ff7f ff7f ff7f  ................
```
type 2, width `0x0060`=96, height `0x02d0`=720, 16 bpp, descriptor 1; first pixels `0x7fff`
(white). Pixel census (Python over all 12 masks): only `0x7fff` and `0x001f` occur (plus one
stray `0x256b` in Industrial 3).

### 3.1 Media mask semantics (`G_Background.cc`)
`FUN_1000fbc0 @ 1000fbc0` (level background load): requires the map TGA dimensions to equal the
level's `#background_RECT` width/height ("Background image dimensions do not match Level data"),
requires mask aspect ratio == map aspect ratio, and sets
`_DAT_100e0134 = mapWidth / maskWidth` (480/96 = **5**), asserting ≥ 1. [HIGH]
`FUN_1000fee0 @ 1000fee0` (is-water test):
```c
  local_18 = local_18 / _DAT_100e0134;            // x / 5
  iVar2 = local_14 / _DAT_100e0134;               // y / 5
  ... *(short *)(local_24 + iVar2 * local_28 + local_18 * 2) == 0x1f   // pure blue
```
→ a terrain point is "media" (water) iff its mask element is exactly `0x001f`. Callers spawn the
`MediaImpact_Water_*` units (`FUN_10016880` reads idli objects 6–9). [HIGH for the test; MED
for the water naming — the only media impact objects are `MediaImpact_Water_*`]
The mask is read in memory row order after QuickTime draws the bottom-up TGA, i.e. row 0 = top of
the map. [MED — QuickTime's TGA orientation handling not read]

## 4. `soun` — sound effects (Audio.pak, 96 entries)

Census (`list_paks.py --audio`, COMM chunks): **96 × AIFC, 1 channel, 16-bit, 44100 Hz,
compression `ima4`**. Music.pak: 3 × AIFC, 2 channels, 16-bit, 44100 Hz, `ima4`. [HIGH — tool]

Worked decode — Command: `xxd -l 64 "$D/Audio/Accuracy Bonus[acbo].IMA"`:
```
00000000: 464f 524d 0000 3acc 4149 4643 4656 4552  FORM..:.AIFCFVER
00000010: 0000 0004 a280 5140 434f 4d4d 0000 0028  ......Q@COMM...(
00000020: 0001 0000 01b4 0010 400e ac44 0000 0000  ........@..D....
00000030: 0000 696d 6134 1149 4d41 2031 3620 6269  ..ima4.IMA 16 bi
```
FORM size `0x3acc`, `AIFC`; FVER `0xa2805140` (AIFC v1); COMM size 40: channels 1, frames
`0x1b4`=436 (ima4 packets of 64 samples → 27904 samples, 0.633 s), sampleSize 16, rate =
80-bit `400e ac44 0000 0000 0000` = 44100, compression `ima4` "IMA 16 bit 4-to-1". Then INST and
SSND (offset 0, blockSize 0, 34-byte ima4 packets). [HIGH]

Loading: `FUN_10047330(id) @ 10047330` (M_Sound.cpp) fetches tag (`soun`,id) and converts it
with `FUN_100d1780`, which accepts AIFF/AIFC (`FUN_100d2360/2400`) or RIFF/WAVE
(`FUN_100d26d0/2750`), compression `NONE` or `ima4` only, and **channels < 2** (`local_2e < 2`,
else error -0x1b5b); `FUN_100d1d90` builds the playable sound (4CCs `asnd`, `ima4`, `mIMA`).
Playback: `FUN_10047bf0(id, …)` ("RESOURCE: Sound '%s' loaded/not found"), wrappers
`FUN_10047670(id, vol, ?, ?)` and `FUN_100475e0(soundSettings*)` (picks a random volume/pitch with
`FUN_10046580`). Channels: `SoundNumChannels` = 8 (flli 38) passed to `FUN_10047160`
("Sound Channels: %i"). [HIGH for format gates; MED for playback parameters]
⚑ corrected (wave 2, 2026-10-03): was "`FUN_10047670(id, vol, ?, ?)`" and "`FUN_100475e0` picks a random volume/pitch" —
the signature is `FUN_10047670(id, priority, volume, allowMultiple)` at pitch 1.0, and
`FUN_100475e0` uses volume = MinVolume (no draw); only the pitch is random — see sound-music.md §2.3
(also engine-loop.md §9).
The sound library at `0x100cfc90–0x100d3530` (Sound Manager glue: `SndNewChannel`,
`SndPlayDoubleBuffer`, `SndDoImmediate`, `GetCompressionInfo`) is a third-party/utility layer;
identified, not read further. ⚑ corrected (wave 2, 2026-10-03): was "identified, not read further" — it is a 16-voice
software mixer (ranked voice list, 8 audible, 44.1 kHz 16-bit stereo, IMA decode + resample) plus
an AIFC music streamer — see sound-music.md §1, §3, §6.

## 5. Music (Music.pak, streamed)

| tag | entry | size | form | used by (code) |
|---|---|---|---|---|
| `mu03` | `Music 3[mu03].aif` | 9172810 | AIFC 2ch 44.1k ima4, 134892 packets (195.8 s) | every level's `#music_ID` (12/12 levels) |
| `ammu` | `Ambient Music Loop[ammu].IMA` | 1629918 | AIFC 2ch, 23966 packets | `FUN_100234d0` before level select: `FUN_10047f90(0x616d6d75,1,0)` |
| `inmu` | `Interface Music Loop[inmu].IMA` | 2798658 | AIFC 2ch, 41153 packets | `FUN_100000e0` boot: `FUN_10047f90(0x696e6d75,1,0)` |
[HIGH — tool + literal 4CCs]
`FUN_10047f90(id, loop?, ?) @ 10047f90` (M_Music.cpp) asks the tag index for the zip PATH and
byte range (`FUN_10002080(0x736f756e,id,path,&off,&len)`), makes an FSSpec, then
`FUN_100cfe64(spec, off, len, bufSize, …)` streams it (`FSpOpenDF`, `SetFPos`, `FSRead`,
`SndPlayDoubleBuffer`); buffer size `SoundSpoolBufferSize` = 204800 (flli 37, `FUN_10047e40`).
Music is never loaded whole. [HIGH for the call chain; MED for argument meanings]
The level-music hook `FUN_10047f90(local_564,1,0)` in `FUN_100051a0` plays the level's music
when the game appears (game time == flli 18). [MED]

## 6. Fonts
No font files: text is drawn with sprite groups. `idli/Fonts[tesp]` lists `#Standard <tesm>`,
`#2 <tesm>`, `#3 <tesm>`; `tesm` = `Interface.pak:im08/Text - Small IC[tesm].gif` + `IA[TESM]`.
Character→frame table: data-tags.md §5. Text appearance comes from `tefo` records. [HIGH for
the files; MED for "all in-game text uses tesm" — G_Text draw path only partly read]
