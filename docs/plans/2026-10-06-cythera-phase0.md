# Plan — Cythera 1.0.4 Phase 0: data in git, decoders, census — 2026-10-06

> Status: **WRITTEN by Fable planner 2026-10-06 (Ben: no separate review); ready to execute.**
> Implements `docs/plans/2026-10-06-cythera-design.md` §9 row **0** only (design §4 data list, §5 layer rules, §7 music,
> §8.8 fonts, §12 hazards). Shape: `docs/plans/2026-10-06-deimos-phase0-data.md` (+ its "As built") and
> `docs/plans/2026-10-06-ferazel-phase1.md`. **Contracts, not code** (Ben, 2026-10-03): exact files, numbered behaviour
> statements each cited to the bank (`file.md §N` + label) or to a planner probe (`pNN`), public signatures only where
> they pin a seam, one line per test with the number it checks and where it came from, verify command, commit message.
> **Every number below was measured on this machine on 2026-10-06** (probes in `$SCRATCH/probes/pNN_*.py` + `.out`,
> listed in "Research notes") unless it cites the bank. Where a probe disagrees with the bank, the probe wins and the
> fact is listed under "Bank corrections to append". No review follows: an executor who finds a number wrong STOPS and
> reports (Invariant 10) — never edits the expectation.

**Goal.** The installed Cythera 1.0.4 folder's game data is in git byte-identical to the archive; `Cythera/Core` exists
with `CytheraCore` (Foundation + HectorResources) and `CytheraRender` (+ HectorGraphics/HectorAudio); every one of the
1,558 segments of `Cythera Data` is classified and decoded to typed values or indexed pixels (one stray segment has no
reader and is listed as such); the three resource files are read and 198 resources decode to typed records; the 46
`'asnd'` + 13 `snd ` become PCM; the 11 QTMA tunes decode to events end-to-end (closes INDEX NOT RESOLVED 9's
sub-point); a Swift script decoder reproduces `scriptdis.py`'s canonical instruction stream for all 958 script-band
segments; `cythera-census` prints `docs/cythera/data-census.md` ending `Totals: … failures 0`. **No Ben gate** (design
§9): the only thing to look at is the optional `--render` PNGs (the seat's addition, Task C11).

**Scope fence.** Nothing from Phase 1 on: no window model, no VM execution, no mixer, no synth, no app target, no
`project.yml` change. The decoders stop at typed values / indexed buffers / PCM / event lists.

**Architecture (design §5).** `HectorKit` gains one additive extension of an existing decoder (K1: `PICT.decodePixels`
accepts the two region opcodes and 16-bit DirectBits). `Cythera/Core` = SwiftPM package, libraries `CytheraCore`,
`CytheraRender`, executable `cythera-census` (thin `main`), test targets `CytheraCoreTests`, `CytheraRenderTests`,
`CytheraCensusTests`. Kit decisions (brief item 2), one line each:
- `clut` → **CytheraCore** (`ColorTableRecord`, 8 + 256×8 bytes): Ferazel C3 put `ColorLUT` game-side; the kit's
  `ColorTable` is PICT-internal. Promote when a third game parses `clut` resources.
- `NFNT`/`FOND`/`sfnt` → **CytheraRender** `BitmapFont` (NFNT strike = pixels) / **CytheraCore** `FontFamily` (FOND
  association table) / sfnt table directory only: one game ships them (BTX bakes glyphs, Aki uses TTF) — kit two-game rule.
- `Lite`, `FILT`, `nrct`, `Pref`, `TxSt` → **CytheraCore** records: Delver-engine private layouts (open-items §10, data-format §3.4/§8).
- `DLOG`/`DITL`/`WIND`/`CNTL`/`ALRT`/`MENU`/`MBAR` → **CytheraCore** records (`DialogTemplate`, `DialogItemList`, …):
  CytheraCore may not import HectorGraphics (design §5), and `HectorGraphics.Ditl` returns `CGRect`s for an AppKit
  shell; the census cross-checks item counts against `Ditl.decode` as an oracle (test-only).
- `snd ` → **HectorAudio** `SndSound` (exists; format 1, one `bufferCmd`, 8-bit — p07); the `'asnd'` form and the
  snd→asnd conversion rule → **CytheraRender** `SoundSegment` (open-items-2026-10-03 §9, HIGH).
- Segment file, XOR, LZ, maps/props/globals/CharEntry, the script decoder → **CytheraCore**; tiles/portraits/sky/pix/
  macro icons/compo tiles/PICT-as-indices/QTMA → **CytheraRender** (design §5).

**Tech.** Swift 6.x / Xcode 27, SwiftPM tools 6.0, XCTest, macOS 15 (`Deimos/Core/Package.swift` shape). Python 3 only
as the planner's probe and as the one-off generator of the committed parity hash list (C9) — never a build or test dependency.

**Paths:**
```
WT      = /Users/andiyar/Developer/Ambrosia-Classics/.claude/worktrees/nifty-cannon-afbf26   (branch claude/nifty-cannon-afbf26)
HK      = /Users/andiyar/Developer/HectorKit        (main d38a541 at plan time: K1-Ferazel merged, D12, zero-skip FLOOR 313)
HKWT    = /Users/andiyar/Developer/HectorKit-worktrees/cythera-k1   (branch cythera-k1, Task K1 only; `git -C $HK worktree add`)
G       = "/Users/andiyar/Developer/Ambrosia/Resources/ambrosia-extracted/RPG/Cythera/Cythera (installed)/files"
SCRATCH = the executing session's scratchpad (logs, canon dumps, PNGs; never the repo)
TOOLS   = $WT/docs/cythera/tools   (seg.py, lz.py, rsrc.py, scriptdis.py — the planner's oracles; the Swift code never shells out to them)
```
The worktree reaches HectorKit through `.claude/worktrees/HectorKit → ~/Developer/HectorKit` (exists; DECISIONS D1);
`Package.swift` uses `Context.environment["HECTORKIT_PATH"] ?? "../../../HectorKit"` (Deimos precedent).

---

## Verification model (read first)

| # | gate | command | expected |
|---|---|---|---|
| G1 | HectorKit zero-skip (K1) | `HECTORKIT_TEST_LOG="$SCRATCH/hk.log" "$HKWT/tools/check-zero-skip.sh" 2>&1 \| tail -n 1` | `PASS: zero skips, zero failures, executed 319 == floor 319` (313 + K1's 6; floor-delta rule, Invariant 9) |
| G2 | `Cythera/Core` suite | `cd "$WT/Cythera/Core" && swift test > "$SCRATCH/cy.log" 2>&1; grep -cE "^Test Case '.*' (passed\|failed\|skipped) \(" "$SCRATCH/cy.log"; grep -cE "^Test Case '.*' (failed\|skipped) \(" "$SCRATCH/cy.log"` | the task's ladder total, then `0` |
| G3 | census = committed doc (C11 on) | `cd "$WT/Cythera/Core" && swift build -c release --product cythera-census > /dev/null && "$(swift build -c release --show-bin-path)/cythera-census" "$WT/Resources/Cythera" > "$SCRATCH/census.md"; echo $?; tail -n 1 "$SCRATCH/census.md"` + `testStdoutEqualsCommittedCensus` green | `0`, then `Totals: segments 1,558 (decoded 1,557 · no reader 1) · resources decoded 198 · files 14 · failures 0` |
| G4 | data = archive (C0 on) | `cd "$WT/Resources/Cythera" && for f in *; do cmp "$f" "$G/$f" \|\| echo "DIFF $f"; done; ls \| wc -l` | no output before the count; `20` |
| G5 | apps untouched | `cd "$WT" && xcodegen generate && for s in Aki BubbleTroubleX; do xcodebuild -scheme "$s" build 2>&1 \| tail -n 1; done` | `** BUILD SUCCEEDED **` ×2 (Phase 0 adds no app target) |
| G6 | scope fence | `git -C "$WT" diff --name-only <task base>..HEAD` | ⊆ the task's **Files** list (+ `docs/DECISIONS.md` where the task says so) |
| G7 | layering | `grep -rnE "^import (AppKit\|UIKit\|SwiftUI\|CoreGraphics\|CoreText\|ImageIO\|AVFoundation\|QuartzCore\|AudioToolbox)" "$WT/Cythera/Core/Sources" \| grep -v "Sources/cythera-census/"`; `grep -rnE "^import (HectorGraphics\|HectorAudio)" "$WT/Cythera/Core/Sources/CytheraCore"` | both empty (`Sources/cythera-census` may import ImageIO behind `#if canImport(ImageIO)` for `--render`, Deimos precedent) |
| G8 | kit game-agnostic (K1) | `grep -rniE "cythera\|delver\|ambrosia" "$HKWT/Sources" --include=*.swift \| grep -v HectorTestSupport` | empty |
| G9 | clean tree per commit | `git -C "$WT" status --porcelain \| grep -v '^??'` | empty after every commit |

**Test ladder (`Cythera/Core`, cumulative, canonical merge order; STOP if different):**
C1 **5** → C2 **14** → C3 **20** → C4 **34** → C5 **44** → C6 **50** → C7 **58** → C8 **64** → C9 **70** → C10 **79** → C11 **84**.
If lanes merge in another order the expected total is the previous total + the merged task's N. HectorKit: 313 → K1 **319**.

**Honesty gate (Ben only):** none in Phase 0 (design §9). Completion is phrased "machine gates green; decodes to the
census" — never "looks right" or "sounds right".

**What the machine does NOT prove:** which `clut 256` the original's resource chain returned (two differ in 4 entries,
Research note 12 — MED, carried to Phase 1's gate card); how the 16-bit paper doll (PICT 129) and the 32-bit start-screen
frames (133–138) were colour-searched into the 8-bit screen (LOW, Phase 1/4); what the Tune Player did at the 168
interior end markers (value 1) that precede `TuneDifference` events (NOT RESOLVED → Phase 2, by Apple's docs or by ear);
the NFNT/sfnt rasterisation the Font Manager produced for the requested sizes (Phase 1); that any sound *sounds* right.

---

## Non-negotiable invariants

1. **Layering (HectorKit D6, Classics D12, design §5).** `CytheraCore` imports Foundation + HectorResources only — no
   pixels, no PCM. `CytheraRender` adds CytheraCore, HectorGraphics, HectorAudio. Only `Sources/cythera-census` may
   import ImageIO (behind `#if canImport(ImageIO)`); `CytheraCensus` itself lives in CytheraRender and hands the
   executable indexed buffers + palette. Windows traps (D18/W0.5): no `String.Encoding.macOSRoman` — use
   `HectorResources.MacRoman.decode`; resolve symlinks before enumerating; no `FileManager` tricks on paths with spaces.
2. **Kit stays game-agnostic.** No type, symbol or doc comment under `$HKWT/Sources` (outside `HectorTestSupport`) says
   "Cythera", "Delver" or "Ambrosia" (G8). The locator and census tests name the game.
3. **Decode as the original reads, not as the format's ideal.** Pix rows padded to 4 bytes (note 6), the LZ terminator op
   (data-format §2), 0x0101/0x0210 never decrypted (script-census §2), the `asnd` zero tail kept (open-items §9), the
   stale `FOND 128` association left as stored — each with a doc comment citing the bank section or the research note.
4. **Refuse what the census has not shown** (HectorKit D2/D5 style): any shape outside the measured corpus throws a
   named error with a synthetic test — a PICT opcode outside the 21 + 5 shapes, a QTMA word with an undefined type nibble
   (8, 0xC, 0xD, 0xE), an `asnd` whose length ≠ blocks·0x800 + 0x40C, a map whose length ≠ 0x20 + C·0x80 + W·H·2.
5. **Hostile-input posture.** Every read bounds-checked; malformed input throws, never traps, never allocates from an
   unchecked size (`count × stride ≤ data.count` before allocating). Every decoder gets a "every prefix throws" test.
6. **Data enters git once, verified.** C0 copies exactly 20 files with `cp -p`, checks SHA-256 against Research note 1,
   commits with explicit paths. Never the PEF `Cythera`, `Register Cythera`, InputSprocket files, `*.ai.rsrc`,
   `Icon_*`, `Cythera Documentation` (0-byte data fork), FAQ/web-link files, `*.text.rsrc`, `Land King Hall screenshot.pict.rsrc`.
7. **Commits.** Explicit paths only — never `git add -A` / `git add .`; never `git stash`. Trailer on every commit, both
   repos, nothing else: `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`. G9 after each commit.
8. **Repos and branches.** K1 works only in `$HKWT` (branch `cythera-k1`), rebases onto `origin/main` immediately before
   the fast-forward push (`git fetch origin && git rebase origin/main && <G1> && git push origin HEAD:main`), then a clean
   `git -C ~/Developer/HectorKit pull --ff-only`. Never build or write in `~/Developer/HectorKit` itself. Classics commits
   stay on `claude/nifty-cannon-afbf26` in `$WT`; the orchestrator merges. Never touch sibling worktrees.
9. **Floor-delta rule.** Other sessions land HectorKit tests concurrently: K1's acceptance is "executed = executed on the
   rebased base + 6"; set `FLOOR` to the printed total. Never add numbers from two branches by hand.
10. **STOP on any unexpected number** (counts, hashes, offsets, test totals, census lines). Report the command output;
    never edit an expectation or the code to make them agree. The bank's three dumps are not in this worktree (`ghidra/`
    holds only scripts); regenerate per `docs/cythera/tools/README.md` before citing a line number (design §12).
11. ⚠️ **LANDMINES.** (a) `swift test` has no package-wide total: count `^Test Case` lines (G2). (b) `swift run` mixes
    build output into stdout: run the built binary (G3). (c) SwiftPM rejects a declared target with no sources:
    `Package.swift` grows task by task — C1 declares CytheraCore + CytheraCoreTests only, C5 adds CytheraRender +
    CytheraRenderTests, C11 adds the executable + CytheraCensusTests. (d) File names with spaces and no extension
    (`Cythera Data`, `AI Scripting Document`): quote every path; `.gitattributes` marks the folder binary. (e) D-numbers
    collide across sessions: the design's rulings are **D28** (D27 is the last on `main` at plan time); confirm at commit
    time, renumber every reference in the same commit if taken. (f) Two different `clut 256` resources exist (app and
    data file): every palette consumer names which one it used. (g) `0x8EFF` is in the tile-sheet page but is NOT a tile
    sheet: `LoadTiles` reads only `0x8E00..0x8E9F` (data-format §3.4) — decoding it as LZ throws (note 5).

---

## Shared architecture (LOCKED — every task codes against these names)

### S1. Package `Cythera/Core`
`Package.swift` (tools 6.0, `platforms: [.macOS(.v15)]`, header comment naming this plan and D28), dependency
`.package(path: Context.environment["HECTORKIT_PATH"] ?? "../../../HectorKit")`. Products: library `CytheraCore`,
library `CytheraRender`, executable `cythera-census`. Targets: `CytheraCore` (HectorResources), `CytheraRender`
(CytheraCore, HectorResources, HectorGraphics, HectorAudio), `cythera-census` (CytheraRender + the kit products it
needs), tests `CytheraCoreTests` (CytheraCore, HectorResources), `CytheraRenderTests` (CytheraRender + kit incl.
HectorGraphics for the `Ditl` oracle), `CytheraCensusTests` (`cythera-census`, CytheraRender). Added per Landmine (c).

### S2. CytheraCore public surface (★ = LOCKED after Phase 0; later phases add, never rename)
- ★ `CytheraData` — `static let environmentVariable = "CYTHERA_DATA"`; `static func dataDirectory() throws -> URL`
  (env else walk up from `#filePath` to `Resources/Cythera`, symlinks resolved — `DeimosData` shape, D24.3);
  `CytheraDataError.notFound(String)`.
- ★ `CytheraResources` — `init(directory: URL) throws`; `app`, `data`, `documentation: ResourceCollection` (via
  `ResourceReader.read(fileAt:)` on `Cythera.rsrc`, `Cythera Data.rsrc`, `Cythera Documentation.rsrc`);
  `func resource(type: String, id: Int16) -> Resource?` — **data file first, then app** (the original opened the
  scenario file after the application, so `GetResource` searched it first; app-shell.md §1.3, HIGH chain / MED for
  which `clut 256` wins, note 12); `segmentFileURL: URL` (`Cythera Data`).
- ★ `SegmentFile` — `init(contentsOf: URL) throws` (mapped); `header: SegmentFileHeader` (title, formatVersion 0x1300,
  scenarioVersion 0x0200, maxMapDimension 0x0200, rawHeader 0x80 B; data-format §1.1); `pages: [UInt8: TOCPage]`;
  `func entry(_ id: UInt16) -> (offset: Int, length: Int)?` (nil when length 0 — "absent = length 0", §1.1);
  `func segment(_ id: UInt16) -> Data?` (slice); `func scriptSegment(_ id: UInt16) -> Data?` (decrypted unless
  `SegmentFile.storedPlaintext.contains(id)` = {0x0101, 0x0210}); `static func isSegmentFile(_ data: Data) -> Bool`
  (u32@0x80 == 0x80, §1.1); `var ids: [UInt16]` sorted.
- ★ `SegmentCipher` — `static func apply(_ bytes: inout [UInt8], id: UInt16, skip: Int = 0)` (the id-keyed LCG XOR of
  data-format §1.3, self-inverse; `skip` = the `offset` loop).
- ★ `SegmentOverlay` — the `TCachedSegFiles` model (data-format §1.4): up to 16 `SegmentStore`s (protocol: `entry`,
  `segment`), `push(_:)`, `segment(_ id:)` from the topmost store that has it, `write(_ id:data:)` to slot 0 (a
  mutable in-memory store in Phase 0; the real save file is Phase 4's). No file writing in Phase 0.
- ★ `LZ` — `static func decode(_ src: Data) throws -> (bytes: [UInt8], consumed: Int)` (data-format §2, 7 op forms);
  `LZError.{truncated, matchBeforeStart}`.
- ★ World: `LevelMap` (`header: MapHeader` fields of data-format §3.1, `chunks: [[UInt16]]` (C × 64), `cells:
  [UInt16]` row-major, `cell(x:y:)`), `MapCell` decode helpers (tile 12 bits, compo 0x1000, transposed 0x2000, seen
  0x8000 — §3.2), `PropRecord` (16 B, every field accessor of §4.2 incl. `kind`, `x`, `y`, `parent`, `type`, `frame`,
  `mirror`, `byte6`, `byte7`, `uniqueIndex`, `scriptSlot`, `heapRef`, `spriteOffset6`), `PropSegment` (records),
  `WorldGlobals` (`init(file: SegmentFile) throws` loading 0xF000–0xF016 into typed members: `baseTiles [UInt16]`
  ×1024, `animations [AnimationRecord]`, `tileFlags [UInt32]` ×8192, `tileNames TileNameTable`, `creatures
  [CreatureRecord]` ×128, `characters [CharEntry]` ×512 (0x4000 at runtime, §6.1), `schedules ScheduleTable`,
  `teleports [UInt32]` ×1024, `wallSubstitutions [WallRecord]`, `arrivalTransitions [UInt8]` ×1024, `tilePseudoProps
  [UInt16]` ×8192, `spriteOffsetsX/Y [Int16]` ×16384, `compoTiles [CompoTileRecord]` ×4096, `filterIDs [UInt8]`
  ×8192, `paletteCycles [PaletteCycleRange]` (0xF005), `f007 Data`, `f00A Data`, `frameVariableNames/objectNames
  [(UInt16, String)]` (0xF014/0xF015)), `CharEntry` (every field of §6.1 by name), `ScheduleEntry` (§6.3).
- ★ Art records (data, no pixels): `ColorTableRecord` (`clut`: seed, flags, 256 `(value, r16, g16, b16)`; `rgb8(index)`
  = high bytes), `PaletteResource` (`pltt`: count, 16-byte entries — counted and parsed, no reader found in the bank), `LightMask` (`Lite`: `size`, `intensities [UInt8]` size×size — engine-classes §3.3), `DisplacementFilter`
  (`FILT`: `holdCount`, `counter`, `colorMask 256 bits`, `frames [[Int8]]` of 1024 — data-format §3.4).
- ★ UI records: `DialogTemplate` (DLOG 20-byte record + title), `DialogItemList` (DITL items: rect, type byte, text/
  handle bytes), `WindowTemplate` (WIND), `ControlTemplate` (CNTL), `AlertTemplate` (ALRT), `MenuResource` (MENU: id,
  width, height, procID, enableFlags, title, items (name, icon, key, mark, style)), `MenuBar` (MBAR ids), `StringList`
  (STR#), `PascalString` (STR), `TextStyle` (TxSt: size, style byte, font name — per TMPL 128), `FontFamily` (FOND:
  flags, familyID, firstChar, lastChar, associations (size, style, fontID)), `StartRects` (nrct 128: 8 rects),
  `PrefDefault` (Pref: name, u32).
- ★ Script: `ScriptInstruction` (`offset`, `length`, `mnemonic: String`, `flag: .reached/.jumpTarget/.dead`),
  `ScriptSegmentListing` (`id`, `kind: ScriptSegmentKind` (.class, .routine, .strtab, .dict, .array, .data, .ai),
  `length`, `instructions`), `ScriptDecoder` (`static func listing(_ id: UInt16, in: SegmentFile) throws ->
  ScriptSegmentListing`), `ScriptCanonical` (`static func text(_ listing:) -> String` — the parity form of C9).

### S3. CytheraRender public surface
- `IndexedImage` (`width`, `height`, `rowBytes`, `pixels [UInt8]` one byte per pixel, frame-sized), `Palette` (from
  `ColorTableRecord`; `func rgba(_ image: IndexedImage) -> [UInt32]` 0xAARRGGBB, index 0 opaque here — transparency is
  a blitter rule of Phase 1, engine-classes §5), `TileStore` (`init(file:) throws`: 0xA00 tiles × 1024 B from sheets
  0x8E00..0x8E9F, absent sheet → zero tiles; `tile(_ n: Int) -> ArraySlice<UInt8>`; `compoTile(_ record:) ->
  [UInt8]` per `BuildCompoTile`, data-format §3.4), `Portrait` (0x87FF + p, 64×64), `SkyStrip` (0x8400 + n, 288×32),
  `PixImage` (0x8F00 + n: u16 w, u16 h, LZ; rowBytes (w+3)&~3 — note 6), `MacroIcon` (0x8A00 + n, 32×16 raw),
  `StoredPicture` (a PICT through `PICT.decodePixels`: `.indexed(IndexedImage, ColorTable?)` / `.direct16([UInt16])`
  / `.direct32([UInt8])`), `BitmapFont` (NFNT: header fields, `locTable`, `owTable`, `glyph(_ c: UInt8) ->
  (bits: [UInt8], width: Int, offset: Int)?`), `SoundSegment` (`'asnd'` → `blocks`, `sampleRate`, `samples [Int16]`
  as stored, `trimmedCount`; `func pcm() -> SndPCM`; `static func from(snd: SndSound) -> SoundSegment` = the converter
  rule), `TuneSequence` (QTMA: `description` fields, `headerEvents [TuneEvent]`, `events [TuneEvent]`, `parts
  [NoteRequestPart]`), `TuneEvent` (enum: `.rest(duration)`, `.note(part, pitch, velocity, duration)`,
  `.extendedNote(part, pitch16, velocity, duration)`, `.control(part, controller, value)`, `.extendedControl(part,
  controller, value)`, `.knob(part, knob, value)`, `.marker(subtype, value)`, `.general(part, subtype, payload
  [UInt32])`), `CytheraCensus` (`static func render(dataDirectory: URL) -> (stdout: String, failures: Int)`,
  `static func renderImages(dataDirectory: URL) -> [(name: String, image: IndexedImage, palette: Palette)]`).

### S4. Runtime data
`Resources/Cythera/` (C0) = the 20 committed files under their original names (Research note 1). Tests read it through
`CytheraData.dataDirectory()`; `CYTHERA_DATA` overrides; a missing file is a FAILURE naming the path, never a skip.

### S5. The census document
`docs/cythera/data-census.md` = header (generated date, HectorKit sha, Classics sha, the two re-run commands of G3,
the "Spec-vs-data deltas" list = Bank corrections 1–13 in two lines each), a rule `---`, then `cythera-census` stdout
verbatim (golden test). Numbers in the doc come only from the tool.

---

## Tasks

Legend: ⚑ MAJOR = two review legs (spec compliance, then quality; Fable reviewers, report everything with confidence);
minor = one leg doing both. "(→ N)" = cumulative `Test Case`s in `Cythera/Core`. Every task: G6, G7, G9, plus the gates
named. Test names are verbatim; each line says what number it checks and where the number came from.

### K1 — ⚑ MAJOR — HectorKit: `PICT.decodePixels` accepts 0x0099 PackBitsRgn, 0x009B DirectBitsRgn, 16-bit DirectBits (+6, kit)
- **Files ($HKWT):** `Sources/HectorGraphics/PICT+Pixels.swift` (additive); new
  `Sources/HectorTestSupport/HectorData+Cythera.swift`; new `Tests/HectorGraphicsTests/PICTPixelsRegionTests.swift`,
  `Tests/HectorGraphicsTests/CytheraPICTCensusTests.swift`; `tools/check-zero-skip.sh` (export + echo
  `HECTORKIT_DATA_CYTHERA`, default `$G`; FLOOR); `docs/DECISIONS.md` (next free HectorKit D-number, expected **D13**);
  `docs/STATE.md` (one line).
- **Why kit, why now:** `PICT` is already the kit's format and `decodeMasked` already parses the 0x0099 region
  (`PICT+Masks.swift`); D11 added 0x009B for Deimos alone — opcode coverage of an existing decoder, not a new decoder,
  so the two-game rule does not bite. 0x009B now has two games' data (Deimos 9 app PICTs, Cythera 7).
- **Contract (additive; `PICT.init`, `decodeAny`, `decodeMasked` unchanged):**
  1. `decodePixels` accepts 0x0099 (PackBitsRgn) exactly as 0x0098 plus the region after the mode word, and 0x009B
     (DirectBitsRgn) as 0x009A plus the region; the region is parsed with the existing region reader and returned —
     `IndexedPICT.maskRegion` / `DirectPICT.maskRegion` (nil for the Rect opcodes), typed as the existing
     `QuickDrawRegion` if it is public, else a thin public value type with `bounds` and `contains(x:y:)` (seat's choice
     of name). Pixels are returned as stored (unclipped); the consumer clips (D11's "region is a clip" semantics).
  2. 16-bit DirectBits (pixelSize 16, cmpCount 3, cmpSize 5): packType 3 (RLE on 16-bit words) and packType 1 /
     rowBytes < 8 (unpacked) decode to `DirectPICT.depth == 16` with `pixels16: [UInt16]` as stored (A1R5G5B5 words,
     bit 15 kept); 32-bit keeps `depth == 32` and `rgb`. `DirectPICT` gains `depth` and `pixels16` (empty for 32-bit).
  3. Refusals keep their names (`unsupportedPixels("bitsOpcode")` now only for 0x0090/0x0091; `"directPack"` for a
     16-bit packType ≠ 1/3 or a 32-bit packType ≠ 4; `"cmpCount"`; `"directMode"` stays for 32-bit mode ≠ 64 —
     **16-bit pictures in the corpus carry mode 0x40 too (PICT 129, Catamarca): accept mode 64 for 16-bit** (p14).
  4. Device-relative indexed tables (ctFlags 0x8000) keep the existing by-position rule (PICT 131/512/513 and three
     screenshots carry it, p14).
- **Tests — `PICTPixelsRegionTests` (synthetic, 4):** `testPackBitsRgnReturnsIndicesAndRegion` (0x0099, 8-bit, ctFlags
  0x8000, a 2-rect region → indices by position + region bounds) · `testDirectBitsRgn32ReturnsRGBAndRegion` (0x009B
  packType 4) · `testDirectBits16PackType3And1` (0x009A packType 3 and a rowBytes < 8 unpacked case; words as stored)
  · `testRegionAndTruncatedHostileInputThrowsNeverTraps` (every prefix of the three pictures throws).
- **Tests — `CytheraPICTCensusTests` (`HECTORKIT_DATA_CYTHERA`, 2):** `testTwentyOnePICTsDecodeByOpcode` — app
  `Cythera.rsrc` PICT 0 (259×342) and 900 (99×151) 0x0098 8-bit; data `Cythera Data.rsrc` 0x0098: 130 (800×600, 256
  entries), 132 (640×480, 224), 139–145 (151×31, 224); 0x0099 ctFlags 0x8000 256 entries: 131 (300×250), 512, 513
  (544×272); 0x009B 16-bit packType 3 mode 64: 129 (80×130); 0x009B 32-bit packType 4 mode 64: 133–138 (88×155);
  **21/21 decode, 0 throws** (p14) · `testScreenshotFilesDecode` — the five `* screenshot.pict` files (512-byte header
  skipped): Odemia, Pnyx, Unicorn 0x0098 8-bit 640×480 ctFlags 0x8000; Catamarca 0x009A 16-bit packType 3 640×480;
  Land King Hall is 0x8200 QuickTime → `decodePixels` throws a `DecodeError` (named in the test log; codec not pinned) (p14).
- **Gate:** G1 = **319** (or rebased base + 6), G8. **Commit:** `HectorGraphics: PICT.decodePixels — 0x0099/0x009B regions returned as maskRegion, 16-bit DirectBits as stored; HECTORKIT_DATA_CYTHERA census (21 PICT + 5 files); floor <n>`.
  Rebase, re-gate, `git push origin HEAD:main`, clean `pull --ff-only` in `~/Developer/HectorKit`.
- **Fallback if K1 is not on `$HK` main when C5 runs:** C5's `StoredPicture` decodes the 11 0x0098 pictures through
  `decodePixels` and records the other 10 as `.refused(reason)`; the census line reads `PICT 21 (indexed 11 · refused
  10)` and the Totals line counts them under `failures` — i.e. **C5 cannot close with failures 0 without K1**; the
  orchestrator sequences K1 first (Execution order, wave A).

### C0 — minor — Data into git + D28
- **Files:** `Resources/Cythera/{Cythera Data, Cythera Data.rsrc, Cythera.rsrc, AI Scripting Document, Cythera Documentation.rsrc, Attack Nearest.ai, Attack Strongest.ai, Attack Weakest.ai, Beserk.ai, Defend.ai, Dummy.ai, Healer.ai, Missile User.ai, Catamarca screenshot.pict, Land King Hall screenshot.pict, Odemia screenshot.pict, Pnyx screenshot.pict, Unicorn screenshot.pict, Cythera 1.0.4 Notes.text, Cythera License.text}` (20, `cp -p` from `$G`); `.gitignore`; `.gitattributes`; `docs/DECISIONS.md`.
- **Contract:** `.gitignore` already reads `/Resources/*` + `!/Resources/Deimos/` (D24): add `!/Resources/Cythera/`
  after it. `.gitattributes`: add `Resources/Cythera/** binary`. `git status --porcelain --ignored Resources` shows
  `Resources/Aki/` still ignored and exactly 20 new files under `Resources/Cythera/`. SHA-256 and sizes = Research
  note 1 (total 11,570,723 B; largest 5,608,688 — no GitHub warning). All 20 names are ASCII (the only non-ASCII names in
  the folder, `Ambrosia’s Web Site (IE/NS)`, are not committed; p01). DECISIONS **D28** "Cythera build: Ben's nine
  brainstorm rulings + the seat's design rulings" = design §11 items 1–9 verbatim, the seat's rulings (three layers §5,
  thread model §5.1, data in git by the D24 shape, deviations §8, phase scoping §9, open-item treatments §10), the
  committed tree with sizes + SHA-256, `CYTHERA_DATA`, the kit decisions of this plan's Architecture paragraph;
  rejected: LFS, symlinked data (D24 reasons), committing the PEF/InputSprocket/`*.ai.rsrc`.
- **Gate:** G4 (`20`, no DIFF); G5; G9. **Commit:** `Resources/Cythera: original Cythera 1.0.4 data (20 files, 11,570,723 B) in git; .gitignore/.gitattributes; DECISIONS D28`.

### C1 — minor — `Cythera/Core` skeleton, data locator, three resource files (→ 5)
- **Files:** `Cythera/Core/Package.swift` (CytheraCore + CytheraCoreTests only); `Sources/CytheraCore/Data/{CytheraData,CytheraResources}.swift`;
  `Tests/CytheraCoreTests/CytheraDataTests.swift`.
- **Contract:** S2 rows `CytheraData`, `CytheraResources`. Resource files are data-fork resource maps (INDEX "Resource
  census"); `ResourceReader.read(fileAt:)` reads them.
- **Tests (5):** `testDataDirectoryResolvesCommittedFolder` · `testOverrideAndMissingFileNamed` (temp dir lacking
  `Cythera Data.rsrc` → `notFound` names it) · `testThreeResourceFilesCounts` — app 339 resources / 52 types, data
  113 / 18, documentation 268 / 40 (p06 = INDEX census) · `testKeyResourceCounts` — app: PICT 2, clut 1, pltt 1, Lite 25,
  snd 13, DLOG 17, DITL 20, WIND 10, CNTL 8, ALRT 5, MENU 14, MBAR 2, CMNU 1, STR# 16, STR 3, TxSt 8, FOND 1, Pref 2,
  crsr 57; data: PICT 19, clut 1, FILT 7, FOND 2, NFNT 2, sfnt 1, STR# 5, TxSt 12, nrct 1, PORT 2, LINF 3, MSta 3,
  eBRS 25, eSTM 16, RMAP 1, DATA 10 (p06/p07) · `testLookupOrderDataThenApp` — `resource("clut", 256)` returns the data
  file's (SHA-256 prefix `e7fe2eef…`, not the app's `f3373625…`; p07, note 12); `resource("Lite", 140)` falls through to
  the app (65 B).
- **Gate:** G2 = **5/0**. **Commit:** `Cythera/Core: package, CytheraData locator, three resource files, data-then-app lookup; 5 tests`.

### C2 — minor — Segment file, TOC, id-keyed cipher, overlay model (→ 14)
- **Files:** `Sources/CytheraCore/Segments/{SegmentFile,SegmentFileHeader,SegmentCipher,SegmentOverlay}.swift`;
  `Tests/CytheraCoreTests/SegmentFileTests.swift`.
- **Contract:** data-format §1.1–§1.4 (HIGH): root page at 0x80 (256 × {u32 offset, u32 length}); root[n] = TOC page n
  for ids 0xnn00..0xnnFF; length 0 = absent; the header is opaque except the named fields (+0x00 Pascal title, +0x40
  i16 0x1300, +0x42 i16 0x0200, +0x48 i16 0x0200); cipher = `mult = (id & 0x3f)·4 + 1`, `inc = (id >> 6) & 0xff`,
  `seed = ((id & 0xffff) >> 8) ^ id`, u32 LCG, byte ^= low byte of the next state (§1.3); script pages 0x01–0x3F are
  the encrypted band **except 0x0101 and 0x0210, stored plaintext** (script-census §2, HIGH mechanical; design §12).
- **Tests (9):** `testIsSegmentFileAndHeaderFields` — u32@0x80 == 0x80; title "Cythera: Fate of Alaric"; +0x40 0x1300,
  +0x42 0x0200, +0x48 0x0200; +0x44/+0x46/+0x4A..0x7F zero (p03; data-format §1.1) · `testRootPageAndTOCPages` — root[0]
  = {0x80, 0x800}; 34 TOC pages, every page length 0x800; 1,558 segments; Σ lengths 5,524,330 of 5,608,688 B; no two
  bodies overlap; max end 0x5594F0 (p02, p03) · `testKnownSegmentEntries` — 0x8000 {0x78676, 0x820}, 0x8001 {0x78E96,
  0x20020}, 0x8002 {0x98EB6, 0x2820} (data-format §1.2 xxd; p03) · `testAbsentSegmentsAreNil` — 0xF003, 0xF006, 0xF00E,
  0x8100, 0x8125, 0x8E96, 0x9128 absent (p03) · `testBandCounts` — maps 42 (0x8000–0x8029) · props 40 (0x8101–0x8129
  minus 0x8125) · sky 18 · portraits 142 · macro 62 · tile sheets in 0x8E00–0x8E9F 159 + 0x8EFF · pix 59 (51 below
  0x8F80 + 8) · music 11 · asnd 46 · globals 20 · script band 958 · AI 0x0410–0x0436 14 (p02, p03) ·
  `testCipherKnownBytes` — decrypting 0x1802 yields `28 8E` at offset 0 (the dictionary offset the listing shows) and
  0x3000's first byte is 0x81 (frame op; script-census §1 "routine = starts with 0x81") (p05 listings) ·
  `testCipherIsInvolutionAndSkipContinuesTheLCG` (synthetic) · `testStoredPlaintextPolicy` — `scriptSegment(0x0101)`
  and `(0x0210)` return raw bytes; `scriptSegment(0x0201)` ≠ `segment(0x0201)` (script-census §2) ·
  `testOverlayTopmostWinsAndWritesGoToSlotZero` (synthetic stores; 16-slot cap; data-format §1.4).
- **Gate:** G2 = **14/0**. **Commit:** `Cythera/Core: SegmentFile (34 TOC pages, 1,558 segments), SegmentCipher, SegmentOverlay model; 9 tests`.

### C3 — minor — LZ codec (→ 20)
- **Files:** `Sources/CytheraCore/Codec/LZ.swift`; `Tests/CytheraCoreTests/LZTests.swift`.
- **Contract:** data-format §2 table, all seven op forms, terminator op `11111xxx`, no length header, consumed count
  returned (HIGH; `lz.py` is the oracle). Hostile: a match reaching before the output start → `matchBeforeStart`;
  running off the input → `truncated`.
- **Tests (6):** `testSevenOpFormsSynthetic` (one stream exercising each row of the table) · `testTileSheet0x8E00` —
  5,378 → 16,384 B, consumed 5,378, SHA-256 `9a5e259ec4ba72fbedf86ebbbfcd523f8f3272a01c726b70579db40f94645a7c` (p04;
  data-format §2) · `testPortraitAndSkyWorked` — 0x8800: 1,482 → 4,096, SHA `86ef37d410f374f743514f916b0878ac3172fad770f246156c4e811331b4cafc`;
  0x8400: 5,474 → 9,216, SHA `4216bfb5925461c1aa5ecbdc1d64fcef0ef5befc8b82162fd40e8538ac60442a` (p04; §2) ·
  `testEveryLZSegmentConsumesExactly` — 159 sheets → 0x4000 each, 142 portraits → 4,096, 18 sky → 9,216, 59 pix (after
  the 4-byte header) → ((w+3)&~3)·h; consumed == length in all 378; op census over them A 222,174 · B 301,737 · C
  29,065 · D 56 · E 1,024 · F 362 · end 378 (p04) · `testStray0x8EFFThrowsMatchBeforeStart` (4,694 B; p04, note 5) ·
  `testTruncatedAndHostileInputThrowsNeverTraps` (every prefix of 0x8800).
- **Gate:** G2 = **20/0**. **Commit:** `Cythera/Core: LZ codec (7 op forms, 378 shipped streams consume exactly); 6 tests`.

### C4 — ⚑ MAJOR — Level maps, props, world globals, CharEntry, schedules (→ 34)
- **Files:** `Sources/CytheraCore/World/{LevelMap,MapHeader,MapCell,PropRecord,PropSegment,WorldGlobals,AnimationRecord,TileNameTable,CreatureRecord,CharEntry,ScheduleTable,CompoTileRecord,WallRecord,PaletteCycleRange,SymbolTable}.swift`;
  `Tests/CytheraCoreTests/{LevelMapTests,PropTests,WorldGlobalsTests}.swift`.
- **Contract:** data-format §3.1 (header fields, exits as teleport indices, HIGH), §3.2 (cell bits), §3.3 (chunk records
  C × 0x80; the chunked path `hdr[6] < hdr[8]` is **parsed as the code does, `C·0x40`, and flagged** — never reached by
  shipped data, HIGH), §4.1–§4.3 (prop record + kind byte), §5 (every 0xF0xx row as a typed member; 0xF001 = records
  until a zero i16 then a 2-byte tail, note 7), §6.1 (CharEntry 0x20 B, 512 at runtime: 256 loaded + 256 zero), §6.3
  (schedules: 256 i16 counts then 8-byte entries). Length formula `0x20 + C·0x80 + W·H·2` enforced (Invariant 4).
- **Tests (14):** `testAllMapHeaders` — 42 maps; (W,H,C) per id as Research note 8; Σ C = 233; `+6 == +8` in all 42;
  `+4` and `+0x14..0x1F` zero; length formula holds for all (p11; data-format §3.1) · `testMap0x8002Worked` — W=H=64,
  C=16, wrap (4,8), exits 5,5,5,5, chunk 0 begins `01F6 01E4`, body at segment offset 0x820 (data-format §3.1 xxd) ·
  `testMap0x8026Exits` — N 0, E 0x8E, S 0, W 0x8F (§3.1 census) · `testMapCellCensus` — 206,976 cells; max tile index
  0x429; compo cells 19,650; no cell carries bit 13 or bit 15; wrap histogram {(8,8):22, (0,0):9, (4,8):4, (4,4):4,
  (0,4):1, (8,4):1, (2,8):1}; 23 maps have an exit (p11) · `testPropCensus` — 40 segments, every length a multiple of
  16, 14,485 records, kinds {0:12104, 1:116, 2:46, 8:618, 9:241, 10:7, 0x10:32, 0x11:55, 0x18:31, 0x1C:1, 0x42:879,
  0x44:298, 0x80:52, 0xFF:5} (data-format §4.3 census = p11); 'B' frame histogram {0:312, 1:30, 3:330, 4:8, 6:2, 7:3,
  8:170, 10:24}; +0xA..0xB zero in all; byte 0xF and byte 0xE bits 6–7 zero in all; max type 800 (p11; §4.2) ·
  `testProp0x8102Worked` — records 2–3: (kind 0, x 10, y 32, type 39, frame 3, byte6 1) and (kind 0x44, x 15, y 17, type
  1) (§4.5) · `testGlobalsPresentAndSizes` — 20 ids; sizes F000 2048 · F001 66 · F002 32768 · F004 5786 · F005 16 ·
  F007 167 · F008 2048 · F009 16384 · F00A 1024 · F00B 5448 · F00C 4096 · F00D 500 · F00F 1024 · F010 16384 · F011
  32768 · F012 32768 · F013 131072 · F014 123 · F015 179 · F016 8192 (p03) · `testBaseTilesAndAnimations` — 1,024 base
  tiles, 395 non-zero, max 4,863; 8 animation records then the zero terminator at 64 and 2 tail bytes; records
  (987,987,4,2) (2161,2161,4,1) (1275,1274,2,4) (1180,1180,4,1) (1176,1176,4,1) (1172,1172,4,1) (1168,1168,4,1)
  (902,902,4,1) (p11; §3.4 xxd shows the first two) · `testTileFlagsAndLightBits` — 8,192 u32, 2,125 non-zero; light
  size bits 0–1 {1:42, 2:5, 3:12}; flicker 0x10000 set on 45 (p11; open-items §10) · `testTileNames` — 547 names;
  last (5247, "earthen wall"); terminator 0x7FFF at byte 5,778; 6 unread bytes follow (p11; §5 "547 names") ·
  `testCreaturesAndCharacters` — F008: 128 records, 50 used (first zero at 50), byte 7 = 0 in all 50, 0 tail records
  (§5, combat.md §4); F009: 512 entries, 131 non-empty, 128 alive, 1 party member, alignment {0:128, 1:2, 2:1}, +0x1E
  {0:11, 2:1, 3:7, 4:7, 5:1, 6:5, 7:8, 8:91}, +0x12/+0x18/+0x1A/+0x1B/+0x1C/+0x1F zero in all 131; char 2 =
  `03013015 2422 0001 00 14 14 14 2580 90 90 24 24 00 08 2422 96 00 00 00 00 00 00 0F 06 00` (§6.1 worked decode) ·
  `testSchedules` — 617 entries, 0x200 + 8·617 == 5,448, 114 characters have entries; char 0: one entry hour 9 →
  (1,0,0); char 2 first entry hour 0, activity 0x96, cond 3, arg 0, location (3,19,21); condition-op histogram top
  {0:539, 1:28, 131:11, 132:8} (p11; §6.3) · `testTeleportsAndSmallGlobals` — 190 non-zero teleports, levels 1–41,
  tp[5] = (1,199,58); 50 wall records starting tiles 144,145,146; arrival bytes {0:981, 14:30, 2:6, 13:3, 1:2, 3:1,
  4:1}; 114 non-zero pseudo-prop tiles; F011/F012 39 non-zero each, max 5,140; 264 non-zero compo records of 4,096;
  124 filter ids {128:72, 131:30, 134:12, 129:4, 130:3, 133:3}; F014 10 / F015 13 symbol entries consuming the whole
  segment; F00A all zero; F005 = five (first, count, 1) ranges D0/8, D8/8, E0/4, E4/4, E8/4 + zero; F007 u16 count 33 +
  33 × 5 B (p11; §5, open-items-2026-10-06 §5) · `testTruncatedMapAndPropThrowNeverTrap` (prefixes; a map whose
  length breaks the formula → named error).
- **Gate:** G2 = **34/0**. **Commit:** `Cythera/Core: LevelMap/PropRecord/WorldGlobals/CharEntry/ScheduleTable — 42 maps, 14,485 props, 20 globals typed; 14 tests`.

### C5 — ⚑ MAJOR — CytheraRender: tile store, portraits, sky, pix, macro icons, palette, compo tiles, Lite/FILT, PICTs as stored (→ 44) — needs K1 on `$HK` main, C3
- **Files:** `Package.swift` (add `CytheraRender`, `CytheraRenderTests`); `Sources/CytheraCore/Art/{ColorTableRecord,PaletteResource,LightMask,DisplacementFilter}.swift`;
  `Sources/CytheraRender/Pixels/{IndexedImage,Palette,TileStore,Portrait,SkyStrip,PixImage,MacroIcon,StoredPicture}.swift`;
  `Tests/CytheraRenderTests/{TileStoreTests,PixelSegmentTests,PaletteAndMasksTests,StoredPictureTests}.swift`.
- **Contract:** data-format §1.5 rows 0x8400/0x8800/0x8A00/0x8E00/0x8F00/0x8F80 and §3.4 (tiles 0xA00 × 32×32, sheets
  0x8E00..0x8E9F only — `0x9f < sVar6` break — an absent sheet gives zero tiles; `BuildCompoTile` quadrant rule;
  HIGH); pix header {u16 w, u16 h} then LZ, **rows padded to a multiple of 4 bytes** (note 6, corrects §1.5); palette =
  `clut 256` (ctSize 255, values 0..255 ascending, 16-bit channels, high byte = 8-bit colour) — data file's by the
  lookup order, app's kept for the census diff (note 12); `Lite` = byte n then n×n bytes (engine-classes §3.3,
  open-items §10); `FILT` = byte0 hold, byte1 counter, bytes 4..0x23 256-bit mask, N × 0x400 i8 offsets (§3.4);
  PICTs via `PICT.decodePixels` (K1).
- **Tests (10):** `testTileStoreBuilds0xA00Tiles` — 2,560 tiles; sheet 0x8E96 absent → tiles 0x960–0x96F all zero;
  130 fully-zero tiles; UI tiles 0x19C–0x1AF all non-empty (ui-toolkit §0); SHA-256 of the 0x280000-byte store
  `5419637e2a87784239e837484206219cae1d23060c23ec73ce6d3079c94a7b80` (p04) · `testPortraits` — 142 (ids 0x8800–0x88FA
  with the 109 gaps of p03), portrait p ↔ 0x87FF + p, 64×64, max index 255, 48,252 zero pixels in all (p04; §6.2) ·
  `testSkyStrips` — 18 × 288×32, 165,888 px, 35,806 zero (p04) · `testPixImages` — 59; dims per id as Research note 9
  (0x8F00 128×128 … 0x8F87 304×128); 11 widths not a multiple of 4 (0x8F04 215→216 rowBytes, 0x8F05/06/1A 210→212,
  0x8F09 249→252, 0x8F0C 258→260, 0x8F0D 254→256, 0x8F11 253→256, 0x8F18 250→252, 0x8F81 86→88, 0x8F82 38→40); Σ
  bytes 1,838,728 (p04) · `testMacroIcons` — 62 × 512 B raw, 32×16, max index 255 (p04) · `testPaletteFromDataClut` —
  data `clut 256`: seed 0, flags 0, ctSize 255, values 0..255; entry 0 (0xFFFF, 0xFFFF, 0xFFFF), entry 1 (0, 0,
  0xA800), entry 255 (0,0,0); 251 entries are not byte-replicated 16-bit values → `rgb8` = high byte; the app's clut
  differs in exactly entries {0, 16, 252, 253}; `pltt 130` (`PaletteResource`: u16 count 256, 14 reserved bytes, 16-byte
  entries) entry 0 = (0xFFFF, 0xFFFF, 0xFFFF), entry 1 = (0xC6C6, 0xC6C6, 0xC6C6) (p07, p19) · `testCompoTileQuadrants` — synthetic record → 4×4
  quadrant copy per `BuildCompoTile` (`src = tile[e & 0xfff] + ((e>>8)>>3 & 0x18) + ((e>>8) & 0x30)*0x10`); all 264
  shipped non-zero records reference tiles ≤ 0xFFF (p11) · `testLightMasks` — 25 Lite: ids 128–133, 140–158; byte0 n =
  10,12,14,16,18,22, 8,14,20,26,32,38,44,50,58,64,70,76,82,88,94,100,106,114,120; 1 + n² == length for all (p07;
  engine-classes §3.3, open-items §10) · `testDisplacementFilters` — 7 FILT 128–134: frames 6,6,6,6,8,8,6; hold
  0,0,0,0,1,1,1; counter 0; mask bits 28,79,8,50,50,12,43; 0x24 + N·0x400 == length (p07; data-format §3.4) ·
  `testStoredPicturesAsStored` — the 21 PICTs through K1 by opcode class as K1's census (11 indexed-rect, 3 indexed-rgn
  with device-relative tables, 1 direct16 80×130, 6 direct32 88×155), the four raster screenshots 640×480, Land King
  Hall recorded `.refused("0x8200 QuickTime")` (p14).
- **Gate:** G2 = **44/0**. **Commit:** `Cythera/Core: CytheraRender — TileStore (0xA00 tiles), portraits/sky/pix/macro, Palette, compo tiles, Lite/FILT records, PICTs as stored; 10 tests`.

### C6 — minor — Sound: `'asnd'` segments and the 13 interface `snd ` → PCM (→ 50) — ∥ C7, C10
- **Files:** `Sources/CytheraRender/Audio/SoundSegment.swift`; `Tests/CytheraRenderTests/SoundSegmentTests.swift`.
- **Contract:** open-items-2026-10-03 §9 (HIGH): `'asnd'`, u32 blocks, Fixed rate, i16 BE × (blocks·1024 + 512),
  8-bit precision, true length not stored → `samples` kept **as stored** (zero tail included; the mixer's end rule is
  Phase 2's), `trimmedCount` reported; `length == blocks·0x800 + 0x40C` enforced; `snd ` through `SndSound(data:)`
  then the converter rule (`FUN_100b7fac`: blocks = ceil(n/1024) min 1, sample − 0x80, zero tail).
- **Tests (6):** `testAsndCensus` — 46 segments; tag ok; length rule holds in all; rates 0x56220000 ×40 (22,050 Hz),
  0x2B110000 ×2, 0x56EE8B9F ×2, 0x2B7745D0 ×2; Σ samples 1,053,696; Σ trimmed 998,777; every sample in −128..127;
  samples == blocks·1024 + 512 for all (p09; §9) · `testAsnd0x9101Worked` — 17,420 B, 8 blocks, 22,050 Hz, 8,704 samples,
  trimmed 7,567, min −128 max 127, SHA-256 of the raw sample bytes `015dfac04505ead3…` (first 16 hex; p09; §9 xxd) ·
  `testAsndToPCM` — `pcm()` mono, `sampleRate == rate/65536`, frames == samples.count, values as stored (not scaled) ·
  `testThirteenInterfaceSnds` — ids 128,129,130,133,134,135,139,140,141,142,143,145,256; all format 1, one command
  0x8051, 8-bit, encode 0; rates 22,050 ×10, 7,418.18 (140), 22,254.55 (141, 142); base notes 60 except 142 = 72; Σ
  header sample counts 108,669 (p07) · `testSndToAsndConversion` — snd 134 (90 samples) → 1 block, 1,536 samples,
  sample[k] = byte − 0x80, tail zero; snd 256 (45,150) → 45 blocks (p07; §9 converter) ·
  `testHostileAsndThrowsNeverTraps` (odd length, bad tag, every prefix).
- **Gate:** G2 = **50/0**. **Commit:** `Cythera/Core: SoundSegment — 46 'asnd' + 13 snd → PCM, converter rule; 6 tests`.

### C7 — ⚑ MAJOR — Music: MusicDescription + QTMA event decoder for the 11 tunes (→ 58) — ∥ C6, C10
- **Files:** `Sources/CytheraRender/Audio/{TuneSequence,TuneEvent,NoteRequestPart}.swift`; `Tests/CytheraRenderTests/TuneSequenceTests.swift`.
- **Contract (closes INDEX NOT RESOLVED 9's "events not decoded"):**
  1. Container (open-items §9, HIGH layout / MED names): u32@0 = description size = offset of the tune events; +4
     `'musi'`; +0x0E u16 1; +0x10 u32 flags (1 in all 11); header events from +0x14 to size; tune events from size to
     the end; `(length − size) % 4 == 0` in all 11 (p10).
  2. Event words are 32-bit big-endian, classified by the top bits (QuickTime Music Architecture event encoding,
     Apple's `QuickTimeMusic.h`; the planner's reading, **confirmed by the corpus: 44,519 tune words + 2,422 header words
     classify with 0 undefined-type words, every general event's tail word carries the same length as its head, every
     tune ends on an end marker, and the NoteRequest payloads decode to readable strings** — p10, p10b):
     `000` rest (duration 24 bits) · `001` note (part 5 bits @24, pitch 6 bits @18 + 32, velocity 7 bits @11, duration
     11 bits) · `010` control (part 5 @24, controller 8 @16, value 16) · `011` marker (subtype 8 @16: 0 end, 1 beat, 2
     tempo; value 16) · `1001` extended note, 2 words (part 12 @16, pitch 16 bits; w2 `10`, velocity 7 @22, duration 22)
     · `1010` extended control, 2 words (part 12 @16, controller 16; w2 `10`, value 16) · `1011` knob, 2 words · `1111`
     general: head `F part12 len16`, `len − 2` payload words, tail `11 subtype14 len16` with the same length; subtypes
     1 NoteRequest, 4 PartKey, 5 TuneDifference, 6 AtomicInstrument, 7 Knob, 8 MIDIChannel, 9 PartChange, 10 NoOp, 11
     UsedNotes, 12 PartMix. Types `1000`, `1100`, `1101`, `1110` → `TuneError.undefinedEvent(wordIndex)` (Invariant 4).
     **MED:** the extended-note pitch is read as an integer (the corpus's merged pitch range 17–84 rules out 8.8 fixed
     values ≥ 0x1100); the extended-note velocity bit position and the knob fields are the planner's recollection — the
     decoder exposes raw words beside the decoded fields so Phase 2 can re-read them against Apple's header.
  3. NoteRequest payload (84 B = 21 words): NoteRequestInfo {flags u8, reserved u8, polyphony i16, typicalPolyphony
     Fixed} then ToneDescription {synthesizerType 4CC, synthesizerName Str31, instrumentName Str31, instrumentNumber
     i32, gmNumber i32} → `NoteRequestPart` (part index = the general event's part field).
- **Tests (8):** `testElevenDescriptions` — description sizes 924, 412, 1180, 1308, 540, 540, 668, 796, 1692, 796, 1052
  for 0x9000–0x900A; tags, u16@0xE, flags; lengths 8412, 40612, 20200, 19032, 9332, 12812, 12908, 12728, 13608, 9808,
  28532 (p10; data-format §1.5) · `testHeaderEventsParseToEnd` — header words 226, 98, 290, 322, 130, 130, 162, 194, 418,
  194, 258; each header = 3 general events per part (NoteRequest, MIDIChannel, UsedNotes) + 1 rest + 1 end marker;
  MIDIChannel payload = part + 1 (p10, p10b) · `testNoteRequestParts` — 75 parts: 7, 3, 9, 10, 4, 4, 5, 6, 13, 6, 8
  per tune; 70 `'ss  '` "Best Synthesizer" "(GS Instrument)" + 5 "Standard Kit" (gmNumber 16385; 0x9002 part 6,
  0x9003 part 4, 0x9006 part 4, 0x9008 part 9, 0x900A part 3); 0x9000 gmNumbers 87, 54, 93, 25, 9, 102, 36; the GM set
  across tunes = {1, 4, 9, 13, 15, 17, 19, 25, 27, 28, 34, 36, 40, 43, 46, 47, 48, 49, 50, 53, 54, 55, 57, 61, 62, 64,
  65, 72, 74, 76, 77, 81, 87, 90, 92, 93, 95, 96, 97, 100, 102, 103, 104, 109, 110, 122, 123, 126, 16385} (p10b) ·
  `testTuneEventsParseToEnd` — tune words 1872, 10050, 4755, 4431, 2198, 3068, 3060, 2983, 2979, 2253, 6870 (Σ 44,519);
  0 undefined; the last word of every tune is `0x60000000` (end marker value 0) (p10) · `testEventCensus` — 0x9000:
  rest 638, note 674, extended note 87, control 25 (controllers 7 ×6, 10 ×6, 33 ×13), beat markers 210, tempo 1,
  end-value-0 1, end-value-1 7, TuneDifference 7, rest Σ 57,648; corpus: notes + extended notes 13,401, TuneDifference
  168 = interior end markers (value 1) 168, final end markers 11 (p10, p10b) · `testFirstWordsOf0x9000` —
  `0x60020000` → marker(tempo, 0); `0x400A01C2` → control(part 0, controller 10, 0x01C2); `0x40075100` → control(0, 7,
  0x5100); `0x410A01BA` → control(1, 10, 0x01BA) (p10) · `testSyntheticNoteAndExtendedFields` (hand-built words for
  note/xnote/xcontrol/knob/general round-trip the field formulas of contract 2) · `testTruncatedAndUndefinedThrowNeverTrap`
  (prefixes; a `0x8…`/`0xC…`/`0xD…`/`0xE…` top nibble outside a general payload → `undefinedEvent`).
- **Gate:** G2 = **58/0**. **Commit:** `Cythera/Core: TuneSequence — QTMA MusicDescription + events for 11 tunes (75 parts, 44,519 words, 0 undefined); 8 tests`.
- **Seat alone:** field names. **Ben's:** none. **Open for Phase 2:** the value-1 end markers + TuneDifference pairs.

### C8 — ⚑ MAJOR — Script instruction decoder: statements, expressions, operand lengths (→ 64)
- **Files:** `Sources/CytheraCore/Script/{ScriptOpcodes,ScriptInstruction,InstructionDecoder,BuiltinNames}.swift`;
  `Tests/CytheraCoreTests/InstructionDecoderTests.swift`.
- **Contract:** script-vm.md §1 (VAddr tags and literals), §4 (statement opcodes 0x81–0x9F and their operand forms, as
  corrected by the 2026-10-03 review: 0x9C `seg16 <int-expr> <args>`; 0x80 and 0x94–0x9A invalid), §5 (expressions:
  RPN until 0x40; 0x00–0x2F locals, 0x30–0x3F args; 0x53 `!=`, 0x54 `==`; 0x45 inline block = literal bytes; 0x65–0x9A
  invalid; ≥ 0xA0 builtins), §8 (text termination, absolute branches, call encodings), script-builtins.md §2 (the 95
  names). The decoder yields `(offset, length, mnemonic)` per statement with the **same mnemonic vocabulary as
  `scriptdis.py`** (the 34 tokens of Research note 14) — the oracle is the Python tool; where the bank and the tool
  disagree the tool's listing wins for parity and the executor reports the disagreement.
- **Tests (6):** `testStatementOperandLengthsSynthetic` (one hand-built statement per opcode row of §4) ·
  `testExpressionWorkedDecode` (§5 worked decode `local0 = Routine0F02(arg0, 1)`) · `testSegment0x1802Head` — on the
  decrypted bytes: `.hdr` @0000 len 2 (dictionary 0x288E); `.array` @0002 len 6; `.array` @0008 len 34; `frame` @002A
  len 3 (args 1 locals 0); `jf` @002D len 23 → target 0x005C; `setfield` @0044 len 10; `setfield` @004E len 7;
  `return` @0055 len 7; `return` @005C len 4 (p05 listing 1802) · `testTextStatementLength` — `text` @0063 in 0x1802's
  subroutine @0060 is 555 bytes long and ends before `return` @028E (p05) · `testBuiltinForms` — `d9 41 00 40` =
  `builtin set_outdoor_sky(0)` len 4 (statement form, 8 shipped sites; the name is the listing's, from the 95-name
  table of script-builtins §2); the expression inside 0x1802's `jf` @002D that the listing renders `random(0, 4)`
  decodes to the same operand length (p05) · `testInvalidOpcodesRefused` (0x80,
  0x94–0x9A statements; 0x65–0x9A expressions → named error, never trap; a `text` running past the segment end → error).
- **Gate:** G2 = **64/0**. **Commit:** `Cythera/Core: script instruction decoder (statements §4, expressions §5, 95 builtin names); 6 tests`.

### C9 — ⚑ MAJOR — Script segment model + canonical parity with `scriptdis.py` for 958 segments (→ 70) — needs C8
- **Files:** `Sources/CytheraCore/Script/{ScriptSegmentListing,ScriptDecoder,ScriptCanonical,CombatAISegment}.swift`;
  `Tests/CytheraCoreTests/ScriptParityTests.swift`; new tool `docs/cythera/tools/script_canon.py`; new golden
  `docs/cythera/script-parity.sha256` (958 lines); `docs/cythera/tools/README.md` (one row); `docs/cythera/INDEX.md`
  (one line in Files).
- **Contract:**
  1. Kinds as the census measures them (script-census §1, HIGH mechanical): `class` (u16 dictionary offset whose target
     is a 0xA0–0xAF dictionary that fits), `routine` (starts 0x81), `strtab` (0x90–0x9F array of string pointers),
     `dict`/`array` (bare literal block), `ai` (page 0x04, ai-scripts.md §3: 0x20-byte name, 8-byte entries), `data`.
     Census: class 700 · routine 218 · strtab 20 · dict 1 · array 2 · data 3 · ai 14 = 958 (p05 = script-census §1).
  2. Reachability as `scriptdis.py` does it: statements reached from dictionary entries / routine entry / jumps /
     pointers; then a **gap sweep** that decodes unreached bytes as dead code (flag `x`); jump targets flagged `>`
     (script-census §2 "dead-code runs": `8B 41 00 40` epilogues 420, lone `88` 175, longer 4; 0x1802 has 3).
  3. **Canonical parity form** (the spec; `ScriptCanonical.text` and `script_canon.py` must produce identical bytes):
     ```
     seg <ID4> kind <kind> len <TOC length>
     <OFFS4> <LEN> <MNEMONIC> <FLAG>          # one line per listing instruction, in listing order
     ```
     `OFFS4` = four upper-case hex digits; `LEN` = decimal byte length of the instruction (the byte pairs shown + the
     `…+N` continuation; 0 for the AI `name`/`entry` lines; the byte count for `data` lines); `MNEMONIC` = the
     listing's token (`.hdr .array .dict .strtab .string .word text goto jf jt return match set setfield setglobal
     builtin frame call callsub callx send print input prompt atput release sysnew gstore store raise switch name entry`
     and `.data` for a data-kind word line); `FLAG` = `-` reached, `>` jump target, `x` dead code. The Python side
     derives it from the listing text with exactly:
     `^([0-9A-F]{4}):([> x])(?:((?:[0-9a-f]{2} )*[0-9a-f]{2})(?: …\+(\d+))?)?\s*(\S+)` and, for data-kind segments,
     `^([0-9A-F]{4}):  ((?:[0-9a-f]{2} ?)+)$` → `.data`; the kind is the first token after `; kind ` (`ai` when the
     header says "compiled combat AI"); the length is the TOC length. One `.canon` file per segment; the golden is
     `sha256  <id4>` per segment, sorted by id.
  4. Measured over the planner's listings (p17): **958 files, 22,166 instruction lines; flags `-` 16,899 · `>` 4,665 ·
     `x` 602; 34 mnemonics: text 3,785 · goto 2,611 · jf 2,509 · return 2,283 · match 1,556 · set 1,480 · builtin 1,417 ·
     frame 1,271 · .array 853 · .string 828 · .dict 701 · .hdr 700 · setfield 554 · call 552 · print 289 · entry 178 · jt
     161 · input 108 · prompt 95 · send 70 · callsub 40 · atput 26 · .strtab 20 · setglobal 18 · release 17 · name 14 ·
     sysnew 10 · gstore 5 · .word 4 · .data 4 · raise 3 · switch 2 · callx 1 · store 1.** The executor regenerates the
     listings (`python3 docs/cythera/tools/scriptdis.py --out "$SCRATCH/scripts" --quiet`; 958 files, byte-identical
     census to `docs/cythera/script-census.md` — p05), runs `script_canon.py`, commits the hash list once, and the
     Swift test must match it. A mismatch is a Swift bug by definition (the tool is the oracle); the implementer fixes
     Swift or STOPS — never the golden.
- **Tests (6):** `testKindClassification` — 958 by kind as contract 1, per-page counts of script-census §1 (0x10 180,
  0x18 121, 0x1B 111, 0x11 88, 0x1A 87, 0x0E 66, …) · `testDictionaryAndMethods0x1802` — dictionary @0x288E; methods
  sel 32 @002A, sel 12 @0292; property sel 68; class 0x40 id 2 (p05) · `testReachabilityFlags` — corpus flags `-`
  16,899 · `>` 4,665 · `x` 602; 0x1802 dead-code runs 3 (p17, p05) · `testLiteralAndDataSegments` — 0x0201 strtab 256
  entries, [2] "Alaric" @0409; 0x0101 plaintext dictionary 127 slots / 55 keys; 0x0301 array; 0x033F data 4 B;
  0x0500 data 20 B; 0x0540 data 4 B (p05; script-census §2) · `testCombatAISegments` — 14: lengths 128,128,128,168,88,176,
  120,128,128,128,88,168,176,120; 0x0410 name "Attack Nearest", entries (len − 32)/8 (p03, p05; ai-scripts §3) ·
  `testCanonicalParityAll958` — `ScriptCanonical.text` hashed per segment == `docs/cythera/script-parity.sha256`;
  22,166 lines; the mnemonic histogram of contract 4 (p17).
- **Gate:** G2 = **70/0**. **Commit:** `Cythera/Core: script segment model + canonical parity (958/958 vs scriptdis.py; tools/script_canon.py; script-parity.sha256); 6 tests`.

### C10 — minor — UI resource records and fonts (→ 79) — ∥ C6, C7
- **Files:** `Sources/CytheraCore/UI/{DialogTemplate,DialogItemList,WindowTemplate,ControlTemplate,AlertTemplate,MenuResource,MenuBar,StringList,PascalString,TextStyle,FontFamily,StartRects,PrefDefault}.swift`;
  `Sources/CytheraRender/Text/BitmapFont.swift`; `Tests/CytheraCoreTests/UIRecordTests.swift`; `Tests/CytheraRenderTests/BitmapFontTests.swift`.
- **Contract:** classic record layouts (Inside Macintosh; ui-toolkit §1 "Which window uses which frame" decoded them
  with `struct.unpack('>4hhhhI', …)`): DLOG = rect(4×i16), procID, visible, filler, goAway, filler, refCon i32, itemsID
  i16, title Str255; WIND = rect, procID, visible, filler, goAway, filler, refCon, title; CNTL = rect, value, visible,
  filler, max, min, procID, refCon, title; ALRT = rect, itemsID, stages u16; DITL = i16 count−1, items {4 B, rect, type
  u8, Str}; MENU = id, width, height, procID, filler, enableFlags u32, title, items…; MBAR = count, ids; STR# = count,
  Str255s; TxSt per TMPL 128 = size u8, style byte, name Str255 (note 13); FOND = 52-byte header + association table at
  0x34 (count−1, {size, style, id}); NFNT = 26-byte header, strike rowWords·2·fRectHeight bytes, locTable (lastChar −
  firstChar + 3) u16, owTable at 16 + owTLoc·2 — **both shipped NFNTs are 2 bytes short of the full owTable (100 of 101
  entries); the missing last entry reads as 0xFFFF (no glyph)** (note 14). Strings are Mac Roman via `MacRoman.decode`.
- **Tests (9):** `testDialogsAndItems` — 17 DLOG: ids 128–142, 900, 9300; procID 16001 for 128–139 and 141, 1 for 140,
  142, 900, 9300; titles 128 `oO;qQ;nN;lL`, 129/134/135 `sSyY;cC;DdnN`, 130–133 `;;Mm;Fm`; rects 128 (40,40,356,420),
  133 (37,65,440,450), 140 (40,40,163,421); 20 DITL items 5,4,4,20,8,13,4,3,11,4,4,14,5,4,6,6,3,2,24,3 (Σ 147) and
  equal to `HectorGraphics.Ditl.decode(_:).count` for all 20 (p07; ui-toolkit §1, §3.2) · `testWindows` — 10 WIND:
  128 "Delver" (20,0,480,640) procID 12; 129 "Map" (16,304,336,624) 16004; 130 "Text" 16016 refCon 0x1220; 131
  "Roster" 16000; 132 "Character" 16000 goAway 1; 133 "Spellbook" 16016 refCon 0x22018 goAway 1; 134 "New Window"
  16048; 135 "Status" (354,0,482,640) procID 2; 136 "To Do" (352,10,352,223) 16032; 1134 "New Window" 16017 (p07;
  ui-toolkit §1 table) · `testControls` — 8 CNTL: 128 "Quit", 129 "Onward!", 130 "Load Player", 131 "New Player"
  (50,200,82,296) procID 16000; 132 "Save" (0,0,32,64); 133 "Cancel"; 134 "Don't Save" (0,0,32,96); 135 procID 1017
  min 135 (p07) · `testAlertsMenusBars` — ALRT 129, 134, 135, 901, 1024; MENU ids 128–138, 200, 201, 202; MBAR 128 →
  2 menus, 129 → 1; CMNU 129 counted (219 B) (p07; app-shell §4) · `testStringLists` — app STR# counts 500:4, 501:10,
  502:7, 503:5, 990:6, 9300:4, 9301:8, 9303:16, 9304:16, 9305:2, 9306:0, 9307:6, 9308:13, 9320:6, 9321:16, 31999:13;
  data 128:4 ("Bye","Name","Job",…), 134:7, 135:41 ("World","Odemia","LKH",…), 255:82, 900:4; STR 128 "Cythera
  Preferences", 129 "Cythera Data", 130 "Cythera Patch"; every list consumes its resource exactly (p07; INDEX census) ·
  `testTextStylesPrefsStartRects` — app TxSt 128 "Sys Large" 12 Chicago · 129 "Sys Small" 10 style 0x01 Geneva · 130
  "Labels" 9 Geneva · 131 "Stats" 10 0x01 Geneva · 132 "Text" 10 Espy Sans · 133–135 Lang0 10/12/18 Espy Sans; data
  TxSt 128 18 ArgosANouveau · 129 14 0x01 ArgosANouveau · 130 9 Geneva · 131 9 0x81 Geneva · 132 10 Geneva · 133–135
  14/22/24 ArgosANouveau · 136–138 10/12/18 Seldane · 999 "Label Colors" bytes A8 4D DD BD; the lookup order makes the
  data styles effective (p18, note 13); Pref 128 "Volume" 5, 129 "Music" 2 (data-format §8.1); nrct 128 = 8 rects,
  rect 0 (102,166,133,317), rect 6 (19,279,47,465), rect 7 (0,0,155,88) (p07; app-shell §5.1) · `testFontFamilies` —
  app FOND 128 "Rogue Font" family 7707, one association (12, 0, 128) whose NFNT 128 does not exist in any committed
  file; data FOND 128 "Seldane" family 128 → (12,0,25740), (18,0,25746); FOND 1046 "ArgosANouveau" → (0,0,7289) =
  sfnt 7289 (TrueType: 12 tables, unitsPerEm 4096, 81 glyphs, name "ArgosANouveau") (p15) · `testBitmapFonts` — NFNT
  25740: fontType 0x9000, chars 0–98, widMax 16, kernMax −1, rect 16×14, ascent 12 descent 2 leading 1, rowWords 17,
  strike 476 B, loc table 101 entries monotonic (last 257), ow table 100 entries, 27 chars with glyphs (`A–K M N P–Z b`
  + 2 control codes); NFNT 25746: 24×21, ascent 18 descent 3 leading 2, rowWords 25, strike 1,050 B, 29 glyphs (p18) ·
  `testGlyphExtraction` — glyph 'A' of NFNT 25740: columns loc['A'+1] − loc['A'] > 0, width from ow low byte, offset
  from ow high byte; a 0xFFFF entry returns nil; hostile (short strike) throws.
- **Gate:** G2 = **79/0**. **Commit:** `Cythera/Core: UI resource records (DLOG/DITL/WIND/CNTL/ALRT/MENU/STR#/TxSt/FOND/nrct/Pref) + BitmapFont (NFNT); 9 tests`.

### C11 — minor — `cythera-census` + `docs/cythera/data-census.md` + `--render` (→ 84) — needs C5–C10
- **Files:** `Package.swift` (executable + `CytheraCensusTests`); `Sources/CytheraRender/Census/CytheraCensus.swift`;
  `Sources/cythera-census/main.swift`; `Tests/CytheraCensusTests/CytheraCensusTests.swift`; `docs/cythera/data-census.md`
  (new); `docs/cythera/INDEX.md` (one pointer row in Files).
- **Tool contract:** `cythera-census <Resources/Cythera dir> [--render <out dir>]`; Markdown on stdout, names never
  machine paths; exit 0 / 1 (any failure, each named) / 2 (bad args). Sections: files · segment file (header, pages,
  one line per non-script segment with band, length, decode result; script band as one line per page + the parity
  verdict) · maps · props · globals · pixels · sounds · music (per tune: parts with gmNumbers, event census) · resources
  (per type counts for the three files; one line per decoded resource) · fonts · unread · Totals. `--render` writes
  `tiles-0x8E19-0x8E1A.png` (the 32 UI-art tiles as two 16-tile rows), `portrait-0x8800.png`, `sky-0x8400.png`,
  `start-screen-pict-132.png` (through its own 224-entry table), `pix-0x8F80.png` (status art, data clut) — ImageIO in
  `Sources/cythera-census` only; the seat's addition, optional, nothing for Ben to judge.
- **Exact summary lines** (each a whole stdout line, in this order, Totals last; every number from p01–p19):
  ```
  # Cythera 1.0.4 — data census
  files 20 · bytes 11,570,723 · Cythera Data 5,608,688 · Cythera Data.rsrc 1,247,331 · Cythera.rsrc 1,008,484 · Cythera Documentation.rsrc 2,420,779 · ai 8 · pict 5
  segments 1,558 · TOC pages 34 · bytes 5,524,330 · overlaps 0 · header 0x1300 0x0200 0x0200
  scripts 958 · code 918 (class 700 · routine 218) · strtab 20 · dict 1 · array 2 · data 3 · ai 14 · unknown opcodes 0 · parity 958/958 · canonical lines 22,166
  maps 42 · cells 206,976 · chunk records 233 · chunked 0 · with exits 23 · compo cells 19,650 · max tile 0x429
  props 40 · records 14,485 · kinds 00:12104 01:116 02:46 08:618 09:241 0A:7 10:32 11:55 18:31 1C:1 42:879 44:298 80:52 FF:5
  globals 20 · base tiles 395 · anim 8 · tile flags 2,125 · names 547 · creatures 50 · chars 131 · schedules 617 · teleports 190 · wall 50 · compo 264 · filter tiles 124
  pixels sheets 159 (0x8E96 absent) · portraits 142 · sky 18 · pix 59 · macro 62 · LZ ops 554,796 · LZ bytes 5,191,304 · raw bytes 31,744
  sounds asnd 46 · 22050 Hz 40 · 11025 Hz 2 · 22254.5 Hz 2 · 11127.3 Hz 2 · samples 1,053,696 (trimmed 998,777) · snd 13 · samples 108,669
  music 11 · parts 75 (GS 70 · Standard Kit 5) · tune words 44,519 · notes 13,401 · undefined 0 · end markers 11 · tune differences 168
  resources app 339/52 · data 113/18 · documentation 268/40 · PICT 21 (indexed 14 · direct 7) · clut 2 (differ 4) · Lite 25 · FILT 7 · snd 13 · DLOG 17 · DITL 20 (items 147) · WIND 10 · CNTL 8 · ALRT 5 · MENU 14 · MBAR 2 · STR# 21 · STR 3 · TxSt 20 · FOND 3 · NFNT 2 · sfnt 1 · pltt 1 · nrct 1 · Pref 2
  fonts Sys Large ArgosANouveau 18 · Sys Small ArgosANouveau 14 bold · Labels Geneva 9 · Stats Geneva 9 bold · Text Geneva 10 · Lang0 ArgosANouveau 14/22/24 · TxSt 136–138 Seldane 10/12/18 · literal TextFont 0/1/3 · TextSize 0/9/10
  unread 0x8EFF 4,694 B · PORT 2 · LINF 3 · MSta 3 · eBRS 25 · eSTM 16 · RMAP 1 · DATA 10 · CMNU 1 · crsr 57
  Totals: segments 1,558 (decoded 1,557 · no reader 1) · resources decoded 198 · files 14 · failures 0
  ```
  Arithmetic: 198 = PICT 21 + clut 2 + pltt 1 + Lite 25 + FILT 7 + nrct 1 + Pref 2 + snd 13 + DLOG 17 + DITL 20 +
  WIND 10 + CNTL 8 + ALRT 5 + STR# 21 + STR 3 + TxSt 20 + FOND 3 + NFNT 2 + sfnt 1 + MENU 14 + MBAR 2; files 14 = 8
  `.ai` + `AI Scripting Document` (CR-terminated text: 17/20/19/13/29/12/19/30 and 301 lines, no LF, ASCII — p20) +
  5 screenshots (4 raster decoded, Land King Hall QuickTime named); 1,557 = 1,558 − 0x8EFF. "fonts" literal values:
  TextFont immediates 0 ×2, 1 ×2, 3 ×3 and TextSize 0 ×4, 9 ×1, 10 ×2 at the 22 call sites whose argument is a literal
  (15 sites load it from a register — p16); the tool prints them from a constant table with that provenance, not by
  reading the binary.
- **Doc:** S5. **Tests (5):** `testSummaryLinesExact` (the 14 lines above verbatim, in order) ·
  `testStdoutEqualsCommittedCensus` (stdout byte-equals the doc body below its rule) · `testExitCodes` (bad args → 2; a
  temp folder with `Cythera Data` truncated to 0x1000 bytes → 1 and the line names the file) · `testOneLinePerSegment`
  (600 non-script segment lines + 24 script-page lines + 198 resource lines) · `testRenderWritesFivePNGs` (temp dir; five
  files of the named sizes: 512×64, 64×64, 288×32, 640×480, 128×128).
- **Gate:** G2 = **84/0**, G3. **Commit:** `Cythera/Core: cythera-census + docs/cythera/data-census.md (1,558 segments, 198 resources, 0 failures); 5 tests`.

### C12 — minor — Final gates + DECISIONS as-built
- **Steps:** re-run G1 (on `$HK` main after K1), G2 (84/0), G3, G4, G5, G7, G9; append to D28 an "As built" paragraph
  (HectorKit sha + floor, `Cythera/Core` test total, the census Totals line, the MED/LOW items carried: notes 12–14,
  C7's open markers, the kit fallback not used); `docs/cythera/INDEX.md` NOT RESOLVED 9: one line "QTMA events decoded
  (Phase 0 C7, data-census.md); open: value-1 end markers / TuneDifference semantics". **STATE/RESUME/handoff are the
  orchestrator's.**
- **Commit:** `docs: Cythera Phase 0 as built (D28)`.

---

## Execution order

| wave | HectorKit (`$HKWT`) | Classics lane A | Classics lane B | Classics lane C | review legs (Fable) |
|---|---|---|---|---|---|
| A | K1 ⚑ (push, pull --ff-only) | C0 → C1 → C2 | — | — | K1 two; C0+C1+C2 one |
| B | — | C3 → C5 ⚑ (needs K1 on main) | C4 ⚑ | C8 ⚑ → C9 ⚑ | C3 one; C5 two; C4 two; C8 two; C9 two |
| C | — | C6 | C7 ⚑ | C10 | C6 one; C7 two; C10 one |
| D | — | C11 → C12 | — | — | C11 one |

- Disjoint files: wave B lanes own `Sources/CytheraCore/{Codec,Art}` + `Sources/CytheraRender/Pixels` (A), `World/`
  (B), `Script/` (C); only lane A touches `Package.swift` in wave B (C5 adds the Render target). Wave C lanes own
  `CytheraRender/Audio/SoundSegment`, `CytheraRender/Audio/Tune*`, `CytheraCore/UI` + `CytheraRender/Text`; none
  touches `Package.swift`. C11 owns `Package.swift` in wave D.
- Orchestrator sessions are 2–3 tasks (fable-kit §5); one Opus implementer per task in the lane worktree; the
  orchestrator merges, re-runs G1–G9 at the merge head, updates STATE, ends each session with a handoff + chip.

---

## Pre-execution self-audit

1. **Design §9 row 0 coverage.** Data in git (C0) ✅; skeleton (C1) ✅; segment file + XOR + LZ (C2, C3) ✅; resources
   (C1, C5, C10) ✅; maps/props/globals/CharEntry (C4) ✅; tiles/portraits/sky/icons/pix → indexed (C5) ✅; `clut` (C5)
   ✅; `Lite`/`FILT` (C5) ✅; `'asnd'` + `snd ` → PCM (C6) ✅; QTMA → events, NR 9 closed (C7, C12) ✅; Swift script
   decoder at parity with `scriptdis.py` (C8, C9) ✅; `cythera-census` → `docs/cythera/data-census.md`, 0 failures
   (C11) ✅; font census incl. requested ids/sizes (C10, C11; design §8.8) ✅.
2. **Brief item 2 (kit decisions) each justified in one line** ✅ (Architecture); K1 is the only kit change; its
   dependency and fallback are explicit (K1 "Fallback", wave A).
3. **Every expected number is a probe or a bank cite.** Self-derived values that the first green run records (none —
   every census line above is pre-measured) ✅. The one deliberately unpinned item is the Land King Hall codec (named in
   a log, not asserted) ✅. The `script-parity.sha256` content is generated by the recipe, not typed here; its line count
   (958), instruction count (22,166) and histogram are pinned ✅.
4. **Ladder arithmetic** from the named tests: C1 5, C2 9, C3 6, C4 14, C5 10, C6 6, C7 8, C8 6, C9 6, C10 9, C11 5 →
   5, 14, 20, 34, 44, 50, 58, 64, 70, 79, 84 ✅. K1 4 + 2 = 6 → 319 ✅.
5. **Census arithmetic.** 11 + 3 + 1 + 6 = 21 PICT (indexed 14, direct 7) ✅; 159 + 142 + 18 + 59 = 378 LZ streams, op
   census sums to 554,796 ✅; 2,605,056 + 581,632 + 165,888 + 1,838,728 = 5,191,304 ✅; 7+3+9+10+4+4+5+6+13+6+8 = 75 parts
   ✅; TuneDifference 168 = Σ(end markers per tune − 1) ✅; resources 198 ✅; DITL items 147 ✅; 1,557 + 1 = 1,558 ✅.
6. **Type-name consistency.** `IndexedImage`/`Palette` (S3) are created in C5 and used by C11; `ScriptInstruction` /
   `ScriptSegmentListing` / `ScriptCanonical` (S2) are created in C8/C9 and only then; `SoundSegment` and `TuneSequence`
   never appear in CytheraCore; `ColorTableRecord`/`LightMask`/`DisplacementFilter` are CytheraCore (data) and consumed
   by CytheraRender ✅. Every ruling reference is D28; D27 appears only as the last taken number (Landmine e).
7. **Honoured "decode as the original reads":** pix rowBytes (p04), `0x9f < sVar6` sheet range (data-format §3.4), the
   zero `asnd` tail, 0x0101/0x0210 raw, FOND 128's dangling association, NFNT's short owTable ✅.
8. **Risk carried from design §12** ✅ (Hazards); encryption covers script pages only and the reader never decrypts the
   two plaintext segments (C2) ✅; Ferazel K1 has landed on main (d38a541) so `decodePixels` exists — the dependency is
   now this plan's own K1 ✅; D-number collision (Landmine e) ✅; dumps absent here (Invariant 10) ✅.
9. **Sibling sessions:** `.claude/worktrees/` holds 14 sibling worktrees (one, `deimos-phase1`, is a live build lane);
   this plan writes only `$WT`, `$HKWT` and the clean `pull --ff-only` ✅.

---

## Open questions for Ben (real forks only)

None. (The clut choice, the 16/32-bit PICT colour search and the QTMA value-1 markers are MED/LOW items carried to the
phase gate cards, not forks.)

---

## Hazards (design §12 + what the probes found)

1. **Regenerate the dumps before trusting a line number** — none of the three decompiles is in this worktree
   (`ghidra/` holds scripts only); INDEX provenance recipes; the Ghidra project path must not contain a dot-prefixed
   element; copy the project before a postScript; `ghidra/find_func.py` defaults to Aki's dump — always `--file`;
   `tools/pef.py --help` writes a stray file named `--help`; `tb.py`/`ppcdis.py` take `--bin` (the planner used a copy
   of the PEF in `$SCRATCH`).
2. **The VM's stack must not clear popped slots** (script-vm.md §3, §8; open-items-2026-10-06 §1) — not Phase 0 code,
   but the C8/C9 decoder must not "fix" the 0x9C FFFF encoding it lists.
3. **Two wave-1 readings were overturned** (the ending branch NR 22; rules.md §3.4's 0x80) — cite corrected sections.
4. **Encryption covers script pages only**; 0x0101 and 0x0210 ship plaintext (NR 3) — C2 never decrypts them.
5. **Ferazel K1 landed** (HectorKit main `d38a541`, D12, floor 313); this plan's K1 builds on it. Check `git -C
   ~/Developer/HectorKit log --oneline -3` first; if the floor moved, apply Invariant 9.
6. **D-numbers collide** across parallel sessions (Landmine e).
7. **`0x8EFF` is not a tile sheet** (4,694 B, not LZ; no reader; note 5). `0x8E96` is absent → tiles 0x960–0x96F are zero.
8. **Pix rows are 4-byte padded** (note 6) — a `w·h` reader under-reads 11 of 59 images.
9. **Two `clut 256` resources** (note 12) — name the one used, everywhere.
10. **PICT 129 (paper doll) is 16-bit and 133–138 (start-screen frames) are 32-bit** in an 8-bit game: the original
    drew them through QuickDraw's colour search into the 256-colour screen (LOW, like Ferazel D26's Color2Index) — a
    Phase 1/4 gate-card item; Phase 0 stores them as stored.
11. **NFNT owTable is one entry short in both fonts** (note 14); **FOND 128 in the app names an NFNT that does not
    exist**; the TxSt sizes 10 for Seldane and 14/22/24 for ArgosANouveau are not bitmap sizes — the Font Manager
    scaled/rasterised (Phase 1 text plan).
12. **QTMA value-1 end markers + TuneDifference events** (168 pairs) — decode and count, do not interpret (C7).
13. **`Land King Hall screenshot.pict` is QuickTime-compressed** (0x8200) — an oracle file, not game data; never a
    census failure.
14. **`Cythera Documentation`'s data fork is 0 bytes** — only the `.rsrc` is committed; the viewer is Phase 8.

---

## Bank corrections to append (each as a ⚑ planner-probe note in the named file; no bank file is edited by this plan — C12 appends them with the census)

1. **data-format.md §1.5 row 0x8E00+n / §3.4 "160 sheets 0x8E00..0x8E9F":** 159 sheets lie in `LoadTiles`' range
   (0x8E96 is absent → tiles 0x960–0x96F have no pixels); the 160th segment of the page is **0x8EFF (4,694 B), not an
   LZ stream and read by nothing** (p03, p04).
2. **data-format.md §1.5 rows 0x8F00+n / 0x8F80+n "{u16 w, u16 h, LZ pixels}":** the LZ output is `((w+3) & ~3) · h`
   bytes — rows padded to 4 bytes; 11 of 59 images have `w % 4 ≠ 0` (p04).
3. **data-format.md §3.4 / §5 0xF001 "records of 4×i16 … zero-terminated":** 8 records, then one zero i16, then 2 unread
   bytes (66 B) (p11).
4. **data-format.md §5 0xF004 "547 names":** confirmed; 6 bytes follow the 0x7FFF terminator (p11).
5. **engine-classes.md §5 / ui-toolkit.md §0 "palette = clut 256 (`GetCTable(0x100)`)":** two `clut 256` resources
   exist — `Cythera.rsrc` (SHA `f3373625…`) and `Cythera Data.rsrc` (`e7fe2eef…`) — differing in entries 0, 16, 252,
   253 (entry 0: 0xFC00 vs 0xFFFF white). The data file is opened after the app, so the chain returns its copy [MED] (p07, p19).
6. **design §4 "committed (≈ 16 MB)":** 20 files, 11,570,723 B (p01).
7. **design §8.8 / digest §2.3 "which font ids/sizes the game requests is not in the bank":** the `TxSt` resources carry
   them (TMPL 128: size, style byte, font name); the data file's twelve override the app's eight: Sys Large
   ArgosANouveau 18 · Sys Small ArgosANouveau 14 bold · Labels Geneva 9 · Stats Geneva 9 bold(+0x80) · Text Geneva 10 ·
   Lang0 Small/Medium/Large ArgosANouveau 14/22/24 · TxSt 136–138 Seldane 10/12/18 · "Label Colors" A8 4D DD BD. Literal
   Toolbox calls: `TextFont` 22 sites (immediates 0 ×2, 1 ×2, 3 ×3; 15 register-loaded), `TextSize` 22 (0 ×4, 10 ×2,
   9 ×1; 15 register-loaded), `TextFace` 27, `TextMode` 7 (0, 1 ×3, 49 ×3), `GetFNum` 1 (p16, p18).
8. **INDEX "Resource census" Cythera Data.rsrc FOND/NFNT/sfnt:** FOND 128 "Seldane" (family 128: 12 → NFNT 25740, 18 →
   NFNT 25746; 27/29 glyphs, upper-case letters + 'b'), FOND 1046 "ArgosANouveau" → sfnt 7289 (TrueType, 81 glyphs,
   4096 upem); app FOND 128 "Rogue Font" (family 7707) → NFNT 128, **which no committed file holds**. Both NFNTs end 2
   bytes before the full owTable (p15, p18).
9. **open-items-2026-10-03.md §9 / INDEX NOT RESOLVED 9 "QTMA events not decoded":** decoded (C7): 11 tunes, 75
   NoteRequest parts (70 GS instruments, 5 Standard Kit), 44,519 tune words, 13,401 notes, 0 undefined words; every
   tune: tempo marker first, end marker (value 0) last; 168 interior end markers with value 1, each followed by a
   3-word `TuneDifference` general event whose payload word is `0x60000000` — semantics open (p10, p10b).
10. **open-items-2026-10-03.md §9 `'asnd'`:** confirmed on all 46; Σ samples 1,053,696, Σ non-zero-trimmed 998,777;
    sample range −128..127 everywhere (p09). The 13 interface `snd ` are format 1 / `bufferCmd` / 8-bit; three rates
    (22,050; 7,418.18 for id 140; 22,254.55 for 141–142); base note 72 on 142 (p07).
11. **data-format.md §4.2 rows +0xA / +0xE..0xF:** confirmed — 0 in all 14,485 records; byte 0xE bits 6–7 and byte 0xF
    zero (p11). §4.3 kind census and §6.1 CharEntry field census reproduce exactly (p11).
12. **script-census.md:** regenerated byte-identical (958 listings, 0 unknown opcodes) in 0.32 s (p05); the canonical
    form of C9 adds 22,166 instruction lines / 34 mnemonics as a second mechanical check (p17).
13. **data-format.md §1.5 "page 0x80: 42 maps" / STR# 135 "41 level names":** 0x8000 (32×32, no 0x8100 props) has no
    name; 0x8001–0x8029 ↔ the 41 names; 0x8125 has no props (p03, p07).

---

## Research notes (every probe result the executor needs; probes in `$SCRATCH/probes`, run 2026-10-06)

1. **Files (p01).** SHA-256 / bytes of the 20 committed files: `Cythera Data` 8f45758d8f3024f3ee0bd7bd16717803fae43874b56bf27472e2cef2ccbefa59 / 5,608,688 ·
   `Cythera Data.rsrc` 824d8a1d532419b7d2cddf97e93fba753645435e57bbaeabff01f7593cee35e7 / 1,247,331 ·
   `Cythera.rsrc` 333416124a74a18bd07ee19c1fb8a602c014046220a3324491e0449875f170f1 / 1,008,484 ·
   `AI Scripting Document` 66456bf781731508bf40acdb5fe81c01f254e353745d76e2ba45d81446d6103d / 10,331 ·
   `Cythera Documentation.rsrc` 00fe7c752206f3d7d78e0aa21362d1841b90d487d46677f178ea5348a9382726 / 2,420,779 ·
   `Attack Nearest.ai` 46331b2b…474976 / 428 · `Attack Strongest.ai` 6a01b191…04178a / 437 · `Attack Weakest.ai`
   4123411c…8be4be5 / 432 · `Beserk.ai` 95472845…827a14 / 317 · `Defend.ai` 532cbbe7…2537d5 / 712 · `Dummy.ai`
   b56a7a70…fc3c7 / 310 · `Healer.ai` ccbb73a3…a281 / 526 · `Missile User.ai` 3111734a…7dc00 / 715 ·
   `Catamarca screenshot.pict` bcdafd33…02f86 / 397,738 · `Land King Hall screenshot.pict` 73f0d130…9149b / 164,900 ·
   `Odemia screenshot.pict` 092bd628…9db6b / 250,384 · `Pnyx screenshot.pict` 30b01e83…30234 / 210,220 ·
   `Unicorn screenshot.pict` f44862d6…739cf / 240,490 · `Cythera 1.0.4 Notes.text` 57c7ad31…85910 / 5,056 ·
   `Cythera License.text` 2d129e3c…a250 / 2,445. Total 11,570,723 (full hashes in `p01_files.txt`; C0 checks by `cmp`).
   Not committed: `Cythera` (PEF, 890,864), `Register Cythera` (+ .rsrc), 17 InputSprocket files + `InputSprocketLib` +
   `USBHIDUniversalModule` (+ .rsrc), 9 `*.ai.rsrc`/`AI Scripting Document.rsrc` (BBST/MPSR editor state), 5 `Icon_*`
   (+ .rsrc), `Ambrosia FAQ.text`, `Ambrosia Products FAQ.text` (+ .rsrc), 4 web-link files, `Stuck_ Get the Cythera
   Hintbook` (+ .rsrc), `Cythera Documentation` (0 B), `*.text.rsrc`, `Land King Hall screenshot.pict.rsrc` (286 B,
   not a resource map).
2. **Segment census (p02 = `seg.py`):** 34 pages / 1,558 segments; per page: 01:1 · 02:20 · 03:2 · 04:14 · 05:3 · 08:22 ·
   09:19 · 0A:8 · 0B:1 · 0C:30 · 0D:10 · 0E:66 · 0F:22 · 10:180 · 11:88 · 14:42 · 15:3 · 18:121 · 19:29 · 1A:87 ·
   1B:111 · 1C:38 · 1E:1 · 30:40 · 80:42 · 81:40 · 84:18 · 88:142 · 8A:62 · 8E:160 · 8F:59 · 90:11 · 91:46 · F0:20.
3. **Bands (p03):** root entries 35 (root[0] self + 34 pages); Σ lengths 5,524,330; 0 overlaps; header bytes 0x00–0x4F
   `17 "Cythera: Fate of Alaric" 00… | 1300 0200 0000 0000 0200 0000 …`; absent-in-range ids: props 0x8125; globals
   0xF003/0xF006/0xF00E; asnd 0x910C–0x910E, 0x9128; tiles 0x8E96; portraits 109 gaps between 0x882A and 0x88EE; pix
   present 0x8F00–0x8F1A, 0x8F20–0x8F30, 0x8F34–0x8F38, 0x8F50, 0x8F51, 0x8F80–0x8F87; AI 0x0410–0x0416, 0x0430–0x0436
   (lengths 128,128,128,168,88,176,120 | 128,128,128,88,168,176,120).
4. **LZ (p04 = `lz.py`):** 378 streams consume exactly their segment (pix after 4 B); op census A 222,174 · B 301,737 ·
   C 29,065 · D 56 · E 1,024 · F 362 · end 378; SHA-256 of sheet 0x8E00 / portrait 0x8800 / sky 0x8400 as in C3.
5. **0x8EFF (p04):** 4,694 B, head `00c2 007f f04a 27f0 2fff b43f 0080 1e00 bc5f 0200 00bc 5f00 3c27 f028 1804 0919`,
   `lz.py` raises (match before start). No reader in the bank; listed as "no reader".
6. **Pix dims (p04):** 0x8F00 128×128 · 01 352×352 · 02 256×252 · 03 256×256 · 04 215×223 · 05 210×259 · 06 210×259 ·
   07 256×272 · 08 200×150 · 09 249×249 · 0A 252×238 · 0B 248×250 · 0C 258×257 · 0D 254×254 · 0E 256×183 · 0F 256×256 ·
   10 256×251 · 11 253×253 · 12 160×256 · 13 256×256 · 14 280×292 · 15 256×256 · 16 248×247 · 17 248×247 · 18 250×247 ·
   19 256×256 · 1A 210×259 · 20 64×128 · 21–30 24×17 ×16 · 34 128×128 · 35/36 12×12 · 37/38 12×8 · 50/51 144×144 ·
   80 128×128 · 81 86×128 · 82 38×44 · 83 64×128 · 84 304×128 · 85 72×50 · 86 36×48 · 87 304×128. Decoded bytes equal
   `((w+3)&~3)·h` in all 59 (the planner's first `w·h` expectation failed on 5, then on all 11 odd widths).
7. **0xF001 (p11):** 66 B = 8 records + zero i16 + 2 bytes; records (tile, base, nframes, divisor): (987,987,4,2)
   (2161,2161,4,1) (1275,1274,2,4) (1180,1180,4,1) (1176,1176,4,1) (1172,1172,4,1) (1168,1168,4,1) (902,902,4,1).
8. **Maps (p11):** (id W H C): 8000 32 32 0 · 8001 256 256 0 · 8002 64 64 16 · 8003 64 64 0 · 8004 32 32 0 · 8005 8 8 0 ·
   8006 64 64 26 · 8007 32 32 0 · 8008 128 128 102 · 8009 128 128 0 · 800A 32 32 0 · 800B 64 64 1 · 800C 64 64 9 · 800D
   64 64 36 · 800E 56 72 0 · 800F 32 32 0 · 8010 64 64 0 · 8011 16 16 2 · 8012 32 64 3 · 8013 64 64 0 · 8014 64 32 3 ·
   8015 64 64 0 · 8016 32 32 2 · 8017 32 32 0 · 8018 64 64 6 · 8019 64 64 0 · 801A 64 32 3 · 801B 64 64 0 · 801C 64 64 0
   · 801D 48 48 0 · 801E 32 32 0 · 801F 48 48 9 · 8020 48 48 9 · 8021 64 64 0 · 8022 64 64 0 · 8023 64 64 0 · 8024 64
   64 4 · 8025 64 64 0 · 8026 24 16 0 · 8027 64 64 2 · 8028 64 64 0 · 8029 32 24 0. Σ C = 233; 206,976 cells.
9. **Props per level (p11, first six):** 0x8101 429 · 0x8102 799 · 0x8103 1,119 · 0x8104 39 · 0x8105 2 · 0x8106 736
   records; Σ 14,485 over 40 segments (`props_census.py` agrees).
10. **Resources (p06 = `rsrc.py`, p07):** per-type counts = INDEX "Resource census" exactly for all three files. Lite ids/
    sizes, FILT ids/frames, snd ids/rates/header lengths, DLOG/WIND/CNTL fields, STR# counts, TxSt bytes, DITL item counts
    as written in C5/C6/C10. `pltt 130` = 256 entries. `nrct 128` bytes `0008 0066 00a6 0085 013d 00b3 00a6 00d2 013d …`.
11. **PICT opcode census (p14):** every picture is v2 with exactly one bits opcode and bounds = frame; opcode sets
    {0x11, 0xC00, 0x01, 0x98, 0xFF} (app 0/900; data 130), {… 0xA1 … 0x98} (132, 139–145), {… 0x1E … 0x99} (131, 512,
    513; ctFlags 0x8000, 256 entries), {… 0x1E … 0x9B} (129: 16-bit packType 3 cmpSize 5; 133–138: 32-bit packType 4
    cmpSize 8); every picture's walk consumes exactly its length. Screenshots: Odemia/Pnyx/Unicorn 0x98 8-bit 640×480
    ctFlags 0x8000; Catamarca 0x9A 16-bit packType 3; Land King Hall 0x8200 (payload 164,186 B) + 0x32/0x1F/0x07 ops.
12. **clut (p07, p19):** both 2,056 B, seed 0, flags 0, ctSize 255, values 0..255; differ at entries {0, 16, 252, 253};
    251 (data) / 250 (app) entries are not byte-replicated 16-bit values (e.g. entry 1 = (0, 0, 0xA800)); entries
    0xD0–0xEB (the 0xF005 cycle ranges) are ordinary colours.
13. **TxSt / fonts (p15, p16, p18):** as Bank corrections 7–8. TMPL 128 field order differs between the two files (app:
    Reserved, Extend, Condense, Shadow, Outline, Underline, Italic, Bold; data: Bold, Italic, Underline, Outline, Shadow,
    Condense, Extend, Reserve) — the decoder stores the raw style byte and lets Phase 1 read it as a QuickDraw `Style`
    (0x01 bold); the 0x80 bit on "Stats" is unexplained.
14. **NFNT (p18):** 25740: strike 476 B at 26, locTable at 502 (101 u16, monotonic, last 257 ≤ rowWords·16 = 272),
    owTable at 704 → would end at 906 but the resource is 904 B (100 entries); 72 of 100 entries 0xFFFF; glyphs for 27
    chars (`A–K M N P–Z b` + two control codes). 25746: strike 1,050 B, loc at 1,076, ow at 1,278 (100 of 101), 29 glyphs.
15. **asnd (p09):** as C6; raw-sample SHA-256 of 0x9101 begins `015dfac04505ead3`.
16. **QTMA (p10, p10b):** as C7. First 24 header words of 0x9000: `f0000003 00000001 c0080003 | f0000006 0 0 84280000 0
    c00b0006 | f0000017 02ef0001 00010000 'ss  ' "Best Synthesizer" … 'GS Instrument' …`; first tune words `60020000
    400a01c2 40075100 410a01ba 41076f00 420a0146 42076200 430a0178 440a01f2 44075000 45076d00 460a0100`; last four
    `460a0100 60000000 c0050018 60000000` (the `c0050018` is the tail of a 24-word TuneDifference event whose payload
    contains `60000000` words — the walker skips payloads by length, so the count of interior end markers is event-level).
    Interior end markers carry value 1 (`0x60000001`); the 0x9000 ones sit at tune-word indices 255, 515, 790, 1076,
    1363, 1640, 1846 and the final value-0 marker at 1871.
17. **Scripts (p05, p17):** `scriptdis.py --out … --census …` → 958 listings in 0.32 s; census byte-identical to the
    committed `script-census.md` (modulo the "Generated" line); per-listing SHA-256 list `p05_listing_hashes.txt`;
    canonical derivation `p17_canon.py` → 22,166 lines, histogram as C9, `p17_canon.sha256` (the planner's run of the
    recipe; the committed golden is regenerated by the implementer with `script_canon.py` and must agree line for line).
18. **Font calls (p16):** import names resolved from the PEF loader relocations (563 imports, 10 libraries; 561 glue stubs,
    0 unresolved — `p16_glue_names.txt`); `TextFont` glue 0x100C35A0, `TextSize` 0x100C35B8, `TextFace` 0x100C35D0,
    `GetFNum` 0x100C50B8, `TextMode` 0x100C4908, `AADrawText` 0x10075B58 (tb). Literal-argument sites: TextFont
    0 @1000204C, 100024EC · 1 @100024BC, 10002578 · 3 @10002514, 1000253C, 100357F0; TextSize 0 @10002058, 100024C8,
    100024F8, 10002584 · 10 @10002520, 10002548 · 9 @100357FC (the `T7LabelWidget` fonts −1/−2/−3 of ui-toolkit §1 and the
    portrait popup "font 3 size 9" of ui-play §10 item 7).
19. **AI text (p20):** the 8 `.ai` files and `AI Scripting Document` are CR-terminated ASCII (CR counts 17, 20, 19, 13,
    29, 12, 19, 30; 301), no LF, no bytes ≥ 0x80.
20. **HectorKit state at plan time:** main `d38a541` (K1-Ferazel `21b8632` + review fixes `916bb4c`; D12; FLOOR 313);
    `PICT+Pixels.swift` refuses 0x0090/0x0091/0x0099/0x009B ("bitsOpcode") and 16-bit DirectBits ("directPack"); `PICT+Masks.swift`
    already parses 0x0099 regions for `decodeMasked`; `SndSound` accepts format 1 / `bufferCmd` / 8-bit;
    `ResourceReader.read(fileAt:)` reads data-fork maps; `HectorTestSupport` locators `HectorData+{BTX,Deimos,Ferazel}.swift`
    are the shape for `HectorData+Cythera.swift`. Classics: `Deimos/Core/Package.swift` is the manifest shape;
    `.gitignore` is already `/Resources/*` + `!/Resources/Deimos/`; `.gitattributes` has `Resources/Deimos/** binary`;
    DECISIONS last entry D27; `Ferazel/` is not on main (its plan is unexecuted).
