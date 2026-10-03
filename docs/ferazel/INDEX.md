# Ferazel's Wand 1.0.3 — RE bank index

**Register: code readings and data decodes only. Nothing in this bank is behaviour-verified.**
The project owner's eyes are the only behaviour oracle.

## Provenance

| item | value (tool output, this session) |
|---|---|
| binary | `…/Ferazel's Wand/Ferazel's Wand (installed)/files/Ferazel's Wand` (data fork), 680,718 B, sha256 `968bbc67…a7ef4811c6` — byte-identical to `ghidra/Ferazel_pef` (`shasum -a 256`) |
| form | PEF `Joy!peffpwpc`, 3 sections (`tools/pef.py`): code 0x9f83c B (container 0x1500); data = pattern-packed `pidata` 0x55ce B → 0x8169 initialised / 0x239f74 total; loader 0x147c B |
| address map | Ghidra code base 0x10000000; data base **0x1009f840** (code end rounded to 16 — verified by decoding the file-name pstrs at `0x100a31d9` etc.); TOC register r2 = data + 0x8000 = **0x100a7840**; TOC words are unrelocated section offsets (pointer = word + 0x1009f840) |
| decompiler | Ghidra 12.1.3 headless, **language forced `PowerPC:BE:32:default`, cspec `macosx`** (auto-detect picks VLE; the `*.VLE-wrong.c` dump is not used) |
| main dump | `ghidra/Ferazel_pef.decompiled.c`, 64,189 lines; log: `DumpDecompile: wrote 1082/1085 functions` (regenerated for the deepening wave 2026-10-03 with the same recipe: same counts, same line total); `find_func.py '.' --names` → `[1082 function(s) matched]`; 731 dot-names (PEF traceback tables), 58 `FUN_`, rest import glue + `entry` |
| **gap found** | 154 functions reached only through transition vectors (sprite Setup/Handle/Hit/Kill callbacks, AppleEvent handlers, sleep/timer procs) have **no block in the main dump** — Ghidra folded their bodies into the preceding named function and the decompiler never reached them. Found by scanning the data section for `{code offset, TOC 0x8000}` pairs: 161 TVectors, 154 targets without a function (`tools/targets.txt`, names from the next traceback name after each entry point; one has none → `.anon_10060c78`) |
| supplementary dump | `tools/FzDecompTargets.java` (Ghidra post-script) creates functions at the 154 targets, sets r2 = 0x100a7840 over their bodies, decompiles: log `FzDecompTargets: wrote 154/154`; output ~~22k lines~~ **23,917 lines** (`ghidra/Ferazel_handlers.decompiled.c`, regenerated 2026-10-03: `FzDecompTargets: wrote 154/154`) ⚑ corrected (deepening 2026-10-03) (kept out of git like the other dumps; regenerate with the recipe below). Biggest: `.HandlePlayerSprite @ 1004d5fc` (2,257 lines), `.HitPlayerSprite @ 100556f4`, `.HandleBoxSprite`, `.SetupBoxSprite`, `.HandleWalkerSprite`, `.SetupBackgroundSprite`, `.HandlePlatformSprite` |
| raw disasm | `tools/FzDisasm.java` (Ghidra post-script, ranges → listing) — used for `.FindFPS`, `.MTNewSprite`. ⚑ corrected (deepening 2026-10-03): the **whole code section** is now listed: `ghidra/Ferazel_pef.disasm.txt` (FzDisasm over `10000000:1009f83c`, 163,345 lines, `<addr>  <mnemonic> <operands>`; `.word` lines are traceback tables / data; git-ignored). It is the evidence for every raw address cited by the deepening files |
| constants | `tools/const.py <hexaddr>…` reads f32/f64/i32/i16 from the unpacked data section (`tools/pef.py` implements PEF pattern-data unpacking, opcodes 0–4) |
| data files | `$FW = /Users/andiyar/Developer/Ambrosia/Resources/ambrosia-extracted/Action-Adventure/Ferazel's Wand/Ferazel's Wand (installed)/files`; resource forks parsed with `tools/rsrc_census.py` (own map walker) |

Recipe (supplementary dump; the Ferazel Ghidra project must already exist from `ghidra/decompile.sh
Ferazel_pef -processor PowerPC:BE:32:default -cspec macosx`; copy it first if another session holds it):
```sh
AH=/opt/homebrew/Cellar/ghidra/12.1.3/libexec/support/analyzeHeadless
$AH <proj-dir> Ferazel_pef -process Ferazel_pef -noanalysis \
    -scriptPath docs/ferazel/tools -postScript FzDecompTargets.java \
    docs/ferazel/tools/targets.txt ghidra/Ferazel_handlers.decompiled.c   # (this session's copy lives there, git-ignored)
$AH <proj-dir> Ferazel_pef -process Ferazel_pef -noanalysis -readOnly \
    -scriptPath docs/ferazel/tools -postScript FzDisasm.java <out>.txt 100064b0:1000650c
```

## Labels
`[HIGH]` read directly in code, every constant resolved, data path traced. `[MED]` read in code
but one link inferred (struct offset, unnamed callee, assumed constant, or a name taken from the
manual / a PICT name). `[LOW]` pattern inference, string evidence, guesswork from names.
"NOT RESOLVED" = looked for and not determined.

## Topical files

| file | sections | labels present |
|---|---|---|
| `engine.md` | 1 identity ("Mascot", Monitor Tool, runtime libs, Sound Tool; out-of-scope list) · 2 startup · 3 screen/buffers/coordinates/parallax · 4 main loop, frame cap, FPS · 5 camera · 6 state machine, death/continue, chapters, victory · 7 input (actions, defaults, ISp, pause/caps lock, debug keys) · 8 prefs record · 9 saved games + game-globals layout | HIGH, MED, LOW, NOT RESOLVED |
| `world-data-format.md` | 1 numbered files = AIFC music (+ why 21/27 absent) · 2 World Data resources, `Mwld` · 3 `Mlvl`: layout, 70-row header table, tile-cell encodings, sprite placement record, type→class table · 4 progression, `Mmap` graph + unlock rule, CalcPercent/FillPercent · 5 `Mcnv` · 6 open items | HIGH, MED, LOW, NOT RESOLVED |
| `sprites-backgrounds-sounds.md` | 1 PICT-only assets · 2 loaders, face record, RLE encoding · 3 tile sets, FG draw rule, blend faces, overlay · 4 CLUTs, AltClutMod, cooling map/flame · 5 sprite sheets, hot rects, kick rects · 6 `snd ` format, Sound Tool mixer, positional audio · 7 Titles | HIGH, MED, LOW, NOT RESOLVED |
| `physics.md` | 0 sprite fields (+ 0.1 fields merged from the deepening) · 1 LoadLevelPhysics (vestigial) · 2 integration helpers · 3 tile collision (neighbourhood, hot rects, kinds, wall cling) · 4 player constants table · 5 health/breath/hazards/death · 6 wind/currents · 7 enemy classes (HP, gravity, hot rects; 7.1 HP selection rules + pointers) · ~~8~~ → `physics-sprites.md` ⚑ corrected (deepening 2026-10-03) | HIGH, MED, LOW, NOT RESOLVED |
| `physics-sprites.md` | physics §8 moved, numbering and text kept (2026-10-03 split at ~650 lines): 8.1 sprite solids/PlatformBounce · 8.2 ropes · 8.3 springs · 8.4 FootPressure · 8.5 programmed paths · 8.6 flotation + quicksand · 8.7 landing effects · 8.8 panting · 8.9 platform modes — with deepening corrections in place | HIGH, MED, LOW, NOT RESOLVED |
| `spells-items.md` | 1 inventory model · 2 casting + spell table · 3 pickups · 4 items · 5 power-ups · 6 HUD, WandGlow | HIGH, MED, LOW, NOT RESOLVED |
| `enemies-ground.md` (deepening) | 1 census · 2 shared (contact damage, Statue spell + `.HandleStatueSprite`, hit tests, liquids, death bookkeeping, sounds) · 3 Walker 1700/1705/1750/1760 (setup by p3 tier, states, hits, death, coins) · 4 Crawler · 5 Roach · 6 Dillo · 7 projectiles · 8 unplaced variants · NR · §0 proposals · corrections | HIGH, MED, LOW, NOT RESOLVED |
| `enemies-flyers.md` (deepening) | 1 shared (helpers, enemy counting / stat, contact damage, sounds) · 2 census · 3 Bat class (setup by sub-range, chaser AI, path bats, swarm, insects, damage, variants) · 4 Gremlin (body, rider) · 5 Floater = Wraith · 6 placement params · NR · §0 · corrections | HIGH, MED, LOW, NOT RESOLVED |
| `enemies-water-cave.md` (deepening) | 0 census · 0.1 shared · 0.2 `+0xb8` tints · 0.3 `.HandleBurn` · 1 Frog (p1 variants, states, spit) · 2 Salamander · 3 Blob · 4 Crab · 5 Statue on these · 6 contact damage · NR · §0 · corrections | HIGH, MED, NOT RESOLVED |
| `bosses.md` (deepening) | 1 shared boss framework (params, spawn timing, "no boss alive" flag, arena lock/camera, what a kill triggers, what hurts each boss, damage dealt, sounds) · 2 Warrior · 3 Wizard · 4 Goblin Chief | HIGH, MED, LOW |
| `bosses-2.md` (deepening) | 5 Fire Guardians (Demon) · 6 Xichra (phases, states, damage, kill) · 7 boss projectiles · NR · §0 · corrections | HIGH, MED, LOW, NOT RESOLVED |
| `enemy-shots-and-damage.md` (deepening) | 1 EnemyShot class (lifecycle, type table, collisions, spawn sites, homing, kill effects) · 2 cannons, statues, trails, shadow double · 3 the player's damage intake (`.HitPlayerSprite` dispatch order, Box/hazard/generic arms, `.ShieldBlock`, `.HurtPlayer`, stun/death) · NR · §0 · corrections | HIGH, MED, LOW, NOT RESOLVED |
| `pickups-boxes.md` (deepening) | 1 Bonus class (setup, pickup gate, type table, containers, spheres, scrolls, items, drops, persistence, census) · 2 Box class (type table, talkers, crates, chests, doors, gates, switch blocks, ledges, teleporters, save point, Tree Trunk, geysers, trampoline) · 3 held item, thrown seeds, non-spell shot ids · NR · §0 · corrections | HIGH, MED, LOW, NOT RESOLVED |
| `triggers-background.md` (deepening) | 0 census · 1 Button · 2 Background (common setup, cannons, springs, fire, bars/spiked balls, spikes, urchins, arrow traps, plants, clouds, passages, wall tunnels, rotating sword, trees, level exit) · 3 triggers outside the class | HIGH, MED, LOW |
| `triggers-background-2.md` (deepening) | 1 chains + see-saw segments · 2 Effect class (effect-id table, crumble overlay) · 3 countdown timer + digits · 4 parallax strip sprites (hdr 0x2716/18/1a) · 5 NR (both parts) · 6 §0 · 7 corrections | HIGH, MED, LOW, NOT RESOLVED |
| `spells-detail.md` (deepening) | 1 spell ids → names (HUD art) · 2 casting trigger, wand animation, `.CastSpell`, power · 3 player-shot flight per id, tile hits, Ice Wall floes/ledges, Tree Trunk, spell 7, sprite hits, non-spell shots · 4 MP regeneration · 5 hang glider · NR · §0 · corrections | HIGH, MED, LOW, NOT RESOLVED |
| `save-continue.md` (deepening) | 1 New Game · 2 save points (the only save writer) · 3 saved-game file + layout (supersedes engine §9 table) · 4 Resume/Continue · 5 death → continue · 6 Esc/abort/menus · 7 what is not persisted · 8 INDEX items 8, 9, 2, 13 · NR · corrections | HIGH, MED, LOW, NOT RESOLVED |
| `platforms-ropes-radial.md` (deepening) | 1 radial geometry (tables, block, per-frame, wheels, wall bounce, spokes) · 2 platforms (setup per type, radial modes, mode-4 floes, corpse platform, Hit/HitTile, visual stages, census) · 3 ropes (types, span, sag curves, census, rope bridge) · 4 springs leftovers + `_DAT_100a0678`/`0718` · 5 player `+0x19e` · 6 crunch arg order · 7 hot-rect tables · NR · §0 · corrections | HIGH, MED, NOT RESOLVED |
| `player-states.md` (deepening) | 0 conventions · 1 per-frame order of `.HandlePlayerSprite` · 2 state globals · 3 state selection (glider, dying, spirit, boss grab, stun, doors, rope, swim, cling, melee, grounded, airborne) · 4 inputs · 5 jump/spin/swim/wall jump · 6 facing · 7 face sets, hot rects · 8 initial state | HIGH, MED, LOW |
| `player-states-2.md` (deepening) | 9 `.WallBounce` (pre-processing, full kind table, composites) · 10 `.HitPlayerTileSprite`, `.WallBounceBG` · 11 kind census of the 24 levels · NR · §0 · corrections | HIGH, MED, NOT RESOLVED |
| `geysers.md` (deepening gap file, review 1a #4) | 1 census + type map (1440..1449 → 0x5a0 / 0x5a5 triple / 0x5a9 head) · 2 setup (params, caches, children) · 3 eruption cycle (level-frame phase, rise/fall rules, worked table) · 4 `.HandleGeyserColumn` (segments, head, solidity, tints, particles, idle) · 5 triple re-targeting · 6 sound (none played) · 7 contacts (player, enemies, boxes) · NR · §0 · corrections | HIGH, MED, LOW, NOT RESOLVED |
| `held-item-melee.md` (deepening gap file, review 1b #11) | 1 held-item sprite (creation, swing start, the 10-frame swing, `.SetHeldItemPos`, hit geometry, state interactions, what a strike does — c = 3..5, `+0xa6` never set, seeds in hand, no carrying) · 2 Shadow Double 0x1b39 · 3 Double-Speed trail · NR · §0 · corrections | HIGH, MED, NOT RESOLVED |
| `coverage.md` (deepening synthesis) | 1 the 154 targets → file § (140 covered, 1 partial, 13 uncovered system callbacks) · 2 cited helpers, name-only list · 3 placed-type census vs explanation (243 types) · 4 inheritance | coverage only (no readings) |
| `tools/` | `pef.py`, `const.py`, `tocrefs.py`, `rsrc_census.py`, `gensprite_map.py`, `FzDecompTargets.java`, `FzDisasm.java`, `targets.txt`, `fer_names.txt` | scripts only (no game data) |

**Append rule:** new findings go into the topical file they belong to, plus one line in this
index (NOT-RESOLVED list or a new row above). Never grow a monolith; split a file that passes
~600 lines.

## Resource census (tool: `tools/rsrc_census.py`, run this session)

Common Finder/bundle types (`ICN#`, `icl4/8`, `ics#/4/8`, `BNDL`, `FREF`, `SIZE`, `cfrg`,
`vers`) omitted from the rows but counted in the totals.

| file (resource fork) | bytes | resources / types | type: count, size range, id range |
|---|---|---|---|
| `Ferazel's Wand.rsrc` (app) | 264,712 | 164 / 28 | ALRT 2 (14) 500–501 · CNTL 7 (23) 128–605 · DITL 30 (2–560) · DLOG 20 (21–34) 150–6900 · MBAR 1 · MENU 9 (49–89) 128–605 · Msct 1 · PICT 5 (2,754–181,550) 145–7000 · STR# 2 (347–725) 300, 400 · Tune 1 (29,580) 6900 · WIND 1 · clut 6 (2,056) 198–4000 · dctb 14 · isap 1 · setl 1 (200) · tset 2 (44–152) 128, 256 · wctb 1 |
| `Ferazel's Wand World Data.rsrc` | 5,511,430 | 60 / 7 | **Mcnv 29 (36,936) 200–401 · Mlvl 24 (52,140–328,348) 1–70 · Mmap 1 (38,144) 200 · Mwld 1 (70,664) 0** · PICT 1 (181,212) 7000 · STR# 2 (499–1,729) 500, 1000 · vers 2 |
| `Ferazel's Wand Backgrounds.rsrc` | 15,821,213 | 194 / 7 | PICT 113 (2,014–539,168) 200–24069 · TEXT 1 · VWCI 1 · cicn 19 (130–1,642) 200–10137 · clut 57 (2,056) 198–4000 · icns 1 · vers 2 |
| `Ferazel's Wand Sprites.rsrc` | 10,028,422 | 587 / 3 | PICT 584 (220–436,884) 160–14850 · icns 1 · vers 2 |
| `Ferazel's Wand Sounds.rsrc` | 2,448,841 | 175 / 3 | `snd ` 172 (557–79,146) 128–8030 · icns 1 · vers 2 |
| `Ferazel's Wand Titles.rsrc` | 4,005,325 | 86 / 4 | PICT 67 (2,520–270,072) 128–4985 · clut 16 (2,056) 128–729 · icns 1 · vers 2 |
| `Ferazel's Wand Documentation.rsrc` (a DOCMaker-style app, creator `Dk@P`) | 3,878,232 | 255 / 40 | CODE 9 · PICT 63 (400–543,288) 128–2065 · TEXT 7 (942–7,258) 128–134 · styl 7 · pInf 78 · conp 18 · DITL 6 · DLOG 5 · STR 11 · STR# 2 · … (40 types) |
| `01.rsrc` … `30.rsrc` (28 files, all identical in shape) | 4,565 each | 4 / 4 | PRNT 1 (120) · STR 1 (24) · WNDW 1 (8) · icns 1 (4,031) — SoundEdit 16 leftovers |
| `Ferazel's Wand 1.0.3 Notes.text.rsrc` | 332 | 1 / 1 | styl 1 (22) |

Data forks: `World Data`, `Backgrounds`, `Sprites`, `Sounds`, `Titles`, `Documentation` are 0 B.

### Music files `01`..`30` (Python COMM-chunk decode, this session)
28 files present; **21 and 27 absent** in both `files/` and the installer manifest. All: AIFC,
2 channels, 16-bit, 22,050 Hz, compression `ima4`. Lengths (s): 01 82.6 · 02 78.2 · 03 70.5 ·
04 59.8 · 05 87.9 · 06 71.9 · 07 71.9 · 08 65.9 · 09 140.8 · 10 68.6 · 11 64.2 · 12 61.1 · 13 89.2
· 14 64.0 · 15 51.5 · 16 66.4 · 17 62.7 · 18 91.9 · 19 65.5 · 20 72.0 · 22 76.9 · 23 65.2 · 24 94.0
· 25 55.7 · 26 67.2 · 28 60.9 · 29 55.9 · 30 52.1. Use and the 21/27 reading: world-data-format.md §1.

## Data appendix

Levels (`Mlvl` id → name; header fields per level are tabulated in world-data-format.md §3.2):
1 A Scent Of Peril · 2 Central Caverns · 3 Western Reaches · 4 Eastern Reaches · 5 Manditraki
Warrior · 10 Unemployed In Greenland · 11 River of Fears · 15 Storm Valley · 18 Goblin Chief ·
20 Hangnabit · 21 Obfuscation & Edification · 22 The Labyrinth · 25 Manditraki Wizard · 30 Flash
Freeze · 31 Iceconoclasm · 40 Parched Earth · 45 The Dig · 50 Fire In The Hole · 51 If You Can't
Stand The Heat… · 52 Out of the Frying Pan · 55 Fire Guardians · 62 Ends of the Earth · 67
Xichra's Lair · 70 Purple Haze. `STR# 1000` also names 32 "Ice Caverns 3", 35 "Ice Boss",
60 "Mountains" with no `Mlvl` (cut levels) [HIGH for absence].

Map nodes (`Mmap 200`, node → level, links): 1→1 {2} · 2→2 {1,3,4} · 3→3 {2} · 4→4 {2,5} ·
5→5 {4,10} · 10→10 {5,11,15} · 11→11 {10,18} · 15→15 {10,20,30} · 18→18 {11,40} · 20→20
{15,21} · 21→21 {20,22,70} · 22→22 {21,25} · 25→25 {22} · 30→30 {15,31} · 31→31 {30} ·
40→40 {18,45,60} · 45→45 {40,50} · 50→50 {45,51} · 51→51 {50,52} · 52→52 {51,55} · 55→55
{52} · 60→62 {40,62} · 62→67 {60} · 70→70 {21}.

## Out of scope (identified only)
CD/installation check (`.main`, `Installer Data` on the CD, machine hash in prefs) · author
birthday dialog (`.DateChecks`) · debug/cheat keys and FPS display (engine.md §7.3) · warp
dialog · loading a third-party world file (`.OpenWorld` with `PromptGetFile('Mwld')`) ·
AppleEvent handlers · movie capture (`.HandleMovieCapture`) · resolution switching
(`.ResSwitch`, Monitor Tool) · InputSprocket configuration UI · QuickTime music plumbing beyond
"play file NN looped".

## NOT RESOLVED (consolidated)
⚑ corrected (deepening 2026-10-03): items 1–14 keep their numbers; "→ closed: file §" marks an item
the deepening wave answered (reviewed — legs 1a/1b/1c below, all fixes applied), "narrowed" keeps what remains. New
sub-items from the deepening files are items 15–29 (⚑ corrected (review 1d, 2026-10-03) #2). Contradictions between files:
`coverage.md` §4 and the review ledger.
1. ~~Per-class meaning of sprite placement params 1–4 and record byte +1 (world-data §3.4).~~
   → closed: per-class table in world-data §3.4 (every placed class; the readings live in the class
   files); byte +1 is 0 in every active record and read by no class (coverage.md §3). Left: the
   decoration rows 2805..2889 are range-level only (pickups-boxes §2.2).
2. Header fields 0x26c7 (OmniPx modes), 0x26c8 (copied to G+0x16), 0xb270..0xb276; PxMid cell
   0xFFFF handling (world-data §3.2/3.3). → **narrowed**: 0x26c8 closed (player starts facing
   left), 0xb270..0xb276 closed (zero, unread; the bank misread them) — save-continue §8.3,
   world-data §3.2. Left: 0x26c7 draw composition per mode; what the blitter draws for PxMid −1
   (the code reads entry [−1] of the PxMid tables, no test) — save-continue §8.3, NR 3–4.
3. `Mcnv` response/action encoding (world-data §5). Unchanged; also whether conversations grant
   items or spells (pickups-boxes NR 7).
4. Why music 21/27 were not shipped (only "never referenced" is established). Unchanged.
5. ~~`.WallBounce` cases 0xc..0x1f, 0x24..0x2f, 0x32..0x3b; `.WallBounceBG`; the unused-looking
   hot-rect tables at `DAT_100a4794+0xc` and `DAT_100a4314` (physics §3).~~ → closed:
   player-states-2 §9–§11 (every kind, composites, `.WallBounceBG`, census); tables:
   platforms-ropes-radial §7 and player-states-2 corrections (`+0xc` only in a dead loop; the
   per-tile rect is indexed by kind). Left: readers of FG kinds 0x4e/0x4f and BG kinds 400..495;
   `.CrunchTile`'s return value (player-states-2 NR 1–2).
6. ~~Enemy behaviour patterns (22 Handle routines), variant selection of enemy HP (physics §7).~~
   → closed for all 16 enemy and boss classes: enemies-ground, enemies-flyers,
   enemies-water-cave, bosses, bosses-2; HP selection rules physics §7.1; projectiles and contact
   damage enemy-shots-and-damage. Left: items 15–20.
7. ~~Glider physics in detail (physics §4).~~ → closed: spells-detail §5. (The deep-liquid factor
   `dRam100a1a30` = 0.65, physics §4 ⚑ corrected (review 2026-10-03) #6.)
8. ~~`G+0x12` (= 3 at new game) reader; whether any lives concept exists (engine §6).~~ → closed:
   write-only, no lives (save-continue §8.1).
9. ~~Prefs +0x142 block; exact meaning of prefs +0x02/+0x04/+0x06 levels (engine §8).~~ → closed:
   +0x02 Graphics, +0x04 Parallax (no shipped control), +0x06 Effects, +0x32/+0x34 resolution
   switch, +0x142 write-only (save-continue §8.2; engine §8).
10. Lighting/tint table algorithms (`.CalcLightingTable`, `.Build*Table`), blend mixing
    arithmetic, flame rule (sprites §3.2, §4). Unchanged — and now the blocker of every tint colour
    the class files name (item 15).
11. ~~Spells 2 and 7 (unnamed, never granted by the debug kit): whether any shipped scroll
    grants them; item ids 0x12 (Hammer?) and 0x14 names (spells-items §2.1, §4).~~ → closed:
    scrolls grant 1, 5, 4, 2→3, 6; 2 and 7 are never granted (pickups-boxes §1.7); names from the
    HUD art — 2 "Ice Crystals", 7 a second "Ice Wall"; 0x12 Ice Pick, 8 Hammer, 0x14 Light Orb
    [MED names] (spells-detail §1, pickups-boxes §1.8).
12. Use sites of most Titles PICTs (sprites §7). Unchanged.
13. ~~Resource-chain winner for `PICT 7000` (app fork vs World Data).~~ → closed [MED]: the app
    fork's copy (save-continue §8.4). Left: contents of the CD's `Installer Data`.
14. ~~Non-enemy sprite physics remainder (physics §8, added by the review fix pass): radial
    geometry `.MakeRadial` / `.UpdateRadialPos` / `.UpdateRadiusSprites` / `.RadialWheelStep`;
    `.HitPlatformSprite`; rope types 3023..3039 (no parameters set); the `.glue::pow` exponent of
    the rope sag curve; the installer of `.GetRopeBridgeHeight` (table `_DAT_100a0a00`); the
    spring cooldown decrement and the class excluded by `PTR_PTR_100a0460`; the player's `+0x19e`
    writes in `.HandlePlayerSprite`; meanings of `_DAT_100a0718` and of the `_DAT_100a0678 = 1`
    springs write; who sets platform mode 4 on a spell-spawned ice floe; platform visual-stage
    fields `+0x88`/`+0xb8`; the arg order of `.GetFGCrunchDirTile` (engine §9 crunch pairs).~~
    (physics §8 is now `physics-sprites.md`) → closed: radial geometry
    (platforms-ropes-radial §1), `.HitPlatformSprite` (§2.6), rope types 3023..3039 armless (§3.2),
    `pow` exponents (§3.4), `.GetRopeBridgeHeight` installer = Box 1466 (§3.7), spring cooldown
    and excluded class = Effect (§4, triggers-background §2.3), player `+0x19e` (§5),
    `_DAT_100a0678` = jump base J (§4), `_DAT_100a0718` = air-animation counter (player-states
    §3.12; the platforms file's "launch latch" was withdrawn — review 1b #1, Critical), floe mode 4 set by
    the shot code (spells-detail §3.4), `+0x88`/`+0xb8` writes (platforms §2.8), crunch-pair order
    (y,x) HIGH (§6). Left: item 25.
15. Draw effects (shared by six files): `+0xb8` modes 1, 3/4, 7, 8, 9, 0xb, 0xc, 0x10..0x13 as
    pixels; ~~the `+0x88` draw gate~~ (closed: light-overlay gate, physics §0.1 ⚑ corrected (review 1c, 2026-10-03) #5); colours of remap /
    tint tables 2/3/4/0xb/0xc/0xf/0x10..0x15/0x17/0x18; `.HandleBurn` row arithmetic and styles
    1 vs 0xd; `.BloodSpray` / `.NewParticle` arguments (enemies-ground NR 1–2, enemies-flyers NR 1/6,
    enemies-water-cave NR 3–4, bosses-2 NR 1, platforms NR 1, triggers-background-2 NR 1/5,
    spells-detail NR 1).
16. enemies-ground: Walker corpse used as a platform — floats or sinks; Crawler/Roach `+0xa6`
    consumers; `FUN_100916dc`/`FUN_10091504` sound helpers [MED].
17. enemies-flyers: `+0x84/+0x86` purpose; `.STPlay3DSoundRand` pitch; the `+0xa6 += 0x45` guard;
    `+0x1b2` setter (narrowed: `.HandleBoxSprite`, enemies-water-cave NR 8); visibility of children
    left active while a parent is idle.
18. enemies-water-cave: Salamander `+0xa6 = 21` and crush `+0x150 = 0x16` readers; `.GetBGTile`
    argument order (Crab water test); whether the dead Frog/Salamander water blocks were live in
    another build.
19. bosses / bosses-2: Xichra cannons (Background 0x442..0x44a values); hdr+0x2730 modes 3..7 on
    screen; ~~whether a player shot ever has `+0xa6 ≠ 0`~~ (closed: no code writes a non-zero `+0xa6`
    on the held item, and the strike frames are c = 3..5 — held-item-melee §1.3, §1.7; ⚑ corrected (review 1c, 2026-10-03) #10); 0x6d6 minions with p3 = 4; vestigial fields (Wizard state 11, Chief `+0xb2`,
    Warrior `+0x154`, p2 = 150); level-55 reach beyond x 15940; the Demon type write.
20. enemy-shots-and-damage: spawner of 0x46b/0x46c; writer of 0x77b's `+0x14c`; setter of the
    input lock `_DAT_100a0570` (also spells-detail NR 3); `+0x1aa` on the Gremlin spit; active-list
    order (bomb splitting twice; 0x6a9 collidable twice); `.WallBounce`'s 0xa0 argument;
    shadow-double flags `PTR_DAT_100a0674`, `_DAT_100a06d0/06d4`.
21. pickups-boxes: `snd ` ids behind several TOC handles; readers of Bonus `+0x168` (p4 = 1 on five
    1291); gate byte 0x100a53d6, `_DAT_100a069c`, `PTR_DAT_100a0708`; ~~`.HandleGeyserColumn`
    geometry and liquids, 0x5a9 creation~~ (closed: geysers.md §1, §4; ⚑ corrected (review 1c, 2026-10-03) #10); spiked-ball PICT, the 2932 object, 1080's 1-px rect;
    falling-rock `+0x160 < 0` setter; door `+0xa0`; effect 0x4b7 against enemies.
22. triggers-background(-2): cannon `+0x154 = 6` and sprite type 90 (re-entry itself closed:
    `.StandardSpriteHandles` counts a negative `+0x130` up, raw 10036894..100368a4); passage
    globals `*_DAT_100a06f0`, `_DAT_100a05f8`, `_DAT_100a0680`, `PTR_DAT_100a05f0`; spawners of
    effects 1202..1205, 1251, −1; Button 1323..1329 rects; gate-link search completeness; gate
    2940 with p1 = 0 reading record 0 (intent; 2941 is a destructible wall that ignores p1 — ⚑ corrected
    (review 1b, 2026-10-03) #2, triggers-background §1); idle activation rule; wind orientation (no
    sprite emits wind — physics §6 stays MED).
23. spells-detail: on-screen test fields `+0x1b6/+0x1b8` (narrowed: left/right draw-clip edges, physics
    §0.1) and face `+0xa/+0xe`; `_DAT_100a06f0`,
    `PTR_DAT_100a0700`, `PTR_DAT_100a04cc`, `_DAT_100a075c`; Boomerang steering `FUN_1003f218`;
    same-frame handling of new shots; orphaned followers and slot reuse [LOW].
24. save-continue: save-point face for p1 = 1 vs 2; exact hold-frame timing; OmniPx composition
    and PxMid −1 (item 2); CD `Installer Data`; `OpenDefaultWorldLevel` failure inside ContinueGame.
25. platforms-ropes-radial: `_DAT_1009fd30`, `_DAT_100a067c`, `*psVar26` in the J reset; platform
    `+0x190`; within-frame order of sibling wheel/see-saw updates; wall-ice face 1 vs 2. (Its NR 5
    play check on `_DAT_100a0718` is answered from raw — review 1b #1; closed in that file.)
26. player-states(-2): PICT 1026 loader; the 5 type-1 trail sprites and `PTR_DAT_100a06bc`; intent of
    the as-written oddities a replica copies anyway (kind-indexed tile rect, kind 0x13's absolute-y
    test, BG 0xc's vy-for-vx, the 0x2c..0x2f ice rules).
27. ~~Field semantics from the synthesis ledger: `+0x1b6..+0x1bc` (edges vs extents), the order of
    `+0x1be..+0x1c4`, `+0x1a2` reuse on reflected shots, and whether other classes read `+0x11c`
    before their own tile pass (physics §0/§0.1).~~ → closed by review 1c from raw (physics §0/§0.1,
    ⚑ corrected (review 1c, 2026-10-03) #3/#4/#6/#7): edges in face-local px; xmin/xmax/ymax/ymin; `+0x1a2` is the burn row and a
    Magical-Shield-reflected shot burns away; the Gremlin's water block is dead too, Walker/Platform lag
    one frame, the Bat copies the previous frame's value.
28. geysers: `.NewParticle` arg 4; colours of particle kinds 200–202; whether idle→active re-runs
    Setup for a collapsed geyser; intent of kinds 3/4 and of the inert p4 (geysers.md NR 1–4).
29. held-item-melee: face mirroring within 32 px (§1.5); active-list order player vs held sprite; door
    `+0xa0`; whether conversations/drops grant Ice Pick / Vorpal Dirk / Hammer; revive vs a frozen
    swing (held-item-melee.md NR 1–4, 6).

## Reviewer notes (attack first)
- Decompiler trap met once already: 8-byte copy loops written as `p[2] = q[2]` after
  `p = base−8`/`base+0x10` hide a +8 offset (`lwzu/stwu` pre-increment). The save layout
  (engine.md §9) was corrected against raw disasm; the same idiom appears in `.SetupLevel`,
  `.ContinueGame`, `.OpenWorld` (FSSpec copies) — re-check any offset derived from such a loop.
- "LoadLevelPhysics is vestigial" rests on a TOC-load scan; an indirect address would defeat it.
- Spell id → manual name mapping (Statue = 1, Ice Wall = 3, Tree Trunk = 4, Boomerang = 5,
  V Blade = 6) is behaviour-derived from code, not from strings. (Deepening: the HUD art `PICT 700`
  captions agree and add 2 "Ice Crystals", 7 a second "Ice Wall" — spells-detail §1 [MED].)
- ⚑ (deepening 2026-10-03) **A TOC-load count is not a write count.** A function may load a TOC
  slot once into a callee-saved register and store through it many times: `tools/tocrefs.py
  100a0718` shows one hit in `.HandlePlayerSprite` (`1004d648 lwz r27,-0x7128(r2)`), yet that
  function stores to the global 13 times through r27 (`sth …,0x0(r27)` between `1004e64c` and `1005073c`). Any "no writer / never decays"
  claim built on `tocrefs.py` must follow the loaded register through the function.
  **Recurring** (2026-10-03 reviews): `tools/tocrefs.py` lists TOC **loads**, not uses — a slot loaded
  once into a callee-saved register is written many times. It produced the deepening's only Critical
  (review 1b #1, the `0x100a0718` "never-decaying latch" in platforms-ropes-radial §4, withdrawn).
- ⚑ (review 1c, 2026-10-03) **`.StandardSpriteHandles` zeroes per-frame fields.** SSH (`10036854`)
  zeroes `+0x11c` (copying it to `+0x120`, `100369ac`), resets the draw clips `+0x1b6..+0x1bc`
  (`100368a8..100368bc`) and the latch `+0x180` every frame, so "handler reads `+0x11c`" means
  nothing without the **call order**: a read after SSH and before the class's own tile pass sees 0.
  Met three times (Frog/Salamander, then the Gremlin's second SSH at `1008061c`, review 1c #4; the
  water-gravity branch of `.ApplyGravityAndSeparateFromTiles`, review 1a #2).
- ⚑ (deepening 2026-10-03) **Signed-compare idiom.** Ghidra renders
  `eqv; subfc; rlwinm 1,31,31; addze; rlwinm 0,31,31` (= `rB < rA` signed) as
  `(uint)(x <= y) - (~(int)(x ^ y) >> 0x1f) & 1`; read alone, the first term gives the opposite
  answer whenever the operands share a sign (enemies-ground.md header; used to settle the gate
  p1 = −2 test at 1006f538..1006f560).

## Review ledger

**2026-10-03 — Fable review, verdict ACCEPT_WITH_FIXES** (12 findings: 3 Important, 9 Minor;
full text `REVIEW-2026-10-03.md`; fix-pass summary `FIXPASS-2026-10-03.md`). Every fix is
marked `⚑ corrected (review 2026-10-03) #n` at its place. "Verified OK" items were not re-checked.

| # | sev | finding | landed |
|---|---|---|---|
| 1 | Important | `G+0x176` is set by `.SavePointSave` too ("checkpointed or completed"), with `.SetupLevel` restore-vs-first-visit and chapter-gate consequences | engine.md §6 (chapter screens) + §9 (G layout + consequence block); world-data-format.md §3.2 row 0x273c + §4.1 |
| 2 | Important | no coverage of non-enemy sprite physics | physics.md new §8 (8.1 PlatformBounce/RectBounce, 8.2 ropes/RopeCollide, 8.3 SuperSpring, 8.4 FootPressure — ground hugging, not pressure plates, 8.5 programmed paths, 8.6 HandleFlotation 0.93/0.86 + quicksand, 8.7 CheckGroundCeilingHitEffects, 8.8 HandleBreathing, 8.9 platform modes); new §0 rows +0x46/+0x138..13c/+0x185/+0x186/+0x194/+0x1e8; §4 rope-state note; NOT-RESOLVED 14 |
| 3 | Important | `.SetupPlayerShotSprite` rewrites shot +4 → spell id, +0x170 → power; statue test is id 1 | spells-items.md §2 items 3 and 7, §2.1 Statue row; physics.md §0 (+0x04, +0x170) and §7 |
| 4 | Minor | `STR# 500` string 12 is "Sparkly torches…", spin-jump hint is 13 | world-data-format.md §3.4 worked decode |
| 5 | Minor | prefs +0x42 default is "@@@@@" (0x100a3193); "Preferences" is the resource name | engine.md §8 |
| 6 | Minor | `dRam100a1a30` = 0.65 | physics.md §4; NOT-RESOLVED 7 closed for that part |
| 7 | Minor | field table missing +0x48 / +0x170 / +0x19e / +0x1a0 | physics.md §0 |
| 8 | Minor | cite the BG-kind level census for liquid labels (kind 5 = quicksand) | physics.md §4 + §5.1; spells-items.md §5 |
| 9 | Minor | prefs defaults +0x32 = 0, +0x34 = 1, +0x3c/+0x3e/+0x40 = 0 | engine.md §8 |
| 10 | Minor | `Mcnv` framing: offsets are relative to `Mcnv + i·0x72a`; record-relative text +0 / speaker +0x100 / pic +0x70a | world-data-format.md §5 |
| 11 | Minor | breath row: cite handler lines; `.ShouldEmitBubbles` = `0 < s+0x120 < 0xf` | physics.md §5.1 (and the §0 `+0x11c` row re-read in the fix pass) |
| 12 | Minor | crunch-pair "(y,x)" rests on unread callee arg order | engine.md §9, labelled MED; NOT-RESOLVED 14 |

(Row 2: physics §8 now lives in `physics-sprites.md`, numbering kept — deepening split.)
(Review-ledger references "synthesis ledger A1..B26" and "adjudication An/Bn" resolve to the
appendix and leg-1c table of `REVIEW-2026-10-03-deepening.md`.)

**2026-10-03 — Deepening wave (RE lane), reviewed: ACCEPT_WITH_FIXES on all three legs, fixes
applied.** Eleven readers wrote 14 new topical
files (`enemies-ground`, `enemies-flyers`, `enemies-water-cave`, `bosses`, `bosses-2`,
`enemy-shots-and-damage`, `pickups-boxes`, `triggers-background`, `triggers-background-2`,
`spells-detail`, `save-continue`, `platforms-ropes-radial`, `player-states`, `player-states-2`) against
the regenerated dumps and the new full raw listing (Provenance). The synthesis pass wrote
`coverage.md` (140 of 154 targets covered, 1 partial, 13 non-gameplay callbacks uncovered; all 243
placed types explained), split physics §8 into `physics-sprites.md`, and applied the cross-file
updates to the existing files, each marked `⚑ corrected (deepening 2026-10-03)` with a pointer to the
new file § that carries the evidence. Contradiction ledger: 41 entries (15 between new files, 26
against the bank); 16 settled from raw disassembly or data by the synthesis pass, 11 consistent /
wording only, 14 left OPEN for the reviewers (items 15–27 above hold the field-level ones). Four
new-file fixes are pending because the synthesis pass may not edit those files:
(A1) platforms-ropes-radial §4 / NR 5 / corr. 9 — `_DAT_100a0718` is the air-animation counter,
not a never-decaying latch (raw: `1004d648` loads the slot into r27; `sth …,0(r27)` stores 0 at
`100500c4`, `100505d4`, `1005073c`; player-states §3.12 is right); (A2) triggers-background-2
§2.2 and its physics §5.1 row — only **non-Box** type-1440 sprites hurt (the Box arm of
`.HitPlayerSprite` returns first, handler dump l. 3859–4214; enemy-shots-and-damage is right); (A3)
enemies-flyers §1.3 — dead attackers do **not** hurt (`.HurtPlayer` refuses HP < 1 unless enemy shot
or box, raw `10054768..10054798`); (A4) platforms-ropes-radial §4 — springs 1154..1159 are inert,
not "fire once" (triggers-background §2.3). Two gap files were then written for review findings
1a #4 and 1b #11: `geysers.md` and `held-item-melee.md`.

Reviewer verdicts (Fable reviewers; full texts `REVIEW-2026-10-03-deepening.md`, with the synthesis
ledger as its appendix; fix summary `FIXPASS-2026-10-03-deepening.md`):
- **Leg 1a — ACCEPT_WITH_FIXES**, 0 Critical / 4 Important / 6 Minor, over seven files
  (enemies-ground, enemies-flyers, enemies-water-cave, enemy-shots-and-damage, pickups-boxes,
  spells-detail, save-continue). Important: dead attackers do not hurt (A3); the water-gravity branch
  is unreachable on a first call; the save point is a Box-arm landing, not a Bonus gate; geysers had no
  coverage (→ `geysers.md`). Fixes marked `⚑ corrected (review 1a, 2026-10-03) #n`.
- **Leg 1b — ACCEPT_WITH_FIXES**, 1 Critical / 3 Important / 9 Minor, over seven files (bosses,
  bosses-2, triggers-background, triggers-background-2, player-states, player-states-2,
  platforms-ropes-radial). The Critical was the `0x100a0718` latch misreading (A1; it is the air
  animation counter). Important: 2941 is a destructible wall, not a switch gate; wall-jump vy −3637;
  the boss-music hdr+0x2724 gate. Gap: held item / shadow / trail (→ `held-item-melee.md`). Marked
  `⚑ corrected (review 1b, 2026-10-03) #n`.
- **Leg 1c — ACCEPT_WITH_FIXES**, 0 Critical / 4 Important / 11 Minor, over the synthesis edits, the
  14 OPEN contradictions (all adjudicated from raw: A2, A4, A8, A10–A12, B4 tail, B16–B25) and the
  two gap files (both hold). Important: wall jump −3637 not −3610 in physics §4; any 300-damage
  player shot breaks 2941 (not only the Ice Pick); `+0x1a2` is one field — reflected shots burn; the
  Gremlin's water block is dead code. Marked `⚑ corrected (review 1c, 2026-10-03) #n` or
  `(adjudication An/Bn)`.
