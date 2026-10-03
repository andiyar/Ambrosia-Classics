# Ferazel's Wand 1.0.3 — bosses (2 of 2): Fire Guardians, Xichra, boss projectiles, open items

**Code readings only; nothing behaviour-verified.** Date 2026-10-03. Sources, conventions and
§1 (shared framework: parameters, boss flag, arena, kill consequences, damage tables, sounds)
are in `bosses.md`; section numbers continue from it. ⚑ wave 2 (2026-10-04): §8–§12 continue in `bosses-3.md`.

---------------------------------------------------------------------------------------------

## 5. Fire Guardians — class Demon (types 1920..1929; level 55)

Callbacks: Setup `.SetupDemonSprite @ 1008a0ac` (handler l. 20886–21022), Handle
`.HandleDemonSprite @ 1008a630` (l. 21040–21368), segment handler `.HandleDemonSegSprite @
1008a594` (l. 21023–21039), Hit `@ 1008b0b4` (l. 21369–21429), Kill `@ 1008b2d0`
(l. 21430–21469); no tile callback (`+0x1f8 = 0`). Helpers: `.InitDemonSprite @ 10089ec4`
(main l. 53440–53482), `.HandleDemonSegs @ 1008a400` (main l. 53483–53539).

### 5.1 Assets and setup  [HIGH]
Face sets (`.InitDemonSprite`, 144×116 cells): PICT 1920 → `PTR_DAT_100a0d84` sway (6), 1921 →
`_DAT_100a0d80` fire (6), 1922 → `_DAT_100a0d7c` roar (3), 1923 → `_DAT_100a0d78` hurt/death (4),
1924 → `_DAT_100a0d74` neck segment (2 frames, 96×96). Sine table `_DAT_100a0d70`, 560 i32:
`table[i] = (int)(sin(i · 0.17951943 · 0.0625) · 95 · 256)` (f32 0x100a1c7c = 2π/35, 0x100a1c78 =
1/16, 0x100a1c74 = 95, 0x100a1c70 = 256; `lfs -0x5bc4/-0x5bc8/-0x5bcc/-0x5bd0` 10089ff0..1008a004;
loop bound `cmpwi 0x230`) — one sine period over 560 entries, amplitude 95 px in 24.8.

Setup: layer 0xc, gravity 0, Kill `+0x50`, `+0x18a = 1`, `+0x1b4 = 1`, HP 1000/2000 by p4 (boss
flag also `fed0 = 0`), hot rect `SetRect(0x1a,0x17,0x4a,0x3a)` (per frame
`SetRect(0x22,0x14,0x67,0x5e)`), state 6, `+0x46 = 2`, `+0xa6 = FastRand(10)`, anchor `+0x14c =
x<<8`, `+0x150 = y<<8`, `+0x154 = 0` (never written again), neck length `+0x158 = 0`, `+0x15c =
+0x160 = 0`, neck speed `+0x164 = 0x300`, extend flag `+0x168 = 1`, facing `+0x17e = (type ==
0x781)` (1 = right), `+0xf0 = 0x1e` (unused).
Types 0x780 / 0x781 (1920 / 1921) only:
- `+0x9c = AllocateGameMem(0x30)` (NewPtrClear): `t[0..7]` = eight segment sprites type **0x785**
  (1925) at (x+30, y+30), layer `+0x80 − 1`, record 0x1ff (none), Demon setup → segment branch;
  seg 7 gets `+0x46 = 1` (face 1 of PICT 1924), others 0. `t[8]` (+0x20) wave speed = 16, `t[9]`
  (+0x24) wave phase = 0, `t[10]` (+0x28) extend timer = 0, `t[11]` (+0x2c) hit escalation = 0.
- 0x780 also sets `_DAT_1009fecc = 2` (guardians alive; `.SetupLevelSprites` zeroes it) and spawns
  the partner **0x781 at (x − p3·32, y)** with the **same record index** (`+0x1e0` = partner). The
  partner reads the same p4 (same HP, also clears `fed0`). Level 55: p3 = 20 → partner at x 455,
  facing right; the placed 0x780 at x 1095 faces left.
Any other type in 1922..1929 takes the segment branch: handler `.HandleDemonSegSprite`
(`PTR_PTR_100a0d64`), no Hit, no tile callback, empty hot rect `SetRect(0,0,0,0)` — an inert
sprite. The segment branch keeps `+0x50 = .KillDemon` (set before the type test) [HIGH].

### 5.2 Per-frame  [HIGH]
Skip if `+0xe9`/`+0x1b2`. `.StandardSpriteHandles`; rect; `phase += t[8]`, reset to 0 (not
modulo) when ≥ 0x230. **Key code 0x77 held → HP = −1** — no debug-flag test (raw 1008a6c4..
1008a6dc: `li r3,0x77; bl IsPressed; … li r0,-0x1; sth r0,0xa4`) [HIGH; key name "End" MED].
`type == 0x780` → write 0x781 then subtract 1 (a no-op; same idiom in `.HandleBurn`). ⚑ wave 2 (2026-10-04): also in
`.UpdateSprites` for 0x6ea; no call or branch between the two stores, so the transient value is
unobservable — omit in a replica (bosses-3 §10.4) [HIGH].
`+0x50 = .KillDemon`. State switch (`n` = `+0x46`):

| state | behaviour |
|---|---|
| 6 sway | `t[8] += 2` while `t[8] < t[11] + 16`; n cycles 0..9, sway frame n (n < 6) or 10 − n; `+0xa6++`. When `+0xa6 > 30 + FastRand(30)` (re-rolled each frame), neck > 0x577f (87 px; `cmpwi 0x5780` 1008a794) and n < 2: n = `+0xa6` = 0, then **roar** (state 9) if `FastRand(100) < 45` (`< 21` right after a roar, clearing `+0x160`), else **fire** (state 2); but if the player is behind (facing left and player x > cx, or facing right and player x < cx) stay in 6 with `+0xa6 = 0` |
| 2 fire | `+0x164 ×= 0.75`; while `t[8] ≥ 1`: `t[8] −= 2` (floor 0), sway frame 0, n = −1 (the neck stops undulating first). Then n++ (and `+0xa6++`): **n = 4** → enemy shot **0x46a** at (x + 96·facingRight + 8, y + 0x28) (pointer `+0x1d4`, its `+0xb8 = 0xb0002`), aimed: `.FindDesiredDirectionGeneric(player cx/cy, shot centre)` → one of 36 10°-steps, `FUN_1003f218(shot, dir, 0x708)` **adds** an impulse of 0x708 (7 px/frame) from the 36-entry table of physics.md §6 (`li r5,0x708` 1008abc0); snd 300 rate 36000+`FastRand(12000)`. n = 5 → shot `+0xb8 = 0xb0000`, 6 → `0xb0001`, 7 → 0. Fire frame `min(n,4)` for n ≤ 4, else `min(10 − n, 4)`. n ≥ 11 → state 6 |
| 9 roar (vulnerable) | `+0x164 ×= 0.75`; `t[8]−−` while `t[8] > (t[11]+16)/2 − 2`; n++; roar frame `n/2` for n/2 < 3, else `min(24 − n/2, 2)`; n > 47 → `+0xa6 = FastRand(30)`, n = 0, `+0x160 = 1`, state 6 |
| 8 recoil (from Hit) | at n = −1: `t[11]++` (each landed hit permanently raises the sway wave-speed cap by 1); `+0x164 ×= 0.75` (Hit set it to −0x800: the neck snaps back); n++; hurt frame n (n < 4) else `max(7 − n, 0)`; segment `t[7 − n]` (n < 8) flash `+0xaa = 8` (a flash runs down the neck); n > 6 → state 6 |
| 4 dying | `t[8]−−` to 0; vx ×0.9 (no effect, x is recomputed); hurt frame `min(n>>2, 3)`, n cap 12; `+0xa6++`: at 12 → `+0x1a2 = 1` (head burns); at `+0xa6 = 12 + k` (k = 0..7) segment `t[k]` gets `+0x46 = 0`, `+0x1a2 = −(30·(7 − k) + 1)` — segment 7 starts burning at frame 20, segment 0 at frame 223 (the neck burns from the head back to the body) |

Constants: 0.75 = 0x100a1c60 (`lfd -0x5be0`, 1008a938/1008aa2c/1008ac84), 0.9 = 0x100a1c58
(`-0x5be8` 1008ad70). Roar/fire odds `cmpwi 0x2c` 1008a7d0, `0x14` 1008a848.

Neck motion in states 2, 6, 8, 9 (l. 21300–21333): neck ≤ 0x4c00 (76 px) → `+0x168 = 1`
(extend); neck ≥ 0x9f00 (159 px) → 0 (retract). Retracting: `t[10] = 0`; speed −= 0x80 while
> −0x400. Extending with speed < 0x400: `t[10]++`; speed += 0x80 once `t[10] > 70` or speed < 0.
`neck += speed`, clamped to [0x2d00, 0xaf00] = [45, 175] px. So the head swings in and out.

Position (every live frame, l. 21336–21366):
- `.HandleDemonSegs` (0x780/0x781 only; raw 1008a400–1008a56c): for segment i = 0..7 (a dead
  one's slot is cleared): `d = i·neck/8`; facing copied; `seg.x = anchorX ± d + 0x1800` (+24 px);
  `idx = (phase + ((0xaf00 − d)>>7)·neck/0xaf00) mod 560`; **`seg.y = 2·anchorY + +0x154 +
  d·table[idx]/0xaf00 − 0x6a00`**. The anchor y is added twice (`lwz r31,0x150(r3)` 1008a4a0 and
  `lwz r11,0x150(r3)` 1008a510, both summed) [HIGH]. With the only shipped placement (y = 105) the
  result is anchorY − 1 px + wave, i.e. it only looks right because 2·105 − 106 ≈ 105; a replica
  must keep this formula or keep the guardian at y 105 [HIGH reading; "bug" LOW].
- Head: `x = anchorX − neck` (facing left) / `+ neck` (right); `y = anchorY + +0x154 + +0x15c`
  with `+0x15c = −0xa00 − (anchorY − seg7.y)` ⇒ **head y = segment-7 y − 10 px**; vx = vy = 0.
  (State 6's own `+0x15c = neck·table[phase]/0xaf00` is overwritten here for 0x780/0x781 — dead.)
- Segment sprite each frame: face = PICT-1924 frame `+0x46`; handles/cleanup (incl. burn).

### 5.3 Damage taken  [HIGH]
Only player shots with `shot+0xa6 == 0` while HP > 0. In **state 9 with n > 4** (48-frame roar,
frames 5..47): shot killed silently; **V Blade (id 6)** → snd 303 only, no damage; any other shot
→ `.HurtSprite(dmg = shot+0xa4, shot.vx/2, −1000, 2, 8)`; if it landed: snd 702 (HP ≤ 200) or
701, 60 % a grunt 477/478 at 42000+`FastRand(10000)`, then state 8, `+0xa6 = n = −1`, neck speed
−0x800 (`li r0,-0x800` 1008b250). Outside the window: shot killed + snd 303. Falling solids are
not tested. Two guardians × 2000 HP; at Fireball damage 100 that is 40 landed roar hits.

### 5.4 Damage dealt  [HIGH]
Contact with a guardian's head rect: generic 0x70 (bosses.md §1.6); segments have empty rects.
Fireball 0x46a: §7.

### 5.5 Kill  [HIGH]
`.KillDemon` runs for the guardians and for **every segment** (segments burn, then their `+0x50`):
count/defeated-stat per call (the 2 guardians and 16 segments were all counted at load, so the
level-55 enemy total includes 18 for the pair), **score `G+0 += 1000` per call** (unconditional,
1008b338) → 9,000 per guardian, 18,000 for the pair; for 0x780/0x781 with the boss flag:
`_DAT_1009fecc−−`, thunder/shake/flash on each guardian, and `fed0 = 1` only when the count drops
below 1. Both guardians share record 7, so the first death already clears that record (`+0xea`,
bosses.md §1.4) — a checkpoint save between the two deaths would store the pair as gone [MED].

---------------------------------------------------------------------------------------------

## 6. Xichra (types 1990..1999; level 67)

Callbacks: Setup `.SetupXichraSprite @ 1008dd44` (l. 22589–22772), Handle `.HandleXichraSprite
@ 1008e4ec` (l. 22773–23546), wing `.HandleXichraWingSprite @ 1008dc7c` (l. 22578–22588), Hit
`@ 1008fdf4` (l. 23547–23653), Kill `@ 100902a4` (l. 23654–23686), HitTile `@ 10090384`
(l. 23687–23708: `.WallBounce` for FG tiles only). Helpers (main): `.InitXichraSprite @ 1008d918`
(l. 53628), `.sinDegrees @ 1008dce4` (`sin(2·π·d/360)`: doubles 0x100a1ce8 = 2, 0x100a1cf0 = π,
0x100a1ce0 = 360, raw 1008dcf0–1008dd04), `.StandardXichraFloat @ 1008e180` (l. 53676),
`.UpdateXichraCannons @ 1008e24c` (l. 53715), `.DoXichraShot @ 1008e388` (l. 53749).

### 6.1 Setup and work block  [HIGH]
Record index 0x1ff → this is the **wing** sprite: handler only (`.HandleXichraWingSprite` =
StandardSpriteHandles + Cleanup). Otherwise: `+0x18a`, layer 1, HP **5000**, `fed0 = 0`, `+0x88 =
0`, `+0x1b4 = 0`, rect `SetRect(0x5c,0x3a,0x93,0x90)`, state 0, `+0x46 = 2`, position forced to
**home (325, 72)**, `+0x15c/+0x160/+0x168` = x ∓ 256 / x (never read), `+0x17e = 0`, `+0xf0 = 0x1e`.
Spawns: wing type 100 at (0,0), layer 0, record 0x1ff (`w+0x00`); cannon A type 0x443 at (−24, 260),
record **400**, Background setup (`w+0x04`); cannon B type 0x449 at (779, 262), record **401**
(`w+0x08`). Work block `+0x9c = AllocateGameMem(0x374)` (zeroed):

| w+ | type | meaning |
|---|---|---|
| 0x00/0x04/0x08 | ptr | wing, cannon A, cannon B |
| 0x0c/0x0e | i16 | home x / y |
| 0x10 | i16 | y at crash landing |
| 0x12 / 0x13 | u8 | "ready" (current action finished) / **fast** flag (set at the end of state 7) |
| 0x14 / 0x16 | i16 | face group (0 float, 1 cast, 2 crash) / frame index |
| 0x18 | i16 | bob index into table A (0..19) |
| 0x1a | i16 | **form** 0..4 (set by the phase) |
| 0x1c | i16 | **hits left** in the phase (3 at start) |
| 0x20 | i32 | sway angle, degrees·256 (starts 0xb4), wraps at 0x16800 |
| 0x24 / 0x28 / 0x2c | i32 | sway speed target / saved target / current (approaches target by 0x30/frame) |
| 0x34 | i32 | action timer |
| 0x38 / 0x3c | i32 | crash/landing counter / rise counter |
| 0x40..0x64 | i32 | rain pattern: side flag, count k, delay, rows, (0x50 unused), row length, delay in row, delay between rows, mode (1 drop / 0 sweep), object kind (0 box 0x434, 1 Box 0x5c4, 2 shot 0x753) |
| 0x68 | i16 | wind-up 0..37 (raises Xichra 6 px per unit) |
| 0x6a | i16 | **phase** 0..6 |
| 0x6c | i16 | minions alive |
| 0x7c | i16[20] | table A: `(short)(sin(18°·i)·10)` (f32 0x100a1cdc = 10.0) |
| 0xa4 | i16[360] | table B: `(short)(sin(i°)·220)` (f32 0x100a1cd8 = 220.0); 0xa4 + 720 = 0x374 |

Faces (`.InitXichraSprite`, 240×200 cells): body group 0 = PICTs 1980/1981/1982 (frames 0–3 /
4–7 / 8–9), group 1 = 1983/1984 (0–3 / 4–5), group 2 = 1985/1986/1987 (0–3 / 4–7 / 8–11); the wing
uses 1970–1972 / 1973–1974 / 1975–1977 with the same indices, `+0xb8 = 0xb0001`, same position and
facing (its fixed-point copy writes `+0x14` twice — x then y — a harmless slip) [HIGH].

### 6.2 Movement  [HIGH]
In states other than 4–8: `w+0x2c` steps 0x30 toward `w+0x24`; `angle += w+0x2c`;
`x = homeX + tableB[angle>>8]` (±220 px sway), `y = homeY − 6·w+0x68`. In all states except 4/5
a bob `y += tableA[w+0x18]` (±10 px, 20-frame cycle) is added at the end and subtracted at the
start of the next frame. `.StandardXichraFloat`: face group 0, frame `(n mod 20)/2` (fast: `n mod
10`), facing 1 iff player x > cx − 4.

### 6.3 Phases (`w+0x6a`, switch at l. 22840–22955)  [HIGH]
| phase | form | hdr+0x2730 | sway target | exit |
|---|---|---|---|---|
| 0 | 0 | 3 | 0 (`w+0x2c = 0`) | state-0 frame 80 (`+0xa6 == 0x50`): Mcnv **250** ("Xichra 1"), record 500 p3 = 4, two Walker-class **0x6d6** minions (record 500, layer 0x14) at (cx − 298, camTop − 110) / (cx + 82, camTop − 110), `w+0x6c = 2` → phase 1. (`+0x100 = 1` is written twice to the first minion, never to the second: raw 1008ecc4/1008ece8 — ⚑ wave 2 (2026-10-04): harmless, the Walker Setup already sets `+0x100 = 1` for p3 = 4; the minions are 2000-HP tier-4 Ax goblins, bosses-3 §8.4) |
| 1 | 0 | — | 0 | each minion with `+0xe9` → `w+0x6c−−`; at < 1: Mcnv **251** ("Xichra 2") → 2 |
| 2 | 0 | 3 | 0x200 | hits < 1 → 3: hits = 4, flash 5, snd 468 rate 78000+`FastRand(12000)`, `.UpdateXichraCannons` |
| 3 | 1 | 4 | 0x300 | hits < 1 → 4: hits = 4, flash 5, snd 468 ×2 (78000+, 90000+) |
| 4 | 2 | 5 | 0x400 | a crash landing with HP < 1 (§6.4 state 4) → 5 |
| 5 | 3 | 6 | 0x600 | hits < 1 while state ∈ {0,1,2} → 6: flash 7, **HP = 9999**, state 4 (crash), snd 468 ×2 |
| 6 | 4 | 7 | 0 | crash landing → state 8 (death) |

Action cycle, phases 2–5: `w+0x34−−`; when < 1 and ready: state 0 → 1, 1 → 2, 2 → 0 with `w+0x34 =
90 + FastRand(60)` (`addi … 0x5a` 1008e7f4). The timer reloads only on 2 → 0, so the shot and
rain attacks run back to back after each 90–149-frame float. hdr+0x2730 is the CLUT-animation
mode field (sprites-backgrounds-sounds.md §4; L67 header ships 3, 16, 75, 12000) ~~[MED: visual]~~
⚑ wave 2 (2026-10-04): decoded — modes 3..7 recolour the magenta ramp (palette 239..254) that makes up ~15 % of the
throne-room backdrop PICT 387: violet → orange → red → flickering grey → black (bosses-3 §9) [HIGH].

### 6.4 States (`+0xb0`, switch at l. 22995–23400)  [HIGH]
| state | behaviour |
|---|---|
| 0 float | ready := 0; rect as Setup; Float; ready when current sway speed = target; `+0xa6++` (phase-0 trigger) |
| 1 shoot | sub 0: Float, save target, target 0; when stopped and frame 0 → sub 1: face group 1, n++, frame n/2 (n < 12) else (21 − n)/2; **n = 12: `.DoXichraShot(3)`**; n > 20 → sub 2: Float, restore target, ready when reached and frame 0 |
| 2 rain | sub 0: Float, target 0, wind-up +1/frame to 37 (rises 222 px, off the top); when stopped, wind-up 37, frame 0 → sub 1, pattern by form (table below); sub 1 spawns one object per expiry of the delay; sub 2: Float, restore target, wind-up −1/frame, ready at 0 |
| 4 crash | target 0, bob index 10, rect `SetRect(0x5c,0x50,0x93,0xa2)`, **gravity 0x15e**, group 2, n++ cap 18, frame n/3; gravity applies only in this state. Grounded (`+0xcd`): on the second grounded frame (`w+0x38 == 1`, tested before `w+0x38++`): snd 435 rate 50000+`FastRand(500)`, **shake 18**, **player stunned 20 frames** (`_DAT_100a0570 = 0x14`) if grounded. When `w+0x38 > 6` and n = 18: `w+0x38 = 0`, n = 12, `w+0x10 = y`; then: HP < 1 → form 2: phase+1 (→5), form 3, state 7, n = 24, hits 3 / other form: state 5; HP ≥ 1 and hits < 1 and form 4 → phase 6, n = 24, state 8; else state 5 |
| 5 grounded | target 0, bob 10, group 2; `w+0x38++`; **vulnerable while `w+0x38 ≤ 30`** (§6.5); after 30: n−− from 12, at < 0 → state 6; frame n/2 |
| 6 rise | wind-up 0; `w+0x3c++` to N = 28 (14 when fast); `y = (homeY·c + w+0x10·(N − c))/N`; Float; c > N and frame 0 → state 0 |
| 7 transform | `w+0x38++`; up to 125: n++ cap 43, frame n>>2; at 125: Mcnv **252** ("Xichra 3"), n = 11, flash 3, grunts 477/478 at 78000+ and (vol 0x97) 58000+; then n−− to < 0 → state 6, **fast = 1** |
| 8 death | `w+0x38++`; < 61: n++ cap 43, frame n>>2 (a `== 0x7d` test inside is dead); then m = `w+0x38` − 60 (m starts at 1): at m = 12, 24, …, 132 (11 times): snd 435, flash 4, **shake 20**, explosion sprite **0x4b7** (Effect class, PICT 1207 "big explosion") at (cx − 75 + `FastRand(65)`, cy − 31 + `FastRand(30)`), layer 0xc; **m > 150 (frame 211): `DAT_100a5106 = 1` and `*_DAT_1009ffc4 = 1`** → `.GameLoop` ends → `.Victory` (engine.md §6); frame 10 |

Wounded glow (bosses.md §1.7) in every state but 8, for 0 < HP ≤ 2000 (`0x7d1`), period 30/12.

`.DoXichraShot(s, N)`: snd 300 rate 36000+`FastRand(12000)`; N enemy shots **0x46a** at (cx−24,
cy−24), layer +1; direction = aim at the player (36 steps) + (i − N/2) → −1/0/+1 step (±10°),
wrapped mod 36 (`cmpwi 0x23`, `±0x24` 1008e460–1008e474); impulse **0xa28** (10.2 px/frame), or
**0x10c2** (16.8) once fast.

Rain patterns (sub 1 of state 2; positions are absolute world x, camera-relative y):
| form | object | per row | rows | delay in row / between rows |
|---|---|---|---|---|
| 0 | Box **0x434** dropped at (X − 16, camTop − 32) | 9 (k = 8..0) | 2–4 | 9 / 21 |
| 1 | pair **0x771** at (camLeft − 60) vx +0x1068 and **0x772** at (camLeft + 608) vx −0x1068, y = 420 − 160·k/5, dmg 0x70, `+0x16c = 1`, layer 1200 | 6 | 3 | 10 / 30 |
| 2 | Box **0x5c4** at (X − 0x33, camTop − 0x43) | 8 | 1–4 | 8 / 16 |
| 3 | enemy shot **0x753** at (X − 0x2f, camTop − 0x3f) | 7 | 1–2 | 8 / 16 |

Drop X: `idx = len − k` or `k` alternating by row parity (`rows & 1`, inverted by the random side
flag), `X = idx·704/len + 96 ± (704/len)/4` (+ for the `len − k` order) — 96..800 across the
screen-wide lair. Kind `w+0x64` is written only by forms 2 and 3; form 0 relies on the zeroed
block [HIGH].

### 6.5 Damage taken  [HIGH]
Shots with `shot+0xa6 == 0`:
- state 5 and `w+0x38 < 31`: `.HurtSprite(dmg = shot+0xa4, 0, −1000, invul 10, flash 10)`; on
  success grunt 477/478 (vol 0xab, 78000+), snd 701 (78000+), shot killed silently, blood spray
  `k = max(dmg/100, 1)`: `(40k, 50k + 350, 150k, 2)`, snd 701 vol 0x55 if HP still > 0. Invul 10 in a
  30-frame window → at most 3 HP hits per landing.
- states 0..3: **id 0x5a** (Fire seeds, item 6 — 800 damage, or 1400 with `+0xf4`, item 0x1a;
  also the Ring of Smiting bolt, spells-items.md §4) with `+0x116 < 1`: shot exploded
  (`.KillPlayerShot(shot,1,1)`), **hits −1**, flash 26, invul 60 (`li r4,0x1a`/`r0,0x3c`
  1008ffd0), grunts; in **form 2** additionally flash/invul 5 and state 4 (crash). Any other shot:
  snd 303 vol 0xab, shot vx ×0.4 (0x100a1cc8), shot burns (`+0x1a2 = 1`, `+0x8c = 1`).
- states 4, 6, 7, 8, and 5 after its window: no effect, the shot continues.
- falling Statue/Box with `+0x160 ≥ 0`, any state: 100 (invul 2), `.KillBox`, snd 701 + grunt.
Fight arithmetic: phase 2 three id-0x5a hits, phase 3 four, phase 4 crashes on every id-0x5a hit
and needs 5000 HP from the grounded windows/solids plus one more crash to register, phase 5
three, phase 6 automatic [HIGH arithmetic].
Debug: with the debug flag, key 0x79 does the id-0x5a effect (l. 22811–22833) — out of scope.
Contact: none (bosses.md §1.6).

### 6.6 Kill, cannons  [HIGH unless noted]
Xichra never burns (`+0x1a2` is not set by its code), so `.KillXichra` (standard boss kill, §1.4)
is not reached in play; the game ends from state 8 [MED: no other writer of its `+0xe9` searched].
`.UpdateXichraCannons` (phase 2→3): cannon A type ← 0x443, cannon B type ← **0x444**; record 400
p1 = 0x67 (103), p2 = 15; record 401 p1 = 0x68, p2 = 15; both `+0xa6 = 0`, `+0x158 = 8`, `+0x160 =
8`, `+0x164 = 9000`, `+0x15c = +2` (A) / −2 (B). Cannon behaviour is Background-class code (types
0x442..0x44a, `.SetupBackgroundSprite` l. 13996ff: face `(type − 0x442)·4`, layer 1000, p1 selects
the mode) — ~~NOT RESOLVED here~~. Before phase 3 the cannons run with records 400/401 all zero.
⚑ wave 2 (2026-10-04): resolved in bosses-3 §8.2 — before phase 3 both are fixed (A up-right, B up-left, launch 9000);
from phase 3 A turns +2 and B −2 per 1/32 turn, 180° per move, 15-frame pause; the type writes
(0x443/0x444) change nothing because aim is set only in Setup [HIGH].

---------------------------------------------------------------------------------------------

## 7. Boss projectiles and dropped objects  [HIGH unless noted]
Enemy shots use `.SetupEnemyShotSprite @ 1005ba5c` (handler l. 5871–6042), `.HandleEnemyShotSprite`
(l. 6043–6339), `.HitEnemyShotSprite` (l. 6340–6395); damage to the player from `.HitPlayerSprite`
l. 4511–4624 (after `.ShieldBlock`; invul 60; coins: dmg 0x70 → 3 at 19 %, dmg > 0x70 → 5).
Common: animation via `+0x46`; killed when > 1000 px left of the camera or > 1000 px right of its
right edge, or below the map (`hdr+0xb282·32`).

| type | from | setup | motion / life | damage to player | removed by player shots? |
|---|---|---|---|---|---|
| 0x71f (1823) | Warrior | rect `SetRect(0x12,0x12,0x1e,0x1e)`, gravity 0; 16 frames 48×48 (PICT 1823) | straight, vx ±0xb00; faces by vx sign | 0x70 | no (excluded in `.HitEnemyShotSprite`) |
| 0x46a (1130) | Demon, Wizard, Xichra | layer 8, rect `(6,6,0x2a,0x1a)`, gravity 0, 6 frames 48×48 (`_DAT_100a0848`) | straight; 5–7 fire particles/frame (`NewParticle(1,0xbe,…)`), or 26×2 flame sparks into the flame buffer when hdr+0x2722 ≠ 0 (level 55 has 2) | 0x70 | no |
| 0x77b (1915) | Chief | rect `(0x20,0x20,0x50,0x38)` then the face rect inset (+4,+4,−4,−3), gravity 0x140, `+0x15c = 0`, **tile callback 0**; 16 frames 112×112 | ballistic, spin (+/− by `+0x15c`) | 0x70 unless `+0x14c ≠ 0`; after a hit `+0x15c = 1`, vx ×−0.15 (0x100a1a00), gravity ≥ 0x15e (bounces away) | no: a player shot touching it is killed with snd 303 |
| 0x753 (1875) | Xichra form 3 | rect `(4,0,0x14,0xe)`, `+0xa4 = 0x1c0`, life `+0x15c = 240`, random facing | gravity 0x100, vx ×0.9/frame (0x100a1a58), vx 0 on ground, flash every 45 frames | **448** (`+0xa4`) | yes |
| 0x771/0x772 (1905/6) | Xichra form 1 | rect `(2,−4,0x3a,4)`, single face, gravity 0 | ±0x1068 horizontal | `+0xa4` = 0x70 (none while gravity > 0) | — |
| Box 0x433 (1075) | Warrior | Box crate, gravity 0x100 | falls from 400–500 px above | 0x38, invul 30, box destroyed — when the box centre is above the player's and vy ≥ 600 | — |
| Box 0x434 (1076) | Wizard, Xichra form 0 | as 0x433; hovering while `+0x160 < 0` | falls | 0x70, invul 60, same condition; nothing while hovering | — |
| Box 0x5c4 (1476) | Xichra form 2 | Box class | falls | 0xa8 on contact, invul 60, coins 5 at 49 % | — |

0x46a/0x71f tile collisions are `.HitEnemyShotTileSprite` (not read here). Whether 0x77b, with
no tile callback, passes through terrain depends on `.ApplyGravityAndSeparateFromTiles` ~~[MED]~~.
⚑ wave 2 (2026-10-04): 0x46a dies on its first FG hit (ignores BG/water), 0x71f on its first wall hit
(enemy-shots §1.2/§1.3); 0x77b **passes through terrain** — `.SeparateFromTiles2` returns at once
when `+0x1f8 == 0` (1003c86c..1003c874) [HIGH] (bosses-3 §12.2).

---------------------------------------------------------------------------------------------

## NOT RESOLVED
1. `+0xb8` draw modes 1, 0xb and 0xc (`0x10008/0x10009/0x1000c`, `0xb0000..0xb0002`) and what
   `.WrapDrawSprites` does with them; the flash buffer `*_DAT_100a0008`. ⚑ wave 2 (2026-10-04): still open — carried
   by INDEX item 15 (draw effects); not attempted by the boss lane (bosses-3 NR 1).
2. ~~Xichra's cannons: Background types 0x442..0x44a with p1 0x67/0x68, p2 15 and the
   `+0x158/+0x15c/+0x160/+0x164` values written by `.UpdateXichraCannons`.~~ → closed: bosses-3 §8.2 (and §8.1 census, §8.3 cannon-fired seeds)
3. ~~`.HitEnemyShotTileSprite` for 0x46a/0x71f; whether 0x77b ignores tiles.~~ → closed: bosses-3 §12.2
4. ~~(→ held-item-melee.md, review 1b #11: the melee hit frames live in `.HandleHeldItemSprite`.)
   Which held-weapon frames carry the player-shot handler (`.HandleItemUse` condition), i.e.
   exactly when melee counts against the Chief / Xichra window; whether any player shot ever has
   `+0xa6 ≠ 0` (the boss Hit gate).~~ Closed by held-item-melee.md §1.3/§1.7: strike = swing calls
   c = 3, 4, 5; the held item's `+0xa6` is never written non-zero, so the boss gate always passes for
   melee. ⚑ corrected (review 1c, 2026-10-03) #10.
5. ~~hdr+0x2730 modes 3..7 as seen on screen (CLUT animation during Xichra's phases).~~ → closed: bosses-3 §9
6. ~~`+0xcd` (grounded/landed) — PlatformBounce writes it; the tile-landing writer was not traced.~~
   Closed (synthesis ledger A5): `.StandardSpriteHandles` copies `+0xce` into `+0xcd` at frame start
   (raw `100368c4..100368c8`); `.PlatformBounce` sets 1 on a landing (`100379c4`) — physics §0.1.
7. ~~Behaviour of the 0x6d6 minions with record-500 p3 = 4 and `+0x100 = 1` (Walker reader).~~ → closed: bosses-3 §8.4
8. ~~`+0x88 = 0` in boss mode (field meaning);~~ ~~`STPlay3DSoundPitched` rate units.~~ → closed: bosses-3 §12.1 (`+0x88` closed: light-overlay gate, physics §0.1 ⚑ corrected (review 1c, 2026-10-03) #5 — boss mode switches the light pass off.)
9. ~~Vestigial: Wizard state 11 (no writer), `w[4]`, Chief `+0xb2`, Warrior `+0x154` (egg) and p2
   default 150 — written, never read in the boss code; purpose unknown.~~ → closed: bosses-3 §10.1–§10.3
   (no reader engine-wide; Warrior/Wizard/Dillo share a Setup template; Chief keeps an emptied switch;
   intent undeterminable)
10. ~~Gate 2940 with p1 ≥ 0 (`record[p1].p4 == 1` condition) — Box-class reader.~~ → closed: bosses-3 §8.5
   (reader in triggers-background §1; the seven level-67 gates read record 0, which nothing writes → never open)
11. ~~Whether level 55 lets the player reach x > 15940 (the only way its arena would lock).~~ → closed: bosses-3 §11
12. ~~Purpose of the Demon/HandleBurn "0x780 → 0x781 → −1" type write (no-op as compiled).~~ → closed: bosses-3 §10.4
   (unobservable no-op, third site in `.UpdateSprites`; intent CLOSED AS UNDETERMINABLE)

## Proposed additions to physics.md §0
| off | type | proposal |
|---|---|---|
| +0x50 | proc | Kill callback (called by `.HandleBurn` when the burn finishes; bosses set it) |
| +0x88 | u8 | cleared by boss Setups in boss mode — ⚑ corrected (review 1c, 2026-10-03) #5: light-overlay gate (`.WrapLightFace` pass skipped), physics §0.1 |
| +0x8c / +0x8d | u8 | burn sound variant (pitched) / extra burn rows per frame (Chief 1) |
| +0x9c | ptr | per-class work block (Demon segment table 0x30, Wizard 7×i16, Xichra 0x374) |
| +0xb0 / +0xb2 | i16 | AI state / sub-state |
| +0xb8 | i32 | draw-effect word (mode<<16 | param) |
| +0xcd | u8 | [grounded/landed] (PlatformBounce sets 1) |
| +0xea | u8 | [clear placement record] — `.UpdateSprites` zeroes the record flag |
| +0xf0 | i32 | bosses: wounded-glow pulse timer |
| +0x14c..+0x168 | | boss per-class fields as listed in §2–§6 (Warrior patrol bounds/home/crate timer, Demon anchor/neck/speed, Chief throws/lane) |
| +0x170 | i32 | bosses: boss flag (= p4); player shots: power (existing) |
| +0x17e | u8 | facing: player 1 = left; **bosses 1 = right** |
| +0x188 / +0x189 / +0x18a | u8 | no record write-back (bosses set `+0x18a`); `+0x188` also blocks the record clear |
| +0x1a2 | i16 | burn-away row counter (<0 delay, 1 start, > face height → Kill) |
| +0x1b2 | u8 | handler skip (all boss handlers return at once) |
| +0x1b4 | u8 | hurt flash uses mode 4 (`0x40000 + 2n`) instead of 3 |
| +0x1b5 | u8 | counted in the level's enemy total |
| +0x1d4..+0x1e0 | ptr | child sprite pointers (crates, minions, fireball, Demon partner) |

## Corrections to the existing bank
1. physics.md §7 table, "several HP values = variants selected by type/params, conditions not
   traced" → for the bosses the condition is **placement p4** (boss flag): Warrior 1200 (p4 = 0) /
   2000; Wizard **1200 (p4 = 0) / 1000 (p4 ≠ 0)**; Chief 1200 / 2000; Demon 1000 / 2000; Xichra 5000
   fixed, set to 9999 at phase 6. Hot rects in the table are Setup-only; the Handles replace them
   every frame (Warrior `SetRect(0x2a,0x3c,0x89,0x88)` ±10 by facing, Chief
   `(0x58,0x73,0xac,0xd2)`, Demon `(0x22,0x14,0x67,0x5e)`, Xichra crash `(0x5c,0x50,0x93,0xa2)`).
   Evidence §1.1, §2–§6.
2. physics.md §0 `+0x17e` "facing left" → true for the player only; every boss uses 1 = right
   (raw 10087f3c..10087f50; §1.7).
3. engine.md §4 boss-arena music "[MED: the counter's meaning (boss alive?) not traced]" →
   `_DAT_1009fd6c` is the current music volume (written by `.SetMusicAIFFVolume`, read by
   `.FadeAIFFMusic`/`.HandleAsyncAIFFMusicFade`); `_DAT_1009fed0` is "no boss alive". Rule: with no
   live boss **in a level with hdr+0x2724 ≠ 0**, fade the level track out, then start track 30
   (main l. 5231: `0x2724 != 0 ∧ fed0 ∧ _DAT_100a5be0 != 0x1e ∧` prefs music `∧ cRam100a5be2`). The
   level-start force-to-30 (main l. 5183: `0x2724 != 0 ∧ fed0`) fires only when no boss Setup
   cleared the flag (idle bosses run Setup at load too) — i.e. on a revisit after the kill (§1.2,
   §1.4). Level 67 (0x2724 = 0) fires neither. ⚑ corrected (review 1b, 2026-10-03) #4.
   ⚑ corrected (review 1c, 2026-10-03) (adjudication B16): this file's reading is confirmed from raw
   — `.SetMusicAIFFVolume` `10049704..10049708 sth r31,0(r3)` through the `fd6c` slot; `fed0` = 0 in
   `.SetupWarriorSprite` `1008796c..10087974` (inside the p4 / HP-2000 branch), = 1 in `.KillWarrior`
   `100887f4..100887fc`, same pattern in the other four pairs [HIGH] (engine.md §4 now carries it).
4. engine.md §6 Victory "death-animation counter > 0x96" → Xichra state 8, `w+0x38 − 60 > 150`
   (frame 211 of the death state), which sets both `DAT_100a5106` and `_DAT_1009ffc4`; reached only
   after the phase-6 crash landing (§6.4). ⚑ corrected (review 1c, 2026-10-03) (adjudication B17):
   confirmed, raw `1008f7c0..1008f898` (explosion every 12 frames while d < 140; d > 0x96 → `stb 1`
   to `100a5106` and `*1009ffc4`) [HIGH] (engine.md §6 now carries it).
5. world-data-format.md §3.2 row 0x2724 → lock/clamp line is `|v ∓ 60|`, camera bounds as §1.3;
   0x272e is applied only after the lock (upgrade MED → HIGH); level 55's 16000 never locks.
6. world-data-format.md §3.4 per-class params → closed for the five boss classes (§1.1); record
   byte +1 has no boss reader.
7. spells-items.md §2.1 "the bosses have none" (statue) → confirmed by raw `bl 0x10043138` scan.
8. INDEX NOT-RESOLVED 6 → boss Handle routines resolved here; NOT-RESOLVED 1 → closed for bosses.

### Wave-2 corrections ⚑ wave 2 (2026-10-04)
| # | file § | old | new | evidence |
|---|---|---|---|---|
| W1 | world-data-format.md §3.2, row 0x2730..0x2736 | "CLUT animation (mode, first index, count?, period 12000)" [MED] | 0x2730 mode 1..7 · 0x2732 **count** of animated entries (indices 255 − count .. 254) · 0x2734 **period** in frames · 0x2736 **amplitude** (12000 in the data); only reader `.AnimateCLUT`, only writer `.HandleXichraSprite`; non-zero only in L50 (1, 48, 180, 12000), L51 (1, 48, 56, 12000), L67 (3, 16, 75, 12000) [HIGH] | bosses-3 §9.1–§9.2; raw 10011850..10011860, 1008e6d0..1008ebcc |
| W2 | sprites-backgrounds-sounds.md §4 | "`.AnimateCLUT` (hdr+0x2730..0x2736) cycles a CLUT range [MED]" | not a cycle: a sine-wave recolour of entries 255 − count..254 of the level+sprite CLUT by a per-mode formula, pushed to the screen with `SetEntries`, rate-gated by the effect level [HIGH] | bosses-3 §9.2; raw 1001180c..10011cd4 |
| W3 | triggers-background.md §2.2 (end) and triggers-background-2.md NR 2 | "A captive of type 90 gets gravity 0x15e [HIGH; identity of type 90 not resolved]" | type 90 = 0x5a = the player shot of id 0x5a (thrown fire/Ziridium seeds from `.HandleItemUse`, the Smite bolt from `.SmiteEnemies`); no placement record has type 90 (all 24 `Mlvl`) [HIGH] — as enemy-shots §2.1 already says | raw `cmpwi r0,0x5a` 10058da8 → `li r0,0x15e; sth r0,0x110(r19)` 10058db0..10058db4; `MTNewSprite(0x5a01, …)` main l. 44265, 47036; bosses-3 §8.3 |
| W4 | triggers-background.md §1 (census paragraph) | 2940 with p1 = 0 "stay shut unless record 0's p4 is 1" | for level 67 settled: record 0 is a 1208 floor fire and every record-p4 writer writes only its own record (Button, Bonus containers, Box, sign), so its seven gates never open [HIGH reading, MED completeness] | bosses-3 §8.5 |
| W5 | coverage.md §2 rows `.AnimateCLUT` / `.UpdateXichraCannons` | "SC, B2" / "cannon values" | add **B3 §9** / **B3 §8.2** | bosses-3 |
