# Ferazel's Wand 1.0.3 — coverage ledger of the RE deepening (2026-10-03)

**Code readings only; nothing behaviour-verified.** This file says *where* each routine and each
placed sprite type is explained; it adds no readings of its own. Date 2026-10-03. Built by the
synthesis pass from: `tools/targets.txt` (the 154 TVector targets), a name-and-address grep of the 14
new files, a census of the active placement records of all 24 `Mlvl` (record layout
world-data-format.md §3.4; class by `tools/gensprite_map.py`), and the new files' section
headings. "§" = section of the named file. Status: **COVERED** (behaviour decoded in that §),
**PARTIAL** (decoded in passing or only some arms), **NAME-ONLY** (cited, behaviour not read),
**UNCOVERED** (not cited by any new file).

File key: EG `enemies-ground.md` · EF `enemies-flyers.md` · EW `enemies-water-cave.md` ·
B1 `bosses.md` · B2 `bosses-2.md` · ES `enemy-shots-and-damage.md` · PB `pickups-boxes.md` ·
T1 `triggers-background.md` · T2 `triggers-background-2.md` · SD `spells-detail.md` ·
SC `save-continue.md` · PR `platforms-ropes-radial.md` · P1 `player-states.md` · P2 `player-states-2.md` ·
GY `geysers.md` · HM `held-item-melee.md` (the two gap files written after review 1a #4 / 1b #11; ⚑ corrected (review 1c, 2026-10-03) #10).

## 1. The 154 targets of `tools/targets.txt`

Totals: **140 COVERED**, **1 PARTIAL** (`.DoOpenDocAE`), **13 UNCOVERED** (all system / UI
callbacks in the INDEX out-of-scope list or engine plumbing). Every sprite Setup / Handle / Hit /
HitTile / Kill callback is covered.

| address(es) | target(s) | status | where |
|---|---|---|---|
| 1004aefc | `.SetupPlayerSprite` | COVERED | P1 §8 (initial state); ES §2.3 (trail spawn); PB §3.1 (held item) |
| 1004d5fc | `.HandlePlayerSprite` | COVERED | P1 §1–§7 (order, state globals, state selection, inputs, facing, faces); SD §2.2 (cast frame), §5 (glider); PR §5 (`+0x19e`); ES §3.8 (stun, death) |
| 10054ca8 | `.HitPlayerTileSprite` | COVERED | P2 §10, §10.1 (`.WallBounceBG`); P2 §9 (`.WallBounce` kinds) |
| 100556f4 | `.HitPlayerSprite` | COVERED | ES §3.1–§3.5 (gate, dispatch order, Box/hazard/generic arms); PB §1.2 (pickup gate), §2.3 (talkers); T1 §2.4–§2.13 (Background hazards); SC §2.1 (save point); P1 §3.6 (doors, teleporters) |
| 10058710 | `.HandleCannonedSprite` | COVERED | ES §2.1; T1 §2.2 (cannon side) |
| 1004b3b4 / 1004b354 | `.SetupTrailSprite` / `.HandleTrailSprite` | COVERED | **HM §3** (Double-Speed trail, five type-1 sprites); ES §2.3 |
| 1004b7d4 / 1004b4f0 | `.SetupShadowSprite` / `.HandleShadowSprite` | COVERED (HIGH in HM; was MED in ES) | **HM §2** (Shadow Double 0x1b39: faces, empty rect, bob table, respawn); ES §2.4 |
| 1004bdd0 / 1004be74 | `.SetupHeldItemSprite` / `.HandleHeldItemSprite` | COVERED | **HM §1** (creation, swing, `.SetHeldItemPos`, hit geometry, strike = c 3..5, `+0xa6`); PB §3.1; P1 §3.10 |
| 1005925c / 10059704 | `.SetupPlayerShotSprite` / `.HandlePlayerShotSprite` | COVERED | SD §3.1 / §3.2 (+ §2.4 power) |
| 1005a7fc / 1005b0bc | `.HitPlayerShotSprite` / `.HitPlayerShotTileSprite` | COVERED | SD §3.7 / §3.3–§3.5 |
| 1005ba5c / 1005bffc | `.SetupEnemyShotSprite` / `.HandleEnemyShotSprite` | COVERED | ES §1.1, §1.2, §1.4, §1.5 |
| 1005c9a8 / 1005d034 | `.HitEnemyShotSprite` / `.HitEnemyShotTileSprite` | COVERED | ES §1.3 (B2 NR 3 asks for the 0x46a/0x71f tile path detail) |
| 1005d988 / 1005e934 | `.SetupBonusSprite` / `.HandleBonusSprite` | COVERED | PB §1.1, §1.3–§1.6 |
| 1005fd38 / 1006010c | `.HitBonusSprite` / `.HitBonusTileSprite` | COVERED | PB §1.1, §1.5 |
| 10060680 / 10061160 | `.SetupEffectSprite` / `.HandleEffectSprite` | COVERED | T2 §2.1, §2.2 |
| 10061978 / 100619a0 | `.HitEffectSprite` / `.HitEffectTileSprite` | COVERED | T2 §2 |
| 10060cd8 | `.HandleGeyserSegSprite` | COVERED | **GY §4, §7** (column segments, contacts); T2 §2.2 (row 1440); ES §3.4 |
| 10060c0c / 10060c78 | `.SetupDigitSprite` / `.anon_10060c78` | COVERED | T2 §3 |
| 10033418 / 10033378 | `.SetupPxSprite` / `.HandlePxSprite` | COVERED | T2 §4 |
| 10061f94 / 100635b4 | `.SetupPlatformSprite` / `.HandlePlatformSprite` | COVERED | PR §2.1–§2.3, §2.5, §2.8 |
| 10064d94 / 10064f04 | `.HitPlatformSprite` / `.HitPlatformTileSprite` | COVERED | PR §2.6 / §2.7 |
| 100652c0 / 10065374 / 10065798 | `.SetupChainSprite` / `.HandleChainSprite` / `.HitChainTileSprite` | COVERED | T2 §1 |
| 10065508 / 100655c8 | `.SetupSeeSawSegSprite` / `.HandleSeeSawSegSprite` | COVERED | T2 §1; PR §2.3 (mode 30) |
| 100659a0 / 10065c00 / 100665bc / 10066aa4 | Crawler Setup / Handle / Hit / HitTile | COVERED | EG §4 (tiles: EG §2.4) |
| 100664a8 | `.HandleStatueSprite` | COVERED | EG §2.2; ES §2.2; EW §5 |
| 10067318 / 100683b8 / 1006a260 / 1006a740 | Walker Setup / Handle / Hit / HitTile | COVERED | EG §3.1 / §3.2–§3.6 / §3.7 / §3.7 |
| 10077914 / 10077a88 / 1007801c / 10078384 | Roach Setup / Handle / Hit / HitTile | COVERED | EG §5 |
| 1008622c / 1008697c / 10087334 / 100875bc / 1008763c | Dillo Setup / Handle / Hit / `.KillDillo` / HitTile | COVERED | EG §6 (death §2.5) |
| 1006b3d8 | `.GetRopeBridgeHeight` | COVERED | PR §3.7; PB §2.2 (type 1466) |
| 1006b43c / 1006d878 | `.SetupBoxSprite` / `.HandleBoxSprite` | COVERED | PB §2.1, §2.2, §2.4.1–§2.4.11 |
| 10070024 / 10070718 | `.HitBoxSprite` / `.HitBoxTileSprite` | COVERED | PB §2.1, §2.4.1, §2.4.9 |
| 10070d30 / 10070e60 / 100710e4 | Button Setup / Handle / Hit | COVERED | T1 §1 |
| 10071710 / 10073afc / 10075044 | Background Setup / Handle / Hit | COVERED | T1 §2.1–§2.15 |
| 1007cdb0 / 1007d044 / 1007cf64 | Blob Setup / Handle / `.HandleDeadBlobSprite` | COVERED | EW §3.1–§3.3 |
| 1007d6e0 / 1007d968 | Blob Hit / HitTile | COVERED | EW §3.4; tiles EW §0.1 |
| 1007dc30 / 1007e6b0 / 1007f508 / 1007f91c | Bat Setup / Handle / Hit / HitTile | COVERED | EF §3.1–§3.3, §3.6 |
| 1007e220 / 1007e2c8 / 1007f734 | Swarm member Setup / Handle / Hit | COVERED | EF §3.4, §3.6 |
| 1007f440 / 1007f4a0 | Insect body Setup / Handle | COVERED | EF §3.5 |
| 1007fc88 / 1007feec / 10080d34 / 100810d4 / 100811a4 | Gremlin Setup / Handle / Hit / `.KillGremlinSprite` / HitTile | COVERED | EF §4.1–§4.4 |
| 100814b8 / 100816d8 / 10081aa4 / 10081c60 | Floater Setup / Handle / Hit / HitTile | COVERED | EF §5.1–§5.3 |
| 10081f14 / 1008214c / 100828cc / 10082c14 / 10082d04 | Frog Setup / Handle / Hit / `.KillFrog` / HitTile | COVERED | EW §1.1–§1.6 |
| 10082f20 / 10083074 / 1008350c / 10083724 / 100837b8 | Salamander Setup / Handle / Hit / `.KillSalamander` / HitTile | COVERED | EW §2.1–§2.5 |
| 100894e4 / 10089828 / 10089dec / 10089e24 | Crab Setup / Handle / `.HandleCrabSegSprite` / Hit | COVERED | EW §4.1–§4.4 |
| 10083f20 / 10084044 / 100840b4 | `.SetupRopeSprite` / `.SetupRopeSegSprite` / `.HandleRopeSegSprite` | COVERED | PR §3.1, §3.5 |
| 10084264 / 10084c1c | `.GetRopeHeight` / `.HandleRopeSprite` | COVERED | PR §3.3 / §3.4 |
| 10084b00 / 10084ba8 | `.RopeIdleize` / `.RopeDeIdleize` | COVERED | PR §3.1 |
| 100878ac / 10087c04 / 1008854c / 1008874c / 10088834 | Warrior Setup / Handle / Hit / `.KillWarrior` / HitTile | COVERED | B1 §2.1–§2.3 (shared rules §1) |
| 1008c6a8 / 1008c8e8 / 1008d470 / 1008d69c / 1008d784 | Wizard Setup / Handle / Hit / `.KillWizard` / HitTile | COVERED | B1 §3.1–§3.3 |
| 1008b538 / 1008b878 / 1008c0e0 / 1008c350 / 1008c434 | Chief Setup / Handle / Hit / `.KillChief` / HitTile | COVERED | B1 §4.1–§4.3 |
| 1008a0ac / 1008a630 / 1008a594 / 1008b0b4 / 1008b2d0 | Demon Setup / Handle / `.HandleDemonSegSprite` / Hit / `.KillDemon` | COVERED | B2 §5.1–§5.5 |
| 1008dd44 / 1008e4ec / 1008dc7c | Xichra Setup / Handle / `.HandleXichraWingSprite` | COVERED | B2 §6.1–§6.4 |
| 1008fdf4 / 100902a4 / 10090384 | Xichra Hit / `.KillXichra` / HitTile | COVERED | B2 §6.5, §6.6, §6 header |
| 10033dbc | `.DoOpenDocAE` | PARTIAL | SC §4 (one caller line: resumes a save opened from the Finder while no game loop runs) |
| 10033d94 / 10033efc / 10033f24 | `.DoOpenAppAE` / `.DoPrintDocAE` / `.DoQuitAppAE` | UNCOVERED | AppleEvent handlers — INDEX out of scope |
| 10005f5c | `.MySleepProc` | UNCOVERED | sleep proc — engine plumbing |
| 10034f40 | `.TintFadeProc` | UNCOVERED | screen tint fade callback — candidate for a later pass (sprites §4 palettes) |
| 10047dd8 | `.STLoopCallBack` | UNCOVERED | Sound Tool loop callback — sprites §6.2 mixer [MED there] |
| 100757b8 / 10075990 | `.DrawGreyOutline` / `.PrefDialogFilter` | UNCOVERED | dialog UI (prefs, engine §8 controls closed via SC §8.2 without them) |
| 100987ac / 1009b7c4 | `.MyDMIterator` / `._MacOSE2SHook` | UNCOVERED | Display Manager / runtime glue — out of scope (resolution switch) |
| 1009c1ac / 1009d830 / 1009d880 | `.ThreadsPostflight` / `._ThreadTimer` / `._ThreadDefer` | UNCOVERED | Thread Manager runtime — engine §1 identity only |

## 2. Main-dump helpers the new files cite (217 distinct names)

Decoded where they are used (COVERED): the collision and integration helpers (`.WallBounce`,
`.WallBounceBG`, `.SeparateFromTiles2`, `.PlatformBounce`, `.RectBounce`, `.ApplyGravityAndSeparateFromTiles`,
`.StandardSpriteHandles` — P2 §9–§10, physics §2/§3/§8.1), `.HurtPlayer` / `.ShieldBlock` /
`.HurtSprite` (ES §3.6–§3.7), `.KillEnemyShot` (ES §1.6), `.TurnIntoStatue` (EG §2.2, ES §2.2),
`.CastSpell` / `.HandleKeys` cast path / `.UpdateItemStat` (SD §1–§2), `.HandleItemUse` (P1 §3.10,
PB §3.1), radial family `.MakeRadialTables` `.MakeRadial` `.UpdateRadialPos`
`.FindUpdatedRadialSpeed` `.RadialWheelStep` `.BounceRadial` `.MakeRadiusSprites`
`.UpdateRadiusSprites` (PR §1), rope family `.SetupRopeSegArray` `.InitRopeSprite` `.RopeCollide`
(PR §3), `.SuperSpring` (PR §4, T1 §2.3), `.CrunchTile` / `.GetFGCrunchDirTile` / `.MakeCrunchSprite`
(PR §6, T2 §2.3), `.KillCrate` (PB §2.4.1), save/continue family `.NewGame` `.SavePointSave`
`.SaveSG` `.OpenSG` `.ContinueGame` `.AskToContinue` `.EndLevelSGUpdate` `.IncrementLastSGString`
(SC §1–§5), boss helpers `.RandomWarriorAttack` `.WarriorLayEgg` `.HandleDemonSegs`
`.UpdateXichraCannons`(partly) `.StandardXichraFloat` `.DoXichraShot` (B1, B2), enemy helpers
`.AxGoblinCoreLogic` `.PopupGoblinCoins` `.HurtGoblin` `.KillWalker` `.ShootSpines` `.DilloLayEgg`
`.RandomDilloAttack` `.KillBat` `.KillBlob` `.KillRoach` `.KillCrawler` (EG, EF, EW), the
`.Init<Class>Sprite` sheet loaders (each class file), `.DoubleSpeedTrail` (ES §2.3),
`.MTAddPxSprite` (T2 §4), `.UpdateDigits` (T2 §3).

Now COVERED by the gap files (⚑ corrected (review 1c, 2026-10-03) #10): `.HandleGeyserColumn` (GY §4: geometry, liquid per
kind, head 0x5a9 creation), the geyser arms of `.SetupBoxSprite`/`.HandleBoxSprite` (GY §2–§3, §5),
`.HandleItemUse` / `.SetHeldItemPos` (HM §1.3–§1.4), `.DoubleSpeedTrail` (HM §3).

NAME-ONLY or arithmetic explicitly left open (each is in a file's NOT RESOLVED list):

| helper | cited by | what is missing |
|---|---|---|
| `.WrapDrawSprites` / `.WrapDrawFace` / `.BlitEncFaceSpecial*` | EF, EW, EG, T2, PR, B2 | `+0xb8` draw-effect modes (1, 3/4, 7, 9, 0xb, 0xc, 0x10..0x13) as pixels; `+0x88` gate (synthesis: sole reader 1001493c) |
| `.BuildTintTable` | EG, EW, T1 | colours of remap tables 2/3/4/0xb/0xc/0xf/0x10..0x15/0x17/0x18 |
| `.HandleBurn` / `.BurnFaceRow` | EF, EW, EG, B1 | row arithmetic, styles 1 vs 0xd (trigger and end are read) |
| `.BloodSpray` / `.NewParticle` / `.ExplodeFaceIntoParticles` | EG, EW, T2, SD | argument meanings, particle kinds |
| `.UpdateXichraCannons` | B2 | cannon values `+0x158..+0x164` |
| `FUN_1003f218` (Boomerang steering) | SD | internals |
| `.HandleLineActions` / `.HandleLineResponses` | SC | `Mcnv` action encoding (INDEX NR 3) |
| `.STPlay3DSoundRand` / `.STPlay3DSoundPitched` | EF, B2 | pitch randomisation / rate units |
| `.HandleIdleSprites` | T1, T2, EG | activation rule for idle sprites (deactivation margins are read) |
| `.AnimateCLUT` | SC, B2 | hdr+0x2730 modes 3..7 on screen |
| `.SetupOmniPx` / OmniPx composition | SC | INDEX NR 2 remainder |

## 3. Placed sprite types vs explanation (census of active records, 24 `Mlvl`)

Every one of the **243 placed types** is explained in some new file (name or covering range row);
per class (count = active records):

| class (range, world-data §3.5) | placed types (×records) | where explained | unplaced sub-ranges |
|---|---|---|---|
| Walker 1700..1709, 1750..1769 | 1700 ×47, 1705 ×37, 1750 ×50, 1760 ×24 | EG §1, §3.3–§3.6 | others: no behaviour (EG §8) |
| Crawler 1712 / Roach 1720 | 1712 ×31 / 1720 ×16 | EG §4 / §5 | — |
| Dillo 1870..1879 | 1870 ×19, 1871 ×1 | EG §6 | 1872..1879: no contact, EG §2.1 |
| Blob 1730..1739 | 1730 ×11, 1731 ×5, 1732 ×13 | EW §3.1 | 1733 HP 2000; 1734..1739 HP 0 |
| Bat 1740..1749, 1850..1854, 1860..1869 | 1740 ×28, 1741 ×3, 1742 ×2, 1851 ×45, 1860 ×5, 1869 ×6 | EF §2, §3.1–§3.7 | EF §3.7 variant table |
| Gremlin 1770..1779 | 1770 ×50 | EF §4 | 1771..1779 as 1770 |
| Floater 1780..1799 | 1780 ×7 (Wraith) | EF §5 | 1790..1799 other rect |
| Frog 1800..1809 / Salamander 1810..1819 | 1800 ×41 / 1810 ×22 | EW §0, §1, §2 | — |
| Crab 1890..1899 | 1892 ×3 | EW §4 | type = aim window only |
| Warrior / Wizard / Chief / Demon / Xichra | 1820, 1830, 1910, 1920, 1990 (×1 each) | B1 §1.1 (type never read except Demon 0x780/0x781) | whole 10-ranges behave alike |
| Platform 1400..1429 | 1400 ×59, 1401 ×25, 1402 ×13, 1403 ×17, 1404 ×27, 1405 ×9, 1407 ×2, 1408 ×10, 1410 ×3, 1420 ×2, 1425 ×2 | PR §2.2, §2.9 | 0x586..0x58b, 0x58f..0x595: no arm (PR corr. 5) |
| Rope 3020..3039 | 3020 ×20, 3021 ×5, 3022 ×24 | PR §3.2, §3.6 | 3023..3039 armless |
| Button 1320..1329 | 1320 ×2, 1322 ×22 | T1 §1 | 1323..1329 hot rect (T2 NR 6) |
| Background | 1090..1097 (171), 1150..1153 (57), 1208 ×89, 1480..1488 (152), 1840..1843 (286), 1900..1903 (100), 2700..2714 (45), 2890..2893 (164), 2900 ×54, 2901 ×4, 3002 ×20, 3060 ×53, 3080..3086 (31), 3249 ×48 | T1 §2.2–§2.15 | Setup handles only the sub-ranges in T1 §2.1; the rest of each world-data range is inert |
| Bonus | 43 types: 1055 ×1944, 1056, 1058, 1059 ×236, 1290..1293, 1303, 1307 ×224, 1330..1341, 1350, 2000 ×5, 3050, 3100..3108, 3204..3226 | PB §1.3–§1.11 | — |
| Box | 105 types: 1060..1062, 1065 ×89, 1070, 1072, 1080, 1250 ×14, 1308, 1440, 1442 ×25, 1450, 1453, 1461..1464, 1470, 1475, 1490..1493, 2808..2884 (decor), 2902..2911, 2921..2932, 2940 ×43, 2941, 2951..2965, 3070, 3090..3092 | PB §2.2–§2.4; SC §2 (1065); T1 §3 (talkers); GY §1–§5 (1440, 1442 geysers) | decoration rows are range-level only (PB §2.2 rows 2805..2889) |

Record byte +1 is 0 in every active record and is read by no class (EG, EF, EW, B1, PB, T1, PR).

## 4. What the fix pass and the next lane inherit
- 13 UNCOVERED targets are non-gameplay; `.TintFadeProc` and `.STLoopCallBack` are the only two a
  replica might need (screen fades, looping sounds) — assign them with sprites §4/§6 work.
- Draw-effect semantics (`+0xb8`, `+0x88`, tint tables, burn) are the largest shared gap: six files
  stop at the same `.WrapDrawSprites` boundary.
- Contradictions between the new files and with the bank: summarised in the INDEX review ledger
  (deepening paragraph: 41 entries, 16 settled from raw by the synthesis pass, the 14 OPEN ones adjudicated from raw by review 1c; all fixes applied by the consolidated fix pass, `FIXPASS-2026-10-03-deepening.md`); the
  bank-facing results are marked
  `⚑ corrected (deepening 2026-10-03)` in physics.md, spells-items.md, world-data-format.md,
  engine.md, sprites-backgrounds-sounds.md, INDEX.md and physics-sprites.md (physics §8, split off by this pass).
