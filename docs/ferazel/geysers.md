# Ferazel's Wand 1.0.3 — geysers (Box types 1440..1449) and their column segments

Code readings only; nothing behaviour-verified. Date 2026-10-03.
Sources: `ghidra/Ferazel_handlers.decompiled.c` ("handler dump l. N"), `ghidra/Ferazel_pef.decompiled.c`
("main dump l. N"), raw disassembly `ghidra/Ferazel_pef.disasm.txt` (addresses `1006xxxx`), constants
via `tools/const.py`, TOC users via `tools/tocrefs.py`, placement census = Python over all 24 `Mlvl`
(record layout world-data-format §3.4), `snd ` names from `Ferazel's Wand Sounds.rsrc`.
Scope: the 1440..1449 arms of `.SetupBoxSprite @ 1006b43c` (handler l. 11624–11700) and
`.HandleBoxSprite @ 1006d878` (handler l. 12597–12701, raw 1006df20–1006e27c);
`.HandleGeyserColumn @ 1006cf7c` (main l. 47485–47676, raw 1006cf7c–1006d564); the column pieces
0x5a9 (head, Box class) and 0x5a0 (segments, Effect class, `.HandleGeyserSegSprite @ 10060cd8`);
`.KillBox` cleanup; face caches in `.InitBoxSprite`; particles; sound; geyser-vs-box contacts.
Damage to the player is banked in enemy-shots-and-damage.md §3.3 (head 0x5a9) and §3.4 (segments
0x5a0) — cited, not repeated. Units: px; heights and velocities in 1/256 px (per frame).

## 1. Census and type map  [HIGH]
`.GenerateSprite` routes 0x5a0..0x5a9 to Box, idle-spawned (activated near the camera;
`tools/gensprite_map.py`, main l. 1728). Setup renames the type and stores a liquid kind:

| placed type | runtime type | kind `+0x14c` | children | shipped placements |
|---|---|---|---|---|
| 1440 (0x5a0) | 0x5a0 | 0 water | — | 2 (level 10 "Unemployed In Greenland") |
| 1441 | 0x5a0 | 1 acid | — | 0 |
| 1442 | 0x5a0 | 2 lava | — | 25 (level 50: 9, level 51: 16) |
| 1443, 1444 | 0x5a0 | 3, 4 | — | 0 |
| 1445..~~1449~~**1448** | 0x5a5 (triple) | type − 1445 (~~0..4~~ **0..3**) | two Box 0x5a0 at x+72, x+144 | 0 |
| 1449 (0x5a9) as runtime | head piece, created by the column | copied each frame | — | never placed |

⚑ corrected (review 1c, 2026-10-03) #11: placed 1449 = 0x5a9 takes the **head** arm, which `.SetupBoxSprite` tests first (handler l. 11624 `iVar16 == 0x5a9`), so the triples are 1445..1448 only (kinds 0..3), as the last row already says. All unplaced [HIGH].

Kind names: 0 water / 1 acid / 2 lava per physics.md §5.1 (1 acid MED there). Levels 52 and 55 have
no geysers. Record byte +1 is 0 in all 27 placements and no geyser code reads it. Kinds 3/4 are
unplaced; for them the base face index (below) overruns the 12-face cache [HIGH as read; LOW intent].

## 2. Setup (`.SetupBoxSprite` arm, handler l. 11633–11700, raw 1006bbdc–1006bde8)  [HIGH]
After the common Box setup (handler handle `.HandleBoxSprite`, hit `.HitBoxSprite`, HP 600):
- Marks face caches 1440/1441/1442 needed (`cache+1 = 1`, MED name). Hot rect
  `SetRect(0, 2, 24, 24)` (left, top, right, bottom); no tile callback; one-way `+0x185 = 1`;
  gravity 0; layer `+0x80 = 0`; `+0x189 = 1` (no record write-back, world-data §3.4).
- `+0x150 = y`. **p1** → target height `+0x154 = p1 << 8`, 0 → **0x6400 (100 px)** (`li r0,0x6400`
  1006bc5c); copied to `+0xf4` and `+0x16c` (base target). **p2** → on-frames `+0x158`, 0 → **60**
  (1006bc98). **p3** → off-frames `+0x15c`, 0 → **60** (1006bcc8). **p4** → `+0xa6` (1006bcf4) — see §3:
  overwritten before any read, **p4 has no effect**.
- Height `+0x164 = 0`, velocity `+0x168 = 0`; idle-activity pads `+0x1cc = p1 px` (above),
  `+0x1c8 = +0x1ca = 64` (left/right) — read by `.HandleIdleSprites` (main l. 4300–4311) to build
  the on-screen test rect [MED pad semantics]. Base anim `+0x46 = FastRand(4)`.
- `+0x9c = AllocateGameMem(0x44)`: 16 segment pointers + head pointer at `+0x40`.
- Types < 0x5a5: kind = type − 0x5a0, `+0x170 = 0`, type := 0x5a0. Types ≥ 0x5a5: kind = type −
  0x5a5, `+0x170 = 1`, type := 0x5a5, `+0xac = −1`, and two children `MTNewSprite(0x5a0, x+0x48 /
  x+0x90, y, layer, rec index +0x48, SetupBoxSprite)` → `+0x1d4`/`+0x1d8`, each `+0x188 = 1`, the
  second `+0xac = −1`. The children re-enter this arm as type 0x5a0, so they read the **same record
  params** (`.MTNewSprite` stores arg 5 in `+0x48` before calling Setup, main l. 30596–30690) but get **kind 0**
  whatever the parent's kind [HIGH as read; intent LOW — moot, no triple is placed].
`FastRand(n) = (n · (seed & 0xffff)) >> 16` ∈ 0..n−1 (`.FastRand`, main l. 31106–31140) [HIGH].

## 3. Eruption cycle (`.HandleBoxSprite` arm, raw 1006df20–1006e0c4)  [HIGH]
Runs for runtime types 0x5a0 and 0x5a5 (Box base only; segments have their own empty handler).
- Base face: `+0x46` 0..7 wraps; face = cache 1440 entry `(+0x46 >> 1) + 4·kind` (4 faces × 2
  frames per kind; PICT 1440 = 12 faces 24×16, 4 per row, `.InitBoxSprite` main l. 47423).
- Phase: `t = C mod (on + off + 1)` with `C = *_DAT_1009fd98` (unsigned `divwu`, 1006df3c), the
  **level frame counter**: zeroed at `.GameLoop` entry (main l. 5109), +1 at the top of every loop
  iteration (l. 5201). `t` is written to `+0xa6` (1006df90) — this is what discards p4. Every geyser
  with equal p2/p3 is in lock-step, phase set by time since level start.
- **Rising** (`t < on`): `v = trunc(0.12 · (+0x154 − h))` (double 0x100a1ae0 = 0.12, 1006dfe8),
  `v = min(v, 0x600)` (1006e010), `h += v`, `+0xf4 = +0x154`. No lower clamp.
- **Falling** (`t ≥ on`, i.e. off + 1 frames): `v = trunc(0.12 · (h − +0xf4))`, then `v > −0x100 →
  −0x100` (1006e080) and `v < −0x700 → −0x700` (1006e094); `h += v`. Slow (1 px/frame) near the top,
  up to 7 px/frame once ≥ ~42 px below it.
- `h < 0 → 0`. At `t == 0` with `+0xac ≠ −1` the arm calls `CalcStereoVolume(buf, 0x2a, centre)`
  and never uses `buf` — **no sound is played** (§6).
- Then (0x5a5 only, rising phase) the triple's re-targeting (§5), then `.HandleGeyserColumn`.

Worked cycles (Python transcription of the above; `trunc` = `fctiwz`) [HIGH arithmetic]:

| p1/p2/p3 (placements) | period | top reached | ≥ 50 % at frame | falls to 0 after |
|---|---|---|---|---|
| default 100/60/60 (19 lava, 2 water) | 121 | 99.9 px | 9 | 32 off-frames |
| 120/90/45 (L50 rec 212) | 136 | 120.0 px | 10 | 35 |
| 180/40/60 (L51 rec 63, 64) | 101 | 175.2 px | 15 | 39 |
| 100/20/60 (L51 rec 134, 136) | 81 | 88.7 px | 9 | 21 |
| 190/60/40 (L51 rec 158) | 101 | 189.7 px | 13 | **never** — bottoms out at ~21 px |

⚑ corrected (review 1c, 2026-10-03) #12: the "falls to 0 after" column mixes counting conventions —
review 1c's transcription of the same rules, counting from the first falling call (t = on) as frame 1,
gives **38** (180/40/60) and **20** (100/20/60) while matching 32 / 35 / never on the other rows. Use
"first falling call = frame 1" and treat those two cells as ±1 [MED for the two cells].

The rise is capped at 6 px/frame until half height, then closes 12 %/frame; it stalls within
8/256 px of the target. The 190/60/40 column never collapses, so it never goes idle (§4).

## 4. `.HandleGeyserColumn` (main l. 47485–47676)  [HIGH]
`h_px = h >> 8`. **h < 1**: kill head and every segment (`+0xe9 = 1`, face 0, slot 0), `+0x1c6 = 1`
(base may go idle off-screen). Otherwise `+0x1c6 = 0` and:
1. `n = (h_px + 31) >> 5` segments (ceil(h_px/32); slots cap at 16 → ≤ 512 px drawn).
2. **Head** (slot `+0x40`): if absent, `MTNewSprite(0x5a9, x − 12, y, layer 11, −1, SetupBoxSprite)`,
   face 0 this frame; else head `+0x46` 0..11 wraps (1006d018), face = cache 1441 entry `+0x46 >> 1`
   (PICT 1441: 6 faces 48×32). Head **solid on all sides** (`+0x185 = 0`) when `h ≤ 0x1000` (16 px)
   and `v > 0` (rising), else one-way top (1006d048–1006d074). Position `(x − 12, y − h_px − 4)`;
   kind copied; if head y > base y − 8 (h_px < 4) face 0 (hidden). Tint `+0xb8`: kind 1 → `0x10017`,
   kind 0 → 0, kind 2 → `0x1000c` (1006d108/1006d11c), kinds 3/4 unchanged — ~~[MED "tint"]~~ a mode-1
   remap through tint table 0x17 / 0xc, copied to the segments (`1006d200..1006d208`) [HIGH dispatch;
   draw-effects §2.2, colours lighting-tables §3.2] ⚑ wave 2 corr (2026-10-04) DE #11 (merged with PA #1).
   Head setup (Box arm, handler l. 11624–11631): rect `SetRect(8, 8, 40, 32)`, one-way, no tile
   callback, gravity 0, push mass and sag 0; no Box handle arm, so only the common tail runs.
3. If the head face is 0 (or no head) `n = 0`.
4. **Segments** i = 0..15: i < n → (create `MTNewSprite(0x5a0, x + 1, y, layer 1, −1,
   SetupEffectSprite)` if absent) y = `base y − 22 − 32·i` (1006d1bc, spacing 0x20 at 1006d3d8);
   face = cache 1442 entry `head +0x46 >> 1` (PICT 1442: 6 faces 20×32); kind and tint copied from
   head; top segment `+0x1bc = 32·n − h_px` (rows clipped from the face top in `.WrapDrawSprites`,
   main l. 10249), others 0. i ≥ n → killed. Effect setup for 0x5a0 (handler l. 7947–7953):
   handler `.HandleGeyserSegSprite` (empty, l. 8033), no hit/tile callback, rect
   `SetRect(4, 24, 16, 32)` → an 8-px-tall damage band at the foot of each 32-px cell, layer 1; it is
   excluded from the explosion package (l. 7893).
5. **Spray particles** (only while column rect `(x, y − h_px, x + 64, y)` intersects the view rect
   `(h, v, h + 608, v + 384)`, origin `PTR_DAT_1009fe78`): per live segment `k = FastRand(3) + 3`
   draws (FastRand(3) is drawn for every segment even off-screen); each: `r = FastRand(32)`; if
   `r ≥ +0x1bc`: `FastRand(100) ≤ 50` → px `x + 10 − FastRand(5)`, `vx = −40 − FastRand(100)`, else
   `x + 14 + FastRand(5)`, `vx = 40 + FastRand(100)`; `vy = 200 − FastRand(1000) − v`; y = seg y + r;
   `NewParticle(kind + 200, 190, (px, y), 4, vx, vy, FastRand(10), 1)`.
   Head (every frame, no view test): y += `FastRand(6) + 10`, one `FastRand(4)` discarded, then
   `FastRand(100) ≤ 50` → px `x + 12 − FastRand(12)`, `vx = −70 − FastRand(170)`, else
   `x + 12 + FastRand(12)`, `vx = 70 + FastRand(170)`; `vy = 250 − FastRand(1300) − v`; same call.
   The RNG order above is the raw order (1006d2a4–1006d394, 1006d3f8–1006d4e0).
   `.NewParticle`/`.HandleParticles` (main l. 29860, 29611): arg 2 = gravity added to vy per frame
   (190), start age = −FastRand(10) (delay), mode 1 = dies on a solid FG tile (≥ 0x51) or on entering
   water with vy ≥ 0x2ef; any particle dies at age > 120 [HIGH]; ~~arg 4 = 4 [NOT RESOLVED meaning]~~
   arg 4 is the **shape code: 4 = 1 px wide × 2 px tall** (`10015b60` jump-table case 4; particles §3.2).
   Colour rows (`.InitParticleColors`, main l. 29291/29301/29320): kind 200 a CLUT ramp
   (entries 0x78/0x7e/0xa8/0xeb, blue +10000 while < 55000), switching **by age>>1** at ages 8/16/24 (the
   by-age first write is overwritten, `10030994` vs `10030fa8`); 201 CLUT 0x71 + min(age/5, 3); 202 red
   `(10 − age/2)·0xaf0 + 32000` with **green = 0.4·red** (orange; `10031048..10031098`, `lfd 100a17a8` =
   0.4), blue 0. Exact colours particles §4.4 (chosen index LOW) ⚑ wave 2 corr (2026-10-04) PA #1.

`.KillBox` (main l. 47950–47962) kills all 16 segments and the head of a dying 0x5a0..0x5a8 base.
No other caller of `.HandleGeyserColumn` exists (`bl 0x1006cf7c` only at 1006e27c), and the three
face caches are used only by geyser code (`tocrefs.py 100a0a14/18/1c`) — **no Background-class
lava spout shares this code**; floor fire 1208 is separate (triggers-background.md §2.4) [HIGH].

## 5. Triple geyser 0x5a5 re-targeting (handler l. 12643–12699, raw 1006e0c8–1006e274)  [HIGH]
Only during the parent's rising phase. For each of the three heads (own, `+0x1d4`'s, `+0x1d8`'s):
counted as **covered** if `+0x186` (ridden this frame) is set and its rider `+0xe0` is not
`*_DAT_1009fdd8` (the player sprite [MED]); the flag is cleared. `B = +0x16c`,
`L = trunc(max(50.0, 0.33·B))` (doubles 0x100a1ad0 = 50.0, 0x100a1ad8 = 0.33), `c` = covered count.
Each column's `+0x154` := `L` if covered, else `B + c·(B − L)`. A crate or statue resting on one jet
(Box solids land on geyser pieces, §7) lowers it to a third and drives the others higher; the player
standing on a head never counts. Unused by the shipped levels.

## 6. Sound  [HIGH]
None. `snd 430 'geyser start'` and `snd 431 'geyser loop'` are loaded by `.InitSounds` into
`*_DAT_100a03c0` / `*_DAT_100a03bc` (main l. 39581–39584) and released by `.DisposeSounds`; no other
code loads those TOC slots (`tocrefs.py`). The only audio-shaped call is the discarded
`CalcStereoVolume(…, 0x2a, …)` at eruption start (§3; its output `r1+0x58` is never read in
`.HandleBoxSprite`). A replica that plays the geyser sounds diverges from 1.0.3 [residual: an
indirect load of those handles was not seen].

## 7. Contacts  [HIGH unless noted]
- **Player vs base** (Box 0x5a0/0x5a5): ordinary Box arm → `.PlatformBounce`, one-way top, no damage.
- **Player vs head 0x5a9**: Box arm, landing → kind ≥ 1 damage per enemy-shots-and-damage.md §3.3
  (kind 1 0x70 / kind 2 0x150, knockback ±400, −0x640, invul 60); kind 0 (water, level 10) is a
  harmless moving platform — the rider is carried by `.StandardSpriteHandles` (physics §8.1) [MED for
  the ride, since the head is moved by direct x/y writes].
- **Player vs segment** (Effect 0x5a0): hazard arm, enemy-shots-and-damage.md §3.4 (±300 knockback);
  `.HurtSprite`, so no coin loss. Player shots pass through segments (no 0x5a0 test in
  `.HitPlayerShotSprite`) [MED, absence].
- **Enemies**: any type-0x5a0 sprite — base or segment — with kind 1/2 hurts Walker and Roach
  (100); Crawler and Frog test `+0x14c == 1 || +0x150 == 2`, so lava (kind 2) does not hurt them
  (enemies-ground.md §2.3, enemies-water-cave.md §1.5) [HIGH as read].
- **Boxes** (`.HitBoxSprite` l. 13424–13510): geyser-vs-geyser pairs are skipped; against any other
  Box/Statue the geyser piece is always the solid (the other lands on it).

## NOT RESOLVED
1. ~~`.NewParticle` arg 4 (= 4) meaning; exact on-screen colours of particle kinds 200–202.~~ → closed:
   particles §3.2/§4.4 (the index pick stays LOW, particles NR 1) ⚑ wave 2 corr (2026-10-04) PA #1
2. Whether `.ActiveToIdleSprite`/`.IdleToActiveSprite` re-run Setup (a second `AllocateGameMem(0x44)`)
   for a collapsed geyser that leaves and re-enters the screen.
3. Visual intent of kinds 3/4 (unplaced; base face index past the 12-entry cache).
4. Whether the designers meant p4 as a phase (shipped p4 = 60, 30, 40, 60 on four lava jets in
   levels 50/51) — in code it is inert.

## Proposed additions to physics.md §0
| off | type | meaning (geyser base) |
|---|---|---|
| +0x150 | i32 | base y at setup |
| +0x154 / +0x16c / +0xf4 | i32 | current target height / base target (p1<<8) / fall reference (8.8 px) |
| +0x158 / +0x15c | i32 | on / off frames (p2 / p3) |
| +0x164 / +0x168 | i32 | column height / velocity (8.8 px, per frame) |
| +0xa6 | i16 | phase `C mod (on+off+1)` (Setup's p4 copy is overwritten) |
| +0x9c | ptr | 0x44-byte block: 16 segment ptrs + head ptr at +0x40 |
| +0x1c6 | u8 | may go idle off-screen (geyser: 1 only when collapsed) |
| +0x1c8 / +0x1ca / +0x1cc / +0x1ce | i16 | idle test pads left / right / top / bottom (`.HandleIdleSprites`) [MED] |
| +0x1bc | i16 | rows clipped from the face top (segments, `.WrapDrawSprites`) |
| +0xac | i32 | −1 = suppress the (dead) eruption-volume call (triple parent and 2nd child) |

## Corrections to the existing bank
| file § | old reading | new reading | evidence |
|---|---|---|---|
| pickups-boxes §2.2 geyser row | "phase `+0xa6 = p4`"; `HandleGeyserColumn` not read; "two 0x5a0 children" | p4 is overwritten every frame by `C mod (p2+p3+1)` before any read — inert; column read (this file §3–4); children are kind 0 regardless of the parent | raw 1006bcf4 vs 1006df90; 1006bd40 |
| pickups-boxes NOT RESOLVED 4 | geometry/liquid/0x5a9 creation unknown | closed: §1, §4 | main l. 47539 |
| pickups-boxes §2.4.10 | "Column pieces 0x5a9" [MED] | one head 0x5a9 per column, created/moved by `.HandleGeyserColumn` [HIGH] | main l. 47539–47562 |
| enemy-shots §3.4 (last para), enemies-ground §2.3 | Box 0x5a0 = "lava/acid pool(s)" | Box 0x5a0 is the geyser base (nozzle); no pool object exists in this range (physics §5.1 already struck it) | §1–2 |
| triggers-background-2 NOT RESOLVED 5 | "geyser kinds 200+" unknown | narrowed: colour rows 200/201/202 by liquid kind (§4.5) | main l. 29291–29320 |
| INDEX NOT RESOLVED 1 | params of 1440..1449 unknown | closed for this range (§2) | raw 1006bc44–1006bcf4 |
