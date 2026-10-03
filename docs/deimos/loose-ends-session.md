# Deimos Rising 1.0.6 — session-flow loose ends (wave 2, reader 7)

Wave-2 reader 7, 2026-10-03. Code and data readings only; nothing here is behaviour-verified.
**Scope:** an explicit checklist taken from the wave-1 NOT RESOLVED lists. D7 = the `plde` fly-in
keys (player-physics.md NR 1). D12 = session end and finale: the `noal` → `12gc` unit chain
(scoring-bonuses.md NR 5, bosses.md NR 8), the lives gate in `FUN_100051a0` (player NR 6), the
high-score insertion `FUN_100214c0` and the post-game gates in `FUN_100234d0` (scoring NR 1/2,
`DAT_100e01b8`), the level-select bonus text (level-scroll-objects.md NR 7), the screen
transitions `FUN_1000b9a0`/`FUN_1000ba70`/`FUN_1001e9d0` (level NR 9). D14 = misc: `FUN_10029c00`
(player NR 5), `FUN_10000630` exit (unit-def-struct.md NR 3), `FUN_100461b0` (unit-def NR 4),
`FUN_1003d550` (unit-def NR 5), `0x100e013c`/`0x100e0140` (level NR 2), `FUN_10012ca0` (level NR 3),
tag order after `Data:Local` overrides (weapons NR 8 = INDEX #2). Plus the film (replay) end to end.
**Out:** tally arithmetic (scoring-bonuses.md §6 owns it), the entity state machine itself
(waves-and-enemies.md §3, bosses.md §3, spawn-and-waves.md §2 are used as given), the name-entry
text rendering, registration.

Evidence: raw listing `$W/disasm-w2s7.txt` (DisasmFuncs.java against `$W/work-w2s7`, 32
functions), plus a raw PPC decoder over `$W/mem/10000000.bin` for the address scans (scratch
scripts `scan94.py`, `r2scan.py`, `rawdis.py`; the method is described where used). `$W` =
`/Users/andiyar/ghidra-proj-deimos`; TOC r2 = `0x100e6330`; data image base `0x100de330`.
Unit data: `$W/data/Game/unde/*.unde.txt`, `$W/data/Game/leve/*.leve.txt`, flli from
`$W/data/Game/flli/Game[gafl].flli.txt` (index = line order, checked against flli 13/18/196).

## 1. D7 — the `plde` fly-in keys have no reader (except MoneyCounterSpawn)

Method: a raw scan of every instruction in the code image. A register is "plde" after
`lwz rX,0x94(rY)` (player+0x94 = plde, player-physics.md §1), or `r3` after `bl` to the plde
getters `FUN_10026ca0` / `FUN_10039520` / `FUN_10039460`. It stays tracked for 60–80
instructions until it is overwritten, a call clobbers r3–r12, or `mr` copies it. Every D-form
load/store through a tracked register is reported. The scanner was **validated** on the known
reads: it finds all of `+0x48 +0x64 +0x68 +0x6c +0x80 +0x84 +0x88 +0x8c +0x90 +0x98 +0x9c
+0xa0 +0xd0 +0xd4 +0xdc +0xe0` at the addresses player-physics.md and scoring-bonuses.md quote
(e.g. `1002a254 lwz r3,0x80(r3)`, `10029e3c lwz r27,0xa0(r3)`).

| plde key (offset) | readers found | label |
|---|---|---|
| `waitingTime` +0x74, `filmIntroTime` +0x78, `introTime` +0x7c | **none** | HIGH (scan) |
| `entry_StartVelocityX/Y` +0xa4/+0xa8, `entry_TargetVelocityX/Y` +0xac/+0xb0, `entry_VelocityDelta` +0xb4 | **none** | HIGH (scan) |
| `death_Duration` +0xc0 | **none** | HIGH (scan) |
| `active_MoneyCounterSpawn_ID` +0xc4 | `10027800 lwz r27,0xc4(r3)` (r3 = `lwz r3,0x94(r30)` at `100277fc`) in the coin-bonus setup `FUN_10027670`, spawned at (flli 179, flli 180) (`10027814 li r3,0xb3 … 10027888 li r3,0xb4`); also preloaded by `FUN_100399a0` (dump: `FUN_1003e580(*(plde+0xc4))`) | HIGH |
| (side finds) `entry_InitialDelay` +0xb8 `1002a1bc`, `death_Spawn_ID` +0xbc `10027e80`, +0xc8 `10027214`/`100272bc` | already in player-physics.md | — |

Cross-check: a second scan of the player and game modules (`0x10026000–0x1002b000`,
`0x10005000–0x10009400`) for `lfs` at 0xa4/0xa8/0xac/0xb0/0xb4 and `lwz` at 0x74/0x78/0x7c/0xc0
finds only stack slots (`r1`), player +0xa8 shield (`10027544`), player +0xa4 max speed
(`100291f4`) and the player level getter `FUN_10029cb0` (`10029cb0 lwz r3,0xc0(r3)`). Plde
pointers are passed to only one callee in the player module that reads plde fields
(`FUN_100399a0`: +0x28/30/38/40/f0/a0/70/bc/c4/c8/cc/d0). [HIGH for "no direct-displacement
reader"; caveat: a plde pointer spilled to the stack and reloaded would escape the tracker — the
second scan covers that case for the two modules that own the player.]
**Consequence for the replica:** there is no fly-in. The ship appears at the start point with zero
velocity after `entry_InitialDelay` (player-physics.md §4.1/4.2); dying lasts `dyingTime`/
`finalDyingTime`, not `death_Duration`. The eight keys are parsed and never used in 1.0.6.

## 2. Session results and the post-game gates (`FUN_100234d0`, listing)

### 2.1 What `FUN_100051a0` hands back [HIGH — dump + listing]
Request (8 bytes at `r1+0x3c` in `FUN_100234d0`): +0 level ID (from level select; 0 for films),
+4 number of players (`stb r19,0x40(r1)`), +5 film flag (`stb r20,0x41(r1)`: 0 play, 1 "Last
Film", 2 attract demo). Result (0x18 bytes at `r1+0x44`), filled at the end of `FUN_100051a0`:
| off | meaning | source |
|---|---|---|
| +0x00/+0x01 | player slot exists | `FUN_10026c90(p) != -1` (index byte). **Both are 1 in a one-player game**: `FUN_10026410` stores index 0/1 for both objects |
| +0x04/+0x08 | score (decoded) | `FUN_100299f0`; 0 if no slot |
| +0x0c/+0x10 | level ID at that player's last level start | `FUN_10029cb0` = player+0xc0; `none` if no slot |
| +0x14 | all levels completed | `G+0x0d` |
| +0x15 | any player cheated | `FUN_10029be0` = player+0xbd |
| +0x16 | stopped by the unregistered limit | `G+0x0e` |

### 2.2 Gates after the game [HIGH — listing `10023640..100238a8`]
```
10023674  lbz r0,-0x6178(r2)     ; DAT_100e01b8 (quit requested), kept in r24
10023680  bne 0x1002377c          ; quit requested -> skip pref update
10023684  lbz r0,0x59(r1) ; bne   ; cheated -> skip
100236a8  lbz r0,0x0(r20) ; beq   ; per player: slot exists
100236b8  lwz r0,0x4(r19) ; cmpwi r0,0x0 ; ble   ; score > 0 (strict) for the sector max
100236c4  lwz r3,0xc(r19) ; bl 0x10011e30        ; sector of the player's level (1..12)
100236e4  lwz r3,0x4(r19) ; bl 0x10021470        ; high-score test on every present player
10023710  lbz r0,0x58(r1) ; bne ; subi r19,r22,0x1   ; not finale -> best - 1
10023724  cmpwi r19,0x1 ; bge ; li r19,0x1           ; best >= 1
10023730  r27 (film) ; 10023738 r25 (start sector > 1) -> skip
10023744  bl 0x10004f00 (pref 3) ; cmpw r19,r3 ; ble -> skip ; bl 0x10004ac0(3, best)
1002383c  lbz r0,0x59(r1) ; bne ; r25 ; r27 ; r24 ; r23 (someone qualified) -> bl 0x100214c0
```
`r25 = (chosen sector > 1)`: `100235d8 lwz r0,0x38(r1); cmpwi r0,0x1; ble; li r25,0x1`.
So: **int pref 3 (highest sector) = max(old, best)**, with `best = max sector over players with
score > 0, minus 1 unless the finale was reached, at least 1`; only for a non-film, non-cheated,
not-quit game started at sector 1. **High-score entry** runs under the same gates when any present
player passes `FUN_10021470` (score > 15th entry, signed strict; scoring-bonuses.md §9.1; ⚑ corrected (review wave 2, 2026-10-03)
#M1 checked and **not** adopted: the listing `10021494 xor r0,r31,r0; 10021498 srawi r3,r0,0x1;
1002149c and r0,r0,r31; 100214a0 subf r0,r0,r3; 100214a4 rlwinm r3,r0,0x1,0x1f,0x1f` evaluates to
the **signed** `score > entry` on 200 000 random pairs plus all sign-boundary pairs, e.g.
(0x80000000, 1) → 0 and (0xFFFFFFFF, 0) → 0, which unsigned would give as 1). This
upgrades scoring-bonuses.md §9.2 (MED) to HIGH; the reading is unchanged.

### 2.3 `DAT_100e01b8` = "quit requested" [HIGH for the writers; MED for the in-game route]
Writers (dump, `0x100e01b8` = r2−0x6178): cleared at the top of the menu loop `FUN_100229a0`;
set by the menu key handler `FUN_10023b00` for `'q'`/`'Q'`; by `FUN_10023330(part == 2)` (menu
command); by `FUN_10022ed0` (event code 8 of `FUN_10048f30`, whose jump table Ghidra could not
recover; ⚑ corrected (review wave 2, 2026-10-03) #C10: code 8 = the **Quit AppleEvent** — high-level event 23 at `100490ec`
returns 8 when `b8` is set after `AEProcessAppleEvent`, front-end.md §2.5 [HIGH]). Readers: the menu loop (`if set → FUN_10024f90` = flash button 6, set
`DAT_100e01b9` = leave the app), `FUN_10022ef0` (the Caps-Lock pause loop, key 0x39, exits with
"quit" when it is set → frame controller quit flag → `FUN_100064c0` ends the game), and the gate
above. So a game that ends because the player quit the application gives **no pref update and
no high-score entry**, and the menu then quits. (The `aevt`/`quit` Apple-event handler installed
by `FUN_10049aa0` is the probable in-game setter; its TVector target was not traced. LOW for
that link.) ⚑ corrected (review wave 2, 2026-10-03) #C10: the aevt route itself is identified (event 23 → code 8, front-end.md
§2.5, HIGH); what stays open is only whether the event pump runs during play (INDEX #48).

## 3. High-score insertion and name entry

### 3.1 `FUN_100214c0 @ 100214c0 (result)` [HIGH — listing `100214c0..10021940`, simulated]
Two full prefs copies: **A** at `r1+0x3a38`, **B** at `r1+0x548` (`FUN_10004c30` each).
Tables (prefs offsets, engine-loop.md §10): scores `+0x1260` (15×4), names `+0x10f8` (15×0x15),
sector names `+0x12d8` (15×0x20); player names `+0x1233`/`+0x1248`.
```
idx1 = first i in 0..14 with P1.score > A.score[i]   ; 10021520 lwzx ; cmpw r4,r0 ; ble next  (strict)
idx2 = same for P2 (only if result[1])
if idx1 != -1 && idx2 != -1 && idx1 >  idx2: idx1 += 1 ; if idx1 >= 15: idx1 = -1   ; 100216a4
if idx2 != -1 && idx1 != -1 && idx2 >= idx1: idx2 += 1 ; if idx2 >= 15: idx2 = -1   ; 100216cc (uses adjusted idx1)
if idx1 != -1: for i = idx1..13: A[i+1] = B[i]   (score, name, sector name)          ; 10021700..1002177c
B = A  (memcpy 0x34f0)                                                                ; 1002178c
if idx2 != -1: for i = idx2..13: A[i+1] = B[i]                                        ; 100217b0..1002182c
A[idx1] = {P1.score, prefs P1 name (A+0x1233), levelName(result+0xc)}                 ; 10021848 stwx ; 1002185c ; 10021870 bl 0x100120f0
A[idx2] = {P2.score, A+0x1248, levelName(result+0x10)}
FUN_10021bd0(0, idx1, A, 1) ; FUN_10021bd0(1, idx2, A, 1)
```
Python simulation of exactly this (scratch `hs.py`, default table 15000…1000):
| P1, P2 | idx1, idx2 | resulting table (top 10) | verdict |
|---|---|---|---|
| 12500, 9500 | 3, 7 | 15000 14000 13000 **P1** 12000 11000 10000 **P2** 9000 8000 | correct |
| 9500, 9500 | 6, 7 | … 10000 **P1** **P2** 9000 … | correct (P1 wins ties) |
| **9500, 12500** | 7, 3 | 15000 14000 13000 **P2** 12000 11000 10000 **P1** **8000 8000** | **9000 lost, 8000 duplicated** |
| **14500, 14600** | 1, 2 | 15000 **P1 14500** **P2 14600** 14000 … | **P2 listed below a lower P1 score** |
Two original quirks, both reachable only in two-player games when both players qualify [HIGH —
listing + simulation]: (a) when P2 out-ranks P1 in different slots, the entry just below P1's
original slot is lost and the next one duplicated (P1's shift used the pristine copy B before P2's
shift moved the rows); (b) when both scores fall between the same two entries, P1 is placed first
regardless of which score is higher. A faithful replica must reproduce both.
The `+0x129c` "per-entry int" of engine-loop.md §10 is **never written** by the insertion. A
raw scan for displacement 0x129c/0x12a0 finds only the prefs save/load/copy routines
(`1000470c`, `10004954`, `10004d94`, `10005094`). It stays 0 from the fresh-prefs zero fill and is
dead in 1.0.6. [MED — no indexed read via a computed base was ruled out beyond the scan]

### 3.2 Name entry `FUN_10021bd0 (player, slot, prefsCopy, afterGame)` [MED — dump, key branches listed]
Copies the player's stored name into the slot and shows the table (`FUN_100222f0`). Then a key loop
(`FUN_10048c90`): `0x0d` Return or `0x0a` → commit (`10021ec4 cmpwi r0,0xd; beq 0x10021f18`,
`10021ee8 cmpwi r0,0xb; bge …; b 0x10021f18`); `0x08` → delete the last char; other printable
chars (ctype mask 0xdc) are appended up to 20, else sound 15. The `0x5e5b` compare after `extsb`
(`10021ef4`) can never match. **While editing there is no timeout and Esc does nothing** (0x1b
fails the printable test). On commit: sound 4; the name is upper-cased for the easter-egg test
(`FUN_100463b0`, `FUN_10057a30`): DILVISH → "Just Ship It, Baby", SUPERCOBRA → "Munkis Rool
J00", PYTHOS → "Leonard Cohen Rules J00", two more from `0x100e8af8`/`0x100e8b63` (one gives
"Filthy Communist") — ⚑ corrected (review wave 2, 2026-10-03) #M7c #C9: these are front-end.md §4.3's `BIKI` → "Filthy
Communist" and `FISJ` → "Daikajinn!!" (order BIKI, DILVISH, SUPERCOBRA, PYTHOS, FISJ, last match
wins; ctype table `0x100f0f94` checked there); an empty name becomes "Jar Jar Must Die". The result is stored into the slot
**and back into the player's default name** (`FUN_10057780(iVar14, iVar15)`). After commit the
screen closes after flli 79 `Scores_DurationBetweenPlayers` = 25 TickCount ticks or a key/click;
flli 78 `Scores_Duration` = 600 is the menu-viewing timeout (`param_4 == 0`).
On exit, if committed, `FUN_100047f0(A)` copies A into the live prefs `_DAT_100def40`.
**Persistence:** prefs reach disk only at shutdown. `FUN_10000630 → FUN_100045f0` writes them
when `DAT_100e00f5` is set, and `FUN_10004540` sets that flag at every prefs load (dump lines
2564/2587). So high scores and pref 3 are written when the app quits normally. A crash loses
them. [HIGH for the call chain (dump; `FUN_100047f0` has the single caller `FUN_10021bd0`)]

## 4. Game over and the lives gate (player NR 6)

**Gate** [HIGH — listing]: the gate byte (`r1+0x3b`) and the game-over-notice byte (`r1+0x3a`)
of `FUN_100051a0` are zeroed once per session (`10005618 stb r0,0x3b(r1)`, `10005620 stb
r0,0x3a(r1)`). They are passed to `FUN_10006b50` as `param_1`/`param_3` (`100059c4 addi
r3,r1,0x3b`, `100059c8 addi r5,r1,0x3a`), which only ever sets them to 1. The gate is set at the
top of the first tick in which P1 is in life state 4 (`10006b9c lbz r0,0x0(r22) … 10006bac li
r4,0x4; bl 0x10026c60 … 10006bc4 stb r0,0x0(r22)`). No other writer exists, so **the gate is never
reset within a session**. It only blocks a lives decrement before P1 has first appeared (at most
the first 56 ticks of the session, when nobody can be dying). For the replica: decrement lives at
the end of every dying state.
**Game over** [HIGH — listing `10006c84..10006d98`]: after the player updates, if neither player
is in game (+0xc4): `G+0x0a = 1`; on the first such tick spawn PermObject 24 `nogo`
(Notice_GameOver) at (flli54·0.5, flli55·0.5) = (208, 240) and `G+0x34 = gameTime`
(`10006d60`). On later ticks `gameTime > G+0x34 + flli 13 (110)` → `G+8 = 0`
(`10006d88 add; cmpw r0,r3; ble; li r0,0; stb r0,0x8(r31)`). So the session ends **111 ticks**
after the last player leaves. In a two-player game the game continues while either player is in.

## 5. D12 — the all-levels finale, full sequence

Trigger (scoring-bonuses.md §8, level-scroll-objects.md §8, HIGH there): at the level-end point
of sector 12 in a session that started at sector 1 (`G+0x14 == 12 && G+0x10 == 12`) →
`G+0x0d = 1` and PermObject 23 **`noal`** instead of `nole` at (208, 240).

### 5.1 `noal` "Notice - All Levels Completed" (data, decoded with the state rules of bosses.md §3.2)
Group of 1, `x/yOffset` 0/0 and −90/−90 → rectangular placement (waves-and-enemies.md §4) at
**(208, 150)**; layer `hud `, 7 states:
| state | timer → target | counter | look | entry sound |
|---|---|---|---|---|
| S0 Flash On | 3 → Flash Off | **16 → Spawn Game Completion** | `nomc` frame 0, vis 100 (Δ100), scale →100 (Δ2) | `acbo` @0.7, RepeatOnStateChange TRUE |
| S1 Flash Off | 3 → Flash On | — | vis →0 (Δ15), scale →90 (Δ2) | — |
| S6 Spawn Game Completion | 2 → Scale Out | — | vis 100, scale 100 | — ; spawn set `12gc` ×1, delay 0 |
| S5 Scale Out | 10 → Scale In | — | scale →100 (Δ1) | — |
| S4 Scale In | 10 → Scale Out | — | scale →90 (Δ1) | **`leen`**, RepeatOnStateChange **FALSE** |
| S2 Fade Out, Delete / S3 Hold | (unreachable: no timer, counter or rule targets them) | | | |
Entry-sound rule (dump `FUN_10033850` lines 169–200, state +0x18/+0x19/+0x1a): a non-looping
entry sound plays when the state's entry counter is 1, **or** on every entry if
`RepeatOnStateChange`. So `acbo` plays on S0 entries 1–15 and `leen` (= the `EndGameFinale`
permanent sound's ID) plays **once**, on the first Scale In. [MED — dump, not listing; data HIGH]

### 5.2 `12gc` "Level 12 - Game Completion" (invisible controller at the spawner, (208, 150))
| state | timer → target | counter | spawn sets |
|---|---|---|---|
| S0 Wait | 5 → Explosions | — | — |
| S2 Explosions | 300 → Spawn Flags… | — | `aieg` ×1 (Air Explosion Group: 50 members, group delay 5–6, offsets ±200, sound `balh`) |
| S1 Spawn Flags, Delete on Counter | 280 → **itself** | **3 → Delete** | 4 × `miof` at (−126,−25), (2,−43), (104,−11), (188,42), delays 0/70/140/210 |
| S3 Wait Before Spawning Again | unreachable | | |
All five rules of every state have unit `none` and are skipped (`100155a8 addis r0,-0x6e6f(r21);
cmpli 0x6e65; beq 0x10015904`). [HIGH for the skip; data HIGH]
`miof` (Mission Iris – Open Flag) is an invisible marker deleted after 1 tick. Le09 (sector 12)
places four **Mission Irises** near the map top: `miac` (416,179), `mipo` (340,120), `mimu`
(240,85), `migc` (132,103). Each waits in S0 for rule "Is Active `miof` within 60". Then S1 wait
10 → S2 Open 8 → S3 spawns its storm (`mias` all-coin storm, `mips` points storm, `pimu` multiplier
pickup, `migs` gold-coin storm; sound `powe`) for 40 → S4 Close 30 → S0. In screen coordinates
(map − 32 in x at view offset 0, y = map y at the top of the map) the flags fall 18–28 px from
miac/mipo/mimu/migc respectively. That is within 60 for any view offset in [−32, 31] (worst case
54.6 px, migc at offset −32), so **each flag opens one iris**. [MED — distance helper of rule 2
not read, bosses.md NR 1; frame equivalence assumed] ⚑ corrected (review wave 2, 2026-10-03) (O3): the rule-2 test is now
listing-read — inclusive `dist ≤ 60` from the polling iris (bosses.md §3.1, HIGH) with the
truncated integer distance (54.6 → 54); the −32 frame rule is settled by loose-ends-combat.md
§5.1. The per-iris px figures stay MED (frame equivalence).

### 5.3 Timeline (T0 = the level-end tick that spawns `noal`; ticks of game time)
| tick | event |
|---|---|
| T0 | `noal` S0, `acbo`; players made invulnerable; accuracy timer starts (`FUN_100072c0`) |
| T0+3, +6, … | Flash Off/On every 3 ticks; `acbo` on each Flash On (15 plays, T0…T0+84) |
| T0+90 | 16th Flash On → counter → S6; `12gc` spawned the same tick (delay 0, spawn-and-waves.md §2.3) |
| T0+92 | `noal` S5 Scale Out |
| T0+95 | `12gc` S2; Air Explosion Group requested: 50 explosions staggered 5–6 ticks (≈ T0+95…T0+370) |
| T0+102 | `noal` S4 Scale In + **`leen`** (only play); then pulses 90↔100 % every 10 ticks until the session ends |
| T0+395 | `12gc` S1 entry 1: flags at ≈ T0+395, +464, +534, +604 (delay d issues at entry + max(d−1,0)) → irises open; storms ≈ 18–19 ticks after each flag |
| T0+675 | S1 entry 2 (self-timer 280): second flag round ≈ T0+675, +744, +814, +884 → each iris releases a second storm |
| T0+955 | S1 entry 3 → counter 3 → `12gc` deleted |
| T0+1201 | accuracy tally state 1 ends (flli 196 = 1200, strict wait) → tally, then the mission bonus if all 12 levels were 100 %, then the coin bonus (scoring-bonuses.md §6.4–6.5; the money from the storms counts) |
| tally done | `G+9` → `FUN_10007170`: `tran`, fade to black (§6), `FUN_100064d0` finds sector 13 → `none` → `G+8 = 0` |
| after | `FUN_100234d0`: result +0x14 = 1 → best sector 12 (no −1) → pref 3 = 12; high-score check (§2.2) |
[Timeline: MED overall — the per-state numbers are data (HIGH) and the timer/counter/spawn rules
are HIGH in bosses.md §3.2 and spawn-and-waves.md §2.3. Medium because the exact same-tick order of
creation versus the first update, and the group-delay semantics of `aieg`, were not re-walked here.]
The game itself never "ends" during the 1200-tick wait. The players keep flying (invulnerable)
and can collect the storm pickups. The session ends only after the tallies.

## 6. Screen transitions (level NR 9)

| function | role | evidence | label |
|---|---|---|---|
| `FUN_1000b9a0 @ 1000b9a0 (display, mode)` | **fade to black.** 33 steps, `a = 32, 31, …, 0`. Each step scales the back buffer (display+0x68) **in place** toward colour 0 by a/32 (`FUN_1001ec80(buf, rect, 0, a)`, a no-op when a == 32), presents it (`mode` 0 `FUN_1000bc60`, 1 `FUN_1000bd80`), then spins until TickCount advances by ≥ 1. Because each step multiplies the already-darkened buffer, the image is visually black after about 12 steps, but the call always takes about 33 ticks (0.55 s) | listing `1000b9cc li r27,0x20 … 1000b9fc bl 0x1001ec80 (r5=0, r6=a) … 1000ba34 addi r31,r31,1; bl 0x100497f0; cmplw; blt … 1000ba50 subic. r27,r27,1; bge` | HIGH (calls, loop); MED (visual compounding) |
| `FUN_1000ba70 @ 1000ba70 (display, mode)` | **fade from black.** It clones the back buffer (`FUN_10009ac0` = clone + copy) and makes a second clone filled with colour 0 (`FUN_10009f00`, colour words at `*(r2−0x732c)` = 0x100d6390 = 0,0). Then for `a = 0, 4, …, 32` (9 steps): back = blend(snapshot, black, a), present, wait ≥ 1 tick. About 9 ticks (0.15 s). Frees both clones | listing `1000bad4 li r25,0 … 1000bb18 bl 0x1001e9d0 … 1000bb70 addi r25,r25,4; cmpwi r25,0x20; ble` | HIGH |
| `FUN_1001e9d0 @ 1001e9d0 (srcA, srcB, dst, rect, a)` | 16-bit 1-5-5-5 blend `dst = floor((A·a + B·(32−a))/32)` per channel. G is moved to bits 20–24 (`rlwimi r7,r8,0xf,0x7,0xb`) so all three channels share one multiply. Clipped to the buffer | listing `1001eb8c andi. 0x7c1f; rlwimi …0xf…; mullw ×a; mullw ×(32−a) (subfic r4,r24,0x20); add; rlwinm r4,r6,0x1b,5,31; andi. 0x7c1f; rlwimi r4,r6,0xc,0x16,0x1a; sth` | HIGH |
Uses: level end `FUN_10007170` (fade out, then the next level); in-game fade-in at game time
flli 18 = 2 of every level (`FUN_100051a0`: `FUN_1000ba70(display,1)` and the level music, once per
level because `FUN_100064d0` clears `G+0x38`, `10006510 stb r5,0x38(r30)`); `FUN_100234d0`:
fade out before the level select and after the game, fade in on the `back` background.
TickCount is 60.15 Hz nominal (timing-frame.md §4; exact rate = INDEX #42) (⚑ corrected (review wave 2, 2026-10-03) #C12:
was "60 Hz") (`FUN_100497f0` = `TickCount` glue), so the transitions are real time, not
logic ticks.

## 7. The film (replay), end to end

**Recorded per tick** [HIGH — dump + listing]: `FUN_1002a3a0 (player, film, isReplay)` runs only
while the player's life state is 4. It clears the 7 input bytes and then either reads the
player's next film byte (`FUN_100097a0`) or polls ISp and records (`FUN_10009830`). Recording per
player block (stride 0x4eac): byte at `+0x1c + cursor` = input bits (engine-loop.md §7);
`frames(+0x10 file) = cursor+1`; `+0x14 = score + 0xb3ac2`; `+0x18 = current level` — all
rewritten each recorded tick, capped at 20000 ticks. Not recorded: ticks in states 1–3, pause,
console, the RNG state, speed settings. In other states the input bytes keep their last value in
both record and replay, so they stay identical.
**Restored at replay start** (`FUN_100069b0` → `FUN_100094a0` load + version check →
`FUN_10009680`): level ID, number of players, seed, then `FUN_10055400(seed)` (srand;
`10006b24 lwz r3,0x38(r1); bl 0x10055400`). **Nothing else is stored.** Lives, score, money,
multiplier, shield and weapons come from the normal per-session setup `FUN_10026410(…, sector)` of
the film's level: 3 lives only if that level is sector 1, else 1; air weapon by sector. A
recording starts from the same fresh state (`10005738..100057ec`: `srand(TickCount())`, seed
stored by `FUN_10009710`). So the replay is deterministic given the same data files and the same
RNG draw order. The pre-`srand` draw `FUN_10046580(400,2000)` at the top of `FUN_100051a0` does not
matter. [HIGH]
**One level only** [HIGH]: in a film session `FUN_10007170` ends the session at level complete
(`100071e8 rlwinm. r0,r25 … stb 0,0x8(r30)`), and `FUN_100064d0` never resets the film cursors
(its only `bl` targets in the 0x10009xxx range are `0x10009d70`/`0x10009f00`, pixel-buffer
routines; `FUN_10009970` cursor reset has the callers `FUN_10009390`/`FUN_10009680` only). A
multi-level game therefore records all its levels into one stream, but "Last Film" replays only
the **start level** of that game.
**Replay ends** when any key or mouse button is pressed (`FUN_10048e60`), or when P1's cursor > P1's
frames (`FUN_10009750`, brute-forced idiom = signed `cursor > frames` — ⚑ corrected (review wave 2, 2026-10-03) #M1 checked and
**not** adopted: listing `10009758 xor; 1000975c srawi 1; 10009760 and r0,r0,r4; 10009764 subf;
10009768 rlwinm r3,r0,0x1,0x1f,0x1f` is the signed compare, as for `FUN_10021470` §2.2; checked after every draw,
`10005a24..10005a48`), or at level complete, or at game over. `FUN_100097a0` still reads the
byte at `cursor == frames` (zero), so the replay runs one tick past the recording. P2's frames
are never checked. While replaying, "REPLAY" (GameString 9) is drawn and cheats are refused.
**Film modes** [HIGH]: `FUN_10024de0` = `FUN_100234d0(2,1)` attract demo. It cycles film tags whose
name contains "Demo" with the counter `G+0x24`, wrapping to the first; `G+0x24` is not in the
session reset list, so it persists across sessions. `FUN_10024e10` = `FUN_100234d0(1,1)` plays tag
`last`. Films skip level select, pref and high-score handling (`r27`).
**Last Film auto-save** [HIGH — listing `10005b00 lbz r0,0x20(r29); cmplwi; bne; … lis
r4,0x6c61; addi r4,r4,0x7374; bl 0x100095b0`]: at the end of **every non-film session** —
game over, finale, quit (`FUN_100064c0` only clears `G+8`, the save still runs), unregistered cut.
The only exceptions are a film session and a cancelled level select (`FUN_100051a0` is not
entered). `FUN_100095b0` copies 0x9d68 bytes and writes the tag `film`/`last` named "Last Film"
(`_DAT_100e0100 → 0x100e449c`) through `FUN_100025b0` → `FUN_10002640` as the file
` Data:Local:<type>:Last Film[last].film` (format `%s[%s].%s` at `0x100e38eb`; `Data`/`Deim`
type/creator). It then rebuilds the tag index (`FUN_100016c0(0,0)`), so the new file overrides any
pak copy (§8.7). Each game overwrites the previous Last Film.

## 8. D14 — miscellany

8.1 **`FUN_10029c00 (player, type)` = console weapon cheat** [HIGH — raw decode]. ⚑ corrected (review wave 2, 2026-10-03)
(`FUN_10029c00` conflict closed): the command is `PLAYER AIRWEP|AIR` / `PLAYER GROUNDWEP|GROUND`
— sub-keywords of the PLAYER handler at `0x10007ff0` (messages-notices-console.md §5.5); this
section had dropped the `PLAYER` prefix. PLAYER is unregistered, so it is unreachable in 1.0.6. There is no
data-image pointer to it (all three memory images scanned for the word 0x10029c00), but there are
two direct `bl` calls in code Ghidra left undefined: `10008408` with `r4 = 0x5045<<16 + 0x4141` =
`'PEAA'` and `10008490` with `'PEAG'`. Both run in loops over the players, gated by
`FUN_10026c60(p,4)` (state 4) and preceded by `FUN_10029bf0(p,1)` (set "cheated"). The selecting
strings are compared at `r31 = r2−0x2634` +0x500/+0x507/+0x50b/+0x515 = "AIRWEP"/"AIR"/
"GROUNDWEP"/"GROUND" (data image). Effect: switch that weapon type to the next definition
available at the current sector (`FUN_1002adb0`, `FUN_1003b180`).
8.2 **`FUN_10000630` exits the process** [HIGH — listing]: its last call `10000730 bl 0x10048480`;
`FUN_10048480` logs, then `100484b8 bl 0x100d4d7c` (UnregisterAppearanceClient glue) and
`100484c0 bl 0x100d4464` (**ExitToShell** glue). So a fatal `FUN_1000ced0(…, 1)` (memory, tool,
`FUN_10001000`, and the unit-def "incorrect or missing data" error) quits the game after the
alert, saving prefs on the way (`FUN_100045f0`). ⚑ conflict with pak-format.md §2.3 item 4:
`FUN_10000fd0` is **not** fatal: `10000fdc li r4,0x0; bl 0x10001040` → `FUN_1000ced0("Error",
msg, 0)` shows the alert and **returns**. The same holds for the FILE/DATA ERROR helpers
`FUN_10000f30`/`FUN_10000f80`, which end in `FUN_10000fd0`. "Tag Index Incomplete! Aborting." and
the "critical files are missing" alert therefore continue running. [HIGH for the flag value; MED
that the alert routine `FUN_10045ab0` does not itself quit]
8.3 **`FUN_100461b0` = "running Mac OS X"** [HIGH — listing]: `Gestalt('sysv')` (`100461b8 lis
r3,0x7379; addi 0x7376; bl 0x100d3684`), returns 1 if no error and the version is ≥ 0x0A00
(`100461e4 cmpwi r0,0xa00; blt`). `DAT_100e024c` is 0 in the data image. So on Mac OS 9 the Units
Cache is neither read nor written. On OS X a missing or stale cache sets the flag and the cache is
written at shutdown; a good load leaves it 0 (no rewrite). `FUN_10041e40` clears it again if its
temp file cannot be opened. Gameplay-neutral.
8.4 **`FUN_1003d550 (unitID, family)`** [HIGH — raw call sites]: both callers pass the entity's
own family record, `lwz r4,0x98(rE)` (`100155b4` rules, `10015d74` spawn sets). Entity+0x98 is
written once in `FUN_100144a0`: `100144b8 stw r4,0x94(r3); lwz r3,0x94(r3); bl 0x1003d450;
stw r3,0x98(r31)` (family of the entity's unit). The lookup searches that family's member list
(`family+0x40`, compare `unit+4`), then the global master list. Unit IDs are unique, so the
result is the same unit either way; the family pass is a fast path. Rules whose unit is `none`
are skipped before the lookup (§5.2).
8.5 **`0x100e013c` / `0x100e0140` have no readers** [HIGH — raw scan]. Every D-form access with
base r2 in the code image: `1000fab4 stb r4,-0x61f4(r2)` (`FUN_1000fa90`), `1000fac8`/`100100b8`/
`100100f4`/`10010114 stw …,-0x61f0(r2)` — stores only. The only `addi rX,r2,d` within 0x100
below them (`1000d074 addi r29,r2,-0x6210` → 0x100e0120) is used only at offset 0. No pointer to
0x100e0040–0x100e0140 exists in any memory image. Both are write-only (dead) state.
8.6 **`FUN_10012ca0 (entity, margin, mode)` bounds** [HIGH — listing]. First a ground entity
(+0x19 == 0) gets `y += scrolled px` (`FUN_1000fed0`), then `x += vx, y += vy` always. `W =
int(flli 54) = 416`, `H = int(flli 55) = 480` (`10012d24..10012d54`, both `fctiwz`; the decompile
mislabels W as the old y); `hw = +0x2c`, `hh = +0x30` (ints). **Mode 1** (the only call,
`10033ff0 li r4,0x80; li r5,0x1; bl 0x10012ca0`, margin 128) keeps the entity iff
`x + hw ≥ −128` (`10012da0 fcmpo; blt fail`), `x − hw ≤ W + 128 = 544` (`10012dd4 fcmpo;
bgt fail`), **`y ≥ −128`** (`10012df0 fcmpo f3,f0; blt fail` — the top test has **no** half
height), and `y − hh ≤ H + 128 = 608` (`10012e2c fcmpo; ble keep`). So an entity is culled when
its centre (not its top edge) goes 128 px above the screen. Mode 0 (`x+hw ≥ −32`, `x−hw ≤ W+32`,
`y+hh ≥ 0`, `y−hh ≤ H`; constants at `*(r2−0x7240)` = 0x100d67a8 → [0]=0.0, [3]=−32.0) is dead in
1.0.6.
8.7 **Tag order after `Data:Local` overrides (INDEX #2, weapons NR 8)** [HIGH for override logic;
MED for "Local first"]. The tag index is a linked list with append-at-tail (`FUN_100009e0`:
node.prev = tail, tail.next = node). `FUN_100016c0` appends the Local-folder records first (the
15-way jump table, INDEX #1, unread) and then every pak in directory order, entries in zip order
(pak records get `+0x154 = 0`, `*(puVar2+0x55) = 0`). `FUN_10004300` walks the list. For every
record with `+0x154 ≠ 0` (Local), `FUN_100043c0(type, id)` removes **every non-Local record with
the same (type, ID)** (`FUN_10000c00` unlink + free; log "Tag Overridden"). So: **Local always
wins** and keeps its early position; duplicates between two paks are **not** removed (only
counted: "Duplicate (%i) tags found", `FUN_10003970`), and the first in list order is found
first. The shipped Local folders are empty, so the 1.0.6 weapon cycle order is the pak order of
weapons-projectiles.md §2.4. An overriding Local `wede` moves to the front of the cycle.
8.8 **Writer of game flag `+0x39` (INDEX #30, weapons NR 1)** [HIGH — raw scan of `stb …,0x39`]:
the game struct is written only at `10005524`/`10005828` (`FUN_100051a0`, = 0 at session
start), `10006db4` (`FUN_10006b50`, = 1 on every tick from the level-end point) and `10007248`
(`FUN_10007170`, = 0 at the level transition). `FUN_10005cf0` returns it. It is the "level
ending" flag; overload warnings and `canBeSpawnedOnlyWhenPlayersActive` key off the end-of-level
phase.
8.9 **Level-select bonus text (level NR 7)** [HIGH]: confirms scoring-bonuses.md §10.3 with an
independent scan of all 37 `bl 0x10020260`. The literal arguments are {4,5,7,9–18,21–23,33–35}
plus the one non-literal site `0x10030480` (0). pgsl 3 "Starting Bonus $" and 6 "No Starting
Bonus" are never shown. The screen shows the sector name, the `%0.2i` number and messages 4/5
only.

## Worked example — two players, P1 makes the table on the last death

Setup: a two-player game started at sector 1 (3 lives each), fresh prefs (table 15000…1000,
names Mars … Electrofryer, sector names "New Atlantis", player names "Player 1"/"Player 2").
P2 was eliminated in sector 2 (`le06`) with 600 points (+0xc4 = 0, +0xc0 = `le06`). P1 reaches
sector 3 (`le02`, "Darius", +0xc0 = `le02`) and is on the last life (lives stored 1 + 0x1524DCEF)
with 12 500 points. Let t = game time (`G+0x1c`) of the fatal hit.
1. **t** — `FUN_10027100` shield < 0 → `FUN_10027e50`: `death_Spawn_ID` spawned, money dropped
   as coins and set 0, **state 3 at t**, +0xce = 1, multiplier → 1 (player-physics.md §5).
2. **t+41** — dying duration = `finalDyingTime` 40 (lives == 1); first tick with `now > t+40`:
   gate is 1 (§4) → lives stored becomes 0 + 0x1524DCEF; lives < 1 → **state 1 at t+41**.
3. **t+62** — `now > t+41 + gameOverTime 20` → P1 +0xc4 = 0. Same tick, no player in game →
   `G+0x0a = 1`, `nogo` spawned at (208, 240), `G+0x34 = t+62`.
4. **t+173** — `t+173 > t+62+110` → `G+8 = 0`. The pass finishes (`FUN_10007170` does nothing,
   game time → t+174, draw, present). At the default 30 ticks/s the last death to here is ≈ 5.8 s.
5. `FUN_100051a0` tail: sounds/music stopped; **Last Film saved** (§7: seed, `le07`, 2 players,
   both input streams from sector 1 onward); result = {1, 1, 12500, 600, `le02`, `le06`, 0, 0, 0}.
6. `FUN_100234d0`: not quit, not cheated → sectors: P1 3 (score > 0), P2 2 → best 3 → not finale
   → **2** → started at 1, not a film → if pref 3 < 2: **pref 3 := 2** (prefs +0x74). High-score
   test: `FUN_10021470(12500)` = 12500 > 1000 → yes; 600 > 1000 → no.
7. Fade to black (≈ 33 TickCount ticks), `back` image, fade in (≈ 9), `tran` at volume 50,
   `FUN_100214c0(result)`.
8. `FUN_100214c0`: idx1 = 3 (12500 > 12000, not > 13000); idx2 = −1. A rows 4..14 = B rows
   3..13 (El B 12000 … Thomas 2000); Electrofryer 1000 drops off. **A[3] = {12500, "Player 1",
   "Darius"}** (`FUN_100120f0('le02')` = level name).
9. `FUN_10021bd0(0, 3, A, 1)`: the slot shows "Player 1". The player types, say, "ACE", then
   Return: sound 4, no easter egg, A.name[3] = "ACE", and the player-1 default name (A+0x1233)
   = "ACE". 25 ticks later the screen closes → `FUN_100047f0(A)` → live prefs.
10. On quitting the app: `FUN_100045f0` writes the prefs file. The score is stored at file
    offset 0x126C as 12500 + 0x024A8903 = **0x024AB9D7** (38 451 671); the name and sector name
    are obfuscated per pak-format.md §3; pref 3 = 2 at 0x74.
If P2 had also qualified with a score higher than P1's but in a different slot, §3.1 quirk (a)
would corrupt one row of the table.

## NOT RESOLVED (this file)
1. The in-game route that sets `DAT_100e01b8` (quit) during play: the `aevt/quit` handler TVector
   (`_DAT_100dea78`, `FUN_10049aa0`) and event code 8 of `FUN_10048f30` (unrecovered jump table).
   Settle: resolve the TVector's code address and read it; recover the jump table at `0x10048fc8`.
   ⚑ corrected (review wave 2, 2026-10-03) #C10 narrowed: code 8 = the Quit AppleEvent (event 23 at `100490ec`, front-end.md
   §2.5); open only whether that event is pumped during play.
2. `FUN_10045ab0` (the alert behind `FUN_1000ced0`) — whether a non-fatal alert can still quit
   (e.g. a Quit button). Decides whether "Tag Index Incomplete! Aborting." really continues.
3. The finale's same-tick order (entity created in `FUN_10006b50` vs its first `FUN_10033850`
   update) and `aieg`'s group-delay meaning (members staggered vs spawn-in delay). These shift
   §5.3 by ±1 tick and set the explosion spread. Settle with `FUN_10033220`/`FUN_10035cd0`
   listings.
4. ~~The rule-2 distance (`FUN_10035070`/`FUN_10042e90`, bosses.md NR 1) and the frame of
   spawn-set children versus level objects (−32 x shift, bosses.md NR 4). Both affect whether every
   flag opens its iris; §5.2 shows a ≥ 5 px margin under the stated assumptions.~~ → ⚑ corrected (review wave 2, 2026-10-03)
   #S (O3): rule 2 = `dist(polling entity, member) ≤ range`, inclusive, range 0 = any distance
   (bosses.md §3.1, listing `10035184 fcmpo cr0,f1,f2; 10035188 cror eq,lt,eq`), distance =
   `FUN_10042e90` sqrtI(trunc(dx²+dy²)) (damage-health-death.md §1, HIGH); the −32 half →
   loose-ends-combat.md §5.1 (no −32 shift for spawn-set children; only `FUN_10035900` level
   objects).
5. ~~Name-entry easter eggs at `0x100e8af8`/`0x100e8b63` (strings not decoded) and the ctype table
   `_DAT_100dea48` (exact accepted character set).~~ → ⚑ corrected (review wave 2, 2026-10-03) #C9 #S: front-end.md §4.3 —
   `BIKI` → "Filthy Communist", `FISJ` → "Daikajinn!!"; ctype table `0x100f0f94` checked.
6. `FUN_10048e60` (replay abort) — which keys/buttons count (assumed any key or click).
7. Pak directory order on modern file systems (HFS order = alphabetical by name), relevant only
   when duplicate tags exist across paks (none in 1.0.6).

## Role-table rows (for merge)
| `FUN_…` | module | role | label | evidence |
|---|---|---|---|---|
| ⚑ corrected `FUN_100234d0` | G_Interface | start game: level select or film, run, then pref-3 update and high-score gates (film / cheat / quit `DAT_100e01b8` / start sector > 1) | HIGH | listing `10023640..100238a8` (this file §2.2); was MED |
| ⚑ corrected `FUN_100214c0` | ~after G_Resource | insert 1–2 scores into the 15-row table (two prefs copies; P1 wins same-slot ties; two-player shift quirk) then name entry | HIGH | listing + simulation §3.1; was MED |
| `FUN_10021bd0` | G_Scores | scores screen / name entry (Return commits, easter eggs, empty → "Jar Jar Must Die"; stores the name as the player's default; commits prefs via `FUN_100047f0`) | MED | dump + key-branch listing §3.2 |
| `FUN_100047f0` | U_Prefs (engine-loop §10) | copy a prefs struct into the live prefs | MED | dump; single caller `FUN_10021bd0` |
| `FUN_10004c30` | U_Prefs (engine-loop §10) | copy the live prefs out (0x34f0) | MED | dump; listing offsets `10004d14..10004da0` |
| `FUN_100045f0` | U_Prefs (engine-loop §10) | shutdown: write the prefs file if dirty (always dirty after load) | MED | dump lines 2564/2587 |
| `FUN_10000630` | — (unattributed) | shutdown sequence, ends in `FUN_10048480` → ExitToShell | HIGH | listing `10000730`, `100484c0 bl 0x100d4464` |
| `FUN_10048480` | — (unattributed) | log, UnregisterAppearanceClient, **ExitToShell** | HIGH | listing |
| ⚑ corrected `FUN_10000fd0` | — (unattributed) | **non-fatal** "critical files missing" alert (`FUN_1000ced0(…,0)`) | HIGH | listing `10000fdc li r4,0x0`; pak-format.md called it fatal |
| `FUN_1000ced0` | — (unattributed) | error alert; arg 3 ≠ 0 → shutdown | MED | dump |
| `FUN_100461b0` | — (unattributed) | Gestalt('sysv') ≥ 0x0A00 (Mac OS X) | HIGH | listing |
| `FUN_1003d550` | G_UnitDefinitions | find unit by ID: entity's family member list, then the master list | HIGH | raw call sites `100155b4`, `10015d74`; entity+0x98 from `100144c8` |
| `FUN_10029c00` | G_Player | debug command `PLAYER AIRWEP\|AIR` / `PLAYER GROUNDWEP\|GROUND` (PLAYER handler `0x10007ff0`, unregistered → unreachable in 1.0.6): cycle a weapon type to the next available at the sector | HIGH | raw calls `10008408` ('PEAA'), `10008490` ('PEAG'); strings `0x100e41fc`/`4203`/`4207`/`4211` — ⚑ corrected (review wave 2, 2026-10-03) (conflict closed): was "console AIRWEP/GROUNDWEP" without the PLAYER prefix |
| ⚑ corrected `FUN_10012ca0` | G_GameObject (span) | integrate position; mode-1 keep test `x±hw` within [−128, 544], `y ≥ −128` (no half height), `y−hh ≤ 608`; mode 0 dead | HIGH | listing §8.6; bounds were MED |
| `FUN_1000b9a0` | — (display module, unattributed) | fade to black, 33 steps a=32→0, in-place compounding scale, ≥1 TickCount per step | HIGH | listing §6 |
| `FUN_1000ba70` | — (display module, unattributed) | fade from black to a snapshot, 9 steps a=0,4…32 | HIGH | listing §6 |
| `FUN_1001e9d0` | U_SpriteBlit | RGB555 two-source blend floor((A·a+B·(32−a))/32) | HIGH | listing §6 |
| `FUN_1001ec80` | U_SpriteBlit | in-place blend of a buffer toward a colour (draw type `COST`, a = 32 no-op) | MED | dump — ⚑ corrected (review wave 2, 2026-10-03) #C5: wording harmonised with function-roles.md |
| `FUN_10009ac0` | M_PixelBuffer | clone a pixel buffer (with contents) | MED | dump ("clonePtr") |
| `FUN_100069b0` | G_Game (span) | load a film: mode 2 = next "Demo" tag (counter G+0x24, wraps), else `last`; srand(film seed) | HIGH | dump + listing `10006b24` |
| `FUN_10009750` | G_Film (span) | replay exhausted: P1 cursor > P1 frames (signed) | HIGH | dump idiom brute-forced; listing `10009750..1000976c` evaluated signed — ⚑ corrected (review wave 2, 2026-10-03) #M1: review's "unsigned" not adopted (§7) |
| `FUN_100095b0` | G_Film.cc | save the film image as `film`/`last` "Last Film" in Data:Local, rebuild the tag index | HIGH | dump + listing `10005b00..10005b18` |
| `FUN_10004300` / `FUN_100043c0` | — (tag index, pak-format.md §2) | apply overrides: each Local record removes every non-Local record with the same (type, ID) | MED | dump — ⚑ label audit (review wave 2): was HIGH on dump only |
| `FUN_100009e0` | U_LinkedList.cc | append at tail (header {+0 count, +4 head, +8 tail}, node {+0 prev, +4 next, +8 data}) | HIGH | listing `10000a4c stw r31,0x4(r28)` (head if empty), `10000a5c stw r31,0x4(r3)` (old tail→next), `10000a70 stw r31,0x8(r28)` (tail = node), `10000a7c` count+1 (`$W/disasm-w2s5c.txt`) — ⚑ corrected (review wave 2, 2026-10-03) #C5: was MED (dump), INDEX #38 |
| `FUN_10000c00` | U_LinkedList.cc | unlink + free (iterator to prev) | MED | dump |
| `FUN_10022ef0` | ~after G_Scores | Caps-Lock pause loop; returns 1 when quit is requested meanwhile | MED | dump |
| `FUN_10024f90` | G_Interface | menu Quit: flash button 6, set leave-app flag | MED | dump |
| `FUN_10024de0` / `FUN_10024e10` | G_Interface | start attract demo (film 2) / play Last Film (film 1) | MED | dump — ⚑ label audit (review wave 2): was HIGH on dump only |

## INDEX updates (for merge)
- **#2 closed** → §8.7 (Local overrides every pak copy; pak duplicates both kept, first in list
  order wins; weapon cycle order = pak order in 1.0.6). The "Local first" insertion order stays
  tied to #1 (MED).
- **#4 closed** (remaining part) → §8.2: `FUN_10000630` ends in ExitToShell, so a fatal unit/plde
  parse error quits. ⚑ New conflict for pak-format.md §2.3 item 4: `FUN_10000fd0` is non-fatal.
- **#27 closed** → §5 (the full `noal` → `12gc` → `miof` → Mission Iris chain with timings; `leen`
  played once by `noal` S4). Residual ±1-tick items are this file's NR 3/4.
- **#30 closed** → §8.8 (writers of `G+0x39`). ⚑ corrected (review wave 2, 2026-10-03): the same closure as loose-ends-combat.md §2
  (they agree); INDEX #30 carries one merged closure line.
- Wave-1 file NRs closed here: player-physics.md NR 1 (§1), NR 5 (§8.1), NR 6 (§4);
  scoring-bonuses.md NR 1 (§3.1), NR 2 (§2.2–2.3, `DAT_100e01b8` = quit requested), NR 5 (§5);
  level-scroll-objects.md NR 2 (§8.5), NR 3 (§8.6), NR 7 (§8.9), NR 9 (§6); bosses.md NR 8
  (finale part, §5); unit-def-struct.md NR 3 (§8.2), NR 4 (§8.3), NR 5 (§8.4);
  weapons-projectiles.md NR 1 (§8.8), NR 8 (§8.7).
- New for the bank: engine-loop.md §10 row 0x129c "per-entry int (sector reached?)" → never
  written, dead (§3.1). engine-loop.md §7: films replay one level; Last Film is saved after every
  non-film session (§7).
