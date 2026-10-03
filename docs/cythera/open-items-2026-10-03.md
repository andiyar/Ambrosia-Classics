# Cythera 1.0.4 — INDEX "NOT RESOLVED" work order, 2026-10-03

Register: **code reading**. Labels: HIGH = quoted decompile / disassembly / bytes prove it; MED =
inferred; LOW = conjecture. Every byte below came from a command run in this session. `$G` =
`/Users/andiyar/Developer/Ambrosia/Resources/ambrosia-extracted/RPG/Cythera/Cythera (installed)/files`.
Items are numbered as in `INDEX.md` § NOT RESOLVED; the later fix pass folds these into the
topical files.

**Method notes (reproducible).**
- Ghidra dropped some functions (the TStream format reader/writer, `TViewer::AddSound`, the
  `TMapWindow::KeyRoutine` body is merged into `ShowTileAnimate`). For those I used a ~60-line PPC
  decoder (scratch, not committed): code section = file offset 0x3470, loaded at 0x10000000;
  instruction at `A` = big-endian u32 at `0x3470 + (A − 0x10000000)`. Function names come from the
  **traceback tables** that follow each body (`00 00 00 00 00 09 …` then a length-prefixed name).
- TOC register: `LoadLevelMap` does `lwz r3,-30292(r2)` for TOC slot 0x100CDC2C ⇒ **r2 =
  0x100D5280**. `addi rX,r2,8562` = 0x100D73F2 etc. — this is how direct-addressed globals were
  enumerated (every load/store/addi with rA = 2 scanned over the whole code section).
- `FUN_100c50e8` is **`__ptr_glue`**, not a function: `lwz r0,0(r12); stw r2,20(r1); mtctr r0;
  lwz r2,4(r12); bctr` (disasm @ 0x100C50E8). Every "unnamed glue" call is an indirect call through a
  TVector in r12 — almost always a C++ virtual (`lwz r12,0(this); lwz r12,off(r12)`). Vtables were
  resolved by reading the vtable words from the unpacked data section (`tools/toc.py` `D`), each word
  = data offset of a TVector, whose first word = code offset.

---------------------------------------------------------------------------------------------
## 1. Segment-file header (0x00–0x7F) — RESOLVED (HIGH except where marked)

```
$ xxd -l 0x80 "$G/Cythera Data"
00000000: 1743 7974 6865 7261 3a20 4661 7465 206f  .Cythera: Fate o
00000010: 6620 416c 6172 6963 0000 0000 0000 0000  f Alaric........
00000020: 0000 0000 0000 0000 0000 0000 0000 0000  ................
00000030: 0000 0000 0000 0000 0000 0000 0000 0000  ................
00000040: 1300 0200 0000 0000 0200 0000 0000 0000  ................
00000050..0x7F: all 0
```
| off | type | meaning | evidence | conf |
|---|---|---|---|---|
| 0x00 | Pascal str (len 0x17) | scenario title | bytes | HIGH (no reader traced; copied whole into new player files) |
| 0x20 | Pascal-ish str ≤ 0x1F | **player files only**: the character name = the player file's name | `NewGame__10TDelverAppFP6FSSpec @ 100152a4`: 16×8-byte copy of the scenario header (`PTR_DAT_100cdcfc`) into the new header, then `FUN_100bcaec(puVar2 + 0x20, auStack_6a, 0x1f)` where `auStack_6a` is the FSSpec name field (FSSpec at `local_70`: vRefNum, parID, name at +6); `GetCharacterName`: `FUN_100b6d24(param_2, PTR_DAT_100cdba0 + 0x21, 0x1f)` (strncpy) and `OpenPlayerFile` `ReadHeader(…, PTR_DAT_100cdba0)` | HIGH for the data flow; MED that `FUN_100bcaec` (lazy-bound glue via `_DAT_100cf30c`) is a Pascal-string copy |
| 0x40 | i16 | **engine data-format version** 0x1300 — the field `CompatibleVersions` checks | `OpenScenFile__10TDelverAppFR6FSSpec @ 10014694`: `_ReadHeader(…, puVar4); cVar13 = _CompatibleVersions__13SegFileHeaderFss(0x1300,(int)*(short *)(puVar4 + 0x40)); if (cVar13 == '\0') { … StopAlert(0x400,0); ExitToShell(); }` | HIGH |
| 0x42 | i16 | **scenario version** 0x0200 — patch files and player files must match it | same function, patch loop: `CompatibleVersions(0x1300, local_1d6)` then `CompatibleVersions((int)*(short *)(puVar4 + 0x42), (int)local_1d4)` (`auStack_216[64]` ⇒ `local_1d6` = +0x40, `local_1d4` = +0x42); `CheckPlayerFile @ 10014b44`: `CompatibleVersions((int)*(short *)(PTR_DAT_100cdcfc + 0x42), (int)local_56)` (`auStack_98[66]` ⇒ +0x42) | HIGH |
| 0x48 | i16 | **maximum map dimension** 0x0200 (0 → 0x400); sizes the map buffer `dim·dim·2` and the block/seen buffers | `InitWorld__10TDelverAppFv @ 10012e38`: `_CreateGlobals__Fs((int)*(short *)(PTR_DAT_100cdcfc + 0x48))`; `CreateGlobals @ 10004d0c`: `*(int *)puVar1 = (int)param_1; if (… == 0) … = 0x400; NewPtr(dim * dim * 2)` | HIGH |
| 0x44, 0x46, 0x4A–0x7F | — | zero; no reader in the four header users (`OpenScenFile`, `CheckPlayerFile`, `OpenPlayerFile`, `NewGame`, `InitWorld`) | grep of `PTR_DAT_100cdcfc` / `PTR_DAT_100cdba0` (6 hits) | HIGH (no PPC reader) |

`CompatibleVersions(a,b)` = same high byte and `b.lo ≤ a.lo` (`@ 10008c90`). Patch files: names
from `STR# 0x81` items 1..9 (`GetIndString(local_14e,0x81,iVar9)`), each pushed onto the overlay
stack with `AddFile`. **`Cythera.rsrc` has no `STR# 129`** (census of every `STR#` this session: Cythera.rsrc
has 500–503, 990, 9300–9321, 31999; Cythera Data.rsrc has 128, 134, 135, 255, 900), so the patch loop is a no-op in the shipped
install [HIGH]. New player files are type/creator `'DelP'`/`'Delv'`
(`__ct__8TSegFileFR6FSSpecUlUl(iVar7,&local_70,0x44656c76,0x44656c50)`) [HIGH].

---------------------------------------------------------------------------------------------
## 4. Map header +0x04, +0x14..+0x1F; `C*0x40` vs `C*0x80` — RESOLVED (HIGH)

- **No reader.** The header buffer is TOC slot `PTR_DAT_100cdbd4` → data+0x1882C, 0x20 bytes. Its
  only users are `LoadLevelMap`, `SaveLevelProps`, `MoveCommand`, `SetViewerLocation` (4 grep hits),
  which read +0, +2, +6, +8, +0xA, +0xB, +0xC..+0x12 only. No other TOC slot points inside the
  header: scanning every TOC word for values in [0x1882C−0x10, 0x1882C+0x30) finds only
  `0x100cdbd4 → 0x1882c` and `0x100cdbfc → 0x1884c` (= header+0x20, which is the 0xF00F table,
  item 6). Census (`tools/seg.py`, 42 maps): `+4 {'0000': 42}`, `+14..1f {'00…00': 42}`.
  ⇒ **+0x04 and +0x14..+0x1F are reserved/unused** in 1.0.4 [HIGH].
- **`C*0x40` is literal and is a latent defect**, confirmed by disassembly of `LoadLevelMap`:
  ```
  flat path     10005dd4: lha r7,8(r29)          ; C
                10005dec: rlwinm r6,r7,7,0,24    ; C << 7
                10005df0: addi r6,r6,32          ; + 0x20  → body offset
  chunked path  10005e9c: lha r8,8(r29)
                10005eac: rlwinm r6,r8,6,0,25    ; C << 6   (= C*0x40)
                10005eb0: addi r6,r6,32
  ```
  The chunk records themselves are loaded as `LoadSegment(…, 0x20, (int)*(short *)(puVar5 + 8) << 7)`,
  so in a chunked map the block-index array would be read from the middle of the chunk records.
  Harmless in 1.0.4 because every shipped map has `+6 == +8` (the chunked path never runs) [HIGH];
  "leftover from an older 0x40-byte chunk format" [LOW].

---------------------------------------------------------------------------------------------
## 5. Prop bytes +0x0A..+0x0F; kinds 0x11 and 0x80; 'B' frames — mostly RESOLVED

**Script field map for props (class 0x50 / 0)** — `GetField__Fsss @ 100921b4`, prop switch:
```c
case 0xf:  *param_1 = (uint)*(ushort *)((int)puVar8 + 10);
case 0x10: *param_1 = (int)((uint)*(byte *)((int)puVar8 + 0xe) << 0x1a |
                    (uint)(*(byte *)((int)puVar8 + 0xe) >> 6)) >> 0x1a & 0xfffffff;
```
`SetField__Fsss5VAddr @ 10092bd4`: `case 0xf: *(short *)((int)puVar12 + 10) = (short)param_4;`
`case 0x10: *(byte *)(+0xe) = (value & 0x3f) | old & 0xc0`.
- **+0x0A..+0x0B** = a free 16-bit script slot (field 0x0F, raw r/w). No script reads or writes
  field 0x0F (census §5 field list has no `0F`), and the PPC scan of every `lbz/lhz/lha/stb/sth`
  with displacement 10/11/14/15 in functions named `*Prop*`/`*Item*`/`*Stage*` hits only `TViewer`
  members. Data: `0000` in all 14,485 shipped records. ⇒ reserved [HIGH for the accessor, HIGH unused].
- **+0x0E bits 0–5** = signed 6-bit **elevation offset** (field 0x10), applied in
  `Render__7TViewerFssss @ 10066ac0` as `local_2a2 = (sext6(byte E)) << 2` and added to both the x and
  the y pixel displacement of the sprite (with the per-type/frame offsets of 0xF011/0xF012, item 6):
  ```c
  local_2a2 = (short)(((int)((uint)*(byte *)((int)puVar16 + 0xe) << 0x1a |
                            (uint)(*(byte *)((int)puVar16 + 0xe) >> 6)) >> 0x1a) << 2);
  … cVar12 = PTR_DAT_100cdc08[(type)*0x20 + frame]  (mirror bit set → PTR_DAT_100cdc04)
  local_2a4 = local_2a2 + cVar12;   … local_2a6 = local_2a2 + cVar12' ;
  ```
  i.e. the sprite is drawn shifted up-left by 4·E px (negative E = down-right). Data: 291 records
  carry it, values 0x3F (−1)×144+5, 0x3B (−5)×60, 0x3E/0x3D/0x3A/0x35/… and 1–7 [HIGH code; MED
  for the name "elevation"]. Bits 6–7 of +0x0E and byte +0x0F: no reader, 0 in data [HIGH unused].
- **Kind bit 0x80 = hidden/disabled.** `SetStage` never stages kinds ≥ 0x80 except 0xC2 (falls to
  `LAB_10066730`); `DrawRoutine` frame-7 groups set/clear it (below); scripts toggle it
  (`setfield A30.f00:kind = (128 ^ A30.f00:kind)` ×4, `| 128`, `& -129`, `== 128` tests). The 52
  shipped kind-0x80 records are map objects (kind 0) that start hidden until a frame-7 condition
  reveals them [HIGH code; MED for the data reading].
- **Kind 0x11 — STILL OPEN.** 55 records; bytes 2..3 hold small numbers (0x0004, 0x000C, 0x001F,
  0x0047 — character-sized indices), byte 1 = 0–6. `GetPropParent @ 10055d4c` returns 0 for it (only
  0x08–0x0B, 0x10, 0x18, 0x1C, 0x42/frame 9 have parents); `SetStage` does not stage it;
  `GetCurInvEncumb`/`ShuffleUpPartyInventory` test 0x10/0x18/0x1C only; no `0x11` kind compare in any
  function that touches the prop table; no script sets/tests kind 17. Tried: decompile grep, script
  census. Would settle: a reader in the not-decompiled functions, or the editor.

**'B' (0x42) frame sub-kinds — RESOLVED** from `DrawRoutine__11TGameViewerFs @ 1005c844` (runs for
staged 'B' props in the current zone, props ≥ 0x100):
```c
switch(pbVar15[4] >> 2 & 0x1f) {
case 0: _HatchEgg__14TActiveMonsterFsss(…);
case 1: if (IsInArea(x,y,p)) { uVar7 = teleports[type]; … sStack_5c = (char)PTR_DAT_100cdbfc[type];
        GoToLocation(…); viewer->+0x20c28 = sStack_5c; DrawRoutine(…,1); return; }
case 2: if (x,y == prop x,y) { SendSignal(type); *pbVar15 |= 0x80; }
case 4: _ChangeZone__11TGameViewerFs(param_1, type);
case 5: _PlayMusic__6TAudioFsUc(_DAT_100cdd24, type, 0);
case 6: if (IsInArea(…)) { SendSignal(type); *pbVar15 |= 0x80; }
case 7: *pbVar15 |= 0x80; cVar8 = _EvalCondition__FUcUc(pbVar15[6],pbVar15[7]);
        for the next `type` props: cVar8 ? (kind &= 0x7f, AddToHood) : (kind |= 0x80);
case 8: if (IsInArea(…)) *(ushort *)PTR_DAT_100cde74 = type;   // current room (GetGlobal 0x12)
case 10: if (pbVar15[6] != 0) pbVar15[6]--;  }
```
and `SetStage @ 10065034` for frame 3: `if (0xff < idx && frame == 3) (*viewer->vtbl[+8])(viewer,
x−vx, y−vy, type, (char)byte6)`; vtable 0x100D606C/+8 = `AddSound__7TViewerFssss` (traceback name;
body not decompiled).

| frame | count (0x81xx) | meaning | conf |
|---|---|---|---|
| 0 | 312 | spawn egg → `HatchEgg` | HIGH |
| 1 | 30 | teleport area: type = teleport index (0xF00C), arrival transition 0xF00F[type] | HIGH |
| 2 | 0 | one-shot step-on trigger at exact x,y → `SendSignal(type)`, then kind 0xC2 | HIGH |
| 3 | 330 | **ambient sound emitter**: `TViewer::AddSound(dx, dy, sound type, byte 6)` | HIGH call / MED args |
| 4 | 8 | zone change: `ChangeZone(type)` (types 0x100–0x102 in data) | HIGH |
| 5 | 0 | `PlayMusic(type)` | HIGH |
| 6 | 2 | one-shot area trigger → `SendSignal(type)` | HIGH |
| 7 | 3 | conditional group: `EvalCondition(byte6, byte7)` shows/hides the next `type` props | HIGH |
| 8 | 170 | room rectangle → current room global | HIGH |
| 9 | 0 | countdown trigger (DoTicks, data-format §4.3) | HIGH (existing) |
| 10 | 24 | byte-6 countdown, always staged | HIGH |

---------------------------------------------------------------------------------------------
## 6. World globals 0xF005/7/A/14/15, 0xF008/D/11/12, 0xF00F — mostly RESOLVED

**No reader for 0xF005, 0xF007, 0xF00A, 0xF014, 0xF015 [HIGH].** Scan of every `li/ori/addi`
immediate in the code section for 0xF000..0xF017: 0xF003/5/6/7/A/14/15/17 have **zero** uses; the
others resolve to `LoadGlobals`, `SaveGlobals`, `NewModel`, `RestoreModel`, `NewGame`,
`GetTileName` (F004), `TViewer` ctor (F00D). Content (this session):
- 0xF00A: 1024 bytes, all zero.
- 0xF014 = {u16 value, C string}… : `(259,'Od_Shutter1') (260,'Od_Shutter2') (1,'_FrameOwner')
  (5,'_WindHeight') (4,'_WindWidth') (2,'_WindX') (3,'_WindY') (257,'itsLights') (258,'itsMessage')
  (256,'itsState')` — a compiler symbol table of frame-variable names [HIGH decode; MED role].
- 0xF015, same shape: `(8,'Cad_Bellows1') (10,'Cad_Candle1') … (6,'Od_Bellows1') (3,'Od_Candle1')
  (1,'Od_Shutter1') (2,'Od_Shutter2')` — 13 named small ids, plausibly gremlin slots (class 0x78,
  0x400-byte gremlin table) [LOW].
- 0xF005 (16 B) `d008 01d8 0801 e004 01e4 0401 e804 0100`, 0xF007 (167 B) `0021 0000 0005 0001 1a00
  0500 0401 0005 …` — not decoded [STILL OPEN; editor/build data, LOW].

**0xF008 = monster-species table [HIGH].** `LoadGlobals @ 10005798`: whole segment into
`PTR_DAT_100cdbd8`; `ObjToMonst__Fs @ 10044a60` scans it as 16-byte records keyed by **object type
at +0xC**, at most 0x80, stopping at type 0:
```c
iVar2 = *(int *)PTR_DAT_100cdbd8;
while (true) { if (0x7f < sVar1) return 0;  if (*(short *)(iVar2 + 0xc) == 0) break;
  if (*(short *)(iVar2 + 0xc) == param_1) return iVar2;  iVar2 += 0x10; sVar1++; }
```
50 records in data. `TActiveMonster(short)` ctor uses `param_1[1] = ObjToMonst(type)`: bytes 0/1/2 →
Body/Reflex/Mind, byte 5 → Health, byte 6 → alignment (`*(char*)(ce+0x19) = *(param_1[1]+6)`), all
scaled by the difficulty roll (item 7). Script class **0x48** objects are these records (item 12);
`GetField` class 0x48 fields 0x2C→b0, 0x2D→b1, 0x2E→b2, 0x2F→b5, 0x30→b3, 0x31→b4, 0x32→u16@+0xA,
0x33→u16@+8, 0x35→b6, 0x36→s16@+0xE. Bytes 3/4/7, u16@8/A, s16@E meanings: STILL OPEN (combat
reader owns them). The tail `(size−0x800)>>4` records (`PTR_DAT_100cdc30/38`) = 0 in 1.0.4; no
reader of `cdc30/cdc38` besides the writer.
```
$ xxd -s 0x5079bc -l 0x20 "$G/Cythera Data"     # 0xF008 records 0, 1
005079bc: 0c0c 0c00 0314 0200 0000 0004 0020 111b
005079cc: 0f0c 0802 0414 0100 0001 4004 002f 044e
```
**0xF00D = wall-face substitution records [HIGH].** `__ct__7TViewerFs @ 10062684`: for each
10-byte record `{u16 tile, u16 alt[4]}` (assert tile ≤ 0x2000), `viewer->tbl[tile] = &alt[0]`.
`Render` (vis state `(*pbVar19 & 3) == 2`) replaces the tile by `alt[0]` if the north neighbour is
visible (`pbVar19[-stride] & 3 == 0`), else `alt[1]` east (`pbVar19[1]`), `alt[2]` south, `alt[3]`
west, iterating to a fixpoint (< 0x2000; ≥ 0x2000 → tile 0xFF). 500 B = 50 records [HIGH code; MED
for "wall seen from the lit side"].

**0xF011 / 0xF012 = per (type, frame) sprite x / y pixel offsets [HIGH].** Only reader `Render`
(above): `PTR_DAT_100cdc08[type*0x20 + frame]` (0x400×0x20 = 0x8000 ✓), the two tables swapped when
the prop's mirror bit (byte 4 bit 7) is set; added to the +0xE elevation.

**0xF00F = arrival screen-transition per teleport index [HIGH].** Readers: `TeleportTo @ 10050e98`
(`if (param_2 == -1) param_2 = (char)PTR_DAT_100cdbfc[param_3];` → viewer `+0x20c28`) and 'B'
frame 1. `DrawRoutine` consumes `+0x20c28`: `-1→1, 0xd→3, 0xe→4, >8 → −4`, then `switch`: 1 = blend
in 20 steps (`OpColor ×6/5`, CopyBits mode 0x20, 5 ticks/step), 2 = blend 15 steps (×8/5), 3 = grow
from centre (`InsetRect −6`), 4 = shrink-in (`InsetRect 0x10`), 5–8 = wipes (`OffsetRect` −0x20,0 /
+0x20,0 / 0,−0x20 / 0,+0x20); then reset to 0. `SetViewerLocation` sets 1 (every level load fades).
Data: of 190 used teleports, 147 → 0, 30 → 14 (shrink), 6 → 2, 3 → 13, 2 → 1, 1 → 3, 1 → 4.

---------------------------------------------------------------------------------------------
## 7. CharEntry +0x12, +0x17, +0x18, +0x1D, +0x1F — RESOLVED

`GetField__Fsss` class 0x40 maps script fields to CharEntry bytes (quoted cases): `0x23 → +0x12`,
`0x27 → +0x17`, `0x20 → +0x1d`; there is **no** field for +0x18, +0x19, +0x1A, +0x1F.

| off | meaning | evidence | conf |
|---|---|---|---|
| +0x12 | **busy / time-debt ticks**: `DoTick` decrements it one per tick (leader: `DoTicks(viewer,1,0)` each); scripts add action costs | `DoTick @ 1004ded8`: `*(char *)(*param_1 + 0x12) = … + -1; if (leader) _DoTicks__11TGameViewerFlUc(…,1,0);`; scripts: `301c` (selector 28 attack) `setfield A30.f23:busy = (A30.f23:busy + 12)` / `+ L04`; `0ea1` `+ ((busy+5)+A31)`; `0c42` `+ A31`; `1802` `= 100`. Smooth movement divides it by 2 or 4 (`HandleMove`: `*(char *)(*param_1 + 0x12) = … / uVar8`) | HIGH |
| +0x17 | **merchant price factor, tenths** (10 = list price). Sell routine `0EA5`: `jf (A32 < 9) -> 0010; set A32 = 20` … `L0E = (((L07[4] * A32) + 9) / 10)`, haggling `A32 = (A32 - 1)`, `return A32`; buy routine `0EA9`: `jf (A32 == 0)…; set A32 = 10`, price `((… * 10) + 5) / A32`. Every caller is `setfield A30.f27:ce17 = R0EA5/R0EA9(…, A30.f27:ce17, …)` (22 merchants) | HIGH (agrees with trade-economy.md §3.1) |
| +0x18 | **smooth-move sub-step state**: bits 2–7 direction index, bits 0–1 sub-step | `HandleMove @ 100488e4` (pref `DAT_100d3e20 < 0`): `*(char *)(*param_1 + 0x18) = (char)param_6;` prop moved by `DAT_100d5576/5564[param_6>>2]`; `HandleSubMove @ 10048fb0`: `if ((ce[0x18] & 3) < bVar4) { ce[0x18] += cVar5; prop[6] = DAT_100d5540[ce[0x18]]; } else { … ce[0x18] = 0; prop[6] = 0; }`; `DoTick` takes the "still sliding" branch while non-zero; ctor zeroes it. Prop byte 6 then carries the sub-cell offset nibbles (`SetStage` `byte6 & 3`, `>>4 & 3`) | HIGH |
| +0x1D | **character class / profession**: bits 0–1 = health-growth code, bits 2–3 = magic-growth code; also an index into data table `seg0501[0110]` | `0E95`: `switch (A30.f20:ce1D & 3) → 0, level/2, level, level*2`; `0E96`: same on `(ce1D >> 2) & 3`; callers `0E82`/`0E84` (health max) and `0E83`/`0E85`/`0EB5` (magic max); `1801` char creation: `L00 = seg0501[0110][A32]` → Body/Reflex/Mind, `setfield A30.f20:ce1D = A32`; `1802`: `L05 = seg0501[0110][G05:leader.f20:ce1D]` then grants `create_prop(28, …)` skills and zeroes it | HIGH usage / MED the word "profession" |
| +0x1F | **difficulty stat roll (%) of a spawned monster** (entries 0x100–0x1FF only) | `__ct__14TActiveMonsterFs @ 10044b98`: `sVar6 = Random() % 0x28 + 10` (diff 0), `% 0x4b + 0x19` (1), `% 100 + 0x32` (2), `% 100 + 100` (3), `% 0x96 + 0x96` (4), else 100; `*(char *)(*param_1 + 0x1f) = (char)sVar6;` then Body/Reflex/Mind/Health/Level `= (base * sVar6 + 0x32) / 100` (min 1). Stored as a byte (rolls > 255 wrap). No reader found | HIGH write / HIGH "no reader" in decompile grep |

Difficulty `DAT_100d73f2` is item 8's third `hhhh` value.

---------------------------------------------------------------------------------------------
## 8. Save stream — RESOLVED (HIGH)

**The four `hhhh` values** (`SaveToFile @ 10012f6c`: `FUN_100c50e8(local_64,PTR_DAT_100ce360,
(int)_DAT_100d73f0,(int)*(short *)PTR_DAT_100cdcf4,(int)_DAT_100d73f2,(int)_DAT_100d73f4)`):

| # | variable | initial (data section) | meaning | evidence |
|---|---|---|---|---|
| 1 | `DAT_100d73f0` | 0x0037 = 55 | **karma** = script global 0x0C, clamped 0..100 | `SetGlobal @ 10093a5c`: `_DAT_100d73f0 = …; if (<0) 0; if (100 <) 100`; `GetGlobal` case 0xc; `1801` sets 55; `ShowPortrait @ 1003dba4` colours the player's name by it (`<0 → 0x21; <0x60 → -(0x1f - v/6); else 0x1e`) | HIGH (name MED, = dialogue.md) |
| 2 | `PTR_DAT_100cdcf4` (short) | 0 | script global 0x0E (scripts use only bit 0: `G0E | 1`, `(G0E & 1) == 0` ×4) | `GetGlobal` case 0xe, `SetGlobal` `param_1 < 0xf` | HIGH store / meaning OPEN |
| 3 | `DAT_100d73f2` | 0x0002 | **difficulty 0–4** — read only by the monster ctor (item 7 +0x1F); **never written** except by the restore stream | disasm scan of all r2-relative access: only `addi r21,r2,8562` in the ctor + save/restore | HIGH ⇒ effectively constant 2 (rolls 50–149 %) |
| 4 | `DAT_100d73f4` | 0x0800 = 2048 | **serial counter** returned-and-incremented by builtin 0xF9 | `Builtin_F9 @ 1009ad40`: `uVar1 = _DAT_100d73f4; _DAT_100d73f4 = _DAT_100d73f4 + 1; *param_1 = uVar1 & 0xfffffff;` | HIGH |
```
initial values: toc.D[0x100d73f0 − 0x100cd280 :+8] = 0037 0002 0800 0000   (tools/toc.py D, this session)
```
**Stream encoding** — `TStream` bodies recovered by disassembly (traceback names
`.ReadData__7TStreamFPce` 0x10017CE0, `.WriteData__7TStreamFPce` 0x10018060, `.BeginChunk__7TStreamFUl`
0x100181C4, `.EndChunk__7TStreamFv` 0x1001828C, `.ReadChunk`, `.IsEOChunk`):
- `WriteData(fmt, …)` walks the format, each code calling `Write(ptr,len)` (vtable +0x18) on a
  big-endian stack temp: **`b`** 1 byte (`stb r0,70(r1)… addi r5,r0,1`), **`h`** 2 (`extsh; sth;
  li r5,2`), **`l`** and **`i`** 4, **`s`** C string incl. NUL (`strlen+1`), **`P`** Pascal string
  (`lbz r5,0(r26); addi r5,r5,1`), **`a`** = (len, ptr) raw bytes, **`H`** = Handle: NULL → u32
  0xFFFFFFFF, else u32 size + contents; **`' '`** = `Align(2)`, **`;`** = `Align(4)` (vtable +0x24
  with 2/4). Dispatch: `cmpwi r0,97 ('a') … 72 ('H') … 59 (';') … 32 (' ') … 80 ('P') … 108 ('l')
  … 104 ('h') … 99 → <0x63 = 'b' … 106 → <0x6a = 'i' … 115 ('s')` @ 0x10017D50–0x10017DC0.
- `BeginChunk(tag)`: write u32 tag; remember `pos` (vtable +8) in `this+4`; write u32 0.
  `EndChunk()`: `len = GetPos − this[+4]`; seek back, write `len`, seek forward
  (`subf r0,r0,r30; stw r0,56(r1); … lwz r12,12(r12)`). So a chunk = **tag(4) + u32 length counted
  from the length field itself (includes its 4 bytes) + body**; one remembered position ⇒ chunks do
  not nest.

Segment 0x0400 is therefore: `'Char'` chunk {hhhh; 32×b vars; 8×l flags; l clock; h day; b viewer
+0xD (= auto-map flag, item 19); l play-seconds; 27×b 0} — then four more chunks:
| chunk | writer | body | conf |
|---|---|---|---|
| `'Mons'` | `SaveMonsters @ 1004e878` | per active monster: `b` = script property 0x37 of its type (the loader picks the class: 9–10 `TCrawlMonster` 0x9C B, 11 `TDragonMonster` 0x68, 12 `TOctoMonster` 0x78, else `TActiveMonster` 0x58), then `TActiveMonster::Save @ 100459a8`: `hhh` {prop index, +0xA, +0xC}; if prop ≥ 0x100: `ha` {prop index, 0x20 bytes of its CharEntry}; `bhhhh` {+0x4C byte, +0x4E, +0x50, +0x52, +0x54}; `h` {word +0x2C}; then per node of the list at +0x30: `bhhl` {+8 byte, +0xA, +0xC, +0x10}. Formats resolved with `tools/toc.py 100ce90c 100ce908 100ce904 100ce900 100ce8fc` → `hhh`, `ha`, `bhhhh`, `h`, `bhhl`. Subclass extras and the list terminator are in the subclass stream ctors (not read) | HIGH layout / MED field names |
| `'FXQ '` | `WriteFXQueue @ 100561b0` | per entry of the `map<TSpellFX,u16>`: `hhh` {key +0xC, key +0xE, value +0x10} (`tools/toc.py 100cea24` → `hhh`) | HIGH |
| `'Wind'` | `MarshalAll @ 10030bd4` | per open inventory window (oldest first): virtual Marshal; reader `UnMarshalAll` reads `l` class id → `TRegistry::GetRegister(id)` → stream ctor; `TInventoryWindow::Marshal` adds `h` owner index (+0x10) | HIGH shape / base-class fields not read |
| `'Grem'` | `SaveGremlins @ 100ad124` | raw `Write(PTR_DAT_100cf008, 0x400)` = 256 × {u16 flags (field 0x14), u16 heap frame (`AllocateFrame`)} | HIGH |

---------------------------------------------------------------------------------------------
## 9. Music 0x9000+ and sound 0x9100+ — RESOLVED (HIGH)

**Sound `'asnd'`** — the format is defined by its own converter `FUN_100b7fac` (builds one from a
`'snd '` resource for the interface sounds):
```c
*puVar10 = 0x61736e64;               // 'asnd'
puVar10[1] = iVar4;                  // blocks = ceil(nSamples / 1024), min 1
puVar10[2] = *(undefined4 *)(iVar3 + iVar6 + 8);   // Fixed sample rate from the snd header
… *psVar9 = bVar2 - 0x80;            // each unsigned 8-bit sample → signed i16
NewPtrClear(blocks * 0x800 + 0x40c)  // 12-byte header + blocks*1024 + 512 zero samples
```
| off | type | meaning |
|---|---|---|
| 0 | 4CC | `'asnd'` |
| 4 | u32 | number of 1024-sample blocks |
| 8 | Fixed 16.16 | sample rate |
| 0xC | i16 BE × (blocks·1024 + 512) | mono samples, 8-bit precision (−128..127), zero-padded tail; true length not stored |
```
$ xxd -s 0x2fb001 -l 0x10 "$G/Cythera Data"      # segment 0x9101
002fb001: 6173 6e64 0000 0008 5622 0000 0000 0000  asnd....V"......
```
Checks this session: all 46 sound segments satisfy `len == blocks*0x800 + 0x40c`; rates: 0x56220000
(22050 Hz) ×40, 0x2B110000 (11025) ×2, 0x56EE8B9F (22254.55) ×2, 0x2B7745D0 (11127.27) ×2; 0x9101 samples span −128..127, 0x9102 −47..61. To decode one: read
`(len−12)/2` big-endian i16 at the rate `u32@8 / 65536`, trim trailing zeros. Playback
(`PlaySound @ 1001be98` → mixer `FUN_100b7a58`): up to 16 voices kept in priority order (`param_1+5` vs voice `+0x30`) [MED], step =
`FixDiv(rate>>8, outputRate>>8)` × pitch, **pitch randomised per play** to
`(Random() & 0x3fff) + 0xe000` = 0.875–1.125, stereo from `CalcStereo(dx,dy)` [HIGH].

**Music** = a QuickTime **MusicDescription** followed by a QTMA tune.
```
$ xxd -s 0x2cd1b1 -l 0x20 "$G/Cythera Data"      # segment 0x9000
002cd1b1: 0000 039c 6d75 7369 0000 0000 0000 0001  ....musi........
002cd1c1: 0000 0001 f000 0003 0000 0001 c008 0003  ................
```
`GMSTune::Play @ 1001a3c0`: `TuneSetHeader(tp, *param_1 + 0x14); TunePreroll(tp); TuneQueue(tp,
*param_1 + *(int *)*param_1, 0x10000, 0, 0xffffffff, 1, 0, 0)` — i.e. u32@0 = description size
(0x39C) = offset of the tune event stream; +4 `'musi'`, +8 reserved, +0xE dataRefIndex 1, +0x10
flags, **+0x14 = QTMA header events** (note-request general events `F000 0003 …`, synth type
`'ss  '` "Best Synthesizer" visible at +0x44); events from +0x39C to the end, played at rate 1.0
from position 0 to end. Native playback needs a QTMA event interpreter + a General-MIDI synth; the
events themselves are not decoded here [HIGH layout; MED for the QuickTime field names].

---------------------------------------------------------------------------------------------
## 10. Resource types PORT/LINF/MSta/eBRS/eSTM/RMAP; `Lite` 128–133 — RESOLVED

**No PPC reader [HIGH].** 4CCs are built with `lis/ori` (`addis rD,0,hi; ori rD,rD,lo`). A scan of
the whole code section for every `addis` whose following `ori/addi` completes the 4CC finds `FILT`
(`LoadDisplacementFilters`) and `Lite` (×3) and **none** of the six (control: the scan finds the
known readers). The bytes are absent from the data section too. Content (`rsrc.py`-based dump this
session) shows editor/build-tool resources:
- `eBRS` (25×32 B, named "Water 1", "Mountains 1", …) = editor tile **brushes**; `eSTM` (16, "Stamp 1",
  first words `0008 0008` = 8×8 then tile ids) = editor **stamps** [MED].
- `MSta` (3×64 B, named "Base", "Plague Cured", "Olpheltius Murdered") = editor **start states**:
  64 B = the 32 byte-vars + 8 flag longs of the `'Char'` chunk (item 8) [MED].
- `LINF` 257–259 (12 B: `0100 0100 ffff …`, `0040 0040 ffff …`) = per-level info, first two words =
  W,H of levels 1–3 (256², 64², 64²) [MED].
- `RMAP` 128 (`'TxSt' 0000 0001 03e7 'TxCl' 0000`) = a ResEdit type→template map (TMPL 129 is `TxCl`)
  [MED]. `PORT` 0/1 (413/2351 B) — not decoded [LOW, STILL OPEN as content].

**`Lite` 128–133 = tile light sources [HIGH].** `CalcLighting__7TViewerFss @ 100641f8`, per cell with
vis state 1 whose tile flags have bits 0–1 set:
```c
iVar13 = (*puVar8 & 3) * 2;                    // tile flag bits 0-1: light size class 1..3
if ((*puVar8 & 0x10000) != 0) iVar13 += Random() & 1;   // flag 0x10000: flicker
piVar4 = GetResource('Lite', iVar13 + 0x7e);   // 128,130,132 (+1 when flickering)
CopyLight(*piVar4 + 1, size, …)
```
Sizes (byte 0): 128→10, 129→12, 130→14, 131→16, 132→18, 133→22 — so flicker alternates with the
next-larger mask. `Lite` 140–158 = party light (existing). New fact for 0xF002: **tile-flag bits 0–1
= light-emitter size, 0x10000 = flicker**.

---------------------------------------------------------------------------------------------
## 12. Class ids 0x28 and 0x48 — 0x48 RESOLVED (HIGH); 0x28 RESOLVED as "no use" (HIGH)

- **0x48 = monster species** (records of 0xF008, item 6). `Ctor__Fsss @ 10091dd4` casts a character
  (class 0x40, via its home type `+0x14 & 0x3ff`) or a prop (class 0, its type) to
  `(ObjToMonst(type) − table) / 16 | 0x40480000`; `GetField` class 0x48 reads the record. Script
  segments 0x1900+i: 0x1901, 0x1910–0x1931 — indices < 50 = the species count [HIGH].
- **0x28: no producer.** `grep 0x4028` = 0 in both dumps; `Ctor__Fsss` handles source classes
  0/0x20/0x40/0x48/0x50 only; `scriptdis` found no `cls28` literal. The three segments 0x1500–0x1502
  (`sel20/enter`: `set_outdoor_sky`, `set_map_title("Underground City" / "Crypts" / "Cave")`,
  `set_zone_light_minimum`, `play_music2`) have the **zone** script shape and are reached as class
  0x20 with zone ids 0x100–0x102: `ObjIDToSegmentID @ 100917a0` returns `param_1 * 0x20 + param_2 +
  0x1000` = 0x1400 + 0x100 = 0x1500, and the 'B' frame-4 zone props carry types 0x100/0x101/0x102
  (prop records `4205 805b 1100 …`, `4203 3025 1101 …`, `4201 500d 1102 …` from the 0x81xx census). ⇒ class 0x28 is unused in 1.0.4;
  its segment range is shared with high zone ids [HIGH]. Fix for script-vm.md §2.1: the 0x28 row's
  "0x15 (3 segs)" belongs to class 0x20.

---------------------------------------------------------------------------------------------
## 16. `MoveAll` pacing; `Render`; sky — pacing RESOLVED (HIGH), Render PARTIAL, sky RESOLVED (HIGH/MED)

**Pacing.** `MoveAll__14TActiveMonsterFv @ 1004e334` has **no wall-clock wait**. Its frame-budget
code only clamps a static:
```c
if (DAT_100d3e20 < '\0') local_4c = 0x10; else local_4c = 0x20;
iVar10 = TickCount();
if (local_4c < (uint)(iVar10 - *(int *)PTR_DAT_100ce898)) *(uint *)PTR_DAT_100ce898 = TickCount() - local_4c;
```
and a disassembly scan of every r2-relative access to `PTR_DAT_100ce898/89c/8a0/8a4` (statics at
0x10132A5C..62) finds **only MoveAll** — the value is never consumed (vestigial) [HIGH]. The loop
then calls `DoTick` on monsters until one returns 3/4 (leader ready for input / level changed); the
only TickCount use left is `if (iVar10 + 0x3cU < TickCount()) cdc40[leader] = 1;` which, on exit,
`FlushEvents(0x2a,0)` + `FlushKeyDown` (drops typed-ahead keys after a ≥ 1 s turn). `DoTick @
1004ded8`: busy ≠ 0 → `busy−1` (+1 clock unit for the leader); busy = 0 and leader → `return 3`
unless the leader is Afraid/Paralysed/Confused/Charmed (status 0x20/0x40/0x2000/0x4000), in which
case it `YieldToAnyThread()`s and plays on. ⇒ **World time is turn-driven**: each leader action's
cost (busy ticks) is simulated synchronously; wall-clock appears only through thread yields
(`TTaskMaster`) and animation: smooth movement (`DAT_100d3e20` bit 7) slides creatures in 2 or 4
sub-steps (bit 1) via `HandleSubMove`, and transitions run at 5 ticks/step (item 6). MoveAll is
called from `HeartBeat`, `KeyRoutine`, `MouseRoutine`, `XDirection` (player commands) and
`BeginPlay` [HIGH].

**Render — PARTIAL.** New this pass: prop elevation +0xE, 0xF011/0xF012 sprite offsets, 0xF00D wall
substitution, auto-map marking (`if (local_fc != 0) *local_28c |= 0x8000;` with `local_fc =
viewer[+0xD]`, item 19), `Lite` emitters. Still open: the full layer/priority order and
`TMaskTile` usage.

**Sky bodies** — `CalcLocations__Fss(day, quarter) @ 1006be68`, data `count [2] rate [4, 20]
off [48, 36] nph [8, 1]` (read with `tools/toc.py` `D` this session). Per body i:
`t = day·96 + q; pos = (off[i] + t·rate[i]/96 + 0x900) mod 96; phase = (nph − ((pos·nph + 48)/96 mod
nph)) mod nph; x = (q + pos) mod 96`. So `rate` = quarter-hours the body lags the sun per day (body 0:
1 h/day → a 24-day cycle; body 1: 5 h/day → 4.8 days), `off` = initial lag, `nph` = phase-frame count
(body 0 waxes/wanes through 8 frames by its angular distance from the sun; body 1 has none) [HIGH
arithmetic; MED "two moons" — the sun itself is just `q`].

---------------------------------------------------------------------------------------------
## 18. Who sets the all-ally override `PTR_DAT_100cde4c` — RESOLVED (HIGH)

Reader: `GetEnemyStatus__14TActiveMonsterFP14TActiveMonster @ 100487d8`: `if (*PTR_DAT_100cde4c != '\0') return 1;` (everyone
friendly). Writer (r2-relative scan, only hit): `0x10043FD8`, inside the body of
`.KeyRoutine__10TMapWindowFs` (traceback name at 0x100446D8; Ghidra mis-attributes it to
`ShowTileAnimate`):
```
10043c58: cmpwi r0,250        ; key char 0xFA
10043c5c: beq  0x10043fcc
10043fcc: lbz r0,0(r28)       ; r28 = TOC 0x100cde50 → cheat-mode flag
10043fd4: beq  → skip
10043fd8: lwz r4,-29748(r2)   ; 0x100cde4c
10043fe0: lbz r0,0(r4); cntlzw r0,r0; rlwinm r0,r0,27,5,31; stb r0,0(r3)   ; flag = !flag
```
Cheat mode itself (same function, 0x10043814–0x10043884): a 4-key rolling buffer
`buf = buf<<8 | key`; `addis r0,r4,0x5699; cmplwi r0,0x7261` ⇒ `buf == 0xA9677261` (keys 0xA9,
'g', 'r', 'a' — 0xA9 = '©', Option-G on a US layout), gated by bit 0 of `0x100d3e23` (prefs byte
block at `DAT_100d3e20`); toggles `*r28` and prints "Cheat mode activated." / "Cheat mode
deactivated." (`tools/toc.py 100ce85c 100ce858`). So the override is a **cheat toggle: key 0xFA
(Option-H, '˙') in the map window while cheat mode is on** [HIGH code; MED for the keyboard
glyphs]. Who sets the `0x100d3e23` bit: not traced.

---------------------------------------------------------------------------------------------
## 19. `script-builtins.md` §4 — RESOLVED except F8 (out of scope)

Vtable slots resolved as described in the method notes (vtables: app 0x100D4358, status window
0x100D4B08, conversation 0x100D5298, scripted window 0x100D69E8, fade-in text 0x100D786C).

| builtin | call site (disasm) | receiver | slot → method | conf |
|---|---|---|---|---|
| A2 end game | 0x10094154 / 0x1009416C | app (TOC 0x100CDB84) | +124 `DoQuit__10TDelverAppFv`, +100 `ShowMenuBar__10TDelverAppFv` (then `FUN_10075360(50)`, `ExitToShell`) | HIGH |
| A6 n < 2 | 0x10094448 | status window (0x100CDB98) | +64 `IdleRoutine__7TWindowFv` | HIGH |
| B5 ask digit | 0x100956E4 / 0x10095704 | conversation (0x100CDCC8) | +280 `mygetch__13TConversationFPc("0123456789")`, +260 `ForceOut__13TConversationFv` | HIGH |
| DB | 0x10098F48 | found scripted window | +104 `Select__7TWindowFv` (bring to front) | HIGH |
| E7 case 2 | 0x10099C54 / 0x10099C7C | app | +68 `MyGetEvent__10TDelverAppFsP11EventRecordUc(8, &ev, 1)` — waits on keyDown mask 8 | HIGH |
| EA | 0x1009A0C4 | conversation | +112 `Hide__12TInteractionFv` (+ `PlayIFSound(2)`) — hide conversation | HIGH |
| EB | 0x1009A028 | conversation | +108 `Show__13TConversationFv` (+ `PlayIFSound(1)`) — show conversation | HIGH |
| ED close curtain | 0x1009A3A4 | app | +64 `RedrawAllNow__4TAppFv` | HIGH |
| EE | 0x1009A948 / 0x1009A970 | local `TStringFadeInTextImageObject` | +8 `Tick__22TFadeInTextImageObjectFv`, +12 `Apply__22TFadeInTextImageObjectFR9TWorkArea` | HIGH |
| F8 | — | CD player | out of scope (INDEX "Out of scope") | — |

- **D0's "monster word 0"** = the `TActiveMonster`'s `CharEntry*` (ctor: `*param_1 = (int)(puVar2 +
  param_2 * 0x20)`; `GetField` 0x22 reads `**(int **)(iVar3 + 0x1c) - table` the same way). D0
  (`Builtin_D0`, lines `puVar4[1] = *puVar5; … (*puVar5 != puVar4[1])`) therefore iterates the props
  whose monster shares *who*'s CharEntry — the body segments of one multi-prop creature
  (`TCrawlMonster`/`TOctoMonster`/`TDragonMonster`) [HIGH code; MED "body segments"].
- **FC's viewer +0xD = auto-mapping on.** Only reader: `Render` (`lbz r14,13(r31)` @ 0x100672DC, r31 =
  `this` from `or r31,r3,r3` @ 0x10066ACC) → `if (local_fc != 0) *local_28c |= 0x8000` on every drawn
  map cell (the "seen" bit saved as 0x8200+L). Scripts: object 0x117A (type 378) `sel16`
  `set_viewer_flag_d(True)` / `sel17` `set_viewer_flag_d(False)` (pick up / drop), and 0x1CC3 gives
  item 378 "this magical mapping device" then sets it True. Saved in the `'Char'` chunk [HIGH].
- **E2's `TBres` callback** = `TLineEffect` (vtable 0x100D76BC, +8 =
  `DoBresPixel__11TLineEffectFl` @ 0x1009930C): for each line point within ±15 cells of the view,
  `GetBestProp(x,y)` (bl 0x1006B188) → `GetCharacter(prop)` (bl 0x1004D704) → `stbx 1` into
  `cee00[(CharEntry* − table) >> 5]` — the set of characters on the missile path, which E2 clears
  first [HIGH].
- **Iterator loop shape** (listing `0ea5` 0x001A–0x006E): `L02 = iterate_list(&L03, 0, coll)` (init
  → first) ; `jt iterate_list(&L03, 1) -> exit` (done?) ; body ; `L02 = iterate_list(&L03, 2)`
  (next) ; `goto` test. Same for `iterate_range` (`1802` 0x0746–0x078D) [HIGH].

---------------------------------------------------------------------------------------------
## Summary

| item | status | label |
|---|---|---|
| 1 header fields / CompatibleVersions field | RESOLVED (+0x40 engine fmt, +0x42 scenario ver, +0x48 max map dim, +0x20 player name) | HIGH (+0x20 copy fn MED) |
| 4 map +0x04, +0x14..0x1F; C*0x40 | RESOLVED (unused; C*0x40 literal latent defect) | HIGH |
| 5 prop +0xA..0xF; kinds 0x11/0x80; 'B' frames | PARTIAL: +0xA free slot, +0xE elevation, 0x80 hidden, all 'B' frames 0–10 resolved; **kind 0x11 open** | HIGH (0x11 open) |
| 6 globals | PARTIAL: F008 species, F00D wall substitution, F011/F012 offsets, F00F transitions, F014/F015 symbol tables, F00A zero; **F005/F007 content open** | HIGH / LOW |
| 7 CharEntry +0x12/17/18/1D/1F | RESOLVED | HIGH (+0x1D name MED) |
| 8 save stream | RESOLVED (hhhh = karma, G0E, difficulty, serial; chunk + format encodings; Mons/FXQ/Wind/Grem) | HIGH (subclass extras MED) |
| 9 music / sound formats | RESOLVED (asnd fully; music = QT MusicDescription + QTMA tune, events not decoded) | HIGH |
| 10 resource types; Lite 128–133 | RESOLVED (editor-only, no reader; Lite = tile light emitters); PORT content open | HIGH / MED |
| 12 class 0x28, 0x48 | RESOLVED (0x48 species; 0x28 unused, 0x15xx = zones 0x100+) | HIGH |
| 16 pacing; Render; sky | PARTIAL: pacing and sky resolved; Render layer order open | HIGH / MED |
| 18 all-ally override writer | RESOLVED (cheat toggle key 0xFA under cheat mode) | HIGH |
| 19 builtin §4 | RESOLVED (F8 out of scope) | HIGH |

Counts: **resolved 9** (1, 4, 7, 8, 9, 10, 12, 18, 19), **partially 3** (5, 6, 16), **still open 0**
whole items (open sub-points: kind 0x11, 0xF005/0xF007 content, `PORT` content, `Render` layer
order, 0xF008 bytes 3/4/7/8–0xF, global 0x0E meaning, writer of pref bit `0x100d3e23`).
