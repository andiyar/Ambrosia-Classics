# Cythera 1.0.4 — UI toolkit (custom CDEF/WDEF/LDEF/MDEF, windows, dialogs, list box, adapters)

⚑ wave 2 (2026-10-06) — new file (reader R4, census groups **H** + **B** of `missing-census.md`).
Register: code reading only. Identify-level map: what each toolkit class is, which definition-proc
resource it serves, what it draws (art ids), and the player-visible keyboard behaviour. No game rule
lives here (see §5). `m:NNNN` = line of `ghidra/Cythera_missing.decompiled.c`; `p:NNNN` = line of
`ghidra/Cythera_pef.decompiled.c` (main dump, cited for context only — not part of the 316).

## 0. Provenance and coverage

Row list = the census classifier (`missing-census.md` §0 script) filtered to groups H and B:
```sh
# classify.py = the census §0 script with `print(k,a,int(n,16),s)` per row instead of the totals
python3 classify.py bi.txt | grep -E '^(TAppearanceAdapter|T7Adapter|TApWidget|T7[A-Za-z]*|TApWindow|TAppearanceMenu|TWindow|TDialog|TListBox|T[A-Za-z]*CDEF|T[A-Za-z]*WDEF|TCDEF|TWDEF|TDrawerWindow|TCMNU|TSave(Font|Port|GWorld)|THandleLocker|STD|FREE:(MyDrawDialogItem|DelverDialogerRoutine|MoveableDialogerRoutine|ExactMatchRoutine|MyLDEF|myListSearch|MyCDEF|MyWDEF|MyMenuDef|MyMenuHook)) ' > mine.txt
wc -l < mine.txt                    # 316  (275 H + 41 B)
awk '{b+=$3} END{print b}' mine.txt # 43140 bytes  (H 38,576 + B 4,564 — agrees with the census)
```
Every one of the 316 bodies was opened (whole body for the large ones named in §1; the 4–8-byte
stubs and the 100-byte `__dt__` boilerplate were read as a class). Covered: **316/316**.

| class (rows) | bytes | address range | class (rows) | bytes | address range |
|---|---|---|---|---|---|
| TAppearanceAdapter 25 | 2,092 | 10000308–10001250 | T7Adapter 25 | 2,400 | 10002b44–10003ca4 |
| TApWidget 12 | 892 | 10000114–10004af8 | T7Widget 16 | 892 | 100012c0–10004388 |
| T7ControlWidget 10 | 776 | 10001b10–10004564 | T7SliderWidget 8 | 652 | 100026fc–10002aa4 |
| T7LabelWidget 3 | 516 | 10002420–100043b8 | T7GroupBox 2 / T7IconWidget 2 | 344 / 240 | 10002034–10004490 / 100021e8–100022cc |
| TApWindow 6 | 644 | 10003f4c–10004284 | TAppearanceMenu 1 / TCMNU 1 | 80 / 48 | 1000f5ac / 1000f4b0 |
| TWindow 24 | 4,288 | 10009518–1000ba78 | TDialog 9 | 1,148 | 100095a4–1001068c |
| dialog procs 4 (Delver/Moveable Dialoger, ExactMatch, MyDrawDialogItem) | 1,180 | 10009344–1007378c | TListBox 18 + MyLDEF + myListSearch | 5,220 | 1002f094–1006e474 |
| MyCDEF 1 | 1,156 | 1006e738 | TCDEF 22 | 1,376 | 1006eca4–1006f5f8 |
| TScrollBarCDEF 8 | 2,532 | 100a7694–100a87e4 | TProgBarCDEF 4 | 764 | 100a72a0–100a88b8 |
| TEditNumberCDEF 6 | 764 | 100a6e88–100a898c | TNumberCDEF 4 | 372 | 100a6c50–100a8a60 |
| TPush/TCheck/TRadioButtonCDEF 4+4+4 | 440+472+472 | 100a64b8–100a8cec | MyWDEF 1 / TWDEF 9 | 612 / 400 | 1006f9ac / 1006fd00–1006ffd8 |
| TBorderWDEF 8 | 1,368 | 100a3f24–100a8e50 | TThinBorderWDEF 6 | 552 | 100a460c–100a8dc0 |
| TPixsWDEF 7 | 2,388 | 100a4978–100a54bc | TDrawerWDEF 7 / TDrawerWindow 6 | 1,556 / 1,256 | 100a56ec–100a8d34 / 100770f8–100a63f0 |
| MyMenuDef 1 / MyMenuHook 1 | 188 / 108 | 100a8360 / 100ac3ac | TSaveFont/Port/GWorld, THandleLocker 4 | 388 | 10028b98–10073c78 |
| **B** std templates 41 | 4,564 | 100014dc–100a8fc4 | **total 316** | **43,140** | |

Not in this set (and so not read here): `TCDEFRegister`/`TWDEFRegister`, `InitCustomDefs__Fv`, the
`TCDEF`/`TWDEF` ctors and the drawing helpers `FrameBox`, `DrawButton`, `DrawCheck`,
`DrawNumberField`, `ExpandHorizontally`, `SetTilePat` — all in the main dump, quoted below only where
they fix a resource id. `TBackdropWind` is census group D (reader R1).

**Art = tiles.** The controls/frames copy pixels from `*PTR_DAT_100cdc64 + k·0x400`. That pointer is
the 0x280000-byte buffer `CreateGlobals__Fs` allocates (`uVar6 = .glue::NewPtr(0x280000);`, p:380) —
0xA00 tiles × 0x400 = the tile-pixel store of data-format.md §3.4 (script-builtins.md A5: "base
`cdc64`"). So offset 0x6B400 = **tile 0x1AD** (`python3 -c "print(hex(0x6b400//0x400))"`); the helper
calls (`SetTilePat__Fs(0x1a4)`, `DrawCheck(…,0x1ab)`) take tile numbers directly. UI tiles used here:
0x19C–0x1AF (sheet 0x8E19 idx 12–15, sheet 0x8E1A idx 0–15). Each blit builds a 32×32 8-bit PixMap from
the 50-byte template at 0x100D3DE4 (`toc.data_u32(0x100d3de4,13)` → rowBytes `0x8020`, bounds
`(0,0,32,32)`, pixelSize 8, cmpCount 1). Colour table for all custom CDEF offscreens =
`*PTR_DAT_100cdc78` = `GetCTable(0x100)` (`CreateGlobals`, p:361; `clut 256` in Cythera.rsrc). [HIGH]

Resolving TOC → TVector → function (used for every "registers" cell below):
```sh
python3 - 100ce09c 100ce098 100ce094 100ce090 100ce08c 100ce088 100ce084 100ce080 100ce07c 100ce078 \
  100ce074 100cef70 100ceb84 100ceb8c 100ceb80 <<'EOF'
import sys,subprocess; sys.path.insert(0,'docs/cythera/tools'); import toc
for a in sys.argv[1:]:
    tv=0x100cd280+toc.tocval(int(a,16)); ca=0x10000000+toc.data_u32(tv,1)[0]
    print(a,subprocess.run(['python3','docs/cythera/tools/tb.py','--at','%x'%ca],capture_output=True,text=True).stdout.strip())
EOF
# 100ce09c→Create__15TPushButtonCDEF  098→TCheckButtonCDEF  094→TRadioButtonCDEF  090→TScrollBarCDEF
# 08c→TProgBarCDEF  088→TEditNumberCDEF  084→TNumberCDEF  080→TBorderWDEF  07c→TThinBorderWDEF
# 078→TPixsWDEF  074→TDrawerWDEF  100cef70→MyMenuDef  100ceb84→MyCDEF  100ceb8c→MyWDEF  100ceb80→MyLDEF
```
Vtables (`python3 - 100d62b4 28` with the same loop over `toc.data_u32(vt,n)`): TCDEF slot +0x0C Draw,
+0x10 DrawAPart, +0x14 Test, +0x1C CalcThumbRegion, +0x20 Pos, +0x24 Thumb, +0x2C Action, +0x60
GetPreferedCTable; TListBox (0x100D61AC) +0x28 Key, +0x30 Click, +0x40 LDEFDraw, +0x44 LDEFHilite,
+0x54 RevealCell. [HIGH]

## 1. Class map

Registration (main dump, `InitCustomDefs__Fv @ 100a8438`, p:51662–51735): each `TCDEFRegister(id)` /
`TWDEFRegister(id)` ctor writes `0x4ef9` (68k `JMP abs.l`) + a routine descriptor into the 6-byte stub
resource (`*(undefined2 *)*piVar3 = 0x4ef9;`, p:35198), then `Register(factory, mask, value)` adds a row
{id, mask, value, factory} (≤ 20 rows). At `initCntl`/`wNew`, `CreateController` picks the first row
whose resource handle equals the def-proc handle and `(varCode & mask) == value`; no match → a bare
`TCDEF` (CDEF) or no controller (WDEF). The stubs in `Cythera.rsrc` (`rsrc.parse`, see §1 note) are
`CDEF 1000/1001/1002` and `WDEF 1000–1003`, each `4ef900000000`; `MDEF 128` is 6 zero bytes,
`LDEF 128` a 128-byte 68k stub. [HIGH]

| class | role · resource | what it draws / does | evidence | label |
|---|---|---|---|---|
| `MyCDEF` @1006e738 | the CDEF entry for ids 1000–1002 (`NewRoutineDescriptor(…,0x3bb0,1)`) | msg 0x1B → returns `' ok '`; msg 3 (init) → `CreateController`, object stored in `contrlData` (+0x1C); every other message (0 draw only if `contrlVis`, 1 test, 2 calcRgns, 4 dispose, 5 pos, 6 thumb, 7 drag, 8 autoTrack, 10/11 calc regions, 13–23, 26) → the TCDEF virtual; handle locked around the call | `uVar4 = 0x206f6b20;` m:12037 | HIGH |
| `TCDEF` @1006eca4 (22) | base controller; `Draw` = double-buffered draw | `NewGWorld` depth 8 with `GetPreferedCTable()` (or screen depth when that returns 0), fill with the window's back pattern (`FillCRect` with `bkPixPat` on colour ports), `DrawAPart(ctrl, part, winCTab, ctlCTab, isColor)`, `CopyBits` back; 20 other methods are 4–8-byte stubs (`Test` = PtInRect of contrlRect, `CalcControlRegion` = RectRgn) | `sVar6 = .glue::NewGWorld(&iStack_80,8,&uStack_7c,puVar4,0,0);` m:12224 | HIGH |
| `TPushButtonCDEF` | **CDEF 1000, varCode&7 = 0** (`_Register__13TCDEFRegisterFPFPP13ControlRecords_P5TCDEFss(iVar4,PTR_PTR_100ce09c,7,0);` p:51680) | `DrawButton(rect, title, state)`: state 1 when hilite part 10 or 1, 2 when hilite 255 (inactive); `DrawButton` (p:36250) uses tile `0x1a8 + state`; title anti-aliased (`AADrawText`) | `.debug::_DrawButton__FR4RectPUc12eButtonState(&uStack_28,**(int **)(param_1 + 4) + 0x28,uVar1);` m:22234 | HIGH (tile in helper: MED) |
| `TCheckButtonCDEF` | **CDEF 1000, var 1** | `DrawCheck(rect, title, state, tile 0x1AB)`; state 3 = checked (`contrlValue != 0`) | `(&uStack_28,**(int **)(param_1 + 4) + 0x28,uVar1,0x1ab);` m:22284 | HIGH |
| `TRadioButtonCDEF` | **CDEF 1000, var 2** | same with tile 0x1AC | `(&uStack_28,**(int **)(param_1 + 4) + 0x28,uVar1,0x1ac);` m:22334 | HIGH |
| `TScrollBarCDEF` (8) | **CDEF 1001, var 0** | vertical only, 16 px wide. Tiles: 0x1AD normal sheet, 0x1AE pressed sheet. Up arrow = src (0,0,16,16), track top cap (16,0)–(32,16), body tiled from rows 8–24 every 16 px, bottom cap (16,16)–(32,32), down arrow (0,16)–(16,32); thumb = the top-cap cell of the pressed tile, drawn only if hilite≠255, min<max and track>16 px. Test parts: 20 up arrow, 22 page up, **129** thumb, 23 page down, 21 down arrow. Thumb y = top+16 + (h−48)·(val−min)/(max−min) (`CalcThumb`, p:51627). Pos/Thumb do live drag mapping | `iStack_60 = *(int *)PTR_DAT_100cdc64 + 0x6b800;` m:22810 | HIGH |
| `TProgBarCDEF` (4) | **CDEF 1001, var 1** | horizontal track `ExpandHorizontally(rect, tile 0x1A5, 0)`; when min<max a 32×16 knob (top half of tile 0x1A5) at x = left + (w−32)·(val−min)/(max−min), with the control's **refCon** printed centred on it (`NumToString(contrlRfCon)`, AA text) | `.debug::_ExpandHorizontally__FR4RectsUc(&uStack_22,0x1a5,0);` m:22535 | HIGH |
| `TEditNumberCDEF` (6) | **CDEF 1002, var 0** | `DrawNumberField(rect, value, hilite)` (frame = `DrawButton` state −9 → tile 0x19F; up/down arrows from tiles 0x1AD/0x1AE, pressed per part 20/21, p:36311); `Action`: part 20 → +1, part 21 → −1, kept within [min,max]; auto-repeat: first step at once, next after `LMGetDoubleTime()` ticks, then every 10 ticks; timer cleared when drawn un-hilited | `*(int *)puVar1 = iVar3 + 10;` m:22440 | HIGH |
| `TNumberCDEF` (4) | **CDEF 1002, var 1** | read-only `DrawNumberField(rect, value, -1)` | `.debug::_DrawNumberField__FR4Rectss(&uStack_14,(int)*(short *)(param_2 + 0x12),0xffffffff);` m:22372 | HIGH |
| `MyWDEF` @1006f9ac | WDEF entry for ids 1000–1003 | msg 3 → `CreateController` → object at WindowRecord+0x82 (`dataHandle`); msgs 0,1,5,6 run on the colour WMgr port (`SyncPorts`); 0 draw (if visible), 1 hit, 2 calcRgns (content rect from the port), 4 dispose, 5 grow, 6 draw size box, 7 features, 8 get region | `*(undefined4 *)(param_2 + 0x82) = uVar2;` m:12518 | HIGH |
| `TWDEF` (9) | base | `Draw`: part 4 toggles close-box hilite, 5/6 zoom; else `DrawHilited`/`DrawUnhilited` by `hilited` (+0x6F); `Grow` = `FrameRgn(strucRgn)`; rest stubs | `*(bool *)(param_1 + 8) = *(char *)(param_1 + 8) == '\0';` m:12587 | HIGH |
| `TBorderWDEF` (8) | **WDEF 1000** (all variants) | structure = content outset 16 px; `FrameBox(strucRect, style, title)` with style = 2·goAway + (var 4 → +4, var 1 → +1); `FrameBox` (p:35422) uses tiles 0x19C/0x19D/0x1A0/0x1A1/0x1A2/0x1A7. Close box 16×16 at the structure's top-left; **var 4 adds a 16×16 grow box at bottom-right**. Grow keeps the window **square**, side = 64·⌊(min(w,h)+32)/64⌋, outline drawn twice (rect and rect outset 16) | `.glue::InsetRect(&uStack_18,0xfffffff0,0xfffffff0);` m:21374 | HIGH (FrameBox art MED) |
| `TPixsWDEF` (7) | **WDEF 1001** | frame = a pix-cache picture: refCon hi word = pix id (`LoadPix`), refCon byte 1 = content x offset in the picture, byte 0 = y offset; var ≠ 0 → no picture (plain rect). Structure region = the picture's non-zero pixels (`MyPMToRegion`). With goAway: a 16-px close tab at y = top + h/4 − 4 on the left edge — close box from tile 0x1AF (pressed = source +16 rows), then 8-px slices to the horizontal midpoint (≥ left+32) and an end cap, clipped to the tab region | `iStack_58 = *(int *)PTR_DAT_100cdc64 + 0x6bc00;` m:21642 | HIGH (pix ids MED) |
| `TDrawerWDEF` (7) | **WDEF 1002** | 1-px frame + an 18-px title strip above the content filled with tile 0x19C (`ExpandHorizontally(…,0x19c,1)`), a title plate (text width + 16) of the same tile, title centred, AA text. Hit: content → 1, any other structure point → **3 (grow)**. Grow: height snaps to 64, then 64 + 16·k (rounded); bottom edge fixed, top kept below y = 36; XOR outline | `.debug::_ExpandHorizontally__FR4RectsUc(&uStack_2e,0x19c,1);` m:21864 | HIGH |
| `TDrawerWindow` (6) | the window class over WDEF 1002 | `HandleResizeWindow`: drag the strip → live gray outline (`PenMode 10`), bottom fixed; a click without a drag **toggles**: closed (height 0) → reopen to the remembered height, open → remember height and collapse to 0; open/closed change fires a virtual (flag +0xC). Always owned by the main device (`GetOwningGD` returns `*_DAT_100cdd40`) | `*(short *)(param_1 + 0xe) = *(short *)(*(int *)(param_1 + 4) + 0x14) - *(short *)(*(int *)(param_1 + 4) + 0x10);` m:22091–22092 | HIGH |
| `TThinBorderWDEF` (6) | **WDEF 1003** | structure = content outset 8 px horizontally, 4 px vertically; `FrameBox(rect, 8, nil)`; no boxes, hit = content or nothing | `.glue::InsetRect(&uStack_18,0xfffffff8,0xfffffffc);` m:21451 | HIGH |
| `MyLDEF` @1006d5a0, `TListBox` (18) | **LDEF 128**: `LNew(…, 0x80, …)`; MyLDEF's descriptor goes in ListRec refCon +0x3C, `this` in userHandle +0x44, selFlags = 0x80 (`lOnlyOne`) (ctor p:35014–35018) | msgs 1 draw / 2 hilite → `LDEFDraw`/`LDEFHilite` virtuals (base `LDEFDraw` p:35044: text cell, x+3, vertically centred, `InvertRect` when selected); 0 init / 3 close ignored. `Hide`/`Show` = move the list and its scroll bars by ±0x4000 h; `Click`: thumb (part 129) tracked live with `LScroll` per mouse move over (track − 48) px; `DrawIntoPort` redraws all visible cells into another port. Keys: §3 | `if (((param_1 != 0) && (param_1 != 3)) && (iVar1 = *(int *)(*param_7 + 0x44), iVar1 != 0)) {` m:11598 | HIGH |
| `myListSearch` @10038f9c | `LSearch` match proc (descriptor procInfo 0x2be0, used by `TInventoryList::PropToLoc`, p:16866) | match iff both cells are 2 bytes and equal (prop-id lookup), not a type-ahead | `if (((param_3 == param_4) && (param_3 == 2)) && (*param_1 == *param_2)) {` m:8537 | HIGH |
| `MyMenuDef` @100a8360 | **MDEF 128** (`GetResource('MDEF',0x80)`, created with `NewHandleClear(6)` if absent, JMP-patched; procInfo 0xff80) | copies the 50-byte PixMap template (whose `pmTable` `CreateGlobals` sets to clut 256: `uRam100d3e0e = *(undefined4 *)puVar3;` p:373), ORs 0x4000 into that table's `ctFlags`, then returns for every message — draws nothing. No `MENU`/`CMNU` in Cythera.rsrc names MDEF 128 (all procID 0) | `100a83e4: 60844000  ori r4,r4,0x4000` (`ppcdis.py 100a8360 100a841c`) | MED; user NOT RESOLVED |
| `MyMenuHook` @100ac3ac | menu-tracking hook (`InstallMenuHook__Fv`, p:53270) | while InputSprocket is active: poll an ISp element, then `HandleISPseudoMouse` (gamepad drives menus) | `.debug::_HandleISPseudoMouse__Fv();` m:23217 | MED |
| `TCMNU` / `TAppearanceMenu` | menu → command id | `TCMNU`: table from the `CMNU` resource (`TCMNU` ctor p:3521); `TAppearanceMenu`: `GetMenuItemCommandID` | `.glue::GetMenuItemCommandID(*(undefined4 *)(param_1 + 0xc),(int)param_2,auStack_8);` m:3766 | HIGH |
| `TWindow` (24) | base window | flags at +8: `&7` = layer (0 document, 1 floating, 3 top); `Select` places layer-1 windows behind the first layer-3 window and layer-0 windows behind the first floater; on deactivate, windows whose flags match the caller's mask are hidden and marked 0x4000, and re-shown on activate. `HandleDragWindow`: pref byte app+0x67 = 0 → classic `DragGrayRgn` outline; ≠ 0 → **live window drag**, and with app+0x68 also live updates of uncovered windows. Flag 0x40 = dockable: `ZoomRoutine` → `Dock(80,16)` sets the zoom standard state to an 80-px-wide, zero-height strip (title bar only) at the main screen's right edge, y = 40 + 16·n (n wraps to 1 near the bottom), and zooms; a collapsed docked window cannot be dragged. `GetResizeRect` = 64..32000. `ForceOnGDevice` pulls a window back when < 32 px of it lies inside the device rect inset 10. `KeyRoutine`: virtual keys 0x101/0x102/0x103 → commands 12/13/14 (cut/copy/paste), Delete (8) → 15, 0x100 → 11 | `if (*(char *)(*(int *)puVar1 + 0x67) == '\0') {` m:2288 | HIGH code; layer and pref meanings MED (prefs → app-shell.md) |
| `TDialog` (9), `MyDrawDialogItem` | modeless dialog on TWindow | events re-enter `DialogSelect` with `windowKind` swapped to 2 and back to 0x7A84; edit commands 12–15 → `DialogCut/Copy/Paste/Delete`; `DialogKeyEquiv` flashes a control item (types 4–7) with `HiliteControl(…,10)` + `Delay(8)`; `MyDrawDialogItem` = user-item proc forwarding to the owning TWindow (`InstallUserItems`, p:2492) | `*(undefined2 *)(*(int *)(param_1 + 4) + 0x6c) = 0x7a84;` m:1879 | HIGH |
| `DelverDialogerRoutine` @1007305c | the app-wide modal filter (descriptor stored by `InitInterface`, p:36815; used by `MyAlert`) | **update**: back pattern = tile 0x1A4 (`SetTilePat`), `DrawDialog`, then a 5-px-outset `Bevel(…,3)` ring round the default item (item number at 0x100D637C = 1). **keys**: §3.2 | `.debug::_SetTilePat__Fs(0x1a4);` m:12747 | HIGH |
| `MoveableDialogerRoutine` @1000efb4 | filter of `TApp::MoveableModalDialog` (m:3735) | mouse-down in the drag region (`FindWindow == 4`) of the dialog → `DragWindow` and swallow the event; update events for other windows go to the app; then chains to a caller filter (procInfo 0xfd0) | `.glue::DragWindow(param_1,*(undefined4 *)(param_2 + 5),PTR_DAT_100cdb94 + 0x56);` m:3702 | HIGH |
| `ExactMatchRoutine` @1007378c | Color-Manager search proc (procInfo 0x3d0, `InitInterface`) | true unless the entry's byte equals a field of the current GDevice's pixmap | `return (uint)*param_2 != *(uint *)(*(int *)(*piVar1 + 0x1a) + 6);` m:12818 | MED |
| `TApWindow` (6), `TApWidget` (12) | window/widget façade over the adapter singleton `_DAT_100d940c` (§2) | every routine forwards to the adapter; `MouseRoutine` toggles a checkbox on part 11 (`1 - value`) and reports (widget, value, part) to the window | `FUN_100c50e8(_DAT_100d940c,iStack_1c,1 - iVar1);` m:1477 | HIGH |
| `TAppearanceAdapter` (25) | Appearance Manager path | real controls: `CreateRootControl`; procIDs: push 0, check 1, slider 48+var, group box 0xA0 (160), static icon 0x141 (321), static text 0x120 (288, font via `SetControlData('font')`, text via `'text'`); keys → `HandleControlKey` on the focus | `.glue::NewControl(*(undefined4 *)(param_3 + 4),param_7,param_8,1,0,0,0,0x120,param_6);` m:300 | HIGH |
| `T7Adapter` (25) + `T7Widget` (16), `T7ControlWidget` (10), `T7SliderWidget` (8), `T7LabelWidget` (3), `T7GroupBox` (2), `T7IconWidget` (2) | System-7 path: an app-side widget tree (`std::vector` of children, `Embed`) | push/check = System 7 `NewControl` procID 0/1 wrapped in `T7ControlWidget`; slider = `DrawSlider`/`TrackSlider` (part 129); label = `TETextBox`, font −1 system, −2 Geneva 10, −3 Geneva 10 bold; group box = `FrameRect` 16 px below the top with the title at x+4 in srcCopy; icon = `PlotCIcon` | `.glue::TETextBox(param_1 + 0x1d,*(undefined1 *)(param_1 + 0x1c),param_1 + 0x14,` m:830 | HIGH |
| `TSaveFont`, `TSavePort`, `TSaveGWorld`, `THandleLocker` | scope guards (dtors restore font/face/size, port, GWorld+device, handle state) | — | `.glue::HSetState(*param_1,(int)(char)*(undefined2 *)(param_1 + 1));` m:12829 | HIGH |

**Which window uses which frame** (resource fields decoded with
`python3 - "$G/Cythera.rsrc"` over `rsrc.parse`, `struct.unpack('>4hhhhI',…)` per WIND/DLOG/CNTL;
procID = 16·WDEF + var): [HIGH]

| resource | title | procID → frame | notes |
|---|---|---|---|
| WIND 128 | Delver | 12 (system zoomNoGrow) | main 640×480 shell window |
| WIND 129 | Map | 16004 → **TBorderWDEF var 4** | square, grow box (64-px snap ↔ odd tile count, engine-classes.md §5) |
| WIND 130 | Text | 16016 → TPixsWDEF, refCon 0x00001220 | pix 0, content at (18,32) in the picture |
| WIND 131 / 132 | Roster / Character | 16000 → TBorderWDEF | Character has a close box |
| WIND 133 | Spellbook | 16016 → TPixsWDEF, refCon 0x00022018 | pix 2, content at (32,24), close tab |
| WIND 134 / 1134 | New Window | 16048 → TThinBorderWDEF / 16017 → TPixsWDEF var 1 (no picture) | — |
| WIND 135 | Status | 2 (system plainDBox) | — |
| WIND 136 | To Do | 16032 → **TDrawerWDEF** | rect height 0 = starts closed |
| DLOG 128–139, 141 | (key strings) | 16001 → TBorderWDEF var 1 | titles hold the keyboard map, §3.2 |
| DLOG 140, 142, 900, 9300 | — | 1 (system dBoxProc) | registration/notice dialogs |
| CNTL 128–134 | Quit, Onward!, Load Player, New Player, Save, Cancel, Don't Save | 16000 → TPushButtonCDEF | — |
| CNTL 135 | — | 1017 = popupMenuProc + 9 (fixed width, window font), menu 135 | MENU 135 "Strategy" |

## 2. Appearance adapter split ⚑ wave 2 (2026-10-06)
- **The OS check** is in `InitMac__4TAppFv @ 1000caf0` (census group C): `Gestalt('appr')` bit 0
  (`gestaltAppearanceExists`) sets app byte +0x16 and calls `RegisterAppearanceClient`:
  `if ((sVar3 == 0) && ((auStack_20[0] & 1) != 0)) {` (m:3042). [HIGH]
- **The choice** is made once, lazily, in `AddAppearance__9TApWindowFv @ 10003ce0` (main dump, p:238):
  byte +0x16 = 0 → a 4-byte object with vtable 0x100D39F8 (= `T7Adapter` methods), else vtable
  0x100D3D78 (= `TAppearanceAdapter` methods) — stored in the singleton `_DAT_100d940c`:
  `if (*(char *)(*(int *)PTR_DAT_100cdb84 + 0x16) == '\0') {`. Vtables resolved with the §0 loop
  (`… 100d39f8 8` → `SetData__9T7Adapter…`; `… 100d3d78 8` → `SetData__18TAppearanceAdapter…`). [HIGH]
- **Consumer**: the only `AddAppearance` call is `DoPrefs__Fv @ 100a3a9c` (p:51310; grep of all three
  dumps) — the Preferences window (`NewCWindow` 532×280, procID 0x412) is the one window built from
  these widgets; every other window uses the custom CDEFs of §1. [MED: single grep hit]
- Factories map one-to-one (§1 rows): Appearance → `NewControl` with Appearance procIDs; System 7 →
  procID 0/1 `NewControl` for buttons/checkboxes, app-drawn `T7*Widget` for slider, label, group
  box, icon. Both return a `TApWidget` handle {vtable 0x100D3D2C, object}. [HIGH]

## 3. Player-visible keyboard behaviour ⚑ wave 2 (2026-10-06)

### 3.1 `TListBox::Key @ 1006da58` (every LDEF-128 list: inventory, journal, to-do, portraits …)
- **No type-ahead.** The body handles only arrows and four navigation keys; `myListSearch` is an
  exact 2-byte-id matcher (§1). [HIGH]
- Arrows (Mac char codes, cell = (v,h)): 0x1C left h−1, 0x1D right h+1, 0x1E up v−1, 0x1F down
  v+1; only when a cell is selected. Negative → 0. **Clamp quirk:** a coordinate ≥ the data bound
  is set *to* the bound (`dataBounds.right`/`.bottom`), not bound−1, so Down on the last row (Right
  on the last column) deselects the old cell and selects a non-existent one — the list is left with
  no selection. Disasm: `1006db58: cmpw r4,r0; blt` then `lha r0,78(r4)` / `sth r0,82(r1)` (and
  76/80 for v) (`ppcdis.py 1006da58 1006dbd8`). [HIGH]
- After a move it calls `RevealCell` (vtable +0x54) with the **old** cell (`lwz r4,84(r1)` at
  1006dbf4; 84(r1) holds the `LGetSelect` result, 80(r1) the moved copy) — the list scrolls to keep
  the previous selection visible, not the new one. [HIGH]
- `RevealCell`: a cell above the visible rows scrolls by (v − top − 1) — one row more than needed;
  below scrolls by (v − bottom + 1). [HIGH]
- Navigation keys use `TApp::TranslateKey @ 1000d030` codes (p:3150–3170: key code 0x73→0x110,
  0x74→0x111, 0x75→0x112, 0x77→0x113, 0x79→0x114 = Home, PgUp, FwdDel, End, PgDn): Home → reveal
  (v 0, h visible.left); PgUp/PgDn → `LScroll` by (visible rows − 1), clamped; End → reveal last row;
  FwdDel ignored. With Shift (modifier 0x200) the target cell is also selected (old one cleared). [HIGH
  codes; key names MED from the Mac virtual key table]

### 3.2 Modal dialogs — `DelverDialogerRoutine` key map (DLOG 128–139, 141)
- Esc (0x1B) → item 2; Return (0x0D) / Enter (0x03) → the default item (1); Cmd-period → item 2
  (plain "." → nothing). Any other key: the **window title** is the key map — `;`-separated groups,
  group n = item n, any character in the group triggers it (DLOG 128 title `oO;qQ;nN;lL`). The pressed
  button flashes (`HiliteControl 10`, `Delay(8)`). [HIGH]
- **Quirk:** the scan stops one short — `cmpw r3,r0; blt` at 10073264 compares the index with the
  title length, so the title's **last character never matches** (in `oO;qQ;nN;lL`, `L` is dead, `l`
  works) (`ppcdis.py 100731c0 10073280`). [HIGH]

## 4. std template instantiations (group B, 41 rows) ⚑ wave 2 (2026-10-06)
Names demangled with `python3 docs/cythera/tools/demangle.py std.txt full`; owner = traceback
neighbours (`ghidra/Cythera_pef.tb.txt`) and the users found by `grep` of tb names.

| family (rows) | container | used by | label |
|---|---|---|---|
| exceptions (8) | dtors/`what()` of `bad_alloc`, `exception`, `logic_error`, `length_error`, `invalid_argument`, `out_of_range` | MSL runtime (vector growth throws `"vector insert length error"`, T7Widget::Embed m:423) | HIGH |
| registry (4) | `map<ulong, void*(*)(TStream*)>` + allocator/`_EmptyMemberOpt` | `TRegistry::RegisterClass @ 100186f0` — stream class id → reader | HIGH |
| task queue (5) | `queue<TaskEvent, deque<TaskEvent>>`, `__cdeque<TaskEvent*>` | `TTaskMaster` / `QueueTaskEvent @ 1001c8d4` (engine-classes.md) | MED |
| statics (3) | `vector<short>` ctor/dtor; `__arraydtor$2299` = destroy 8 elements of 12 B | after `__sinit_TStatusWindow_cp` — a static array of 8 `vector<short>` in TStatusWindow.cp | MED |
| activity (2) | `list<ActivityQueueEntry>` | `TActiveMonster` (follows its ctor) — NPC activity queue (schedules-npcs.md) | MED |
| spell FX (4) | `map<TSpellFX, ushort>` | `TSpellFX` (`AddAbility`, `PassTime`, `WriteFXQueue`) — magic.md | LOW (meaning of the ushort) |
| seg files (4) | `set<FileRange, CompareRange>` | after `TSegFile::Verify` — segment-file range bookkeeping | MED |
| sanity (4) | `set<MemRange>` | `TSanity` debug checker (`MemRange::Test @ 1009b81c`) | MED |
| widgets/lists (4) | `vector<TScriptedWindow::TWidget*>`, `vector<TPickItemDrawer*>`, `vector<TInventoryPile::PileEntry>`, `allocator<char>` | `TScriptedWindow` ctor, `cbPickItem`, `TInventoryPile` ctor, `TWText` | HIGH (neighbours) |
| strings (3) | `basic_string<char>::CharArray` `_EmptyMemberOpt`, `allocator<char>` `_EmptyMemberOpt`, `out_of_range` | `basic_string` users (TWText) | MED |

## 5. Game-rule content
None. Every body here is presentation or OS plumbing. Two UI facts touch other banks only as
cross-references: the Map window's 64-px square grow (`TBorderWDEF::Grow`) is what keeps the viewer's
tile count odd (engine-classes.md §5, ui-play.md); the edit-number auto-repeat is the stepping
control of whichever window uses CDEF 1002 (ui-play.md / app-shell.md own those windows). [MED]
