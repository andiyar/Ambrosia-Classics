# Bubble Trouble X 1.1 — hero, input, pushing, dynamite, lives, death

Code readings. Hero = global struct `hero @ 0x385d0` (nm). Grid: col 0..15, row 0..10, cell 40 px.
Directions everywhere: **1 up, 2 down, 3 left, 4 right**.

## 0. Hero struct (offsets used below)

| off | type | meaning (from the code that reads/writes it) |
|---|---|---|
| +0x02 | i16 | state: 1 appearing, 2 playing, 3 caught ("ouch"), 4 dying |
| +0x04 | u16 | frame the state started |
| +0x0c | u16 | last hero-bubble launch frame (`_Bubbles`) |
| +0x14 | Rect | top,left,bottom,right (top = row·40 + yoff) |
| +0x1c | Rect | previous rect (dirty-rect bookkeeping) |
| +0x24 | u8 | license-valid flag (recomputed while dying; 1 after `_ResetHeroLives`) |
| +0x26 | i16 | facing / movement direction 1..4 |
| +0x28 | i8 | col |
| +0x34 | i8 | row |
| +0x35 | u8 | aligned (both offsets 0) |
| +0x36/+0x38 | i16 | x / y offset inside the move, −40..40 |
| +0x3a | u8 | `RT3_IsRegistered()` copy |
| +0x3c/+0x3e | i16 | sprite set (1 idle, 2 up, 3 down, 4 left, 5 right, 6 push, 7 death) / frame |
| +0x40 | u8 | push/pop animation active; +0x42 counter; +0x46 duration |
| +0x48 | i16 | death-animation counter |
| +0x4a | u8 | visible |
| +0x4b | u8 | death bubbles emitted |
| +0x4c | u8 | trapped in a balloon; +0x4e start frame |
| +0x50 | u8 | invisibility bonus active; +0x51 draw-transparent toggle; +0x52 start frame |
| +0x54 | u64 | license code copy |
| +0x5f | u8 | speed-up active (+0x60 start) — never enabled in the shipped build |
| +0x66 | i16 | speed, px/frame |
[HIGH] for each offset's use; names are mine.

## 1. Start position — `_ResetHeroPosition @ 0002165f`

- If `gMaze[0x67]` (col 7, row 6) is empty → hero at (7,6). [HIGH]
- Else scan rows 5..7, cols 6..8 (row-major) for the first empty cell; failing that, the first cell
  that is not a jewel (0x14/0x1e) — i.e. the hero may start **on a bubble**. If none: "Internal
  error: can't find good starting loc." and quit. [HIGH]
- When state 1 → 2 (`_PlayGame`), `gMaze[hero cell] = 0`: the bubble under the hero vanishes. [HIGH]
  Matches the editor read-me ("nearest free square … else put on top of a bubble, and that bubble
  is removed"); note the code's "nearest" is a fixed 3×3 scan order, not a distance search.
- Resets: aligned, offsets 0, rect = cell, facing 3 (left), sprite set 1, frame 3, push flag 0,
  `+0x4b`, `+0x4c` = 0. `_InitHero @ 000217b3` additionally: state 1, stateStart = frame (0 at level
  start), speed 5, invisibility off, speed-up off. [HIGH]
- Jewels are placed **after** `_InitHero` and only avoid (7,6), not the hero's actual cell. [HIGH]
  All 50 shipped mazes have (7,6) empty (Python check of byte 0x67 over `MAZE_1..50`: no exceptions),
  so at level start the hero is always at (7,6) and the edge case needs a custom level. [HIGH]
  On a respawn the scan runs against the current maze, so a bubble pushed onto (7,6) displaces him.

## 2. Input — `_CheckHeroMovement @ 00021f49`

Called only from `_ProcessHero`, only when hero state == 2 and neither the push animation (`+0x40`)
nor the balloon trap (`+0x4c`) is active (those return earlier). [HIGH]
- Live play: `_UpKey/_DownKey/_LeftKey/_RightKey/_PushKey` → `_GameKeyDown(code)` = `GetKeys` bit test
  on the Mac virtual key code from the current key set (data-formats.md §9). Keys are **levels, not
  edges**: held = pressed every sample. [HIGH]
- Demo: the five flags come from `FILM.{up,down,left,right,push}[gRecordingCounter]`, then
  `gRecordingCounter++`. [HIGH]
- Output globals: `gHero_Up/Down/Left/RightKeyPressed`, `gHero_PushKeyPressed`, and
  `gHero_MoveKeyDown` (any direction). Multiple directions may be set at once. [HIGH]

## 3. Movement

Speed `hero+0x66` = 5 px/frame → 8 frames per cell. [HIGH] (`_InitHero`, `_SetHeroSpeed(5)`; the only
`_SetHeroSpeed` caller is `_PlayGame` with 5.) The anti-crack path in `_ProcessHero` can toggle 5↔1
for cracked licenses only (`hero+0x24==0 && license≠0`, score > 17923, 1/31 chance). [HIGH]

Aligned (`hero+0x35`) — `_MoveHeroAligned @ 00022847`, entered only if some direction is held:
- Priority **Up > Down > Left > Right** (if/else chain). Sets facing, sprite set (2/3/4/5), frame 1. [HIGH]
- `next = _GetNextObject(dir, col, row)`; moves only if next ∈ {0, 'P'} (empty); otherwise only turns
  to face the obstacle. Moving = offset rect by 5 px and accumulate `+0x36/+0x38`; when it reaches
  ±40 the col/row changes and the offset resets to 0. [HIGH]
- The cell occupied by an enemy is empty in `gMaze` (enemies are not in the maze), so the hero
  can walk into enemies (and be caught). Eggs are in the maze (0x3c) and block him. [HIGH]

Between cells — `_MoveHeroNotAligned @ 000224c8`: the hero keeps going in his direction regardless
of keys, **except** that pressing the exact opposite direction reverses immediately (dir 2 checks
Up, 1 checks Down, 4 checks Left, 3 checks Right). Walk frame (+0x3e) steps −1 on a reversal frame
(wrap 1→8), +1 otherwise (wrap 8→1). [HIGH]
Cosmetic quirk with RNG cost: whenever a direction is (re)chosen, if `level ≥ gLevelForEffect`
the code draws `GetRandomFast(0,1)`; only an unregistered copy (`hero+0x3a==0`) uses the result
(swaps the up/down or left/right sprite). `gLevelForEffect` starts at 50 and is replaced on the first
`_ProcessHero` of the session by `_Get13To22()` (13..22). [HIGH] — replay hazard, see replay-oracle.md.

## 4. Push / pop — `_ProcessHero @ 00022de0` + `_HeroPushCrushCheck @ 000220d8`

Only when aligned and Push is held; uses the **facing** (`hero+0x26`), not the held direction. [HIGH]
Let `N = _GetNextObject(face)` (adjacent cell), `D = _GetDistantObject(face)` (cell beyond; 0x32
if off-grid). Return 1 = "push", 2 = "pop", 0 = nothing (then normal movement runs). [HIGH]

| N | D | action | return |
|---|---|---|---|
| 10/15/16 bubble or 52 dynamite | 0 or 'P' | `_PushBlock(col,row,face,N)` — bubble starts sliding; for dynamite already lit (`_IsActiveBombBlock`) → nothing, return 0 | 1 |
| same | 10..60 (any object or wall 0x32) | `_CrushBlock(col,row,face, score=1)` — pop (+1 point ×mult); dynamite: also `_ActivateBombBlock` (light fuse, or detonate if already lit > 30 frames) | 2 |
| 20 jewel, no jewel joined yet | D empty or D jewel | push | 1 |
| 20 jewel, a target exists | N is the target → thud (sound 7); else push if D empty, or D is jewel/cluster and D is the target | 1 |
| 20 jewel, otherwise | — | thud (sound 7), no move | 1 |
| 30 joined cluster, or 50 wall | — | thud | 1 |
| 60 egg | — | `_KillEggBlock` (see bubbles-items-scoring.md §2) | 2 |
| 0 / other | — | — | 0 |
[HIGH] — table transcribes the branches; `'3'`/0x33 branch is dead (code 0x33 never stored).

After return 1: sprite set 6 (push), `+0x40=1`, duration 2 → the hero is frozen for that frame plus 3
more `_ProcessHero` calls (counter 1,2 ≤ 2; 3 ends it; the ending call also does not move). After
return 2: duration 5 → frozen 6 more calls. On the ending call the walking sprite for the facing is
restored (with the `gLevelForEffect` RNG draw). [HIGH]

`_PushBlock @ 0001bd62`: creates a moving block in the adjacent cell (`_NewBlock(..., type, -1,
param6=1)`) and sets that maze cell to 0 — **a sliding bubble is not in `gMaze`**. [HIGH]
`_CrushBlock @ 0001bc14`: creates a pop block (type 0x28) in the adjacent cell and writes maze 0x28
unless the cell is dynamite; points `AddToScore(1, 1)` when `score` arg set (hero only; enemies pass 0).
[HIGH] (disasm `0001bd3f movl $1` → `_AddToScore`.)

## 5. Lives, catch, death — `_PlayGame` hero state machine

- Lives: `_ResetHeroLives` → 3. `_AddHero(n)` caps at 9. Extra lives: at score ≥ 10000, then 40000,
  80000, 120000… (`_AddToScore`), and on EXTRA completion. [HIGH]
- `_IsHeroCaught(rect, protectInvisible, bigInset) @ 00021c79`: only in state 2; skipped if
  `protectInvisible && hero+0x50`; rect inset by 4 (or 11 when `bigInset`), hero rect inset by 8 when
  `bigInset`; strict overlap (`_RectsCollide`: `<` on all four edges). [HIGH]
  Callers: enemy body (`_ProcessEnemies`, (1,1)), moving bubble (`_MoveBlock`, (1,0)), blast
  (`_CheckForBombKills`, (1,1)). Balloons capture separately (§6). [HIGH]
- `_HeroCaught(kind) @ 00021dfa`: state 3, stateStart = frame, `_StopAllEnemies` (every enemy in
  states 1,2,3,4,6 → 5 frozen), "Ouch" bubble. kind 1 (enemy): sound 0x25 or 10 by
  `GetRandomFast(0,1)`. kind 2 (squashed/blasted): sounds, `GetRandomFast(0,1)`, splat, star group
  0xe, hero invisible (`+0x4a=0`). [HIGH] — note it can be called several times in one frame (e.g.
  big dynamite runs three blast rects) and re-draws RNG each time.
- State 3 → 4 after **30 frames** (`stateStart+0x1e < frame`): `_SubtractLife`, set 1, frame 0,
  death counter 0, `_MakeAllEnemiesDisappear` (all enemies removed, their types returned to the
  level pool; all balloons popped), music stops. [HIGH]
- State 4 (dying): set 7, every 2 frames frame+1 up to 16; at the 17th step (once, if visible) air
  bubble group 0xb. After **65 frames**: demo/record → game ends; else state 1, respawn at
  `_ResetHeroPosition`, `_Multiplier_Reset(1)` (multiplier lost), "game over" notice if lives < 1. [HIGH]
- State 1 → 2 after **70 frames** for the first appearance in a `_PlayGame` call, **60** thereafter
  (`(-(ushort)!first & 0xfff6) + 0x46`), or game over after **95** frames when lives < 1. On
  appearing: clear maze cell, visible, speed 5, music, star group 0, sounds,
  `_Blocks_DeactivateRubberBlocks` (every active blue/purple block is retired and written into the
  maze at its current grid col/row, even if it was between cells). [HIGH]
- During states 1, 3, 4 `_ProcessHero` returns early (no input sampled). [HIGH]

## 6. Balloon trap (shark bubble) on the hero

`_Balloons_CaptureHero @ 00023cbb` (flying balloon overlaps the hero, hero not invisible and not
already trapped): balloon becomes "holding" at the hero's cell, `hero+0x4c=1`. `_ProcessHero`
then returns early until `frame > +0x4e + 90` (3 s), so the hero cannot move or push.
⚑ corrected (review 2026-10-03): on the first frame the condition holds the code does `+0x4c = 0; return;`
(`_ProcessHero` decompile) — that frame also consumes no FILM sample; input resumes one call later.
[HIGH] The hero is
**not** killed by the trap itself; enemies touching him still catch him (`_ProcessEnemies`). [HIGH]
On release the balloon pops when it still overlaps the now-free hero and calls `_PopEnemy` with
the balloon's enemy index 0xff (−1) — an out-of-array read at `enemy[-1]` (memory just below the
`enemy` array = `_environment`/GWorld globals per nm). Effect NOT RESOLVED (NR-6); the replica
should treat it as a no-op. [MED]

## 7. Invisibility bonus — `_SetHeroInvisibility(1)`

300 frames (`+0x52 + 300`); from frame 210 the sprite blinks (toggle every 3 frames); while active,
enemy bodies, moving bubbles, blasts and balloons cannot catch the hero. [HIGH]

## 8. Weapons — dead code

`_InitWeapon`, `_NewWeapon`, `_LaunchWeapon`, `_IncreaseAmmo`, `_DecreaseAmmo`, `_DrawWeaponInfo` have
**no callers** in the disasm (caller scan). Dynamite is a maze object (code 52), not a weapon. [HIGH]
(The brief's `_InitWeapon…_LaunchWeapon` fuse/ammo hypothesis does not apply; the real dynamite
rules are in bubbles-items-scoring.md §4.)

## 9. Pause-screen cheat codes (not replayable input)

`_PauseGame @ 0001767b` hashes the last five typed characters
(`(c0+410)(c1+106)(c2+333)+3+(c3+280)(c4+560)`) against constants: toggle FPS, reset score, daddy
mode (15 fps), star burst, toggle frame limit, end level, ghost icons, +1 life, +9000 points,
invisibility, capture all enemies, EXTRA letters 1–5, multiplier 2–5, regenerate bubbles. Most set
`gPlayerIsCheating` (no high score). [HIGH] Pause is disabled in demo mode. FILMs carry no typed keys,
so cheats cannot occur during playback.
