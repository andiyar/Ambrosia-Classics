# Deimos Rising 1.0.6 — front end: main menu, start/return flow, scores, name entry, credits, advert, pause

Scope (wave-2 reader 9, 2026-10-03): the menu and non-game screens. Ranges `0x10021950–0x10026100`
(G_Scores.cc `FUN_10021950`/`FUN_10021bd0`/`FUN_100222f0`, the menu loop `FUN_100229a0` and its
neighbours, all of G_Interface.cc `0x10023040–0x10025970`, the advert `FUN_10025970`, G_Credits.cc
`FUN_10025b90`), the low tail of level selection `0x10030020–0x100313b0` (only the functions not
owned by the frame controller), and `FUN_10006240`. Also read, because the flow needs them: the Mac
event pump `FUN_10048f30` + its jump table, `FUN_10049910`, `FUN_10049370`, `FUN_10048c90`, the
screen fades `FUN_1000b9a0`/`FUN_1000ba70`, the text-list fades `FUN_1000db90`/`FUN_1000df00`,
`FUN_10030870` (pause hook), `FUN_100069b0` (film choice), `FUN_100214c0` (call order only).
OUT: level-selection internals (scoring-bonuses.md §10 — cited, not re-derived), the frame
controller rows (engine-loop.md §4), boot internals (engine-loop.md §2), the game loop.

Evidence: decompile dump; raw listings `$W/disasm-w2s9.txt` (range post-script `DisasmRange.java`,
copied to `$W/tools-w2s9/`; ranges `10021950:10026100 10030020:10031400 10006240:100064c0
10048f30:10049150`) and `$W/disasm-w2s9b.txt` (DisasmFuncs: `FUN_1000b9a0 FUN_1000ba70
FUN_1000db90 FUN_1000df00 FUN_10049820`). Perm-list indices: a Python pass over the listing pairing
each `li r3,N` with the following `bl` to `FUN_10020250/10020210/10020200/10020260/1000d130`
(every index below was checked this way; "F n" = flli n, "SND n" = gaso n, "SPR n" = gasp n,
"FMT n" = `idli Formats[gate]` n via `FUN_1000d130(n, ts)` which copies text format n). Data
values: `$W/data/Game/...` decoded files (flli index = `grep '^#' … | awk '{print NR-1}'`).
Strings in the binary: read from `$W/mem/100de330.bin` (C strings; the copyright string is
obfuscated, decoded with the `FUN_10046470` transform `((b>>4|b<<4)^0xff)`). Button labels: the
sprite sheet `Game/im08/Menu Buttons IC[mebu].gif` viewed as an image.

Time unit everywhere: Mac **ticks** (TickCount, ~60.15 Hz). All front-end waits are
TickCount loops, not frame-controller ticks.

## 1. Front-end state (globals, r2 = 0x100e6330)

| address | r2 off | meaning | evidence | label |
|---|---|---|---|---|
| `0x100e01b0` | −0x6180 | button list (list of 0x124-byte buttons) | `FUN_10023fd0`, `100254d8 lwz r3,-0x6180(r2)` | HIGH |
| `0x100e01ac` | −0x6184 | element list (text-settings 0x148 each, drawn by G_Text) | `FUN_10025420`, `1002551c` | HIGH |
| `0x100e01a4` / `0x100e01a0` | | loading-progress line list / its timestamp | `FUN_10025330`, `FUN_10023040` | MED |
| `0x100e01b4` | | "registered" seen (hides REGISTER button) | `FUN_100229a0`, `FUN_10023e10` | MED |
| `0x100e01b5` | −0x617b | pause screen active | `10022f18 stb r0,-0x617b(r2)` | HIGH |
| `0x100e01b6` | −0x617a | request: restart/resume menu music on next menu pass | `10022b9c lbz r0,-0x617a(r2)` | HIGH |
| `0x100e01b7` | −0x6179 | suspended (app in background or a modal dialog up) | `FUN_10023da0`/`FUN_10023e10`, getter `FUN_10023030` | HIGH |
| `0x100e01b8` | −0x6178 | quit requested (Q key, File▸Quit, Quit AppleEvent) | `10023c7c stb r0,-0x6178(r2)`; getter `FUN_10022ee0` | HIGH |
| `0x100e01b9` | | leave the menu loop (set by QUIT) | `FUN_10024f90` | HIGH |
| `0x100e01a8` | −0x6188 | display-front tracking for suspend/resume | `10022a88` | MED |

`FUN_10022ee0` has no direct caller in `callers.txt`; it is called from the jump-table case of the
event pump at `100490f8 bl 0x10022ee0` (missed by the direct-call scan). [HIGH — listing]

## 2. Main menu (`FUN_100229a0 @ 100229a0`, called from `FUN_100000a0`)

### 2.1 The button list — `FUN_10023fd0 @ 10023fd0` + `FUN_10024430 @ 10024430` [HIGH]
Sprites: SPR 3 `mebu` (normal), SPR 4 `mebh` (hilited), SPR 5 `galo` (logo), each loaded with
`FUN_1001f950(1, id, 0)` (listing `10024034/44/54 li r3,3/4/5; bl 0x10020200`). Buttons are added
in this order by `FUN_10024430(text, id, type, normalSpr, hiliteSpr, frame)`:

| list idx | id | type | content | `mebu` frame → label (sheet) | condition |
|---|---|---|---|---|---|
| 0 | 0 | 1 logo | SPR 5 `galo` frame 0 | game logo | always |
| 1 | 1 | 0 sprite | `mebu`/`mebh` | 0 → **1 PLAYER** | always |
| 2 | 2 | 0 | | 1 → **2 PLAYER** | always |
| 3 | 3 | 0 | | 2 → **PREFERENCES** | always |
| 4 | 4 | 0 | | 4 → **SCORES** | always |
| 5 | 5 | 0 | | 5 → **DEMOS** | always |
| 6 | 6 | 0 | | 6 → **QUIT** | always |
| 7 | 7 | 0 | | 7 → **REGISTER** | only if `0x100e01b4 == 0` (unregistered) |
| 7/8 | 8 | 2 web link | text = `inte` line 0 `WWW.DEIMOSRISING.COM` | — | always |
| 8/9 | 9 | 3 copyright | text = decoded string at `0x100e8dcf`: `COPYRIGHT 2001-2003 SWOOP SOFTWARE & AMBROSIA SOFTWARE, INC.` | — | always |

Sheet frames 3 CONTROLS, 8 PURCHASE, 9 EDITOR are not used by the menu; 10–13 START / NO ACCESS /
`<` / `>` are the level-select frames (flli 96–99). The labels are read off the GIF (row-major
frame order assumed = sprite frame index; consistent with flli 96–99 = 12/10/11/13). [frames HIGH
from the listing args; labels MED — image + frame-order assumption]
Note: the `inte` line 1 copyright (`…2001-2002…`) is loaded but the menu draws the hard-coded
2001-2003 string. [HIGH]

Button struct (0x124 bytes, `FUN_10024430` stores at `10024498…1002450c`): `+0x000` id (u8);
`+0x001` text (≤255, text buttons; `+0x100` = 0); `+0x104/+0x108/+0x10c/+0x110` hit rect top/
left/bottom/right (written by `FUN_1000da50` when the elements are built; compared in
`FUN_10024530` `100245dc lwz r0,0x108(r4)` vs mouse h, `0x104` vs v); `+0x114` normal sprite,
`+0x118` hilite sprite, `+0x11c` frame (text buttons: `'none','none',0`); `+0x120` hilited;
`+0x121` dirty (initial 1); `+0x122` type. [HIGH — listing]

### 2.2 Layout — `FUN_10025420 @ 10025420` (rebuilds the element list each redraw) [HIGH]
Per button (list index `i`), one text-settings element with format by type and state:

| type | normal format | hilited format | position |
|---|---|---|---|
| 0 sprite | FMT 5 `inbn`, sprite `+0x114`, frame `+0x11c` | FMT 6 `inbh`, sprite `+0x118` | x = F52/2 = **320**, y = F62 + i·F63 = **168 + 30·i** |
| 1 logo | FMT 7 `ingl` (both states, normal sprite) | same | x = 320, y from `ingl` `#Loc_Y_INT` **101** |
| 2 web | FMT 1 `inwe` (blend 12) | FMT 2 `inwh` (blend 0, colorise white) | from format: centred, y **426**, small font |
| 3 copyright | FMT 3 `inco` (blend 12) | FMT 4 `inch` (blend 0, colorise) | centred, y **447**, small font |

Listing: `100255a0 stw r3,0x100(r25)` with `r3 = F52/2` (`rlwinm …,1,31,31; add; srawi r3,r3,1`),
`100255a4 stw r0,0x104(r25)` with `r0 = r29 + r27·r28` (r29 = F62 = 168, r28 = F63 = 30,
r27 = list index). The y counts the logo (index 0), so 1 PLAYER is centred at y 198, 2 PLAYER 228,
PREFERENCES 258, SCORES 288, DEMOS 318, QUIT 348, REGISTER 378. Sprites are drawn centred on
(x, y) and the hit rect is the sprite frame's bounds centred there (`FUN_1000da50`: `left = x −
w/2`, `top = y − h/2`); text buttons use the text bounds (`FUN_1000d260`). Hilite = `inbh`
(`#ColoriseColor_RGB <ff0000>` with `Colorise_Do FALSE` — the visible change is the `mebh` sheet).
[HIGH for the arithmetic and indices; tefo values HIGH — file bytes]

### 2.3 Entry sequence
`FUN_100229a0` start: `t0 = TickCount`; clear `b8`, `b9`; registration check (`FUN_10010e60`,
`FUN_10010f90` → `b4`); `FUN_10025330` (fresh progress list); `FUN_10023380` (load the 28 `inte`
strings into a 28×256 table at `PTR_DAT_100df288`; listing loop bound `0x1c`); `FUN_10023fd0`;
`FUN_10025420`; `FlushEvents`; `FUN_10023410` (draw menu: menu bar `GetNewMBar(128)`, TGA `back`
into both screen buffers +0x68/+0x6c, unhilite all, **fade the element list in** `FUN_10025840`,
redraw); present; show cursor; `b6 = 0` (the boot's `inmu` keeps playing). [HIGH for order — dump;
MED for callee roles outside the range]

### 2.4 Idle loop (every pass, while not suspended `b7 == 0`) [HIGH unless noted]
1. `b8` set → `FUN_10024f90` (QUIT: click SND 2, hilite QUIT for F61 = 10 ticks, then `b9 = 1`).
2. **Copyright flip**: if `TickCount > t0 + F68` (240; listing `10022ad8 li r3,0x44`,
   `10022afc cmplw r3,r25; ble`) toggle and restart: odd flips set button 9's text to the
   registration banner (`FUN_10010e90` → pgsl 33 `THIS COPY IS UNREGISTERED`, or 34/35
   `REGISTERED TO %s [%i COPIES]` / `THIS COPY IS REGISTERED TO %s`), even flips back to the
   copyright string; redraw. So copyright 240 ticks → banner 240 ticks → … (first flip at 240).
3. Music service `FUN_10047f50`; if `b6`: `b6 = 0`, `t0 = now`, then if music is still playing →
   resume (`FUN_10048220(0)`), else start `inmu` looped (`FUN_10047f90('inmu',1,0)`).
4. Hover (only when `b8 == 0`): `GetMouse`; if the mouse is NOT inside the screen rect
   `+0x50..+0x5c` (unidentified, set in `FUN_1000ae20`; NR 2) → `FUN_10024530(mouse)`: for each
   button, inside its rect → `+0x120 = 1` and on the **transition** into hilite play SND 11
   `InterfaceMenuButtonRollover` `mbro` with args (0x4b, 100, 0) — not for the logo (type 1);
   outside → unhilite. Returns the id under the mouse or −1.
5. `FUN_10024810(0)`: if any button dirty → restore background (+0x6c → +0x68), rebuild elements,
   draw, present.
6. One event from `FUN_10048f30` (§2.5) and dispatch (§2.6).
On `b9`: present, fade the elements out (`FUN_10025890`), free lists, stop music with fade
(`FUN_10048120(1)`: fade 1000, wait ≤ 600 ticks for it); registered → return to shutdown;
unregistered → screen fade to black (33 ticks) and the advert `FUN_10025970(0)` (§5.3), then
return. [HIGH — dump + listing]

### 2.5 Event pump `FUN_10048f30 @ 10048f30` (jump table `*(r2−0x6da0)` = `0x100f0384`) [HIGH]
`GetNextEvent(everyEvent)`, `DSpProcessEvent`, then by `what` (table read from the data image):

| what | case | returns | meaning |
|---|---|---|---|
| 1 mouseDown | `10049028` → `FUN_10049910` | 2, sub = FindWindow class | inContent → sub 2 + local point; inMenuBar → `MenuSelect` → sub 1 + item code from `FUN_10049370`; inSysWindow → `SystemClick`; inDrag → drag window |
| 3 keyDown, 5 autoKey | `10049044` | 4 + charCode, or 5 + item | Command held (`modifiers` bit 8) → `MenuKey`, hilite menu 5 ticks (`10049080 li r3,5; bl 0x10049820`), item code; else charCode (low byte of `message`, sign-extended) |
| 6 update | `10048fd4` | 3 | redraw/present unless suspended |
| 15 osEvt | `100490c0` | 6 resume / 7 suspend | suspendResumeMessage bit 0 |
| 23 high-level | `100490ec` | 8 if `b8` set after `AEProcessAppleEvent` | Quit AppleEvent |
| others | | 0 | |

`FUN_10049370(menu, item)`: Apple menu 128 item 1 (About) → 1; other Apple items → `OpenDeskAcc`;
menu 2000 (File) item 1 → 2. [HIGH — read]

### 2.6 Dispatch in `FUN_100229a0` [HIGH]
- 2/sub 1 or 5 (menu): `FUN_10023330(code)`: 1 → `FUN_10025060` (credits — "About"), 2 → `b8 = 1`.
- 2/sub 2 (click in content): only if `b8 == 0`: id = `FUN_10024530(point)`; if id ≠ −1 and
  `FUN_10024a50(id)` (track) returns 1 → reset `t0` and act (§2.7).
  `FUN_10024a50`: plays SND 2 `InterfaceClick` `incl` (0x4b, 100, 0) unless the button is the
  logo, then while `StillDown`: hilite the button when the mouse is inside its rect, unhilite all
  otherwise, redraw; on release unhilite all; returns "released inside".
- 4 (key): `FUN_10023b00(char)`, reset `t0`.
- 6 resume → `FUN_10023e10`; 7 suspend → `FUN_10023da0`; both reset `t0`.
- 8 (quit AE): if suspended resume, then `b8 = 1`.

### 2.7 Button actions [HIGH — dump; mode meaning MED via `FUN_100069b0`]
| id | label | action |
|---|---|---|
| 0 | logo | nothing (case 0 `break`) |
| 1 | 1 PLAYER | `FUN_10024d80` → `FUN_100234d0(0, 1)` (§3) |
| 2 | 2 PLAYER | `FUN_10024db0` → `FUN_100234d0(0, 2)` |
| 3 | PREFERENCES | `FUN_10024e40` → configuration dialog `FUN_100047c0(0)`, then `b6 = 1` |
| 4 | SCORES | if **Option** (key 0x3a) is down: suspend, alert `FUN_100498e0(inte 24 "Erase High Scores", 25 "Are you sure…", 26 "Erase", 27 "Cancel")`; Erase → `FUN_10004ae0` (default table, engine-loop.md §10); resume. Then `FUN_10024e70` (scores screen §4.1) |
| 5 | DEMOS | `FUN_10024de0` → `FUN_100234d0(2, 1)`: play the next film whose name contains `Demo` (cycling counter `G+0x24`, wraps) |
| 6 | QUIT | `b9 = 1` (leave menu) |
| 7 | REGISTER | `FUN_10025190`: fullscreen → suspend display (DSp state 2) else `FUN_10049870`; registration dialog `FUN_10010e00(…,1)`; resume if frontmost |
| 8 | web link | `FUN_10025270`: suspend; alert (inte 20 "Visit the Deimos Rising Website Now?", 21, 22 "Launch", 23 "Cancel"); Launch → `ICLaunchURL(inte 19 "www.deimosrising.com")` (stays suspended until the OS resume event); Cancel → resume |
| 9 | copyright | `FUN_10025060` → credits `FUN_10025b90('cred')` (§6) |
The guide's "hold down the Option key and click on the Scores button" matches id 4 (cite). The
Option check is only on the mouse path: the S/H keys open the scores without the erase prompt.

### 2.8 Keyboard (`FUN_10023b00 @ 10023b00`, charCode) [HIGH — listing `10023b10…10023c14`]
Every recognised key first plays SND 2 (0x4b, 100, 0), then `FUN_100246c0(id)`: if the button
exists, unhilite all, hilite it, redraw, **busy-wait F61 = 10 ticks** (`10024700 li r3,0x3d`,
`FUN_10049820`), unhilite, redraw — then the action.
| keys | action |
|---|---|
| `1`, `N`, `n`, Return (0x0d), 0x0a | 1 PLAYER |
| `2` | 2 PLAYER |
| `P`, `p` | PREFERENCES (then `FUN_10025920(char)` — no-op for these chars) |
| `H`, `h`, `S`, `s` | SCORES (no Option/erase check) |
| `D`, `d` | DEMOS |
| `R`, `r` | REGISTER, only if button 7 exists |
| `F`, `f` | click sound, **no button flash**, `FUN_100234d0(1, 1)` = replay the film `last` (the previous game; `FUN_100069b0` uses tag `'last'` when mode ≠ 2) — undocumented key |
| `Q`, `q` | `b8 = 1` (no sound here; the QUIT flash + click come from §2.4 step 1) |
| charCode 0x9D (−0x63) | `FUN_10047990`: sound volume (int pref 0) −10, floor 0 |
| charCode 0x8A (−0x76) | `FUN_10047a30`: volume +10, cap 100 |
| `O`, `o`, Esc, arrows, anything else | nothing |
There is no keyboard focus/arrow navigation and no Esc action on the main menu. Command-keys go
to the menus (§2.5). Which physical keys yield 0x9D/0x8A is NR 3.

## 3. Start game and return to menu — `FUN_100234d0 @ 100234d0 (mode, players)`
mode 0 = normal (players 1/2), 1 = replay `last` (F key), 2 = demo film. [HIGH for the branch
structure — dump + listing call order `10023518…10023a98`]
1. Clear the 8-byte start record; record `+5` = mode; normal: `+4` = players, pause music
   (`FUN_10048220(1)`).
2. Disable Apple▸About (`FUN_10049320(0)`), present, hide cursor, **fade the menu elements out**
   (`FUN_10025890`, 32 steps × F160), play SND 3 `InterfaceTransition` `tran` (0x4b, 100, 1)
   (`10023560`), **screen fade to black** `FUN_1000b9a0(scr,0)` (33 ticks).
3. Normal only: stop music (`FUN_10048120(0)`), start `ammu` looped (`100235a8 lis r3,0x616d`),
   `FUN_1004a990(0)`, **level selection** `FUN_1002e310(&sector)` (§7). `'none'` (Esc) → no game:
   stop music, skip to step 6. Else record `+0` = level ID; `startedLater = sector > 1`.
4. `FUN_100051a0(&record, result)` (game). Afterwards: result `[0x16]` (unregistered cut-off) →
   fade to black (interlaced variant, 33 ticks) and the advert **with** the F67 minimum (§5.3).
5. If not quitting (`b8 == 0`) and no cheat (`[0x15]`): best-sector → int pref 3 (normal mode,
   `!startedLater`; arithmetic in scoring-bonuses.md §9.2); flag "some present player beats the
   15th score" (`FUN_10021470`).
6. If a game ran: fade to black (33 ticks). Draw `back` into both buffers, **fade in**
   `FUN_1000ba70(scr,0)` (9 ticks).
7a. High-score path (normal, `!startedLater`, no quit, no cheat, a qualifier): SND 3 (0x32, 100,
   1), FlushEvents, re-enable About, **`FUN_100214c0`** (inserts rows, then name entry per
   player, §4.2), show cursor, rebuild the menu (menu bar, `back`, unhilite, element fade-in 32
   steps, redraw, present), FlushEvents, `b6 = 1`.
7b. Otherwise: `back` again, present, normal mode → SND 3 (0x32, 100, 1); menu bar, `back`,
   unhilite, element fade-in, redraw, enable About, show cursor; normal mode → `b6 = 1`.
`b6 = 1` makes the next menu pass resume or restart `inmu` (§2.4 step 3). Film/demo modes never
set `b6` and never stop the menu music in this function (NR 4). Game-over itself (notice, F13 =
110 ticks) is inside the game loop (engine-loop.md §3); the front end only sees the return.

## 4. High scores (G_Scores.cc)

### 4.1 Scores screen `FUN_10021950 @ 10021950` (from SCORES, `FUN_10024e70`) [HIGH]
Clear +0x68 to black (fill constant at `0x100d6e20` = 0), draw `back` into both buffers, copy the
prefs (`FUN_10004c30`), build the list `FUN_100222f0(list, prefs, edit=0, dim=0, slot=0, player=−1)`,
draw (`FUN_1000d7f0(list,0,0)`), present — **no fade in**. Loop: music service; exit when
`TickCount > start + F78` (600; `10021ab4 li r3,0x4e`); events via `FUN_10048c90` (1 mouseDown,
2 keyDown, 3 autoKey, 4 update): update → present; mouseDown → exit (silent); key → exit, and
`N`/`n` → SND 2 (0x32, 100, 1) and return 1 → `FUN_10024e70` calls `FUN_100234d0(0,1)` (straight
into a 1-player game). On exit: restore +0x6c → +0x68, present, free; `FUN_10024e70` then redraws
the menu (menu bar, `back`, unhilite, element fade-in 32 steps). F77 is read at the top and
discarded (also read by the layout). [HIGH]

### 4.2 Layout `FUN_100222f0 @ 100222f0 (list, prefs, edit, dim, slot, player)` [HIGH]
Headers: FMT 10 `scnt` "Name" (x 110, y 83, left), FMT 11 `scst` "Score" (x 377, right), FMT 12
`sset` "Sector" (x 463, left) — strings at `0x100e8ba1/ba6/bac`. Then 15 rows, `rowY = F77 (107)`,
`rowY += F76 (19)` per row (`10022838 li r3,0x4c`), 4 elements per row (list item 3 + 4·row is the
symbol, 4 + 4·row the name):
- symbol: template text-settings at `0x100e8964` (face `none`); only the row being edited gets the
  player's ship face (gaob 0/1 Player 1/2 → player def `+0x28` face, `+0x2c` frame), at x = F80
  (73), y = rowY + F81 (7).
- name `prefs+0x10f8+21·row`, score `"%i"` of `prefs+0x1260+4·row`, sector name
  `prefs+0x12d8+32·row`; y = rowY; x from the formats (110 / 377 right-aligned monospaced / 463).
- format choice: edited row → hilite (FMT 14 `scph`, 17 `scsh`, 20 `sseh`: colorise `00ffff`);
  other rows → `dim` arg ? Dim (15/18/21) : Normal (13/16/19). Dim and Normal formats are
  byte-identical in the data (no colorise), so dimming is invisible in 1.0.6.
Row 0 is at y 107, row 14 at y 373 (107 + 14·19). [HIGH — listing indices + tefo bytes]

### 4.3 Name entry `FUN_10021bd0 @ 10021bd0 (player, slot, prefs, fromGame)` [HIGH]
Called only by `FUN_100214c0` with `fromGame = 1`, **player 1 first, then player 2**, each only if
that player qualified (`10021bd0(0,slot1,…)` then `(1,slot2,…)`; slots computed in one pass, a
tie-shift moves the lower-placed entry down; scoring-bonuses.md §9.2). Each call is a full screen:
1. Clear to black, draw `back`; seed the table name with the player's remembered name
   (`prefs+0x1233+21·player`, default "Player %i"); edit buffer = first 20 chars.
2. Build the list with `edit = 1, dim = 1, slot, player`; draw; present (no fade). Play SND 9
   `HighScoreAchieved` (`none` → silent) (0x32, 100, 1).
3. Loop (no time limit while editing):
   - cursor blink: when `now > lastKey + F82 (30)` **and** `now > lastFlip + F83 (10)` toggle;
     while shown and length < 20, the displayed name gets pgsl 7 `_` appended. Any key hides it.
   - keys (charCode, listing `10021ebc…10021ef4`): Return 0x0d or 0x0a → confirm; Backspace 0x08
     → delete last char + SND 2 (if non-empty); any char whose MSL ctype has a bit of 0xdc
     (upper 0x80, lower 0x40, digit 0x10, punct 0x08, space 0x04 — table `0x100f0f94` checked:
     'A' 0xa0, 'a' 0x60, '0' 0x30, '!' 0x08, ' ' 0x04, Tab 0x02, BS 0x01) → append if length < 20
     (`10022110 cmplwi r3,0x14`) with SND 0 `ButtonClick` `clic`, else SND 15 `ScoreEntryFailure`
     `shwa`. Tab, Esc, Enter (0x03), arrows: ignored silently. A compare with 0x5e5b at
     `10021ef4` can never match a sign-extended byte (dead code). Mouse clicks are ignored while
     editing.
   - confirm: SND 4 `CommandConfirmation` `incl`; uppercase copy; easter eggs by substring:
     `BIKI` → "Filthy Communist", `DILVISH` → "Just Ship It, Baby", `SUPERCOBRA` → "Munkis Rool
     J00", `PYTHOS` → "Leonard Cohen Rules J00", `FISJ` → "Daikajinn!!" (checked in that order,
     the last match wins); empty → "Jar Jar Must Die". Rebuild with `edit = 0, dim = 1` (row
     loses hilite and ship), store the name in the table and as the player's remembered name.
   - after confirm: exit on any key or click, or when `now > confirmTime + (fromGame ? F79 (25) :
     F78 (600))` — i.e. 25 ticks in practice.
4. Exit: free the image; if confirmed, **save prefs** `FUN_100047f0(prefs)`; restore +0x6c →
   +0x68; present.
So in a 2-player game where both qualify: P1 screen (P1's row cyan + P1 ship), confirm, 25 ticks,
P2 screen (P2's row, P2 ship), confirm, 25 ticks, then the menu (§3 step 7a).

## 5. Transitions and fades

### 5.1 Screen fades (M_Display, outside the range; listing `disasm-w2s9b.txt`) [HIGH]
- `FUN_1000b9a0(scr, interlaced)` **fade to black**: levels 32 → 0 (`1000b9cc li r27,0x20`,
  `1000ba50 subic. r27,r27,1; bge`), 33 presents, each at least one tick after the previous
  (`1000ba34 addi r31,r31,1; …cmplw; blt`) ⇒ **≈33 ticks**. Blend `FUN_1001ec80(dst, rect, 0,
  level)`: `pixel·level + 0·(32−level)` per 5-bit channel (decompile) → black at 0.
- `FUN_1000ba70(scr, interlaced)` **fade in from black**: levels 0, 4, …, 32 (`1000bad4 li r25,0`,
  `1000bb70 addi r25,r25,4`, `1000bb74 cmpwi r25,0x20; ble`) ⇒ 9 presents ≈ **9 ticks**.
  [steps HIGH; direction MED — `FUN_1001e9d0` blend not read]

### 5.2 Element (text/sprite list) fades — G_Text, rate F160 `Interface_FadeRate` = 1 [MED]
`FUN_1000db90(list, rate)` fade in: blend 31 → 0 over 32 steps, `rate` ticks apart; `FUN_1000df00`
fade out: blend 1 → 32 over 32 steps. With F160 = 1 ⇒ **≈32 ticks** each. Wrappers in range:
`FUN_10025840` (menu fade in), `FUN_10025890` (menu fade out), `FUN_100232d0` (loading lines fade
out). [counts read in the decompile + `1000dbd0 li r25,0x20`, `1000df64 cmplwi r25,0x20`; MED
because G_Text is out of scope]

### 5.3 Advertisement `FUN_10025970 @ 10025970 (enforceDelay)` [HIGH]
Shown only to unregistered copies: on QUIT from the menu (`enforceDelay = 0`) and after a game
that hit the unregistered cut-off (`enforceDelay = 1`). Clear to black, draw TGA `adve`
(`0x61647665`), fade in (9 ticks), show cursor; if `enforceDelay`: busy-wait until `start + F67`
(240 ticks, `10025a2c li r3,0x43`; `start` taken before the fade); FlushEvents (input during the
wait is discarded); then wait for mouseDown or keyDown (`FUN_10048c90` 1/2) → SND 2 (0x4b, 100, 0);
fade to black (33 ticks).

### 5.4 Sounds used by the front end [HIGH for ids/args; meaning of args = INDEX #11]
| SND | key | tag | where | args |
|---|---|---|---|---|
| 0 | ButtonClick | `clic` | name-entry char accepted | 0x32,100,1 |
| 2 | InterfaceClick | `incl` | menu click/keys, advert, credits exit, scores `N`, backspace | 0x4b,100,0 (menu/advert), 0x32,100,1 (scores/credits/name) |
| 3 | InterfaceTransition | `tran` | leaving the menu to play; returning to the menu | 0x4b,100,1 out; 0x32,100,1 back |
| 4 | CommandConfirmation | `incl` | name confirmed | 0x32,100,1 |
| 8 | Paused | `incl` | pause entered | 0x32,100,1 |
| 9 | HighScoreAchieved | `none` | name-entry start (silent) | 0x32,100,1 |
| 10 | Registered | `leen` | registration detected on resume | 0x4b,100,1 |
| 11 | InterfaceMenuButtonRollover | `mbro` | hover enters a button | 0x4b,100,0 |
| 15 | ScoreEntryFailure | `shwa` | name full (20) | 0x32,100,1 |
Music: `inmu` (menu, boot), `ammu` (level select), stop-with-fade `FUN_10048120(1)` on QUIT.

## 6. Credits `FUN_10025b90 @ 10025b90 ('cred')` — paged, not scrolled [HIGH]
Clear to black (constant `0x100d6ea0` = 0), draw `back`, copy a 640×480 band (F52 × F53) to the
back buffer, present. Pages from `stli Attributions[cred]`: per page, lines are read until a
line containing `<page ` (`_DAT_100e01c0` → `0x100e9130`); its number after the first space
(ctype bit 0x04) up to `>` is parsed with `"%i"` (`0x100e9158`) as this page's **display time in
ticks**. A line containing `<title>` (`0x100e9128`) uses FMT 8 `crti` (colorise `00ffbd`) with the
text after the tag; others FMT 9 `crno`; all left-aligned at x 120 (format), y = F74 (130) +
F75 (16)·lineIndex (reset each page). Cycle: page shown → when its time is up: fade out (32 steps ×
F160), free, **wait 60 ticks** (`10025d50 li r3,0x3c; bl 0x10049820`), build next page, fade in
(32 steps), restart the timer. The first page has time 0, so it appears after the 60-tick wait.
After the last page times out → exit. Input (`FUN_10048c90`): mouseDown → SND 2 (0x32,100,1),
exit; any key → SND 2 and exit, `N`/`n` → return 1 (caller `FUN_10025060` starts a 1-player game).
Exit fades the page out. Page times in the file: 200, 210, 120, 120, … (first four `<page>`
lines). [HIGH — listing indices F74/F75/F160/0x3c, strings from the image, file bytes]

## 7. Level selection (front-end view; internals in scoring-bonuses.md §10)
- Entered only from mode 0 after the transition (§3); music `ammu`. Background TGA `lese`
  (`0x6c657365`), fade in 9 ticks (`FUN_1000ba70`), exit fade 33 ticks. [HIGH — dump]
- Three previews (the chosen sector in the middle, neighbours with wrap), x = F39 (55) + i·F41
  (191) → 55/246/437, y = F40 (76) + i·F42 (0); click rects reli 18–20 `LevSel_Button_*`
  (55,76,200,382 / 246,76,392,382 / 438,76,583,382). The preview list always starts at **sector 1**
  (`FUN_1002efb0(list, 1, …)` before the loop). Over each preview `FUN_10006240` tiles the video
  grid (§7.1). [HIGH for indices; layout claims MED via scoring-bonuses]
- Three sprite buttons from SPR 6/7 (`mebu`/`mebh`, hover → 7): `<` frame F96 12 at (F90 128, F91
  228), START frame F97 10 / NO ACCESS F98 11 (unreachable) at (F92 320, F93 228), `>` frame F99 13
  at (F94 511, F95 228); hilited scale F100 1.1. [HIGH — listing indices]
- Selectable = `sector ≤ int pref 3` (fresh prefs: 1); unregistered: sectors > 4
  (`FUN_10011b00` returns 4) show "Registration Required" (pgsl 5) instead of "Sector Not Reached"
  (pgsl 4). Per sector: preview image, name text and `"%0.2i"` number. Sounds: SND 13 `lsch` move,
  SND 12 `lsse` accept, SND 14 `lsna` refused, SND 11 hover. Esc → `'none'` (back to menu, no game).
  (scoring-bonuses.md §10.1–10.2, MED)
- **No two-player, difficulty or speed option exists in the front end**: players come from the
  menu button; no difficulty strings exist; "Game Speed …" (pgsl 24–30) is console/engine only.
  flli 86–89 (`LevelSelect_Instruction_*`) and reli 16/17 have **no consumer** (Python scan of the
  dump for `FUN_10020250(n)` / `FUN_10020220(n,`), and pgsl 1/2 are unread (scoring-bonuses §10.3):
  the instruction line was cut. [HIGH for absence of literal consumers]

### 7.1 `FUN_10006240 @ 10006240 (rect, dark, flag)` — video-grid overlay [HIGH]
Tiles sprite SPR 0 `vigr` (`10006340`) frame F84 (normal 0) or F85 (dark 1) over `rect`, clipped
to it: tile size from `FUN_10019ca0`, `cols = width/w + 1`, `rows = height/h + 1`, blit flags byte
0x0f, `flag` → blit byte +1. Only caller `FUN_1002f7a0` (preview button) passes `dark = 0`, so the
dark frame is never used.

## 8. Pause — `FUN_10022ef0 @ 10022ef0 (presentMode, hideCursor)` [HIGH — listing]
Called from the frame controller's `FUN_10030870` when Caps Lock started a pause (begin frame
`FUN_10030360` shows pgsl 0 "Press Caps Lock"; engine-loop.md §4). Sets `b5`, FlushEvents,
`FUN_100476a0` (sound halt — MED), SND 8 `Paused` `incl` (0x32,100,1), pauses music. Then a tight
poll with **no event processing**: leave when Caps Lock (key 0x39) is up and the app is not
suspended; the loop also ends if `b8` was already set (returns 1 → controller `+2` = quit).
On a normal resume: resume music; `hideCursor` (always 0 from the controller); present interlaced
if `presentMode == 1`, normal if 0; clear `b5`. No resume sound. `FUN_10030870` then calls
`FUN_100181e0(0, FUN_10005ce0())` (MED, not read).

## 9. Loading-progress lines (boot) [MED]
`FUN_10023040 @ 10023040 (text, newLine, fadeIn)` — callers `FUN_1001fe60`, `FUN_1002ab20`,
`FUN_10039280`, `FUN_1003d0a0` (permanent images/sounds, units, weapons, players): append a line
(FMT 0 `prog`: x 50, base y 100, small, left) when the list is empty or `newLine`, blend start
0x20; each line i at y = base + i·F64 (20) (`100231ac li r3,0x40`); the last line gets `text`,
faded in when `fadeIn`, else drawn; present. `FUN_100232d0` (boot end) fades the lines out
(32 × F160) and frees them. F65 `Interface_Progress_MinTimeBetweenBlocks` has **no consumer**.

## 10. Function census
| function | lines | role | label |
|---|---|---|---|
| `FUN_10021950` | 78 | scores screen (600-tick view, `N` → game) | HIGH |
| `FUN_10021bd0` | 225 | name entry for one player | HIGH |
| `FUN_100222f0` | 213 | scores list layout | HIGH |
| `FUN_10022880` | 16 | free all items of a list | HIGH |
| `FUN_100228d0` | 31 | static init of the scores symbol template (`0x100e8964`) | LOW |
| `FUN_100229a0` | 227 | main menu loop | HIGH |
| `FUN_10022ed0` / `FUN_10022ee0` | 10/9 | set / get quit request `b8` | HIGH |
| `FUN_10022ef0` | 48 | pause screen | HIGH |
| `FUN_10023030` | 9 | get suspended `b7` | HIGH |
| `FUN_10023040` | 90 | loading progress line | MED |
| `FUN_100232d0` | 18 | fade out + free progress lines | HIGH |
| `FUN_10023330` | 15 | menu command (1 About → credits, 2 Quit) | HIGH |
| `FUN_10023380` | 28 | load 28 `inte` strings | HIGH |
| `FUN_10023410` | 25 | draw the menu (menubar, `back`, element fade-in) | HIGH |
| `FUN_100234d0` | 186 | start game / return to menu | HIGH (structure) |
| `FUN_10023b00` | 151 | menu key handler | HIGH |
| `FUN_10023da0` / `FUN_10023e10` | 22/54 | suspend / resume (+ registration detection, SND 10) | MED |
| `FUN_10023fd0` | 60 | build the button list | HIGH |
| `FUN_10024280` | 33 | remove button by id | HIGH |
| `FUN_10024360` | 33 | free the button list | HIGH |
| `FUN_10024430` | 40 | add button | HIGH |
| `FUN_10024530` | 62 | hover hit-test + rollover sound | HIGH |
| `FUN_100246c0` | 22 | keyboard button flash (F61) | HIGH |
| `FUN_10024750` | 27 | button exists? | HIGH |
| `FUN_10024810` | 40 | redraw if any button dirty | HIGH |
| `FUN_10024900` / `FUN_10024a00` | 35/16 | set hilite of one / all buttons | HIGH |
| `FUN_10024a50` | 94 | click tracking | HIGH |
| `FUN_10024cb0` | 38 | set button text | HIGH |
| `FUN_10024d80/db0/de0/e10` | 10 | 1P / 2P / demo / replay-last | HIGH |
| `FUN_10024e40` | 10 | preferences dialog | MED |
| `FUN_10024e70` | 39 | scores action + menu redraw | HIGH |
| `FUN_10024f90` | 31 | QUIT flash, leave menu | HIGH |
| `FUN_10025060` | 39 | credits action + menu redraw | HIGH |
| `FUN_10025190` | 37 | register action | MED |
| `FUN_10025270` | 32 | web-link action | MED |
| `FUN_10025330` / `FUN_100253d0` | 28/16 | new / clear progress list | HIGH |
| `FUN_10025420` | 116 | build menu elements (layout) | HIGH |
| `FUN_10025770` | 33 | free element list | HIGH |
| `FUN_10025840` / `FUN_10025890` | 17 | element fade in / out (F160) | HIGH |
| `FUN_100258e0` | 14 | draw element list | HIGH |
| `FUN_10025920` | 15 | volume keys 0x9D / 0x8A | HIGH (keys NR) |
| `FUN_10025970` | 51 | advertisement | HIGH |
| `FUN_10025b00` | 25 | static init (credits globals) | LOW |
| `FUN_10025b90` | 185 | credits | HIGH |
| `FUN_100260b0` | 16 | free list items | HIGH |
| `FUN_10006240` | 110 | video-grid overlay | HIGH |
| `FUN_10030020`, `FUN_10030e70` | 36/43 | static inits (level-select / score-bar globals) | LOW (read) |
| `FUN_100301d0`, `FUN_100302b0`, `FUN_10030350`, `FUN_10030900` | | controller destructor / end session (FlushEvents) / frame counter / paused byte | MED (read) |
| `FUN_100302e0` | 15 | between-level reset (scoring-bonuses §10.4) | MED (read) |
| `FUN_10030df0` | 25 | **frame-controller state reset** (see rows) | HIGH |
| `FUN_10030f40` | 135 | score-bar init: resource group "Score Bar", 2×0x14c, reli 0–7/8–15 + screen-offset copies, faces `none` | MED (read) |
| `FUN_100313b0` | 13 | release "Score Bar" group | LOW (read) |
| `FUN_10030190…FUN_10030bc0` (frame controller) | | engine-loop.md §4 | not re-read (only `FUN_10030870` read) |

## Worked example — cold start → main menu → 1-player game at sector 1
Boot (engine-loop.md §2 order; fade lengths from §5.1): 5-tick wait; fade to black 33; publisher
logo `pucr` + `publ` (unless Command held); fade in 9; hold until `publ` ends, or until 130 ticks
(F66) after the timestamp taken before the fade-in; fade to black 33; developer logo, `inmu`
starts; fade in 9; hold to 240 ticks after its timestamp; fade to black 33; `back` loading screen,
fade in 9; progress lines (x 50, y 100, 120, 140 … ); lines fade out ≈32 ticks (`FUN_100232d0`).
Menu (`FUN_100229a0`): `back` redrawn, the elements fade in ≈32 ticks: logo (y 101), 1 PLAYER
198, 2 PLAYER 228, PREFERENCES 258, SCORES 288, DEMOS 318, QUIT 348, REGISTER 378 (unregistered),
`WWW.DEIMOSRISING.COM` y 426, `COPYRIGHT 2001-2003 …` y 447; at tick 240 the copyright line flips
to `THIS COPY IS UNREGISTERED` (or `THIS COPY IS REGISTERED TO …`), back at 480, … `inmu` loops.
Mouse moves onto 1 PLAYER (rect = frame-0 bounds centred on 320,198) → `mebh` frame 0 + SND 11
`mbro`. Mouse down → SND 2 `incl`; release inside → `FUN_100234d0(0,1)`. (Keyboard `1`/`N`/Return
instead: SND 2, 10-tick hilite, same call.)
Start: music paused; menu elements fade out ≈32 ticks; SND 3 `tran`; fade to black 33; music
stopped, `ammu` starts; level selection: `lese` + previews (left = sector 12 Carthage by wrap,
middle = sector 1 Mariner Valley, right = sector 2 Cydonia Plateau), fade in 9 ticks; fresh
prefs (pref 3 = 1) ⇒ START (frame 10) shown. Fire/Return/click middle → SND 12 `lsse`, accept
flash (F44/F45), fade to black 33; returns level ID of le07 (`Lucena`), `sector = 1`.
Game: `FUN_100051a0({le07, players 1, mode 0})`, 3 lives (start sector 1). On game over (110-tick
notice) control returns: score > 15th entry (1000 by default) → fade to black 33, `back` fade in 9,
SND 3, name screen (row cyan + ship 1, cursor `_` blinking every 10 ticks after 30 idle), Return →
SND 4, 25 ticks, prefs saved; menu rebuilt with element fade-in ≈32, `inmu` restarted. Approximate
dead time from the click to the level-select screen being live: 32 + 33 + 9 ≈ 74 ticks (1.2 s).

## NOT RESOLVED (this file)
1. Physical keys for charCodes 0x9D / 0x8A (menu volume −/+ in `FUN_10025920`); settle by testing
   the original or reading the KCHR in use (they are Mac Roman `ù` / `ä`).
2. The screen rect `+0x50..+0x5c` that suppresses menu hover while the mouse is inside it (set in
   `FUN_1000ae20` from locals and `+0x60`); read `FUN_1000ae20`.
3. Direction of `FUN_1000ba70`'s blend (`FUN_1001e9d0` unread): assumed black → image.
4. Music after a demo/replay: `FUN_100234d0` neither stops `inmu` nor sets `b6` in modes 1/2;
   whether level music keeps playing on the menu afterwards depends on `FUN_100051a0`'s music
   calls.
5. Semantics of the sound args (0x4b|0x32, 100, 0|1) — INDEX #11.
6. Developer-logo draw (`FUN_10044c30(1000)` in boot) and `FUN_100476a0` (pause sound halt) not
   read.
7. Whether erasing high scores (Option+SCORES) is saved immediately: `FUN_10004ae0` writes the live
   prefs, no save call in `FUN_100229a0`; settle by reading the prefs save path at quit.
8. Item labels/command-keys of menu 128/2000 (resource fork MENU not parsed); only item 1 of each
   is acted on.
9. Accept/fail flash durations in level select (F44–F47 arithmetic in `FUN_1002fcc0`, owned by
   scoring-bonuses §10).

## Role-table rows (for merge)
| `FUN_100229a0` | G_Interface.cc | main menu loop: copyright flip F68, hover, event dispatch, button actions | HIGH | listing `10022ab4…10022cb8`; front-end.md §2 |
| `FUN_100234d0` | G_Interface.cc | start game (modes 0 play / 1 replay `last` / 2 demo) + return-to-menu fades, high-score path | HIGH | listing call order `10023518…10023a98`; front-end.md §3 |
| `FUN_10023b00` | G_Interface.cc | menu keys 1/N/Return,2,P,H/S,D,R,F,Q, 0x9D/0x8A volume | HIGH | listing `10023b10…`; §2.8 |
| `FUN_10023330` | G_Interface.cc | menu command: 1 About→credits, 2 Quit | HIGH | read; §2.6 |
| `FUN_10023380` | G_Interface.cc | load 28 `inte` strings (table `PTR_DAT_100df288`, 256 B each) | HIGH | loop bound 0x1c |
| `FUN_10023410` | G_Interface.cc | draw menu (menubar, `back`, element fade-in) | HIGH | read |
| `FUN_10023da0` / `FUN_10023e10` | G_Interface.cc | suspend / resume (+ registration detect, SND 10, remove REGISTER) | MED | read |
| `FUN_10023fd0` | G_Interface.cc | build button list (logo, 1P, 2P, PREFS, SCORES, DEMOS, QUIT, [REGISTER], web, copyright) | HIGH | SPR 3/4/5 listing; §2.1 |
| `FUN_10024280` / `FUN_10024360` / `FUN_10024430` / `FUN_10024750` | G_Interface.cc | remove button / free list / add button (0x124 struct) / exists | HIGH | listing stores `10024498…1002450c` |
| `FUN_10024530` | G_Interface.cc | hover hit-test, SND 11 on hilite entry (not logo) | HIGH | `10024650 li r3,0xb` |
| `FUN_100246c0` | G_Interface.cc | key flash: hilite, wait F61 ticks | HIGH | `10024700 li r3,0x3d` |
| `FUN_10024810` / `FUN_10024900` / `FUN_10024a00` / `FUN_10024cb0` | G_Interface.cc | redraw-if-dirty / set hilite / unhilite all / set text | HIGH | read |
| `FUN_10024a50` | G_Interface.cc | click tracking (SND 2, StillDown loop, released-inside) | HIGH | `10024b30` |
| `FUN_10024d80` / `db0` / `de0` / `e10` | G_Interface.cc | `FUN_100234d0(0,1)` / `(0,2)` / `(2,1)` demo / `(1,1)` replay last | HIGH | read |
| `FUN_10024e40` | G_Interface.cc | PREFERENCES → `FUN_100047c0(0)`, `b6 = 1` | MED | read |
| `FUN_10024e70` / `FUN_10025060` | G_Interface.cc | SCORES / credits action, `N` → 1P game, menu redraw | HIGH | read |
| `FUN_10024f90` | G_Interface.cc | QUIT flash, leave menu | HIGH | `10025008 li r3,0x3d` |
| `FUN_10025190` / `FUN_10025270` | G_Interface.cc | REGISTER / web-link (inte 19–23, ICLaunchURL) | MED | read |
| `FUN_10025330` / `FUN_100253d0` / `FUN_100232d0` | G_Interface.cc | progress list new / clear / fade-out F160 | HIGH | `100232ec li r3,0xa0` |
| `FUN_10023040` | G_Interface.cc | loading progress line (FMT 0, F64 spacing) | MED | `100231ac li r3,0x40` |
| `FUN_10025420` | G_Interface.cc | menu elements: x F52/2, y F62 + i·F63; FMT 1–7 by type/hilite | HIGH | `10025574…100255a4` |
| `FUN_10025770` / `FUN_10025840` / `FUN_10025890` / `FUN_100258e0` | G_Interface.cc | free / fade in / fade out / draw element list | HIGH | F160 listing |
| `FUN_10025920` | G_Interface.cc | volume −10 / +10 on charCode 0x9D / 0x8A | HIGH | listing `1002592c` |
| `FUN_10025970` | G_Interface.cc | advert `adve`; F67 minimum when after a cut-off game; click/key exit | HIGH | `10025a2c li r3,0x43` |
| `FUN_10025b90` | G_Credits.cc | paged credits: `<page N>` ticks, `<title>`, F74/F75, 60-tick gap | HIGH | listing `10025d50 li r3,0x3c` |
| `FUN_10025b00` / `FUN_100228d0` | | static initialisers | LOW | caller `FUN_10000000` |
| `FUN_10021950` | G_Scores.cc | scores screen: 600 ticks (F78), click/key exit, `N` → 1P game | HIGH | `10021ab4 li r3,0x4e` |
| `FUN_10021bd0` | G_Scores.cc | name entry: 20 chars, ctype 0xdc, Return, BS, blink F82/F83, linger F79, easter eggs, save prefs | HIGH | listing `10021d90…100221f4` |
| `FUN_100222f0` | G_Scores.cc | scores layout: headers FMT 10–12, 15 rows y F77+F76·r, ship symbol F80/F81, FMT 13–21 | HIGH | listing indices |
| `FUN_10022880` / `FUN_100260b0` | | free list items | HIGH | read |
| `FUN_10022ed0` / `FUN_10022ee0` / `FUN_10023030` | | set/get quit `b8`; get suspended `b7` | HIGH | `100490f8 bl 0x10022ee0` |
| `FUN_10022ef0` | ~after G_Scores | pause: SND 8, poll Caps Lock 0x39 (no events), resume music | HIGH | listing `10022f18…10023010` |
| `FUN_10048f30` | M_Application | event pump: what 1→2, 3/5→4|5, 6→3, 15→6/7, 23→8 | HIGH | table `0x100f0384` |
| `FUN_10049910` / `FUN_10049370` / `FUN_10048c90` | M_Application | mouseDown class / menu item map / simple event poll (1 click, 2 key, 3 autokey, 4 update) | HIGH | read |
| `FUN_1000b9a0` / `FUN_1000ba70` | M_Display | fade to black 33 ticks / fade in 9 ticks | HIGH (steps) | `disasm-w2s9b.txt` |
| `FUN_10006240` | | video-grid overlay (SPR 0, F84/F85) over a rect | HIGH | `10006340` |
| ⚑ corrected `FUN_10030df0` | frame controller | zero the frame-controller state (+0 paused, +2 quit, +4 interlace, +8 frames, +0x1c tick, +0x2c/+0x30 divider, +0x34 tick flag) | HIGH | stores `10030e0c…10030e54`, callers `FUN_10030190`/`FUN_10030210`; was "zero-init of a 0x35-byte struct (score-bar state?)" LOW |
| `FUN_10030f40` | G_ScoreBar.cc | score-bar init (group "Score Bar", reli 0–15, 2×0x14c) | MED | read |

## INDEX updates (for merge)
- Closes nothing in the consolidated list; adds observations to #11 (front-end arg patterns,
  §5.4).
- Proposed new items: (a) menu volume keys 0x9D/0x8A (this file NR 1); (b) hover-suppress rect
  `+0x50` (NR 2); (c) music state after demo/replay (NR 4); (d) erase-scores persistence (NR 7).
- New topical row: `front-end.md` — 1 state; 2 main menu (buttons, layout, idle, event pump,
  dispatch, actions, keys); 3 start/return flow; 4 scores + name entry; 5 fades, advert, sounds;
  6 credits; 7 level select (front view) + video grid; 8 pause; 9 loading lines; 10 census.
