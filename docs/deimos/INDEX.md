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
311/609 unions were not re-run. ⚑ wave 1 (2026-10-03): the hand table is now **509 rows = 308
HIGH / 187 MED / 14 LOW** (+216 rows, 56 corrected; function-roles.md header); unions still not
re-run. ⚑ corrected (review wave 1, 2026-10-03): after the review-wave-1 fix pass the hand table is **510 rows = 240 HIGH /
256 MED / 14 LOW** (68 HIGH → MED by the label audit, +1 MED row; function-roles.md header).
⚑ wave 2 (2026-10-03): the hand table is now **678 rows = 392 HIGH / 271 MED / 15 LOW** (+168
rows, 96 corrected; 36 proposed-HIGH rows lowered to MED by the label rule; function-roles.md
header); unions still not re-run.

## Topical files
| file | lines | sections | labels present (`grep -o '\[HIGH'` etc.: H/M/L) |
|---|---|---|---|
| `pak-format.md` | 342 | 1 ZIP (stored only) reader + byte tables + worked xxd decode; 2 entry naming, suffix→type table, tag index build, entry reading; 3 text de-obfuscation `~rotl4`; 4 census of ` Data/`; 5 first-20 listing per pak | 13/5/2 |
| `data-tags.md` | 188 | 1 `#key <value>` token grammar + readers; 2 `stli` string lists; 3 `flli` 220 positional floats + accessor; 4 `idli`/`reli`/`coli` permanent lists (RECT text order); 5 `tefo` text formats + font glyph order; 6 weapon-def key table | 12/6/1 |
| `sprite-sound-containers.md` | 236 | 1 QuickTime image import; 2 `im08` sprite plates (IC/IA pairing, cell grid, frame rects, worked decode, census); 3 `im16` TGA + media mask; 4 sound effects AIFC ima4; 5 music streaming; 6 fonts | 17/6/0 |
| `engine-loop.md` | 326 | 1 binary identity; 2 application flow; 3 game loop; 4 frame cadence (TickCount limiter, speed divider, keys); 5 screen layout, scroll, spawn row, render layers; 6 level order table; 7 film (replay) format; 8 InputSprocket input; 9 RNG; 10 prefs + high scores | 31/8/2 |
| `waves-and-enemies.md` | 369 | 1 level files + placement census; 2 unit definitions (states, spawn sets, rules, key→offset tables); 3 entity update + 17 rule conditions + shield scaling; 4 worked "wave" (controller unit) + group spawning; 5 player defs; 6 weapons; 7 scoring; 8 NOT RESOLVED | 21/8/0 |
| `function-roles.md` | 461 | 1 hand role table (279 rows, per-row label); 2 data-key consumer list (93); 3 module spans (424) | per row: 130/138/11 |
| `units-movement.md` | 552 | 1 per-tick motion order; 2 coordinates, px/tick, compass heading, trig tables; 3 entity motion fields; 4 velocity set-up on state entry; 5 motion controller + nearest player, seek, hold, reverse, cyclic, ramp, constrain, range; 6 flee targets; 7 culling/on-screen; 8 animation + turning; 9 spawn-set emitter; 10 function census; worked Shuriken | 50/6/0 |
| `spawn-and-waves.md` | 573 | 1 spawn request, entity group/PERM, pool; 2 spawn sets (record, state-entry arming, per-tick executor `FUN_10015b40`, rotation gate, positions, key→behaviour); 3 request→group→members, creation order, initial motion, cyclic start; 4 owner lock/link/orbit; 5 removal, children, PERM; 6 rule callees; 7 `FUN_10036cf0` = collision; 8 remaining range; 9 RNG draw order; worked `07s1` | 27/10/0 |
| `weapons-projectiles.md` | 484 | 1 `wede` loader + key→offset table; 2 weapon handler struct, per-tick order, fire rate/switching, air power-up/overload, overload penalty, bombs, crosshair; 3 spawn request, launchers, RNG; 4 pickups; 5 other functions; worked example | 43/5/0 |
| `damage-health-death.md` | 504 | 0 constants; 1 math/collision module; 2 collision tests (circle, boxes, player↔entity, entity↔obstacle, entity↔entity, hittable flag); 3 entity shields + damage; 4 destruction, media gate, deletion sweep; 5 player shields, hit, death; 6 pickups; worked example | 23/14/1 |
| `player-physics.md` | 478 | 1 player object (0x36c); 2 movement (velocity, integration, clamp, banking, view shift, crosshair); 3 hits; 4 life states, respawn, level start, appear fade, invulnerability; 5 death (player side); 6 defence bonus, overload warnings; 7 setup/lives/money/score; 8 two-player differences; 9 integrity check; worked "hold up"; `plde` key→offset table | 25/7/0 |
| `scoring-bonuses.md` | 512 | 1 player scoring fields + game struct; 2 obfuscation transforms; 3 add score + extra lives; 4 multiplier; 5 money, pickups; 6 end-of-level sequence (defence bonus, ground accuracy, tier, tally, coin bonus); 7 random-bonus selection; 8 finale; 9 high scores + start-sector rules; 10 level selection (starting bonus = unimplemented); 11 scoring cheats; worked example | 53/17/1 |
| `unit-def-struct.md` | 632 | 1 lifecycle + functions; 2 parse semantics/defaults; 3 unit struct (0x7a60); 4 state struct (0x5e0); 5 rule struct (0x88); 6 spawn-set record (0x5c); 7 sizes/maxima; 8 Units Cache format; 9 `plde` struct (0x108, 57 keys); 10 reconciliation; worked `03p1` | 27/3/1 |
| `bosses.md` | 369 | 1 no boss code (negative evidence); 2 scroll-pause gate + level-end = scroll distance; 3 rule conditions, state timer/OnCounter, spawn sets, damage/layers, parts; 4 per-sector end set pieces; 5 composite boss units; worked sector 1 (`le07`) | 20/2/0 |
| `level-scroll-objects.md` | 482 | 1 scroll state; 2 level start, initial window 3120, initial spawn pass; 3 per-tick scroll, spawn row, level end; 4 scroll pause/resume; 5 horizontal shift; 6 `leve` → pending list → spawn at row → request; 7 coordinate frames; 8 session + level progression; 9 G_Background proper; worked `le01` | 56/9/0 |
| `sprite-geometry-draw.md` | 509 | 0 constants; 1 frame lookup + dimensions, `kU_Sprite_MaxDimensions` 300×256; 2 entity geometry fields + half-size refresh + scale; 3 draw command, draw entry, centre anchor, collision box vs drawn rect; 4 visibility → alpha, tint, hit glow, scale; 5 shadows (layers 2/4/6, offsets, darkness); 6 render layers and order; worked example (wave 2) | 26/1/0 |
| `particles-debris-blur.md` | 418 | 1 RNG draws in scope, in order (302 init draws, per-particle `R(0,4)`); 2 particles (lifecycle, emit request, burst types, group/particle structs, velocity tables, emitters, colour, update, draw); 3 debris = ground-obstacle rects; 4 motion blur (pool, emit/update/draw, data); 5 feedback into gameplay; worked `psbu` (wave 2) | 21/3/1 |
| `timing-frame.md` | 415 | 1 frame-controller object (0x38 B); 2 one loop pass (begin frame, game-loop body, end-frame arithmetic, Esc 16 frames, FPS monitor); 3 speed divider never set (#12); 4 ticks per second, no catch-up; 5 interlacing + auto-interlace; 6 timing prefs + DITL 190 labels + console gate; 7 film replay per tick; worked 10 s of play (wave 2) | 34/2/0 |
| `hud-scorebar.md` | 367 | 1 coordinate frames (back buffer vs screen, +32); 2 score-bar state; 3 per-tick update; 4 draw; 5 meter fill arithmetic; 6 weapon icons + handler `+0x08`; 7 level start + init; 8 two-player / solo layout; 9 text formats (54) + text renderer, CEBU/CEGA; worked example (wave 2) | 55/7/0 |
| `messages-notices-console.md` | 441 | 1 modules, lifecycle, timebases; 2 message queue (record, post, aging, draw, posters); 3 GameString call sites; 4 notices (state, post, tick, who posts); 5 console (open/type/execute, registration gate — 10 live commands, cheat word, cheat handlers, raw handler range); 6 replica checklist; worked extra life (wave 2) | 19/5/0 |
| `loose-ends-combat.md` | 557 | 0 constants; 1 trig + heading convention settled; 2 game flag `+0x39` = level end reached; 3 pickups + player `+0xce/+0xcf`; 4 removal bookkeeping (double `FUN_10036120`, `+0x13c..e`, `+0xd8` owner); 5 spawn geometry (−32 shift, orbit/lock/link); 6 weapon handler + crosshair; 7 accessors (`FUN_10017150` ruling, closest player); worked example (wave 2) | 37/2/0 |
| `loose-ends-session.md` | 468 | 1 `plde` fly-in keys unread; 2 session results + post-game gates, quit flag; 3 high-score insertion + name entry; 4 game over + lives gate; 5 all-levels finale sequence; 6 screen transitions (fades); 7 film end to end; 8 miscellany (ExitToShell, `FUN_10000fd0` non-fatal, Local overrides, `+0x39` writers); worked two-player table (wave 2) | 25/4/0 |
| `sound-music.md` | 521 | 1 architecture; 2 sound effects (load, conversion, play parameters, is-playing); 3 voice list (16 voices, priority, stealing, mixing); 4 master/device volume + prefs + keys; 5 state sounds; 6 music (level/fade arithmetic, streaming, when, pause); 7 `gaso` call sites; 8 audible vs implementation detail; worked Ion Cannon (wave 2) | 40/3/0 |
| `front-end.md` | 528 | 1 front-end state; 2 main menu (buttons, layout, idle, event pump, dispatch, actions, keys); 3 start/return flow; 4 scores + name entry; 5 fades, advert, sounds; 6 credits; 7 level select (front view) + video grid; 8 pause; 9 loading lines; 10 census; worked cold start (wave 2) | 31/2/0 |
Label counts per file: `cd docs/deimos; for f in *.md; do grep -o '\[HIGH' $f | wc -l; …` (counts the
first label of each bracket; compound brackets such as "[HIGH for X; MED for Y]" count once).
Line and label counts in this table are as of the implementer session; the 2026-10-03 fix pass
added text to every topical file (see Review ledger). The nine wave-1 rows were counted on
2026-10-03 (`wc -l`; `grep -o '\[HIGH' f | wc -l` etc.) at commit a57c0fd; the review-wave-1 fix
pass then lowered role-row/table labels (`… | MED | … ⚑ label audit`) and added text, so those
per-file counts are pre-fix-pass. The nine wave-2 rows (marked "(wave 2)") were counted on
2026-10-03 at commit c79d5e2 (same commands), before their Fable review; function-roles.md is
now 969 lines.

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
  ⚑ corrected (wave 2, 2026-10-03): only FPS, VERSION/VERS, SUPERMUNKI and the cheats LIFE,
  ACCURACY, FUNDS, SCORE, SHIELDS, MULT are registered in 1.0.6; every other command is gated out
  by `FUN_1002d080`'s debugOnly flag and is unreachable. Cheat word = `supermunki`
  (messages-notices-console.md §5.2–§5.3).

## NOT RESOLVED (consolidated)
Pak / data
1. Local-folder scan handlers (15-way jump table at `0x100e2db4`, Ghidra could not recover it).
2. ~~Override precedence between `Data:Local` files and pak entries (`FUN_10004300`/`FUN_100043c0`).
   Also decides the weapon cycle order after overrides (weapons-projectiles.md NR 8). (wave 1)~~ →
   ⚑ closed (wave 2, 2026-10-03) → loose-ends-session.md §8.7: each Local record removes every non-Local record
   with the same (type, ID); pak duplicates are both kept and the first in list order wins;
   weapon cycle order = pak order in 1.0.6 (HIGH for the override logic; the "Local first"
   insertion order stays tied to #1, MED).
3. Minimum tag count `_DAT_100e00ec` for "Tag Index Incomplete! Aborting." ⚑ narrowed (wave 2,
   2026-10-03): the alert is non-fatal (`FUN_10000fd0` → `FUN_1000ced0(…, 0)` returns), so the
   game continues after it unless the alert routine `FUN_10045ab0` itself quits
   (loose-ends-session.md §8.2, NR 2). Threshold still open.
4. ~~Whether loaders abort when the token parse-error flag (`DAT_100e01e1`) is set. ⚑ narrowed
   (wave 1, 2026-10-03): for `unde`/`plde` a missing/malformed non-string key in strict mode ⇒
   fatal "Error" alert + shutdown sequence; missing string keys are silent (unit-def-struct.md
   §2.1–2.2). Open: whether `FUN_10000630` exits (unit-def-struct.md NR 3) and other loaders.~~ →
   ⚑ closed (wave 2, 2026-10-03) (remaining part) → loose-ends-session.md §8.2: `FUN_10000630` ends in
   `FUN_10048480` → ExitToShell, so a fatal unit/plde parse error quits after the alert.
5. ~~`tefo` `#Format_ID` numeric values "3"/"4": whether they match (`FUN_10014060` unread).~~ →
   hud-scorebar.md §9: `<3>` = CEBU, `<4>` = CEGA (strtok NUL + 4-byte copy + strcmp; MED). ⚑ closed (wave 2, 2026-10-03)
6. Space-character advance in sprite text (`FUN_1000ebd0` float branch). ⚑ narrowed (wave 2,
   2026-10-03): at scale 1.0 the size comes from the per-ASCII cache `*(0x100df024)`
   (`FUN_1000ed10`, 128 × 8 B); its filler is unread (hud-scorebar.md §9, NR 6).
7. ~~`plde` parser key→offset table (`FUN_10039e70`, reader form not matched by the tool).~~ →
   unit-def-struct.md §9 (all 0x108 bytes, 57 keys; HIGH) = player-physics.md role-row table. ⚑ closed (wave 1, 2026-10-03)
Graphics / sound
8. ~~`kU_Sprite_MaxDimensions` values (`_DAT_100df180`).~~ → sprite-geometry-draw.md §1.1:
   width 300, height 256, inclusive (asserts in `FUN_10018d20`/`FUN_1001a2a0`); shipped maxima
   218 × 110 (HIGH). ⚑ closed (wave 2, 2026-10-03)
9. ~~Alpha blending semantics and the frame encoder (`U_SpriteBlit.cc`, `FUN_1001d780`).~~
   Resolved in the fix pass → sprite-sound-containers.md §2.3a (transparency = red 5-bit channel
   of the alpha plate, 0 opaque … 31/key transparent, blend `(dst·a+src·(32−a))/32`). Still open:
   the writer of the alpha on/off global `DAT_100e0181`. ⚑ corrected (review 2026-10-03)
   ⚑ narrowed (wave 2, 2026-10-03): `DAT_100e0181` starts at 1 (image); the sibling switches are
   `DAT_100e0172` (setter `FUN_1001a290`) and `DAT_100e0171` (queue effects); writers still open
   (sprite-geometry-draw.md §4.4, NR 3).
10. QuickTime's TGA row orientation as seen by the media-mask lookup (assumed row 0 = top).
11. ~~Playback parameters of `FUN_10047670`/`FUN_10047bf0` (volume/pitch/priority semantics).~~ →
    sound-music.md §2.3 (`(id, priority ≤ 100, volume → 128·v/100, allowMultiple)`, pitch 16.16 =
    speed 1/p, no pan/loop) and §3 (priority = rank in a 16-voice list, 8 audible). ⚑ closed (wave 2, 2026-10-03)
    Residual: pitch direction by ear (#49).
Engine
12. ~~Game-speed divider values per "Game Speed …" label (writer of frame-controller `+0x2c`).~~ →
    timing-frame.md §3: no code writes the divider; the game always runs at Normal (1 tick per
    frame); GameStrings 24–30 and 19/20 have no consumer (also messages-notices-console.md §3).
    ⚑ closed (wave 2, 2026-10-03)
13. Dialog labels of byte prefs 4/7/8 and int prefs 0/1 (resource-fork DITL not parsed), and
    ≈0x1000 bytes of the 0x34f0 prefs block (key/ISp config?; `FUN_100050f0` defaults unread).
    ⚑ narrowed (wave 2, 2026-10-03): DITL 190 parsed — byte 4 "Full Screen (Takes Effect on
    Relaunch)", 5 "Interlacing", 7 "Bypass System Volume", 8 "ESC Key Delay"; int 0/1 = Sound/Music
    Volume (defaults 50/100); `FUN_100050f0` read (key table at +0x14b8) (timing-frame.md §6,
    sound-music.md §4.2); byte 9 = FPS counter, byte 11 = cheats enabled
    (messages-notices-console.md §5). Still open: int pref 2 (= 50, no reader found) and the rest
    of the ≈0x1000-byte block.
14. OS X keyboard/HID control path and the default key table (`M_ControlsConfigure.cc`,
    `M_HIDConfigure.cc`, `STR#` 130). ⚑ narrowed (wave 2, 2026-10-03): the default key codes
    (2 players × 7) written by `FUN_100050f0` are listed in timing-frame.md §6; consumer not found.
15. ~~ISp y-axis polarity (which input byte is "up").~~ → engine-loop.md §8: [0]=up, [2]=down
    (HIGH, `FUN_10028170` disassembly). ⚑ corrected (review 2026-10-03) #5
16. ~~`srand` argument at game start.~~ → engine-loop.md §9: `srand(TickCount())`, same value =
    film seed (HIGH, disassembly `100057c8`). ⚑ corrected (review 2026-10-03) #3
17. ~~Initial scroll top (3120 inferred) and the horizontal-shift driver (`FUN_100100b0` caller).~~
    → level-scroll-objects.md §2 (top 3120, HIGH) and §5 (driven by the active players'
    left/right input, ±1 px, clamp [−32, 31]; HIGH), player-physics.md §2.5. ⚑ closed (wave 1, 2026-10-03)
18. ~~Film header `+4` source.~~ → engine-loop.md §7: decoded score + 0xb3ac2 (HIGH,
    `FUN_1002a3a0`). ⚑ corrected (review 2026-10-03) #4
Gameplay
19. ~~Movement executors (`FUN_10015930`, `FUN_10015280`, `FUN_10015b40`) and speed units.~~ →
    units-movement.md §1–§8 (animation step, motion controller, px/tick, compass heading; HIGH);
    `FUN_10015b40` is the spawn-set executor (spawn-and-waves.md §2.3). ⚑ closed (wave 1, 2026-10-03)
20. ~~Spawn-set executor `FUN_10036cf0` (rate/volley/delay/offset/absolute-coordinate semantics).~~
    → the executor is `FUN_10015b40` + arming `FUN_10017cb0`, every `stateSpawnSet*` key
    resolved: spawn-and-waves.md §2.2–§2.6 (HIGH), bosses.md §3.3; `FUN_10036cf0` is entity↔entity
    collision (damage-health-death.md §2.5). ⚑ closed (wave 1, 2026-10-03) Residual: −32 x shift for ground
    spawn-set children (bosses.md NR 4). ⚑ residual closed (wave 2, 2026-10-03): no −32 shift for
    spawn-set children; only `FUN_10035900` level objects (loose-ends-combat.md §5.1).
21. ~~Group member placement offsets (`x/yOffsetMin/Max`, `randomiseInitialLoc`).~~ →
    waves-and-enemies.md §4 "member placement" (`FUN_10037930`, HIGH). ⚑ corrected (review 2026-10-03) #2
22. ~~Rule callees `FUN_10034ee0` (tracking), `FUN_10035070` (active), `FUN_10017ef0` (range).~~
    → spawn-and-waves.md §6 (HIGH), units-movement.md §5.8. ⚑ closed (wave 1, 2026-10-03)
    ~~Direction of rule conditions 15/16~~ → waves-and-enemies.md §3: #15 `count < range`, #16
    `count > range` (HIGH). ⚑ corrected (review 2026-10-03) #6
23. ~~`_DAT_100df43c` string in the state-timer step.~~ → `"none"` (no state change),
    waves-and-enemies.md §3 step 4. ⚑ corrected (review 2026-10-03) #7
24. ~~Collision shape test `FUN_10042f80`, entity damage `FUN_10014f10`, player hit `FUN_10026c90`.~~
    → damage-health-death.md §2.1 (`FUN_10042f80` = strict circle overlap), §3 (`FUN_10014f10`),
    §5.2 + player-physics.md §3 (the player hit is `FUN_10027100`; `FUN_10026c90` is the
    player-index getter). ⚑ closed (wave 1, 2026-10-03)
25. ~~Player physics/crosshair (`FUN_10028170`), weapon fire/power-up/overload logic (input →
    velocity now read, engine-loop.md §8; power-up/overload state machine `FUN_1003c0d0` and
    launch `FUN_1003c4f0` identified in function-roles.md §1, arithmetic not written up).~~ →
    player-physics.md §2, §3, §6.2 (HIGH); weapons-projectiles.md §2–§3 (fire, power-up,
    overload, bombs, launch; HIGH; crosshair position §2.8 MED). ⚑ closed (wave 1, 2026-10-03)
26. ~~Initial extra-life threshold/step; exact coin-bonus, ground-accuracy and defence-bonus
    arithmetic; random-bonus selection details.~~ → scoring-bonuses.md §3.1–3.2, §6.1–6.5, §7
    (HIGH); player-physics.md §6.1. ⚑ closed (wave 1, 2026-10-03)
27. ~~End-of-game finale (`EndGameFinale` sound, `Notice_AllLevelsCompleted`) sequencing.
    ⚑ narrowed (wave 1, 2026-10-03): finale condition (sector 12 ends a session started at sector
    1), notice, 1200-frame wait, mission bonus, game end, pref update traced (scoring-bonuses.md
    §8, level-scroll-objects.md §8); `EndGameFinale` has no code consumer. Open: the data-driven
    `noal`/`12gc` unit chain (scoring-bonuses.md NR 5).~~ →
    ⚑ closed (wave 2, 2026-10-03) → loose-ends-session.md §5: full `noal` → `12gc` → `miof` → Mission Iris chain with
    timings (`leen` played once by `noal` S4); no code plays gaso 6 `EndGameFinale`
    (sound-music.md §7). Residual ±1-tick items → #47.
28. ~~Starting bonus for a later start sector (`pgsl` lines 3 "- Starting Bonus $", 6 "- No
    Starting Bonus"; no literal consumer found) — function-roles.md §1 fix-pass notes. (added
    by the fix pass, review #9)~~ → scoring-bonuses.md §9.3, §10.3 (HIGH: unimplemented in 1.0.6;
    a later start sector gives 1 life, no high score/pref update/finale), player-physics.md §7,
    level-scroll-objects.md §8. ⚑ closed (wave 1, 2026-10-03)
Wave 1 additions (2026-10-03)
29. ~~Possible double bookkeeping: direct removers call `FUN_10036120` and the reaper
    `FUN_10036610` may call it again (kill count, coins) — spawn-and-waves.md NR 1.~~ →
    loose-ends-combat.md §4.1: real (no guard anywhere) but behaviour-neutral for 1.0.6 data;
    worst case under modding = orphaned members + pool leak. ⚑ closed (wave 2, 2026-10-03)
30. ~~Writer of game flag `+0x39` (`FUN_10005cf0`; suppresses overload warning, gates
    `canBeSpawnedOnlyWhenPlayersActive`) — weapons-projectiles.md NR 1.~~ → `+0x39` = level end
    reached: set `10006db4` (`FUN_10006b50`), cleared `10007248` (`FUN_10007170`) and
    `10005524`/`10005828` (session init); five gates (loose-ends-combat.md §2,
    loose-ends-session.md §8.8). ⚑ closed (wave 2, 2026-10-03)
31. Weapon-def keys with no consumer found (`numAmmoInPack`, `ammoWarnAtCount`, `shieldIncrease`,
    `livesIncrease`, `invulnerableForTime`, `maxAllowed`, …) — weapons-projectiles.md NR 3.
32. ~~Owner index `entity+0xd8` of enemy-spawned entities (do enemy-shot kills ever score?) —
    damage-health-death.md NR 2.~~ → loose-ends-combat.md §4.3: inherited along spawn chains;
    level-object/notice roots → 0xff, so enemy-shot kills never score. ⚑ closed (wave 2, 2026-10-03)
33. ~~RNG consumers not listing-walked (now noted in engine-loop.md §9): `FUN_100431f0` init draws
    (before/after `srand`?) and per-tick motion-blur draws — damage-health-death.md NR 7/8.
    ⚑ corrected (review wave 1, 2026-10-03): widened by the wave-1 critic — particle emitter `FUN_10043340` (callers
    `FUN_10014f10`, `FUN_10016300`, `FUN_10033850`), the motion-blur interval draw in
    `FUN_10033850`, init table `FUN_10044630`; all listed LOW in engine-loop.md §9 (wave 2).~~ →
    ⚑ closed (wave 2, 2026-10-03) → particles-debris-blur.md §1: `FUN_100431f0` makes 302 draws (300 in
    `FUN_10044630` + 2), all before any `srand` (no replay effect); `FUN_10043340` draws `R(0,4)`
    per particle inside the tick (replay-relevant); the motion-blur interval draw is real but
    every shipped blur state has 0/0, so it never draws. Residual: list append order (#38).
34. ~~B-side `passHitsToOwner` in `FUN_10036cf0` redirects to A's owner (original bug?) —
    bosses.md NR 3, damage-health-death.md NR 10.~~ → closed: player shots carry no owner, so
    the redirect never fires and turrets/bubbles absorb player shots on their own shields; only
    ramming reaches the owner (bosses.md §3.5, damage-health-death.md §2.5, spawn-and-waves.md §7;
    HIGH). ⚑ corrected (review wave 1, 2026-10-03) #I1
35. `invulnerableUntil…` unit keys appear inert (no consumer, MED) — bosses.md §3.5.
Wave 2 additions (2026-10-03)
36. Where the per-layer render lists of layers 2–15 are emptied each frame (`FUN_1001a650` clears
    only 0/1; xrefs to `_DAT_100df198`) — sprite-geometry-draw.md NR 2.
37. Scaled blitters (`FUN_1001c270` … `FUN_1001bfd0`) unread: sampling rule for scaled sprites —
    sprite-geometry-draw.md NR 6 (also hud-scorebar.md NR 2).
38. Whether `FUN_100009e0` appends at the list tail (dump says tail, MED; listing would settle it).
    It decides whether an entity spawned mid-update emits particles in the same tick (replay
    order) — particles-debris-blur.md NR 2, loose-ends-session.md role rows.
39. LCG state at the first app draw = image value 1 (assumes a pre-execution data image and no
    indirect `rand` before `FUN_100431f0`); affects only the particle direction table —
    particles-debris-blur.md NR 3.
40. Particle colour packing: whether the `unde` `RRGGBB` reader packs 8-bit channels into 555 by
    `>>3` — particles-debris-blur.md NR 1.
41. `hitParticleDoCircularBurst_BOOL` (+0x131) has no reader at the hit site (inert?) —
    particles-debris-blur.md NR 7.
42. Exact TickCount rate on the target OS / Ben's machine (60.15 Hz assumed → 30.07 vs 30.00
    ticks/s) — timing-frame.md NR 5 (a ruling/measurement for Ben).
43. Whether `tefo` `Loc_X/Y` are screen-absolute or game-area-relative (message x 30 vs the 32-px
    border) — messages-notices-console.md NR 2.
44. Mac OS X volume path: the volume keys skip the hardware call and the message under OS X;
    whether the replica reproduces the OS 9 messages is a ruling for Ben —
    messages-notices-console.md NR 6, sound-music.md §4.
45. MathLib `atan` last-ulp agreement for the 1° round-trip truncation set —
    loose-ends-combat.md NR 1.
46. Air launchers `FUN_1003c7a0`/`FUN_1003c940` copy req+0x28 from registers not traced (only the
    ground launcher known to change +0x28, MED) — loose-ends-combat.md NR 4.
47. Finale same-tick order (entity created in `FUN_10006b50` vs its first `FUN_10033850` update)
    and `aieg` group-delay meaning: ±1 tick in the finale timeline — loose-ends-session.md NR 3.
48. In-game route that sets the quit flag `DAT_100e01b8` (aevt/quit TVector, event code 8 of the
    unrecovered jump table at `0x10048fc8`) — loose-ends-session.md NR 1.
49. Pitch direction by ear: the code makes `pitch` a duration multiplier (speed 1/p) — Ben listens
    to `exsl` at 0.5 or `icbu` — sound-music.md NR 1.
50. `ampCmd` full scale on a sampled-sound channel (255 or 256): decides whether music at pref 100
    is −6 dB vs effects — sound-music.md NR 2.
51. Whether any shipped path plays a sound that was not preloaded (would trigger the wrong-sound
    path of §2.3 step 4; `FUN_1001f950(0,id,2)`) — sound-music.md NR 4.
52. Physical keys for menu volume charCodes 0x9D / 0x8A (Mac Roman `ù` / `ä`) —
    front-end.md NR 1.
53. Screen rect `+0x50..+0x5c` that suppresses menu hover (set in `FUN_1000ae20`) —
    front-end.md NR 2.
54. Music state after a demo/replay returns to the menu (`inmu` not restarted in modes 1/2?) —
    front-end.md NR 4.
55. Whether erasing high scores (Option+SCORES) is saved immediately (`FUN_10004ae0` writes the
    live prefs; prefs are written at quit by `FUN_100045f0`) — front-end.md NR 7.

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

**Wave 1 (2026-10-03) — RE-bank deepening, nine topical files** (`units-movement.md`,
`spawn-and-waves.md`, `weapons-projectiles.md`, `damage-health-death.md`, `player-physics.md`,
`scoring-bonuses.md`, `unit-def-struct.md`, `bosses.md`, `level-scroll-objects.md`; reader output at
a57c0fd). Synthesis merged 216 new + 56 corrected rows into function-roles.md §1 (open ⚑ conflicts:
`FUN_10017150`, `FUN_10034ce0`, `FUN_10010570`), closed NOT-RESOLVED #7, #17, #19, #20, #22, #24,
#25, #26, #28, narrowed #2, #4, #27, added #29–#35, and applied the named ⚑ conflict corrections
to waves-and-enemies.md and engine-loop.md (marked `⚑ corrected (wave 1, 2026-10-03)`).
**Verdict: ACCEPT_WITH_FIXES** — Fable review of commit a57c0fd (1 Important, 10 Minor; 170 HIGH
claims re-derived from listings/data: 166 confirmed / 4 wrong; full text
`docs/deimos/REVIEW-wave1-2026-10-03.md`; completeness critic `CRITIC-wave1-2026-10-03.md`;
fix-pass summary `FIXPASS-wave1-2026-10-03.md`). Every fix is marked inline with
`⚑ corrected (review wave 1, 2026-10-03) #n` (or `⚑ label audit (review wave 1)`).
| # | sev | finding | landed in |
|---|---|---|---|
| I1 | Imp | `passHitsToOwner`: player shots land on the turret's own shields (B-side redirect tests A's owner; player shots have none); only ramming passes to the owner | bosses.md header, §3.4, §3.5 row rewritten, §4 turret table (pllt/talt 3.0→8, tapt 3.0/3.4→8/9, tgtu 5.0→13, betu/fgnt 1.0→3, bubbles 0.0 swallow), §5 rows, worked example, NR 3 closed; damage-health-death.md §2.5 + NR 10; spawn-and-waves.md §7; function-roles.md `FUN_10036cf0`; NOT-RESOLVED #34 struck |
| M1 | Min | `+0xce` cleared in state 4 only (`1002a1a8 cmpwi r0,5; bge`) | damage-health-death.md §5.1 |
| M2 | Min | `bu01`: no per-kill coin (`destructCoin_ID none`); only the group-kill `cass` | bosses.md worked example |
| M3 | Min | level request template at `0x100eb41c` (r2+0x50ec), not `0x100eb420` | spawn-and-waves.md §1.1, §8 row |
| M4 | Min | range test precedes integration: y = −100 + 6(n−1); trigger at update 50, not 49 | units-movement.md worked example step 2 |
| M5 | Min | spawn executor runs for every cull survivor; `FUN_10017150` holds rotation (not firing); `FUN_10014f10` r4 unread | bosses.md §3.3, §3.4 |
| M6 | Min | player `+0xa0` = extra-life step increment; tick 9 = 275.00006 (float32) | player-physics.md §1 table, worked example |
| M7 | Min | scope census: scoring `FUN_10030570/5e0/640/790/7b0/7c0/870/910`, level `FUN_10011bf0`/`FUN_10011c00` | scoring-bonuses.md §10 table (8 "not re-read" rows); level-scroll-objects.md role rows + scope line; function-roles.md `FUN_10011bf0` (new MED row) |
| M8 | Min | label audit: HIGH rows backed by dump/read/strings only | 72 role rows + 34 body-table rows in the nine files and 68 rows in function-roles.md lowered to MED (`⚑ label audit`); 11 kept HIGH with a pointer to another file's listing; counts re-run (function-roles.md header, above) |
| M9 | Min | close scoring NR 3 (`'shie'`/`'spec'` both compared) and level-scroll NR 6 (`FUN_1003cdb0` not inverted) | scoring-bonuses.md §5.1, NR 3, `FUN_10037580` row → HIGH; level-scroll-objects.md NR 6; function-roles.md `FUN_10037580` |
| M10 | Min | `FUN_100146f0` draw order listing-confirmed (`100148dc`→`100149f0`→`10014b14`→`10014d74`→`10014d90`→`10014dc0`) | spawn-and-waves.md §3.2 step 6, §9 row → HIGH, NR 5 |
Also from the critic: the three open role conflicts (`FUN_10017150` rotation gate, `FUN_10034ce0(now,
id)`, `FUN_10010570` REVERSE) and `FUN_1003cf10` (unit-module init) were resolved against the
raw listing (`$W/disasm-fix.txt`) — function-roles.md rows, losing files corrected (damage §2.5,
spawn §5, bosses §2.4/role rows); engine-loop.md §9 gained the unread rand-consumer list (LOW).

**Wave 2 (2026-10-03) — RE-bank deepening, nine topical files, pending Fable review**
(`sprite-geometry-draw.md`, `particles-debris-blur.md`, `timing-frame.md`, `hud-scorebar.md`,
`messages-notices-console.md`, `loose-ends-combat.md`, `loose-ends-session.md`, `sound-music.md`,
`front-end.md`; reader output at c79d5e2). Synthesis merged 168 new + 96 corrected rows into
function-roles.md §1 (678 rows = 392/271/15; 36 proposed-HIGH rows lowered to MED by the label
rule — the owning files still print HIGH for them), closed NOT-RESOLVED #2, #4 (remaining part),
#5, #8, #11, #12, #27, #29, #30, #32, #33 and the #20 residual, narrowed #3, #6, #9, #13, #14, added
#36–#55, and applied the named ⚑ conflict corrections (marked `⚑ corrected (wave 2, 2026-10-03)`)
to engine-loop.md §3/§4/§5/§9 (incl. the prefs table the bank cites as §10), data-tags.md §4/§5, sprite-sound-containers.md §4,
pak-format.md §2.3, level-scroll-objects.md §8, spawn-and-waves.md §3.3/§9, player-physics.md
§2.6/§4.4, damage-health-death.md §1/NR 7–9, weapons-projectiles.md §2/§4/role row and scoring-bonuses.md
§11. Open ⚑ conflicts left in rows for the reviewer: `FUN_10009750` (signed vs unsigned compare),
`FUN_10029c00` (command name and label), `FUN_10030df0` (+4 "interlace" in front-end.md). Big
results: no speed setting exists; 30.07 ticks/s from the 2-tick limiter (`FPS_Delay`); only 10
console commands are live; game flag `+0x39` = level end reached; particle draws are in the replay
stream; M_Sound is a 16-voice software mixer. Wave-1 file-level NRs closed by wave 2 are listed in
each wave-2 file's "INDEX updates" section (not re-marked in the wave-1 files).
