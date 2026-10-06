# Deimos Rising 1.0.6 — Mac utility tail (files, PICT, alerts, dialogs), U_Manager registry

Wave 4, reader w4s4 (2026-10-04). Scope: the Mac utility span `0x10044930–0x10046510` (35
functions listed in brief-wave4 §w4s4; the inits `FUN_100448b0`/`FUN_10046680` are wave 3's
`static-init-audit.md`; already-rowed `FUN_100450e0`, `FUN_100461b0`, `FUN_100463b0`,
`FUN_10046470`, `FUN_10046580`, `FUN_100465e0` are not re-read except where noted), the
U_Manager span `0x1003a780–0x1003ade0` (9 listed functions + `FUN_1003a780`, re-read for an
upgrade), and the MotionBlur leftover `FUN_10046b70`. OUT: the log file `FUN_10049400` (w4s2),
the present path / `FUN_1000ce20` (w4s1), the path builders and directory walkers
`FUN_10048560`/`FUN_10048610`/`FUN_10048810` (read here only for the worked example; their rows
belong to whoever owns `0x10048xxx`).

Evidence: raw listing `$W/disasm-w4s4.txt` (DisasmRange over `10044900:100467c0`,
`1003a780:1003ade0`, `10046b70:10046ba0`) and `$W/w4s4-ext.txt` (DisasmFuncs over the callers
`FUN_1000ced0`, `FUN_10048330`, `FUN_10048810`, `FUN_10048560`, `FUN_100498e0`, `FUN_10009bd0`,
`FUN_10009f00`, `FUN_1000c470`, `FUN_1000a840`, `FUN_10026260`, `FUN_100263a0`, …). Strings
resolved with `python3 $W/w4s4-str.py <addr>` (reads `mem/100de330.bin`); app resources with
`python3 $W/w4s4-rsrc.py "<app>/..namedfork/rsrc" PICT:1000 STR#:131`. Glue names were checked
against the dump's `// ==== <Import> @ 100dxxxx ====` stub headers (e.g. `100d498c`
StandardAlert, `100d4794` FSMakeFSSpec, `100d48b4` PBGetCatInfoSync, `100d567c` PBHGetFInfoSync,
`100d552c` NewGWorld, `100d53f4` GetCWMgrPort). TOC r2 = `0x100e6330`.

Toolbox struct offsets below (CInfoPBRec, AlertStdAlertParamRec, TERec, GDevice, GrafPort) are
the Universal Interfaces layouts; where a claim depends on such a layout the label says so.

---

## 1. Alerts: `FUN_10045ab0`, `FUN_10045c60`, `FUN_10045ef0` — and INDEX #3

### 1.1 `FUN_10045ab0 @ 10045ab0 (title, message, fatal)` — one-button StandardAlert, always returns [HIGH]
Every instruction of the function was read (`10045ab0..10045c54`). Calls, in order:
`FUN_100462b0` (zero 256 bytes), `FUN_10057760` strlen, `FUN_10051c60` memcpy, the same three
again for the message, then **one** `bl 0x100d498c` (StandardAlert) at `10045c3c`. There is a
single exit, `10045c54 blr`, reached unconditionally after StandardAlert. No ExitToShell, no
branch on itemHit (the itemHit word at `r1+0x38` is never read). **The alert routine itself
never quits.**

| step | detail | listing |
|---|---|---|
| title → Pascal | len = min(strlen, 255), copied to `r1+0x155`, length byte at `r1+0x154` | `10045af0 cmplwi r29,0xff; ble; li r29,0xff`, `10045b10 stb r29,0x154(r1)` |
| message → Pascal | len = strlen **unclamped**; memcpy of the full length into a 256-byte buffer, length byte = low 8 bits | `10045b64..10045b90` (no `cmplwi …,0xff`) |
| `\n` → `\r` | loop runs `len−1` times from index 0 — **the last character is never converted** (both strings) | `10045b20 subi r0,r5,0x1; cmpwi r5,0x1; mtctr; ble`, `10045b34 cmpwi r0,0xa; stb r4(=0xd)` |
| param rec @ `r1+0x3c` | movable 0 (`+0`), helpButton 0 (`+1`), filterProc 0 (`+2`), defaultText (`+6`), cancelText 0 (`+0xa`), otherText 0 (`+0xe`), defaultButton 1 (`+0x12`), cancelButton 2 (`+0x14`), position `0xa80a` (`+0x16`) | `10045bd0 stb r3,0x3c`, `10045bd4 stw r3,0x3e`, `10045be0/10045bec stw r0,0x42`, `10045bfc stw r7,0x46`, `10045c08 stw r7,0x4a`, `10045c18 sth r6(1),0x4e`, `10045c1c sth r5(2),0x50`, `10045bf0 lis r3,0x1; subi r4,r3,0x57f6` → `0xa80a`, `10045c20 sth r4,0x52` |
| default button text | `fatal ≠ 0` → pool+0x48 = **"Quit"**; else pool+0x4d = **"OK"** (pool = `*(0x100df548)` = `0x100efe98`) | `10045abc lwz r30,-0x6de8(r2)`, `10045bdc addi r0,r30,0x48` / `10045be8 addi r0,r30,0x4d` |
| alert type | `fatal ≠ 0` → 0 (kAlertStopAlert); else 2 (kAlertCautionAlert) | `10045c14 li r3,0x0; 10045c24 bne; 10045c28 li r3,0x2` |

String pool `0x100efe98` (command: `python3 $W/w4s4-str.py` / raw dump): `"\nFILE ERROR: Could not load a
Mac PICT resource with id: %i"` (+0), Pascal `"Geneva"` (+0x3c), `"Save"` (+0x43), `"Quit"` (+0x48),
`"OK"` (+0x4d), `"Delete"` (+0x50). The cancel button is NULL, so the alert has exactly one
button. Position `0xa80a` = kWindowCenterParentWindow [MED — constant name from the SDK].

Callers (both traced):
- `FUN_1000ced0` (error alert) `1000cfa4 bl 0x10045ab0` with its own (title, msg, fatal). After
  the alert returns, `1000cfd4 rlwinm. r0,r28…; beq 0x1000cfe8` → only a **fatal** flag reaches
  `1000cfdc bl 0x10000630` (shutdown → ExitToShell, loose-ends-session.md §8.2). Before the alert,
  a fatal call frees the memory reserve (`1000cf0c bl 0x10046270`, §2.1), and the display is
  suspended if `FUN_1000b620(display)` (`1000cf54…1000cf84`), else `FUN_10049870`.
- `FUN_10048330` (Toolbox init) `10048454 bl 0x10045ab0` with `li r5,0x1`: QuickTime missing
  (`Gestalt('qtim')` ≠ noErr) → STR# 131 #1 "QuickTime Not Found" / #2 "QuickTime is needed to
  continue.  Please ensure that it is properly installed on your machine.  …" (resource fork
  read with `w4s4-rsrc.py`), Stop alert with "Quit", **then the caller** calls ExitToShell.

**Consequence for INDEX #3** [HIGH]: `FUN_10000fd0` → `FUN_1000ced0("Error", msg, 0)` shows a
Caution alert with a single "OK" button and returns; nothing in the alert path can quit. "Tag Index
Incomplete! Aborting." therefore does **not** abort: the game continues after OK.

### 1.2 `FUN_10045c60 @ 10045c60 (title, message, defaultText, cancelText)` — two-button question [HIGH]
Same Pascal conversion as §1.1 for four strings (only the title is clamped to 255; same last-char
`\n` quirk). Buffers: title `r1+0x354`, message `r1+0x254`, default `r1+0x154` (param 3, r29),
cancel `r1+0x54` (param 4, r31) (`10045d78..10045e14`). Param rec at `r1+0x3c`: defaultText =
`r1+0x154` (`10045e9c stw r4,0x42`), cancelText = `r1+0x54` (`10045ea4 stw r5,0x46`), otherText 0,
defaultButton 1, cancelButton 2, position `0xa80a`; `10045eb8 li r3,0x1` = **kAlertNoteAlert**;
`10045ecc bl 0x100d498c` StandardAlert; returns itemHit `10045ed4 lha r3,0x38(r1)`. One exit.

### 1.3 `FUN_10045ef0 @ 10045ef0 (title, msg, default, cancel)` → bool [HIGH]
`10045ef8 lwz r31,-0x7904(r2)` (display object `0x100dea2c`); if `FUN_1000b620(display)` (display
flag +8) → `FUN_1000c2a0(display)` (suspend; w4s1's) — **not** restored afterwards; then
`FUN_10045c60`; returns `itemHit == 1` (`10045f4c subfic r0,r0,0x1; cntlzw; rlwinm …,0x1b,5,31`).
Sole caller `FUN_100498e0` (a bare tail-forwarder, `100498ec bl 0x10045ef0`; its callers pass a 5th
argument `1` in r7 that neither function reads). Users: SCORES+Option "Erase High Scores"
(`FUN_100229a0`) and the web-link "Launch"/"Cancel" (`FUN_10025270`) — front-end.md §2.

---

## 2. Memory reserve and string/memory utilities

### 2.1 Emergency memory reserve [HIGH]
| function | role | evidence |
|---|---|---|
| `FUN_10046210 @ 10046210 (size)` | free any existing reserve (`FUN_10046270`), then `operator new(size)` (`FUN_1004d400` → `FUN_1004d320`) into `0x100e0278`; returns `ptr ≠ 0` | `10046224 lwz r0,-0x60b8(r2)`, `10046244 bl 0x1004d400`, `10046250 stw r3,-0x60b8(r2)`, `1004624c neg/or/rlwinm` |
| `FUN_10046270 @ 10046270` | if `0x100e0278` ≠ 0: `operator delete` (`FUN_1004d420`), clear | `1004627c..10046294` |

Only allocation: `FUN_10048330` `100483c8 lis r3,0x2; subi r3,r3,0x7000` → **0x19000 = 102 400
bytes**, `100483d0 bl 0x10046210`; failure → **ExitToShell with no alert** (dump). Released by
`FUN_1000ced0` before a *fatal* alert (`1000cf0c`) and by `FUN_10048480` at exit — i.e. a
"rainy-day" block freed so the fatal alert and shutdown have memory.

### 2.2 String and memory helpers
| function | role | label / evidence |
|---|---|---|
| `FUN_10044930 @ 10044930 (s)` | C string → Pascal **in place** (shift right by 1, `s[0] = strlen & 0xff`; no 255 clamp); null → no-op | HIGH: `10044938 or. r31,r3,r3; beq`, `10044a38 lbz r0,-0x1(r5); stb r0,0x0(r5)`, `10044a48 stb r3,0x0(r31)`; callers `FUN_10048610`, `FUN_10048810` |
| `FUN_10044a60 @ 10044a60 (p)` | Pascal → C string in place (shift left by 1, NUL at `[len]`); null → return | HIGH: `10044a64 beqlr`, `10044af8 lbz r0,0x1(r4); stb r0,0x0(r4)`, `10044b0c stbx r0,r3,r5`; callers `FUN_10048330` (STR# 131), `FUN_10048610`, `FUN_10048810`, `FUN_10049700` |
| `FUN_100462b0 @ 100462b0 (p, n)` | `memset(p, 0, n)` (`FUN_10051f40`) | HIGH: `100462bc li r4,0x0; bl 0x10051f40` |
| `FUN_100462e0 @ 100462e0 (s)` | strdup: `new(strlen+1)`, zero it, memcpy `strlen` bytes; null in or alloc fail → 0 | HIGH: `10046308 addi r31,r3,0x1`, `10046310 bl 0x1004d400`, `10046328 bl 0x10051f40`, `10046338 subi r5,r31,0x1; bl 0x10051c60`; callers U_Pak (`FUN_10003030`, `FUN_10003a40`, `FUN_10004050`, `FUN_100040c0`) |
| `FUN_10046380 @ 10046380 (p)` | free the strdup (`FUN_1004d420`) if non-null | HIGH: `10046384 cmplwi r3,0x0; beq`; same four callers |
| `FUN_10046410 @ 10046410 (s)` | **tolower** in place: ctype map `*(0x100dea48)` bit 0x80 (upper) → table `*(0x100dea68)`; byte 0xff kept | HIGH: `10046414 lwz r6,-0x78c8(r2)`, `10046418 lwz r5,-0x78e8(r2)`, `10046434 rlwinm. r0,r0,0,0x18,0x18` (0x80); image: map['A'] = 0xa0, map['a'] = 0x60, lower['A'] = 'a' (python over `100de330.bin`, map `0x100f0f94`, lower `0x100f1094`, upper `0x100f1194`); callers `FUN_10004050`, `FUN_100040c0` (suffix compare) |
| `FUN_10046510 @ 10046510 (dst, src, n)` | bounded copy: null dst/src or n < 1 → return 0; else `strncpy(dst, src, n)` (`FUN_100577a0`, NUL-padding) then `dst[n] = 0` (dst needs n+1 bytes); returns dst | HIGH: `1004652c..1004653c`, `10046548 bl 0x100577a0`, `10046554 stbx r0,r30,r31`; 23 callers (callers.txt) |

`FUN_100463b0` (already rowed MED "toupper") is the mirror of `FUN_10046410`: map bit 0x40
(`100463d4 rlwinm. r0,r0,0,0x19,0x19`) → upper table `-0x78c4(r2)` = `0x100dea6c` → `0x100f1194`
(upper['a'] = 'A'). Upgrade offered in the role rows [HIGH].

---

## 3. File system helpers (FSSpec, catalog info)

| function | role | label / evidence |
|---|---|---|
| `FUN_10044ce0 @ 10044ce0 (cpath, FSSpec* out)` → bool | empty path → false; copy ≤ 255 chars (`FUN_10046510(buf,path,0xff)`), C→Pascal inline, **`FSMakeFSSpec(vRefNum 0, dirID 0, path, out)`**; returns `err == noErr` (so fnfErr → false even though the spec is filled) | HIGH: `10044cf8 lbz; extsb.; beq`, `10044d10 bl 0x10046510`, `10044e40 stb r3,0x38(r1)`, `10044e4c li r3,0; li r4,0; bl 0x100d4794`, `10044e5c extsh; cntlzw; rlwinm …,0x1b` |
| `FUN_10044e80 @ 10044e80 (cpath, type, creator)` → OSErr | `FUN_10052360` (MSL path → FSSpec, [MED]) ; `FSpGetFInfo`; set `fdType`, `fdCreator`; `FSpSetFInfo`. Returns the first failing OSErr or SetFInfo's result (r3 passes through; the dump shows `void`) | HIGH: `10044ea0 bl 0x10052360; extsh.; bne exit`, `10044eb8 bl 0x100d4d1c`, `10044ec8 stw r30,0x38(r1)` / `10044ed4 stw r31,0x3c(r1)`, `10044ed8 bl 0x100d4d34`; caller `FUN_100484e0` logs pool+0x11 "ERROR: (%i) could not change file type for file '%s'" on non-zero |
| `FUN_10044f00 @ 10044f00 (FSSpec*)` → u32 | `PBHGetFInfoSync` with HFileParam at `r1+0x38`: ioNamePtr = spec+6, ioVRefNum = spec.vRefNum, ioFVersNum 0, ioFDirIndex 0, ioDirID = spec.parID; returns **ioFlMdDat** (modification date, PB+0x4c) or 0 on error | HIGH: `10044f10 addi r0,r3,0x6; stw r0,0x4a` (+0x12), `10044f24 sth r0,0x4e` (+0x16), `10044f28 stb r4,0x52`, `10044f34 stw r0,0x68` (+0x30), `10044f38 sth r4,0x54`, `10044f3c bl 0x100d567c`, `10044f4c lwz r31,0x84(r1)` (+0x4c); callers `FUN_100420f0` (Units Cache date), `FUN_1001b040` (Sprite Groups Cache date), `FUN_10048610` |
| `FUN_10044f70 @ 10044f70 (FSSpec*)` → u32 | copy the spec name, `PBGetCatInfoSync` (ioFDirIndex 0, ioDirID = parID, ioCompletion 0); if noErr **and** ioFlAttrib bit 0x10 (directory) → **ioDrMdDat** (PB+0x4c), else 0 | HIGH: `10044f9c bl 0x100d3a2c` (BlockMoveData len+1), `10044fa8 stw r0,0x8a` (+0x12), `10044fb8 sth r0,0x8e`, `10044fbc sth r4,0x94` (+0x1c), `10044fc4 stw r0,0xa8` (+0x30), `10044fc8 stw r4,0x84` (+0xc), `10044fcc bl 0x100d48b4`, `10044fdc lbz r0,0x96; rlwinm. …,0x1b,0x1b`, `10044fe8 lwz r31,0xc4(r1)` (+0x4c); caller `FUN_10048610` |

So the "find the file" step of the Units Cache reader (unit-def-struct.md §8) is `FSMakeFSSpec`
on the string built by `FUN_10048560(" Data", "Units Cache", buf, 1)` = `": Data:Units Cache"` —
a **partial path relative to the default directory** (vRefNum 0, dirID 0) [HIGH for the call;
MED that the default directory is the application folder at run time]. Its date is the file's
modification date [HIGH]. The music player `FUN_10047f90` uses `FUN_10044ce0` on the pak path
returned by `FUN_10002080` and hands the FSSpec + offset + length to `FUN_100cfe64` [HIGH for the
call, dump `FUN_10047f90` lines 26–37].

---

## 4. QuickDraw / screen helpers

| function | role | label / evidence |
|---|---|---|
| `FUN_10044b20 @ 10044b20 (port, Rect* out)` | copy `portRect` (port+0x10..+0x16) to a Rect | HIGH: `10044b20 lha r0,0x10(r3); sth r0,0x0(r4)` … `lha r0,0x16; sth 0x6`; caller `FUN_10009f00` (paint pixel buffer with an RGB colour: SetGWorld, RGBForeColor, this, PaintRect, ForeColor(33 = black)) `10009f88` |
| `FUN_10044b50 @ 10044b50 (port, int out[4])` | portRect widened to ints in order {top, left, bottom, right} | HIGH: `10044b58 lha r5,0x10; stw r5,0x0`, `lha r0,0x12; stw r0,0x4`, `lha r7,0x14; stw r7,0x8`, `lha r6,0x16; stw r6,0xc`; caller `FUN_1000c470` (DSp setup) `1000c848` |
| `FUN_10044b80 @ 10044b80 (Point pt, GDHandle* out)` | walk `GetDeviceList`/`GetNextDevice`; for each device with `TestDeviceAttribute(13 screenDevice)` and `(15 screenActive)` and `PtInRect(pt, &gdRect)` (GDevice+0x22) → `*out = dev`. No break: the **last** matching device wins; `*out` untouched if none | HIGH: `10044b9c bl 0x100d591c`, `10044bb4 li r4,0xd; bl 0x100d5934`, `10044bcc li r4,0xf`, `10044be0 lwz r4,0x0(r31); addi r4,r4,0x22; bl 0x100d3f9c`, `10044bfc stw r31,0x0(r30)`, `10044c04 bl 0x100d594c`; caller `FUN_1000a840` `1000a938` (window's top-left; falls back to GetMainDevice) |
| `FUN_10044c30 @ 10044c30 (short id)` | `GetPicture(id)`; null → log `"\nFILE ERROR: Could not load a Mac PICT resource with id: %i"`; else `HNoPurge`, rect = {0, 0, frame.bottom−frame.top, frame.right−frame.left} (picFrame moved to the port origin, native size), `DrawPicture` into the **current port**, `HPurge` (no ReleaseResource) | HIGH: `10044c48 bl 0x100d56ac`, `10044c58 lwz r3,-0x6de8(r2); bl 0x10049550`, `10044c80..10044ca8` (`lha 0x2/0x4/0x6/0x8`, `sth 0x38/0x3a = 0`, `0x3c = h`, `0x3e = w`), `10044cac bl 0x100d56dc`, `10044cb8 bl 0x100d56f4`; sole caller `FUN_100000e0` with **1000** after "Loading Developer Logo" (port = pixel buffer filled by `FUN_10009f00`). PICT 1000 = "Swoop Software Logo", 25 340 bytes, picFrame (0,0,480,640) (`w4s4-rsrc.py`) |
| `FUN_10045010 @ 10045010 (Rect* r, short depth, CTabHandle ct)` → GWorldPtr | need = `depth·(width+8)·height / 8` (signed); `MaxBlock() < need + 0x40000` → flags 4 (useTempMem) else 0; `NewGWorld(&gw, depth, r, ct, NULL, flags)`; returns gw, or 0 on any error | HIGH: `10045038..10045060` (`subf; addi r4,r4,0x8; mullw; mullw; srawi 3; addze`), `10045064 bl 0x100d4e0c`, `1004506c addis r0,r30,0x4; cmplw; bge; li r31,0x4`, `10045090 li r7,0x0`, `10045094 bl 0x100d552c`; caller `FUN_10009bd0` (M_PixelBuffer.cc) `10009c28 li r5,0x0` (ct = NULL). 640×480×16 ⇒ need 622 080 B; app heap if MaxBlock ≥ 884 224 B |
| `FUN_10045640 @ 10045640 (port)` | `SetGWorld(port, NULL)` | HIGH: `10045644 li r4,0x0; bl 0x100d492c`; caller `FUN_10010fc0` (dialog as port) |
| `FUN_10045f70 @ 10045f70` → bool | **"all graphics ports sane"** — not a screen base. screenBase = `GetPixBaseAddr((*GetCWMgrPort)->portPixMap)`; walks the low-memory **PortList** handle at `0x0D66` (word count, then port pointers at +2+4i). For each port: device word must be 0; if `portBits.rowBytes` bit 15 (CGrafPort): `portPixMap` handle and master pointer non-null, `HandleZone` ≠ 0, `MemError` = 0, `GetPixBaseAddr(portPixMap) ≤ screenBase`; else (old GrafPort): `baseAddr` ≠ 0 and ≤ screenBase, bounds top ≤ bottom, left ≤ right. Then portRect top ≤ bottom, left ≤ right; visRgn (+0x18) and clipRgn (+0x1c) handles non-null with master pointers, HandleZone ≠ 0, MemError = 0. Any failure → 0; all ports pass → 1 | HIGH: `10045f80 lwz r28,0xd66(0)`, `10045f88 bl 0x100d53f4`, `10045f94 lwz r3,0x2(r3); bl 0x100d540c`, `10045fb8 lha r0,0x0(r29); cmpwi; beq`, `10045fd0 lha r0,0x6(r29); rlwinm. …,0x10,0x10`, `10046044 cmplw r3,r31; ble`, `10046070 cmplw r0,r31; ble`, `10046080..100460a4`, `100460b0..100460d4`, `100460e0..1004617c`, `10046198 li r3,0x1`. Unsigned compares (`cmplw`) on addresses; `ble` = equality allowed. PortList-at-0xD66 identity [MED — Inside Macintosh low-memory map] |

`FUN_10045f70`'s only caller `FUN_1000ae20` (M_Display setup, right after registering "Display"):
0 → `FUN_1000ced0("System Level Error", "\nSorry but this application cannot continue safely.\n\nSome
other application or extension has created a system wide error (bad Graphics Port).\n\nPlease
restart your machine and try again.  If necessary, you may need to disable third party
extensions.", 1)` — fatal Stop alert "Quit", then shutdown [HIGH: dump lines 39–42; strings
`0x100e48f3`, `0x100e4906` (248 chars, so the unclamped copy of §1.1 does not overflow here)].
⚑ The wave-2 critic called it "direct screen base"; it returns a boolean.

---

## 5. Dialog and menu helpers (preferences dialog DLOG 190, menus)

All are thin glue wrappers; `dlg, item` are DialogPtr and DITL item number.

| function | role | label / evidence |
|---|---|---|
| `FUN_10045610 @ 10045610 (win)` | `ShowWindow(win)` | HIGH: `1004561c bl 0x100d3dbc`; caller `FUN_10010fc0` |
| `FUN_100457f0 @ 100457f0 (dlg, item, Handle* out)` | `GetDialogItem(dlg, item, &type, out, &rect)` | HIGH: `100457f4 or r6,r5,r5`, `10045808 bl 0x100d528c` |
| `FUN_10045670 @ 10045670 (dlg, item, bold)` | ControlFontStyleRec (0x18 bytes zeroed): flags 0xff (kControlUseAllMask) · font = `GetFNum("Geneva")` · size 9 · style/mode/just 0 · fore/back colour black; `SetControlFontStyle(item handle, &rec)`. The `bold` path stores font −3 (kControlFontSmallBoldSystemFont) and is then **overwritten** by the Geneva number (dead store); all callers pass 0 anyway | HIGH: `10045698 addi r3,r1,0x40; li r4,0x18; bl 0x100462b0`, `100456a4 li r3,0xff; sth r3,0x40`, `100456b4 li r0,-0x3; sth r0,0x42`, `100456bc lwz r3,-0x6de8(r2); addi r3,r3,0x3c; bl 0x100d5244`, `100456d4 li r0,0x9; sth r0,0x44`, `100456e4 sth r5,0x42`, `100456fc bl 0x100d52a4`; constant names MED (SDK). Caller `FUN_10010fc0` items 8, 9, 10, 17, 18, 19, 5, 6, 7 |
| `FUN_10045720 @ 10045720 (dlg, item)` → bool | `IsControlActive(item handle) ≠ 0` | HIGH: `1004573c bl 0x100d5394`, `10045748 neg; or; rlwinm 1,31,31` |
| `FUN_10045770 @ 10045770 (dlg, item)` | `ActivateControl` if the item handle ≠ 0 | HIGH: `1004578c cmplwi; beq`, `10045794 bl 0x100d537c`; callers `FUN_10010fc0`, `FUN_10011590` |
| `FUN_100457b0 @ 100457b0 (dlg, item)` | `GetDialogItemAsControl`; `DeactivateControl` if ≠ 0 (asymmetric with the activate helper, same effect) | HIGH: `100457c0 bl 0x100d52d4`, `100457d4 bl 0x100d52ec` |
| `FUN_10045820 @ 10045820 (dlg, item)` → value | `GetControlValue(item handle)`, 0 if no handle | HIGH: `10045838 bl 0x100d528c`, `10045844 cmplwi; beq; bl 0x100d435c` |
| `FUN_10045870 @ 10045870 (dlg, item, v)` | `SetControlValue(item handle, v)` (no null check) | HIGH: `10045890 bl 0x100d528c`, `100458a0 bl 0x100d3f54` |
| `FUN_100458c0 @ 100458c0 (dlg, font, size)` | `SetGWorld(dlg, NULL)`, `TextFont(font)`, `TextSize(size)`, `GetFontInfo(&fi)`; then pokes the dialog's TEHandle (`DialogRecord+0xa0`): txFont = 1, txSize = 9, lineHeight = ascent+descent+leading, fontAscent = ascent | HIGH for offsets/values: `100458e8 bl 0x100d492c`, `100458f4 bl 0x100d39cc`, `10045900 bl 0x100d39e4`, `1004590c bl 0x100d3d5c`, `10045914 lwz r3,0xa0(r29)`, `10045924 sth r4(1),0x4a`, `10045930 sth r0(9),0x50`, `10045938..10045950 sth r0,0x18`, `10045960 sth r0,0x1a`; field names MED (TERec/DialogRecord layout). Caller `FUN_10010fc0` (font, 9) |
| `FUN_10045980 @ 10045980 (dlg, item, cstr)` | Pascal copy (clamped 255); if the item handle ≠ 0: `SetDialogItemText`, `GetDialogItemAsControl`, `Draw1Control` | HIGH: `100459b0 cmplwi r3,0xff`, `100459e8 bl 0x100d528c`, `10045a00 bl 0x100d531c`, `10045a14 bl 0x100d52d4`, `10045a20 bl 0x100d5334`; caller `FUN_10011590` ("%i%%" slider labels) |
| `FUN_10045a50 @ 10045a50 (menu, item)` / `FUN_10045a80 @ 10045a80 (menu, item)` | `DisableItem` / `EnableItem` | HIGH: `10045a5c bl 0x100d3fcc` / `10045a8c bl 0x100d3fe4`; callers `FUN_100491d0` (MENU 2001 "Interface - Edit" items 0,1,3,4,5,6 disabled; item 0 = whole menu), `FUN_10049320` (MENU 128 item 1 toggled) |

---

## 6. U_Manager.cc — the module-name registry ("Manager God")

Globals: list `0x100e023c` (`r2−0x60f4`), initialised flag `0x100e0240` (`r2−0x60f0`); string
base `r31 = r2+0x6890 = 0x100ecbc0` ("sPriv_ListPtr", +0xe "U_Manager.cc", +0x1b "Manager God",
+0x27 "Manager God termination Not Required (Not Initialised)", +0x5e "Manager Init:  %s", +0x70
"ERROR:  Manager already initialised.  Manager Name:  \"%s\"", +0xaa "Manager Termination:  %s",
+0xc3 "Manager Not Terminated (Was Not Registered):  %s", +0xf4 "newManagerNamePtr") — command
`python3 $W/w4s4-str.py 100ecbc0 100ecbce …`.

Record (0x88 bytes, `FUN_1003ab30`) [HIGH]:
| off | type | meaning | evidence |
|---|---|---|---|
| +0x00 | u32 | magic 0x499602d2 (1 234 567 890, same as tag records) | `1003ab80 lis r3,0x4996; addi 0x2d2; stw r0,0x0(r30)` |
| +0x04 | char[128] | module name (≤ 0x7f chars + NUL, `FUN_10046510`) | `1003ab90 addi r3,r30,0x4; li r5,0x7f` |
| +0x84 | u8 | the `log` flag passed at registration; **never read** in this span | `1003aba0 stb r29,0x84(r30)` |

| function | role | evidence |
|---|---|---|
| `FUN_1003a780` | init: flag = 1; `FUN_1003a990` (free a previous list); `new(0xc)` + list ctor `FUN_10000890`; null → assert `FUN_10000e70("sPriv_ListPtr","U_Manager.cc",63)`; register "Manager God" with log | HIGH: `1003a794 li r0,0x1; stb r0,-0x60f0(r2)`, `1003a7a0 bl 0x1003a990`, `1003a7a4 li r3,0xc; bl 0x1004d320`, `1003a7b8 bl 0x10000890`, `1003a7c4 stw r30,-0x60f4(r2)`, `1003a7d4 li r5,0x3f`, `1003a7e0 addi r3,r31,0x1b; li r4,0x1; bl 0x1003a870`; caller `FUN_100000e0` |
| `FUN_1003a810` | terminate: flag set → `FUN_1003a900("Manager God",1)`, `FUN_1003a990`, flag = 0; else log +0x27 | HIGH: `1003a820 lbz r0,-0x60f0(r2)`, `1003a82c..1003a844`, `1003a84c addi r3,r3,0x27; bl 0x10049550`; caller `FUN_10000630` (shutdown) |
| `FUN_1003a870 (name, log)` | **register**: not yet registered (`FUN_1003aa70`) → add record (`FUN_1003ab30`), log "Manager Init:  %s" if `log`; already registered → log the ERROR line (non-fatal, nothing else happens) | HIGH: `1003a894 bl 0x1003aa70; rlwinm.; bne`, `1003a8a8 bl 0x1003ab30`, `1003a8b8 addi r3,r31,0x5e`, `1003a8cc addi r3,r31,0x70`; 28 callers (every module init) |
| `FUN_1003a900 (name, log)` | **unregister**: registered → remove (`FUN_1003abe0`), log "Manager Termination:  %s" if `log`; else (if `log`) "Manager Not Terminated (Was Not Registered):  %s" | HIGH: `1003a924..1003a964`; 28 callers (every module teardown) |
| `FUN_1003a990` | free all: if flag and list: count n, then n × {advance cursor (`FUN_10000e10`), unlink (`FUN_10000c00`), free the record (`FUN_1004d3b0`)}; destroy list `FUN_100008b0(list,1)`; list = 0 | HIGH: `1003a9a8..1003aa44`; cursor seed = the 8-byte template at `*(0x100df498)` (`1003a9d0 lwz r4,-0x6e98(r2)`) |
| `FUN_1003aa70 (name)` → bool | linear search: `strcmp(record+4, name) == 0` → 1 | HIGH: `1003aad8 lwz r3,0x3c(r1); addi r4…; addi r3,r3,0x4; bl 0x10057820; cmpwi; bne` |
| `FUN_1003ab30 (name, log)` | allocate + fill the record (table above); null → assert "newManagerNamePtr" line 0xf6; append (`FUN_100009e0`) | HIGH: `1003ab50 li r3,0x88; bl 0x1004d320`, `1003ab74 li r5,0xf6`, `1003abac bl 0x100009e0` |
| `FUN_1003abe0 (name)` | find by strcmp, unlink and free the first match, stop | HIGH: `1003ac54 bl 0x10057820`, `1003ac70 bl 0x10000c00`, `1003ac7c bl 0x1004d3b0`, `1003ac84 b exit` |

**What U_Manager is** [HIGH]: a name-only bookkeeping list. It holds no handlers, no update
callbacks and no init order; nothing in the game reads it except these functions. Its only
effects are log lines and the "already initialised" guard text (which does **not** stop the
caller's own init from running again — the caller proceeds regardless, `FUN_1003a870` returns
void). It is unrelated to the console's registration gate (`FUN_1002d080`'s debugOnly flag,
messages-notices-console.md §5.2). Replica: can be dropped entirely.

---

## 7. Weapon-handler constructor / destructor (`~after U_Manager`, G_WeaponHandler.cc span)

| function | role | evidence |
|---|---|---|
| `FUN_1003acc0 @ 1003acc0 (h)` → h | ctor of the handler embedded at **player+0x240**: crosshair game object at h+0x8c (`FUN_100125d0`); h+0x120 crosshair shown = 0, h+0x121 locked = 0, h+0x122 player index = 0xff; h+0x70 aux list = 0; h+0x11 air state = 0, h+0x14 = 0, h+0x2c held = 0; h+0x31 ground state = 0, h+0x34 = 0, h+0x4c held = 0 | HIGH: `1003acd0 addi r31,r30,0x8c; bl 0x100125d0`, `1003acec stb r4,0x94(r31)`, `1003acf8 stb r4,0x95(r31)`, `1003acfc stb r0(−1),0x96(r31)`, `1003ad00 stw r4,0x70(r30)`, `1003ad04..1003ad18`; caller `FUN_10026260` `10026288 addi r3,r3,0x240; bl 0x1003acc0`. Field names per weapons-projectiles.md §2.2 |
| `FUN_1003ad40 @ 1003ad40 (h, short del)` → h | dtor: if h: aux list → `FUN_1003cb30` (free records), `FUN_100008b0(list,1)`, h+0x70 = 0; crosshair object dtor `FUN_10012610(h+0x8c, 0)`; `del > 0` → free h (MW C++ dtor pattern) | HIGH: `1003ad60..1003ad88`, `1003ad9c bl 0x10012610`, `1003ada4 extsh. r0,r31; ble; bl 0x1004d3b0`; caller `FUN_100263a0` `100263c0 addi r3,r30,0x240; li r4,-0x1` (embedded: never freed) |

Not U_Manager: the inventory's "~after U_Manager" bracket ends at `1003ab30`; these two belong to
the G_WeaponHandler.cc span that `FUN_1003ade0` opens [MED for the module, by content].

---

## 8. MotionBlur leftover `FUN_10046b70` — NUMBLURS readout [HIGH]

`10046b7c lwz r3,-0x60ac(r2)` (blur list `0x100e0284`), `bl 0x10000ce0` (count), `blr` with the
count still in r3 → returns the number of live motion blurs (the dump's `void` is wrong).
It has no direct caller but has a TVector: data word `0x100e0a18` = {`0x10046b70`, TOC
`0x100e6330`}, referenced only by TOC slot `0x100dea70` (python scan of all three memory images
for the word `0x10046b70`, then for `0x100e0a18`). The only code loading that slot is
`0x10047130 lwz r6,-0x78c0(r2)` (raw scan of `10000000.bin` for `lwz rX,-0x78c0(r2)`), inside the
undefined code at `0x10047120` = the NUMBLURS console handler (TV `0x100e0a20`, registered by
`FUN_100466e0` `1004673c bl 0x1002d080` with r7 = 1): it posts `FUN_1002dbd0("Num Motion Blurs:  "
(pool `0x100efef0`+0x134), type 2, upper 0, readout = TV of `FUN_10046b70`)` and returns 1
(hand-decoded words `0x10047120..0x10047158`; `bl` target `0x1002dbd0` from `0x4bfe6a91`).
Because the registration has debugOnly = 1, NUMBLURS is never added in 1.0.6
(messages-notices-console.md §5.2): **`FUN_10046b70` is unreachable** in the shipped build.

---

## Worked example — finding ` Data:Paks` and its paks (FSSpec calls in order)

Inputs: the app folder `Deimos Rising/` contains ` Data/Paks/` = {`.DS_Store`, `Audio.pak`,
`Game.pak`, `Interface.pak`, `Music.pak`} (`ls -la "$G/ Data/Paks/"`).

1. `FUN_100016c0` → `FUN_10048560(" Data:Paks", 0, dir, 1)`: leading-colon form, no file →
   `sprintf("%s%s%s", ":", " Data:Paks", ":")` = **`": Data:Paks:"`** (pool `*(0x100df59c)` =
   `0x100f03e4`: +0x46 "%s%s%s", +0x4d ":", +0x4f "%s%s%s%s", +0x58 "%s%s"; listing `10048564 lwz
   r9,-0x6d94(r2)`, `10048588 addi r5,r9,0x4d`, `10048590 addi r4,r9,0x46`) [HIGH].
2. For i = 1, 2, … `FUN_10048810(dir, i, name)` (listing in `$W/w4s4-ext.txt`) [HIGH]:
   a. `strcpy` the path into a 256-byte buffer, `FUN_10044930` → Pascal `"\x0c: Data:Paks:"`
      (`100488c8`, `100488d4`).
   b. `GetCurrentProcess(&psn)` (`100488e0`), `GetProcessInformation(&psn, &info)` with
      processInfoLength 0x3c, processName NULL, processAppSpec → FSSpec at `r1+0x128`
      (`100488f0..10048910`). This anchors on the **application's own folder** (spec.parID),
      not on the default directory.
   c. Copy the Pascal path over the spec's name (`10048934 bl BlockMoveData` → `r1+0x12e`).
   d. `PBGetCatInfoSync` #1: ioNamePtr = that path, ioVRefNum = app vRefNum, ioFDirIndex = 0,
      ioDirID = app parID (`10048944..1004895c`) → the folder ` Data:Paks`; its ioDrDirID comes
      back at PB+0x30.
   e. `PBGetCatInfoSync` #2: same PB, ioFDirIndex = **i**, ioDirID = the Paks folder's dirID
      (`1004896c..1004898c`) → the i-th catalog entry; fnfErr past the end → return 0, loop ends.
   f. noErr → return 1; if ioFlAttrib bit 0x10 is clear (a file), Pascal name → C → `strcpy(name)`
      (`100489ac..100489d0`). For a **sub-folder the name buffer is left unchanged** (`100489b8
      bne 0x100489e4`), so the caller re-processes the previous name — a latent double-index
      quirk (no sub-folders ship) [HIGH for the branch; consequence MED].
3. Catalog order (HFS+, case-insensitive) [MED]: i = 1 `.DS_Store` (no `.zip`/`.pak` suffix,
   `strcmp` with ".DS_Store" = 0 → skipped silently), 2 `Audio.pak`, 3 `Game.pak`,
   4 `Interface.pak`, 5 `Music.pak`, 6 → fnfErr → end.
4. Each pak: `FUN_10048560(" Data:Paks", "Game.pak", path, 1)` → `"%s%s%s%s"` =
   **`": Data:Paks:Game.pak"`**, opened by `FUN_10049de0` (MSL fopen path, which resolves through
   `FUN_10052360` relative to the **default directory**) [MED for the open's anchor].
5. Later, music: `FUN_10047f90` gets the stored pak path from `FUN_10002080` and calls
   `FUN_10044ce0(path, &spec)` → `FSMakeFSSpec(0, 0, "\x14: Data:Paks:Music.pak", &spec)` (§3);
   noErr → stream from (spec, offset, length) [HIGH for the call sequence].

Replica rule distilled: every data path is `<app folder>/ Data/...` (note the leading space in
` Data`); paks are visited in the folder's catalog order; non-pak files are skipped (logged unless
`.DS_Store`).

---

## NOT RESOLVED (this file)
1. Whether the default directory (vRefNum 0 / dirID 0, used by `FUN_10044ce0` and the MSL open)
   always equals the application folder (`processAppSpec.parID`, used by the directory walkers),
   e.g. when launched from an alias or under OS X. Settle: run under Mac OS 9 / Classic with an
   alias launch, or read MSL's `FUN_10052360` → `FUN_100524f0` default-directory logic.
2. `FUN_10045f70` under Mac OS X: reading the low-memory PortList at `0x0D66` from a CFM app — if
   the page reads as zero, the loop count is 0 and the check passes vacuously. Settle: run the
   OS X build with a breakpoint at `10045f80`. Replica-neutral.
3. `0xa80a` (kWindowCenterParentWindow), the ControlFontStyleRec / TERec / CInfoPBRec field
   names, and AlertType numbers are taken from Universal Interfaces layouts, not from this binary
   (the offsets and values themselves are listing-checked).
4. ~~`FUN_1000c2a0` / `FUN_1000b620` (display suspend/flag used around both alerts) — w4s1's scope;
   whether `FUN_10045ef0` leaving the display suspended matters is decided by its callers'
   resume (`FUN_10023e10`, front-end.md).~~ → ⚑ corrected (review wave 3, 2026-10-06) #S: display-window-present.md §4 table (`FUN_1000b620` = is-initialised `lbz r3,0x8(r3)`; `FUN_1000c2a0` = make the window current) and §7 (suspend/resume), HIGH (critic wave 3 §3).

## Role-table rows (for merge)
| `FUN_10044930` | — (Mac utility span) | C string → Pascal in place (no 255 clamp) | HIGH | listing `10044938..10044a48`; callers `FUN_10048610`, `FUN_10048810` (file-pict-alerts-manager.md §2.2) |
| `FUN_10044a60` | — (Mac utility span) | Pascal → C string in place | HIGH | listing `10044a60..10044b0c`; callers `FUN_10048330`, `FUN_10048610`, `FUN_10048810`, `FUN_10049700` (§2.2) |
| `FUN_10044b20` / `FUN_10044b50` | — (Mac utility span) | copy portRect (+0x10) to a Rect / to int[4] {top,left,bottom,right} | HIGH | listing; callers `FUN_10009f00` `10009f88`, `FUN_1000c470` `1000c848` (§4) |
| `FUN_10044b80` | — (Mac utility span) | find the active screen GDevice whose gdRect contains a point (last match wins) | HIGH | listing `10044b9c..10044c04`; caller `FUN_1000a840` (§4) |
| `FUN_10044c30` | — (Mac utility span) | draw PICT resource id at native size at (0,0) of the current port; missing → log "FILE ERROR: Could not load a Mac PICT…"; boot uses id 1000 "Swoop Software Logo" 640×480 | HIGH | listing `10044c48..10044cb8`; caller `FUN_100000e0` (§4) |
| `FUN_10044ce0` | — (Mac utility span) | C path → FSSpec via FSMakeFSSpec(0,0,…); true iff noErr | HIGH | listing `10044cf8..10044e64`; callers `FUN_100420f0`, `FUN_1001b040`, `FUN_10047f90` (§3) |
| `FUN_10044e80` | — (Mac utility span) | set a file's type/creator (path→FSSpec, FSpGetFInfo, FSpSetFInfo); returns OSErr | HIGH | listing `10044ea0..10044ed8`; caller `FUN_100484e0` (§3) |
| `FUN_10044f00` | — (Mac utility span) | file modification date (PBHGetFInfoSync ioFlMdDat) or 0 | HIGH | listing `10044f10..10044f4c`; callers `FUN_100420f0`, `FUN_1001b040`, `FUN_10048610` (§3) |
| `FUN_10044f70` | — (Mac utility span) | folder modification date (PBGetCatInfoSync, dir bit 0x10 → ioDrMdDat) or 0 | HIGH | listing `10044f8c..10044fe8`; caller `FUN_10048610` (§3) |
| `FUN_10045010` | — (Mac utility span) | NewGWorld(depth, rect, ctab, no device); useTempMem when MaxBlock < depth·(w+8)·h/8 + 256 KB | HIGH | listing `10045038..10045094`; caller `FUN_10009bd0` (§4) |
| `FUN_10045610` / `FUN_10045640` | — (Mac utility span) | ShowWindow / SetGWorld(port, NULL) | HIGH | listing; caller `FUN_10010fc0` (§4–5) — ⚑ corrected (review wave 3, 2026-10-06) #L: label audit, address cited — `1004561c bl 0x100d3dbc` (ShowWindow), `10045644 li r4,0x0; 10045650 bl 0x100d492c` (SetGWorld) |
| `FUN_10045670` | — (Mac utility span) | dialog item font = Geneva 9 plain via SetControlFontStyle (bold arg is a dead store) | HIGH | listing `10045698..100456fc`; caller `FUN_10010fc0` (§5) |
| `FUN_10045720` / `FUN_10045770` / `FUN_100457b0` | — (Mac utility span) | dialog item IsControlActive / ActivateControl / DeactivateControl | HIGH | listing; callers `FUN_10010fc0`, `FUN_10011590` (§5) — ⚑ corrected (review wave 3, 2026-10-06) #L: label audit, address cited — `1004573c bl 0x100d5394`, `10045794 bl 0x100d537c`, `100457c0 bl 0x100d52d4; 100457d4 bl 0x100d52ec` |
| `FUN_100457f0` / `FUN_10045820` / `FUN_10045870` | — (Mac utility span) | GetDialogItem handle / GetControlValue / SetControlValue | HIGH | listing; caller `FUN_10010fc0` (§5) — ⚑ corrected (review wave 3, 2026-10-06) #L: label audit, address cited — `10045808 bl 0x100d528c`, `1004584c bl 0x100d435c`, `100458a0 bl 0x100d3f54` |
| `FUN_100458c0` | — (Mac utility span) | set dialog port font/size and poke its TEHandle (font 1, size 9, line height, ascent) | HIGH | listing `100458e8..10045960`; caller `FUN_10010fc0` (§5) |
| `FUN_10045980` | — (Mac utility span) | set dialog item text (≤255) and redraw the control | HIGH | listing `100459a8..10045a20`; caller `FUN_10011590` (§5) |
| `FUN_10045a50` / `FUN_10045a80` | — (Mac utility span) | DisableItem / EnableItem | HIGH | listing; callers `FUN_100491d0`, `FUN_10049320` (§5) — ⚑ corrected (review wave 3, 2026-10-06) #L: label audit, address cited — `10045a5c bl 0x100d3fcc` / `10045a8c bl 0x100d3fe4` |
| `FUN_10045ab0` | — (Mac utility span) | one-button StandardAlert(title, msg): fatal → Stop "Quit", else Caution "OK"; centred on parent; **always returns** (never quits) | HIGH | listing `10045ab0..10045c54` (single exit); callers `FUN_1000ced0` `1000cfa4`, `FUN_10048330` `10048454` (§1.1) |
| `FUN_10045c60` | — (Mac utility span) | two-button Note StandardAlert(title, msg, default, cancel) → itemHit | HIGH | listing `10045c60..10045ee8`; caller `FUN_10045ef0` (§1.2) |
| `FUN_10045ef0` | — (Mac utility span) | suspend fullscreen display if active, ask `FUN_10045c60`, return itemHit == 1 | HIGH | listing `10045ef0..10045f68`; caller `FUN_100498e0` (§1.3) |
| `FUN_10045f70` | — (Mac utility span) | validate every port in the low-mem PortList (device 0, pixmap/baseAddr ≤ screen base, sane bounds/portRect, valid vis/clip rgns) → bool; caller shows fatal "bad Graphics Port" alert on 0 | HIGH | listing `10045f80..10046198`; caller `FUN_1000ae20` (§4) |
| `FUN_10046210` / `FUN_10046270` | — (Mac utility span) | allocate / free the 100 KB emergency memory reserve `0x100e0278` | HIGH | listing; `FUN_10048330` `100483c8` size 0x19000, frees in `FUN_1000ced0` (fatal) and `FUN_10048480` (§2.1) |
| `FUN_100462b0` / `FUN_100462e0` / `FUN_10046380` | — (Mac utility span) | memset 0 / strdup (operator new) / free it | HIGH | listing `100462b0..100463a8` (§2.2) |
| `FUN_10046410` | — (Mac utility span) | string tolower in place (MSL ctype map bit 0x80) | HIGH | listing `10046410..10046464` + table bytes (§2.2) |
| `FUN_10046510` | — (Mac utility span) | bounded copy: strncpy(dst,src,n) + dst[n]=0; null/n<1 → 0 | HIGH | listing `10046510..10046570` (§2.2) |
| ⚑ corrected `FUN_100463b0` | — (Mac utility span) | string toupper in place (ctype map bit 0x40 → upper table 0x100f1194) | HIGH | listing `100463b0..10046404` + table bytes (§2.2); was MED "string toupper (ctype table)" |
| ⚑ corrected `FUN_1003a780` | U_Manager.cc | registry init: flag, new name list, register "Manager God" | HIGH | listing `1003a794..1003a7e8` (§6); was MED "manager init ("Manager God")" |
| `FUN_1003a810` | U_Manager.cc | registry teardown ("Manager God" unregister, free list) | HIGH | listing `1003a820..1003a854`; caller `FUN_10000630` (§6) |
| `FUN_1003a870` / `FUN_1003a900` | U_Manager.cc | register / unregister a module name (log only; duplicate init = log, no guard) | HIGH | listing `1003a870..1003a984`; every module init/teardown (§6) |
| `FUN_1003a990` | U_Manager.cc | free every record and the list | HIGH | listing `1003a9a8..1003aa44` (§6) |
| `FUN_1003aa70` / `FUN_1003ab30` / `FUN_1003abe0` | U_Manager.cc | find by name / add 0x88-byte record {magic, name[128], log} / remove by name | HIGH | listing (§6) — ⚑ corrected (review wave 3, 2026-10-06) #L: label audit, address cited — `1003aad8 … bl 0x10057820` (strcmp), `1003ab50 li r3,0x88; bl 0x1004d320`, `1003abac bl 0x100009e0`, `1003ac54 bl 0x10057820; 1003ac70 bl 0x10000c00` (file-pict-alerts-manager.md §6 table) |
| `FUN_1003acc0` / `FUN_1003ad40` | G_WeaponHandler.cc (span) | weapon-handler ctor / dtor (embedded at player+0x240) | HIGH | listing `1003acc0..1003ad30`, `1003ad40..1003add0`; callers `FUN_10026260` `1002628c`, `FUN_100263a0` `100263c8` (§7) |
| ⚑ corrected `FUN_10046b70` | G_MotionBlur.cpp | NUMBLURS readout: return live blur count (TV `0x100e0a18`, used only by the debug-only NUMBLURS handler at undefined `0x10047120`; unreachable in 1.0.6) | HIGH | listing `10046b7c..10046b94`; TOC `0x100dea70` loaded at `0x10047130` (§8); was LOW "blur count (NUMBLURS callback?)" |

## INDEX updates (for merge)
- **#3 (Tag Index Incomplete threshold)** narrowed further → §1.1: the alert routine
  `FUN_10045ab0` has one exit and never quits; a non-fatal `FUN_1000ced0` shows a one-button
  Caution alert ("OK") and returns, so "Tag Index Incomplete! Aborting." continues [HIGH]. The
  threshold `_DAT_100e00ec` stays open.
- **loose-ends-session.md NR 2** closed → §1.1 (same evidence); pak-format.md §2.3 item 4's
  "(unless the alert routine itself quits, MED)" can drop the caveat.
- unit-def-struct.md §8 "`FUN_100461b0` (not read)", "finds the file (`FUN_10044ce0`)": the file
  lookup is FSMakeFSSpec on `": Data:Units Cache"` and the date is the file's modification date
  (§3) [HIGH].
- Wave-2 critic family labels corrected: `FUN_10045ab0` is not a "PICT alert" (the PICT routine is
  `FUN_10044c30`), `FUN_10045f70` is not "direct screen base" (port-list validator).
- New fact for whoever owns `0x10048xxx`: `FUN_10048810` leaves the name buffer unchanged for a
  sub-folder entry (worked example step 2f).
