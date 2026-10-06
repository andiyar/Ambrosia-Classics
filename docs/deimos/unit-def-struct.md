# Deimos Rising 1.0.6 — unit-definition, state, rule, spawn-set and player-definition structs (authoritative map with defaults)

Scope: `G_UnitDefinitions.cc` `0x1003d0a0–0x10042100` and `G_PlayerDefinitions.cc`
`0x10039280–0x1003a780` (inventory module spans), every function listed there, plus the two
direct neighbours needed to place them (`FUN_1003cf10` unit-manager init, `FUN_1003d030`
shutdown — both just below the range, read for context). OUT: the consumers of these structs
(entity update, movement, spawn-set executor, rule evaluator — waves-and-enemies.md §3), the
token readers themselves (data-tags.md §1; only their missing-key behaviour is restated here),
weapons (`wede`). Code readings only; nothing behaviour-verified.

Evidence codes used in the tables (all from the raw listing `$W/disasm-unitdef.txt`, produced by
`DisasmFuncs.java` on a private copy `$W/work-unitdef` for all 56 in-scope functions):
- **P@addr** — the reader `bl` at that address; destination = register + displacement of the
  `addi r6,…` before it. In `FUN_1003fda0` the destination register is `r29 = unit+0x18`
  (`1003fdb4 addi r29,r31,0x18`), so the table adds 0x18. In `FUN_10040920` `r30` = state base
  (`10040924 mulli r5,r5,0x5e0 · 10040934 addi r30,r5,0x4e0 · 10040938 add. r30,r28,r30`), `r25` =
  the new spawn-set record, `r28 = r30 + r*0x88` (`1004171c add r28,r30,r26`, `100417a4 addi
  r26,r26,0x88`). Type = which reader (`FUN_1002cb20` STR, `…c7d0` ID, `…c880` INT, `…c960` FLOAT,
  `…ca40` BOOL, `…cbd0` COLOR); STR size = the `li r7,…` max length.
- **D@addr** — the store in the defaults functions `FUN_1003e1e0` (unit) / `FUN_1003e3d0` (state) /
  `FUN_1003f470` (rules) / `FUN_1003e490` (spawn set) / `FUN_10039cf0` (plde).
- **C** — size/boundary/type confirmed by the compiler-generated copy `FUN_1003d650` and its
  per-block helpers (`lbz/stb` = 1-byte bool, `lhz/sth` = 16-bit colour, `lfs/stfs` = float,
  `lwz/stw` = int/ID; bytes it never touches = padding).
Machine cross-check: a script walked the listing (`lk.py`, scratchpad) and compared all 220 reader
calls of `FUN_1003fda0`/`FUN_10040920` with `key_offsets.py` on the dump: **0 offset or type
mismatches** (the only differences are the two stack destinations `numStates_INT` → `r1+0x38` and
`stateRuleName_STR` → `r1+0x40`, which the tool prints as `0x000`). [HIGH]

## 1. Lifecycle and the functions that touch the structs

```
FUN_1003cf10 (init "Unit Definition" manager; registers LOG… debug commands)
  └ FUN_100420f0  Units Cache READER  ──ok──▶ "Units Cache loaded OK."
       └ fail ─▶ FUN_1003d0a0(1)  build master list: for i=0.. FUN_1003fc50(i)
                    FUN_1003fc50: alloc 0x7a60 · memset 0 · FUN_1003e1e0 defaults · FUN_1003fda0 parse
                                  · unit+8 = isGroundBased?'grnd':'air ' · token error ⇒ unit+0x10=1 + fatal alert
                    append to master list · numStates bounds check · FUN_1003f4e0 family list
FUN_1003d030 (shutdown, also called from the shutdown sequence FUN_10000630)
  └ if cache flag DAT_100e024c: FUN_10041e40 Units Cache WRITER (uses FUN_1003d650)
```

| function | role | label | evidence |
|---|---|---|---|
| `FUN_1003cf10 @ 1003cf10` | unit manager init: `FUN_1003a870("Unit Definition",1)`, 5 debug commands (LOGSCROLLPAUSERS, LOGFAMILIES/FAMILIES, LOGUNUSEDUNITS, UNITSCORES), then cache-or-build | HIGH | dump; strings `0x100ed179` "Units Cache not loaded. (Attempting to load all Unit Def Tags instead.)"; listing `1003cf34 bl 0x1003a870` ("Unit Definition"), `1003cf5c…1003cfdc` 4× `bl 0x1002d080` (handlers = undefined code `0x10041a40/b30/b70/d70` via TOC r2−0x6e3c/−0x6e40/−0x6e44/−0x6e48), `1003cfe4 bl 0x100420f0; bne` → else `1003d000 bl 0x1003d0a0(1)`; caller `FUN_100000e0` — ⚑ label audit (review wave 1): HIGH kept, listing added in the fix pass |
| `FUN_1003d0a0 @ 1003d0a0` | build master list (list head `_DAT_100e0260`, family list `_DAT_100e025c`); loops `FUN_1003fc50(i)` until 0; appends **before** the bounds check; logs + asserts only when n < 0 or n > 20 | HIGH | listing `1003d1bc lwz r0,0x14(r28) · cmpwi r0,0x0 · blt · cmpwi r0,0x14 · ble 1003d220` (skip both log and assert); assert text `0x100ed297` "unitPtr->fileData.numStatesUsed > 0 and … <= kG_UnitDef_MaxNumStates" |
| `FUN_1003fc50 @ 1003fc50` | load unit i: `FUN_10002be0(i,'unde')`, decode, alloc 0x7a60, memset, defaults, parse, layer, error flag | HIGH | dump + listing `1003fd68 stb r0,0x10(r30)`; `FUN_1004d320(0x7a60)` |
| `FUN_1003e1e0 @ 1003e1e0` | unit defaults (frees any old spawn-set lists, memset 0x7a60, header + 20 `'none'` IDs + 4 sound records + group/scale/visibility/appears + 20× `FUN_1003e3d0`; state 0 name "State 1") | HIGH | listing `1003e1e0–1003e3c4` (§3 D@ column); `"State 1"` = `r2+0x6ce0+0x46b` = `0x100ed47b` |
| `FUN_1003e3d0 @ 1003e3d0` | state defaults (memset 0x5e0, entry-sound record, MaxNumToPlay 1, rules, 4 IDs `'none'`, required scale/visibility 100) | HIGH | listing `1003e3d0–1003e48c` |
| `FUN_1003f470 @ 1003f470` | rule-block defaults: count 0; 5× {unit `'none'`, cond "", action "", range 0} | HIGH | listing (stride `0x88`: `stw r4,0x4/0x8c/0x114/0x19c/0x224`) |
| `FUN_1003e490 @ 1003e490` | spawn-set defaults | HIGH | listing; caller `FUN_10040920` |
| `FUN_1003fda0 @ 1003fda0` | parse unit (unit-level keys, then `numStates` × `FUN_10040920`) | HIGH | listing §3 |
| `FUN_10040920 @ 10040920` | parse state s (keys, spawn sets, rules) | HIGH | listing §4–§6 |
| `FUN_1003d650 @ 1003d650` | **compiler-generated copy-assignment of the `fileData` sub-struct = unit+0xc … +0x7a60 (0x7a54 bytes)**; only caller is the cache writer | HIGH | listing: states start at `addi r31,r29,0x4d4`, end `addi r28,r29,0x7a54`, stride `addi r31,r31,0x5e0` (0x4d4+0xc = 0x4e0); writer copies words 0–2 itself then calls it on `+3` words |
| `FUN_1003e1a0 @ 1003e1a0` | copy sound record (ID,int,int,int,float,float = 0x18) | HIGH | `lwz×4, lfs 0x10, lfs 0x14` |
| `FUN_1003e120 @ 1003e120` | copy shields block (3 floats + 2 sound records = 0x3c, unit 0x43c–0x477) | HIGH | `lfs 0x0/0x4/0x8`, then two sound patterns |
| `FUN_1003e040 @ 1003e040` | copy destruct block (unit 0x478–0x4d3, 0x5c) | HIGH | listing |
| `FUN_1003e020 @ 1003e020` | copy pickup block (unit 0x4d4–0x4df) | HIGH | `lwz 0x0/0x4/0x8` |
| `FUN_1003dfb0 / de70 / de30 / de00 / ddc0 / dd60 / dce0` | copy state sub-blocks at state +0x000 (sound, 0x24) / +0x024 (rules, 0x2ac) / +0x2d0 (particles, 0x10) / +0x2e0 (collision, 0xc) / +0x2ec (motion blur, 0x14) / +0x300 (animation, 0x20) / +0x324 (owner bools, 0xe) | HIGH | call sites `1003d918–1003d968` with `addi r3,r31,<off>` |
| `FUN_1003d2f0 @ 1003d2f0` | find unit by ID (linear over master list, compares unit+4) | HIGH | `1003d35c lwz r0,0x4(r3) · cmpw r0,r28`; callers `FUN_1002a450 FUN_10033220 FUN_10035900` |
| `FUN_1003d3a0 @ 1003d3a0` | i-th unit of the master list (0-based) | MED | dump (counter `== i+1`) |
| `FUN_1003d450 @ 1003d450` | family record of a unit (by `familyName` +0x58, empty → default family `" Misc"`) | HIGH | dump; `_DAT_100e0244 → 0x100ed01f " Misc"` (memory image) |
| `FUN_1003d550 @ 1003d550` | find unit by ID, first inside a family's member list (`fam+0x40`), then globally | MED | dump; callers `FUN_10015550` (rules), `FUN_10015b40` |
| `FUN_1003f4e0 @ 1003f4e0` | add unit to its family (create 0x4c-byte family {name[0x40], list@+0x40} if new; no-name units → " Misc", prepended) | MED | dump; `FUN_1004d320(0x4c)` — ⚑ label audit (review wave 1) |
| `FUN_1003e680 @ 1003e680` | load a unit's resources once (`FUN_1003fb60` guard): verify 4 unit sounds + every state's entry sound (`FUN_100417d0`) and sprite face (`FUN_100418a0`), missing → field reset to `'none'` with a log; recurse into destructCoin, coinOnGroupKill, deletionSpawn, destructSpawn, pickup_MultiplierSpawn, each state's collision_Spawn and every spawn-set Spawn_ID | MED | dump (offsets 0x4bc 0x448 0x460 0x424 0x4a8 0x4ac 0x2dc 0x478 0x4d8; state +0x000 +0x304 +0x2e0; spawn +0x20) — ⚑ label audit (review wave 1) |
| `FUN_1003e580 @ 1003e580` | load resources for unit ID (find + `FUN_1003e680`) | HIGH | listing `1003e5fc lwz r0,0x4(r3)`; callers `FUN_1002b790`, `FUN_100399a0` |
| `FUN_1003e510 @ 1003e510` | (re)create the "already-loaded resources" list `_DAT_100e0258` | MED | string `sPriv_UnitResourceListPtr`; callers `FUN_100051a0 FUN_100064d0` (game start) — ⚑ label audit (review wave 1) |
| `FUN_1003fb60 @ 1003fb60` | test-and-insert unit ID into that list | MED | dump — ⚑ label audit (review wave 1) |
| `FUN_1003fa80 @ 1003fa80` | free that list | MED | dump |
| `FUN_1003ec70 @ 1003ec70` | list of unit IDs a unit references (coin, coinOnGroupKill, deletionSpawn, destructSpawn, pickup_MultiplierSpawn, **all 5** rule units per state, spawn-set IDs — not collision_Spawn) | MED | dump (`iVar4 < 5`, stride 0x88 at state+0x28) — ⚑ label audit (review wave 1) |
| `FUN_1003ef90 @ 1003ef90` | "is unit ID referenced by any other unit" (LOGUNUSEDUNITS) | MED | dump; no direct caller (debug command table) |
| `FUN_1003f0b0 @ 1003f0b0` | collect all sprite IDs (mode 1: each state's sprite face, unit+0x7e4 = 0x4e0+0x304) or sound IDs (mode 0: 4 unit sounds + state entry sounds) of every unit into a list | MED | dump; no direct caller |
| `FUN_1003f280 @ 1003f280` | integrity check: every master-list entry has magic 0x499602d2, else "Unit Manager Integrity FAILURE" | HIGH | listing `1003f2fc subis r0,r3,0x4996 · cmplwi r0,0x2d2` |
| `FUN_1003f360 / f410 / f830 / fa10` | free master list (and every state's spawn-set list) / free one list / free family list / free one family | MED | dump |
| `FUN_1003f8b0 @ 1003f8b0` | log the family table ("Unit Definition Families") | MED | strings |
| `FUN_10041960 @ 10041960` | check a sprite ID exists (`FUN_1001fbe0`), else log "MISSING SPRITE RESOURCE" and set `'none'` (used for editorPreviewSpriteFace and stateSpriteFace at parse time) | MED | dump; callers `FUN_1003fda0 FUN_10040920` — ⚑ label audit (review wave 1) |
| `FUN_100417d0 / FUN_100418a0` | same for sound / sprite at resource-load time | MED | strings "SOUND RESOURCE MISSING", "SPRITE RESOURCE MISSING" — ⚑ label audit (review wave 1) |
| `FUN_10041e40 @ 10041e40` | **Units Cache writer** (§8) | MED | dump + `FUN_100426e0` — ⚑ label audit (review wave 1) |
| `FUN_100420f0 @ 100420f0` | **Units Cache reader** (§8) — ⚑ the review/handoff called it the writer | MED | dump; strings "Units Cache Invalid…" — ⚑ label audit (review wave 1) |

## 2. Parse semantics that decide which defaults survive

1. **Missing STR key → silent default.** `FUN_1002cb20` returns without calling the error logger
   when the key is not found (listing `1002cb64 beq 0x1002cba8`; the only calls are
   `bl 0x1002c550/0x1000cd90/0x10046510`). Present STR → dest memset to its max length, then at most
   max−1 chars copied (always NUL-terminated); `<>` → empty string (overrides a default such as
   "State 1"). [HIGH]
2. **Missing or malformed INT/FLOAT/BOOL/ID/COLOR → error flag, dest untouched.** E.g. `FUN_1002c880`
   calls `FUN_1002ce60` on not-found (`1002c93c`) and on length < 1 (`1002c8d8`); ID must be exactly
   4 chars. `FUN_1002ce60` sets `DAT_100e01e1 = 1` only while strict mode `DAT_100e01e0` is on, which
   `FUN_1002c4d0(tagName, 1)` turns on before each `unde`/`plde` parse (`FUN_1003fc50`,
   `FUN_10039cf0`). After the parse `FUN_1002c540()` ≠ 0 ⇒ `unit+0x10 = 1` and
   `FUN_10001040("A Unit Definition file contained incorrect or missing data.", 1)` →
   `FUN_1000ced0("Error", msg, 1)` which shows the alert and, because the 3rd argument is 1, runs
   `FUN_10000630` ("Starting Shut Down Sequence"). So in the shipped engine **a missing non-string key
   is fatal at load**; its default is never used in play. [HIGH for the call chain; MED that
   `FUN_10000630` ends the process — it calls ~30 shutdown routines, the final one not read]
3. **Forward-only cursor**: a key absent from state *s* is found in state *s+1* (strstr from the
   cursor to the end of the buffer) and the cursor jumps there — the rest of state *s* then
   misparses. Only matters for hand-edited files. [HIGH — `FUN_1002c550` only moves the cursor on
   success; reasoning for the consequence]
4. **Uninitialised counts.** `numStates` (`r1+0x38` in `FUN_1003fda0`), `numSpawnSets` (`r1+0x3c`)
   and `numRules` (`r1+0x38`) in `FUN_10040920` are stack locals with no initialising store before
   the reader (only the cursor `r1+0x3c`/`stw r0,0x3c(r1)` @1003fdc8 is zeroed in the unit parser).
   A missing count key leaves garbage — but per item 2 that is already fatal. The unit-def default
   `numStates = 1` (`D@1003e280`) is therefore **always overwritten** (`10040818 stw r0,0x14(r31)`).
   [HIGH]
5. **No caps in the parser.** `FUN_1003fda0` loops `numStates` times and `FUN_10040920` loops
   `numRules` times with no bound (`100417ac lwz r0,0x38(r1) · cmpw r25,r0 · blt`): numStates > 20
   writes past the 0x7a60 allocation before `FUN_1003d0a0` checks it; numRules > 5 overwrites
   state+0x2d0… (particles, collision, …) with rule data. numStates = 0 is accepted silently (§1).
   numSpawnSets is unbounded by design (linked list). Shipped data: states ≤ 14, rules = 5 in all
   1167 states, spawn sets ≤ 7 (waves-and-enemies.md §2 census) — inside every limit. [HIGH]
6. **Post-parse fix-ups** (all in listing):
   - unit: `shields_MaxAmount < shields_BaseAmount ⇒ MaxAmount = BaseAmount`
     (`100403a8 lfs f0,0x42c(r29) · lfs f1,0x424(r29) · fcmpo · bge · stfs f1,0x42c(r29)`; r29-relative
     0x42c/0x424 = unit 0x444/0x43c). Shipped: 6 units have max 0 < base (`bagb bgpb cair icpb icb 
     jgbu`, all increment 0) → max becomes base; no effect on the spawn formula, which only applies
     the cap when increment > 0 (waves-and-enemies.md §3). [HIGH]
   - unit: `unit+8 = isGroundBased ? 'grnd' : 'air '` (`FUN_1003fc50`). [HIGH]
   - state: `OnTimerMax < OnTimerMin ⇒ Max = Min` (`10040a18 lwz r0,0x3b0(r30) · lwz r3,0x3ac(r30) ·
     cmpw · bge · stw r3,0x3b0(r30)`); then if `Max > 0` and `OnTimerChangeTo` is empty: log "NOTE: A
     Unit Definition has an unused State Change Timer." and **both timers = 0** (`10040a98–10040aa0`).
     [HIGH]
   - state: any of the owner bools 0x324–0x32d (checked after reading them) or 0x32e/0x32f/0x330
     set ⇒ `unit+0x11 = 1`. [HIGH — dump; consumer of unit+0x11 not found, see NOT RESOLVED]
   - state: `stateSpriteFace_ID` / unit `editorPreviewSpriteFace_ID` not present as a sprite ⇒ set to
     `'none'` (`FUN_10041960`). [HIGH]
   - spawn set with `Spawn_ID == 'none'`: logged ("Suggest you delete the Spawn Set"), kept. [HIGH]
   - unit: FYI logs only for destroy-but-not-delete children and for delete/destroy children with
     no spawn sets. [HIGH]
7. Key strings `stateNumSpawnSets_INT` and `stateRuleAction_STR` are stored **without** the leading
   `#` (`100410b0 addi r5,r31,0x1991`, `10041774 addi r5,r31,0x2178`, `r31 = r2+0x6ce0`; bytes at `0x100ed010+0x1991` = `00 "stateNumSpawnSets_INT"`); `strstr` still matches the `#…`
   text. [HIGH]

## 3. Unit-definition struct (`unde`, sizeof 0x7a60, base = the pointer stored in the master list)

Layout: header 0x0–0xb (not in the copy), `fileData` 0xc–0x7a5f (`FUN_1003d650`): scalars
0xc–0x4df, then `state[20]` at 0x4e0 (§4). Offsets are unit-relative. Default = value after
`FUN_1003e1e0` (memset 0 unless listed). Types: `OSType` 4-char ID, `pix16` 16-bit pixel from the
HTML `RRGGBB` reader, `bool8` 1 byte (TRUE iff value == "TRUE"). Label: every `P@`/`D@` row
[HIGH — listing]; rows marked "no key" [MED — existence/size from C, meaning unknown].

| off | type | key / meaning | default | evidence |
|---|---|---|---|---|
| 0x000 | uint32 | — magic | 0x499602d2 (1234567890) | D@1003e24c; integrity check FUN_1003f280 `subis r0,r3,0x4996; cmplwi r0,0x2d2` |
| 0x004 | OSType | — unit ID (the `unde` tag ID) | 'none' | D@1003e25c; parser `stw r3,0x4(r5)` @1003fdcc; compared by FUN_1003d2f0 `lwz r0,0x4(r3); cmpw` @1003d35c |
| 0x008 | OSType | — layer (derived) | 'air ' | D@1003e268; after parse = isGroundBased ? 'grnd' : 'air ' (FUN_1003fc50) |
| 0x00c | int32 | — fileData version (no key) | 10000 | D@1003e278 `li r0,0x2710`; = Units Cache header version (§8) [MED: name] |
| 0x010 | bool8 | — data-error flag (no key) | 0 | D@1003e290; set 1 by FUN_1003fc50 `stb r0,0x10(r30)` @1003fd68 when the token error flag is up |
| 0x011 | bool8 | — "has owner-linked state" (no key) | 0 | D@1003e298; set 1 by FUN_10040920 if any state sets a bool in 0x324–0x330 (§4) |
| 0x012 | pad[2] | — (not copied by FUN_1003d650) | 0 | C |
| 0x014 | int32 | `numStates_INT` | 1, but always overwritten (see §2) | D@1003e280; P@10040808 into stack r1+0x38, `stw r0,0x14(r31)` @10040818 |
| 0x018 | char[0x40] | `name_STR` | "" | P@1003fe14 |
| 0x058 | char[0x40] | `familyName_STR` | "" | P@1003fe30 |
| 0x098 | char[0x80] | `description_STR` | "" | P@1003fe4c |
| 0x118–0x11e | bool8 ×7 | 118 `doNotSpawnIfTypeAlreadyExists_BOOL` · 119 `deleteExistingEntitiesOfThisTypeOwnedByPlayer_BOOL` · 11a `harmlessToPlayers_BOOL` · 11b `playerProjectile_BOOL` · 11c `canBeHitByPlayerProjectile_BOOL` · 11d `constrainInGameArea_BOOL` · 11e `castsShadows_BOOL` | FALSE | P@1003fef4 P@1003fedc P@1003ff0c P@1003ff24 P@1003ff3c P@1003ff6c P@1003ff84 |
| 0x11f–0x125 | bool8 ×7 | 11f `initiallyHuntsClosestPlayer_BOOL` · 120 `displayNoticeOnceOnly_BOOL` · 121 `hittableWhenInvisible_BOOL` · 122 `doBurst_BOOL` · 123 `doImplode_BOOL` · 124 `initialHeadingSetInEditor_BOOL` · 125 `isGroundBased_BOOL` | FALSE | P@1003ffe4 P@10040490 P@1003fffc P@10040790 P@100407a8 P@10040014 P@100407c0 |
| 0x126–0x12c | bool8 ×7 | 126 `fleesNorthOnNoActivePlayers_BOOL` · 127 `fleesSouthOnNoActivePlayers_BOOL` · 128 `collidesWithGroundObstacles_BOOL` · 129 `useOwnerHeading_BOOL` · 12a `canBeSpawnedOnlyWhenPlayersActive_BOOL` · 12b `doDeathSpawnOnAnyMedia_BOOL` · 12c `adjustShadowLocForScaling_BOOL` | FALSE | P@1004002c P@10040044 P@1004005c P@10040748 P@10040074 P@100407d8 P@1003ff9c |
| 0x12d–0x133 | bool8 ×7 | 12d `randomiseInitialLoc_BOOL` · 12e `adjustInitialLocForOwnerScale_BOOL` · 12f `usePreviewAppearanceInPlacementEditor_BOOL` · 130 `allowStationaryOptionInPlacementEditor_BOOL` · 131 `hitParticleDoCircularBurst_BOOL` · 132 `terrainEffect_BOOL` · 133 `includeInAirAccuracyCount_BOOL` | FALSE | P@1003ffb4 P@1003ffcc P@1004008c P@100400a4 P@10040550 P@1003ff54 P@100400bc |
| 0x134 | bool8 | `includeInGroundAccuracyCount_BOOL` | FALSE | P@100400d4 |
| 0x135 | byte[0x45] | — no key (0x135–0x179) | 0 | memset only; copied as a block (C); consumer not searched |
| 0x17a | byte[4] | — no key (0x17a–0x17d) | 0 | copied as two halfwords (C) — possibly two unused COLOR slots [LOW] |
| 0x17e | pix16 | `hitParticlesColor_COLOR` | 0 | P@10040568 |
| 0x180 | byte[0x12] | — no key (0x180–0x191) | 0 | copied as words/halfwords (C) |
| 0x192 | pad[2] | — | 0 | not copied (C) |
| 0x194 | int32 | `numInGroupMin_INT` | 1 | P@1003fe64 |
| 0x198 | int32 | `numInGroupMax_INT` | 1 | P@1003fe7c |
| 0x19c | int32 | `groupDelayMin_INT` | 0 | P@1003fe94 |
| 0x1a0 | int32 | `groupDelayMax_INT` | 0 | P@1003feac |
| 0x1a4 | int32 | `initialHeading_INT` | 0 | P@10040718 |
| 0x1a8 | int32 | `initialHeadingTolerance_INT` | 0 | P@10040730 |
| 0x1ac | int32 | `initialScalePercent_INT` | 100 | P@10040414 |
| 0x1b0 | int32 | `initialScalePercentTolerance_INT` | 0 | P@1004042c |
| 0x1b4 | int32 | `initialVisibilityPercent_INT` | 100 | P@100403fc |
| 0x1b8 | int32 | `entryNoticeDelay_INT` | 0 | P@10040478 |
| 0x1bc | int32 | `editorPreviewSpriteFrame_INT` | 0 | P@10040114 |
| 0x1c0 | int32 | `appearsPercent_INT` | 100 | P@1003fec4 |
| 0x1c4 | byte[0x98] | — no key (0x1c4–0x25b) | 0 | memset only (C) |
| 0x25c | float | `xOffsetMin_FLOAT` | 0 | P@100406b8 |
| 0x260 | float | `xOffsetMax_FLOAT` | 0 | P@100406d0 |
| 0x264 | float | `yOffsetMin_FLOAT` | 0 | P@100406e8 |
| 0x268 | float | `yOffsetMax_FLOAT` | 0 | P@10040700 |
| 0x26c | float | `initialSpeedMin_FLOAT` | 0 | P@10040760 |
| 0x270 | float | `initialSpeedMax_FLOAT` | 0 | P@10040778 |
| 0x274 | float | `damage_FLOAT` | 0 | P@100403e4 |
| 0x278 | byte[0x5c] | — no key (0x278–0x2d3) | 0 | memset only (C) |
| 0x2d4 | OSType | `editorPreviewSpriteFace_ID` | 'none' | P@100400ec |
| 0x2d8 | OSType | `hitParticles_ID` | 'none' | P@10040538 |
| 0x2dc | OSType | `deletionSpawn_ID` | 'none' | P@100406a0 |
| 0x2e0 | OSType | `drawLayer_ID` | 'none' | P@10040444 |
| 0x2e4 | OSType | `mediaImpactSize_ID` | 'none' | P@100407f0 |
| 0x2e8 | OSType[15] | — no key (0x2e8–0x323): 15 reserved ID slots | 'none' each | D@1003e2b0…1003e2e8 (`stw r8,0x2e8(r31)` … `stw r8,0x320(r31)`, r8 = 'none') |
| 0x324 | char[0x100] | `entryNotice_STR` | "" | P@10040460 |
| 0x424 | sound rec 0x18 | `entryNoticeSound_ID` +0 · `…_MinVolume_INT` +4 · `…_MaxVolume_INT` +8 · `…_Priority_INT` +0xc · `…_MinPitch_FLOAT` +0x10 · `…_MaxPitch_FLOAT` +0x14 | 'none', 100, 100, 100, 1.0, 1.0 | P@100404a8 … P@10040520 |
| 0x43c | float | `shields_BaseAmount_FLOAT` | 0 | P@100403a0 |
| 0x440 | float | `shields_LevelIncrement_FLOAT` | 0 | P@10040388 |
| 0x444 | float | `shields_MaxAmount_FLOAT` | 0 | P@10040370 |
| 0x448 | sound rec 0x18 | `shieldSound_ID` +0 · `…_MinVolume_INT` +4 · `…_MaxVolume_INT` +8 · `…_Priority_INT` +0xc · `…_MinPitch_FLOAT` +0x10 · `…_MaxPitch_FLOAT` +0x14 | 'none', 100, 100, 100, 1.0, 1.0 | P@10040580 … P@100405f8 |
| 0x460 | sound rec 0x18 | `unshieldedSound_ID` +0 · `…_MinVolume_INT` +4 · `…_MaxVolume_INT` +8 · `…_Priority_INT` +0xc · `…_MinPitch_FLOAT` +0x10 · `…_MaxPitch_FLOAT` +0x14 | 'none', 100, 100, 100, 1.0, 1.0 | P@10040610 … P@10040688 |
| 0x478 | OSType | `destructSpawn_ID` | 'none' | P@10040174 |
| 0x47c | OSType | `destructParticle_ID` | 'none' | P@1004021c |
| 0x480 | pix16 | `destructParticleColor_COLOR` | 0 | P@10040234 |
| 0x482 | char[0x20] | `destructNotice_STR` | "" | P@10040250 |
| 0x4a4 | int32 | `destructNumCoinsToRelease_INT` | 0 | P@10040268 |
| 0x4a8 | OSType | `destructCoin_ID` | 'none' | P@10040280 |
| 0x4ac | OSType | `destructCoinOnGroupKill_ID` | 'none' | P@10040298 |
| 0x4b0–0x4b4 | bool8 ×5 | 4b0 `destructDestroyChildren_BOOL` · 4b1 `destructDeleteChildren_BOOL` · 4b2 `destructDrawToTerrain_BOOL` · 4b3 `destructCreateObstacle_BOOL` · 4b4 `destructReleaseRandomBonus_BOOL` | FALSE | P@100402b0 P@100402c8 P@100402e0 P@10040310 P@100402f8 |
| 0x4b5 | bool8 | — no key | FALSE | copied as a byte inside the destruct block (FUN_1003e040 +0x3d) |
| 0x4b6 | pad[2] | — | 0 | not copied (C) |
| 0x4b8 | int32 | `score_INT` | 0 | P@100403cc |
| 0x4bc | sound rec 0x18 | `destructSound_ID` +0 · `…_MinVolume_INT` +4 · `…_MaxVolume_INT` +8 · `…_Priority_INT` +0xc · `…_MinPitch_FLOAT` +0x10 · `…_MaxPitch_FLOAT` +0x14 | 'none', 100, 100, 100, 1.0, 1.0 | P@1004018c … P@10040204 |
| 0x4d4 | OSType | `pickup_Type_ID` | 'none' | P@1004012c |
| 0x4d8 | OSType | `pickup_MultiplierSpawn_ID` | 'none' | P@10040144 |
| 0x4dc | int32 | `pickup_Value_INT` | 0 | P@1004015c |
| 0x4e0 | state[20] | states, stride 0x5e0 (§4) | §4 | `FUN_10040920` `mulli r5,r5,0x5e0 · addi r30,r5,0x4e0`; copy loop end `0x4d4+20·0x5e0 = 0x7a54` (+0xc) |

Notes. (a) Code defaults ≠ editor defaults: the shipped files write sound `Priority 50`, the code
default is 100 — irrelevant because every shipped file carries every key (worked example).
(b) `damage_FLOAT` 0x274 and the four group ints are plain scalars; `initialScalePercent` /
`initialVisibilityPercent` / `appearsPercent` are **INT** (reader `FUN_1002c880`, defaults stored
with `stw r0` = int 100 @1003e36c/70/74). (c) The 20 ID words 0x2d4–0x320 all default to `'none'` (D@1003e29c–1003e2e8). (d) `editorPreviewSpriteFace_ID` is validated at parse
time; the other IDs only at resource-load time (`FUN_1003e680`). [HIGH]

## 4. State struct (sizeof 0x5e0; state s at unit + 0x4e0 + s·0x5e0, s = 0..19)

Offsets are state-relative (add 0x4e0 + s·0x5e0 for unit-relative; state 0 = unit+0x4e0).
Default = after `FUN_1003e3d0` (applied to all 20 states, including those beyond `numStates`).

| off | type | key / meaning | default | evidence |
|---|---|---|---|---|
| 0x000 | sound rec 0x18 | `stateEntrySound_ID` +0 · `…_MinVolume_INT` +4 · `…_MaxVolume_INT` +8 · `…_Priority_INT` +0xc · `…_MinPitch_FLOAT` +0x10 · `…_MaxPitch_FLOAT` +0x14 | 'none', 100, 100, 100, 1.0, 1.0 | P@10040d94 … P@10040e0c |
| 0x018–0x01a | bool8 ×3 | 018 `stateSoundLoop_BOOL` · 019 `stateSoundAllowOnlyOneInstance_BOOL` · 01a `stateSoundRepeatOnStateChange_BOOL` | FALSE | P@10040e54 P@10040e6c P@10040e84 |
| 0x01b | bool8 | — no key | FALSE | byte copy FUN_1003dfb0 +0x1b |
| 0x01c | int32 | `stateSoundLoopDelay_INT` | 0 | P@10040e24 |
| 0x020 | int32 | `stateSoundMaxNumToPlay_INT` | 1 | P@10040e3c |
| 0x024 | int32 | — active-rule count (derived) | 0 | FUN_1003f470 `stw r0,0x0(r3)`; = number of read rules whose unit ≠ 'none' (§5) |
| 0x028 | rule[5] | rules, stride 0x88 (§5) | see §5 | FUN_1003de70 loop end `addi r0,r3,0x2ac` |
| 0x2d0 | OSType | `stateParticles_ID` | 'none' | P@10041444 |
| 0x2d4 | pix16 | `stateParticlesColor_COLOR` | 0 | P@1004145c |
| 0x2d6 | bool8 | `stateParticlesRepeat_BOOL` | FALSE | P@10041474 |
| 0x2d7 | bool8 | — no key | FALSE | byte copy FUN_1003de30 +0x7 |
| 0x2d8 | int32 | `stateParticles_RepeatDelay_INT` | 0 | P@1004148c |
| 0x2dc | int32 | `stateParticles_MaxNumBursts_INT` | 0 | P@100414a4 |
| 0x2e0 | OSType | `collision_Spawn_ID` | 'none' | P@10041028 |
| 0x2e4 | bool8 | `collision_RepeatSpawns_BOOL` | FALSE | P@10041040 |
| 0x2e5 | bool8 | — no key | FALSE | byte copy FUN_1003de00 +0x5 |
| 0x2e6 | pad[2] | — | 0 | not copied |
| 0x2e8 | int32 | `collision_SpawnDelay_INT` | 0 | P@10041058 |
| 0x2ec | bool8 | `state_MotionBlur_Required_BOOL` | FALSE | P@100413b4 |
| 0x2ed | bool8 | `state_MotionBlur_AllowGlowDrawing_BOOL` | FALSE | P@100413cc |
| 0x2ee | pad[2] | — | 0 | not copied |
| 0x2f0 | int32 | `state_MotionBlur_MinTimeBetweenBlurs_INT` | 0 | P@100413e4 |
| 0x2f4 | int32 | `state_MotionBlur_MaxTimeBetweenBlurs_INT` | 0 | P@100413fc |
| 0x2f8 | float | `state_MotionBlur_InitialVisibilityPercent_FLOAT` | 0 | P@10041414 |
| 0x2fc | float | `state_MotionBlur_VisibilityDeltaPercent_FLOAT` | 0 | P@1004142c |
| 0x300–0x303 | bool8 ×4 | 300 `stateDoAnimateBackwards_BOOL` · 301 `stateDoLoopAnimation_BOOL` · 302 `stateContinuousFrameRandomisation_BOOL` · 303 `stateDoRotateToTarget_BOOL` | FALSE | P@10040c8c P@10040ca4 P@10040cbc P@10040cd4 |
| 0x304 | OSType | `stateSpriteFace_ID` | 'none' | P@10040ae8 |
| 0x308 | int32 | `stateNumDirections_INT` | 0 | P@10040c2c |
| 0x30c | int32 | `stateSpriteFrameMin_INT` | 0 | P@10040b10 |
| 0x310 | int32 | `stateSpriteFrameMax_INT` | 0 | P@10040b28 |
| 0x314 | int32 | `stateFramesPerDirection_INT` | 0 | P@10040c44 |
| 0x318 | int32 | `stateFrameDelay_INT` | 0 | P@10040c5c |
| 0x31c | int32 | `stateFrameDelta_INT` | 0 | P@10040c74 |
| 0x320 | OSType | `stateFlee_ID` | 'none' | P@10040d4c |
| 0x324–0x32a | bool8 ×7 | 324 `stateUseParentDirection_BOOL` · 325 `invulnerableUntilAllChildrenDestroyed_BOOL` · 326 `invulnerableUntilOwnerDestroyed_BOOL` · 327 `useOwnersVisibility_BOOL` · 328 `useOwnersScale_BOOL` · 329 `canBeDestroyedOnOwnerDestruction_BOOL` · 32a `canBeDeletedOnOwnerDeletion_BOOL` | FALSE | P@10040b40 P@10040e9c P@10040ec8 P@10040ef4 P@10040f20 P@10040f4c P@10040f78 |
| 0x32b–0x330 | bool8 ×6 | 32b `passHitsToOwner_BOOL` · 32c `visuallyReflectOwnerHits_BOOL` · 32d `destroyOwnerOnDestruction_BOOL` · 32e `stateLockToOwnerLoc_BOOL` · 32f `stateLinkToOwnerLoc_BOOL` · 330 `stateOrbitOwner_BOOL` | FALSE | P@10040fa4 P@10040fd0 P@10040ffc P@100415ac P@100415d8 P@10041604 |
| 0x331 | bool8 | — no key | FALSE | byte copy FUN_1003dce0 +0xd |
| 0x332 | pix16 | `stateTintColor_COLOR` | 0 | P@10040bfc |
| 0x334 | byte[0x12] | — no key (0x334–0x345) | 0 | copied as words + halfwords 0x342/0x344 (C) |
| 0x346–0x34c | bool8 ×7 | 346 `statePauseVerticalScrolling_BOOL` · 347 `stateCollides_BOOL` · 348 `stateInvulnerable_ShieldsDoNotDepleteOnCollision_BOOL` · 349 `stateHunts_BOOL` · 34a `stateCyclicMotion_BOOL` · 34b `stateReverseDirectionOnReaction_BOOL` · 34c `stateHoldPositionToTarget_BOOL` | FALSE | P@100414bc P@100414d4 P@100414ec P@1004151c P@10041534 P@10041564 P@1004154c |
| 0x34d–0x353 | bool8 ×7 | 34d `stateDoColorise_BOOL` · 34e `stateIsTargetable_BOOL` · 34f `stateCollidesWithPlayers_BOOL` · 350 `stateDeleteOnNoActivePlayers_BOOL` · 351 `stateDestructOnNoActivePlayers_BOOL` · 352 `stateDestructIfVerticalScrollingNotPaused_BOOL` · 353 `stateDrawToTerrain_BOOL` | FALSE | P@10040c14 P@1004157c P@10041594 P@10041630 P@10041648 P@10041660 P@10041678 |
| 0x354–0x357 | bool8 ×4 | 354 `stateDoNotGlowOnCollision_BOOL` · 355 `stateUseThisStateOnWeaponPowerupRelease_BOOL` · 356 `stateUseThisStateOnShieldDepletion_BOOL` · 357 `statePickup_DoNotChangeAppearanceOnStateChange_BOOL` | FALSE | P@10041690 P@100416c0 P@100416a8 P@10041504 |
| 0x358 | byte[0x52] | — no key (0x358–0x3a9) | 0 | block copy (C) |
| 0x3aa | pad[2] | — | 0 | not copied |
| 0x3ac | int32 | `stateOnTimerMin_INT` | 0 | P@100409f8 |
| 0x3b0 | int32 | `stateOnTimerMax_INT` | 0 | P@10040a10 |
| 0x3b4 | int32 | `stateOnCounter_INT` | 0 | P@10040ab4 |
| 0x3b8 | int32 | `stateOnHitChangeStateDelay_INT` | 0 | P@100409e0 |
| 0x3bc | int32 | `stateRequiredScalePercent_INT` | 100 | P@10040b9c |
| 0x3c0 | int32 | `stateScaleDeltaPercent_INT` | 0 | P@10040bb4 |
| 0x3c4 | int32 | `stateRequiredVisibilityPercent_INT` | 100 | P@10040b6c |
| 0x3c8 | int32 | `stateVisibilityDeltaPercent_INT` | 0 | P@10040b84 |
| 0x3cc | int32 | `stateTintPercent_INT` | 0 | P@10040bcc |
| 0x3d0 | int32 | `stateTintDeltaPercent_INT` | 0 | P@10040be4 |
| 0x3d4 | byte[0x78] | — no key (0x3d4–0x44b) | 0 | block copy (C) |
| 0x44c | float | `stateOnRange_FLOAT` | 0 | P@10040990 |
| 0x450 | float | `stateHoldMaxSpeed_FLOAT` | 0 | P@10040d1c |
| 0x454 | float | `stateHoldDelta_FLOAT` | 0 | P@10040d34 |
| 0x458 | float | `stateMaxSpeed_FLOAT` | 0 | P@10040cec |
| 0x45c | float | `stateDelta_FLOAT` | 0 | P@10040d04 |
| 0x460 | float | `stateFleeSpeed_FLOAT` | 0 | P@10040d64 |
| 0x464 | float | `stateFleeDelta_FLOAT` | 0 | P@10040d7c |
| 0x468 | byte[0x34] | — no key (0x468–0x49b) | 0 | block copy (C) |
| 0x49c | char[0x40] | `stateName_STR` | "" (state 0: "State 1", D@1003e390–1003e39c) | P@10040978 |
| 0x4dc | char[0x40] | `stateOnTimerChangeTo_STR` | "" | P@10040a40 |
| 0x51c | char[0x40] | `stateOnCounterChangeTo_STR` | "" | P@10040ad0 |
| 0x55c | char[0x40] | `stateOnRangeChangeTo_STR` | "" | P@100409ac |
| 0x59c | char[0x40] | `stateOnHitChangeTo_STR` | "" | P@100409c8 |
| 0x5dc | ptr | — spawn-set list (0xc-byte list header, §6) | NULL | FUN_10040920 `stw …,0x5dc` ; freed by FUN_1003f410 |

Sub-block boundaries (C): sound 0x000–0x023 · rules 0x024–0x2cf · particles 0x2d0–0x2df ·
collision 0x2e0–0x2eb · motion blur 0x2ec–0x2ff · animation 0x300–0x31f · flee ID 0x320 · owner
bools 0x324–0x331 · coalesced POD runs 0x332–0x3a9, 0x3ac–0x44b, 0x44c–0x49b · five 0x40 strings
0x49c–0x5db · list pointer 0x5dc. [HIGH]

## 5. Rule struct (sizeof 0x88; rule r at state + 0x28 + r·0x88, r = 0..4; block = state+0x24)

| off (rule-rel.) | state-rel. (r=0) | type | key | default | evidence |
|---|---|---|---|---|---|
| — | 0x024 | int32 | active count = rules read whose unit ≠ `'none'` | 0 | `10041788 lwz r3,0x28(r28) · subis · cmplwi 0x6e65 · beq` / `stw r0,0x24(r30)`; D `1003f4cc stw r0,0x0(r3)` |
| 0x00 | 0x028 | OSType | `stateRuleUnit_ID` | `'none'` | P@10041730; D `stw r4,0x4(r3)` (r3 = state+0x24) |
| 0x04 | 0x02c | char[0x40] | `stateRuleCondition_STR` (one of the 17 strings, waves-and-enemies.md §3) | "" | P@10041764; D `stb r0,0x8(r3)` |
| 0x44 | 0x06c | char[0x40] | `stateRuleAction_STR` (target state name) | "" | P@10041780; D `stb r0,0x48(r3)` |
| 0x84 | 0x0ac | int32 | `stateRuleRange_INT` | 0 | P@10041748 (INT reader); D `stw r0,0x88(r3)` |
| — | stack | char[0x40] | `stateRuleName_STR` — read into `r1+0x40` and discarded | — | P@10041714 |

File order per rule: Name, Unit, Range, Condition, Action. Block size 4 + 5·0x88 = 0x2ac
(`FUN_1003de70` loop bound `addi r0,r3,0x2ac`); the array is fixed at 5 and every consumer scans 5
(`FUN_1003ec70`, `FUN_10015550`); the parser does not cap (§2.5). [HIGH]

## 6. Spawn-set record (sizeof 0x5c) and list

`state+0x5dc` → a 0xc-byte list object (`FUN_1004d320(0xc)` + `FUN_10000890` init), one node per
spawn set, each a separate 0x5c allocation (`FUN_1004d320(0x5c)`), appended in file order
(`FUN_100009e0`), defaults `FUN_1003e490` then the keys. Count = `stateNumSpawnSets_INT`; no list
when 0 (`+0x5dc = 0`). Offsets record-relative.

| off | type | key | default | evidence |
|---|---|---|---|---|
| 0x000 | char[0x20] | `stateSpawnSetName_STR` | "" | P@1004116c |
| 0x020 | OSType | `stateSpawnSetSpawn_ID` | 'none' | P@10041184 |
| 0x024 | int32 | `stateSpawnSetXOffset_INT` | 0 | P@100411dc |
| 0x028 | int32 | `stateSpawnSetYOffset_INT` | 0 | P@100411f4 |
| 0x02c | int32 | `stateSpawnSetRateMin_INT` | 0 | P@1004123c |
| 0x030 | int32 | `stateSpawnSetRateMax_INT` | 0 | P@10041254 |
| 0x034 | int32 | `stateSpawnSetNumInVolleyMin_INT` | 1 | P@1004126c |
| 0x038 | int32 | `stateSpawnSetNumInVolleyMax_INT` | 1 | P@10041284 |
| 0x03c | int32 | `stateSpawnSetDelayBetweenEntitiesMin_INT` | 0 | P@1004129c |
| 0x040 | int32 | `stateSpawnSetDelayBetweenEntitiesMax_INT` | 0 | P@100412b4 |
| 0x044 | bool8 | `stateSpawnSetAdjustOffsetForUnitRotation_BOOL` | FALSE | P@1004120c |
| 0x045 | bool8 | `stateSpawnSet_AbsoluteCoordinates_BOOL` | FALSE | P@10041224 |
| 0x046 | bool8 | `stateSpawnSetRepeatSpawns_BOOL` | FALSE | P@100412cc |
| 0x047 | bool8 | `stateSpawnSetDon'tSpawnOffscreen_BOOL` | FALSE | P@100412e4 |
| 0x048 | bool8 | `stateSpawnSetPauseAnyRotationWhileSpawning_BOOL` | FALSE | P@100412fc |
| 0x04c | int32 | `stateSpawnSetTimeToPauseRotationAfterSpawning_INT` | 0 | P@10041314 |
| 0x050 | bool8 | `stateSpawnSetSpawnIfFleeing_BOOL` | FALSE | P@1004132c |
| 0x051 | bool8 | `stateSpawnSetSetHeading_BOOL` | FALSE | P@10041374 |
| 0x054 | int32 | `stateSpawnSetHeadingDegrees_INT` | 0 | P@1004138c |
| 0x058 | bool8 | `stateSpawnSet_StationaryOption_BOOL` | FALSE | P@10041344 |
| 0x059 | bool8 | `stateSpawnSet_TerrainEffectsOption_BOOL` | FALSE | P@1004135c |

Padding (not stored by defaults nor readers): 0x49–0x4b, 0x52–0x53, 0x5a–0x5b. X/YOffset defaults
come from the 8-byte constant at `0x100d72d0` = (0, 0) (`lwz r7,-0x6e54(r2)` → slot `0x100df4dc`;
`python3` over `$W/mem/100de330.bin`). X/YOffset and HeadingDegrees are **INT**. [HIGH]

## 7. Sizes and maxima

| item | value | evidence |
|---|---|---|
| sizeof unit def | 0x7a60 (31328) | `FUN_1004d320(0x7a60)` in `FUN_1003fc50`; memset `li r4,0x7a60` @1003e22c; cache header word 2 |
| sizeof fileData | 0x7a54 (unit+0xc …) | `FUN_1003d650` end `addi r28,r29,0x7a54` |
| sizeof state | 0x5e0 (1504) | stride everywhere; memset `li r4,0x5e0` @1003e400 |
| sizeof rule | 0x88 (136); rule block 0x2ac | `FUN_1003de70` |
| sizeof spawn set | 0x5c (92) | allocations; cache header word 3 |
| sizeof sound record | 0x18 (ID, minVol, maxVol, priority: int; minPitch, maxPitch: float) | `FUN_1003e1a0` |
| sizeof family record | 0x4c (name[0x40] + list@0x40) | `FUN_1003f4e0` |
| sizeof plde | 0x108 (264) | `FUN_1004d320(0x108)` in `FUN_10039cf0` |
| max states | 20 (`kG_UnitDef_MaxNumStates`); 0 accepted | assert text; `cmpwi …,0x14` loops in `FUN_1003e1e0`, `FUN_1003f360`, `FUN_100420f0` |
| rules per state | exactly 5 slots | §5 |
| spawn sets per state | unbounded (list) | §6 |
| live entities | < 1001 (consumer side) | waves-and-enemies.md §4 |

[HIGH]

## 8. Units Cache (` Data:Units Cache`, type `Data`, creator `Deim`)

A pure load-time accelerator: an exact memory image of the parsed master list. [HIGH unless noted]
- **Writer `FUN_10041e40`** (from `FUN_1003d030` at shutdown, only when `DAT_100e024c ≠ 0`, i.e. the
  reader failed this run): probes writability by `fopen(" Data:Unit Temp","w+")` (`FUN_10048560`,
  `FUN_10050390`, mode string `0x100ef97e` = "w+"); failure → log (copy-pasted text) "Sprite Groups
  Cache not loaded. (Cannot write to this volume, skipping.)" and flag cleared. Then
  `size = 0x10 + Σunits(0x7a60 + numStates·4 + Σstates count·0x5c)`, buffer `FUN_1000cb60(size,0)`:
  ```
  int32 version = 10000 · int32 unitCount · int32 0x7a60 · int32 0x5c        (header, 0x10)
  per unit:  0x7a60 bytes  = words 0..2 (magic, ID, layer) + FUN_1003d650(fileData)   (memory image,
             incl. the stale list pointers at state+0x5dc)
             per state s < numStates:  int32 count · count × 0x5c spawn-set records
  ```
  written by `FUN_100426e0(buf,size,1)`: path `FUN_10048560(" Data", _DAT_100e0248 → "Units Cache")`,
  create with `FUN_10001200(…,0x17,'Data','Deim')`, reopen, `FUN_10001430` write, log "Data Saved:".
- **Reader `FUN_100420f0`** (from `FUN_1003cf10`): frees and recreates the master and family lists;
  gated by `FUN_100461b0()` (= running Mac OS X, loose-ends-session.md §8.3 — ⚑ corrected (wave 3+4, 2026-10-04): was "not read");
  finds the file (`FUN_10044ce0` = FSMakeFSSpec on `": Data:Units Cache"`; file-pict-alerts-manager.md §3) and its modification date
  (`FUN_10044f00`); enumerates ` Data:Local:unde` (`FUN_10048610`) for the newest local file date;
  **cache older than any local `unde` file ⇒ ignored** ("ignoring cache as Unit Defs data is more
  recent"). Pak dates are not compared [MED — only this folder is enumerated]. Opens (`FUN_10001200`
  mode 0x11), reads the whole file, validates `version == 10000` ("old version"), `count ≥ 1`,
  `word2 == 0x7a60`, `word3 == 0x5c`; then per unit copies 0x7a60 bytes into a fresh allocation
  (loop count 0xf4c pairs = 0x7a60), rebuilds each state's list from the counts, appends to the
  master list and the family list. No numStates bounds check and no sprite validation on this path.
  Any failure sets `DAT_100e024c = 1` (rebuild at shutdown) and returns 0 → `FUN_1003d0a0(1)`.
- No `Units Cache` file ships in the game folder (`ls "$G/ Data"`: HID.bundle, Icon, Local, Paks).
  A replica can ignore the cache entirely; its only behavioural trace is load speed.

## 9. Player definitions (`plde`, G_PlayerDefinitions.cc) — closes INDEX NOT-RESOLVED #7

Chain: `FUN_100391f0` (init "Player Definition") → `FUN_10039280(1) @ 10039280` (list
`_DAT_100e0234`; progress text from `stli 'inte'` lines 14/15) → for i = 0.. `FUN_10039cf0(i) @ 10039cf0`:
`FUN_10002be0(i,'plde')`, decode, alloc **0x108**, memset, defaults, strict mode
(`FUN_1002c4d0`), `FUN_10039e70(id, buf, rec) @ 10039e70`, token error ⇒ fatal
"A Player Definition file contained incorrect or missing data." (`FUN_10001040(…,1)`). The parser
also, after each of the four sprite IDs, checks the sprite exists (`FUN_1001fbe0`; missing → log +
`'none'`) and loads it at once (`FUN_1001f950(1,id,1)`, failure → `FUN_10000f30` assert). [HIGH]

`key_offsets.py` now does match this parser (the review-#12 regex fix); the table below is from
the raw listing (`r30` = record, `10039e80 or r30,r5,r5`) and agrees with the tool row-for-row.
Defaults: `FUN_10039cf0` stores `10039d8c–10039dec` (11 IDs `'none'` + sound record from
`0x100d7250` = `'none'`,100,100,100,1.0,1.0 via slot `0x100df48c`); everything else 0. [HIGH]

| off | type | key / meaning | default | evidence |
|---|---|---|---|---|
| 0x000 | uint32 | — magic | 0x499602d2 | D@10039d8c; checked by FUN_10039c00 before free |
| 0x004 | OSType | — plde tag ID | — | parser `stw r3,0x4(r5)` @10039ea0; matched by FUN_10039460 `+4` |
| 0x008 | char[0x20] | `name_STR` | "" | P@10039ee8 |
| 0x028 | OSType | `spriteHighScore_ID` | 'none' | P@10039f00 |
| 0x02c | int32 | `spriteHighScoreFrame_INT` | 0 | P@10039fe4 |
| 0x030 | OSType | `spriteScoreBar_ID` | 'none' | P@10039ffc |
| 0x034 | int32 | `spriteScoreBarFrame_INT` | 0 | P@1003a0e0 |
| 0x038 | OSType | `spriteScoreBarShield_ID` | 'none' | P@1003a1f4 |
| 0x03c | int32 | `spriteScoreBarShieldFrame_INT` | 0 | P@1003a2d8 |
| 0x040 | OSType | `spriteScoreBarPower_ID` | 'none' | P@1003a0f8 |
| 0x044 | int32 | `spriteScoreBarPowerFrame_INT` | 0 | P@1003a1dc |
| 0x048 | int32 | `defaultShieldPercentage_INT` | 0 | P@1003a2f0 |
| 0x04c | int32 | `shieldWarningPercentage_INT` | 0 | P@1003a308 |
| 0x050 | int32 | `shieldBaseHitPercentage_INT` | 0 | P@1003a320 |
| 0x054 | int32 | `shieldHitDelay_INT` | 0 | P@1003a338 |
| 0x058 | pix16 | `hitGlowColor_COLOR` | 0 | P@1003a350 |
| 0x05c | int32 | `hitGlowSpeed_INT` | 0 | P@1003a368 |
| 0x060 | int32 | `life_MaxNum_INT` | 0 | P@1003a380 |
| 0x064 | int32 | `life_NumInitial_INT` | 0 | P@1003a398 |
| 0x068 | int32 | `life_InitialRequiredScore_INT` | 0 | P@1003a3b0 |
| 0x06c | int32 | `life_AdditionalRequiredScore_INT` | 0 | P@1003a3c8 |
| 0x070 | OSType | `life_Spawn_ID` | 'none' | P@1003a3e0 |
| 0x074 | int32 | `waitingTime_INT` | 0 | P@1003a3f8 |
| 0x078 | int32 | `filmIntroTime_INT` | 0 | P@1003a410 |
| 0x07c | int32 | `introTime_INT` | 0 | P@1003a428 |
| 0x080 | int32 | `gameOverTime_INT` | 0 | P@1003a440 |
| 0x084 | int32 | `dyingTime_INT` | 0 | P@1003a458 |
| 0x088 | int32 | `finalDyingTime_INT` | 0 | P@1003a470 |
| 0x08c | int32 | `entry_InvulnerabilityTime_INT` | 0 | P@1003a590 |
| 0x090 | int32 | `entry_soloStartX_INT` | 0 | P@1003a488 |
| 0x094 | int32 | `entry_soloStartY_INT` | 0 | P@1003a4a0 |
| 0x098 | int32 | `entry_multiStartX_INT` | 0 | P@1003a4b8 |
| 0x09c | int32 | `entry_multiStartY_INT` | 0 | P@1003a4d0 |
| 0x0a0 | OSType | `entry_Spawn_ID` | 'none' | P@1003a4e8 |
| 0x0a4 | float | `entry_StartVelocityX_FLOAT` | 0 | P@1003a500 |
| 0x0a8 | float | `entry_StartVelocityY_FLOAT` | 0 | P@1003a518 |
| 0x0ac | float | `entry_TargetVelocityX_FLOAT` | 0 | P@1003a530 |
| 0x0b0 | float | `entry_TargetVelocityY_FLOAT` | 0 | P@1003a548 |
| 0x0b4 | float | `entry_VelocityDelta_FLOAT` | 0 | P@1003a560 |
| 0x0b8 | int32 | `entry_InitialDelay_INT` | 0 | P@1003a578 |
| 0x0bc | OSType | `death_Spawn_ID` | 'none' | P@1003a5a8 |
| 0x0c0 | int32 | `death_Duration_INT` | 0 | P@1003a5c0 |
| 0x0c4 | OSType | `active_MoneyCounterSpawn_ID` | 'none' | P@1003a5d8 |
| 0x0c8 | OSType | `active_SpawnOnHit_ID` | 'none' | P@1003a5f0 |
| 0x0cc | OSType | `active_ShieldWarningObject_ID` | 'none' | P@1003a608 |
| 0x0d0 | OSType | `active_DefenceBonusObject_ID` | 'none' | P@1003a620 |
| 0x0d4 | float | `active_DefaultMaxSpeed_FLOAT` | 0 | P@1003a638 |
| 0x0d8 | float | `active_VelocityDelta_FLOAT` | 0 | P@1003a650 |
| 0x0dc | int32 | `powerupOverload_NumWarnings_INT` | 0 | P@1003a668 |
| 0x0e0 | int32 | `powerupOverload_InitialTimeBetweenWarnings_INT` | 0 | P@1003a680 |
| 0x0e4 | int32 | `powerupOverload_MinimumTimeBetweenWarnings_INT` | 0 | P@1003a698 |
| 0x0e8 | float | `powerupOverload_WarningFadePercent_FLOAT` | 0 | P@1003a6b0 |
| 0x0ec | pix16 | `powerupOverload_Hilite_COLOR` | 0 | P@1003a6c8 |
| 0x0f0 | sound rec 0x18 | `powerupOverloadSound_ID` +0 · `…_MinVolume_INT` +4 · `…_MaxVolume_INT` +8 · `…_Priority_INT` +0xc · `…_MinPitch_FLOAT` +0x10 · `…_MaxPitch_FLOAT` +0x14 | 'none', 100, 100, 100, 1.0, 1.0 | P@1003a6e0 … P@1003a758 |

Offsets 0x000–0x107 are fully covered (no gaps, no unknown fields). Values in the shipped files
such as `#defaultShieldPercentage_INT <100.000000>` are read with `%i` → 100 (sscanf stops at the
`.`). File order differs from offset order at 0x8c (`entry_InvulnerabilityTime` read last of the
entry group) and the score-bar sprites (Power 0x40 read before Shield 0x38). [HIGH]

Other `G_PlayerDefinitions` functions:

| function | role | label | evidence |
|---|---|---|---|
| `FUN_10039460 @ 10039460` | index of the plde with tag ID (−1 if none / `'none'`) | MED | dump `*(int *)(local_14 + 4) != param_1`; callers `FUN_100222f0 FUN_10026410` — ⚑ label audit (review wave 1) |
| `FUN_10039520 @ 10039520` | i-th plde record | MED | dump; callers `FUN_100222f0 FUN_10026410 FUN_100395d0 FUN_10039a80` |
| `FUN_100396c0 @ 100396c0` | list of unit IDs a plde references (0xa0 entry, 0x70 life, 0xbc death, 0xc4 money counter, 0xc8 spawn-on-hit, 0xcc shield warning, 0xd0 defence bonus) | MED | dump offsets = table — ⚑ label audit (review wave 1) |
| `FUN_100395d0 @ 100395d0` | is unit ID referenced by any plde (pairs with `FUN_1003ef90`) | MED | dump; no direct caller |
| `FUN_10039940 @ 10039940` | free an ID list | MED | dump |
| `FUN_100399a0 @ 100399a0` | load a plde's resources: sprites 0x28/0x30/0x38/0x40, sound 0xf0 (`FUN_1001f950(0/1,id,1)`), then `FUN_1003e580` for the 7 unit IDs | MED | dump; caller `FUN_10026410` — ⚑ label audit (review wave 1) |
| `FUN_10039a80 @ 10039a80` | collect plde sprite IDs (mode 1) or the overload sound (mode 0) into a list | MED | dump; no direct caller (pairs with `FUN_1003f0b0`) |
| `FUN_10039c00 @ 10039c00` | free the plde list (only records with magic 0x499602d2) | MED | dump; callers `FUN_10039230` (shutdown), `FUN_10039280` — ⚑ label audit (review wave 1) |
| `FUN_1003a780 @ 1003a780` | U_Manager init ("Manager God", list `_DAT_100e023c`) — next module, not plde | MED | strings `U_Manager.cc`; caller `FUN_100000e0` |

## 10. Reconciliation with waves-and-enemies.md §2/§5 and function-roles.md

- Every unit, state and spawn-set offset in waves-and-enemies.md §2 is confirmed by the listing;
  **no `⚑ conflict`**. Additions: field types and sizes (STR lengths 0x40/0x40/0x80/0x20/0x100 unit,
  0x40 state, 0x20 spawn-set name), defaults, the derived fields (unit +0x08 layer, +0x0c version,
  +0x10 error, +0x11 owner flag, state +0x24 count), padding and the no-key regions.
- §8 item 9 ("rules loop reads `#stateNumRules_INT` but the evaluator scans exactly 5") — sharpened:
  the parser has no cap; > 5 rules overruns into state+0x2d0 (§2.5). [HIGH]
- §2 "valid 1..20 else 'incorrect number of states' + assert" — ⚑ corrected: 0 is accepted
  silently (log and assert fire only for < 0 or > 20), and the parse of > 20 states has already
  overrun the allocation before the check. [HIGH]
- §5 "parser `FUN_10039e70`'s offsets NOT RESOLVED" → §9 here.
- function-roles row `FUN_1003d650` "unit-definition struct copy (field-by-field assignment)" —
  refined: copy-assignment of the `fileData` sub-struct (unit+0xc, 0x7a54 bytes) used only by the
  cache writer; it is not on any gameplay path. The review's handoff label for `FUN_100420f0`
  ("Units Cache writer") is wrong — it is the reader; the writer is `FUN_10041e40`.
- data-tags.md §1 "Whether loaders abort on the flag" → for `unde`/`plde`: yes, fatal (§2.2).

## Worked example — `Level 3 - Pause 1` (`03p1`) parsed into the struct by hand

Source `$W/data/Game/unde/Level 3 - Pause 1[03p1].unde.txt` (755 lines, decoded). U = unit pointer.

| field (key) | address | value after load | from |
|---|---|---|---|
| magic | U+0x000 | 0x499602d2 | default |
| unit ID | U+0x004 | `'03p1'` | `FUN_1003fda0` arg |
| layer | U+0x008 | `'grnd'` | fix-up: `isGroundBased_BOOL <TRUE>` (U+0x125 = 1) |
| version | U+0x00c | 10000 | default |
| error / owner flags | U+0x010 / U+0x011 | 0 / 0 | no token error; no owner bool TRUE in any state |
| `numStates_INT` | U+0x014 | 5 | file |
| `name_STR` / `familyName_STR` | U+0x018 / U+0x058 | "Level 3 - Pause 1" / "Level" | file (17 / 5 chars ≤ 63) |
| `description_STR` | U+0x098 | 80-char text | file (≤ 127, not truncated) |
| `harmlessToPlayers_BOOL` | U+0x11a | 1 | file |
| `numInGroupMin/Max`, `appearsPercent` | U+0x194/0x198/0x1c0 | 1 / 1 / 100 | file (equal to the defaults) |
| `initialScalePercent`, `initialVisibilityPercent` | U+0x1ac / U+0x1b4 | **0 / 0** | file overrides the default 100 |
| `editorPreviewSpriteFace_ID` / `…Frame_INT` | U+0x2d4 / U+0x1bc | `'edpr'` / 26 | file |
| `drawLayer_ID` | U+0x2e0 | `'defa'` | file |
| 4 sound records' Priority | U+0x430/0x454/0x46c/0x4c8 | **50** | file overrides the default 100 |
| reserved IDs | U+0x2e8…U+0x320 | 15 × `'none'` | default (no key) |
| shields base/inc/max | U+0x43c/0x440/0x444 | 0 / 0 / 0 | file (clamp no-op) |

State table (state s at U + 0x4e0 + s·0x5e0):

| s | base | `stateName_STR` (+0x49c) | timer min/max (+0x3ac/+0x3b0) → target (+0x4dc) | pause (+0x346) | spawn sets (+0x5dc list) |
|---|---|---|---|---|---|
| 0 | U+0x4e0 | "Wait Until Pausing" (replaces default "State 1" at U+0x97c) | 180/180 → "Pause Scrolling, Spawn Buzzsaws" | 0 | none (U+0xabc = NULL) |
| 1 | U+0xac0 | "Pause Scrolling, Spawn Buzzsaws" | 400/400 → "Wait before Pausing Tank" | 1 (U+0xe06) | 1: `bu02` |
| 2 | U+0x10a0 | "Wait before Pausing Tank" | 140/150 → "Pause Tank" | 1 | none |
| 3 | U+0x1680 | "Pause Tank" | 170/180 → "Spawn Buzzsaws Again" | 1 | 1: `tala` at (480, 101), rate 0/0 |
| 4 | U+0x1c60 | "Spawn Buzzsaws Again" | 500/500 → "Delete" | 1 | 1: `bu02` |
| 5–19 | U+0x2240 … U+0x7480 | "" | 0/0 | 0 | none — **entire state = defaults** (MaxNumToPlay 1, IDs `'none'`, RequiredScale/Visibility 100, 5 inert rules) |

State 1's spawn-set record R (node of the list at U+0x109c): R+0x00 "Buzzsaw Groups - Top of Screen"
(30 chars — the longest spawn-set name shipped; buffer allows 31), R+0x20 `'bu02'`, R+0x24 208,
R+0x28 −100 (0xffffff9c), R+0x2c/0x30 rate 90/100, R+0x34/0x38 volley 1/1, R+0x3c/0x40 delay 0/0,
R+0x45 AbsoluteCoordinates 1, R+0x46 RepeatSpawns 1, rest 0. Every state's 5 rules have unit
`'none'` (state 0: condition "Is Tracking Player", action "Delete"; states 1–4: both empty) ⇒
active count +0x24 = 0 ⇒ the rule evaluator is never entered for this unit. No timer is zeroed
(every non-zero timer has a target).

**Which keyed fields fell to defaults: none.** A simulation of the forward-cursor parse
(`sim.py`, scratchpad; key order = the listing order of §3–§6) over all 386 decoded `unde` files
reports **0 files with a missing key, 0 keys matched outside their own state block**; a `grep`
census finds no empty value for any non-string key and no ID that is not 4 characters; no string
exceeds its buffer (longest: name 31, description 111, state name 43, spawn-set name 30;
`destructNotice_STR` and `entryNotice_STR` are empty in every file). Both `plde` files likewise
contain all 57 keys. So in shipped data the code defaults only show up in the no-key fields (header
magic/version, reserved `'none'` IDs, zeroed unknown regions) and in the unused states
`numStates..19`. [HIGH — tool output]

## NOT RESOLVED (this file)
1. Meaning of the no-key regions of the unit (0x135–0x179, 0x17a–0x17d, 0x180–0x191, 0x1c4–0x25b,
   0x278–0x2d3, byte 0x4b5, the 15 ID slots 0x2e8–0x320) and of the state (byte 0x1b, 0x2d7, 0x2e5,
   0x331, 0x334–0x345, 0x358–0x3a9, 0x3d4–0x44b, 0x468–0x49b). They are memset, copied and cached
   but never written by any parser or default. Settle: search the consumers (`FUN_10033850`,
   `FUN_10015930/5280/5b40`, `FUN_10036cf0`, `FUN_10035cd0`) for reads at those displacements from
   a unit/state base; if none, they are reserved space.
2. Consumer of `unit+0x11` ("has owner-linked state") and of `unit+0x0c` (10000). A `char`-pattern
   grep of the dump for `+ 0x11)` found only weapon-struct uses. Settle as in 1.
3. ~~`FUN_10000630` (shutdown sequence): whether it terminates the process after a fatal parse error
   (last callee `FUN_10048480` not read) — decides whether a malformed `unde` aborts the game.~~ → ⚑ corrected (review wave 3, 2026-10-06) #S: loose-ends-session.md §8.2: `FUN_10000630` ends in ExitToShell (`10000730 bl 0x10048480`) (critic wave 3 §3).
4. ~~`FUN_100461b0` — the gate in front of the cache reader (pref? volume writable?); and whether
   `DAT_100e024c` is initialised to 0 (static) so that a successful cache load never rewrites it.~~ → ⚑ corrected (review wave 3, 2026-10-06) #S: loose-ends-session.md §8.3: `FUN_100461b0` = "running Mac OS X" (`Gestalt('sysv')`) (critic wave 3 §3).
5. ~~`FUN_1003d550`'s first list: confirmed as a family member list only by shape (`param_2+0x40`,
   elements → unit pointers); its callers `FUN_10015550`/`FUN_10015b40` pass which family? (read
   the call sites).~~ → ⚑ corrected (review wave 3, 2026-10-06) #S: loose-ends-session.md §8.4 (raw call sites pass the entity's family) (critic wave 3 §3).
6. ~~`FUN_1003ef90`, `FUN_1003f0b0`, `FUN_100395d0`, `FUN_10039a80` have no direct caller; presumably
   reached through the debug-command table registered by `FUN_1003cf10` (`FUN_1002d080`). Not
   gameplay; not traced.~~ → ⚑ corrected (review wave 3, 2026-10-06) #S: reached from the no-function unit-def console handler at `0x10041b70` (registered by `FUN_1003cf10`; `10041c9c bl 0x1002b150`, `10041cb0 bl 0x100395d0`, `10041cc4 bl 0x1003ef90`; fix-pass listing) — debug-only; `FUN_1003f0b0`/`FUN_10039a80` are the LOGUNUSED collectors (sprite-manager-resource-image.md NR 3) (critic wave 3 §1, §3).

## Role-table rows (for merge)

| `FUN_1003cf10` | G_UnitDefinitions.cc | unit manager init: debug commands, Units Cache load or master-list build | HIGH | read §1; listing `1003cf34 bl 0x1003a870` ("Unit Definition"), `1003cf5c…1003cfdc` 4× `bl 0x1002d080` (handlers = undefined code `0x10041a40/b30/b70/d70` via TOC r2−0x6e3c/−0x6e40/−0x6e44/−0x6e48), `1003cfe4 bl 0x100420f0; bne` → else `1003d000 bl 0x1003d0a0(1)`; caller `FUN_100000e0` — ⚑ label audit (review wave 1): HIGH kept, listing added in the fix pass; this reading wins the bosses.md conflict ("console unit commands" LOW) |
| `FUN_1003d0a0` | G_UnitDefinitions.cc | build master unit list; numStates check passes 0..20 (log+assert only <0 or >20) | HIGH | listing 1003d1bc–1003d218 |
| `FUN_1003d2f0` | G_UnitDefinitions.cc | find unit definition by ID (unit+4) | HIGH | listing 1003d35c (was MED "usage") |
| `FUN_1003d3a0` | G_UnitDefinitions.cc | i-th unit of the master list | MED | read |
| `FUN_1003d450` | G_UnitDefinitions.cc | family record of a unit (" Misc" if no family name) | HIGH | read; `0x100ed01f` |
| `FUN_1003d550` | G_UnitDefinitions.cc | find unit by ID, family list first then global | MED | read |
| ⚑ corrected `FUN_1003d650` | G_UnitDefinitions.cc | compiler copy-assignment of unit `fileData` (unit+0xc, 0x7a54 B); only for the Units Cache writer (was "unit-definition struct copy (field-by-field assignment)") | HIGH | listing 1003d904–1003dcb8 |
| `FUN_1003dce0` `FUN_1003dd60` `FUN_1003ddc0` `FUN_1003de00` `FUN_1003de30` `FUN_1003de70` `FUN_1003dfb0` | G_UnitDefinitions.cc | copy state sub-blocks (+0x324 owner bools, +0x300 anim, +0x2ec blur, +0x2e0 collision, +0x2d0 particles, +0x024 rules, +0x000 sound) | HIGH | listing |
| `FUN_1003e020` `FUN_1003e040` `FUN_1003e120` `FUN_1003e1a0` | G_UnitDefinitions.cc | copy unit sub-blocks (pickup, destruct, shields+2 sounds, sound record) | HIGH | listing |
| `FUN_1003e1e0` | G_UnitDefinitions.cc | unit-definition defaults (incl. 20 states, state 0 "State 1") | HIGH | listing §3 |
| `FUN_1003e3d0` | G_UnitDefinitions.cc | state defaults | HIGH | listing §4 |
| `FUN_1003f470` | G_UnitDefinitions.cc | rule-block defaults (5 rules) | HIGH | listing §5 |
| `FUN_1003e490` | G_UnitDefinitions.cc | spawn-set defaults | HIGH | listing §6 |
| `FUN_1003e510` | G_UnitDefinitions.cc | reset loaded-unit-resources list | MED | string + callers — ⚑ label audit (review wave 1) |
| `FUN_1003e580` | G_UnitDefinitions.cc | load resources of unit ID | HIGH | listing |
| `FUN_1003e680` | G_UnitDefinitions.cc | load/verify a unit's sounds+sprites, recurse into referenced units | MED | read (was MED strings) — ⚑ label audit (review wave 1) |
| `FUN_1003ec70` | G_UnitDefinitions.cc | list unit IDs referenced by a unit | MED | read — ⚑ label audit (review wave 1) |
| `FUN_1003ef90` | G_UnitDefinitions.cc | is unit referenced by another unit (LOGUNUSEDUNITS) | MED | read |
| `FUN_1003f0b0` | G_UnitDefinitions.cc | collect all unit sprite/sound IDs into a list | MED | read |
| `FUN_1003f280` | G_UnitDefinitions.cc | master-list integrity check (magic 0x499602d2) | HIGH | listing |
| `FUN_1003f360` `FUN_1003f410` `FUN_1003f830` `FUN_1003fa10` `FUN_1003fa80` | G_UnitDefinitions.cc | free master list / ID list / family list / family / resource list | MED | read |
| `FUN_1003f4e0` | G_UnitDefinitions.cc | add unit to family list (0x4c family records) | MED | read (was MED strings) — ⚑ label audit (review wave 1) |
| `FUN_1003f8b0` | G_UnitDefinitions.cc | log family table | MED | strings |
| `FUN_1003fb60` | G_UnitDefinitions.cc | test-and-insert unit ID into loaded-resources list | MED | read — ⚑ label audit (review wave 1) |
| `FUN_1003fc50` | G_UnitDefinitions.cc | load unit i (alloc 0x7a60, defaults, parse, layer, error ⇒ fatal) | HIGH | listing (was MED strings) |
| `FUN_10041960` `FUN_100417d0` `FUN_100418a0` | G_UnitDefinitions.cc | sprite (parse time) / sound / sprite (load time) existence check, else `'none'` | MED | read — ⚑ label audit (review wave 1) |
| ⚑ corrected `FUN_10041e40` | G_UnitDefinitions.cc | Units Cache writer (format §8) | MED | read — ⚑ label audit (review wave 1) |
| ⚑ corrected `FUN_100420f0` | G_UnitDefinitions.cc | Units Cache reader/validator (handoff called it the writer) | MED | read — ⚑ label audit (review wave 1) |
| `FUN_10039280` | G_PlayerDefinitions.cc | build player-definition list | MED | read — ⚑ label audit (review wave 1) |
| `FUN_10039cf0` | G_PlayerDefinitions.cc | load plde i (0x108 record, defaults, parse) | HIGH | listing |
| `FUN_10039e70` | G_PlayerDefinitions.cc | parse plde (57 keys, table §9) | HIGH | listing |
| `FUN_10039460` `FUN_10039520` | G_PlayerDefinitions.cc | plde index by ID / i-th plde | MED / MED | read — ⚑ label audit (review wave 1) |
| `FUN_100396c0` `FUN_100399a0` | G_PlayerDefinitions.cc | plde referenced unit IDs / load plde resources | MED | read — ⚑ label audit (review wave 1) |
| `FUN_100395d0` `FUN_10039940` `FUN_10039a80` `FUN_10039c00` | G_PlayerDefinitions.cc | unit referenced by plde / free list / collect IDs / free plde list | MED | read |
| `FUN_1003a780` | U_Manager.cc | manager init ("Manager God") | MED | strings |

## INDEX updates (for merge)
- **#7 closed**: `plde` key→offset table (all 0x108 bytes) → this file §9.
- **#4 narrowed**: for `unde`/`plde`, a missing or malformed non-string key sets the flag in strict
  mode and the loader shows a fatal "Error" alert and runs the shutdown sequence; missing string
  keys are silent (§2.1–2.2). Remaining: whether `FUN_10000630` exits (NOT RESOLVED 3 here) and
  the behaviour of other loaders.
- waves-and-enemies.md §8 #9 sharpened (no parser cap on rules/states; 0 states accepted) → §2.5.
- New topical file row: `unit-def-struct.md` — unit/state/rule/spawn-set/plde struct maps with
  defaults, parse semantics, Units Cache format.
