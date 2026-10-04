# Bubble Trouble X 1.1 — RE bank index

## Provenance
- Game: Bubble Trouble X 1.1 (Aug 2008 Universal Binary; app `vers` 1.0.2, data `vers` 1.0.0),
  `…/BubbleTroubleX_1.1_UB/Bubble Trouble X.app` (Mach-O executable 764,080 B).
- Binary read: thin i386 slice `/Users/andiyar/Developer/Ambrosia/ghidra/BTX_i386` (Carbon C, full
  symbols), produced with `lipo -thin i386` (per `ghidra/README.md`).
- Dump: `/Users/andiyar/Developer/Ambrosia/ghidra/BTX_i386.decompiled.c` (34,806 lines), Ghidra
  12.1.3 headless + `DumpDecompile.java`. Dump header: `// Decompilation of BTX_i386 (1559 functions)`;
  function blocks present — `python3 ghidra/find_func.py '.' --names --file <dump>` →
  **`[1137 function(s) matched]`**. The other 422 are external stubs/imports or folded bodies.
- Folded game functions (nm `t` symbols below 0x30000 with no dump block, Python diff of
  `nm -n` vs the block list): `_DoFXSuitabilityCheck @ 0000f760`, `_NewEnemy @ 00012172`,
  `_CorrectEnemyMazeY @ 00012682`, `_CorrectEnemyMazeX @ 00012704`, `_MoveEnemy @ 00012786`,
  `_MoveEnemyRandomly @ 0001396f` (plus `start`, `dyld_stub_binding_helper`). The enemy ones were read
  from `otool -tV` disassembly (enemies-ai.md header).
- Other tools this session: `otool -tV` (47,065-line listing), `nm -n`, `otool -l` (section table
  for `__data` / `__const` reads), `python3 ghidra/read_const.py` not needed (the only FP constants
  were decoded inline with `struct`), Python resource-map parser for every `.rsrc`.
  ⚑ corrected (review 2026-10-03): that parser is now checked in — `docs/bubble-trouble/tools/rsrc_census.py`
  (generic classic resource-map parser; `--extract DIR` writes `<TYPE>_<id>.bin` payloads).
- Rules oracle read: guide `basics.html`, `enemies.html`, `advanced.html`, `about.html`;
  `BT Editor read me.txt`. Cross-checks are cited inline ("Guide: …").
- Not read (per brief): anything under `~/Developer/Ambrosia/docs/`.

## Files
| file | sections | labels present |
|---|---|---|
| `engine-loop.md` | 1 program flow · 2 frame cadence (0.033 s timer) · 3 RNG + all call sites · 4 frame step order · 5 game-state machine · 6 screen/GWorld coordinates | HIGH, MED |
| `hero-and-input.md` | 0 hero struct · 1 start position · 2 input sampling · 3 movement · 4 push/pop table · 5 lives/catch/death timings · 6 balloon trap · 7 invisibility · 8 weapons = dead code · 9 pause cheats | HIGH, MED |
| `enemies-ai.md` | 0 enemy struct · 1 spawning · 2 egg→hatch timeline · 3 per-frame processing · 4 EnemyAI: 4a speeds, 4b FigureEnemyMove, 4c random walk, 4d homing, 4e pop/push/balloon actions · 5 squish/pop/capture · 6 level counts · 7 dead code | HIGH, MED |
| `bubbles-items-scoring.md` | 1 blocks & bouncing · 2 pops & eggs · 3 jewels · 4 dynamite & blast shapes · 5 balloons · 6 multiplier table · 7 bonus bubbles · 8 EXTRA · 9 time bonus · 10 regenerate · 11 air bubbles · 12 score table | HIGH, MED |
| `data-formats.md` | 1 MAZE · 2 LEVL · 3 FILM · 4 SpIL/SpIc/cicn/btSP · 5 orbit + checksum tables · 6 snd · 7 PICT/Rect · 8 SCOR · 9 prefs file · 10 other resources | HIGH, MED, LOW |
| `replay-oracle.md` | 1 determinism inventory (all clock reads) · 2 input stream · 3 demo start sequence with RNG draw counts · 4 replay hazards · 5 per-frame order · 6 validation plan | HIGH, MED, LOW |
| `tools/rsrc_census.py` | resource-fork census / extractor used for every table and decode in this bank | — |
| `data-census.md` | `btx-census` stdout (BubbleTrouble/Core): every cicn/ppat/PICT/snd through HectorKit; its ⚑ corrections (plan 2026-10-03 hectorkit-btx-decoders) are in `data-formats.md` §4 §6 §7 | HIGH, MED |
| `REVIEW-2026-10-03.md` · `FIXPASS-2026-10-03.md` | Fable review and the fix-pass summary (ledger at the end of this file) | — |

Append rule: new findings append to the topical file (new numbered subsection, with `name @ addr`,
the quoted lines, the command that resolved any constant, and a per-claim label) **and one line in
this index** (file table or NOT-RESOLVED list). Never a monolith; split a file before it passes ~600 lines.

## Resource census

Command (from the repo root; covers all six files incl. the editor's) — ⚑ corrected (review 2026-10-03), re-run
with the checked-in parser and reproduces every table below exactly:
```sh
R="/Users/andiyar/Developer/Ambrosia/Resources/ambrosia-extracted/Action-Adventure/Bubble Trouble X/BubbleTroubleX_1.1_UB"
find "$R" -name '*.rsrc' -print0 | xargs -0 python3 docs/bubble-trouble/tools/rsrc_census.py
```
(Original session command: `python3 scratchpad/bt/rsrc.py <file>`, not checked in.)

**BT Levels.rsrc** (1,345,319 B)
| type | count | size (B) | ids |
|---|---|---|---|
| `LEVL` | 50 | 64–64 | 1..50 |
| `MAZE` | 50 | 176–176 | 1..50 |
| `PICT` | 6 | 103360–159156 | 13000..13005 |
| `ppat` | 7 | 71766–71766 | 912..13005 |
| `vers` | 2 | 53–67 | 1..2 |
| `FILM` | 4 | 10012–10012 | 1..4 |

**BT Sounds.rsrc** (6,909,050 B)
| type | count | size | ids |
|---|---|---|---|
| `snd ` | 51 | 725–1772436 | 9000..11004 |
| `vers` | 2 | 53–67 | 1..2 |

**BT Sprites.rsrc** (1,157,823 B)
| type | count | size | ids |
|---|---|---|---|
| `TMPL` | 2 | 51–69 | 25000..25001 (describe `SpIc`, `SpIL` — not btSP) |
| `SpIL` | 1 | 4–4 | 128 |
| `cicn` | 331 | 322–5434 | 25000..31723 |
| `vers` | 2 | 53–67 | 1..2 |
| `SpIc` | 1 | 210–210 | 1000 |
| `btSP` | 325 | 328–4608 | 25000..31723 |

**BT Titles.rsrc** (874,126 B)
| type | count | size | ids |
|---|---|---|---|
| `PICT` | 7 | 7814–515718 | 9001..9100 |
| `vers` | 2 | 53–67 | 1..2 |

**Bubble Trouble X.rsrc** (1,553,648 B)
| type | count | size | ids |
|---|---|---|---|
| `MENU` | 10 | 29–353 | 128..1020 |
| `DITL` | 42 | 18–392 | 129..9005 |
| `BNDL` | 1 | 68 | 128 |
| `ics8` | 7 | 256 | 128..1004 |
| `ics4` | 3 | 128 | 128..900 |
| `ics#` | 9 | 64 | 128..1005 |
| `ICN#` | 3 | 256 | 128..130 |
| `icl8` | 2 | 1024 | 128..129 |
| `icl4` | 2 | 512 | 128..129 |
| `FREF` | 6 | 7 | 128..133 |
| `ALRT` | 28 | 14 | 129..9005 |
| `STR#` | 27 | 52–3938 | 128..4000 |
| `STR ` | 2 | 109–214 | -16397..132 |
| `DARK` | 2 | 1024 | 128..129 |
| `MBAR` | 1 | 10 | 128 |
| `DLOG` | 11 | 24–34 | 160..3001 |
| `PICT` | 15 | 930–457926 | 200..29402 |
| `CURS` | 8 | 68 | 256..263 |
| `cicn` | 4 | 906–1802 | 128..1002 |
| `CNTL` | 4 | 28–35 | 1000..1009 |
| `crsr` | 1 | 242 | 200 |
| `ICON` | 3 | 128 | 1000..1002 |
| `SPIN` | 2 | 240–512 | 1..2 |
| `Bubb` | 1 | 77 | 0 |
| `SCOR` | 1 | 138 | 128 |
| `hfdr` | 1 | 18 | -5696 |
| `vers` | 2 | 53–83 | 1..2 |
| `TMPL` | 1 | 38 | 128 ('Rect') |
| `Rect` | 7 | 8 | 1..7 |
| `IMAG` | 1 | 24006 | 128 |
| `carb` | 1 | 2 | 0 |
| `snd ` | 1 | 11540 | 9047 |
| `plst` | 1 | 784 | 0 |
| `dlgx` | 11 | 6 | 129..3001 |
| `icns` | 1 | 54022 | -1000 |
| `xmnu` | 1 | 128 | 131 |

**extras/BT Level Editor.app/…/BT Level Editor.rsrc** (136,382 B; inspected only for TMPLs — none)
`DITL 15, MENU 4, MBAR 1, DLOG 12, vers 2, WIND 1, STR# 1, cicn 4, crsr 6, icl4 1, ICN# 1, ics8 1,
ics4 1, ics# 1, BNDL 1, BteD 1, FREF 1, ALRT 3, icl8 1, PICT 6, carb 1, plst 1, icns 1`.

## Out of scope (identified only)
- Registration/licensing: `_RT3_*`, `_ASWReg_*`, `_DoRegReminder`, `_RegisterButton`, `__RT3_*`,
  network clock `_Clock*`, proxies; license-check byte mazes inlined in `_ProcessHero`,
  `_ProcessEnemies`, `_MakeAllEnemiesDisappear`, `_InitMac`; `_Useless5/7/8` decoys.
- Update check: Sparkle bridge loaded in `_openApplicationAEHandler`.
- Anti-tamper: `_InitEncryption`/`_CheckForHacking` (shadow score/lives/level, flag read by nothing),
  `_CheckLevel/_CheckMaze/_OtherLevCheck/_OtherMazeCheck` (checksums, flags read by nothing;
  `_CheckLevelReroute` = `_CheckLevel` — ⚑ corrected (review 2026-10-03), name added),
  `_ScramblePassword` (nibble-swap+invert, no callers in the sim), contest leftovers
  (`_GetBogusContestScore`, "BT Contest" file name).
- Unregistered nag: the game stops after level 7 for an unregistered copy (engine-loop.md §5).

## Decisions for Ben (real forks the code exposes)
1. ~~Orbit stars on Intel~~ — ⚑ corrected (review 2026-10-03): **demoted to a note, no decision needed.** The
   byte-order bug is real (i386 reads `SPIN 1` raw, offsets ~±10000 px, never drawn; PPC draws a
   radius-48 orbit), but orbit stars (motion type 2) come only from `_NewStarGroup(…, 10)`, whose sole
   caller is `_PauseGame @ 0001767b` — the pause-screen cheat hash `0x211e290` "star burst". So it is
   invisible in play, demo and FILM replay. (data-formats.md §5)
2. **Registration state for the replica**: several branches (hero sprite swap, extra RNG draws, level-8
   stop) depend on it; recommend "registered, valid license" (replay-oracle.md §4).
3. **Preferences that alter RNG** (stars, air bubbles): keep both ON for FILM replay; expose or not?

## NOT RESOLVED
- NR-1 FILM +8 "level" field: stale `GetLevel()` at record time; data reads (u16) 2,2,3,4 for ids 1..4; unused by playback. Meaning of the stored values unknown.
- NR-2 btSP header second i16 (8, 101, …): unused by the plotter; meaning unknown.
- NR-3 ⚑ corrected (review 2026-10-03), narrowed: the algorithm is cited as Apple's documented QuickDraw `Random` (`randSeed = randSeed×16807 mod (2^31−1)`, 16-bit i16 result) at [LOW] (engine-loop.md §3). Open: (a) whether Carbon's `Random` keeps the 0x8000 → 0 adjustment; (b) the process-start `randSeed` (QD docs: 1 after `InitGraf`). Needs a runtime probe on the original.
- NR-4 `RT3_GetDisplayCopies()` returning "N/A" — which license state arms the `_DrawPointsToComp` RNG trap.
- NR-6 `_PopEnemy(-1)` / `_ReleaseEnemyFromBalloon(-1)` after a hero balloon: reads/writes below the enemy array; effect unknown. → narrowed by C12 (`_ReleaseEnemyFromBalloon(-1)` only on the residual path: an enemy catch on exactly trap-release frame h+91 at a w16 = 120 level; `_PopEnemy(-1)` is live on every hero-balloon pop and reads slot −1 = `_environment`+4 / +0x47 = 0x393ab. Its effect depends on runtime memory and stays open. bubbles-items-scoring.md §5).
- NR-7 `_FigureEnemyMove` homing with `old dir == 0`: `back` is uninitialised after `LocationErrorInt`. → RESOLVED by C11 (`_LocationErrorInt` → `_DoLocationError` → `_StopAlert` + `_CleanUp` → `_ExitToShell`: the original quits; `back` is never read. enemies-ai.md §4d).
- NR-8 Editor "Balloon time" ↔ LEVL word: code uses w15 (flash) and w16 (release); w17 (always 300) is never read.
- NR-9 Conditions the FILMs were recorded under (prefs 0x35/0x36, license state).
- NR-10 Whether the shipped FILMs (possibly recorded with the 2002 engine) replay in sync in X 1.1 itself — needs Ben's eyes on the original demo. → evidence 2026-10-04: the FILM headers' 16-bit level field shows an older recording build (`data-formats.md` §3 ⚑); the replica desyncs on FILMs 2–4 with no 1.1 code discrepancy found (Classics DECISIONS D8).
- NR-11 Delivered frame rate of the original on real hardware (code: 0.033 s timer = 30.3 Hz nominal).
- NR-12 `_openApplicationAEHandler` tail (InitMac/Interface invocation) not read line by line.
(NR-5 was resolved this session: all shipped mazes have (7,6) empty.)

## Review ledger

**2026-10-03 — Fable review, verdict ACCEPT_WITH_FIXES** (`REVIEW-2026-10-03.md`; fix pass
`FIXPASS-2026-10-03.md`). Every fix is marked `⚑ corrected (review 2026-10-03)` at the place below.
1. [Important] `_NewStar` pre-draw playfield clip (edge squishes draw fewer RNG numbers) — landed in
   `replay-oracle.md` §4.2; also `engine-loop.md` §3 RNG table, `bubbles-items-scoring.md` §11.
2. [Important] Orbit stars only from the "star burst" pause cheat — Decision #1 demoted to a note in
   `INDEX.md` "Decisions for Ben"; landed in `data-formats.md` §5.
3. [Important] `_CheckForBombKills` re-counts dead enemies (A∩C on row r−1) — landed in
   `bubbles-items-scoring.md` §4 and `enemies-ai.md` §5; pointer in `replay-oracle.md` §4.5.
4. [Minor] LEVL w15/w16 per-level step sequence — landed in `data-formats.md` §2 and
   `bubbles-items-scoring.md` §5.
5. [Minor] 0x33a3c holds code addresses; immediates at the targets — landed in
   `bubbles-items-scoring.md` §3.
6. [Minor] Balloon-release frame consumes no FILM sample — landed in `hero-and-input.md` §6 and
   `replay-oracle.md` §2.
7. [Minor] QuickDraw `Random` cited as external fact [LOW]; NR-3 narrowed — landed in
   `engine-loop.md` §3, `replay-oracle.md` §4.3, `INDEX.md` NR-3.
8. [Minor] Dummy-(0,7) threshold u+9 vs u+10 untraced [LOW] — landed in `enemies-ai.md` §4d and
   `replay-oracle.md` §4.3.
9. [Minor] Bounce-sound wording ("a block travelling right") — landed in `bubbles-items-scoring.md` §1.
10. [Minor] Census parser checked in as `tools/rsrc_census.py`, re-run reproduces all six tables —
    landed in `INDEX.md` "Resource census" (command pasted) and `data-formats.md` header.
11. [Minor] Missing names: `_EnemyCheckBurstingBubble` → `enemies-ai.md` §4b; `_Multiplier_Process`
    → `bubbles-items-scoring.md` §6; `_TimeBonus_Increase` → `bubbles-items-scoring.md` §9;
    `_CheckBlock`/`_NewHurtBlock` → `bubbles-items-scoring.md` §1 and `data-formats.md` §2 (w3);
    `_CheckLevelReroute` → `INDEX.md` "Out of scope"; `_EditorRunning` → `engine-loop.md` §1.
12. [Minor] FILM leftovers share one residue (last nonzero index identical across all four) —
    landed in `data-formats.md` §3.

**2026-10-03 — Plan 2026-10-03 btx-core corrections** (`docs/plans/2026-10-03-btx-core-and-film-harness.md`
§"Bank corrections to append"). Each one was re-checked against the dump/disasm at append time and is
marked `⚑ corrected (plan 2026-10-03 btx-core)` at the place below.
1. C1 [HIGH] At most one `_HeroCaught` per frame (state-2 gate in `_IsHeroCaught`, state 3 set first)
   — `replay-oracle.md` §4.5, `hero-and-input.md` §5, `bubbles-items-scoring.md` §4.
2. C2 [HIGH] Hero-squash star group 0xe = 14 stars (shared tail `LAB_00004af8`) — `replay-oracle.md` §4.2
   (supersedes REVIEW finding 1's "13 stars").
3. C3 [HIGH] Star groups 1/0xb/0xc/0xd have no callers; type-0xb stars come only from groups 3/4/5 and
   0xe — `replay-oracle.md` §4.1.
4. C4 [HIGH] The shark balloon's collision box grows once (frame ≤ 1 gate), never to the full balloon —
   `bubbles-items-scoring.md` §5.
5. C5 [HIGH] A moving block pops flying balloons only; held-enemy balloons pop via `_WasEnemySquished`,
   hero balloons never — `bubbles-items-scoring.md` §1.
6. C6 [HIGH] `_ResetBlocks` seeds `gNumNormalBlocks = 100` so frame 1's recount runs — `engine-loop.md` §4.
7. C7 [HIGH] An air bubble dies when its bottom < 0; delayed bubbles skip movement and the drift-index
   advance — `bubbles-items-scoring.md` §11.
8. C8 [HIGH] `_Bonus_SetNumEnemySquishes` returns early for n < 3 — `bubbles-items-scoring.md` §6,
   `enemies-ai.md` §5.
9. C9 [HIGH, arithmetic] Hero state 2 on frame 71, first `_CheckNewEnemies` on frame 82 —
   `replay-oracle.md` §3, `engine-loop.md` §4.
10. C10 [HIGH] An enemy squished on entry can still catch the hero in the same call — `enemies-ai.md` §3.
11. C11 [HIGH] Old dir 0 in homing → `_LocationErrorInt` → `_ExitToShell` (the original quits) —
    `enemies-ai.md` §4d; NR-7 resolved.
12. C12 [HIGH code path; MED residual] Hero balloon: `_PopEnemy(-1)` runs at trap release h+91;
    `_ReleaseEnemyFromBalloon(-1)` is reachable only on the residual h+91-catch path at w16 = 120 —
    `bubbles-items-scoring.md` §5; NR-6 narrowed. New at append time [MED]: slot −1 lies in
    `_environment`, so the original `_PopEnemy(-1)` may award +100 once per process (effect open).
- Note (not a correction; from the plan's Research note 6 [derived], not re-checked here): registration
  is RNG-neutral for levels 1–4, so FILMs 1–4 cannot discriminate Decision 2.
- 2026-10-04 — BTX Diagnosis protocol (Classics DECISIONS D8): `data-formats.md` §3 ⚑ — FILM level field is a 16-bit store,
  so FILMs 1–4 predate X 1.1 [HIGH]; NR-10 evidence appended.
