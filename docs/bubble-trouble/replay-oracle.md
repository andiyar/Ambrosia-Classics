# Bubble Trouble X 1.1 — deterministic FILM replay: what the code requires

Goal: replay `FILM 1..4` (or any future recording) in the replica and land on the same state as the
original, frame for frame. Everything here is a code reading; nothing has been run.

## 1. Determinism inventory (why replay is possible at all)

- One RNG, QuickDraw `Random()` via `_GetRandomFast`, seeded once per game from the FILM seed.
  engine-loop.md §3. [HIGH]
- No floating point in the simulation: the only functions touching FLOAT_/DOUBLE_ are `_InitMac`,
  `_UpdateProgress`, `_ASWPlotCIconHandle`, `_PauseGame`, `_PlayGame` (mouse warp + timer interval),
  `_ClockMakeWideSeconds` (find_func scan this session). [HIGH]
- Time is counted in frames (`gFrameCounter`, u16, zeroed per level). Wall-clock reads inside game
  logic (all call sites, caller scan of the disasm):
  - `_TickCount`: `_PlayGame` (seed in mode 0 — overwritten by the FILM seed in demo; frame pacing;
    FPS display), `_PauseGame`, `_WaitFor` (used by `_TimeBonus_CountDown`, `_Multiplier_Flash` —
    pure delays), menu/credits/cursor functions. **None feeds simulation state.** [HIGH]
  - `_Microseconds`: only `_StartTimeCheck/_UpdateTimeCheck/_FinishTimeCheck` — no callers. [HIGH]
  - `_GetTime`/`_DateToSeconds`: `_Interface_GetOccasions` (menu text), `_DoBirthdaysCheck` (startup
    dialog), `_IsExpiryDateOk` (no callers). [HIGH]
  - `_TimerGetSeconds`: `_InitMac`, `_ProcessEnemies` (hatch), `_MakeAllEnemiesDisappear` — results
    discarded (anti-crack noise). [HIGH]
- Input is sampled at exactly one place, `_CheckHeroMovement`. [HIGH]

## 2. The input stream

- A FILM sample is consumed by each call of `_CheckHeroMovement`, which happens inside `_ProcessHero`
  **only** when: hero state == 2, not in the push/pop freeze (`hero+0x40`), not balloon-trapped
  (`hero+0x4c`). Frames in states 1/3/4, push freezes and traps consume **no** sample. [HIGH]
  ⚑ corrected (review 2026-10-03): the balloon-release frame consumes none either — on the first frame where
  `frame > hero+0x4e + 90` holds, `_ProcessHero` does `+0x4c = 0; return;` (decompile), so sampling
  resumes one call later. One-sample precision for FILM replay. [HIGH]
- So sample index ≠ frame index. The replica must advance its sample pointer only on those calls. [HIGH]
- Sample value: five bytes, nonzero = held (FILM data has only 0/1). Same priority rules as live keys
  (Up > Down > Left > Right when aligned; opposite-direction reversal between cells). [HIGH]
- Stop rule: after a frame's full update+draw, if `FILM.count <= gRecordingCounter` → game ends.
  Also ends at hero death (state-4 timeout), at level completion (+70 frames), or on any real key /
  mouse event. [HIGH]
- Level = FILM id (data-formats.md §3), start lives 3, score 0, multiplier 1, EXTRA cleared. [HIGH]

## 3. Exact start-up sequence for a demo game (mode 1)

```
PlayGame(level = id, mode 1):
  gLimitFrames=1; FlushEvents; SetHacked(0); level-hack flags reset; install 0.033 s timer
  load FILM id → gRecording (count, seed, …); gFilmCounter = (gFilmCounter+1) mod nFilms
  gRecordingCounter = 0
  SetQDGlobalsRandomSeed(FILM.seed)
  gPlayGame = 1; SetLevel(id-1); ResetHeroLives(); ResetScore(0); Multiplier_Reset; EXTRA_Reset
  NewLevel():                       ; RNG draws in this order
     NextLevel → level = id
     LoadLevel(id)                  ; 0 draws (id ≤ 50)
     ResetBlocks; ResetHurtBlockList; TimeBonus_Reset; LoadMaze(LEVL[0]); InitHero
     PositionJewels                 ; 2 draws per jewel: (1,14),(1,9)
     Splats_Init
     Bubbles_Init → CreateRandomLUT ; 33×(40,480), 21×(0,4), 21×(2,5), 13×(25,90), 21×(0,14)
     Balloons_Init
     InitStars → CreateStarRandomLocLookupTable ; 21× {(0,8),(0,1)}
     InitPoints                     ; 8×(2,6)
     InitEnemies; InitEnemyAI
     Bonus_Init                     ; (0,100),(220,600),(450,950); per armed slot (70,530),(1,14)
                                    ;   [+(9,13) if 5..8][+(lo,hi) if 3/14]; then 21×(0,4)
     DrawMaze …
  frame loop (engine-loop.md §4)
```
[HIGH] — sequence read from `_PlayGame` and `_NewLevel`; draw counts from each init function's loop
bounds (table sizes from nm addresses: XLoc 0x34e80–0x34ec2 = 33 shorts, Drift/Vertical/Groups 21
bytes, Delay 13 shorts, star lookup 0x2a/2 = 21, bonus drift 0x37700–0x3772a = 21 shorts).
The hero's first appearance takes 70 frames (fresh `_PlayGame` call). [HIGH]
⚑ corrected (plan 2026-10-03 btx-core) — **C9, frame numbers.** The 70 is a delay, not a frame number. `_NewLevel @ 0001735f` does
`_gFrameCounter = 0;` before `_InitHero()`, which sets hero state 1 and stateStart = frame (0); the loop
increments the counter before the hero state machine. In `_PlayGame @ 00018247` the state-1 arm
`if ((int)((uint)*(ushort *)(puVar7 + 4) + iVar13) < (int)(uint)_gFrameCounter)` (iVar13 =
`(-(ushort)!bVar1 & 0xfff6) + 0x46` = 0x46 on the first appearance) first holds on **frame 71**. That
sets state 2 and `*(ushort *)(puVar7 + 4) = _gFrameCounter;` (71). The state-2 arm
`if (*(ushort *)(PTR__hero_0003f014 + 4) + 10 < (uint)_gFrameCounter) { … _CheckNewEnemies(); }` first
fires on **frame 82**. Frame 71 does not reach it because the state arms are an if/else chain. Command:
`python3 ghidra/find_func.py '_PlayGame' --file <dump>` (also `'_NewLevel'`, `'_InitHero'`).
[HIGH] (arithmetic over the quoted lines)

## 4. RNG consumers that depend on things a FILM does not record (replay hazards)

1. **Preferences.** Stars (bool pref 0x35) and air bubbles (bool 0x36) default ON
   (`_AlexPrefsGameInit`). With stars off, `_NewStarGroup` returns before `_NewStar` (except groups
   0xf/0x10, which never draw RNG) → the `(0,1)` draws of type-0xb stars vanish (star groups 3/4/5
   from every squish and egg kill, 0xb–0xe incl. hero squash). With bubbles off, `_Bubbles` and
   `_Bubbles_NewGroup` return early → the `(5,9)` draw per air bubble vanishes. **The replica must run
   with both ON to match a FILM recorded with defaults**, and the original itself would desync if a
   user turned them off. [HIGH] for the gating; that FILMs were recorded with both ON is [LOW]
   (assumed default) — NR-9.
   ⚑ corrected (plan 2026-10-03 btx-core) — **C3, which star groups really draw.** Groups **1, 0xb, 0xc and 0xd have no
   callers**. Every call site of `_NewStarGroup @ 000035b5` (13 `calll _NewStarGroup` plus the tail
   `jmp _NewStarGroup` at 0001c008 in `_KillEggBlock`, from `otool -tV <binary>`; the group is the
   `0x8(%esp)` / `0x10(%ebp)` immediate, or the decompile's argument): 3/4/5 (`_SquishEnemy` by sprite,
   `_KillEggBlock` 0001bfb1/0001bfce/0001c00d), 0xe (`_HeroCaught`, 00021f16), 0 and 2 (`_PlayGame`
   0001889f/00018b0e, `_Jewels_TurnToBlocks`, `_Jewels_GiveBonus`, `_CheckJewelMovement`, `_Bonus_Pop`
   0001a769), 0xf/0x10 (`_ExplodeBombBlock` 0001c171/0001c0b8), 6–9 (`_ProcessHero`, decompile
   `uVar14 = 6/7/8/9` by direction), 10 (`_PauseGame` 00017a7f). Star type = the 5th `_NewStar`
   argument. Groups 3/4/5 make 4 type-0xb stars each and 0xe makes 14 (C2, next item). Group 0 makes
   type 0 (+ type 10 at the tail), group 2 types 3..10, groups 6–9 type 0, group 10 type 2 (orbit), and
   groups 0xf/0x10 type 0. So the type-0xb `(0,1)` draws come only from squishes, egg kills and the
   hero squash. Command: `python3 ghidra/find_func.py '_NewStarGroup' --file <dump>`; `otool -tV
   <binary>`. [HIGH]
2. **Cosmetic pools have to be simulated exactly.** `_NewStar` returns before its RNG draw when 60
   stars are alive (`gNumActiveStars == 0x3c`) or no slot is free, **or when the star leaves the
   playfield** (next paragraph); `_Bubbles_New` returns before its
   draw when 8 air bubbles are alive. Star slots are freed by animation count (type 0xb also when far
   off-screen) and air bubbles when they rise above y 0, both in the **draw** pass. So the replica must
   model star lifetimes, star 0xb bounce/exit motion, air-bubble motion (rise speed from the vertical
   table, snaking table, drift table, x clamps 5..635) to the pixel. [HIGH]
   ⚑ corrected (review 2026-10-03) — **pre-draw playfield clip.** `_NewStar @ 0000329a` frees the slot and
   returns **before** the type-0xb `GetRandomFast(0,1)` when the new star's rect leaves the playfield
   (x 0..640, y 0..440): decompile `if ((left < 0) || (0x280 < right) || (top < 0) || (0x1b8 < bottom))
   { star[0] = 0; return; }` precedes `if (param_5 == 0xb) { … _GetRandomFast(0,1) … }`. Squish
   groups 3/4/5 place four 26-px stars at (x,y) offsets (−8,−8), (+6,+6), (−16,+20), (+6,+20) from the
   cell origin, so a squish or egg kill in **col 0 draws 2** numbers instead of 4 (both negative-x
   stars clip), in **row 0 draws 3** (the −8 star), in **row 10 draws 2** (the +20 stars: bottom
   400+20+26 = 446 > 440); the clip is per star, so corners combine. Group 0xe (hero squash, 13
   stars) clips the same way. A replica without this clip desyncs on edge squishes. [HIGH]
   ⚑ corrected (plan 2026-10-03 btx-core) — **C2, group 0xe is 14 stars, not 13.** `_NewStarGroup @ 000035b5` case 0xe has 13
   explicit `_NewStar(…,0xb,0xffffffff)` calls and sets `iVar8 = (int)(short)(param_2 + -2); iVar12 =
   (int)(short)(param_1 + 10);` inside the case. It then sets `uVar15 = 0xb; uVar14 = 8; uVar13 = 2;`
   and `break`s to the shared tail `LAB_00004af8: _NewStar(iVar12,iVar8,uVar13,uVar14,uVar15,uVar16);`.
   That tail is a **14th** type-0xb star, so two stars sit at (x+10, y−2) (anim 4 and anim 8).
   Disasm cross-check: `otool -tV <binary>` shows 83 `calll _NewStar` between 000035b5 and 00004b04,
   which is the 82 explicit calls in the decompile plus the tail at 00004af8. The clip above applies
   per star to all 14, so a hero squash makes up to 14 `(0,1)` draws. This also supersedes the "13
   stars" in REVIEW-2026-10-03.md finding 1 (that file is the review record and stays as written).
   Command: `python3 ghidra/find_func.py '_NewStarGroup' --file <dump>`. [HIGH]
3. **Session latches.** `_Get0To6()` (u) and `_Get13To22()` (L) are fixed at the first menu entry from
   the process's initial QuickDraw seed (no RNG call happens earlier in `_InitMac` — caller scan).
   - L: from the first `_ProcessHero` with state 2 onward, every direction choice at level ≥ L draws
     `GetRandomFast(0,1)` (registered or not).
   - u: `_FigureEnemyMove` draws a discarded `(0,7)` when `level ≥ u+9` and the license code is 0.
     ⚑ corrected (review 2026-10-03): the threshold is untraced — decompile `uVar8 + 9 <= level`, but disasm
     00013def..00013dfd compares `GetLevel()` with `[-0x2c(%ebp)] + 10` (`jb` skips), and `-0x2c` is
     set at 00013d49 from a value not traced (`-0x34` = `_Get0To6` result is confirmed): either
     x = u−1 or the threshold is u+10. [LOW] (enemies-ai.md §4d)
   For FILMs 1–4 (levels 1–4) neither fires (L ≥ 13, threshold ≥ 9 either way). [HIGH]
   For longer recordings, L and u must be known. If Carbon starts `randSeed` at 1 and `Random` is the
   classic Park–Miller step, u = 1 and L = 15 (computed: seed 1 → 16807 → (0,6) gives 1; next
   282475249, low word 0x3af1 → (13,22) gives 15). [LOW] — depends on NR-3 (the step itself is the
   documented QuickDraw algorithm cited at [LOW] in engine-loop.md §3; the review re-computed u = 1,
   L = 15).
4. **License / registration branches.** Present in the sim path; with a *valid registered license* or
   *no license at all* they consume no RNG except where noted: [HIGH]
   - `_FigureEnemyMove` dummy `(0,7)`: fires when license code == 0 (unregistered) — see 3.
   - `_DrawPointsToComp` `(0,20)` per live score popup per frame when `gPointsNotReg` (set when
     `RT3_GetDisplayCopies()` returns "N/A") and level ≥ point.threshold (20..24, from `_InitPoints`
     draws). Whether "N/A" means unregistered is NOT RESOLVED (NR-4).
   - `_ProcessEnemies` hatch `(1,30)`, `_ProcessHero` `(0,30)`, `_CrushBlock` `(0,40)`: only for a
     registered-but-invalid (cracked) license.
   - `_PlayGame` end-of-level `(0,20)`: only for 20 blacklisted license codes.
   Recommendation for the replica: model "registered, valid license" (the condition under which
   Ambrosia demoed the game) — but the FILM's own recording state is unknown (NR-9).
5. **Multiple calls per frame.** `_HeroCaught` draws `(0,1)` each call and can be called up to three
   times in one frame by a large blast; `_CheckForBombKills` order is A, B, C rects. Replicate call
   counts, not just outcomes. [HIGH] ⚑ corrected (review 2026-10-03): the blast kill count `k` also counts
   already-dead enemies (A and C overlap on row r−1) — scoring/multiplier, not RNG; enemies-ai.md §5.
   ⚑ corrected (plan 2026-10-03 btx-core) — **C1, at most one `_HeroCaught` per frame.** `_IsHeroCaught @ 00021c79` returns 0
   unless `(*(short *)(PTR__hero_0003f014 + 2) == 2)`, and `_HeroCaught @ 00021dfa` begins
   `*(undefined2 *)(PTR__hero_0003f014 + 2) = 3;`. All three callers gate on `_IsHeroCaught`:
   `_CheckForBombKills @ 000116eb`, `_ProcessEnemies @ 00011ad3` (which also tests `hero+2 == 2`) and
   `_MoveBlock @ 0001cccb`. `python3 ghidra/find_func.py '_HeroCaught\(' --file <dump>` → 4 blocks:
   those three plus the definition. After the first catch, every later test that frame fails: the
   second and third blast rects, later enemies, later blocks. So the "up to three times" above does not
   happen. There is **one `_HeroCaught` per catch**: one `(0,1)` draw, plus one star group 0xe for
   kind 2 only (block/blast). Kind 1 (enemy) draws `(0,1)` and makes no stars. [HIGH]
6. **Iteration order is part of the RNG order.** Enemies are processed in slot order 0..29; blocks in
   slot order 0..34 (MoveBlock squish → star group draws); free-slot search is "lowest free index".
   Slot allocation must match the original (first free). [HIGH]
7. **Undefined reads.** `_FigureEnemyMove` with `old dir == 0` uses an uninitialised `back` (NR-7);
   `_PopEnemy(-1)` on a hero balloon reads below the enemy array (NR-6). Neither consumes RNG
   directly; outcome unknown.
8. **u16 frame counter.** Timers compare `start + delay` against the u16 frame in mixed signed/unsigned
   ways; a level longer than 65535 frames (36 min) would wrap. Not reachable in FILMs. [MED]

## 5. Per-frame update order (the part a replica must mirror exactly)

```
frame++
hero state machine  (may call _CheckNewEnemies → _NewEnemy: (0,15),(0,10),(1,4),(0,5)×k)
normal-bubble recount (may end level)
_Bubbles            (air-bubble launch: (5,9) per bubble)
_ProcessEnemies     (per slot: _EnemyAI → _FigureEnemyMove: (1,r), tie-break (1,2), MoveEnemyRandomly
                     16 draws; actions → _Balloons_New (4,7); hatch; catch → _HeroCaught (0,1);
                     squish → star groups)
_ProcessHero        (input sample; turns → (0,1) if level ≥ L; push → CrushBlock/PushBlock/KillEggBlock)
_Splats_Process
_Bubbles_Process
_Balloons_Process   (captures → none; pops → _PopEnemy; release)
_Bonus_Process      (collect → rewards: CaptureAll (4,7)×n, Regenerate (1,14),(1,9)…)
_ProcessBlocks      (MoveBlock: squish → star groups, _HeroCaught; explosions; eggs; jewel joins)
_ProcessStars; _ProcessPoints; _TimeBonus_Process
draw pass           (frees stars, points, air bubbles, dead enemies; _DrawPointsToComp trap)
end-of-level / demo-stop checks
```
[HIGH] (engine-loop.md §4 for the citations).

## 6. Validation plan the replica can use (no behaviour claimed here)

- Feed FILM 1 with seed 0x004642a0 on level 1; log RNG draw count per frame and the sample pointer.
  The film should end by `count` exhaustion (1118 samples) unless the hero dies first — the film's
  own end condition is itself an oracle check (which one fires tells whether the replay stayed in
  sync). [MED] (method, not a finding)
- Ben's eyes on the original's demo (same machine, prefs at defaults) are the only behaviour oracle;
  the FILMs may have been recorded by an earlier build (the 1996/2002 engine) — whether X replays them
  faithfully is NOT RESOLVED (NR-10).
