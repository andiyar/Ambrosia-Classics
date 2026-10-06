# Ferazel's Wand 1.0.3: platforms, ropes, radial geometry (2): frame order, sibling order, loose ends

Code readings only; nothing behaviour-verified. Date 2026-10-04.
Sources: main dump `ghidra/Ferazel_pef.decompiled.c` ("main l. N"), handler dump `ghidra/Ferazel_handlers.decompiled.c`
("handler l. N"), raw listing `ghidra/Ferazel_pef.disasm.txt` (addresses), `tools/const.py` / `tools/tocrefs.py`
(TOC slot → TVector = word + 0x1009f840), PICT 711 decoded from `Ferazel's Wand Sprites.rsrc` (own PackBits decoder).

Scope: wave 2 (2026-10-04), INDEX NOT-RESOLVED 25 (platforms-ropes-radial NR 2, 3, 4, 6) and the
frame-order / active-list rule that save-continue §9, held-item-melee §4 and player-states §9 cite.
Continues `platforms-ropes-radial.md` (sections 1–7); numbering continues at §8. Units as there.

## 8. One game frame and the active list  [HIGH]

### 8.1 Order of one frame
| step | what | raw |
|---|---|---|
| 1 | `.GameLoop` calls `.PaintFrameWrap`; its whole body is inside `if (*PTR_DAT_1009fe2c == 0)` (the pause flag; also read by `.Pause` [MED name]) | `1000a184`; `10011d00` |
| 2 | draw: lights, water effects, **`.WrapDrawSprites`** (walks the active list in order) | `10011dd0` |
| 3 | frame-parity flip of `*_DAT_1009fd30` (§10.1) | `10012710..1001272c` |
| 4 | `.HandleIdleSprites` (idle slots whose extents meet the view ± 0x60 become active) | `100127cc` |
| 5 | `.HandleSprites` = `.MTHandleSprites` → `.MTCollideSprites` → if the player is alive (`*_DAT_1009ffa8 == 0`) and exists: `.MTCollideSpecialSprite(player, HitPlayerSprite)` | `100127d4`; `10007c30`, `10007c38`, `10007c40..10007c64` |
| 6 | `.HandleParticles`, `.WrapEraseSprites` | after `100127d4` |
| 7 | back in `.GameLoop`: events, keys, sounds, track map, then **`.UpdateSprites`** (removes `+0xe9` sprites, idles) | `1000a298` |

So every sprite handler of frame n runs before every hit callback of frame n, and what either writes
is drawn at step 2 of frame n+1. Inside one frame a value written by a hit callback is seen by
handlers only in the next frame.

### 8.2 The active list
- Head `*(_DAT_1009ff58 + 0x5c)`; links `+0x68` next, `+0x6c` previous.
- **Sorted by the i32 layer `+0x80`, ascending, signed** (`cmpw`). `.MTInsertSprite` (raw
  `10032f1c..10032fd0`) inserts a sprite in front of the first sprite whose layer is **strictly
  greater** (`bge` on equal at `10032f44`, `10032f80`), otherwise at the tail: **inside one layer, the
  order is insertion order** (oldest first).
- `.MTNewSprite` runs the Setup proc (`bl 0x1009f80c` with r12 = the setup TVector, `1003321c`)
  **before** `.MTInsertSprite` (`1003322c`); the `+0x80` argument is stored first (`10033200`) but the
  Setup proc may overwrite it, and the inserted position uses the Setup's value.
- `.MTChangeSpriteLayer` = remove + insert (moves the sprite to the tail of its new layer group).
  Direct `+0x80` stores do **not** move a sprite (e.g. `.HandleStatueSprite` `+0x80 = 2` at `10066518`,
  `.HandleHeldItemSprite` `0x14` every frame at `1004beb0`, `.DoSetupPlatformSprite` `100632d8`/`10063400`).
- `.MTHandleSprites` (raw `100325b8..100325d8`) loads `next` **before** calling the handler `+0x4c`
  (skipped when null). A sprite created during the pass is handled in the same frame only if it is
  inserted after that saved `next`; inserted between the current sprite and `next` (or earlier) it
  first runs next frame.

### 8.3 The two collision passes
`.MTCollideSprites` (raw `100326cc..10032a90`): clears every `+0x44` (hot-rect-computed flag); for
each sprite A **in list order** with `+0x5c ≠ 0`, `+0x1b2 == 0`, `+0xe9 == 0`, scans every B **from the
head** (`10032714`) with B ≠ A, `+0xe9 == 0`, `|ΔA+0xc| < R` and `|ΔA+0xa| < R` (R = `*(_DAT_1009ff58+0x1c)`,
`100326e8`) = **360 px** (`li r0,0x168; sth r0,0x1c(r31)` at `10032274`/`10032278`; ⚑ corrected (review
2g, 2026-10-04) #1), the `+0x184` same-handler exclusion, and `.CalcHotRect` rects `+0x3c` intersecting.
- Contacts 1..6 are collected; a 7th and later are dispatched at once, `A.hit(A,B)` then `B.hit(B,A)`
  if B has one (`10032848..10032870`).
- 1 contact: `A.hit(A,B)`, `B.hit(B,A)` (`10032898..100328c8`).
- 2..6: key `−(|ey − A+0xe| + |ex − A+0x10|)` per contact, with `ex` = B `+0x42` if B `+0x10` < A `+0x10`
  else B `+0x3e`, and `ey` = B `+0x3c` if B `+0xe` < A `+0xe` else B `+0x40` (`100328e8..10032958`);
  the **minimum** key (the contact farthest by that measure) is dispatched first (single-pass minimum,
  `10032990..100329bc`), then the others in list order (`10032a2c..10032a80`). The x term uses B's
  near edge and the y term its far edge — as written.
- Every **ordered** pair is visited: when A and B both have hit callbacks, each callback runs **twice**
  per frame (once with A outer, once with B outer) — unless the first visit kills one of them: the
  outer and inner `+0xe9` tests (`10032750`, `1003276c`) then skip the second visit; and there is **no**
  `+0xe9` re-test between `A.hit` and `B.hit` of one visit, so B's callback runs even if `A.hit` just
  killed B (enemy-shots-and-damage-2 §4.2) ⚑ corrected (review 2g, 2026-10-04) #2. The main pass
  intersects with `.TheSectRect` (`10032688`), the player pass with `.SectRectFast` (`10034db4`); "twice"
  assumes both agree on rects that only touch at an edge — not verified [MED] ⚑ corrected (review 2g,
  2026-10-04) #3.

`.MTCollideSpecialSprite(player, HitPlayerSprite)` (raw `10032ac8..10032eec`; TOC `_DAT_1009fdd4` → TV
`0x100a21b4` → `100556f4`): the player has **no** hit callback (`.SetupPlayerSprite` `s+0x5c = 0`,
player-states §8), so `.HitPlayerSprite` is reached **only here**, once per contact per frame.
- Rects: the raw `+0x34` rect plus position on both sides (`10032bfc..10032c84`), not `+0x3c`.
- Contacts: every sprite with a handler, `+0xe9 == 0`, ≠ player; up to 16 collected (`cmpwi 0x10`
  `10032c9c`), later ones get `HitPlayerSprite` at once without their own hit.
- 1 contact: `HitPlayerSprite(player, C)`, then `C.hit(C, player)` if C has one.
- ≥ 2: if any contact's handler is `.HandleSeeSawSegSprite` (r31 = TOC `−0x7678` = `_DAT_100a01c8` →
  TV `0x100a22a4` → `100655c8`, compared at `10032db8`): `HitPlayerSprite` for every contact **in list
  order** and no contact hit callbacks (`10032e9c..10032ed8`). Otherwise each contact in **list order**
  gets `HitPlayerSprite(player, C)` then `C.hit(C, player)`: the "sort" (`10032e04..10032e30`) takes the
  first entry whose key is < 32000 and breaks (`addi r6,r27,0` at `10032e30`); every key is ≤ 0, so
  the order is plain list order.
- Hence a sprite with a hit callback that touches the player gets `C.hit(C, player)` **twice** per
  frame (in `.MTCollideSprites` as the outer A, then here) unless a see-saw segment is also touching.

### 8.4 Layers met in this wave
| layer | sprites | raw |
|---|---|---|
| −2 | chain spokes 0x596 of platform modes 10/11/20/21/22 (`.MakeRadiusSprites` arg 3; `.SetupChainSprite` keeps it) | `10062610 li r5,-0x2` (also `100627fc`, `10062830`, `10062878`, `10062a34`, `10062d20`) |
| −1 | **every Platform** (`.SetupPlatformSprite`), record platforms, wheel/see-saw siblings, spell floes and wall ice (spawned with arg 2, Setup overrides) | `10061fbc li r7,-0x1` → `10061fd4` |
| 0 | see-saw segments 0x59b (`.MakeRadiusSprites` arg 0; `.SetupSeeSawSegSprite` keeps it) | `10062fc0 li r5,0x0` |
| 2 | Box class (save points, crates; Setup default) | `1006b498 li r0,0x2` → `1006b4ac` |
| 9 | five Double-Speed trail sprites, Shadow Double (player layer − 1) | held-item-melee §2/§3 |
| 10 | the player | `1004af88 li r5,0xa` → `1004afac` |
| 0x14 | the held item (created inside `.SetupPlayerSprite`, `1004b018..1004b030`) | `1004bdfc` → `1004be20` |

Record platforms are created by `.SetupLevelSprites` in a pass of their own, record index 0..510
(`10003e8c..10003eb0`: types 0x578..0x595), **after** the 0x51b pass (`10003e1c`) and **before** every
other type (`10003f04..10003f2c`); `.GenerateSprite` never idles a platform (`10003588..100035a0`:
`r30 = 0`). So within layer −1: record platforms in record order, then the siblings, created on the
first frame by each record platform's first handler (`.DoSetupPlatformSprite` via `+0x17c == 0`), in
record order, each group S1 (`+0x1d4`), S2 (`+0x1d8`), S3 (`+0x1dc`) consecutively (main l. 54606,
54704, 54770–54773, 54820–54826; all `MTNewSprite(…, 1, −1, Platform)`).

## 9. Within-frame order of sibling wheels and see-saw arms (platforms NR 4)  [HIGH]

From §8.4 the record platform P **precedes** its siblings, and the siblings run S1, S2, S3.
Per frame (handler l. 8553–8650 wheels, 8424–8478 see-saw):
1. Every member runs its own handler: cooldown; if ridden (`+0x186`, set by `.PlatformBounce` in the
   **previous** frame's collision pass, §8.1) and `+0xa6 ≥ 0`: driver flag `+0xb2 = 1` and
   `.RadialWheelStep`; then `.UpdateRadialPos` (angle += speed, hub += hub velocity, damping);
   position and spokes placed.
2. The member whose `+0xb2 == 1` (the **driver**: the one ridden most recently) then writes into every
   sibling: `+0xb2 = 0`, angle = own + offset, speed = own speed, **hub position** `+0x0/+0x4` = own —
   **not** the hub velocity `+0x8/+0xc` (see-saw raw `10063e48..10063ea8`; wheels handler l. 8590–8650).

Consequences a replica must copy:
- **A sibling after the driver in the list** runs step 1 on the copied values in the same frame:
  its angle advances by one more damped speed step, so it is drawn **one frame ahead** of the driver
  (and its hub moves by its own residual hub velocity). Driver P → S1..S3 all lead by one step.
- **A member before the driver** ran step 1 on the copy from the previous frame: in step with the
  driver except on frames where the driver received a rider impulse (`.RadialWheelStep`), which it
  shows one frame late. Driver S2 of a 3-wheel → P, S1 lag on impulse frames; S3 leads.
- A former driver keeps its own hub velocity (decaying ×`+0x10`/256 per frame) and adds it to the
  copied hub each frame until it fades.
- Riding latency: wheels respond on the frame after the landing (n+1). A see-saw responds on **n+2**:
  the landing sets the **segment's** `+0x186` in frame n; the segment (layer 0) runs after the arms
  (layer −1) in frame n+1 and only then marks its arm ridden and writes the lever `+0x150` (handler
  l. 9438–9444); the arm reads it in frame n+2. The arm clears its own `+0x186` at the end of every
  handler (`10063eb0`), before the segment can set it.

## 10. Globals of the platform/player code (platforms NR 2)  [HIGH]

### 10.1 `_DAT_1009fd30` → global `0x1024b50c` (u8) = frame parity
Only writer: `.PaintFrameWrap` (slot loaded once into r27 at `10011d28`): `lbz; cmplwi 1; bne →
stb 1; else stb 0` at `10012710..1001272c`, i.e. 1, 0, 1, 0 … once per unpaused frame, before the
sprite handlers (§8.1). Initial 0 (bss: `const.py 1024b50c` → 0). Ten loads, all byte reads (follow
of every load): `.FindUpperLeftCorner`, `.WrapDrawWaterEffects`, `.AnimateCLUT`, `.HandlePlayerSprite`
(`1005113c`: power-up tint selection while invulnerable, handler l. 2510), `.HitPlayerShotSprite`, `.HitPlayerShotTileSprite`, `.HandleBonusSprite`,
`.HandlePlatformSprite` (`10064b28`), `.HandleWizardSprite`. For the **floe** (mode 4, lifetime
`+0xa6 < 0x2d`, handler l. 9066–9078): parity 0 → effect 0, parity 1 → `0xb0000` — the floe is
drawn translucent on alternate frames (a 2-frame blink) for its last 44 frames. Closes the
platforms §2.8 "[MED: that global as a flash phase]".

### 10.2 `_DAT_100a067c` → global `0x102bb7a8` (u8) = write-only
Three TOC loads (`tocrefs`), each used for one store and dropped (followed): `.HitPlayerSprite`
`10056bc8..10056bcc` stores 1 when the player's centre x is inside a touched see-saw segment
(handler l. 3875); `.HandlePlayerSprite` `1004e57c..1004e588` stores 0 every frame (unconditional:
both arms of the preceding test join at `1004e57c`); `.ClearPlayerVars` `1004ac2c/1004ac38` stores 0.
No other slot reaches the byte (neighbouring slots `0x100a0660..0x100a0678` checked for offset
accesses: none). **No reader**: a dead flag; a replica may omit it.

### 10.3 `*psVar26` in the J reset = the climb flag `_DAT_100a0758`
`psVar26 = _DAT_100a0758` (handler l. 722); raw: r15 = TOC `−0x70e8` (= slot `0x100a0758`) at `1004d650`.
The reset (raw `1004dc54..1004dc84`): `J = 0` if (`s+0xce ≠ 0` **or** `climb ≠ 0`) **and** the ridden
sprite `*PTR_DAT_100a0558 == 0` (slot `−0x72e8`); then `J = −0x898` if High Jump (`1004dc88..1004dca0`).
At this point (before `.HandleKeys`) `climb` still holds the previous frame's tile-pass value, so J
is cleared while grounded or clinging and **kept while riding a sprite** (the rider's J is written by
`.HandleKeys` from the ridden sprite's `+0x194` at the jump). Corrects platforms §4's "not frozen".

## 11. Platform `+0x190` and the Statue spell on a platform (platforms NR 3)  [HIGH]

`+0x190` has three accesses in the whole code section (`fieldscan` of `0x190(rN)` excluding r1/r2):
stores only — `.InitSprite` `1003d540` (0), `.SetupPlatformSprite` `10062014` (0), `.HitPlatformSprite`
`10064dd8` (0, before `.TurnIntoStatue`). **No load**: a dead field (always 0).

`.TurnIntoStatue(platform)` (main l. 38248; raw `10043138..100431c4`): sound, saves `+0x4c/+0x5c/+0x1f8`
into `+0x1ec/+0x1f0/+0x1f4`, `+0x130 = 0x78`, `+0x134 = +0xb8`, installs `.HandleStatueSprite` /
`.HitBoxSprite` / `.HitBoxTileSprite`, `vx = vy = 0`. For the next 120 frames the platform:
- runs **no platform code**: no `.StandardSpriteHandles`, no radial update, no spoke placement (its
  spokes freeze where they were), no rider carry, no lifetime count (a floe does not melt meanwhile);
- `.HandleStatueSprite` (handler l. 9857–9884): light added once, tint `0x1000b`, `+0x130 −1`,
  `v = 0`, **`+0x80 = 2` by direct store** (list position unchanged, §8.2; the 2 survives the thaw);
  blinks (effect 0) on odd counts below 0x14; at ≤ 0 restores the three callbacks and `+0xb8`,
  `+0xa4 −= 200` (no platform code reads `+0xa4`), removes the light;
- to the player it is a plain solid: `.HitPlayerSprite`'s Statue arm (handler l. 4216–4222)
  `PlatformBounce(player, platform, centre, 0, rect, 0)` — still one-way, since `+0x185` is not
  touched; its own hit callback is now `.HitBoxSprite`, whose solid arms (handler l. 13464–13514)
  treat Statue/Box/Platform-handled sprites as solids [MED: the per-mover arms not re-read for a
  frozen platform];
- wheel/see-saw siblings keep running their own handlers; a frozen driver stops slaving them, so they
  coast with their own damping until another member is ridden.

## 12. Wall-ice face 1 vs 2 (platforms NR 6)  [HIGH]

`.HitPlayerShotTileSprite` (handler l. 5734–5776; raw `1005b1e0..1005b320`), Ice-Wall shot (type 3),
FG layer, after `.WallBounce` returned a hit, with `k` = the **raw** tile kind argument (hundreds
included, `rlwinm …,0x10,0x1f` at `1005b200`/`1005b254`):
- `R` = `k == 2` or (`k ∈ {6, 7}` and the shot's `vx == 0` after the bounce) (`1005b23c..1005b28c`);
- `L` = `k == 0` or (`k ∈ {4, 5}` and `vx == 0`) (`1005b1f0..1005b238`);
- `R` → `MTNewSprite(0x57c, X − 0x17, shot +0xe, 2, −1, Platform)`, `+0x16c = 1` (`1005b2b8..1005b2e0`);
  else `L` → same at `X + 0xf`, `+0x16c = 2` (`1005b2e8..1005b310`); then `+0xa6 = 0xb4`, `+0xb0 = 4`.
  X = the tile cell's left x (low half of the tile-position argument).
- Kinds with a material (≥ 100), composites 0x10..0x1f and every other kind: no wall ice.

Face set 0x2c7 = `PICT 711 'frozen water platform'` (40×72 → 3 faces 40×24 stacked,
`LoadEncFaceSetFromPICT(0x2c7,3,0x28,0x18,1,…)` main l. 54475; face i = rows 24i..24i+23), decoded:

| face | art | used when |
|---|---|---|
| 0 | free floe: flat slab, icicles below, both ends rounded | `+0x16c = 0` (shot entering water) |
| 1 | ledge whose **right** end rises and dissolves into a wall (dithered right edge) | `R`: solid right-half wall (kinds 2, 6, 7) hit while moving right; the ledge spans X−23..X+16 (40 px), its right end on the wall face at X+16 ⚑ corrected (review 2g, 2026-10-04) #5 |
| 2 | mirror image: **left** end merges into a wall | `L`: solid left-half wall (kinds 0, 4, 5) hit while moving left; spans X+15..X+54 (40 px) from the wall face at X+16 ⚑ corrected (review 2g, 2026-10-04) #5 |

## NOT RESOLVED
1. ~~(Unchanged from platforms NR 1, not this lane) pixel semantics of draw effects 1..4, 7, 9, 0xc,
   0x10..0x13 and which blend operand is the sprite pixel.~~ → closed by draw-effects §2 / §2.7
   ⚑ wave 2 corr (2026-10-04) DE #5, #6
2. The visual meaning of the `.MTCollideSprites` dispatch key (far-y / near-x edge mix, §8.3) — the
   rule is exact; whether it was meant as "nearest first" cannot be settled from code (UNDETERMINABLE
   intent; copy as written).

## Proposed additions to physics.md §0
| off | type | meaning |
|---|---|---|
| +0x44 | u8 | hot rect `+0x3c` computed this collision pass (cleared at the start of `.MTCollideSprites`) |
| +0x68 / +0x6c | ptr | active-list next / previous |
| +0x80 | i32 | layer: active-list sort key, ascending, insertion order within a layer (§8.2) |
| +0x190 | i32 | dead: written 0 only (§11) |

## Corrections to the existing bank
| # | file § | old | new | evidence |
|---|---|---|---|---|
| 1 | held-item-melee §1.5 last paragraph (owned by this lane; applied there) | "`.GameLoop` runs `.MTHandleSprites` then `.MTCollideSprites`" | both run inside `.PaintFrameWrap` → `.HandleSprites`, after the draw; the player's hits come from `.MTCollideSpecialSprite` | §8.1; `100127d4`, `10007c30..10007c64` |
| 2 | triggers-background §2.3 (spring cooldown "re-armed 4 frames") / enemy-shots-and-damage NR (active-list order, "collidable twice") | order not established | handlers before hits; a hit callback runs twice per frame for a pair where both sprites have one, and twice for a sprite touching the player (§8.3); a spring fired in frame n can fire again in frame n+4's collision pass | §8.1, §8.3 |
| 3 | physics.md §0 `+0x80` (if listed as draw order only) | draw/sort | also the handle and collision order (one list) | §8.2 |
