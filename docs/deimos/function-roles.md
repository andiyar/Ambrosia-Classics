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
| `FUN_100009e0` | U_LinkedList.cc | linked list append | MED | newLinkPtr; used as list add everywhere |
| `FUN_10000ce0` |  | list count | MED | usage pattern |
| `FUN_10000e10` |  | list iterate (cursor) | MED | usage pattern |
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
| `FUN_10007170` |  | level complete -> next level / end | MED | read |
| `FUN_100064c0` |  | end session request | MED | callers |
| `FUN_100064d0` |  | start level (display, level load) | MED | perm consumer F52-56 |
| `FUN_100069b0` |  | load film for playback (attract cycle), srand(seed) | HIGH | read |
| `FUN_100072c0` |  | ground accuracy tier computation | MED | perm F188-194 |
| `FUN_100075e0` |  | end-of-level accuracy tally | MED | perm F195-203 |
| `FUN_10005cc0` |  | current level ID | HIGH | read |
| `FUN_10005cd0` |  | current sector number | HIGH | read |
| `FUN_10005ce0` |  | game time / frame accessor | LOW | usage |
| `FUN_10005d20` |  | player n pointer | MED | usage in FUN_10033850 |
| `FUN_10006190` |  | add points to player n | MED | read |
| `FUN_10006110` |  | any player active | MED | rule #7 |
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
| `FUN_1000fbc0` | G_Background.cc | load level map + media mask, mask element size | HIGH | read |
| `FUN_1000fee0` |  | is point on water (mask == 0x001f) | HIGH | read |
| `FUN_1000ffc0` |  | resume vertical scroll (speed 1) | HIGH | read |
| `FUN_1000ffe0` |  | pause vertical scroll | HIGH | read |
| `FUN_1000fff0` |  | is scroll paused | HIGH | read |
| `FUN_10010000` |  | scroll step, level-end flag, spawn objects at top-64 | HIGH | read |
| `FUN_10010220` |  | advance scroll window by speed | HIGH | read |
| `FUN_100100b0` |  | horizontal view shift ±32 | HIGH | read |
| `FUN_10010120` |  | draw terrain window | MED | perm F54/55 |
| `FUN_1000fec0` |  | scroll window top | MED | read |
| `FUN_10010990` |  | HTML RRGGBB -> 16-bit pixel | MED | string — ⚑ corrected (review 2026-10-03) #8: was HIGH on string/import/usage evidence only |
| `FUN_10010f90` |  | registered? (out of scope) | MED | callers |
| `FUN_10010e90` |  | registration banner (out of scope) | MED | perm S33-35 |
| `FUN_10010cf0` | M_Registration.cc | registration profile (out of scope) | MED | strings |
| `FUN_10011c00` | G_Level.cc | build level order list from encoded table | HIGH | read |
| `FUN_10011b30` |  | is level in first-4 (unregistered) set | HIGH | read |
| `FUN_100122f0` | G_Level.cc | parse level file | HIGH | read |
| `FUN_10012230` | G_Level.cc | load level by tag | MED | caller |
| `FUN_100120f0` | G_Level.cc | level info by ID | MED | callers |
| `FUN_10011e30` | G_Level.cc | sector number of current level | MED | caller |
| `FUN_10011de0` | G_Level.cc | level count | LOW | caller (last-level test) |
| `FUN_10012fa0` |  | draw entity: draw-layer 4CC -> render layer | HIGH | read |
| `FUN_10013460` |  | draw entity shadow | MED | perm F48-51 |
| `FUN_10014650` |  | current state pointer (unit+0x4e0+s*0x5e0) | HIGH | read |
| `FUN_100146f0` | G_Entity.cc | change state by name (Delete/Destroy special) | MED | strings |
| `FUN_10015550` |  | evaluate 5 state rules | HIGH | read |
| `FUN_10014f10` |  | damage entity | MED | perm F167 |
| `FUN_10016300` |  | destroy entity (random bonus table) | MED | perm F209-219 |
| `FUN_10016880` |  | water-impact spawn | MED | perm O6-9 |
| `FUN_10017510` |  | flee targets | MED | perm F14-17 |
| `FUN_10017cb0` |  | init state spawn-set timers | MED | read |
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
| `FUN_10021470` |  | score beats 15th high score | MED | read |
| `FUN_100214c0` |  | high-score entry | LOW | caller |
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
| `FUN_10026410` | G_Player.cc | player setup + permanent unit loads | MED | perm O0-39 |
| `FUN_10028170` |  | player update (movement, crosshair, defence bonus) | MED | perm F183-187 |
| `FUN_10029a10` |  | add score (obfuscated) + extra lives | HIGH | read |
| `FUN_1002a3a0` | G_Player.cc (span) | per-player input step: clear 7 bytes at +0x1fc, replay from film or poll ISp + record with decoded score | HIGH | disasm (engine-loop.md §7) — ⚑ corrected (review 2026-10-03) #4 |
| `FUN_10027670` |  | end-of-level coin bonus | MED | read |
| `FUN_10027930` |  | money counter display | MED | perm |
| `FUN_10027e50` |  | coin unit selection | MED | perm O2-5 |
| `FUN_10027100` |  | player hit spawn delay | MED | perm F162 |
| `FUN_100269a0` |  | player appear fade | MED | perm F163-165 |
| `FUN_10029fe0` |  | bonus multiplier units | MED | perm O35-39 |
| `FUN_10026c90` |  | player takes hit | LOW | usage |
| `FUN_10026c10` |  | player is alive | LOW | usage |
| `FUN_1002ba00` | G_WeaponDefinitions.cc | parse weapon definition | HIGH | read |
| `FUN_1003beb0` |  | bomb count default/max | MED | perm F151/152 |
| `FUN_1003b3c0` |  | weapon selector switch | MED | perm SND18 |
| `FUN_1003ade0` | G_WeaponHandler.cc | crosshair fade | MED | perm F149/150 |
| `FUN_1003cca0` |  | is default air/ground weapon (DEAA/DEAG) | MED | 4CCs |
| `FUN_1003c0d0` | G_WeaponHandler.cc (span) | air-weapon power-up state machine: spawn power-up unit (+0x1cc) after delay +0x1c8; charge level +0x20 every +0x1d0 ticks to max +0x1d4; overload after +0x1d8 (state 2); release at max if +0x1e4 (state 3, `FUN_10034ce0`) | MED | read (weapon-def `powerup_Air_*` +0x1c8..0x1e4) — ⚑ corrected (review 2026-10-03) #9 |
| `FUN_1003c4f0` | G_WeaponHandler.cc (span) | launch weapon: spawn each `spawn_*` record (unit +0x20 at player pos + XLoc/YLoc, heading +0x2c/+0x30) via `FUN_10033220`, then `crosshairSpawnOnActivation` (+0x180) | MED | read — ⚑ corrected (review 2026-10-03) #9 |
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
| `FUN_10033090` |  | spawn level objects at a scroll row | HIGH | read |
| `FUN_10033220` |  | spawn request (group, limits) | HIGH | read |
| `FUN_10035900` | G_EntityGroup.cc | build pending level-object list | HIGH | read |
| `FUN_100369f0` |  | group size with appearsPercent | HIGH | read |
| `FUN_10035bf0` |  | spawn group members | HIGH | read |
| `FUN_10035cd0` |  | create one entity (shields by sector, spawn delay) | HIGH | read |
| `FUN_10037930` | G_EntityGroup.cc (span) | member placement: x/yOffsetMin/Max rectangular or radial, randomiseInitialLoc | HIGH | disasm (waves-and-enemies.md §4) — ⚑ corrected (review 2026-10-03) #2 |
| `FUN_10037b50` | G_EntityGroup.cc (span) | initial speed (float draw initialSpeedMin/Max) + initial heading (± tolerance draw) / hunt / burst | MED | read — ⚑ corrected (review 2026-10-03) #2 |
| `FUN_10012910` |  | set entity position (x,y) | MED | callers `FUN_10037930` — ⚑ corrected (review 2026-10-03) #2 |
| `FUN_100351f0` |  | count live entities of a unit | MED | rule #14-16 |
| `FUN_100352f0` |  | any destroyable air entity | MED | rule #4 |
| `FUN_100353e0` |  | any destroyable ground entity | MED | rule #5 |
| `FUN_10036cf0` |  | state spawn sets executor | LOW | caller context |
| `FUN_1003d0a0` | G_UnitDefinitions.cc | build master unit list (1..20 states) | HIGH | read |
| `FUN_1003d650` | G_UnitDefinitions.cc | unit-definition struct copy (field-by-field assignment); caller `FUN_10041e40` | MED | read — ⚑ corrected (review 2026-10-03) #9 |
| `FUN_1003fc50` | G_UnitDefinitions.cc | load unit i | MED | strings |
| `FUN_1003fda0` | G_UnitDefinitions.cc | parse unit definition | HIGH | read |
| `FUN_10040920` | G_UnitDefinitions.cc | parse one state | HIGH | read |
| `FUN_1003d2f0` |  | find unit definition by ID | MED | usage |
| `FUN_1003e680` |  | load unit resources (sounds/sprites) | MED | strings |
| `FUN_1003f4e0` | G_UnitDefinitions.cc | add unit to family list | MED | strings |
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
