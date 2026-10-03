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
| main dump | `ghidra/Ferazel_pef.decompiled.c`, 64,189 lines; log: `DumpDecompile: wrote 1082/1085 functions`; `find_func.py '.' --names` → `[1082 function(s) matched]`; 731 dot-names (PEF traceback tables), 58 `FUN_`, rest import glue + `entry` |
| **gap found** | 154 functions reached only through transition vectors (sprite Setup/Handle/Hit/Kill callbacks, AppleEvent handlers, sleep/timer procs) have **no block in the main dump** — Ghidra folded their bodies into the preceding named function and the decompiler never reached them. Found by scanning the data section for `{code offset, TOC 0x8000}` pairs: 161 TVectors, 154 targets without a function (`tools/targets.txt`, names from the next traceback name after each entry point; one has none → `.anon_10060c78`) |
| supplementary dump | `tools/FzDecompTargets.java` (Ghidra post-script) creates functions at the 154 targets, sets r2 = 0x100a7840 over their bodies, decompiles: log `FzDecompTargets: wrote 154/154`; output 22k lines (kept out of git like the other dumps; regenerate with the recipe below). Biggest: `.HandlePlayerSprite @ 1004d5fc` (2,257 lines), `.HitPlayerSprite @ 100556f4`, `.HandleBoxSprite`, `.SetupBoxSprite`, `.HandleWalkerSprite`, `.SetupBackgroundSprite`, `.HandlePlatformSprite` |
| raw disasm | `tools/FzDisasm.java` (Ghidra post-script, ranges → listing) — used for `.FindFPS`, `.MTNewSprite` |
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
| `physics.md` | 0 sprite fields · 1 LoadLevelPhysics (vestigial) · 2 integration helpers · 3 tile collision (neighbourhood, hot rects, kinds, wall cling) · 4 player constants table · 5 health/breath/hazards/death · 6 wind/currents · 7 enemy classes (HP, gravity, hot rects) · 8 non-enemy sprite physics (sprite solids/PlatformBounce, ropes, springs, FootPressure, programmed paths, flotation + quicksand, landing effects, panting, platform modes) — added in the review fix pass | HIGH, MED, LOW, NOT RESOLVED |
| `spells-items.md` | 1 inventory model · 2 casting + spell table · 3 pickups · 4 items · 5 power-ups · 6 HUD, WandGlow | HIGH, MED, LOW, NOT RESOLVED |
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
1. Per-class meaning of sprite placement params 1–4 and record byte +1 (world-data §3.4).
2. Header fields 0x26c7 (OmniPx modes), 0x26c8 (copied to G+0x16), 0xb270..0xb276; PxMid cell
   0xFFFF handling (world-data §3.2/3.3).
3. `Mcnv` response/action encoding (world-data §5).
4. Why music 21/27 were not shipped (only "never referenced" is established).
5. `.WallBounce` cases 0xc..0x1f, 0x24..0x2f, 0x32..0x3b; `.WallBounceBG`; the unused-looking
   hot-rect tables at `DAT_100a4794+0xc` and `DAT_100a4314` (physics §3).
6. Enemy behaviour patterns (22 Handle routines), variant selection of enemy HP (physics §7).
7. Glider physics in detail (physics §4). (The deep-liquid factor `dRam100a1a30` is
   **resolved** = 0.65, physics §4 ⚑ corrected (review 2026-10-03) #6.)
8. `G+0x12` (= 3 at new game) reader; whether any lives concept exists (engine §6).
9. Prefs +0x142 block; exact meaning of prefs +0x02/+0x04/+0x06 levels (engine §8).
10. Lighting/tint table algorithms (`.CalcLightingTable`, `.Build*Table`), blend mixing
    arithmetic, flame rule (sprites §3.2, §4).
11. Spells 2 and 7 (unnamed, never granted by the debug kit): whether any shipped scroll
    grants them; item ids 0x12 (Hammer?) and 0x14 names (spells-items §2.1, §4).
12. Use sites of most Titles PICTs (sprites §7).
13. Resource-chain winner for `PICT 7000` (app fork vs World Data).
14. Non-enemy sprite physics remainder (physics §8, added by the review fix pass): radial
    geometry `.MakeRadial` / `.UpdateRadialPos` / `.UpdateRadiusSprites` / `.RadialWheelStep`;
    `.HitPlatformSprite`; rope types 3023..3039 (no parameters set); the `.glue::pow` exponent of
    the rope sag curve; the installer of `.GetRopeBridgeHeight` (table `_DAT_100a0a00`); the
    spring cooldown decrement and the class excluded by `PTR_PTR_100a0460`; the player's
    `+0x19e` writes in `.HandlePlayerSprite`; meanings of `_DAT_100a0718` and of the
    `_DAT_100a0678 = 1` springs write; who sets platform mode 4 on a spell-spawned ice floe;
    platform visual-stage fields `+0x88`/`+0xb8`; the arg order of `.GetFGCrunchDirTile` (engine
    §9 crunch pairs).

## Reviewer notes (attack first)
- Decompiler trap met once already: 8-byte copy loops written as `p[2] = q[2]` after
  `p = base−8`/`base+0x10` hide a +8 offset (`lwzu/stwu` pre-increment). The save layout
  (engine.md §9) was corrected against raw disasm; the same idiom appears in `.SetupLevel`,
  `.ContinueGame`, `.OpenWorld` (FSSpec copies) — re-check any offset derived from such a loop.
- "LoadLevelPhysics is vestigial" rests on a TOC-load scan; an indirect address would defeat it.
- Spell id → manual name mapping (Statue = 1, Ice Wall = 3, Tree Trunk = 4, Boomerang = 5,
  V Blade = 6) is behaviour-derived from code, not from strings.

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
