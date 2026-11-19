# Deimos Rising 1.0.6 — the front end, OS 9 build (L) against OS X build (X)

Scope (Phase 4 S0/CMP, 2026-11-20): the front-end functions in the §2 table (the screens the Phase 4 grounding
appendices cite, and the callees that turned out to differ), compared between the two builds in the one app. A
function not in §2, including an unlisted callee of a listed one, was **not** compared for this file and is not
claimed the same: the automatic pass of §1 may have paired it as identical, but no one read it. Ruling 5 of the Phase 4
plan says the front end follows X where the builds differ; each screen task reads this file first. This file
**reports** differences; it changes nothing else in the bank (corrections go to the S0/BK task).

## 1. The two builds, the files, the method

**What they are.** The 1.0.6 data fork holds two complete PowerPC games. **L** ("Deimos Rising.PPC", offset 0) is the
classic Mac OS 8/9 build: InterfaceLib, DrawSprocket full screen, InputSprocket for keys. Everything else in
`docs/deimos` describes L. **X** ("Deimos Rising.OSX", offset 0xf67c0) is the CarbonLib build that Mac OS X runs,
the one Ben played: its own key reader, an HID gamepad layer loaded from ` Data/HID.bundle`, Carbon accessors.
The two were compiled from the same sources: X's functions sit in the same order as L's, shifted a little
(boot and prefs at the same addresses, the menu +0x210, the level select +0x3c0, the input layer +0x2310).

**Files.**
- L listing: `~/Developer/Ghidra/deimos/proj/disasm-review3-all.txt` (code 10000000–1004b400; not in git); L data
  image `~/Developer/Ghidra/deimos/proj/mem/100de330.bin`, L r2 = 0x100e6330; L C dump `ghidra/deimos/Deimos_pef.decompiled.c`
  (import names: its `// ==== Name @ addr` glue headers).
- X: `ghidra/deimos/Deimos_osx.disasm.txt`, `Deimos_osx.functions.txt` (entry, size, span), `Deimos_osx.data.txt`
  (r2 = 0x100eba10). See "Deimos OS X fragment" in `ghidra/README.md`. "X 1xxxxxxx" = this listing; a bare address or
  `FUN_` = L.

**Method** (a scratch Python pass, not committed; re-derivable from the files above):
1. Both listings were split into functions. Each instruction was normalised: calls to imports by name (L glue names
   from the C dump headers, the glue's `lwz r12,d(r2)` decoded to find the import; X glue names from the functions
   file); every r2 load resolved through that build's own data image to what it points at — an import, a function
   (transition vectors followed), a C string, or a data address; immediates kept.
2. The two function lists were aligned in address order (difflib over a hash of each normalised body, then
   similarity inside the gaps, then a longest-increasing-subsequence filter). 955 of L's 979 listed functions
   paired; 906 are instruction-for-instruction identical apart from addresses.
3. For each pair below, the bodies were diffed with L's callees mapped to their X partners and L's globals mapped to
   X's (both maps built from the identical pairs), and with registers and stack offsets masked. Every remaining hunk
   was read by hand in both listings. Where the automatic pairing near the input layer was off by one (L 1004a990 /
   1004a9c0), the call sites decide (§3 D18).
4. Jump tables were read from the data images (L 0x100f0384 / X 0x100f5e24 event pump; L 0x100e6120 / X 0x100ebb28
   configuration-dialog items; X 0x100f57a0 / 0x100f57dc controls window).

**Confidence.** HIGH = read in both listings; MED = inferred from shape (or from L's description of code X shares);
LOW = guess.

## 2. L ↔ X address table

"Same" means: after mapping callees and globals, the instruction streams match (registers may be renamed). Sizes are
L span (to the next function in the C dump) / X body size and span. Callees the appendices cite are the briefer rows.

| function (role) | L | X | L span | X size / span | calls | constants | conf |
|---|---|---|---|---|---|---|---|
| main: boot → menu → shutdown | 100000a0 | 100000a0 | 64 | 52 / 64 | same | same | HIGH |
| boot | 100000e0 | 100000e0 | 1360 | 1352 / 1360 | same | same | HIGH |
| shutdown (prefs written here) | 10000630 | 10000630 | 288 | 280 / 288 | same | same | HIGH |
| main menu | 100229a0 | 10022bb0 | 1328 | 932 / 1328 | differs (input suspend, D18) | same | HIGH |
| draw menu (menu bar, back, fade-in) | 10023410 | 10023800 | 192 | 184 / 192 | differs (D7) | same | HIGH |
| start a game / return | 100234d0 | 100238c0 | 1584 | 1572 / 1584 | differs (D7, D13, D18) | same | HIGH |
| suspend | 10023da0 | 10024190 | 112 | 112 / 112 | same | same | HIGH |
| resume | 10023e10 | 10024200 | 448 | 416 / 416 | differs (D7, D15) | same | HIGH |
| PREFERENCES action | 10024e40 | 10025210 | 48 | 48 / 48 | same | same | HIGH |
| SCORES action | 10024e70 | 10025240 | 288 | 276 / 288 | differs (D7) | same | HIGH |
| About / credits action | 10025060 | 10025430 | 304 | 284 / 288 | differs (D7) | same | HIGH |
| element fade-in wrapper | 10025840 | 10025c00 | 80 | 76 / 80 | same | same | HIGH |
| loading progress line | 10023040 | 100233c0 | 656 | 760 / 768 | differs (D17) | same | HIGH |
| level select | 1002e310 | 1002e6d0 | 3072 | 3092 / 3104 | differs (D10) | same¹ | HIGH |
| level-select draw | 1002f3c0 | 1002f7a0 | 992 | 992 / 992 | same | same | HIGH |
| level-select draw (preview) | 1002f7a0 | 1002fb80 | 1216 | 1216 / 1216 | same | same | HIGH |
| paused-frame hook (frame controller) | 10030870 | 10030c50 | 144 | 160 / 160 | differs (D11) | differs (event mask) | HIGH |
| pause | 10022ef0 | 10023120 | 320 | 472 / 480 | differs (D10, D12) | same | HIGH |
| (new in X) background event pump | — | 10023300 | — | 168 / 176 | — | — | HIGH |
| (new in X) set quit flag / Preferences AE target | — | 100230e0 / 100230f0 | — | 12 / 32 | — | — | HIGH |
| scores screen | 10021950 | 10021b60 | 640 | 640 / 640 | same | same | HIGH |
| high-score insertion | 100214c0 | 100216d0 | 1168 | 1116 / 1168 | same | same | HIGH |
| name entry | 10021bd0 | 10021de0 | 1824 | 1820 / 1824 | same | same | HIGH |
| credits | 10025b90 | 10025f50 | 1312 | 1304 / 1312 | same | same | HIGH |
| demo / film choice | 100069b0 | 10006a20 | 416 | 396 / 416 | same | same | HIGH |
| session (start, loop, end) | 100051a0 | 10005200 | 2848 | 2828 / 2848 | differs (input resume/suspend only, D18) | same | HIGH |
| film object constructor | 10009390 | 10009400 | 112 | 104 / 112 | same | same | HIGH |
| film record: header | 10009710 | 10009780 | 64 | 60 / 64 | same | same | HIGH |
| film record: one tick | 10009830 | 100098a0 | 320 | 312 / 320 | same | same | HIGH |
| film save (`last`) | 100095b0 | 10009620 | 208 | 204 / 208 | same | same | HIGH |
| film file write (pak tag) | 100025b0 | 100025b0 | 144 | 132 / 144 | same | same | HIGH |
| configuration dialog | 10010fc0 | 10011240 | 1488 | 748 / 1376 | differs (D2–D5) | differs (item numbers) | HIGH |
| configuration dialog refresh | 10011590 | 100117a0 | 1248 | 436 / 1248 | same² | same | HIGH |
| open configuration dialog | 100047c0 | 100047c0 | 48 | 44 / 48 | same | same | HIGH |
| screen fade to black | 1000b9a0 | 1000bc20 | 208 | 208 / 208 | same | same | HIGH |
| screen fade from black | 1000ba70 | 1000bcf0 | 352 | 340 / 352 | same | same | HIGH |
| element fade in | 1000db90 | 1000de10 | 880 | 876 / 880 | same | **differs (D1)** | HIGH |
| element fade out | 1000df00 | 1000e180 | 880 | 876 / 880 | same | **differs (D1)** | HIGH |
| prefs read | 10004f80 | 10004fe0 | 368 | 356 / 368 | same | same | HIGH |
| prefs write | 10004640 | 10004640 | 384 | 380 / 384 | same | same | HIGH |
| prefs write at quit | 100045f0 | 100045f0 | 80 | 72 / 80 | same | same | HIGH |
| prefs missing → fresh | 10004540 | 10004540 | 176 | 168 / 176 | same | same | HIGH |
| scores/names erase (defaults) | 10004ae0 | 10004ae0 | 336 | 332 / 336 | same | same | HIGH |
| prefs defaults (bytes, ints 3) | 10004f20 | 10004f80 | 96 | 88 / 96 | same | same | HIGH |
| prefs defaults (display, sound, both key sets) | 100050f0 | 10005150 | 176 | 176 / 176 | same | same | HIGH |
| (new in X) key-set fetch per player | — | 10004f20 | — | 88 / 96 | — | — | HIGH |
| display init (takes Full Screen byte) | 1000ae20 | 1000b080 | 1808 | 1836 / 1840 | differs (D6) | differs (D6) | HIGH |
| event pump | 10048f30 | 1004a270 | 544 | 244 / 576³ | differs (D16) | differs (D16) | HIGH |
| event reader (scores, name entry, credits, advert; grounding B §2c, §5) | 10048c90 | 10049f60 | 224 | 288 / 288 | differs (D24) | same | HIGH |
| menu bar set-up | 100491d0 | 1004a530 | 336 | 320 / 320 | differs (D7) | differs (D7) | HIGH |
| About item on/off | 10049320 | 1004a670 | 80 | 4 / 16 | differs (D9: empty in X) | — | HIGH |
| menu item → code | 10049370 | 1004a680 | 144 | 72 / 80 | differs (no desk accessories) | same codes | HIGH |
| AppleEvent handlers install | 10049aa0 | 1004adf0 | 512 | 420 / 608 | differs (D8) | differs (D8) | HIGH |
| app start (Toolbox, menus, AEs) | 10048330 | 10049630 | 336 | 280 / 288 | differs (D7, D22) | — | HIGH |
| input resume (wrapper) | 1004a990 | 1004cca0 | 48 | 68 / 80 | differs (HID, D18) | same | HIGH |
| input suspend (wrapper) | 1004a9c0 | 1004ccf0 | 48 | 52 / 64 | differs (HID, D18) | same | HIGH |
| per-pass key/pad read (level select's input; paired by its four call sites L 10006b94/1002e82c/1002e944/10030544 ↔ X 10006c04/1002ebec/1002ed24/10030924) | 1004aa90 | 1004cdf0 | 192 | 868 / 880 | differs (own key reader + HID; grounding C §3b) | — | HIGH |
| input set-up at boot | 1004a8b0 | 1004cbc0 | 96 | 68 / 80 | differs (HID, D19) | — | HIGH |

¹ Besides the event-mask constant of D10, one r2 load points at an 8-byte constant in each build's code section
(L 0x100d7094, both words 0; X 0x100dc924, listed as `??` — undecodable, so not read as values; MED same).
² The calls differ only because X has two byte-identical "deactivate item" functions (X 10046a70 and 10046ab0, each
`GetDialogItemAsControl` + `DeactivateControl`, the body of L 100457b0) and calls the second; no behaviour change.
³ The X body size undercounts: the switch-table cases lie past it (span 576).

## 3. Differences

Each: what differs, both addresses, what a player sees, and the mark for Phase 4.

**D1 — Element fades take half as long.** The text/sprite element fade-in steps the level by 2, not 1
(L 1000dc00 `subi r25,r25,0x1` ↔ X 1000de80 `subi r25,r25,0x2`; loop ends at 0, L 1000dee0 / X 1000e160), so it runs
**16 passes** (levels 30, 28 … 0) instead of 32. The fade-out likewise (L 1000df70 `addi … 0x1` ↔ X 1000e1f0
`addi … 0x2`; ends at 32, X 1000e4d0): 16 passes, levels 2 … 32. The per-pass wait is unchanged (the caller's tick
count). A player sees every menu fade in and out (entering the menu, after a game, around credits and scores) in about
16 ticks, not 32. **Changes what Phase 4 builds.** (Contradicts appendix A §5.2 and the timing in B §1a, which are L's:
the click-to-level-select dead time is about 16 + 33 + 9 = 58 ticks in X, not 74.) HIGH.

**D2 — Configuration dialog: which items are greyed.** L greys item 8 "Full Screen (Takes Effect on Relaunch)" at
open (L 10011180..10011188). X leaves it live and instead greys item 10 "Bypass System Volume", item 12 (the sound
slider) and its labels 11 and 13 (X 10011348..10011380). The refresh still makes item 12 live when byte 7 is already 1
(L 10011708..10011724, X 10011904..10011934). A player on OS X can tick Full Screen but not Bypass System Volume.
**Changes what Phase 4 builds.** HIGH (as grounding C §2).

**D3 — Configuration dialog: no forced font.** L sets Geneva 9 on the whole dialog (`GetFNum` + L 100458c0 at
1001107c..1001108c) and on items 8, 9, 10, 17, 18, 19, 5, 6, 7 (L 10045670 calls, 100110bc..10011178). X calls
`GetFNum` and discards the result (X 100112f8), then sets nothing (X 10011300..10011320): its text comes from the
Dialog Manager with `dftb 190` and the theme. **Changes what Phase 4 builds (the look only; it feeds question 6).**
HIGH for the code, MED for how OS X then drew it.

**D4 — "Set Controls…" opens the game's own window.** L calls the InputSprocket panel (L 10011414 → 1004ae00) and
always marks the dialog changed (L 10011420). X opens the controls window (X 100115fc..10011604: X 100435d0 with
prefs + 0x14b8 / + 0x14d4) and marks changed only when it returns Save (X 1001160c..10011614). **Changes what Phase 4
builds.** HIGH (as grounding C §3).

**D5 — "Set Gamepad Controls…" is shown in X.** L hides item 19 always (L 10011134..1001113c). X hides it only when
its HID layer is down (X 10011328..10011340); item 19 then opens the HID window (X 10011634..1001164c → X 1004b3c0).
But in X a missing HID layer stops the game at start-up: the input set-up (X 1004cbc0 → X 1004b050) shows the fatal
alert "Input Error (File Missing)" / "Could not start the Mac HID Manager. Please ensure that the file "HID.bundle" is
in the game's Data folder." (X 1004b09c / 1004b110 → 1004b1e4..1004b1f0, third argument 1 = fatal). On any OS X
install that runs at all, the button is therefore **visible**. **Changes what Phase 4 builds** — it contradicts the
reasoning of ruling 17 ("as X hides it when its gamepad layer is absent"): hiding it is a choice for the seat, not
what X did. HIGH.

**D6 — "Full Screen" unticked gives a window at the next launch (ruling 13).** The boot reads byte 4
(`FUN_10004ef0(4)`, L and X 10000230) and passes it to the display init, identically in both. L's display init never
uses it (display-window-present §8.1). X's display init stores **windowed = 1** (display + 0x4d) when the byte is 0
(X 1000b0ec..1000b0fc; L 1000ae8c..1000ae90 has no such write), before the monitor-size check that clears the copy it
passes on (X 1000b1e8), and then takes the DrawSprocket path only when windowed is 0 (X 1000b1ec). Everything after
that is the windowed path L also contains but can never reach: the window is created with windowed = 1 (X 1000b2c8
→ X 1000a6c0, the counterpart of L 1000a640: procID 4, a document window without a grow box, titled "Deimos Rising"),
the display rect is centred on the main screen (X 1000b380 tests windowed, as L 1000b104 does), and events are
not handed to DrawSprocket. A player who unticks Full Screen and relaunches plays in a 640×480 window on the desktop,
with the menu bar visible. **Changes what Phase 4 builds.** HIGH for the write and the branch; MED for the window's
exact look (read from L's unreachable path, which X shares instruction for instruction except for Carbon accessors).

**D7 — The menu bar is built once, and differently.** L builds the bar (L 100491d0: `GetNewMBar 128`, `SetMenuBar`,
the Apple menu's desk accessories, File 2000, Edit 2001 items 0, 1, 3–6 disabled) at the draw-menu step and again after
every game, resume, scores and credits (callers L 10023424, 100238bc, 10023a28, 10023ed4, 10024ebc, 100250b4). X builds
it **once**, at app start (X 10049660 in X 10049630); none of the six X counterparts calls it (X 1002381c, 10023cb4,
10023e18, 100242bc, 10025288, 10025480). X's version (X 1004a530): `GetNewMBar 128`, `SetMenuBar`,
**`EnableMenuCommand(nil, 'pref')`** — the application menu's Preferences… item is live (X 1004a57c..1004a588); no
Apple-menu handle and no desk accessories; **deletes the File menu** (X 1004a5bc..1004a5c0), so Quit is only the
application menu's Quit (a Quit AppleEvent → quit flag); Edit greyed as in L; `DrawMenuBar` (X 1004a654). A player on
OS X sees Deimos Rising ▸ About…, Preferences…, Quit, and a greyed Edit menu; no File menu. The exact list on screen
is OS X's to lay out (the application menu also carries the system's own items), and in full screen DrawSprocket
hides the bar, so it is seen only in windowed mode (D6). **Changes what Phase 4 builds** (the return path in B §1b
steps 11a/11b loses its menu-bar step; ruling 12's menu list). HIGH for the code; MED for the menu list the player
sees.

**D8 — Preferences… in the application menu opens the configuration dialog.** X installs a fifth AppleEvent handler,
`aevt`/`pref` (X 1004ae50..1004ae94; L installs four: oapp, odoc, quit, pdoc), whose body (X 1004b020) calls
X 100230f0 → X 10025210, the counterpart of L 10024e40, the PREFERENCES button's action (open the dialog, then flag
the menu music restart). It runs inside `AEProcessAppleEvent`, i.e. wherever the event pump handles a high-level
event: the main menu, and in X also the pause and the level select (D10) — reachable there only when the menu bar can
be clicked or ⌘, typed (windowed mode, D6). **Changes what Phase 4 builds.** Contradicts grounding C §5 ("No
Preferences menu item", true of L). HIGH for the handler; MED for reachability outside the menu.

**D9 — About is never greyed.** L's "About on/off" (L 10049320, Enable/DisableItem on Apple-menu item 1) is called with
0 at game start and 1 on return (L 10023538, …). X's counterpart is an empty function (X 1004a670: `blr`), called from
the same places (X 10023928, …). In X the About item stays enabled during a game (menus are not read in play anyway).
**Changes what Phase 4 builds** — contradicts ruling 12's "disabled during a game". HIGH.

**D10 — The pause and the level select listen for app switching and Quit.** X adds a background event pump
(X 10023300): one event through the normal pump (X 1004a270); resume → X 10024200 (resume), suspend → X 10024190
(suspend), Quit AppleEvent → resume if suspended, then the quit flag (X 10023374, flag r2 − 0x5ec0 = L's b8,
r2 − 0x6178); it returns 1 only when the pump reported no event (code 0), and 0 otherwise — for the three codes it
acts on and also for every code it ignores, e.g. a menu choice such as About (D23), which is simply dropped. X's
pause calls it every loop (X 10023214; L's loop
10022f68..10022fa4 reads no events), and tests Caps Lock only after an idle pump while not suspended
(X 100231f0..10023210). X's level select calls it after each begin-frame when `EventAvail(everyEvent)` says an event
waits (X 1002ec2c..1002ec5c; nothing in L 1002e86c..1002e880). So the level select removes one waiting event of any
kind per frame, keys and clicks included; that is harmless, because the level select reads keys through the per-pass
key read (X 1004cdf0) and the mouse through `Button` / `GetMouse` (X 1004a1a0, 1004a220), never from events. A player
on OS X can ⌘-Tab away and back while paused or choosing a sector (D11); on OS 9 those events wait for the menu.
**Quit from the Dock does not quit at once in the level select.** The pump sets the quit flag, but the level select
never reads it: the flag's only readers are the main menu (X 10022bb0), the pause (X 10023120), the start/return path
(X 100238c0) and the getter X 10023110 (used only by the event pump, X 1004a458). Nothing happens until a sector is
chosen or the level select is cancelled; cancelling returns to the menu, which then quits; choosing a sector starts
the level, which plays on until the next pause (MED: nothing in the game loop reads the flag). Quit while paused ends
the pause loop at once (X 10023228..10023244, returning 1); the paused-frame hook then sets the frame controller's quit
byte (X 10030cb8), the game ends, the post-game check (X 10023a6c) skips the high scores, and the menu quits.
**Changes what Phase 4 builds.** HIGH (MED where marked).

**D11 — Leaving the app pauses the game.** The frame controller's paused-frame hook (L 10030870 ↔ X 10030c50) enters
the pause screen not only when a pause was requested but also when `EventAvail(0x8100)` (operating-system and
activate events) finds one waiting (X 10030c58..10030c7c). Entering the pause this way does what every pause entry
does: flush the event queue, stop all effects, play the Paused sound and pause the music (X 10023150..10023184);
whether that flush drops the waiting suspend event is not settled by the listing (LOW). Inside the pause (D10) the
suspend is handled; on return, with Caps Lock off, the pause ends by itself. A player who switches away mid-level
finds the game frozen, music paused, until they come back. **In the level select it is a race:** each frame the level
select pumps one event (X 1002ec5c) before the frame's pause check runs at the end of the frame (X 1003097c, reached
from X 1002f204). A switch the pump catches runs the suspend (X 10024190: music paused) with no pause screen and no
Paused sound, and the check then finds nothing waiting; only a switch that arrives after the pump and before the
check opens the pause screen. Activate events (mask 0x0100) can also trigger the pause; they matter only in windowed
mode (D6), where clicking another window deactivates the game's (LOW in practice). **Changes what Phase 4 builds.**
HIGH for the code; MED for which way an app switch in the level select goes, and for the exact first-frame order on
return.

**D12 — The pause shows the cursor during a game.** When a game is running (X 10005d20 reads G + 8, the "session
running" byte), X's pause shows the cursor and leaves in-game display mode (X 100231a8..100231b8: X 1000ba00 = L
1000b780, X 1000c6c0 = L 1000c440), presents the screen at once (X 100231c0..100231e4), and on a normal exit hides the
cursor and re-enters in-game mode (X 10023250..10023270: X 1000b960 = L 1000b6e0, X 1000c670 = L 1000c3f0). L does
none of this (L 10022f5c..10022f68). **Changes what Phase 4 builds** (cursor visible while paused in a game). HIGH.

**D13 — Films keep the cursor, until an app switch.** At game start X skips the hide-cursor when the session is a
film (demo or Last Film) (X 1002393c..10023948 tests r27 = film; L 1002354c..10023550 hides it always). A player
watching a demo on OS X sees the mouse pointer (a click ends a demo). But the paused-frame hook's app-switch check
(D11) is not limited to games, and the session-running byte the pause tests (D12) is set for every session, films
included (X 10005874, reached by both the play and the record path). So an app switch during a film enters the pause,
which shows the cursor, and its normal exit hides it (X 10023250..10023270): the pointer is gone for the rest of that
film. **Changes what Phase 4 builds.** MED (each step read in X; the chain through the frame controller during a film
is inferred).

**D14 — (folded into D7)** the start/return path's two menu-bar rebuilds (L 100238bc, 10023a28) are absent in X.

**D15 — Resume does not present.** L's resume presents the full screen (L 10023e58..10023e5c → L 1000bc60); X's does
not (X 10024240 → 10024248). After switching back, the picture returns at the next present (an update event or a
redraw) rather than at once. **Changes what Phase 4 builds** (small). HIGH for the code, MED for what the eye sees.

**D16 — The event pump yields.** L `GetNextEvent(everyEvent)` (L 10048f78) ↔ X `WaitNextEvent(everyEvent, sleep,
nil)`, sleep 60 ticks while suspended, else 0 (X 1004a2b0..1004a2d8). Its jump table (L 0x100f0384 ↔ X 0x100f5e24,
24 entries) has the same cases (every X target = L target + 0x20 relative to the function), so it returns the same
codes. The tick reader also calls `EventAvail` first (X 1004aab0 vs L 100497f0). **No change for Phase 4.** HIGH.

**D17 — Loading lines handle suspend/resume.** X's loading-progress line (X 100233c0 ↔ L 10023040) runs one pump
event when `EventAvail` finds one and acts on resume/suspend only (X 100233cc..1002344c). **No change for Phase 4**
(only app switching while a level loads). HIGH.

**D18 — Input suspend/resume go to the HID layer.** Every site that suspends or resumes InputSprocket in L calls X's
HID wrappers instead: suspend L 1004a9c0 → X 1004ccf0 (HID suspend if up), resume L 1004a990 → X 1004cca0 (HID resume
if up, argument passed on). Sites: menu L 10022a5c ↔ X 10022c6c; start/return L 100235c4/10023608/10023640 ↔
X 100239bc/10023a00/10023a38; session L 10005890/10005af8 ↔ X 100058f0/10005b58; alert L 1000cefc/1000cfcc ↔
X 1000d17c/1000d24c; console L 1002d210/1002d3bc/1002d3cc ↔ X 1002d5d0/1002d77c/1002d78c. **No change for Phase 4.**
HIGH.

**D19 — Input set-up and the key reader.** L sets up InputSprocket (L 1004a8b0); X sets up HID (X 1004cbc0 →
X 1004b050, fatal alert without `HID.bundle`, D5). X's per-pass read (X 1004cdf0) reads the prefs key sets with
`GetKeys` and ORs the HID bytes (grounding C §3b). **No change for Phase 4** beyond what C §3 already asks. HIGH.

**D20 — Prefs: identical, one function added.** Every prefs function matches; X inserts the per-player key-set fetch
X 10004f20 (prefs + 0x14b8 + 0x1c × player), which shifts the later ones by 0x60. Correction to the S0 brief and to
grounding C §1b's "X equivalents … `FUN_10004fe0`/`10005150`": X's prefs **read** is X 10004fe0 (L 10004f80), its
**write** is X 10004640 (L 10004640, same address); X 10005150 is L 100050f0 (display, sound and key defaults).
**No change for Phase 4.** HIGH.

**D21 — Display plumbing uses Carbon accessors.** Window create (X 1000a6c0), refresh (X 1000a8f0), paint (X 1000ac50),
the screen blit (X 1000ad30, adds `QDFlushPortBuffer`), and the GWorld helpers (X 10009c40, 10009f00) replace direct
port fields with accessor calls. Same pixels. **No change for Phase 4.** HIGH for the code, MED that nothing visible
differs.

**D22 — App start.** X skips the classic Toolbox initialisation (L 10048344..100483a8) and pumps nine
`WaitNextEvent` calls after building the menu bar (X 10049668..10049690). **No change for Phase 4.** HIGH.

**D23 — Menu clicks.** X's mouse-down handling inlines the menu-item mapping (X 1004acc8..1004ad10; L 100499c0 calls
L 10049370), drops `OpenDeskAcc`/`SystemClick`, and reads window bounds through accessors. Codes unchanged: Apple 128
item 1 → About (1), File 2000 item 1 → 2 (unreachable in X: no File menu). **No change for Phase 4.** HIGH.

**D24 — The screens' event reader waits instead of polling.** The reader used by the scores screen, name entry, the
credits and the advert screen (grounding B §2c, §2d, §5; L 10048c90 ↔ X 10049f60; call sites L 10021ae0, 10021e74,
10025f8c, 10025a6c ↔ X 10021cf0, 10022084, 1002634c, 10025e2c) calls `GetNextEvent(everyEvent)` in L (L 10048cc0)
and `WaitNextEvent(everyEvent, sleep, nil)` in X (X 10049fcc), sleeping 60 ticks while suspended, 1 tick when the
session-running byte (D12) is clear — the menus — and 0 when it is set (X 10049f8c..10049fb4). Everything after the
call is the same (L 10048cd0..10048d54 ↔ X 10049fdc..1004a060): the DrawSprocket hand-off and the codes returned
(1 mouseDown, 2 keyDown and 3 autoKey with the character, 4 update; any other event 0). These screens time themselves
by `TickCount`, so the sleep adds at most a tick of latency to a key or click. **No change for Phase 4** (nothing the
player sees). HIGH for the code; MED that nothing visible differs.

## 4. Ruling 13 and grounding C §6a items 1, 2, 5

**Item 5 — what X does with the Full Screen byte, and its menu bar.** Byte 4 = 0 → the game runs in a window at the
next launch; byte 4 = 1 (the default written for a fresh file) → DrawSprocket full screen as in L (D6). The dialog
lets the player change it in X (D2) and the text "(Takes Effect on Relaunch)" is true there. So ruling 13 resolves to:
**the replica's Full Screen checkbox chooses full screen or a 640×480 window at the next launch.** The X menu bar is
D7 (application menu with About, Preferences…, Quit; Edit greyed; no File menu), and Preferences… opens the
configuration dialog (D8).

**Item 2 — X's three r2 slots in the controls window, resolved through the data dump.**
- r2 − 0x6bec → 0x100e63c8, a transition vector to **X 10043f90** (the key-capture filter grounding C §3a inferred;
  now HIGH). X 1004372c..10043730 makes the filter UPP from it.
- r2 − 0x6bf0 → **0x100f57a0**, the item-hit jump table (X 10043760..10043770, items 3–17): item 3 (the Player 1/2
  tab) → X 10043798; the edit fields 5, 7, …, 17 → X 10043774 (focus that field if it is not the focused one, X
  10046b20, store the focus in r2 − 0x5e10); the arrow pictures 4, 6, …, 16 → X 10043850 (nothing).
- r2 − 0x6bf4 → **0x100f57dc**, the assign jump table (X 10043e08..10043e18, focus item 5–17): fields 5, 7, 9, 11, 13,
  15, 17 store into slots 0–6 (X 10043e1c, 10043e50, 10043e7c, 10043ea8, 10043ed4, 10043f00, 10043f2c); even items →
  X 10043f58 (nothing). The source file named next to it in the data is "M_ControlsConfigure.cc".
All three confirm grounding C §3a's field ↔ slot mapping. HIGH.

**Item 1 — X's HID gamepad layer (X 1004b050..1004bfa7 and 1004cca0..1004cd6b, 1004d1e0..1004ee50).**
- **Available** iff `Gestalt('sysv') ≥ 0x1000` and ` Data/HID.bundle` loads (X 1004b300 → X 1004e720, which resolves
  `HIDGetElementValue`, `HIDCalibrateValue`, `HIDScaleValue`, `HIDConfigureAction`, `HIDSaveElementConfig`,
  `HIDRestoreElementConfig` and the device-list calls by name from the bundle). Unavailable → fatal alert at boot (D5).
- **No default bindings.** The binding table — 14 records of 8 bytes, (element, device), player 1 at +0x00, player 2
  at +0x38 — is at X 0x101220b4 in zero-filled data. Its only writers are the HID window (X 1004b3c0 → X 1004d1e0) and
  the file load (X 1004bc90, `HIDRestoreElementConfig` per record) of "Deimos Rising HID Data" in the user's
  Preferences folder (`FindFolder(kOnAppropriateDisk, 'pref', create)` + "/Deimos Rising HID Data", X 1004b140..1004b1b8);
  the save is X 1004bbb0 (`fopen "wb"`, `HIDSaveElementConfig` for each record). A pad does **nothing** in X until the
  player binds it in the HID window. HIGH.
- **Element → input byte** (X 1004b540, run each pass; result at X 0x10122124, 7 bytes per player, copied out by
  X 1004ba30 and ORed into the key bytes by X 1004cdf0). Input bytes: [0] up, [1] right, [2] down, [3] left, [4] fire
  ground, [5] fire air, [6] select (grounding C §3b). Records by offset: +0x00 → [0]; +0x08 → [1]; +0x10 → [2];
  +0x18 → [3]; +0x20 → [4]; +0x28 → [5]; +0x30 → [6]. A button sets its byte when its value ≠ 0. If the element in
  record +0x00 is an **axis** (X 1004bad0: element type 1 and usage 0x30–0x39 or 0x40–0x45 — note this includes the
  hat switch, 0x39), its value is read, calibrated and scaled (`HIDGetElementValue` → `HIDCalibrateValue` →
  `HIDScaleValue`), and **< 0x2f (47) sets [0] up, > 0xd0 (208) sets [2] down**; record +0x10 is then skipped. The same
  for record +0x18: < 0x2f → [3] left, > 0xd0 → [1] right, record +0x08 skipped. Records +0x20/+0x28/+0x30 are always
  read as on/off. Player 2: the same from +0x38 into bytes 7–13. HIGH for the rule and thresholds.
- **Not settled by the listing:** which row of the HID window (DITL 192: Up, Down, Left, Right, Fire, Bomb, Select)
  writes which record — that is in X 1004d1e0 (span 2048, a switch) — so "Fire" vs "Bomb" against bytes [4]/[5] is MED
  at best; the scale range the thresholds apply to (set by calibration, X 1004dc20, DITL 193, unread; 0–255 if
  `HIDScaleValue` keeps its defaults, LOW); the file's text format (HID Utilities' own, unread).

## 5. Open items

1. **Whole-game diff (grounding C §6a item 4) is still unrun outside the front end.** The pass above saw, in passing,
   compiler-level changes in gameplay code: L 10042cd0 ↔ X 100430c0 (heading; four `frsp` roundings gone), L 10034ee0 /
   10035070 ↔ X 100352d0 / 10035460 (entity-group rules; an int → float conversion changed), L 10037ed0 ↔ X 100382c0
   (cyclic-motion start; a float constant read from a different pool offset). Not front end; not judged here.
2. The HID window and calibration (X 1004d1e0, X 1004dc20) and the HID Data file format are unread (§4 item 1).
3. What OS X drew for the configuration dialog without the forced Geneva 9 (D3) — question 6.
4. The exact look of X's windowed mode (D6): window position after centring and whether the title bar is shown as
   L's procID 4 suggests — read from shared code, never seen.
5. Whether X processes ⌘, (Preferences…) or menu-bar clicks during pause and level select in full screen (D8; the
   menu bar is hidden by DrawSprocket there).
6. Corrections for S0/BK (listed, not made here): display-window-present §8.1 "Full Screen does nothing" is L only
   (D6); grounding A §5.2 and B §1a fade counts are L's (D1); A §5.3 pause, B §1a step 2 (the cursor) and B §1b step 11
(the menu bar),
   C §1b's X prefs addresses (D20), C §5's "No Preferences menu item" (D8); ruling 17's reason (D5) and ruling 12's
   About detail (D9) are the seat's to revisit.
