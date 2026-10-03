# Deimos Rising 1.0.6 — text-tag grammar and the "permanent" lists (stli flli idli reli coli tefo)

Code readings only. Conventions as in pak-format.md. Decoded copies of every text entry are
produced by `python3 docs/deimos/tools/list_paks.py "$G/ Data/Paks" --decode <dir>` (writes
`<entry>.txt` = de-obfuscated, CR→LF). `$G` = the game folder (INDEX.md).

## 1. Token grammar (U_Token.cc, `0x1002c490…0x1002ce60`)

A text tag is a sequence of `#key <value>` items; whitespace/comments between items are ignored
because readers search for strings. Readers (all `FUN_xxx(buf, &cursor, keyString, dest, …)`):
| reader | value type | parse | evidence |
|---|---|---|---|
| `FUN_1002cb20` | STR | copy, max len given by caller | used for `#name_STR` etc. |
| `FUN_1002c7d0` | ID (4CC) | length between `<` `>` must be exactly 4 | "Invalid ID Length (must be 4 characters long)" |
| `FUN_1002c880` | INT | `sscanf(v, "%i")` (`0x100ea6d0`="%i"), max 31 chars | "Invalid Integer Length" |
| `FUN_1002c960` | FLOAT | `sscanf` float, max 31 chars | "Couldn't find KEY for a Float" |
| `FUN_1002ca40` | BOOL | `strcmp(v, "TRUE")==0` (`_DAT_100e01dc`→"TRUE"); anything else = false | read |
| `FUN_1002cbd0` | COLOR | `FUN_10010990` "HTML RGB" `RRGGBB` → 16-bit pixel | "ERROR: HTML RGB String (%s) in incorrect format." |
| `FUN_1002cc90` | RECT | `strtok(v, ",")` + `%i` ×4 | "Invalid length for a RECT." |

Core locator `FUN_1002c550 @ 1002c550`:
```c
  iVar1 = FUN_10057a30(param_1 + *param_3);           // strstr(buf + cursor, key)
  if (iVar1 != 0) {
    iVar1 = FUN_10057a30(iVar1,param_5);              // strstr(..., "<")  (0x100ea64c)
    ...
      iVar2 = FUN_10057a30(iVar1,param_6);            // strstr(..., ">")  (0x100ea64e)
      if (iVar2 != 0) {
        *param_4 = (iVar2 - iVar1) + -1;              // value length
        *param_3 = iVar2 - param_1;                   // cursor := position of '>'
```
Claims:
- The cursor only moves forward: each key is searched from the end of the previous value, so
  keys must appear in the file in the parser's call order; repeated blocks (unit states, spawn
  sets, rules, level objects) are parsed by calling the same readers again. [HIGH]
- A key that is missing is NOT skipped silently: the reader logs "FILE PARSING ERROR" via
  `FUN_1002ce60` (only when `DAT_100e01e0` logging is enabled) and sets `DAT_100e01e1` (error
  flag, read by `FUN_1002c540`). Whether loaders abort on the flag: loaders print "A Unit
  Definition file contained incorrect or missing data." (`FUN_1003fc50`) [MED].
- Because `strstr` is used, a key that is a prefix-substring of a later key can match early;
  the shipped files avoid this by ordering. [LOW — reasoning, not observed]

A second, order-independent style is used by `G_Text.cc` (`tefo`, `FUN_1000ef90`): the whole
buffer is re-copied before every key (`FUN_1000cd60(iVar4,param_1,iVar3)`) and searched with
`FUN_1002c630` (strstr from the start, then `strtok` "<" ">"). [HIGH]

## 2. `stli` — string lists (CR-separated lines, 0-based index)

Reader `FUN_10002e50(listID, index, dst, max) @ 10002e50`: loads tag (`stli`,listID), decodes,
counts `\r` to the requested line, copies up to the next `\r`. [HIGH]
Cross-check: `FUN_1001fe60` calls `FUN_10002e50('inte', 6, …)` while logging "Loading Permanent
Sprites"; line 6 of `Interface[inte].stli` is `Loading Permanent Image:  `. [HIGH]

`Game[pgsl].stli` is copied wholesale into a 37 × 128-byte table at TOC slot `0x100df204` by
`FUN_1001fe60` ("Loading Game Strings", loop `iVar6 < 0x25`), read by
`FUN_10020260(i) = base + i*0x80` (disassembly: `lwz r4,-0x712c(r2); rlwinm r0,r3,7,…; add`).
[HIGH] Lines (0-based) used by code (from `docs/deimos/tools/perm_consumers.py`):
| idx | text | consumer |
|---|---|---|
| 0 | `Press Caps Lock` | `FUN_10030360` (pause notice) |
| 9 | `REPLAY` | `FUN_100051a0` (film playback banner) |
| 11/14/15/16 | `Ground Accuracy:` / `Coin Bonus:` / `x` / `=` | end-of-level tallies `FUN_100075e0`, `FUN_10027930` |
| 17/18 | `Interlacing ON/OFF` | `FUN_10030910` (F6 key), `FUN_10030640` (auto) |
| 21/22/23 | `Sound Volume OFF` / `Sound Volume` / `%` | `FUN_10030910` (-/= keys) |
| 33/34/35 | registration banners | `FUN_10010e90` (out of scope) |
Other lists: `Interface[inte]` (1013 bytes, 27 CRs → 28 lines counting the unterminated last
line — ⚑ corrected (review 2026-10-03) #16: line count = CR count + 1 when the file does not end in CR; loading/progress/alerts), `Attributions[cred]` (credits,
`<title>`/`<page N>` markup read by G_Credits.cc), `Editor[edit]`, `Parse List[pali]` (2 bytes:
`1` + CR; read by `FUN_100015a0` beside the "incompatible with the game data" alert — a data
version check, value 1) [MED].

## 3. `flli` — the permanent float list (`flli/Game[gafl]`)

Loader `FUN_100204a0 @ 100204a0` ("Loading Permanent Floats"):
```c
  iVar3 = FUN_10002da0(0x666c6c69,0x6761666c);          // tag ('flli','gafl')
  ...  FUN_10046470(iVar5,iVar4);                        // de-obfuscate
  do {
    ...
    iVar8 = FUN_1002c700(iVar6,uVar7,0x100e83da,local_38,0x100e83dc,0x100e83de); // "#","<",">"
    if (iVar8 == 0) goto LAB_10020614;
    FUN_10057660(iVar8,0x100e83e0,iVar2 + iVar10);       // sscanf "%f" -> float[i]
    iVar9 = iVar9 + 1;  iVar10 = iVar10 + 4;
  } while (iVar9 < 0xdc);                                // exactly 220
  ...
  if (iVar9 != 0xdc) { FUN_10049550(s_DATA_ERROR__Permanent_Float_list_100e83e3); ...
```
Destination `iVar2 = _DAT_100df200` (TOC slot r2-0x7130). Accessor `FUN_10020250(i)`:
`lwz r4,-0x7130(r2); rlwinm r0,r3,2,…; lfsx f1,r4,r0` → returns float `i` in f1. r2 = data base
+ 0x8000 = `0x100e6330`, so r2-0x7130 = `0x100df200` — the same slot the loader fills. [HIGH]

So **float i = the i-th `#…<…>` item in file order** (keys are documentation only; the parser
never compares key names). The file has 220 items (`grep -c '^#'` → 220). The decompiler loses
the f1 return (shows `FUN_10020250(n); … (int)in_f1`), so every `FUN_10020250(N)` in the dump
reads flli item N. Full index: `grep -n '^#' "Game/flli/Game[gafl].flli.txt"` (line-1 = index).
Selected items (index: key value) used in the other files:
| idx | key | value | idx | key | value |
|---|---|---|---|---|---|
| 13 | Game_GameOverNoticeDuration | 110 | 54 | VisibleGameWidth | 416 |
| 14–17 | Game_EntityFlee N/S/W/E | -1000/2000/-1000/2000 | 55 | VisibleGameHeight | 480 |
| 18 | Game_NumFramesUntilGameAppears | 2 | 56 | ReqDisplayDepth | 16 |
| 32 | FPS_MaxRate | 30 | 57/58 | ScoreBarWidth/Height | 160/480 |
| 33 | FPS_Delay | 2 | 59 | LeftBorderWidth | 32 |
| 34 | FPS_DeficiencyLevel | 10 | 60 | RightBorderWidth | 32 |
| 37 | SoundSpoolBufferSize | 204800 | 144 | Particle_Gravity | 0.96 |
| 38 | SoundNumChannels | 8 | 151/152 | WepHandler_Default/MaxNumBombs | 1/8 |
| 48/49 | Shadow_X/YOffset | -48/104 | 161 | Player_ImpactDamageToEntities | 100 |
| 50/51 | Shadow_GroundX/YOffset | -6/8 | 182 | Player_ExtraLifeScoreAdjustment | 10000 |
| 52/53 | MinScreenWidth/Height | 640/480 | 183 | Player_TopGameAreaLimit | 13 |
| 66 | Interface_PublisherLogoDelay | 130 | 184 | Player_DefenceBonusBaseAmount | 2000 |
| 209–217 | Game_RandomBonusPercent_1..9 | 70 78 82 84 87 91 95 98 100 | 219 | Game_MinimumLevelForHighestRandomBonus | 3 |
Values: [HIGH — file bytes]; index→consumer mapping: [HIGH] for the accessor, per-consumer
meaning [MED] (consumer functions only partly read; see function-roles.md).

## 4. `idli` — ID lists (`#key <ID>` items, positional)

Reader `FUN_10003520(listID, index) @ 10003520`: walks `#`…`<`…`>` items (`0x100e384c/4e/50`),
returns the 4CC of item `index` (asserts `strlen(token)==sizeof(G_GameObject_ID)` = 4), `none`
if absent. Permanent tables filled by `FUN_1001fcf0` (decompiled loop counts):
| list (tag) | count | table slot / accessor | contents (file order) |
|---|---|---|---|
| `gasp` Sprites | 8 | `0x100df214` / `FUN_10020200(i)` | vigr edut pl1o mebu mebh galo mebu mebh |
| `gaso` Sounds | 24 (0x18) | `0x100df210` / `FUN_10020210(i)` | 0 ButtonClick `clic` … 20 MoneyCount `moco`, 22 GroundAccuracy MaxBonus `acbo`, 23 MissionBonus `miac` |
| `inre` Rects (reli) | 22 (0x16) | `0x100df20c` / `FUN_10020220(i,&r)` (16 B each) | scorebar/levsel/briefing rects |
| `gaob` Objects | 40 (0x28) | `0x100df208` / `FUN_100201f0(i)` | 0/1 Player 1/2, 2–5 MoneyUnit 50/10/5/1, 6–9 water impacts, 10–21 Notice_Level_01..12, 22 LevelEnd, 23 AllLevelsCompleted, 24 GameOver, 25–34 RandomBonus_1..10, 35–39 Multiplier X2 X3 X4 X5 X10 |
| `gaco` Colors (coli) | 1 | `uRam100e0194` via `FUN_10003340` | scoreBar_Digit `52c594` |
Other idli: `Fonts[tesp]` (3 items, all `tesm`), `Editor[edit]`, `Formats[gate]` (55 tefo IDs).
⚑ corrected (wave 2, 2026-10-03): was "55 tefo IDs" — the file has 54 items (0..53) and `FUN_1000ed60` loads 54
(`cmpwi …0x36` loop) — see hud-scorebar.md §9.
[HIGH for counts/slots (literal loop bounds + accessor disassembly); MED for each consumer's use]

`reli/Rects[inre]` RECT values are `<a, b, c, d>` read by `FUN_1002cc90` (strtok ","): the
decompile's register flow stores token 1→`r[1]`, 2→`r[0]`, 3→`r[3]`, 4→`r[2]`, i.e. the TEXT
order is **(left, top, right, bottom)** and memory is a Mac Rect (top, left, bottom, right).
Cross-check: every level has `#background_RECT <0, 0, 480, 3600>`, and `FUN_1000fbc0` compares
`+0x6c` (r[3] = right = 480) with the map image width and `+0x68` (r[2] = bottom = 3600) with its
height ("Background image dimensions do not match Level data") — consistent only with this order.
So `#Scorebar Player 1 Score <25, 81, 135, 95>` = left 25, top 81, right 135, bottom 95 (110×14,
relative to the 160-px score bar). [MED — the store order comes from `unaff_r26..r29` juggling;
the background cross-check is HIGH] ⚑ corrected (wave 2, 2026-10-03): MED → HIGH — the meter code computes the bar
width as `r[3] − r[1]` (`10032460`, `10032464`, `1003246c subf`), which gives 96 = the `shme` frame
width only in this order — see hud-scorebar.md §1.

## 5. `tefo` — text formats (54 files, G_Text.cc `FUN_1000ef90`)

Keys (order-independent, §1): `#Loc_X_INT #Loc_Y_INT #Size_INT #Format_ID #Monospaced_BOOL
#DrawShadows_BOOL #BlendAmount_0To32_INT (≤32, %u) #SpaceBetweenChars_INT (≥0)
#Colorise_Do_BOOL #ColoriseColor_RGB #ColorStrip_Do_BOOL #ColorStrip_HOffset_INT
#ColorStrip_VOffset_INT #ColorStrip_BlendAmount_0To32_INT #ColorStrip_Color_RGB
#ColorStrip_MinWidth_INT #ColorStrip_MinHeight_INT`. [HIGH — strings + read order]
⚑ corrected (wave 2, 2026-10-03): was "`#Size_INT`" in the key list — it is never read: the string "Size_INT" does not
occur in the data image and `FUN_1000ef90` reads only the other 16 keys; every format uses the one
font `tesm` — see hud-scorebar.md §9.
`#Format_ID`: the first 4 chars after `<` become a 4CC; the strings "0".."4" (`0x100e5735…3d`)
map to `LEFT CENT RIGH CEBU CEGA`; anything else not among those five logs "Unknown Text Format
Flag" and becomes `LEFT`. Shipped values: LEFT ×28, CENT ×8, RIGHT ×4 (→`RIGH`), CEBU ×5,
`3` ×7, `4` ×2 (`grep -h '#Format_ID'` census). Comments in the files: CEBU = "Centre in
buffer", CEGA = "Centre in game area", CENT = "Centered around location". Whether "3"/"4" really
match (the 4 copied bytes are `3>` + 2 more chars, compared to "3") is NOT RESOLVED
(`FUN_10014060` 4CC→string not read). [MED]
BlendAmount scale: 0 = opaque, 32 = invisible (`kU_Pixel16_Visible` … `kU_Pixel16_Invisible`,
assert text) [MED — names only].

### Glyph order of sprite fonts (`FUN_1000e8d0 @ 1000e8d0`)
A switch maps a character to a frame index in the font sprite group (`tesm` = Text - Small).
Extracted programmatically from the decompiled `case X: return Y;` pairs:
```
frame 0-25  A-Z      26-51 a-z      52-61 1 2 3 4 5 6 7 8 9 0
62 !  63 "  64 #  65 $  66 %  67 &  68 '  69 ( [ {  70 ) ] }  71 *  72 +  73 ,  74 -  75 .
76 /  77 :  78 ;  79 <  80 =  81 >  82 ?  83 @  84 \  85 ^  86 _  87 `  88 |  89 ~
default (any other byte) 90
```
Space is handled outside this table (`FUN_1000ebd0` branches on a float compare before calling
it; the space advance is NOT RESOLVED). [HIGH for the table]

## 6. Weapon / player definition key tables

Generated with `python3 docs/deimos/tools/key_offsets.py ghidra/Deimos_pef.decompiled.c
FUN_1002ba00 FUN_10039e70` (offsets into the in-memory definition; key names truncated at 32
chars by Ghidra's labels). `wede` parser `FUN_1002ba00` (G_WeaponDefinitions.cc), in call order:
`#type_ID +0x008 · #default_ID +0x00c · #name_STR +0x010 · #description1_STR +0x030 ·
#description2_STR +0x0b0 · #scoreBarPreviewFace_ID +0x130 · #scoreBarPreviewFrame_INT +0x134 ·
#maxAllowed_INT +0x138 · #minimumLevelAvailable_INT +0x13c · #maximumLevelAvailable_INT +0x140 ·
#player1AppearanceFace_ID +0x144 · #player2AppearanceFace_ID +0x148 · #playerGlow_COLOR +0x14c ·
#selectionSound_* +0x150..0x164 · #crosshairFace_ID +0x168 · #crosshairFrame_INT +0x16c ·
#crosshairLockedFace_ID +0x170 · #crosshairLockedFrame_INT +0x174 · #crosshairX/YOffset +0x178/17c ·
#crosshairSpawnOnActivation_ID +0x180 · #numAmmoInPack_INT +0x184 · #ammoWarnAtCount_INT +0x188 ·
#ammoWarning_STR +0x18c · #autoRepeat_BOOL +0x1ac · #delayBetweenLaunches_INT +0x1b0 ·
#delayBetweenLoadLaunches_INT +0x1b4 · #shieldIncrease_INT +0x1b8 · #livesIncrease_INT +0x1bc ·
#invulnerableForTime_INT +0x1c0 · #spawn_NumUnitsToSpawn_INT (count) then per spawn
{#spawn_Name_STR, #spawn_Unit_ID +0x20, #spawn_XLoc_INT +0x24, #spawn_YLoc_INT +0x28,
#spawn_SetHeading_BOOL +0x2c, #spawn_Angle_INT +0x30} · #powerup_Air_* +0x1c8..0x1e4 ·
#powerup_Ground_* +0x1e8..0x204`. [HIGH — tool output from the reader calls]
The `plde` parser is `FUN_10039e70` (G_PlayerDefinitions.cc); its reader calls use a form the
tool regex does not match (0 rows) — its key→offset table is NOT RESOLVED (keys themselves:
see waves-and-enemies.md §5).
