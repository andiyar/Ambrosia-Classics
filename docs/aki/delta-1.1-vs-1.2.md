# Aki — every rule/behaviour delta between 1.1.0 (Carbon, PPC) and 1.2.0 (Cocoa, i386)

1.1 = `/Users/andiyar/Developer/Ambrosia/ghidra/Aki_ppc.decompiled.c` (+ binary `Aki_ppc`, sha256
c53f581c…6366, byte-identical to the 1.1.0 bundle executable — `shasum` this session).
1.2 = `ghidra/Aki12_i386.decompiled.c`. The replica follows 1.2 unless the owner rules otherwise.
"Arb?" = owner to arbitrate (Y = a real choice; – = cosmetic/plumbing or 1.2 clearly a bug fix).
Field names: 1.1 `g` offsets differ from 1.2 (e.g. 1.1 remaining time g+0x104 = 1.2 g+0xb8); the
`_p` prefs struct has the **same** offsets in both.

## A. Compared and found identical (no delta)
| # | subsystem | 1.1 | 1.2 | conf. |
|---|---|---|---|---|
| A1 | 12 built-in layouts, tile order, layer args | `Layout1..12` (emulated, `tools/diff_layouts.py`) | `_Layout1..12` | HIGH |
| A2 | level → function dispatch (6→Layout10, 8→11, 10→6, 11→8) | `LoadLayout` @ 0x21b74 | `_LoadLayout` @ 0x132f1 | HIGH |
| A3 | per-layout pixel offsets | `g+0xe0/0xe4` in each `LayoutN` | `g+0x94/0x98` | HIGH |
| A4 | 144-tile face multiset (34×4 + 8 seasons) | `DAT_000d1af0` | `_C.97.126381` @ 0x33dc0 | HIGH (byte compare) |
| A5 | visibility rule (layer +1 only, ±1 half-unit) | `SetVisibleTiles` @ 0x20aac | @ 0x12328 | HIGH |
| A6 | open rule (left/right at ±2, |Δy| ≤ 1) | `SetOpenTiles` @ 0x20be0 | @ 0x1245e | HIGH |
| A7 | match predicate (same face, or any two of 205–212) | `SelectCGTile` @ 0x1fd04 | @ 0x13eec | HIGH |
| A8 | hit-test geometry (23 / 27.5 px per half-unit, +5/−10 px per layer, 51×60 box, top layer first, closed tiles skipped) and the mismatch fall-through | `SelectCGTile` (DOUBLE_000d4588 = 55, d4598 = 46, d44f8 = 0.5 via `read_const.py Aki_ppc`) | `_SelectCGTile` | HIGH |
| A9 | deal / reshuffle algorithm (srand(TickCount), rand()%144 rejection, retry until ≥ 1 pair) | `ShuffleCustomTiles` @ 0x20488 (retries by recursion) | @ 0x12763 (loop) | HIGH |
| A10 | open-pair count formula (incl. B == 6 ⇒ −2, round to even) | `CountOpenPairs` @ 0x20d94 | @ 0xe5e4 | HIGH |
| A11 | time limit 150 s, b8 = 150 − (elapsed + pen − bonus), cap 300, bar 450 px / 18000 ticks | `CustomGameScreen` @ 0x1c05c, `RedrawCustomTimeBar` @ 0x1ccf0 | @ 0x12dbc, @ 0xefa0 | HIGH |
| A12 | match bonus Hard 3 / Medium 6 / Easy 12 | `SelectCGTile` / `AddBonusTime` @ 0x1fc94 | `_SelectCGTile` | HIGH |
| A13 | hint: penalty rem/2, /4, /8; scan order from after previous hint, no wrap | `ShowNextCGHint` @ 0x205b4 | @ 0x12622 | HIGH |
| A14 | reshuffle penalty 3/4, 1/2, 1/4 of remaining | `ReshuffleCustomTiles` @ 0x20318 | @ 0x133ff | HIGH |
| A15 | undo: one pair, +3/+6/+12, allowed only diff ≥ 2 and remaining ≠ 0 | `UndoLastCGMove` @ 0x207e8 + handler `'un  '` | @ 0x128cb + tag 3 | HIGH |
| A16 | "stacked" loss when exactly one open tile remains (no loss counter) | `RedrawMatchedTiles` @ 0x1f4f4 (`CountOpenTiles() == 1`) | @ 0x13af5 | HIGH |
| A17 | no-more-pairs freeze (bc, c0), reshuffle button restores | `RedrawNoMorePairs` @ 0x1f824, `SelectCGButton` @ 0x1ffe8 | @ 0x10854, @ 0x1356f | HIGH |
| A18 | win bookkeeping: wins++ incl. Practice, best time excl. Practice, unlock next if not Practice | `CustomGameScreen` | `_CustomGameScreen` | HIGH |
| A19 | time-out: losses++ (built-in), TryAgain for custom | `RedrawCustomTimeBar` tail | same | HIGH |
| A20 | Practice: timer base reset each redraw | `RedrawCustomTimeBar` (`p[0x20c] == 3`) | same | HIGH |
| A21 | map lantern positions & hit boxes, Option-key lock bypass, demo gate | `SelectMapArea` @ 0x9c54 (`DAT_000d1960/1990`) | `_SelectMapArea` @ 0x78c2 | HIGH |
| A22 | difficulty buttons on the map bar (wrap 0↔3) | `SelectMenuOptions` @ 0x9ef0 | @ 0x8041 | HIGH |
| A23 | default prefs values | `SetDefaultPrefs` @ 0xa424 | `_LoadPrefs` defaults | HIGH |
| A24 | `.aki` text format, 144-tile play rule, < 144 → editor | `LoadCustomLevel` @ 0x2155c, `DoSaveAs` @ 0x1b77c | @ 0x14177, @ 0xb89d | HIGH |
| A25 | click double-fire guard (GetDblTime/2, > 1 px both axes) | `MainRunLoopForThreadedApps` @ 0xe6a4 | `-[Controller mouseDown:]` | HIGH |
| A26 | sound ids/files (except tilehit, D15) | `InitializeSound` | `_InitializeSound` | HIGH |
| A27 | custom-level "levels 13–17" = 5 random decorations, stats not recorded | `RandomBackground` @ 0x219c8 | @ 0x12d60 | HIGH |
| A28 | Give Up via menu with confirmation (dialog 0x57) | `'new '` handler | `abortGame` | HIGH |
| A29 | idle hint-button flash after 1800 ticks | `CustomGameScreen` (`g[0xd0]`) | `g[0x84]` | HIGH |

## B. Deltas
| # | subsystem | 1.1 reading | 1.2 reading | conf. | impact on replica | Arb? |
|---|---|---|---|---|---|---|
| D1 | Escape key during a level | `MainRunLoopForThreadedApps` @ 0xe6a4: key 0x35 in game ⇒ give-ups[level]++ (guarded < 12), end level, stop music — **no confirmation** | `-[Controller keyDown:]` @ 0x42eb (otool: `cmpw $0x1b` → `abortGame`) ⇒ confirmation dialog first | HIGH (1.2 disassembly) / MED (1.1 decompile) | Esc = Give Up with/without "Are you sure" | Y |
| D2 | Quit during a level | `MainWindowCommandHandler` @ 0xa7b8 `'quit'` in game: give-ups[level]++ **without** the level < 12 guard and without confirmation, then quit. For a custom level (index 12..16) the 16-bit increment lands at p+0x248 + 2·idx = 0x260/0x262/0x264/0x266/0x268 inside the big-endian 32-bit best times of levels 1–3 (best[0] @ 0x260, best[1] @ 0x264, best[2] @ 0x268): idx 12/14/16 hit the **high** halves of best[0]/best[1]/best[2] (+65536 s), idx 13/15 the **low** halves of best[0]/best[1] (+1 s) ⚑ corrected (review 2026-10-03) | `applicationShouldTerminate:` → `abortGame`: confirm, guarded | MED (decompile; the index arithmetic is plain) | 1.1 bug; replica should use 1.2 | – |
| D3 | Escape in the Level Editor | `MainRunLoopForThreadedApps`: key 0x35 in editor ⇒ `DoSaveAs()` always, then "Incomplete" dialog if < 144, then map | `exitLevelEditor`: Save / Don't Save / Cancel alert only if dirty | MED | editor exit UX | Y |
| D4 | Practice warning | none: `SelectMapArea` goes straight to the level | alert "You will not be able to progress…" (Practice Level / Cancel) when the next level is still locked | HIGH | one extra dialog | Y |
| D5 | Undo menu item after an undo | `UndoLastCGMove`: `if (1 < diff) DisableMenuCommand('un  ')` — the `DisableMenuCommand(0,'un  ')` call is seen by review, its `1 < diff` guard **not re-verified** [LOW] ⚑ corrected (review 2026-10-03) | `if (diff < 2) g[0x1f1] = 0` (unreachable) ⇒ stays enabled; a 2nd undo is a silent no-op | HIGH (1.2 side); 1.1 guard LOW | menu-state only | – |
| D6 | Pause on losing focus | `mySRHandler` @ 0xed94: app deactivated ⇒ `PauseGame(1)` in any mode | pauses on `windowDidResignMain:` only when **not** fullscreen; app deactivation alone just stops music | MED | fullscreen focus loss | Y |
| D7 | Reshuffle via menu in "no more pairs" | `'resh'`: a8 += now − c0 but b8 not restored (same as 1.2) | same | HIGH | (listed because the **button** path differs from the menu path in both versions — rules.md §11) | Y |
| D8 | No-more-pairs sound/music stop | `RedrawNoMorePairs` plays Reshuffle.aiff and stops music on **every** full redraw in that state | played once in `_RedrawMatchedTiles` when pairs hit 0 | MED | possible repeated sound in 1.1 | – |
| D9 | Full redraw after each match | only when no pairs remain | `_RedrawCustomGameScreen(1)` after every match while tiles remain | HIGH | none visible expected (redraw cost) | – |
| D10 | Time-bar draw guard | stone loop runs regardless of remaining | `while (0 < iVar3 && 0 < sVar5)` — nothing drawn at ≤ 0 | MED | last-frame visuals at time-out | – |
| D11 | Main loop cadence | busy loop: `ReceiveNextEvent(…, 0)` then Map/Game/Editor screen every iteration | `NSTimer` 0.05 s → `idleTimerFired:` | HIGH | game tick granularity (both gate on TickCount deltas: time ≥ 2 ticks, flashes > 5, map > 6) | – |
| D12 | Level description window | Carbon nib windows "Level 1".."Level 17" in `Aki.nib` via `CreateNewDialog(10)`; cancel flag g+200 | Cocoa `LevelDescriptionWindowController` + `Localizable.strings` keys, preview image, own checkbox writes p+0x214 on Continue | HIGH | presentation | – |
| D13 | Preferences storage | file `Aki Prefs` in the Preferences folder, type `Pref`, creator `*LMS`, raw 0x290-byte struct (`SavePrefs` @ 0xa348) | `NSUserDefaults` key `GameSettings`, 143-byte packed BE blob; one-time migration from the 1.1 file | HIGH | replica storage choice (format is the owner's) | Y |
| D14 | Preferences contents | Sound, Music, *Tile Animation (with perf note), Full Screen (800 x 600), Display Level Description, **Check online for updates** (p+0x216, Reggie version check: `DAT_000d80fe` = 1.1 `_p`+0x216 gates `ReggieVersionCheck`) | same minus "Check online" (Sparkle instead; p+0x216 kept but unused) | HIGH | drop update UI (out of scope) | – |
| D15 | tilehit sound | `tilehit.aiff` (4362 bytes) | `tilehit.mp3` (990 bytes) | HIGH | asset choice | Y |
| D16 | Graphics source | 82 `PICT` resources in `Aki - Mahjong Solitaire.rsrc` (backgrounds 140–151 + 200–204, previews 300–315 + 400–404, …), 16-bit GWorlds (`NewGWorld(…, 0x10, …)`) | PNG files, 32-bit GWorlds | HIGH | asset fidelity: 1.2 PNGs are the better source | Y |
| D17 | Background ↔ level | `LayoutN` sets PICT id (L1→143, L2→151, L3→141, L4→150, L5→149, L6→146, L7→140, L8→145, L9→142, L10→148, L11→147, L12→144) | background N for level N | HIGH (ids) / NOT RESOLVED (same pictures?) | which image per level | Y |
| D18 | Custom decoration numbering | level index 12..16, PICT 200–204, description windows "Level 13".."Level 17" | index 13..17, `background13..17.png`, `level13..17_custom_title` | HIGH | none for rules (both ≥ 12) | – |
| D19 | Custom-level picker | `FT_FileOpenPicker` filtered by HFS type `LVLE` only | `aki` extension **or** `LVLE` | HIGH | modern files have no HFS type ⇒ use extension | – |
| D20 | Fullscreen | DrawSprocket (`SwitchRes`, `DSpContext_*`), menu bar shown while mouse y < 24 (`CustomGameScreen` tail) | `CGCaptureAllDisplays` + `CGDisplaySwitchToMode` 800×600, no menu-bar reveal (`ShowMenuBar` absent from the 1.2 dump) | HIGH | replica uses HectorKit scaling (design ruling) | – |
| D21 | Match sound | `PlaySound(0x46)` | `StopSound(0x50)` then `PlaySound(0x46)` (cuts a playing cancel sound) | HIGH | trivial | – |
| D22 | Update check / registration | Reggie version check, RT3 trial notices | Sparkle, RT3 | HIGH | out of scope | – |

## C. Not compared (say so)
Level Editor internals beyond D3 (grid, overlap, nudge, undo) were read in 1.2 only; 1.1 has the
same function set (`CreateTile`, `CheckNotOverlap`, `UndoLastLEMove`, …) but no line-by-line
comparison was done — NOT RESOLVED whether they differ. Statistics dialog: same nib labels
(Win/Loss, Gave Up, Best Time min./sec., Totals) in both `Aki.nib` files; control-ID loop compared
only superficially (1.1 loop bound 0x19d = 1.2's) — [MED] no delta. Map hover/preview animation:
not compared.
