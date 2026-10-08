# Ferazel's Wand 1.0.3 — backdrop compositor (OmniPx, PxMid, cell −1), Titles use sites, CD data

Code readings only; nothing behaviour-verified. Date 2026-10-04.
Sources: main dump `ghidra/Ferazel_pef.decompiled.c`, raw listing `ghidra/Ferazel_pef.disasm.txt` (cited by
address), data section via `tools/const.py` / `tools/tocrefs.py`, resource forks via `tools/rsrc_census.py`
plus small Python PICT/PackBits/DirectBits decoders (this session), the CD volume dump and installer
manifest under `…/Ferazel's Wand/`. TOC r2 = 0x100a7840. Wave 2, lane L4.
Scope: INDEX items 2 (0x26c7 composition, PxMid −1), 12 (Titles use sites), 13 (`Installer Data`),
4 (music 21/27), 24 (OmniPx/PxMid part), 26 (PICT 1026 loader). Read world-data-format §3.2/§3.3 and
save-continue §8.3 first; this file supersedes the "NOT RESOLVED" halves of both.

## 1. The backdrop compositor (needed for both OmniPx and PxMid)

### 1.1 Where the parallax layers are drawn  [HIGH]
The PxBack/PxMid layers are **not** drawn into the frame buffer by `.RedrawScrollGrid`; they are
composited into the screen **while the frame is copied out**:
`.PaintFrameWrap` → `.WrapCopyToScreen @ 100174bc` → `.DoubleBlitUniversal @ 10022e34` →
`.DoubleBlitPPCParallaxOneLayer @ 10017924` (or `…Fire @ 10018dd4`, §1.6). Every output row is built
in the line buffer `*(-0x6838(r2))` and copied to the screen base `*_DAT_1009fd0c + row·rowBytes`.

| gate | raw | effect |
|---|---|---|
| prefs+9 = 0 | `10012744 lbz r3,0x9(r28)`; `cntlzw` → WrapCopyToScreen arg 6 | ≠0 → plain `CopyBits`, no backdrop at all (WrapCopyToScreen) [MED: which UI item sets +9 not traced] |
| prefs+4 = 3 and hdr+0x2722 ≤ 0 | `10022f8c..10022fa8` | DoubleBlitUniversal draws nothing (no copy at all for that rect) [HIGH arithmetic] |
| hdr+0x2722 > 0 (levels 52, 55) | `10022fb4..10022fbc` | Fire variant (§1.6) |
| prefs+2 (Graphics) = 1 / 2 / 3 | `10022fc0..1002307c` | (arg6,arg7) = (0,0) / (0,1) / (1,0): normal / each row written twice / line-skipped (every other row, start row parity-adjusted) |

The source frame is a 640×416 ring buffer: `v' = scrollV mod 416` (`100174cc..10017514`, magic
`0x4ec4ec4f`), `h' = scrollH mod 640`. When `v' − 32 ≥ 1` (`1001754c`) the 384-row view is split into
**two blitter calls**: view rows `0 .. 415−v'` and `416−v' .. 383` (dst tops 8 and `8+416−v'`), each with
an optional second horizontal piece (`param_3/param_5`) handled inside the call [HIGH for the split
arithmetic, MED for the rect plumbing read from the decompile]. Each call restarts the row state of §1.3.

### 1.2 Pixel rules  [HIGH]
Three sources per output byte: **F** = frame port `*_DAT_100a000c` (tiles + sprites + particles, empty
areas 0), **M** = mask port `*_DAT_100a0008` (0xFF where the backdrop may show — boolean FG/sprite
masks are stamped into it, sprites-backgrounds §3.1), and the current layer cell **I** (image) / **K**
(mask) from the 8×6 cell tables at `PTR_DAT_100a1020` (I) and `_DAT_100a101c` (K).

| row mode (`r16`) | byte rule (leading/trailing bytes) | word rule (4-byte, big-endian, aligned in tile space) | raw |
|---|---|---|---|
| back (r16 = 0) | `M == 0xFF ? I : F` (I = PxBack cell) | `M==0xFFFFFFFF → I`; `M==0 → F`; else `F + (M & I)` (32-bit add) | `10018044..1001805c`, `100180e8..10018130` |
| mid (r16 = 1) | `K == 0x00 ? I : F` (I = PxMid sheet *id*, K = sheet *id+1*) | `K==0 → I`; `K==0xFFFFFFFF → F`; else `(K & F) + I` | same byte loop with `r11 = 0` (`10017fa0`), `10018198..100181e4` |

So a **back row** shows the parallax only through the mask port (behind tiles and sprites), while a
**mid row** draws the PxMid art **over everything** (tiles, sprites, particles) and shows F through its
own mask; the PxBack is **not** drawn at all on a mid row [HIGH]. Sheet check (Python decode, this
session): every PxMid pair has image 0 exactly where the id+1 sheet is 0xFF (e.g. 268/269: 18,760 px of
image 0 = 18,760 px of mask 0xFF; 458/459: 33,859 = 33,859) [HIGH data]. Bytes are split as
`lead = ((x+3)&~3) − x`, words `(w − lead) >> 2`, tail `(w − lead) & 3`, all bytes if `w < 5`
(`10017dd8..10017e40`) [HIGH].

### 1.3 Row state machine of one call (as written)  [HIGH unless noted]
Inputs: dst rect top `T` (screen y; view row = T − 8), scroll `(V,H)` = `PTR_DAT_1009fe78` (v,h);
`yb = hdr+0xb26c`, `ym = hdr+0xb26e`; `v0b = V·yb >> 8`, `v0m = V·ym >> 8` (srawi).
1. `qm = trunc((T−8+v0m)/128)` (stack 0xac), `qb = trunc((T−8+v0b)/128)` (0xc0) — `10017a7c..10017ae4`.
2. Initial fill of the 8 col × 6 row cell tables (`10017aec..10017bec`): I[col][row] = PxBack cell
   `(col + trunc((L + H·back[(qb+row)·128] >> 8 − 16)/128), qb+row)`; **K[col][row] = PxMid sheet id+1
   cell `(col + trunc((L + H·mid[(qm+row)·128] >> 8 − 16)/128), qm+row)`**. `back[]` = hdr+0x326c,
   `mid[]` = hdr+0x726c (i16 per virtual row).
3. Per-row factor arrays for view rows 0..479 (`10017c2c..10017c98`): `xb[r] = back[r+v0b]`,
   `ripple[r] = −(rippleTab[r+v0b] >> 8)` (`_DAT_1009ffb8`, non-zero only with hdr+0x26ca, levels 11/18),
   `xm[r] = mid[r+v0m]`.
4. Row-0 refill of I with PxBack for the current factors (`10017ed4..10017f40`). **Mode starts as back**
   (`li r16,0` at `1001793c`; the only other writer of r16 is `1001891c`) [HIGH].
5. Loop rows `y = T .. B−1` (step 1; 2 when arg6/arg7): draw the row from table row `t` (starts 0) at
   sub-row `s` (starts `(T−8+v0b) mod 128`); then `s += step`; if `s > 127`: `s −= 128`, `t += 1`
   (next table row, `local_64/68 += 4`).
6. **Mode is re-decided only where a factor changes**: if `xb[r] == xb[r+step]` and
   `xm[r] == xm[r+step]` nothing happens; else (`LAB_1001886c`, raw `10018880..1001891c`)
   `r16 = (xm[r+step] ≠ 0) && hdr+0x3268 == 1`, and:
   - mid: for `k = 0 .. min(2, 6−t)−1`, all 8 cols: I[t+k] = sheet **id** cell, K[t+k] = sheet **id+1**
     cell, both at `x = col + trunc((L + H·xm[r] >> 8 − 16)/128)`,
     **`y = int16(qm + ((n − qm) >>> 7)) + k`** where `n` = rows processed so far in this call (stack
     0x88) and `>>>` is a logical shift (`10018a10..10018aa8`: `subf; rlwinm r3,r0,0x19,0x7,0x1f`);
     then `s = (T−8 + v0m + n) & 0x7f` (`10018b1c..10018bdc`). Because `GetPxMidTile` → `.ConstrainXY`
     sign-extends to 16 bits (`1003be0c..1003be6c`), the y is effectively `qm + floor((n−qm)/128)`
     (floor division, also for `n < qm`), then clamped to `[0, h1−1]`.
   - back: I[t] only (current row) refilled with PxBack at `y = qb + t` and `s = (T−8+v0b+n) & 0x7f`;
     its x adds the row's ripple, `x = col + trunc((L + H·xb[r] >> 8 + ripple[r] − 16)/128)` (`10018974
     add`, array through TOC `−0x682c` at `10018938`; non-zero only on levels 11/18) ⚑ corrected (review 2e, 2026-10-04) #3.
   Table rows `t+2..5` keep whatever the initial fill or an earlier refill put there.
   - extra refill trigger: a stack flag `0x86` (`100187c4 stb r0,0x86(r1)`, set when stack `0xe0 ≠ 0` and stack `0xb0 > 0x280`,
     `100187a8..100187c4`) also forces the re-decision; likely dead in the shipped modes [MED] ⚑ corrected
     (review 2e, 2026-10-04) #4.

### 1.4 Consequences a replica must copy  [HIGH arithmetic; MED where noted]
- A call that starts inside the mid region with constant factors draws **PxBack**, not PxMid, until a
  factor change (step 4 + 6).
- The as-written mid y ignores the sub-tile phase of `v0m` and subtracts a tile index from a pixel
  count; with the shipped data it lands **exactly one cell row above** the geometric row
  `floor((T−8+v0m+n)/128)` at every reachable scroll (§1.5) [MED: simulation]. In general it can be
  0, −1 or −2 rows off.
- After two sub-row wraps inside one mid run the table row `t+2` still holds the *initial* fill
  (I = PxBack cell, K = PxMid mask cell) — a PxBack texture shown through a PxMid silhouette. Not
  reached by shipped data (§1.5) [MED].

### 1.5 What the shipped levels actually show (Python transcription of §1.3, all `V ∈ [0, 32·H − 384]`)  [MED]
PxMid is enabled (hdr+0x3268 = 1) in exactly the 14 levels that name a PxMid sheet (hdr+0x284e ≠ 0):
10, 15, 21, 22, 30, 31, 40, 45, 50, 51, 52, 55, 62, 70 [HIGH, census]. In every one the mid factor
table is 0 up to a start row, then 384 (×1.5), then 128 from row 5001 (level 22: from row **6001**,
census — ⚑ corrected (review 2e, 2026-10-04) #2; LOW that the §1.5 simulation was affected); `ym` ≈ 1.25–1.31 (320..335)
except level 45 (`ym` = 1) [HIGH, census]. The ×1.5 horizontal rate and the >1 vertical rate make the
PxMid a **near-foreground band** at the bottom of the level [LOW: intent].

| level(s) | sheet | mid starts at virtual row | band visible for V in | cell rows drawn (as written) | geometric rows | −1 cells drawn | stale rows |
|---|---|---|---|---|---|---|---|
| 10, 31, 50, 51, 62, 70 | 268/288/298/298/348/348 | 2177 | 1392..1536 | 16, 17 | 17, 18 | none | none |
| 15 | 458 | 2177 | 1371..1536 | 16, 17 | 17, 18 | none | none |
| 40 | 318 | 2177 | 1384..1536 | 16, 17 | 17, 18 | none | none |
| 21 | 258 | 2432 | 1610..1696 | 18 | 19 | none | none |
| 22 | 378 | 4994 | 3599..3712 | 38, 39 | 39, 40 | none | none |
| 30 | 278 | 1025 | 514..640 | 7, 8 | 8, 9 | none | none |
| 45 | 318 | 5001 | never (`ym` = 1) | — | — | — | — |
| 52, 55 | 298 | 2177 | Fire variant: PxMid never drawn (§1.6) | — | — | — | — |

The ring split never falls inside the band at any reachable V (no band row is lost to step 4) in the
normal graphics mode; the same holds for the doubled and line-skipped modes apart from the skipped
rows themselves. Every band tile row of the main grid (tile rows 53..64 depending on level) has a BG or
FG tile in every cell (0 empty cells of 768..3,584 per level), so the missing PxBack behind a mid row
is never exposed [HIGH data; the "never exposed" reading also needs BG face transparency — MED].

### 1.6 Fire variant (levels 52 and 55)  [HIGH]
`.DoubleBlitPPCParallaxOneLayerFire @ 10018dd4` composites the flame GWorld `*_DAT_1009fe84` (rows
offset by a 70-entry wobble table `_DAT_100a00c4` unless hdr+0x2722 = 2) through the same `M`/`F` byte
and word rules; it has no `bl` to `GetPxBackTile`/`GetPxMidTile` (only `1009e1ec`, `10000128`, `1009ed2c`,
`10000148` in `10018dd4..100196e8`). Levels 52/55 therefore never show their PxBack (297) or PxMid
(298) sheets.

## 2. PxMid cell −1 / 0xFFFF (INDEX item 2 remainder) — CLOSED

### 2.1 The two indexing sequences  [HIGH]
```
10017ba4  bl 0x1003c59c          ; GetPxMidTile → r3 = i16 cell (−1 for 0xFFFF)
10017bac  extsh r0,r3
10017bb0  rlwinm r0,r0,0x2,0x0,0x1d   ; ·4
10017bb4  lwzx r3,r18,r0          ; r18 = r2−0x286c = 0x100a4fd4 (PxMid sheet id+1)
10017bc0  addi r0,r3,0x60         ; → port row table
...
10018a78  bl 0x1003c59c
10018a80  extsh r0,r3
10018a84  rlwinm r0,r0,0x2,0x0,0x1d
10018a88  lwzx r3,r17,r0          ; r17 = r2−0x289c = 0x100a4fa4 (PxMid sheet id)
10018aa0  lwzx r3,r18,r0          ; 0x100a4fd4 again
```
No compare of the cell value anywhere between the call and the `lwzx` (both ranges listed above).
`GetPxMidTile` (`1003c59c..1003c624`) returns the raw `lha` — no −1 handling there either.

### 2.2 Bytes read for −1  [HIGH]
| table | base | entry [−1] = address | what lives there at run time | static (const.py) |
|---|---|---|---|---|
| PxMid sheet id (I in mid mode) | 0x100a4fa4 (12 ptrs) | **0x100a4fa0** | PxBack port **35** (PxBack table 0x100a4f14, 36 ptrs, ends 0x100a4fa4) | 0 (filled by `.LoadPxBackTileset` 1000224c) |
| PxMid sheet id+1 (K) | 0x100a4fd4 (12 ptrs) | **0x100a4fd0** | PxMid **image** port **11** (entry 11 of 0x100a4fa4) | 0 (filled by `.LoadPxMidTileset` 10002344) |

Both are valid ports whenever a PxMid sheet is loaded, so nothing crashes.

### 2.3 What a −1 cell would draw  [HIGH arithmetic]
- In the **initial fill** (K only): a −1 cell puts image tile 11 into K; K is dereferenced only on a mid
  row whose table row was not refilled (the stale case, §1.4) — never in shipped data.
- In a **mid refill**: I = PxBack tile 35, K = PxMid image tile 11. Byte rule: `tile11 == 0 ? back35 : F`;
  word rule: `w11 == 0 → back35`, `w11 == 0xFFFFFFFF → F`, else `(w11 & F) + back35` (32-bit add with
  carries). Image tile 11 has no 0 pixels in sheets 268, 258, 288 (Python) — so such a cell would be a
  per-word garbage mix of frame and PxBack 35.
- In a **back row** the K table is not read (`10018000 bne` selects `*_DAT_100a0008` as mask), so −1
  in the PxMid map is harmless there.

### 2.4 Reachability  [MED: simulation of §1.3; HIGH for the map data]
No shipped, reachable state draws a −1 PxMid cell (§1.5 table: the drawn rows 16/17, 18, 38/39, 7/8
contain no −1). The **geometric** rows would: level 15 row 18 has −1 in columns 128..199 (Python), and
columns up to ≈150 are reachable — a replica that "fixes" the row arithmetic must then also decide
what −1 shows. Replica rule: port §1.3 literally; −1 never occurs.

### 2.5 "No PxMid tileset" path  [HIGH]
hdr+0x3268 is 0 in all 10 levels without a PxMid sheet (census), so r16 never becomes 1 there and the
id/id+1 tables are never dereferenced (§2.3). `_DAT_1009ff68` (set by `LoadPxMidTileset`) still has no
reader; `.DisposePxMidTileset @ 100027f8` is an empty function (`return`), so a previous level's PxMid
ports stay allocated and stay in the tables.

## 3. OmniPx (hdr+0x26c7) — CLOSED

### 3.1 What it is  [HIGH mechanism; LOW for the name's intent]
A 128×128 off-screen blit port (`*0x100a00b4` slot → variable 0x100f97e4) that **replaces PxBack cell 0**
and is **rebuilt every drawn frame** from (a) an optional animated base copied from other PxBack cells
and (b) up to 16 wrapping 128×128 overlay faces, each scrolled by its own parallax factor and constant
drift. While it is on, `.GetPxBackTile` returns 0 for every cell (`1003c4f8 lbz r0,0x174(r5)` …
`1003c510 li r3,0x0`), so the whole PxBack layer is this one port tiled every 128 px; it is shown only
through the back-mode mask (§1.2), i.e. behind tiles and sprites. Effectively a multi-layer infinitely
tiling backdrop (rain sheets, drifting particles) instead of a map.

### 3.2 Life cycle  [HIGH]
| step | where | what |
|---|---|---|
| level start | `.SetupLevel` stores `G+0x174 = 0` then `bl SetupOmniPx` at `10004e18` | |
| first call ever | `10019db0..` | clears the 16 face pointers 0x100a36fc once (flag `*0x100a00b0`) |
| mode 0 | `10019e10..10019e1c` | `G+0x174 = 0`, return (off) |
| port | `10019e34` `NewBlitPort(128,128, *_DAT_1009ff8c)` (level+sprite CLUT); fail → `ReportError`, off | also sets the load CLUT `*_DAT_1009ff94 = *_DAT_1009ff8c` and never restores it [MED] |
| layer arrays | zeroes fx 0x100a373c, fy 0x100a375c, vx 0x100a377c, vy 0x100a379c, accX 0x100a37bc, accY 0x100a37dc (16 i16 each) | |
| per mode | `10019f88..1001a148` (§3.3) | faces + parameters |
| `.TurnOnOmniPx` | `1001a14c` → `10019ac4..10019b88` | if `G+0x174` already set: return. Set it; **for modes ∉ {4,5,6,7}** back up and zero all 8192 PxBack x-factors (hdr+0x326c) and `yb` (hdr+0xb26c) into 0x100f00a8 / 0x100f40a8 (TOC slots `0x100a00c0`/`0x100a00bc`, loaded `10019ae4`/`10019acc`; ⚑ corrected (review 2e, 2026-10-04) #1) (`10019b04..10019b54`); save PxBack slot 0 to 0x100f97e0 and store the port there (`10019b70..10019b84`) |
| level end | `.GameLoop` exit `1000a46c` `TurnOffOmniPx`, `1000a474` `KillOmniPx` | TurnOff restores slot 0 and **always** copies the backup buffer back into hdr+0x326c/0xb26c (also after modes 4..7, whose buffer is stale/BSS zero) — harmless because every level start re-reads `Mlvl` from disk (`.OpenDefaultWorldLevel` `DetachResource`, 10048ac0) [MED: harmless]; Kill disposes faces and port |

### 3.3 Setup per mode (raw `10019f88..1001a148`; registers r31 faces, r30 fx, r29 fy, r28 vx, r27 vy)  [HIGH]
| mode | levels (census) | face 0 / face 1 (`Load1EncFaceFromPICT`, Sprites) | fx, fy (/256) | vx, vy (1/256 px per drawn frame) | base refresh (§3.4) | backdrop grid |
|---|---|---|---|---|---|---|
| 0 | other 19 | — | — | — | — | normal PxBack |
| 1 | 15 Storm Valley | 6000 (0x1770) / 6001 (0x1771) | 0x40 / 0x80 | f0: +0x100, +0x500; f1: +0x200, +0x800 | none | screen-fixed (factors zeroed) |
| 2 | 5 Manditraki Warrior | 6201 (0x1839) / 6200 (0x1838) | 0x40 / 0x80 | f0: −0x80, −0x200; f1: +0x80, +0x400 | PxBack cells 6..14 | screen-fixed |
| 3 | — | none | — | — | none | screen-fixed |
| 4 | — | as mode 2 | as 2 | as 2 | cells 6..14 | level factors kept |
| 5 | 25 Manditraki Wizard | 6301 (0x189d) / 6300 (0x189c) | as 2 | as 2 | cells 6..14 | level factors kept |
| 6 | 70 Purple Haze | none | — | — | interlaced cells 1..29 | level factors kept |
| 7 | — | none | — | — | ping-pong cells 0..28..1 | level factors kept |
| ≥ 8 | — | none | — | — | none | screen-fixed (TurnOn zeroes) |

Mode 1 also writes fx/fy[3] = 0xaa then 0xc0, fx/fy[4] = 0xd2, fx/fy[5] = 0xe6 and `0x100a3802 = 0`
(`1001a020..1001a068`); faces 3..5 are never loaded, so these writes are **dead** (UpdateOmniPx skips a
null face, `1001a640..1001a648`; no other access to 0x100a3742..3766/0x100a3802 in either dump) [HIGH].
PICT 6200 and 6300 are byte-identical (sha256 prefix `ace346500df0`) [HIGH data].

### 3.4 Per-frame update `.UpdateOmniPx @ 1001a434`  [HIGH]
Called from `.PaintFrameWrap` at `10012708`, after `DrawParticles` (`10012700`) and before
`WrapCopyToScreen` (`10012774`), inside the draw branch (`10011fc4 rlwinm. r0,r19…; 10011fd4 beq`) —
so only on **drawn** frames (half rate with "Reduce frame rate"), and the result is on screen in the
same frame. Counter `c` = i16 at 0x100f97e8 (slot 0x100a008c; loaded only here; BSS, starts 0, never
reset between levels).
1. Base (rect 0,0,128,128, `CopyBitsCTForce` = QuickDraw `CopyBits` after copying the colour-table
   seed):
   - modes 2, 4, 5 (`1001a470..1001a4ec`): `if c ≥ 18: c = 0`; copy PxBack cell `6 + (c>>1)`
     (`0x100a4f2c + 4·(c>>1)`) over the port. `c` is *not* incremented here.
   - mode 6 (`1001a4f8..1001a55c`): `c += 1; if c ≥ 58: c = 0`; `.InterlaceBlit128(cell 1+(c>>1), port, c&1)`:
     copies rows `c&1, c&1+2, …, 126+(c&1)` (64 rows × 128 B; `1001a184..1001a40c`, row pointers at
     port+0x60, 16 iterations × 4 rows).
   - mode 7 (`1001a568..1001a610`): `c += 1; if c ≥ 56: c = 0`; copy cell `c` if `c < 29` else `56−c`.
2. Faces (`1001a614..1001a834`), i = 0..15, skip null: `c += 1`;
   `accX = (accX + vx) mod 0x8000`, `accY = (accY − vy) mod 0x8000` (16-bit store, then +0x8000 if
   negative; the `≥ 0x8000` test on a sign-extended `lha` can never fire);
   `x = −(((accX>>8) + (H·fx >> 8)) rem 128)`, `y = −(((accY>>8) + (V·fy >> 8)) rem 128)` (truncating
   rem, then negated, x,y ∈ (−128,0]); `BlitEncFaceClipX(face, port, srcPt 0 (word at 0x100a15c4 = 0),
   (y,x), 128,128)` — transparent pixels (value 0) skipped, clipped to the 128×128 port; if `x≠0 || y≠0`
   also at (x+128,y), (x+128,y+128), (x,y+128) so the face wraps toroidally.
   Net per drawn frame with two faces: `c += 2` → in modes 2/4/5 the base advances one cell per frame
   (9-frame cycle).

### 3.5 On-screen composition per mode  [HIGH mechanism; MED for the visual readings]
Back-row pixel (§1.2) where the mask port is 0xFF = port pixel at
`((viewX + offX) mod 128, (viewRow + offY) mod 128)`; with the factors zeroed (modes 1–3) `offX = offY = 0`
(grid fixed to the 608×384 view, anchored at its top-left), else the level's own PxBack factors move the
grid (level 25: ×1.0 both axes; level 70: ×0.25). Layer order inside the port: base, face 0, face 1.
| mode / level | what the player sees behind the tiles |
|---|---|
| 1 / 15 | face 6000 (opaque: 0 transparent pixels in its 8-bit PICT) moving at ¼ camera speed, drifting 1 px/frame left and 5 px/frame down; over it face 6001 (92.5 % transparent) at ½ camera speed, 2 px left / 8 px down — slanted rain sheets; plus particle rain and thunder (§3.6) |
| 2 / 5 | PxBack cells 6..14 of sheet 600 cycling one per frame; face 6201 at ¼ speed drifting ½ px right / 2 px up; face 6200 at ½ speed ½ px left / 4 px down (both mostly white = transparent after remap: 70–81 % pure white in the DirectBits PICTs) |
| 5 / 25 | same as 2 with sheet 601 and faces 6301/6300, grid moving 1:1 with the camera |
| 6 / 70 | PxBack cells 1..29 of sheet 357, each cell blended in over two frames by odd/even rows (58-frame cycle), grid at ¼ camera speed |
Sheet check (Python, per-cell non-zero coverage): sheets 600 and 601 have **exactly** cells 6..14 painted
(1.0) and the other 27 empty (0.0); sheet 357 is fully painted [HIGH data] — the data matches the code.

### 3.6 Mode 1 extras: `.GenerateRain @ 100109c0` (every logic frame, drawn or not, `10011ee4..10011ef0`)  [HIGH constants; MED flow]
- First call per level (`*_DAT_1009fe88 == 0`; SetupLevel clears it after SetupOmniPx): timer
  `T = 90 + FastRand(90)` (`100109f0..100109fc`), start looped `snd 452` "rainloop.snd" (`STPlayLoopedSound`,
  `10010a14`; handle `*_DAT_1009fe24` ← `FUN_10091748(0x1c4)` in `.InitSounds`).
- Thunder: `T > 0`: `T −= 1`. `T == 0`: lightning flash `*_DAT_100a00fc = 3` (alternate-buffer flicker in
  PaintFrameWrap), `snd 453` "thunder.snd" (`10010a40..10010a58`), `T = −1`. `−1 → −2`. `−2`:
  `GammaFadeOutAsync(2, …, 0xc, 0x10)`, three `HandleAsyncGammaFade`, `GammaFadeInAsync(0x6e)`, `T = −3`.
  `T < −2`: `T = 210 + FastRand(150)` (`10010ae8..10010af4`).
- Drops: x from `H + FastRand(50)` stepping `50 + FastRand(200)` while `< H + 660`; y = `V` (top of
  view); per drop 3 `NewParticle`s; style `0x4b3 + FastRand(2)`: 0x4b3 = kinds 7,6,5 with (5, vx −1200,
  vy 3600), each next particle **4 px lower and 1 px left**; 0x4b4 = kinds 7,7,6 with (4, −700, 2100),
  each next 2 px lower and 1 px left only when `FastRand(100) > 50` (`10010bb4`, `10010c3c`)
  (`10010b28..10010ca0`; particles §5.1) ⚑ corrected (review 2e, 2026-10-04) #5. Particle kinds →
  particles.md §4.

### 3.7 Counter/side notes
- The flash buffer shown during `_DAT_100a00fc` is the mask port itself (`10012754 lwz r5,-0x7838(r2)` is
  `_DAT_100a0008`), composited with the same rules: backdrop where 0xFF, mask value elsewhere [HIGH].
  With parallax on this shows the backdrop with silhouettes of every tile/sprite in palette index 0 [MED:
  index 0's colour depends on the level CLUT].

## 4. Titles file use sites (INDEX item 12) — CLOSED
Method: every `bl` to `GetPicture`, `GetCTable`, `.MTGetandDrawPICTResInRect`, `.DrawPicInGWorld`,
`.DrawPicInRect`, `.DrawPICTToBackScreen`, `Load1*/Load*Set*/Cache*FromPICT` in the whole code section
(Python over the raw listing, r3/r4 source per site), the computed-id sites read individually, all `DITL`
picture items in every fork, and a grep of both dumps for each id (decimal and hex). Resource chain at
front-end time: Sprites → Sounds → Titles → (prefs) → Installer Data → app (§6.3); none of the Titles ids
also exists in Sprites/Sounds (census), so every id below resolves to Titles.

### 4.1 PICT (67)  [HIGH for call sites; screen names MED where from context]
| id | size | use site | screen / when |
|---|---|---|---|
| 128 'Loading Screen' | 640×480 | `.main` `1001065c li r3,0x80` → DrawPICTToBackScreen | boot loading screen when the screen is **not** 640×480 (screen CLUT = clut 128) |
| 129 'Game Screen' | 640×480 | `.SetupLevel` 10004fd0, `.ContinueGame` 1000de0c, `.ChapterScreen` 10009ce8, `.ShowWorldMap` 1007c5a4 | frame around the 608×384 view |
| 130 | 640×480 | `.DrawMainMenu` 10002fa0 | main menu at exactly 640×480 (sets menu flag `*PTR_DAT_1009ff5c = 0`) |
| 131 'Publisher Logo' | 640×480 | `.main` 100103f0 | first screen after `SwitchTo8BitColorMT` |
| 132 | 640×88 | `.InitAppGlobals` 10000fd0 → port 0x100ab9d8 | status bar (`.UpdateStatusBar`, `.Pause`, `.UpdateTextStats`, `.UpdateItemStat`, `.UpdateHealthMagic`) |
| 133 | 196×45 | `.InitAppGlobals` 10001014 → port 0x100ab9dc | HUD health/magic piece (`.UpdateHealthMagic` 10008464) |
| 134 | 640×480 | `.DrawMainMenu` 10002fbc | main menu on any other screen size (flag = 1) |
| 136 | 640×480 | `.main` 10010648 | boot loading screen at 640×480 |
| 137 | 640×480 | **no code reference** | — |
| 138 | 640×480 | `.AskToContinue` 10007230 | death / continue screen (death clut 132) |
| 140 | 320×110 | `.InitAppGlobals` 1000112c → port 0x100ab9f0 | `.StageCompleteEffect @ 10005950` (stage-complete panel) |
| 141 | 52×714 | `.InitAppGlobals` 10001160 → port 0x100ab9f4 | `.FillPercent @ 10005510` (stats bar strip) |
| 142 | 320×64 | `.InitAppGlobals` 10001190 → port 0x100ab9f8 | `.PopupStageLoad @ 10005ba0` (level-loading popup) |
| 159 / 161 / 162 | 640×416, 640×416, 640×128 | `.Victory` 1000ad24 / 1000add0 / 1000ae7c (`GetPicture` → `DrawPicture` into ports 000c / 0004 / 0008) | victory scroll (`.CopyVictoryStitch`), victory clut 260 |
| 172..177 | 82×82 | `.WandGlow @ 10006b6c`: `172+i` for i 0..5, then `182−i` for i 6..10 (`10006c1c`, `10006c30`), 5 ticks each, rect (138,286)–(220,368) | death screen after choosing Continue |
| 4600..4607 | various | `.Victory` → `.CreditScreen(id, s)` `1000b050..1000b0dc`: 4600 s=30, 4601 s=5, 4602..4606 s=8, 4607 s=30 | end credits; each centred on black for `s·30` ticks, any key = next, Esc = skip all; screen clut 801 |
| 4610, 4620, …, 4670 | 640/608×480 | `.ChapterScreen(n)` `10009c0c addi r3,r3,0x11f8` with `n·10` → `4600 + 10n`, n = hdr+0x273c ∈ 1..7 | chapter card, clut `280+n`; shown from `.GameLoop` 1000a0cc when the level has no save/completion yet; ≤ 1200 waits of 1 tick, any key/button skips |
| 4803 | 144×811 | `.Credits @ 1000e5b4` → `.DoAboutDialog(600, 0x12c3)` → `GetPicture` 10078624 | scrolling credits strip in DLOG 600 (main-menu Credits button) |
| 4804 | 200×276 | `DITL 600` item 1 picItem (rect 0,0,276,200) | background of the same credits dialog |
| 4901..4905 | 154×42 … 83×42 | `.TrackClickOnCommandButton @ 10002c5c`: `0x1324 + n` (10002d5c) | main-menu button n **highlighted**: 1 New Game, 2 Continue, 3 Options, 4 Credits, 5 Quit (`.MainMenu` 1000e618) |
| 4911..4915 | same | `+10` | same buttons, normal state (redrawn on release) |
| 4925 / 4935 | 83×42 | `10002d64 cmpwi r30,0x1329` → `li r30,0x133d` when the 134 menu is up | Quit button highlighted / normal on the non-640×480 menu |
| 4921 | 225×96 | `.Pause` 100061d4 | pause banner, rect (207,152)–(432,248) + window origin |
| 4951..4955, 4961..4965 | 194×53 … 109×53 | **no code reference** | (≈1.26× scaled copies of 4901..4915 [LOW: purpose]) |
| 4970 / 4971 | 138×22 / 117×21 | `.TrackClickOnCommandButtonDeath @ 10006970`: `0x1369 + n` | death-screen buttons normal: 1 Continue (→ WandGlow), 2 quit (→ `.TurnGray`) |
| 4980 / 4981 | same | `0x1373 + n` (100069fc) | same, highlighted |
| 4985 | 32×28 | `.AskToContinue` 100072a8, 100074d4, 10007588 | keyboard/ISp selection cursor at (190,388) or (190,410) |
Note: holding a main-menu button and sliding in/out of it more than 9 times plays `snd 199` via `SndPlay`
(`TrackClickOnCommandButton`, MED).

### 4.2 clut (16)  [HIGH for the GetCTable sites]
| id 'name' | site | role |
|---|---|---|
| 128 'splash screen clut' | `.InitAppGlobals` 10000bb0 → `_DAT_100a79ac`; `.main` 10010614 `SetScreenClut` | screen CLUT for loading screens 128/136 |
| 130 'main menu clut' | 10000bf8 → `_DAT_100a79b0`; `.DrawMainMenu` 10002f60 | main menu |
| 131 'preview clut' | 10000c40 → `PTR_DAT_100a002c`, and again 10000c88 → `_DAT_100a0028` ("demo CLUT") | **loaded twice, never read** (both slots loaded only at 10000a0c/10000a08) |
| 132 'death clut' | 10000e38 → `_DAT_100a0014` | `.AskToContinue` 100071a0, `.TurnGray` 10006ccc |
| 260 'Victory' | 10000df0 → `_DAT_100a0018` | `.Victory` 1000ac5c |
| 281..287 (intro, forest, desert, fire, ruins, ice, mountain chapter) | `.ChapterScreen` 10009ba8 `addi r3,r31,0x118` (`280+n`) | chapter cards; data n: level 1→1, 10→2, 40→3, 50→4, 22→5, 30→6, 62→7 (census of hdr+0x273c) |
| 288, 289, 290 'interstitial 1–3', 729 'splash screen clut orig' | **no code reference** (no `GetCTable` site yields them; `n` ≤ 7 in data; no `PICT 4680+` exists) | — |
Error-string names in `.InitAppGlobals` (pstrs at 0x100a272e..0x100a2867) also name app-fork cluts 801
"system", 700 "world map", 200 "sprite", 199 "sprite grays", 198 "cooling" [HIGH].

### 4.3 Gamma fades (`10035310..10035918`, Monitor-Tool `MT_FadeToColor`/`MT_FadeCustom`)  [MED]
| routine | behaviour |
|---|---|
| `.GammaFadeOut(steps,…)` | blocking fade to a colour via `MT_FadeCustom(0,100,…)`; marks the screen faded (`*_DAT_1009fde8 = 1`) |
| `.GammaFadeIn(n)` | blocking: percent 0→100 in steps of `100/(3n)` (≥1), one tick each, then 100; shows cursor |
| `.GammaFadeInSlow(n)` | two `MT_FadeToColor` calls with duration arg `max(100, 33n)` |
| `.GammaFadeOutAsync(n,col…)` / `.GammaFadeInAsync(n)` + `.HandleAsyncGammaFade` (once per GameLoop iteration) | step k of n: `MT_FadeToColor(0, col or NULL, 100k/n, 0, 1)`; out ends at 100 with the colour, in ends with `(0,0,0)` (raw `100357cc..100358b8`) |
Exact library semantics of the third argument: NOT RESOLVED (third-party Monitor Tool).

## 5. PICT 1026 loader (INDEX item 26 part) — CLOSED: never loaded  [HIGH for the search; MED overall]
No instruction in the code section has the immediate `0x402` (the only textual hits are `subi r31,r2,0x4024`
and `subi r28,r2,0x4022`). Computed-id loader sites and their ranges (i ≥ 0 loop indices): `750+i` (i < 27),
`1330+i`, `1480+i`, `1490+i`, `1500+i`, `2700+i`, `2805+i`, `2850+i`, `2870+i`, `2902+i`, `2920+i`,
`2950+i`, `3000+i`, `3080+i`, `3100+i`, `3200+i` (main l. 52318–52330, 56136, 58765–58830,
61892–61911), `4600+10n`, `172+i`, level-header
ids (PxBack 207..601, PxMid 258..458, FG 200..380, BG 203..380, pattern 206..511, Px sprite 265..385),
conversation pictures `Mcnv +0x80a` (4001..4033) — none can produce 1026. The player set skips 0x402
between `0x401` and `0x403` (`.InitPlayerSprite`). PICT 1026 (400×152, 38,682 B) is dead data; so is
PICT 1054 (400×76, no `0x41e` either) [HIGH].

## 6. CD volume, `Installer Data`, music 21/27

### 6.1 Volume contents (`(volume)/`, recursive)  [HIGH]
842 files (639 non-empty) in 60 directories: `Ferazel's Wand Installer` (66,864,235 B, VISE 3),
`Installer Data` (10,934 B + 3,201 B resource fork), `Read Me Before Installing` (4,139 B),
`AppleShare PDS`, `Frontend Resources - QT` (4 QuickTime movies), `Web Site urls ƒ` (4),
`Other Goodies from Ambrosia ƒ` (627 non-empty files: other Ambrosia products and add-ons), HFS
system folders, and the 66 whitespace-named 0-byte entries at the root. No AIFF/AIFC file and no file
named `21`/`27` anywhere on the volume (`find` by name; the only "music" files are EV/Maelstrom/Chiral
add-on archives).

### 6.2 `Installer Data` — CLOSED (item 13 remainder)  [HIGH]
- Finder type/creator `????`/`????`.
- **Data fork**: an RTF document (Word export, `{\rtf1\ansi…`), ≈1,320 words: "Ferazel's Wand Plot
  Writeup 1", dated Friday 31 July 1998, by Josh Rothman — the design backstory (habnabits, the
  Manditraki, the stolen wand, Ferazel's quest), ending in pasted e-mail MIME residue. Not game data.
- **Resource fork**: `PICT 32000` (32×32, 2,754 B), `STR  128` "Ferazel's Wand Installer",
  `STR# 128` {"Installer Data", "Ferazel's Wand"}, `vers 128` (1.0). **No `PICT 7000`** → the app fork's
  PICT 7000 is the one drawn (save-continue §8.4's caveat is void). None of these type/id pairs exists
  in the app, Titles, Sprites, Sounds, Backgrounds or World Data forks, so the open fork shadows nothing.

### 6.3 The CD check in `.main`  [HIGH]
Machine hash from Gestalt `cput, mach, rom , romv, sysv, pclk, lram` (`((cput+0x45)·mach + rom)·romv +
sysv)·pclk + lram`, −1 → −2; `100100bc..10010160`, `100100d0 addi r22,r4,0x45`) compared with
prefs+0x3a (`10010180`); on mismatch `OpenResFile("Ferazel's Wand:Installer Data")` (`10010194 subi
r3,r2,0x4281` = pstr 0x100a35bf, decoded; `1001019c bl`), i.e. a file at the root of a volume named
"Ferazel's Wand", `GetVRefNum`,
`PBHGetVInfoSync`; any failure → DLOG 1600 "CD Request" (`GetNewDialog(0x640)`, OK → `ExitToShell`).
The file's contents are never read; the fork is never closed (stays in the chain under the files opened
later). On success the hash is written to prefs+0x3a (`ChangedResource`/`WriteResource`), so the CD is
asked for again only when the hardware/system signature changes.

### 6.4 Music 21 and 27 (INDEX item 4) — CLOSED AS UNDETERMINABLE for the "why"; facts HIGH
| evidence | finding |
|---|---|
| every `.SetAIFFMusic` call (raw, whole code) | constants 24 (`.main` 1001052c, `.NewGame` 1000b550, `.ContinueGame` 1000d84c), 25 (`.ShowWorldMap` 1007c798), 29 (`.Victory` 1000acb4), 30 (`.GameLoop` 1000a27c); hdr+0x284a (`.GameLoop` 1000a060); the current track re-played (`0x100a5be0`, `.Pause` 10006398, `.MakeCurrPrefs` 1000e3d0); its own retry `n−1` (10049594) |
| level data | hdr+0x284a ∈ {1,2,3,4,5,6,8,9,10,12,13,15,16,17,18,22,23,26,28} |
| installer catalog (`manifest.csv`) | AIFC entries are contiguous at stride 0xbc: `20` @0x24e3 → `22` @0x259f, `26` @0x288f → `28` @0x294b — **no catalog slot was ever there** |
| demo installer manifest | ships only 01, 06, 09, 24 |
| CD volume | no stray tracks (§6.1) |
| shipped documentation | the manual's blurb promises "a pulse-quickening, awe-inspiring soundtrack of 30 songs" (`Ferazel's Wand Documentation`); the CD read-me says the music folder's tracks are required to run |
| also unreferenced but shipped | 7, 11, 14, 19, 20 (durations 64–72 s, Python from COMM; assuming 64 frames per `ima4` packet) |
So 21 and 27 were never in the installer and are never requested; a request would fall back to 20 / 26
(`SetAIFFMusic` retries `n−1` when the open fails). STR# 1000 names three levels with no `Mlvl` (32 "Ice
Caverns 3", 35 "Ice Boss", 60 "Mountains"); tying the 7 unused/missing track numbers to cut content is
[LOW] — the binary and data cannot settle why 21/27 were dropped.

### 6.5 Tables that could name tracks  [HIGH]
None exists. App: `STR# 300` 'Warning Strings' (QuickTime music errors), `STR# 400` 'Fatal Error
Strings', `MENU 130` (Music / Sound Effects toggles), `Tune 6900` 'dummy' (29,580 B; no
`GetResource('Tune')` — no `0x54756e65` in the code; `.InitMusic` only opens the QuickTime `'tune'`
component, `OpenDefaultComponent(0x74756e65)`). World Data: `STR# 500` 'signs', `STR# 1000` 'level
names' (99 slots, 27 non-empty). Music files' own forks: SoundEdit 16 leftovers (`STR  −16396`
"SoundEdit 16 version 2"). The file name is the only track identity (`:Ferazel's Wand Music:NN`).

## NOT RESOLVED
1. Exact visual output of `MT_FadeToColor`'s percent argument (Monitor Tool library; §4.3). Tried: raw of
   `HandleAsyncGammaFade`; the library body is outside this binary's named code.
2. Which preferences UI writes prefs+9 (parallax composite off) — the gate is read at `10012744`; the
   writer was not traced (lane scope: compositor only).
3. Colour of palette index 0 in each level CLUT, needed to describe the lightning-flash silhouettes and
   the transparency of the DirectBits OmniPx faces 6200/6201/6300 after QuickDraw remapping (white → 0
   assumed, MED). Tried: 8-bit faces decoded exactly; DirectBits faces measured as "pure white"
   fraction only. ⚑ corrected (review 2e, 2026-10-04) #6: cross-reference lighting-tables §1.4 —
   entries 0x00..0x9f of every "+ base" level CLUT equal `clut 200`, whose entry 0 is ffffff (white),
   and lighting-tables §4 (unwritten table 4 → index 0, white); the palette half is therefore settled
   [HIGH data]; the QuickDraw remapping of the DirectBits faces stays MED.
4. Why tracks 21/27 (and 5 others) are unused — undeterminable from code/data (§6.4).
5. Intended use of Titles PICT 137, 4951..4965 and cluts 288..290, 729 — no reference; purpose LOW.

## Proposed additions to physics.md §0
None (no sprite fields involved).

## Corrections to the existing bank
| # | file § | old | new | evidence |
|---|---|---|---|---|
| 1 | engine.md §3 draw order | "parallax+tile grid (`.SetScrollLocation` → `.RedrawScrollGrid`) … OmniPx, copy to screen" | the parallax layers are composited **during the copy to screen** (`WrapCopyToScreen` → `DoubleBlitUniversal` → `DoubleBlitPPCParallaxOneLayer`/`Fire`); `RedrawScrollGrid` only fills the tile frame | this file §1.1; `10022ff0..1002307c` are the only calls of the two blitters |
| 2 | engine.md §3 parallax paragraph | "PxMid likewise" (implies both layers drawn) | a screen row is **either** a back row (PxBack behind tiles/sprites through the mask port) **or** a mid row (PxMid over everything, no PxBack); mid rows exist only when hdr+0x3268 = 1, and mode changes only at factor-change rows | §1.2–1.3; `1001793c`, `1001891c` |
| 3 | world-data-format.md §3.2 row 0x3268 | "parallax enable (1 in 16 levels)" [MED] | **PxMid enable**: 1 in **14** levels, exactly those with hdr+0x284e ≠ 0 (10,15,21,22,30,31,40,45,50,51,52,55,62,70) [HIGH] | census; `1001890c lha r3,0x3268(r3); cmpwi r3,0x1` |
| 4 | world-data-format.md §3.2 row 0x726c | "PxMid per-scanline x-parallax factor" | also the row-mode selector: 0 = back row, ≠0 = mid row (if 0x3268 = 1); shipped values 0 / 384 / 128 | §1.3 step 6; census §1.5 |
| 5 | world-data-format.md §3.3 PxMid row | "how −1 is handled at draw time NOT RESOLVED" | no test; reads entries [−1] (PxBack port 35 / PxMid image port 11); never reached with shipped data; harmless on back rows | §2 |
| 6 | world-data-format.md §3.2 row 0x26c7 | "draw composition still open" | closed: §3.3–3.5 of this file | raw `10019f88..1001a148`, `1001a434..1001a834` |
| 7 | save-continue.md §8.3 / NR 3–4 | OmniPx composition and PxMid −1 NOT RESOLVED; "`uRam100a3742..3766` set only in mode 1" (role open) | closed (§2, §3); the mode-1 writes to layers 3..5 and 0x100a3802 are dead (faces 3..5 never loaded) | `1001a048..1001a068`, `1001a640..1001a648` |
| 8 | save-continue.md §8.4 caveat, NR 5 | `Installer Data` contents unknown | RTF plot write-up + tiny fork (PICT 32000, STR 128, STR# 128, vers 128); no PICT 7000 → the app's copy wins unconditionally | §6.2 |
| 9 | sprites-backgrounds-sounds.md §7 | "the remaining ids' use sites NOT RESOLVED"; "128/729 splash, 131 preview, 288..290 interstitials" | every id mapped (§4.1/4.2); 137, 4951..4955, 4961..4965, cluts 288..290 and 729 have no reference; clut 131 loaded twice and never read; 140 = stage-complete panel, 142 = loading popup, 133 = health/magic HUD | §4 |
| 10 | sprites-backgrounds-sounds.md §3 table, PxMid row | "two sheets id and id+1 … plain" | sheet id = image (0 = transparent), id+1 = mask (0 = opaque, 0xFF = clear); stored in 0x100a4fa4 / 0x100a4fd4 | §1.2 decode |
| 11 | player-states.md §7 (and player-states-2 NR 4) | PICT 1026 "unused or loaded by computed id" | unused: no `0x402` immediate, no computed site can yield it; PICT 1054 also unused | §5 |
| 12 | world-data-format.md §1 | "Why 21 and 27 are missing … NOT RESOLVED" | facts closed (never catalogued by the installer, never requested, fallback n−1); the reason is undeterminable | §6.4 |
| 13 | engine.md §3 | `.DisposePxMidTileset` not mentioned | it is empty: PxMid ports persist across levels | `100027f8` (`return`) |

## ⚑ Corrections (R3 build, 2026-10-09; Ben: follow the binary)
1. **§1.1 corner piece.** When v' − 32 > 0 and h' − 32 > 0, the corner is always composited through `.DoubleBlitUniversal`,
   backdrop or not: `100178b8 b 100178c8` jumps over the CopyBits at `100178bc`, which nothing branches to [HIGH].
2. **§1.3 line-skip (graphics 3).** A call whose dst top is odd starts one screen row lower (`10017a6c..10017a78`) but
   still reads its first source row there (source row = src.top + (y − adjusted top), `10017fb0..10017fcc`); piece 2
   uses the unadjusted dst2 top (`10018304..10018328`) [HIGH].
3. **§1.5 / plan p19.** One call draws view rows 0..383 and compares the factor of row 383 with row 384, so on level 1
   at V 10 the back row is re-decided only at 273→274; the 410→411 change lies past the drawn rows [HIGH].
4. Header 0x271e (the 0x86/0x85 flags) is 0 on all 24 levels; the late re-decide branch (`100187a8`, view row > 0x280)
   is dead as written [HIGH data].
