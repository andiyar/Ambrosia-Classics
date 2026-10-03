# Aki — game rules as the 1.2.0 code reads them

Source: `ghidra/Aki12_i386.decompiled.c` (1.2.0 i386 slice). Every function is cited `name @ addr`.
Constants are resolved with `python3 ghidra/read_const.py ghidra/Aki12_i386` (output pasted in §0).
1.1.0 differences are listed in `delta-1.1-vs-1.2.md`, not here. Nothing here is behaviour-verified:
these are code readings.

Labels: `[HIGH]` read in code, constants resolved, data path traced · `[MED]` one link inferred ·
`[LOW]` inference from names/strings/images.

## 0. Constants used in this file

```
$ python3 ghidra/read_const.py ghidra/Aki12_i386
=== __literal4  (0x33b1c..0x33b40, endian='<') ===
  0x00033b1c = 600.0     0x00033b20 = 0.5    0x00033b24 = 157.0   0x00033b28 = 392.0
  0x00033b2c = 60.0      0x00033b30 = 65536.0 0x00033b34 = -400.0 0x00033b38 = 400.0
  0x00033b3c = -0.5
=== __literal8  (0x33f98..0x34000, endian='<') ===
  0x00033f98 = 55.0  0x00033fa0 = 0.5  0x00033fa8 = 46.0  0x00033fb0 = 1.0  0x00033fb8 = 17.0
  0x00033fc0 = 32.0  0x00033fc8 = 10.0 0x00033fd0 = 23.0  0x00033fd8 = 27.5 0x00033fe0 = 4.0
  0x00033fe8 = 2.0   0x00033ff0 = 4294967296.0  0x00033ff8 = 1000000.0
```
Time is QuickDraw ticks (`_TickCount`, 60 per second); `0x3c` = 60, `0x708` = 1800, `0x2328` = 9000,
`18000`, `0x96` = 150, `300`.

Global blocks: `_g` @ 0x34780 (game state, accessed as `PTR__g_00038024 + off`) and `_p` @ 0x349c0
(persistent prefs/stats, `PTR__p_00038028 + off`), addresses from `nm ghidra/Aki12_i386`. Field
meanings used below are derived in this file and summarised in `method-map-1.2.md` §6.

## 1. Board model

### 1.1 Tile record (0x28 bytes, `_malloc(0x28)` in `_AddTile` @ 0x146bc) [HIGH]
| off | type | meaning | evidence |
|---|---|---|---|
| 0x00 | s16 | layer z, 0 = bottom … 6 = top | `*puVar5 = g[0x1e8]` (the inverted layer) |
| 0x02 | s16 | face id 200..241 | written by `_ShuffleCustomTiles` (`*(short *)(iVar4 + 2) = sVar1`) |
| 0x04 | s16 | fade frame (0..10) during the match animation | `param_1[2]` loop in `_RedrawMatchedTiles` |
| 0x08 | f64 | y in half-units | `= 2*param_2` |
| 0x10 | f64 | x in half-units | `= 2*param_1` |
| 0x18 | u8 | open | set by `_SetOpenTiles` |
| 0x19 | u8 | visible (not covered) | set by `_SetVisibleTiles`; `AddTile` inits 1 |
| 0x1a | u8 | hint highlight | `_ShowNextCGHint` |
| 0x1b | u8 | selected (red) | `_SelectCGTile` |
| 0x1c | u8 | removed (matched, kept for undo) | `_RedrawMatchedTiles` |
| 0x1d | u8 | "fading" during match animation | `_RedrawMatchedTiles` |
| 0x20/0x24 | ptr | next / prev | doubly linked list `_gCGFirstPtr`/`_gCGLastPtr` |

Unit: one tile is **2 half-units wide and 2 tall**; layouts may place tiles on any half-unit, so
half-offset stacking (pyramids, bridges) is expressed directly. [HIGH] (follows from the ±2 / ±1
tests below).

### 1.2 Layer argument [HIGH]
`_AddTile(x, y, L)` takes L = 1 (top) … 7 (bottom) and stores z = 7 − L. Custom `.aki` files store z
directly (0 = bottom), see `file-formats.md`. Drawing loops z = 0..6 (`_DrawGameTiles` @ 0xfe0a
`local_44` 0→7), so z = 6 is drawn last (on top).

## 2. Visibility ("covered") — `_SetVisibleTiles` @ 0x12328 [HIGH]
For each tile T: visible := 1; then for every tile U with `U.removed == 0` and `U.z == T.z + 1`:
if |U.y − T.y| ≤ 1 and |U.x − T.x| ≤ 1 (half-units; tested as `== , == +1.0, == −1.0` with
DOUBLE_00033fb0 = 1.0) then visible := 0.
```c
if ((char)psVar5[0xe] == '\0' && *psVar6 + 1 == (int)*psVar5) {
  ... if ((dVar1 == dVar2) || (dVar2 == dVar1 + dVar3)) ... (dVar7 == dVar8 - dVar3) ...
      *(undefined1 *)((int)psVar6 + 0x19) = 0;
```
The goto tangle reduces to "y within ±1 AND x within ±1" on every path (traced by hand; the final
statement is reached only when both hold).
- Only the layer **exactly one above** is tested. A tile with a gap layer above it (something at
  z+2 but nothing at z+1 over it) counts as uncovered. [HIGH] — replica must copy this, not the
  "anything above" rule.
- Overlap of 1 half-unit counts as covering (a tile resting half on top covers both below it).

## 3. Open test — `_SetOpenTiles` @ 0x1245e [HIGH]
Decompile, condensed (NaN guards and gotos removed, comments added):
```c
*(undefined1 *)(psVar6 + 0xc) = 0;                       // open := 0
if (*(char *)((int)psVar6 + 0x19) == '\x01') {           // only visible tiles can be open
  ... if (*psVar6 == *psVar7) {                          // same layer
        dVar8 = x6 - DOUBLE_00033fe8;                    // x - 2.0 → left neighbour column
        if (dVar8 == x7) { if (y7 in {y6, y6+1, y6-1}) if (psVar7.removed == 0) bVar4 = true; }
        dVar8 = DOUBLE_00033fe8 + x6;                    // x + 2.0 → right neighbour column
        if (x7 == dVar8) { ...same y test... bVar3 = true; }
  if (!bVar3) open = 1;  if (!bVar4) open = 1;
```
Open := visible AND (no unremoved same-layer tile at x−2 with |Δy| ≤ 1 OR none at x+2 with
|Δy| ≤ 1). A neighbour at x±1 (half overlap, same layer) does **not** block. [HIGH]
The neighbour does not need to be visible itself — only not removed. [HIGH]

## 4. Faces and matching

### 4.1 Tile set (144) — `_C.97.126381` @ 0x33dc0 [HIGH]
`_ShuffleCustomTiles` begins `_memcpy(local_13c,&_C_97_126381,0x120)` (144 shorts). Read with:
```
python3 - <<'EOF'
import struct,collections; d=open('ghidra/Aki12_i386','rb').read()
off=0x33dc0-0x33b40+207680            # __const vaddr 0x33b40 at file offset 207680 (otool -l)
v=struct.unpack('<144h',d[off:off+288]); print(sorted(collections.Counter(v).items()))
EOF
→ 42 distinct ids: 200..204 ×4, 205..212 ×1 each, 213..241 ×4
```
So 34 faces × 4 = 136 plus 8 unique faces (205–212) = 144. The same table is byte-identical in 1.1.0
(`DAT_000d1af0`, compared in this session → True). The table order is irrelevant (faces are dealt
randomly, §5) except that it fixes the multiset. Face → picture: row `(face−200)×50` of
`tile_pictures.png` (39×2100 = 42 rows of 50), source rect `(0, face*50−10000, 38, face*50−9950)`
in `_DrawGameTiles`. [HIGH] Which face is which suit (bamboo/circle/number/winds/seasons) is only
visible in the PNG — [LOW] naming per the Handbook ("eight Season unique tiles that match with
each other" ⇒ 205–212 are the seasons).

### 4.2 Match test — `_SelectCGTile` @ 0x13eec [HIGH]
```c
if ((psVar1[1] == psVar5[1]) ||
   (((ushort)(psVar1[1] - 0xcdU) < 8 && ((ushort)(psVar5[1] - 0xcdU) < 8)))) { ...match... }
```
Two tiles match iff identical face, or both faces in 205..212 (0xcd..0xd4): **all eight
"season" tiles match one another** (not two groups of four as in common mahjong solitaire). The
same predicate is used by `_CountOpenPairs` and `_ShowNextCGHint`. [HIGH]

## 5. Dealing / shuffle — `_ShuffleCustomTiles(char reuse)` @ 0x12763 [HIGH]
Decompile, condensed (the unrolled zeroing loop and the 16-bit modulo idiom
`(short)iVar5 + (short)(iVar5 / 0x90) * -0x90` written as `% 144`):
```c
do {
  _memcpy(local_13c,&_C_97_126381,0x120);   uVar3 = _TickCount();  _srand(uVar3);
  if (reuse) { zero all 144 slots; copy the faces of the current tiles, in list order, into slots 0..N-1 }
  for (tile in list order) {
     do { iVar5 = _rand(); sVar2 = iVar5 % 144; } while (local_13c[sVar2] == 0);
     tile.face = local_13c[sVar2]; tile.hint = 0; tile.selected = 0; local_13c[sVar2] = 0;
  }
  _SetVisibleTiles(); _SetOpenTiles(); sVar2 = _CountOpenPairs(); g[0x60] = sVar2;
} while (sVar2 == 0);
```
- Fresh deal (`reuse` = 0, from `_LoadLayout` @ 0x132f1 and `_LoadCustomLevel`): uniform random
  assignment of the 144-tile multiset to the 144 positions by rejection sampling. Re-dealt until at
  least one open pair exists. **No solvability guarantee** (the Handbook concedes this). [HIGH]
- Reshuffle (`reuse` = 1): same, but the multiset is the faces of the tiles still in the list
  (after `_DeleteTile` of removed ones, §8). [HIGH]
- RNG: libc `srand(TickCount())` then `rand()`; re-seeded each attempt, so a failed attempt within
  the same tick repeats the same permutation until the tick changes. The replica needs any uniform
  RNG; the exact sequence is unreproducible by design (tick seed). [HIGH]
- Theoretical hang: a reshuffle with exactly one open position never finds a pair. §8 step 7 ⚑ corrected (review 2026-10-03) ends the game
  at one open tile, which prevents the common case. [MED] (reasoned, not exhaustive)

## 6. Open-pair count — `_CountOpenPairs` @ 0xe5e4 [HIGH]
Over open, unremoved tiles T: m(t) = number of other open unremoved tiles matching t.
A = #{t : m(t) > 0}; B = #{t : m(t) == 2}. If B == 6 then A −= 2. If A is odd, A −= 1.
Result = (short)(A × 0.5) (DOUBLE_00033fa0 = 0.5), stored to g+0x60 and drawn as "#Open"
(`_RedrawCustomOpenPairs` @ 0x103f5, up to 3 digits). It is an approximation: exact for pairs and
for one or two open triples, over-counts for three triples. The replica must reproduce the formula,
not a true matching count, because g+0x60 == 0 is the "no more pairs" trigger. [HIGH]

## 7. Selecting and matching — `_SelectCGTile(Point)` @ 0x13eec [HIGH]
Hit test, from z = 6 down to 0 (`local_40` 6→0, `local_1e` = 5z: 30 → 0 step −5), tiles in list
order within a layer. Pixel box of tile (x, y, z in half-units):
```
left = (short)(int)(46.0*x*0.5) + 5z − g[0x94]        hit if left ≤ h ≤ left+0x32 (50)
top  = (short)(int)(55.0*y*0.5) − 10z + g[0x98]       hit if top  ≤ v ≤ top +0x3b (59)
```
(0x33fa8 = 46.0, 0x33f98 = 55.0, 0x33fa0 = 0.5 → 23 px per half-unit across, 27.5 px down; layer
shift +5 px right, −10 px up.) The first tile in that order whose box contains the click **and**
is open and not removed is taken. Closed tiles are skipped, not "absorbing": a click on a closed
tile can land on an open tile of a lower layer whose box overlaps the point. [HIGH]
Point unpacking: on i386 the `Point` arrives as `(v | h<<16)`; `sVar3 = param>>16` is h,
`(short)param` is v. [MED] (struct layout inference; consistent with all callers).

State machine with selection pointer g+0x1ec:
| situation | effect | sound id (file) |
|---|---|---|
| click the selected tile | deselect | 0x5a unclick.aiff |
| nothing selected | select (red, tile+0x1b) | 10 tilehit.mp3 |
| selected + matching tile | `_RedrawMatchedTiles`, bonus (§10) | stop 0x50, play 0x46 TileMatch.aiff |
| selected + non-matching | `break` out of this layer's loop, continue lower layers | 0x50 cancel.aiff |
| no hit anywhere | on the last list tile of the z = 0 pass, deselect if something selected | 0x5a |

Mismatch subtlety [HIGH, reading of control flow]: after the mismatch `break`, the z-loop continues
downward; when the z = 0 pass reaches the last tile with a selection still set, the old selection is
cleared (0x5a). So a mismatch on a tile at z > 0 ends with **nothing selected**; a mismatch on a
z = 0 tile ends the function with the **old selection kept**. Owner to confirm feel.
⚑ corrected (review 2026-10-03): the lower-layer passes after the `break` still run the full hit/open test, so a lower-layer
open tile whose hit box also contains the point (e.g. the z−1 tile two columns right: its box starts
at left+41, inside the 51-px box) is compared against the still-set selection and can **match**
(pair removed) or mismatch again. The two conclusions above hold only when no lower open tile is hit.
[HIGH, reading of control flow]

Mouse gating — `-[Controller mouseDown:]` @ 0x4489 [HIGH]: clicks with v in 0x22b..0x24b (555..587)
go to the button bar (`_SelectCGButton`); otherwise, if not paused and g+0x60 > 0, `_SelectCGTile`.
A second click within `GetDblTime()/2` ticks of the previous one is ignored unless it moved more
than 1 px in **both** h and v. Any click resets the idle clock g+0x4c.

## 8. Removing a pair — `_RedrawMatchedTiles(tile)` @ 0x13af5 [HIGH]
Order of operations:
1. Clear every hint flag (tile+0x1a). If difficulty > 1 set g+0x1f1 = 1 (enables Undo menu).
2. `_DeleteTile` (free) every tile already marked removed — i.e. the **previous** pair is now gone
   for good.
3. Mark both tiles fading (+0x1d); collect neighbours within ±4.0 half-units of either tile into the
   ST list (`_CalculateSurroundingTiles` @ 0x138a7, DOUBLE_00033fe0 = 4.0) for redraw; run the fade:
   up to 11 frames (`param_1[2] < 0xb`), one frame only if animations are off (p+0x213 == 0).
4. Mark both removed (+0x1c = 1), clear selection, `_SetVisibleTiles`, `_SetOpenTiles`, redraw #Open.
5. g+0x62 := count of unremoved tiles. If g+0x60 == 0: stop music, play 0x14 (Reshuffle.aiff).
6. If tiles remain: `_RedrawCustomGameScreen(1)` (this draws the "no more pairs" state, §11).
7. If exactly **one** open unremoved tile exists and tiles remain: dialog 0x47 ("Stacked" nib),
   g+0x7d = 1 (lost), g+0x68 = 1 (end level); custom level ⇒ g+0x229 = 1 (offer Try Again). The
   stacked loss does **not** increment the loss counter. [HIGH]
8. If no tiles remain: g+0x68 = 1 (win is processed in `_CustomGameScreen`, §14 ⚑ corrected (review 2026-10-03)).

## 9. Hint — `_ShowNextCGHint` @ 0x12622 [HIGH]
1. Clear all current hint flags; remember the first hinted tile in list order (F).
2. Charge the penalty (§10) — **always**, even if no hint is found.
3. Scan from F.next (or the list head if there was no hint) to the end of the list: the first open
   unremoved tile with a matching open unremoved partner (partner = first in list order) gets both
   tiles flagged; redraw; stop. No wrap-around: if the scan reaches the end, no hint is shown.
Because F is the earlier of the two hinted tiles in list order, pressing hint again can show the
same pair. Gate: hint button / menu only when g+0x60 ≠ 0 and not paused (`_SelectCGButton`,
`_HandleMenuCommand` case 4).

## 10. Time, bonus, penalties — `_CustomGameScreen` @ 0x12dbc, `_RedrawCustomTimeBar` @ 0xefa0

Difficulty is p+0x20c: **0 = Hard, 1 = Medium (default), 2 = Easy, 3 = Practice**. [HIGH for the
mapping]: `_RedrawMapScreen` blits source rect `(0x128, diff*0x17+0xf1, 0x17b, …)` of `misc.png`,
and the image at x 296..379 shows, top to bottom from y 241, "Hard / Medium / Easy / Practice"
(viewed this session). `_LoadPrefs` default `*(short *)(p + 0x20c) = 1`.

State (seconds unless noted): a8 start tick · ac penalty · b0 bonus · b4 elapsed · b8 remaining ·
bc remaining frozen at "no more pairs" · c0 tick when frozen/paused.

| rule | code | [label] |
|---|---|---|
| level start: a8 = now, ac = b0 = b4 = c0 = 0, b8 = 150 | `_AnimationMapScreenToCustom` @ 0x10f5f: `+ 0xb8) = 0x96` | [HIGH] |
| each tick (≥ 2 ticks since last, not paused, not ended): b4 = (now − a8)/60; b8 = 150 − ((b4 + ac) − b0) | `_CustomGameScreen`: `0x96 - ((iVar7 + ac) - b0)` | [HIGH] |
| cap: if b8 > 300 then ac += b8 − 300 | `_RedrawCustomTimeBar`, `_RedrawCustomGameScreen` | [HIGH] |
| match bonus b0 += Hard 3 / Medium 6 / Easy 12 / Practice 0 | `_SelectCGTile` switch on p+0x20c | [HIGH] |
| hint penalty ac += b8/2 Hard, b8/4 Medium, b8/8 Easy, 0 Practice (C truncating division) | `_ShowNextCGHint` | [HIGH] |
| reshuffle penalty ac += 3·b8/4 Hard, b8/2 Medium, b8/4 Easy, 0 Practice; none if b8 == 0 | `_ReshuffleCustomTiles` @ 0x133ff | [HIGH] |
| undo penalty ac += 3 Hard, 6 Medium, 12 Easy — but undo runs only for p+0x20c > 1, so in practice **Easy +12 s, Practice 0** | `_UndoLastCGMove` @ 0x128cb + `_HandleMenuCommand` case 3 `1 < p[0x20c]` | [HIGH] |
| Practice: a8 := now on every time-bar redraw ⇒ elapsed stays 0, remaining stays 150 | `if (p[0x20c] == 3) g[0xa8] = TickCount()` | [HIGH] |
| time-out: b8 < 1 (checked only while g+0x60 ≠ 0) ⇒ stop music & tick, g+0x7d = 1, losses[level]++ (built-in) or g+0x229 = 1 (custom), save prefs, end | `_RedrawCustomTimeBar` tail | [HIGH] |
| low-time tick: b8 < 16 starts sound 100 (tick.mp3), stops when ≥ 16; looped while < 15 | `_RedrawCustomTimeBar`, `_CustomGameScreen` | [HIGH] |
| idle prompt: no click for > 1800 ticks (30 s) ⇒ hint button flashes until next click | `g[0x84] = g[0x4c] + 0x708 < now` | [HIGH] |

Handbook cross-check: it says Hard = "penalties 50% more than medium, bonus 50% less" and Easy =
"penalties 50% less, bonus 50% more". Code: bonus Hard 3 vs Medium 6 (−50% ✓), Easy 12 (+100% ✗);
hint Hard 1/2 vs 1/4 (+100% ✗), Easy 1/8 (−50% ✓). Code governs. [HIGH]

Time bar: length L = min(450, (9000 − ((now − a8) + 60·ac − 60·b0)) × 450 / 18000) px — i.e. 1.5 px
per second, full width = 300 s; the bar is drawn as k = ⌊L/24⌋ (≤ 17) stones of 25 px from
`misc.png` row y 39..78 masked by row y 78..117, plus an end-cap stone chosen by the remainder from
a 6-column grid of partial stones (rows y 117..273). Drawn into window rect (0x8d,0x22d)-(0x255,0x24c).
[MED] — arithmetic HIGH; which pixels the player perceives as "black" vs "grey (overtime)" stones
(Handbook: "time over the two and a half minutes is displayed by grey time stones that appear over
the original black ones") is NOT RESOLVED from code alone; the black slots are probably painted by
`plate.png`, which this session did not decode.

Elapsed display: `_RedrawCustomTimeAccumulated` @ 0xe6e4 draws b4 as HH:MM:SS (b4/3600, %3600/60,
%60) with digit sprites; not drawn while g+0x60 == 0. [HIGH]

## 11. "No more pairs" state [HIGH]
`_RedrawCustomGameScreen` @ 0x10a07 calls `_RedrawNoMorePairs` @ 0x10854 when g+0x60 == 0 and
tiles remain: overlay `nopairs.png` at (0x128,0x1a); all tiles drawn with the grey row of
`tiles.png` (y 207..276, `_DrawGameTiles` branch `g[0x60] == 0`); g+0x85 = 1 (reshuffle button
flashes); bc := b8; c0 := now (time frozen). Hint and pause buttons are inert (they require
g+0x60 ≠ 0). Leaving the state:
- Reshuffle **button**: a8 += now − c0, c0 = 0, b8 := bc, then `_ReshuffleCustomTiles` → penalty
  from the frozen b8.
- Reshuffle **menu** (⌘R, tag 6): a8 += now − c0, c0 = 0 but b8 is *not* restored, so the penalty
  uses the last per-tick b8 (which kept counting down while frozen). [HIGH] — a small 1.2 quirk
  between two paths to the same action; owner to arbitrate whether to copy.
- Undo (Easy/Practice): a8 += now − c0, c0 = 0, then undo.
The time-out test does not run in this state (body of `_RedrawCustomTimeBar` is skipped when
`_CountOpenPairs() == 0`).

## 12. Undo — `_UndoLastCGMove` @ 0x128cb [HIGH]
Restores the first two tiles in list order with removed == 1 (only the last matched pair can be in
that state, §8 step 2), clears their selection, recomputes visibility/open, redraws, charges the
penalty (§10). **Depth = 1 pair.** Nothing to undo after a reshuffle (reshuffle deletes removed
tiles) — then no penalty. Gate: menu tag 3 only if p+0x20c > 1 (Easy, Practice) and b8 ≠ 0; the
menu item is enabled from the first match onward (g+0x1f1) and stays enabled after an undo (the
re-disable is under `p[0x20c] < 2`, unreachable). A second undo is a silent no-op.

## 13. Pause — `_PauseGame(bool)` @ 0xd34b [HIGH]
Pause: g+0x67 = 1; if pairs exist and not already frozen, c0 = now; stop tick sound; music stops
(`_PlayMovie` stops the track while g+0x67); the board is not drawn (`_RedrawCustomGameScreen`
draws tiles only when its argument = !paused) and `pause.png` is overlaid. Unpause: a8 += now − c0,
c0 = 0. Entry points: pause button (only when g+0x60 ≠ 0), Game menu tag 7 (any time in game),
window losing main status (`-[Controller windowDidResignMain:]` pauses, `windowDidBecomeMain:`
unpauses if it paused), Preferences sheet (`-[Controller showPreferences:]` sends `pause`).
App deactivation alone only stops music (`applicationWillResignActive:`). [HIGH]

## 14. End of level [HIGH]
`_CustomGameScreen`, next tick after g+0x62 reached 0:
- stop music, play 0x1e (LevelComplete.aiff); for built-in levels (index < 12):
  wins[level]++ (p+0x218 + 2·level) **including Practice**; best time p+0x260 + 4·level := min(b4)
  (first win stores b4) **except Practice**; save.
- not Practice: unlock next level p+0x201 + level = 1 (for level < 11); custom level clears the
  first-run guide flag g+0x22b.
- demo gate (out of scope): unregistered + level index 2 → "Completed Demo" alert.
- g+0x68 = 1 → return to the map (`_AnimationCustomGameScreenToMap` @ 0xdca0). For a **win** the
  bookkeeping block sets g+0x68 and the **same** `_CustomGameScreen` invocation falls into the `else`
  branch that runs the transition; "next tick" applies only to stacked/time-out losses ⚑ corrected (review 2026-10-03). Only if
  g+0x7d (lost: time-out or stacked) is set: it plays GameOver.aiff (0x28), and `_RedrawMapScreen`
  then shows a random proverb splash (`_RandomProverbScreen` @ 0x60c8: `random() % 11`, one
  157-px strip of `proverbs.png`), and for a lost custom level the "TryAgain" dialog (0x53) whose
  OK reloads the same file (g+0x22a → `_LoadCustomLevel`).
Give Up (menu tag 2 / Escape / quit) → `-[Controller abortGame]` @ 0x3cbc: confirmation dialog 0x57
("LoadLevel" nib); on OK give-ups[level]++ (p+0x248 + 2·level, level < 12), end level. No proverb.

## 15. Not modelled by the code (stated so nobody invents them)
No score. No undo history beyond one pair. No solvability check. No "auto-match" or end-of-game
bonus. Stats are counts and best times only (`file-formats.md` §3).
