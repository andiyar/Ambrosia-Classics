# Cythera 1.0.4 — map rendering: `Render__7TViewerFssss` layer order (code reading)

⚑ wave 3 (2026-10-06). Register: **code reading only** — what the PPC code draws and in what
order; nothing play-verified. Labels: **HIGH** = an address plus a quoted decompiled line or
instruction proves it; **MED** = inferred from structure, names or one source; **LOW** =
conjecture; **NOT RESOLVED** = not read. `p:NNNNN` = line in `ghidra/Cythera_pef.decompiled.c`.
Closes INDEX NOT RESOLVED 16 (layer-order half); the wall-clock half is engine-classes.md §3.4.

---------------------------------------------------------------------------------------------
## 0. Scope, inputs, commands

- **Read whole:** `Render__7TViewerFssss @ 10066ac0` (length 0x223C, `tb.py --at 10066ac0`;
  p:32113–33454) against `python3 docs/cythera/tools/ppcdis.py 10066ac0 10068cfc` (2,191
  instructions). **Read for the tie-ins:** `SetStage__7TViewerFss @ 10065034` (p:31356–32005, ladder
  checked against `ppcdis.py 10065034 10066730`), `NoLOS @ 100693e4` and the staging tail of `LOS
  @ 10069554` (p:33612–33960), `ApplyRoof @ 10068d24`, `ApplyFilter @ 10064e00`, `ApplyLight @
  10064eac`, `MaskAnyTile` (both), `TMaskTile`, `TCopyTile`, `TCopyCompoTile`, `DoPropFX @
  1006683c`, `AdjustPropFX @ 10066a44`, `SetEraseColor @ 10066a88`, the render chain of
  `DrawRoutine__11TGameViewerFs @ 1005c844` (p:27739–27960), `GetField`/`SetField` case 0xC.
- **Data words** (TOC-relative tables): `python3 -c "import sys; sys.path.insert(0,'docs/cythera/tools');
  import toc; print([hex(x) for x in toc.data_u32(0x100d5fa4,24)])"` →
  `['0x0', '0x10001', '0x0', '0x0', '0x1', '0x0', '0xff9eff9e', '0xff9eff9e', '0x44ff9e', '0x0',
  '0x0', '0x40000', '0x100000', '0x100210', '0x100210', '0x100210', '0x0', '0x10', '0x100000',
  '0x200', '0x0', '0x0', '0x0', '0x10']` (§2.4).
- **Tile-flag names** (data, not code): `python3 docs/cythera/tools/tileflag_census.py …` (new
  tool, header documents its expected output).
- **Not read:** `CalcLighting`, `DimOffLevel`, `InteractProps` bodies (only their place in the
  chain); the full `LOS` shadow-casting walk; THood insertion order (`AddToHood`, `MoveHood`);
  the vtable hook `*_DAT_100cea80` after lighting; the screen-transition blit.

---------------------------------------------------------------------------------------------
## 1. Whole-frame order, first pixel to last [HIGH unless marked]

All drawing goes into the viewer's offscreen buffer: base pointer viewer `+0xB0`, rowBytes `+0xB4`,
a square of (N+1)×32 pixels (N = view size in tiles, viewer `+0`; h = viewer `+2`, the centre
offset; engine-classes.md §5). Call chain in `DrawRoutine` (p:27923–27957; `bl` addresses from
`ppcdis.py`):

| # | step | where | what it puts on screen |
|---|---|---|---|
| 0 | `SetStage(x, y)` (full redraw only) | p:27825 | nothing drawn: builds the stage + staged list (§5, §6) |
| 1 | `LOS` or `NoLOS` | `1005cd4c` / `1005cd64`; p:27923 `if ((PTR_DAT_100cdbf0[0x1a] & 0x80) == 0) { _LOS__7TViewerFss(…)` | view-cell visibility grid + the Render staged list (§6) |
| 2 | `InteractProps`, `CalcLighting`, `DimOffLevel` | `1005cd78`, `1005cd8c`, `1005cda0` | nothing drawn; light map computed (bodies not read) |
| 3 | **`Render(viewer, x, y, subX, subY)`** | `1005cdbc`; p:27932 | §2: backdrop pre-pass → ground → passes 0–5 (FX at the top of pass 5) → backdrop post-pass |
| 4 | `ApplyRoof(x, y, +0x20C2C)` (LOS mode only) | `1005ce04`; p:27933–27934 | roofs over everything Render drew (§1.1) |
| 5 | `ApplyFilter(*(viewer +0x18 + frame·4))` (a per-frame LUT pointer) | `1005ce34`; p:27938 | whole-buffer colour lookup `*p = lut[*p]` (p:31292 `*pbVar5 = *(byte *)(param_2 + (uint)*pbVar5);`) |
| 6 | `ApplyLight()` (LOS mode, leader CharEntry +6 bit 0x400 clear) — else `ApplyFilter(viewer +0x20C8C)` | `1005cec8` / `1005ce8c`; p:27940–27946 | per 4×4-pixel block of the light map at viewer +0x80BC: level 0 → filled with 0xFF, 1..31 → `SubLightSolid`/`SubLightDither` (odd/even), ≥32 untouched |
| 7 | vtable hook `*_DAT_100cea80` (+ offscreen base) | `1005cef4` | NOT RESOLVED |
| 8 | in the window GWorld (viewer +0x78): `ShowBarks`, then tile 0x186 (`PTR_DAT_100cdc28 + 0x618`) via `MaskTile` at (+0x20C32, +0x20C34)+h when byte +0x20C30 is set | `1005cf2c`, `1005cf70`; p:27954–27959 | speech barks, a one-tile marker [MED: marker's purpose not traced] |

`subX/subY` = the leader prop's byte 6 bits 0–1 / 4–5 when prefs byte 0x100d3e20 bit 7 (sub-tile
movement) is set, else 0 (DrawRoutine p:27811–27818). So lighting (5–6) darkens everything Render
and ApplyRoof drew, FX and backdrops included; barks and the marker are drawn after lighting.

### 1.1 Roofs (`ApplyRoof @ 10068d24`) [HIGH as code]
Walks the SetStage list (+0x1DC16/+0x1DC18) for kind `'D'` (0x44, p:33499); each covers the 8×8
chunk (data-format.md §3.3) ending at its (x, y). A roof id (frame field) is shown when any non-zero
chunk cell of any of its props lies on a visible view cell; the roof the leader stands under is then
removed (p:33542 `acStack_6e[param_1[0x1060d]] = '\0';`, viewer +0x20C1A). Every non-zero chunk cell of a
shown roof is drawn with `MaskAnyTile(…ll)` (p:33567), unseen view cells under it become 3 (p:33569),
and the light map under its opaque 4×4 blocks is set to `b/5` (32 when b ≥ 160), b = the fourth
argument = viewer +0x20C2C (p:33588) — roofs ignore the party light [HIGH code; b = the brightness
of engine-classes §3.3, MED]. Roofs are drawn **after** pass 5 and the backdrop
post-pass, so they cover creatures, FX and tall props.

---------------------------------------------------------------------------------------------
## 2. Inside `Render__7TViewerFssss`

### 2.1 Viewer fields Render touches [HIGH: census of every `r31`-relative operand in the listing]
+0 N; +2 h; +4 view-cell row stride (N+2); +0xC redraw byte (cleared on exit, `10068ce4: stb
r13,12(r31)`); +0xD "mark seen" byte; +0x10 vtable; +0x78 window GWorld; +0xB0 offscreen base;
+0xB4 rowBytes; +0xB8 "stage has a 0x10000000 tile"; +0xB9 erase colour; +0xBA animation frame
0..7; +0xC0C8 view-cell grid ((N+2)², bits 0–1 visibility); +0xC1EC per-tile wall-face pointers;
+0x1FC18 staged count / +0x1FC1A staged prop indices; +0x20C1C/+0x20C1E map W/H; +0x20C20/+0x20C22
wrap sizes. **Render never reads the 31×31 stage (+0x141EC) or the quarter-tile grid (+0x15FF4)**:
every ≥ 0x10000 offset in the listing (the 27 `addis …,1` / `addis …,2` sites) leads to +0xC0C9 +
stride (`10066b20: addis r26,r14,1` / `10066b28: addi r26,r26,-16183` / `10066b34: add r26,r31,r26`),
+0xC1EC + tile·4 (`10067354`–`1006735c`), +0x1FC18/+0x1FC1A (displacements −1000/−998 off
`+0x20000`) or +0x20C1C..22 (3100–3106 off `r31+0x20000`). So the SetStage priority nibble plays no part in draw
order (§5).

### 2.2 Step A — backdrop pre-pass (only when +0xB8 ≠ 0) [HIGH]
- Gate: `10066b08: lbz r14,184(r3)` … `10066b3c: beq 0x10067038`. SetStage sets +0xB8 when any
  stage cell's tile has flag 0x10000000 (p:31463 `*(undefined1 *)(param_1 + 0xb8) = 1;`).
- Fills the whole buffer with the erase colour: `10066b70: bl 0x100b46a0` = the MSL fill routine
  (dst, byte, n) with (+0xB0, (char)+0xB9, (N+1)·rowBytes·32) (p:32331). Erase colour = 0xFF after
  `ChangeZone` (`SetEraseColor(…, 0xff)`; `SetEraseColor @ 10066a88` stores +0xB9).
- Walks the Render staged list from last to first (`10066b7c: lha r14,-1000(r15)` = +0x1FC18, then
  −1) and draws every **kind 0x42 (`'B'`) frame 10** prop (`10066c04: cmplwi r14,0x42`, `10066c24:
  cmplwi r7,0xa`) whose `sext6(byte E)` is **negative** (`10066c50: bge 0x10067018` skips ≥ 0):
  picture = `NewPix(cache, &pm, type)` (`10066d50`), placed with `OffsetRect` and drawn with
  `CopyBits(…, 0x24, 0)` (p:32462; mode 36 = transparent).
- Placement (decompiled arithmetic, p:32394–32450) [MED as a reading of the formula, HIGH for the
  constant `10066e28: addi r14,r14,34`]: scale k = 2·sext6(E) + 34 px per tile of distance from the
  leader; left = h·32 + k·(px − x) + (8 − k/4)·subX − width/2 + 16, same for y with subY. E = −1 →
  k = 32 (moves with the map); E < −1 → slower (a distant backdrop).

### 2.3 Step B — ground cells [HIGH]
Rows y = −h … h+1, columns x = −h … h+1 (p:32488–32492; loop ends `100676d4` / `10067678`), i.e.
view cells 0..N in both directions, row-major. Per cell (view-cell byte `v` at +0xC0C8, starting at
row 1 col 1):
1. `v & 3 == 0` (unseen) → `CopyTile(tile 0xFF)` (`10067058: rlwinm. r13,r13,0,30,31`, `10067084:
   lwz r4,1020(r15)` = frame table + 0xFF·4, `100670a0`).
2. Else the map word (wrapping by +0x20C20/22 when non-zero, else tile 0xFF off-map); if +0xD is set
   the word gets 0x8000 = automap "seen" (`1006732c: ori r15,r13,0x8000`).
3. `v & 3 == 2` → wall-face substitution through +0xC1EC (`1006733c: cmpwi r15,2`): take alt[0..3]
   for the first unseen neighbour N/E/S/W, repeat until stable, ≥ 0x2000 → 0xFF (data 0xF00D).
4. Draw by tile flag / word bits: flag **0x10000000** → `MaskAnyTile(…ll)` (`10067448: rlwinm.
   r13,r13,0,3,3` → `10067480`; colour 0 stays transparent, showing step A); else word **0x1000**
   (compo) → `TCopyCompoTile` (`1006751c`, word also 0x2000) / `CopyCompoTile` (`1006758c`); else
   word **0x2000** → `TCopyTile` (`100675f8`); else `CopyTile` (`10067654`).
- `T…` = **transposed** copy: `TCopyTile @ 10062de4` / `TMaskTile @ 10063534` write destination row k
  from source column k (`*puVar3 = *param_2; puVar3[1] = param_2[0x20]; puVar3[2] = param_2[0x40];
  …`). So word/prop bit 0x2000 is a diagonal flip, not a mask variant. [HIGH]

### 2.4 Step C — the pass loop: selection tables [HIGH]
Counter at 162(r1) runs 0..5 (`100676e4` sets 0; `1006878c: cmpwi r13,6` / `10068790: blt 0x100676ec`).
At the top of each pass, six per-pass words are loaded (`10067744: addi r14,r2,3388 ; = 0x100d5fbc`,
`1006774c … 0x100d5fc8`, `10067760 … 0x100d5fa4`, `10067774 … 0x100d5fb0`, `100677c4 … 0x100d5fd4`,
`100677d8 … 0x100d5fec`); values from the §0 dump (u16 tables split into halves):

| pass | kindMask 0x100d5fbc | kindVal 0x100d5fc8 | A 0x100d5fa4 | B 0x100d5fb0 | flagMask 0x100d5fd4 | flagVal 0x100d5fec |
|---|---|---|---|---|---|---|
| 0 | 0xFF9E | 0 | 0 | 0 | 0x100000 | 0x100000 |
| 1 | 0xFF9E | 0 | 0 | 0 | 0x100210 | 0x200 |
| 2 | 0xFF9E | 0 | 1 | 0 | 0x100210 | 0 |
| 3 | 0xFF9E | 0 | 1 | 1 | 0x100210 | 0 |
| 4 | 0x0044 | 4 | 0 | 0 | 0 | 0 |
| 5 | 0xFF9E | 0 | 0 | 0 | 0x10 | 0x10 |

Each pass walks the Render staged list **from last to first** (`10067834: b 0x10068768` …
`1006875c: lha r13,152(r1)` / `addi r13,r13,-1` / `10068770: bge 0x10067838`) and, per prop:
1. pass 5 only: FX byte update (§4);
2. rough bounds: prop cell (before offsets) in 0..N+3 both ways (`10067a08`–`10067a48`);
3. **kind test**: `(kind & kindMask) == kindVal` (`10067a68: and r13,r15,r13` / `10067a7c: cmpw r14,r13`
   / `bne 0x1006875c`);
4. **dead test**: `(1 & A) == B` — the left operand is the constant 1 (`10067a4c: li r14,1` → 148(r1),
   the slot's only store, `10067a74`; `10067a98: and r13,r14,r13` / `10067a9c: cmpw r15,r13`). True for
   passes 0, 1, 3, 4, 5; **false for pass 2, which therefore never draws anything**;
5. tile = base[type] + frame (`10067b20: add r25,r13,r14`); sub-tile and sprite offsets (§3);
6. **per drawn tile**: `(tileflags[t] & flagMask) == flagVal` (`and rX,r20,rY` / `cmpw r19,rX` before
   every one of the 12 calls; r20/r19 loaded at `10067804`/`10067818`), and the tile's final cell in
   0..N. Main tile and each extension tile are tested **separately**, so one multi-tile object can be
   split across passes.

What each pass draws (kind & 0xFF9E == 0 ⇔ kind ∈ {0x00, 0x01, 0x20, 0x21, 0x40, 0x41, 0x60,
0x61}; of these SetStage stages 0x00, 0x01, 0x20, 0x21, 0x40 — §6; kind & 0x44 == 4 ⇔ bit 2 set,
bit 6 clear: the staged kinds 0x04 and 0x24):

| pass | draws | tile-flag condition (per tile) | data census (`tileflag_census.py`) [names LOW] |
|---|---|---|---|
| 0 | objects (kinds 0/1/0x20/0x21/0x40) | 0x100000 set | 295 tiles: snowcaps, mountains, table, steps, carpet, shore, floor, footprints… |
| 1 | objects | 0x200 set, 0x100000 and 0x10 clear | 0x200: 973 tiles (walls, tables, many creature images) |
| 2 | nothing (dead test) | (0x100000, 0x200, 0x10 all clear) | — |
| 3 | objects | 0x100000, 0x200, 0x10 all clear | the rest |
| 4 | **creatures: kind 0x04 (written by `HatchEgg` `1004f484: li r0,4` / `1004f48c: stb r0,0(r4)`; a character placed on stage, MED) and 0x24 (spawned monster, `1004f8c4: li r3,36` / `1004f8d8: stb r3,0(r24)`; schedules-npcs.md §8)** | none (mask 0) | — |
| — | in-flight FX: `RenderMissiles` (vtable +0x10) at the top of pass 5, before its list walk (`100676f0: cmpwi r13,5` … `10067704: bl 0x100c50e8`; magic.md §11.3) | — | — |
| 5 | objects | 0x10 set | 295 tiles: hydra, tree, wall, ancient tree, cavern, archway, sign, well… |

- Order on screen: ground < pass 0 < 1 < 3 < creatures < FX < pass 5 < backdrop post-pass < roofs.
  A tile with both 0x100000 and 0x10 is drawn in pass 0 **and** 5 (`--eq 0x100010` → 1 tile,
  "cavern"); 0x210 tiles (72: doors, bookshelves, hydra) go to pass 5 only. [HIGH code; counts HIGH]
- Kinds never drawn by any pass: 0x02/0x03/0x22/0x23 (0x800 markers), 0x42 (except the backdrop
  passes), 0x44 (roofs → ApplyRoof), contained/inventory kinds (not staged). [HIGH]
- Reading of the flags [MED/LOW]: 0x100000 = flat/ground-level object (drawn first, under
  everything; SetStage gives it targeting priority 1 when 0x800 is clear and no earlier ladder row
  applies, §5); 0x10 = tall/overhanging part drawn over creatures and missiles (priority 1 when 0x20
  is clear and no earlier row applies); 0x200 = "drawn before
  ordinary objects" — its role is not explained by the code.

### 2.5 The twelve `MaskAnyTile__7TViewerFUslls @ 10063cc0` sites [HIGH]
Arguments (r3 viewer, r4 tile, r5 column x, r6 row y, r7 = FX byte, `rlwinm r7,r21,0,24,31` at every
site). Mirror = prop byte 4 bit 7 (`10067dd8: rlwinm r14,r15,25,31,31`, `10067df0: beq 0x10068340`
→ plain sites when clear). Extension = `tileflags[t] & 0xC0` of the **unflipped** base tile.

| site | mirror | ext. flags | tile drawn | cell |
|---|---|---|---|---|
| `100683c8` | no | any | t | (x, y) |
| `100684e4` | no | 0x40 | t−1 | (x, y−1) |
| `10068584` | no | 0x80 | t−1 | (x−1, y) |
| `10068634` | no | 0xC0 | t−1 | (x−1, y) |
| `100686c0` | no | 0xC0 | t−2 | (x, y−1) |
| `10068750` | no | 0xC0 | t−3 | (x−1, y−1) |
| `10067e90` | yes | any | t ^ 0x2000 | (x, y) |
| `10067fb0` | yes | 0x80 | (t−1) ^ 0x2000 | (x, y−1) |
| `1006807c` | yes | 0x40 | (t−1) ^ 0x2000 | (x−1, y) |
| `10068174` | yes | 0xC0 | (t−2) ^ 0x2000 | (x−1, y) |
| `10068258` | yes | 0xC0 | (t−1) ^ 0x2000 | (x, y−1) |
| `10068338` | yes | 0xC0 | (t−3) ^ 0x2000 | (x−1, y−1) |

The flag test at each extension site reads `tileflags[t−k]` (e.g. `10068688: addi r15,r13,-2` →
`10068690: lwzx r14,r22,r14` before the call at `100686c0`). Mirror therefore transposes every tile and swaps the roles of the
up/left neighbours: the whole multi-tile object is flipped about its bottom-right diagonal. [HIGH]

### 2.6 Step D — backdrop post-pass and exit [HIGH]
After pass 5 (`10068790` falls through) the staged list is walked again, last to first
(`100687a0: lha r14,-1000(r14)`), drawing kind 0x42 frame 10 props with `sext6(E) ≥ 0`
(`10068890: blt 0x10068ca8` skips negatives) — **not** gated by +0xB8. Same `NewPix`/`OffsetRect`/
`CopyBits(…, 36, 0)` (`10068998`, `10068c70`, `10068ca0`); scale k = 32 − 2·sext6(E)
(`10068a60: subfic r13,r13,32`), left = h·32 + k·(px − x) − k·subX/4 − width/2 + 16 [MED formula].
These are drawn over everything Render drew. Then +0xC := 0 and return (`10068ce4`). No sound,
lighting, LOS or roof work happens inside Render; ambient-sound placement rides inside
`RenderMissiles` (magic.md §11.3).

---------------------------------------------------------------------------------------------
## 3. Where the sprite offsets apply (props only, inside the pass loop) [HIGH]
All three adjust the **destination** (base pointer +0xB0, restored after the prop at p:33437
`*(int *)(param_1 + 0x58) = local_2a0;`) and/or the target cell; ground and backdrops are untouched.
1. **Sub-tile position** (byte 6): base += (b6 & 3)·8 + ((b6 >> 4) & 3)·8·rowBytes — 8 px steps
   right/down (`10067b68`–`10067bb4`). Applied when (prefs byte 0x100d3e20 bit 7 **and** kind 4 or
   0x24) or type flag 0x4000 (script property 0x28 bit 0x40) is set (`10067ad4: rlwinm
   r14,r13,25,31,31`, `10067b2c: cmplwi r13,0x4`, `10067b38: cmplwi r13,0x24`, `10067b60: rlwinm.
   r13,r15,0,17,17`).
2. **Sprite offset**: dx = 4·sext6(byte E) + offA[type·32 + frame], dy = 4·sext6(byte E) +
   offB[type·32 + frame], with offA = 0xF011 (`PTR_DAT_100cdc08`) and offB = 0xF012 (`…c04`),
   swapped when mirrored (`10067bcc: rlwinm r13,r15,26,0,6` / `srawi r13,r13,26` / `rlwinm
   r13,r13,2,0,29` = `sext6(E) << 2`; table picks `10067c1c`/`10067c64`/`10067cc8`/`10067d10`). Then
   x −= dx >> 5, y −= dy >> 5 and base −= (dx & 31) + rowBytes·(dy & 31) (`10067d70`–`10067dd4`):
   **positive values move the sprite up and left**; E shifts both axes equally.
3. **Multi-tile extension** (§2.5): the extension cells are relative to the offset cell from 2.
The same base pointer feeds `MaskTile`/`TMaskTile` (x·32 + rowBytes·y·32 from +0xB0), which reject
cells outside 0..N with `DebugStr` (`TMaskTile @ 10063534`). [HIGH]

---------------------------------------------------------------------------------------------
## 4. The prop FX byte (the trailing `s` of `MaskAnyTile(…lls)`) [HIGH as code; effect names MED]
- Storage: a byte per prop index, `PTR_DAT_100cdc40` → `NewPtrClear(0x4400)` (p:432–434); script
  field **0x0C** of a prop (`GetField` p:47521 `*param_1 = (uint)*(byte *)(*(int *)PTR_DAT_100cdc40 +
  (int)(short)param_2);`, `SetField` p:47893); `MoveAll` also writes 0/1 (p:21564, p:21607) and `FollowLeader` writes `('\x05' - (char)local_58[sVar13]) * '\x04' + '.'`.
- Render reads it per staged prop (`100678e8: lbzx r21,r14,r15`) and passes it to every draw. In pass
  5 only, `AdjustPropFX` (`10067910`) steps it and stores it back (`10067968: stbx r14,r15,r13`): high
  nibble 0 → unchanged; low nibble ≠ 0 → −1; else → 0. The pass-5 draw still uses the old value
  (r21 is written only at `100678e8`). So an effect lasts low-nibble+1 frames.
- `DoPropFX @ 1006683c` (called by `MaskAnyTile(…lls)` before the mask copy): 0x1n → pixels whose low
  colour nibble > n become transparent; 0x2n → each colour c in 0x10..0xCF with bit 0x10 becomes c + 16 − n when that stays in
  c's 16-colour row, else 0xFF; 0x3n → pseudo-random dissolve (LCG ×21+11,
  keep when value ≤ n); 0x01 → copy, then overlay the 32×32 image at tile-pixel buffer + 0x61400
  (tile 0x185) [MED: `PTR_DAT_100cdc64` = the 0x280000-byte tile buffer from `LoadTiles`]; other →
  plain copy.

---------------------------------------------------------------------------------------------
## 5. SetStage's priority ladder vs Render (engine-classes.md §5 "priority 1..8") [HIGH]
**The ladder does not order drawing.** Render never reads the stage (§2.1). The ladder fills each
stage cell's "best prop" (u16 at +6, priority nibble at +4 bits 4–7, best tile at +4 bits 15–27),
read back by `GetBestProp @ 1006b188` / `GetBestPropRel @ 1006b2e0` / `GetBestTile @ 1006b3b4`, whose
callers are targeting/interaction code: `LookCommand`, `SearchCommand`, `UseOnCommand`, `ShortName`,
`MoveCommand`, `XDirection`, `CursorRoutine`, `FindSurface`, `PointToProp`, `KeyTargetToProp`,
`TLineEffect::DoBresPixel` (grep of the three names over the four dumps). The higher priority wins a
cell (`<` test, p:31634). Ladder (p:31576–31627; uT = tileflags[tile], uY = typeflags[type]), first
match:

| order | condition | priority |
|---|---|---|
| — | prop from the 0xF010 tile list (pseudo, `local_56 < 0`) | −1 (never best) |
| 1 | kind 4 or 0x24 | 7 |
| 2 | uT & 0x10000000 | −1 |
| 3 | uY & 0x100000 (property 0x24 "weight" present): uT & 0x200 → 4, else 5 | 4 / 5 |
| 4 | uY & 0x400000 (property 0x37) | 7 |
| 5 | uY & 0x1000800 (0x1000000 = property 0x3A, 0x800 = property 0x28 bit 0x10) and not uT & 0x100000 | 8 |
| 6 | uT & 0x100000 and not uT & 0x800 | 1 |
| 7 | uT & 0x20000 | 2 |
| 8 | uY & 0x200000 (property 0x25) | 4 |
| 9 | (uT & 0x30) == 0x10 | 1 |
| 10 | otherwise | 3 |

- Priority **7 is never stored as best prop for the main cell** (`&& (local_5e != 7)`, p:31634); instead
  the prop index is written into the 124×124 quarter-tile grid (+0x15FF4): a 4×4 block offset by the
  byte-6 sub-position when prefs bit 7 is set, else one quarter cell (p:31640–31661). Readers:
  `HatchEgg`, `SwitchParty`, `InteractProps` (grep `0x15ff4`). So that grid is an **occupant grid for
  creatures and property-0x37 objects**, not roof ownership (roofs use +0x20C1A and the 'D' chunks,
  §1.1). Extension cells of a creature have no `!= 7` guard (p:31680ff.). [HIGH code; "occupant" MED]
- Pass ↔ priority, where they meet: pass 0's 0x100000 tiles are priority 1 (row 6); pass 5's 0x10
  tiles are priority 1 when 0x20 is clear (row 9); creatures (pass 4) are 7. So the low-priority
  layers for clicking are the floor and overhead layers, consistent with the draw order, but there is
  no table mapping one to the other. [HIGH for each row; "consistent" MED]
- **Disagreement on 0xC0 objects** [HIGH]: SetStage marks a 0xC0 object's cells as t−1 **up**, t−2
  **left**, t−3 up-left for both mirror states (`10065fbc: stwu r4,-248(r19)` with `addi r3,r9,-1`,
  then `10066190: stwu r0,240(r19)` with `addi r6,r6,-2`, then `10066364: stwu r4,-248(r19)` with
  `addi r3,r3,-3`; only 0x40↔0x80 are swapped for mirror, `10065b74`–`10065b98`). Render draws an
  unmirrored 0xC0 object as t−1 **left**, t−2 **up** (§2.5). For unmirrored 2×2 objects the up and
  left cells therefore carry each other's tile flags/best tile (walls, LOS, targeting) relative to what
  is drawn; mirrored ones agree. 79 tiles have 0xC0 (`tileflag_census.py --eq 0xc0`: mountains,
  snowcaps, titan, tree, cities…). [Whether any shipped prop or map content is affected: NOT RESOLVED]

---------------------------------------------------------------------------------------------
## 6. The two staged lists [HIGH unless marked]
- **SetStage list** (+0x1DC16 count ≤ 0x1000, +0x1DC18 indices): built in walk order — first the
  0xF010 pseudo-props (kind 0x40, `local_56` from −n: `PTR_DAT_100cead4[(-1 - local_56)]`, p:31492),
  then the THood entries in hood order (`PTR_DAT_100cdbc8 + local_56 * 2 + 8`, p:31495). Staged kinds
  (dispatch `10065434`–`100654a4`): 0x00, 0x01, 0x04, 0x20, 0x21, 0x24, 0x40 inside the 31×31 window;
  0x42 when frame 10 or inside the window; 0x44 when its 8×8 chunk (x−8..x, y−8..y) lies inside it; 0xC2 outside
  the window reverts to 0x42. 0x02/0x03/0x22/0x23 are not staged: they only OR 0x800 into their stage cell when their tile has
  flag 0x800 (`100656b0: ori r0,r4,0x800` / `100656b8: b 0x10066730`); 0x05–0x1F, 0x25–0x3F, other
  ≥ 0x80 are skipped.
- **Render list** (+0x1FC18 count ≤ 0x800, +0x1FC1A): `NoLOS` (p:33624–33644) sets every view cell
  to 1 and keeps SetStage-list props whose view cell is in 0..N+1; `LOS` (p:33914–33960) keeps the
  leader unconditionally and any other prop in view whose view cell is visible (state 1), or state 2
  with tile flag 0x420. Order = SetStage-list order.
- **Draw order within a pass** = Render list reversed: THood entries last-to-first, then the
  pseudo-props. Among props of the same pass on the same cell, the one earlier in the hood ends on
  top. [HIGH for both walk directions; the hood's own order (AddToHood/MoveHood) NOT RESOLVED]
- Backdrops ('B' frame 10) are drawn only if staged by LOS/NoLOS, i.e. their anchor cell must be in
  view (and visible in LOS mode). [HIGH as code]

---------------------------------------------------------------------------------------------
## 7. Still open
- THood order (decides overlap within a pass); `CalcLighting`/`DimOffLevel`/`InteractProps`
  bodies; the post-lighting vtable hook; marker tile 0x186's purpose. [NOT RESOLVED]
- Why pass 2 exists (identical masks to pass 3, killed by a constant) — LOW: a compiled-out
  condition; only its effect (never draws) is HIGH.
