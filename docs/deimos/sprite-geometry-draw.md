# Deimos Rising 1.0.6 — sprite geometry, collision size and per-entity draw parameters

**Scope.** Sprite geometry as the simulation sees it, and how an entity becomes draw commands.
Functions: `FUN_10019ca0` (U_Sprite_GetDimensions), `FUN_10019c10`, `FUN_10019ad0`,
`FUN_10019530`, the scale/anchor arithmetic of the draw dispatcher `FUN_10019570` (its
mode/clip dispatch is already HIGH in sprite-sound-containers.md §2.3a), the half-size refresh
`FUN_10012940`, the rect builders `FUN_10012ad0`/`FUN_10012a00`, the draw entry `FUN_10012f20`,
entity draw `FUN_10012fa0`, shadow draw `FUN_10013460`, the fade→alpha helper `FUN_10010c20`, the
shadow/sprite passes of `FUN_100345f0`, and `kU_Sprite_MaxDimensions` (`_DAT_100df180`,
INDEX #8). Read as well, because they decide the questions: the render queue `FUN_10018a40`,
`FUN_1001a450`, `FUN_1001a650`, `FUN_10018b20`, the head of the scaled blitters
`FUN_1001a6f0`/`FUN_1001aa90`, `FUN_1001a260`, `FUN_10012840`, `FUN_10012650`, the shadow and
tint blitters `FUN_1001dd20`/`FUN_1001df00`, `FUN_1004d5c0`.
**OUT:** the pixel blend arithmetic of every blitter (sprite-sound-containers.md §2.3a), the
debug-label part of `FUN_100345f0`, the collision tests themselves (damage-health-death.md §2),
terrain drawing (level-scroll-objects.md §5, §9). This is a code reading. None of it has been
checked against the running game.
Raw listings: `$W/disasm-w2s1.txt`, `$W/disasm-w2s1b.txt`, `$W/disasm-w2s1c.txt`
(DisasmFuncs.java against the private copy `$W/work-w2s1`; `$W` = `/Users/andiyar/ghidra-proj-deimos`).

**Short answers.**
- **(1)** An entity's position is the centre of its *trimmed* sprite frame, in both the unscaled
  and the scaled draw path.
- **(2)** The collision box is `x ± trunc(w·s)/2`, `y ± trunc(h·s)/2`, built from the frame's
  w/h and the live scale `+0x84`. It is refreshed every tick. A radius is half the box height.
  - player ship (pl1o): 21
  - Flipper Mk 2: 19
  - Tank - Laser: 22
- **(3)** `kU_Sprite_MaxDimensions` = width 300, height 256.
- **(4)** There are two kinds of shadow:
  - Air-layer shadows: a half-size copy of the sprite at offset (−24, +52).
  - Ground-layer shadows: full size at offset (−6, +8).
  - In both, the pixels under the silhouette are darkened to 20/32 of their brightness.
  - The SHADOWS console flag (default on) gates all of them. ⚑ corrected (review wave 2, 2026-10-03) #M7a: SHADOWS is never
    registered in 1.0.6, so the flag stays 1 and shadows are always on (§3.2).
- **(5)** Visibility `+0x68` becomes an alpha of 32·(1 − v/100). Tint `+0x58` is a second
  solid-colour silhouette pass. Scale `+0x84` takes the scaled blit path.
- **(6)** Draw order:
  - layers 0–1: terrain stamps, drawn into the terrain buffer
  - the terrain
  - layers 2–5: ground shadows and ground units
  - `FUN_10043ba0` = the particle draw (particles-debris-blur.md §2.9, HIGH; ⚑ corrected (review wave 2, 2026-10-03) #C5, was
    "not read")
  - layers 6–15: air shadows, air units, player, effects, atmosphere, HUD

## 0. Constant resolution
Command (scratchpad `rd.py`: big-endian reads, data image for ≥ 0x100de330, code image below; TOC
r2 = 0x100e6330):
```
python3 -c "from rd import *; p=u32(0x100df180); print([i32(p+4*i) for i in range(2)])"
```
| TOC slot | → | values | used by |
|---|---|---|---|
| `0x100df180` (r2−0x71b0) | `0x100d6d04` | int **300, 256** = `kU_Sprite_MaxDimensions` {width, height} | `FUN_10018d20`, `FUN_1001a2a0` |
| `0x100df188` (r2−0x71a8) | `0x100d6d34` | f32 **1.0**, **100.0**, **0.5** | scale ≠ 1 test; `FUN_1001a260` ÷100; centring 0.5 |
| `0x100df178` (r2−0x71b8) | `0x100d6d40` | f64 2⁵² (unsigned bias), 2⁵²+2³¹ (signed bias) | int→float |
| `0x100df17c` (r2−0x71b4) | `0x100d6d0c` | Rect {0, 0, 480, 416} = game-area buffer | scaled path picks the unclipped blitter |
| `0x100df0e8` (r2−0x7248) | `0x100d67c4` | f64 **0.0**, bias, **100.0**, **32.0**, **1.0**, 2⁵² | visibility/tint compares |
| `0x100df0f0` (r2−0x7240) | `0x100d67a8` | f32 0.0, 100.0, 1.0, −32.0, **0.03125**, **32.0**, **0.5** (+0x18) | tint arithmetic; shadow factor 0.5 |
| `0x100df0ec` (r2−0x7244) | `0x100d6788` | Rect {0, 0, 480, 416} | default entity clip rect (`FUN_10012650`); also copied into the template clip by the static initialiser `FUN_10014120` (§3.1) |
| `r2+0xb4` (address, not a slot) | `0x100e63e4` | 0x4c-byte draw-command template (§3.1). ⚑ corrected (review wave 2, 2026-10-03) #C1: the data-image bytes are **not** the runtime template — `FUN_10014120` (a static initialiser, runs before `main`) writes +0x04/+0x08 ← 0, clip +0x20..+0x2c ← {0, 0, 480, 416}, +0x38..+0x44 ← 0 (§3.1) | `FUN_10012fa0`, `FUN_10013460` |
| `0x100df0ac` (r2−0x7284) | `0x100d6444` | f32 255, 65535, **100.0**, **32.0**, **0.0** | `FUN_10010c20` |
| `0x100df5e8` (r2−0x6d48) | `0x100d77dc` | f64 0.0, 2³², 2³¹ | `FUN_1004d5c0` (double → unsigned) |
flli items (`grep '^#' "$W/data/Game/flli/Game[gafl].flli.txt"`, line−1 = index): **48
Shadow_XOffset −48.0, 49 Shadow_YOffset 104.0, 50 Shadow_GroundXOffset −6.0, 51
Shadow_GroundYOffset 8.0**. Initial bytes (data image) `0x100e0170..0x100e0181`: `0170`=1,
`0171`=1, `0172`=1, `0179`=0, `0181`=1. [HIGH — image bytes]

## 1. Frame lookup and dimensions (U_Sprite.cc)

| function | role | label | evidence |
|---|---|---|---|
| `FUN_10019ad0 @ 10019ad0` | `frame(id, n)` → encoded-frame pointer, or 0. It walks the sprite-group list `_DAT_100e017c` (record +4 = id, +8 = frame count, +0xc = frame pointer array). If `n ≥ count` it logs "INVALID SPRITE REF … Required Frame (zero based)" and uses frame 0. `'none'` gives 0. | HIGH | listing `10019b4c lwz r0,0x4(r27); cmpw r0,r25` (id), `10019b58 lwz r0,0x8(r27); cmpw r26,r0; blt` (n < count), `10019bb8 li r26,0x0`, `10019bbc lwz r3,0xc(r27); rlwinm r0,r26,2; lwzx r29,r3,r0` |
| `FUN_10019530 @ 10019530` | group loaded? = `FUN_10019ad0(id, 0) ≠ 0` | HIGH | listing `10019534 li r4,0; bl 0x10019ad0; neg; or; rlwinm r3,r0,1,31,31` |
| `FUN_10019ca0 @ 10019ca0` | **U_Sprite_GetDimensions(id r3, frame r4, int wh[2] r5, scale f1)**. `'none'` gives {0,0}. A missing frame triggers a load attempt `FUN_1001f950(1,id,2)`, a recursive retry and a console note "Loaded Sprite Group %s". If that fails it asserts `spriteFrameDataPtr` (U_Sprite.cc 0x514/0x522). With scale == 1.0 it returns the raw w, h. Otherwise `w' = trunc((float)w × s)`, `h' = trunc((float)h × s)`. | HIGH | listing below |
| `FUN_10019c10 @ 10019c10` | the same scale arithmetic, taking a frame pointer already in hand (r3) | HIGH | listing `10019c10–10019c98` (same instructions as below) |

```
10019ca8  fmr f31,f1                         ; scale
10019ce4  bl 0x10019ad0                      ; r3 = id, r4 = frame still live from the caller
10019e34  lwz r3,-0x71a8(r2) ; lfs f0,0x0(r3) ; fcmpu cr0,f0,f31 ; bne scaled   ; 1.0 ?
10019e44  lwz r0,0x4(r30) ; stw r0,0x0(r31) ; lwz r0,0x8(r30) ; stw r0,0x4(r31)  ; w, h raw
10019e58  lwz r4,0x4(r30) … xoris r4,r4,0x8000 … fsubs f2,f0,f1   ; (float)w (single)
10019e90  fmuls f2,f2,f31 ; fctiwz f0,f2 … stw r0,0x0(r31)        ; w' = trunc(w·s)
10019e9c  fmuls f1,f1,f31 ; fctiwz f0,f1 … stw r0,0x4(r31)        ; h' = trunc(h·s)
```
The multiply is single precision (`fsubs`/`fmuls`) and the result is truncated toward zero, not
rounded. [HIGH]

### 1.1 `kU_Sprite_MaxDimensions` (INDEX #8) [HIGH]
`FUN_10018d20` (group loader) asserts each frame against it:
```
10018d2c  lwz r27,-0x71b0(r2)                 ; &kU_Sprite_MaxDimensions = 0x100d6d04
100191ac  lwz r0,0x0(r27) ; cmpw r23,r0 ; ble ok   ; "spriteWidth > 0 and spriteWidth <= kU_Sprite_MaxDimensions.width"  (line 0x24d)
100191d4  lwz r0,0x4(r27) ; cmpw r22,r0 ; ble ok   ; "spriteHeight > 0 and spriteHeight <= kU_Sprite_MaxDimensions.height" (line 0x24e)
```
- Values: **width 300, height 256**, inclusive (`ble`).
- The integrity check `FUN_1001a2a0 @ 1001a2a0` ("Sprite Manager Integrity FAILURE") checks
  every cached frame header the same way (`1001a394 lwz r0,0x0(r28)`, `1001a3b4 lwz r0,0x4(r28)`).
  It also checks magic `0x499602d2` and depth 1..16.
- The assert strings were read from the image at `0x100e6ff8` and `0x100e7039`.
- Data check (scratchpad `allf.py`, the §2.2 plate scan over every alpha plate): the largest
  frame width is **218** (`Level Names IA[LENA]`) and the largest height is **110**
  (`Burst IA[BURS]`). Every shipped frame is well inside the limit.

## 2. Entity geometry fields and the half-size refresh

### 2.1 Fields (G_GameObject; the same layout for player and entities)
| off | type | meaning | written by | evidence |
|---|---|---|---|---|
| +0x00/+0x04 | f32 | x, y = **centre** of the drawn frame (game-area px) | movement | §3.3 |
| +0x18 | u8 | pans with the horizontal view offset (draw x −= `_DAT_100e0144`) | reset 1; `FUN_100144a0` 0 for layer `hud ` | `10012fe0 lbz r0,0x18(r25)` → `bl 0x100100a0` [HIGH] |
| +0x19 | u8 | air (1) / ground (0); picks the shadow style for layer `defa` | reset 1; spawn | `100130f8`, `100135e4` |
| +0x1a | u8 | adjustShadowLocForScaling: shadow offset × scale | reset 0 | `10013608 lbz r0,0x1a(r23)` [HIGH read; MED that it is the `adjustShadowLocForScaling` copy — writer not traced] |
| +0x1c / +0x20 | 4CC / int | sprite group id / frame | state enter, animation | `10012960`, `10012990` |
| +0x24 / +0x28 | int | scaled frame w', h' | `FUN_10012940` | `100129a0 addi r5,r31,0x24` |
| +0x2c / +0x30 | int | half w', half h' (C division) | `FUN_10012940` | `100129b0 rlwinm r3,r4,1,31,31; add; srawi r3,r3,1; stw r3,0x2c(r31)` |
| +0x34 | u8 | size dirty: set by an animation step, a scale step or the owner copy; cleared by the refresh | `FUN_10015930` `10015b08`, `FUN_10012840` `10012854`/`10012888`, `FUN_10036930` `10036974` | listings |
| +0x35 | u8 | draw immediately (skip the render queue) | reset 0, terrain stamp 0 | §3.2 |
| +0x36 | u8 | draw into the terrain buffer (`stateDrawToTerrain` 0x353 / `destructDrawToTerrain`) | `FUN_100146f0` (`*(e+0x36) = state[0x353]`), `FUN_10036610` | dump l. 12129; spawn-and-waves.md §5 |
| +0x37 / +0x38 | u8 | draw sprite / draw shadow (pass selectors) | `FUN_100345f0`, `FUN_100298c0` | §5 |
| +0x3c..+0x48 | Rect | clip rect {top, left, bottom, right}; default {0,0,480,416} | reset | `10012718..10012724`; slot r2−0x7244 |
| +0x4c | 4CC | draw layer (`drawLayer_ID`); 0 / `none` → `defa` | reset `defa` | `100130c4..100130e4` |
| +0x50 | ptr | current encoded-frame pointer (0 → look up by id/frame) | `FUN_10015930` `10015b14 bl 0x10019ad0; stw r3,0x50(r30)` | listing |
| +0x54 | u8 | hide the normal sprite pass (`stateDoColorise` 0x34d, copied every tick) | `FUN_10033850` dump l. 30915 | `100132dc lbz r0,0x54(r25); bne skip` [HIGH skip; MED key] |
| +0x58 / +0x64 | f32 / u16 | tint % (`stateTintPercent` 0x3cc) / tint colour (`stateTintColor` 0x332) | `FUN_10033850` | §4.2 |
| +0x68 | f32 | visibility % (0..100) | `FUN_10012750` | §4.1 |
| +0x74 / +0x78 / +0x80 | u8 / int / u16 | hit-glow on / level (int alpha) / colour | `FUN_10012bc0` | §4.3 |
| +0x84 / +0x88 / +0x8c | f32 | scale current / target / step | §2.3 | listings |
| +0x90 | int | tick of the last terrain stamp | `FUN_10012fa0` `100132a4 stw r26,0x90(r25)` | §3.2 |

### 2.2 `FUN_10012940(e) @ 10012940` — half-size refresh [HIGH]
```
10012954  lbz r0,0x34(r3) ; beq done                       ; only when dirty
10012960  lwz r5,0x1c(r31) ; 'none' → +0x2c = +0x30 = 0, clear dirty
10012970  lwz r3,0x50(r31) ; cmplwi ; beq byId
1001297c  lfs f1,0x84(r31) ; addi r4,r31,0x24 ; bl 0x10019c10   ; frame ptr in hand
10012990  lwz r4,0x20(r31) ; or r3,r5,r5 ; lfs f1,0x84(r31) ; addi r5,r31,0x24 ; bl 0x10019ca0
100129a8  +0x2c = +0x24 / 2 ; +0x30 = +0x28 / 2 (signed C division) ; +0x34 = 0
```
This resolves damage-health-death.md §2.2's open point: the scale argument f1 is the **entity's
live scale `+0x84`**. So the collision half-size is `trunc(trunc(w·s)/2)`, built from the
*trimmed* frame of the plate (sprite-sound-containers.md §2.2).
Callers (callers.txt): `FUN_100146f0` (state enter), `FUN_10033850` (every entity tick),
`FUN_100269a0`, `FUN_10028170`, `FUN_10029cc0` (player), `FUN_10036930`, `FUN_1003b3c0`.

### 2.3 Where the scale comes from [HIGH]
- `FUN_1001a260(pct) @ 1001a260` = `(float)pct / 100.0f`. Listing: `1001a284 fsubs f1,f1,f2;
  1001a288 fdivs f1,f1,f0` with f0 = `0x100d6d38` = 100.0.
- On spawn (`FUN_100146f0`, dump l. 12151–12164):
  - `+0x84 = (initialScalePercent U+0x1ac + R(−tol/2…) )/100`, where tol is
    `initialScalePercentTolerance` U+0x1b0 and the value is floored at 0.
  - `+0x88 = stateRequiredScalePercent` (0x3bc) /100.
  - `+0x8c = stateScaleDeltaPercent` (0x3c0) /100.
  - The RNG call is units-movement.md's.
- Every tick (`FUN_10033850`, dump l. 266–271) the entity runs these in order:
  1. reload `+0x88`/`+0x8c` from the current state (`piVar9[0xef]` = 0x3bc, `[0xf0]` = 0x3c0)
  2. `FUN_10012840` (step)
  3. `FUN_10012940` (refresh)
  4. the collision tests, later in the same tick
  So the collision box always matches the scale of the current tick.
- `FUN_10012840 @ 10012840`: if `cur > tgt`: dirty, `cur −= step`, clamp at tgt. If
  `cur < tgt`: dirty, `cur += step`, clamp. Equal: nothing (listing `10012840–100128b0`,
  `fcmpo`/`ble`/`bgelr`/`blelr`). [HIGH]
- Players: reset `+0x84 = +0x88 = 1.0` (`FUN_10012650` `10012730 stfs f0,0x84(r3)`, f0 = slot
  r2−0x7240 word 2 = 1.0). No player code changes it except the "second fade" gate
  (player-physics.md).

## 3. From entity to draw command

### 3.1 The 0x4c-byte draw command (template at `0x100e63e4`) [HIGH]
Built on the stack by `FUN_10012fa0` (at r1+0x38) and `FUN_10013460` (r1+0x38). Field
offsets come from the stores. ⚑ corrected (review wave 2, 2026-10-03) #C1: the template is
**not** the data image (`b(0x100e63e4,0x4c)`, was the source of the "template" column) — the
static initialiser `FUN_10014120 @ 10014120` (a callee of `FUN_10000000`, runs before `main`)
overwrites part of it. Raw listing (`$W/disasm-units.txt`), r8 = `addi r8,r2,0xb4` = `0x100e63e4`,
single-word `lwz`/`stw` copies (no 8-byte loop, no hidden +8):
```
10014120 lwz r3,-0x7254(r2)  ; slot 0x100df0dc -> 0x100d6778 = {0, 0, 0, 0}
10014128 lwz r7,0x0(r3) ; 10014130 lwz r6,0x4(r3) ; 10014134 stw r7,0x4(r8) ; 1001413c stw r6,0x8(r8)   ; +0x04/+0x08 <- 0
10014124 lwz r4,-0x7244(r2)  ; slot 0x100df0ec -> 0x100d6788 = {0, 0, 0x1e0, 0x1a0} (code image)
10014144 stw r0,0x20(r8) ; 1001414c stw r3,0x24(r8) ; 10014154 stw r0,0x28(r8) ; 10014160 stw r0,0x2c(r8)  ; clip <- {0, 0, 480, 416}
10014150 lwz r5,-0x7258(r2)  ; slot 0x100df0d8 -> 0x100d6798 = {0, 0, 0, 0}
10014168 stw r3,0x38(r8) ; 10014170 stw r0,0x3c(r8) ; 10014180 stw r4,0x40(r8) ; 1001418c stw r0,0x44(r8)  ; +0x38..+0x44 <- 0
```
(It also writes +0x08/+0x0c of the neighbouring block `r2+0x100` ← 0.) The data image holds an
all-zero clip at +0x20..+0x2c; the **runtime template clip is the game area {top 0, left 0,
bottom 480, right 416}** = the rect `0x100d6d0c` that `FUN_10019570` compares against. Consequence:
any command builder that keeps the template clip gets a 416 × 480 game-area clip (and therefore
the **unclipped** scaled blitter `FUN_1001a6f0`, §3.3), not a zero clip. Entity draws are not
affected — `FUN_10012fa0` overwrites the clip from entity +0x3c..+0x48 (`10013098..100130b4`).
Values in the "template" column below are now the runtime ones. [HIGH — raw listing + code-image
bytes]
| off | field | template (runtime, after `FUN_10014120`) | entity source (FUN_10012fa0 listing) |
|---|---|---|---|
| 0x00 | frame ptr | 0 | `10013044 lwz r0,0x50(r25); stw r0,0x38(r1)` |
| 0x04 / 0x08 | x, y (int) | 0 | `1001305c lfs f0,0x0(r25); fctiwz … subf r0,r3,r0; add r0,r27,r0; stw r0,0x3c(r1)` / `10013078 … add r0,r0,r26; stw r0,0x40(r1)` |
| 0x0c / 0x10 | sprite id / frame | `none` / 0 | `1001304c`, `10013054` |
| 0x14 | flags: 1 fade blend, 2 shadow, 4 tint, 8 target = terrain buffer | 0 | §3.2, §4 |
| 0x18 | scale (f32) | 1.0 | `10013090 lfs f0,0x84(r25); stfs f0,0x50(r1)` |
| 0x1c | alpha 0..32 (32 = not drawn) | 0 | §4 |
| 0x20..0x2c | clip {top, left, bottom, right} | {0, 0, 480, 416} ⚑ corrected (review wave 2, 2026-10-03) #C1 (was 0, the data-image value) | `10013098..100130b4` (+0x3c..+0x48) |
| 0x30 | render layer (byte) | **7** | §6 |
| 0x31 | draw-now flag | 0 | `100130b8 lbz r0,0x35(r25); stb r0,0x69(r1)` |
| 0x34 | colour (u16) | 0x7fff | tint/hit passes |
| 0x38..0x48 | `COST` rect + colour (not used for sprites) | 0 | — |

Draw x = `trunc(e.x) − hOffset (if +0x18 and not +0x36) + 32 (if +0x36)`.
Draw y = `trunc(e.y) + windowTop (if +0x36)`. hOffset is `FUN_100100a0` = `_DAT_100e0144`.
windowTop is `FUN_1000fec0` = `_DAT_100e5acc`. Both are named in level-scroll-objects.md §1.
[HIGH — listing `10012fc4..1001308c`]

### 3.2 `FUN_10012f20(e) @ 10012f20` — draw entry [HIGH]
```
10012f34  lfd f0,0x0(r4)        ; 0.0
10012f3c  lfs f1,0x68(r3) ; fcmpo ; cror eq,lt,eq ; beq skip     ; nothing unless visibility > 0
10012f4c  lbz r0,0x38(r31) ; beq → ; bl 0x10006220 ; beq → ; bl 0x10013460   ; shadow if +0x38 and SHADOWS
10012f74  lbz r0,0x37(r31) ; beq → ; bl 0x10012fa0                          ; sprite if +0x37
```
- `FUN_10006220 @ 10006220` is the **SHADOWS console flag**. It returns the byte at
  `*(0x100defd0) + 0x28` (= `0x100fb1c0`) once the console has been set up (`DAT_100e00fe`).
  Before that it returns 1.
- The console setup (dump l. 3243–3246) sets `puVar9[0x28] = 1` and **calls** the registration
  for `SHADOWS` and `SHADOW` ("Toggles the drawing of Game Entity shadows"). ⚑ corrected (review
  wave 2, 2026-10-03) #C6 #M7a: was "registers SHADOWS/SHADOW" and "MED that `0x100e0868`
  toggles this byte". The pointer `0x100e0868` is the TVector of `0x10007e00` (data image word =
  `0x10007e00`), the SHADOWS handler, which reads and flips `G+0x28` (`10007e10 lwz
  r31,-0x7360(r2)` … `10007e24 lbz r0,0x28(r31)`) — the same byte `FUN_10006220` reads
  (`1000622c lwz r3,-0x7360(r2); 10006230 lbz r3,0x28(r3)`). SHADOWS/SHADOW are debug-only and
  gated out by `FUN_1002d080` (messages-notices-console.md §5.2, §5.5), so they are **never
  registered**: the byte stays 1 all session and **shadows are always on** in 1.0.6. [HIGH — raw
  listings + data image]
- Entity draw (`FUN_10012fa0`), after the command is built:
  - `+0x36` set → if `FUN_10005ce0()` (game block +0x1c = the **game time** getter, HIGH per
    messages-notices-console.md role row `FUN_10005ce0`; ⚑ corrected (review wave 2, 2026-10-03)
    #C5, was "LOW: last-present tick") `> +0x90`:
    layer 1, flags |8, clip = the terrain buffer bounds (`FUN_1000a530(display+0x6c)`), and
    `+0x90 = now`. If not, the command keeps template layer 7 and map coordinates (a latent
    oddity; it cannot happen on the single stamp call from `FUN_10036610`). [HIGH listing
    `10013264..100132a4`; meaning of `FUN_10005ce0` = game time, ⚑ corrected (review wave 2,
    2026-10-03) #C5, was LOW]
  - otherwise the layer comes from the 4CC table (§6).
  - visibility ≠ 100.0 → flags |1, alpha = `FUN_10010c20(trunc(+0x68))` (§4.1).
  - main pass unless `+0x54`; then the tint pass (§4.2), then the hit pass (§4.3). Each pass
    goes to `FUN_10019570` directly if `+0x35`, otherwise to the queue `FUN_10018a40`.

### 3.3 Anchor = centre: the draw offset arithmetic (answers Q1) [HIGH]
Unscaled (`cmd+0x18 == 1.0`), `FUN_10019570`:
```
100195cc  lfs f0,0x18(r31) ; lfs f1,0x0(r4) ; fcmpu ; … xori r27,r3,0x1     ; r27 = scaled?
100196b4  lwz r30,0x4(r23) ; lwz r24,0x8(r23)                              ; w, h of the frame
100196c0  rlwinm/add/srawi → w/2, h/2 (C division) ; subf r26,r3,r26 ; subf r25,r0,r25
                                                                          ; left = X − w/2, top = Y − h/2
```
Scaled (`FUN_1001a6f0 @ 1001a6f0`, and identically `FUN_1001aa90 @ 1001aa90` at `1001ab2c..1001ab80`):
```
1001a75c  lfs f5,0x8(r10)          ; 0.5 (0x100d6d3c)
1001a77c  fmuls f7,f3,f1           ; W = (float)w × s  (unrounded)
1001a78c  fctiwz f3,f7             ; w' = trunc(W)
1001a7ac  fnmsubs f4,f7,f5,f4      ; X − 0.5·W
1001a7b8  fctiwz f3,f4             ; left = trunc(X − 0.5·W) ; right = left + w'   (1001a7d8 add r21,r29,r3)
1001a7c4  fnmsubs f0,f8,f5,f1      ; top = trunc(Y − 0.5·H) ; bottom = top + h'
```
- Both paths centre the frame on the integer draw position. The frame is the *trimmed* cell
  content (sprite-sound-containers.md §2.2). So in an animation whose frames trim to different
  sizes, each frame is centred on its own trimmed box. That is not the plate cell.
- The unscaled path draws `[X−⌊w/2⌋, X−⌊w/2⌋+w)`. An odd width's extra column lands on the
  right.
- The scaled path is unclipped (`FUN_1001a6f0`) when the command clip equals the game-area
  rect `0x100d6d0c` (`10019818..10019844`), else clipped (`FUN_1001aa90`).
- The unscaled path counts a frame as clipped when `X < left || X+w ≥ right` (`10019754 cmpw;
  blt`, `1001975c add; cmpw; blt`).

### 3.4 Collision box vs drawn rect (answers Q2) [HIGH]
- Collision box (`FUN_10012ad0`; `FUN_10012a00` is the same in Mac Rect order; listings
  `10012ad0–10012b98`, `10012a00–10012acc`), inclusive:
  `l = trunc(x − hw)`, `r = trunc(x + hw)`, `t = trunc(y − hh)`, `b = trunc(y + hh)`, with hw/hh
  from §2.2.
- Radii (damage-health-death.md §2.3, §2.5): an entity uses `(b − t)/2` (int); the player uses
  `(b − t) × 0.5` (float).
- For `y ≥ hh` (both trunc arguments ≥ 0) `b − t = 2·hh`, so **radius = hh = trunc(trunc(h·s)/2)**.
  An odd h loses its last row.
- Near the top edge (`0 < y < hh`) `trunc` rounds the negative top toward zero. `b − t` is then
  `2·hh − 1` and an entity radius can drop by one (e.g. hh 21, y = 10.5: t = −10, b = 31 → 41
  → 20). [HIGH — arithmetic on the listing]
- The inclusive box is `2·hw + 1` px wide, while the unscaled sprite is w px wide. For even w
  the box sticks out one px to the right. In the scaled path the box and the drawn rect can
  differ by one px (worked example).

## 4. Visibility, tint and hit glow at draw time (answers Q5)

### 4.1 Visibility `+0x68` → alpha: `FUN_10010c20(v) @ 10010c20` [HIGH]
```
10010c2c  xoris … fsubs f3,f0,f3     ; (float)v      (v = trunc(+0x68), signed)
10010c5c  fdivs f1,f3,f1             ; /100.0
10010c60  fmuls f1,f1,f2 ; fsubs f1,f1,f2   ; ×32 − 32
10010c68  fcmpo f1,f0(0.0) ; bge ; fneg     ; |…|
10010c74  bl 0x1004d5c0              ; double → unsigned (trunc; <0 → 0)
10010c78  cmplwi r3,0x20 ; ble ; li r3,0x20  ; min 32
```
- **alpha = min(32, trunc(|32·v/100 − 32|))**. For 0 ≤ v ≤ 100 this is `trunc(32 − 0.32·v)`:
  v 100 → 0 (opaque), 50 → 16, 1 → 31, 0 → 32 (not drawn: `FUN_10019570`
  `100195a0 lwz r0,0x1c(r31); cmplwi r0,0x20; beq end`).
- Quirk: v > 100 bounces back up (150 → 16).
- The sprite is drawn with flags |1 (blend mode 1) only when `+0x68 ≠ 100.0`.
- Entities with `+0x68 ≤ 0` are not drawn at all (§3.2).
- `FUN_1004d5c0 @ 1004d5c0` = MSL double→unsigned: `<0 → 0`, `≥2³² → 0xFFFFFFFF`, ≥2³¹ handled
  by subtract (listing `1004d5c0–1004d60c`; constants slot r2−0x6d48 = 0.0, 2³², 2³¹). [HIGH]

### 4.2 Tint `+0x58` (glow) — second pass, colour silhouette [HIGH]
Runs only when `+0x58 > 0.0` (`10013310 lfs f1,0x58(r25); lfd f5,0x0(r30); fcmpo; ble skip`):
```
1001332c  fdiv f1,f1,f0          ; g/100.0
10013344  fmul f1,f2,f1          ; ×32.0            → frsp
1001334c  fsubs f3,f0,f3 ; fmuls f2,f3,f2   ; (float)a0 × 0.03125   (a0 = main-pass alpha, unsigned)
10013360  fsub f2,f4,f2          ; 1.0 − a0/32       → frsp
10013368  fmuls f1,f1,f2 ; fsubs f1,f1,f0   ; … − 32.0 ; |…| ; bl 0x1004d5c0
10013384  stw r3,0x54(r1)        ; alpha
1001338c  flags = 4 (|8 if +0x36) ; 100133a8 lhz r0,0x64(r25); sth r0,0x6c(r1)   ; colour
```
- **tint alpha = trunc(|32·(g/100)·(1 − a0/32) − 32|)**. Flags 4 select mode 3,
  `FUN_1001df00 @ 1001df00`: over the sprite's silhouette,
  `dst = (dst·a + colour·(32 − a))/32`.
- So the colour covers `(g/100)·(1 − a0/32)` of the silhouette. At g = 100 on an opaque sprite
  it is solid colour; it fades with the sprite's own visibility.
- The pass goes to the same layer right after the sprite.
- With `+0x54` (`stateDoColorise`) the main pass is skipped. Only this silhouette is drawn.
  [HIGH blit read; MED key name]

### 4.3 Hit glow `+0x74` — third pass [HIGH]
`100133d8 lbz r0,0x74(r25); beq end` → flags 4 (|8), `10013408 lwz r0,0x78(r25); stw r0,0x54(r1)`
(the int level *is* the alpha), `10013410 lhz r0,0x80(r25)` colour. The hit glow runs level
32→4→32 (units-movement.md §2), so at the peak the colour covers 28/32 = 87.5 %.

### 4.4 Scale `+0x84`
`cmd+0x18 = +0x84`. Anything ≠ 1.0 takes the scaled blitters (§3.3). They take the alpha as a
double in f2 (`10019848..100198a4`: `stw r0,0x6c(r1)` = alpha, `lfd f0,0x68(r1); fsubs f2,f0,f2`)
and the mode byte as the first stack argument (`10019848 stw r22,0x38(r1)`, read at
`1001a718 lbz r0,0xfb(r1)`). [HIGH]
Global switches read on the way (⚑ corrected (wave 3+4, 2026-10-04): writers now traced — only the debugOnly FX/ALPHA console
handlers write them and neither command is registered, so all three stay 1 all session;
blit-pixel-rules.md §6, sprite-manager-resource-image.md §3.2):
- `DAT_100e0172` (`FUN_1001a290` setter, initial 1) enables alpha maps in scaled blits.
- `DAT_100e0181` (initial 1) does the same for unscaled blits (INDEX #9 residue).
- `DAT_100e0171` (initial 1, no writer found): when 0, `FUN_10018a40` forces every queued
  command to alpha 0 and scale 1.0 (`10018ad8..10018ae4`).

## 5. Shadows (answers Q4)

### 5.1 Which entities, in which pass [HIGH]
- **Entities.** `FUN_100345f0 @ 100345f0` (per group, called from draw world `FUN_10007070`)
  runs two loops over the group's members.
  - Loop 1 (with the debug labels): for each member with sprite ≠ `none`, `castsShadows`
    (U+0x11e) and spawn delay `+0xb0 ≤ 0`: `+0x38 = 1, +0x37 = 0`, `FUN_10012f20`, `+0x37 = 1`.
    Listing `10034a98..10034ae4`:
    `lwz r3,0x94(r23); lbz r0,0x11e(r3); beq; lwz r0,0xb0(r23); cmpwi; bgt; … stb r0,0x38(r23); … stb r0,0x37(r23); bl 0x10012f20`.
  - Loop 2 (`10034b18..10034b5c`): for each member with sprite ≠ `none` and `+0xb0 ≤ 0`:
    `+0x38 = 0, +0x37 = 1`, `FUN_10012f20`, `+0x38 = 1`.
  - So **`FUN_100345f0` is also the entity sprite pass**, not only labels + shadows (⚑ role row).
- **Player.** `FUN_100298c0` (state 4) does the same two calls. It does not check castsShadows,
  so the ship always casts a shadow (dump l. 24494–24501).
- **Terrain stamps.** `FUN_10036610` sets `+0x38 = castsShadows` and draws once with `+0x36`.
  The shadow is baked into the terrain on layer 0.
- **Global gate.** Every shadow pass also needs `FUN_10006220` = `G+0x28` ≠ 0. ⚑ corrected (review wave 2, 2026-10-03) #M7a: that
  byte is 1 all session in 1.0.6 (SHADOWS is never registered, §3.2), so the gate always passes.

### 5.2 `FUN_10013460(e) @ 10013460` — offset, size, darkness [HIGH]
Builds the same command as §3.1 with flags |2 (`10013518 ori r0,r0,0x2`). Alpha starts at 20
(`100134f8 li r3,0x14`). When visibility ≠ 100 it becomes `max(20, FUN_10010c20(v))`
(`10013598 bl 0x10010c20; cmplwi r3,0x14; bge; li r3,0x14`).
| case (draw layer / +0x19) | shadow layer | cmd scale | offset (dx, dy) | listing |
|---|---|---|---|---|
| `defa`, air (+0x19 = 1) | 6 | 0.5 × s | (flli48, flli49) × k = **(−24, +52)** at k = 0.5 | `100135f0 li r0,0x6; lfs f1,0x18(r31); lfs f0,0x84(r23); fmuls; stfs f0,0x50(r1)` |
| `defa`, ground (+0x19 = 0) | 2 | s | (flli50, flli51) × s = **(−6, +8)** at s = 1 | `1001374c li r0,0x2; li r3,0x32; lfs f0,0x84(r23)` |
| `grou` | 2 | s | (−6, +8)·s | `10013c20 li r0,0x2; li r3,0x32` |
| `grhi` | 4 | s | (−6, +8)·s | `10013ccc li r0,0x4; li r3,0x32` |
| `ailo aihi plwe play plsh plef plui atmo hud ` | 6 | 0.5 × s | (−48, 104)·k | `10013b58..10013c18` → `10013d78 li r0,0x6` |
| any other 4CC | template 7 | per +0x19 row | per +0x19 row | `10013950..10013b4c`, no layer store |
| `+0x36` (terrain stamp) | 0, flags |8, clip = terrain buffer | as above | as above, + (32, windowTop) | `1001387c..10013944`, `10013f50..10014018` |
- k = 0.5 × s when `+0x1a` (adjustShadowLocForScaling) is set, else k = 0.5 (`1001360c beq` →
  `100136dc lfs f0,0x18(r31)`).
- The air-style shadow sprite is drawn at half scale either way. Only its offset ignores the
  entity scale when `+0x1a` is clear.
- Offset arithmetic: `d = trunc(k × (float)trunc(flli))`. Shadow x = `trunc(e.x + dx − hOffset)`,
  shadow y = `trunc(e.y + dy)` (`100137fc..10013874`: `fadds f1,f3,f1` x+dx, `fsubs f1,f1,f0`
  −hOffset, `fctiwz`).
- **Darkness.** Mode 2 = `FUN_1001dd20 @ 1001dd20` (unscaled) or `FUN_1001c6c0`/`FUN_1001bcf0`
  (scaled, not read). For each silhouette pixel (colour ≠ key, or the alpha-map rules)
  `dst = dst·a/32` per 5-bit channel (⚑ corrected (review wave 2, 2026-10-03) #M3: listing `1001ddb4..1001ddd0`, see the role row):
  `uVar3 = ((dst & 0x3e0) << 15 | dst & 0x7c1f) * a; dst = (uVar3>>20)&0x3e0 | (uVar3>>5)&0x7c1f`.
  - a = 20: the ground under the shadow drops to **62.5 %** brightness (37.5 % darker).
  - A fading unit's shadow lightens with it. At v ≤ ~37 the shadow alpha exceeds 20, and at
    v ≈ 0 it reaches 32 (not drawn).
  - Partial-alpha pixels go through a float path the decompiler hides (`FUN_1004d5c0` with a
    lost f1). [MED for that sub-case] → ⚑ corrected (wave 3+4, 2026-10-04): HIGH — α = trunc(a + 0.032·p²) as float, skip ≥ 32
    (listing `1001ddd8..1001de48`, blit-pixel-rules.md §3.1).
- 4CC names are the `lis/addi` constants: `0x6875 6420` `hud `, `0x6174 6d6f` `atmo`,
  `0x6169 6c6f/6869` `ailo/aihi`, `0x6772 6f75/6869` `grou/grhi`, `0x706c 7368/6566/6179/7765/7569`
  `plsh/plef/play/plwe/plui`, `0x6465 6661` `defa`.

## 6. Render layers and order (answers Q6) [HIGH]
- **Sprite layers** (`FUN_10012fa0` `100130e8..10013260`; agrees with engine-loop.md §5):
  - `defa` → 3 (ground) / 7 (air)
  - `grou` 3, `grhi` 5, `ailo` 7, `aihi` 8, `plwe` 9, `play` 10, `plsh` 11, `plef` 12,
    `plui` 13, `atmo` 14, `hud ` 15
  - an unknown 4CC keeps template 7
  - terrain stamp → 1
- **Shadow layers:** 2 / 4 / 6, and 0 for stamps (§5.2).
- **Queue.** `FUN_10018a40` → `FUN_1001a450 @ 1001a450` appends a copy of the 0x4c-byte command
  to the list of its layer byte (`*(byte*)(cmd+0x30)`). Arrays: `_DAT_100df194` (list
  pointers), `_DAT_100df198` (counts); a full list doubles its size ("NOTE: Sprite Render List
  expanded"). The queued copy gets `+0x31 = 1`.
- **Flush.** `FUN_1001a650(L) @ 1001a650` draws layer L's commands in insertion order through
  `FUN_10019570`. Commands on layers 0 and 1 are turned to `none` after drawing.
- **Frame order.** `FUN_10018b20(p) @ 10018b20`: p 0 → layers 0, 1; p 1 → 2..5; p 2 → 6..15.
  End frame `FUN_10030bc0` calls them in this order:
  1. `FUN_10018b20(0)` (stamps and their shadows, drawn into the terrain buffer by flag 8 →
     port `DAT_100e0170`, initial 1 = display+0x6c via `FUN_1000ad90`)
  2. `FUN_10010120` (the terrain window to the screen buffer)
  3. `FUN_10018b20(1)` (ground shadows 2, ground units 3, `grhi` shadows 4, `grhi` units 5)
  4. `FUN_10043ba0` = particle draw, particles-debris-blur.md §2.9 [HIGH there] (⚑ corrected (review wave 2, 2026-10-03) #C5,
     was "not read")
  5. `FUN_10018b20(2)` (air shadows 6, `ailo`/air `defa` 7, `aihi` 8, player weapons 9,
     player 10, player shield 11, effects 12, `plui` 13, `atmo` 14, HUD 15)
- **Consequences:**
  - A shadow is always under every sprite of its band.
  - The player's shadow (layer 6) is under air units.
  - Within one layer the draw order is call order: groups in `FUN_100345f0` order, members in
    list order, the tint and hit passes right after their sprite.
- ⚑ conflict: engine-loop.md §5 says "shadows → layer 1". The listing gives 2/4/6, and 0 for
  terrain stamps. Layer 1 is the terrain-stamp *sprite*.

## Worked example
Frame sizes come from the alpha plates through the §2.2 scan (scratchpad `pf.py` = the
`frames()` function of `docs/deimos/tools/plate_frames.py`). Unit keys come from
`$W/data/Game/unde/*.txt`. The player ship sprite is **not in `plde`**: it is the air weapon's
`player1AppearanceFace_ID` (`FUN_10029f60`, player-physics.md §1). The starting weapon at
sector 1 is the Ion Cannon (weapons-projectiles.md §2.4) → `pl1o`.
| unit | sprite / frame | trimmed w×h | scale | half (hw, hh) | box at (200.0, 100.0) l,t,r,b | radius | draw layer | shadow |
|---|---|---|---|---|---|---|---|---|
| Player 1 ship (Ion) | `pl1o` 0 (all 7 bank frames 53×43) | 53×43 | 1.0 | 26, 21 | 174, 79, 226, 121 | 42×0.5 = **21.0** | `play` 10 | layer 6, 26×21 (trunc 26.5/21.5), at (−24, +52) |
| Flipper Mk 2 `fl02` (state 0 "Move South") | `raso` 18 | 38×38 | 1.0 (initialScale 100) | 19, 19 | 181, 81, 219, 119 | 38/2 = **19** | `aihi` 8 | castsShadows: layer 6, 19×19 at (−24, +52) |
| Tank - Laser `tala` (state 0) | `suta` 0 | 38×45 | 1.0 | 19, 22 | 181, 78, 219, 122 | 44/2 = **22** | `grou` 3 | castsShadows: layer 2, 38×45 at (−6, +8) |
- Player vs Flipper: they touch when the truncated distance is under 21 + 19 = **40** px
  (strict, damage-health-death.md §2.1), after the inclusive AABB test passes.
- **Player, scale 1.0, drawn at (200.0, 100.0).** Assume hOffset 0.
  - command x, y = 200, 100. Unscaled path: left = 200 − 26 = 174, top = 100 − 21 = 79.
  - on screen: columns 174..226 (53), rows 79..121 (43). The inclusive box is the same
    174..226 × 79..121.
  - shadow: x = trunc(200 − 24) = 176, y = 152, scale 0.5. Scaled path: W = 26.5, H = 21.5,
    left = trunc(176 − 13.25) = 162, top = trunc(152 − 10.75) = 141, size 26×21. The pixels
    under the half-size silhouette are darkened to 20/32.
- **Non-1 scale: Beamer Bullet `bebu`.** Keys: `initialScalePercent` 60, tolerance 0,
  `stateRequiredScalePercent` 100, `stateScaleDeltaPercent` 5, frame `bebu` 0 = 18×18, layer
  `ailo` (7), no shadow.
  - The scale walk, in float32, mimics `fadds` (numpy, scratchpad):
    0.6 → 0.65000004 → 0.70000005 → … → 0.9500001 → (1.0000001 clamped) **1.0** in 8 ticks.
  - At (200.0, 100.0):

| tick | s | w' = trunc(18·s) | hw = hh | box l..r (t..b) | radius | drawn columns |
|---|---|---|---|---|---|---|
| spawn | 0.6 | 10 | 5 | 195..205 (95..105) | 5 | trunc(200 − 5.4) = 194 .. 203 |
| 1 | 0.65 | 11 | 5 | 195..205 | 5 | 194 .. 204 |
| 2 | 0.70 | 12 | 6 | 194..206 | 6 | 193 .. 204 |
| 4 | 0.80 | 14 | 7 | 193..207 | 7 | 192 .. 205 |
| 6 | 0.90 | 16 | 8 | 192..208 | 8 | 191 .. 206 |
| 8 | 1.0 | 18 | 9 | 191..209 | 9 | (unscaled path) 191 .. 208 |
  - Because the step and refresh run before collision in the same tick (§2.3), the first
    collision test already sees s = 0.65.
  - The scaled image starts one px left of the box (194 vs 195). The unscaled one at 1.0 starts
    on the box edge.
  - Its radius against the player is 5 → 9, so the hit distance is under 26 → 30 px.

## NOT RESOLVED (this file)
1. ~~`FUN_10043ba0` (called between the ground and air layer flushes) — not read. Clouds/atmosphere
   overlay? Settles: read it.~~ → ⚑ corrected (review wave 2, 2026-10-03) #S: particles-debris-blur.md §2.9 (the particle
   draw, HIGH).
2. ~~Where the per-layer render lists of layers 2..15 are emptied each frame (`FUN_1001a650` only
   clears 0/1). A reset of `_DAT_100df198` counts must exist. Settles: xrefs to `_DAT_100df198`.~~ →
   ⚑ corrected (wave 3+4, 2026-10-04): `FUN_100189f0` zeroes the 16 layer counts at every begin frame (`10030388`)
   (blit-pixel-rules.md §7.1 and sprite-manager-resource-image.md §7 agree; INDEX #36).
3. ~~Writers of `DAT_100e0171` (queue "effects": alpha/scale forced off when 0), `DAT_100e0181`,
   and the callers of `FUN_1001a290`/`FUN_10019c00` (`FUN_10018740`). Settles: xref search on the
   raw `stb …,-0x61bf/-0x61af(r2)` displacements.~~ → ⚑ corrected (wave 3+4, 2026-10-04): only the FX (`1001afdc`) and ALPHA
   (`1001f060`, via `FUN_1001a290`) console handlers, both debugOnly and never registered → all three
   switches stay 1; `FUN_10019c00` is called once with (0, 1) (blit-pixel-rules.md §6,
   sprite-manager-resource-image.md §3.2 agree; INDEX #9). `DAT_100e0172` is `-0x61be(r2)`.
4. ~~That the console `SHADOWS` registration pointer (`0x100e0868`) reaches byte `0x100fb1c0`
   (`FUN_10006220`). Settles: read `FUN_1002d080` and what `0x100e0868` holds after init.~~ →
   ⚑ corrected (review wave 2, 2026-10-03) #M7a: `0x100e0868` = TVector of `0x10007e00` (SHADOWS), which flips `G+0x28` = the
   byte `FUN_10006220` reads; SHADOWS is unregistered, so the byte is 1 all session (§3.2).
5. ~~Writer of entity `+0x1a` (assumed `adjustShadowLocForScaling` U+0x12c). Settles: grep the
   raw listing of `FUN_10035cd0`/`FUN_100146f0` for `stb …,0x1a(`.~~ → ⚑ corrected (wave 3+4, 2026-10-04): closed for entities
   (blit-pixel-rules.md §7.2); the player's writer is its NR 4, and three reset/copy `stb …,0x1a(` sites
   are sprite-manager-resource-image.md NR 6.
6. ~~Scaled mode-2/3 blitters `FUN_1001c6c0`, `FUN_1001bcf0`, `FUN_1001c8f0`, `FUN_1001bfd0` (and
   modes 0/1 `FUN_1001c270/c480`, `FUN_1001b7d0/ba40`) — not read.~~ (⚑ corrected (wave 3+4, 2026-10-04): all read —
   nearest-neighbour, left/top-aligned integer sampling; per-mode formulas = the unscaled ones;
   blit-pixel-rules.md §5; INDEX #37.) Assumed to be the scaled
   twins of the unscaled formulas (sampling rule unknown: nearest? which source pixel for a
   given destination pixel). Settles: read one.
7. ~~Partial-alpha pixel branch of `FUN_1001dd20` (float factor lost in the decompile).~~ → ⚑ corrected (wave 3+4, 2026-10-04):
   α = trunc(a + 0.032·p²), skip ≥ 32 (blit-pixel-rules.md §3.1).
8. ~~`FUN_10005ce0` meaning (game block +0x1c; the terrain-stamp once-per-tick guard).~~ →
   ⚑ corrected (review wave 2, 2026-10-03) #C5 #S: game time getter `G+0x1c` (messages-notices-console.md role row
   `FUN_10005ce0`, HIGH).
9. Negative frame numbers in `FUN_10019ad0` pass the `n < count` check and index before the
   array (no data case known).

## Role-table rows (for merge)
| function | module | role | conf | evidence |
|---|---|---|---|---|
| ⚑ corrected `FUN_10019ca0` | U_Sprite.cc | U_Sprite_GetDimensions(id, frame, &wh, scale f1): load-on-miss, w' = trunc(w·s), h' = trunc(h·s) | HIGH | listing `10019e34–10019eb8` (was MED "sprite dimensions / draw frame", strings) |
| `FUN_10019c10` | U_Sprite.cc | same, from a frame pointer | HIGH | listing `10019c10–10019c98` |
| `FUN_10019ad0` | U_Sprite.cc | frame pointer of (group id, frame); out of range → frame 0 + log | HIGH | listing `10019b4c–10019bc4` |
| `FUN_10019530` | U_Sprite.cc | sprite group loaded? | HIGH | listing |
| `FUN_10018d20` | U_Sprite.cc | (add) asserts frame w ≤ 300, h ≤ 256 (`kU_Sprite_MaxDimensions`) | HIGH | listing `100191ac`, `100191d4` |
| `FUN_1001a2a0` | U_Sprite.cc | sprite manager integrity check (magic, w ≤ 300, h ≤ 256, depth ≤ 16) | HIGH | listing `1001a394`, `1001a3b4`; string |
| ⚑ corrected `FUN_10012940` | G_GameObject (span) | half-size refresh when dirty: wh = GetDimensions(sprite, frame, scale +0x84); +0x2c/+0x30 = w/2, h/2 | HIGH | listing `10012940–100129fc` (was MED, scale arg unread) |
| `FUN_10012f20` | G_GameObject (span) | draw entry: if visibility > 0 → shadow (if +0x38 and SHADOWS) then sprite (if +0x37) | HIGH | listing `10012f20–10012f9c` |
| ⚑ corrected `FUN_10012fa0` | G_GameObject (span) | build draw command; layer from 4CC; terrain-stamp mode; fade alpha; main / tint / hit-glow passes | HIGH | listing `10012fa0–10013450` (role widened) |
| ⚑ corrected `FUN_10013460` | G_GameObject (span) | shadow: layer 2/4/6 (0 stamp), air = half-size at (−48,104)·0.5[·s], ground = (−6,8)·s; mode 2, alpha max(20, fade) | HIGH | listing `10013460–10014040` (was MED, perm F48-51) |
| `FUN_10010c20` | G_GameObject (span) | visibility % → alpha: min(32, trunc(|32v/100 − 32|)) | HIGH | listing `10010c20–10010c90` |
| `FUN_10006220` | G_Game? | SHADOWS console flag (`*(0x100defd0)+0x28`, 1 before console init) | HIGH | listing `10006220–1000623c` |
| ⚑ corrected `FUN_100345f0` | G_EntityGroup.cc | per group: debug labels + shadow pass (castsShadows), then **sprite pass** of every spawned member | HIGH | listing `10034a98–10034b5c` (was MED "labels + shadow draw") |
| `FUN_10018a40` | U_Sprite.cc | queue or draw a command (when `DAT_100e0171` is 0: alpha 0, scale 1) | HIGH | listing `10018a40–10018b10` |
| `FUN_1001a450` | U_Sprite.cc | append command to the per-layer render list (grows ×2) | MED | dump; strings "Sprite Render List expanded" — ⚑ label audit (review wave 2): was HIGH on dump + strings |
| `FUN_1001a650` | U_Sprite.cc | flush one render layer; layers 0/1 consumed | MED | dump — ⚑ label audit (review wave 2): was HIGH on dump |
| `FUN_10018b20` | U_Sprite.cc | flush layer bands: 0 → {0,1}, 1 → {2..5}, 2 → {6..15} | HIGH | dump; ⚑ label audit (review wave 2): HIGH kept on the raw listing (`$W/disasm-review2.txt`): `10018b54 li r3,0x0; bl 0x1001a650; li r3,0x1; bl` (band 0), `10018b68..10018b84` `li r3,0x2..0x5` (band 1), `10018b8c..10018bd8` `li r3,0x6..0xf` (band 2); `10018b44 b 0x10018bdc` = the argument < 0 exit (no flush), `10018b48 cmpwi r0,0x3; bge` = ≥ 3 exit |
| `FUN_1001a6f0` / `FUN_1001aa90` | U_SpriteBlit.cc | scaled blit (unclipped / clipped): centred, size trunc(w·s), mode by stack byte | HIGH | listing `1001a75c–1001a7e8`, `1001ab0c–1001ab80` |
| `FUN_1001dd20` | U_SpriteBlit.cc | mode 2 shadow blit: dst·a/32 under the silhouette | HIGH | dump; ⚑ corrected (review wave 2, 2026-10-03) #M3: listing `1001ddb4 lhz r3,0(r26); andi. r0,r3,0x7c1f; rlwimi r0,r3,0xf,0x7,0xb; mullw r3,r0,r21; rlwinm r0,r3,0x1b,0x5,0x1f; andi. 0x7c1f; rlwimi r0,r3,0xc,0x16,0x1a; 1001ddd0 sth` (reviewer-confirmed) |
| `FUN_1001df00` | U_SpriteBlit.cc | mode 3 tint blit: (dst·a + colour·(32−a))/32 under the silhouette | HIGH | dump; ⚑ corrected (review wave 2, 2026-10-03) #M3: listing `1001df94 subfic r12,r8,0x20` (32−a), `1001dfa8 mullw r31,r31,r8` (dst·a), `1001dfac mullw r12,r30,r12` (colour·(32−a)), `1001dfb0 add`, `1001dfb4..1001dfbc` repack, `1001dfc0 sth` (reviewer-confirmed) |
| `FUN_1001a260` | U_Sprite.cc (span) | percent int → float /100 | HIGH | listing `1001a260–1001a28c` |
| `FUN_1001a290` | U_Sprite.cc (span) | set `DAT_100e0172` (scaled alpha maps on/off) | MED | dump — ⚑ label audit (review wave 2): was HIGH on dump |
| `FUN_10019c00` | U_Sprite.cc (span) | set port indices `DAT_100e0179` (normal) / `DAT_100e0170` (flag 8) | MED | dump; caller `FUN_10018740` — ⚑ label audit (review wave 2): was HIGH on dump |
| `FUN_1004d5c0` | MSL runtime | double → unsigned int | HIGH | listing |
| ⚑ corrected `FUN_10012840` | G_GameObject (span) | scale step +0x84 → +0x88 by +0x8c, clamp, dirty +0x34 | HIGH | listing `10012840–100128b0` (was MED dump) |
| `FUN_1000a530` | M_Display.cc (span) | copy a port's bounds rect (+0x1c..+0x28) | MED | dump only |
| `FUN_1000ad90` | M_Display.cc | display port by index 0/1/2 → +0x68/+0x6c/+0x70 | MED | dump |
| `FUN_10019ee0` | U_Sprite.cc | frame count of a group (error message only) | LOW | caller context, not read — ⚑ corrected (wave 3+4, 2026-10-04): read — HIGH in sprite-manager-resource-image.md §2 / function-roles.md |
| `FUN_10043ba0` | G_Particle (span) | particle draw, between layer bands 1 and 2 | HIGH | particles-debris-blur.md §2.9 listing `10043ba0..10044500` — ⚑ corrected (review wave 2, 2026-10-03) #C5: was LOW "not read" |
| `FUN_1001c270` `FUN_1001c480` `FUN_1001c6c0` `FUN_1001c8f0` `FUN_1001b7d0` `FUN_1001ba40` `FUN_1001bcf0` `FUN_1001bfd0` | U_SpriteBlit.cc | scaled blit modes 0–3 without / with alpha map | LOW | callers in `FUN_1001a6f0` only, not read — ⚑ corrected (wave 3+4, 2026-10-04): all eight read — HIGH rows in blit-pixel-rules.md / function-roles.md (§5 sampling rule) |
Also touched, not read (roles stand in the bank or are generic): `FUN_10014060` (4CC → text),
`FUN_10049550` (log), `FUN_1001f950` (G_Res_Load), `FUN_1001fc30`, `FUN_10002420`,
`FUN_10000ce0`/`FUN_10000e10` (list count / iterate), `FUN_10000ed0`/`FUN_10000f80`/`FUN_10000e70`
(asserts), `FUN_1002dbd0` (console text), `FUN_1000a4a0`, `FUN_1001ec80`, `FUN_10012750`,
`FUN_10010120`, `FUN_10005ce0` (game time getter `G+0x1c`, HIGH in messages-notices-console.md;
⚑ corrected (review wave 2, 2026-10-03) #C5, was LOW).

## INDEX updates (for merge)
- **#8 closed** → this file §1.1: `kU_Sprite_MaxDimensions` = {width 300, height 256},
  inclusive; shipped maxima 218 × 110.
- **#9 residue narrowed** → §4.4 / NR 3: `DAT_100e0181` initial value 1 (image). The sibling
  switches are `DAT_100e0172` (setter `FUN_1001a290`) and `DAT_100e0171`. Writers are still open.
- **damage-health-death.md §2.2 open point** (scale argument of `FUN_10019ca0`) → §2.2: it is the
  entity scale `+0x84`, refreshed every tick before collision.
- **player-physics.md NR 8** → §4: `+0x68` → alpha `trunc(32 − 0.32·v)`, not drawn at ≤ 0.
  `+0x58` → a colour-silhouette pass covering g% × own opacity. `+0x84` → the scaled blit.
- **⚑ conflict with engine-loop.md §5** ("shadows → layer 1") → §5.2/§6: shadows are on layers
  2/4/6, and 0 for terrain stamps.
- New NOT-RESOLVED candidates: NR 1 (`FUN_10043ba0`), NR 2 (render-list reset), NR 6 (scaled
  blit sampling).
