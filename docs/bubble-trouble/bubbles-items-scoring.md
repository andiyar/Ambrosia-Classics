# Bubble Trouble X 1.1 — moving bubbles, eggs, jewels, dynamite, balloons, bonuses, EXTRA, multiplier, time bonus, score

Code readings. Naming: the game calls maze bubbles **blocks** (`block @ 0x3d210`, 35 slots ×
0x34 bytes) and the decorative rising air bubbles **Bubbles** (`_Bubbles_*`, 8 slots). "×mult" =
`_AddToScore(v, 1)`, which multiplies by `gBonusMultiplier` (unless the license code equals the
blacklisted 0x029348de929a84af). [HIGH]

## 1. Blocks (moving / animating maze objects)

`_NewBlock(col,row,dir,type,enemy,flag) @ 0001b94b` — first free of 35 slots ("none free" → error).
| off | meaning |
|---|---|
| +0x00 | state: 1 active, 2 popping, 3 static (lit dynamite, egg), 4 egg about to pop |
| +0x02 | start frame |
| +0x04 | type (cell code) |
| +0x06 | Rect; +0x0e previous Rect |
| +0x16 | direction; +0x17 col; +0x18 row; +0x19 aligned; +0x1b/+0x1c x/y offset (±40) |
| +0x1a | moves (1) or static (0) |
| +0x1d | enemies squished by this block so far |
| +0x1e/+0x20 | sprite set / frame |
| +0x28 | retire flag (slot freed in the draw pass) |
| +0x29 | enemy index (egg) |
| +0x2a | egg pop delay (15) |
| +0x2c/+0x2e/+0x30 | bouncing now / bounces done / bounce step |
Types: 10/15/16 bubbles move; 20 jewel moves; 30 cluster static anim; 40 pop (state 2);
52 dynamite moves when pushed (`flag=1`) or is a static lit fuse (`flag=0`, state 3); 60 egg (state 3). [HIGH]

### `_MoveBlock @ 0001cccb` — once per frame for every block with +0x1a set (from `_ProcessBlocks`)
1. A moving jewel/cluster becomes a normal bubble (type 10) if TimeBonus ≤ 0. [HIGH]
2. Unless bouncing: move **10 px/frame** (4 frames per cell); col/row step when the offset hits ±40. [HIGH]
3. Collisions every frame (rect inset 3): first enemy overlapping (states 1,3,4,5,6; slot order;
   a ballooned enemy's balloon is popped) → `_SquishEnemy(e, ++block.count)`; hero
   `_IsHeroCaught(blockRect, 1, 0)` → `_HeroCaught(2)`; flying/holding balloons overlapping → popped;
   bonus bubble hit (`_Bonus_WasHit`, bonus rect inset 8) → collected. [HIGH]
4. When aligned: jewel → `_CheckJewelMovement` (§3). Else `next = _GetNextObject(dir)`; if empty and not
   bouncing → keep going. Otherwise (blocked, incl. the playfield edge = 0x32):
   - non-rubber: retire, `gMaze[cell] = type`; dynamite → `_ExplodeBombBlock` immediately. [HIGH]
   - blue 15 / purple 16 (disasm 0001cfa2..0001d287): 4-frame squash animation in place (frames per
     direction: up 2,3,2(+sound),1; down 4,5,4,1; left 6,7,6,1; right 8,9,8,1), then the direction
     reverses and `bounces++`; blue retires at the cell when `bounces > 1`, purple when `> 2` — i.e.
     blue bounces once, purple twice, then rests at the next obstacle. [HIGH] (Guide: "Blue bubbles
     bounce once, and purple bubbles bounce twice".) ⚑ corrected (review 2026-10-03): the reversal sound
     differs by branch in `_MoveBlock @ 0001cccb` — a block **travelling right** (the branch that
     sets `dir = 3`, reversing it to the left) has no `_PlayMySnd(0x14)` at squash step 4; the
     `dir = 4` branch (a block travelling left, reversing right) plays it at steps 3 and 4. [MED]
5. Block–block: after all blocks moved, for each moving, non-retired block i, the first later block j
   (moving, non-retired) whose rect overlaps (strict) → both reverse direction (unless bouncing or
   already reversed this frame), sound 0x14. [HIGH] (Guide: "push a bubble into another that's
   already moving, it'll bounce back".)

`_CheckBlock` / `_NewHurtBlock`: dirty-rect redraw of a maze cell (the "hurt block" list drawn in the
draw pass); the consumers of LEVL w3/w4 (data-formats.md §2). No simulation state, no RNG.
⚑ corrected (review 2026-10-03) (names added). [MED]
⚑ corrected (plan 2026-10-03 btx-core) — **C5, step 3 of `_MoveBlock`: which balloons a block pops.** Only **flying** ones.
`_MoveBlock` calls `_Balloons_CheckSquishes(&local_24)`, and `_Balloons_CheckSquishes @ 00023ae8` tests
`if (*pcVar2 == '\x01') { cVar1 = _RectsCollide(param_1,puVar4); if (cVar1 != '\0') {
_Balloons_PopBalloon(iVar3); } }` (balloon state 1 only). A balloon **holding an enemy** pops through
the enemy instead. `_WasEnemySquished @ 00010eca` returns the first overlapping enemy in states
1/4/5/6/3 and ends `if (puVar1[iVar5] != '\x06') { return iVar3; } _Balloons_PopBalloon((int)*local_28);`
(`local_28` = enemy +0x43, its balloon index). A balloon **holding the hero** (state 2, holder 0xff)
is never popped by a block. Command: `python3 ghidra/find_func.py '_Balloons_CheckSquishes' --file
<dump>` (also `'_WasEnemySquished'`). [HIGH]

## 2. Popping and eggs

- Pop (`_CrushBlock`): pop block type 40, state 2, sprite 0x18; `_ProcessBlocks` advances the frame each
  tick and after frame 8 retires it and empties the cell. Hero pop +1 ×mult; enemy pops 0. [HIGH]
- `_KillEggBlock @ 0001be3b` (hero pushes an egg cell): egg block → pop (type 40, state 2), cell 40,
  +50 ×mult, popup, `_KillEnemy(enemy, 0)` (counts as squished), star group 3/4/5 by type. [HIGH]
- Egg timeline: enemies-ai.md §2.

## 3. Jewels

Placement `_PositionJewels @ 0001c6a6` (LEVL w12 = 3 or 4 jewels), each by
`_PositionSingleJewel @ 0001c544`: start at `GetRandomFast(1,14)`, `GetRandomFast(1,9)`; walk cells
(col 1..14 then next row, rows 1..9 wrapping to 1) until a normal bubble (10) that is not (7,6) and —
for the first 150 tries — whose row and column hold no jewel yet; after 500 tries the walk widens to
the full 16×11 grid. The bubble becomes a jewel (20). [HIGH] (Editor read-me: "tries to place the
jewels on a row and column that hasn't got any jewels, and also away from the edge" — consistent.)

Pushing rules: hero-and-input.md §4. Enemies never touch jewels. [HIGH]
Joining (`_CheckJewelMovement @ 0001ca05`, when a sliding jewel aligns): [HIGH]
- No join yet: a jewel slides **into** another jewel's cell (the next-cell test returns "keep going"
  for a jewel while no target exists); on arrival: `gJewelFound=1`, target = that cell, the cell
  becomes cluster 30 (new animating block), join count++.
- Target exists: a jewel whose next cell is the target keeps going and merges on arrival (count++);
  a jewel meeting any other object or non-target jewel stops there as a jewel.
- Each join: if `count < jewels−1` → partial: sound 9, stars, and **if active enemies < max, total
  enemies +1 and starfish pool +1** (a starfish will hatch). Else `_Jewels_GiveBonus`. (Guide: "Sammy
  the Starfish hatches if you join jewels when you've got rid of too many of your enemies".)
- `_Jewels_GiveBonus @ 0001c7c5`: if the target is on the border (col 0/15 or row 0/10) → 1000; else
  by level 1: 5000, 2: 6000, 3: 7000, 4: 8000, 5: 9000, ≥6: 10000; ×mult; then
  `_Balloons_CaptureAllEnemies`; jewels done. ⚑ corrected (review 2026-10-03): the jump table at 0x33a3c holds
  six **code addresses** (`19 c8 01 00 25 c8 01 00 31 c8 01 00 3d c8 01 00 49 c8 01 00 0d c8 01 00`),
  not the values; the immediates are at the targets — 0001c825 `$0x1388`, 0001c831 `$0x1770`,
  0001c83d `$0x1b58`, 0001c849 `$0x1f40`, 0001c80d `$0x2328`, 0001c819 `$0x2710`; border 0001c855
  `$0x3e8`. Values and level mapping unchanged.
  Matches the guide exactly. [HIGH]
- TimeBonus reaching 0 → `_Jewels_TurnToBlocks`: every 20/30 cell becomes 10 (if not done). [HIGH]

## 4. Dynamite (code 52)

- Size: one-stick sprite below level 12, two-stick from 12; blast shape switches at the same level. [HIGH]
- Pushed with room to slide → slides like a bubble; when it stops (any obstacle/edge) it explodes
  that frame. [HIGH]
- Pushed when blocked → `_CrushBlock` (+1 ×mult, a pop animation on the dynamite cell, maze keeps 52)
  and `_ActivateBombBlock`: new static fuse block (state 3, sound 0x18); `_ProcessBlocks` rewrites
  the maze cell to 52 every frame and explodes it when `frame > start + 60` (2 s). Pushing a lit
  fuse again: if more than 30 frames have passed → explode now, else nothing. A lit dynamite that
  could slide cannot be pushed (`_IsActiveBombBlock` → return 0). [HIGH] (Guide: "the fuse lights,
  and you only have a couple of seconds".)
- `_ExplodeBombBlock @ 0001c032`: cell := 0, sound 0x19; blast rects (strict overlap with enemy rects):
  - level < 12: one rect = the cell grown 40 px each side (3×3 cells incl. diagonals); star group 0xf.
  - level ≥ 12 (disasm 0001c0d8..0001c15e): A = cols c−1..c+1 × rows r−2..r−1; B = cols c−1..c+1 ×
    row r+2; C = cols c−2..c+2 × rows r−1..r+1 → union = 5×5 minus its four corners; star group 0x10.
    The running kill count is chained: A base 0, B base n_A, C base n_A+n_B. [HIGH]
  - ⚑ corrected (review 2026-10-03) — **original-engine quirk the replica must reproduce.**
    `_CheckForBombKills @ 000116eb` increments its count (`local_1e`) for **every** enemy in states
    1/3/4/5/6 whose rect overlaps, **without testing the dead flag `+0x47`**; `_SquishEnemy` ignores
    a dead enemy but k still advances. Rects A (rows r−2..r−1) and C (rows r−1..r+1) overlap on row
    r−1, cols c−1..c+1: an enemy there is killed by A and **re-counted by C**, inflating `base+k`
    (and so the points and the `_Bonus_SetNumEnemySquishes` multiplier step) for every later enemy
    in C — e.g. a second enemy in C scores 800 and steps the multiplier instead of scoring 400.
    Count dead-but-overlapping enemies too. [HIGH]
  Each enemy hit → `_SquishEnemy(e, base+k)` (200, 400, … and multiplier steps from the 3rd);
  balloons holding them pop; the hero inside a rect (inset 11 vs hero inset 8, not invisible)
  is killed (`_HeroCaught(2)`, once per rect that hits). [HIGH]
  Guide: "squishes everything one 'bubble width' away … the larger size … two bubble widths away" —
  consistent; the code adds the exact cut-corner shape.
⚑ corrected (plan 2026-10-03 btx-core) — **C1.** "once per rect that hits" is wrong: the hero dies at most once per blast.
`_CheckForBombKills @ 000116eb` ends `cVar1 = _IsHeroCaught(*param_1,param_1[1],1,1); if (cVar1 != '\0')
{ _PlayMySnd(0x2b,10,5); _HeroCaught(2); }`. `_IsHeroCaught @ 00021c79` requires
`*(short *)(PTR__hero_0003f014 + 2) == 2`, and `_HeroCaught @ 00021dfa` sets it to 3 first, so the
second and third rect find the hero in state 3. That is one `_HeroCaught(2)`: one `(0,1)` draw and one
star group 0xe (14 stars, replay-oracle.md §4.2 C2). Command: `python3 ghidra/find_func.py
'_IsHeroCaught' --file <dump>`. [HIGH]

## 5. Balloons (Normal the shark's bubble attack, and capture balloons)

30 slots × 0x2c at 0x379e0. [HIGH]
- `_Balloons_New(e)` (shark): spawns next to the enemy, offset 20 px in its direction, moving **8 px/
  frame**, anim period `GetRandomFast(4,7)`, sound 0xe; the collision box starts as a ~17 px square in
  front and grows to the full balloon over the first few frames. [MED] (box arithmetic summarised.)
- Flying, each frame (`_Balloons_Process @ 00024394`): move; first enemy in state 1/4/5 overlapping
  → it is captured (state 6, balloon holds it); else the hero (not trapped, not invisible) overlapping
  → hero trapped 90 frames (hero-and-input.md §6); else leaving the playfield or reaching a cell with
  an object (codes 10..60) → pop (4-frame anim). The shark can catch itself or other enemies. [HIGH]
- Holding an enemy: flashes after LEVL w15 frames, releases (`_ReleaseEnemyFromBalloon`) after LEVL
  w16 frames. ⚑ corrected (review 2026-10-03): the values step down per level, not in one jump —
  w15/w16 = 140/170 (L1), 130/160 (L2), 120/150 (L3), 110/140 (L4–12), 100/130 (L13–15), 90/120
  (L16–50) (Python `struct.unpack('>32h')` over LEVL_1..50); the replica uses the per-level data.
  Hero touching it (not trapped) → pop and
  `_PopEnemy` → +100 ×mult, enemy dead. Moving blocks and blasts also pop/kill. [HIGH]
- `_Balloons_CaptureAllEnemies @ 000240dd` (jewel bonus, EXTRA, capture bonus): every enemy in state
  1/4/5 gets a holding balloon at its position (`GetRandomFast(4,7)` each); eggs are not captured. [HIGH]
⚑ corrected (plan 2026-10-03 btx-core) — **C4, the shark balloon's collision box grows once, not to the full balloon.**
`_Balloons_New @ 000237f9` starts the anim frame (+0x1c) at 1 and the counter (+0x1e) at 0. The flying
arm of `_Balloons_Process @ 00024394` grows the box only under `if ((*(short *)(puVar7 + -5) < 2) && (sVar6 =
*(short *)(puVar7 + -3), *(ushort *)(puVar7 + -3) = sVar6 + 1U, 2 < (ushort)(sVar6 + 1U)))` (disasm
0002449f `cmpw $0x1,-0x5(%ebx); jg 0x24621`), so growth runs only while the frame ≤ 1. On the 3rd
flying call that reaches this step, the counter passes 2 and the frame becomes 2. The box is then
(top+8, left+8, top+31, left+26) (`+5 = left+8; +3 = top+8; +9 = left+0x1a; +7 = top+0x1f`, disasm
000244f9..0002453b). From then on frame 2 fails the gate. The frame-3 arm (0002451b: top+3, left+3,
top+32, left+26) and the frame-4 arm (00024544: the full balloon rect) cannot be reached from the
flying path. Command: `otool -tV <binary>` 0002449f..00024550; `python3 ghidra/find_func.py
'_Balloons_Process' --file <dump>`. [HIGH]
⚑ corrected (plan 2026-10-03 btx-core) — **C12, the hero balloon's holder −1 (narrows NR-6).** `_Balloons_CaptureHero @ 00023cbb`
sets the balloon to state 2 (`(&_gBalloons)[iVar7] = 2;`), start = frame h, holder
`(&DAT_00037a03)[iVar7] = 0xff;`, and on the hero `puVar4[0x4c] = 1; *(undefined2 *)(puVar4 + 0x4e) =
uVar5;`. `_ProcessHero @ 00022de0` clears the trap (`puVar12[0x4c] = 0;`) on the first frame where
`(uVar9 & 0xffff) <= *(ushort *)(puVar12 + 0x4e) + 0x5a` fails, i.e. frame h+91. This is state 2 only:
states 1/3 return first and state 4 skips the block. Later that frame, the state-2 arm of
`_Balloons_Process @ 00024394` tests `if ((puVar1[0x4c] == '\0') && (cVar2 =
_RectsCollide(local_2c,puVar1 + 0x14), cVar2 != '\0')) { _Balloons_PopBalloon(iVar8);
_PopEnemy((int)(char)puVar7[2]); }`. The box was set to the hero's 40×40 rect at capture and the
trapped hero cannot move, so the balloon pops: `_PopEnemy(-1)` runs on h+91 (the live path). The release
test after it (`start + *(short *)(PTR__level_0003f010 + 0x20)` (LEVL w16, ≥ 120) `< frame` →
`_ReleaseEnemyFromBalloon(-1)`) cannot be reached while the hero stays in state 2. [HIGH] (code path)
Residual path [MED, derived]: an enemy catches the hero in `_ProcessEnemies` on exactly frame h+91,
before `_ProcessHero` would clear the trap. The caught hero's `_ProcessHero` returns at state 3, so +0x4c
stays 1 and the hero-pop never fires. The balloon then reaches its release test at h+w16+1, while state
3→4 runs at the top of frame h+122 (`_MakeAllEnemiesDisappear` → `_Balloons_PopAll @ 00023f54`: state
2 → 3, no release). Release comes first only if h+w16+1 < h+122, i.e. w16 = 120 (levels 16–50):
release at h+121. A catch on h+90 or earlier puts the PopAll at the top of frame h+121 or earlier, so
there is no release. Never in levels 1–4 (w16 ≥ 140). Replica (plan Invariant 18): both calls with
holder −1 are no-ops.
New finding at append time (not in the plan) [MED, address arithmetic]: `_PopEnemy @ 00011254` with −1
does not test the index. `pcVar1 = PTR__enemy_0003f04c + param_1 * 0x5c; if ((pcVar1[0x47] == '\0') &&
(*pcVar1 != '\0')) { … _AddToScore(100,1); _NewPoint(…); puVar2[param_1 * 0x5c + 0x47] = 1; …
_gNumEnemiesSquished++ …; gMaze[…] = 0; }`. `_enemy` is at 0x393c0 (`nm -n`), so slot −1 starts at
0x39364 = `_environment` (0x39360) + 4, and its +0x47 byte is 0x393ab, between `_gCompGWorld`
(0x393a0) and `_gSpriteGWorld` (0x393b0). The original's effect therefore depends on runtime memory.
If `_environment`+4 is nonzero and 0x393ab is still 0, the first hero-balloon pop in a process awards
+100 ×mult with a popup, increments `gNumEnemiesSquished`, writes 0 to a maze cell indexed from that
memory, and sets 0x393ab = 1, so it fires at most once per process. If not, it does nothing. NOT
RESOLVED. The replica's no-op matches the original only in the second case. Command: `python3
ghidra/find_func.py '_Balloons_CaptureHero' --file <dump>` (also `'_Balloons_Process'`,
`'_ProcessHero'`, `'_Balloons_PopAll'`, `'_PopEnemy'`); `nm -n <binary>`.

## 6. Multiplier — `gBonusMultiplier` 1..5

`_Bonus_SetNumEnemySquishes(n) @ 0001a818` is called by `_SquishEnemy` **on every squish whose
running count n is ≥ 3** (and on n = 0). Jump tables at 0x33830/48/60/78 (dumped this session): [HIGH]

| n \ current | 1 | 2 | 3 | 4 | 5 |
|---|---|---|---|---|---|
| 3 | 2 | 3 | 4 | 5 | bonus |
| 4 | 3 | 3 | 4 | 5 | bonus |
| 5 | 4 | 4 | 4 | 5 | bonus |
| ≥6 | 5 | 5 | 5 | 5 | bonus |
"bonus" = +2000 ×mult (level ≤ 8) or +4000 ×mult (level ≥ 9) with a popup; multiplier unchanged.
Because the call happens at n=3, then n=4, …, a 4-fish push from 1x goes 1→2 (n=3) →3 (n=4); from
3x: →4 →5. This reproduces the guide ("three fish … increase one level … four fish two levels … at
5x, 2000 points up to level 8 and 4000 from level 9"). [HIGH]
Reset to 1 on new game and on every respawn (`_Multiplier_Reset(1)` at hero state 4→1); persists
across levels. Applies to every ×mult award and to the time bonus at level end. [HIGH]
`_Multiplier_Process`: the multiplier's flash animation only; no RNG, no state change.
⚑ corrected (review 2026-10-03) (name added). [MED]
⚑ corrected (plan 2026-10-03 btx-core) — **C8.** `_SquishEnemy @ 0001131b` does call `_Bonus_SetNumEnemySquishes(n)` for n ≥ 3 and for
n ≤ 0, but `_Bonus_SetNumEnemySquishes @ 0001a818` begins `_gBonus_NumEnemiesSquishedAtOnce = param_1;
if (param_1 < 3) { _gBonus_NumEnemiesSquishedAtOnce = 0; return; }`. So n ≤ 2 (including 0 and
negatives) never steps the multiplier. Only n = 3, 4, 5 and ≥ 6 reach the table above. Command:
`python3 ghidra/find_func.py '_Bonus_SetNumEnemySquishes' --file <dump>`. [HIGH]

## 7. Bonus bubbles — `_Bonus_Init @ 00019734`, `_Bonus_Process @ 0001a92b`

Two slots (`bonus @ 0x376a0`, 0x28 each). Per level: slot 0 always armed; slot 1 armed if
`GetRandomFast(0,100) < 50`. Launch frames: slot 0 `GetRandomFast(220,600)`, slot 1
`GetRandomFast(450,950)` (harp sound on the launch frame). Start: left = `GetRandomFast(70,530)`,
top 440 (bottom of the playfield), 40×40; rises 2 px/frame with a snaking x-table (19 steps) and a
21-entry random drift table (`GetRandomFast(0,4)` ×21 per level). Leaves when top < 0. [HIGH]
Type = `GetRandomFast(1,14)`; 3 → 14; 5..8 → `GetRandomFast(9,13)`; 14 → time value. Rewards
(`_Bonus_Reward @ 0001a2c5`): [HIGH]

| type | odds per bubble | reward |
|---|---|---|
| 1 | 1/14 | capture all enemies in balloons |
| 2 | 1/14 | `_RegenerateBlocks` (§10) |
| 4 | 1/14 | invisibility 300 frames |
| 9..13 | 9/14 combined (each letter 1/14 direct + 4/14·1/5 remap) | EXTRA letter E,X,T,R,A |
| 14 (and 3) | 2/14 | time bonus + v (cap 99950), v by level: L1–2 {500,800}; L3–5 {500,800,1000}; L6–10 {800,1000,2000}; L11+ {1000,2000,3000,4000,5000} (uniform) |
| 5..8 | 0 (remapped) | would call `_Multiplier_Change` (dead) |
Collected by the hero touching it (bonus rect inset 8 vs hero rect, hero state 2) or by a moving
bubble (`_Bonus_WasHit`). After collection it floats 30 frames then disappears. [HIGH]
Guide: "pop this bonus bubble, either by swimming into it or squishing it with a bubble". Consistent.

## 8. EXTRA — `_EXTRA_Change @ 0001a163`

Letters persist across lives and levels (reset only at game start, and at a level change if the
completion animation is still running). Completing all five: +1 life (`_AddHero`, cap 9), +10000
×mult, capture all enemies, letters cleared. [HIGH] (Guide: extra life, 10,000 points, enemies
captured.)

## 9. Time (level) bonus — `_TimeBonus_*`

- Start (`_TimeBonus_Reset @ 00006930`): level < 5: 2500; < 10: 3000; < 15: 3500; ≥ 15: 4000. [HIGH]
- `_TimeBonus_Process @ 00006a15`: while not end-of-level and bonus > 0: only in hero state 2, every
  time `frame > timer + 30` → −50 (one step per 31 frames; the timer is re-armed to the current frame
  whenever the hero is not in state 2). Below 500: warning beep each step. Reaching 0: "Hurry up"
  sounds/notice, jewels revert (§3). [HIGH]
- `_TimeBonus_Increase` (bonus-bubble time reward, §7): adds to the bonus with the cap 0x1866e
  (99950). ⚑ corrected (review 2026-10-03) (name added). [MED]
- Bonus ≤ 0 effects elsewhere: no more spawns (enemies-ai.md §1), enemies always home and speed up
  (§4a), moving jewels become bubbles. [HIGH] (Guide: "No more enemies will appear … the ones that are
  left will turn nasty".)
- Level end `_TimeBonus_CountDown @ 00006dcb`: if mult > 1, bonus ×= mult (cap 99950); then transfer
  to score in chunks (500 if ≥ 50000, 200 if ≥ 10000, 100 if ≥ 5000, else 50) with `_AddToScore(chunk,
  0)` (no second multiplication), 3 ticks per chunk (`_WaitFor(1)` ×3). [HIGH]

## 10. Regenerate bubbles — `_RegenerateBlocks @ 0001c3db`

Six times: random start (1..14, 1..9), walk forward skipping the hero's row and column, until a cell
that is empty now and held a normal bubble in the level's original layout (`gMazeCopy == 10`). The
new bubble is **blue (15)** below level 11; from 11 `GetRandomFast(0,1)`: 0 → purple 16, 1 → blue 15.
An enemy overlapping the new bubble (inset 3) is squished (n=1). A walk that wraps the grid twice
gives up that one. [HIGH]

## 11. Air bubbles (cosmetic, but they consume RNG) — `_Bubbles @ 000169e2`

Gated by bool pref 0x36. Every `delay` frames (table, 25..90) launch a group: if the hero is playing,
aligned, facing left/right and 140 frames passed since his last group → small group at his mouth;
else a group from a random-table x at y 385. Each bubble `_Bubbles_New` draws `GetRandomFast(5,9)`;
max 8 alive (none drawn when full); a bubble dies when it rises above y 0 (freed in the draw pass).
Death also emits group 0xb. [HIGH] — they matter only for RNG order (replay-oracle.md §4).
⚑ corrected (review 2026-10-03): the type-0xb **stars'** `(0,1)` draw has a further pre-draw exit besides the
60-star cap — `_NewStar @ 0000329a` returns before drawing when the star rect leaves the playfield
(x 0..640, y 0..440); edge squishes draw fewer numbers. Details: replay-oracle.md §4.2. [HIGH]
⚑ corrected (plan 2026-10-03 btx-core) — **C7, air-bubble death and delayed bubbles.** `_Bubbles_Process @ 00016b1a`:
`if (*(short *)(pcVar11 + 0xe) < 0) { pcVar11[0x21] = '\x01'; }`. The bubble rect is at +0xa (top
+0xa, left +0xc, bottom +0xe, right +0x10, as written by `_Bubbles_New @ 00016349`), so a bubble is
marked dead when its **bottom** is above y 0, not its top. `_Bubbles_New` sets `+0x22` (delayed) when
its 4th argument (the delay) is ≥ 1. Groups 9, 10 and 0xb of `_Bubbles_NewGroup @ 0001657e` pass
delays 2/3/4/6 to some of their bubbles. A delayed bubble runs only `if ((int)((int)*(short *)(pcVar11 +
0x24) + (uint)*(ushort *)(pcVar11 + 2)) < (int)(uVar6 & 0xffff)) { pcVar11[0x22] = '\0';
pcVar11[0x20] = '\x01'; } goto LAB_00016cc1;`. Until `delay + start < frame` it skips movement, its
snaking index **and** the shared `_gBubbles_RandDriftIndex` advance. Command: `python3
ghidra/find_func.py '_Bubbles_Process' --file <dump>` (also `'_Bubbles_New'`,
`'_Bubbles_NewGroup'`). [HIGH]

## 12. Score events (all ×mult unless noted)

| event | points | function |
|---|---|---|
| squish, n-th by one block/blast | 200·2^(n−1) for n=1..4, 3200 for n ≥ 5 (and n=0) | `_SquishEnemy` |
| 3+ in one push at 5x | +2000 (≤ L8) / +4000 (≥ L9) per extra squish | `_Bonus_SetNumEnemySquishes` |
| pop a ballooned enemy | 100 | `_PopEnemy` |
| pop a bubble (hero) | 1 | `_CrushBlock` |
| pop an egg | 50 | `_KillEggBlock` |
| all jewels joined | 5000..10000 by level, 1000 on the border | `_Jewels_GiveBonus` |
| all normal bubbles gone | 2000, level ends | `_PlayGame` |
| EXTRA complete | 10000 | `_EXTRA_Change` |
| level end | remaining time bonus × mult (not re-multiplied) | `_TimeBonus_CountDown` |
Extra life at 10000, then 40000, 80000, +40000 each (any source, incl. countdown). [HIGH]
Score storage: `gStackScore` with a shadow `*gEScore = score + 0x129` (lives +0x10d, level +0xc0)
checked every frame by `_CheckForHacking` (sets `gHacked`, read by nothing). [HIGH] Guide: "200 for
every fish … 200, 400 … 800 for the third" — consistent.
