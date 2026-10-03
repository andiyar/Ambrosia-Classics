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

## 4. RNG consumers that depend on things a FILM does not record (replay hazards)

1. **Preferences.** Stars (bool pref 0x35) and air bubbles (bool 0x36) default ON
   (`_AlexPrefsGameInit`). With stars off, `_NewStarGroup` returns before `_NewStar` (except groups
   0xf/0x10, which never draw RNG) → the `(0,1)` draws of type-0xb stars vanish (star groups 3/4/5
   from every squish and egg kill, 0xb–0xe incl. hero squash). With bubbles off, `_Bubbles` and
   `_Bubbles_NewGroup` return early → the `(5,9)` draw per air bubble vanishes. **The replica must run
   with both ON to match a FILM recorded with defaults**, and the original itself would desync if a
   user turned them off. [HIGH] for the gating; that FILMs were recorded with both ON is [LOW]
   (assumed default) — NR-9.
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
