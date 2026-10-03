# Ferazel's Wand 1.0.3 — engine: identity, init, loop, screen, camera, states, input, prefs, saves

Register: code readings only; **nothing here is behaviour-verified**. Labels per claim:
`[HIGH]` read in code with constants resolved and data path traced, `[MED]` one link inferred,
`[LOW]` pattern/string inference. `G` = game-globals block (TOC slot `_DAT_1009ffc0`, which points at 0x10231a1c — computed with
`tools/pef.py`: unrelocated TOC word + data base 0x1009f840; TOC slots are named by their own
address, as the dump does). Units: positions are pixels;
velocities are 1/256 px per frame ("fixed 24.8").

## 1. Engine identity  [MED]

- **Ben Spees' own engine, internal codename "Mascot".** Evidence: the world-file type/creator
  `Mwld`/`Msct`, the app's `Msct` signature resource, `Mwld 0` is named "Mascot World", the
  data-file resource types `Mlvl/Mmap/Mcnv` (M-prefixed), the `STR# 300/400` messages say
  "Sorry, Mascot requires QuickTime …", the sprite/screen layer is prefixed `MT…`
  (`.MTNewSprite`, `.MTInit`, `.MTHandleSprites`, …), and a birthday message names the author's
  mailbox at `mixedmetaphor.com` (string at 0x100a34ce) [MED: identity from strings/names].
  No SpriteWorld/SAT/DrawSprocket names appear in the 1082 dump names or the data strings
  [HIGH for absence in what was searched: names list + data-section strings].
- **Bundled libraries** (all statically linked, no traceback names for most):
  - "Monitor Tool" — `monitor_tool.c`, `mt_common.c`, `mt_mac.c` assert strings; functions
    `.MT_Open/.MT_SetMode/.MT_FadeTo/…` (resolution switch, gamma fades, CLUT) [HIGH, strings +
    names].
  - A small runtime: `atomic.c`, `memory.c`, `queues.c`, `strings.c`, `system.c`, `timers.c`,
    `threads.c` (named `.AtomicIncrement`, `.QueueInsert`, `.TimerGetMicroseconds`,
    `.ThreadYield`, …) [HIGH, strings + names].
  - "Sound Tool" software mixer: the unnamed `FUN_10090928..FUN_1009250c` block (16 voices,
    converts `snd ` to an internal `'asnd'` buffer, `SndPlayDoubleBuffer`) — see
    sprites-backgrounds-sounds.md §6 [MED].
  - InputSprocket (`ISp*` imports) and QuickTime (`*Movie*` imports, music).
- Toolbox: Carbon-era classic toolbox via CFM imports (`InitGraf`, `GetNewCWindow`, `NewGWorld`,
  `CopyBits`, …) [HIGH].
- Out of scope, identification only: CD/installation check in `.main` (opens
  `Ferazel's Wand:Installer Data` on the CD volume when a Gestalt-derived machine hash differs
  from prefs +0x3a) — copy protection; `.DateChecks` (author birthday dialog); debug/cheat keys
  (§7.3); AppleEvent handlers; `.HandleMovieCapture`.

## 2. Startup sequence (`.main @ 1000ffc0`)  [HIGH]

1. `.InitToolbox` (MaxApplZone, 20× MoreMasters, InitGraf…InitCursor), `.Randomize`,
   `.DateChecks`.
2. Prefs: `.SetPrefFile("Ferazel's Wand Prefs", '????', 'pref')`, `.CheckSysVersion`,
   `.GetProcessorInfo`, `.InitPrefs`, `.MakeCurrPrefs`; CD check (out of scope).
3. `.InitInputSprocket`, `MT_Open`, `.ResSwitch` (optional switch to 640×480); quits if the main
   screen is < 640×480.
4. `.OpenResourceFiles`: opens `Ferazel's Wand Titles`, `… Sounds`, `… Sprites` (in that order;
   Sprites stays current) — each missing file is fatal.
5. `GetCTable(200)`, AppleEvents, cursors, menu bar.
6. `.InitEngine`: `MTInit(screen 0,0,640,480; view 16,8,624,392)` (§3).
7. `SwitchTo8BitColorMT`; draw `PICT 131` splash; music track 24; `.InitSounds`;
   `.InitAppGlobals`; loading screen `PICT 136` (640×480 main screen) else `PICT 128`; 3-D
   progress bar; `.InitSprites`, `.InitFaces`, `.InitTiles`; then `.MainMenu` (loops until quit).

`.InitAppGlobals @ 100009c8` allocates the three big handles [HIGH]:
`_DAT_100a005c` Mwld (0x11408), `_DAT_100a0058` Mlvl header (0xb29c; replaced by the detached
resource on level load), `_DAT_100a0054` save block (0xebe58); loads CLUTs 801, 128, 130, 131
(×2), 700, 200, 199, 198, 260, 132; builds the three 640×416 off-screen ports
(`NewBlitPortSlop(0x280,0x1a0,0,8)` → `_DAT_100a000c/0008/0004`), the status-bar port
(640×88 `PICT 132`) and HUD pieces (PICTs 133, 702, 703, 700, 701, 140, 141, 142), the flame
buffer (`FlameCreate`, 640×100) + `.LoadCoolingMap`, and `.BuildSineTable`.

`.InitSprites @ 100002ac` loads every sprite class's faces once at boot (InitPlayerSprite …
InitRopeSprite, 28 calls) [HIGH].

## 3. Screen, buffers, coordinates

| item | value | evidence | label |
|---|---|---|---|
| window / screen | 640×480, 8-bit indexed | `.InitEngine` `SetRect(0,0,0x280,0x1e0)`; `SwitchTo8BitColorMT`; quits if screen < 640×480 | [HIGH] |
| game view on screen | rect (16,8)–(624,392) = **608×384** | `.InitEngine` `SetRect(0x10,8,0x270,0x188)`; `WrapCopyToScreen(...,0x10,8,...)` | [HIGH] |
| status bar | 640×88 at y 392..480 (`PICT 132`, 640×88, Titles) | `.InitAppGlobals` `NewBlitPort(0x280,0x58)`, `DrawPicInGWorld(0x84)` | [HIGH] |
| back buffers | three 640×416 ports with 8-px slop | `NewBlitPortSlop(0x280,0x1a0,0,8)` | [HIGH] |
| tile size | 32×32 (main grid), 128×128 (parallax) | `>>5`/`*0x20` everywhere; `LoadPxBackTileset(…,0x80,0x80,…)` | [HIGH] |
| world origin | top-left, y down; scroll point `PTR_DAT_1009fe78` = (v,h) of the view's top-left in world px | `.SetScrollLocation(h, v)` calls | [HIGH] |
| scroll clamp | 0 ≤ h ≤ 32·W − 640, 0 ≤ v ≤ 32·H − 384 | tail of `.FindUpperLeftCorner` | [HIGH] |

Parallax (`.DoubleBlitPPCParallaxOneLayer @ 10017924`): for screen row `r`, the PxBack layer
is offset horizontally by `scrollX · back[r + (scrollY·yb>>8)] >> 8` where `back` is the
8192-entry table at hdr+0x326c and `yb` = hdr+0xb26c; PxMid likewise with hdr+0x726c / 0xb26e
[HIGH]. The PxBack/PxMid maps are 6×8 visible 128-px cells per frame (loop `8 × 6`) [HIGH].
Draw order per frame (`.PaintFrameWrap @ 10011cf8`): parallax+tile grid
(`.SetScrollLocation` → `.RedrawScrollGrid`), lights on tiles, `.HandleLights`, water effects,
`.WrapDrawSprites`, rain (OmniPx mode 1), `.AnimateCLUT`, flame layer, particles, OmniPx, copy to
screen at (16,8) [HIGH for order of calls; per-layer blend rules NOT RESOLVED].

## 4. Main loop and frame cadence (`.GameLoop @ 10009d48`)  [HIGH]

Per iteration:
```
start = TickCount(); frameCounter++;
FindUpperLeftCorner();                       // camera (§5)
PaintFrameWrap(draw, odd);                   // draw (if draw) THEN sprite logic:
                                             //   HandleIdleSprites, HandleSprites
                                             //   (MTHandleSprites → each sprite's +0x4c
                                             //   callback; MTCollideSprites; player special
                                             //   collisions), HandleParticles, erase
CheckGameEvents(); CheckGameLoopKeys(); UpdateDynamicSounds(); UpdateTrackMap();
every >150 ticks and if FPS display on: FindFPS/DisplayFPS
boss-music check (hdr+0x2724, below)
UpdateSprites();                             // write-back to placement records, kill dead
if (prefs+8) WaitNextEvent(…)                // "allow background tasks"
UpdateStatusBar(1,0,0); HandleAsyncAIFFMusicFade(); HandleAsyncGammaFade(); DeadTime();
if (!prefs[0])      while (TickCount() - 2 < start) DeadTime();      // cap 2 ticks
else if (odd)       while (TickCount() - 4 < start) DeadTime();      // cap 4 ticks / 2 steps
odd = !odd;
```
- **Fixed step, no delta time**: every movement constant is per iteration; the cap is 2 Mac
  ticks (≈30.08 Hz at 60.15 ticks/s). With prefs[0] ("Reduce frame rate", manual) set, even
  iterations skip the screen copy (`PaintFrameWrap(0,…)`) and the pair is capped at 4 ticks:
  logic stays ≤30 steps/s, display ≤15 fps. A slow machine simply runs slower [HIGH].
- `DeadTime` = `Button(); CheckFlags(); MusicAIFFTickle()` [HIGH].
- `.FindFPS @ 100064b0` (float-only, empty in the decompile; raw disasm via
  `tools/FzDisasm.java`): `f1 = 60.0f · frames / ticks` (`lfs f3,-0x62d8(r2)` → 0x100a1568 =
  60.0f; `lfd f2,-0x62c8(r2)` = 0x4330000080000000 int→double magic) [HIGH].
  `.DisplayFPS`: `NumToString((int)(fps·100.0f))` (0x100a1570 = 100.0f), inserts a '.' two
  digits from the right and appends " FPS", draws at (28,470) in 12-pt bold [HIGH]. Shown only
  when `_DAT_100a0064` (the debug flag) is set.
- Exit conditions: `DAT_100a5106` (abort/death) or `_DAT_100a0088` (level complete). After the
  loop: health `G+4 < 1` → `.DeathEffect`; else if complete → `.EndLevelSGUpdate`,
  `.StageCompleteEffect` (skipped when the Escape-Ring flag `_DAT_1009fd64` is set).
- Boss-arena music: if hdr+0x2724 ≠ 0 and `_DAT_1009fed0` and music on, the loop switches to
  track 30 when the counter `_DAT_1009fd6c` ≤ 0, else fades out [MED: the counter's meaning
  (boss alive?) not traced]. At level start the same condition forces `hdr+0x284a = 30`.
  ⚑ corrected (deepening 2026-10-03): `_DAT_1009fd6c` is the current music volume and `_DAT_1009fed0` is "no boss
  alive" (cleared by a boss Setup with the boss flag, set by its Kill): with no live boss the
  level track fades out, then track 30 fades in; the level-start force fires on a revisit after
  the kill (bosses-2 corr. 3, bosses §1.2–§1.4).

## 5. Camera  [HIGH]

`.PlayerScroll @ 1004c528` maintains a focus point: focus x `_DAT_1009fd44 = playerX +
(lookahead _DAT_100a0680 >> 8)` every frame; focus y `_DAT_1009fd40` only follows the player
y when the player is on ground/rope/swimming or leaves the band (view rect inset 16 top, 96
bottom): downward it moves `max(Δ/6, 6)` px/frame, upward `max((focus − limit)/7, 5)`
[HIGH for the arithmetic; the exact list of gating flags is long and quoted in the function].
`playerX/Y` here are `_DAT_1009fd94/_DAT_1009fd90` (set to start+50/start+59 by `.GameLoop`).

`.FindUpperLeftCorner @ 1000b5ec`:
- target h = focusX − 0x130 (304) + hdr+0x270a; target v = focusY − 0xc0 (192) + hdr+0x270c;
  with a 16-px snap of the target x (`(t>>4)<<4`) when the player's |vx| < 256 and not
  carried/swimming/auto-scrolling.
- scroll moves toward target by `max(|Δ|/6, 1)` per frame on each axis (`*0x2aaaaaab>>32`
  ≡ /6).
- auto-scroll levels (hdr+0x272a; §world-data 3.2): mode 1/2 add `speed>>8` to h per frame,
  mode 3/4 to v (mode 4 with speed 0x280 alternates +3/+2 by the frame parity flag
  `_DAT_1009fd30`), clamped to the player position.
- screen shake: while `_DAT_1009ffa0 > 0`, v ± (shake>>1) alternating each frame (`&1`, or
  `&3` with reduce-frame-rate), shake−−.
- graphics modes 2 and 3 (prefs+2) force even v (`(v>>1)<<1`).
- arena bounds from hdr+0x2724/0x272e (boss levels), then the map clamp (§3).

## 6. Game-state machine  [HIGH unless noted]

```
main → MainMenu ─New Game→ NewGame ──→ [GameLoop ⇄ ShowWorldMap]* ─→ Victory → MainMenu
          │                    ↑ level complete → EndLevelSGUpdate, StageCompleteEffect,
          │                    │   ShowWorldMap returns next level (−1 = quit to menu)
          ├─Resume→ ContinueGame (OpenSG) → same loop from the saved level/checkpoint
          ├─Options / Credits / Quit
death (G+4 < 1) → DeathEffect → AskToContinue: only if a save was made/loaded this session
                  (PTR_DAT_1009fe00); "continue" re-enters ContinueGame on that save, else menu.
```
⚑ corrected (deepening 2026-10-03): "continue" re-reads the **file** (`OpenSG(fd18)`) — nothing is refilled, the player
restarts on the save point, and level completions since that save are lost; with no save this
session there is no death screen at all. Only save points (type 1065, once each per game) write
saves; the Esc dialog's Save branch is dead (DITL 202 has no item 5); level completion only
updates memory. Full flow: **save-continue.md** §1–§7.
- There is **no lives counter**: death ends the run unless the player resumes from a save
  (`.AskToContinue @ 10007190` buttons via `TrackClickOnCommandButtonDeath`) [MED: no other
  decrement of a life-like field found; `G+0x12 = 3` is set in `.InitGameGlobals` but its
  reader was not traced — NOT RESOLVED]. ⚑ corrected (deepening 2026-10-03): `G+0x12` is write-only; no lives concept
  (save-continue §8.1) [HIGH].
- Chapter screens: entry to a level with hdr+0x273c ≠ 0 shows `.ChapterScreen(n)` (Titles
  CLUTs 281..287 "1 intro … 7 mountain chapter") only while `G+0x176+2·L == 0` (`.GameLoop`,
  main dump l. 5188–5192). That flag is set by **checkpoint saves as well as completion** (§9),
  so a level re-entered after a checkpoint save in it — e.g. resumed via `.ContinueGame` — shows
  no chapter screen; "first entry" means "no checkpoint or completion recorded for L yet"
  ⚑ corrected (review 2026-10-03) #1.
- Stage load popup `.PopupStageLoad`/`.UpdateStageLoad(…, 100)` during `.SetupLevel`.
- Victory: `_DAT_1009ffc4` set by `.HandleXichraSprite @ 1008e4ec` (death-animation counter
  > 0x96 also sets `DAT_100a5106` to end the loop) or the F8 debug key → `.Victory` (track 29,
  PICTs 159/161/162). ⚑ corrected (deepening 2026-10-03): the counter is Xichra state 8, `w+0x38 − 60 > 150` (frame 211 of
  the death state), reached only after the phase-6 crash landing (bosses-2 §6.4, corr. 4).

## 7. Input

### 7.1 Actions and default keys  [HIGH]
`.IsInputKeyPressed(i)` (`@ 1004a134`) for action `i` 0..8: if prefs+0xa ("Use InputSprocket")
and ISp active → `.InputGetKeyState(i)`, else `IsPressed(prefs[0x12 + 2i])` (GetKeys bitmap,
bit `k&7` of byte `k>>3`). Defaults from `.InitPrefs @ 1000f180`:

| i | action | default Mac key code | key | ISp element (`.InputGetKeyState`) |
|---|---|---|---|---|
| 0 | left | 0x56 | keypad 4 | x-axis < 0x59ffffff |
| 1 | right | 0x58 | keypad 6 | x-axis > 0xa5ffffff |
| 2 | up / climb | 0x5b | keypad 8 | y-axis > 0xa5ffffff |
| 3 | down / duck | 0x57 | keypad 5 | y-axis < 0x59ffffff |
| 4 | run | 0x38 | Shift | button `butnquik` |
| 5 | jump / swim | 0x3a | Option | button `butnjump` |
| 6 | use item / cast | 0x37 | Command | button "Use Item" |
| 7 | previous item | 0x59 | keypad 7 | button "Prev Item" |
| 8 | next item | 0x5c | keypad 9 | button "Next Item" |

(Consistent with the manual's Quick and Simple chapter.) Fixed keys: Caps Lock = pause,
Escape (0x35) = abort-game dialog, ⌘ combos (0x37+0x0c Q quit, 0x0d W abort, 0x23 P options) —
`.CheckGameLoopKeys @ 10007684` [HIGH].

### 7.2 Pause and Caps Lock  [HIGH]
`.CapsLockDown @ 10005f04` = `BitTst(GetKeys, 0x3e)` (BitTst's MSB-first numbering → key code
0x39, Caps Lock). The decompile drops the return value; raw disasm (`tools/FzDisasm.java`,
0x10005f04..0x10005f38) shows `bl BitTst` followed directly by the epilogue, so BitTst's r3 is
the function result [HIGH]. `.CheckGameLoopKeys` calls `.Pause` when caps
lock is down and the debounce `PTR_DAT_1009fe14` is 0. `.Pause @ 10006078`: draws `PICT 0x1339`
(4921, 225×96 in Titles) in the view, fades music, shows the menu bar, installs a sleep proc,
then spins `CheckEvent` until caps lock has been up for 5 consecutive polls; restores volume /
music, hides the menu bar, redraws.

### 7.3 Debug/cheat keys (out of scope, identification only)
`_DAT_100a0064` debug flag set by ⌘+Shift+Option+';'+'0' (key codes 0x37 + 0x38,0x3a,0x29,0x1d)
in `.CheckGameLoopKeys`; then in `.HandleKeys`: keys '1'/'2'/'9' (0x12/0x13/0x19) complete
the level with exit 1/2/0, F13 (0x69) with exit −1, F12 stage-complete effect, F8 victory, F9
kill self, F1 full health/magic, F2 `iRam100a5110 −= 30`, F10 give items (spells-items.md §5); in
`.CheckGameLoopKeys`: F11 (0x67) level number +1, 'C'+'S' (0x08+0x01) save-point save, F5
(0x60) toggles `cRam100a267c`. FPS display also needs the flag.

## 8. Preferences (`'Pref'` id 0 in `Ferazel's Wand Prefs`, 0x942 bytes)  [MED]

Field defaults from `.InitPrefs`; meaning from the reading site:

| off | type | default | meaning (reader) |
|---|---|---|---|
| 0x00 | u8 | 0 | reduce frame rate (`.GameLoop`) [HIGH] |
| 0x01 | u8 | 0 | auto-reuse saved-game file (`.SavePointSave → SaveSG(prefs[1]==0)`) [HIGH] |
| 0x02 | i16 | 1 | graphics detail popup; 3 → scan-line ("black lines") mode, 2/3 → even scroll v [MED] — ⚑ corrected (deepening 2026-10-03): **Graphics** 1 High / 2 Low / 3 Line-skipped (save-continue §8.2) |
| 0x04 | i16 | 2 | effects popup [LOW] — ⚑ corrected (deepening 2026-10-03): ~~effects~~ **Parallax** 1 Super / 2 Parallax / 3 No; no control in the shipped dialog (orphan `CNTL 604`), so always 2 (save-continue §8.2) [HIGH] |
| 0x06 | i16 | 2 if `_DAT_100a511a` < 0x108 else 1; value 3 skips `DrawLightsOntoTiles` [MED] — ⚑ corrected (deepening 2026-10-03): **Effects** 1 Enhanced / 2 Normal / 3 Reduced (save-continue §8.2) |
| 0x08 | u8 | 0 | allow background tasks (`WaitNextEvent` in loop) [HIGH] |
| 0x09 | u8 | 0 | passed as "!flag" to `WrapCopyToScreen` [LOW] |
| 0x0a | u8 | 0 | use InputSprocket [HIGH] |
| 0x0b | u8 | 1 | sound on (`STPlay*` gate) [HIGH] |
| 0x0c | u8 | 1 | music on [HIGH] |
| 0x0e / 0x10 | i16 | 7 / 9 | sound volume? / music volume (music = v·256/9) [MED] |
| 0x12..0x22 | i16[9] | §7.1 | key codes [HIGH] |
| 0x2a, 0x30 | i16 | 0x30, 0x4c | Tab, Enter (dialog keys?) [LOW] |
| 0x32 / 0x34 | i16 | 0 / 1 | written by `.InitPrefs @ 1000f180`; reader not traced [HIGH for the defaults] ⚑ corrected (review 2026-10-03) #9 — ⚑ corrected (deepening 2026-10-03): +0x32 switch the monitor to 640×480 (`.ResSwitch`), +0x34 ask the resolution question on launch (`DLOG 1300`) (save-continue §8.2) |
| 0x36 / 0x38 | i16 | 0 / sysvol/28 | use system volume / sound volume·28 [MED] |
| 0x3a | i16 | −1 | machine hash for the CD check (out of scope) [HIGH] |
| 0x3c / 0x3e / 0x40 | i16 | 0 / 0 / 0 | written by `.InitPrefs`; reader not traced [HIGH for the defaults] ⚑ corrected (review 2026-10-03) #9 |
| 0x42 | pstr[256] | **"@@@@@"** — the 5-byte pstr at `0x100a3193` (`pef.b(0x100a3180,0x40)` → `…quit.\x05@@@@@\x0bPreferences…`); "Preferences" at `0x100a3199` is the resource *name* passed to `AddResource(h,'Pref',0,&DAT_100a3199)`, not this default [HIGH] ⚑ corrected (review 2026-10-03) #5 | last saved-game file name [MED] |
| 0x142 | pstr[256]×8 | empty | NOT RESOLVED — ⚑ corrected (deepening 2026-10-03): **write-only** (only `.InitPrefs` touches it, raw 0x1000f410) (save-continue §8.2) [HIGH] |

## 9. Saved games  [HIGH unless noted]

File type `'FWSg'`, creator `'Msct'`; one resource `'FWSg'` id 0 named "Ferazel Saved Game"
(`.SaveSG @ 10048294`, `.OpenSG @ 10048608`). Resource body = the 0xebe58-byte save block
(`_DAT_100a0054`):

| off | size | content | writer |
|---|---|---|---|
| 0x00000 | u32 | `Mwld+0x100` stamp (resume refuses a mismatch) — ⚑ corrected (deepening 2026-10-03): compared only on `.ContinueGame`'s fallback branch (default world file unopenable) (save-continue §3.3–§4) | DoSaveGame / SavePointSave / EndLevelSGUpdate |
| 0x00004 | u8 | "preview version" flag (resume refuses if 1) | set 0 |
| 0x00005 | u8 | "demo version" flag (resume refuses if 1) | set 0 |
| 0x00006 | u8 | 1 = at checkpoint / end of level (restores the record snapshot) | |
| 0x00008 | i16 | level number (< 80) | |
| 0x0000c | i32 | player x | SavePointSave, EndLevelSGUpdate |
| 0x00010 | i32 | player y | SavePointSave, EndLevelSGUpdate |
| 0x00018 | 0x19978 | copy of `G` (0x332f × 8 bytes; ends exactly at 0x19990). The decompile's `puVar9 = save+0x10; puVar9[2] = …` hides the +8: raw disasm of `.SavePointSave` shows `addi r5,r3,0x10` then `stwu r3,0x8(r5)` (pre-increment) — first store at +0x18 [HIGH] | |
| 0x19990 | u32 | `GetDateTime` | |
| 0x19998 + 0x2000·L | 511×16 | placement-record snapshot of level L (x,y stored −6, restored +6) | |
| 0xe7d98 | pstr | world file name (`_DAT_1009fd58`) | DoSaveGame — ⚑ corrected (deepening 2026-10-03): `.DoSaveGame` is unreachable in 1.0.3 (DITL 202 has no item 5), so this is never written (save-continue §3.3) |

`G` itself (from `.InitGameGlobals @ 10001498`; uses from the pickup/HUD code) holds: +0x00
score (i32; drawn by `.UpdateTextStats`), +0x04 health, +0x06 breath (oxygen, ≤ health), +0x08
suffocation countdown, +0x0a max health (start 560 each), +0x0c max magic, +0x0e magic (560),
+0x10 coins (drawn at (150,19); lost on hits), +0x12 = 3 (NOT RESOLVED; ⚑ corrected (deepening 2026-10-03): write-only,
save-continue §8.1), +0x16 start facing (header 0x26c8 at NewGame / once at ContinueGame; the
facing at each save point — save-continue §8.3) ⚑ corrected (deepening 2026-10-03), +0x14 gold-Xichron
counter (wraps at 100), +0x24 + 10·k inventory slots k < 27 (spells-items.md §1), +0xad8 + 2·n
world flags set by trigger sprite 1058,
+0x172 selected slot, +0x174 OmniPx-active, +0x176 + 2·L **"level L has a save snapshot"
[100]** (see below), +0x23e + 2·L level unlocked[100], +0x306/+0x3ce/+0x496 (+0x55e/+0x626)
per-level achieved counters[100], +0x6ee/+0x7b6/+0x87e (+0x946/+0xa0e) per-level totals[100],
+0xad6 count + +0x12d8 u8[20000] level-of-destroyed-crunch-tile + +0x60f8 pairs[…] (re-applied
by `.SetupLevel` when revisiting). Pair order: `.SetupLevel` calls
`GetFGCrunchDirTile(G[0x60fa+4i], G[0x60f8+4i])` / `DestroyCrunchTile(same, …)`, so the label
"(y,x)" rests on the unread argument order of those two callees [MED] ⚑ corrected (review
2026-10-03) #12. ⚑ corrected (deepening 2026-10-03): **(y at +0x60f8, x at +0x60fa) [HIGH]** — `.CrunchTile` unpacks a
QuickDraw Point and calls `GetFGCrunchDirTile(h>>5, v>>5)` (platforms-ropes-radial §6,
triggers-background-2 corr.). The save-block layout re-checked against raw, the save-point trigger
and the New Game / Continue / death flows: **save-continue.md** §2–§5 (its §3.3 table supersedes
the table above where they differ).

**G+0x176 is not "completed"** ⚑ corrected (review 2026-10-03) #1. It is cleared only by
`.InitGameGlobals` and set to 1 by both `.SavePointSave @ 1000c104` (every checkpoint save:
raw `1000c1b4 lha r0,0x0(r28)` … `1000c1c0 sth r5,0x176(r3)` with r5 = 1; decompile
`*(undefined2 *)(iVar6 + *psVar2 * 2 + 0x176) = 1`, main dump l. 6316) and
`.EndLevelSGUpdate @ 1000c8d8` (level end, l. 6494). Meaning: "checkpointed or completed — a
record snapshot for L exists in the save block". Consequences a replica must reproduce:
- `.SetupLevel @ 1000430c` (l. 2378–2420): flag `== 1` → restore branch: re-destroy the crunch
  tiles logged for L, copy the 511-record snapshot `save+0x19998+0x2000·L` back into the level
  (x/y +6), and **keep** the per-level counters; flag `== 0` → first-visit branch: zero
  `G+0x306/0x3ce/0x496` for L and recount the totals `G+0x6ee/0x7b6/0x87e`. A replica that sets
  the flag only on completion would, after a checkpoint resume, reset the stats and respawn every
  collected/killed sprite. (Debug key code 0x76 held during `.SetupLevel` clears the flag first
  → forced fresh load; out of scope.)
- `.GameLoop` chapter-screen gate (§6) tests the same flag.
