# Ferazel's Wand 1.0.3 — the player sprite: state machine, animation, inputs

Code readings only; nothing behaviour-verified. Date 2026-10-03. Sources: supplementary handler
dump `ghidra/Ferazel_handlers.decompiled.c` ("handler dump l. N"), main dump
`ghidra/Ferazel_pef.decompiled.c` ("main dump l. N"), raw disassembly `ghidra/Ferazel_pef.disasm.txt`
(addresses), `docs/ferazel/tools/const.py`, a Python census over the 24 `Mlvl` resources.
Scope: (a) `.HandlePlayerSprite @ 1004d5fc` (handler dump l. 652–2907) read as a state machine,
with `.HandleKeys @ 10052ac0` (main dump l. 44140–44975), `.HandleItemUse @ 1004d054`,
`.ClearPlayerVars @ 1004aa48`, `.InitPlayerSprite @ 1004a284` and `.SetupPlayerSprite @ 1004aefc`
(handler dump l. 240–440); (b) `.HitPlayerTileSprite @ 10054ca8` (handler dump l. 2909–3152),
`.WallBounce @ 10037a54` (main dump l. 32854–33885) and `.WallBounceBG @ 1003a2e8` (main dump
l. 33888–34556) — part (b) is in `player-states-2.md`. Units as physics.md (1/256 px per frame).
Labels per INDEX. Glider physics belong to the spells reader; only its entry/exit are named here.
⚑ wave 2 (2026-10-04): §9 places the player in the frame (handler/collision order, layers) and closes the
dead globals `PTR_DAT_100a06e8`, `PTR_DAT_100a06bc`, `_DAT_100a067c`.

## 0. Conventions
The player's state lives almost entirely in **globals**, not in sprite fields. They are named here
by their TOC slot exactly as the decompiler prints them (`_DAT_100a0758`, `PTR_DAT_100a0668`): the
slot holds a pointer, the value is the global it points to. `F` = facing global `_DAT_100a5f5a`
(1 = left, 2 = right; `_DAT_100a5f5c` = last frame's F, copied at handler entry l. 734). `s` = the
player sprite. Face sets are pointers to arrays of 0x34-byte face records; "set[i]" = record i.

## 1. Per-frame order of `.HandlePlayerSprite`  [HIGH, handler dump]

| l. | step |
|---|---|
| 733–803 | ridden sprite `PTR_DAT_100a0558 = s+0xdc`; carpet flag `PTR_DAT_100a05a4` (ridden type 0x438/0x439) → player `vx = 0`; looping ambient sound for level modes 2/4 (out of scope) |
| 806–814 | return if `s+0xe9` (kill) or `s+0x1b2` set |
| 815–845 | max speeds `_DAT_100a600a/600c` (ground walk/run) and `_DAT_100a600e/6010` (air walk/run): 0x76c/0xc80; quicksand scaling; Double Speed 0xd82/0x15e0 (physics §4) |
| 846–853 | idle counter `_DAT_100a068c += 1`; `s+0x18c = 0`; `s+0x8a = (climb == 0)` (water-current gate, physics §2); rope latch `_DAT_100a0584 = _DAT_100a0588; _DAT_100a0588 = 0`; `.RopeCollide` unless dying |
| 854–925 | gravity selection (§5.6), jump base J reset / High Jump, Feather Fall clamp |
| 929 | `.StandardSpriteHandles` |
| 930–1003 | Shadow Double sprite 0x1b39 spawn/kill; crunch-capable `s+0xeb = spin ∨ s+0xce`; ~18 countdown timers (§2) |
| 1004–1063 | power-up timers (`.TickTock`) → active/blink flags |
| 1064–1166 | near-surface flag `_DAT_100a05fc` (§2), spirit float (§3.3), liquid damage/heal (physics §5.1) |
| 1172 | `.SeparateFromTiles2` (pre-move contact pass) |
| 1174–1197 | standard hot rect `(0x26,0x22,0x3e,0x55)` (both arms of the `if` identical); `_DAT_100a0738 = s+0xce` (or 3 when riding); catapult request `s+0x14c == 1` → air counter 8, airborne; impact speed `_DAT_100a0660 = vy` |
| 1198–1204 | **`.HandleKeys(s, ridden)`** unless door transit `_DAT_100a06f0 ≠ 0` (then input flags cleared, v = 0) |
| 1205–1222 | quicksand `vy ×= 0.65`; gravity add + clamp 12000 + `vy == 0 → 1` (not while clinging; not while floating `s+0x120 ≠ 0 ∧ s+0x19e ≠ 0`) |
| 1223–1295 | horizontal drag / ground deceleration (§5.7) |
| 1296–1305 | `s+0xce = s+0xcf = 0`; inventory selection repair |
| 1320–1355 | climb pre-move (§3.9): previous-climb latch `PTR_DAT_100a0754 = climb`; vy eased ±100 toward 0 (cap ±4000), vx = ∓0x800 into the wall, **climb cleared** (re-asserted by the tile callback) |
| 1356–1361 | landed/bumped latches cleared; `.ApplySpeedAndSeparateFromTiles` |
| 1362–1389 | surface material 2 (damage) / 3 (ice) (physics §3.3); lost the wall this frame → `vx = vy = 0` |
| 1396 | `.HandleBreathing` (physics §8.8) |
| 1397–1430 | wand/cast phase machine (§3.11.6) |
| 1431–1475 | potion drink timer (§3.11.7) |
| **1476–2453** | **state/animation selection** — first matching branch wins, `goto LAB_10050e6c` (§3) |
| 2453–2459 | pull-up counter reset when not climbing; facing (§6) |
| 2460–2497 | breath/drowning (physics §5.1), bubbles |
| 2498–2603 | teleporter charge `PTR_DAT_100a0700` tint (§3.6); power-up tint `s+0xb8` |
| 2604–2621 | level side push hdr+0x272c (physics §4) |
| 2622–2679 | `.PlayerConstraints`, integer/centre positions, camera look-ahead `_DAT_100a0680` (engine §5), `.PlayerScroll` |
| 2683 | `.SeparateFromTiles2` again (`PTR_DAT_100a0704 = 1`: the only pass that processes water, player-states-2 §10) |
| 2684–2692 | draw offset: x −0x14 while pulling up facing left; x −0x32 while dying/reviving facing left |
| 2694–2704 | **death trigger**: `HP < 1 ∧ dying == 0 ∧ stun == 0` → wind scale `s+0x90 = 0`, died-in-water flag `PTR_DAT_100a0560 = (s+0x11c ∨ s+0x120)`, sound `_DAT_100a03ec`, dying counter = 1 |
| 2705–2749 | liquid screen tint; breath refill when not bubbling |
| 2750–2752 | below the map (`y > h·32 + 100`) → HP = 0 |
| 2753–2770 | stillness counter → `PTR_DAT_100a0674` "standing still" (§3.11.4) |
| 2771–2866 | trail history ring for the Shadow Double (14 × 16 B at `PTR_DAT_100a0520`) |
| 2867–2905 | `.DoubleSpeedTrail`, `.StandardSpriteCleanup`, flash/tint overrides, `.UpdatePentSprites` |

## 2. State globals (written/read by the player code)

| global (TOC slot) | role (evidence) | label |
|---|---|---|
| `_DAT_100a069c` | dying counter (0 alive; 1.. dying; reset to 0x1e on revive) | HIGH |
| `_DAT_100a05e0` | glider active | HIGH |
| `_DAT_100a0574` | spirit-form transition counter (mist potion) | HIGH |
| `_DAT_100a0578` | spirit-form timer (600 frames; −1 after returning) | HIGH |
| `_DAT_100a0570` | boss-grab counter (Chief writes 0x18, Xichra 0x14; −1/frame) | HIGH |
| `_DAT_100a0748` | hurt-stun counter (set 1 by `.HurtPlayer` and two `.HitPlayerSprite` sites; runs 1..10) | HIGH |
| `_DAT_100a05f8` | door walk-in (+1..) / walk-out (−15..0) counter; the walk-out ends 7 frames before input returns (triggers-background-2 §8.2, ⚑ wave 2 corr (2026-10-04) T2 W5) | HIGH |
| `_DAT_100a06f0` | door transit counter (input lock; 1..0x16, then −0x16; the climb back to 0 is **not timed**: +1 only on frames the player overlaps a passage, normally the destination — triggers-background-2 §8.2, ⚑ wave 2 corr (2026-10-04) T2 W5) | HIGH |
| `PTR_DAT_100a0700` / `PTR_DAT_100a070c` / `PTR_DAT_100a0708` | teleporter charge / touching-teleporter-this-frame / fire request | HIGH |
| `_DAT_100a0588` / `_DAT_100a0584` / `_DAT_100a0580` / `_DAT_100a058c` | on rope now / last frame / rope sprite / rope-walk frame (0..15) | HIGH |
| `_DAT_100a0714` | swim counter (0 = not swimming, 1 idle, 3..12 stroke) | HIGH |
| `_DAT_100a05fc` | near-surface flag: set when `0 < s+0x120 ≤ 0x15` and liquid ≠ 5; cleared when grounded, `s+0x120 > 0x2b` or 0 | HIGH |
| `_DAT_100a0758` / `PTR_DAT_100a0754` | climb (wall cling) this frame / last frame | HIGH |
| `PTR_DAT_100a074c` | wall side (1 = wall on the left, 2 = right) | HIGH |
| `_DAT_100a06a0` | pull-up counter (0, 1..20) | HIGH |
| `_DAT_100a5f54` | climb animation phase (1..12, wraps; UP +1, DOWN −1) | HIGH |
| `_DAT_100a0698` | melee/throw counter (1..5, −5..−1) | HIGH |
| `_DAT_100a071c` | crouch depth (0..4) | HIGH |
| `PTR_DAT_100a05e8` / `_DAT_100a05e4` | shield raise (0..5; 7 after a block, decays) / shield hot-rect extension (0..7) | HIGH |
| `_DAT_100a0730` / `_DAT_100a0734` | LEFT / RIGHT walking input this frame (ground only) | HIGH |
| `_DAT_100a072c` | run flag (RUN held when last accelerating on the ground) | HIGH |
| `_DAT_100a0728` | walk cycle running last frame | HIGH |
| `_DAT_100a068c` / `_DAT_100a0688` | idle frames / fidgets played | HIGH |
| `PTR_DAT_100a06c8` / `PTR_DAT_100a06c4` | turn-around countdown (4..0) / draw-mirrored-during-turn flag | HIGH |
| `PTR_DAT_100a04fc` | breathing chest frame (written by `.HandleBreathing`, reset to 3 on stopping) | HIGH |
| `_DAT_100a0718` | **air animation counter** (0 grounded; jump/fall face index source; spring writes 2, catapult 8, `.HitPlayerSprite` 1) — closes the "meaning of `_DAT_100a0718`" part of INDEX NOT-RESOLVED 14 | HIGH |
| `PTR_DAT_100a0668` / `_DAT_100a0664` | spin flag / spin frame (0..7) | HIGH |
| `_DAT_100a05b8` / `_DAT_100a05b4` | launched/tumble flag / tumble frame (0..7) | HIGH |
| `_DAT_100a0764` | jump counter (6 on ground, 3 clinging, 0 airborne — refilled whenever the JUMP arm is not taken, i.e. not (`glider == 0` ∧ JUMP ∧ teleporter charge < 1); ⚑ corrected (review 1b, 2026-10-03) #7, §5.1) | HIGH |
| `_DAT_100a0678` | jump base J (0; ridden sprite's `+0x194`; −0x898 High Jump; springs write 1) | HIGH |
| `PTR_DAT_100a06b8` | spin-refill cooldown (20 frames) | HIGH |
| `_DAT_100a05f4` | swim stroke cooldown (12 frames) | HIGH |
| `PTR_DAT_100a04d8` | post-jump guard (2 frames): no `.FootPressure`, no FG `.WallBounce` | HIGH |
| `PTR_DAT_100a05f0` | no-cling timer: **3** on contact with Background types 0x730..0x733 (raw `100583c8..100583dc`; the decompiler dropped the store, handler dump l. 4291 shows only the load) | HIGH |
| `PTR_DAT_100a060c` | crunch-bounce cooldown (5 frames) | HIGH |
| `_DAT_100a06ec` / `_DAT_100a06d4` / `_DAT_100a06d0` / `_DAT_100a0760` | cast active / wand phase (0..7) / wand-held counter (→18) / USE debounce | HIGH |
| `_DAT_100a0768` | last cast was spell 6 (V Blade) → alternate cast face set (`.CastSpell` sets 1 only in its spell-6 arm, main dump l. 43964) | MED (arm = spell 6 by its 2-shot/±4000 code) |
| `_DAT_100a05b0` / `_DAT_100a5fd6` | potion drink counter (1..40) / potion item id | HIGH |
| `_DAT_100a059c` | carpet-steering lock (5 after `.HurtPlayer`, 2 after a carpet wall hit) | HIGH |
| `_DAT_100a0738` | ground kind last pass (`s+0xce` copy) | HIGH |
| `PTR_DAT_100a04cc` | "stood on a BG one-way top" timer (15) — only read by the glider exit | HIGH |
| `PTR_DAT_100a06bc` / `PTR_DAT_100a06c0` | ⚑ wave 2 (2026-10-04): 3-frame "new hit" counter (set 3 when `+0x116` rises above last frame's copy `06c0`, counts down) — **no reader** / that copy (§9.2) | HIGH |
| `_DAT_100a0684` | ⚑ wave 2 (2026-10-04): save-point hold counter (−1/+1 toward 0 per frame here; +2 per landing in `.HitPlayerSprite`) — save-continue §9.2 | HIGH |

## 3. State selection (handler dump l. 1476–2453; first match wins)

Order: **glider → dying → spirit transition → boss grab → hurt-stun → door walk → rope → swim →
wall cling/pull-up → melee → grounded → airborne** [HIGH]. Each branch sets the face `s+0xc0`
(face writes made earlier by `.HandleKeys` are overwritten [MED: every branch was checked to write
`+0xc0` except the potion/cast overlays, which write on top]). Most branches also do
`if (idle > 0) idle = fidgets` ("idle reset") and stop the spin sound.

### 3.1 Glider (l. 1476–1728)  [entry/exit HIGH; internals → spells reader]
Entry: touching hang-glider pickup 3050 (`.HitPlayerSprite` l. 3628–3644, refused while the
re-pickup cooldown `PTR_DAT_100a05c4` runs): `_DAT_100a05e0 = 1`, launch sequence
`_DAT_100a05d4 = 1`, position = the pickup's, hot rect `(0x37,0x3e,99,0x6e)` (then
`(0x37,0x3e,99,0x61)` every frame). Exit: grounded > 12 frames → `_DAT_100a05d4 = −0x17` landing
sequence; at 0: glider pickup 0xbea respawned at the player, cooldown 180 frames, glider off,
gravity 0x1b8, x += 0x1e px, y += 0x20 px (0x0a px if `PTR_DAT_100a04cc`), hot rect restored.
Death while gliding runs the dying logic inside this branch (no necklace revive on the glider).

### 3.2 Dying / revive (l. 1729–1812; also l. 1661–1727 on the glider)  [HIGH]
Entry: the death trigger (§1 l. 2694). Per frame: idle reset, hit callback `s+0x5c = 0`, Shadow
Double off, vx = 0, climb = 0, invulnerability 0, counter +1; for counter < 30: buoyancy
`s+0x19e += 1 + (counter & 1)`, float line `s+0x1a0 = −22` (the body floats up in liquid — this is
where the "player +0x19e writes" of INDEX NOT-RESOLVED 14 come from), face `1022[counter/3]`, and
after counter 8 the hot rect drifts 2 px/frame toward the facing side; counter ≥ 30 → `1022[9]`.
End at 80 (100 if died in liquid): revive or game over exactly as physics §5.2. Revive runs
`PTR_DAT_100a0594` 1..30 with face `1022[(30 − r)/3]` (the death animation backwards) and sound
`_DAT_100a03e0` pitched 40000 (48000 on the glider).

### 3.3 Spirit form — Mist potion (item 0x19) (l. 1813–1847, 1076–1103)  [HIGH]
Entry: potion counter frame 40 with item 0x19 → `_DAT_100a0574 = 1`. Counter 1..12: v = 0, face
`1038[n>>2]`; at 13: vy = −0x35c, body position saved (`PTR_DAT_100a04d4/04d0`), timer
`_DAT_100a0578 = 600`, counter 0, a **body sprite type 0x45** (the player's own type, Bonus class
callback `_DAT_1009ff38`) spawned with the player's facing. While the timer > 0: ground kind 0,
swim state forced ≥ 1, near-surface flag 1, gravity 0x50, vy ≤ 0x400; tint `s+0xb8 = 0xb0001`
(0xb0005 when `.TickTockLong` flags); **`.HitPlayerTileSprite` returns immediately (no tile
collision at all)**; `.HitPlayerSprite` ignores everything but Bonus-class sprites; HandleKeys
blocks items. Exit A: touching the body after ≥ 240 frames (`timer ≤ 0x167`) → timer −1, counter
0xe, flash 6, player teleported to the body, body killed; counter 14..26 plays
`1038[(27 − n)>>2]` (reverse), then timer 0. Exit B: timer runs out → `G+4 = HP = 0` at the body
position → death.

### 3.4 Boss grab (l. 1848–1889)  [HIGH]
`_DAT_100a0570 > 0` (Chief writes 0x18 when the player is on ground/a top, `+0xce ∨ +0xcd`,
handler dump l. 21769; Xichra 0x14, l. 23244): vx × 0.5 per frame (`dRam100a1a28` = 0.5), idle
reset, climb/spin/crouch off; face `1037[k]` with `j = (n mod 12) >> 1` mapped j 0→0, 1→1, 2→0,
3→2, 4→3, 5→2 (l. 1864–1886). `.HandleKeys` returns at once while it runs; a later damaging hit clears it
(`.HitPlayerSprite` l. 4621).

### 3.5 Hurt-stun (l. 1890–1917)  [HIGH]
Entry: `_DAT_100a0748 = 1` (`.HurtPlayer`; contact hits l. 4048/4509). 10 frames, face `1013` index
0,1,2,3,3,3,3,3,2,1, then 0. Climb/spin/crouch cleared. Effects elsewhere: ground deceleration
300 instead of 800 (l. 1282), LEFT cannot change facing while stunned (RIGHT can — §6), death
waits for the stun to end (l. 2694).

### 3.6 Doors and teleporters (l. 1918–1941; `.HitPlayerSprite` l. 4100–4180, 4304–4392)  [HIGH]
Door types 0xb54/0xb55: needs UP (or a transit already running): `_DAT_100a05f8 = 1` and a gamma
fade; `_DAT_100a06f0` counts to 0x16 (input locked, v = 0); at 0x16 the player is moved by the
offset to the paired record (param 1 match), camera snapped, fade in, walk-out `_DAT_100a05f8 =
−15`, `_DAT_100a06f0 = −0x16`. Faces: walk-in `1033[min(n>>1, 5)]`, walk-out
`1030[min(|n|>>2, 2)]`, one frame per tick until 0. Teleporters 0x424..0x426: each touching frame
sets `PTR_DAT_100a070c`; `PTR_DAT_100a0700` +1/frame while touching, −8/frame otherwise; 21..59 →
sparkle tint `0x50000 + clamp(min(((n−12)>>2)+2, 15) + rand(6) − 3, 0, 15)` (n = |charge|);
60..79 → set to 79; 80 → fire flag; the next contact teleports (mosaic transition) and sets −59, which counts back to 0.
`.HandleKeys` ignores all input while `|charge| > 30` and L/R while `|charge| ≥ 21`.

### 3.7 On a rope (l. 1942–1970)  [HIGH]
`_DAT_100a0588` (set by `.RopeCollide`, physics §8.2). `|vx| ≤ 0x80` → face `1016[0]`, or
`1016[castPhase]` while casting (not after V Blade); else walk `1017[_DAT_100a058c >> 1]`, counter
+1/frame wrapping 0..15 (8 faces, 2 ticks each). Gravity is 0 on the rope (l. 875).

### 3.8 Swimming (l. 1971–2005)  [HIGH]
Entry: fully submerged (`s+0x11c == 1`), not spinning, liquid ≠ 5 → `_DAT_100a0714 = 1` (l. 864–
873); a stroke sets 3 (§5.4). Per frame: gravity 0x50; `k = n − 1`, if `k > 11` → n = 1, k = 0;
face `1027[k>>1]`; melee runs inside (`.HandleItemUse`); if n > 1, n += 1 (stroke = 10 ticks,
faces 1,1,2,2,3,3,4,4,5,5, then idle 0); jump counter refilled to 6 when the stroke cooldown is 0
(held JUMP repeats strokes every 12 frames); below the surface band (`_DAT_100a05fc == 0`) a
rising vy is damped +200/frame and splash 3 fires on stroke frame 5 when `s+0x120 > 0x12`. Exit:
out of liquid (`s+0x11c = s+0x120 = 0`, not spirit) → 0; touching ground also clears it (l. 1266).

### 3.9 Wall cling, climb and pull-up (l. 2006–2073; tile side player-states-2 §10)  [HIGH]
The cling is **re-established every frame**: l. 1320–1355 clears it after forcing vx = −0x800
(wall on the left) / +0x800 into the wall and easing vy toward 0 by 100; `.HitPlayerTileSprite`
re-sets it on contact (the "was clinging" latch replaces the direction key). Losing contact
(e.g. climbing past the top) → v = 0 (l. 1386). In the state: air counter, spin, crouch 0.
- Climbing (pull-up 0): phase `_DAT_100a5f54` wraps 1..12 (0 → 12, 13 → 1); face
  `1012[(phase−1)>>1]`; casting while clinging → vy = 0, phase 1, face `1031[min(castPhase,5)]`.
  Vertical speed: `.HandleKeys` sets vy = −1000 (UP) / +1000 (DOWN) (±0x578 Double Speed); vy = 0
  instead if `*PTR_DAT_100a06e0 == 0` **or** (wand phase > 0 ∧ `_DAT_100a06d0 < 5`) (main dump
  l. 44776–44810). `PTR_DAT_100a06e0` is set 1 at the top of every `.HandleKeys` call (l. 44403) and
  cleared when a cast starts in that call (l. 44437): "no cast began this frame". ⚑ corrected
  (review 1b, 2026-10-03) #6 (the 06e0 term was missing). The same frame's pre-move ease
  makes it **±900 (±1300)**; with no key vy stays 0 (the tile callback zeroes v on every cling
  frame, player-states-2 §10, so the ±100 ease has nothing to act on). No gravity while clinging.
- Pull-up (`_DAT_100a06a0` 1..20, started by the tile callback at a ledge top): face
  `1023[(n−1)>>1]` (120×120 cells), n = 20 → `1023[9]`; after 20: x ± 32 px toward the wall
  (fixed-point +0x2000), y − 22 px (−0x1600), climb/spin off, **crouch depth 2**, grounded
  (`s+0xce = 1`, `_DAT_100a0738 = 1`), face `1011[2]`.
- Wall jump: §5.5.

### 3.10 Melee / throw (`.HandleItemUse`, main dump l. 43547–43650)  [HIGH]
Entry: USE with item 0, 0x12, 0x15 (stab) or 6/0x1a (seeds) selected (`.HandleKeys` l. 44644–
44680; sound `_DAT_100a03e8` / `_DAT_100a0268` vol 0x55; side `PTR_DAT_100a04f4 = (F == 1)`).
Counter 1..5 then 6 → −5 … −1 → 0: face `1021[|n|−1]` standing / `1035[|n|−1]` crouched
(0,1,2,3,4,4,3,2,1,0 — 10 ticks). The held-item sprite hits only at n = 3,4,5 (handler
`PTR_PTR_100a04e8` with hit/tile callbacks); damage 100 (dagger), 300 + crunch (0x12), 200 +
crunch (0x15); seeds spawn shot 0x5a01 at n = 5 (spells-items §4). The held-item sprite's own
Setup/Handle (`.SetupHeldItemSprite` / `.HandleHeldItemSprite`) and the hit frames → held-item-melee.md
(review 1b #11). Runs above the grounded and
airborne branches, and inside the swim branch.

### 3.11 Grounded (`_DAT_100a0738 ∨ s+0xce`; l. 2078–2347)  [HIGH]
Common: air counter 0, spin 0, spin sound stopped.
1. **Crouch** (`_DAT_100a071c ≠ 0`, DOWN held on ground, depth +1/frame to 4, −1/frame when
   released): face `1011[depth−1]`; with a shield raised (`PTR_DAT_100a05e8 ≥ 1`):
   `_DAT_100a05e4` +1 to 7, face `1039[min(raise−1,5)]`, or `1039[min(raise+2,8)]` with the
   Magical Shield (0xf) and raise ≥ 4; raise > 5 decays 1/frame; casting at full crouch → face
   `1034[castPhase−2]`. Crouch hot rect: §7.
2. Not crouching: shield extension 0.
3. **Walk / run** (L/R ground flag): first frame sets phase `s+0x46 = 0xc`; `PTR_DAT_100a0670 = 0`.
   Run flag → `s+0x46 += 2`, wrap past 0x17 → face `1024[s+0x46 >> 1]` (12 faces, 1 tick each),
   footstep at phase 6 and 0x10 (8 and 0x10 with Double Speed), turn countdown 0. Walk →
   `s+0x46 += 2`, wrap past 0x1f; only if `|vx| > 0x5db` (raw `1005080c cmpwi r0,0x5dc` / `bge`, i.e.
   `|vx| ≥ 0x5dc`; handler dump l. 2178) or facing unchanged, and no turn running [HIGH; ⚑ corrected
   (review 1b, 2026-10-03) #8: address added — the compare sits past the reviewer's 1004f000–10050300
   window]:
   face `1020[s+0x46 >> 1]` (16 faces), footsteps at 6 and 0x16 (8 and 0x20 with Double Speed —
   0x20 never occurs, so one step per cycle). Footstep: index `PTR_DAT_100a0710 += 1 + rand(2)`
   mod 4 into the 4-sound table `_DAT_100a025c` (vol 0x78 run, 0x55 walk); in liquid one 3D
   splash `_DAT_100a0378` vol 0x2a instead. Otherwise falls through to 4.
4. **Stand** (`_DAT_100a0728 = 0`; on entry chest frame 3): with idle < 150:
   - no turn running: F unchanged → face `1003[chestFrame]` (breathing, physics §8.8); F changed
     → **turn**: countdown 4, face `1030[0]`, mirrored flag 1; then countdown 3 → `1030[1]`
     mirrored, 2 → `1030[2]` mirrored, 1 → `1030[1]`, 0 → `1030[0]` (5 ticks; the first three are
     drawn with the old facing).
   - potion overlay (`_DAT_100a05b0 > 0`): n < 20 → `1036[min((n−1)>>1,5)]`, else
     `1036[clamp((39−n)>>1,0,5)]`.
   - wand overlay (phase ≥ 1): turn cancelled, idle reset, face `1014[phase−1]` (`1032[…]` after
     V Blade); phase 0 and standing on an uphill slope (F = 1 on kind 0xc/0x2c/0x2d, F = 2 on
     0xf/0x2e/0x2f) → single face `1004`.
   - idle ≥ 150 → **fidget** `m = idle − 150`: fidgets < 3 → `1029`: m 0..7 → `m/3`, 8..99 → 2,
     100..139 → `min(m−92,15)/3` (2..5), 140..155 → `(15 − (m−140))/3` (5..0), > 155 → idle 0,
     fidgets + 1; fidgets ≥ 3 → `1028[(m mod 20)>>1]` (10 faces, 2 ticks) until m > 240 → idle
     = −rand(60), fidgets 0. Any input (`.HandleKeys` L/R/USE/DOWN) zeroes idle and fidgets.
5. **Cast** (§3.11.6) and **potion** (§3.11.7) run in their own counters regardless of state;
   their faces appear only through the overlays above (and rope/crouch/cling variants).
6. Wand phase machine (l. 1397–1430): USE with a spell and magic > 0 → `_DAT_100a06ec = 1`,
   phase 3 (or re-cast if already 3). Active: phase +1/frame, `.CastSpell` at phase 4 if magic
   > 0, after 6 → inactive, phase 3. At phase 3 a hold counter runs to 18, then phase 2 → 1 → 0
   (one tick each). Fastest re-cast: 4 ticks (USE must be released between casts,
   `_DAT_100a0760`). A second entry flag `PTR_DAT_100a06e8` (+1 phase up to 3, then active) has
   no writer in either dump ~~[NOT RESOLVED]~~ (⚑ wave 2 (2026-10-04): never non-zero, the branch is dead — §9.2,
   player-states-2 §15).
7. Potion counter (l. 1431–1475): +1/frame; at 20: item 5 → HP = breath = max; item 4 → magic =
   max (flash 6); item 0x19 → just removed; at 40 item 0x19 → spirit (§3.3); > 40 → 0.

### 3.12 Airborne (l. 2349–2452)  [HIGH]
Air counter `c = _DAT_100a0718` update: c < 10: rising (`vy ≤ 0`) and not spinning → c + 1; else
c < 3 → c = 18; else c + 2. c ≥ 10: c + 1 only while falling, not spinning, not in wind
(`s+0x92`). In wind and c > 14 → c − 1. Spin → c = 26. Feather Fall or launched → c ≤ 15.
Bucket b of c: <0 → 9; 0–1 → 0; 2–3 → 1; 4–5 → 2; 6–7 → 3; 8–15 → 4; 16–23 → 5; 24–29 → 6;
30–35 → 7; 36–41 → 8; ≥ 42 → 9. Faces: spinning → `1025[spinFrame]`, spin frame +1/tick mod 8,
launched flag cleared; launched (not spinning) → `1015[tumbleFrame]` (+1/tick mod 8) and facing
is not refreshed this frame; else `1010[b]`. So a jump shows faces 0..4 rising, and the first
falling frame jumps to 5 (if it rose < 3 frames) or advances 2/frame to the falling faces.

### 3.13 Other carried states  [HIGH unless noted]
- **Riding**: `PTR_DAT_100a0558 = s+0xdc`; ground kind forced 3; magic carpet (0x438/0x439)
  steering in `.HandleKeys` (physics §4), player vx 0, carpet snapped under the player on a FG wall
  contact (`.HitPlayerTileSprite` l. 3055–3070).
- **Catapult launch**: platform sets `s+0x14c = 1` → air counter 8, airborne (l. 1191–1196).
- **Cannoned**: `.TurnIntoCannoned @ 10058594` swaps the sprite's handler/hit/tile callbacks into
  `+0x1ec/+0x1f0/+0x1f4`, installs `.HandleCannonedSprite`, timer `+0x130 = 15`, cannon `+0x1e4`;
  for the player sets the launched flag; the player fires early with JUMP when the cannon's record
  param 1 < 0. Launch geometry belongs to the cannon reader ~~[NOT RESOLVED here]~~ (⚑ wave 2 (2026-10-04): read in
  triggers-background §2 "Firing").
- **Statue / carrying / pushing**: no player statue state exists (`.TurnIntoStatue` has no
  player caller); no carry state; pushing is `.RectBounce` mass transfer (physics §8.1), no
  player face or flag. "Running" (1024) was formerly unlabelled.

## 4. Inputs consumed (`.HandleKeys`; action numbers engine §7.1)  [HIGH]
Early returns: `|teleporter charge| > 30`; potion drinking (also clears wand phase and crouch);
boss grab; pull-up running; dying. Debug keys first (engine §7.3).

| state | 0 L / 1 R | 2 U | 3 D | 4 RUN | 5 JUMP | 6 USE |
|---|---|---|---|---|---|---|
| carpet | carpet vx ±0x140 (cap ±0xc80), sets F | carpet vy −0x100 (≥ −4000) | +0x100 | — | normal | normal |
| ground | `.AccelerateBasedOnSlope` (§5.7), walk flags, F, `.FootPressure`, exertion +1/+3 | — | crouch (F from L/R unless a shield is held; shield raise by pressing away from F) | run accel/max | jump (§5) | item/spell |
| air (no rope, no swim) | L: −0x14a if `vx > −airMax`; R: §5.7 | — | spin while jump counter 1..5 | — | sustain / spin refill | item/spell |
| rope | ±1000, cap ±0x960 (+R extra §5.7) | — | drop through (RopeCollide) | — | sustain | spell (rope cast face) |
| swim | ±0xd2 to ±0x76c (+R extra) | with JUMP below the surface band: leap (§5.4) | spin | — | stroke | item/spell |
| cling | **ignored** (block skipped while climbing) | climb up (0 if a cast began this frame or phase > 0 ∧ held < 5, §3.9 ⚑ #6) | climb down (same gate) | — | wall jump | spell only (melee/potions need `climb == 0 ∧ rope == 0`) |
| glider | vx ±0x96 to ±0xc80, turn request ±12 | pitch −1/frame to −5 | pitch +1 to +5 (relaxes to 0) | — | ignored | spell |
Every L/R/USE/DOWN press zeroes idle and fidgets. **USE held with an item (not a spell)
selected, while not clinging/on a rope/shielding, replaces the whole L/R (and glider) block for
as long as it is held** (main dump l. 44446–44458 vs the item `switch` at l. 44644; the item itself fires once per press,
debounce `_DAT_100a075c`) [HIGH].

## 5. Jump, spin, swim, wall jump, drag  [HIGH]
1. **Counter refill** (main dump l. 44962–44973): the `else` of the JUMP arm's condition
   `*_DAT_100a05e0 == 0` (not gliding) ∧ JUMP pressed ∧ teleporter charge `< 1` (l. 44818–44819): on
   ground → 6, clinging → 3, airborne → 0. ⚑ corrected (review 1b, 2026-10-03) #7 — not "only while
   JUMP is up": the refill also runs with JUMP held while gliding or with teleporter charge ≥ 1. In
   ordinary play (no glider, no charge) it is still JUMP-up only, so: **no coyote time** (walking off
   a ledge with JUMP up zeroes the counter next frame), **no jump buffer and no auto-repeat** (holding
   JUMP through a landing does not jump). `.RopeCollide` writes 6 while on the same rope, 0 on a fresh grab.
2. **Initial jump** (ground, not swimming, counter 6, l. 44876–44910): if `s+0x116 > 60`
   (Invincibility sphere) → launched tumble; rope flags 0; exertion +8; sound `_DAT_100a03f8` vol
   0x9c; post-jump guard 2; vy = 0; face `1010[0]` and airborne if the air counter is 0; ridden →
   J = ridden `+0x194` (springboard sound when ridden mode 0x58c and J ≠ 0); `.AccelerateSprite(0,
   J − 0xc80 − ((|vx| + 0x4e2) >> 3), cap 8000)`; counter −1.
3. **Sustain**: each later frame with JUMP held and counter 1..5 (airborne, not swimming): vy = 0
   then the same impulse; counter −1. Gravity is added after `.HandleKeys` in the same frame, so a
   held frame nets impulse + gravity. Max 6 frames of constant rise; releasing ends it.
4. **Spin** (l. 44761–44774, 44838–44860): DOWN while counter 1..5 (no JUMP needed) → spin, swim
   0, crouch 0, spin sound `_DAT_100a03cc` vol 0xba. DOWN + JUMP with counter 1..6 → the same, and
   if not near the surface and the cooldown is 0: **counter refilled to 6**, cooldown 20 — a
   second sustain window (spin = jump extension once per 20 frames). On the ground DOWN + JUMP is
   a spin jump. UP + JUMP while submerged below the surface band → swim state 0, air counter 1,
   refill as above: a land-style leap out of the swim state. Spin effects: crunch-capable,
   face 1025, `CrunchTile` bounce (player-states-2 §10); its gravity is water-only (Corrections).
5. **Wall jump** (l. 44818–44836): JUMP with climb set and counter > 0 → sound, guard 2, climb 0,
   vy = 0 (−0x8cb when the counter is 3), vx = +0x8ca (wall on the left) / −0x8ca. The counter is
   still 3, so the **sustain of item 3 runs in the same call** and overwrites vy with
   `J − 0xc80 − ((0x8ca + 0x4e2) >> 3)` = −3200 − (3500 >> 3 = 437) = **−3637** (J = 0; 0x4e2 = 1250);
   up to 3 sustained frames. ⚑ corrected (review 1b, 2026-10-03) #3 (was −3610, an arithmetic slip;
   formula and same-call mechanism verified, main dump l. 44869–44880).
6. **Swim stroke** (counter 6 while swimming or near the surface, l. 44913–44946): impulse
   `J − 0x640 − ((|vx| + 200) >> 3)`, halved when already swimming below the surface band; swim
   counter 3, gravity 0x50, stroke cooldown 12, exertion +8, sound `_DAT_100a02e8` vol 0x9c (not
   in spirit form), cap 2000 (×0.8 in water by `.AccelerateSprite`). Held: counter 1..5 repeats
   the impulse quartered (below the surface band) or whole.
7. **Horizontal** (raw disasm `10053580..100539c0`): ground L/R call `.AccelerateBasedOnSlope`
   with 0x14f (walk, from rest/turning, not ice) or 0x104, run 500 / 300, cap walk/run max; LEFT
   on ice-slope press `y += 2|vx| + 0x200` when `s+0x112 > 0`. **RIGHT then always adds +0x14a when
   `vx < airMax`** (`_DAT_100a600e`, or `6010` with the run flag) — on the ground, rope and in
   water too; LEFT adds −0x14a only in plain air. Airborne drag 100/frame (600 on a rope, 20 on
   the glider) is applied **every** airborne frame, input or not (l. 1223–1260); ground
   deceleration (800 / 300 stunned / ice value, physics §3.3) only on the side with no input
   (l. 1262–1294).

## 6. Facing  [HIGH]
`s+0x17e` (1 = drawn facing left) = `(F ≠ 2)` XOR the turn mirrored flag, refreshed each frame
except while tumbling (l. 2457). F is written by: L (`vx < 0` and not stunned) / R (`vx > 0`,
**no stun check**) on the ground or in air (main dump l. 44524/44581; raw `10053788`, `100539ac`);
crouch L/R without a shield; carpet L/R; wall cling (wall side); glider turn. Initial F: `G+0x16`
(0 → right) — `G+0x16` is written from level header byte `0x26c8` by `.NewGame`/`.ContinueGame`
(main dump l. 5786, 6885; raw `.NewGame` `1000b3d8 lbz r0,0x26c8(r3)` → `1000b3dc sth r0,0x16(r21)`,
`.ContinueGame` `1000d684 lbz r0,0x26c8(r3)` → `1000d688 sth r0,0x16(r17)`, r3 = the dereferenced
level-header handle) and from the facing at a save point (`.HitPlayerSprite` l. 4199); read by
`.SetupPlayerSprite` at raw `1004b2b0 lha r0,0x16(r29)` → `+0x17e = 1` if non-zero (1004b2bc–1004b2c0)
else 0 (1004b2d0): the level's **start facing** (closes the meaning half of INDEX NOT-RESOLVED 2)
[HIGH; ⚑ corrected (review 1b, 2026-10-03) #13: 0x26c8 read spot-checked in raw disasm].

## 7. Face sets (`.InitPlayerSprite`, main dump l. 42149–42258) and hot rects

| PICT | faces (w×h) | global | state / index | cadence |
|---|---|---|---|---|
| 1003 | 4 (100×120) | `_DAT_100a07ec` | stand, breathing chest frame | breathing period (physics §8.8) |
| 1004 | 1 | `_DAT_100a07e8` | stand facing uphill on a slope | — |
| 1010 | 10 | `_DAT_100a07e4` | jump/fall bucket | §3.12 |
| 1011 | 4 | `_DAT_100a07e0` | crouch depth−1 | 1/tick |
| 1012 | 6 | `_DAT_100a07dc` | climb phase | per UP/DOWN tick |
| 1013 | 4 | `_DAT_100a07d8` | hurt-stun | 10 ticks |
| 1014 | 6 | `_DAT_100a07d4` | cast standing | wand phase |
| 1015 | 8 | `_DAT_100a079c` | launched tumble (also `.HandleCannonedSprite`) | 1/tick |
| 1016 | 7 | `_DAT_100a0798` | rope stand / rope cast | — |
| 1017 | 8 | `_DAT_100a0794` | rope walk | 2 ticks |
| 1020 | 16 | `_DAT_100a07d0` | walk | 1/tick |
| 1021 | 5 | `_DAT_100a07cc` | stab standing (`.HandleItemUse`) | 1/tick |
| 1022 | 10 (150×120) | `_DAT_100a07c8` | dying / revive | 3 ticks |
| 1023 | 10 (120×120) | `_DAT_100a07c4` | pull-up | 2 ticks |
| 1024 | 12 | `_DAT_100a07c0` | run | 1/tick |
| 1025 | 8 | `_DAT_100a07bc` | spin | 1/tick |
| 1027 | 6 | `_DAT_100a07b8` | swim | 2 ticks |
| 1028 | 10 | `_DAT_100a07b4` | fidget 2 (after 3 fidgets) | 2 ticks |
| 1029 | 6 | `_DAT_100a07b0` | fidget 1 | §3.11.4 |
| 1030 | 3 | `_DAT_100a07ac` | turn-around; door walk-out | 1/tick |
| 1031 | 6 | `_DAT_100a07a8` | cast while clinging | wand phase |
| 1032 | 6 | `_DAT_100a07a4` | cast after V Blade | wand phase |
| 1033 | 6 | `_DAT_100a07a0` | door walk-in | 2 ticks |
| 1034 | 5 | `_DAT_100a0790` | cast crouched | wand phase |
| 1035 | 5 | `_DAT_100a078c` | stab crouched | 1/tick |
| 1036 | 6 | `_DAT_100a0788` | potion drink | 2 ticks |
| 1037 | 4 | `_DAT_100a0784` | boss grab | §3.4 |
| 1038 | 4 | `_DAT_100a0780` | spirit transition (also `.SetupBonusSprite`) | 4 ticks |
| 1039 | 9 | `_DAT_100a077c` | shield raise | 1/tick |
| 1050–1053 | 6/4/6/4 (160×160, cached) | `_DAT_100a0778/0774/0770/076c` | glider | → spells reader |
| 750..776 | 27 single faces | `_DAT_100a5f68` array | held-item faces (index = item id) | — |
1026 (0x402, 400×152) is not loaded by `.InitPlayerSprite` and no `0x402` literal occurs in
either dump ~~[NOT RESOLVED: unused or loaded by computed id]~~ — **unused**: no `0x402` immediate and no
computed site can yield it; PICT 1054 is also unused (rendering-omnipx-titles §5) [HIGH for the search]
⚑ wave 2 corr (2026-10-04) RO #11. Labels:
PICT/global/use [HIGH]; state names [MED, from the selecting code, the PICTs are unnamed].

Hot rects (`SetRect(s+0x34, l,t,r,b)`): standard `(0x26,0x22,0x3e,0x55)` reset every frame
(`.HandleKeys` l. 44327/44330, handler l. 1174–1178); **crouch on ground** `(0x26,0x37,0x3e+e,0x55)`
facing right / `(0x26−e,0x37,0x3e,0x55)` facing left, e = shield extension 0..7 (main dump
l. 44754/44757) — 24×30 px, the shield adds up to 7 px forward; glider `(0x37,0x3e,99,0x61)`;
dying: drifts 2 px/frame after frame 8 [HIGH].

## 8. `.SetupPlayerSprite @ 1004aefc` initial state (handler dump l. 240–440)  [HIGH]
`.InitSprite`, `.ClearPlayerVars` (zeroes every global of §2; climb phase 1, bubble timer 0x28,
`DAT_100a5f58 = 1`, breath phase 3); melee item `_DAT_100a5fd8 = −1`; ridden 0; camera look-ahead
0; dying 0; global hot-rect copy `PTR_DAT_100a0530` and `s+0x34` = `(0x26,0x22,0x3e,0x55)`; type
`s+4 = 0x45`; v = 0; layer `s+0x80 = 10`; HP = `G+4`; gravity 0x1b8; handler `PTR_PTR_100a052c`,
**hit callback `s+0x5c = 0`**, tile callback `PTR_PTR_100a0528`; player x/y copied to
`_DAT_1009fd44/1009fe68` and `_DAT_1009fd40/1009fe64`; fixed-point x/y; face 0; held-item sprite
type 100 at layer 0x14 (`_DAT_100a065c`; → held-item-melee.md); exertion 0; `s+0x13c = 0x100`; `s+0xe4 = 1`; wind scale
`s+0x90 = 0x100`; Shadow-Double trail ring: 14 × 16 B `{−1, −1, 0, 0}`; five type-1 sprites at
layer 9 into `PTR_DAT_100a051c` (16-B records `{sprite, 0, −1, −1, 0}`) [MED: Double-Speed trail
by `.SetupTrailSprite` handler] → HIGH: slot 0x100a0518 → `1004b3b4` (⚑ corrected (deepening 2026-10-03, held-item-melee.md corr. 5; held-item-melee §3)); eight Pentashield slots at `PTR_DAT_100a0514` (0x14 B: angle
`0x4800·i` = 72°·i, radius 0x30, 0xa00, active 0) and count 0; idle/fidgets/wand 0; died-in-water
0; facing from `G+0x16` (§6, also sets `_DAT_100a5f5c`); door/revive/debug-kill/glider 0.

## 9. Wave 2 (2026-10-04): the player in the frame; dead globals  [HIGH]

### 9.1 Where the player runs in a frame
Order of one frame and the active list: platforms-ropes-radial-2 §8. For the player:
- Layer 10 (`1004af88 li r5,0xa` → `1004afac`). Before it in every frame: the five trail sprites and the
  Shadow Double (layer 9 = player layer − 1; their Setups do not change `+0x80`), platforms (−1), Box
  class (2). After it: the held item (0x14, held-item-melee §4.1).
- The Shadow Double's handler therefore reads the pose ring **before** the player appends this
  frame's pose (handler l. 2771–2866): its newest readable entry is last frame's. A Double created in
  frame n (inside the player's handler, layer 9 = before the player) is first handled in n+1.
- The player has **no hit callback** (`s+0x5c = 0`, §8): `.HitPlayerSprite` runs only from
  `.MTCollideSpecialSprite`, after every handler of the frame, once per touching sprite, in list order
  (raw `10032ac8..10032eec`; the `+0x34` rect plus position, not `.CalcHotRect`). Whatever it writes
  (stun, spring velocity, counters, save point) is seen by the player's handler in the **next** frame.
  The touching sprite's own hit callback with the player as argument runs twice per frame (once in
  `.MTCollideSprites` as the outer sprite, once here) unless a see-saw segment is among the contacts.
- The player's tile callback runs inside its own handler (the two `.SeparateFromTiles2` passes, §1).

### 9.2 Globals with no reader
- `PTR_DAT_100a06e8` (byte 0x102bb7dc): its three TOC loads store 0 (`1004ab50..1004ab5c`,
  `1004ed18..1004ed1c`) or read it (`1004ecf0`); the neighbouring byte slots `0x100a06dc` / `0x100a06e0`
  are accessed only with byte operations — never non-zero, so the l. 1399–1402 branch is dead.
- `PTR_DAT_100a06bc` (i16 0x102bb7ca): set to 3 at `1004ddb4..1004ddbc` when `+0x116 > *PTR_DAT_100a06c0`
  and `*_DAT_100a06f0 == 0`, decremented at `1004ddc0..1004ddd8`, zeroed at `1004abac`; no other load and
  no aliasing slot — write-only. `PTR_DAT_100a06c0` = `+0x116` copied at `1004e1bc..1004e1c8`.
- `_DAT_100a067c`: written 1 by `.HitPlayerSprite` on a see-saw segment touch and 0 every frame here
  (`1004e57c..1004e588`) — write-only (platforms-ropes-radial-2 §10.2).

## NOT RESOLVED
1. ~~`PICT 1026` (0x402, 400×152): no loader found (§7) — not this lane's (wave 2: lane L4).~~ → closed:
   unused (§7; rendering-omnipx-titles §5) ⚑ wave 2 corr (2026-10-04) RO #11

## Proposed additions to physics.md §0
- `+0x5c` (player) = 0 always: the player's sprite-contact logic is `.HitPlayerSprite`, called only by
  `.MTCollideSpecialSprite` (platforms-ropes-radial-2 §8.3).

## Corrections to the existing bank
| # | file § | old | new | evidence |
|---|---|---|---|---|
| W1 | enemy-shots-and-damage / spells-detail notes on "same-frame handling of new shots" | open | rule: a sprite created inside a handler is handled in the same frame only if its insertion point (layer, then insertion order) lies after the creator's successor as saved before the call; a Double (layer 9, created by the layer-10 player) never is | §9.1; platforms-ropes-radial-2 §8.2 (raw `100325b8..100325d8`, `10032f1c..10032fd0`) ⚑ corrected (review 2g, 2026-10-04) #7: duplicate sixth cell removed |
