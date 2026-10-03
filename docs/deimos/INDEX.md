# Deimos Rising 1.0.6 — RE bank index

Logic oracle for the Ambrosia Classics rebuild of Deimos Rising (Swoop Software / Ambrosia,
2001–2002). **Code readings only — nothing here is behaviour-verified.** Ben's eyes close the
honesty gates.

## Provenance
| item | value | how obtained |
|---|---|---|
| game folder (`$G`) | `/Users/andiyar/Developer/Ambrosia/Resources/ambrosia-extracted/Action-Adventure/DeimosRising/Deimos Rising 1.0.6 (volume)/Deimos Rising/` | given |
| binary | `$G/Deimos Rising`, data fork 2045976 B, PEF `Joy!peffpwpc`; resource fork 151602 B (xattr) | `ls -la@`, `xxd -l 16` |
| analysed copy | `ghidra/Deimos_pef`, md5 `3bc346259ee7a4f6287e027aeb7c2d0c` (= the game binary's md5) | `md5 -q` both |
| version | `vers` 1/2 = 1.0.6 final; log string build date "Jan  2 2004" | resource fork parse; `FUN_100000e0` |
| binary kind | classic (InterfaceLib, not CarbonLib) CFM PEF, 10 import libraries | PEF loader section (engine-loop.md §1) |
| dump | `ghidra/Deimos_pef.decompiled.c` (3070632 B) | Ghidra 12.1.3 headless, `ghidra/decompile.sh Deimos_pef -processor PowerPC:BE:32:default -cspec macosx` (recipe: `ghidra/README.md`) |
| language | `PowerPC:BE:32:default:macosx` — forced; auto-detect picks the wrong VLE language | `grep 'Using Language' ghidra/analyze-Deimos_pef.log` |
| function count | Ghidra log: **"wrote 2580/2588 functions"**; dump blocks `grep -c '^// ==== '` → **2580**; named `FUN_…` → **2133**; the rest are import glue (`.glue::Name`) and `entry` | tool output |
| address model | code `0x10000000` (910128 B), data `0x100de330` (pidata unpacked by Ghidra), TOC r2 = `0x100e6330` | `DumpMemory.java` log; disassembly of accessors |
| memory image | `tools/DumpMemory.java` → `<dir>/10000000.bin`, `100de330.bin`, `1011ef10.bin` (used to resolve strings/tables the decompile prints as raw hex) | headless post-script on the existing project |

Stripped binary: roles come from strings (assert texts carry source-file names such as
`G_Level.cc`), data-file keys, import call sites and link-order clustering. Function-role table
size: **279 hand-assigned roles (130 HIGH / 138 MED / 11 LOW) + 32 more data-key consumers =
311 functions with a specific role; 609 of the 2133 `FUN_` functions have a role or a source
module** (function-roles.md header, all from tool output). ⚑ corrected (review 2026-10-03): after the fix pass the
hand table is 293 rows = 119 HIGH / 163 MED / 11 LOW (19 downgrades, 14 added rows); the
311/609 unions were not re-run.

## Topical files
| file | lines | sections | labels present (`grep -o '\[HIGH'` etc.: H/M/L) |
|---|---|---|---|
| `pak-format.md` | 342 | 1 ZIP (stored only) reader + byte tables + worked xxd decode; 2 entry naming, suffix→type table, tag index build, entry reading; 3 text de-obfuscation `~rotl4`; 4 census of ` Data/`; 5 first-20 listing per pak | 13/5/2 |
| `data-tags.md` | 188 | 1 `#key <value>` token grammar + readers; 2 `stli` string lists; 3 `flli` 220 positional floats + accessor; 4 `idli`/`reli`/`coli` permanent lists (RECT text order); 5 `tefo` text formats + font glyph order; 6 weapon-def key table | 12/6/1 |
| `sprite-sound-containers.md` | 236 | 1 QuickTime image import; 2 `im08` sprite plates (IC/IA pairing, cell grid, frame rects, worked decode, census); 3 `im16` TGA + media mask; 4 sound effects AIFC ima4; 5 music streaming; 6 fonts | 17/6/0 |
| `engine-loop.md` | 326 | 1 binary identity; 2 application flow; 3 game loop; 4 frame cadence (TickCount limiter, speed divider, keys); 5 screen layout, scroll, spawn row, render layers; 6 level order table; 7 film (replay) format; 8 InputSprocket input; 9 RNG; 10 prefs + high scores | 31/8/2 |
| `waves-and-enemies.md` | 369 | 1 level files + placement census; 2 unit definitions (states, spawn sets, rules, key→offset tables); 3 entity update + 17 rule conditions + shield scaling; 4 worked "wave" (controller unit) + group spawning; 5 player defs; 6 weapons; 7 scoring; 8 NOT RESOLVED | 21/8/0 |
| `function-roles.md` | 461 | 1 hand role table (279 rows, per-row label); 2 data-key consumer list (93); 3 module spans (424) | per row: 130/138/11 |
Label counts per file: `cd docs/deimos; for f in *.md; do grep -o '\[HIGH' $f | wc -l; …` (counts the
first label of each bracket; compound brackets such as "[HIGH for X; MED for Y]" count once).
Line and label counts in this table are as of the implementer session; the 2026-10-03 fix pass
added text to every topical file (see Review ledger).

Tools (`docs/deimos/tools/`, all run in this session):
`list_paks.py` (pak census/listing/decode/audio/images), `StringXrefs.java` (Ghidra post-script:
string + call xrefs), `DumpMemory.java` (memory image), `DisasmFuncs.java` (raw PPC disassembly of
named functions), `func_profile.py` (per-function strings/imports/4CCs/module), `module_spans.py`
(link-order module attribution), `perm_consumers.py` (data-key consumers of the permanent-list
accessors), `key_offsets.py` (text-key → struct-offset tables from the parsers),
`plate_frames.py` (re-implementation of the sprite-plate scan for checking).
Headless form used: `analyzeHeadless <projdir> Deimos_pef -process Deimos_pef -noanalysis
-readOnly -scriptPath docs/deimos/tools -postScript <Script>.java <out> [args]` against a copy of
the project created by `decompile.sh`.

## Out of scope (identified only)
- Registration: `Register Deimos Rising` (separate PEF), `M_Registration.cc`
  (`FUN_10010cf0…10010f90`), unregistered time limit and 4-level demo set in `FUN_100051a0` /
  `FUN_10011b30`, `STR#` 900/901 shareware texts.
- Web/network: InternetConfig `ICLaunchURL` ("Visit the Deimos Rising Website Now?").
- Linked libraries: MSL C/C++ runtime, zlib inflate (unused by the STORED-only pak reader), IJG
  JPEG 6, an HTML renderer (tag parser strings, `index.iml`), SIOUX console, a GIF/PICT/sound
  helper layer at `0x100cc000–0x100d3530`.
- In-game level editor (`Editor[edit]` lists, `Editor Panel`/`Editor Background` TGAs,
  "WeaponEditor_PlayerImage" sprite) — editors come last by project ruling.
- `HID.bundle/libHIDUtilities.dylib` (Mach-O ppc, OS X gamepad helper).
- Debug console commands (SHADOWS, FPS, LIMITFPS, MEMORY, …) — the cheat subset is original
  player-facing behaviour (guide "Cheats"); the cheat word is stored obfuscated in the binary.

## NOT RESOLVED (consolidated)
Pak / data
1. Local-folder scan handlers (15-way jump table at `0x100e2db4`, Ghidra could not recover it).
2. Override precedence between `Data:Local` files and pak entries (`FUN_10004300`/`FUN_100043c0`).
3. Minimum tag count `_DAT_100e00ec` for "Tag Index Incomplete! Aborting."
4. Whether loaders abort when the token parse-error flag (`DAT_100e01e1`) is set.
5. `tefo` `#Format_ID` numeric values "3"/"4": whether they match (`FUN_10014060` unread).
6. Space-character advance in sprite text (`FUN_1000ebd0` float branch).
7. `plde` parser key→offset table (`FUN_10039e70`, reader form not matched by the tool).
Graphics / sound
8. `kU_Sprite_MaxDimensions` values (`_DAT_100df180`).
9. ~~Alpha blending semantics and the frame encoder (`U_SpriteBlit.cc`, `FUN_1001d780`).~~
   Resolved in the fix pass → sprite-sound-containers.md §2.3a (transparency = red 5-bit channel
   of the alpha plate, 0 opaque … 31/key transparent, blend `(dst·a+src·(32−a))/32`). Still open:
   the writer of the alpha on/off global `DAT_100e0181`. ⚑ corrected (review 2026-10-03)
10. QuickTime's TGA row orientation as seen by the media-mask lookup (assumed row 0 = top).
11. Playback parameters of `FUN_10047670`/`FUN_10047bf0` (volume/pitch/priority semantics).
Engine
12. Game-speed divider values per "Game Speed …" label (writer of frame-controller `+0x2c`).
13. Dialog labels of byte prefs 4/7/8 and int prefs 0/1 (resource-fork DITL not parsed), and
    ≈0x1000 bytes of the 0x34f0 prefs block (key/ISp config?; `FUN_100050f0` defaults unread).
14. OS X keyboard/HID control path and the default key table (`M_ControlsConfigure.cc`,
    `M_HIDConfigure.cc`, `STR#` 130).
15. ~~ISp y-axis polarity (which input byte is "up").~~ → engine-loop.md §8: [0]=up, [2]=down
    (HIGH, `FUN_10028170` disassembly). ⚑ corrected (review 2026-10-03) #5
16. ~~`srand` argument at game start.~~ → engine-loop.md §9: `srand(TickCount())`, same value =
    film seed (HIGH, disassembly `100057c8`). ⚑ corrected (review 2026-10-03) #3
17. Initial scroll top (3120 inferred) and the horizontal-shift driver (`FUN_100100b0` caller).
18. ~~Film header `+4` source.~~ → engine-loop.md §7: decoded score + 0xb3ac2 (HIGH,
    `FUN_1002a3a0`). ⚑ corrected (review 2026-10-03) #4
Gameplay
19. Movement executors (`FUN_10015930`, `FUN_10015280`, `FUN_10015b40`) and speed units.
20. Spawn-set executor `FUN_10036cf0` (rate/volley/delay/offset/absolute-coordinate semantics).
21. ~~Group member placement offsets (`x/yOffsetMin/Max`, `randomiseInitialLoc`).~~ →
    waves-and-enemies.md §4 "member placement" (`FUN_10037930`, HIGH). ⚑ corrected (review 2026-10-03) #2
22. Rule callees `FUN_10034ee0` (tracking), `FUN_10035070` (active), `FUN_10017ef0` (range).
    ~~Direction of rule conditions 15/16~~ → waves-and-enemies.md §3: #15 `count < range`, #16
    `count > range` (HIGH). ⚑ corrected (review 2026-10-03) #6
23. ~~`_DAT_100df43c` string in the state-timer step.~~ → `"none"` (no state change),
    waves-and-enemies.md §3 step 4. ⚑ corrected (review 2026-10-03) #7
24. Collision shape test `FUN_10042f80`, entity damage `FUN_10014f10`, player hit `FUN_10026c90`.
25. Player physics/crosshair (`FUN_10028170`), weapon fire/power-up/overload logic (input →
    velocity now read, engine-loop.md §8; power-up/overload state machine `FUN_1003c0d0` and
    launch `FUN_1003c4f0` identified in function-roles.md §1, arithmetic not written up).
26. Initial extra-life threshold/step; exact coin-bonus, ground-accuracy and defence-bonus
    arithmetic; random-bonus selection details.
27. End-of-game finale (`EndGameFinale` sound, `Notice_AllLevelsCompleted`) sequencing.
28. Starting bonus for a later start sector (`pgsl` lines 3 "- Starting Bonus $", 6 "- No
    Starting Bonus"; no literal consumer found) — function-roles.md §1 fix-pass notes. (added
    by the fix pass, review #9)

## Append rule
New findings append to the topical file they belong to (or a new topical file of ≤ ~600 lines)
plus one line in this index (table row or NOT-RESOLVED edit) — never a monolith. Every claim
keeps `name @ addr`, the quoted decompile lines, resolved constants with the command, and a
[HIGH]/[MED]/[LOW] label with its reason. Close a NOT-RESOLVED item by striking it here and
pointing to the file/section that resolves it.

## Review ledger
**2026-10-03 — Fable review, verdict ACCEPT_WITH_FIXES** (17 findings, 7 Important;
full text `docs/deimos/REVIEW-2026-10-03.md`; fix-pass summary `FIXPASS-2026-10-03.md`). Every
fix is marked inline with `⚑ corrected (review 2026-10-03)`.
| # | sev | finding | landed in |
|---|---|---|---|
| 1 | Imp | "37 functions call rand" wrong → 2 direct callers (int 20 / float 4 callers) | engine-loop.md §9 |
| 2 | Imp | float RandomRange `FUN_100465e0` missing; its 4 consumers; `FUN_10037930` placement read | engine-loop.md §9 (table), waves-and-enemies.md §4, function-roles.md §1; NOT-RESOLVED #21 struck |
| 3 | Imp | `srand(TickCount())` from disasm, = film seed (MED→HIGH) | engine-loop.md §3 skeleton + §9; #16 struck |
| 4 | Imp | film `+4` = decoded score + 0xb3ac2 (`FUN_1002a3a0`) | engine-loop.md §7; #18 struck |
| 5 | Imp | input bytes [0]=up [2]=down [3]=left [1]=right (LOW→HIGH) | engine-loop.md §8; #15 struck |
| 6 | Imp | rule 15 ≡ count < range, rule 16 ≡ count > range | waves-and-enemies.md §3; #22 part struck |
| 7 | Imp | `_DAT_100df43c` = "none" | waves-and-enemies.md §3 step 4 + §8 #5; #23 struck |
| 8 | Min | 19 HIGH rows on string/import evidence → MED | function-roles.md §1 rows + header counts |
| 9 | Min | heavy unmentioned functions; starting bonus uncovered | function-roles.md §1 (7 rows + notes; `COST` = draw type, not a cost), sprite-sound-containers.md §2.3a (alpha answered); NOT-RESOLVED #9 struck, #28 added |
| 10 | Min | caller counts 21/19 → 20/18 | pak-format.md §3, engine-loop.md §4 |
| 11 | Min | version needed 0x000A also on 1 file (`ammu`) | pak-format.md §1.3 |
| 12 | Min | `key_offsets.py` missed `s_` labels; fixed + re-run, delta pasted | tools/key_offsets.py, waves-and-enemies.md §2 |
| 13 | Min | "Most placed" skipped sess/sels/geys | waves-and-enemies.md §1 (retitled, 4 rows added) |
| 14 | Min | raw branch of `FUN_10029a10` writes the extra-life step | waves-and-enemies.md §7 |
| 15 | Min | import string literally `ICAp;InternetConfigLib` | engine-loop.md §1 |
| 16 | Min | `inte` = 27 CRs (28 lines incl. unterminated last) | data-tags.md §2 |
| 17 | Min | REPORT's flat "zlib never reached" vs bank MED | REPORT-implementer.md |
