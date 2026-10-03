# Deimos Rising 1.0.6 — combat loose ends (wave 2, reader 6)

Wave-2 reader 6 (2026-10-03). The scope is a **checklist**, not an address range. It is the open
items D2/D4/D5/D8/D9/D10 named in the NOT RESOLVED sections of units-movement.md (U), spawn-and-waves.md (S),
weapons-projectiles.md (W), damage-health-death.md (D), player-physics.md (P), bosses.md (B),
scoring-bonuses.md (SC) and level-scroll-objects.md (L). It also covers the disputed `FUN_10017150` and the
accessors `FUN_10005ed0`, `FUN_10006090`, `FUN_10006110` and `FUN_100142f0`. **OUT:** everything those files
already settle at HIGH (I cite them, I do not re-derive them), registration/checksum code, and the
editor. Listings: `DisasmFuncs.java` on a private copy `$W/work-w2s6`. The outputs are
`$W/disasm-w2s6.txt` (trig, accessors, pickups, removers, spawn path, weapon handler), `-w2s6b.txt`
(`FUN_10006b50`, `FUN_10007170`, `FUN_100051a0`, `FUN_10026ee0`, `FUN_1002a150`, `FUN_10028170`,
`FUN_10033850`, `FUN_100146f0`, `FUN_10015b40`, …) and `-w2s6c.txt` (every `FUN_10033220` caller, `FUN_10037b50`,
`FUN_10037930`, `FUN_100144a0`). Raw-image scans were done with a scratch PPC opcode scanner. It
walks `$W/mem/10000000.bin` 4 bytes at a time and decodes the D-form `lbz/stb/lwz/stw/lfs/stfs` displacements.
Data census: scratch `unde.py`, which parses all 386 `$W/data/Game/unde/*.unde.txt` (772 files = 386 binary+txt).
Nothing here is behaviour-verified.

**Answer up front.**
- **Heading convention, final.** Two angle systems. The **compass** angle (data, entity `+0x138`) runs 0 = up and 90 = right,
  clockwise. The **internal** angle is h' = (180 − h) mod 360 (`FUN_10043040`), with vector (sin h', cos h'): 0 = down, 90 = right,
  180 = up. `FUN_10042cd0` is the exact inverse of that vector map. It uses truncation, which makes
  ~30–40 of the 360 headings lose 1° per velocity→heading round trip (§1.3).
- **Game `+0x39` = "level end reached".** It is set every tick from the scroll-end tick (`10006db4`) and
  cleared at session start and at each level transition (`10005524`, `10005828`, `10007248`). It
  gates five things: the respawn-invulnerability clear, the start of an overload and the cancelling of a running one, the spawning of the
  46 `canBeSpawnedOnlyWhenPlayersActive` units (mostly enemy bullets), and the once-per-level
  defence-bonus latch (§2).
- **Double removal is real, but inert in the shipped data.** No guard exists anywhere, so an entity removed by
  a direct remover gets `FUN_10036120` twice. A census shows that no unit able to take that path
  ever sits in a group of ≥ 2, and none of those units releases coins. The visible consequences (orphaned group members, a
  pool leak, double coins) therefore cannot occur in 1.0.6 data (§4.1).
- `'spec'` **is** compared in the pickup switch. Its case is a no-op that still consumes the pickup.
  The shipped pickups are coin ×4, shie ×2, exli ×1 and mult ×1 (§3). `+0xcf` (sticky invulnerability) is
  set only by the debug console command `GOD` (§3.3).
- `FUN_10017150` **is the rotation gate**, not a spawn-set reader (§7.1). `initiallyHuntsClosestPlayer`
  aims at the player closest to the **screen point (208, 0)**, not to the spawner (§7.2, ⚑).

## 0. Constants (all big-endian; code image for addresses < 0x100de330)
Command template: `python3 -c "import struct;c=open('$W/mem/10000000.bin','rb').read();d=open('$W/mem/100de330.bin','rb').read();u=lambda a:struct.unpack('>I',d[a-0x100de330:][:4])[0];…"`.
Read the TOC slot (`0x100e6330+disp`) and then the pointee.
| slot | → | values | used by |
|---|---|---|---|
| r2−0x6e2c `0x100df504` | `0x100d7318` | f32 0.0174533, **0.0**, **180.0**, **90.0**, **270.0** | `FUN_10042cd0` axis cases (+4..+0x10) |
| r2−0x6e20 `0x100df510` | `0x100d732c` | f64 0.01, 57.2957795, 2⁵²+2³¹, **57.29577951308232** (+0x18), **180** (+0x20), **360** (+0x28), **270** (+0x30), 0.0 | `FUN_10042cd0` quadrant offsets |
| r2−0x6ef0 `0x100df440` | `0x100d7204` | f32 0.5, 0.7, 0.9, **32.0** (+0xc), 0.0 (+0x10), **−100.0** (+0x14), **1.0** (+0x18), 1.4 | `FUN_10035900` (−32), `FUN_10037b50` |
| r2−0x702c `0x100df304` | `0x100d6fc8` | f32 0.0, 100.0, **1324366.0** | shield clamp / bias |
| r2−0x7038 `0x100df2f8` | `0x100d6fdc` | f64 bias, **100.0** (+8), **0.0** (+0x10) | `FUN_10027490` |
| r2−0x73b4 `0x100def7c` | `0x100d62fc` | f32 0.0, 0.0 | `FUN_10005ed0` default |
| r2−0x6e6c `0x100df4c4` | `0x100d72b0` | f32 **0.0, 100.0** | crosshair visibility reset (`FUN_1003af90` r31) |
| `DAT_100e0214` (r2−0x611c) | — | byte **1** in the data image | "Player Active Only Spawns" switch |
| flli 149/150/151/152/183/185–187 | — | 6.0 / 6.0 / **1.0** / **8.0** / 13.0 / 3, −4, 80 | `grep -n` of `$W/data/Game/flli/Game[gafl].flli.txt` (line n = index n−1) |

## 1. D2 — trig and heading, settled (U NR1, D NR9, S NR2, W NR7, B NR5)

### 1.1 Who builds what [HIGH]
The brief's "table builders" `FUN_10042b30`/`FUN_10042b80`/`FUN_10042ee0`/`FUN_10042f00` are
**accessors**. The only builder is `FUN_10042920` (D §1: cos → `0x10106d30`, sin → `0x10106790`,
360 floats each). Listings (`$W/disasm-w2s6.txt`):
| function | listing | role |
|---|---|---|
| `FUN_10042f00 @ 10042f00` | `cmpwi r3,0x168; bne; li r3,0` · `lwz r4,-0x6e34(r2)` · `rlwinm r0,r3,2; lfsx f1,r4,r0` | S[h] (sin table), h = 360 → 0, no other range check |
| `FUN_10042ee0 @ 10042ee0` | same with `-0x6e30(r2)` | C[h] (cos table) |
| `FUN_10042b30 @ 10042b30` | `bl 0x10042f00; stfs f1,0x0(r31); bl 0x10042ee0; stfs f1,0x4(r31)` | out = (S[h'], C[h']) |
| `FUN_10042b80 @ 10042b80` | `fmr f31,f1 … bl 0x10042f00; fmuls f0,f31,f1; stfs f0,0x0(r31); bl 0x10042ee0; fmuls; stfs f0,0x4(r31)` | out = speed·(S[h'], C[h']) |
| `FUN_10043040 @ 10043040` | `cmpwi r3,0xb4; bgt` → `subi r3,r3,0xb4; bl 0x1004ee30` (abs) / `subfic r0,r3,0x21c` | h' = (180 − h) mod 360, in place |

### 1.2 `FUN_10042cd0(&v) @ 10042cd0` full branch walk [HIGH — listing `10042cd0..10042e8c`]
Here x = `lfs f2,0x0(r3)` and y = `lfs f3,0x4(r3)`. f1 starts at 0.0 (`10042ce0 lfs f1,0x4(r4)`), and every early exit
jumps to `10042e64 fctiwz f0,f1` (truncate toward 0). Then `10042e70 cmpwi r3,0x168; blt; li r3,0`
maps ≥ 360 to 0.
| case | listing | result |
|---|---|---|
| x = 0 ∧ y = 0 | `10042cf4 fcmpu f1,f2; bne` / `fcmpu f1,f3; beq e64` | 0 |
| x = 0 ∧ y > 0 | `10042d10 fcmpo f3,f0; bgt e64` | 0 |
| x = 0 ∧ y < 0 | `10042d24 fcmpo f3,f0; bge` → `lfs f1,0x8(r4)` | 180 |
| y = 0 ∧ x > 0 | `10042d40 fcmpo f2,f0; ble` → `lfs f1,0xc(r4)` | 90 |
| y = 0 ∧ x < 0 | `10042d5c fcmpo f2,f0; bge` → `lfs f1,0x10(r4)` | 270 |
| x > 0 ∧ y > 0 | `10042d80 fdivs f1,f2,f3; bl atan; frsp; lfd f0,0x18(r31); fmul; frsp` | 57.2958·atan(x/y) |
| x > 0 ∧ y < 0 | `10042db4 fabs f0,f3; fdivs f1,f2,f0; bl atan; … lfd f0,0x20(r31); fnmsub` | 180 − 57.2958·atan(x/\|y\|) |
| x < 0 ∧ y > 0 | `10042df4 fabs f0,f2; fdivs f1,f0,f3; … lfd f0,0x28(r31); fnmsub` | 360 − 57.2958·atan(\|x\|/y) |
| x < 0 ∧ y < 0 | `10042e34 fabs ×2; fdivs f1,f1,f0` (\|y\|/\|x\|) `… lfd f0,0x30(r31); fnmsub` | 270 − 57.2958·atan(\|y\|/\|x\|) |
| NaN | no branch taken | 0 |
Each quadrant formula returns h' for v = s·(sin h', cos h'). I checked all four algebraically, e.g. quadrant 4:
\|cos\|/\|sin\| = tan(270 − h') → 270 − (270 − h') = h'. So `FUN_10042cd0` is the inverse of
`FUN_10042b80` in the **internal** system. Callers: `FUN_100146f0` (heading for later state entries,
U §4) and `FUN_10037b50` (burst/implode, followed by `FUN_10043040` → compass `+0x138`).

### 1.3 The convention, once and for all [HIGH]
| system | where | 0° | 90° | 180° | 270° | vector |
|---|---|---|---|---|---|---|
| compass h | data keys (`initialHeading`, `HeadingDegrees`), entity `+0x138`, `FUN_10043090`/`FUN_10042ad0` results | up | right | down | left | (sin h, −cos h) |
| internal h' = (180 − h) mod 360 | `FUN_10042b30/2b80` input, `FUN_10042cd0` output, orbit angle `+0xe0` | down | right | up | left | (sin h', cos h') |
Screen y grows downward (U §2.1). Data checks: projectile heading 0 flies up (W §3); the Shuriken
(`initialHeading 180`) has state "Move South…" (U §2.2).
**Round-trip truncation quirk [MED]:** `FUN_10042cd0` truncates. I simulated the listing's float/double steps
(float tables of sin/cos(i·0.0174533f), `fdivs`, double `atan`, `frsp`, ×57.29577951308232,
`fnmsub`, `fctiwz`) with IEEE libm. The heading of s·(S[h'],C[h']) comes back as h'−1 for 30 of the 360
headings at s = 1.0 or 4.0, 35 at 0.75 and 41 at 7.0 (e.g. 1→0, 2→1, 4→3, 13→12, 31→30, 46→45). So a moving unit
that re-enters a state (U §4 recomputes h' from v) can turn by 1°. A replica must keep the same
float tables, double atan and truncation. MED, not HIGH: the exact set depends on the Mac
MathLib `atan` agreeing to the last ulp.

### 1.4 Consequences for open items
- **B NR5, Pulse Tank [HIGH for the vector, MED for the timing].** `tapu` is spawned by the
  `Tank` set (`SetHeading`, 285°, absolute (480,140)) → `FUN_10033220` heading arg = req+0x10 =
  285, flag 1 (`100335b0 lwz r8,0x10(r24)`). In `FUN_10037b50` the flag branch at `10037e34..10037e50` does
  `FUN_10043040` → h' = 255, then `FUN_10042b80(255, s)` → v = s·(−0.9659, −0.2588). Here s = float draw
  `initialSpeedMin/Max` 0.7–0.8 (`10037bbc..10037bc4`). The tank's only state has `stateDelta 0`, so it
  keeps v forever (U §4 "D = 0 ⇒ keeps its spawn speed"). x falls by 0.676–0.773 px/tick, so it
  crosses from 480 to 416 in **83 ticks (s = 0.8) to 95 ticks (s = 0.7)**. y changes by −0.18…−0.21 px/tick, plus 1 px per tick
  while the terrain scrolls (ground unit, U §2.1).
- **Burst/implode y-flip [HIGH code, inert data].** `FUN_10037b50` takes d = member − groupPos
  (`10037cc0..10037cd0`) and stores `vy = −(uy·speed)` (`10037d28 fneg`), while `FUN_10037930` places members
  at gy **+** cy·r (`100379d8 fmadds`). So burst members fly outward horizontally but **inward**
  vertically (the top member moves down through the centre). `+0x138` matches the flipped
  velocity (`10037d30 bl 0x10042cd0` + `FUN_10043040`). Census: `doBurst`/`doImplode` TRUE in **0**
  of 386 units → inert in 1.0.6.

## 2. D4 — game flag `+0x39` (W NR1, INDEX #30)
Game object = `*(r2−0x7360)` (static, `PTR_DAT_100defd0`); `FUN_10005cf0 @ 10005cf0` = `lwz
r3,-0x7360(r2); lbz r3,0x39(r3); blr` [HIGH].

### 2.1 Writers — complete raw scan [HIGH]
Scan of the whole code image for `stb/stbu` with displacement 0x39, filtered to game-object bases:
| addr | function | value | context |
|---|---|---|---|
| `10006db4` | `FUN_10006b50` (per-tick game step) | **1** | `bl 0x10010000; rlwinm; cmplwi r0,0x1; bne; li r3,0x1; stb r3,0x39(r31)` — every tick on which the scroll step reports level end (L §3: progress ≥ level bottom) |
| `10007248` | `FUN_10007170` (level transition) | 0 | `li r0,0; stb r0,0x0(r27)` (+0x09) … `stb r0,0x39(r30)` (r30 = r2−0x7360) just before `bl 0x100064d0` (next level start) |
| `10005524`, `10005828` | `FUN_100051a0` (session) | 0 | session-init blocks that also clear +0x08..+0x0c |
`FUN_100064d0` (level start) clears +0x29 and +0x38 but **not** +0x39. The clear for level n+1 is
the one in `FUN_10007170`. Every other `stb …,0x39(…)` hit is a stack slot or another struct (the
`r1`-based hits in `FUN_10033850` are its local `0x39(r1)`).
⇒ +0x39 = **"level end reached"**: 1 from the scroll-end tick through the end-of-level tally until the
transition, and 0 during play. (L §7 labelled it MED "level ending"; now HIGH.)

### 2.2 What it gates — every reader [HIGH]
Direct callers of `FUN_10005cf0` (`$W/callers.txt`; `bl 0x10005cf0` found at four sites) plus one
by-value pass:
| site | gate | listing |
|---|---|---|
| `FUN_1002a150` state 4 | invulnerability `+0xce` is auto-cleared only while +0x39 = 0 (and now > enter + `entry_InvulnerabilityTime`, in game, not sticky) | `1002a1e8 lbz r0,0xce(r29); beq` · `1002a1f4 bl 0x10005cf0; bne skip` · `1002a20c lwz r3,0x8c(r3); add; cmpw r30,r0; ble` · `1002a228 lbz r0,0xcf; bne` · `1002a234 stb 0,0xce; stb 0,0xcf` |
| `FUN_10028170` overload start | return code 1 from `FUN_1003b3c0` starts the overload only if state 4, +0x39 = 0, `+0x210` = 0 | `10029140 lbz r0,0xc6(r31); cmplwi 4; bne` · `1002914c bl 0x10005cf0; bne` · `1002915c lbz r0,0x210(r31)` |
| `FUN_10026ee0` overload tick | with +0x39 set, a running overload is **cancelled** (same reset as leaving state 4: +0x210/+0x211 = 0, counters 0, glow off, +0x64 = 0x7fff) | `10026f60 lbz r0,0x210(r29); beq` · `10026f6c bl 0x10005cf0; beq tick` · `10026f7c li r3,0; … stb r3,0x210(r29)` |
| `FUN_10033220` spawn gate | units with `canBeSpawnedOnlyWhenPlayersActive` (unit +0x12a) spawn only if `DAT_100e0214` ≠ 0 **and** some player is in state 4 (`FUN_10006110`) **and** +0x39 = 0; else the request is dropped (after its size/appears draws, S §3.1) | `100332cc lbz r0,0x112(r27)` (r27 = unit+0x18) · `100332d8 lbz r0,-0x611c(r2); beq drop` · `100332e4 bl 0x10006110; beq drop` · `100332f4 bl 0x10005cf0; bne drop` |
| `FUN_10028170` param 7 | `FUN_10006b50` passes +0x39 (`10006c10 lbz r9,0x39(r31)`) → r19; first tick with it set and `+0xd0` = 0: `+0xd0` = 1, spawn plde+0xd0 unit, defence bonus (P §6.1) | `10028198 or r19,r9,r9` · `10028f3c rlwinm. r0,r19; beq` · `10028f44 lbz r0,0xd0(r31); bne` · `10028f54 stb r0,0xd0(r31)` |
Consequences:
- **After the level-end trigger, enemy fire stops.** 46 units have `canBeSpawnedOnlyWhenPlayersActive`
  TRUE (census: `talb tlbf scl2 irmp bh02 s2li s2bu sc3l scre shur ppbu s3bu psbu bu01 ngbu
  ppbf psbf fgbu jgbu scli …`, mostly `*bu`/`*bf` bullets and flashes). The same gate also suppresses them while no player
  is in state 4 (entering, dying or respawning). [HIGH code + census]
- `DAT_100e0214` defaults to 1. Its only writer is an undecompiled console handler at `0x10039080` (`lbz;
  cntlzw; rlwinm; stb r0,-0x611c(r2)` = toggle). That handler prints "Player Active Only Spawns ON/OFF" (strings
  `0x100ec065`/`0x100ec082`) and is reached through the pointer at `0x100e0980` (console table,
  command `PLAYERACTIVESPAWNS`). With it OFF those 46 units **never** spawn. [HIGH raw bytes]
- Level-start invulnerability (P §4.4 / P NR9): `FUN_10027de0(p,1,0)` at level end sets `+0xce`.
  `+0x39` keeps it from clearing through the tally. Then `FUN_10007170` clears +0x39 and
  `FUN_100269a0` re-enters state 2 → `FUN_10029cc0` → state 4 with enter = now (P §4.1). So on level
  2+ the ship is invulnerable until 61 ticks after it becomes active. On **level 1** `+0xce` = 0 from
  the constructor `FUN_10026260`, so there is no such window. [HIGH chain; P §4.4 wording "the level-end flag is never
  cleared" should read "+0xce is never cleared by level start"]

## 3. D5 — pickups and player flags (SC NR3, D NR4, W NR2, L NR5)

### 3.1 `FUN_10037580(player r3, entity r4) @ 10037580` — the full switch [HIGH — listing `10037580..100376f0`]
Binary compare tree on `pickup_Type_ID` (unit +0x4d4, `100375a8 lwz r5,0x4d4(r6)`). r31 = 1 on
entry (`10037588 li r31,0x1`) is the return value (1 = consumed).
| type | compare | action | returns |
|---|---|---|---|
| `grnd` | `100375a0 lis r4,0x6772; addi …0x6e64; beq 10037648` | `bl 0x10027dd0` (player +0xce) → if set `li r31,0` | 0 if invulnerable, else 1 (no other effect) |
| `air ` | `100375cc lis 0x6169; addi 0x7220; beq 10037630` | same | same |
| `coin` | `100375b8 lis 0x636f; addi 0x696e; beq 10037660` | if value (+0x4dc) ≠ 0: `FUN_100275b0(p, value)` (money += value) then `FUN_10012bc0(p, 0x7fff, 6, 0)` (player glow) | 1 |
| `exli` | `100375e0 lis 0x6578; addi 0x6c69; beq 1003769c` | `FUN_10026d70(p, 1)` (one life, cap, life_Spawn_ID) | 1 |
| `mult` | `10037608 lis 0x6d75; addi 0x6c74; beq 10037690` | `FUN_10029b20(p)` (multiplier step, state 4 only) | 1 |
| `shie` | `100375f4 lis 0x7368; addi 0x6965; beq 100376ac` | f1 = (float)value via `xoris 0x8000`/magic (`r2−0x6ee8`) → `FUN_10027490(p, f1)` | 1 |
| `spec` | `1003761c lis r3,0x7370; addi r0,r3,0x6563; cmpw; beq 100376d8; b 100376d8` | **nothing** — both arms go to the exit | 1 |
| anything else | falls to `100376d8` | nothing | 1 |
**SC NR3 settled:** both `'shie'` and `'spec'` are in the listing. The decompiler dropped `'spec'`
because its case is empty (`'spec'` sorts above `'shie'`, so it sits in the `bge` arm at `10037604`). The value of `pickup_Value_INT` is ignored by
`exli`, `mult`, `air `, `grnd` and `spec`.
**Caller (pickup branch of `FUN_10033850`) [HIGH — `100341d0..10034224`]:** `lwz r3,0x4d4(r31)`; `≠
none` → `bl 0x10037580`; on return 1: killer = `FUN_10026c90(player)` (index) → `FUN_10016300(e,
index, now)` (destroy: +0xcb, +0xd9 = index, +0xda = 1, destruct particle/sound/spawn) → `stb
1,0xca(r19)` (collected). The collected pickup **awards no score** (score only comes from `FUN_10014f10`,
which this branch does not call) and releases **no coins** (`FUN_10036120` skips both coin blocks when +0xca is set:
`100361c4 lbz r0,0xca(r26); bne 1003634c`). The per-player loop re-tests `+0xcb` first
(`10034110 lbz r0,0xcb(r19); bne exit`), so if both ships touch it the same tick **P1 wins**. A pickup
refused with 0 stays and can be taken by P2 or later.

### 3.2 Shield pickup cap `FUN_10027490(p, f1) @ 10027490` [HIGH — listing]
`100274bc lbz r0,0xc4(r3); beq exit` (player in game) · `100274c8 lfd f0,0x10(r30)` = 0.0;
`fcmpu f0,f31; bne` (delta ≠ 0, else exit) · `100274d8 bl 0x10027540` (get) · `fadds f1,f1,f31` ·
`100274e4 lfd f0,0x8(r30)` = 100.0 `fcmpo; ble` → else `lfs f1,0x4(r31)` = 100.0 · `100274f8 lfd
f0,0x10(r30)` = 0.0 `fcmpo; bge` → else `lfs f1,0x0(r31)` = 0.0 · `bl 0x10027560` (set).
So shield = **clamp(shield + value, 0, 100)**. Exactly 100 is allowed, and the pickup is taken even at 100.
Getter/setter raw bytes: `10027540 lwz r4,-0x702c(r2); lfs f1,0xa8(r3); lfs f0,0x8(r4);
fsubs f1,f1,f0` and `10027560 … fadds f0,f0,f1; stfs f0,0xa8(r3)`. The stored shield is a **single-precision
float biased by 1324366.0** (P §3). Consequence [HIGH arithmetic]: 1324366 lies in [2²⁰, 2²¹), so the
stored value has a resolution of **0.125**. Every shield value (hit costs included) is quantised to
1/8 point on store.

### 3.3 Player `+0xce` / `+0xcf` and `FUN_10027de0`/`FUN_10027db0` [HIGH]
`FUN_10027de0(p, set r4, sticky r5) @ 10027de0` (listing `10027de0..10027e40`): returns unless in
game; `set` → (`sticky` → `+0xcf = 1`) and `+0xce = 1`; `!set` → if `+0xcf` = 0 clear both; else
clear both only if `sticky`.
All writers of `+0xce`/`+0xcf` (decompile grep, confirmed by raw `bl` scan to `0x10027de0`):
| writer | effect |
|---|---|
| `FUN_10026260` (constructor) | both 0 |
| `FUN_10027e50` death (`10028120`) | `+0xce = 1` if in game |
| `FUN_10006b50` level end (`10006f20 li r4,1; li r5,0; bl 0x10027de0`) | `+0xce = 1` for every in-game player |
| `FUN_1002a150` state 4 (§2.2) | both 0 after the timer, unless sticky |
| console `GOD` (undecompiled handler, `10008508..10008518`: `bl 0x10027dd0; cntlzw; rlwinm` → r4 = !current; `li r5,0x1; bl 0x10027de0`) | toggles `+0xce` with **sticky = 1**; strings "GOD", "Player Invulnerability ON/OFF" at `0x100e4218…` |
So `+0xce` = invulnerable and `+0xcf` = **debug god-mode latch**, never set in normal play. What `+0xce` does
in normal play: the player hit `FUN_10027100` ignores shield loss (P §3), and `air `/`grnd` pickups are
refused (§3.1). Shield, coin, life and multiplier pickups still work while invulnerable.
`FUN_10027db0 @ 10027db0` = `lbz r3,0xd8(r3); neg; or; rlwinm 1,31,31` = (player +0xd8 ≠ 0). Player
+0xd8 is the coin-tally state that `FUN_10027670` sets to 1 (`1002769c li r0,1; stb r0,0xd8(r30)`),
so it means "end-of-level coin tally started". It is unrelated to invulnerability (L NR5 paired the two; SC and P rows had it MED). [HIGH]

### 3.4 Shipped pickup census [HIGH — `unde.py` over 386 units]
| unit | name | type | value | effect |
|---|---|---|---|---|
| `cass` / `casg` / `cals` / `calg` | Cash Small Silver/Gold, Large Silver/Gold | `coin` | 1 / 5 / 10 / 50 | money += value; player glow 0x7fff for 6 |
| `pism` | Pickup – Shields Mini | `shie` | 20 | shield +20 (cap 100) |
| `pish` | Pickup – Shields | `shie` | 100 | shield → 100 |
| `piel` | Pickup – Extra Life | `exli` | 1 (unused) | +1 life (cap `life_MaxNum`) |
| `pimu` | Pickup – Multiplier | `mult` | 0 (unused) | multiplier 1→2→3→4→5→10 |
The other 378 units are `none`. `air `, `grnd` and `spec` occur nowhere. `pickup_MultiplierSpawn_ID` (+0x4d8) is `none` everywhere, and
its only readers are the resource loader `FUN_1003e680` and the reference lister `FUN_1003ec70` (raw scan
of `lwz …,0x4d8`), so it is inert. `pism` arrives as the `destructSpawn_ID` of `csht` (Cap – Shield
Station) and `sess` (Secret – Small Shield); `pish` comes from a spawn set of `irsm` (Iris – Shield Major).

## 4. D8 — removal bookkeeping (S NR1/NR4/NR7/NR8, D NR2/NR3; INDEX #29, #32)

### 4.1 The double `FUN_10036120` [HIGH code; HIGH census that it is inert]
- `FUN_10036120(group, e, destroyed, byPlayer) @ 10036120` has **no** `+0xcb` guard. The listing runs
  `1003614c lbz 0x13e` → children → `10036194` kills++ → `100361b4..10036348` coins → `1003634c`
  `FUN_10016300` if destroyed → `10036374 stb 1,0xcb` → `10036378..80` `+0xa8 −= 1` → return (+0xa8 < 1 ∧
  ≠ PERM).
- None of the five direct removers tests `+0xcb` (their only field loads are `+0x144`/`+0x9c`
  owner match, `+0xd8` player, unit `+0x4` and state `+0x329`/`+0x32a`; raw listing lines
  `10036474..100364c0`, `1003659c..100365d4`, `10034c4c..10034ca8`, `10034e8c..10034ea4`,
  `10036c8c..10036cb8`). None of them unlinks the entity or returns its pool slot (`FUN_10038810`
  is called only by the reaper).
- The reaper `FUN_10036610` calls `FUN_10036120` for **every** listed entity with `+0xcb`, then
  unlinks and frees it. An entity removed directly therefore gets `FUN_10036120` **twice**. The
  second call's `destroyed` = `+0xda`, which `FUN_10016300` set to 1 in the first call when
  destroyed. Its `byPlayer` = `+0xd9 ≠ 0xff`, and `+0xd9` was passed through unchanged.
- Effects of the second call: kills `+0xac` +1 again (if destroyed) and **live `+0xa8` −1 again**. Coins
  are spawned again only if the entity had already been killed by a player earlier in the same tick
  (`+0xd9` = player). Direct callers: `FUN_100363c0`/`FUN_100364f0` (children, from inside
  `FUN_10036120`), `FUN_10034b90(player)` (player death `FUN_10027e50`), `FUN_10034de0(serial)`
  (`FUN_10027e50`, `FUN_10029fe0`: the multiplier display entity) and `FUN_10036be0(unit, player,
  destroyed)` (`FUN_10033220`, `deleteExistingEntitiesOfThisTypeOwnedByPlayer`).
- **Worst case (modded data only):** a non-PERM group of n ≥ 2 whose members are removed directly
  reaches `+0xa8 ≤ 0` while members are still listed. The reaper then frees the group (`FUN_10000af0`
  frees the links only) and `break`s, which orphans the remaining members: they are never updated or
  drawn, their pool slots leak (live count stays up and the 1000 cap at `FUN_10033220` comes closer) and their
  reaper steps are skipped.
- **Census [HIGH]:** no unit with `numInGroupMax ≥ 2` has any state with
  `canBeDestroyedOnOwnerDestruction` or `canBeDeletedOnOwnerDeletion`. The five
  `deleteExisting…` units (`noel nodb noal nosw nole`) have group size 1, and of the 73 removable
  parent→child pairs (54 parents with `destructDestroyChildren`, 58 with `destructDeleteChildren`)
  none has a child group > 1 or a destroyable child that releases coins or has a score. A group of 1 hits `+0xa8` = 0
  on the direct call (the "empty" return is ignored by the removers) and −1 on the reaper call, which returns
  "empty" → the group is freed normally. A PERM group is never freed. The skipped reaper step
  `_DAT_100e0218 −= 1` is a debug counter with **no reader** (raw scan of `-0x6118(r2)`: only
  `FUN_10032bd0`/`FUN_10032e60` reset, `FUN_10035cd0` ++, `FUN_10036610` −−).
  ⇒ **No visible effect in 1.0.6.** The replica should still call it twice so that modded data behaves as the original.

### 4.2 Entity `+0x13d` / `+0x13e` / `+0x13c` — every access (raw scan 0x10011000–0x10045000) [HIGH]
| field | writers | readers | meaning |
|---|---|---|---|
| `+0x13c` | `FUN_100142f0` (0), `FUN_10035cd0` (req+0x1c), `FUN_10033850` `10034548` (ground-obstacle stop) | `FUN_10015b40`, `FUN_10017a10`, `FUN_10033850`, `FUN_10035cd0`, `FUN_10037b50` | stationary |
| `+0x13d` | `FUN_100142f0` (0), `FUN_10035cd0` (`10035f30 lbz r0,0x1d(r22); stb r0,0x13d(r28)`) | **only** `FUN_10015b40` `10015da4` | terrain-effects flag. Its sole use: a spawn set whose unit has `terrainEffect` fires only if the spawner is not stationary **and** has +0x13d (S §2.5) |
| `+0x13e` | `FUN_100142f0` `10014474` (0, r5 = 0 from `100143a4 li r5,0x0`), `FUN_100144a0` `1001460c` (1) | **only** `FUN_10036120` `1003614c` | "has ≥ 1 spawn-set record". `FUN_100144a0` sets it inside the loop that allocates one zeroed 0x18 record per spawn set of every state (`100145b0 lwz r3,0x5dc(r25)` … `10014600 bl 0x1000cd90` (0x18) … `stb 1,0x13e`) |
So `destructDestroyChildren`/`destructDeleteChildren` act **only** for units with spawn sets (the children are
found by owner id `+0x144`). Census: all 54/58 such parents have spawn sets. **D NR3 closed:**
`FUN_100142f0 @ 100142f0` is the entity field reset (callers `FUN_100141a0`, pool allocator
`FUN_100385d0`). It zeroes +0xac…+0xda and +0x13c..+0x13e and sets +0xd8 = +0xd9 = +0x118 = −1
(`1001439c li r6,-0x1`).

### 4.3 Entity `+0xd8` owner index for spawned entities (D NR2, INDEX #32) [HIGH]
`FUN_10035cd0` sets `+0xd8 = req+0x14` (`10035d94 lbz r0,0x14(r22); stb r0,0xd8(r28)`) and `+0xd9 = −1`
(`10035d9c`). The req+0x14 values by source:
- All five request templates (`0x100e3ca4` game, `0x100e91d4` player, `0x100eb41c` entity group, `0x100ecd14`
  weapon) hold `+0x14 = 0xff` (data-image dump; each is 0x2c bytes: id, x, y, +0x0c flags, +0x10
  heading, +0x14 player, +0x18 editor heading, +0x1c/+0x1d stationary/terrain, +0x20 owner ptr, +0x24 owner
  serial, **+0x28 f32 1.0**).
- Request sites that store `+0x14` (per-site scan of stores at base+0x14 for every `bl 0x10033220`):
  spawn sets (`10016174`), destruct spawn (`10016478`), water impact (`10016b90`), deletion spawn
  (`10036828`) and `FUN_10014f10` hit spawn (`10015238`) all copy the **source entity's `+0xd8`**. The player
  sites (`FUN_10026d70`, `FUN_10027100`, `FUN_10027670`, `FUN_10027e50`, `FUN_10028170`, `FUN_10029cc0`,
  `FUN_10029fe0`; but not the death coin drops `10028044..100280ec`, which keep 0xff) and the weapon launchers (`1003c5f8`, `1003c8bc`, `1003ca9c`, `1003b5e4`, `1003b7c0`,
  `1003c1e0`, `1003c3f0`) store the player index. The level objects (`FUN_10033090`), notices (`FUN_100064d0`,
  `FUN_10006b50`) and coin releases (`FUN_10036120`) keep the template's 0xff.
⇒ `+0xd8` is inherited along the spawn chain from the root. Every chain that starts at a level object
or notice carries **0xff**, so enemy-shot kills never credit a player. A chain that starts at a player launch or
a player-side spawn carries that player's index. Pickups spawned from destroyed caps carry 0xff.

### 4.4 req+0x28 speed multiplier (S NR8) [HIGH]
Of the 32 reachable `bl 0x10033220` sites (⚑ corrected (review wave 2, 2026-10-03) #M2: the code image holds **34** — a raw
scan for `bl` with target `0x10033220`; the two extra, `0x10038ce4` and `0x10038ed8`, lie in the
undecompiled G_EntityGroup debug-command handlers after `FUN_10038810`, which are never registered
and so unreachable, messages-notices-console.md §5.2; they are excluded here), all but one write req+0x28 only as the template halves (`sth rX,
base+0x28 / +0x2a` = 1.0; the struct is copied 2-byte aligned). The exception is `FUN_1003c4f0` (ground launcher):
`1003c6cc fdivs f0,f1,f0; 1003c6d0 stfs f0,0x9c(r1)` (base 0x74) = `max(0, trunc(h.y − crosshair.y)) /
|crosshairYOffset|` (W §3). The consumer `FUN_10037b50` does `10037e58 lfs f0,0x18(r31)` (1.0) `fcmpu f0,f30;
beq` → otherwise `vx·=m, vy·=m`. **Only Plasma Bomb children fly faster or slower.**

### 4.5 Same-tick processing of new entities (S NR4) [HIGH]
- The lists are doubly linked and append at the tail (`FUN_100009e0`). The iterator follows `next` (`FUN_10000e10`).
  `FUN_10033850` re-reads both counts every iteration (`100345a0 bl 0x10000ce0; cmpw r21,r3; blt`
  members, `100345c0 bl 0x10000ce0; …cmpw` groups). Nothing is unlinked during the pass (only the
  reaper, after it, `100345d4`).
- `FUN_10033220` puts a request either at the tail of the PERM member list (1 member and no owner,
  or the owner is in PERM) or in a new group at the tail of the active list (S §1.2). PERM is created
  first. Requests that carry an owner (spawn sets, destruct spawns, `FUN_10014f10` hit spawns — all
  set req+0x20) therefore land **ahead** of the iteration point: at the PERM tail when the spawner is
  itself in PERM, otherwise in a new tail group. **Exception:** owner-less singletons requested
  *during* the pass by player-side code called from the collision step (`FUN_10027100` hit spawns,
  `FUN_10027e50` death spawn/coin drop, `FUN_10026d70` life spawn and `FUN_10029fe0` multiplier
  display via `FUN_10037580`; player template, +0x20 = 0) go to the PERM tail. They are reached in the
  same pass only if the pass is still inside PERM, otherwise next tick.
- First visit: `10033a54 lwz r4,0xb0(r19); subi; stw; cmpwi 0; ble process` / else `10033a74 stw
  r17,0xa4(r19)` (state start = now while waiting).
⇒ Entities requested **before** `FUN_10033850` in the tick (player weapons, level objects,
notices) or **during** it with an owner (spawn sets, damage destruct spawns, hit spawns) get their first
`+0xb0` decrement, and with a group delay of 0 a **full update, on the spawn tick**. Entities
requested by the reaper `FUN_10036610` (deletion spawns, coin releases, group-kill coins, the
owner-destroy chain's destruct spawns) are first seen the next tick. While `+0xb0 > 0` the state
start time `+0xa4` is restamped every tick, so state timers count from appearance.

## 5. D9 — spawn geometry (B NR4, U NR7, S NR3; INDEX #20 residual)

### 5.1 The −32 x shift applies to level objects only [HIGH]
The 32.0 constant (slot r2−0x6ef0, +0xc) is loaded at five sites (`grep -0x6ef0(r2)`): `FUN_10035900`
`10035908`, `FUN_10037b50`, `FUN_10037930`, `FUN_10037ed0` and `FUN_10033850`. Only `FUN_10035900` uses
+0xc: ground-layer level-object groups get `x −= 32` at level load. In the request path `FUN_10033220`
copies `group.x = req.x` unchanged (`1003351c lfs f0,0x4(r24); stfs f0,0x9c(r26)`), and only y is
converted for map rows (`10033524 lbz r0,0xc(r24)` → `FUN_1000fec0` − y). `FUN_10035bf0`/`FUN_10035cd0` have no x
adjustment. `FUN_10037930` uses only +0x10 (0.0). ⇒ **Spawn-set children get no shift.** The
sector-1 Pulse Tank (absolute (480,140)) appears at x **480**, 64 px right of the 416-px area (B §3.3 assumed this).

### 5.2 Orbit/lock/link and `+0x10/+0x14/+0xe0` [HIGH]
- `+0x10/+0x14` = velocity (vx, vy), px/tick (`FUN_10037b50` `10037c74 stfs f0,0x10(r30)`, `10037c80
  stfs f0,0x14(r30)`; copies `+0x100/+0x104`, `+0x108/+0x10c` = desired, `+0x110/+0x114` = accel 0).
- Orbit init (S §4): angle `+0xe0` = `FUN_10043040(FUN_10042ad0(owner, self))`. `FUN_10042ad0` gives the
  compass angle of self − owner, and the mirror turns it into internal h', so `FUN_10042b80(+0xe0, r)` =
  r·dir(self − owner) and the first orbit step is continuous [HIGH by §1.3].
- Orbit tick `FUN_10037350` (`1003741c..100374e8`): skipped if owner pos == own pos
  (`fcmpu; beq 1003756c`). If radius `+0xdc` == 0.0 or `step = trunc(vx)` == 0 → pos = owner + offset. Otherwise
  `+0xe0 += step` (wrap: `cmpwi 0x167; ble; subi 0x168` / `cmpwi 0; bge; addi 0x168`) → pos = owner +
  `FUN_10042b80(+0xe0, +0xdc)` (`10037490 lfs f1,0xdc(r31); bl 0x10042b80; fadds ×2; bl 0x10012930`).
  Positive vx raises h', which on a y-down screen moves bottom → right → top: **counter-clockwise on
  screen**, `trunc(vx)` degrees per tick. vx ramps to `stateMaxSpeed` by `stateDelta` (U §5.6).
- If neither the owner link nor the owning player exists, all three helpers do nothing (the
  `cVar1` gate). The position then follows the integrator, so an orbiter whose owner died moves at vx
  px/tick in a straight line [MED — integrator order from U §1; no shipped orbiter checked].

## 6. D10 — weapon handler and crosshair (P NR2/NR4, W NR5/NR6, L NR6, B NR6)
The handler sits at player+0x240, so handler offset k = player offset k+0x240.

### 6.1 `FUN_1003b3c0` return codes (P NR2) [HIGH — cites W §2.3/§2.6, listing re-checked]
The return byte `local_c8` is 0 by default. It becomes **2** when a power-up button is released in states 1/2 (`FUN_1003b3c0` for
ground `+0x31`, air `+0x11`; state → 3, `FUN_10034ce0(now, activation serial)`), or when the air
machine `FUN_1003c0d0` hits max power with `DoReleaseOnMaxPowerLevel`. It becomes **1** when `FUN_1003c0d0` passes
`activation + powerup_Air_OverloadTime` (state 1 → 2). The ground copy never sets a code (W). In
`FUN_10028170`, 1 starts the player-side overload under the §2.2 gate, and 2 takes the `bVar8 < 3` branch (W §2.6).
`local_1a8` ("switched") = a select happened → `FUN_10029f60` (sprite refresh).

### 6.2 Crosshair flag `+0x360` = handler `+0x120` lifecycle (P NR4) [HIGH]
Raw scan for `stb …,0x120(…)` / `0x360(…)` in the code image: the only handler-side store is
`1003b9ec stb r4,0x120(r22)` with r4 = 1, run on **every** `FUN_1003b3c0` call (state 4 and `+0x84` = 1.0).
**No clearer exists.** `FUN_1003af90` (reset at level start/respawn) and `FUN_1003ade0` (setup) never write it,
and the other 0x120 hits belong to other structs (`FUN_100222f0`, `FUN_10024xxx`, score/prefs).
Readers: `FUN_10028170 10029704` (crosshair adjust), `FUN_1003bab0` (early return), `FUN_1003bd00`.
⇒ It is 0 only until the player's first active tick of the session and 1 forever after. "Crosshair shown" is
effectively always true. Also, `+0x121` ("locked") is reset to 0 every call (`1003ba08`).
**flli 149/150:** `FUN_1003ade0` stores F149 → handler `+0x124` and F150 → `+0x128` (`1003ae48`,
`1003ae5c`). `+0x124` is read once, in `FUN_1003af90` (`1003b148..1003b15c`: crosshair object visibility
`+0xf4` = 0.0, required `+0xf8` = 100.0, delta `+0xfc` = `+0x124`). `+0x128` has **no reader** (scan of
`lfs/lwz …,0x128` in 0x10026000–0x1003e000 and of player offset 0x368). ⇒ After every level start
and respawn the crosshair fades in **0 → 100 at 6 per tick** (17 ticks, `FUN_10012750` step each handler
tick). `Crosshair_FadeOutPercentageRate` is dead. Quirk: the very first `FUN_1003af90` call
inside `FUN_1003ade0` runs **before** `+0x124` is stored, so the session's first reset uses the
uninitialised delta. That reset is overwritten at level start (`FUN_100269a0` → `FUN_1003af90(h,1)`).

### 6.3 The unresolved branch in the crosshair code (W NR6) [HIGH]
`bVar17` (r15) = **"ship pinned against the bottom edge this tick"**. `10029618 li r3,0xb7` (flli 183
`Player_TopGameAreaLimit` 13) → if `y − halfH(+0x30) < 13` → y = 13 + halfH, vy = 0 (no flag;
`1002966c fcmpo; bge`). Otherwise if `y + halfH > (int)VisibleGameHeight` (r16 = trunc(flli 55) = 480, set at
`10029584`) → y = 480 − halfH, vy = 0, **`100296e0 li r15,0x1`**. Crosshair (`10029704..`): `cmplwi
r14,0` (r14 = player `+0x1fe`, down input) and `rlwinm. r0,r15` → both set: adj += 3 (cap 80);
else if adj > 0: adj += −4 (floor 0) (P §2.6). So holding down while pressed against the bottom pulls the
crosshair in.

### 6.4 Handler `+0x08` (W NR5) [HIGH]
Raw scan of `stb …,0x8(…)` in 0x1003a000–0x1003e000: `1003ae34` (`FUN_1003ade0`, 0, after its
`FUN_1003af90` call), `1003afd4` (`FUN_1003af90`, `li r29,1` → **1**), `1003b8fc` (select, 1).
Its only reader is `FUN_1003bb30` (`lbz r3,0x8(r3)`), called each frame by the score bar `FUN_100317e0`. ⇒ The flag is
never cleared after level start. The score bar re-runs the weapon-preview lookup `FUN_1003bb40` every
frame from the first level start on, which is harmless. (`FUN_1003bb20` is not a clearer: raw bytes `c0230024` = `lfs
f1,0x24(r3)`, a power-level getter.)

### 6.5 Weapon carry-over (L NR6) [HIGH — listing `1003b0ac..1003b134`, `FUN_1003cdb0` `1003cdb0..1003ce58`]
`FUN_1003af90(h, arg)`: resets the transient fire, power-up and bomb state (`+0x78/+0x7c/+0x84` = 0, …). Then any pending
ground def `+0x54` is applied (`FUN_1003b180(h,'PEAG',…)`). With **arg 1** (level start,
`FUN_100269a0`), `FUN_1003cd30(sector)` = the first `PEAA` def whose `minimumLevelAvailable` **equals**
the sector; if one exists → equip it and drop the pending air def `+0x50`, otherwise keep the current air weapon (and
keep `+0x50` pending). With **arg 0** (respawn `FUN_10029cc0`) the pending `+0x50` is applied. Shipped
minima: Ion Cannon 1, Bacta Gun 2, Rear Gun 3, Photon Beam 5. So the game auto-switches to Bacta on
entering sector 2, Rear Gun at 3 and Photon at 5, and otherwise carries the weapon over. Start weapon `FUN_1003cdb0(sector)`
= the `PEAA` def with min ≤ sector ≤ max and the **highest** min (`1003ce28 lwz r0,0x13c(r30); cmpw
r0,r4; bge skip`, first wins ties) — not inverted (agrees with the fix pass).

### 6.6 Plasma Bomb count per press (B NR6) [HIGH — listings `1003beb0..1003bf74`, `1003b964..1003b9d0`]
Press (`FUN_1003b3c0`): ground button down (r24), previous-tick ground button up (`1003b9a8 lbz
r0,0x9(r22); bne`), ground power-up idle (`+0x31` = 0), no salvo pending (`+0x84 ≤ 0`) →
`FUN_1003beb0`: if `now > +0x78 + delayBetweenLaunches (def+0x1b0)`: `n = sector + trunc(F151) − 1`
(`1003beec bl 0x10005cd0; li r3,0x97; …fctiwz; add; subi`), `n = min(n, trunc(F152))`
(`1003bf38 cmpw; ble; stw`), `+0x84 = n − 1`, launch now, `+0x78 = +0x7c = now`. Salvo: while `+0x84 > 0`,
when `now > +0x7c + delayBetweenLoadLaunches (def+0x1b4)` → launch, `+0x84 −= 1`, `+0x78 = +0x7c = now`
(`1003b964..1003b998`). F151 = 1.0 and F152 = 8.0, Plasma Bomb `delayBetweenLaunches 4`,
`delayBetweenLoadLaunches 1`, `autoRepeat FALSE`. ⇒ **bombs per press = min(sector, 8)**, released at
t, t+2, …, t+2(n−1). The next press is accepted only after a release/re-press and once `now >` last launch + 4. The guide's
"increases in power as you progress" is this count. A bomb's damage does not change (B NR6: 0.4 in every sector).

## 7. Accessors and the disputed function

### 7.1 `FUN_10017150 @ 10017150` — ruling: rotation gate [HIGH]
Listing `10017150..100172c4`: state = `unit + s·0x5e0 + 0x4e0` (`1001716c..1001717c`); `10017180 lbz
r0,0x303(r31)` (`stateDoRotateToTarget`) = 0 → `stb 0,0xc1(r26)`, return 1. Otherwise decrement `+0xc4`
toward 0 (`1001719c..100171c0`); `+0xc4 > 0` → hold. Otherwise loop over the state's spawn sets: skip if
`Spawn_ID` (+0x20) = `none` (`10017224 lwz r3,0x20(r3); subis 0x6e6f; cmplwi 0x6e65`). Hold if the
runtime record is active (`10017250 lbz r0,0x14(r3)`), the set has `PauseAnyRotationWhileSpawning`
(`1001725c lbz r0,0x48(r25)`) and `0 < remaining (+8) < volleySize (+0xc)`
(`10017268..1001727c`). If not held → `bl 0x100172d0` (turn toward target) and return its result. It reads
no spawn position, unit or offset and issues no request. **The three files that call it a rotation
gate are right. damage-health-death.md §1/§4 "spawn-set reader" (LOW, one grep hit) should be
corrected.** Its only caller is `FUN_10015b40` (the spawn-set executor calls it first, so the confusion is
understandable).

### 7.2 `FUN_10005ed0(ref r3, out r4) @ 10005ed0` — closest active player [HIGH] ⚑
Out = (0,0) (`10005ed8 lwz r5,-0x73b4(r2)` → `0x100d62fc`). It counts players in state 4
(`FUN_10026c60(p,4)`). With 1 player, out = that ship's position. With 2, it computes the distance from **ref** (`10005fd4..10006000`:
`lfs …0x4(r29)`, `lfs …0x0(r29)` with r29 = r3; `fmadds; fctiwz; bl 0x10042f20`) and keeps the smaller
(`10006028 fcmpo f0,f31; bge skip` → ties keep P1). Returns 1 if any player is active. Its only caller is `FUN_10037b50`'s
`initiallyHuntsClosestPlayer` branch, which passes ref = **(VisibleGameWidth·0.5, 0.0) = (208, 0)**
(`10037c00 li r3,0x36; bl 0x10020250; lfs f2,0x0(r31)` (0.5) `; lfs f0,0x10(r31)` (0.0) `; fmuls;
stfs 0x58/0x5c; addi r3,r1,0x58; addi r4,r1,0x60; bl 0x10005ed0`). With no player the target becomes (208, −100)
(`10037c3c lfs f0,0x14(r31)`). ⚑ corrected: S §3.3 reads (208, 0) as a "default". It is
the **reference point**. In a 2-player game a hunter aims at the ship nearer the top-centre, not
the one nearer to itself. Census: only `mine` uses the key.

### 7.3 `FUN_10006090(idx, out)`, `FUN_10006110()`, `FUN_10005d40` [HIGH]
- `FUN_10006090 @ 10006090`: `extsb; rlwinm …2` → `lwzx r3,r30,r31` (game players[idx]); `li r4,4; bl
  0x10026c60` (state == 4, `10026c60 lbz r3,0xc6(r3); … cntlzw` = equality); if true `bl 0x100128d0`
  (position → out). It returns that flag. Callers `FUN_10033600`, `FUN_10037130/7230/7350`: the owning
  player is the fallback "owner position" (S §4).
- `FUN_10006110 @ 10006110`: loop i < 2 (`cmpwi r29,0x2`) over players, returns 1 at the first in state
  4. Callers `FUN_10033220` (§2.2) and `FUN_10015550`.
- `FUN_10005d40` (nearest player to a point, U NR3): same distance code with ref = the entity's
  position. Index out (`FUN_10026c90`), 0xff when none. With no active player the position out is read from the
  uninitialised stack slot `local_64[iVar9·2+2]` with iVar9 = −1, as U NR3 says. Callers `FUN_10015280`, `FUN_10017ef0`.

### 7.4 Bonus: U NR4 (which record supplies the air flag) [HIGH]
`FUN_10035cd0` `10035f88 lis r4,0x6169; lwz r5,0x8(r21); addi r0,r4,0x7220; subf; cntlzw; rlwinm` →
`stb r0,0x19(r28)`. r21 = the unit definition argument (r4 of `FUN_10035cd0`, `10035d44 bl 0x100144a0`
with it), so entity `+0x19` = (unit+0x08 == `'air '`), i.e. `!isGroundBased` (S §1). The level-object
record is not consulted.

## Worked example
**`pism` (Pickup – Shields Mini) collected by P1 with shield 60.** `pism` (`$W/data/Game/unde/Pickup -
Shields Min[pism].unde.txt`) has: `pickup_Type_ID shie`, `pickup_Value_INT 20`, `harmlessToPlayers`
FALSE (default), `isGroundBased` FALSE, group 1–1, no spawn sets, `destructSound_ID shch` (vol 100–100,
prio 75, pitch 0.8–0.8), `destructParticle_ID smci` colour `00F8F8`, no coins. Its states are "Grow and Dance Around"
(timer 165, Collides/CollidesWithPlayers TRUE, cyclic, MaxSpeed 4, Delta 0.1) → "Dwindle,
Delete" (timer 20, still collidable) → `Delete`, so it can be taken for 185 ticks after appearing.
1. **Spawn.** The Shield Station cap `csht` is destroyed (by player damage, inside `FUN_10033850`) →
   `FUN_10016300` step 4 issues `destructSpawn_ID pism` (if `FUN_10016880` passes, i.e. the cap is not over water): owner = `csht`, `+0x14` = `csht`'s `+0xd8`
   (0xff), +0x28 = 1.0. The result is a singleton with an owner, so it goes to PERM if `csht` is in PERM, else into a new group of 1 (§4.5).
   `FUN_10035cd0`: `+0xd8` = 0xff, `+0xd9` = 0xff, `+0xca` = 0, `+0x19` = 1 (air), `+0x13e` = 0. Group
   delay 0 → `+0xb0` = 0, and the same pass reaches it: `+0xb0` → −1, full update on the spawn tick (§4.5).
2. **Contact (tick T).** `FUN_10033850` pickup branch: rect/circle hit with P1 → `+0x4d4` = `'shie'` ≠
   none → `FUN_10037580(P1, e)` → `100376ac lwz r4,0x4dc(r6)` = 20 → f1 = 20.0 → `FUN_10027490`:
   in game, 20.0 ≠ 0.0; get = 1324426.0 − 1324366.0 = 60.0; 60 + 20 = 80 ≤ 100 →
   set `P1+0xa8` = 1324446.0. Return 1.
3. `FUN_10026c90(P1)` = 0 → `FUN_10016300(e, 0, T)`: glow off; air layer, so no obstacle; particles `smci`
   (`00F8F8`); no destructSpawn; no notice; sound `shch`; **`+0xcb` = 1, `+0xd9` = 0, `+0xda` = 1**;
   `includeInGroundAccuracyCount` FALSE → no tally; no random bonus. Then **`+0xca` = 1**. The P2 iteration
   stops on `+0xcb`. No score and no money change.
4. **Reaper (end of tick T).** No ground count, no terrain stamp, no destroyOwnerOnDestruction (FALSE)
   → `FUN_10036120(g, e, 1, 1)`: `+0x13e` = 0 → no children; `g+0xac` += 1 (for a group of 1: 1 ==
   `+0xa4` → "group kill"); coin blocks skipped (`+0xca` = 1; `destructCoin*` are `none` anyway);
   `FUN_10016300` no-op; `+0xcb` = 1; `g+0xa8` 1 → 0 → returns 1 if non-PERM → group freed, else PERM
   kept. Unlink and `FUN_10038810` (pool live −1). Single path, no double call (§4.1).
5. **Net:** P1 shield 60 → **80** (stored 1324446.0, resolution 0.125). The score bar animates it on its next
   frames (`FUN_100317e0` steps the displayed value toward it by flli 120 up / 121 down per frame, dump l. 29421–29440). Invulnerability,
   lives, money, multiplier and score are unchanged. If P1 had shield 90 → 100 (capped). At 100 the pickup is still
   consumed.

## NOT RESOLVED (this file)
1. MathLib `atan` ulp agreement (§1.3): the exact set of headings that lose 1° per round trip
   is from an IEEE simulation. A run of the original (or the MathLib atan bit pattern) would settle it.
2. ~~Orphaned-orbiter motion (§5.2) relies on U's integrator order. No shipped orbiter whose owner can die
   while `+0xd8` = 0xff was enumerated (census of `OrbitOwner` states × owner destruction).~~ → ⚑ corrected (wave 3+4, 2026-10-04) (critic O6):
   the 4 shipped orbiters (`bgpp icpp pbpp rgpp`) are deleted with their owner or their player, so the orphan
   motion never happens in 1.0.6 (gameplay-leftovers.md §7.3).
3. The console handlers at `0x10008xxx` (GOD) and `0x10039080` (PLAYERACTIVESPAWNS) are not in the
   decompile dump (no function boundary). They were read from raw bytes only, and their command-table entry layout
   (`0x100e0980`) was not decoded. Debug-only, so behaviour-neutral for normal play.
4. ~~`FUN_1003c7a0`/`FUN_1003c940` copy req+0x28 from registers (`sth r9/r8`, `sth r10/r9`). I assumed
   they hold the template halves (same pattern as the other sites) but did not trace the loads → MED for "only the
   ground launcher changes +0x28".~~ → ⚑ corrected (wave 3+4, 2026-10-04) (critic O4): traced — `1003c874/78`, `1003ca54/58` load
   template +0x28/+0x2a (1.0); air/aux shots always pass 1.0 [HIGH] (gameplay-leftovers.md §7.1; INDEX #46).
5. `FUN_10015550` (second caller of `FUN_10006110`) not read.
6. Pulse Tank timing (§1.4) assumes the scroll state and the on-screen gate definition of B §3.
   The 83–95-tick figure is for the x-crossing of the centre only.

## Role-table rows (for merge)
| `FUN_10042cd0` | U_Math | heading (internal h') of a float vector: axis cases 0/180/90/270, quadrant atan formulas, trunc, ≥360→0; exact inverse of `FUN_10042b80` | HIGH | full listing `10042cd0..10042e8c` (loose-ends-combat.md §1.2) — ⚑ corrected (was MED, decompile) |
| `FUN_10005cf0` | G_Game | game `+0x39` "level end reached" (set `10006db4`, cleared `10007248`/`10005524`/`10005828`) | HIGH | listing + raw store scan (§2) |
| `FUN_10007170` | G_Game | level transition: when +0x09 and a player is alive → sound, fade, clear +0x09/**+0x39**, `FUN_100302e0`, `FUN_100064d0` next level; otherwise +0x08 = 0 (session ends) | MED | decompile + `10007248` (§2.1) |
| `FUN_10037580` | G_EntityGroup | pickup switch: grnd/air (refuse if invulnerable), coin, exli, mult, shie, **spec (no-op, consumed)**, default consumed | HIGH | listing `10037580..100376f0` (§3.1) — ⚑ corrected (spec case) |
| `FUN_10027490` | G_Player | shield += value, clamp [0,100], skip if 0 or not in game | HIGH | listing (§3.2) |
| `FUN_10027de0` | G_Player | set/clear invulnerable `+0xce` with sticky `+0xcf` (sticky only from console GOD) | HIGH | listing `10027de0..10027e40` + raw call `10008518` (§3.3) |
| `FUN_10027db0` | G_Player | coin tally started (player +0xd8 ≠ 0) | HIGH | listing; writer `FUN_10027670` `100276a0` (§3.3) |
| `FUN_10036120` | G_EntityGroup | remove-from-group bookkeeping, **no +0xcb guard** (direct removers + reaper ⇒ called twice) | HIGH | listing `10036120..100363b8` (§4.1) |
| `FUN_100363c0` / `FUN_100364f0` | G_EntityGroup | destroy / delete children (owner id +0x144 == e+0x9c, state 0x329 / 0x32a) via `FUN_10036120`, no unlink | HIGH | listing (§4.1) |
| `FUN_10034b90` | G_EntityGroup | player gone: entities with +0xd8 == player destroyed (0x329) or deleted (0x32a) | HIGH | listing `10034c4c..10034ca8` |
| `FUN_10034de0` | G_EntityGroup | delete first entity with serial == arg | HIGH | listing `10034e8c..10034ea4` |
| `FUN_10036be0` | G_EntityGroup | remove entities of unit X owned by player P (destroyed flag passed) | HIGH | listing `10036c8c..10036cb8` |
| `FUN_100142f0` | G_Entity | entity field reset (+0xac…+0xda = 0, +0xd8/+0xd9/+0x118 = −1, +0x13c..+0x13e = 0) | HIGH | listing `100143a4..10014474` (§4.2) |
| `FUN_100144a0` | G_Entity | allocate one zeroed 0x18 spawn record per spawn set of every state; +0x13e = 1 | HIGH | listing `100145b0..1001460c` (§4.2) |
| `FUN_10005ed0` | G_Game | closest state-4 player to **ref point** (ties → P1), default (0,0); returns any-active | HIGH | listing (§7.2) — ⚑ corrected (caller passes ref (208,0)) |
| `FUN_10006090` | G_Game | position of player idx if in state 4 | HIGH | listing (§7.3) |
| `FUN_10006110` | G_Game | any player in state 4 | HIGH | listing (§7.3) |
| `FUN_10017150` | G_Entity | rotate-to-target gate (`DoRotateToTarget`, +0xc4 pause, PauseAnyRotation mid-volley) → `FUN_100172d0` | HIGH | listing `10017150..100172c4` (§7.1) — ⚑ corrected (damage-health-death.md called it "spawn-set reader", LOW) |
| `FUN_1003beb0` | G_WeaponHandler | bomb press: n = min(sector + F151 − 1, F152), +0x84 = n−1, launch | HIGH | listing `1003beb0..1003bf74` (§6.6) |
| `FUN_1003cd30` | G_WeaponHandler | first PEAA def with minimumLevelAvailable == sector | MED | decompile; caller `FUN_1003af90` `1003b0e4` (§6.5) |
| `FUN_1003bb20` | G_WeaponHandler | get handler +0x24 (air power level, float) | HIGH | raw `c0230024 4e800020` (§6.4) |
| (undecompiled) `0x10039080` | console | toggle `DAT_100e0214` "Player Active Only Spawns" | HIGH | raw bytes, pointer `0x100e0980` (§2.2) |

## INDEX updates (for merge)
- **#29 closed:** the double `FUN_10036120` is real (no guard anywhere). It is behaviour-neutral for 1.0.6 data
  (census: no removable unit in a group ≥ 2 and no destroyable child with coins), and its worst case under modding is
  orphaned members plus a pool leak → loose-ends-combat.md §4.1.
- **#30 closed:** `+0x39` = level end reached. Writers `10006db4` (1) and `10007248`/`10005524`/`10005828` (0).
  Five gates → §2.
- **#32 closed:** `+0xd8` is inherited along spawn chains. Level-object/notice roots → 0xff, so enemy-shot
  kills never score → §4.3.
- **#20 residual closed:** no −32 shift for spawn-set children (only `FUN_10035900` level objects) → §5.1.
- Narrowed or closed file-level NRs: U NR1/NR4 (§1.2, §7.4), S NR1/NR2/NR4/NR6/NR7/NR8 (§4, §1, §7),
  W NR1/NR2/NR5/NR6/NR7 (§2, §3.3, §6.4, §6.3, §1.3), D NR2/NR3/NR4/NR9 (§4.3, §4.2, §3.2, §1.2/§7.1),
  P NR2/NR4/NR9 (§6.1, §6.2, §2.2), B NR4/NR5/NR6 (§5.1, §1.4, §6.6), SC NR3 (§3.1), L NR5/NR6
  (§3.3, §6.5).
- Corrections for the fix pass: damage-health-death.md `FUN_10017150` "spawn-set reader" → rotation
  gate (§7.1). spawn-and-waves.md §3.3 "default (W·0.5, 0)" → the reference point of the
  closest-player search (§7.2). player-physics.md §4.4 "the level-end flag is never cleared by the level
  start" → `+0x39` is cleared in `FUN_10007170`; it is `+0xce` that level start leaves set (§2.2).
  player-physics.md §2.6 "+0x360 set while the ground weapon is being fired" → set on every handler tick, never
  cleared (§6.2).
