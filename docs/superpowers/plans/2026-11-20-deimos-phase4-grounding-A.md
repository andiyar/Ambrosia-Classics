# P4 grounding A — the screens before a game: boot, main menu, level select, credits, fades, pause (read-only, 2026-11-20)
Sources: listing `~/Developer/Ghidra/deimos/proj/disasm-review3-all.txt` (L; the brief's `ghidra/deimos-proj/…` path does not
exist), dump `ghidra/deimos/Deimos_pef.decompiled.c` (D, line numbers `D:n`), decoded data `~/Developer/Ghidra/deimos/proj/data/Game/`,
image constants `…/proj/mem/10000000.bin`. Bank: front-end.md (FE), scoring-bonuses.md §10 (SB), engine-loop.md (EL),
text-metrics-lists.md §3 (TM), micro-wave §3.8 (MW). HIGH = L, or D with every branch read; MED = D only / inferred.
Swift paths relative to `Deimos/Core/Sources/`. "Tick" = Mac TickCount (60.15 Hz) unless "frame" is said; frame = one
frame-controller frame (FPS limiter 2 ticks, EL §4). Out of this appendix: start/return flow `FUN_100234d0`, scores,
name entry, films/attract, prefs file, configuration dialog — cited only where a screen here hands over.

## 1. Boot `FUN_100000e0` (caller `FUN_100000a0`: boot → menu `FUN_100229a0` → shutdown `FUN_10000630`)
| # | address | what happens | conf |
|---|---|---|---|
| 1 | 100000fc..1000014c | toolbox, log, managers, console, tag index, **prefs load** `FUN_10004540`, input init | HIGH |
| 2 | 1000015c / 1000016c | read **Option** (0x3A) and **Command** (0x37) once; Command held = "quiet launch" (no `publ`, no `inmu`) | HIGH |
| 3 | 10000188..100001e4 | resources, permanent lists, `FUN_10018070`, `FUN_10010cf0` (roles not read), music init (flli 37), sound init (flli 38) | HIGH order |
| 4 | 100001f0..10000228 | Option held **or** byte pref 2 == 0 (first run) → configuration dialog `FUN_100047c0(1)`, pref 2 ← 1 (other appendix) | HIGH |
| 5 | 10000230..1000029c | display `FUN_1000ae20(D, 640, 480, 16, pref 4)`; window current | HIGH |
| 6 | 100002ac | sprite manager init `FUN_10018740(0,1)` | HIGH |
| 7 | 100002c0 / 100002d4 | busy-wait **5** ticks; **fade to black** (mode 0 = full-screen present, 33 presents ≥ 1 tick apart) | HIGH |
| 8 | 100002ec..10000338 | back ← black; TGA `pucr` (260×342) **copied centred** (`FUN_1000a3b0`) → top-left (190, 69) | HIGH |
| 9 | 10000340 / 10000348 | volume up then down: int pref 0 quantised (100 → 90; ≤ 90 unchanged), pushed to the device (sound-music §4.4) | HIGH |
| 10 | 10000350..10000390 | T1 = TickCount; Command up and `publ` loaded → play `publ` (prio 0x32, vol 100, multiple 1) | HIGH |
| 11 | 100003a0 / 100003a8 | **fade in** (mode 0, 9 presents); sprite-cache policy `FUN_10018bf0` (OS X: loads every im08) | HIGH |
| 12 | 100003b0..10000404 | Command up **and** sound available → spin (music service) while the `publ` voice lives, then free it; **no 130 floor or cap**. ≈ 235,776 frames / 44.1 kHz = 5.35 s ≈ **322 ticks** after T1 | HIGH (branch) / MED (length) |
| 12′ | 10000408..10000430 | else (Command held or no sound): wait until TickCount ≥ T1 + flli 66 (**130**) | HIGH |
| 13 | 1000043c | fade to black (33) | HIGH |
| 14 | 10000454..10000474 | port = back (`FUN_10009e40`); back ← black; **PICT 1000** "Swoop Software Logo" 640×480 at (0,0) (`FUN_10044c30`) | HIGH |
| 15 | 10000480..10000494 | Command up → `inmu` play, loop 1, startPaused 0 | HIGH |
| 16 | 1000049c..100004d4 | T2 = TickCount; fade in (9); spin (music service) until TickCount ≥ T2 + **240** | HIGH |
| 17 | 100004e0..100004f0 | fade to black (33); text module init `FUN_1000d010`; message init | HIGH |
| 18 | 10000504..10000580 | back ← black; TGA `back` → back AND save buffer (D+0x68, D+0x6c); fade in (9) | HIGH |
| 19 | 10000590..100005b0+ | loaders: permanent sprites+sounds `FUN_1001fe60`, levels, units `FUN_1003cf10` → `FUN_1003d0a0(1)`, weapons `FUN_1002ab20(1)`, players `FUN_10039280(1)`, score bar, … | HIGH order |
| 20 | (end) | `FUN_100232d0`: loading lines **fade out** (32 passes, rate flli 160 = 1), freed | HIGH |
**Loading lines** (`FUN_10023040(text, newLine, fadeIn)`, D:20568; all boot calls pass fadeIn = 1): format 0 `prog` (x 50,
y 100, small, LEFT, blend 0); line i at y = 100 + 20·i (flli 64). Each call: restore the WHOLE back buffer from the save
buffer, redraw every line, present full screen. A **new** line is created with blend 0x20 and its first draw is the
one-element fade `FUN_1000d6d0` (blend 31 → 0, one draw+present per tick = 32 ticks); later calls on the same line
(item names, "…Done") replace its text and draw at once. Five lines: y 100 `inte 6` "Loading Permanent Image:  " + 8
sprite names → `inte 7`; y 120 `inte 8` + 24 sound names (or "Sound System Not Available") → `inte 9`; y 140 hard-coded
"Unpacking Unit: " + 386 unit names → "Unpacking Unit: Done" (`inte 10/11` "Loading Unit:" have no reader); y 160
`inte 12` + 5 weapon names → `inte 13`; y 180 `inte 14` + 2 player names → `inte 15`. ≈ 425 item redraws. [HIGH calls
D:19019–19073, 25285–25312, 33899–33926, 36195–36221; MED the item format strings 0x100e7feb / 0x100ed2fa (not read)]
**Cold-start timeline** (sound on, Command up, prefs present; T = 0 at display open; load time excluded): 0–38 black
(wait 5, fade of black) · 38–47 publisher logo fades in, `publ` from 38 · 47–≈360 held until `publ` ends · ≈360–393 fade
· 393–402 Swoop logo fades in, `inmu` loops from 393 · held to 633 · 633–666 fade · 666–675 `back` fades in · 675–≥835
five lines (32-tick fade-in each, names flashing) · ≥835–≥867 lines fade out · ≥867–≥899 menu elements fade in · first
copyright flip at menu t0 + 241. Command held: 38–168 publisher logo (silent), and no `inmu` until something sets b6 (§2.2). [HIGH order, MED absolute]

## 2. Main menu `FUN_100229a0` (D:20261; L 100229a0..10022ecc)
### 2.1 Entry and layout (FE §2.1–2.3 confirmed in D)
t0 = TickCount; b9 = b8 = 0; registration check → b4; new progress list; load the 28 `inte` lines; build buttons
(`FUN_10023fd0`); build elements (`FUN_10025420`); FlushEvents; window current; **draw menu** `FUN_10023410`: DrawMenuBar
(`FUN_100491d0`), `back` → back + save, unhilite all, **element fade-in** (32 passes ≥ 1 tick, TM §3.1), redraw-if-dirty;
present full screen; InitCursor; b6 = 0. [HIGH D:20299–20317]
| element (list idx) | art / text | format normal → hilited | centre / y | conf |
|---|---|---|---|---|
| 0 logo | gasp 5 `galo` frame 0 (163×114) | 7 `ingl` both | (320, 101) | HIGH |
| 1–6 buttons | gasp 3 `mebu` frames 0,1,2,4,5,6 → hilited gasp 4 `mebh` same frame | 5 `inbn` → 6 `inbh` | (320, 168 + 30·i): 198, 228, 258, 288, 318, 348 | HIGH |
| 7 REGISTER | `mebu` 7 | — | (320, 378) — **absent in the registered build** (ruling) | HIGH |
| web (8) | `inte 0` "WWW.DEIMOSRISING.COM" | 1 `inwe` (blend 12) → 2 `inwh` (blend 0, colourise white) | centred, y 426, small | HIGH |
| copyright (9) | decoded "COPYRIGHT 2001-2003 SWOOP SOFTWARE & AMBROSIA SOFTWARE, INC." | 3 `inco` (12) → 4 `inch` (0, white) | centred, y 447 | HIGH |
Hit rect = the element's current bounds (rebuilt each redraw), so a hilited sprite button's rect is its `mebh` frame
(1400×30 plate) while the normal one is the `mebu` frame (667×58 plate) — see risk 6. Labels per frame: FE §2.1 (MED).

### 2.2 One idle pass (repeats with no wait; the event pump does not block) [HIGH D:20318–20484]
1. b9 → leave (§2.5). 2. registration idle tick; input poll `FUN_1004a9c0`; window collapsed? → suspend `FUN_10023da0` /
un-collapsed → resume `FUN_10023e10` (edge-tracked in `0x100e01a8`). 3. If not suspended (b7 == 0): b8 → QUIT flash
`FUN_10024f90`, b8 = 0 → **flip** when TickCount > t0 + flli 68 (240, strict): toggle; odd flips = registration banner
(`FUN_10010e90`: pgsl 35 "THIS COPY IS REGISTERED TO %s" when copies < 2, else pgsl 34 "REGISTERED TO %s  [%i COPIES]",
name upper-cased; pgsl 33 when unregistered), even = copyright; t0 = now; redraw → music service; b6 → b6 = 0, t0 = now,
music still alive (`FUN_100481e0`) ? resume : play `inmu` loop → hover (b8 clear): mouse outside the menu-bar strip
(top MBarHeight px, inclusive; no hoverable element reaches it) → `FUN_10024530`: hilite the button under the mouse,
gaso 11 `mbro` (0x4b, 100, 0) **on entry only**, not for the logo. 4. Redraw if any button dirty (restore whole back from
save, rebuild, draw, present full). 5. One event `FUN_10048f30` (table FE §2.5) and dispatch:
- click in content (b8 clear): id under the point; `FUN_10024a50` track: gaso 2 `incl` (0x4b, 100, 0) unless logo, then
  a blocking StillDown loop (hilite while inside, redraw); released inside → t0 = now → action (FE §2.7; ids ≥ 10 return).
- menu choice (sub 1, or Command-key 5): About (Apple 128 item 1) → credits `FUN_10025060`; File (2000) item 1 → b8 = 1.
  Command-key hilites the menu title 5 ticks (`10049080`).
- key (4): `FUN_10023b00(char)` (FE §2.8, HIGH), then t0 = now. update (3): present. resume (6) / suspend (7): t0 = now.
  Quit AppleEvent (8): resume if suspended, b8 = 1.
### 2.3 Actions this appendix owns (others: FE §2.7 → appendix B/C/D)
| trigger | sequence | conf |
|---|---|---|
| QUIT button / b8 path | button: b9 = 1 at once (click already sounded). b8 (Q key, File▸Quit, Quit AE): `FUN_10024f90`: `incl` (0x4b,100,0), unhilite all, hilite QUIT, redraw, busy-wait flli 61 (**10**), unhilite, redraw, b9 = 1 | HIGH |
| leave (b9) | present; **element fade-out** (32); free lists; music stop **with fade** `FUN_10048120(1)` (1 s, ≤ 600-tick guard); registered → return → shutdown (starts with a 30-tick wait `FUN_10049820(0x1e)`, prefs written there) | HIGH |
| About / copyright click (id 9) | `FUN_10025060`: present, element fade-out, credits `'cred'` (§4); returned 1 (N key) → 1-player game; FlushEvents, DrawMenuBar, `back` → both, unhilite 0–9, element fade-in, redraw, present. `inmu` untouched throughout | HIGH D:21774 |
| keys | `1 N n ⏎ 0x0A` 1P · `2` 2P · `P p` prefs · `H h S s` scores · `D d` demos · `R r` register (if present) · `F f` replay Last Film (sound, no flash) · `Q q` b8 · 0x9D / 0x8A volume −/+10 · all else nothing; recognised keys: `incl` (0x4b,100,0) + 10-tick button flash first | HIGH (FE §2.8) |
| suspend `FUN_10023da0` | b7 = 1; music pause; DSp suspend; user volume restored (no OS volume writes by ruling) | HIGH D:21077 |
| resume `FUN_10023e10` | b7 = 0; cursor; present full; **b6 = 1**; device volume; resume music unless the pause screen is up (b5); registered-now detection (unregistered only: gaso 10 `leen`, REGISTER removed) | HIGH D:21099 |
| advert `FUN_10025970` | unregistered only — never in the registered build | HIGH |

## 3. Level select `FUN_1002e310(&sector)` (D:27193; L 1002e310..1002ee80) — runs on the FRAME CONTROLLER
Entered from `FUN_100234d0` mode 0 after: element fade-out, `tran`, fade to black, music stop, `ammu` play loop (appendix B).
### 3.1 Set-up (in order) [HIGH]
`0x100e01fd` = 1 (level select active; read only by the console's ⏎ path `FUN_1002d230` to choose the ISp restore —
no visible effect) · flash reset `FUN_1002fc90` (mode 0, colour 0x7fff, alpha 32, scale 1.0) · result = 'none' ·
save buffer re-made 640×480×16 (`FUN_10009d70`; it held the level map) · accepted `0x100e01fe` = 0 · notice reset ·
three button records: `<` rect reli 18 (55,76)-(200,382), sprite gasp 6, frame flli 96 (12), at (flli 90/91) = (128, 228);
START rect reli 19 (246,76)-(392,382), frame flli 97 (10), at (320, 228); `>` rect reli 20 (438,76)-(583,382), frame
flli 99 (13), at (511, 228) — **the click/hover rects are the whole preview areas; the sprites sit on their centres** ·
frame controller construct + start `FUN_10030210(ctrl, 0, 0, 0)` (full-screen present, `1002e554`) · back ← black; TGA
`lese` → back and save · message record: time 0, text "Not Inited", active 0 · copy back → save; window current ·
asserts numLevels ≥ 3 · 3 previews: x = 55 + 191·i (55, 246, **437**), y 76; **middle = sector 1 always**
(`FUN_1002efb0(list, 1, 1, …)` D:27396), neighbours wrap (12 | 1 | 2) · draw once (hover off) · input clear + copy ·
end frame `FUN_10030570(ctrl, 0, 0)` (no present: 3rd arg 0) · **fade in** (mode 0, 9) · ShowCursor.
### 3.2 Per-frame loop (`FUN_10030360` begin frame → quit flag; tick flag; then end frame `(ctrl, 0, 1)` = present)
On a tick (every frame — no code writes the divider, EL §4): (a) not accepted → restore whole back from save; (b) flash step
`FUN_1002fcc0`; (c) notice tick (level-select frame count i); not paused → `FUN_100181e0(0, i)` (clear the notice, MED); (d) not accepted and console
input closed (`FUN_1002d190`): input clear+copy, player-0 7-byte input (EL §8: [1] right, [3] left, [4] fire ground,
[5] fire air, [6] select; default keys → ⌥ ⌘ Space); mouse (display-rect relative): over `<` / START / `>` rect
(inclusive) → button sprite gasp 7 (`mebh`) at scale flli 100 (1.1) and gaso 11 `mbro` (0x4b,100,0) on entry; mouse button
down there → sets left / accept / right; START frame = middle reachable ? flli 97 START (10) : **flli 98 NO ACCESS (11)**
(1002eaa0..1002eacc). Edge latches: left/right move once per press, accept once per press. **Accept** (any of [4..6]):
reachable → gaso 12 `lsse` (0x32,100,1), flash `FUN_1002fe40(1)`, accepted = 1 (1002ec24..1002ec5c); not reachable →
gaso 14 `lsna` (0x32,100,1), message time = frames presented, text pgsl 4 "Sector Not Reached" (registered build), colour
and blend from format 26 `lsfa` (red, blend 0), fail flash `FUN_1002fe40(2)` (1002ec64..1002ed08). **Move** (only when no
accept bit): cancel a running flash, index ∓1 with wrap 1↔12, gaso 13 `lsch` (0x32,100,1), re-fill previews (clears the
message). Accepted and flash ended (mode 0) → **exit at once, before drawing** (D:27569). (e) Draw `FUN_1002f3c0` (§3.3).
(f) every frame: message fade `FUN_1002ef10` (after flli 43 = **40** frames: blend +1/frame, at 32 cleared). Esc (pref 8:
0 → at once; 1 → 16th held frame), console, −/= volume, F6, Caps Lock pause all live through the controller (§5.3).
### 3.3 Drawing one frame `FUN_1002f3c0` / `FUN_1002f7a0` / `FUN_10006240` [HIGH D:27794–28241; layering MED]
Per preview (left, middle, right): rect = preview TGA (146×306) at its x, y. Hover on (not accepted, loop draws) and the
mouse inside → **queued `COST` strip**: format 29 `lsbo` (Loc −1/−1 → rect grown 1 px each side, colour cyan 00ffff, blend
20). Preview: plain copy, or — middle preview while flash scale ≠ 1.0 — **opaque scaled copy** `FUN_1001d1b0`: w′ =
trunc(146·s), h′ = trunc(306·s), centred on the rect centre (0.5 at 0x100d70e0), then, if flash alpha ≠ 32, a drawn-now
`COST` wash over the UNSCALED rect, flash colour, blend = alpha. Then the video grid: gasp 0 `vigr` frame flli 84 (0)
tiled over the rect (cols = w/tw + 1, rows = h/th + 1, clipped, blit flags 0x0f). Then: notice; level **name** (info
+0x000, e.g. "Mariner Valley") — or, while the message is active, the message text with colourise on, lsfa colour and the
message blend — in format 25 `lsde` (cyan 63c5d6) if reachable else 24 `lsna` (red), centred, y 407; **number**
"%0.2i" of the sector in 22 `lsnu` (cyan) / 23 `lsnn` (red), centred, y 38; the three button sprites (START skipped
while the controller's paused byte is set). All template clips: the level-select draw template 0x100eaddc = {0,0,480,416}.
### 3.4 The accept/fail flash — INDEX #62 **closed** [HIGH]
Format index = 0-based `idli gate` order (format 0 = `prog`, 26 = `lsfa` match their uses): **27 = `lsca`** (BlendAmount
16, colour 00ff00), **28 = `lscf`** (16, ff0000). Start (`1002fea8..1002ff14`): mode 1/2, scale 1.0, growing 1, colour =
fmt+0x122, alpha = fmt+0x114 = **16**. Steps (one per frame, step first then draw): alpha 17, 18 … 32; scale accept 1.18,
1.36, 1.54, 1.72, 1.90, 2.0 (clamp, step 6), 1.82 … 1.10, 1.0 (step 12); fail 1.25, 1.5, 1.75, 2.0 (step 4) … 1.0 (step
8); mode 0 at **step 16** (alpha 32 dominates). Visible: zoom + wash on accept steps 1–11 (alpha 17–27), fail steps 1–7;
steps with scale 1.0 draw the plain preview. Accept: the frame of step 16 is not drawn or presented → last frame shown =
step 15; then fade to black (mode 0, 33). Accept-to-fade ≈ 15 frames ≈ 30 ticks. Fail: stays on the screen; a new press
restarts it from step 0.
### 3.5 Exit [HIGH D:27577–27596, L 1002ee34..]
active flag 0; **fade to black** (mode 0, 33); controller end session (FlushEvents); accepted → HideCursor; free previews;
`*sector` = index + 1 (also on Esc — the caller ignores it for 'none'); return the middle level tag (`le07` for sector 1)
or `'none'`. `ammu` keeps playing; the caller stops it (appendix B). Unlock: registered → reachable iff sector ≤ int pref 3
(fresh prefs 1); the unregistered sector-4 cut and pgsl 5 never occur in the registered build. [HIGH D:27675–27691]

## 4. Credits `FUN_10025b90('cred')` (D:22214) [HIGH unless marked]
Back ← black; `back` → back; copy rect {0,0,480,640} back → save; present full; FlushEvents; empty element list; page time
0, timer = now. Loop: music service; page time up (now > timer + time) → element fade-out (32; **an empty list returns at
once**, D:8186+76), free, **busy-wait 60 ticks**, read `stli cred` lines until one contains `<page ` (its number = this
page's time in ticks) — `<title>` lines → format 8 `crti` (colour 00ffbd) with the text after the tag, others 9 `crno`;
x 120, y = 130 + 16·k (flli 74/75) — then element fade-in (32), timer = now. Input only between timeouts (fades and the
60-tick wait leave events queued): mouseDown → `incl` (0x32,100,1), exit 0; key → `incl`, exit (N/n → 1 = 1P game). Exit:
fade-out, free. Pages (10): 200, 210, 120, 120, 420, 300, 240, 240, 420, 420 ticks; titles Swoop Software, Additional Unit
Art, Music, Mac OS X Support, Geek Support, Ambrosia Software, Special Thanks, Chief Testers, Testers, Testers. First page
visible at entry + 60 + 32. After page 10: the stli's trailing empty line (line 102) becomes a blank 11th page held 420
ticks (stale time) before the exit fade [MED — depends on `FUN_10002e50` returning that empty line].

## 5. Fades and pause
### 5.1 Screen fades (Swift exists, HIGH; FE §5.1) — `FUN_1000b9a0(D, mode)` to black: 33 presents a = 32 … 0, scaled in
place, ≥ 1 tick apart; `FUN_1000ba70(D, mode)` from black: 9 presents a = 0, 4 … 32. mode 0 → full-screen present
`FUN_1000bc60`, 1 → game layout. Every fade in this appendix is mode 0.
### 5.2 Element fades (TM §3.1, HIGH): in `FUN_1000db90` 32 passes level 31 … 0; out `FUN_1000df00` 1 … 32; pass k starts
≥ 1 tick (flli 160) after pass k−1; each pass restores each element's rect from save, draws (text alpha = max(level, own
blend); sprite alpha = level only, template scale 1.0), presents the rect; alpha 32 erases. Empty list: no passes.
One-element fade `FUN_1000d6d0`: blend −1 per tick to 0, restore/draw/present each pass (loading lines only).
### 5.3 Pause `FUN_10022ef0(presentMode, hideCursor)` (D:20507) — reached only from the frame controller (game, level select):
b5 = 1, FlushEvents, halt all effects, gaso 8 `incl` (0x32,100,1), music pause, window current; spin until (not suspended
and Caps Lock up) or b8 (then returns 1 → controller quit); normal end → music resume; present: 1 → game screen, 0 → full
screen (level select passes 0, `FUN_10030870` → `(+4, 0)`); b5 = 0. Before it, begin frame posts notice pgsl 0 "Press
Caps Lock" (`NoticeSlot.pressCapsLock(controllerMode: 0)`); the level select draws it (format 49 `gano`, y 220) with START
hidden. No resume sound. [HIGH; notice placement on level select MED]

## 6. Sounds and music of these screens (args = priority, volume, allowMultiple) [HIGH]
| cue | where | args |
|---|---|---|
| `publ` · `inmu` play loop | boot (Command up) · also menu b6 path when the stream is gone | 0x32,100,1 · loop 1, paused 0 |
| music pause/resume · stop with fade | menu b6, suspend/resume, pause screen · leaving the menu (`FUN_10048120(1)`, 1 s, ≤ 600 ticks) | `FUN_10048220(1/0)` |
| gaso 11 `mbro` · gaso 2 `incl` | hover entry (menu, level-select buttons) · menu click/key/QUIT flash | 0x4b,100,0 both |
| gaso 2 `incl` · halt + gaso 8 `incl` | credits exit · pause | 0x32,100,1 both |
| gaso 12 `lsse` / 14 `lsna` / 13 `lsch` | level select accept / refused / move | 0x32,100,1 |
| gaso 7 `incl` · gaso 1 `clic` | −/= keys · console open — level select, via FrameKeys (OS X branch, Q4/D31) | 100,100,1 · FrameKeys |
| `ammu` loop | started before level select (appendix B), plays throughout it | — |

## 7. What exists in Swift / what tasks must add
| need | exists (file:line) | must add |
|---|---|---|
| screen fades | `RenderOp.fade` RenderOp.swift:52, `FadeKind` :24, `PresentKind.fullScreen` :20; Fades.swift:19/35/50; FadeToBlack.swift:25; driver `.fade` handling DeimosDriver.swift:38 | fades outside a `DeimosSession` (the driver is session-bound: `newSession` :399, `idle` :189) |
| fills, image copies | `.fill` :38, `.loadImage(image:into:dst:)` :40 (centred `pucr` = dst rect), `.copy` :42, `.present` :56 | PICT 1000 source (HectorKit `PICT.decodeAny`, used only by deimos-census AppResourceFork.swift:47) + stage `Resources/Deimos/Deimos Rising.rsrc` into the app (tools/stage-deimos.sh ships `Data` only) |
| TGA / sprites / text | TGAImage.swift:43 (all 45 im16), SpriteGroup.swift:59, `DeimosAssets` DeimosAssets.swift:10 (floats :13, gameStrings :16, formats :18, sprites :23, rects :27, `spriteGroup` :95), TextFormat.swift:19, `TextRequest` TextLayout.swift:8 (`layout` :127, `draw` :208), `DrawCommand` DrawCommand.swift:7 (`costRect` :29) | element list (text + sprite elements, bounds per TM §3), element fades in/out, one-element fade; `stli inte`/`cred` accessors (`inte` is read only by Console.swift:119); video-grid tiler |
| `COST` strips | SpriteBlitter.swift:78 (rejects a rect wholly outside the clip, else fills it whole), CostRect.swift:24 | — |
| preview zoom | ScaledLeaves.swift:26 is the keyed sprite path, not this | opaque scaled raw copy `FUN_1001d1b0` (blit-pixel-rules row; L 1001d1e0..1001d248) |
| frame controller in level select | FrameController.swift:63 `startSession(… gameScreenLayout: false …)`, :99, :121; FrameKeys.swift:102 `beginFrame`, :195 `endFrameWrapper`, :207 `pauseScreen`, `PauseScreen` :30; NoticeSlot.swift:53/:124/:166 | FrameKeys/Console take `game: inout GameState` (messages, console commands) — decouple or give level select a GameState |
| input | KeyTable.swift:13 (→ `PlayerInput` left/right/fire*/select), `HeldKeys` HeldKeys.swift:7 (★ LOCKED; no mouse), App keyDown → `macCharCodes` DeimosController.swift:362/:374 | mouse position + button in the input seam (also the film-end click, remainder S9.8); App `mouseDown` :410 is empty; charCode events and click classes for the menu |
| music | `MusicCue` MusicCue.swift:4 (★ LOCKED: play/stop/pause/resume/level) | stop-with-fade (1 s, guarded); Core-side "stream alive" state for the b6 path (`FUN_100481e0`) |
| prefs | `DeimosPrefs.intPrefs` DeimosPrefs.swift:14 (pref 3 = highest sector) | (file I/O: other appendix) |
| levels | `LevelOrder.level(sector:)` LevelOrder.swift:22; `LevelDefinition` name :31, description :35, `previewImage` :44 | 3-preview model with reachable flag |
| waits | `.limit`, `.pauseWait` (host ops, RenderOp.swift:64) | tick waits (5, 10, 60, 130, 240), wait-for-voice-end (`publ`), StillDown click tracking — as a front-end state machine in Core (design §3 "FrontEnd") driven by the host clock |
| menu bar | App `makeMenuBar` DeimosController.swift:218 (Full Screen, Quit only) | About → credits, Quit → b8 (Q3) |
| suspend | DeimosDriver.swift:166/:174, App `updateSuspension` :310 | menu b7/b6 semantics |

## 8. Data facts (all present in `Resources/Deimos/Data`; loaders: TGA, GIF sprite groups, tefo, stli, reli, flli, idli exist)
| item | tag / file | size / count |
|---|---|---|
| publisher logo | `Interface.pak im16 pucr` | TGA 260×342 |
| developer logo | app resource fork **PICT 1000** "Swoop Software Logo" (`Resources/Deimos/Deimos Rising.rsrc`) | 640×480; `Interface.pak im16 decr` 640×480 "Developer Credit" exists but no code loads it (no `0x64656372` in D) |
| backgrounds | `back` (boot, menu, credits), `lese` (level select), `adve` (unregistered advert), `menu` (no loader found) | TGA 640×480 |
| previews | `cap1–3 inp1–3 isp1–3 jup1–3` (level `previewImage`) | TGA 146×306 ×12 |
| sprites | gasp 0 `vigr` (302×92, 2 fr), 3/6 `mebu` (667×58, 14 fr), 4/7 `mebh` (1400×30, 14 fr), 5 `galo` (163×114, 1 fr) | im08 GIF plates |
| strings | `stli inte` 28 lines, `cred` 102 lines (10 `<page>`), `pgsl` 0, 4, 5, 33–35 | |
| formats | `idli gate` 0 prog, 1–7 menu, 8/9 credits, 22–29 level select, 49 gano | 54 |
| rects | `reli inre` 18–20 (text order l,t,r,b); right preview drawn from x 437 but its rect starts at 438 (replicate) | 22 |
| floats | flli 39–47, 61–68, 74/75, 84/85, 90–100, 160 (values in §§1–4) | 220 |
| sounds | `publ` 235,776 fr; `incl mbro lsse lsch lsna tran clic leen`; music `inmu` (2,633,792 fr), `ammu` | 44.1 kHz |

## 9. Open questions and risks
(a) Facts still unread (implementer reads them from L):
1. Item-name format strings 0x100e7feb (sprites/sounds), 0x100ed2fa (units), 0x100e9b6c (weapons) and what `FUN_1001a1f0`
   strips from a sprite tag name — L around 1001fe60..1001ffa0, 1003d0a0.., 1002ab20.. and the data image at those addresses.
2. Render-layer and immediate/queued state of each level-select draw (hover strip queued via `FUN_10018a40`; video grid
   `10006340`; button sprites; flash wash via `FUN_10019570` "now"): decides what overlays what — L 1002f3c0..1002f79c,
   1002f7a0..1002fc5c, 10006240..1000634c.
3. Field mapping of the button sprite command in `FUN_1002f3c0` (which local is scale / flags; is non-hovered scale 1.0) —
   L 1002f3c0..1002f79c.
4. `mebu` vs `mebh` frame sizes per used frame (hover flicker if a hilited frame is smaller than its normal frame — risk 6)
   — measure with `SpriteGroup` (no listing needed).
5. Whether `FUN_10002e50` returns the empty last `cred` line (blank 11th page, §4) — L at `FUN_10002e50`.
6. Command-key menu flash `FUN_10049820(5)` placement and the menu-bar drawing `FUN_100491d0` — L 10049044..100490c0.
7. The publisher-logo hold length depends on when the mixer drops the `publ` voice (`FUN_100476e0`) — measure in the
   replica's mixer against 321.6 ticks.
8. FE §2.8's "volume keys play the click" vs `FUN_10025920` being reached after the click — L 10023b10..10023c14.
(b) QUESTIONS FOR BEN (do not answer here):
- Q1. The copyright line flips every 4 s to a registration banner. The registered replica has no owner record: show
  "THIS COPY IS REGISTERED TO <name>" (whose name?), or something else?
- Q2. "WWW.DEIMOSRISING.COM" lights up under the mouse and, clicked, offers to open the browser. The website link is out
  of scope: keep the line and its hover with a click that does nothing, or show the original's dialog?
- Q3. The original's menu bar had "About Deimos Rising…" (opens the credits screen) and File ▸ Quit. Put About → the
  credits screen into the Mac app menu, in place of a standard About panel?
- Q4. The loading screen redraws each of ≈425 item names (8 images, 24 sounds, 386 units, 5 weapons, 2 players) as it
  loads them; the replica loads in an instant. Show every name for one screen update (a few seconds of flicker), or only
  each line's 32-tick fade-in and its "Done"?
Risks:
5. Front-end waits are busy loops in the original (the event queue keeps filling); the replica must queue clicks/keys
   through fades and the credits' 60-tick gaps, and FlushEvents exactly where the original does (menu entry, credits
   entry, level-select end, pause).
6. Hover flicker (a(4)): hit rects follow the drawn frame; replicate whatever it does.
7. Right preview never shows the hover strip: its `COST` rect (x 436..584) lies wholly right of the template clip x 416, so
   `FUN_10019570` rejects it (SpriteBlitter.swift:78 logic); left and middle do show it. Original quirk — replicate.
8. Launch modifiers: Command held = no `publ`, no `inmu` until b6; Option held = configuration dialog. The App must read
   them at launch (Finder launches rarely have them; tests must).
9. Level select uses frame-controller frames (2 ticks) while every other screen here uses ticks: mixing them up halves or
   doubles the flash, the message hold and the Esc hold.
10. `HeldKeys` and `MusicCue` are ★ LOCKED seams: mouse and fade-stop need a seat ruling before a task changes them.

## 10. Suggested tests (bounded; headless; ticks from an injected clock)
| test | asserts | bound |
|---|---|---|
| `testBootSequenceOps` | §1 order: wait 5, fade toBlack(full), fill, `pucr` dst (190,69,…), volume quantise (100→90, 95→90, 50→50), `publ` (50,100,multiple), fade fromBlack, hold until voice end, fade, PICT 1000 at (0,0), `inmu` loop, fade in, hold to T2+240, fade, `back` ×2, fade in | one boot |
| `testBootQuietLaunch` / `testBootNoSound` | Command: no `publ`, no `inmu`, 130-tick hold; no sound: 130-tick hold, `publ` not waited | one boot each |
| `testLoadingLines` | 5 lines at y 100…180; first draw of each line = 32 fade passes; item rewrites instant; ends with 32-pass fade-out | one boot |
| `testMenuLayout` | element centres (320,101), (320,198+30i) i=0…5, no REGISTER (registered), www y 426, copyright y 447; formats 7/5/6/1–4 | static |
| `testCopyrightFlip` | flip strictly after t0+240; alternates banner/copyright; t0 reset by click, key, suspend, resume | 1,000 ticks |
| `testMenuHover` | `mbro` (0x4b,100,0) once per entry; none for logo; none inside the menu-bar strip | scripted mouse path |
| `testMenuKeys` | each FE §2.8 char → action + `incl` + 10-tick flash; `F` no flash; `Q`/File▸Quit → `incl`, QUIT hilite 10 ticks, element fade-out 32, music stop-fade, no advert | table + one quit |
| `testMenuSuspendResume` | suspended: no flip/hover/music service; resume → b6 → resume or `inmu` restart | 2 cycles |
| `testLevelSelectInitial` | previews 12/1/2 at x 55/246/437 y 76; START frame 10; `lsde` name "Mariner Valley", number "01"; fade-in 9 after a non-presenting end frame | 1 frame |
| `testLevelSelectUnlock` | pref 3 = 1: sector 2 → NO ACCESS frame 11, `lsna`/`lsnn` red; pref 3 = 12: all START | 12 sectors |
| `testLevelSelectMoveEdgeAndWrap` | held → one move; `lsch`; 1←→12 wrap; message cleared | 30 frames |
| `testAcceptFlash` | `lsse`; per step alpha 17…32, scale sequence §3.4 (float32), wash steps 1–11 only; exit on step 16 without a present; returns `le07`, sector 1; fade toBlack(full) | 20 frames |
| `testFailFlash` | `lsna`; message pgsl 4 red, held 40 frames, blend +1/frame to 32; scale steps 1–8; screen stays | 80 frames |
| `testLevelSelectEsc` | pref 8 = 0 → 'none' next frame; pref 8 = 1 → 16th held frame | 20 frames |
| `testHoverStripRightPreviewRejected` | right-preview hover strip draws nothing; left/middle draw a 148×308 cyan blend-20 strip | 3 frames |
| `testLevelSelectPause` | Caps Lock → notice "Press Caps Lock", START hidden, halt + gaso 8, music pause, `.pauseWait(.fullScreen)` | 1 pause |
| `testCreditsPaging` | 10 pages, times §4, y 130+16k, titles in `crti`; 60-tick gaps; first page at +92; exit: click → `incl` (0x32,100,1) result 0, `N` → 1, other key → 0 | ≈ 3,000 ticks |
| `testElementFades` | 32 passes ≥ 1 tick; text alpha max(level, own); sprite alpha = level; empty list = 0 passes | unit |
Only eyes can check: the logos, the menu's look and hover, the zoom-and-wash flash, the grid over the previews, the
credits' look. **No reference screenshot of the original exists** (repo, Ghidra folder, archive index): goldens can only be
the replica's own frames (regression), built from the TGAs (`deimos-census` already renders `menu.png`/`background.png`).

## 11. Corrections to docs/deimos found (list only)
1. front-end.md §7 — "NO ACCESS F98 11 (unreachable)": shown whenever the middle sector is not reachable (`1002eaa0..1002eacc`).
2. front-end.md l. 26–27 "All front-end waits are TickCount loops, not frame-controller ticks" — false for level select:
   it runs the frame controller (`FUN_10030210(ctrl,0,0,0)` 1002e554, begin 1002e87c, end 1002ee24), 2-tick frames, with
   Esc, console, pause, volume keys, F6 live.
3. front-end.md worked example — "Fire/Return/click middle": Return is not an accept; accept = player-0 bytes 4–6 or a
   press inside reli 19 (`1002ec0c..`, D:27498).
4. front-end.md §7 — the button "click rects reli 18–20" are the whole preview areas; `<`/START/`>` sprites sit on their
   centres; clicking the left/right preview moves.
5. INDEX #62 — closable: formats 27/28 are `lsca`/`lscf` (0-based `idli gate`), start alpha 16; the flash is 16
   **frames** (≈ 30 ticks), not ticks, and its last step is never presented (D:27569).
6. INDEX #59 residue — the `COST` leaf is all-or-nothing (rejected wholly outside the clip, else filled whole, 100197ac..);
   the right-preview hover strip is therefore never drawn.
7. front-end.md worked example / engine-loop.md §2 — "hold until `publ` ends, or until 130 ticks": exclusive branches
   (`100003b0..10000404` then `b 0x10000434`); with sound, no 130 floor or cap.
8. front-end.md §9 — only a new loading line fades in (blend 0x20 at creation); rewrites draw at once; every call
   restores the whole back buffer; units use hard-coded "Unpacking Unit: " (`inte 10/11` unread); 5 lines.
9. front-end.md §6 — "after the last page times out → exit": a blank page (the empty last `cred` line) is shown for the
   stale 420 ticks first [MED].
10. micro-wave §3.8 — "the starter/initial values are set by the caller `FUN_1002e310`": by `FUN_1002fe40` (as the fold-in
    said); the reset values (`FUN_1002fc90`) are mode 0, colour 0x7fff, alpha 32, scale 1.0.

## 12. Sizes and grouping
| task | content | size |
|---|---|---|
| FE-0 front-end runner | Core state machine for blocking waits/fades/StillDown, host clock, input seam with mouse + char events, menu-bar commands, FlushEvents points | medium (seam rulings first) |
| FE-1 element list + fades | element list (text/sprite, bounds, hit rects), fade in/out, one-element fade — shared by menu, credits, loading lines (and scores, appendix B) | medium |
| FE-2 boot | §1 + PICT staging + loading lines + timeline test | medium |
| FE-3 main menu | §2 layout, idle pass, flip, hover, click tracking, keys, quit, suspend/resume | large |
| FE-4 level select | §3 incl. flash, message, zoom copy, grid, hover strip, controller/pause/console context | large |
| FE-5 credits | §4 on FE-1 | small |
Shared code: FE-1 under FE-2/3/5; FE-0 under all; FE-4 needs FE-0 and the GameState decoupling of FrameKeys. Pause and
screen fades need no task of their own.
