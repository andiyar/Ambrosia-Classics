# Ferazel's Wand 1.0.3 — ground enemies, part 2: wave-2 loose ends (corpse raft, `+0xa6`, sound voices)

Code readings only; nothing behaviour-verified. Date 2026-10-04.
Sources: raw listing `ghidra/Ferazel_pef.disasm.txt` (addresses), handler dump
`ghidra/Ferazel_handlers.decompiled.c` ("h. l. N"), main dump `ghidra/Ferazel_pef.decompiled.c`
("m. l. N"), constants via `tools/const.py`, TOC slots via `tools/tocrefs.py`, and a field-access
scanner (scratch Python: every `l*/st* rX,0xNN(rY)` in the raw listing, bucketed by the function
separators of both dumps; stack-relative `(r1)` accesses dropped) — "store scan" / "load scan" below.

Continues `enemies-ground.md` (same units and conventions: px, velocities 1/256 px/frame, frames
≈ 1/30 s, `S` = the enemy sprite, `P` = the player). Closes INDEX item 16 and enemies-ground NR 3–7.
Labels per INDEX.

## 1. The Walker corpse as a platform: it **floats**  [HIGH]

### 1.1 Conversion (recap of enemies-ground §3.8, with the raw)
The 1700-path corpse (types 1700, 1705 and 1760 all die as type 0x6a4 = 1700) converts once
`+0xb2 > 0x32` (`10068ad4 cmpwi 0x32; ble`) and the previous frame touched water
(`10068adc lwz 0x11c` / `10068ae8 lwz 0x120`; `+0x11c` is already zeroed, so it is `+0x120`).
Writes `10068b38..10068b88`: handler `+0x4c` := TOC −0x7640 (= `_DAT_100a0200`, the Platform
handler), rect `SetRect(+0x34, 0x10, 0x35, 0x42, 0x47)` (`10068b40..10068b54`), float line
`+0x1a0 = −6` (`10068b60`), one-way `+0x185 = 1`, `+0xa6 = 0`, `+0x116 = 0`, `+0x17c = 1`
(Platform set-up already done → `.DoSetupPlatformSprite` is skipped, `100635f8..10063604`),
`+0x13a = 0x20`, `+0x138 = 0x3c`. Nothing else changes: `+0xb0` stays **4** (the death state),
the hit callback `+0x5c` and the **tile-hit callback `+0x1f8 = .HitWalkerTileSprite`** stay (the
only Walker store to `+0x1f8` is Setup's `1006737c`; store scan), and the buoyancy `+0x19e` is
**0** (its only writers are `.InitSprite` `1003d554` → 0, `.SetupProgrammedPath`,
`.HandlePlayerSprite`, `.DoSetupPlatformSprite`, and the 0x6a4 ramp below; no Walker routine).

### 1.2 One frame of the corpse under `.HandlePlatformSprite @ 100635b4`

| step | raw | effect on the corpse |
|---|---|---|
| 1 | `100635d8..10063614` | returns if `+0xe9` / `+0x1b2`; `+0x17c ≠ 0` → no set-up; `bl .StandardSpriteHandles` (`10063614`): `+0x120 ← +0x11c`, `+0x11c = 0` (`10036994..100369ac`) |
| 2 | `1006361c..10063654` | mode dispatch on `+0xb0`: 4 is `< 0x1e`, `< 0xc`, `≠ 2`, `≥ 2`, `< 0xa` → `b 10064968` (no mode code at all) |
| 3 | `10064968..10064988` | `+0xb0 == 3`? no; `== 4`? **yes** → shared raft/floe/corpse block (`+4 == 0x6a4` would also enter) |
| 4 | `10064988..100649c0` | type 0x6a4 and `+0x19e < 0x50` → `if FastRand(2) == 1: +0x19e += 1` — buoyancy ramps 0 → 80, +½ per frame on average (≈ 160 frames to full) |
| 5 | `100649c4..100649e8` | gravity `vy += +0x110` **only if** `+0x11c == 0 ∧ +0x120 == 0` — i.e. only when the previous frame had no water contact; `+0x110` is the Walker's 0x151 (`100673dc`, `100684e4`, `10069140`; the Platform handler's own `+0x110` stores `10063f14..10063f8c` lie in other mode branches) |
| 6 | `100649ec..100649f4` | raft tilt block is mode 3 only — skipped |
| 7 | `10064ac0..10064ac8` | `.ApplyFriction(s, 100)`: vx moves 100 toward 0, no overshoot (vy untouched) |
| 8 | `10064ad0..10064ad8` | `+0xa6 ≤ 0` → no lifetime countdown, no melt: the corpse raft is **permanent** |
| 9 | `10064b84..10064bb4` | `+0xb0 < 0xa` → `x += vx`, `y += vy` (fixed point `+0x14/+0x1c`) |
| 10 | `10064c54..10064cb8` | integer position refresh, `bl .SeparateFromTiles2` (`10064c8c`), refresh again |
| 11 | `1003cc24..1003ccd0` | `.SeparateFromTiles2` calls the tile-hit callback `+0x1f8` (`lwz r12,0x1f8(r27)` then `bl 0x1009f80c` ×3) for every FG cell and every non-zero-kind BG cell the hot rect overlaps (BG: layer 0, the whole 32×32 cell) |
| 12 | `1006a9b4..1006aa10` | `.HitWalkerTileSprite`, BG kind ≥ 200: `.IsWaterTile(kind)` (`bl 100430c8`: 200 ≤ kind < 210, `100430c8..100430e8`) and `+0x140 == 0` → `bl .HandleUnderWater` |
| 13 | `10043070..1004308c` | `.HandleUnderWater` (surface search, `+0x11c ≥ 1`, splash on entry) then, because `+0x19e > 0`, `bl .HandleFlotation`; `+0x140 = 1` |
| 14 | `10064d50` | `.StandardSpriteCleanup` |

### 1.3 Flotation arithmetic (`.HandleFlotation @ 10042d04`)  [HIGH]
`surface` = top edge of the topmost water cell of the hit column (`.HandleUnderWater` walks up
while `.GetBGTile(col, row−1)` is water; `surface = row·32`, m. l. 38157–38168). Then
(`10042d04..10042e08`):
- `target = surface + (+0x1a0) − (hotTop + (hotBottom − hotTop)/2)` = `surface − 6 − (0x35 + 9)` =
  **`surface − 68`** (sprite y); `b = min(+0x19e, 0x15e)` (`10042d28..10042d3c`), negated when
  `target < y` (`10042d40..10042d48`); `vy += b`.
- `b > 0` (pushing down) → `vy = trunc(vy · 0.86)` (double `0x100a17f8`, `10042d70`); `b ≤ 0`
  (pushing up) → `vy = trunc(vy · 0.93)` (`0x100a17f0`, `10042dac`); `const.py`: 0.86 / 0.93.
- `y == target` and `|vy| < 0x46` → `vy = 0`, `y` snapped (`10042dd4..10042e04`).

**Outcome.** Once converted, the corpse gets no gravity while it touches water (step 5), and the
flotation pulls it toward `y = surface − 68`: hot rect `y+0x35 .. y+0x47` = `surface − 15 ..
surface + 3`, i.e. it rides with its 18-px hot rect 3 px under the surface, hot-rect midline 6 px
above it. The 3-px overlap keeps the water cell in contact (step 11 uses the full cell), so the
`+0x120` gate keeps gravity off and the state is stable. A corpse that converted while lying on
the bottom rises: with `b` growing ~½ per frame the upward speed tends to `0.93·b/0.07 ≈ 13.3·b`
(≈ 4.2 px/frame at `b = 80`) [HIGH arithmetic; the rise profile is a consequence, not a constant].
It never sinks again and never expires. The player can stand on it (`+0x185` one-way top,
platforms-ropes-radial §2.5).

### 1.4 Edges  [MED unless noted]
- **Which liquid** does not matter for the platform phase: `.HandleUnderWater` handles every
  kind 200..209 the same way for flotation; the Walker's liquid damage (enemies-ground §2.4) is in
  `.HandleWalkerSprite`, which no longer runs. Kind 5 (quicksand) additionally applies its own
  sink/floor rule before the flotation call (physics-sprites §8.6) [HIGH code; the combined
  motion is not worked out].
- **Leaving the water** (pushed by a rider, a current, or the surface dropping): the first frame
  with neither `+0x11c` nor `+0x120` set restores gravity 0x151 — it falls like any platform and
  floats again on the next water it meets.
- **Riders**: whatever a rider does to the corpse goes through `.PlatformBounce`/`.HitPlatformSprite`
  (platforms-ropes-radial §2.6); not re-derived here.
- The 1750 Ax goblin never converts (its death path has no water test) [HIGH: enemies-ground §3.8].

## 2. Crawler and Roach `+0xa6`  [HIGH]

**Crawler** — `+0xa6` is a live **cooldown** shared by the leap and the flee hop:

| access | raw | meaning |
|---|---|---|
| Setup `+0xa6 = 3` | `100659e0 li r7,0x3` → `10065a10 sth` | first-leap delay |
| state 2 count-down | `10065f34..10065f44` (if > 0, −1) | per state-2 grounded frame |
| state 2 leap gate | `10065f48 lha; cmpwi 0; bne` + `10065f54 +0xb2 == −1` | `+0xa6 == 0` arms the wind-up (enemies-ground §4) |
| leap re-arm | `10065e98..10065ea8` `+0xa6 = 10 + FastRand(10)` | |
| state 3 hop gate | `10065fd8 lha; cmpwi 0; bne` | flee hop only at 0 |
| hop re-arm / count-down | `10066068` (`20 + FastRand(30)`), `100660c8..100660d0` (−1) | |

So the initial 3 **is** consumed: a crawler that reaches state 2 (floor, or after the ceiling
drop) can start its first wind-up only after three state-2 grounded frames. enemies-ground NR 7's
"no consumer" is wrong for the Crawler (Corrections #1).

**Roach** — `+0xa6` is effectively **write-only**: Setup 3 (`1007794c`/`1007798c`); state 2 only
decrements it while > 0 (`10077c44..10077c54`, the load is its own guard); every reader that acts
on it (`10077c64` hop gate, `10077d54` count-down) lies in state 3 (`10077c5c..10077d80`), and
state 3 is unreachable: the dispatch `10077b1c..10077b40` enters 3 only when `+0xb0 == 3`, whose
sole writer `10077d70` is inside the state-3 block (store scan of `+0xb0` over the Roach routines:
Setup `10077994` = 2, `10077d70` = 3, `10077d9c` = 4). Readers of a Roach's `+0xa6` elsewhere: the
other `+0xa6` loads in `.Hit*` routines read the *other* sprite's field behind a player-shot or
EnemyShot handler gate (e.g. `1006a288..1006a2b4`, `10078034..10078058`) — none can see a Roach.

## 3. `FUN_100916dc` / `FUN_10091504` — voice count / voice stop  [HIGH]

The mixer keeps up to 16 voices, 0x34 bytes each, at `*TOC−0x652c` (`_DAT_100a1314`), count at
`*TOC−0x6530`; `+0` = voice id (serial, +2 per new voice), `+4` = sound pointer (the
`FUN_10091748` 'asnd' block), `+0x1c` completion proc, `+0x2c/+0x2e` volumes, `+0x30` priority
(`FUN_10091208` writes them, m. l. 78280–78294). Both helpers do nothing when the sound system is
off (byte TOC−0x5b08).
- **`FUN_100916dc(x)` = number of voices playing `x`** (`100916dc..10091744`): counts entries
  with `+0 == x` (`10091704..1009170c`) or `+4 == x` (`10091710..1009171c`), or every entry when
  `x == 0` (`10091720`).
- **`FUN_10091504(x)` = stop `x`** (`10091504..100916c8`): same match; each matching voice is
  removed (array closed up, last slot zeroed) and, if it had a completion proc, that proc is
  called with (2, x, …) (m. l. 78339–78363).
The goblin cries pass the **sound pointer** (`lwz r3,0(slot)` before each `bl`, `100671f8..10067224`
and `1006705c..10067138`), so the tests are **global**: `.GoblinRandomCry` stays silent while any
voice anywhere plays 465/466/467, and `.GoblinHurtCry` cuts every playing 465/466/468 in the level,
not just this goblin's. A replica must keep that (one shared voice pool, match by sound).

## 4. `_DAT_1009fe8c` = the level-load counting window  [HIGH]
A byte flag: `.SetupLevel` stores 1 (`10004da4 li r0,1; 10004db0 stb`), calls `.SetupLevelSprites`
(`10004db4 bl 0x10003cd0`) and stores 0 (`10004dc0`). Every other load of the slot (`tocrefs.py
1009fe8c`: 16 Setup routines — Bonus, Crawler, Walker, Roach, Blob, Bat, Gremlin, Floater, Frog,
Salamander, Dillo and the five bosses) is the "count me as an enemy / collectible" test. Sprites
created later (pipe children, spawned shots, idle re-activation — which re-runs no Setup) are
therefore never counted. Same reading in bosses.md §1.2 and pickups-boxes.md, now raw-backed.

## 5. EnemyShot behaviour of the Walker/Dillo projectiles  [pointer]
enemies-ground NR 3 (flight, tiles, expiry of 0/1, 0x6a9, 0x6d6, 0x6e1/0x6e2, 0x753, 0x754) is
answered in enemy-shots-and-damage.md §1.2 (type table: life/death per type, damage), §1.3 (tile
and sprite collisions, bounce budgets), §1.6 (`.KillEnemyShot` effects). The 0x753 "egg" is a
**bomb**, not a hatching egg: fuse `+0x15c = 240` frames, flash every 45, explodes (ibid. §1.2).

## 6. Enemy pipes spawn ground enemies  [HIGH data; behaviour in enemies-flyers §7.4]
Census (all 24 `Mlvl`, Python): every enemy pipe (Box 1490..1493) is in **level 21**: rec 35
(1491, p1 = 1730 Blob), 36 (1491, 1705 spear guard, p2 150), 135 (1491, 1705, p2 60), 136 (1492,
1700 thrower, p2 110), 137 (1490, 1860 insect bat, p2 60), 169 (1493, 1730 Blob, p2 100).
A pipe's child is created with record index 0x200 (no record; never idles, never written back) and
**forceNow** (`1006ec90..1006ecac`: `li r6,0x200; li r7,0x1; bl .GenerateSprite`), so pipe Walkers
are counted by no stat (§4) and leave no placement record. While emerging they carry `+0x1b2 = 1`
(enemies-flyers §7.4).

## 7. The crush write `+0x150 = 0x16` on the Dillo  [HIGH]
`.HitDilloSprite` writes `+0xa4 = 0`, `+0x150 = 0x16` on a crush (`10087570..1008757c`), the
Crawler/Roach death-counter idiom; no Dillo routine loads `+0x150` (load scan: the only `+0x150`
loads in enemy routines are Crawler `10066170..10066204`, Roach `10077dc4..10077e20`, the swarm
member, the Crab, and two *other*-sprite reads behind the geyser-segment type gate 0x5a0,
`1006687c`, `10082b00`). For the Dillo the value is write-only; the crush kills through HP 0.

## NOT RESOLVED
1. Colours of the Walker/Crawler/statue remap tables and `.BloodSpray`/`.HandleBurn` details
   (enemies-ground NR 1–2) — INDEX item 15, another lane; not attempted here.
2. The rise profile of a corpse converted on the bottom (§1.3) is arithmetic only; the combined
   quicksand + flotation motion (§1.4) was not worked out (no shipped corpse placement in
   quicksand was checked).
3. What a rider does to the corpse raft's vertical motion (`.PlatformBounce` side) — not traced here.

## Proposed additions to physics.md §0
| off | type | meaning | evidence |
|---|---|---|---|
| +0x19e | i16 | add: type 0x6a4 under the Platform handler ramps it +1 w.p. ½ per frame to 0x50 (`10064988..100649c0`); every other class leaves it 0 (store scan) | §1.1, §1.2 |
| +0xa6 | i16 | Crawler: leap / flee-hop cooldown (initial 3 live); Roach: write-only (only reader state 3 is unreachable) | §2 |
| +0x150 | i32 | Crawler/Roach: death counter (crush writes 0x16 → dies next frame); Dillo, Frog, Salamander, Blob, Bat, Gremlin, Floater: write-only crush mark | §7, enemies-water-cave §7.2 |

## Corrections to the existing bank
| # | file § | old | new | evidence |
|---|---|---|---|---|
| 1 | enemies-ground.md NR 7 (applied in place, ⚑ wave 2) | "Crawler/Roach `+0xa6` initial 3 … no consumer in state 2" | Crawler: initial 3 is the first-leap delay (consumer `10065f48`); Roach: write-only, its only reader is unreachable state 3 | §2 |
| 2 | sprites-backgrounds-sounds.md §6.2 | `FUN_10091208` only | add `FUN_100916dc(x)` = number of voices playing sound/voice `x` (0 = all) and `FUN_10091504(x)` = stop all voices matching `x`, calling each voice's completion proc | §3; `100916dc..10091744`, `10091504..100916c8` |
| 3 | platforms-ropes-radial.md §2.5 | "buoyancy grows +1 … to 0x50" (no outcome stated) | add: water reaches it through the Walker tile callback kept in `+0x1f8` → `.HandleUnderWater` → `.HandleFlotation`; equilibrium `y = surface − 68` (hot rect 3 px submerged); no lifetime — the corpse floats permanently | §1; `1006a9ec..1006aa10`, `10043070..10043084`, `10064ad0` |
| 4 | INDEX.md item 16 | open | closed: floats (§1), Crawler/Roach `+0xa6` (§2), sound helpers HIGH (§3) | this file |
| 5 | pickups-boxes.md row 1490..1493 "[MED for purpose]" | purpose MED | enemy pipes: all six shipped in level 21 with p1 = 1730/1705/1705/1700/1860/1730 (§6); child `+0x1b2` = emerging (enemies-flyers §7.4) | census; `1006ecdc`, `1006f040` |
