# Ferazel's Wand 1.0.3 — flying enemies: Bat (bats, insects, swarms), Gremlin, Floater (Wraith)

Code readings only; nothing behaviour-verified.
Date 2026-10-03. Sources: handler dump `ghidra/Ferazel_handlers.decompiled.c` ("handler dump l. N"),
main dump `ghidra/Ferazel_pef.decompiled.c` ("main dump l. N"), raw listing
`ghidra/Ferazel_pef.disasm.txt` (addresses `1007xxxx`), data section via `tools/const.py` / `tools/pef.py`,
level census over all 24 `Mlvl` (Python, this session, `rsrc_census.parse` + the §3.4 record layout).
Scope: classes Bat (types 1740..1749, 1850..1854, 1860..1869), Gremlin (1770..1779), Floater
(1780..1799) — `.SetupBatSprite` `.HandleBatSprite` `.HitBatSprite` `.HitBatTileSprite`
`.SetupSwarmMemberSprite` `.HandleSwarmMemberSprite` `.HitSwarmMemberSprite` `.SetupInsectBodySprite`
`.HandleInsectBodySprite` `.SetupGremlinSprite` `.HandleGremlinSprite` `.HitGremlinSprite`
`.KillGremlinSprite` `.HitGremlinTileSprite` `.SetupFloaterSprite` `.HandleFloaterSprite`
`.HitFloaterSprite` `.HitFloaterTileSprite`, main-dump `.InitBatSprite` `.KillBat`
`.InitGremlinSprite` `.InitFloaterSprite`, and the helpers they call. Programmed paths are physics.md
§8.5 (not repeated). Units as physics.md (px; velocities 1/256 px/frame; Rects as `SetRect(l,t,r,b)`
arguments, stored at `+0x34` as top,left,bottom,right). Labels per INDEX.

| function | address | handler dump lines |
|---|---|---|
| `.SetupBatSprite` | 1007dc30 | 16367–16576 |
| `.SetupSwarmMemberSprite` / `.HandleSwarmMemberSprite` | 1007e220 / 1007e2c8 | 16577–16595 / 16596–16705 |
| `.HandleBatSprite` | 1007e6b0 | 16706–17166 |
| `.SetupInsectBodySprite` / `.HandleInsectBodySprite` | 1007f440 / 1007f4a0 | 17167–17177 / 17178–17188 |
| `.HitBatSprite` / `.HitSwarmMemberSprite` / `.HitBatTileSprite` | 1007f508 / 1007f734 / 1007f91c | 17189–17243 / 17244–17276 / 17277–17311 |
| `.SetupGremlinSprite` / `.HandleGremlinSprite` | 1007fc88 / 1007feec | 17312–17395 / 17396–17798 |
| `.HitGremlinSprite` / `.KillGremlinSprite` / `.HitGremlinTileSprite` | 10080d34 / 100810d4 / 100811a4 | 17799–17882 / 17883–17919 / 17920–17978 |
| `.SetupFloaterSprite` / `.HandleFloaterSprite` | 100814b8 / 100816d8 | 17979–18054 / 18055–18178 |
| `.HitFloaterSprite` / `.HitFloaterTileSprite` | 10081aa4 / 10081c60 | 18179–18220 / 18221–18255 |
| `.InitBatSprite` / `.KillBat` / `.InitGremlinSprite` / `.InitFloaterSprite` | 1007daf8 / 1007f874 / 1007faac / 100813dc | main dump 51727 / 51743 / 51770 / 51843 |

Callback TVectors resolved with `pef.tocfunc` (TOC slot → TVector → code → traceback name) [HIGH]:
`0x100a04c4` HandleBat, `0x100a0c7c` HitBat, `0x100a0c78` HitBatTile, `0x100a0c74` SetupSwarmMember,
`0x100a0470` HandleSwarmMember, `0x100a0c68` HitSwarmMember, `0x100a0c70`/`0x100a0c6c`
Setup/HandleInsectBody, `0x100a04a4` HandleGremlin, `0x100a0c9c` HitGremlin, `0x100a0c98`
KillGremlinSprite, `0x100a0c94` HitGremlinTile, `0x100a04ac` HandleFloater, `0x100a0cb4` HitFloater,
`0x100a0cb0` HitFloaterTile, `0x100a0830` SetupEnemyShot, `0x100a0488` HandleEnemyShot, `0x100a04e8`
HandlePlayerShot, `0x100a01f8` HandleStatue, `0x100a0484` HandleBox, `0x1009ff38` SetupBonus.

## 1. Shared machinery

### 1.1 Helpers  [HIGH unless noted]
- `.FastRand(n)` (main dump l. 31106): returns `(n · (seed & 0xffff)) >> 16` ⇒ 0..n−1; `n = 0`
  reseeds from `LMGetTime + LMGetTicks` and returns an undefined register (matters only for the
  unplaced Floater variant, §4.4).
- `FUN_1003f218(s, dir, m)` (main dump l. 36374) [name proposal: AddDirImpulse]: adds a vector of
  magnitude `m` in 10°-step direction `dir` 0..35 to `(vx, vy)`: dir 0 → `vx −= m`; dir k →
  `vx −= cos(10k)·m`, `vy += sin(10k)·m` (cos/sin as doubles 0.985/0.174, 0.94/0.342, … at
  0x100a18b0..0x100a18c8, `const.py`). So 0 = left, 9 = down, 18 = right, 27 = up (screen y down) —
  the same table as physics.md §6.
- `.FindDesiredDirectionGeneric(target, from)` (main dump l. 37458): both args packed Points
  `(v << 16 | h)`; returns the 0..35 index (same convention) of the vector from `from` to `target`,
  rounded to the nearest 10° by tangent thresholds (−11.43 = tan 85°, −3.732 = tan 75°, …,
  −0.0875 = tan 5°, doubles 0x100a1800..0x100a1840); equal h or v are nudged by +1 first [HIGH
  for the up-left quadrant read through; other quadrants MED by symmetry].
- `.EnforceMaxSpeed(s, m)`: physics.md §2.
- **Double displacement.** `.HandleBatSprite` (raw `1007f2d4..1007f2f4`), `.HandleGremlinSprite`
  body (`10080594..100805b4`) and rider (`10080a14..10080a34`) do `x += vx; y += vy` themselves and
  then call `.ApplyGravityAndSeparateFromTiles`, which adds `vx`/`vy` again (main dump l. 32697ff.).
  Bats and gremlins therefore move **2·v per frame**; every speed below is the stored `v`
  [HIGH, raw-checked]. `.HandleFloaterSprite` and `.HandleSwarmMemberSprite` integrate once.
- `.MTNewSprite(type, x, y, layer, recIdx, setupTV)` (main dump l. 30596) clears 0x1fc bytes,
  stores type/x/y/layer, sets `+0x48 = recIdx`, **calls the Setup callback immediately**, then
  inserts — so a parent may overwrite a child's fields right after spawning it [HIGH].
  `recIdx` 0x1ff / 0x200 are "no record" sentinels: `.UpdateSprites` only touches records with
  `−1 < +0x48 < 0x1ff` (main dump l. 4924–4962) [HIGH].
- Idle spawning (`.AddIdleSprite @ 10007d8c`) also goes through `.MTNewSprite` (layer arg 1, which
  the Setups below overwrite), so Setup runs at level load; children a Setup spawns (swarm members,
  insect body) are ordinary active sprites and are **not** idled with their parent
  (`.ActiveToIdleSprite` only calls the parent's `+0x54`, unset here) [MED: consequence not traced].

### 1.2 Enemy counting and the level "enemies" stat  [HIGH]
During `.SetupLevelSprites` the flag `*_DAT_1009fe8c` is 1 (`.SetupLevel`, main dump l. 2521–2527).
A Setup that sees it sets `+0x1b5 = 1` and increments `*_DAT_1009ffb4`, which `.SetupLevel` stores as
the level total `G+0x6ee+2L` (l. 2533; `puVar12 = _DAT_1009ffb4`, l. 2232). `.KillBat` (raw
`1007f874..1007f8fc`) and `.KillGremlinSprite` (handler dump l. 17883–17919), if `+0xe9 == 0` and
`+0x1b5`, decrement `*_DAT_1009ffb4` and increment `G+0x306+2L`. So **G+0x306/0x6ee is the enemies
stat** (narrows world-data-format.md §4.3). Consequences in this scope:
- Swarm centres (1869) and Wraiths (1780) are counted but have **no crediting path** (the swarm
  sets `+0xe9` directly, §2.4; the Floater has no death path, §4.3). Shipped placements: 1869 ×3 in
  level 10, ×2 in 11, ×1 in 21; 1780 ×7 in 62 — on those levels the enemies stat cannot reach 100%
  [HIGH for the code path; MED for the on-screen consequence, `.CalcPercent` clamp in world §4.3].
- Not counted: gremlin children, swarm members, insect bodies (Setup sees `+0x48 == 0x1ff`/they use
  other Setups), and 1850-family bats with param1 < 0 (§2.1).

`+0x188 = 1` (set for path bats 0x6cd/0x6ce, the whole 0x73a family, every gremlin) makes
`.UpdateSprites` skip both the per-frame type/x/y write-back and the "clear record flag on death"
(main dump l. 4923–4962): those sprites keep their placement position in the record and **remain
active in the record after being killed** (respawn whenever the record block is replayed, e.g. a
checkpoint restore, engine.md §9) [HIGH code; MED consequence]. Chaser bats (0x6cc) do not set it:
the record follows them, and the 0x6cc→0x6d1 retype on waking (§2.2) is written back, so a restored
woken bat comes back awake as 1745 [HIGH].

### 1.3 Contact damage to the player (`.HitPlayerSprite`)  [HIGH]
`.MTCollideSprites @ 100326cc` (main dump l. 30210ff.) calls A's `+0x5c` with B for every hot-rect
overlap where A has a hit callback, neither has `+0xe9`, and not (`A+0x184` and same `+0x4c`) — the
player's callback runs whatever B's own `+0x5c` is. `.HurtPlayer` itself gates on the attacker's
HP: raw `10054768–10054798` — `lha r0,0xa4(attacker); cmpwi r0,0; bgt` → proceed; otherwise proceed
only if the attacker's handler `+0x4c` is EnemyShot (TOC −0x73b8) or Box (TOC −0x73bc), else
`li r3,0; b 10054c74` (returns 0, no damage). So a dead/dying flyer (HP < 1: a falling, burning
gremlin, a dying swarm member) does **not** hurt on contact [HIGH]. ⚑ corrected (review 1a,
2026-10-03) #1 — the earlier reading "attacker HP not tested, so a burning gremlin / dying swarm
member still hurts" was wrong and is withdrawn (agrees with enemies-ground §2.1, enemy-shots §3.7).
Values (`.HurtPlayer(p, a, dmg, blood, invul, coins)`, physics.md §5.1):

| attacker | dmg | invul | coins lost | evidence |
|---|---|---|---|---|
| Bat (handler HandleBat): all 1740.., 1850.. (except below), 1860.. | 0x38 = 56 | 60 | 0 | raw `10057a40..a4c` (TOC −0x737c → HandleBat), l. 4544 |
| 0x73a..0x73e with `+0x160 ≠ 0` (param1 < 0) | none | — | — | raw `100579f0..a08`, l. 4534 |
| swarm centre 0x74d | none | — | — | raw `100579e8`, l. 4531 |
| swarm member (HandleSwarmMember, any type) | 0x70 = 112 | 60 | 3 with p = 19/100 (`FastRand(100) > 0x50`) | default `li r24,0x70` raw `1005796c`; l. 4513, 4619 |
| Gremlin body or mounted rider (HandleGremlin) | 0xe0 = 224 | 60 | 5 (dmg > 0x70) | raw `10057a1c` |
| Floater (HandleFloater), only while phase `+0x46 > 12` | 0x70 | 60 | 3 with p = 19/100 | raw `10057cc8..10057d04`, l. 4243 |
| enemy shot 0x712 (bat spit, rider shot) | 0x38 | 60 | 0 | l. 4565–4597 (falls to `iVar37 = 0x38`) [MED: raw not re-read] |
| enemy shot 0x6f4 (wraith bolt) | 0x70 | 60 | 19% → 3 | l. 4578 [MED: raw not re-read] |

`.ShieldBlock(p, a)` runs first and can cancel the hit (raw `100579c4`). Insect bodies and gremlin
back layers have empty hot rects and cannot touch [MED: empty-rect SectRect assumed false].

### 1.4 Sounds and sheets  [HIGH: `.InitSounds` load pairs (main dump l. 39512ff.) × `snd ` names in the Sounds file]

| slot | `snd ` id / name | used for |
|---|---|---|
| `_DAT_100a02a8` | 608 "batdisturb" | chaser bat wakes (`STPlay3DSoundRand`, vol 0xab) |
| `_DAT_100a02a4` | 609 "bathit" | bat/insect hurt by a shot (Rand, 0xab) |
| `_DAT_100a0274` | 701 "Crawler Ouch" | water damage (0x55); hurt with HP > 200 (0x100); wraith hurt |
| `_DAT_100a0270` | 702 "Crawler uh oh" | hurt leaving HP ≤ 200 (0x100) |
| `_DAT_100a026c` | 703 "crawler death" | bat death (0x100); rider death; rider dislodged (0x55) |
| `_DAT_100a031c` | 480 "swarmMemberDieSound" | swarm member hurt, pitched 58000 + rand(20000), 0xab |
| `_DAT_100a0320[0..1]` | 477/478 "monster1/2Sound" | gremlin: 18% on hurt (pitched 84000 + rand(5000)); death if rider mounted (0x100) |
| `_DAT_100a02f4` | 494 "flap" | gremlin wing cycle wrap (0x55) |
| `_DAT_100a02ec` / `_DAT_100a02f0` | 496 "firehiss2" / 495 "firehiss" | rider fires (51% / 49%) |
| `_DAT_100a02c8` | 504 "elecshot" | wraith fires (0xab) |

Sheets (`.CacheEncFaceSetFromPICT(desc, PICT, frames, w, h, cols, …)`; PICT sizes from the Sprites
file confirm `frames·w`) [HIGH]. A Setup sets `desc+1 = 1` to mark the sheet needed this level.

| desc (TOC slot) | PICT (name) | frames × w×h | user |
|---|---|---|---|
| `0x100a0c90` | 1740 'bat' | 11 × 56×52 | 1740..1749 |
| `0x100a0c84` / `0x100a0c80` | 1850 / 1851 (unnamed) | 12 × 64×80 each | 0x73a family, param1 ≥ 0 / < 0 |
| `0x100a0c8c` | 1860 | 9 × 48×44 (0..7 head, 8 body) | 1860.. insects |
| `0x100a0c88` | 1869 | 8 × 24×22 | swarm members |
| `0x100a0cac` / `0x100a0ca8` / `0x100a0ca4` | 1770 / 1771 / 1772 | 10 × 132×120, 10 × 132×120, 4 × 32×32 | gremlin body / back layer / rider |
| `0x100a0cc0` | 1780 'Wraith' | 6 × 100×80 | 1780..1789 |
| `0x100a0cbc` / `0x100a0cb8` | 1790 / 1791 | 8 × 88×100 — **PICTs absent** from the Sprites file | 1790..1799 (unplaced) |

## 2. Census (shipped levels, all active records; record byte +1 is 0 in every one)  [HIGH]

| type (hex) | n | levels (count) | params p1,p2,p3,p4 |
|---|---|---|---|
| 1740 (0x6cc) chaser bat | 28 | 2(1) 3(11) 4(6) 10(4) 11(2) 21(4) | all 0 (+1 inactive record in level 3) |
| 1741 (0x6cd) path bat | 3 | 3(1) 21(2) | (2,340,800,0) (1,100,768,0) (1,60,512,0) |
| 1742 (0x6ce) path bat that spits | 2 | 21(1) 52(1) | (1,60,512,0) (2,150,500,0) |
| 1851 (0x73b) path bat, 1850 family | 45 | 11(40: 30 p1>0, 10 p1<0) 22(2) 31(3, p1=0) | p1 ∈ {2, −2, 0}, p2 160..400, p3 320..1200, one p4 = 200 |
| 1860 (0x744) insect | 5 | 21(5) | all 0 |
| 1869 (0x74d) swarm | 6 | 10(3) 11(2) 21(1) | L10: (0,8..) (0,6..) (0,12..); L21: (0,9,..); L11: (8,0,0,0) ×2 |
| 1770 (0x6ea) gremlin | 50 | 15(6) 20(6) 50(20) 51(17) 52(1) | p1 1 (39) or 2 (11); p2 25..390; p3 400..1700; p4 150/300 once each |
| 1780 (0x6f4) wraith | 7 | 62(7) | all 0 |

No other type in 1740..1749, 1850..1854, 1860..1869, 1770..1799 is placed.

## 3. Bat class

### 3.1 `.SetupBatSprite` by type sub-range  [HIGH; raw `1007dc30..1007e1ec` checked]
Common: `.InitSprite`; `+0x84 = +0x86 = 0`; layer `+0x80 = 0xb`; Handle/Hit/HitTile = HandleBat /
HitBat / HitBatTile; gravity `+0x110 = 0`; `+0xc0 = 0`; `+0x150 = −1`; fixed-point x/y from the
record x/y. Counted (§1.2) unless stated.

| types | HP `+0xa4` | hot rect | per-type set-up |
|---|---|---|---|
| 0x6cc..0x6d5 (1740..1749) | **500** (raw `1007dcc0`) | (0xc,0xf,0x2b,0x2f) | 0x6ce → retyped 0x6cd with `+0x188 = 1`, `+0x14c = 1` (spitter), `+0xb8 = 0x1000c`, `+0x154 = rand(80)+50`; then 0x6cc: `+0xa6 = 0` (asleep); 0x6cd: `+0x188 = 1`, `+0xa6 = 1`, `.SetupProgrammedPath(s,−1,0)`; 0x6d1: `+0xa6 = 1` (awake). All: thrust `+0x158 = 0x1e`, `+0x15c = 0`, state `+0xb0 = 7` |
| 0x73a..0x743 (Bat for 1850..1854 only; 1855..1859 are Background class) | **100** (`1007dde0`) | (0x10,0x1e,0x30,0x32) | `+0x188 = 1`; 0x73c → 0x73b with `+0x14c = 1`, `+0xb8 = 0x1000c`, `+0x154 = rand(80)+50`; 0x73a: `+0xa6 = 0`; 0x73b: `+0xa6 = 1`, path. `+0x158 = 0x1e`, `+0x15c = 0`, `+0xb0 = 7`. **param1 < 0**: layer 8, `+0x160 = 1` (sheet 1851, harmless §1.3, not counted); else `+0x160 = 0` (sheet 1850) (`1007deb8..1007df04`) |
| 0x74d (1869) swarm | 100, no hit callback (`+0x5c = 0`) | `±r/2` square | see §3.4 |
| 0x744..0x74c (1860..1868) insect | **200** (`1007e144`) | (6,6,0x2a,0x26) | `+0xc0 = ` sheet-1860 frame 3, `+0xb0 = 7`, `+0xa6 = 3`, heading `+0x46 = 3`, `+0xb8 = 0xb0004`, thrust `+0x158 = 0x28`, `+0x15c = 0`, unlit `+0x88 = 0`; body child §3.5 |

### 3.2 Chaser AI — types 0x6cc/0x6d1, 0x73a, 0x744 (handler dump l. 16764–16943)  [HIGH; raw constants listed are from `1007e794..1007ec50`]
Target point T = (playerX `_DAT_1009fd94`, playerY `_DAT_1009fd90` − 15) (engine.md §5 for the
globals). `+0x46` = heading 0..35, `+0xb0` = state, `+0xa6` = awake/animation counter.
1. **Awake (`+0xa6 > 0`)**: 0x6cc retypes itself 0x6d1. If centre x < playerX: `+0x17e = 1`, and if
   `vx < −0x100` and centre x < playerX − 40: `vx += 0x48`; mirrored for the other side (`+0x17e = 0`,
   `vx > 0x100`, `vx −= 0x48`). (Brake only when flying away horizontally.)
2. **Water** (`+0x120 ≠ 0`, previous frame in water): `vy −= 100` while `vy > −800`; and if (fully
   submerged in kind-0 water, `+0x120 == 1 && +0x128 == 0`) or (kind > 0 and ≠ 3) and `+0x116 == 0`:
   HP −100, invul `+0x116 = 0x13`, flash `+0xaa = 0x11`, "Crawler Ouch" vol 0x55 (l. 16786–16799).
3. **Asleep (`+0xa6 < 1`)**: wakes if |centre x − playerX| < 0x9c (156) and 0x20 < playerY − centre y
   < 200 (player below): "batdisturb", `+0xa6 = 0x14` (l. 16801–16812).
4. **Awake: state machine**, d = Dir(T from centre):
   - 7 (turn): d == heading → state 8; else heading `+1` if `d > h && d − h < 18`, otherwise `−1`,
     wrapping 0..35. (When d < h by more than 18 it turns the long way round — as written.)
   - 8 (thrust): if d is not within ±2 of heading (also tested ±36) → state 6; else
     `AddDirImpulse(heading, +0x158)` unless gated: 1740 family gate `|+0x86| > 0xb3 && |+0x84| > 0xb3`,
     1850 family `> 0x4f`, insect `|vx| > 0x1c1 && |vy| > 0x1c1`. `+0x84/+0x86` are only ever zeroed for
     bats (writers: `.InitSprite`, the Setups, `.RectBounceFake2` on the player — raw `sth …0x84/0x86`
     scan), so bats of the 1740/1850 families thrust every aligned frame [HIGH for the scan].
   - 6: with `+0x84 = +0x86 = 0` → state 7 at once (skips the rest of the steering that frame).
   - 5: heading = d (no writer of state 5 found in these handlers).
   No speed cap exists in the Bat handler; only the horizontal brake, wall bounces and water slow it.
5. 0x6cc..0x6d5 animation: if `+0xa6 > 0` it increments, > 0x15 → 2; face = frame `+0xa6 >> 1`
   (frame 0 = asleep, 1..10 awake). 0x73a family: `+0xa6` increments every frame and wraps after
   0x12 to 0, face = frame `+0xa6 >> 1` of sheet 1850/1851 — so a 0x73a bat is "asleep" one frame in
   19 and otherwise steers. 0x744/0x745: `+0xa6` 1..8 cycling, face = frame `+0xa6 − 1`.
6. 0x73a..0x743 only, after integration: if not fully submerged `+0x164 = y`; if `y < +0x164`,
   `y = +0x164`, `vy = 0` (cannot rise while fully submerged) [HIGH code; LOW purpose].

### 3.3 Path bats and the spit (l. 16972–17040)  [HIGH]
Every Bat type that is not 0x6cc/0x6d1/0x73a/0x744/0x74d takes the path branch: `+0x8a = 0`; mode 2
paths decay `vy` toward 0 by 0x100/frame (zeroed inside ±0x100) and face by `vx` sign; other modes
face the player; then `.HandleProgrammedPath` (physics.md §8.5; p1 mode, p2 travel px, p3 speed) —
at the doubled displacement of §1.1. Census modes: 1 and 2 (shuttles) and 0 (1851 in level 31: no
motion). Spitters (`+0x14c == 1`: 1742, 1852): `+0x154` counts down; at 0 and |playerY − centre y|
< 0x1e: `MTNewSprite(0x712, centre x − 12, centre y − 7, layer + 1, −1, SetupEnemyShot)`, shot
`vx = +0x708` if `+0x17e` else `−0x708`, shot `vy = bat vy >> 2`, cooldown `rand(0x4b) + 0x3c`
(60..134 frames) (raw `1007ee44..1007ef18`). The spawner also adds the shot's raw `vx` (±1800) to the
shot's **integer** x and the bat's raw `vy` to its integer y (`1007eed8..1007eef4`); the shot's
fixed-point position is untouched, so this is overwritten at the shot's first integration [HIGH code;
LOW intent].

### 3.4 Swarm 1869 (Setup l. 16416–16466, Handle l. 16944–16971, members l. 16577–16705)  [HIGH]
Setup: centre at record +(0x40, 0x40) (integer only; fixed point keeps the record point);
`AllocateGameMem(0x54)` → `+0x9c` (20 member pointers, `+0x50` alive count, `+0x52` total);
member type = p1 (0 → 0x74c), count = p2 (0 → 8; no bound check — > 20 would overwrite the
counts), radius `+0x154` = p3 (0 → 0x4b = 75). Members: `MTNewSprite(type, cx + rand(2r) − r,
cy + rand(2r) − r, layer − 1, 0x200, SetupSwarmMember)` with `+0x14c/+0x150` = centre. Count < 1 →
dies at once. Out of memory → "Out of memory creating swarm!" and `ExitToShell`.
Centre per frame: `.HandleBatSprite` holds exactly two `bl .StandardSpriteHandles` (raw `1007e788`, `1007ec68`); the earlier reading that it "runs **twice**" for the centre is not established — whether both calls lie on the swarm-centre path was not re-derived [MED] ⚑ corrected (review 1a, 2026-10-03) #7; `AddDirImpulse(Dir((playerY, playerX)
from (y, x) top-left), rand(6) + 20)`; `EnforceMaxSpeed 400`; `+0xb8 = 0x10009`; copies its x/y to
each live member's `+0x14c/+0x150`; a member with `+0xe9` is dropped (`alive −1`; ≤ 0 → centre
`+0xe9 = 1`, no `.KillBat`, §1.2). No face (invisible), collides with tiles (HitBatTile).
Member (`.SetupSwarmMemberSprite`): Handle = HandleSwarmMember, anim `+0x46 = rand(7)`, rect
(0,0,0x18,0x16), Hit = HitSwarmMember, HP 100, `+0x184 = 1` (members never test each other).
Member per frame: works relative to the centre: face = sheet-1869 frame `+0x46` (0..7 cycling);
alive: `AddDirImpulse(Dir(centre from own centre), rand(0x96) + 0x172)` (370..519),
`EnforceMaxSpeed 0xa8c`; if within 8 px of the centre on both axes and |vx|, |vy| < 0x578: `vx, vy =
rand(0x12fc) − 2430` each (double 0x100a1b98 = 2430.0); then jitter `± rand(400) − 200` on both;
dead (HP < 1): `vx = (int)(vx·0.85)` (0x100a1b90), `vy = max(vy, 0) + 0x32`, tile callback HitBatTile,
first frame `+0x1a2 = 1`, `vy = 0` → `.HandleBurn` burn-away (via `.StandardSpriteCleanup`) removes it.
`+0x17e = 1` when member x + 12 < playerX. Members are hit by player shots (§3.6).
Level 11's two swarms carry p1 = 8, p2 = 0: members get **type 8** (count 8, radius 75); the type
only feeds `+4` (faces are set explicitly), so behaviour matches type 0x74c [MED: no other type-8
test found in this scope].

### 3.5 Insect 1860 body (Setup l. 16467–16492, l. 16741–16754 / 17146–17159)  [HIGH]
Setup spawns `MTNewSprite(own type, x, y, layer − 1, 0x200, SetupInsectBody)` into `+0x1d4`, its
Handle replaced by HandleInsectBody (only Standard handles/cleanup; no hit callback, empty rect). Each
Bat frame (before and after the body) copies to the body: face = sheet-1860 frame 8 (types
0x744..0x746 only), `+0xa/+0xc`, `+0x11c`, `+0x17e`, `+0x1ba`. `.KillBat` recurses into `+0x1d4`.
⚑ corrected (review 1c, 2026-10-03) (adjudication B4 tail): the first copy (`1007e744`) runs before the
Bat's own `.StandardSpriteHandles`, so it carries the previous frame's `+0x11c` [HIGH].

### 3.6 Damage taken, death, drops (`.HitBatSprite`, `.HitSwarmMemberSprite`, l. 17041–17080)  [HIGH]
- Player shot (handler HandlePlayerShot, shot `+0xa6 == 0`): `.KillPlayerShot`; spell id 1 →
  `.TurnIntoStatue`; else `.HurtSprite(s, shot+0xa4, shot vx >> 3, shot vy >> 3, invul 2, flash 8)`;
  on a hit: Bat — "bathit"; `+0xa6 < 2 → 0x15` (wakes a sleeper); BloodSpray if alive; HP < 201 →
  "uh oh" else (alive) "Ouch". Member — BloodSpray if alive, pitched swarm sound. (`HitSwarmMember`
  also requires the other sprite's `+4 ≠ 0x74d` — a shot's +4 is a spell id, so always true.)
- Statue or Box sprite: `.PlatformBounce`; if it returns 2 and (the box falls, `vy > 0`, or the bat
  is grounded `+0xce`) → HP 0 (crushed); `+0x150 = 0x16` has no reader in this class.
- Death: HP < 1 → `+0xb0 = 4`; next frame (l. 17041): "crawler death" 0x100, `+0x5c = 0`, face off,
  `.KillBat` (+100 score, stat §1.2, `+0xe9 = +0xea = 1`, recursive on `+0x1d4`), **+500 score**,
  coins: `rand(3) + 1` × `MTNewSprite(0x516, centre − 4, layer 2, SetupBonus)` with `vy = −0x578 −
  rand(0x640)`, `vx = rand(1000) − 500` (coin pickup = 1 coin, 5 score, spells-items.md §3); blood:
  N = 170 if prefs+6 == 1 else 100 (`*(_DAT_1009fe44+6)`, [MED] prefs pointer), N × `NewParticle(2,
  0x78, …)` + N/8 larger ones. Total score: bat 600, insect 700 (body +100).
- Tiles (`.HitBatTileSprite`): kind < 100 → `.WallBounce(…, 0, rect, 0, 0)`, < 200 →
  `.WallBounceBG`, water kinds → `.HandleUnderWater` unless `+0x140`.
- Unexplained tail (l. 17141): if the face is the placeholder face of PICT 151 (`*_DAT_100a007c`,
  `.InitSprites`) `+0xa6 += 0x45` [HIGH code; LOW purpose].

### 3.7 Variant summary (every type in the class ranges)

| type | role | placed |
|---|---|---|
| 1740 / 1745 | chaser bat, asleep / awake; 1740 becomes 1745 on waking | 28 / 0 |
| 1741 | path bat (p1..p4 path) | 3 |
| 1742 | path bat + spit (→ 1741 at Setup) | 2 |
| 1743, 1744, 1746..1749 | HP 500, no path set-up (`+0xf0 = 0`), `+0xa6 = 0` → hovers motionless, frame 0, faces the player [HIGH code] | 0 |
| 1850 / 1851 / 1852 | chaser / path / path + spit (→ 1851), HP 100, sheet by p1 sign | 0 / 45 / 0 |
| 1853, 1854 | HP 100, no path set-up → motionless, animated | 0 |
| 1860 | insect chaser + body | 5 |
| 1861 | insect body + head, path branch without path (motionless), animated | 0 |
| 1862..1868 | insect, motionless, face fixed at frame 3; 1868 is also the default member type | 0 |
| 1869 | swarm | 6 |

## 4. Gremlin (types 1770..1779; only 1770 placed)  [HIGH unless noted]

### 4.1 Composite set-up (l. 17312–17395; raw `1007fc88..1007fea8`)
Every part runs `.SetupGremlinSprite`: Handle HandleGremlin, Hit HitGremlin, **no tile callback**
(`+0x1f8 = 0`), Kill `+0x50 = KillGremlinSprite`, sheets 1770/1771/1772 marked needed, gravity 0,
HP 500 (`li r0,0x1f4`), rect (0x28,0x26,0x59,0x50), `+0x14c = 0`, `+0x150 = −1`, `+0xa6 = 0`,
`+0xb0 = 7`. A part whose `+0x48 == 0x1ff` (a child) gets an empty rect, no hit callback, not counted.
The parent (record) then sets layer 10, part index `+0xec = 0` and spawns, with recIdx 0x1ff:
- back layer `+0x1d4`: same x/y, layer 9, `+0xec = 1`, `+0xb8 = 0xb0000`, unlit, no hits;
- **rider** `+0x1d8`: at (x + 0x26, y + 0x1b), layer 12, `+0xec = 2`, backlink `+0x1d4` = parent,
  rect (6,3,0x1a,0x16) (bottom 0x1b − 5), tile callback HitGremlinTile;
then `.SetupProgrammedPath(s, −1, 0)` (p1 mode, p2 travel, p3 speed; p4 unused for modes 1/2),
`+0x188 = 1`, counted. Spawned at once (class table: "now"), so gremlins run from level load.

### 4.2 Body (`+0xec == 0`, l. 17440–17619)
- Copies `+0x14c` (rider state: 0 mounted, 1 dislodged, 2 rider dead) to the rider.
- Water (`+0x11c ≠ 0`, this frame): `vy −= 100` while > −800; fully submerged kind 0 **or any kind
  > 0 (including healing kind 3)** with no invul → HP −100, invul 0x13, flash 0x11, "Ouch" Rand 0x55,
  18% monster sound. ⚑ corrected (review 1c, 2026-10-03) #4: **dead code as shipped** — `1008061c or
  r3,r31,r31; bl 0x10036854` is a second `.StandardSpriteHandles` on the gremlin itself, right before
  the reads at `10080628`/`10080648`, and SSH zeroes `+0x11c` (`100369ac`), so the test never sees
  water (like the Frog/Salamander blocks, enemies-water-cave §0.1): gremlins neither slow nor take
  water damage. A replica copies the dead block as dead [HIGH].
- `.HandleProgrammedPath`. Mode 1: anim advances while `vy < +0x30` (previous frame's vy, copied by
  `.WrapDrawSprites`, main dump l. 10348) or mid-cycle; `vx ·= 0.8`; faces the player. Mode 2: anim
  always advances; faces by `vx` sign; `vy ·= 0.7`. Other modes: anim advances, faces player.
- Wing cycle: anim index `+0xa6` 0..21 → frame from the table built by `.InitGremlinSprite` (raw
  `1007faac..1007fc30`; 50 shorts copied from data 0x100a6dd0, count `0x16`): **0,0,0,1,1,2,2,3,3,4,4,5,5,5,6,6,7,7,8,8,9,9**;
  at ≥ 22 → 0 and "flap" 0x55. Body face sheet 1770, back layer the same frame of 1771.
- HP < 1 → state 4: `+0x5c = 0`, path off, `vx ·= 0.8` per frame, gravity 0x5a, tile callback
  HitGremlinTile; first frame `+0x1a2 = 1` (burn-away starts), **+1200 score**, 1..3 coins as bats,
  `vy = 0`, monster death sound if the rider is mounted. When `.HandleBurn` finishes it calls `+0x50`:
  `.KillGremlinSprite` → +2000 score, stat credit, back layer killed, mounted rider killed, rider
  backlink cleared. (Total 3200.)
- After integration: back layer follows (x/y, facing, frame, `+0x1bc`). Rider mounted: copies facing,
  flash `+0xaa`, `+0xb8`, burn row `+0x1bc − 0x1b`, position body + (0x26 facing-left | 0x3e
  facing-right, 0x1b). Rider not mounted: rider Hit = HitGremlin (now shootable) and, while the body
  lives, `rand(5) + 8` blood particles/frame from the saddle (x + 0x3a/0x4a, y + 0x2f).

### 4.3 Rider (`+0xec == 2`, l. 17620–17796)
- Dislodged/alone (`+0x14c ≠ 0`): HP < 1, or y > map height·32 (`hdr+0xb282 << 5`) → HP −1:
  dies — "crawler death", +500 score, 100/170 blood particles, tells the body `+0x14c = 2`,
  `+0x1d8 = 0`. Not counted, no stat.
- Fire control: cooldown `+0x15c` (starts 0) counts down; at ≤ 0 and not firing (`+0xb2 ≠ 9`):
  d = Dir(rider centre from player centre `*_DAT_1009fdd8+0xe` [MED: player-sprite pointer]).
  Facing left: d ∈ {16,17,18} → 18, d ∈ 19..24 → 22, else no shot; facing right: d ∈ {0,1,2} → 0,
  d ∈ 30..35 → 32. Dislodged rider: forced 18 (left) / 0 (right) and no shot if the player is behind.
  Also no shot if the body is dead, or (body alive) its centre is outside the view rect
  (camera h − 32 .. h + 640, v − 32 .. v + 416; `PTR_DAT_1009fe78`). If allowed and the rider is not
  dead-state 2: `+0x158 = (d + 18) mod 36` — **the shot direction is 0 / 4 (left, 40° down-left)
  or 18 / 14** — `+0x154 = 0`, `+0xb2 = 9` (raw `1008030c..10080350`). The following "face = frame 0
  of sheet 1772" write goes to the rider's own `+0x1d8`, which is always 0 (raw `10080354`), so it
  never happens: the rider's face is 0 (not drawn) until its first shot and rests on frame 0 after it
  [HIGH code; LOW visible effect — sheet 1772 may be only an overlay].
- Firing (`+0xb2 == 9`), t = `+0x154`: mounted on a mode-1 body → body `vx, vy ·= 0.65`; face frame
  t/2 for t < 8 else 6 − t/2; t == 1 firehiss2 (51%) / firehiss; **t == 7**: `MTNewSprite(0x712, x + 4,
  y + 6, layer − 1, −1, SetupEnemyShot)`, `AddDirImpulse(shot, dir, 0x708)`, shot `vx +=` body vx,
  shot rect bottom −3, dir 4 → shot `+0x17e = 1`, `+0x1aa = 0xdc`; dir 14 → `+0x1aa = 0x140` [MED:
  `+0x1aa` = draw rotation in degrees, copied to the face by `.WrapDrawSprites`]; t ≥ 12 → `+0xb2 = 0`,
  cooldown `rand(0x1e) + 0x1e`. t++ each frame. (raw `10080418..10080590`.)
- Then x += v, gravity/tiles; grounded → `vx ·= 0.5`.

### 4.4 Hits (l. 17799–17882; tiles l. 17920–17978)
Skips parts with `+0xe9`/`+0xea`. Player shot (`+0xa6 == 0`): statue for id 1; else HurtSprite as
bats; `+0xa6 < 2 → 0x15`; BloodSpray; HP < 201 and (rider mounted or this is a child) → "uh oh",
else alive → "Ouch" + 18% monster sound (body). **Body hit with rider mounted: 19% (`rand(100) >
0x50`) dislodges** — "crawler death" 0x55, `+0x14c = 1`, rider HP `rand(300) + 300`, rider
`vx = ∓(rand(200) + 300)` (sign by facing: left → negative), `vy = −0x226 − rand(200)`, gravity 0x96.
Statue/Box crush as bats. HitGremlinTile: dying body or rider → `vx ·= 0.8` and `.WallBounce(…, 0xa0,
…, 1)`; on a bounce |vy| < 0x100 → 0; other branches as bats.

## 5. Floater = Wraith (types 1780..1799; only 1780 placed)

### 5.1 Setup (l. 17979–18054; raw `100814b8..10081674`)  [HIGH]
Layer 0xb, Handle/Hit/HitTile = HandleFloater/HitFloater/HitFloaterTile, gravity 0, HP 500, `+0xb0 =
7`, counted. 0x6f4..0x6fd: sheet 1780, rect **(0x23,1,0x3e,0x4b)**, **tile callback 0** (passes
through terrain), hidden period `+0x14c` = p1 (0 → 0x41 = 65), initial hidden delay `+0xa6` = p2,
teleport box `+0x154` = p3 (0 → 0x50 = 80), home `+0x158/+0x15c` = record x/y, phase `+0x46 = 0`,
unlit. 0x6fe..0x707 (1790..1799): sheets 1790/1791 (absent), rect (0x17,2,0x38,0x5c), nothing else —
home 0, box 0 ⇒ `FastRand(0)` reseeds and returns garbage; with the 1780 sheet hard-coded in the
handler this variant is unfinished [HIGH code; MED "unfinished"]. Unplaced.

### 5.2 Cycle (l. 18055–18178)  [HIGH]
`+0xa6 > 0`: count down, invisible (`+0xc0 = 0`). Otherwise by phase `+0x46` (then `+0x46++`):

| phase | action |
|---|---|
| 0 | teleport: x = home x − box/2 + rand(box), y likewise; `vx, vy = rand(600) − 300` (constant drift) |
| 0..11 | frame 0; fade-in `+0xb8` = 0xb0002 (0..3), 0xb0000 (4..7), 0xb0001 (8..11); face the player |
| 12..19 | opaque (`+0xb8 = 0`), face the player |
| 20..28 | frames (phase − 18) >> 1 = 1..5 (wind-up) |
| 29 | fire: `MTNewSprite(own type, x + off − 12, y + 10, layer 0, −1, SetupEnemyShot)`, off = 6 facing left / 0x5e facing right; "elecshot" at (x + off, y + 0x16); shot `+0x15c` = Dir(player + (0,8)) [no reader found for type 0x6f4] |
| 30..64 | hold frame 5 |
| 65..74 | frames (10 − (phase − 65)) >> 1 = 5..1 |
| 75..86 | fade-out 0xb0001 / 0xb0000 / 0xb0002 per 4 phases; **while hurt-flashing (`+0xaa > 0`) phase = 0x4a, opaque** |
| ≥ 87 | invisible, phase → 0, `+0xa6` = hidden period |

Facing `+0x17e` = 1 when playerX ≥ centre x [MED: carry-idiom read]. Then
`.ApplyGravityAndSeparateFromTiles` (single displacement). The wraith bolt (EnemyShot 0x6f4, rect
(5,5,0x12,0xc), HP field 0x70, fades in by its own age, homes on (playerY + 8, playerX) with
`AddDirImpulse(·, 0x8c)` while age < 20, 16-frame anim; handler dump l. 5939–5947, 6140–6160) [MED:
EnemyShot belongs to the enemy-shot reading].

### 5.3 Damage taken  [HIGH code]
`.HitFloaterSprite`, only while visible (`+0xc0 ≠ 0`): player shot → `.KillPlayerShot`, statue for
id 1, **no HP damage**; an EnemyShot of the wraith's own type → HP −100, flash 10, "Ouch", shot
killed; Statue/Box crush → HP 0. **No code in the four Floater routines, nor in
`.StandardSpriteHandles`/`Cleanup`/`.UpdateSprites`, tests the Floater's HP** (raw scan of
`100814b8..10081f14`: `+0xa4` is never compared/branched on; its only read, `lha r4,0xa4` at `10081b5c`,
feeds the −100 write itself ⚑ corrected (review 1a, 2026-10-03) #8 — earlier "only written") — a wraith never dies of damage; no score, no drops
[HIGH for the scan; MED that nothing else removes it]. Statue reverts after 120 frames
(`.HandleStatueSprite`, l. 9853ff.).

## 6. Placement params (closes INDEX NOT-RESOLVED 1 for these classes)  [HIGH]

| class / types | p1 | p2 | p3 | p4 | byte +1 |
|---|---|---|---|---|---|
| Bat 1740/1745, 1743.., 1860.. | — | — | — | — | — |
| Bat 1741/1742 | path mode (§8.5) | travel px | speed | radial modes only | — |
| Bat 1850..1854 | path mode for 1851/1852; **sign < 0 = background variant** (all) | travel | speed | radial only | — |
| Bat 1869 swarm | member type (0 → 1868) | count (0 → 8, ≤ 20) | radius (0 → 75) | — | — |
| Gremlin 1770.. | path mode | travel | speed | radial only | — |
| Floater 1780..1789 | hidden frames (0 → 65) | initial hidden delay | teleport box px (0 → 80) | — | — |

"—" = no reader in the class's routines (record reads are `hdr + 0x48·16 + {8,10,0xc,0xe}`).

## NOT RESOLVED
1. `+0xb8` draw-mode values (0xb0000/1/2/4, 0x10009, 0x1000c): passed to `.WrapDrawFace` (main dump
   l. 10246–10351; flash overrides with 0x30000/0x40000) — the meaning of modes 0xb/1 not read.
2. `+0x84/+0x86` purpose (only zeroed for bats; player `.RectBounceFake2` writes them) — the bat gates
   look vestigial.
3. Whether `.STPlay3DSoundRand` randomises pitch (name only).
4. The `+0xa6 += 0x45` placeholder-face guard (§3.6).
5. `.WallBounce` argument semantics (bounce 0xa0, last arg 1) — physics.md §3 open item.
6. `.HandleBurn` row arithmetic (only its trigger and end — `+0xe9` or `+0x50` — are read here).
7. Statue-form interactions beyond the 120-frame revert (another reader's scope).
8. What sets `+0x1b2` (every handler returns early on it).
9. Whether children left active while a parent is idle (swarm members, insect body) are visible.

## Proposed additions to physics.md §0
`+0x28/+0x30` i32 previous-frame vx/vy (copied by `.WrapDrawSprites`) · `+0x50` proc kill callback
(called by `.HandleBurn` at the end instead of `+0xe9`) · `+0x54/+0x58` proc idle-out / idle-in
callbacks · `+0x88` u8 lit (`.WrapLightFace`) · `+0x9c` ptr per-sprite block (swarm member table) ·
`+0xa6` i16 per-class counter (bats: awake + anim; wraith: hidden countdown; gremlin: wing index;
player shot: 0 = live) · `+0xb0` i16 AI state (4 = dying) · `+0xb2` i16 secondary state (rider 9 =
firing) · `+0xb8` i32 draw mode for `.WrapDrawFace` · `+0xc0` ptr current face (0 = not drawn) ·
`+0xea` u8 killed → clear record flag · `+0xec` i16 composite part index · `+0x14c..+0x164` per-class
scratch (§3–5) · `+0x184` u8 no collision with same-handler sprites · `+0x188` u8 no record
write-back and no record clear on death · `+0x1a2` i16 burn-away progress (≠ 0 → `.HandleBurn`) ·
`+0x1aa`/`+0x1ae` i16 face rotation / scale [MED] · `+0x1b5` u8 counted enemy · `+0x1bc` i16 burn row
· `+0x1d4/+0x1d8` ptr linked parts · `+0x48` values 0x1ff/0x200 = spawned child, no record.

## Corrections to the existing bank
1. physics.md §7 table, Bat row "HP 100, 200": the 1740..1749 family is **500** (raw `1007dcc0`),
   1850 family 100, insects 200, swarm/members 100; rects per §3.1.
2. physics.md §7 Floater row rect (0x17,2,0x38,0x5c) is the unplaced 1790..1799 variant; the shipped
   1780 Wraith uses **(0x23,1,0x3e,0x4b)** and no tile callback (raw `10081550..1008155c`).
3. physics.md §7 "statue … 12 call sites": for the Floater the statue is the **only** effect of a
   player shot (no HurtSprite in `.HitFloaterSprite`).
4. physics.md §0 `+0x17e` "facing left": every flyer sets it to 1 when the player is to the right,
   and the bat spit flies `+0x708` (right) when it is set — for these classes 1 = facing right /
   mirrored art. Needs reconciling with the player's use [HIGH for these classes].
5. physics.md §8.5 "m = 3 floater" is a programmed-path mode, unrelated to the Floater class.
6. world-data-format.md §4.3 [MED: which counter is which]: `G+0x306`/`0x6ee` = enemies (§1.2).
7. physics.md §2: `.HandleBatSprite`/`.HandleGremlinSprite` pre-add v before
   `.ApplyGravityAndSeparateFromTiles` → 2·v per frame (§1.1) — worth a note there.
8. physics.md §7 "Statue/Box/Platform set `+0x185`" (review 1a #5, adj. 2): the Statue does **not** set `+0x185` — no `0x185` store in `100664a8–100665bc` (`.HandleStatueSprite`) or `10043138–100431c4` (`.TurnIntoStatue`); thaw `lha 0xa4; subi 0xc8; sth` at `1006656c–10066574`; `+0x130 = 0x78`, `+0x134 ← +0xb8` at `10043194–1004319c`.
9. physics.md §2 water gravity `max(0.7·g, 0x100)` — add the caveat (review 1a #2, adjudication 4): taken only when `+0x11c ≠ 0` at the routine's entry (`lwz 0x11c @100375c8`), before its own `SeparateFromTiles2` (`bl 1003c804 @10037624`); `.StandardSpriteHandles` zeroes `+0x11c` each frame (`100368d4 … 100369ac`), so every sprite's first call uses dry gravity; only a second same-frame call (Frog) or a direct `+0x11c` writer (Bonus 1055 in-water flag, 1350 air bubble) takes the 0x100 branch.
10. spells-items.md §2.1 (review 1a adjudication 1) — names only: id 2 "Ice Crystals" (cost 10, gravity 0, unholdable), id 3 "Ice Wall" (cost 0x1e `1005213c`, dmg 0x12c `10052138`, floes `1005a2e4–1005a30c`, ledges `1005b2c4/1005b2f4`), id 7 second Ice-Wall icon (cost 0xc, dmg 0x96, gravity 0xfa, no floe); PICT 700 captions 0..11 = Fireball, Statue, Ice Crystals, Ice Wall, Tree Trunk, Boomerang, VBlade, Ice Wall, DensityBall, Sandstorm, EnergyBolt, Ice Shards.
11. physics.md §5.1 `.HurtPlayer` (review 1a #1): refuses (returns 0) when the attacker's HP < 1 unless its handler is EnemyShot (TOC −0x73b8) or Box (TOC −0x73bc) — raw `10054768–10054798`; dead flyers do not hurt on contact (§1.3).
