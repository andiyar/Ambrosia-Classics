# Cythera 1.0.4 — scripted windows and their widgets (native code, as the script sees it)

⚑ wave 2 (2026-10-06) — new file. Scripts build windows with statement/expression 0x9B `sysnew`
(script-vm.md §4/§5) and talk to them through fields 0x37–0x41; the widgets call back into scripts.
This file reads the 128 group-F bodies of the missing dump (census §1 F) plus the main-dump
constructors they depend on. The conversation-side modal loop is in dialogue-ui.md §10.

Register: **code reading only**; HIGH / MED / LOW as in dialogue-ui.md. Script listings are
`ghidra/cythera-scripts/<seg>.txt` (scriptdis).

## 0. Provenance and method

- Bodies: `python3 ghidra/find_func.py "<exact names @…>" --file ghidra/Cythera_missing.decompiled.c --max 0`
  over the 128 F names of `docs/cythera/tools/missing-addrs.txt` (+ 3 `TScriptPickItemDrawer` rows, read
  in dialogue-ui.md §9.1). **All 128 read whole.** Main-dump context: `CreateSysObj`, `DispatchSysObj`,
  `DispatchUIMethod`, `GetField/SetField__15TScriptedWindowFsss`, `Alloc/Find/FreeScripted{Window,Widget}`,
  every `Display*`, `AddWidget`, `FindWidget`, window `Mouse/Key/Idle`, the widget and `TW*` ctors,
  `TScriptedWindow(TStream)` ctor (registrations), `RenumberProp__16TInventoryWindowFss`.
- Vtables. Widget base `TScriptedWindow::TWidget` = 0x100D71B8 (dtor store), slots resolved with the
  dialogue-ui.md §0 one-liner (`vt=0x100d71b8`, s = 0xC…0x5C) + `tb.py --at` [HIGH]:
  +0xC dtor · +0x10 WantsFocus · +0x14 IsPoint · +0x18 MouseRoutine · +0x1C CursorRoutine · +0x20 KeyRoutine ·
  +0x24 FocusRoutine · **+0x28 Flash** · +0x2C PointToProp · +0x30 PropToPoint · +0x34 CanDrop ·
  +0x38 HiliteDrop · +0x3C UnhiliteDrop · +0x40 DoDrop · +0x44 RebuildInv · +0x48 RenumberParent ·
  +0x4C RenumberChild · +0x50 DispatchWidgetMethod · +0x54 GetField · +0x58 SetField · +0x5C Marshal
  (+0x8 = 0: `Draw` is per class). Window `TScriptedWindow` = 0x100D69E8 (83 slots dumped the same way;
  the ones used here: +0x24 Close, +0x28 Mouse, +0x2C Key, +0x3C Cursor, +0x40 Idle, **+0x48
  HandleDragWindow**, +0x98 CanSearch, +0x9C–+0xA8 drop family, +0xC4 `Invalidate__16TInventoryWindowFs`,
  **+0xD0 RenumberParent, +0xD4 RenumberChild**, +0xD8 Marshal, +0xE0 DispatchWindowMethod,
  **+0xE4 GetField**, +0xE8 SetField, **+0xEC OffsetOrigin, +0xF0 DispatchCommand**). [HIGH]

## 1. Object ids and dispatch

- **Ids.** `AllocScriptedWindow @ 100841BC`: first free of **256** slots in `PTR_DAT_100cede8`,
  `local_28 = uVar2 | 0x41040000;` — a window is the tag-4 object of class **0x104**. `AllocScriptedWidget
  @ 10084464`: first free of **1024** slots in `_DAT_100ceddc`, id `uVar2 | 0x41050000` (class **0x105**).
  Both return the existing id when the pointer is already registered; table full → a thrown exception
  (`FUN_100bdef4`). [HIGH]
- **Sends.** DoInterp0 routes a class-0x1xx object (`param_3 & 0x1000000`) to `DispatchSysObj`, which
  passes 0x104/0x105 to `DispatchUIMethod` and answers Nil for 0x101 and anything else
  (`if ((sVar1 == 0x101) || ((sVar1 != 0x104 && (sVar1 != 0x105)))) *param_1 = Nil`). `DispatchUIMethod`
  calls the window's +0xE0 `DispatchWindowMethod` or the widget's +0x50 `DispatchWidgetMethod`
  (`ppcdis.py 10087df8 10087ef0`: `lwz r12,224(r12)`, `lwz r12,80(r12)`). [HIGH]
  - `DispatchWidgetMethod__Q215TScriptedWindow7TWidgetFssP5VAddr @ 10087C20`: returns Nil — widgets answer
    no selector. [HIGH]
  - `DispatchWindowMethod__15TScriptedWindowFssP5VAddr @ 10087F34`: only selector **4** does anything —
    it walks the widgets comparing each widget's +0xC with the argument (`IsEqual`) and computes the
    matching widget's id into a local — then returns **Nil** in every case (the found id is never stored
    to the result). [HIGH code; ⚑ an apparent original slip: "find widget by tag" always yields Nil]
- **Fields.** `GetField__Fsss`/`SetField__Fsss` (main) route 0x104/0x105 to
  `GetField/SetField__15TScriptedWindowFsss`, which call the window's +0xE4/+0xE8 or the widget's
  +0x54/+0x58 (`ppcdis.py 10088028 10088108`: `lwz r12,228(r12)`, `lwz r12,84(r12)`). A freed slot
  answers Nil. [HIGH]
- **Window fields.** Plain `TScriptedWindow`: `GetField__15TScriptedWindowFs @ 1008822C` returns Nil
  and `SetField @ 1008826C` is empty — a picture window has **no** script-visible fields. Interaction
  windows (modal) answer field 0x37 (dialogue-ui.md §10). [HIGH]
- **Is it open?** Builtin DB `cbShowWindow` = `FindScriptedWindow(obj)` + `Select` (script-builtins §4);
  `FindScriptedWindow__15TScriptedWindowF5VAddr` takes a 0x104 id, or any other value as a prop index
  for `FindInventory` — so `scripted_window_shown(A30)` with a prop finds that prop's open window. [HIGH]
- **Delete.** `DeleteSysObj__Fss @ 10091C20`: class 0x104 → `FindScriptedWindow` + **+0x24
  `CloseRoutine`** (`ppcdis.py 10091c20 10091cd0`: `10091c90: 818c0024 lwz r12,36(r12)`), so deleting a
  window object also sends selector 1 (§3); 0x101 and 0x105 → nothing (a widget cannot be deleted alone). [HIGH]

## 2. Creating windows and widgets — 0x9B `sysnew` (`CreateSysObj__FssP5VAddr @ 10091830`)

### 2.1 Class map [HIGH]
Each `sysnew_<cls>(args…)` calls one constructor; args are the pushed values (a[0] = window id for
widgets). Shipped uses = `grep -h -o 'sysnew_[0-9A-Za-z]*' ghidra/cythera-scripts/*.txt | sort | uniq -c`.

| cls | native | args (a0…) | shipped uses |
|---|---|---|---|
| 1 | heap list (`THeapObj` tag 1, `AtPut` each arg) | values… | 12 |
| 3 | heap string = concatenation of the args' strings | strings… | 1 (104B) |
| 4, 2 args | **`TInteraction::CreateModal(w, h)`** — modal window | w, h | 0EA5, 0EA9 (350×300), 100E (300×320), 1087 (350×200), 300F (260×130) |
| 4, other | **`DisplayPicture`** — picture window | prop, frame or Nil, a2, a3, w, h | 13 (signs, scrolls, containers, instruments, devices, map …) |
| 6 | `TWText` | win, text, x, y, w, h | 17 |
| 7 | `TWScrollText` | win, text, x, y, w, h | 1 (0E65) |
| 8 | `TWButton` | win, title, x, y, w, h | 15 |
| 9 | `TWPix` | win, pix, x, y | 8 (1175) |
| 0xA | `TWPixButton` | win, upPix, downPix, offPix, x, y | 12 |
| 0xB | `TWInvent` (container view of the window's prop) | win, x, y, w, h | 1 (0E66) |
| 0xC | `DisplayAddDrop` — finds the window and returns **Nil**, creates nothing | win | 0 |
| 0xD | `TWList` | win, x, y, w, h | **0** |
| 0xF | `TWMusicBox` | win, x, y, w, h, instrument, notes list | 4 (1098, 1099 ×2, 109A) |
| 0x10 | `TWIcon` | win, tile, x, y | 3 |
| 0x11 | `TWNumberEntry` (proc 0x3EA0) | win, x, y, w, h | 3 |
| 0x12 | `TWNumber` (proc 0x3EA1, max 0x7FFF) | win, x, y, w, h | 2 |
| 0x13 | `TWAutoMap` | win, x, y, w, h | 1 (117A) |
| 0x14 | `TWTextEntry` | win, text, x, y, w, h | 1 (1087) |
| else | Nil | — | — |

So `TWList` (and the drop class 0xC) are compiled but never used by 1.0.4's scripts. [HIGH]

### 2.2 Common constructor path [HIGH, e.g. `DisplayAddButton @ 10084E68`]
`FindScriptedWindow(a0)` then a checked cast to `TScriptedWindow` (`FUN_100be5a0(…,&PTR_s_TScriptedWindow_100d69a0,…)`;
not a scripted window → result Nil); set the port; untag the integer args; **window +0xEC
`OffsetOrigin(&x, &y)`** (`ppcdis.py 10084e68 10084fc0`: `lwz r12,236(r12)`) — a no-op for picture
windows, +0xA50/+0xA52 for a conversation (dialogue-ui.md §2); `new` the widget; `AddWidget`;
`AllocScriptedWidget` → the widget id is the expression's value.
`AddWidget @ 10086BCC`: append to the window's widget vector (+0x1C capacity, +0x20 count, +0x24 array,
doubling growth); the first widget whose `WantsFocus` is true becomes the focus (+0x28) and gets
`FocusRoutine(0)`; then window +0xC4 `Invalidate(1)`.

### 2.3 Windows
- **Picture window** (`DisplayPicture @ 1008476C`): a[1] = Nil → `TScriptedWindow(prop, 16000, refCon 0, w, h)`;
  else proc **0x3E90** and refCon = `a3 | a1 << 16 | a2 << 8`. `__ct__15TScriptedWindowFsslss @ 10086000`:
  `TInventoryWindow(prop)` (window +0x10 = the prop it belongs to), `NewCWindow`, **+0x2C := (proc == 0x3E90)**
  (draggable by any non-widget point, §3), `PlayIFSound(1)`, `RandomPlace`. [HIGH code; MED that the
  0x3E90 WDEF draws its frame from the refCon bytes — WDEFs are ui-toolkit.md's]
- **Modal window** (`CreateModal__12TInteractionFss`): no conversation → a new `TSimpleInteraction(NULL, w, h)`
  becomes the current interaction; in a conversation → `CalcOrigin(conv, w, h)` and the conversation
  itself is the window. Either way it gets a 0x104 id. [HIGH]

## 3. Window behaviour [HIGH unless marked]

- **Mouse** (`MouseRoutine__15TScriptedWindowF5Points @ 10086880`): update, then `FindWidget` (topmost =
  last added: the list is searched from the end with `IsPoint` = `PtInRect(where, widget+0x10)`); if the
  widget `WantsFocus` and is not the focus: old focus `FocusRoutine(1)`, new focus `FocusRoutine(0)`; then
  the widget's `MouseRoutine`; if that returns false and +0x2C is set → +0x48 `HandleDragWindow`.
- **Keys** (`KeyRoutine__15TScriptedWindowFs @ 100865D4`): with a focus widget, **only it** gets the key;
  otherwise every widget from last to first gets it (shortcut letters, §4.1). So in a window with a
  text-entry field, button shortcut letters are dead. **Idle**: focus `FocusRoutine(2)` (TE caret).
- **Close** (`CloseRoutine__15TScriptedWindowFv @ 10086340`): **sends selector 1 to the owning prop**
  (`___ct__5VAddrFcUsUs(&uStack_18,4,0,*(undefined2 *)(param_1 + 0x10)); _DoInterp__7TInterpFs5VAddr(auStack_14,1,uStack_18);`
  — `ppcdis.py 10086340 10086410`: `1008637c: 38800001 li r4,1`, `10086380: bl 0x10082658`), then frees and
  deletes every widget, frees the window id, `TInventoryWindow::CloseRoutine`. No shipped class defines
  selector 1 (`grep -h '\.dict' ghidra/cythera-scripts/*.txt | grep -o -E '[{ ]1[:/][^,}]*'` → nothing),
  so it lands in 3001 `return 0` (script-library §9). [HIGH]
- **Drops** (`CanDrop/HiliteDrop/UnhiliteDrop/DoDrop__15TScriptedWindow`): to the widget under the point,
  else the `TDroppableWindow` behaviour; `CanSearch` returns 1; `PointToProp`/`PropToPoint` ask the
  widgets. Widget base `CanDrop @ 10087A0C` refuses with `AutoEye` of `(Can't drop there)`
  (`toc.py 100cedac`). [HIGH]
- **Owner tracking** (`RenumberProp__16TInventoryWindowFss @ 100313B4`, called from `LoadLevelProps` and
  `CopyProp`): the window showing prop *old* gets +0xD0 `RenumberParent(old, new)`, the window showing
  *old*'s parent gets +0xD4 `RenumberChild(old, new)` (`ppcdis.py 100313b4 10031464`: `lwz r12,208(r12)`,
  `lwz r12,212(r12)`). `RenumberParent__15TScriptedWindowFss @ 1008742C` = the inventory-window update of
  +0x10 then every widget's `RenumberParent`; `RenumberChild @ 100874F4` = every widget's `RenumberChild`.
  Only `TWInvent` implements them (§5.9). ⚑ The base widget versions are empty, so a widget's f38
  receiver (§4) and the music box's +0x4C keep the **old** prop index after a renumber. [HIGH code;
  MED effect — when renumbering happens with a window open was not traced]

## 4. The widget base, as scripts see it

`__ct__Q215TScriptedWindow7TWidgetFP15TScriptedWindowssss @ 100875B4` (main) [HIGH]: +0x20 window,
+0x10 rect (x, y, x+w, y+h), **+4 := prop(window +0x10)** (`param_1[1] = *(ushort *)(param_2 + 0x10) | 0x40000000;`),
**+8 := Nil**, +0xC := 0, four shortcut keys at +0x18 := 0.
Fields (`GetField/SetField__Q215TScriptedWindow7TWidget`, main) [HIGH]:

| field | widget slot | get | set |
|---|---|---|---|
| 0x38 | +4 | value | any value — the **first argument** passed to the handler |
| 0x39 | +8 | value | any value — the **handler** |
| 0x3A | +0xC | value | any value — a free tag (selector-4 lookup, §1) |
| 0x3B | window | the window id (`FindScriptedWindow`) | — |
| other | — | Nil | ignored |

**Pressing a widget** — the same tail in `TWText::MouseRoutine @ 10088B54`, `TWControl::MouseRoutine @
1008A990`, `TWButton::Flash @ 1008AC94`, `TWPixButton::MouseRoutine @ 1008C1A0`,
`TWNumberEntry::MouseRoutine @ 1008CCB0` [HIGH]:
```
if (*(int *)(param_1 + 8) == *(int *)PTR_DAT_100cdbb0) { FUN_100c50e8(*(undefined4 *)(param_1 + 0x20),param_1); }
else { FindScriptedWidget(&uStack_1c,param_1); uStack_18 = *(undefined4 *)(param_1 + 4);
       _DoInterp__7TInterpFs5VAddr5VAddr5VAddr(auStack_14,0xffffffff,*(undefined4 *)(param_1 + 8),uStack_18,uStack_1c); }
```
- Handler **Nil** → window +0xF0 `DispatchCommand(widget)` (`ppcdis.py 1008a990 1008aa5c`: `lwz r12,240(r12)`):
  empty for picture windows (the press does nothing); for a modal window it ends the modal loop and
  `window.f37` returns this widget (dialogue-ui.md §10).
- Handler set → `DoInterp(−1, handler, f38, widget)`. DoInterp0 runs a **code-pointer** receiver (tag −1)
  directly with the remaining values as arguments
  (`___ct__7TInterpFs(auStack_5c,uVar8 & 0x7fff); _DoInterpAt__7TInterpFsP5VAddr(&local_78,auStack_5c,(int)local_4c[0],… + 4);`
  in `DoInterp0__7TInterpFs5VAddrs @ 10082B34`), so the code at the handler runs with **A30 = f38
  (by default the window's prop), A31 = the widget id**; the selector −1 is never looked up. Every
  shipped f39 store is a code pointer (`grep -h -E '\.f39' ghidra/cythera-scripts/*.txt` → 11 stores, all
  `@xxxx`). [HIGH]

### 4.1 Shortcut letters
`__ct__9TWControlFP15TScriptedWindow5VAddrsssss @ 1008A304` (main): the title becomes a Pascal string; while
its length L > 2 and the byte before the last is `/`, the **last byte** is stored as the next shortcut
(+0x18, +0x1A, …) and L −= 2; the control is created with the stripped title (`ppcdis.py 1008a304 1008a438`:
`1008a3d4: 3861003f addi r3,r1,63` / `1008a3d8: 7c0300ae lbzx r0,r3,r0` / `1008a3dc: 2c00002f cmpwi r0,47`;
store `1008a3a4: 7c8320ae lbzx r4,r3,r4` at sp+64+L, `1008a3b0: 7c9f032e sthx r4,r31,r0`). There is no
bound on the number of pairs (a fifth would overwrite +0x20, the window pointer). [HIGH]
`KeyRoutine__Q215TScriptedWindow7TWidgetFs @ 10087854`: A–Z → a–z, compare with the four shorts, a match
calls **+0x28 `Flash`** (`ppcdis.py 10087854 100878fc`: `100878c0: 818c0028 lwz r12,40(r12)`). Only
`TWButton::Flash` does something: `HiliteControl(1)`, `Delay(8)`, `HiliteControl(0)`, then the press tail.
Shipped titles: 100E sleep dialog `Until Dawn/d`, `…/o`, `…/n`, `…/s`, `…/m`; 300F take-or-steal
`Take/s`, `Steal/s` (`grep -n -E '"(Until [A-Za-z]+/.|Take/s|Steal/s)"' ghidra/cythera-scripts/*.txt`).
⚑ `Cancel/c/` (100E @026F) and `Leave/l/` (300F @010C) end in `/`, so the byte before the last is a letter,
**no shortcut is parsed and the title is shown with the slashes**. [HIGH code + bytes; not observed]

## 5. Widget kinds

Each `Marshal` writes a four-letter tag then the base record (`Marshal__Q215TScriptedWindow7TWidget`: +4,
+8, the rect, the four shortcut shorts) then its own data. Tags are the constants passed first
(`python3 -c "print((0x77547874).to_bytes(4,'big'))"` style, all decoded this session). [HIGH]

**5.1 `TWText` 'wTxt'** (cls 6). Ctor (main): +0x24 std::string text, +0x28 the text VAddr, +0x2C
clickable := 0, +0x2D pressed := 0, +0x2E justification := 1, +0x30 colour := 0x45. Fields
(`GetField @ 10088CEC`, `SetField @ 10088DBC`) [HIGH]: **0x3C** justification (0 left, −1 right, else
centre; `Draw`: `if (… + 0x2e) == 0 … +2; else if (… == -1) … right − 2`); **0x3D** set text (copy +
`InvalRect`; not readable); **0x40** clickable (True/False); **0x41** colour; 0x37 set is ignored.
Scripts write 65535 for right-justified (`setfield L09.f3C = 65535`, 0EA5/0EA9) — untagged to the short −1.
`MouseRoutine`: not clickable → base behaviour (window drag); clickable → tracked, drawn in 0xCD while
pressed, released inside → press tail. `Draw @ 1008872C` lays the text out with `TTextContext` in style 2,
falling back to style 1 when it does not fit, centred vertically [MED: style numbers only].

**5.2 `TWTextEntry` 'wTEd'** (cls 0x14). Ctor: `TENew` over the rect, `TESetText`. **0x37** get = a new heap
string copied from the TE text (`THeapObj` tag 3, NUL added); set = `TESetText` of the string.
`WantsFocus` = 1; Mouse = `TEClick` (shift extends) + window `Invalidate(0x4000)` (+0xC4,
`ppcdis.py 100895e8 10089650`: `li r4,16384`, `lwz r12,196(r12)`); Key = `TEKey`; Focus 0/1/2 =
`TEActivate`/`TEDeactivate`/`TEIdle`; cursor 0x2D; `Draw` = erase, frame, `DrawTEInPort`. Marshal saves the
text. [HIGH] Used once: 1087 (inkwell, a modal 350×200 window).

**5.3 `TWScrollText` 'wSTx'** (cls 7). `PostInit` (main) draws the whole text once into a QuickDraw
picture (`OpenPicture` … `TTextContext::Draw(…, 0x14, …, 0x21, 0x199)` … `ClosePicture`) and adds a 16-px
scroll bar (proc 0x3E90) on the right. `MouseRoutine @ 1008A0E4`: outside the text column → base; in the bar:
thumb (0x81) → `TrackControl` + `Scrolled`; arrows ±1, page parts ±height/10, via an action proc
(`ScrollTextTrack @ 10089FD4` clamps 0…max and calls `Scrolled`). `Draw` clips, sets the origin
(−4, +0x2C) and `DrawPicture`s. [HIGH bodies; MED for the scroll unit = 10 px]

**5.4 `TWControl` / `TWButton` 'wBut' / `TWNumberEntry` 'wNmE' / `TWNumber` 'wNum'** (cls 8 / 0x11 / 0x12).
`TWControl` fields (`GetField @ 1008A748`, `SetField @ 1008A82C`) [HIGH]: **0x37** control value (set only
from an integer), **0x3E** minimum, **0x3F** maximum, **0x40** set True → `HiliteControl(0)`, False →
`HiliteControl(1)` (not readable). Mouse = `TrackControl` → press tail (`TWNumberEntry` passes action −1,
i.e. the CDEF's own tracking); cursor 0x2A. Button proc 16000, number entry 0x3EA0, number 0x3EA1
(max 0x7FFF). Example: 100E's hours field `sysnew_11(L06, 150, 240, 150, 32)` then `f3E = 1`, `f3F = 12`,
`f37 = 1`; after the modal returns the `Hours` button, `L10 = L0D.f37`.

**5.5 `TWIcon` 'wIcn'** (cls 0x10): +0x24 tile number; `Draw @ 1008AFA0` = `CopyBits` from the tile pixels
`*PTR_DAT_100cdc64 + tile * 0x400` (mode 0x24) into the rect. No fields of its own. [HIGH]

**5.6 `TWPix` 'wPix'** (cls 9): +0x24 pixel-cache id. **0x37** get = the id; set (integer) = dispose the old
pixmap, `NewPix(id)`, redraw (+8 `Draw` with the window port) and window `Invalidate(0x4000)`. `Draw` =
`LoadPix` + `CopyBits` (mode 0x24); dtor `ReleasePix`. [HIGH] 1175 shows its 8 holes this way
(`setfield L04.f37 = (L00[A31] + 53)`).

**5.7 `TWPixButton` 'wPxB'** (cls 0xA): pix ids +0x24 up / +0x26 down / +0x28 disabled; state +0x2A
(0 up, 1 down, 2 disabled) [HIGH]:

| field | get | set |
|---|---|---|
| 0x40 enabled | state 2 → False; 0/1 → True | True → 0; False → 2 |
| 0x37 pressed | 1 → True; 0 → False; 2 → Nil | True → 1; False → 0; Nil → 2 |

Each set invalidates the rect. `MouseRoutine @ 1008C1A0`: only in state 0 and only on a **non-transparent
pixel** of the up picture (`IsPixelHit`); `PlayIFSound(6)`, track (state 1 while inside), `PlayIFSound(7)`,
released inside → state 0, press tail. Other clicks → base. [HIGH]

**5.8 `TWAutoMap` 'wMap'** (cls 0x13): `Draw @ 1008C814` — no buffer → fill; dirty flag +0x64 →
`MagicMap(viewer, cx − w/2, cy − h/2, w, h, +0x58, +0x5C, 5)` with centre (+0x60, +0x62), then `CopyBits`.
`MouseRoutine @ 1008C9D0` pans while dragging: centre = start − (mouse − start)/4 on each axis; redraw on
change. ⚑ The y-change test compares the old **y** with the new **x** (`ppcdis.py 1008c9d0 1008cac8`:
`1008ca58: a81f0060 lha r0,96(r31)` / `1008ca5c: 7fa30734 extsh r3,r29` / `1008ca60: 7c030000 cmpw r3,r0`) —
the decompiler's `(short)param_2 - (short)param_2` hides the saved start point (sp+60). [HIGH from the
listing] Marshal saves the centre. Used by 117A (map).

**5.9 `TWInvent` 'wInv'** (cls 0xB): +0x30 the container prop (= window +0x10 at creation), +0x24 a
`TInventoryPile` over the rect (`PostInit`, main). `Draw` = pile draw; `RebuildInv` = rebuild pile +
window `Invalidate(1)`; `RenumberParent` follows +0x30; `RenumberChild` → pile. `PointToProp` /
`PropToPoint` / `MouseRoutine` → pile hit test, a hit starts the droppable-window drag
(`MouseRoutine__16TDroppableWindowF5Points`). [HIGH]
**`CanDrop__8TWInventFsR5Point @ 1008DAE0`** (dragged prop *p*, point) [HIGH], in order, each refusal
showing a hint line via `AutoEye` (`toc.py 100ced74 100ced70 100cedac 100ced6c 100ced68`):
*p* is the container itself → `(Fold Space)`, refuse; *p* already inside it (`GetPropParent(p)` = +0x30) →
`(Abort)`, refuse; point outside the rect → `(Can't drop there)`; else **selector 23 to the container
with *p***: `DoInterp(0x17, prop(+0x30), prop(p))` — not `IsTrue` → `(Doesn't fit)`, refuse; true →
`(Put In)`, accept. `DoDrop` (point in rect) → `TakeCommand(p, container)`. Selector 23 receivers:
desk 1011, dresser 1012, crate 1043, corpses 104E/10D2/111B, sack 108B, pouch 108C, chest 108D, coffer 108E
(`grep -l '\.dict' … | xargs grep -l -E "[{ ]23[:/]"`); the default 3017 returns False. [HIGH]

**5.10 `TWList` 'wLst' + `TWListList`** (cls 0xD, unused by shipped scripts). Rows are list cells whose
first 4 bytes are an object id followed by text (`AddItem @ 1008E998`: `LAddRow`, `LSetCell(&item, 4, …)`,
`LAddToCell(text)`). `MouseRoutine @ 1008E7F4` → `TListBox::Click` (= `LClick`, true on double-click;
`Click__8TListBoxF5Points @ 1006DEDC`) [HIGH]:
single click on a row → **selector 8 to the row's object** (`DoInterp(8, item)`); double click →
**selector 10 to the container with the item** (`DoInterp(10, prop(+0x30), item)`) then
`PostUse(item, result)`. `CanDrop`/`DoDrop` = the `TWInvent` logic (selector 23). `Marshal` **throws**
(`Marshalling TWList not supported`, `toc.py 100ced64`). `LDEFDraw` draws the cell text from byte 4,
`InvertRect` when selected. [HIGH]

**5.11 `TWMusicBox` 'wMus'** (cls 0xF) — §7.

## 6. Persistence — `TRegistrar` and the stream tags

`Marshal__15TScriptedWindowFP7TStream @ 1008F5F0` writes tag **'ScrW'**, the inventory-window record,
then width, height, global top-left, refCon (+0x30), proc (+0x34), widget count, and each widget's
Marshal. `__ct__15TScriptedWindowFP7TStream` (main) registers the 13 widget tags on first use
(`_RegisterClass__9TRegistryFUlPFP7TStream_Pv(0x77547874,PTR_PTR_100cdfc0);` …). The 15
`CreateFromStream__…TRegistrar<…>` bodies are identical shapes — `new(size)` + the class's `(TStream*)`
ctor. Map, checked by resolving each TOC slot to its TVector code and `tb.py --at`
(`toc.data_u32` over 0x100CDF90…0x100CDFC0, 0x100CDD18/1C) [HIGH]:

| tag | registrar | size | tag | registrar | size |
|---|---|---|---|---|---|
| ScrW | `TRegistrar<TScriptedWindow>` 10012A6C | 0x38 | wNmE | `<TWNumberEntry>` 1008F024 | 0x28 |
| ChrW | `<TCharacterWindow>` 100129CC | 0x88 | wNum | `<TWNumber>` 1008F0BC | 0x28 |
| wTxt | `<TWText>` 1008F560 | 0x34 | wBut | `<TWButton>` 1008F150 | 0x28 |
| wTEd | `<TWTextEntry>` 1008F4C8 | 0x28 | wIcn | `<TWIcon>` 1008F1E4 | 0x28 |
| wSTx | `<TWScrollText>` 1008F430 | 0x34 | wInv | `<TWInvent>` 1008F274 | 0x34 |
| wMus | `<TWMusicBox>` 1008F398 | 0x50 | wLst | `<TWList>` 1008F308 | 0x34 |
| wPix | `<TWPix>` 1008EF94 | 0x58 | wPxB | `<TWPixButton>` 1008EEFC | 0xC4 |
| wMap | `<TWAutoMap>` 1008EE68 | 0x68 | | | |

Saved: the widget base (f38, f39, rect, shortcuts) and per kind: text + flags (wTxt), TE text (wTEd),
the text VAddr (wSTx), pix ids/state (wPix, wPxB), tile (wIcn), centre (wMap), instrument + prop + notes
(wMus, §7), container (wInv). **Not saved**: the music-box note history (+0x48). [HIGH]

## 7. `TWMusicBox` and the signals it leads to (item 23, native side)

`DisplayAddMusicBox @ 100856D8` (main): notes = up to 16 integers from the list (`local_5c[16]`, loop to
`Len`), then `TWMusicBox(win, prop = window +0x10, x, y, w, h, instrument, count, notes)`. Ctor: +0x24
instrument, +0x26 key count, +0x28 notes (shorts), **+0x48 history := 0**, **+0x4C := the prop**. [HIGH]
`Draw @ 1008D1EC`: key *i* is a letter `'A' + note` centred in a slot of width w/count, outlined 0x45.
**`MouseRoutine__10TWMusicBoxF5Point @ 1008D328`** [HIGH]:
```
sVar2 = (short)(((int)(short)param_2 - (int)*(short *)(param_1 + 0x12)) / (int)sVar5);      // key index
… DrawTextOutlined(…,&cStack_28,1,0x199,0x21);                                              // lit
.debug::_PlayNote__6TAudioFsss(_DAT_100cdd24,(int)*(short *)(param_1 + 0x24),*(short *)(param_1 + sVar2 * 2 + 0x28) + 0x40,0x14);
… DrawTextOutlined(…,&cStack_28,1,0x45,0x21);                                               // unlit
*(int *)(param_1 + 0x48) = *(int *)(param_1 + 0x48) << 4 | (int)*(short *)(param_1 + sVar2 * 2 + 0x28);
.debug::___ct__5VAddrFcUsUs(&uStack_30,4,0,*(undefined2 *)(param_1 + 0x4c));
.debug::_DoInterp__7TInterpFs5VAddr5VAddr(auStack_2c,10,uStack_30,uVar4 & 0xfffffff);
```
(listing: `1008d4f4: 54842036 rlwinm r4,r4,4,0,27`, `1008d4fc: 7c800378 or r0,r4,r0`, `1008d510: 5720013e
rlwinm r0,r25,0,4,31`, `1008d534: 3880000a li r4,10`, `1008d538: bl 0x100826f4`). So each key press plays
`PlayNote(instrument, note + 0x40, 0x14)` and sends **selector 10 (use_on) to prop(+0x4C) with the integer
`(history << 4 | note) & 0x0FFFFFFF`** — the last seven notes, newest in the low nibble. Clicks outside
the keys → base. ⚑ The note is ORed unmasked: a note > 15 spills into the previous nibble. [HIGH]

**Native → script → signal joins** (for the orchestrator; the signal *receivers* are R5's
schedules-npcs.md): [HIGH bytes, `sed -n … ghidra/cythera-scripts/<seg>.txt`]
- 1099 panpipes: two key sets (`blk@004D` 15, 12, 9, 7, 3 for quality 1, `blk@007A` 15, 12, 9, 6, 3 else);
  its use_on: `0098: jf (((A31 & 1048575) == 1014211) && (A30.f06:quality == 1)) -> 00B7`, `00B0: send_signal(129)`.
  1014211 = 0xF79C3 = notes 15, 7, 9, 12, 3 (oldest first).
- 109A lyre: keys 18, 15, 12, 9, 6, 3; use_on `005F: jf ((A31 & 4095) == 4038) -> 0077`, `0070: send_signal(131)`;
  4038 = 0xFC6 = 15, 12, 6. (Key 18 = 0x12 ORs a 1 into the previous nibble.)
- 1098 lute: keys 15, 12, 9, 6, 3, no use_on → 300A `return 0`.
- 1175 "strange device": three `TWPixButton`s whose f39 handlers (`@01FB`, `@0209`, `@0217`) run through the
  §4 press tail (selector −1) → `sub_00BE(A30, 0/1/2)` → `sub_0063(…, 132/133/134)` → `00B7: send_signal(A32)`
  when the 8 hole states match a pattern. So signals **132–134** are reached only from
  `TWPixButton::MouseRoutine` (the handlers are anonymous code, not dictionary methods) [HIGH], and
  **129 / 131** from `TWMusicBox::MouseRoutine` — their use_on methods are also the target of
  `UseOnCommand` (selector 10, script-vm §2.3) with an object argument; the panpipes' 20-bit test value
  exceeds any 16-bit prop index, the lyre's 12-bit test could in principle match an object id whose low
  bits are 0xFC6 (how `&` treats an object value was not read) [MED for that alternative path].
- No other new body sends a signal: the only native `SendSignal` callers are the main-dump ones and
  `cbSendSignal` (`grep -B3 'bl 0x10053794' all.dis`, census §2 item 23). Signals 1, 34, 35, 130, 135 come
  from scripts only (1864, 10C1, 1417, 1025 — R5).

## 8. Selectors widgets send into scripts (subset of the N3 scan, script-library §9) [HIGH]

| sel | sender (new body) | receiver | arguments |
|---|---|---|---|
| 1 | `CloseRoutine__15TScriptedWindowFv` 10086380 | prop(window +0x10) | — (no shipped receiver → 3001) |
| 8 | `MouseRoutine__6TWListF5Point` 1008E8F8 | the row's object | — (single click; unused class) |
| 10 | `MouseRoutine__6TWListF5Point` 1008E930 | prop(container) | the row's object (double click; unused) |
| 10 | `MouseRoutine__10TWMusicBoxF5Point` 1008D538 | prop(+0x4C) | note history (28-bit int) |
| 23 | `CanDrop__8TWInventFsR5Point` 1008DBC4, `CanDrop__6TWListFsR5Point` 1008E680 | prop(container) | prop(dragged) → truthy = fits |
| −1 | TWText 10088C68, TWControl 1008AA1C, TWButton::Flash 1008AD30, TWPixButton 1008C30C, TWNumberEntry 1008CD3C | the f39 handler (code pointer) | f38, widget id |

## 9. Quirks found (code readings, none observed on screen)

1. `DispatchWindowMethod` selector 4 finds a widget by tag but always returns Nil (§1).
2. `Cancel/c/` and `Leave/l/` get no shortcut and show their slashes (§4.1).
3. Unbounded shortcut pairs (§4.1); unbounded/16-note music-box arrays (§7, `local_5c[16]`).
4. Base widgets ignore prop renumbering (§3).
5. Auto-map pan compares y with x (§5.8).
6. `TWList` cannot be saved (`Marshal` throws) and is never created by 1.0.4 scripts (§5.10).
7. Music-box notes > 15 are not masked into the 4-bit history (§7).

## 10. Open

- The 0x3E90 WDEF's use of the picture-window refCon bytes (ui-toolkit.md).
- When `RenumberProp` runs while a scripted window is open (level load / prop copy timing).
- `Scrolled__12TWScrollTextFv` and the scroll-text maximum formula (main dump, not read in full here).
