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
- ⚑ corrected (review wave 1, 2026-10-03): after the review-wave-1 fix pass → §1 hand table:
  **510 functions — HIGH 240, MED 256, LOW 14** (same command). Delta: 68 HIGH → MED by the label
  audit (review M8), +1 MED row (`FUN_10011bf0`, review M7); the four conflict rows kept HIGH
  with fix-pass listings.
- ⚑ wave 2 (2026-10-03): +168 rows, 96 corrected → §1 hand table: **678 functions — HIGH 392,
  MED 271, LOW 15** (same command). 96 existing rows were changed in place (`— ⚑ corrected (wave 2,
  2026-10-03)`); `FUN_10017150` only gained a confirmation note. The label rule (HIGH only with a
  listing/raw/data citation) lowered 36 proposed-HIGH rows to MED (`— ⚑ label rule (wave 2
  synthesis)`; one of them, `FUN_10047330`, was HIGH before); the owning wave-2 files still print
  HIGH for those rows. Six new rows for code with no Ghidra function are `(undefined)` rows and are
  not counted. §2/§3/union still not re-run.
- ⚑ corrected (review wave 2, 2026-10-03): after the review-wave-2 fix pass → §1 hand table: **679 functions — HIGH 397,
  MED 267, LOW 15** (same command: `awk '/^## 1\./,/^## 2\./' function-roles.md | grep '^| `FUN_' |
  awk -F'|' '{print $5}' | sort | uniq -c`). Delta: +1 HIGH row (`FUN_10014120`, critic C1);
  MED → HIGH on a quoted listing: the label-rule rows `FUN_1001dd20`, `FUN_1001df00` (review M3),
  `FUN_10018b20`, `FUN_10048120`, plus `FUN_100009e0` (C5, INDEX #38) and `FUN_10029c00` (conflict
  closed) = 6; HIGH → MED: `FUN_100d1780` (M3) and `FUN_1001ec80` (C5) = 2. The other 32 label-rule
  rows stay MED and their owning wave-2 files were lowered to match (`⚑ label audit (review wave
  2)`), so no row carries different labels in two files.
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
| `FUN_10000630` | — (unattributed) | shutdown sequence, ends in `FUN_10048480` → ExitToShell | HIGH | listing `10000730`, `100484c0 bl 0x100d4464` (loose-ends-session.md §3.2) — ⚑ corrected (wave 2, 2026-10-03): was "shutdown sequence" MED; see loose-ends-session.md §3.2 |
| `FUN_10048330` | M_Application.cpp | Toolbox init (InitGraf…InitCursor, Gestalt 'qtim') | MED | imports — ⚑ corrected (review 2026-10-03) #8: was HIGH on string/import/usage evidence only |
| `FUN_10048480` | — (unattributed) | log, UnregisterAppearanceClient, **ExitToShell** | HIGH | listing (loose-ends-session.md §8) |
| `FUN_10049aa0` | M_Application.cpp | install AppleEvent handlers aevt/oapp/odoc/pdoc/quit | MED | 4CCs — ⚑ corrected (review 2026-10-03) #8: was HIGH on string/import/usage evidence only |
| `FUN_100491d0` | M_Application.cpp | menu bar setup | MED | sPriv_Menu_File |
| `FUN_10000e70` |  | assert: memory error | MED | "MEMORY ERROR" string — ⚑ corrected (review 2026-10-03) #8: was HIGH on string/import/usage evidence only |
| `FUN_10000ed0` |  | assert: tool error | MED | "TOOL ERROR" — ⚑ corrected (review 2026-10-03) #8: was HIGH on string/import/usage evidence only |
| `FUN_10000f30` |  | assert: file error | MED | "FILE ERROR" — ⚑ corrected (review 2026-10-03) #8: was HIGH on string/import/usage evidence only |
| `FUN_10000f80` |  | assert: data error | MED | "DATA ERROR" — ⚑ corrected (review 2026-10-03) #8: was HIGH on string/import/usage evidence only |
| `FUN_10000fd0` | — (unattributed) | **non-fatal** "critical files missing" alert (`FUN_1000ced0(…,0)`) | HIGH | listing `10000fdc li r4,0x0`; pak-format.md called it fatal (loose-ends-session.md §8) — ⚑ corrected (wave 2, 2026-10-03): was "fatal: critical files missing" MED; see loose-ends-session.md §8 |
| `FUN_10000910` | U_LinkedList.cc | linked list insert | MED | newLinkPtr |
| `FUN_100009e0` | U_LinkedList.cc | linked list append **at the tail** (header {+0 count, +4 head, +8 tail}; node = prev,next,data); used as list add everywhere | HIGH | listing `10000a4c stw r31,0x4(r28)` (head if empty), `10000a5c stw r31,0x4(r3)` (old tail→next), `10000a68 stw r3,0x0(r31)` (prev = old tail), `10000a70 stw r31,0x8(r28)` (tail = node), `10000a7c` count+1 (`$W/disasm-w2s5c.txt`) — ⚑ corrected (review wave 2, 2026-10-03) #C5: was MED "tail append from the dump"; INDEX #38 struck — read + assert string (loose-ends-session.md role rows) — ⚑ corrected (wave 2, 2026-10-03): was "linked list append (node = prev,next,data); used as list add everywhere" MED; see loose-ends-session.md §8 |
| `FUN_10000ce0` |  | list count | MED | usage pattern |
| `FUN_10000e10` |  | list iterate (cursor over prev,next,data nodes) | MED | read + assert string — ⚑ corrected (wave 1, 2026-10-03): was "list iterate (cursor)" MED; see level-scroll-objects.md role rows — ⚑ label audit (review wave 1) |
| `FUN_10000c00` | U_LinkedList.cc | unlink current node and free it; iterator moves to prev | MED | read + assert string; dump (loose-ends-session.md role rows) — ⚑ corrected (wave 2, 2026-10-03): was "unlink current node (cursor)" MED; see loose-ends-session.md §8 |
| `FUN_1000cb60` | M_Memory.cc | allocate (NewPtr/NewPtrClear) with failure log | MED | imports + "MEMORY ALLOCATION FAILURE" — ⚑ corrected (review 2026-10-03) #8: was HIGH on string/import/usage evidence only |
| `FUN_1004d320` |  | operator new | MED | alloc + null asserts at callers |
| `FUN_1004d5c0` | MSL runtime | double → unsigned int | HIGH | listing (sprite-geometry-draw.md §4.1) |
| `FUN_1000cd60` |  | memcpy | MED | usage |
| `FUN_1000cd90` |  | memset 0 | MED | usage |
| `FUN_1000ced0` | — (unattributed) | error alert; arg 3 ≠ 0 → shutdown | MED | dump (loose-ends-session.md §8) |
| `FUN_1000d130` | G_Text.cc | copy text format i (0x148 B) | MED | read (hud-scorebar.md §9) — ⚑ label rule (wave 2 synthesis): proposed HIGH on "read" only — ⚑ label audit (review wave 2): MED settled — the owning file had no listing line or data bytes for it, so its row was lowered to MED too |
| `FUN_1000d260` | G_Text.cc | measure formatted text (digit cache, no draw) | MED | read (hud-scorebar.md §9) |
| `FUN_1000d380` | G_Text.cc | draw formatted text: digit cache (`DAT_100e0124` off-by-one), shadow pass, colour strip, text | HIGH | listing `1000d3e8…1000d474` + decompile (hud-scorebar.md §4) |
| `FUN_1000e270` | G_Text.cc | text layout/draw per alignment (CENT X−W/2, RIGH X−W, CEBU/CEGA centred in 640/416), returns bounds | HIGH | listing `1000e304…1000e4fc` (hud-scorebar.md §9) |
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
| `FUN_100466e0` / `FUN_10046760` | G_MotionBlur.cpp (span) | blur module init (prealloc once) / teardown | MED | decompile; callers `FUN_100000e0` / `FUN_10000630` (particles-debris-blur.md §4.2) |
| `FUN_100467c0` | G_MotionBlur.cpp | per-level reset: empty list, new list 0x100e0284, clear pool flags | HIGH | listing; caller `FUN_100064d0` (particles-debris-blur.md §4.2) |
| `FUN_10042920` | math module (span 0x10042100–0x100432d0; name not in binary) | build atan int[1024], sqrt float[16384], cos/sin float[360] tables (start-up) | HIGH | listing; caller `FUN_100000e0` (units-movement.md §2.3, damage-health-death.md §1) |
| `FUN_10042a90` | math module (span 0x10042100–0x100432d0; name not in binary) | free math tables | MED | decompile (damage-health-death.md §1) |
| `FUN_10042ad0` | math module (span 0x10042100–0x100432d0; name not in binary) | heading (compass int) from two int points | HIGH | listing (units-movement.md §2.2, damage-health-death.md §1) |
| `FUN_10042b30` | math module (span 0x10042100–0x100432d0; name not in binary) | heading → unit vector (x = sin h, y = cos h) | HIGH | listing (damage-health-death.md §1, units-movement.md §2.2) |
| `FUN_10042b80` | math module (span 0x10042100–0x100432d0; name not in binary) | vector = speed·(sin h, cos h) | HIGH | listing (units-movement.md §2.2, damage-health-death.md §1) |
| `FUN_10042bf0` | math module (span 0x10042100–0x100432d0; name not in binary) | normalise vector (x² computed as trunc(x)·x — quirk) | HIGH | listing `10042c1c–10042c44` (damage-health-death.md §1) |
| `FUN_10042c90` | math module (span 0x10042100–0x100432d0; name not in binary) | vector length (libm sqrt) | HIGH | listing (damage-health-death.md §1) |
| `FUN_10042cd0` | math module (span 0x10042100–0x100432d0; name not in binary) | heading (internal h') of a float vector: axis cases 0/180/90/270, quadrant atan formulas, trunc, ≥360→0; exact inverse of `FUN_10042b80` | HIGH | full listing `10042cd0..10042e8c` (loose-ends-combat.md §1.2) — ⚑ corrected (was MED, decompile) (loose-ends-combat.md §1.2) — ⚑ corrected (wave 2, 2026-10-03): was "heading of a float vector (libm atan, axis table)" MED; see loose-ends-combat.md §1.2 |
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
| `FUN_10049910` / `FUN_10049370` / `FUN_10048c90` | M_Application | mouseDown class / menu item map / simple event poll (1 click, 2 key, 3 autokey, 4 update) | MED | read (front-end.md §2.5) — ⚑ label rule (wave 2 synthesis): proposed HIGH on "read" only — ⚑ label audit (review wave 2): MED settled — the owning file had no listing line or data bytes for it, so its row was lowered to MED too |
| `FUN_10049150` |  | IsKeyDown(virtual key code): GetKeys+BitTst | HIGH | read |
| `FUN_10048ee0` |  | GetMouse wrapper | HIGH | read |
| `FUN_10048f30` | M_Application | event pump: what 1→2, 3/5→4 or 5, 6→3, 15→6/7, 23→8 | HIGH | table `0x100f0384` (front-end.md §2.5) |
| `FUN_10048e60` |  | Button() wrapper | MED | import — ⚑ corrected (review 2026-10-03) #8: was HIGH on string/import/usage evidence only |
| `FUN_10048e30` |  | FlushEvents wrapper | MED | import — ⚑ corrected (review 2026-10-03) #8: was HIGH on string/import/usage evidence only |
| `FUN_10048a00` |  | read prefs file (FindFolder 'pref', HOpen, FSRead) | MED | imports — ⚑ corrected (review 2026-10-03) #8: was HIGH on string/import/usage evidence only |
| `FUN_10048ac0` |  | write prefs file "Deimos Rising Preferences" type pref creator Deim | MED | imports + string — ⚑ corrected (review 2026-10-03) #8: was HIGH on string/import/usage evidence only |
| `FUN_10048d70` | ? | read one OS event: keyDown → 2 + char, autoKey → 3, mouseDown → 1 | MED | decompile (messages-notices-console.md §5.1) |
| `FUN_100015a0` |  | pak manager init, LOGTAGS command, data version check (pali) | MED | strings |
| `FUN_100016c0` | U_Pak.cc | build tag index (Local then Paks) | HIGH | read |
| `FUN_100021a0` | U_Pak.cc | parse entry name -> display, ID, type | HIGH | read |
| `FUN_10003a40` |  | tag ID between [ ] | HIGH | read |
| `FUN_10003b20` |  | suffix -> resource type (15 tables) | HIGH | read |
| `FUN_100040c0` |  | suffix is .zip/.pak | MED | strings — ⚑ corrected (review 2026-10-03) #8: was HIGH on string/import/usage evidence only |
| `FUN_10004230` |  | format "%s[%s].%s" | MED | string — ⚑ corrected (review 2026-10-03) #8: was HIGH on string/import/usage evidence only |
| `FUN_10004300` / `FUN_100043c0` | — (tag index, pak-format.md §2) | apply overrides: each Local record removes every non-Local record with the same (type, ID) | MED | dump (loose-ends-session.md §8) — ⚑ label rule (wave 2 synthesis): proposed HIGH on "dump" only — ⚑ label audit (review wave 2): MED settled — the owning file had no listing line or data bytes for it, so its row was lowered to MED too |
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
| `FUN_100045f0` | U_Prefs (engine-loop §10) | shutdown: write the prefs file if dirty (always dirty after load) | MED | dump lines 2564/2587 (loose-ends-session.md §3.2) |
| `FUN_10004640` | U_Prefs.cc | save prefs (encode names, offset scores) | HIGH | read |
| `FUN_100047f0` | U_Prefs (engine-loop §10) | copy a prefs struct into the live prefs | MED | dump; single caller `FUN_10021bd0` (loose-ends-session.md §3.2) |
| `FUN_10004ae0` |  | default high-score table | HIGH | read |
| `FUN_10004c30` | U_Prefs (engine-loop §10) | copy the live prefs out (0x34f0) | MED | dump; listing offsets `10004d14..10004da0` (loose-ends-session.md §3.1) — ⚑ corrected (wave 2, 2026-10-03): was "copy prefs block" MED; see loose-ends-session.md §3.1 |
| `FUN_10004f80` |  | load prefs (System Folder, else pak 'pref'), version 0x2714 | HIGH | read |
| `FUN_100050f0` | U_Prefs.cc (span) | prefs defaults: byte 4=1, 5/6/7/8=0, int 0/1/2 = 50/100/50, key table 14 codes at +0x14b8 | HIGH | listing `100050f0..1000519c` (timing-frame.md §5) |
| `FUN_10004ef0` |  | get byte pref n (+4+n) | HIGH | read |
| `FUN_10004ab0` |  | set byte pref n | HIGH | read |
| `FUN_10004f00` |  | get int pref n (+0x68+4n) | HIGH | read |
| `FUN_10004ac0` |  | set int pref n | HIGH | read |
| `FUN_100051a0` | G_Game.cc | game loop (one session) | HIGH | read |
| `FUN_10006b50` |  | logic tick: input, notices, debris, particles, blur, players, scorebar, scroll, end-level, entities | HIGH | read |
| `FUN_10007070` |  | draw world | MED | callees |
| `FUN_10007170` | G_Game.cc (span) | level transition: when +0x09 and a player is alive → sound, fade, clear +0x09/**+0x39**, `FUN_100302e0`, `FUN_100064d0` next level; otherwise +0x08 = 0 (session ends) | MED | decompile + `10007248` (loose-ends-combat.md §2.1) — ⚑ corrected (wave 2, 2026-10-03): was "level complete → transition sound, `FUN_100064d0` next sector (session ends via `none`)" MED; see loose-ends-combat.md §2.1 |
| `FUN_100064c0` | G_Game.cc (span) | stop session (`+0x08 = 0`) | MED | read — ⚑ corrected (wave 1, 2026-10-03): was "end session request" MED; see level-scroll-objects.md §8 — ⚑ label audit (review wave 1) |
| `FUN_100064d0` | G_Game.cc (span) | level start: next sector, per-level resets, scroll init, load spawns, preload weapons (`FUN_1002b3a0`), Notice_Level_NN; perm F52-56 | HIGH | read + listing — ⚑ corrected (wave 1, 2026-10-03): was "start level (display, level load)" MED; see level-scroll-objects.md §8 |
| `FUN_100069b0` | G_Game (span) | load a film: mode 2 = next "Demo" tag (counter G+0x24, wraps), else `last`; srand(film seed) | HIGH | dump + listing `10006b24` (loose-ends-session.md §7) — ⚑ corrected (wave 2, 2026-10-03): was "load film for playback (attract cycle), srand(seed)" HIGH; see loose-ends-session.md §7 |
| `FUN_100072c0` | G_Game.cc (span) | accuracy tier: pct float ≥100/95/90/85/80 → flli189–194 × sector; step max(trunc(b·0.02f),100); sets 100 % flag G+0xb | HIGH | listing `100072c0..100075dc` — ⚑ corrected (wave 1, 2026-10-03): was "ground accuracy tier computation" MED; see scoring-bonuses.md §6.3 |
| `FUN_100075e0` | G_Game.cc (span) | accuracy tally (11 states) + mission bonus 10 × flli205 raw when all levels 100 % | HIGH | listing `100079a0..10007d3c`, table `0x100e3cd0` — ⚑ corrected (wave 1, 2026-10-03): was "end-of-level accuracy tally" MED; see scoring-bonuses.md §6.4 |
| `FUN_10007d60` | G_Game.cc (span) | draw accuracy-tally text (format 53, alpha G+0x50) | HIGH | listing `10007d60..10007df8` (messages-notices-console.md §1) |
| (undefined) `0x10007eb0` | G_Game.cc (span) | console `FPS` handler: toggle byte pref 9, message (no Ghidra function) | HIGH | range listing `10007eb0..10007f44` (timing-frame.md §6); not counted in the `FUN_` row counts |
| (undefined) `0x10007f50` | G_Game.cc (span) | console `LIMITFPS` handler: toggle byte pref 10 — command never registered (r7 = 1), unreachable (no Ghidra function) | HIGH | range listing `10007f50..10007fe4`, `10005294` (timing-frame.md §6); not counted in the `FUN_` row counts |
| (undefined) `0x10007e00`…`0x100090d0` | G_Game.cc (span) | 18 console handlers (FPS, VERSION, supermunki and 6 cheats reachable; the rest debug-only, unregistered); `FUN_10008820` (GAMETIME) is the only Ghidra function in the range | HIGH | raw listing + TVs `0x100defc8…0x100def84` (messages-notices-console.md §5.5); not counted in the `FUN_` row counts |
| `FUN_10008820` | G_Game.cc (span) | console GAMETIME handler (debug-only, unregistered → unreachable) | MED | raw range listing (messages-notices-console.md §5.5) |
| `FUN_10007130` | G_Game.cc (span) | counter resets: `FUN_10007130` the 5 cheat-use counters G+0x16c…0x17c **at game start** (not per level), `FUN_10007150` accuracy counts G+0x3c/+0x40, `FUN_10007280` accuracy tally +0x48… | MED | read (level-scroll-objects.md §8, scoring-bonuses.md §6.2); `FUN_10007130` alone proposed HIGH from decompile + raw writer scan (messages-notices-console.md role rows) — ⚑ corrected (wave 2, 2026-10-03): was "per-level counter resets: `FUN_10007130` game struct +0x16c…, `FUN_10007150` accuracy counts G+0x3c/+0x40, `FU…" MED; see messages-notices-console.md §5.4 |
| `FUN_10005cc0` |  | current level ID | HIGH | read |
| `FUN_10005cd0` |  | current sector number | HIGH | read |
| `FUN_10005ce0` | G_Game.cc (span) | game time getter `G+0x1c` | HIGH | decompile one-liner + GAMETIME TV use (messages-notices-console.md §5.5) — ⚑ corrected (wave 2, 2026-10-03): was "game time / frame accessor" LOW; see messages-notices-console.md §5.5 |
| `FUN_10005cf0` | G_Game | game `+0x39` "level end reached" (set `10006db4`, cleared `10007248`/`10005524`/`10005828`) | HIGH | listing + raw store scan (loose-ends-combat.md §2) |
| `FUN_10005d00` | G_Game.cc (span) | accuracy-reward flag G+0xc get (`FUN_10005d10` clears it) | MED | read (scoring-bonuses.md §6.4) |
| `FUN_10005d20` |  | player n pointer | MED | usage in FUN_10033850 |
| `FUN_10005d40` | G_Game.cc (span) | nearest active player to a point: position, distance, player number (ties → player 1) | HIGH | listing `10005d40..10005ec0` (units-movement.md §5.1) |
| `FUN_10005ed0` | G_Game | closest state-4 player to **ref point** (ties → P1), default (0,0); returns any-active | HIGH | listing — ⚑ corrected (caller passes ref (208,0)) (loose-ends-combat.md §7.2) |
| `FUN_10006090` | G_Game | position of player idx if in state 4 | HIGH | listing (loose-ends-combat.md §7.3) |
| `FUN_10006190` |  | add points to player n | MED | read |
| `FUN_10006110` | G_Game | any player in state 4 | HIGH | listing (loose-ends-combat.md §7.3) — ⚑ corrected (wave 2, 2026-10-03): was "any player active" MED; see loose-ends-combat.md §7.3 |
| `FUN_100061e0` | G_Game.cc (span) | ground-accuracy created += 1 (G+0x3c); `FUN_10006200` destroyed += 1 (G+0x40) | HIGH | hand-decoded words `100061e4`, `10006204` (scoring-bonuses.md §6.2) |
| `FUN_10006220` | G_Game? | SHADOWS console flag (`*(0x100defd0)+0x28`, 1 before console init) | HIGH | listing `10006220–1000623c` (sprite-geometry-draw.md §3.2) |
| `FUN_10006240` |  | video-grid overlay (SPR 0, F84/F85) over a rect | HIGH | `10006340` (front-end.md §7.1) |
| `FUN_10009390` |  | film buffer init (version 0x2715) | HIGH | read |
| `FUN_10009710` |  | film header for recording | HIGH | read |
| `FUN_10009830` |  | record one tick of input (bit-packed) | HIGH | read |
| `FUN_100097a0` |  | replay one tick of input | HIGH | read |
| `FUN_10009750` | G_Film (span) | film **finished**: P1 cursor > P1 recorded frame count (returns 1 when the replay is exhausted; the game loop then stops) | HIGH | listing `10009750..1000976c` (timing-frame.md §7) — ⚑ corrected (wave 2, 2026-10-03): was "film still playing" HIGH; see timing-frame.md §7, loose-ends-session.md §7 — ~~⚑ conflict: timing-frame.md reads the branchless idiom as unsigned, loose-ends-session.md as signed (dump idiom, no listing); listing reading kept — moot for non-negative counts~~ ⚑ corrected (review wave 2, 2026-10-03) #M1: conflict settled **signed** — the listing sequence `10009758 xor; 1000975c srawi r3,r0,0x1; 10009760 and r0,r0,r4; 10009764 subf r0,r0,r3; 10009768 rlwinm r3,r0,0x1,0x1f,0x1f` evaluates to signed `cursor > count` on every tested pair ((0x80000000, 1) → 0); the review's "unsigned" was not adopted; timing-frame.md §7 corrected |
| `FUN_100095b0` | G_Film.cc | save the film image as `film`/`last` "Last Film" in Data:Local, rebuild the tag index | HIGH | dump + listing `10005b00..10005b18` (loose-ends-session.md §7) — ⚑ corrected (wave 2, 2026-10-03): was "save film as tag 'last'" HIGH; see loose-ends-session.md §7 |
| `FUN_100094a0` |  | load film tag + version check | MED | strings |
| `FUN_10009680` |  | film header getters (seed) | MED | caller |
| `FUN_10009770` |  | film seed getter | HIGH | read |
| `FUN_10009780` |  | film level getter | HIGH | read |
| `FUN_10009790` |  | film player-count getter | HIGH | read |
| `FUN_10009230` | G_Game.cc (span) | post "Please Register Deimos Rising!" (de-obfuscated `0x100e447c`), type 1 | HIGH | listing; was LOW "show decoded notice text" (messages-notices-console.md §2.5) — ⚑ corrected (wave 2, 2026-10-03): was "show decoded notice text" LOW; see messages-notices-console.md §2.5 |
| `FUN_1000ae20` | M_Display.cc | display setup 640x480x16, borders, score bar | MED | perm F52-59 |
| `FUN_1000b9a0` | M_Display (unattributed) | fade to black: 33 steps a = 32→0, in-place compounding scale, ≥ 1 TickCount per step | HIGH | listing (loose-ends-session.md §6; front-end.md §5.1 agrees) |
| `FUN_1000ba70` | M_Display (unattributed) | fade from black to a snapshot: 9 steps a = 0,4,…,32 (`FUN_1001e9d0` blend), ≥ 1 TickCount each, blocking | HIGH | listing (loose-ends-session.md §6; front-end.md §5.1 agrees; timing-frame.md MED "fade in/out") — front-end.md NR 3 left the direction open; loose-ends-session.md §6 read the blend |
| `FUN_1000beb0` |  | present **game screen** (borders, game area, score bar) — chosen by controller +4, not by interlacing | MED | dump (border PaintRects, F54/F55/F59); was "present frame (interlaced)" (timing-frame.md §2.3) — ⚑ corrected (wave 2, 2026-10-03): was "present frame (interlaced)" MED; see timing-frame.md §2.3 |
| `FUN_1000bc60` |  | present full screen (640×480; level select, fades) | MED | dump F52/F53; was "present frame" (timing-frame.md §2.3) — ⚑ corrected (wave 2, 2026-10-03): was "present frame" MED; see timing-frame.md §2.3 |
| `FUN_1000a480` |  | pixel buffer width,height | HIGH | read |
| `FUN_1000a4a0` |  | pixel buffer base,rowBytes | MED | usage |
| `FUN_1000a530` | M_Display.cc (span) | copy a port's bounds rect (+0x1c..+0x28) | MED | dump only (sprite-geometry-draw.md §3.2) |
| `FUN_1000ad90` | M_Display.cc | display port by index 0/1/2 → +0x68/+0x6c/+0x70 | MED | dump (sprite-geometry-draw.md §6) |
| `FUN_100099c0` | M_PixelBuffer.cc | pixel buffer (GWorld) create w,h,depth | MED | caller args |
| `FUN_10009ac0` | M_PixelBuffer | clone a pixel buffer (with contents) | MED | dump ("clonePtr") (loose-ends-session.md §6) |
| `FUN_10009fd0` |  | copy picture → picture (CopyBits ×2, or interlaced `FUN_100450e0`) | MED | dump (timing-frame.md §5) — ⚑ corrected (wave 2, 2026-10-03): was "copy rect between buffers" MED; see timing-frame.md §5 |
| `FUN_1000ef90` | G_Text.cc | parse tefo text format | HIGH | read |
| `FUN_1000e8d0` |  | character -> font frame index | HIGH | read |
| `FUN_1000ebd0` |  | draw one character | MED | read |
| `FUN_1000ed60` | G_Text.cc | load the 54 permanent text formats (gate idli order) | MED | read (hud-scorebar.md §9) — ⚑ label rule (wave 2 synthesis): proposed HIGH on "read" only — ⚑ label audit (review wave 2): MED settled — the owning file had no listing line or data bytes for it, so its row was lowered to MED too |
| `FUN_1000edf0` | G_Text.cc | load one tefo tag and parse it | MED | read (hud-scorebar.md §9) |
| `FUN_1000e670` | G_Text.cc | measure/draw one glyph (centre x+w/2, y+h/2; shadow offset F19/F20, blend F21; colourise flag 4) | MED | decompile — was "text shadow settings" MED (hud-scorebar.md §9) — ⚑ corrected (wave 2, 2026-10-03): was "text shadow settings" MED; see hud-scorebar.md §9 |
| `FUN_1000f7a0` | G_Background.cc | module init: register "Background", 12 debug console command names (10 handlers) | HIGH | strings + TOC handler slots (level-scroll-objects.md §9) |
| `FUN_1000f990` | G_Background.cc | free media mask if module live (session end) | MED | read (level-scroll-objects.md §9) |
| `FUN_1000f9c0` | G_Background.cc | module shutdown, free mask | MED | read (level-scroll-objects.md §9) |
| `FUN_1000fa10` | G_Background.cc | level-load spawn pass: rows bottom … top−64 (3600 … 3056) | HIGH | listing `1000fa48 subi r3,r3,0x41` (level-scroll-objects.md §2) |
| `FUN_1000fa90` | G_Background.cc | level scroll init: speed 1, offset 0, window top = RECT bottom − 480 (3600 − 480 = 3120), progress 481 | HIGH | listing `1000fb38` (level-scroll-objects.md §2); dump (bosses.md §2.3) |
| `FUN_1000fbc0` | G_Background.cc | load level map + media mask, mask element size | MED | read — ⚑ label audit (review wave 1) |
| `FUN_1000fee0` |  | is point on water (mask == 0x001f) | MED | read — ⚑ label audit (review wave 1) |
| `FUN_1000ffc0` | G_Background.cc | resume vertical scroll (speed 1) unless the level has ended | HIGH | listing — ⚑ corrected (wave 1, 2026-10-03): was "resume vertical scroll (speed 1)" HIGH; see level-scroll-objects.md §4 |
| `FUN_1000ffe0` |  | pause vertical scroll | MED | read — ⚑ label audit (review wave 1) |
| `FUN_1000fff0` |  | is scroll paused | MED | read — ⚑ label audit (review wave 1) |
| `FUN_10010000` | G_Background.cc | per-tick scroll step; level end when progress (r2−0x61e4, starts 481) ≥ level RECT bottom (3600), i.e. window top = 1; spawn row top−64 (world y −64) | HIGH | raw `10010000..1001009c` — ⚑ corrected (wave 1, 2026-10-03): was "scroll step, level-end flag, spawn objects at top-64" HIGH; see bosses.md §2.3, level-scroll-objects.md §3 |
| `FUN_10010220` |  | advance scroll window by speed | HIGH | read |
| `FUN_100100b0` | G_Background.cc | horizontal view offset ±1 px per call, clamp [−32, 31]; driven by each active player's left/right input (`FUN_10028170`, call `10029508`), reset per level | HIGH | listing + caller — ⚑ corrected (wave 1, 2026-10-03): was "horizontal view shift ±32" HIGH; see level-scroll-objects.md §5, player-physics.md §2.5 |
| `FUN_10010120` | G_Background.cc | draw terrain window: map (top, off+32, top+480, off+448) → buffer (0,0,480,416); perm F54/55 | HIGH | listing; ⚑ label audit (review wave 2) #M3: HIGH kept — pref 5 reaches the copy as its 5th argument (`100101cc li r3,0x5; bl 0x10004ef0; 100101e4 or r7,r3,r3; 100101f8 bl 0x10009fd0`, `$W/disasm-review2.txt`); the every-other-row pattern inside `FUN_10009fd0`/`FUN_100450e0` stays MED (timing-frame.md §5) — ⚑ corrected (wave 1, 2026-10-03): was "draw terrain window" MED; see level-scroll-objects.md §9 — ⚑ corrected (wave 2, 2026-10-03): was without the interlace case; the blit is interlaced (`FUN_100450e0`, every other row) when byte pref 5 is on; see timing-frame.md §5 |
| `FUN_1000fec0` | G_Background.cc | scroll window top (map row of world y 0) | MED | read; callers use it for map↔world — ⚑ corrected (wave 1, 2026-10-03): was "scroll window top" MED; see level-scroll-objects.md §1 — ⚑ label audit (review wave 1) |
| `FUN_1000fed0` | G_Background.cc | pixels scrolled this tick (ground entities add it to y) | MED | read; writer `FUN_10010220` (units-movement.md §2.1, level-scroll-objects.md §3) — ⚑ label audit (review wave 1) |
| `FUN_100100a0` | G_Background.cc | horizontal offset getter | MED | read (level-scroll-objects.md §5) — ⚑ label audit (review wave 1) |
| `FUN_10010360` | G_Background.cc | free media mask | MED | read (level-scroll-objects.md §9) — ⚑ label audit (review wave 1) |
| `FUN_10010570` | G_Background.cc | console REVERSE handler: scroll speed −1 ↔ 1 unless the level has ended ("Vertical Scrolling Reversed/Resumed"); debug | HIGH | listing `10010570..100105f8` (`10010580 lwz r0,-0x6208(r2); cmpwi r0,-0x1`); registration: `FUN_1000f7a0` passes TOC slot `0x100df07c` for "REVERSE" → TVector `0x100e0890` → `0x10010570`; SCROLL/SCROLLING use `0x100df094` → `0x100104f0` (undefined code, toggle 1 ↔ 0) — memory image, fix pass — ⚑ corrected (review wave 1, 2026-10-03) (conflict resolved): level-scroll-objects.md §9 wins; bosses.md "SCROLL toggle" (MED) corrected in bosses.md §2.4 and role rows |
| `FUN_10010860` | G_Background.cc | console LEVELSPAWNS toggle (debug) | MED | read (level-scroll-objects.md §9) — ⚑ label audit (review wave 1) |
| (undefined) `0x100103b0` `0x10010430` `0x10010480` `0x100104f0` `0x10010600` `0x10010640` `0x100106f0` `0x100107a0` | G_Background.cc | console BACKSIZE, ERASEBACK, JUMP, SCROLL, ROW, LOGMEDIA, MEDIASIZE, MEDIA handlers (no Ghidra function) | HIGH | TOC slots `0x100df07c…a0` + listings (level-scroll-objects.md §9); not counted in the `FUN_` row counts |
| `FUN_10010990` |  | HTML RRGGBB -> 16-bit pixel | MED | string — ⚑ corrected (review 2026-10-03) #8: was HIGH on string/import/usage evidence only |
| `FUN_10010c20` | G_GameObject (span) | visibility % → alpha: min(32, trunc(abs(32v/100 − 32))) | HIGH | listing `10010c20–10010c90` (sprite-geometry-draw.md §4.1) |
| `FUN_10010f90` |  | registered? (out of scope) | MED | callers |
| `FUN_10010e90` |  | registration banner (out of scope) | MED | perm S33-35 |
| `FUN_10010cf0` | M_Registration.cc | registration profile (out of scope) | MED | strings |
| `FUN_10011a70` | G_Level.cc | module init: register "Level", build order list | MED | read (level-scroll-objects.md §8) — ⚑ label audit (review wave 1) |
| `FUN_10011ab0` | G_Level.cc | module shutdown, free order list | MED | read (level-scroll-objects.md §8) |
| `FUN_10011b00` | G_Level.cc | number of unregistered levels = 4 (demo, out of scope) | MED | read (level-scroll-objects.md §8) — ⚑ label audit (review wave 1) |
| `FUN_10011b10` | G_Level.cc | free order list (demo cut) | MED | read (level-scroll-objects.md §8) |
| `FUN_10011bf0` | ~after G_Background (G_Level span) | set byte `DAT_100e0151` = 1 (flag `FUN_100120f0` asserts clear); caller `FUN_100015a0` (pak version-mismatch error path) | MED | dump (level-scroll-objects.md role rows) — ⚑ corrected (review wave 1, 2026-10-03) #M7 (new row) |
| `FUN_10011c00` | G_Level.cc | build level order list from encoded table | HIGH | read (not re-read in wave 1: level-scroll-objects.md role rows ⚑ corrected (review wave 1, 2026-10-03) #M7) |
| `FUN_10011b30` |  | is level in first-4 (unregistered) set | MED | read — ⚑ label audit (review wave 1) |
| `FUN_100122f0` | G_Level.cc | parse level file | HIGH | read |
| `FUN_10012230` | G_Level.cc | read pak entry `leve`, de-obfuscate, parse | MED | read — ⚑ corrected (wave 1, 2026-10-03): was "load level by tag" MED; see level-scroll-objects.md §6.1 — ⚑ label audit (review wave 1) |
| `FUN_100120f0` | G_Level.cc | load level by tag (asserts editor flag `DAT_100e0151` clear) | MED | read — ⚑ corrected (wave 1, 2026-10-03): was "level info by ID" MED; see level-scroll-objects.md §6.1 — ⚑ label audit (review wave 1) |
| `FUN_10011e30` | G_Level.cc | level tag → sector (0 if absent) | MED | read — ⚑ corrected (wave 1, 2026-10-03): was "sector number of current level" MED; see level-scroll-objects.md §8 — ⚑ label audit (review wave 1) |
| `FUN_10011de0` | G_Level.cc | level count (order-list length via `FUN_10000ce0`, 12) | MED | read — ⚑ corrected (wave 1, 2026-10-03): was "level count" LOW; see level-scroll-objects.md §8 — ⚑ label audit (review wave 1) |
| `FUN_10011f00` | G_Level.cc | sector → level tag (`none` if absent) | MED | read (level-scroll-objects.md §8) — ⚑ label audit (review wave 1) |
| `FUN_10011fd0` | G_Level.cc | load level by sector (info [+ object list]) | MED | read (level-scroll-objects.md §8) — ⚑ label audit (review wave 1) |
| `FUN_10012170` | G_Level.cc | free a level-object list | MED | read (level-scroll-objects.md §6.1) — ⚑ label audit (review wave 1) |
| `FUN_100121c0` | G_Level.cc | free the level order list | MED | read (level-scroll-objects.md §8) — ⚑ label audit (review wave 1) |
| `FUN_100125d0` | G_GameObject (span) | constructors: `FUN_100125d0` game object, `FUN_100141a0` entity | MED | dump (units-movement.md §10) |
| `FUN_10012650` | G_GameObject (span) | object reset (air = 1, layer `defa`, sprite none) | MED | dump (units-movement.md §3) |
| `FUN_10012840` | G_GameObject (span) | scale step +0x84 → +0x88 by +0x8c, clamp, dirty +0x34 | HIGH | listing `10012840–100128b0` (was MED dump) (sprite-geometry-draw.md §2.1) |
| `FUN_100128d0` | G_GameObject (span) | get position | MED | dump (units-movement.md §2.1) — ⚑ label audit (review wave 1) |
| `FUN_10012940` | G_GameObject (span) | half-size refresh when dirty: wh = GetDimensions(sprite, frame, scale +0x84); +0x2c/+0x30 = w/2, h/2 | HIGH | listing `10012940–100129fc` (was MED, scale arg unread) (sprite-geometry-draw.md §2.2) — ⚑ corrected (wave 2, 2026-10-03): was "half-size from sprite frame dims / 2" MED; see sprite-geometry-draw.md §2.2 |
| `FUN_10012a00` | G_GameObject (span) | entity bounds as Mac rect {t,l,b,r} | HIGH | listing (damage-health-death.md §2.2) |
| `FUN_10012ad0` | G_GameObject (span) | bounding box l,t,r,b = centre ± half size (trunc) | HIGH | listing (damage-health-death.md §2.2); dump (units-movement.md §2.1) |
| `FUN_10012bc0` | G_GameObject (span) | start hit glow (colour, speed, 32) unless active | HIGH | listing (damage-health-death.md §3) |
| `FUN_10012ca0` | G_GameObject (span) | integrate position; mode-1 keep test `x±hw` within [−128, 544], `y ≥ −128` (no half height), `y−hh ≤ 608`; mode 0 dead | HIGH | listing §8.6; bounds were MED (loose-ends-session.md §8.6) — ⚑ corrected (wave 2, 2026-10-03): was "integrate position: ground `y += scroll delta`; `x += vx; y += vy`; cull outside the area with margin 128" HIGH; see loose-ends-session.md §8.6 |
| `FUN_10012f20` | G_GameObject (span) | draw entry: if visibility > 0 → shadow (if +0x38 and SHADOWS) then sprite (if +0x37) | HIGH | listing `10012f20–10012f9c` (sprite-geometry-draw.md §3.2) |
| `FUN_10012fa0` | G_GameObject (span) | build draw command; layer from 4CC; terrain-stamp mode; fade alpha; main / tint / hit-glow passes | HIGH | listing `10012fa0–10013450` (role widened) (sprite-geometry-draw.md §2.1) — ⚑ corrected (wave 2, 2026-10-03): was "draw entity: draw-layer 4CC -> render layer" HIGH; see sprite-geometry-draw.md §2.1 |
| `FUN_10013460` | G_GameObject (span) | shadow: layer 2/4/6 (0 stamp), air = half-size at (−48,104)·0.5[·s], ground = (−6,8)·s; mode 2, alpha max(20, fade) | HIGH | listing `10013460–10014040` (was MED, perm F48-51) (sprite-geometry-draw.md §5.2) — ⚑ corrected (wave 2, 2026-10-03): was "draw entity shadow" MED; see sprite-geometry-draw.md §5.2 |
| `FUN_10014120` | (static init) | static initialiser (callee of `FUN_10000000`, before `main`): draw-command template `0x100e63e4` +0x04/+0x08 ← 0, clip +0x20..+0x2c ← {0, 0, 480, 416} (from `0x100d6788`), +0x38..+0x44 ← 0; `r2+0x100` +0x08/+0x0c ← 0 | HIGH | raw listing `10014120..10014194` (`$W/disasm-units.txt`): `1001412c addi r8,r2,0xb4`, `10014144/4c/54/60 stw …,0x20/0x24/0x28/0x2c(r8)` (sprite-geometry-draw.md §3.1) — ⚑ corrected (review wave 2, 2026-10-03) #C1: new row; was LOW "static init (entity globals)" in units-movement.md §10 |
| `FUN_10014650` |  | current state pointer (unit+0x4e0+s*0x5e0) | HIGH | read |
| `FUN_100142f0` | G_Entity.cc (span) | entity field reset (+0xac…+0xda = 0, +0xd8/+0xd9/+0x118 = −1, +0x13c..+0x13e = 0) | HIGH | listing `100143a4..10014474` (loose-ends-combat.md §4.2) — ⚑ corrected (wave 2, 2026-10-03): was "entity reset (target none `+0x118 = −1`, velocities 0)" MED; see loose-ends-combat.md §4.2 |
| `FUN_100144a0` | G_Entity.cc | allocate one zeroed 0x18 spawn record per spawn set of every state; +0x13e = 1 | HIGH | listing `100145b0..1001460c` (loose-ends-combat.md §4.2) — ⚑ corrected (wave 2, 2026-10-03): was "bind unit def to entity (unit cache +0x98); allocate per-state spawn-record lists (+0x19c+4s, 0x18-byte record…" MED; see loose-ends-combat.md §4.2 |
| `FUN_10014670` | G_Entity.cc (span) | switch entity to its first `UseThisStateOnWeaponPowerupRelease` state (+0x835 = 0x4e0 + 0x355) | MED | dump (units-movement.md §10, weapons-projectiles.md §2.5) — ⚑ label audit (review wave 1) |
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
| `FUN_10017150` | G_Entity.cc (span) | spawn-time rotation gate: if the state lacks DoRotateToTarget (+0x303) → +0xc1 = 0, return; else count +0xc4 down, hold rotation while +0xc4 > 0 or while any set with PauseAnyRotationWhileSpawning (+0x48) is mid-volley (0 < left < volley), else `FUN_100172d0` (turn toward target) | HIGH | listing `10017180 lbz r0,0x303(r31)`, `1001719c–100171c0` (+0xc4), `10017210 lwz r3,0x5dc(r31)`, `1001725c lbz r0,0x48(r25)`, `10017268–1001727c`, `100172a4 bl 0x100172d0` (fix-pass listing `$W/disasm-fix.txt`); only caller `FUN_10015b40` — ⚑ corrected (review wave 1, 2026-10-03) (conflict resolved): rotation gate wins (units-movement.md §8.2, spawn-and-waves.md §2.4, bosses.md §3.3); damage-health-death.md's "runtime spawn-set reader (LOW)" corrected in its §2.5 and INDEX updates — wave 2: confirmed by loose-ends-combat.md §7.1 (listing `10017150..100172c4`) |
| `FUN_100172d0` | G_Entity.cc (span) | turn sprite one direction step toward target point (+0x11c/+0x120) every FrameDelay; sets +0xc1 tracking flag | HIGH | listing (units-movement.md §8.2); spawn-and-waves.md §6 MED |
| `FUN_10017510` | G_Entity.cc (span) | flee target by 4CC code (13 codes), sets fleeing; perm F14-17 | HIGH | listing — ⚑ corrected (wave 1, 2026-10-03): was "flee targets" MED; see units-movement.md §6 |
| `FUN_10017a10` | G_Entity.cc (span) | ramp velocity to desired; stationary → zero; orbit rate | HIGH | listing (units-movement.md §5.6) |
| `FUN_10017b70` | G_Entity.cc (span) | hold position (accelerate away, HoldMaxSpeed / HoldDelta) | HIGH | listing (units-movement.md §5.3) |
| `FUN_10017c40` | G_Entity.cc (span) | reverse on reaction (desired = −dir·MaxSpeed) | HIGH | listing (units-movement.md §5.4) |
| `FUN_10017cb0` | G_Entity.cc (span) | state-entry spawn-set arming: per set rate, last = now, volley = left, delay draws, first volley armed at entry; +0xc4 = TimeToPause; +0xc3 "has sets" | HIGH | raw `10017d4c..10017db8`; caller `FUN_100146f0` — ⚑ corrected (wave 1, 2026-10-03): was "init state spawn-set timers" MED; see spawn-and-waves.md §2.2, bosses.md §3.3 |
| `FUN_10017e70` | G_Entity.cc (span) | switch to the first `UseThisStateOnShieldDepletion` state (+0x836) | HIGH | listing; caller `FUN_10014f10` (damage-health-death.md §3, units-movement.md §10) |
| `FUN_10017ef0` | G_Entity.cc (span) | rules #8/#9 "within range of a player": nearest active player with dist < range (strict), range ≠ 0 | HIGH | listing (units-movement.md §5.8, spawn-and-waves.md §6) |
| `FUN_10018070` | Notice | notice module init (registers NOTICE — debug-only, not added) | HIGH | listing (messages-notices-console.md §4) — ⚑ corrected (wave 2, 2026-10-03): was the umbrella "notice start / stop / reset / post / tick / draw (`FUN_10018070`…`FUN_100184b0`)" MED; the other five now have own rows; see messages-notices-console.md §4 |
| `FUN_100180e0` | Notice | notice module teardown | HIGH | listing (messages-notices-console.md §1) |
| `FUN_10018130` | Notice | notice reset (alpha 32, sound 'none', 'CEGA') | HIGH | listing (messages-notices-console.md §1) |
| `FUN_100181e0` | Notice | post / clear the single notice slot (hold, fade-in, delay, sound, alignment) | HIGH | listing (messages-notices-console.md §4.2) |
| `FUN_10018320` | Notice | notice tick per game tick: delay, sound, auto-clear after flli 71 = 60, fade-in −flli 72 = 2, fade-out +flli 73 = 4 | HIGH | listing `10018320..100184ac` (messages-notices-console.md §4.3) |
| `FUN_100184b0` | Notice | draw notice with format 49, alpha, alignment N+0x68 | HIGH | listing (messages-notices-console.md §1) |
| (undefined) `0x10018580` | Notice | NOTICE console handler (debug-only, unregistered → unreachable; no Ghidra function) | HIGH | raw listing (messages-notices-console.md §4); not counted in the `FUN_` row counts |
| `FUN_10018670` | Notice | static initialiser | LOW | listing shape (messages-notices-console.md role rows) |
| `FUN_100189f0` |  | clear the 16 render-layer queue heads (`*(r2-0x7198)`) | MED | listing `100189f0..10018a38`; callers begin frame, session start, level start (timing-frame.md §1) |
| `FUN_10018a40` | U_Sprite.cc | queue or draw a command (when `DAT_100e0171` is 0: alpha 0, scale 1) | HIGH | listing `10018a40–10018b10` (sprite-geometry-draw.md §3.2) |
| `FUN_10018b20` | U_Sprite.cc | flush render-layer bands: 0 → layers 0–1, 1 → 2–5, 2 → 6–15 (`FUN_1001a650(n)`); other arguments flush nothing; caller end frame `FUN_10030bc0` | HIGH | listing (`$W/disasm-review2.txt`) `10018b54 li r3,0x0; bl 0x1001a650; li r3,0x1; bl` (band 0), `10018b68..10018b84` `li r3,0x2..0x5` (band 1), `10018b8c..10018bd8` `li r3,0x6..0xf` (band 2); `10018b44 b 0x10018bdc` = the negative-argument exit (sprite-geometry-draw.md §6, timing-frame.md §2.3) — ⚑ label rule (wave 2 synthesis): both files propose HIGH on dump only — ⚑ label audit (review wave 2): raised back to HIGH on the listing |
| `FUN_10018d20` | U_Sprite.cc | load sprite group (IC+IA plates -> frames) | HIGH | read — ⚑ corrected (wave 2, 2026-10-03): was without the size asserts; it also asserts frame w ≤ 300, h ≤ 256 (`kU_Sprite_MaxDimensions`, listing `100191ac`, `100191d4`); see sprite-geometry-draw.md §1.1 |
| `FUN_10019530` | U_Sprite.cc | sprite group loaded? | HIGH | listing (sprite-geometry-draw.md §1) |
| `FUN_1001f140` | U_SpritePlate.cc | scan plate -> rect list | HIGH | read |
| `FUN_1001f1c0` | U_SpritePlate.cc | plate key-pixel checks + frame loop | HIGH | read |
| `FUN_1001f340` |  | next frame rect | HIGH | read |
| `FUN_1001f4e0` |  | strip height | HIGH | read |
| `FUN_1001f540` |  | cell width | HIGH | read |
| `FUN_1001f5b0` |  | trim cell to content | HIGH | read |
| `FUN_1001d780` | U_SpriteBlit.cc | encode frame: 0x18 header (magic 0x499602d2, w, h, key, alpha offset) + RGB555 + alpha map | HIGH | read (sprite-sound-containers.md §2.3a) — ⚑ corrected (review 2026-10-03) #9: was MED, caller only |
| `FUN_1001eec0` | U_SpriteBlit.cc | build alpha map from alpha plate: red 5-bit channel, 31/key → 32 (transparent), empty row → 1000 | HIGH | read — ⚑ corrected (review 2026-10-03) #9 |
| `FUN_1001d9f0` | U_SpriteBlit.cc | blit frame: colour key, or alpha blend (dst·a+src·(32−a))/32 | HIGH | read — ⚑ corrected (review 2026-10-03) #9 |
| `FUN_1001dd20` | U_SpriteBlit.cc | mode 2 shadow blit: dst·a/32 under the silhouette | HIGH | listing `1001ddb4 lhz r3,0(r26); andi. r0,r3,0x7c1f; rlwimi r0,r3,0xf,0x7,0xb; mullw r3,r0,r21; rlwinm r0,r3,0x1b,0x5,0x1f; andi. 0x7c1f; rlwimi r0,r3,0xc,0x16,0x1a; 1001ddd0 sth` (review wave 2 M3) (sprite-geometry-draw.md §5.2) — ⚑ label rule (wave 2 synthesis): proposed HIGH on "dump" only — ⚑ corrected (review wave 2, 2026-10-03) #M3: raised back to HIGH on the listing |
| `FUN_1001df00` | U_SpriteBlit.cc | mode 3 tint blit: (dst·a + colour·(32−a))/32 under the silhouette | HIGH | listing `1001df94 subfic r12,r8,0x20`, `1001dfa8 mullw r31,r31,r8`, `1001dfac mullw r12,r30,r12`, `1001dfb0 add`, `1001dfb4..1001dfbc` repack, `1001dfc0 sth` (review wave 2 M3) (sprite-geometry-draw.md §4.2) — ⚑ label rule (wave 2 synthesis): proposed HIGH on "dump" only — ⚑ corrected (review wave 2, 2026-10-03) #M3: raised back to HIGH on the listing |
| `FUN_1001e9d0` | U_SpriteBlit | RGB555 two-source blend floor((A·a+B·(32−a))/32) | HIGH | listing §6 (loose-ends-session.md §6) |
| `FUN_10019570` | U_Sprite.cc | sprite draw dispatcher (mode flags, clip, scale path, `COST` rect) — not a decoder | HIGH | read (sprite-sound-containers.md §2.3a) — ⚑ corrected (review 2026-10-03) #9 |
| `FUN_10019ad0` | U_Sprite.cc | frame pointer of (group id, frame); out of range → frame 0 + log | HIGH | listing `10019b4c–10019bc4` (sprite-geometry-draw.md §1) |
| `FUN_10019c00` | U_Sprite.cc (span) | set port indices `DAT_100e0179` (normal) / `DAT_100e0170` (flag 8) | MED | dump; caller `FUN_10018740` (sprite-geometry-draw.md role rows) — ⚑ label rule (wave 2 synthesis): proposed HIGH on "dump; caller `FUN_10018740`" only — ⚑ label audit (review wave 2): MED settled — the owning file had no listing line or data bytes for it, so its row was lowered to MED too |
| `FUN_10019c10` | U_Sprite.cc | same, from a frame pointer | HIGH | listing `10019c10–10019c98` (sprite-geometry-draw.md §1) |
| `FUN_1001ec80` | U_SpriteBlit.cc | in-place blend of a buffer toward a colour (draw type `COST`, a = 32 no-op) | MED | read — ⚑ corrected (review 2026-10-03) #9 — ⚑ corrected (review wave 2, 2026-10-03) #C5: wording unified with loose-ends-session.md §6 (was "draw translucent solid-colour rect"); ⚑ label audit (review wave 2): was HIGH on read only (body not listing-read; its call sites are, e.g. `1000b9fc`) |
| `FUN_10019ca0` | U_Sprite.cc | U_Sprite_GetDimensions(id, frame, &wh, scale f1): load-on-miss, w' = trunc(w·s), h' = trunc(h·s) | HIGH | listing `10019e34–10019eb8` (was MED "sprite dimensions / draw frame", strings) (sprite-geometry-draw.md §1) — ⚑ corrected (wave 2, 2026-10-03): was "sprite dimensions / draw frame" MED; see sprite-geometry-draw.md §1 |
| `FUN_10019ee0` | U_Sprite.cc | frame count of a group (error message only) | LOW | caller context, not read (sprite-geometry-draw.md role rows) |
| `FUN_1001a260` | U_Sprite.cc (span) | percent int → float /100 | HIGH | listing `1001a260–1001a28c` (sprite-geometry-draw.md §2.3) |
| `FUN_1001a290` | U_Sprite.cc (span) | set `DAT_100e0172` (scaled alpha maps on/off) | MED | dump (sprite-geometry-draw.md §4.4) — ⚑ label rule (wave 2 synthesis): proposed HIGH on "dump" only — ⚑ label audit (review wave 2): MED settled — the owning file had no listing line or data bytes for it, so its row was lowered to MED too |
| `FUN_1001a2a0` | U_Sprite.cc | sprite manager integrity check (magic, w ≤ 300, h ≤ 256, depth ≤ 16) | HIGH | listing `1001a394`, `1001a3b4`; string (sprite-geometry-draw.md §1.1) |
| `FUN_1001a450` | U_Sprite.cc | append command to the per-layer render list (grows ×2) | MED | dump; strings "Sprite Render List expanded" (sprite-geometry-draw.md §6) — ⚑ label rule (wave 2 synthesis): proposed HIGH on "dump; strings "Sprite Render List expanded"" only — ⚑ label audit (review wave 2): MED settled — the owning file had no listing line or data bytes for it, so its row was lowered to MED too |
| `FUN_1001a650` | U_Sprite.cc | flush one render layer; layers 0/1 consumed | MED | dump (sprite-geometry-draw.md §6) — ⚑ label rule (wave 2 synthesis): proposed HIGH on "dump" only — ⚑ label audit (review wave 2): MED settled — the owning file had no listing line or data bytes for it, so its row was lowered to MED too |
| `FUN_1001a6f0` / `FUN_1001aa90` | U_SpriteBlit.cc | scaled blit (unclipped / clipped): centred, size trunc(w·s), mode by stack byte | HIGH | listing `1001a75c–1001a7e8`, `1001ab0c–1001ab80` (sprite-geometry-draw.md §3.3) |
| `FUN_1001c270` `FUN_1001c480` `FUN_1001c6c0` `FUN_1001c8f0` `FUN_1001b7d0` `FUN_1001ba40` `FUN_1001bcf0` `FUN_1001bfd0` | U_SpriteBlit.cc | scaled blit modes 0–3 without / with alpha map | LOW | callers in `FUN_1001a6f0` only, not read (sprite-geometry-draw.md role rows) |
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
| `FUN_10021470` | G_Scores.cc (span) | score > 15th high score (signed, strict) | HIGH | listing + brute force (`10021494..100214a4`, same idiom as `FUN_10009750`; ⚑ corrected (review wave 2, 2026-10-03) #M1: review's "unsigned" checked and not adopted) — ⚑ corrected (wave 1, 2026-10-03): was "score beats 15th high score" MED; see scoring-bonuses.md §9.1 |
| `FUN_100214c0` | G_Scores.cc (span) | insert 1–2 scores into the 15-row table (two prefs copies; P1 wins same-slot ties; two-player shift quirk) then name entry | HIGH | listing + simulation §3.1; was MED (loose-ends-session.md §3.1) — ⚑ corrected (wave 2, 2026-10-03): was "high-score insertion for 1–2 players, then scores-screen name edit" MED; see loose-ends-session.md §3.1 |
| `FUN_10021950` | G_Scores.cc | scores screen: 600 ticks (F78), click/key exit, `N` → 1P game | HIGH | `10021ab4 li r3,0x4e` (front-end.md §4.1) — ⚑ corrected (wave 2, 2026-10-03): was "scores screen" MED; see front-end.md §4.1 |
| `FUN_10021bd0` | G_Scores.cc | name entry: 20 chars, ctype 0xdc, Return commits, BS, blink F82/F83, linger F79, easter eggs, empty → "Jar Jar Must Die"; stores the name as the player's default; commits prefs via `FUN_100047f0` | HIGH | listing `10021d90…100221f4` (front-end.md §4.3; loose-ends-session.md §3.2 MED from dump + key branches) — ⚑ corrected (wave 2, 2026-10-03): was "scores screen input/flash" MED; see front-end.md §3.2 |
| `FUN_100222f0` | G_Scores.cc | scores layout: headers FMT 10–12, 15 rows y F77+F76·r, ship symbol F80/F81, FMT 13–21 | HIGH | listing indices (front-end.md §4.2) — ⚑ corrected (wave 2, 2026-10-03): was "scores layout" MED; see front-end.md §4.2 |
| `FUN_10022880` / `FUN_100260b0` |  | free list items | MED | read (front-end.md §10) — ⚑ label rule (wave 2 synthesis): proposed HIGH on "read" only — ⚑ label audit (review wave 2): MED settled — the owning file had no listing line or data bytes for it, so its row was lowered to MED too |
| `FUN_100229a0` | G_Interface.cc | main menu loop: copyright flip F68, hover, event dispatch, button actions | HIGH | listing `10022ab4…10022cb8`; front-end.md §2 (front-end.md §2) — ⚑ corrected (wave 2, 2026-10-03): was "interface main loop" MED; see front-end.md §2 |
| `FUN_10022ed0` / `FUN_10022ee0` / `FUN_10023030` |  | set/get quit `b8`; get suspended `b7` | HIGH | `100490f8 bl 0x10022ee0` (front-end.md §10) |
| `FUN_100234d0` | G_Interface.cc | start game (mode 0 play / 1 replay `last` / 2 demo; players): level select or film, run, return-to-menu fades, then pref-3 update and high-score gates (film / cheat / quit `DAT_100e01b8` / start sector > 1) | HIGH | listing `10023640..100238a8` (loose-ends-session.md §2.2), call order `10023518…10023a98` (front-end.md §3) — ⚑ corrected (wave 2, 2026-10-03): was "start game (level select, play, high score)" MED; see loose-ends-session.md §2.2, front-end.md §3 |
| `FUN_10023b00` | G_Interface.cc | menu keys 1/N/Return,2,P,H/S,D,R,F,Q, 0x9D/0x8A volume | HIGH | listing `10023b10…`; §2.8 (front-end.md §2.8) |
| `FUN_10023da0` / `FUN_10023e10` | G_Interface.cc | suspend / resume (+ registration detect, SND 10, remove REGISTER) | MED | read (front-end.md §1) |
| `FUN_10022ef0` | ~after G_Scores | modal pause screen: SND 8 (gaso[8]), music paused, polls Caps Lock 0x39 (no event loop) until released, resumes music; returns 1 when quit was requested meanwhile | HIGH | listing `10022f18…10023010` (front-end.md §8; timing-frame.md §2.4, messages-notices-console.md and loose-ends-session.md agree at MED from the dump) — ⚑ corrected (wave 2, 2026-10-03): was "pause screen" MED; see front-end.md §8 |
| `FUN_10023040` | G_Interface.cc | loading progress line (FMT 0, F64 spacing) | MED | `100231ac li r3,0x40` (front-end.md §1) — ⚑ corrected (wave 2, 2026-10-03): was "progress text line" MED; see front-end.md §1 |
| `FUN_10023330` | G_Interface.cc | menu command: 1 About→credits, 2 Quit | MED | read; §2.6 (front-end.md §2.6) — ⚑ label rule (wave 2 synthesis): proposed HIGH on "read; §2.6" only — ⚑ label audit (review wave 2): MED settled — the owning file had no listing line or data bytes for it, so its row was lowered to MED too |
| `FUN_10023380` | G_Interface.cc | load 28 `inte` strings (table `PTR_DAT_100df288`, 256 B each) | HIGH | loop bound 0x1c (front-end.md §2.3) |
| `FUN_10023410` | G_Interface.cc | draw menu (menubar, `back`, element fade-in) | MED | read (front-end.md §2.3) — ⚑ label rule (wave 2 synthesis): proposed HIGH on "read" only — ⚑ label audit (review wave 2): MED settled — the owning file had no listing line or data bytes for it, so its row was lowered to MED too |
| `FUN_10023fd0` | G_Interface.cc | build button list (logo, 1P, 2P, PREFS, SCORES, DEMOS, QUIT, [REGISTER], web, copyright) | HIGH | SPR 3/4/5 listing; §2.1 (front-end.md §2.1) — ⚑ corrected (wave 2, 2026-10-03): was "interface buttons/logo sprites" MED; see front-end.md §2.1 |
| `FUN_10024280` / `FUN_10024360` / `FUN_10024430` / `FUN_10024750` | G_Interface.cc | remove button / free list / add button (0x124 struct) / exists | HIGH | listing stores `10024498…1002450c` (front-end.md §10) |
| `FUN_10024530` | G_Interface.cc | hover hit-test, SND 11 on hilite entry (not logo) | HIGH | `10024650 li r3,0xb` (front-end.md §2.1) |
| `FUN_100246c0` | G_Interface.cc | key flash: hilite, wait F61 ticks | HIGH | `10024700 li r3,0x3d` (front-end.md §2.8) |
| `FUN_10024810` / `FUN_10024900` / `FUN_10024a00` / `FUN_10024cb0` | G_Interface.cc | redraw-if-dirty / set hilite / unhilite all / set text | MED | read (front-end.md §2.4) — ⚑ label rule (wave 2 synthesis): proposed HIGH on "read" only — ⚑ label audit (review wave 2): MED settled — the owning file had no listing line or data bytes for it, so its row was lowered to MED too |
| `FUN_10024a50` | G_Interface.cc | click tracking (SND 2, StillDown loop, released-inside) | HIGH | `10024b30` (front-end.md §2.6) |
| `FUN_10024d80` / `FUN_10024db0` / `FUN_10024de0` / `FUN_10024e10` | G_Interface.cc | button actions: `FUN_100234d0(0,1)` 1P / `(0,2)` 2P / `(2,1)` attract demo / `(1,1)` replay Last Film | MED | read/dump (front-end.md §2.7; loose-ends-session.md §7) — ⚑ label rule (wave 2 synthesis): both files propose HIGH on read/dump only — ⚑ label audit (review wave 2): MED settled — the owning file had no listing line or data bytes for it, so its row was lowered to MED too |
| `FUN_10024e40` | G_Interface.cc | PREFERENCES → `FUN_100047c0(0)`, `b6 = 1` | MED | read (front-end.md §2.7) |
| `FUN_10024e70` / `FUN_10025060` | G_Interface.cc | SCORES / credits action, `N` → 1P game, menu redraw | MED | read (front-end.md §4.1) — ⚑ label rule (wave 2 synthesis): proposed HIGH on "read" only — ⚑ label audit (review wave 2): MED settled — the owning file had no listing line or data bytes for it, so its row was lowered to MED too |
| `FUN_10024f90` | G_Interface.cc | menu QUIT: flash button (F61 delay), set the leave-menu / leave-app flag | HIGH | `10025008 li r3,0x3d` (front-end.md §2.7; loose-ends-session.md MED from the dump) |
| `FUN_10025190` / `FUN_10025270` | G_Interface.cc | REGISTER / web-link (inte 19–23, ICLaunchURL) | MED | read (front-end.md §2.7) |
| `FUN_10025330` / `FUN_100253d0` / `FUN_100232d0` | G_Interface.cc | progress list new / clear / fade-out F160 | HIGH | `100232ec li r3,0xa0` (front-end.md §1) |
| `FUN_10025420` | G_Interface.cc | menu elements: x F52/2, y F62 + i·F63; FMT 1–7 by type/hilite | HIGH | `10025574…100255a4` (front-end.md §2.2) — ⚑ corrected (wave 2, 2026-10-03): was "button layout" MED; see front-end.md §2.2 |
| `FUN_10025770` / `FUN_10025840` / `FUN_10025890` / `FUN_100258e0` | G_Interface.cc | free / fade in / fade out / draw element list | HIGH | F160 listing (front-end.md §10) |
| `FUN_10025920` | G_Interface.cc | volume −10 / +10 on charCode 0x9D / 0x8A | HIGH | listing `1002592c` (front-end.md §2.8) |
| `FUN_10025b90` | G_Credits.cc | paged credits: `<page N>` ticks, `<title>`, F74/F75, 60-tick gap | HIGH | listing `10025d50 li r3,0x3c` (front-end.md §6) — ⚑ corrected (wave 2, 2026-10-03): was "credits" MED; see front-end.md §6 |
| `FUN_10025970` | G_Interface.cc | advert `adve`; F67 minimum when after a cut-off game; click/key exit | HIGH | `10025a2c li r3,0x43` (front-end.md §5.3) — ⚑ corrected (wave 2, 2026-10-03): was "advertisment screen" MED; see front-end.md §5.3 |
| `FUN_10025b00` / `FUN_100228d0` |  | static initialisers | LOW | caller `FUN_10000000` (front-end.md §10) — ⚑ caution ⚑ corrected (review wave 2, 2026-10-03) #C1: `FUN_100228d0` writes the scores symbol template `0x100e8964` before `main`; its data-image bytes are not runtime values (INDEX #56) |
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
| `FUN_10026c20` | G_Player.cc | in game and life state 1 (out of lives) | MED | dump (player-physics.md §4) — ⚑ label audit (review wave 1) |
| `FUN_10026c50` | G_Player.cc | get life state (+0xc6) | MED | dump (player-physics.md §4, damage-health-death.md §5.1) — ⚑ label audit (review wave 1) |
| `FUN_10026c60` | G_Player.cc | life state == arg (+0xc6) | MED | dump (player-physics.md §4, damage-health-death.md §5.1) — ⚑ label audit (review wave 1) |
| `FUN_10026c80` | G_Player.cc | set life state + enter time | HIGH | dump; callers `FUN_10026410`, `FUN_100269a0` (player-physics.md §4) |
| `FUN_10026ca0` | G_Player.cc | get plde pointer (+0x94) | MED | dump (player-physics.md §1) — ⚑ label audit (review wave 1) |
| `FUN_10026cb0` | G_Player.cc | max speed = active_DefaultMaxSpeed | HIGH | disasm (player-physics.md §2.1) |
| `FUN_10026cc0` | G_Player.cc | init session lives (life_NumInitial if start sector 1 else 1), extra-life threshold = life_InitialRequiredScore (+0x9c), step 0 | HIGH | listing `10026ce0..10026d18`, `10026838` (scoring-bonuses.md §3.2, player-physics.md §7, level-scroll-objects.md §8) |
| `FUN_10026d50` | G_Player.cc | get / set lives (`FUN_10026d60`; stored ± 0x1524DCEF) | HIGH | listing (player-physics.md §7, scoring-bonuses.md §2) |
| `FUN_10026d70` | G_Player.cc | add one life, cap life_MaxNum, spawn life_Spawn_ID | HIGH | listing `10026d84..10026dc0` (scoring-bonuses.md §3.3, player-physics.md §7) |
| `FUN_10026ea0` | G_Player.cc | clear overload + glow fields | MED | dump (player-physics.md §6.2) — ⚑ label audit (review wave 1) |
| `FUN_10026ee0` | G_Player.cc | overload warning pulse; the Nth (powerupOverload_NumWarnings, 8) warning destroys the ship | HIGH | disasm `10026f0c..100270d8` (player-physics.md §6.2, weapons-projectiles.md §2.6) |
| `FUN_10027400` | G_Player.cc | reset shield (100 / 0) + hit timers | HIGH | disasm (player-physics.md §3) |
| `FUN_10027490` | G_Player.cc | shield += value, clamp [0,100], skip if 0 or not in game | HIGH | listing (loose-ends-combat.md §3.2) — ⚑ corrected (wave 2, 2026-10-03): was "add shield, clamp [0,100]" HIGH; see loose-ends-combat.md §3.2 |
| `FUN_10027540` | G_Player.cc | get / set shield (`FUN_10027560`; stored + 1324366.0) | HIGH | listing (damage-health-death.md §5.1, player-physics.md §3) |
| `FUN_10027580` | G_Player.cc | money = 0 | HIGH | disasm (player-physics.md §7) |
| `FUN_100275b0` | G_Player.cc | add / get / set money (`FUN_10027610` / `FUN_10027620`; stored ± 0xB2CCE) | HIGH | listing `10027738` (scoring-bonuses.md §5.2, player-physics.md §7) |
| `FUN_10027630` | G_Player.cc | reset coin-tally (money-counter display) fields | MED | read (scoring-bonuses.md §6.5, player-physics.md) |
| `FUN_10027db0` | G_Player.cc | coin tally started (player +0xd8 ≠ 0) | HIGH | listing; writer `FUN_10027670` `100276a0` (loose-ends-combat.md §3.3) — ⚑ corrected (wave 2, 2026-10-03): was "coin tally started / money counter running (+0xd8 ≠ 0)" MED; see loose-ends-combat.md §3.3 |
| `FUN_10027dd0` | G_Player.cc | player invulnerable flag (+0xce) | HIGH | disasm (player-physics.md §4.4, damage-health-death.md §5.1) |
| `FUN_10027de0` | G_Player.cc | set/clear invulnerable `+0xce` with sticky `+0xcf` (sticky only from console GOD) | HIGH | listing `10027de0..10027e40` + raw call `10008518` (loose-ends-combat.md §3.3) — ⚑ corrected (wave 2, 2026-10-03): was "set/clear invulnerability (+ sticky)" MED; see loose-ends-combat.md §3.3 |
| `FUN_100298c0` | G_Player.cc | draw player (state 4): weapons, sprite passes, coin-tally text while alpha < 32 | MED | dump; caller `FUN_10007070` (player-physics.md, scoring-bonuses.md) |
| `FUN_100299c0` | G_Player.cc | reset / get / set score (`FUN_100299f0` / `FUN_10029a00`; stored ± 0x05532A3E) | HIGH | disasm (player-physics.md §7, scoring-bonuses.md §2, level-scroll-objects.md §8) |
| `FUN_10029b20` | G_Player.cc | step score multiplier 1→2→3→4→5→10 | HIGH | jump table `0x100e93c0` (player-physics.md, scoring-bonuses.md §4) |
| `FUN_10029bd0` | G_Player.cc | get multiplier / `FUN_10029fd0` reset to 1 | MED | dump (player-physics.md, scoring-bonuses.md §4) — ⚑ label audit (review wave 1) |
| `FUN_10029be0` | G_Player.cc | get / set flag +0xbd (`FUN_10029bf0`) | LOW | dump (player-physics.md) |
| `FUN_10029c00` | G_Player.cc | advance the player's weapon of a type ('PEAA' air / 'PEAG' ground) to the next one available at the sector; **callers found**: raw calls `10008408` ('PEAA'), `10008490` ('PEAG') inside the debug command `PLAYER AIRWEP` (alias `AIR`) / `PLAYER GROUNDWEP` (alias `GROUND`) (sub-keywords of the PLAYER handler `0x10007ff0`), which is not registered in 1.0.6 → unreachable in release | HIGH | raw listing `10008404 addi r4,r30,0x4141; 10008408 bl`, `1000848c addi r4,r30,0x4147; 10008490 bl`; strings `AIRWEP` `0x100e41fc`, `AIR` `0x100e4203`, `GROUNDWEP` `0x100e4207`, `GROUND` `0x100e4211` (data image) (messages-notices-console.md §5.5; loose-ends-session.md role rows) — ⚑ corrected (wave 2, 2026-10-03): was "advance / re-assign the player's weapon of a type for the sector (no direct caller)" MED; see messages-notices-console.md §5.5 — ~~⚑ conflict: messages-notices-console.md names the command PLAYER AIR/GROUND (sub-commands) at MED; loose-ends-session.md names it AIRWEP/GROUNDWEP at HIGH; kept MED (body not listing-walked by either)~~ ⚑ corrected (review wave 2, 2026-10-03): not a conflict — both are the PLAYER sub-keywords (session had dropped the prefix); wording harmonised in all six places, HIGH for the code + strings |
| `FUN_10029cb0` | G_Player.cc | get +0xc0 (level ref) | MED | dump (player-physics.md) |
| `FUN_10029cc0` | G_Player.cc | become active / respawn: start pos, v 0, state 4, appear fade, spawn entry unit | HIGH | disasm (player-physics.md §4.1) |
| `FUN_10029f10` | G_Player.cc | reset ship sprite/frame; `FUN_10029f60` ship sprite = displayed weapon's appearance face | HIGH | disasm (player-physics.md, weapons-projectiles.md §5) |
| `FUN_1002a150` | G_Player.cc | life-state step (entering, dying, lives decrement, game over, invulnerability expiry) | HIGH | disasm (player-physics.md §4) |
| `FUN_1002a450` | G_Player.cc | load-and-check a permanent unit def | MED | strings (player-physics.md) |
| `FUN_1002a4f0` | (static init) | spawn-request template statics | LOW | dump (player-physics.md) — ⚑ caution ⚑ corrected (review wave 2, 2026-10-03) #C1: writes `0x100e9178…` before `main` (INDEX #56) |
| `FUN_1002a5b0` | G_Debris.cc (span) | register / tear down (`FUN_1002a610`) "Debris" + NUMDEBRIS console command | MED | strings (player-physics.md) |
| `FUN_1002a610` | G_Debris.cc (span) | debris teardown | MED | decompile (particles-debris-blur.md §3) |
| `FUN_1002a660` | G_Debris.cc | per-level reset of the obstacle-rect list | MED | decompile + assert string; caller `FUN_100064d0` (particles-debris-blur.md §3) — ⚑ label rule (wave 2 synthesis): proposed HIGH on "decompile + assert string; caller `FUN_100064d0`" only — ⚑ label audit (review wave 2): MED settled — the owning file had no listing line or data bytes for it, so its row was lowered to MED too |
| `FUN_1002a6d0` | G_Debris.cc | add obstacle rect (16 bytes) — unchanged | HIGH | listing `1002a6d0..1002a760` (particles-debris-blur.md §3) — ⚑ corrected (wave 2, 2026-10-03): was "add debris rect" MED; see particles-debris-blur.md §3 |
| `FUN_1002a770` | G_Debris.cc (span) | per tick: shift every obstacle rect's top/bottom by the scroll delta | HIGH | listing; caller `FUN_10006b50` `10006bd8` (particles-debris-blur.md §3) |
| `FUN_1002a830` | G_Debris.cc | rect vs obstacle list, inclusive on all sides (was MED decompile) | HIGH | listing `1002a8a4..1002a8e4` (particles-debris-blur.md §3) — ⚑ corrected (wave 2, 2026-10-03): was "rect vs debris list (inclusive)" MED; see particles-debris-blur.md §3 |
| `FUN_1002a920` | G_Debris.cc (span) | obstacle count (NUMDEBRIS callback?) | LOW | no direct caller (particles-debris-blur.md §3) |
| `FUN_1002a950` | G_Debris.cc (span) | free all obstacles + list | MED | decompile (particles-debris-blur.md §3) |
| `FUN_1002aa70` | (static init) | `"nonenone"` string pair template | LOW | decompile; caller `FUN_10000000` (particles-debris-blur.md §3) |
| `FUN_1002aa90` / `FUN_1002aad0` | G_WeaponDefinitions.cc (span) | register+build / unregister+free the weapon list | MED | decompile; callers `FUN_100000e0` / `FUN_10000630` (particles-debris-blur.md §3) |
| `FUN_1002ba00` | G_WeaponDefinitions.cc | parse weapon definition | MED | read — ⚑ label audit (review wave 1) |
| `FUN_1002ab20` | G_WeaponDefinitions.cc | build master weapon list (wede tags in index order) | MED | read; caller `FUN_1002aa90` (weapons-projectiles.md §1.1) — ⚑ label audit (review wave 1) |
| `FUN_1002acf0` | G_WeaponDefinitions.cc | i-th weapon definition | MED | read (weapons-projectiles.md §1.3) — ⚑ label audit (review wave 1) |
| `FUN_1002adb0` | G_WeaponDefinitions.cc | next weapon of type available at level after current (wraps; `none` → first) | HIGH | listing `1002ae30…1002ae8c` (weapons-projectiles.md §2.4) |
| `FUN_1002aec0` | G_WeaponDefinitions.cc | list of unit IDs a weapon references | MED | read (weapons-projectiles.md §1.3) — ⚑ label audit (review wave 1) |
| `FUN_1002b150` | G_WeaponDefinitions.cc | is unit referenced by any weapon (no caller found) | MED | read (weapons-projectiles.md §1.3) |
| `FUN_1002b240` | G_WeaponDefinitions.cc | free ID list | MED | read (weapons-projectiles.md §1.3) — ⚑ label audit (review wave 1) |
| `FUN_1002b2a0` | G_WeaponDefinitions.cc | weapon-def defaults (magic, none IDs, sound defaults) | HIGH | read + image `0x100d7014` (weapons-projectiles.md §1.2) |
| `FUN_1002b3a0` | G_WeaponDefinitions.cc | preload PEAA/PEAG/SPEC weapons for the level | MED | read; caller `FUN_100064d0` (weapons-projectiles.md §1.1) — ⚑ label audit (review wave 1) |
| `FUN_1002b400` | G_WeaponDefinitions.cc | collect weapon sprite (1) / sound (0) IDs (no caller found) | MED | read (weapons-projectiles.md §1.3) |
| `FUN_1002b590` | G_WeaponDefinitions.cc | free master weapon list | MED | read (weapons-projectiles.md §1.1) — ⚑ label audit (review wave 1) |
| `FUN_1002b6d0` | G_WeaponDefinitions.cc | preload weapons of a type at a level | MED | read (weapons-projectiles.md §1.1) — ⚑ label audit (review wave 1) |
| `FUN_1002b790` | G_WeaponDefinitions.cc | preload one weapon's sprites / sound / units | MED | read (weapons-projectiles.md §1.1) — ⚑ label audit (review wave 1) |
| `FUN_1002b8e0` | G_WeaponDefinitions.cc | load i-th wede tag (0x208-byte def) | MED | read (weapons-projectiles.md §1.1) — ⚑ label audit (review wave 1) |
| `FUN_1002c490` | G_WeaponDefinitions.cc | init weapon spawn record (0x34) | MED | read (weapons-projectiles.md §1.2) — ⚑ label audit (review wave 1) |
| `FUN_1003beb0` | G_WeaponHandler.cc | bomb press: n = min(sector + F151 − 1, F152), +0x84 = n−1, launch | HIGH | listing `1003beb0..1003bf74` (loose-ends-combat.md §6.6) — ⚑ corrected (wave 2, 2026-10-03): was "start bomb salvo: n = min(sector + F151 − 1, F152)" HIGH; see loose-ends-combat.md §6.6 |
| `FUN_1003b3c0` | G_WeaponHandler.cc | per-tick weapon handler: held counters, release, power-ups, select (SND18), air fire, bomb salvo, crosshair, launches; returns 1 overload / 2 release | HIGH | listing — ⚑ corrected (wave 1, 2026-10-03): was "weapon selector switch" MED; see weapons-projectiles.md §2.3 |
| `FUN_1003ade0` | G_WeaponHandler.cc | weapons-handler setup: reset, crosshair fade rates F149/150, default ground weapon (DEAG) + starting air weapon (`FUN_1003cdb0`) | HIGH | listing `1003ae48…1003af3c` — ⚑ corrected (wave 1, 2026-10-03): was "crosshair fade" MED; see weapons-projectiles.md §2.1 |
| `FUN_1003cca0` | G_WeaponHandler.cc | first weapon whose default is DEAA (arg 0) / DEAG (arg ≠ 0); level ignored | HIGH | read + caller listing — ⚑ corrected (wave 1, 2026-10-03): was "is default air/ground weapon (DEAA/DEAG)" MED; see weapons-projectiles.md §2.4 |
| `FUN_1003c0d0` | G_WeaponHandler.cc | air power-up machine: activation on held ≥ +0x1c8; level step every +0x1d0+1 ticks to max +0x1d4; overload at activation + +0x1d8 → return 1; release (or DoReleaseOnMaxPowerLevel) → state 3 + `FUN_10034ce0`, spawns every +0x1e0+1 | HIGH | listing `1003c148…1003c4d4` — ⚑ corrected (review 2026-10-03) #9 — ⚑ corrected (wave 1, 2026-10-03): was "air-weapon power-up state machine: spawn power-up unit (+0x1cc) after delay +0x1c8; charge … overload after +0x1d8 (state 2); release at max if +0x1e4 (state 3, `FUN_10034ce0`)" MED; see weapons-projectiles.md §2.5 |
| `FUN_1003c4f0` | G_WeaponHandler.cc | GROUND weapon launch: spawn records with speed ratio to the crosshair distance, then `crosshairSpawnOnActivation` (+0x180); the air launch is `FUN_1003c7a0` | HIGH | listing `1003c578…1003c784` — ⚑ corrected (review 2026-10-03) #9 — ⚑ corrected (wave 1, 2026-10-03): was "launch weapon: spawn each `spawn_*` record (unit +0x20 at player pos + XLoc/YLoc, heading +0x2c/+0x30) via `FUN_10033220`, then `crosshairSpawnOnActivation` (+0x180)" MED; see weapons-projectiles.md §3.2 |
| `FUN_1003af90` | G_WeaponHandler.cc | handler reset (arg 1: auto-equip weapon unlocked at sector; pending apply; keeps weapons) | HIGH | listing `1003b0ac…1003b134` (weapons-projectiles.md §2.4) |
| `FUN_1003b180` | G_WeaponHandler.cc | set weapon of type (immediate if no power-up active, else pending); AUX toggle | HIGH | listing (weapons-projectiles.md §2.4) |
| `FUN_1003b340` | G_WeaponHandler.cc | current weapon of type | MED | read (weapons-projectiles.md §2.2) — ⚑ label audit (review wave 1) |
| `FUN_1003bab0` | G_WeaponHandler.cc | crosshair locked/unlocked frame | HIGH | listing (weapons-projectiles.md §2.8) |
| `FUN_1003bb00` | G_WeaponHandler.cc | set handler x,y | MED | read (weapons-projectiles.md §2.2) — ⚑ label audit (review wave 1) |
| `FUN_1003bb20` | G_WeaponHandler.cc | get air power percent (+0x24) | HIGH | listing (weapons-projectiles.md §2.5) |
| `FUN_1003bb30` | G_WeaponHandler.cc | get weapon-list-changed flag | HIGH | listing (weapons-projectiles.md §2.2) |
| `FUN_1003bb40` | G_WeaponHandler.cc | score-bar icons: {face,frame} of cur(pending)/next/next-after air weapon; repeats (by face+frame) → none | HIGH | listing `1003bb70…1003bcb4` — ⚑ corrected: was MED (hud-scorebar.md §6) — ⚑ corrected (wave 2, 2026-10-03): was "score-bar weapon icons (cur / next / next)" MED; see hud-scorebar.md §6 |
| `FUN_1003bce0` | G_WeaponHandler.cc | displayed air weapon (pending else current) | HIGH | listing (weapons-projectiles.md §2.4) |
| `FUN_1003bd00` | G_WeaponHandler.cc | draw crosshair | MED | read (weapons-projectiles.md §2.8) — ⚑ label audit (review wave 1) |
| `FUN_1003bd40` | G_WeaponHandler.cc | debug log of handler (no caller) | MED | read (weapons-projectiles.md §5) |
| `FUN_1003bf80` | G_WeaponHandler.cc | air fire timing (cooldown + edge unless autoRepeat) | HIGH | listing (weapons-projectiles.md §2.4) |
| `FUN_1003bff0` | G_WeaponHandler.cc | aux fire timing | MED | read (weapons-projectiles.md §2.4) |
| `FUN_1003c7a0` | G_WeaponHandler.cc | AIR weapon launch: spawn records at player pos + XLoc/YLoc → `FUN_10033220` | HIGH | listing (weapons-projectiles.md §3.2) |
| `FUN_1003c940` | G_WeaponHandler.cc | aux weapon launch | MED | read (weapons-projectiles.md §3.2) |
| `FUN_1003cb30` | G_WeaponHandler.cc | free aux records | MED | read (weapons-projectiles.md §5) — ⚑ label audit (review wave 1) |
| `FUN_1003cbf0` | G_WeaponHandler.cc | find aux record by weapon ID | MED | read (weapons-projectiles.md §5) — ⚑ label audit (review wave 1) |
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
| `FUN_1002cef0` | G_Console.cc | console module init: name, reset, command list, HELP/COMMANDS/? (debug-only, not added) | HIGH | listing `1002cef0..1002cfec` (messages-notices-console.md §1) |
| `FUN_1002cff0` | G_Console.cc | console teardown | HIGH | listing (messages-notices-console.md §1) |
| `FUN_1002d040` | G_Console.cc | console reset (closed, invisible, fade 0, buffer cleared, last-key = arg) | HIGH | listing (messages-notices-console.md §1) |
| `FUN_1002c4d0` |  | set parse context name/log flag | HIGH | read |
| `FUN_1002c540` |  | parse error flag | HIGH | read |
| `FUN_1002d080` | G_Console.cc | register command (name ≤31 upper, help, TV, +0x128 result sound, +0x129 hidden); **skipped entirely when debugOnly (r7) ≠ 0**, so only 10 commands exist in 1.0.6 | HIGH | listing `1002d0a4 rlwinm. r0,r7…; bne 0x1002d174`; was MED "register console command" (messages-notices-console.md §5.2) — ⚑ corrected (wave 2, 2026-10-03): was "register console command" MED; see messages-notices-console.md §5.2 |
| `FUN_1002d1a0` | G_Console.cc | open console: FlushEvents, gaso[1], open/visible, save + suspend ISp | HIGH | listing; was MED (messages-notices-console.md §1) — ⚑ corrected (wave 2, 2026-10-03): was "open console" MED; see messages-notices-console.md §1 |
| `FUN_1002d230` | G_Console.cc | console typing: keyDown via GetOSEvent, 120-frame expiry (flli 22), 30-char cap, ⏎/⌫/↑ recall, execute + restore ISp | HIGH | listing `1002d230..1002d400` (messages-notices-console.md §1) |
| `FUN_1002d410` | G_Console.cc | console draw + 8-frame fade (flli 23), formats 33/34, prompt = inte line 16 | HIGH | listing (messages-notices-console.md §5.1) |
| `FUN_1002d5d0` | G_Console.cc | free command list | HIGH | listing (messages-notices-console.md §1) |
| `FUN_1002d6c0` | G_Console.cc | find command by name | HIGH | listing (messages-notices-console.md role rows) |
| `FUN_1002d190` | G_Console.cc | console input-open flag getter | HIGH | listing `1002d190 lbz r3,-0x613f(r2)` (messages-notices-console.md role rows) — ⚑ corrected (wave 2, 2026-10-03): was "console is open" MED; see messages-notices-console.md role rows |
| `FUN_1002d770` | G_Console.cc | execute console line: first token upper, lookup, "Unknown Command", call handler TV, save last line, gaso[4]/[5] by result if +0x128 | HIGH | listing `1002d770..1002d940`; was MED "console command result sound" (messages-notices-console.md §2.5) — ⚑ corrected (wave 2, 2026-10-03): was "console command result sound" MED; see messages-notices-console.md §2.5 |
| (undefined) `0x1002d950` | G_Console.cc | HELP handler (debug-only, unregistered → unreachable; no Ghidra function) | HIGH | raw listing (messages-notices-console.md §5.2); not counted in the `FUN_` row counts |
| `FUN_1002da40` / `FUN_1002e280` | G_Console.cc / G_Message.cc | static initialisers | LOW | listing shape (messages-notices-console.md §1) |
| `FUN_1002dac0` / `FUN_1002db00` | G_Message.cc | message module init / teardown | HIGH | listing (messages-notices-console.md §1) |
| `FUN_1002db50` | G_Message.cc | message-queue reset (level start, frame-controller init/reset) | HIGH | listing + callers (messages-notices-console.md §1) |
| `FUN_1002dbd0` | G_Message.cc | post message (text, type 0/1/2, upper, sticky readout TV); max flli 24 = 20, dropped when full; re-post of a readout un-sticks it | HIGH | listing `1002dbd0..1002dd88`; was MED "show game message" (messages-notices-console.md §2.2) — ⚑ corrected (wave 2, 2026-10-03): was "show game message" MED; see messages-notices-console.md §2.2 |
| `FUN_1002dd90` | G_Message.cc | age messages each frame: after flli 25 = 60 frames, fade += flli 26 = 1; delete at 32 (one per frame) | HIGH | listing; was MED (messages-notices-console.md §2.3) — ⚑ corrected (wave 2, 2026-10-03): was "message aging" MED; see messages-notices-console.md §2.3 |
| `FUN_1002dea0` | G_Message.cc | draw messages: sticky lines first, then newest-on-top stack, gap flli 27 = 20, formats 35/36/37 by type, alpha = fade | HIGH | listing `1002dea0..1002e18c` (messages-notices-console.md §2.4) |
| `FUN_1002e190` | G_Message.cc | free message list | HIGH | listing (messages-notices-console.md §1) |
| `FUN_1002e300` | G_Message.cc (span) | level-select-active flag getter (`DAT_100e01fd`, written only in `FUN_1002e310`) | MED | listing + raw writer scan (messages-notices-console.md §5.1) |
| `FUN_10030190` | frame ctrl | construct frame controller (= zero all fields) | MED | dump; callers `FUN_100051a0`, `FUN_1002e310` (timing-frame.md §1) — ⚑ label rule (wave 2 synthesis): proposed HIGH on "dump; callers `FUN_100051a0`, `FUN_1002e310`" only — ⚑ corrected (wave 2, 2026-10-03): was "frame controller construct" MED; see timing-frame.md §1 — ⚑ label audit (review wave 2): MED settled — the owning file had no listing line or data bytes for it, so its row was lowered to MED too |
| `FUN_100301d0` | frame ctrl | controller destructor (delete if flag > 0) | MED | dump; called with −1 (timing-frame.md §1) |
| `FUN_10030210` | frame ctrl | start session: zero; +1 film, +4 game-layout, +3 auto-interlace allowed; clear layer queues; FPS monitor init; divider reset; FlushEvents | HIGH | listing — was "frame controller start session" MED (timing-frame.md §1) — ⚑ corrected (wave 2, 2026-10-03): was "frame controller start session" MED; see timing-frame.md §1 |
| `FUN_100302b0` | frame ctrl | end session (FlushEvents) | MED | dump (timing-frame.md §1) |
| `FUN_100302e0` | ~after G_LevelSelection | level-transition reset (layers, messages, FPS monitor, divider; keeps the limiter stamp) | MED | dump; caller `FUN_10007170` listing (timing-frame.md role rows) — ⚑ label rule (wave 2 synthesis): proposed HIGH on the dump (only the caller is listing-read) — ⚑ corrected (wave 2, 2026-10-03): was "between-level frame-controller reset" MED; see timing-frame.md §1 — ⚑ label audit (review wave 2): MED settled — the owning file had no listing line or data bytes for it, so its row was lowered to MED too |
| `FUN_10030350` | ~after G_LevelSelection | get frames-presented counter (+8) | MED | dump (timing-frame.md §1) — ⚑ label rule (wave 2 synthesis): proposed HIGH on "dump" only — ⚑ corrected (wave 2, 2026-10-03): was "frame counter getter" MED; see timing-frame.md §1 — ⚑ label audit (review wave 2): MED settled — the owning file had no listing line or data bytes for it, so its row was lowered to MED too |
| `FUN_10030020` | ~after G_LevelSelection | static inits / struct zero / Score Bar release / destructor / end-session / byte getter (`FUN_10030020` / `FUN_10030e70` / `FUN_10030df0` / `FUN_100313b0` / `FUN_100301d0` / `FUN_100302b0` / `FUN_10030900`) | LOW | read (scoring-bonuses.md §10.4) — ⚑ corrected (wave 2, 2026-10-03): `FUN_10030df0` was "struct zero" here → frame-controller state reset (own row); `FUN_100301d0` (destructor), `FUN_100302b0` (end session), `FUN_10030900` (paused getter) now have own rows; see timing-frame.md §1, front-end.md role rows — ⚑ caution ⚑ corrected (review wave 2, 2026-10-03) #C1: `FUN_10030e70` writes `0x100eb03c`/`0x100eb184`/`0x100eb1d8` before `main` (INDEX #56) |
| `FUN_10030360` | frame ctrl | begin frame: music, clear layers, console, message aging, volume/F6, mouse, Caps-Lock pause (not in films), Esc, input poll on tick frames; returns frame count | HIGH | listing `100304e8..` — was "keys, console, pause, quit" (timing-frame.md §2.1) — ⚑ corrected (wave 2, 2026-10-03): was "begin frame: keys, console, pause, quit" HIGH; see timing-frame.md §2.1 |
| `FUN_10030570` | frame ctrl | end-frame wrapper: end frame (r4/r5 passed through), Esc counter (discarded), pause screen, FPS monitor on tick frames | HIGH | listing `10030570..100305d4` (timing-frame.md §2.4) — ⚑ corrected (wave 2, 2026-10-03): was "end frame wrapper" HIGH; see timing-frame.md §2.4 |
| `FUN_10030bc0` | frame ctrl | end frame: messages, FPS text (pref 9), console, layers 0–1/bg/2–5/`FUN_10043ba0`/6–15, limiter spin to lastPresent+FPS_Delay (pref 10), counters, divider→tick flag, present by +4 | HIGH | listing `10030bc0..10030de8` (timing-frame.md §2.3) — ⚑ corrected (wave 2, 2026-10-03): was "end frame: render layers, FPS limiter, speed divider, present" HIGH; see timing-frame.md §2.3 |
| `FUN_10030df0` | frame controller | frame-controller state reset: zero +0…+0x34 (0x38 B: +0 paused, +2 quit, +4 present mode = init argument, +8 frames, +0x1c last present, +0x2c/+0x30 divider, +0x34 tick flag) | HIGH | listing stores `10030e0c…10030e54`; callers `FUN_10030190`/`FUN_10030210` (timing-frame.md §1, front-end.md role rows) — ⚑ corrected (wave 2, 2026-10-03): was "struct zero" LOW inside the `FUN_10030020` umbrella row (scoring-bonuses.md §10.4: "zero-init of a 0x35-byte struct (score-bar state?)"); see timing-frame.md §1 — ~~⚑ conflict: front-end.md labels +4 "interlace"; timing-frame.md §2.3 and messages-notices-console.md §4.4 (listing) read +4 as the present selector set from the `FUN_10030210` argument, not the interlace pref — kept~~ ⚑ corrected (review wave 2, 2026-10-03) #C2: closed — front-end.md corrected; +4 = present selector (`10030d94 lbz r0,0x4(r29); cmpwi r0,0x1; beq` → `10030dc4 bl 0x1000beb0`, 0 → `10030db4 bl 0x1000bc60`) |
| `FUN_100307b0` |  | tick-this-frame flag | HIGH | disasm |
| `FUN_100307c0` | frame ctrl | Esc: quit at once, or (pref 8 "ESC Key Delay") when hold counter > 30; called twice per frame → 16 frames | HIGH | listing — was "hold > 30 frames if pref 8" (timing-frame.md §2.5) — ⚑ corrected (wave 2, 2026-10-03): was "Esc quit (hold > 30 frames if pref 8)" HIGH; see timing-frame.md §2.5 |
| `FUN_10030910` |  | -/= volume, F6 interlace keys | HIGH | read |
| `FUN_10030640` | frame ctrl | FPS monitor: per >60-tick window publish count **always** (before the pref-10 test); only if limiter on: cumulative deficient windows (count < 30) → every 10th sets pref 5 if +3 and pref 6 | HIGH | listing `10030688 lwz r0,0x20(r30); 10030690 stw r0,0x24(r30)` before `10030694 bl 0x10004ef0` (pref 10), `100306a0 beq 0x1003075c` skips only the deficit block — ⚑ corrected (review wave 2, 2026-10-03) #I1: was "if limiter on…" read as gating the whole body — was MED "FPS monitor + auto interlace" (timing-frame.md §2.6) — ⚑ corrected (wave 2, 2026-10-03): was "FPS monitor + auto interlace" MED; see timing-frame.md §2.6 |
| `FUN_100305e0` | frame ctrl | FPS monitor init (+0x18 = now, +0x20 = +0x24 = 30, +0x28 = 0) | HIGH | listing (timing-frame.md §2.6) — ⚑ corrected (wave 2, 2026-10-03): was "FPS monitor init" MED; see timing-frame.md §2.6 |
| `FUN_10030790` | frame ctrl | reset divider (+0x2c = +0x30 = 0, tick = 1) — the only divider writer besides the constructor | HIGH | listing (timing-frame.md §1) — ⚑ corrected (wave 2, 2026-10-03): was "reset speed divider" HIGH; see timing-frame.md §1 |
| `FUN_10030870` | frame controller | after the paused frame: console reset, pause screen, clear notice, unpause, quit request | HIGH | listing `10030870..100308f0` (messages-notices-console.md §1) — ⚑ corrected (wave 2, 2026-10-03): was "pause handling" MED; see messages-notices-console.md §1 |
| `FUN_10030900` | frame ctrl | get paused flag (+0) | MED | dump; caller `FUN_1002e310` (timing-frame.md §1) |
| `FUN_10030f40` | G_ScoreBar.cc | score-bar init: per player 8 local rects (R0–7 / R8–15) + back-buffer copies (+416 x), state reset | HIGH | listing `10030fbc…10031124` — ⚑ corrected: was "score bar rects" MED (hud-scorebar.md §7) — ⚑ corrected (wave 2, 2026-10-03): was "score bar rects" MED; see hud-scorebar.md §7 |
| `FUN_10031400` | G_ScoreBar.cc | level start: load `scor` background into back + save buffers, icons, plde sprite IDs, all dirty, meters 0, draw | HIGH | listing; caller `FUN_100064d0` (hud-scorebar.md §4) |
| `FUN_10031710` | G_ScoreBar.cc | set displayed shield % (+0x20) for player index | HIGH | listing; callers `FUN_10027e50`, `FUN_1002a150` (hud-scorebar.md §2) |
| `FUN_10031760` | G_ScoreBar.cc | set displayed power % (+0x24), clamp <1→0, >100→100 | HIGH | listing (hud-scorebar.md §2) |
| `FUN_100317e0` | G_ScoreBar.cc | per-tick HUD update: dirty flags, shield/power followers (F120/121/126/127; rise only in state 4), icon rebuild on handler +0x08, one-shot dim on game over | HIGH | listing `10031810…10031aac` — ⚑ corrected: was "score bar meters update" MED (hud-scorebar.md §3) — ⚑ corrected (wave 2, 2026-10-03): was "score bar meters update" MED; see hud-scorebar.md §3 |
| `FUN_10031ad0` | G_ScoreBar.cc | set "blit element to screen" flag `DAT_100e01ff` | MED | read (hud-scorebar.md §4) — ⚑ label rule (wave 2 synthesis): proposed HIGH on "read" only — ⚑ label audit (review wave 2): MED settled — the owning file had no listing line or data bytes for it, so its row was lowered to MED too |
| `FUN_10031ae0` | G_ScoreBar.cc | draw dirty elements of both players (restore bg, draw, optional screen blit) | HIGH | listing (hud-scorebar.md §4) |
| `FUN_10031d70` | G_ScoreBar.cc | draw score: tefo 43/44, "%0.7i", dim = blend halfway to 32 | HIGH | listing (hud-scorebar.md §4) |
| `FUN_10031ea0` | G_ScoreBar.cc | draw lives symbol at F112–115 (dim: blend 16) | HIGH | listing (hud-scorebar.md §4) |
| `FUN_10032050` | G_ScoreBar.cc | draw reserve lives = lives−1 capped F143, "%i", tefo 45/46, red 47/48 at 0 | HIGH | listing — ⚑ corrected: was "lives display" MED (hud-scorebar.md §4) — ⚑ corrected (wave 2, 2026-10-03): was "lives display" MED; see hud-scorebar.md §4 |
| `FUN_10032250` | G_ScoreBar.cc | draw shield meter F116–119 + COST overlay from left+fill (tefo 41 strip blend/colour) | HIGH | listing (hud-scorebar.md §5) |
| `FUN_10032500` | G_ScoreBar.cc | draw power meter F122–125 (tefo 42) | HIGH | listing (hud-scorebar.md §5) |
| `FUN_100327b0` | G_ScoreBar.cc | draw weapon icon slot 0/1/2 (F128–139, scale F142, blend F140/F141) | HIGH | listing (hud-scorebar.md §4) |
| `FUN_10032a70` | G_ScoreBar.cc | blit one element rect back buffer → screen (local rect + D+0x2c/0x30) | MED | read (hud-scorebar.md §4) — ⚑ label rule (wave 2 synthesis): proposed HIGH on "read" only — ⚑ label audit (review wave 2): MED settled — the owning file had no listing line or data bytes for it, so its row was lowered to MED too |
| `FUN_10032b20` | G_ScoreBar.cc (static init) | fill draw-command templates `0x100eb228`, `0x100eb374`, `0x100eb3c8` | MED | read; caller `FUN_10000000` (hud-scorebar.md §4) — ⚑ caution ⚑ corrected (review wave 2, 2026-10-03) #C1: hud-scorebar.md NR 7 read these templates from the data image; runtime values come from this function (INDEX #56) |
| `FUN_10032bd0` | G_EntityGroup.cc | "Entity Group" module init: counters, flags `DAT_100e021c..f`, NUMENT/LOGENT/TRACKENT/ENTSTATES/SPAWNTOP/ENTID/ENTFAMILIES/ENTNAMES/PLAYERACTIVESPAWNS console commands | MED | strings (hud-scorebar.md role rows) |
| `FUN_10032df0` | G_EntityGroup.cc | "Entity Group" module teardown | MED | strings (hud-scorebar.md role rows) |
| `FUN_10033850` |  | update all entities (state machine, collisions, scroll pause) | HIGH | read |
| `FUN_100345f0` | G_EntityGroup.cc | per group: debug labels + shadow pass (castsShadows), then **sprite pass** of every spawned member | HIGH | listing `10034a98–10034b5c` (was MED "labels + shadow draw") (sprite-geometry-draw.md §2.1) — ⚑ corrected (wave 2, 2026-10-03): was "per-entity debug labels (state name of a watched unit, unit IDs, 'Ground Accuracy' on includeInGroundAccuracyC…" MED; see sprite-geometry-draw.md §2.1 |
| `FUN_10033090` | G_EntityGroup.cc (span) | spawn pending level objects whose yLoc == row; request y flagged "map row"; record always removed | HIGH | listing — ⚑ corrected (wave 1, 2026-10-03): was "spawn level objects at a scroll row" HIGH; see level-scroll-objects.md §6.3 |
| `FUN_10033220` |  | spawn request (group, limits) | HIGH | read |
| `FUN_10035900` | G_EntityGroup.cc | build pending level-object list; x −= 32 iff unit `isGroundBased` (unit+8 == `grnd`); placement `#layer_ID` unused | HIGH | listing `10035abc` — ⚑ corrected (wave 1, 2026-10-03): was "build pending level-object list" HIGH; see level-scroll-objects.md §6.2 |
| `FUN_100369f0` |  | group size with appearsPercent; size draw args are `R(min′,max)` | HIGH | disasm — ⚑ corrected (wave 1, 2026-10-03): was "group size with appearsPercent" HIGH (waves §4 said the args were dropped, MED); see spawn-and-waves.md §3.1 |
| `FUN_10035bf0` |  | spawn group members | HIGH | read |
| `FUN_10035cd0` |  | create one entity (shields by sector, spawn delay) | HIGH | read |
| `FUN_10037930` | G_EntityGroup.cc (span) | member placement: x/yOffsetMin/Max rectangular or radial, randomiseInitialLoc | HIGH | disasm (waves-and-enemies.md §4) — ⚑ corrected (review 2026-10-03) #2 |
| `FUN_10037b50` | G_EntityGroup.cc (span) | initial motion: stationary / supplied heading / hunt closest / burst-implode (y negated) / default heading ± tolerance; speed FloatRandomRange(min,max) × request multiplier | HIGH | disasm — ⚑ corrected (review 2026-10-03) #2 — ⚑ corrected (wave 1, 2026-10-03): was "initial speed (float draw initialSpeedMin/Max) + initial heading (± tolerance draw) / hunt / burst" MED; see spawn-and-waves.md §3.3 |
| `FUN_10012910` | G_GameObject (span) | set entity position (x,y) | MED | dump; callers `FUN_10037930`, `FUN_10028170` — ⚑ corrected (review 2026-10-03) #2 — ⚑ corrected (wave 1, 2026-10-03): was "set entity position (x,y)" MED; see units-movement.md §2.1 — ⚑ label audit (review wave 1) |
| `FUN_100351f0` | G_EntityGroup.cc | count entities of a unit whose spawn delay is over (rules #14–16) | MED | dump — ⚑ corrected (wave 1, 2026-10-03): was "count live entities of a unit" MED; see bosses.md §3.1 — ⚑ label audit (review wave 1) |
| `FUN_100352f0` | G_EntityGroup.cc | rule #4: any entity whose unit has includeInAirAccuracyCount (+0x133); no live/on-screen test | MED | dump; caller `FUN_10015550` — ⚑ corrected (wave 1, 2026-10-03): was "any destroyable air entity" MED; see bosses.md §3.1 — ⚑ label audit (review wave 1) |
| `FUN_100353e0` | G_EntityGroup.cc | rule #5: any entity whose unit has includeInGroundAccuracyCount (+0x134) and is on screen (`FUN_10016bd0`) | MED | dump; caller `FUN_10015550` — ⚑ corrected (wave 1, 2026-10-03): was "any destroyable ground entity" MED; see bosses.md §3.1 — ⚑ label audit (review wave 1) |
| `FUN_10034ee0` | G_EntityGroup.cc | rule "Is Tracking Player": live entity of unit with +0xc1 set, dist ≤ range (0 = any) | HIGH | disasm (spawn-and-waves.md §6) |
| `FUN_10035070` | G_EntityGroup.cc | rule #2 "Is Active": live entity of unit (spawn delay ≤ 0), `dist(polling entity, member) ≤ range` inclusive (0 = any); unit `none` → false | HIGH | disasm (spawn-and-waves.md §6); `10035140 cmpwi r23,0x0; beq` (range 0), `10035184 fcmpo cr0,f1,f2; 10035188 cror eq,lt,eq` (≤), `100351ac beq` skip — ⚑ corrected (review wave 2, 2026-10-03) (O3): bosses.md §3.1 raised from MED to HIGH |
| `FUN_10036cf0` | G_EntityGroup.cc | entity↔entity collision: same layer (unit+8), harmless XOR, playerProjectile (+0x11b) / canBeHitByPlayerProjectile (+0x11c) pairing, AABB then circle (`FUN_10042f80`); A takes B.damage_FLOAT (to A's owner if passHitsToOwner), then B takes A.damage via `FUN_10014f10` (B-side passHitsToOwner tests and damages A's owner — bug; player shots have no owner, so a passHits turret/bubble hit by a player shot takes the damage on its own shields — only ramming reaches the owner; bosses.md §3.5 ⚑ corrected (review wave 1, 2026-10-03) #I1); returns A deleted. Called per entity whose state has Collides (+0x347). NOT the spawn-set executor (that is `FUN_10015b40`) | HIGH | raw `10036fc4..100370e8` (`lfs f1,0x274(r4)`), dump; caller `FUN_10033850` (`10034594 bl`) — ⚑ corrected (wave 1, 2026-10-03): was "state spawn sets executor" LOW; see damage-health-death.md §2.5, spawn-and-waves.md §7, bosses.md §3.4 |
| `FUN_10032e60` | G_EntityGroup.cc | level start: reset groups, notice list, id counters, create PERM group, pending list | HIGH | disasm (spawn-and-waves.md §8) |
| `FUN_10033600` | G_EntityGroup.cc | owner-relative init: offset, orbit radius/angle, owner last pos | HIGH | disasm (spawn-and-waves.md §4) |
| `FUN_10034b90` | G_EntityGroup.cc | player gone: entities with +0xd8 == player destroyed (0x329) or deleted (0x32a) | HIGH | listing `10034c4c..10034ca8` (loose-ends-combat.md §4.1) — ⚑ corrected (wave 2, 2026-10-03): was "player gone: destroy (0x329) / delete (0x32a) entities owned by that player; caller `FUN_10027e50`" MED; see loose-ends-combat.md §4.1 |
| `FUN_10034ce0` | G_EntityGroup.cc | find entity by serial (+0x9c) → `FUN_10014670(entity, now)` (enter its first UseThisStateOnWeaponPowerupRelease state; `now` becomes the state-start time); callers `FUN_1003b3c0`, `FUN_1003c0d0` | HIGH | listing `10034d8c lwz r0,0x9c(r3); cmpw r0,r25`, `10034d98 or r4,r24,r24; bl 0x10014670` (r24 = arg 1); `FUN_10014670` dump passes it as `FUN_100146f0` param_4, stored at +0xa4 — ⚑ corrected (review wave 1, 2026-10-03) (conflict resolved): weapons-projectiles.md §2.3/§2.5 wins; spawn-and-waves.md §5 "set named state on entity by id (arg 1 = state name)" corrected |
| `FUN_10034de0` | G_EntityGroup.cc | delete first entity with serial == arg | HIGH | listing `10034e8c..10034ea4` (loose-ends-combat.md §4.1) — ⚑ corrected (wave 2, 2026-10-03): was "delete entity by id; callers `FUN_10027e50`, `FUN_10029fe0`" MED; see loose-ends-combat.md §4.1 |
| `FUN_10035580` | G_EntityGroup.cc | active group count | MED | read (spawn-and-waves.md §8) |
| `FUN_100355b0` | G_EntityGroup.cc | debug integrity check / dump (no direct callers) | MED | read (spawn-and-waves.md §8) |
| `FUN_10035810` | G_EntityGroup.cc | free pending level-object list | MED | read (spawn-and-waves.md §8) |
| `FUN_10035b00` | G_EntityGroup.cc | free all groups | MED | read (spawn-and-waves.md §8) |
| `FUN_10036120` | G_EntityGroup.cc | remove entity from group: destroy/delete children, kill count, destruct coins, group-kill coin (non-PERM), destruction, live count; returns empty-non-PERM | HIGH | disasm (spawn-and-waves.md §5); damage-health-death.md §4.3, bosses.md §3.5 MED — ⚑ corrected (wave 2, 2026-10-03): was silent on re-entry; it has **no +0xcb guard**, so direct removers + the reaper call it twice (behaviour-neutral for 1.0.6 data); see loose-ends-combat.md §4.1 |
| `FUN_100363c0` | G_EntityGroup.cc | destroy children: every entity whose owner id +0x144 == e+0x9c and whose state has canBeDestroyedOnOwnerDestruction → state 0x329 via `FUN_10036120`, no unlink | HIGH | listing (loose-ends-combat.md §4.1) — ⚑ corrected (wave 2, 2026-10-03): was "destroy children whose state has canBeDestroyedOnOwnerDestruction" MED; see loose-ends-combat.md §4.1 |
| `FUN_100364f0` | G_EntityGroup.cc | delete children: owner id +0x144 == e+0x9c and state has canBeDeletedOnOwnerDeletion → state 0x32a via `FUN_10036120`, no unlink | HIGH | listing (loose-ends-combat.md §4.1) — ⚑ corrected (wave 2, 2026-10-03): was "delete children whose state has canBeDeletedOnOwnerDeletion" MED; see loose-ends-combat.md §4.1 |
| `FUN_10036610` | G_EntityGroup.cc | per-tick reaper of +0xcb entities: ground count, draw-to-terrain, destroy owner, deletion spawn, `FUN_10036120`, free entity / empty non-PERM group | HIGH | disasm (spawn-and-waves.md §5); damage-health-death.md §4.3 MED; call at `100345d4` |
| `FUN_10036930` | G_EntityGroup.cc | copy owner visibility / scale / hit-glow fields (useOwners*, visuallyReflectOwnerHits) | HIGH | raw `10033f4c..10033f58` args (bosses.md §3.5); spawn-and-waves.md §4 MED |
| `FUN_10036ab0` | G_EntityGroup.cc | owner link valid (ptr, serial +0x9c, not deleted) | MED | dump 1-liner (spawn-and-waves.md §1.3, damage-health-death.md §4.3, bosses.md §3.5) — ⚑ label audit (review wave 1) |
| `FUN_10036af0` | G_EntityGroup.cc | first live entity of a unit | MED | read (spawn-and-waves.md §8) |
| `FUN_10036be0` | G_EntityGroup.cc | remove entities of unit X owned by player P (destroyed flag passed) | HIGH | listing `10036c8c..10036cb8` (loose-ends-combat.md §4.1) — ⚑ corrected (wave 2, 2026-10-03): was "remove entities of a unit owned by a player (deleteExisting…)" MED; see loose-ends-combat.md §4.1 |
| `FUN_10037130` | G_EntityGroup.cc | LockToOwnerLoc: pos = owner + offset | HIGH | disasm (spawn-and-waves.md §4) |
| `FUN_10037230` | G_EntityGroup.cc | LinkToOwnerLoc: pos += owner displacement | HIGH | disasm (spawn-and-waves.md §4) |
| `FUN_10037350` | G_EntityGroup.cc | OrbitOwner: angle += trunc(+0x10) deg/tick at radius | HIGH | disasm (spawn-and-waves.md §4) |
| `FUN_10037580` | G_EntityGroup.cc | player-contact pickup by pickup_Type_ID: coin → money += pickup_Value; exli → life; mult → multiplier step; shie → shields += pickup_Value; spec → nothing; air/grnd only check player +0xce; other → 1 (entity destroyed) | HIGH | listing `10037580–100376f0` (damage-health-death.md §6, weapons-projectiles.md §4); 'shie' `100375f4`→`100376ac`, 'spec' `1003761c`→`100376d8` re-checked — ⚑ corrected (review wave 1, 2026-10-03) #M9: scoring-bonuses.md §5.1/NR 3 now HIGH too; spawn-and-waves.md MED |
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
| (undefined) `0x10039080` | G_EntityGroup (console) | PLAYERACTIVESPAWNS handler: toggle `DAT_100e0214` "Player Active Only Spawns" (debug-only, not among the 10 registered commands) | HIGH | raw bytes, pointer `0x100e0980` (loose-ends-combat.md §2.2; messages-notices-console.md §5.2); not counted in the `FUN_` row counts |
| `FUN_10039100` | ~after G_EntityGroup | static init of request templates | LOW | read (spawn-and-waves.md §8) |
| `FUN_100391f0` | G_PlayerDefinitions.cc | player-definition module init ("Player Definition", builds list); `FUN_10039230` unload | LOW | strings (spawn-and-waves.md §8, unit-def-struct.md §9) |
| `FUN_10039280` | G_PlayerDefinitions.cc | build player-definition list | MED | read (unit-def-struct.md §9) — ⚑ label audit (review wave 1) |
| `FUN_10039460` | G_PlayerDefinitions.cc | plde index by tag ID (−1 if none) | MED | read (unit-def-struct.md §9) — ⚑ label audit (review wave 1) |
| `FUN_10039520` | G_PlayerDefinitions.cc | i-th plde record | MED | read (unit-def-struct.md §9) |
| `FUN_100395d0` | G_PlayerDefinitions.cc | unit referenced by plde / free list / collect IDs / free plde list (`FUN_100395d0` / `FUN_10039940` / `FUN_10039a80` / `FUN_10039c00`) | MED | read (unit-def-struct.md §9) |
| `FUN_100396c0` | G_PlayerDefinitions.cc | plde referenced unit IDs; `FUN_100399a0` load plde resources | MED | read (unit-def-struct.md §9) — ⚑ label audit (review wave 1) |
| `FUN_10039cf0` | G_PlayerDefinitions.cc | load plde i (0x108 record, defaults, parse, error ⇒ fatal) | HIGH | listing (unit-def-struct.md §9) |
| `FUN_10039e70` | G_PlayerDefinitions.cc | parse plde: 57 keys → offsets 0x008–0x107 (table in unit-def-struct.md §9 and player-physics.md role rows) | HIGH | listing reader calls `10039ee8..1003a758` (unit-def-struct.md §9, player-physics.md) |
| `FUN_1003a780` | U_Manager.cc | manager init ("Manager God") | MED | strings (unit-def-struct.md §9) |
| `FUN_1003cf10` | G_UnitDefinitions.cc | unit-module init: register "Unit Definition" (`FUN_1003a870`), 5 console names on 4 handlers (LOGSCROLLPAUSERS, LOGFAMILIES/FAMILIES, LOGUNUSEDUNITS, UNITSCORES; handlers are undefined code `0x10041a40/b30/b70/d70`), then Units Cache read `FUN_100420f0`, falling back to the full build `FUN_1003d0a0(1)` | HIGH | listing `1003cf34 bl 0x1003a870`, `1003cf5c…1003cfdc` 4× `bl 0x1002d080`, `1003cfe4 bl 0x100420f0`, `1003d000 bl 0x1003d0a0`; caller `FUN_100000e0` — ⚑ corrected (review wave 1, 2026-10-03) (conflict resolved): unit-def-struct.md §1 wins; bosses.md "console unit commands" (LOW) corrected |
| `FUN_1003d030` | G_UnitDefinitions.cc | unit-defs module teardown | MED | read (weapons-projectiles.md §5) |
| `FUN_1003d0a0` | G_UnitDefinitions.cc | build master unit list; numStates check passes 0..20 (log + assert only < 0 or > 20) | HIGH | listing `1003d1bc–1003d218` — ⚑ corrected (wave 1, 2026-10-03): was "build master unit list (1..20 states)" HIGH; see unit-def-struct.md §2.5 |
| `FUN_1003d650` | G_UnitDefinitions.cc | compiler copy-assignment of unit `fileData` (unit+0xc, 0x7a54 B); only for the Units Cache writer `FUN_10041e40` | HIGH | listing `1003d904–1003dcb8` — ⚑ corrected (review 2026-10-03) #9 — ⚑ corrected (wave 1, 2026-10-03): was "unit-definition struct copy (field-by-field assignment)" MED; see unit-def-struct.md §1 |
| `FUN_1003fc50` | G_UnitDefinitions.cc | load unit i: alloc 0x7a60, defaults, parse, error ⇒ fatal; sets unit+8 layer = `grnd` if isGroundBased else `air ` (the collision layer) | HIGH | listing; raw `1003fd20..1003fd44` (bosses.md, level-scroll-objects.md) — ⚑ corrected (wave 1, 2026-10-03): was "load unit i" MED; see unit-def-struct.md §1, bosses.md §3.4, level-scroll-objects.md §6.2 |
| `FUN_1003fda0` | G_UnitDefinitions.cc | parse unit definition | HIGH | read |
| `FUN_10040920` | G_UnitDefinitions.cc | parse one state | HIGH | read |
| `FUN_1003d2f0` | G_UnitDefinitions.cc | find unit definition by ID (unit+4 = tag) | HIGH | listing `1003d35c` — ⚑ corrected (wave 1, 2026-10-03): was "find unit definition by ID" MED; see unit-def-struct.md §1 |
| `FUN_1003e680` | G_UnitDefinitions.cc | load/verify a unit's sounds + sprites, recurse into referenced units | MED | read — ⚑ corrected (wave 1, 2026-10-03): was "load unit resources (sounds/sprites)" MED; see unit-def-struct.md §1 — ⚑ label audit (review wave 1) |
| `FUN_1003f4e0` | G_UnitDefinitions.cc | add unit to family list (0x4c family records) | MED | read — ⚑ corrected (wave 1, 2026-10-03): was "add unit to family list" MED; see unit-def-struct.md §1 — ⚑ label audit (review wave 1) |
| `FUN_1003d3a0` | G_UnitDefinitions.cc | i-th unit of the master list | MED | read (unit-def-struct.md §1) |
| `FUN_1003d450` | G_UnitDefinitions.cc | family record of a unit (" Misc" if no family name) | HIGH | read; `0x100ed01f` (unit-def-struct.md §1) |
| `FUN_1003d550` | G_UnitDefinitions.cc | find unit by ID: entity's family member list, then the master list | HIGH | raw call sites `100155b4`, `10015d74`; entity+0x98 from `100144c8` (loose-ends-session.md §8) — ⚑ corrected (wave 2, 2026-10-03): was "find unit by ID, family list first then global" MED; see loose-ends-session.md §8 |
| `FUN_1003dce0` | G_UnitDefinitions.cc | copy state sub-blocks (`FUN_1003dce0` / `FUN_1003dd60` / `FUN_1003ddc0` / `FUN_1003de00` / `FUN_1003de30` / `FUN_1003de70` / `FUN_1003dfb0`: +0x324 owner bools, +0x300 anim, +0x2ec blur, +0x2e0 collision, +0x2d0 particles, +0x024 rules, +0x000 sound) | HIGH | listing (unit-def-struct.md §1) |
| `FUN_1003e020` | G_UnitDefinitions.cc | copy unit sub-blocks (`FUN_1003e020` / `FUN_1003e040` / `FUN_1003e120` / `FUN_1003e1a0`: pickup, destruct, shields + 2 sounds, sound record) | HIGH | listing (unit-def-struct.md §1) |
| `FUN_1003e1e0` | G_UnitDefinitions.cc | unit-definition defaults (incl. 20 states, state 0 "State 1") | HIGH | listing (unit-def-struct.md §3) |
| `FUN_1003e3d0` | G_UnitDefinitions.cc | state defaults | HIGH | listing (unit-def-struct.md §4) |
| `FUN_1003e490` | G_UnitDefinitions.cc | spawn-set defaults | HIGH | listing (unit-def-struct.md §6) |
| `FUN_1003e510` | G_UnitDefinitions.cc | reset loaded-unit-resources list | MED | string + callers (unit-def-struct.md §1) — ⚑ label audit (review wave 1) |
| `FUN_1003e580` | G_UnitDefinitions.cc | load resources of a unit ID | HIGH | listing (unit-def-struct.md §1) |
| `FUN_1003ec70` | G_UnitDefinitions.cc | list unit IDs referenced by a unit | MED | read (unit-def-struct.md §1) — ⚑ label audit (review wave 1) |
| `FUN_1003ef90` | G_UnitDefinitions.cc | is unit referenced by another unit (LOGUNUSEDUNITS) | MED | read (unit-def-struct.md §1) |
| `FUN_1003f0b0` | G_UnitDefinitions.cc | collect all unit sprite/sound IDs into a list | MED | read (unit-def-struct.md §1) |
| `FUN_1003f280` | G_UnitDefinitions.cc | master-list integrity check (magic 0x499602d2) | HIGH | listing (unit-def-struct.md §1) |
| `FUN_1003f360` | G_UnitDefinitions.cc | free master list / ID list / family list / family / resource list (`FUN_1003f360` / `FUN_1003f410` / `FUN_1003f830` / `FUN_1003fa10` / `FUN_1003fa80`) | MED | read (unit-def-struct.md §1) |
| `FUN_1003f470` | G_UnitDefinitions.cc | rule-block defaults (5 rules) | HIGH | listing (unit-def-struct.md §5) |
| `FUN_1003f8b0` | G_UnitDefinitions.cc | log family table | MED | strings (unit-def-struct.md §1) |
| `FUN_1003fb60` | G_UnitDefinitions.cc | test-and-insert unit ID into the loaded-resources list | MED | read (unit-def-struct.md §1) — ⚑ label audit (review wave 1) |
| `FUN_10041960` | G_UnitDefinitions.cc | sprite (parse time) / sound / sprite (load time) existence check, else `'none'` (`FUN_10041960` / `FUN_100417d0` / `FUN_100418a0`) | MED | read (unit-def-struct.md §2) — ⚑ label audit (review wave 1) |
| `FUN_10041e40` | G_UnitDefinitions.cc | Units Cache writer (format unit-def-struct.md §8) | MED | read (unit-def-struct.md §8) — ⚑ corrected (wave 1, 2026-10-03): the fix-pass note named `FUN_100420f0` as the writer — ⚑ label audit (review wave 1) |
| `FUN_100420f0` | G_UnitDefinitions.cc | Units Cache reader / validator | MED | read (unit-def-struct.md §8) — ⚑ corrected (wave 1, 2026-10-03): was "Units Cache writer" (function-roles.md §1 fix-pass notes, unread); see unit-def-struct.md §8 — ⚑ label audit (review wave 1) |
| `FUN_100426e0` | ? (after G_UnitDefinitions) | write a data file in the Data folder (Units Cache helper) | MED | strings; caller `FUN_10041e40` (damage-health-death.md §1) |
| `FUN_100428b0` | ? | static initialiser copying constant records | LOW | decompile (damage-health-death.md §1) |
| `FUN_100431f0` | G_Particle (span) | particle module init: register, `FUN_10044630` table (300 draws), then R(0,99) burst index → 0x100e026c, R(0,99) ring index → 0x100e0268, NUMPG command; app start, before any srand (was LOW "two RandomRange(0,99) + FUN_1002d080") | HIGH | listing `100431f0..10043260`; caller `FUN_100000e0` `100005d0` (particles-debris-blur.md §1) — ⚑ corrected (wave 2, 2026-10-03): was "init: two RandomRange(0,99) + `FUN_1002d080`; `FUN_10043280` teardown" LOW; see particles-debris-blur.md §1 |
| `FUN_10043280` | G_Particle (span) | particle module teardown (free groups if live) | HIGH | listing; caller `FUN_10000630` (particles-debris-blur.md §2.1) |
| `FUN_100432d0` | G_Particle.cc | per-level reset: free groups, new group list 0x100e0270; indices NOT reset | HIGH | listing; caller `FUN_100064d0` (particles-debris-blur.md §2.1) |
| `FUN_100438c0` | G_Particle (span) | particle update: delay, ground scroll, drag ×flli144 (0.96, not gravity), move, bounds x∈[−32, W+25] y∈[0, H−7], fade += trunc(flli148) to 32 then die; frees empty groups (was MED "particles update (gravity)") | HIGH | listing `100438c0..10043b9c`; caller `FUN_10006b50` `10006be0` (particles-debris-blur.md §2.8) — ⚑ corrected (wave 2, 2026-10-03): was "particles update (gravity)" MED; see particles-debris-blur.md §2.8 |
| `FUN_10043ba0` | G_Particle (span) | particle draw: 7×7 top-left-anchored 555 blend stamp per particle into the game buffer, every presented frame of a game (gated on end-frame `param_2`, constant 1 from the game loop, 0 from level select — not on the tick flag), between render bands 1 and 2 of end frame | HIGH | listing `10043ba0..10044500`; caller `FUN_10030bc0` `10030cd0`, gate `10030cc8 rlwinm. r0,r28; 10030ccc beq 0x10030cd8` with r28 = r4 (`10030be0`), game loop `10005aac li r4,0x1` (particles-debris-blur.md §2.9; layer placement MED) — ⚑ corrected (review wave 2, 2026-10-03) #C4 #C5: critic's "ticked frames only" not adopted (the gate is `param_2`); sprite-geometry-draw.md and timing-frame.md now point here (were LOW "not read") |
| `FUN_10044550` | G_Particle (span) | free all groups + list | HIGH | listing; callers `FUN_10043280`, `FUN_100432d0` (particles-debris-blur.md §2.1) |
| `FUN_10044630` | G_Particle (span) | build ring (unit) and burst (×1/.85/.7/.55) direction tables, 100 entries, 3 draws each (R(0,W), R(0,H), R(0,3)) | HIGH | listing `10044630..10044834`; caller `FUN_100431f0` (particles-debris-blur.md §2.5) |
| `FUN_10044840` | G_Particle (span) | free one group | HIGH | listing; caller `FUN_100438c0` (particles-debris-blur.md §2.1) |
| `FUN_100450e0` |  | interlaced CopyBits: every other row, field parity at picture +0x2c toggled per call | MED | dump (timing-frame.md §5) |
| `FUN_100461b0` |  | running on Mac OS X: Gestalt('sysv') ≥ 0x0A00 | HIGH | listing (loose-ends-session.md, sound-music.md role rows; messages-notices-console.md agrees) |
| `FUN_10043340` | G_Particle.cc | emit burst: type tiny/tici 5, smal/smci 10, med/meci 20, larg/laci 40 (`ci` = ring table, small ×3 / others ×5); 5 colour variants (flli 145/146); per particle **R(0,4)** colour draw; velocity from the cycling table entry (was MED "emit particles", perm F145/146) | HIGH | listing `10043340..100438b0`; callers `FUN_10033850` `10033b4c`, `FUN_10014f10` `10015114`, `FUN_10016300` `100163c4` (particles-debris-blur.md §2.2) — ⚑ corrected (wave 2, 2026-10-03): was "emit particles" MED; see particles-debris-blur.md §2.2 |
| `FUN_10046840` | G_MotionBlur.cpp | emit blur: copy entity sprite instance (+0x18..+0x8c, glow only if AllowGlow), vis = Initial, floor 0.0, delta (was LOW "emit motion blur") | HIGH | listing `10046840..10046a04`; caller `FUN_10033850` `100343a4` (particles-debris-blur.md §1) — ⚑ corrected (wave 2, 2026-10-03): was "emit motion blur" LOW; see particles-debris-blur.md §1 |
| `FUN_10046a10` | G_MotionBlur.cpp | per tick: vis −= delta; < 0.0 → remove + free | HIGH | listing; caller `FUN_10006b50` `10006be8` (particles-debris-blur.md §1) |
| `FUN_10046ae0` | G_MotionBlur.cpp | draw all blurs (`FUN_10012f20`) | HIGH | listing; caller `FUN_10007070` `10007094` (particles-debris-blur.md §1) |
| `FUN_10046b70` | G_MotionBlur.cpp | blur count (NUMBLURS callback?) | LOW | no direct caller (particles-debris-blur.md §4.2) |
| `FUN_10046ba0` | G_MotionBlur.cpp | remove all from list | MED | decompile (particles-debris-blur.md §4.2) |
| `FUN_10046c70` | G_MotionBlur.cpp | prealloc 1000 × 0x94 sprite objects | HIGH | listing (particles-debris-blur.md §4.2) |
| `FUN_10046d30` | G_MotionBlur.cpp | clear pool in-use flags, cached index 0 | MED | decompile (particles-debris-blur.md §4.2) |
| `FUN_10046e20` | G_MotionBlur.cpp | destroy pool | MED | decompile (particles-debris-blur.md §4.2) |
| `FUN_10046eb0` | G_MotionBlur.cpp | allocate pool slot (cap 1000, warn once) | HIGH | listing `10046ed0..` (particles-debris-blur.md §1) |
| `FUN_100470f0` | G_MotionBlur.cpp | free pool slot | MED | decompile (particles-debris-blur.md §4.2) |
| `FUN_10047160` | M_Sound.cpp | sound init: mixer `FUN_100d1400(n,44100)`, n = flli 38 (8) (warn unless 1..98), save user device volume, flags 0290/0291, apply prefs, record list | HIGH | listing `1004719c–10047270` (sound-music.md §1) — ⚑ corrected (wave 2, 2026-10-03): was "sound init (channels)" MED; see sound-music.md §1 |
| `FUN_10047290` | M_Sound.cpp | sound shutdown: free records, mixer stop (restores device volume) | MED | read (sound-music.md §2.1) — ⚑ label rule (wave 2 synthesis): proposed HIGH on "read" only — ⚑ label audit (review wave 2): MED settled — the owning file had no listing line or data bytes for it, so its row was lowered to MED too |
| `FUN_10047330` | M_Sound.cpp | load `soun` tag → asnd/mIMA record {magic, id, data, lastVoice −1} | MED | read (sound-music.md §2.1) — ⚑ label rule (wave 2 synthesis): proposed HIGH on "read" only — ⚑ corrected (wave 2, 2026-10-03): was "load sound effect tag" HIGH; see sound-music.md §2.1 — ⚑ label audit (review wave 2): MED settled — the owning file had no listing line or data bytes for it, so its row was lowered to MED too |
| `FUN_10047460` | M_Sound.cpp | free all sound records | MED | read (sound-music.md §2.1) |
| `FUN_10047510` | M_Sound.cpp | free one sound record by id (voices not stopped) | MED | read (sound-music.md §2.1) |
| `FUN_10047bf0` | M_Sound.cpp | play primitive (id, prio≤100, vol→128·v/100 L=R, allowMultiple, f1 pitch→16.16) → mixer voice (was "play sound by ID" MED) | HIGH | listing `10047bf0–10047e34` (sound-music.md §2.1) — ⚑ corrected (wave 2, 2026-10-03): was "play sound by ID" MED; see sound-music.md §2.1 |
| `FUN_10047670` | M_Sound.cpp | play(id, priority, volume, allowMultiple) at pitch 1.0 (was "play sound (id, volume…)" MED) | HIGH | listing `10047670–10047698` (sound-music.md §2.1) — ⚑ corrected (wave 2, 2026-10-03): was "play sound (id, volume…)" MED; see sound-music.md §2.1 |
| `FUN_100476a0` | M_Sound.cpp | stop all effect voices | HIGH | listing (sound-music.md §2.1) |
| `FUN_100475e0` | M_Sound.cpp | play sound record: volume = MinVolume, prio = Priority&0xFF, pitch = RandomRangeF(Min,Max), (record, allowMultiple) (was "play sound from settings block" MED) | HIGH | listing `10047600–1004764c` (sound-music.md §2.1) — ⚑ corrected (wave 2, 2026-10-03): was "play sound from settings block" MED; see sound-music.md §2.1 |
| `FUN_100476e0` | M_Sound.cpp | is-playing: last started voice of the id still in the voice list (was MED "usage") | HIGH | listing `100476e0–100477c4`, `FUN_100d1b30` (sound-music.md §2.1) — ⚑ corrected (wave 2, 2026-10-03): was "is sound playing" MED; see sound-music.md §2.1 |
| `FUN_100477d0` | M_Sound.cpp | record-list integrity check (no caller) | MED | read (sound-music.md §2.1) |
| `FUN_10047910` | M_Sound.cpp | sound-available getter | HIGH | listing (sound-music.md §2.1) |
| `FUN_10047920` | M_Sound.cpp | apply prefs: device ← int pref 0 if byte 7 (not on OS X); music level ← int pref 1 | HIGH | listing `10047920–1004798c` (sound-music.md §2.1) |
| `FUN_10047990` | M_Sound.cpp | volume down: pref0 −10 (≥0) → device 128·v/100 (unless OS X) (was LOW) | HIGH | listing (sound-music.md §4.3) — ⚑ corrected (wave 2, 2026-10-03): was "volume down" LOW; see sound-music.md §4.3 |
| `FUN_10047a30` | M_Sound.cpp | volume up: pref0 +10 (≤100) → device (was LOW) | HIGH | listing (sound-music.md §4.3) — ⚑ corrected (wave 2, 2026-10-03): was "volume up" LOW; see sound-music.md §4.3 |
| `FUN_10047ad0` | M_Sound.cpp | restore the user's device volume (suspend) | HIGH | listing (sound-music.md §4.1) |
| `FUN_10047b10` | M_Sound.cpp | re-apply prefs (same body as `FUN_10047920`; resume) | HIGH | listing (sound-music.md §4.2) |
| `FUN_10047b80` | M_Sound.cpp | volume % → 0..128 (`clamp(128·v/100,0,128)`) | HIGH | listing + table `0x100d7414` (sound-music.md §4.1) |
| `FUN_100d1780` |  | convert AIFF/AIFC/WAV (NONE/ima4, mono) to playable | MED | read — ⚑ label audit (review wave 2) #M3: was HIGH on read only |
| `FUN_100d18d0` | sound lib | start voice: ranked insertion, evict 16th, refuse below all | HIGH | listing `100d18d0–100d1b20` (sound-music.md §3.1) |
| `FUN_100d1b30` | sound lib | count voices by id / data / all | HIGH | listing (sound-music.md §2.4) |
| `FUN_100d1be0` | sound lib | stop voices by id / data / all | HIGH | listing (sound-music.md §2.1) |
| `FUN_100d1cf0` | sound lib | remove voice i | MED | read (sound-music.md §3.2) |
| `FUN_100d1d90` | sound lib | build asnd/mIMA (strip ima4 packet headers, nibble swap; PCM → IMA) | MED | read (sound-music.md §2.2) — ⚑ label rule (wave 2 synthesis): proposed HIGH on "read" only — ⚑ label audit (review wave 2): MED settled — the owning file had no listing line or data bytes for it, so its row was lowered to MED too |
| `FUN_100d21a0` | sound lib | mixer render: voices < numChannels mixed, rest advanced silently | HIGH | listing (sound-music.md §3.2) |
| `FUN_100d2c30` | sound lib | open mixer output (SndNewChannel sampledSynth stereo, SndPlayDoubleBuffer) | MED | read (sound-music.md §2.3) — ⚑ label rule (wave 2 synthesis): proposed HIGH on "read" only — ⚑ label audit (review wave 2): MED settled — the owning file had no listing line or data bytes for it, so its row was lowered to MED too |
| `FUN_100d32d0` | sound lib | IMA decode + gain>>7 + linear-interp resample + saturating mix (one voice) | HIGH | listing (sound-music.md §3.2) |
| `FUN_10047e40` | M_Music.cpp | music init (spool buffer flli 37 = 204800; SM ≥ 3.2) | MED | read (sound-music.md §6.1) — ⚑ label rule (wave 2 synthesis): proposed HIGH on "read" only — ⚑ corrected (wave 2, 2026-10-03): was "music init (spool buffer)" MED; see sound-music.md §6.1 — ⚑ label audit (review wave 2): MED settled — the owning file had no listing line or data bytes for it, so its row was lowered to MED too |
| `FUN_10047ef0` | M_Music.cpp | music shutdown (fade-stop, lib close) | MED | read (sound-music.md §6.1) — ⚑ label rule (wave 2 synthesis): proposed HIGH on "read" only — ⚑ label audit (review wave 2): MED settled — the owning file had no listing line or data bytes for it, so its row was lowered to MED too |
| `FUN_10047f50` | M_Music.cpp | music service (completion callback; no-op as used) | MED | read (sound-music.md §6.1) |
| `FUN_10047f80` | M_Music.cpp | music-playing flag getter | MED | read (sound-music.md §6.1) — ⚑ label rule (wave 2 synthesis): proposed HIGH on "read" only — ⚑ label audit (review wave 2): MED settled — the owning file had no listing line or data bytes for it, so its row was lowered to MED too |
| `FUN_10047f90` | M_Music.cpp | play music (id, loop, startPaused) streamed from pak | HIGH | listing (sound-music.md §6.1) — ⚑ corrected (wave 2, 2026-10-03): was "play music tag streamed from pak" HIGH; see sound-music.md §6.1 |
| `FUN_10048120` | M_Music.cpp | stop music (fade=1: 1 s blocking fade-out, 600-tick guard) (was "stop/fade music" LOW) | HIGH | listing `10048158 li r3,0x3e8; bl 0x100d04d8` (1000 ms), `1004819c addi r31,r3,0x258` (now + 600), `10048180 cmplw r3,r31; ble` (guard), `100481bc bl 0x100d0250` (dispose) (`$W/disasm-review2.txt`); read + call args (sound-music.md §6.1) — ⚑ label rule (wave 2 synthesis): proposed HIGH on "read + call args" only — ⚑ label audit (review wave 2): raised back to HIGH on the listing — ⚑ corrected (wave 2, 2026-10-03): was "stop/fade music" LOW; see sound-music.md §6.1 |
| `FUN_100481e0` | M_Music.cpp | music stream exists | MED | read (sound-music.md §6.1) — ⚑ label rule (wave 2 synthesis): proposed HIGH on "read" only — ⚑ label audit (review wave 2): MED settled — the owning file had no listing line or data bytes for it, so its row was lowered to MED too |
| `FUN_10048220` | M_Music.cpp | pause (1: getRate+rateCmd 0) / resume (0: rateCmd saved) music | HIGH | listings `FUN_100d039c/040c` (sound-music.md §6.1) |
| `FUN_10048280` | M_Music.cpp | music level ← int pref 1 | MED | read (sound-music.md §4.2) — ⚑ label rule (wave 2 synthesis): proposed HIGH on "read" only — ⚑ label audit (review wave 2): MED settled — the owning file had no listing line or data bytes for it, so its row was lowered to MED too |
| `FUN_100482c0` | M_Music.cpp | music % → 0..128 | HIGH | table `0x100d7430` (sound-music.md §6.1) |
| `FUN_100cfe64` | sound lib | start music stream (FSpOpenDF, AIFC header, double buffer, loop flag) | MED | read (sound-music.md §6.1) — ⚑ label rule (wave 2 synthesis): proposed HIGH on "read" only — ⚑ corrected (wave 2, 2026-10-03): was "file stream player (SndPlayDoubleBuffer)" MED; see sound-music.md §6.1 — ⚑ label audit (review wave 2): MED settled — the owning file had no listing line or data bytes for it, so its row was lowered to MED too |
| `FUN_100d0250` | sound lib | stop music stream (quietCmd, dispose, close) | MED | read (sound-music.md §6.1) — ⚑ label rule (wave 2 synthesis): proposed HIGH on "read" only — ⚑ label audit (review wave 2): MED settled — the owning file had no listing line or data bytes for it, so its row was lowered to MED too |
| `FUN_100d04d8` | sound lib | start music fade-out over N ms | MED | read (sound-music.md §6.1) |
| `FUN_100d05d0` | sound lib | music double-buffer callback (fill, last-buffer, fade step) | MED | read (sound-music.md §6.2) |
| `FUN_100d0968` | sound lib | music buffer copy + PBReadAsync refill + loop wrap | MED | read (sound-music.md §6.3) |
| `FUN_100d136c` | sound lib | music ampCmd = min(255, vol·fade>>8) | HIGH | listing (sound-music.md §6.2) |
| `FUN_100d1400` | sound lib | mixer init (≤16 audible, 44.1k 16-bit stereo, 1024-frame double buffer, save device volume) | HIGH | listing (sound-music.md §1) |
| `FUN_100d1630` | sound lib | mixer shutdown, restore device L/R | MED | read (sound-music.md §2.1) — ⚑ label rule (wave 2 synthesis): proposed HIGH on "read" only — ⚑ label audit (review wave 2): MED settled — the owning file had no listing line or data bytes for it, so its row was lowered to MED too |
| `FUN_100d16d0` | sound lib | SetDefaultOutputVolume(v) | HIGH | listing (sound-music.md §4.1) |
| `FUN_100d1730` | sound lib | saved device volume, avg L/R | HIGH | listing (sound-music.md §2.1) |
| `FUN_1004a8b0` |  | input init | MED | read |
| `FUN_1004abd0` |  | InputSprocket needs + init | HIGH | read |
| `FUN_1004afa0` |  | InputSprocket poll -> 2x7 bytes | HIGH | read |
| `FUN_1004aa20` |  | clear input state | HIGH | read |
| `FUN_1004aa90` |  | copy polled input to game input | HIGH | read |
| `FUN_1004ab50` |  | get player n input (7 bytes) | MED | read |
| `FUN_1004ae00` |  | ISpConfigure dialog | MED | import |
| `FUN_10004f20` | U_Prefs.cc (span) | prefs reset: if arg, bytes 0–3/8/9/11 = 0, byte 10 (limiter) = 1, int 3 = 1; then `FUN_100050f0` | HIGH | listing (timing-frame.md §6) — ⚑ corrected (wave 2, 2026-10-03): was "reset byte/int pref defaults (limiter on, sector 1)" HIGH; see timing-frame.md §6 |
| `FUN_10010fc0` | M_Configuration.cc | preferences dialog DLOG/DITL 190: items 8/9/10/17 toggle byte prefs 4/5/7/8, sliders 12/15 → int prefs 0/1, 18 ISpConfigure, 3 Defaults, 4 Revert, 2 Cancel restores copy | HIGH | dump + DITL 190 resource (timing-frame.md §5) — ⚑ corrected (wave 2, 2026-10-03): was "configuration dialog (pref toggles, sliders, ISpConfigure)" MED; see timing-frame.md §5 |
| `FUN_10011590` | M_Configuration.cc (span) | load dialog controls from prefs (items 8/9/10/17, sliders 12/15 + "%i%%" labels 13/16; slider 12 enabled by pref 7) | HIGH | dump + DITL (timing-frame.md §5) |

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
- ~~Open conflicts flagged in rows: `FUN_10017150`, `FUN_10034ce0`, `FUN_10010570`.~~ → resolved
  in the review-wave-1 fix pass (below).

Review wave 1 fix-pass notes (⚑ corrected (review wave 1, 2026-10-03); review verdict
ACCEPT_WITH_FIXES, `REVIEW-wave1-2026-10-03.md`):
- **Conflicts resolved from the raw listing** (`$W/disasm-fix.txt`, own project copy
  `$W/work-fix`): `FUN_10017150` = rotation gate (not a spawn-set reader); `FUN_10034ce0(now, id)`
  (arg 1 is the time, not a state name); `FUN_10010570` = REVERSE (SCROLL is undefined
  `0x100104f0`); `FUN_1003cf10` = unit-module init + console registration + cache load (not
  "console unit commands"). Rows above carry the winning reading and the listing lines.
- **passHitsToOwner (review I1):** only ramming passes damage to the owner; player shots land on
  the turret's own shields (`FUN_10036cf0` row; bosses.md §3.5, §4 turret table).
- **Label audit (review M8):** HIGH rows whose only evidence was "dump"/"read"/"strings"/
  "accessor" and that no wave-1 file backs with a listing line were lowered to MED — 68 rows here,
  each marked `— ⚑ label audit (review wave 1)`; the same rows were lowered in the owning files'
  role-row sections (72 rows) and matching body tables (34 rows). Rows kept HIGH by pointing to
  another file's listing are marked "HIGH kept". `FUN_1003cf10`, `FUN_10034ce0` (listings read in
  the fix pass) and `FUN_1000f7a0` (TOC slots re-resolved) stayed HIGH.

Wave 2 notes (⚑ wave 2, 2026-10-03; nine topical files, rows merged above, pending Fable review):
- **No speed setting exists:** nothing writes the frame-controller divider `+0x2c` (only the
  zeroing `FUN_10030790`/`FUN_10030df0`); the "Game Speed …" strings have no consumer, so every
  frame is one logic tick (timing-frame.md §3).
- **30 ticks/s:** the limiter spins to last present + `FPS_Delay` (flli 33 = 2 Mac ticks) →
  60.15/2 ≈ 30.07 ticks/s on a fast machine, slow motion when a frame takes longer; no catch-up
  (timing-frame.md §2.3, §4). Esc-hold quits after 16 frames, not 30 (§2.5).
- **Only 10 live console commands:** `FUN_1002d080` skips registration when its debugOnly
  argument is set, so 1.0.6 registers just FPS, VERSION/VERS, SUPERMUNKI and the cheats LIFE,
  ACCURACY, FUNDS, SCORE, SHIELDS, MULT; SHADOWS, LIMITFPS, PLAYER, ALLLEVELS, NOTICE, HELP and the
  G_Background/entity commands are unreachable (messages-notices-console.md §5.2, timing-frame.md §6).
- **Game flag `+0x39` = level end reached:** set by `FUN_10006b50` on the scroll-end tick
  (`10006db4`), cleared by `FUN_10007170` before the next level start and by session init
  (loose-ends-combat.md §2, loose-ends-session.md §8.8).
- **Particle draws are in the replay stream:** `FUN_10043340` draws `R(0,4)` per particle inside
  the logic tick; the 302 init draws of `FUN_100431f0` come before any `srand`; the motion-blur
  interval draw never fires with shipped data (particles-debris-blur.md §1).
- **16-voice mixer:** M_Sound is a software mixer (16-entry ranked voice list, 8 audible =
  flli 38, 44.1 kHz 16-bit stereo) plus an AIFC streamer; `FUN_10047670(id, priority, volume,
  allowMultiple)` (sound-music.md §1–§3).
- Also: `FUN_100345f0` draws every entity sprite (sprite-geometry-draw.md); shadows go to layers
  2/4/6 (§5.2); `FUN_10009750` returns 1 when the film has finished (timing-frame.md §7);
  `FUN_1000beb0` is the game-screen present, not an interlaced present (timing-frame.md §2.4);
  `FUN_10000fd0` is a non-fatal alert (loose-ends-session.md §8); `FUN_10030df0` is the
  frame-controller state reset (front-end.md, timing-frame.md §1).
- ~~Open ⚑ conflicts in rows: `FUN_10009750` (signed vs unsigned compare; moot for non-negative
  counts), `FUN_10029c00` (command name PLAYER AIR/GROUND vs AIRWEP/GROUNDWEP; MED vs HIGH),
  `FUN_10030df0` (front-end.md calls +4 "interlace"; the listing reading is the present selector).~~
  ⚑ corrected (review wave 2, 2026-10-03): all three closed — `FUN_10009750` is **signed** (listing evaluated; #M1),
  `FUN_10029c00` = `PLAYER AIRWEP|AIR` / `PLAYER GROUNDWEP|GROUND` (HIGH), `FUN_10030df0` +4 =
  present selector (front-end.md corrected, #C2).

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
