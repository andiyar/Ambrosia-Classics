# Ferazel's Wand 1.0.3 — world data format (`Ferazel's Wand World Data`)

Register: **code readings + data decodes only; nothing is behaviour-verified.** Every claim carries
a label: `[HIGH]` read directly in code with constants resolved and the data path traced;
`[MED]` read in code but one link inferred; `[LOW]` pattern/string inference. Function addresses
are `name @ addr` in `ghidra/Ferazel_pef.decompiled.c` (main dump) or, for the 154 sprite
callbacks Ghidra missed, in the supplementary dump produced by `docs/ferazel/tools/FzDecompTargets.java`
(see INDEX §Provenance). "hdr" = the locked `Mlvl` handle (`*(int*)*_DAT_100a0058`).

Paths below: `$FW = /Users/andiyar/Developer/Ambrosia/Resources/ambrosia-extracted/Action-Adventure/Ferazel's Wand/Ferazel's Wand (installed)/files`.

## 1. The numbered files are music, not levels  [HIGH]

The 28 files `01`..`30` (no `21`, no `27`) are AIFF-C music, not level data:

```
$ xxd -l 64 "$FW/01"
00000000: 464f 524d 001d 8966 4149 4643 4656 4552  FORM...fAIFCFVER
00000010: 0000 0004 a280 5140 434f 4d4d 0000 0028  ......Q@COMM...(
00000020: 0002 0000 6f2f 0010 400d ac44 0000 0000  ....o/..@..D....
00000030: 0000 696d 6134 1149 4d41 2031 3620 6269  ..ima4.IMA 16 bi
```
All 28: 2 ch, 16-bit, 22050 Hz, `ima4` (census in INDEX). Their `.rsrc` forks (4,565 B each) hold
only `PRNT`/`STR `/`WNDW`/`icns` (SoundEdit 16 leftovers). The installer manifest types them
`AIFC`/`Nqst`.

Use site: `.SetAIFFMusic @ 10049388` builds the path `:Ferazel's Wand Music:NN` (pstr at
`0x100a5be3`, two digits, zero-padded when `< 10`), opens it with QuickTime
(`OpenMovieFile`/`NewMovieFromFile`/`LoadMovieIntoRam`/`StartMovie`, looping time-base flag 1),
so the shipped install puts these files in a folder named `Ferazel's Wand Music` [HIGH, string +
call chain]. Track index clamp: `n < 1 || n > 0x20 → n = 1`; if the open fails and `n > 1` it
recurses with `n-1` [HIGH].

Track numbers the code/data reference [HIGH, from the call sites + `Mlvl+0x284a` census §3.2]:
- 24 (`0x18`) main menu (`.main`, `.NewGame`, `.ContinueGame`), 25 (`0x19`) world map
  (`.ShowWorldMap`), 29 (`0x1d`) victory (`.Victory`), 30 (`0x1e`) the boss/lock-screen override
  in `.GameLoop` (see engine.md §4).
- per-level `Mlvl+0x284a`: 1,2,3,4,5,6,8,9,10,12,13,15,16,17,18,22,23,26,28.

Why 21 and 27 are missing: **no code path or shipped level references them** (the level table
never names 21/27; the constants above are 24/25/29/30) [HIGH for "not referenced by the 24
shipped levels or by any constant SetAIFFMusic argument"; the commercial reason is unknown —
~~NOT RESOLVED~~ facts closed (never catalogued by the installer, never requested, fallback n−1), the
reason UNDETERMINABLE — rendering-omnipx-titles §6.4 ⚑ wave 2 corr (2026-10-04) RO #12]. Tracks 7, 11, 14, 19, 20 exist but are likewise unreferenced by any constant
or by the 24 levels [HIGH, same evidence]. (The CD volume dump has no AIFC files of its own;
its 66 whitespace-named entries are 0-byte — checked with a Python listing in this session.)

## 2. The world file: resources

`$FW/Ferazel's Wand World Data.rsrc` is the resource fork (data fork is 0 bytes; installer type
`Mwld`, creator `Msct`). Header bytes:

```
$ xxd -l 16 "$FW/Ferazel's Wand World Data.rsrc"
00000000: 0000 0100 0054 1299 0054 1199 0000 066d  .....T...T.....m
```
data offset 0x100, map offset 0x541299, data length 0x541199, map length 0x66d. Census (types,
counts, size ranges) is in INDEX. Loader routines:

| resource | id(s) | loader | what the code reads |
|---|---|---|---|
| `Mwld` | 0 | `.OpenDefaultWorld @ 10048fb8`, `.OpenWorld @ 10048de0` (`GetResource('Mwld',0)`, detached into `_DAT_100a005c`) | +0x100 (stamp), +0x1c4 (start level) |
| `Mlvl` | level number (1..70 in data) | `.OpenDefaultWorldLevel @ 10048ac0` (`GetResource('Mlvl', n)`, detached into `_DAT_100a0058`, `HLock`, then `.SetupLevelTilemapPtrs`) | §3 |
| `Mmap` | 200 | `.OpenDefaultWorldMap @ 10048940` (called by `.InitPlayerMapData @ 1007aa88` with 200) | §5 |
| `Mcnv` | conversation id | `.OpenDefaultWorldConv @ 100487d4` (from `.Conversation @ 1007a7e8`) | §6 |
| `STR#` | 1000 "level names" | `.InitMapLevelNames @ 1007ad84`: `GetIndString(buf, 1000, i)` for i=0..99 into 256-byte slots at `_DAT_100a0c34` | map/status-bar names |
| `STR#` | 500 "signs" | 19 sign texts; read by `.HitPlayerSprite` for sign sprites (§3.4) | [HIGH] |
| `PICT` | 7000 | `.ShowWorldMap` draws `PICT 7000` (608×384 world-map art; the app fork holds another 608×384 `PICT 7000`) [MED: resource-chain order decides which one is drawn] ⚑ corrected (deepening 2026-10-03): the **app fork's** copy is drawn; the World Data copy is dead (they differ in a 63×86 region) — save-continue §8.4 [MED] | |

All loaders open the world file by name (`_DAT_100a0060` ← `"Ferazel's Wand World Data"`, pstr
at `0x100a2714`, copied in `.InitAppGlobals`) or via the FSSpec saved by `.OpenWorld` when the
user picked a different `Mwld` file [HIGH]. Out of scope: the "pick another world file" path
(`.OpenWorld` with a `PromptGetFile` for type `'Mwld'`) is an authoring/third-party-world
affordance — record only.

### 2.1 Mwld id 0 "Mascot World" (70,664 B)  [HIGH for the two used fields]

| off | type | value in shipped file | read by |
|---|---|---|---|
| 0x000 | pstr[256] | `\x09Teraknorn` (+ stale bytes `orld name here>`) | nothing found |
| 0x100 | u32 | 0x152be0ed | world identity stamp: copied to save +0x00 by `.DoSaveGame/.SavePointSave/.EndLevelSGUpdate`, compared on resume by `.ContinueGame` |
| 0x144 | i16 | 2 | no reader found |
| 0x1c4 | i16 | 1 | start level for New Game (`.NewGame @ 1000b11c`) — ⚑ corrected (review 1c, 2026-10-03) (adjudication B20): read only with the debug flag or a non-default world; the shipped path loads literal 1 (§4.1) |
| 0x1c6 | i16 | 100 | no reader found |
| rest | | zero | |

```
$ xxd -s 0x4a02b1 -l 0x20 "$FW/Ferazel's Wand World Data.rsrc"     # Mwld body starts at 0x4a02b1
$ xxd -s $((0x4a02b1+0x100)) -l 4 ...  → 152b e0ed
$ xxd -s $((0x4a02b1+0x1c4)) -l 4 ...  → 0001 0064
```
(Body offset computed by walking the resource map; script `docs/ferazel/tools/rsrc_census.py`.)

## 3. `Mlvl` — one level per resource

24 `Mlvl` resources: ids 1,2,3,4,5,10,11,15,18,20,21,22,25,30,31,40,45,50,51,52,55,62,67,70
(names in INDEX census). The resource **id is the level number** used everywhere
(`_DAT_1009feac` current level, map node `+0x102`, save `+0x08`, `STR# 1000` index) [HIGH].

### 3.1 Overall layout  [HIGH]

`.SetupLevelTilemapPtrs @ 1004913c`:
```c
iVar2 = hdr + 0xb29c;  *(hdr+0xb284) = iVar2;                         // PxBack map
iVar2 += w(0xb278)*h(0xb27a)*2;  *(hdr+0xb288) = iVar2;              // PxMid map
iVar2 += w(0xb27c)*h(0xb27e)*2;  *(hdr+0xb28c) = iVar2;              // BG map
iVar2 += w(0xb280)*h(0xb282)*2;  *(hdr+0xb290) = iVar2;              // FG map
iVar2 += w(0xb280)*h(0xb282)*2;  *(hdr+0xb294) = iVar2;              // map #5 (unused)
*(hdr+0xb298) = iVar2 + w(0xb280)*h(0xb282)*2;                      // overlay map
```
So: fixed header 0xb29c (45,724) bytes, then PxBack `w0×h0` u16, PxMid `w1×h1` u16, then four
main-grid maps `w2×h2` u16. Checked against all 24 resource sizes: `len − 0xb29c − 2(w0h0+w1h1)`
is exactly `4 × 2·w2·h2` for every level (Python loop over the extracted bodies, this session).
The 4-byte pointers at 0xb284..0xb298 are runtime fields (stale values in the file).

Map #5 (`hdr+0xb294`): no reader anywhere in either dump (xref of offset 0xb294 finds only
`.SetupLevelTilemapPtrs`), and it is all-zero in all 24 levels → **unused** [HIGH].

### 3.2 Header field table

Census values are from all 24 levels (Python dump of each field, this session).

| off | type | meaning | use site(s) | label |
|---|---|---|---|---|
| 0x0000 | u32 | 0x04277dc9 in every level | no reader found | [HIGH] unused |
| 0x0004 | rec[511] ×16 B | sprite placement records (§3.4) | `.SetupLevelSprites @ 10003cd0`, `.UpdateSprites @ 1000982c`, saves | [HIGH] |
| 0x1ff4..0x25c3 | | zero in all levels | none | [HIGH] unused |
| 0x25c4 | pstr[256] | level display name | written by `.ShowWorldMap` from `STR# 1000`; drawn by `.UpdateTextStats` | [HIGH] |
| 0x26c4 | i16 | map-node level number (= own id in all 24) | `.ShowWorldMap`: `FindCurrNode(hdr+0x26c4)` | [HIGH] |
| 0x26c6 | u8 | "draw submerged tiles as tinted faces" flag (=1 only in 11) | `.PlainWrapFGTile`, `.PlainWrapFGOverlayTile`, `.RedrawScrollGrid` | [MED] |
| 0x26c7 | u8 | OmniPx mode (0,1,2,5,6) | `.SetupOmniPx`, `.TurnOnOmniPx`, `.UpdateOmniPx`, `.PaintFrameWrap` | [MED] meaning NOT RESOLVED — ⚑ corrected (deepening 2026-10-03): narrowed per mode (1 rain + overlay faces 6000/6001, level 15; 2/5 faces 6200/6201 and 6300/6301 with an animated port; 6 interlaced 29 frames, level 70); ~~draw composition still open (save-continue §8.3)~~ closed: rendering-omnipx-titles §3.3–§3.5 (raw `10019f88..1001a148`, `1001a434..1001a834`) ⚑ wave 2 corr (2026-10-04) RO #6 |
| 0x26c8 | u8 | copied to game-globals +0x16 at level start | `.NewGame`, `.ContinueGame` | [HIGH] copy; meaning NOT RESOLVED — ⚑ corrected (deepening 2026-10-03): **player starts facing left** (`.SetupPlayerSprite` sets `+0x17e = G+0x16 ≠ 0`); 1 in levels 3, 5, 11, 18, 40, 45, the six that start at the map's right edge [HIGH]; a resumed session never refreshes it from the header (save-continue §8.3, player-states §6). ⚑ corrected (review 1b, 2026-10-03) #13: raw — `lbz 0x26c8` at `1000b3d8` (`.NewGame`) and `1000d684` (`.ContinueGame`) → `G+0x16`; read by `.SetupPlayerSprite` `1004b2b0..1004b2d0` (`≠ 0 → +0x17e = 1`) [HIGH, re-derived by review 1c] |
| 0x26c9 | u8 | water-surface effect flag | `.WrapDrawWaterEffects` | [MED] |
| 0x26ca | u8 | parallax ripple flag | `.RipplePxBackOffsets`, `.DoubleBlitPPCParallaxOneLayer` | [MED] |
| 0x26cb | u8 | FG pattern tile period: 0 → 8×8, ≠0 → 6×6 | `.GetFGPatternTile @ 1003c0b8` | [HIGH] |
| 0x26cc | u8/i16 | px tilesets use sprite CLUT (`_DAT_1009ff94 ← _DAT_1009ff8c`) when ≠0 | `.LoadPxBackTileset`, `.LoadPxMidTileset`, `.MTAddPxSprite` | [MED] |
| 0x26cd | u8 | level-wide "in liquid" behaviour flag (=1 in 30,31) | `.HandlePlayerSprite`, `.SetupBackgroundSprite`, `.SetupBoxSprite`, `.SetupFrogSprite` | [LOW] |
| 0x26d0 | u8 | level has its own `snd ` set in the world file | `.LoadLevelSounds @ 100333d4` | [HIGH] (0 in all levels) |
| 0x2706 | i16 | ~~ambient darkness (0..5)~~ **enable flag** for per-cell darkness (values 1, 2, 5 all just enable; the darkness is the BG-cell high byte − 1) ⚑ wave 2 corr (2026-10-04) LT #5 | `.GetAmbDarkVal @ 1001aaf8`, `.DrawLightOverFace`, `.DrawParticles`, copied to globals+0x22 in `.SetupLevel` | [HIGH] (lighting-tables §7.1) |
| 0x270a/0x270c | i16 | camera target offsets x/y added to the player-centred target (x: 0 everywhere; y: −30 in 11, −108 in 18, 36 in 25, −80 in 67) | `.FindUpperLeftCorner` | [HIGH] |
| 0x270e | i16 | landing/"hard-ground" damage (112,150,56,100; 0 → 0x70) | `.HandlePlayerSprite` (`+0xd8 == 2` branch) | [MED] — ⚑ planner-probe (Phase 2 plan A10, landed by F3 2026-10-10; M l. 45106–45123): **damaging-surface damage, not landing damage** — right after `.ApplySpeedAndSeparateFromTiles`, `+0xd8 == 2` (material 2 = FG kind 2xx stood on) ∧ `+0x116 == 0` ∧ not dying → HP −= hdr+0x270e (0 → 0x70) every such frame, `+0x116 = 0x3c`, `+0xaa = 0x12`, hurt sound; no landing speed is read [HIGH] |
| 0x2710 | i16 | ice slipperiness: ground friction = (256−v)·800>>8 (100 in 1,2; 80 in 11,18; 220 in 30,31) | `.HandlePlayerSprite` (`+0xd8 == 3`) | [HIGH] |
| 0x2712 | i16 | gamma fade-in on level start | `.GameLoop` | [HIGH] (0 in data) |
| 0x2714 | i16 | water-current push, 1/256 px/frame (550, 470, −512, 768) | `.StandardSpriteHandles`, `.WrapDrawWaterEffects` | [HIGH] |
| 0x2716/18/1a | i16×3 | parallax sprite: PICT id, ?, ? (265/128/222 …) | `.SetupLevel → .MTAddPxSprite(id, a, b)`; 0x271a also `.BuildSineTable` | [MED] — ⚑ corrected (deepening 2026-10-03): Backgrounds PICT id of a 768-px horizon strip / its x-parallax factor (/256) / base y (+232), tiled across the level as `Px` sprites (triggers-background-2 §4) [HIGH arithmetic] |
| 0x271c | i16 | alternate CLUT id (0 in data) → `.AltClutMod` | `.SetupLevel` | [HIGH] |
| 0x271e | i16 | parallax mode flag | `.DoubleBlitPPCParallaxOneLayer`, `.PaintFrameWrap` | [MED] (0 in data) |
| 0x2722 | i16 | fire/flame mode (0; 1 in 52; 2 in 55) | `.SetupLevel` (pre-runs `FlameAddLine/FlameUpdate` 59/60 times), `.PaintFrameWrap`, `.DoubleBlitPPCParallaxOneLayerFire`, `.HandleEnemyShotSprite` | [HIGH] (setup) |
| 0x2724 | i16 | boss-arena camera bound x: >0 right edge, <0 left edge (|v|); also triggers track 30 (engine.md §4) | `.FindUpperLeftCorner`, `.GameLoop`, `.PlayerConstraints` | [HIGH] — ⚑ corrected (deepening 2026-10-03): the player lock line is `|v| ∓ 60`, applied only while a boss is alive (`_DAT_1009fed0 == 0`); level 55's 16000 never locks (bosses §1.3, bosses-2 corr. 5) |
| 0x2726 | i16 | auto-scroll x speed (1/256 px/frame) (768 in 51) | `.SetupLevelSprites`, `.FindUpperLeftCorner` | [HIGH] |
| 0x2728 | i16 | auto-scroll y speed (640 in 52) | same | [HIGH] |
| 0x272a | i16 | auto-scroll enable | `.SetupLevelSprites` | [HIGH] |
| 0x272c | i16 | constant side push on the player (−320 in 15, Storm Valley): airborne vx drifts toward 5·v, grounded x += v/4 per frame (physics.md §4) | `.HandlePlayerSprite` | [HIGH] |
| 0x272e | i16 | second arena bound (−640 in 18, 1384 in 25, −448 in 55) | `.FindUpperLeftCorner` | [MED] — ⚑ corrected (deepening 2026-10-03): applied only after the lock; arithmetic in bosses §1.3 [HIGH there] |
| 0x2730..0x2736 | i16×4 | CLUT animation ⚑ wave 2 corr (2026-10-04) LT #6 = B3 #W1: 0x2730 **mode** 1..7 · 0x2732 **count** n of animated entries (indices 255 − n .. 254) · 0x2734 **period** P in frames · 0x2736 **amplitude** A (12000 in the data); non-zero only in L50 (1, 48, 180, 12000), L51 (1, 48, 56, 12000), L67 (3, 16, 75, 12000) | only reader `.AnimateCLUT` (`10011850..10011860`); only writer `.HandleXichraSprite` (`1008e6d0..1008ebcc`) | [HIGH] (lighting-tables §1.5, bosses-3 §9.1–§9.2) |
| 0x273c | i16 | chapter-screen number shown on entry (1..7) | `.GameLoop → .ChapterScreen` while `G+0x176+2·L == 0`, i.e. no checkpoint save **or** completion recorded for the level yet (engine.md §9) ⚑ corrected (review 2026-10-03) #1 | [HIGH] |
| 0x2846 | i16 | player start y (px) | `.NewGame`: `GameLoop(x−32, y−32, …)` | [HIGH] |
| 0x2848 | i16 | player start x (px) | same | [HIGH] |
| 0x284a | i16 | music track number | `.GameLoop → .SetAIFFMusic` | [HIGH] |
| 0x284c | i16 | PxBack tileset PICT (<1 → 5000) | `.LoadLevelTilesets @ 10003098` | [HIGH] |
| 0x284e | i16 | PxMid tileset PICT pair id, id+1 (0 → none) | same | [HIGH] |
| 0x2850 | i16 | FG tileset PICT (0 → 181); also the FG-water tileset | same | [HIGH] |
| 0x2852 | i16 | BG tileset PICT (0 → 180) | same | [HIGH] |
| 0x2856 | i16 | FG pattern tileset PICT (<1 → 206) | same | [HIGH] |
| 0x285c | i16 | level CLUT (0 → 201) | `.SetupLevel` | [HIGH] |
| 0x285e | i16 | level+sprite CLUT (0 → 202); becomes the screen CLUT | `.SetupLevel` | [HIGH] |
| 0x2860 | i16 | physics override flag | `.LoadLevelPhysics @ 1000332c` | [HIGH] (0 in all 24) |
| 0x2862..0x286a | i16×5 | physics values (see physics.md §1: written, never read) | same | [HIGH] |
| 0x28e0 | i16[96] | FG tile → kind table | `.LoadTileDefinitions @ 10041dcc` | [HIGH] |
| 0x29a0 | i16[96] | BG tile → kind table | same | [HIGH] |
| 0x3268 | i16 | ~~parallax enable (1 in 16 levels)~~ **PxMid enable**: 1 in **14** levels, exactly those with hdr+0x284e ≠ 0 (10, 15, 21, 22, 30, 31, 40, 45, 50, 51, 52, 55, 62, 70) ⚑ wave 2 corr (2026-10-04) RO #3 | `.DoubleBlitPPCParallaxOneLayer` (`1001890c lha r3,0x3268(r3); cmpwi r3,0x1`) | [HIGH] |
| 0x326c | i16[8192] | PxBack per-scanline x-parallax factor (/256) | `.DoubleBlitPPCParallaxOneLayer`, `.CalcPxRowContents`, `.TurnOnOmniPx` | [HIGH] |
| 0x726c | i16[8192] | PxMid per-scanline x-parallax factor (/256); also the row-mode selector: 0 = back row, ≠ 0 = mid row (if 0x3268 = 1); shipped values 0 / 384 / 128 ⚑ wave 2 corr (2026-10-04) RO #4 (rendering-omnipx-titles §1.3 step 6, §1.5) | same | [HIGH] |
| 0xb26c | i16 | PxBack y-parallax factor (/256) | same | [HIGH] |
| 0xb26e | i16 | PxMid y-parallax factor (/256) | same | [HIGH] |
| 0xb270..0xb276 | | ~~0x20,8,0x20,8 in level 1~~ ⚑ corrected (deepening 2026-10-03): **zero in all 24 levels**, no access in the code; the quoted values are 0xb278..0xb27e (this file's own xxd below: `004f4f8d` = +0xb270 starts with 8 zero bytes) (save-continue §8.3) | no reader found | [HIGH] unused |
| 0xb278/0xb27a | i16 | PxBack map w,h (tiles of 128 px) | §3.1 | [HIGH] |
| 0xb27c/0xb27e | i16 | PxMid map w,h | §3.1 | [HIGH] |
| 0xb280/0xb282 | i16 | main grid w,h (tiles of 32 px) | §3.1, all Get*Tile | [HIGH] |
| 0xb284..0xb298 | ptr×6 | runtime map pointers | §3.1 | [HIGH] |

Other bytes in 0x26c4..0x2846 and 0x284c..0x28e0 not listed: zero in all 24 levels or no
reader found (NOT RESOLVED). Default-tileset fallbacks (5000, 181, 180, 206) are reached only
when the field is ≤0; all 24 levels name their tilesets explicitly (census row above).

Worked decode, level 1 (`Mlvl 1` body at file offset 0x4e9d1d):
```
$ xxd -s $((0x4e9d1d+0x2840)) -l 0x30 "$FW/Ferazel's Wand World Data.rsrc"
004ec55d: 0000 0000 0000 00af 0073 0001 00cf 0000  .........s......
004ec56d: 00c8 00cb 0000 00ce 0000 0000 00c9 00ca  ................
```
→ 0x2846 start y = 0x00af = 175, 0x2848 start x = 0x0073 = 115, 0x284a music = 1,
0x284c PxBack = 0x00cf = 207, 0x284e PxMid = 0, 0x2850 FG = 0x00c8 = 200, 0x2852 BG = 0x00cb =
203, 0x2856 pattern = 0x00ce = 206, 0x285c CLUT = 0x00c9 = 201 ('earthcav'), 0x285e = 0x00ca =
202 ('base + earthcav'). `PICT 207` is 768×768 = 6×6 tiles of 128 (Backgrounds census).
```
$ xxd -s $((0x4e9d1d+0xb260)) -l 0x40 "$FW/Ferazel's Wand World Data.rsrc"
004f4f7d: 0080 0080 0080 0080 0080 0080 004a 0080  .............J..
004f4f8d: 0000 0000 0000 0000 0020 0008 0020 0008  ......... ... ..
004f4f9d: 00c8 0032 04a0 643c 04a0 663c 04a0 683c  ...2..d<..f<..h<
```
→ 0xb26c PxBack y-factor 0x4a = 74/256, 0xb26e PxMid y-factor 0x80, 0xb278.. dims 32×8, 32×8,
200×50 (main grid = 6400×1600 px). The PxMid factor table is all 0x0080 (= ½).

### 3.3 Tile maps — per-cell encoding  [HIGH]

All maps are row-major u16 big-endian, `cell = map[y*w + x]`. Getters clamp `x,y` into the map
with `.ConstrainXY @ 1003be0c` (no wrap) [HIGH]. ⚑ wave 2 corr (2026-10-04) EW W2: every `.Get*Tile(a, b)` that goes through
`.ConstrainXY` takes **(column, row)** — raw-shown for `.GetBGTile` (`1003c204..1003c27c`: cell = b·w + a)
[HIGH]; the other getters not re-checked (enemies-water-cave §7.3).

| map | getter @ addr | decode |
|---|---|---|
| PxBack (`hdr+0xb284`, w0×h0, 128-px tiles) | `.GetPxBackTile @ 1003c4d8` | whole u16 = tile index into the 36-tile PxBack set; returns 0 while globals+0x174 (OmniPx active) |
| PxMid (`hdr+0xb288`, w1×h1) | `.GetPxMidTile @ 1003c59c` | whole u16 = index into the 12-tile PxMid set (0xFFFF present in every level; ~~how −1 is handled at draw time NOT RESOLVED~~ no test: reads entries [−1] (PxBack port 35 / PxMid image port 11); never reached with shipped data; harmless on back rows — rendering-omnipx-titles §2 ⚑ wave 2 corr (2026-10-04) RO #5) |
| BG (`hdr+0xb28c`) | `.GetBGTile @ 1003c204` / `.GetLightTile @ 1003c2b4` | low byte −1 = BG tile 0..95 (−1 = none); high byte −1 = light level (data: 0..11) |
| FG (`hdr+0xb290`) | `.GetFGTile @ 1003be90`, `.GetFGCrunchKindTile @ 1003bffc`, `.GetFGCrunchDirTile @ 1003bf40` | bits 0-7 −1 = FG tile 0..95 (−1 none; 95 = "pattern" tile); bits 8-11 crunch kind; bits 12-15 crunch dir/state (written by `.SetFGCrunchDirTile`, clamped 0..15) |
| overlay (`hdr+0xb298`) | `.GetFGOverlay1Tile @ 1003c368` / `.GetFGOverlay2Tile @ 1003c420` | low byte −1 = o1, high byte −1 = o2. o1 0..15 → ~~wind/current direction with strength o2~~ **wind** (no current meaning) toward o1·10° counter-clockwise from right (9 = up), magnitude o2·14 per frame (×`+0x90`/256), test threshold o2·15 (`.StandardSpriteHandles`; ⚑ wave 2 corr (2026-10-04) T2 W2, triggers-background-2 §8.4); o1 = 100 → draw FG-tileset tile o2 over sprites; o1 = 101 → BG-tileset tile o2; o2 ≥ 95 → draw the pattern tile (`.PlainWrapFGOverlayTile`) |

`.SetFGTile` writes `(cell & 0xff00) + (tile+1)` [HIGH]. FG/BG tile → collision kind via the
header tables (`.LookupFGTileKind`/`.LookupBGTileKind`, index 0..95, else −1); after
loading, FG kinds 0x50..0x5f are overwritten with the identity 80..95 (`.LoadTileDefinitions`)
[HIGH]. Kind semantics → physics.md §3.

Worked decode, level 1 main grid at file offset 0x4f53b9 (BG), 0x4fa1d9 (FG), 0x4feff9 (map #5),
0x503e19 (overlay) — offsets computed from the dims above; the four maps end exactly at the
resource end 0x508c39. Census over level 1 (Python, this session): BG low byte ≤ 96 in all
cells, high byte 1..12 in all 10,000 cells; FG 7,274 non-zero cells, crunch-kind nibble set in 3;
map #5 all zero; overlay 20 non-zero cells with low byte 101 (o1 = 100 → FG tile drawn over).

### 3.4 Sprite placement record (16 bytes at hdr+4+16·i, i < 511)  [HIGH]

| rec off | hdr off | type | meaning | evidence |
|---|---|---|---|---|
| +0x0 | +0x4 | u8 | 1 = spawn; cleared to 0 when the sprite dies/collected (`.UpdateSprites` writes `+4 = 0`) | `.SetupLevelSprites` `*(char*)(rec+4) == 1` |
| +0x1 | +0x5 | u8 | no reader found | NOT RESOLVED — ⚑ corrected (deepening 2026-10-03): 0 in every active record and read by no class (all class readers, coverage.md §3) [HIGH] |
| +0x2 | +0x6 | i16 | sprite type (→ class table §3.5) | same, `GenerateSprite(...,type,...)` |
| +0x4 | +0x8 | i16 | param 1 | per-class Setup routines (xref list below) |
| +0x6 | +0xa | i16 | param 2 | |
| +0x8 | +0xc | i16 | param 3 | |
| +0xa | +0xe | i16 | param 4 | |
| +0xc | +0x10 | i16 | y (px, sprite top-left) | `GenerateSprite(rec+0xe, rec+0xc, …)`; `.UpdateSprites` writes `+0x10 ← sprite+0xa` |
| +0xe | +0x12 | i16 | x (px) | `.UpdateSprites` writes `+0x12 ← sprite+0xc` |

Spawn order (`.SetupLevelSprites`): first every record of type 0x51b, then types 0x578..0x595
(platforms), then everything else [HIGH]. Records are live: `.UpdateSprites` copies each
sprite's current type/x/y back into its record every frame unless sprite flags +0x188/+0x189/
+0x18a are set, and clears `+0` when the sprite is destroyed [HIGH]. Saves snapshot the whole
511-record block per level (engine.md §8).

Params by class (which Setup/Handle reads `hdr + idx·16 + {8,10,0xc,0xe}`): Background, Box,
Platform (`.DoSetupPlatformSprite` 40 reads), Bonus, Walker, Crawler, Roach, Floater, Frog,
Dillo, Crab, Chief, Demon, Warrior, Bat, `.SetupProgrammedPath`, `.HitPlayerSprite` (17 reads of
param 1 — triggers/exits) [HIGH for the existence of the reads, awk over both dumps]. The
per-class meaning of each param is **NOT RESOLVED** (needs one pass per Setup routine), except
these talker/trigger types read in `.HitPlayerSprite` [HIGH]. ⚑ corrected (deepening 2026-10-03) — per-class meanings now
live in the deepening files (the readings stay there; this is the index):

| class (types) | params p1..p4 (summary) | file § |
|---|---|---|
| Walker (1700..1769) | p1 bomb type (1760), p3 tier → HP / cooldown / palette / coins | enemies-ground §1, §3.1 |
| Crawler / Roach / Dillo | Crawler p1 ceiling/floor, p2 HP; Roach none; Dillo by type | enemies-ground §4–§6 |
| Bat / Gremlin / Floater | Bat p1 < 0 → background bat (harmless, uncounted), path params (physics-sprites §8.5) | enemies-flyers §6 |
| Frog / Salamander / Blob / Crab | Frog p1 = variant (HP, tint, score); Crab p1 = reach; others none | enemies-water-cave §0 |
| Warrior / Wizard / Chief / Demon / Xichra | p4 = boss flag; Demon p3 = partner offset; Warrior/Wizard p2 written 150, unread | bosses §1.1 |
| Bonus (1055..3248) | per type (scroll p1, sphere p2 duration, containers p4 = spent, trigger 1058) | pickups-boxes §1.3, §1.10 |
| Box (1060..3099) | per type (doors p1/p4, chests p3, crates p1..p3, gates/blocks rec(p1/p2).p4, geysers p1..p4, pipes p1/p2, signs/talkers p1/p4) | pickups-boxes §2.2, §2.4 |
| Button (1320..1329) | writes its own p4 (pressed); p1 = 1 latches | triggers-background §1 |
| Background (1090..3249) | cannons p1 mode, passages p1 = partner record / p2 darkness, spikes p1..p3, fire p1 tint, exits p1/p2 | triggers-background §2 |
| Platform (1400..1429) | p1 mode, p2 radius/travel/count, p3 speed, p4 start angle/offset; catapult p1 = 2 non-solid | platforms-ropes-radial §2.2, §2.9 |
| Rope (3020..3039) | p1..p4 = absolute end points (x1,y1,x2,y2) | platforms-ropes-radial §3.3 |

Read in `.HitPlayerSprite` [HIGH]:
- type 2902 (0xb56) **sign**: on first touch (param 4 == 0) or UP, with a 90-frame cooldown,
  if param 1 > 0 → `GetIndString(STR# 500, param1)` from the world file, shown by
  `.SimpleConv` titled "Wooden Sign"; param 4 is then set to 1 ("read").
- types 2903..2909 except 2907, and 2833..2836 (0xb11..0xb14): same trigger; if param 1 > 100 →
  `.Conversation(Mcnv id = param1, record index, sprite)`.
- type 2907 (0xb5b): timer trigger, `iRam100a5110 = param1·30 − 1` (frames).
- type 3249 (0xcb1, Background class, 48 placements) **level exit**: sound, map exit index
  `uRam100a5116 = param1`, second exit `_DAT_100a5118 = param2` when ≠ 0, then
  `_DAT_100a0088 = 1` (level complete).

Census (all 24 levels): 5,641 active records, 243 distinct types, 48 records with flag 0 but a
type, one record with flag 99 (Python, this session).

Worked decode (level 1, first two records):
```
$ xxd -s $((0x4e9d1d+4)) -l 32 "$FW/Ferazel's Wand World Data.rsrc"
004e9d21: 0100 0b6a 0000 0000 0000 0000 029a 154f  ...j...........O
004e9d31: 0100 0b56 000c 0000 0000 0000 01b7 0196  ...V............
```
rec0: active 1, type 0x0b6a (2922 → Box class), params 0,0,0,0, y 0x29a = 666, x 0x154f = 5455.
rec1: type 0x0b56 (2902 → Box class, a sign), param1 12 → `STR# 500` string 12 (1-based
`GetIndString(buf, 500, param1)` in `.HitPlayerSprite`): "The sign reads, “Sparkly torches and
roc…" — **not** the spin-jump hint, which is string 13 ⚑ corrected (review 2026-10-03) #4;
y 439, x 406.

### 3.5 Sprite type → class (setup callback)  [HIGH]

`.GenerateSprite @ 10003478(x, y, type, recIndex, forceNow, layer)` selects a Setup callback
(TOC TVector → code; names from PEF traceback tables) by type range, and either spawns now
(`MTNewSprite`) or queues an *idle* sprite (`.AddIdleSprite`, activated later by
`.HandleIdleSprites`) [HIGH]. Mechanical transcription: `docs/ferazel/tools/gensprite_map.py`.

| type range (dec) | class (`.Setup<Class>Sprite`) | spawn |
|---|---|---|
| 1055,1056, 1058,1059, 1303, 1290..1299, 1307 | Bonus | idle |
| 1330..1350 (0x532..0x546) | Bonus | now |
| 2000..2049, 3050, 3100..3109, 3200..3248 | Bonus | idle |
| 1080,1081 | Box | now |
| 1060..1062, 1065, 1070..1072, 1075, 1250..1279, 3070, 1308, 2805..2889, 2902..2909, 2910,2911, 2920..2949, 2951..2999, 3090..3099, 1440..1449, 1460..1479 | Box | idle |
| 1450..1459, 1490..1499 | Box | now |
| 1090..1099 | Background | idle, or now if param1 < 0 |
| 1150..1159, 1208, 1840..1843 (now), 1855..1859, 1900..1909, 2700..2799, 2900,2901, 3000..3019, 3060, 3080..3089, 3249 | Background | idle (1840..1843 and 1480..1489 and 2890..2899: now) |
| 1400..1429 (0x578..0x595) | Platform | now |
| 1320..1329 | Button | idle |
| 1700..1709, 1750..1769 | Walker | idle |
| 1712 | Crawler | idle |
| 1720 | Roach | idle |
| 1730..1739 | Blob | idle |
| 1740..1749, 1850..1854, 1860..1869 | Bat | idle |
| 1770..1779 | Gremlin | now |
| 1780..1799 | Floater | idle |
| 1800..1809 | Frog | idle |
| 1810..1819 | Salamander | idle |
| 1820..1829 | Warrior | now |
| 1830..1839 | Wizard | idle |
| 1870..1879 | Dillo | idle |
| 1890..1899 | Crab | idle |
| 1910..1919 | Chief | idle |
| 1920..1929 | Demon | now |
| 1990..1999 | Xichra | now |
| 3020..3039 | Rope | idle |
| 1830 is inside the 1700..1839 sub-chain (Wizard), so the later `type == 0x726 → Effect` arm is dead | | |

Types in 1710/1711, 1713..1719, 1721..1729 and anything not listed spawn nothing.
⚑ corrected (deepening 2026-10-03): a class's range is wider than its behaviour — the Background Setup handles only
1090..1098, 1150..1153, 1208, 1211..1213, 1480..1489, 1840..1843, 1855/1856, 1900..1903,
2700..2799 (faces 2700..2729), 2890..2893, 2900/2901, 3000..3009, 3060, 3080..3087, 3249; the rest
are inert (triggers-background §2.1). Walker behaviour exists only for 1700, 1705, 1750, 1760
(enemies-ground §8). Placed-type census per class: coverage.md §3. Every one of
the 243 types present in the shipped levels maps to a class (script run, this session; per-class
type list with counts reproduced by `gensprite_map.py` + the census loop). The `layer` arg
(default −1 → 0) lands in sprite+0x80; MTNewSprite callers pass 10 (player), 11 (shots),
2, 800, 32000 [MED: "draw layer" is inferred from `.MTChangeSpriteLayer`'s name].

## 4. Level progression

### 4.1 Level number lifecycle  [HIGH]
- New game: level = `Mwld+0x1c4` (1). Option-key cheat/warp only when debug flag
  `_DAT_100a0064` is set (`.WarpDialog`) — out of scope (debug). ⚑ corrected (deepening 2026-10-03): the shipped path
  loads literal level 1; `Mwld+0x1c4` is read only with the debug flag or a non-default world
  (same value in the data) (save-continue §1, raw 0x1000b2b8..0x1000b2cc cited there).
  ⚑ corrected (review 1c, 2026-10-03) (adjudication B20): settled for save-continue — `1000b27c lbz
  r0,0(r14)` (r14 ← TOC −0x77dc = the debug flag `_DAT_100a0064`, re-assigned at `1000b22c` on the
  non-default-world path): set → `lha 0x1c4(Mwld)`; clear → `li r3,1; bl OpenDefaultWorldLevel`
  (`1000b2b8..1000b2cc`) [HIGH].
- `.NewGame` loop: `GameLoop(hdr+0x2848−32, hdr+0x2846−32, 0, 1)`; on level complete
  (`_DAT_100a0088` set) and not victory → `.ShowWorldMap()` returns a level number → 
  `OpenDefaultWorldLevel(n)` → next `GameLoop` at that level's start.
- `.UpLevel @ 10005e2c` is an empty stub: raw disasm is a single `blr` followed by its
  traceback table (`FzDisasm` 0x10005e2c..0x10005e4c); it is called from `.CheckGameEvents`
  when the current level number changes [HIGH].
- Save/resume rejects saved level numbers ≥ 80 (`.ContinueGame`: `0x4f < *(short*)(save+8)` →
  dialog) [HIGH].
- Re-entering a level: `.SetupLevel` restores the level's saved record snapshot and keeps its
  counters iff `G+0x176+2·L == 1`, a flag set by **every checkpoint save** (`.SavePointSave`)
  as well as by `.EndLevelSGUpdate` at completion; otherwise it is a first visit (counters
  zeroed, totals recounted, chapter screen shown). Detail and evidence: engine.md §9
  ⚑ corrected (review 2026-10-03) #1.

### 4.2 `Mmap` 200 — world map graph  [HIGH]

38,144 B = 128 nodes × 0x128 + 256 zero bytes.

| node off | type | meaning | reader |
|---|---|---|---|
| +0x000 | u8 | node exists | `.FindCurrNode`, `.MakeNodeSprites`, `.CheckPlayerNodeMovement` |
| +0x001 | pstr[257] | name (empty in data; names come from `STR# 1000`) | `.InitPlayerMapData` copies |
| +0x102 | i16 | level number entered from this node | `.ShowWorldMap` return value |
| +0x104 | i16,i16 | map position v,h (px within the 608×384 map PICT) | node sprite at (h−20, v−20) |
| +0x108 | i16[7] | links = node indices (0 = none) | `.CheckPlayerNodeMovement`, `.MakeNodeSprites` |
| +0x116 | i16 | node face (1 on the boss nodes 5,18,25,55,62) | `AddNodeSprite(..., face, ...)` |
| +0x118..0x127 | | zero | none |

Node index = level number in this map except node 60 → level 62, node 62 → level 67. Worked
decode (node 1):
```
$ xxd -s $((0x496dad+0x128+0x100)) -l 0x18 "$FW/Ferazel's Wand World Data.rsrc"
… 0001 0133 00ed 0002 0000 0000 0000 0000 0000 0000
```
→ level 1, (v,h) = (307,237), links {2}. Full node table (24 nodes) in INDEX §Data appendix.

Movement rule (`.CheckPlayerNodeMovement @ 1007bfdc`) [HIGH]: for each link compute primary
and secondary direction from the position delta (1 = left, 2 = right, 3 = up, 4 = down; primary
is the axis with the larger |delta|); an arrow (or ISp elements 0..3) that matches a link's
primary direction moves there; if none, secondary directions are tried. A move is allowed only
if the destination level is unlocked: `globals[+0x23e + 2·level] != 0`.

Unlocking (`.ShowWorldMap`) [HIGH]: on entry, if exit index `sRam100a5116 ≥ 0` (or
`_DAT_100a5118`), the level of `node[cur].links[exit]` is marked unlocked and `.DrawNewLink`
animates it. Exit indices come from the level-exit sprite type 3249 (params 1 and 2, §3.4)
[HIGH]; debug keys `0x12`/`0x13`/`0x19` set exit 1/2/0; the Escape Ring sets −1 (no unlock). Level 1 is unlocked at game start
(`InitGameGlobals: *(short*)(G+0x240) = 1`). Selection: Return/Enter or ISp elements 5/6;
Escape/⌘-Q-style keys abort to menu.

### 4.3 `.CalcPercent @ 10005894` / `.FillPercent @ 10005510` (stage-complete stats)  [HIGH]

`CalcPercent(a, b)`: `b == 0 → 100`; `a == 0 → 0`; else `(int)(100.0f · a / b)` (constant
`_DAT_100a1570` = 100.0f, read with `tools/const.py 100a1570`), clamped to ≤ 100 and ≥ 2.
`FillPercent(x, y, pct, dx, dy)` animates a 52×14 bar from the 52×714 strip PICT in blit port
`_DAT_100ab9f4` (`PICT 141` in Titles, 52×714 = 51 frames of 14 px): it steps `pct/2·2`
frames, 2 ticks per frame (1 tick when pct > 45), with a looping tick sound; then a final sound
by score band (< 11, < 100, = 100). The three stats per level are the counters
`G+0x306/0x3ce/0x496` (achieved) vs `G+0x6ee/0x7b6/0x87e` (totals, set by `.SetupLevel` from the
counts `.SetupLevelSprites` accumulates); the manual names them enemies defeated, Xichrons
collected, secrets found [MED: which counter is which not traced]. ⚑ corrected (deepening 2026-10-03): `G+0x306/0x6ee` =
**enemies** (bosses, flyers and water-cave readers: each counted enemy has `+0x1b5 = 1`, its kill
increments 0x306 — enemies-flyers §1.2, enemies-water-cave §0.1), `G+0x3ce/0x7b6` = **Xichrons**
(1055/1056), `G+0x496/0x87e` = **secrets** (1059) (pickups-boxes §1.10) [HIGH]. Swarms (1869) and
the Wraith are counted but never credited, so the enemies stat of levels 10, 11, 21, 62 cannot
reach 100 % (enemies-flyers §1.2).

## 5. `Mcnv` — conversations  [MED framing; HIGH for the wave-2 decode below]

29 resources × 36,936 B = 0x100 header (pstr conversation name, e.g. `\x0cRojinko Conv`) + 20
lines × 0x72a. From `.HandleConvLine @ 1007a624` the code computes `Mcnv + i·0x72a` and then
adds `+0x100` (text), `+0x200` (speaker), `+0x80a` (picture) — offsets relative to
`Mcnv + i·0x72a`, **not** to the line record (0x80a > 0x72a). Record-relative framing: line `i`
spans `[0x100 + i·0x72a, 0x82a + i·0x72a)` with pstr text at +0, pstr speaker name at +0x100,
i16 picture id at +0x70a (0 = no line) ⚑ corrected (review 2026-10-03) #10 [MED]. Reviewer's
decode of `Mcnv 200` with these offsets works for lines 0..19 (line 0 "Suspicious
Character"; lines 9/10/14/15/16 are picture-0 logic nodes titled "[magic 30 coin check]",
"[been here check]"). ⚑ wave 2 corr (2026-10-04) CM #1–#6 = PB2 #P9 (one merged text; full decode
conversations-mcnv.md §2–§4) [HIGH]:
- **Line record** (record-relative): responses `+0x200 + 0x100k` (k = 0..4), response targets
  `+0x700 + 2k`, condition `+0x70c..+0x712`, two actions `+0x71c` / `+0x722` (type, A, B — i.e.
  `Mcnv + i·0x72a + 0x81c / + 0x822`, `lha 0x81c` `1007a2dc`, `lha 0x822` `1007a300`), next `+0x728`;
  `+0x714..+0x71b` and the header pstr are unread. Target encoding conversations-mcnv §2.3.
- **Entry**: index 19 = line #20 is the entry/logic node; an empty #20 falls through to #1
  (`i = 19 → 0`, `1007a5d0..1007a5e8`); the loop also stops on the abort flag `*0x100a0c14`
  (`1007a888..1007a8b4`).
- **Readers** (offsets in the `Mcnv + i·0x72a` framing): `.HandleLineResponses` reads `+0x300..+0x80a` only; `.HandleLineActions` reads
  `+0x80c..+0x828`, `G` (coins, inventory, flags `+0xad8`), the live level header (`100a0058`) and the
  save block only for action 10. Action codes 1..6, 9, 10 through the table at `0x100a6cd0` (0, 7, 8 =
  no-op `1007a55c`): 1 coins −= A, 2 give item A × B, 3 remove item A × B, 4/6 set a record param to 1,
  5 set flag, 9 kill a sprite, 10 set a per-level byte.
- **What conversations grant** (review 2h ruling 3): items only, never spells; Mcnv 205 #8 gives the
  **Platinum Key** and #5 removes a Health Potion; 207 #7 sells the **Ice Pick** (500 coins) and #9
  removes a Steel Key (#n 1-based; PB2 §8's "line 6/7" are 0-based for #7/#8).

## 6. Open items (also in INDEX)
- ~~Per-class meaning of record params 1–4.~~ ⚑ corrected (deepening 2026-10-03): closed for every placed class (§3.4 table).
- ~~0x26c7/0x26c8/0x272c/0xb270..0xb276 header fields.~~ ⚑ corrected (deepening 2026-10-03): 0x26c8 and 0xb270..0xb276
  closed (§3.2); 0x272c was already HIGH; ~~0x26c7 OmniPx composition and PxMid −1 drawing remain
  (save-continue §8.3)~~ both closed by rendering-omnipx-titles §2/§3 ⚑ wave 2 corr (2026-10-04) RO #5, #6.
- ~~Mcnv response/action encoding~~ (closed, §5, ⚑ wave 2 corr (2026-10-04) CM #1); `STR# 500` sign reader.
