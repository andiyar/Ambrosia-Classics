# Deimos Rising 1.0.6 — G_Text: glyph metrics, the format flag bytes, and the element lists (wave 3)

Scope: G_Text.cc, `0x1000d010–0x1000f794`, every function by raw listing: `FUN_1000d010 1000d0f0
1000d130 1000d230 1000d260 1000d380 1000d6d0 1000d7f0 1000da50 1000db90 1000df00 1000e270 1000e670
1000e8d0 1000ebd0 1000ec70 1000ed10 1000ed60 1000edf0 1000ef90 1000f720`. Also read as callers:
`FUN_10025840 10025890 100232d0` (fade wrappers), the fade/draw call sites in `FUN_10025b90
10021950 10021bd0 100258e0`, and `FUN_10019570`/`FUN_10019ca0` (existing listings, entry tests
only). This file **extends hud-scorebar.md §9** and does not repeat it. Its alignment arithmetic is
HIGH there and is used here as given. OUT: the blitters (blit-pixel-rules.md, w3s1), G_Interface
layout (front-end.md), the `tefo` file grammar (data-tags.md §5). The brief's range end
`0x1000fbc0` runs into G_Background: `FUN_1000f7a0` (listed but not re-read), `1000f990 1000f9c0
1000fa10 1000fa90 1000fbc0 1000fec0 1000fed0 1000fee0 1000ffc0 1000ffe0 1000fff0` are **not
re-read**. They belong to level-scroll-objects.md.
Evidence: listing `$W/disasm-w3s3.txt` (project copy `$W/work-w3s3`, `DisasmFuncs.java`); TOC
r2 = `0x100e6330`; constants by Python `struct.unpack('>…')` over `$W/mem/100de330.bin` (data,
base `0x100de330`) and `$W/mem/10000000.bin` (code-image records `0x100d…`); glyph sizes from
`$W/w3s3-tesm.py` over `$W/data/Interface/im08/Text - Small IA[TESM].gif`. The decompile census
script is `$W/w3s3-census.py`. `$W` = `/Users/andiyar/Developer/Ambrosia-Classics/ghidra/deimos-proj`.

## 0. Globals and TOC slots (resolved; image vs runtime checked)

| TOC disp | slot | points to | meaning | runtime source |
|---|---|---|---|---|
| `-0x730c` | `0x100df024` | `0x100ff878` | glyph-size cache, 128 × {w, h} (8 B) | filled by `FUN_1000ec70` (§1.2) |
| `-0x72ec` | `0x100df044` | `0x100ff870` | digit max {w, h} (8 B) | zeroed by `FUN_1000d010` from `0x100d63c0` = {0,0} |
| `-0x72f0` | `0x100df040` | `0x100d63c0` | size returned for chars ≥ 0x80 | code image = {0, 0} |
| `-0x72f8` | `0x100df038` | `0x100d63f0` | floats {1.0, 0.0, 0.5} | code image |
| `-0x72f4` | `0x100df03c` | `0x100fb340` | the 54 formats × 0x148 | `FUN_1000ed60` |
| `-0x1098` (direct) | — | `0x100e5298` | G_Text draw-command template (0x4c B) | image + `FUN_1000f720` (§0.1) |
| `-0x104c` (direct) | — | `0x100e52e4` | format template (0x148 B) | image + `FUN_1000f720` |
| `-0x6210` | — | `0x100e0120` | font sprite ID (`tesp` item 0 → `tesm`) | `FUN_1000d010` |
| `-0x620c` | — | `0x100e0124` | monospace glyph char | `FUN_1000d010` = 0x20, then digit cache |
| `-0x620b` | — | `0x100e0125` | module live | 1 in `FUN_1000d010`, 0 in `FUN_1000d0f0` |
| `-0x6214` | — | `0x100e011c` | formats loaded | 1 in `FUN_1000ed60`, 0 in `FUN_1000d0f0` |
[HIGH — slot words read from the data image; disp = slot − `0x100e6330`]

### 0.1 The static initialiser `FUN_1000f720 @ 1000f720` (callee of `FUN_10000000`) [HIGH]
This applies the C1 rule (runs before `main`). Single-word copies, no 8-byte loop:
```
1000f720 lwz r3,-0x7314(r2)  ; slot 0x100df01c -> 0x100d63b8 = {0, 0}
1000f72c subi r8,r2,0x1098   ; r8 = 0x100e5298 (draw template)
1000f734 stw r7,0x4(r8) ; 1000f73c stw r6,0x8(r8)                 ; cmd x, y <- 0, 0
1000f724 lwz r4,-0x7318(r2)  ; slot 0x100df018 -> 0x100d63d0 = {0, 0, 480, 416}
1000f744 stw r0,0x20(r8) ; 1000f74c stw r3,0x24(r8) ; 1000f754 0x28 ; 1000f760 0x2c   ; clip
1000f750 lwz r5,-0x731c(r2)  ; slot 0x100df014 -> 0x100d63e0 = {0, 0, 0, 0}
1000f768 0x38 ; 1000f770 0x3c ; 1000f780 0x40 ; 1000f78c 0x44     ; COST rect <- 0
1000f76c subi r3,r2,0x104c ; 1000f778 stw r7,0x100(r3) ; 1000f790 stw r6,0x104(r3)  ; format Loc <- 0, 0
```
- Draw template `0x100e5298`: the image has clip {0,0,0,0}. At runtime the clip is **{top 0, left 0,
  bottom 480, right 416} = the game area**, the same pattern as `FUN_10014120` on `0x100e63e4`.
  The other fields keep their image values: x 0, y 0, sprite `none`, frame 0, flags 0, scale 1.0,
  alpha 0, layer +0x30 = 7, +0x31 = 0, colour +0x34 = 0x7fff.
- Format template `0x100e52e4`: the initialiser writes only Loc = (0, 0), which equals the image.
  So every other default is the image value (§2.1).

## 1. Glyph metrics (closes INDEX #6, hud NR 5/6)

### 1.1 Character → frame `FUN_1000e8d0 @ 1000e8d0` [HIGH]
```
1000e8d0 extsb r3,r3 ; 1000e8d4 subi r0,r3,0x21 ; 1000e8d8 cmplwi r0,0x5d ; 1000e8dc bgt 0x1000ebc4
1000e8e0 subi r3,r2,0xf04    ; jump table 0x100e542c (= 0x100e6330 − 0xf04), 0x5e entries (chars 0x21..0x7e)
1000ebc4 li r3,0x5a ; blr    ; default frame 90
```
I resolved the jump table from the image: every target is `li r3,N; blr`. The result equals the
data-tags.md §5 table. Space (0x20), control bytes, DEL and **every byte ≥ 0x80** fall through to
frame **90**. A byte ≥ 0x80 is sign-extended, so `c − 0x21` is negative and fails the unsigned
compare. ⚑ corrected (review wave 3, 2026-10-06) #I1: the table base is `0x100e542c` (r2 `0x100e6330` − `0xf04`), was
`0x100e5430` (the frame values above were resolved from the right base; review wave 3 hazard).

### 1.2 The cache filler `FUN_1000ec70 @ 1000ec70` (caller: module init `FUN_1000d010`, once) [HIGH]
```
1000ec78 lwz r31,-0x72f8(r2)   ; &1.0
1000ec80 lwz r30,-0x730c(r2)   ; cache 0x100ff878
1000eca0 extsb r3,r28 ; bl 0x1000e8d0                       ; frame(c)
1000ecac lwz r3,-0x6210(r2) ; lfs f1,0x0(r31) ; addi r5,r1,0x38 ; bl 0x10019ca0   ; GetDimensions(font, frame, 1.0)
1000ecd4 stw r3,0x0(r4) ; 1000ecdc stw r0,0x4(r4)            ; cache[c] = {w, h}
1000ecd8 cmpwi r28,0x80 ; 1000ece4 blt                       ; c = 0..127
```
This is the only writer of the cache. `FUN_1000d010` calls it after it loads the formats
(`1000d0c8 bl 0x1000ed60; 1000d0cc bl 0x1000ec70`). The fill is not repeated later. `callers.txt`
lists only `FUN_1000d010` for `ec70`.

### 1.3 Size lookup `FUN_1000ed10(c, _, out)` and measure `FUN_1000ebd0(font, c, scale f1, out)` [HIGH]
```
1000ed10 rlwinm r0,r3,0,24,31 ; cmplwi r0,0x80 ; blt 0x1000ed38     ; c < 0x80 → cache[c]
1000ed24 lwz r3,0(r4) ; lwz r0,4(r4) ; stw … (r5)                   ; else {0,0} from 0x100d63c0
1000ec04 bl 0x1000e8d0 ; 1000ec10 lfs f0,0x0(r4) (=1.0) ; 1000ec14 fcmpu cr0,f0,f31 ; 1000ec18 bne 0x1000ec30
1000ec28 bl 0x1000ed10          ; scale == 1.0 → cache
1000ec40 bl 0x10019ca0          ; scale != 1.0 → GetDimensions(font, frame(c), scale) = trunc(w·s), trunc(h·s)
1000ec48 or r3,r31,r31          ; returns the frame index
```
`FUN_1000ebd0` only measures. It never draws. ⚑ corrected: the role row said "draw one character".
The "float branch" (INDEX #6) is just scale = 1.0 vs scale ≠ 1.0.

### 1.4 The `tesm` frame sizes that matter [MED — data scan, see the caveat]
The game builds its frame table at load from the plates (sprite-sound-containers.md §2.2,
`FUN_1001f340` rect → encoder `w, h` at block +4/+8). `FUN_10019ca0` returns exactly those words
(`10019e44 lwz r0,0x4(r30); stw r0,0(r31); 10019e4c lwz r0,0x8(r30)`). The data ships no encoded
blocks, only the GIF plates. So the closest check is the scan run on the alpha plate's **8-bit
palette indices**, which is what the game compares, not RGB: `python3 $W/w3s3-tesm.py`. The
plate is 852 × 18 and has 91 frames, indices and RGB agree:

| frame | 52 '1' | 53 '2' | 54 '3' | 55 '4' | 56 '5' | 57 '6' | 58 '7' | 59 '8' | 60 '9' | 61 '0' | 90 (default) | 0 'A' |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| w × h | 5×13 | 6×13 | 7×13 | 7×13 | 7×13 | 7×13 | **6**×13 | 7×13 | 7×13 | 7×13 | **4×13** | 7×13 |

⚑ conflict hud-scorebar.md §9 step 1 lists the widths as `5,6,7,7,7,6,7,7,7,7`. The 6 px glyph is
frame **58 ('7')**, not frame 57 ('6'). The digit-cache outcome does not change (§1.5). Frame 90
is a 4 × 13 cell whose colour plate is entirely the key green (0,189,0) (checked with PIL: one
colour). Its alpha plate is all white. **Frame 90 is an invisible 4-px glyph.** Caveat (MED): the
game compares indices after QuickTime draws into an 8-bit GWorld. A palette remap could only merge
colours. The trim tests "≠ blue fill", and greys and white cannot map to pure blue, so the widths
are robust.

### 1.5 Space advance and the monospaced cell — INDEX #6 closed, hud NR 5 confirmed [HIGH code / MED widths]
- **Space at scale 1.0** = cache[0x20] = size of frame 90 = **4 px** (+ the format's spacing).
  At scale s ≠ 1 it is `trunc(4·s)` (`FUN_10019ca0`). The draw skips it:
  `1000e6e0 cmpwi r0,0x20; 1000e6f0 beq 0x1000e8b4` in `FUN_1000e670`. Any other unmapped
  byte < 0x80 (Tab etc.) also advances 4 px. It *is* drawn, but as frame 90, which is invisible.
  A byte ≥ 0x80 advances **0** at scale 1.0 ({0,0} from `0x100d63c0`) and `trunc(4·s)` at other
  scales. [HIGH code; MED the 4 px]
- **Monospaced cell** (`FUN_1000d380`/`FUN_1000d260` first call, listing `1000d3c4…1000d474`):
  the cache check measures when cached w == 0 **or** h == 0 (`1000d3dc beq; 1000d3e4 bne`). Max h
  starts at h('1') (`1000d3fc lwz r0,0x3c(r1); stw r0,0x44(r1)`). Max w starts at 0, so frame 52
  always "wins" first. Label = `'0' + i` at each strict increase (`1000d434 ble`). With widths
  5, 6, 7, … → '0' (i 0), '1' (i 1), '2' (i 2), and nothing wider follows ⇒ `DAT_100e0124 = '2'`,
  whose glyph is frame 53, **6 px**. The cell is **6 px at scale 1.0** (`trunc(6·s)` otherwise:
  the width pass measures the mono char at the format scale, `1000e33c lfs f1,0x118(r22)`).
  Before the first text draw `DAT_100e0124` = 0x20 (`1000d04c li r0,0x20; 1000d064 stb
  r0,-0x620c(r2)`), but no layout can run before the cache is set. [HIGH code; MED widths]

## 2. The format record and its three flag bytes (closes hud NR 3, messages NR 1)

### 2.1 Defaults that no `tefo` key sets [HIGH]
`FUN_1000ef90` starts from a copy of the format template (`1000f01c subi r3,r2,0x104c`, 0x29 × 8
bytes to `r1+0x68`; the first `stw` lands at `r1+0x68`). None of its stores hits the local
`+0x10c/+0x10d/+0x110/+0x118/+0x124/+0x128` (`r1+0x174/175/178/180/18c/190`). I checked every
`st*`/`addi r5,r1,…` in `1000ef90…1000f71c`; the only ones in range are 0x168/16c/170/176/177/17c/
184/188/194/198/19c/1a0/1a8/1ac. The template bytes (`0x100e52e4`, unchanged at runtime, §0.1) are:
| off | default | meaning (this file) |
|---|---|---|
| +0x10c | **8** | render layer → draw cmd +0x30 |
| +0x10d | **0** | clip select: 0 = buffer bounds, 1 = keep template clip = game area |
| +0x110 | **1** | draw-now → draw cmd +0x31 |
| +0x118 | 1.0 | glyph scale |
| +0x11c | 1 | spacing if the key is absent |
| +0x124 / +0x128 | `none` / 0 | **element sprite ID / frame** (list elements, §3); `none` = text element |
| +0x130/+0x134/+0x138 | 3 / 3 / 16 | strip H/V offset, strip blend |
`FUN_1000edf0` zero-fills its local (`1000ee1c bl 0x1000cd90`, 0x148). It loads `tefo`
(`1000ee2c addi r3,r3,0x666f` → `'tefo'`), parses, and copies 0x148 bytes into the table slot.
[HIGH for the stores; MED for the callee roles memset/lock/unlock]

### 2.2 Where each flag byte goes (the glyph record built by `FUN_1000e270`) [HIGH]
`FUN_1000e270` packs a per-glyph record at `r1+0x48` (`1000e524…1000e574`):
`+0 = fmt+0x10c`, `+4 font`, `+8 char`, `+0xc x (cell)`, `+0x10 y = fmt+0x104`,
`+0x14 blend = fmt+0x114`, `+0x18 scale`, `+0x1c shadows`, `+0x1d draw?`, `+0x1e = fmt+0x110`,
`+0x1f colourise`, `+0x20 colour`, `+0x22 = fmt+0x10d`. `FUN_1000e670` copies the draw template
`0x100e5298` to `r1+0x38` (9 × 8 + 2 × 2 bytes). Then:
```
1000e72c lbz r0,0x22(r26) ; cmplwi ; bne 0x1000e74c          ; +0x10d != 0 → keep template clip
1000e738 lwz r3,-0x7904(r2) ; addi r4,r1,0x58 ; lwz r3,0x68(r3) ; bl 0x1000a530   ; else clip = bounds of D+0x68
1000e78c lbz r0,0x1e(r26) ; stb r0,0x69(r1)                  ; cmd+0x31 = fmt+0x110
1000e794 lbz r0,0x0(r26)  ; stb r0,0x68(r1)                  ; cmd+0x30 = fmt+0x10c
```
and in `FUN_10019570`: `100195ac lbz r0,0x31(r31); cmplwi; bne 0x100195c0; 100195b8 bl
0x1001a450` → **+0x31 == 0 queues** the command on render layer `cmd+0x30`. It is drawn later at
the end-frame layer flush (sprite-geometry-draw.md §6). **+0x31 = 1 draws at once** into the
current buffer. So:
- **+0x10c = render layer** (0..15). It only matters when +0x110 = 0. Default 8. Overlays write
  0x0f = the `hud ` layer 15, the last one flushed.
- **+0x10d = clip select.** 0 → clip to the bounds of the back buffer `D+0x68`. 1 → keep the
  template clip, which is the game area {0,0,480,416} only because of `FUN_1000f720`. That rect
  also makes `FUN_10019570` choose the unclipped scaled blitter (sprite-geometry-draw.md §3.3).
- **+0x110 = draw-now.** 1 (default, HUD, front end) draws immediately. 0 (messages, console,
  notices, frame rate, tallies) queues on layer +0x10c.
Census of the writers (decompile, `$W/w3s3-census.py`, local-offset match on the `FUN_1000d130`
buffer) [MED]: `FUN_100051a0`, `10007d60`, `100184b0` (notice), `100298c0` (coin tally),
`1002dea0` (messages) and `10030bc0` (frame rate) write layer 0x0f, own clip 1, now 0. `1002d410`
(console) writes layer 0x0f and now 0. The score bar `10031d70`/`10032050` writes now = 1 only.
Front-end callers (`100222f0`, `10025420`, `10025b90`, `10023040`) write none, so they get layer
8, buffer clip and immediate draw. No caller writes +0x10f (shadows), and every shipped `tefo` has
`#DrawShadows_BOOL <FALSE>` (`grep`). So **the shadow pass is dead in 1.0.6**.

### 2.3 The colour strip is always queued [HIGH]
`FUN_1000d380` builds the `COST` command at `r1+0x48` from the same template:
`1000d528 stw r5,0x54(r1)` ('COST'), `1000d52c` alpha = strip blend (+0x138), **`1000d530 stb
r3(=0),0x79(r1)` → cmd+0x31 = 0**, `1000d534 sth` colour → cmd+0x48, `1000d55c` layer = +0x10c.
So the strip always goes into the layer list, even when the text is drawn at once.
Grow/min arithmetic (`1000d56c…1000d68c`): measure → left −= H, right += H, top −= V,
bottom += V. If `right − left < minW`: LEFT → right = left + minW. CENT/CEBU/CEGA → left =
**X** − minW/2 (C division), right = left + minW, **using Loc X even for CEBU/CEGA, whose text
ignores X**. RIGH → left = right − minW. Anything else logs. If `bottom − top < minH`: bottom =
top + minH. Order in `FUN_1000d380`: shadow pass (if +0x10f) → strip → text with shadows cleared
(`1000d4c4 stb r3,0x1a3(r1)` = local +0x10f ← 0). For queued overlays (layer 15) the strip
therefore lies under its text. Shipped strips that use immediate text: none found. `brpr` (index
52) has a strip, but no caller passes index 50–52 as a literal (census) [LOW].

### 2.4 Where `Loc_X/Y` land — messages NR 2 / INDEX #43 closed [HIGH] ⚑ corrected (review wave 3, 2026-10-06) #M3: was "[HIGH for \"no offset\"; MED for the target buffer]" — the target is settled: normal draws go to port index `0x100e0179` = 0 → `FUN_1000ad90` → `D+0x68` (`10019728 lbz r4,-0x61b7(r2); bl 0x1000ad90`, blit-pixel-rules.md §1), the 640×480×16 back buffer (`1000b320`, display-window-present.md §1, §8.2)
No code between the format and the draw command adds an offset. Cell x = start x (`Loc_X` for
LEFT, hud §9 for the others) + spacing. The command gets `cell + w/2`, `Loc_Y + h/2`
(`1000e758…1000e770`). `FUN_10019570` then subtracts w/2, h/2 (sprite-geometry-draw.md §3.3). So
**Loc is the glyph top-left in the coordinates of the buffer being drawn**. In game that is the
back buffer, whose game area is x 0..415 (the terrain window goes to buffer (0,0,480,416),
`FUN_10010120`; screen x = buffer x + 32, hud-scorebar.md §1). Therefore **tefo Loc is
game-area-relative in game**: message x 30 is 30 px inside the playfield, screen x 62. Overlays
with +0x10d = 1 are clipped to the game area (x < 416). CEGA (centre in 416) agrees. In the front
end the same numbers are 640-wide screen coordinates (menu x = F52/2 = 320, front-end.md §2.2).

## 3. Element lists (G_Interface's text/sprite lists) [HIGH unless noted]
An **element** is a 0x148-byte format record (`FUN_1004d320(0x148)`, appended with
`FUN_100009e0`). `+0x124 == 'none'` → text element (string at +0, layout by format). Otherwise →
sprite element: ID +0x124, frame +0x128, centre (+0x100, +0x104), scale +0x118, alpha +0x114. The
layout `FUN_10025420` fills +0x124/+0x128 from the button record (+0x114/+0x118 sprite, +0x11c
frame; decompile lines 384–421). Iteration uses `FUN_10000ce0` (count) and `FUN_10000e10` (cursor
{0,0} from `0x100d63c0`, element at cursor+4). List order is append order.

Sprite-element rect (identical in `d7f0`, `da50`, `db90`, `df00`): `wh = FUN_10019ca0(id, frame,
scale)`; `left = X − w/2`, `top = Y − h/2` (C division, `rlwinm …,1,31,31; add; srawi 1`),
`right = left + w`, `bottom = top + h` (`1000db10…1000db64`). Text-element rect = `FUN_1000d260`:
{Y, start x, Y + max h, end + 1} (hud §9).

| function | role | evidence |
|---|---|---|
| `FUN_1000d7f0 @ 1000d7f0 (list, restore, present)` | draw every element once. Text: measure; if `restore`, copy the rect from the save buffer D+0x6c to D+0x68 (`FUN_10009fd0`); draw (`FUN_1000d380`). Sprite: **always** restores its rect (`1000d924 bl 0x10009fd0`, no test of `restore`), builds the command (x, y = centre, flags = template \| 1, alpha +0x114, scale +0x118, layer/now/clip as §2.2) and calls `FUN_10019570`. If `present`: rect + screen origin (`FUN_1000c3b0`: top += D+0x0c, left += D+0x10) → `FUN_1000bbd0` copy to the window | listing `1000d860…1000da24`. Callers: `(0,0)` from 10021950/10021bd0/100258e0; `(1,1)` at `10022244` (name-entry redraw) |
| `FUN_1000da50 @ 1000da50 (list, index, rectOut)` | bounds of element `index` (0-based). Zero rect if `count < 1` or `index ≥ count` (`1000da8c cmpwi r30,1; blt`; `1000da94 cmpw r27,r30; bge`). Mac Rect order {top, left, bottom, right} | listing; caller `FUN_10025420` stores it at button +0x104 = hit rect |
| `FUN_1000db90 @ 1000db90 (list, rate)` | **fade in**, see §3.1 | listing |
| `FUN_1000df00 @ 1000df00 (list, rate)` | **fade out**, see §3.1 | listing |
| `FUN_1000d6d0 @ 1000d6d0 (fmt)` | fade **one** text element in: local copy; per pass wait until `TickCount ≥ prev + 1` (`1000d750…1000d76c`); restore; `if blend ≠ 0: blend −= 1` (`1000d78c…1000d79c`); draw; present; loop while blend ≠ 0. A loading line starts at blend 0x20 (`FUN_10023040`), so it shows 31 … 0 = 32 draws, one per tick | listing `1000d6d0…1000d7e8` |

### 3.1 The list fades — front-end.md §5.2 raised from MED to HIGH
```
fade in  (db90): level = 32 (1000dbd0 li r25,0x20); t = 0
  loop: wait while t > TickCount (1000dbe4 cmplw r26,r3; bgt)      ; unsigned
        t = rate + TickCount (1000dbf8 add r26,r23,r3)
        if level != 0: level -= 1 (1000dbf4 cmplwi; 1000dc00 subi)
        for each element (list order): copy; alpha = max(level, own +0x114)  (1000dd20 cmplw r25,r0; blt)
             restore rect from D+0x6c; draw; present rect
  until level == 0 after a pass (1000dee0 cmplwi r25,0; bne)        ⇒ levels 31,30,…,0 = 32 passes
fade out (df00): level = 0 (1000df40 li r25,0); if level < 32: level += 1 (1000df64 cmplwi 0x20; bge; addi)
  same pass body (1000e090 cmplw r25,r0)                            ⇒ levels 1,2,…,32 = 32 passes
  until level == 32 (1000e250 cmplwi r25,0x20; bne)
```
- **Rate** = `fctiwz(PermFloat(160))` = 1 (`Interface_FadeRate <1.0>`) at every call site:
  `10025858/100258a8/100232e8/10025d20/10025f58/10026048 li r3,0xa0; bl 0x10020250; fctiwz`.
  Pass k starts no earlier than 1 tick after pass k−1 started. The first pass does not wait (t =
  0). Total ≈ 32 ticks plus draw time.
- Alpha is absolute, not cumulative. Every pass first restores the background from D+0x6c, so
  pass k shows the element at alpha 32 − k (fade in) or k (fade out) over clean background. The
  last fade-out pass (alpha 32) only restores: `FUN_10019570` skips alpha 0x20 (`100195a4 cmplwi
  r0,0x20; beq exit`), so the element is erased.
- **Text** alpha = `max(level, own blend)` (unsigned). Example: `inwe`/`inco` (own 12) hold at 12
  during the last 12 fade-in passes and the first 11 fade-out passes. **Sprite** alpha = `level`
  only (`1000de58 stw r25,0x84(r1)`), so the own +0x114 is ignored.
- Quirk: the fade passes **do not copy the sprite scale** into the command. No store to cmd+0x18
  (`r1+0x80`) appears in `1000ddf0…1000de84` / `1000e160…1000e1f4`, whereas `FUN_1000d7f0` has
  `1000d9a8 lfs f0,0x118(r26); stfs f0,0x80(r1)`. The template scale 1.0 is used, but the
  restored rect is the scaled one. This is invisible for the shipped menus, whose elements keep
  the template scale 1.0 [LOW that no element is scaled — layout writes no +0x118 in the decompile].
- Text flags in a fade: blend > 0 and not colourised → flag 1 (fade blend). Colourised → flag 4
  (tint) with the alpha in +0x1c (`1000e7a8…1000e7d4`). Whether the tint blitter honours that
  alpha is blit-pixel-rules.md's question (NR 3).

## 4. The rest of the range [HIGH unless noted]
| function | role | evidence |
|---|---|---|
| `FUN_1000d010` | G_Text init: register "Text" (`FUN_1003a870`), digit cache ← {0,0}, module live = 1, mono char = ' ', log "Loading Text Sprites", font = `tesp` item 0 (`FUN_10003520('tesp',0)`), `G_Res_Load(sprite, font, 0)` unless `none` (assert on failure), load formats, fill glyph cache | `1000d03c…1000d0cc`; strings `0x100e55a4+5/+0xa/+0x1f` |
| `FUN_1000d0f0` | G_Text shutdown: unregister, module live = 0, formats loaded = 0 | `1000d108…1000d118`; caller `FUN_10000630` |
| `FUN_1000d130` | copy format i: 0x20 × 8 = text[256], then the fields one by one (+0x100…+0x144) | `1000d130…1000d228` (no hidden +8: both pointers pre-decremented by 4) |
| `FUN_1000d230` | is the font sprite loaded (`FUN_10019530(font)`) | `1000d23c…1000d240`; caller `FUN_10023040` |
| `FUN_1000d260` | measure formatted text (digit cache + `FUN_1000e270(…, 0)`) | `1000d260…1000d368` |
| `FUN_1000d380` | draw formatted text (cache, shadow pass, strip, text) | §1.5, §2.3 |
| `FUN_1000e270` | layout + per-glyph draw (hud §9). Width pass max-h `r29` is computed and never used. W counts the spacing before **every** char, so centred text sits `spacing/2` right of Loc | `1000e328…1000e398`, `1000e598…1000e650` |
| `FUN_1000e670` | measure one glyph; if drawing and not space: build the command. Normal: flags 4 + colour if colourised, else 1 if blend > 0. Shadow: `x += fctiwz(F19 −10)`, `y += fctiwz(F20 10)`, alpha = `max(blend, (uint)F21 17)`, flags \| 2, never colourised | `1000e6c4…1000e8ac` |
| `FUN_1000ed60` | load the 54 formats (`'gate'` item i → `FUN_1000edf0` → `0x100fb340 + 0x148·i`), set formats-loaded | `1000edb8 cmpwi r26,0x36`, `1000edc8 stb r0,-0x6214(r2)` |
| `FUN_1000ef90` | parse a tefo (hud §9 HIGH); unknown alignment logs and falls back to LEFT X | template copy `1000f01c` |

## Worked example

**A. HUD score, player 1, score 1234, format 43 `sbs1`** (Loc 494,83, `CENT`, monospaced,
spacing 4, colourise 94dee6, blend 0; HUD sets +0x110 = 1 and leaves +0x10c = 8, +0x10d = 0).
`"%0.7i"` → `"0001234"` (7 chars, `FUN_10057760` strlen).
1. Digit cache (first ever text draw): frames 52..61 widths 5,6,7,7,7,7,6,7,7,7 → label '2',
   max {7, 13}; `DAT_100e0124 = '2'` (`1000d474`).
2. Width pass (`1000e328…1000e380`): every char measures '2' at scale 1.0 → cache[0x32] =
   {6, 13} (`FUN_1000ed10`). W = 0.0 + 7 × (4 + 6) = 70.0.
3. Start: CENT `fctiwz(494 − 0.5·70) = 459` (`1000e410 fnmsubs`, `1000e414 fctiwz`).
4. Draw pass (`1000e598…1000e60c`), x₀ = 459:

| char | cell = x + 4 | mono advance | x after | glyph frame, w | cmd x = cell + w/2 | drawn columns |
|---|---|---|---|---|---|---|
| 0 | 463 | 6 | 469 | 61, 7 | 466 | 463..469 |
| 0 | 473 | 6 | 479 | 61, 7 | 476 | 473..479 |
| 0 | 483 | 6 | 489 | 61, 7 | 486 | 483..489 |
| 1 | 493 | 6 | 499 | 52, 5 | 495 | 493..497 |
| 2 | 503 | 6 | 509 | 53, 6 | 506 | 503..508 |
| 3 | 513 | 6 | 519 | 54, 7 | 516 | 513..519 |
| 4 | 523 | 6 | 529 | 55, 7 | 526 | 523..529 |
   cmd y = 83 + 13/2 = 89 → rows 83..95 (`FUN_10019570`: left = x − w/2, top = y − h/2).
   7-px glyphs overlap 1 px into the 4-px gap. Flags 4, colour from +0x122; drawn immediately; clip =
   buffer bounds. Returned rect {83, 459, 96, 530}. On screen (+32) the glyphs start at x 495.
   [HIGH arithmetic; MED glyph widths §1.4]

**B. One menu element fading in** (`FUN_10025840` → `FUN_1000db90(list, 1)`): the 1 PLAYER
button, a sprite element at (320, 198) (front-end.md §2.2), own blend 0, scale 1.0.
| pass | earliest start (ticks) | level | cmd alpha | opacity (32 − a)/32 |
|---|---|---|---|---|
| 1 | T₀ | 31 | 31 | 1/32 |
| 2 | T₀ + 1 | 30 | 30 | 2/32 |
| 3 | T₀ + 2 | 29 | 29 | 3/32 |
| 4 | T₀ + 3 | 28 | 28 | 4/32 |
| 5 | T₀ + 4 | 27 | 27 | 5/32 |
Each pass restores the button's rect from D+0x6c, draws at alpha a with flag 1, and presents the
rect. The web-URL text element (`inwe`, own blend 12) gets the same alphas 31…27 in these passes.
Passes 21–32 hold it at 12. For a plain alpha-blended pixel (sprite-sound-containers.md §2.3a,
`(dst·a + src·(32 − a)) >> 5`) with a sprite channel of 31 over a background of 0: pass 1 →
`31·1 >> 5` = 0, pass 5 → `31·5 >> 5` = 4. The exact mode-1 composition with a per-pixel plate is
blit-pixel-rules.md's [MED].

## NOT RESOLVED (this file)
1. ~~Identity and size of the buffer `D+0x68` that the clip-select 0 path uses (`FUN_1000a530`
   copies its port bounds). Its width (576 vs 640) decides where buffer-bounds-clipped HUD text
   could be cut. Settle with `FUN_100099c0`/`FUN_1000ae20` (+0x68 creation).~~ → ⚑ corrected (review wave 3, 2026-10-06) #M3 / S:
   display-window-present.md §1/§4: `D+0x68` is the 640×480×16 work/back buffer (F52×F53×F56,
   `1000b320`), so the buffer-bounds clip is {0,0,480,640}.
2. ~~Which buffer the end-frame layer flush draws queued overlays into (assumed `D+0x68`, so the
   game-area-relative reading of §2.4 holds). Settle with `FUN_1001a650` → `FUN_10019570`
   immediate path (target port selection).~~ → ⚑ corrected (review wave 3, 2026-10-06) #M3: every non-terrain draw resolves port
   index `0x100e0179` = 0 → `FUN_1000ad90` → `D+0x68` (`10019728 lbz r4,-0x61b7(r2); bl
   0x1000ad90`, blit-pixel-rules.md §1; the index is written only by `FUN_10019c00(0, 1)`,
   sprite-manager-resource-image.md §0), so §2.4 holds [HIGH].
3. ~~Whether the tint blitter (flag 4, colourised text) applies cmd alpha +0x1c. If not, colourised
   messages (`meer`, `mest`) and colourised fades would not fade. This is blit-pixel-rules.md's
   question.~~ → ⚑ corrected (review wave 3, 2026-10-06) #C4 / S: blit-pixel-rules.md §1.2, §3 (mode 3 row `1001df00`): the tint leaf
   blends with α = a (cmd alpha) and skips at α ≥ 32, so colourised text does fade.
4. Formats 50–52 (`brti`/`brno`/`brpr`): no literal `FUN_1000d130` index in the census. They may
   be unused, or reached by a computed index [LOW].
5. ~~`FUN_1000c3b0` offsets D+0x0c/D+0x10 = buffer → window origin (decompile only) and
   `FUN_1000bbd0` (window copy, hud NR 4) [MED].~~ → ⚑ corrected (review wave 3, 2026-10-06) #M3 / S:
   display-window-present.md §5.2: `FUN_1000c3b0` adds `+0x10` to left/right and `+0xc` to
   top/bottom (`1000c3b0..1000c3e4`); `FUN_1000bbd0` = one CopyBits srcCopy (`1000bbd0…1000bc5c`).
6. The 8-bit-index frame scan (§1.4) is a re-implementation. A runtime dump of
   `FUN_10019ca0(tesm, 52..61/90)` would make the widths HIGH.

## Role-table rows (for merge)
| `FUN_1000d010` | G_Text.cc | module init: register "Text", digit cache {0,0}, live = 1, mono char ' ', font = tesp[0] + load, formats, glyph cache | HIGH | listing `1000d010…1000d0e8` |
| `FUN_1000d380` | G_Text.cc | draw formatted text: digit cache (labels `'0'+i` on strict increase), shadow pass if +0x10f, `COST` colour strip (always queued), text | HIGH | listing `1000d3c4..1000d474` (digit cache, `1000d3f4 li r4,0x31`, `1000d434 ble`), strip `1000d528..1000d55c` (§1.5, §2.3) — ⚑ corrected (review wave 3, 2026-10-06) #I1: merge row was missing |
| `FUN_1000e270` | G_Text.cc | layout + per-glyph draw per alignment; glyph record `r1+0x48` carries +0x10c/+0x10d/+0x110 | HIGH | listing `1000e328..1000e398` (width pass), `1000e524…1000e574` (record), `1000e598…1000e650` (§2.2, §4) — ⚑ corrected (review wave 3, 2026-10-06) #I1: merge row was missing |
| `FUN_1000e8d0` | G_Text.cc | character → font frame: 0x21..0x7e via jump table `0x100e542c`, all else (space, ≥ 0x80) → 90 | HIGH | listing `1000e8d4..1000e8e8` (`subi r0,r3,0x21; cmplwi 0x5d; bgt 0x1000ebc4; subi r3,r2,0xf04`) + table `0x100e542c` (§1.1) — ⚑ corrected (review wave 3, 2026-10-06) #I1: merge row was missing |
| `FUN_1000ef90` | G_Text.cc | parse a `tefo` text format into a zeroed local (template copy), unknown alignment → log + LEFT | HIGH | listing `1000f01c subi r3,r2,0x104c` (template copy, `li r0,0x29` CTR) + store census (§4) — ⚑ corrected (review wave 3, 2026-10-06) #I1: merge row was missing |
| `FUN_1000d0f0` | G_Text.cc | module shutdown: unregister, live = 0, formats-loaded = 0 | HIGH | listing `1000d0f0…1000d128` |
| ⚑ corrected `FUN_1000d130` | G_Text.cc | copy text format i (0x148 B) | HIGH | listing `1000d130…1000d228` — was MED (no listing) |
| `FUN_1000d230` | G_Text.cc | is the font sprite loaded | HIGH | listing `1000d23c` → `FUN_10019530` |
| ⚑ corrected `FUN_1000d260` | G_Text.cc | measure formatted text (digit cache, `FUN_1000e270(…,0)`) | HIGH | listing `1000d260…1000d368` — was MED |
| `FUN_1000d6d0` | G_Text.cc | fade one text element in (blend −1 per tick to 0, restore/draw/present each pass); loading lines | HIGH | listing `1000d74c…1000d7cc` |
| `FUN_1000d7f0` | G_Text.cc | draw element list (restore?, present?); sprite elements always restore | HIGH | listing `1000d844…1000da30` |
| `FUN_1000da50` | G_Text.cc | element bounds by index (button hit rect) | HIGH | listing `1000da8c…1000db64` |
| `FUN_1000db90` | G_Text.cc | fade element list in: alpha 31→0, 32 passes, `rate` ticks apart; text max(level, own), sprite level | HIGH | listing `1000dbd0…1000dee4` |
| `FUN_1000df00` | G_Text.cc | fade element list out: alpha 1→32, 32 passes; last pass erases | HIGH | listing `1000df40…1000e254` |
| ⚑ corrected `FUN_1000e670` | G_Text.cc | measure one glyph; draw it (skip space): cmd from template 0x100e5298, layer +0x10c, now +0x110, clip by +0x10d; shadow variant (−10, +10, alpha ≥ 17, flag 2) | HIGH | listing `1000e670…1000e8c4` — was MED (decompile) |
| ⚑ corrected `FUN_1000ebd0` | G_Text.cc | measure one character → frame; scale 1.0 → glyph cache, else GetDimensions | HIGH | listing `1000ec04…1000ec48` — was "draw one character" MED |
| `FUN_1000ec70` | G_Text.cc | fill glyph-size cache 0x100ff878 (c 0..127, scale 1.0) | HIGH | listing `1000eca0…1000ece4` |
| `FUN_1000ed10` | G_Text.cc | cached glyph size (c ≥ 0x80 → {0,0}) | HIGH | listing `1000ed10…1000ed50` |
| ⚑ corrected `FUN_1000ed60` | G_Text.cc | load the 54 permanent text formats | HIGH | listing `1000edb8 cmpwi r26,0x36` — was MED |
| ⚑ corrected `FUN_1000edf0` | G_Text.cc | load one tefo tag, parse into a zeroed local, copy 0x148 B | HIGH | listing `1000ee1c…1000ef64` — was MED |
| `FUN_1000f720` | G_Text.cc | static initialiser: draw template 0x100e5298 x,y/clip {0,0,480,416}/COST rect; format template Loc | HIGH | listing `1000f720…1000f790` |

## INDEX updates (for merge)
- **#6 closed** → §1.3–§1.5. Space = frame 90 (invisible), 4 px at scale 1.0, `trunc(4·s)`
  otherwise, never drawn. The cache filler is `FUN_1000ec70`.
- **#43 closed** → §2.4. Loc = buffer coordinates, with no offset added. In game it is
  game-area-relative (screen = +32), and overlays are clipped to the game area.
  (MED residue: §NR 2 — ⚑ corrected (review wave 3, 2026-10-06) #M3: closed, NR 2 struck.)
- hud-scorebar.md NR 3 closed (§2.2), NR 5 confirmed 6 px (§1.4–§1.5, ⚑ widths list order), NR 6
  closed. messages-notices-console.md NR 1, NR 2 closed. front-end.md §5.2 → HIGH (§3.1).
- New: `FUN_1000f720` writes the G_Text draw-template clip before main (for the INDEX #56 audit
  table).
