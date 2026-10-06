# Ferazel's Wand 1.0.3 — coverage ledger of the RE deepening (2026-10-03) and wave 2 (2026-10-04)

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
⚑ wave 2 (2026-10-04): LT `lighting-tables.md` · DE `draw-effects.md` · PA `particles.md` ·
RO `rendering-omnipx-titles.md` · CM `conversations-mcnv.md` · B3 `bosses-3.md` ·
EG2 `enemies-ground-2.md` · SD2 `spells-detail-2.md` · PR2 `platforms-ropes-radial-2.md` ·
ES2 `enemy-shots-and-damage-2.md` · PB2 `pickups-boxes-2.md`. Wave-2 pointers are appended to the
deepening cells after "⚑ w2:"; they come from a name grep of the 11 new files plus the wave-2 sections
added in place (EF §7, EW §7, T2 §8, SC §9, P1 §9, P2 §12–§15, HM §4), each § checked against its heading.

## 1. The 154 targets of `tools/targets.txt`

Totals: **141 COVERED**, **1 PARTIAL** (`.DoOpenDocAE`), **12 UNCOVERED** (all system / UI
callbacks in the INDEX out-of-scope list or engine plumbing). Every sprite Setup / Handle / Hit /
HitTile / Kill callback is covered. ⚑ wave 2 (2026-10-04): `.TintFadeProc` moved to COVERED (LT §10);
was 140 / 1 / 13.

| address(es) | target(s) | status | where |
|---|---|---|---|
| 1004aefc | `.SetupPlayerSprite` | COVERED | P1 §8 (initial state); ES §2.3 (trail spawn); PB §3.1 (held item) · ⚑ w2: SD2 §1 (cast-start flag); PR2 §8.4 (layer 10) |
| 1004d5fc | `.HandlePlayerSprite` | COVERED | P1 §1–§7 (order, state globals, state selection, inputs, facing, faces); SD §2.2 (cast frame), §5 (glider); PR §5 (`+0x19e`); ES §3.8 (stun, death) · ⚑ w2: SD2 §1 (gate globals, item latch); PR2 §8.1 (place in the frame), §10 (parity, J-reset climb flag); ES2 §4.4 (landing stagger); LT §10 (liquid screen tint); CM §1.1 (conversation cooldown); P1 §9 |
| 10054ca8 | `.HitPlayerTileSprite` | COVERED | P2 §10, §10.1 (`.WallBounceBG`); P2 §9 (`.WallBounce` kinds) · ⚑ w2: P2 §12 (FG 0x4e/0x4f, BG 400..495), §13 (`.CrunchTile` return) |
| 100556f4 | `.HitPlayerSprite` | COVERED | ES §3.1–§3.5 (gate, dispatch order, Box/hazard/generic arms); PB §1.2 (pickup gate), §2.3 (talkers); T1 §2.4–§2.13 (Background hazards); SC §2.1 (save point); P1 §3.6 (doors, teleporters) · ⚑ w2: ES2 §4.2 (called only from the `.MTCollideSpecialSprite` pass); PR2 §8.3; CM §1.1 (talker/sign arms); PB2 §3 (gate globals), §4.2 (stalactites), §7 (0x4b7); B3 §8.2, §8.5; T2 §8.2 (passage globals); SC §9.1–§9.2 (save point) |
| 10058710 | `.HandleCannonedSprite` | COVERED | ES §2.1; T1 §2.2 (cannon side) · ⚑ w2: B3 §8.2–§8.3 (Xichra cannons, launched seeds); T2 §8.1 |
| 1004b3b4 / 1004b354 | `.SetupTrailSprite` / `.HandleTrailSprite` | COVERED | **HM §3** (Double-Speed trail, five type-1 sprites); ES §2.3 |
| 1004b7d4 / 1004b4f0 | `.SetupShadowSprite` / `.HandleShadowSprite` | COVERED (HIGH in HM; was MED in ES) | **HM §2** (Shadow Double 0x1b39: faces, empty rect, bob table, respawn); ES §2.4 |
| 1004bdd0 / 1004be74 | `.SetupHeldItemSprite` / `.HandleHeldItemSprite` | COVERED | **HM §1** (creation, swing, `.SetHeldItemPos`, hit geometry, strike = c 3..5, `+0xa6`); PB §3.1; P1 §3.10 · ⚑ w2: HM §4 (list order, mirroring, `+0x11c`); PR2 §8.2 |
| 1005925c / 10059704 | `.SetupPlayerShotSprite` / `.HandlePlayerShotSprite` | COVERED | SD §3.1 / §3.2 (+ §2.4 power) · ⚑ w2: SD2 §2 (visibility test), §3 (Boomerang steering), §5 (followers, orphans) |
| 1005a7fc / 1005b0bc | `.HitPlayerShotSprite` / `.HitPlayerShotTileSprite` | COVERED | SD §3.7 / §3.3–§3.5 · ⚑ w2: SD2 §5; PR2 §12 (wall-ice faces); PB2 §7 |
| 1005ba5c / 1005bffc | `.SetupEnemyShotSprite` / `.HandleEnemyShotSprite` | COVERED | ES §1.1, §1.2, §1.4, §1.5 · ⚑ w2: ES2 §4.1 (spawn set, dead fields), §4.5 (spit `+0x1aa`) |
| 1005c9a8 / 1005d034 | `.HitEnemyShotSprite` / `.HitEnemyShotTileSprite` | COVERED | ES §1.3 (B2 NR 3 asks for the 0x46a/0x71f tile path detail) · ⚑ w2: ES2 §4.3 (bombs, 0x6a9, shards); B3 §12.2 (boss projectiles vs tiles) |
| 1005d988 / 1005e934 | `.SetupBonusSprite` / `.HandleBonusSprite` | COVERED | PB §1.1, §1.3–§1.6 · ⚑ w2: PB2 §2 (`+0x168`), §1.3 (sounds); PA §5.1 (emitters) |
| 1005fd38 / 1006010c | `.HitBonusSprite` / `.HitBonusTileSprite` | COVERED | PB §1.1, §1.5 · ⚑ w2: PB2 §1.3; B3 §8.5 |
| 10060680 / 10061160 | `.SetupEffectSprite` / `.HandleEffectSprite` | COVERED | T2 §2.1, §2.2 · ⚑ w2: PA §5.1 (particle emitters); PB2 §7 (0x4b7 vs enemies/crates); T2 §8.6 (no-spawner effects) |
| 10061978 / 100619a0 | `.HitEffectSprite` / `.HitEffectTileSprite` | COVERED | T2 §2 |
| 10060cd8 | `.HandleGeyserSegSprite` | COVERED | **GY §4, §7** (column segments, contacts); T2 §2.2 (row 1440); ES §3.4 · ⚑ w2: PA §4.4 (kinds 200–202 colours), §3.2 (shape code) |
| 10060c0c / 10060c78 | `.SetupDigitSprite` / `.anon_10060c78` | COVERED | T2 §3 |
| 10033418 / 10033378 | `.SetupPxSprite` / `.HandlePxSprite` | COVERED | T2 §4 |
| 10061f94 / 100635b4 | `.SetupPlatformSprite` / `.HandlePlatformSprite` | COVERED | PR §2.1–§2.3, §2.5, §2.8 · ⚑ w2: PR2 §8.4 (layers), §10.1, §11 (`+0x190`); EG2 §1.2 (Walker corpse); DE §2.6 (mode 0xa child) |
| 10064d94 / 10064f04 | `.HitPlatformSprite` / `.HitPlatformTileSprite` | COVERED | PR §2.6 / §2.7 · ⚑ w2: PR2 §11; EG2 §1.4 (corpse edges) |
| 100652c0 / 10065374 / 10065798 | `.SetupChainSprite` / `.HandleChainSprite` / `.HitChainTileSprite` | COVERED | T2 §1 |
| 10065508 / 100655c8 | `.SetupSeeSawSegSprite` / `.HandleSeeSawSegSprite` | COVERED | T2 §1; PR §2.3 (mode 30) · ⚑ w2: PR2 §8.3 (see-saw slot in the player pass), §9 (sibling order) |
| 100659a0 / 10065c00 / 100665bc / 10066aa4 | Crawler Setup / Handle / Hit / HitTile | COVERED | EG §4 (tiles: EG §2.4) · ⚑ w2: EG2 §2 (`+0xa6` first-leap delay) |
| 100664a8 | `.HandleStatueSprite` | COVERED | EG §2.2; ES §2.2; EW §5 · ⚑ w2: PR2 §11 (Statue on a platform) |
| 10067318 / 100683b8 / 1006a260 / 1006a740 | Walker Setup / Handle / Hit / HitTile | COVERED | EG §3.1 / §3.2–§3.6 / §3.7 / §3.7 · ⚑ w2: EG2 §1 (corpse floats), §5; DE §2.1 (tiers 0x10010..15) |
| 10077914 / 10077a88 / 1007801c / 10078384 | Roach Setup / Handle / Hit / HitTile | COVERED | EG §5 · ⚑ w2: EG2 §2 (`+0xa6` write-only) |
| 1008622c / 1008697c / 10087334 / 100875bc / 1008763c | Dillo Setup / Handle / Hit / `.KillDillo` / HitTile | COVERED | EG §6 (death §2.5) · ⚑ w2: EG2 §7 (crush write); B3 §10.1 (the Dillo template) |
| 1006b3d8 | `.GetRopeBridgeHeight` | COVERED | PR §3.7; PB §2.2 (type 1466) |
| 1006b43c / 1006d878 | `.SetupBoxSprite` / `.HandleBoxSprite` | COVERED | PB §2.1, §2.2, §2.4.1–§2.4.11 · ⚑ w2: PB2 §4 (spiked balls, stalactites, magic carpet), §5 (boulders), §9 (decoration per type); B3 §8.5 (lair gates); PA §5.2 |
| 10070024 / 10070718 | `.HitBoxSprite` / `.HitBoxTileSprite` | COVERED | PB §2.1, §2.4.1, §2.4.9 · ⚑ w2: PB2 §4.2, §4.3, §6 (door `+0xa0`), §7; PR2 §11 |
| 10070d30 / 10070e60 / 100710e4 | Button Setup / Handle / Hit | COVERED | T1 §1 · ⚑ w2: T2 §8.5–§8.6 (record-p4 linkage, 1323..1329); B3 §8.5 |
| 10071710 / 10073afc / 10075044 | Background Setup / Handle / Hit | COVERED | T1 §2.1–§2.15 · ⚑ w2: B3 §8.2 (cannon rotate arm, `.HitBackgroundSprite` 0x442..0x44c); T2 §8.1, §8.4 (wind) |
| 1007cdb0 / 1007d044 / 1007cf64 | Blob Setup / Handle / `.HandleDeadBlobSprite` | COVERED | EW §3.1–§3.3 · ⚑ w2: PA §5.3 (BloodSpray kind 201) |
| 1007d6e0 / 1007d968 | Blob Hit / HitTile | COVERED | EW §3.4; tiles EW §0.1 |
| 1007dc30 / 1007e6b0 / 1007f508 / 1007f91c | Bat Setup / Handle / Hit / HitTile | COVERED | EF §3.1–§3.3, §3.6 · ⚑ w2: EF §7.1–§7.3, §7.5 |
| 1007e220 / 1007e2c8 / 1007f734 | Swarm member Setup / Handle / Hit | COVERED | EF §3.4, §3.6 |
| 1007f440 / 1007f4a0 | Insect body Setup / Handle | COVERED | EF §3.5 |
| 1007fc88 / 1007feec / 10080d34 / 100810d4 / 100811a4 | Gremlin Setup / Handle / Hit / `.KillGremlinSprite` / HitTile | COVERED | EF §4.1–§4.4 · ⚑ w2: ES2 §4.5 (spit rotation); EF §7.3 |
| 100814b8 / 100816d8 / 10081aa4 / 10081c60 | Floater Setup / Handle / Hit / HitTile | COVERED | EF §5.1–§5.3 |
| 10081f14 / 1008214c / 100828cc / 10082c14 / 10082d04 | Frog Setup / Handle / Hit / `.KillFrog` / HitTile | COVERED | EW §1.1–§1.6 · ⚑ w2: EW §7.4 (dead water block); ES2 §4.8 (tint source) |
| 10082f20 / 10083074 / 1008350c / 10083724 / 100837b8 | Salamander Setup / Handle / Hit / `.KillSalamander` / HitTile | COVERED | EW §2.1–§2.5 · ⚑ w2: EW §7.1, §7.4 |
| 100894e4 / 10089828 / 10089dec / 10089e24 | Crab Setup / Handle / `.HandleCrabSegSprite` / Hit | COVERED | EW §4.1–§4.4 · ⚑ w2: EW §7.3 (`.GetBGTile(col,row)`) |
| 10083f20 / 10084044 / 100840b4 | `.SetupRopeSprite` / `.SetupRopeSegSprite` / `.HandleRopeSegSprite` | COVERED | PR §3.1, §3.5 |
| 10084264 / 10084c1c | `.GetRopeHeight` / `.HandleRopeSprite` | COVERED | PR §3.3 / §3.4 |
| 10084b00 / 10084ba8 | `.RopeIdleize` / `.RopeDeIdleize` | COVERED | PR §3.1 |
| 100878ac / 10087c04 / 1008854c / 1008874c / 10088834 | Warrior Setup / Handle / Hit / `.KillWarrior` / HitTile | COVERED | B1 §2.1–§2.3 (shared rules §1) · ⚑ w2: B3 §10.1 (`+0x154`, p2 = 150) |
| 1008c6a8 / 1008c8e8 / 1008d470 / 1008d69c / 1008d784 | Wizard Setup / Handle / Hit / `.KillWizard` / HitTile | COVERED | B1 §3.1–§3.3 · ⚑ w2: B3 §10.2 (state 11) |
| 1008b538 / 1008b878 / 1008c0e0 / 1008c350 / 1008c434 | Chief Setup / Handle / Hit / `.KillChief` / HitTile | COVERED | B1 §4.1–§4.3 · ⚑ w2: B3 §10.3 (`+0xb2`); ES2 §4.4 (landing stagger) |
| 1008a0ac / 1008a630 / 1008a594 / 1008b0b4 / 1008b2d0 | Demon Setup / Handle / `.HandleDemonSegSprite` / Hit / `.KillDemon` | COVERED | B2 §5.1–§5.5 · ⚑ w2: B3 §10.4 (type-write no-op) |
| 1008dd44 / 1008e4ec / 1008dc7c | Xichra Setup / Handle / `.HandleXichraWingSprite` | COVERED | B2 §6.1–§6.4 · ⚑ w2: **B3 §8** (lair: cannons §8.2, minions §8.4), §9.1 (only writer of hdr+0x2730); ES2 §4.4; CM §1.1 (conversations 250..252) |
| 1008fdf4 / 100902a4 / 10090384 | Xichra Hit / `.KillXichra` / HitTile | COVERED | B2 §6.5, §6.6, §6 header |
| 10033dbc | `.DoOpenDocAE` | PARTIAL | SC §4 (one caller line: resumes a save opened from the Finder while no game loop runs) |
| 10033d94 / 10033efc / 10033f24 | `.DoOpenAppAE` / `.DoPrintDocAE` / `.DoQuitAppAE` | UNCOVERED | AppleEvent handlers — INDEX out of scope |
| 10005f5c | `.MySleepProc` | UNCOVERED | sleep proc — engine plumbing |
| 10034f40 | `.TintFadeProc` | COVERED ⚑ wave 2 | LT §10 (per-channel fade-out curves; red first, blue last) — was UNCOVERED |
| 10047dd8 | `.STLoopCallBack` | UNCOVERED | Sound Tool loop callback — sprites §6.2 mixer [MED there]; ⚑ w2: B3 §10.4 notes in passing that it re-queues a sound and reads no sprite (not decoded) |
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

~~NAME-ONLY or arithmetic explicitly left open (each is in a file's NOT RESOLVED list):~~
⚑ wave 2 (2026-10-04): every row of the deepening's NAME-ONLY table is now COVERED. The old table,
with its new location:

| helper | cited by (deepening) | was missing | now COVERED in |
|---|---|---|---|
| `.WrapDrawSprites` / `.WrapDrawFace` / `.BlitEncFaceSpecial*` | EF, EW, EG, T2, PR, B2 | `+0xb8` modes as pixels; `+0x88` gate | DE §1 (pipeline), §2 (every mode), §3 (`+0x88` per mode); tables LT §2 |
| `.BuildTintTable` (and `.BuildReddenTable`, the pair/water builders) | EG, EW, T1 | table colours | LT §3 (tint bank, colours §3.2 — index pick LOW), §4 (water), §5 (hurt flash), §6 (pair / translucency) |
| `.CalcLightingTable` / `.CalcAmbientDarken` / `.GetFakeLight` | (INDEX 10) | algorithm | LT §7.3 / §7.2 / §7.5 |
| `.HandleBurn` / `.BurnFaceRow` | EF, EW, EG, B1 | row arithmetic, styles 1 vs 0xd | DE §4.1–§4.3; particles side PA §5.5 |
| `.BloodSpray` / `.NewParticle` / `.ExplodeFaceIntoParticles` | EG, EW, T2, SD | argument meanings, particle kinds | PA §2 (`.NewParticle`), §5.3 (`.BloodSpray`), §5.2 + DE §5 (explode), §4 (kinds) |
| `.UpdateXichraCannons` | B2 | cannon values `+0x158..+0x164` | B3 §8.2 (bosses-2 W5) |
| `FUN_1003f218` (Boomerang steering) | SD | internals | SD2 §3 (name proposal `.AddDirImpulse`) |
| `.HandleLineActions` / `.HandleLineResponses` (+ `.Conversation`, `.HandleConvLine`) | SC | `Mcnv` action encoding | CM §3.1–§3.4 (format §2.2–§2.3); PB2 §8 |
| `.STPlay3DSoundRand` / `.STPlay3DSoundPitched` | EF, B2 | pitch randomisation / rate units | EF §7.2 (enemies-flyers W4); B3 §12.1 |
| `.HandleIdleSprites` | T1, T2, EG | activation rule | T2 §8.3; EW §7.5 (`.AddIdleSprite`) |
| `.AnimateCLUT` | SC, B2 | hdr+0x2730 modes 3..7 | B3 §9 (bosses-2 W5); LT §1.5 |
| `.SetupOmniPx` / OmniPx composition | SC | INDEX NR 2 remainder | RO §3.2–§3.5 |
| `FUN_100916dc` / `FUN_10091504` | EG | sound helpers [MED] | EG2 §3 (voice count / voice stop) |

Also COVERED by wave 2: `.HandleFlotation` (EG2 §1.3), `.AltClutMod` (LT §1.6), `.InitParticleColors`
(PA §4), `.Splash` (PA §5.4), `.ParticleGlow` (PA §5.6), `.GenerateRain` (RO §3.6), the active-list and
collision routines `.MTNewSprite` / `.MTInsertSprite` / `.MTCollideSprites` / `.MTCollideSpecialSprite`
(PR2 §8.2–§8.3, ES2 §4.2, SD2 §4).

### 2.1 Routine map — draw, compositor, OmniPx, particles (⚑ wave 2, 2026-10-04; review leg E Minor)

| chain (caller → callee) | decoded in |
|---|---|
| `.PaintFrameWrap` → `.WrapCopyToScreen` → `.DoubleBlitUniversal` → `.DoubleBlitPPCParallaxOneLayer` (or `.DoubleBlitPPCParallaxOneLayerFire`, levels 52/55) | RO §1.1 (where, gates), §1.2 (pixel rules), §1.3–§1.5 (row state machine, shipped levels), §1.6 (Fire); flame layer LT §9 |
| `.RedrawScrollGrid` (fills the tile frame only; no parallax) | RO §1.1; FG blend faces LT §8 |
| `.WrapEraseSprites` (dirty-rectangle restore) | DE §1.1 |
| `.WrapDrawSprites` → `.WrapDrawFace` → `.BlitEncFaceX` (dispatch) | DE §1.1, §1.2; mode word → table LT §2; mask buffer DE §1.3 |
| `.BlitEncFaceX` → `.BlitEncFaceSpecialClipX` / `.BlitEncFaceSpecialNoClipX` (table modes 1, 3, 4, 9, 0xc; 0xa squash) | DE §2.2, §2.6 |
| `.BlitEncFaceX` → `.BlitEncFaceTransClip` / `.BlitEncFaceTransFlipClip` (mode 0xb) | DE §2.7; pair tables LT §6.1 |
| `.BlitEncFaceDiffuse` (5) · `.BlitEncFaceWaterRipple` (6) · `.BlitEncFaceBehindTilesClip` (8) · `.BlitEncFaceRot` (rotation/scale) | DE §2.3 · §2.4 · §2.5 · §2.9 |
| `.SetupLevel` → `.SetupOmniPx` → `.TurnOnOmniPx`; per frame `.UpdateOmniPx`; `TurnOffOmniPx` / `KillOmniPx` at level end | RO §3.2 (life cycle), §3.3 (per mode), §3.4 (update), §3.5 (composition) |
| `.NewParticle` → `.HandleParticles` → `.DrawParticles` → `.WrapDrawParticle`; `.EraseParticles` | PA §2, §2.1, §3.1, §3.2, §3.3 |
| `.GammaFade*` / `.TintScreen` / `.TintFadeProc` (Monitor Tool) | LT §10; Titles fades RO §4.3 |

### 2.2 Residual partials (each is in a file's NOT RESOLVED list)

| routine / item | what is still missing | where |
|---|---|---|
| `Color2Index` (Color Manager, via `.BuildTintTable` / `.InitParticleColors`) | the exact palette index chosen for each requested RGB [LOW] | PA §4.3, NR 1; LT §1.2, NR 1–2 |
| `.BlitEncFaceRot`, flipped blitter twins | exact rounding, scale constant; twins checked by slot loads only [MED] | DE NR 3, NR 6 |
| `.WrapDrawWaterEffects` | cell-record fields named by offset only | PA NR 4 |
| `PEDistance` | metric not read | LT NR 6 |
| `MT_FadeToColor` | library internals [MED] | LT §10; RO NR 1 |
| `.STLoopCallBack` | not decoded | §1 above |

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
| Box | 105 types: 1060..1062, 1065 ×89, 1070, 1072, 1080, 1250 ×14, 1308, 1440, 1442 ×25, 1450, 1453, 1461..1464, 1470, 1475, 1490..1493, 2808..2884 (decor), 2902..2911, 2921..2932, 2940 ×43, 2941, 2951..2965, 3070, 3090..3092 | PB §2.2–§2.4; SC §2 (1065); T1 §3 (talkers; conversations CM §1.2); GY §1–§5 (1440, 1442 geysers); ⚑ w2: PB2 §4.3 (1080/1081 = magic carpet), §4.2 (2932/2933 = stalactites), §4.1 (spiked balls 1475/1476), §9 (decoration rows per type) | ~~decoration rows are range-level only (PB §2.2 rows 2805..2889)~~ → per type in PB2 §9 (unplaced list there) |

Record byte +1 is 0 in every active record and is read by no class (EG, EF, EW, B1, PB, T1, PR).

## 4. What the next lane inherits (⚑ rewritten, wave 2 2026-10-04)
The deepening's inheritance (draw effects as the largest shared gap, `.TintFadeProc`) is closed by
wave 2 (§2 above). What is still genuinely open is INDEX "Still genuinely open after wave 2":
- **Palette index choice** (INDEX 15): which index `Color2Index` returns for each requested tint /
  particle colour [LOW] — PA §4.3, LT §1.2 and NR 1–2. Needs a Color Manager inverse-table
  reimplementation or a capture from the original.
- **Geysers NR 2–4** (INDEX 28): Setup re-run on idle→active for a collapsed geyser; kinds 3/4; the
  inert p4 — untouched by wave 2.
- **Slot reuse / drops**: follower-slot reuse frequency in play (INDEX 23, SD2 NR 3, LOW); the
  enemy-drop half of held-item-melee NR 4 (INDEX 29).
- **ContinueGame nil handle** (INDEX 24): outcome past the nil dereference of a missing level — SC §9.3.
- **Intent only** (facts read, replicate as written): music 21/27 (INDEX 4, RO §6.4); vestigial boss
  fields (INDEX 19, B3 §10, NR 4); the 2940 p1 = 0 gate (INDEX 22, T2 §8.5); the as-written tile
  oddities (INDEX 26, P2 §14).
- Not gameplay: the 12 UNCOVERED system callbacks of §1 (`.STLoopCallBack` is the only one a replica
  might need, for looping sounds).
- Contradictions and fixes of the wave: `REVIEW-2026-10-04-wave2.md` (legs A–H) and
  `FIXPASS-2026-10-04-wave2.md`; the deepening's ledger stays summarised in the INDEX review ledger.
