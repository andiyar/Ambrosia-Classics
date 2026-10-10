# Ferazel's Wand 1.0.3 — the player sprite (2): tile kinds, `.HitPlayerTileSprite`, census

Code readings only; nothing behaviour-verified. Date 2026-10-03. Continuation of
`player-states.md` (same sources and labels). Scope: `.HitPlayerTileSprite @ 10054ca8` (handler
dump l. 2909–3152), `.WallBounce @ 10037a54` (main dump l. 32854–33885), `.WallBounceBG @ 1003a2e8`
(main dump l. 33888–34556), the hot-rect table reads, and a census of collision kinds over the
24 shipped `Mlvl` resources. Closes INDEX NOT-RESOLVED 5 except where listed at the end.
⚑ wave 2 (2026-10-04): §12–§15 close the rest of INDEX 5 and the INDEX 26 rows of this file (kind
readers, `.CrunchTile`'s return and the crunch kinds, the as-written oddities, the leftover globals);
sources as before plus `PICT 185` decoded with an own PackBits reader.

Notation: the tile cell's top-left is (X, Y) (px). The mover's hot rect in world px is T (top),
L (left), B (bottom), R (right); "c" = the **centred** left (`x + (rectL + rectR)/2`), c + 1 the
centred right (§9.1). "Push to L = X+16" means set integer x so that the rect's left edge lands
there. "Land" = if `vy > 0`: `vy = 0` (or the slope rule), `s+0xce = kind`. "Ceiling" = if `vy < 0`:
`s+0xcf = kind`, `vy = 0`. `slip` = `s+0x112` (ice, physics §3.3). The player passes bounce factor 0
and bounce flag 0 (handler dump l. 3055, 3123), so the bounce arms (`v × f >> 8`, reflected) never
run for the player; they are listed only as "(bounce arm)".

## 9. `.WallBounce` (solid FG kinds; BG kinds < 100)

### 9.1 Pre-processing  [HIGH, raw `10037a54..10037c78`]
1. `while (k > 99) { k −= 100; material++ }`; `k < 0` or `k > 0x3c` → return 0.
2. **Centring**: for every kind except 0, 2, 8, 0xb, 0xd, 0xe, 0x24..0x2b the local rect copy gets
   `left = (rectL + rectR) >> 1` (kind 4 keeps its left) and `right = that + 1` (kind 7 keeps its
   right): floors and slopes test a 1-px column at the sprite's centre.
3. Integer x/y refreshed from the 24.8 position.
4. `k < 0x30` only: intersect the tile rect **`DAT_100a4794 + 0x14·k + 4`** (offset by X, Y) with
   the (centred) mover rect; no overlap → return 0. That field is the per-**FG-tile** hot rect
   written by `.InitTileHotRects`' first loop (index = tile number, physics §3.2), here indexed by
   the **kind** — so the test uses the hot rect of FG tile number `k` of the current level
   (raw `10037b8c..10037bc0`: `mulli r3,k,0x14`, base `r2−0x30ac` = 0x100a4794, reads +4..+0xa).
   The per-kind rects that loop 3 builds at `+0xc` are read only by `.SeparateFromTiles2`'s dead
   second loop (raw `1003ce74..1003cea0`). Census (§11): in all 24 levels, for every kind k < 0x30
   that occurs, FG tile #k has a kind ≡ k (mod 100), so the per-tile rect equals the natural
   one — the mis-index has **no effect on shipped data** [HIGH on the census; ~~LOW that it is a slip~~ intent UNDETERMINABLE, ⚑ wave 2 (2026-10-04) §14].
5. `k == 0x3c` → `k = 3`, `Y −= 8` (a half-floor 8 px higher; never in FG data, BG only as 160).
6. Switch on k (jump table at `r2−0x236c` = 0x100a54d4, 0x3a entries; `k > 0x39` → default).
7. After a resolution (return 1): player only (`s == *_DAT_1009fdd8`) and an ice slide happened
   in this call and no bounce: `vy < 0 → 0`; `y += 2` and `vy += 0x200` if `vy > 0` (a `y += 1`
   arm for kinds 0x13/0x14 is unreachable: slides happen only in the base-kind recursion);
   `s+0xd0 = 0` (not on a one-way top); 24.8 x/y re-synced only if the integer changed; material
   > 0 → `s+0xd8 = material` (physics §3.3) [HIGH].

### 9.2 Kind table  [HIGH, main dump l. 32948–33840 unless noted]

| k | shape (tile-local) | resolution |
|---|---|---|
| 0 | left half wall | if L < X+16: `vx < 0 → 0`; push L = X+16 (uses the real left edge) |
| 1 | top half slab | if T < Y+16: ceiling; push T = Y+16 |
| 2 | right half wall | if R > X+16: `vx > 0 → 0`; push R = X+16 |
| 3 | bottom half floor | if B > Y+16: land; B = Y+16 (no from-above test: any overlap lands) |
| 4 | bottom-left quarter | x, y ← last frame's integers (`+8`, `+6`); if `(Y+32 − Bprev) < (Lprev − X)` and `vx ≤ 0`: `vx = 0`, push L = X+16 (real left edge); else land on Y+16. (`Bprev = B − vy>>8`, `Lprev` = restored left − `vx>>8`) |
| 5 | top-left quarter | restore; if `(T − Y) < (c − X)` (pre-restore rect): `vx = 0`, push c = X+16; else ceiling, T = Y+16 |
| 6 | top-right quarter | restore; if `(T − Y) < (X+32 − (c+1))`: `vx = 0`, push c+1 = X+16; else ceiling, T = Y+16 |
| 7 | bottom-right quarter | restore; if `(Y+32 − Bprev) < (X+32 − Rprev)` (no vx sign test, unlike 4): `vx = 0`, push R = X+16 (real right edge); else land on Y+16 |
| 8 | top half + right half (empty bottom-left) | hit if the rect meets `(X,Y,X+32,Y+16)` or `(X+16,Y,X+32,Y+32)` (the first rect's bottom is the register left from the switch prologue, raw `10037c5c`/`100385c4`: Y+16); if `(X+32 − R) < (T − Y)`: `vx > 0 → 0`, R = X+16; else `vy < −1 → −1`, T = Y+16; then clamp R ≤ X+16 **and** T ≥ Y+16 |
| 9 | bottom half + right half (empty top-left), centred | rects `(X,Y+16,X+32,Y+32)`, `(X+16,Y,X+32,Y+32)`; if `(X+32 − R) < (Y+32 − B)`: R = X+16; else land, B = Y+16; clamp R ≤ X+16, B ≤ Y+16 |
| 0xa | left half + bottom half (empty top-right), centred | rects `(X,Y,X+16,Y+32)`, `(X,Y+16,X+32,Y+32)`; if `(L − X) < (Y+32 − B)`: `vx < 0 → 0`, L = X+16; else land, B = Y+16; clamp L ≥ X+16, B ≤ Y+16 |
| 0xb | top half + left half (empty bottom-right) | rects `(X,Y,X+32,Y+16)` (same register bottom), `(X,Y,X+16,Y+32)`; if `(L − X) < (T − Y)`: L = X+16; else `vy < −1 → −1`, T = Y+16; clamp L ≥ X+16, T ≥ Y+16 |
| 0xc | 45° floor "\" (solid lower-left) | `s = clamp(c − X, 0, 32)`; if B > Y+s: land with **`vy = |vx| + 0x100`**; B = Y+s; ice: `vx += 7.07·slip`, then if `vx < 0`: `vy = vx + 0x300` |
| 0xd | 45° ceiling (solid upper-left) | `s = clamp(32 − (L − X), 0, 32)` (real left); if T < Y+s: ceiling, T = Y+s |
| 0xe | 45° ceiling (solid upper-right) | `s = clamp(R − X, 0, 32)` (real right); if T < Y+s: ceiling, T = Y+s |
| 0xf | 45° floor "/" (solid lower-right) | `s = clamp(32 − (c+1 − X), 0, 32)`; land `vy = |vx| + 0x100`; B = Y+s; ice: `vx −= 7.07·slip`, if `vx > 0`: `vy = 0x260 − vx` |
| 0x10..0x1f | composites: recurse into `.WallBounce` with a base kind chosen by the centre column against X+16 (or the top against Y+16) | table §9.3 |
| 0x20 / 0x21 | 1:2 floor "\", left / right tile | `s = (c − X)>>1` clamped 0..16 / `+16` clamped 16..32; land `vy = |vx|/2 + 0x100`; ice: `vx += 3.82·slip`, then if not bouncing `vy = max(vy, vx>>1)` |
| 0x22 / 0x23 | 1:2 floor "/", low / high tile | `s = 32 − ((c+1 − X)>>1)` clamped 16..32 / `16 − (…)` clamped 0..16 (then 0..32); land as 0x20; ice (not bouncing): `vx −= 3.82·slip`, `vy = min(vy, −(vx>>1))` |
| 0x24 / 0x25 | 1:2 ceiling, surface 32→16 / 16→0 left to right | `s = 32 − ((L − X)>>1)` clamped 16..32 / `16 − …` clamped 0..16 (real left); ceiling, T = Y+s |
| 0x26 / 0x27 | 1:2 ceiling, surface 0→16 / 16→32 | `s = (R − X)>>1` clamped 0..16 / `+16` clamped 16..32 (real right); ceiling |
| 0x28 / 0x29 | 2:1 ceiling, right / left half | `t = L − X`; 0x28: `s = clamp(32 − 2(t − 16), 0, 32)`; 0x29: `s = clamp(32 − 2t, 0, 32)` only if `t ≤ 16`; ceiling |
| 0x2a / 0x2b | 2:1 ceiling, left / right half | `t = R − X`; 0x2a: `s = clamp(2t, 0, 32)`; 0x2b: `s = clamp(2(t − 16), 0, 32)` only if `t ≥ 16`; ceiling |
| 0x2c / 0x2d | 2:1 floor "\", right half of the upper tile / left half of the lower | `t = c − X`; 0x2c: `s = clamp(2(t − 16), 0, 32)`; 0x2d: `s = clamp(2t, 0, 32)` only if `t ≤ 16`; if B > Y+s: **`vy = 2|vx| + 0x100` and `s+0xce = k` even when rising** (no `vy > 0` test, raw `10039824..10039844`); ice: `vx += 9.23·slip`, then `if (vy < 2·vy) vy = 2·vx` (i.e. when `vy > 0`; raw `100398bc..100398d4`) |
| 0x2e / 0x2f | 2:1 floor "/", left half / right half | `t = c+1 − X`; 0x2e: `s = clamp(32 − 2t, 0, 32)`; 0x2f: `s = clamp(32 − 2(t − 16), 0, 32)` only if `t ≥ 16`; land unconditionally as 0x2c; ice: `vx −= 9.23·slip`, `if (−2·vy < vy) vy = −2·vx` |
| 0x30, 0x31 | — | no case: return 0 (no collision) |
| 0x32..0x35 | 1:4 floor "\", four tiles | `t = c − X` (**not clamped**); `s = (t + 0 / 0x20 / 0x40 / 0x60) >> 2` (8 px of drop per tile, raw `10039e60..10039edc`); land `vy = |vx|/2 + 0x100`; ice: `vx += 2.86·slip`, not bouncing → `vy = max(vy, vx>>1)` |
| 0x36..0x39 | 1:4 floor "/", four tiles | `t = c − X`; `s = ((32 − t) >> 2) + 24 / 16 / 8 / 0`; land as 0x32; ice: `vx −= 2.86·slip`, then the same `vy = max(vy, vx>>1)` as 0x32 (not mirrored) |
| 0x3a, 0x3b | — | default: return 0 |
| 0x3c | half floor 8 px higher | → kind 3 with Y − 8 (step 5) |
⚑ planner-probe (Phase 2 plan A6, landed by F3 2026-10-10): "last frame's integers" for kinds 4–7 (and
`.WallBounceBG` 4/7) are `+0x8`/`+0x6`, which `.SeparateFromTiles2` writes from the 24.8 position **at the entry of
every call** (raw `1003c82c..1003c844`; `.ApplySpeedAndSeparateFromTiles` also writes them before each
separation, `.ApplyGravityAndSeparateFromTiles` after its last) — so the revert goes to the position the current separation started from (the
current integration sub-step), not to the previous frame's position [HIGH]. Kind 3 stores `B = Y+16` outside its
`vy > 0` test: a rising sprite overlapping a kind-3 rect is still put on Y+16, it only does not land (`+0xce`, vy
kept) [HIGH, decompile case 3 = raw `10037de8..`].
Slip factors are f64 constants: 7.07 (`0x100a1910`), 3.82 (`0x100a1908`), 9.23 (`0x100a1900`), 2.86
(`0x100a18f8`) (`tools/const.py`); a slide is applied at most once per `.SeparateFromTiles2` call per sprite (latch
`s+0x181`, cleared at every call's entry, raw `1003c868` — so a sprite separated several times in a frame can slide
several times; ⚑ F3 review correction of "once per frame"). Labels: arithmetic [HIGH]; the shape glosses ("\" etc.) are [MED] (derived from the
surface formulas, not from tile art).

### 9.3 Composite kinds 0x10..0x1f (recursion; `c` = centred left, `c+1` = centred right)  [HIGH]

| k | test → base kind if true / else | k | test → true / else |
|---|---|---|---|
| 0x10 | c < X+16 → 3 / 0xc | 0x18 | c > X+16 → 3 / 0xc |
| 0x11 | T > Y+16 → 0xd / 0 | 0x19 | c < X+16 → 0 / 0xd |
| 0x12 | c+1 > X+16 → 1 / 0xe | 0x1a | c+1 < X+16 → 1 / 0xe |
| 0x13 | c+1 < X+16 → 2 / else 0xf if `(y + vCentre) + rectB > 16` | 0x1b | c+1 > X+16 → 2 / 0xf |
| 0x14 | c > X+16 → 0 / 0xc | 0x1c | c < X+16 → 0 / 0xc |
| 0x15 | c < X+16 → 1 / 0xd | 0x1d | c > X+16 → 1 / 0xd |
| 0x16 | T < Y+16 → 2 / 0xe | 0x1e | c+1 > X+16 → 2 / 0xe |
| 0x17 | c+1 > X+16 → 3 / 0xf | 0x1f | c+1 < X+16 → 3 / 0xf |
The recursive call gets the original (uncentred) rect, so base kinds 0/2/0xd/0xe then use the real
edges. 0x13's second test compares an absolute y (`y + *param_4 + rectB`, `param_4` = the hot
rect's vertical-centre offset `sStack_72`, handler dump l. 2952) with 16, so for any on-map y it is
true and 0x13 ≡ (2 / 0xf) [HIGH as written; ~~LOW that a tile-relative test was meant~~ intent UNDETERMINABLE, ⚑ wave 2 (2026-10-04) §14]. The `default`
arm's "copy position to old position for 0xb < k < 0x20" is unreachable (all have cases).

## 10. `.HitPlayerTileSprite @ 10054ca8` (handler dump l. 2909–3152)  [HIGH]
`tileHit(s, (Y,X), kind, layer)` from `.SeparateFromTiles2` (physics §3.1); `vCentre` /
`hCentre` = hot-rect centre offsets (l. 2950–2953).
1. Spirit form (`_DAT_100a0578 > 0`) → return (passes through every tile).
2. Walk-on power-up active and BG water kind = power-up kind → treated as FG kind 3 at Y − 16
   (floor surface at the cell top).
3. **FG (layer 1)**: `k = kind mod 100`; `dy = (y + vCentre) − (Y + 16)`.
   - Cling test: `vx < 0` and (LEFT or clinging last frame): k = 0 → cling; k ∈ {4, 0x14, 0x2d}
     → ledge kind, cling iff `dy > 0`; k = 5 → cling iff `dy < 4`; side 1. Mirror with `vx > 0`,
     RIGHT: 2; {7, 0x13, 0x2f}; 6; side 2. Gate: not grounded last pass, not on a rope, no-cling
     timer 0, not gliding. Cling: if not clinging last frame → jump counter 0 and cling sound
     `_DAT_100a0374` (3D random, vol 0x3c); climb = 1; F = side; launched 0; swim 0; wall side;
     `s+0x17e` = 1 for side 1. Ledge kind and no pull-up running: cell above (FG at column X>>5,
     row (Y>>5) − 1) empty → if `(y + vCentre − 4) − (Y + 16) < 1` start the pull-up (sound
     `_DAT_100a03f0` vol 0xab); cell above occupied → `y += 1000/256` px, `vy = 0`, climb = 1
     (cannot climb past a covered ledge). Every cling frame ends with `vx = vy = 0`.
   - Post-jump guard `PTR_DAT_100a04d8 > 0` → return (no FG resolution for 2 frames after a jump
     or wall jump; the cling test above still ran).
   - `.WallBounce(s, kind with hundreds, …, 0, hotRect, 0, 0)`; on a hit: carpet lock 2, and
     when riding a carpet the carpet is lifted so its hot-rect top meets the player's hot-rect
     bottom and its vx zeroed when the player's vx ≤ 0xff (always: the rider's vx is forced 0).
     Then `.CheckGroundCeilingHitEffects` (physics §8.7).
4. **Crunch (layer 2)**: crunch-capable `s+0xeb = (crunch cooldown PTR_DAT_100a060c == 0) ∧
   vy > 0x9c4` (overwriting the per-frame `spin ∨ grounded` value that let the call happen);
   `.CrunchTile(pos, eb)`; if it returns non-zero and eb: `.RectBounceFake2`, position re-synced,
   `vy' = (int)(−0.9·vy)` (`dRam100a1a20` = −0.9); DOWN held → spin on, spin sound,
   `vy = −|vy'|`; else spin off, spin sound stopped, `vy = 0`; cooldown 5; `s+0xce = 0`.
5. **BG (layer 0)**: `kind < 100` → `.WallBounce` (fully solid, includes −1 which returns at once);
   100..199 → `.WallBounceBG(kind − 100)` and, if it hit while grounded, `PTR_DAT_100a04cc = 15`;
   both then `.CheckGroundCeilingHitEffects`. 600/601 → ignored. 200..209 (`.IsWaterTile`) →
   `.HandleUnderWater` **only in the end-of-frame pass** (`PTR_DAT_100a0704`, set at l. 2681 and
   cleared at l. 1065) and only if `s+0x140 == 0`. Every other BG kind (210..599, ≥ 602,
   including the census' 400..495) is ignored by the player.

### 10.1 `.WallBounceBG @ 1003a2e8` — one-way BG tops  [HIGH]
`k = kind − 100` with no hundreds loop; `k < 0` or `> 0x3c` → 0; integer position refreshed;
k < 0x30: the same mis-indexed tile rect test, against the **uncentred** rect; 0x3c → 3 at Y − 8;
switch on k − 3 (table `r2−0x2284` = 0x100a55bc, kinds 3..0x2f; others → no collision).
- Floors land only from above: kind 3 needs `Bprev = B − vy>>8 ≤ Y+17`; slopes 0xc, 0xf,
  0x20..0x23, 0x2c..0x2f need `Bprev ≤ Y+s+3`, sample the surface at the **previous** x
  (`x − vx>>8`) on the real left (0xc, 0x20/0x21, 0x2c/0x2d) or right edge (others), land with
  the same `vy` rule as `.WallBounce` but only when `vy > 0` (also for 0x2c..0x2f), apply the
  ice `vx` slide, and have no `vy` coupling and no post-slide `+2 px`.
- **BG kind 0xc samples `x − vy>>8`** (`+0x2c`, raw `1003a708 lwz r5,0x2c(r31)`) where every
  other case uses vx — ~~a slip in the original~~ as written, intent UNDETERMINABLE (⚑ wave 2 (2026-10-04) §14); no shipped level has BG kind 112 (§11).
- Kinds 4 / 7: position reverts to last frame's integers; if `(Y+32 − B) < (L − X)` (4) /
  `(X+32 − R)` (7) the routine returns "hit" with only that revert; else lands on Y+16 when
  `Bprev ≤ Y+19`, otherwise no hit (but the revert stays).
- Ceilings 0xd, 0xe, 0x24..0x2b resolve like `.WallBounce` (two-way, no from-below test; 0xd/0xe
  at the previous x).
- Composites 0x10..0x1f choose as §9.3 using previous-x edges and then call **`.WallBounce`**
  (the two-way solver) with the base kind.
- Kinds 0, 1, 2, 5, 6, 8..0xb, 0x30..0x3b: nothing.
- On a hit: `s+0xd0 = 1` (one-way top) and the 24.8 position is always re-synced (sub-pixel lost).
Upgrades physics §3.3's "[LOW for one-way]".
⚑ F3 follow-the-binary (2026-10-10, decompile l. 34114–34792): two rows above are incomplete. (1) Kinds 4 / 7:
after the revert, when `y + bottom ≤ Y+16` (the reverted y) the routine **reports a hit** with only the revert
(`uVar7 = 1` set before the test); the no-hit case is only `y + bottom > Y+16 ∧ Bprev > Y+19`. (2) The composites
do not all test previous-x edges: 0x11 (`Y+16 < T` → 0xd / 0), 0x13 (`Y+16 < B` → 2, else `y + vC + B > 16` → 0xf,
else none), 0x14 (`Y+16 < B` → 0 / 0xc) and 0x16 (`T < Y+16` → 2 / 0xe) test the current y; the others use
`L/R − (vx >> 8)` as §9.3 with `.WallBounce`'s choices (raw `1003a960..1003a96c` for 0x14) [HIGH].

## 11. Kinds in the shipped levels (Python over all 24 `Mlvl`: FG table hdr+0x28e0, BG table
hdr+0x29a0, tiles 0x50..0x5f forced to kind = tile as `.LoadTileDefinitions` does, FG/BG maps per
world-data §3.1/§3.3; script in the session scratchpad `ps/kinds.py`)  [HIGH]

FG cells by kind mod 100 (material-0 count; materials in brackets):

| k | cells | k | cells | k | cells | k | cells |
|---|---|---|---|---|---|---|---|
| 0 | 4668 | 0xc | 386 (+10 ice) | 0x18 | 87 | 0x24 | 563 |
| 1 | 10534 | 0xd | 94 | 0x19 | 39 | 0x25 | 564 |
| 2 | 4620 | 0xe | 58 | 0x1a | 29 | 0x26 | 483 |
| 3 | 9302 (+28 m1, +340 m2, +501 ice) | 0xf | 330 (+23 ice) | 0x1b | 153 | 0x27 | 501 |
| 4 | 700 (+23 ice) | 0x10 | 15 | 0x1c | 144 | 0x28 | 55 |
| 5 | 1406 | 0x11 | 24 | 0x1d | 37 | 0x29 | 46 |
| 6 | 1518 | 0x12 | 27 | 0x1e | 29 | 0x2a | 69 |
| 7 | 707 (+21 ice) | 0x13 | 118 (+4 ice) | 0x1f | 106 | 0x2b | 52 |
| 8 | 1473 | 0x14 | 123 (+5 ice) | 0x20 | 671 (+49 ice) | 0x2c | 8 |
| 9 | 664 (+7 ice) | 0x15 | 27 | 0x21 | 700 (+55 ice) | 0x2d | 4 |
| 0xa | 671 (+8 ice) | 0x16 | 11 | 0x22 | 704 (+80 ice) | 0x2e | 19 |
| 0xb | 1374 | 0x17 | 9 | 0x23 | 663 (+73 ice) | 0x2f | 15 |
| 0x32..0x35 | 93/95/91/91 | 0x36..0x39 | 85/85/87/85 | 0x4e/0x4f | 91/86 (no `.WallBounce` case) | 80..93, 95 | 3,435 + 138,322 (decor; ignored) |
Never present in FG: 0x30, 0x31, 0x3a..0x4d, 0x5e (94); 0x3c only as BG 160. The 1:4 slopes
0x32..0x39 and kinds 0x4e/0x4f occur only in 22, 40, 45, 62, 70 (+0x32/0x33 not in 45).
Materials: **1** = level 67 only (28 cells of 103; no reader of `s+0xd8 == 1` in either dump →
plain floor); **2** (damaging) = kind 203 only, 340 cells in levels 1, 2, 4, 11, 15, 21, 22, 31,
50, 62; **3** (ice) = levels 30 and 31 only, on kinds 3, 4, 7, 9, 0xa, 0xc, 0xf, 0x13, 0x14,
0x20..0x23 (and 380/381/388/389, ignored decor). Level 67's FG grid has only those 28 kinded cells.
BG kinds: < 100 solid only in level 45 (The Dig: kinds 1..11, 1,554 cells, plus 5,663 of 95);
one-way 103 (525 cells, 19 levels), 104 (5) and 107 (6) in levels 1/51/67, 160 (= 0x3c, 166 cells
in 3, 20, 22, 25, 30, 31, 40); liquids 200..205 (physics §5.1); 400..483 and 495 (21,112 cells in
11, 18, 22, 30, 31, 40, 62) — ignored by the player (§10 item 5) ~~[NOT RESOLVED: other readers]~~ (⚑ wave 2 (2026-10-04): no reader at all, §12).

## 12. Wave 2 (2026-10-04): who reads FG kinds 0x4e/0x4f and BG kinds 400..495 (NR 1)  [HIGH]
Method. A tile kind is read only through `.LookupFGTileKind @ 10041fe8` / `.LookupBGTileKind @ 10041f98`:
their tables `_DAT_100a0218` / `_DAT_100a0214` have no other TOC load than `.LoadTileDefinitions`
(`tocrefs`), and the header tables hdr+0x28e0 / hdr+0x29a0 appear only there (`10041df4`/`10041df8`, the
only `0x28e0`/`0x29a0` operands in the listing). Every call site was read: 8 × `bl 0x10041fe8`, 26 ×
`bl 0x10041f98`, the tile-callback dispatch of `.SeparateFromTiles2` (main l. 35293–35343) and the kind
tests of all 22 `Hit*TileSprite` routines.

FG kinds 0x4e / 0x4f (78 / 79; 91 / 86 cells, only in levels 22, 40, 45, 62, 70 — §11):

| reader | use | raw |
|---|---|---|
| `.SeparateFromTiles2` → every class's tile callback (layer 1) | → `.WallBounce`, which returns 0 for `k mod 100 > 0x3c` (§9.1 step 1); the player's cling test lists only 0, 2, 4–7, 0x13, 0x14, 0x2d, 0x2f: **no collision** | `1003caf4`, `10037a54..` |
| `.PlainWrapFGTile`, `.RedrawScrollGrid` | `k = kind mod 100` selects **blend face k** of `PICT 185` through which the level's pattern tile is mixed into the cell (sprites-backgrounds-sounds §3.1 step 2) | `10012bd0..10012c04`, `10013870..100138a0` |
| `.LoadEncWaterFaceSetFromPICT` | kind 0..0x5f selects the FG-water-mask cell (`PICT 183`) stamped into the water copy of the tile | `1002f7d0..1002f7f0` |
| `.InitTileHotRects` | per-kind rect switch (no 0x4e/0x4f case → default); feeds only the overlap pre-test | `10002858..10002890` |
| `.ReshapeCrunchedTile` | neighbour-kind switch: no 0x4e/0x4f case | `10043f54..` |

So 0x4e/0x4f are **draw-only kinds**: no solidity, only a blend shape. `PICT 185` cells 0x4e/0x4f
decoded (weights per sprites-backgrounds-sounds §3.2: index 0 or 0x97..0x98 → 3; 1..0x96 → 0;
0x99..0x9b → 2; 0x9c..0x9e → 1): weight 3 only in a band along the **top edge**, about 6 px deep where
the two cells meet (right side of 0x4e, left side of 0x4f) and thinning to nothing at the outer
edges; everything below is weight 0 — a two-cell arch at the top [HIGH decode; MED which weight
means pattern, sprites §3.2].

BG kinds 400..495 (21,112 cells in 11, 18, 22, 30, 31, 40, 62):
- `.SeparateFromTiles2` passes every non-zero BG kind to the tile callback (layer 0, `1003cb04`,
  main l. 35334–35342); every callback dispatches `< 100` → `.WallBounce`, `< 200` → `.WallBounceBG`,
  `.IsWaterTile` (200..209, main l. 38228) → `.HandleUnderWater`, anything else → nothing.
- Every other BG-kind call site tests only water: `.FillCachedTileArray` (cache fields read only by
  `.WrapDrawWaterEffects`, which uses them under the water flag: kinds 200 / 0xcb / 0xcd),
  `.PlainWrapFGTile`, `.PlainWrapFGOverlayTile`, `.RedrawScrollGrid`, `.HandleParticles`, `.Splash`
  (`< 200` clamped to 200, `100429c8..100429d4`), `.HandleUnderWater`, and the water tests in Setup
  Bonus / Box / Background / Crab.
- **No reader distinguishes 400..495**: to every sprite and to the draw they are the same as "no BG
  kind". What the level designers meant by them is UNDETERMINABLE from code (data-only marks).

## 13. `.CrunchTile`'s return value; crunch kinds (NR 2)  [HIGH]
`.CrunchTile(pos, strength) @ 10044928`; callers test only the low byte (`rlwinm. r0,r3,0,24,31`):

| case | return | raw |
|---|---|---|
| the cell has no crunch direction (`.GetFGCrunchDirTile` = bits 12..15 of the FG cell word, `1003bfb4`, is 0) | 0 | `10044968..10044974` → `10044c20` |
| strength 0 and crunch kind ≠ 3 | the **crunch kind itself** (r3 still holds `.GetFGCrunchKindTile`'s result): non-zero for kinds 1, 2, 4; nothing else happens | `10044988..1004499c` → `10044c24` |
| strength ≠ 0, or kind 3 | **1**, whatever happened (broke, cracked, resisted, or nothing) | `10044c18` |

So it means "a crunch cell was there and was processed", **not** "broke" and not "bounce". Callers:
- `.HitPlayerTileSprite` (`100552b8..100552fc`): the bounce needs return ≠ 0 **and** `s+0xeb ≠ 0`; with
  `+0xeb = 1` the return is always 1, so a fast-falling player (`vy > 0x9c4`, cooldown 0) **bounces off
  the cell it has just broken** as well as off one that resisted.
- `.HitPlayerShotTileSprite` (`1005b5f8..1005b62c`): return ≠ 0 and shot type ∉ {6, 0x3c} →
  `KillPlayerShot(shot,1,1)` (immediate return for the held item, held-item-melee §1.7).
- `.HitEffectTileSprite` (`10061a84`): ignored.

Crunch kinds as the code treats them (`10044988..10044b6c`; s = strength: player 0/1, shots 1, seeds 2,
Ice Pick 4, Vorpal Dirk 1), break = immediate `.DestroyCrunchTile` + rock sound + crunch log:

| kind | breaks at once when | otherwise |
|---|---|---|
| 0 | s ≠ 0 | s = 0: nothing |
| 1 | s == 2 | s = 0: nothing; s ∈ {1, 3, 4}: crumble overlay created (hp 2), or hp −1 if one exists and its delay is 0; crack sound and delay rand(3)+1 when hp ≥ 1; breaks when hp < 1 |
| 2 | s == 2 | s = 0: nothing; s = 1: resist sound only (if not already playing [MED: helper `FUN_100916dc`]); s ≥ 3: nothing unless an overlay already exists (then as kind 1) |
| 3 | s == 2 | **any contact, s = 0 included**: overlay created armed (`+0x16c = 1`, delay 15) — it then counts down and crumbles the cell **by itself** (triggers-background-2 §2.3) |
| 4 | s ≥ 4 | s = 0: nothing; 1 ≤ s < 4: resist sound only |

A grounded player calls the crunch pass every frame (`+0xeb = spin ∨ grounded`, §10 item 4) with
strength 0 unless falling fast, so kind 3 is the cell that collapses under a player standing on it
(confirmed by review 2g: `+0xeb` is rewritten from the vy > 0x9c4 test at `100552a0`/`100552ac` before
`lbz r4,0xeb` at `100552b4` — ⚑ corrected (review 2g, 2026-10-04) #9).
The tiles' art is level data; a name for each kind is UNDETERMINABLE from code — the table above is
what a replica implements.

## 14. The as-written oddities (NR 8): intent CLOSED AS UNDETERMINABLE  [HIGH for each rule]
No comment, assertion, second build or data case shows what was meant; for three of the four the
shipped data never exercises the odd part (§11). A replica copies these rules exactly:
1. **Kind-indexed tile rect** (`10037b8c..10037bc0`): for `k = kind mod 100 < 0x30`, the (centred) mover
   rect must meet `(X + e+6, Y + e+4, X + e+0xa, Y + e+8)` with `e = 0x100a4794 + 0x14·k` — the hot-rect
   entry of **FG tile number k** of the current level, not of the tile that was hit; no overlap → no
   collision (`.WallBounceBG` the same against the uncentred rect). No effect on shipped data (§9.1).
2. **Kind 0x13** (`10038e54..10038ed0`): `x + Rc < X + 16` (Rc = right edge of the centred rect copy,
   `lha 0x90(r1)`) → resolve as kind 2; else if `y + vC + Bc > 16` — y the sprite's integer y, vC the
   caller's vertical-centre value (`*param_4`, added at `10037c60`), Bc the rect copy's bottom
   (`lha 0x8e(r1)`) — resolve as kind 0xf; else no collision. The comparison is against the absolute
   number 16, so below the top 16 px of a map 0x13 ≡ (kind 2 / kind 0xf). 118 + 4 ice cells shipped.
3. **BG kind 112** (`.WallBounceBG` case 0xc, `1003a708..1003a770`): `s = clamp((x − (vy >> 8)) + L − X,
   0, 32)` — the previous position is taken with **vy** (`lwz r5,0x2c`) where every other slope uses vx;
   lands when `y + B > Y + s` and `(y − (vy >> 8)) + B ≤ Y + s + 3`. No shipped BG cell has kind 112.
4. **2:1 floors 0x2c..0x2f** (`10039768..100398f0`, `100398f4..10039a84`): on overlap with `y + B > Y + s`
   (0x2d needs `t ≤ 16`, 0x2f `t ≥ 16`): optional bounce scaling of vx and vy (overwritten next), then
   unconditionally `vy = 2|vx| + 0x100`, `s+0xce = k` (no `vy > 0` test: a rising sprite is snapped down
   onto the surface); then if the slide applies (`+0x112 > 0`, latch `+0x181` clear): latch,
   `vx = (int)(vx + 9.23·slip)` (0x2c/0x2d, `fmadd`) or `(int)(vx − 9.23·slip)` (0x2e/0x2f, `fnmsub`;
   9.23 = f64 at TOC −0x5f40 = `0x100a1900`), then `vy = 2·vx` resp. `vy = −2·vx` — the guarding tests
   (`vy < 2·vy`, `vy > −2·vy`) mean `vy > 0`, always true after the store, so the assignment is
   unconditional and uses the signed post-slide vx; finally `y = Y + s − B`, hit. No shipped ice on
   0x2c..0x2f (§11), so the ice half is never reached in 1.0.3.

## 15. The other rows of the NR list (wave 2)  [HIGH]
- **NR 3 `PTR_DAT_100a06e8`** (byte 0x102bb7dc): its 3 TOC loads store 0 (`.ClearPlayerVars`
  `1004ab50..1004ab5c`, `.HandlePlayerSprite` `1004ed18..1004ed1c`) or read it (`1004ecf0`); the adjacent
  slots `0x100a06dc` / `0x100a06e0` (bytes 0x102bb7da / 0x102bb7db) are accessed only with byte ops
  (all loads followed, incl. r28 at `1004c55c`). Never non-zero: the "second entry flag" branch
  (handler l. 1399–1402) is dead.
- **NR 5** cannon launch geometry: covered by triggers-background §2 "Firing" (`.HandleCannonedSprite`,
  handler l. 4640–4888). **NR 6** glider internals: spells-detail §5.
- **NR 7** the five type-1 sprites are the Double-Speed trail (held-item-melee §3, slot `0x100a0518` →
  `.SetupTrailSprite 1004b3b4`). **`PTR_DAT_100a06bc`** (i16 0x102bb7ca): set to 3 when the player's
  invulnerability `+0x116` exceeds last frame's copy `PTR_DAT_100a06c0` (a new hit) and no door
  transit (`1004dd90..1004ddbc`), counted down to 0 every frame (`1004ddc0..1004ddd8`), zeroed by
  `.ClearPlayerVars` (`1004abac`); those are all its TOC loads, no neighbour slot reaches it: **no
  reader** (a dead counter). Its partner `PTR_DAT_100a06c0` = `+0x116` copied each frame
  (`1004e1bc..1004e1c8`, handler l. 1071), read only by that test.

## NOT RESOLVED
1. ~~Readers of FG kinds 0x4e/0x4f (desert levels) and BG kinds 400..495 other than the player's
   tile callback (both are no-ops for the player).~~ → closed: §12 (0x4e/0x4f draw-only blend shapes;
   400..495 read by nothing) — ⚑ wave 2 (2026-10-04)
2. ~~`.CrunchTile`'s return value meaning (break vs bounce) — only its use is read here.~~ → closed: §13 — ⚑ wave 2 (2026-10-04)
3. ~~`PTR_DAT_100a06e8` (second cast-start flag): no writer in either dump.~~ → closed: §15, never
   non-zero, the branch is dead — ⚑ wave 2 (2026-10-04)
4. ~~PICT 1026 (0x402): no loader found.~~ → closed: unused, as is PICT 1054 (rendering-omnipx-titles §5)
   ⚑ wave 2 corr (2026-10-04) RO #11
5. ~~Cannon launch geometry (`.HandleCannonedSprite` arms, the cannon's `+0x46/+0x164`) — cannon reader.~~
   → closed elsewhere: triggers-background §2 "Firing" — ⚑ wave 2 (2026-10-04)
6. ~~Glider internals (`_DAT_100a05d0/05d4/05d8/05dc/05c8`, faces 1050–1053) — spells reader.~~ → closed
   elsewhere: spells-detail §5 — ⚑ wave 2 (2026-10-04)
7. ~~The 5 type-1 sprites at `PTR_DAT_100a051c` (trail by handler name only) and `PTR_DAT_100a06bc`
   (3-frame counter on a new hit; reader not traced).~~ → closed: §15 (trail = held-item-melee §3;
   `PTR_DAT_100a06bc` has no reader) — ⚑ wave 2 (2026-10-04)
8. ~~Intent of the three as-written oddities a replica must copy anyway: WallBounce's kind-indexed
   tile rect (§9.1.4), kind 0x13's absolute-y test (§9.3), BG 0xc's `vy` for previous x (§10.1),
   and the 0x2c..0x2f ice `vy` rules.~~ → CLOSED AS UNDETERMINABLE (intent): §14 states each rule
   exactly; nothing in code or data shows the intent — ⚑ wave 2 (2026-10-04)

## Proposed additions to physics.md §0
- `+0x46` (player) walk/run cycle phase (even 0..30 / 0..22); `+0x14c` (player) catapult launch
  request (platform writes 1, handler consumes).
- `+0x8a` = not clinging (gate of the water current); `+0x90` wind/current scale (player 0x100,
  0 while dying); `+0x92` in-wind flag (holds the fall animation).
- `+0xc0` current face record; `+0xb8` draw effect (0x10001..0x1000c power-up tints, 0x5000n
  teleporter sparkle, 0xb0001/0xb0005 spirit, 0x10007 debug); `+0x1a6/+0x1a8` effect parameters;
  `+0x88` ~~draw-normal flag~~ light-overlay gate (`.WrapLightFace` pass; ⚑ corrected (review 1c, 2026-10-03) #5, physics §0.1); `+0x18c` effect-active flag.
- `+0xd0` on a one-way top (`.WallBounceBG` 1, `.WallBounce` 0, `.PlatformBounce` one-way).
- `+0xe4` enables `.SeparateFromTiles2`'s second (dead) loop — player 1; `+0xeb` crunch-capable.
- `+0x140` skip water processing; `+0x181` ice slide applied in this `.SeparateFromTiles2` call (cleared at each call); `+0x1b2` handler skip.
- `+0x1e4` cannon sprite; `+0x1ec/+0x1f0/+0x1f4` saved handler / hit / tile callbacks while
  cannoned; `+0x130` (cannoned) fire timer.

## Corrections to the existing bank
| file § | old reading | new reading | evidence |
|---|---|---|---|
| physics §4 "gravity, spin jump 0x118 — spin flag" | spin uses 0x118 | 0x118 only when **swimming or fully submerged** and spinning; out of water a spin falls at 0x1b8 | raw `1004da90..1004dacc`: `lha r0,(r18=swim)`; `bne`→`li 0x50`; else `lwz 0x11c; cmpwi 1; bne skip`; `li 0x50; sth`; `lbz spin; beq skip; li 0x118; sth` |
| physics §4 "air control ±0x14a … not on ground, not swimming" | symmetric air control | LEFT −0x14a only in plain air; **RIGHT +0x14a in every non-cling state** (ground after the slope accel, rope, swim, air) while `vx < airMax`; ground right accel is therefore 0x14f/0x104 + 0x14a | raw LEFT `10053748..10053784` (only on the not-rope/not-swim path) vs RIGHT: swim `1005393c b 10053974`, rope `10053958→10053974`, ground `100538fc FootPressure … b 10053974`, then `10053974..100539a8 addi r0,r3,0x14a` |
| physics §4 "air drag (no input) 100" | drag only without input | airborne drag 100 / 600 rope / 20 glider applies every airborne frame regardless of input | handler dump l. 1223–1260 (no input test; ground decel l. 1262–1294 is input-gated by `_DAT_100a0730/0734`) |
| physics §4 "wall-climb vertical vy = −1000 / +1000 / 0" | ±1000 | effective **±900** (±1300 Double Speed): the pre-move ease adds ±100 in the same frame; 0 without a key because the cling zeroes v every frame; also 0 when a cast began this frame (`*PTR_DAT_100a06e0 == 0`) or wand phase > 0 ∧ `_DAT_100a06d0 < 5` (main dump l. 44776–44810; ⚑ review 1b #6) | raw `1004ea5c..1004eacc` (`addi 0x64` / `subi 0x64`, clamp ±0xfa0) after `.HandleKeys`; handler dump l. 3049–3050 |
| physics §4 "wall jump … vy = 0 (−0x8cb when the counter is 3)" | vy −0x8cb | the counter is 3 when clinging, so the jump-sustain arm runs in the same call and sets `vy = J − 0xc80 − ((0x8ca+0x4e2)>>3)` = **−3637** (⚑ corrected (review 1b, 2026-10-03) #3: was −3610; 3500 >> 3 = 437); the −0x8cb store is dead | main dump l. 44818–44836 then 44869–44880 (no return between) |
| physics §4 "jump hold … 3 when leaving a rope/ladder" | 3 = rope/ladder | 3 = **clinging to a wall**; rope = 6 (`.RopeCollide`); refill = the `else` of (not gliding ∧ JUMP ∧ teleporter charge < 1), so in ordinary play only while JUMP is up (no coyote, no buffer) — ⚑ corrected (review 1b, 2026-10-03) #7 | main dump l. 44818–44819, 44962–44973 |
| physics §4 "spin jump: DOWN + JUMP with counter 1..6 → spin flag" | spin only | also refills the counter to 6 (cooldown 20, not near the surface): a second sustain window; DOWN alone with counter 1..5 also spins | main dump l. 44838–44860, 44761–44774 |
| physics §3.2 "second 64-entry table at +0xc … readers not traced" | unread | `+0xc` (per kind) read only by the dead second loop of `.SeparateFromTiles2`; `.WallBounce`/`.WallBounceBG` read the per-tile `+4` rect **indexed by kind** | raw `1003ce74..1003cea0`; `10037b8c..10037bc0`; `1003a2f4` |
| physics §3.3 "4–7 quarter blocks choosing the shallower axis; 8–0xb L-shaped two-rect blocks"; "further cases … NOT RESOLVED" | partial | full table §9.2–9.3 (8..0xb are three-quarter blocks forced into their empty quarter; 0x30/0x31/0x3a/0x3b have no case) | main dump l. 32948–33840; jump table 0x100a54d4 |
| physics §3.3 BG 100..199 "one-way … [LOW]" | LOW | one-way from above for floors (+1/+3 px slack), two-way ceilings and composites; `s+0xd0 = 1` | §10.1 |
| physics §4 hot rect "crouching with a shield changes it" | shield only | every ground crouch uses `(0x26,0x37,0x3e,0x55)`; the shield extends it forward 0..7 px | main dump l. 44754/44757 |
| physics §3.3 crunch "with the spin flag" | spin required | the call needs `s+0xeb = spin ∨ grounded`, the break test is `cooldown == 0 ∧ vy > 0x9c4`; bounce `vy = −0.9·vy` only with DOWN held | handler dump l. 3079–3118; `tools/const.py 100a1a20` = −0.9 |
| INDEX NOT-RESOLVED 2 "0x26c8 (copied to G+0x16)" | unread | G+0x16 = start facing (0 right, else left), read by `.SetupPlayerSprite`, re-written at save points | handler dump l. 419–431, 4199; main dump l. 5786, 6885; raw 1000b3d8/1000b3dc, 1000d684/1000d688, 1004b2b0 (⚑ review 1b #13 spot-check) |
| INDEX NOT-RESOLVED 14 "player's +0x19e writes", "`_DAT_100a0718`" | unread | +0x19e grows during the death animation (the body floats); `_DAT_100a0718` = air animation counter | handler dump l. 1678, 1740, 2349–2452 |
| physics §4 wall-jump row (already ⚑-corrected by the deepening to "net **vy = −3610**") | −3610 | **−3637** = −3200 − (3500 >> 3) (review 1b #3) | main dump l. 44869–44880; 0x4e2 = 1250 |
| physics §8.3 / §8.4 (`_DAT_100a0718`, FootPressure gate) | any "launch latch, never decays" text carried over from platforms-ropes-radial corr. 9 | air animation counter, zeroed every grounded / rope / swim / cling frame through r27 (loaded once at raw 1004d648; stores 100500c4, 10050250, 100505d4, 1005073c); `.FootPressure` skipped only on airborne / first-landing frames (review 1b #1) | §2, §3.12; platforms-ropes-radial §4 |
| world-data §3.2 0x26c8 row | HIGH, evidence by dump line | add the raw addresses `.NewGame` 1000b3d8, `.ContinueGame` 1000d684, `.SetupPlayerSprite` 1004b2b0 (review 1b #13) | §6 |

Wave 2 (2026-10-04):

| # | file § | old | new | evidence |
|---|---|---|---|---|
| W1 | physics.md §3.3 crunch bullet | "bounce if not broken" | the player bounces whenever it falls fast onto a crunch cell, **broken or not** (`.CrunchTile` returns 1 for every processed cell when the strength is non-zero) | §13; raw `10044c18`, `100552c0..100552fc` |
| W2 | spells-detail §3 (line "crunch cell … if it broke → kill") | kill if it broke | kill if the cell was processed (return ≠ 0: broke, cracked or resisted) | §13; raw `1005b5f8..1005b62c` |
| W3 | sprites-backgrounds-sounds §3.1 step 2 | (kinds as collision only) | add: FG kinds 0x4e/0x4f exist only for this blend step (no collision); BG kinds 400..495 have no reader | §12 |
| W4 | held-item-melee §1.7 "kind meanings NOT RESOLVED" (owned by this lane; applied there) | open | crunch kinds 0..4 per §13 table; art = level data | §13 |
