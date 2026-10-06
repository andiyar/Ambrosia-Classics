# Plan — Deimos Rising Phase 0: data decoders + census — 2026-10-06

> Status: DRAFT (Opus planner, 2026-10-06; awaiting orchestrator review + Ben's answers to "Open questions")
> Shape: `~/Developer/Toolkits/fable-kit/plan-template.md`; precedents `docs/plans/2026-10-03-phase0-hectorkit-lift.md`
> (Aki Phase 0: verification model, invariants, zero-skip floor) and `docs/plans/2026-10-03-hectorkit-btx-decoders.md`
> (a game's decoders added to HectorKit later: worktree branch, floor-delta rule, census tool + golden doc).
> **Contracts, not code** (Ben, 2026-10-03): types, signatures, behaviour, test names and what each proves,
> acceptance commands. No implementations.
> Scene: Classics DECISIONS **D22** (Ben, 2026-10-06) — Deimos builds next; step 2 = Phase 0 (this plan), step 3 = the
> build plan. Bank (the oracle): `docs/deimos/` — closed 2026-10-06, 938 rows = 716 HIGH / 222 MED / 0 LOW.
> Planner's probes (not committed): scratchpad `dp0/{zipv,gifv,gifpal,scanv,tgav,aifv,imav,textv,gramv,encv,enc2}.py`
> over the archive copy. **Every number below came from those runs on 2026-10-06** unless it cites the bank.

**Goal:** every original Deimos Rising 1.0.6 data file — the 871 entries of the four paks plus the one Local file —
is in git, opens, and decodes (image → frames / RGB555 buffer, sound → PCM, text → parsed record), proven by
`deimos-census` whose stdout is `docs/deimos/data-census.md` with **0 failures**.

**Architecture (brief rulings):**
- **HectorKit** (generic, reusable, Foundation-only): `StoredZipArchive` + `CRC32` (HectorResources), `AIFFAudio`
  (AIFF/AIFC, `NONE`/`ima4` → PCM through the existing `IMA4`), `WAVEAudio` (RIFF PCM) and the `SoundFile` dispatcher
  (HectorAudio). Built on `HK=/Users/andiyar/Developer/HectorKit-worktrees/deimos-phase0` (branch `deimos-phase0`),
  real-data tests through the new `HECTORKIT_DATA_DEIMOS`, merged to HectorKit main **before** Classics consumes it.
- **Classics** (Deimos-specific): new SwiftPM package `Deimos/Core` — library `DeimosCore` (Foundation +
  HectorResources + HectorAudio only, HectorKit D6), executable `deimos-census`, test target `DeimosCoreTests`.
  Owns: tag naming + tag index (Local → Paks, overrides), text de-obfuscation, the U_Token grammar and every text
  type (stli flli idli reli coli tefo plde unde wede leve), `film`, `im16` TGA, `im08` GIF + the sprite-plate scan +
  the frame encoder, and the `soun` load gate. Worktree `WT=/Users/andiyar/Developer/Ambrosia-Classics/.claude/worktrees/deimos-phase0`
  (branch `deimos-phase0`).
- **Data in git** (Ben's standing ruling; D10, D20, memory "shareware data goes in git"): `Resources/Deimos/Data/`
  holds `Paks/{Audio,Game,Interface,Music}.pak` and `Local/film/Last Film[last].film`, byte-identical to the archive.

**Tech:** Swift 6.4 / Xcode 27 beta, SwiftPM tools 6.0, XCTest, macOS 15. Python 3 + Pillow only as the planner's probe
(never a build or test dependency).

---

## Verification model (read first)

**Machine-verifiable — executors close these alone:**

| # | gate | expected |
|---|---|---|
| G1 | HectorKit zero-skip gate on `$HK`, `HECTORKIT_DATA_DEIMOS` exported | `PASS: zero skips, zero failures, executed N == floor N`, N = base + **37** (252 at `0467025` → **289** if nothing else lands; floor-delta rule, invariant 9) |
| G2 | HectorKit landed: `git -C ~/Developer/HectorKit merge-base --is-ancestor <K4 sha> HEAD` | exit 0 (main checkout fast-forwarded, R4) |
| G3 | Classics data commit = archive | `shasum -a 256` of the five files equals Research note 1, sizes equal |
| G4 | `Deimos/Core` whole suite | `swift test` → executed = the task ladder total (**98** at C7), `0` lines matching `^Test Case '.*' (failed|skipped) \(` |
| G5 | Census tool | `deimos-census Resources/Deimos/Data` exit 0; stdout ends with the exact Totals line of Task C7; `DeimosCensusTests.testStdoutEqualsCommittedCensus` green (doc = stdout verbatim) |
| G6 | Classics builds untouched | `xcodegen generate && xcodebuild -scheme Aki build` and `-scheme BubbleTroubleX build` → BUILD SUCCEEDED (Deimos adds no app target) |
| G7 | Untracked/modified check per commit | `git status --porcelain | grep -v '^??'` empty after each commit |

**Honesty gates (Ben only) — none blocks Phase 0:**
- **INDEX #10 (MED residual):** the title/menu art decoded with TGA descriptor bit 5 honoured shows **upright**
  (`deimos-census --render out/deimos-render` writes `menu.png`; Ben looks once). Closes sprite-manager-resource-image.md NR 4.
- Phrase every completion claim as "decodes to the census", never "looks right".

**What the machine does NOT prove:** the exact QuickTime colour conversions (24→16 truncation, 8-bit system-CLUT
mapping — both MED, Research notes 14–15, chosen to the bank's and QuickDraw's documented rules and pinned by
tests); that effects *sound* right (Phase 1: the game's own mixer decodes effects differently from CoreAudio —
Research note 21); any game logic.

**Known deltas to disclose up front (so none is mistaken for a bug):**
1. `Music 3[mu03].aif`'s FORM size is **76 bytes short** of the file (a QuickTime `wave` chunk was added without
   updating it): its SSND runs past the declared FORM end. Readers walk chunks to the end of the *data*.
2. One pak entry (`Music.pak:Ambient Music Loop[ammu].IMA`) has general-purpose flag bit 1 set and version-needed 10;
   meaningless for STORED, ignored (the game never reads flags).
3. 18 of 45 TGAs carry colour-map-spec byte 7 (colour-map entry size) = `0x18` with colour-map type 0 — ignored per TGA; 14 TGAs carry the
   26-byte TGA 2.0 footer.
4. The `GLOW` alpha plate scans to **different frame rects** under the original's 8-bit-index compare than under an
   RGB compare (bank tool `plate_frames.py`): fill (8,0,255) and the frame body's (0,0,255) land on one system-CLUT
   index. The 8-bit result is the original's; 5 of its 12 rects differ (Research note 15).
5. `plde` writes three `_INT` keys as `100.000000` / `15.000000`; `sscanf("%i")` reads the leading integer (100, 15).
6. Every `tefo` carries `#Size_INT`, which the engine never reads (bank data-tags §5 ⚑).
7. Bank pak-format §3 says "some files use CR LF": the census finds **none** — CR in stli/flli/idli/reli/tefo, LF in
   leve/plde/unde/wede, no line end in coli.
8. D22's text names "im08/im16 images" among the HectorKit decoders; this plan (orchestrator brief) puts GIF/TGA in
   `DeimosCore` (kit two-game rule — no other Ambrosia title ships GIF/TGA). Recorded as D23.2; Open question Q2.
9. Pushing the data prints GitHub's large-file warning for `Game.pak` (54,956,985 B = 52.4 MiB > 50 MiB
   recommended, < 100 MB hard limit). Accepted; no LFS (Research note 2).

---

## Non-negotiable invariants

1. **Kit stays game-agnostic.** No type, symbol or doc comment in `Sources/HectorResources|HectorAudio` says "Deimos",
   "pak", "Ambrosia". Game names live only in test files and `HectorTestSupport` locators (HectorKit D3/D5 precedent).
2. **Foundation-only (HectorKit D6).** `HectorResources`, `HectorAudio`, `DeimosCore` import Foundation (+ HectorKit
   Foundation-only products). No ImageIO/AVFoundation/AppKit in them; Apple frameworks only in tests as oracles
   (`AVAudioFile`, `/usr/bin/zip`, `/usr/bin/afconvert`) and in `deimos-census --render` (ImageIO PNG writer). Windows
   traps (Classics D18/W0.5): no `String.Encoding.macOSRoman` — use `HectorResources.MacRoman`; no `FileManager`
   symlink enumeration without resolving (invariant 9 of the Aki plan).
3. **Hostile-input posture.** Every read bounds-checked; malformed input throws a named error, never traps, never
   allocates from an unchecked size (check `count × stride ≤ data.count` before allocating).
4. **Refuse what the census has not shown** (HectorKit D2/D5 style): an unsupported ZIP method, AIFC codec, TGA type,
   GIF feature etc. throws a named error with a synthetic test, rather than decoding approximately.
5. **Replicate the original's reading, not the format's ideal.** Where the game's reader differs from a textbook one
   (data offset from the LOCAL header; first-`.` suffix; forward-only token cursor; `%i` semantics; 8-bit-index plate
   scan; red-channel alpha), the code follows the game and the doc comment cites the bank section.
6. **Data enters git once, verified.** Task C0 copies exactly five files, checks SHA-256 against Research note 1, and
   commits them with explicit paths. Never `HID.bundle`, `.DS_Store`, `Icon\r`, the PEF binaries (Q1), the Player Guide.
7. **Never `git add -A` / `.`**; explicit paths; G7 after every commit. Trailer on every commit, both repos, no other:
   `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`. Never `git stash`.
8. **Repos and branches.** HectorKit work only in `$HK` (branch `deimos-phase0`), merged by `git fetch origin && git
   rebase origin/main && <gate> && git push origin HEAD:main` (fast-forward; on rejection rebase, re-gate, retry).
   Never build or write in `~/Developer/HectorKit` except R4's clean `pull --ff-only`. Classics commits stay on branch
   `deimos-phase0` in `$WT`; the orchestrator merges/pushes. Never touch sibling worktrees (`magical-jang-e96263`,
   `bold-dewdney-ee1445`, `ferazel-wave2`, …) or the Classics main checkout.
9. **Floor-delta rule.** Other sessions may land HectorKit tests concurrently. Each HectorKit task's acceptance is
   "executed = executed on the rebased base + this task's new tests"; on a `FLOOR` conflict re-run the gate on the
   rebased tree and set `FLOOR` to the printed total. Never add numbers from two branches by hand.
10. **STOP on any unexpected number** (counts, hashes, offsets, frame totals, test totals) and report the command
    output — never edit an expectation or the code to make them agree.
11. ⚠️ **LANDMINE — `swift test` has no package-wide total.** Count `^Test Case '.*' (passed|failed|skipped) \(` lines;
    for a filtered run take the non-zero `Executed N tests` line (Aki plan Research note 18). Never `grep -c skipped` bare.
12. ⚠️ **LANDMINE — `swift run` mixes build output into stdout.** The census doc is produced from the built binary
    (`swift build -c release` then `"$(swift build -c release --show-bin-path)/deimos-census"`).
13. ⚠️ **LANDMINE — SwiftPM rejects a declared target with no sources.** `Deimos/Core/Package.swift` grows task by
    task; do not pre-declare targets.
14. ⚠️ **LANDMINE — the archive folder is ` Data` with a LEADING SPACE.** Quote every path; the committed copy drops
    the space (`Resources/Deimos/Data`).
15. ⚠️ **LANDMINE — Game.pak is 55 MB.** Read it with `Data(contentsOf:options: .mappedIfSafe)`; return entry bytes as
    slices of that `Data`, never copy the archive per entry. Tests must not hold more than one decoded music track at once.

---

## Research notes the executor must know

All byte claims below were **re-verified on the archive bytes on 2026-10-06** (planner probes) unless marked "bank".
`$G = /Users/andiyar/Developer/Ambrosia/Resources/ambrosia-extracted/Action-Adventure/DeimosRising/Deimos Rising 1.0.6 (volume)/Deimos Rising`.

**Data and repo**
1. **The five files** (`shasum -a 256`, sizes from `ls -l`):
   `Paks/Audio.pak` 1,702,614 B `b46ce0711faca7ce0cd33c850c41e88bd3be7f7289eee9d80fe03c7013bb1039` ·
   `Paks/Game.pak` 54,956,985 B `3ae865a9ee3b005dc10368de847e4a3dea402dc1a911bbd09f0728153aceee09` ·
   `Paks/Interface.pak` 2,849,896 B `de7d2dd349f208f72eae156820c48c791f06e46b24ec5816e1a1bed0dfea0d93` ·
   `Paks/Music.pak` 13,601,894 B `3ee906a6f885ba466645ea53bab6aebba54840d756a63212f895364cebadc455` ·
   `Local/film/Last Film[last].film` 40,296 B `cf5f42cc475c011e750d3fe268e06f890ee0aac4b1678d79bcf2dca5b3e1b897`.
   The rest of `$G/ Data`: `.DS_Store` files (modern extraction residue), 0-byte `Icon\r` in ` Data`, `Local` and 13 of
   the 15 `Local/<type>` folders (`tefo`, `unde` are empty), `HID.bundle` (OS X HID helper dylib). Not committed.
2. **Git limits.** Game.pak is above GitHub's 50 MiB *warning* and below the 100 MB *hard* limit; total add ≈ 73 MB.
   No hard blocker → plain git, no LFS (LFS would also break anonymous clones of the public repo past the free quota).
   Classics `.gitignore` line 2 is `/Resources/` — a directory exclusion git cannot re-include beneath, so C0 changes it
   to `/Resources/*` + `!/Resources/Deimos/` (the Aki `Resources/Aki/*.app` symlinks stay ignored). `.DS_Store` is
   already ignored globally. A new `.gitattributes` line `Resources/Deimos/** binary` stops any autocrlf/diff on the
   data (text-type entries are inside the paks, but the rule costs nothing).
3. **App resource fork (not in scope unless Q1 says so):** `$G/Deimos Rising/..namedfork/rsrc`, 151,602 B, 39 types incl.
   PICT 12, DITL 6, DLOG 5, MENU 5, STR# 5, crsr 3, cicn 2, TEXT 3 (the config dialog DITL 190 and alert PICTs, bank
   file-pict-alerts-manager.md). Forks do not survive git (HectorKit D6.5) → it would be committed as a data-fork `.rsrc`.
4. **HectorKit state.** `$HK` = `0467025` (= origin/main); `tools/check-zero-skip.sh` FLOOR **252**; DECISIONS D1–D9
   (next free **D10**); tags `v0.1.0`, `v0.2.0`. Existing reusable pieces: `IMA4.decode(_:packetFrames:channels:)`
   (34-byte Apple packets, packet-interleaved channels, CoreAudio carry rule, HectorKit D9), `SndPCM`
   (`sampleRate: Double, channels, frames, samples: [Int16]` interleaved), `MacRoman.decode(_:)`. Nothing for ZIP,
   AIFF/AIFC or WAVE exists. `HectorAudio` already depends on `HectorResources`.
5. **Classics state.** `$WT` = `69ef231` (main). Next free Classics D-number **D23** (re-check at commit — D-numbers have
   collided before). The worktree's `../HectorKit` symlink resolves to `~/Developer/HectorKit` (main checkout).
   `Aki/Core` is the package shape to mirror (tools 6.0, `.package(path: "../../../HectorKit")`, `@main` census in
   `Sources/<exe>/`, tests through `@testable import`).

**Pak = ZIP, STORED only** (bank pak-format.md §1)
6. All four paks re-walked EOCD → CD → local headers: **886 CD entries = 871 files + 15 folders** (Audio 96/0,
   Game 763/13, Interface 9/2, Music 3/0); EOCD at file end (comment length 0), CD immediately before it, CD order ==
   local-header order == ascending offsets with no gaps (last data end == CD offset). Every entry: method 0,
   compressed == uncompressed, **CRC-32 matches the data (871/871)**, no data descriptor (flag bit 3 clear), extra
   field = ZipIt `0x2705` 18 bytes in both CD and local header, made-by 0x0714, no zip64 values, no CD comments.
   Version-needed 20 on 870 files, 10 on 15 folders + `ammu`; flags 0 except `ammu` (2). Names are ASCII, `/`
   separator, folder names end `/`. Interface worked entry: `im16/Developer Credit[decr].TGA` LHO 106, data offset
   **185** (= 106 + 30 + 31 + 18), size 614,418 (bank §1.4 agrees).
7. **The game's reader** (bank §1.2): finds the EOCD by a backwards search (retry string "Retry reading of ECD"),
   refuses spanning; walks the CD (method +10, csize +20, usize +24, nameLen +28, extraLen +30, commentLen +32, LHO +42);
   rejects an entry unless method 0 **and** csize == usize; data offset = LHO + 30 + **local** nameLen + **local**
   extraLen. CRC never checked. Entries with size 0 (folders) are not indexed.

**Tag naming and index** (bank pak-format.md §2, app-pak-music-library.md §2)
8. Name → (display, ID, type): strip the zip path after the last `/`; display = text before the first `[`; ID = exactly
   4 chars between `[` and `]` (spaces allowed: `[bop ]`); type = the suffix from the **first** `.` (max 15 chars)
   matched against 15 tables in fixed order (bank §2.2 table, first match wins; e.g. `.gif .GIF .giff .GIFf .GIFF
   .im08 .Im08 .IM08` → `im08`; `.IMA .aif` → `soun`). IDs are case-sensitive 4CCs; `none` = "no resource". A name
   containing `.DS_Store` is silently rejected; missing ID/suffix → logged and skipped. Census: all 871 classify; **no
   duplicate (type, ID)**, no zero-size file entry, no name with a second `.`.
9. Index build: Local first — for each of the 15 types in table order (`im08 im16 soun stli flli wede reli idli coli
   tefo plde pref film unde leve`) enumerate `Data/Local/<type>/`, skip unopenable/size ≤ 0 files, `.tag` header files
   (none ship; refuse), add the rest under their SUFFIX type (a wrong-folder file logs a non-fatal alert and is still
   added), flag Local. Then every `*.pak`/`*.zip` in `Data/Paks` in catalog (name) order (Audio, Game, Interface, Music),
   entries in CD order. Overrides: each Local record removes every non-Local record with the same (type, ID); pak
   duplicates are kept and the first in list order wins (loose-ends-session.md §8.7). Fewer than **100** records → a
   non-fatal "Tag Index Incomplete!" alert (app-pak-music-library.md §2.3). Enumerations "i-th tag of type T" walk index
   order — that order is the unde/plde/wede master-list order (weapons §1.1: `aibg, aiic, aipb, airg, plbo`).
10. Census: **872 records** = coli 1 · film 5 (4 pak + 1 Local) · flli 1 · idli 6 · im08 250 · im16 45 · leve 12 ·
    plde 2 · reli 1 · soun 99 · stli 5 · tefo 54 · unde 386 · wede 5. No (type, ID) collides, so the Local `last`
    film overrides nothing. `Last Film[last].film` is byte-identical to `Game.pak:film/Demo 01[de01].film`.

**Text** (bank pak-format.md §3, data-tags.md, unit-def-struct.md §2, waves-and-enemies.md §1)
11. De-obfuscation `plain = ~rotl8(cipher, 4)` is an involution. **All 473 text entries are encoded** (none plain); no NUL
    byte in any decoded text; 85 carry Mac Roman bytes ≥ 0x80 (leve 6, unde 79, stli 1 — `edit`; ⚑ as built: was `cred`). Loaders decode
    unconditionally except `unde` (only if `#name_STR` is absent) and `wede` (only if `#type_ID` is absent).
12. U_Token grammar: `strstr(buf+cursor, key)`, then `<` searched from the key hit, then `>`; value = between; cursor :=
    position of `>` (forward-only). Readers: STR (max length per key, copies ≤ max−1, missing key silent — default kept,
    `<>` → ""); ID (exactly 4 chars else error); INT (`sscanf %i`, ≤ 31 chars, length ≥ 1); FLOAT (`sscanf %f` float32);
    BOOL (`strcmp(v,"TRUE")==0`, anything else false); COLOR (`RRGGBB` → pix16 = `(r>>3)<<10|(g>>3)<<5|(b>>3)`, the
    float `trunc(65535·c/255)` path is ≡ `c>>3` for all c — INDEX #40 HIGH; ⚑ as built (R-B): `"0"` is NOT special — anything
    but six hex digits is an error ("Invalid COLOR.", flag set, dest untouched)); RECT (`strtok ","`
    + 4×`%i`, text order (left, top, right, bottom) → Mac Rect (top, left, bottom, right), HIGH). Missing/malformed
    non-STR key → error flag (strict mode is on for unde/plde — ⚑ as built: and wede — fatal "incorrect or missing data" +
    quit). ⚑ as built (R-B): an INT/FLOAT value with no digits is NOT an error (`sscanf` return unchecked; dest untouched) —
    only a missing key or a zero-length value flags.
    Value census over all text: INT 57,140 (6 written as floats, note 5 of deltas; no leading zeros/hex), FLOAT 19,815,
    BOOL TRUE 4,149 / FALSE 63,723 (⚑ as built: TRUE 4,201 / FALSE 64,203 — the probe skipped the 532
    `#stateSpawnSetDon'tSpawnOffscreen_BOOL` items, 52 TRUE + 480 FALSE), COLOR 3,223 (all 6 hex digits).
13. Per-type shapes (census): `stli` 5 lists, lines = CR count (+1 if the file does not end in CR): cred 102, edit 5,
    inte 28, pali 1, pgsl 37 (= the 37 × 128 GameStrings table) → **173**; `flli/gafl` **220** `#…<…>` items (positional,
    keys are documentation; ≠ 220 → "DATA ERROR"); `idli` 6 lists: edit 1, gaob 40, gaso 24, gasp 8, gate 54, tesp 3 (= 130);
    `reli/inre` 22 RECTs; `coli/gaco` 1 item `scoreBar_Digit <52c594>`; `tefo` 54 files × the same 17 keys, order-
    independent reader (fresh search from the start per key), `#Format_ID` → LEFT 28 · CENT 8 · RIGH 4 (`RIGHT`) ·
    CEBU 12 (5 `CEBU` + 7 `3`) · CEGA 2 (`4`); `leve` 12 levels, **565** objects (Σ `#numObjects_INT` == Σ `#unit_ID`
    per file), every `#unit_ID` is an `unde` tag, `#background_RECT <0, 0, 480, 3600>` in all 12; `plde` 2 × 57 keys;
    `wede` 5 (spawn counts aibg 8 · aiic 3 · aipb 1 · airg 1 · plbo 2 = 15); `unde` **386** units, **1,167** states,
    numStates histogram {1:128, 2:91, 3:37, 4:59, 5:18, 6:19, 7:10, 8:8, 9:6, 10:2, 11:1, 12:5, 13:1, 14:1}, numRules = 5
    in all 1,167 states, spawn sets per state {0:788, 1:285, 2:64, 3:11, 4:15, 6:2, 7:2}; every `stateSpriteFace_ID`
    (1,167), `editorPreviewSpriteFace_ID` (386) and sound ID (2,711 `…Sound…_ID` values) names an existing tag or
    `none` → **0** "MISSING SPRITE/SOUND" resets. Every unit-ID reference in unde resolves to an `unde` tag (772:
    stateSpawnSetSpawn 532, destructSpawn 99, stateRuleUnit 93, destructCoin 28, destructCoinOnGroupKill 15,
    collision_Spawn 5); idli `gaob` 40 = 38 unde + `pl01`/`pl02` (plde); `gasp`/`tesp` → im08, `gaso` → soun, `gate` → tefo;
    every level's map/preview/mask → im16 and music → soun; `tesm` scans to exactly **91** frames. Struct maps: unde unit-def-struct.md §3–§6 (0x7a60/0x5e0/0x88/0x5c,
    defaults, fix-ups §2.6), plde §9 (0x108, 57 keys), wede weapons-projectiles.md §1.2 (0x208), leve waves-and-enemies.md
    §1 + level-scroll-objects.md §6.1 (0x18-byte objects).
14. `film` (engine-loop.md §7): 40,296 = 0x9d68 bytes, big-endian: version **0x2715** · seed · level 4CC · players u8 ·
    P1 block @0x10 and P2 block @0x4ebc (0x4eac each: frames u32, score+0xb3ac2 u32, level 4CC, ≤ 20,000 input bytes
    from +0xc, bits 0–6 = left right up down fireGround fireAir select). Census: de01 le07 seed 0x469c2 4,809 ticks score
    25,050 · de02 le06 0x4f655 8,357 116,180 · de03 le02 0x54c83 10,058 57,520 · de04 le08 0x5afed 5,649 24,670 · last =
    de01; 1 player each; P2 block zero except level `none`; input bytes ≤ 0x4a (bit 7 never set); bytes after the last
    recorded tick are zero.

**Images** (bank sprite-sound-containers.md §1–§3, sprite-manager-resource-image.md §6, blit-pixel-rules.md)
15. **Original pipeline:** QuickTime's graphics importer (`'grip'`, `'GIF '`/`'TGA '`) draws the file into a GWorld:
    TGAs at the file's own depth (16) via `FUN_10020f00`; sprite plates via `FUN_10021190` — the **alpha plate (`ABCD`)
    into an 8-bit GWorld** (frame scan on 8-bit indices), then the **colour plate (`abcd`) and the alpha plate again into
    16-bit GWorlds**. No flip, no SetFlags/Matrix in either importer (HIGH).
    - 24→16: the GIF palette becomes a QuickDraw CLUT (16-bit components c·257) and CopyBits to 16-bit keeps the high 5
      bits → exactly `c >> 3` (`(c·257) >> 11 == c >> 3` for all c). Same rule as the game's own COLOR packer
      (note 12). [MED — QuickDraw rule, not read in this binary; **253 used palette components** across the plates would
      differ under round-to-nearest, so the choice is pinned by tests.]
    - 8-bit GWorld: default system CLUT (`clut` 8: 215-entry 6×6×6 cube FF..00 minus black, then 10-step ramps of red,
      green, blue, grey `EE DD BB AA 88 77 55 44 22 11`, then black = 256) with QuickDraw's 4-bit inverse table: each
      colour maps through cell `(r>>4, g>>4, b>>4)` to the CLUT entry nearest that cell's colour `(q·17)`.
      [MED — inverse-table construction not read. Planner check: 4-bit-cell nearest and full-precision nearest give
      **identical frame rects on all 125 plates** (2,554 frames); both differ from an RGB compare only on
      `GLOW` (850 × 102, 12 frames), where 5 rects change — e.g. frame 3 is (51,279,100,328), RGB gives (8,279,100,328).]
16. **GIF census (250 `im08`):** all `GIF89a`, global colour table present (2–256 entries; ⚑ as built: the shipped tables
    are 8–256 — 8 ×5, 16 ×4, 32 ×3, 64 ×3, 256 ×235), exactly one image
    descriptor at (0,0) sized == the logical screen, **no** local colour table, **no** interlace, exactly one extension
    (GCE `0xF9`) with transparency flag 0 and disposal 0, LZW minimum code size 8 in all 250, trailer `0x3B` at EOF, no
    trailing bytes. Max plate 1400 × 131. Pillow decodes all 250 to their header size.
17. **Sprite groups:** 125 colour plates (lower-case IDs, `… IC[abcd].gif`) + 125 alpha plates (`… IA[ABCD].gif`),
    `{upper(IC)} == {IA}`, sizes equal per pair (Game 124 pairs + Interface `tesm`/`TESM`). Plate scan (bank §2.2):
    row-0 keys `p0` fill, `p1` grid (asserts p0≠p1, p1≠p2, w ≥ 3, h ≥ 2); strips = runs of rows from row 1 whose
    column-0 pixel ≠ grid; cells = runs of columns with no grid pixel in the strip rows; trim rows/columns equal to the
    cell's top-left colour; all-fill cell skipped; rect (top,left,bottom,right) = (stripTop + stripH − h − 1, cellLeft + 1,
    top + h, left + w); scan order strips top→bottom, cells left→right; frame w ≤ 300, h ≤ 256 (inclusive), < 0xFFFF
    frames. Census (8-bit scan): **2,554 frames**, max 218 × 110 (bank: shipped maxima 218 × 110).
18. **Frame encoder** (`FUN_1001d780`, `FUN_1001eec0`; sprite-sound-containers §2.3a, sprite-manager §4.2): key =
    16-bit colour-plate pixel (2,0); block = 0x18 header {magic 0x499602d2, w, h, 16, key u16, hasAlpha u8, (stale u8),
    alphaOffset u32 = 0x18 + 2wh or 0} + w·h RGB555 from the colour plate + optional w·h u16 alpha map from the 16-bit
    alpha plate: `p == key → 0x20`; else `r5 = (p >> 10) & 31`, `r5 < 31 → r5` (visible) else `0x20`; a row with no
    visible pixel gets `1000` in its first entry; a frame with no visible pixel has no map. Census: **2,553 of 2,554
    frames carry a map** (the exception is `tesm` frame 90, rect (3,846,16,850), 4 px wide — the invisible space/default
    glyph, text-metrics-lists.md §1.3); Σ w·h = **3,129,511 px**; Σ block bytes = **12,579,236**. Worked (bank
    sprite-manager §Worked example, re-derived): `bocr` key **0x0360**, rects (3,3,19,19) (3,22,19,37) (7,40,19,53),
    blocks **1048 / 984 / 648**, empty-row markers frame 1 {15}, frame 2 {0, 6, 7}.
19. **TGA census (45 `im16`):** header idLen 0, colour-map type 0, image type 2, origin 0,0, 16 bpp, descriptor
    **0x01** (1 attribute bit; bit 5 = 0 → rows stored bottom-up; bit 4 = 0); pixels little-endian A1R5G5B5;
    **no pixel has bit 15 set**; body = 18 + 2wh; 14 files then carry the 26-byte footer ending `TRUEVISION-XFILE.\0`.
    Sizes: 480×3600 ×12 (maps), 96×720 ×12 (media masks), 146×306 ×12 (previews), 640×480 ×5, 160×480, 112×480,
    260×342, 284×173. Masks: 829,440 px = 712,245 `0x7fff` + **117,194 `0x001f`** (water) + one stray `0x256b`
    (`ist3`; ⚑ as built: the bytes say `int3`, Industrial 3 Media). Orientation pin: `Canyon 1 Media[cat1]` column 5 water at stored rows 371–389 → **top-down rows 330–348**.

**Sound** (bank sprite-sound-containers.md §4–§5, sound-music.md §2.2, §6)
20. **AIFF census (99 `soun`):** all `FORM`/`AIFC`, chunks FVER COMM [MARK] INST SSND APPL (91 + 7 with MARK) or, for
    `mu03`, FVER COMM `wave` SSND; COMM: rate 80-bit extended = **44100**, sampleSize 16, compression **`ima4`**
    (name `IMA 16 bit 4-to-1`, COMM 40 bytes; `mu03` 30 bytes `IMA 4:1`); SSND offset 0, blockSize 0, data bytes ==
    numFrames × 34 × channels exactly in all 99. Audio.pak 96 × mono, Σ packets 48,959 → **3,133,376 frames**; Music.pak
    3 × stereo: mu03 134,892 · ammu 23,966 · inmu 41,153 packets. FORM size == file − 8 in 98; `mu03` 76 short (delta 1).
    MARK/INST loop points exist in 7 effects — the game ignores them (no loop) — kit exposes nothing of them.
21. **IMA4 = CoreAudio:** a line-by-line Python port of `IMA4.swift` decodes **all 99 Deimos sounds and the 10 Aki 1.1.0
    AIFCs sample-identical to `afconvert -f WAVE -d LEI16`** (Aki = the kit's second game for AIFC/ima4). FNV-1a 64 over
    Int16 LE (the `SndPCMTests.fnv1a` definition): acbo `0x05b903825977c1b9` (436 pkts) · clic `0xad17745ee5fd8f38` (15) ·
    ammu `0xa4e1357f237dcca7` · inmu `0xa9ff0f86ea2dfab6` · mu03 `0xda67ed4558e63ea3` · Aki GameOver (stereo, 1,963)
    `0x1d968f02f55b5e41` · Aki TileMatch (mono, 111) `0x867b354317469a2d`. **But** the game's own effect mixer
    (`FUN_100d1d90`) strips every packet preamble and decodes one continuous nibble stream (no resync; 66·P samples,
    the last 2·P from zeroed bytes) — bank MED. Music goes through the Sound Manager (= Apple's decoder). Phase 0 decodes
    every sound with the kit for the census; the faithful effect decode is Phase 1's (Phase-1 section).
22. **Load gate** (`FUN_100d1780`, sound-music §2.2): accepts AIFF/AIFC or RIFF/WAVE, compression NONE or `ima4`,
    **channels < 2** for effects (`soun` via `FUN_10047330`); music streams the pak byte range itself (no channel gate).
    No WAVE and no uncompressed sound ships in any Ambrosia title in hand → `WAVEAudio` and the AIFF PCM path are
    synthetic-tested with an `AVAudioFile` oracle (the brief requires them; the original's loader accepts them).

---

## Scope

- **Does:**
  1. HectorKit: `CRC32`, `StoredZipArchive` (HectorResources); `AIFFAudio`, `WAVEAudio`, `SoundFile` (HectorAudio);
     `HECTORKIT_DATA_DEIMOS` locator; gate floor +37; D10; STATE/CLAUDE lines; tag `v0.3.0`.
  2. Classics: `Resources/Deimos/Data/` (5 files) in git; `.gitignore`/`.gitattributes`; DECISIONS D23.
  3. `Deimos/Core`: `DeimosData` locator, `TagName`, `TagIndex`, `DeimosText`, `TokenReader`, `StringList`,
     `FloatList`, `IDList`, `RectList`, `ColorList`, `TextFormat`, `Film`, `LevelDefinition`, `UnitDefinition`,
     `PlayerDefinition`, `WeaponDefinition`, `TGAImage`, `GIFImage`, `QuickDrawColor` (16-bit + system CLUT),
     `SpritePlate` (scan), `SpriteGroup` (encoder), `DeimosSound` (load gate → PCM); `deimos-census` (+ `--render`);
     `docs/deimos/data-census.md`.
- **Untouched (load-bearing):** every existing HectorKit source file and test (new files only, plus `FLOOR`, docs, the
  gate's `export`/`echo` lines); HectorKit `Package.swift`; `IMA4`/`SndSound` behaviour; `Aki/`, `BubbleTrouble/`,
  `BubbleTroubleX/`, `project.yml` (no Deimos app target); `docs/deimos/` bank files except one pointer line in
  `INDEX.md` (C7); Classics `docs/STATE.md`, `RESUME.md`, handoffs (orchestrator's); the archive (read-only).
- **Explicitly deferred (owner):**
  - The game's own effect decode (preamble-stripped continuous IMA stream, 66·P samples) and the 16-voice mixer →
    Phase 1 sound task (Research note 21).
  - Blitters (modes 0–3, scale, tint, COST), glyph table use, text layout, film *replay* → Phase 1.
  - Sprite Groups Cache / Units Cache files (load-time accelerators, never shipped, no behavioural trace) → never,
    unless Phase 1 rules otherwise; the OS X load-all "pseudo-groups" for upper-case IDs (sprite-manager §4.1) → Phase 1
    note only.
  - Writing tags back to `Local` (Last Film save, `FUN_10002640`) and `pref` → Phase 1.
  - GIF features the census lacks (interlace, LCT, transparency, multi-image, offset images), TGA types ≠ 2 / depth ≠ 16,
    AIFC codecs other than `NONE`/`ima4`, WAVE codecs other than PCM 8/16 → refused now, implemented when a file needs them.
  - Promoting GIF/TGA to HectorKit → only if a second game needs them (Q2).
  - The app resource fork, `Register Deimos Rising`, the Player Guide → Q1.

---

## Open questions for Ben (real forks only)

- **Q1 — the rest of the game folder.** Commit and census the app's resource fork now (as `Resources/Deimos/Deimos
  Rising.rsrc`, data fork; 12 PICT, 6 DITL incl. the config dialog 190, menus, cursors — Phase 1's front end needs
  them) and the Player Guide HTML (the rules oracle, 44 KB + 50 images)? **Recommended: yes to the resource fork as
  optional Task C8** (≈ one small task: HectorKit already reads PICT/DITL); the guide can wait. Default if unanswered:
  defer both to Phase 1.
- **Q2 — where GIF/TGA live.** D22's wording lists "im08/im16 images" among the HectorKit decoders; this plan follows the
  brief and puts them in `DeimosCore` (kit rule: a decoder is "general" only after two games' data; only Deimos ships
  GIF/TGA). Promote later if Cythera/Ferazel ever need them. **Default: DeimosCore** (recorded in D23.2).

(Not questions — Ben's eyes items: INDEX #10 upright menu, from `--render`; nothing else in Phase 0 is visible.)

---

## Tasks

Gate command (HectorKit, every K task):
`cd "$HK" && HECTORKIT_TEST_LOG="${TMPDIR:-/tmp}/hk-deimos-$$.log" tools/check-zero-skip.sh 2>&1 | tail -n 1`.
Classics suite (every C task from C1): `cd "$WT/Deimos/Core" && swift test > "${TMPDIR:-/tmp}/deimos-$$.log" 2>&1;
grep -cE "^Test Case '.*' (passed|failed|skipped) \(" "${TMPDIR:-/tmp}/deimos-$$.log"; grep -cE "^Test Case '.*' (failed|skipped) \(" "${TMPDIR:-/tmp}/deimos-$$.log"` → the stated total, then `0`.
"+N tests" = executed rises by exactly N. Review legs (Fable reviewers, report everything with confidence) are listed
in "Execution order".

### Task K0 — HectorKit baseline (no commit)
- Steps: `git -C "$HK" fetch origin && git -C "$HK" status` (clean, on `deimos-phase0`); `git -C "$HK" rebase origin/main`
  if behind; `swift build` in `$HK`; the gate.
- Verify: gate PASS; record E₀ (**252** at `0467025` unless origin moved) and the HEAD sha.

### Task K1 — `CRC32` + `StoredZipArchive` + Deimos locator (+14 tests)
- Files (new): `Sources/HectorResources/CRC32.swift`, `Sources/HectorResources/StoredZipArchive.swift`,
  `Sources/HectorTestSupport/HectorData+Deimos.swift`, `Tests/HectorResourcesTests/StoredZipArchiveTests.swift`,
  `Tests/HectorResourcesTests/DeimosPakCensusTests.swift`. Edit: `tools/check-zero-skip.sh` (export + echo
  `HECTORKIT_DATA_DEIMOS` default `$HOME/Developer/Ambrosia/Resources/ambrosia-extracted/Action-Adventure/DeimosRising/Deimos Rising 1.0.6 (volume)/Deimos Rising/ Data/Paks`; FLOOR).
- Contracts:
  - `public enum CRC32 { public static func checksum<S: Sequence>(_ bytes: S, initial: UInt32 = 0) -> UInt32 where S.Element == UInt8 }`
    — IEEE 802.3 reflected polynomial 0xEDB88320, as ZIP; `checksum("123456789") == 0xCBF43926`.
  - ```swift
    public struct StoredZipArchive: Sendable {
        public struct Entry: Sendable, Equatable {
            public let name: String            // CD name, Mac Roman decoded (MacRoman.decode), '/' separators
            public let isDirectory: Bool       // name ends in "/"
            public let method: Int             // CD +10
            public let flags: Int              // CD +8 (reported, never acted on)
            public let crc32: UInt32           // CD +16 (reported; never checked on read — the game doesn't)
            public let compressedSize: Int, uncompressedSize: Int
            public let localHeaderOffset: Int
            public let dataOffset: Int         // LHO + 30 + LOCAL nameLen + LOCAL extraLen
        }
        public enum ReadError: Error, Equatable {
            case noEndOfCentralDirectory, multiDisk, zip64Unsupported, truncated(String), badSignature(String)
            case notStored(name: String, method: Int)      // method != 0
            case sizeMismatch(name: String)                // csize != usize
        }
        public let entries: [Entry]            // central-directory order
        public init(data: Data) throws         // walks EOCD (backwards search over ≤ 65,535 + 22 bytes) → CD → each local header
        public init(contentsOf url: URL) throws // Data(contentsOf:options: .mappedIfSafe)
        public func data(for entry: Entry) throws -> Data   // slice; throws notStored / sizeMismatch for that entry only
    }
    ```
    Listing never fails on a compressed entry (the game rejects per entry); `data(for:)` does. EOCD/CD/local-header
    bounds and signatures checked; any 0xFFFF/0xFFFFFFFF zip64 sentinel in EOCD → `zip64Unsupported`; disk numbers ≠ 0 →
    `multiDisk`. Doc comment: "verified on one game's data plus `/usr/bin/zip -0` output; not yet called general".
  - `extension HectorData { public static let deimosPaksVar = "HECTORKIT_DATA_DEIMOS" }` (doc: "a game's folder of
    STORED ZIP archives + AIFC sounds; a data locator for the census, like `btxVar` (D3)") and
    `public func deimosPak(_ fileName: String) throws -> StoredZipArchive` (XCTSkip naming the variable when absent).
- Tests — `StoredZipArchiveTests` (synthetic, built in-test with little-endian helpers):
  `testCRC32KnownVector` · `testListsFilesAndDirectoriesInCentralOrder` · `testDataOffsetUsesLocalHeaderLengths`
  (local extra 7 bytes, central extra 18 → offset from local) · `testCompressedEntryListedButRefusedOnRead`
  (method 8 → `notStored`, other entries still read) · `testSizeMismatchRefusedOnRead` ·
  `testEndOfCentralDirectoryFoundBehindComment` (100-byte archive comment) · `testZip64AndMultiDiskRefused` ·
  `testTruncatedAndHostileInputThrowsNeverTraps` (every prefix of a 3-entry archive throws; CD offset/size past EOF and
  nameLen past EOF throw before allocating) · `testMatchesSystemZipStoredOutput` (writes 3 temp files, runs
  `/usr/bin/zip -0 -X -q`, reads the archive: names, sizes, bytes and CRCs equal the inputs) · `testMacRomanNames`
  (name byte 0xA5 → "•") = **10**.
- Tests — `DeimosPakCensusTests` (`deimosPak`): `testFourPaksStructure` (per pak: CD entries 96/776/11/3, files
  96/763/9/3, folders 0/13/2/0, file sizes of note 1) · `testEveryEntryStoredAndCRCMatches` (871 files: method 0,
  csize == usize, `CRC32` of `data(for:)` == `crc32` for all; flags all 0 except the one `ammu` entry = 2) ·
  `testInterfaceWorkedEntry` (`im16/Developer Credit[decr].TGA`: LHO 106, dataOffset 185, size 614,418, first 18 bytes
  `00 00 02 00 00 00 00 00 00 00 00 00 80 02 e0 01 10 01`) · `testEntriesContiguousInOffsetOrder` (each entry's
  dataOffset + size == next LHO; last == CD offset) = **4**.
- Verify: `swift test --filter 'StoredZipArchiveTests|DeimosPakCensusTests'` (env set) → `Executed 14 tests, with 0
  failures`; gate PASS at E₀ + 14; set FLOOR.
- Commit: `HectorResources: StoredZipArchive (STORED-only ZIP, local-header data offsets) + CRC32; HECTORKIT_DATA_DEIMOS census of four paks; floor <n>`.
  Rebase, gate, `git push origin HEAD:main`. Then **R4** (below).

### Task K2 — `AIFFAudio` (AIFF/AIFC → PCM) (+15 tests)
- Files (new): `Sources/HectorAudio/AIFFAudio.swift`, `Tests/HectorAudioTests/AIFFAudioTests.swift`,
  `Tests/HectorAudioTests/DeimosAIFCCensusTests.swift`, `Tests/HectorAudioTests/AkiAIFCCensusTests.swift`. Edit: FLOOR.
- Contracts:
  ```swift
  public struct AIFFAudio: Sendable, Equatable {
      public enum Form: String, Sendable { case aiff = "AIFF", aifc = "AIFC" }
      public enum Encoding: Equatable, Sendable { case pcm(bitsPerSample: Int); case ima4 }   // AIFC 'NONE' → .pcm
      public let form: Form
      public let channels: Int
      public let frameCount: Int        // COMM numSampleFrames — PACKETS for ima4, sample frames for pcm
      public let sampleRate: Double     // COMM 80-bit extended, exact
      public let encoding: Encoding
      public let soundData: Data        // SSND bytes after its offset field (blockSize ignored, offset honoured)
      public let declaredFormSize: Int  // FORM size field as stored (mu03: file − 8 − 76)
      public init(data: Data) throws    // throws AudioFileError
      public func linearPCM() throws -> SndPCM   // ima4 → IMA4.decode(packetFrames: frameCount, channels:); pcm8 signed → s<<8; pcm16 BE
  }
  public enum AudioFileError: Error, Equatable {
      case notAIFF, notWAVE, truncated(String), missingChunk(String)
      case unsupportedCompression(String), unsupportedSampleSize(Int), unsupportedChannels(Int)
      case soundDataTooShort(needed: Int, actual: Int)
  }
  ```
  Chunk walk from offset 12 to the END OF THE DATA (not the FORM size — known delta 1), padding odd chunk sizes;
  unknown chunks skipped; COMM + SSND required. Accept channels 1–2 (more → `unsupportedChannels`); compression
  `NONE` (and plain AIFF) at 8/16 bits, `ima4` (sampleSize field ignored for ima4); refuse every other 4CC by name
  (`sowt`, `fl32`, `MAC3`, …). ima4: require `soundData.count ≥ frameCount × 34 × channels`, decode exactly
  `frameCount` packets (trailing bytes ignored). Extended-80 conversion handles exponent/mantissa exactly (44100,
  22254.545454…, 11025 vectors).
- Tests — `AIFFAudioTests` (synthetic): `testAIFF16BitMonoBigEndian` · `testAIFF8BitSigned` ·
  `testAIFCNoneEqualsAIFF` · `testAIFCIma4DecodesThroughIMA4` (2 hand packets, mono + stereo interleave, equals
  `IMA4.decode` on the same bytes) · `testExtendedRates` · `testChunksWalkedPastDeclaredFormSize` (SSND after a
  FORM size that ends early → still found) · `testOddChunkPaddingAndUnknownChunksSkipped` ·
  `testRefusals` (sowt, 24-bit, 3 channels, missing COMM, missing SSND, short ima4 data) ·
  `testTruncatedAndHostileInputThrowsNeverTraps` · `testPCMMatchesAVAudioFileOracle` (`#if canImport(AVFoundation)`:
  a synthetic 16-bit stereo AIFF written to a temp file; AVAudioFile int16 read == `linearPCM().samples`) = **10**.
- Tests — `DeimosAIFCCensusTests` (env `HECTORKIT_DATA_DEIMOS`, via `deimosPak`):
  `testAllNinetySixEffects` (Audio.pak: 96 AIFC, mono, 44100, ima4, Σ packets 48,959, Σ PCM frames 3,133,376) ·
  `testThreeMusicTracks` (stereo; packets mu03 134,892 · ammu 23,966 · inmu 41,153; mu03 declaredFormSize ==
  data.count − 8 − 76) · `testDecodeHashesPinned` (FNV-1a 64 of note 21 for acbo, clic, ammu, inmu, mu03 — decode one
  track at a time) · `testAfconvertOracle` (`/usr/bin/afconvert -f WAVE -d LEI16` on temp copies of acbo, clic, ammu →
  sample-identical to `linearPCM()`) = **4**.
- Tests — `AkiAIFCCensusTests` (`HECTORKIT_DATA_AKI11`): `testTenAkiAIFCsDecode` (the 10 `.aiff`: all AIFC ima4 44100;
  channels/packets GameOver 2/1,963 · LevelComplete 2/1,696 · LevelStart 2/2,551 · Preview 1/204 · Reshuffle 2/2,298 ·
  TileMatch 1/111 · cancel 1/172 · chime 1/955 · tilehit 2/18 · unclick 2/26; hashes GameOver/TileMatch of note 21) = **1**.
- Verify: filtered run `Executed 15 tests, with 0 failures`; gate base + 15.
- Commit: `HectorAudio: AIFFAudio (AIFF/AIFC NONE + ima4 → PCM via IMA4); Deimos 99 + Aki 10 AIFC census, afconvert oracle; floor <n>`. Push, R4.

### Task K3 — `WAVEAudio` + `SoundFile` dispatcher (+8 tests)
- Files (new): `Sources/HectorAudio/WAVEAudio.swift`, `Sources/HectorAudio/SoundFile.swift`,
  `Tests/HectorAudioTests/WAVEAudioTests.swift`. Edit: FLOOR.
- Contracts: `public struct WAVEAudio: Sendable, Equatable { channels, frameCount, sampleRate: Double, bitsPerSample,
  soundData: Data; init(data:) throws; linearPCM() throws -> SndPCM }` — RIFF/WAVE, `fmt ` format tag **1 only**, 8-bit
  unsigned → `(s − 128) << 8`, 16-bit LE; channels 1–2; chunks walked to the end of data, odd sizes padded, `LIST`/`fact`/
  unknown skipped; other tags (0x11 IMA ADPCM, 0x02, 0xFFFE, 3) → `unsupportedCompression("wav 0x…")`.
  `public enum SoundFile { public static func linearPCM(from data: Data) throws -> SndPCM }` — `FORM` → AIFFAudio,
  `RIFF…WAVE` → WAVEAudio, else `notAIFF` (the shape of the original's `FUN_100d1780` accept rule; doc says so without
  naming the game).
- Tests: `testWAVE16MonoLittleEndian` · `testWAVE8BitUnsignedOffset` · `testStereoInterleaved` ·
  `testListChunkAndOddPaddingSkipped` · `testRefusals` (0x11, 24-bit, 3 ch, missing fmt/data) ·
  `testTruncatedAndHostileInputThrowsNeverTraps` · `testPCMMatchesAVAudioFileOracle` (`#if canImport(AVFoundation)`) ·
  `testSoundFileDispatch` (AIFC, WAVE, garbage) = **8**. (Synthetic only — no WAVE ships in any title in hand; the doc
  comment says "synthetic-verified only".)
- Verify: filtered `Executed 8 tests`; gate base + 8.
- Commit: `HectorAudio: WAVEAudio (PCM 8/16) + SoundFile dispatcher; synthetic + AVAudioFile oracle; floor <n>`. Push, R4.

### Task K4 — HectorKit docs + tag (after K1–K3 on origin/main)
- Edits: `docs/DECISIONS.md` **D10** (next free number after the final rebase): "Stored ZIP + AIFF/AIFC/WAVE in the kit:
  data offset from the local header, listing never refuses / reading does, CRC reported not enforced; chunk walk to end of
  data (a real file's FORM size is short); AIFC NONE + ima4 only via `IMA4` (sample-exact vs afconvert on 99 + 10 files of
  two games); WAVE PCM synthetic-only; HECTORKIT_DATA_DEIMOS accepted as D3", Rejected: zlib/inflate (no STORED-only
  game needs it; not Foundation on all targets) · bounding chunks by FORM size (loses mu03's SSND tail) · AVFoundation
  decode (D6/D9) · GIF/TGA in the kit (one game; Classics D23.2). `docs/STATE.md`: modules + census line ("Deimos: 4
  paks / 871 STORED entries, 99 AIFC ima4; Aki 10 AIFC"), floor, carried "ZIP one game + zip(1); WAVE synthetic".
  `CLAUDE.md` env-var sentence gains `HECTORKIT_DATA_DEIMOS`; `README.md` module list if it has one.
- Tag: `git tag -l v0.3.0` empty → `git tag -a v0.3.0 -m "Deimos: StoredZipArchive, AIFFAudio, WAVEAudio"`; push the tag.
  If it exists, use the next minor and say so in the commit.
- Verify: gate PASS on origin/main HEAD; G2.
- Commit: `docs: Deimos format layer landed (DECISIONS D10, STATE, env vars); tag v0.3.0`. Push, R4.

**R4 — main-checkout catch-up (BTX plan precedent):** after each push, when `git -C ~/Developer/HectorKit status
--porcelain` is empty and it is on `main`, run `git -C ~/Developer/HectorKit pull --ff-only`. Otherwise the Classics
package builds with `HECTORKIT_PATH=$HK` (its manifest reads `Context.environment["HECTORKIT_PATH"] ?? "../../../HectorKit"`,
Task C1). Never edit the shared symlink.

### Task C0 — Data into git + D23 (Classics; independent of HectorKit)
- Steps: in `$WT`: `mkdir -p Resources/Deimos/Data/Paks "Resources/Deimos/Data/Local/film"`; `cp -p` the five files of
  note 1 from `"$G/ Data/…"`; `shasum -a 256` both sides (G3); edit `.gitignore` (`/Resources/` → `/Resources/*` and
  `!/Resources/Deimos/`; keep the stale header comment's line but reword it to "game data: see DECISIONS D23 — Deimos is
  committed; other games via symlinks"); add `.gitattributes` with `Resources/Deimos/** binary`;
  `git status --porcelain --ignored Resources` shows `Resources/Aki/` still ignored and exactly the five data files new.
  DECISIONS **D23** (append): (1) Deimos original data is committed at `Resources/Deimos/Data/{Paks,Local}` (Ben's
  standing ruling over D10's "unchanged for now"; D20 public repo): five files, SHA-256 listed; ` Data` renamed `Data`
  (leading space is a Windows/shell hazard); `HID.bundle`, `Icon\r`, `.DS_Store`, PEF binaries not committed; GitHub's
  50 MiB warning on Game.pak accepted (no LFS — note 2). (2) Layering per the brief: STORED-ZIP + AIFF/AIFC/WAVE in
  HectorKit; GIF/TGA/tags/text/film/sprites in `Deimos/Core` (refines D22's parenthetical; Q2). (3) DeimosCore tests read
  the committed data (no env var, never skip); `DEIMOS_DATA` overrides. Rejected: LFS · data out of git with symlinks
  (Aki/BTX pattern — superseded for new games by Ben's ruling) · keeping ` Data` with the space.
- Verify: G3; G7.
- Commit: `Resources/Deimos: original Deimos Rising 1.0.6 data (4 paks + Last Film) in git; .gitignore/.gitattributes; DECISIONS D23`
  — paths: the five files, `.gitignore`, `.gitattributes`, `docs/DECISIONS.md`.

### Task C1 — `Deimos/Core` skeleton: locator, tag naming, tag index (→ 16 tests)
- Precondition: K1 on HectorKit main and reachable through `../../../HectorKit` (G2-style check on K1's sha) or R4's fallback.
- Files: `Deimos/Core/Package.swift`; `Sources/DeimosCore/{DeimosData,TagName,TagIndex}.swift`;
  `Tests/DeimosCoreTests/{TagNameTests,TagIndexTests,DeimosDataTests}.swift`.
- Manifest contract: package `DeimosCore`, tools 6.0, `platforms: [.macOS(.v15)]`, dependency
  `.package(path: Context.environment["HECTORKIT_PATH"] ?? "../../../HectorKit")`; target `DeimosCore` (products
  HectorResources, HectorAudio); test target `DeimosCoreTests` (DeimosCore, HectorResources, HectorAudio).
  (C7 adds the executable.) Comment header in the Aki style naming this plan.
- Contracts:
  - `public enum DeimosData { public static func dataDirectory() throws -> URL }` — `DEIMOS_DATA` env if set, else the
    repo's `Resources/Deimos/Data` found by walking up from `#filePath` (symlinks resolved, invariant 2); throws
    `DeimosDataError.notFound(String)`. Tests use this (data is in git → never skips).
  - `public struct TagName: Sendable, Equatable { displayName: String; id: FourCC; type: FourCC; init?(entryName: String) }`
    — rules of note 8 (strip after last `/`; reject `.DS_Store`; first `[`…`]` 4 chars; suffix from the first `.`, 15
    chars max, the 15 tables in order). `public struct FourCC: Hashable, Sendable, CustomStringConvertible` (big-endian
    UInt32; `init?(_ s: String)` exactly 4 Mac Roman bytes; `static let none`).
    `public static let typeOrder: [FourCC]` = the 15 types in table order.
  - `public struct TagIndex: Sendable { public struct Record: Sendable, Equatable { type, id, displayName, isLocal: Bool,
    source: Source (.local(URL) | .pak(archiveIndex: Int, entry: StoredZipArchive.Entry)), size: Int };
    public let records: [Record]; public let alerts: [String]` (wrong-folder, duplicates, "Tag Index Incomplete!", skipped
    names — the original's log lines, verbatim text from the bank); `public init(dataDirectory: URL) throws`;
    `public func record(type:id:) -> Record?` (first in list order); `public func records(ofType:) -> [Record]` (index
    order); `public func data(for: Record) throws -> Data` }. Build order and override rules of note 9; zero-size
    skipped; non-zip in Paks skipped with the original's alert; zip in Local skipped; `.tag` files → alert + skip
    (unsupported, none ship).
- Tests: `TagNameTests` — `testDisplayIdSuffix` (`im08/Bomb Crater IA[BOCR].gif` → "Bomb Crater IA", BOCR, im08) ·
  `testSpaceInIdAndCaseSensitivity` (`[bop ]`; `bocr` ≠ `BOCR`) · `testFirstDotSuffixAndTableOrder` (`.IMA`/`.aif` →
  soun, `.TGA` → im16, `.lvl` → leve, unknown suffix → nil) · `testRejects` (`.DS_Store`, no `[`, 3- or 5-char ID) = 4.
  `TagIndexTests` (synthetic temp dirs + zips built in-test) — `testLocalScannedBeforePaks` ·
  `testLocalOverridesEveryPakCopy` · `testPakDuplicatesFirstWins` · `testWrongFolderStillAddedWithAlert` ·
  `testZeroSizeAndNonZipSkipped` · `testIncompleteIndexAlertBelow100` = 6.
  `DeimosDataTests` (real) — `testFivePaksFilesPresentWithSizes` · `testIndexHas872RecordsByType` (note 10 counts) ·
  `testLastFilmIsLocalAndEqualsDemo01` · `testPakOrderAndNoAlerts` (paks Audio, Game, Interface, Music; `alerts` empty) ·
  `testWeaponOrder` (`records(ofType: wede)` IDs = aibg aiic aipb airg plbo) · `testInterfaceDecrBytes` (size 614,418,
  first bytes as K1) = 6. **Total 16.**
- Verify: suite 16 / 0. Commit: `Deimos/Core: package, DeimosData, TagName, TagIndex (Local → Paks, overrides); 16 tests`.

### Task C2 — Text layer: de-obfuscation, U_Token reader, the six small types, film (→ 43 tests)
- Files: `Sources/DeimosCore/{DeimosText,TokenReader,StringList,FloatList,IDList,RectList,ColorList,TextFormat,Film}.swift`;
  `Tests/DeimosCoreTests/{TokenReaderTests,TextListsTests,FilmTests}.swift`.
- Contracts:
  - `public enum DeimosText { public static func decode(_ bytes: [UInt8]) -> [UInt8] }` (involution, note 11).
  - `public struct TokenReader` over `[UInt8]` (C-string semantics: stops at the first NUL): `var cursor: Int`;
    `private(set) var errorCount: Int` + `errors: [String]` (key names); `mutating func string(_ key:, maxLength:) -> String?`
    (nil = key missing, default kept, silent); `id(_:) -> FourCC?`; `int(_:) -> Int32?` (`%i`: optional sign, `0x`
    hex, leading-`0` octal, decimal; stops at first non-digit — "100.000000" → 100); `float(_:) -> Float?` (`%f`);
    `bool(_:) -> Bool?` (exact "TRUE"); `color(_:) -> UInt16?` (note 12); `rect(_:) -> MacRect?`
    (`public struct MacRect: Equatable, Sendable { top, left, bottom, right: Int32 }`, from text l,t,r,b). Non-STR
    misses/malformations increment `errorCount` (= the original's error flag). `static func findAnywhere(...)` variants
    = the order-independent G_Text search (fresh from 0 each key).
  - `StringList(data:)` → `lines: [[UInt8]]` + `string(at:)` (Mac Roman), CR-split rule of note 13.
    `FloatList(data:)` → exactly 220 floats else `TextDataError.wrongCount(expected: 220, actual:)` (positional; generic
    `#`…`<`…`>` walk). `IDList(data:)` → `[(key: String, id: FourCC)]` (4-char assert → error). `RectList` →
    `[(key, MacRect)]`. `ColorList` → `[(key, UInt16)]`. `TextFormat(data:)` → the 16 read keys of data-tags §5 (Loc X/Y,
    Format (enum LEFT CENT RIGH CEBU CEGA with the "0"–"4" + unknown→LEFT rule; `<3>` = CEBU, `<4>` = CEGA), Monospaced,
    DrawShadows, BlendAmount ≤ 32, SpaceBetweenChars ≥ 0, Colorise Do/Color, ColorStrip Do/HOffset/VOffset/Blend/Color/
    MinWidth/MinHeight), `#Size_INT` NOT read; order-independent.
  - `public struct Film: Sendable, Equatable { version, seed: UInt32, level: FourCC, playerCount: Int, players: [Block]
    (2; frames, score (stored − 0xb3ac2, as Int32), level, inputs: [UInt8] (frames bytes)) ; init(data:) throws }` —
    size must be 0x9d68, version 0x2715 else `FilmError.outOfDate(Int)` (the game's "out of date"), frames ≤ 20,000;
    `struct Input: OptionSet` bits 0–6 of note 14.
- Tests: `TokenReaderTests` — `testForwardOnlyCursor` (a key before the cursor is not found → error, cursor unchanged) ·
  `testStringMissingIsSilentAndTruncatesToMaxMinusOne` · `testIdMustBeFourChars` · `testIntUsesPercentI` ("100.000000"
  → 100, "0x10" → 16, "010" → 8, "-1000") · `testFloatAndBool` ("TRUE" vs "True" vs " TRUE") · `testColorPacksHighFiveBits`
  ("52c594" → 0x2B12; "0" → 0; "52c59" → error) · `testRectTextOrderToMacRect` (`<25, 81, 135, 95>` → t81 l25 b95 r135) ·
  `testOrderIndependentSearch` · `testStopsAtNUL` · `testDecodeIsInvolutionAndWorkedColi` (bank §3 bytes → `#scoreBar_Digit\t…<52c594>`) ·
  `testValueCensusOverAllText` (every `#…_TYPE <…>` item of all 473 files read with its suffix's reader: INT 57,140 /
  FLOAT 19,815 / BOOL 4,149 + 63,723 / COLOR 3,223, 0 errors) = 11.
  `TextListsTests` (real, via TagIndex) — `testStringListsLineCounts` (cred 102 · edit 5 · inte 28 · pali 1 · pgsl 37; inte
  line 6 = "Loading Permanent Image:  ", pgsl 0 = "Press Caps Lock", 9 = "REPLAY") · `testFloatList220` (index 32 = 30, 37 =
  204800, 38 = 8, 54 = 416, 55 = 480, 144 = 0.96, 219 = 3, data-tags §3 table) · `testIDLists` (counts of note 13; gaso 0 =
  `clic`; gasp = vigr edut pl1o mebu mebh galo mebu mebh; tesp = 3 × `tesm`) · `testRectList22` (item 0 = t81 l25 b95 r135) ·
  `testColorList` (0x2B12) · `testFiftyFourTextFormats` (format histogram of note 13; BlendAmount ≤ 32 all) ·
  `testEveryTextEntryDecodesWithoutNUL` (473 entries; Mac Roman high-byte file counts 6/79/1) ·
  `testSyntheticWrongFloatCount` · `testSyntheticRectAndIdErrors` · `testFormatIdUnknownFallsBackToLeft` = 10.
  `FilmTests` — `testFourDemosAndLastFilm` (note 14 values ×5) · `testInputBitsDecode` (de01 first non-zero input = left) ·
  `testVersionRefused` (0x2714 → outOfDate) · `testWrongSizeRefused` · `testPlayerTwoBlockEmpty` · `testFramesCapped20000`
  (synthetic 20,001 → error) = 6. **+27 → 43.**
- Verify: suite 43 / 0. Commit: `DeimosCore: text de-obfuscation, U_Token reader, stli/flli/idli/reli/coli/tefo, film; 27 tests`.

### Task C3 — ⚑ MAJOR — Definition parsers: unde, plde, wede, leve (→ 61 tests)
- Files: `Sources/DeimosCore/{UnitDefinition,PlayerDefinition,WeaponDefinition,LevelDefinition,DefinitionLists}.swift`;
  `Tests/DeimosCoreTests/{UnitDefinitionTests,PlayerWeaponLevelTests}.swift`.
- Contracts (struct fields = the bank's key tables, **in reader call order**; names = key minus the type suffix,
  lowerCamel; types per suffix; every row's default from the bank's D@ column):
  - `public struct UnitDefinition: Sendable, Equatable` — unit-def-struct.md §3 (unit scalars, sound records 0x18 =
    {id, minVol, maxVol, priority: Int32; minPitch, maxPitch: Float}, shields/destruct/pickup blocks), `states: [UnitState]`
    (§4; `rules: [UnitRule]` exactly 5 slots §5; `spawnSets: [SpawnSet]` §6), derived `layer` (`grnd`/`air `), `id`.
    `public static func parse(id: FourCC, text: [UInt8], spriteExists: (FourCC) -> Bool) -> (UnitDefinition, errors: [String])`
    — decodes only if `#name_STR` absent (note 11); strict mode (any non-STR error = the original's fatal load error,
    reported, not thrown); post-parse fix-ups of unit-def-struct.md §2.6 in order (shields max, OnTimer max/min and the
    unused-timer zeroing, owner-bool flag `+0x11`, missing sprite face → `none` via `spriteExists`); no caps (numStates and
    numRules loop as read — §2.5), but `numStates > 20` reported as the original's assert text.
  - `PlayerDefinition` — §9 (0x108, 57 keys, 11 IDs default `none`, sound record default {none,100,100,100,1.0,1.0}); four
    sprite IDs checked via `spriteExists`.
  - `WeaponDefinition` — weapons-projectiles.md §1.2 (0x208; spawn records `{name, unit, x, y, setHeading, angle}`; power-up
    air/ground blocks; selection sound default); decodes only if `#type_ID` absent.
  - `LevelDefinition` — waves-and-enemies.md §1 header (name ≤ 0x20, indentifier (sic) ≤ 0x40, description/copyright ≤ 0x100,
    background RECT, image/preview/music/mask/briefing IDs, numObjects) + `objects: [LevelObject]` (unit, layer, x, y,
    heading, stationary, terrainEffects); unknown unit ID → dropped AND count decremented (level-scroll-objects §6.1
    landmine, via a `unitExists` closure); `parseHeaderOnly` variant (objects not built).
  - `public struct DefinitionLists { units: [UnitDefinition], players, weapons, levels; init(index: TagIndex) throws }` —
    master lists in tag-index order; `errors` aggregated.
- Tests: `UnitDefinitionTests` — `testAll386UnitsParseStrictWithZeroErrors` · `testStateRuleSpawnCensus` (1,167 states,
  histogram of note 13, rules 5 everywhere, spawn-set histogram) · `testWorkedExample03p1` (unit-def-struct.md "Worked
  example — Level 3 - Pause 1": every field the bank lists) · `testShieldsMaxFixUpSixUnits` (`bagb bgpb cair icpb icb  jgbu`:
  max == base after parse) · `testNoMissingSpriteResets` · `testPlainTextUnitParsesWithoutDecode` (synthetic) ·
  `testMissingIntIsAnErrorMissingStringIsNot` (synthetic) · `testNumStatesOver20Reported` (synthetic) ·
  `testUnusedStateTimerZeroed` (synthetic) · `testForwardCursorMisparseFollowsOriginal` (synthetic: key missing in state 1
  is taken from state 2) = 10. `PlayerWeaponLevelTests` — `testTwoPlayerDefinitions57Keys` · `testFiveWeaponsInIndexOrder`
  (spawn counts 8/3/1/1/2) · `testWeaponWorkedExample` (weapons-projectiles.md "Worked example" fields) ·
  `testTwelveLevels565Objects` (per-level counts; every level `background_RECT` t0 l0 b3600 r480, music `mu03`,
  briefing `none`) · `testLevel07Header` (Mariner Valley / Lucena / jum2 / jup2 / jut2 / 38 objects) ·
  `testEveryPlacedUnitExists` · `testUnknownUnitDropsAndDecrements` (synthetic) · `testLayerIdAgreesWithGroundFlag`
  (565/565, level-scroll-objects §6.1) = 8. **+18 → 61.**
- Verify: suite 61 / 0. Commit: `DeimosCore: unde/plde/wede/leve parsers in the original's call order; strict census 386/2/5/12; 18 tests`.

### Task C4 — `im16`: TGA → RGB555, top-down (→ 68 tests)
- Files: `Sources/DeimosCore/TGAImage.swift`; `Tests/DeimosCoreTests/TGAImageTests.swift`.
- Contract: `public struct TGAImage: Sendable, Equatable { width, height: Int; pixels: [UInt16] /* QuickDraw x1R5G5B5,
  row 0 = visual top, bit 15 cleared */; init(data: Data) throws }` — image type 2 only; bpp 16 only (the original warns
  and imports anyway — refused here, invariant 4, doc says so); honour descriptor bit 5 (0 → flip rows) and refuse bit 4
  (right-to-left); skip ID field; ignore colour-map spec when map type 0; ignore anything after the pixels (footer);
  require `18 + idLen + 2wh ≤ count`. `TGAError` named cases.
- Tests: `testSyntheticBottomUpFlippedTopDownStays` · `testRefusals` (type 10, 24 bpp, bit 4, truncated) ·
  `testAll45DecodeToCensusSizes` (size histogram, 14 footers, no bit-15 pixel) · `testMediaMaskCensus` (12 masks:
  712,245 / 117,194 / 1 stray `0x256b` in `ist3`) · `testCanyon1MaskOrientation` (column 5 water rows 330–348 top-down) ·
  `testBackgroundRectMatchesMaps` (12 maps 480 × 3600 = each level's background_RECT; mask aspect = map aspect, ratio 5) ·
  `testMenuFirstStoredRowIsBottom` (the stored first row == decoded last row) = **7 → 68**.
- Verify: suite 68 / 0. Commit: `DeimosCore: im16 TGA → top-down RGB555 (descriptor bit 5 honoured); 45 TGA census; 7 tests`.

### Task C5 — ⚑ MAJOR — `im08`: GIF, QuickDraw colour, plate scan, frame encoder (→ 84 tests)
- Files: `Sources/DeimosCore/{GIFImage,QuickDrawColor,SpritePlate,SpriteGroup}.swift`;
  `Tests/DeimosCoreTests/{GIFImageTests,SpriteGroupTests}.swift`.
- Contracts:
  - `public struct GIFImage: Sendable { width, height: Int; palette: [(r: UInt8, g: UInt8, b: UInt8)]; indices: [UInt8]
    (row 0 = top); init(data: Data) throws }` — GIF87a/89a; global table required; one image; LZW (min code size 2–8,
    clear/end codes, 12-bit cap, deferred-clear tolerated); extensions skipped except GCE inspected; refuse (named):
    local colour table, interlace, transparency flag, image ≠ (0,0, screen size), second image, index ≥ palette count.
  - `public enum QuickDrawColor { static func rgb555(_ r: UInt8, _ g: UInt8, _ b: UInt8) -> UInt16 /* c>>3 */;
    static let systemCLUT8: [(UInt8, UInt8, UInt8)] /* 256, note 15 order */; static func systemIndex(_ r:, _ g:, _ b:) -> UInt8
    /* 4-bit inverse-table cell → nearest CLUT entry, ties → lowest index; memoised 4096 cells */ }` — doc carries the MED
    labels and the note-15 evidence.
  - `public enum SpritePlate { static func frameRects(alphaIndices: [UInt8], width: Int, height: Int) throws -> [MacRect] }`
    — note 17 exactly, on SYSTEM-CLUT indices of the alpha plate (`systemIndex` of each palette colour); asserts become
    `SpritePlateError` cases with the original's assert texts.
  - `public struct SpriteGroup: Sendable { id: FourCC; frames: [SpriteFrame]; init(colour: GIFImage, alpha: GIFImage,
    id: FourCC) throws }`; `public struct SpriteFrame: Sendable, Equatable { rect: MacRect; width, height: Int; key: UInt16;
    pixels: [UInt16] /* RGB555 */; alphaMap: [UInt16]? /* 0…31, 0x20, 1000 */; var blockSize: Int /* 0x18 + 2wh (+2wh) */ }`
    — sizes must match ("Sprite color and alpha plates are not equal size"); key = colour pixel (2,0) via `rgb555`; alpha
    plate converted with `rgb555`; encoder rule of note 18; `SpriteGroup.load(id:index:)` pairs `abcd` with `ABCD`.
- Tests: `GIFImageTests` — `testSyntheticLZWVectors` (hand-encoded 4×4 with clear/end and code-width growth; a 12-bit
  table fill) · `testRefusals` (LCT, interlace, transparency, offset image, two images, bad index, truncated LZW) ·
  `testAll250DecodeToHeaderSizes` · `testBombCraterPlates` (bank §2.3 palette + rows 0–4/18–20 indices) = 4.
  `SpriteGroupTests` — `testRGB555IsHighFiveBits` (222 → 27, 140 → 17; the 253 used palette components where rounding would
  differ, counted over all plates) · `testSystemCLUT8Table` (256 entries; index = 36·r + 6·g + b over levels FF CC 99 66 33 00
  for 0–214: 0 = FFFFFF, 5 = FFFF00, 210 = 0000FF, 214 = 000033; 215 = EE0000, 225 = 00EE00, 235 = 0000EE, 245 = EEEEEE,
  254 = 111111, 255 = 000000) · `testSystemIndexCells` ((8,0,255) and (0,0,255) → 210; FFFFFF → 0; 000000 → 255) · `testPlateScanAsserts` (synthetic p0 == p1, w < 3) · `testBocrWorkedExample` (key 0x0360,
  rects, blocks 1048/984/648, first colour row 8×0360 4×0842 4×0360, first alpha row 32×8 28 30 28 30 32×4, empty rows
  {15} and {0,6,7}) · `testGlowUsesEightBitScan` (GLOW rect 3 = (51,279,100,328), not the RGB-compare (8,279,100,328);
  12 frames) · `testAll125GroupsCensus` (125 groups, 2,554 frames, 2,553 with maps, Σ px 3,129,511, Σ block bytes
  12,579,236, max 218 × 110) · `testTesmFrame90IsInvisibleSpace` (rect (3,846,16,850), no alpha map) ·
  `testUpperCaseIdsAreAlphaPlates` (every IA ID = upper(IC ID)) · `testEncoderSyntheticRules` (key → 0x20, red 31 → 0x20,
  empty row → 1000, no visible pixel → nil map) · `testFrameLimits` (synthetic 301-wide frame → error) ·
  `testColourKeyHistogram` (24-bit colour at (2,0) of the 125 colour plates: (0,239,0) 85 · (239,0,0) 24 · (0,173,0) 4 ·
  (0,140,0) 2 · ten colours once each: (0,255,156) (0,222,0) (49,156,206) (255,8,8) (255,255,0) (0,0,255) (173,0,0)
  (255,206,0) (49,49,99) (0,189,0)) = 12.
  **+16 → 84.** (If any GLOW/total number differs: STOP — the CLUT/inverse-table rule is the suspect; report both.)
- Verify: suite 84 / 0. Commit: `DeimosCore: im08 GIF (LZW), QuickDraw 16-bit + system-CLUT colour, plate scan, frame encoder; 125 groups / 2554 frames; 16 tests`.

### Task C6 — `soun`: the load gate over the kit (→ 88 tests) — needs K2 + K3 on HectorKit main
- Files: `Sources/DeimosCore/DeimosSound.swift`; `Tests/DeimosCoreTests/DeimosSoundTests.swift`.
- Contract: `public enum DeimosSound { static func effectPCM(_ data: Data) throws -> SndPCM` (SoundFile, then the original's
  gate: channels < 2 → else `DeimosSoundError.stereoEffect`, compression NONE/ima4 only — the doc notes the kit decode is
  CoreAudio's, not the game mixer's; Phase 1); `static func musicInfo(_ data: Data) throws -> AIFFAudio` (no channel gate;
  the byte range is what Phase 1 streams) }`.
- Tests: `testNinetySixEffectsPassTheGate` (all 96 → mono PCM, 44100, frames 3,133,376 in total) ·
  `testThreeMusicTracksAreStereoAndRejectedAsEffects` (`musicInfo` ok; `effectPCM` → `stereoEffect`) ·
  `testSyntheticWAVEEffectAccepted` · `testSyntheticUnsupportedCodecRejected` = **4 → 88**.
- Verify: suite 88 / 0. Commit: `DeimosCore: soun load gate (mono effects, NONE/ima4) over HectorAudio; 4 tests`.

### Task C7 — `deimos-census` + `data-census.md` + reference integrity (→ 98 tests) — needs K4 landed
- Files: `Deimos/Core/Package.swift` (add `.executable(name: "deimos-census")`, `.executableTarget(name: "deimos-census",
  dependencies: ["DeimosCore", HectorResources, HectorAudio])`, `.testTarget(name: "DeimosCensusTests", dependencies:
  ["deimos-census", "DeimosCore"])`); `Sources/deimos-census/DeimosCensus.swift`; `Tests/DeimosCensusTests/DeimosCensusTests.swift`;
  `Tests/DeimosCoreTests/ReferenceIntegrityTests.swift`;
  `docs/deimos/data-census.md` (new); `docs/deimos/INDEX.md` (one pointer line under "Topical files").
- Tool contract: `deimos-census <Data dir> [--render <out dir>]`; Markdown on stdout, entry NAMES never machine paths;
  exit 0 / 1 any failure / 2 bad args (Aki convention). Testable seam `enum DeimosCensus { static func render(dataDirectory:
  URL) -> (stdout: String, failures: Int) }` (`@testable import deimos_census`). Sections: 1 files (5, sizes, SHA-256) ·
  2 paks (CD entries/files/folders/CRC) · 3 tag index (records by type, overrides, alerts) · 4 **every entry, one line**
  (pak · type · ID · name · size · result: GIF w×h → n frames / TGA w×h / AIFC ch·packets·frames / text parsed summary /
  film level·ticks) — 872 lines incl. Local · 5 sprite groups (125 lines: id, plate size, frames, maps) · 6 text (per-type
  numbers of note 13) · 7 sound (note 20) · 8 films · Totals. `--render` (ImageIO, census-only): `menu.png`,
  `background.png`, `canyon1-map.png` (top-down), `bocr-frames.png`, `tesm-plate.png` into the given dir (git-ignored `out/`).
- **Exact summary lines** (each a whole stdout line, in this order; Totals last):
  ```
  # Deimos Rising 1.0.6 — data census
  files 5 · paks 4 (Audio.pak 96 · Game.pak 763 · Interface.pak 9 · Music.pak 3) · local 1 · CRC ok 871
  tags 872 · coli 1 · film 5 · flli 1 · idli 6 · im08 250 · im16 45 · leve 12 · plde 2 · reli 1 · soun 99 · stli 5 · tefo 54 · unde 386 · wede 5 · overridden 0 · alerts 0
  im08 250 · sprite groups 125 · frames 2554 (alpha maps 2553) · pixels 3,129,511 · encoded bytes 12,579,236 · max frame 218×110
  im16 45 · 480×3600 12 · 96×720 12 · 146×306 12 · 640×480 5 · other 4 · water px 117,194
  soun 99 · effects 96 mono ima4 44100 Hz (frames 3,133,376) · music 3 stereo ima4 (packets 134,892 · 23,966 · 41,153)
  text 473 · stli 173 lines · flli 220 · idli 130 · reli 22 · coli 1 · tefo 54 · plde 2 · wede 5 (spawns 15) · leve 12 (objects 565) · unde 386 (states 1,167) · token errors 0
  film 5 · version 10005 · de01 le07 4809 · de02 le06 8357 · de03 le02 10058 · de04 le08 5649 · last le07 4809
  Totals: entries 872 (pak 871 + local 1), decoded 872, failures 0
  ```
- Tests (`DeimosCensusTests`): `testSummaryLinesExact` (the nine lines verbatim, in order, Totals last; failures 0) ·
  `testEveryEntryHasOneLine` (872) · `testStdoutEqualsCommittedCensus` (stdout byte-equals the body of
  `docs/deimos/data-census.md` below its rule, via `#filePath`) · `testExitCodes` (bad args → 2; a temp Data dir with one
  corrupt GIF → 1 and the failure line names it) · `testRenderWritesFivePNGs` (`#if canImport(ImageIO)`, temp dir) = 5.
  `ReferenceIntegrityTests` (DeimosCoreTests, through `TagIndex` + `DefinitionLists`): `testPermanentListsResolve` (gasp 8 →
  im08 groups · gaso 24 → soun · gaob 40 → 38 unde + `pl01`/`pl02` plde · gate 54 → tefo · tesp 3 → `tesm`) ·
  `testLevelResourcesResolve` (12 × map/preview/mask → im16, music → soun) · `testUnitReferencesResolve` (772 unit-ID
  references → unde: stateSpawnSetSpawn 532 · destructSpawn 99 · stateRuleUnit 93 · destructCoin 28 ·
  destructCoinOnGroupKill 15 · collision_Spawn 5) · `testUnitFacesAndSoundsResolve` (1,553 sprite faces → im08 groups;
  2,711 sound IDs → soun or `none`) · `testGlyphFontHas91Frames` (`tesm` = frames 0–90 of data-tags §5) = 5. **+10 → 98.**
- Doc: `data-census.md` = header (generated date, HectorKit sha + tag, Classics sha, the re-run commands:
  `swift build --package-path Deimos/Core -c release` and `"$(swift build --package-path Deimos/Core -c release
  --show-bin-path)/deimos-census" "$PWD/Resources/Deimos/Data"`), a "Spec-vs-data deltas" list (= the Known deltas 1–7
  and Research notes 15, 21 in two lines each), the rule `---`, then stdout verbatim.
- Verify: G4 (98 / 0), G5 (tool exit 0; last line `Totals: entries 872 (pak 871 + local 1), decoded 872, failures 0`), G6.
- Commit: `Deimos/Core: deimos-census + DeimosCensusTests + reference integrity; docs/deimos/data-census.md (872 entries, 0 failures)`.

### Task C8 — (only if Q1 = yes) App resource fork
- Steps: copy `$G/Deimos Rising/..namedfork/rsrc` to `Resources/Deimos/Deimos Rising.rsrc` (data fork); SHA-256 into D23;
  census section 9 via `ResourceReader.read(fileAt:)` + `PICT.decodeAny` / `Ditl.decode` (every PICT decodes or is named
  refused; 6 DITL items parse); tests `testAppResourceForkTypeCounts` (39 types of note 3) · `testEveryPICTAndDITLDecodes`.
  Census lines/ladder grow accordingly (STOP-and-report rule applies to the new numbers; the planner did not decode them).
- Commit: `Resources/Deimos: app resource fork as data-fork .rsrc; census section 9`.

### Task C9 — Final gates + DECISIONS as-built
- Steps: re-run G1 (on origin/main), G2, G3, G4, G5, G6, G7; append to D23 an "As built" paragraph (HectorKit tag + sha,
  floor, DeimosCore test total, census Totals line, the MED items carried: notes 15/21, INDEX #10 for Ben); `docs/deimos/INDEX.md`
  pointer already in C7. **STATE/RESUME/handoff are the orchestrator's.**
- Commit: `docs: Deimos Phase 0 as built (D23)`.

---

## As built — corrections from the Phase 0 reviews (2026-10-06)

The research notes above keep the planner's text; ⚑ marks the corrected spots. In one place:
- **Oracle.** `ghidra/Deimos_pef.decompiled.c` was never produced for 1.0.6; implementers and reviewers worked from the
  disassembly listing `~/Developer/Ambrosia-Classics/ghidra/deimos-proj/disasm-review3-all.txt` plus the memory images `mem/10000000.bin` (code,
  base 0x10000000) and `mem/100de330.bin` (data, base 0x100de330, r2 = 0x100e6330). Every address cited in the
  DeimosCore doc comments is a listing address.
- Note 11: the one stli with Mac Roman bytes is `edit`, not `cred`.
- Note 12: COLOR `"0"` is an error (`FUN_10010990` returns false; the wrapper logs "Invalid COLOR."); INT/FLOAT with no
  digits store nothing and raise no flag; RECT zeroes its destination before the lookup (the one reader that writes on
  failure). BOOL value census = TRUE 4,201 / FALSE 64,203 (the probe missed the apostrophe key).
- wede strict mode is ON (`1002b994 li r4,1; bl 0x1002c4d0`), fatal like unde/plde; `leve` has none.
- Note 16: shipped GIF global tables are 8–256 entries.
- Invariant 4, one deliberate exception (R-D fix pass, kept by R-E): `GIFImage`'s LZW loop accepts a stream whose
  codes end at exactly width × height pixels with no end code (`GIFImage.swift` "data ended at the last pixel"); a
  stream ending short of w × h still throws `truncatedLZW`. Lenient where browsers and QuickTime are, never inventing pixels.
- Note 19 / Known delta 3: the stray mask pixel is in `int3`; the TGA stray is header byte 7 (colour-map entry size)
  = 0x18 with colour-map type 0.
- Tag index (R-B, listings `100016c0–10001f14`): duplicates are counted per Local flag after all records and before
  overrides (a pair logs "(2)" twice); the zip test is lower-cased `strstr`; a rejected zip entry ends its pak's
  enumeration; alert lines are the binary's format strings.
- Test ladder as built: C7 **99** (the census suite has 5 + DeimosCoreTests 94), review fixes R-B +2, R-C +1, R-D +0
  → 102. C8 STOPPED at its decode gate (2026-10-06): HectorKit `PICT.decodeAny` refuses 9 of the 12 app-fork PICTs
  (opcode 0x009B DirectBitsRgn, 16-bit packType 3: 130 135 190–193 195–197); PICT 128/900/1000 and all 6 DITLs decode.
  Nothing of C8 is committed; the orchestrator rules (kit support for 0x009B, or record them as named refusals).
  ⚑ Resolved: the orchestrator ruled kit support — HectorKit `c4a8866` (D11) decodes 0x009B, doc minors `33d4dee` (floor
  301); C8 landed at `7b0a8fe` (PICT 12/12, DITL 6/6, items 76; +2 tests), R-E fixes at `f93a974` → ladder **104**; C9 gates and
  numbers: DECISIONS D24 "As built".

## Execution order

Waves — harden the shared layer first, then march:

| wave | HectorKit (`$HK`) | Classics (`$WT`) | review leg (Fable, after the wave) |
|---|---|---|---|
| A | K0 → K1 (push, R4) | C0 (data + D23; no kit dependency) | **R-A**: K1 + C0 (zip reader vs bank §1, data integrity) |
| B | K2 → K3 (push, R4) | C1 (needs K1) → C2 | **R-B**: K2/K3 (chunk walk, refusals, oracles) + C1/C2 (tag rules, token semantics) |
| C | K4 (docs, tag) | C3 ⚑ ‖ C4 → C5 ⚑ | **R-C**: C3 against unit-def-struct §2–§9 / weapons §1 / waves §1 key tables; **R-D**: C4/C5 against notes 15–19 |
| D | — | C6 (needs K3) → C7 → (C8) → C9 | **R-E**: census doc, golden test, every Known delta disclosed |

Test ladder (Classics, cumulative, STOP if different): C1 16 · C2 43 · C3 61 · C4 68 · C5 84 · C6 88 · C7 **98**.
HectorKit ladder (from E₀): K1 +14 · K2 +15 · K3 +8 = **+37**.
Implementers: Opus, one task per session-leg, two ⚑ MAJOR tasks (C3, C5) each get their own leg. Reviewers report every
finding with a confidence; fixes land before the next wave starts.

---

## What Phase 1 (step 3, the build plan) will need from Phase 0

- `TagIndex` as the only data door: `record(type:id:)`, `records(ofType:)` (master-list order), `data(for:)`; Local-override
  semantics; the `Last Film` write-back path is Phase 1's (re-index after save).
- Parsed tables: `FloatList` (220 permanent floats by index — FPS 30, sound channels 8, game area 416×480, …), `StringList`
  (pgsl 37 game strings, inte, cred), `IDList` (gasp 8 / gaso 24 / gaob 40 / tesp / gate 54), `RectList` (inre 22),
  `ColorList`, `TextFormat` ×54, `DefinitionLists` (386 units with states/rules/spawn sets, 2 players, 5 weapons,
  12 levels / 565 placements), `Film` (4 demos + last) for the attract mode and replay goldens.
- Pixels: `SpriteGroup` frames exactly as the blitters consume them (RGB555 + key + alpha map with 0x20/1000 markers);
  `TGAImage` top-down RGB555 for maps (480×3600), masks (`mask[y/5][x/5] == 0x001f`), previews, menu/scorebar screens.
- Sound: PCM for every `soun` via the kit; **Phase 1 must add the game's own effect decode** (preamble-stripped continuous
  IMA stream, 66·P samples — sound-music.md §2.2) and the 16-voice / 8-audible mixer, and stream music from the pak byte
  range with the whole-SSND seamless loop (§6.3).
- Open MED items Phase 1 inherits: 24→16 truncation and 8-bit inverse-table mapping (notes 15), the effect decode (note 21),
  INDEX #10 (Ben's eyes on `menu.png`), the app resource fork if Q1 deferred it (config dialog DITL 190, alerts).
- The glyph map (data-tags §5) over `tesm`'s frames 0–90 (frame 90 = invisible 4-px space, verified here).

---

## Pre-execution self-audit

1. Every brief ruling has a task? ZIP + AIFF/AIFC/WAVE + IMA4 in kit (K1–K3) ✅; `HECTORKIT_DATA_DEIMOS` under the
   zero-skip gate (K1) ✅; merged to kit main before Classics consumes (C1/C6/C7 preconditions, R4) ✅; Deimos formats in
   `DeimosCore` (C1–C6) ✅; census of 871 + Local with 0 failures (C7) ✅; data in git with folder decision (C0) ✅;
   images "as the original" with MED flagged (notes 15, C5) ✅; Open questions + Phase-1 section ✅.
2. Does any kit file name the game? `HectorData+Deimos.swift` and test files only (invariant 1) ✅. The `SoundFile` doc
   describes the accept rule without the game name ✅.
3. Can Classics build against a stale HectorKit main checkout? C1 precondition + `HECTORKIT_PATH` fallback ✅→FIXED:
   added the env fallback to the C1 manifest contract (the BTX core manifest lacks it).
4. `.gitignore` re-include trap (`/Resources/` excludes the directory; `!` beneath cannot re-include) ✅→FIXED: C0 changes
   it to `/Resources/*` and checks the Aki symlinks stay ignored.
5. Is "decode exactly as the original" honoured where it bites? 8-bit-index scan (GLOW proves it matters) ✅; 24→16 rule
   pinned with the 253-component count ✅; TGA flip from bit 5, not from QuickTime folklore ✅; data offset from the local
   header ✅; `%i` for INTs (plde floats) ✅; forward-only cursor ✅.
6. Sample-exact audio claim is planner-run, not assumed: Python port of `IMA4.swift` vs afconvert on 99 + 10 files ✅;
   K2's `testAfconvertOracle` re-proves it in Swift ✅.
7. Hash pins could depend on a different hash definition ✅ — same FNV-1a 64 over Int16 LE as `SndPCMTests.fnv1a`.
8. Memory: one 17.3 M-sample track ≈ 35 MB Int16 — tests decode one at a time (invariant 15) ✅.
9. Test-count arithmetic re-added per task from the named tests (C1 4+6+6, C2 11+10+6, C3 10+8, C4 7, C5 4+12, C6 4,
   C7 5+5) ✅→FIXED: a first draft's C2 header and C7 reference-test count were estimates; both now come from named
   tests whose expected values the planner measured (reference counts by probe walk, 2026-10-06).
10. A task with no verify? C8 is conditional and has none of its own numbers ✅→FIXED: it inherits STOP-and-report and
    names its two tests.
11. Untested claim the plan relies on: "no WAVE/PCM AIFF ships anywhere" — checked Deimos (99 AIFC ima4) and Aki 1.1.0
    (10 AIFC ima4 + MP3); BTX sounds are `snd ` resources ✅. WAVE stays synthetic-only and labelled so.
12. Sibling sessions: the Ferazel wave-2 and other worktrees exist; this plan writes only `$WT`, `$HK` and (R4) a clean
    `pull --ff-only` ✅.
13. D-number collisions: D23 (Classics) and D10 (HectorKit) are "next free at commit time" ✅.
14. Spec item with no task: "Local files" — the committed Local holds one film; C1 indexes it, C2 parses it, C7 lists it ✅.
    Local `pref` (no file ships) — nothing to census ✅.
