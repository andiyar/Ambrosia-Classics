# Ferazel's Wand 1.0.3 — New Game / save / continue flow, saved-game file, engine open items

**Code readings only; nothing behaviour-verified.** Date 2026-10-03.
Sources: main dump `ghidra/Ferazel_pef.decompiled.c` (cited "l. N"), handler dump
`ghidra/Ferazel_handlers.decompiled.c` ("handler l. N"), raw disassembly
`ghidra/Ferazel_pef.disasm.txt` (cited by address), data section via `tools/const.py` / `tools/pef.py`,
resource forks via `tools/rsrc_census.py`. TOC r2 = 0x100a7840.
Scope: `.NewGame`, `.ContinueGame`, `.SavePointSave`, `.DoSaveGame`, `.EndLevelSGUpdate`, `.SaveSG`,
`.OpenSG`, `.IncrementLastSGString`, `.AskToContinue`, `.SetupLevel` restore branch, save-point
sprite trigger, saved-game file format, dialogs, what is / is not persisted; INDEX NOT-RESOLVED
items 8, 9, 2, 13. Extends engine.md §6/§8/§9 and world-data-format.md §3.2/§4 (read first).
⚑ wave 2 (2026-10-04): §9 adds INDEX 24's save-point faces, hold timing and the `OpenDefaultWorldLevel`
failure (PICT 1065 decoded with an own PackBits reader; frame order from platforms-ropes-radial-2 §8).

Global flags used below (TOC slot → meaning; all byte flags unless noted):

| TOC slot (decompiler name) | address | meaning (from the readers/writers below) | label |
|---|---|---|---|
| `_DAT_1009fd48` | 0x100f007d | "continue requested": set by NewGame/ContinueGame when AskToContinue answers yes; MainMenu then calls `ContinueGame(fd18)` | [HIGH] |
| `_DAT_1009fd4c` | 0x1024b510 | "aborted from the world map" (ShowWorldMap) | [HIGH] |
| `_DAT_1009fd50` | 0x1024b50f | "quit the application from the world map" | [HIGH] |
| `_DAT_1009fd54` | 0x102baf20 | "a saved-game file is known this run" (SaveSG/OpenSG set 1; NewGame clears) | [HIGH] |
| `_DAT_1009fd18` | 0x102badc4 | 88-byte `StandardFileReply` of the last saved/opened game file | [HIGH] |
| `PTR_DAT_1009fe00` | 0x102baf22 | "a save was written or loaded this game" (SaveSG/OpenSG set 1; NewGame clears); gates the death screen | [HIGH] |
| `_DAT_1009fd5c` | 0x1024b4e2 | "use the default world file" (MainMenu, File menu, ContinueGame set 1) | [HIGH] |
| `_DAT_1009ffa8` | 0x1024b4c6 | "player died" (GameLoop sets on G+4 < 1; InitGameGlobals clears) | [HIGH] |
| `_DAT_1009fe68` / `_DAT_1009fe64` | 0x10225a08 / 0x10225a0a | player x / y in whole px (i16), rewritten every frame from sprite `+0x14>>8` / `+0x1c>>8` (`.HandlePlayerSprite` 0x100513b4..0x100513e0) | [HIGH] |
| `_DAT_1009feac` | 0x102259fe | current level number (i16) | [HIGH] |
| `_DAT_100a0054` | handle | the 0xebe58-byte save block | [HIGH] |

---

## 1. New Game (`.NewGame @ 1000b11c`, l. 5669–5835)  [HIGH unless noted]

Entry points: main-menu button 1 or key N (`.MainMenu`, l. 7268), File menu item 1 (`.HandleFileMenuSelection`,
l. 28807). Both set `fd5c = 1` first, so the "pick another world" branch is unreachable from the UI.

1. `FlushEvents`, `KillAllSprites`, `InitGameGlobals` (G defaults, engine.md §9; also `save+6 = 0`
   when the save handle exists, l. 824), `fe00 = 0` ("no save this game", l. 5713).
2. `OpenDefaultWorld("Ferazel's Wand World Data")` → `Mwld 0`; `InitMapLevelNames`.
3. Start level — raw 0x1000b2b8..0x1000b2cc: default world, Option not held, debug flag
   `_DAT_100a0064` clear → **literal level 1** (`li r3,0x1; bl OpenDefaultWorldLevel`). `Mwld+0x1c4`
   is read only with the debug flag set or on the (unreachable) custom-world path. Option held without
   the debug flag → dialog "Ferazel sez: No more cheating!" (0x100a2e31) then level 1.
4. `fd54 = 0` (no known save file), loop until `DAT_100a5106`:
   - `G+0x16 ← hdr[0x26c8]` **every level** (raw 0x1000b3d8 `lbz r0,0x26c8(r3)`, 0x1000b3dc
     `sth r0,0x16(r21)`), then `GameLoop(hdr+0x2848 − 32, hdr+0x2846 − 32, 0, 1)`.
   - level complete and not victory → `ShowWorldMap()`; result < 0 → end loop; else
     `OpenDefaultWorldLevel(n)`, level ← n. If `fd50` → `Quit`. If not aborted (`fd4c == 0`):
     `save+0xc ← hdr+0x2848 − 32`, `save+0x10 ← hdr+0x2846 − 32` (l. 5797–5800).
5. After the loop: `G+4 < 1` (died) → `RestorePreExistingWindowBackground`, `AskToContinue()`; yes →
   `fd48 = 1` and return (MainMenu resumes, §5). Then victory → `.Victory`; else back to the menu,
   music track 24 (0x18).

`GameLoop(x, y, a3, a4)` (l. 5058): `x,y` = player spawn (sprite top-left, px; also stored to
fe68/fe64), `a3` → player sprite `+0x46` (0 from every caller), `a4` only gates the level-start gamma
fade on `hdr+0x2712` (0 in all 24 levels) [HIGH]. Every level entry also sets
`G+0x23e+2·L = 1` (unlocked) [HIGH].

## 2. Save points — the only way the shipped game writes a save  [HIGH unless noted]

### 2.1 Trigger (`.HitPlayerSprite`, handler l. 4181–4205; raw 0x10057714..0x10057858)

The player **landing on** a sprite of type **1065 (0x429)** runs the steps below. 1065 is Box class
(world-data §3.5): it is handled in the **Box arm** of `.HitPlayerSprite` (the arm entered on the
contact's handler == Box, `lwz r3,−0x73bc(r2)` at `0x10056b18`; Box handler pointer 0x100a0484 →
0x1006d878 `.HandleBoxSprite`), after the `PlatformBounce(player, box, …)` call, and only on its
**landing result** (return 1 — the same landing that feeds the geyser, trampoline, spin-stomp and
teleporter arms, pickups-boxes §2.1); the type test is `cmpwi r3,0x429` at `0x10057714` (`bne
0x1005855c`). There is **no** `+0xa6`/`+0xb0` gate: `.SetupBoxSprite` sets `+0xa6 = 3` for every Box,
and the `+0xa6 == 0 && +0xb0 == 0` test (handler l. 3282) is the **Bonus** pickup gate
(pickups-boxes §1.2; `PTR_PTR_100a047c` → TV 0x100a2264 → 0x1005e934 = `.HandleBonusSprite`), not the
save point's — a replica using it would never save [HIGH] ⚑ corrected (review 1a, 2026-10-03) #3, #9
— earlier "touching … Box class (`PTR_PTR_100a047c`) whose `+0xa6 == 0` and `+0xb0 == 0`". This
account and pickups-boxes §2.4.8 now describe the same path; the step table here is the detailed one.

| step | code | raw |
|---|---|---|
| gate 1 | `DAT_100a53d6 != 0` — the "no async gamma fade running" flag (cleared by `GammaFadeIn/OutAsync`, set when the fade ends, l. 31650–31745; initial 1 at `const.py 100a53d6` → `01`) [MED for the name] | 0x1005771c |
| gate 2 | placement **param 1** of the save point's record (`hdr + idx·16 + 8`, idx = sprite `+0x48`) == 0 | 0x10057740 |
| hold | counter `*_DAT_100a0684 += 2`; fire only when it exceeds 15. `.HandlePlayerSprite` moves the counter 1 toward 0 every frame (0x1004de68..0x1004de98), so ≈15 consecutive landing frames (standing on the point) are needed ~~[MED: frame order]~~ ⚑ wave 2 (2026-10-04): HIGH — fires on the 15th consecutive landing frame (§9.2) — HIGH for the counter arithmetic; "standing still lands every frame" (§9.2, RectBounce l. 36297) is MED, so the frame count while standing is MED ⚑ corrected (review 2g, 2026-10-04) #8 | 0x10057754, 0x10057768 |
| fire | counter ← −150 (0x10057774); record param 1 ← player `+0x17e` (facing-left) + 1, i.e. 1 = faced right, 2 = faced left (0x1005778c..0x100577a0); `G+0x16 ← player +0x17e` (0x100577b0); `SavePointSave()` (0x100577b4) | |
| success | `snd 420` "teleport in" + `snd 421` "teleport out" (handles `_DAT_100a03e0/03dc` ← `FUN_10091748(0x1a4/0x1a5)`, l. 39562–39564), `GammaFadeOutAsync(2, …, 0xc, 0x10)`, three `HandleAsyncGammaFade`, `GammaFadeInAsync(0x2d)` — a short flash [MED: visual] | 0x100577c4.. |
| failure / cancel | record param 1 ← 0 — the point stays usable | 0x1005783c |

The record write precedes the snapshot, so the used marker is saved with it: **each save point works
once per game, even after resuming** (manual TEXT 130 agrees: "Once Ferazel has used this saved game
point, he can't use it again"). Visual: `.SetupBoxSprite`/`.HandleBoxSprite` (handler l. 11517,
12409) set face `*_DAT_100a0a28 + param1·0x34` from `PICT 1065 'save point'` (Sprites, 252×100 =
3 faces of 84×100, `LoadEncFaceSetFromPICT(0x429,3,0x54,100,…)`, l. 47417): face 0 idle, 1/2 used
~~[MED: face art not inspected]~~ ⚑ wave 2 (2026-10-04): decoded — 0 empty pedestal with a green check, 1 stone statue facing right, 2 facing left (§9.1); Setup also sets no gravity (`+0x110 = 0`), `+0x185 = 1`, hot rect
`SetRect(+0x34, 0x21,0x3f,0x33,99)`.

Census (all 24 levels, records of type 1065): **91** save points (89 with spawn flag 1, two with 0:
level 3 rec 216, level 22 rec 66); all params 0; none in 67 Xichra's Lair or 70 Purple Haze. Per
level: 1:2, 2:3, 3:6, 4:6, 5:2, 10:5, 11:4, 15:7, 18:2, 20:3, 21:5, 22:8, 25:2, 30:8, 31:5, 40:2, 45:5,
50:6, 51:3, 52:3, 55:1, 62:3 [HIGH, Python over `Mlvl`].

### 2.2 `.SavePointSave @ 1000c104` (l. 6287–6460)

Raw-verified order: `InputActivate(0,0)`, `FlushEvents(0xff7f)`;
`save+0 ← Mwld+0x100` (0x1000c168); `GetDateTime(save+0x19990)` (0x1000c178 `addis 2`,
`subi 0x6670`); `save+6 ← 1` (0x1000c1a0); `save+8 ← level` (0x1000c1b0);
`G+0x176+2·L ← 1` (0x1000c1c0); G copy 0x332f × 8 B to `save+0x18` (`addi r5,r3,0x10` +
`stwu r3,0x8(r5)`, 0x1000c1cc..0x1000c1e0 — the decompile's `save+0x10` hides the +8);
`save+0xc ← (i32)playerX` (0x1000c204), `save+0x10 ← (i32)playerY` (0x1000c214); `save+4 ← 0`,
`save+5 ← 0`; then 511 records `hdr+4+16i` → `save+0x19998+0x2000·L+16i` (base 0x1000c264
`subi 0x6668`) with record `+0xe` (x) and `+0xc` (y) each −6 (0x1000c2a4 `subi 0x665a`,
0x1000c2cc `subi 0x665c`). Finally `SaveSG(prefs[1] == 0)` (0x1000c804..0x1000c814) and a full
redraw. Returns SaveSG's result.

So a save stores **the player's position at the moment of the save** (on the save point), not the
level start.

### 2.3 Other writers of the save block

- `.EndLevelSGUpdate @ 1000c8d8` (l. 6466): identical stamp/date/+6/+8/0x176/G/+0xc/+0x10/
  snapshot writes, but **no** `+4/+5` write and **no** `SaveSG` — memory only. Called by `GameLoop`
  on level completion (raw 0x1000a408). There is **no autosave**: completing a level does not touch
  the disk.
- `.DoSaveGame @ 1000bfb0` (l. 6240): world name → `save+0xe7d98` (raw 0x1000bfe4/0x1000bfe8), stamp,
  date, G copy, `+4/+5 = 0`, `SaveSG(1)`; it does **not** write `+6`, `+8`, `+0xc/+0x10` or the
  snapshot. Its only caller is `.ConfirmAbortGameDialog` item 5 (raw 0x100068b4 `cmpwi r0,0x5` →
  0x10006904 `bl DoSaveGame`) — and the shipped `DITL 202` "Abort Warning" has only 4 items
  (1 OK, 2 Cancel, 3 PICT 145, 4 text `^0`). **DoSaveGame is unreachable in 1.0.3** [HIGH: code +
  DITL decode]. Consequences: every shipped save has `+6 = 1`; the world-name field `0xe7d98` is
  never written by the shipped UI (stays as allocated — `NewHandleClear`, so an empty pstr — or as
  loaded from an older file).
- `.NewGame` / `.ContinueGame` post-map write of `+0xc/+0x10` (§1, §4).
- `.HandleLineActions` (conversation action code 10, l. 50376): sets the spawn flag
  (`+0`) of record `i` in level `L`'s snapshot to 1 — a conversation can make a sprite appear in
  another level, effective only if that level's `G+0x176` flag is 1 when re-entered [HIGH for the
  write; MED for the action-code meaning, Mcnv encoding is INDEX item 3].
- `.InitGameGlobals`: `save+6 = 0` (l. 824).

## 3. Saved-game file (`.SaveSG @ 10048294`, `.OpenSG @ 10048608`)  [HIGH unless noted]

### 3.1 SaveSG(prompt)

- `prompt == 0` **and** `fd54` set → silently reuse the reply in `fd18` (pref "Reuse saved game
  files", prefs+1). Otherwise: build ParamText `^0` = "at a checkpoint on level " (0x100a587f) if
  `save+6` else "at the beginning of level " (0x100a5899) + level number; `IncrementLastSGString`;
  `PromptPutFile("Please name your saved game." (0x100a58b4), default name prefs+0x42, reply)`.
- `.PromptPutFile @ 1004258c` = `CustomPutFile(prompt, name, reply, dlgID 0x3eb = 1003, …)` (raw
  0x10042590 `li r6,0x3eb`). `DITL 1003`: Save, Cancel, help, volume, Eject, Desktop, list, popup,
  line, name edit, prompt "Save as:", New-Folder control −6046, and static text "Your saved game will
  reflect your position as of the most recent checkpoint." It has no `^0`, so the "at a checkpoint on
  level N" ParamText is never displayed; `DLOG/DITL 1001` (which has `^0`) and `1002` are unused
  [HIGH for the id; MED that Standard File puts the prompt in item 11].
- Cancel → restore the old prefs+0x42 name, return 0.
- Good reply: `fd54 = 1`; reply → `fd18`; `FSpDelete` (replace); reply name → prefs+0x42 and written to
  the prefs file (`.UpdateSGString`); `FSpCreate(creator 'Msct', type 'FWSg')`, `FSpCreateResFile`,
  `FSpOpenResFile(…, 3)`, `AddResource(saveBlockHandle, 'FWSg', 0, "Ferazel Saved Game")`,
  `WriteResource`, `DetachResource`, `CloseResFile` (raw 0x10048400..0x10048500). Success →
  `fe00 = 1`, return 1.
- Errors (raw 0x10048520..0x1004857c): −34 → "…because the disk is full."; −33 → "…because the
  directory is full."; −44 → "…because the volume is locked."; other → "The game could not be saved.
  Check that there is enough space and the volume is not locked." + code. Returns 0 (save point
  re-armed, §2.1).

**File format**: empty data fork; resource fork with exactly one resource `'FWSg'` id 0, name
"Ferazel Saved Game" (pstr 0x100a586c), body = the whole save block, 0xebe58 = 965,208 bytes.
No slots: Standard File named files, any number, any folder.

### 3.2 Default name (`.IncrementLastSGString @ 1004811c`, l. 40877)

On prefs+0x42 (live prefs copy): if its chars 1..4 are `@@@@` (the factory default "@@@@@",
0x100a3193) → "Ferazel Saved Game". Else, only when length < 31: last char a digit → strip the
trailing digit run, append its value + 1 (`NumToString`); last char a space → append "2"; otherwise
append " 2". So successive saves default to "Ferazel Saved Game", "Ferazel Saved Game 2", "… 3" [HIGH].

### 3.3 Layout of the save block / `'FWSg'` body (supersedes engine.md §9 table; offsets raw-checked)

| off | size | content | writers | readers |
|---|---|---|---|---|
| 0x00000 | u32 | `Mwld+0x100` world stamp | SPS 0x1000c16c, ELSGU, DoSaveGame | ContinueGame **fallback branch only** (0x1000d8e8..0x1000d8f0) |
| 0x00004 | u8 | "preview version" flag (0 written) | SPS 0x1000c220, DoSaveGame | ContinueGame 0x1000d0f4 (== 1 → refuse) |
| 0x00005 | u8 | "demo version" flag (0 written) | SPS 0x1000c22c, DoSaveGame | ContinueGame 0x1000d118 |
| 0x00006 | u8 | 1 = snapshot/checkpoint save (always 1 in shipped saves) | SPS, ELSGU (=1), InitGameGlobals (=0) | ContinueGame 0x1000d1ac / 0x1000d91c; SaveSG prompt text |
| 0x00007 | u8 | — | none | none |
| 0x00008 | i16 | level number | SPS 0x1000c1b0, ELSGU | ContinueGame (≥ 80 → refused with the **demo** message, 0x1000d140 `cmpwi r0,0x50`) |
| 0x0000a | 2 | — | none | none |
| 0x0000c | i32 | player x (px, sprite top-left) | SPS 0x1000c204, ELSGU, NewGame/ContinueGame after the map (next level's start x − 32) | ContinueGame → GameLoop |
| 0x00010 | i32 | player y | same (0x1000c214) | same |
| 0x00014 | 4 | — | none | none |
| 0x00018 | 0x19978 | copy of G (engine.md §9) | SPS, ELSGU, DoSaveGame | ContinueGame 0x1000d0cc..0x1000d0e0 (`addi r4,r3,0x10; lwzu r3,0x8(r4)` → first read at +0x18) |
| 0x19990 | u32 | `GetDateTime` (s since 1904) | SPS, ELSGU, DoSaveGame | none |
| 0x19994 | 4 | — | none | none |
| 0x19998 + 0x2000·L | 511 × 16 | record snapshot of level L (rec +0xc y and +0xe x stored −6, restored +6); 16 spare bytes per slot | SPS, ELSGU, HandleLineActions | SetupLevel, ContinueGame |
| 0xe7d98 | pstr | world file name | DoSaveGame only (unreachable) | ContinueGame fallback (`OpenDefaultWorld(save+0xe7d98)`, 0x1000d8a8) |
| 0xe7e98..0xebe57 | 0x3fc0 | — | none | none |

"Writers/readers" is complete: the save handle's TOC slot `-0x77ec` is referenced only by
InitAppGlobals, InitGameGlobals, SetupLevel, NewGame, DoSaveGame, SavePointSave, EndLevelSGUpdate,
ContinueGame, SaveSG, OpenSG, HandleLineActions (`tools/tocrefs.py 100a0054`) [HIGH].

### 3.4 OpenSG(reply)

`reply == 0` → `PromptGetFile("Please select the saved game from which you would like to
continue." (0x100a59db), types {'FWSg'}, reply)` = `CustomGetFile(…, dlgID 0x5dc = 1500, …)` (raw
0x1004253c); `DITL 1500` "Prompt GetFile" shows the prompt in item 10 `^0`. Else copy the given
88-byte reply. Then `FSpOpenResFile(…, 1)`, dispose the old save handle, `GetResource('FWSg', 0)`
(missing → "Sorry, this does not appear to be a saved game file."), `DetachResource`, close; reply →
`fd18`; `fe00 = 1`, `fd54 = 1`; `ResError` ≠ 0 → "Error opening the saved game." **No size check**
on the loaded resource [HIGH]. The 8-byte copy loops here (`0xb × 8` = 88 bytes, a whole
`StandardFileReply`) were re-checked against the locals: `sfGood` = first byte, FSSpec at +6, name
at +0xc [HIGH].

## 4. Resume / Continue (`.ContinueGame @ 1000d004`, l. 6628–7118)  [HIGH unless noted]

Callers: main-menu button 2 / keys O or R (`ContinueGame(0)` → file dialog), File menu item 2
"Restore Game..." (`ContinueGame(0)`), MainMenu when `fd48` is set (`ContinueGame(fd18)`, raw
0x1000e994), and the Finder "open document" AppleEvent (`.DoOpenDocAE`, handler l. 151, only while
no game loop runs) [HIGH].

1. `FlushEvents`, `MTShowWindow`, **`InitGameGlobals`**, `OpenSG(arg)`; failure → redraw, return.
2. `KillAllSprites`; `fd5c ← 1`; level ← `save+8`; **G ← save+0x18** (whole 0x19978 bytes);
   `*_DAT_1009fd28 = 1` (write-only global, no other reference).
3. Refusals (each shows its dialog, then return to menu): `+4 == 1` "…saved with a preview version
   …"; `+5 == 1` or level ≥ 80 "…saved with a demo version …" (same string 0x100a2f33 for both).
4. Raw 0x1000d16c..0x1000d188: `fd5c != 0` (always) and `OpenDefaultWorld("Ferazel's Wand World
   Data")` succeeds → **default branch**; else → fallback branch.
   - **Default branch** (the shipped path): `InitMapLevelNames`, `OpenDefaultWorldLevel(level)`
     (return value ignored); `save+6 == 0` → `G+0x16 ← hdr[0x26c8]` (raw 0x1000d684/0x1000d688);
     else copy the level's snapshot into the live header (x/y +6). **No world-stamp check.** Loop:
     `GameLoop(save+0xc, save+0x10, 0, 0)`; after a completed level → map → next level, and (not
     aborted) `save+0xc/+0x10 ← next level start − 32` (raw 0x1000d768..0x1000d79c). Death test is
     `ffa8 != 0` (raw 0x1000d7ac) → AskToContinue as in NewGame.
   - **Fallback branch** (default world file cannot be opened): `fd5c ← 0`,
     `OpenDefaultWorld(save+0xe7d98)`, compare `Mwld+0x100` with `save+0` — mismatch → "Sorry, that
     doesn't seem to be the world this saved game was saved in." (0x100a2f9a); `save+6 != 0` →
     `*_DAT_1009ff90 = 1` (skip one `InitTrackMap`) and snapshot copy; then a **single** GameLoop
     (start position if `+6 == 0`, saved position otherwise) with no world-map loop. Shipped saves
     carry an empty world name (§2.3), so this branch cannot succeed with them [HIGH reading].
5. Unlike NewGame, the ContinueGame loop **never refreshes `G+0x16` from `hdr[0x26c8]`** (raw
   0x1000d6b4..0x1000d7a8 has no `0x26c8` access): in a resumed session every later level starts with
   the facing that was saved, not the level's flag [HIGH]. Replicate.
6. During `GameLoop → SetupLevel` (l. 2365–2520): `G+0x176+2·L == 1` (restored from the file) →
   re-destroy the crunch tiles logged for L, copy the snapshot in again, keep the per-level
   counters; no chapter screen (engine.md §6/§9).

## 5. Death → continue  [HIGH unless noted]

`GameLoop` ends; `G+4 < 1` → `ffa8 = 1`, `FadeAIFFMusic(0,2)`, `.DeathEffect` (closing-border wipe,
visual only, l. 2676) (raw 0x1000a3a0..0x1000a3c4). Caller → `.AskToContinue @ 10007190`:

- `fe00 == 0` (nothing saved or loaded since New Game) → returns false immediately — **no death
  screen, straight back to the main menu** (raw 0x100071d0..0x100071e0).
- Otherwise: screen CLUT, `PICT 138` (Titles, 640×480) as background; two image buttons drawn by
  `.TrackClickOnCommandButtonDeath`: 1 "Continue" rect (252,390)–(390,412), 2 "Abort" rect
  (262,413)–(379,434) (SetRect l,t,r,b); idle faces `PICT 4970/4971`, pressed `4980/4981` (Titles);
  press/release sounds `snd 4803` "Interface/Mouse Down" / `4804` "…Mouse Up" (handles
  `_DAT_100a0040/003c` ← `FUN_10091748(0x12c3/0x12c4)`, l. 355–357). Keys: Return/Enter → the
  highlighted button (Continue unless moved); Esc or ⌘Q → Abort. With InputSprocket on (prefs+0xa):
  ISp up/down move a marker `PICT 4985` (32×28) between (190,388)–(222,416) and (190,410)–(222,438)
  with `snd 10`, any other ISp key selects. Exit effect: Continue → `.WandGlow`, Abort → `.TurnGray`.
  The `DLOG 203 "Game Over"` text dialog in the app fork is **not used** (no `GetNewDialog(203)`)
  [MED: searched decompile call sites].
- Continue → `fd48 = 1`, return to MainMenu → `ContinueGame(fd18)` → **re-reads the last save file
  from disk** (§4).

What a continue restores (all from the file, i.e. the state at the last save point used):
health `G+4`, breath, max health/magic, magic `G+0xe`, coins, score, inventory and selected slot,
world flags `G+0xad8…`, unlocks `G+0x23e…`, per-level counters/totals, crunch log, `G+0x176` flags,
facing `G+0x16`. **Nothing is refilled**: no code writes `G+4`/`G+0xe` at level start or on
continue (all G+4/G+0xe writers: InitGameGlobals, PlayerConstraints, HandlePlayerSprite, CastSpell,
HandleKeys, HitPlayerSprite, HitPlayerShotSprite — scan of every `sth` at those displacements off the
G pointer); `.SetupPlayerSprite` sets sprite HP `+0xa4 ← G+4` (handler l. 290) [HIGH].
Position: on the save point (`save+0xc/+0x10`). Enemies/pickups: as recorded at save time (killed /
collected stay gone; survivors respawn at their saved record positions, re-run through their Setup
routine — runtime HP/AI state is not saved) [HIGH for records; MED for "fresh Setup state"].
**Lost**: everything after the last disk save, including level completions and unlocks recorded only
by `EndLevelSGUpdate` in memory, crunch tiles broken later, items picked up later.

Edge case [MED]: if `OpenSG(fd18)` fails (file moved/deleted), ContinueGame returns with `fd48` still
1, so MainMenu calls it again every loop pass (raw 0x1000e984..0x1000e994) — an error-dialog loop.

## 6. Escape / abort / menus (save-related parts)  [HIGH unless noted]

- In game, Esc → `ConfirmAbortGameDialog` (`DLOG 202`, ParamText "Are you sure you want to abort this
  game?"): OK (item 1, framed default) → abort to menu; Cancel → resume. No save option (§2.3). File
  menu "Abort Game" (`.AbortGame`) is the same dialog.
- World map (l. 51630–51670): ⌘ or Esc held — with Q → "Are you sure you want to quit?" → OK sets
  `fd4c` + `fd50` (Quit after the map); otherwise with W or Esc → the abort dialog → OK sets `fd4c`.
- Menus (`MENU 129` File: New Game / Restore Game... / – / Abort Game / – / Quit; `MENU 130` Game:
  Music / Sound Effects / – / Preferences…). `.MainMenu` shows the menu bar while the mouse is in the
  top 20 px (l. 7310) [HIGH]; no in-game path to it was found [MED].
- Main-menu hot rects (PointInRect l,t,r,b): New Game (427,263)–(581,305), Resume (434,305)–(626,345),
  Options (441,346)–(612,388), Credits (448,387)–(562,427), Quit (456,429)–(539,471); keys N, O/R,
  I/P, C, Q; X → the "Coming soon: Ferazel's Destiny…" joke dialog with a 30-pass cooldown.
- Debug only (out of scope): key 0x76 during SetupLevel clears `G+0x176+2L`; keys C+S (codes 8 and 1)
  held without ⌘/Esc while the debug flag is set → `SavePointSave` (raw 0x10007b6c).

## 7. What is NOT persisted  [HIGH unless noted]

- Live level header except the 511 records (tile edits other than the crunch log are not saved).
- Sprite runtime state (HP, timers, AI), non-record sprites (shots, effects, particles).
- Track map: 128×128 bytes at 0x100a79b6 (`InitTrackMap`/`SetTrackMap`/`UpdateTrackMap` mark a
  15×15-cell area around the player). **No reader exists** — the only `addi rX,r2,0x176` bases are
  in InitTrackMap (0x10005070) and SetTrackMap (0x1000515c). Vestigial; a replica can omit it.
- Prefs (separate file), music position, camera, timer-trigger countdown `iRam100a5110`, the
  SetupLevelSprites tallies (`_DAT_1009ffac/b0/b4`, recomputed).
- G fields that are saved but reset per level anyway: `G+0x20` (= 0) and `G+0x22` (← hdr+0x2706)
  by SetupLevel (l. 2376–2377); `G+0x174` OmniPx-active (SetupLevel l. 2539).

## 8. INDEX NOT-RESOLVED items

### 8.1 Item 8 — `G+0x12` and lives: **closed**  [HIGH]
`G+0x12 = 3` is written once (`.InitGameGlobals`, raw 0x10001a24 `sth r0,0x12(r4)`). A scan of every
function that loads the G TOC slot (`-0x7880`, the only TOC word pointing into G — data-section scan
for words in G's range found only `0x1009ffc0` and `0x100a0078` = G+0x19978) finds **no other access
at displacement 0x12**; G is otherwise touched at +0x12 only by the wholesale save/restore copies.
There is no lives concept: death ends the run, with continue possible only from a disk save (§5).
The manual's TEXT resources mention no lives. (Caveat [MED]: an access through a spilled/derived
pointer would evade the scan; none was seen.) Review 1a (#10) spot-checked the 22 raw `…,0x12(r`
accesses: the 4 within 300 lines of a G TOC load (`10003ef0`, `100082a4`, `10008334`, `1004b088`) use
record/sprite/table bases, not G — the reading holds; the per-function scan itself was not re-run.

### 8.2 Item 9 — prefs: **closed** for +0x02/+0x04/+0x06/+0x142, plus +0x32/+0x34
Mapping from `.PreferencesDialog` (l. 48601) / `.UpdatePrefsPanel` (l. 48971) item numbers onto the
appended `DITL 6901` "Game Preferences" (items 7.. = DITL items 1..; `SwitchPrefsPanel` keeps 6 base
items) [HIGH]:

| prefs | control | values | readers / effect |
|---|---|---|---|
| +0x00 | item 7 "Reduce frame rate" | bool | (engine.md §8) |
| +0x01 | item 8 "Reuse saved game files" | bool | `SaveSG(prefs[1]==0)` |
| +0x08 | item 9 "Allow background tasks" | bool | (engine.md §8) |
| +0x02 | item 10, `CNTL 602` → `MENU 602` | 1 High Detail, 2 Low Detail, 3 Line-skipped | 3 → black-line mode (`RestoreWindowBackground`, `AbortGame`, `RedrawGameArea`, `GameLoop`, `PaintFrameWrap`…); 2/3 → even camera y (engine.md §8) |
| +0x06 | item 11, `CNTL 603` → `MENU 603` | 1 Enhanced, 2 Normal, 3 Reduced; default 2 if Gestalt `cput` < 0x108 (pre-G3) else 1 | effect level: e.g. `.HitPlayerSprite` death burst `ExplodeFaceIntoParticles(…,1,1,1,…)` when 1 and the count `*_DAT_100a019c` < 1000 [~~MED: count = live particles~~ ⚑ wave 2 corr (2026-10-04) PA #6: it is the live-particle counter, but it is never reset per level and colour-0 deaths decrement it twice (`10031ba8`, `10031bc8`; no other writer), so it drifts negative (and can wrap) — the < 1000 / < 1500 gates are not a live-count test in practice (particles §1.4)], `(…,2,1,7,…)` when 2 and < 1500, else `(…,2,2,7,…)` (handler l. 3363–3370); `.WrapDrawWaterEffects` draws an extra water face only when 1 and `hdr+0x26c6 == 0` (l. 8790); the `.AnimateCLUT` block at l. 8956 runs never when 3, every 4th frame when 2, and when 1 only while `*_DAT_1009fd30 == 0`; 3 skips `DrawLightsOntoTiles` (engine.md §8). Other readers: `RedrawScrollGrid`, `WrapDrawSprites`, `DrawParticles`, `HandleBurn`, Bonus/Effect/Bat/Gremlin handlers [HIGH for list; per-site effects not all read] |
| +0x04 | none in the shipped DITL (item 12 is the static text "Graphics:"; the item-12 branch that writes +4 is dead) — the orphan `CNTL 604 "Px popup"` / `MENU 604` (1 Super Parallax, 2 Parallax, 3 No Parallax) is its UI | default 2 | `.DoubleBlitUniversal` (l. 18917): value 3 skips the parallax back layer unless `hdr+0x2722 > 0`. Unreachable from the shipped UI → always 2 [HIGH] |
| +0x32 | item 14 "Resolution switching" (the click handler updates item 16 — a slip, harmless) | bool | `.ResSwitch` (l. 8010): switch the monitor to 640×480 when set; set by the first-run `DLOG 1300` (OK → 1, "Don't Switch" → 0) |
| +0x34 | — | 1 | "ask the resolution question" (`.ResSwitchDialog` shows `DLOG 1300` while ≠ 0, then clears it) |
| +0x3c/+0x3e/+0x40 | — | 0 | written by InitPrefs and "Default Settings" only; no reader (displacement scan) |
| +0x142 | — | 8 empty pstr[256] | **write-only**: the only `0x142` immediate in the code is `.InitPrefs` (raw 0x1000f410 `addi r4,r26,0x142`); no reader by displacement or base. Reserved/vestigial [HIGH]; purpose (e.g. a recent-files list) [LOW] |

### 8.3 Item 2 — level header fields
- **0x26c8 = "player starts the level facing left"** [HIGH]: `NewGame` (raw 0x1000b3d8) and
  `ContinueGame` (0x1000d684) copy it to `G+0x16`; `.SetupPlayerSprite` (handler l. 422, raw
  0x1004b2b0 `lha r0,0x16(r29)`) sets player `+0x17e` (facing left) = `G+0x16 != 0` and
  `_DAT_100a5f5a/5f5c = 1` (else 2). Census: 1 in levels 3, 5, 11, 18, 40, 45 — exactly the six
  levels whose start x (hdr+0x2848) lies in the right 7 % of the map (e.g. 3: 11026 of 11200 px)
  [HIGH, Python]. The only other `G+0x16` writer is the save point (§2.1). No other `0x26c8` access
  in the code (`grep ',0x26c8('` → 2 hits).
- **0xb270..0xb277**: zero in all 24 levels and no access anywhere (`grep ',0xb27[0-7]('` → none).
  The bank's "0x20,8,0x20,8 in level 1" belongs to 0xb278..0xb27e (PxBack/PxMid dims) — see
  Corrections [HIGH].
- **0x26c7 OmniPx mode** — narrowed [MED overall]. `SetupLevel → SetupOmniPx(0)` (l. 2540): 0 →
  off. ≠0 → `G+0x174 = 1`, a 128×128 blit port becomes PxBack tile 0 (`GetPxBackTile` returns 0 while
  `G+0x174`, world-data §3.3), and `TurnOnOmniPx` zeroes the PxBack x-factor table and `hdr+0xb26c`
  (no backdrop parallax) except for modes 4..7. Up to 16 drifting overlay faces with per-layer
  velocities (`DAT_100a377c/379c`). Per mode (l. 13207–13256, 13392–13420):
  mode 1 — overlay faces `PICT 6000/6001` (Sprites, 128×128), velocities 0x100/0x500 and
  0x200/0x800, plus `.GenerateRain` every frame (`.PaintFrameWrap` l. 9193) — level 15 Storm
  Valley; mode 2 (and 4) — faces `PICT 6201/6200`, velocities −0x80/−0x200, port animated from 9
  frames of table 0x100a4f2c (counter 0..17, step ½) — level 5; mode 5 — faces `PICT 6301/6300`,
  same velocities and frame animation as 2 — level 25; mode 3 — no faces loaded, no port animation; mode 6 — `InterlaceBlit128`
  of 29 frames (table 0x100a4f18, counter 0..57, odd/even rows alternate) — level 70; mode 7 —
  ping-pong 29 frames from 0x100a4f14 (unused in data). Census values: 0, 1 (15), 2 (5), 5 (25),
  6 (70). ~~Exact draw composition NOT RESOLVED.~~ Closed: rendering-omnipx-titles §3.3–§3.5; the mode-1
  writes to layers 3..5 (`uRam100a3742..3766`) and to 0x100a3802 are dead — faces 3..5 are never loaded
  (`1001a048..1001a068`, `1001a640..1001a648`) ⚑ wave 2 corr (2026-10-04) RO #7.
- **PxMid cell 0xFFFF** — narrowed. Both fetch sites in `.DoubleBlitPPCParallaxOneLayer` use the
  returned i16 directly as an index (raw 0x10017bac..0x10017bc0 and 0x10018a80..0x10018aa8:
  `extsh; rlwinm 2; lwzx; addi 0x60`) — **no −1 test**. −1 therefore reads entry [−1] of the PxMid
  tables: 0x100a4fa0 (= PxBack port 35, the last of the 36 at 0x100a4f14) and 0x100a4fd0 (= PxMid
  image port 11 of 0x100a4fa4) [HIGH for the arithmetic]. Every level has −1 cells (all-−1 PxMid maps
  in the 12 levels without a PxMid tileset). What the blitter draws for such a pair, and how it skips
  the layer when no PxMid tileset is loaded (`_DAT_1009ff68` is written by `LoadPxMidTileset` but has
  no reader) — ~~NOT RESOLVED~~ closed: rendering-omnipx-titles §2 (never reached with shipped data;
  "no PxMid tileset" path §2.5) ⚑ wave 2 corr (2026-10-04) RO #7.

### 8.4 Item 13 — `PICT 7000` resource-chain winner: **closed — the application's copy** [HIGH — ⚑ wave 2 corr (2026-10-04) RO #8; was MED]
`.ShowWorldMap` draws `PICT 7000` through `.MTGetandDrawPICTResInRect` = `GetPicture` (l. 51542;
the chain, not `Get1Resource`). Resource-file life cycle traced: the app fork is open at launch;
`.OpenResourceFiles` opens Titles, Sounds, Sprites (Sprites current) and keeps them; the prefs file
is opened/closed around each use; Backgrounds is opened/closed inside `SetupLevel`; **every** World
Data opener closes it before returning — `OpenDefaultWorld`, `OpenWorld`, `OpenDefaultWorldLevel`,
`OpenDefaultWorldMap`, `OpenDefaultWorldConv` (each `CurResFile` / `UseResFile(old)` /
`CloseResFile`), and the `SetResWorldFile`/`RestoreResWorldFile` pairs (LoadLevelTilesets ×5,
LoadLevelSounds, InitMapLevelNames, Conversation, HitPlayerSprite sign) [HIGH]. Titles/Sounds/
Sprites/Backgrounds hold no `PICT 7000` (rsrc census). So at map time the only open file with
`PICT 7000` is the application → **app fork `PICT 7000` (181,550 B) is drawn; the World Data copy
(181,212 B) is dead data**. The two 608×384 images share one CLUT; decoded PackBits pixels differ
in 3,618 pixels inside x 46..108, y 176..261 (map coords; near nodes 45 The Dig (h 91, v 241) and 50
Fire In The Hole (h 51, v 265)) [HIGH, Python decode]. Caveat [LOW]: the CD check in `.main` opens
"Ferazel's Wand:Installer Data" (only when the machine hash ≠ prefs+0x3a) and never closes it; its
contents are unknown — if it held a `PICT 7000` it would sit above the app in the chain.
⚑ wave 2 corr (2026-10-04) RO #8: decoded — an RTF plot write-up ("Plot Writeup 1", 10,934 B) with a tiny
resource fork (PICT 32000, STR 128, STR# 128, vers 128) and **no PICT 7000**, so the app's copy wins
unconditionally (rendering-omnipx-titles §6.2) [HIGH].

## 9. Wave 2 (2026-10-04): save-point faces, hold timing, a missing level on resume

### 9.1 Save-point faces (NR 1)  [HIGH unless noted]
- Face index = record param 1: `+0xc0 = *_DAT_100a0a28 + p1·0x34` in both `.SetupBoxSprite` (handler
  l. 11517–11524) and `.HandleBoxSprite` (handler l. 12409–12413). The 0x429 arms and the Setup tail
  (`LAB_1006cf1c`, handler l. 12239–12244) never write `+0x17e`, which `.MTNewSprite`'s
  `_MemoryClear` leaves 0: **never mirrored** [MED for the absence: decompile of those arms].
- Set cut: `LoadEncFaceSetFromPICT(0x429, 3, 0x54, 100, 3, …)` (main l. 58807); face i is column
  `i mod 3`, row `i / 3` of the sheet, i.e. x 84i..84i+83 (raw `1002f220..1002f250`:
  `divw; mullw; subf`, then `SetRect(col·w, row·h, (col+1)·w, (row+1)·h)`).
- `PICT 1065 'save point'` decoded (Sprites file, 252×100, 8-bit, 153-entry clut, PackBits rows):

| face | record p1 | art |
|---|---|---|
| 0 | 0 — unused | a short dark pedestal with green rims and a **green check mark**; nothing on it |
| 1 | 1 — saved facing right (`+0x17e` = 0) | taller pedestal (grey check mark) carrying a grey **stone statue of a hooded figure pointing a wand to the right** |
| 2 | 2 — saved facing left | the same statue mirrored, wand to the **left** |

  So a used save point shows Ferazel turned to stone in the direction he faced when he saved
  [MED: "Ferazel" from the art and the manual's wording; the direction rule is HIGH].
- Timing: p1 is written in the collision pass of frame n (§9.2); the Box handler installs the face in
  frame n+1 after that frame's draw, so the statue is first drawn in frame n+2
  (platforms-ropes-radial-2 §8.1). `.SavePointSave`'s own full redraw happens inside frame n, before.

### 9.2 Hold timing (NR 2)  [HIGH unless noted]
Counter `C = *_DAT_100a0684` (i16). TOC loads: `.ClearPlayerVars` 1, `.HandlePlayerSprite` 3,
`.HitPlayerSprite` 4 (`tocrefs`; each followed — single-use registers).
- Level start: `.ClearPlayerVars` (called by `.SetupPlayerSprite`) stores 0 (`1004ac1c..1004ac28`).
- **Handler pass**: `.HandlePlayerSprite` moves C one step toward 0 every frame — `> 0 → −1`,
  `< 0 → +1` (`1004de68..1004de98`), after only the `+0xe9` / `+0x1b2` early returns.
- **Collision pass, same frame** (all handlers run first; the player's hits come only from
  `.MTCollideSpecialSprite`, once per contact per frame — platforms-ropes-radial-2 §8.1, §8.3): a
  landing (`.PlatformBounce` = 1) on an unused save point (p1 == 0, gate byte set) does `C += 2`
  (`10057754..1005775c`) and fires when `C > 15` (`cmpwi r0,0xf; ble` at `10057768/1005776c`).
- Standing still lands every frame [MED]: the gravity add leaves `vy ≥ 1` on every frame (`vy == 0 → 1`,
  player-states §1 l. 1205–1222) and `.RectBounce` returns 1 for a from-above contact with `vy > 0`
  (main l. 36297–36300).

| consecutive landing frame k | C after the handler | C after the landing |
|---|---|---|
| 1 | 0 | 2 |
| 2 | 1 | 3 |
| k | k − 1 | k + 1 |
| 15 | 14 | **16 > 15 → fire** |

So from C = 0 the save fires in the collision pass of the **15th consecutive landing frame** (half a
second at 30 frames/s). A frame without a landing costs one step of decay and nothing else.
- Fire (`10057770..100577b4`): `C = −150`, p1 = facing + 1, `G+0x16` = facing, then `.SavePointSave()`
  runs **synchronously inside the collision pass** (its `.SaveSG` file dialog included).
- After a failed or cancelled save (p1 back to 0 at `1005783c`) C is still −150: standing on the point
  adds +1 (handler) +2 (landing) = +3 per frame, `C = −150 + 3j` after j frames, so it fires again on
  the **56th** landing frame (j = 55 gives exactly 15, not > 15); stepping off, C is back to 0 after 150
  frames.

### 9.3 `OpenDefaultWorldLevel` failing inside `.ContinueGame` (NR 6)  [HIGH up to the nil dereference]
`.OpenDefaultWorldLevel(level, fileName) @ 10048ac0` (main l. 41500–41562):
1. **File cannot be opened** (`ResError ≠ 0`, or refNum 0 / −1: `addi 1; rlwinm 16..31; cmplwi 1`
   at `10048b70..10048b84`): `ParamText(fileName, …)`, `.ReportError(0x100a5b3c "The world file "^0"
   could not be accessed. Please report this error code to Ambrosia.", err)` (`10048b88..10048bac`;
   `.ReportError` puts the message and the number in a `GenericMessage` alert), then
   **`ExitToShell`** (`10048bb0`). Inside ContinueGame's default branch the same file was opened a
   moment earlier by `.OpenDefaultWorld` (§4 step 4), so this needs the file to vanish in between.
2. **Level resource missing** (`GetResource('Mlvl', level)` returns nil — a save naming a level < 80
   that World Data lacks; the shipped file has 24): the nil handle is stored to `*_DAT_100a0058`
   (`10048bf4`), `DetachResource` / `HLock` get nil, and **`.SetupLevelTilemapPtrs` dereferences it**
   (`bl 0x1004913c` at `10048c34`; main l. 41774: `*(int *)*handle + 0xb29c`, then five stores into
   `+0xb284..+0xb298` of whatever address 0 holds). Then `.SafeReportStr(0x100a5af7 "Tried to open a
   level that wasn't there!")` — which **shows nothing**: it overwrites r3 at its first instruction
   pair (raw `100359c8..10035a04`: fade in if `*_DAT_1009fde8`, `InputActivate(0,0)`, return). The
   routine returns false (`10048c50`).
3. `.ContinueGame` **ignores the result** at all three calls (`1000d19c`, `1000d714`, `1000d90c`: r3
   is not tested afterwards) and proceeds to the snapshot copy and `.GameLoop` through the nil level
   handle.
Beyond step 2 the outcome depends on the memory at address 0 (readable low memory on Mac OS 9, an
unmapped page under Mac OS X), not on the game: **CLOSED AS UNDETERMINABLE** past the first nil
dereference. Unreachable with any file 1.0.3 writes (save +8 is always the level that was running).
A replica cannot reproduce undefined behaviour; refusing such a file is the only defined choice.

## NOT RESOLVED
1. ~~Save-point face art: which of `PICT 1065`'s 3 faces is drawn for param 1 = 1 vs 2 (direction).~~
   → closed: §9.1 — ⚑ wave 2 (2026-10-04)
2. ~~Exact frame timing of the save-point hold (call order of HandlePlayerSprite vs HitPlayerSprite
   within a frame; ≈15 frames).~~ → closed: §9.2 (15th consecutive landing frame) — ⚑ wave 2 (2026-10-04)
3. ~~OmniPx composition (how the 16 overlay faces and the animated port combine with PxMid/FG) and
   the role of `uRam100a3742..3766` values set only in mode 1.~~ → closed (§8.3) ⚑ wave 2 corr (2026-10-04) RO #7
4. ~~PxMid −1 drawing semantics and the "no PxMid tileset" skip path (§8.3).~~ → closed (§8.3) ⚑ wave 2 corr (2026-10-04) RO #7
5. ~~Contents of the CD's `Installer Data` (affects item 13 only if it carries `PICT 7000`).~~ → closed
   (§8.4: no PICT 7000) ⚑ wave 2 corr (2026-10-04) RO #8
6. ~~Behaviour when `OpenDefaultWorldLevel` fails inside the ContinueGame default branch (return value
   ignored) — only reachable with a corrupt/foreign save.~~ → closed: §9.3 — file failure = alert +
   `ExitToShell`; missing level = silent nil dereference, CLOSED AS UNDETERMINABLE past it — ⚑ wave 2 (2026-10-04)

## Proposed additions to physics.md §0
- `+0x46` (player): set from `GameLoop`'s 3rd argument at spawn (always 0) — reading of `+0x46`
  elsewhere is per-class (already listed); no new meaning.
- None else; the save point uses Box-class fields already listed (`+0xc0` face, `+0x110`, `+0x185`,
  `+0x34` rect, `+0x48` record index).

## Corrections to the existing bank
| file § | old reading | new reading | evidence |
|---|---|---|---|
| engine.md §9 table row 0x00000 | "resume refuses a mismatch" | checked only in ContinueGame's fallback branch (default world file unopenable); the shipped path never compares the stamp | raw 0x1000d16c..0x1000d188 vs 0x1000d8e8; ⚑ corrected (review 1c, 2026-10-03) (adjudication B19): settled for this file — the only `0x100(` load in ContinueGame is 1000d8e8 on the 1000d898 branch [HIGH] |
| engine.md §9 table row 0xe7d98 | world name written by DoSaveGame (implied live) | DoSaveGame is unreachable (DITL 202 has no item 5) → field never written in 1.0.3 | raw 0x100068b4, DITL 202 decode |
| engine.md §9 G list `+0x12 = 3 (NOT RESOLVED)` | unknown | write-only, no lives concept | §8.1 |
| engine.md §9 G list | (no +0x16) | `G+0x16` = player-facing-left at spawn: hdr[0x26c8] per level in NewGame, once in ContinueGame, player facing at each save point | §8.3, §2.1 |
| engine.md §6 diagram | "continue re-enters ContinueGame on that save" | it re-reads the **file** via `OpenSG(fd18)`; level completions since the last save point are lost; with no save this game, no death screen at all | §5; ⚑ corrected (review 1a adjudication 6 / B18, 2026-10-03) (label ⚑ corrected (review 1d, 2026-10-03) #1): settled for this file (raw 100071d0..100071e4, 1000d0cc) |
| engine.md §8 rows +0x02/+0x04/+0x06 | +0x04 "effects popup [LOW]", +0x06 meaning partial | +0x02 Graphics (High/Low/Line-skipped); **+0x06 Effects** (Enhanced/Normal/Reduced); **+0x04 Parallax** (Super/Parallax/No), no control in the shipped dialog | §8.2 |
| engine.md §8 rows +0x32/+0x34, +0x142 | reader not traced / NOT RESOLVED | +0x32 auto 640×480 switch, +0x34 ask-on-launch; +0x142 write-only | §8.2 |
| world-data-format.md §3.2 row 0xb270..0xb276 | "0x20,8,0x20,8 in level 1" | zero in all 24 levels, no access; the quoted values are 0xb278..0xb27e | Python census; the bank's own xxd line `004f4f8d: 0000 0000 0000 0000 0020 0008 …` starts at +0xb270 |
| world-data-format.md §3.2 row 0x26c8 | "meaning NOT RESOLVED" | player starts facing left | §8.3 |
| world-data-format.md §4.1 first bullet | "New game: level = Mwld+0x1c4 (1)" | shipped path loads literal level 1; Mwld+0x1c4 only with the debug flag or a non-default world (same value in data) | raw 0x1000b2b8..0x1000b2cc; ⚑ corrected (review 1c, 2026-10-03) (adjudication B20): settled for this file — `1000b27c lbz r0,0(r14)` (r14 = debug-flag slot −0x77dc, re-assigned at 1000b22c on the non-default-world path) [HIGH] |
| physics.md §7 Bat row (review 1a #5, adj. 3) | "HP 100, 200" | 1740 family **500** (`1007dcbc cmpwi 0x6d6; bge` → `1007dcc0 li 0x1f4`), 1850 family 100 (`1007dde0 li 0x64`), insects 200 (`1007e144 li 0xc8`) | enemies-flyers §3.1 |
| physics.md §7 "Statue/Box/Platform set +0x185" (review 1a #5, adj. 2) | Statue sets one-way | the Statue does **not**: no `0x185` store in `100664a8–100665bc` or `10043138–100431c4`; thaw `lha 0xa4; subi 0xc8; sth` `1006656c–10066574`; `+0x130 = 0x78`, `+0x134 ← +0xb8` `10043194–1004319c` | enemies-water-cave §5 |
| physics.md §7 Floater row (review 1a #5) | rect (0x17,2,0x38,0x5c) | shipped 1780 Wraith rect (0x23,1,0x3e,0x4b) at `10081550–1008155c`; the other is the unplaced 1790..1799 variant | enemies-flyers §5.1 |
| physics.md §2 water gravity (review 1a #2, adj. 4) | `max(0.7·g, 0x100)` "in water" | taken only if `+0x11c ≠ 0` at entry (`100375c8`), before the routine's own `SeparateFromTiles2` (`10037624`); `+0x11c` is zeroed per frame (`100369ac`), so a sprite's first call each frame uses dry gravity; only a second same-frame call (Frog) or a direct writer (Bonus 1055, 1350) can take the 0x100 branch | enemies-water-cave §0.1 |
| spells-items.md §2.1 (review 1a adj. 1) | spell names | names only: id 2 "Ice Crystals", id 3 "Ice Wall" (floes/ledges), id 7 second Ice-Wall icon (PICT 700 captions 0..11: Fireball, Statue, Ice Crystals, Ice Wall, Tree Trunk, Boomerang, VBlade, Ice Wall, DensityBall, Sandstorm, EnergyBolt, Ice Shards) | spells-detail §1 |
| world-data-format.md §2 table, PICT 7000 row | "[MED: resource-chain order decides]" | the app fork's copy is drawn; World Data's is dead (they differ in a 63×86 region) | §8.4 |

Wave 2 (2026-10-04):

| # | file § | old | new | evidence |
|---|---|---|---|---|
| W1 | pickups-boxes §2.4.8 "lit face" | p1 = facing+1 selects a "lit" frame | the used faces are a stone statue facing right (p1 = 1) or left (p1 = 2); face 0 is the empty pedestal with a green check | §9.1, PICT 1065 decode |
| W2 | engine.md §6 (saved-game continue) | — | add: a world file that cannot be reopened on resume quits the application (`ExitToShell`); a save naming a missing level dereferences a nil handle with no visible message (`.SafeReportStr` ignores its string) | §9.3; raw `10048bb0`, `100359c8..10035a04` |
| W3 | any reader of `.SafeReportStr` call sites | message shown | `.SafeReportStr` never displays its argument (fade-in + input off only) | raw `100359c8..10035a04` |
