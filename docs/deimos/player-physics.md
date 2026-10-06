# Deimos Rising 1.0.6: the player ship (G_Player.cc): movement, life cycle, shields, `plde`

Scope: address range `0x10026100–0x1002a660` (G_Player.cc span `10026410–1002a450` plus the
bracketed neighbours `10026100–100263a0` and `1002a4f0–1002a610`; see `$W/inventory.txt`), and the
`plde` parser `FUN_10039e70` for the key→offset table only. **Out of scope** (other readers):
`FUN_10029a10` (add score / extra lives), `FUN_10027670`, `FUN_10027930`, `FUN_10027e50` (I read
only its player-side writes: state, invulnerability, lives; §5), `FUN_10029fe0` (scoring reader),
`FUN_10026c90`/`FUN_10026c10` (damage reader; I read them because the update calls them, §8 ⚑),
the weapon handler at player `+0x240` (`FUN_1003a…–1003c…`), and the registration check.
`$W` = `/Users/andiyar/ghidra-proj-deimos`. Raw listings: `$W/disasm-player2.txt` (every function
in scope + `FUN_10029a10`, `FUN_10005cd0/cf0`), `$W/disasm-player.txt` (`FUN_10039e70`),
`$W/disasm-player3.txt` (`FUN_10027e50`, `FUN_10006b50`, `FUN_10012750`), all made with
`DisasmFuncs.java` against the copy `$W/work-player`. Constants come from the memory image through
`mem.py` (`struct.unpack('>f', image[addr-base:…])`, code base 0x10000000, data base 0x100de330).
Recurring TOC pointers: `r2-0x702c` → `0x100df304` → float table `0x100d6fc8` =
`[0.0, 100.0, 1324366.0, 1.0, -32.0]` (called **pf[0..4]** below); `r2-0x7038` → `0x100df2f8` →
double table `0x100d6fdc` = `[2^52+2^31 (int→float bias), 100.0, 0.0]` (**pd[0..2]**);
`r2-0x7034` → `0x100df2fc` → `0x100d6ec8` = `(0.0, 0.0)` (the reset velocity).
One logic tick = one call of `FUN_10006b50`, and `now` = game time `game+0x1c`, +1 per tick
(engine-loop.md §3).

## 1. The player object (`0x36c` bytes, `FUN_1004d320(0x36c)` in `FUN_100051a0`)
The player is an entity-sprite object (shared helpers `FUN_10012…` in the entity/sprite module)
extended with player fields. Field table (offsets from raw listings unless marked):
| off | type | meaning | evidence |
|---|---|---|---|
| +0x00/+0x04 | float | x, y in **visible-game-area coordinates** (y down; 0..416 × 0..480) | `100294e0..10029500` integrate; clamps §2.3 use flli 54/55 |
| +0x10/+0x14 | float | vx, vy (px/tick) | §2.1 listing |
| +0x1c | ID | ship sprite = air weapon's `player1AppearanceFace_ID` (+0x144, P1) or `player2AppearanceFace_ID` (+0x148, P2) | `FUN_10029f60` `10029fa0 lwz r0,0x144(r3)` / `10029fac lwz r0,0x148(r3)`, r3 = `FUN_1003bce0(+0x240)` [MED that it is the current air weapon] |
| +0x20 | int | sprite frame 0..6: 0 level, 1–3 bank left, 4–6 bank right | §2.4 |
| +0x2c/+0x30 | int | half frame width / height (`FUN_10012940`: w/2, h/2) | dump `FUN_10012940` [MED, outside range] |
| +0x58..+0x64 | float/u16 | glow current/target/rate/colour (used by overload flashes) | §6 |
| +0x68/+0x6c/+0x70 | float | appear fade current / required / delta | §4.3 |
| +0x94 | ptr | `plde` definition | `FUN_10026410` `10026490 stw r3,0x94(r27)` |
| +0x98 | int | **lives, obfuscated** stored = lives + 0x1524dcef | `FUN_10026d60` `addis r4,r4,0x1525; subi r0,r4,0x2311; stw r0,0x98(r3)` |
| +0x9c/+0xa0 | int | next extra-life score threshold / extra-life step increment (set 0 at session start; `threshold += AdditionalRequired + step`, `step += flli 182` — scoring-bonuses.md §3.1) | `FUN_10026cc0` `10026d10 lwz r3,0x68(r3); stw r3,0x9c(r31)` — ⚑ corrected (review wave 1, 2026-10-03) #M6: +0xa0 was "(cleared)" |
| +0xa4 | float | max speed = `active_DefaultMaxSpeed` | `FUN_10026cb0` `lfs f0,0xd4(r4); stfs f0,0xa4(r3)` |
| +0xa8 | float | **shield %, obfuscated** stored = shield + 1324366.0 (pf[2]) | `FUN_10027540` `lfs f1,0xa8(r3); lfs f0,0x8(r4); fsubs f1,f1,f0` |
| +0xac | int | money held, obfuscated (+0xb2cce) | `FUN_10027610` `subis r3,r3,0xb; subi r3,r3,0x2cce` |
| +0xb0 | int | score, obfuscated (+0x5532a3e) | `FUN_100299f0` `subis r3,r3,0x553; subi r3,r3,0x2a3e` |
| +0xb4 | u8 | score multiplier 1,2,3,4,5,10 | `FUN_10029b20` jump table §7 |
| +0xc4 | u8 | in game (has not been eliminated) | `FUN_10026c10 lbz r3,0xc4(r3)` |
| +0xc5 | u8 | appear-fade running | §4.3 |
| +0xc6 | u8 | life state 0..4 (§4) | `FUN_10026c80` |
| +0xc8 | int | time the state was entered | `FUN_10026c80` |
| +0xcc | s8 | player index 0/1 (0xff = unused) | constructor `10026310 stb r4,0xcc(r3)` |
| +0xcd | u8 | number of players in this game (1 or 2) | `FUN_10026410` `10026434 stb r28,0xcd(r3)`, r28 = `game+0x21` |
| +0xce/+0xcf | u8 | invulnerable / invulnerability is sticky | `FUN_10027dd0`, `FUN_10027de0`, §5 |
| +0xd0 | u8 | hit this level (defence bonus forfeited or already paid) | §3, §6 |
| +0xd1 | u8 | shield-warning object already spawned | §3 |
| +0xd4 | int | time of the last banking-frame opportunity | §2.4 |
| +0x1fc..+0x202 | u8×7 | input: up, right, down, left, fire ground, fire air, select | engine-loop.md §8 (HIGH) |
| +0x204/+0x208 | int | last accepted hit time / last spawn-on-hit time | §3 |
| +0x20c | int | crosshair forward adjustment 0..80 | §2.5 |
| +0x210..+0x220 | | overload warning: active, phase, (0.0), last flash, interval, count | §6 |
| +0x224..+0x23c | | integrity-check schedule (P1 only) | §9 |
| +0x240 | struct | weapon handler (out of scope); +0x2b4 = handler+0x74 = ground weapon def; +0x2cc = crosshair sprite; +0x360 = crosshair visible | `FUN_1003b3c0` dump: `+0x120 = 1`, `+0x74)+0x1b4`, `+0x74)+0x168` [MED] |
[HIGH for every offset whose evidence column quotes a listing; MED where marked]

## 2. Movement: `FUN_10028170 @ 10028170`, per tick, per player
Caller `FUN_10006b50` (the logic tick) loops P1 then P2:
`FUN_10028170(player, startedFlag, filmFlag, now, film, game+0x20 (playback), game+0x39 (level complete))`
(dump `FUN_10006b50` lines 64–69; arg registers r4..r9 saved as r17,r16,r26,r15,r14,r19 at
`10028184..10028198`). Order inside the update when `+0xc4` (in game) is set
(`10028f30 lbz r0,0xc4(r31); beq 0x100298a8`):
1. defence bonus (§6), 2. `FUN_1002a150` life-state step (§4), 3. `FUN_1002a3a0` input
(clear 7 bytes, film or ISp; state 4 only), 4. `FUN_10012840` (second fade), 5. `FUN_10026ee0`
overload warnings (§6), 6. `FUN_10012750` (glow + appear fade step), 7. clear `+0xc5` when
`+0x68 == +0x6c` (`10029094..100290a8`), 8. `FUN_10012940` (frame size → half w/h),
`FUN_10012c10` (blink), 9. **only if state == 4** (`100290c4 cmplwi r0,0x4; bne 0x100298a8`):
weapon handler `FUN_1003b3c0` (only when `+0x84 == 1.0`, pf[3]), velocity, banking frame,
integrate, view shift, clamps, `FUN_1003bb00`, crosshair. [HIGH — listing order]
Nothing in the movement path draws from the RNG (no call to `FUN_10046580`/`FUN_100465e0` in
`FUN_10028170`). [HIGH — `grep -c 'bl 0x1004658\|bl 0x100465e' d28170.txt` → 0]

### 2.1 Velocity: constant acceleration, hard cap, linear decay [HIGH]
step = `plde.active_VelocityDelta` (+0xd8, 1.6), cap = `+0xa4` = `active_DefaultMaxSpeed` (7.8):
```
100291f4  lfs f3,0xa4(r31)        ; cap
100291f8  lfs f0,0xd8(r3)         ; step   (r3 = plde)
10029208  fsubs f1,f1,f0 ; stfs f1,0x14(r31)        ; up:    vy -= step
10029214  fcmpo cr0,f1,f2 ; bge  ; stfs f2,0x14(r31) ;        if vy < -cap: vy = -cap
1002922c  fadds … 0x14 ; 10029238 fcmpo f1,f3 ; ble  ; down:  vy += step; if vy > cap: vy = cap
10029254  fsubs … 0x10 ; … bge                       ; left:  vx -= step; clamp -cap
10029278  fadds … 0x10 ; … ble                       ; right: vx += step; clamp +cap
10029290  (left==0 && right==0):
100292a4  lfd f2,0x10(r20)  ; pd[2] = 0.0
100292a8  fcmpo f1,f2 ; ble ; fsubs ; … bge ; lfs f1,0x0(r22) ; if vx > 0: vx -= step; if vx < 0: vx = 0
100292d4  fcmpo f1,f2 ; bge ; fadds ; … ble ; lfs 0.0       ; if vx < 0: vx += step; if vx > 0: vx = 0
100292f8  (up==0 && down==0): same decay on vy (10029308..1002935c)
```
Opposite keys held together cancel (both blocks run: −step then +step). Decay is linear (one
step per tick toward 0, snapping to exactly 0), not multiplicative drag. Axis velocities are
independent; there is no diagonal normalisation (diagonal speed up to 7.8·√2 ≈ 11.03).

### 2.2 Integration [HIGH]
`100294e0 lfs f1,0x0(r31); lfs f0,0x10(r31); fadds; stfs f0,0x0(r31)` (x += vx), same for y at
`100294f4..10029500`, **after** the velocity update and the frame step, in single precision.

### 2.3 Clamp to the game area [HIGH]
`W` = int(flli 54 VisibleGameWidth 416), `H` = int(flli 55 VisibleGameHeight 480), `T` =
int(flli 183 Player_TopGameAreaLimit 13), `hw`/`hh` = `+0x2c`/`+0x30` (half sprite frame):
```
10029580  lfs f0,0x10(r22)       ; pf[4] = -32.0
10029588  fsubs f1,f3,f1 ; fcmpo f1,f0 ; bge   ; if x - hw < -32:  x = hw - 32   (subi r0,r3,0x20), vx = 0
100295c0  addi r0,r17,0x20 ; … fadds ; fcmpo ; ble ; else if x + hw > W + 32: x = W - hw + 32, vx = 0
10029618  li r3,0xb7 ; bl 0x10020250 ; fctiwz      ; T = 13
10029664  fsubs f1,f3,f1 ; fcmpo ; bge           ; if y - hh < T:  y = T + hh (add r0,r6,r5), vy = 0
100296bc  fadds ; fcmpo ; ble ; subf r0,r5,r16   ; else if y + hh > H: y = H - hh, vy = 0,
100296e0  li r15,0x1                             ;      bottomPinned = 1 (used by the crosshair)
```
So the ship may slide 32 px under each side border (the visible window can itself shift ±32 in
the 480-wide map, engine-loop.md §5), never above row 13, never below the screen bottom. Clamping
zeroes the velocity on that axis only.

### 2.4 Banking frame, timing flli 166 [HIGH]
```
10029360  li r3,0xa6 ; bl 0x10020250 ; fctiwz   ; k = int(flli 166 Player_TimeBetweenFrameChanges) = 1
10029370  lwz r0,0xd4(r31) ; add r0,r0,r3 ; cmpw r26,r0 ; ble 0x100294e0   ; skip unless now > last + k
1002938c  stw r26,0xd4(r31)                                             ; last = now (every opportunity)
```
then one of three 7-entry jump tables (not shown by Ghidra's listing; read from the image:
`python3 -c "from mem import *; print([hex(U(0x100e6330+o+4*i)) for i in range(7)])"` for
o = 0x3074/0x3058/0x303c; each case is `li r0,N; stw r0,0x20(r31); b`, e.g. `0x38000004 0x901f0020`):
| frame now | 0 | 1 | 2 | 3 | 4 | 5 | 6 |
|---|---|---|---|---|---|---|---|
| no left/right (table `0x100e93a4`) | 0 | 0 | 1 | 2 | 0 | 4 | 5 |
| left held (`0x100e9388`) | 1 | 2 | 3 | 3 | 3 | 4 | 5 |
| right held, not left (`0x100e936c`) | 4 | 0 | 1 | 2 | 5 | 6 | 6 |
Left wins when both are held (the left test is first, `10029388`/`10029404`). With k = 1 the
frame moves at most one step every **2** ticks. Quirk to replicate: left from frame 4 jumps
straight to 3 (full left bank), while right from the left bank walks 3→2→1→0→4.
`+0xd4` is reset to 0 by `FUN_10029f10` (respawn / level start), so the first opportunity after
appearing is immediate.

### 2.5 View shift driven by left/right input [HIGH]
`10029504..10029524`: left held → `FUN_100100b0(0)`; else right held → `FUN_100100b0(1)`.
`FUN_100100b0` moves the map window offset `_DAT_100e0144` by −1/+1 per call, clamped to
[−32, 31] (engine-loop.md §5). It is the **input**, not the ship's x, that drives the shift, and
in a two-player game both players call it in the same tick (P1 first), so opposite inputs cancel.

### 2.6 Crosshair (ground-weapon aim), flli 185–187 [HIGH arithmetic; MED for the flag]
Runs only when `+0x360` (weapon handler +0x120, set by `FUN_1003b3c0` while the ground weapon
is being fired) is set (`10029704`): ⚑ corrected (wave 2, 2026-10-03): was "set … while the ground weapon is being
fired" — `1003b9ec stb r4,0x120(r22)` (r4 = 1) runs on every handler tick and no clearer exists, so
the flag is 1 from the player's first active tick for the rest of the session — see
loose-ends-combat.md §6.2.
```
10029710  cmplwi r14,0x0 (down) ; rlwinm. r0,r15 (bottomPinned)
10029720  li r3,0xb9 …  add  ; stw r0,0x20c(r31)   ; down AND pinned at bottom: adj += int(flli 185 Crosshair_DownSpeed 3)
10029734  li r3,0xbb … cmpw r0,r3 ; ble ; stw r3   ;   if adj > int(flli 187 Crosshair_MaxAdjustment 80): adj = 80
10029770  cmpwi r0,0x0 ; ble                       ; otherwise, if adj > 0:
1002977c  li r3,0xba … add ; … bge ; li r0,0      ;   adj += int(flli 186 Crosshair_UpSpeed −4); if adj < 0: adj = 0
100297b4  lwz r6,0x2b4(r31) ; lwz r5,0x178(r6)     ; cx = x + groundWeapon.crosshairXOffset (+0x178)
100297f8  lwz r0,0x17c(r6) … lwz r0,0x20c(r31)     ; cy = y + groundWeapon.crosshairYOffset (+0x17c) + adj
10029838  bl 0x10012ba0 ; srawi r4,r3,0x1          ; ch = crosshair sprite height / 2 (round toward 0)
10029878  fsubs f1,f3,f1 ; fcmpo f1,f0 ; bge       ; if cy - ch < 0.0: cy = ch
100298a0  bl 0x10012910                            ; set crosshair sprite (+0x2cc) position
```
Plasma Bomb (`plbo`, the only ground weapon): `crosshairXOffset 0`, `crosshairYOffset -121`
(decoded `wede`), so the target marker sits 121 px ahead of the ship; pressing down while pinned
against the bottom edge pulls it back toward the ship by 3/tick to at most 80 px (−41 ahead),
releasing returns it at 4/tick. The crosshair fade rates flli 149/150 are not read here (not
consumed by `FUN_10028170`; NOT RESOLVED 4). Where bombs land relative to the crosshair is the
weapon launcher's (`FUN_1003c4f0`, other reader).

## 3. Hits: `FUN_10027100 @ 10027100(player, ?, now, f1 = hit factor)` [HIGH]
Only caller `FUN_10033850` (entity update / collision, `$W/callers.txt`).
```
1002712c  lbz r0,0xc6(r3) ; cmplwi 4 ; bne end        ; only in state 4
1002713c  lwz r5,0x204(r28) ; lwz r0,0x54(r4) ; add ; cmpw r29,r0 ; blt end
                                                    ; ignore unless now >= lastHit + shieldHitDelay (+0x54, 1)
10027150  stw r29,0x204(r28)                        ; lastHit = now
10027154  bl 0x10027dd0 ; bne 0x100271bc            ; if not invulnerable (+0xce):
10027174  lwz r0,0x50(r4) … fmuls f31,f30,f0        ;   dmg = f1 × shieldBaseHitPercentage (+0x50, 15)
1002719c  fsubs f1,f1,f31 ; … ble ; stb 1,0xd0(r28) ;   shield -= dmg; if dmg > 0: +0xd0 = 1 (no defence bonus)
100271c8  fcmpo f1,0.0 ; bge ; bl 0x10027e50        ; if shield < 0.0 (strict): destroyed (§5), return
100271f4  lhz r4,0x58(r5) ; lwz r5,0x5c(r5) ; bl 0x10012bc0   ; hit glow: hitGlowColor (+0x58), hitGlowSpeed (+0x5c)
10027208  fcmpo f30,0.0 ; ble end                   ; rest only if f1 > 0:
10027214  lwz r3,0xc8(r3) …  li r3,0xa2 …           ;   if active_SpawnOnHit_ID (+0xc8 'plsh') != none and
10027244  cmpw r29,r0 ; blt                          ;     now >= lastSpawn (+0x208) + int(flli 162 Player_DelayBetweenHitSpawns 10):
1002724c  stw r29,0x208(r28) … bl 0x10033220        ;     lastSpawn = now; spawn 'plsh' at the ship (player index in the request)
100272e8  lbz r0,0xd1(r28) ; bne end                 ;   if shield warning not yet shown and
10027324  fcmpo f1,f0 ; cror eq,lt,eq ; bne end      ;     shield <= shieldWarningPercentage (+0x4c, 15):
10027330  lwz r27,0xcc(r3) … bl 0x10033220 ; stb 1,0xd1;     spawn active_ShieldWarningObject_ID ('nosw') if not none; +0xd1 = 1
```
Consequences: a hit with factor f costs 15·f shield points (f = 1 → 7 hits from 100 leave −5,
so the **7th** full hit destroys: 100→85→70→55→40→25→10→−5); a hit landing exactly on 0 survives.
While invulnerable the glow and the spawn-on-hit still happen but no shield is lost. Hits are
accepted at most once per `shieldHitDelay` ticks. The meaning of the hit factor f1 (damage
scaling from the attacker) is the damage reader's.
Shield pickups: `FUN_10027490(player, f1 = delta)` (caller `FUN_10037580`): if in game and
delta ≠ 0, shield = clamp(shield + delta, 0.0, 100.0) (`100274e0 fadds; lfd f0,0x8(r30)` = 100.0;
`100274f8 lfd f0,0x10(r30)` = 0.0). [HIGH]

## 4. Life states and the respawn cycle: `FUN_1002a150 @ 1002a150(player, now, gate)` [HIGH]
State byte `+0xc6`, entered at `+0xc8` (`FUN_10026c80` stores both). Dispatch `1002a188..1002a1b0`:
| state | meaning | per-tick rule (plde keys) | evidence |
|---|---|---|---|
| 0 | none | — | |
| 1 | out of lives | if `now > enter + gameOverTime` (+0x80, 20): `+0xc4 = 0` (player leaves the game) | `1002a24c..1002a268` |
| 2 | entering (invisible, no input) | if `now > enter + entry_InitialDelay` (+0xb8, 55): `FUN_10029cc0` → state 4; else `FUN_10031710(index, 0.0)` (score bar) | `1002a1b4..1002a1e4` |
| 3 | dying | duration = `finalDyingTime` (+0x88, 40) if lives == 1 else `dyingTime` (+0x84, 80); after `now > enter + duration`: if `gate` and in game, lives = max(lives−1, 0); then lives < 1 → state 1 (enter = now); else `FUN_10029cc0` (respawn, state 4) and shield = `defaultShieldPercentage` (+0x48, 100) (0 if not in game), lastHit = lastSpawn = 0, `+0xd1 = 0` | `1002a290..1002a378` |
| 4 | active | if invulnerable (`+0xce`) and level not complete (`FUN_10005cf0` = `game+0x39` == 0) and `now > enter + entry_InvulnerabilityTime` (+0x8c, 60) and in game and not sticky (`+0xcf`): clear `+0xce`, `+0xcf` | `1002a1e8..1002a23c` |
Lives are decremented **at the end of the dying state**, not at the moment of death
(`1002a2dc subic. r3,r4,0x1; bge; li r3,0x0`). The lives==1 test is on the raw value
(`1002a29c cmpwi r4,0x1` after `subis r4,r3,0x1525; addi r4,r4,0x2311`), i.e. the last life
dies faster (40 vs 80 ticks). `gate` = FUN_10028170's 2nd argument = `*param_1` of
`FUN_10006b50`, which that function sets once P1's state is 4 (`FUN_10026c60(*puVar8,4)`) [MED
— reset points of that flag not read; NOT RESOLVED 6].

### 4.1 Becoming active / respawn: `FUN_10029cc0 @ 10029cc0(player, now)` [HIGH]
If in game: `FUN_10029f10` (ship sprite from the weapon, frame 0, `+0xd4 = 0`, `+0x4c = 'play'`),
`FUN_10012940`; position = (`entry_soloStartX` +0x90, `entry_soloStartY` +0x94) = (208, 330) if
`+0xcd == 1` (one-player game), else (`entry_multiStartX` +0x98, `entry_multiStartY` +0x9c) =
(104, 330) for P1, (312, 330) for P2 (`10029d00..10029da0`); velocity = (0, 0)
(`10029da8 lfs f0,0x0(r30)`, r30 → 0x100d6ec8); crosshair adj = 0; overload cleared and glow
reset (`10029dd0..10029dfc`); `+0xc5 = 1`; **state = 4, enter = now** (`10029e04 stb r0,0xc6`,
`10029e08 stw r29,0xc8`); appear fade = flli 163/164/165 (§4.3); spawn `entry_Spawn_ID` (+0xa0,
`plen`) at the ship if not none; `FUN_10029fe0` (multiplier unit, scoring reader);
`FUN_1003af90(+0x240, 0)` (weapon handler). It does **not** touch money, lives or `+0xce`.

### 4.2 Level start: `FUN_100269a0 @ 100269a0(player, levelRef, now)` [HIGH]
Caller `FUN_100064d0` (level start; loops P1 then P2, levelRef = `game+0x18`). If in game: `+0xd0 = 0` (defence bonus
eligible again), `FUN_1003af90(+0x240, 1)`, `+0xc5 = 0`, `+0xc0 = levelRef`, `FUN_10029f10`,
`FUN_10012940`, `FUN_10026b10` (start position as §4.1, velocity 0, crosshair 0, overload
cleared), **state 2 at now** (`10026a20 li r4,0x2; bl 0x10026c80`), `FUN_10012c00`, money = 0
(`FUN_10027580`), money-counter fields reset (`FUN_10027630`), shield = `defaultShieldPercentage`
100 (`FUN_10027400(p,1)`: `10027448 lwz r5,0x48(r5) … bl 0x10027560`), lastHit/lastSpawn/warning
reset, overload cleared, appear fade = flli 163/164/165, then **`FUN_10046580(400, 2000)`**
(`10026a9c li r3,0x190; li r4,0x7d0; bl 0x10046580`) — an int RandomRange draw made for every
in-game player (P2 too) though only P1 stores it (§9). This draw must be reproduced for film
replay order (engine-loop.md §9).
So the ship is invisible and frozen for 55 ticks at level start (state 2), then appears at the
start point with zero velocity.

### 4.3 Appear fade, flli 163–165 [HIGH for the values; MED for the step]
`+0x68 = flli 163 Player_Appears_Initial 0.0`, `+0x6c = flli 164 Player_Appears_Required 100.0`,
`+0x70 = flli 165 Player_Appears_Delta 2.0` (`10029e0c..10029e34`, `10026a6c..10026a98`,
`stfs f1` after each `bl 0x10020250`). The step is `FUN_10012750` (entity module, dump read, not
in my range): if current < required, current = min(current + delta, required) → 0, 2, …, 100 in
**50 ticks**; the update clears `+0xc5` when `+0x68 == +0x6c` (`1002909c fcmpu; bne`). What the
fade value scales at draw time (alpha vs. size) is not read (NOT RESOLVED 8).

### 4.4 Invulnerability [HIGH for the writes; MED for the level-start consequence]
Set: `FUN_10027e50` at death (`10028120 li r0,0x1; stb r0,0xce(r24)` when in game) and
`FUN_10027de0(p,1,0)` for every in-game player when the level-end trigger fires (`FUN_10006b50`).
Cleared only by state 4 after `entry_InvulnerabilityTime` (60) ticks from entering state 4 and
only while the level is not complete. So: invulnerable from death through the 80-tick dying
state and the first 61 ticks after respawn; and, because the level-end flag is never cleared by
the level start (`FUN_100269a0` does not write `+0xce`), also for the first 61 ticks after
appearing in every level after the first (constructor `FUN_10026260` writes `+0xce = 0` only at
game start). ⚑ corrected (wave 2, 2026-10-03): was "the level-end flag is never cleared by the level start" — the
game's level-end flag `+0x39` **is** cleared (in `FUN_10007170`, `10007248`, before the next
level start); what level start leaves set is the player's invulnerable flag `+0xce` — see
loose-ends-combat.md §2.1, §3.3. No direct caller passes `FUN_10027de0(p,0,…)` (`$W/callers.txt`: only `FUN_10006b50`).

## 5. Death from the player's side: `FUN_10027e50` (scoring reader owns the coin arithmetic)
Callers: `FUN_10027100` (shield < 0) and `FUN_10026ee0` (8th overload warning). Player-side
writes [HIGH — `$W/disasm-player3.txt`]: spawn `death_Spawn_ID` (+0xbc, `plde`) at the ship;
shield = 0 if not in game (`10027f30`); lastHit/lastSpawn = 0, `+0xd1 = 0`; money is dropped as
coin units 50/10/5/1 (PermObject 2..5) greedily and set to 0 (`10028104 stw r0,0xac(r24)` with
0xb2cce); **state = 3, enter = now** (`1002810c`, `10028110`); `+0xce = 1` if in game; if the
multiplier is not 1, `FUN_10034de0(+0xb8)` and the multiplier resets to 1 (`FUN_10029fd0`).
`death_Duration` (+0xc0, 90) is not read by any function in this range (NOT RESOLVED 1).

## 6. Defence bonus and power-up overload
### 6.1 Defence bonus, flli 184 [HIGH]
```
10028f3c  rlwinm. r0,r19 ; beq        ; game+0x39 (level complete) set
10028f44  lbz r0,0xd0(r31) ; bne      ; and not hit this level
10028f50  stb 1,0xd0(r31)             ; pay once
10028f5c  lwz r23,0xd0(r3)            ; active_DefenceBonusObject_ID ('nodb'): spawn at the ship if not none
10029000  bl 0x10005cd0               ; sector = game+0x14 (1-based, waves-and-enemies.md §3)
1002900c  li r3,0xb8 ; bl 0x10020250 ; fctiwz ; mullw r4,r0,r18 ; bl 0x10029a10
                                      ; score += int(flli 184 Player_DefenceBonusBaseAmount 2000) × sector
```
It is a one-shot award, not an accumulator: **2000 × sector** to each in-game player who lost no
shield during the level (`+0xd0` is set by any hit with dmg > 0, §3, and cleared at level start,
§4.2). An overload death does not set `+0xd0`, so a player killed only by overload still earns
it. How `FUN_10029a10` applies the multiplier to this amount is the scoring reader's.

### 6.2 Overload warnings: `FUN_10026ee0 @ 10026ee0(player, now)` [HIGH]
Start (in `FUN_10028170`, `10029140..1002919c`): when `FUN_1003b3c0` returns 1, state is 4, the
level is not complete and no overload is running: `+0x210 = 1`, phase `+0x211 = 1`, `+0x218 =
now`, interval `+0x21c = powerupOverload_InitialTimeBetweenWarnings` (+0xe0, 8), count `+0x220 =
0`, glow colour `+0x64 = powerupOverload_Hilite_COLOR` (+0xec). Return 2 cancels (all cleared,
`100291a4..100291d8`). The return codes belong to `FUN_1003c0d0`'s state machine (other reader).
Per tick while running (state 4, level not complete; otherwise everything is cleared):
- phase 1: if `now > last + interval`: last = now; glow = min(glow + 100.0, 100.0)
  (`10026fdc lfd f1,0x8(r28)`; `cror eq,gt,eq` → ≥ 100 → pf[1]); phase 0; interval −= 1, not
  below `powerupOverload_MinimumTimeBetweenWarnings` (+0xe4, 3); count += 1; **count ==
  `powerupOverload_NumWarnings` (+0xdc, 8) → `FUN_10027e50` (ship destroyed)**; else play the
  `powerupOverloadSound_*` block (+0xf0, `wewa`) via `FUN_100475e0(…,1)`.
- phase 0: glow −= `powerupOverload_WarningFadePercent` (+0xe8, 20.0); if ≤ 0 → 0, phase 1.
- always: `+0x5c = glow`, `+0x60 = 0`, `+0x64 = Hilite colour` (glow drawn as-is).
Timeline with the shipped values, start at tick t0: flashes at t0+9, +17, +24, +30, +36, +42,
+48 (7 sounds), destruction at **t0+54** unless cancelled. [MED — derived by stepping the listing;
assumes `FUN_10026ee0` first runs at t0+1, which follows from the call order §2]
The overload sound's pitch is Min 1.0 = Max 1.0, so it draws no RNG (engine-loop.md §9).

## 7. Setup, lives, money, score: `FUN_10026410 @ 10026410(player, index, numPlayers, now, sector)`
Caller `FUN_100051a0` for index 0 and 1 (`FUN_10026410(*p, i, game+0x21, game+0x1c, sector)`,
sector = `FUN_10011e30()` stored at `game+0x14`). [HIGH]
- `+0xcd = numPlayers`, `+0xcc = index`; definition = PermObjectID index (0 `pl01`, 1 `pl02`)
  → `FUN_10039460` → `FUN_10039520` → `+0x94` (`10026434..10026490`); "Setting Up Player %i";
  both `plde` resource sets are loaded (`FUN_100399a0`).
- Permanent unit loads (`FUN_1002a450` = check-and-load a unit def by ID, asserting
  "RESOURCE FAILURE"): PermObjectID 2–5 (money units `calg cals casg cass`), 6–9 (water
  impacts), 10..10+N−1 (level notices, N = `FUN_10011de0()`), 22–24 (`nole noal nogo`), 25–34
  (random bonuses `rb01..rb10`), 35–39 (multipliers `mux2..muxx`). [HIGH — names from
  `idli/Objects[gaob]` line order]
- In game: `numPlayers != 1` → both; `numPlayers == 1` → only index 0 (`+0xc4 = 1`).
- **Initial lives** (`FUN_10026cc0(p, sector == 1)`: `10026838 subfic r0,r30,0x1; cntlzw;
  rlwinm r4,r0,0x1b,…`): `life_NumInitial` (+0x64, **3**) when the game starts at sector 1,
  otherwise **1**; extra-life threshold `+0x9c = life_InitialRequiredScore` (+0x68, 10000);
  not in game → 0 lives. (Starting later costs lives; compare NOT-RESOLVED #28 "starting bonus".)
- money = 0, score = 0 (`FUN_100299c0`), multiplier = 1 (`FUN_10029fd0`), shield = 100
  (`FUN_10027400(p,1)`), weapon handler setup `FUN_1003ade0(+0x240, index, now, sector)` (initial
  weapons: other reader), max speed = 7.8 (`FUN_10026cb0`), money-counter reset, overload
  cleared; state 2 if in game (and input bytes cleared) else state 1; `+0x23c` (§9).
- Extra life `FUN_10026d70 @ 10026d70(player, showFx)` (callers `FUN_10029a10`, `FUN_10037580`):
  new = lives + 1, capped at `life_MaxNum` (+0x60, 10) when that is > 0; if new > lives: spawn
  `life_Spawn_ID` (+0x70, `noel`) at the ship when `showFx`, store. [HIGH — `10026d98..10026dc0`]
- Multiplier step `FUN_10029b20` (caller `FUN_10037580`): state 4 only; 1→2→3→4→5→10, each
  followed by `FUN_10029fe0`; 10 stays (jump table `0x100e93c0`: cases `li r0,N; stb r0,0xb4(r3);
  bl 0x10029fe0`). [HIGH]

## 8. Two-player differences [HIGH unless marked]
`plde` P1/P2 differ only in name, score-bar/high-score frames 0/1, `entry_multiStartX` 104/312
and `active_MoneyCounterSpawn_ID` `p1mc`/`p2mc` (decoded files, `diff`). Code differences: ship
sprite from the weapon's `player1/2AppearanceFace` (§1); one-player games use the solo start
(208, 330) and leave P2 out of the game; both players' left/right drive the shared view shift
(§2.5); the integrity check and its stored schedule are P1-only but the RNG draw is made per
in-game player (§4.2, §9); the lives-decrement gate follows P1 (§4) [MED]. Updates run P1 then
P2 each tick (`FUN_10006b50`).
⚑ conflict with function-roles.md §1 (damage reader's rows, reported for merge):
`FUN_10026c90` is `lbz r3,0xcc(r3); blr` = **get player index**, not "player takes hit"
(`FUN_100051a0` tests it against −1 to decide whether a player slot exists); `FUN_10026c10` is
`lbz r3,0xc4(r3)` = "in game" (still has lives / not eliminated), not just "alive".

## 9. Integrity check at the top of `FUN_10028170` (registration; identified only) [MED]
Gate `100281a4 lbz r0,0x23c(r3); beq` and `100281b0 lwz r0,0x234(r31); cmpw r26,r0; bne` — runs
once when `now == +0x234`. `+0x23c` is set only for P1 (`10026968 bl 0x1007ebf0`, nonzero result).
`+0x234` = level start time + `RandomRange(400, 2000)` (§4.2). Two obfuscated byte-mixing
variants over two 17-byte templates (labels `s_Deimos_RisingDei…`) and the registration name
(`+0x224` copy) produce a pass flag; pass → `+0x238 += 1` and, after the first pass, `+0x234 =
now × 2` (`10028f10..10028f2c`); fail → `FUN_10001080` ("Sorry, but critical files are
missing…") + `FUN_10011b10` (`10028efc..10028f04`). `FUN_10026180` is called twice inside with its
result discarded (`10028b38 lbz r3,…`, `10028c54 srawi r3,…` overwrite r3). Draws no RNG. For a
rebuild this block is inert apart from the `FUN_10046580(400,2000)` draw it schedules.

## Worked example: hold "up" for 10 ticks from rest (Player 1, one-player game)
Data: `plde/Player 1[pl01]`: `active_VelocityDelta 1.6` (+0xd8), `active_DefaultMaxSpeed 7.8`
(+0xd4 → +0xa4), `entry_soloStartX/Y 208/330`; flli 166 = 1, 183 = 13. Start: the tick after
`FUN_10029cc0` placed the ship at (208, 330) with v = (0, 0), frame 0. Input `[0]` (up) = 1 each
tick; no other key. Single-precision results (Python with `struct` float32 rounding):
| tick | vy after step (§2.1) | y after integrate (§2.2) | note |
|---|---|---|---|
| 1 | −1.6 | 328.4 | |
| 2 | −3.2 | 325.2 | |
| 3 | −4.8 | 320.4 | |
| 4 | −6.4 | 314.0 | |
| 5 | −8.0 → **−7.8** | 306.2 | cap: −8.0 < −7.8 (`10029214 bge` not taken) |
| 6 | −7.8 | 298.4 | |
| 7 | −7.8 | 290.6 | |
| 8 | −7.8 | 282.8 | |
| 9 | −7.8 | 275.0 | (float32: 275.00006) ⚑ corrected (review wave 1, 2026-10-03) #M6 |
| 10 | −7.8 | 267.2 | (float32: 267.20007) |
Release on tick 11: decay +1.6/tick → vy −6.2, −4.6, −3.0, −1.4, then −1.4 + 1.6 = 0.2 > 0 →
snapped to 0 on tick 15; y = 261.0, 256.4, 253.4, 252.0, 252.0 (rest 78 px above the start).
x stays 208 and vx 0 (the no-horizontal decay leaves 0 at 0); the frame stays 0 (no-horizontal
table maps 0 → 0); the top clamp is never reached (needs y − hh < 13). With the Plasma Bomb
crosshair shown, cy = y − 121 throughout (adj stays 0: not pinned at the bottom), e.g. 146.2 at
tick 10. Holding "right" instead from frame 0 would bank 0 → 4 on tick 1 (`+0xd4` = 0), → 5 on
tick 3, → 6 on tick 5, and shift the view +1 per tick (10 px after 10 ticks, capped at offset 31).

## NOT RESOLVED (this file)
1. ~~Consumers of `plde` keys not read in this range: `waitingTime` (+0x74), `filmIntroTime`
   (+0x78), `introTime` (+0x7c), `entry_StartVelocityX/Y` (+0xa4/+0xa8, −7.2),
   `entry_TargetVelocityX/Y` (+0xac/+0xb0), `entry_VelocityDelta` (+0xb4), `death_Duration`
   (+0xc0), `active_MoneyCounterSpawn_ID` (+0xc4). `grep -n "0x94) + 0x(74|78|7c|a4|a8|ac|b0|b4)"`
   in the dump finds none; the fly-in may live in the `plen` entry unit (unit-def reader). Settle:
   raw scan of the code image for `lwz rX,0x94(rY)` followed by loads at these offsets, and the
   callers of `FUN_10026ca0` (get plde).~~ → ⚑ corrected (review wave 3, 2026-10-06) #S: loose-ends-session.md §1: the `plde` fly-in keys have no reader except MoneyCounterSpawn (critic wave 3 §3).
2. ~~`FUN_1003b3c0` return codes (1 = start overload, 2 = cancel; local flag → `FUN_10029f60`
   sprite refresh) and the gate `+0x84 == 1.0` (entity second fade, `FUN_10012840`) — weapon
   handler reader.~~ → ⚑ corrected (review wave 3, 2026-10-06) #S: loose-ends-combat.md §6.1 (`FUN_1003b3c0` return codes, listing re-checked) (critic wave 3 §3).
3. The checksum arithmetic of §9 (registration, out of scope by project ruling).
4. Lifecycle of the crosshair flag `+0x360` (set in `FUN_1003b3c0`; clearer not traced) and the
   consumer of flli 149/150 `Crosshair_FadeIn/OutPercentageRate`. ⚑ corrected (wave 3+4, 2026-10-04) narrowed: the crosshair
   fade is `FUN_10012750` run on the crosshair object (gameplay-leftovers.md §2.1).
5. ~~`FUN_10029c00` has no direct caller (`$W/callers.txt`); body reads sector and re-assigns a
   handler weapon slot via `FUN_1002adb0`/`FUN_1003b180`. Settle: search the data image for
   its address (function-pointer table).~~ → ⚑ corrected (review wave 2, 2026-10-03) #S: two raw callers `10008408` ('PEAA')
   and `10008490` ('PEAG') in the debug command `PLAYER AIRWEP|AIR` / `PLAYER GROUNDWEP|GROUND` (sub-keywords of the PLAYER handler `0x10007ff0`; strings `AIRWEP` `0x100e41fc`, `AIR` `0x100e4203`, `GROUNDWEP` `0x100e4207`, `GROUND` `0x100e4211`), unregistered → unreachable in 1.0.6
   (messages-notices-console.md §5.5, loose-ends-session.md §8.1).
6. ~~Reset points of the lives-decrement gate (`FUN_10006b50` `*param_1` = `local_a27[2]` in
   `FUN_100051a0`). Settle: read `FUN_100051a0` around the level loop.~~ → ⚑ corrected (review wave 3, 2026-10-06) #S: loose-ends-session.md §4 (game over and the lives gate) (critic wave 3 §3).
7. ~~Hit factor f1 passed by `FUN_10033850` to `FUN_10027100` (damage reader).~~ → ⚑ corrected (wave 3+4, 2026-10-04) (critic O7):
   f1 = the colliding unit's `damage_FLOAT` (+0x274), `100342c0 lfs f1,0x274(r31)` (gameplay-leftovers.md §7.4c).
8. ~~What `+0x68` (appear fade) and `+0x58` (glow) do at draw time (`FUN_10012f20`, sprite blit).~~ → ⚑ corrected (review wave 3, 2026-10-06) #S: sprite-geometry-draw.md §4 (visibility `+0x68` → alpha, hit glow `+0x58`) (critic wave 3 §3).
9. Level-start invulnerability carry-over (§4.4) is a code reading with no indirect-clear search;
   Ben's eyes: is the ship invulnerable for ~2 s after appearing on level 2+?

## Role-table rows (for merge)
| function | module | role | conf | evidence |
|---|---|---|---|---|
| `FUN_10026100` | (static init) | copy constant templates into G_Player statics | HIGH | dump; caller `FUN_10000000` — ⚑ corrected (review wave 3, 2026-10-06) #L: was LOW on dump; TU init D + T only, static-init-audit.md §3 table A (listing + interpreter); function-roles.md row |
| `FUN_10026180` | G_Player.cc (span) | pure `7·3^bitlen(x&0xff)`; only caller discards it (obfuscation filler in §9) | HIGH | disasm `10026180..10026254`, `10028b38`/`10028c54` |
| `FUN_10026260` | G_Player.cc (span) | player constructor (field defaults, lives 0, money 0, score 0, index 0xff, numPlayers 1) | HIGH | disasm stores `100262a4..10026340`; caller `FUN_100051a0` |
| `FUN_100263a0` | G_Player.cc (span) | player destructor | MED | dump |
| ⚑ corrected `FUN_10026410` | G_Player.cc | player setup: plde by index, perm unit loads O2–39, in-game by numPlayers, lives 3 at sector 1 else 1, shield 100, score/money 0, state 2 | HIGH | disasm `10026434..10026874`; was "player setup + permanent unit loads MED" |
| ⚑ corrected `FUN_100269a0` | G_Player.cc | level start per player: state 2, start position, shield 100, money 0, defence-bonus flag reset, appear fade F163–165, RandomRange(400,2000) | HIGH | disasm `100269d0..10026af0`; was "player appear fade MED" |
| `FUN_10026b10` | G_Player.cc | place at solo/multi start, v = 0, crosshair 0 | HIGH | disasm |
| `FUN_10026c20` | G_Player.cc | in game and state 1 (out of lives) | MED | dump (2 loads) — ⚑ label audit (review wave 1) |
| `FUN_10026c50` | G_Player.cc | get life state +0xc6 | MED | dump — ⚑ label audit (review wave 1) |
| `FUN_10026c60` | G_Player.cc | life state == arg | MED | dump — ⚑ label audit (review wave 1) |
| `FUN_10026c80` | G_Player.cc | set life state + enter time | HIGH | dump; callers 10026410, 100269a0 |
| ⚑ corrected `FUN_10026c90` | G_Player.cc | get player index +0xcc | HIGH | `lbz r3,0xcc(r3)`; was "player takes hit LOW" |
| ⚑ corrected `FUN_10026c10` | G_Player.cc | in game flag +0xc4 | HIGH | `lbz r3,0xc4(r3)`; was "player is alive LOW" |
| `FUN_10026ca0` | G_Player.cc | get plde +0x94 | MED | dump — ⚑ label audit (review wave 1) |
| `FUN_10026cb0` | G_Player.cc | max speed = active_DefaultMaxSpeed | HIGH | disasm |
| `FUN_10026cc0` | G_Player.cc | init lives (NumInitial or 1) + extra-life threshold | HIGH | disasm |
| `FUN_10026d50` / `FUN_10026d60` | G_Player.cc | get / set lives (obfuscated +0x1524dcef) | HIGH | disasm |
| `FUN_10026d70` | G_Player.cc | add one life, cap life_MaxNum, spawn life_Spawn_ID | HIGH | disasm `10026d84..10026dc0` |
| `FUN_10026ea0` | G_Player.cc | clear overload + glow fields | MED | dump — ⚑ label audit (review wave 1) |
| `FUN_10026ee0` | G_Player.cc | overload warning flashes; Nth warning destroys ship | HIGH | disasm `10026f0c..100270d8` |
| ⚑ corrected `FUN_10027100` | G_Player.cc | player hit: shield −= f×15, death if < 0, glow, spawn-on-hit (F162), shield warning | HIGH | disasm; was "player hit spawn delay MED" |
| `FUN_10027400` | G_Player.cc | reset shield (100 / 0) + hit timers | HIGH | disasm |
| `FUN_10027490` | G_Player.cc | add shield, clamp [0,100] | HIGH | disasm |
| `FUN_10027540` / `FUN_10027560` | G_Player.cc | get / set shield (obfuscated +1324366.0) | HIGH | disasm |
| `FUN_10027580` | G_Player.cc | money = 0 | HIGH | disasm |
| `FUN_100275b0` / `FUN_10027610` / `FUN_10027620` | G_Player.cc | add / get / set money (obfuscated +0xb2cce) | HIGH | disasm |
| `FUN_10027630` | G_Player.cc | reset money-counter display fields | MED | dump |
| `FUN_10027db0` | G_Player.cc | money counter running (+0xd8) | MED | dump |
| `FUN_10027dd0` | G_Player.cc | invulnerable flag +0xce | HIGH | disasm |
| `FUN_10027de0` | G_Player.cc | set/clear invulnerability (+sticky) | MED | dump |
| ⚑ corrected `FUN_10028170` | G_Player.cc | player update: accel/decay/cap movement, banking frames F166, view shift, area clamp F54/55/183, crosshair F185–187, defence bonus F184 | HIGH | disasm §2; was MED "perm F183-187" |
| `FUN_100298c0` | G_Player.cc | draw player (state 4): weapons, sprite passes, money text | MED | dump; caller `FUN_10007070` |
| `FUN_100299c0` / `FUN_100299f0` / `FUN_10029a00` | G_Player.cc | reset / get / set score (obfuscated +0x5532a3e) | HIGH | disasm |
| `FUN_10029b20` | G_Player.cc | step score multiplier 1→2→3→4→5→10 | HIGH | jump table `0x100e93c0` |
| `FUN_10029bd0` / `FUN_10029fd0` | G_Player.cc | get / reset(1) multiplier | MED | dump — ⚑ label audit (review wave 1) |
| `FUN_10029be0` / `FUN_10029bf0` | G_Player.cc | get / set flag +0xbd | HIGH | dump — ⚑ corrected (review wave 3, 2026-10-06) #L: was LOW on dump; cheated flag get/set `10029be0 lbz r3,0xbd(r3)` / `10029bf0 stb r4,0xbd(r3)` (gameplay-leftovers.md §3) |
| `FUN_10029c00` | G_Player.cc | advance a weapon slot to the next weapon of its type available at the sector; reached only from the debug command `PLAYER AIRWEP\|AIR` / `PLAYER GROUNDWEP\|GROUND` (sub-keywords of the PLAYER handler `0x10007ff0`; strings `AIRWEP` `0x100e41fc`, `AIR` `0x100e4203`, `GROUNDWEP` `0x100e4207`, `GROUND` `0x100e4211`) (unreachable in 1.0.6) | HIGH | raw calls `10008408`/`10008490` + strings (messages-notices-console.md §5.5) — ⚑ corrected (review wave 2, 2026-10-03): was "(no direct caller)" LOW |
| `FUN_10029cb0` | G_Player.cc | get +0xc0 (level ref) | MED | dump |
| `FUN_10029cc0` | G_Player.cc | become active / respawn: start pos, v 0, state 4, appear fade, spawn entry unit | HIGH | disasm |
| `FUN_10029f10` / `FUN_10029f60` | G_Player.cc | reset ship sprite/frame / sprite from weapon appearance face | HIGH | disasm |
| `FUN_1002a150` | G_Player.cc | life-state step (entering, dying, lives decrement, game over, invulnerability expiry) | HIGH | disasm |
| `FUN_1002a450` | G_Player.cc | load-and-check a permanent unit def | MED | strings |
| `FUN_1002a4f0` | (static init) | spawn-request template statics | HIGH | dump — ⚑ caution ⚑ corrected (review wave 2, 2026-10-03) #C1: it writes `0x100e9178…` before `main`, so no value of those templates may be taken from the data image (INDEX #56) — ⚑ corrected (review wave 3, 2026-10-06) #L: was LOW on dump; TU init (player request +0x24 ← −1), static-init-audit.md §3 table A (listing + interpreter); function-roles.md row |
| `FUN_1002a5b0` / `FUN_1002a610` | G_Debris.cc (span) | register / tear down "Debris" + NUMDEBRIS console command | MED | strings |
| `FUN_10039e70` | G_PlayerDefinitions.cc | `plde` parser (table below) | HIGH | disasm reader calls |
`plde` key → offset (`FUN_10039e70`, from the listing pairs `addi r5,r31,<key>` /
`addi r6,r30,<off>` before each reader `bl`, key base r31 = 0x100ec0a0; struct 0x108 bytes,
`FUN_10039cf0` presets IDs to `none`): name_STR +0x08 (32 B) · spriteHighScore_ID +0x28 ·
spriteHighScoreFrame +0x2c · spriteScoreBar_ID +0x30 · spriteScoreBarFrame +0x34 ·
spriteScoreBarShield_ID +0x38 · …ShieldFrame +0x3c · spriteScoreBarPower_ID +0x40 · …PowerFrame
+0x44 · defaultShieldPercentage +0x48 · shieldWarningPercentage +0x4c · shieldBaseHitPercentage
+0x50 · shieldHitDelay +0x54 · hitGlowColor +0x58 · hitGlowSpeed +0x5c · life_MaxNum +0x60 ·
life_NumInitial +0x64 · life_InitialRequiredScore +0x68 · life_AdditionalRequiredScore +0x6c ·
life_Spawn_ID +0x70 · waitingTime +0x74 · filmIntroTime +0x78 · introTime +0x7c · gameOverTime
+0x80 · dyingTime +0x84 · finalDyingTime +0x88 · entry_InvulnerabilityTime +0x8c ·
entry_soloStartX/Y +0x90/+0x94 · entry_multiStartX/Y +0x98/+0x9c · entry_Spawn_ID +0xa0 ·
entry_StartVelocityX/Y +0xa4/+0xa8 · entry_TargetVelocityX/Y +0xac/+0xb0 · entry_VelocityDelta
+0xb4 · entry_InitialDelay +0xb8 · death_Spawn_ID +0xbc · death_Duration +0xc0 ·
active_MoneyCounterSpawn_ID +0xc4 · active_SpawnOnHit_ID +0xc8 · active_ShieldWarningObject_ID
+0xcc · active_DefenceBonusObject_ID +0xd0 · active_DefaultMaxSpeed +0xd4 ·
active_VelocityDelta +0xd8 · powerupOverload_NumWarnings +0xdc · …InitialTimeBetweenWarnings
+0xe0 · …MinimumTimeBetweenWarnings +0xe4 · …WarningFadePercent +0xe8 · …Hilite_COLOR +0xec ·
powerupOverloadSound_ID +0xf0 · …MinVolume +0xf4 · …MaxVolume +0xf8 · …Priority +0xfc ·
…MinPitch +0x100 · …MaxPitch +0x104. `*_INT` keys go through `FUN_1002c880` (`%i`, so
"100.000000" → 100). [HIGH — 57 reader calls, `10039ee8..1003a758`]

## INDEX updates (for merge)
- **#7 closed** → player-physics.md "Role-table rows" (`plde` key→offset table, 57 keys).
- **#25 player part closed** → §2 (movement, banking, clamps, crosshair), §3 (hits), §6.2
  (overload warnings from the player side); weapon power-up/launch arithmetic stays open.
- **#17 narrowed**: the horizontal-shift driver is the player's left/right input (both players)
  → §2.5; engine-loop.md §5 "MED that the player's x drives it" is ⚑ superseded. Initial scroll
  top still open.
- **#26 narrowed**: defence bonus = 2000 × sector, once per level, only if no shield was lost
  → §6.1. Initial extra-life threshold = `life_InitialRequiredScore` 10000 stored at `+0x9c` by
  `FUN_10026cc0` → §7 (its stepping is in `FUN_10029a10`, scoring reader).
- **#28 narrowed**: starting at a sector other than 1 gives 1 life instead of 3 → §7.
- **#24 (player hit) closed for the player side** → §3; `FUN_10026c90` relabelled (§8 ⚑).
- New for engine-loop.md §9 (RNG order): `FUN_100269a0` draws `FUN_10046580(400,2000)` per
  in-game player at every level start → §4.2.
