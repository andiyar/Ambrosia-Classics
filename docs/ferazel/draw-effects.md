# Ferazel's Wand 1.0.3 — sprite draw effects (`+0xb8` modes), the light-overlay gate, burn-away

Code readings only; nothing behaviour-verified. Date 2026-10-04.
Sources: raw listing `ghidra/Ferazel_pef.disasm.txt` (every HIGH cites `10xxxxxx` addresses from it),
`ghidra/Ferazel_pef.decompiled.c` ("main dump") and `ghidra/Ferazel_handlers.decompiled.c` ("handler
dump") for structure; jump table and constants read with `tools/const.py`, TOC slots with `tools/tocrefs.py`.

Scope (wave 2, lane L2): WHICH blitter each `+0xb8` value selects and what it does per pixel; the
`+0x88` gate; `.HandleBurn` / `.BurnFaceRow`. The **colours** inside the remap / tint / blend / light
tables are lane L1's (`lighting-tables.md`); this file names the table and the index, never a colour.
Particle kinds and `.NewParticle` argument meanings are lane L3's; this file gives the raw arguments only.

TOC r2 = 0x100a7840; a TOC slot `-0xNNNN(r2)` is the global at `0x100a7840 − 0xNNNN`.

## 1. The per-sprite draw pipeline (`.WrapDrawSprites @ 100144c8`)

### 1.1 Order of operations for one sprite  [HIGH]
For each sprite on the active list:
1. Skip if `+0xe9` (dead) or `+0xc0` (face) is 0 (`1001452c`, `10014538`), or if the face rect
   offset by the sprite position misses the 608×384 view rect (`SectRectFast`, `1001457c`).
2. Source window in face-local px: rows `[+0x1bc, min(+0x1ba, h))`, columns `[+0x1b6, min(+0x1b8, w))`;
   the destination point is shifted down/right by `+0x1bc`/`+0x1b6` (`10014600..10014684`).
   (`+0x1bc` is the burn clip of §4.)
3. `face+0x1a ← +0x1aa` (rotation, degrees), `face+0x1c ← +0x1ae` (scale /256) (`10014688..10014698`).
   If scale < 0x100 **and** rotation = 0, the destination point moves by
   `(visible extent · (0x100 − +0x1ae)) >> 9` in both axes — the shrunken image stays centred
   (`100146a0..100146ec`).
4. **Effective mode** `m` = `+0xb8` (loaded `10014604`), then two overrides:
   - **hurt flash**: if `+0xaa ≠ 0`, `n = min(+0xaa, 7)`; `m = 0x30000 + n`, or `0x40000 + 2n` when
     `+0x1b4 ≠ 0` (`100146f0..10014728`). `+0xb8` itself is not touched — the class's own tint
     returns when the flash ends. `.StandardSpriteHandles` decrements `+0xaa` by 1 per frame
     (`10036880..10036890`), so a flash of N frames shows tables 7,7,…,6,5,…,1.
   - **dynamic light** (`+0x89 ≠ 0`, face present): `L = .GetLightTile(cx>>5, cy>>5)` (cx = `+0x10`,
     cy = `+0xe`), `F` = `.GetFakeLight(…)`; if `L < 1 ∧ F < 1` then `m = +0xb8 = 0`, else
     `m = +0xb8 = 0xc0000 + L·0x100 + F` (`1001472c..100147bc`; L = −1 with F ≥ 1 gives `0xbff00 + F`,
     i.e. mode 0xb, not 0xc — ⚑ corrected (review 2a, 2026-10-04) #4). This runs **after** the hurt flash
     and overwrites it: a `+0x89` sprite never shows a hurt flash [HIGH].
5. **Water split** by `+0x11c` (rows of the face above the water surface; 1 = fully submerged,
   physics §0) — tested on the stored `+0xb8`, not on `m` (`100147c0..1001491c`):

   | condition | draws (`.WrapDrawFace`) |
   |---|---|
   | `+0x11c < 1`, or stored mode = 0xe, or `+0x18c ≠ 0` | one draw, mode `m` (`1001480c`) |
   | `+0x11c == 1` | one draw, mode **`0x60000 + +0x128`** (water ripple, kind = `+0x128`) — `m` is ignored, so a fully submerged sprite shows neither its tint nor its hurt flash (`1001491c`) |
   | `+0x11c > 1` | rows above the line with `m`, height `+0x11c − +0x1bc` (`10014864`); then rows from `max(+0x11c, +0x1bc)` down with `0x60000 + +0x128` (`100148e4`) |
6. `face+0x1a = 0`, `face+0x1c = 0x100` (`10014924..10014938`).
7. **Light overlay** (§3) if `+0x88 ≠ 0` ∧ prefs+6 ≠ 3 ∧ stored mode ≠ 0xe (`1001493c..1001499c`).
8. Last-frame copies, among them `+0xbc ← +0xb8` (`100149dc..100149e0`), `+0xc8 ← +0xc0`.

`.WrapDrawFace @ 100151c4` only clips to the view and wraps the destination into the 640×416 ring
buffer (`x mod 0x280`, `y mod 0x1a0`, up to four `.BlitEncFaceX` calls); the mode word passes
through unchanged [HIGH, main l. 10360–10425 structure; no mode logic].

`.WrapEraseSprites @ 10014a58` (dirty-rectangle restore of last frame's image) forces an erase when
last frame's mode `+0xbc >> 16` was 0xb or 5 (`10014d08..10014d1c`), or `+0x1b3` (burning) is set,
among other triggers. A replica that redraws the whole frame needs none of this [HIGH for the test].

### 1.2 `.BlitEncFaceX @ 1002c908` — dispatch  [HIGH]
`mode = arg >> 16`, `sub = arg & 0xffff` (`1002c9a8..1002c9b4`); `rot = face+0x1a`, `scale = face+0x1c`,
`flip = +0x17e`. Mode 0xa forces the clipping variant and keeps `sub` for the mask pass
(`1002cc50..1002cc5c`).

| mode | rot = 0 ∧ scale = 0x100, not flipped | flipped | rot ≠ 0 or scale ≠ 0x100 |
|---|---|---|---|
| 0 | `.BlitEncFaceNoClipX` / `ClipX` (`1002cca8`/`1002ccc8`) | `.BlitEncFaceFlipNoClip` / `FlipClip` (`1002ccf0`/`1002cd10`) | Scale / Rot (below) |
| 1, 2, 3, 4, 7, 9, 0xa, 0xc, 0xf, 0x10..0x13 | `.BlitEncFaceSpecialNoClipX` / `SpecialClipX` (`1002cd98`/`1002cdc0`) | `.BlitEncFaceFlipNoClipSpecial` / `FlipClipSpecial` (`1002cdf0`/`1002ce18`) | Scale / Rot |
| 5 | `.BlitEncFaceDiffuse` (`1002d160`) | `.BlitEncFaceFlipDiffuse` (`1002d188`) | Scale / Rot |
| 6 | `.BlitEncFaceWaterRipple` (`1002cfdc`) | `.BlitEncFaceFlipWaterRipple` (`1002d004`) | Scale / Rot |
| 8 | `.BlitEncFaceBehindTilesNoClip` / `Clip` (`1002cf84`/`1002cfa4`) | **same, unflipped** (no flip test, `1002cf5c`) | Scale / Rot |
| 0xb | `.BlitEncFaceTransClip` (`1002ceec`) | `.BlitEncFaceTransFlipClip` (`1002cf1c`) | Scale / Rot |
| 0xd | `.BlitEncFaceTransRippleClip` (`1002cf54`) | same (no flip test) | Scale / Rot |
| 0xe | `.BlitEncBoolFace{NoClip,Clip}` value `sub & 0xff` (`1002d0b0`/`1002d0d8`) | `…FlipNoClip/FlipClip` (`1002d104`/`1002d128`) | Scale / Rot |
| 0x14 (or ≥ 0x15 when hdr+0x26c6 = 0) | `.BlitEncFaceTileBlend` (`1002d04c`) | same | Scale / Rot |
| ≥ 0x15, hdr+0x26c6 ≠ 0 | `.BlitEncFaceTileBlendSpecial(…, mode − 0x15, sub)` (`1002d074`) | same | Scale / Rot |

Scale / Rot: `rot = 0 ∧ not flipped` → `.BlitEncFaceScale(…, mode, sub, scale)` (`1002ceac`); otherwise
`.BlitEncFaceRot(…, mode, sub, rot, scale, flip, clip)` (`1002ce7c`) (§2.9).

**Mask pass** (`1002d18c..1002d2c0`): when mode < 0x14, mode ≠ 0xd, rot = 0 and scale = 0x100, the
face is drawn a second time as a boolean silhouette of value **0** into the mask buffer
`*_DAT_100a0008` (`li r9,0x0` before each call): `.BlitEncBoolFaceWaterRipple` /
`FlipWaterRipple` for mode 6 (`1002d1f0`/`1002d214`), else `.BlitEncBoolFace{NoClip,Clip,FlipNoClip,
FlipClip}` (`1002d248..1002d2c0`; the Clip call carries `sub` for mode 0xa). Scale and Rot write the
0 into the mask inline (decompile of `.BlitEncFaceScale` / `.BlitEncFaceRot`: `*param_2 = 0`,
`*puVar18 = 0`) [HIGH for the calls; MED inline].

### 1.3 The mask buffer `*_DAT_100a0008`  [HIGH for reads/writes; MED for the purpose]
The second 640×416 port (engine §2). FG tile drawing marks pixels where the background shows
(sprites §3.1 rule 4); a byte **0xff = nothing opaque here yet** — the parallax back layer will be
painted into it later. Every ordinary sprite draw writes 0 under its silhouette (mask pass above), so
the parallax fill skips it. Two blitters read it:
- mode 8 (`.BlitEncFaceBehindTiles*`) draws only where the mask is non-zero (§2.5);
- mode 0xb/0xd (`.BlitEncFaceTrans*`): where the mask is 0xff the "background" operand of the blend
  is the parallax pixel computed on the spot by `.CalcPxRowContents @ 10027aac` (it reads
  `.GetPxBackTile` cells), not the draw buffer (§2.7).
(bosses-2 NR 1 calls it "the flash buffer"; it is this mask.)

## 2. Mode table

### 2.1 Summary — every `+0xb8` value the code writes  [HIGH dispatch; colours → L1]
Writers from a scan of every `stw rX,0xb8(rY)` in the raw listing (241 stores; 11 on the stack, 1
in `.DrawBlackLines` on a non-sprite record, 229 on sprites) and the decompiled constants. "Table" = 256-byte remap `T[pixel]`.

| `+0xb8` | mode → blitter | per pixel (opaque source pixel `s`, destination `d`) | parameters | writers (classes) |
|---|---|---|---|---|
| 0 | plain copy | `d = s` | — | everyone (default `.InitSprite` `1003d504`) [HIGH rule; writer list from the decompile scan, MED] |
| `0x1nnnn` | 1 → Special | `d = T1[nn][s]`, `T1[k] = *_DAT_100a0140 + k·0x100` (`.BuildTintTable`) | sub = table index | power-up/pickup glints 0x10008/0x10009 (player, shots, Bonus, Box, Warrior/Wizard/Xichra wound glow); statue/strong variant 0x1000b; Frog/Blob/Crawler/Dillo/Walker variants (0x10002, 3, 4, 0xb, 0xc, 0xf, 0x10..0x15, 0x17); Background/Box/decor `0x10000 + p` from placement data; geyser head 0x10017/0x1000c; spokes 0x10018 (`.SetRadiusSpritesEffect`); Effect 0x10005 [HIGH rule; writer list from the decompile scan, MED] |
| `0x3000n` (draw time only) | 3 → Special | `d = T3[n][s]`, `T3[k] = *_DAT_100a0178 + k·0x100` (`.BuildReddenTable`) | n = min(`+0xaa`,7) ∈ 1..7 | hurt flash, any sprite [HIGH rule; writer list from the decompile scan, MED] |
| `0x4000n` (draw time only) | 4 → Special | `d = T4[n][s]`, `T4[k] = *_DAT_100a0174 + k·0x100` (`.BuildReddenTable`) | n = 2·min(`+0xaa`,7) ∈ 2..14 | hurt flash when `+0x1b4` (Warrior, Wizard, Demon, ice wall 2941) [HIGH rule; writer list from the decompile scan, MED] |
| `0x5000n` | 5 → Diffuse | with probability n/30: `d = 0x99 + rand(6)`; else `d = s` | n 0..15 | player teleporter charge (`100510ec`) [HIGH rule; writer list from the decompile scan, MED] |
| `0x6000k` (draw time only) | 6 → WaterRipple | row shifted by −1/0/+1 px (§2.4); `d = T6[k][s]`, `T6[k] = *_DAT_100a0170 + k·0x100` (`.BuildWaterTintTable`) | k = `+0x128` water kind | the submerged rows of any sprite (§1.1 step 5) [HIGH rule; writer list from the decompile scan, MED] |
| `0x80000` | 8 → BehindTiles | `d = s` only where mask ≠ 0 (§2.5) | — | parallax strip sprites `.SetupPxSprite` (`10033480`, with `+0x88 = 0`) [MED rule: the raw is a word add `and r9,r9,r24; add r23,r23,r9` (`10026be4..10026bec`), equal to a copy only if the destination holds 0 under each 0xff mask byte (§2.5, NR 4) — ⚑ corrected (review 2a, 2026-10-04) #1; writer list from the decompile scan, MED] |
| `0x90000` | 9 → Special | `d = T6[0][s]` — the water tint **without** ripple | sub always 0 | Crab, spikes and teleporters placed in water (`.SetupCrabSprite`, `.SetupBackgroundSprite`, `.SetupBoxSprite`) [HIGH rule; writer list from the decompile scan, MED] |
| `0xa0000 + q` | 0xa → SpecialClip | raw copy, rows squashed vertically by q/256 (§2.6) | q < 0xfb | springboard gauge (`10064914`) [HIGH rule; writer list from the decompile scan, MED] |
| `0xb0000 + a` | 0xb → Trans | `d = B[a][s·256 + bg]` (§2.7) | a ∈ {0,1,2,4,5} written | fades/blinks: crumble/blink platforms, floes, trails, dead Blob, Floater fade-in, Demon/Xichra shots, Bonus/Box blinks, Gremlin back layer, spirit (0xb0001/0xb0005), parallax decor 0xb0004 [HIGH rule; writer list from the decompile scan, MED] |
| `0xc0000 + L·0x100 + F` | 0xc → Special | F = 0: `d = *_DAT_100a0130 + L·0x100`[s]; F ≠ 0: `d = (*_DAT_100a0134 + L·0x6e00 + F·0x100)[s]` (`.CalcLightingTable` / `.InitLighting`) | L = signed high byte, F = low byte; a negative D never reaches this blitter from the `+0x89` writer: D = −1 turns the word into `0xbff00 + F`, mode **0xb** (D = 254, level 30, arrives here as signed −2) (`rlwinm 8; addis 0xc`, `100147a4..100147b0`; lighting-tables §2.2) ⚑ corrected (review 2a, 2026-10-04) #4 | `+0x89` dynamic light (§1.1); radial spokes and depth-mode pendulums (`.UpdateRadiusSprites` `1003dbd0`, `.UpdateRadialPos` `1003e264`) [HIGH rule; writer list from the decompile scan, MED] |

No sprite writer stores modes 2, 3, 4, 6, 7, 0xd, 0xe, 0xf, 0x10..0x13 or ≥ 0x14 in `+0xb8` (scan
above; 3/4/6 exist only as draw-time values). The INDEX's "modes 7, 0x10..0x13" are **mode-1 table
indices** (0x10007 player debug tint; Walker tiers 0x10010..0x10015, `.SetupWalkerSprite`
`10067638..10067758`) [HIGH].

### 2.2 Table modes 1, 3, 4, 9, 0xc in `.BlitEncFaceSpecial*`  [HIGH]
`.BlitEncFaceSpecialClipX @ 100271d4`: `cmplwi r25,0xc; bgt` then a 13-entry jump table at TOC
`−0x3adc` = `0x100a3d64` (bytes read: 0→`272b4`, 1→`27224`, 2→`272b4`, 3→`27290`, 4→`272a4`,
5→`272b4`, 6→`27238`, 7→`272b4`, 8→`272b4`, 9→`27238`, 0xa→`272b4`, 0xb→`272b4`, 0xc→`2724c`;
`272b4` = no table). Cases: 1 `lwz r25,-0x7700(r2)` (0x100a0140) `10027224..10027230`;
6/9 `-0x76d0` (0x100a0170) `10027238..10027244`; 0xc `1002724c..1002728c` (`srawi r5,r25,8` signed
L, `rlwinm r5,r25,0,24,31` F, `mulli r25,r5,0x6e00`, slots `-0x7710` = 0x100a0130 / `-0x770c` =
0x100a0134); 3 `-0x76c8` (0x100a0178) `10027290..1002729c`; 4 `-0x76cc` (0x100a0174)
`100272a4..100272b0`. The sub is `extsh`'d then `·0x100`. The copy loop is `d = T[s]` over every
op-2 (literal) byte of the RLE stream; op-3 skips leave the destination untouched (transparent)
(decompile `param_3 + (uint)*(byte*)…`). `.BlitEncFaceSpecialNoClipX @ 100276ac`,
`.BlitEncFaceFlipNoClipSpecial @ 10029310`, `.BlitEncFaceFlipClipSpecial @ 10029588`,
`.BlitEncFaceScale`, `.BlitEncFaceRot` carry the **same** switch (decompile) [HIGH for ClipX; MED
for the other five].

Modes with no table entry (2, 7, 0xf, 0x10..0x13 and 0xa outside the clip path): the table
register keeps the caller's third argument (the source-offset point) and the blitter reads
"`T`" from that address — undefined output. Unreachable from shipped writers (§2.1) [HIGH for the
fall-through; behaviour moot].

### 2.3 Mode 5 — diffuse sparkle (`.BlitEncFaceDiffuse @ 10029988`)  [HIGH]
Per literal pixel: `rand(30) < n` → `d = 0x99 + rand(6)` (palette indices 0x99..0x9e), else `d = s`
(`10029b60..10029b94`: `li r3,0x1e; bl .FastRand; cmpw r0,r17; bge` copy; `li r3,6; bl .FastRand;
addi r0,r3,0x99; stb`). Flipped twin `@ 10029c6c` (`10029e58`, `10029e70`, `10029e7c`). The
player's n: `|t|` of the teleporter-charge timer 21..59 → `clamp((|t|−12)/4 + 2, ≤15) + rand(6) − 3`,
clamped 0..15, with `+0x18c = 1` (main l. 46315–46335, `100510b4..100510ec`).

### 2.4 Mode 6 — water ripple (`.BlitEncFaceWaterRipple @ 10029f70`)  [HIGH]
Per destination row y (buffer row, after clipping): the row's start pointer is offset by
`R[((*_DAT_1009fd74 >> 8) + y) mod 35]` px (`1002a244..1002a284`: `srawi r11,r11,8`, `mulli
…,0x23`, `lhax r11,r6,r11` with r6 = TOC `−0x7728` = `_DAT_100a0118`), then every literal pixel
`d = T6[k][s]` (r25 = TOC `−0x76d0` = 0x100a0170, `10029f78`). `R` is built by `.BuildSineTable`
(`100201e0..1002024c`): `R[i] = trunc(1.5 · sin(i · 0.17951943))` for i = 0..34 (f32 0.1795194 =
2π/35 at 0x100a1730, f64 1.5 at 0x100a1728, `fctiwz`) =
`0,0,0,0,0, 1×9 (i=5..13), 0×8 (14..21), −1×9 (22..30), 0,0,0,0` (computed with the binary's float
steps; no value is near a rounding edge). The phase `*_DAT_1009fd74` += 0x100 once per painted
frame in `.PaintFrameWrap` (`100127ec..100127f4`, right after `.WrapEraseSprites`), so the wave
advances one row per frame. Quirk: the offset is also added to the column counter used for the
left/right clip tests, so a horizontally clipped rippled sprite clips one pixel off [MED].
Flipped twin `@ 1002a300` (same slots, `mulli …,0x23` `1002a610`). The mask pass uses the same
ripple (`.BlitEncBoolFaceWaterRipple`).

### 2.5 Mode 8 — behind tiles (`.BlitEncFaceBehindTilesClip @ 100269c4`)  [HIGH code; MED purpose]
r6 = TOC `−0x7838` (`_DAT_100a0008`, the mask) at `100269d8`. Per 4-byte group of a literal run
(`10026bd0..10026bec`): `if (mask_word ≠ 0) d_word += s_word & mask_word`; the 2-byte and 1-byte
tails do the same (`10026c0c..10026c54`; the last byte: `if mask ≠ 0: d = s`). With mask bytes of
0xff over empty (0) destination pixels this is "copy where the mask says the background shows,
keep the FG tile / earlier sprite elsewhere": the sprite appears **behind** the foreground tiles
and behind sprites drawn before it. [MED: that the draw buffer holds 0 under every 0xff mask byte —
needed for the word add to equal a copy — is inferred, not traced.] No flip variant exists.

### 2.6 Mode 0xa — vertical squash (`.BlitEncFaceSpecialClipX`, `sVar9 == 10` arms)  [HIGH]
Accumulator `acc = 0x100` at entry (`100271f0 li r6,0x100`). At every row token, while still in the
top-clipped rows the row is skipped as usual (`100275f8..10027610`); otherwise
`acc += q; row_ptr_for_this_row = current dest row; if acc ≥ 0x100 { dest row += 1; acc −= 0x100 }`
(`10027614..10027630`; the row pointer is taken at `10027620` before the advance at `10027628`).
Pixels are copied **raw** (no table, `10027508..` byte copy). Since q < 0x100 at most one advance
happens per row, so (first visible row j = 0) source row j lands on destination row 0 for j = 0 and
`1 + ⌊j·q/256⌋` for j ≥ 1: several source rows overwrite one destination row (opaque pixels only),
and the image is about `2 + ⌊(h−1)·q/256⌋` rows tall, top-anchored. The springboard gauge (Platform 0x58e) draws `0xa0000 + q` with
`q = ((top + 0x2d − y') << 8) / 0x2d` while 11 ≤ q < 0xfb, plain when q ≥ 0xfb
(platforms-ropes-radial §2.8). [MED: the flip twins have no mode-10 arm, so a flipped gauge would
read an undefined table — no flipped gauge is known.]

### 2.7 Mode 0xb — translucency (`.BlitEncFaceTransClip @ 10027d04`)  [HIGH]
At entry `li r15,0xd` (`10027d0c`) and `stb r15,0(r7)` (`10027d74`) store 0x0d into the 512-byte
buffer at `0x100a39b6` (meaning: lighting-tables §6.2 / NR 5) ⚑ corrected (review 2a, 2026-10-04) #5.
Blend table by `a` (`10027d28..10027dfc`): a = 0 → `*_DAT_100a015c` (`−0x76e4`), 1 → `0158`
(`−0x76e8`), 2 → `0154` (`−0x76ec`), 3 → `0150` (`−0x76f0`), 4 → `014c` (`−0x76f4`), 5 → `0160`
(`−0x76e0`); any other a → `*_DAT_100a0144 + (short)(a − 0x80) · 0x1000` (`10027de4..10027df8`,
`rlwinm r0,r0,0xc`). Per literal pixel (`10027fe0..10028054`):
- `bg = (mask byte == 0xff) ? parallax pixel (.CalcPxRowContents, computed once per run then walked)
  : d` (`cmplwi r0,0xff` `10027fe8`);
- `d = B[(s << 8) + bg]` (`rlwinm r3,r26,8,0,23; add r0,r3,r0; lbzx r0,r28,r0`).
So the **row index is the sprite pixel, the column the background** — this settles platforms §2.8's
open "which operand is the sprite pixel". For a ≥ 0x80 the source is first remapped,
`s' = (*_DAT_100a0148)[s]` (`10028090..10028098`, slot `−0x76f8`); no writer uses a ≥ 0x80. The mask
pass then writes 0 under the silhouette, so the parallax fill will not overwrite the blended
pixels. `.BlitEncFaceTransFlipClip @ 100287cc` loads the same eight slots (tocrefs) [MED for its
loop]. Combined with platforms §2.8's table formulas (½/½, ¾·row+¼·col, ¼·row+¾·col for a = 0/1/2 —
L1 to confirm), a = 1 is the most opaque and a = 2 the most transparent of the three; tables for
a = 3, 4, 5 → L1.

### 2.8 Modes 0xd, 0xe, ≥ 0x14  [HIGH for "no sprite writer"]
- 0xd `.BlitEncFaceTransRippleClip @ 10028220`: translucency (same eight slots) with the ripple
  phase (`10028254`, `100286dc`, `10028724`); never written to `+0xb8`.
- 0xe: draws the silhouette in the single palette index `sub & 0xff` (`.BlitEncBoolFace*` with
  value `uVar13 & 0xff`; the value byte is replicated into a word at `100238fc..1002393c`) and
  suppresses the light pass and the water split (§1.1). Never written to `+0xb8`.
- ≥ 0x14: FG tile/pattern blends (`(w + 0x15) << 16 | pattern`, sprites §3.1 rule 2); not sprite modes.

### 2.9 Rotation and scale  [MED]
`.BlitEncFaceScale @ 1002bdc0`: nearest-neighbour **reduction only** — a 8.8 accumulator gains
`scale` per source pixel/row and emits one destination pixel/row each time it passes 0xff, so
scale > 0x100 cannot enlarge; mode 0 copies `s`, any other mode uses the §2.2 switch table (main
dump `.BlitEncFaceScale` l. "switch(param_7)"; `param_7 == 0` branch), mask byte 0 written per
emitted pixel. `.BlitEncFaceRot @ 1002ac00`: forward mapping of each source pixel about the face
bounds centre by `cos/sin` tables `_DAT_100a0164/_DAT_100a0168[angle]` (flip → angle 360 − angle and
x mirrored), both multiplied by `scale/256` when scale ≠ 0x100; each pixel is written **two
destination pixels wide** to plug holes, same switch table, mask 0. Modes 5, 6, 8, 0xb under
rotation/scale fall into the table branch with no table (undefined) — the shipped rotated/scaled
sprites (radial spokes, pendulum links, chain links) use modes 0, 1 or 0xc [MED: Rot loop not read
in raw].

## 3. The `+0x88` light-overlay gate against each mode  [HIGH]
Gate (`1001493c..1001499c`): `+0x88 ≠ 0` ∧ prefs+6 (Effects, `lha r0,0x6(r28)`) ≠ 3 ∧ **stored**
`+0xb8 >> 16 ≠ 0xe` → `.WrapLightFace(face, port, …, flip, water_row)` with `water_row = +0x11c`
unless `+0x18c ≠ 0` (then 0). Physics §0.1's reading is confirmed. `.WrapLightFace @ 100156c8` wraps
`.DrawLightOverFace @ 1001cf38`, which walks the light list (200 entries at `_DAT_100a0128`) and,
when the level's ambient darkness hdr+0x2706 > 0, `.BlitAmbDarkenOverFace*`; rows below `water_row`
use the underwater variant (last argument 1). These blitters **remap the destination pixel in place**
over the face's opaque footprint — `lbz r17,0(r9) … lbzx r16,r10,r17 … stw r16,0(r9)`
(`.BlitAmbDarkenOverFaceClip`, `1001e3b4..1001e3f0`); the light blitters do the same in the decompile
(`*p = T[*p]`) [HIGH for darken, MED for the light blitters]. Consequences per mode:

| mode | light pass |
|---|---|
| 0, 1, 3/4 (flash), 5, 9, 0xa, 0xc | runs if `+0x88`; darkens/lights the already-tinted pixels (a tint is not "unlit") [HIGH] |
| 6 (submerged part) | runs, underwater variant below `water_row` [HIGH] |
| 8 | runs over the whole silhouette — **including pixels the mode-8 blit did not draw** (FG tile pixels inside the footprint would be darkened) — but the only mode-8 writer sets `+0x88 = 0` (`10033470`) [HIGH gate; MED consequence] |
| 0xb | runs over the whole footprint after the blend; this is why the fades clear `+0x88` first (platform crumble: `+0x88 = 0` from counter > 2, before any 0xb stage; floe and blink restore 1 with mode 0) [HIGH gate; MED consequence] |
| 0xe | never (gate) [HIGH] |
| any, `+0x89` lit | `+0x89` sprites set `+0x88 = 0` themselves (raft, PR §2.8); the mode-0xc table already carries the light [HIGH] |

Extra interaction found: the player clears `+0x88` whenever its `+0xb8 ≠ 0` (`100512dc..100512ec`:
`lwz r0,0xb8; cmpwi 0; beq; li r0,0; stb r0,0x88`), so a tinted player is drawn unlit.

## 4. Burn-away: `.HandleBurn @ 10043cd8` and `.BurnFaceRow @ 100437d8`

### 4.1 Call site and frame order  [HIGH]
Sole caller `.StandardSpriteCleanup` (`10036ed0 lha 0x1a2; cmpwi 0; beq` → `10036ee0 bl
0x10043cd8`). `.StandardSpriteHandles` earlier in the same handler resets `+0x1bc = 0` and
`+0x1b3 = 0` (`100368ac`, `100368c0`); `.HandleBurn` then re-sets both, so the draw that follows
sees this frame's burn row.

### 4.2 `.HandleBurn(s)` step by step  [HIGH]
Nothing happens if `+0xc0 == 0` (`10043d00..10043d08`). Then:
1. `+0x1b3 = 1` (burning; forces the erase of §1.1) (`10043d0c..10043d10`).
2. If `+0x1a2 == 1` and the hot rect is not zero-width (`+0x3a − +0x36 ≥ 0x10` or `+0x36 ≠ +0x3a`,
   i.e. simply left ≠ right) (`10043d14..10043d38`): burn sound `*PTR_DAT_100a01ec` (snd 462,
   EW §0.3) — `+0x8c == 0`: `.STPlay3DSoundRand(snd, 1, 0xab, +0xe)` (`10043d48..10043d58`); else
   `.STPlay3DSoundPitched(snd, 1, 0x41, +0xe, 110000 + rand(15000))` (`10043d64..10043d88`,
   `addis r4,r4,2; subi r7,r4,0x5250`).
3. If `0 < +0x1a2 < face+8` (opaque-bounds top, sprites §2.1): `+0x1a2 = face+8`
   (`10043d90..10043dac`).
4. Repeat `k = +0x8d + 1` times (`10043e68..10043e78`):
   a. `style = +0x8e ? 0xd : 1` (`10043db8..10043dcc`);
   b. `+0x1a2 += 1` (`10043dd0..10043dd8`); if the result is < 0 → **return** (delay); if 0 →
      `+0x1a2 = 1`, **return** (`10043ddc..10043df8`);
   c. `.BurnFaceRow(face, pos (+0xa), 2, +0x1a2, +0x17e, style)` (`10043dfc..10043e10`);
   d. if prefs+6 == 1 (Enhanced) ∧ `rand(100) > 50` ∧ `+0x8d == 0`: again with spacing 1
      (`10043e14..10043e58`);
   e. `+0x1bc = +0x1a2` (`10043e5c..10043e64`).
5. If `+0x1a2 > face+0xc` (opaque-bounds bottom) (`10043e7c..10043e8c`): type 0x780 → write 0x781
   then subtract 1 (no-op, `10043e90..10043eac`); `+0x50 ≠ 0` → call it (Kill proc, ptr-glue
   `1009f80c`), else `+0xe9 = 1` (`10043eb0..10043ed0`).

**What the player sees**: nothing is erased pixel by pixel — the face is **clipped from the top**
(`+0x1bc = row`, §1.1 step 2) and the row just consumed spawns particles. Token row R passed to
`.BurnFaceRow` is face row R−1 (0-based; see 4.3), and `+0x1bc = R` hides rows 0..R−1, so the
consumed row vanishes the frame it sparks.

**Progression** with T = max(face+8, 1), B = face+0xc, k = `+0x8d + 1`: frame f (f ≥ 1, counting
the first call with `+0x1a2 = 1`) ends with `+0x1a2 = T + f·k`; the sprite is killed at the end of
the first frame with `T + f·k > B`, i.e. after `⌊(B − T)/k⌋ + 1` frames (the kill frame itself is
not drawn when `+0xe9` is set; with a Kill proc it depends on the proc). With `+0x8d = 0` that is
opaque height + 1 frames (sprites §2.1: B = last opaque row + 1).
**Delay**: a negative start −d gives d frames with nothing burnt (and the face fully visible) before
the first burn frame (the Demon staggers its segments with `+0x1a2 = −30·(7 − (+0xa6 − 12)) − 1`,
`1008ae50..1008ae70`).

Writers (scan of `sth …,0x1a2(`): `= 1` in Walker (×2), swarm member, Gremlin, Frog, Salamander,
Dillo, Warrior, Demon, Chief, Wizard, `.ShieldBlock` (reflected enemy shot), and on a **player shot**
that hits the Wizard or Xichra (`.HitWizardSprite` `1008d4fc`, `.HitXichraSprite` `10090110`, both
also `+0x8c = 1` → the pitched sound; the shot's `+0x24` is first scaled by a TOC double) [HIGH addresses; MED
"player shot": gate `+0x4c == PTR_PTR_100a04e8` read in the decompile]. `+0x8c = 1` also in
`.SetupEnemyShotSprite` (`1005bacc`); `+0x8d = 1` only in `.SetupChiefSprite` (`1008b5f0`: the
Goblin Chief burns 2 rows/frame); `+0x8e = 1` only in `.SetupFrogSprite` when hdr+0x26cd ≠ 0
(`100820b4..100820c4`).

### 4.3 `.BurnFaceRow(face, pos, spacing, R, flip, style)`  [HIGH]
Walks the RLE tokens (sprites §2.2). Each op-1 (row) token: row counter += 1, y += 1 (starting at
pos.v), x = pos.h (or pos.h + face width when flipped) (`10043a5c..10043a7c`); op-3 skips advance x
(± by flip) (`10043a40..10043a54`). Only the literal (op-2) bytes of token row R are visited
(`cmplw r17,r0; beq` `10043874`); other rows are skipped without drawing. The pixel **values are
never read** — particles are fixed-kind, not pixel-coloured. For each opaque pixel, with a counter
c starting at 0: if `c ≤ 0` spawn and set `c = spacing − 1` (`r21 = spacing − 1`, `10043804`,
`100439f4`), else `c −= 1` (`100439fc`); so spacing 2 sparks every second opaque pixel, spacing 1
every pixel. A spawn (`100438c4..10043974`) is
`.NewParticle(style, 20 − rand(25), (y + rand(4), x), size, rand(50) − 25, −500 − rand(150), 2 − rand(12), 0)`
with `size` from `rand(100)`: ≥ 87 → 5, 26..86 → 2, 13..25 → 4, 1..12 → 1, 0 → unchanged (the
register then still holds the caller's r28, which `.HandleBurn` loaded with the style) (`100438e8..1004392c`).
Then 1 in 5 (`rand(5) == 1`, `1004397c..1004398c`) a second particle
`.NewParticle(4, 20 − rand(25), same pos, 2, ±(250 + rand(200)) (− when rand(100) > 50), −300 − rand(250), same 6th-arg value, 0)`
(`10043990..100439ec`). The y used is pos.v + R (+rand(4)), one row below face row R−1.

**Styles 1 vs 0xd** differ only in the first argument of the main particle: particle kind **1** vs
**0xd** (the 1-in-5 extra particle is kind 4 in both). What kinds 1, 4 and 0xd look like and what
arguments 2, 4, 7 mean is lane L3's (`.NewParticle @ 10031e68`).

## 5. `.ExplodeFaceIntoParticles @ 10043448` — not a draw mode  [HIGH]
No `+0xb8` value triggers it and the draw path never calls it. Its 13 call sites are explicit, in
handlers: `.ExplodeCrunchedTile` (`1004456c`), `.ShieldBlock` (`10055654`), `.HitPlayerSprite`
(`10055a48`, `10055a88`, `10055ab0`), `.KillPlayerShot` (`1005ae04`), `.KillEnemyShot`
(`1005cf4c`, `1005cf84`, `1005cfe4`), `.HandlePlatformSprite` (`10064b0c`), `.HandleBoxSprite`
(`1006de24`, `1006f59c`), `.KillBox` (`10070668`) (`bl 0x10043448` scan). One draw-relevant fact for
L3: its particles take the **raw face pixel** as colour (`kind = −(pixel + 0x100)`, `10043590..1004359c`,
`10043670..10043684`), so a tinted (mode 1/0xb/0xc) sprite explodes in its untinted colours.

## 6. INDEX item 15 and the per-file items it cites

| item | status here |
|---|---|
| INDEX 15 "`+0xb8` modes 1, 3/4, 7, 8, 9, 0xb, 0xc, 0x10..0x13 as pixels" | **closed** (§2): 7 and 0x10..0x13 are mode-1 table indices, not modes |
| INDEX 15 "`.HandleBurn` row arithmetic and styles 1 vs 0xd" | **closed** (§4) |
| INDEX 15 colours of tables 2/3/4/0xb/0xc/0xf/0x10..0x15/0x17/0x18 | not here → L1 (table = `*_DAT_100a0140 + sub·0x100`) |
| INDEX 15 `.BloodSpray` / `.NewParticle` arguments | not here → L3 (raw args of the burn calls given in §4.3) |
| enemies-ground NR 1 | → L1; NR 2 burn rate **closed** (§4.2), BloodSpray → L3 |
| enemies-flyers NR 1 | **closed** (0xb000a translucency §2.7, 0x10009/0x1000c remap §2.2); NR 6 **closed** |
| enemies-water-cave NR 3 | table colours → L1; styles 1 vs 0xd **closed** (particle kind); NR 4 → L3; §0.2 corrected below |
| bosses-2 NR 1 | **closed** (modes 1, 0xb, 0xc; "flash buffer" = mask buffer §1.3) |
| platforms-ropes-radial NR 1, §2.8 | **closed** (pixel rules; blend operand = sprite row §2.7; 0x10018 = mode 1, table 0x18 → L1) |
| triggers-background-2 NR 1 | **closed**; NR 5 → L3 |
| spells-detail NR 1 | `.NewParticle` args → L3 (no draw-mode content) |
| geysers §4 tints | 0x10017 / 0x1000c are mode-1 remaps through tables 0x17 / 0xc, copied to segments (`1006d200..1006d208`) [HIGH dispatch] |

## NOT RESOLVED
1. Colours of every table named here (T1, T3, T4, T6, light tables, blend tables a = 0..5) — lane L1.
   Not attempted here by brief.
2. Particle kinds 1, 4, 0xd and `.NewParticle` arguments 2, 4, 6, 7 — lane L3. Raw values given (§4.3).
3. `.BlitEncFaceRot` exact rounding and the `_DAT_100a1680` scale constant — read in the decompile
   only; the two-pixel-wide write and forward mapping are MED. Tried: decompile of `.BlitEncFaceRot`
   (§2.9); the raw loop was not read. ⚑ corrected (review 2a, 2026-10-04) #9
4. Mode 8's word-add identity needs the draw buffer to hold 0 under each 0xff mask byte; the FG tile
   drawers' handling of transparent pixels was not traced (only sprites §3.1 rule 4 and the reads here).
5. Data-driven mode-1 indices (`0x10000 + p` from Box p1 / Background and decoration p2 / Box `+0x150` /
   `.HandleEffectSprite`'s variable sub)
   can exceed the number of tables `.BuildTintTable` builds — the bound belongs with L1's table count.
   Tried: the writer scan of §2.1 only (values, not their data ranges). ⚑ corrected (review 2a, 2026-10-04) #9
6. Flipped twins (`TransFlipClip`, `FlipDiffuse`, `FlipWaterRipple`, `Flip*Special`) checked by slot loads
   and constants only, not loop-by-loop (MED). Tried: `tocrefs.py` slot loads and the constants named
   in §2.3/§2.4/§2.7. ⚑ corrected (review 2a, 2026-10-04) #9
7. Whether any shipped sprite combines rotation/scale with mode 5/6/8/0xb (would hit the undefined-table
   branch, §2.9): writers were scanned by value, not cross-checked against every `+0x1aa`/`+0x1ae` writer.
   Tried: the 241-store `+0xb8` scan (§2.1). ⚑ corrected (review 2a, 2026-10-04) #9

## Proposed additions to physics.md §0
| off | type | meaning |
|---|---|---|
| +0xb8 | i32 | replace the row's mode list with: `mode<<16 \| sub`; written modes **0, 1, 5, 8, 9, 0xa, 0xb, 0xc** only; 3/4 (hurt flash) and 6 (submerged rows) are draw-time substitutes; 2, 7, 0xd, 0xe, 0xf, 0x10..0x13 never written; per-pixel rules draw-effects §2 [HIGH] |
| +0xbc | i32 | last frame's `+0xb8`; `.WrapEraseSprites` forces an erase when its mode was 0xb or 5 (`10014d08..10014d1c`) [HIGH] |
| +0x89 | u8 | refine: overrides the hurt flash; writes `+0xb8 = 0` when unlit (`100147b8`) [HIGH] |
| +0x18c | u8 | refine: disables the water split and passes water row 0 to the light pass (`100147dc`, `10014964`) [HIGH] |
| +0x1b3 | u8 | burning: set every `.HandleBurn` call (`10043d10`), cleared by `.StandardSpriteHandles` (`100368c0`), read by `.WrapEraseSprites` [HIGH] |
| +0x8c / +0x8d / +0x8e | u8 | confirmed: pitched burn sound (vol 0x41, 110000+rand(15000)) / extra burn rows per frame (Chief = 1) / main burn particle kind 0xd instead of 1 [HIGH] |
| +0x1a2 | i16 | add: token-row counter; burn starts at max(face+8, 1); kill when > face+0xc (draw-effects §4.2) [HIGH] |

## Corrections to the existing bank
| # | file § | old | new | evidence |
|---|---|---|---|---|
| 1 | enemies-water-cave §0.3 | "each row erased by `.BurnFaceRow(…)`"; "style 1, or 0xd" (implied visual style) | `.BurnFaceRow` erases nothing; it spawns particles along the row's opaque pixels; the face is hidden by the top clip `+0x1bc = row`. Style = particle kind 1 / 0xd of the main particle | `10043e5c..10043e64`; `100438c4..10043974` |
| 2 | enemies-water-cave §0.3 | "the dissolve lasts (opaque height) frames" | `⌊(face+0xc − max(face+8,1))/k⌋ + 1` frames, k = `+0x8d+1` (opaque height + 1 at k = 1) | `10043e7c..10043e8c` |
| 3 | enemies-water-cave §0.2 | "Other modes met: … 0xe" | no code writes mode 0xe to `+0xb8`; 0xe is only tested in `.WrapDrawSprites` | `b8.py` store scan |
| 4 | physics.md §0.1 `+0xb8` row | "0x10..0x13 blends"; "Pixel semantics NOT RESOLVED" | 0x10..0x15 are mode-1 table indices (Walker tiers); semantics draw-effects §2 | `10067638..10067758` |
| 5 | platforms-ropes-radial §2.8 | "0xa clipped draw (arg = clip)"; "0xe mask-only"; "other modes (1..4, 7, 9, 0xc, 0x10..0x13) → Special" | 0xa = vertical squash by arg/256 (raw copy); 0xe = solid silhouette in palette index arg; Special implements only 1, 3, 4, 6/9, 0xc (2, 7, 0xf, 0x10..0x13 read an undefined table and are never written) | `10027614..10027630`; jump table 0x100a3d64 |
| 6 | platforms-ropes-radial §2.8 | blend operand "not traced" | row = sprite pixel, column = background (or the parallax pixel where the mask is 0xff) | `10027fe0..10028054` |
| 7 | enemies-ground §2 (burn) | "erases one face row per frame … [MED]" | top-clip + particles; `+0x8d + 1` rows/frame; see #1 | as #1 |
| 8 | bosses.md §1 death sequence | "when the burnt row passes the face height" | when `+0x1a2 >` face+0xc (opaque-bounds bottom), not the frame height | `10043e84` |
| 9 | bosses-2 NR 1 | "the flash buffer `*_DAT_100a0008`" | the sprite/parallax mask buffer (§1.3); every non-rotated sprite writes 0 under its silhouette | `1002d18c..1002d2c0` |
| 10 | enemies-water-cave §0.2 table | "Mode 1 = per-pixel remap … (`.BlitEncFaceSpecialClipX`, case 1)" | correct; add: the hurt flash replaces it for the flash's frames, and a fully submerged sprite (`+0x11c == 1`) is drawn with the water table instead of its tint | `100146f0..10014728`, `100148f0..1001491c` |
| 11 | geysers §4 | tint "[MED "tint"]" | mode-1 remap through table 0x17 / 0xc [HIGH dispatch] | §2.2 |

## ⚑ Corrections (R4, 2026-10-09; Ben: follow the binary; both Opus review legs CONFIRMED at the addresses)
1. **`.WrapDrawSprites` never culls.** The SectRect cull offsets both the face rect and the 0x260×0x180 window by the
   same scroll (`10014544..1001457c`), so every sprite with a face passes. The right clip is h + 0x280 (`10015260`).
2. **`.WrapEraseSprites @10014a58` offsets the previous face bounds by the scroll, not the sprite position**
   (`10014c08..10014c14`), so almost every sprite is erased every frame. An empty SectRect (the rect misses the ring)
   yields (0,0,0,0) and re-stamps cell (0,0) (decompile l. 10589–10603). An out-of-range tile in the re-stamp reports an
   error and abandons the rest of the rect.
3. **Flip light blitters** read the light column at offCol + width − c (not width − 1 − c); the flipped second-light
   blitter leaves p = 0 pixels unchanged where the unflipped one reads them as 0xf5. The light-slot quick reject in
   `.DrawLightOverFace` adds the light's own coordinate to the bound (decompile l. 15172–15184).
4. **Mode 0xb (`+0x89` D = −1 case) is not reached on level 1** — no level-1 Setup sets `+0x89`; refused by name in Phase 1.
   Level-1 Setup modes: 0 ×148, 0x10006 ×8, 0x10007 ×1, 0x10010 ×3, 0x10016 ×2.
