# Aki — Mahjong Solitaire: RE bank index

## Provenance
| item | value |
|---|---|
| 1.2.0 binary | `Aki 1.2 UB/Aki.app/Contents/MacOS/Aki` (fat ppc+i386, `lipo -info`) → i386 slice `ghidra/Aki12_i386` (sha256 d8c8acbc…dcda) |
| 1.2.0 dump | `ghidra/Aki12_i386.decompiled.c`, Ghidra 12.1.3 headless + `DumpDecompile.java` (recipe `ghidra/README.md`). `ghidra/analyze-Aki12_i386.log`: "DumpDecompile: wrote **566/842** functions" — **276 functions produced no block** (import stubs and a few small ObjC methods; where those mattered they were read with `otool -tV -p`). `grep -c '^// ==== FUN_'` → **28** unnamed blocks (18 import thunks in `__jump_table`, 7 RT3 accessors, 3 list helpers). 77 ObjC methods in `nm`. ⚑ 2026-10-08: lost with its worktree, regenerated (`wrote 566/842` again) and **committed** as `ghidra/aki/Aki12_i386.decompiled.c` (+ binary, log). |
| 1.1.0 binary | `/Users/andiyar/Developer/Ambrosia/ghidra/Aki_ppc` (thin PPC Mach-O, Carbon C++; sha256 c53f581c…6366 = the 1.1.0 bundle executable) |
| 1.1.0 dump | `/Users/andiyar/Developer/Ambrosia/ghidra/Aki_ppc.decompiled.c`; its log `analyze-aki.log`: "wrote **3503/4214** functions"; 217 `halt_baddata` blocks at 0xcf8c4..0x1041dc are mis-decoded `[clone .eh]` tables (e.g. the second `Layout1` @ 0xd0274). PPC decompile drops the 3rd argument of `AddTile` (r7) — recovered by emulation (`tools/diff_layouts.py`). ⚑ 2026-10-08: committed copy `ghidra/aki/Aki_ppc.decompiled.c` (+ `Aki_ppc`, `analyze-aki.log`). |
| 1.1.0 evidence class | ⚑ corrected (review 2026-10-03): the 1.1 (PPC) rows rest on the Ghidra decompile **plus** the reviewer's independent listing-decoder trace of `Layout1`/`Layout3`/`Layout7` (scratchpad `ppcdis.py`). There is no raw-disassembly oracle for this binary on this machine: `otool -tV` and `objdump` both refuse `Aki_ppc` ("symbol table extends beyond the end of the file" / obsolete load command), so `ghidra/README.md`'s `otool -tV <thin-mach-o>` does not apply to it. 1.1 HIGH labels (delta A5–A16) stand on the decompile, re-read by the reviewer. |
| constants | `python3 ghidra/read_const.py ghidra/Aki12_i386` (13 doubles, 9 floats) and `… Aki_ppc` (62 doubles, 26 floats); outputs quoted where used |
| bundle / data | 1.2 `Resources/` (50 PNG, 15 audio, nibs, strings, Handbook PDF); 36 level files in `Aki Custom Level Pack 1/`; 1.1 `.rsrc` (82 PICT) |
| method | code reading only; **nothing is behaviour-verified** (owner's eyes are the gate) |

## Files
| file | sections | labels present |
|---|---|---|
| `rules.md` | 0 constants · 1 board model/tile record · 2 visibility · 3 open test · 4 tile set & match · 5 deal/shuffle · 6 open-pair count · 7 select/hit test · 8 pair removal & stacked loss · 9 hint · 10 time/bonus/penalties/difficulty map/time bar · 11 no-more-pairs · 12 undo · 13 pause · 14 end of level & give up · 15 what does not exist | HIGH, MED, NOT RESOLVED |
| `levels.md` | 1 level→function map · 2 1.1↔1.2 layout diff (tool output) · 3 levels 13–17 · 4 progression/unlock/map · 5 difficulty↔level · 6 Replay / Play Custom / Try This Level · 7 open items | HIGH, MED, NOT RESOLVED |
| `levels-layouts.md` | generated (x, y, L) tables for all 12 layouts, 1728 tuples, per-layout offsets/background/layer counts | HIGH |
| `file-formats.md` | 1 `.aki` (identity, byte table + xxd example, pack census, validation, editor grid) · 2 1.2 prefs (`GameSettings` 143-byte blob, stats dialog IDs, 1.1 migration) · 3 1.1 `Aki Prefs` · 4 other artefacts | HIGH, MED, LOW, NOT RESOLVED |
| `method-map-1.2.md` | 1 every ObjC class/method · 2 C helper families (screens, logic, drawing, editor, dialogs, graphics, sound/music, prefs) · 3 out of scope · 4 menu tags · 5 screen state machine · 6 `_g` field table | HIGH (default), MED, LOW |
| `delta-1.1-vs-1.2.md` | A 29 "compared, identical" rows · B 22 delta rows (D1–D22) with arbitration flags · C not compared | HIGH, MED, NOT RESOLVED |
| `assets-census.md` | 1 PNGs with sizes and code-side layout · 2 audio with ids · 3 strings/nibs/docs · 4 1.1 PICT census | HIGH, MED, LOW |
| `tools/diff_layouts.py` | 1.2 parser + 1.1 PPC emulator, diff table, `--markdown` regenerates `levels-layouts.md` | — |
| `tools/rsrc_census.py` | classic resource-fork parser (type/id/size census) | — |
| `REPORT-implementer.md` | implementer report (saved by the orchestrator from the hand-back) | — |

## Headline findings

- **Ruling 2026-10-03 (Ben): 1.2.0 is the replica target.** All 1.1↔1.2 deltas resolve to 1.2 (see `delta-1.1-vs-1.2.md` header).
1. All 12 layouts are byte-for-byte the same in 1.1.0 and 1.2.0 (incl. order and layers); 144 tiles each.
2. "Levels 13–17" are not layouts: they are five random backgrounds/titles for user `.aki` levels.
3. Difficulty 0 = Hard, 1 = Medium, 2 = Easy, 3 = Practice; Undo exists only in Easy/Practice.
4. All eight season tiles (ids 205–212) match each other.
5. Visibility tests only the layer directly above; open = free left or right side at ±1 tile.
6. Rule deltas 1.1→1.2 are confined to UX plumbing (Esc/quit confirmation, practice alert, editor
   exit, focus-loss pause, prefs storage); the core rules and constants are identical.

## NOT RESOLVED (consolidated)
1. Time bar visuals: which pixels are the "black" vs "grey overtime" stones the Handbook describes
   (`plate.png`/`misc.png` not decoded) — `rules.md` §10.
2. Whether 1.1's PICT backgrounds 140–151 (assigned out of order by `LayoutN`) show the same
   pictures as 1.2's `backgroundN.png` for the same level — `levels.md` §7, delta D17.
3. Purpose of `_g`+0xc4 (init 0x2a30, decremented by elapsed·60, never read for rules) — method-map §6.
4. Purpose of `_p`+0x000..0x1ff (two 256-byte areas, cleared, never read) — file-formats §3.
5. Meaning of `_p`+0x210 bit 0 (preserved by `save:`, never set) — file-formats §2.2.
6. `StringToNumber` (Matt Slot toolkit, stub only) on malformed `.aki` fields; behaviour on short
   files — file-formats §1.3.
7. No real `GameSettings` blob or 1.1 `Aki Prefs` file available for a worked example.
8. Level Editor internals 1.1 vs 1.2 not compared line by line; map hover animation not compared —
   delta §C.
9. Which face id is which suit/picture (needs a look at `tile_pictures.png`; only the season group
   205–212 is fixed by code) — rules §4.1.
10. `_enterFullscreen` bits-per-pixel argument to `CGDisplayBestModeForParameters`.
11. Meaning of FT error codes −7209 / −7203 beyond the dialogs they trigger.
12. Whether Preferences opened in fullscreen pauses the game (the fullscreen branch of
    `showPreferences:` lost its message arguments in the decompile).
13. Purpose of the 30 unreferenced small PICTs in the 1.1 resource fork; `layer_buttons.png` cell grid.
14. Stats window: which on-screen column each control ID feeds (nib layout not mapped).

## Append rule
New findings go into the topical file they belong to (create a new topical file rather than let one
exceed ~600 lines) **plus one line here** (in "Files" if a new file, otherwise under a dated
"Addenda" heading). Never fold findings into a monolith; never edit a claim's label without saying
what new evidence changed it.

## Review ledger
**2026-10-03** — Fable review, verdict **ACCEPT_WITH_FIXES** (8 findings, all Minor); full text in
`REVIEW-2026-10-03.md`. Fix pass applied the same day; each fix carries `⚑ corrected (review 2026-10-03)`.
1. D2 quit-in-custom-level write: idx 12/14/16 hit high halves (+65536 s), 13/15 low halves (+1 s) — landed in `delta-1.1-vs-1.2.md` §B D2.
2. Mismatch `break`: a lower open tile overlapping the point can still match/mismatch the kept selection — landed in `rules.md` §7.
3. Win transition runs in the same `_CustomGameScreen` call; "next tick" only for stacked/time-out — landed in `rules.md` §14.
4. Cross-references §5 → §8 step 7 and §8 step 8 → §14 — landed in `rules.md` §5 and §8.
5. `showPreferences:` fullscreen branch flagged NOT RESOLVED (#12) — landed in `method-map-1.2.md` §1.
6. "verified identical" → "identical by code comparison" — landed in `levels-layouts.md` line 1.
7. 1.1 evidence class stated (decompile + reviewer PPC listing-decoder trace; `otool -tV` fails on `Aki_ppc`) — landed in `INDEX.md` Provenance.
8. D5 1.1 `1 < diff` guard marked not re-verified (LOW) — landed in `delta-1.1-vs-1.2.md` §B D5.

- **Phase 0 data census (machine-generated, 2026-10-03):** `data-census.md` — every 1.1.0 PICT (82), 1.2.0 PNG (50) and audio file decoded/opened through HectorKit; numbers are tool output.
