# Deimos Rising 1.0.6: player weapons, power-up and overload, bombs, projectiles

Scope: G_WeaponDefinitions.cc `0x1002ab20…0x1002ba00` (+ the spawn-record initialiser
`FUN_1002c490`) and G_WeaponHandler.cc plus its unattributed tail `0x1003ade0…0x1003d030`
(inventory rows in `$W/inventory.txt`). Named targets: the air power-up/overload machine
`FUN_1003c0d0`, the launchers `FUN_1003c4f0`/`FUN_1003c7a0`/`FUN_1003c940`, the per-tick handler
`FUN_1003b3c0`, bombs `FUN_1003beb0`, the `wede` parser and its key→offset table, how a launch becomes an
entity through `FUN_10033220`, and what pickups do to the handler. I followed callees outside the range
only as far as they decide a weapon number (`FUN_10033220`, `FUN_10035cd0`, `FUN_10037b50`,
`FUN_10034ce0`, `FUN_10014670`, `FUN_10037580`, `FUN_10026ee0`, `FUN_10027e50`, the call site in
`FUN_10028170`). OUT of scope: collision and damage (`FUN_10033850` step 8, `FUN_10014f10`,
`FUN_10042f80`); the movement executors; the spawn-set executor `FUN_10036cf0` (it drives the
child spawns of `rgbs`/`icps`/…); the token readers `FUN_1002c4d0…FUN_1002cc90`, which are already
in the bank (data-tags.md §1) and were not re-read here. One tick = one logic frame, capped at 30/s by default
(engine-loop.md §4). Raw listings: `$W/disasm-weapons.txt` (all 42 in-range functions +
`FUN_10037580`, `FUN_10033220`) and `$W/disasm-weapons2.txt` (callees), made with
`DisasmFuncs.java` against the private copy `$W/work-weapons`.

## 1. Weapon definition (`wede`, G_WeaponDefinitions.cc)

### 1.1 Loading
| function | role | label / evidence |
|---|---|---|
| `FUN_1002ab20 @ 1002ab20` | build master weapon list `_DAT_100e01d4`: free old (`FUN_1002b590`), then `FUN_1002b8e0(i)` for i = 0,1,… until 0, append each; logs "Weapon Definitions Loaded: %i"; with `param_1` it also logs through `inte` strings 12/13 | MED (read; caller `FUN_1002aa90`) — ⚑ label audit (review wave 1) |
| `FUN_1002b8e0 @ 1002b8e0` | load the i-th `wede` tag (`FUN_10002be0(i,'wede',&id)`), alloc 0x208, zero, defaults `FUN_1002b2a0`, parse `FUN_1002ba00`; "A Weapon Definition file contain…" if the parse-error flag is set | MED (read) — ⚑ label audit (review wave 1) |
| `FUN_1002b2a0 @ 1002b2a0` | defaults: `+0x000` magic `0x499602d2`, ID fields `+0x130 +0x144 +0x148 +0x168 +0x170 +0x180 +0x1cc +0x1dc +0x1ec +0x1fc` = `none`, selection-sound block `+0x150..+0x164` ← `{none,100,100,100,1.0,1.0}` (table `0x100d7014`), frees spawn list `+0x1c4` | HIGH (read + image: `0x100df324 → 0x100d7014` = `6e6f6e65 64 64 64 3f800000 3f800000`) |
| `FUN_1002ba00 @ 1002ba00` | the parser (table §1.2). Stores the tag ID at `+0x004`. Decodes the text only if `strstr(buf,"#type_ID")` fails | MED (read) — ⚑ label audit (review wave 1) |
| `FUN_1002c490 @ 1002c490` | spawn record init: name "", unit `none`, XLoc/YLoc ← `{0,0}` (`_DAT_100df320`), SetHeading 0, Angle 0 | MED (read; sole caller `FUN_1002ba00`) — ⚑ label audit (review wave 1) |
| `FUN_1002acf0 @ 1002acf0` | i-th definition of the master list (0 past the end) | MED (read) — ⚑ label audit (review wave 1) |
| `FUN_1002b590 @ 1002b590` | free the master list (checks magic, frees spawn lists) | MED (read) — ⚑ label audit (review wave 1) |

List order = tag-index order. In `Game.pak` the `wede` entries sit in the order `aibg, aiic, aipb, airg, plbo`, in both the
local-header order and the central-directory order (Python walk of `Game.pak`). [MED: that the
index keeps pak order is from pak-format.md §2.3; the override step `FUN_10004300` is unread]

### 1.2 Key → offset table (definition struct, 0x208 bytes)
I read this from the reader calls in `FUN_1002ba00` (dump lines quoted in place, e.g.
`FUN_1002c880(param_2,local_48 + 1,s__delayBetweenLaunches_INT_100e9fcf,param_3 + 0x1b0)`). It agrees with
data-tags.md §6 and adds the spawn-record layout, the power-up offsets one by one, and the parse-time fix-ups.
| off | type | key | consumer read here |
|---|---|---|---|
| 0x000 | u32 | magic 0x499602d2 | `FUN_1002b590` |
| 0x004 | 4CC | (tag ID of the file) | cycling `FUN_1002adb0`, log |
| 0x008 | 4CC | `#type_ID` (`PEAA` air, `PEAG` ground, `SPEC`) | `FUN_1002adb0`, `FUN_1003cd30/cdb0` |
| 0x00c | 4CC | `#default_ID` (`DEAA`/`DEAG`/none) | `FUN_1003cca0` |
| 0x010 / 0x030 / 0x0b0 | str 32/128/128 | `#name_STR`, `#description1_STR`, `#description2_STR` | none found |
| 0x130 / 0x134 | 4CC / int | `#scoreBarPreviewFace_ID` / `…Frame_INT` | `FUN_1003bb40` (score-bar icons), `FUN_100146f0` |
| 0x138 | int | `#maxAllowed_INT` | none found |
| 0x13c / 0x140 | int | `#minimumLevelAvailable_INT` / `#maximumLevelAvailable_INT` (`< 1` → 9999 at parse) | availability §2.4 |
| 0x144 / 0x148 | 4CC | `#player1/2AppearanceFace_ID` | `FUN_10029f60` (ship sprite) |
| 0x14c | color | `#playerGlow_COLOR` | none found |
| 0x150..0x164 | snd block | `#selectionSound_ID`, Min/MaxVolume, Priority, Min/MaxPitch | preload only (`FUN_1002b790`) |
| 0x168 / 0x16c | 4CC / int | `#crosshairFace_ID` / `#crosshairFrame_INT` | `FUN_1003b3c0`, `FUN_1003bab0` |
| 0x170 / 0x174 | 4CC / int | `#crosshairLockedFace_ID` / `#crosshairLockedFrame_INT` | `FUN_1003bab0` (frame only) |
| 0x178 / 0x17c | int | `#crosshairXOffset_INT` / `#crosshairYOffset_INT` | `FUN_10028170` (crosshair pos), `FUN_1003c4f0` (`abs`) |
| 0x180 | 4CC | `#crosshairSpawnOnActivation_ID` | `FUN_1003c4f0` |
| 0x184 / 0x188 / 0x18c | int/int/str32 | `#numAmmoInPack_INT`, `#ammoWarnAtCount_INT`, `#ammoWarning_STR` | none found |
| 0x1ac | bool | `#autoRepeat_BOOL` | `FUN_1003bf80/bff0`, `FUN_1003b3c0` |
| 0x1b0 | int | `#delayBetweenLaunches_INT` | `FUN_1003bf80`, `FUN_1003bff0`, `FUN_1003beb0` |
| 0x1b4 | int | `#delayBetweenLoadLaunches_INT` | `FUN_1003b3c0` (bomb salvo) |
| 0x1b8 / 0x1bc / 0x1c0 | int | `#shieldIncrease_INT`, `#livesIncrease_INT`, `#invulnerableForTime_INT` | none found |
| 0x1c4 | list* | spawn records (`#spawn_NumUnitsToSpawn_INT` = count, not stored) | launchers §3 |
| 0x1c8 | int | `#powerup_Air_TimeUntilActivation_INT` | `FUN_1003c0d0` |
| 0x1cc | 4CC | `#powerup_Air_ActivationSpawn_ID` | `FUN_1003c0d0` |
| 0x1d0 | int | `#powerup_Air_TimeBetweenPowerLevelChanges_INT` | `FUN_1003c0d0` |
| 0x1d4 | int | `#powerup_Air_MaxPowerLevel_INT` | `FUN_1003c0d0` |
| 0x1d8 | int | `#powerup_Air_OverloadTime_INT` | `FUN_1003c0d0` |
| 0x1dc | 4CC | `#powerup_Air_ReleaseSpawn_ID` | `FUN_1003c0d0` |
| 0x1e0 | int | `#powerup_Air_TimeBetweenReleaseSpawns_INT` | `FUN_1003c0d0` |
| 0x1e4 | bool | `#powerup_Air_DoReleaseOnMaxPowerLevel_BOOL` | `FUN_1003c0d0` |
| 0x1e8..0x204 | same 8 | `#powerup_Ground_*` (0x1f4 = MaxPowerLevel, dump prints `param_3 + 500`) | `FUN_1003b3c0` (ground copy, §2.3); **0x1f8 OverloadTime has no reader** |
Spawn record (0x34 bytes, `FUN_1004d320(0x34)`): `Name_STR +0x00 (32) · Unit_ID +0x20 · XLoc_INT +0x24 ·
YLoc_INT +0x28 · SetHeading_BOOL +0x2c (byte) · Angle_INT +0x30`. At parse the angle is brought into [0, 360):
+360 if negative, −360 if > 359, then 0 if still out of range. Missing sprite IDs (preview, both appearances, both
crosshair faces) log "MISSING SPRITE RESOURCE…" and are reset to `none`.
[HIGH: literal `param_3 + off` / `iVar3 + off` arguments. "none found" is LOW: a
whole-dump grep for `+ 0x184)` etc. found no reader that is typed as a weapon definition]

### 1.3 Other definition helpers
| function | role | label |
|---|---|---|
| `FUN_1002adb0 @ 1002adb0` | **cycle**: `(type, curID, level)` → walks the list in order over definitions with `type` and `min ≤ level ≤ max`. If curID = `none` it returns the first match. Otherwise it returns the next match after curID, and wraps to the first match when curID is the last match or is not in the matching set. 0 if nothing matches | HIGH (listing `1002ae30 lwz r0,0x13c(r3); cmpw r31,r0; blt` · `1002ae3c lwz r0,0x140(r3); cmpw r31,r0; bgt`) |
| `FUN_1003cca0 @ 1003cca0` | first definition whose `default_ID` = `DEAA` (arg 0) or `DEAG` (arg ≠ 0). **Level is ignored** | HIGH (read; called with 1 from `FUN_1003ade0`, listing `1003aec4 li r3,0x1; bl 0x1003cca0`) |
| `FUN_1003cdb0 @ 1003cdb0` | starting air weapon for a level: among `PEAA` with `min ≤ L ≤ max`, the one with the **largest `minimumLevelAvailable`** (first in list on ties) | HIGH (listing `1003ce28 lwz r0,0x13c(r30); cmpw r0,r4; bge skip` → replaces only on strictly greater min) |
| `FUN_1003cd30 @ 1003cd30` | first `PEAA` whose `minimumLevelAvailable == L` (newly unlocked weapon) | HIGH (listing `1003cd80 lwz r0,0x13c(r3); cmpw r0,r29; bne`) |
| `FUN_1002b3a0 @ 1002b3a0` → `FUN_1002b6d0` → `FUN_1002b790` | level-start preload: for types `PEAA`,`PEAG`,`SPEC` available at the level, `G_Res_Load` the selection sound, preview, crosshair faces and appearances, and `FUN_1003e580` every referenced unit (crosshair spawn, 4 power-up IDs, spawn units) | HIGH (read; caller `FUN_100064d0` start level) |
| `FUN_1002aec0 @ 1002aec0` | new list of every unit ID a weapon references (`+0x180 +0x1cc +0x1dc +0x1ec +0x1fc` + each spawn `+0x20`) | MED (read; caller `FUN_1002b150`) — ⚑ label audit (review wave 1) |
| `FUN_1002b150 @ 1002b150` | "is unit X referenced by any weapon" (uses `FUN_1002aec0`, frees with `FUN_1002b240`) | MED (read; **no caller**: none in the dump, and no pointer to it in either memory image. Probably for the `LOGUNUSEDUNITS` console log, LOW) |
| `FUN_1002b240 @ 1002b240` | free an ID list | MED (read) — ⚑ label audit (review wave 1) |
| `FUN_1002b400 @ 1002b400` | append the sprite IDs (mode 1) or selection sound (mode 0) of every weapon to a list | MED (read; no caller found, same search) |

## 2. Weapon handler (G_WeaponHandler.cc): struct, per-tick flow

### 2.1 Where it lives and who drives it
The handler is embedded in the player at **player+0x240**. `FUN_10028170` (player update) calls
`FUN_1003b3c0(player+0x240, player /*x,y*/, in[4] fireGround, in[5] fireAir, in[6] select, gameTime, &switched)`.
It runs only when player state `+0xc6 == 4` (active) and player `+0x84 == 1.0`:
```
100290c4  lbz r0,0xc6(r31) ; cmplwi r0,0x4 ; bne      100290d0 lfs f1,0xc(r22) ; lfs f0,0x84(r31) ; fcmpu ; bne
100290e0  lbz r5,0x200(r31)     ; [4] fire ground  (player+0x1fc+4)
100290e8  lbz r6,0x201(r31)     ; [5] fire air
100290f0  lbz r7,0x202(r31)     ; [6] select weapon
100290f4  addi r3,r31,0x240 ; 100290fc bl 0x1003b3c0
```
(`r22` = `_DAT_100df304` → `0x100d6fc8`, whose `+0xc` = 1.0 (image). Reading `+0x84` as the player's scale is MED, by analogy
with entity `+0x84`.) Return value: **1** = overload begins → player overload warning (§2.6), **2**
= power-up released → warning cancelled (`10029120…` branch table; decompile lines 470–497 of the
function). A non-zero `switched` → `FUN_10029f60(player)` sets the ship sprite to the weapon's
`player1/2AppearanceFace_ID` (it uses the pending weapon if there is one, via `FUN_1003bce0`). [HIGH]

Setup `FUN_1003ade0(h, playerIdx, gameTime, sector)` (only caller `FUN_10026410`, new game,
`FUN_100051a0` passes game `+0x1c` and the start sector): logs "Setting Up Player %i Weapons
Handler", resets via `FUN_1003af90(h,0)`, sets `+0x122` = player index, `+0x124/+0x128` = flli 149/150
`Crosshair_FadeIn/OutPercentageRate` (6/6), `+0xd8` = `'plui'` (draw layer of the crosshair sprite object at `+0x8c`;
entity `+0x4c` holds the draw layer in `FUN_10035cd0`, so `+0x8c+0x4c`, MED), and creates or clears the aux list `+0x70`.
Ground weapon = `FUN_1003cca0(1)` (`DEAG`), air weapon = `FUN_1003cdb0(sector)`; either one missing →
"GAME DATA INCORRECT…" + fatal assert. Both launch timers ← gameTime. [HIGH: listing `1003ae48
stfs f1,0x124(r27)`, `1003ae64 stw r0,0xd8(r27)` (`lis r3,0x706c` = 'pl..'), `1003aed4 stw r3,0x74(r27)`,
`1003af30 stw r3,0x58(r27)`]

### 2.2 Handler struct (offsets from player+0x240)
| off | type | meaning | evidence |
|---|---|---|---|
| 0x00/0x04 | float | player x,y copy (`FUN_1003bb00(h, player)` each tick after the vertical clamp) | `FUN_10028170` dump line ~698; [HIGH] |
| 0x08 | byte | "weapon list changed" flag for the score bar (set by reset and by select; read by `FUN_1003bb30`) | listing `1003afd4 stb r29,0x8(r3)`, `1003b8fc stb r0,0x8(r22)`; [HIGH] |
| 0x09/0x0a/0x0b | byte | last tick's fireGround / fireAir / select (edge detection) | `1003b9d4 stb r24,0x9(r22)` …; [HIGH] |
| 0x11 | byte | **air power-up state** 0 idle · 1 charging · 2 overloaded · 3 releasing | §2.3; [HIGH] |
| 0x14 | int | air state start time (activation / overload / release tick) | [HIGH] |
| 0x18 | int | serial (`entity+0x9c`) of the activation entity | `1003c200 lwz r0,0x3c(r1); stw r0,0x18(r26)`; [HIGH] |
| 0x1c | int | time of last power-level step | [HIGH] |
| 0x20 | int | **power level** 0..max | [HIGH] |
| 0x24 | float | power percent 0..100 (score-bar power meter, `FUN_1003bb20`: `lfs f1,0x24(r3); blr`) | [HIGH] |
| 0x28 | int | time of last release spawn (= activation time until the first release) | [HIGH] |
| 0x2c | int | consecutive ticks fireAir held (0 when released) | `1003b418…1003b428`; [HIGH] |
| 0x31, 0x34..0x4c | | the same block for the ground power-up (state, start, serial, step time, level, percent, release time, held count) | [HIGH] |
| 0x50 / 0x54 | def* | pending air / ground weapon (switch requested while a power-up is active) | `FUN_1003b180`; [HIGH] |
| 0x58 | def* | current air weapon | [HIGH] |
| 0x5c / 0x60 | int | last air launch time (both written together) | `FUN_1003bf80`; [HIGH] |
| 0x68 | int | air launches since the weapon was set (only tested `> 0`) | [HIGH] |
| 0x6c / 0x6d | byte | zeroed / set to 1 on switch (meaning unknown; aux records carry "infinite ammo" at the same relative place) | LOW |
| 0x70 | list* | auxiliary weapons (24-byte records {def, lastLaunch, lastLaunch2, ammo, count, byte, infiniteAmmo}) | `FUN_1003b180` `'AUX '`, `FUN_1003bd40` log strings; [MED] |
| 0x74 | def* | current ground weapon | [HIGH] |
| 0x78 / 0x7c | int | last bomb salvo start / last bomb launch time | `FUN_1003beb0`; [HIGH] |
| 0x84 | int | bombs still to launch in the current salvo | [HIGH] |
| 0x8c… | sprite | crosshair sprite object (pos via `FUN_100128d0`, draw `FUN_10012f20`) | [MED] |
| 0xa8 / 0xac | 4CC/int | crosshair face / frame (refreshed each tick from the ground weapon) | [HIGH] |
| 0x120 / 0x121 | byte | crosshair shown / "locked" (over a ground target) | `FUN_1003bab0` listing; [HIGH] |
| 0x122 | byte | player index (owner byte of every spawn request) | [HIGH] |
| 0x124 / 0x128 | float | crosshair fade in/out rate (flli 149/150) | [HIGH] |

### 2.3 Per-tick order (`FUN_1003b3c0 @ 1003b3c0`; role was "weapon selector switch")
1. `+0x2c` = fireAir ? `+0x2c`+1 : 0 and `+0x4c` = fireGround ? `+0x4c`+1 : 0 (listing `1003b404…1003b448`).
2. **Release**: if fireAir is up and air state ∈ {1,2} → state 3, `+0x14`=now,
   `FUN_10034ce0(now, +0x18)`, return code 2. The same for ground. (`1003b44c…1003b4c8`)
3. If the air weapon has `autoRepeat == 0` → `FUN_1003c0d0` (air power-up, §2.5).
   (`1003b4cc lwz r6,0x58(r22); lbz r0,0x1ac(r6); cmplwi r0,0x0; bne skip`)
4. Ground power-up: an inline copy of §2.5 using `+0x1e8..+0x204`, run if either ground power-up ID is set.
   Differences: **no overload test** (`+0x1f8` is never read) and it never sets a return code.
   Unreachable with shipped data (Plasma Bomb has both IDs = `none`).
5. **Select** on its rising edge (`select && !+0x0b`): `next = FUN_1002adb0('PEAA', curAir.id, sector)`;
   if found → `FUN_1003b180(h,'PEAA',next)`; `+0x08`=1; `switched`=1; play PermSound 18
   `WepSelector_Switch` via `FUN_10047670(snd, 0x4b, 100, 1)`. Otherwise, if fireAir and air
   state == 0 → `FUN_1003bf80` (air) and `FUN_1003bff0` (aux). So pressing select that tick suppresses
   the air shot. (`1003b8a8…1003b960`)
6. **Bombs**: if a salvo is running (`+0x84 > 0`) and `now > +0x7c + delayBetweenLoadLaunches` →
   `+0x84`−1, launch, `+0x78`=`+0x7c`=now. Otherwise, on the fireGround rising edge (`!+0x09`) with
   ground state 0 → `FUN_1003beb0`. (`1003b964…1003b9d0`)
7. Store this tick's buttons in `+0x09/0a/0b`. Crosshair: `+0x120`=1, face/frame ← ground
   `+0x168/+0x16c`, `+0x121`=0, refresh sprite `+0x8c`.
8. Launch: ground `FUN_1003c4f0`, then air `FUN_1003c7a0`, then aux `FUN_1003c940`. Then
   `FUN_1003bab0(h,0)` (crosshair frame back to unlocked; `FUN_10033850` sets it locked with arg 1).
[HIGH: every step checked in `$W/disasm-weapons.txt`, the lines cited]

### 2.4 Fire rate, edge triggering, switching, availability
- **Air shot** `FUN_1003bf80 @ 1003bf80`: fires when `now > lastAir(+0x5c) + delayBetweenLaunches` and
  (`autoRepeat` or fireAir was **up** last tick). All five shipped weapons have `autoRepeat FALSE`, so
  each shot needs a fresh press, and a press inside the cooldown is dropped (no buffering). Minimum
  spacing = delay+1 ticks.
  ```
  1003bf88 lwz r5,0x5c(r3) ; 1003bf8c lwz r0,0x1b0(r6) ; add ; cmpw r4,r0 ; ble no-fire
  1003bf9c lbz r0,0x1ac(r6) ; bne fire ; 1003bfac lbz r0,0xa(r3) ; beq fire ; li r5,0
  1003bfc4 lwz r5,0x68(r3) ; addi +1 ; stw r4,0x5c(r3) ; stw r4,0x60(r3)
  ```
  [HIGH]
- **Switch** `FUN_1003b180 @ 1003b180 (h, type, def)`. For `PEAA`: if `def == +0x58` the pending switch is cleared.
  Else, if air state is 0 → immediate (`+0x58`=def, `+0x64`=`+0x68`=0, `+0x6c`=0, `+0x6d`=1,
  `+0x50`=0). Else the switch goes to pending `+0x50`, applied when the power-up returns to state 0 (`1003c4b4…`) or at
  the next handler reset. `PEAG` is the same with `+0x74/+0x54`. `'AUX '` toggles a record in the aux
  list; `'IMEF'` is compared and ignored. [HIGH for PEAA/PEAG (listing `1003b1f4…`); MED for AUX]
- **Availability by level.** `L` = `FUN_10005cd0()` = game `+0x14`, the sector (1-based position in
  the level order; MED per waves-and-enemies.md §3). The select button cycles through `PEAA` weapons with
  `min ≤ L ≤ max` in list order. Shipped data (list order aibg, aiic, aipb, airg):
  | L | air weapons in the select cycle | starting weapon at new game (`FUN_1003cdb0`) | auto-equipped at level start (`FUN_1003cd30`) |
  |---|---|---|---|
  | 1 | Ion | Ion | Ion (min 1) |
  | 2 | Bacta, Ion | Bacta | Bacta |
  | 3 | Bacta, Ion, Rear | Rear | Rear |
  | 4 | Bacta, Rear | Rear | none (keeps current) |
  | ≥5 | Bacta, Photon, Rear | Photon | Photon at 5 only |
  Level start (`FUN_100064d0` → `FUN_100269a0` → `FUN_1003af90(h,1)`) equips the weapon whose
  `minimumLevelAvailable` equals the new sector (listing `1003b0dc bl 0x10005cd0; bl 0x1003cd30;
  …; bl 0x1003b180`). The reset does **not** check that the current weapon is still in range: an Ion
  Cannon still held when sector 4 starts stays equipped until the next select. Select then jumps to Bacta,
  the first match, because the current weapon is not in the matching set. [HIGH for the code; MED for the
  table, since it rests on list order and on sector = "level"]
- **Ground weapon** is always the `DEAG` default (Plasma Bomb). Only the pending-apply in the reset and the
  uncalled `FUN_10029c00` can change it. [HIGH] ⚑ corrected (wave 2, 2026-10-03): was "uncalled" — `FUN_10029c00` has two raw
  callers (`10008408` 'PEAA', `10008490` 'PEAG') in an undecompiled debug console handler that is
  not registered in 1.0.6, so it is unreachable in release — see messages-notices-console.md §5.5,
  loose-ends-session.md §8.1. ⚑ corrected (review wave 2, 2026-10-03) (`FUN_10029c00` conflict closed): the command is
  `PLAYER AIRWEP|AIR` / `PLAYER GROUNDWEP|GROUND` (sub-keywords of the PLAYER handler `0x10007ff0`; strings `AIRWEP` `0x100e41fc`, `AIR` `0x100e4203`, `GROUNDWEP` `0x100e4207`, `GROUND` `0x100e4211`); unregistered → unreachable in 1.0.6 [HIGH for the code + strings].
- **Death / respawn**: `FUN_1002a150` → `FUN_10029cc0` → `FUN_1003af90(h,0)` resets timers,
  power-up state, held counters and bomb salvo, and applies any pending switch, but does **not** touch
  `+0x58/+0x74`. **No weapon is lost on death.** [HIGH (listing `1003afc0…1003aff8`
  writes `+0x5c +0x60 +0x68 +0x78 +0x7c +0x84`, never `+0x58/+0x74`)]
- **Score-bar icons** `FUN_1003bb40 @ 1003bb40` (callers `FUN_10031400`, `FUN_100317e0`) build three
  `{face, frame}` pairs: current (or pending) air weapon, next in cycle, the one after. A pair is replaced by
  `none` if it repeats an earlier one. [HIGH (read)]

### 2.5 Air power-up / overload machine (`FUN_1003c0d0 @ 1003c0d0`)
Runs only if `ActivationSpawn_ID` or `ReleaseSpawn_ID` ≠ `none`. Times are gameTime ticks; T0 = activation tick.
| state | test (listing) | effect |
|---|---|---|
| 0 idle | `1003c148 lwz r3,0x2c(r26); lwz r0,0x1c8(r28); cmpw r3,r0; blt exit` → **held ≥ TimeUntilActivation** | `+0x2c`=0; spawn `ActivationSpawn_ID` at player x,y (no offset, owner = player); `+0x18` = its serial; state 1; `+0x14`=`+0x1c`=`+0x28`=now; level 0; percent 0.0 |
| 1 charging, overload test first | `1003c230 lwz r3,0x1d8(r28); cmpwi r3,0; ble skip; …; cmpw r27,r0; ble skip` → **OverloadTime > 0 and now > `+0x14` + OverloadTime** | return 1; state 2; `+0x14`=now |
| 1 charging, level step | `1003c26c lwz r3,0x1c(r26); lwz r0,0x1d0(r28); add; cmpw r27,r0; ble exit` → **now > last + TimeBetweenPowerLevelChanges** | level+1; percent = `(float)(100.0 × ((float)level / (float)max))` (`fsubs; fdivs; fmul f4(=100.0); frsp`); percent < 1.0 → 0.0, > 100.0 → 100.0. If level > max (`1003c30c cmpw r0,r3; ble`) → level = max, percent 100.0, and if `DoReleaseOnMaxPowerLevel` → state 3, `FUN_10034ce0`, return 2; `+0x1c` is not updated. Else `+0x1c`=now |
| 2 overloaded | `1003c120 cmpwi r0,0x2; beq exit` | nothing (level frozen) until fireAir is released → state 3 (§2.3 step 2) |
| 3 releasing | `1003c35c lwz r0,0x20(r26); cmpwi r0,0; ble reset` | level ≤ 0 → state 0, `+0x14`=now, percent 0.0, apply pending `+0x50`. Else if `now > +0x28 + TimeBetweenReleaseSpawns` (`1003c368…ble exit`) → spawn `ReleaseSpawn_ID` at player x,y, `+0x28`=now, level−1, recompute percent |
Constants: `r30 = r2−0x6e74 → 0x100df4bc → 0x100d72b8` = doubles {100.0, 1.0, 2^52+2^31 magic};
`r31 = r2−0x6e6c → 0x100df4c4 → 0x100d72b0` = floats {0.0, 100.0} (Python on `mem/10000000.bin`). [HIGH]

What this means:
- Holding fire: the press tick t_p fires a normal shot and counts 1. The power-up **activates on the 15th
  consecutive held tick** (t_p+14) for every shipped weapon (`TimeUntilActivation 15`).
- Level k is reached at T0 + k·(TBPLC+1). Overload is timed from **activation**, not from reaching
  max: it comes on the first tick after T0+OverloadTime.
- On release (state 1 or 2) the activation entity is told to switch (`FUN_10034ce0` finds the entity with
  `+0x9c == serial` → `FUN_10014670` puts it in its first state flagged
  `stateUseThisStateOnWeaponPowerupRelease` (+0x355; `unit+0x835+s·0x5e0`)). In the same tick the release
  stream begins. **`level` release spawns** follow, one every TBRS+1 ticks, then the weapon returns to idle. Releasing
  at level 0 gives no release spawn. [HIGH]
- Quirk: `+0x2c` keeps counting while fireAir is held during state 3. If the button is still (or again)
  held for ≥15 ticks when state 0 resumes, the power-up re-activates on that tick. [HIGH by reading]

### 2.6 Overload penalty (player side, `FUN_10026ee0 @ 10026ee0`)
On return code 1, `FUN_10028170` (if the game flag `FUN_10005cf0()` = game `+0x39` is clear and no warning is already
running) sets player `+0x210`=1 (warning on), `+0x211`=1 (wait phase), `+0x218`=now, `+0x21c` =
`powerupOverload_InitialTimeBetweenWarnings` (playerDef `+0xe0`, 8), `+0x220`=0 (count),
`+0x64` = `powerupOverload_Hilite_COLOR` (`+0xec`) (listing `10029168…1002919c`). Every tick
`FUN_10026ee0` then does:
- wait phase: if `now > +0x218 + interval` → `+0x218`=now, tint `+0x58` += 100.0. On reaching ≥100 → 100,
  fade phase, interval−1 (floor `powerupOverload_MinimumTimeBetweenWarnings` `+0xe4` = 3),
  count+1. If **count == `powerupOverload_NumWarnings` (`+0xdc` = 8) → `FUN_10027e50(player, now)`**,
  otherwise play `powerupOverloadSound` (`+0xf0`, `wewa`).
- fade phase: tint −= `powerupOverload_WarningFadePercent` (`+0xe8`, 20) per tick; at ≤ 0 → 0 and back to wait.
`FUN_10027e50` is the **player death**: it spawns `death_Spawn_ID` (`+0xbc`), spills all coins as
MoneyUnit_50/10/5/1 units, zeroes coins (`+0xac` ← 0xb2cce = encoded 0) and sets player state
`+0xc6` = 3 (role table: "coin unit selection", ⚑ conflict). Return code 2 (release) clears the
warning (`+0x210`=0, tint reset; decompile of `FUN_10028170` lines 485–497).
plde offsets from `FUN_10039e70` reader calls (`…_NumWarnings_INT…, param_3 + 0xdc` etc., dump lines
34459–34469). Guide wording ("without fear of self destruction" for Photon Beam) agrees.
Timeline with shipped values, S = overload tick (`FUN_10026ee0` runs before the weapon call in
`FUN_10028170`, so it first acts at S+1): flashes at S+9, S+17, S+24, S+30, S+36, S+42, S+48 (sound
each) and death at **S+54** (≈1.8 s at 30 fps). [HIGH for the rules and offsets (decompile + plde
parser); MED for the tick timeline (assumes tint 0 at start; call order from the decompile)]

### 2.7 Bombs (`FUN_1003beb0 @ 1003beb0`)
On a fresh fireGround press with `now > +0x78 + delayBetweenLaunches`:
```
1003beec bl 0x10005cd0 (sector) ; 1003bef8 li r3,0x97 ; bl 0x10020250 ; fctiwz   ; flli 151 DefaultNumBombs = 1.0
1003bf14 add r4,r31,r0 ; subi r0,r4,0x1 ; stw r0,0x84(r29)                       ; n = sector + 1 − 1
1003bf08 li r3,0x98 ; …; cmpw r0,r3 ; ble ; stw r3,0x84(r29)                       ; flli 152 MaxNumBombs = 8.0 → n = min(n, 8)
1003bf44 lwz r4,0x84 ; subi ; stw r0,0x84(r29) ; stw r30,0x78 ; stw r30,0x7c ; li r3,1  ; launch #1 now
```
So "bombs" are a **salvo size, not an inventory**: one press launches `min(sector + 1 − 1, 8)` =
min(sector, 8) Plasma Bombs. The first goes at once, the rest one every `delayBetweenLoadLaunches+1` ticks
(step 6 of §2.3). The next salvo needs a new press more than `delayBetweenLaunches` ticks after the **last** bomb
(`+0x78` is refreshed per bomb). Guide: "your Plasma Bomb launcher is automatically upgraded for you"
each level. [HIGH; flli values by `awk 'NR==152||NR==153' flli/Game[gafl].flli.txt` (0-based 151/152)]

### 2.8 Crosshair
Position (in `FUN_10028170`, dump ~24456): `x = player.x + crosshairXOffset`, `y = player.y +
crosshairYOffset + adj`, with `adj` = player `+0x20c` ∈ [0, flli 187 `Crosshair_MaxAdjustment` 80].
`adj` += flli 185 `Crosshair_DownSpeed` (3) per tick while down is held and the ship is pinned at its
vertical limit. Otherwise `adj` += flli 186 `Crosshair_UpSpeed` (−4) per tick, floor 0. y is
clamped so that `y − halfHeight ≥ 0.0`. The guide matches: "Pressing down while the VacFighter is at the bottom of the screen
will cause the bomb crosshair to drop down". [MED: decompile only; "pinned at the bottom" = `bVar17`, LOW]
Frame = `crosshairFrame` normally, `crosshairLockedFrame` when `FUN_10033850` calls
`FUN_1003bab0(h,1)` (the guide's "glow red when over an enemy"). Plasma Bomb: face `pbta`, frames 0/1,
offset (0, −121). [HIGH for `FUN_1003bab0` (listing); MED for when it is called]

## 3. Launch → entity

### 3.1 Spawn request (0x2c bytes; template at `r2+0x69e4` = `0x100ecd14`)
Every launcher copies the template, then fills the fields. Runtime template (image overwritten before `main` by `FUN_1003ce60`): `none, 0.0, 0.0, 0, 0, 0xff000000,
0, 0, 0, −1, 1.0f` — only +0x24 differs from the image (`1003cf00 stw r0,0x24(r12)`, source `0x100d72a8`
= `00000000 ffffffff`; static-init-audit.md §5.1 #23). ⚑ corrected (wave 3+4, 2026-10-04): was "Template image: … 0, 0, 0, 0, 1.0f
(Python on `mem/100de330.bin` at `0x100ecd14`). `FUN_1003ce60` (static init) refreshes parts of it." Fields as `FUN_10033220`/`FUN_10035cd0` consume them:
| off | meaning | consumer (listing) |
|---|---|---|
| 0x00 | unit ID (`none` → assert) | `10033240` |
| 0x04 / 0x08 | x / y (world) | group `+0x9c/+0xa0` |
| 0x0c | byte: y is screen-relative (converted with `FUN_1000fec0`) | `10033524 lbz r0,0xc(r24)`; 0 for weapons |
| 0x0d | byte: SetHeading → heading = `+0x10` (± tolerance) | `10033580 lbz r0,0xd(r24)` |
| 0x10 | heading (deg) | `100335b0 lwz r8,0x10(r24)` |
| 0x14 | byte: spawning player (−1 none) → entity `+0xd8` | `10033370`, `10035d94` |
| 0x18 | heading used when SetHeading = 0 and the unit has `initialHeadingSetInEditor` | `10033594` |
| 0x1c / 0x1d | bytes → entity `+0x13c/+0x13d` (`+0x13c` ≠ 0 = no initial motion) | `10035f20` |
| 0x20 / 0x24 | parent entity / extra → entity `+0x140/+0x144` | `10035d54` |
| 0x28 | float **initial-speed multiplier** (1.0 default) | `10035f44 lfs f1,0x28(r22)` → `FUN_10037b50`: `10037e58 lfs f0,0x18(r31) (=1.0); fcmpu f0,f30; beq; … fmuls` on vx `+0x10`, vy `+0x14` |
`FUN_10033220` also applies the unit's group size, `canBeSpawnedOnlyWhenPlayersActive`,
`doNotSpawnIfTypeAlreadyExists`, `deleteExistingEntitiesOfThisType` (only when owner ≠ −1), and the
**1000-entity cap** (`count + n < 0x3e9`, else "Reached Entity Limit" once). Its out-param receives
`{entity*, serial}` (`FUN_10035cd0`: `*param_8 = entity; param_8[1] = entity+0x9c`, serial =
`_DAT_100e0204++`). [HIGH for the listed offsets; MED for `+0x18/+0x1c` semantics]

### 3.2 Launchers
| function | what it spawns | label |
|---|---|---|
| `FUN_1003c7a0 @ 1003c7a0` (**air**, only if `+0x68 > 0`) | every spawn record of `+0x58` whose unit ≠ none: x = h.x + XLoc, y = h.y + YLoc, `+0x0d` = SetHeading, `+0x10` = Angle, owner = `+0x122` | HIGH (listing: request at `r1+0x40`, `1003c8e0 stfs →0x44`, `1003c900 stfs →0x48`, `1003c908 stb →0x4d`, `1003c910 stw →0x50`, `1003c8bc stb r7,0x54(r1)` from `0x122(r27)`) |
| `FUN_1003c4f0 @ 1003c4f0` (**ground**; role was "launch weapon") | each spawn record of `+0x74` likewise, plus speed multiplier `+0x28 = (float)max(0, trunc(h.y − crosshair.y)) / (float)abs(crosshairYOffset)`. Then, if `crosshairSpawnOnActivation_ID` ≠ none, that unit at the **crosshair** position | HIGH (listing `1003c658 lfs f1,0x4(r27); lfs f0,0x3c(r1); fsubs; fctiwz; …bge; li r21,0` · `1003c680 lwz r3,0x17c(r3); bl 0x1004ee30 (abs)` · `1003c6cc fdivs; stfs f0,0x9c(r1)` = request+0x28) |
| `FUN_1003c940 @ 1003c940` (**aux**) | spawn records of every aux weapon with count > 0 | MED (read; unreachable in shipped data) |
| `FUN_1003bff0 @ 1003bff0` | aux fire timing (same rule as `FUN_1003bf80`, per record) | MED (read) |
Effect of the bomb multiplier: with the crosshair at its default (adj 0) the ratio is 121/121 = 1.0. Dropping
the crosshair by adj gives (121−adj)/121, so bombs fly slower and shorter and come down nearer the ship. [HIGH
arithmetic; MED for the gameplay reading]

Heading for projectiles: with SetHeading FALSE the heading comes from the unit (`initialHeading`
+0x1a4, or request `+0x18`=0 when `initialHeadingSetInEditor`). With TRUE it is `Angle` plus
`RandomRange(−tol/2, tol/2)` when `initialHeadingTolerance` ≠ 0 (`10035ed4…10035ee4`). All
shipped projectile units have heading 0 and tolerance 0, so they fly straight up. 0 = north is MED (bullets go up the screen).

### 3.3 RNG
The handler itself never draws. Each spawn goes through the generic creation draws (engine-loop.md §9).
For the units the five weapons spawn directly, all of them have min = max for speed, group size and first-state timer,
tolerance 0 and appears 100 %, so **no draw**. The exception is the Rear Gun release unit `rgpb` (speed 9–11, tolerance
16, timer 120–130): it draws per release spawn. Children made by spawn sets were not traced. [MED: a Python census of
the 16 units (`icb icbf bagb bagl pb rgbs plbo pblf icpo icps bgpo bgpb pbpo pbps rgpo rgpb`) plus the
§9 rule "no draw when min == max"]

## 4. Pickups and the handler
`FUN_10037580 @ 10037580 (player, entity)` (called from the `FUN_10033850` collision step; a return of 1
→ the pickup is destroyed with `+0xd9` = player) switches on `pickup_Type_ID` (+0x4d4):
`coin` → `FUN_100275b0` + glow, if `pickup_Value` ≠ 0 · `exli` → `FUN_10026d70(player,1)` · `shie` →
`FUN_10027490(player,(float)pickup_Value)` · `mult` → `FUN_10029b20` · `air `/`grnd` → **only**
`FUN_10027dd0(player)` (player `+0xce`). If that flag is set, return 0 (not taken). `spec` → nothing.
[HIGH: listing `10037630 bl 0x10027dd0 … li r31,0x0`; no call into the handler on any path]
So **no pickup type changes the weapon handler**. Weapon pickups (`air `/`grnd`/`spec`) are only cosmetic:
on each state change `FUN_100146f0` cycles the entity's shown weapon `+0xf8` with `FUN_1002adb0` and shows its
`scoreBarPreviewFace` (unless `statePickup_DoNotChangeAppearance` +0x357). In any case, **no shipped unit uses
these types** (census: coin 4, exli 1, mult 1, shie 2, none 378). The only code that moves a player to the
next weapon of a type, `FUN_10029c00` (G_Player), has no caller in the dump and no pointer in either
memory image. [HIGH for the census and the code; LOW that `FUN_10029c00` is dead rather than reached indirectly]
⚑ corrected (review wave 2, 2026-10-03): its only callers are the debug command `PLAYER AIRWEP|AIR` / `PLAYER GROUNDWEP|GROUND` (sub-keywords of the PLAYER handler `0x10007ff0`; strings `AIRWEP` `0x100e41fc`, `AIR` `0x100e4203`, `GROUNDWEP` `0x100e4207`, `GROUND` `0x100e4211`), unregistered → unreachable in 1.0.6
(messages-notices-console.md §5.5) [HIGH].
⚑ corrected (wave 2, 2026-10-03): was "has no caller in the dump" — raw calls at `10008408`/`10008490` (debug console
weapon command, AIRWEP/AIR/GROUNDWEP/GROUND strings), unregistered → unreachable in normal play —
see loose-ends-session.md §8.1, messages-notices-console.md §5.5.
Not read: `FUN_10027dd0`'s flag writer `FUN_10027de0` (role of `+0xce/+0xcf`), `FUN_10027490`, `FUN_10029b20`.

## 5. Other in-range functions
| function | role | label |
|---|---|---|
| `FUN_1003af90 @ 1003af90` | handler reset (arg 1 = level start: auto-equip `FUN_1003cd30(sector)`; arg 0 = apply pending air). Always applies pending ground, unlocks the crosshair, sets `+0xf4/+0xf8` = {0,100}, `+0xfc` = fade-in rate | HIGH (listing §2.4) |
| `FUN_1003b340 @ 1003b340` | weapon of type: `PEAA` → `+0x58`, `PEAG` → `+0x74`, else 0 | MED (read; caller `FUN_10029c00`) — ⚑ label audit (review wave 1) |
| `FUN_1003bab0 @ 1003bab0` | crosshair locked/unlocked frame | HIGH (listing) |
| `FUN_1003bb00 @ 1003bb00` | copy x,y into the handler | MED (read) — ⚑ label audit (review wave 1) |
| `FUN_1003bb20 @ 1003bb20` | get power percent `+0x24` (float return; the decompiler shows an empty body) | HIGH (listing) |
| `FUN_1003bb30 @ 1003bb30` | get `+0x08` flag | HIGH (listing) |
| `FUN_1003bb40 @ 1003bb40` | score-bar weapon icons (§2.4) | MED (read) — ⚑ label audit (review wave 1) |
| `FUN_1003bce0 @ 1003bce0` | displayed air weapon = pending `+0x50` else `+0x58` | HIGH (listing) |
| `FUN_1003bd00 @ 1003bd00` | draw crosshair if shown (`FUN_10012f20(+0x8c)`) | MED (read; caller `FUN_100298c0`) — ⚑ label audit (review wave 1) |
| `FUN_1003bd40 @ 1003bd40` | debug log "Weapon Handler Log for Player…" (primary air/ground, aux list) | MED (read; no caller) |
| `FUN_1003cb30 @ 1003cb30` | free all aux records | HIGH (read; callers `FUN_1003ad40`, `FUN_1003ade0`) |
| `FUN_1003cbf0 @ 1003cbf0` | find aux record by weapon ID | MED (read) — ⚑ label audit (review wave 1) |
| `FUN_1003ce60 @ 1003ce60` | static init of request/record templates at `0x100ecccc…0x100ecd4c` | MED (read; caller `FUN_10000000`) |
| `FUN_1003cf10 @ 1003cf10` | **G_UnitDefinitions** module init: console commands LOGSCROLLPAUSERS, LOGFAMILIES, FAMILIES, LOGUNUSEDUNITS, UNITSCORES. Loads the units cache (`FUN_100420f0`) or builds the master list `FUN_1003d0a0(1)` | MED (read; caller `FUN_100000e0`) |
| `FUN_1003d030 @ 1003d030` | G_UnitDefinitions module teardown (`FUN_10041e40` cache save if dirty, frees) | MED (read; caller `FUN_10000630`) |
| `FUN_1002c4d0…FUN_1002cc90` (12 fns) | token readers | already HIGH/MED in the bank; not re-read |
Every function in both ranges is listed in this file. None is "not read".

## Worked example
**Air – Ion Cannon `aiic` at sector 1, player 1 at (208, 330).** (File values from
`$W/data/Game/wede/Air - Ion Cannon[aiic].wede.txt`; unit values from the decoded `unde` files.)
1. New game at sector 1: `FUN_1003cdb0(1)` → only Ion has `1 ≤ 1 ≤ 3` → air = Ion; ground =
   `FUN_1003cca0(1)` → Plasma Bomb (`DEAG`). Ship face `pl1o`.
2. Tap Fire Air at tick t (cooldown clear): `FUN_1003bf80`: `t > last + 4` → shot; `+0x5c` = t.
   `FUN_1003c7a0` spawns 3 requests (owner 0, SetHeading 0):
   `icb ` at (203, 330), `icbf` (flash) at (208, 322), `icb ` at (212, 330). `icb `: speed 10/10 (no RNG),
   heading 0, `damage 0.4`, `playerProjectile TRUE`, `harmlessToPlayers TRUE`, one state with
   `stateMaxSpeed 10`, `stateCollides TRUE`. The next shot needs a new press at ≥ t+5 (max 6 shots/s at 30 fps).
3. Hold from tick t: `+0x2c` = 1 at t … 15 at **t+14 → activation** (T0 = t+14): `icpo` spawned at the
   ship (serial kept), state 1. Levels: k at T0+3k (TBPLC 2 → every 3 ticks), percent 5k %. Level 20 =
   100 % at T0+60 (t+74, ≈2.5 s). At T0+63 level 21 is clamped to 20 (DoRelease FALSE → keeps charging).
4a. Release at tick r with level 20: `icpo` → state `_Powerup Release, Dwindle & Del` (the one flagged
   `stateUseThisStateOnWeaponPowerupRelease`, 50 ticks then Delete). `icps` is spawned at the ship at r, r+2,
   …, r+38 (20 spawns, TBRS 1). At r+40 level 0 → idle. Each `icps` lives 6 ticks in "Spawn Bullet,
   Expand" (spawn set `icpb`), then "Dwindle & Delete" 12 ticks.
4b. Keep holding: at T0+181 (t+195, 6.5 s after the press) overload → state 2, return 1, player warning:
   flashes at S+9 … S+48 with `wewa` each, and at S+54 (t+249, ≈8.3 s after the press) `FUN_10027e50` kills the
   player (death spawn `plde`, coins spilled). Releasing at any tick before S+54 → state 3 (20 release spawns)
   and the warning stops.
**Other air weapons** (same rules, `TimeUntilActivation 15`):
| weapon | delay → min shot spacing | spawns per shot | level step | max (full at) | overload at | release unit, every |
|---|---|---|---|---|---|---|
| Bacta `aibg` | 5 → 6 ticks | 7 × `bagb` at angles 3,6,9,357,354,351,0 from (±3,−10),(±6,−8),(±9,−3),(0,−11) + flash `bagl` (0,−9); `bagb` speed 12, life 20 ticks | 3 ticks | 20 (T0+60) | T0+181 | `bgpb`, 2 ticks |
| Rear Gun `airg` | 8 → 9 ticks | 1 × `rgbs` spawner (speed 0, 6 ticks) | 4 ticks | 12 (T0+48) | T0+181 | `rgpb`, 3 ticks (random speed 9–11, ±8°) |
| Photon Beam `aipb` | 8 → 9 ticks | 1 × `pb  ` (speed 0, 3 ticks) | 6 ticks | 22 (T0+132) | never (0) | `pbps`, 4 ticks |
**Ground – Plasma Bomb `plbo` at sector 5**: a fresh Fire Ground press at t (with `t > lastBomb + 4`) →
salvo of min(5, 8) = 5. Bombs go at t, t+2, t+4, t+6, t+8 (`delayBetweenLoadLaunches 1`), each = `plbo` at the
ship (heading 0 from `initialHeadingSetInEditor`, speed 6 × ratio) + flash `pblf` at (x, y−6). With adj = 0 the ratio
is 1.0, so the bomb flies 19 ticks (state "Flight", timer 19/19) × 6 = 114 px up toward the crosshair at
y−121, then enters "Dwindle & Delete". With adj = 40 the ratio is 81/121 = 0.669 → 4.02 px/tick. The next salvo
needs a press after t+8+4. Nothing in this weapon powers up (all `powerup_*` IDs none).

## NOT RESOLVED (this file)
1. Game flag `+0x39` (`FUN_10005cf0`) that suppresses the overload warning (and gates
   `canBeSpawnedOnlyWhenPlayersActive`): its writer was not found. A grep for stores at game `+0x39` would settle it.
2. Player `+0xce/+0xcf` (`FUN_10027de0`), the flag that makes `air `/`grnd` pickups untakeable: read its callers.
3. Consumers of `numAmmoInPack`, `ammoWarnAtCount`, `ammoWarning_STR`, `shieldIncrease`, `livesIncrease`,
   `invulnerableForTime`, `maxAllowed`, `playerGlow_COLOR`, `name/description` (none found). A data
   xref of the definition pointer, or the editor code, would settle it.
4. ~~`FUN_10047670(snd, 0x4b, 100, 1)` argument meaning for the select sound (INDEX #11).~~ → ⚑ corrected (review wave 2, 2026-10-03)
   #S: sound-music.md §2.3 (priority 0x4b = 75, volume 100, allowMultiple 1).
5. Whether handler `+0x08` is ever cleared after a select (score-bar refresh flag). Only setup clears it.
6. `bVar17` in the crosshair adjustment (which vertical limit pins the ship). Needs the listing of
   `FUN_10028170` around `0x100293xx`.
7. The movement that turns heading 0 + speed into motion (`FUN_10043040`/`FUN_10042b80`) and the
   north = 0 convention (movement reader).
8. Tag-index order vs pak order once `FUN_10004300` (override) runs. This affects the cycle order of §2.4.
9. Handler `+0x6c/+0x6d` and aux `+0x14/+0x15` meanings (ammo/infinite flags?): unused by shipped data.

## Role-table rows (for merge)
| `FUN_1002ab20` | G_WeaponDefinitions.cc | build master weapon list (wede tags in index order) | MED | read; caller `FUN_1002aa90` — ⚑ label audit (review wave 1) |
| `FUN_1002acf0` | G_WeaponDefinitions.cc | i-th weapon definition | MED | read — ⚑ label audit (review wave 1) |
| `FUN_1002adb0` | G_WeaponDefinitions.cc | next weapon of type available at level after cur (wraps; `none` → first) | HIGH | listing `1002ae30…1002ae8c` |
| `FUN_1002aec0` | G_WeaponDefinitions.cc | list of unit IDs a weapon references | MED | read — ⚑ label audit (review wave 1) |
| `FUN_1002b150` | G_WeaponDefinitions.cc | is unit referenced by any weapon (no caller found) | MED | read |
| `FUN_1002b240` | G_WeaponDefinitions.cc | free ID list | MED | read — ⚑ label audit (review wave 1) |
| `FUN_1002b2a0` | G_WeaponDefinitions.cc | weapon-def defaults (magic, none IDs, sound defaults) | HIGH | read + image `0x100d7014` |
| `FUN_1002b3a0` | G_WeaponDefinitions.cc | preload PEAA/PEAG/SPEC weapons for level | MED | read; caller `FUN_100064d0` — ⚑ label audit (review wave 1) |
| `FUN_1002b400` | G_WeaponDefinitions.cc | collect weapon sprite (1) / sound (0) IDs (no caller found) | MED | read |
| `FUN_1002b590` | G_WeaponDefinitions.cc | free master weapon list | MED | read — ⚑ label audit (review wave 1) |
| `FUN_1002b6d0` | G_WeaponDefinitions.cc | preload weapons of type at level | MED | read — ⚑ label audit (review wave 1) |
| `FUN_1002b790` | G_WeaponDefinitions.cc | preload one weapon's sprites/sound/units | MED | read — ⚑ label audit (review wave 1) |
| `FUN_1002b8e0` | G_WeaponDefinitions.cc | load i-th wede tag (0x208 def) | MED | read — ⚑ label audit (review wave 1) |
| `FUN_1002c490` | G_WeaponDefinitions.cc | init weapon spawn record (0x34) | MED | read — ⚑ label audit (review wave 1) |
| ⚑ corrected `FUN_1003ade0` | G_WeaponHandler.cc | weapons-handler setup: reset, crosshair fade rates F149/150, default ground (DEAG) + starting air (`FUN_1003cdb0`) | HIGH | listing `1003ae48…1003af3c` (was "crosshair fade", MED) |
| `FUN_1003af90` | G_WeaponHandler.cc | handler reset (arg 1: auto-equip weapon unlocked at sector; pending apply; keeps weapons) | HIGH | listing `1003b0ac…1003b134` |
| `FUN_1003b180` | G_WeaponHandler.cc | set weapon of type (immediate if no power-up active, else pending); AUX toggle | HIGH | listing |
| `FUN_1003b340` | G_WeaponHandler.cc | current weapon of type | MED | read — ⚑ label audit (review wave 1) |
| ⚑ corrected `FUN_1003b3c0` | G_WeaponHandler.cc | per-tick weapon handler: held counters, release, power-ups, select, air fire, bomb salvo, crosshair, launches; returns 1 overload / 2 release | HIGH | listing (was "weapon selector switch", MED) |
| `FUN_1003bab0` | G_WeaponHandler.cc | crosshair locked/unlocked frame | HIGH | listing |
| `FUN_1003bb00` | G_WeaponHandler.cc | set handler x,y | MED | read — ⚑ label audit (review wave 1) |
| `FUN_1003bb20` | G_WeaponHandler.cc | get air power percent (+0x24) | HIGH | listing |
| `FUN_1003bb30` | G_WeaponHandler.cc | get weapon-list-changed flag | HIGH | listing |
| `FUN_1003bb40` | G_WeaponHandler.cc | score-bar weapon icons (cur/next/next) | MED | read — ⚑ label audit (review wave 1) |
| `FUN_1003bce0` | G_WeaponHandler.cc | displayed air weapon (pending else current) | HIGH | listing |
| `FUN_1003bd00` | G_WeaponHandler.cc | draw crosshair | MED | read — ⚑ label audit (review wave 1) |
| `FUN_1003bd40` | G_WeaponHandler.cc | debug log of handler (no caller) | MED | read |
| ⚑ corrected `FUN_1003beb0` | G_WeaponHandler.cc | start bomb salvo: n = min(sector + F151 − 1, F152) | HIGH | listing `1003beec…1003bf58` (was "bomb count default/max", MED) |
| `FUN_1003bf80` | G_WeaponHandler.cc | air fire timing (cooldown + edge unless autoRepeat) | HIGH | listing |
| `FUN_1003bff0` | G_WeaponHandler.cc | aux fire timing | MED | read |
| ⚑ corrected `FUN_1003c0d0` | G_WeaponHandler.cc | air power-up machine (activation on held ≥ +0x1c8; step every +0x1d0+1 ticks; overload at activation + +0x1d8 → return 1; release spawns every +0x1e0+1) | HIGH | listing `1003c148…1003c4d4` (was MED) |
| ⚑ corrected `FUN_1003c4f0` | G_WeaponHandler.cc | GROUND weapon launch (spawn records + speed ratio to crosshair) + crosshairSpawnOnActivation | HIGH | listing `1003c578…1003c784` (was "launch weapon", MED) |
| `FUN_1003c7a0` | G_WeaponHandler.cc | AIR weapon launch (spawn records at pos + XLoc/YLoc) | HIGH | listing |
| `FUN_1003c940` | G_WeaponHandler.cc | aux weapon launch | MED | read |
| `FUN_1003cb30` | G_WeaponHandler.cc | free aux records | MED | read — ⚑ label audit (review wave 1) |
| `FUN_1003cbf0` | G_WeaponHandler.cc | find aux record by weapon ID | MED | read — ⚑ label audit (review wave 1) |
| ⚑ corrected `FUN_1003cca0` | G_WeaponHandler.cc | first weapon with default DEAA (0) / DEAG (≠0), level ignored | HIGH | read + caller listing (was MED) |
| `FUN_1003cd30` | G_WeaponHandler.cc | PEAA weapon with min level == L | HIGH | listing |
| `FUN_1003cdb0` | G_WeaponHandler.cc | starting air weapon: available PEAA with highest min level | HIGH | listing |
| `FUN_1003ce60` | G_WeaponHandler.cc (span) | static init of spawn-request templates | MED | read |
| `FUN_1003cf10` | G_UnitDefinitions.cc | unit-defs module init (console cmds, cache or build) | MED | read |
| `FUN_1003d030` | G_UnitDefinitions.cc | unit-defs module teardown | MED | read |
| `FUN_10034ce0` | G_EntityGroup.cc | find entity by serial → `FUN_10014670(entity, now)` | HIGH | read; listing `10034d8c lwz r0,0x9c(r3); cmpw r0,r25`, `10034d98 or r4,r24,r24; bl 0x10014670` (arg 1 = time, passed on as `FUN_100146f0` param_4 → +0xa4); callers `FUN_1003b3c0`, `FUN_1003c0d0` — ⚑ label audit (review wave 1): HIGH kept, listing added in the fix pass; this reading wins the spawn-and-waves.md conflict |
| `FUN_10014670` | G_Entity (span) | switch entity to its UseThisStateOnWeaponPowerupRelease state | MED | read (+0x835 = 0x4e0+0x355) — ⚑ label audit (review wave 1) |
| `FUN_10037580` | G_EntityGroup.cc | apply pickup by pickup_Type_ID (coin/exli/shie/mult; air/grnd only check player+0xce) | HIGH | listing |
| `FUN_10026ee0` | G_Player.cc | overload warning pulse; 8th warning → player death | HIGH | read + plde offsets — ⚑ label audit (review wave 1): HIGH kept — listing evidence in player-physics.md role rows |
| ⚑ corrected `FUN_10027e50` | G_Player.cc | player death: death spawn, coin spill (MoneyUnit 50/10/5/1), state 3 | MED | read (was "coin unit selection") |
| `FUN_10029c00` | G_Player.cc | advance player to next weapon of type; reached only from the debug command `PLAYER AIRWEP\|AIR` / `PLAYER GROUNDWEP\|GROUND` (sub-keywords of the PLAYER handler `0x10007ff0`; strings `AIRWEP` `0x100e41fc`, `AIR` `0x100e4203`, `GROUNDWEP` `0x100e4207`, `GROUND` `0x100e4211`), unregistered → unreachable in 1.0.6 | HIGH | raw calls `10008408` ('PEAA'), `10008490` ('PEAG') + data-image strings — ⚑ corrected (wave 2, 2026-10-03): callers found in an unregistered debug console handler (`10008408`, `10008490`); see messages-notices-console.md §5.5 — ⚑ corrected (review wave 2, 2026-10-03) (conflict closed): was "(no caller found)" MED |
| `FUN_10029f60` | G_Player.cc | ship sprite = displayed weapon's appearance face | HIGH | read — ⚑ label audit (review wave 1): HIGH kept — listing evidence in player-physics.md role rows |

## INDEX updates (for merge)
- **#25 closed for the weapon half** (fire, power-up, overload, bombs, launch → entity): this file §2–§3.
  Player physics stays with engine-loop.md §8; the crosshair position is in §2.8 (MED).
- waves-and-enemies.md §6: "Bombs: DefaultNumBombs 1, MaxNumBombs 8" should read as a **salvo size
  min(sector, 8)** (§2.7); "weapon firing/power-up code NOT RESOLVED" → this file. The NOT RESOLVED
  #7 there is closed for weapons.
- ⚑ conflict: function-roles.md `FUN_10027e50` "coin unit selection" → player death (§2.6).
- New NOT-RESOLVED candidates: items 1, 3, 8 above (game flag `+0x39`; unused weapon keys; index
  order after overrides).
- Topical-files table: add `weapons-projectiles.md` (§1 wede loader + key table, §2 handler struct /
  per-tick / power-up / overload / bombs / crosshair, §3 spawn request + launchers + RNG, §4
  pickups, §5 other functions).
