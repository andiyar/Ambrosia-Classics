# Bubble Trouble X 1.1 — enemies: spawn, eggs, AI, speeds, squish/capture

Code readings. Enemy array `enemy @ 0x393c0`, 30 slots × 0x5c bytes. Directions 1 up, 2 down,
3 left, 4 right.

**Dump gap.** Five static functions are absent from the dump as separate blocks (nm `t` symbols with
no `// ====` header): `_NewEnemy @ 00012172`, `_CorrectEnemyMazeY @ 00012682`,
`_CorrectEnemyMazeX @ 00012704`, `_MoveEnemy @ 00012786`, `_MoveEnemyRandomly @ 0001396f`. Each is
reached by a tail `jmp` (`_CheckNewEnemies` 00012586 → NewEnemy, `_EnemyAI` 0001436e → MoveEnemy,
`_FigureEnemyMove` 00013d97 → MoveEnemyRandomly, MoveEnemy 00012c55/00012c76 → CorrectEnemyMazeY/X)
and Ghidra folded their bodies into the caller's decompile. Every claim below about those five was
checked against `otool -tV` disassembly. [HIGH]

## 0. Enemy struct (offsets used)

| off | meaning |
|---|---|
| +0x00 u8 | state: 0 free, 1 active, 2 egg (pre-flash), 3 egg (flashing), 4 (tested, never set), 5 frozen, 6 held in balloon |
| +0x02 u16 | state-start frame |
| +0x10 u8 | type 1 piranha (Chombert), 2 eel (Remington), 3 shark (Normal), 4 starfish (Haarrfish) |
| +0x12 Rect | top,left,bottom,right |
| +0x23 u8 | direction 1..4 (0 = none, cleared while deciding) |
| +0x24 i8 / +0x30 i8 | col / row |
| +0x31 u8 | aligned (both coords multiples of 40) |
| +0x32 / +0x38 | x / y remainder mod 40 |
| +0x3a i16 | sprite set = type id: 0x1b piranha, 0x1c eel, 0x1d shark, 0x1e starfish (0x3039/0x303a debug types) |
| +0x3c i16 | "tier", always 4 for real enemies (set in `_NewEnemy`; the only other write is in the 0x303a debug branch) |
| +0x3e i16 | 0x14 at spawn, 0x17 (or 0x13/0x14 on a cracked license) at hatch — anti-crack marker only |
| +0x40 i16 | animation frame; +0x4c anim tick |
| +0x43 i8 | balloon index holding it (−1 none) |
| +0x44 i16 | post-hatch delay counter; +0x4b u8 post-hatch delay flag |
| +0x46 u8 | drawn; +0x47 u8 dead (slot freed in the draw pass) |
| +0x48 i16 | "stuck" counter (random walk) |
| +0x4a u8 | **pause**: when set, the enemy does not move this frame |
| +0x4e / +0x50 i16 | speed counter / speed (piranha uses +0x4e as its speed) |
| +0x52 i16 | action wait counter; +0x58 i16 pending action (1 push, 2 pop, 3 balloon, 4 wait) |
| +0x5a u16 | frame of last pop/push/balloon (spawn frame initially) |
[HIGH] for every use cited; the +0x3c "always 4" relies on a decompile grep of all `+ 0x3c) =`
writes on enemy pointers (2 hits) — a register-indirect write elsewhere cannot be fully excluded [MED].

## 1. Spawning — `_CheckNewEnemies @ 000124fa` → `_NewEnemy @ 00012172`

Called every frame while hero state == 2 and `frame > hero.stateStart + 10` (`_PlayGame`). [HIGH]
Gates, in order:
1. hero state 2.
2. `gNumNormalBlocks < 1` (no normal bubble left) → no spawn; if no enemy active, set
   `gNumEnemiesSquished = total` (level ends).
3. `TimeBonus ≤ 0` → `gNumEnemiesSquished = total − active` (no more spawns: "Hurry up").
4. `squished + active ≥ total` → return.  5. `active ≥ LEVL max (w7)` → return.
6. no free slot among 30 → return.
Then NewEnemy (same frame): [HIGH]
- `c = GetRandomFast(0,15); r = GetRandomFast(0,10)`; scan forward **starting at c+1** (row-major,
  col wraps 15→0 with row+1, row wraps 10→0) until a cell == 10 (normal bubble). The starting cell
  itself is tested last.
- Egg goes **inside that bubble**: maze cell = 0x3c, `gNumNormalBlocks--`, `_NewBlock(c,r,0,0x3c,slot,0)`
  (egg block: state 3, frame = enemy type, +0x2a = 15).
- direction = `GetRandomFast(1,4)`; tier 4; state 2; stateStart = frame; lastPop = frame.
- type: if pool words 18..23 are all 0, word 18 := 1; then repeat `i = GetRandomFast(0,5)` until
  `pool[i] ≠ 0` (rejection loop — variable number of RNG draws); `pool[i]--`; type = i+1.
- initial anim frame: per direction 1→1, 2→4, 3→7, 4→10 (starfish always 1).
- `gNumEnemiesActive++`.
Consequence: eggs are laid back-to-back, one per frame, until `max` are active; a squished enemy is
replaced on the frame after its slot is freed. [HIGH] (behaviour unverified).

## 2. Egg → hatch timeline

Enemy (`_ProcessEnemies @ 00011ad3`): [HIGH]
- state 2: when `frame > start + LEVL w10` (10) → state 3, start = frame.
- state 3: when `frame > start + 10 + LEVL w8` (egg time, 50) → **hatch**: state 1, start = frame,
  drawn, post-hatch delay flag set (16 frames of no AI: `+0x44` counts to 16), `+0x3e` marker.
Egg block (`_ProcessBlocks @ 0001d2b8`): [HIGH]
- state 3 while `frame < start + LEVL w8`: alternates bubble sprite / egg sprite every 9 frames.
- then state 4; when `frame > start + 15` → becomes a popping bubble (type 0x28, maze 0x28, 8 frames,
  sound 0x10), then the cell is emptied.
With level-1 values: egg block pops ≈ 66 frames after laying; the enemy goes active ≈ 72 frames after
laying and starts thinking 16 frames later. [HIGH] arithmetic; on-screen sync unverified.
Hero pushing an egg cell pops it and kills the unborn enemy (+50 ×mult) — `_KillEggBlock`
(bubbles-items-scoring.md §2). Enemies never pop eggs (their pop mask is codes 10/15/16 only). [HIGH]

## 3. Per-frame enemy processing (`_ProcessEnemies`)

For each slot (0..29), by state: [HIGH]
- 1: if post-hatch delay → count it; else `_EnemyAI(i)`. Advance animation (piranha/shark/eel:
  3- or 5-frame cycles per direction, every 3–4 ticks; starfish 7 frames).
- 2 / 3: egg timers (§2).  4, 5, 6: nothing.
Then for every non-free slot: `_CorrectEnemyAligned`; if **not aligned**, look at the cell the body
is entering — dir 1/3: `gMaze[col,row]` (the coords already rounded toward the target), dir 2/4:
`_GetNextObject(dir)` — and if it holds a bubble or jewel (10/15/16/20/30), `_SquishEnemy(i,1)`
(a bubble that has come to rest into the enemy's path squashes it: 200 points). [HIGH]
Finally, state 1 only: if hero state 2 and `_IsHeroCaught(enemyRect,1,1)` → `_HeroCaught(1)`. [HIGH]
Collision insets: enemy rect −11 each side, hero rect −8 → bodies must overlap by more than 19 px. [HIGH]
⚑ corrected (plan 2026-10-03 btx-core) — **C10, an enemy squished on entry can still catch the hero.** `_ProcessEnemies @
00011ad3` sets `bVar14 = true;` for state 1 at the top of the iteration (`LAB_00011ba5`). It then runs
the not-aligned entry test (`_SquishEnemy(iVar13,1);`, which sets the dead flag `+0x47` and leaves the
state byte at 1). Then it tests `if (((bVar14) && (*(short *)(PTR__hero_0003f014 + 2) == 2)) &&
((cVar5 = _IsHeroCaught(…enemy rect…,1,1), cVar5 != '\0' && (*pcVar1 != '\x04')))) { _HeroCaught(1);
}` with no `+0x47` test. So an enemy that a resting bubble squashes on entry can still catch the hero
in the same call, and the replica must reproduce that. Command: `python3 ghidra/find_func.py
'_ProcessEnemies' --file <dump>` (also `'_SquishEnemy'`). [HIGH]

## 4. `_EnemyAI @ 00014296`

```
aligned = (left % 40 == 0 && top % 40 == 0)
if aligned: _FigureEnemyMove(i)          ; may set dir, pause, start an action
if pause (+0x4a): return
_MoveEnemy(i)                            ; tail jump
```
[HIGH]

### 4a. `_MoveEnemy @ 00012786` — speeds (px/frame), recomputed only when aligned

With tier = 4 every "tier ≤ 3" branch is dead; what remains (disasm 00012812..00012b0e): [HIGH]

| type | speed rule |
|---|---|
| piranha 0x1b | 2. If TimeBonus ≤ 0: 4 when \|dcol\|>1 or \|drow\|>1 from the hero, else 2. (speed kept in +0x4e) |
| eel 0x1c | TimeBonus > 0: 2 when \|dcol\|≤2 and \|drow\|≤2, else 4. TimeBonus ≤ 0: 2 when both ≤1, else 8 |
| shark 0x1d | step counter c = ++(+0x4e) each aligned frame: c≤1 keep; 2–3 → 4; 4–5 → 2 (8 if bonus≤0); 6–7 → 4; 8–9 → 2 (8 if bonus≤0); 10 → 4; 11 → 8; 12 → 4; >12 → 2 and c=0 |
| starfish 0x1e | c = ++(+0x4e): bonus>0: 1–3 → 4, 4–6 → 8, 7 → 4, >7 → 2 and c=0. bonus≤0: 1–2 → 4, 3–6 → 8, 7 → 4, >7 → 2, c=0 |
Move: dir 1 top/bottom −= s; 2 += s; 3 left/right −= s; 4 += s; then `col = left/40`,
`row = top/40` (C division; coords are non-negative). Speeds 2/4/8 all divide 40, so an enemy
re-aligns exactly. [HIGH] Guide cross-check: Chombert "same speed, doubles when the bonus runs out";
Remington "two speeds … double when further away … extremely fast when bonus runs out";
Normal "small, darting movements"; Haarrfish "darting … much faster than Blinky" (hero = 5). Consistent.

### 4b. `_FigureEnemyMove @ 00013bd4` (aligned enemies)

`u = _Get0To6()` (session constant 0..6). [HIGH]
1. **Pending action** `+0x58` (always taken because `u ≤ 7`):
   2 → `_TryRemoveGo(dir)`; 1 → `_TryEnemyPushBlock(dir)`; 3 → `_TryEnemyCreateBalloon(dir)` — each
   success → pause, return. 4 → if `+0x52 < 10`: `+0x52++`, pause, return; else clear.
2. `old = dir; dir = 0`. If old ≠ 0: if the next cell is a popping bubble (0x28) and paused → keep
   `dir = old`, return (wait for the pop). (The 0x28 test is `_EnemyCheckBurstingBubble @ 00012e01`
   — ⚑ corrected (review 2026-10-03), name added.) Else if paused and the way ahead is free
   (`_TryAndTurnEnemy(old)`) → unpause, return (carry on after a pause).
3. Clear pause. `r = _FigureEnemyRandomness(i)`; **roll = GetRandomFast(1, r)**.
4. If roll ≠ 1 and TimeBonus > 0 → `dir = old`, tail-jump **`_MoveEnemyRandomly`** (§4c).
5. Else **home on the hero** (§4d).
[HIGH] (disasm 00013bd4..00013d97).

`_FigureEnemyRandomness @ 00012d65`: base = starfish `750 − 15·level`, eel 120, shark 180, debug
0x3039 1200 / 0x303a 30, else (piranha) 600; `r = base / (frame − stateStart) + 1`, min 1 (C int
division; stateStart = hatch or balloon-release frame). So the homing chance 1/r grows with time
since hatching: a piranha reaches 1/2 after 600 frames (≈20 s), an eel after 120. [HIGH]
Guide: Chombert "quite a while after hatching before he starts going for Blinky"; Remington
"quicker to start" — consistent.

### 4c. `_MoveEnemyRandomly @ 0001396f` (disasm-only function)

```
pending-action dispatch identical to 4b.1 (success → pause, return)
old = dir; dir = 0
order = [3,4,1,2]; repeat 8: a = GetRandomFast(0,3); b = GetRandomFast(0,3); swap(order[b], order[a])
for d in order: if d != opposite(old) and TryAndTurn(d): return
if old != 0 and TryAndTurn(opposite(old)): return          ; reverse as last resort
if stuck(+0x48) > 0: _ToastBubble(i); stuck = 0; return
stuck++; dir = 3; pause = 1
```
[HIGH] — 16 RNG draws per call, every time this branch runs.
`_TryAndTurnEnemy(d)` → `_CheckUp/Down/Left/Right`: succeeds only if `dir == 0` and the next cell is
0, 'F' or 'P' (effectively empty); sets `dir = d`. [HIGH]
`_ToastBubble @ 00012ef2`: pops the first adjacent bubble (10/15/16) checking **up, down, left —
never right** (the loop exits at 4 before testing it; disasm 00012f3e `cmpw $3; jle`), with
`_CrushBlock(..., score 0)`; if none, `dir = 1`. Always sets pause. [HIGH]

### 4d. Homing branch

`dx = e.col − hero.col`, `dy = e.row − hero.row` — **signed**: the code negates them only when
`u == −1`, which `_Get0To6` can never return (disasm 00013dc2 `cmpl $-1,-0x34(%ebp)`). [HIGH]
Dummy draw: if `level ≥ u + 9` and `gAIRegistered == 0` (license code is zero, i.e. unregistered;
set in `_DrawMaze`) → `GetRandomFast(0,7)` discarded. [HIGH] for the draw and the license gate.
⚑ corrected (review 2026-10-03): the level threshold is **untraced [LOW]** — the decompile says `uVar8 + 9 <=
level`, but disasm 00013def..00013dfd compares `GetLevel()` with `[-0x2c(%ebp)] + 10` (`jb` skips),
and `-0x2c` is set at 00013d49 from a value not traced (`-0x34` = the `_Get0To6` result is
confirmed). Either that value is u−1 (threshold u+9) or the threshold is u+10. Unregistered path only.
`back` = opposite(old) (old 0 → `LocationErrorInt` and `back` uninitialised — NR-7).
Primary/secondary choice (p, s), using the signed values: [HIGH]

| dy (enemy−hero row) | dx (enemy−hero col) | p, s |
|---|---|---|
| < 0 (hero below) | < 0 | dx < dy ? (2 down, 4 right) : (4, 2) |
| < 0 | 0 | 2, then 3 or 4 by GetRandomFast(1,2) (1→3) |
| < 0 | > 0 | 3 left, 2 down (the "dy ≤ dx" test is always true) |
| 0 | < 0 | 4 right, then 1 or 2 by GetRandomFast(1,2) (1→1) |
| 0 | > 0 | 3 left, then 1/2 random |
| 0 | 0 | 4, 1 |
| > 0 (hero above) | 0 | 1 up, then 3/4 random |
| > 0 | < 0 | 1 up, 4 right (dx < dy always) |
| > 0 | > 0 | dx < dy ? (1, 3) : (3, 1) |
Note the comparisons are on signed values, so in the "both negative" quadrant the larger *signed*
value wins — the opposite of an abs-distance rule. Replicate as written.

Then: [HIGH]
```
if back != p:                                  ; (tier < 6 always true)
   if shark && CanDoNormalPop && TryEnemyCreateBalloon(p): return
   if TryAndTurn(p): return
   if starfish && TryEnemyPushBlock(p): return
   if CanDoNormalPop:
       if (eel or shark) && TryEnemyPushBlock(p): return
       if TryRemoveGo(p): return
   tried[p] = 1
if back != s:
   if TryAndTurn(s): return
   if CanDoNormalPop:
       if (starfish, eel or shark) && TryEnemyPushBlock(p): return     ; NB: p, not s
       if TryRemoveGo(s): return
   tried[s] = 1
k = (back == p) ? s : (back == s) ? p : none
if k: TryAndTurn(opposite(k)) → return on success; tried[opposite(k)] = 1
for d = 1..4: if !tried[d] && d != back: TryAndTurn(d) → return;
              if CanDoNormalOtherPop && TryRemoveGo(d) → return; tried[d] = 1
for d = 1..4: if !tried[d]: TryAndTurn(d) → return; tried[d] = 1       ; i.e. reverse
clear tried; TryRemoveGo(p) → return; tried[p]=1; TryRemoveGo(s) → return; tried[s]=1
2 passes: for d: if !tried[d]: TryRemoveGo(d) → return; tried[d] = 1
dir = old; pause = 1
```
`_CanDoNormalPop @ 00012cf4`: `frame > lastPop + 120 && (short)(10 − frame) < (short)((frame −
stateStart)/30)`; `_CanDoNormalOtherPop` the same with 4. The second term is true whenever
`10 < frame < 32778` (left side negative) — effectively a 120-frame cool-down. [MED] (the formula is
exact; "effectively" assumes levels shorter than ~18 min).
⚑ corrected (plan 2026-10-03 btx-core) — **C11, old dir 0: the original quits (resolves NR-7).** The switch on the old direction
(`-0x45(%ebp)`, disasm 00013e1d..00013e29) sends every value except 1..4 to 00013e2b `movl $0x1,
0x4(%esp)`; `movl $0x7d8,(%esp)`; 00013e3a `calll _LocationErrorInt`. `_LocationErrorInt @ 000145be` is
`_DoLocationError((int)param_1,(int)param_2,0x232c);`. `_DoLocationError @ 00014511` shows the string,
then `_StopAlert((int)param_3,0); _CleanUp();`, and `_CleanUp @ 00005413` ends `_FlushEvents(0xffff,0);
… _ExitToShell();`. Control never returns, so `back` is never read. An enemy homing with old dir 0
ends the program. Replica: stop with "original would abort" (plan Invariant 18). Command: `otool -tV
<binary>` 00013e1d..00013e3a; `python3 ghidra/find_func.py '_DoLocationError' --file <dump>` (also
`'_CleanUp'`). [HIGH]

### 4e. Actions (all set `dir`, pause the enemy and wait N aligned frames before acting)

| action | function | condition | wait N (frames) | effect |
|---|---|---|---|---|
| pop | `_TryRemoveGo @ 0001305e` | next cell ∈ {10,15,16} | starfish 10, else max(5, 40 − level) | `_CrushBlock(no score)`, lastPop = frame |
| push | `_TryEnemyPushBlock @ 000131fd` | next == 10 only, cell beyond 0 or 'F', and not near the edge (row ≤ 8 down, ≥ 2 up, col ≥ 2 left, ≤ 13 right) | starfish 10, else max(5, 70 − 2·level) | `_PushBlock(..., 10)`, lastPop = frame |
| balloon | `_TryEnemyCreateBalloon @ 00013441` | hero not trapped; walking from the enemy's own cell in `d`, a scanned cell equals the hero's col,row before the first non-empty next cell (up/left stop at index 1, down at 9, right at 14) | max(5, 70 − 3·level) | `_Balloons_New(i)`; lastPop updated every waiting frame |
[HIGH] Each waiting frame stores the action in `+0x58` and counts `+0x52`; the action fires on the
frame the count reaches N (count then reset). Guide: "Remington … a longer pause means he's going
to push it rather than pop it" — matches (70−2L > 40−L for levels < 30). Only the shark creates
balloons (only call sites: shark homing branch + pending-action replay). [HIGH]
Jewels (20/30) and dynamite (52) are never popped or pushed by enemies (pop mask 0x18400 = codes
10,15,16; push requires 10) — "safe jewels". [HIGH]

## 5. Squish, pop, capture, release

- `_SquishEnemy(i, n) @ 0001131b` (ignored if dead or free): points ×mult — n=1: 200, 2: 400, 3: 800,
  4: 1600, any other n (0 or ≥5): 3200; for n ≥ 3 (and 0) calls `_Bonus_SetNumEnemySquishes(n)`
  (multiplier, bubbles-items-scoring.md §6); marks dead, `gNumEnemiesSquished++`, clears its maze cell
  (harmless — enemies are not in the maze), splat, star group by sprite (3 piranha, 4 eel/starfish,
  5 shark; groups 3–5 draw RNG when stars are on). [HIGH]
  Sources of n: a moving block passes its own running count (`block+0x1d`, +1 per enemy it hits);
  `_RegenerateBlocks` passes 1; `_ProcessEnemies` overlap passes 1; blasts pass base+k. [HIGH]
- `_PopEnemy(i) @ 00011254`: enemy in a balloon popped by the hero: +100 ×mult, dead, squished++. [HIGH]
- `_KillEnemy(i, clearCell)`: dead, squished++ (egg kill). [HIGH]
- `_CaptureEnemy(i, balloon)`: state 6, sprite 0x20, frame = type. [HIGH]
- `_ReleaseEnemyFromBalloon(i)`: unless state 5 → state 1, stateStart = frame (resets homing
  randomness and the CanDoNormalPop window), sprite/frame from type+dir. [HIGH]
- `_StopAllEnemies`: states 1,2,3,4,6 → 5 (hero caught). `_MakeAllEnemiesDisappear`: every non-free
  enemy → dead, its type returned to the pool (`level[0x22 + type*2]++`), not counted as squished;
  balloons in state 2 popped. Egg blocks already in the maze keep running their timers. [HIGH]
- `_CheckForBombKills(rect, base) @ 000116eb`: enemies in states 1,4,5,6,3 overlapping `rect`
  (strict) → pop their balloon if any, `_SquishEnemy(i, base + k)` (k = 1,2,… in slot order); then the
  hero test `_IsHeroCaught(rect,1,1)` → `_HeroCaught(2)`. Returns k. [HIGH]
  ⚑ corrected (review 2026-10-03): k (`local_1e`) is incremented for every overlapping enemy in those states
  **without testing the dead flag `+0x47`**; `_SquishEnemy` ignores the dead one but k advances. With
  the big blast, rects A and C overlap on row r−1 (cols c−1..c+1), so an enemy killed by A is
  re-counted by C and inflates `base+k` (points and multiplier step) for every later enemy in C.
  Original-engine quirk — the replica must reproduce it (bubbles-items-scoring.md §4). [HIGH]
⚑ corrected (plan 2026-10-03 btx-core) — **C8.** The "for n ≥ 3 (and 0)" call is real (the 3200 default arm `LAB_000113bd` covers n ≤ 0
and n ≥ 5 and falls through to `_Bonus_SetNumEnemySquishes(iVar7);`). But `_Bonus_SetNumEnemySquishes
@ 0001a818` begins `if (param_1 < 3) { _gBonus_NumEnemiesSquishedAtOnce = 0; return; }`, so n ≤ 2
never steps the multiplier. Command: `python3 ghidra/find_func.py '_SquishEnemy' --file <dump>` (also
`'_Bonus_SetNumEnemySquishes'`). [HIGH]

## 6. Level count bookkeeping

`_AreAllEnemiesSquished`: `gNumEnemiesSquished ≥ LEVL total (+0xc)`. Total can grow at run time
(+1 starfish per partial jewel join while active < max). `_FinishLevel` (all normal bubbles gone)
sets squished = total. [HIGH] The guide's "enemy line" technique is not a code concept: lining
enemies up simply lets one moving block hit several (each hit raises that block's n). [MED]

## 7. Dead/unused in this build

`_InitEnemyAI` (empty), `_UsableEnemyBlock`, `_TooMuchEnemyTurning`, `_DoEnemyFeatureDelay`
(inlined as action 4), `_SquishAllEnemies` — no callers. Enemy types 5/6 have pool words but no
sprite branch (`_NewEnemy` leaves +0x3a unset → `_MoveEnemy` `LocationError`). Shipped LEVLs keep
words 22–23 at 0. [HIGH]
