# Deimos Rising 1.0.6 — sprite blit pixel rules (U_SpriteBlit.cc): modes, alpha maps, clipping, scaling

**Scope (wave 3, reader w3s1).** Every pixel a sprite command writes, read by raw listing:
- the dispatcher `FUN_10019570` (mode, clip and scale selection, argument passing);
- the four unscaled unclipped leaves `FUN_1001d9f0` (mode 0), `FUN_1001db50` (mode 1),
  `FUN_1001dd20` (mode 2), `FUN_1001df00` (mode 3), including the `FUN_1001dd20` partial-alpha
  branch (sprite-geometry-draw.md NR 7);
- the four unscaled clipped twins `FUN_1001e0d0` `FUN_1001e2b0` `FUN_1001e4f0` `FUN_1001e770`,
  instruction-diffed against their siblings;
- the scaled dispatchers `FUN_1001a6f0` / `FUN_1001aa90` (full bodies) and all 17 scaled leaves
  `FUN_1001b7d0` … `FUN_1001d460`;
- the three global switches `DAT_100e0171` / `DAT_100e0172` / `DAT_100e0181` (raw store scan of
  the whole code image, their two writers and their console registrations `FUN_10018740`,
  `FUN_1001d5e0`), plus `FUN_10018a40` (the queue), `FUN_1001a290`, `FUN_10019c00`;
- optional items done: sprite NR 2 (render-list reset, `FUN_100189f0`) and NR 5 (entity `+0x1a`).

**OUT:** the encoder `FUN_1001d780`, the alpha-map builder `FUN_1001eec0` (both in
sprite-sound-containers.md §2.3a), the plate scan, `FUN_1001ec80` (`COST` rect), anything
≥ `0x1001e9d0`, the command builders (sprite-geometry-draw.md §3–§5).

This is a code reading. None of it has been checked against the running game.

Evidence: `$W/disasm-w3s1.txt` (DisasmFuncs.java over the private copy `$W/work-w3s1`: the 37
functions named above), `$W/w3s1-ranges.txt` (DisasmRange over the two unnamed handler bodies
`1001afc0..1001b030` and `1001f040..1001f0c0`), `$W/w3s1-extra.txt` (`FUN_1001d5e0`,
`FUN_100000e0`), `$W/w3s1-extra2.txt` (`FUN_100189f0`). Scans: `$W/w3s1-stbscan.py`,
`$W/w3s1-basescan.py`, `$W/w3s1-slotscan.py`, `$W/w3s1-blscan.py`, `$W/w3s1-slot7198.py`.
Worked example: `$W/w3s1-worked.py`. `$W` = `/Users/andiyar/ghidra-proj-deimos`.

**Short answers.**
- **Kernel.** Every blending leaf uses one packed RGB555 kernel:
  `out_c = floor((dst_c·α + src_c·(32 − α)) / 32)` per 5-bit channel, exact (no channel bleed).
  α is the weight of the **destination**: α 0 = source only, α 32 = destination unchanged.
- **Mode 1 (fade).** The critic's read is confirmed.
  - No alpha map: every pixel ≠ colour key blends with the command alpha a.
  - With a map (map value p): p 32 → skip. p 0 → blend with a. Else α = a + p (additive), skip
    when α ≥ 32.
  - A map value of 1000 skips the whole row (unscaled) or that pixel (scaled).
- **Mode 2 (shadow), partial-alpha branch (NR 7).** α = trunc(a + 0.032·p²) in single
  precision. The pixel is skipped when α ≥ 32, otherwise `dst = dst·α/32`.
  - A shadow at a = 20 keeps map values 1..19 (α 20..31) and drops p ≥ 20.
- **Clipped twins** = the unclipped sibling's kernel, instruction for instruction. Two things
  are added:
  - an early reject;
  - a per-pixel test `clipL ≤ x < clipR && clipT ≤ y < clipB` on the command clip `+0x20..+0x2c`.
  
  Dispatcher map: flags &1 → mode 1 `e2b0`, &2 → mode 2 `e4f0`, &4 → mode 3 `e770`, else mode
  0 `e0d0`.
- **Scaling.** Nearest neighbour with left/top-aligned integer sampling:
  - `sx = (srcW·(dx − left)) div dstW`, `sy = (srcH·(dy − top)) div dstH`, where
    dstW = trunc(srcW·s) and dstH = trunc(srcH·s);
  - x positions come from a per-column table on the stack, y is computed per row.
  
  The unclipped scaled leaves clamp the destination hard to x ∈ [0, 416), y ∈ [0, 480)
  (`0x1a0`/`0x1e0`). The clipped ones test the command clip per pixel instead. The per-mode
  formulas equal the unscaled ones. The one code difference: the mode 1/3 partial branch clamps
  α to 32 and blends, which is a no-op. So the pixels are identical.
- **Globals.** In 1.0.6 all three switches stay 1 for the whole session:
  - the only stores are the console toggles **FX** (`DAT_100e0171`) and **ALPHA**
    (`DAT_100e0181`, which copies itself into `DAT_100e0172`);
  - both commands are registered `debugOnly = 1`, so they are never added (messages §5.2).
  
  The critic's O10 hypothesis is confirmed.
- **Render lists (NR 2).** `FUN_100189f0` zeroes all 16 per-layer counts. It is called first
  thing in every begin frame (`FUN_10030360` at `10030388`).
- **`+0x1a` (NR 5).** It is written in `FUN_10035cd0` from unit-def `+0x12c`
  (adjustShadowLocForScaling).

## 0. Constant and address resolution
TOC r2 = `0x100e6330`. Displacement d of a byte global = address − r2:
- `0x100e0171 − 0x100e6330 = −0x61bf`
- `0x100e0172 − 0x100e6330 = −0x61be`. ⚑ The brief's `-0x61ae` is a typo: `-0x61ae(r2)` is
  `0x100e0182`. The listing setter `1001a290 stb r3,-0x61be(r2)` confirms `−0x61be`.
- `0x100e0181 − 0x100e6330 = −0x61af`

Constants: `w3s1-rd.py` (big-endian reads, data image at or above 0x100de330, code image below):
`python3 -c "…r.slot(d)…"`, as run in this session.
| TOC slot | → | value | used by |
|---|---|---|---|
| `r2−0x7164` (`0x100df1cc`) | `0x100d6db4` | f32 `0x3d03126f` = **0.032** | `FUN_1001dd20`, `FUN_1001e4f0` (mode-2 partial α) |
| `r2−0x7168` (`0x100df1c8`) | `0x100d6db8` | f64 `0x4330000000000000` = 2⁵² (unsigned int→float bias) | same |
| `r2−0x717c` (`0x100df1b4`) | `0x100d6d78` | f32 `0x3d03126f` = **0.032** | `FUN_1001bcf0`, `FUN_1001cdc0` (scaled mode-2 partial α) |
| `r2−0x7180` (`0x100df1b0`) | `0x100d6d7c` | f64 2⁵² | same |
| `r2−0x71a8` (`0x100df188`) | `0x100d6d34` | f32 1.0, 100.0, **0.5** (+8) | scale ≠ 1 test (`100195d0`); centring (`1001a75c lfs f5,0x8(r10)`) |
| `r2−0x71b8` (`0x100df178`) | `0x100d6d40` | f64 2⁵², 2⁵²+2³¹ | alpha → double (`1001985c`), int → float (`1001a74c lfd f6,0x8(r4)` = signed bias) |
| `r2−0x71b4` (`0x100df17c`) | `0x100d6d0c` | Rect {0, 0, 480, 416} | scaled unclipped-vs-clipped test (`10019818..10019844`) |
| immediate | — | `0x1a0` = 416, `0x1e0` = 480 | scaled unclipped leaves' destination clamps (`1001b81c`, `1001b828`) |
| immediate | — | `0x3e8` = 1000 (empty-row marker), `0x20` = 32 (transparent) | every map leaf |
Initial bytes (data image, `w3s1-tv.py`): `0x100e0170`=1, `0171`=1, `0172`=1, `0179`=0,
`0180`=0, `0181`=1. [HIGH — image bytes; §6 shows no pre-main or runtime writer reaches 0171/0172/0181]

## 1. Dispatch: `FUN_10019570 @ 10019570` → 30 leaves [HIGH]
### 1.1 Selection
```
100195a0 lwz r0,0x1c(r31) ; cmplwi r0,0x20 ; beq end          ; alpha 32 → nothing
100195cc lfs f0,0x18(r31) ; lfs f1,0x0(r4) ; fcmpu ; … xori r27,r3,0x1   ; r27 = (scale ≠ 1.0)
100196b4 lwz r30,0x4(r23) ; lwz r24,0x8(r23)                  ; frame w, h
1001973c lwz r21,0x24(r31) ; lwz r20,0x20(r31) ; lwz r19,0x2c(r31) ; lwz r18,0x28(r31)
                                                             ; clipL, clipT, clipR, clipB
100197d4 rlwinm. r0,r4,0,31,31 → r22=1 ; 100197e4 …30,30 → 2 ; 100197f4 …29,29 → 3 ; else 0
10019808 bl 0x1000a4a0  (port, &base → r1+0x5c, &rowBytes → r1+0x58)
```
- **Mode**: flag bit 1 wins over 2, and 2 over 4. So mode = 1 if `&1`, 2 if `&2`, 3 if `&4`,
  else 0. The port is `DAT_100e0170` with flag 8, else `DAT_100e0179`
  (`10019714`/`10019728` `lbz r4,-0x61c0/-0x61b7(r2); bl 0x1000ad90`).
- `FUN_1000a4a0(port, &a, &b)` returns `a = port[5]` (pixel base) and `b = port[6]`
  (rowBytes), per the dump. The dump of `FUN_1000fee0` confirms the use as
  `base + y·rowBytes + 2x`.
- **Unscaled clip classification** (`10019754..100197a8`), with X = left, Y = top:
  - the frame is *inside* iff `X ≥ clipL && X+w < clipR && Y ≥ clipT && Y+h < clipB`;
  - *rejected* iff `X+w < clipL || X ≥ clipR || Y+h < clipT || Y ≥ clipB`;
  - else *clipped* (r29 = 1).
  
  Note the strict `X+w < clipR`: a frame ending exactly on the right/bottom edge takes the
  clipped twin. The output is identical (§4).
- **Scaled**: `FUN_1001a6f0` when the command clip equals `0x100d6d0c` = {0,0,480,416}, else
  `FUN_1001aa90` (`10019818..10019844`). This was HIGH already in sprite-geometry-draw.md §3.3.
  There is no reject test before the scaled path.

### 1.2 Argument passing (answers "how the f2 alpha / stack mode reach the leaves")
| callee | r3 | r4 | r5 | r6 / r7 | r8 | r9 | r10 | stack (caller r1+…) |
|---|---|---|---|---|---|---|---|---|
| `d9f0` m0 | frame | rowBytes | base | X / Y | — | — | — | — |
| `db50` m1, `dd20` m2 | frame | rowBytes | base | X / Y | alpha `cmd+0x1c` | — | — | — |
| `df00` m3 | frame | rowBytes | base | X / Y | alpha | colour `cmd+0x34` | — | — |
| `e0d0` m0 | frame | rowBytes | base | X / Y | clipL | clipT | clipR | 0x38 clipB |
| `e2b0` m1, `e4f0` m2 | frame | rowBytes | base | X / Y | alpha | clipL | clipT | 0x38 clipR, 0x3c clipB |
| `e770` m3 | frame | rowBytes | base | X / Y | alpha | colour | clipL | 0x38 clipT, 0x3c clipR, 0x40 clipB |
| `a6f0` | frame | **base** | **rowBytes** | cmd X / Y | frame w | frame h | — | 0x38 mode (word; byte read at +3), 0x40 colour; f1 = scale, f2 = (double)alpha |
| `aa90` | frame | base | rowBytes | cmd X / Y | w | h | — | 0x38 mode, 0x40 clipL, 0x44 clipT, 0x48 clipR, 0x4c clipB, 0x50 colour; f1, f2 |
- f2 = alpha as a float: `10019880 stw r0(0x4330),0x68(r1); 10019890 stw alpha,0x6c(r1);
  10019898 lfd f0,0x68(r1); 100198a0 fsubs f2,f0,f2(2⁵²)`. That is exact for 0..31.
- In the scaled dispatchers the alpha goes back to an int: `1001a868 fmr f1,f2; bl 0x1004d5c0`
  (MSL double→unsigned, trunc). This happens only on the mode 1/2/3 branches. Mode-0 leaves get
  no alpha (`1001a830..1001a85c`, `1001a960..1001a990`: no `bl 0x1004d5c0`).
- The mode byte: `1001a718 lbz r0,0xfb(r1)` (= 0xc0 + 0x38 + 3) and `1001aabc lbz r3,0x11b(r1)`
  (= 0xe0 + 0x38 + 3).
- The colour: `1001a720 lhz r27,0x102(r1)` and `1001aad4 lhz r16,0x132(r1)`.
- The colour key for the key-path leaves is read from the frame header:
  `1001a978 lhz r0,0x10(r22)` (frame +0x10).

### 1.3 Leaf matrix [HIGH — call sites listed; every leaf body read]
Map path = `frame+0x12 ≠ 0` **and** the global switch ≠ 0:
- unscaled: `DAT_100e0181` (`1001d9fc lbz r0,-0x61af(r2)` … in all 8 unscaled leaves);
- scaled: `DAT_100e0172` (`1001a714 lbz r10,-0x61be(r2)`, `1001aab8`).

| path | mode 0 copy | mode 1 fade | mode 2 shadow | mode 3 tint | call sites |
|---|---|---|---|---|---|
| unscaled, inside | `FUN_1001d9f0` | `FUN_1001db50` | `FUN_1001dd20` | `FUN_1001df00` | `10019948` `1001996c` `10019990` `100199b8` |
| unscaled, clipped | `FUN_1001e0d0` | `FUN_1001e2b0` | `FUN_1001e4f0` | `FUN_1001e770` | `10019a14` `10019a48` `10019a7c` `10019ab4` |
| scaled, game-area clip, alpha map | `FUN_1001b7d0` | `FUN_1001ba40` | `FUN_1001bcf0` | `FUN_1001bfd0` | `1001a85c` `1001a8a0` `1001a8e4` `1001a92c` |
| scaled, game-area clip, colour key | `FUN_1001c270` | `FUN_1001c480` | `FUN_1001c6c0` | `FUN_1001c8f0` | `1001a990` `1001a9d8` `1001aa20` `1001aa6c` |
| scaled, other clip, alpha map | `FUN_1001cb40` | `FUN_1001cc60` | `FUN_1001cdc0` | `FUN_1001cf80` | `1001ac1c` `1001ac70` `1001acc4` `1001ad1c` |
| scaled, other clip, colour key | `FUN_1001d0e0` | `FUN_1001d270` | `FUN_1001d370` | `FUN_1001d460` | `1001ad90` `1001ade8` `1001ae40` `1001ae9c` |
- The unscaled leaves hold both the map and the key path inside one function.
- `FUN_1001d1b0 @ 1001d1b0` is **not** a sprite leaf. It is a scaled, clipped **opaque** copy of
  a raw RGB555 buffer (no key, no map, no alpha). Its only caller is `FUN_1002f7a0`
  (level-select button; callers.txt).
- A mode byte ≥ 4 or < 0 draws nothing (`1001a824 cmpwi r0,0x4; bge end`).

## 2. The blend kernel (all modes) [HIGH]
Listing (mode 0 partial alpha, `FUN_1001d9f0`), and it is the same sequence in every leaf:
```
1001da88 lhz r5,0x0(r10)          ; dst
1001da8c subfic r0,r30,0x20       ; 32 − α
1001da90 andi. r4,r5,0x7c1f       ; R (bits 10..14) | B (bits 0..4)
1001da98 rlwimi r4,r5,0xf,0x7,0xb ; + G moved to bits 20..24
1001da9c rlwimi r3,r29,0xf,0x7,0xb   (src likewise)
1001daa0 mullw r4,r4,r30          ; dst·α
1001daa4 mullw r0,r3,r0           ; src·(32 − α)
1001daa8 add r3,r4,r0
1001daac rlwinm r0,r3,0x1b,0x5,0x1f ; >> 5
1001dab0 andi. r0,r0,0x7c1f       ; R, B back
1001dab4 rlwimi r0,r3,0xc,0x16,0x1a ; G: bits 25..29 → 5..9
1001dab8 sth r0,0x0(r10)
```
- Each packed field is 10 bits wide: B 0..9, R 10..19, G 20..29. A sum of at most 31·32 = 992
  < 1024 cannot carry into the next field. The kernel is therefore exactly
  **`out_c = ⌊(dst_c·α + src_c·(32 − α))/32⌋`** per channel. That is a floor, with no rounding
  term.
- **Shadow kernel** (mode 2): only the dst half, `out_c = ⌊dst_c·α/32⌋`
  (`1001ddb4..1001ddd0`, reviewer-confirmed in wave 2).
- **Tint kernel** (mode 3): the colour argument replaces src, `out_c = ⌊(dst_c·α +
  col_c·(32 − α))/32⌋` (`1001df8c..1001dfc0`).
- The same floor kernel is `FUN_1001e9d0` (loose-ends-session.md §6) and the particle stamp
  (particles-debris-blur.md §2.9).

## 3. Unscaled unclipped leaves — per-pixel rules [HIGH]
Common frame: `dst = base + Y·rowBytes + 2X`. After each row, dst += rowBytes − 2w.
- Map path, per row: if the row's first map entry is 1000, advance the src/map/dst pointers by
  2w and skip the row. Otherwise walk w pixels with map value p.
- Key path: a pixel is drawn iff `src ≠ frame+0x10`.

| mode | key path (no map) | map: p = 32 | p = 0 | p = 1..31 | listing |
|---|---|---|---|---|---|
| 0 `d9f0` | copy src | skip | **copy** src | blend α = p | `1001da50 cmplwi r0,0x3e8`, `1001da6c cmplwi r30,0x20`, `1001da80 sth r29` (copy), `1001daa0 mullw r4,r4,r30`; key `1001db0c cmplw r4,r0; beq; sth` |
| 1 `db50` | blend α = a | skip | blend α = a | α = a + p; **skip if α ≥ 32** else blend | `1001dbb4 cmplwi r11,0x3e8`, `1001dbcc cmplwi r11,0x20`, `1001dbf8 mullw r31,r31,r8` (p = 0: α = a), `1001dc18 add r28,r8,r11; cmplwi r28,0x20; bge skip`, `1001dc3c mullw r31,r31,r28`; key `1001dcac cmplw; beq`, `1001dccc mullw r5,r5,r8` |
| 2 `dd20` | dst·a/32 | skip | dst·a/32 | α = trunc(a + 0.032·p²) (§3.1); skip if α ≥ 32, else dst·α/32 | `1001dd8c cmplwi r0,0x3e8`, `1001dda4 cmplwi r4,0x20`, `1001ddc0 mullw r3,r0,r21`, `1001ddd8..1001de28`, `1001de38 mullw r3,r0,r3`; key `1001deb8 mullw r4,r0,r21` |
| 3 `df00` | tint α = a | skip | tint α = a | α = a + p; skip if α ≥ 32, else tint α | `1001df60 cmplwi r12,0x3e8`, `1001df7c cmplwi r12,0x20`, `1001dfa8 mullw r31,r31,r8`, `1001dfc8 add r28,r8,r12; cmplwi r28,0x20; bge`, `1001dff0 mullw r30,r30,r28`; key `1001e080 mullw r5,r5,r8` |
- **Mode 0 ignores the command alpha.** It is the default for a sprite at full visibility
  (alpha 0).
- **Mode 1's per-pixel α is additive.** A sprite fading at a = 16 loses every map pixel with
  p ≥ 16. Soft edges disappear before the core fades. The worked example shows this. There is no
  multiplicative opacity anywhere.
- In mode 1 the p = 0 branch skips the ≥ 32 test. It cannot matter, because the dispatcher
  never passes a = 32 (`100195a0`).
- `df00` tests `frame+0x12` before the global (`1001df3c`, `1001df40`). The others test the
  global first. The result is the same.
- The "colour key without a plate" case (decompile read) is confirmed for every mode: the key
  path runs when `frame+0x12 == 0` or the global is 0.

### 3.1 Mode 2 partial-alpha branch (sprite NR 7) [HIGH]
```
1001ddd8 lis r0,0x4330 ; lwz r3,-0x7168(r2) ; stw r4(p),0x44(r1) ; lfd f3,0x0(r3)   ; f3 = 2⁵²
1001ddec lfs f1,0x0(r31)            ; r31 = *(r2−0x7164) → f1 = 0.032f
1001ddf0 lfd f0,0x40(r1) ; 1001ddf8 fsubs f0,f0,f3          ; f0 = (float)p
1001de00 lfd f2,0x48(r1) ; 1001de04 fmuls f1,f1,f0          ; f1 = 0.032·p   (single)
1001de08 stw r21(a),0x3c(r1) ; 1001de0c fsubs f2,f2,f3      ; f2 = (float)p
1001de14 lfd f0,0x38(r1) ; 1001de18 fsubs f0,f0,f3          ; f0 = (float)a
1001de1c fmadds f1,f2,f1,f0         ; f1 = p·(0.032·p) + a   (one rounding)
1001de20 bl 0x1004d5c0              ; trunc → unsigned
1001de24 cmplwi r3,0x20 ; bge skip ; 1001de38 mullw r3,r0,r3 … sth   ; dst·α/32
```
- **α = trunc(fl32(p·fl32(0.032·p) + a))**. This is a quadratic falloff, unlike the additive
  rule of modes 1 and 3. The wave-2 suspicion of "a lost f1" is answered: f1 is the 0.032 product.
- Table (numpy float32, `fmadds` emulated as an exact product + sum, rounded once):
  - **a = 20** (the standard shadow, sprite-geometry-draw.md §5.2), for p = 1…19:
    `20 20 20 20 20 21 21 22 22 23 23 24 25 26 27 28 29 30 31`. p ≥ 20 is skipped.
  - a = 24: p ≤ 15 is drawn. a = 28: p ≤ 11 is drawn.
  - a = 0: `0 0 0 0 0 1 1 2 2 3 3 4 5 6 7 8 9 10 11 12 14 15 16 18 20 21 23 25 26 28 30` (p 1..31).
- So a shadow pixel under a half-transparent sprite pixel (p ≈ 16) darkens to 28/32. That is
  much lighter than the 20/32 under an opaque pixel.
- The clipped twin `FUN_1001e4f0` has the same code (`1001e6a0..1001e6f0`, K via r22 =
  `*(r2−0x7164)`). The scaled `FUN_1001bcf0` (`1001bf24..1001bf74`) and `FUN_1001cdc0`
  (`1001ced4..1001cf24`) use the identical sequence with slots `r2−0x717c`/`−0x7180`, which
  hold the same bytes `3d03126f` / `4330000000000000`.

## 4. Unscaled clipped twins — instruction diff [HIGH]
Each twin = its sibling's body with three additions. Register allocation differs, and so does
the loop counter (CTR vs. a counted register). The kernels are the same instruction sequence.

**(a) Early reject**, redundant with the dispatcher:
`X > clipR || X+w < clipL || Y > clipB || Y+h < clipT` → return. Example: `1001e0d4 cmpw r6,r10;
bgt` … `1001e100 cmpw r0,r9; bge`.

**(b) A running (x, y) pair**: x restarts at X every row, and y += 1 per row (including
1000-marker rows).

**(c) A per-pixel predicate before anything is read**:
`x ≥ clipL && x < clipR && y ≥ clipT && y < clipB`, else skip. The src/map/dst pointers still
advance.

| twin vs sibling | predicate (map path) | kernel (twin ≡ sibling) |
|---|---|---|
| `e0d0` vs `d9f0` (m0) | `1001e1f0 cmpw r25,r8; blt` `1001e1f8 cmpw r25,r10; bge` `1001e200 cmpw r7,r9; blt` `1001e208 cmpw r7,r28; bge` | `1001e214..1001e260` ≡ `1001da6c..1001dab8`; key `1001e188..1001e194` ≡ `1001db08..1001db14` |
| `e2b0` vs `db50` (m1) | `1001e400..1001e41c` (r9, r11, r10, r0) | `1001e424..1001e4ac` ≡ `1001dbcc..1001dc54` (incl. `1001e470 add r21,r8,r22; cmplwi r21,0x20; bge`); key `1001e368..1001e3a8` ≡ `1001dca8..1001dce4` |
| `e4f0` vs `dd20` (m2) | `1001e648..1001e664` (r25, r27, r26, r28) | `1001e668..1001e710` ≡ `1001dda0..1001de48` (same float path); key `1001e5c8..1001e5f4` ≡ `1001dea0..1001dec8` |
| `e770` vs `df00` (m3) | `1001e8d0..1001e8ec` (r10, r11, r12, r0) | `1001e8f0..1001e980` ≡ `1001df78..1001e008`; key `1001e830..1001e874` ≡ `1001e058..1001e098` |
- **Rect source.** The command clip `cmd+0x20..+0x2c` = {top, left, bottom, right}, passed as
  (clipL = +0x24, clipT = +0x20, clipR = +0x2c, clipB = +0x28) (§1.2). Right and bottom are
  exclusive.
- The 1000-marker test runs before the clip test and skips the whole row (`1001e1d8`,
  `1001e3ec`, `1001e638`, `1001e8b8`).
- **Consequence for a replica:** clipping is a pure pixel mask. A clipped sprite draws exactly
  the pixels its unclipped twin would, restricted to the clip rect. There is no re-anchoring and
  no row/column shift.

## 5. Scaled path [HIGH]
### 5.1 Geometry (`FUN_1001a6f0` `1001a738..1001a7f4`; `FUN_1001aa90` `1001aae8..1001aba4`)
```
1001a77c fmuls f7,f3,f1    ; W = (float)w · s        1001a78c fctiwz → w' = trunc(W)
1001a794 fmuls f8,f4,f1    ; H = (float)h · s        1001a7a4 fctiwz → h' = trunc(H)
1001a7ac fnmsubs f4,f7,f5,f4 ; X − 0.5·W → 1001a7b8 fctiwz → left
1001a7c4 fnmsubs f0,f8,f5,f1 ; Y − 0.5·H → 1001a7d0 fctiwz → top
1001a7d8 add r21,r29,r3 (right = left + w') ; 1001a7e8 add r20,r28,r4 (bottom = top + h')
1001a7e0 subf. r3,r29,r21 ; ble end ; 1001a7f0 subf. r3,r28,r20 ; ble end    ; w' ≤ 0 or h' ≤ 0 → nothing
```
Everything is single precision. This extends sprite-geometry-draw.md §3.3, which had the head.

### 5.2 Sampling rule (unclipped leaves; `FUN_1001b7d0` shown) [HIGH]
```
1001b800 subf r31,r0,r11     ; dstH = bottom − top    (before clamping)
1001b804 subf r12,r10,r12    ; dstW = right − left
1001b808 bge → / li r26,0    ; x0 = max(left, 0)       1001b814 → y0 = max(top, 0)
1001b81c cmpwi r25,0x1a0 ; ble / li r25,0x1a0   ; x1 = min(right, 416)
1001b828 cmpwi r24,0x1e0 ; ble / li r24,0x1e0   ; y1 = min(bottom, 480)
1001b864 subf r11,r10,r16 ; mullw r11,r8,r11 ; divw r3,r11,r12 ; rlwinm r3,r3,1 ; stw r3,0(r5)
                             ; tab[dx] = 2·((srcW·(dx − left)) div dstW), dx = x0..x1−1 (8× unrolled)
1001b970 subf r3,r0,r30 ; mullw r3,r9,r3 ; divw r3,r3,r31   ; sy = (srcH·(dy − top)) div dstH
1001b980 mullw r4,r3,r6      ; row offset = sy·2·srcW  (same offset into pixels and map)
1001b984 mullw r3,r30,r7 ; add r5,r3,r10 ; add r5,r28,r5  ; dst = base + dy·rowBytes + 2·x0
1001b9b0 lwzu r11,0x4(r23) ; lhzx r22,r4,r11 (map) ; lhzx r21,r3,r11 (src)
```
- **Nearest neighbour, left/top aligned, integer division**, no +½. `divw` truncates toward
  zero. dx − left ≥ 0 always, so this is a floor.
  - sx runs 0 … ⌊srcW·(dstW−1)/dstW⌋ ≤ srcW − 1, so it never reads out of the frame.
  - Downscaling drops columns and rows: at s = 0.5 the even ones survive (worked example).
  - Upscaling repeats them, starting at the left/top edge.
- The column table lives in the leaf's stack frame (`r1+0x38`, frame 0x700 → room for 434
  entries ≥ 416). It is indexed by the absolute dx.
- **Clamps.** The unclipped leaves clamp the destination to [0, 416) × [0, 480) **by
  immediates**, not by the command clip or the port size.
  - Every unclipped leaf has them: `1001b81c/1001b828`, `1001ba90/1001ba9c`, `1001bd5c/1001bd68`,
    `1001c020/1001c02c`, `1001c2b8/1001c2c4`, `1001c4cc/1001c4d8`, `1001c70c/1001c718`,
    `1001c940/1001c94c`.
  - This equals the runtime template clip {0,0,480,416} (C1). That is the only clip that
    selects this path, so the result is the same as a clip test.
  - The sample position uses the *unclamped* left/top. Clamping never shifts the image.
- In the map leaves a map value 1000 is tested per pixel (`1001b9c0 cmplwi r22,0x3e8`). It sits
  only in column 0 of an empty row, and that row's other entries are 32. So this equals the
  unscaled row skip.

### 5.3 Clipped scaled leaves (`FUN_1001cb40`…`FUN_1001d460`) [HIGH]
- **Loop order is column-major.** The outer loop is dx = left … right−1, with the column test
  `clipL ≤ dx < clipR`. The inner loop is dy = top … bottom−1, with `clipT ≤ dy < clipB`. Both
  sx and sy are recomputed per pixel with the same formula (`1001cb7c..1001cb8c`,
  `1001cbc0..1001cbc8`).
- **No hard clamp.** The command clip is the only bound.
- Every destination pixel is written at most once. The visiting order therefore does not change
  the result.
- Arguments: frame pixels, map, base, srcRowBytes, rowBytes, srcW, srcH, left; stack top, right,
  bottom, clipL, clipT, clipR, clipB, then alpha / key / colour as below (`1001cb54..1001cb74`).
- The key leaves `d0e0/d270/d370/d460` take base in r4 and srcRowBytes in r5 (no map), and the
  key at stack 0x50 (`1001d110 lhz r27,0x52(r1)`).

### 5.4 Per-mode formulas, scaled vs unscaled
| mode | scaled map leaves (unclipped / clipped) | scaled key leaves | equals unscaled? |
|---|---|---|---|
| 0 | p 32/1000 skip, p 0 copy, else blend α = p (`1001b9d4 sth r21`, `1001b9f4 mullw r17,r17,r22`; `1001cbfc sthx`, `1001cc1c`) | copy ≠ key (`1001c448 cmplw r25,r28; beq; sth`; `1001d180`) | yes |
| 1 | p 0 → α = a (`1001bc5c mullw r20,r20,r0`); else **α = min(a + p, 32), blend** (`1001bc7c add r20,r0,r18; cmplwi r20,0x20; ble; li r20,0x20`; `1001cd5c..1001cd68`) | blend α = a (`1001c680 mullw r26,r17,r28`; `1001d330`) | yes: α = 32 blends to `dst·32/32 = dst`, the same as skipping |
| 2 | p 0 → dst·a/32 (`1001bf0c mullw r3,r0,r21`); else §3.1 float α, skip ≥ 32 (`1001bf68 fmadds`, `1001bf70 cmplwi r3,0x20; bge`) | dst·a/32 (`1001c8b4 mullw r20,r22,r11`; `1001d424`) | yes |
| 3 | p 0 → tint a (`1001c1e8`); else α = min(a + p, 32), tint (`1001c208..1001c214`; `1001d078..1001d084`) | tint a (`1001caf8 mullw r17,r17,r26`; `1001d528`) | yes |
- Inputs: the alpha is `0x44(r1)` for the unclipped map leaves (`1001ba68 lwz r0,0x744(r1)`
  with a 0x700 frame), `0x40` for the unclipped key leaves, and `0x54`/`0x50` for the clipped
  ones. The colour is at `0x48`/`0x58`. All of them come from §1.2.

### 5.5 Scaled vs unscaled geometry at s ≈ 1
Scale exactly 1.0 never goes scaled (`100195dc fcmpu`). Just above 1.0 the integer size can be
unchanged while the anchor moves. Example: w 18, s = 1.0000001, X = 100.
- W = 18.0000018, w' = 18, `left = trunc(100 − 9.0000009) = 90`;
- the unscaled path at 1.0 has `left = 100 − 9 = 91`.

A scale walk that ends a hair above 1.0 is drawn 1 px left/up. sprite-geometry-draw.md §2.3
says the walk clamps to exactly 1.0. [HIGH arithmetic; whether any shipped walk ends ≠ 1.0 —
not checked]

## 6. The three global switches — complete writer scan (INDEX #9, sprite NR 3, critic O10) [HIGH]
**Method 1 — direct TOC-relative stores.** `w3s1-stbscan.py` decodes every word of
`$W/mem/10000000.bin` (910128 B, `0x10000000..0x100de32f`).
- It keeps D-form instructions with RA = 2: `(w & 0xFC1F0000) == (op << 26 | 2 << 16)` for op
  ∈ {stb 38 (0x98…), stbu 39, sth 44, sthu 45, stw 36, stwu 37, stfs 52, stfd 54, stmw 47,
  lbz 34, lbzu 35, lhz 40, lwz 32}.
- A hit is reported when `r2 + d … r2 + d + size − 1` covers `0x100e0171`, `0x100e0172` or
  `0x100e0181`. That catches word and half-word stores that overlap the bytes, as well as byte
  stores.
- Every `addi rX,r2,d` with an effective address in `0x100e0100..0x100e0200` is reported too.

Result (complete list):
| addr | insn | in |
|---|---|---|
| `10018a4c` | `lbz r0,-0x61bf(r2)` | `FUN_10018a40` (read) |
| `1001afd0` / **`1001afdc`** / `1001afe0` | `lbz` / **`stb r0,-0x61bf(r2)`** / `lbz` | unnamed handler at `0x1001afc0` (toggle 0171) |
| **`1001a290`** | **`stb r3,-0x61be(r2)`** | `FUN_1001a290` (set 0172) |
| `1001a714`, `1001aab8` | `lbz …,-0x61be(r2)` | `FUN_1001a6f0`, `FUN_1001aa90` (read) |
| `1001d9fc` `1001db60` `1001dd38` `1001df40` `1001e10c` `1001e2f0` `1001e550` `1001e7b4` | `lbz …,-0x61af(r2)` | the 8 unscaled leaves (read) |
| `1001f054` / **`1001f060`** / `1001f06c` | `lbz` / **`stb r3,-0x61af(r2)`** / `lbz` | unnamed handler at `0x1001f040` (toggle 0181) |
| `1000d074`, `1001fde8` | `addi` → `0x100e0120`, `0x100e0194` | bases used only at +0 (`1000d08c stw r3,0x0(r29)`, `1001fe00 sth r3,0x0(r30)`); no store reaches the targets |

**Method 2 — indirect bases.** `w3s1-basescan.py` follows 853 bases: every `addi rX,r2,d` or
`lwz rX,d(r2)` whose base or loaded pointer lies within ±0x8000 of the targets. It looks 64
instructions ahead for a D-form store through rX whose range covers a target. It found **none**.
No data-image or code-image word points into `0x100e0168..0x100e0188` either (same script).
This scan cannot see stores through a computed pointer (stbx, or pointer arithmetic outside
64 instructions). [MED for that residue]

**The two writers** (`$W/w3s1-ranges.txt`; Ghidra had made no function at either address):
```
1001afc0 … 1001afd0 lbz r0,-0x61bf(r2) ; cntlzw r0,r0 ; rlwinm r0,r0,0x1b,0x5,0x1f ; 1001afdc stb r0,-0x61bf(r2)
         ; 0171 = (0171 == 0) ; prints "Sprite FX Enabled" / "Sprite FX Disabled" (r2+0x7ac+0xd0f / +0xd21)
1001f040 … 1001f054 lbz r0,-0x61af(r2) ; cntlzw ; rlwinm r3,… ; 1001f060 stb r3,-0x61af(r2) ; 1001f064 bl 0x1001a290
         ; 0181 = !0181 ; 0172 = 0181 ; "Sprite Alpha Drawing Enabled" / "…Disabled" (r2+0x183c+0x9f / +0xbc)
```
**How they are reached** (`w3s1-tv.py`, `w3s1-slotscan.py`, `w3s1-blscan.py`):
- `0x1001afc0` is the code word of the TVector `0x100e0908`.
  - That TVector is referenced only by the slot `r2−0x71a4`.
  - The slot is loaded only at `10018890 lwz r5,-0x71a4(r2)`.
  - That load feeds `100188a8 bl 0x1002d080` with name **`FX`** ("Toggles the drawing of special
    effects such as visibility, highlighting, colorisation and scaling.") and **`100188a0 li
    r7,0x1`**.
- `0x1001f040` is the code word of the TVector `0x100e0918`.
  - It is referenced only by the slot `r2−0x7160`.
  - The slot is loaded only at `1001d6b0`, which feeds `1001d6c8 bl 0x1002d080` with name
    **`ALPHA`** ("Toggles the use of the alpha channel when drawing sprites.") and **`1001d6c0 li
    r7,0x1`**. This is in `FUN_1001d5e0` = the "Blitter" module init, called from
    `FUN_10018740`.
- No `b`/`bl` targets either handler. `FUN_1001a290` has exactly one caller, `1001f064`.
- `FUN_1002d080` returns without registering when r7 ≠ 0 (messages-notices-console.md §5.2,
  `1002d0a4`). So **FX and ALPHA do not exist in 1.0.6**. Typing them gives "Unknown Command".

**Conclusion.** `DAT_100e0171`, `DAT_100e0172` and `DAT_100e0181` keep their image value **1**
for the whole session (w3s2's static-init audit covers pre-main writers; none of the
direct/indirect stores above is in a static initialiser). Consequences:
- alpha maps are always used, unscaled and scaled;
- `FUN_10018a40`'s "FX off" branch is dead. That branch copies the command with the 9 × 8-byte
  loop + 2 halves, sets alpha `0x54(r1)` = cmd+0x1c ← 0 and scale `0x50(r1)` = cmd+0x18 ← 1.0,
  and **keeps the mode flags**. So with FX off a shadow would have drawn black and a tint solid.
  [HIGH listing `10018a94..10018ae4`; moot]

INDEX #9 closes.

Also from the listings, `FUN_10018740 @ 10018740` (sprite manager init, caller `FUN_100000e0`
at `100002ac` with `100002a4 li r3,0x0; li r4,0x1`):
- `1001877c stb 1 → 0x100e0180`, `10018784 stw 0 → 0x100e0174`;
- `FUN_10019c00(0, 1)` (`10019c00 stb r3,-0x61b7(r2)` → `0179` = 0 normal port; `10019c04 stb
  r4,-0x61c0(r2)` → `0170` = 1 terrain port). These equal the image values.
- 16 render lists of `0x251c0` = 152000 B = **2000 commands × 0x4c** each (`100187f8 lis r31,0x2;
  10018824 addi r3,r31,0x51c0; bl 0x1000cb60`), with counts 0 (`10018808 stwx r0,r29,r27`).

## 7. Optional items
### 7.1 Render-list reset (sprite NR 2, INDEX #36) [HIGH]
`FUN_100189f0 @ 100189f0`: `lwz r3,-0x7198(r2); li r0,0; stw r0,0x0(r3) … stw r0,0x3c(r3)`. This
zeroes 16 words = the per-layer **counts** array.
- `FUN_1001a450` increments the same array (`1001a480 lwz r31,-0x7198(r2)` …
  `1001a62c lwzx r3,r31,r30; addi; stwx`).
- `FUN_1001a650` loops to it (`1001a658 lwz r4,-0x7198(r2); 1001a66c lwzx r29,r4,r0`).
- The command arrays (`r2−0x719c`) are kept and reused.

Callers, by a raw `bl` scan (`w3s1-blscan.py`):
- `10030388` in begin frame `FUN_10030360`, unconditional (second call after
  `10030380 bl 0x10047f50`);
- `10030250` in start session `FUN_10030210`;
- `100302f4` in the level-transition reset `FUN_100302e0`;
- `10006824` in level start `FUN_100064d0`.

So every layer list is empty at the start of each frame. This raises timing-frame.md §2's "MED
that they are the layer heads" to HIGH: they are the counts read by the flush.

### 7.2 Writer of entity `+0x1a` (sprite NR 5) [HIGH]
`FUN_10035cd0` (create one entity; listing `$W/disasm-bosses2.txt`):
- `10035d10 or. r28,r3,r3` (entity);
- `10035d4c lwz r31,0x94(r28)` (unit def; r31 not reassigned before the store);
- `10035fac lbz r0,0x12c(r31); 10035fb0 stb r0,0x1a(r28)`.

U+0x12c = `adjustShadowLocForScaling_BOOL` (unit-def-struct.md §9). The bank's assumed key is
confirmed for entities. The player path (`FUN_100146f0` and the player constructors) was not
searched.

## Worked example
**Beamer Bullet `bebu` frame 0, drawn with mode 1 (visibility 50 → alpha 16, sprite §4.1), scale
0.5, at (100, 100), game-area clip.**

**Path.**
- `FUN_10012fa0` sets flags |1 and alpha 16.
- In `FUN_10019570`, scale ≠ 1 (`100195dc`), so the scaled path.
- The clip is {0,0,480,416} = `0x100d6d0c`, so `FUN_1001a6f0` (`100198f8`).
- The map exists (frame+0x12 = 1) and `DAT_100e0172` = 1, so with mode byte 1 →
  `1001a868 bl 0x1004d5c0` (alpha 16) → `1001a8a0 bl 0x1001ba40`.

**Frame** (`w3s1-worked.py`: plate scan `frames()` of `docs/deimos/tools/plate_frames.py` on
`Beamer Bullet IA[BEBU].gif`; 16 frames):
- frame 0 rect (t,l,b,r) = (3,3,21,21), so 18 × 18;
- colour key = colour-plate pixel (2,0) = RGB (0,239,0);
- map p = red-5 of the alpha plate (31 or key → 32; an all-32 row → 1000 in column 0);
- RGB8 → RGB555 assumed as `c >> 3` per channel (QuickTime's 8→5 conversion, **not read**,
  LOW).

Map rows 6–10, columns 4–13 (rows 0–3 and 15–17 are empty, so they get the 1000 marker):
```
row 6:  30 30 28 12  0  0  8 24 28 30
row 8:  30 26  0  0  0  0  0  0 22 28
row 10: 30 28 12  0  0  0  0  0 26 28
```
**Geometry** (§5.1, float32):
- W = H = 18 × 0.5 = 9.0, so w' = h' = 9;
- left = trunc(100 − 4.5) = 95, top = 95;
- right = bottom = 104. Clamps x0 = 95, x1 = 104 (< 416), y0 = 95, y1 = 104.

**Column table** (`1001bad8..1001bbc8`): tab[dx] = 2·⌊18·(dx − 95)/9⌋ bytes. That gives sx =
**0, 2, 4, 6, 8, 10, 12, 14, 16** for dx = 95…103.

**First destination row** dy = 95 (`1001bbe4..1001bbf0`): sy = ⌊18·0/9⌋ = 0.
- Source row 0 is an empty row: map (0,0) = 1000, the rest 32.
- Per pixel: dx 95 → (0,0) p 1000 skip (`1001bc30`); dx 96…103 → (2..16, 0) p 32 skip
  (`1001bc28`).
- **Nothing is written in row 95.** Rows 96 (sy 2) and 103 (sy 16) are the same.

**Source → destination map for dy = 99** (sy = ⌊18·4/9⌋ = 8):
| dx | 95 | 96 | 97 | 98 | 99 | 100 | 101 | 102 | 103 |
|---|---|---|---|---|---|---|---|---|---|
| src (sx, 8) | 0 | 2 | 4 | 6 | 8 | 10 | 12 | 14 | 16 |
| p | 32 | 32 | 30 | 0 | 0 | 0 | 22 | 30 | 32 |
| rule | skip | skip | 16+30 ≥ 32 → α 32 = no-op | α 16 | α 16 | α 16 | 16+22 → α 32 no-op | no-op | skip |
At a = 16 every glow pixel with p ≥ 16 vanishes. Only the core (p < 16) is drawn.

**Blended value of dx = 99, dy = 99** (p 0 → `1001bc44..1001bc74`, α = a = 16). Assume
dst = `0x2986` = (R 10, G 12, B 6). The source is plate RGB (239, 0, 49), so src = `0x7406` =
(29, 0, 6).
- R = ⌊(10·16 + 29·16)/32⌋ = ⌊624/32⌋ = 19
- G = ⌊(12·16 + 0·16)/32⌋ = 6
- B = ⌊(6·16 + 6·16)/32⌋ = 6
- → **`0x4cc6`**, which matches the script.

**A partial pixel.** dy = 98, dx = 100 → src (10, 6), p 8, so α = min(16 + 8, 32) = 24
(`1001bc7c..1001bcbc`). Source (156, 0, 33) → (19, 0, 4).
- R = ⌊(10·24 + 19·8)/32⌋ = ⌊392/32⌋ = 12
- G = ⌊12·24/32⌋ = 9
- B = ⌊(6·24 + 4·8)/32⌋ = ⌊176/32⌋ = 5
- → **`0x3125`**.

Unscaled at the same alpha, `FUN_1001db50` would give the same per-pixel values, over all 18
columns of each row.

## NOT RESOLVED (this file)
1. RGB8 → RGB555 conversion of the GIF plates. QuickTime draws them into the 16-bit buffers, and
   the worked example assumes `c >> 3`. This decides every source colour and every map value
   p. Settles: read the `FUN_10021190` load path, or dump a decoded frame from a running game.
2. Indirect stores to `0x100e0171/0172/0181` through a computed pointer (stbx, or a base
   derived more than 64 instructions earlier) are not excluded by §6 method 2. [MED residue]
   Settles: a Ghidra reference search over every write xref to those three addresses.
3. Whether any shipped scale walk ends at a value ≠ 1.0 and so takes the scaled path at w' = w
   with a 1-px anchor shift (§5.5). Settles: enumerate `stateRequiredScalePercent` /
   `stateScaleDeltaPercent` pairs in `$W/data/Game/unde`.
   ⚑ corrected (review wave 3, 2026-10-06) #58 narrowed: walks cannot drift — `FUN_10012840` clamps exactly to the target
   (`10012878`/`100128ac stfs f1,0x84(r3)`) and the target is percent/100.0f (`FUN_1001a260`), so a walk to
   100 % ends at exactly 1.0f (INDEX #58 closed). Left: the data census of states whose target percent is
   itself near 100 (a genuine scale with w′ = w for small sprites) [MED].
4. ~~The player's `+0x1a` writer (`FUN_100146f0` / player constructors): not searched (§7.2).~~ → ⚑ corrected (review wave 3, 2026-10-06) #S: the player's `+0x1a` = 0 from the GameObject reset `FUN_10012650` (`100126f0 stb r12,0x1a(r3)`, r12 = 0 at `10012668`), called by `FUN_100125d0` from the player ctor `FUN_10026260`; no other player store (only four `stb …,0x1a(` in the code range: `100126f0`, `10035fb0`, `1003dff4`, `1004688c`) (critic wave 3 §3).
5. `FUN_1001d1b0`'s caller arguments in `FUN_1002f7a0` (preview scale and clip) — not read.
   Only the leaf body was read.

## Role-table rows (for merge)
| function | module | role | conf | evidence |
|---|---|---|---|---|
| ⚑ corrected `FUN_1001b7d0` | U_SpriteBlit.cc | scaled blit, unclipped, alpha map, mode 0: column table `sx = srcW·(dx−left) div dstW`, `sy` per row; clamp [0,416)×[0,480); p 32/1000 skip, 0 copy, else blend α = p | HIGH | listing `1001b800..1001b828`, `1001b864..1001b880`, `1001b970..1001ba0c` (was LOW "modes 0–3 without / with alpha map") |
| ⚑ corrected `FUN_1001ba40` | U_SpriteBlit.cc | same, mode 1: p 0 → α = a; else α = min(a+p, 32) blend | HIGH | listing `1001bc5c`, `1001bc7c..1001bcbc` (was LOW) |
| ⚑ corrected `FUN_1001bcf0` | U_SpriteBlit.cc | same, mode 2 shadow: p 0 → dst·a/32; else α = trunc(a + 0.032·p²), skip ≥ 32 | HIGH | listing `1001bf0c`, `1001bf24..1001bf94` (was LOW) |
| ⚑ corrected `FUN_1001bfd0` | U_SpriteBlit.cc | same, mode 3 tint: p 0 → tint a; else α = min(a+p, 32) | HIGH | listing `1001c1d0..1001c248` (was LOW) |
| ⚑ corrected `FUN_1001c270` | U_SpriteBlit.cc | scaled blit, unclipped, colour key, mode 0: copy ≠ key | HIGH | listing `1001c2b8..1001c2c4`, `1001c408..1001c450` (was LOW) |
| ⚑ corrected `FUN_1001c480` | U_SpriteBlit.cc | same, mode 1: blend α = a under ≠ key | HIGH | listing `1001c660..1001c698` (was LOW) |
| ⚑ corrected `FUN_1001c6c0` | U_SpriteBlit.cc | same, mode 2: dst·a/32 under ≠ key | HIGH | listing `1001c8a0..1001c8c4` (was LOW) |
| ⚑ corrected `FUN_1001c8f0` | U_SpriteBlit.cc | same, mode 3: tint a under ≠ key | HIGH | listing `1001cad8..1001cb10` (was LOW) |
| `FUN_1001cb40` | U_SpriteBlit.cc | scaled blit, clipped (per-pixel cmd clip, column-major, no clamp), alpha map, mode 0 | HIGH | listing `1001cb7c..1001cc34` |
| `FUN_1001cc60` | U_SpriteBlit.cc | same, mode 1 (α = min(a+p,32)) | HIGH | listing `1001cd24..1001cd9c` |
| `FUN_1001cdc0` | U_SpriteBlit.cc | same, mode 2 (0.032·p² float α) | HIGH | listing `1001ceb0..1001cf44` |
| `FUN_1001cf80` | U_SpriteBlit.cc | same, mode 3 | HIGH | listing `1001d040..1001d0b8` |
| `FUN_1001d0e0` | U_SpriteBlit.cc | scaled blit, clipped, colour key, mode 0 | HIGH | listing `1001d118..1001d188` |
| `FUN_1001d270` | U_SpriteBlit.cc | same, mode 1 | HIGH | listing `1001d308..1001d348` |
| `FUN_1001d370` | U_SpriteBlit.cc | same, mode 2 | HIGH | listing `1001d408..1001d434` |
| `FUN_1001d460` | U_SpriteBlit.cc | same, mode 3 | HIGH | listing `1001d500..1001d540` |
| `FUN_1001d1b0` | U_SpriteBlit.cc | scaled, clipped **opaque** copy of a raw RGB555 buffer (no key, no map); caller `FUN_1002f7a0` (level-select preview) | HIGH | listing `1001d1e0..1001d248` |
| `FUN_1001db50` | U_SpriteBlit.cc | mode 1 fade blit: key → blend a; map: p 32 skip, 0 → a, else a+p, skip ≥ 32; row 1000 skip | HIGH | listing `1001dbb4..1001dc54`, `1001dcac..1001dce4` |
| ⚑ corrected `FUN_1001dd20` | U_SpriteBlit.cc | mode 2 shadow: dst·a/32; partial map p → α = trunc(a + 0.032·p²) (float), skip ≥ 32 | HIGH | listing `1001ddd8..1001de48` (partial branch was MED "lost f1") |
| `FUN_1001e0d0` | U_SpriteBlit.cc | clipped twin of `FUN_1001d9f0` (mode 0): early reject + per-pixel cmd-clip mask, same kernel | HIGH | listing `1001e0d4..1001e108`, `1001e1f0..1001e260` |
| `FUN_1001e2b0` | U_SpriteBlit.cc | clipped twin of `FUN_1001db50` (mode 1) | HIGH | listing `1001e2bc..1001e2ec`, `1001e400..1001e4ac` |
| `FUN_1001e4f0` | U_SpriteBlit.cc | clipped twin of `FUN_1001dd20` (mode 2) | HIGH | listing `1001e51c..1001e54c`, `1001e648..1001e710` |
| `FUN_1001e770` | U_SpriteBlit.cc | clipped twin of `FUN_1001df00` (mode 3) | HIGH | listing `1001e77c..1001e7b0`, `1001e8d0..1001e980` |
| ⚑ corrected `FUN_1001a6f0` / `FUN_1001aa90` | U_SpriteBlit.cc | scaled dispatch: geometry, w'/h' ≤ 0 → none, map iff frame+0x12 && `DAT_100e0172`, alpha → int via `FUN_1004d5c0`, mode byte → leaf (§1.3) | HIGH | listing `1001a714..1001aa6c`, `1001aab8..1001ae9c` (role widened: was head only) |
| `FUN_10019570` | U_Sprite.cc | (add) unscaled inside/clipped/reject classification `X ≥ clipL && X+w < clipR …`; mode priority &1 > &2 > &4; leaf argument layout §1.2 | HIGH | listing `10019754..100197a8`, `100197cc..10019ab4` |
| ⚑ corrected `FUN_1001a290` | U_Sprite.cc (span) | set `DAT_100e0172`; only caller the debug ALPHA toggle `1001f064` | HIGH | listing `1001a290 stb r3,-0x61be(r2)`; bl scan (was MED dump) |
| ⚑ corrected `FUN_10019c00` | U_Sprite.cc (span) | set port indices `DAT_100e0179` ← r3, `DAT_100e0170` ← r4; called once (0, 1) | HIGH | listing `10019c00 stb r3,-0x61b7(r2); stb r4,-0x61c0(r2)`; call `100002a4..100002ac`, `1001878c` (was MED dump) |
| `FUN_10018740` | U_Sprite.cc | sprite manager init: 0180 = 1, ports (0,1), 16 render lists × 2000 commands, blitter init `FUN_1001d5e0`, LOGSPRITE and FX commands (debugOnly → never registered) | HIGH | listing `10018774..100188a8` |
| `FUN_1001d5e0` | U_SpriteBlit.cc | "Blitter" module init: two 0x30 buffers (`sPriv_Buffer`, `sPriv_AlphaBuffer`), ALPHA command (debugOnly → never registered) | HIGH | listing `1001d608..1001d6c8` |
| `0x1001afc0` (no function) | U_Sprite.cc | FX console handler: toggle `DAT_100e0171`; unreachable | HIGH | listing `1001afd0..1001b020`; TV `0x100e0908` ← slot r2−0x71a4 only |
| `0x1001f040` (no function) | U_SpriteBlit.cc | ALPHA console handler: toggle `DAT_100e0181`, copy to `DAT_100e0172`; unreachable | HIGH | listing `1001f054..1001f0ac`; TV `0x100e0918` ← slot r2−0x7160 only |
| `FUN_100189f0` | U_Sprite.cc | zero the 16 render-layer counts (each begin frame, session start, level start/transition) | HIGH | listing `100189f0..10018a38`; callers `10030388`, `10030250`, `100302f4`, `10006824` |
| ⚑ corrected `FUN_1001a450` | U_Sprite.cc | append command to layer list (copy 0x4c, +0x31 = 1, count+1; grows ×2) | HIGH | listing `1001a56c..1001a634` (was MED dump) |
| ⚑ corrected `FUN_1001a650` | U_Sprite.cc | flush layer L in insertion order, skipping `none` and other-layer entries; layers 0/1 set to `none` after drawing | HIGH | listing `1001a658..1001a6c8` (was MED dump) |
| `FUN_10018a40` | U_Sprite.cc | (add) FX-off branch dead in 1.0.6; it keeps mode flags | HIGH | listing `10018a4c`, `10018a94..10018ae4`; §6 |
| ⚑ corrected `FUN_1001c270` … `FUN_1001bfd0` group row | — | replaced by the 8 rows above | — | — |

## INDEX updates (for merge)
- **#9 closed** → §6. `DAT_100e0171/0172/0181` are written only by the FX and ALPHA console
  handlers (`1001afdc`, `1001f060`, `1001a290`). Both commands are debugOnly and never
  registered, so all three stay 1. The critic's O10 hypothesis is confirmed. ⚑ Brief typo:
  `DAT_100e0172` is `−0x61be(r2)`, not `−0x61ae`.
- **#36 closed** → §7.1. `FUN_100189f0` zeroes the 16 layer counts at every begin frame
  (`10030388`). timing-frame.md §2's MED on the meaning becomes HIGH.
- **#37 closed** → §5. Nearest-neighbour, left/top-aligned integer sampling. The unclipped
  scaled path clamps to 416 × 480, the clipped path masks with the command clip. The per-mode
  formulas equal the unscaled ones. The same applies to **hud-scorebar.md NR 2's sampling
  half**.
- **sprite-geometry-draw.md NR 3** closed (§6). **NR 5** closed for entities (§7.2). **NR 6**
  closed (§5). **NR 7** closed (§3.1).
- **sprite-geometry-draw.md §5.2 "[MED for that sub-case]"** → HIGH:
  α = trunc(a + 0.032·p²) (§3.1).
- **sprite-sound-containers.md §2.3a** "Still open: who sets `DAT_100e0181`" → §6.
- **⚑ refinement, not a conflict**, sprite-sound-containers.md §2.3a. It says "per pixel a:
  0x20 → skip, 0 → copy, else blend". That is mode 0 only. Modes 1 and 3 add the command alpha
  (α = a + p), and mode 2 uses the quadratic §3.1. Suggest that sentence gets "(mode 0)".
- New NOT-RESOLVED candidates: NR 1 (RGB8 → 555 plate conversion), NR 3 (scale walks ending
  ≠ 1.0).
