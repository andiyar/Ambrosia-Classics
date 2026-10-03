# Bubble Trouble X 1.1 — engine loop, frame step, RNG, state machine, coordinates

Code readings of the i386 slice. "frame" = one iteration of the `_PlayGame` loop. Labels per claim.

## 1. Program flow

- `_main @ 00005586` installs an `'aevt','oapp'` handler and runs `RunApplicationEventLoop`; the
  open-app handler (`_openApplicationAEHandler @ 000066db`) loads the Sparkle and registration
  bundles (out of scope), `RT3_Open`, then runs `_InitMac` and the menu `_Interface`. [MED] (the
  tail of the handler that calls InitMac/Interface was not read line by line; both are only
  reachable from there per the caller scan).
- `_EditorRunning`: no callers — dead. ⚑ corrected (review 2026-10-03) (name added). [MED]
- `_InitMac @ 0000563c` order that matters: prefs (`_InitPrefs`, `_AlexPrefsInit`,
  `_LoadDefaultHiScores`, `_LoadGamePrefs`) → `_InitEncryption` → open the four data files (+ custom
  files from Application Support) → `_PreloadBackgrounds` → 640×480 environment rect → window,
  GWorlds → `_InitSpritePlottingTechnique` → sound → `_InitCompiledSprites`, `_InitKeys`,
  `_InitControls`, `_LoadLetters` → `_LoadSprites(0)`, `_LoadOrbitData`, `_LoadSounds`. **No RNG call
  and no `SetQDGlobalsRandomSeed` anywhere before the menu.** [HIGH] (caller scan of
  `_GetRandomFast`/`_SetQDGlobalsRandomSeed` over the disasm).
- `_Interface @ 0000b500` = main menu loop: on entry `_ResetMenuStars`, then `_Get0To6()` and
  `_Get13To22()` (latch two session constants, §3), `_CheckNumRecordings` (count FILMs). Keys:
  N/Return/Enter new game, D demo, L level select, S scores, P prefs, C credits, Q quit, R register,
  B/W sounds, X poem, Z quote. Idle: every `0x4b0` = 1200 ticks without input it alternates
  `_DemoButton` / `_ScoresButton`. [HIGH]
- `_RequestGame(level, mode) @ 0000a9a1` → `_PlayGame(level, mode)`. Callers: `_NewGameButton`
  (1, 0), level select (`_DoLevelSelect` result, 0), `_DemoButton` (filmCounter+1, 1). Afterwards: high
  score check only if `level==1 start && !cheating && mode==0`. [HIGH]
  `gGameMode`: 0 = play, 1 = demo playback, 2 = record (unreachable, data-formats.md §3). [HIGH]

## 2. Frame cadence (where "30 fps" lives)

`_PlayGame @ 00018247`, on OS X:
```
_InstallEventLoopTimer(GetMainEventLoop(), fireDelay=0.0, interval=<double 0x3fa0e560_4189374c>,
                       NewEventLoopTimerUPP(_TimerAction), 0, &gCarbonTimer)   ; disasm 00018326..00018355
_TimerAction @ 00016e3b: gTimerFired = 1
```
The interval double decodes to **0.033 s** (Python `struct.unpack('<d', …)` → `0.033`). [HIGH]
At the end of every frame the loop spins `ReceiveNextEvent(…, timeout, …)` until `gTimerFired`
(timeout `0x3f50624dd2f1a9fc` = 0.001 s while waiting), then clears it. → nominal 1/0.033 =
**30.3 frames/s**, not exactly 30; the editor read-me says "30 frames in 1 second". [HIGH] for the
constant; actual delivered rate is behaviour → unverified.
Fallback when not OS X: `do TickCount() while (< last+2)` → 30 fps (60/2); "daddy mode" (pause cheat)
uses +4 → 15 fps. [HIGH]
`gLimitFrames` (=1 at game start) can be toggled by a pause-menu cheat code → frames run unthrottled.
[HIGH] Simulation never reads wall-clock time; everything is counted in frames (`gFrameCounter`, u16). [HIGH]

## 3. RNG — `_GetRandomFast` and QuickDraw `Random`

```
_GetRandomFast(lo, hi) @ 0000c4cc:
  r = Random();                       ; QuickDraw, returns i16
  p = ((hi - lo) + 1) * (r & 0xffff); ; unsigned 32-bit product
  if (p > 0x7fffffff) p += 0xffff;    ; round-toward-zero fix for the arithmetic shift
  return (lo + (p >> 16)) & 0xffff;   ; >> is arithmetic (int)
```
[HIGH] (decompile, 6 lines). With r taken as unsigned 0..65535 the result is in [lo, hi].
`Random` is the only RNG primitive in the binary (`_Random` callers: `_GetRandomFast` only;
`_RandomSeed` is a different, RT3 helper used only by `_Useless7`). [HIGH]

QuickDraw `Random()` algorithm (Apple, not in the dump): `randSeed = randSeed * 16807 mod
(2^31 − 1)`; result = low 16 bits of the new seed as a signed i16, with −32768 mapped to 0.
⚑ corrected (review 2026-10-03): this cannot come from the binary — `_Random` is an undefined import (`nm -u`:
`_Random`, `_RandomSeed`, `_GetQDGlobalsRandomSeed`, `_SetQDGlobalsRandomSeed`; the only
`calll _Random` is 0000c4d9 inside `_GetRandomFast`). It is cited as a **documented external fact**
(Apple's QuickDraw `Random`, Inside Macintosh) at **[LOW]** — unverified on Carbon/i386. Open points
narrowed to NR-3: (a) whether Carbon's `Random` keeps the 0x8000 → 0 adjustment, (b) the
process-start `randSeed` (QD docs: 1 after `InitGraf`).

Seeding (`_PlayGame` disasm 0001839d..000184cc): [HIGH]
- mode 0 (play): `SetQDGlobalsRandomSeed(TickCount())`.
- mode 1 (demo): `SetQDGlobalsRandomSeed(FILM.seed)` (the u32 at FILM+4).
- mode 2 (record): seed = TickCount, then `FILM.seed = GetQDGlobalsRandomSeed()`.
The seed is set once per game (not per level); levels inherit the running RNG state.

Session-latched values (§ replay-oracle.md §5): `_Get0To6 @ 0000ccc9` / `_Get13To22 @ 0000ccfb`
draw `GetRandomFast(0,6)` / `GetRandomFast(13,22)` the first time they are called (static `_val`
initialised to 99 — bytes `63000000` at 0x3408c/0x34090 in `__data`) and return the same value for
the rest of the process. First callers are `_Interface` lines `_Get0To6(); _Get13To22();`. [HIGH]

Every `_GetRandomFast` call site (caller scan of `calll _GetRandomFast` in the disasm, 27 functions):

| family | function → range(s) | when | sim-relevant? |
|---|---|---|---|
| level build | `_LoadLevel` (21,50) | level ≥ 51 only | yes |
| level build | `_PositionSingleJewel` (1,14),(1,9) | per jewel | yes |
| level build | `_Bubbles_CreateRandomLUT` 33×(40,480), 21×(0,4), 21×(2,5), 13×(25,90), 21×(0,14) | every `_NewLevel` (109 draws, unconditional) | yes (order) |
| level build | `_CreateStarRandomLocLookupTable` 21×{(0,8),(0,1)} | every `_NewLevel` (42 draws) | yes (order) |
| level build | `_InitPoints` 8×(2,6) | every `_NewLevel` | yes (order) |
| level build | `_Bonus_Init` (0,100),(220,600),(450,950), per bonus (70,530),(1,14)[,(9,13)][,(lo,hi)], 21×(0,4) | every `_NewLevel` | yes |
| enemies | `_NewEnemy` (0,15),(0,10),(1,4), (0,5)×k rejection loop | each spawn | yes |
| enemies | `_ProcessEnemies` (1,30) | hatch, only on the cracked-license path | no (NR) |
| enemies | `_FigureEnemyMove` (1,r), (0,7) dummy, (1,2) tie-breaks | aligned enemy each frame | yes |
| enemies | `_MoveEnemyRandomly` 8×{(0,3),(0,3)} | random-walk branch | yes |
| hero | `_MoveHeroAligned`, `_MoveHeroNotAligned`, `_ProcessHero` (0,1) | on direction change when level ≥ `_Get13To22()` | yes |
| hero | `_ProcessHero` (0,30) | after a pop, cracked-license path only | no |
| hero | `_HeroCaught` (0,1) | sound choice on every catch/squish | yes (order) |
| blocks | `_CrushBlock` (0,40) | cracked-license path only | no |
| blocks | `_RegenerateBlocks` (1,14),(1,9) ×6, (0,1) at level ≥ 11 | regen bonus / cheat | yes |
| balloons | `_Balloons_New` (4,7); `_Balloons_CaptureAllEnemies` (4,7) per enemy | yes |
| cosmetic | `_Bubbles_New` (5,9) per air bubble | gated by bool pref 0x36 | **yes — consumes RNG** |
| cosmetic | `_NewStar` (0,1) for type-0xb stars | gated by bool pref 0x35 (except groups 0xf/0x10), 60-star cap, free slot, and the playfield clip (x 0..640, y 0..440 — exits **before** the draw; ⚑ corrected (review 2026-10-03), replay-oracle.md §4.2) | **yes** |
| cosmetic | `_DrawPointsToComp` (0,20) | per score popup per frame if `gPointsNotReg` and level ≥ 20..24 | unregistered-path trap (NR-4) |
| anti-piracy | `_PlayGame` (0,20) | end of level, only if the license code is on a 20-entry blacklist | no |
| menu | `_HandleMSMouse` (3,33), `_ProcessMenuStars` | menu only | no (game reseeds) |
| menu | `_Get0To6`, `_Get13To22` | once per process | latches |
| hiscore | `_CheckHiScore` | after game | no |
[HIGH] for the call sites and ranges (read in each function, ranges are literal args);
"sim-relevant" is the replay consequence argued in replay-oracle.md.

## 4. The frame step (`_PlayGame` loop body, in order)

```
gTimerFired = 0; gFrameCounter++                       ; u16, reset to 0 by _NewLevel
ResetNumBgndRects(); ResetNumScrnRects()
hero state machine (hero+2):                           ; see hero-and-input.md §5
  2: if frame > hero.stateStart+10 → _CheckNewEnemies()
  1: appear after 70 (first appearance) / 60 (later) frames, or end game after 95 if lives<1
  3: after 30 frames → state 4, SubtractLife, MakeAllEnemiesDisappear
  4: after 65 frames → demo/record: stop; else respawn (state 1), Multiplier_Reset
pause key → pause notice (not in demo)
if gNumNormalBlocks > 0: recount normal bubbles; if 0 → +2000 (×mult), FinishLevel
_Bubbles()           air-bubble launcher (cosmetic, RNG)
_ProcessEnemies()    AI + movement + egg timers + hero-catch test
_ProcessHero()       input sample (_CheckHeroMovement) + hero movement + push
_Splats_Process()
_Bubbles_Process()
_Balloons_Process()
_Bonus_Process()     EXTRA/multiplier animation, bonus bubbles
_ProcessBlocks()     moving bubbles, pops, eggs, dynamite, jewel anim, block-block bounces
_ProcessStars()
_ProcessPoints()
_TimeBonus_Process()
_Sounds_CheckDelayedSounds(); _EraseNotice()
draw: RestoreBgnd, HurtBlocks, Hero, Enemies, Balloons, Blocks, Splats, Bonus, Stars, Ouch,
      Points (frees expired points; RNG trap), Bubbles (frees air bubbles), _CheckForHacking,
      Score, TimeBonus, ReserveInfo, Notice, DrawRectsToScreen
escape key handling (bool pref 0x3d: hold >30 frames, else immediate quit)
end-of-level check: if !gIsEndOfLevel && hero state ∈ {1,2} && AreAllEnemiesSquished →
      gIsEndOfLevel=1, gEndOfLevelTime=frame
      if gIsEndOfLevel && state∈{1,2} && lives>0 && frame > gEndOfLevelTime+70:
          demo → stop; else EXTRA reset if animating, TimeBonus_CountDown, level>7 &&
          unregistered → nag + stop, else _NewLevel()
cmd-Q check; license parity check; pause dialog if requested
demo: if FILM.count <= gRecordingCounter → stop
wait for the 0.033 s timer
```
[HIGH] — call order read straight from the decompile (`_PlayGame` lines 365–907 of the dump block)
with addresses 00018787..00018c30 confirming sequence.

Things the order implies (all [HIGH], derived from the order above):
- Enemies move **before** the hero reads input in the same frame; blocks move **after** both.
- Draw-phase functions free slots (stars, points, air bubbles, enemies with the dead flag
  `+0x47`): `_DrawEnemiesToComp` is where a squished enemy's slot is released and
  `gNumEnemiesActive--` happens, so a replacement can spawn on the next frame's
  `_CheckNewEnemies`.
- `_TimeBonus_CountDown` (end of level) calls `_AdvanceFrameCounter` inside its loop and uses
  `_WaitFor` (TickCount); harmless because `_NewLevel` zeroes the counter. [HIGH]

## 5. Game-state machine

```
Menu (_Interface) ──N/level select──► PlayGame(mode 0) ──game over / esc / cmd-Q──► hi-score? ► Menu
       └──D or 1200-tick idle (alternating with Scores)──► PlayGame(mode 1, demo) ──► Menu
PlayGame: SetLevel(start-1); ResetHeroLives (3); ResetScore; Multiplier_Reset; EXTRA_Reset; _NewLevel
_NewLevel @ 0001735f: gIsEndOfLevel=0; gFrameCounter=0; NextLevel; LoadLevel; ResetBlocks;
   ResetHurtBlockList; TimeBonus_Reset; LoadMaze(LEVL[0]); InitHero; PositionJewels; Splats_Init;
   Bubbles_Init; Balloons_Init; InitStars; InitPoints; InitEnemies; InitEnemyAI(no-op); Bonus_Init;
   DrawMaze; notices; music
```
[HIGH]. Demo playback ends on: samples exhausted, hero death animation finished (state 4 timeout),
level completed (+70 frames), any key/mouse-down event (event kind 1 in the wait loop), app
deactivation. [HIGH]
Unregistered gate: after finishing level 7 (`GetLevel() > 7` at the transition) an unregistered
copy shows `_DoRegReminder` and ends the game. [HIGH] (registration out of scope; the replica will
behave as registered — decision recorded in INDEX).

## 6. Screen / GWorld coordinates

- Environment rect `SetRect(environment+0x12, 0,0,0x280,0x1e0)` → 640×480 logical screen. [HIGH]
- Playfield = maze 16×40 by 11×40 = **640×440 at (0,0)**; cell (c,r) → rect (top r·40, left c·40,
  +40, +40). Clip in `_RestoreBgndRect`/`_NewStar`/`_Bubbles_DrawToComp`: x 0..640, y 0..440 (0x1b8). [HIGH]
- Score bar band y 446..476 (0x1be..0x1dc): score digits from x 132 (0x84, 24 px per digit), EXTRA
  letters at x 322/338/359/381/403, time bonus at x 480 (23 px digits, +22 when <10000), multiplier
  at x 601, reserve-hero icon 16..48 / count 55..77. [HIGH] (literal SetRect/SpriteToComp args in
  `_DrawScore`, `_EXTRA_Draw`, `_TimeBonus_Draw`, `_Multiplier_Draw`, `_InitHero`).
- GWorlds: comp (composite, all sprites drawn here), bgnd (background PICT + static maze bubbles?
  — `_DrawMaze` draws the PICT into bgnd and comp, and maze bubbles into comp), sprite, score, trans.
  Dirty-rect lists (`_AddRectToBgnd` restore, `_AddRectToScreen` blit). On OS X every sprite is a
  `cicn` plotted with QuickDraw (data-formats.md §4). [MED] (pipeline skimmed, only enough to fix
  coordinates).
- Sprite positions are the top-left of the 40×40 cell rect for hero/enemies/blocks (`SpriteToComp(0,
  left, top, set, frame)`). [HIGH]
