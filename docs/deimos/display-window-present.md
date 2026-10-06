# Deimos Rising 1.0.6: pixel buffers, window, display setup, presents and memory helpers (wave 4, w4s1)

Scope: code range `0x10009ac0–0x1000d010`, the M_PixelBuffer.cc, M_Window.cc, M_Display.cc and
M_Memory.cc modules. That is all 60 functions on the wave-4 census list (§10 has one row each),
plus the orphan block at `0x1000ad50`. To get the bank's existing rows to HIGH, I also re-read
these neighbours by listing: `FUN_100099c0`, `FUN_10009ac0`, `FUN_10009fd0`, `FUN_1000a480`,
`FUN_1000a4a0`, `FUN_1000a530`, `FUN_1000ad90`, `FUN_1000ae20` (display setup; hud-scorebar.md
§1 already has its rect arithmetic), `FUN_1000bc60`, `FUN_1000beb0`, `FUN_1000cb60`,
`FUN_1000cd60` and `FUN_1000cd90`. For cross-checks only, I also read listings of
`FUN_10045010` (NewGWorld wrapper) and `FUN_100450e0` (interlaced CopyBits). Both belong to
w4s4's range. I also read the G_Background console handler at `0x100107a0` and the
update-event case of the event pump at `0x10048fd4`.

OUT of scope: `FUN_1000ca10` (static initialiser, wave 3), the fades `FUN_1000b9a0`/`FUN_1000ba70`
(already HIGH; I read them only for their calls), `FUN_1000ced0` (alert), `FUN_10045f70`
(w4s4) and the G_Text range from `0x1000d010` on.

Evidence: the raw listing `$W/disasm-w4s1.txt` (DisasmRange `10009390:1000d0a0`) and
`$W/w4s1-annot.txt`. The annotated copy puts the import name on every `bl` into the glue range,
using a map built from the glue stubs `0x100d2000–0x100d6800` (`$W/w4s1-glue.txt`, 445 named
imports, the same count as the distinct `.glue::` names in the dump). The other evidence files:
`$W/w4s1-extra.txt` (`FUN_10045010`, `FUN_100450e0`), `$W/w4s1-bg.txt` and `$W/w4s1-evt.txt`
(other ranges). The scan scripts are `$W/w4s1-stbscan.py`, `w4s1-wscan.py`,
`w4s1-callsites.py`, `w4s1-allcalls.py`, `w4s1-tv.py` and `w4s1-strs.py`. TOC r2 is `0x100e6330`.
All strings come from the data image.

## 1. The pixel buffer object (M_PixelBuffer.cc, 0x30 bytes)

**Construction.** `FUN_100099c0` zeroes the object (`FUN_10009a20`) and then calls `FUN_10009bd0`.
I read `FUN_10009bd0`'s listing from `10009bd0` to `10009cf8`.

| off | type | meaning | written at | evidence |
|---|---|---|---|---|
| +0x00 | GWorldPtr | the offscreen GWorld; 0 = invalid | `10009c34 stw r3,0x0(r26)` (from `FUN_10045010`) | [HIGH] |
| +0x04 | BitMap* | `GWorld + 2` (`&port->portBits`, the CopyBits idiom) | `10009c98 addi r0,r4,0x2; 10009c9c stw r0,0x4(r26)` | [HIGH] |
| +0x08 / +0x0c | int | width / height | `10009ca0 stw r27,0x8` / `10009ca4 stw r28,0xc` | [HIGH] |
| +0x10 | int | depth (bits) | `10009ca8 stw r29,0x10` | [HIGH] |
| +0x14 | Ptr | pixel base (`GetPixBaseAddr`) | `10009cb4 stw r3,0x14` | [HIGH] |
| +0x18 | long | rowBytes (`GetPixRowBytes`) | `10009cc4 stw r3,0x18` | [HIGH] |
| +0x1c..+0x28 | 4 × int | bounds rect, Mac order: top 0, left 0, bottom = height, right = width | `10009cd8 stw 0,0x1c; 10009cd4 stw 0,0x20; 10009ce0 stw r4(h),0x24; 10009cdc stw r3(w),0x28` | [HIGH] |
| +0x2c | int | interlace field parity: starts at 0, toggled by `FUN_100450e0` | `10009ce4 stw r0,0x2c`; `1000a168 addi r7,r29,0x2c` | [HIGH] |

**Creation sequence** [HIGH, listing `10009bf8…10009cbc`]:
1. Dispose the old buffer (`FUN_10009d00`).
2. `SetRect(r, 0, 0, w, h)`.
3. `FUN_10045010(&r, depth, 0, flag)`: `NewGWorld(&gw, depth, &r, cTable = NULL, aGDevice = NULL,
   flags)`. The flags are 4 (`useTempMem`) when `MaxBlock() < depth·(w+8)·h/8 + 0x40000`, and 0
   otherwise. The 4th argument is never read: r6 is overwritten at `10045038`. Listing:
   `1004505c srawi…; 1004506c addis r0,r30,0x4; 10045070 cmplw; 10045078 li r31,0x4;
   10045090 li r7,0x0; 10045094 bl NewGWorld`.
4. On a null GWorld: fatal memory assert `FUN_10000e70("fBuffer", "M_PixelBuffer.cc", 0xae)`.
   This quits via `FUN_1000ced0(…,1)` (loose-ends-session.md §8.2).
5. `GetGWorldPixMap`, `LockPixels` (pixels stay locked for the buffer's lifetime; there is no
   UnlockPixels anywhere in the module), `SetGWorld(gw, NULL)`, `EraseRect(&gw->portRect)`
   (`+0x10`), then the field stores above.

All buffers use the global `ReqDisplayDepth` (F56 = 16). There is no colour table.

| function | role | label / evidence |
|---|---|---|
| `FUN_10009bd0 @ 10009bd0` | create GWorld w×h×depth, as above | HIGH, listing |
| `FUN_10009d00 @ 10009d00` | if +0 ≠ 0: `DisposeGWorld`, then zero all 12 words | HIGH, `10009d20 bl DisposeGWorld; 10009d28…10009d58 stw 0` |
| `FUN_10009d70 @ 10009d70` | resize: if (w,h,depth) differs from +8/+0xc/+0x10, dispose and recreate with flag 0. Called at game end with the terrain buffer `D+0x6c` and 640×480×16 (`FUN_100051a0`) | HIGH, `10009d9c…10009db8 cmpw` ×3; `10009e18 li r7,0; bl 0x10009bd0` |
| `FUN_10009e40 @ 10009e40` | make current: `SetGWorld(+0, NULL)`; if invalid, log "DEBUG: Setting to a non valid Pixel Buffer." and nothing else | HIGH, `10009e5c bl SetGWorld` |
| `FUN_10009e90 @ 10009e90` | make current and `EraseRect(portRect)` (port background colour; white unless changed). Callers: the sprite manager `FUN_10018d20`, console ERASEBACK `0x10010460` | HIGH, `10009eb4 SetGWorld; 10009ee0 EraseRect` |
| `FUN_10009f00 @ 10009f00` | fill with an RGB colour: make current, `RGBForeColor({a>>16, a&0xffff, b>>16})`, `PaintRect(portRect)` (`FUN_10044b20` copies the GWorld portRect), then `ForeColor(blackColor = 33)` | HIGH, `10009f78 RGBForeColor; 10009f94 PaintRect; 10009f9c li r3,0x21; 10009fa0 ForeColor` |
| `FUN_1000a450 @ 1000a450` | getter: width, height, depth, base, rowBytes (+8…+0x18) | HIGH, listing `1000a450…1000a478` |
| `FUN_1000a480 @ 1000a480` | getter: width, height | HIGH, `1000a480 lwz 0x8; 1000a488 lwz 0xc` |
| `FUN_1000a4a0 @ 1000a4a0` | getter: base, rowBytes (+0x14/+0x18); if invalid, logs "DEBUG: Pixel Buffer invalid. Width/Height/Depth" but still returns the (zero) fields | HIGH, `1000a4ec lwz 0x14; 1000a4f4 lwz 0x18` |
| `FUN_1000a520 @ 1000a520` | getter: depth (+0x10) | HIGH, `1000a520 lwz r3,0x10(r3)` |
| `FUN_1000a530 @ 1000a530` | copy the bounds rect +0x1c..+0x28 | HIGH, listing |
| `FUN_1000a560 @ 1000a560` | address of the bounds rect (`this+0x1c`) | HIGH, `1000a560 addi r3,r3,0x1c` |
| `FUN_1000a570 @ 1000a570` | return the GWorldPtr; logs "DEBUG: Returned Mac Buffer invalid." if 0 | HIGH, listing |
| `FUN_10009ac0 @ 10009ac0` | clone: new 0x30 object, same w/h/depth, then `FUN_10009fd0(src, new, NULL, NULL, 0)` (contents copied). The new-fails assert is "clonePtr", line 0x94 | HIGH, `10009b5c bl 0x10009bd0; 10009ba0 bl 0x10009fd0` with `r5=r6=r7=0` |

The bank already has `FUN_10009a20` (zero), `FUN_10009a60` (deleting destructor; w4s5's list)
and `FUN_100099c0`.

## 2. Copies between pixel buffers

### 2.1 `FUN_10009fd0(src, dst, srcRect*, dstRect*, interlaced)` [HIGH, listing `10009fd0…1000a184`]
1. `SetGWorld(dst)`.
2. srcRect = `*srcRect`, or the **src** bounds if NULL (`1000a02c or r3,r29,r29; bl 0x1000a530`).
3. dstRect = `*dstRect`, or **also the src bounds** if NULL (`1000a0a0 or r3,r29,r29`). The
   dst's own bounds are never consulted.
4. If `interlaced == 0`: **two identical** `CopyBits(src+4, dst+4, &srcR, &dstR, srcCopy (0),
   maskRgn NULL)` (`1000a12c`, `1000a14c`; both have r7 = r8 = 0 and the same rects). The second
   copy is pure redundancy: same pixels, double cost. This settles timing-frame.md NR 4 and the
   "double CopyBits" part of INDEX O14.
5. Otherwise: one `FUN_100450e0(src+4, dst+4, &srcR, &dstR, &src->+0x2c)`.

Interlaced callers: a raw scan of all 59 `bl 0x10009fd0` sites (`w4s1-callsites.py 10009fd0 7`)
finds r7 = `li 0` everywhere except `100101f8` in `FUN_10010120`, the background blit, whose r7
comes from a call (pref 5, timing-frame.md §5), and `1000a434` in `FUN_1000a3b0`, which passes
its own 4th argument (0 at its only caller, `FUN_100000e0`). [HIGH]

**Cross-check of `FUN_100450e0`** (w4s4's range; the bank row is MED) [HIGH for the call shape,
MED for the row arithmetic]:
- It copies both BitMaps/PixMaps to locals. A PixMap handle is detected by
  `rowBytes & 0xc000 == 0xc000`.
- It keeps the two flag bits and doubles rowBytes: `10045588 rlwinm r8,r0,0x0,0x10,0x11;
  10045590 rlwimi r8,r0,0x1,0x12,0x1e`.
- It halves the rects and bounds (`srawi …,0x1`). When the parity word is odd, it starts one row
  later (`10045424 add r5,r5,r7`, base += rowBytes).
- It makes one `CopyBits(…, srcCopy, NULL)` (`100455c8 li r7,0x0; 100455e0 bl CopyBits`), then
  sets `*parity ^= 1` (`100455e8…100455f4`).

That confirms timing-frame.md §5's reading: every other row, alternating per call.

⚑ as built (Deimos Phase 1 render fix pass b59b751, 2026-10-06; Fable spot review): the row arithmetic
above is incomplete. Step 1 first subtracts 2 rows from the bounds and the base
(`100453ac…10045410`), then pads/trims for parity and, when the rect top is odd, steps the base
back one row (−rowBytes), before the `srawi` halving (`100454f8…100455dc`). Net effect: the halved
bounds are [−1, 239) for a 480-row buffer, so the **last field row of each field (478 even / 479
odd) is clipped** — an interlaced blit never writes it. `DeimosRender`'s `CopyBits` transcribes
this. [HIGH — listing, verified by the fix pass and its review]

### 2.2 `FUN_1000a3b0(src, dst, srcRect*, interlaced)`: copy centred [HIGH, listing `1000a3b0…1000a444`]
w = srcRect.right − srcRect.left and h = bottom − top. The destination rect is centred in the
dst bounds:
- left = (dst+0x28 − w)/2 and top = (dst+0x24 − h)/2. This is signed /2 rounding toward zero:
  `1000a3dc rlwinm r0,r6,0x1,0x1f,0x1f; add; srawi r0,r0,0x1`.
- right = left + w and bottom = top + h.

It then tail-calls `FUN_10009fd0(src, dst, srcRect, &centred, interlaced)`. The only caller is
`FUN_100000e0`, which uses it to centre the publisher logo `pucr`/`TGA ` in the back buffer.
(The decompile showed a bare thunk because it dropped the arithmetic.)

### 2.3 `FUN_1000a190(src, dst, percent, srcRect*, dstRect*)`: blended copy [HIGH, listing `1000a190…1000a3a0`]
1. Clamp percent to 0..100 (`1000a1b4 bge; 1000a1c0 cmpwi r31,0x64`).
2. `SetGWorld(dst)`, then the rect defaults as in §2.1 (both NULL → the src bounds).
3. `GetPenState`.
4. weight = `(int)(float)(65535.0 · (float)(percent / 100.0f))`. The constants are double 65535.0
   at `0x100d6378` (TOC `-0x7354`) and float 100.0 at `0x100d6374` (TOC `-0x7358`), from the
   code image. Listing: `1000a31c fdivs; 1000a320 fmul; 1000a324 frsp; 1000a328 fctiwz`.
5. `OpColor({w,w,w})`, then `CopyBits(src+4, dst+4, &sR, &dR, blend (0x20), NULL)`
   (`1000a358 li r7,0x20`).
6. `OpColor({0,0,0})`, then `SetPenState`.

**Reachability:** the only `bl` (`10010818`) sits in the undefined G_Background console handler at
`0x100107a0` (TVector `0x100e08a0`), which is console **MEDIA**: blend the media mask buffer
(`*(r2−0x61f8)`) over the terrain buffer `D+0x6c` at percent = PermFloat 153. MEDIA is a debugOnly
command, never registered in 1.0.6 (messages-notices-console.md §5.2), so **`FUN_1000a190` is
unreachable**. callers.txt had no caller for it because the site is in code Ghidra did not define.
[HIGH for the site, MED for "unreachable" (rests on §5.2)]

## 3. The window object (M_Window.cc, 0x18 bytes, `D+4`)

| off | type | meaning | evidence |
|---|---|---|---|
| +0x00 | WindowPtr | the Mac window | `1000a6c8`/`1000a6f8 stw r3,0x0(r28)` |
| +0x04 | PixMapPtr | `*(gdPMap)` of the screen under the window's content origin (set only by `FUN_1000a840`) | `1000a960 lwz r3,0x16(r3); lwz r0,0x0(r3); 1000a968 stw r0,0x4(r31)` |
| +0x08 | BitMap* | `WindowPtr + 2` (set only by `FUN_1000a840`) | `1000a8b4 addi r0,r3,0x2; stw r0,0x8` |
| +0x0c | byte | created | `1000a780 stb r0(1),0xc` |
| +0x0d | byte | windowed (procID choice and collapse handling) | `1000a6fc stb r30,0xd` |
| +0x0e | byte | "in game" mark (`FUN_1000abd0`) | `1000a704 stb 0,0xe`; `1000abd0 stb r4,0xe(r3)` |
| +0x10 / +0x14 | int | content-region bbox left / top in global coords (`contRgn` = `WindowPeek+0x76`, `**rgn` +4 / +2) | `1000a8c8 lha r4,0x2; 1000a8cc lha r0,0x4; 1000a8d0 stw r0,0x10; 1000a8d4 stw r4,0x14` |

No reader of +0x04, +0x08, +0x0e, +0x10 or +0x14 turned up. I did a decompile grep for
`*(D+4)+…` reads in the game range (none found) but no raw-listing scan. [MED: they look
like leftovers of a direct-to-screen path that 1.0.6 never uses]

**`FUN_1000a640(win, rect*, windowed)`: create** [HIGH, listing `1000a640…1000a7c4`]
1. `SetRect` from the int rect.
2. `NewCWindow(NULL, &r, "\pDeimos Rising", visible 1, procID, behind −1, goAway 0, refCon 0)`.
   procID is **2 (`plainDBox`)** when not windowed (`1000a6e0 li r7,0x2`) and 4 (`noGrowDocProc`)
   when windowed (`1000a6b0 li r7,0x4`). The title is the Pascal string at `0x100e4624`.
3. Store +0xd = windowed and +0xe = 0. A null window is a fatal memory assert ("fMacWindow",
   "M_Window.cc", 0x53).
4. `SetGWorld(window)`, then `RectRgn(window->visRgn (+0x18), &r)`. This forces the visible
   region to the whole rect, menu-bar area included.
5. `InvalRect(&r)`, `PaintRect(&r)` (in the port's default black pen), `TextFont(3)` (Geneva),
   `TextSize(9)`.
6. +0xc = 1. Log "    Window created (%ix%i)" with width = r[3]−r[1] and height = r[2]−r[0].

| function | role | label / evidence |
|---|---|---|
| `FUN_1000a5c0 @ 1000a5c0` | constructor: +0xc = 0, +0/+4/+8 = 0 | HIGH, listing `1000a5c0…1000a5d4` |
| `FUN_1000a5e0 @ 1000a5e0` | deleting destructor: `FUN_1000a7d0`, +0xc = 0, `operator delete` if flag > 0 | HIGH, `1000a600 bl 0x1000a7d0; 1000a61c bl 0x1004d3b0` |
| `FUN_1000a7d0 @ 1000a7d0` | dispose: if created and non-null, make current then `DisposeWindow`, +0 = 0; +0xc = 0 | HIGH, `1000a810 bl DisposeWindow` |
| `FUN_1000a840 @ 1000a840` | refresh origin: +0x10/+0x14 = 0. If created: when windowed **and** `IsWindowCollapsed`, `CollapseWindow(w, false)` (expand) and wait 5 ticks (`FUN_10049820(5)`, a TickCount busy-wait). Then +8 = w+2, +0x10/+0x14 = contRgn left/top. The global content rect is portRect (`FUN_1000ab20`) offset by (left, top). `FUN_10044b80(topLeft, &gd)` picks the active screen device containing it, falling back to `GetMainDevice`; +4 = that device's PixMapPtr | HIGH, listing `1000a840…1000a97c` (`1000a884 IsWindowCollapsed; 1000a89c CollapseWindow; 1000a8a4 li r3,0x5`) |
| `FUN_1000a980 @ 1000a980` | make current: if created, `SetGWorld(window, NULL)`; logs "DEBUG: window was invalid on SetTo()" | HIGH, `1000a9a8 SetGWorld` |
| `FUN_1000a9e0 @ 1000a9e0` | `HideWindow` | HIGH, `1000a9f8` |
| `FUN_1000aa30 @ 1000aa30` | `ShowWindow` | HIGH, `1000aa48` |
| `FUN_1000aa80 @ 1000aa80` | is in front: `FrontWindow() == +0` | HIGH, `1000aab8` |
| `FUN_1000aaf0 @ 1000aaf0` | `BringToFront` if non-null | HIGH, `1000ab08` |
| `FUN_1000ab20 @ 1000ab20` | portRect (`WindowPtr+0x10..+0x16`) → int rect (top, left, bottom, right) | HIGH, `1000ab2c…1000ab38 lha 0x10…0x16` |
| `FUN_1000ab50 @ 1000ab50` | make current, then `PaintRect(portRect)` in the current pen (black) | HIGH, `1000ab88 SetGWorld; 1000abac PaintRect` |
| `FUN_1000abd0 @ 1000abd0` | +0xe = arg | HIGH, `stb r4,0xe(r3)` |
| `FUN_1000abe0 @ 1000abe0` | `IsWindowCollapsed(+0) != 0` | HIGH, `1000abf0`, `neg/or/rlwinm` idiom |
| `FUN_1000ac20 @ 1000ac20` | **the one blit to the screen**, see §5.1 | HIGH |

## 4. The display object `D` (M_Display.cc, bss `0x100f7bf8`, TOC slot `-0x7904` = `0x100dea2c`)

Layout. I add the flag bytes and buffers to the hud-scorebar.md §1 rect table; rect fields are
4 × int in Mac order (top, left, bottom, right).

| off | type | meaning | writers | evidence |
|---|---|---|---|---|
| +0x00 | DSpContextReference | from `DSpFindBestContext(&attr, D)` | `FUN_1000c470`; `FUN_1000c8d0` (= 0) | `1000c704 or r4,r31,r31; 1000c728 bl DSpFindBestContext`; `1000c9b4` [HIGH] |
| +0x04 | window object* | 0x18-byte object | `FUN_1000ae20` `1000b02c`; `FUN_1000b530` | [HIGH] |
| +0x08 | byte | initialised | `FUN_1000ae20` end (1); `FUN_1000b530` (0) | [HIGH] |
| +0x09 | byte | shutdown attempted | `FUN_1000b530` `1000b584` | [HIGH] |
| +0x0c..+0x18 | rect | **display rect**: F52×F53 (640×480) centred in the window. +0x10 = (right − 640)/2, +0xc = (bottom − 480)/2 (signed /2) | `1000b15c`, `1000b174`, `1000b180`, `1000b18c` | [HIGH] |
| +0x1c..+0x48 | rects | game area / score bar on screen / score bar in buffer | hud-scorebar.md §1 | [HIGH there] |
| +0x4c | byte | cursor visible (1 at construction) | `FUN_1000ad00`; `FUN_1000b6e0`/`b730`/`b780` | [HIGH] |
| +0x4d | byte | **windowed mode**. The only writer is the pre-main constructor (= 0), see §8.1 | `1000ad28` | [HIGH] |
| +0x4e | byte | still setting up: 1 from construction until the end of `FUN_1000ae20` | `1000ad2c` (1), `1000b518` (0) | [HIGH] |
| +0x50..+0x5c | rect | the top of the screen down to the menu-bar height: (rect.top, rect.left, **MBarHeight**, rect.right) of the DSp front-buffer rect | `1000b0a0 stw r4,0x50; 1000b09c stw r0,0x54; 1000b0a8 stw r6(=+0x60),0x58; 1000b0a4 stw r5,0x5c` | [HIGH] |
| +0x60 | int | `GetMBarHeight()` (`FUN_100497c0`) | `1000ae8c` | [HIGH] |
| +0x64 | byte | screen wider than F52: (rect.right > 640), signed | `1000b0c8…1000b0dc` (`xor/srawi/and/subf/rlwinm`, the signed idiom of timing-frame.md §7; evaluated on 641/640 → 1, 640/640 → 0) | [HIGH] |
| +0x65 | byte | suspended (DSp context inactive, window hidden) | `FUN_1000b7d0` (1), `FUN_1000b8b0` (0) | [HIGH] |
| +0x68 | pixbuf* | **work/back buffer** 640×480×16 (F52×F53×F56) | `1000b320` (args r25/r26/r27 = w/h/depth) | [HIGH] |
| +0x6c | pixbuf* | second 640×480×16 buffer, the terrain picture (timing-frame.md §5) | `1000b3c0` | [HIGH for the size] |
| +0x70 | pixbuf* | 160×480×16 score-bar buffer (F57×F58) | `1000b454 lwz r26 (F58)…1000b46c lwz r25 (F57)…1000b490` | [HIGH] |

All three buffers are filled with RGB(0,0,0) at creation. `FUN_10009f00`'s colour comes from TOC
`-0x732c` → `0x100d6390` (code image), which holds 6 zero bytes. The w3s2 emulator log
`$W/w3s2-emu.txt` shows no pre-main store there. [HIGH]

Writer census for +0x4d/+0x4e/+0x64/+0x65: a raw `stb` scan of the code image
(`w4s1-stbscan.py`, `w4s1-wscan.py`, the latter for wider stores) finds these writers:

| field | writers |
|---|---|
| +0x4d | `FUN_1000ad00` and `FUN_1002dbd0` (a message record, not `D`) |
| +0x4e | `FUN_1000ad00`, `FUN_1000ae20` |
| +0x65 | `FUN_1000ad00`, `FUN_1000b7d0`, `FUN_1000b8b0` (plus `FUN_1000e270` on its own stack frame) |

No `stw`/`sth` covering +0x4c..+0x4f appears in any display function. The 23 `stw 0x4c` sites
are all in game, level or unit modules. [HIGH]

| function | role | label / evidence |
|---|---|---|
| `FUN_1000ad00 @ 1000ad00` | constructor, **pre-main**: called from `FUN_10000750` (emulator log `1000ad04…1000ad44`). Zeroes +8,+9,+0x65,+0x68..+0x70,+4,+0x64,+0x4d,+0x60,+0x50..+0x5c; sets +0x4e = 1, +0x4c = 1 | HIGH, listing `1000ad00…1000ad48` |
| `0x1000ad50` (no Ghidra function) | `~Display()`: empty body, `if (this && (short)flag > 0) operator delete(this)`. Its TVector `0x100e0878` is loaded at `0x10000850` inside the static initialiser `FUN_10000750` (registered for exit destruction; wave 3 owns that registration) | MED, listing `1000ad50…1000ad8c`, `w4s1-tv.py` |
| `FUN_1000ad90 @ 1000ad90` | buffer by index: 0 → +0x68, 1 → +0x6c, 2 → +0x70; otherwise the **non-fatal** data assert ("FALSE", line 0x80) and return 0 | HIGH, listing `1000ada4…1000adf4` (`bl 0x10000f80`) |
| `FUN_1000b620 @ 1000b620` | is initialised (+8) | HIGH, `lbz r3,0x8(r3)` |
| `FUN_1000b6a0 @ 1000b6a0` | +0x4e (still setting up) | HIGH |
| `FUN_1000b6b0 @ 1000b6b0` | copy the menu-bar strip rect +0x50..+0x5c | HIGH |
| `FUN_1000c2f0 / FUN_1000c320 / FUN_1000c350` | copy the display rect (+0xc), the score bar in the buffer (+0x3c) and the score bar on screen (+0x2c) | HIGH, listings |
| `FUN_1000c2a0 @ 1000c2a0` | make the window current if initialised; "ERROR: Attempted to set to a NULL window!" | HIGH |
| `FUN_1000c3b0 @ 1000c3b0` | offset a rect by the display origin (+0x10 to left/right, +0xc to top/bottom). Used by the G_Text screen-text helpers before `FUN_1000bbd0` | HIGH, decompile and `1000c3c4…` |
| `FUN_1000c380 @ 1000c380` | window collapsed? (returns `FUN_1000abe0`). The menu loop polls it to suspend and resume (`FUN_10023da0`/`FUN_10023e10`) | HIGH |
| `FUN_1000c3f0 @ 1000c3f0` | game start (`FUN_100051a0`): `FUN_1000a840` + window +0xe = 1 | HIGH, `1000c408`, `1000c418` |
| `FUN_1000c440 @ 1000c440` | game end: window +0xe = 0 | HIGH |

## 5. Presents: what reaches the screen

### 5.1 The only screen blit: `FUN_1000ac20(win, pixbuf, srcRect*, dstRect*, flag)` [HIGH, listing `1000ac20…1000acf0`]
- If the window is non-null: `SetRect` both int rects into Mac rects, then **one**
  `CopyBits(pixbuf->GWorld + 2, WindowPtr + 2, &src, &dst, srcCopy, NULL)`
  (`1000acc0 addi r4,r4,0x2; 1000acc4 li r7,0x0; 1000acc8 li r8,0x0; 1000accc addi r3,r3,0x2;
  1000acd0 bl CopyBits`).
- **The 5th argument is never read.** The prologue saves r3, r4 and r6 (r5 is used at once) but
  not r7; the first r7 use is a write at `1000ac58`. Every present computes `flag = (D+0x4e ||
  D+0x65)` (`1000bc24`, `1000bd4c`, `1000be70`, `1000c1a4`, `1000c260`), and nothing uses it.
- There is **no VBL wait, no DrawSprocket swap and no direct screen write**. The import census
  has 445 glue stubs. Of the DSp calls, only `DSpStartup/Shutdown`, `GetVersion`,
  `FindBestContext`, `Context_Reserve/Release/SetState/GetState/GetFrontBuffer`,
  `SetBlankingColor` and `ProcessEvent` are imported: no `SwapBuffers`, `GetBackBuffer` or
  `WaitForVBL`. The only other timing import is `Delay` (not in this range).

### 5.2 `FUN_1000bbd0(D, pixbuf, srcRect*, dstRect*)`: rect present [HIGH, listing `1000bbd0…1000bc5c`]
This is `FUN_1000a980(window)` followed by `FUN_1000ac20(window, pixbuf, src, dst)`, with no
offset applied. Callers:
- the G_Text screen-text helpers `FUN_1000d6d0/d7f0/db90/df00` (rects pre-offset by
  `FUN_1000c3b0`);
- the score-bar partial present `FUN_10032a70(rect, src)`: dst = score bar on screen
  (`FUN_1000c350`) + rect, src from the back buffer `+0x68`;
- `FUN_10031400` (score-bar set-up, gated by `DAT_100e01ff`).

This settles hud-scorebar.md NR 4: mode 0 is `srcCopy`, one CopyBits, no interlacing on any
present.

### 5.3 `FUN_1000bc60(D)`: full-screen present (menus, fades with arg 0) [HIGH, listing `1000bc60…1000bd7c`]
src = {0, 0, F53 = 480, F52 = 640} of the back buffer `D+0x68`, and dst = the display rect
`D+0xc`. Neither is offset in practice: when +0x64 = 0, both tops get `off`, which is the
MBarHeight only while +0x4e = 1, i.e. never after set-up. In DSp mode on a 640×480 context that
is one `CopyBits` from buffer (0,0,480,640) to window (0,0,480,640).

### 5.4 `FUN_1000bd80(D)`: "game layout" present (fades with arg 1) [HIGH, listing `1000bd80…1000bea0`]
src = {0, 0, F53 = 480, F52 − F59 = 608} and dst = {0, D+0x20, 480, 608 + D+0x20}. With
D+0x20 = 32 the dst is x 32..639. Buffer x 0..607 lands at screen x 32..639: game area at
32..447, score bar at 448..607, and buffer columns 576..607 at screen 608..639. The left border
x 0..31 is **not** touched and nothing is painted. One CopyBits. Used by `FUN_1000b9a0`/`FUN_1000ba70`
when their 2nd argument is set (the level-appear fade in `FUN_100051a0`). dst.top is 0, not
`D+0xc` (the same thing on a 640×480 context).

### 5.5 `FUN_1000beb0(D)`: in-game present (end of frame, controller +4 == 1) [HIGH, listing `1000beb0…1000c298`]
1. If +0x65 (suspended): return without drawing (`1000bed8 bne 0x1000c27c`).
2. `off` = +0x4e ? MBarHeight : 0, which is 0 at runtime. Make the window current.
3. **Only if +0x64** (screen wider than 640): `ForeColor(blackColor)`, take portRect
   (`FUN_1000ab20`) into r, and `PaintRect` four times:
   - {pr.top+off, pr.left, **D.top**, pr.right};
   - then top = D.bottom (`1000bf78`);
   - then top += off, right = D.left;
   - then top += off, left = D.right.

   The bottom stays D.top after the first rect, so **rects 2–4 are empty** (bottom < top) and
   only the band above the display is painted. That is an original bug, harmless because
   `FUN_1000a640`/`FUN_1000ab50` painted the whole window black and nothing else draws there.
   [HIGH: `1000bf60 lwz r0,0xc(r30); 1000bf64 sth r0,0x3c(r1)`; the bottom is not rewritten
   before `1000bfbc`]
4. **Left border:** `PaintRect({D.top, D.left, D.top + F53, D.left + F59})` = (0,0,480,32).
   **Right strip:** `PaintRect({D.top, D.left + F52 − F59, D.top + F53, D.left + F52})` =
   (0,608,480,640). Both use the window's current pen, which is black (the default, or
   `ForeColor(33)` from step 3). **F59 `LeftBorderWidth` is used for both; F60 is never read.**
   Listing: `1000bff4 li r3,0x3b` … `1000c04c PaintRect`; `1000c054 li r3,0x34`, `1000c068 li
   r3,0x3b`, `1000c084 li r3,0x3b` … `1000c0e8 PaintRect`. [HIGH]
5. **Game area:** src = {0, 0, F55 = 480, F54 = 416} (`1000c0f8 li r3,0x36`, `1000c110 li
   r3,0x37`) and dst = `D+0x1c` = (0,32,480,448). `FUN_10009e40(+0x68)`, then `FUN_1000ac20`:
   one CopyBits.
6. **Score bar:** src = `D+0x3c` = (0,416,480,576) **of the back buffer `+0x68`** (`1000c234 lwz
   r29,0x0(r28)`, r28 = D+0x68), not of `+0x70`; dst = `D+0x2c` = (0,448,480,608). One
   CopyBits.

So an in-game present is 2 PaintRect + 2 CopyBits (srcCopy) with no wait. This settles
timing-frame.md NR 6. Beyond the calls listed in §5.6 it has one more caller: the update-event
case of the event pump at `10048ffc` (§6). Only `FUN_100229a0` calls the pump, with r3 = 0, so
that path always picks `FUN_1000bc60`.

### 5.6 Per-frame versus once [HIGH for the call sites listed]
| when | calls |
|---|---|
| boot, once (`FUN_100000e0`) | `FUN_1000ca90` (memory) → `FUN_1000ae20(D, 640, 480, 16, pref 4)` → `FUN_1000c470` (DSp) → `FUN_1000a640`/`FUN_1000ab50`/`FUN_1000aa30` → 3 × (`FUN_100099c0` + `FUN_10009f00` black) → `FUN_1000c2a0`; publisher logo via `FUN_1000a3b0` |
| every game frame | end frame `FUN_10030bc0`: messages/FPS text → console → render layers 0–1 (`FUN_10018b20(0)`) → background `FUN_10010120` → `FUN_10009fd0` (terrain `+0x6c` → `+0x68`; 2 CopyBits, or 1 interlaced) → layers 2–5 → particles `FUN_10043ba0` → layers 6–15 → limiter **only if byte pref 10** → `FUN_1000beb0` — ⚑ corrected (review wave 3, 2026-10-06) #C7: was "background → sprites → limiter → present"; order per timing-frame.md §2.3 (listing) |
| every menu frame | `FUN_1000bc60` (via `FUN_10024810`, `FUN_10024e70`, …); score-bar and text partials via `FUN_1000bbd0` |
| fades | `FUN_1000bc60` or `FUN_1000bd80` once per step |
| suspend/resume, collapse, alerts | `FUN_1000b7d0` / `FUN_1000b8b0` |
| game start / end | `FUN_1000c3f0` / `FUN_1000c440`; at end `FUN_10009d70(+0x6c, 640, 480, 16)` |
| quit (`FUN_10000630`) | `FUN_1000b530` → `FUN_1000c8d0`; `FUN_1000caf0` (leak report) |

## 6. DrawSprocket set-up and teardown

### 6.1 `FUN_1000c470(D, w, h, depth, unused, rect*)` [HIGH, listing `1000c470…1000c8c8`]
1. Log "    Required Display Dimensions:  %i x %i". If the weak import `DSpStartup` is NULL
   (`1000c4a4 lwz r0,-0x7f68(r2)`): fatal alert "Missing System Software" / "Apple's DrawSprocket
   was not found… 1.7.2 or later…" (`FUN_1000ced0(…,1)`, which quits).
2. If `DSpGetVersion` is NULL: log "Old (pre 1.7) version…" and treat as too old. Otherwise
   `DSpGetVersion(&NumVersion)`, sprintf "DrawSprocket version: %i.%i.%i" plus a stage suffix
   ("(Not Released)", Development/Alpha/Beta/Final/Unknown Stage). That string is built into a
   stack buffer and **never logged** (`1000c5c0…1000c644`, no `FUN_10049550` after it).
3. **Version gate:** OK if major > 1, or major == 1 and minor > 7, or 1.7 with bug ≥ 2. That is
   DSp ≥ 1.7.2 (`1000c648 cmpwi r29,0x1` … `1000c680 cmpwi r27,0x2`). Too old → fatal "Old System
   Software" alert (quits).
4. `DSpStartup()`: an error logs "ERROR: (%i) DrawSprocket could not be started." and makes a
   fatal tool assert (line 0x581).
5. `DSpContextAttributes` (0x48 bytes, cleared by `FUN_1000cd90`), from the raw `stw` offsets at
   sp+0x6c (`1000c6f0…1000c724`):

   | attr off | field | value |
   |---|---|---|
   | +0x00 | frequency | 0 (any) |
   | +0x04 / +0x08 | displayWidth / displayHeight | w = 640 / h = 480 (`stw r23,0x70`, `stw r24,0x74`) |
   | +0x14 | colorNeeds | 2 = `kDSpColorNeeds_Require` (`stw r3,0x80`) |
   | +0x1c | contextOptions | 0 (no page flipping, no hardware acceleration) (`stw r5,0x88`) |
   | +0x20 / +0x24 | backBufferDepthMask / displayDepthMask | 16 = `kDSpDepthMask_16` (`stw r25,0x8c/0x90`) |
   | +0x28 / +0x2c | backBufferBestDepth / displayBestDepth | 16 (`stw r25,0x94/0x98`) |
   | +0x30 | pageCount | **1** (`stw r0,0x9c`) |
   | others | colorTable, gameMustConfirmSwitch, … | 0 |

   The depth argument (16) is written into the mask fields too. 16 = `kDSpDepthMask_16` (bit 4),
   so it works by coincidence.
6. `DSpFindBestContext(&attr, &D->ctx)` then `DSpContext_Reserve(ctx, &attr)`. Errors are logged
   and make a fatal tool assert (0x59e / 0x5ad).
7. `DSpSetBlankingColor(*(RGBColor*)0x100fb318)`. The colour is in bss (TOC `-0x7334`, beyond the
   data image). Its only reference is this load (`1000c798`, raw TOC scan) and there is no
   pre-main store in `w3s2-emu.txt`, so it is **black**. An error here is non-fatal (logged only).
8. `DSpContext_SetState(ctx, kDSpContextState_Active = 0)`. Error → fatal (0x5cd).
9. `DSpContext_GetFrontBuffer(ctx, &port)` (an error is a fatal assert, 0x5d5). `FUN_10044b50`
   copies the port's portRect into `*rect`, which becomes the window rect. Asserts right > 0 and
   bottom > 0. Log "    DrawSprocket context dimensions: %i, %i, %i, %i". Then a 5-tick
   busy-wait.

The 5th argument (r7) is **never read**: it is not among the saved registers
(`1000c47c…1000c48c` save r3–r6 and r8), and the first r7 use is a write at `1000c520`. [HIGH]

### 6.2 `FUN_1000ae20` paths that feed it (rereading the hud-scorebar.md §1 function)
- `FUN_10045f70()` false → alert "System Level Error" / "Sorry but this application cannot
  continue safely… (bad Graphics Port)…" with flag 1 (fatal), then return (`1000ae78`, `1000ae80`).
  `FUN_10045f70` walks the low-memory **PortList** (`10045f80 lwz r28,0xd66(0)`, loop
  `10046188..10046194`) and validates every GrafPort (file-pict-alerts-manager.md §4) — ⚑ corrected (review wave 3, 2026-10-06) #M2: was
  "walks the GDevice list and validates the pixmaps".
- The main-device rect from `gdRect` (`1000aec0 lwz r0,0x26(r3); lwz r3,0x22(r3)`) is used only
  for: the r7 arg, forced to 0 unless the monitor is strictly larger than 640×480 (`1000af4c cmpw;
  1000af50 ble; 1000af78 li r28,0x0`), which is then dropped by `FUN_1000c470`; and the windowed
  centring, which is unreachable (§8.1).
- The DSp path overwrites that local rect with the front-buffer rect (`1000afa8 addi r8,r1,0x58`).
- Then: window object (`new 0x18`; "fWindowPtr" fatal assert), `FUN_1000a640(win, rect, +0x4d)`,
  `FUN_1000ab50` (paint black), `FUN_1000aa30` (show), make current, the +0x50 rect, +0x64, the
  display rect, hud rects, 3 buffers, +8 = 1, +0x4e = 0. [HIGH]

### 6.3 `FUN_1000c8d0(D)`: teardown [HIGH, listing `1000c8d0…1000ca04`]
1. Make the window current (via the global `D`).
2. If ctx == 0: log "NON-FATAL ERROR: DrawSprocket context was not valid." Otherwise
   `DSpContext_GetState`. If that errs, log and skip release. If the state ≠ 2 (inactive):
   `DSpContext_SetState(ctx, 2)`. Then `DSpContext_Release(ctx)` and ctx = 0.
3. Log "Attempting to Shut Down DrawSprocket", wait 5 ticks, `DSpShutdown()`.

Every error here is logged only; nothing quits.

### 6.4 `FUN_1000b530(D)`: display shutdown [HIGH, listing `1000b530…1000b618`]
1. Unregister "Display" (`FUN_1003a900`).
2. If initialised: if +9 is already set, log "DEBUG: Display Shut Down Already attempted!".
   Otherwise set +9 = 1, then:
   - if not windowed, `FUN_1000c8d0`;
   - delete the buffers +0x68/+0x6c/+0x70 (`FUN_10009a60(b,1)`, loop `1000b5b0…1000b5dc`);
   - delete the window (`FUN_1000a5e0(w,1)`);
   - +8 = 0.

The only caller is `FUN_10000630` (quit).

## 7. Suspend/resume, cursor and events

| function | what it does | label / evidence |
|---|---|---|
| `FUN_1000b7d0 @ 1000b7d0` (suspend) | Only if initialised and not suspended. If not windowed: `DSpContext_GetState`, and if the state ≠ 2, `DSpContext_SetState(ctx, kDSpContextState_Inactive = 2)` (errors are fatal tool asserts, lines 0x238/0x23e); then `HideWindow`. Always: +0x65 = 1. Callers: `FUN_1000ced0` (around alerts), `FUN_10010fc0` (prefs dialog), `FUN_10023da0` (menu, window collapsed), `FUN_10025190`, `FUN_10025270` | HIGH, `1000b818…1000b88c` |
| `FUN_1000b8b0 @ 1000b8b0` (resume) | +0x65 = 0. If not windowed: when the state ≠ 0, `DSpContext_SetState(ctx, Active = 0)` (fatal assert 0x267); `ShowWindow` + `PaintRect` the whole window black. Always: if the window is not in front, `BringToFront`, make current, paint black. The game image comes back at the next present | HIGH, `1000b8d0…1000b978` |
| `FUN_1000b630 @ 1000b630` | `DSpProcessEvent(event, &processed)` when not windowed; the processed byte is normalised to 0/1 and the OSStatus returned. Windowed: processed = 0, return 0. Callers: the event pumps `FUN_10048c90`/`FUN_10048f30`. (`10048fa8` then overwrites the flag with 0, so the game handles every event itself; w4s2's function) | HIGH, `1000b660 bl DSpProcessEvent; 1000b66c neg/or/rlwinm` |
| `FUN_1000b6e0 @ 1000b6e0` | `HideCursor` if +0x4c, then +0x4c = 0 | HIGH |
| `FUN_1000b730 @ 1000b730` | `ShowCursor` if !+0x4c, then +0x4c = 1 | HIGH |
| `FUN_1000b780 @ 1000b780` | `InitCursor` (arrow, visible) if initialised, then +0x4c = 1 | HIGH |

**Menu-bar strip (INDEX #53, front-end.md NR 2):** the menu loop `FUN_100229a0` reads
`GetMouse` (`FUN_10048ee0`: {h, v} in window-local coordinates) and the +0x50 rect. Listing
`10022c1c…10022c64` (disasm-review2.txt):

| check | instruction |
|---|---|
| h < left → outside | `cmpw; blt` |
| h > right → outside | `bgt` |
| v < top → outside | `blt` |
| v ≤ bottom → inside | `ble` |
| inside → skip hover | `bne 0x10022c90` |

So **button hover is suppressed while the pointer is in the top MBarHeight + 1 rows (0..MBarHeight
inclusive, full width)**, where the hidden system menu bar would be. Outside it the loop calls
`FUN_1000bc60` only if +0x4e is set (never after set-up), then the hover `FUN_10024530`.
[HIGH for the rect and the test; MED for the MBarHeight value, which is a runtime OS value
(20 on a standard Mac OS 9 system)]

## 8. Consequences for the replica

### 8.1 Windowed mode is unreachable and the "Full Screen" preference does nothing
The windowed choice is `D+0x4d`. Its only writer is the pre-main constructor (= 0, §4 census),
so `FUN_1000ae20` always takes the DrawSprocket path and `FUN_1000b630` always forwards events
to DSp.

The DITL "Full Screen (Takes Effect on Relaunch)" pref byte 4 reaches `FUN_1000ae20` as r7
(`FUN_100000e0`: `FUN_10004ef0(4)` → 5th argument). It is cleared when the monitor is not larger
than 640×480, passed to `FUN_1000c470` as r7, and **never read there** (§6.1). The pref has no
effect in 1.0.6. [HIGH]

⚑ conflict: engine-loop.md §5 says the display mode is a "choice from pref byte 4". Same for
timing-frame.md §6, which gives byte 4 the role "display mode": the dialog label is right, but
the code ignores the value.

### 8.2 Screen model for a faithful replica
- One 640×480 16-bit context (DSp, any refresh, colour required, one page) over a borderless
  window of the same rect.
- Everything is composed into the 640×480 back buffer `+0x68`: game area at x 0..415, score bar
  at 416..575. It is then copied with QuickDraw `srcCopy` to the window: game area to x 32..447,
  score bar to x 448..607. x 0..31 and 608..639 are painted black every game frame.
- There is no vertical-sync wait and no page flip, so tearing is part of the original look. The
  frame pacing is only the TickCount limiter (timing-frame.md §2.3).
- Menus copy the whole buffer 1:1.
- `RightBorderWidth` (F60 = 32) is never used; the right strip width is F59. Since both are 32,
  the picture is the same.
- Interlacing (pref 5) affects only the terrain → work-buffer copy, never a present.

## Worked example: one in-game frame at 640×480×16 (DSp mode, interlacing off)
State from `FUN_1000ae20` with a 640×480 DSp context:
- display rect `D+0xc` = (0,0,480,640) and +0x64 = 0 (640 > 640 is false);
- game area `D+0x1c` = (0,32,480,448);
- score bar on screen `D+0x2c` = (0,448,480,608);
- score bar in the buffer `D+0x3c` = (0,416,480,576);
- +0x4e = 0 and +0x65 = 0.

The Toolbox calls in order:
1. Background (`FUN_10010120` → `FUN_10009fd0(+0x6c, +0x68, …, 0)`, `10009fd0` listing):
   `SetGWorld(work GWorld, NULL)`; `CopyBits(terrain+2, work+2, &sR, &dR, srcCopy, NULL)` ×2,
   with identical arguments (`1000a12c`, `1000a14c`).
2. Sprites, HUD and text are drawn into `+0x68` (blitters, not in this file). Then the limiter
   spins on `TickCount` until lastPresent + 2.
3. `FUN_1000beb0(D)`:
   1. `SetGWorld(window, NULL)` (`FUN_1000c2a0` → `FUN_1000a980`). +0x64 = 0, so there are no
      letterbox bands.
   2. `SetGWorld(window, NULL)` again, then `PaintRect({top 0, left 0, bottom 480, right 32})`.
      From `1000bff0…1000c048`: left = D+0x10 = 0, top = D+0xc = 0, right = 0 + F59 = 32,
      bottom = 0 + F53 = 480.
   3. `PaintRect({0, 608, 480, 640})`: left = 0 + F52 − F59 = 608, right = 608 + 32 = 640
      (`1000c054…1000c0e8`).
   4. `SetGWorld(work, NULL)` (`FUN_10009e40`), `SetGWorld(window, NULL)`, then
      `CopyBits(work+2, window+2, {0,0,480,416}, {0,32,480,448}, srcCopy, NULL)`. The src rect
      is F55/F54 at `1000c0f8…1000c140`; the dst is `D+0x1c`.
   5. `SetGWorld(window, NULL)` ×2, then `CopyBits(work+2, window+2, {0,416,480,576},
      {0,448,480,608}, srcCopy, NULL)`.

Total: 4 CopyBits (2 for the background, 2 for the present), 2 PaintRect and about 7
SetGWorld calls, with no VBL wait and no DSp call.
Interlacing on: step 1 becomes one `CopyBits` with doubled rowBytes over every other row.
Pixel 100,50 of the game area (buffer x = 100, y = 50) lands at screen (132, 50).

## NOT RESOLVED (this file)
1. Window +0x04/+0x08/+0x0e/+0x10/+0x14 have no reader found. I only grepped the decompile for
   `*(D+4)+…` reads. A raw scan for `lwz/lbz rX,0x4|0x8|0xe|0x10|0x14(rY)` with rY = `D+4` would
   settle whether a direct-to-screen path survives.
2. The window's pen colour when +0x64 = 0: the border `PaintRect`s rely on it being black (the
   NewCWindow default). No `RGBForeColor`/`ForeColor` on the window port was found in this
   range. A port-colour change elsewhere (e.g. G_Text drawing with the window current) would
   change the border colour. Settle with a raw scan of `ForeColor`/`RGBForeColor` call sites
   that run while the window is current.
3. MBarHeight at runtime (it defines the hover-dead strip, §7). It is OS-dependent; Ben's system
   decides.
4. What DSp does when 640×480×16 is unavailable: `DSpFindBestContext` may return a larger mode.
   The code centres the display rect and paints only the top band (§5.5). Behaviour depends on
   the DSp version.
5. ~~`FUN_10045f70` and `FUN_10044b80` are labelled by w4s4. I used their decompile only.~~ → ⚑ corrected (review wave 3, 2026-10-06) #S: file-pict-alerts-manager.md §4 (`FUN_10045f70` = PortList validator, listing `10045f80..10046198`) (`FUN_10044b80` = active-screen GDevice finder, same §4 table) (critic wave 3 §3).

## Role-table rows (for merge)
| `FUN_10009bd0` | M_PixelBuffer.cc | create pixel buffer: NewGWorld(depth, 0,0,w,h, no ctab/device, useTempMem if MaxBlock < est+256K), LockPixels, SetGWorld, EraseRect; fields +0..+0x2c (§1) | HIGH | listing `10009bf8…10009ce4`, `10045088…10045094` |
| `FUN_10009d00` | M_PixelBuffer.cc | dispose: DisposeGWorld + zero fields | HIGH | `10009d20 bl DisposeGWorld` |
| `FUN_10009d70` | M_PixelBuffer.cc | resize if w/h/depth changed (dispose + recreate) | HIGH | `10009d9c…10009e1c` |
| `FUN_10009e40` | M_PixelBuffer.cc | make current (SetGWorld); debug log if invalid | HIGH | `10009e5c` |
| `FUN_10009e90` | M_PixelBuffer.cc | make current + EraseRect(portRect) | HIGH | `10009eb4`, `10009ee0` |
| `FUN_10009f00` | M_PixelBuffer.cc | fill with RGBColor (RGBForeColor, PaintRect portRect, ForeColor black) | HIGH | `10009f78…10009fa0` |
| `FUN_1000a190` | M_PixelBuffer.cc | blended copy: OpColor(65535·pct/100), CopyBits mode blend (0x20); only caller the unregistered console MEDIA handler `0x100107a0` → unreachable | HIGH | `1000a31c…1000a360`; site `10010818` |
| `FUN_1000a3b0` | M_PixelBuffer.cc | copy src rect centred in the dst bounds (signed /2), then `FUN_10009fd0` (publisher logo) | HIGH | `1000a3c8…1000a434` |
| `FUN_1000a450` | M_PixelBuffer.cc | getter: w, h, depth, base, rowBytes | HIGH | `1000a450…1000a478` |
| `FUN_1000a520` | M_PixelBuffer.cc | getter: depth (+0x10) | HIGH | `1000a520` |
| `FUN_1000a560` | M_PixelBuffer.cc | bounds-rect address (+0x1c) | HIGH | `1000a560` |
| `FUN_1000a570` | M_PixelBuffer.cc | GWorldPtr getter (debug log if 0) | HIGH | `1000a570…1000a5b4` |
| `FUN_1000a5c0` | M_Window.cc | window object constructor | HIGH | `1000a5c0…1000a5d4` |
| `FUN_1000a5e0` | M_Window.cc | window deleting destructor | HIGH | `1000a600…1000a61c` |
| `FUN_1000a640` | M_Window.cc | NewCWindow("Deimos Rising", plainDBox 2 / noGrowDocProc 4 if windowed), visRgn = rect, Inval/Paint black, Geneva 9 | HIGH | `1000a6a0…1000a774` |
| `FUN_1000a7d0` | M_Window.cc | dispose window (DisposeWindow) | HIGH | `1000a810` |
| `FUN_1000a840` | M_Window.cc | refresh: un-collapse if windowed (+5 ticks), +8 = port bits, +0x10/+0x14 = content origin, +4 = PixMap of the device under it | HIGH | `1000a858…1000a968` |
| `FUN_1000a980` | M_Window.cc | make window current (SetGWorld) | HIGH | `1000a9a8` |
| `FUN_1000a9e0` | M_Window.cc | HideWindow | HIGH | `1000a9f8` |
| `FUN_1000aa30` | M_Window.cc | ShowWindow | HIGH | `1000aa48` |
| `FUN_1000aa80` | M_Window.cc | is front window | HIGH | `1000aab8` |
| `FUN_1000aaf0` | M_Window.cc | BringToFront | HIGH | `1000ab08` |
| `FUN_1000ab20` | M_Window.cc | portRect → int rect | HIGH | `1000ab2c…1000ab38` |
| `FUN_1000ab50` | M_Window.cc | make current + PaintRect(portRect) (black) | HIGH | `1000ab88`, `1000abac` |
| `FUN_1000abd0` | M_Window.cc | set +0xe "in game" byte (no reader found) | HIGH | `stb r4,0xe(r3)` |
| `FUN_1000abe0` | M_Window.cc | IsWindowCollapsed | HIGH | `1000abf0` |
| `FUN_1000ac20` | M_Window.cc | **the screen blit**: one CopyBits(pixbuf GWorld+2 → WindowPtr+2, srcCopy, no mask); 5th arg ignored; no VBL | HIGH | `1000acb4…1000acd0` |
| `FUN_1000ad00` | M_Display.cc | display constructor (pre-main, from `FUN_10000750`): +0x4e = +0x4c = 1, rest 0 | HIGH | `1000ad00…1000ad48`; w3s2-emu |
| (undefined) `0x1000ad50` | M_Display.cc | ~Display (empty; delete if flag > 0); TVector `0x100e0878` loaded in `FUN_10000750` at `0x10000850` | MED | listing `1000ad50…1000ad8c`, `w4s1-tv.py` |
| `FUN_1000b530` | M_Display.cc | display shutdown: once-guard +9, DSp teardown if not windowed, delete 3 buffers + window | HIGH | `1000b550…1000b604` |
| `FUN_1000b620` | M_Display.cc | is initialised (+8) | HIGH | `1000b620` |
| `FUN_1000b630` | M_Display.cc | DSpProcessEvent passthrough (processed → 0/1); windowed → 0 | HIGH | `1000b660…1000b678` |
| `FUN_1000b6a0` | M_Display.cc | +0x4e (set-up in progress; 0 after `FUN_1000ae20`) | HIGH | `1000b6a0` |
| `FUN_1000b6b0` | M_Display.cc | menu-bar strip rect (top, left, MBarHeight, right) | HIGH | `1000b6b0…`; writers `1000b09c…1000b0a8` |
| `FUN_1000b6e0` | M_Display.cc | HideCursor (tracked +0x4c) | HIGH | `1000b700` |
| `FUN_1000b730` | M_Display.cc | ShowCursor (tracked +0x4c) | HIGH | `1000b750` |
| `FUN_1000b780` | M_Display.cc | InitCursor if initialised | HIGH | `1000b7a0` |
| `FUN_1000b7d0` | M_Display.cc | suspend: DSp context → Inactive (2), HideWindow, +0x65 = 1 | HIGH | `1000b818…1000b88c` |
| `FUN_1000b8b0` | M_Display.cc | resume: DSp → Active (0), Show + paint black, bring to front | HIGH | `1000b8d0…1000b978` |
| `FUN_1000bbd0` | M_Display.cc | present a rect of a buffer to the window (one CopyBits, srcCopy, no offset) | HIGH | `1000bbfc…1000bc38` |
| `FUN_1000bd80` | M_Display.cc | fade present (game layout): buffer (0,0,480,608) → screen (0,32,480,640), no borders | HIGH | `1000bd8c…1000be84` |
| `FUN_1000c2a0` | M_Display.cc | make display window current | HIGH | `1000c2ac…1000c2d8` |
| `FUN_1000c2f0` / `FUN_1000c320` / `FUN_1000c350` | M_Display.cc | display rect (+0xc) / buffer score-bar rect (+0x3c) / screen score-bar rect (+0x2c) getters | HIGH | listings — ⚑ corrected (review wave 3, 2026-10-06) #L: label audit, address cited — `1000c2f0..1000c30c` (lwz/stw +0xc..+0x18), `1000c320..1000c33c` (+0x3c..+0x48), `1000c350..1000c36c` (+0x2c..+0x38) |
| `FUN_1000c380` | M_Display.cc | window collapsed? (menu suspend/resume poll) | HIGH | `1000c390` |
| `FUN_1000c3b0` | M_Display.cc | offset rect by display origin (+0x10, +0xc) | HIGH | decompile + listing — ⚑ corrected (review wave 3, 2026-10-06) #L: label audit, address cited — `1000c3b0..1000c3e4` (+0x10 added to left/right, +0xc to top/bottom) |
| `FUN_1000c3f0` | M_Display.cc | game start: window refresh + in-game byte 1 | HIGH | `1000c408`, `1000c418` |
| `FUN_1000c440` | M_Display.cc | game end: in-game byte 0 | HIGH | `1000c454` |
| `FUN_1000c470` | M_Display.cc | DrawSprocket set-up: DSp ≥ 1.7.2 gate (fatal alerts), Startup, FindBestContext(640×480, colorNeeds Require, depth 16, 1 page, options 0), Reserve, black blanking, Active, front-buffer rect; 5th arg unused | HIGH | `1000c4a4…1000c8b0` |
| `FUN_1000c8d0` | M_Display.cc | DrawSprocket teardown: Inactive, Release, DSpShutdown (all non-fatal) | HIGH | `1000c920…1000c9e8` |
| `FUN_1000ca90` | M_Memory.cc | memory module init: register "Memory", zero the 4 counters, tracking on, `set_new_handler(0x10001000)` (TV `0x100e07c0`; ⚑ corrected (review wave 3, 2026-10-06) (critic wave 3 §1): no `FUN_10001000` exists — the handler is no-function code at `0x10001000`, a fatal alert via `1000101c bl 0x1000ced0` with `r5 = 1`) | HIGH | `1000caa4…1000cacc` |
| `FUN_1000caf0` | M_Memory.cc | memory module shutdown: leak report if allocs ≠ frees | HIGH | `1000cb14…1000cb48` |
| `FUN_1000cc00` | M_Memory.cc | free pointer: GetPtrSize → freed bytes/count, DisposePtr | HIGH | `1000cc18…1000cc3c` |
| `FUN_1000cc60` | M_Memory.cc | GetPtrSize (0 for NULL) | HIGH | `1000cc78` |
| `FUN_1000cca0` | M_Memory.cc | NewHandle/NewHandleClear, optional HLock | HIGH | `1000ccbc…1000ccdc` |
| `FUN_1000cd00` | M_Memory.cc | DisposeHandle if non-null | HIGH | `1000cd14` |
| `FUN_1000cd30` | M_Memory.cc | HLock if non-null | HIGH | `1000cd44` |
| `FUN_1000cdc0` | M_Memory.cc | memset(p, c, n) thunk → `FUN_10051f40` | HIGH | `1000cdcc`; `FUN_100462b0` = `FUN_10051f40(p,0,n)` |
| `FUN_1000cdf0` | M_Memory.cc | FreeMem | HIGH | `1000cdfc` |
| `FUN_1000ce20` | M_Memory.cc | log "Memory Check (%s) - Free Mem: %iK, Max Block: %iK" (FreeMem/MaxBlock ÷1024, rounded toward 0); callers `FUN_10002850`, console LOGMEM `0x100087e8` (unregistered) | HIGH | `1000ce44…1000cea4` |
| ⚑ corrected `FUN_10009fd0` | M_PixelBuffer.cc | copy buffer → buffer: rects default to the **src** bounds (both); off = two identical CopyBits srcCopy, on = `FUN_100450e0`; only interlaced caller `FUN_10010120` | HIGH | listing `10009fd0…1000a184`; raw call-site scan; was MED (dump) |
| ⚑ corrected `FUN_1000beb0` | M_Display.cc | in-game present: skip if suspended; letterbox bands only if screen wider than 640 (3 of 4 rects empty, bug); black left (0..31) and right (608..639, width F59) borders; 2 CopyBits from `+0x68`: game (0,0,480,416) → (0,32,480,448), bar (0,416,480,576) → (0,448,480,608); no VBL | HIGH | listing `1000beb0…1000c298`; was MED (dump) |
| ⚑ corrected `FUN_1000bc60` | M_Display.cc | full-screen present: buffer (0,0,480,640) → display rect, one CopyBits | HIGH | listing `1000bc60…1000bd7c`; was MED (dump) |
| ⚑ corrected `FUN_1000a4a0` | M_PixelBuffer.cc | base, rowBytes getter (+0x14/+0x18) | HIGH | `1000a4ec`, `1000a4f4`; was MED (usage) |
| ⚑ corrected `FUN_1000a530` | M_PixelBuffer.cc | copy bounds rect +0x1c..+0x28 | HIGH | `1000a530…1000a550`; was MED |
| ⚑ corrected `FUN_1000ad90` | M_Display.cc | buffer by index 0/1/2 → +0x68/+0x6c/+0x70; other → non-fatal data assert, 0 | HIGH | `1000ada4…1000adf4`; was MED |
| ⚑ corrected `FUN_100099c0` | M_PixelBuffer.cc | constructor: zero + create(w,h,depth,flag) | HIGH | `100099e4`, `10009a00`; was MED |
| ⚑ corrected `FUN_10009ac0` | M_PixelBuffer.cc | clone pixel buffer with contents | HIGH | `10009b5c`, `10009ba0`; was MED |
| ⚑ corrected `FUN_1000cb60` | M_Memory.cc | NewPtr/NewPtrClear; success → alloc bytes/count += ; failure → log with FreeMem (no assert) | HIGH | `1000cb80…1000cbd4`; was MED |
| ⚑ corrected `FUN_1000cd60` / `FUN_1000cd90` | M_Memory.cc | thunks: → `FUN_10051c60` (memcpy) / → `FUN_100462b0` = memset 0 | HIGH (thunk) | `1000cd6c`, `1000cd9c`; callee identity stays MED |
| ⚑ corrected `FUN_100450e0` | (w4s4 range) | interlaced copy: rowBytes doubled (flag bits kept), rect/bounds halved, odd parity → start one row lower, one CopyBits srcCopy, parity ^= 1 | HIGH (call shape) | `10045588…10045590`, `100455c8…100455f4`; was MED (dump) |

Memory globals (for the record): alloc count `0x100e010c`, alloc bytes `0x100e0110`, free count
`0x100e0104`, freed bytes `0x100e0108`, tracking flag `0x100e0114`. They are TOC
`-0x6224/-0x6220/-0x622c/-0x6228/-0x621c`, from the `1000cab8…1000cac8` stores. [HIGH]

## INDEX updates (for merge)
- **#53 closed** (front-end.md NR 2) → §4 and §7. +0x50..+0x5c = (top, left, MBarHeight, right)
  of the DSp screen rect. Menu hover is suppressed while the pointer is in that strip
  (inclusive).
- **O14 closed** (hud NR 4, timing NR 4, timing NR 6) → §2.1 and §5:
  - `FUN_10009fd0`'s double CopyBits is confirmed by listing (identical, redundant);
  - every present is one CopyBits srcCopy per rect through `FUN_1000ac20`;
  - there is no VBL wait or page flip;
  - `FUN_1000beb0` draws 2 border PaintRects + 2 CopyBits;
  - interlacing touches only the background copy.
- **New, for the ledger:** pref byte 4 "Full Screen" is ignored and windowed mode is unreachable
  (§8.1). ⚑ conflict with engine-loop.md §5 ("choice from pref byte 4") and timing-frame.md §6
  (byte 4 = "display mode").
- **New:** `FUN_1000beb0` letterbox bug: only the top band is painted (§5.5); F60
  `RightBorderWidth` is unused (the right strip uses F59).
- **New:** `FUN_1000a190` is reachable only from the unregistered console command MEDIA (§2.3).
