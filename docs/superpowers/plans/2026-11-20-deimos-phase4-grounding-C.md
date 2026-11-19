# Phase 4 grounding C — settings on disk, the two dialogs, the controller (read-only research, 2026-11-20)
Sources: classic listing `~/Developer/Ghidra/deimos/proj/disasm-review3-all.txt` (L), dump `ghidra/deimos/Deimos_pef.decompiled.c` (D),
**OS X fragment listing (X, new — see §0)**, app fork `Resources/Deimos/Deimos Rising.rsrc` (R, parsed with a scratch map
parser), bank `engine-loop.md` §1/§8/§10 (B-EL), `timing-frame.md` §5–6 (B-TF), `file-pict-alerts-manager.md` §5,
`front-end.md` §1–2, §4.3, `sound-music.md` §4, `micro-wave-2026-10-06.md` §1, the shipped Player Guide (G, cite only).
HIGH = read in L or X or R bytes; MED = D only / inferred / TOC not resolved; LOW = guess. Swift paths relative to `Deimos/`.

## 0. The finding that reframes this phase: the app holds TWO games' worth of code, and the bank read the other one
- `cfrg 0` (R) lists three PowerPC fragments in the one data fork: **"Deimos Rising.PPC"** at offset 0 (1,009,597 B;
  InterfaceLib + InputSprocketLib — the classic Mac OS 8/9 build the whole bank and the dump describe), **"Deimos
  Rising.OSX"** at **0xf67c0** (1,035,460 B; CarbonLib, `GetKeys`, CFBundle → `HID.bundle`; the build Mac OS X actually
  runs), and a "FATCarbon 1.5.1" stub at 0x1f3490. B-EL §1 "a classic … application, not a Carbon one" is true of
  fragment 1 only. HIGH (cfrg bytes; `Joy!peff` at 0x0, 0xf67c0, 0x1f3490).
- X was made this session: fragment extracted to scratch, Ghidra 12.2 headless import (language forced as for L), then
  `DisasmRange.java` over 0x10000000–0x100e3a10 (235,769 lines) plus a memory/symbol dump. **Homebrew Ghidra 12.2 ships
  no arm64 decompiler** (`os/mac_arm_64/decompile does not exist`) — X is disassembly only. X lives only in the session
  scratchpad: it must be regenerated into `~/Developer/Ghidra/deimos/` (and committed per house rule) before a task cites it.
- Function addresses in X sit near L's but shifted (config dialog L `10010fc0` ↔ X `10011240`; prefs block pointer
  L `_DAT_100def40` ↔ X `lwz -0x71cc(r2)`). Below, "X 1004cdf0" means the OS X fragment's address.

## 1. The prefs file (U_Prefs.cc; one 0x34f0-byte raw memory image)
### 1a. Record layout (field boundaries from the copy routines L `FUN_100047f0`/`FUN_10004c30`, D 2670–3050)
| off | size | meaning | fresh default | read by | written by | Swift today | conf |
|---|---|---|---|---|---|---|---|
| 0x0000 | 4 | version 0x2714 | 0x2714 | load `FUN_10004f80` (after decode) | fresh | `version` | HIGH |
| 0x0004/05/07 | 1 each | byte prefs 0, 1, 3 | 0 | none found | fresh | in `bytePrefs` | MED |
| 0x0006 | 1 | byte 2 config dialog done | 0 → 1 | boot `100000e0` (D 104) | boot `FUN_10004ab0(2,1)` after the dialog, Save or not | in `bytePrefs` | HIGH |
| 0x0008 | 1 | byte 4 "Full Screen" | 1 | boot → display init (never used, display §8.1); dialog | dialog item 8, Defaults | yes | HIGH |
| 0x0009 | 1 | byte 5 interlacing | 0 | terrain blit, level-start dance, F6, FPS monitor (B-TF §5) | dialog 9, F6, dance | yes, used | HIGH |
| 0x000a | 1 | byte 6 auto-interlace | 0 | FPS monitor | defaults only | yes | HIGH |
| 0x000b | 1 | byte 7 Bypass System Volume | 0 | volume apply `FUN_10047920/10047b10`, dialog | dialog 10, Defaults | yes | HIGH |
| 0x000c | 1 | byte 8 ESC Key Delay | 0 | Esc `FUN_100307c0` | dialog 17, Defaults | yes, `FrameKeys.swift:124` | HIGH |
| 0x000d | 1 | byte 9 FPS counter | 0 | end frame | console FPS `0x10007eb0`; fresh only | yes, `Cheats.swift:36` | HIGH |
| 0x000e | 1 | byte 10 FPS limiter | **1** | end frame, FPS monitor | fresh only (LIMITFPS unregistered) | yes | HIGH |
| 0x000f | 1 | byte 11 cheats enabled — **persists across launches** | 0 | console cheats | `100089a8` ("supermunki") | yes, `Cheats.swift:42` | HIGH |
| 0x0010–0x0067 | 88 | byte prefs 12–99 | 0 | none | none | in `bytePrefs` (0x64) | MED |
| 0x0068 | 4 | int 0 sound volume 0–100 | 50 | volume fns, dialog | dialog 12, −/= keys | `intPrefs[0]` | HIGH |
| 0x006c | 4 | int 1 music volume | 100 | `FUN_10048280` | dialog 15 | `intPrefs[1]` | HIGH |
| 0x0070 | 4 | int 2 — no reader (L and X scans) | 50 | none | defaults | `intPrefs[2]` | HIGH writer / MED none |
| 0x0074 | 4 | int 3 highest sector reached | 1 | level select `FUN_1002efb0` | `FUN_100234d0` after a sector-1, no-cheat game | `intPrefs[3]` | HIGH |
| 0x0078–0x01f7 | 384 | int prefs 4–99 | 0 | none | none | **no** (Swift keeps 4) | MED |
| 0x01f8–0x10f7 | 3840 | reserved block (copied as 960 words, never indexed) | 0 | none | none | **no** | MED |
| 0x10f8 | 15×21 | high-score names, obfuscated on disk over `strlen` | Mars … Electrofryer (table 0x100d61c0) | scores | name entry via copy | `highScoreNames` (String) | HIGH |
| 0x1233 | 2×21 | remembered player names, plain | "Player 1/2" | name-entry seed | name entry | `playerNames` | HIGH |
| 0x125d | 3 | padding (not copied by the copy routines; written raw) | 0 | — | — | **no** | HIGH |
| 0x1260 | 15×4 | high scores; disk = value + 0x024A8903 | 15000 … 1000 | scores; `FUN_10021470` vs 0x1298 | insertion | `highScores` | HIGH |
| 0x129c | 15×4 | dead ints; disk = value − 0x5969FBD0 (fresh: 0xA6960430) | 0 | none | none | **no** | HIGH |
| 0x12d8 | 15×32 | sector names, obfuscated over `strlen` | "New Atlantis" | scores | insertion | `highScoreSectorNames` | HIGH |
| 0x14b8 | 7×4 | P1 key set (Mac virtual key codes as Int32) | 7E 7B 7C 7D 37 3A 31 | X 1004cdf0 (§3c) | controls window Save, Defaults | `keyTable[0…6]` UInt16 | HIGH |
| 0x14d4 | 7×4 | P2 key set | 5B 56 58 57 77 75 79 | same | same | `keyTable[7…13]` | HIGH |
| 0x14f0–0x34ef | 8192 | reserved block (copied as 2048 words, never indexed) | 0 | none | none | **no** | MED |
No registration field: only U_Prefs functions touch the prefs pointer (L: 13 functions, all U_Prefs; X: 14); registration
is M_Registration's own (design §7.4 registered build). MED (copies passed to G_Scores could index further; none seen).

### 1b. I/O, obfuscation, lifecycle (L addresses; X equivalents identical in shape, `FUN_10004fe0`/`10005150`)
- **File:** name Pascal "Deimos Rising Preferences" (`_DAT_100df59c+0x5d`), type `pref`, creator `Deim`, folder
  `FindFolder(kOnSystemDisk, 'pref', no create)` (L 10048a00/10048ac0; X 10049cd0 same args) — OS 9: System Folder:
  Preferences; OS X: ~/Library/Preferences (MED, Carbon resolution). FindFolder failure → vRef 0/dir 0 (app folder).
  Finder message `STR -16397` "This document contains the preferences saved by the game…". HIGH (R + D).
- **Read** (`FUN_10004f80`): `FSRead` 0x34f0 into the live block, byte count ignored (a short file is accepted if the
  version matches — what fills the rest is unread, §7a.3); on open failure: tag `pref`/`pref` in the pak hierarchy
  (`FUN_10002850`) — the shipped ` Data/Local/pref` is an **empty folder** (archive copy), so no fallback in practice.
  Then for k in 0…14: names at 0x10f8+21k and 0x12d8+32k de-obfuscated in place over `strlen` (`FUN_10057760`) of the
  stored bytes; scores −0x024A8903; 0x129c +0x5969FBD0; **then** version test → mismatch = "Preferences Data Version
  Invalid" → missing. HIGH.
- **Missing/invalid** (`FUN_10004540`): zero the block, version, `FUN_10004ae0` (names, "Player %i", scores
  16000−1000k, "New Atlantis"), `FUN_10004f20(1)` (bytes 0–3, 8, 9 = 0, **10 = 1**, 11 = 0, int 3 = 1, then
  `FUN_100050f0`: byte 4 = 1, 5/6/7 = 0, ints 0/1/2 = 50/100/50, both key sets), **written at once** ("Default
  Preferences Saved"). A corrupt file is therefore overwritten at boot. HIGH.
- **Write** (`FUN_10004640`): copy to a temp, obfuscate the copy's names (involution `FUN_10046470`: per byte nibble-swap
  then XOR 0xFF, over `strlen` of the plain name; the NUL and the bytes after it are left raw), +0x24A8903 /
  −0x5969FBD0, `FSWrite` 0x34f0 + `SetEOF`; HCreate if absent. Callers: fresh prefs (boot) and **quit only**
  (`FUN_10000630 → FUN_100045f0`, guarded by a flag set at load, so every quit writes). Dialog Save, name entry, int
  pref 3, F6, cheats, −/= all change memory only (C7). HIGH.
- Quirk: a name byte 0xFF obfuscates to 0x00 and truncates that name at the next load; arbitrary files are not
  byte-exact round-trippable — files the original wrote are (no 0xFF in names). HIGH (arithmetic).
- **No original prefs file exists on this Mac or in the archive** (mdfind "Deimos Rising Prefer…" empty; archive
  `Local/pref` holds only `Icon`; no `pref` tag in any pak). Tests must build expectations from the arithmetic.
- **Swift today:** `Core/Sources/DeimosCore/Game/DeimosPrefs.swift:6` (typed fields only, `fresh` :46 matches the
  defaults incl. byte 4 = 1, byte 10 = 1); `DeimosText.swift` already implements `FUN_10046470`; `MacRoman` (HectorResources)
  is available to Core. **Missing:** the 0x34f0 codec, ints 4–99, both reserved blocks, the pad, the dead ints, raw
  name bytes (a String cannot keep bytes past the NUL — byte-exact round trip needs the raw image), file I/O, the
  boot/quit lifecycle, threading prefs out of a session (driver stand-in 6, `DeimosHost/DeimosDriver.swift:49`, :232).
- **A task must add:** a Core codec `DeimosPrefs(fileBytes:) / fileBytes` (big-endian, obfuscation, offsets above;
  keep the raw image so unknown bytes survive), version/size checks as the original, fresh = file of `fresh`; the App
  owns the path (design §7.5: `~/Library/Application Support/Ambrosia Classics/Deimos Rising/Deimos Rising Preferences`;
  never `UserDefaults`; Core stays Foundation + HectorResources + HectorAudio, no `String.Encoding.macOSRoman`), reads at
  boot before the dialog test, writes on fresh and at every quit path (⌘Q / File▸Quit / Q / QUIT / AppleEvent,
  i.e. `applicationWillTerminate`), and threads the live prefs in and out of each session (high scores, int 3,
  bytes 5/9/11, int 0).

## 2. The configuration dialog — DLOG/DITL 190 "Game - Preferences"
DLOG 190 (R): 379×377 (t30 l16 b407 r395), procID 1, invisible, empty title, position 0x280A (centre main screen, MED);
`dlgx` 0x0B (theme background/controls), `DLGX` font Charcoal, `dftb 190` Geneva 9 (code also forces Geneva 9:
L `FUN_100458c0`, `FUN_10045670` on items 5–10, 17–19).
| # | kind | rect t,l,b,r | text | drives | conf |
|---|---|---|---|---|---|
| 1 | button (default) | 344,290,364,360 | Save | keep live edits, close | HIGH |
| 2 | button (cancel) | 344,212,364,282 | Cancel | restore the 0x34f0 snapshot (keys too), close | HIGH |
| 3 | button | 344,14,364,90 | Defaults | `FUN_10004f20(0)` = `FUN_100050f0`: bytes 4–8, ints 0–2 **and both key sets**; not 9/10/11/int 3 | HIGH |
| 4 | button | 344,97,364,167 | Revert | restore the snapshot, re-apply volume, refresh; grey again | HIGH |
| 5/6/7 | group box (CNTL 200/201/202, proc 164) | 17,22,78,356 / 85,22,195,356 / 202,22,279,356 | Video / Audio / Controls | — | HIGH |
| 8 | checkbox | 34,49,52,331 | Full Screen (Takes Effect on Relaunch) | byte 4 | HIGH |
| 9 | checkbox | 54,49,72,331 | Interlacing  (Faster but lower quality) | byte 5, live next frame | HIGH |
| 10 | checkbox | 138,49,156,251 | Bypass System Volume | byte 7; activates item 12 | HIGH |
| 11 | static (disabled) | 162,66,176,154 | Sound Volume: | — | HIGH |
| 12 | control **CNTL 2000 — absent from the fork** | 162,158,184,298 | — | int 0, `FUN_10047920` + `SysBeep(1)` on release | HIGH ref / LOW look |
| 13 | static (disabled) | 162,301,176,335 | 100% → "%i%%" of int 0 | label | HIGH |
| 14 | static (disabled) | 110,51,125,136 | Music Volume: | — | HIGH |
| 15 | control **CNTL 2001 — absent** | 108,138,130,278 | — | int 1, same as 12 | HIGH ref / LOW look |
| 16 | static (disabled) | 109,281,123,315 | 100% → "%i%%" of int 1 | label | HIGH |
| 17 | checkbox | 253,49,271,331 | ESC Key Delay  (Requires key to be held down) | byte 8 | HIGH |
| 18 | button | 225,51,245,151 | Set Controls… | L: `ISpConfigure`; **X: controls window §3** | HIGH |
| 19 | button | 225,169,245,331 | Set Gamepad Controls... | L: hidden always; **X: hidden only if HID unavailable**, else HID window | HIGH |
| 20 | static (disabled) | 302,38,338,361 | (Hold down Option during launch to display this dialog) | — | HIGH |
Item 12/15 action procs: ±1 arrow, ±10 page, live relabel, pinned by the control's own min/max (micro-wave §1) — the
min/max/proc live in the missing CNTLs. Unused leftovers: CNTL 1000/1001 popups → MENU 1000/1001 "Off,1…7,Full".
**Behaviour** (L `FUN_10010fc0` 10010fc0..10011590 / X `FUN_10011240` 10011240..100117a0; refresh L `FUN_10011590`, X `100117a0`):
- Opens: at boot when Option (0x3A) is held or byte 2 == 0 (`FUN_100047c0(1)`, before the display exists; afterwards
  byte 2 = 1); from the main menu PREFERENCES button or `P` key (`FUN_10024e40` → `FUN_100047c0(0)`, then menu music
  restart flag `0x100e01b6`). No menu-bar item. Fullscreen: the display is suspended around it (L 10010fe4..10011008). HIGH.
- Open with param 1 (boot): no cancel item, item 2 deactivated (L 10011238..10011240; X 10011418..10011428). HIGH.
- At open, **L deactivates item 8 Full Screen** (10011184..10011188); **X does not**, and instead deactivates items
  10, 12, 11, 13 (X 10011348..10011380) — on OS X "Bypass System Volume" can't be ticked, so the sound slider stays grey
  unless byte 7 was already 1 (refresh activates 12 iff byte 7: L 10011708..10011724, X 10011904..10011934). Item 4 grey;
  re-activated before each `ModalDialog` once anything changed. HIGH.
- Toggles take effect in memory at once; nothing is written to disk until quit. Volume changes re-apply the device volume
  (`FUN_10047920`; "unless OS X", sound-music §4.3) and beep. Byte 4 changes nothing in either build (relaunch text is
  aspirational in 1.0.6: display §8.1; X's display use of byte 4 at X 10000230 unread). After close: `FUN_10047920`,
  `DisposeDialog`, display resumed. HIGH.

## 3. The controls window — DLOG/DITL 191 "Game - Controls" (OS X fragment only; closes INDEX #14)
DLOG 191 (R): 303×324 (t40 l16 b364 r319), procID 1, position 0x680A (centre parent's screen, MED); dftb 191 Geneva 9.
| # | kind | rect t,l,b,r | text / res | role | conf |
|---|---|---|---|---|---|
| 1 | button | 291,215,311,285 | Save | copy both working sets into prefs +0x14b8/+0x14d4, return 1 (X 1004386c..100438ec) | HIGH |
| 2 | button | 291,128,311,198 | Cancel | discard, return 0 | HIGH |
| 3 | tab control CNTL 191 (proc 128, value 6000 → `tab#` 6000 "Player 1","Player 2") | 20,18,276,285 | — | value 1/2 → current player; fields refilled, focus → 5 (X 10043798..10043848) | HIGH |
| 4 / 5 | PICT 190 Up Arrow / edit | 56,151,69,164 / 75,128,89,186 | placeholder text | slot 0 up | HIGH |
| 6 / 7 | PICT 191 Left Arrow / edit | 103,46,116,59 / 102,65,116,123 | | slot 1 left | HIGH |
| 8 / 9 | PICT 192 Right Arrow / edit | 103,255,116,268 / 102,191,116,249 | | slot 2 right | HIGH |
| 10 / 11 | PICT 193 Down Arrow / edit | 148,151,161,164 / 128,128,142,186 | | slot 3 down | HIGH |
| 12 / 13 | PICT 195 Fire Air Weapon / edit | 185,69,201,184 / 186,191,200,249 | "Air" | slot 4 fire air | HIGH |
| 14 / 15 | PICT 196 Fire Ground Weapon / edit | 211,69,227,184 / 212,191,226,249 | "Ground" | slot 5 fire ground | HIGH |
| 16 / 17 | PICT 197 Select Special Weapon / edit | 236,69,252,184 / 237,191,251,249 | "Select" | slot 6 select | HIGH |
### 3a. Behaviour (X `FUN_100435d0` 100435d0..10043924; fill `10043930`; name `10043b40`; assign `10043c00`; filter at 10043f90)
- Caller: config dialog item 18 (X 100115fc..10011614) passes `prefs+0x14b8`, `prefs+0x14d4`; a Save marks the outer
  dialog changed (Revert lit), and the outer Cancel/Revert undo it (whole-record snapshot). HIGH.
- Open: working copies of both sets (10043628..100436c4), tab = P1, focus = item 5, fields filled, item 5 selected,
  `ModalDialog` with a filter (UPP from TOC −0x6bec; the 10043f90 body — TOC not resolved, MED).
- **Key capture (filter):** keyDown/autoKey → virtual key code `(message >> 8) & 0xFF` → assign, event consumed (so
  Return/Enter/Esc/Tab/F-keys/arrows are all bindable and never press Save/Cancel); null events poll `GetKeys` edges for
  **left Control 0x3B, Shift 0x38, Option 0x3A, Command 0x37** only (1004404c..100441ac). Caps Lock, right-hand
  modifiers, Fn: never bindable. Mouse on a field → focus it. HIGH.
- **Assign** (`10043c00`): name = `STR# 130` "Game Keys" entry code+1 (128 entries; gaps read "Unknown"), codes outside
  0…0x7F or an empty entry → "??" (data 0x100f5835). **Refused**: the code equals any of the 14 working slots (both
  players) **unless** the focused field's current text equals the new name → `FlushEvents` + `SysBeep`, nothing
  changes. Otherwise set the field text, store into the current player's slot, focus advances 5→7→9→11→13→15→17→5. HIGH.
  Quirk: the self-match is by name, so two different "Unknown" keys can end up duplicated (LOW impact).
- Defaults per player: as §1a (P2 = kp8, kp4, kp6, kp5, End, Fwd-Delete, Page Down). No Defaults button in this window.
### 3b. The consumer — INDEX #14 closed
X `FUN_1004cdf0` (1004cdf0..1004d1c8) is the OS X per-pass input read (callers X 10006c04 game loop, 1002ebec/1002ed24
level select, 10030924 frame controller — same sites where L calls the ISp poll): for each player it fetches the set
(X `FUN_10004f20(player, &buf)`: `prefs + 0x14b8 + 0x1c·player`) and `GetKeys`-tests each code (`FUN_1004a4b0`):
slot 0 → byte [0] up, 1 → [3] left, 2 → [1] right, 3 → [2] down, **4 → [5] fire air, 5 → [4] fire ground, 6 → [6]
select** (1004ce18..1004cf08); then, if the HID layer is up (`FUN_1004b300`), ORs HID pad bytes per player
(`FUN_1004ba30(0,…)` P1, `(1,…)` P2, 1004cf1c..1004d138). Slot meanings are now HIGH and match
`Core/Sources/DeimosCore/Game/KeyTable.swift:18` `slotBits`. Level select uses **P1's set** (left/right, any fire = accept).
### 3c. The original's own gamepad (OS X): DITL 192 "Game - HID Controls" (433×364; tab control CNTL 192 Player 1/2;
buttons Up, Down, Left, Right, Fire, Bomb, Select each beside a "---" binding label) and DITL 193 "Game - HID Calibration"
(410×235; "Press the controller to the far left… Release… far right… please wait…", per axis). Code X 1004b050..1004e800;
config persisted to a separate file "Deimos Rising HID Data" (fopen "wb"/"rb", `FindFolder(kOnAppropriateDisk,'pref')`),
needs `HID.bundle` (libHIDUtilities.dylib) in ` Data`. G confirms: "If you are running Mac OS X, you can configure your
key settings and your gamepad settings separately … press Set Gamepad Controls…". HIGH for existence; MED for details.
- **Swift today:** `KeyTable.swift:13` (slot map), `Seams/HeldKeys.swift:7` (held set + `capsLock` + `typed`),
  `Seams/PlayerInput.swift:6`, `App/DeimosController.swift:266` `heldKeys` (polls HectorShell). No dialog, no DITL/STR#/
  PICT reader in Core (only `deimos-census/AppResourceFork.swift:11`), and the `.rsrc` is **not staged into the app**
  (`project.yml` stages only `Data`). Ferazel precedent for a drawn dialog: Core model
  `Ferazel/Core/Sources/FerazelCore/Front/PrefsDialogModel.swift:13` (incl. key capture), resource types
  `Front/DialogResources.swift:44/98/184/220`, App draws; Windows renderer `Ferazel/Windows/Sources/FerazelWinKit/DialogRenderer.swift`.
- **A task must add:** stage `Deimos Rising.rsrc`; Core models of DITL 190/191 (items, rects, texts, enabled/hidden,
  focus, the capture rules above, Defaults/Revert/Cancel snapshot semantics, first-launch no-cancel) driven by events,
  drawn by the App from the model (Windows reuses the model); key names from STR# 130; PICTs 190–197 via HectorGraphics.

## 4. The game controller (D45 item 5: "as the original's keys (D36/D37 shape)")
**Kit (HectorKit D16):** `Sources/HectorInput/ShellPad.swift:7` `ShellPadButton` (positions), :21 `ShellPadState`, :43
`ShellPadBinding` (`.key`, `.keyAfterHold`, `.capsLockToggle`), :54 `ShellPadMapping`; `Sources/HectorShell/ShellGamepad.swift:21`
— **`padState()` unions every connected controller (:33–43); there is no per-pad identity**; `ShellView.swift:56`
`padMapping` (nil = off, Deimos today), :15 `padKeyDown`. `pollKeyState()` returns keyboard ∪ pad held, Caps Lock ‖ latch —
so in Deimos the pad lands in `HeldKeys` with no Core change (`DeimosController.swift:271`).
**BTX:** `BubbleTroubleX/Shared/BTXPadLayout.swift:21/35` (`mapping(keySet:inPlay:dialogUp:)`), wiring
`App/BTXController.swift:653–678` (assign before each poll; pad Return/Esc into dialogs), tests
`Windows/Tests/BTXWinKitTests/WinGamepadTests.swift:91–274` (10), `GAMEPAD.md` (69 lines).
**Ferazel:** `Ferazel/Core/Sources/FerazelCore/Input/FerazelPadLayout.swift:27/43` (context table :11–19), wiring
`Ferazel/App/FerazelController.swift:503–527`, tests `Core/Tests/FerazelCoreTests/PadLayoutTests.swift:12/46/101/167` (4),
`GAMEPAD.md` (60 lines). Ben was told: works out of the box, buttons by position, + pause, − held 1 s aborts, remapping
the keys remaps the buttons, no pointer, no pad set-up screen.
**Deimos under the same shape** (layout in Core `Input/DeimosPadLayout.swift`, Foundation + HectorInput only — HectorInput
is not yet a DeimosCore dependency: a Package.swift change):
| context | d-pad / left stick | face (S E W N) | shoulders / triggers | + | − | forced by D36/D37? |
|---|---|---|---|---|---|---|
| in play (session running, not paused) | P1 set slots 0–3 | slots 4/5/6 assignment = **Q4** | **Q4** | Caps Lock latch (pause is the lock state, `FrameKeys.swift:48`, driver :273) | Esc after 1 s hold (stacks with byte 8's 16-frame hold) | d-pad, +, − yes |
| paused | — | — | — | latch | — | yes |
| level select | P1 slots 1/2 (it reads P1's set) | P1 slots 4–6 (accept) | — | — | Esc (→ `none`, back to menu): hold or not = **Q5** | slots yes; − no |
| main menu | arrows (menu ignores them) | Return = 1 PLAYER | — | Return | — (no Esc action) | yes; 2 PLAYER from pad = **Q5** |
| name entry, scores, credits, dialogs | arrows | Return | — | Return | Esc | yes (face = accept default name) |
| demo film | — (keys never end a film, D45 ruling 1) | — | — | — | — | yes |
F6 interlace, −/= volume, ~ console: unmapped (D36 "shoulders… unmapped" precedent; not forced). Two players on two pads
needs a kit change (per-controller states, e.g. by `GCController.playerIndex`) — HectorKit decision, **Q3**.

## 5. Menus and system events touching prefs or these dialogs
MBAR 128 = MENU 128 (Apple: "About Deimos Rising…" → credits; disabled in a game `FUN_10049320`), 2000 File ▸ Quit ⌘Q,
2001 Edit (all disabled). No Preferences menu item. Quit paths (File▸Quit, ⌘Q via MenuKey, Q key, QUIT button, Quit
AppleEvent `0x10049c50`) all reach shutdown → prefs write. In play the loop reads `GetKeys` only, so ⌘Q does nothing
there in the original. Suspend/resume (osEvt) never touches prefs; the dialogs suspend/resume the DSp display themselves.
X's menu handling ("sPriv_Menu_File", OS X app menu) unread. Swift today: app menu Quit ⌘Q + hidden Full Screen
(`App/DeimosController.swift:213–222`); no save on terminate.

## 6. Open questions and risks
**(a) Facts still unread**
1. X HID layer 1004b050..1004e800: default bindings (if any), element→byte rules, calibration math, HID Data format.
2. X filter/jump tables (TOC −0x6bec/−0x6bf0/−0x6bf4): addresses inferred from code shape; resolve r2 to confirm.
3. Contents of the prefs block before `FSRead` (allocation of `_DAT_100def40`): decides the short-file case.
4. **Whole-game diff L vs X**: every bank rule is L's; X is what Ben played (D30 TickRate .osx). Only the input, dialog
   and prefs paths were compared here. A full diff (function-by-function size/shape) is unrun.
5. X display use of byte 4 (X 10000230 → display init) and X menu-bar set-up.
6. What the original drew at DITL 190 items 12/15 (CNTL 2000/2001 missing from the fork): min/max/look unknown.
**(b) QUESTIONS FOR BEN**
- Q1. Where the two builds differ (Full Screen greyed in OS 9 / Bypass System Volume + sound slider greyed on OS X;
  Set Controls = Apple's InputSprocket panel vs the game's own window; Set Gamepad Controls shown on OS X only), which
  one does the replica follow?
- Q2. The OS X original had its own gamepad windows (per-player binding + calibration, its own file). Build those, the
  D36/D37 fixed layout, or both?
- Q3. Two pads for two players (kit change), or one pad for player 1?
- Q4. Which pad buttons fire air, fire ground and select?
- Q5. Pad on the menu/level select: a way to start 2 PLAYER; is − in level select a 1 s hold?
- Q6. Dialog look and place: OS X Aqua (what he saw) or classic Platinum; centred on the black 640×480 canvas?
- Q7. "Full Screen (Takes Effect on Relaunch)": inert as in 1.0.6, or drive the replica's full screen at next launch?
- Q8. The volume controls at items 12/15: does he remember sliders, scroll bars or Off/1–7/Full pop-ups?
**Risks:** (R1) bank-is-the-wrong-fragment (a.4); (R2) quit paths that bypass the save (force quit = original loss,
fine; ⌘Q in play must still save); (R3) the String-typed names lose raw bytes → keep the raw image; (R4) the
reserved 12 KB must survive untouched; (R5) a pad held across a mapping change (D16 "ignored until released") — the
menu→play switch must not fire; (R6) the dialog at first launch shows before any logo, so the window must exist first.

## 7. Suggested tests (bounded; expectations computed, no golden fixture needed)
Prefs (≈ +7): `testFreshPrefsFileImage` — 0x34f0 bytes; BE 0x00002714 @0; @0x08 = 1, @0x0e = 1; BE 50/100/50/1 @0x68;
@0x1260 = 15000+0x24A8903 BE; @0x129c = 0xA6960430; @0x10f8 = obfuscated "Mars"; keys @0x14b8. `testPrefsRoundTrip` —
write(read(write(fresh))) byte-equal, and a record with poked bytes in both reserved blocks, the pad and ints 4–99
survives. `testVersionMismatchIsFresh` (and the fresh file is written). `testNameObfuscationOverStrlen` (bytes past
the NUL untouched; 0xFF truncation quirk). `testNamesDecodedBeforeVersionCheck`. `testQuitWritesSessionChanges` (App/
Host: int 3, scores, byte 11 reach disk only at quit). `testBootDialogRuleByte2AndOption`.
Dialog 190 (≈ +8): `testDITL190Parse` (20 items, rects/texts above, items 12/15 → 2000/2001), item→pref toggles,
`testDefaultsResetsKeysNotBytes9to11`, `testCancelRestoresSnapshotIncludingKeys`, `testRevertGreysUntilChange`,
`testFirstLaunchHasNoCancel`, the per-build greying (after Q1), slider pinning 0…100 assumed (after Q8).
Controls 191 (≈ +7): `testDITL191Parse` (17 items, tab# Player 1/2), `testCaptureNamesFromSTR130` (0x31 "Space",
0x7E "Arrow Up", 0x80 → "??"), `testFocusAdvancesAndWraps`, `testDuplicateAcrossPlayersRefused` (beep, no change),
`testSameKeyInSameFieldAccepted`, `testModifiersOnlyLeftFour` (0x39 Caps Lock never binds), `testTabSwitchRefillsFocus5`,
`testSaveWritesBothSetsCancelNone`; `KeyTable` slot map pinned to X 1004ce18..1004cf08.
Controller (≈ +4, Ferazel shape): play layout follows the live key set; out-of-play arrows/Return/Esc; + latch; − hold 1 s.

## 8. Corrections to docs/deimos found (list only)
1. engine-loop.md §1: the data fork carries three fragments (PPC @0, **OSX @0xf67c0**, FATCarbon stub); "not a Carbon one" holds for fragment 1 only; every bank address is fragment 1's.
2. INDEX #14, engine-loop.md §8, timing-frame.md §6: the key-set consumer is X `FUN_1004cdf0`; slot meanings HIGH (4 = fire air, 5 = fire ground, 6 = select); key window = DITL 191 in X.
3. engine-loop.md §10: "≈0x1000 bytes from 0x0b0" wrong — byte prefs 0x04–0x67 (100), int prefs 0x68–0x1f7 (100), reserved 0x1f8–0x10f7 and 0x14f0–0x34ef, pad 0x125d–0x125f; table omits byte 7 and byte 11.
4. file-pict-alerts-manager.md §5 / timing-frame.md §6: item 19 is hidden only in L (X shows it when HID loads); item 18 → ISpConfigure in L only; L deactivates item 8 at open (10011188), X deactivates 10–13 (X 10011348..10011380) — unrecorded.
5. timing-frame.md §6 / micro-wave §1: items 12/15 reference CNTL 2000/2001, absent from the shipped fork.
6. engine-loop.md §10: pak fallback exists but the shipped `Local/pref` folder is empty.
Outside docs/deimos: design 2026-10-06 Q8 ("OS X keyboard path … unreachable from this classic binary") and
`DeimosPrefs.swift:15` / `KeyTable.swift:8` ("slot meaning LOW") are superseded by §3b.

## 9. Rough size
Prefs file codec + lifecycle: **medium**. Dialog 190 (model + drawn + rsrc staging, shared with 191): **large**.
Controls 191: **medium**. Controller, one pad, D36 shape: **small**; two pads (kit change): **medium**; the original's
HID windows 192/193 (if Q2 says so): **large**, and needs (a.1) read first.
