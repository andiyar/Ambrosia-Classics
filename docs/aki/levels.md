# Aki — levels: layouts, 1.1 ↔ 1.2 diff, levels 13–17, progression

Sources: `ghidra/Aki12_i386.decompiled.c` (1.2), `/Users/andiyar/Developer/Ambrosia/ghidra/Aki_ppc.decompiled.c`
+ binary `Aki_ppc` (1.1), bundle `Localizable.strings`. The full tile lists are in
`levels-layouts.md` (generated). Labels as in `rules.md`.

## 1. Which function is which level — `_LoadLayout` @ 0x132f1 [HIGH]
`g+0x90` is the 0-based level index chosen on the map. The dispatch is **not** in name order:
```c
if (*(short *)(PTR__g_00038024 + 0x90) == 5) { _Layout10(); }   ... == 7 → _Layout11, == 9 → _Layout6, == 10 → _Layout8
```
| level | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 10 | 11 | 12 |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| function | Layout1 | Layout2 | Layout3 | Layout4 | Layout5 | **Layout10** | Layout7 | **Layout11** | Layout9 | **Layout6** | **Layout8** | Layout12 |
| sets g+0x8e (background N) | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 10 | 11 | 12 |

Each `_LayoutN` ends with `g+0x94 = dx; g+0x98 = dy; g+0x8e = level`, so the background number
always equals the level number; only the *function names* are shuffled. The 1.1 `LoadLayout` @
0x21b74 has the identical dispatch (`sVar2 == 5 → Layout10()`, …). [HIGH]
After the layout: `g+0x62 = 0x90` (144 tiles left), `g+0x1f1 = 0` (undo off),
`_ShuffleCustomTiles(0)`, slide-in animation, draw.

## 2. Mechanical diff of the 12 layouts, 1.1.0 vs 1.2.0 [HIGH]
Tool: `docs/aki/tools/diff_layouts.py` (written this session). 1.2 side parses the dump's
`_AddTile(lo,hi,lo,hi,L)` calls. 1.1 side: Ghidra's PPC decompile **lost the layer argument**
(under the Mach-O PPC ABI the two doubles shadow r3–r6, so the short is in r7, which the decompile
shows as `in_r7`/a chained return value) and five 1.1 layouts are written with `for` loops
(int→double via the `0x43300000` magic) where 1.2 is fully unrolled. So the tool **emulates** each
1.1 `LayoutN` over the binary's `__text` (a 22-opcode PPC subset: addi/addis/lfd/fmr/fadd/fsub/
xoris/stw/lwz/stfd/cmpwi/bc/bl/…) and records `(f1, f2, r7)` at each `bl AddTile` (0x21a2c). For
the seven loop-free 1.1 layouts the emulated (x,y) are also checked against the dump's
`AddTile(DOUBLE_x, DOUBLE_y, …)` literals.

```
$ python3 docs/aki/tools/diff_layouts.py
layout fn | level | 1.2 @addr  n | 1.1 @addr  n(dump) n(bin) | dump==bin xy | 1.2==1.1 (x,y,layer) ordered | as set
_Layout1  |     1 | 0x19294 144 | 0x10dc8 144 144 | True | True | True
_Layout2  |     2 | 0x259e4 144 | 0x17618 144 144 | True | True | True
_Layout3  |     3 | 0x160c0 144 | 0x0f6b0  22 144 | n/a (dump has loops) | True | True
_Layout4  |     4 | 0x240fa 144 | 0x16880 144 144 | True | True | True
_Layout5  |     5 | 0x22810 144 | 0x15aec 144 144 | True | True | True
_Layout10 |     6 | 0x1dd52 144 | 0x13214 144 144 | True | True | True
_Layout7  |     7 | 0x147d6 144 | 0x0f0b4   4 144 | n/a (dump has loops) | True | True
_Layout11 |     8 | 0x1c468 144 | 0x1267c  56 144 | n/a (dump has loops) | True | True
_Layout9  |     9 | 0x179aa 144 | 0x102d8  69 144 | n/a (dump has loops) | True | True
_Layout6  |    10 | 0x20f26 144 | 0x14d48 144 144 | True | True | True
_Layout8  |    11 | 0x1f63c 144 | 0x13fb0 144 144 | True | True | True
_Layout12 |    12 | 0x1ab7e 144 | 0x11b54  48 144 | n/a (dump has loops) | True | True
```
Result: **all 12 layouts are identical in 1.1.0 and 1.2.0, call-for-call, including the layer
argument and the order.** No "differing coordinates" section exists because there are none. The
per-layout pixel offsets are identical too (1.1 `g+0xe0/0xe4` = 1.2 `g+0x94/0x98`, compared value
by value from both dumps). Independent cross-check: `otool -tV ghidra/Aki12_i386 -p _LayoutN | grep -c
'calll\s*_AddTile'` = 144 for all 12, and the first call disassembles to `movl $0x5,0x10(%esp)`,
`movl $0x40200000,0xc(%esp)`, `movl $0x40140000,0x4(%esp)` = `_AddTile(5.0, 8.0, 5)`, matching the
table.

Which 1.1 `Layout1` is code (brief question): `Layout1 @ 0x10dc8` is the real function (164-line
block of `AddTile` calls). `Layout1 @ 0xd0274` is one of 217 `halt_baddata` blocks in
0xcf8c4..0x1041dc that Ghidra's demangler labels `Layout1() [clone .eh]` — exception-handling
tables mis-disassembled as code, not a thunk. [HIGH] (`grep -c halt_baddata` = 217 in the 1.1 dump;
every `LayoutN` has such a twin at 0xd01f0..0xd0374).

## 3. Levels 13–17 are not layouts [HIGH]
Hypothesis "17 levels in 1.2, 13–17 custom-format" is **refuted**. Evidence:
- There are exactly 12 layout functions and `_LoadLayout` dispatches only indices 0..11.
- No level data file exists in the bundle (listing in `assets-census.md`: PNG/AIFF/MP3/nibs/PDF only).
- `_RandomBackground` @ 0x12d60: `sVar1 = rand()%5 + 0xd; g[0x90] = sVar1; return sVar1;` →
  13..17. It is called by `_LoadCustomLevel` @ 0x14177 (g+0x8e = background) and by the "Open Level
  Editor" command.
- `+[LevelDescriptionWindowController runModalWithLayout:custom:]` @ 0x29d40 (no decompile block;
  read from `otool -tV`): `n = layout + 1`; title key = `custom ? "level%d_custom_title" :
  "level%d_title"` (cfstrings @ 0x345e0 / 0x345f0, `cmovel` on the `custom` byte), description key
  `"level%d_description"` (@ 0x34600), image `"preview%d"` (@ 0x34610). `_LoadCustomLevel` calls it
  with `(g[0x8e] − 1, 1)`.
So "levels 13–17" are **five decorations for user-made `.aki` levels**: a random one of
`background13..17.png` + `preview13..17.png` + the `level13..17_custom_title` /
`level13..17_description` strings (Pagoda at Bishamonten Shrine, Gokoku Shrine, The Gate at
Hiroshima Castle, Cenotaph for the A-bomb Victims, Sake Casks at Miyajima's Itsukushima Shrine).
The tile layout comes from the file. 1.1 does the same with PICT 200..204 (`RandomBackground` @
0x219c8 returns `rand()%5 + 200`, level index 12..16). Stats are never recorded for these
(all stat writes are guarded by `level < 0xc`).

## 4. Progression and unlock [HIGH]
- Unlock flags: p+0x200 + i (i = 0..11), u8. Default: level 1 unlocked (`p[0x200] = 1`), rest 0
  (`_LoadPrefs` @ 0x293f6 defaults).
- A non-Practice win of level index i < 11 sets p+0x201 + i (the next level). Practice wins never
  unlock (`if (sVar2 != 3)` in `_CustomGameScreen`). A Practice start on a level whose successor is
  still locked shows the alert "You will not be able to progress to the next level when playing in
  practice mode." with buttons Practice Level / Cancel (`_SelectMapArea` @ 0x78c2; 1.1 has no such
  alert — see delta).
- Map hit boxes (`_SelectMapArea`, `_MapScreen`): lantern i at (left, top) =
  (713,310) (403,176) (231,115) (89,45) (12,269) (234,356) (326,281) (355,294) (547,315) (434,223)
  (374,216) (405,244) for levels 1..12; clickable if left+23 ≤ h ≤ left+52 and top+17 ≤ v ≤ top+54.
  Same table in 1.1 (`DAT_000d1960`/`d1990`, read this session).
- Clicking a locked lantern → dialog 0x28 ("Unavailable" nib). **Holding Option** (GetKeys byte 7
  bit 2) bypasses the lock in both versions. [MED] — the bit test is HIGH; "bit 2 of byte 7 =
  Option (key code 58)" is KeyMap layout knowledge, not read from the binary.
- Unregistered builds: indices ≥ 3 not selectable and a "Completed Demo" alert after level 3 —
  registration layer, out of scope; the replica behaves as registered.
- Map rendering: the highest unlocked lantern gets a 4-frame flashing marker (frame counter
  ping-pongs 0→3 every > 6 ticks); hovering a lantern blits that level's 237×181 strip of
  `previews.png` at (0x207,0x2b), plays Preview.aiff, and overlays `notavail.png` rows 50..100 if
  locked. [HIGH]
- First-run guide: `SplashScreen("guide")` before a level when level 2 is still locked and g+0x22b
  (set at launch) is 1. [HIGH]
- Level description: if p+0x214 ("Display Level Description") the LevelDescription window
  (title, description, 237×181 preview, Continue/Cancel, its own checkbox) precedes the level;
  Cancel sets g+0x7c and the level is not started; Continue stores the dialog's checkbox into
  p+0x214 and starts it. [HIGH] — `otool -tV -p '-[LevelDescriptionWindowController cancel:]'`:
  `movl 0x38024,%eax; movb $0x1,0x7c(%eax)`; `continue:`: `[_checkbox state]; decl %eax;
  sete 0x214(p)`. (Ghidra's 13-line blocks for these methods dropped the stores.)

## 5. Difficulty ↔ level [HIGH]
Difficulty is global (p+0x20c), chosen on the map's bottom bar: x 0x11c..0x13b → +1 (3 wraps to
0), x 0x140..0x203 → −1 (0 wraps to 3) (`_SelectMenuOptions` @ 0x8041). It does not change the
layout; it changes bonus/penalty/undo (rules.md §10) and Practice disables time, best-time
recording and unlocking. Wins/losses/give-ups are recorded per level regardless of difficulty
(wins even in Practice). There is no per-difficulty stats split.

## 6. "Replay Last Level" and "Play Custom Level" [HIGH]
Both refer to **custom (.aki) levels only**:
- Play Custom Level… (tag 14, ⌘⇧N): clears g+0xd0 and opens the file picker (`aki` extension or
  HFS type `LVLE`), then `_LoadCustomLevel`.
- Replay Last Level (tag 18): enabled only when g+0xd0 (FT path of the last custom file) ≠ 0; the
  menu title becomes `"Replay %@"` with the file name. It re-reads the same file (new random deal,
  new random 13–17 decoration).
- Try This Level (tag 19, editor): enabled at exactly 144 tiles (g+0x1f2); saves if dirty, leaves
  the editor and plays the file.
There is no "replay the last built-in level" command; built-in levels are started from the map.

## 7. NOT RESOLVED here
- Whether 1.1's per-level backgrounds (PICT 140–151, assigned non-sequentially by `LayoutN`:
  Layout1→143, Layout2→151, Layout3→141, Layout4→150, Layout5→149, Layout6→146, Layout7→140,
  Layout8→145, Layout9→142, Layout10→148, Layout11→147, Layout12→144) are the same pictures as
  1.2's `backgroundN.png` for the same level. Needs PICT decoding.
