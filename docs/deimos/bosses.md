# Deimos Rising 1.0.6 — bosses, end-of-sector set pieces, the scroll-pause gate

Reader H, wave 1 (2026-10-03). Code readings + data census only; nothing is behaviour-verified.
**Scope:** boss / end-of-level logic, data first: the final `Level`-family controller of each of
the 12 sectors and the heavy multi-part ground units in each final screen (`$W/data/Game/leve`,
`$W/data/Game/unde`, Player Guide); the scroll-pause gate and level-end detection
(`FUN_10033850` step 6, `FUN_10006b50`, `FUN_10010000`/`FUN_10010220`, `FUN_1000ffc0/ffe0/fff0`);
the mechanics those set pieces lean on — rule-condition callees `FUN_100352f0`, `FUN_100353e0`,
`FUN_100351f0`, `FUN_10035070`, on-screen test `FUN_10016bd0`, state change/OnCounter
`FUN_100146f0`, spawn sets `FUN_10015b40`/`FUN_10017cb0`, damage `FUN_10014f10`, entity–entity
collision `FUN_10036cf0`, owner/child propagation (`FUN_10036930`, `FUN_10036ab0`,
`FUN_10036120`, `FUN_100363c0`, `FUN_10036610`). No address range is owned. **OUT:** spawn-at-row
`FUN_10033090` and `G_Level.cc` (level reader — read only for the gate), movement executors
`FUN_10015930`/`FUN_10015280` (not read), `FUN_10034ee0` "tracking" (not read), lock/link/orbit
bodies `FUN_10037130/7230/7350` (not read), the end-of-level tally arithmetic
(`FUN_10027670`, `FUN_100072c0`, `FUN_100075e0`, `FUN_10027930` — not read), the finale
sequence after sector 12 (INDEX NR #27). Evidence kit: dump `ghidra/Deimos_pef.decompiled.c`;
raw PPC listings `$W/disasm-bosses.txt`, `$W/disasm-bosses2.txt` (own project copy
`$W/work-bosses`, `DisasmFuncs.java`); unit/level census scripts kept in the session scratchpad
(a 60-line `#key <value>` parser: a state starts at `#stateName_STR`, spawn sets at
`#stateSpawnSetName_STR`, rules at `#stateRuleName_STR`).

**Answer up front.** Deimos Rising has **no boss entity type, no boss flag, no boss health bar
and no boss announcement** [HIGH, §1]. What plays as a boss is an *end-of-sector set piece*: the
last `Level`-family controller of the sector stops the scroll ~180 ticks after it appears,
throws waves at the player, and (in 5 of 12 sectors) waits on a rule — "all on-screen
ground-accuracy targets destroyed" or "unit X is gone" — before deleting itself. The level ends
purely on scroll distance (window top reaches row 1), so the controller's lifetime *is* the
boss fight. The heavy targets on that last screen are ordinary multi-part ground units
(base + turret child flagged `passHitsToOwner` — which passes only *ramming* to the owner; player
shots that touch the turret drain the turret's own shields, §3.5 ⚑ corrected (review wave 1, 2026-10-03) #I1); in sectors 10 and 12 the centrepiece gun is
invulnerable until the two on-screen Nuke Stations are destroyed (a persistent destruction-FX
unit counted by an `== 2` rule).

## 1. Is there a boss? — negative evidence

| check | result | label |
|---|---|---|
| strings in the binary | `strings -a "$G/Deimos Rising" \| grep -ci boss` → 0; `grep -ci boss` over the dump and `$W/profile.txt` → 0 | HIGH |
| Player Guide | sections: Story, Controls, Weapons, Enemies (Ground 20 / Air 13 rows), Hints, Scoring, Levels, Special Bonuses. No boss section; the closest are "Turbinium Fusion Reactor … you'll have to take these out before tackling the weapons they power" and "Nuke Cannon … Heavily shielded" (cite). | HIGH (text) |
| unit families | 60 families / 386 units, none named Boss/Guardian; `Notice` family (16) = level-start, level-end, game-over, all-levels, war-crime animations only | HIGH (census) |
| unit notices | `#entryNotice_STR`/`#destructNotice_STR` non-empty in 0 of 386 units; `#entryNoticeSound_ID` = `none` in 386/386 | HIGH (grep) |
| score bar | `flli` `ScoreBar_*` keys (lines 112–144) and `reli` `Scorebar …` rects (16) are per-player score / lives / shields / power / weapons only — no enemy meter | HIGH (file) |
| who pauses the scroll | `statePauseVerticalScrolling_BOOL <TRUE>` in 292 states of 53 units: every one is a `Level` controller (49) or `Pause - 10/15/20/30 Seconds` (`pa10/15/20/30`, 4); the `pa*` units are placed in 0 levels | HIGH (grep) |
| `stateDestructIfVerticalScrollingNotPaused` | `TRUE` in 0 of 1167 states (code path exists, §2.4) | HIGH (census) |

So "the boss of level N" below means: the final controller of sector N + the ground units it
gates on. Sector numbering = play order (engine-loop.md §6; controller IDs `NN??` use it).

## 2. The scroll-pause gate and level-end detection

### 2.1 Order of operations per logic tick (`FUN_10006b50 @ 10006b50`)
```c
  cVar4 = FUN_10010000();            // scroll step with LAST tick's speed, spawn row, level-end test
  if (cVar4 == '\x01') { … level-end handling (2.3) … }
  cVar4 = FUN_10033850(*piVar9);     // update all entities; returns "someone pauses"
  if (cVar4 == '\0') FUN_1000ffc0(); // speed = 1 unless level ended
  else               FUN_1000ffe0(); // speed = 0
```
The pause decided in tick *t* takes effect in tick *t+1*; a controller that deletes itself in
tick *t* lets the scroll move again in *t+1*. [HIGH — dump lines quoted; `FUN_1000ffc0` body
`if (DAT_100e0148 != 0) return; _DAT_100e0128 = 1;`, `FUN_1000ffe0` body `_DAT_100e0128 = 0;`;
caller `FUN_10006b50 <- FUN_100051a0` (`$W/callers.txt`)]

### 2.2 Who asserts the pause (`FUN_10033850` step 6, exact)
The return value is the byte `local_60` (stack `0x140(r1)`), cleared at entry and set only here:
```
10033d60  bl 0x10014650            ; r18 = current state (after any timer state change)
10033d70  lbz r0,0x346(r18)        ; statePauseVerticalScrolling
10033d78  beq 0x10033d84
10033d7c  li r0,0x1
10033d80  stb r0,0x140(r1)
…
100345d8  lbz r3,0x140(r1)         ; return value
```
Reached only for an entity that (a) has finished its spawn-in delay (`+0xb0` decremented to < 1;
while counting down, `+0xa4` state-start is re-stamped to "now" every tick) and (b) was not
deleted/destroyed by its own state timer this tick. A timer that switches state re-reads the
state first (`goto LAB_10033d70` after `FUN_10014650`), so the **new** state's flag counts in the
same tick. Rules (`FUN_10015550`) are evaluated *after* the flag is set, so a rule that deletes
the controller still leaves one paused tick. There is no other condition: any live entity of
any family in a pausing state stops the scroll. [HIGH — raw listing above + dump]

### 2.3 Level end = scroll distance, nothing else
`FUN_1000fa90` (level scroll init): `iRam100e5ac4 = level+0x68` (= RECT bottom 3600),
`top _DAT_100e5acc = 3600 − PermFloat 55 (480) = 3120`, progress `_DAT_100e014c = 480 + 1 = 481`.
`FUN_10010220` each tick with speed s: `top −= s; progress += s` (clamped 0..3600).
`FUN_10010000`:
```
10010038  subi r3,r2,0x874 ; lwz r4,0x8(r3)     ; r4 = 3600 (0x100e5ac4)
1001003c  lwz r0,-0x61e4(r2)                    ; progress
10010044  cmpw r0,r4 ; blt 0x10010068           ; progress < 3600 → spawn row top−64
1001004c  … stb 1 → -0x61e8(r2) (DAT_100e0148 level-ended); stw 0 → speed; return 1
```
So the level ends in the tick progress reaches 3600, i.e. when `top` = 3120 − (3600 − 481) =
**1**, after 3119 scrolled ticks plus every paused tick. A controller therefore delays the level
end by exactly its paused lifetime; the remaining distance after it deletes itself is
`pauseTop − 1` ticks (§4). Nothing tests "boss dead". [HIGH — raw listing + dump of
`FUN_1000fa90`/`FUN_10010220`]

On the first level-ended tick (`FUN_10006b50`): if players are alive (game struct `+10` == 0),
Notice `idli gaob[22]` = `nole` "Notice - Level End" ("Sector Secured" animation) — or
`gaob[23]` = `noal` "All Levels Completed" when the game struct's `+0x14`/`+0x10` equal
`FUN_10011de0()` (last level) — is spawned at `(PermFloat 54 × 0.5, PermFloat 55 × 0.5)` =
(208, 240), screen centre (`*(float*)(PTR_DAT_100def80+8)` → `0x100d6354+8` = 0.5, read from
the code image); then `FUN_10027de0(player,1,0)` per player and `FUN_100072c0(time)`; later ticks
run the tally (`FUN_100075e0`, `FUN_10027670`, `FUN_10027930`) until game struct `+9` = 1. With
no player alive, `gaob[24]` `nogo` Game Over instead. [MED — dump read; tally callees not read]

### 2.4 Side paths
- `stateDestructIfVerticalScrollingNotPaused` (+0x352): `10033f5c lbz r0,0x352(r18)` →
  `bl 0x1000fff0` (`return speed == 0`) → if scrolling, `FUN_10016300` destroy. Unused by data
  (§1). [HIGH]
- Console `REVERSE` (`FUN_10010570`): toggles speed −1 ↔ 1 ("Vertical Scrolling
  Reversed/Resumed"), never when the level has ended; `SCROLL`/`SCROLLING` is the separate
  handler at undefined `0x100104f0` (toggle 1 ↔ 0). `LOGSCROLLPAUSERS` is *registered* by the
  unit-module init `FUN_1003cf10`; its handler is undefined code at `0x10041a40` (TVector
  `0x100e0a00` ← TOC r2−0x6e3c), which logs "NOTE: Unit pauses scrolling: %s". Debug only.
  [HIGH — listing `10010580 lwz r0,-0x6208(r2); cmpwi r0,-0x1` … `100105c8 li r0,0x1`,
  `10010598 li r0,-0x1`; registration `FUN_1000f7a0` `REVERSE` → TOC slot `0x100df07c` →
  TVector `0x100e0890` → `0x10010570`, `SCROLL` → `0x100df094` → `0x100e08c0` → `0x100104f0`
  (memory image); `1003cf40 lwz r5,-0x6e3c(r2); … 1003cf5c bl 0x1002d080` with
  "LOGSCROLLPAUSERS" at r2+0x6ce0+0x31] ⚑ corrected (review wave 1, 2026-10-03) (conflict): was "`SCROLL`/`SCROLLING`
  (`FUN_10010570`) … `LOGSCROLLPAUSERS` (`FUN_1003cf10`) logs …" [MED]; level-scroll-objects.md §9
  had it right.

## 3. Mechanics the set pieces use (code)

### 3.1 Rule conditions that gate bosses (refines waves-and-enemies.md §3)
| # | condition | exact test | label |
|---|---|---|---|
| 4 | No Destroyable Air Entities Are Active | `FUN_100352f0`: false if ANY entity in any group has unit `includeInAirAccuracyCount` (+0x133). No live / deleted / spawn-delay / on-screen test — pending group members count. | MED (dump; only offset +0x133 = named key) — ⚑ label audit (review wave 1) |
| 5 | No Destroyable Ground Entities Are Active | `FUN_100353e0`: false if any entity has unit `includeInGroundAccuracyCount` (+0x134) **and** `FUN_10016bd0(entity)` = on-screen. Off-screen ground targets do not hold the gate. | MED (dump) — ⚑ label audit (review wave 1) |
| — | on-screen test `FUN_10016bd0` | `0.0 ≤ x ≤ (int)PermFloat54 (416)` and `0.0 ≤ y ≤ (int)PermFloat55 (480)`, inclusive, entity `+0/+4` = screen x/y | HIGH — raw `10016bf4 fcmpo; blt`, `10016c38 fcmpo; bgt`, `10016c8c fcmpo; ble`; 0.0 from `*(float*)0x100d6c8c` (code image) |
| 2/3 | Is Active / Is Not Active | `FUN_10035070(unit, pos, range)`: true if any entity of that unit ID with `+0xb0 < 1` (spawn delay over) exists; if range ≠ 0 it must also be within `range` (distance `FUN_10042e90` = sqrtI(trunc(dx²+dy²)), compare `dist ≤ range`, **inclusive**; range 0 = any distance). `pos` = the polling entity's own (x, y), copied by `FUN_100128d0` at `100156ac or r3,r26,r26; 100156b0 addi r4,r1,0x4c; 100156b4 bl 0x100128d0` in the rule evaluator `FUN_10015550` (case 2/3 wiring from the decompile) | HIGH — listing `$W/disasm-bosses.txt`: `10035094 subis r0,r21,0x6e6f; 10035098 cmplwi r0,0x6e65; 100350a0 beq` (unit `none` → false); `1003512c cmpw r0,r21` (member unit ID); `10035134 lwz r0,0xb0(r3); 10035138 cmpwi r0,0x0; 1003513c bgt` (spawn delay must be ≤ 0); `10035140 cmpwi r23,0x0; 10035144 beq 0x100351b0` (range 0 → true without a distance); `10035148 bl 0x100128c0` (= `blr`, identity → member +0/+4) `10035158 bl 0x10042e90` (distance from `param_2`); `10035184 fcmpo cr0,f1,f2; 10035188 cror eq,lt,eq` (dist ≤ (double)range); `100351a8 fcmpu cr0,f1,f0; 100351ac beq 0x100351b8` (f0 = 0.0 at `0x100d7238`: result 0 → next member) — ⚑ corrected (review wave 2, 2026-10-03) (critic O3): was MED "distance helper not read" |
| 14 | Number of This Type of Entity Active | `FUN_100351f0(unit)` counts entities of that unit with `+0xb0 < 1`; rule fires on `count == range` | MED (dump) — ⚑ label audit (review wave 1) |
[callers: all five `<- FUN_10015550` (`$W/callers.txt` lines 655–659)]

### 3.2 State timer and OnCounter (`FUN_100146f0 @ 100146f0`)
- On entry to state s: `entity+0xa8 = s`, `+0xa4 = now`, entry counter `+0x14c+4s += 1`,
  timer `+0xb8 = RandomRange(stateOnTimerMin, Max)` (`FUN_10046580`), spawn sets re-armed
  (`FUN_10017cb0`, §3.3). [HIGH — dump; offsets `0x3ac/0x3b0` = named keys]
- Timer fires when `now == +0xa4 + +0xb8` (FUN_10033850 step 4). Target `""`, `"none"` or a
  name that is no state (shipped: `No State`) = stay forever. [HIGH, waves §3]
- **OnCounter:** if `stateOnCounter (+0x3b4) > 0` and the entry counter equals it, the counter is
  reset to 0 and the entity immediately enters `stateOnCounterChangeTo (+0x51c)` (`Delete`/
  `Destroy` honoured). This is how controllers loop a wave N times (`05e1` ×2, `09e1`/`10e1` ×3,
  `12e1` ×4; `11e1`'s counter 7 is never reached on its timer path). [HIGH — dump lines
  `if ((0 < *(int *)(iVar6 + 0x3b4)) && (*(int *)(param_1 + s*4 + 0x14c) == *(int *)(iVar6 + 0x3b4)))`]
- **OnHit** (`FUN_10014f10`): fires only if `stateOnHitChangeStateDelay (+0x3b8) ≠ 0` and
  `lastOnHit(+0xfc) + delay < now` — raw `10014fe4 lwz r3,0x3b8(r30); cmpwi r3,0x0; beq`. Shipped
  data: 33 states set OnHit, all to `No State` → OnHit is unused in 1.0.6. [HIGH]

### 3.3 Spawn sets — `FUN_10015b40` is the executor (⚑ conflict, see role rows)
Called once per tick for every live entity that survived the 128-px cull (`FUN_10012ca0`; not
only on-screen ones) from `FUN_10033850` (after owner lock/link/orbit), it first calls
`FUN_10017150` (rotate-to-target; holds **rotation**, not firing, while a
`PauseAnyRotationWhileSpawning` volley is mid-way), then ⚑ corrected (review wave 1, 2026-10-03) #M5: was "once per tick per
on-screen entity" and "holds firing". for each spawn set of the current state with its 0x18-byte runtime record
`r` (`entity+0x19c+4s` list, allocated by `FUN_100144a0` at creation):
- state entry (`FUN_10017cb0`): `r.rate = R(RateMin,Max)`, `r.last = now`, `r.volley =
  r.left = R(NumInVolleyMin,Max)`, `r.delay = R(DelayBetweenEntitiesMin,Max)`, active if
  rate ≥ 0 and volley > 0 → **every set fires one volley at state entry**, repeating or not;
- `r.left > 0`: `if (r.delay > 0) r.delay--; if (r.delay ≤ 0) { spawn one; r.left--; r.delay =
  R(dbe) }` — so with dbe 0 the first entity appears in the entry tick;
- `r.left == 0`: not `RepeatSpawns` → set goes inactive; else when `now ≥ r.last + r.rate`:
  `r.last = now`, re-draw delay, volley, rate (no spawn in that tick);
- `Don'tSpawnOffscreen`: volley abandoned while the spawner is off-screen; `SpawnIfFleeing`
  gate; position = spawner + offset (rotated if `AdjustOffsetForUnitRotation`) or the raw offset
  if `AbsoluteCoordinates` (screen coordinates — consistent with `FUN_10016bd0`'s frame); the
  child gets the spawner as owner (`local_88 = param_1`) and goes through the group spawner
  `FUN_10033220` (so one "spawn" of `bu01` is a 5–6 Buzzsaw group).
[HIGH for the volley/rate logic and offsets — raw `10015c70..10015d5c`: `lwz r3,0x3c(r28)`
dbe, `0x34/0x38` volley, `0x2c/0x30` rate, `lbz r0,0x46(r28)` repeat, `10015cec cmpw r31,r0;
blt` (now < last+rate → wait); MED for the absolute-coordinate frame and owner field]

### 3.4 Damage, shields, layers (`FUN_10014f10 @ 10014f10`)
- Collision partners must share the unit layer 4CC at unit `+8`, written by the loader
  `FUN_1003fc50`: `1003fd20 lbz r0,0x125(r30)` (`isGroundBased`) → `'grnd'` else `'air '`
  (`lis r3,0x6772 … stw r0,0x8(r30)`). Player Ion Cannon bullets (`icb `, isGroundBased FALSE)
  **cannot hit ground units**; Plasma Bombs (`plbo`, TRUE) cannot hit air units. [HIGH]
- `FUN_10036cf0(A, now)` (entity–entity collision; ⚑ the bank calls it the spawn-set executor):
  A collides with B if both states `Collides`, B live (spawn delay over) and visible (`+0xac`), B ≠ A (entity serial `+0x9c`), same layer,
  exactly one of them `harmlessToPlayers` (player side vs enemy side), and the projectile rule
  (`playerProjectile` A → B `canBeHitByPlayerProjectile`, else B must be hittable and a
  projectile); then boxes + `FUN_10042f80`. **A takes B's `damage_FLOAT`** (`10037020 lfs
  f1,0x274(r4)`, r4 = B.unit) — redirected to A's owner if A's state `passHitsToOwner` and the
  owner is valid — then **B takes A's damage**; B's own `passHitsToOwner` tests and damages
  **A's** owner (`10037074 lwz r5,0x140(r17)`, `100370b4 lwz r3,0x140(r17)`, r17 = A), never
  B's. [HIGH — raw `10036fc4..100370e8`] ⚑ corrected (review wave 1, 2026-10-03) #I1: the B-side redirect added; consequence
  in §3.5.
- `FUN_10014f10(e r3, — r4, player r5, now r6)` with damage f1 (r4 is never read; the unit is
  reloaded at `10014fb8 lwz r29,0x94(r26)`) ⚑ corrected (review wave 1, 2026-10-03) #M5: was "`FUN_10014f10(e, unit, player,
  now)`": ignored unless `now > lastHit(+0xb4) +
  (int)PermFloat 167` (Entity_HitDelay = 1 → at most one hit per 2 ticks; raw `10014f70 cmpw
  r28,r0; ble skip`); `shields(+0x134) −= dmg` in single precision (`10014f84 fsubs`), clamped to
  0.0; nothing at all if old shields ≤ 0.0; `stateInvulnerable_ShieldsDoNotDeplete` (+0x348)
  restores the old value (`10014fe0 stfs f2,0x134(r26)`); if still > 0: glow (unless
  `DoNotGlowOnCollision`), hit particles, shield sound (`+0x448`, or unshielded sound `+0x460`
  when invulnerable), `collision_Spawn` (`+0x2e0`, repeat/delay rules); if ≤ 0.0:
  `FUN_10006190(player, score_INT, 0)` then destroy (`FUN_10016300`) — or, if entity `+0xcd`, the
  shield-depletion path `FUN_10017e70`. Zero threshold: `*(double*)(0x100d6ca4+8)` = 0.0 (code
  image). [HIGH]
- `+0xcd` is set at spawn by `FUN_10035cd0` when the unit has a state with
  `stateUseThisStateOnShieldDepletion` (`10035db8 addi r0,r5,0x836` = 0x4e0+0x356). Shipped data
  sets that key in **0** states — the "second phase on shields gone" mechanism exists but no
  1.0.6 unit uses it. [HIGH for data, MED for `FUN_10017e70` (not read)]
- Player ramming (FUN_10033850 step 8) deals `PermFloat 161` = 100 to the entity, redirected
  by the entity's **own** `passHitsToOwner` to its **own** owner (`10034228 lbz r0,0x32b(r18)`;
  `10034238 addi r3,r19,0x140; bl 0x10036ab0`; `10034268 lwz r3,0x140(r19); … bl 0x10014f10`,
  r19 = the entity). This is the only path on which a turret passes damage up. [HIGH]
- **Hits to kill = number of float32 subtractions of the weapon's damage until shields ≤ 0.0.**
  Because 0.4f is not exact, 12.0 needs 31 hits (not 30) and 2.0 needs 6 (not 5) — a replica must
  subtract in float32. [HIGH — numpy float32 replay of the `fsubs`/`fcmpo` sequence]

### 3.5 Parts: owners, children, turrets
| mechanism | code | label |
|---|---|---|
| owner link = `entity+0x140` (pointer) + `+0x144` (owner's serial `+0x9c`); valid iff non-null, serial matches, owner not deleted (`FUN_10036ab0`) | dump of `FUN_10036ab0` (its inlined twin in `FUN_10036cf0` `10036fd4–10037004` is listing-checked); set by `FUN_100142f0` from the spawn request | MED (dump) / MED (setter) — ⚑ label audit (review wave 1): was HIGH (dump) |
| `useOwnersVisibility` 0x327, `useOwnersScale` 0x328, `visuallyReflectOwnerHits` 0x32c → copy owner's visibility / scale / glow fields each tick (`FUN_10036930`) | raw `10033f4c lbz r5,0x327; lbz r6,0x328; lbz r7,0x32c; bl 0x10036930` | HIGH |
| `passHitsToOwner` 0x32b → **ramming** damage goes to the owner (the entity's own `+0x140`, `10034228–10034274`). **Player shots land on the turret's own shields**: a player shot is always A in `FUN_10036cf0` (B must be `canBeHitByPlayerProjectile`; all 9 `playerProjectile` units — `icb ` `plbo` `bagb` `bgpb` `icpb` `pbbl` `pbbu` `rgpb` `rgbu` — have it FALSE), so a turret is B; B's flag tests **A's** owner (`10037074`, `100370b4`, r17 = A), and a player shot has none (spawn-request template `0x100ecd14` +0x20 = 0 (no owner pointer) and +0x24 = −1 (written before `main` by `FUN_1003ce60`, `1003ceec`/`1003cf00` from `0x100d72a8`; static-init-audit.md §5.2; ⚑ corrected (wave 3+4, 2026-10-04): was "+0x20/+0x24 = 0, read from the data image"); both launchers copy that template and never write request +0x20/+0x24 — ground/bomb launch `FUN_1003c4f0` `1003c57c–1003c5ec` (then only +0x04/+0x08/+0x0d/+0x10/+0x14/+0x28) and `1003c6fc–1003c76c`, air launch `FUN_1003c7a0` `1003c838–1003c8ac` (then only +0x04/+0x08/+0x0d/+0x10/+0x14)), so the redirect never fires and the turret takes `A.damage` itself (`100370d8–100370e8`). Turret shields exist and are drained: `tapt` 3.0 + 0.4/sector (max 5.0), `pllt`/`talt` 3.0, `tgtu` 5.0, `betu`/`fgnt` 1.0; zero-shield bubbles (`nsbu bsbu cart cs2b csbu lsbu shsb`, 0.0) swallow the hit (`FUN_10014f10` does nothing when old shields ≤ 0.0, damage §3). No turret has `includeInGroundAccuracyCount`, and all 16 have `canBeDestroyedOnOwnerDestruction`, so killing the base still kills the turret; a bomb whose circle touches only the turret is wasted against the base. Original bug (B-side copy of the A-side test; spawn-and-waves.md §7, damage-health-death.md §2.5) — replicate. | §3.4; listings above; decoded `unde` (`#shields_BaseAmount/LevelIncrement/MaxAmount_FLOAT`) | HIGH ⚑ corrected (review wave 1, 2026-10-03) #I1: was "projectile and ramming damage go to the owner; the turret's own shields never drop while the owner lives" [HIGH] |
| owner destroyed → `FUN_100363c0`: every entity whose `+0x144` = dying serial and whose state has `canBeDestroyedOnOwnerDestruction` 0x329 is destroyed (recursive via `FUN_10036120`); `destructDestroyChildren`/`destructDeleteChildren` (unit 0x4b0/0x4b1) select destroy vs delete (`FUN_100364f0`, 0x32a) | dump lines 32322–32325, 32429, 32481 | MED |
| `destroyOwnerOnDestruction` 0x32d (`FUN_10036610` sweep) | dump line 32559; data: 0 states | MED |
| **`invulnerableUntilAllChildrenDestroyed` 0x325 / `invulnerableUntilOwnerDestroyed` 0x326 are inert**: the only loads in the whole code image are the parser's (`10040ea4 lbz r0,0x325(r30)`, `10040ed0 lbz r0,0x326(r30)`, both setting unit `+0x11`); no `addi` of 0x325/0x326/0x805/0x806 either | byte-pattern scan of `$W/mem/10000000.bin` for `lbz/stb/lwz…` with d=0x325/0x326 and `addi` imm | HIGH for "no direct load", MED for "inert" (an indexed load would escape the scan) |
| lock / link / orbit (0x32e/0x32f/0x330 → `FUN_10037130/7230/7350`) | callers only | not read |
Data census (states with the key TRUE): `passHitsToOwner` 16 units (every turret/bubble child:
`betu bsbu cart cs2b csbu fgnt lsbu ngtu nsbu pllt pptu pstu shsb talt tapt tgtu`),
`LockToOwnerLoc` 71, `canBeDestroyedOnOwnerDestruction` 49, `invulnerableUntilOwnerDestroyed` 1
(`cart`), `invulnerableUntilAllChildrenDestroyed` 0, `destroyOwnerOnDestruction` 0,
`UseThisStateOnShieldDepletion` 0. The boss "gate by sub-targets" design is therefore done with
rules, not with the invulnerable-until keys (§5). [HIGH — census]

## 4. Per-sector end set pieces
Pause row = `yLoc + 64 − (timer of the non-pausing lead-in states)`; visible map rows =
`pauseTop … pauseTop+480`. "Pause" = sum of timers on the timer-only path from the first pausing
state to `Delete`, min..max (counters followed; rule exits ignored). Gated ground set = units
with `includeInGroundAccuracyCount` placed in the visible rows (screen x = map x − 32 for ground
objects); bombs = Plasma Bomb hits (0.4) **that land on the base unit** at that sector's shields
(§3.4). Hits on a `passHitsToOwner` child (turret, bubble) stay on the child (§3.5), so they do
not count toward the base; the base figures below are unchanged by that correction, and the
children's own figures are in the turret table after this one. ⚑ corrected (review wave 1, 2026-10-03) #I1.
| sec | level | final controller (y) | pause top | pause ticks | early exit (rule) | waves / spawns during the pause | on-screen gated ground set → bombs |
|---|---|---|---|---|---|---|---|
| 1 | le07 Mariner Valley | `01b1` Level 1 - Bridge (512) | 346 | 800 | #5 ground clear → Delete | `tapu` once at abs (480,140) hdg 285 (before pause); `bu01` group every 100–115 | `plla` 2.6→7; `tapu` 1.5→4 (placed, x 433 = off-screen right unless moved) |
| 2 | le06 Cydonia Plateau | `02e2` End 2 (136) | 20 | 1380–1450 | `bu02` Is Not Active → Delete (last state only) | `bu02` groups every 100–110 + sporadic 150–160, two phases | `bsgr`×3 4.4→11; `tapu` 1.9→5 (one off-screen) |
| 3 | le02 Darius | `03e1` End (195) | 79 | 1910–1965 | #5 ground clear → 240-tick wait → Delete | `flip` every 120–140 (×2 phases); `tala` from east (480,232) and west (−60,120) | `bala` 6.8→17; `bsde` 4.8→12; + the two spawned `tala` |
| 4 | le08 Neo Kowloon | `04e1` End (131) | 15 | 1660–1665 | #5 ground clear (either phase) → 240 → Delete | `flip` every 90–95, two 500-tick phases | `twgu` 12.0→31; `sggr`×2 4.2→11 |
| 5 | le11 Heart of Darkness | `05e1` End (133) | 17 | 2591–2671 | `pola` Is Not Active → 160 → Delete; counter 2 on "Shuriken Wave 3, RULE" | `shur` waves ×3; flags `imof` (open Iris Mine), `plaf` (activate Large Popup), `plsf` (shutdown) on exit | `pola` 12.6→32; `csht` 8.0→20 |
| 6 | le04 Bellerephon | `06e1` End (123) | 7 | 2321–2341 | none to the end (`shur` Is Not Active only skips a wait) | `scre`, `shur` waves; `plaf`; `plsf` on exit | `cara` 6.0→15; `pola` 13.0→33 |
| 7 | le12 Greater Babylon | `07e1` End (150) | 34 | 1791–1821 | none | `flip`; `pasc`×2 (west −60,200; bottom 416,500); `sc02` | `bala` 8.4→21 (`bsde` off-screen) |
| 8 | le03 Ticonderoga | `08e1` End 1 (130) | 14 | 2220–2280 | none | `flip`; `poaf` (Popup activate); `sc02`×2; `posf` on exit | `fg02` 15.0→38; `popu`×2 9.8→25; `bsgr` 6.8→17 |
| 9 | le05 Yucatan Rift | `09e1` End 1 (132) | 16 | 2351–2512 | none (counter 3 loop) | `fl02`; `sh02` from east; `pasc`×2 | `bsat` 7.0→18 |
| 10 | le01 Kepler Massif | `10e1` End 1 (247) | 131 | 2211–2372 | none (counter 3 loop) | `s3f1` Screw Mk 3 formation; `fl02` | `fgnu` 2.0→6 *after* both `ns02` 40.0→100 each |
| 11 | le10 Thermopylae | `11e1` End 1 (205) | 89 | 2250–2325 | none | `fl02` + sporadic; `bacc` NeoBaccula (invulnerable obstacle); `papu` from north | none |
| 12 | le09 Carthage | `12e1` End 1 (377) | 261 | 2750–2905 | `be02` Is Not Active → 140 → Delete; counter 4 on "Spawn Flippers" | `bacc` every 320; `fl02` | `be02` 2.0→6 *after* both `ns02` 40.0→100 each |
[HIGH for every number — decoded `leve`/`unde` files, scripted; MED for the pause-top arithmetic
(assumes the controller is live on its spawn tick: group of 1, `groupDelayMin` 0)]
Turret / bubble children of the gated bases above (decoded `unde`; shields = min(base +
increment × (sector − 1), max); float32 hit count as in §3.4; none of them is in the rule-#5 gate,
all die with their owner) [HIGH — data + numpy float32 replay] ⚑ corrected (review wave 1, 2026-10-03) #I1 (new):
| sec | base → child | child shields | bombs to kill the child alone |
|---|---|---|---|
| 1 | `plla` → `pllt` | 3.0 | 8 |
| 1, 2 | `tapu` → `tapt` | 3.0 (sec 1), 3.4 (sec 2) | 8, 9 |
| 3 | `bala` → `pllt`; spawned `tala` → `talt` | 3.0; 3.0 | 8; 8 |
| 4 | `twgu` → `tgtu` | 5.0 | 13 |
| 7 | `bala` → `pllt` | 3.0 | 8 |
| 10 | `fgnu` → `fgnt` | 1.0 | 3 |
| 12 | `be02` → `betu` | 1.0 | 3 |
| 2, 3, 8, 9, 10, 12 | `bsgr`/`bsde`/`bsat` → `bsbu`; `ns02` → `nsbu`; 6 `cara` → `cart` | 0.0 | — (hit swallowed, no effect) |
Practical reading: a bomb whose circle covers base and turret damages both (one `FUN_10014f10`
per overlapping B; the bomb is not deleted by hitting a turret, whose `damage_FLOAT` is 0.0, or
1.0 for `betu`/`fgnt`), so the base counts above hold as long as the bomb overlaps the base; a
bomb that only reaches the turret's circle is spent on the turret. [MED — group-list order and
the bomb's own shields not traced; review open question 2]

Lead-in: every final controller waits 180 ticks unpaused (`01b1`: 40 + 190) — 6 s at 30 ticks/s.
At 30 ticks/s the timer-only pauses run 27 s (sector 1) to 97 s (sector 12). Sector 1 also has an
earlier 800-tick pause (`01m1` at y 1395, Buzzsaw groups, no gate); other sectors have 2–4
earlier `s`/`m`/`p`/`b` controllers.

## 5. Boss-class composite units (the targets in the final screens)
| unit | parts (children spawned on S0 entry) | gate / special | attack pattern (turret) | label |
|---|---|---|---|---|
| `be02` Beamer Mk 2 (sec 12 finale; `be01` Mk 1 at sec 11 y 2435) | `betu` turret (passHits = ramming only; own shields 1.0 → 3 bombs; reflect hits, destroyed/deleted with owner), `ngsh` shield animation | S0 invulnerable (`+0x348`), `collision_Spawn ngsh` flashes on every hit; rule `nsde` "Number of This Type of Entity Active" range 2 → S1 (vulnerable, 2.0 shields, spawns `ngsh` once). Description: "Invulnerable until all Nuke Stations are destroyed." Destroy → `bede` FX, 4×`cals` coins, `pi5k` from the turret | `betu`: S0 wait 60 → S3 wait until player ≤ 300 → S2 track 40 → S1 attack 180 ticks: 2×5 `bebu` every 60 (dbe 4–5) → S4 pause 90 → S1 …; 2nd entry of S4 → S5 extended attack 60 ticks: 10 `bebu` (dbe 6) → S6 10 → S4 | HIGH (data) |
| `ns02` Nuke Station Mk 2 | `nsbu` bubble (passHits; 0.0 shields → swallows bomb hits on it) | 40.0 shields (no increment) → 100 bombs; destruct spawns `nsde`, whose S3 "Hang Around for Hits" (timer 0 → `No State`) never ends, so each destroyed station leaves one persistent `nsde`; the `== 2` rule therefore counts the two final-screen stations (earlier `nsde` are culled off-screen, 128-px margin `FUN_10012ca0`) | — | HIGH (data) / MED (culling of earlier markers) |
| `fgnu` Flare Gun Nuke (sec 10 finale; also sec 12 y 2409/2501) | `fgnt` turret (passHits; own shields 1.0 → 3 bombs) | identical `nsde == 2` gate; 2.0 → 6 bombs; `10e1` does **not** wait for it (timer-only) | `fgnt` same cycle as `betu` with `fgbu` | HIGH (data) |
| `twgu` Twin Gun (sec 4 finale) | `tgtu` turret (passHits; own shields 5.0 → 13 bombs), `tgca` cap | 12.0 (cap) → 31 bombs | `tgtu`: wait 90 → S3 until player ≤ 280 **or** rule `carf` (Radar flag) Is Active → track 80 → attack 270: 2×4 `tgbu` every 90 → wait 160 → attack … | HIGH (data) |
| `fg02` Flare Gun Mk 2 (sec 8 finale) | `polb` background only — the gun itself fires | 15.0 → 38 bombs | same 60/40/180/90/extended cycle as `betu`, range 300 | HIGH (data) |
| `pola` Popup - Large (sec 5, 6 finales) | `polb` background | invulnerable while closed (S0, S3, S4, S8); S0 waits for flag `plaf` Is Active within 400 px → open 24 → rotate 40 → attack 180 (8 `polp` per 60) → post 40 → close when animation stops → S3 70–85 (if `plsf` active → S8 do nothing forever) → reopen | (itself) | HIGH (data); range semantics HIGH (§3.1, ⚑ corrected (review wave 2, 2026-10-03) O3; was MED) |
| `popu` Popup (sec 8 finale) | `poba` | same pattern, flags `poaf`/`posf`, 6 `popr` per 40, random 0–70 open delay | (itself) | HIGH (data) |
| `bala` Laser Base / `plla` Laser Platform (sec 3, 7 / sec 1) | `pllt` turret (passHits; own shields 3.0 → 8 bombs), `pllc` cap | 6.0+0.4/sector (max 16) / 2.6+0.4 (max 6) | `pllt`: wait 90 → until player ≤ 260 → track 75–80 → attack: 6 `pllb` every 65–70 (dbe 2–3) | HIGH (data) |
| `tapu` Pulse Tank | `tapt` turret (passHits; own shields 3.0 + 0.4/sector, max 5.0 → 8 bombs in sector 1), `tapc` cap, `tatr` track marks | 1.5+0.4 (max 4); moves at 0.7–0.8 | `tapt`: wait 90–100 → until player ≤ 180 → track 70–75 → attack: 3 `tapb` every 80 | HIGH (data) |
(Turret shield figures added ⚑ corrected (review wave 1, 2026-10-03) #I1; source as the turret table in §4.)
Controller ⇄ unit coordination uses invisible **flag units** spawned at the controller's own
position (offset 0,0): the target polls them with `Is Active` (+ range) rules — `plaf`/`plsf`
(Large Popup), `poaf`/`posf` (Popup), `imof` (Iris Mine), `carf` (Radar → Twin Gun). [HIGH data;
MED that range is measured from the polling entity — `FUN_10035070` distance helper not read]
⚑ corrected (review wave 2, 2026-10-03) (O3): settled — rule 2 measures `dist(polling entity, flag) ≤ range` inclusive, with the
truncated-integer distance `FUN_10042e90` (§3.1, listing).

## Worked example — sector 1 (Mariner Valley, `le07`), the "Level 1 boss"
Controller `01b1` "Level 1 - Bridge", description "Pauses scrolling, spawns groups of Buzzsaws,
tank, waits all ground destroyed." Placed `#unit_ID <01b1> #layer_ID <grnd> #xLoc_INT <195>
#yLoc_INT <512>`. Unit: family `Level`, 3 states, `harmlessToPlayers` TRUE, every state
`Collides` FALSE, sprite `none`, shields 0, score 0, group 1 (delay 0). Spawned in the tick the
window top reaches 576 (`512 + 64`, `FUN_10010000`) = tick T0.

| state (file order) | timer | → | pause | rules | spawn sets |
|---|---|---|---|---|---|
| S0 `Wait` | 40..40 | S2 | no | — | — |
| S2 `Spawn Tank, Wait` | 190..190 | S1 | no | — | `Tank`: `tapu` at absolute (480,140), SetHeading 285°, rate 0–0, volley 1, dbe 0, repeat FALSE |
| S1 `Pause Until RULE, Spawn Buzzsa, Tank` | 800..800 | `Delete` | **yes** | r0: unit `NULL`, "No Destroyable Ground Entities Are Active", range 0 → `Delete` (r1–r4 inert: unit `none`) | `Buzzsaw Groups - Top of Screen`: `bu01` at absolute (208,−100), rate 100–115, volley 1, dbe 0, repeat TRUE |

Timeline (ticks; 30 ticks/s):
1. **T0** live at once (spawn delay 0), state S0. Scroll keeps moving.
2. **T0+40** timer → S2. `FUN_10017cb0` arms `Tank`; `FUN_10015b40` spawns one Pulse Tank the same
   tick at screen (480,140) — 64 px right of the 416-px game area — heading 285°. Its S0 spawns
   turret `tapt`, cap `tapc` and track marks.
3. **T0+230** timer → S1; pause flag set this tick (§2.2) → scroll stops from T0+231 with
   window top **346**: map rows 346–826 stay on screen until the controller dies. Same tick: the
   ground rule is evaluated (if already true, the controller deletes now and the pause lasts one
   tick); otherwise the Buzzsaw set fires its first volley: one `bu01` group request = 5–6
   Buzzsaw Mk 1 (`numInGroup` 5–6, staggered `groupDelay` 9–22 ticks each) from (208,−100).
4. Every tick in S1: rule r0 — false while any `includeInGroundAccuracyCount` entity is inside
   0≤x≤416, 0≤y≤480. Buzzsaw groups at T0+230, then T0+230+R1+1, +R2, … (R = 100–115) — 7 or 8
   groups (35–48 Buzzsaws) if the pause runs to its end.
5. Exit: first tick the gate holds → `Delete`; else **T0+1030** timer → `Delete`. Next tick the
   scroll resumes; **345** more ticks bring the top from 346 to 1 → level end → `nole` "Sector
   Secured" at (208,240). The Buzzsaws at rows 204 and 149 spawn during that run-out.

The gated set while paused (sector 1 shields = base, increment unused):
| target | where | shields | Plasma Bomb hits (0.4) | Ion Cannon hits | score / drops |
|---|---|---|---|---|---|
| `plla` Platform - Laser (+`pllt` turret: passHits = ramming only, +`pllc` cap) | map (370,531) → screen (338,185) | 2.6 (2.5999999f) | **7** (2.2, 1.8, 1.4, 1.0, 0.6, 0.2, −0.2) | 0 — layer `grnd` ≠ `air ` | 0 points, 2 × `cass` coins, FX `plld` |
| `tapu` Pulse Tank spawned by S2 (+`tapt`) | enters from x 480 | 1.5 | **4** (1.1, 0.7, 0.3, −0.1) | 0 | 200, 1 × `cass` |
| `tapu` Pulse Tank placed at map (465,665) | screen x 433 → counts only once it drives into x ≤ 416 | 1.5 | **4** | 0 | 200, 1 × `cass` |
| `pllt` turret on the platform (not gated; dies with `plla`) | on the platform | 3.0 | **8** if hit alone | 0 | 0 points, no coin |
| `tapt` turret on each tank (not gated; dies with `tapu`) | on the tank | 3.0 | **8** if hit alone | 0 | 0 points, no coin |
| `bu01` Buzzsaw Mk 1 (not gated; air) | groups from (208,−100) | 0.4 | — (bombs are ground layer) | **1** (0.4f − 0.4f = 0.0 ≤ 0) | 50; no per-kill coin (`destructCoin_ID none`, skipped at `100361d4–100361dc`), one `cass` for the whole group (`destructCoinOnGroupKill_ID`) ⚑ corrected (review wave 1, 2026-10-03) #M2: was "50, 1 coin" |
So with the default weapons the sector-1 "boss" costs **7 + 4 (+4) = 11–15 Plasma Bomb
impacts on the bases** (a bomb that reaches only a turret's circle is spent on the turret: 8 to
kill `pllt` or `tapt` alone, which does not advance the base) ⚑ corrected (review wave 1, 2026-10-03) #I1; the default air weapon (Ion Cannon, `aiic`, `DEAA`, a pair of `icb ` per launch,
`delayBetweenLaunches 4`) cannot damage any of the gated targets. A bomb collides only in its
1-tick `Dwindle & Delete` state (`plbo` S1 is the only `Collides` state), and the 1-tick hit delay
applies per victim, so a bomb that touches both turret and platform hits **both** (one 0.4 hit
each: the turret on its own shields, the platform on its own) — not "one impact = one hit". ⚑ corrected (review wave 1, 2026-10-03) #I1
(review open question 2): was "the 1-tick hit delay stops a bomb that touches both turret and
platform from counting twice — one impact = one 0.4 hit".
Ramming any of them deals 100 (instant kill) to the target and a hit to the player.
[HIGH for data values, state graph, hit counts and the pause/scroll numbers; MED for: the
spawned tank's entry path (movement executor not read), "both overlapping victims are hit"
(group-list order and the bomb's own survival not traced), per-launch bomb count (flli 151/152 handling not read)]

## NOT RESOLVED (this file)
1. ~~`FUN_10035070` range semantics: which position is passed (`param_2`) and the distance helper
   `FUN_10042e90` — settles whether `plaf … 400` means "flag within 400 px of the Popup". Read
   both in raw listing.~~ → ⚑ corrected (review wave 2, 2026-10-03) #S (O3): §3.1 — `param_2` = the polling entity's position,
   distance = `FUN_10042e90` (damage-health-death.md §1, HIGH), test `dist ≤ range` inclusive
   (`10035184 fcmpo; 10035188 cror eq,lt,eq`), range 0 = any. So `plaf … 400` = "a live `plaf`
   within 400 px (integer-truncated) of the Popup".
2. `FUN_10017e70` (shield-depletion state switch) and `FUN_10035cd0`'s `+0xcd` setter — data never
   uses the key, so behaviour-neutral for 1.0.6; read for mod support only.
3. ~~B-side `passHitsToOwner` in `FUN_10036cf0` uses **A's** owner — does the redirect ever
   succeed?~~ → closed: never for player shots (no owner: template `0x100ecd14` +0x20 = 0, +0x24 = −1 [⚑ corrected (wave 3+4, 2026-10-04): was "+0x20/+0x24 = 0"; static-init-audit.md §5.2],
   neither launcher `FUN_1003c4f0`/`FUN_1003c7a0` sets them), so the turret absorbs the hit; §3.5. ⚑ corrected (review wave 1, 2026-10-03) #I1
4. ~~Whether ground-placed spawn-set children get the −32 x shift (`FUN_10035900` applies it to
   level objects; spawn requests via `FUN_10033220` not checked) — decides whether the sector-1
   tank appears at screen x 480 or 448.~~ → ⚑ corrected (review wave 3, 2026-10-06) #S: loose-ends-combat.md §5.1: the −32 x shift applies to level objects only; spawn requests via `FUN_10033220` get no shift (critic wave 3 §3).
5. ~~Movement of the Pulse Tanks (heading 285° convention, `FUN_10042b30`; executors
   `FUN_10015930`/`FUN_10015280`) — decides when they enter the on-screen gate.~~ → ⚑ corrected (review wave 3, 2026-10-06) #S: loose-ends-combat.md §1.2–§1.4 (heading convention settled; Pulse Tank vector HIGH, timing MED) (critic wave 3 §3).
6. ~~Plasma Bomb launches per press and `WepHandler_Default/MaxNumBombs` (flli 151/152,
   `FUN_1003beb0`) — the guide's "automatically increases in power as you progress" is not in the
   `wede`/`unde` damage numbers (0.4 in every sector); likely bomb count. Needed for time-to-kill.~~ → ⚑ corrected (review wave 3, 2026-10-06) #S: loose-ends-combat.md §6.6: the bomb count per press is what "increases in power" (listings `1003beb0..1003bf74`, `1003b964..1003b9d0`); bomb damage stays 0.4 (critic wave 3 §3).
7. ~~`FUN_10034ee0` "Is Tracking Player" (rule #0) not read — no boss uses it (2773 uses, all with
   unit `none` except two), low priority.~~ → ⚑ corrected (review wave 3, 2026-10-06) #S: spawn-and-waves.md §6 (rule callees, `FUN_10034ee0` read) (critic wave 3 §3).
8. ~~End-of-level tally (`FUN_100072c0`, `FUN_100075e0`, `FUN_10027670`, `FUN_10027930`) and the
   sector-12 finale (`noal`, `Spawn Game Completion` state) — INDEX NR #26/#27, not read here.~~ → ⚑ corrected (review wave 3, 2026-10-06) #S: loose-ends-session.md §5 (finale sequence) and scoring-bonuses.md §6/§8 (tally, INDEX #26/#27 closed) (critic wave 3 §3).

## Role-table rows (for merge)
| function | module | role | conf | evidence |
|---|---|---|---|---|
| ⚑ corrected `FUN_10036cf0` |  | entity-vs-entity collision: same layer (unit+8), opposite harmless side, projectile/hittable pairing, shape test; A takes B.damage_FLOAT (or A's owner if A's state passHitsToOwner), then B takes A.damage (B's passHitsToOwner tests A's owner — never succeeds for player shots, so turrets absorb hits); returns A deleted. Was "state spawn sets executor" LOW; ⚑ corrected (review wave 1, 2026-10-03) #I1 B-side clause | HIGH | raw `10036fc4..100370e8` (`lfs f1,0x274(r4)`), dump; caller `FUN_10033850` (`10034594 bl`, gated by state +0x347 Collides) |
| `FUN_10015b40` |  | state spawn-set executor (volley/rate/delay/offset/absolute/heading/offscreen/fleeing) → `FUN_10033220`. waves §3 step 7 listed it as movement (not read) | HIGH | raw `10015c70..10015f98` offsets = spawn-set keys; caller `FUN_10033850` |
| `FUN_10017150` |  | spawn-time rotation gate: DoRotateToTarget state (+0x303), hold rotation while a PauseAnyRotationWhileSpawning volley is in progress, else `FUN_100172d0` | HIGH | listing `10017180 lbz r0,0x303(r31)`, `1001725c lbz r0,0x48(r25)`, `100172a4 bl 0x100172d0`; caller `FUN_10015b40` — ⚑ corrected (review wave 1, 2026-10-03) (conflict resolution): was MED (dump) |
| `FUN_100144a0` | G_Entity.cc | bind unit to entity; allocate per-state spawn-info lists (0x18-byte records, entity+0x19c+4s) | MED | dump, asserts `fStateSpawnInfoLists…`, `newSpawnInfoPtr`; caller `FUN_10035cd0` |
| ⚑ corrected `FUN_10017cb0` |  | arm all spawn sets on state entry: rate, last=now, volley=left, delay; sets entity+0xc3 "has sets". (was MED "init state spawn-set timers" — same role, now raw-checked) | HIGH | raw `10017d4c..10017db8`; caller `FUN_100146f0` |
| ⚑ corrected `FUN_100146f0` | G_Entity.cc | change state by name; stamps +0xa4, draws timer +0xb8, increments entry counter +0x14c+4s and applies OnCounter (+0x3b4 → +0x51c); re-arms spawn sets (was MED, strings) | HIGH | dump; OnCounter compare quoted §3.2; callers `FUN_10033850`, `FUN_10015550`, `FUN_10014f10`, `FUN_10015280`, `FUN_10035cd0`, `FUN_10017e70`, `FUN_10014670` — ⚑ label audit (review wave 1): HIGH kept — listing evidence in units-movement.md role rows |
| ⚑ corrected `FUN_10014f10` |  | damage entity: hit delay PermFloat167, float32 shields −= dmg, invulnerable restore, OnHit (needs delay ≠ 0), glow/particles/sounds/collision spawn, kill → score + destroy or shield-depletion path (was MED, perm F167) | HIGH | raw `10014f10..10015074`; callers `FUN_10036cf0`, `FUN_10033850` |
| ⚑ corrected `FUN_100353e0` |  | rule #5: any entity with unit includeInGroundAccuracyCount (+0x134) that is on-screen (`FUN_10016bd0`) | MED | dump; caller `FUN_10015550` — ⚑ label audit (review wave 1) |
| ⚑ corrected `FUN_100352f0` |  | rule #4: any entity with unit includeInAirAccuracyCount (+0x133); no live/on-screen test | MED | dump; caller `FUN_10015550` — ⚑ label audit (review wave 1) |
| `FUN_100351f0` |  | count entities of unit with spawn delay over (rule #14–16) — unchanged role, now read | MED | dump — ⚑ label audit (review wave 1) |
| `FUN_10035070` |  | rule #2 "Is Active": live entity of unit (spawn delay ≤ 0) exists, within `dist ≤ range` (inclusive) of the polling entity; range 0 = any; unit `none` → false | HIGH | listing `10035140 cmpwi r23,0x0; beq` (range 0), `10035158 bl 0x10042e90`, `10035184 fcmpo cr0,f1,f2; 10035188 cror eq,lt,eq`, `100351ac beq` skip (`$W/disasm-bosses.txt`) — ⚑ corrected (review wave 2, 2026-10-03) (O3): was MED "distance helper not read" |
| `FUN_10016bd0` |  | entity on-screen test 0≤x≤416, 0≤y≤480 inclusive | HIGH | raw listing; callers `FUN_10015b40`, `FUN_100353e0` |
| `FUN_10036ab0` |  | owner link valid (ptr, serial +0x9c, not deleted) | MED | dump (4 lines) — ⚑ label audit (review wave 1) |
| `FUN_10036930` |  | copy owner visibility / scale / hit-glow fields (useOwners*, visuallyReflectOwnerHits) | HIGH | raw `10033f4c..10033f58` args; dump |
| `FUN_100363c0` |  | destroy children whose state has canBeDestroyedOnOwnerDestruction | MED | dump; caller `FUN_10036120` |
| `FUN_10036120` | G_EntityGroup.cc span | remove entity from group: children destroy/delete, coins, group-kill coin, destroy | MED | dump |
| `FUN_1000fa90` |  | level scroll init: top = 3600−480, progress = 481, speed 1 | HIGH | dump; feeds `FUN_10010000` compare (raw) |
| ⚑ corrected `FUN_10010000` |  | scroll step; level end when progress (r2−0x61e4) ≥ level bottom (3600) i.e. top = 1 (was "level-end flag" — now the exact criterion) | HIGH | raw `10010000..1001009c` |
| ⚑ corrected `FUN_10010570` |  | console REVERSE handler: speed −1 ↔ 1 unless level ended (SCROLL/SCROLLING is undefined `0x100104f0`) | HIGH | listing `10010570..100105f8`; TOC `0x100df07c` → TVector `0x100e0890` → `0x10010570` (registered as REVERSE in `FUN_1000f7a0`) — ⚑ corrected (review wave 1, 2026-10-03) (conflict): was "console SCROLL toggle 1 ↔ −1" MED |
| ⚑ corrected `FUN_1003cf10` | G_UnitDefinitions.cc | unit-module init: register "Unit Definition", register 5 console names on 4 handlers (LOGSCROLLPAUSERS, LOGFAMILIES/FAMILIES, LOGUNUSEDUNITS, UNITSCORES; handlers are undefined code `0x10041a40/b30/b70/d70`), then Units Cache read `FUN_100420f0` or full build `FUN_1003d0a0(1)` | HIGH | listing `1003cf34 bl 0x1003a870`, `1003cf5c…1003cfdc` 4× `bl 0x1002d080`, `1003cfe4 bl 0x100420f0`, `1003d000 bl 0x1003d0a0`; caller `FUN_100000e0` — ⚑ corrected (review wave 1, 2026-10-03) (conflict): was "console unit commands" LOW; unit-def-struct.md §1 had it right |
| ⚑ corrected `FUN_1003fc50` | G_UnitDefinitions.cc | load unit i; sets unit+8 layer = 'grnd' if isGroundBased else 'air ' (the collision layer) | HIGH | raw `1003fd20..1003fd44` |

## INDEX updates (for merge)
- **NR #20** (spawn-set executor `FUN_10036cf0`): narrowed/re-targeted — the executor is
  `FUN_10015b40` + arming `FUN_10017cb0` (bosses.md §3.3, HIGH for volley/rate/delay/repeat);
  still open there: absolute-coordinate frame and the −32 ground shift for children (this file NR 4).
  `FUN_10036cf0` is collision (⚑ conflict with waves-and-enemies.md §3 step 9 / §4 / §8 #2 and
  function-roles.md §1 row).
- **NR #22**: `FUN_10035070` (Is Active) read at MED (bosses.md §3.1); `FUN_10034ee0`,
  `FUN_10017ef0` still open.
- **NR #24**: `FUN_10014f10` damage closed (bosses.md §3.4); `FUN_10042f80`, `FUN_10026c90` open.
- New topical-file row: `bosses.md` — 1 negative evidence; 2 scroll-pause gate + level end;
  3 rule callees, OnCounter, spawn sets, damage/layers, parts; 4 per-sector end table; 5 composite
  units; worked example sector 1.
- New NOT-RESOLVED candidates: B-side `passHitsToOwner` uses A's owner (bosses.md NR 3 — closed in the fix pass, §3.5, ⚑ corrected (review wave 1, 2026-10-03) #I1);
  inert `invulnerableUntil…` keys (§3.5, MED).
- ⚑ conflict (waves-and-enemies.md §3 step 7/9): spawn sets are executed by `FUN_10015b40` for every
  on-screen entity, not by `FUN_10036cf0` for colliding entities; controllers (Collides FALSE) do
  spawn.
