# Cythera 1.0.4 — the conversation and modal-input layer (native code)

⚑ wave 2 (2026-10-06) — new file. dialogue.md (659 lines) is full; this file carries the wave-2
reading of the conversation window and of the interaction "modes" (answer chips, MORE pause,
how-many slider, pick list, modal scripted window). It is cited by section number from
dialogue.md and never repeats it. Scripted windows and their widgets are in scripted-windows.md.

Register: **code reading only**. Labels: **HIGH** = whole body read, every callee named or plain
arithmetic; **MED** = an unnamed glue callee or an inferred meaning; **LOW** = from names only.

## 0. Provenance and method

- Bodies: `ghidra/Cythera_missing.decompiled.c` (840 blocks, census §1 groups E/F). My 71 group-E
  rows (68 + the 3 `TScriptPickItemDrawer` rows) were extracted with the banked finder, one regex of
  exact names built from `docs/cythera/tools/missing-addrs.txt`:
  `python3 ghidra/find_func.py "<name1 @|name2 @|…>" --file ghidra/Cythera_missing.decompiled.c --max 0`
  → 68 + 131 headers (E and F together = 199 rows = census 71 + 128). **All 71 E bodies were read
  whole** (most are 4–300 B; the large ones are listed in §3–§9).
- Context read from the main dump (not missing, cited only): `BeginTalking`/`EndTalking`,
  `__ct__12TInteractionFsss`, `CreateModal`, `__ct__9TPickMode…`, `__ct__12THowManyMode…`,
  `SetValue__12THowManyModeFs`, `Justify__12TTextContextFsss`, `PlaySound`, `mygetnum__13TStatusWindowFs`.
- Vtable slots (`FUN_100c50e8` = `__ptr_glue`, open-items §19): slot from `ppcdis.py` (`lwz r12,<s>(r12)`),
  target = data word → TVector → code, the dialogue.md §0 one-liner, then `tb.py --at`. TConversation
  vtable 0x100D5298 (dtor store `*param_1 = &PTR_PTR_100d5298;`), TSimpleInteraction 0x100D4F78
  (dtor store). Resolved this session:

| slot | TConversation (0x100D5298) | TSimpleInteraction (0x100D4F78) |
|---|---|---|
| +0x24 Close | `CloseRoutine__13TConversationFv` 1003B304 | `CloseRoutine__15TScriptedWindowFv` 10086340 |
| +0x28 / +0x2C / +0x3C / +0x40 | `TInteraction` Mouse 1003BF98 / Key 1003C200 / Cursor 1003C118 / Idle 1003C060 | same |
| +0x48 drag | `HandleDragWindow__12TInteractionF5Point` 1004259C (empty) | same |
| +0x6C / +0x70 | `Show__13TConversationFv` 1003B9F0 / `Hide__12TInteractionFv` 1003BBC4 | `Show__12TInteractionFv` 1003B5DC / Hide |
| +0xE4 / +0xF0 | `GetField__12TInteractionFs` 10042330 / `DispatchCommand__12TInteraction…` 1004247C | same |
| +0xF4 / +0xF8 | `IsJournalable__13TConversation` 1003C4E4 / `WriteJournal__13TConversation` 1003C628 | `TInteraction` stubs (return 0 / empty) |
| +0xFC / +0x100 | `GetInteractRect__13TConversation` 1003C858 / `GetWorkRect__13TConversation` 1003C944 | — |
| +0x104 / +0x10C | `ForceOut__13TConversationFv` 1003DFD4 / `ClearData__13TConversationFv` 1003C398 | `ForceOut__12TInteractionFv` 1003F878 (empty) |
| +0x114 / +0x118 / +0x11C | `mygets` 1003F314 / `mygetch` 1003F4DC / `mygetnum` 1003F650 | — |

  Command shape: `python3 -c "import sys;sys.path.insert(0,'docs/cythera/tools');import toc;vt,s=0x100d5298,0xe4;w=toc.data_u32(vt+s)[0];print(hex(0x10000000+toc.data_u32(toc.DB+w)[0]))"`
  then `python3 docs/cythera/tools/tb.py --at <addr>`. [HIGH]
- TOC strings by `python3 docs/cythera/tools/toc.py 100ce7ec 100ce7f0 100ce7f4 100ce7f8 100ce7fc 100ce7d8 100ce7dc 100ce7e0 100ce7e4 100ce7d4 100ce7c4 100ce7c0`:
  `\x02- ` (Pascal), `- `, `"`, `*MORE*`, `[Write To Journal]`, `0123456789`, `No`, `Yes`, `yn`, `None`,
  `\x02OK`, `\x06Cancel`. These are engine UI labels (constants), not game prose.
- Colour numbers passed to `ForeColor`/`DrawTextOutlined` are classic QuickDraw constants
  (0x21 = 33 black, 0x1E = 30 white, 0x45 = 69 yellow, 0xCD = 205 red, 0x199 = 409 blue). The numbers
  are HIGH; the colour names are MED (standard QuickDraw values, `DrawTextOutlined` not read).
- ⚑ corrected (review wave 2 2026-10-06) — review m9, the covered list by address (class :: method @ addr,
  length in bytes). Re-derived this session with the census §0 classifier with one `print(a,int(n,16),k,s)` per row (see app-shell.md §0 correction),
filtered by class `TConversation|TInteraction|TSimpleInteraction|TConvResponseMode|
  TPickMode|TScriptPickItemDrawer|THowManyMode|TConvMoreMode|TConvMode|TModalMode|TTextOut|TBark` → **71 rows /
  15,788 B** (= census). Every row was read whole (§0 above); rows not named elsewhere in this file are
  the 4–8 B stubs and dtors.
```
TBark:: dt @10061e74 84
TConvMode:: DrawRoutine @1003bf68 4 · MouseRoutine @1003c028 4 · IdleRoutine @1003c0e8 4
  CursorRoutine @1003c1c8 4 · KeyRoutine @1003c29c 4 · WantAutoKey @1003cb6c 8 · dt @1003cfd8 84
TConvMoreMode:: CursorRoutine @1003cbdc 140 · MouseRoutine @1003cce4 224 · KeyRoutine @1003ce34 76
  dt @10042670 100 · WantAutoKey @10042700 8
TConvResponseMode:: DrawRoutine @1003e17c 452 · MouseRoutine @1003e378 844
  IdleRoutine @1003e700 64 · CursorRoutine @1003e778 308 · KeyRoutine @1003e8ec 780
  dt @100425dc 100
TConversation:: dt @1003b1fc 220 · CloseRoutine @1003b304 228 · OffsetOrigin @1003b4a8 36
  Show @1003b9f0 424 · ClearData @1003c398 284 · IsJournalable @1003c4e4 268
  WriteJournal @1003c628 508 · GetInteractRect @1003c858 60 · GetWorkRect @1003c944 96
  myprintstr @1003d054 436 · ForceOut @1003dfd4 100 · mygets @1003f314 408 · mygetch @1003f4dc 324
  mygetnum @1003f650 160
THowManyMode:: dt @10041500 156 · DrawRoutine @100415c8 76 · MouseRoutine @10041644 664
  CursorRoutine @10041914 140 · KeyRoutine @10041a78 428
TInteraction:: Hide @1003bbc4 288 · NeedsRedraw @1003bd10 8 · DrawRoutine @1003bd48 496
  MouseRoutine @1003bf98 88 · IdleRoutine @1003c060 88 · CursorRoutine @1003c118 120
  KeyRoutine @1003c200 108 · EraseArea @1003c2cc 100 · ClearData @1003c364 4
  GetWorkRect @1003c8d0 60 · IsJournalable @1003cca4 8 · WriteJournal @1003cdfc 4
  ForceOut @1003f878 4 · GetField @10042330 284 · DispatchCommand @1004247c 64
  HandleDragWindow @1004259c 4
TModalMode:: dt @10041fec 124 · DrawRoutine @10042090 60 · MouseRoutine @100420fc 64
  CursorRoutine @10042174 64 · KeyRoutine @100421ec 56
TPickMode:: dt @1003faf0 172 · DrawRoutine @1003fd3c 660 · KeyRoutine @1003fffc 472
  MouseRoutine @10040200 1672
TScriptPickItemDrawer:: GetItemHeight @10096118 80 · DrawItem @100961a4 1460 · ct @10096cf0 48
TSimpleInteraction:: GetInteractRect @10041088 76 · dt @1004250c 96
TTextOut:: LDEFDraw @10039480 544 · LDEFHilite @100396d8 4 · dt @1003a238 100
```

## 1. Class shape

`TInteraction` derives from `TScriptedWindow` (its ctor: `___ct__15TScriptedWindowFss(param_1,0,(int)param_2);`
in `__ct__12TInteractionFsss @ 1003A8F8`, so the window's owner prop +0x10 is 0); `TConversation` and
`TSimpleInteraction` derive from `TInteraction` (dtors chain to `___dt__12TInteractionFv`).
A running input "mode" is a `TConvMode` subclass held at **interaction +0x3C**; mode +4 = its interaction.
Vtables (dtor stores): `TConvMode` 0x100D5130, `TConvMoreMode` 0x100D510C, `TConvResponseMode`
0x100D50D4, `TPickMode` 0x100D509C, `THowManyMode` 0x100D4E98, `TModalMode` 0x100D4E60. [HIGH]

**TInteraction as host** (bodies 1003BF98, 1003C060, 1003C118, 1003C200) [HIGH]: Mouse, Key, Cursor
and Idle go to the current mode when one runs, else to the scripted-window handler:
`if (*(int *)(param_1 + 0x3c) == 0) { .debug::_KeyRoutine__15TScriptedWindowFs(param_1,param_2); } else { FUN_100c50e8(*(undefined4 *)(param_1 + 0x3c),param_2); }`
(Mouse forwards only when a mode runs). `HandleDragWindow` is empty → an interaction panel cannot be
dragged; `NeedsRedraw` returns 0; `IsJournalable` 0, `WriteJournal`/`ForceOut`/`ClearData` empty.
`TConvMode`'s own Draw/Mouse/Idle/Cursor/Key are empty and `WantAutoKey__9TConvModeFv` returns 1;
`WantAutoKey__13TConvMoreModeFv` returns **0** (key auto-repeat does not reach the MORE pause). [HIGH
bodies; MED for the auto-repeat meaning of `WantAutoKey`]

**DrawRoutine__12TInteractionFv @ 1003BD48** [MED: two glue calls]: clears +0x12, clips to the
outside of the port rect, `MyCopyBitsBevel` from the GWorld at +0x40 (the saved background), then
`CopyBits` of the GWorld at +0x44 (the panel contents) onto the port, then the mode's draw
(`if (*(int *)(param_1 + 0x3c) != 0) { FUN_100c50e8(); }`, slot +0xC = `DrawRoutine` by the TConvMode
vtable, resolved as above). `EraseArea` copies a rect back from +0x44.
**Hide__12TInteractionFv @ 1003BBC4** [MED]: copies the +0x40 background back over the window
(`CopyBits(…)` with `LMSetPaintWhite(0)` around `Hide__7TWindowFv`), then
`*PTR_DAT_100cdd00 = 0; .debug::_DisableKeyboard__Fv();`. Builtin EA (`cbHideConversation`) calls
this slot (+0x70) and EB (`cbShowConversation`) calls +0x6C (script-builtins §4).

## 2. The conversation window's life

Opening and closing are in dialogue.md §1 and §11. The new bodies add: [HIGH unless marked]
- **Open.** `BeginTalking__13TStatusWindowFv @ 10035DC0` (main dump): `iVar1 = FUN_100be7c8(0xa54);`
  then `___ct__13TConversationFv(iVar1);` stored at status +0x34 — the object is 0xA54 bytes.
- **Show__13TConversationFv @ 1003B9F0**: `Show__12TInteractionFv`, zero both pane lengths
  (+0x452, +0x854), redraw both panes (`ShowTalking`, `ShowMessage`), then for up to **three speaker
  slots** (shorts at +0xA48, +0xA4A, +0xA4C) with an id > 0: `DrawPortrait(0x20, i*0x58 + 0xc, id, 0x24)`,
  `GetCharacterName(id, buf, 0)`, `FitText(buf, 0x54)`, centred name drawn outlined in colour 0x1E on
  0x21 (`DrawTextOutlined(…,0x1e,0x21)`). Speaker *i* sits 0x58 px below speaker *i−1* (the same
  0x58 pitch the talk pane uses, dialogue.md §2.3).
- **Geometry.** `GetInteractRect__13TConversationFR4Rect`: `.glue::SetRect(param_2,0x74,0xbc,0x200,0x114);`
  (left 116, top 188, right 512, bottom 276); `GetWorkRect__13TConversationFR4Rect` = the port rect
  with left forced to 0x68; `OffsetOrigin__13TConversationFRsRs` adds +0xA50/+0xA52 to a point (used
  by every scripted-widget constructor, scripted-windows.md §2.2).
- **ClearData__13TConversationFv @ 1003C398**: zero +0x50 and both pane lengths, redraw both panes,
  copy the work rect from the background GWorld. **CloseRoutine__13TConversationFv @ 1003B304**:
  free every scripted widget hosted in the conversation (`FreeScriptedWidget`, then widget vtable
  +0xC = dtor, by the TWidget vtable in scripted-windows.md §0), `FreeScriptedWindow`, `ValidRect` of
  the work rect, then +0x10C `ClearData` (slots by `ppcdis.py 1003b304 1003b3e8`: `lwz r12,256(r12)`,
  `lwz r12,268(r12)`). So closing a modal window that ran inside a conversation clears the panel and
  leaves the conversation open.
- **Close for good.** `EndTalking__13TStatusWindowFv` deletes the conversation (vtable dtor, status
  +0x34 := 0). `__dt__13TConversationFv @ 1003B1FC`: `ForceOut` (+0x104, `ppcdis.py 1003b1fc 1003b2d8`:
  `lwz r12,260(r12)`), then `ConvMore` (dialogue.md §2.4: returns at once when +0x4F is set), frees the
  100 chip strings (`for (sVar1 = 0; sVar1 < 100; …) if (param_1[sVar1 + 0x22e] != 0) FUN_100b2ccc(…)`
  — +0x8B8 = word 0x22E), `*_DAT_100cdcc8 = 0;` (no conversation), `___dt__12TInteractionFv`. [HIGH call
  order; MED that a final MORE pause shows only when text arrived since the last one]

**Field map of TConversation (0xA54 B)** [HIGH offsets from the bodies above + dialogue.md §2/§3]:
+0x38 skip-MORE flag · +0x3C running mode · +0x40 background GWorld · +0x44 panel GWorld · +0x4C in-quotes ·
+0x4D/+0x4E talk/message pane "shown" · +0x4F MORE-done · +0x52 talk text (≤ 0x3FF) · +0x452 its length ·
+0x454 message text · +0x854 its length · +0x858 / +0x860 journal-button rects (talk / message) ·
+0x8B8 100 chip pointers · +0xA48 three speaker ids · +0xA4E current speaker index · +0xA50/+0xA52 origin.

## 3. Text into the panes (confirmations of dialogue.md §2)

`myprintstr__13TConversationFPcs @ 1003D054` decompiles to exactly the wave-1 listing reading
(dialogue.md §2.3/§2.4): at `*` the flushed length is `param_2 + (-1 - (int)pcVar3)` (the byte before
`*` is dropped), at an opening `"` the run restarts **at** the quote (`pcVar3 = param_2;`), at a closing
`"` one TOC `"` byte is appended (`AppendConv(param_1,puVar1,1)`). `ForceOut__13TConversationFv @
1003DFD4` decompiles to the §3.1 reading. [HIGH — wave-1 claims confirmed, nothing changed]

**The status-pane log (no conversation).** `LDEFDraw__8TTextOutFUcP4Rect5Pointss @ 10039480` draws one
log line: `ForeColor(0x21)`; an `@` starts a hint word (the `@` itself is not drawn); the word ends at
the first byte that is not A–Z/a–z and is drawn in **colour 0x199** (`.glue::ForeColor(0x199);
.debug::_AADrawText__FPcss(pcVar3,0,(int)pcVar4 - (int)pcVar3); .glue::ForeColor(0x21);`). [HIGH]
⚑ A hint word that runs to the end of the line is drawn by the final flush (`if (pcVar3 < pcVar4)
AADrawText(…)`) while the colour is already 0x21, i.e. not highlighted. [HIGH code; not observed]
The trailing-blank trim tests `pcVar3[param_6]` (the byte at index *length*, one past the last).
[HIGH code] This narrows dialogue.md §15 item 3 for the log list: hint words are coloured there; the
conversation panes' `TTextContext` drawing was not read.

## 4. The MORE pause — `TConvMoreMode` (dialogue.md §2.4)

- `KeyRoutine__13TConvMoreModeFs @ 1003CE34`: `if (param_2 == 0x1b) { *(…)(*(int *)(param_1 + 4) + 0x38) = 1; }`
  then `Done`. [HIGH — confirms wave 1]
- `MouseRoutine__13TConvMoreModeF5Points @ 1003CCE4`: `r = IsJournalable(where)` (interaction +0xF4). r = 0:
  `AutoEye("*MORE*")`, `PlayIFSound(6)`, wait for the button to come up (`do { … StillDown(); } while …`),
  `Done`, `PlayIFSound(7)`. r ≠ 0: cursor 0x28, `AutoEye("[Write To Journal]")`, `WriteJournal(r)` (+0xF8);
  the pause stays. [HIGH; interface-sound ids 6/7 are numbers only — LOW for what they sound like]
- `CursorRoutine__13TConvMoreModeF5Points @ 1003CBDC`: cursor 0x20 + `*MORE*` over text, cursor 0x28 +
  `[Write To Journal]` over a journal button. [HIGH]

## 5. The journal buttons (closes dialogue.md §15 item 4 at the conversation side)

`IsJournalable__13TConversationF5Point @ 1003C4E4` [HIGH]: stores the point in `PTR_DAT_100ce800`;
returns **1** when the point is in a 24×24 box built from the rect at +0x858 and **2** for the rect at
+0x860, else 0: `_sStack_10 = CONCAT22(sStack_10,sStack_a); _sStack_c = CONCAT22(sStack_10 + 0x18,sStack_a + 0x18);`
where `sStack_10` = the stored rect's top and `sStack_a` = its right — the box's top-left corner is the
stored rect's top-right corner. [HIGH code; MED that +0x858/+0x860 are the pane rects]
`WriteJournal__13TConversationFs @ 1003C628` [HIGH; TJournal internals are R1's ui-play.md]: tracks the
mouse while down, redrawing the box with `DrawButton(&r, 0, pressed)` and icon 0x187 (`MaskSubIcon`);
released inside →
- **2 (message pane)**: NUL-terminate at +0x854 and `AddToJournal__8TJournalFPc(param_1 + 0x454)` —
  the narration text as shown;
- **1 (talk pane)**: NUL-terminate at +0x452 and `SaidToJournal__8TJournalFsPc(speaker, param_1 + 0x52)`
  with speaker = `*(short *)(param_1 + *(short *)(param_1 + 0xa4e) * 2 + 0xa48)` — the current speaker's
  character id and the spoken text.
The journal records whatever text the pane currently holds (≤ 0x3FF bytes), not the whole conversation.

## 6. Answer chips and typed lines — `TConvResponseMode` (dialogue.md §3.3, §6)

Fields (from the bodies; the ctor is `GetResponse`'s, dialogue.md §3.3) [HIGH]: +0xC `TEHandle` (0 = no
text field) · +0x10 its rect · +0x18 chip count · +0x1C chip strings · +0x20 chip rects (8 B each) ·
+0x24 choice string (0 = none) · +0x28 buffer · +0x2C buffer length · +0x30 → short result index.

**DrawRoutine @ 1003E17C** [HIGH]: each chip = `SetText(6)`, `"- "` at the chip's left, then the chip text
after `StringWidth("\x02- ")`, both `DrawTextOutlined(…, 0x45, 0x21)`; baseline = chip vertical centre +
half of app +0x30. Then, with a text field, `EraseRect` + `TEUpdate`. `IdleRoutine @ 1003E700` =
`TEIdle` when a field exists.
**CursorRoutine @ 1003E778** [HIGH]: over the field → cursor 0x2D; over a chip → 0x20; else the journal
test: 0x28 + `[Write To Journal]`, or 0x2B and `AutoEye(0)` (clears the hint line).

**MouseRoutine @ 1003E378** (844 B) [HIGH]:
1. Click inside the field rect with a field → `TEClick(where, modifiers & 0x200, te)` (shift extends
   the selection) and return — no sound.
2. Otherwise `PlayIFSound(6)`; find the first chip rect containing the point. Found → track while the
   button is down, redrawing `"- "` + text in **0xCD while inside, 0x45 while outside**
   (`if (bVar11) { uVar7 = 0xcd; } else { uVar7 = 0x45; }`). Released inside → `**(short **)(param_1 + 0x30) = sVar12;`,
   copy the chip text into the buffer when a buffer length is set (`FUN_100b6d08` = strcpy, dialogue.md
   §3.1), `Done`. Released outside → nothing (no journal test).
3. No chip hit → journal test (interaction +0xF4); journalable → cursor 0x28 + `WriteJournal`.
4. Always `PlayIFSound(7)`; **`PlayIFSound(0)` when nothing was hit** (the "reject" sound).

**KeyRoutine @ 1003E8EC** (780 B) [HIGH]: key −1 stays 0xFFFF; any other key is mapped through the
to-lower table at 0x100D8A86 (dialogue.md §6).
- Return (13) or Enter (3): **only with a text field** → `TEGetText`, `BlockMove(text, buffer, buflen)`,
  NUL at the TE length when shorter (`if (*(short *)(**(int **)(param_1 + 0xc) + 0x3c) < *(short *)(param_1 + 0x2c))`),
  `Done`. Without a field Return/Enter do nothing.
- Other keys pass when there is no choice string, or the key is in it (`FUN_100b6e38` = strchr), or it is
  Backspace (8) with a field; a key that does not pass → **`PlayIFSound(0)`** (the "beep" of wave 1 is
  interface sound 0, not `SysBeep`).
- Passing key, no field: when a choice string and chips exist, the first *i* < chip count with
  `key == choice[i]` is drawn in 0xCD, stored as the result, `Done`. (So a choice string longer than
  the chip list cannot select past the last chip.)
- Passing key, with a field: `TEKey` of the **raw** event character (`*(uint *)(*(int *)PTR_DAT_100cdb84 + 6) & 0xff`,
  not the lowered key) — typed case is kept in the field and lowered later by `GetResponse`.

## 7. `mygets` / `mygetch` / `mygetnum` (dialogue.md §3.2, §6)

`mygets` @ 1003F314 and `mygetch` @ 1003F4DC decompile to the wave-1 listing readings (100 slots,
skip 0 and −1, upper-case first letter in place, ≤ 20 collected backwards; `yn` → `Yes`/`No`; length
> 20 → `SysBeep(1)` + clamp; every per-character slot pointer = `auStack_90`). [HIGH — confirmed]
**`mygetnum__13TConversationFv @ 1003F650`** [HIGH]: `ForceOut`, then
`GetResponse(this, buf, "0123456789", 15, NULL, 0)` — a text field that accepts only digits and
Backspace (other keys → sound 0, §6) — then `buf[15] = 0` and a plain decimal fold
(`iVar2 = (int)*pcVar1 + iVar2 * 10 + -0x30;`), no overflow check.
Native callers (closes dialogue.md §15 item 8's second half): a scan for the slot over the whole code
section (`ppcdis.py 10000000 100cd280 > all.dis; grep -E 'lwz r12,(284|280|276)\(r12\)' all.dis`) finds
+0x11C only at `10035bb4` in **`mygetnum__13TStatusWindowFs @ 10035B88`**, which forwards to the
conversation when one exists (`else { iVar1 = FUN_100c50e8(); }`) and otherwise reads digits (or hex
when its argument is 0x10) from the status log. Its 8 callers (`grep 'bl 0x10035b88' all.dis`) are all
in `KeyRoutine__10TMapWindowFs @ 100437B8` (R1's ui-play.md). +0x118 (`mygetch`) is reached from
DoInterpAt 0x8F and `cbgetdigit`; +0x114 (`mygets`) from DoInterpAt 0x8E and 0x8F `*`. [HIGH]

## 8. How many — `THowManyMode` (dialogue.md §7.1; builtin B4 `cbhowmany`)

Fields (ctor `__ct__12THowManyModeFP12TInteractionRssss @ 100412C0`, main dump, + bodies) [HIGH]:
+0xC min · +0xE max · +0x10 step (`HowMany` passes 1: `___ct__12THowManyModeFP12TInteractionRssss(iVar3,*piVar2,local_28,(int)param_2,(int)param_3,1);`) ·
+0x14 → short value (starts at max) · +0x18 slider control (`NewControl(…, value, min, max, 0x3e91, …)`) ·
+0x20 **OK** button (`\x02OK`) · +0x24 **Cancel** button (`\x06Cancel`), both proc 16000.
`SetValue__12THowManyModeFs` writes the control value, its refCon, and the short; no clamping.
⚑ corrected (review wave 2 2026-10-06) — review N1(d): proc 0x3E91 = 16017 = CDEF 1001 × 16 + variant 1
= `TProgBarCDEF` (ui-toolkit.md §1 class map: horizontal track, 32×16 knob, the control's **refCon**
printed on the knob with `NumToString(contrlRfCon)`). So `SetValue` writing the refCon is what puts
the current number on the slider knob. [HIGH: procID arithmetic + both bodies as banked]
`DrawRoutine @ 100415C8` draws the three controls; `CursorRoutine @ 10041914` = cursor 0x2A or the journal
cursor/label (as §6).

**MouseRoutine @ 10041644** (664 B) [HIGH]: `PlayIFSound(6)` first, `PlayIFSound(7)` last, and
`PlayIFSound(0)` when nothing was hit.
- On the **slider**: custom tracking, no `TrackControl`. While the button is down, with `r` = slider rect
  and `p` the mouse: `p.v` more than 16 px above/below `r` → restore the value from mouse-down; else
  `p.h < r.left + 16` → **min**; `p.h < r.right − 16` → `min + (max − min)·(p.h − (r.left + 16)) / (r.right − r.left − 32)`;
  else **max**.
- **OK** tracked in → `Done` (value kept). **Cancel** tracked in → `**(undefined2 **)(param_1 + 0x14) = 0;`
  then `Done` — Cancel returns **0, not the minimum**.
- Elsewhere → the journal test as §6.

**KeyRoutine @ 10041A78** (428 B) [HIGH; key codes 0x1C–0x1F are the Mac arrow characters, 0x110/0x113 are
engine key codes whose source was not traced — MED]:
⚑ corrected (review wave 2 2026-10-06) — review N1(a): the source is traced. `TApp::TranslateKey @
1000d030` (p:3153–3166): `case 0x73: param_2 = 0x110;` … `case 0x77: param_2 = 0x113;` — Mac key
codes 0x73 / 0x77 = **Home / End** (ui-toolkit.md §3.1). So Home → min, End → max. [HIGH codes; key
names MED from the Mac virtual key table]

| key | effect |
|---|---|
| 0x1D (→) | value < max → value + step |
| 0x1C (←) | value > min → value − step |
| 0x1E (↑), 0x110, Backspace (8) | value := min |
| 0x1F (↓), 0x113 | value := max |
| Return (13), Enter (3) | `Done` |
| Esc (0x1B) | value := min, `Done` |
| '0'–'9' | new = value·10 + digit; **ignored unless new < max** (`if ((int)*(short *)(param_1 + 0xe) <= (int)sVar1 + **(short **)(param_1 + 0x14) * 10 + -0x30) return;`) |
| other | `PlayIFSound(0)` |

⚑ Because the value starts at **max**, the first digit typed always gives value·10 + d ≥ max and is
ignored; typing works only after Backspace/↑ (→ min), and a typed value can never equal max (the test
is `max <= new`). [HIGH code; not observed on screen]
Result to the script: `HowMany` returns the short (dialogue.md §7.1), so B4 yields the slider value,
min after Esc, **0 after Cancel**. [HIGH]

## 9. Pick an item — `TPickMode` + `TScriptPickItemDrawer` (dialogue.md §7.3; builtin C0 `cbPickItem`)

**What C0 builds** (`cbPickItem__FP5VAddr @ 10096798`, re-read for the drawer): prompt = `VAddrToPtr(a0)`
or NULL for Nil; format = `VAddrToPtr(a1)` or NULL; one static `TScriptPickItemDrawer` per item
(`*(… + sVar8 * 0xc + 4) = format; *(… + sVar8 * 0xc + 8) = row;`, items capped `sVar8 < 0x14`);
button strings from list a3 into a 10-slot local array **with no bound** (`auStack_74[10]`, loop to
`Len(a3)`) — more than 9 buttons would overrun it (no shipped call does). Result
`*param_1 = (int)sStack_88 & 0xfffffff;` (a negative button code becomes the 28-bit integer of the same
value). [HIGH]

**TPickMode fields** (ctor @ 1003F8AC + bodies) [HIGH]: +0xC → short result · +0x10 button count ·
+0x14 drawer vector · +0x18 button strings · +0x1C row height = max of the drawers' `GetItemHeight` ·
+0x20 prompt · +0x24 scroll bar (only when the rows do not fit: `if ((uint)(int)sVar2 < count)` →
`NewControl(…, max = count − visible, 0x3e90, …)`) · +0x28 first visible row.

**Layout** (`DrawRoutine @ 1003FD3C`) [HIGH]: list rows from y = 0x14, row pitch = height + 4, list right
edge −16 when the scroll bar exists, list bottom = work bottom − 0x20; prompt centred at y = half the
app +0x30 value + 10 in 0x45 on 0x21; **buttons along the bottom from the right**, each
`(workW − 24) / 5` wide (`iVar5 = ((int)uStack_24._2_2_ - (int)sStack_1e) + -0x18; iVar5 = iVar5 / 5 …`),
stepping left by width + 6; each title is shown with trailing `/x` pairs stripped (§9.1).

**MouseRoutine @ 10040200** (1672 B) [HIGH]:
- **Rows**: from row +0x28 down, a hit row's drawer is redrawn hilited (`FUN_100c50e8(*puVar10,&sStack_5c,1)`,
  the drawer's `DrawItem(rect, hilite)`), tracked; released inside → result = **row index** (top row +
  offset), `Done`.
- **Buttons**: tracked with `DrawButton(rect, title, state)`; released inside → result = **−(k+1)** for
  button *k* counted from the right (`**(short **)(param_1 + 0xc) = -(sVar3 + 1);`), `Done`.
- **Scroll bar** parts: 0x14 → −1 row, 0x15 → +1, 0x16 → −(visible−1), 0x17 → +(visible−1), auto-repeating
  while held; 0x81 (thumb) → proportional tracking (track length L = thumb-part height − 0x30, value =
  min + (L/2 + pos·(max − min))/L); each change
  sets +0x28 and calls `DrawTheList`.

**KeyRoutine @ 1003FFFC** [HIGH; disasm checked, `ppcdis.py 1003fffc 100401d4`]: A–Z → a–z; for each button
title copied to a Pascal string at sp+56 with length L: while `L > 2` and the byte before the last is `/`
(`10040194: 38610037 addi r3,r1,55` / `10040198: 7c0300ae lbzx r0,r3,r0` / `1004019c: 2c00002f cmpwi r0,47`),
compare the key with the **last** byte (`1004010c: 38610038 addi r3,r1,56` / `10040114: 7c0300ae lbzx r0,r3,r0`
/ `10040118: 7c040000 cmpw r4,r0`); equal → strip the `/x` pairs, `DrawButton(…, 4)`, result −(k+1), `Done`.
⚑ **Hang**: when the key differs, `1004011c: 40820068 bne 0x10040184` re-tests the *same* L
(`10040184`–`100401a0`) — nothing advances, so a key that does not match a `/x` button title loops forever.
Unreached in 1.0.4: the only script strings with a `/x` tail are scripted-window buttons in 100E, 300F
(scripted-windows.md §4.1), none is a pick_item button
(`grep -h -o '"[^"]*/[^"]*"' ghidra/cythera-scripts/*.txt | sort -u`). [HIGH code; reachability HIGH by the grep]
⚑ corrected (review wave 2 2026-10-06): reachability is **MED**, not HIGH — the grep sees string
literals only; a pick_item button list built at run time (e.g. `sysnew_03` concatenation) could carry a
`/x` tail without a literal. The code reading stays HIGH.

### 9.1 The row format language — `DrawItem__21TScriptPickItemDrawerFRC4RectUc @ 100961A4`

Drawer = {vtable, +4 format, +8 row value} (`__ct__21TScriptPickItemDrawerFv @ 10096CF0`: +8 := Nil).
`GetItemHeight @ 10096118`: 0x14, or **0x20 when the format contains `%i`**. DrawItem walks the format
with a text buffer and an x position (start: rect left + 2), colour 0xCD when hilited else 0x45, each
`%` code consuming the next element of the row (`At(row, k)`, k = 0, 1, …) [HIGH]:

| code | effect |
|---|---|
| `%d` | integer, `sprintf` "%d" (TOC 0x100CEE20, `toc.py 100cee20 100cee78` → `%d`, `%s`) |
| `%s` | string (`VAddrToPtr`), `sprintf` "%s" |
| `%i` | item icon: integer `item` → tile `(item >> 10) + table[item & 0x3FF]` (`PTR_DAT_100cdbf4`), 32×32 from the tile pixels (`*PTR_DAT_100cdc64 + tile * 0x400`), vertically centred; x += 0x24 |
| `%n` | the tile's name (`GetTileName(tile, buf, 1, 0)`) |
| `%p` and any other letter | consumes an element, draws nothing |
| `\|` | flush the buffered text at x with the current justification, x := pen position; then optional `.` (centre) or `-` (right), then optional decimal *p* → x = left + (p·width + 50)/100 |

Justification: `Justify__12TTextContextFsss` — 0 left, 1 centre (x − w/2), −1 right (x − w). [HIGH]
Shipped formats: `%s`, `%p%s` (0816 Where Is: the room element is skipped), `|%i|%s|-100%d ob|` and
`|%i|%s (%d)|-100%d ob|` (shops: icon, name, right-aligned price at 100 %), `|%i|(%s)|-100%d obsidian`
(`grep -h 'pick_item' ghidra/cythera-scripts/*.txt`). This closes the format half of dialogue.md §15
item 1. [HIGH]

## 10. Modal scripted windows — `TModalMode` and `GetField__12TInteractionFs`

`TModalMode` (`__ct__10TModalModeFP12TInteraction @ 10041F74`, main) forwards everything to the
scripted-window handlers of its interaction: `DrawRoutine @ 10042090` → `DrawIntoPort__15TScriptedWindow`,
`MouseRoutine @ 100420FC` → `MouseRoutine__15TScriptedWindowF5Points`, `CursorRoutine @ 10042174`,
`KeyRoutine @ 100421EC` likewise; its dtor makes one glue call on the interaction with a local rect
(unresolved slot). [HIGH forwarders; MED dtor]
**`GetField__12TInteractionFs @ 10042330`** [HIGH; one glue call before `Perform` unresolved → MED for it]:
field 0x37 → result cell (`PTR_DAT_100ce7bc`) := Nil, +0x38 := 0, new `TModalMode`, +0x3C := it,
`Perform__9TConvModeFv` (the modal loop, dialogue.md §13), delete it, +0x3C := 0, return the result cell;
any other field → `GetField__15TScriptedWindowFs` (always Nil).
**`DispatchCommand__12TInteractionFPQ215TScriptedWindow7TWidget @ 1004247C`**: `Done` the running mode and
`FindScriptedWidget(result cell, widget)` — the result is the clicked widget's object id. So reading
`window.f37` on a modal window waits for a widget with no handler to be pressed and returns that
widget (scripted-windows.md §4). [HIGH]

## 11. Other group-E bodies (one line each) [HIGH]

`__dt__8TTextOutFv` (→ `TListBox` dtor) · `LDEFHilite__8TTextOut` (empty) · `__dt__9TConvModeFv`,
`__dt__13TConvMoreModeFv`, `__dt__17TConvResponseModeFv` (vtable resets only) · `__dt__9TPickModeFv`
(two interaction glue calls, `DisposeControl` of the scroll bar) · `__dt__12THowManyModeFv` (dispose the 3
controls, `ValidRect`) · `__dt__10TModalModeFv` · `__dt__18TSimpleInteractionFv` ·
`GetInteractRect__18TSimpleInteractionFR4Rect` (`SetRect(r, 0, 0x14, w(+0x4C), h(+0x4E) + 0x14)`) ·
`GetWorkRect__12TInteractionFR4Rect` (glue) · `__dt__5TBarkFv` (vtable 0x100D5F80 only; barks:
dialogue.md §12).

## 12. What this settles (for dialogue.md §15 and the INDEX)

- §15 item 2 (TConvResponseMode Draw/Idle, THowManyMode input, TModalMode, TSimpleInteraction): **closed**
  (§6, §8, §10, §11).
- §15 item 4 (what the journal click records): **closed at the conversation side** (§5); TJournal storage
  is R1's.
- §15 item 1: the pick_item **format language closed** (§9.1); the Where-Is row fields stay with dialogue.md.
- §15 item 3: narrowed — log-list hint words are drawn in colour 0x199 (§3); `TTextContext` codes unread.
- §15 item 8: `mygetnum`'s native callers settled (§7); `CanTalk` part untouched.
- New quirks (not observed on screen): pick-button key hang (§9, unreachable), how-many digit entry
  (§8), Cancel → 0 (§8), trailing hint word not highlighted in the log (§3).
