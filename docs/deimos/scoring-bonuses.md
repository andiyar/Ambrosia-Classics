# Deimos Rising 1.0.6 — scoring, money, bonuses, extra lives, level selection, finale

Scope (reader F, wave 1, 2026-10-03): score storage and the add-score path (`FUN_10029a10`),
extra lives (`FUN_10026cc0`, `FUN_10026d70`), the score multiplier (`FUN_10029b20`,
`FUN_10029fe0`), money (pickups `FUN_10037580`, accessors, death spill `FUN_10027e50`), the
end-of-level bonus sequence inside `FUN_10006b50` (defence-bonus **payout**, ground-accuracy
count + tier + tally `FUN_100072c0`/`FUN_100075e0`, mission bonus, coin bonus
`FUN_10027670`/`FUN_10027930`), the random-bonus **selection** in `FUN_10016300`, the high-score
gate/entry (`FUN_10021470`, `FUN_100214c0`, and the gating code in `FUN_100234d0`), the
level-selection screen range `0x1002e310–0x10031400`, and the finale. OUT: the death sequencing
around `FUN_10016300` and entity damage (damage reader), defence-bonus damage latch and player
movement (player reader — `player-physics.md`), weapon power-ups, the frame controller rows in the
range (engine-loop.md §3–§4, not re-read).

Evidence: decompile dump; raw listings `$W/disasm-scoring.txt` (DisasmFuncs) and
`$W/disasm-scoring-ranges{,2,3}.txt` — made with a new range post-script
`DisasmRange.java` (kept in my scratchpad; same headless form as the brief, `-postScript
DisasmRange.java <out> start:end …`; it disassembles jump-table case bodies that DisasmFuncs
skips). Whole-binary call-site scans: a Python pass over `$W/mem/10000000.bin` decoding every
`bl` (opcode 18, LK=1) and the preceding `li r3,imm` ("raw bl-scan" below). Constants: flli index
= `grep '^#' Game[gafl].flli.txt | awk '{print NR-1, $0}'`; pgsl index = file line − 1 (0-based,
`FUN_10020260(0xe)` = line 15 "Coin Bonus:"); gaob/gaso indices likewise.

## 1. Data structures

### 1.1 Player scoring fields (player object, 0x36c bytes, `FUN_10026260` constructor)
| off | type | meaning | evidence |
|---|---|---|---|
| +0x94 | ptr | player definition (`plde`) | `FUN_10026410` |
| +0x98 | int | lives, **stored + 0x1524DCEF** | `FUN_10026d50/60`; `10026d9c subis r3,r3,0x1525; addi r31,r3,0x2312` [HIGH] |
| +0x9c | int | next extra-life threshold (plain) | `FUN_10026cc0`, `FUN_10029a10` [HIGH] |
| +0xa0 | int | extra-life step increment (plain) | same [HIGH] |
| +0xac | int | money (coin units, $1 each), **stored + 0xB2CCE** | `FUN_10027610/20`; `10027738 subis r3,r3,0xb; subi r0,r3,0x2cce` [HIGH] |
| +0xb0 | int | score, **stored + 0x05532A3E** | `10029a3c subis r30,r3,0x553; subi r30,r30,0x2a3e` [HIGH] |
| +0xb4 | u8 | score multiplier 1/2/3/4/5/10 | `FUN_10029b20` [HIGH] |
| +0xb8 | int | entity id of the multiplier indicator unit (−1 none) | `FUN_10029fe0` [MED] |
| +0xbd | u8 | cheated this game (set by every console cheat) | raw bl-scan: 16 `bl 0x10029bf0` with r4=1 in `0x10008118–0x100091bc` [MED] |
| +0xc0 | ID | level ID at the last level start (= "sector reached") | `FUN_100269a0` [HIGH] |
| +0xc4 | u8 | player in this game | every function gates on it [HIGH] |
| +0xc6 | u8 | life state (4 = active, 3 = dying) | `FUN_10026c80` [HIGH] |
| +0xd0 | u8 | hit-this-level latch (defence bonus) | player-physics.md §3/§6 [HIGH there] |
| +0xd8 | u8 | coin-bonus tally state 0–8 | `FUN_10027930` [HIGH] |
| +0xdc / +0xe8 | int | tally state timer / per-tick timer | same [MED] |
| +0xe0 | int | tally text alpha 0..32 (32 = invisible) | `FUN_10027630` sets 0x20 [MED] |
| +0xe4 | int | coin value this level | `FUN_10027670` [HIGH] |
| +0xec | char[] | tally text | `FUN_10055390` calls [HIGH] |
| +0x1ec / +0x1f0 / +0x1f4 | int | money at tally start / bonus remaining / step | `10027740..100277ec` [HIGH] |
| +0x1f8 | int | tally text y offset for the 2nd counter | `FUN_10027670` flli 181 [MED] |

### 1.2 Game struct `G` (`*(r2−0x7360)` = `PTR_DAT_100defd0`)
| off | type | meaning | evidence |
|---|---|---|---|
| +0x00/+0x04 | ptr | players 0/1 | `FUN_100051a0` |
| +0x08 | u8 | game running | `FUN_100051a0` loop |
| +0x09 | u8 | level complete (tallies done) → `FUN_10007170` advances | `FUN_10006b50` |
| +0x0b | u8 | this level ended at 100 % ground accuracy | `10007388 stb r0,0xb(r31)` [HIGH] |
| +0x0c | u8 | accuracy reward armed for this level (copied from +0x0b at level start) | `FUN_100064d0`: `G[0xc]=0; if G[0xb] {G[0xb]=0; G[0xc]=1}` [MED] |
| +0x0d | u8 | all levels completed (finale) | `FUN_10006b50` §8 [MED] |
| +0x10 | int | levels started this game | `FUN_100064d0` `+0x10 += 1` [MED] |
| +0x14 | int | current sector number (1-based level index) | `FUN_10005cd0`; written `G+0x14 = iVar5` in `FUN_100064d0` [HIGH] |
| +0x39 | u8 | level-end point reached | `FUN_10006b50` [MED] |
| +0x3c | int | ground-accuracy units created | `100061e4 lwz r3,0x3c(r4); addi; stw` [HIGH] |
| +0x40 | int | ground-accuracy units destroyed | `10006204 lwz r3,0x40(r4)…` [HIGH] |
| +0x44 | int | levels finished at exactly 100 % this game | `FUN_100075e0` case 4 [HIGH] |
| +0x48 | u8 | accuracy tally state 0–10 | jump table `r2−0x2660` = `0x100e3cd0` (11 entries) [HIGH] |
| +0x4c/+0x54 | int | tally state timer / per-tick timer | [HIGH] |
| +0x50 | int | tally alpha | [MED] |
| +0x58/+0x5c | int | accuracy bonus remaining / step | `100074ec..1000758c` [HIGH] |
| +0x60 | char[] | tally text | [HIGH] |
| +0x160 | int | accuracy percent (truncated) | `1000735c stw r0,0x160(r31)` [HIGH] |
| +0x164/+0x168 | u8/int | mission-bonus flag / payments made | `10007b80`, `10007c84` [HIGH] |
| +0x174 | int | SCORE cheat uses (max 2) | `10008e60 lwz r3,0x174(r31); cmpwi r3,0x2` [HIGH] |

## 2. Obfuscation transforms [HIGH]
Stored = plain + K, decode = stored − K, 32-bit wrap, no other mixing:
- score `K = 0x05532A3E` (89 336 382): `FUN_100299f0` get, `FUN_10029a00` set, `FUN_10029a10`
  (`10029a3c subis 0x553; 10029a40 subi 0x2a3e` … `10029af0 addis r3,r30,0x553; addi r0,r3,0x2a3e`).
- money `K = 0xB2CCE` (732 366): `FUN_10027610/20`.
- lives `K = 0x1524DCEF` (354 737 391): `FUN_10026d50/60`.
Note the coin-tally decrement `*(+0xac) -= 1` (`10027c78..80`) operates on the stored value,
which is the same as decrementing plain money by 1. (Prefs-file score obfuscation
`± 0x024A8903` is engine-loop.md §10.)

## 3. Add score and extra lives

### 3.1 `FUN_10029a10 @ 10029a10 (player, pts, raw)` — the only score adder [HIGH]
Raw bl-scan: 7 call sites — `0x100061bc` (`FUN_10006190`, kill points), `0x10007a34` (accuracy
tally, r5=0), `0x10007cc0` (mission bonus, **r5=1**), `0x1000827c` (console, 9000, r5=0),
`0x10008ed4` (SCORE cheat, 10000, r5=0), `0x10027c90` (coin tally, r5=0), `0x10029030` (defence
bonus, r5=0). The score is otherwise only ever **set to 0** (`FUN_10029a00` has one caller
`FUN_100299c0`, called from the constructor and `FUN_10026410` player setup).
```
if !in_game: return
add  = raw ? pts : pts * multiplier(+0xb4)          ; 10029a44..58 (mullw)
new  = score + add
if pts > 0:                                          ; 10029a5c cmpwi r4,0; ble
    if !raw:
        if new > threshold(+0x9c):                   ; 10029a70 cmpw r30,r0; ble  (strict >)
            AddLife(player, fx=1)                    ; FUN_10026d70
            threshold += plde.life_AdditionalRequiredScore (+0x6c)
            threshold += step(+0xa0)
            step      += int(flli 182 Player_ExtraLifeScoreAdjustment = 10000)
    else:
        step = new + int(flli 182)                   ; 10029ad0..aec
score = new
```
- At most one life per call: if one add crosses two thresholds, the second life comes with the
  next positive non-raw add (the score is still above the advanced threshold).
- Negative `pts` (Hospital `score_INT −10000`) is multiplied too when `raw == 0` and never touches
  lives; the score is not clamped at 0. [HIGH — listing]
- The `raw` branch is reached only by the mission bonus (§6.4); it awards no life and replaces the
  step with `score + 10000` (so the threshold after the next crossing jumps by ≥ the score). [HIGH]

### 3.2 Initial values — closes the threshold part of NOT-RESOLVED #26 [HIGH]
`FUN_10026cc0 @ 10026cc0 (player, fullStart)`, called only from `FUN_10026410` (raw bl-scan
`0x10026850`, `0x10026874`):
```
lives     = fullStart ? plde.life_NumInitial(+0x64) : 1      ; 10026ce8..10026d00
threshold = plde.life_InitialRequiredScore (+0x68)            ; 10026d10 lwz r3,0x68(r3); stw 0x9c
step      = 0                                                 ; 10026d18 stw r0,0xa0(r31)
```
`fullStart = (startSector == 1)`: `10026838 subfic r0,r30,0x1; cntlzw r0,r0; rlwinm r4,r0,0x1b,5,31`
(r30 = `FUN_10026410` param 5 = 1-based start level from `FUN_100051a0`). plde offsets from the
parser `FUN_10039e70` raw listing: `1003a37c addi r6,r30,0x60` (`#life_MaxNum_INT`, key string
r31+0x416 = 0x100ec4b6), `…0x64` NumInitial, `…0x68` InitialRequiredScore, `…0x6c`
AdditionalRequiredScore, `1003a3dc addi r6,r30,0x70` `#life_Spawn_ID`. Player 1/2 values: 10 /
3 / 10000 / 30000 / `noel`.

Threshold sequence (single player, no mission bonus): life when score **exceeds** 10 000,
40 000, 80 000, 130 000, 190 000, 260 000, … (increments 30 000, 40 000, 50 000, …: increment n
= 30 000 + 10 000·(n−1)). Matches the guide's "first 10,000 points, then 30,000 … then another
40,000". [HIGH]

### 3.3 `FUN_10026d70 @ 10026d70 (player, fx)` add one life [HIGH]
`new = lives+1; if life_MaxNum > 0 && new > life_MaxNum: new = life_MaxNum`
(`10026da0 cmpwi r0,0; ble; cmpw r31,r0; ble; or r31,r0,r0`); if `new > lives`: spawn
`life_Spawn_ID` ('noel', Notice – Extra Life) at the ship when `fx` and the ID is not none, store
`new`. At the cap (10) a threshold crossing still advances threshold/step but adds nothing.
Callers: `FUN_10029a10`, the `exli` pickup (`FUN_10037580`), console 'life' cheats
(`0x10008108`, `0x10008190`, `0x10008aa8`).

## 4. Score multiplier
- Step `FUN_10029b20 @ 10029b20` (only caller `FUN_10037580` 'mult' pickup, plus cheats
  `0x100085fc`, `0x100091ac`): state 4 only; jump table `r2+0x3090` = `0x100e93c0` decoded from the
  data image: case1→2, 2→3, 3→4, 4→5, 5→10, 0/6–10 → no change (so ×10 is the cap). Each step
  calls `FUN_10029fe0`. [HIGH — table bytes + listing `10029b58..10029bb0`]
- `FUN_10029fe0 @ 10029fe0` indicator: if state 4, map 2/3/4/5/10 → PermObjectID 35..39
  (`mux2 mux3 mux4 mux5 muxx`; table `0x100e93ec`), kill the previous indicator
  (`FUN_10034de0(+0xb8)`), spawn the new one at the ship with owner = player index, store its id
  in +0xb8. Also called from `FUN_10029cc0` (ship becomes active) so the indicator reappears after
  entry. [HIGH for the map; MED for the spawn record fields]
- Reset to ×1: player setup (`FUN_10026410` → `FUN_10029fd0`) and death (`FUN_10027e50`:
  `if multiplier != 1 {FUN_10034de0(+0xb8); FUN_10029fd0}`). Not reset at level start
  (`FUN_100269a0` does not call it) → the multiplier survives levels until the ship dies. [HIGH]
- Applies to every `raw == 0` add: kills, defence bonus, accuracy tally, coin tally, SCORE cheat,
  and negative kill scores. [HIGH]

## 5. Money

### 5.1 Pickups — `FUN_10037580 @ 10037580 (player, entity)` [HIGH for every case — ⚑ corrected (review wave 1, 2026-10-03) #M9: was "HIGH for coin/exli/mult"; `shie` and `spec` confirmed in NR 3]
Called from the entity update `FUN_10033850` on player contact; switch on unit
`pickup_Type_ID` (+0x4d4): `coin` → if `pickup_Value_INT` (+0x4dc) ≠ 0: `FUN_100275b0(player,
value)` (money += value; `10037660 lwz r4,0x4dc(r6); cmpwi r4,0; beq; bl 0x100275b0`) and the
pickup is consumed; `exli` → `FUN_10026d70(p,1)`; `mult` → `FUN_10029b20`; `shie` → shields
+= `pickup_Value` (`FUN_10027490`, cap: player reader); `spec` → nothing; any other type (`none` in the data) returns 1 so the contacted entity is
 destroyed via `FUN_10016300` (impact — damage reader); types `grnd`/`air ` return 0 while the
 player is invulnerable (no unit def uses them).
Coin units (unde data): `calg` Large Gold 50, `cals` Large Silver 10, `casg` Small Gold 5,
`cass` Small Silver 1 = PermObjectID 2/3/4/5 `MoneyUnit_50/10/5/1`.

### 5.2 Money lifetime [HIGH]
- Set to 0 at construction, player setup and **every level start** (`FUN_100269a0` →
  `FUN_10027580` at `0x10026a3c`). Money therefore never carries between levels; it is cashed by
  the coin bonus (§6.5) or lost.
- ⚑ corrected role: `FUN_10027e50 @ 10027e50` is the **ship-destroyed** handler (callers
  `FUN_10026ee0` overload, `FUN_10027100` hit, console `0x10008380`), not "coin unit selection":
  spawns `death_Spawn_ID`, then spills the held money as coins at the ship, greedy:
  `while m ≥ 50: spawn O2 ($50)`, `≥10: O3`, `≥5: O4`, `≥1: O5`
  (`1002802c subi r26,r26,0x32 … 1002804c cmpwi r26,0x32`, `0xa`, `0x5`, `0x1`), money = 0
  (`10028100 addi r0,r3,0x2cce; stw 0xac`), state 3, multiplier reset (§4). The spilled coins are
  normal pickups and can be re-collected (by either player). [HIGH]

## 6. End-of-level sequence (inside `FUN_10006b50`, per frame)
Order per frame (decompile, MED for order): (a) `FUN_10028170` for both players with
`param_7 = G+0x39` → defence-bonus payout (§6.1); (b) if `FUN_10010000()` (level-end scroll point
reached): `G+0x39 = 1`; first time: spawn `Notice_LevelEnd` (O22 `nole`) — or
`Notice_AllLevelsCompleted` (O23 `noal`) when the finale condition holds (§8) — at
(flli54·0.5, flli55·0.5) = (208, 240); make both players invulnerable (`FUN_10027de0(p,1,0)`);
`FUN_100072c0(frame)` (accuracy setup). Later frames: `FUN_100075e0(frame)` until it returns 1;
then for each in-game player whose counter has not started, `FUN_10027670` (coin setup), then
`FUN_10027930` each frame; when all report done → `G+9 = 1` (next level via `FUN_10007170`).

### 6.1 Defence ("Shield") bonus payout [HIGH]
`10028f3c..10029030` (in `FUN_10028170`): when `G+0x39` and `+0xd0 == 0`: `+0xd0 = 1`; spawn
`active_DefenceBonusObject_ID` (plde +0xd0, `nodb`) at the ship; then
`FUN_10029a10(p, int(flli 184 Player_DefenceBonusBaseAmount = 2000) × sector, raw 0)`
(`10029000 bl 0x10005cd0; li r3,0xb8; bl 0x10020250; fctiwz; mullw r4,r0,r18; li r5,0`).
So **defence bonus = 2000 × sector × multiplier**, once per level, only if the ship took no shield
damage this level (latch set on any hit with dmg > 0 — player-physics.md §3).

### 6.2 Ground-accuracy count mechanics [HIGH]
- Created: `FUN_10035cd0` (create entity) — `100360d8 lbz r0,0x134(r31); beq; bl 0x100061e0`
  (unit `includeInGroundAccuracyCount` +0x134) → `G+0x3c += 1` (also a debug counter
  `*(r2−0x6118)` += 1).
- Destroyed: `FUN_10016300` — `10016508 lbz r0,0x134(r30); beq; bl 0x10006200` → `G+0x40 += 1`.
  `FUN_10016300` is the common destroy routine for **every destroy path** (player damage via
  `FUN_10014f10`, rule `Destroy` actions and range/hit transitions in `FUN_10033850`, owner/group
  destruction in `FUN_10036120`/`FUN_10036610`; 9 raw call sites), so a counted unit destroyed by
  scripted self-destruction also counts as "hit". [HIGH for the increments; MED that non-player
  destroy paths reach counted units in practice]
- Reset: `FUN_10007150` (both counts = 0) at game start and every level start.
- Data: 36 unit defs have the flag (grep of decoded `unde`), Extra-Life bunkers do not (guide).
- Debug label "Ground Accuracy" on counted units (`FUN_100345f0`, flag `DAT_100e021c`); console
  `DISPLAYACCURACY` (`0x10008860`) prints `"%i / %i  -  %i%%"` = destroyed / created / percent
  or "No Targets Yet". [MED]

### 6.3 Accuracy tier — `FUN_100072c0 @ 100072c0 (frame)` [HIGH]
```
pct = created > 0 ? (float)((float)destroyed / (float)created) * 100.0   ; 10007324 fsubs, 10007334 fdivs, 10007338 fmul (double 100.0 @0x100d6364), frsp
                  : 0.0                                                   ; 10007344 lwz r3,-0x73b0(r2) -> 0x100d6354 = 0.0f
G+0x160 = trunc(pct)
g = int(flli 188 TierPercentageGap = 5)
pct >= 100        -> tier = flli 189 (5000), G+0x0b = 1     ; fcmpo + cror eq,gt,eq => >=
pct >= 100 - g    -> flli 190 (2000)
pct >= 100 - 2g   -> flli 191 (1000)
pct >= 100 - 3g   -> flli 192 (500)
pct >= 100 - 4g   -> flli 193 (250)
else              -> flli 194 (0)
bonus(G+0x58) = tier * sector(G+0x14)                         ; 100074f4 mullw
step(G+0x5c)  = bonus < 1 ? 0 : max(trunc((float)bonus * 0.02f), int(flli 199 = 100))
```
(`flli 200 = 0.02` single: `10007530 fmuls f31,f31,f1`; `10007568 fcmpo; bge` keeps the larger.)
Comparisons use the untruncated float, e.g. 94.99 % is tier 3.

### 6.4 Accuracy tally — `FUN_100075e0 @ 100075e0 (frame)` [HIGH for 6, 8, 10; MED for 1–5, 7, 9]
Every wait is `timer + N < frame` (strict) → lasts N+1 frames. Sounds: gaso 20 `MoneyCount`
`moco`, 21 `nobo`, 22 `GroundAccuracyCount_MaxBonus` `acbo`, 23 `…_MissionBonus` `miac`.
| state | action | exit |
|---|---|---|
| 1 | wait flli 195 (60) — **flli 196 (1200) when G+0xd (finale)** | →2, sound 20 |
| 2 | fade in (alpha −= flli 203 per frame) | after flli 197 (20) →3; text "Ground Accuracy:   N%" |
| 3 | | after 197 →4; text + "   Bonus:  " |
| 4 | | after 197 →5; if pct int == 100: `G+0x44 += 1`, sound 22; elif bonus 0: sound 21; else 20 |
| 5 | text "…Bonus:  None!" (bonus 0) or "…Bonus:  M" | after 197 →6 |
| 6 | every 3rd frame (flli 198 = 2): remaining −= step (clamped ≥ 0); `FUN_10029a10(p, step, 0)` for both players; sound 20 | remaining < 1 →7 |
| 7 | wait flli 201 (20) | →8 |
| 8 | fade out (alpha += flli 204, cap 32); after flli 202 (20): if `G+0x44 == numLevels` (`10007b68 bl 0x10011de0; lwz r0,0x44(r31); cmpw r0,r3`) → mission bonus: flag, count 0, text pgsl 10 "All Mission Targets Destroyed!!!", sound 23 at volume 100 →9 | else **done** |
| 9 | flash on, wait flli 206 (4) | →10, text off |
| 10 | if flag clear → done; else after flli 207 (3): count += 1; `FUN_10029a10(p, int(flli 205 = 100000), raw 1)` for both players (`10007c88..10007cc0`); if count < flli 208 (10) →9 (text on) else flag = 0 | |
Consequences [HIGH]:
- The full step is paid every tick while only the remainder is clamped → **overshoot** when
  `bonus` is not a multiple of `step`: tier 250 on odd sectors (bonus 250, 750, …, 2750, step
  100) pays 300, 800, …, 2800 (× multiplier). All other tier×sector products are exact
  (checked numerically for sectors 1–12 with float32 arithmetic).
- **Mission bonus = 10 × 100 000 = 1 000 000** per player, raw (no multiplier, never an extra
  life, overwrites the life step, §3.1), only when every level of the game ended at exactly 100 %
  — reachable only in a run started at sector 1 (`G+0x44` reset only at game start in
  `FUN_100051a0`). ⚑ corrected waves-and-enemies.md §7 ("100 % = MissionBonus 100000 + miac"):
  a single 100 % level gives tier 1 (5000 × sector) + sound `acbo` + the reward flag (§7).

### 6.5 Coin bonus — `FUN_10027670 @ 10027670 (player, frame, stacked)` + `FUN_10027930` [HIGH]
Setup (`100276c8..100277ec`):
```
coinValue(+0xe4) = int(flli 170 AdjustBonusFactorForLevel) == 0
                   ? int(flli 171 BonusFactorPerCoinHeld = 100)
                   : sector * int(flli 171)               ; flli 170 = 0 in the data -> 100
money0(+0x1ec)   = money
bonus(+0x1f0)    = money0 * coinValue
step(+0x1f4)     = bonus < 1 ? 0 : max(trunc((float)bonus * 0.02f), int(flli 199 = 100))
```
then spawns `active_MoneyCounterSpawn_ID` (plde +0xc4, `p1mc`/`p2mc`) at (flli 179, flli 180) =
(105, 248), y += flli 181 (70) and `+0x1f8 = 70` when `stacked` (the second player's counter).
For whole-coin money the step is exactly `max(2·money, 100)` (float32 check, money 1–199 999):
**≥ 50 coins → 50 ticks of 2·money; < 50 coins → `money` ticks of 100** — the sum is always
exactly `bonus`. Tally `FUN_10027930` (states, all waits strict):
1 wait flli 172 (10) →2 (sound 20); 2 fade in (alpha −= flli 177) for flli 173 (20) →3 text
"Coin Bonus:   <money0>"; 3 →4 adds "  x  <coinValue>"; 4 →5 adds "  =  <bonus>" (sound 21 if
bonus < 1 else 20); 5 →6; 6 every 3rd frame (flli 176 = 2): money −= 1, `FUN_10029a10(p, step,
0)` (**× multiplier**, may award lives), remaining −= step (not clamped), sound 20, text update;
when remaining < 1 →7; 7 wait flli 174 (30) →8; 8 wait flli 175 (20) → done. The money −1 per
tick has no lasting effect (money is zeroed at the next level start). Coin bonus =
**money × 100 × multiplier**, not sector-scaled in 1.0.6 (flli 170 = 0).

## 7. Random-bonus selection — `FUN_10016300 @ 10016300` (selection only) [HIGH]
When the destroyed unit has `destructReleaseRandomBonus` (+0x4b4): `r = RandomRange(0,100)`
(`10016528 li r3,0; li r4,0x64; bl 0x10046580` → 101 equiprobable values 0..100, one LCG draw;
engine-loop.md §9). Every test is `r < int(flli)` (`cmpw r28,r0; bge next`):
| r | object | spawns (unde data) | chance |
|---|---|---|---|
| < 70 (F209) | O25 `rb01` — but if `G+0x0c` (reward armed) and r < F218 (10): O30 `rb06` and disarm (`FUN_10005d10`) | `cass` $1 / (`pimu` multiplier) | 70/101 |
| 70–77 (F210 78) | O26 `rb02` | `cals` $10 | 8/101 |
| 78–81 (F211 82) | O27 `rb03` | `casg` $5 | 4/101 |
| 82–83 (F212 84) | O28 `rb04` | `calg` $50 | 2/101 |
| 84–86 (F213 87) | O29 `rb05` | `cass` + `cals` | 3/101 |
| 87–90 (F214 91) | O30 `rb06` | `pimu` multiplier step | 4/101 |
| 91–94 (F215 95) | O31 `rb07` | `pish` shields | 4/101 |
| 95–97 (F216 98) | O32 `rb08` | `piel` extra life | 3/101 |
| 98–100 | if sector < F219 (3): O32 `rb08` (`1001675c cmpw r3,r27; bge`); else r < F217 (100): O33 `rb09`, else O34 `rb10` | `rben` (Random Bonus – Enemy: grows, retreats, hunts — "Shenobi Assault Mine" in the guide) / nothing (rb10 "Not Used. Delete.", 0 spawn sets) | 3/101 |
The "GroundAccuracyReward": a 100 % level arms `G+0x0c` for the **next level only**; the first
random bonus that rolls r < 10 there becomes a multiplier pickup instead of a $1 coin, once.
The spawned `rbNN` unit is placed at the destroyed entity with its owner/heading fields (record
copied from `uRam100e64bc..`; MED). Units with the flag: Bonus Stations (`bsat bsgr bsde`), Caps
(`came cara car2 casi`) among the counted ground units.

## 8. Finale — NOT-RESOLVED #27 [MED]
1. Condition (`FUN_10006b50`, at the level-end point): `G+0x14 == numLevels && G+0x10 ==
   numLevels` → `G+0x0d = 1`. `G+0x10` counts levels started this game, so it holds only when
   all 12 sectors were played from sector 1 (guide: "you must have started from Mariner Valley").
   Otherwise finishing sector 12 shows the ordinary `nole` notice and the game simply ends when
   `FUN_100064d0` finds no level 13 (`G+0x18 = 'none'`, `G+8 = 0`).
2. Spawn `Notice_AllLevelsCompleted` O23 (`noal`) instead of O22.
3. The accuracy tally waits 1200 frames (flli 196, 40 s at 30 fps) instead of 60 while the
   `noal` unit runs its states (data: Flash On/Off with entry sound `acbo`; "Spawn Game
   Completion" spawns `12gc` "Level 12 – Game Completion" — flags `miof` and explosions `aieg`;
   "Scale In" plays **`leen`**). [LOW — data reading only]
4. Accuracy tally, then the mission bonus if all levels were 100 % (§6.4), then the coin bonus.
5. `G+9` → `FUN_10007170` → `FUN_100064d0` finds no next level → game over; result byte
   `[0x14] = G+0xd` makes `FUN_100234d0` store highest sector = 12 (§9.2).
`EndGameFinale` (gaso 6, ID `leen`): raw bl-scan of all 61 `bl 0x10020210` sites finds **no
`li r3,0x6`** — the permanent sound index is never played by code; the same ID is played by the
`noal` unit data (and gaso 10 `Registered`, also `leen`, by `0x10023f7c`). [HIGH for "no code
consumer"]

## 9. High scores and the start-sector rules

### 9.1 `FUN_10021470 @ 10021470 (score)` = score > 15th high score [HIGH]
Copies prefs (`FUN_10004c30`), reads offset 0x1298 (`10021490 lwz r0,0x12d0(r1)`, buffer at
r1+0x38 → prefs 0x1260 + 14·4) and returns the branch-free idiom
`(((p^s)>>1) − ((p^s)&p)) >>> 31` (`srawi; and; subf; rlwinm …,1,31,31`) — brute-forced over 10⁵
random pairs: equals signed `p > s`. Default 15th score 1000.

### 9.2 Session gating — `FUN_100234d0` (decompile) [MED]
After `FUN_100051a0` returns its 0x18-byte result (flags [0..1] player present, +4/+8 scores,
+0xc/+0x10 level IDs at last level start, [0x14] = G+0xd, [0x15] = any player cheated (+0xbd),
[0x16] = unregistered-limit hit):
- `startedLater = chosenSector > 1` (from `FUN_1002e310`).
- Highest-sector pref (int pref 3): only in a normal (non-replay) session, `DAT_100e01b8 == 0`
  (unidentified), no cheat, and `!startedLater`:
  `best = max over present players with score > 0 of sectorIndex(levelID)`; if not finale
  `best −= 1`; `best = max(best,1)`; `if pref3 < best: pref3 = best`. I.e. the pref holds the
  highest sector **fully completed** in a run started at sector 1 (guide wording identical).
- High-score entry `FUN_100214c0` only with the same gates plus some present player's score
  passing `FUN_10021470`.
- `FUN_100214c0 @ 100214c0`: for each present player find the first slot i (0..14) with
  `table[i] < score` (strict, so ties rank below), adjust when both qualify (the lower-placed index
  shifts down by one, dropped past 14), shift the 15-row tables (score, 21-byte name, 32-byte
  sector name) down, insert score + player name (prefs 0x1233/0x1248) + level name of the last
  level reached, then `FUN_10021bd0(player, slot, prefs, 1)` (scores screen / name edit). [MED]

### 9.3 Start-sector consequences (all found code paths) [HIGH unless noted]
- Lives: `life_NumInitial` (3) only when start sector = 1, else **1** (§3.2).
- Score 0, money 0, multiplier 1 for every start sector (setters' only callers, raw bl-scan).
- No high-score entry and no pref update when start > 1 (§9.2, MED).
- No finale and no mission bonus unless started at 1 (§6.4, §8).
- Weapons: `FUN_1003ade0` (weapon handler init) receives the start level; `FUN_1003cdb0(level)`
  picks the default air weapon whose `minimumLevelAvailable ≤ level ≤ maximumLevelAvailable`
  ("No suitable Air Weapon for Level %i") — the only start-sector-dependent *gain*. [MED; weapon
  reader owns the rule]

## 10. Level selection screen (0x1002e310–0x10031400)

### 10.1 Unlock rule — `FUN_1002efb0 @ 1002efb0 (list, sector, middle, msg, outID)` [MED]
Fills the three previews (middle = chosen sector, left/right = neighbours with wrap 1↔numLevels).
Per preview: `+0x2c4 = reachable`, `+0x2c5 = registration required`:
registered (`FUN_10010f90`) → `reachable = sector ≤ pref3` (signed-compare idiom); unregistered →
`sector > FUN_10011b00()` (demo limit) ⇒ `+0x2c5 = 1`, else `reachable = sector ≤ pref3`. The
middle preview is copied to the global at `PTR_DAT_100df3ac` (+0x2c4/+0x2c5 included) and its level
ID returned. There is **no price**: selecting costs nothing beyond §9.3 (`COST` is a draw type —
function-roles.md fix-pass note, confirmed in `FUN_1002f7a0` `local_1f0 = 0x434f5354` hover rect).

### 10.2 Consumers of `+0x2c4` [MED]
`FUN_1002e310`: accept-button sprite frame flli 97 vs 98 (`FUN_10020250(0x61/0x62)`); on accept:
reachable → sound 12 `LevelSelectChoose`, flash `FUN_1002fe40(1)`, exit after the flash with the
level ID; unreachable → sound 14 `LevelSelectFailure`, message pgsl 4 "Sector Not Reached" or 5
"Registration Required", fail flash `FUN_1002fe40(2)`. `FUN_1002f3c0`: name text style 0x18/0x19
and number style 0x17/0x16 (`"%0.2i"` sector number). Input: 7-byte player-0 input
(engine-loop.md §8): byte 3 (left) or click on button R18 → previous sector, byte 1 (right) or R20
→ next (wrap), sound 13; any of bytes 4–6 or click on R19 → accept. Esc → returns `'none'`.

### 10.3 NOT-RESOLVED #28 "Starting Bonus" — resolved as **unimplemented** [HIGH]
pgsl index 3 "  -  Starting Bonus $" and 6 "  -  No Starting Bonus" (also 1 "Choose a starting
Sector…", 2 "Press any button to start", 8 "_") have no reader: the raw bl-scan of all 37
`bl 0x10020260` sites gives r3 ∈ {0,4,5,7,9–18,21–23,33–35} (the one non-`li` site `0x10030480`
has r3 = 0 from `1003042c li r3,0x0`), and the list base `*(r2−0x712c)` is loaded only at
`0x1001fe6c` (loader) and `0x10020260` (accessor). No score or money is added at game start:
score/money/lives are only initialised (§9.3) and every score add is one of the 7
`FUN_10029a10` sites (§3.1), none in the start path. The strings are leftovers of a cut feature.

### 10.4 Function census of the range
| function | lines | role | label |
|---|---|---|---|
| `FUN_1002e310` | 407 | level-select screen loop (3 previews, input, accept/fail, returns level ID, `*out = sector`) | MED (read) |
| `FUN_1002ef10` | 18 | message timeout: after flli 43 frames fade the message and restore the level name | MED (read) |
| `FUN_1002efb0` | 176 | fill 3 previews + unlock flags (§10.1) | MED (read) |
| `FUN_1002f3c0` | 208 | draw the screen: 3 buttons via `FUN_1002f7a0`, name, `%0.2i` number, 3 button rects R18–R20 hilite | MED (read) |
| `FUN_1002f7a0` | 242 | draw one preview button; mouse-over `COST` rect; zoom/blend of the selected one | MED (read; existing row) |
| `FUN_1002fc60` | 10 | list item 1 (middle preview) | MED (read) |
| `FUN_1002fc90` | 21 | reset selection flash | MED (read) |
| `FUN_1002fcc0` | 59 | selection flash animation (accept flli 44/45, fail 46/47) | MED (existing; read) |
| `FUN_1002fe40` | 47 | start flash: 0 reset, 1 accept (text style 0x1b), 2 fail (0x1c) | MED (read) |
| `FUN_1002ff30` | 36 | mouse-in-rect test for a button + rollover sound gaso 11 | MED (read) |
| `FUN_10030020` | 36 | static initialiser of level-select globals | HIGH (⚑ corrected (review wave 3, 2026-10-06) #L: was "LOW (read)"; listing `10030020..1003012c`, static-init-audit.md §3 table A (listing + interpreter); function-roles.md row) |
| `FUN_10030190`, `FUN_10030210` | | frame controller construct / start | existing, not re-read |
| `FUN_100301d0` | 12 | frame-controller destructor (free if flag > 0) | MED (⚑ corrected (review wave 3, 2026-10-06) #L: was "LOW (read)"; = timing-frame.md §1 / function-roles.md (MED)) |
| `FUN_100302b0` | 10 | frame-controller end session → `FUN_10048e30` | MED (⚑ corrected (review wave 3, 2026-10-06) #L: was "LOW (read)"; = timing-frame.md §1 / function-roles.md (MED)) |
| `FUN_100302e0` | 15 | between-level reset: messages, console, FPS monitor init, speed divider | MED (read) |
| `FUN_10030350` | 9 | frame counter getter (+8) | MED (read) |
| `FUN_10030360`–`FUN_10030bc0` | | frame loop rows (engine-loop.md) | existing, not re-read |
| `FUN_10030570` | 18 | end-frame wrapper (bank: HIGH; callers `FUN_100051a0`, `FUN_1002e310`) | not re-read ⚑ corrected (review wave 1, 2026-10-03) #M7 |
| `FUN_100305e0` | 18 | FPS monitor init (bank: MED; callers `FUN_10030210`, `FUN_100302e0`) | not re-read ⚑ corrected (review wave 1, 2026-10-03) #M7 |
| `FUN_10030640` | 48 | FPS monitor + auto interlace (bank: MED; caller `FUN_10030570`) | not re-read ⚑ corrected (review wave 1, 2026-10-03) #M7 |
| `FUN_10030790` | 12 | reset speed divider (bank: HIGH; callers `FUN_10030210`, `FUN_100302e0`) | not re-read ⚑ corrected (review wave 1, 2026-10-03) #M7 |
| `FUN_100307b0` | 9 | tick-this-frame flag (bank: HIGH, disasm; callers `FUN_10030360`, `FUN_10030570`) | not re-read ⚑ corrected (review wave 1, 2026-10-03) #M7 |
| `FUN_100307c0` | 31 | Esc quit (bank: HIGH, disasm; callers `FUN_10030360`, `FUN_10030570`) | not re-read ⚑ corrected (review wave 1, 2026-10-03) #M7 |
| `FUN_10030870` | 22 | pause handling (bank: MED; caller `FUN_10030570`) | not re-read ⚑ corrected (review wave 1, 2026-10-03) #M7 |
| `FUN_10030910` | 95 | −/= volume, F6 interlace keys (bank: HIGH; caller `FUN_10030360`) — the heaviest function in this range, owned by a future timing/frame reader | not re-read ⚑ corrected (review wave 1, 2026-10-03) #M7 |
| `FUN_10030900` | 9 | frame-controller byte 0 getter (used as "redraw" gate in `FUN_1002e310`) | MED (⚑ corrected (review wave 3, 2026-10-06) #L: was "LOW (read)"; = paused-flag getter, timing-frame.md §1 / function-roles.md (MED)) |
| `FUN_10030df0` | 25 | zero-init of a 0x35-byte struct (score-bar state?) | HIGH (⚑ corrected (review wave 3, 2026-10-06) #L: was "zero-init of a 0x35-byte struct (score-bar state?)" LOW (read); = frame-controller state reset, zero +0…+0x34, listing stores `10030e0c…10030e54` (timing-frame.md §1, function-roles.md)) |
| `FUN_10030e70` | 43 | static initialiser of score-bar globals (writes `0x100eb03c`/`0x100eb184`/`0x100eb1d8`) — ⚑ caution ⚑ corrected (review wave 2, 2026-10-03) #C1: those templates' data-image bytes are pre-initialiser values (INDEX #56) | HIGH (⚑ corrected (review wave 3, 2026-10-06) #L: was "LOW (read)"; TU init, static-init-audit.md §3 table A (listing + interpreter); function-roles.md row) |
| `FUN_10030f40` | 135 | score bar rects | existing, not re-read |
| `FUN_100313b0` | 13 | release "Score Bar" resource group, clear `DAT_100e0200` | HIGH (⚑ corrected (review wave 3, 2026-10-06) #L: was "LOW (read)"; gameplay-leftovers.md §4.3) |

## 11. Console cheats that touch scoring (player-facing per the guide) [HIGH — listings]
All refuse during a film ("Not During a Film, Buddy!"), need byte pref 11 (cheats enabled), and
set +0xbd (§1.1) on each active player: `accuracy` (`0x10008b80`) sets created = destroyed = 100
("Ground Accuracy 100%", sound 22); `score` (`0x10008df0`) `FUN_10029a10(p, 10000, 0)` — at most 2
per game (`G+0x174`), else "I Think Not, Young Kitty!"; `funds` (`0x10008c90`) money += 20
(`10008d6c li r4,0x14`); `ALLLEVELS` (`0x10008930`) pref3 = numLevels ("Access All Areas ON").
⚑ corrected (wave 2, 2026-10-03): was ALLLEVELS listed with the cheats that refuse during a film, need pref 11 and set
+0xbd — it does none of these and is a debug-only command that `FUN_1002d080` never registers in
1.0.6, so it is unreachable — see messages-notices-console.md §5.5.

## Worked example
Sector 1, one player, multiplier ×1, score 0 at level start, the ship took a hit this level.
The player destroys 10 of the 12 Swivel Guns (`swgu`, `score_INT 500`,
`includeInGroundAccuracyCount TRUE`) and collects 3 × `calg` ($50) and 2 × `cals` ($10).
1. Kills: `FUN_10006190` → `FUN_10029a10(p, 500, 0)` ×10 → score 5000 (< threshold 10 000).
   Counts: `G+0x3c = 12` (at creation), `G+0x40 = 10`. Money: `FUN_100275b0` → 170.
2. Level end: `+0xd0 = 1` (hit) → no defence bonus. (Unhit: +2000 × 1 here.)
3. Accuracy: pct = (float)(10.0f/12.0f) × 100.0 = 83.33333 → `G+0x160 = 83`; 83.3 < 85 and
   ≥ 80 → flli 193 = 250 → bonus = 250 × sector 1 = **250**; step = max(trunc(250 × 0.02f) = 5,
   100) = 100. Ticks: remaining 250 → 150 → 50 → 0 (clamped) = 3 ticks × 100 = **300 paid**
   (overshoot, §6.4). Score 5300.
4. Coin bonus: coinValue = 100 (flli 170 = 0); bonus = 170 × 100 = **17 000**; step =
   max(trunc(17000 × 0.02f) = 340, 100) = 340 → 50 ticks, one every 3rd frame (150 frames = 5 s at
   the 30-fps limiter). After tick k the score is 5300 + 340k.
5. First extra life: initial threshold = `life_InitialRequiredScore` 10 000, test `score > 10000`:
   5300 + 340k > 10000 ⇒ k = 14 (score 10 060) → lives 3 → 4 (`noel` notice), threshold =
   10 000 + 30 000 + 0 = 40 000, step = 10 000. Final score 22 300; next life above 40 000, then
   80 000.
Variants: unhit → score 7000 after step 2, 7300 after 3, life at coin tick k = 8 (10 020), final
24 300. With multiplier ×2 every non-raw payment doubles: kills reach exactly 10 000 (not
> 10 000, no life yet); the first accuracy tick (+200) gives the life (10 200; threshold 40 000);
accuracy pays 600 → 10 600; coin ticks of 680: second life at k = 44 (40 520); final 44 600.

## NOT RESOLVED (this file)
1. ~~`FUN_100214c0` insertion details were read from the decompile only (two-player index
   adjustment, name/sector string copies); a listing check of the adjust block would make it HIGH.~~ → ⚑ corrected (review wave 3, 2026-10-06) #S: loose-ends-session.md §3.1 (`FUN_100214c0` listing `100214c0..10021940`, simulated) (critic wave 3 §3).
2. ~~`FUN_100234d0` pref-3 update and high-score gate: decompile only (the `best − 1` rule matches
   the guide); listing of `0x100235xx..0x100236f0` would settle it at HIGH. `DAT_100e01b8`
   (an extra gate, likely film/demo playback) not identified.~~ → ⚑ corrected (review wave 3, 2026-10-06) #S: loose-ends-session.md §2.2 (gates after the game, listing `10023640..100238a8`) and §2.3: `DAT_100e01b8` = **quit requested**, not a film/demo gate (#C3; INDEX #48 closed: nothing sets it during play) (critic wave 3 §3, C3).
3. ~~`FUN_10037580` 'shie'/'spec' cases~~ → closed: the switch is not mis-recovered; both are
   compared — `100375f4 lis r4,0x7368; addi r0,r4,0x6965` ('shie') `beq 0x100376ac` → shields +=
   `pickup_Value` (+0x4dc, int→float, `100376d0 bl 0x10027490`); `1003761c lis r3,0x7370; addi
   r0,r3,0x6563` ('spec') `beq 0x100376d8` → nothing (return the default). damage-health-death.md
   §6 had it right. ⚑ corrected (review wave 1, 2026-10-03) #M9
4. Text alpha/fade arithmetic of both tallies (`+0x50`, `+0xe0`) and the money-counter draw
   `FUN_100298c0` were not checked against listings (visual only).
5. ~~The `noal`/`12gc` finale unit chain is data-driven; its state order and the moment the game
   actually ends relative to the 1200-frame wait are not traced (needs the entity state machine,
   waves-and-enemies.md §3, applied to those unit files).~~ → ⚑ corrected (review wave 3, 2026-10-06) #S: loose-ends-session.md §5 (the `noal`/`12gc` finale timeline, §5.3) (critic wave 3 §3).
6. ~~Which non-player destroy paths can hit counted units in shipped levels (accuracy can only rise
   from those) — needs a level/unit census of `Destroy` actions on counted units.~~ → ⚑ corrected (wave 3+4, 2026-10-04) (critic O7):
   none — a counted unit is destroyed only by player damage in 1.0.6 (census of the 36 counted units,
   gameplay-leftovers.md §7.4e).
7. ~~Console handler at `0x1000827c` (`FUN_10029a10(p, 9000, 0)`) and the death call at
   `0x10008380` belong to the `PLAYER` debug command family (strings at r31+0x33a…); not read.~~ → ⚑ corrected (review wave 3, 2026-10-06) #S: messages-notices-console.md §5.5 (the unregistered `PLAYER` debug family; unreachable in 1.0.6) (critic wave 3 §3).

## Role-table rows (for merge)
| `FUN_10029a10` | G_Player.cc | add score: ×multiplier unless raw; strict `> threshold` → 1 life, threshold += AdditionalRequired + step, step += flli 182; raw (mission bonus only) sets step = score + flli 182; score stored + 0x05532A3E | HIGH | listing `10029a10..10029af8`; 7 call sites (raw bl-scan) |
| `FUN_10026cc0` | G_Player.cc | init lives (NumInitial if start sector 1 else 1), threshold = InitialRequiredScore, step 0 | HIGH | listing `10026ce0..10026d18`, `10026838` |
| `FUN_10026d70` | G_Player.cc | add one life capped at life_MaxNum, spawn life_Spawn_ID | HIGH | listing `10026d90..10026dc0` |
| `FUN_10026d50` / `FUN_10026d60` | G_Player.cc | lives get/set (± 0x1524DCEF) | HIGH | listing |
| `FUN_100299f0` / `FUN_10029a00` | G_Player.cc | score get/set (± 0x05532A3E) | HIGH | decompile + `FUN_10029a10` listing |
| `FUN_10027610` / `FUN_10027620` / `FUN_100275b0` | G_Player.cc | money get / set / add (± 0xB2CCE) | HIGH | listing `10027738` |
| `FUN_10037580` | G_EntityGroup.cc | player-contact handler by pickup_Type_ID: coin → money += pickup_Value; exli → life; mult → multiplier step; shie → shields += pickup_Value; spec → nothing; other → 1 (entity destroyed) | HIGH | listing for every case (`100375f4`→`100376ac` shie, `1003761c`→`100376d8` spec); caller `FUN_10033850` — ⚑ corrected (review wave 1, 2026-10-03) #M9: was MED, NR #3 |
| `FUN_10029fe0` | G_Player.cc | spawn multiplier indicator O35–39 for ×2/3/4/5/10, replace previous (+0xb8) | HIGH | jump table `0x100e93ec` + listing |
| ⚑ corrected `FUN_10027e50` | G_Player.cc | ship destroyed: death spawn, spill money as $50/$10/$5/$1 coins (greedy), money 0, state 3, multiplier reset | HIGH | listing `10027f64..10028124`; was "coin unit selection MED" |
| ⚑ corrected `FUN_10027670` | G_Player.cc | coin-bonus setup: coinValue = flli171 (×sector if flli170≠0), bonus = money×coinValue, step = max(trunc(bonus·0.02f),100), spawn money-counter unit | HIGH | listing `100276c8..100277ec`; was MED |
| ⚑ corrected `FUN_10027930` | G_Player.cc | coin-bonus tally state machine (8 states, pays step×multiplier every 3rd frame) | HIGH | listing `10027c70..10027c90` + decompile; was "money counter display MED" |
| `FUN_10027630` | G_Player.cc | reset coin-tally fields | MED | read |
| `FUN_10027db0` | G_Player.cc | coin tally started (+0xd8 ≠ 0) | MED | read |
| `FUN_100298c0` | G_Player.cc | draw ship + coin-tally text while alpha < 32 | MED | read |
| `FUN_100061e0` / `FUN_10006200` | G_Game.cc (span) | ground-accuracy created / destroyed += 1 (G+0x3c / G+0x40) | HIGH | hand-decoded words `100061e4`, `10006204` |
| `FUN_10007150` / `FUN_10007280` | G_Game.cc (span) | reset accuracy counts / reset accuracy tally | MED | read |
| ⚑ corrected `FUN_100072c0` | G_Game.cc (span) | accuracy tier: pct float ≥100/95/90/85/80 → flli189–194 × sector; step max(trunc(b·0.02f),100); sets 100 % flag G+0xb | HIGH | listing `100072c0..100075dc`; was MED |
| ⚑ corrected `FUN_100075e0` | G_Game.cc (span) | accuracy tally (11 states) + mission bonus 10 × flli205 raw when all levels 100 % | HIGH | listing `100079a0..10007d3c`, table `0x100e3cd0`; was "end-of-level accuracy tally MED" |
| `FUN_10005d00` / `FUN_10005d10` | G_Game.cc (span) | accuracy-reward flag G+0xc get / clear | MED | read |
| ⚑ corrected `FUN_10016300` | G_Entity (span) | destroy entity; counts ground accuracy; random-bonus pick r=RandomRange(0,100) vs flli209–219 → O25–34 | HIGH (selection) | listing `10016508..100167b8`; was MED |
| ⚑ corrected `FUN_10021470` | G_Scores (span) | score > 15th high score (signed, strict) | HIGH | listing + brute force; was MED |
| ⚑ corrected `FUN_100214c0` | G_Scores (span) | high-score insertion for 1–2 players, then scores screen edit | MED | read; was LOW "caller" |
| `FUN_1002efb0` | G_LevelSelection.cc | fill 3 level previews; reachable = sector ≤ int pref 3 (unregistered: > demo limit → registration required) | MED | read |
| `FUN_1002f3c0` | G_LevelSelection.cc | draw level-select screen | MED | read |
| `FUN_1002ef10` | G_LevelSelection.cc | level-select message timeout | MED | read |
| `FUN_1002fe40` / `FUN_1002fc90` / `FUN_1002ff30` / `FUN_1002fc60` | G_LevelSelection.cc | flash start / reset / button hit-test + rollover sound / middle preview | MED | read |
| `FUN_100302e0` | ~after G_LevelSelection | between-level frame-controller reset | MED | read |
| `FUN_10030350` | ~after G_LevelSelection | frame counter getter | MED | read |
| `FUN_10030020` / `FUN_10030e70` / `FUN_10030df0` / `FUN_100313b0` | ~after G_LevelSelection | static inits (TU inits) / frame-controller state reset / Score Bar teardown | HIGH | static-init-audit.md §3 table A; listing stores `10030e0c…10030e54` (timing-frame.md §1); gameplay-leftovers.md §4.3 — ⚑ corrected (review wave 3, 2026-10-06) #L: row split; was one LOW row "static inits / struct zero / Score Bar release / destructor / end-session / byte getter" on read |
| `FUN_100301d0` / `FUN_100302b0` / `FUN_10030900` | frame controller | destructor / end session (FlushEvents) / paused-flag getter | MED | dump (timing-frame.md §1; function-roles.md, MED) — ⚑ corrected (review wave 3, 2026-10-06) #L: split from the LOW row above |

## INDEX updates (for merge)
- **#26 closed**: initial threshold = `life_InitialRequiredScore` 10 000, step 0, step += 10 000
  per life (§3.1–3.2); coin bonus = money × 100 × multiplier in max(2·money,100) steps (§6.5);
  accuracy = tier(flli189–194 by float pct ≥ 100/95/90/85/80) × sector × multiplier with the
  100-step overshoot quirk (§6.3–6.4); defence bonus payout = 2000 × sector × multiplier (§6.1);
  random-bonus selection table (§7).
- **#27 narrowed**: finale condition, notice, 1200-frame wait, mission bonus, game end and pref
  update traced (§8); `EndGameFinale` perm sound has no code consumer (its ID `leen` is played by
  the `noal` unit data). Open: the data-driven `noal`/`12gc` chain (NR #5).
- **#28 closed**: no starting bonus exists in 1.0.6 code — pgsl 3/6 unreferenced (raw scan);
  start-sector effects are 1 life, no high score, no pref update, no finale, start weapon by level
  (§9.3, §10.3).
- waves-and-enemies.md §7 ⚑ corrections: "100 % = MissionBonus 100000 + miac" → per-level 100 %
  is tier 1 + `acbo`; mission bonus is 10 × 100 000 raw for all-levels-100 % (§6.4); "coins ×
  coinValue" → money (coin units) × 100; initial threshold now resolved; random-bonus "flli 218
  (10)" = reward-armed upgrade threshold, "219 (3)" = minimum sector for rb09/rb10 (§7).
- function-roles.md §1 fix-pass note on the starting bonus → see §10.3.
