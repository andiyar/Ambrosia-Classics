# Deimos Rising 1.0.6 — level loading, the scroll, level-object spawning, level progression

Reader I, wave 1 (2026-10-03). Code readings only; nothing is behaviour-verified. Conventions
as in pak-format.md. **Scope:** G_Background.cc and its scroll helpers `0x1000f7a0–0x10010860`
(the brief's range `0x1000fbc0–0x10010800`, widened to the module's init/level-start functions
`FUN_1000f7a0`, `FUN_1000fa10`, `FUN_1000fa90` and the console handlers Ghidra left undefined at
`0x100103b0–0x10010860`, because NOT-RESOLVED #17 lives there); G_Level.cc `0x10011a70–0x100122f0`;
`FUN_10033090` (spawn at row), `FUN_10035900` (pending list), the spawn request `FUN_10033220`
only for the level-object path; G_Game.cc `FUN_100051a0` (session), `FUN_100064d0` (level
start), the level-end branch of `FUN_10006b50`, `FUN_10007170` (go to next level); the `leve`
data side. **Out:** the entity state machine and the boss gate (bosses reader), group member
placement (waves-and-enemies.md §4), player physics, weapon/score arithmetic (only pointed to),
registration/demo (noted only), level editor.

Evidence: disassembly `$W/disasm-levelscroll.txt` and `$W/disasm-levelscroll-2.txt`
(`$W` = `/Users/andiyar/ghidra-proj-deimos`), made with a copy of `DisasmFuncs.java` extended to
disassemble address ranges (`DisasmMix.java`, scratchpad) against `$W/work-levelscroll`. TOC
r2 = `0x100e6330`, so `-0x6208(r2)` = `0x100e0128` etc. Floats/tables from `$W/mem/*.bin`
(TOC slots point into the code image `10000000.bin`). Data from `$W/data/Game/` (decoded paks).

## 1. Scroll state (G_Background.cc globals)
| global | r2 disp | type | meaning | written by | evidence |
|---|---|---|---|---|---|
| `0x100e0128` | −0x6208 | int | vertical scroll speed, px per logic tick: 1 running, 0 paused (−1 only via the debug REVERSE command) | `FUN_1000fa90` (=1), `FUN_1000ffc0` (=1), `FUN_1000ffe0` (=0), `FUN_10010000` (=0 at level end), console | [HIGH] `1000faac li r0,0x1 / 1000fab8 stw r0,-0x6208(r2)`; `1000ffcc li r0,0x1 / stw r0,-0x6208(r2)` |
| `0x100e012c` | −0x6204 | byte | level-object spawning disabled (debug `LEVELSPAWNS` toggle `FUN_10010860`) | console only | [HIGH] `1000fa2c lbz r0,-0x6204(r2) / bne` and `10010068` |
| `0x100e0130` | −0x6200 | int | pixels scrolled this tick (old top − new top; 0 when paused) | `FUN_10010220` | [HIGH] `10010320 lwz r0,0(r30) / subf r0,r0,r31 / stw r0,-0x6200(r2)`; reader `FUN_1000fed0` |
| `0x100e0134` | −0x61fc | int | media-mask element size = map width / mask width | `FUN_1000fbc0` | [HIGH] decompile `_DAT_100e0134 = local_7c / local_84` + assert "sPriv_MediaMaskElementSize >= 1" |
| `0x100e0138` | −0x61f8 | ptr | media-mask image | `FUN_1000fbc0`, freed `FUN_10010360` | [HIGH] |
| `0x100e013c` | −0x61f4 | byte | set 0 at level start; no reader in the dump | `FUN_1000fa90` | [MED] (xref script over the dump: only writer) |
| `0x100e0140` | −0x61f0 | int | last horizontal step taken (−1/0/+1) | `FUN_100100b0` | [MED] no reader found (xref) |
| `0x100e0144` | −0x61ec | int | horizontal view offset, [−32, 31] | `FUN_100100b0`; 0 at level start | [HIGH] §5 |
| `0x100e0148` | −0x61e8 | byte | level-end flag (scroll finished) | `FUN_10010000`; 0 at level start | [HIGH] `10010058 stb r3,-0x61e8(r2)` |
| `0x100e014c` | −0x61e4 | int | scroll progress = rows travelled + 481, clamped to [0, map bottom] | `FUN_1000fa90`, `FUN_10010220` | [HIGH] §3 |
| `0x100e5abc..5ac8` | r2−0x874 | Mac Rect | copy of `#background_RECT` (top 0, left 0, bottom 3600, right 480) | `FUN_1000fa90` | [HIGH] `1000fad4 lwz r0,0x60(r27) … 1000fb04 stw r3,0xc(r30)` |
| `0x100e5acc..5ad8` | r2−0x864 | Mac Rect | visible window in map rows: top, left=32, bottom=top+480, right=32+416 | `FUN_1000fa90`, `FUN_10010220` | [HIGH] §2 |

There is **no scroll-speed data key**: the 1 px/tick is a literal in two places (`FUN_1000fa90`,
`FUN_1000ffc0`). The "Game Speed" divider (engine-loop.md §4) changes ticks per second, not px per
tick. [HIGH — every writer of `0x100e0128` listed above; xref script over the dump]

## 2. Level start: initial window and the initial spawn pass (closes NOT-RESOLVED #17, part 1)
`FUN_1000fa90(levelInfo) @ 1000fa90` (called once per level from `FUN_100064d0`):
speed = 1, level-end = 0, scrolled = 0, h-offset = 0, h-step = 0, `0x100e013c` = 0; loads the map
and mask (`FUN_1000fbc0`, §9); copies the RECT; then
```
1000fae4  li r0,0x20          ; window.left = 32
1000fb18  li r3,0x37 ; bl FUN_10020250      ; PermFloat 55 VisibleGameHeight = 480
1000fb28  lwz r0,0x0(r28)     ; rect.bottom (0x100e5ac4) = 3600
1000fb38  subf r0,r4,r0 ; 1000fb3c stw r0,0x0(r31)   ; window.top = 3600 - 480 = 3120
1000fb40  li r3,0x36 ...      ; window.right = 32 + PermFloat 54 VisibleGameWidth (416) = 448
1000fb80  add r0,r0,r4 ; stw r0,0x8(r31)              ; window.bottom = top + 480 = 3600
1000fb9c  addi r0,r3,0x1 ; 1000fba0 stw r0,-0x61e4(r2) ; progress = 480 + 1 = 481
```
→ **initial window top = 3120** (map rows 3120–3599 visible), progress = 481. [HIGH — listing;
PermFloat 54/55 = 416/480 from `Game[gafl].flli.txt` items 54/55]

After the entity-group system has built the pending list (`FUN_10032e60` → `FUN_10035900`, §6),
`FUN_100064d0` calls `FUN_1000fa10 @ 1000fa10`:
```
1000fa2c  lbz r0,-0x6204(r2) ; bne -> skip       ; spawning disabled?
1000fa3c  lwz r3,0x0(r3)     ; top (3120)
1000fa48  subi r3,r3,0x41    ; top - 65
1000fa4c  subf r30,r3,r0     ; n = bottom - (top - 65) = 3600 - 3055 = 545
1000fa5c  subf r3,r29,r0 ; bl FUN_10033090        ; spawn row (bottom - i), i = 0..544
```
→ every level object with **yLoc 3056…3600** spawns at level load, before the first tick
(rows 3600 down to 3056 = top − 64). [HIGH — listing]
Census: 13 of 565 placements are in this band (Python over the 12 decoded levels; max yLoc in
any level 3309, min 78; no yLoc outside [0, 3600]). [HIGH — tool output]

## 3. Per-tick scroll step, spawn timing, level-end detection
Called once per logic tick from `FUN_10006b50` (update world), after the players/score bar and
before the entity update (engine-loop.md §3 order).
`FUN_10010000 @ 10010000`:
```
10010014  bl FUN_10010220                     ; advance (below)
10010018  lwz r0,-0x6208(r2) ; bne 0x10010038 ; speed != 0 ?
10010024  (speed == 0) return levelEnd ? 1 : 0
1001003c  lwz r0,-0x61e4(r2) ; lwz r4,0x8(r3) ; cmpw ; blt 0x10010068   ; progress < rect.bottom ?
1001004c  else: progress = bottom; levelEnd = 1; speed = 0; return 1
10010068  lbz r0,-0x6204(r2) ; bne -> return 0                          ; spawning disabled
10010078  lwz r3,0(top) ; subi r3,r3,0x40 ; bl FUN_10033090             ; spawn row top-64
```
`FUN_10010220 @ 10010220` (advance): if speed == 0 → scrolled = 0; else top −= speed,
progress += speed (clamped to [0, rect.bottom]), window.bottom −= speed; if top < 1 → top = 0,
bottom = 480; if bottom > map-buffer bottom (`FUN_1000a530` bounds) → bottom = map bottom,
top = bottom − 480 (reverse-scroll guard); scrolled = old top − new top. [HIGH — listing
`10010254…10010328`]

Consequences (all [HIGH] arithmetic on the listings above, no pauses assumed unless stated):
- Scroll tick k (the k-th tick in which speed was non-zero; k = 1 on the level's first tick,
  game time 0) leaves top = 3120 − k and spawns **row 3056 − k**.
- A placement with yLoc Y < 3056 spawns on scroll tick **k = 3056 − Y**; with no pause before it
  that is **game time 3055 − Y** (game time is reset to 0 by `FUN_100064d0` and incremented after
  each tick's update, engine-loop.md §3).
- Spawn match is exact integer equality `fctiwz(yLoc) == row` (`100330f4 lfs f0,0xa0(r29) /
  fctiwz / cmpw r27,r0 / bne`); rows advance by exactly 1, so no row is skipped while speed is 1.
  Rows below 0 are rejected (`10033098 or. r27,r3,r3 / blt`).
- **Level end**: progress reaches 3600 on scroll tick k = 3600 − 481 = **3119** (top = 1). That
  tick does not spawn (its row would be −63). Rows spawned per tick therefore run 3055 … 0 (the
  last useful one, row 0, on k = 3056). Minimum level length = **3119 scroll ticks** (≈104 s at
  the ≤30 ticks/s cadence of engine-loop.md §4) plus all paused ticks.
- The level-end flag is sticky: from then on speed stays 0 (`FUN_1000ffc0` refuses to resume when
  the flag is set, `1000ffc0 lbz r0,-0x61e8(r2) / bnelr`) and `FUN_10010000` returns 1 every tick.
- Level end is detected **only** by the scroll reaching the map top. It is not a sentinel unit and
  not a notice; `Notice_LevelEnd` is a *consequence* (§8). [HIGH — the only writer of the flag]

## 4. What pauses and resumes the scroll (mechanism)
Every tick, the last call of `FUN_10006b50` is:
```c
  cVar4 = FUN_10033850(gameTime);          // update all entity groups
  if (cVar4 == '\0') FUN_1000ffc0();       // resume: speed = 1 unless level ended
  else               FUN_1000ffe0();       // pause:  speed = 0
```
`FUN_10033850` returns 1 iff, during that update, at least one entity reached the state-update
point with its current state's `statePauseVerticalScrolling` byte (state +0x346) set (`local_60 =
1` at `LAB_10033d70`, after the spawn countdown `entity+0xb0` has run out and after the
Delete/Destroy/state-change handling of that tick). [HIGH for the call/branch and the +0x346 test
(decompile of `FUN_10033850` lines 238–240, key from waves-and-enemies.md §2); MED for the exact
set of entities that count — the bosses reader owns that loop]
Properties that follow [HIGH]:
- Pause state is recomputed every tick; there is no latch. The decision made in tick t applies to
  the scroll advance of tick t+1 (FUN_10010000 runs before FUN_10033850 in the same tick).
- While paused nothing spawns (FUN_10010000 skips `FUN_10033090` when speed is 0) and resumption
  continues from the same row, so pauses only shift spawn times, never drop rows.
- `stateDestructIfVerticalScrollingNotPaused` (+0x352) reads `FUN_1000fff0` (speed == 0) in the
  same update (`FUN_10033850` decompile line ≈283). [HIGH call; MED order]
- The debug console commands SCROLL/SCROLLING (`0x100104f0`, toggle 1↔0) and REVERSE
  (`FUN_10010570`, toggle 1↔−1) are overwritten on the next tick by the line above unless an
  entity is pausing (their help text: "Maybe. Probably not."). No other writer of the speed
  exists. [HIGH — listings `100104f0…1001056c`, `10010570…100105f8`]

## 5. Horizontal shift (closes NOT-RESOLVED #17, part 2)
`FUN_100100b0(char right) @ 100100b0`: step = right ? +1 : −1; offset += step; clamp: below −32 →
−32, above 31 → 31 (`100100dc cmpwi r0,-0x20 / bge`, `100100fc cmpwi r0,0x1f / ble`); the step
actually taken is stored in `0x100e0140`. Range **[−32, +31]**. [HIGH]
**Driver**: only caller is the player update `FUN_10028170`, once per tick **per active player**,
inside the branch `player+0xc4 (active) != 0 && player state +0xc6 == 4`:
```
100291ec  lbz r15,0x1ff(r31)    ; input byte [3] = left
100291f0  lbz r16,0x1fd(r31)    ; input byte [1] = right
100294e4  cmplwi r15,0x0 ; beq 0x10029518
10029508  li r3,0x0 ; bl FUN_100100b0    ; left held  -> offset - 1
10029518  cmplwi r16,0x0 ; beq
10029520  li r3,0x1 ; bl FUN_100100b0    ; else right held -> offset + 1
```
So the shift is driven by the **left/right input**, not by the ship's x: 1 px per tick while a
direction is held, left wins if both, and in a two-player game both players' inputs add (each
call moves it). It is reset to 0 at every level start. [HIGH — listing; input byte map
engine-loop.md §8; the state-4 meaning "playing" is MED]
**Consumers** (`FUN_100100a0` getter): terrain draw `FUN_10010120` takes source x = offset + 32
(`10010138 lwz r3,-0x61ec(r2) / addic. r0,r3,0x20`, clamped ≥ 0) — map columns offset+32 …
offset+447; entity draw `FUN_10012fa0` and shadow draw `FUN_10013460` draw at
`x − offset` for every entity whose byte +0x18 is set (`10012fe0 lbz r0,0x18(r25)`; the base
constructor sets +0x18 = 1 and `FUN_100144a0` clears it only for draw layer `hud `); particle
draw `FUN_10043ba0`. Net effect: a camera pan over a 480-wide world shown 416 wide; HUD-layer
entities do not pan. [HIGH for the reads; MED for "all non-HUD entities" (default +0x18 = 1 in the
base constructor `FUN_10012650`, read in the decompile only)]

## 6. From `leve` placement to entity group
### 6.1 `leve` grammar (data side) and loader
Key table as in waves-and-enemies.md §1 (parser `FUN_100122f0`). Additions from this reading:
- Level header only (`objectList == 0`) is parsed when building the order list and when the
  level-select screen reads names; the 0x18-byte objects are built only when a list is passed
  (`FUN_100122f0`: `if (param_3 != 0)`). [HIGH]
- Unknown `#unit_ID` (no `unde` tag): the object is dropped **and** the loop bound
  `#numObjects_INT` (re-read from +0x278 each iteration) is decremented while the index still
  advances, so every dropped object also loses the last object of the file
  (`1001257c lwz r3,0x278(r26) / subi / stw … 1001258c lwz r0,0x278(r26) / cmpw r29,r0 / blt`).
  Latent: every one of the 565 placed IDs exists among the 386 `unde` tags (Python check). [HIGH]
- `#layer_ID` (obj+0x04) is **never read at run time**: `FUN_10035900` reads obj +0x0, +0x8, +0xc,
  +0x10, +0x14, +0x15 only (listing `100359a4…10035a88`). The run-time layer comes from the unit
  definition (§6.2). In all 565 placements `#layer_ID` agrees with the unit's
  `#isGroundBased_BOOL` (Python cross-check), so data never exercises the difference. [HIGH]

### 6.2 Pending list — `FUN_10035900(objectList) @ 10035900`
Called by `FUN_10032e60` (entity-group reset at level start). Frees any old pending list
(`FUN_10035810`), creates `0x100e022c` (r2−0x6104), and for each level object in file order:
unit = `FUN_1003d2f0(id)` (unit-def lookup, unit+4 = tag); if absent, log "NOTE: An invalid Unit
ID …" and skip; else `FUN_1003e680` (load the unit's resources) and append a 0xbc-byte group
record:
| group off | value | evidence |
|---|---|---|
| +0x94 | −1 (serial not yet assigned) | `10035a58 stw r5,0x94(r24)` (r5 = −1) |
| +0x98 | unit ID | `10035a4c stw r4,0x98(r24)` |
| +0x9c | float(xLoc), then −32.0 if the unit is ground based | `10035a9c fsubs / stfs f0,0x9c(r24)`; `10035abc lwz r3,0x8(r31) / subis r0,r3,0x6772 / cmplwi r0,0x6e64 / bne` ; `10035ad0 lfs f0,0xc(r28) / fsubs` |
| +0xa0 | float(yLoc) (map row) | `10035ab8 stfs f0,0xa0(r24)` |
| +0xa4/+0xa8/+0xac/+0xb0 | 0 | listing |
| +0xb4 | headingDegrees | `10035a74 stw r3,0xb4(r24)` |
| +0xb8 | isStationary | `10035a80 stb r3,0xb8(r24)` |
| +0xb9 | enableTerrainEffects | `10035a88 stb r0,0xb9(r24)` |
The ground test is **unit+0x08 == `grnd`**, and unit+0x08 is set by the unit loader
`FUN_1003fc50` from `#isGroundBased_BOOL` (+0x125): `1003fd20 lbz r0,0x125(r30) / beq → 'air '
else 'grnd' / stw r0,0x8(r30)`. The constant: r28 = TOC slot `0x100df440` → `0x100d7204`, +0xc =
**32.0** (`python3 -c` over `10000000.bin`: floats at 0x100d7204 = 0.5, 0.7, 0.9, 32.0, 0.0, −100.0).
[HIGH]

### 6.3 Spawn at a row — `FUN_10033090(row) @ 10033090`
For each pending record (iteration over the initial count; `FUN_10000c00` unlinks the current
node and backs the iterator up to its predecessor, so removal never skips a neighbour — list
helpers `FUN_10000e10`/`FUN_10000c00` read): if `fctiwz(+0xa0) == row`, build a 0x2c-byte spawn
request on the stack from the template at `0x100eb41c` (r2+0x50ec; bytes = `'none'`, 0…, +0x14 =
0xff, +0x28 = 1.0f) and overwrite: +0x00 unit, +0x04 x (+0x9c), +0x08 y (+0xa0), **+0x0c = 1**
("y is a map row"), +0x18 heading, +0x1c stationary, +0x1d terrain effects; call
`FUN_10033220(&req, 0, 0)`; then **unconditionally** unlink and free the pending record
(`100331b0 bl FUN_10033220 / 100331c4 bl FUN_10000c00`). [HIGH — listing `1003310c…100331ec`]
Same-row objects spawn in file order in the same call. [HIGH]

### 6.4 The request — `FUN_10033220` (level-object path only)
- Rejections (object lost for good, because §6.3 already removed it): group size
  `FUN_100369f0(unit)` ≤ 0; `canBeSpawnedOnlyWhenPlayersActive` (+0x12a) with no active player
  (also passes if `DAT_100e0214` and `FUN_10006110`/`FUN_10005cf0` agree — not read);
  `doNotSpawnIfTypeAlreadyExists` (+0x118) and one exists (`FUN_10036af0`); entity limit:
  `count + size` must be < 1001 (`0x3e9`), else a once-per-level "Reached Entity Limit" message.
  [HIGH for the tests and their order (decompile, matching listing `10033220…`); MED for the
  callee roles]
- Position: group +0x9c = req x unchanged; group +0xa0 = req y if +0x0c == 0, else
  **y − window.top** (`10033524 lbz r0,0xc(r24) / beq; bl FUN_1000fec0; fctiwz; subf r0,r0,r3;
  neg r0,r0; …; stfs f0,0xa0(r26)`). For a level object on the per-tick path, y − top =
  row − top = **−64**; on the load pass y − 3120 ∈ [−64, 480]. [HIGH]
- Heading: if req +0x0d (0 in the level template) → always the placed heading; else the unit's
  `initialHeadingSetInEditor` (+0x124; listing `1003358c lbz r7,0x10c(r27)` with r27 = unit+0x18)
  decides placed heading (+ random `initialHeadingTolerance`, `FUN_10035cd0`) vs the unit's
  `initialHeading`. [HIGH for the branch; tolerance arithmetic MED]
- `isStationary`/`enableTerrainEffects` go to entity +0x13c/+0x13d (`FUN_10035cd0`). [HIGH reads;
  their effect is the movement reader's]
- Members: `FUN_10035bf0` → `FUN_10035cd0` per member; placement offsets and staggered spawn
  countdown as in waves-and-enemies.md §4. Entity +0x19 ("air") = unit+0x08 == `air `
  (`10035f8c lwz r5,0x8(r21) … 10035fa0 stb r0,0x19(r28)`). [HIGH]

## 7. Coordinate frames (engine-loop.md §5 refined)
| frame | x | y | relation | evidence |
|---|---|---|---|---|
| map (terrain image, `leve` rows) | 0…479 | 0…3599 (0 = top) | — | RECT check in `FUN_1000fbc0` |
| world (entity +0x00/+0x04) | −32…448 for ground; air uses xLoc as is | 0 = top of the visible window | **map x = world x + 32, map y = world y + top** | `FUN_10016880`: `local_70 = x + 0x20; local_6c = y + FUN_1000fec0()` before the water test; `FUN_10012fa0` terrain-draw mode adds 32 and top |
| game-area buffer | world x − hOffset | world y | entities with +0x18 set, terrain source x = hOffset + 32 | §5 |
| screen | buffer x + 32 (left border) | buffer y | 32 + 416 + 32 + 160 layout | engine-loop.md §5 [MED there] |
- Placement x → world x: **ground units xLoc − 32; air units xLoc unchanged.** So an air unit at
  xLoc 178 sits over map column 210 at offset 0, a ground unit at xLoc 178 over column 178. [HIGH
  for the arithmetic; why the editor does this is not known]
- Ground entities (+0x19 == 0) ride the terrain: each update adds the tick's scrolled pixels to
  their y (`10012cc0 lbz r0,0x19(r3) / bne; bl FUN_1000fed0; … fadds; stfs f0,0x4(r30)`), then
  add velocity. Air entities do not. [HIGH]
- Cull: the entity update deletes an entity whose `FUN_10012ca0(e, 128, 1)` is false — x outside
  [−128, 416+128] or y outside [−128, 480+128], give or take the half-extents (the exact mode-1
  expression is not settled). The spawn row y = −64 is inside that margin either way. [HIGH for
  the call and margin `cVar10 = FUN_10012ca0(iVar15,0x80,1)` → `+0xcb = 1`; MED for the bounds]
- Whether entity (x, y) is the sprite centre or corner is not settled here (the half-extents
  +0x2c/+0x30 = w/2, h/2 are computed by `FUN_10012940`, suggesting centre). [MED]

## 8. Session and level progression (G_Game.cc)
Game struct at `PTR_DAT_100defd0` (0x180 bytes, zeroed once): fields used here:
| off | meaning | evidence |
|---|---|---|
| +0x00/+0x04 | player 1/2 objects (0x36c each, created per session) | `FUN_100051a0` |
| +0x08 | session running | loop condition |
| +0x09 | level complete (tallies done) → go to next level | `FUN_10006b50` sets, `FUN_10007170` reads |
| +0x0a | no player alive (game over in progress) | `FUN_10006b50` |
| +0x0d | all levels completed | `FUN_10006b50`; returned to caller (`param_2[0x14]`) |
| +0x0e | stopped by the unregistered-level limit (out of scope) | `FUN_100064d0` |
| +0x10 | levels started this session (0 before the first) | `FUN_100064d0` `+0x10 += 1` |
| +0x14 | current sector (1–12) = `FUN_10005cd0()` | `FUN_100064d0` |
| +0x18 | current level tag (`none` = no more levels) | |
| +0x1c | game time, **reset to 0 at every level start** | `FUN_100064d0` first statement |
| +0x29 / +0x2c | level-end handled / its game time | `FUN_10006b50` |
| +0x39 | level ending (passed to player update as its last arg) | `FUN_10006b50` |
[HIGH for each write quoted; the labels of +0x0a/+0x39 are MED (usage)]

**Session** `FUN_100051a0(request{levelTag, numPlayers, filmFlag}, results)`: the start level is
any of the 12 (level select); sector = `FUN_10011e30(tag)`; level info loaded with
`FUN_10011fd0`; each player set up once by `FUN_10026410(player, index, numPlayers, 0, sector)`;
then `FUN_100064d0(film, info)` and the frame loop (engine-loop.md §3). Results per player:
alive flag, score (`FUN_100299f0`, de-obfuscated player +0xb0), last level tag (+0xc0), cheated
flag (+0xbd); plus +0x0d and +0x0e. [HIGH reading]

**Level start** `FUN_100064d0(film, info) @ 100064d0`, in order: game time = 0; flags cleared;
accuracy counters reset (`FUN_10007130/7150/7280`); first level → load `+0x18`; later level →
sector = sector(tag) + 1, and if > `FUN_10011de0()` (= 12) the tag becomes `none`; else load it.
`+0x10 += 1`. Tag `none` → stop music, session ends (`+0x08 = 0`). Otherwise: `+0x14` = sector;
`FUN_1002b3a0(sector)` (per-sector setup of `PEAA`/`PEAG`/`SPEC` items — not read); music; each
player `FUN_100269a0(player, tag, 0)`; message/debris/particle lists reset; `FUN_1000fa90` (§2);
`FUN_10032e60` (entity groups + pending list); free the parsed object list; notices reset;
`FUN_1000fa10` (load-time spawns, §2); spawn `PermObjectID(sector + 9)` = **Notice_Level_NN**
at game-area (416·0.5, 480·0.5) = **(208, 240)** with req +0x0c = 0 (template `0x100e3ca4`,
r2−0x268c; factor `*(float*)(0x100d6354+8)` = 0.5 from the code image); score bar redraw;
first terrain draw. [HIGH — listing `1000682c…100068c4` for the notice; call order from the
decompile]

**Level end** (branch of `FUN_10006b50` when `FUN_10010000` returns 1), listing `10006d9c…`:
1. `+0x39 = 1` every tick from now on.
2. First such tick (`+0x29 == 0`) and someone alive (`+0x0a == 0`): if **sector == 12 and
   levels-started == 12** → `+0x0d = 1` (`10006de8 lwz r0,0x14(r31) / cmpw r0,r3 / bne;
   10006df4 lwz r0,0x10(r31) / cmpw r0,r25 / bne; li r0,1; stb r0,0xd(r31)`). Spawn
   `PermObjectID(23)` **Notice_AllLevelsCompleted** if set, else `PermObjectID(22)`
   **Notice_LevelEnd**, at (208, 240). `+0x29 = 1`, `+0x2c = time`; each active player
   `FUN_10027de0(p, 1, 0)` (not read); `FUN_100072c0(time)` (ground-accuracy tier). If nobody
   is alive, only `+0x29 = 1` (the game-over path ends the session). [HIGH]
   ⇒ The all-levels finale needs **all 12 sectors played in one session from sector 1**; a
   session started at a later sector shows Notice_LevelEnd after sector 12 and then ends
   (next `FUN_100064d0` finds sector 13 > 12 → `none`). [HIGH — follows from the two reads]
3. Later ticks: `FUN_100075e0(time)` runs the accuracy tally; once it reports done, each active
   player runs the coin bonus `FUN_10027670` (until `FUN_10027db0`) and the money counter
   `FUN_10027930`; when all are done `+0x09 = 1`. [HIGH call structure; MED callee roles,
   function-roles.md]
4. Same tick, `FUN_10007170`: if `+0x09` and a player is active: in a film → session ends (a film
   holds one level); else stop music, play `PermSoundID(3)` (`tran` InterfaceTransition, vol
   75/100), `FUN_1000b9a0(display, 1)`, clear `+0x09`/`+0x39`, frame-controller reset
   `FUN_100302e0`, then **`FUN_100064d0(0, info)` → next sector**. No active player → session
   ends. [HIGH reading] ⚑ corrected (wave 2, 2026-10-03): was "vol 75/100" — the arguments are priority 75, volume
   100 (`FUN_10047670(id, priority, volume, allowMultiple)`, sound-music.md §2.3);
   `FUN_1000b9a0` is the fade to black (33 steps, loose-ends-session.md §6).
The defence bonus is paid inside the player update when `+0x39` is set: once per level per active
player (`player+0xd0` latch, cleared per level), spawn the player-def `active_DefenceBonusObject_ID`
and add score `Player_DefenceBonusBaseAmount (2000) × sector` (`FUN_10029a10(p, F184·FUN_10005cd0())`).
[MED — decompile of `FUN_10028170` lines 428–454; any further condition is the scoring reader's]

**What carries between levels and what resets** (per-session setup `FUN_10026410` vs per-level
`FUN_100269a0`, which acts only on active players, `+0xc4`):
| item | session start | each level | evidence |
|---|---|---|---|
| lives (player +0x98, stored + 0x1524dcef) | `life_NumInitial` (3) if the start sector is 1, **else 1** | carried | `FUN_10026cc0`: `10026ce0 rlwinm. r0,r4… beq → li r4,0x1`; caller `10026838 subfic r0,r30,0x1 / cntlzw / rlwinm r4,r0,0x1b,…` = (sector == 1); plde +0x64 = `#life_NumInitial_INT` (`FUN_10039e70` line 114) [HIGH] |
| next extra-life score (+0x9c) | `life_InitialRequiredScore` (10000, plde +0x68) | carried | `10026d10 lwz r3,0x68(r3) / stw r3,0x9c(r31)` [HIGH] |
| score (+0xb0, stored + 0x5532a3e) | 0 (`FUN_100299c0`) | carried | setter `FUN_10029a00` has no per-level caller (xref) [HIGH] |
| coins held (+0xac, stored + 0xb2cce) | 0 | **reset to 0** (`FUN_100269a0` → `FUN_10027580`) after the end-of-level coin bonus counted them | xref of `FUN_10027620`; `FUN_10027670` multiplies +0xac [HIGH reset; MED "coins"] |
| weapons | `FUN_1003ade0(…, sector)`: default ground weapon (`DEAG`), air weapon = the `PEAA` def whose level range contains the start sector (`FUN_1003cdb0`) | `FUN_1003af90(handler, 1)`: transient fire/overload state cleared, pending `PEAG` pickup applied, `PEAA` swapped if a `PEAA` def has min level == current sector (`FUN_1003cd30`) | [MED — arguments partly dropped by the decompiler; weapons reader owns it] |
| position, velocity, appear fade, state 2 at time 0 | | reset (`FUN_10026b10`, `FUN_10026c80(p,2,t)`, PermFloats 163–165) | [MED] |
| inactive (dead) player | | stays out (`FUN_100269a0` returns at once if `+0xc4 == 0`) | [HIGH] |
Starting sector > 1 thus gets 1 life and a later air weapon — the code side of the level-select
"Starting Bonus" lines (NOT-RESOLVED #28, narrowed; the displayed text is not traced). [MED]
Demo note (out of scope): unregistered copies stop after sector `FUN_10011b00()` = 4 (`+0x0e`),
and `FUN_10011b30(info)` tests membership of the first 4 identifiers. [HIGH reading, not specified]

## 9. G_Background.cc proper
- `FUN_1000fbc0(info) @ 1000fbc0`: loads `#backgroundImage_ID` (`im16`, TGA) into the map buffer
  (display+0x6c, resized to image w×h at PermFloat 56 depth), asserts image size == RECT
  (`ERROR: Background image dimensions…`, line 0xe7); loads `#mediaMask_ID` (invalid → `none`
  with "FILE ERROR: Media Mask ID invalid"), asserts equal aspect ratio (line 0x11a), element
  size = map w / mask w (480 / 96 = 5; 3600 / 720 = 5) ≥ 1 (line 0x122). [HIGH]
- `FUN_1000fee0(point)`: water test — map point / element size → mask pixel == `0x001f`
  (pure blue in 16-bit 555). Caller `FUN_10016880` passes map coordinates (§7). [HIGH]
- **No parallax**: one map layer, drawn each frame by `FUN_10010120` (called from the end-frame
  `FUN_10030bc0` and once at level start) as a single 416×480 blit from map rect (top, offset+32,
  top+480, offset+448) to buffer rect (0, 0, 480, 416) with draw mode `pref byte 5`
  (`bl FUN_10004ef0(5)`). [HIGH for the rects (listing `10010138…100101f8`); the meaning of pref
  5 is engine-loop.md's (interlace toggle)]
- Module glue: `FUN_1000f7a0` registers module "Background" and 12 debug console command names
  on 10 handlers (BACKSIZE, ERASEBACK, JUMP, SCROLL, SCROLLING, ROW, LOGMEDIA, LOGMEDIAMASK, MEDIASIZE, MEDIA,
  LEVELSPAWNS, REVERSE; handlers via TOC slots `0x100df07c…0x100df0a0`); `FUN_1000f990`/
  `FUN_1000f9c0` free the mask. JUMP (`0x10010480`) advances one screen (480 rows) through
  `FUN_10010220` without spawning the skipped rows. Debug only. [HIGH — strings and listings]

## Worked example — `Level 01 [le01]` (Kepler Massif, sector 10), first 10 placements
Data: `$W/data/Game/leve/Level 01[le01].leve.txt` (46 objects); unit fields from the decoded
`unde` files. Formulas: §3 (k = 3056 − Y; game time = 3055 − Y if no pause yet), §6.2 (x − 32
iff `isGroundBased`), §6.4 (spawn y = −64), §7 (buffer x = world x − hOffset; screen x =
buffer x + 32 [MED]). hOffset = 0 assumed (it moves only with left/right input).
| # | unit | layer | xLoc | yLoc | hdg | stat/terr | ground? | world x | scroll tick k | game time (no pause) | spawn y | screen x @ off 0 |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| 1 | fl02 Flipper Mk 2 | air | 178 | 3020 | 0 | F/F | no | 178 | 36 | 35 | −64 | 210 |
| 2 | fl02 | air | 285 | 2926 | 0 | F/F | no | 285 | 130 | 129 | −64 | 317 |
| 3 | fl02 | air | 253 | 2701 | 0 | F/F | no | 253 | 355 | 354 | −64 | 285 |
| 4 | fl02 | air | 192 | 2907 | 0 | F/F | no | 192 | 149 | 148 | −64 | 224 |
| 5 | fl02 | air | 168 | 2704 | 0 | F/F | no | 168 | 352 | 351 | −64 | 200 |
| 6 | fl02 | air | 348 | 2699 | 0 | F/F | no | 348 | 357 | 356 | −64 | 380 |
| 7 | sc03 Screw Mk 3 | air | 196 | 1353 | 0 | F/F | no | 196 | 1703 | ≥ 1702 | −64 | 228 |
| 8 | sc03 | air | 302 | 1268 | 0 | F/F | no | 302 | 1788 | ≥ 1787 | −64 | 334 |
| 9 | papu Panzer - Pulse | grnd | 0 | 1117 | 105 | F/T | yes | −32 | 1939 | ≥ 1938 | −64 | 0 (world x −32 = under the left border; comes into view only when the camera pans left) |
| 10 | grob Ground Obstacle | grnd | 204 | 1164 | 0 | F/F | yes | 172 | 1892 | ≥ 1891 | −64 | 204 |
Reading:
- Spawn order is by row, not file order: 1 (k 36), 2 (130), 4 (149), then 5, 3, 6 (352, 355, 357);
  8 objects of the file lie between. Before any of them, the two `bsde` (Bonus Station – Desert,
  ground) at yLoc 3309 and 3129 are spawned at load (§2) at world y 189 and 9.
- The controller `10s1` ("Level 10 - Start 1", ground, xLoc 302, yLoc 2718) spawns on k = 338
  (game time 337); its first state waits 180 ticks before entering "Pause Scrolling, Wait"
  (`statePauseVerticalScrolling TRUE`), so the first pause starts ≈ game time 517 or later —
  after placements 1–6, whose times above therefore hold. Placements 7–10 come after the pauses
  of `10s1`, `10s2` (yLoc 2414, k 642) and `10m1` (yLoc 2029, k 1027), whose timers are random
  (e.g. 100–110, 330–350 ticks); their game times are k − 1 + (paused ticks), not computable
  statically. Their scroll tick k is exact.
- Each fl02 placement becomes a group of 8–9 Flippers (`numInGroupMin/Max` 8/9) at group
  (x, −64); members get x = group x + RandomRange(−80, 80), y = −64 + 0 (`x/yOffset` −80/80,
  0/0, rectangular mode) and staggered spawn countdowns of 8–16 ticks each
  (`groupDelayMin/Max` 8/16), per waves-and-enemies.md §4.
- `papu` has `initialHeadingSetInEditor` TRUE, so it faces the placed 105° (± its tolerance);
  the Flippers' placed heading 0 is ignored (flag FALSE) in favour of the unit's `initialHeading`.
- Ground units 9 and 10 thereafter move down 1 px per scroll tick with the terrain (§7); the air
  Flippers move only by their own state machine.
[HIGH for k, world x, spawn y (code + data); MED for screen x (left-border placement) and for the
"≈ 517" pause start (state timer semantics are the units reader's)]

## NOT RESOLVED (this file)
1. Entity anchor: is (x, y) the sprite centre? Settle by reading the blit callee of
   `FUN_10012fa0` (what it subtracts from `local_84/local_80`).
2. `0x100e013c` and `0x100e0140` have no readers in the dump; check the raw listing / jump-table
   targets for indirect reads before declaring them dead.
3. `FUN_10012ca0` mode-1 bounds exact expression (float compares with `cror`; only the 128 margin
   is HIGH).
4. `FUN_1002b3a0(sector)` → `FUN_1002b6d0('PEAA'/'PEAG'/'SPEC', sector)`: per-sector item setup,
   probably the level-gated weapon availability; not read.
5. `FUN_10027de0(player, 1, 0)` at level end and `FUN_10027db0`: player end-of-level mode; not read.
6. ~~Weapon carry-over details of `FUN_1003af90(handler, 1)` and the start-weapon pick
   `FUN_1003cdb0` ("best" bookkeeping looks inverted)~~ → `FUN_1003cdb0` closed: not inverted.
   Over weapon defs of class `PEAA` (`1003cdf4 subis r0,r4,0x5045; cmplwi r0,0x4141`) with
   `+0x13c ≤ sector ≤ +0x140` (`1003ce00–1003ce14`), the first match is taken and a later one
   replaces it only when best.min < cand.min (`1003ce28 lwz r0,0x13c(r30); cmpw r0,r4; bge
   skip`) — the highest minimum sector wins, ties keep the first; weapons-projectiles.md §1.3 is
   right. ⚑ corrected (review wave 1, 2026-10-03) #M9. `FUN_1003af90` carry-over details stay with the weapons reader.
7. Which on-screen text the level select shows for "Starting Bonus" vs "No Starting Bonus"
   (`pgsl` lines 3/6) — the code-side consequences are §8 (1 life, later air weapon).
8. Whether entities still in their spawn countdown (+0xb0 > 0) can pause the scroll (they appear
   to be skipped before `LAB_10033d70`) — bosses reader.
9. `FUN_1000b9a0(display, 1)` at the level transition (fade?) and `FUN_10010f90` registered test —
   not read.

## Role-table rows (for merge)
| function | module | role | label | evidence |
|---|---|---|---|---|
| `FUN_1000f7a0` | G_Background.cc | module init: register "Background", 12 debug console command names (10 handlers) | HIGH | strings + TOC handler slots (re-checked in the fix pass: REVERSE slot `0x100df07c` → TVector `0x100e0890` → `0x10010570`; SCROLL/SCROLLING `0x100df094` → `0x100e08c0` → `0x100104f0`, memory image) — ⚑ label audit (review wave 1): HIGH kept on data evidence |
| `FUN_1000f990` | G_Background.cc | free media mask if module live (session end) | MED | read |
| `FUN_1000f9c0` | G_Background.cc | module shutdown, free mask | MED | read |
| `FUN_1000fa10` | G_Background.cc | level-load spawn pass: rows bottom … top−64 (3600…3056) | HIGH | listing `1000fa48 subi r3,r3,0x41` |
| `FUN_1000fa90` | G_Background.cc | level scroll init: speed 1, offset 0, window top = rect.bottom − 480 (3120), progress 481 | HIGH | listing `1000fb38` |
| `FUN_1000fbc0` | G_Background.cc | load map + media mask, size/aspect asserts, mask element size (unchanged; evidence added §9) | MED | read — ⚑ label audit (review wave 1) |
| `FUN_1000fec0` | G_Background.cc | scroll window top (map row of world y 0) | MED | read; callers use it for map↔world — ⚑ label audit (review wave 1) |
| `FUN_1000fed0` | G_Background.cc | pixels scrolled this tick | MED | read; ground entities add it to y — ⚑ label audit (review wave 1) |
| `FUN_1000fee0` | G_Background.cc | is map point water (mask pixel 0x001f) | MED | read — ⚑ label audit (review wave 1) |
| `FUN_1000ffc0` | G_Background.cc | resume scroll (speed 1) unless level ended | HIGH | listing |
| `FUN_1000ffe0` | G_Background.cc | pause scroll (speed 0) | MED | read — ⚑ label audit (review wave 1) |
| `FUN_1000fff0` | G_Background.cc | scroll paused? | MED | read — ⚑ label audit (review wave 1) |
| `FUN_10010000` | G_Background.cc | per-tick scroll step; level end when progress ≥ 3600; spawn row top−64 | HIGH | listing |
| `FUN_100100a0` | G_Background.cc | horizontal offset getter | MED | read — ⚑ label audit (review wave 1) |
| `FUN_100100b0` | G_Background.cc | horizontal offset ±1, clamp [−32, 31]; driven by player left/right input | HIGH | listing + caller `10029508` |
| ⚑ corrected `FUN_10010120` | G_Background.cc | draw terrain window: map (top, off+32, top+480, off+448) → buffer (0,0,480,416) (was MED "draw terrain window") | HIGH | listing |
| `FUN_10010220` | G_Background.cc | advance window by speed, clamp, set scrolled delta | HIGH | listing |
| `FUN_10010360` | G_Background.cc | free media mask | MED | read — ⚑ label audit (review wave 1) |
| `FUN_10010570` | G_Background.cc | console REVERSE (speed 1↔−1), debug | HIGH | listing |
| `FUN_10010860` | G_Background.cc | console LEVELSPAWNS toggle, debug | MED | read — ⚑ label audit (review wave 1) |
| (undefined) `0x100103b0` `0x10010430` `0x10010480` `0x100104f0` `0x10010600` `0x10010640` `0x100106f0` `0x100107a0` | G_Background.cc | console BACKSIZE, ERASEBACK, JUMP, SCROLL, ROW, LOGMEDIA, MEDIASIZE, MEDIA handlers (no Ghidra function) | HIGH | TOC slots `0x100df07c…a0` + listings |
| `FUN_10011a70` | G_Level.cc | module init: register "Level", build order list | MED | read — ⚑ label audit (review wave 1) |
| `FUN_10011ab0` | G_Level.cc | module shutdown, free order list | MED | read |
| `FUN_10011b00` | G_Level.cc | number of unregistered levels = 4 (demo, out of scope) | MED | read — ⚑ label audit (review wave 1) |
| `FUN_10011b10` | G_Level.cc | free order list (demo cut) | MED | read |
| `FUN_10011b30` | G_Level.cc | level among first 4 identifiers? (demo, out of scope) | MED | read — ⚑ label audit (review wave 1) |
| `FUN_10011bf0` | ~after G_Background (G_Level span) | set byte `DAT_100e0151` = 1 (the flag `FUN_100120f0` asserts clear); called twice by `FUN_100015a0` on the pak version-mismatch error path ("Sorry, but this version of Deimos…") | MED | dump (2 lines); caller `FUN_100015a0` — not re-read in wave 1; ⚑ corrected (review wave 1, 2026-10-03) #M7 (new row) |
| `FUN_10011c00` | G_Level.cc | build level order list from encoded table (existing bank row; caller `FUN_10011a70`) | HIGH (bank, unchanged) | not re-read in wave 1 — ⚑ corrected (review wave 1, 2026-10-03) #M7 (new row) |
| `FUN_10011de0` | G_Level.cc | level count (list length, 12) | MED | read (`FUN_10000ce0` = count) — was LOW — ⚑ label audit (review wave 1) |
| `FUN_10011e30` | G_Level.cc | tag → sector (0 if absent) | MED | read — was MED — ⚑ label audit (review wave 1) |
| `FUN_10011f00` | G_Level.cc | sector → tag (`none` if absent) | MED | read — ⚑ label audit (review wave 1) |
| `FUN_10011fd0` | G_Level.cc | load level by sector (info [+ object list]) | MED | read — ⚑ label audit (review wave 1) |
| `FUN_100120f0` | G_Level.cc | load level by tag (asserts editor flag `DAT_100e0151` clear) | MED | read — was MED — ⚑ label audit (review wave 1) |
| `FUN_10012170` | G_Level.cc | free a level-object list | MED | read — ⚑ label audit (review wave 1) |
| `FUN_100121c0` | G_Level.cc | free the order list | MED | read — ⚑ label audit (review wave 1) |
| `FUN_10012230` | G_Level.cc | read pak entry `leve`, de-obfuscate, parse | MED | read — was MED — ⚑ label audit (review wave 1) |
| `FUN_100064d0` | G_Game.cc (span) | level start: next sector, per-level resets, scroll init, load spawns, Notice_Level_NN | HIGH | read + listing |
| `FUN_10007170` | G_Game.cc (span) | level complete → transition sound, `FUN_100064d0` next sector | MED | read — ⚑ label audit (review wave 1) |
| `FUN_100064c0` | G_Game.cc (span) | stop session (`+0x08 = 0`) | MED | read — ⚑ label audit (review wave 1) |
| `FUN_10007130` / `FUN_10007150` / `FUN_10007280` | G_Game.cc (span) | per-level counter resets (game struct +0x16c…, +0x3c/40, +0x48…) | MED | read |
| ⚑ corrected `FUN_10033090` | G_EntityGroup.cc (span) | spawn pending level objects whose yLoc == row; request y flagged "map row"; record always removed (was HIGH "spawn level objects at a scroll row") | HIGH | listing |
| ⚑ corrected `FUN_10035900` | G_EntityGroup.cc | build pending list; x −= 32 iff unit `isGroundBased` (unit+8 == `grnd`), placement `#layer_ID` unused (was: "grnd objects" by layer) | HIGH | listing `10035abc` |
| `FUN_1003fc50` | G_UnitDefinitions.cc | load unit def; unit+8 = `grnd`/`air ` from isGroundBased | HIGH | listing `1003fd20` |
| `FUN_1003d2f0` | G_UnitDefinitions.cc | unit def by tag (list lookup, unit+4 = tag) | HIGH | read — ⚑ label audit (review wave 1): HIGH kept — listing evidence in unit-def-struct.md role rows |
| `FUN_10026cc0` | G_Player.cc | session lives: life_NumInitial if start sector 1 else 1; extra-life threshold | HIGH | listing |
| `FUN_10026d60` | G_Player.cc | set lives (stored + 0x1524dcef) | HIGH | read — ⚑ label audit (review wave 1): HIGH kept — listing evidence in player-physics.md role rows |
| `FUN_10027620` | G_Player.cc | set coins held (stored + 0xb2cce) | MED | read + coin-bonus use |
| `FUN_100299f0` | G_Player.cc | score getter (stored − 0x5532a3e) | HIGH | read — ⚑ label audit (review wave 1): HIGH kept — listing evidence in player-physics.md role rows |
| `FUN_10012ca0` | G_Sprite (span) | move entity (ground: + scrolled px), in-area test with margin | HIGH | listing (bounds MED) |
| `FUN_10000e10` / `FUN_10000c00` / `FUN_100009e0` | U_LinkedList.cc | iterate / unlink-current / append (node = prev,next,data) | MED | read + assert string — ⚑ label audit (review wave 1) |
Not read in scope: none of the functions in `0x1000fbc0–0x10010860`, `0x10011a70–0x10011b30` or
`0x10011de0–0x100122f0` is unread. Not re-read: `FUN_10011c00` (79 lines, build level order list, existing bank row) and
`FUN_10011bf0` (10 lines) — rows below. ⚑ corrected (review wave 1, 2026-10-03) #M7: the old line claimed `0x10011c00–` was
fully read. Callees named but not read: `FUN_1002b3a0`→`FUN_1002b6d0`, `FUN_10027de0`,
`FUN_10027db0`, `FUN_1000b9a0`, `FUN_100467c0`, `FUN_1004a950`, `FUN_10018130`, `FUN_100189f0`,
`FUN_10031ad0`, `FUN_10031400`, `FUN_10036af0`, `FUN_10006110`, `FUN_10005cf0`.

## INDEX updates (for merge)
- **#17 closed** → this file §2 (initial top 3120, HIGH from `FUN_1000fa90` listing) and §5
  (horizontal shift driven by the active players' left/right input in `FUN_10028170`, ±1 px per
  tick each, clamp [−32, 31], reset per level; consumed by terrain draw and all non-HUD entity
  draws).
- **#27 narrowed** → §8 level-end step 2: Notice_AllLevelsCompleted is spawned only when sector 12
  ends a session that played all 12 levels (started at sector 1); the session then ends via
  `FUN_100064d0` (`none`). `EndGameFinale` sound sequencing still open.
- **#28 narrowed** → §8 carry table: a start sector > 1 gives 1 life (vs 3) and the `PEAA`
  weapon matching the start sector; the level-select text is not traced.
- engine-loop.md §5 corrections for merge: initial top 3120 is HIGH (not MED); the −32 x shift
  depends on the unit's `isGroundBased`, not the placement layer; the spawn row −64 is entered as
  world y −64; minimum level length is 3119 scroll ticks (level end at top = 1, not 0).
  ⚑ conflict (minor): engine-loop.md §5 says "When the window top reaches 0 the level-end flag
  is set" — the flag is set by the progress counter reaching the RECT bottom, which happens at
  top = 1 (§3).
- waves-and-enemies.md §1 "grnd objects get x −= 32": ⚑ conflict (minor) — it is the unit's
  `isGroundBased`; the data agree in all 565 placements so behaviour is the same.
