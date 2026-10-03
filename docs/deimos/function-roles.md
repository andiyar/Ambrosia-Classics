# Deimos Rising 1.0.6 — function-role table (the bank's spine)

Stripped PEF: 2580 decompiled blocks, 2133 named `FUN_…` (INDEX provenance). Roles below come
from (a) hand reading (§1), (b) data-key consumption (`perm_consumers.py`, §2) and
(c) link-order module attribution (`module_spans.py`, §3). Labels: HIGH = read in code /
disassembly with the data path traced; MED = role from read code with one inferred link
(unnamed callee, usage pattern); LOW = caller context or name pattern only.

Counts (tool output, this session):
- §1 hand table: **293 functions — HIGH 119, MED 163, LOW 11** (count of `| `FUN_` rows by
  label) ⚑ corrected (review 2026-10-03): was 279 = 130/138/11; the fix pass downgraded 19 string/import-only HIGH rows to
  MED (#8), raised `FUN_1001d780` to HIGH, and added 14 rows (7 HIGH, 7 MED). The §2/§3/union
  counts below are from the original session and were not re-run.
- ⚑ wave 1 (2026-10-03): +216 rows, 56 corrected → §1 hand table: **509 functions — HIGH 308,
  MED 187, LOW 14** (`awk '/^## 1\./,/^## 2\./' function-roles.md | grep '^| \`FUN_'`, label =
  4th column, `sort | uniq -c`). Combined rows (`FUN_a` / `FUN_b`) count once; the undefined
  G_Background console-handler row is not a `FUN_` row and is not counted. §2/§3/union still not
  re-run.
- §2 data-key consumers: 93 functions, 61 of them also in §1 → 311 distinct functions with a
  specific role (`sort -u` of both name lists | `wc -l` → 311).
- §3 module attribution: 123 functions tagged by their own assert/source-file string + 301
  bracketed by same-module neighbours = 424 (`module_spans.py` output below).
- Union of §1–§3: **609 of the 2133 `FUN_` functions** carry a role or a module
  (`sort -u | grep -c FUN_` → 609). The remaining ~1524 are mostly runtime/library code
  above `0x1004b400` (MSL C/C++ runtime, zlib inflate, IJG JPEG, an HTML renderer, SIOUX, the
  sound and GIF/PICT helpers at `0x100cc000–0x100d3530`) and unattributed game helpers.

## 1. Hand-assigned roles

| function | module (assert string) | role | conf | evidence |
|---|---|---|---|---|
| `FUN_100000a0` |  | main body: boot, interface loop, shutdown | HIGH | 3 calls, read |
| `FUN_100000e0` |  | boot sequence: managers, pak index, prefs, input, permanent data, display, logos, loading screen | MED | strings "Loading Publisher Logo" etc. — ⚑ corrected (review 2026-10-03) #8: was HIGH on string/import/usage evidence only |
| `FUN_10000630` |  | shutdown sequence | MED | "Starting Shut Down Sequence" |
| `FUN_10048330` | M_Application.cpp | Toolbox init (InitGraf…InitCursor, Gestalt 'qtim') | MED | imports — ⚑ corrected (review 2026-10-03) #8: was HIGH on string/import/usage evidence only |
| `FUN_10049aa0` | M_Application.cpp | install AppleEvent handlers aevt/oapp/odoc/pdoc/quit | MED | 4CCs — ⚑ corrected (review 2026-10-03) #8: was HIGH on string/import/usage evidence only |
| `FUN_100491d0` | M_Application.cpp | menu bar setup | MED | sPriv_Menu_File |
| `FUN_10000e70` |  | assert: memory error | MED | "MEMORY ERROR" string — ⚑ corrected (review 2026-10-03) #8: was HIGH on string/import/usage evidence only |
| `FUN_10000ed0` |  | assert: tool error | MED | "TOOL ERROR" — ⚑ corrected (review 2026-10-03) #8: was HIGH on string/import/usage evidence only |
| `FUN_10000f30` |  | assert: file error | MED | "FILE ERROR" — ⚑ corrected (review 2026-10-03) #8: was HIGH on string/import/usage evidence only |
| `FUN_10000f80` |  | assert: data error | MED | "DATA ERROR" — ⚑ corrected (review 2026-10-03) #8: was HIGH on string/import/usage evidence only |
| `FUN_10000fd0` |  | fatal: critical files missing | MED | string — ⚑ corrected (review 2026-10-03) #8: was HIGH on string/import/usage evidence only |
| `FUN_10000910` | U_LinkedList.cc | linked list insert | MED | newLinkPtr |
| `FUN_100009e0` | U_LinkedList.cc | linked list append (node = prev,next,data); used as list add everywhere | HIGH | read + assert string — ⚑ corrected (wave 1, 2026-10-03): was "linked list append" MED; see level-scroll-objects.md role rows |
| `FUN_10000ce0` |  | list count | MED | usage pattern |
| `FUN_10000e10` |  | list iterate (cursor over prev,next,data nodes) | HIGH | read + assert string — ⚑ corrected (wave 1, 2026-10-03): was "list iterate (cursor)" MED; see level-scroll-objects.md role rows |
| `FUN_10000c00` | U_LinkedList.cc | unlink current node (cursor) | HIGH | read + assert string (level-scroll-objects.md role rows) |
| `FUN_1000cb60` | M_Memory.cc | allocate (NewPtr/NewPtrClear) with failure log | MED | imports + "MEMORY ALLOCATION FAILURE" — ⚑ corrected (review 2026-10-03) #8: was HIGH on string/import/usage evidence only |
| `FUN_1004d320` |  | operator new | MED | alloc + null asserts at callers |
| `FUN_1000cd60` |  | memcpy | MED | usage |
| `FUN_1000cd90` |  | memset 0 | MED | usage |
| `FUN_10057760` |  | strlen | MED | usage |
| `FUN_10057820` |  | strcmp | MED | returns 0 on equal at all sites |
| `FUN_10057a30` |  | strstr | MED | token locator |
| `FUN_100578f0` |  | strtok | MED | (NULL, delim) continuation calls |
| `FUN_10057660` |  | sscanf | MED | "%i"/"%f"/"%u" args |
| `FUN_10055390` |  | sprintf | MED | format args |
| `FUN_10057780` |  | strcpy | MED | usage |
| `FUN_10049550` |  | log printf | MED | all log strings |
| `FUN_100553e0` |  | rand (MSL LCG) | HIGH | read |
| `FUN_10055400` |  | srand | HIGH | read |
| `FUN_10046580` |  | RandomRange(min,max) inclusive | HIGH | read |
| `FUN_100465e0` |  | FloatRandomRange(lo,hi): lo==hi→lo (no draw), else min+(hi−lo)·rand()/32767.0f; 4 callers | HIGH | disasm (engine-loop.md §9) — ⚑ corrected (review 2026-10-03) #2: was missing |
| `FUN_10042920` | math module (span 0x10042100–0x100432d0; name not in binary) | build atan int[1024], sqrt float[16384], cos/sin float[360] tables (start-up) | HIGH | listing; caller `FUN_100000e0` (units-movement.md §2.3, damage-health-death.md §1) |
| `FUN_10042a90` | math module (span 0x10042100–0x100432d0; name not in binary) | free math tables | MED | decompile (damage-health-death.md §1) |
| `FUN_10042ad0` | math module (span 0x10042100–0x100432d0; name not in binary) | heading (compass int) from two int points | HIGH | listing (units-movement.md §2.2, damage-health-death.md §1) |
| `FUN_10042b30` | math module (span 0x10042100–0x100432d0; name not in binary) | heading → unit vector (x = sin h, y = cos h) | HIGH | listing (damage-health-death.md §1, units-movement.md §2.2) |
| `FUN_10042b80` | math module (span 0x10042100–0x100432d0; name not in binary) | vector = speed·(sin h, cos h) | HIGH | listing (units-movement.md §2.2, damage-health-death.md §1) |
| `FUN_10042bf0` | math module (span 0x10042100–0x100432d0; name not in binary) | normalise vector (x² computed as trunc(x)·x — quirk) | HIGH | listing `10042c1c–10042c44` (damage-health-death.md §1) |
| `FUN_10042c90` | math module (span 0x10042100–0x100432d0; name not in binary) | vector length (libm sqrt) | HIGH | listing (damage-health-death.md §1) |
| `FUN_10042cd0` | math module (span 0x10042100–0x100432d0; name not in binary) | heading of a float vector (libm atan, axis table) | MED | decompile (damage-health-death.md §1) |
| `FUN_10042e90` | math module (span 0x10042100–0x100432d0; name not in binary) | point distance sqrtI(trunc(dx²+dy²)) | HIGH | listing; callers `FUN_10034ee0`, `FUN_10035070`, `FUN_10033600` (damage-health-death.md §1) |
| `FUN_10042ee0` | math module (span 0x10042100–0x100432d0; name not in binary) | cos of int degrees (table, r2−0x6e30) | HIGH | listing (units-movement.md §2.3, damage-health-death.md §1) |
| `FUN_10042f00` | math module (span 0x10042100–0x100432d0; name not in binary) | sin of int degrees (table, r2−0x6e34) | HIGH | listing (units-movement.md §2.3, damage-health-death.md §1) |
| `FUN_10042f20` | math module (span 0x10042100–0x100432d0; name not in binary) | sqrtI(n): table if n < 16384 else libm | HIGH | listing (units-movement.md §2.3, damage-health-death.md §1) |
| `FUN_10042f80` | math module (span 0x10042100–0x100432d0; name not in binary) | circle overlap: sqrtI(trunc(dx²+dy²)) < rA + rB (strict) — the collision "shape test" (NOT a pixel/shape-mask test) | HIGH | listing `10042f9c–10043018`; callers `FUN_10033850`, `FUN_10036cf0` (damage-health-death.md §2.1) |
| `FUN_10043040` | math module (span 0x10042100–0x100432d0; name not in binary) | compass ↔ internal heading: 180 − h mod 360 | HIGH | listing (units-movement.md §2.2, damage-health-death.md §1) |
| `FUN_10043090` | math module (span 0x10042100–0x100432d0; name not in binary) | table-atan heading (a − 90 mod 360) | HIGH | listing (units-movement.md §2.2, damage-health-death.md §1) |
| `FUN_10046470` |  | text obfuscation ~rotl4 (involutive) | HIGH | read |
| `FUN_100463b0` |  | string toupper (ctype table) | MED | read |
| `FUN_10014060` |  | 4CC -> C string | MED | usage |
| `FUN_100140b0` |  | C string -> 4CC | MED | "G_GameObject_ConvertStringToID" string |
| `FUN_100497f0` |  | TickCount wrapper | HIGH | read |
| `FUN_10049150` |  | IsKeyDown(virtual key code): GetKeys+BitTst | HIGH | read |
| `FUN_10048ee0` |  | GetMouse wrapper | HIGH | read |
| `FUN_10048e60` |  | Button() wrapper | MED | import — ⚑ corrected (review 2026-10-03) #8: was HIGH on string/import/usage evidence only |
| `FUN_10048e30` |  | FlushEvents wrapper | MED | import — ⚑ corrected (review 2026-10-03) #8: was HIGH on string/import/usage evidence only |
| `FUN_10048a00` |  | read prefs file (FindFolder 'pref', HOpen, FSRead) | MED | imports — ⚑ corrected (review 2026-10-03) #8: was HIGH on string/import/usage evidence only |
| `FUN_10048ac0` |  | write prefs file "Deimos Rising Preferences" type pref creator Deim | MED | imports + string — ⚑ corrected (review 2026-10-03) #8: was HIGH on string/import/usage evidence only |
| `FUN_100015a0` |  | pak manager init, LOGTAGS command, data version check (pali) | MED | strings |
| `FUN_100016c0` | U_Pak.cc | build tag index (Local then Paks) | HIGH | read |
| `FUN_100021a0` | U_Pak.cc | parse entry name -> display, ID, type | HIGH | read |
| `FUN_10003a40` |  | tag ID between [ ] | HIGH | read |
| `FUN_10003b20` |  | suffix -> resource type (15 tables) | HIGH | read |
| `FUN_100040c0` |  | suffix is .zip/.pak | MED | strings — ⚑ corrected (review 2026-10-03) #8: was HIGH on string/import/usage evidence only |
| `FUN_10004230` |  | format "%s[%s].%s" | MED | string — ⚑ corrected (review 2026-10-03) #8: was HIGH on string/import/usage evidence only |
| `FUN_10001f20` |  | tag exists (type,id) | MED | callers |
| `FUN_10002850` | U_Pak.cc | load tag bytes (pointer) | MED | strings |
| `FUN_10002a20` | U_Pak.cc | load tag bytes (handle) | MED | used by image/sound loaders |
| `FUN_10002be0` | U_Pak.cc | n-th tag of a type | MED | level enumeration |
| `FUN_10002080` |  | tag -> zip path + byte range | MED | music streaming |
| `FUN_10002340` |  | n-th tag of type with name | MED | film enumeration |
| `FUN_10002420` |  | tag display name | MED | log callers |
| `FUN_10002640` |  | write tag as loose file in Data:Local | MED | strings |
| `FUN_10002da0` | U_Pak.cc | load tag (generic) | MED | flli loader |
| `FUN_10002e50` | U_Pak.cc | stli line reader | HIGH | read |
| `FUN_10003030` | U_Pak.cc | reli rect reader | MED | 'reli', "Rect" |
| `FUN_10003340` | U_Pak.cc | coli colour reader | MED | 'coli', "Color" |
| `FUN_10003520` | U_Pak.cc | idli item reader | HIGH | read |
| `FUN_10003700` | U_Pak.cc | copy tag data | MED | dataCopyPtr |
| `FUN_100037a0` |  | pak failure alert | MED | string |
| `FUN_10049de0` |  | open zip, read ECD + central directory | HIGH | strings + read |
| `FUN_1004a1d0` |  | parse central directory record | HIGH | read |
| `FUN_1004a4f0` |  | seek local header -> data offset | HIGH | read |
| `FUN_10049ca0` | unzip.c | accept entry: stored only, csize==usize | HIGH | read |
| `FUN_1004a660` |  | read LE u16 | MED | usage — ⚑ corrected (review 2026-10-03) #8: was HIGH on string/import/usage evidence only |
| `FUN_1004a680` |  | read LE u32 | MED | usage — ⚑ corrected (review 2026-10-03) #8: was HIGH on string/import/usage evidence only |
| `FUN_1004a470` |  | close zip | MED | caller |
| `FUN_1004a6b0` |  | ECD search retry | MED | string |
| `FUN_10004540` |  | prefs init/load-or-default | MED | strings |
| `FUN_10004640` | U_Prefs.cc | save prefs (encode names, offset scores) | HIGH | read |
| `FUN_10004ae0` |  | default high-score table | HIGH | read |
| `FUN_10004c30` |  | copy prefs block | MED | read |
| `FUN_10004f80` |  | load prefs (System Folder, else pak 'pref'), version 0x2714 | HIGH | read |
| `FUN_10004ef0` |  | get byte pref n (+4+n) | HIGH | read |
| `FUN_10004ab0` |  | set byte pref n | HIGH | read |
| `FUN_10004f00` |  | get int pref n (+0x68+4n) | HIGH | read |
| `FUN_10004ac0` |  | set int pref n | HIGH | read |
| `FUN_100051a0` | G_Game.cc | game loop (one session) | HIGH | read |
| `FUN_10006b50` |  | logic tick: input, notices, debris, particles, blur, players, scorebar, scroll, end-level, entities | HIGH | read |
| `FUN_10007070` |  | draw world | MED | callees |
| `FUN_10007170` | G_Game.cc (span) | level complete → transition sound, `FUN_100064d0` next sector (session ends via `none`) | HIGH | read — ⚑ corrected (wave 1, 2026-10-03): was "level complete -> next level / end" MED; see level-scroll-objects.md §8 |
| `FUN_100064c0` | G_Game.cc (span) | stop session (`+0x08 = 0`) | HIGH | read — ⚑ corrected (wave 1, 2026-10-03): was "end session request" MED; see level-scroll-objects.md §8 |
| `FUN_100064d0` | G_Game.cc (span) | level start: next sector, per-level resets, scroll init, load spawns, preload weapons (`FUN_1002b3a0`), Notice_Level_NN; perm F52-56 | HIGH | read + listing — ⚑ corrected (wave 1, 2026-10-03): was "start level (display, level load)" MED; see level-scroll-objects.md §8 |
| `FUN_100069b0` |  | load film for playback (attract cycle), srand(seed) | HIGH | read |
| `FUN_100072c0` | G_Game.cc (span) | accuracy tier: pct float ≥100/95/90/85/80 → flli189–194 × sector; step max(trunc(b·0.02f),100); sets 100 % flag G+0xb | HIGH | listing `100072c0..100075dc` — ⚑ corrected (wave 1, 2026-10-03): was "ground accuracy tier computation" MED; see scoring-bonuses.md §6.3 |
| `FUN_100075e0` | G_Game.cc (span) | accuracy tally (11 states) + mission bonus 10 × flli205 raw when all levels 100 % | HIGH | listing `100079a0..10007d3c`, table `0x100e3cd0` — ⚑ corrected (wave 1, 2026-10-03): was "end-of-level accuracy tally" MED; see scoring-bonuses.md §6.4 |
| `FUN_10007130` | G_Game.cc (span) | per-level counter resets: `FUN_10007130` game struct +0x16c…, `FUN_10007150` accuracy counts G+0x3c/+0x40, `FUN_10007280` accuracy tally +0x48… | MED | read (level-scroll-objects.md §8, scoring-bonuses.md §6.2) |
| `FUN_10005cc0` |  | current level ID | HIGH | read |
| `FUN_10005cd0` |  | current sector number | HIGH | read |
| `FUN_10005ce0` |  | game time / frame accessor | LOW | usage |
| `FUN_10005d00` | G_Game.cc (span) | accuracy-reward flag G+0xc get (`FUN_10005d10` clears it) | MED | read (scoring-bonuses.md §6.4) |
| `FUN_10005d20` |  | player n pointer | MED | usage in FUN_10033850 |
| `FUN_10005d40` | G_Game.cc (span) | nearest active player to a point: position, distance, player number (ties → player 1) | HIGH | listing `10005d40..10005ec0` (units-movement.md §5.1) |
| `FUN_10006190` |  | add points to player n | MED | read |
| `FUN_10006110` |  | any player active | MED | rule #7 |
| `FUN_100061e0` | G_Game.cc (span) | ground-accuracy created += 1 (G+0x3c); `FUN_10006200` destroyed += 1 (G+0x40) | HIGH | hand-decoded words `100061e4`, `10006204` (scoring-bonuses.md §6.2) |
| `FUN_10009390` |  | film buffer init (version 0x2715) | HIGH | read |
| `FUN_10009710` |  | film header for recording | HIGH | read |
| `FUN_10009830` |  | record one tick of input (bit-packed) | HIGH | read |
| `FUN_100097a0` |  | replay one tick of input | HIGH | read |
| `FUN_10009750` |  | film still playing | HIGH | read |
| `FUN_100095b0` | G_Film.cc | save film as tag 'last' | HIGH | read |
| `FUN_100094a0` |  | load film tag + version check | MED | strings |
| `FUN_10009680` |  | film header getters (seed) | MED | caller |
| `FUN_10009770` |  | film seed getter | HIGH | read |
| `FUN_10009780` |  | film level getter | HIGH | read |
| `FUN_10009790` |  | film player-count getter | HIGH | read |
| `FUN_10009230` |  | show decoded notice text | LOW | read |
| `FUN_1000ae20` | M_Display.cc | display setup 640x480x16, borders, score bar | MED | perm F52-59 |
| `FUN_1000beb0` |  | present frame (interlaced) | MED | caller branch |
| `FUN_1000bc60` |  | present frame | MED | caller branch |
| `FUN_1000a480` |  | pixel buffer width,height | HIGH | read |
| `FUN_1000a4a0` |  | pixel buffer base,rowBytes | MED | usage |
| `FUN_100099c0` | M_PixelBuffer.cc | pixel buffer (GWorld) create w,h,depth | MED | caller args |
| `FUN_10009fd0` |  | copy rect between buffers | MED | usage |
| `FUN_1000ef90` | G_Text.cc | parse tefo text format | HIGH | read |
| `FUN_1000e8d0` |  | character -> font frame index | HIGH | read |
| `FUN_1000ebd0` |  | draw one character | MED | read |
| `FUN_1000e670` |  | text shadow settings | MED | perm F19-21 |
| `FUN_1000f7a0` | G_Background.cc | module init: register "Background", 12 debug console command names (10 handlers) | HIGH | strings + TOC handler slots (level-scroll-objects.md §9) |
| `FUN_1000f990` | G_Background.cc | free media mask if module live (session end) | MED | read (level-scroll-objects.md §9) |
| `FUN_1000f9c0` | G_Background.cc | module shutdown, free mask | MED | read (level-scroll-objects.md §9) |
| `FUN_1000fa10` | G_Background.cc | level-load spawn pass: rows bottom … top−64 (3600 … 3056) | HIGH | listing `1000fa48 subi r3,r3,0x41` (level-scroll-objects.md §2) |
| `FUN_1000fa90` | G_Background.cc | level scroll init: speed 1, offset 0, window top = RECT bottom − 480 (3600 − 480 = 3120), progress 481 | HIGH | listing `1000fb38` (level-scroll-objects.md §2); dump (bosses.md §2.3) |
| `FUN_1000fbc0` | G_Background.cc | load level map + media mask, mask element size | HIGH | read |
| `FUN_1000fee0` |  | is point on water (mask == 0x001f) | HIGH | read |
| `FUN_1000ffc0` | G_Background.cc | resume vertical scroll (speed 1) unless the level has ended | HIGH | listing — ⚑ corrected (wave 1, 2026-10-03): was "resume vertical scroll (speed 1)" HIGH; see level-scroll-objects.md §4 |
| `FUN_1000ffe0` |  | pause vertical scroll | HIGH | read |
| `FUN_1000fff0` |  | is scroll paused | HIGH | read |
| `FUN_10010000` | G_Background.cc | per-tick scroll step; level end when progress (r2−0x61e4, starts 481) ≥ level RECT bottom (3600), i.e. window top = 1; spawn row top−64 (world y −64) | HIGH | raw `10010000..1001009c` — ⚑ corrected (wave 1, 2026-10-03): was "scroll step, level-end flag, spawn objects at top-64" HIGH; see bosses.md §2.3, level-scroll-objects.md §3 |
| `FUN_10010220` |  | advance scroll window by speed | HIGH | read |
| `FUN_100100b0` | G_Background.cc | horizontal view offset ±1 px per call, clamp [−32, 31]; driven by each active player's left/right input (`FUN_10028170`, call `10029508`), reset per level | HIGH | listing + caller — ⚑ corrected (wave 1, 2026-10-03): was "horizontal view shift ±32" HIGH; see level-scroll-objects.md §5, player-physics.md §2.5 |
| `FUN_10010120` | G_Background.cc | draw terrain window: map (top, off+32, top+480, off+448) → buffer (0,0,480,416); perm F54/55 | HIGH | listing — ⚑ corrected (wave 1, 2026-10-03): was "draw terrain window" MED; see level-scroll-objects.md §9 |
| `FUN_1000fec0` | G_Background.cc | scroll window top (map row of world y 0) | HIGH | read; callers use it for map↔world — ⚑ corrected (wave 1, 2026-10-03): was "scroll window top" MED; see level-scroll-objects.md §1 |
| `FUN_1000fed0` | G_Background.cc | pixels scrolled this tick (ground entities add it to y) | HIGH | read; writer `FUN_10010220` (units-movement.md §2.1, level-scroll-objects.md §3) |
| `FUN_100100a0` | G_Background.cc | horizontal offset getter | HIGH | read (level-scroll-objects.md §5) |
| `FUN_10010360` | G_Background.cc | free media mask | HIGH | read (level-scroll-objects.md §9) |
| `FUN_10010570` | G_Background.cc | console REVERSE: scroll speed 1 ↔ −1 (debug) | HIGH | listing (level-scroll-objects.md §9) — ⚑ conflict: bosses.md role rows call it the SCROLL toggle (MED, strings + dump); level-scroll-objects.md puts SCROLL at undefined `0x100104f0` from the TOC slots |
| `FUN_10010860` | G_Background.cc | console LEVELSPAWNS toggle (debug) | HIGH | read (level-scroll-objects.md §9) |
| (undefined) `0x100103b0` `0x10010430` `0x10010480` `0x100104f0` `0x10010600` `0x10010640` `0x100106f0` `0x100107a0` | G_Background.cc | console BACKSIZE, ERASEBACK, JUMP, SCROLL, ROW, LOGMEDIA, MEDIASIZE, MEDIA handlers (no Ghidra function) | HIGH | TOC slots `0x100df07c…a0` + listings (level-scroll-objects.md §9); not counted in the `FUN_` row counts |
| `FUN_10010990` |  | HTML RRGGBB -> 16-bit pixel | MED | string — ⚑ corrected (review 2026-10-03) #8: was HIGH on string/import/usage evidence only |
| `FUN_10010f90` |  | registered? (out of scope) | MED | callers |
| `FUN_10010e90` |  | registration banner (out of scope) | MED | perm S33-35 |
| `FUN_10010cf0` | M_Registration.cc | registration profile (out of scope) | MED | strings |
| `FUN_10011a70` | G_Level.cc | module init: register "Level", build order list | HIGH | read (level-scroll-objects.md §8) |
| `FUN_10011ab0` | G_Level.cc | module shutdown, free order list | MED | read (level-scroll-objects.md §8) |
| `FUN_10011b00` | G_Level.cc | number of unregistered levels = 4 (demo, out of scope) | HIGH | read (level-scroll-objects.md §8) |
| `FUN_10011b10` | G_Level.cc | free order list (demo cut) | MED | read (level-scroll-objects.md §8) |
| `FUN_10011c00` | G_Level.cc | build level order list from encoded table | HIGH | read |
| `FUN_10011b30` |  | is level in first-4 (unregistered) set | HIGH | read |
| `FUN_100122f0` | G_Level.cc | parse level file | HIGH | read |
| `FUN_10012230` | G_Level.cc | read pak entry `leve`, de-obfuscate, parse | HIGH | read — ⚑ corrected (wave 1, 2026-10-03): was "load level by tag" MED; see level-scroll-objects.md §6.1 |
| `FUN_100120f0` | G_Level.cc | load level by tag (asserts editor flag `DAT_100e0151` clear) | HIGH | read — ⚑ corrected (wave 1, 2026-10-03): was "level info by ID" MED; see level-scroll-objects.md §6.1 |
| `FUN_10011e30` | G_Level.cc | level tag → sector (0 if absent) | HIGH | read — ⚑ corrected (wave 1, 2026-10-03): was "sector number of current level" MED; see level-scroll-objects.md §8 |
| `FUN_10011de0` | G_Level.cc | level count (order-list length via `FUN_10000ce0`, 12) | HIGH | read — ⚑ corrected (wave 1, 2026-10-03): was "level count" LOW; see level-scroll-objects.md §8 |
| `FUN_10011f00` | G_Level.cc | sector → level tag (`none` if absent) | HIGH | read (level-scroll-objects.md §8) |
| `FUN_10011fd0` | G_Level.cc | load level by sector (info [+ object list]) | HIGH | read (level-scroll-objects.md §8) |
| `FUN_10012170` | G_Level.cc | free a level-object list | HIGH | read (level-scroll-objects.md §6.1) |
| `FUN_100121c0` | G_Level.cc | free the level order list | HIGH | read (level-scroll-objects.md §8) |
| `FUN_100125d0` | G_GameObject (span) | constructors: `FUN_100125d0` game object, `FUN_100141a0` entity | MED | dump (units-movement.md §10) |
| `FUN_10012650` | G_GameObject (span) | object reset (air = 1, layer `defa`, sprite none) | MED | dump (units-movement.md §3) |
| `FUN_100128d0` | G_GameObject (span) | get position | HIGH | dump (units-movement.md §2.1) |
| `FUN_10012940` | G_GameObject (span) | half-size from sprite frame dims / 2 | MED | decompile (damage-health-death.md §2.2) |
| `FUN_10012a00` | G_GameObject (span) | entity bounds as Mac rect {t,l,b,r} | HIGH | listing (damage-health-death.md §2.2) |
| `FUN_10012ad0` | G_GameObject (span) | bounding box l,t,r,b = centre ± half size (trunc) | HIGH | listing (damage-health-death.md §2.2); dump (units-movement.md §2.1) |
| `FUN_10012bc0` | G_GameObject (span) | start hit glow (colour, speed, 32) unless active | HIGH | listing (damage-health-death.md §3) |
| `FUN_10012ca0` | G_GameObject (span) | integrate position: ground `y += scroll delta`; `x += vx; y += vy`; cull outside the area with margin 128 | HIGH | listing `10012cc0..10012e30` (units-movement.md §2.1, §7); level-scroll-objects.md agrees (module "G_Sprite (span)", bounds MED) |
| `FUN_10012fa0` |  | draw entity: draw-layer 4CC -> render layer | HIGH | read |
| `FUN_10013460` |  | draw entity shadow | MED | perm F48-51 |
| `FUN_10014650` |  | current state pointer (unit+0x4e0+s*0x5e0) | HIGH | read |
| `FUN_100142f0` | G_Entity.cc (span) | entity reset (target none `+0x118 = −1`, velocities 0) | HIGH | dump (units-movement.md §3) |
| `FUN_100144a0` | G_Entity.cc | bind unit def to entity (unit cache +0x98); allocate per-state spawn-record lists (+0x19c+4s, 0x18-byte records); +0x13e | MED | read/dump, asserts `newSpawnInfoPtr`; caller `FUN_10035cd0` (spawn-and-waves.md §2.1, bosses.md §3.3; units-movement.md proposed HIGH on strings only — kept MED per review #8) |
| `FUN_10014670` | G_Entity.cc (span) | switch entity to its first `UseThisStateOnWeaponPowerupRelease` state (+0x835 = 0x4e0 + 0x355) | HIGH | dump (units-movement.md §10, weapons-projectiles.md §2.5) |
| `FUN_100146f0` | G_Entity.cc | change state by name (last match wins; Delete/Destroy special): stamps +0xa4, draws timer +0xb8, entry counter +0x14c+4s with OnCounter (+0x3b4 → +0x51c); velocity ramp set-up (accel = s1·dir − v, desired = MaxSpeed·dir); flee start/stop; re-arms spawn sets (`FUN_10017cb0`) | HIGH | listing `10014bac..10014db4` (units-movement.md §4); OnCounter dump (bosses.md §3.2); 7 callers — ⚑ corrected (wave 1, 2026-10-03): was "change state by name (Delete/Destroy special)" MED; see units-movement.md §4, bosses.md §3.2 |
| `FUN_10015550` |  | evaluate 5 state rules | HIGH | read |
| `FUN_10015280` | G_Entity.cc (span) | motion controller: nearest player, no-player actions, cyclic, constrain, OnRange trigger, hold / hunt / ramp | HIGH | listing `10015280..1001554c` (units-movement.md §5) |
| `FUN_10015930` | G_Entity.cc (span) | sprite animation step (row from heading, loop / ping-pong / stop, random frames) | HIGH | listing `10015930..10015b20` (units-movement.md §8.1) |
| `FUN_10015b40` | G_Entity.cc (span) | state spawn-set executor (per tick, on-screen entities incl. Collides-FALSE controllers): rotation gate `FUN_10017150`, per set volley arm / countdown / issue (rate, volley, delay), positions absolute / relative / rotated with owner scale, heading, offscreen / fleeing gates → `FUN_10033220` | HIGH | raw `10015b40..100161b0` (units-movement.md §9, spawn-and-waves.md §2.3–§2.6, bosses.md §3.3); caller `FUN_10033850` — all three files agree |
| `FUN_10014f10` | G_Entity.cc (span) | damage entity: hit delay PermFloat167 (>), float shields +0x134 −= dmg, invulnerable restore, OnHit state (needs delay ≠ 0), ≤ 0 → score + destroy or `UseThisStateOnShieldDepletion` (`FUN_10017e70`); glow/particles/sound/collision spawn | HIGH | listing `10014f10..1001527c` (damage-health-death.md §3), raw (bosses.md §3.4); callers `FUN_10036cf0`, `FUN_10033850` — ⚑ corrected (wave 1, 2026-10-03): was "damage entity" MED; see damage-health-death.md §3, bosses.md §3.4 |
| `FUN_10016300` | G_Entity.cc (span) | destroy entity: obstacle, particles, destructSpawn (media-gated `FUN_10016880`), notice, sound, flags +0xcb/+0xd9/+0xda, ground-accuracy kill count, random bonus r = RandomRange(0,100) vs flli209–219 → O25–34 | HIGH | listing `10016300..10016528` (damage-health-death.md §4.1), `10016508..100167b8` (scoring-bonuses.md §7) — ⚑ corrected (wave 1, 2026-10-03): was "destroy entity (random bonus table)" MED; see damage-health-death.md §4.1, scoring-bonuses.md §7 |
| `FUN_100161c0` | G_Entity.cc (span) | facing in degrees from the current sprite frame / directions | HIGH | read + disasm use (spawn-and-waves.md §2.5; units-movement.md §8 MED) |
| `FUN_10016230` | G_Entity.cc (span) | sprite frame for a heading (rounded) | MED | dump (units-movement.md §8) |
| `FUN_10016880` | G_Entity.cc (span) | media gate for destruct/deletion spawns (may the spawn appear here?) + water impact by mediaImpactSize (perm O6-9) | HIGH | listing — ⚑ corrected (wave 1, 2026-10-03): was "water-impact spawn" MED; see damage-health-death.md §4.2 |
| `FUN_10016bd0` | G_Entity.cc (span) | entity centre on screen: 0 ≤ x ≤ 416 (VisibleGameWidth), 0 ≤ y ≤ 480, inclusive | HIGH | raw listing (bosses.md §3.3, spawn-and-waves.md §2.3, units-movement.md §7); callers `FUN_10015b40`, `FUN_100353e0` |
| `FUN_10016cc0` | G_Entity.cc (span) | seek target: per-axis ±Delta, clamp ±MaxSpeed (flee speeds when fleeing) | HIGH | listing (units-movement.md §5.2) |
| `FUN_10016da0` | G_Entity.cc (span) | constrainInGameArea bounce | HIGH | listing (units-movement.md §5.7) |
| `FUN_10016fe0` | G_Entity.cc (span) | cyclic motion (2 RNG draws per tick) | HIGH | listing (units-movement.md §5.5) |
| `FUN_10017150` | G_Entity.cc (span) | spawn-time rotation gate: DoRotateToTarget (+0x303), +0xc4 countdown, hold rotation while a PauseAnyRotationWhileSpawning volley is in progress, else `FUN_100172d0` | HIGH | dump + listing (units-movement.md §8.2); spawn-and-waves.md §2.4 and bosses.md §3.3 read it MED; caller `FUN_10015b40` — ⚑ conflict: damage-health-death.md INDEX updates call it "the runtime spawn-set reader (LOW)"; three files with listings put the executor in `FUN_10015b40` |
| `FUN_100172d0` | G_Entity.cc (span) | turn sprite one direction step toward target point (+0x11c/+0x120) every FrameDelay; sets +0xc1 tracking flag | HIGH | listing (units-movement.md §8.2); spawn-and-waves.md §6 MED |
| `FUN_10017510` | G_Entity.cc (span) | flee target by 4CC code (13 codes), sets fleeing; perm F14-17 | HIGH | listing — ⚑ corrected (wave 1, 2026-10-03): was "flee targets" MED; see units-movement.md §6 |
| `FUN_10017a10` | G_Entity.cc (span) | ramp velocity to desired; stationary → zero; orbit rate | HIGH | listing (units-movement.md §5.6) |
| `FUN_10017b70` | G_Entity.cc (span) | hold position (accelerate away, HoldMaxSpeed / HoldDelta) | HIGH | listing (units-movement.md §5.3) |
| `FUN_10017c40` | G_Entity.cc (span) | reverse on reaction (desired = −dir·MaxSpeed) | HIGH | listing (units-movement.md §5.4) |
| `FUN_10017cb0` | G_Entity.cc (span) | state-entry spawn-set arming: per set rate, last = now, volley = left, delay draws, first volley armed at entry; +0xc4 = TimeToPause; +0xc3 "has sets" | HIGH | raw `10017d4c..10017db8`; caller `FUN_100146f0` — ⚑ corrected (wave 1, 2026-10-03): was "init state spawn-set timers" MED; see spawn-and-waves.md §2.2, bosses.md §3.3 |
| `FUN_10017e70` | G_Entity.cc (span) | switch to the first `UseThisStateOnShieldDepletion` state (+0x836) | HIGH | listing; caller `FUN_10014f10` (damage-health-death.md §3, units-movement.md §10) |
| `FUN_10017ef0` | G_Entity.cc (span) | rules #8/#9 "within range of a player": nearest active player with dist < range (strict), range ≠ 0 | HIGH | listing (units-movement.md §5.8, spawn-and-waves.md §6) |
| `FUN_10018070` | Notice (strings) | notice start / stop / reset / post / tick / draw (`FUN_10018070`…`FUN_100184b0`) | MED | strings + dump (units-movement.md §10) |
| `FUN_10018d20` | U_Sprite.cc | load sprite group (IC+IA plates -> frames) | HIGH | read |
| `FUN_1001f140` | U_SpritePlate.cc | scan plate -> rect list | HIGH | read |
| `FUN_1001f1c0` | U_SpritePlate.cc | plate key-pixel checks + frame loop | HIGH | read |
| `FUN_1001f340` |  | next frame rect | HIGH | read |
| `FUN_1001f4e0` |  | strip height | HIGH | read |
| `FUN_1001f540` |  | cell width | HIGH | read |
| `FUN_1001f5b0` |  | trim cell to content | HIGH | read |
| `FUN_1001d780` | U_SpriteBlit.cc | encode frame: 0x18 header (magic 0x499602d2, w, h, key, alpha offset) + RGB555 + alpha map | HIGH | read (sprite-sound-containers.md §2.3a) — ⚑ corrected (review 2026-10-03) #9: was MED, caller only |
| `FUN_1001eec0` | U_SpriteBlit.cc | build alpha map from alpha plate: red 5-bit channel, 31/key → 32 (transparent), empty row → 1000 | HIGH | read — ⚑ corrected (review 2026-10-03) #9 |
| `FUN_1001d9f0` | U_SpriteBlit.cc | blit frame: colour key, or alpha blend (dst·a+src·(32−a))/32 | HIGH | read — ⚑ corrected (review 2026-10-03) #9 |
| `FUN_10019570` | U_Sprite.cc | sprite draw dispatcher (mode flags, clip, scale path, `COST` rect) — not a decoder | HIGH | read (sprite-sound-containers.md §2.3a) — ⚑ corrected (review 2026-10-03) #9 |
| `FUN_1001ec80` | U_SpriteBlit.cc | draw translucent solid-colour rect (draw type `COST`) | HIGH | read — ⚑ corrected (review 2026-10-03) #9 |
| `FUN_10019ca0` | U_Sprite.cc | sprite dimensions / draw frame | MED | strings |
| `FUN_1001f7c0` | G_Resource.cc | resource manager init + console cmds | MED | strings |
| `FUN_1001f950` | G_Resource.cc | G_Res_Load(type,id,usage) | MED | strings |
| `FUN_1001fcf0` |  | load permanent ID/rect/colour/float lists | HIGH | read |
| `FUN_1001fe60` | G_Resource.cc | load permanent sprites, sounds, game strings | HIGH | read |
| `FUN_100204a0` | G_Resource.cc | load 220 permanent floats | HIGH | read |
| `FUN_100201f0` |  | PermObjectID(i) | HIGH | disasm |
| `FUN_10020200` |  | PermSpriteID(i) | HIGH | disasm |
| `FUN_10020210` |  | PermSoundID(i) | HIGH | disasm |
| `FUN_10020220` |  | PermRect(i) | HIGH | disasm |
| `FUN_10020250` |  | PermFloat(i) | HIGH | disasm |
| `FUN_10020260` |  | GameString(i) | HIGH | disasm |
| `FUN_10021190` | M_Image.cc | QuickTime image import into pixel buffer | HIGH | read |
| `FUN_10020da0` |  | image load wrapper | MED | callers |
| `FUN_10021470` | G_Scores.cc (span) | score > 15th high score (signed, strict) | HIGH | listing + brute force — ⚑ corrected (wave 1, 2026-10-03): was "score beats 15th high score" MED; see scoring-bonuses.md §9.1 |
| `FUN_100214c0` | G_Scores.cc (span) | high-score insertion for 1–2 players, then scores-screen name edit | MED | read — ⚑ corrected (wave 1, 2026-10-03): was "high-score entry" LOW; see scoring-bonuses.md §9.2 |
| `FUN_10021950` | G_Scores.cc | scores screen | MED | perm F77/78 |
| `FUN_10021bd0` |  | scores screen input/flash | MED | perm |
| `FUN_100222f0` | G_Scores.cc | scores layout | MED | perm |
| `FUN_100229a0` |  | interface main loop | MED | caller of FUN_100000a0, perm F68 |
| `FUN_100234d0` |  | start game (level select, play, high score) | MED | read |
| `FUN_10022ef0` |  | pause screen | MED | perm SND8 |
| `FUN_10023040` | G_Interface.cc | progress text line | MED | perm F64 |
| `FUN_10023fd0` |  | interface buttons/logo sprites | MED | perm SPR3-5 |
| `FUN_10025420` | G_Interface.cc | button layout | MED | perm F62/63 |
| `FUN_10025b90` | G_Credits.cc | credits | MED | perm |
| `FUN_10025970` |  | advertisment screen | MED | perm F67 |
| `FUN_1002e310` | G_LevelSelection.cc | level selection screen | MED | perm |
| `FUN_1002fcc0` |  | level select accept/fail scaling | MED | perm F44-47 |
| `FUN_1002f7a0` | G_LevelSelection.cc (span) | draw a level-select button; mouse-over hilite = `COST` translucent rect (`COST` is a draw type, NOT a price) | MED | read — ⚑ corrected (review 2026-10-03) #9 |
| `FUN_1002ef10` | G_LevelSelection.cc | level-select message timeout | MED | read (scoring-bonuses.md §10.4) |
| `FUN_1002efb0` | G_LevelSelection.cc | fill 3 level previews; reachable = sector ≤ int pref 3 (unregistered: > demo limit → registration required) | MED | read (scoring-bonuses.md §10.1) |
| `FUN_1002f3c0` | G_LevelSelection.cc | draw level-select screen | MED | read (scoring-bonuses.md §10.4) |
| `FUN_1002fe40` | G_LevelSelection.cc | `FUN_1002fe40` flash start / `FUN_1002fc90` reset / `FUN_1002ff30` button hit-test + rollover sound / `FUN_1002fc60` middle preview | MED | read (scoring-bonuses.md §10.4) |
| `FUN_10026410` | G_Player.cc | player setup: plde by index, perm unit loads O2–39, in-game by numPlayers, lives 3 at sector 1 else 1, shield 100, score/money 0, state 2 | HIGH | disasm `10026434..10026874` — ⚑ corrected (wave 1, 2026-10-03): was "player setup + permanent unit loads" MED; see player-physics.md §7 |
| `FUN_10028170` | G_Player.cc (span) | player update: accel/decay/cap movement, banking frames F166, view shift (`FUN_100100b0`), area clamp F54/55/183, crosshair F185–187, defence bonus F184 | HIGH | disasm — ⚑ corrected (wave 1, 2026-10-03): was "player update (movement, crosshair, defence bonus)" MED; see player-physics.md §2 |
| `FUN_10029a10` | G_Player.cc | add score: ×multiplier unless raw; strict `> threshold` → 1 life, threshold += AdditionalRequired + step, step += flli 182; raw (mission bonus only) sets step = score + flli 182; score stored + 0x05532A3E | HIGH | listing `10029a10..10029af8`; 7 call sites (raw bl-scan) — ⚑ corrected (wave 1, 2026-10-03): was "add score (obfuscated) + extra lives" HIGH; see scoring-bonuses.md §3.1 |
| `FUN_1002a3a0` | G_Player.cc (span) | per-player input step: clear 7 bytes at +0x1fc, replay from film or poll ISp + record with decoded score | HIGH | disasm (engine-loop.md §7) — ⚑ corrected (review 2026-10-03) #4 |
| `FUN_10027670` | G_Player.cc | coin-bonus setup: coinValue = flli171 (×sector if flli170 ≠ 0), bonus = money × coinValue, step = max(trunc(bonus·0.02f),100), spawn money-counter unit | HIGH | listing `100276c8..100277ec` — ⚑ corrected (wave 1, 2026-10-03): was "end-of-level coin bonus" MED; see scoring-bonuses.md §6.5 |
| `FUN_10027930` | G_Player.cc | coin-bonus tally state machine (8 states, pays step × multiplier every 3rd frame) | HIGH | listing `10027c70..10027c90` + decompile — ⚑ corrected (wave 1, 2026-10-03): was "money counter display" MED; see scoring-bonuses.md §6.5 |
| `FUN_10027e50` | G_Player.cc | player death (ship destroyed): owned entities destroyed/deleted (`FUN_10034b90`), death spawn, spill money as $50/$10/$5/$1 coins (greedy, MoneyUnit O2-5), money 0, state 3, multiplier reset | HIGH | listing `10027f64..10028124` (scoring-bonuses.md); decompile (weapons-projectiles.md §2.6, damage-health-death.md §5.3, both MED) — ⚑ corrected (wave 1, 2026-10-03): was "coin unit selection" MED; see scoring-bonuses.md §5.2, damage-health-death.md §5.3, weapons-projectiles.md §2.6 |
| `FUN_10027100` | G_Player.cc | player takes hit: shieldHitDelay (≥), shield −= dmg × shieldBaseHitPercentage (15), death if < 0, glow, SpawnOnHit (F162), shield warning | HIGH | listing / disasm — ⚑ corrected (wave 1, 2026-10-03): was "player hit spawn delay" MED; see damage-health-death.md §5.2, player-physics.md §3 |
| `FUN_100269a0` | G_Player.cc | level start per player: state 2, start position, shield 100, money 0, defence-bonus flag reset, appear fade F163–165, RandomRange(400,2000) | HIGH | disasm `100269d0..10026af0` — ⚑ corrected (wave 1, 2026-10-03): was "player appear fade" MED; see player-physics.md §4.2 |
| `FUN_10029fe0` | G_Player.cc | spawn multiplier indicator O35–39 for ×2/3/4/5/10, replacing the previous one (+0xb8) | HIGH | jump table `0x100e93ec` + listing — ⚑ corrected (wave 1, 2026-10-03): was "bonus multiplier units" MED; see scoring-bonuses.md §4 |
| `FUN_10026c90` | G_Player.cc (span) | get player index (`+0xcc`) | HIGH | `lbz r3,0xcc(r3)` one-liner; `FUN_10026410` "Setting Up Player %i" — ⚑ corrected (wave 1, 2026-10-03): was "player takes hit" LOW; see units-movement.md §5.1, damage-health-death.md §5.1, player-physics.md §8 (the player hit is `FUN_10027100`) |
| `FUN_10026c10` | G_Player.cc (span) | player in-game flag (`+0xc4`) | HIGH | `lbz r3,0xc4(r3)` (player-physics.md); damage-health-death.md labels it MED — ⚑ corrected (wave 1, 2026-10-03): was "player is alive" LOW; see player-physics.md §1, damage-health-death.md §5.1 |
| `FUN_10026100` | (static init) | copy constant templates into G_Player statics | LOW | dump; caller `FUN_10000000` (player-physics.md) |
| `FUN_10026180` | G_Player.cc (span) | pure `7·3^bitlen(x&0xff)`; only caller discards it (obfuscation filler) | HIGH | disasm `10026180..10026254`, `10028b38`/`10028c54` (player-physics.md §9) |
| `FUN_10026260` | G_Player.cc (span) | player constructor (field defaults, lives 0, money 0, score 0, index 0xff, numPlayers 1) | HIGH | disasm stores `100262a4..10026340`; caller `FUN_100051a0` (player-physics.md §1) |
| `FUN_100263a0` | G_Player.cc (span) | player destructor | MED | dump (player-physics.md) |
| `FUN_10026b10` | G_Player.cc | place at solo/multi start, v = 0, crosshair 0 | HIGH | disasm (player-physics.md §4.1) |
| `FUN_10026c20` | G_Player.cc | in game and life state 1 (out of lives) | HIGH | dump (player-physics.md §4) |
| `FUN_10026c50` | G_Player.cc | get life state (+0xc6) | HIGH | dump (player-physics.md §4, damage-health-death.md §5.1) |
| `FUN_10026c60` | G_Player.cc | life state == arg (+0xc6) | HIGH | dump (player-physics.md §4, damage-health-death.md §5.1) |
| `FUN_10026c80` | G_Player.cc | set life state + enter time | HIGH | dump; callers `FUN_10026410`, `FUN_100269a0` (player-physics.md §4) |
| `FUN_10026ca0` | G_Player.cc | get plde pointer (+0x94) | HIGH | dump (player-physics.md §1) |
| `FUN_10026cb0` | G_Player.cc | max speed = active_DefaultMaxSpeed | HIGH | disasm (player-physics.md §2.1) |
| `FUN_10026cc0` | G_Player.cc | init session lives (life_NumInitial if start sector 1 else 1), extra-life threshold = life_InitialRequiredScore (+0x9c), step 0 | HIGH | listing `10026ce0..10026d18`, `10026838` (scoring-bonuses.md §3.2, player-physics.md §7, level-scroll-objects.md §8) |
| `FUN_10026d50` | G_Player.cc | get / set lives (`FUN_10026d60`; stored ± 0x1524DCEF) | HIGH | listing (player-physics.md §7, scoring-bonuses.md §2) |
| `FUN_10026d70` | G_Player.cc | add one life, cap life_MaxNum, spawn life_Spawn_ID | HIGH | listing `10026d84..10026dc0` (scoring-bonuses.md §3.3, player-physics.md §7) |
| `FUN_10026ea0` | G_Player.cc | clear overload + glow fields | HIGH | dump (player-physics.md §6.2) |
| `FUN_10026ee0` | G_Player.cc | overload warning pulse; the Nth (powerupOverload_NumWarnings, 8) warning destroys the ship | HIGH | disasm `10026f0c..100270d8` (player-physics.md §6.2, weapons-projectiles.md §2.6) |
| `FUN_10027400` | G_Player.cc | reset shield (100 / 0) + hit timers | HIGH | disasm (player-physics.md §3) |
| `FUN_10027490` | G_Player.cc | add shield, clamp [0,100] | HIGH | disasm (player-physics.md §3) |
| `FUN_10027540` | G_Player.cc | get / set shield (`FUN_10027560`; stored + 1324366.0) | HIGH | listing (damage-health-death.md §5.1, player-physics.md §3) |
| `FUN_10027580` | G_Player.cc | money = 0 | HIGH | disasm (player-physics.md §7) |
| `FUN_100275b0` | G_Player.cc | add / get / set money (`FUN_10027610` / `FUN_10027620`; stored ± 0xB2CCE) | HIGH | listing `10027738` (scoring-bonuses.md §5.2, player-physics.md §7) |
| `FUN_10027630` | G_Player.cc | reset coin-tally (money-counter display) fields | MED | read (scoring-bonuses.md §6.5, player-physics.md) |
| `FUN_10027db0` | G_Player.cc | coin tally started / money counter running (+0xd8 ≠ 0) | MED | read (scoring-bonuses.md §6.5, player-physics.md) |
| `FUN_10027dd0` | G_Player.cc | player invulnerable flag (+0xce) | HIGH | disasm (player-physics.md §4.4, damage-health-death.md §5.1) |
| `FUN_10027de0` | G_Player.cc | set/clear invulnerability (+ sticky) | MED | dump (player-physics.md §4.4) |
| `FUN_100298c0` | G_Player.cc | draw player (state 4): weapons, sprite passes, coin-tally text while alpha < 32 | MED | dump; caller `FUN_10007070` (player-physics.md, scoring-bonuses.md) |
| `FUN_100299c0` | G_Player.cc | reset / get / set score (`FUN_100299f0` / `FUN_10029a00`; stored ± 0x05532A3E) | HIGH | disasm (player-physics.md §7, scoring-bonuses.md §2, level-scroll-objects.md §8) |
| `FUN_10029b20` | G_Player.cc | step score multiplier 1→2→3→4→5→10 | HIGH | jump table `0x100e93c0` (player-physics.md, scoring-bonuses.md §4) |
| `FUN_10029bd0` | G_Player.cc | get multiplier / `FUN_10029fd0` reset to 1 | HIGH | dump (player-physics.md, scoring-bonuses.md §4) |
| `FUN_10029be0` | G_Player.cc | get / set flag +0xbd (`FUN_10029bf0`) | LOW | dump (player-physics.md) |
| `FUN_10029c00` | G_Player.cc | advance / re-assign the player's weapon of a type for the sector (no direct caller) | MED | read (weapons-projectiles.md §5); player-physics.md rates it LOW |
| `FUN_10029cb0` | G_Player.cc | get +0xc0 (level ref) | MED | dump (player-physics.md) |
| `FUN_10029cc0` | G_Player.cc | become active / respawn: start pos, v 0, state 4, appear fade, spawn entry unit | HIGH | disasm (player-physics.md §4.1) |
| `FUN_10029f10` | G_Player.cc | reset ship sprite/frame; `FUN_10029f60` ship sprite = displayed weapon's appearance face | HIGH | disasm (player-physics.md, weapons-projectiles.md §5) |
| `FUN_1002a150` | G_Player.cc | life-state step (entering, dying, lives decrement, game over, invulnerability expiry) | HIGH | disasm (player-physics.md §4) |
| `FUN_1002a450` | G_Player.cc | load-and-check a permanent unit def | MED | strings (player-physics.md) |
| `FUN_1002a4f0` | (static init) | spawn-request template statics | LOW | dump (player-physics.md) |
| `FUN_1002a5b0` | G_Debris.cc (span) | register / tear down (`FUN_1002a610`) "Debris" + NUMDEBRIS console command | MED | strings (player-physics.md) |
| `FUN_1002a6d0` | G_Debris.cc | add debris rect | HIGH | decompile + assert string (damage-health-death.md §2.4) |
| `FUN_1002a830` | G_Debris.cc | rect vs debris list (inclusive) | MED | decompile (damage-health-death.md §2.4) |
| `FUN_1002ba00` | G_WeaponDefinitions.cc | parse weapon definition | HIGH | read |
| `FUN_1002ab20` | G_WeaponDefinitions.cc | build master weapon list (wede tags in index order) | HIGH | read; caller `FUN_1002aa90` (weapons-projectiles.md §1.1) |
| `FUN_1002acf0` | G_WeaponDefinitions.cc | i-th weapon definition | HIGH | read (weapons-projectiles.md §1.3) |
| `FUN_1002adb0` | G_WeaponDefinitions.cc | next weapon of type available at level after current (wraps; `none` → first) | HIGH | listing `1002ae30…1002ae8c` (weapons-projectiles.md §2.4) |
| `FUN_1002aec0` | G_WeaponDefinitions.cc | list of unit IDs a weapon references | HIGH | read (weapons-projectiles.md §1.3) |
| `FUN_1002b150` | G_WeaponDefinitions.cc | is unit referenced by any weapon (no caller found) | MED | read (weapons-projectiles.md §1.3) |
| `FUN_1002b240` | G_WeaponDefinitions.cc | free ID list | HIGH | read (weapons-projectiles.md §1.3) |
| `FUN_1002b2a0` | G_WeaponDefinitions.cc | weapon-def defaults (magic, none IDs, sound defaults) | HIGH | read + image `0x100d7014` (weapons-projectiles.md §1.2) |
| `FUN_1002b3a0` | G_WeaponDefinitions.cc | preload PEAA/PEAG/SPEC weapons for the level | HIGH | read; caller `FUN_100064d0` (weapons-projectiles.md §1.1) |
| `FUN_1002b400` | G_WeaponDefinitions.cc | collect weapon sprite (1) / sound (0) IDs (no caller found) | MED | read (weapons-projectiles.md §1.3) |
| `FUN_1002b590` | G_WeaponDefinitions.cc | free master weapon list | HIGH | read (weapons-projectiles.md §1.1) |
| `FUN_1002b6d0` | G_WeaponDefinitions.cc | preload weapons of a type at a level | HIGH | read (weapons-projectiles.md §1.1) |
| `FUN_1002b790` | G_WeaponDefinitions.cc | preload one weapon's sprites / sound / units | HIGH | read (weapons-projectiles.md §1.1) |
| `FUN_1002b8e0` | G_WeaponDefinitions.cc | load i-th wede tag (0x208-byte def) | HIGH | read (weapons-projectiles.md §1.1) |
| `FUN_1002c490` | G_WeaponDefinitions.cc | init weapon spawn record (0x34) | HIGH | read (weapons-projectiles.md §1.2) |
| `FUN_1003beb0` | G_WeaponHandler.cc | start bomb salvo: n = min(sector + F151 − 1, F152) | HIGH | listing `1003beec…1003bf58` — ⚑ corrected (wave 1, 2026-10-03): was "bomb count default/max" MED; see weapons-projectiles.md §2.7 |
| `FUN_1003b3c0` | G_WeaponHandler.cc | per-tick weapon handler: held counters, release, power-ups, select (SND18), air fire, bomb salvo, crosshair, launches; returns 1 overload / 2 release | HIGH | listing — ⚑ corrected (wave 1, 2026-10-03): was "weapon selector switch" MED; see weapons-projectiles.md §2.3 |
| `FUN_1003ade0` | G_WeaponHandler.cc | weapons-handler setup: reset, crosshair fade rates F149/150, default ground weapon (DEAG) + starting air weapon (`FUN_1003cdb0`) | HIGH | listing `1003ae48…1003af3c` — ⚑ corrected (wave 1, 2026-10-03): was "crosshair fade" MED; see weapons-projectiles.md §2.1 |
| `FUN_1003cca0` | G_WeaponHandler.cc | first weapon whose default is DEAA (arg 0) / DEAG (arg ≠ 0); level ignored | HIGH | read + caller listing — ⚑ corrected (wave 1, 2026-10-03): was "is default air/ground weapon (DEAA/DEAG)" MED; see weapons-projectiles.md §2.4 |
| `FUN_1003c0d0` | G_WeaponHandler.cc | air power-up machine: activation on held ≥ +0x1c8; level step every +0x1d0+1 ticks to max +0x1d4; overload at activation + +0x1d8 → return 1; release (or DoReleaseOnMaxPowerLevel) → state 3 + `FUN_10034ce0`, spawns every +0x1e0+1 | HIGH | listing `1003c148…1003c4d4` — ⚑ corrected (review 2026-10-03) #9 — ⚑ corrected (wave 1, 2026-10-03): was "air-weapon power-up state machine: spawn power-up unit (+0x1cc) after delay +0x1c8; charge … overload after +0x1d8 (state 2); release at max if +0x1e4 (state 3, `FUN_10034ce0`)" MED; see weapons-projectiles.md §2.5 |
| `FUN_1003c4f0` | G_WeaponHandler.cc | GROUND weapon launch: spawn records with speed ratio to the crosshair distance, then `crosshairSpawnOnActivation` (+0x180); the air launch is `FUN_1003c7a0` | HIGH | listing `1003c578…1003c784` — ⚑ corrected (review 2026-10-03) #9 — ⚑ corrected (wave 1, 2026-10-03): was "launch weapon: spawn each `spawn_*` record (unit +0x20 at player pos + XLoc/YLoc, heading +0x2c/+0x30) via `FUN_10033220`, then `crosshairSpawnOnActivation` (+0x180)" MED; see weapons-projectiles.md §3.2 |
| `FUN_1003af90` | G_WeaponHandler.cc | handler reset (arg 1: auto-equip weapon unlocked at sector; pending apply; keeps weapons) | HIGH | listing `1003b0ac…1003b134` (weapons-projectiles.md §2.4) |
| `FUN_1003b180` | G_WeaponHandler.cc | set weapon of type (immediate if no power-up active, else pending); AUX toggle | HIGH | listing (weapons-projectiles.md §2.4) |
| `FUN_1003b340` | G_WeaponHandler.cc | current weapon of type | HIGH | read (weapons-projectiles.md §2.2) |
| `FUN_1003bab0` | G_WeaponHandler.cc | crosshair locked/unlocked frame | HIGH | listing (weapons-projectiles.md §2.8) |
| `FUN_1003bb00` | G_WeaponHandler.cc | set handler x,y | HIGH | read (weapons-projectiles.md §2.2) |
| `FUN_1003bb20` | G_WeaponHandler.cc | get air power percent (+0x24) | HIGH | listing (weapons-projectiles.md §2.5) |
| `FUN_1003bb30` | G_WeaponHandler.cc | get weapon-list-changed flag | HIGH | listing (weapons-projectiles.md §2.2) |
| `FUN_1003bb40` | G_WeaponHandler.cc | score-bar weapon icons (cur / next / next) | HIGH | read (weapons-projectiles.md §5) |
| `FUN_1003bce0` | G_WeaponHandler.cc | displayed air weapon (pending else current) | HIGH | listing (weapons-projectiles.md §2.4) |
| `FUN_1003bd00` | G_WeaponHandler.cc | draw crosshair | HIGH | read (weapons-projectiles.md §2.8) |
| `FUN_1003bd40` | G_WeaponHandler.cc | debug log of handler (no caller) | MED | read (weapons-projectiles.md §5) |
| `FUN_1003bf80` | G_WeaponHandler.cc | air fire timing (cooldown + edge unless autoRepeat) | HIGH | listing (weapons-projectiles.md §2.4) |
| `FUN_1003bff0` | G_WeaponHandler.cc | aux fire timing | MED | read (weapons-projectiles.md §2.4) |
| `FUN_1003c7a0` | G_WeaponHandler.cc | AIR weapon launch: spawn records at player pos + XLoc/YLoc → `FUN_10033220` | HIGH | listing (weapons-projectiles.md §3.2) |
| `FUN_1003c940` | G_WeaponHandler.cc | aux weapon launch | MED | read (weapons-projectiles.md §3.2) |
| `FUN_1003cb30` | G_WeaponHandler.cc | free aux records | HIGH | read (weapons-projectiles.md §5) |
| `FUN_1003cbf0` | G_WeaponHandler.cc | find aux record by weapon ID | HIGH | read (weapons-projectiles.md §5) |
| `FUN_1003cd30` | G_WeaponHandler.cc | PEAA weapon with min level == L | HIGH | listing (weapons-projectiles.md §2.4) |
| `FUN_1003cdb0` | G_WeaponHandler.cc | starting air weapon: available PEAA with highest min level | HIGH | listing (weapons-projectiles.md §2.4) |
| `FUN_1003ce60` | G_WeaponHandler.cc (span) | static init of spawn-request templates | MED | read (weapons-projectiles.md §3.1) |
| `FUN_1002c550` |  | locate key from cursor | HIGH | read |
| `FUN_1002c630` |  | locate key from start | HIGH | read |
| `FUN_1002c700` |  | locate '#' item | HIGH | read |
| `FUN_1002c7d0` |  | read ID | HIGH | read |
| `FUN_1002c880` |  | read INT | HIGH | read |
| `FUN_1002c960` |  | read FLOAT | MED | strings |
| `FUN_1002ca40` |  | read BOOL | HIGH | read |
| `FUN_1002cb20` |  | read STR | MED | usage |
| `FUN_1002cbd0` |  | read COLOR | HIGH | read |
| `FUN_1002cc90` | U_Token.cc | read RECT | HIGH | read |
| `FUN_1002ce60` |  | parse error report | HIGH | read |
| `FUN_1002c4d0` |  | set parse context name/log flag | HIGH | read |
| `FUN_1002c540` |  | parse error flag | HIGH | read |
| `FUN_1002d080` |  | register console command | MED | strings — ⚑ corrected (review 2026-10-03) #8: was HIGH on string/import/usage evidence only |
| `FUN_1002d1a0` |  | open console | MED | perm SND1 |
| `FUN_1002d190` |  | console is open | MED | usage |
| `FUN_1002d770` |  | console command result sound | MED | perm SND4/5 |
| `FUN_1002dbd0` |  | show game message | MED | perm F24 |
| `FUN_1002dd90` |  | message aging | MED | perm F25/26 |
| `FUN_10030190` |  | frame controller construct | MED | read |
| `FUN_10030210` |  | frame controller start session | MED | read |
| `FUN_100302e0` | ~after G_LevelSelection | between-level frame-controller reset | MED | read (scoring-bonuses.md §10.4) |
| `FUN_10030350` | ~after G_LevelSelection | frame counter getter | MED | read (scoring-bonuses.md §10.4) |
| `FUN_10030020` | ~after G_LevelSelection | static inits / struct zero / Score Bar release / destructor / end-session / byte getter (`FUN_10030020` / `FUN_10030e70` / `FUN_10030df0` / `FUN_100313b0` / `FUN_100301d0` / `FUN_100302b0` / `FUN_10030900`) | LOW | read (scoring-bonuses.md §10.4) |
| `FUN_10030360` |  | begin frame: keys, console, pause, quit | HIGH | read |
| `FUN_10030570` |  | end frame wrapper | HIGH | read |
| `FUN_10030bc0` |  | end frame: render layers, FPS limiter, speed divider, present | HIGH | read |
| `FUN_100307b0` |  | tick-this-frame flag | HIGH | disasm |
| `FUN_100307c0` |  | Esc quit (hold > 30 frames if pref 8) | HIGH | disasm |
| `FUN_10030910` |  | -/= volume, F6 interlace keys | HIGH | read |
| `FUN_10030640` |  | FPS monitor + auto interlace | MED | read |
| `FUN_100305e0` |  | FPS monitor init | MED | read |
| `FUN_10030790` |  | reset speed divider | HIGH | read |
| `FUN_10030870` |  | pause handling | MED | read |
| `FUN_10030f40` |  | score bar rects | MED | perm R0-15 |
| `FUN_100317e0` |  | score bar meters update | MED | perm F120-127 |
| `FUN_10032050` |  | lives display | MED | perm F143 |
| `FUN_10033850` |  | update all entities (state machine, collisions, scroll pause) | HIGH | read |
| `FUN_100345f0` | G_EntityGroup.cc | per-entity debug labels (state name of a watched unit, unit IDs, "Ground Accuracy" on includeInGroundAccuracyCount units; flags `DAT_100e021c..f`, cleared in `FUN_10032bd0`) + shadow draw for castsShadows (+0x11e) entities; called from draw world `FUN_10007070` | MED | read — ⚑ corrected (review 2026-10-03) #9 |
| `FUN_10033090` | G_EntityGroup.cc (span) | spawn pending level objects whose yLoc == row; request y flagged "map row"; record always removed | HIGH | listing — ⚑ corrected (wave 1, 2026-10-03): was "spawn level objects at a scroll row" HIGH; see level-scroll-objects.md §6.3 |
| `FUN_10033220` |  | spawn request (group, limits) | HIGH | read |
| `FUN_10035900` | G_EntityGroup.cc | build pending level-object list; x −= 32 iff unit `isGroundBased` (unit+8 == `grnd`); placement `#layer_ID` unused | HIGH | listing `10035abc` — ⚑ corrected (wave 1, 2026-10-03): was "build pending level-object list" HIGH; see level-scroll-objects.md §6.2 |
| `FUN_100369f0` |  | group size with appearsPercent; size draw args are `R(min′,max)` | HIGH | disasm — ⚑ corrected (wave 1, 2026-10-03): was "group size with appearsPercent" HIGH (waves §4 said the args were dropped, MED); see spawn-and-waves.md §3.1 |
| `FUN_10035bf0` |  | spawn group members | HIGH | read |
| `FUN_10035cd0` |  | create one entity (shields by sector, spawn delay) | HIGH | read |
| `FUN_10037930` | G_EntityGroup.cc (span) | member placement: x/yOffsetMin/Max rectangular or radial, randomiseInitialLoc | HIGH | disasm (waves-and-enemies.md §4) — ⚑ corrected (review 2026-10-03) #2 |
| `FUN_10037b50` | G_EntityGroup.cc (span) | initial motion: stationary / supplied heading / hunt closest / burst-implode (y negated) / default heading ± tolerance; speed FloatRandomRange(min,max) × request multiplier | HIGH | disasm — ⚑ corrected (review 2026-10-03) #2 — ⚑ corrected (wave 1, 2026-10-03): was "initial speed (float draw initialSpeedMin/Max) + initial heading (± tolerance draw) / hunt / burst" MED; see spawn-and-waves.md §3.3 |
| `FUN_10012910` | G_GameObject (span) | set entity position (x,y) | HIGH | dump; callers `FUN_10037930`, `FUN_10028170` — ⚑ corrected (review 2026-10-03) #2 — ⚑ corrected (wave 1, 2026-10-03): was "set entity position (x,y)" MED; see units-movement.md §2.1 |
| `FUN_100351f0` | G_EntityGroup.cc | count entities of a unit whose spawn delay is over (rules #14–16) | HIGH | dump — ⚑ corrected (wave 1, 2026-10-03): was "count live entities of a unit" MED; see bosses.md §3.1 |
| `FUN_100352f0` | G_EntityGroup.cc | rule #4: any entity whose unit has includeInAirAccuracyCount (+0x133); no live/on-screen test | HIGH | dump; caller `FUN_10015550` — ⚑ corrected (wave 1, 2026-10-03): was "any destroyable air entity" MED; see bosses.md §3.1 |
| `FUN_100353e0` | G_EntityGroup.cc | rule #5: any entity whose unit has includeInGroundAccuracyCount (+0x134) and is on screen (`FUN_10016bd0`) | HIGH | dump; caller `FUN_10015550` — ⚑ corrected (wave 1, 2026-10-03): was "any destroyable ground entity" MED; see bosses.md §3.1 |
| `FUN_10034ee0` | G_EntityGroup.cc | rule "Is Tracking Player": live entity of unit with +0xc1 set, dist ≤ range (0 = any) | HIGH | disasm (spawn-and-waves.md §6) |
| `FUN_10035070` | G_EntityGroup.cc | rule #2 "Is Active": live entity of unit, dist ≤ range (0 = any) | HIGH | disasm (spawn-and-waves.md §6); bosses.md §3.1 MED |
| `FUN_10036cf0` | G_EntityGroup.cc | entity↔entity collision: same layer (unit+8), harmless XOR, playerProjectile (+0x11b) / canBeHitByPlayerProjectile (+0x11c) pairing, AABB then circle (`FUN_10042f80`); A takes B.damage_FLOAT (to A's owner if passHitsToOwner), then B takes A.damage via `FUN_10014f10` (B-side passHitsToOwner also redirects to A's owner — bug); returns A deleted. Called per entity whose state has Collides (+0x347). NOT the spawn-set executor (that is `FUN_10015b40`) | HIGH | raw `10036fc4..100370e8` (`lfs f1,0x274(r4)`), dump; caller `FUN_10033850` (`10034594 bl`) — ⚑ corrected (wave 1, 2026-10-03): was "state spawn sets executor" LOW; see damage-health-death.md §2.5, spawn-and-waves.md §7, bosses.md §3.4 |
| `FUN_10032e60` | G_EntityGroup.cc | level start: reset groups, notice list, id counters, create PERM group, pending list | HIGH | disasm (spawn-and-waves.md §8) |
| `FUN_10033600` | G_EntityGroup.cc | owner-relative init: offset, orbit radius/angle, owner last pos | HIGH | disasm (spawn-and-waves.md §4) |
| `FUN_10034b90` | G_EntityGroup.cc | player gone: destroy (0x329) / delete (0x32a) entities owned by that player; caller `FUN_10027e50` | MED | read (spawn-and-waves.md §5, damage-health-death.md §4.3) |
| `FUN_10034ce0` | G_EntityGroup.cc | find entity by serial (+0x9c) → `FUN_10014670` (switch to its UseThisStateOnWeaponPowerupRelease state; arg 1 = time); callers `FUN_1003b3c0`, `FUN_1003c0d0` | HIGH | read (weapons-projectiles.md §2.3, §2.5) — ⚑ conflict: spawn-and-waves.md §5 reads it as "set named state on entity by id" (arg 1 = state name, MED); the dump passes arg 1 through `FUN_10014670` as the time argument of `FUN_100146f0` |
| `FUN_10034de0` | G_EntityGroup.cc | delete entity by id; callers `FUN_10027e50`, `FUN_10029fe0` | MED | read (spawn-and-waves.md §5) |
| `FUN_10035580` | G_EntityGroup.cc | active group count | MED | read (spawn-and-waves.md §8) |
| `FUN_100355b0` | G_EntityGroup.cc | debug integrity check / dump (no direct callers) | MED | read (spawn-and-waves.md §8) |
| `FUN_10035810` | G_EntityGroup.cc | free pending level-object list | MED | read (spawn-and-waves.md §8) |
| `FUN_10035b00` | G_EntityGroup.cc | free all groups | MED | read (spawn-and-waves.md §8) |
| `FUN_10036120` | G_EntityGroup.cc | remove entity from group: destroy/delete children, kill count, destruct coins, group-kill coin (non-PERM), destruction, live count; returns empty-non-PERM | HIGH | disasm (spawn-and-waves.md §5); damage-health-death.md §4.3, bosses.md §3.5 MED |
| `FUN_100363c0` | G_EntityGroup.cc | destroy children whose state has canBeDestroyedOnOwnerDestruction | MED | read (spawn-and-waves.md §5, bosses.md §3.5) |
| `FUN_100364f0` | G_EntityGroup.cc | delete children whose state has canBeDeletedOnOwnerDeletion | MED | read (spawn-and-waves.md §5) |
| `FUN_10036610` | G_EntityGroup.cc | per-tick reaper of +0xcb entities: ground count, draw-to-terrain, destroy owner, deletion spawn, `FUN_10036120`, free entity / empty non-PERM group | HIGH | disasm (spawn-and-waves.md §5); damage-health-death.md §4.3 MED; call at `100345d4` |
| `FUN_10036930` | G_EntityGroup.cc | copy owner visibility / scale / hit-glow fields (useOwners*, visuallyReflectOwnerHits) | HIGH | raw `10033f4c..10033f58` args (bosses.md §3.5); spawn-and-waves.md §4 MED |
| `FUN_10036ab0` | G_EntityGroup.cc | owner link valid (ptr, serial +0x9c, not deleted) | HIGH | dump 1-liner (spawn-and-waves.md §1.3, damage-health-death.md §4.3, bosses.md §3.5) |
| `FUN_10036af0` | G_EntityGroup.cc | first live entity of a unit | MED | read (spawn-and-waves.md §8) |
| `FUN_10036be0` | G_EntityGroup.cc | remove entities of a unit owned by a player (deleteExisting…) | MED | read (spawn-and-waves.md §3.1) |
| `FUN_10037130` | G_EntityGroup.cc | LockToOwnerLoc: pos = owner + offset | HIGH | disasm (spawn-and-waves.md §4) |
| `FUN_10037230` | G_EntityGroup.cc | LinkToOwnerLoc: pos += owner displacement | HIGH | disasm (spawn-and-waves.md §4) |
| `FUN_10037350` | G_EntityGroup.cc | OrbitOwner: angle += trunc(+0x10) deg/tick at radius | HIGH | disasm (spawn-and-waves.md §4) |
| `FUN_10037580` | G_EntityGroup.cc | player-contact pickup by pickup_Type_ID: coin → money += pickup_Value; exli → life; mult → multiplier step; shie → shields; air/grnd only check player +0xce; other → 1 (entity destroyed) | HIGH | listing `10037580–100376f0` (damage-health-death.md §6, weapons-projectiles.md §4); scoring-bonuses.md §5.1 MED for shie/other; spawn-and-waves.md MED |
| `FUN_100377f0` | G_EntityGroup.cc | debug tracked-entity spawn notice | MED | read (spawn-and-waves.md §8) |
| `FUN_10037ed0` | G_EntityGroup.cc | cyclic-motion start velocity (5–6 int draws) | HIGH | disasm (spawn-and-waves.md §3.4) |
| `FUN_100380e0` | G_EntityGroup.cc | entry notice (once-only list, delay, sound) | MED | read (spawn-and-waves.md §8) |
| `FUN_10038230` | G_EntityGroup.cc | notice already shown? | MED | read (spawn-and-waves.md §8) |
| `FUN_100382f0` | G_EntityGroup.cc | add shown notice | MED | read (spawn-and-waves.md §8) |
| `FUN_10038390` | G_EntityGroup.cc | build entity pool (1000 × 0x1ec) | MED | read (spawn-and-waves.md §1.3) |
| `FUN_10038450` | G_EntityGroup.cc | reset entity pool flags | MED | read (spawn-and-waves.md §1.3) |
| `FUN_10038540` | G_EntityGroup.cc | dispose entity pool | MED | read (spawn-and-waves.md §1.3) |
| `FUN_100385d0` | G_EntityGroup.cc | allocate pooled entity | MED | read (spawn-and-waves.md §1.3) |
| `FUN_10038810` | G_EntityGroup.cc (span) | free pooled entity | MED | read (spawn-and-waves.md §1.3) |
| `FUN_10039100` | ~after G_EntityGroup | static init of request templates | LOW | read (spawn-and-waves.md §8) |
| `FUN_100391f0` | G_PlayerDefinitions.cc | player-definition module init ("Player Definition", builds list); `FUN_10039230` unload | LOW | strings (spawn-and-waves.md §8, unit-def-struct.md §9) |
| `FUN_10039280` | G_PlayerDefinitions.cc | build player-definition list | HIGH | read (unit-def-struct.md §9) |
| `FUN_10039460` | G_PlayerDefinitions.cc | plde index by tag ID (−1 if none) | HIGH | read (unit-def-struct.md §9) |
| `FUN_10039520` | G_PlayerDefinitions.cc | i-th plde record | MED | read (unit-def-struct.md §9) |
| `FUN_100395d0` | G_PlayerDefinitions.cc | unit referenced by plde / free list / collect IDs / free plde list (`FUN_100395d0` / `FUN_10039940` / `FUN_10039a80` / `FUN_10039c00`) | MED | read (unit-def-struct.md §9) |
| `FUN_100396c0` | G_PlayerDefinitions.cc | plde referenced unit IDs; `FUN_100399a0` load plde resources | HIGH | read (unit-def-struct.md §9) |
| `FUN_10039cf0` | G_PlayerDefinitions.cc | load plde i (0x108 record, defaults, parse, error ⇒ fatal) | HIGH | listing (unit-def-struct.md §9) |
| `FUN_10039e70` | G_PlayerDefinitions.cc | parse plde: 57 keys → offsets 0x008–0x107 (table in unit-def-struct.md §9 and player-physics.md role rows) | HIGH | listing reader calls `10039ee8..1003a758` (unit-def-struct.md §9, player-physics.md) |
| `FUN_1003a780` | U_Manager.cc | manager init ("Manager God") | MED | strings (unit-def-struct.md §9) |
| `FUN_1003cf10` | G_UnitDefinitions.cc | unit manager init: debug console commands (LOGSCROLLPAUSERS, LOGFAMILIES, LOGUNUSEDUNITS), Units Cache load or master-list build | HIGH | read (unit-def-struct.md §1); weapons-projectiles.md MED, bosses.md LOW (strings only) |
| `FUN_1003d030` | G_UnitDefinitions.cc | unit-defs module teardown | MED | read (weapons-projectiles.md §5) |
| `FUN_1003d0a0` | G_UnitDefinitions.cc | build master unit list; numStates check passes 0..20 (log + assert only < 0 or > 20) | HIGH | listing `1003d1bc–1003d218` — ⚑ corrected (wave 1, 2026-10-03): was "build master unit list (1..20 states)" HIGH; see unit-def-struct.md §2.5 |
| `FUN_1003d650` | G_UnitDefinitions.cc | compiler copy-assignment of unit `fileData` (unit+0xc, 0x7a54 B); only for the Units Cache writer `FUN_10041e40` | HIGH | listing `1003d904–1003dcb8` — ⚑ corrected (review 2026-10-03) #9 — ⚑ corrected (wave 1, 2026-10-03): was "unit-definition struct copy (field-by-field assignment)" MED; see unit-def-struct.md §1 |
| `FUN_1003fc50` | G_UnitDefinitions.cc | load unit i: alloc 0x7a60, defaults, parse, error ⇒ fatal; sets unit+8 layer = `grnd` if isGroundBased else `air ` (the collision layer) | HIGH | listing; raw `1003fd20..1003fd44` (bosses.md, level-scroll-objects.md) — ⚑ corrected (wave 1, 2026-10-03): was "load unit i" MED; see unit-def-struct.md §1, bosses.md §3.4, level-scroll-objects.md §6.2 |
| `FUN_1003fda0` | G_UnitDefinitions.cc | parse unit definition | HIGH | read |
| `FUN_10040920` | G_UnitDefinitions.cc | parse one state | HIGH | read |
| `FUN_1003d2f0` | G_UnitDefinitions.cc | find unit definition by ID (unit+4 = tag) | HIGH | listing `1003d35c` — ⚑ corrected (wave 1, 2026-10-03): was "find unit definition by ID" MED; see unit-def-struct.md §1 |
| `FUN_1003e680` | G_UnitDefinitions.cc | load/verify a unit's sounds + sprites, recurse into referenced units | HIGH | read — ⚑ corrected (wave 1, 2026-10-03): was "load unit resources (sounds/sprites)" MED; see unit-def-struct.md §1 |
| `FUN_1003f4e0` | G_UnitDefinitions.cc | add unit to family list (0x4c family records) | HIGH | read — ⚑ corrected (wave 1, 2026-10-03): was "add unit to family list" MED; see unit-def-struct.md §1 |
| `FUN_1003d3a0` | G_UnitDefinitions.cc | i-th unit of the master list | MED | read (unit-def-struct.md §1) |
| `FUN_1003d450` | G_UnitDefinitions.cc | family record of a unit (" Misc" if no family name) | HIGH | read; `0x100ed01f` (unit-def-struct.md §1) |
| `FUN_1003d550` | G_UnitDefinitions.cc | find unit by ID, family list first then global | MED | read (unit-def-struct.md §1) |
| `FUN_1003dce0` | G_UnitDefinitions.cc | copy state sub-blocks (`FUN_1003dce0` / `FUN_1003dd60` / `FUN_1003ddc0` / `FUN_1003de00` / `FUN_1003de30` / `FUN_1003de70` / `FUN_1003dfb0`: +0x324 owner bools, +0x300 anim, +0x2ec blur, +0x2e0 collision, +0x2d0 particles, +0x024 rules, +0x000 sound) | HIGH | listing (unit-def-struct.md §1) |
| `FUN_1003e020` | G_UnitDefinitions.cc | copy unit sub-blocks (`FUN_1003e020` / `FUN_1003e040` / `FUN_1003e120` / `FUN_1003e1a0`: pickup, destruct, shields + 2 sounds, sound record) | HIGH | listing (unit-def-struct.md §1) |
| `FUN_1003e1e0` | G_UnitDefinitions.cc | unit-definition defaults (incl. 20 states, state 0 "State 1") | HIGH | listing (unit-def-struct.md §3) |
| `FUN_1003e3d0` | G_UnitDefinitions.cc | state defaults | HIGH | listing (unit-def-struct.md §4) |
| `FUN_1003e490` | G_UnitDefinitions.cc | spawn-set defaults | HIGH | listing (unit-def-struct.md §6) |
| `FUN_1003e510` | G_UnitDefinitions.cc | reset loaded-unit-resources list | HIGH | string + callers (unit-def-struct.md §1) |
| `FUN_1003e580` | G_UnitDefinitions.cc | load resources of a unit ID | HIGH | listing (unit-def-struct.md §1) |
| `FUN_1003ec70` | G_UnitDefinitions.cc | list unit IDs referenced by a unit | HIGH | read (unit-def-struct.md §1) |
| `FUN_1003ef90` | G_UnitDefinitions.cc | is unit referenced by another unit (LOGUNUSEDUNITS) | MED | read (unit-def-struct.md §1) |
| `FUN_1003f0b0` | G_UnitDefinitions.cc | collect all unit sprite/sound IDs into a list | MED | read (unit-def-struct.md §1) |
| `FUN_1003f280` | G_UnitDefinitions.cc | master-list integrity check (magic 0x499602d2) | HIGH | listing (unit-def-struct.md §1) |
| `FUN_1003f360` | G_UnitDefinitions.cc | free master list / ID list / family list / family / resource list (`FUN_1003f360` / `FUN_1003f410` / `FUN_1003f830` / `FUN_1003fa10` / `FUN_1003fa80`) | MED | read (unit-def-struct.md §1) |
| `FUN_1003f470` | G_UnitDefinitions.cc | rule-block defaults (5 rules) | HIGH | listing (unit-def-struct.md §5) |
| `FUN_1003f8b0` | G_UnitDefinitions.cc | log family table | MED | strings (unit-def-struct.md §1) |
| `FUN_1003fb60` | G_UnitDefinitions.cc | test-and-insert unit ID into the loaded-resources list | HIGH | read (unit-def-struct.md §1) |
| `FUN_10041960` | G_UnitDefinitions.cc | sprite (parse time) / sound / sprite (load time) existence check, else `'none'` (`FUN_10041960` / `FUN_100417d0` / `FUN_100418a0`) | HIGH | read (unit-def-struct.md §2) |
| `FUN_10041e40` | G_UnitDefinitions.cc | Units Cache writer (format unit-def-struct.md §8) | HIGH | read (unit-def-struct.md §8) — ⚑ corrected (wave 1, 2026-10-03): the fix-pass note named `FUN_100420f0` as the writer |
| `FUN_100420f0` | G_UnitDefinitions.cc | Units Cache reader / validator | HIGH | read (unit-def-struct.md §8) — ⚑ corrected (wave 1, 2026-10-03): was "Units Cache writer" (function-roles.md §1 fix-pass notes, unread); see unit-def-struct.md §8 |
| `FUN_100426e0` | ? (after G_UnitDefinitions) | write a data file in the Data folder (Units Cache helper) | MED | strings; caller `FUN_10041e40` (damage-health-death.md §1) |
| `FUN_100428b0` | ? | static initialiser copying constant records | LOW | decompile (damage-health-death.md §1) |
| `FUN_100431f0` | ? | init: two RandomRange(0,99) + `FUN_1002d080`; `FUN_10043280` teardown | LOW | decompile; caller `FUN_100000e0` (damage-health-death.md §1) |
| `FUN_100438c0` |  | particles update (gravity) | MED | perm F144/148 |
| `FUN_10043340` | G_Particle.cc | emit particles | MED | perm F145/146 |
| `FUN_10046840` |  | emit motion blur | LOW | caller |
| `FUN_10047160` | M_Sound.cpp | sound init (channels) | MED | strings |
| `FUN_10047330` | M_Sound.cpp | load sound effect tag | HIGH | read |
| `FUN_10047bf0` |  | play sound by ID | MED | strings |
| `FUN_10047670` |  | play sound (id, volume…) | MED | wrapper |
| `FUN_100475e0` |  | play sound from settings block | MED | read |
| `FUN_100476e0` |  | is sound playing | MED | usage |
| `FUN_10047990` |  | volume down | LOW | key handler |
| `FUN_10047a30` |  | volume up | LOW | key handler |
| `FUN_100d1780` |  | convert AIFF/AIFC/WAV (NONE/ima4, mono) to playable | HIGH | read |
| `FUN_10047e40` | M_Music.cpp | music init (spool buffer) | MED | strings |
| `FUN_10047f90` |  | play music tag streamed from pak | HIGH | read |
| `FUN_10048120` |  | stop/fade music | LOW | string |
| `FUN_100cfe64` |  | file stream player (SndPlayDoubleBuffer) | MED | imports |
| `FUN_1004a8b0` |  | input init | MED | read |
| `FUN_1004abd0` |  | InputSprocket needs + init | HIGH | read |
| `FUN_1004afa0` |  | InputSprocket poll -> 2x7 bytes | HIGH | read |
| `FUN_1004aa20` |  | clear input state | HIGH | read |
| `FUN_1004aa90` |  | copy polled input to game input | HIGH | read |
| `FUN_1004ab50` |  | get player n input (7 bytes) | MED | read |
| `FUN_1004ae00` |  | ISpConfigure dialog | MED | import |
| `FUN_10004f20` |  | reset byte/int pref defaults (limiter on, sector 1) | HIGH | read |
| `FUN_10010fc0` | M_Configuration.cc | configuration dialog (pref toggles, sliders, ISpConfigure) | MED | read |

Fix-pass notes (⚑ corrected (review 2026-10-03)):
- #9 completeness: 649 of the 979 `FUN_` below `0x1004b400` are mentioned nowhere in the bank.
  Rows added above for the heavy ones the review named (`FUN_1003c0d0`, `FUN_1003c4f0`,
  `FUN_10019570`, `FUN_100345f0`, `FUN_1003d650`, `FUN_1002f7a0`). Named by the review but still
  unread: `FUN_10036610`/`FUN_10036120` (G_EntityGroup.cc span, `PERM` compares),
  `FUN_1003e1e0` (unit-def defaults, "State 1"), `FUN_100420f0` (Units Cache writer).
- The review's hint that `COST` is a level-selection cost is wrong: `0x434f5354` is a sprite
  draw type for a translucent colour rectangle (`FUN_10019570` → `FUN_1001ec80`; used for button
  hilites in `FUN_1002f7a0` and four other draw sites).
- **Starting bonus — uncovered.** `Game[pgsl]` lines 3 "- Starting Bonus $", 4 "Sector Not
  Reached", 6 "- No Starting Bonus" imply a money bonus for starting at a later sector. Only
  line 4 has a literal consumer (`FUN_10020260(4)` in the level-selection screen `FUN_1002e310`,
  shown when the chosen sector's `+0x2c4` flag is clear); `grep 'FUN_10020260(3)'` / `(6)` → no
  call sites (the index may be computed). Rule NOT RESOLVED (INDEX #28).
  ⚑ corrected (wave 1, 2026-10-03): no starting bonus exists in 1.0.6 code — pgsl 3/6 have no
  consumer in a raw scan; a later start sector gives 1 life instead of 3 and the matching `PEAA`
  weapon (scoring-bonuses.md §9.3, §10.3; player-physics.md §7; level-scroll-objects.md §8).

Wave 1 notes (⚑ wave 1, 2026-10-03; nine topical files, rows merged above, pending Fable review):
- **Spawn executor relabel:** the state spawn-set executor is `FUN_10015b40` (with arming in
  `FUN_10017cb0` and the rotation gate `FUN_10017150`), not `FUN_10036cf0`; it runs for every
  on-screen entity, controllers included (spawn-and-waves.md §2, bosses.md §3.3, units-movement.md §9).
- **Collision:** `FUN_10036cf0` is entity↔entity collision with mutual `damage_FLOAT`;
  `FUN_10042f80` is a strict circle-overlap test (not a pixel/shape test); layers come from
  `isGroundBased` via `FUN_1003fc50` (damage-health-death.md §2, bosses.md §3.4).
- **Player hit / death:** the player hit is `FUN_10027100` (was "player hit spawn delay");
  `FUN_10026c90` is only the player-index getter (was "player takes hit"); player death is
  `FUN_10027e50` (was "coin unit selection") — damage-health-death.md §5, player-physics.md §3,
  scoring-bonuses.md §5.2.
- **Air-weapon launch:** `FUN_1003c4f0` is the GROUND launch; the AIR launch is `FUN_1003c7a0`;
  `FUN_1003b3c0` is the whole per-tick weapon handler (was "weapon selector switch");
  `FUN_1003ade0` is handler setup (was "crosshair fade") — weapons-projectiles.md §2–§3.
- The fix-pass "still unread" list is now read: `FUN_10036610`/`FUN_10036120`
  (spawn-and-waves.md §5), `FUN_1003e1e0` (unit-def-struct.md §3), `FUN_100420f0` (= Units Cache
  reader, not writer; writer `FUN_10041e40`, unit-def-struct.md §8).
- Open conflicts flagged in rows: `FUN_10017150`, `FUN_10034ce0`, `FUN_10010570`.

## 2. Data-key consumers (`perm_consumers.py`)

Command: `python3 docs/deimos/tools/perm_consumers.py ghidra/Deimos_pef.decompiled.c $D/Game`
(F = flli float index, S = pgsl string line, O = gaob object, SND = gaso sound, SPR = gasp sprite,
R = inre rect). The key a function reads is a strong role hint [MED per row]. Output (lines
truncated at 190 chars):
```
FUN_100000e0 100000e0 | F37=SoundSpoolBufferSize ; F38=SoundNumChannels ; F56=ReqDisplayDepth ; F53=MinScreenHeight ; F52=MinScreenWidth ; F66=Interface_PublisherLogoDelay
FUN_100051a0 100051a0 | F18=Game_NumFramesUntilGameAppears ; S9=REPLAY ; F56=ReqDisplayDepth ; F53=MinScreenHeight ; F52=MinScreenWidth
FUN_10006240 10006240 | SPR0=Video Grid ; F84=VideoGrid_NormalFrame ; F85=VideoGrid_DarkFrame
FUN_100064d0 100064d0 | F56=ReqDisplayDepth ; F53=MinScreenHeight ; F52=MinScreenWidth ; F54=VisibleGameWidth ; F55=VisibleGameHeight
FUN_10006b50 10006b50 | O24=Notice_GameOver ; F54=VisibleGameWidth ; F55=VisibleGameHeight ; F13=Game_GameOverNoticeDuration ; O22=Notice_LevelEnd ; O23=Notice_AllLevelsCompleted
FUN_10007170 10007170 | SND3=InterfaceTransition
FUN_100072c0 100072c0 | F188=Game_GroundAccuracyCount_TierPercentageGap ; F194=Game_GroundAccuracyCount_TierValue_6 ; F193=Game_GroundAccuracyCount_TierValue_5 ; F192=Game_GroundAccuracyCoun
FUN_100075e0 100075e0 | F195=Game_GroundAccuracyCount_WaitingToAppear ; F196=Game_GroundAccuracyCount_WaitingToAppearAllLevelsCompleted ; SND20=MoneyCount ; F203=Game_GroundAccuracyCount_Fad
FUN_1000ae20 1000ae20 | F52=MinScreenWidth ; F53=MinScreenHeight ; F59=LeftBorderWidth ; F55=VisibleGameHeight ; F54=VisibleGameWidth ; F57=ScoreBarWidth ; F58=ScoreBarHeight
FUN_1000bc60 1000bc60 | F52=MinScreenWidth ; F53=MinScreenHeight
FUN_1000bd80 1000bd80 | F52=MinScreenWidth ; F59=LeftBorderWidth ; F53=MinScreenHeight
FUN_1000beb0 1000beb0 | F59=LeftBorderWidth ; F53=MinScreenHeight ; F52=MinScreenWidth ; F54=VisibleGameWidth ; F55=VisibleGameHeight
FUN_1000e270 1000e270 | F54=VisibleGameWidth ; F52=MinScreenWidth
FUN_1000e670 1000e670 | F21=Text_ShadowBlendAmount ; F19=Text_ShadowXAdjust ; F20=Text_ShadowYAdjust
FUN_1000fa90 1000fa90 | F55=VisibleGameHeight ; F54=VisibleGameWidth
FUN_1000fbc0 1000fbc0 | F56=ReqDisplayDepth
FUN_10010120 10010120 | F54=VisibleGameWidth ; F55=VisibleGameHeight
FUN_10010220 10010220 | F55=VisibleGameHeight
FUN_10010e90 10010e90 | S35=THIS COPY IS REGISTERED TO %s ; S34=REGISTERED TO %s  [%i COPIES] ; S33=THIS COPY IS UNREGISTERED
FUN_10012ca0 10012ca0 | F54=VisibleGameWidth ; F55=VisibleGameHeight
FUN_10013460 10013460 | F50=Shadow_GroundXOffset ; F51=Shadow_GroundYOffset ; F48=Shadow_XOffset ; F49=Shadow_YOffset
FUN_10014f10 10014f10 | F167=Entity_HitDelay
FUN_10016300 10016300 | F209=Game_RandomBonusPercent_1 ; O25=RandomBonus_1 ; F218=Game_RandomBonusPercent_GroundAccuracyReward ; O30=RandomBonus_6 ; F210=Game_RandomBonusPercent_2 ; O26=Rand
FUN_10016880 10016880 | O7=MediaImpact_Water_Small ; O6=MediaImpact_Water_Tiny ; O8=MediaImpact_Water_Medium ; O9=MediaImpact_Water_Large
FUN_10016bd0 10016bd0 | F54=VisibleGameWidth ; F55=VisibleGameHeight
FUN_10016da0 10016da0 | F54=VisibleGameWidth ; F55=VisibleGameHeight
FUN_10017510 10017510 | F55=VisibleGameHeight ; F54=VisibleGameWidth ; F15=Game_EntityFleeSouthLocation ; F14=Game_EntityFleeNorthLocation ; F17=Game_EntityFleeEastLocation ; F16=Game_Entity
FUN_10018320 10018320 | F71=Notice_AppearanceGameTime ; F72=Notice_FadeInAmount ; F73=Notice_FadeOutAmount
FUN_10021950 10021950 | F77=Scores_YLoc ; F78=Scores_Duration ; SND2=InterfaceClick
FUN_10021bd0 10021bd0 | SND9=HighScoreAchieved ; F78=Scores_Duration ; F79=Scores_DurationBetweenPlayers ; F82=Scores_PromptFlashDelayAfterKeyHit ; F83=Scores_PromptDelayBetweenFlashes ; SND
FUN_100222f0 100222f0 | F77=Scores_YLoc ; O1=Player 2 ; O0=Player 1 ; F80=Scores_SymbolXLoc ; F81=Scores_SymbolYLoc ; F76=Scores_VerticalGap
FUN_100229a0 100229a0 | F68=Interface_CopyrightFlipTime_Ticks
FUN_10022ef0 10022ef0 | SND8=Paused
FUN_10023040 10023040 | F64=Interface_Progress_VerticalGap
FUN_100232d0 100232d0 | F160=Interface_FadeRate
FUN_100234d0 100234d0 | SND3=InterfaceTransition
FUN_10023b00 10023b00 | SND2=InterfaceClick
FUN_10023e10 10023e10 | SND10=Registered
FUN_10023fd0 10023fd0 | SPR3=Interface_Buttons_Normal ; SPR4=Interface_Buttons_Hilited ; SPR5=Interface_GameLogo
FUN_10024530 10024530 | SND11=InterfaceMenuButtonRollover
FUN_100246c0 100246c0 | F61=Interface_Btn_HiliteDelay
FUN_10024a50 10024a50 | SND2=InterfaceClick
FUN_10024f90 10024f90 | SND2=InterfaceClick ; F61=Interface_Btn_HiliteDelay
FUN_10025420 10025420 | F62=Interface_Btn_StartYLoc ; F63=Interface_Btn_VerticalGap ; F52=MinScreenWidth
FUN_10025840 10025840 | F160=Interface_FadeRate
FUN_10025890 10025890 | F160=Interface_FadeRate
FUN_10025970 10025970 | F67=Interface_AdvertismentDelay_Ticks ; SND2=InterfaceClick
FUN_10025b90 10025b90 | F53=MinScreenHeight ; F52=MinScreenWidth ; F74=Credits_TitleYLoc ; F160=Interface_FadeRate ; F75=Credits_VerticalGap ; SND2=InterfaceClick
FUN_10026410 10026410 | O1=Player 2 ; O0=Player 1 ; O2=MoneyUnit_50 ; O3=MoneyUnit_10 ; O4=MoneyUnit_5 ; O5=MoneyUnit_1 ; O6=MediaImpact_Water_Tiny ; O7=MediaImpact_Water_Small ; O8=MediaImp
FUN_100269a0 100269a0 | F163=Player_Appears_Initial ; F164=Player_Appears_Required ; F165=Player_Appears_Delta
FUN_10027100 10027100 | F162=Player_DelayBetweenHitSpawns
FUN_10027670 10027670 | S14=Coin Bonus: ; F170=Player_MoneyCounter_AdjustBonusFactorForLevel ; F171=Player_MoneyCounter_BonusFactorPerCoinHeld ; F200=Game_GroundAccuracyCount_Countdown_Adjus
FUN_10027930 10027930 | F172=Player_MoneyCounter_WaitingToAppear ; SND20=MoneyCount ; F177=Player_MoneyCounter_FadeInRate ; F173=Player_MoneyCounter_Appearing ; S14=Coin Bonus: ; S15=x ; SND
FUN_10027e50 10027e50 | O5=MoneyUnit_1 ; O4=MoneyUnit_5 ; O3=MoneyUnit_10 ; O2=MoneyUnit_50
FUN_10028170 10028170 | F184=Player_DefenceBonusBaseAmount ; F166=Player_TimeBetweenFrameChanges ; F54=VisibleGameWidth ; F55=VisibleGameHeight ; F183=Player_TopGameAreaLimit ; F186=Crosshai
FUN_10029a10 10029a10 | F182=Player_ExtraLifeScoreAdjustment
FUN_10029cc0 10029cc0 | F163=Player_Appears_Initial ; F164=Player_Appears_Required ; F165=Player_Appears_Delta
FUN_10029fe0 10029fe0 | O35=UnitDef_Multiplier_X2 ; O36=UnitDef_Multiplier_X3 ; O37=UnitDef_Multiplier_X4 ; O38=UnitDef_Multiplier_X5 ; O39=UnitDef_Multiplier_X10
FUN_1002d1a0 1002d1a0 | SND1=ConsoleActivate
FUN_1002d230 1002d230 | F22=Console_ExpireTime
FUN_1002d410 1002d410 | F23=Console_FadeOutRate
FUN_1002d770 1002d770 | SND5=CommandFailure ; SND4=CommandConfirmation
FUN_1002dbd0 1002dbd0 | F24=Message_MaxNum
FUN_1002dd90 1002dd90 | F25=Message_Duration ; F26=Message_FadeOutRate
FUN_1002dea0 1002dea0 | F27=Message_VerticalGap
FUN_1002e310 1002e310 | F56=ReqDisplayDepth ; F53=MinScreenHeight ; F52=MinScreenWidth ; R18=LevSel_Button_Previous ; SPR6=Level Selection Normal ; F96=LevelSelect_SpriteFrame_Previous ; F90
FUN_1002ef10 1002ef10 | F43=LevSel_InfoFadeOutTime
FUN_1002f3c0 1002f3c0 | F100=LevelSelect_HilitedButtonScale
FUN_1002fcc0 1002fcc0 | F46=LevSel_Failure_ScalingRate ; F47=LevSel_Failure_MaxScale ; F44=LevSel_Acceptance_ScalingRate ; F45=LevSel_Acceptance_MaxScale
FUN_1002ff30 1002ff30 | SND11=InterfaceMenuButtonRollover
FUN_10030360 10030360 | S0=Press Caps Lock
FUN_100305e0 100305e0 | F32=FPS_MaxRate
FUN_10030640 10030640 | F32=FPS_MaxRate ; F34=FPS_DeficiencyLevel ; S17=Interlacing      ON
FUN_100307c0 100307c0 | F32=FPS_MaxRate
FUN_10030910 10030910 | SND7=GameInterfaceSoundChange ; S21=Sound Volume     OFF ; S23=% ; S22=Sound Volume ; S17=Interlacing      ON ; S18=Interlacing      OFF
FUN_10030bc0 10030bc0 | F32=FPS_MaxRate ; F33=FPS_Delay
FUN_10030f40 10030f40 | R0=Scorebar Player 1 Score ; R1=Scorebar Player 1 Life Symbol ; R2=Scorebar Player 1 Life Count ; R3=Scorebar Player 1 Weapon 1 ; R4=Scorebar Player 1 Weapon 2 ; R5=S
FUN_100317e0 100317e0 | F120=ScoreBar_ShieldMeterIncreaseRate ; F121=ScoreBar_ShieldMeterDecreaseRate ; F126=ScoreBar_PowerMeterIncreaseRate ; F127=ScoreBar_PowerMeterDecreaseRate
FUN_10031ea0 10031ea0 | F114=ScoreBar_P2LivesSymbol_XLoc ; F115=ScoreBar_P2LivesSymbol_YLoc ; F112=ScoreBar_P1LivesSymbol_XLoc ; F113=ScoreBar_P1LivesSymbol_YLoc
FUN_10032050 10032050 | F143=ScoreBar_Lives_MaxNumDisplayed
FUN_10032250 10032250 | F118=ScoreBar_P2ShieldMeter_XLoc ; F119=ScoreBar_P2ShieldMeter_YLoc ; F116=ScoreBar_P1ShieldMeter_XLoc ; F117=ScoreBar_P1ShieldMeter_YLoc
FUN_10032500 10032500 | F124=ScoreBar_P2PowerMeter_XLoc ; F125=ScoreBar_P2PowerMeter_YLoc ; F122=ScoreBar_P1PowerMeter_XLoc ; F123=ScoreBar_P1PowerMeter_YLoc
FUN_100327b0 100327b0 | F130=ScoreBar_P1Weapons_2_XLoc ; F131=ScoreBar_P1Weapons_2_YLoc ; F136=ScoreBar_P2Weapons_2_XLoc ; F137=ScoreBar_P2Weapons_2_YLoc ; F142=ScoreBar_Weapons_NonSelectedS
FUN_10033850 10033850 | F54=VisibleGameWidth ; F55=VisibleGameHeight ; F161=Player_ImpactDamageToEntities
FUN_10037b50 10037b50 | F54=VisibleGameWidth
FUN_10037ed0 10037ed0 | F55=VisibleGameHeight
FUN_1003ade0 1003ade0 | F149=Crosshair_FadeInPercentageRate ; F150=Crosshair_FadeOutPercentageRate
FUN_1003b3c0 1003b3c0 | SND18=WepSelector_Switch
FUN_1003beb0 1003beb0 | F151=WepHandler_DefaultNumBombs ; F152=WepHandler_MaxNumBombs
FUN_10043340 10043340 | F145=Particle_ColorVariationAdjust ; F146=Particle_FringeColorAdjust
FUN_100438c0 100438c0 | F54=VisibleGameWidth ; F55=VisibleGameHeight ; F144=Particle_Gravity ; F148=Particle_BlendAmountRate_Long
FUN_10043ba0 10043ba0 | F54=VisibleGameWidth ; F55=VisibleGameHeight
FUN_10044630 10044630 | F54=VisibleGameWidth ; F55=VisibleGameHeight
```

## 3. Module spans (`module_spans.py`)

Command: `python3 docs/deimos/tools/func_profile.py ghidra/Deimos_pef.decompiled.c $MEM > profile.txt;
python3 docs/deimos/tools/module_spans.py profile.txt` (`$MEM` = output dir of DumpMemory.java).
Output:
```
functions in dump: 2580; FUN_-named: 2133
module-tagged: 123; bracketed: 301; total attributed: 424
  U_LinkedList.cc          10000910-100009e0  2 functions
  U_Pak.cc                 100016c0-10003700  19 functions
  U_Prefs.cc               10004640-10004640  1 functions
  G_Game.cc                100051a0-100051a0  1 functions
  G_Film.cc                100095b0-100095b0  1 functions
  M_PixelBuffer.cc         10009ac0-10009bd0  2 functions
  M_Window.cc              1000a640-1000a640  1 functions
  M_Display.cc             1000ad90-1000c470  27 functions
  G_Text.cc                1000d010-1000ef90  20 functions
  G_Background.cc          1000fbc0-1000fbc0  1 functions
  M_Registration.cc        10010cf0-10010e00  3 functions
  M_Configuration.cc       10010fc0-10010fc0  1 functions
  G_Level.cc               10011c00-100122f0  10 functions
  G_Entity.cc              100144a0-100146f0  4 functions
  U_Sprite.cc              10018740-1001b390  27 functions
  U_SpriteBlit.cc          1001d5e0-1001eec0  17 functions
  U_SpritePlate.cc         1001f140-1001f1c0  2 functions
  G_Resource.cc            1001f7c0-100204a0  17 functions
  U_Image.cc               10020e60-10020e60  1 functions
  M_Image.cc               10021190-10021190  1 functions
  G_Scores.cc              10021950-100222f0  3 functions
  G_Interface.cc           10023040-10025420  34 functions
  G_Credits.cc             10025b90-10025b90  1 functions
  G_Player.cc              10026410-1002a450  53 functions
  G_Debris.cc              1002a660-1002a6d0  2 functions
  G_WeaponDefinitions.cc   1002ab20-1002ba00  14 functions
  U_Token.cc               1002cc90-1002cc90  1 functions
  G_Console.cc             1002cef0-1002d410  8 functions
  G_Message.cc             1002db50-1002dbd0  2 functions
  G_LevelSelection.cc      1002e310-1002efb0  3 functions
  G_ScoreBar.cc            10031400-10031400  1 functions
  G_EntityGroup.cc         10032e60-100385d0  46 functions
  G_PlayerDefinitions.cc   10039280-10039e70  11 functions
  U_Manager.cc             1003a780-1003ab30  7 functions
  G_WeaponHandler.cc       1003ade0-1003b180  3 functions
  G_UnitDefinitions.cc     1003d0a0-100420f0  44 functions
  G_Particle.cc            100432d0-10043340  2 functions
  G_MotionBlur.cpp         100467c0-10046eb0  10 functions
  M_Sound.cpp              10047160-10047330  3 functions
  M_Music.cpp              10047e40-10047e40  1 functions
  M_Application.cpp        100491d0-10049aa0  16 functions
  unzip.c                  10049ca0-10049ca0  1 functions
```
Module tags found only through TOC-base+offset string resolution (G_MotionBlur.cpp, M_Sound.cpp,
M_Music.cpp, M_Application.cpp, unzip.c, G_Particle.cc) are [LOW]: the offset heuristic in
`func_profile.py` also produced visible false positives (e.g. "Last Film" attached to sound
functions). Bracketed attribution assumes CodeWarrior emitted each translation unit
contiguously, which the monotonic order of the tagged spans supports [MED].
