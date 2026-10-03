# Cythera 1.0.4 — `Cythera Data` container, world records, save game

Register: **code reading only**. Nothing here is behaviour-verified. Function addresses are the
Ghidra PPC addresses in `ghidra/Cythera_pef.decompiled.c`. Byte order is big-endian throughout.
Tools used below live in `docs/cythera/tools/` (`seg.py` = segment-file TOC parser + decryptor,
`lz.py` = the engine's LZ decompressor, `pef.py` = PEF data-section unpacker, `rsrc.py` =
resource-map census). Data path abbreviation: `$G` = `/Users/andiyar/Developer/Ambrosia/Resources/ambrosia-extracted/RPG/Cythera/Cythera (installed)/files`.

Engine name: the class `TDelverApp`, resource `Delv`, the `Page` help resources ("Delver
Topics", "The Delver Engine …") — the engine is internally "Delver" [HIGH: names/strings].

---------------------------------------------------------------------------------------------
## 1. The segment file (`TSegFile`)

### 1.1 Layout
| offset | size | meaning | evidence |
|---|---|---|---|
| 0x000 | 0x80 | file header (opaque to `TSegFile`; read/written whole by `ReadHeader`/`WriteHeader`) | `ReadHeader__8TSegFileFPv @ 1007a830`: `SetFPos(…,1,0)`, `local_14[0]=0x80` |
| 0x080 | 0x800 | **root TOC page**: 256 × {u32 offset, u32 length} | `LoadTOC__8TSegFileFv @ 10079be0`: `SetFPos(…,1,0x80)`, `local_28=0x800` |
| … | … | segment bodies and the other TOC pages, anywhere in the file | |

[HIGH] Read directly; every constant is literal in the decompile.

- `IsSegFile__8TSegFileFs @ 100795dc`: a file is a segment file iff the u32 at 0x80 == 0x80
  (`SetFPos(…,0x80)`, reads 8, `return local_14[0] == 0x80`). [HIGH]
- Root entry 0 is the root page itself (`BlankFile @ 10079a78` writes `{0x80, 0x800}`). [HIGH]
- Root entry *n* (1..255) is the {offset,length} of **TOC page *n***, which holds the entries of
  segments `0xnn00..0xnnFF`. `LoadTOC` loops `sVar4 = 1..0xff`, `if (puVar1[3] != 0)` reads page n
  from `puVar1[2]` length `puVar1[3]`. `SaveTOC @ 10079d80` writes page n back with
  `SaveSegment(this, n, page, 0x800)` — i.e. TOC page n is itself stored as **segment id n**
  (page 0x00's entry n). Elegant: the root page is "segment page 0". [HIGH]
- Segment id is a u16: high byte = TOC page, low byte = slot. Lookup expression (repeated in
  every accessor): `*(param_1 + (id>>8)*2 + 4)` = in-memory page pointer at object offset
  `8 + 4*(id>>8)`, then `+ (id & 0xff)*8` → {offset, length}. Length 0 = absent. [HIGH]
- `SaveSegment__8TSegFileFUsPvl @ 1007a4b0`: if the new length exceeds the old, the segment is
  **appended at EOF** (`GetEOF`, `SetEOF(eof+len)`, entry = {eof, len}); if shorter, the length
  is just reduced in place. Old space is leaked until `Compact__8TSegFileFv @ 1007a9a8`. [HIGH]
- In-memory `TSegFile` object (0x408 bytes, `FUN_100be7c8(0x408)` before every ctor): +0 i16
  file refnum, +2 u8 dirty-TOC, +3 u8 locked (save asserts if set), +4 u32 open date, +8
  `TOCEntry*[256]`. [HIGH]

### 1.2 Worked decode (real file)
```
$ xxd -s 0x80 -l 0x30 "$G/Cythera Data"
00000080: 0000 0080 0000 0800 0054 5226 0000 0800  .........TR&....
00000090: 0054 5a26 0000 0800 0054 6226 0000 0800  .TZ&.....Tb&....
```
Root[0] = {0x80, 0x800} (self). Root[1] = page 0x01 at 0x545226, 0x800 bytes. …
```
$ xxd -s 0x480 -l 8 "$G/Cythera Data"          # root[0x80] = TOC page for ids 0x80xx
00000480: 0055 1226 0000 0800
$ xxd -s 0x551226 -l 0x20 "$G/Cythera Data"     # page 0x80, slots 0..3
00551226: 0007 8676 0000 0820 0007 8e96 0002 0020  ...v... ....... 
00551236: 0009 8eb6 0000 2820 0009 b6d6 0000 2020  ......( ......  
```
Segment 0x8000 = {0x78676, 0x820}; 0x8001 = {0x78e96, 0x20020}; 0x8002 = {0x98eb6, 0x2820}. [HIGH]

Census (command `python3 docs/cythera/tools/seg.py`): **file 5,608,688 B, 34 TOC pages, 1,558
segments**. Per page (ids, count, length range): see §1.4.

### 1.3 Segment encryption
`Encrypt__8TSegFileFPvlUsl @ 1007ba30` (Decrypt @ 1007bae0 just calls it — XOR, self-inverse):
```c
iVar3 = (param_3 & 0x3f) * 4 + 1;          // multiplier  (id & 0x3f)*4+1
uVar2 = param_3 >> 6 & 0xff;                // increment   (id >> 6) & 0xff
param_3 = (int)(param_3 & 0xffff) >> 8 ^ param_3;   // seed = (id>>8) ^ id
while (param_4--) param_3 = uVar2 + param_3 * iVar3;   // skip 'offset' steps
while (param_2--) { param_3 = uVar2 + param_3 * iVar3; *p++ ^= (byte)param_3; }
```
32-bit LCG keyed only by the segment id; each byte XORed with the low byte of the next state.
[HIGH] (all constants literal; arithmetic is u32).

Which segments are encrypted: those read through `TCachedSegFiles::GetEncryptedSegment @
1007d148` (decrypts after load) — every call site is the script interpreter (`TInterp` ctor,
`VAddrToPtr`, `Dispatch`, `DoExpr`, `DoInterpAt`), i.e. **script segments** (pages 0x01–0x3x,
see `script-vm.md`). Map/prop/tile/global segments are loaded with plain `LoadSegment`. [HIGH for
the call graph; MED for "all of pages 0x01–0x30 are encrypted" — inferred from the readers +
the random-looking bytes, e.g. 0x0201 begins `867bfe56…`]

### 1.4 Overlay stack (`TCachedSegFiles`) — how saves work
`TCachedSegFiles` (@ 1007ccac..1007dd8c) keeps up to 16 open `TSegFile`s (`param_1[1..16]`) and a
merged 256-page directory mapping every id → {cached data ptr, owning TSegFile}. `AddFile` pushes
a file on top (`for sVar1=0xf..1: slot[s]=slot[s-1]; slot[0]=new`) and re-points every id the new
file contains (`SetEntry`). Reads go to the **topmost file that has the id**; writes
(`SaveSegment__15TCachedSegFiles…`) always go to `slot[0]`. [HIGH]

So a save game is a sparse segment file overlaying `Cythera Data`: only changed/runtime segments
are present. `DoSave__10TDelverAppFUcUc @ 10013900` creates a scratch file with creator/type
`'Delv'`/`'Temp'` (`__ct__8TSegFileFR6FSSpecUlUl(…,0x44656c76,0x54656d70)`) on top for in-play
changes; `SaveToFile @ 10012f6c` copies every segment of the scratch file (`TSegFileIterator`)
into the player file, then `Compact`s. A `'PICT'` preview is added to the player file's resource
fork (`AddFilePreview(…,0x50494354,…)`). [HIGH]

### 1.5 Segment-id map
`python3 docs/cythera/tools/seg.py` (page census, `Cythera Data`):

| ids | count in data | len range | content | reader (evidence) | conf |
|---|---|---|---|---|---|
| 0x0101 | 1 | 1246 | script/heap support (encrypted?) | not traced | NOT RESOLVED |
| 0x02xx–0x0Fxx | 1–66 per page (⚑ corrected (review 2026-10-03): page 0x0B has 1 segment, 0x0B00 = 7 bytes; page 0x01 also has 1) | 4–29972 | script code segments (encrypted) — see script-vm.md | `TInterp` | MED |
| 0x0400 | — (save only) | — | **save-game 'Char' stream** | `SaveToFile`: `SaveSegment(…,0x400,…)` | HIGH |
| 0x0401 | — | 0x800 | to-do list | `LoadToDo__5TToDoFv @ 1007782c` | HIGH (id) |
| 0x0404 | — | 0x14 | status-window macros | `LoadMacros__13TStatusWindowFv` | HIGH (id) |
| 0x0410–0x0436 | 14 | 88–176 | **compiled combat-AI scripts** (built-in) | `GetCombatAIName`, `PerformAI` (`0x360+n`, see ai-scripts.md) | HIGH |
| 0x10xx–0x1Dxx, 0x1E20 | ~700 | 22–10426 | per-object script classes (`ObjIDToSegmentID`) | script-vm.md | HIGH formula / MED class names |
| 0x30xx | 40 | 7–805 | global routines (`TInterp(0x3000+selector)`) | `DoInterp0 @ 10082b34` | HIGH |
| 0x8000+L | 42 | 160–131104 | **level L map** | `LoadLevelMap__Fs @ 10005cb8` | HIGH |
| 0x8100+L | 40 | 32–36640 | **level L props** | `LoadLevelProps__FssUc @ 1000722c` | HIGH |
| 0x8200+L | — (save only) | w/8·h | level L "seen" bitmap (automap) | `SaveLevelProps @ 10006dc8` | HIGH |
| 0x8400+n | 18 | 3837–7095 | sky strip 288×32, LZ | `ChangeOutdoor__13TStatusWindowFUcs` (`LoadPixs(…,0x120,0x20)`) | HIGH |
| 0x8800+n−1 | 142 | 449–3332 | portrait n, 64×64 8-bit, LZ | `DrawPortrait__Fssss @ 100086c4` (`param_3+0x87ff`) | HIGH |
| 0x8A00+n | 62 | 512 | macro icon 32×16 raw 8-bit | `DrawAMacro__FR4RectsUc @ 100373a0` | HIGH |
| 0x8E00+n | 160 | 1429–11198 | tile sheet n: 16 tiles × 32×32 8-bit, LZ → 0x4000 B | `LoadTiles__Fv @ 10005080` | HIGH |
| 0x8F00+n | (part of 59) | | backdrop pattern: {u16 w,u16 h, LZ pixels} | `LoadPattern__13TBackdropWindFv` | HIGH |
| 0x8F80+n | (part of 59) | | status-window artwork, same {w,h,LZ} form | `__ct__13TStatusWindowFv` | HIGH |
| 0x9000+n | 11 | 8412–40612 | music (handed to GMS `GMSPlayAmbient/Spot`) | `PlayMusic__6TAudioFsUc @ 1001bb3c` | HIGH (id) / format NOT RESOLVED |
| 0x9100+n | 46 | 7180–175116 | sounds, begin **`'asnd'`** (⚑ corrected (review 2026-10-03): segment 0x9101 begins `61 73 6e 64 00 00 00 08`) | `PlaySound__6TAudio…`, `BeginSpotSound` | HIGH (id) / format NOT RESOLVED |
| 0xE000+k | — (save only) | ≤0x2000 | journal pages (`pos>>13`) | `Flush__15TJournalSegmentFv @ 10077bfc` | HIGH |
| 0xF000–0xF016 | 20 | 16–131072 | **world globals** — §5 | `LoadGlobals__Fv @ 10005798` | HIGH ids |
| 0xF306 | — (save only) | 0x1000 | props 0..255 (the character props) | `SaveLevelProps` | HIGH |
| 0xF307 / 0xF308 | — (save only) | 0x40000 / 0x2000 | persistent script heap / unique-object table | `Save__5THeapFP8TSegFile @ 100ab820` | HIGH |

Pages present in the shipped data and not traced to a reader: 0x01, 0x03 (0x0301, 0x033F),
0x05, 0x08, 0x09, 0x0A, 0x0B, 0x0C, 0x0D, 0x0E, 0x0F (all in the encrypted-script band) —
**NOT RESOLVED** which script class/kind each page holds beyond the `ObjIDToSegmentID` formula.

---------------------------------------------------------------------------------------------
## 2. The LZ codec (`FUN_1007573c @ 1007573c`)

Used for tiles, portraits, sky, pixmaps (`LoadPixs`, `TPixCacheBase::NewPix/LoadPix`). No length
header: decoding runs until a terminator op. [HIGH] — every branch read; re-implemented in
`tools/lz.py` and it reproduces exact sizes (tile sheet 0x8E00: 5378 → 16384 bytes consumed
exactly 5378; portrait 0x8800: 1482 → 4096; sky 0x8400: 5474 → 9216 = 288×32).

| first byte `b` | bytes | action |
|---|---|---|
| `0xxxxxxx` | b, b1 | copy `(b1>>3)&3` literals, then match len `(b1&7)+3`, distance `1 + ((b&0x7f) | (b1&0xe0)<<2)` |
| `10xxxxxx` | b, b1, b2 | copy `b2&3` literals, then match len `(b1&0x1f)+3`, distance `1 + ((b2&0xfc)<<7 | b&0x3f | (b1&0xe0)<<1)` |
| `110 0xxxx` | 1+n | literal run, n = `((b&0xf)+1)*4` |
| `110 1xxxx` | 1+n | literal run, n = `b&0xf` |
| `1110 xxxx` | 2 | RLE: byte b1 × `(b&0xf)+3` |
| `11110 xxx` | 3 | RLE: byte b2 × `b1+3` |
| `11111 xxx` | 1 | end of stream |

---------------------------------------------------------------------------------------------
## 3. Level maps (segment 0x8000 + L)

### 3.1 Header (first 0x20 bytes, loaded into the global at `PTR_DAT_100cdbd4`)
| off | type | meaning | evidence | conf |
|---|---|---|---|---|
| 0x00 | i16 | width W (tiles) | `LoadLevelMap`: map body = `W*H*2`; `SetViewerLocation @ 1005c328`: `+0x20c1c = *(short*)hdr` | HIGH |
| 0x02 | i16 | height H | same, `+0x20c1e = hdr[2]` | HIGH |
| 0x04 | i16 | unused by `LoadLevelMap` (0 in all 42 maps) | census | NOT RESOLVED |
| 0x06 | i16 | first chunk index used by "chunked" maps (see 3.3) | `LoadLevelMap` | HIGH |
| 0x08 | i16 | number C of 0x80-byte chunk records following the header | `LoadSegment(…,0x20, C<<7)` into `PTR_DAT_100cdc50` | HIGH |
| 0x0A | u8 | X wrap span (power of 2, 0 = no wrap) | `SetViewerLocation`: `+0x20c20 = (byte)hdr[10]`; `SetStage` masks `x & (span-1)` | HIGH |
| 0x0B | u8 | Y wrap span | `+0x20c22 = (byte)hdr[0xb]` | HIGH |
| 0x0C | i16 | exit when leaving across the **north** edge: teleport index | `MoveCommand__8TGameSys @ 10050460`: `TeleportTo(…,-1,hdr[0xc],0)` | HIGH (⚑ corrected (review 2026-10-03): was MED; `y == 0 → hdr[0xC]`) |
| 0x0E | i16 | exit east | `x ≥ W → hdr[0xE]` | HIGH (⚑ corrected (review 2026-10-03)) |
| 0x10 | i16 | exit south | `y ≥ H → hdr[0x10]` | HIGH (⚑ corrected (review 2026-10-03)) |
| 0x12 | i16 | exit west | `x == 0 → hdr[0x12]` | HIGH (⚑ corrected (review 2026-10-03)) |
| 0x14–0x1F | — | zero in all 42 maps | census below | NOT RESOLVED |

⚑ corrected (review 2026-10-03) — **fallback when the hit edge's exit is 0**: `MoveCommand` then uses the perpendicular
edge's exit chosen by half of the map, e.g. top row with hdr[0xC] = 0: x < W/2 → hdr[0x12] (west)
else hdr[0xE] (east); likewise for the other edges. [HIGH] Edge exits apply only when the step did
not auto-use a property-0x3A prop (rules.md §2).

The exits are **teleport indices** into the table at segment 0xF00C (§5), not level numbers:
`TeleportTo__8TGameSysFsss @ 10050e98`: `uVar2 = *(uint *)(PTR_DAT_100cdc00 + param_3*4)` →
`GoToLocation(level=uVar2>>24, x=(uVar2>>12)&0xfff, y=uVar2&0xfff)`. [HIGH]

Census of all 42 map headers (command in `tools/seg.py` style; excerpt):
```
8001 w=256 h=256 s6=  0 s8=  0 +a=0000 +c=0000…                 (the overworld, no exits)
8002 w= 64 h= 64 s6= 16 s8= 16 +a=0408 +c=0005 0005 0005 0005  (16 roof chunks, all exits → teleport 5)
8008 w=128 h=128 s6=102 s8=102 +a=0808 +c=0012 0012 0012 0012
8026 w= 24 h= 16 s6=  0 s8=  0 +a=0404 +c=0000 008e 0000 008f   (east→142, west→143)
```
In every shipped map `+6 == +8` [tool output], so the chunked path (§3.3) is never taken by the
shipped data.

Worked decode:
```
$ xxd -s 0x98eb6 -l 0x30 "$G/Cythera Data"        # segment 0x8002
00098eb6: 0040 0040 0000 0010 0010 0408 0005 0005  .@.@............
00098ec6: 0005 0005 0000 0000 0000 0000 0000 0000  ................
00098ed6: 0000 0000 01f6 01e4 01fd 01e1 01e1 01f1  ................   ← chunk 0 begins at +0x20
```
W=64, H=64, C=16 chunk records (16×0x80 = 0x800), wrap 4×8, all four exits → teleport 5.
Map body at `0x20 + 16*0x80` = segment offset 0x820; segment length 0x2820 = 0x20 + 0x800 +
64·64·2 ✓. Teleport 5 (`xxd -s 0x50db18 -l 4` → `010c 703a`) = level 1, x 199, y 58. [HIGH]

### 3.2 Map cell (u16, row-major, `cell = map[y*W + x]`)
| bits | meaning | evidence | conf |
|---|---|---|---|
| 0–11 | tile index (0..0xFFF; 0..0x9FF have pixels) | `SetStage`: `& 0x1fff`; `MaskAnyTile`: `PTR_DAT_100cdc28 + (t&0x1fff)*4 + frame*0x2800` (0x2800 = 0xA00 ptrs) | HIGH |
| 12 (0x1000) | **compo tile**: low 12 bits index a CompoTileRecord (§3.4) | `MaskAnyTile__7TViewerFUsll @ 10063b9c`: `if ((t & 0x1000) == 0) … else BuildCompoTile(…, PTR_DAT_100cdc58 + (t&0xfff)*0x20)` | HIGH |
| 13 (0x2000) | draw with the transparent mask variant (`TMaskTile`) | same function | MED (flag only seen on the `MaskAnyTile` argument; not checked whether map cells carry it) |
| 15 (0x8000) | "seen" (automap) — runtime only, from segment 0x8200+L | `LoadLevelMap`: `*puVar16 |= 0x8000` for each set bit | HIGH |

Out-of-map cells on non-wrapping edges render tile 0xFF (`SetStage`: `if (bVar3) uVar6 = 0xff`). [HIGH]

### 3.3 Chunk records (0x80 bytes each = 8×8 u16)
Two uses, both read in code:
1. **Roof / overlay masks** for kind-0x44 props (§4): `SetStage` tests
   `*(short*)(chunks + type*0x80 + …)` for the 8×8 block whose bottom-right corner is the prop's
   (x,y) and, if the player stands under a non-zero cell, records the prop's 5-bit field as the
   current roof id (`viewer+0x20c1a`). [MED — the index arithmetic is read, the visual result
   ("roof hides") is inferred from the names `ApplyRoof__7TViewerFsss`.]
2. **Chunked maps** (`hdr[6] < hdr[8]`): body is `(W/8)·(H/8)` u16 block indices at
   `0x20 + C*0x40`, each block `k` expanded from chunk `hdr[6]+k`. [HIGH as code; never exercised
   by shipped data. Note the body offset uses `C*0x40` here but `C*0x80` in the flat path — read
   literally, flagged for review.]

### 3.4 Tiles, animation, compo tiles
- Tile pixels: 0xA00 tiles × 32×32 bytes (8-bit, palette `clut` 256 / app resource), loaded from
  160 sheets `0x8E00..0x8E9F` (`LoadTiles`: `0x9f < sVar6` break, `*0x4000`). Pixel value 0 =
  transparent (`FindBoundsRect__FR4RectPc @ 10005640` treats non-zero as opaque). [HIGH]
- 8 animation frames: `LoadGlobals` builds `ptr[frame 0..7][tile 0..0x9FF]`; default = the tile
  itself; overridden from segment **0xF001**: records of 4×i16 {tile, base, nframes, divisor},
  zero-terminated; `ptr[f][tile] = pixels(base + ((f / divisor) mod nframes))`. [HIGH]
  ```
  $ xxd -s 0x4fe229 -l 0x10 "$G/Cythera Data"
  004fe229: 03db 03db 0004 0002 0871 0871 0004 0001
  ```
  tile 0x3DB animates through 0x3DB..0x3DE, advancing every 2 global frames; tile 0x871 every frame.
- An hourly per-type override: `ScheduleTime__FsUc @ 10006bec` asks every object type
  (1..0x3FF) for script property **0x29** with the hour; an integer result re-points all 8 frame
  pointers of that type's base tile to `base + result` (clocks, sundials…). [HIGH as code; the
  purpose is LOW]
- **CompoTileRecord** (0x20 bytes, 4096 of them = segment **0xF013**, 0x20000 B):
  `BuildCompoTile__FPUcP15CompoTileRecord @ 100051a8` — 4×4 u16 entries; each entry picks an 8×8
  quadrant of a source tile: `src = tile[e & 0xfff] + ((e>>8)>>3 & 0x18) + ((e>>8) & 0x30)*0x10`
  i.e. bits 14–15 = quadrant column (×8 px), bits 12–13 = quadrant row (×8 rows). Output = 32×32. [HIGH]
- **Displacement filters** (shimmer/heat/water): `FILT` resources 0..255 in `Cythera Data.rsrc`
  (7 present). Layout from `LoadDisplacementFilters__Fv @ 100052a0`: byte0 = frame hold count,
  byte1 = running counter, bytes 4..0x23 = 256-bit palette mask (which colour indices are
  displaced), then N frames of 0x400 signed-offset bytes. `DisplacementFilterTile @ 100053e8`:
  for each pixel whose colour bit is set, `out = in[offset_table[i]]` (relative fetch).
  `AdvanceDisplacementFilters` steps a frame when the counter hits 0. Per-tile filter id:
  segment **0xF016** (0x2000 bytes, one per tile). Gated by preference bit `bRam100d3e21 & 8`. [HIGH]
  Sizes agree: 6180 = 0x24 + 6×0x400, 8228 = 0x24 + 8×0x400 (`tools/rsrc.py` census).

### 3.5 Seen-bitmap (0x8200+L, save only)
`SaveLevelProps` writes, per row, `ceil(W/8)` bytes, LSB = leftmost cell, from the 0x8000 bit;
`LoadLevelMap` restores it. [HIGH]

---------------------------------------------------------------------------------------------
## 4. Props (`PropItem`, 16 bytes) — segment 0x8100 + L

### 4.1 Global prop table
`CreateGlobals__Fs @ 10004d0c`: props live in one array of **0x4400 × 16 B** (`NewPtrClear(0x44000)`,
`PTR_DAT_100cdc44`). Index ranges [HIGH]:

| index | use | evidence |
|---|---|---|
| 0x000–0x0FF | one prop per **character** (prop i ↔ CharEntry i) | `CueCharacters`, `SaveLevelProps` copy 0..0xFF ↔ CharEntry; saved as 0xF306 |
| 0x100–(count−1) | the current level's props, loaded from 0x8100+L (`LoadLevelProps` loads at `+0x1000`) | count = `(len>>4) + 0x100` |
| up to 0x3FFF | growth; "Out of space for new props" at 0x4000 | `NewProp__Fv @ 10007b10` |
| (0x4000 − n)..0x3FFF | props carried between levels (party inventory) | `LoadLevelProps(L, n, …)` relocation loops |
| 0x4000–0x43FF | per-frame pseudo-props synthesised by `SetStage` for tiles with a 0xF010 entry (kind 0x40) | `SetStage`: `puVar12 = props + 0x40000` |

Free list: byte0 = 0xFF marks a free slot; its low 24 bits chain to the next free index
(`ChainFreeProps__FUc @ 10007850`, `DeleteProp__Fs`). Deleting a prop recursively deletes
everything whose parent is it. [HIGH]

### 4.2 Record layout
| off | bits | meaning | evidence | conf |
|---|---|---|---|---|
| 0 | 8 | **kind** (table 4.3) | everywhere | HIGH |
| 1..3 | 24 | on map: x = bits 12–23, y = bits 0–11 (each signed 12-bit); contained: parent index in the low 16 bits | `SetStage`: `((u32>>8)<<16>>16)>>4`, `(short)(u16@2 <<20)>>20`; `GetPropParent__FP8PropItem @ 10055d4c` returns `(short)u32` | HIGH |
| 4..5 | 0–9 | object **type** (0..0x3FF) | `& 0x3ff` everywhere | HIGH |
| 4 | bits 2–6 of byte 4 (= bits 10–14 of the u16) | **frame / state** 0..31 (tile = base[type] + frame) | `(byte[4]>>2)&0x1f` + `PTR_DAT_100cdbf4[type]` | HIGH |
| 4 | bit 7 of byte 4 | mirror: swaps multi-tile extension direction 0x40↔0x80 | `SetStage`: `if ((char)pbVar16[4] < 0) swap` | MED |
| 6 | 8 | quality / letter / timer / sub-position (type-flag dependent, §4.4) | `GetItemQuality`, `GetItemLetter`, `DoTicks` countdown, `SetStage` sub-offset `byte6 & 3`, `byte6>>4 & 3` | HIGH per accessor |
| 6..7 | 16 or 8 | **count** (u16 at +6 if type flag 0x200; u8 at +7 if flag 0x100; else 1; 0 reads as 1) | `GetItemCount__FP8PropItem @ 1005577c` | HIGH |
| 7 | 8 | facing/activity copy for characters | `RepositionChar` writes `param_2+7` | MED |
| 8..9 | 16 | index into the unique-object table (`PTR_DAT_100cdba4`, saved as 0xF308) | `AllocateFrame__8PropItemFv @ 10007c5c` | HIGH |
| 0xA..0xB | 16 | not touched by any accessor read | — | NOT RESOLVED |
| 0xC..0xD | 16 | script heap reference (a THeapObj "frame", type 2) holding per-instance variables; DecRef'd on delete | `AllocateFrame`, `DeleteProp`, `ChainFreeProps` | HIGH |
| 0xE..0xF | 16 | not touched by any accessor read | — | NOT RESOLVED |

### 4.3 Kind byte (byte 0)
Census over all 40 shipped prop segments (`kind byte census`): `0:12104, 1:116, 2:46, 8:618,
9:241, 10:7, 16:32, 17:55, 24:31, 28:1, 66:879, 68:298, 128:52, 255:5`.

| kind | meaning (as used) | evidence | conf |
|---|---|---|---|
| 0x00 | object on the map at (x,y) | `SetStage` `LAB_100656bc` path | HIGH |
| 0x01 | on map, alternate draw path (`bVar1 < 2` → same as 0) | `SetStage` | MED |
| 0x02, 0x03, 0x22, 0x23 | on map + tile-flag 0x800 "blocker" marking | `SetStage` `LAB_100655e8` | MED |
| 0x04, 0x24 | on map, drawn as roof layer (priority 7) | `SetStage`: `if (*pbVar16 == 4 || == 0x24) local_72 = 7` | MED |
| 0x08–0x0B | **inside a container prop** (parent = low 16 bits) | `GetPropParent` (`7 < b < 0xc`), `GetCurInvEncumb` walks `\t`/`\b` chains | HIGH |
| 0x10 | in a character's **inventory** (parent = char index) | `GetCurInvEncumb__Fs` | HIGH |
| 0x11 | (present in data, 55×) — not decoded | — | NOT RESOLVED |
| 0x18 | **equipped/wielded** by a character | `GetCurEquEncumb__Fs` | HIGH |
| 0x1C | a character's **skill** (type = skill id) | `FindSkill__Fss @ 10056100` | HIGH |
| bit 0x20 | "transient" — freed by `ChainFreeProps(1)` on level load | `ChainFreeProps`: `(*puVar5 & 0x20000000) != 0` | HIGH |
| 0x21 `'!'`, 0x20 `' '` | merge records: on (re)load from a save, a scenario prop of the same type may overwrite them | `LoadLevelProps` merge loop | MED |
| 0x40 | per-frame tile pseudo-prop (from 0xF010) | `SetStage` | HIGH |
| 0x42 `'B'` | **invisible marker ("egg") prop**. For props 0..0xFF it is the character's on-map body (CharEntry-linked). For level props the 5-bit frame field selects the marker sub-kind (census over 0x81xx: frame 0: 312, 1: 30, 3: 330, 4: 8, 6: 2, 7: 3, 8: 170, 10: 24): **frame 8 = room rectangle** (type = room id, centre x,y, byte 6 = width, byte 7 = height); **frame 9 = countdown trigger** (byte 6 = ticks at rate 16 units, parent low16: 0 → zone, <0x100 → character, else prop; fires selector 21); frame 10 = always staged; frame 3 = viewer effect taking (type, byte 6); frame 0 = spawn egg consumed by `HatchEgg` | `CueCharacters`, `RebuildParty`; `GetRoom__9CharEntryFv @ 10053cec`; `DoTicks`; `SetStage`; `HatchEgg @ 1004f420` | HIGH (room, trigger) / MED (10, egg) / LOW (3) |
| 0x44 `'D'` | roof/overlay zone: type field = chunk index, frame field = roof id | `SetStage` | MED |
| 0x80 | (present, 52×) — not decoded | — | NOT RESOLVED |
| 0xC2 | character hidden off-stage (reverts to 0x42 when out of the 31×31 window) | `SetStage`, `ChainFreeProps` | MED |
| 0xFF | free slot | `NewProp`, `DeleteProp` | HIGH |

### 4.4 Per-type tables (built at start from scripts)
`FillIntfCache__Fv @ 1009b164` asks each type's script (class 0, segment 0x1000+type) for
properties and fills `typeflags[0x400]` (`PTR_DAT_100cdba8`) [HIGH as code]:

| script property | → typeflags bit / table |
|---|---|
| 0x27 (bitmask) | bit0..5 → 0x1..0x20; 0x40→0x80; 0x80→0x40; 0x200→0x4000000; 0x800→0x8000000 |
| 0x28 (bitmask) | 1→0x100 (count in byte 7), 2→0x200 (count u16), 4→0x400 (letter), 8→0x1000, 0x10→0x800, 0x20→0x2000 (frame shows stack size), 0x40→0x4000 |
| 0x24 (weight) | integer → `weight[type]` (`PTR_DAT_100cde7c`); non-integer (a list) → 0x2000000 "weight by frame"; any → 0x100000 |
| 0x25 / 0x26 / 0x3A / 0x23 / 0x15 | presence → 0x200000 / 0x800000 / 0x1000000 / 0x80000 / 0x10000 |
| 0x37 | presence → 0x400000 and byte table `PTR_DAT_100cdeb8` |
| 0x22 | byte table `PTR_DAT_100cdebc` = value+1 |
| 0x3B | short table `PTR_DAT_100cdec4` (a light/effect id passed to the viewer for kind-0 props) |

Stack frames for counted items (flag 0x2000, `SetItemCount__FP8PropItems @ 1005560c`): frame 0
for 1, 1 for 2, 2 for 3, 3 for 4, 4 for 5–9, 5 for 10–19, 6 for 20–34, 7 for ≥35. [HIGH]

Weight: `GetObjectWeight__Fsss @ 100554e4` = `weight[type] × count`, or for 0x2000000 types
`property24[frame] × count`. Encumbrance limits (`GetMaxInvEncumb/GetMaxEquEncumb`): inventory
= Body×20, equipped = Body×10 (CharEntry +9). [HIGH]

### 4.5 Worked decode
```
$ xxd -s $((0xe6c06+0x20)) -l 0x20 "$G/Cythera Data"     # segment 0x8102, records 2-3
000e6c26: 0000 a020 0c27 0100 0000 0000 0000 0000  ... .'..........
000e6c36: 4400 f011 0001 0000 0000 0000 0000 0000  D...............
```
Record 2: kind 0 (on map), x = 0x00A = 10, y = 0x020 = 32, u16@4 = 0x0C27 → type 0x027 = 39,
frame (0x0C>>2)&0x1F = 3 → tile `f000[39]+3` = 1123, whose name (0xF004) is "portcullis";
byte 6 = 1. Record 3: kind 0x44 (roof zone), x 15, y 17, chunk 1. [HIGH for field extraction;
the tile-name join is a tool join, not a game display.]

---------------------------------------------------------------------------------------------
## 5. World globals (0xF0xx) — `LoadGlobals__Fv @ 10005798` / `NewModel`

| id | size | loaded into | meaning | conf |
|---|---|---|---|---|
| 0xF000 | 0x800 | `PTR_DAT_100cdbf4` | u16 **base tile per object type** (0x400) | HIGH (`tile = f000[type] + frame` in SetStage, DrawInventoryIcon) |
| 0xF001 | var | (temp) | tile animation records (§3.4) | HIGH |
| 0xF002 | 0x8000 | `PTR_DAT_100cdc14` | u32 **tile flags** per tile (0x2000) — passability/LOS/draw-layer bits; render priority logic in `SetStage` reads 0x10000000, 0x100000, 0x800, 0x20000, 0x200, 0x30, 0xC0 (multi-tile extension, `SetStage`: 0x80 → tile−1 also drawn one cell left (`puVar12[-2]`); 0x40 → tile−1 one cell up (`puVar12[-0x3e]`, row stride 0xF8); 0xC0 → tile−1 up, tile−2 left, tile−3 up-left (`puVar12[-0x40]`); bit 7 of the prop's byte 4 swaps 0x40↔0x80) | HIGH ids / MED per-bit meaning |
| 0xF004 | var | (cached) | **tile names**: {u16 last-tile-of-range, C string}…, terminated by an id > 0x2000 (0x7FFF). A tile without its own entry takes the next higher entry's name. `/` = plural-only text, `\` = singular-only text, reset at space (`SingPlur__FPcPcUc`). 547 names (tool). | HIGH |
| 0xF005, 0xF007, 0xF00A, 0xF014, 0xF015 | 16, 167, 1024, 123, 179 | — | no PPC reader found (`grep 0xf005` etc. = 0 hits) | NOT RESOLVED |
| 0xF008 | 2048 | `PTR_DAT_100cdbd8` | first 0x800 bytes = header; rest = 16-byte records, count `(size−0x800)>>4` → `PTR_DAT_100cdc38` (here 0 records) | NOT RESOLVED meaning |
| 0xF009 | 0x2000 (0x4000 in saves) | `PTR_DAT_100cdbf0` | **CharEntry[256]** (§6); saved back with 0x4000 | HIGH |
| 0xF00B | var | `PTR_DAT_100cdbe0/dc` | **schedules** (§6.3) | HIGH |
| 0xF00C | 0x1000 | `PTR_DAT_100cdc00` | **teleport table**: 1024 × u32 location (level<<24 \| x<<12 \| y); 190 non-zero (tool) | HIGH |
| 0xF00D | var (500) | TViewer+0xC188.. | 10-byte records {u16 tile (≤0x2000), 4×u16}; per-tile pointer table | NOT RESOLVED meaning |
| 0xF00E | 0x800 — ⚑ corrected (review 2026-10-03): **absent from the shipped data** (the F0 page has 20 segments: f000–f002, f004–f005, f007–f00d, f00f–f016); like the "save only" rows, it exists only in saves — `NewModel` loads it via `TCachedSegFiles`, so a fresh game sees zeros | `PTR_DAT_100cdbac` | u16 flags per **room** (0x400): bit 0 = visited (set on first entry, which sends selector 7 to the room script); saved by `SaveGlobals` | HIGH (`HeartBeat__8TGameSysFs @ 10053a80`: `if ((flags[room] & 1) == 0) { DoInterp(7, room); flags[room] |= 1; }`) |
| 0xF00F | 0x400 | `PTR_DAT_100cdbfc` | byte per teleport index → viewer `+0x20c28` on arrival (value 14 in samples) | MED id / NOT RESOLVED meaning |
| 0xF010 | 0x4000 | `PTR_DAT_100cdc10` | u16 per tile; non-zero spawns a kind-0x40 pseudo-prop carrying it (light source id?) | MED |
| 0xF011, 0xF012 | 0x8000 each | `PTR_DAT_100cdc08`, `…c04` | not traced | NOT RESOLVED |
| 0xF013 | 0x20000 | `PTR_DAT_100cdc58` | **CompoTileRecord[4096]** | HIGH |
| 0xF016 | 0x2000 | `PTR_DAT_100cdc0c` | displacement-filter id per tile | HIGH |

---------------------------------------------------------------------------------------------
## 6. Characters

### 6.1 `CharEntry` (0x20 bytes; 256 in segment 0xF009, 512 at runtime)
The runtime table is 0x4000 bytes = 512 entries: `NewModel`/`RestoreModel` load 0xF009 and zero
the upper 0x2000 bytes; `SaveGlobals` writes all 0x4000; `HeartBeat` iterates 0..0x1FF. Entries
0x100..0x1FF are therefore runtime-only (spawned monsters — MED, `CreateMonster` not traced to the
index allocator). [HIGH for sizes]
| off | type | meaning | evidence | conf |
|---|---|---|---|---|
| 0x00 | u32 | location: level<<24 \| x<<12 \| y | `RepositionChar`, `MovePartyBetweenLevels`, `NewModel` (`>>0x18`, `>>0xc & 0xfff`, `& 0xfff`) | HIGH |
| 0x04 | u16 | current type (10 bits) + frame (bits 10–14) — copied to prop i | `CueCharacters` | HIGH |
| 0x06 | u16 | status flags: bit0 alive/active (clear → "Dead"); 0x2 Poisoned; 0x40 Paralyzed; 0x2000 Confused; 0x20 Afraid; 0x200 Charmed; 0x10 regenerating (DoTicks); bit k = condition bit k+8 for `EvalCondition` | `DrawStatPart__16TCharacterWindow` string ladder (strings resolved via `tools/toc.py`: "Dead","Fine","Hurt","Wounded","Critical","Poisoned"…) | HIGH |
| 0x08 | u8 | flags: 0x40 = **party member**; 0x80 = name known (use scripted name); bits = condition bits 0–7 | `RebuildParty`, `GetCharacterName__FsPcUc` | HIGH |
| 0x09 | u8 | **Body** | `DrawStatPart`: "Body: %d" ← `+9` | HIGH |
| 0x0A | u8 | **Reflex** | "Reflex: %d" ← `+10` | HIGH |
| 0x0B | u8 | **Mind** | "Mind: %d" ← `+0xb` | HIGH |
| 0x0C | u16 | **Experience** | `DrawStat2Part`: "Exp: %5d" ← `+0xc` | HIGH |
| 0x0E | u8 | **Health** current | "Health" ← `+0xe` | HIGH |
| 0x0F | u8 | Health max | `+0xf` | HIGH |
| 0x10 | u8 | **Magic** current | "Magic" ← `+0x10` | HIGH |
| 0x11 | u8 | Magic max | `+0x11` | HIGH |
| 0x12 | u8 | not traced | — | NOT RESOLVED |
| 0x13 | u8 | **Level** | "Level: %2d" ← `+0x13` | HIGH |
| 0x14 | u16 | "home" type/frame (restored by `RepositionChar`) | `RepositionChar`: `*(ushort*)(param_1+5) & 0x3ff` | MED |
| 0x16 | u8 | current schedule activity (from schedule byte 1); 'p'(0x70) excluded from scheduling; 0x80 = walking to waypoint | `ScheduleTime`, `RepositionChar` | MED |
| 0x17 | u8 | not traced (0 for 110 chars; 10–18 for 21) | census | NOT RESOLVED |
| 0x18 | u8 | non-zero → `TActiveMonster::DoTick` takes the "controlled/other" branch | `DoTick__14TActiveMonsterFUc @ 1004ded8` | LOW |
| 0x19 | u8 | **alignment**: 0 neutral, 1 evil, 2 good, 3 feral | `CalculateObject__14SCombatAIEntry` groups good/evil/neutral/feral test `+0x19 == 2/1/0/3` | HIGH |
| 0x1A | u8 | more condition flags (bits 0x18–0x1F) | `DrawStatPart` icon loop | MED |
| 0x1B | u8 | **food** hours remaining; 0 → no regeneration ("Hungry") | `DoTicks` (decrement per hour; regen gated on `!= 0`) | MED (name inferred from the "Hungry" status) |
| 0x1C | u8 | **Training** points | "Training: %2d" ← `+0x1c` | HIGH |
| 0x1D | u8 | not traced (values 0–15 in data) | census | NOT RESOLVED |
| 0x1E | u8 | combat behaviour: <0xB0 built-in mode (3..8 set by `HatchEgg` from the activity byte), ≥0xB0 user AI slot (segment 0x360+v) | `RecalcUserAIMenu__16TCharacterWindowFv @ 1003071c`, `HatchEgg @ 1004f420` | MED |
| 0x1F | u8 | 0 in all data; not traced | census | NOT RESOLVED |

Worked decode (character 2):
```
$ xxd -s $((0x5081bc+0x40)) -l 0x20 "$G/Cythera Data"
005081fc: 0301 3015 2422 0001 0014 1414 2580 9090  ..0.$"......%...
0050820c: 2424 0008 2422 9600 0000 0000 000f 0600  $$..$"..........
```
location 0x03013015 → level 3, x 0x013 = 19, y 0x015 = 21; type 0x2422&0x3FF = 34; flags 0x0001
(alive); byte8 0 (not in party); Body 0x14 = 20, Reflex 20, Mind 20; Exp 0x2580 = 9600; Health
0x90/0x90 = 144/144; Magic 0x24/0x24 = 36/36; +0x12 0; Level 8; home 0x2422; activity 0x96;
+0x17..+0x1C all 0 (alignment neutral, food 0, training 0); +0x1D = 0x0F; behaviour +0x1E = 6.
[HIGH for extraction, field names per the table]

Field census over the 131 non-empty CharEntries (command: a `collections.Counter` over each byte
of 0xF009 in `tools/seg.py` style): `+0x12, +0x18, +0x1A, +0x1B, +0x1C, +0x1F` are 0 for all;
`+0x19` = {0:128, 1:2, 2:1}; `+0x1E` = {0:11, 2:1, 3:7, 4:7, 5:1, 6:5, 7:8, 8:91}.

Character 1 is the player: its name comes from `PTR_DAT_100cdba0 + 0x21` (Pascal-ish, length at
+0x20) rather than the script (`GetCharacterName`). [HIGH]

### 6.2 Names and portraits
- `GetCharacterName__FsPcUc @ 10007d40`: char 1 → player name; else if flag 0x80 (or forced) and
  the script string `VAddr(3, segment = 0x1800+id?, …)` — literally `id<<16 | 0x30000201` (tag 3,
  index `id`, segment 0x0201) — exists, use it; otherwise the tile name of the character's type.
  [HIGH as code; MED on the reading that segment 0x0201's string table indexed by character id
  is the name table.]
- `DrawPortrait__Fssss @ 100086c4`: portrait p (1-based) = segment `0x87FF + p`, LZ → 64×64
  8-bit, `CopyBits` 0x40 rowBytes. 142 portraits in data. [HIGH]

### 6.3 Schedules (segment 0xF00B)
Layout (`LoadGlobals` tail): 256 × i16 counts (0x200 bytes), then for each character in order its
`count` 8-byte entries. [HIGH]

| off | type | meaning |
|---|---|---|
| 0 | u8 | hour (0..23) the entry starts |
| 1 | u8 | activity code → CharEntry +0x16 / prop +7 |
| 2 | u8 | condition opcode (`EvalCondition`, rules.md §3) |
| 3 | u8 | condition argument |
| 4 | u32 | location (level<<24\|x<<12\|y); 0 = block header |

Census: 617 entries, `512 + 8×617 = 5448` = segment length ✓ (tool). Worked decode:
```
$ xxd -s $((0x50c5bc+0x200)) -l 0x18 "$G/Cythera Data"
0050c7bc: 0900 0000 0100 0000 0096 0300 0301 3015  ..............0.
0050c7cc: 0000 0100 0000 0000
```
Char 0: one entry (hour 9 → level 1 (0,0)). Char 2's first entry: hour 0, activity 0x96, cond
0x03 arg 0 ("global flag 0 clear"), location (3,19,21); then `00 00 01 00 00000000` = block-end
marker (cond 1). Selection algorithm in rules.md §3.

---------------------------------------------------------------------------------------------
## 7. Save game

A save is a `TSegFile` (creator/type from `NewGame`/`DoSaveAs`, not traced) that overlays
`Cythera Data` (§1.4). Written by `SaveToFile__10TDelverAppFR6FSSpecP8TSegFileUc @ 10012f6c`:

1. `SaveLevelProps(curLevel)` → 0x8100+L (props 0x100..), 0xF306 (props 0..0xFF), 0x8200+L
   (seen bits), then `SaveGlobals` → 0xF009 (CharEntry, 0x4000 bytes), 0xF00E. [HIGH]
2. `SaveToDo` (0x0401), `SaveMacros` (0x0404), `THeap::Save` (0xF307 heap 256 KB, 0xF308
   unique-object table). [HIGH]
3. Segment **0x0400**: a `TMemoryStream` (max 0x280000) with: tag `'Char'`; `"hhhh"`
   {`DAT_100d73f0`, `PTR_DAT_100cdcf4`, `DAT_100d73f2`, `DAT_100d73f4`}; 32 × `"b"` byte variables
   (`PTR_DAT_100cdbbc`, the `EvalCondition` 0x80-class vars); 8 × `"l"` flag words
   (`PTR_DAT_100cdbc0`, 256 global flags); `"l"` clock (`DAT_100d3e18`); `"h"` day
   (`DAT_100d3e1c`); `"b"` viewer byte +0xd; `"l"` accumulated play seconds (`PTR_DAT_100ce3c8`,
   updated from `GetDateTime`); 27 × `"b"` zero padding; then `TActiveMonster::SaveMonsters`,
   `TSpellFX::WriteFXQueue`, `TInventoryWindow::MarshalAll`, `TGremlin::SaveGremlins`. Format
   strings resolved with `tools/toc.py 100ce360 100ce35c 100ce358 100ce354` → `hhhh`, `b`, `l`,
   `h`. [HIGH for order/types; the four `hhhh` values are NOT RESOLVED]
4. Every segment of the scratch file is copied in; `Compact` if requested. [HIGH]

`RestoreModel__10TDelverAppFv @ 10013ff4` reads the same order back. [HIGH]

NOT RESOLVED here: the stream encodings of `SaveMonsters`, `WriteFXQueue`, `MarshalAll`,
`SaveGremlins` (functions identified, not read field-by-field).
