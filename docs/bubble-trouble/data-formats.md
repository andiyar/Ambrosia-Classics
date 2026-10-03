# Bubble Trouble X 1.1 — data formats (code readings + worked decodes)

Scope: every record the game reads from its shipped `.rsrc` files and the prefs file it writes.
All `xxd` decodes below were run in this session on resources extracted with a Python resource-map
parser (`scratchpad/bt/rsrc.py`: 16-byte header → map → type list → ref list, as the brief describes;
extracted payloads written to `scratchpad/bt/res/<TYPE>_<id>.bin`). ⚑ corrected (review 2026-10-03): the parser is
now checked in as `docs/bubble-trouble/tools/rsrc_census.py`; `--extract res FILE.rsrc` writes the same
`res/<TYPE>_<id>.bin` payloads (a space in the type becomes `_`, e.g. `snd__9000.bin`). Paths:
`R=…/BubbleTroubleX_1.1_UB/Bubble Trouble X.app/Contents/Resources`.

Byte order. The `.rsrc` files are big-endian (classic Mac). The i386 build installs CoreEndian
flippers for exactly five types (`_BTInstallEndianFlippers @ 00028366`):
`SpIL`, `SpIc`, `LEVL`, `Rect`, `FILM`. Every other type is handed to the code raw. [HIGH] — read
directly: five `_CoreEndianInstallFlipper(0x72737263 'rsrc', <type>, <flipper>)` calls, types
`0x5370494c 'SpIL'`, `0x53704963 'SpIc'`, `0x4c45564c 'LEVL'`, `0x52656374 'Rect'`, `0x46494c4d 'FILM'`.

---------------------------------------------------------------------------------------------------
## 1. `MAZE` — 176 bytes = 16 × 11 cells  (BT Levels.rsrc, ids 1..50)

Reader: `_LoadMaze @ 0002626e` — zeroes `gMaze` and `gMazeCopy` (16×11), then
`_memmove(gMaze, *h, 0xb0); _memmove(gMazeCopy, *h, 0xb0)`. [HIGH]

| offset | size | meaning |
|---|---|---|
| `col + 16*row` | u8 | cell code, col 0..15, row 0..10 (row-major, row 0 = top) [HIGH] (index form `gMaze[col + row*0x10]` in `_GetNextObject @ 00025f34`, `_NormalBlockCount`, `_DrawMaze`) |

Cell codes (meaning from the code that writes/tests them):

| code | meaning | evidence |
|---|---|---|
| 0 | empty water | hero/enemy may enter (`_MoveHeroAligned`, `_CheckUp`) [HIGH] |
| 10 `0x0a` | normal bubble | sprite set 0x11 in `_DrawMaze`; counted by `_NormalBlockCount` [HIGH] |
| 15 `0x0f` | blue bubble, bounces once | sprite 0x14; `_MoveBlock` bounce limit `count>1` [HIGH] |
| 16 `0x10` | purple bubble, bounces twice | sprite 0x15; bounce limit `count>2` [HIGH] |
| 20 `0x14` | jewel (runtime only — placed by `_PositionSingleJewel`) | sprite 0x16 [HIGH] |
| 30 `0x1e` | joined-jewel cluster (runtime) | sprite 0x17; `_CheckJewelMovement` [HIGH] |
| 40 `0x28` | bubble currently popping (runtime, 8 frames) | `_CrushBlock` writes 0x28; `_ProcessBlocks` clears to 0 after frame>8 [HIGH] |
| 50 `0x32` | "wall" — never stored; returned by `_GetNextObject`/`_GetDistantObject` off-grid | [HIGH] |
| 52 `0x34` | dynamite (1 stick below level 12, 2 sticks from 12) | sprite 0x12/0x13 chosen by `GetCurrLevelNum() < 0xc` in `_DrawMaze` [HIGH] |
| 60 `0x3c` | bubble holding an enemy egg (runtime) | `_NewEnemy` writes 0x3c [HIGH] |
| 70 `'F'`, 80 `'P'` | tested as "passable" by hero/enemy code but **never written to the maze**; they are balloon capture-kind tags (`_Balloons_CaptureHero` writes 0x46, `_Balloons_CheckBalloonEnemyHit` writes 0x50 into balloon+0x22) | [HIGH] for "never written to maze" — grep of every `gMaze[...] =` site in the dump (12 sites) and of `movb $0x46/$0x50` in disasm |

Census of shipped mazes (command: Python over `res/MAZE_1..50.bin`, `Counter` of bytes):
`[(0, 4747), (10, 3692), (15, 169), (16, 115), (52, 77)]` — only codes 0/10/15/16/52 occur in data. [HIGH]

Worked decode — `xxd res/MAZE_1.bin` (first two rows):
```
00000000: 0a00 0000 0a00 0a0a 0a0a 000a 0a0a 000a   row 0: B . . . B . B B B B . B B B . B
00000010: 0a00 0a00 0a00 0a00 0000 0000 000a 000a   row 1: B . B . B . B . . . . . . B . B
```
(B = 10 normal bubble). Cell (7,6) = byte 0x67 = `00` → hero starts at the default (7,6) on level 1
(see hero-and-input.md §1).

---------------------------------------------------------------------------------------------------
## 2. `LEVL` — 64 bytes = 32 big-endian i16 (BT Levels.rsrc, ids 1..50)

Flipper `_FlipLEVL @ 000284b9` byte-swaps every 16-bit word → the record is 32 × i16. [HIGH]
Reader `_LoadLevel @ 00002ef7` copies into the global `level` struct (same offsets), with clamps.

| word | byte off | `level`+ | meaning | evidence / label |
|---|---|---|---|---|
| 0 | 0x00 | +0x00 | MAZE resource id to load | `_NewLevel`: `_LoadMaze(*(short*)level)` [HIGH] |
| 1 | 0x02 | +0x02 | background PICT id | `_DrawMaze`: `_DrawAndCentrePict(level+2)` [HIGH] |
| 2 | 0x04 | +0x04 | music set 1..4 → `'snd '` named "Level set N music.1" | `_LoadMusic` `NumToString(level+4)` [HIGH] |
| 3 | 0x06 | +0x06 | frame index for redrawn bubble ("hurt block") | `_NewHurtBlock` (via `_CheckBlock` dirty-rect redraw — ⚑ corrected (review 2026-10-03)) [MED] (draw-only) |
| 4 | 0x08 | +0x08 | same, for jewel cells | `_NewHurtBlock` [MED] |
| 5 | 0x0a | +0x0a | unused by game (copied only) | access scan of disasm (§9) [MED] |
| 6 | 0x0c | +0x0c | total enemies on level; clamped to ≤30 | `if (w6 < 0x1f) … else 0x1e` [HIGH]; `_AreAllEnemiesSquished` |
| 7 | 0x0e | +0x0e | max enemies active at once | `_CheckNewEnemies` [HIGH] |
| 8 | 0x10 | +0x10 | egg time (frames the egg bubble flashes) | `_ProcessBlocks` egg; `_ProcessEnemies` state 3 [HIGH]; editor read-me "Egg time" |
| 9 | 0x12 | +0x12 | unused | [MED] |
| 10 | 0x14 | +0x14 | delay before the egg starts (enemy state 2 → 3) | `_ProcessEnemies` case 2 [HIGH] |
| 11 | 0x16 | +0x16 | unused | [MED] |
| 12 | 0x18 | +0x18 | jewel count, clamped to 3..4 | `if (w12 < 3) 3; if (>4) 4` [HIGH] |
| 13,14 | 0x1a,0x1c | | unused | [MED] |
| 15 | 0x1e | +0x1e | balloon starts flashing after N frames | `_Balloons_Process` [HIGH] |
| 16 | 0x20 | +0x20 | balloon releases its enemy after N frames | `_Balloons_Process` [HIGH] |
| 17 | 0x22 | +0x22 | value 300 on every level; never read as a field (only as array base `level+0x22+type*2`) | [MED]; editor "Balloon time" mapping NOT RESOLVED (NR-8) |
| 18..23 | 0x24..0x2e | +0x24..+0x2e | enemy pool per type 1..6 (1 piranha, 2 eel, 3 shark, 4 starfish, 5/6 unused) | `_NewEnemy` draws `GetRandomFast(0,5)` index, decrements; `_LoadLevel` checks Σ w18..23 == w6 else `_LocationError(0x7de,1)` [HIGH] |
| 24..31 | 0x30..0x3e | | copied as 4 × u32, never read | [MED] |

Note the pool words are **mutated at run time** (decremented on spawn, re-incremented by
`_MakeAllEnemiesDisappear`, starfish added by `_CheckJewelMovement`) — the in-memory `level` is a
working copy reloaded each `_NewLevel`. [HIGH]

Worked decode — `xxd res/LEVL_1.bin`:
```
00000000: 0001 0390 0001 0001 0001 0001 0004 0002   maze 1, PICT 912, music 1, 1,1,1, total 4, max 2
00000010: 0032 0002 000a 0014 0003 000a 0014 008c   egg 50, -, pre-egg 10, -, jewels 3, -, -, flash 140
00000020: 00aa 012c 0004 0000 0000 0000 0000 0000   release 170, 300, pool: piranha 4, eel 0, …
00000030: 0000 0000 0000 0000 0000 0000 0000 0000
```
All 50 records tabulated (Python `struct.unpack('>32h')`) in this session: total runs 4..12, max 2..7,
jewels 3 (levels 1–12) / 4 (13–50). Level 3 is the
first with eels (pool 2/4), level 6 first with sharks, level 12 first with starfish. [HIGH]
⚑ corrected (review 2026-10-03): flash/release (w15/w16) step down per level, not one jump at L16 —
140/170 (L1), 130/160 (L2), 120/150 (L3), 110/140 (L4–12), 100/130 (L13–15), 90/120 (L16–50). [HIGH]

Level numbers above 50: `_LoadLevel` replaces any level ≥ 51 with `GetRandomFast(0x15,0x32)` (21..50);
≥ 100 also `SetCurrLevelNum(99)`. [HIGH] (RNG consumer — see replay-oracle.md.)

---------------------------------------------------------------------------------------------------
## 3. `FILM` — demo recording, 10012 bytes (BT Levels.rsrc, ids 1..4)

In-memory image `gRecording @ 0x34f40` (nm), size `0x271c` (10012); `_PlayGame` copies the resource
over it with `_memmove(&_gRecording, *h, 0x271c)` (resizing the handle to 0x271c first). Flipper
`_FlipFILM @ 000284e3` swaps only the first three u32 and only when the size is 0x271c. Field
addresses from `_SetPlayRecordCount`, `_Get*Recording`/`_Set*Recording` (each indexes a 2000-byte
array by `gRecordingCounter`) and `_PlayGame` (seed at `0x34f44`, level at `0x34f48`). [HIGH]

| off | size | name | meaning |
|---|---|---|---|
| 0 | u32 BE | count | number of recorded input samples; playback ends when `count <= gRecordingCounter` (checked after each frame's update) |
| 4 | u32 BE | seed | QuickDraw `randSeed` installed by `SetQDGlobalsRandomSeed` before the level is built |
| 8 | u32 BE | level | written at record time as `GetLevel()` **before** the start level is set (i.e. stale); never read on playback [HIGH for "never read" — only 3 disasm refs to 0x34f44/0x34f48, all in `_PlayGame` record/seed paths] |
| 12 | 2000 × u8 | up[] | nonzero = Up held on sample i |
| 2012 | 2000 × u8 | down[] | |
| 4012 | 2000 × u8 | left[] | |
| 6012 | 2000 × u8 | right[] | |
| 8012 | 2000 × u8 | push[] | |

Capacity: `_RecordingCountOK` = `gRecordingCounter < 2000` → at most 2000 samples. [HIGH]
**One sample = one call of `_CheckHeroMovement`**, not one frame (replay-oracle.md §2). [HIGH]

Census (Python over the 4 FILMs, this session):
```
1 'The basics'     count 1118 seed 0x4642a0 level-field 0x00020000
2 'Multiplier fun' count  846 seed 0x45f1f8 level-field 0x00020000
3 'Eel appeal'     count  943 seed 0x461498 level-field 0x00030000
4 'Lucky boy'      count  890 seed 0x4621ef level-field 0x00040000
```
Every array byte is 0 or 1; bytes beyond `count` are nonzero leftovers from earlier recordings (the
buffer is never cleared — only `gRecording=0` is reset), e.g. FILM 1 has 89/100/90/92/1 nonzero
up/down/left/right/push bytes past index 1118. [HIGH]
⚑ corrected (review 2026-10-03) — evidence: the **last nonzero index is identical across all four films**
(down 1976, left 1919, right 1964), i.e. all four share one earlier recording's residue, which
corroborates "buffer never cleared". [HIGH]

Worked decode — `xxd -l 16 res/FILM_1.bin; xxd -s 12 -l 64 res/FILM_1.bin`:
```
00000000: 0000 045e 0046 42a0 0002 0000 0000 0000   count 0x45e=1118, seed 0x004642a0, level-field
0000000c: 0000 …                                    up[0..]
0000003a:                                0101 …     up[46] = 1  (offset 0x3a-12 = 46)
```
Run-length of the first samples (`U D L R P`, '.' = not held): `..... ×16, ...R. ×25, ..... ×5,
U.... ×37, ..... ×8, ..L.. ×7, …`; first push at sample 212. [HIGH]

Which level a film plays: the film **id**, not the level field. `_DemoButton` calls
`_RequestGame(filmCounter+1, 1)`; `_PlayGame` loads `FILM id = gFilmCounter+1` and `_SetLevel(param-1)`;
`_NewLevel` then `_NextLevel()` → level = film id. Film ids 1..4 → levels 1..4; `gFilmCounter` cycles
mod `gNumFilmsAvailable` (counted at menu entry by `_CheckNumRecordings`: probe ids 1,2,… until
`GetResource` fails). [HIGH] Level 3 being the first eel level matches the title "Eel appeal". [LOW]
(corroboration only). The level field's u16 reading (2,2,3,4) does not match ids 1,2 →
meaning NOT RESOLVED (NR-1).

Writer (dev-only): with `gGameMode==2`, `_CheckHeroMovement` stores the five flags and bumps the count;
at game end `_PlayGame` replaces `FILM id = GetLevel()` (`AddResource(h,'FILM',level,"\pFILM RECORDING")`).
No call path sets `gGameMode` to 2: `_RequestGame` is only called with mode 0 (`_NewGameButton`,
level-select) or 1 (`_DemoButton`). [HIGH] — record mode unreachable in the shipped build.

---------------------------------------------------------------------------------------------------
## 4. Sprites: `SpIL` / `SpIc` / `cicn` / `btSP` (BT Sprites.rsrc)

The file's two `TMPL`s describe **SpIc and SpIL**, not btSP (the brief's hypothesis corrected):
```
TMPL 25000 'SpIc': 'Sprite count' ZCNT, LSTC, 'Starting ID' DWRD, 'Frame count' DWRD, LSTE
TMPL 25001 'SpIL': "'SpIc' count" ZCNT, LSTC, "'SpIc' ID" DWRD, LSTE
```
No TMPL for btSP exists in any game file or in `BT Level Editor.rsrc` (type census of the editor
rsrc in INDEX.md). [HIGH]

`SpIL 128` (`xxd`: `0000 03e8`): ZCNT 0 → 1 entry, SpIc id 1000. `_InitCompiledSprites @ 00015784`
reads `SpIL 128`, then each listed `SpIc`. [HIGH]

`SpIc 1000` "Level independent sprites" (210 B): i16 count-1 (0x33 → 52 sets), then 52 ×
{i16 startID, i16 frameCount}. `xxd -l 32 res/SpIc_1000.bin`:
```
0033 61a8 0004 620c 0008 6270 0008 62d4 0008 6338 0008 639c 0004 6400 0010 6590
 52  25000  4  25100  8  25200  8  25300  8  25400  8  25500  4  25600 16  26000 …
```
Sprite addressing: `_SpriteToComp(set=0, x, y, s, f)` plots frame `f` (1-based) of SpIc entry `s-1`,
i.e. resource id `start[s-1] + f-1`. [HIGH] (`CSData[set][(s-1)]` offset table + `f-1`).
Decoded set table (s → start,count → use as read in code):
1 (25000,4) hero idle · 2–5 (25100..25400, 8 each) hero up/down/left/right walk · 6 (25500,4) push ·
7 (25600,16) death · 0x11 (27000,1) bubble · 0x12/0x13 (27020/27030,3) dynamite small/large ·
0x14/0x15 (27050/27060, 9) blue/purple bounce frames · 0x16 (27100,1) jewel · 0x17 (27150,4) joined jewel ·
0x18 (27300,9) pop · 0x19 (27350,3) bonus-bubble shell · 0x1a (27400,21) bonus icons · 0x1b (28000,12)
piranha · 0x1c (28100,20) eel · 0x1d (28200,12) shark · 0x1e (28300,7) starfish · 0x1f (28500,4) egg
(frame = enemy type) · 0x21/0x22 (30000/30500,10) digits normal/flash · 0x23 (30600,4) multiplier ·
0x24/0x25 (30700/30750,5) EXTRA lit/unlit · 0x26/0x27 splats · 0x28–0x2c stars · 0x2d–0x30 air
bubbles · 0x31–0x33 balloon fly/hold/pop · 0x34 (31700,24) score popups. [HIGH] for the arithmetic;
[MED] for the use labels (taken from the call sites that pass each set number).

Which pixels are used on Intel: `_InitSpritePlottingTechnique @ 00014ab5` sets
`gUsePlotIcon = (shortPref 0x39 == 1)`, then forces it true when `_IsDoubleBuffered()`, and
`_IsDoubleBuffered @ 0000cb5f` simply returns `_IsOSX()`. On OS X every sprite is therefore a
`cicn` (`_LoadIcon` → `GetCIcon(id)`, plotted with `_ASWPlotCIcon`/`PlotCIconHandle`). [HIGH]
Counts: 331 `cicn`, 325 `btSP`; cicn ids with no btSP twin: 25004, 25108, 25208, 25308, 25408, 25504. [HIGH]

`btSP` (classic compiled-sprite path, `_LoadSpriteDataRes @ 00014b63` + `_BlastIt @ 0000298d` /
`_BlastItTransparent @ 000027aa`): one frame per resource, 8-bit pixels.

| off | size | meaning |
|---|---|---|
| 0 | i16 | row width in bytes (dest increment = rowBytes − this) [HIGH] |
| 2 | i16 | unused by the plotter (25000 → 8, 25001 → 101) — NOT RESOLVED (NR-2) |
| 4.. | u32 ops | op = top byte, n = low 24 bits: **1** copy n literal bytes then pad to 4; **2** skip n dest bytes; **3** next row; **4** end [HIGH] |

Worked decode — `xxd -l 64 res/btSP_25000.bin`:
```
0028 0008 | 02000028 (skip 40) 03000000 (row) 02000028 03000000 0200000b (skip 11)
01000006 db41 4165 8fe0 0000 (copy 6 + pad 2) 02000006 01000006 b365 4141 dbdf 0000 …
```
Full walk (Python, this session): 40 row ops, one end op → 40×40 frame. [HIGH]
The ops are stored big-endian but `_BlastIt` reads them as native u32 and no btSP flipper exists;
on i386 this path would mis-decode — consistent with it being bypassed on OS X. [MED] (inference
from the missing flipper + forced cicn path).

`cicn` worked decode (`xxd -l 96 res/cicn_25000.bin`): standard Color QuickDraw `cicn`
(PixMap rowBytes 0x8028, bounds 0,0,40,40, 8-bit, then mask/bitmap/CTab/data). [HIGH] (format is
Apple's; the game only calls `GetCIcon`).

⚑ corrected (plan 2026-10-03 hectorkit-btx-decoders, Task 7) — evidence: `data-census.md` §2 (HectorKit `CIcon` over every
cicn) and a Python re-check of the mask bits, colour tables and pixel values over the
`tools/rsrc_census.py --extract` payloads at append time:
- Not every sprite is 8-bit. The 331 `cicn` are **8-bit 217 · 4-bit 83 · 1-bit 20 · 2-bit 11** (sizes
  18×18 … 64×64; size × depth table in `data-census.md` §2). [HIGH]
- **7 cicns are all-transparent blanks** (mask all zero): the six with no btSP twin (25004, 25108, 25208,
  25308, 25408, 25504) and **27308**. [HIGH]
- The colour tables are **value-indexed** (ctFlags 0x0000): in 227 of 331 the pixel values reach past the
  entry count, and every one of those 227 tables is entries 0…n−2 at values 0…n−2 plus a final black entry
  whose value is 2^d−1 (d = pixel depth). Position indexing would read past the table; `CIcon` looks entries
  up by `value`. [HIGH]

---------------------------------------------------------------------------------------------------
## 5. Orbit table `SPIN 1` (240 B) and checksum tables `DARK 129` / `SPIN 2` (Bubble Trouble X.rsrc)

`_LoadOrbitData @ 000031a6`: `memmove(gOrbit_Table, *GetResource('SPIN',1), size)`. Consumer
`_ProcessStars` type-2 stars: `y = table[idx*4]`, `x = table[idx*4+2]` (i16), idx += 2, wraps 60→2.
→ 60 entries × {i16 dy, i16 dx}. [HIGH]
`xxd -l 48 res/SPIN_1.bin` → BE `(37,30) (40,26) (42,21) (44,17) (46,12) (47,7) (48,2) (48,-2) …`
— a radius-48 circle. Read raw on i386 (no flipper) it becomes `(9472,7680) …`. [HIGH] for the
bytes; the consequence (orbit stars land off-screen and are not drawn on Intel) [MED].
⚑ corrected (review 2026-10-03): the bug is real but **invisible in play, demo and FILM replay**. Motion
type 2 (orbit) is created only by `_NewStarGroup(…, 10)` (`_NewStar(x,y,2,0,2,idx)`), and the only
caller passing 10 is `_PauseGame @ 0001767b` — the pause-screen cheat hash `0x211e290`, "star burst"
(`_NewStarGroup(hero.col*40, hero.row*40, 10)`). Group 0 (hero appear) uses motion type 0; group 2
(jewel bonus, bonus pop) uses types 3–9. `gOrbit_Table` has exactly two references
(`_LoadOrbitData`, `_ProcessStars` case 2); `_DrawStarsToComp @ 00004de0` clips rects outside
0..640/0..440, so the LE-read stars are simply not drawn. No longer a decision for Ben (INDEX note). [HIGH]

Level checksums (anti-tamper, dead): `_CheckLevel`/`_CheckMaze` compare Σ u16 words of the
LEVL/MAZE handle with `DARK 129` i32 at `(id-1)*4` / `0xc4+id*4`; `_OtherLevCheck`/`_OtherMazeCheck`
compare Σ i·word_i with `SPIN 2` at the same offsets. Verified against the data this session: all
50 LEVL and 50 MAZE match **as big-endian** (`{'levBE':50,'mazBE':50,'s2levBE':50,'s2mazBE':50}`, LE: 0).
Results land in `gLevelsOkay`/`gCopyLevelsOkay`, whose readers `_LevelsOkay`/`_CopyLevelsOkay`
have no callers in the dump. [HIGH] (caller scan) → irrelevant to the replica beyond "custom levels load".

---------------------------------------------------------------------------------------------------
## 6. Sounds `'snd '` (BT Sounds.rsrc 51, app rsrc 1)

`_LoadSounds @ 00026a20` loads ids 9000..9047 (`while id != 0x2358`) via `ST_LoadSndResource`;
`_PlayMySnd(n, prio, delay) @ 00026a7b` plays slot n = id 9000+n, or queues it `delay` frames ahead
(5 queue slots, flushed by `_Sounds_CheckDelayedSounds`); volume from shortPref 0x33 (2→0x10,
3→0x40, 4→0x100, other → silent). [HIGH] 9047 lives in `Bubble Trouble X.rsrc`.
Decoded headers (Python, this session): 9000–9045 format-1 standard 8-bit 22050 Hz, 9046 11127 Hz;
music 11001–11004 named "Level set N music.1", compressed `ima4` @ 22255 Hz. [HIGH]
Worked decode `xxd -l 64 res/snd_9000.bin`: `0001 0001 0005 0000 0080 0001 8051 0000 0000 0014 …`
→ format 1, 1 modifier (sampledSynth 5), 1 command bufferCmd (0x8051) offset 0x14; header at 0x14:
length 0x1f26 = 7974 B, rate 0x56220000 = 22050 Hz, encode 0. [HIGH]
Music: `_LoadMusic(1)` builds "Level set " + LEVL word 2 + " music" + ".1" and `GetNamedResource`;
title music (`LoadMusic(0)`) is mapped to "Level set 3 music". [HIGH]

⚑ corrected (plan 2026-10-03 hectorkit-btx-decoders, Task 7) — evidence: `data-census.md` §5 (HectorKit `SndSound` over all 52)
and a Python re-read of each sound header's Fixed rate / encode / numChannels at append time:
- Music 11001–11004 plays at **22254.545 Hz** (Fixed 0x56EE8BA3), not "22255 Hz", and is **stereo**
  (cmpSH numChannels 2, codec 'ima4'; packets 24,032 · 19,168 · 21,924 · 26,064). [HIGH]
- **9047** "Squeak squeak" (app rsrc) is standard 8-bit PCM at the same **22254.545 Hz** (0x56EE8BA3),
  11,498 frames. 9046's exact rate is **11127.273 Hz** (0x2B7745D1). [HIGH]
- HectorKit's `SndSound.sampleRateHz` truncates the Fixed rate (22254, 11127 — ≤ 0.0025 % pitch); the exact
  fraction is deferred to the BTX audio plan (HectorKit decoder plan, Scope). [HIGH]

---------------------------------------------------------------------------------------------------
## 7. Pictures, rects, cursors

PICT: `_DrawMaze` draws `PICT <LEVL word 1>` centred (`_DrawAndCentrePict` → `GetPicture`, centred
in the 640×480 environment rect) into both the background and composite GWorlds. [HIGH] Ids used
by LEVL: 912 (in `Bubble Trouble X.rsrc`, 457,926 B, unnamed) and 13000–13005 (`BT Levels.rsrc`).
The same ids also exist as `ppat` in BT Levels ("Main Menu Pattern" 912, "Waves Dark" 13000, …) —
`GetPicture` asks for type PICT only, so the ppats are not what the level shows. [HIGH] (type is
fixed at the call). Titles 9001–9100 (BT Titles.rsrc); menu `PICT 0x238c` (9100) buttons and
`0x2332` (9010) title in `_Interface`; splash `PICT 200`, `0x2333` in `_InitMac`. [HIGH]
`Rect` 1..7 (flipped): main-menu button hot rects, QuickDraw order top,left,bottom,right.
`xxd res/Rect_1.bin` → `00a5 00e4 013b 0106` = "Interface - New Button" (165,228,315,262). [HIGH]

⚑ corrected (plan 2026-10-03 hectorkit-btx-decoders, Task 7) — evidence: `data-census.md` §3–§4 (HectorKit `PICT`,
`PICT.decodeQuickTime`, `PixelPattern`) and a Python opcode walk over every PICT and ppat payload at append time:
- The 28 PICTs (Levels 6, Titles 7, app 15) take **four shapes**: raw 11 — PackBitsRect 0x0098 (900, 998,
  999, 8001, 9100) and DirectBitsRect 0x009A (200, 912, 913, 9010, 9011, 9099) · banded QuickTime JPEG
  0x8200, 8 (13000–13005, 29401, 29402) · **0x0099 PackBitsRgn**, 4 (9001, 9002, 9012, 9020: 8-bit pixels cut
  out by a QuickDraw region) · **0x8201 uncompressed QuickTime with a QuickTime 'rle ' 8-bit matte**, 5 (2910,
  7000, 9030, 9031, 9077). The two masked shapes are not decoded by the kit yet (HectorKit decoder plan Tasks
  4a/4b); the census lists them as named deferrals. [HIGH] for the opcode streams.
- PICT 200 (32-bit DirectBits, cmpCount 4) stores an **all-zero alpha plane** (102,300 of 102,300 pixels).
  [HIGH] for the bytes; that the original draws it opaque (QuickDraw ignores the high byte of a 32-bit pixel)
  is [MED] — Ben's eyes on the splash close it.
- The 7 `ppat` (912, 13000–13005) are all patType 1, 256×256 8-bit, PixMap rowBytes 0x8110 = **272** (16
  junk bytes per row past the 256-pixel width — never image), pmVersion 1, colour table **ctFlags 0x8000**
  (device-relative: looked up by position), 256 entries, offsets patMap 28 / patData 78 / pmTable 69,710. [HIGH]

---------------------------------------------------------------------------------------------------
## 8. High scores: `SCOR 128` (138 B) and its copy in the prefs file

Reader `_LoadDefaultHiScores @ 000249d4` (copy ≤ 0x8a bytes, then `_SwapHighScoresFromBigEndian`:
7 × u32 at +0x60, 7 × u16 at +0x7c). Layout from `_CheckHiScore @ 00024b34` / `_DrawSingleHiScore
@ 0002553a` (`name = +0x0c + i*0x0c`, `score = +0x60 + i*4`, `level = +0x7c + i*2`). [HIGH]

| off | size | meaning |
|---|---|---|
| 0x00 | 12 | Pascal string: default name offered in the entry dialog (`SetDialogString(dlg,2,highScores)`) |
| 0x0c + 12i | 12 ×7 | Pascal names, entries i=0..6 (0 = best) |
| 0x60 + 4i | u32 BE ×7 | scores |
| 0x7c + 2i | u16 BE ×7 | level reached |

`xxd res/SCOR_128.bin`: slot0 "The Fonz"; entries Potsie 4500/L4, Ralph 1000/L3, Ritchie 500/L2,
Mr Kotter 500/L1, Horshack 500/L1, Mr Peabody 500/L1, Sherman 500/L1. [HIGH] (layout) — the guide
has no high-score text to cross-check.

## 9. Prefs file (data fork, "Bubble Trouble X Prefs" in the Preferences folder)

No user prefs file ships, so there is no worked decode; layout from code only.
`_SaveGamePrefs @ 00026b36` writes 0x800 bytes of `gPrefsData` then the 0x8a high-score block
(big-endian, swapped around the write); `_LoadGamePrefs @ 00027306` reads 0x800, and if
`version == 0x17` reads the 0x8a block, else deletes the file and re-inits. Creator 'Bubb', type 'pref'. [HIGH]

| off | size | field | accessor |
|---|---|---|---|
| 0x000 | u16 BE | version = 0x17 (23) | `_GetPrefsVersion` |
| 0x002 + (n−1) | u8 ×100 | boolean pref n=1..100 (byte at n+1) | `_GetBooleanPref` |
| 0x066 + 2(n−1) | i16 BE ×100 | short pref n | `_GetShortPref` (`n+0x65+(n-1)`) |
| 0x12e + 4(n−1) | i32 BE ×100 | long pref n | `_GetLongPref` |
| 0x2be + 22(n−1) | 22 ×20 | key set n: 12-byte C name, then i16 BE left,right,up,down,push (Mac virtual key codes) | `_GetKeySetPref`, `_InitControls` order |
| 0x476 + 40(n−1) | 40 ×10 | legacy score list: C name (30) + C decimal score at +0x1e | `_SetHighScore` (only `_ZeroPrefs` fills it) |
| 0x800 | 0x8a | high-score block, layout §8 | |

Prefs that matter to the simulation (defaults from `_AlexPrefsGameInit`/`_AlexPrefsKeysInit`): [HIGH]
- bool 0x35 = 1 "stars" — gates `_NewStarGroup` (RNG consumer, replay-oracle.md §4)
- bool 0x36 = 1 "air bubbles" — gates `_Bubbles`, `_Bubbles_NewGroup` (RNG consumer)
- bool 0x3d = 0 — when set, Escape must be held >30 frames to quit
- short 0x38 = 1 current key set; set 1 "Default" = 0x7b/0x7c/0x7e/0x7d/0x31 (←/→/↑/↓/space)
- short 0x3a = 10 (init) highest level offered by level select; `_LoadLevel` raises it to any level
  reached if `< 31`. Long pref and bool 0x3e (byte 0x3f) "default scores loaded" are bookkeeping.

## 10. Other app resources (identified, not needed by the simulation)
`Bubb 0` copyright string; `STR# 129` required files ("BT Sounds","BT Titles","BT Sprites","BT
Levels","Bubble Trouble X Prefs","BT Contest"); `STR# 136` optional custom files ("BT Custom
Levels/Sprites/Sounds", opened from ~/Library/Application Support/Bubble Trouble X by `_InitMac`;
a custom file counts if it holds any LEVL or MAZE 1). `DARK 128` "System Shadow", `SPIN 2`, `ppat`,
`IMAG`, `TMPL 128 'Rect'`. [HIGH] for names (decoded this session).
