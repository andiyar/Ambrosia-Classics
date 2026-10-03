# Deimos Rising 1.0.6 — application flow, frame cadence, screen, RNG, input, film, prefs

Code readings only; nothing is behaviour-verified. Conventions as in pak-format.md.
`PermFloat(n)` = `FUN_10020250(n)` = item n of `flli/Game[gafl]` (data-tags.md §3, HIGH);
`GameString(n)` = `FUN_10020260(n)` = line n of `stli/Game[pgsl]`.
Key codes below are Mac virtual key codes passed to `FUN_10049150(code)` = `GetKeys` + `BitTst`
(`FUN_10049150 @ 10049150`, HIGH), named from Apple's standard US virtual-key table
(0x35 Esc, 0x39 Caps Lock, 0x32 `` ` ``/~, 0x1B `-`, 0x18 `=`, 0x61 F6, 0x3A Option, 0x37 Command).

## 1. Binary identity (correction to the lane prompt)
PEF loader section (Python over `ghidra/Deimos_pef`, container header + loader info): 3 sections
(code 910128 B; packed data → 265176 B; loader), main = section 1 offset `0x2760`, 10 import
libraries: MathLib, QuickTimeLib, AppearanceLib, InternetConfigLib (the loader-string literal is
`ICAp;InternetConfigLib` — fragment-name prefix; ⚑ corrected (review 2026-10-03) #15), DrawSprocketLib,
**InterfaceLib (384 imports)**, SoundLib, UnicodeConverter, TextCommon, InputSprocketLib. No
CarbonLib. This data fork is a classic Mac OS 8/9 CFM/PEF application, not a Carbon one, even
though its resource fork carries `carb` 0 and `plst` resources. [HIGH — loader section bytes]
OS X–only pieces (`HID.bundle`, "M_HIDConfigure.cc", "M_ControlsConfigure.cc" strings) are not
reachable through the imports above; `GetSharedLibrary`/`FindSymbol` are imported, so run-time
binding may exist. [LOW]
Version strings (`FUN_100000e0`): "Version: %s, %s, %s" with "1.0.6"-family args and build date
"Jan  2 2004". Resource `vers` 1/2: `01 06 80 00` = 1.0.6 final. [HIGH]

## 2. Application flow

`FUN_100000a0 @ 100000a0` (called from the CFM entry):
```c
  FUN_100000e0();      // boot + load everything
  FUN_100229a0();      // interface (main menu) loop
  FUN_10000630();      // "Starting Shut Down Sequence"
```
[HIGH — read directly; roles from strings in each callee]

`FUN_100000e0` boot order (calls in order, roles by strings/consumers):
Toolbox init `FUN_10048330` → log "Version…" → managers (`FUN_1003a780` U_Manager, `FUN_1000ca90`
memory, `FUN_1002cef0` console) → pak tag index (`FUN_100015a0` → `FUN_100016c0`) → prefs load
`FUN_10004540` → input `FUN_1004a8b0` → read keys Option(0x3A)/Command(0x37) → resource manager
`FUN_1001f7c0`, permanent lists `FUN_1001fcf0` (+ floats) → music init `FUN_10047e40(PermFloat 37)`,
sound init `FUN_10047160(PermFloat 38)` → if Option held or pref byte 2 == 0: configuration
dialog `FUN_100047c0` ("Presenting Configuration Dialog") and set pref byte 2 → display
`FUN_1000ae20(…, 640, 480, 16, pref byte 4)` → publisher logo `pucr` (+ sound `publ` unless
Command held), wait PermFloat 66 (=130) ticks or the sound → developer logo, interface music
`inmu` (unless Command held), wait 0xF0 (240) ticks → loading screen `back` → load permanent
sprites/sounds/strings `FUN_1001fe60`, levels `FUN_10011a70`, units `FUN_1003cf10`, weapons,
players, score bar, etc. [HIGH for order; MED for each callee role]

Start-game path `FUN_100234d0(isFilm, …) @ 100234d0` (called from the menu): if not a film: play
`ammu` music, level selection `FUN_1002e310` → returns level ID (or `none`) and a start index;
run the game `FUN_100051a0(&{levelID, numPlayers, filmFlag…}, result)`; afterwards compute the
highest completed sector and store it in int pref 3 (`FUN_10004ac0(3,…)`) only when started from
sector 1 (`!bVar1`, i.e. start index ≤ 1) and no cheating flag; if a player's score beats the
15th table entry (`FUN_10021470`, compares with prefs `+0x1298`) enter the high-score screen
`FUN_100214c0`. [MED — the flags `local_a6/a7/a8` were not fully named]
Guide cross-check (cite): the guide says highest level is remembered only when starting from
Mariner Valley, and a higher start gives no high score — consistent with this reading.

## 3. The game loop (`FUN_100051a0 @ 100051a0`, G_Game.cc)

Skeleton (decompile, trimmed):
```c
  iVar10 = FUN_10046580(400,2000);                 // random frame for the unregistered cut-off
  DAT_100e00fc = FUN_10010f90(_DAT_100dea30);      // registered?  (out of scope)
  ...  console commands registered once (SHADOWS, FPS, LIMITFPS, PLAYER, VERSION, … cheats)
  for two players: FUN_1004d320(0x36c) player objects
  iVar14 = FUN_1004d320(0x9d7c); FUN_10009390();   // film buffer (§7)
  FUN_10030190(auStack_9a0); FUN_10030210(auStack_9a0,bVar2,1,1);   // frame controller init
  if (film) FUN_100069b0(...) /* load film, srand(film seed) */
  else    { uVar11 = FUN_100497f0(); FUN_10055400(/*uVar11, see §9*/); FUN_10009710(film,levelID,players,uVar11); }
  ...
  while (puVar9[8] != '\0') {                                     // game running
      uVar11 = FUN_10030360(auStack_9a0,local_a27,&local_a28);    // begin frame: input, pause, console
      if (local_a28 != '\0') FUN_100064c0();                      // quit requested
      if (local_a27[0] != '\0') {                                 // LOGIC TICK this frame
        if (puVar9[0x38] == '\0') {
          FUN_10020250(0x12);                                     // NumFramesUntilGameAppears = 2
          if (*(int *)(puVar9 + 0x1c) == (int)in_f1) { music; fade in; puVar9[0x38] = 1; }
        }
        FUN_10006b50(local_a27 + 2,bVar2,local_a27 + 1,iVar14);   // update world
        FUN_10007170(auStack_9a0,bVar2,auStack_7e0);              // level-complete -> next level
        *(int *)(puVar9 + 0x1c) = *(int *)(puVar9 + 0x1c) + 1;    // GAME TIME ++
        if ((bVar4) && (*(int *)(puVar9 + 0x1c) == iVar10 + 400)) { puVar9[8] = '\0'; break; }
      }
      FUN_10007070();                                             // draw world
      if (film) { mouse/key aborts; else draw "REPLAY" (GameString 9) }
      FUN_10030570(auStack_9a0,1,puVar9[0x38]);                   // end frame: present + pace
  }
```
⚑ corrected (wave 2, 2026-10-03): was "console commands registered once (SHADOWS, FPS, LIMITFPS, PLAYER,
VERSION, … cheats)" — `FUN_1002d080` skips every command registered with debugOnly ≠ 0, so only
FPS, VERSION/VERS, SUPERMUNKI and the cheats LIFE, ACCURACY, FUNDS, SCORE, SHIELDS, MULT exist;
SHADOWS, LIMITFPS and PLAYER are not added — see messages-notices-console.md §5.2, timing-frame.md §6.
⚑ corrected (wave 2, 2026-10-03): was "music; fade in" at game appearance — there is no music fade-in: the
call is `FUN_10047f90(levelMusic, 1, 0)` followed by `FUN_1000ba70(display, 1)`, a display fade
from black (9 steps) — see sound-music.md §6.2, loose-ends-session.md §6.
Claims:
- One logic tick = one call of `FUN_10006b50` and one increment of game time (`+0x1c` of the
  game struct at `PTR_DAT_100defd0`); all game durations in the data (frames, `*_INT` delays)
  count these ticks. [HIGH for the increment; MED that all data delays use this counter]
- Drawing (`FUN_10007070`) runs every loop pass, ticked or not. [HIGH]
- There is no time accumulator / catch-up: a slow machine runs the game slower. [HIGH — the only
  gates on the tick are the speed divider and pause, §4]
- Unregistered copies: on levels outside the first four of the order table (§6) the game ends
  400 ticks after a random tick in [400,2000] (`bVar4` path). Out of scope for the replica.
  [HIGH reading; out of scope]

`FUN_10006b50 @ 10006b50` (update world) order: input poll (`FUN_1004aa20` clear,
`FUN_1004aa90` ISp read unless console open) → notices `FUN_10018320(gameTime)` → debris
`FUN_1002a770` → particles `FUN_100438c0` → motion blur `FUN_10046a10` → each player
`FUN_10028170(player, …)` → score bar `FUN_100317e0` → if no player alive: game-over notice
(object 24 `Notice_GameOver`) then stop after PermFloat 13 (=110) ticks → `FUN_10010000` scroll +
end-of-level detection → end-of-level tallies (§5) → entity groups `FUN_10033850(gameTime)`,
whose return value pauses (`FUN_1000ffe0`) or resumes (`FUN_1000ffc0`) vertical scrolling.
[HIGH for the call order; MED for callee roles]

## 4. Frame cadence (frame controller `0x10030190…0x10030df0`, unattributed, between G_LevelSelection.cc and G_ScoreBar.cc)

Begin frame `FUN_10030360`: `FUN_10047f50` (music service), console key 0x32 (`` ` ``) opens
the console (`FUN_1002d1a0`, sound `gaso[1]`), Esc handled by `FUN_100307c0`, `FUN_10030910`
handles `-`(0x1B)/`=`(0x18) volume down/up and F6 (0x61) interlace toggle (pref byte 5),
Caps Lock (0x39) sets the paused flag and shows GameString 0 "Press Caps Lock"; returns the tick
flag `+0x34`. [HIGH for keys/strings]
Esc (`FUN_100307c0`): if pref byte 8 == 0 (the default) → quit at once; else Esc must be held
for more than PermFloat 32 (=30) consecutive frames. [HIGH reading; the dialog label of pref 8
NOT RESOLVED] ⚑ corrected (wave 2, 2026-10-03): was "held for more than … 30 consecutive frames" — the hold
counter is bumped twice per frame (begin frame and the end-frame wrapper), so quit comes on the
**16th** held frame; pref 8 is DITL item 17 "ESC Key Delay (Requires key to be held down)" — see
timing-frame.md §2.5, §6.

End frame `FUN_10030bc0 @ 10030bc0`:
```c
  cVar6 = FUN_10004ef0(9);                          // pref byte 9: draw FPS counter
  ...
  FUN_10018b20(0); if (param_2) FUN_10010120();     // render layers / background
  FUN_10018b20(1); if (param_2) FUN_10043ba0();
  FUN_10018b20(2);
  cVar6 = FUN_10004ef0(10);                         // pref byte 10: frame-rate limiter on
  if (cVar6 != '\0') {
    do {
      FUN_10020250(0x21);                           // FPS_Delay = 2.0
      iVar1 = (int)in_f1;
      iVar3 = *(int *)(param_1 + 0x1c);             // TickCount at previous present
      uVar4 = FUN_100497f0();                       // TickCount()
    } while (uVar4 < (uint)(iVar3 + iVar1));
  }
  *(undefined4 *)(param_1 + 0x1c) = FUN_100497f0();
  *(int *)(param_1 + 8) += 1;  *(int *)(param_1 + 0x20) += 1;      // frame counters
  if (*(int *)(param_1 + 0x30) == 0) {              // speed divider countdown
    *(undefined1 *)(param_1 + 0x34) = 1;            // tick next frame
    *(undefined4 *)(param_1 + 0x30) = *(undefined4 *)(param_1 + 0x2c);
  } else {
    *(undefined1 *)(param_1 + 0x34) = 0;
    if (*(int *)(param_1 + 0x2c) != 999) *(int *)(param_1 + 0x30) -= 1;
  }
  ... present: FUN_1000beb0 (interlaced, field +4 == 1) or FUN_1000bc60 (+4 == 0)
```
⚑ corrected (wave 2, 2026-10-03): was "`FUN_1000beb0` (interlaced, field +4 == 1)" — `fc+4` is the
`FUN_10030210` init argument (1 in the game loop, 0 on level select), not the interlace pref;
`FUN_1000beb0` is the game-screen present (borders, game area, score bar) and `FUN_1000bc60` the
full-screen present. Interlacing is byte pref 5, consumed by the background blit `FUN_10010120` —
see timing-frame.md §2.3–§2.4, §5, messages-notices-console.md §4.4.
Claims:
- With the limiter on, each frame is presented no sooner than 2 Mac ticks (TickCount, ~60.15 Hz)
  after the previous one ⇒ at most ~30 frames/s — the `FPS_MaxRate` 30 of the data is the label
  of that cap. `FUN_100497f0` is a thin `TickCount()` wrapper. [HIGH]
  ⚑ corrected (wave 2, 2026-10-03): was "the `FPS_MaxRate` 30 … is the label of that cap" — the limiter
  constant is `FPS_Delay` (flli 33 = 2); `FPS_MaxRate` (flli 32) is the FPS-monitor and Esc-hold
  threshold. The limiter (byte pref 10, ON in fresh prefs) cannot be toggled in a stock build:
  `LIMITFPS` is not registered and no dialog item exists → 30.07 ticks/s on a fast machine — see
  timing-frame.md §2.3, §4, §6.
- Logic ticks per frame: 1 when the divider `+0x2c` is 0 ("Game Speed Normal"); otherwise one
  tick every `div+1` frames; `div == 999` freezes ticks ("Stopped"). The GameString list holds
  "Game Speed Normal/Half/1/4th/1/8th/1/16th/1/32th/Stopped" (lines 24–30) but the code that
  writes `+0x2c` was not found (only `FUN_10030790` zeroes it) → divider values per label NOT
  RESOLVED. [HIGH for the mechanism] ⚑ corrected (wave 2, 2026-10-03): was "divider values per label NOT
  RESOLVED" — no code writes `+0x2c` (only the zeroing `FUN_10030790`/`FUN_10030df0`), so the game
  always runs at Normal, one tick per frame; the strings have no consumer — see timing-frame.md §3.
- FPS monitor `FUN_10030640`: once per 60 ticks compares frames counted with PermFloat 32 (30);
  after PermFloat 34 (=10) deficient seconds, if the "auto interlacing" pref byte 6 is set and
  interlacing (byte 5) is off, it switches interlacing on and shows GameString 17. [MED]
  ⚑ corrected (wave 2, 2026-10-03): was "after … 10 deficient seconds" — deficient windows (> 60 ticks,
  count < 30) are counted cumulatively, never reset by a good window; the whole monitor runs only
  with the limiter on and needs session flag +3; pref 6 has no UI, so in a stock install
  auto-interlace never fires — see timing-frame.md §2.6, §5.
- `Microseconds` is imported but called only from library code (two calls, in `FUN_1006df40` and `FUN_1006e080`,
  `0x1006c000` region); the game clock is TickCount via `FUN_100497f0` (18 callers) and `FUN_10049820`.
  [HIGH for the call sites — `find_func.py 'glue::Microseconds\(|glue::TickCount\('`]
  ⚑ corrected (review 2026-10-03) #10: was "19 callers"; `find_func.py 'FUN_100497f0\(' --names` prints 19 blocks, one of
  which is the definition itself (`void FUN_100497f0(`) → 18 callers.

## 5. Screen pipeline and coordinates
- Display 640×480×16 (PermFloats 52/53/56) via DrawSprocket (`M_Display.cc`, "DrawSprocket
  1.7.2 or later is required") or a window ("Running in windowed mode"); choice from pref byte 4
  (`FUN_1000ae20(…, pref 4)`). [MED]
- Screen layout from flli: left border 32 | game area 416×480 | right border 32 | score bar
  160×480 (32+416+32+160 = 640). `FUN_1000ae20` reads exactly PermFloats 52,53,59,55,54,57,58.
  Score-bar element positions are absolute screen x (e.g. `ScoreBar_P1ShieldMeter_XLoc` 495). [HIGH
  for values; MED for the placement arithmetic]
  ⚑ corrected (wave 2, 2026-10-03): was "left border 32 | game area | right border 32 | score bar" and
  "absolute screen x" — `FUN_1000ae20` places the score bar directly after the game area (screen
  x 448..607; the remaining 32 px are x 608..639, `RightBorderWidth` F60 is not read there), and
  every score-bar flli XLoc/YLoc and `tefo` Loc is in **back-buffer** coordinates (bar = x 416..575),
  so screen x = buffer x + 32 — see hud-scorebar.md §1.
- Terrain: the level map is 480×3600 (`#background_RECT <0, 0, 480, 3600>` in all 12 levels);
  the visible 416-wide window is offset horizontally inside the 480-wide map by up to ±32
  (`FUN_100100b0`: offset `_DAT_100e0144` clamped to [-32, 31], moved ±1 per call;
  `FUN_10010120` draws from x = offset+32). [HIGH for the clamp; MED that the player's x drives it]
  ⚑ corrected (wave 1, 2026-10-03): was "MED that the player's x drives it" — the shift is driven by each active
  player's left/right **input** (not the ship's x), ±1 px per tick, reset per level [HIGH], see
  player-physics.md §2.5, level-scroll-objects.md §5.
- Vertical scroll `FUN_10010220`: each logic tick the window top `_DAT_100e5acc` decreases by the
  scroll speed `_DAT_100e0128` (set to **1** by `FUN_1000ffc0`, 0 by `FUN_1000ffe0`), so the
  map scrolls **1 pixel per tick** from the bottom (row 3600-480) towards row 0. When the window
  top reaches 0 the level-end flag `DAT_100e0148` is set (`FUN_10010000`). [HIGH for the -1/tick;
  MED for initial top = 3120 (from `_DAT_100e5acc < 1` clamp logic and VisibleGameHeight)]
  ⚑ corrected (wave 1, 2026-10-03): was "When the window top reaches 0 the level-end flag … is set" and "MED for initial
  top = 3120" — the flag is set when the progress counter (starts 481, +1 per scrolled px)
  reaches the RECT bottom 3600, i.e. at window top = **1** (minimum 3119 scroll ticks); initial top
  3120 is HIGH (`FUN_1000fa90`, listing `1000fb38`) — see level-scroll-objects.md §2–§3, bosses.md §2.3.
  At 30 ticks/s a level lasts ≥ 3120/30 = 104 s plus every scroll pause. [MED — arithmetic]
- Level objects spawn when the scroll reaches them: `FUN_10010000` calls
  `FUN_10033090(_DAT_100e5acc - 0x40)`, which spawns every pending level object whose `yLoc`
  equals that row exactly, i.e. 64 px above the visible top. Ground-layer objects have their x
  shifted by −32.0 (`*(float*)(_DAT_100df440+0xc)` = 32.0, read from the memory image) in
  `FUN_10035900`. [HIGH] ⚑ corrected (wave 1, 2026-10-03): was "Ground-layer objects" — the shift is keyed on the
  unit's `isGroundBased` (unit+8 == `grnd`), not the placement `#layer_ID`; the spawn row enters
  as world y −64 — see level-scroll-objects.md §6.2, §7.
- Render layers (`FUN_10012fa0`, draw-layer 4CC → layer number): `defa` → 3 (ground) / 7 (air,
  by entity flag +0x19), `grou` 3, `grhi` 5, `ailo` 7, `aihi` 8, `plwe` 9, `play` 10, `plsh` 11,
  `plef` 12, `plui` 13, `atmo` 14, `hud ` 15; shadows → layer 1 offset by Shadow_X/Y (flli
  48–51). 4CCs decoded from the float-typed compares (`2.926252e+29` = `play`, etc.). [HIGH]
  ⚑ corrected (wave 2, 2026-10-03): was "shadows → layer 1" — shadows go to layers 2/4/6 (0 for terrain
  stamps; layer 1 is the terrain-stamp sprite) — see sprite-geometry-draw.md §5.2, §6.

## 6. Level order, sectors, demos
`FUN_10011c00 @ 10011c00` builds the level list from a 12 × 64-byte table (pointer in TOC slot
`0x100df0cc` → `0x100d6470`, read from the code-block image), each entry an obfuscated
identifier decoded with `FUN_10046470` and matched against every level's `#indentifier_STR`:
| sector | identifier | level file | `#name_STR` |
|---|---|---|---|
| 1 | Lucena | le07 | Mariner Valley |
| 2 | Yippe | le06 | Cydonia Plateau |
| 3 | Vista | le02 | Darius |
| 4 | Swoop | le08 | Neo Kowloon |
| 5 | Conrad | le11 | Heart of Darkness |
| 6 | Delos | le04 | Bellerephon |
| 7 | Sparta | le12 | Greater Babylon |
| 8 | Saratoga | le03 | Ticonderoga |
| 9 | Hannibal | le05 | Yucatan Rift |
| 10 | Leonidas | le01 | Kepler Massif |
| 11 | Thebes | le10 | Thermopylae |
| 12 | Yamato | le09 | Carthage |
The tag number in the file name is NOT the play order. Independent data cross-check: the `Level`-family
controller units are named by sector ("Level 7 - Start 1" = `07s1`), and the controller prefixes
placed in each level file are: le07→01, le06→02, le02→03, le08→04, le11→05, le04→06, le12→07,
le03→08 (+04), le05→09, le01→10 (+09), le10→11, le09→12 — every file contains its own sector's
controllers (`grep -o '#unit_ID <[0-9][0-9]..>'` per decoded level). [HIGH — table bytes decoded; matching
loop read]. The guide calls Mariner Valley the first level (cite) — agrees.
`FUN_10011b30` treats the first 4 identifiers as the unregistered-accessible set. The four
demo films record le07, le06, le02, le08 (film headers, §7) — the same four. [HIGH]

## 7. Film (replay) format — `film` tags, 40296 bytes
Struct in memory = 0x14-byte runtime header + the 0x9d68-byte file image (`FUN_10009390` zeroes
0x9d68 bytes at +0x14 and writes version `0x2715` there; `FUN_100095b0` saves exactly
`film + 0x14`, 0x9d68 bytes). File layout (big-endian):
| file off | size | field | evidence |
|---|---|---|---|
| 0x00 | 4 | version = 0x2715 (10005) | `FUN_10009390`; loader rejects other versions ("out of date (Film version: %i)") |
| 0x04 | 4 | RNG seed | `FUN_10009710` param 4; playback `FUN_10009680` → `FUN_10055400` (srand) |
| 0x08 | 4 | level ID 4CC | `FUN_10009710` param 2 |
| 0x0c | 1 | number of players | `FUN_10009710` param 3 |
| 0x10 | 0x4eac | player 1 block | stride `param_2 * 0x4eac` |
| 0x4ebc | 0x4eac | player 2 block | |
Player block: `+0` u32 frames recorded; `+4` u32 = **decoded player score + 0xb3ac2**; `+8` 4CC
current level (`FUN_10005cc0`); `+0xc…` one input byte per tick, max 20000 (`< 20000` guard;
0xc + 20000 = 0x4e2c ≤ 0x4eac). [HIGH]
⚑ corrected (review 2026-10-03) #4 (was "param_4 not traced — score inferred [MED]"): the only caller of the recorder,
`FUN_1002a3a0 @ 1002a3a0` (dump line 24976; per-player input step, runs only when player state
byte `+0xc6 == 4`), passes the de-obfuscated score:
```
1002a414  lwz r6,0xb0(r29)        ; player+0xb0 = score + 0x5532a3e (waves-and-enemies.md §7)
1002a424  subis r6,r6,0x553
1002a428  subi r6,r6,0x2a3e       ; r6 = score
1002a42c  bl 0x10009830           ; FUN_10009830(film, player+0xcc, player+0x1fc, score)
```
and `FUN_10009830` stores `param_4 + 0xb3ac2` at block `+4` on every recorded tick (so the
field holds the score at the last recorded tick; frozen once 20000 ticks are reached). Demo 01:
0x000b9c9c − 0xb3ac2 = 25050. [HIGH — disassembly + file bytes]
Input byte (`FUN_10009830` record / `FUN_100097a0` replay):
| bit | input struct byte | meaning (§8) |
|---|---|---|
| 0 | [3] | left |
| 1 | [1] | right |
| 2 | [0] | up |
| 3 | [2] | down |
| 4 | [4] | fire ground |
| 5 | [5] | fire air |
| 6 | [6] | select weapon |
Worked decode — `xxd -l 96 "$D/Game/film/Demo 01[de01].film"`:
```
00000000: 0000 2715 0004 69c2 6c65 3037 0100 0000  ..'...i.le07....
00000010: 0000 12c9 000b 9c9c 6c65 3037 0000 0000  ........le07....
...
00000040: 0000 0000 0000 0000 0000 0000 0001 0101  ................
00000050: 0101 0101 0100 0000 0000 0202 0202 0202  ................
```
version 0x2715, seed 0x000469c2, level `le07`, 1 player; P1: 0x12c9 = 4809 ticks, 0x000b9c9c −
0xb3ac2 = 0x61da = 25050 (score), level `le07`, inputs from 0x1c: zeros then `01` (left) runs,
`02` (right) runs. P2 block at 0x4ebc is empty except `none` at 0x4ec4. Demo headers: de01 le07,
de02 le06, de03 le02, de04 le08 (seeds 0x469c2, 0x4f655, 0x54c83, 0x5afed). [HIGH]
Attract mode: `FUN_100069b0` cycles through `film` tags whose name contains "Demo"
(`_DAT_100e00f8` → "Demo"), wrapping; a normal game saves itself as tag `last` ("Last Film").

## 8. Input (InputSprocket path; M_Application/`0x1004a8b0…0x1004b270`)
`FUN_1004abd0` builds 10 ISp needs (5 per player; strings in order): "Player n Horizontal
Movement" (axis x), "Vertical Movement" (axis y), "Fire Ground" (button `fire`), "Fire Air"
(button `sfir`), "Select Weapon" (button `optn`); `ISpInit(10, needs, …, 'Deim', '0002', …)`,
activates keyboard (`keyd`) and mouse (`mous`) device classes. [HIGH]
`FUN_1004afa0` poll → per-player 7-byte struct:
```c
  .glue::ISpElement_GetSimpleState(*puVar2,local_14);          // P1 axis x
  if (local_14[0] < 0x2fffffff) puVar1[3] = 1;                  // low  -> [3]
  else if (0xbfffffff < local_14[0]) puVar1[1] = 1;             // high -> [1]
  .glue::ISpElement_GetSimpleState(puVar2[1],local_14);         // P1 axis y
  if (local_14[0] < 0x2fffffff) puVar1[2] = 1;  else if (0xbfffffff < …) *puVar1 = 1;
  ... buttons -> [4] fire ground, [5] fire air, [6] select weapon; P2 at +7..+13
```
Axis thresholds: below 0x2FFFFFFF / above 0xBFFFFFFF of the 32-bit ISp axis range. [HIGH]
Byte meanings: [0]=up, [2]=down, [3]=left, [1]=right [HIGH]; [4..6] from need order [HIGH].
⚑ corrected (review 2026-10-03) #5 (was "[3]=left, [1]=right [MED]; [0]=up, [2]=down — ISp convention assumed [LOW]"):
the consumer decides it. `FUN_1002a3a0` copies the 7 bytes to `player+0x1fc` (`[0]`=+0x1fc …
`[3]`=+0x1ff); `FUN_10028170` (player update, dump-function lines ~500–535) applies them to the
velocity pair `player+0x10` (vx) / `player+0x14` (vy), step `*(float*)(playerDef(+0x94)+0xd8)`,
clamp `±player+0xa4` (`param_1[0x29]`):
```
100291dc  lbz r0,0x1fc(r31)  ; [0]   -> 10029208 fsubs f1,f1,f0 ; stfs f1,0x14(r31)   vy -= step
100291e8  lbz r14,0x1fe(r31) ; [2]   -> 1002922c fadds f1,f1,f0 ; stfs f1,0x14(r31)   vy += step
100291ec  lbz r15,0x1ff(r31) ; [3]   -> 10029254 fsubs f1,f1,f0 ; stfs f1,0x10(r31)   vx -= step
100291f0  lbz r16,0x1fd(r31) ; [1]   -> 10029278 fadds f1,f1,f0 ; stfs f1,0x10(r31)   vx += step
```
Map y grows downward (row 0 = top, the scroll window top decreases, engine-loop §5; the player's
`entry_StartVelocityY` is −7.2, i.e. it enters moving up), so [0]=up, [2]=down, [3]=left,
[1]=right. With neither horizontal (resp. vertical) byte set, vx (resp. vy) decays toward 0 by
one step per tick (same block, `pdVar4[2]` = 0.0). The playerDef offsets `+0xd8`/`+0xa4` are
presumably `active_VelocityDelta` 1.6 / `active_DefaultMaxSpeed` 7.8 (the `plde` key→offset
table is still NOT RESOLVED, INDEX #7) [MED for that naming only].
Defaults (guide, cite only): arrows move, Command fire air, Space select weapon, Option fire
ground, Esc quit, Caps Lock pause, F6 interlace, ~ console. The resource fork `STR#` 130 is a
key-name table indexed by virtual key code ("A","S","D","F","H","G","Z","X",…) used by a key
configurator. The OS X key/HID mapping code and the default key table are NOT RESOLVED.

## 9. RNG
`FUN_100553e0 @ 100553e0` (MSL `rand`):
```c
  _DAT_100e032c = _DAT_100e032c * 0x41c64e6d + 0x3039;
  return _DAT_100e032c >> 0x10 & 0x7fff;
```
`FUN_10055400(s)` = `srand` (stores `_DAT_100e032c`). `FUN_10046580(min,max) @ 10046580` =
`min == max ? min : min + rand() % (max - min + 1)` (no `rand` draw when min == max). [HIGH]
`FUN_100465e0(lo,hi) @ 100465e0` = **float RandomRange** (f1, f2 → f1), single precision:
```
100465fc  fcmpu cr0,f29,f30      ; lo == hi ?  -> return lo, NO rand draw
1004660c  fcmpo cr0,f29,f30      ; f31 = (lo > hi) ? hi : lo        (= min)
10046620  bl 0x100553e0          ; rand()
10046628  xoris r3,r3,0x8000     ; int -> double via 0x43300000 / 4503601774854144.0 (r2-0x6ddc)
1004663c  fsubs f1,f30,f29       ; hi - lo
10046654  fmuls f1,f1,f2         ; (hi - lo) * rand()
10046658  fdivs f0,f1,f0         ; / K,  K = *(float*)(r2-0x6dd8 -> 0x100d73f4) = 32767.0
1004665c  fadds f1,f0,f31        ; + min
```
→ `lo == hi ? lo : min(lo,hi) + (hi − lo)·rand()/32767.0f` — closed interval [lo, hi] when
lo < hi. (Quirk: if lo > hi the result is `hi + (hi−lo)·r`, i.e. ≤ hi — not the range; replicate
as written.) [HIGH — disassembly; constants from the memory image]
⚑ corrected (review 2026-10-03) #2: this float variant was missing from the bank.
Seeding: a new game calls `srand(TickCount())`, and the same value is the film seed:
```
100057c8  bl 0x100497f0          ; FUN_100497f0 = TickCount()   -> r3
100057d0  or r20,r3,r3           ; keep it in r20 (r3 untouched)
100057d4  bl 0x10055400          ; srand(r3)
100057e8  or r6,r20,r20          ; 4th arg of
100057ec  bl 0x10009710          ; FUN_10009710(film, levelID, numPlayers, seed) -> film +4
```
Playback seeds from the film (`FUN_100069b0`) → seed = TickCount at game start. [HIGH —
disassembly of `FUN_100051a0`] ⚑ corrected (review 2026-10-03) #3 (was "[MED — srand argument inferred]").
Direct callers of `rand` (`FUN_100553e0`): **exactly two** — `FUN_10046580` (int RandomRange,
**20 callers**) and `FUN_100465e0` (float RandomRange, **4 callers**). Every game-side draw goes
through one of these. [HIGH — `find_func.py 'FUN_100553e0\(' --names` → 3 blocks incl. the
definition; `'FUN_10046580\('` → 21 incl. definition; `'FUN_100465e0\('` → 5 incl. definition]
⚑ corrected (review 2026-10-03) #1: was "37 functions call `rand` directly … [HIGH count]" — wrong.
Float-RandomRange consumers (all affect film-replay determinism, since each draw advances the one
LCG state shared with the int draws):
| caller | what is drawn | evidence |
|---|---|---|
| `FUN_10017510` (flee target) | x (or y) of the flee point: `FUN_100465e0(0.0, VisibleGameWidth)` (PermFloat 54) or `(0.0, VisibleGameHeight)` (55) for the random-axis flee modes; stored at entity `+0x11c`/`+0x120` | 12 call sites; lower bound `*(float*)(r2-0x71f8 → 0x100d6c8c)` = 0.0 |
| `FUN_10037930` (member placement at spawn) | radius in `[0.0, abs(xOffsetMax)]` when `randomiseInitialLoc` — see waves-and-enemies.md §4 | `100379b8` |
| `FUN_10037b50` (initial motion at spawn) | initial speed `FUN_100465e0(initialSpeedMin +0x26c, initialSpeedMax +0x270)` — drawn for every created entity unless entity `+0x13c` is set | `10037bbc lfs f1,0x26c(r29); lfs f2,0x270(r29); bl 0x100465e0` |
| `FUN_100475e0` (play sound from a settings block) | pitch `FUN_100465e0(block+0x10, block+0x14)` (Min/MaxPitch); skipped when the sound ID is `none` | `10047610..18` |
Note on `FUN_100475e0`: its volume is `FUN_10046580(block+4, block+4)` — **MinVolume twice**
(`lwz r3,0x4(r30); or r4,r3,r3`), so volume never varies and that call never draws; only the
pitch draw (when Min ≠ Max pitch) consumes RNG. [HIGH — disassembly]
Per created entity the order of draws is: `FUN_10037930` placement (int and/or float) →
`FUN_10037b50` speed (float) then heading tolerance (int) → state-0 timer in `FUN_100146f0`
(int) — `FUN_10035cd0` calls them in that order (dump: `FUN_10037930(param_1,iVar3);
FUN_10037b50(...); FUN_100146f0(iVar3,1,…+0x97c,…)`). A replica must keep the call order
identical for films to replay. [HIGH for the order of the three calls]
⚑ corrected (wave 1, 2026-10-03): was "placement → speed → heading tolerance → state-0 timer" as the whole per-entity
order — incomplete. Full order per member: D1 heading tolerance (int, conditional, before
placement) → `FUN_10037930` → `FUN_10037b50` (speed; tolerance only in its default-heading branch)
→ `FUN_100146f0` state 0 (timer, frame, scale tolerance, flee floats, `FUN_10017cb0` per set
rate → volley → delay) → group delay `R(groupDelayMin, groupDelayMax)` (first member included) →
`FUN_10037ed0` (cyclic, conditional); group size/appears draws in `FUN_100369f0` come first and
`FUN_10015b40` re-arms sets delay → volley → rate — see spawn-and-waves.md §3.2, §9. Further int
RandomRange consumers missing from the table above: `FUN_100269a0` draws `R(400,2000)` per in-game
player at every level start (player-physics.md §4.2); `FUN_10033850` draws the motion-blur
interval per qualifying entity per tick and `FUN_100431f0` draws `R(0,99)` twice at app init
(damage-health-death.md §1, NR 7/8; INDEX #33).
⚑ corrected (wave 2, 2026-10-03): was "`FUN_100431f0` draws `R(0,99)` twice at app init" — it makes **302** draws
(300 in `FUN_10044630`, then the two `R(0,99)`), all at app start before any `srand`, so they do
not affect replays. Add to the per-tick consumers: the particle emitter `FUN_10043340` draws one
`R(0,4)` per particle inside the logic tick (callers `FUN_10014f10`, `FUN_10016300`,
`FUN_10033850`) — replay-relevant. The motion-blur interval draw is real but every shipped blur
state has 0/0 (min == max → no draw), so it never fires with shipped data — see
particles-debris-blur.md §1, §4.4. The LOW table below is superseded by that listing walk.

Other rand consumers found by the wave-1 critic (unread, wave 2) [LOW — callers from
`$W/callers.txt` (direct calls only); bodies not listing-walked] ⚑ corrected (review wave 1,
2026-10-03): the replay-order table and the per-entity order above do **not** yet contain these,
so they are not a complete draw order:
| consumer | direct callers (`callers.txt`) | why it matters for replay |
|---|---|---|
| `FUN_10043340` particle emitter (284 lines; calls `FUN_10046580`) | `FUN_10014f10` (entity hit), `FUN_10016300` (entity destroyed), `FUN_10033850` (entity update) | in-game, per hit / kill / update; its draws interleave with the gameplay draws above |
| motion blur: the interval draw `R(state+0x2f0, state+0x2f4)` sits in `FUN_10033850` itself (per qualifying entity per tick); the blur functions `FUN_100467c0` reset, `FUN_10046840` emit, `FUN_10046a10` update, `FUN_10046ae0` draw (+ `FUN_10046ba0` `FUN_10046c70` `FUN_10046d30` `FUN_10046e20` `FUN_10046eb0` `FUN_100470f0`) do **not** call `FUN_10046580`/`FUN_100465e0` directly | `FUN_100467c0` ← `FUN_100064d0`; `FUN_10046840` ← `FUN_10033850`; `FUN_10046a10` ← `FUN_10006b50`; `FUN_10046ae0` ← `FUN_10007070`; `FUN_10046eb0` ← `FUN_10046840`; `FUN_100470f0` ← `FUN_10046a10` | the draw is per entity per tick in the entity update; indirect draws through the blur module are not excluded (jump-table/indirect calls are missed by `callers.txt`) |
| `FUN_10044630` init-time table (79 lines; two `FUN_10046580` per table entry) | `FUN_100431f0` ← `FUN_100000e0` (app boot) | runs at app start, so before the `srand(TickCount())` of a new game — matters only if the LCG state is not reseeded (it is, §9 seeding); listing not walked |
File: System Folder `Preferences` (`FindFolder(kOnSystemDisk, 'pref')`), name Pascal
"Deimos Rising Preferences" (`_DAT_100df59c`+0x5d), type `pref`, creator `Deim`
(`FUN_10048ac0`). Fallback when absent: a `pref`/`pref` tag in the pak hierarchy (`FUN_10004f80`).
Size 0x34f0 = 13552 bytes, raw memory image of the prefs struct `_DAT_100def40`. [HIGH]
| off | size | field | evidence |
|---|---|---|---|
| 0x0000 | 4 | version 0x2714 (10004); other → "Preferences Data Version Invalid" | `FUN_10004f80` |
| 0x0004+n | 1 | byte prefs n: 2 config-dialog-done, 4 display mode, 5 interlacing, 6 auto-interlacing, 8 Esc-hold, 9 FPS display, 10 FPS limiter | `FUN_10004ef0/ab0` callers |
| 0x0068+4n | 4 | int prefs n: 3 = highest sector reached | `FUN_10004f00/ac0` |
| 0x10f8 | 15×21 | high-score names, obfuscated on disk (§3 of pak-format) | `FUN_10004640/4f80` |
| 0x1233 | 2×21 | player names, default "Player %i" | `FUN_10004ae0` |
| 0x1260 | 15×4 | high scores, on disk = value + 0x024A8903 | save/load ±0x24a8903 |
| 0x129c | 15×4 | per-entry int (sector reached?), on disk = value − 0x5969FBD0 | save/load — ⚑ corrected (wave 2, 2026-10-03): was "sector reached?" — never written by the insertion; only the prefs save/load/copy routines touch it (dead) — see loose-ends-session.md §3.1 |
| 0x12d8 | 15×32 | per-entry sector name, obfuscated; default "New Atlantis" | `FUN_10004ae0` |
Fresh prefs (`FUN_10004540` when loading fails): zero the block, version 0x2714, default
high scores (`FUN_10004ae0`), then `FUN_10004f20(1)`:
```c
    *(undefined1 *)(_DAT_100def40 + 4) = 0;  ... (iVar1 + 7) = 0;      // byte prefs 0..3
    *(undefined1 *)(iVar1 + 0xc) = 0;  *(undefined1 *)(iVar1 + 0xd) = 0; // prefs 8, 9
    *(undefined1 *)(iVar1 + 0xe) = 1;                                   // pref 10 = FPS limiter ON
    *(undefined1 *)(iVar1 + 0xf) = 0;
    *(undefined4 *)(iVar1 + 0x74) = 1;                                  // int pref 3 = sector 1
```
→ out of the box the 30-fps limiter of §4 is ON. [HIGH]
Configuration dialog (`FUN_10010fc0`, M_Configuration.cc, `ModalDialog` loop): item 8 toggles
byte pref 4, item 9 pref 5 (interlacing), item 10 pref 7, item 0x11 pref 8; items 0x0c/0x0f
store slider values into int prefs 0/1 (then `FUN_10047920`, sound-related — volumes?); item
0x12 opens `ISpConfigure` (`FUN_1004ae00`); item 3 resets defaults (`FUN_10004f20(0)`). Item
labels live in the resource-fork DITL/CNTL (not parsed). [MED] ⚑ corrected (wave 2, 2026-10-03): DITL 190 is now
parsed — item 8 "Full Screen", 9 "Interlacing", 10 "Bypass System Volume", 17 "ESC Key Delay",
sliders 12/15 = Sound/Music Volume (int prefs 0/1, defaults 50/100) — see timing-frame.md §6,
sound-music.md §4.2.
Defaults (`FUN_10004ae0`): scores 15000, 14000, …, 1000 (`16000 - iVar5`, iVar5 = 1000·k);
names decoded from a 15×21 table at `0x100d61c0`: Mars, Supercobra, Neurotik, El B, Dilvish,
Sam, Vodi, Fisj, Alex, h'biki, Goldenberry, Leadfeather, Troll, Thomas, Electrofryer. [HIGH for
offsets and arithmetic; MED for byte-pref meanings (from console/caller context); the rest of
the 0x34f0 block (≈0x1000 bytes from 0x0b0, likely key/ISp config) NOT RESOLVED]
