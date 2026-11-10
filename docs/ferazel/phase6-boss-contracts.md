# Ferazel's Wand 1.0.3 — Phase 6 boss contracts (Task BOS)

Research only, 2026-11-11, base 2f25cf6. Every line number is the **committed** dump
`ghidra/ferazel/Ferazel_pef.decompiled.c` (88,106 lines), cited "M l. N"; raw addresses from
`Ferazel_pef.disasm.txt` are cited "raw XXXXXXXX". The bank (`bosses.md`, `bosses-2.md`, `bosses-3.md`) was read
against the dump line by line for the Warrior and the Chief, and state by state for the other three; where they
differ the dump wins and the difference is listed in §8 and appended to the bank file as a dated correction.
Constants were read from the PEF data with `docs/ferazel/tools/const.py` (the f64 / f32 values quoted below).

How to read a contract: **Setup** (every store in dump order), **Handle** (a table: state → what runs each frame,
what it leaves to, the random draws in order, the sounds, the spawns), **Hit**, **Kill**, **Init** (the cache sets and
their place in the registration list), **the three pieces** every boss task builds (its `EnemyCommon.killProc` case,
its `.HitPlayerSprite` step-7 row, its `.SmiteEnemies` entry), the **per-class duties** of the plan's "Every class
task also", the **engine features** it needs that are not built today, the **test list** and the **scripted kill**.

"R(n)" = `.FastRand(n)` (0…n−1, one draw of the one stream). "S" = the boss sprite. Velocities are 1/256 px a frame.
`+0x10` / `+0xe` = the stored hot-rect centre x / y; `*_DAT_1009fd94` / `*_DAT_1009fd90` = the player's centre x / y
(`PlayerState.centreX` / `centreY`). The facing idiom `(a <= b) − (…) & 1` (raw `10087f3c..10087f50`) is
"1 (facing right) iff the player's centre x > S's centre x" wherever it appears below ("face the player").

---

## 0. The five at a glance

| | Warrior | Goblin Chief | Wizard | Fire Guardians | Xichra |
|---|---|---|---|---|---|
| types / level | 1820…1829 (0x71c…) / 5 | 1910…1919 (0x776…) / 18 | 1830…1839 (0x726…) / 25 | 1920…1929 (0x780…) / 55 | 1990…1999 (0x7c6…) / 67 |
| spawn | now | idle | idle | now (+ partner, + 16 segments) | now (+ wing, + 2 cannons) |
| HP (boss flag p4 ≠ 0 / = 0) | 2000 / 1200 | 2000 / 1200 | 1000 / 1200 | 2000 / 1000 each | 5000 fixed (9999 at phase 6) |
| live states (+ dead code) | 4: 6, 7 (walk / run), 2, 4 | 5: 6, 1, 3, 2, 4 | 6: 6, 9, 2 (fireballs / crate), 12, 10, 4 (+ 11) | 5: 6, 2, 9, 8, 4 | 8 states (0, 1, 2, 4–8) × 7 phases (0–6) |
| shots spawned | 0x71f (EnemyShot, built) | 0x77b (EnemyShot, built) | 0x46a ×3 (EnemyShot, built) | 0x46a aimed (built) | 0x46a ×3 aimed; rain 0x753, 0x771/0x772 (built) |
| other children | 3 falling crates Box 0x433 (built arm) | — | hovering crate Box 0x434 (built arm) | partner guardian (same class), 8 neck segments each (**new class**) | wing (**new class**), cannons 0x443/0x449 (Background), minions 0x6d6 (Walker, built), rain Box 0x434 / 0x5c4, explosions Effect 0x4b7 |
| new `SpriteHandler` cases | none (`.warrior` exists) | `.chief` | `.wizard` | `.demon`, `.demonSegment` | `.xichra`, `.xichraWing` |
| hurt by | falling Statue / Box (200) | every player shot (`+0xa4`), falling solid (200) | falling solid with `+0x160 ≥ 0` (100) | player shots in roar frames 5…47 only, not V Blade | phase-dependent (§6.5) |
| contact damage (step 7) | 0x70 (row M l. 49840) | 0x70 (row M l. 49849) | 0x70 (row M l. 49846) | 0x70 (default; no row) | none (not in the list) |
| proposed tasks (tests) | 2 (8 + 8) | 2 (9 + 8) | 2 (9 + 7) | 3 (8 + 9 + 8) | 3 (9 + 10 + 8), plus 6C-XL |

---

## 1. What every boss shares (built at LV5 or before, unless marked)

### 1.1 The framework the five rely on

- **The arena** (`BossArena`, LV5 — built): `noBossAlive` `*_DAT_1009fed0`, `locked` `*PTR_DAT_1009fed4`, `panCounter`
  `*_DAT_1009ff9c`; `.SetupLevelSprites` writes `fed4 = 0`, `fed0 = 1` (M l. 2016–2019); `.PlayerConstraints`' arena
  part (M l. 44035–44100) and `.FindUpperLeftCorner`'s bounds (M l. 5937–6028, applied M l. 6168–6173). The routine
  `.PlayerConstraints` is still marked "partial — missing: boss-arena lock" in `routines-classified.tsv`; that row is
  stale (LV5 built it).
- **The gate** 2940 with p1 −1 opens while `fed0 == 1` (BT/LV5, `BoxSprite.gateArm`, M l. 61016–61064 — built).
- **The music rule** (LV5 — built): level start forces hdr `+0x284a = 30` when `+0x2724 ≠ 0 ∧ fed0` (M l. 5218–5219);
  every iteration `+0x2724 ≠ 0 ∧ fed0 ∧ track ≠ 30 ∧ prefs music ∧ no fade running` → fade out, then track 30
  (M l. 5266–5274, read before `_UpdateSprites`).
- **The burn** (`.HandleBurn @ 10043cd8`, M l. 38765–38838, called by `.StandardSpriteCleanup` while `+0x1a2 ≠ 0`,
  M l. 32661–32662 — built, `Burn`): on the frame `+0x1a2 == 1` the burn sound (`.STPlay3DSoundRand(snd PTR_DAT_100a01ec,
  1, 0xab)` — one R(10000) — or, with `+0x8c`, R(15000) and the pitched call at 110000 + R); a positive `+0x1a2` below
  the face's `+8` jumps to it; then `+0x8d + 1` rows a frame, each `+0x1a2 + 1`, `.BurnFaceRow`, and with prefs
  effects 1 (Enhanced) and `+0x8d == 0` one R(100) a row (> 0x32 → a second row pass); when the face's `+0xc` <
  `+0x1a2` → the Kill proc `+0x50` (none → `+0xe9 = 1`) (M l. 38824–38834).
  **Kill-frame formula** (used by every scripted kill below): with `T` / `B` the burning face's `+8` / `+0xc`
  (opaque top / bottom) and `k = +0x8d + 1` rows a frame, a burn started by the Handle on frame F reaches the Kill on
  frame `F + ⌈(B − T + 1) / k⌉ − 1` (the first pass runs in F's own Cleanup).
- **The counting window** (`EnemyCounting`, built): each boss Setup counts itself (`+0x1b5 = 1`, live + 1) only while
  `_DAT_1009fe8c` is set (M l. 2521–2526); its Kill (all five Kills share the head, e.g. M l. 73479–73485) does live
  − 1 and `G+0x306+2L` + 1 when `+0xe9 == 0 ∧ +0x1b5`, then `+0xe9 = 1`, `+0xea = 1`.
- **The boss-kill tail** (Warrior, Chief, Wizard: with `+0x170 ≠ 0`; Xichra: always; Demon: guardians with the flag):
  `.STPlay3DSoundPitched(snd 453 *_DAT_1009fd68, 1, 0x100, +0xe, 48000)` (no draw), shake `*_DAT_1009ffa0 = 0x1e`, the
  mask flash `*_DAT_100a00fc = 3`, `fed0 = 1`. Shake and flash are built (`Camera.shake`, `ScreenFlash`, EF).
- **Death entry** (Warrior, Chief, Wizard, Demon): after the state switch, `HP < 1 ∧ +0xb0 ≠ 4` → `+0xb0 = 4`,
  `+0x46 = 0`, `+0xa6 = 0`, `.STPlay3DSound(snd 703 *_DAT_100a026c, 1, 0x100, +0xe)` (no draw; the Chief draws first,
  §3).
- **The wounded glow** (Warrior, Wizard, Xichra; not the Chief, not the Demon): `+0xf0 − 1`; at 1…3 `+0xb8 = 0x10008`,
  at 4…6 `0x10009` (only under the class's HP threshold); at ≤ 0 reload (class period) and `+0xb8 = 0`. A falling-solid
  hit writes `+0xf0 = 0`.
- **The Statue spell**: no boss Hit calls `.TurnIntoStatue` (raw scan of `bl 0x10043138`, bosses §1.5) — a Statue shot
  is an ordinary player shot to every boss. Each boss task's "Statue arm" is therefore *none*, pinned by one test row.
- **Environmental hazards** (`EnemyCommon.environmentalHazard`): no boss Hit tests the 0x4b7 explosion or 0x5a0 — none.
- **`.MTNewSprite`** (M l. 30690–30717): stores `+0x80` = the layer argument, then runs the Setup, then re-stores
  `+0x48`, then inserts — so **a Setup's own layer store wins** over the caller's argument; a spawn that finds no free
  record returns 0 and the caller's later stores go to address 0 + offset (the port drops them, Ruling 16).

### 1.2 The three pieces (named for every boss)

1. **`EnemyCommon.killProc` case** — today the `.warrior` arm exists and runs only the count
   (`EnemyCounting.kill`, `// later: Phase 6 — .KillWarrior's tail`, `EnemyCommon.swift:98–107`); the other four
   bosses have no arm (they are `.inert`). Each boss task adds or completes its arm with the tail of §1.1.
2. **`.HitPlayerSprite` step 7** — the routing list (M l. 49514–49521) sends the Handles 0494 (Warrior), 04b0 (Demon),
   04bc (Chief), 0490 (Wizard) — with the walkers' and others' — to the generic enemy path (M l. 49802–49929). Damage rows
   (M l. 49827–49851): Warrior 0x70 (49840–49842), Wizard 0x70 (49846–49848), Chief 0x70 (49849–49851); the Demon has no
   row and takes the default 0x70; coins 3 when R(100) > 0x50 (drawn before `.HurtPlayer`); invulnerability 0x3c.
   Xichra's Handle (048c) is in neither list: **no contact damage**. The port: `HitPlayerSprite.hit`'s
   `case .walker, … .warrior, …` (`HitPlayerSprite.swift:67`) gains `.chief`, `.wizard`, `.demon` — the damage needs no
   new code (the default is 0x70).
3. **`.SmiteEnemies` entry** (M l. 46981–47046): the walk compares `+0x4c` against 15 Handles, the five bosses among
   them (048c Xichra, 0490 Wizard, 0494 Warrior, 04b0 Demon, 04bc Chief); the first 16 matches each get a player shot
   0x5a01 at their stored centre − 4 (layer 0xb, `+0xf0 = 0`, `+0xa6 = 0`). `Smite.enemyHandlers` holds `.warrior`
   today; each boss task appends its case. Not listed: the Demon's segments (handler 0d64), Xichra's wing (0dcc).

### 1.3 Re-map of the bank's line numbers (old 64,189-line dumps → committed dump)

| bank cite | routine | committed dump |
|---|---|---|
| handler l. 20023–20113 / 20114–20420 / 20421–20463 / 20464–20496 / 20497–20531 | Warrior Setup / Handle / Hit / Kill / HitTile | M l. 72989–73077 / 73115–73419 / 73422–73462 / 73465–73495 / 73498–73530 |
| main l. 52954 / 52968 / 52983 | `.InitWarriorSprite` / `.WarriorLayEgg` / `.RandomWarriorAttack` | M l. 72975–72986 / 73080–73092 / 73095–73112 |
| l. 21470–21556 / 21557–21838 / 21839–21896 / 21897–21929 / 21930–21964 | Chief Setup / Handle / Hit / Kill / HitTile | M l. 75031–75115 / 75162–75441 / 75444–75499 / 75502–75532 / 75535–75567 |
| main l. 53540 / 53563 | `.InitChiefSprite` / `.GoblinChiefRandomCry` | M l. 75008–75028 / 75118–75159 |
| l. 21965–22060 / 22061–22460 / 22461–22509 / 22510–22542 / 22543–22577 | Wizard Setup / Handle / Hit / Kill / HitTile | M l. 75591–75684 / 75687–76084 / 76087–76133 / 76136–76166 / 76169–76201 |
| l. 22370–22394; main l. 53607 | Wizard crate carry; `.InitWizardSprite` | M l. 76011–76045; 75570–75588 |
| l. 20886–21022 / 21023–21039 / 21040–21368 / 21369–21429 / 21430–21469 | Demon Setup / SegSprite / Handle / Hit / Kill | M l. 74367–74501 / 74561–74575 / 74578–74904 / 74907–74965 / 74968–75005 |
| main l. 53440–53482 / 53483–53539; l. 21300–21333 / 21336–21366 | `.InitDemonSprite` / `.HandleDemonSegs`; neck motion / position | M l. 74324–74364 / 74504–74558; 74843–74868 / 74876–74900 |
| l. 22589–22772 / 22578–22588 / 22773–23546 / 23547–23653 / 23654–23686 / 23687–23708 | Xichra Setup / Wing / Handle / Hit / Kill / HitTile | M l. 76263–76444 / 76238–76246 / 76570–77341 / 77344–77448 / 77451–77481 / 77484–77503 |
| l. 22840–22955 / 22995–23400 / 22811–22833 | Xichra phase switch / state switch / debug key | M l. 76644–76792 / 76793–77194 / 76618–76643 |
| main l. 53628 / 53676 / 53715 / 53749 | `.InitXichraSprite` / `.StandardXichraFloat` / `.UpdateXichraCannons` / `.DoXichraShot` | M l. 76204–76235 / 76447–76483 / 76486–76517 / 76520–76567 (`.sinDegrees` 76249–76260) |
| main l. 43386–43449; 5905–5960, 6133–6137 | `.PlayerConstraints`; `.FindUpperLeftCorner` | M l. 43991–44126 (arena 44035–44100); 5882–6239 (5937–6028, 6168–6173) |
| main l. 5183–5185 / 5231–5240 | music force / rule | M l. 5218–5219 / 5266–5274 |
| main l. 38598–38608; 32436; 32479–32500 | `.HandleBurn` Kill call; Cleanup's burn call; `.HurtSprite` | M l. 38824–38834; 32661–32662; 32705–32724 |
| main l. 4924–4930, 4936–4942 | `.UpdateSprites` write-back guard / record clear | M l. 4959–4966 / 4971–4999 |
| main l. 30679–30683 | `.MTNewSprite` Setup call | M l. 30710–30717 |
| main l. 44078; handler l. 4224–4230 / 4511–4624 | `.SmiteEnemies`; step-7 routing / generic path | M l. 46981–47046; 49514–49521 / 49802–49929 |
| handler l. 13235–13285; 12443–12470 | Box gate p1 −1; Box hovering rock | M l. 61016–61064; 60222–60284 |

---

## 2. Manditraki Warrior (types 0x71c…0x725; level 5) — 6A-W ⚑

Callbacks set by Setup: Handle `+0x4c` = `PTR_PTR_100a0494`, Hit `+0x5c` = `0d44`, tile `+0x1f8` = `0d40`, Kill `+0x50`
= `0d3c`. Today: `Warrior.swift` holds the whole Setup (LV5) and a ◇ Handle; Hit and Kill bodies are empty stand-ins.

### 2.1 Init — `.InitWarriorSprite` (M l. 72975–72986)
Three sets, 0xb4 × 0xa0 (180 × 160), all faces in one row, flag 0 (no `*_DAT_100a0a48` wrapper):
`PTR_DAT_100a0d50` 0x71c walk (8), `_DAT_100a0d4c` 0x71d attack (8), `_DAT_100a0d48` 0x71e death (6). Registered by
`.InitSprites` at M l. 134, right after the Dillo's four (M l. 133) — already in `CachedFaces.sets` (LV5). The 0x71f
shot is a boot set (`EnemyShot`), not cached.

### 2.2 Setup — `.SetupWarriorSprite` (M l. 72989–73077) — built (LV5), re-read, agrees
`.InitSprite`; `+0x84 = +0x86 = 0`; layer 0xc; the four callbacks; `+0x18a = 1`; marks 0x71c, 0x71d, 0x71e
(M l. 73028–73030); `+0x170` = record p4; gravity 0x122; `+0xc0 = 0`; p4 = 0 → HP 0x4b0, else HP 2000, `fed0 = 0`,
`+0x88 = 0`; `+0x1b4 = 1`; `+0x168 = HP`; `+0xc ← +8`, `+0xa ← +6`; hot rect SetRect(0x1a, 0x17, 0x4a, 0x3a);
`+0x150 = −1`; `+0xb0 = 6`, `+0xb2 = 0`, `+0x46 = 2`, `+0x14c = 0`; `+0xa6 = R(10)`; record p2 0 → 0x96 (written to the
live record); `+0x15c / +0x160 = x ∓ 0x15e`; `+0x168 = x`; `+0x164 = 0`; R(100) → `+0x17e = (R > 0x32)`; face 0x71c[0];
`+0xf0 = 0x1e`; the counting window; `+0x14 / +0x1c = +8 / +6 << 8`. Draws: R(10), R(100).

### 2.3 Handle — `.HandleWarriorSprite` (M l. 73115–73419)
Head (every live frame): `+0xe9` or `+0x1b2` → return; `.StandardSpriteHandles`; hot rect SetRect(0x2a, 0x3c, 0x89,
0x88), then left −10 when facing left, right +10 when facing right (M l. 73144–73150).

**Boss-mode block** (only `+0x170 ≠ 0`; runs whatever the lock, M l. 73151–73213):
1. Crate slots `+0x1d4`, `+0x1d8`, `+0x1dc`: a slot whose sprite has `+0xe9` set is emptied.
2. Any slot empty → `+0x16c − 1`; when `+0x16c < 1`, every empty slot gets `MTNewSprite(0x433, +0x168 + d, +0xa −
   h, layer 9, record −1, Box setup _DAT_1009ff34)` with (d, h) = (−0xba, 400), (+0x46, 500), (+0x146, 400) in that slot
   order. All three present → `+0x16c = 15`. `+0x16c` starts 0, so the **first Handle frame spawns all three**; on
   level 5 (home 875, y 227 while unlocked) at x 689 / 945 / 1201, y −173 / −273 / −173. A destroyed crate comes back
   15 frames after the frame it is seen dead (`+0x16c` was 15 → 14 … → 0); a crate at rest keeps its slot.
   The decompile reuses the setup-proc variable for the third spawn's result (M l. 73178) — a register reuse with no
   effect (the proc is reloaded each frame).
3. The glow: `+0xf0 − 1`; v = `+0xf0`: 1…3 → (HP < 0x3e9) `+0xb8 = 0x10008`; 4…6 → (HP < 0x3e9) `0x10009`; else v < 1 →
   reload 0xf when HP < 0x1f5 else 0x1e, and `+0xb8 = 0` (whatever the HP).

**State switch** (`+0xb0`, M l. 73215–73391; states 0, 1, 3, 5 and > 7 do nothing):

| state | per frame (dump order) | leaves to | draws | sounds / spawns |
|---|---|---|---|---|
| 6 decide | face 0x71c[0]; `+0xa6 > 0` → − 1; **`fed4 == 0` → return** (no ×0.5, no death test, no gravity, no liquids, no Cleanup — the sprite is not moved or animated by the engine while the arena is open); `+0xa6 < 1` → decide (below); then vx × 0.5 (f64 0x100a1c40) | 7 or 2 | decide: R(100) r; walk branch R(3), R(100), [R(100) → `.WarriorLayEgg`: R(2)]; attack branch `.RandomWarriorAttack`: **R(100) discarded**, R(2) | — |
| 7 walk (`+0x14c == 0`) | face 0x71c[n >> 1]; n > 14 → n = 0, `+0xa6 − 1`, x outside [`+0x15c`, `+0x160`] → `+0xa6 = 0`, `+0xa6 == 0` → state 6, `+0xa6 = R(9) + 4`; n + 1; vx = ±0x600 by facing | 6 | R(9) at the cycle end that leaves | — |
| 7 run (`+0x14c ≠ 0`) | face 0x71c[n]; n > 6 → the same cycle end; n + 1; vx = ±0xc00 | 6 | R(9) | — |
| 2 attack | vx × 0.4 (0x100a1c38); n < 2 → face 0x71c[0], face the player; else: n == 7 → R(6000), snd 704 `*_DAT_100a0268` (1, 0x100, +0xe, 50000 + R); face = word at `0x71d set + (n >> 1)·4` = attack face (n >> 1) − 1; n == 9 → `MTNewSprite(0x71f, cx ± 0x30 − 0x18, cy − 0x25, 0, −1, EnemyShot setup PTR_PTR_100a0830)`, shot vx = 0xb00, negated facing left; n > 16 → n = 0, `+0x14c − 1`, < 1 → state 6, `+0xa6 = R(9) + 4`; then n + 1 | 6 | R(6000) at n = 7; R(9) at the end | snd 704; shot 0x71f |
| 4 dying | vx × 0.9 (0x100a1c30); face 0x71e[n >> 2]; n + 1, cap 0x17; `+0xa6 + 1`; `+0xa6 == 0x2d` → `+0x1a2 = 1` | — (the burn ends in the Kill) | — | — |

Decide (M l. 73341–73387): r = R(100); `|playerCY − cy| < 0x50` → T = 0x41 and face the player, else T = 0x13;
`*_DAT_1009ffa8` (the game-over flag) set → T = −1. **r > T → walk / run**: state 7, n = 1, face 0x71c[0],
`+0xa6 = R(3) + 2`, then R(100) > 100 − T → run (`+0x14c = 1`) else walk (`+0x14c = 0`) and R(100) > 0x50 →
`.WarriorLayEgg` (`+0x154 = 2`, `+0xa6 = 5`, `+0x14c = R(2) + 1` — so the "egg" turns the walk into a run and
nothing reads `+0x154`); then x > `+0x160` → face left, else x < `+0x15c` → face right. **Else → attack**
(`.RandomWarriorAttack`, M l. 73095–73112: R(100) **discarded** (raw `10087b7c..10087b84`: `li r3,0x64; bl FastRand`, the
result never read), `+0xb0 = 2`, n = 0 (written twice), `+0x154 = 0`, `+0xa6 = 0x10`, `+0x14c = R(2) + 1` swings).

Timing facts: the walk cycle is 15 frames (n 1…15), the run 7 (n 1…7); the **first** swing is 18 frames (n 0…17,
the shot at the 10th), every later swing 17 (the reset leaves n = 0 and the same frame's + 1 makes it 1).

**Tail** (M l. 73392–73417): death entry (§1.1); `.ApplyGravityAndSeparateFromTiles` with the tile callback
(`.HitWarriorTileSprite`, M l. 73498–73530 — the Crawler's body, `CrawlerRoach.hitTile`); liquids — in liquid
(`+0x11c ≠ 0` and (`+0x11c == 1 ∧ kind 0` or kind > 0)): kind 3 heals 4 below HP 500; kind 2 with `+0x116 == 0` →
`+0x116 = 0x13`, HP − 100, `+0xaa = 0x11`, snd 701 vol 0x55 — exactly `EnemyCommon.liquids(class: .dillo)`;
`.StandardSpriteCleanup`.

### 2.4 Hit — `.HitWarriorSprite` (M l. 73422–73462)
- Other's `+0x4c` = the player-shot Handle (`PTR_PTR_100a04e8`) ∧ shot `+0xa6 == 0` ∧ HP > 0 →
  `.KillPlayerShot(shot, sound 0, effect 1)`, `.STPlay3DSound(snd 303 *_DAT_100a041c, 1, 0x100, shot +0xe)`. Immune.
- Else other is a Statue (`01f8`) or a Box (`0484`): `.PlatformBounce(S, solid, S's hot-rect centre offset, 0, S's
  rect, 0)` == 2 ∧ (solid vy > 0 ∨ S `+0xce`) → `.HurtSprite(S, 200, solid.vx >> 1, −1000, 2, 8)`, `+0xf0 = 0`,
  `.KillBox(solid)`, R(10000) → snd 701 at 42000 + R, R(10000), R(2) → snd 477/478 (`_DAT_100a0320[R]`) at 42000 + R.
  Sounds and `.KillBox` run whether or not the hurt landed. 2000 / 200 = **10 crate hits**.
- The shot's `+0xa6 ≠ 0` or HP ≤ 0 (dying): a player shot passes through.

### 2.5 Kill — `.KillWarrior` (M l. 73465–73495)
The head (count, `+0xe9 = 1`, `+0xea = 1`), then with `+0x170 ≠ 0` the tail of §1.1 (thunder 48000, shake 0x1e, flash
3, `fed0 = 1`). No score. The gate opens from the next gate Handle; track 30 by the loop rule.

### 2.6 The three pieces and the class duties
- killProc: the existing `.warrior` arm gains the tail (M l. 73486–73493).
- step 7: exists (`.warrior` in the routing case; damage 0x70) — a test row only.
- Smite: exists (`Smite.enemyHandlers[0]`) — the seed is absorbed (killed + 303).
- Statue arm: none. Liquids: the `.dillo` row. Hazards: none. Idle margins: none (spawned now). Picture marks: built.
- Write-back flags: Setup `+0x18a = 1` (built, LV5 test exists); Kill `+0xea = 1` — one Setup-test row each.

### 2.7 Engine features the Warrior needs that are not built
- **6A-FR**: `.HitPlayerSprite`'s rock arm (M l. 49170–49188): a 0x434 with `+0x160 < 0` → return; 0x433 (`+0x160 ≥
  0`) with its centre y above the player's and vy ≥ 600 → `.HurtPlayer(player, rock, 0x38, blood 1, invul 0x1e, coins
  0)` + `.KillBox`; 0x434 likewise with 0x70 / invul 0x3c (`HitPlayerSprite.swift:177`, `// later: Phase 6`). The
  crates are the level-5 fight's whole damage source, so 6A-FR lands before or with 6A-W.
- Nothing else: the Box 0x433 Setup and Handle arms (`BoxSprite.isBoulder`, `boulder`), `.KillBox`, `.PlatformBounce`,
  `.HurtSprite`, the burn, the shot 0x71f, shake, flash, gate and music are built. **6A-FB (the fireball cache) is not a
  Warrior dependency** — no Warrior code touches 0x46a (§8 D19).

### 2.8 Hazards for the build
- Crate slots are record pointers into the 700-record pool and are tested by the dead flag only: a crate record freed
  and re-used by another spawn before the Warrior's next look reads the new occupant's `+0xe9`. The build keeps the
  slots as the pool's record identity and pins the case where a crate dies and a spawn re-uses its record in one frame.
- Every Handle frame may spawn (crates, the shot): no `SpriteSlot` copy held across a spawn (`SpriteWorld` rule 2).
- A spawn with no free record (Ruling 16): `+0x16c` keeps counting below 1 and the empty slot re-tries every frame.
- `.KillPlayerShot(shot, 0, 1)` makes an effect sprite: the `staleSlot` (r29 + 0x9a) of this call site is traced in
  the raw (`PlayerShotHits.kill`'s rule) by the build.

### 2.9 Proposed split and tests (`Tests/FerazelCoreTests/Enemies/WarriorTests.swift`)
**6A-W1 — the Handle** (replaces the ◇ in place; the switch-off check returns LV5's goldens):
1. `testWarriorCratesFirstFrame` — three 0x433 at (689, −173), (945, −273), (1201, −173), layer 9, slots filled; next
   frame `+0x16c` = 15.
2. `testWarriorCrateRespawnAfter15` — a crate killed on frame k is replaced on frame k + 15 (first empty-seen frame +
   14), in slot order.
3. `testWarriorUnlockedReturnsBeforeGravity` — arena open: y unchanged, `+0xa6` counts to 0 and stays, no R(100) drawn.
4. `testWarriorDecideDraws` — a seeded decide consumes R(100), R(3), R(100)[, R(100), R(2)] in that order; T 0x41 / 0x13.
5. `testWarriorAttackDiscardsR100` — `.RandomWarriorAttack` consumes R(100) then R(2); `+0xa6` 0x10.
6. `testWarriorSwingTimingAndShot` — snd 704 on n = 7 (rate 50000 + R(6000)), shot 0x71f on n = 9 at (cx ± 0x30 − 0x18,
   cy − 0x25), vx ±0xb00; first swing 18 frames, next 17.
7. `testWarriorWalkRunCycles` — walk 15 frames vx ±0x600, run 7 frames ±0xc00, patrol bound forces `+0xa6 = 0`.
8. `testWarriorDeathAndGlow` — HP 0 → state 4, snd 703; `+0x1a2 = 1` on dying frame 45; glow 0x10009 / 0x10008 at HP ≤
   1000, period 15 at HP ≤ 500.
**6A-W2 — Hit, Kill, the fight** (with 6A-FR):
1. `testWarriorAbsorbsShots` — a player shot killed (sound 0, effect 1) + snd 303; HP unchanged; a Smite seed the same.
2. `testWarriorCrateCrush200` — a falling 0x433 landing: HP − 200, `+0xf0 = 0`, `.KillBox`, R(10000), R(10000), R(2).
3. `testWarriorStatueShotIsAShot` — a Statue-spell shot is absorbed (no `.TurnIntoStatue`).
4. `testWarriorLavaAndBrine` — kind 2: −100, invul 0x13, flash 0x11, snd 701 vol 0x55; kind 3: +4 below 500.
5. `testWarriorKillTail` — the count, `+0xe9`, `+0xea`, snd 453 at 48000, shake 0x1e, flash 3, `noBossAlive = 1`; with
   p4 0 no tail.
6. `testWarriorKillFrameFormula` — Kill on dying frame 45 + (B − T) of 0x71e[5] (B, T read from the face store).
7. `testWarriorContactAndWriteBack` — step 7 hurts 0x70 (R(100) drawn first); Setup `+0x18a`, Kill `+0xea`.
8. `testWarriorScriptedKill` — see 2.10.

### 2.10 Scripted kill — measured by the build, not derivable on paper
What is fixed on paper: the death-to-Kill tail (45 dying frames, then `B − T` burn frames of face 0x71e[5], 1 row a
frame, `+0x8c = +0x8d = 0`, plus one R(100) a row at effects 1) and the 10-crate arithmetic. What is not: the frame the
tenth crate lands, which depends on the player's path into the arena (the lock at x < 1384), the RNG stream from the
seed through every level-5 sprite, the Box physics of each crate and the Warrior's walk. The build task chooses the
seed (the session's default) and a key script (walk left into the arena, then the moves that bring crates down on
him), **measures** the HP-0 frame and the Kill frame once, checks Kill − HP0 = 45 + (B − T), and pins both; any later
change is a STOP (Invariant 10). No frame number is given here.

---

## 3. Goblin Chief (types 0x776…0x77f; level 18) — 6A-CH ⚑

Callbacks: Handle `PTR_PTR_100a04bc`, Hit `0d90`, tile `0d8c`, Kill `0d88`. Today `.inert` (no `SpriteHandler` case).

### 3.1 Init — `.InitChiefSprite` (M l. 75008–75028)
`*_DAT_100a0a48 = 1`; four sets 0x100 × 0xfe (256 × 254), 4 a row: `PTR_DAT_100a0da4` 0x777 throw A (4),
`_DAT_100a0da0` 0x778 throw B (4), `_DAT_100a0d9c` 0x779 jump (4), `_DAT_100a0d98` 0x77a death (4); then the single
`_DAT_100a0d94` 0x776 (standing); `*_DAT_100a0a48 = 0`. **All five records carry flag 1** (reloaded when the CLUT ids
differ, `.NeedToReloadForThisClut`). Registration: `.InitSprites` M l. 136 (after the Wizard's) — `CachedFaces.sets`
gets 0x777, 0x778, 0x779, 0x77a after the Wizard's 0x727, 0x728 (which follow the Warrior's 0x71e); `singles` gets
0x776 after the Wizard's 0x726, both after the Crab's 0x767.

### 3.2 Setup — `.SetupChiefSprite` (M l. 75031–75115)
`.InitSprite`; `+0x84 = +0x86 = 0`; layer 0xc; the four callbacks; marks the single 0x776, sets 0x777…0x77a and
`_DAT_100a083c` (the 0x77b boulder set) (M l. 75067–75075); `+0x170` = p4; gravity 0x276; `+0xc0 = 0` (no face until the
first Handle frame); `+0x8d = 1` (burns 2 rows a frame); p4 = 0 → HP 0x4b0, else HP 2000, `fed0 = 0`, `+0x88 = 0`;
`+0x168 = HP`; re-seat `+0xc ← +8`, `+0xa ← +6`; hot rect SetRect(0x5e, 0x55, 0xa5, 0xd4); `+0xb0 = 6`, `+0xb2 = 0`,
`+0x46 = 2`, `+0x14c = 0`; `+0xa6 = R(10)` (drawn, then overwritten); lane `+0x15c = 2`; `+0x164 = 0`; `+0x17e = 1`;
`+0xf0 = 0x1e` (no reader); `+0x46 = 0`; `+0xa6 = 0`, then `+0xa6 = −40`; the counting window; `+0x14 / +0x1c`.
**No `+0x18a`, no `+0x1b4`.** Draws: R(10).

### 3.3 Handle — `.HandleChiefSprite` (M l. 75162–75441)
Head: `+0xe9 == 0 ∧ +0x1b2 == 0` (else nothing at all); `.StandardSpriteHandles`; hot rect SetRect(0x58, 0x73, 0xac,
0xd2). Faces: S = standing 0x776, A = throw A 0x777, B = throw B 0x778, J = jump 0x779, D = death 0x77a.

| state | per frame (dump order) | leaves to | draws | sounds / spawns |
|---|---|---|---|---|
| 6 wait | vx = 0; face S; `fed4` set → `+0xa6 + 1`; `+0xa6 > 15 ∧ +0xcd` → n = 0, `+0xa6 = 0`, state 1 | 1 | — | — |
| 1 jump | i = n / 2 (toward 0) from the old n, n + 1, i cap 2, face J[i]; **new n == 3** → R(100) r, R(6000) p, snd 414 `*_DAT_100a03f8` (prio 0x14, vol 0xab, +0xe, 35000 + p), vy = −0x2904, `+0xce = 0`, the lane change by r (< 0x21 / < 0x42 / else): lane 2 → vx −0x700 / 0 / +0x700, lane 1 → 0 / +0x700 / +0xe00, lane 3 → −0xe00 / −0x700 / 0, `+0x15c` = 1 / 2 / 3; else new n > 3 ∧ vy > 0 → `+0xa6 = 0`, n = 0, state 3 | 3 | R(100) then R(6000) | snd 414 |
| 3 land | not grounded (`+0xcd == 0`) → face J[3]; grounded: n == 0 → R(12000), snd 435 `*_DAT_1009fdec` (1, 0xab, +0xe, 40000 + R), shake `= 0x16`, player `+0xce ∨ +0xcd` → **stagger `*_DAT_100a0570 = 0x18`**, vx = 0, face the player; faces n 0–1 S, 2–4 A[0], 5–6 S; n < 6 → n + 1, else R(2) → `+0x158 = R + 2` throws, state 2, n = 0, `+0xa6 = 0` | 2 | R(12000) on landing; R(2) at n = 6 | snd 435, shake, stagger |
| 2 throw | i = n >> 1: < 4 → A[i], < 8 → B[i − 4], else S; **n == 7** → R(8000), snd 704 (1, 0x5f, +0xe, 45000 + R), `MTNewSprite(0x77b, +0xc + (right ? 0xa1 : −0x11), +0xa + 0x33, +0x80 − 1, −1, EnemyShot setup)`, boulder `+0x17e` = S's facing, `+0x46 = 15`, vx = R(500) + 4000, vy = −0x4b0 − R(0x96); `|playerX − cx| < 0xf0` → vx × 0.8 (0x100a1c98), vy = 2000 (the `< 0x9b` branch, vx × 0.5 / vy 0xc80, is unreachable after it); facing left → vx negated; then n == 0 → face the player, `+0x158 − 1`, < 1 → `+0xa6 = 0`, n = 0, state 6, face S, else state 2, n + 1; n < 0x12 → n + 1; else `+0xa6 = 0`, n = 0 | 6 | R(8000), [the 0x77b Setup's], R(500), R(0x96) at n = 7 | snd 704; boulder 0x77b |
| 4 dying | vx × 0.9 (0x100a1c88); face D[min(n >> 2, 3)]; n + 1, cap 0x10; `+0xa6 + 1`; `+0xa6 == 0x14` → `+0x1a2 = 1` | — | — | — |

Throw cycle = 19 frames (n 0…18); the decrement precedes the first throw, so a landing gives **1 or 2 throws**. The
first jump comes 56 frames after the lock (`+0xa6` −40 → 16), later ones 16 frames after the last throw cycle.

**Tail** (M l. 75419–75438): `+0xb2 > 0` → `< 5` ? + 1 : 0 (a hit counter with no consumer; the raw keeps an emptied
switch, bosses-3 §10.3); death entry with **R(100) < 0x3c → `.GoblinChiefRandomCry` first**, then snd 703;
`.ApplyGravityAndSeparateFromTiles` (tile callback = the Crawler body, M l. 75535–75567); `.StandardSpriteCleanup`.
**No liquids test, no glow.**

`.GoblinChiefRandomCry(S)` (M l. 75118–75159): R(100) r (always drawn); only if none of 465, 466, 467 is playing
(`FUN_100916dc`, global, tested in that order): r < 0x29 → R(10000), snd 467 vol 0xc9; r < 0x47 → R(10000), 466 vol
0xab; else R(10000), 465 vol 0xab; rate 42000 + R. (Not `EnemyCommon.goblinRandomCry`, which draws R(500).)

### 3.4 Hit — `.HitChiefSprite` (M l. 75444–75499)
- Player shot ∧ shot `+0xa6 == 0` ∧ HP ≥ 1: `.KillPlayerShot(shot, 0, 0)` (silent) **first**; `.HurtSprite(S, shot
  +0xa4, 0, 0, 2, 8)` — on a miss (invulnerable) return, the shot is wasted; on a hurt: `+0x116 = 15`, `+0xb2 = 1`,
  `.BloodSpray(S, shot, 0x28, 400, 0x96, 2)`, HP < 0xc9 → snd 702 (`_DAT_100a0270`) else snd 701, R(100) < 0x3c → the
  cry. Fireball (100) → 20 landed hits for 2000 HP.
- Else a Statue / Box: the crush test of the Warrior → `.HurtSprite(S, 200, solid.vx >> 1, −1000, 2, 8)`, `+0xf0 = 0`,
  `.KillBox`, R(10000) → snd 701 at 42000 + R, the cry (R(100) [+ R(10000)]).

### 3.5 Kill — `.KillChief` (M l. 75502–75532)
Identical to `.KillWarrior` (head, then the tail with `+0x170 ≠ 0`).

### 3.6 The three pieces and the class duties
- killProc: new `.chief` arm = count + tail (`killsForGood` gains `.chief`).
- step 7: add `.chief` to the routing case (row M l. 49849–49851, 0x70).
- Smite: append `.chief`; a seed hurts it with the seed's `+0xa4`.
- `SpriteHandler.chief`, `SpriteClassTable` already returns `(.chief, .idle)` for 0x776…0x77f.
- Statue arm none; liquids none; hazards none.
- Idle: spawned idle; the Setup writes no margin field and leaves `+0xc0 = 0`. The idle entry is made by the generic
  `.AddIdleSprite` path (built); the build pins the frame the Chief activates on level 18 (measured).
- Write-back: **no `+0x18a`** → `.UpdateSprites` copies the Chief's type / x / y into record 1 every frame (M l.
  4959–4966) — a save mid-fight stores his current position; Kill `+0xea = 1` clears the record. A test row each.
- Arena (level 18): v = −1400, lock when x < 1340, second bound −640 (window [640, 1400]); built (`BossArena`), a
  level-18 test row.

### 3.7 Engine features the Chief needs that are not built
- **The boss stagger's player arm** (M l. 45591–45632 in `.HandlePlayerSprite`): while `*_DAT_100a0570 > 0`: vx × 0.5
  (f64 0x100a1a28), the face from `*_DAT_100a0784` by `((c mod 12) >> 1)` (0, 1 → +0, +0x34; 2 → +0; 3 → +0x68; 4 →
  +0x9c; 5 → +0x68), the standing / cling / spin clears and the spin-sound stop, `_DAT_100a071c = 0`; then a jump to
  the end of the player's state chain (`LAB_10050e6c`). Built already: the count-down (`Player.swift:489`, M l. 44740–44741), `.HandleKeys`'
  early return (`HandleKeys.swift:36`, M l. 47120–47122), the zeroing by a landed enemy shot (M l. 49910–49912) and
  `.ClearPlayerVars`' zero (M l. 42749–42752). Today `PlayerStates.swift:372` returns at once (its comment cites
  "l. 45625–45672"; the committed dump has the arm at M l. 45591–45632). Shared with Xichra (§6).
- Cache records with flag 1 in `CachedFaces` (the mechanism exists; five new records).

### 3.8 Proposed split and tests (`Tests/FerazelCoreTests/Enemies/ChiefTests.swift`)
**6A-CH1 — class, Setup, Init, Handle, the stagger arm**:
1. `testChiefSetupWrites` — every store of 3.2 (HP 2000, gravity 0x276, `+0x8d` 1, `+0xa6` −40, lane 2, no `+0x18a`,
   R(10) drawn).
2. `testChiefCacheRegistration` — sets 0x777…0x77a after 0x728 and before 0x780, single 0x776 after 0x726, all flag 1;
   the level-18 marks include 0x77b.
3. `testChiefFirstJumpAfterLock` — `+0xa6` counts only while locked; state 1 on the 56th locked frame (grounded).
4. `testChiefJumpDrawOrderAndLanes` — R(100) before R(6000); the nine lane rows; vy −0x2904 on the third jump frame.
5. `testChiefLandingShakeAndStagger` — snd 435 (40000 + R(12000)), shake 0x16, stagger 0x18 only when the player is
   grounded; throws R(2) + 2 at n = 6.
6. `testChiefThrowBoulder` — at n = 7: R(8000), snd 704 vol 0x5f, 0x77b at (x + 0xa1 / −0x11, y + 0x33), `+0x46` 15, vx
   4000 + R(500), vy −1200 − R(150); near player (< 240) vx × 0.8, vy 2000.
7. `testChiefThrowCount` — throws 2 → one boulder, 3 → two; back to state 6 with `+0xa6 = 0`.
8. `testChiefDeathCryDraws` — HP 0: R(100) (< 60 → R(100) [+ R(10000)]) before snd 703; burn on dying frame 20.
9. `testPlayerStaggerArm` — 24 frames: vx halves each frame, the six faces by c mod 12, no key read, then free.
**6A-CH2 — Hit, Kill, the pieces, the fight**:
1. `testChiefTakesShotDamage` — shot killed silently first; HP − `+0xa4`; `+0x116` 15; blood spray; 701 / 702 at HP ≤ 200.
2. `testChiefInvulnerableWastesShots` — a shot during `+0x116 > 0` is killed and does nothing else.
3. `testChiefCrush200AndCry` — 200, `+0xf0 = 0`, `.KillBox`, R(10000), the cry's R(100).
4. `testChiefKillTailAndGate` — count, `+0xe9`, `+0xea`, snd 453, shake 0x1e, flash 3, `noBossAlive = 1`, the level-18
   gate (x 628) opens, track 30.
5. `testChiefRecordWriteBack` — record 1's x / y follow the Chief each frame; cleared after the Kill.
6. `testChiefContactAndSmite` — step 7 0x70; a Smite seed hurts by its `+0xa4`.
7. `testLevel18ArenaBounds` — lock at x < 1340, camera window [640, 1400].
8. `testChiefScriptedKill` — see 3.9.

### 3.9 Scripted kill — measured by the build
On paper: 20 landed Fireball hits at most one per 15 frames; the tail = 20 dying frames + ⌈(B − T + 1) / 2⌉ − 1 burn
frames of 0x77a[3] (2 rows a frame, no R(100) rows since `+0x8d ≠ 0`). The landing frames of the hits depend on the
player's casting, the Chief's random lanes and the boulders' hits on the player — measured once with the default seed
and a key script (enter the arena, then cast while facing him), then pinned.

---

## 4. Manditraki Wizard (types 0x726…0x72f; level 25) — 6B-WZ ⚑ (full read; split below)

Callbacks: Handle `PTR_PTR_100a0490`, Hit `0db0`, tile `0dac`, Kill `0da8`. Today `.inert`.

### 4.1 Init — `.InitWizardSprite` (M l. 75570–75588)
`*_DAT_100a0a48 = 1`; sets 0xc0 × 0x8c (192 × 140), 8 a row: `PTR_DAT_100a0dbc` 0x727 move (8), `_DAT_100a0db8` 0x728
cast (8); single `_DAT_100a0db4` 0x726 standing; flag back 0. Flag 1 on all three. `.InitSprites` M l. 135: sets after
the Warrior's 0x71e, single after the Crab's 0x767.

### 4.2 Setup — `.SetupWizardSprite` (M l. 75591–75684)
`.InitSprite`; `+0x84 = +0x86 = 0`; **layer 1**; callbacks; `+0x18a = 1`; marks 0x727, 0x728, single 0x726 and
`_DAT_100a0848` (the 48 × 48 0x46a cut); `+0x170` = p4; gravity 0x122; `+0xc0 = 0`; p4 = 0 → HP 0x4b0, else **HP
1000**, `fed0 = 0`, `+0x88 = 0`; `+0x1b4 = 1`; `+0x168 = HP`; re-seat; hot rect SetRect(0x42, 0x1e, 0x7c, 0x7e) (never
changed); `+0x150 = −1`; `+0xb0 = 6`, `+0xb2 = 0`, `+0x46 = 2`, `+0x14c = 0`; `+0xa6 = R(10)`; `+0xf0 = 0xf`; p2 0 →
0x96 (live record); `+0x15c / +0x160 = x ∓ 0x100`; `+0x168 = x`; `+0x164 = 0`; `+0x17e = 0`; face 0x727[0];
`+0x9c = AllocateGameMem(0xe)` (7 zeroed i16: w0 actions left, w1 unused, w2 next state, w3 attack kind, w4
write-only counter, w5 crate timer, w6 fireball run); `+0xf0 = 0x1e`; counting; `+0x14 / +0x1c`. Draws: R(10).

### 4.3 Handle — `.HandleWizardSprite` (M l. 75687–76084)
Head: `+0xe9` / `+0x1b2` → return; `.StandardSpriteHandles`; switch (13 arms). HP bands: high > 600, mid 301…600, low ≤
300. Faces: M = move 0x727, C = cast 0x728, S = standing 0x726.

| state | per frame | leaves to | draws | sounds / spawns |
|---|---|---|---|---|
| 6 idle | W = 10 (HP < 0x12d) / 16 (< 0x259) / 22; face S; vx 0; `+0xa6 + 1`; R(10) r; W + r ≤ `+0xa6` → `+0xa6 = 0`, n = 0, state 9; face the player | 9 | R(10) **every frame** | — |
| 9 advance | i = n mod 16 (≥ 0); face M[i >> 1]; vx = 0x500, negated facing left; n + 1; n > 31 → face S, vx 0; n > 35 → face the player, w2 = 12, `+0xa6 = 0`, n = 0, state 2; B = 20 (low) / 10 (mid) / 0; R(100) r < B + 40 ∧ w6 < 3 → fireballs: w6 + 1, w3 = 0, R = 22 (HP > 600) else 35 (the 45 arm is dead), R(100) > R → w0 = 1 else w0 = R(3) + 2; else crate: R(100) r, w6 = 0, w3 = 1, r ≥ 0x5b → w0 = 1, r ≥ 0x15 → 2, else R(2) + 3; w4 + 1 | 2 | R(100), then R(100) [+ R(3)] or R(100) [+ R(2)] | — |
| 2 attack, w3 = 0 (fireballs) | face C[min(n >> 1, 7)]; n == 7: `+0xa6 < 1` → `+0xa6 = 20`, n − 1; else `+0xa6 − 1`, `+0xb8` = 0x1000c on odd frames by `*_DAT_1009fd30` else 0, `+0xa6 < 1` → `+0xb8 = 0` else n − 1, face the player — a **21-frame hold at n = 7**, re-armed every volley; n == 8 → three 0x46a at (cx − 0x18, cy − 0x18), layer `+0x80 + 1`, (vx, vy) = (0x1194, 0), (0x1068, −0x5dc), (0xce4, −0xbb8), vx negated facing left; R(12000), snd 300 `*_DAT_100a0424` (1, 0x100, 36000 + R); w0 − 1; n + 1; n > 15 → face S, face the player, w0 == 0 → done, else w5 < 1 → n = 0 | done → w2 | R(12000) at n = 8 (after the three shot Setups) | 3 × 0x46a, snd 300 |
| 2 attack, w3 = 1 (crate) | face C[min(n >> 1, 7)]; n == 10 → `MTNewSprite(0x434, cx − 0x10, cy − 0x10, 9, −1, Box setup)` into `+0x1d4`, its `+0x160 = −0x34`, w5 = 0x34, w0 − 1; n + 1; n > 15 → face S, face the player, w0 == 0 → done, else w5 < 1 → n = 0 (the next crate waits for the last to drop) | done | [the Box Setup's] | Box 0x434 |
| done | `+0xa6 = 0`, n = 0, state = w2 (always 12) | 12 | — | — |
| 12 | face the player; state 10 | 10 | — | — |
| 10 | face M[7 − (i >> 1)] (i = n mod 16 ≥ 0); vx = −0x500, negated facing right (so toward the facing, as in 9); n + 1; > 31 stand; > 35 → `+0xa6 = 0`, n = 0, state 6 | 6 | — | — |
| 11 (no writer) | as 10 with vx +0x500, negated facing right | — | — | — |
| 4 dying | vx × 0.9 (0x100a1cc0); face **C**[n >> 2]; n + 1 cap 0x10; `+0xa6 + 1`; == 0x14 → `+0x1a2 = 1` | — | — | — |

Crate carry (M l. 76011–76045, every frame while w5 > 0): w5 − 1; the crate (`+0x1d4`) gone (0 or `+0xe9`) → w5 = 0,
`+0x1d4 = 0`; else t = (float)(max(w5 − 0x16, 0) / 30.0) (0x100a1cb8 = 30.0), and while w5 > 10: crate x = (short)(int)
((playerX − 0x10)·(1 − t) + (float)((float)crate.x · t)), y likewise with (playerCY − 0x88) and crate.y — **the crate's
own current position**, so it eases towards 136 px above the player, tracks him exactly from w5 22 down to 11, then
hangs; `+0x14 / +0x1c` follow. The Box Handle (`BoxSprite.boulder`, built) keeps it weightless while `+0x160 < 0` and
drops it 52 frames after it appeared.

Tail: death entry, **else** the glow (tint only at 0 < HP < 0x259; reload 0xc at HP < 0x12d else 0x1e);
`.ApplyGravityAndSeparateFromTiles` (Crawler-body tile callback, M l. 76169–76201); Cleanup. No liquids.

### 4.4 Hit — `.HitWizardSprite` (M l. 76087–76133)
- Player shot ∧ `+0xa6 == 0` ∧ HP > 0: if the shot's `+0x1a2 < 1` → shot vx × 0.4 (0x100a1ca0), `+0x1a2 = 1`, `+0x8c =
  1` (it burns away; no `.KillPlayerShot`, no sound).
- Statue / Box **with `+0x160 ≥ 0`**: the crush test → `.HurtSprite(S, 100, …, 2, 8)`, `+0xf0 = 0`, `.KillBox`,
  R(10000) snd 701, R(10000), R(2) grunt. 1000 / 100 = 10 hits.

### 4.5 Kill — `.KillWizard` (M l. 76136–76166): as the Warrior's.

### 4.6 Pieces, duties, engine
killProc `.wizard`; step 7 row M l. 49846–49848 (0x70); Smite (the seed burns away); `SpriteHandler.wizard`
(`SpriteClassTable`: `(.wizard, .idle)`); Statue none; liquids none; idle as the Chief (no margins; face 0x727[0]
present); write-back `+0x18a` / `+0xea`; arena level 25 v = +592, lock x > 532, window [592, 1384]. Engine: **6A-FB**
(0x46a cached by record — the Wizard marks only the 48 × 48 cut); nothing else (Box 0x434 hover arm, shots, burn built).

### 4.7 Proposed split and tests (`WizardTests.swift`)
**6B-WZ1 — Setup, Init, Handle**: `testWizardSetupWrites` (HP 1000 boss, layer 1, block 0xe, face 0x727[0]);
`testWizardCacheRegistration` (0x727, 0x728 after 0x71e; 0x726 after 0x767; flag 1); `testWizardIdleDrawsEveryFrame`
(R(10) each frame, W 22 / 16 / 10); `testWizardAdvanceChoosesAttack` (draw order, B, w6 < 3 cap, R 22 / 35);
`testWizardFireballChargeAndVolley` (21 frames at n 7, the parity tint, three velocities, snd 300 after the spawns);
`testWizardCrateSpawnAndCarry` (0x434 at n 10, `+0x160` −52, w5 52, the eased path, release at 52);
`testWizardRetreatAndDeadState11` (12 → 10 → 6; 11 unreachable); `testWizardDeathAndGlow` (cast face n >> 2, burn at
20, period 12 at HP ≤ 300); `testWizardSwitchOff`.
**6B-WZ2 — Hit, Kill, fight**: `testWizardShotsBurnAway`; `testWizardOwnHoveringCrateHarmless` (`+0x160 < 0` ignored);
`testWizardCrush100`; `testWizardKillTail`; `testWizardContactSmite`; `testLevel25ArenaBounds`; `testWizardScriptedKill`
(measured: the crate attacks are the only damage — the player lures the released crate onto him; tail 20 + (B − T) of
0x728[4]).

---

## 5. Fire Guardians — class Demon (types 0x780…0x789; level 55) — 6C-DM ⚑ (full read)

Callbacks: Handle `PTR_PTR_100a04b0`, Hit `0d6c`, tile **0**, Kill `0d68`; the segment Handle `PTR_PTR_100a0d64`.

### 5.1 Init — `.InitDemonSprite` (M l. 74324–74364)
No `*_DAT_100a0a48` wrapper (flag 0). Sets 0x90 × 0x74 (144 × 116): `PTR_DAT_100a0d84` 0x780 sway (6, **3 a row**),
`_DAT_100a0d80` 0x781 fire (6, 3 a row), `_DAT_100a0d7c` 0x782 roar (3, 3), `_DAT_100a0d78` 0x783 hurt / death (4, 4);
`_DAT_100a0d74` 0x784 neck (2, 0x60 × 0x60, 2). Then the 560-entry i32 table `_DAT_100a0d70`: `table[i] = (int)(sin(i ·
0.17951943 · 0.0625) · 95 · 256)` (f32 0x100a1c7c = 2π/35, 0x100a1c78 = 1/16, 0x100a1c74 = 95, 0x100a1c70 = 256) — one
period over 560. The decompile garbles the `sin` return (it is in f1); the bank's formula from the raw stands.
`.InitSprites` M l. 137: sets after the Chief's 0x77a.

### 5.2 Setup — `.SetupDemonSprite` (M l. 74367–74501)
`.InitSprite`; `+0x84 = +0x86 = 0`; layer 0xc; Handle, Hit, tile 0, Kill; `+0x18a = 1`; marks 0x780…0x784 and **all
three 0x46a cuts** (`_DAT_100a0848`, `0844`, `0840`); `+0x170` = p4; gravity 0; `+0xc0 = 0`; p4 = 0 → HP 1000, else HP
2000 and `fed0 = 0` — **no `+0x88 = 0`** (the Demon alone keeps its light pass); `+0x1b4 = 1`; `+0x168 = HP`; re-seat;
SetRect(0x1a, 0x17, 0x4a, 0x3a); `+0xb0 = 6`, `+0xb2 = 0`, `+0x46 = 2`; `+0xa6 = R(10)`; anchor `+0x14c = x << 8`,
`+0x150 = y << 8`; `+0x154 = +0x158 = +0x15c = +0x160 = 0`; neck speed `+0x164 = 0x300`; extend `+0x168 = 1`;
`+0x17e = (type == 0x781)`; `+0xf0 = 0x1e`.
- Types 0x780 / 0x781: block `+0x9c = AllocateGameMem(0x30)`; eight `MTNewSprite(0x785, x + 0x1e, y + 0x1e, +0x80 − 1,
  record 0x1ff, the Demon setup _DAT_1009fee8)` into t[0…7] (t[7] `+0x46 = 1`, others 0) — each runs this Setup and
  takes the segment branch, whose own layer store (0xc) wins over the argument; t[9] = 0, t[8] = 0x10, t[9] = 0, t[10] =
  0 (t[11] zero from the allocation). 0x780 also: `*_DAT_1009fecc = 2`; the partner `MTNewSprite(0x781, x − p3·32, y,
  layer = the record index, record = the same index, Demon setup)` into `+0x1e0` (its layer argument is overwritten to
  0xc as well).
- Any other type (the segments): Handle `0d64`, Hit 0, tile 0, SetRect(0, 0, 0, 0). The segment keeps `+0x50 =
  .KillDemon`, `+0x18a`, the count, and reads its p4 from record 0x1ff (hdr + 0x1ffe, one past the 511 records — the
  build reads that i16 from level 55's `Mlvl`), so its HP is 1000 or 2000 by that word.
- Counting; `+0x14 / +0x1c`.
**Level-55 load draws:** the guardian's R(10), then its eight segments' R(10) (inside their spawns), then the partner's
R(10) and its eight — **18 × R(10)**, in that order. Counted: 2 + 16 = 18.

### 5.3 Handle — `.HandleDemonSprite` (M l. 74578–74904); segment `.HandleDemonSegSprite` (M l. 74561–74575)
Segment Handle: unless `+0xe9` / `+0x1b2`: Handles; face 0x784[`+0x46`]; Cleanup (the burn runs here).
Guardian head: `+0xe9` / `+0x1b2` → return; Handles; SetRect(0x22, 0x14, 0x67, 0x5e); phase t[9] += t[8], > 0x22f →
0; **`IsPressed(0x77)` → HP = −1** (no debug gate; key code 0x77, End on an extended keyboard); the 0x780 type idiom
(no-op, omit); `+0x50 = .KillDemon`. The neck flag `move` starts false.

| state | per frame | leaves to | draws | spawns / sounds |
|---|---|---|---|---|
| 6 sway | t[8] + 2 while < t[11] + 16; n + 1, > 9 → 0; `+0xa6 + 1`; R(30) r; r + 30 < `+0xa6` ∧ neck > 0x577f ∧ n < 2 → n = `+0xa6` = 0, and: `+0x160 == 0` → R(100) < 0x2d → 9 else 2; else `+0x160 = 0`, R(100) < 0x15 → 9 else 2; player behind (facing left ∧ cx < px, or right ∧ px < cx) → state 6, `+0xa6 = 0`; face 0x780[n] (n < 6) else [10 − n]; move; `+0x15c = neck·table[t[9]] / 0xaf00` (overwritten later for the head) | 2 / 9 | R(30) every frame; R(100) on a choice | — |
| 2 fire | move; `+0x164 × 0.75`; t[8] < 1 → `+0xa6 + 1`, n + 1, s = n: s < 11 → s == 6: shot `+0xb8 = 0xb0001`; s == 4: `MTNewSprite(0x46a, x + 0x60·facing + 8, y + 0x28, +0x80 − 1, −1, EnemyShot setup)` into `+0x1d4`, `+0xb8 = 0xb0002`; s == 5: 0xb0000; s == 7: 0; then s == 4: `.CalcCenterPos(shot)`, dir = `.FindDesiredDirectionGeneric(player centre, shot centre)`, `FUN_1003f218(shot, dir, 0x708)`, R(12000), snd 300 (36000 + R); face 0x781[min(s ≤ 4 ? s : 10 − s, 4)]; s ≥ 11 → n = `+0xa6` = 0, state 6; else (t[8] ≥ 1): t[8] − 2 (floor 0), face 0x780[0], n = −1 | 6 | R(12000) at s 4 | 0x46a aimed, snd 300 |
| 9 roar | move; `+0x164 × 0.75`; t[8] − 1 while > (t[11] + 16) / 2 − 2; n + 1; i = n >> 1: < 3 → 0x782[i], else [min(24 − i, 2)]; n > 47 → `+0xa6 = R(30)`, n = 0, `+0x160 = 1`, state 6 | 6 | R(30) at the end | — |
| 8 recoil | n == −1 → t[11] + 1; move; `+0x164 × 0.75`; n + 1; `+0xa6 + 1`; face 0x783[n] (n < 4) else [max(7 − n, 0)]; n < 8 → segment t[7 − n] `+0xaa = 8` (**no null check**); n > 6 → state 6 | 6 | — | — |
| 4 dying | move false; t[8] − 1 while > 0; vx × 0.9; face 0x783[min(n >> 2, 3)]; n + 1 cap 12; `+0xa6 + 1`; > 11: == 12 → `+0x1a2 = 1`; < 20 → segment t[a6 − 12] (`+0xe9` → slot 0, read **before** the null test): `+0x46 = 0`, `+0x1a2 = −(30·(7 − (a6 − 12)) + 1)` | — | — | — |

Neck motion (`move`, M l. 74843–74868): neck ≤ 0x4c00 → extend 1; ≥ 0x9f00 → 0. extend 0: t[10] = 0, speed > −0x400 →
− 0x80. extend 1 ∧ speed < 0x400: t[10] + 1, and (t[10] > 0x46 ∨ speed < 0) → speed + 0x80. neck += speed, clamp
[0x2d00, 0xaf00]. Constants: 0.75 = 0x100a1c60, 0.9 = 0x100a1c58.

Tail (M l. 74869–74901): death entry; 0x780 / 0x781 → `.HandleDemonSegs` (M l. 74504–74558: per segment i, a dead one's
slot cleared — `*slot + 0xe9` read before the null test; d = i·neck / 8 (toward 0); x256 = anchorX ± d + 0x1800; idx =
(t[9] + ((0xaf00 − d) >> 7)·neck / 0xaf00) mod 0x230; y256 = **anchorY + `+0x154` + d·table[idx] / 0xaf00 + anchorY −
0x6a00**; `+0xc / +0xa` from them; facing copied), then `+0x15c = −0xa00 − (anchorY − t[7].y256)` (**t[7] read without a
null test**); x256 = anchor ∓ neck by facing; y256 = anchorY + `+0x154` + `+0x15c`; vx = vy = 0; `+0xc / +0xa`;
Cleanup. No gravity, no glow, no liquids.

### 5.4 Hit — `.HitDemonSprite` (M l. 74907–74965)
Player shot ∧ `+0xa6 == 0` ∧ HP > 0: window = state 9 ∧ n > 4. In the window `.KillPlayerShot(shot, 0, 0)`; shot type 6
(V Blade) → snd 303 only; else `.HurtSprite(S, shot +0xa4, shot.vx >> 1, −1000, 2, 8)` → on a hurt: HP < 0xc9 → 702
else 701; R(100) < 0x3c → R(10000), R(2) grunt (42000 + R); state 8, `+0xa6 = n = −1`, speed `+0x164 = −0x800`.
Outside: `.KillPlayerShot(shot, 0, 1)` + snd 303. Solids are not tested.

### 5.5 Kill — `.KillDemon` (M l. 74968–75005)
Head (count), then **score `G+0 += 1000` unconditionally**, `+0xe9`, `+0xea`; 0x780 / 0x781 with the flag:
`*_DAT_1009fecc − 1`, snd 453, shake 0x1e, flash 3, `fecc < 1 → fed0 = 1`. Runs for every segment too (9,000 a guardian).

### 5.6 Pieces, duties, engine
killProc `.demon` (guardian) and `.demonSegment` (the same `.KillDemon`); step 7 `.demon` (default 0x70; segments have
empty rects and no row); Smite `.demon` (segments not listed); `SpriteHandler.demon` / `.demonSegment`; Statue none; no
liquids; write-back `+0x18a` (both) / `+0xea`; arena: v = 16000 never locks (bosses-3 §11) — only the music applies.
Engine not built: **the End key** (`IsPressed(0x77)` — a HectorInput key read the shells must pass, ungated in the
original); **6B-FI** (the flame buffer: 0x46a's flame sparks when hdr `+0x2722 ≠ 0`, level 55 fire mode 2 backdrop);
**6A-FB** (the 0x46a cuts by record — the Demon marks all three); `*_DAT_1009fecc` (guardians alive; zeroed by
`.SetupLevelSprites`) as a new Core global.

### 5.7 Hazards
Three null reads on emptied segment slots (HandleDemonSegs' `+0xe9`, state 8's `+0xaa` store, the tail's t[7] `+0x1c`):
on the Mac they touch low memory. The first two are harmless while the slots are filled; the tail's read matters if
segment 7 finishes burning before the head does — segment 7 starts burning on dying frame 19 (delay −1), the head on
frame 12. **The build measures on level 55 which Kill comes first; if t[7] can be empty while the head still runs, STOP
and ask** (the head's y would come from low memory).

### 5.8 Proposed split and tests (`DemonTests.swift`)
**6C-DM1 — Init, Setup, segments**: sine table pins (table[0] 0, table[140] = 95·256, table[420] = −95·256);
`testDemonCacheRegistration` (0x780…0x784 after 0x77a, flag 0, 3/3/3/4/2 a row); `testDemonSetupPairAndSegments` (partner at
x 455 on L55, 16 segments, layer 0xc, record 0x1ff); `testDemonLevelLoadDraws` (18 × R(10) in order);
`testDemonCounts18`; `testDemonSegmentSetupBranch` (Handle 0d64, empty rect, p4 from hdr + 0x1ffe); `testHandleDemonSegs`
(the anchor-twice y formula at y 105); `testDemonSegmentHandleFace`.
**6C-DM2 — Handle**: sway choice draws; fire (neck settles, shot at s 4, aim + 0x708, tints 5–7); roar (48 frames,
`+0x160`); recoil (t[11] + 1, flash down the neck); neck motion bounds; head position; dying (head burn at 12, segment
delays −211 … −1); End key; switch-off.
**6C-DM3 — Hit, Kill, fight**: roar window; V Blade; outside the window; KillDemon score per call and fecc / fed0; the
seg-7 order check (5.7); contact / Smite; `testFireGuardiansScriptedKill` (measured; 2 × 2000 HP through roar windows of
43 frames).

---

## 6. Xichra (types 0x7c6…0x7cf; level 67) — 6C-XI ⚑ and 6C-XL (full read of Handle and Hit; Init/Setup line by line)

Callbacks (body): Handle `PTR_PTR_100a048c`, Hit `0dc8`, tile `0dc4`, Kill `0dc0`; wing Handle `0dcc`.

### 6.1 Init — `.InitXichraSprite` (M l. 76204–76235)
`*_DAT_100a0a48 = 1`; sixteen sets 0xf0 × 200 (240 × 200), 2 a row, in this order: 0x7bc (`e0c`, 4), 0x7bd (`e08`, 4),
0x7be (`e04`, 2), 0x7bf (`e00`, 4), 0x7c0 (`dfc`, 2), 0x7c1 (`df8`, 4), 0x7c2 (`df4`, 4), 0x7c3 (`df0`, 4), 0x7b2 (`dec`,
4), 0x7b3 (`de8`, 4), 0x7b4 (`de4`, 2), 0x7b5 (`de0`, 4), 0x7b6 (`ddc`, 2), 0x7b7 (`dd8`, 4), 0x7b8 (`dd4`, 4), 0x7b9
(`dd0`, 4); flag back 0. All flag 1. `.InitSprites` M l. 138: after the Demon's 0x784, before the Floater's 0x6f4.

### 6.2 Setup — `.SetupXichraSprite` (M l. 76263–76444)
Record 0x1ff → the **wing**: `.InitSprite`, Handle `0dcc` only (layer = the caller's 0, no face, no rect).
Else: `+0x18a = 1`; `+0x84 = +0x86 = 0`; layer 1; callbacks; `+0xa6 = 0`; marks the sixteen sets, the 0x46a cuts
`0848` and `0840`, the 0x77b set `083c`, the Background single 0x5cf (`PTR_DAT_100a09f4[0x71]` = record 7 of the
0x5c8+i block, PICT 1487, the red spiked ball), the Walker single 0x6d6 (`09ec`) and its sets 0x6d7 (`09d0`), 0x6d8
(`09cc`), 0x6d9 (`09c8`), 0x6da (`09c4`); gravity 0; `+0xc0 = 0`; HP 5000; `fed0 = 0`; `+0x88 = 0`; `+0x1b4 = 0`;
`+0x168 = HP`; re-seat; SetRect(0x5c, 0x3a, 0x93, 0x90); `+0x150 = −1`; `+0xb0 = 0`, `+0xb2 = 0`, `+0x46 = 2`, `+0x14c =
0`; `+0xa6 = R(10)`; `+0xf0 = 0xf`; position forced to (0x145, 0x48) = (325, 72); `+0x15c / +0x160 = x ∓ 0x100`; `+0x168
= x`; `+0x164 = 0`; `+0x17e = 0`; block `+0x9c = AllocateGameMem(0x374)`; w+0 = `MTNewSprite(100, 0, 0, 0, 0x1ff, Xichra
setup)` (the wing); w+0xc / +0xe = home (325, 72); w+4 = cannon A `MTNewSprite(0x443, −24, 260, 0, record 400,
Background setup _DAT_1009ff30)`; w+8 = cannon B `MTNewSprite(0x449, 779, 262, 0, 401, Background setup)`; table A
(20 × i16 at w+0x7c) = (short)(sin(18°·i)·10); table B (360 × i16 at w+0xa4) = (short)(sin(i°)·220); w+0x1c hits = 3;
w+0x6a phase = 0; `+0xa6 = 0`; `+0xb0 = 0`; w+0x20 angle = 0xb4; `+0xf0 = 0x1e`; counting; `+0x14 / +0x1c`. Draws:
R(10), then the two cannons' Background Setups.

### 6.3 Handle — `.HandleXichraSprite` (M l. 76570–77341)
Order of one frame:
1. State ∉ {4, 5}: y −= table A[w+0x18] (last frame's bob removed) — **before** the `+0xe9` test.
2. `+0xe9` / `+0x1b2` → return; Handles.
3. Debug (`*_DAT_100a0064` set and key 0x79, state ≠ 4): out of scope — the shipped flag is 0, `IsPressed` is not
   called.
4. **Phase switch** (w+0x6a, M l. 76644–76792): sets the form w+0x1a, hdr `+0x2730` (CLUT mode) and the sway target
   w+0x24; phases 2–5 run the action cycle (w+0x34 − 1; < 1 ∧ ready w+0x12: state 0 → 1 (b2 0), 1 → 2 (b2 0), 2 → 0 with
   w+0x34 = R(60) + 90).

| phase | form | 0x2730 | target | exit (in the phase switch unless noted) |
|---|---|---|---|---|
| 0 | 0 (w+0x2c = 0) | 3 | — | state 0 at `+0xa6 == 0x50` (below) |
| 1 | 0 | (not written) | — | each minion slot (`+0x1d4`, `+0x1d8`) with `+0xe9` → w+0x6c − 1, slot 0; w+0x6c < 1 → `.Conversation(251, +0x48, S)`, phase 2 |
| 2 | 0 | 3 | 0x200 | hits < 1 → phase 3, hits 4, flash 5, R(12000) snd 468 (78000 + R), `.UpdateXichraCannons` |
| 3 | 1 | 4 | 0x300 | hits < 1 → phase 4, hits 4, flash 5, R(12000) 468 (78000+), R(12000) 468 (90000+) |
| 4 | 2 | 5 | 0x400 | (state 4's crash landing with HP < 1, below) |
| 5 | 3 | 6 | 0x600 | hits < 1 ∧ state ∈ {0, 1, 2} → phase 6, flash 7, HP 9999, state 4, x256 / y256 from +0xc / +0xa, n = 0, vx = vy = 0, w+0x38 = w+0x3c = 0, two 468 |
| 6 | 4 | 7 | 0 | (state 4 → 8) |

5. **State switch** (`+0xb0`, M l. 76793–77194; state 3 has no arm):

| state | per frame | leaves to | draws / sounds / spawns |
|---|---|---|---|
| 0 float | ready 0; SetRect(0x5c, 0x3a, 0x93, 0x90); `.StandardXichraFloat`; current w+0x2c == target → ready 1; `+0xa6 + 1`; == 0x50 → `.Conversation(250, +0x48, S)`, phase 1, record 500 p3 = 4 (hdr + 0x1f4c), w+0x6c = 2, two `MTNewSprite(0x6d6, cx − 0x12a / cx + 0x52, camTop − 0x6e, 0x14, record 500, Walker setup _DAT_1009ff24)` into `+0x1d4` / `+0x1d8`, the **first** minion's `+0x100 = 1` twice | (cycle) | 2 Walker Setups |
| 1 shoot | ready 0; b2 0: Float, target ≠ 0 → saved w+0x28 = target, target 0, current == 0 ∧ frame 0 → b2 1; b2 1: target 0, n + 1, group 1, frame n < 12 ? n >> 1 : (21 − n) >> 1, **n == 12 → `.DoXichraShot(S, 3)`**, n > 20 → b2 2; b2 2: Float, target 0 → saved, reached ∧ frame 0 → ready | (cycle) | DoXichraShot: R(12000) snd 300, 3 × 0x46a aimed −1/0/+1 step, impulse 0xa28 (0x10c2 once fast) |
| 2 rain | ready 0; b2 0: Float, save + zero the target, wind-up w+0x68 + 1 cap 0x25; current == 0 ∧ wind-up 0x25 ∧ frame 0 → b2 1 and the pattern by form (below); b2 1: target 0, delay w+0x48 − 1, < 1 → one object (below), `.CalcCenterPos`, k − 1, k < 0 → rows − 1, < 1 → b2 2, else delay = between, k = len; else delay = in-row; b2 2: Float, restore, wind-up − 1 floor 0, reached ∧ wind-up 0 ∧ frame 0 → ready | (cycle) | form 0: R(3), R(100); form 2: R(4), R(100); form 3: R(2), R(100); form 1: none |
| 4 crash | target 0; bob 10; SetRect(0x5c, 0x50, 0x93, 0xa2); n + 1; gravity 0x15e; group 2; airborne: n cap 18, frame n / 3; grounded: w+0x38 == 1 → R(500) snd 435 (50000 + R), shake 0x12, grounded player → stagger 0x14; n cap 18; w+0x38 + 1; frame n / 3; w+0x38 > 6 ∧ n == 18 → w+0x38 = 0, n = 12, w+0x10 = y; HP < 1: form 2 → phase + 1, form 3, state 7, n = 0x18, hits 3 / else state 5; HP ≥ 1 ∧ hits < 1: form 4 → phase 6, n = 0x18, state 8 / else 5; else 5 | 5 / 7 / 8 | R(500) on the second grounded frame |
| 5 grounded | target 0, bob 10, group 2; w+0x38 + 1; > 30 → n − 1, < 0 → n = 0, state 6, w+0x3c = 0; frame n >> 1 | 6 | — (vulnerable while w+0x38 ≤ 30, §6.4) |
| 6 rise | N = 0x1c (0xe when fast); target 0; wind-up 0; w+0x3c + 1; Float; > N ∧ frame 0 → state 0; > N → w+0x3c = N; y = homeY·c / N + crashY·(N − c) / N (two integer divisions); y256 | 0 | — |
| 7 transform | target 0, bob 10, group 2; w+0x38 + 1; < 0x7e: n + 1 cap 0x2b, frame n >> 2; == 0x7d → `.Conversation(252, +0x48, S)`, n = 0xb, flash 3, R(10000) R(2) grunt (78000+), R(10000) R(2) grunt vol 0x97 (58000+); ≥ 0x7e: n − 1, < 0 → n = 0, state 6, **fast w+0x13 = 1**, w+0x3c = 0; frame n | 6 | — |
| 8 death | target 0, bob 10, group 2; w+0x38 + 1; < 0x3d: n + 1 cap 0x2b, frame n >> 2 (the == 0x7d test is dead); else m = w+0x38 − 0x3c: m < 0x8c ∧ m mod 12 == 0 → **`.STPlay3DSoundRand`(435, 1, 0x100, +0xe)** (one R(10000)), flash 4, shake 0x14, R(30) dy, R(65) dx, `MTNewSprite(0x4b7, cx + dx − 0x4b, cy + dy − 0x1f, 0xc, −1, Effect setup)`; m > 0x96 → `DAT_100a5106 = 1`, `*_DAT_1009ffc4 = 1` (every frame from w+0x38 = 211); frame 10 | — (`.GameLoop` ends → `.Victory`) | 11 explosions (m 12 … 132) |

Rain patterns (all written on the b2 0 → 1 frame; kind w+0x64 written only by forms 2 and 3, form 0 relies on the
zeroed block):

| form | len = k | rows | in-row / between | mode | object (b2 1) |
|---|---|---|---|---|---|
| 0 | 8 | R(3) + 2 | 9 / 0x15 | 1 drop | Box 0x434 at (X − 0x10, camTop − 0x20), layer 9 |
| 1 | 5 | 3 | 10 / 0x1e | 0 sweep | 0x771 at (camLeft − 0x3c, Y) and 0x772 at (camLeft + 0x260, Y), Y = 0x1a4 − k·0xa0 / len; both `+0xa4 = 0x70`, `+0x16c = 1`, vx ±0x1068, `.MTChangeSpriteLayer(1200)`; **only the 0x772** also gets gravity 0 and vy 0 |
| 2 | 7 | R(4) + 1 | 8 / 0x10 | 1 | Box **0x5c4** at (X − 0x33, camTop − 0x43) |
| 3 | 6 | R(2) + 1 | 8 / 0x10 | 1 | EnemyShot 0x753 at (X − 0x2f, camTop − 0x3f) |

Drop X (mode 1): parity = rows & 1, inverted when the side flag (R(100) > 0x31) is set; parity 0 → idx = len − k and
off = +(0x2c0 / len) / 4, else idx = k and off = −(0x2c0 / len) / 4; X = idx·0x2c0 / len + 0x60 + off.

6. **Glow** (state ≠ 8): tint at 0 < HP < 0x7d1; reload 0xc at HP < 0x12d else 0x1e.
7. **Movement**: state 4 → `.ApplyGravityAndSeparateFromTiles` (tile callback: `.WallBounce` on FG hits only, M l.
   77484–77503); states 0–3 (not 5–8): current w+0x2c steps 0x30 toward the target; angle w+0x20 += current, ≥ 0x16800
   → − 0x16800; x = homeX + table B[angle >> 8]; y = homeY − 6·wind-up; x256 / y256. States 5, 6, 7, 8: no sway.
8. **Faces** by group w+0x14 and frame w+0x16: group 0 → 0x7bc[0…3], 0x7bd[4…7 → 0…3], 0x7be[8, 9 → 0, 1]; group 1 →
   0x7bf[0…3], 0x7c0[4, 5]; group 2 → 0x7c1[0…3], 0x7c2[4…7], 0x7c3[8…11]; a frame past a group's range writes no face.
   The wing (w+0) gets the same group / frame from 0x7b2…0x7b9, Xichra's +0xa / +0xc (one 4-byte copy), x256 = x << 8
   then **x256 = y << 8** (the slip), Xichra's facing, `+0xb8 = 0xb0001`.
9. Cleanup; then state ∉ {4, 5}: bob w+0x18 + 1 mod 20, y += table A[bob] (`+0x1c` not updated).

`.StandardXichraFloat` (M l. 76447–76483): n + 1, group 0; slow: n > 19 → 0, frame n >> 1; fast: n > 9 → 0, frame n;
facing = (playerX > cx − 4).

### 6.4 Hit — `.HitXichraSprite` (M l. 77344–77448)
Player shot with `+0xa6 == 0` (no HP test):
- state 5 ∧ w+0x38 < 0x1f: `.HurtSprite(S, shot +0xa4, 0, −1000, 10, 10)`; on a hurt: k = max(dmg / 100, 1); R(10000)
  R(2) grunt vol 0xab (78000+); R(10000) snd 701 (78000+); `.KillPlayerShot(shot, 0, 0)`; `.BloodSpray(S, shot, 40k, 50k
  + 350, 150k, 2)`; HP > 0 → snd 701 vol 0x55. On a miss the shot flies on.
- state ∈ {0, 1, 2, 3} (and any state > 8): shot type 0x5a ∧ `+0x116 < 1` → `.KillPlayerShot(shot, 1, 1)`, hits − 1,
  `+0xaa = 0x1a`, `+0x116 = 0x3c`, two grunts (78000+, vol 0x97 58000+); form 2 → `+0xaa = +0x116 = 5`, state 4, n 0, vy
  vx 0, w+0x38 = w+0x3c = 0. Else, shot `+0x1a2 < 1` → snd 303 vol 0xab (at the shot), shot vx × 0.4 (0x100a1cc8), it
  burns (`+0x1a2 = 1`, `+0x8c = 1`).
- states 4, 6, 7, 8 and 5 after its window: nothing.
Statue / Box with `+0x160 ≥ 0`, any state: the crush test → 100 (invul 2, flash 8), `+0xf0 = 0`, `.KillBox`, R(10000)
701, R(10000) R(2) grunt (42000+).

### 6.5 Kill — `.KillXichra` (M l. 77451–77481)
Head, then the tail **unconditionally** (no boss-flag test). Not reached in play: Xichra never sets `+0x1a2`; the
game ends from state 8 (bosses-2 §6.6, MED on other burn writers).

### 6.6 The lair (6C-XL; bosses-3 §8) and the hand-offs
- Cannons: R (record 4, 1090, placed), A (0x443, record 400), B (0x449, record 401). Background cannons with p1 0 are
  built (W2b); **the rotating arm (record p1 101…106, `cmpwi r4,0x65` raw `10073c7c`) is refused at Setup today**
  (`BackgroundSprite.swift:334`) — `.UpdateXichraCannons` (M l. 76486–76517) writes p1 0x67 / 0x68 into the live records
  at phase 3, so the Handle's per-frame p1 read must reach that arm: 6C-XL builds it (and the 485 cue).
- Minions 0x6d6 (record 500 p3 = 4): built Walker class (WK2); not counted (spawned outside the window).
- Gates 2940 p1 = 0: built gate arm; record 0's p4 is never written → walls.
- CLUT animation: Xichra writes hdr `+0x2730` every frame (modes 3…7); `.AnimateCLUT` (6B-CA, M l. 8926ff, called at M
  l. 9231) reads it — **the header field must be a mutable Core value** (today `LevelRun` reads a parsed header), shared
  by 6B-CA and 6C-XI.
- `.Victory`: the flag `*_DAT_1009ffc4` (and `DAT_100a5106`) → 6C-VI's `GameFlow` state; the three victory routines
  are ENG / 6C-VI's (§7).
- Conversations 250, 251, 252 (`Mcnv`, LL checks their opcodes) started **from inside a Handle**: the suspension
  mechanism exists for the player's Handle (the IU hint); 6C-XI makes it work from a sprite Handle in the handle pass
  (the rest of the Handle — phase write, record 500, the minion spawns — runs after the resume).
- Spiked ball Box 0x5c4 (form 2 rain): its Box arm and its `.HitPlayerSprite` arm (M l. 49189–49197: R(100) < 0x33 → 0
  coins else 5, `.HurtPlayer(0xa8, blood 1, invul 0x3c)`) are Phase 6 cards (`BoxSprite.swift:474`).

### 6.7 Pieces, duties, engine
killProc `.xichra` (the unconditional tail; unreachable in play but built as read); **no step-7 row** (the dump has
none — a test pins that contact does nothing); Smite `.xichra` (a seed is an id-0x5a hit); `SpriteHandler.xichra`,
`.xichraWing`; Statue none; no liquids; write-back `+0x18a` (body; the wing's record 0x1ff is outside the guard) /
`+0xea`; the stagger (§3.7, shared with the Chief); arena none (v = 0). Engine not built: CLUT animation (6B-CA) with a
mutable `+0x2730`; the Handle-site conversation suspension; the rotating cannon arm (6C-XL); the 0x5c4 spiked ball (Box
card); `.Victory` (6C-VI); 6A-FB (0x46a cuts).

### 6.8 Proposed split and tests (`XichraTests.swift`)
**6C-XI1 — Setup, Init, phases, float**: Setup writes and the three spawns (wing record 0x1ff, cannons at (−24, 260) /
(779, 262) records 400 / 401); tables A and B (table B[90] = 220, A[5] = 10); cache registration (16 sets after 0x784, flag
1); `testXichraBobOrder` (bob removed before the `+0xe9` test, added after Cleanup); sway approach 0x30 and the angle
wrap; the phase table (form, `+0x2730`, target per phase); the action cycle (R(60) + 90 only on 2 → 0); phase 0 at frame
80 (conversation 250, record 500 p3 4, minions at cx − 298 / cx + 82, camTop − 110); phase 1 → 2 on both minions dead
(conversation 251).
**6C-XI2 — the attack and crash states**: DoXichraShot (draw before the spawns, ±1 step wrap, 0xa28 / 0x10c2); the rain
patterns ×4 (X formula, parity, the 0x772-only gravity write); crash (gravity only in state 4, the second-grounded-frame
cue, shake 0x12, stagger 0x14, the three exits); grounded window 30; rise N 28 / 14; transform (conversation 252 at
125, fast); death (11 explosions, draw order Rand R(10000) / R(30) / R(65), victory flag from w+0x38 = 211); faces and
the wing copy (the x256 slip — the build checks the wing draws at Xichra's x when its Handle runs first in the list).
**6C-XI3 — Hit, Kill, the fight**: state-5 window (invul 10, k blood, kill on a hurt only); id 0x5a phase hits and the
form-2 crash; deflection ×0.4 and burn; solids 100; contact none; Smite; `testXichraScriptedVictory` (measured).

Scripted victory: on paper the tail is fixed — state 8 begins on the frame of the phase-6 crash landing's exit, and the
victory flag is set on the 211th state-8 frame after it; the frames before (three id-0x5a hits in phase 2, four in phase
3, the phase-4 crashes and 5000 HP of grounded hits, three in phase 5) depend on seeds lobbed by the lair's cannons and
are **measured** by the build.

---

## 7. Row coverage of `gap-ledger/routines-classified.tsv`

Measured: **46** rows carry the exact phrases "phase 6 (boss)" (40) or "phase 6: boss face cache registration" (6).
The card's **52** is those 46 plus six rows found by a wider grep (`boss|Xichra|Victory|arena`): `.ShootSpines`
("phase 6 (Dillo boss)"), `.sinDegrees` ("phase 6 (Xichra)"), `.PlayerConstraints` ("partial — boss-arena lock") and
the three "phase 6 (victory sequence)" rows. Eight of the 46 (and `.ShootSpines`) are the **Dillo's**, built in run 45
(`Dillo.swift`) — the ledger was classified before that and is stale for them. So **39 rows are this document's** (38 of
the 46 plus `.sinDegrees`), each in exactly one contract:

| contract | rows (address name) | n |
|---|---|---|
| §2 Warrior | 100877d0 `.InitWarriorSprite`, 100878ac `.SetupWarriorSprite`, 10087afc `.WarriorLayEgg`, 10087b6c `.RandomWarriorAttack`, 10087c04 `.HandleWarriorSprite`, 1008854c `.HitWarriorSprite`, 1008874c `.KillWarrior`, 10088834 `.HitWarriorTileSprite` | 8 |
| §3 Chief | 1008b3f8 `.InitChiefSprite`, 1008b538 `.SetupChiefSprite`, 1008b724 `.GoblinChiefRandomCry`, 1008b878 `.HandleChiefSprite`, 1008c0e0 `.HitChiefSprite`, 1008c350 `.KillChief`, 1008c434 `.HitChiefTileSprite` | 7 |
| §4 Wizard | 1008c5c8 `.InitWizardSprite`, 1008c6a8 `.SetupWizardSprite`, 1008c8e8 `.HandleWizardSprite`, 1008d470 `.HitWizardSprite`, 1008d69c `.KillWizard`, 1008d784 `.HitWizardTileSprite` | 6 |
| §5 Fire Guardians | 10089ec4 `.InitDemonSprite`, 1008a0ac `.SetupDemonSprite`, 1008a400 `.HandleDemonSegs`, 1008a594 `.HandleDemonSegSprite`, 1008a630 `.HandleDemonSprite`, 1008b0b4 `.HitDemonSprite`, 1008b2d0 `.KillDemon` | 7 |
| §6 Xichra | 1008d918 `.InitXichraSprite`, 1008dc7c `.HandleXichraWingSprite`, 1008dce4 `.sinDegrees`, 1008dd44 `.SetupXichraSprite`, 1008e180 `.StandardXichraFloat`, 1008e24c `.UpdateXichraCannons`, 1008e388 `.DoXichraShot`, 1008e4ec `.HandleXichraSprite`, 1008fdf4 `.HitXichraSprite`, 100902a4 `.KillXichra`, 10090384 `.HitXichraTileSprite` | 11 |
| **total** | | **39** |

The other 13 of the card's 52, owned elsewhere (named once, owned zero times here):
- Dillo, built (run 45): 10086120 `.InitDilloSprite`, 1008622c `.SetupDilloSprite`, 1008648c `.ShootSpines`, 1008678c
  `.DilloLayEgg`, 100867fc `.RandomDilloAttack`, 1008697c `.HandleDilloSprite`, 10087334 `.HitDilloSprite`, 100875bc
  `.KillDillo`, 1008763c `.HitDilloTileSprite` (9).
- `.PlayerConstraints` 1004cb4c: arena part built at LV5 (`BossArena`, §1.1) (1).
- 1000ac3c `.Victory`, 1000a6ac `.CopyVictoryStitch`, 1000aa68 `.CreditScreen`: non-boss "phase 6 (victory sequence)"
  rows → ENG / 6C-VI; Xichra's contract names only the hand-off flag (3).

---

## 8. Disagreements (dump wins; the bank files carry dated corrections for D1–D9)

| # | where | said | the dump | evidence |
|---|---|---|---|---|
| D1 | bosses §2.2 (`.RandomWarriorAttack`) | swings = R(2) + 1 | the routine first draws **R(100) and discards it**, then R(2) | M l. 73102; raw `10087b7c..10087b84` |
| D2 | bosses §2.2 attack | "`+0x46 > 16` → 0" (cycle length implicit) | first swing 18 frames, later swings 17 (reset then + 1) | M l. 73254–73264 |
| D3 | bosses §3.2 crate carry | "crate x = (playerX − 16)(1 − t) + x·t" | the `x` is the **crate's own** current x / y (an easing recurrence), not the Wizard's | M l. 76027–76040 |
| D4 | bosses §3.2 fireballs | "a 20-frame charge" | 21 frames at n = 7 (an arming frame sets `+0xa6 = 20`), re-armed every volley | M l. 75768–75791 |
| D5 | bosses §4.2 jump | R(100) and R(6000) listed without order; "at `+0x46 == 3`" | R(100) (lane) **before** R(6000) (pitch); the test uses n after its + 1 (third jump frame) | M l. 75295–75307 |
| D6 | bosses §2–§4 Inits | (flag not mentioned) | Wizard, Chief, Xichra register under `*_DAT_100a0a48 = 1` (flag-1 cache records); Warrior and Demon flag 0; Chief / Wizard register their sets before the single | M l. 75020–75026, 75582–75586, 76216–76233 |
| D7 | bosses-2 §5.1 segments | "layer `+0x80 − 1`" | the segment's own Setup stores layer 0xc after `.MTNewSprite` stored the argument → **layer 0xc**; the partner's layer argument is its record index, also overwritten to 0xc | M l. 74401, 74461–74463, 74480–74483; M l. 30710–30717 |
| D8 | bosses-2 §5.1 | (silent) | each segment Setup draws R(10), reads p4 from record 0x1ff (hdr + 0x1ffe), and the Demon Setup has **no `+0x88 = 0`**; three null reads on emptied segment slots | M l. 74443, 74423–74424, 74528, 74715–74723, 74806, 74880–74886 |
| D9 | bosses-2 §6.4 state 8 | "snd 435 … explosion at (cx − 75 + R(65), cy − 31 + R(30))" | the sound is **`.STPlay3DSoundRand`** (one R(10000)); then R(30) (y) **before** R(65) (x) | M l. 77177–77185 |
| D10 | bosses-2 §6.4 form 1 | "gravity 0" for both | only the 0x772 gets `+0x110 = 0` and vy 0 written | M l. 76903–76918 |
| D11 | card BOS "contact-damage row … M l. 49836–49846" | one range | routing list M l. 49514–49521, damage rows M l. 49840–49851 (Warrior / Wizard / Chief), Demon default, **Xichra none** | M l. 49514–49521, 49827–49851 |
| D12 | card BOS "three pieces … which no boss has today" | none built | the Warrior has all three in part: routing + default 0x70, `Smite.enemyHandlers`, the killProc count arm | `HitPlayerSprite.swift:67`, `Smite.swift:18`, `EnemyCommon.swift:98` |
| D13 | card BOS acceptance "(52 rows)" | 52 | 46 exact-phrase rows; 39 in these contracts; the 52 includes 9 built Dillo rows, `.PlayerConstraints` and 3 victory rows (§7) | `routines-classified.tsv` |
| D14 | ledger rows for the Dillo / `.PlayerConstraints` | "not built" / "partial" | built (run 45; LV5) — the ledger is stale | `Dillo.swift`, `BossArena.swift` |
| D15 | plan "6A-FB the fireball cache (before 6A-W)" | a Warrior prerequisite | the Warrior never touches 0x46a; the first users are the Wizard (6B), the Demon and Xichra (6C) — an order choice, not a dependency | M l. 72975–73530 |
| D16 | `PlayerStates.swift:371` comment | the boss-grab arm "l. 45625–45672" | M l. 45591–45632 (45625ff is the hurt-stun's lead-in) | M l. 45591–45672 |
| D17 | bank §1.4 line cites throughout | old dumps | §1.3 table | — |
| D18 | bosses-2 §6.5 | (silent) | the state-5 arm of the Xichra Hit has **no HP > 0 test** (the other four Hits gate on HP) | M l. 77365–77368 |
| D19 | bosses-2 §6.3 | phase 0 trigger "state-0 frame 80" | `+0xa6` (i16) counts every state-0 frame of the whole fight; it equals 0x50 again only after a 65,536-frame wrap — LOW, a test pins the one-shot in normal play | M l. 76801–76802 |

---

## 9. For the planner

### 9.1 Task split (test counts are sized like the neighbouring enemy files, 5–15)

| boss | tasks | tests |
|---|---|---|
| Warrior | 6A-FR (rock player arm) → 6A-W1 Handle → 6A-W2 Hit / Kill / fight | — / 8 / 8 |
| Chief | 6A-CH1 class + Setup + Init + Handle + the stagger arm → 6A-CH2 Hit / Kill / pieces / fight | 9 / 8 |
| Wizard | 6B-WZ1 Setup + Init + Handle → 6B-WZ2 Hit / Kill / fight (after 6A-FB) | 9 / 7 |
| Fire Guardians | 6C-DM1 Init + Setup + segments → 6C-DM2 Handle → 6C-DM3 Hit / Kill / fight (after 6B-FI, 6A-FB) | 8 / 9 / 8 |
| Xichra | 6C-XL lair (rotating cannon arm) → 6C-XI1 Setup + phases → 6C-XI2 states → 6C-XI3 Hit / Kill / fight (after 6B-CA, the Handle-site suspension, 6C-VI's flag, the 0x5c4 ball) | — / 9 / 10 / 8 |

### 9.2 Engine features not built today, by boss (for ENG's cross-check)
- Warrior: 6A-FR only.
- Chief: the stagger's player arm (M l. 45591–45632) — also Xichra's.
- Wizard: 6A-FB.
- Fire Guardians: the End key read (`IsPressed(0x77)`); 6B-FI (flame buffer, fire mode 2, 0x46a sparks); 6A-FB;
  the `*_DAT_1009fecc` global.
- Xichra: 6B-CA with a mutable hdr `+0x2730`; a conversation suspension from a sprite Handle; the rotating cannon arm
  (p1 101…106, 6C-XL); the 0x5c4 spiked ball's Box and player arms; 6C-VI (`.Victory`); 6A-FB; the stagger arm.

### 9.3 Not derivable on paper (each build task measures, then pins)
Every scripted kill's HP-0 frame; each burning face's opaque top / bottom (read through the face store, as
`GoblinBurnLevelRunTests` does); the Chief's idle activation frame on level 18; whether the Demon's segment 7 dies
before its head (§5.7 — a possible STOP); the wing's list order against Xichra's (§6.3 step 8); record 0x1ff's p4 word
on level 55.

### 9.4 Read depth
Warrior and Chief: every line of their spans read and transcribed. Wizard, Fire Guardians and Xichra: every state of
Setup / Handle / Hit / Kill read in the committed dump; nothing here is marked skimmed except the Demon's sine-table
call (the decompile garbles the `sin` return; the bank's raw-derived formula is kept) — re-derive it at 6C-DM's planning
run.
