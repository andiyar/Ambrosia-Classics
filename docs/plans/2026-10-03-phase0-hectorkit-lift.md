# Plan — Phase 0: HectorKit lift from EV + Aki data census — 2026-10-03

> Status: LOCKED (Ben: "just do the executor here", 2026-10-03) | EXECUTING
> **For agentic workers:** execute task-by-task with superpowers:subagent-driven-development (or
> superpowers:executing-plans). Steps use checkbox (`- [ ]`) syntax. Every number below that a step
> "expects" came from tool output on this machine on 2026-10-03; if reality differs, STOP and report —
> never edit an expectation to match.

**Goal:** Create HectorKit (`HectorResources`, `HectorGraphics`, `HectorAudio`) as a byte-faithful lift of
EV's Foundation-only format code + its opcode-level tests, green at a recorded zero-skip floor; teach
`HectorGraphics` Aki's banded QuickTime-JPEG PICTs; then census every Aki 1.1.0 PICT and every Aki 1.2.0
PNG / both versions' AIFF+MP3 through the kit from a new `Aki/Core` package, and tag HectorKit `v0.1.0`.

**Architecture:** HectorKit = one SwiftPM package (tools 6.0, macOS 15, Swift 6 mode, zero package
dependencies) with three library products and one test-only internal target (`HectorTestSupport`).
Ambrosia-Classics gains `Aki/Core` (SwiftPM: library `AkiCore`, executable `aki-census`, tests) that
depends on HectorKit by local path. Game data is never committed: tests find it through env vars
(HectorKit) or git-ignored symlinks (Classics).

**Tech stack:** Swift 6.4 / Xcode 27.0 beta (`swift --version` → `Apple Swift version 6.4`), SwiftPM,
XCTest, Foundation, CoreGraphics, ImageIO, AVFoundation (Classics only).

**Spec:** `docs/design-2026-10-03-hectorkit-and-classics.md` (whole; §2 module table, §5 verification).
**Repos:**
- `HK=/Users/andiyar/Developer/HectorKit` — work **directly on `main`**, push after every green task.
- `WT=/Users/andiyar/Developer/Ambrosia-Classics/.claude/worktrees/dazzling-chebyshev-e403ce` — branch
  `claude/dazzling-chebyshev-e403ce`; commit here, **do not push to main** (the orchestrator merges).
- `EV=/Users/andiyar/Developer/Ambrosia/engine/EVCore` — **read-only** (pinned at `e23122f408555d2961f30006f43a9555ac04244e`).

Shell state does not persist between tool calls: every command block below re-declares the variables it uses.

---

## Verification model (read first)

How "done" is proven for Phase 0 (design §5, made literal):

**Machine-verifiable — the executor closes these alone:**

| # | gate | expected (exact) |
|---|---|---|
| G1 | HectorKit whole suite, real data wired, zero skips, at the final floor | last line `PASS: zero skips, zero failures, executed 112 == floor 112` |
| G2 | Aki 1.1.0 PICT census in the kit: 124 resources / 82 PICT / 0 `snd ` / 11 raw + 71 QuickTime, per-id raw sizes, band histogram 1×45 2×5 4×20 6×1 | `Executed 3 tests, with 0 failures (0 unexpected) in …` (the Graphics bundle's line; the other bundles print `Executed 0 tests`, filtered out) |
| G3 | EV-data oracle for the lifted code: resource counts 1034 / 840 / 1728 / 1018 / 1543, PICT 8500/6000/5000/10000/5027, DITL+DLOG 1000/1013, snd 128/129/130 | inside G1: `0` `Test Case … skipped` lines in `/tmp/hectorkit-test.log` |
| G4 | Classics census tests: 82 PICT → frame (11/71); 50 PNG → declared sizes; 14 + 15 audio files open at 44.1 kHz with per-file channel counts; 5 composites within mean \|ΔRGB\| < 6 of their 1.2.0 PNG | `6` executed and `0` failed-or-skipped `Test Case` lines |
| G5 | Census tool totals (Task 7 Step 7.8) | stdout ends `- PICT: 82 (raw 11, quicktime 71, failed 0)` / `- PNG: 50 (failed 0)` / `- Audio: 1.1.0 14 of 14 opened, 1.2.0 15 of 15 opened` / `- Failures: 0`; exit 0 |
| G6 | Lift fidelity: only module-prefix lines differ from EV | exactly the `diff` output printed in Tasks 1–3 (and Task 5 Step 5.7 for `PICT.swift`) |
| G7 | EV repo untouched | `EV untouched` |
| G8 | HectorKit tagged on origin | one line ending `refs/tags/v0.1.0` |

The gate commands (each is also a task step):

```sh
# G1 + G3
/Users/andiyar/Developer/HectorKit/tools/check-zero-skip.sh 2>&1 | tail -n 1
grep -cE "^Test Case '.*' skipped \(" /tmp/hectorkit-test.log                      # → 0
# G2
cd /Users/andiyar/Developer/HectorKit && HECTORKIT_DATA_AKI11="/Users/andiyar/Developer/Ambrosia/Aki/Aki - Mahjong Solitaire/Aki - Mahjong Solitaire.app/Contents/Resources" \
  swift test --filter AkiPICTCensusTests 2>&1 | grep -E 'Executed [0-9]+ tests?, with' | grep -v 'Executed 0 tests' | tail -n 1
# G4
cd /Users/andiyar/Developer/Ambrosia-Classics/.claude/worktrees/dazzling-chebyshev-e403ce/Aki/Core && swift test > /tmp/aki-g4.log 2>&1
grep -cE "^Test Case '.*' (passed|failed|skipped) \(" /tmp/aki-g4.log; grep -cE "^Test Case '.*' (failed|skipped) \(" /tmp/aki-g4.log
# G7
git -C /Users/andiyar/Developer/Ambrosia rev-parse HEAD | diff - /tmp/phase0-ev-head.txt && \
  git -C /Users/andiyar/Developer/Ambrosia status --porcelain | diff - /tmp/phase0-ev-porcelain.txt && echo "EV untouched"
# G8
git -C /Users/andiyar/Developer/HectorKit ls-remote --tags origin v0.1.0
```

Expected HectorKit test totals as the plan advances — counted as `Test Case '…' passed|failed|skipped` lines,
because `swift test` prints one `'All tests'` block per test bundle and no package total (Research note 18);
each is a STOP-if-different number:
Task 1 → **39**, Task 2 → **79**, Task 3 → **89** (= first floor), Task 5 → **109**, Task 6 → **112** (final floor).
Per-bundle `'All tests'` lines at the end: Resources **39**, Graphics **63** (40 lifted + 20 Task 5 + 3 Task 6), Audio **10**.
Per file: Resources 39 = BRGRBackend 7 + ByteReader 4 + ClassicBackend 4 + ClassicResourceMapWriter 11 +
IntegrationData 5 + ResourceCollection 2 + ResourceReader 6; Graphics lift 40 = PICTTests 26 (21 + 5
RealPICTCensus) + DitlTests 14; Audio 10; Task 5 adds CodecImage 4 + PICTQuickTime 16; Task 6 adds 3.

**Honesty gates (Ben only):** none closes Phase 0 — there is nothing to look at or play yet. Phrase every
completion claim as "machine gates G1–G8 green", never "Aki's art looks right". The first eyes-on gate is
Phase 1 ("that is Aki's map screen"; the map is PICT 164 ↔ 1.2.0 `map.png`).
What the machine does NOT prove here: pixel-exact colour of the JPEG composites (checked only to mean
|ΔRGB| < 6 against 1.2.0's PNGs, which are themselves re-encodes), audio *playback* (files only open), and
anything about game logic.

**Known deltas to disclose up front (so none is mistaken for a bug):**
1. Aki 1.1.0 has **71** QuickTime-JPEG PICTs + **11** raw — the design says 70 + 12 (§4).
2. Aki 1.1.0 has **0** `'snd '` resources — the design §5 "every snd opens" gate is vacuous for Aki; the
   `snd` decoder's oracle stays EV's Override Sounds (snd 128/129/130).
3. Every Aki QuickTime PICT is **banded** (1/2/4/6 JPEG strips + a 1-bit placeholder after each); the lifted
   `compressedQuickTimePayload` threw on all 71 and saw only band 1 — fixed and extended in Task 5 (HectorKit D2).
4. PICT 135 (2358×68 `plate`) is 32-bit **cmpCount 4** (ARGB) — not cmpCount 3 as the Phase-0 brief's B3
   said (census3.out line 34: `direct32 pack4 cmp4`). The lifted decoder's cmpCount-4 path (PICT.swift:226-254)
   handles it, so its alpha plane is REAL and lands in the RGBA's A channel — a fact Phase 1 must composite with.
5. EV's own QuickTime ship pics 5027/5030 are a *different* QuickTime shape (a 0x0032 paint op before the
   band, a pen/text-state + LongText "decompressor required" fallback after it — `0007 PnSize · 0003 · 0004 ·
   000D · 0010 · 0028`): the banded walk skips-and-records the 0x0032, reads the band, and refuses the
   fallback at **0x0007** (pinned by a test); they keep working through the lifted `compressedQuickTimePayload`.
9. Rect-paint ops inside a banded QuickTime PICT are skipped and **recorded** (`droppedPaintOps`), exactly
   as `PICT.init` does (orchestrator ruling 2026-10-03; Aki's 71 carry none).
6. `swift build`/`swift test` print one Swift 6 concurrency **warning** on `ContainerBackend.swift`'s
   `static let backends` — lifted as-is (rename-only rule); not an error, not to be fixed here.
7. Run without the env vars, HectorKit's data-gated tests **skip** (by design, message names the variable).
   Only a `tools/check-zero-skip.sh` PASS counts as green.
8. Aki 1.2.0 audio differs from 1.1.0: `tilehit.aiff` → `tilehit.mp3`, new `tick.aiff` (14 vs 15 files).

---

## Non-negotiable invariants

These override any task step if they ever conflict.

1. **The EV repo is untouched** (R8). Read and `cp` from `$EV` only — never `git` write commands, never
   `swift build`/`swift test` with `$EV` as the package, never an editor on its files. G7 proves it.
2. **Lifted files change by module prefix only** (D1). The complete list of allowed non-prefix deviations:
   (a) `TestSupport.swift` → `HectorTestSupport/Fixtures.swift` (public + inits, `repoRoot` removed);
   (b) `IntegrationDataTests.swift`, `PICTTests.swift` (`pictFork` → `novaFork`), `SndSoundTests.swift`
   (`overrideRawFork` → `novaFork`) and `DitlTests.swift` (assembled subset) re-pointed to env vars;
   (c) `PICT.swift` in Task 5: exactly three hunks (two new `DecodeError` cases, `Cursor` private→internal,
   0x00A0/0x00A1 in `compressedQuickTimePayload`). Doc comments that mention EV, pilots, D-numbers stay verbatim.
3. **Never `git add -A` / `git add .`** — add the explicit paths each commit step lists; afterwards check
   there are **no modified tracked files**: `git status --porcelain | grep -v '^??'` prints nothing. (Untracked
   files are tolerated — the worktree carries the untracked `docs/plans/` until the orchestrator commits it.)
4. **HectorKit commits go to `main` and are pushed** after each green task; **Classics commits stay on
   `claude/dazzling-chebyshev-e403ce`** (no push to main, no merge). Every commit in BOTH repos ends with
   exactly the trailer the orchestrator fixed (R6, re-ruled 2026-10-03), whichever model implements, and no
   other trailer: `Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>`.
5. **No copyrighted data is ever committed.** Originals stay in `~/Developer/Ambrosia/…`; HectorKit reaches
   them through env vars, Classics through the git-ignored `Resources/Aki/*.app` symlinks.
6. **A skip is a failure.** No task is "green" without its stated count *and* zero `^Test Case '…'
   (failed|skipped)` lines; HectorKit's final word is `tools/check-zero-skip.sh`'s PASS line. Never
   `grep -c skipped` bare — the lifted `[HectorResources] skipped A Corrupt.rez` log line matches it.
7. **`PICT.init` keeps throwing `unsupportedOpcode(0x8200)`** on QuickTime PICTs (EV relies on it;
   `testCompressedQuickTimeInitStillThrowsUnsupported` + `testInitStillThrowsUnsupported8200OnBandedStream`).
8. **STOP on any unexpected number** (test totals, 124/82/71/11/0, 50, 14/15, diff output, tool totals) and
   report it with the command output — do not adjust code or expectations to make them agree.
9. ⚠️ **LANDMINE — symlinked start dirs enumerate as empty.** `FileManager.enumerator(at:)` silently yields
   zero entries when its start URL is a symlink to a directory (EV `TestSupport.swift:84-91`). Every locator
   here resolves symlinks first (`HectorData.directory`, `findFile`, the Classics `akiResources`). Keep it so.
10. ⚠️ **LANDMINE — SwiftPM rejects a declared target with no sources.** `Package.swift` grows task by task
    exactly as shown (Tasks 1/2/3 for HectorKit; 7a/7b for `Aki/Core`). Do not pre-declare targets.
11. ⚠️ **LANDMINE — `swift run` mixes build progress into stdout.** The census document is produced by
    building first and executing the binary from `--show-bin-path` (Task 7 Step 7.8), never `swift run`.
12. ⚠️ **LANDMINE — `cd` into the wrong checkout.** HectorKit commands use `git -C "$HK"`; Classics commands
    use `git -C "$WT"`. Never run a git WRITE command (add/commit/checkout/reset/stash/push) in
    `/Users/andiyar/Developer/Ambrosia-Classics` (main checkout) — Task 0's read-only `status` is the only git
    there — and never touch the sibling worktree `focused-darwin-329781` (another lane may be running there).
13. **Orchestrator ruling 2026-10-03 — raster ops in the banded walk are REFUSED.** `quickTimeBands` throws
    `unsupportedOpcode` on PixMap/DirectBits ops (0x0098/0x0090 with rowBytes bit 15 set, 0x009A, …); only the
    1-bit placeholder BitMap directly after a band is skipped. Rect-paint ops are skipped and recorded (Known delta 9).
14. ⚠️ **LANDMINE — `swift test` has no package-wide total.** Count `^Test Case '…' (passed|failed|skipped) (`
    lines for whole-suite runs; for a filtered run take the non-zero `Executed` line (Research note 18).
15. Never "fix" lifted code's behaviour or warnings (e.g. the `backends` concurrency warning, EV-semantics
    arithmetic in `SndSound.playbackDurationFrames` / `loadSoundsTicks`) — carried as-is (D1).

---

## Research notes the executor must know

Each verified 2026-10-03 against the real source/data (tool output this session).

1. **EV pin.** `git -C ~/Developer/Ambrosia rev-parse HEAD` = `e23122f408555d2961f30006f43a9555ac04244e`;
   `git diff --quiet e23122f -- <every lift path>` is clean. `git status --porcelain` there shows one untracked
   file (`?? scratchpad_swt.txt`) — not ours; snapshot it in Task 0, compare in Task 8.
2. **EV package** (`$EV/Package.swift`): tools 6.0, `.macOS(.v15)`, Swift 6 mode. The lifted sources import
   Foundation only, except `Ditl.swift` (+ CoreGraphics). `SndSound.swift` uses nothing else from EVCore.
3. **Lifted source line counts:** BRGRContainer 80, ByteReader 62, ClassicResourceMap 173, ContainerBackend 106,
   MacRoman 21, Resource 37 (= 479); PICT 389; Ditl 122; SndSound 221.
4. **The only module-prefix token in lifted sources** is the `[EVResources]` stderr tag, 4 sites in
   `ContainerBackend.swift` (lines 51, 68, 76, 102). All other "EV" mentions are in comments (provenance).
5. **Public API the plan builds on (quoted from EV):** `public enum ResourceReader { public static func
   read(fileAt url: URL) throws -> ResourceCollection?; public static func read(folderAt url: URL, onProgress:
   ((Int, Int) -> Void)? = nil) throws -> ResourceCollection }` (ContainerBackend.swift:17-40);
   `public struct ResourceCollection { types(), resources(of:), resource(type:id:), counts() -> [(type: String,
   count: Int)], count }`; `public struct Resource: Equatable { type: String; id: Int16; name: String?; data: Data }`;
   `public struct PICT: Sendable { width, height, rgba: Data, droppedPaintOps: [Int]; public enum DecodeError:
   Error, Equatable { case notV2, truncated, unsupportedOpcode(Int), badPackBits, unsupportedDepth(Int) };
   public init(data: Data) throws; public static func compressedQuickTimePayload(data: Data) throws ->
   (codec: String, width: Int, height: Int, payload: Data) }`; `public enum Ditl { decode(_:) -> [Item]?,
   rects, boundingBox, dlogBounds, windowSize(dlogData:items:background:fallback:) }`;
   `public struct SndSound: Equatable, Sendable { init?(data:), format, sampleRateHz, numChannels,
   baseFrequency, payload, frameCount, durationTicks, headerSampleCount, loadSoundsTicks,
   static playbackDurationFrames(bufferFrames:sampleRateHz:rate:fps:), static ima4EffectivePacketCount(...) }`.
6. **`PICT`'s cursor is `private struct Cursor`** (PICT.swift:25) — invisible to a second file, hence the
   one-line visibility change in Task 5. `PICT` declares `init(data:)` in its body, which suppresses the
   synthesised memberwise init, hence the internal `init(width:height:rgba:droppedPaintOps:)` in the extension
   (allowed: same module).
7. **`compressedQuickTimePayload`'s walk** (PICT.swift:349-363) accepts only 0x0011/0x0C00/0x0001/0x001E/
   0x001F/0x0030–34 before 0x8200 → throws `unsupportedOpcode(0x00A1)` (= 161) on every Aki QuickTime PICT.
   `PICT.init` already skips 0x00A0 (2 B) and 0x00A1 (kind u16 + size u16 + size B) (PICT.swift:80-91).
8. **`decodePackBitsRect` throws `unsupportedDepth(1)` on a BitMap** (rowBytes bit 15 clear, PICT.swift:111);
   the banded walker therefore parses-and-skips the placeholder itself.
9. **The 0x8200 record** (PICT.swift:338-342 + census): opSize u32, then 68 fixed bytes (version 2, matrix
   36, matteSize 4, matteRect 8, mode 2, srcRect 8, accuracy 4, maskSize 4), matte+mask, ImageDescription
   (Aki: idSize 86, cType `jpeg`, depth 24, clutID −1), payload. Aki's opSize = 68 + 86 + dataSize rounded
   up to even (e.g. data 65715 → opSize 65870); next opcode = start-of-opSize-field + 4 + opSize. Aki matrices
   are exactly `[0x00010000,0,0, 0,0x00010000,0, tx<<16, ty<<16, 0x40000000]` (probe of PICTs 130/140/306).
10. **Aki placeholder** (probe, PICT 140): `0098 · 000a · 0000 0000 002c 0045 · 0000 0000 002c 0045 ·
    <band rect> · 0000` then 44 PackBits rows with u8 counts — 526 bytes including the 2-byte opcode
    (524 after it). The record's pad byte, when 68 + 86 + dataSize is odd, sits INSIDE opSize.
11. **Aki band payloads are JFIF** (`ffd8ffe0…`); `sips` (ImageIO) reads band 0 of PICT 140 as 800×160 and of
    PICT 130 as 392×320.
12. **Aki census** (`census3.out`, 376 lines): 11 raw DirectBitsRect (bounds = srcRect = dstRect = picFrame;
    16-bit packType 3: 128 467×468, 129 53×1104, 131 39×2100, 133 132×144, 134 416×480, 168 416×480,
    314 240×150; 32-bit packType 4: 135 2358×68 **cmpCount 4**, 5591 128×4, 8715 2×128, 23098 14×128 cmpCount 3)
    — corrects the brief's B3 ("4 × … cmpCount 3"). PICT 135's leading plane is a real alpha plane, decoded by
    the lifted cmpCount-4 path (PICT.swift:226-254) into the RGBA's A channel: a Phase-1 compositing fact;
    71 QuickTime with band counts 1×45, 2×5, 4×20, 6×1 (Counter line 376). PICT 140: bands 800×160 at ty
    0/160/320 + 800×120 at 480; 130 (392×1727): 5×320 + 127; 132 (237×2172): 3×544 + 540; 306: 1×181.
13. **Aki 1.1.0 `.rsrc`** is a DATA-fork classic map (no `..namedfork/rsrc`): header dataOff 256, mapOff
    7922960, dataLen 7922704, mapLen 2116, file 7925076 B; types CHNK 1, `STR ` 4, PICT 82, pnot 1, icns 1,
    8BIM 33, TEXT 1, ANPA 1 = 124; 0 `snd `. `ResourceReader.read(fileAt:)` falls back to the data fork.
14. **EV ship PICT 5027** (Override Ships, probe): `0011 · 0c00 · 001e · 0001 · 0032 · 001f · 8200` (opSize
    30360 = 68 + mask 10 + idSize 102 + data 30180, codec `tiff`), then 0x0007/0x0003/0x0004/0x000D/0x0010/
    0x0028… (pen/text state — 0x0007 PnSize, 0x0003 TxFont, 0x0004 TxFace, 0x000D TxSize, 0x0010 TxRatio —
    then 0x0028 LongText: "QuickTime™ and a TIFF (Uncompressed) decompressor are needed…"). The banded walk
    therefore records the 0x0032, reads the band, and throws `unsupportedOpcode(0x0007)` (= 7) on the fallback.
15. **Aki 1.2.0 PNGs** (sips): 17 × `background{1..17}` 800×600, `buyaki` 800×600, `map` 800×600,
    17 × `preview{1..17}` 237×181, `previews` 237×2172, `proverbs` 392×1727, `tile_pictures` 39×2100,
    `tiles` 53×1104, `misc` 467×468, `nopairs` 416×480, `pause` 416×480, `notavail` 240×150, `paper` 420×338,
    `welcome` 523×338, `guide` 440×503, `layer_buttons` 224×260, `arrow` 132×144, `plate` 2358×68 = 50. All are
    palettised, alpha 255 everywhere, no ICC/gAMA/sRGB chunk (PIL).
16. **Cross-version oracle** (PIL composite of the 1.1.0 bands vs 1.2.0 PNG, mean |ΔRGB| on 0–255; ImageIO via
    `sips` gives the same to 0.01; the kit's own ImageIO path prints 1.77 for 140): 140↔`background7` 1.78, 130↔`proverbs` 2.53, 132↔`previews` 4.98,
    164↔`map` 3.02, 315↔`paper` 0.04. Swapping the first two bands: 140 → 30.04, 130 → 10.48. Threshold 6.0.
17. **Audio (afinfo, all 44100 Hz):** 1.1.0 — ima4 AIFF: GameOver 2 ch, LevelComplete 2, LevelStart 2,
    Preview 1, Reshuffle 2, TileMatch 1, cancel 1, chime 1, tilehit 2, unclick 2; MP3: Aki Theme 1/2/3 2 ch,
    tick 1. 1.2.0 — same AIFF set minus `tilehit.aiff` plus `tick.aiff` (1 ch); MP3 adds `tilehit.mp3` (2 ch).
18. **XCTest output on this toolchain** (corrects brief B5): `swift test` runs each test target as its own
    `.xctest` bundle and prints one `Test Suite 'All tests'` block per bundle; **there is no package-wide
    total** — count `Test Case '…' (passed|failed|skipped)` lines. Per-test lines start at column 0:
    `Test Case '-[HectorResourcesTests.ByteReaderTests testEndianAndWidths]' passed (0.001 seconds).` Summary
    lines: `Executed N tests, with 0 failures (0 unexpected) in …`, with skips `Executed N tests, with M tests
    skipped and K failures (…)`; a test that THROWS counts as `(1 unexpected)`. A filtered run still prints
    every bundle's block (`Executed 0 tests` for bundles with no match). `swift test` mixes stdout/stderr →
    always `2>&1`. Idioms used below:
    - whole suite, executed: `grep -cE "^Test Case '.*' (passed|failed|skipped) \(" LOG`
    - whole suite, bad: `grep -cE "^Test Case '.*' (failed|skipped) \(" LOG` → `0`
    - filtered run: `grep -E 'Executed [0-9]+ tests?, with' LOG | grep -v 'Executed 0 tests' | tail -n 1`
    Never `grep -c skipped` bare: the lifted `[HectorResources] skipped A Corrupt.rez: …` stderr line (from
    `ResourceReaderTests`' synthetic corrupt file) and compiler diagnostic context both contain the word.
19. **`/usr/bin/DeRez` exists** → `ClassicBackendTests.testSyntheticBlobMatchesDeRez` runs (not a skip).
20. **Swift facts used:** a public struct's memberwise init is internal (→ explicit `public init` on the
    fixture structs); a local function shadows an imported module-level one, but `SndSoundTests` defines
    local `be16`/`be32` while HectorTestSupport exports public `be16`/`be32`, so it imports only what it
    needs: `import func HectorTestSupport.novaFork` (scoped import — zero ambiguity risk); an executable
    target whose entry file is not `main.swift` uses `@main` (`AkiCensus.swift`); a hyphenated executable
    target `aki-census` gets module name `aki_census` (irrelevant here — nothing imports it).
21. **`HectorTestSupport` imports XCTest from a regular (non-test) target — verified.** The plan reviewer
    built a full replica of Tasks 1–3/5–7 and a three-target toy: `swift build` is clean (one known warning),
    and `swift build -c release --product <lib>` does not build the XCTest-importing support target. Generic
    guard only: an unexpected `no such module 'XCTest'` → STOP (target layout is ruling R1).
22. **All new Swift in this plan was type-checked on this machine** (`swiftc -typecheck` + `-emit-sil -wmo`,
    Swift 6 mode, single-module approximation with the lifted sources) before the plan was written, and again
    after the review fix pass: zero errors. The Fable plan review then built and RAN a full replica of Tasks
    1–3 and 5–7 (scratch `HK`/`WT`): every expected diff matched, 112 HectorKit tests (bundles 39 / 63 / 10) and
    6 Classics tests passed, and the census tool printed the four expected totals — the measurement and
    paint-op fixes in this revision come from that run.
23. **Paths.** Main checkout's `.git/info/exclude` contains `.claude/worktrees/` (so the HectorKit symlink is
    invisible to git); Classics `.gitignore` line 2 is `/Resources/` and it ignores `.build/` and `.swiftpm/`;
    HectorKit `.gitignore` ignores `.build/`, `.swiftpm/`, `Fixtures/private/`.

---

## Scope

**Does (done-when):**
- [ ] `~/Developer/HectorKit` has `Package.swift` (3 library products, zero deps), `Sources/{HectorResources,
  HectorGraphics,HectorAudio,HectorTestSupport}`, `Tests/{HectorResourcesTests,HectorGraphicsTests,HectorAudioTests}`,
  `tools/check-zero-skip.sh` (FLOOR=112), `docs/STATE.md`, `docs/DECISIONS.md` (D1–D3); G1, G2, G3, G6 green.
- [ ] HectorGraphics decodes banded QuickTime PICTs (`PICT.quickTimeBands`, `PICT.decodeQuickTime`,
  `CodecImage.decode`), and `compressedQuickTimePayload` reaches all 71 Aki QuickTime PICTs.
- [ ] HectorKit is tagged `v0.1.0` on origin (G8).
- [ ] Ambrosia-Classics (worktree branch) has `Aki/Core` (library `AkiCore` = `AkiBundle`, executable
  `aki-census`, `AkiCoreTests`), `docs/aki/data-census.md`, `docs/DECISIONS.md` (D1); G4, G5 green.
- [ ] EV untouched (G7).

**Untouched (load-bearing claim):** the EV repo (no file, no commit, no build); `docs/STATE.md`,
`docs/RESUME.md`, handoffs and the design doc in Ambrosia-Classics (**STATE/RESUME/handoff updates are the
orchestrator's job, not a plan task**); the sibling worktree `focused-darwin-329781`; `ghidra/`; no
`project.yml` / xcodegen / app target is created.

**Explicitly deferred (each to a named owner):**
- `HectorShell` (design §2) → Phase 1 plan.
- `project.yml`, `Aki/App`, first staged `.app`, boot smoke (design §3, §5) → Phase 1.
- Layout tables, rules, timer, `.aki` round-trip, stats tests (design §5 "Aki core") → Phase 2/3 plans.
- Ghidra on the Aki 1.2 Intel slice, the 1.1.0↔1.2.0 rule diff, `docs/aki/` RE bank (design §6 step 0) →
  the RE-bank lane (RESUME Trigger A), already its own session.
- Fetching the Aki add-ons / 36-level community pack (design §6 step 0, §4) → not in hand per the Phase-0
  brief; the orchestrator assigns it (Phase 3 needs it).
- EV's re-export shim (`EVResources` → `@_exported import HectorResources`) → EV's own PR after its lanes merge.
- Making the banded walk accept EV 5027/5030's pen/text-state + LongText fallback (refused at 0x0007 — their
  0x0032 paint op is already skipped-and-recorded) → only on a real need (they work today via
  `compressedQuickTimePayload`).
- HD-art packs, licence → as the design says (late / very end).

---

## Tasks

### Task 0 — Preflight: pin EV, verify both repos, create the local symlinks

**Files:** none tracked. Creates untracked symlinks:
`/Users/andiyar/Developer/Ambrosia-Classics/.claude/worktrees/HectorKit` → `/Users/andiyar/Developer/HectorKit`;
`Resources/Aki/1.1.0.app` and `Resources/Aki/1.2.0.app` in **both** the worktree and the main checkout
(git-ignored there; the main-checkout pair makes the repo-relative paths in docs work after the merge).

- [ ] **Step 0.1: Pin and snapshot EV.**

```sh
EVR=/Users/andiyar/Developer/Ambrosia
git -C "$EVR" rev-parse HEAD | tee /tmp/phase0-ev-head.txt
git -C "$EVR" diff --quiet e23122f408555d2961f30006f43a9555ac04244e -- \
  engine/EVCore/Sources/EVResources engine/EVCore/Sources/EVGraphics/PICT.swift \
  engine/EVCore/Sources/EVGraphics/Ditl.swift engine/EVCore/Sources/EVCore/SndSound.swift \
  engine/EVCore/Tests/EVResourcesTests engine/EVCore/Tests/EVGraphicsTests/PICTTests.swift \
  engine/EVCore/Tests/EVCoreTests/SndSoundTests.swift engine/EVCore/Tests/EVCoreTests/PortChromeTests.swift \
  && echo "EV lift sources clean at e23122f"
git -C "$EVR" status --porcelain | tee /tmp/phase0-ev-porcelain.txt
```

Expected: `e23122f408555d2961f30006f43a9555ac04244e`, then `EV lift sources clean at e23122f`, then the
porcelain snapshot (on 2026-10-03: `?? scratchpad_swt.txt`). If HEAD moved but the second line still prints,
proceed (the lift files are byte-identical to the pin). If the second line does not print, **STOP**.

- [ ] **Step 0.2: HectorKit is clean, on main, one commit.**

```sh
HK=/Users/andiyar/Developer/HectorKit
git -C "$HK" rev-parse --abbrev-ref HEAD; git -C "$HK" status --porcelain | grep -v '^??'; git -C "$HK" log --oneline; ls -A "$HK"
```

Expected: `main`; (no output — no modified tracked files); `8c614f1 HectorKit: door (CLAUDE.md) + gitignore — classic-Mac
format layer, lifted from the EV engine next`; `.git .gitignore CLAUDE.md`.

- [ ] **Step 0.3: The worktree is clean on its branch and has no `Aki/` yet.**

```sh
WT=/Users/andiyar/Developer/Ambrosia-Classics/.claude/worktrees/dazzling-chebyshev-e403ce
git -C "$WT" rev-parse --abbrev-ref HEAD; git -C "$WT" status --porcelain | grep -v '^??'; ls "$WT"
```

Expected: `claude/dazzling-chebyshev-e403ce`; (no output — no modified tracked files; the untracked
`docs/plans/` holding this plan is expected until the orchestrator commits it); `CLAUDE.md docs ghidra` (no `Aki`).

- [ ] **Step 0.4: HectorKit symlink so `../../../HectorKit` resolves from the worktree.**

```sh
LINK=/Users/andiyar/Developer/Ambrosia-Classics/.claude/worktrees/HectorKit
[ -L "$LINK" ] || ln -s /Users/andiyar/Developer/HectorKit "$LINK"
readlink "$LINK"; ls "$LINK/CLAUDE.md"
git -C /Users/andiyar/Developer/Ambrosia-Classics status --porcelain | grep -v '^??'
git -C /Users/andiyar/Developer/Ambrosia-Classics/.claude/worktrees/dazzling-chebyshev-e403ce status --porcelain | grep -v '^??'
```

Expected: `/Users/andiyar/Developer/HectorKit`; `/Users/andiyar/Developer/Ambrosia-Classics/.claude/worktrees/HectorKit/CLAUDE.md`;
then **no** output from either filtered porcelain (no modified tracked files).

- [ ] **Step 0.5: `Resources/Aki` symlinks (worktree + main checkout).**

```sh
A11="/Users/andiyar/Developer/Ambrosia/Aki/Aki - Mahjong Solitaire/Aki - Mahjong Solitaire.app"
A12="/Users/andiyar/Developer/Ambrosia/Resources/ambrosia-extracted/Action-Adventure/Aki - Mahjong Solitaire/Aki 1.2 UB/Aki.app"
WT=/Users/andiyar/Developer/Ambrosia-Classics/.claude/worktrees/dazzling-chebyshev-e403ce
for ROOT in "$WT" /Users/andiyar/Developer/Ambrosia-Classics; do
  mkdir -p "$ROOT/Resources/Aki"
  ln -sfn "$A11" "$ROOT/Resources/Aki/1.1.0.app"
  ln -sfn "$A12" "$ROOT/Resources/Aki/1.2.0.app"
done
ls -l "$WT/Resources/Aki/1.1.0.app/Contents/Resources/Aki - Mahjong Solitaire.rsrc" | awk '{print $5}'
ls "$WT/Resources/Aki/1.2.0.app/Contents/Resources" | grep -c '\.png$'
git -C "$WT" check-ignore -v Resources/Aki/1.1.0.app
git -C "$WT" status --porcelain | grep -v '^??'; git -C /Users/andiyar/Developer/Ambrosia-Classics status --porcelain | grep -v '^??'
```

Expected: `7925076`; `50`; `.gitignore:2:/Resources/	Resources/Aki/1.1.0.app`; no output from the two filtered
porcelains (the symlinks are ignored, not untracked).

- [ ] **Step 0.6: The env-var defaults and DeRez exist.**

```sh
ls "/Users/andiyar/Developer/Ambrosia/data/nova"
ls -d "/Users/andiyar/Developer/Ambrosia/reference" "/Users/andiyar/Developer/Ambrosia/Aki/Aki - Mahjong Solitaire/Aki - Mahjong Solitaire.app/Contents/Resources"
ls -l /usr/bin/DeRez | awk '{print $1}'
```

Expected: the nova listing includes `Override Data 1`, `Override Data 2`, `Override Graphics`, `Override Ships`,
`Override Sounds`, `Override Titles`; both directories print; DeRez is executable (`-rwxr-xr-x`).

- **Verify:** Steps 0.1–0.6 printed exactly their expected output.
- **Commit:** none (nothing tracked changed).

---

### Task 1 — `HectorResources` + `HectorTestSupport` + `HectorResourcesTests` (39 tests)

**Files:**
- Create (lifted, prefix-only): `$HK/Sources/HectorResources/{BRGRContainer,ByteReader,ClassicResourceMap,ContainerBackend,MacRoman,Resource}.swift`
- Create (lifted, prefix-only): `$HK/Tests/HectorResourcesTests/{BRGRBackendTests,ByteReaderTests,ClassicBackendTests,ClassicResourceMapWriterTests,ResourceCollectionTests,ResourceReaderTests}.swift`
- Create (adapted from EV TestSupport.swift): `$HK/Sources/HectorTestSupport/Fixtures.swift`
- Create (new): `$HK/Sources/HectorTestSupport/HectorData.swift`
- Create (adapted, env vars): `$HK/Tests/HectorResourcesTests/IntegrationDataTests.swift`
- Create: `$HK/Package.swift` (stage 1)

- [ ] **Step 1.1: Lift the six sources; rename the log tag.**

```sh
HK=/Users/andiyar/Developer/HectorKit; EV=/Users/andiyar/Developer/Ambrosia/engine/EVCore
mkdir -p "$HK/Sources/HectorResources" "$HK/Sources/HectorTestSupport" "$HK/Tests/HectorResourcesTests"
cp "$EV"/Sources/EVResources/{BRGRContainer,ByteReader,ClassicResourceMap,ContainerBackend,MacRoman,Resource}.swift "$HK/Sources/HectorResources/"
sed -i '' 's/\[EVResources\]/[HectorResources]/g' "$HK/Sources/HectorResources/ContainerBackend.swift"
for f in BRGRContainer ByteReader ClassicResourceMap ContainerBackend MacRoman Resource; do
  echo "== $f"; diff "$EV/Sources/EVResources/$f.swift" "$HK/Sources/HectorResources/$f.swift"; done
```

Expected output (exactly):

```
== BRGRContainer
== ByteReader
== ClassicResourceMap
== ContainerBackend
51c51
<                 "[EVResources] unreadable folder \(url.lastPathComponent): \(error)\n".utf8))
---
>                 "[HectorResources] unreadable folder \(url.lastPathComponent): \(error)\n".utf8))
68c68
<                     "[EVResources] skipped \(file.lastPathComponent): \(error)\n".utf8))
---
>                     "[HectorResources] skipped \(file.lastPathComponent): \(error)\n".utf8))
76c76
<                             "[EVResources] duplicate \(type) #\(res.id) in \(file.lastPathComponent) — last-wins\n".utf8))
---
>                             "[HectorResources] duplicate \(type) #\(res.id) in \(file.lastPathComponent) — last-wins\n".utf8))
102c102
<                 "[EVResources] unreadable file \(url.lastPathComponent): \(error)\n".utf8))
---
>                 "[HectorResources] unreadable file \(url.lastPathComponent): \(error)\n".utf8))
== MacRoman
== Resource
```

- [ ] **Step 1.2: Lift the six prefix-only test files.** Three of them use the fixture builders, which now
  live in the `HectorTestSupport` module, so they gain `import HectorTestSupport` after their testable import.

```sh
HK=/Users/andiyar/Developer/HectorKit; EV=/Users/andiyar/Developer/Ambrosia/engine/EVCore
cp "$EV"/Tests/EVResourcesTests/{BRGRBackendTests,ByteReaderTests,ClassicBackendTests,ClassicResourceMapWriterTests,ResourceCollectionTests,ResourceReaderTests}.swift "$HK/Tests/HectorResourcesTests/"
sed -i '' 's/^@testable import EVResources$/@testable import HectorResources/' "$HK"/Tests/HectorResourcesTests/*.swift
perl -pi -e 's/^(\@testable import HectorResources)$/$1\nimport HectorTestSupport/' "$HK"/Tests/HectorResourcesTests/{BRGRBackendTests,ClassicBackendTests,ResourceReaderTests}.swift
for f in BRGRBackendTests ByteReaderTests ClassicBackendTests ClassicResourceMapWriterTests ResourceCollectionTests ResourceReaderTests; do
  echo "== $f"; diff "$EV/Tests/EVResourcesTests/$f.swift" "$HK/Tests/HectorResourcesTests/$f.swift"; done
```

Expected output (exactly):

```
== BRGRBackendTests
3c3,4
< @testable import EVResources
---
> @testable import HectorResources
> import HectorTestSupport
== ByteReaderTests
2c2
< @testable import EVResources
---
> @testable import HectorResources
== ClassicBackendTests
3c3,4
< @testable import EVResources
---
> @testable import HectorResources
> import HectorTestSupport
== ClassicResourceMapWriterTests
3c3
< @testable import EVResources
---
> @testable import HectorResources
== ResourceCollectionTests
2c2
< @testable import EVResources
---
> @testable import HectorResources
== ResourceReaderTests
3c3,4
< @testable import EVResources
---
> @testable import HectorResources
> import HectorTestSupport
```

- [ ] **Step 1.3: Write `$HK/Sources/HectorTestSupport/Fixtures.swift`** (EV's `TestSupport.swift` made a
  module: `public` everywhere, explicit public inits on the two fixture structs, `repoRoot()` removed):

```swift
import Foundation

// Shared synthetic-blob builders for every HectorKit test target. Lifted from EV's
// `Tests/EVResourcesTests/TestSupport.swift` (EV e23122f) with two mechanical changes only:
// every symbol is `public` (this is now its own module, HectorTestSupport), and the two fixture
// structs gained explicit public initialisers (a public struct's memberwise init is internal).
// EV's `repoRoot()` locator is gone on purpose — real data is found through env vars (HectorData,
// DECISIONS D3), never by walking up to a checkout.

// MARK: - Little byte-emitting helpers (big/little-endian) for building synthetic blobs.
public func be16(_ v: Int) -> [UInt8] { [UInt8((v >> 8) & 0xFF), UInt8(v & 0xFF)] }
public func be24(_ v: Int) -> [UInt8] { [UInt8((v >> 16) & 0xFF), UInt8((v >> 8) & 0xFF), UInt8(v & 0xFF)] }
public func be32(_ v: Int) -> [UInt8] { [UInt8((v >> 24) & 0xFF), UInt8((v >> 16) & 0xFF), UInt8((v >> 8) & 0xFF), UInt8(v & 0xFF)] }
public func le32(_ v: Int) -> [UInt8] { [UInt8(v & 0xFF), UInt8((v >> 8) & 0xFF), UInt8((v >> 16) & 0xFF), UInt8((v >> 24) & 0xFF)] }

public struct FixtureResource {
    public let id: Int16; public let name: String?; public let data: [UInt8]
    public init(id: Int16, name: String?, data: [UInt8]) { self.id = id; self.name = name; self.data = data }
}
public struct FixtureType {
    public let code: String; public let resources: [FixtureResource]   // code: 4 ASCII chars
    public init(code: String, resources: [FixtureResource]) { self.code = code; self.resources = resources }
}

/// MacRoman-encode a 4-char type code as raw bytes. Type codes are a fixed-width 4-byte OSType field
/// on disk, decoded by `ByteReader.macRoman` — NOT `String.utf8`, which is multi-byte for diacritics
/// (e.g. "shïp".utf8 is 5 bytes: "ï" = U+00EF = 0xC3 0xAF in UTF-8 vs. one MacRoman byte). Builders
/// must encode with the same charset the reader decodes with, or fixed-stride offsets misalign.
public func macRoman4(_ s: String) -> [UInt8] { Array(s.data(using: .macOSRoman) ?? Data(s.utf8)) }

// MARK: - Synthetic CLASSIC resource-map blob, built straight from the resfork.py layout.
public func makeClassicBlob(_ types: [FixtureType]) -> Data {
    var dataSection = [UInt8](); var dataOffsets = [[Int]]()
    for t in types {
        var offs = [Int]()
        for res in t.resources { offs.append(dataSection.count); dataSection += be32(res.data.count) + res.data }
        dataOffsets.append(offs)
    }
    var nameList = [UInt8](); var nameOffsets = [[Int?]]()
    for t in types {
        var offs = [Int?]()
        for res in t.resources {
            if let n = res.name { offs.append(nameList.count); let nb = Array(n.utf8); nameList += [UInt8(nb.count)] + nb }
            else { offs.append(nil) }
        }
        nameOffsets.append(offs)
    }
    let typeEntriesLen = 2 + types.count * 8
    var refLists = [UInt8](); var refOffOfType = [Int]()
    for (ti, t) in types.enumerated() {
        refOffOfType.append(typeEntriesLen + refLists.count)     // from type-list start
        for (ri, res) in t.resources.enumerated() {
            refLists += be16(Int(UInt16(bitPattern: res.id)))
            refLists += be16(nameOffsets[ti][ri] ?? 0xFFFF)
            refLists += [0]                                      // attrs
            refLists += be24(dataOffsets[ti][ri])                // data-relative offset
            refLists += [0, 0, 0, 0]                             // reserved handle
        }
    }
    var typeList = be16(types.count - 1)
    for (ti, t) in types.enumerated() {
        typeList += Array(t.code.utf8)
        typeList += be16(t.resources.count - 1)
        typeList += be16(refOffOfType[ti])
    }
    typeList += refLists
    let typeListOff = 28
    let nameListOff = typeListOff + typeList.count
    let map = [UInt8](repeating: 0, count: 24) + be16(typeListOff) + be16(nameListOff) + typeList + nameList
    // The resource DATA section begins at offset 256: the 16-byte header + 240 bytes reserved for the
    // system (112) and application (128), per Inside Macintosh. The real Resource Manager — and DeRez,
    // which powers the -useDF cross-check — rejects a fork whose data starts right after the header
    // with mapReadErr (-199); a data-fork `Rez` round-trip confirmed 256 is the accepted layout (a
    // map header copy is NOT required — dataOff is the deciding factor). Our own parser reads dataOff
    // from the header, so this offset is transparent to it; the padding exists only to satisfy DeRez.
    let dataOff = 256, mapOff = dataOff + dataSection.count
    var blob = be32(dataOff) + be32(mapOff) + be32(dataSection.count) + be32(map.count)
    blob += [UInt8](repeating: 0, count: dataOff - 16)   // reserved system + application area
    blob += dataSection + map
    return Data(blob)
}

/// Recursively find the first file named `name` under `dir` (for the git-ignored reference data).
///
/// `dir` resolves symlinks first: `FileManager.enumerator(at:)` silently yields ZERO entries when
/// its starting URL is itself a symlink to a directory (verified empirically — no error, no nil,
/// just an empty enumeration) — a Foundation trap, not a documented option. This repo's worktrees
/// symlink `data/`/`reference/` in (git-ignored), so an unresolved `dir` here would make every
/// data-gated test that searches `reference/` silently see "no files", indistinguishable from a
/// clean checkout with no data at all — the exact ambiguity XCTSkip is meant to represent honestly.
public func findFile(named name: String, under dir: URL) -> URL? {
    let resolved = dir.resolvingSymlinksInPath()
    guard let en = FileManager.default.enumerator(at: resolved, includingPropertiesForKeys: nil) else { return nil }
    for case let u as URL in en where u.lastPathComponent == name { return u }
    return nil
}

// MARK: - Synthetic BRGR .rez blob, built straight from the brgr.py / plugconvert.c layout.
public func makeBRGRBlob(_ types: [FixtureType]) -> Data {
    let flat: [(type: String, res: FixtureResource)] = types.flatMap { t in t.resources.map { (t.code, $0) } }
    let numResources = flat.count
    let numEntries = numResources + 1
    let mapName = Array("resource.map\u{0}".utf8)                 // 13 bytes
    let dataStart = 24 + numEntries * 12 + mapName.count

    var blobs = [UInt8](); var offs = [(Int, Int)]()
    for (_, res) in flat { offs.append((dataStart + blobs.count, res.data.count)); blobs += res.data }
    let mapStart = dataStart + blobs.count

    var map = be32(8) + be32(types.count)
    for t in types { map += macRoman4(t.code) + be32(0) + be32(t.resources.count) }
    for (i, (code, res)) in flat.enumerated() {
        map += be32(i + 1)                                        // index (1-based)
        map += macRoman4(code)
        map += be16(Int(UInt16(bitPattern: res.id)))
        var name = [UInt8](repeating: 0, count: 256)
        for (k, byte) in Array((res.name ?? "").utf8).prefix(255).enumerated() { name[k] = byte }
        map += name
    }

    var offsetTable = [UInt8]()
    for (o, s) in offs { offsetTable += le32(o) + le32(s) + le32(0) }
    offsetTable += le32(mapStart) + le32(map.count) + le32(0)     // last entry → the map

    let header2Length = 25 + numEntries * 12                      // == 12 + offsetTable + mapName offset math
    var blob = Array("BRGR".utf8) + le32(1) + le32(header2Length) // header1 (12 B)
    blob += le32(1) + le32(1) + le32(numEntries)                  // header2: unknown, firstIndex, numEntries
    blob += offsetTable + mapName + blobs + map
    return Data(blob)
}
```

Check it against EV:

```sh
diff /Users/andiyar/Developer/Ambrosia/engine/EVCore/Tests/EVResourcesTests/TestSupport.swift /Users/andiyar/Developer/HectorKit/Sources/HectorTestSupport/Fixtures.swift
```

Expected output (exactly):

```
2,3d1
< import XCTest
< @testable import EVResources
4a3,9
> // Shared synthetic-blob builders for every HectorKit test target. Lifted from EV's
> // `Tests/EVResourcesTests/TestSupport.swift` (EV e23122f) with two mechanical changes only:
> // every symbol is `public` (this is now its own module, HectorTestSupport), and the two fixture
> // structs gained explicit public initialisers (a public struct's memberwise init is internal).
> // EV's `repoRoot()` locator is gone on purpose — real data is found through env vars (HectorData,
> // DECISIONS D3), never by walking up to a checkout.
> 
6,9c11,14
< func be16(_ v: Int) -> [UInt8] { [UInt8((v >> 8) & 0xFF), UInt8(v & 0xFF)] }
< func be24(_ v: Int) -> [UInt8] { [UInt8((v >> 16) & 0xFF), UInt8((v >> 8) & 0xFF), UInt8(v & 0xFF)] }
< func be32(_ v: Int) -> [UInt8] { [UInt8((v >> 24) & 0xFF), UInt8((v >> 16) & 0xFF), UInt8((v >> 8) & 0xFF), UInt8(v & 0xFF)] }
< func le32(_ v: Int) -> [UInt8] { [UInt8(v & 0xFF), UInt8((v >> 8) & 0xFF), UInt8((v >> 16) & 0xFF), UInt8((v >> 24) & 0xFF)] }
---
> public func be16(_ v: Int) -> [UInt8] { [UInt8((v >> 8) & 0xFF), UInt8(v & 0xFF)] }
> public func be24(_ v: Int) -> [UInt8] { [UInt8((v >> 16) & 0xFF), UInt8((v >> 8) & 0xFF), UInt8(v & 0xFF)] }
> public func be32(_ v: Int) -> [UInt8] { [UInt8((v >> 24) & 0xFF), UInt8((v >> 16) & 0xFF), UInt8((v >> 8) & 0xFF), UInt8(v & 0xFF)] }
> public func le32(_ v: Int) -> [UInt8] { [UInt8(v & 0xFF), UInt8((v >> 8) & 0xFF), UInt8((v >> 16) & 0xFF), UInt8((v >> 24) & 0xFF)] }
11,12c16,23
< struct FixtureResource { let id: Int16; let name: String?; let data: [UInt8] }
< struct FixtureType { let code: String; let resources: [FixtureResource] }   // code: 4 ASCII chars
---
> public struct FixtureResource {
>     public let id: Int16; public let name: String?; public let data: [UInt8]
>     public init(id: Int16, name: String?, data: [UInt8]) { self.id = id; self.name = name; self.data = data }
> }
> public struct FixtureType {
>     public let code: String; public let resources: [FixtureResource]   // code: 4 ASCII chars
>     public init(code: String, resources: [FixtureResource]) { self.code = code; self.resources = resources }
> }
18c29
< func macRoman4(_ s: String) -> [UInt8] { Array(s.data(using: .macOSRoman) ?? Data(s.utf8)) }
---
> public func macRoman4(_ s: String) -> [UInt8] { Array(s.data(using: .macOSRoman) ?? Data(s.utf8)) }
21c32
< func makeClassicBlob(_ types: [FixtureType]) -> Data {
---
> public func makeClassicBlob(_ types: [FixtureType]) -> Data {
72,81d82
< // MARK: - Locators for the data-gated integration tests (all data is git-ignored).
< func repoRoot() -> URL? {
<     var dir = URL(fileURLWithPath: #filePath)
<     for _ in 0..<12 {
<         dir.deleteLastPathComponent()
<         if FileManager.default.fileExists(atPath: dir.appendingPathComponent("CLAUDE.md").path) { return dir }
<     }
<     return nil
< }
< 
90c91
< func findFile(named name: String, under dir: URL) -> URL? {
---
> public func findFile(named name: String, under dir: URL) -> URL? {
98c99
< func makeBRGRBlob(_ types: [FixtureType]) -> Data {
---
> public func makeBRGRBlob(_ types: [FixtureType]) -> Data {
```

- [ ] **Step 1.4: Write `$HK/Sources/HectorTestSupport/HectorData.swift`** (the env-var locator, D3):

```swift
import Foundation
import HectorResources
import XCTest

/// Real-data locator for HectorKit's data-gated tests (DECISIONS D3). Game data is copyrighted and
/// never lives in this repo: each test reads a directory named by an environment variable and
/// throws `XCTSkip` — whose message NAMES the variable — when it is unset or the file is absent.
/// `tools/check-zero-skip.sh` exports this machine's defaults and fails the run on any skip, so a
/// skip is always counted, never silent.
public enum HectorData {
    /// Directory holding EV Nova's Override resource-FORK files (`Override Data 1`, `Override Titles`, …).
    public static let novaVar = "HECTORKIT_DATA_NOVA"
    /// Directory searched RECURSIVELY for the reference `.ndat` / `.rez` files (`Nova Data 4.ndat`, …).
    public static let novaReferenceVar = "HECTORKIT_DATA_NOVA_REFERENCE"
    /// Aki - Mahjong Solitaire 1.1.0's `Contents/Resources` directory (holds the data-fork `.rsrc`).
    public static let aki11Var = "HECTORKIT_DATA_AKI11"

    /// The directory named by `variable`, symlinks resolved. XCTSkip when unset/empty or not a directory.
    public static func directory(_ variable: String) throws -> URL {
        guard let raw = ProcessInfo.processInfo.environment[variable], !raw.isEmpty else {
            throw XCTSkip("\(variable) is not set — real-data test skipped (tools/check-zero-skip.sh sets it)")
        }
        let url = URL(fileURLWithPath: raw).resolvingSymlinksInPath()
        var isDirectory: ObjCBool = false
        guard FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory),
              isDirectory.boolValue else {
            throw XCTSkip("\(variable)=\(raw) is not a directory")
        }
        return url
    }

    /// `fileName` directly inside the directory named by `variable`. XCTSkip when absent.
    public static func file(_ fileName: String, in variable: String) throws -> URL {
        let dir = try directory(variable)
        let url = dir.appendingPathComponent(fileName)
        guard FileManager.default.fileExists(atPath: url.path) else {
            throw XCTSkip("\(fileName) absent under \(variable)=\(dir.path)")
        }
        return url
    }

    /// The first file named `fileName` anywhere under the directory named by `variable` — EV's
    /// recursive `findFile` semantics (first enumerator hit wins). XCTSkip when not found.
    public static func find(_ fileName: String, under variable: String) throws -> URL {
        let dir = try directory(variable)
        guard let url = findFile(named: fileName, under: dir) else {
            throw XCTSkip("\(fileName) not found under \(variable)=\(dir.path)")
        }
        return url
    }
}

/// One EV Nova Override fork from `HECTORKIT_DATA_NOVA`, read through `ResourceReader` — the
/// env-var replacement for EV's `overrideRawFork(_:)` / `pictFork(_:)` (both walked up to a
/// checkout's `data/nova`). XCTSkip (naming the variable) when the directory or file is absent.
public func novaFork(_ name: String) throws -> ResourceCollection {
    let url = try HectorData.file(name, in: HectorData.novaVar)
    guard let collection = try ResourceReader.read(fileAt: url) else {
        throw XCTSkip("\(name) under \(HectorData.novaVar) is not a resource container")
    }
    return collection
}
```

- [ ] **Step 1.5: Write `$HK/Tests/HectorResourcesTests/IntegrationDataTests.swift`** (EV's five tests,
  every assertion unchanged, locators re-pointed to `HectorData`):

```swift
import XCTest
import Foundation
@testable import HectorResources
import HectorTestSupport

/// These are the real format-correctness oracle (spec Verification model). Each locates a git-ignored
/// data file and SKIPS (not fails) when absent, so the suite stays green on a machine with no data.
///
/// HectorKit: lifted from EV's `IntegrationDataTests` (EV e23122f) with the locators re-pointed from
/// `repoRoot()` + `data/nova` + `reference/` to the env vars of DECISIONS D3 — `HECTORKIT_DATA_NOVA`
/// (the Override forks) and `HECTORKIT_DATA_NOVA_REFERENCE` (searched recursively, EV's `findFile`
/// semantics). Every count and assertion is EV's, unchanged.
final class IntegrationDataTests: XCTestCase {

    // Classic Mac resource fork — DeRez-verified ground truth (STATE.md).
    func testClassicOverrideData2Counts() throws {
        let file = try HectorData.file("Override Data 2", in: HectorData.novaVar)
        let c = try XCTUnwrap(try ResourceReader.read(fileAt: file))
        XCTAssertEqual(c.count, 1034)
        XCTAssertEqual(c.types().count, 11)
        XCTAssertEqual(c.resources(of: "shïp").count, 48)   // anchored per-type from STATE/DeRez
        XCTAssertEqual(c.resources(of: "wëap").count, 36)
        XCTAssertEqual(c.resources(of: "oütf").count, 75)
    }

    // Classic in the DATA fork (EV Nova .ndat) — probe doc, DeRez-confirmed.
    func testClassicNovaData4CountsFromDataFork() throws {
        let file = try HectorData.find("Nova Data 4.ndat", under: HectorData.novaReferenceVar)
        let c = try XCTUnwrap(try ResourceReader.read(fileAt: file))
        XCTAssertEqual(c.count, 840)
        XCTAssertEqual(c.resources(of: "përs").count, 516)
        XCTAssertEqual(c.resources(of: "oütf").count, 242)
        XCTAssertEqual(c.resources(of: "wëap").count, 81)
        XCTAssertEqual(c.resources(of: "PICT").count, 1)
    }

    // BRGR .rez — recorded structural numbers (brgr finding). DeRez cannot read BRGR.
    func testBRGROverrideRezCounts() throws {
        let d1 = try HectorData.find("Override Data 1.rez", under: HectorData.novaReferenceVar)
        XCTAssertEqual(try ResourceReader.read(fileAt: d1)?.count, 1728)
        let d2 = try HectorData.find("Override Data 2.rez", under: HectorData.novaReferenceVar)
        XCTAssertEqual(try ResourceReader.read(fileAt: d2)?.count, 1018)
    }

    func testBRGREVClassicCounts() throws {
        let file = try HectorData.find("EV Data.rez", under: HectorData.novaReferenceVar)
        let c = try XCTUnwrap(try ResourceReader.read(fileAt: file))
        XCTAssertEqual(c.count, 1543)       // EV Classic, a different game on the same container
        XCTAssertEqual(c.types().count, 17)
    }

    // The whole-DIRECTORY read the app performs on a folder drop, pointed at the real Override
    // folder (Override Data 1 + 2 + graphics/ships/sounds/titles). Exercises read(folderAt:) on a
    // real multi-file directory. `HectorData.directory` resolves symlinks, so the enumerated file
    // URLs are real paths and `..namedfork/rsrc` resolves.
    func testReadFolderOnRealOverrideDirectory() throws {
        let folder = try HectorData.directory(HectorData.novaVar)

        let merged = try ResourceReader.read(folderAt: folder)

        // Per-type anchors unique to Override Data 2 (STATE/DeRez) — no other file in the folder
        // carries these types, so they survive the merge collision-free.
        XCTAssertEqual(merged.resources(of: "shïp").count, 48)
        XCTAssertEqual(merged.resources(of: "wëap").count, 36)
        XCTAssertEqual(merged.resources(of: "oütf").count, 75)
        XCTAssertEqual(merged.resources(of: "sÿst").count, 311)
        // Proof the merge reached beyond the Data files: Override Ships/Graphics contribute rlëD sprites.
        XCTAssertGreaterThan(merged.resources(of: "rlëD").count, 0)
        // Floor: Override Data 1 (1721) + Data 2 (1034) = 2755, plus the graphics/ships/sounds forks.
        XCTAssertGreaterThan(merged.count, 2755)
    }
}
```

- [ ] **Step 1.6: Write `$HK/Package.swift` (stage 1).**

```swift
// swift-tools-version: 6.0
import PackageDescription

// HectorKit — the classic-Mac format layer for Ambrosia game revivals. Zero package dependencies.
// Lifted from the EV engine (EVCore @ e23122f): docs/DECISIONS.md D1.
let package = Package(
    name: "HectorKit",
    platforms: [.macOS(.v15)],
    products: [
        .library(name: "HectorResources", targets: ["HectorResources"]),
    ],
    targets: [
        .target(name: "HectorResources"),
        // Test-only: the shared synthetic-blob builders + the env-var real-data locator (D3). Not a
        // product, so no client package can depend on it. It imports XCTest (XCTSkip).
        .target(name: "HectorTestSupport", dependencies: ["HectorResources"]),
        .testTarget(name: "HectorResourcesTests", dependencies: ["HectorResources", "HectorTestSupport"]),
    ]
)
```

- [ ] **Step 1.7: Build.**

```sh
cd /Users/andiyar/Developer/HectorKit && swift build 2>&1 | tail -n 3
```

Expected: ends with `Build complete!` (the one `backends` concurrency warning is expected — Known delta 6).

- [ ] **Step 1.8: Run WITHOUT data — the skip path must name its variable.**

```sh
cd /Users/andiyar/Developer/HectorKit && env -u HECTORKIT_DATA_NOVA -u HECTORKIT_DATA_NOVA_REFERENCE swift test > /tmp/hk-t1-nodata.log 2>&1
grep -cE "^Test Case '.*' (passed|failed|skipped) \(" /tmp/hk-t1-nodata.log; grep -cE "^Test Case '.*' skipped \\(" /tmp/hk-t1-nodata.log
grep -c "is not set — real-data test skipped" /tmp/hk-t1-nodata.log
```

Expected: `39`; `5` (the five `IntegrationDataTests`); and a count ≥ 5 (XCTest echoes each skip's message;
each names `HECTORKIT_DATA_NOVA` or `HECTORKIT_DATA_NOVA_REFERENCE`).

- [ ] **Step 1.9: Run WITH data — zero skips.**

```sh
cd /Users/andiyar/Developer/HectorKit && HECTORKIT_DATA_NOVA=/Users/andiyar/Developer/Ambrosia/data/nova \
  HECTORKIT_DATA_NOVA_REFERENCE=/Users/andiyar/Developer/Ambrosia/reference swift test > /tmp/hk-t1.log 2>&1
grep -cE "^Test Case '.*' (passed|failed|skipped) \(" /tmp/hk-t1.log; grep -cE "^Test Case '.*' (failed|skipped) \(" /tmp/hk-t1.log
```

Expected: `39` and `0`. (A bare `grep -c skipped` would print `1` here: the lifted `[HectorResources] skipped
A Corrupt.rez` stderr line from `ResourceReaderTests` — never use it.)

- [ ] **Step 1.10: No EV imports, no repo-walking locator survives.**

```sh
cd /Users/andiyar/Developer/HectorKit && grep -rnE '^(@testable )?import EV' Sources Tests; grep -rnE '^[^/]*(repoRoot\(|"data/nova)' Sources Tests; echo "gate done"
```

Expected: only `gate done`.

- **Verify:** Steps 1.1, 1.2, 1.3 diffs exact; 1.7 `Build complete!`; 1.8 and 1.9 lines exact; 1.10 clean.
- [ ] **Commit + push (HectorKit main):**

```sh
HK=/Users/andiyar/Developer/HectorKit
git -C "$HK" add Package.swift Sources/HectorResources Sources/HectorTestSupport Tests/HectorResourcesTests
git -C "$HK" commit -F - <<'EOF'
HectorResources: lift EVResources (EV e23122f) + tests; HectorTestSupport env locator

Byte-faithful copy of engine/EVCore/Sources/EVResources/*.swift; only the [EVResources] log tag
renamed. Tests lifted with @testable import renamed; TestSupport became the HectorTestSupport module
(public builders), and IntegrationDataTests reads HECTORKIT_DATA_NOVA / _REFERENCE (D3).
39 tests, 0 failures, 0 skips with data wired.

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>
EOF
git -C "$HK" status --porcelain | grep -v '^??'; git -C "$HK" push origin main
```

Expected: no output from the filtered porcelain; push succeeds (`main -> main`).

---

### Task 2 — `HectorGraphics` (`PICT`, `Ditl`) + `PICTTests` + `DitlTests` (→ 79 tests)

**Files:**
- Create (lifted, byte-identical): `$HK/Sources/HectorGraphics/{PICT,Ditl}.swift`
- Create (lifted, prefix + locator): `$HK/Tests/HectorGraphicsTests/PICTTests.swift`
- Create (assembled from EV `PortChromeTests.swift` lines 13–128 + 213–259): `$HK/Tests/HectorGraphicsTests/DitlTests.swift`
- Modify: `$HK/Package.swift` (stage 2)

- [ ] **Step 2.1: Lift the two sources (no changes at all).**

```sh
HK=/Users/andiyar/Developer/HectorKit; EV=/Users/andiyar/Developer/Ambrosia/engine/EVCore
mkdir -p "$HK/Sources/HectorGraphics" "$HK/Tests/HectorGraphicsTests"
cp "$EV"/Sources/EVGraphics/{PICT,Ditl}.swift "$HK/Sources/HectorGraphics/"
diff "$EV/Sources/EVGraphics/PICT.swift" "$HK/Sources/HectorGraphics/PICT.swift" && diff "$EV/Sources/EVGraphics/Ditl.swift" "$HK/Sources/HectorGraphics/Ditl.swift" && echo identical
```

Expected: `identical`.

- [ ] **Step 2.2: Lift `PICTTests.swift`.** First confirm the private `pictFork` helper is at lines 474–481:

```sh
sed -n '474,481p' /Users/andiyar/Developer/Ambrosia/engine/EVCore/Tests/EVGraphicsTests/PICTTests.swift
```

Expected (exactly — line 481 is blank):

```
private func pictFork(_ name: String) throws -> ResourceCollection {
    guard let root = repoRoot() else { throw XCTSkip("repo root (CLAUDE.md) not found") }
    let url = root.appendingPathComponent("data/nova/\(name)").resolvingSymlinksInPath()
    try XCTSkipUnless(FileManager.default.fileExists(atPath: url.path), "\(name) absent")
    guard let c = try ResourceReader.read(fileAt: url) else { throw XCTSkip("\(name) not a container") }
    return c
}

```

Then copy, delete the helper, rename the imports, and point the five call sites at `novaFork`:

```sh
HK=/Users/andiyar/Developer/HectorKit; EV=/Users/andiyar/Developer/Ambrosia/engine/EVCore
cp "$EV/Tests/EVGraphicsTests/PICTTests.swift" "$HK/Tests/HectorGraphicsTests/"
sed -i '' -e '474,481d' -e 's/^@testable import EVGraphics$/@testable import HectorGraphics/' \
  -e 's/^import EVResources$/import HectorResources/' -e 's/try pictFork(/try novaFork(/g' \
  "$HK/Tests/HectorGraphicsTests/PICTTests.swift"
perl -pi -e 's/^(import HectorResources)$/$1\nimport HectorTestSupport/' "$HK/Tests/HectorGraphicsTests/PICTTests.swift"
diff "$EV/Tests/EVGraphicsTests/PICTTests.swift" "$HK/Tests/HectorGraphicsTests/PICTTests.swift"; grep -c "func test" "$HK/Tests/HectorGraphicsTests/PICTTests.swift"
```

Expected output (exactly):

```
2,3c2,4
< @testable import EVGraphics
< import EVResources
---
> @testable import HectorGraphics
> import HectorResources
> import HectorTestSupport
474,481d474
< private func pictFork(_ name: String) throws -> ResourceCollection {
<     guard let root = repoRoot() else { throw XCTSkip("repo root (CLAUDE.md) not found") }
<     let url = root.appendingPathComponent("data/nova/\(name)").resolvingSymlinksInPath()
<     try XCTSkipUnless(FileManager.default.fileExists(atPath: url.path), "\(name) absent")
<     guard let c = try ResourceReader.read(fileAt: url) else { throw XCTSkip("\(name) not a container") }
<     return c
< }
< 
492c485
<         let titles = try pictFork("Override Titles")
---
>         let titles = try novaFork("Override Titles")
501c494
<         let ships = try pictFork("Override Ships")
---
>         let ships = try novaFork("Override Ships")
510c503
<         let ships = try pictFork("Override Ships")
---
>         let ships = try novaFork("Override Ships")
519c512
<         let gfx = try pictFork("Override Graphics")
---
>         let gfx = try novaFork("Override Graphics")
530c523
<         let ships = try pictFork("Override Ships")
---
>         let ships = try novaFork("Override Ships")
26
```

- [ ] **Step 2.3: Assemble `DitlTests.swift`** — EV's Ditl/DLOG synthetic tests (PortChromeTests.swift
  13–128) and the three Override Titles pins (213–259), in a class of their own; the `ColrRecord` tests stay
  in EV. First confirm the cut lines:

```sh
sed -n '13p;128,130p;213p;259,260p' /Users/andiyar/Developer/Ambrosia/engine/EVCore/Tests/EVCoreTests/PortChromeTests.swift
```

Expected (exactly):

```
    // MARK: - Ditl synthetic hostile input
    }

    // MARK: - ColrRecord synthetic hostile input
    /// DITL 1000 (spaceport main) = 14 items with the coordinator-verified service rects.
    }
}
```

Then build the file:

```sh
HK=/Users/andiyar/Developer/HectorKit; PC=/Users/andiyar/Developer/Ambrosia/engine/EVCore/Tests/EVCoreTests/PortChromeTests.swift
{ cat <<'EOF'
import XCTest
import Foundation
import CoreGraphics
import HectorResources
@testable import HectorGraphics
import HectorTestSupport

/// Machine tests for the `Ditl` dialog-item-list decoder — lifted from EV's `PortChromeTests`
/// (EV e23122f, lines 13–128 and 213–259; the cölr `ColrRecord` tests stay in EV: cölr is an EV Nova
/// record). Two layers: synthetic HOSTILE input (malformed bytes must never trap — nil / defaults
/// only), and data-gated PINS against the real Override Titles fork (HECTORKIT_DATA_NOVA).
final class DitlTests: XCTestCase {

EOF
  sed -n '13,128p' "$PC"
  printf '\n    // MARK: - Data-gated real-fork pins (skipped when HECTORKIT_DATA_NOVA is unset)\n\n'
  sed -n '213,259p' "$PC" | sed 's/try overrideRawFork(/try novaFork(/g'
  echo '}'
} > "$HK/Tests/HectorGraphicsTests/DitlTests.swift"
grep -c "func test" "$HK/Tests/HectorGraphicsTests/DitlTests.swift"; wc -l < "$HK/Tests/HectorGraphicsTests/DitlTests.swift"
grep -n "novaFork\|Colr\|overrideRawFork" "$HK/Tests/HectorGraphicsTests/DitlTests.swift"
```

Expected (exactly; `wc` pads its number with spaces):

```
14
     180
9:/// (EV e23122f, lines 13–128 and 213–259; the cölr `ColrRecord` tests stay in EV: cölr is an EV Nova
135:        let fork = try novaFork("Override Titles")
153:        let fork = try novaFork("Override Titles")
164:        let fork = try novaFork("Override Titles")
```

- [ ] **Step 2.4: `$HK/Package.swift` (stage 2)** — replace the whole file with:

```swift
// swift-tools-version: 6.0
import PackageDescription

// HectorKit — the classic-Mac format layer for Ambrosia game revivals. Zero package dependencies.
// Lifted from the EV engine (EVCore @ e23122f): docs/DECISIONS.md D1.
let package = Package(
    name: "HectorKit",
    platforms: [.macOS(.v15)],
    products: [
        .library(name: "HectorResources", targets: ["HectorResources"]),
        .library(name: "HectorGraphics", targets: ["HectorGraphics"]),
    ],
    targets: [
        .target(name: "HectorResources"),
        .target(name: "HectorGraphics"),
        // Test-only: the shared synthetic-blob builders + the env-var real-data locator (D3). Not a
        // product, so no client package can depend on it. It imports XCTest (XCTSkip).
        .target(name: "HectorTestSupport", dependencies: ["HectorResources"]),
        .testTarget(name: "HectorResourcesTests", dependencies: ["HectorResources", "HectorTestSupport"]),
        .testTarget(name: "HectorGraphicsTests",
                    dependencies: ["HectorGraphics", "HectorResources", "HectorTestSupport"]),
    ]
)
```

- [ ] **Step 2.5: Test with data.**

```sh
cd /Users/andiyar/Developer/HectorKit && HECTORKIT_DATA_NOVA=/Users/andiyar/Developer/Ambrosia/data/nova \
  HECTORKIT_DATA_NOVA_REFERENCE=/Users/andiyar/Developer/Ambrosia/reference swift test > /tmp/hk-t2.log 2>&1
grep -cE "^Test Case '.*' (passed|failed|skipped) \(" /tmp/hk-t2.log; grep -cE "^Test Case '.*' (failed|skipped) \(" /tmp/hk-t2.log
grep -E "Test Suite 'All tests' (passed|failed)" -A1 /tmp/hk-t2.log | grep Executed
```

Expected: `79` and `0`; then the two per-bundle lines `Executed 39 tests, with 0 failures (0 unexpected) …`
(Resources) and `Executed 40 tests, with 0 failures (0 unexpected) …` (Graphics).

- **Verify:** 2.1 `identical`; 2.2/2.3 outputs exact; 2.5 exact.
- [ ] **Commit + push:**

```sh
HK=/Users/andiyar/Developer/HectorKit
git -C "$HK" add Package.swift Sources/HectorGraphics Tests/HectorGraphicsTests
git -C "$HK" commit -F - <<'EOF'
HectorGraphics: lift PICT + Ditl (EV e23122f, byte-identical) + PICTTests + DitlTests

PICTTests: imports renamed, pictFork -> HectorTestSupport.novaFork (HECTORKIT_DATA_NOVA).
DitlTests: EV PortChromeTests lines 13-128 + 213-259 (the cölr tests stay in EV).
79 tests, 0 failures, 0 skips with data wired.

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>
EOF
git -C "$HK" status --porcelain | grep -v '^??'; git -C "$HK" push origin main
```

---

### Task 3 — `HectorAudio` (`SndSound`) + `SndSoundTests` (→ 89 tests)

**Files:**
- Create (lifted, byte-identical): `$HK/Sources/HectorAudio/SndSound.swift`
- Create (lifted, prefix + locator): `$HK/Tests/HectorAudioTests/SndSoundTests.swift`
- Modify: `$HK/Package.swift` (stage 3)

Carried, not a task: `SndSound.playbackDurationFrames` and `loadSoundsTicks` encode EV-engine semantics
(warp clock, `_LoadSounds` tick constant) in pure arithmetic — lifted as-is under the rename-only rule (D1).

- [ ] **Step 3.1: Lift the source.**

```sh
HK=/Users/andiyar/Developer/HectorKit; EV=/Users/andiyar/Developer/Ambrosia/engine/EVCore
mkdir -p "$HK/Sources/HectorAudio" "$HK/Tests/HectorAudioTests"
cp "$EV/Sources/EVCore/SndSound.swift" "$HK/Sources/HectorAudio/"
diff "$EV/Sources/EVCore/SndSound.swift" "$HK/Sources/HectorAudio/SndSound.swift" && echo identical
```

Expected: `identical`.

- [ ] **Step 3.2: Lift the tests.** `SndSoundTests` defines local `be16`/`be32` helpers, so it imports only
  `novaFork` from HectorTestSupport (scoped import — Research note 20).

```sh
HK=/Users/andiyar/Developer/HectorKit; EV=/Users/andiyar/Developer/Ambrosia/engine/EVCore
cp "$EV/Tests/EVCoreTests/SndSoundTests.swift" "$HK/Tests/HectorAudioTests/"
sed -i '' -e 's/^import EVResources$/import HectorResources/' -e 's/^import EVCore$/import HectorAudio/' \
  -e 's/try overrideRawFork(/try novaFork(/g' "$HK/Tests/HectorAudioTests/SndSoundTests.swift"
perl -pi -e 's/^(import HectorAudio)$/$1\nimport func HectorTestSupport.novaFork/' "$HK/Tests/HectorAudioTests/SndSoundTests.swift"
diff "$EV/Tests/EVCoreTests/SndSoundTests.swift" "$HK/Tests/HectorAudioTests/SndSoundTests.swift"
```

Expected output (exactly):

```
3,4c3,5
< import EVResources
< import EVCore
---
> import HectorResources
> import HectorAudio
> import func HectorTestSupport.novaFork
74c75
<         let coll = try overrideRawFork("Override Sounds")
---
>         let coll = try novaFork("Override Sounds")
90c91
<         let coll = try overrideRawFork("Override Sounds")
---
>         let coll = try novaFork("Override Sounds")
98c99
<         let coll = try overrideRawFork("Override Sounds")
---
>         let coll = try novaFork("Override Sounds")
```

- [ ] **Step 3.3: `$HK/Package.swift` (stage 3, final for Phase 0)** — replace the whole file with:

```swift
// swift-tools-version: 6.0
import PackageDescription

// HectorKit — the classic-Mac format layer for Ambrosia game revivals. Zero package dependencies.
// Lifted from the EV engine (EVCore @ e23122f): docs/DECISIONS.md D1.
let package = Package(
    name: "HectorKit",
    platforms: [.macOS(.v15)],
    products: [
        .library(name: "HectorResources", targets: ["HectorResources"]),
        .library(name: "HectorGraphics", targets: ["HectorGraphics"]),
        .library(name: "HectorAudio", targets: ["HectorAudio"]),
    ],
    targets: [
        .target(name: "HectorResources"),
        .target(name: "HectorGraphics"),
        .target(name: "HectorAudio"),
        // Test-only: the shared synthetic-blob builders + the env-var real-data locator (D3). Not a
        // product, so no client package can depend on it. It imports XCTest (XCTSkip).
        .target(name: "HectorTestSupport", dependencies: ["HectorResources"]),
        .testTarget(name: "HectorResourcesTests", dependencies: ["HectorResources", "HectorTestSupport"]),
        .testTarget(name: "HectorGraphicsTests",
                    dependencies: ["HectorGraphics", "HectorResources", "HectorTestSupport"]),
        .testTarget(name: "HectorAudioTests",
                    dependencies: ["HectorAudio", "HectorResources", "HectorTestSupport"]),
    ]
)
```

- [ ] **Step 3.4: Test with data.**

```sh
cd /Users/andiyar/Developer/HectorKit && HECTORKIT_DATA_NOVA=/Users/andiyar/Developer/Ambrosia/data/nova \
  HECTORKIT_DATA_NOVA_REFERENCE=/Users/andiyar/Developer/Ambrosia/reference swift test > /tmp/hk-t3.log 2>&1
grep -cE "^Test Case '.*' (passed|failed|skipped) \(" /tmp/hk-t3.log; grep -cE "^Test Case '.*' (failed|skipped) \(" /tmp/hk-t3.log
grep -E "Test Suite 'All tests' (passed|failed)" -A1 /tmp/hk-t3.log | grep Executed
```

Expected: `89` and `0`; then per-bundle `Executed 39 …`, `Executed 40 …`, `Executed 10 …` (each `with 0 failures`).

- **Verify:** 3.1 `identical`; 3.2 diff exact; 3.4 exact.
- [ ] **Commit + push:**

```sh
HK=/Users/andiyar/Developer/HectorKit
git -C "$HK" add Package.swift Sources/HectorAudio Tests/HectorAudioTests
git -C "$HK" commit -F - <<'EOF'
HectorAudio: lift SndSound (EV e23122f, byte-identical) + SndSoundTests

Imports renamed; overrideRawFork -> HectorTestSupport.novaFork (scoped import). EV-engine
arithmetic (playbackDurationFrames, loadSoundsTicks) carried as-is. 89 tests, 0 failures, 0 skips.

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>
EOF
git -C "$HK" status --porcelain | grep -v '^??'; git -C "$HK" push origin main
```

---

### Task 4 — Zero-skip gate, first floor (89), HectorKit docs

**Files:**
- Create: `$HK/tools/check-zero-skip.sh` (executable)
- Create: `$HK/docs/DECISIONS.md` (D1–D3), `$HK/docs/STATE.md`
- Modify: `$HK/CLAUDE.md` (the env-var sentence)

- [ ] **Step 4.1: Write `$HK/tools/check-zero-skip.sh`** and `chmod +x` it. **This is R2's "floor filled
  from the first green run":** the first green whole-suite run is Task 3 Step 3.4, which counted 89, so the
  script is written with `FLOOR=89`, and Step 4.2 — the script's own first run — must reproduce exactly 89
  (STOP otherwise). Writing the number in advance, rather than pasting it after, turns a lost or duplicated
  test into a STOP instead of a silently lower floor. The script counts `Test Case` lines (Research note 18).

```bash
#!/usr/bin/env bash
# HectorKit machine gate (docs/DECISIONS.md D3): run the WHOLE suite with this machine's real data
# wired in, and FAIL on any skipped test, any failure, or an executed-test total below FLOOR.
# A total ABOVE the floor passes and tells you to bump FLOOR (tests were added — record them).
# Env vars already set in the caller's environment win over the defaults below.
set -euo pipefail

FLOOR=89   # recorded zero-skip floor: "Executed N tests" of the last green run

cd "$(dirname "$0")/.."

export HECTORKIT_DATA_NOVA="${HECTORKIT_DATA_NOVA:-$HOME/Developer/Ambrosia/data/nova}"
export HECTORKIT_DATA_NOVA_REFERENCE="${HECTORKIT_DATA_NOVA_REFERENCE:-$HOME/Developer/Ambrosia/reference}"
export HECTORKIT_DATA_AKI11="${HECTORKIT_DATA_AKI11:-$HOME/Developer/Ambrosia/Aki/Aki - Mahjong Solitaire/Aki - Mahjong Solitaire.app/Contents/Resources}"
echo "HECTORKIT_DATA_NOVA=$HECTORKIT_DATA_NOVA"
echo "HECTORKIT_DATA_NOVA_REFERENCE=$HECTORKIT_DATA_NOVA_REFERENCE"
echo "HECTORKIT_DATA_AKI11=$HECTORKIT_DATA_AKI11"

LOG=/tmp/hectorkit-test.log
set +e
swift test 2>&1 | tee "$LOG"
test_status=${PIPESTATUS[0]}
set -e

# swift test runs each test target as its OWN .xctest bundle, each printing its own
# "Test Suite 'All tests'" block — there is NO package-wide total (Research note 18). So count the
# per-test result lines, which are bundle-independent and start at column 0:
#   Test Case '-[HectorResourcesTests.ByteReaderTests testEndianAndWidths]' passed (0.001 seconds).
# (Anchor on "^Test Case": a bare "skipped" also matches the lifted "[HectorResources] skipped …" log.)
executed=$(grep -cE "^Test Case '.*' (passed|failed|skipped) \(" "$LOG" || true)
failures=$(grep -cE "^Test Case '.*' failed \(" "$LOG" || true)
skipped_cases=$(grep -E "^Test Case '.*' skipped \(" "$LOG" || true)

echo
echo "per-bundle 'All tests' summaries (for the human; the gate counts Test Case lines):"
grep -E "Test Suite 'All tests' (passed|failed)" -A1 "$LOG" | grep -E 'Executed [0-9]+ tests?' || true
echo "executed: $executed   floor: $FLOOR   failures: $failures   swift test exit: $test_status"
if [ "$executed" -eq 0 ]; then
    echo "FAIL: no 'Test Case' result lines in $LOG (build failure?) — swift test exit $test_status"
    exit 1
fi
if [ -n "$skipped_cases" ]; then
    echo "FAIL: zero-skip gate — skipped tests:"
    echo "$skipped_cases"
    exit 1
fi
if [ "$test_status" -ne 0 ] || [ "$failures" != "0" ]; then
    echo "FAIL: swift test exit $test_status, $failures failed test(s)"
    exit 1
fi
if [ "$executed" -lt "$FLOOR" ]; then
    echo "FAIL: executed $executed < floor $FLOOR — tests were lost"
    exit 1
fi
if [ "$executed" -gt "$FLOOR" ]; then
    echo "PASS (above floor): executed $executed > floor $FLOOR — set FLOOR=$executed in tools/check-zero-skip.sh and commit it"
    exit 0
fi
echo "PASS: zero skips, zero failures, executed $executed == floor $FLOOR"
```

```sh
chmod +x /Users/andiyar/Developer/HectorKit/tools/check-zero-skip.sh && bash -n /Users/andiyar/Developer/HectorKit/tools/check-zero-skip.sh && echo syntax-ok
```

Expected: `syntax-ok`.

- [ ] **Step 4.2: First floor run.**

```sh
/Users/andiyar/Developer/HectorKit/tools/check-zero-skip.sh > /tmp/hk-gate.log 2>&1; echo "exit $?"; tail -n 2 /tmp/hk-gate.log
```

Expected: `exit 0`, then `executed: 89   floor: 89   failures: 0   swift test exit: 0` and
`PASS: zero skips, zero failures, executed 89 == floor 89`. Any other total → STOP.

- [ ] **Step 4.3: The gate bites** — point the Nova variable at a missing directory; the run must FAIL on skips.

```sh
HECTORKIT_DATA_NOVA=/nonexistent /Users/andiyar/Developer/HectorKit/tools/check-zero-skip.sh > /tmp/hk-gate-neg.log 2>&1; echo "exit $?"
grep -E '^FAIL' /tmp/hk-gate-neg.log; grep -c "HECTORKIT_DATA_NOVA=/nonexistent is not a directory" /tmp/hk-gate-neg.log
```

Expected: `exit 1`; `FAIL: zero-skip gate — skipped tests:`; a count ≥ 1 (every Override-fork test skips,
naming the variable: 1 folder + 1 Data-2 test in IntegrationDataTests, 5 RealPICTCensusTests, 3 Ditl pins,
3 snd oracles = 13 skips at Task 4; the same negative run after Task 5 gives 14, because
`testEVShip5027StaysOutsideTheBandedWalk` skips too). Then re-run Step 4.2 so `/tmp/hectorkit-test.log` holds
a green log again.

- [ ] **Step 4.4: Write `$HK/docs/DECISIONS.md`:**

```markdown
# DECISIONS.md — HectorKit

> Append-only. Numbered. Never re-litigate a locked decision — supersede it with a new numbered
> entry that references the old one. Record rejected alternatives with the reason.
> Design + provenance: `~/Developer/Ambrosia-Classics/docs/design-2026-10-03-hectorkit-and-classics.md`;
> the executing plan: `~/Developer/Ambrosia-Classics/docs/plans/2026-10-03-phase0-hectorkit-lift.md`.

---

## D1 — HectorKit starts as a byte-faithful lift of EV's Foundation-only format code (2026-10-03)

**Decided:** Copied from `~/Developer/Ambrosia/engine/EVCore` at EV commit
`e23122f408555d2961f30006f43a9555ac04244e`, history-free:
`Sources/EVResources/{BRGRContainer,ByteReader,ClassicResourceMap,ContainerBackend,MacRoman,Resource}.swift`
→ `HectorResources`; `Sources/EVGraphics/{PICT,Ditl}.swift` → `HectorGraphics`;
`Sources/EVCore/SndSound.swift` → `HectorAudio`. Tests: `Tests/EVResourcesTests/*` (TestSupport became
the `HectorTestSupport` module), `Tests/EVGraphicsTests/PICTTests.swift`, `Tests/EVCoreTests/SndSoundTests.swift`,
and the `Ditl` subset of `Tests/EVCoreTests/PortChromeTests.swift` (lines 13–128 + 213–259) as `DitlTests`.
Changes are limited to: module prefixes (`import`/`@testable import`, the `[EVResources]` log tag →
`[HectorResources]`); EV's `repoRoot()`/`data/nova` locators → env vars (D3); TestSupport symbols made
`public` with explicit initialisers. Doc comments that mention EV, pilots, D-numbers etc. are provenance
and stay verbatim. Carried as-is (EV-engine semantics in pure arithmetic): `SndSound.playbackDurationFrames`
and `SndSound.loadSoundsTicks`. The EV repo is untouched; EV adopts HectorKit later through a re-export
shim in its own machine-gated PR (design §1.3).
**Because:** one decoder with two consumers only stays one decoder if the first copy is provably the
same bytes — reviewers diff HectorKit against EV at a pinned SHA and see only prefix lines.
**Rejected:** renaming inside the EV repo (design §1 — entangles new games with EV's lanes and open PRs) ·
tidying EV-flavoured comments during the lift (destroys the diff-against-EV review and the provenance) ·
lifting the cölr `ColrRecord` tests with `Ditl` (cölr is an EV Nova record — stays in EV).
**Approved by:** design doc 2026-10-03 (Ben's verbal approval in pieces; written review pending) and the
Phase-0 orchestrator rulings R1/R8 in the plan.

## D2 — Banded QuickTime PICTs: walk every band, skip the placeholder, composite through ImageIO (2026-10-03)

**Decided:** Aki 1.1.0's 71 QuickTime PICTs are `0x0011 · 0x0C00 · 0x00A1 LongComment · 0x0001 Clip ·
N × [0x8200 JPEG band · 0x0098 1-bit BitMap placeholder] · 0x00FF` (N = 1, 2, 4 or 6). HectorGraphics gains:
(a) `compressedQuickTimePayload` skips 0x00A0/0x00A1 exactly as `PICT.init` does (it threw
`unsupportedOpcode(0x00A1)` on every Aki QuickTime PICT; it still returns only the first band);
(b) `PICT.quickTimeBands(data:)` walks the whole stream: state ops as `PICT.init`, every 0x8200 band
(placed at its matrix translation, whole-pixel translation only), the 1-bit BitMap directly after a band
parsed-and-skipped and counted — it is QuickTime's "decompressor required" fallback image, never art;
rect-paint ops 0x0030–0x0034 skipped and RECORDED exactly as `PICT.init` does (returned as a fourth
element, `droppedPaintOps`); any other opcode throws, including raster PixMaps/DirectBits (no way to mix
raster pixels into the codec composite); (c) `CodecImage.decode` (ImageIO → RGBA8 premultiplied, sRGB, top row
first); (d) `PICT.decodeQuickTime(data:)` composites the bands into a frame-sized RGBA, refusing a band
outside the frame (`DecodeError.bandOutOfFrame`) or bands that do not tile it exactly
(`DecodeError.bandCoverage`: gap, overlap, or decoded size ≠ declared), and carries the walk's
`droppedPaintOps` into the composite. This supersedes the Phase-0 brief's R3 wording (a three-element
`quickTimeBands` tuple and `droppedPaintOps = []`). `PICT.init` still throws
`unsupportedOpcode(0x8200)` (EV app code relies on it). `PICT.Cursor` went from `private` to internal so
the new file can walk with it. EV's own QuickTime PICTs (ship 5027/5030: a 0x0032 paint op before the band,
a pen/text-state + LongText "decompressor required" fallback after it, starting 0x0007 PnSize) are a
different shape; the banded walk records the 0x0032, reads the band, refuses the fallback at 0x0007 (pinned
by a test), and they stay on `compressedQuickTimePayload`.
**Orchestrator rulings (2026-10-03):** (1) rect-paint ops in the banded walk are skipped and recorded, as
`PICT.init` does, and carried into `decodeQuickTime`'s `droppedPaintOps`; (2) raster PixMap/DirectBits ops
in the banded walk are REFUSED (`unsupportedOpcode`).
**Because:** every one of the 71 must reach its declared frame size (design §5) and a band-order or offset
bug must be visible: Aki 1.2.0 re-shipped the same art as PNG, so a composite is checked against its 1.2.0
twin (mean |ΔRGB| < 6; a two-band swap costs 10–30).
**Rejected:** decoding 0x8200 inside `PICT.init` (breaks EV's contract and its pinned test) · first band only
(the 800×600 backgrounds are 4 bands, PICT 130 is 6) · drawing the placeholder BitMap (paints a 69×44 1-bit
"QuickTime required" glyph over the art) · refusing paint ops in the banded walk (would put EV's own
5027/5030 shape further out of reach for no gain; `PICT.init`'s record-and-disclose contract already exists) ·
compositing raster ops into the banded image (no census case; refused instead) · a hand-written JPEG decoder
(ImageIO is the platform's).
**Approved by:** Phase-0 orchestrator ruling R3 as amended by the two rulings above (2026-10-03), under the
design doc; Ben's review pending.

## D3 — Real data through environment variables; a zero-skip floor is the machine gate (2026-10-03)

**Decided:** Data-gated tests read `HECTORKIT_DATA_NOVA` (the EV Nova Override fork folder),
`HECTORKIT_DATA_NOVA_REFERENCE` (searched recursively for `Nova Data 4.ndat`, `Override Data 1.rez`,
`Override Data 2.rez`, `EV Data.rez`) and `HECTORKIT_DATA_AKI11` (Aki 1.1.0 `Contents/Resources`) through
`HectorTestSupport.HectorData`; an unset variable or a missing file throws `XCTSkip` naming the variable.
`tools/check-zero-skip.sh` exports this machine's defaults, runs `swift test`, and FAILS on any skipped test,
any failure, or an executed total below its `FLOOR` constant; above the floor it passes and says to bump
`FLOOR`. The current floor is in the script and in `docs/STATE.md`.
**Because:** HectorKit has no data of its own and every machine keeps the originals somewhere different;
a skip that is counted can never pass for a green run.
**Rejected:** walking up to a checkout's `data/` (EV's `repoRoot()` — HectorKit has no data dir) ·
committing derived fixtures (copyright; `.gitignore` already excludes `Fixtures/private/`) · letting skips
pass (a machine with no data would look exactly like a green one).
**Approved by:** Phase-0 orchestrator ruling R2 (2026-10-03); Ben's review pending.
```

- [ ] **Step 4.5: Write `$HK/docs/STATE.md`:**

```markdown
# STATE — HectorKit — 2026-10-03

> Live state only. Dated; re-verify before acting. Forks go in `docs/DECISIONS.md`.

## Where we are

- **Lifted from EV** (`engine/EVCore` @ `e23122f`, D1): `HectorResources` (classic map, BRGR, reader,
  MacRoman), `HectorGraphics` (`PICT`, `Ditl`), `HectorAudio` (`SndSound`), + test-only `HectorTestSupport`.
- **Gate:** `tools/check-zero-skip.sh` — zero skips, zero failures, **floor 89** (2026-10-03).
- Real data via env vars (D3): `HECTORKIT_DATA_NOVA`, `HECTORKIT_DATA_NOVA_REFERENCE`, `HECTORKIT_DATA_AKI11`.

## Open, ordered

1. Phase 0 Task 5: banded QuickTime PICTs (D2) — `quickTimeBands`, `CodecImage`, `decodeQuickTime`.
2. Phase 0 Task 6: Aki 1.1.0 PICT census test; then tag `v0.1.0`.
3. Phase 1: `HectorShell` (design §2).
4. EV adopts HectorKit via a re-export shim — EV's own PR, later (design §1.3).
```

- [ ] **Step 4.6: Correct the env-var sentence in `$HK/CLAUDE.md`** (Edit tool, exact strings).
  Replace:

```
Real-data fixture tests read game data from sibling checkouts via `HECTORKIT_DATA` env paths and
SKIP (counted, never silent) when absent — see `tools/check-zero-skip.sh` once it exists.
```

  with:

```
Real-data fixture tests read game data via `HECTORKIT_DATA_NOVA`, `HECTORKIT_DATA_NOVA_REFERENCE` and
`HECTORKIT_DATA_AKI11` and SKIP (naming the variable) when absent; `tools/check-zero-skip.sh` sets this
machine's defaults and FAILS on any skip or a total below its recorded floor (docs/DECISIONS.md D3).
```

- **Verify:** 4.1 `syntax-ok`; 4.2 PASS line at 89; 4.3 `exit 1` + FAIL line.
- [ ] **Commit + push:**

```sh
HK=/Users/andiyar/Developer/HectorKit
git -C "$HK" add tools/check-zero-skip.sh docs/DECISIONS.md docs/STATE.md CLAUDE.md
git -C "$HK" commit -F - <<'EOF'
tools/check-zero-skip.sh (floor 89) + docs: STATE, DECISIONS D1-D3

The machine gate: whole suite with this machine's real data, fails on any skip, any failure,
or a total below FLOOR. D1 lift provenance (EV e23122f), D2 banded QuickTime (next task),
D3 env-var data policy + zero-skip floor.

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>
EOF
git -C "$HK" status --porcelain | grep -v '^??'; git -C "$HK" push origin main
```

---

### Task 5 — ⚑ MAJOR — Banded QuickTime: `CodecImage`, the extractor fix, `quickTimeBands`, `decodeQuickTime` (→ 109 tests)

**Review:** MAJOR task — two review legs before Task 6 starts: (1) spec compliance against D2, ruling R3 and
this task's steps; (2) code quality + hostile-input posture (every read bounds-checked, no trap, no silent
loss). The implementer stops after Step 5.12 and hands both legs the commits of Steps 5.3, 5.6, 5.9, 5.12.

**Files:**
- Create: `$HK/Tests/HectorGraphicsTests/QuickTimeFixtures.swift`, `CodecImageTests.swift`, `PICTQuickTimeTests.swift`
- Create: `$HK/Sources/HectorGraphics/CodecImage.swift`, `$HK/Sources/HectorGraphics/PICT+QuickTime.swift`
- Modify: `$HK/Sources/HectorGraphics/PICT.swift` (exactly three hunks — Invariant 2c)
- Modify: `$HK/tools/check-zero-skip.sh` (`FLOOR=89` → `FLOOR=109`), `$HK/docs/STATE.md`

Env: only Steps 5.8 and 5.10 run `testEVShip5027StaysOutsideTheBandedWalk`, so only they pass
`HECTORKIT_DATA_NOVA=/Users/andiyar/Developer/Ambrosia/data/nova` inline; Step 5.11's script sets all three
variables itself. The other steps' filters select no data-gated test.

- [ ] **Step 5.1: Write the fixtures `$HK/Tests/HectorGraphicsTests/QuickTimeFixtures.swift`:**

```swift
import CoreGraphics
import Foundation
import ImageIO

// Synthetic fixtures for the banded-QuickTime tests (HectorKit D2). The PICT builder mirrors, opcode
// for opcode, the stream every one of Aki 1.1.0's 71 QuickTime PICTs carries (census 2026-10-03):
//   0x0011 · 0x0C00 · 0x00A1 (kind 498, 22 B "8BIM…") · 0x0001 Clip ·
//   N × [ 0x8200 band · 0x0098 1-bit BitMap placeholder (rowBytes 10, bounds 69×44) ] · 0x00FF
// The one deliberate difference: band payloads are tiny PNGs with codec "png " instead of JPEG
// "jpeg" — ImageIO sniffs the payload BYTES, not the fourcc, and PNG round-trips pixels exactly.

/// One band of a synthetic banded QuickTime PICT.
struct FixtureBand {
    var x: Int
    var y: Int
    var width: Int
    var height: Int
    var payload: Data
    var codec: String = "png "
    /// Matrix a/d (Fixed 16.16). 0x0001_0000 = 1.0, the only value the walker accepts.
    var matrixScale: Int = 0x0001_0000
}

/// `count` copies of one RGBA pixel.
func solidRGBA(_ pixel: [UInt8], count: Int) -> [UInt8] {
    Array([[UInt8]](repeating: pixel, count: count).joined())
}

/// An sRGB CGImage over row-major RGBA8 bytes (top row first, premultiplied — use alpha 0 or 255).
func makeCGImage(width: Int, height: Int, rgba: [UInt8]) -> CGImage {
    precondition(rgba.count == width * height * 4, "rgba must be width*height*4 bytes")
    let info = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue
                            | CGBitmapInfo.byteOrder32Big.rawValue)
    return CGImage(width: width, height: height, bitsPerComponent: 8, bitsPerPixel: 32,
                   bytesPerRow: width * 4, space: CGColorSpace(name: CGColorSpace.sRGB)!,
                   bitmapInfo: info, provider: CGDataProvider(data: Data(rgba) as CFData)!,
                   decode: nil, shouldInterpolate: false, intent: .defaultIntent)!
}

/// Encode RGBA8 pixels through ImageIO as `typeIdentifier` ("public.png" or "public.jpeg").
func encodeImage(width: Int, height: Int, rgba: [UInt8], as typeIdentifier: String) -> Data {
    let out = NSMutableData()
    let destination = CGImageDestinationCreateWithData(out as CFMutableData, typeIdentifier as CFString, 1, nil)!
    CGImageDestinationAddImage(destination, makeCGImage(width: width, height: height, rgba: rgba), nil)
    precondition(CGImageDestinationFinalize(destination), "ImageIO failed to encode \(typeIdentifier)")
    return out as Data
}

func makePNG(width: Int, height: Int, rgba: [UInt8]) -> Data {
    encodeImage(width: width, height: height, rgba: rgba, as: "public.png")
}

/// A solid-colour PNG band of `width`×`height` at (x, y).
func solidBand(x: Int, y: Int, width: Int, height: Int, _ pixel: [UInt8]) -> FixtureBand {
    FixtureBand(x: x, y: y, width: width, height: height,
                payload: makePNG(width: width, height: height, rgba: solidRGBA(pixel, count: width * height)))
}

/// The placeholder Aki writes after every band: 0x0098 PackBitsRect with a 1-bit BitMap (rowBytes
/// 10, high bit CLEAR), bounds = srcRect = (0,0,44,69), dstRect = the band's rect, mode srcCopy,
/// then 44 PackBits rows (here each one repeat run: count 2, flag 0xF7 = 10 × 0x00).
func akiPlaceholder(for band: FixtureBand) -> [UInt8] {
    var p: [UInt8] = []
    func u16(_ v: Int) { p.append(UInt8(truncatingIfNeeded: v >> 8)); p.append(UInt8(truncatingIfNeeded: v)) }
    u16(0x0098)
    u16(10)                                                         // rowBytes (bit 15 clear → BitMap)
    u16(0); u16(0); u16(44); u16(69)                                // bounds t,l,b,r
    u16(0); u16(0); u16(44); u16(69)                                // srcRect
    u16(band.y); u16(band.x); u16(band.y + band.height); u16(band.x + band.width)   // dstRect
    u16(0)                                                          // mode (srcCopy)
    for _ in 0..<44 { p.append(contentsOf: [2, 0xF7, 0x00]) }       // 44 packed rows
    if p.count % 2 == 1 { p.append(0) }
    return p
}

/// Build a banded CompressedQuickTime PICT in Aki 1.1.0's exact opcode shape.
/// - `extraOpsBeforeBands`: raw opcode bytes injected after the Clip (word-padded).
/// - `placeholder`: the bytes written after each band (nil = no placeholder at all).
func makeBandedQuickTimePICT(frameWidth: Int, frameHeight: Int, bands: [FixtureBand],
                             extraOpsBeforeBands: [UInt8] = [],
                             placeholder: ((FixtureBand) -> [UInt8])? = akiPlaceholder) -> Data {
    var d = Data()
    func u8(_ v: Int) { d.append(UInt8(truncatingIfNeeded: v)) }
    func u16(_ v: Int) { u8(v >> 8); u8(v) }
    func u32(_ v: Int) { u16(v >> 16); u16(v) }
    func pad() { if d.count % 2 == 1 { d.append(0) } }
    u16(0)                                                          // picSize (decoders ignore)
    u16(0); u16(0); u16(frameHeight); u16(frameWidth)               // picFrame t,l,b,r
    u16(0x0011); u8(0x02); u8(0xFF)                                 // VersionOp v2
    u16(0x0C00); d.append(contentsOf: [UInt8](repeating: 0, count: 24))   // HeaderOp
    u16(0x00A1); u16(498); u16(22)                                  // LongComment kind 498, 22 B
    d.append(contentsOf: Array("8BIM".utf8)); d.append(contentsOf: [UInt8](repeating: 0, count: 18))
    u16(0x0001); u16(10); u16(0); u16(0); u16(frameHeight); u16(frameWidth)   // Clip
    d.append(contentsOf: extraOpsBeforeBands); pad()
    for b in bands {
        u16(0x8200)
        u32((68 + 86 + b.payload.count + 1) & ~1)                    // opSize, rounded up to even (Aki)
        u16(0)                                                      // version
        u32(b.matrixScale); u32(0); u32(0)                          // a, b, u
        u32(0); u32(b.matrixScale); u32(0)                          // c, d, v
        u32(b.x << 16); u32(b.y << 16); u32(0x4000_0000)            // tx, ty, w
        u32(0)                                                      // matteSize
        u32(0); u32(0)                                              // matteRect
        u16(64)                                                     // mode
        u16(0); u16(0); u16(b.height); u16(b.width)                 // srcRect
        u32(0)                                                      // accuracy
        u32(0)                                                      // maskSize
        u32(86)                                                     // ImageDescription @0 idSize
        d.append(contentsOf: Array(b.codec.utf8.prefix(4)))         // @4 cType
        u32(0); u16(0); u16(0)                                      // @8 reserved ×2, dataRefIndex
        u16(0); u16(0); u32(0)                                      // @16 version, revision, vendor
        u32(0); u32(0)                                              // @24 temporal/spatial quality
        u16(b.width); u16(b.height)                                 // @32 width, height
        u32(0x0048_0000); u32(0x0048_0000)                          // @36 hRes, vRes
        u32(b.payload.count)                                        // @44 dataSize
        u16(1)                                                      // @48 frameCount
        d.append(contentsOf: [UInt8](repeating: 0, count: 32))      // @50 name (Str31)
        u16(24)                                                     // @82 depth
        u16(0xFFFF)                                                 // @84 clutID −1
        d.append(b.payload); pad()
        if let placeholder { d.append(contentsOf: placeholder(b)); pad() }
    }
    u16(0x00FF)                                                     // EndOfPicture
    return d
}
```

- [ ] **Step 5.2 (red): Write `$HK/Tests/HectorGraphicsTests/CodecImageTests.swift`:**

```swift
import XCTest
import Foundation
@testable import HectorGraphics

/// `CodecImage` — the ImageIO decode under every QuickTime-in-PICT path (HectorKit D2).
/// Fixtures are generated in-test through ImageIO (no binary fixtures).
final class CodecImageTests: XCTestCase {

    /// 3×2 PNG, distinct pixel per position: the decode is top-row-first, R,G,B,A, exact for
    /// opaque and fully transparent pixels (premultiplied == straight at alpha 0 and 255).
    func testDecodesPNGPixelsExactlyTopRowFirst() throws {
        let pixels: [UInt8] = [255, 0, 0, 255,   0, 255, 0, 255,   0, 0, 255, 255,     // row 0: R G B
                               0, 0, 0, 0,       255, 255, 255, 255, 255, 255, 0, 255]  // row 1: clear W Y
        let image = try CodecImage.decode(makePNG(width: 3, height: 2, rgba: pixels))
        XCTAssertEqual(image.width, 3)
        XCTAssertEqual(image.height, 2)
        XCTAssertEqual([UInt8](image.rgba), pixels)
    }

    /// JPEG is lossy — only the geometry is exact.
    func testDecodesJPEGToItsSize() throws {
        let jpeg = encodeImage(width: 16, height: 8, rgba: solidRGBA([200, 100, 50, 255], count: 128),
                               as: "public.jpeg")
        let image = try CodecImage.decode(jpeg)
        XCTAssertEqual([image.width, image.height], [16, 8])
        XCTAssertEqual(image.rgba.count, 16 * 8 * 4)
        XCTAssertEqual(image.rgba[3], 255, "JPEG decodes opaque")
    }

    func testGarbageIsNotAnImage() {
        XCTAssertThrowsError(try CodecImage.decode(Data("not an image at all".utf8))) {
            XCTAssertEqual($0 as? CodecImage.DecodeError, .notAnImage)
        }
    }

    func testEmptyDataIsNotAnImage() {
        XCTAssertThrowsError(try CodecImage.decode(Data())) {
            XCTAssertEqual($0 as? CodecImage.DecodeError, .notAnImage)
        }
    }
}
```

```sh
cd /Users/andiyar/Developer/HectorKit && swift test --filter CodecImageTests 2>&1 | grep -m1 -E "error:"
```

Expected: an `error: cannot find 'CodecImage' in scope` line (compile red).

- [ ] **Step 5.3 (green): Write `$HK/Sources/HectorGraphics/CodecImage.swift`:**

```swift
import CoreGraphics
import Foundation
import ImageIO

/// Decode one codec-compressed still image (JPEG, PNG, TIFF — anything ImageIO reads) to RGBA8.
///
/// This is the decode half of every QuickTime-in-PICT path (HectorKit D2): a 0x8200
/// CompressedQuickTime record carries a JPEG/TIFF payload that QuickDraw itself never rasterised,
/// so the kit hands it to ImageIO. ImageIO sniffs the BYTES, not the record's fourcc.
public enum CodecImage {
    public enum DecodeError: Error, Equatable {
        /// ImageIO could not open the bytes as an image (empty, truncated, or not an image format).
        case notAnImage
    }

    /// - Returns: the image's pixel `width`/`height` and `width * height * 4` bytes, row-major from
    ///   the TOP row, in R,G,B,A order, sRGB, with **premultiplied** alpha
    ///   (`kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big`). Opaque sources (every JPEG)
    ///   come out with A = 255, where premultiplied and straight alpha are the same bytes.
    public static func decode(_ data: Data) throws -> (width: Int, height: Int, rgba: Data) {
        guard !data.isEmpty,
              let source = CGImageSourceCreateWithData(data as CFData, nil),
              let image = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
            throw DecodeError.notAnImage
        }
        let width = image.width, height = image.height
        guard width > 0, height > 0, let space = CGColorSpace(name: CGColorSpace.sRGB) else {
            throw DecodeError.notAnImage
        }
        let bitmapInfo = CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Big.rawValue
        var rgba = Data(count: width * height * 4)
        let drawn = rgba.withUnsafeMutableBytes { buffer -> Bool in
            guard let context = CGContext(data: buffer.baseAddress, width: width, height: height,
                                          bitsPerComponent: 8, bytesPerRow: width * 4,
                                          space: space, bitmapInfo: bitmapInfo) else { return false }
            context.interpolationQuality = .none
            context.setBlendMode(.copy)
            context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
            return true
        }
        guard drawn else { throw DecodeError.notAnImage }
        return (width: width, height: height, rgba: rgba)
    }
}
```

```sh
cd /Users/andiyar/Developer/HectorKit && swift test --filter CodecImageTests 2>&1 | grep -E 'Executed [0-9]+ tests?, with' | grep -v 'Executed 0 tests' | tail -n 1
```

Expected: `Executed 4 tests, with 0 failures (0 unexpected) in …` (the Graphics bundle's line; the Resources
and Audio bundles print `Executed 0 tests`, filtered out — Research note 18). Commit (no push yet):

```sh
HK=/Users/andiyar/Developer/HectorKit
git -C "$HK" add Sources/HectorGraphics/CodecImage.swift Tests/HectorGraphicsTests/QuickTimeFixtures.swift Tests/HectorGraphicsTests/CodecImageTests.swift
git -C "$HK" commit -F - <<'EOF'
HectorGraphics: CodecImage (ImageIO -> RGBA8 premultiplied) + banded-QuickTime fixtures (D2)

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>
EOF
```

- [ ] **Step 5.4 (red): The extractor fix, test first.** Write `$HK/Tests/HectorGraphicsTests/PICTQuickTimeTests.swift`
  with only its first two tests (the file is replaced by the full version in Step 5.7):

```swift
import XCTest
import Foundation
import HectorResources
@testable import HectorGraphics

/// Banded CompressedQuickTime (0x8200) PICTs — `compressedQuickTimePayload`'s LongComment fix,
/// `quickTimeBands`, and `decodeQuickTime` (HectorKit D2). Synthetic fixtures mirror Aki 1.1.0's
/// stream shape exactly (QuickTimeFixtures.swift); the real-data census is AkiPICTCensusTests.
final class PICTQuickTimeTests: XCTestCase {

    private let red: [UInt8] = [255, 0, 0, 255]
    private let blue: [UInt8] = [0, 0, 255, 255]

    /// 4×3 frame = a 4×2 red band at y 0 + a 4×1 blue band at y 2 — Aki's top-to-bottom strips.
    private func twoBandFixture() -> (data: Data, bands: [FixtureBand]) {
        let bands = [solidBand(x: 0, y: 0, width: 4, height: 2, red),
                     solidBand(x: 0, y: 2, width: 4, height: 1, blue)]
        return (makeBandedQuickTimePICT(frameWidth: 4, frameHeight: 3, bands: bands), bands)
    }

    // MARK: - compressedQuickTimePayload (the lifted extractor) on the Aki shape

    /// Before HectorKit D2 the extractor's walk skipped only 0x0011/0x0C00/0x0001/0x001E/0x001F/0x0030–34
    /// and threw `unsupportedOpcode(0x00A1)` on every Aki QuickTime PICT (each carries a LongComment).
    /// It now skips 0x00A0/0x00A1 exactly as `PICT.init` does — and still returns only the FIRST band.
    func testCompressedQuickTimePayloadSkipsLongCommentAndReturnsFirstBand() throws {
        let (data, bands) = twoBandFixture()
        let qt = try PICT.compressedQuickTimePayload(data: data)
        XCTAssertEqual(qt.codec, "png ")
        XCTAssertEqual([qt.width, qt.height], [4, 2])
        XCTAssertEqual(qt.payload, bands[0].payload)
    }

    /// The raster path must still refuse the codec opcode (EV app code relies on it).
    func testInitStillThrowsUnsupported8200OnBandedStream() {
        XCTAssertThrowsError(try PICT(data: twoBandFixture().data)) {
            XCTAssertEqual($0 as? PICT.DecodeError, .unsupportedOpcode(0x8200))
        }
    }
}
```

```sh
cd /Users/andiyar/Developer/HectorKit && swift test --filter PICTQuickTimeTests > /tmp/hk-t5-4.log 2>&1
grep -E 'Executed [0-9]+ tests?, with' /tmp/hk-t5-4.log | grep -v 'Executed 0 tests' | tail -n 1; grep -m1 "unsupportedOpcode(161)" /tmp/hk-t5-4.log
```

Expected: `Executed 2 tests, with 1 failure (1 unexpected) in …` (a thrown error counts as unexpected), and a failure line for
`testCompressedQuickTimePayloadSkipsLongCommentAndReturnsFirstBand` mentioning `unsupportedOpcode(161)` (0x00A1).

- [ ] **Step 5.5 (green): `PICT.swift` hunk 3 of 3** — in `compressedQuickTimePayload`'s walk, skip
  0x00A0/0x00A1 exactly as `PICT.init` does. Edit tool, replace (unique in the file):

```swift
            case 0x001F: try c.skip(6)                             // OpColor
```

with:

```swift
            case 0x001F: try c.skip(6)                             // OpColor
            case 0x00A0: try c.skip(2)                             // ShortComment — as PICT.init (HectorKit D2)
            case 0x00A1: _ = try c.u16()                           // LongComment — as PICT.init; Aki 1.1.0
                         let size = try c.u16(); try c.skip(size)  // carries one before every 0x8200
```

```sh
cd /Users/andiyar/Developer/HectorKit && swift test --filter 'PICTQuickTimeTests|PICTTests' 2>&1 | grep -E 'Executed [0-9]+ tests?, with' | grep -v 'Executed 0 tests' | tail -n 1
```

Expected: `Executed 23 tests, with 0 failures (0 unexpected) in …` — the 2 new tests + the 21 tests of class
`PICTTests` (`RealPICTCensusTests` does not match the regex `PICTTests`; its 5 real-data tests run in Step 5.11).

- [ ] **Step 5.6: Commit (no push yet).**

```sh
HK=/Users/andiyar/Developer/HectorKit
git -C "$HK" add Sources/HectorGraphics/PICT.swift Tests/HectorGraphicsTests/PICTQuickTimeTests.swift
git -C "$HK" commit -F - <<'EOF'
PICT.compressedQuickTimePayload: skip 0x00A0/0x00A1 like PICT.init (D2)

It threw unsupportedOpcode(0x00A1) on every Aki 1.1.0 QuickTime PICT (each carries a LongComment
before its first 0x8200). Still returns only the first band.

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>
EOF
```

- [ ] **Step 5.7 (red): `PICT.swift` hunks 1 and 2, then the full test file.** Edit tool, replace:

```swift
    public enum DecodeError: Error, Equatable {
        case notV2, truncated, unsupportedOpcode(Int), badPackBits, unsupportedDepth(Int)
    }
```

with:

```swift
    public enum DecodeError: Error, Equatable {
        case notV2, truncated, unsupportedOpcode(Int), badPackBits, unsupportedDepth(Int)
        /// `decodeQuickTime`: a 0x8200 band reaches outside the picFrame (HectorKit D2).
        case bandOutOfFrame
        /// `decodeQuickTime`: the bands do not tile the picFrame exactly — a gap, an overlap, or a band
        /// that decodes to a size other than its ImageDescription's (HectorKit D2).
        case bandCoverage
    }
```

and replace:

```swift
    /// Big-endian byte cursor with bounds-checked reads (mirrors Sprite's decode discipline).
    private struct Cursor {
```

with:

```swift
    /// Big-endian byte cursor with bounds-checked reads (mirrors Sprite's decode discipline).
    /// HectorKit D2: internal, not private — `PICT+QuickTime.swift` walks with it.
    struct Cursor {
```

Check that `PICT.swift` now differs from EV by exactly the three hunks:

```sh
diff /Users/andiyar/Developer/Ambrosia/engine/EVCore/Sources/EVGraphics/PICT.swift /Users/andiyar/Developer/HectorKit/Sources/HectorGraphics/PICT.swift
```

Expected output (exactly):

```
21a22,26
>         /// `decodeQuickTime`: a 0x8200 band reaches outside the picFrame (HectorKit D2).
>         case bandOutOfFrame
>         /// `decodeQuickTime`: the bands do not tile the picFrame exactly — a gap, an overlap, or a band
>         /// that decodes to a size other than its ImageDescription's (HectorKit D2).
>         case bandCoverage
25c30,31
<     private struct Cursor {
---
>     /// HectorKit D2: internal, not private — `PICT+QuickTime.swift` walks with it.
>     struct Cursor {
358a365,367
>             case 0x00A0: try c.skip(2)                             // ShortComment — as PICT.init (HectorKit D2)
>             case 0x00A1: _ = try c.u16()                           // LongComment — as PICT.init; Aki 1.1.0
>                          let size = try c.u16(); try c.skip(size)  // carries one before every 0x8200
```

Now replace `$HK/Tests/HectorGraphicsTests/PICTQuickTimeTests.swift` with the full file:

```swift
import XCTest
import Foundation
import HectorResources
@testable import HectorGraphics
import HectorTestSupport

/// Banded CompressedQuickTime (0x8200) PICTs — `compressedQuickTimePayload`'s LongComment fix,
/// `quickTimeBands`, and `decodeQuickTime` (HectorKit D2). Synthetic fixtures mirror Aki 1.1.0's
/// stream shape exactly (QuickTimeFixtures.swift); the real-data census is AkiPICTCensusTests.
final class PICTQuickTimeTests: XCTestCase {

    private let red: [UInt8] = [255, 0, 0, 255]
    private let blue: [UInt8] = [0, 0, 255, 255]

    /// 4×3 frame = a 4×2 red band at y 0 + a 4×1 blue band at y 2 — Aki's top-to-bottom strips.
    private func twoBandFixture() -> (data: Data, bands: [FixtureBand]) {
        let bands = [solidBand(x: 0, y: 0, width: 4, height: 2, red),
                     solidBand(x: 0, y: 2, width: 4, height: 1, blue)]
        return (makeBandedQuickTimePICT(frameWidth: 4, frameHeight: 3, bands: bands), bands)
    }

    // MARK: - compressedQuickTimePayload (the lifted extractor) on the Aki shape

    /// Before HectorKit D2 the extractor's walk skipped only 0x0011/0x0C00/0x0001/0x001E/0x001F/0x0030–34
    /// and threw `unsupportedOpcode(0x00A1)` on every Aki QuickTime PICT (each carries a LongComment).
    /// It now skips 0x00A0/0x00A1 exactly as `PICT.init` does — and still returns only the FIRST band.
    func testCompressedQuickTimePayloadSkipsLongCommentAndReturnsFirstBand() throws {
        let (data, bands) = twoBandFixture()
        let qt = try PICT.compressedQuickTimePayload(data: data)
        XCTAssertEqual(qt.codec, "png ")
        XCTAssertEqual([qt.width, qt.height], [4, 2])
        XCTAssertEqual(qt.payload, bands[0].payload)
    }

    /// The raster path must still refuse the codec opcode (EV app code relies on it).
    func testInitStillThrowsUnsupported8200OnBandedStream() {
        XCTAssertThrowsError(try PICT(data: twoBandFixture().data)) {
            XCTAssertEqual($0 as? PICT.DecodeError, .unsupportedOpcode(0x8200))
        }
    }

    // MARK: - quickTimeBands

    func testQuickTimeBandsWalksEveryBandAndCountsPlaceholders() throws {
        let (data, bands) = twoBandFixture()
        let walk = try PICT.quickTimeBands(data: data)
        XCTAssertEqual([walk.frame.width, walk.frame.height], [4, 3])
        XCTAssertEqual(walk.bands.count, 2)
        XCTAssertEqual(walk.skippedPlaceholders, 2)
        XCTAssertEqual(walk.droppedPaintOps, [])
        XCTAssertEqual(walk.bands.map(\.codec), ["png ", "png "])
        XCTAssertEqual(walk.bands.map(\.x), [0, 0])
        XCTAssertEqual(walk.bands.map(\.y), [0, 2])
        XCTAssertEqual(walk.bands.map(\.width), [4, 4])
        XCTAssertEqual(walk.bands.map(\.height), [2, 1])
        XCTAssertEqual(walk.bands.map(\.payload), bands.map(\.payload))
    }

    /// A BitMap is only the "decompressor required" placeholder when it directly follows a band.
    func testPlaceholderWithoutPrecedingBandIsRefused() {
        let lone = akiPlaceholder(for: solidBand(x: 0, y: 0, width: 4, height: 3, red))
        let data = makeBandedQuickTimePICT(frameWidth: 4, frameHeight: 3, bands: [],
                                           extraOpsBeforeBands: lone)
        XCTAssertThrowsError(try PICT.quickTimeBands(data: data)) {
            XCTAssertEqual($0 as? PICT.DecodeError, .unsupportedOpcode(0x0098))
        }
    }

    /// A PixMap (rowBytes bit 15 SET) after a band is real pixels, not a placeholder → refused.
    func testPixMapAfterBandIsRefused() {
        let data = makeBandedQuickTimePICT(
            frameWidth: 4, frameHeight: 3, bands: twoBandFixture().bands,
            placeholder: { band in var p = akiPlaceholder(for: band); p[2] |= 0x80; return p })
        XCTAssertThrowsError(try PICT.quickTimeBands(data: data)) {
            XCTAssertEqual($0 as? PICT.DecodeError, .unsupportedOpcode(0x0098))
        }
    }

    /// 0x0030–0x0034 are skipped and RECORDED exactly as `PICT.init` does (orchestrator ruling
    /// 2026-10-03), and `decodeQuickTime` carries the record into the composite's `droppedPaintOps`.
    func testRectPaintOpIsSkippedAndRecordedInBandedWalk() throws {
        let data = makeBandedQuickTimePICT(frameWidth: 4, frameHeight: 3, bands: twoBandFixture().bands,
                                           extraOpsBeforeBands: [0x00, 0x30, 0, 0, 0, 0, 0, 0, 0, 0])
        let walk = try PICT.quickTimeBands(data: data)
        XCTAssertEqual(walk.droppedPaintOps, [0x0030])
        XCTAssertEqual(walk.bands.count, 2)
        let pict = try PICT.decodeQuickTime(data: data)
        XCTAssertEqual(pict.droppedPaintOps, [0x0030])
        XCTAssertEqual([pict.width, pict.height], [4, 3])
    }

    /// Raster pixels cannot be mixed into the codec composite → refused.
    func testRasterOpcodeIsRefusedInBandedWalk() {
        let data = makeBandedQuickTimePICT(frameWidth: 4, frameHeight: 3, bands: twoBandFixture().bands,
                                           extraOpsBeforeBands: [0x00, 0x9A])
        XCTAssertThrowsError(try PICT.quickTimeBands(data: data)) {
            XCTAssertEqual($0 as? PICT.DecodeError, .unsupportedOpcode(0x009A))
        }
    }

    /// Only a whole-pixel translation matrix is in the census; a scaled band is refused, not mis-placed.
    func testNonTranslationMatrixIsRefused() {
        var band = solidBand(x: 0, y: 0, width: 4, height: 3, red)
        band.matrixScale = 0x0002_0000                                  // 2.0
        let data = makeBandedQuickTimePICT(frameWidth: 4, frameHeight: 3, bands: [band])
        XCTAssertThrowsError(try PICT.quickTimeBands(data: data)) {
            XCTAssertEqual($0 as? PICT.DecodeError, .unsupportedOpcode(0x8200))
        }
    }

    /// Hostile-input posture: every strict prefix of a valid stream throws `.truncated` — never traps.
    func testEveryTruncationThrowsTruncated() {
        let data = twoBandFixture().data
        for n in 0..<data.count {
            XCTAssertThrowsError(try PICT.quickTimeBands(data: data.prefix(n)), "prefix \(n)") {
                XCTAssertEqual($0 as? PICT.DecodeError, .truncated, "prefix \(n)")
            }
        }
    }

    // MARK: - decodeQuickTime

    func testDecodeQuickTimeComposesBandsAtTheirOffsets() throws {
        let pict = try PICT.decodeQuickTime(data: twoBandFixture().data)
        XCTAssertEqual([pict.width, pict.height], [4, 3])
        XCTAssertEqual(pict.rgba.count, 4 * 3 * 4)
        XCTAssertEqual(pict.droppedPaintOps, [])
        XCTAssertEqual([UInt8](pict.rgba), solidRGBA(red, count: 8) + solidRGBA(blue, count: 4))
    }

    func testBandOutsideFrameThrows() {
        let data = makeBandedQuickTimePICT(frameWidth: 4, frameHeight: 3, bands: [
            solidBand(x: 0, y: 0, width: 4, height: 2, red),
            solidBand(x: 0, y: 3, width: 4, height: 1, blue),           // rows 3…3 of a 3-row frame
        ])
        XCTAssertThrowsError(try PICT.decodeQuickTime(data: data)) {
            XCTAssertEqual($0 as? PICT.DecodeError, .bandOutOfFrame)
        }
    }

    func testBandGapThrowsCoverage() {
        let data = makeBandedQuickTimePICT(frameWidth: 4, frameHeight: 4, bands: [
            solidBand(x: 0, y: 0, width: 4, height: 2, red),
            solidBand(x: 0, y: 2, width: 4, height: 1, blue),           // row 3 never painted
        ])
        XCTAssertThrowsError(try PICT.decodeQuickTime(data: data)) {
            XCTAssertEqual($0 as? PICT.DecodeError, .bandCoverage)
        }
    }

    /// Equal total area (8 + 4 = 12 = 4×3) but band 1 overlaps band 0's row 1 and leaves row 2 bare:
    /// the overlap check — not the area sum — must catch it.
    func testBandOverlapThrowsCoverage() {
        let data = makeBandedQuickTimePICT(frameWidth: 4, frameHeight: 3, bands: [
            solidBand(x: 0, y: 0, width: 4, height: 2, red),
            solidBand(x: 0, y: 1, width: 4, height: 1, blue),
        ])
        XCTAssertThrowsError(try PICT.decodeQuickTime(data: data)) {
            XCTAssertEqual($0 as? PICT.DecodeError, .bandCoverage)
        }
    }

    /// The ImageDescription says 4×2 but the payload decodes to 4×1 → the pixels do not tile the frame.
    func testDecodedSizeMismatchThrowsCoverage() {
        var band = solidBand(x: 0, y: 0, width: 4, height: 2, red)
        band.payload = makePNG(width: 4, height: 1, rgba: solidRGBA(red, count: 4))
        let data = makeBandedQuickTimePICT(frameWidth: 4, frameHeight: 3, bands: [
            band, solidBand(x: 0, y: 2, width: 4, height: 1, blue),
        ])
        XCTAssertThrowsError(try PICT.decodeQuickTime(data: data)) {
            XCTAssertEqual($0 as? PICT.DecodeError, .bandCoverage)
        }
    }

    func testUndecodablePayloadThrowsNotAnImage() {
        var band = solidBand(x: 0, y: 0, width: 4, height: 3, red)
        band.payload = Data(repeating: 0x5A, count: 40)
        let data = makeBandedQuickTimePICT(frameWidth: 4, frameHeight: 3, bands: [band])
        XCTAssertThrowsError(try PICT.decodeQuickTime(data: data)) {
            XCTAssertEqual($0 as? CodecImage.DecodeError, .notAnImage)
        }
    }

    // MARK: - The second game's QuickTime shape (data-gated, HECTORKIT_DATA_NOVA)

    /// EV's ship pic 5027 is CompressedQuickTime too, but NOT the banded shape: a 0x0032 paintRect
    /// precedes its 0x8200 and a pen/text-state + LongText "decompressor required" fallback follows it
    /// (0x0007 PnSize first). The banded walk records the paint op, reads the band, then refuses the
    /// fallback at 0x0007 (a boundary pinned, not a bug); the lifted extractor still reads its TIFF.
    func testEVShip5027StaysOutsideTheBandedWalk() throws {
        let ships = try novaFork("Override Ships")
        let res = try XCTUnwrap(ships.resource(type: "PICT", id: 5027), "PICT 5027 absent")
        XCTAssertThrowsError(try PICT.quickTimeBands(data: res.data)) {
            XCTAssertEqual($0 as? PICT.DecodeError, .unsupportedOpcode(0x0007))
        }
        XCTAssertEqual(try PICT.compressedQuickTimePayload(data: res.data).codec, "tiff")
    }
}
```

```sh
cd /Users/andiyar/Developer/HectorKit && swift test --filter PICTQuickTimeTests 2>&1 | grep -m1 -E "error:"
```

Expected: an `error: type 'PICT' has no member 'quickTimeBands'` (or `decodeQuickTime`) line (compile red).

- [ ] **Step 5.8 (green): Write `$HK/Sources/HectorGraphics/PICT+QuickTime.swift`:**

```swift
import Foundation

// MARK: - Banded CompressedQuickTime (0x8200) pictures (HectorKit D2, 2026-10-03)
//
// Aki - Mahjong Solitaire 1.1.0 ships 71 of its 82 PICTs in one exact shape (census 2026-10-03):
//   0x0011 · 0x0C00 · 0x00A1 LongComment (kind 498, 22 B "8BIM…") · 0x0001 Clip ·
//   N × [ 0x8200 CompressedQuickTime band · 0x0098 1-bit BitMap placeholder ] · 0x00FF
// Each band is a JPEG strip (ImageDescription width = frame width, height = band height) placed by
// its 3×3 matrix translation (tx, ty); the band heights tile the frame exactly. The BitMap after
// every band is QuickTime's "decompressor required" fallback image (69×44, rowBytes 10, high bit
// CLEAR) — it is parsed and SKIPPED, never drawn. Rect-paint ops (0x0030–0x0034) are skipped and
// RECORDED exactly as `PICT.init` does. EV's own QuickTime PICTs (ship pics 5027/5030) are a different
// shape: the walk gets past their 0x0032 (recorded) and their band, then refuses the pen/text-state +
// LongText "decompressor required" fallback at 0x0007 — they stay on `compressedQuickTimePayload`.

extension PICT {

    /// One 0x8200 CompressedQuickTime record: a codec image placed inside the picture frame.
    /// `x`/`y` are relative to the picFrame's top-left (matrix translation minus frame origin);
    /// `width`/`height` are the record's ImageDescription size; `payload` is the undecoded image.
    public struct QuickTimeBand: Sendable {
        public let codec: String
        public let width: Int
        public let height: Int
        public let x: Int
        public let y: Int
        public let payload: Data
    }

    /// Walk a whole PICT v2 stream whose image is carried by 0x8200 CompressedQuickTime records,
    /// returning the picFrame size, every band in stream order, how many 1-bit "decompressor
    /// required" placeholder BitMaps were skipped, and the rect-paint ops dropped (encounter order).
    ///
    /// Opcodes: the state/annotation ops `PICT.init` skips (0x0011 v2 only, 0x0C00, 0x0001, 0x001E,
    /// 0x001F, 0x00A0, 0x00A1); the 0x0030–0x0034 rect-paint ops, skipped and RECORDED exactly as
    /// `PICT.init` records them (HectorKit D2, orchestrator ruling 2026-10-03); 0x8200 (a band); a
    /// BitMap (0x0090/0x0098 with rowBytes bit 15 CLEAR) ONLY immediately after a band
    /// (parse-and-skip, counted); and 0x00FF. Everything else throws `unsupportedOpcode` — including
    /// raster PixMaps / DirectBits, which `PICT.init` decodes: there is no way to mix raster pixels
    /// into the codec composite, so the walk refuses (orchestrator ruling 2026-10-03). A band whose
    /// matrix is not a whole-pixel translation (scale 1.0, no shear, w = 1.0) throws
    /// `unsupportedOpcode(0x8200)`. Every read is bounds-checked: hostile input throws, never traps.
    public static func quickTimeBands(data: Data) throws
        -> (frame: (width: Int, height: Int), bands: [QuickTimeBand], skippedPlaceholders: Int,
            droppedPaintOps: [Int]) {
        var c = Cursor([UInt8](data))
        _ = try c.u16()                                 // picSize — ignored (we trust data.count)
        let top = try c.i16(), left = try c.i16(), bottom = try c.i16(), right = try c.i16()
        let w = right - left, h = bottom - top
        guard w > 0, h > 0 else { throw DecodeError.truncated }

        var bands: [QuickTimeBand] = []
        var skipped = 0
        var dropped: [Int] = []                         // 0x0030–0x0034 skipped, as PICT.init records them
        var previousWasBand = false
        loop: while true {
            c.align2()                                  // v2 opcodes are word-aligned
            let op = try c.u16()
            let followsBand = previousWasBand
            previousWasBand = false
            switch op {
            case 0x0011:                                // VersionOp: v2 = 0x02 0xFF
                let v = try c.u8(); _ = try c.u8()
                guard v == 0x02 else { throw DecodeError.notV2 }
            case 0x0C00:                                // HeaderOp
                try c.skip(24)
            case 0x0001:                                // Clip: size-prefixed region (size incl. itself)
                let size = try c.u16()
                guard size >= 2 else { throw DecodeError.truncated }
                try c.skip(size - 2)
            case 0x001E:                                // DefHilite: zero-data state op
                break
            case 0x001F:                                // OpColor: RGBColor (3×u16)
                try c.skip(6)
            case 0x00A0:                                // ShortComment: kind (u16)
                try c.skip(2)
            case 0x00A1:                                // LongComment: kind (u16) + size (u16) + size bytes
                _ = try c.u16()
                let size = try c.u16()
                try c.skip(size)
            case 0x0030, 0x0031, 0x0032, 0x0033, 0x0034:  // frame/paint/erase/invert/fill Rect: rect (4×i16).
                try c.skip(8)                           // DROPS the painted rect (cosmetic) — record it.
                dropped.append(op)
            case 0x8200:                                // CompressedQuickTime: one band
                bands.append(try readQuickTimeBand(&c, frameTop: top, frameLeft: left))
                previousWasBand = true
            case 0x0090, 0x0098:                        // BitsRect / PackBitsRect: the band's placeholder
                guard followsBand else { throw DecodeError.unsupportedOpcode(op) }
                try skipPlaceholderBitMap(&c, op: op)
                skipped += 1
            case 0x00FF:                                // EndOfPicture
                break loop
            default:
                throw DecodeError.unsupportedOpcode(op)
            }
        }
        return (frame: (width: w, height: h), bands: bands, skippedPlaceholders: skipped,
                droppedPaintOps: dropped)
    }

    /// Decode a banded CompressedQuickTime PICT to a frame-sized RGBA image: walk it with
    /// `quickTimeBands`, check the bands tile the frame exactly, decode each band's payload with
    /// `CodecImage`, and copy it in at (x, y). `droppedPaintOps` is the walk's record of the
    /// 0x0030–0x0034 rect-paint ops it skipped (the same never-silent disclosure `PICT.init` makes).
    ///
    /// Throws `DecodeError.bandOutOfFrame` if a band reaches outside the frame, and
    /// `DecodeError.bandCoverage` if the bands leave a gap, overlap, or decode to a size other than
    /// the one their ImageDescription declares; `CodecImage.DecodeError.notAnImage` if a payload
    /// is not an image. Every band is decoded BEFORE the frame buffer is allocated, so a hostile
    /// frame size never allocates on its own. RGBA is CodecImage's (premultiplied; JPEG is opaque).
    public static func decodeQuickTime(data: Data) throws -> PICT {
        let walk = try quickTimeBands(data: data)
        let w = walk.frame.width, h = walk.frame.height
        for b in walk.bands where b.x < 0 || b.y < 0 || b.x + b.width > w || b.y + b.height > h {
            throw DecodeError.bandOutOfFrame
        }
        var area = 0
        for (i, a) in walk.bands.enumerated() {
            area += a.width * a.height
            for b in walk.bands[(i + 1)...]
            where a.x < b.x + b.width && b.x < a.x + a.width && a.y < b.y + b.height && b.y < a.y + a.height {
                throw DecodeError.bandCoverage            // two bands overlap
            }
        }
        guard area == w * h else { throw DecodeError.bandCoverage }   // a gap (or no bands at all)

        var decoded: [(band: QuickTimeBand, rgba: [UInt8])] = []
        for b in walk.bands {
            let image = try CodecImage.decode(b.payload)
            guard image.width == b.width, image.height == b.height else { throw DecodeError.bandCoverage }
            decoded.append((band: b, rgba: [UInt8](image.rgba)))
        }
        var out = [UInt8](repeating: 0, count: w * h * 4)
        for (b, px) in decoded {
            let rowLength = b.width * 4
            for row in 0..<b.height {
                let src = row * rowLength
                let dst = ((b.y + row) * w + b.x) * 4
                out.replaceSubrange(dst..<dst + rowLength, with: px[src..<src + rowLength])
            }
        }
        return PICT(width: w, height: h, rgba: Data(out), droppedPaintOps: walk.droppedPaintOps)
    }

    /// Memberwise initialiser for this module's decoders (`init(data:)` suppresses the synthesised one).
    init(width: Int, height: Int, rgba: Data, droppedPaintOps: [Int]) {
        self.width = width
        self.height = height
        self.rgba = rgba
        self.droppedPaintOps = droppedPaintOps
    }

    /// One 0x8200 record, cursor just past the opcode. Layout (QuickTime CompressedData → Image
    /// Description, big-endian; see `compressedQuickTimePayload`): opSize u32, then 68 fixed bytes —
    /// version u16, matrix 9×u32, matteSize u32, matteRect 8, mode u16, srcRect 8, accuracy u32,
    /// maskSize u32 — then matte + mask data, the ImageDescription (idSize u32 @0, cType @4,
    /// width/height i16 @32/@34, dataSize u32 @44), the payload, and pad. `opSize` is authoritative
    /// for where the next opcode starts (Aki rounds it up to even, covering the pad byte).
    private static func readQuickTimeBand(_ c: inout Cursor, frameTop: Int, frameLeft: Int) throws -> QuickTimeBand {
        let opSize = try c.u32()
        let recordStart = c.pos
        guard opSize >= 68, recordStart + opSize <= c.bytes.count else { throw DecodeError.truncated }
        let recordEnd = recordStart + opSize
        _ = try c.u16()                                 // version
        var m: [Int] = []
        for _ in 0..<9 { m.append(Int(Int32(bitPattern: UInt32(try c.u32())))) }
        // [a b u; c d v; tx ty w]: a, d Fixed 16.16; u, v, w Fract 2.30; tx, ty Fixed 16.16.
        guard m[0] == 0x0001_0000, m[1] == 0, m[2] == 0,
              m[3] == 0, m[4] == 0x0001_0000, m[5] == 0,
              m[6] & 0xFFFF == 0, m[7] & 0xFFFF == 0, m[8] == 0x4000_0000 else {
            throw DecodeError.unsupportedOpcode(0x8200)   // not a whole-pixel translation
        }
        let matteSize = try c.u32()
        try c.skip(8)                                   // matteRect
        _ = try c.u16()                                 // mode
        try c.skip(8)                                   // srcRect
        _ = try c.u32()                                 // accuracy
        let maskSize = try c.u32()
        try c.skip(matteSize)                           // matte data
        try c.skip(maskSize)                            // mask data
        let idSize = try c.u32()                        // ImageDescription @0
        let cType = try c.take(4)                       // @4 fourcc
        try c.skip(24)                                  // @8 → @32
        let width = try c.i16()                         // @32
        let height = try c.i16()                        // @34
        try c.skip(8)                                   // @36 → @44 (hRes/vRes)
        let dataSize = try c.u32()                      // @44
        guard idSize >= 48, width > 0, height > 0 else { throw DecodeError.truncated }
        try c.skip(idSize - 48)                         // @48 → end of ImageDescription
        guard c.pos + dataSize <= recordEnd else { throw DecodeError.truncated }
        let payload = try c.take(dataSize)
        c.pos = recordEnd
        let codec = String(cType.map { Character(UnicodeScalar($0)) })
        return QuickTimeBand(codec: codec, width: width, height: height,
                             x: (m[6] >> 16) - frameLeft, y: (m[7] >> 16) - frameTop,
                             payload: Data(payload))
    }

    /// The 1-bit BitMap QuickTime writes after each band (cursor just past the opcode): rowBytes u16
    /// (bit 15 CLEAR — a PixMap is real pixels and is refused), bounds, srcRect, dstRect, mode, then
    /// bounds-height rows — raw `rowBytes` bytes per row for 0x0090 or rowBytes < 8, else a u8
    /// (rowBytes ≤ 250) / u16 byte count and that many PackBits bytes. Skipped, never unpacked.
    private static func skipPlaceholderBitMap(_ c: inout Cursor, op: Int) throws {
        let rowBytesRaw = try c.u16()
        guard rowBytesRaw & 0x8000 == 0 else { throw DecodeError.unsupportedOpcode(op) }
        let rowBytes = rowBytesRaw & 0x7FFF
        let boundsTop = try c.i16(); _ = try c.i16()
        let boundsBottom = try c.i16(); _ = try c.i16()
        let rows = boundsBottom - boundsTop
        guard rows > 0 else { throw DecodeError.truncated }
        try c.skip(8); try c.skip(8); _ = try c.u16()   // srcRect, dstRect, mode
        for _ in 0..<rows {
            if op == 0x0090 || rowBytes < 8 {
                try c.skip(rowBytes)
            } else {
                let byteCount = rowBytes > 250 ? try c.u16() : try c.u8()
                try c.skip(byteCount)
            }
        }
    }
}
```

```sh
cd /Users/andiyar/Developer/HectorKit && HECTORKIT_DATA_NOVA=/Users/andiyar/Developer/Ambrosia/data/nova \
  swift test --filter 'PICTQuickTimeTests|CodecImageTests' > /tmp/hk-t5-8.log 2>&1
grep -E 'Executed [0-9]+ tests?, with' /tmp/hk-t5-8.log | grep -v 'Executed 0 tests' | tail -n 1
grep -cE "^Test Case '.*' (failed|skipped) \(" /tmp/hk-t5-8.log
```

Expected: `Executed 20 tests, with 0 failures (0 unexpected) in …` and `0`.

- [ ] **Step 5.9: Commit (no push yet).**

```sh
HK=/Users/andiyar/Developer/HectorKit
git -C "$HK" add "Sources/HectorGraphics/PICT+QuickTime.swift" Sources/HectorGraphics/PICT.swift Tests/HectorGraphicsTests/PICTQuickTimeTests.swift
git -C "$HK" commit -F - <<'EOF'
HectorGraphics: PICT.quickTimeBands + PICT.decodeQuickTime (banded QuickTime, D2)

Walks the whole stream: every 0x8200 band (whole-pixel matrix translation), the 1-bit
"decompressor required" BitMap after each band parsed-and-skipped and counted, rect-paint ops
skipped and recorded as PICT.init does (droppedPaintOps); raster ops and anything else throw.
decodeQuickTime checks the bands tile the frame (bandOutOfFrame / bandCoverage), decodes each with
CodecImage, composites, carries droppedPaintOps. PICT.init still throws unsupportedOpcode(0x8200).
EV ship 5027 pinned as outside the banded walk (refused at its 0x0007 pen/text fallback).

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>
EOF
git -C "$HK" status --porcelain | grep -v '^??'
```

- [ ] **Step 5.10: Mutation evidence** (each mutant must turn exactly one named test red; then restore and
  prove the file is back to the committed bytes).

```sh
HK=/Users/andiyar/Developer/HectorKit; F="$HK/Sources/HectorGraphics/PICT+QuickTime.swift"
cd "$HK"
run() { HECTORKIT_DATA_NOVA=/Users/andiyar/Developer/Ambrosia/data/nova swift test --filter PICTQuickTimeTests > /tmp/hk-mut.log 2>&1
        grep -oE 'PICTQuickTimeTests test[A-Za-z0-9]+\] : ' /tmp/hk-mut.log | sort -u
        grep -E 'Executed [0-9]+ tests?, with' /tmp/hk-mut.log | grep -v 'Executed 0 tests' | tail -n 1; }
# M1 — overlap check disabled
sed -i '' 's|throw DecodeError.bandCoverage            // two bands overlap|continue                                  // MUTANT M1|' "$F"; run; git checkout -- "$F"
# M2 — bands composited at row 0 instead of y
sed -i '' 's|let dst = ((b.y + row) \* w + b.x) \* 4|let dst = (row * w + b.x) * 4|' "$F"; run; git checkout -- "$F"
# M3 — placeholder accepted without a preceding band
sed -i '' 's|guard followsBand else|guard true else|' "$F"; run; git checkout -- "$F"
git diff --quiet -- "$F" && echo "restored"
```

Expected, in order: M1 → `PICTQuickTimeTests testBandOverlapThrowsCoverage] : ` and
`Executed 16 tests, with 1 failure (0 unexpected) …`; M2 → `PICTQuickTimeTests testDecodeQuickTimeComposesBandsAtTheirOffsets] : `
and `Executed 16 tests, with 1 failure …`; M3 → `PICTQuickTimeTests testPlaceholderWithoutPrecedingBandIsRefused] : `
and `Executed 16 tests, with 1 failure …`; then `restored`. (M3 also draws a "will never be executed" warning.)
(`git checkout -- <file>` restores the committed version of that one file — it is the Step 5.9 commit.)

- [ ] **Step 5.11: Floor 89 → 109** (Edit tool, exact strings). In `$HK/tools/check-zero-skip.sh` replace

```
FLOOR=89   # recorded zero-skip floor: "Executed N tests" of the last green run
```

with

```
FLOOR=109   # recorded zero-skip floor: "Executed N tests" of the last green run
```

In `$HK/docs/STATE.md` replace `**floor 89** (2026-10-03)` with `**floor 109** (2026-10-03)`, and replace

```
1. Phase 0 Task 5: banded QuickTime PICTs (D2) — `quickTimeBands`, `CodecImage`, `decodeQuickTime`.
```

with

```
1. Phase 0 Task 5 done: banded QuickTime PICTs (D2) — `quickTimeBands`, `CodecImage`, `decodeQuickTime`.
```

```sh
/Users/andiyar/Developer/HectorKit/tools/check-zero-skip.sh 2>&1 | tail -n 1
```

Expected: `PASS: zero skips, zero failures, executed 109 == floor 109`.

- [ ] **Step 5.12: Commit + push all of Task 5.**

```sh
HK=/Users/andiyar/Developer/HectorKit
git -C "$HK" add tools/check-zero-skip.sh docs/STATE.md
git -C "$HK" commit -F - <<'EOF'
check-zero-skip: floor 109 (banded QuickTime + CodecImage tests)

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>
EOF
git -C "$HK" status --porcelain | grep -v '^??'; git -C "$HK" push origin main
```

- **Verify:** 5.2/5.4/5.7 red as stated; 5.3/5.5/5.8 green as stated; 5.10 three single-test reds + `restored`;
  5.11 PASS at 109. **Then STOP for the two review legs.**

---

### Task 6 — Aki 1.1.0 PICT census in the kit (→ 112 tests, final floor)

**Files:**
- Create: `$HK/Tests/HectorGraphicsTests/AkiPICTCensusTests.swift`
- Modify: `$HK/tools/check-zero-skip.sh` (`FLOOR=109` → `FLOOR=112`), `$HK/docs/STATE.md`

- [ ] **Step 6.1: Write `$HK/Tests/HectorGraphicsTests/AkiPICTCensusTests.swift`:**

```swift
import XCTest
import Foundation
import HectorResources
@testable import HectorGraphics
import HectorTestSupport

/// Real-data census of the second game's PICTs (design §2 rule: a decoder is "general" only after a
/// census against ≥2 games' real data). Aki - Mahjong Solitaire 1.1.0 keeps all its art in ONE
/// data-fork classic resource file; every one of its 82 PICTs must decode to its own picFrame:
/// 11 raw DirectBitsRect through `PICT(data:)`, 71 banded QuickTime-JPEG through
/// `PICT.decodeQuickTime(data:)`. Data-gated on HECTORKIT_DATA_AKI11 (the 1.1.0 Contents/Resources).
/// Numbers are the 2026-10-03 opcode-stream census (HectorKit D2). Lives in the kit's tests, not the
/// library: no HectorKit TYPE knows the word "Aki".
final class AkiPICTCensusTests: XCTestCase {

    private static let resourceFileName = "Aki - Mahjong Solitaire.rsrc"

    private func akiCollection() throws -> ResourceCollection {
        let url = try HectorData.file(Self.resourceFileName, in: HectorData.aki11Var)
        return try XCTUnwrap(try ResourceReader.read(fileAt: url), "\(Self.resourceFileName) is not a resource container")
    }

    /// picFrame (width, height) straight from the PICT header: picSize u16 @0, then top/left/bottom/right i16.
    private func picFrame(_ data: Data) throws -> (width: Int, height: Int) {
        let b = [UInt8](data)
        guard b.count >= 10 else { throw PICT.DecodeError.truncated }
        func i16(_ o: Int) -> Int { Int(Int16(bitPattern: UInt16(b[o]) << 8 | UInt16(b[o + 1]))) }
        return (width: i16(8) - i16(4), height: i16(6) - i16(2))
    }

    func testResourceFileTypeCounts() throws {
        let c = try akiCollection()
        XCTAssertEqual(c.count, 124)
        XCTAssertEqual(c.resources(of: "PICT").count, 82)
        XCTAssertEqual(c.resources(of: "snd ").count, 0, "Aki's sounds are loose AIFF/MP3 files")
        let byType = Dictionary(uniqueKeysWithValues: c.counts().map { ($0.type, $0.count) })
        XCTAssertEqual(byType, ["CHNK": 1, "STR ": 4, "PICT": 82, "pnot": 1, "icns": 1,
                                "8BIM": 33, "TEXT": 1, "ANPA": 1])
    }

    func testEveryPICTDecodesToItsFrame() throws {
        let c = try akiCollection()
        var raw: [Int16: [Int]] = [:]
        var quickTime = 0
        for res in c.resources(of: "PICT") {
            let frame = try picFrame(res.data)
            do {
                let pict = try PICT(data: res.data)
                XCTAssertEqual([pict.width, pict.height], [frame.width, frame.height], "PICT \(res.id) raw")
                XCTAssertEqual(pict.rgba.count, pict.width * pict.height * 4, "PICT \(res.id) raw rgba")
                raw[res.id] = [pict.width, pict.height]
            } catch PICT.DecodeError.unsupportedOpcode(let op) where op == 0x8200 {
                do {
                    let pict = try PICT.decodeQuickTime(data: res.data)
                    XCTAssertEqual([pict.width, pict.height], [frame.width, frame.height], "PICT \(res.id) QuickTime")
                    XCTAssertEqual(pict.rgba.count, frame.width * frame.height * 4, "PICT \(res.id) QuickTime rgba")
                    XCTAssertEqual(pict.droppedPaintOps, [], "PICT \(res.id)")
                    quickTime += 1
                } catch {
                    XCTFail("PICT \(res.id): decodeQuickTime threw \(error)")
                }
            } catch {
                XCTFail("PICT \(res.id): PICT(data:) threw \(error)")
            }
        }
        XCTAssertEqual(raw.count, 11, "raw DirectBitsRect PICTs")
        XCTAssertEqual(quickTime, 71, "banded QuickTime PICTs")
        XCTAssertEqual(raw, [128: [467, 468], 129: [53, 1104], 131: [39, 2100], 133: [132, 144],
                             134: [416, 480], 168: [416, 480], 314: [240, 150],             // 16-bit
                             135: [2358, 68], 5591: [128, 4], 8715: [2, 128], 23098: [14, 128]])   // 32-bit
        // (135 is cmpCount 4: its leading alpha plane is real and decodes into rgba's A channel.)
    }

    func testQuickTimeBandStructureMatchesTheCensus() throws {
        let c = try akiCollection()
        var bandsPerPICT: [Int: Int] = [:]                      // band count → number of PICTs
        for res in c.resources(of: "PICT") where (try? PICT(data: res.data)) == nil {
            let walk = try PICT.quickTimeBands(data: res.data)
            bandsPerPICT[walk.bands.count, default: 0] += 1
            XCTAssertEqual(walk.skippedPlaceholders, walk.bands.count, "PICT \(res.id): one placeholder per band")
            XCTAssertEqual(Set(walk.bands.map(\.codec)), ["jpeg"], "PICT \(res.id) codecs")
            XCTAssertTrue(walk.bands.allSatisfy { $0.x == 0 && $0.width == walk.frame.width }, "PICT \(res.id) full-width strips")
            XCTAssertEqual(walk.bands.map(\.height).reduce(0, +), walk.frame.height, "PICT \(res.id) heights tile the frame")
            // The fixed lifted extractor now reaches every Aki QuickTime PICT and returns band 0.
            XCTAssertEqual(try PICT.compressedQuickTimePayload(data: res.data).payload, walk.bands[0].payload,
                           "PICT \(res.id) first band")
        }
        XCTAssertEqual(bandsPerPICT, [1: 45, 2: 5, 4: 20, 6: 1])

        func bands(_ id: Int16) throws -> [PICT.QuickTimeBand] {
            try PICT.quickTimeBands(data: XCTUnwrap(c.resource(type: "PICT", id: id), "PICT \(id)").data).bands
        }
        XCTAssertEqual(try bands(140).map(\.y), [0, 160, 320, 480])           // 800×600 background
        XCTAssertEqual(try bands(140).map(\.height), [160, 160, 160, 120])
        XCTAssertEqual(try bands(130).map(\.height), [320, 320, 320, 320, 320, 127])   // 392×1727
        XCTAssertEqual(try bands(132).map(\.height), [544, 544, 544, 540])     // 237×2172
        XCTAssertEqual(try bands(306).map(\.height), [181])                    // 237×181 preview
    }
}
```

- [ ] **Step 6.2: Run it without and with the variable.**

```sh
cd /Users/andiyar/Developer/HectorKit
env -u HECTORKIT_DATA_AKI11 swift test --filter AkiPICTCensusTests > /tmp/hk-t6-nodata.log 2>&1
grep -E 'Executed [0-9]+ tests?, with' /tmp/hk-t6-nodata.log | grep -v 'Executed 0 tests' | tail -n 1; grep -c "HECTORKIT_DATA_AKI11 is not set" /tmp/hk-t6-nodata.log
HECTORKIT_DATA_AKI11="/Users/andiyar/Developer/Ambrosia/Aki/Aki - Mahjong Solitaire/Aki - Mahjong Solitaire.app/Contents/Resources" \
  swift test --filter AkiPICTCensusTests 2>&1 | grep -E 'Executed [0-9]+ tests?, with' | grep -v 'Executed 0 tests' | tail -n 1
```

Expected: `Executed 3 tests, with 3 tests skipped and 0 failures (0 unexpected) …`, a count ≥ 3 (each skip
names `HECTORKIT_DATA_AKI11`); then `Executed 3 tests, with 0 failures (0 unexpected) in …` (G2).

- [ ] **Step 6.3: Floor 109 → 112** (Edit tool, exact strings). In `$HK/tools/check-zero-skip.sh` replace

```
FLOOR=109   # recorded zero-skip floor: "Executed N tests" of the last green run
```

with

```
FLOOR=112   # recorded zero-skip floor: "Executed N tests" of the last green run
```

In `$HK/docs/STATE.md` replace `**floor 109** (2026-10-03)` with `**floor 112** (2026-10-03)`, and replace

```
2. Phase 0 Task 6: Aki 1.1.0 PICT census test; then tag `v0.1.0`.
```

with

```
2. Phase 0 Task 6 done: all 82 Aki 1.1.0 PICTs decode to their frames (11 raw, 71 QuickTime); tag `v0.1.0` next.
```

```sh
/Users/andiyar/Developer/HectorKit/tools/check-zero-skip.sh 2>&1 | tail -n 1
```

Expected: `PASS: zero skips, zero failures, executed 112 == floor 112` (G1).

- [ ] **Commit + push:**

```sh
HK=/Users/andiyar/Developer/HectorKit
git -C "$HK" add Tests/HectorGraphicsTests/AkiPICTCensusTests.swift tools/check-zero-skip.sh docs/STATE.md
git -C "$HK" commit -F - <<'EOF'
AkiPICTCensusTests: all 82 Aki 1.1.0 PICTs decode to their frames (11 raw / 71 QuickTime); floor 112

The second game's census (design §2 rule): 124 resources, 82 PICT, 0 snd; raw per-id sizes; band
histogram 1x45 2x5 4x20 6x1; compressedQuickTimePayload == band 0 on all 71. HECTORKIT_DATA_AKI11.

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>
EOF
git -C "$HK" status --porcelain | grep -v '^??'; git -C "$HK" push origin main
```

---

### Task 7 — Ambrosia-Classics: `Aki/Core` package, `AkiBundle`, census tests, `aki-census`, census doc

**Files (all under `$WT`):**
- Create: `Aki/Core/Package.swift` (stage 7a, then 7b), `Aki/Core/Sources/AkiCore/AkiBundle.swift`,
  `Aki/Core/Tests/AkiCoreTests/AkiCensusTests.swift`, `Aki/Core/Sources/aki-census/AkiCensus.swift`,
  `docs/aki/data-census.md`

- [ ] **Step 7.1: `Aki/Core/Package.swift` stage 7a** (library + tests only — no executable yet, Invariant 10):

```swift
// swift-tools-version: 6.0
import PackageDescription

// Aki — Mahjong Solitaire core (game logic + data loading) on HectorKit. Phase 0 holds only the
// shipped-bundle locator and the data-census tool; game logic arrives in Phase 2.
// HectorKit is a LOCAL path dependency during build-out (design §3): from Aki/Core, three levels
// up is the directory that holds both repos (in a worktree session: the .claude/worktrees/HectorKit
// symlink — docs/DECISIONS.md D1).
let package = Package(
    name: "AkiCore",
    platforms: [.macOS(.v15)],
    products: [
        .library(name: "AkiCore", targets: ["AkiCore"]),
    ],
    dependencies: [
        .package(path: "../../../HectorKit"),
    ],
    targets: [
        .target(name: "AkiCore"),
        .testTarget(name: "AkiCoreTests", dependencies: [
            "AkiCore",
            .product(name: "HectorResources", package: "HectorKit"),
            .product(name: "HectorGraphics", package: "HectorKit"),
        ]),
    ]
)
```

- [ ] **Step 7.2 (red): Write `Aki/Core/Tests/AkiCoreTests/AkiCensusTests.swift`:**

```swift
import AVFoundation
import AkiCore
import Foundation
import HectorGraphics
import HectorResources
import XCTest

/// An Aki `Contents/Resources` folder for the data-gated census tests: env var `variable` if set,
/// else the repo's git-ignored symlink `Resources/Aki/<app>/Contents/Resources` (docs/DECISIONS.md
/// D1). XCTSkip — naming the variable — when neither exists.
private func akiResources(_ variable: String, defaultApp app: String) throws -> URL {
    var repo = URL(fileURLWithPath: #filePath)                 // …/Aki/Core/Tests/AkiCoreTests/<file>
    for _ in 0..<5 { repo.deleteLastPathComponent() }          // → the repo (or worktree) root
    let env = ProcessInfo.processInfo.environment[variable].flatMap { $0.isEmpty ? nil : $0 }
    let path = env ?? repo.appendingPathComponent("Resources/Aki/\(app)/Contents/Resources").path
    let url = URL(fileURLWithPath: path).resolvingSymlinksInPath()
    var isDirectory: ObjCBool = false
    guard FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory), isDirectory.boolValue else {
        if let env { throw XCTSkip("\(variable)=\(env) is not a directory") }
        throw XCTSkip("\(variable) unset and the default \(path) is absent — set \(variable) to an Aki Contents/Resources folder")
    }
    return url
}

private func aki11() throws -> AkiBundle {
    try AkiBundle(resourcesURL: akiResources("AKI_DATA_11", defaultApp: "1.1.0.app"))
}
private func aki12() throws -> AkiBundle {
    try AkiBundle(resourcesURL: akiResources("AKI_DATA_12", defaultApp: "1.2.0.app"))
}

/// Phase 0 census pins (docs/aki/data-census.md is the human-readable twin, from `aki-census`).
final class AkiCensusTests: XCTestCase {

    // MARK: - AkiBundle (synthetic, always on)

    func testBundleListsResourceAudioAndPNGSortedByName() throws {
        let dir = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("aki-bundle-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: dir) }
        for name in ["b.png", "a.png", "z.mp3", "Y.aiff", "game.rsrc", "notes.txt", "icon.icns"] {
            try Data([0]).write(to: dir.appendingPathComponent(name))
        }
        let bundle = try AkiBundle(resourcesURL: dir)
        XCTAssertEqual(bundle.resourceFile?.lastPathComponent, "game.rsrc")
        XCTAssertEqual(bundle.audioFiles.map(\.lastPathComponent), ["Y.aiff", "z.mp3"])
        XCTAssertEqual(bundle.pngFiles.map(\.lastPathComponent), ["a.png", "b.png"])
    }

    // MARK: - 1.1.0: 82 PICTs, all to their frames

    func testAki11EveryPICTDecodesToItsFrame() throws {
        let bundle = try aki11()
        let rsrc = try XCTUnwrap(bundle.resourceFile, "1.1.0 ships a .rsrc")
        XCTAssertEqual(rsrc.lastPathComponent, "Aki - Mahjong Solitaire.rsrc")
        let collection = try XCTUnwrap(try ResourceReader.read(fileAt: rsrc))
        let picts = collection.resources(of: "PICT")
        XCTAssertEqual(picts.count, 82)
        var raw = 0, quickTime = 0
        for res in picts {
            let b = [UInt8](res.data)
            func i16(_ o: Int) -> Int { Int(Int16(bitPattern: UInt16(b[o]) << 8 | UInt16(b[o + 1]))) }
            let frame = [i16(8) - i16(4), i16(6) - i16(2)]          // right−left, bottom−top
            let pict: PICT
            do {
                pict = try PICT(data: res.data); raw += 1
            } catch PICT.DecodeError.unsupportedOpcode(let op) where op == 0x8200 {
                pict = try PICT.decodeQuickTime(data: res.data); quickTime += 1
            }
            XCTAssertEqual([pict.width, pict.height], frame, "PICT \(res.id)")
            XCTAssertEqual(pict.rgba.count, frame[0] * frame[1] * 4, "PICT \(res.id)")
        }
        XCTAssertEqual([raw, quickTime], [11, 71])
    }

    /// The composite is not just the right SIZE: 1.2.0 re-shipped the same art as PNG, and each
    /// decoded 1.1.0 QuickTime composite sits within a mean |ΔRGB| of 6 (0–255) of its 1.2.0 twin —
    /// measured 2026-10-03: 140 1.77 (this ImageIO path; 1.78 with PIL), 130 2.53, 132 4.98, 164 3.02,
    /// 315 0.04; swapping two bands of 140 costs 30.0, of 130 10.5.
    func testAki11QuickTimeCompositesMatchTheirAki12PNGs() throws {
        // Un-nested on purpose: XCTUnwrap records an error thrown inside its autoclosure (an XCTSkip
        // from the locator) as a FAILURE before rethrowing — call the skipping locator outside it.
        let bundle = try aki11()
        let rsrc = try XCTUnwrap(bundle.resourceFile, "1.1.0 ships a .rsrc")
        let collection = try XCTUnwrap(try ResourceReader.read(fileAt: rsrc))
        let pngDir = try akiResources("AKI_DATA_12", defaultApp: "1.2.0.app")
        let twins: [(id: Int16, png: String)] = [(140, "background7.png"), (130, "proverbs.png"),
                                                 (132, "previews.png"), (164, "map.png"), (315, "paper.png")]
        for twin in twins {
            let res = try XCTUnwrap(collection.resource(type: "PICT", id: twin.id), "PICT \(twin.id)")
            let pict = try PICT.decodeQuickTime(data: res.data)
            let png = try CodecImage.decode(Data(contentsOf: pngDir.appendingPathComponent(twin.png)))
            XCTAssertEqual([png.width, png.height], [pict.width, pict.height], twin.png)
            let a = [UInt8](pict.rgba), b = [UInt8](png.rgba)
            var sum = 0
            for i in stride(from: 0, to: a.count, by: 4) {
                sum += abs(Int(a[i]) - Int(b[i])) + abs(Int(a[i + 1]) - Int(b[i + 1])) + abs(Int(a[i + 2]) - Int(b[i + 2]))
            }
            let meanDiff = Double(sum) / Double(a.count / 4 * 3)
            XCTAssertLessThan(meanDiff, 6.0, "PICT \(twin.id) vs \(twin.png)")
        }
    }

    // MARK: - 1.2.0: 50 PNGs, all to their sizes

    func testAki12EveryPNGDecodesToItsSize() throws {
        let bundle = try aki12()
        XCTAssertNil(bundle.resourceFile, "1.2.0 ships no .rsrc")
        var expected: [String: [Int]] = [
            "arrow.png": [132, 144], "buyaki.png": [800, 600], "guide.png": [440, 503],
            "layer_buttons.png": [224, 260], "map.png": [800, 600], "misc.png": [467, 468],
            "nopairs.png": [416, 480], "notavail.png": [240, 150], "paper.png": [420, 338],
            "pause.png": [416, 480], "plate.png": [2358, 68], "previews.png": [237, 2172],
            "proverbs.png": [392, 1727], "tile_pictures.png": [39, 2100], "tiles.png": [53, 1104],
            "welcome.png": [523, 338],
        ]
        for n in 1...17 {
            expected["background\(n).png"] = [800, 600]
            expected["preview\(n).png"] = [237, 181]
        }
        XCTAssertEqual(expected.count, 50)
        var decoded: [String: [Int]] = [:]
        for url in bundle.pngFiles {
            let image = try CodecImage.decode(Data(contentsOf: url))
            XCTAssertEqual(image.rgba.count, image.width * image.height * 4, url.lastPathComponent)
            decoded[url.lastPathComponent] = [image.width, image.height]
        }
        XCTAssertEqual(decoded, expected)
    }

    // MARK: - Audio: every shipped AIFF/MP3 opens (44.1 kHz; channel count per file per afinfo)

    private func assertAudioOpens(_ bundle: AkiBundle, channels expected: [String: Int],
                                  file: StaticString = #filePath, line: UInt = #line) throws {
        var seen: [String: Int] = [:]
        for url in bundle.audioFiles {
            let audio = try AVAudioFile(forReading: url)
            XCTAssertEqual(audio.fileFormat.sampleRate, 44_100, url.lastPathComponent, file: file, line: line)
            XCTAssertGreaterThan(audio.length, 0, url.lastPathComponent, file: file, line: line)
            seen[url.lastPathComponent] = Int(audio.fileFormat.channelCount)
        }
        XCTAssertEqual(seen, expected, file: file, line: line)
    }

    func testAki11AudioFilesOpen() throws {
        try assertAudioOpens(aki11(), channels: [
            "Aki Theme 1.mp3": 2, "Aki Theme 2.mp3": 2, "Aki Theme 3.mp3": 2, "GameOver.aiff": 2,
            "LevelComplete.aiff": 2, "LevelStart.aiff": 2, "Preview.aiff": 1, "Reshuffle.aiff": 2,
            "TileMatch.aiff": 1, "cancel.aiff": 1, "chime.aiff": 1, "tick.mp3": 1,
            "tilehit.aiff": 2, "unclick.aiff": 2,
        ])
    }

    func testAki12AudioFilesOpen() throws {
        try assertAudioOpens(aki12(), channels: [
            "Aki Theme 1.mp3": 2, "Aki Theme 2.mp3": 2, "Aki Theme 3.mp3": 2, "GameOver.aiff": 2,
            "LevelComplete.aiff": 2, "LevelStart.aiff": 2, "Preview.aiff": 1, "Reshuffle.aiff": 2,
            "TileMatch.aiff": 1, "cancel.aiff": 1, "chime.aiff": 1, "tick.aiff": 1, "tick.mp3": 1,
            "tilehit.mp3": 2, "unclick.aiff": 2,
        ])
    }
}
```

```sh
WT=/Users/andiyar/Developer/Ambrosia-Classics/.claude/worktrees/dazzling-chebyshev-e403ce
cd "$WT/Aki/Core" && swift test 2>&1 | grep -m1 -E "error:"
```

Expected: the command fails with an `error:` naming target `AkiCore` (it has no sources yet) — the red.

- [ ] **Step 7.3 (green): Write `Aki/Core/Sources/AkiCore/AkiBundle.swift`:**

```swift
import Foundation

/// One shipped Aki - Mahjong Solitaire `Contents/Resources` folder (1.1.0 Carbon or 1.2.0 Cocoa),
/// as the files lie on disk — the shipped bundle layout IS the data format (design §4).
public struct AkiBundle: Sendable {
    /// The data-fork classic resource file (`*.rsrc`): 1.1.0 ships `Aki - Mahjong Solitaire.rsrc`
    /// (124 resources, 82 PICT); 1.2.0 ships none (its art is loose PNGs) → nil.
    public let resourceFile: URL?
    /// Every `.aiff` and `.mp3` directly in the folder, sorted by file name.
    public let audioFiles: [URL]
    /// Every `.png` directly in the folder, sorted by file name.
    public let pngFiles: [URL]

    /// Lists `resourcesURL` (not recursive). Throws if the folder cannot be read.
    public init(resourcesURL: URL) throws {
        let names = try FileManager.default.contentsOfDirectory(atPath: resourcesURL.path).sorted()
        func files(_ extensions: Set<String>) -> [URL] {
            names.filter { extensions.contains(($0 as NSString).pathExtension.lowercased()) }
                .map { resourcesURL.appendingPathComponent($0) }
        }
        resourceFile = files(["rsrc"]).first
        audioFiles = files(["aiff", "mp3"])
        pngFiles = files(["png"])
    }
}
```

```sh
WT=/Users/andiyar/Developer/Ambrosia-Classics/.claude/worktrees/dazzling-chebyshev-e403ce
cd "$WT/Aki/Core" && swift test > /tmp/aki-t7.log 2>&1
grep -cE "^Test Case '.*' (passed|failed|skipped) \(" /tmp/aki-t7.log; grep -cE "^Test Case '.*' (failed|skipped) \(" /tmp/aki-t7.log
```

Expected: `6` and `0` (G4 — data reached through the `Resources/Aki` symlinks from Task 0). (`Aki/Core` has one
test bundle, so its single `Executed 6 tests, with 0 failures (0 unexpected)` line agrees; a bare
`grep -c skipped` would also hit compiler diagnostic context from the `backends` warning on first build.)

- [ ] **Step 7.4: The skip path names its variable** (point both at a missing path):

```sh
WT=/Users/andiyar/Developer/Ambrosia-Classics/.claude/worktrees/dazzling-chebyshev-e403ce
cd "$WT/Aki/Core" && AKI_DATA_11=/nonexistent AKI_DATA_12=/nonexistent swift test > /tmp/aki-t7-nodata.log 2>&1
grep -E 'Executed [0-9]+ tests?, with' /tmp/aki-t7-nodata.log | tail -n 1; grep -c "AKI_DATA_1[12]=/nonexistent is not a directory" /tmp/aki-t7-nodata.log
```

Expected: `Executed 6 tests, with 5 tests skipped and 0 failures (0 unexpected) …` (only the synthetic
`AkiBundle` test runs; `0 failures` holds because no locator call is nested inside `XCTUnwrap`, which would
record the thrown XCTSkip as a failure) and a count ≥ 5 (each skip names its variable).

- [ ] **Step 7.5: Commit (worktree branch).**

```sh
WT=/Users/andiyar/Developer/Ambrosia-Classics/.claude/worktrees/dazzling-chebyshev-e403ce
git -C "$WT" add Aki/Core/Package.swift Aki/Core/Sources/AkiCore Aki/Core/Tests/AkiCoreTests
git -C "$WT" status --porcelain | grep -v '^??'
git -C "$WT" commit -F - <<'EOF'
Aki/Core: AkiBundle + census tests on HectorKit (82 PICT, 50 PNG, 14+15 audio, 1.2 twins)

SwiftPM package on HectorKit by local path (../../../HectorKit). Tests default to the git-ignored
Resources/Aki/{1.1.0,1.2.0}.app symlinks; AKI_DATA_11 / AKI_DATA_12 override; skips name the var.

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>
EOF
git -C "$WT" status --porcelain | grep -v '^??'
```

Expected: before the commit, the filtered porcelain lists only `A  Aki/Core/…` paths (no `Package.resolved` is written
for a path-only dependency — confirmed by the plan review's replica); after: no output.

- [ ] **Step 7.6: `Aki/Core/Package.swift` stage 7b** — replace the whole file with:

```swift
// swift-tools-version: 6.0
import PackageDescription

// Aki — Mahjong Solitaire core (game logic + data loading) on HectorKit. Phase 0 holds only the
// shipped-bundle locator and the data-census tool; game logic arrives in Phase 2.
// HectorKit is a LOCAL path dependency during build-out (design §3): from Aki/Core, three levels
// up is the directory that holds both repos (in a worktree session: the .claude/worktrees/HectorKit
// symlink — docs/DECISIONS.md D1).
let package = Package(
    name: "AkiCore",
    platforms: [.macOS(.v15)],
    products: [
        .library(name: "AkiCore", targets: ["AkiCore"]),
        .executable(name: "aki-census", targets: ["aki-census"]),
    ],
    dependencies: [
        .package(path: "../../../HectorKit"),
    ],
    targets: [
        .target(name: "AkiCore"),
        .executableTarget(name: "aki-census", dependencies: [
            "AkiCore",
            .product(name: "HectorResources", package: "HectorKit"),
            .product(name: "HectorGraphics", package: "HectorKit"),
        ]),
        .testTarget(name: "AkiCoreTests", dependencies: [
            "AkiCore",
            .product(name: "HectorResources", package: "HectorKit"),
            .product(name: "HectorGraphics", package: "HectorKit"),
        ]),
    ]
)
```

- [ ] **Step 7.7: Write `Aki/Core/Sources/aki-census/AkiCensus.swift`:**

```swift
import AVFoundation
import AkiCore
import Foundation
import HectorGraphics
import HectorResources

/// aki-census — Phase 0 data census of Aki - Mahjong Solitaire 1.1.0 + 1.2.0 through HectorKit.
///
///     aki-census <Aki 1.1.0 Contents/Resources> <Aki 1.2.0 Contents/Resources>
///
/// Prints Markdown on stdout (docs/aki/data-census.md is this output verbatim under a header) and
/// exits 1 if any PICT, PNG or audio file fails to decode/open, 2 on bad arguments. Prints file
/// NAMES only, never machine paths.
@main
struct AkiCensus {
    static func main() {
        let args = CommandLine.arguments
        guard args.count == 3 else {
            FileHandle.standardError.write(Data(
                "usage: aki-census <Aki 1.1.0 Contents/Resources> <Aki 1.2.0 Contents/Resources>\n".utf8))
            exit(2)
        }
        do {
            let failures = try run(v11: URL(fileURLWithPath: args[1]), v12: URL(fileURLWithPath: args[2]))
            exit(failures == 0 ? 0 : 1)
        } catch {
            FileHandle.standardError.write(Data("aki-census: \(error)\n".utf8))
            exit(1)
        }
    }

    static func row(_ cells: [String]) -> String { "| " + cells.joined(separator: " | ") + " |" }

    /// Returns the number of failures (0 = everything decoded/opened).
    static func run(v11 resources11: URL, v12 resources12: URL) throws -> Int {
        let v11 = try AkiBundle(resourcesURL: resources11)
        let v12 = try AkiBundle(resourcesURL: resources12)
        var failures = 0

        // 1. The 1.1.0 resource file.
        guard let rsrc = v11.resourceFile,
              let collection = try ResourceReader.read(fileAt: rsrc) else {
            FileHandle.standardError.write(Data("aki-census: FAIL: no readable .rsrc resource file in the 1.1.0 folder\n".utf8))
            return 1
        }
        print("## 1. Aki 1.1.0 resource file — `\(rsrc.lastPathComponent)`\n")
        print(row(["type", "count"])); print(row(["---", "---:"]))
        for (type, count) in collection.counts() { print(row(["`\(type)`", "\(count)"])) }
        print(row(["**total**", "**\(collection.count)**"]))
        print("\nThe 1.2.0 folder has \(v12.resourceFile == nil ? "no" : "a") `.rsrc` file.\n")

        // 2. Every PICT through the kit.
        print("## 2. PICT census (1.1.0) — every PICT through HectorKit\n")
        print("`kind`: raw16 / raw32 = DirectBitsRect via `PICT(data:)` (\"argb\" = cmpCount 4, a real alpha")
        print("plane); quicktime = banded 0x8200 JPEG via `PICT.decodeQuickTime(data:)`.\n")
        print(row(["id", "frame", "kind", "bands", "decode"])); print(row(["---:", "---", "---", "---:", "---"]))
        var rawCount = 0, quickTimeCount = 0
        var composites: [(id: Int16, width: Int, height: Int, rgba: [UInt8])] = []
        for res in collection.resources(of: "PICT") {
            do {
                let pict = try PICT(data: res.data)
                let depth = directBitsDepth(res.data)
                let kind = depth.map { "raw\($0.pixelSize)" + ($0.cmpCount == 4 ? " argb" : "") } ?? "raw"
                print(row(["\(res.id)", "\(pict.width)×\(pict.height)", kind, "—", "ok"]))
                rawCount += 1
            } catch PICT.DecodeError.unsupportedOpcode(let op) where op == 0x8200 {
                do {
                    let bands = try PICT.quickTimeBands(data: res.data).bands.count
                    let pict = try PICT.decodeQuickTime(data: res.data)
                    print(row(["\(res.id)", "\(pict.width)×\(pict.height)", "quicktime", "\(bands)", "ok"]))
                    composites.append((res.id, pict.width, pict.height, [UInt8](pict.rgba)))
                    quickTimeCount += 1
                } catch {
                    print(row(["\(res.id)", "?", "quicktime", "?", "FAIL: \(error)"])); failures += 1
                }
            } catch {
                print(row(["\(res.id)", "?", "?", "?", "FAIL: \(error)"])); failures += 1
            }
        }
        let pictTotal = collection.resources(of: "PICT").count

        // 3. The 1.2.0 PNGs.
        var pngs: [(name: String, width: Int, height: Int, rgba: [UInt8])] = []
        var pngFailures = 0
        var pngRows: [String] = []
        for url in v12.pngFiles {
            do {
                let image = try CodecImage.decode(Data(contentsOf: url))
                pngRows.append(row(["`\(url.lastPathComponent)`", "\(image.width)×\(image.height)", "ok"]))
                pngs.append((url.lastPathComponent, image.width, image.height, [UInt8](image.rgba)))
            } catch {
                pngRows.append(row(["`\(url.lastPathComponent)`", "?", "FAIL: \(error)"])); pngFailures += 1
            }
        }
        failures += pngFailures

        print("\n## 3. 1.1.0 QuickTime art ↔ 1.2.0 PNG\n")
        print("For each QuickTime PICT: the same-size 1.2.0 PNG with the smallest mean absolute RGB")
        print("difference (0–255 scale) from the decoded composite. A wrong band order/offset costs ≥ 10.\n")
        print(row(["PICT", "frame", "closest 1.2.0 PNG", "mean abs diff"])); print(row(["---:", "---", "---", "---:"]))
        for c in composites {
            let candidates = pngs.filter { $0.width == c.width && $0.height == c.height }
            let scored = candidates.map { (name: $0.name, diff: meanAbsRGBDiff(c.rgba, $0.rgba)) }
            if let best = scored.min(by: { $0.diff < $1.diff }) {
                print(row(["\(c.id)", "\(c.width)×\(c.height)", "`\(best.name)`", String(format: "%.2f", best.diff)]))
            } else {
                print(row(["\(c.id)", "\(c.width)×\(c.height)", "— (no same-size PNG)", "—"]))
            }
        }

        print("\n## 4. PNG census (1.2.0) — every PNG through `CodecImage`\n")
        print(row(["file", "size", "decode"])); print(row(["---", "---", "---"]))
        pngRows.forEach { print($0) }

        // 5. Audio, both versions.
        print("\n## 5. Audio — every AIFF/MP3 through `AVAudioFile(forReading:)`\n")
        var opened: [Int] = []
        for (label, bundle) in [("1.1.0", v11), ("1.2.0", v12)] {
            print("### \(label)\n")
            print(row(["file", "format", "sample rate", "channels", "length (frames)", "processing format"]))
            print(row(["---", "---", "---:", "---:", "---:", "---"]))
            var ok = 0
            for url in bundle.audioFiles {
                do {
                    let file = try AVAudioFile(forReading: url)
                    let format = file.fileFormat
                    let processing = file.processingFormat
                    print(row(["`\(url.lastPathComponent)`", fourCC(format.streamDescription.pointee.mFormatID),
                               "\(Int(format.sampleRate))", "\(format.channelCount)", "\(file.length)",
                               "\(commonFormatName(processing.commonFormat)) \(Int(processing.sampleRate)) Hz "
                               + "\(processing.channelCount) ch \(processing.isInterleaved ? "interleaved" : "non-interleaved")"]))
                    ok += 1
                } catch {
                    print(row(["`\(url.lastPathComponent)`", "FAIL: \(error)", "", "", "", ""])); failures += 1
                }
            }
            opened.append(ok)
            print("")
        }

        print("## Totals\n")
        print("- PICT: \(pictTotal) (raw \(rawCount), quicktime \(quickTimeCount), failed \(pictTotal - rawCount - quickTimeCount))")
        print("- PNG: \(v12.pngFiles.count) (failed \(pngFailures))")
        print("- Audio: 1.1.0 \(opened[0]) of \(v11.audioFiles.count) opened, 1.2.0 \(opened[1]) of \(v12.audioFiles.count) opened")
        print("- Failures: \(failures)")
        return failures
    }

    /// For a raw PICT: pixelSize/cmpCount of its first DirectBitsRect (0x009A), found by stepping the
    /// state ops Aki's raw PICTs carry before it (0x0011 · 0x0C00 · 0x00A1 · 0x0001; 0x00A0 too).
    /// nil if the stream has any other opcode first. Census labelling only — decoding is the kit's.
    static func directBitsDepth(_ data: Data) -> (pixelSize: Int, cmpCount: Int)? {
        let b = [UInt8](data)
        func u16(_ o: Int) -> Int? { o >= 0 && o + 1 < b.count ? Int(b[o]) << 8 | Int(b[o + 1]) : nil }
        var pos = 10                                     // past picSize + picFrame
        while let op = u16(pos) {
            pos += 2
            switch op {
            case 0x0011: pos += 2
            case 0x0C00: pos += 24
            case 0x00A0: pos += 2
            case 0x00A1:
                guard let size = u16(pos + 2) else { return nil }
                pos += 4 + size
            case 0x0001:
                guard let size = u16(pos) else { return nil }
                pos += size
            case 0x009A:
                // baseAddr 4 · rowBytes 2 · bounds 8 · pmVersion 2 · packType 2 · packSize 4 ·
                // hRes 4 · vRes 4 · pixelType 2 → pixelSize @32, cmpCount @34 (after the opcode).
                guard let pixelSize = u16(pos + 32), let cmpCount = u16(pos + 34) else { return nil }
                return (pixelSize, cmpCount)
            default:
                return nil
            }
            if pos % 2 == 1 { pos += 1 }
        }
        return nil
    }

    /// Mean absolute difference over the R, G, B channels of two same-size RGBA8 buffers.
    static func meanAbsRGBDiff(_ a: [UInt8], _ b: [UInt8]) -> Double {
        precondition(a.count == b.count)
        var sum = 0
        var i = 0
        while i < a.count {
            sum += abs(Int(a[i]) - Int(b[i])) + abs(Int(a[i + 1]) - Int(b[i + 1])) + abs(Int(a[i + 2]) - Int(b[i + 2]))
            i += 4
        }
        return Double(sum) / Double(a.count / 4 * 3)
    }

    static func fourCC(_ v: UInt32) -> String {
        String([24, 16, 8, 0].map { Character(UnicodeScalar(UInt8(truncatingIfNeeded: v >> $0))) })
    }

    static func commonFormatName(_ f: AVAudioCommonFormat) -> String {
        switch f {
        case .pcmFormatFloat32: return "Float32"
        case .pcmFormatFloat64: return "Float64"
        case .pcmFormatInt16: return "Int16"
        case .pcmFormatInt32: return "Int32"
        case .otherFormat: return "other"
        @unknown default: return "unknown"
        }
    }
}
```

- [ ] **Step 7.8: Build (release — the art-correspondence section compares ~400 image pairs) and run.**

```sh
WT=/Users/andiyar/Developer/Ambrosia-Classics/.claude/worktrees/dazzling-chebyshev-e403ce
cd "$WT" && swift build --package-path Aki/Core -c release 2>&1 | tail -n 1
"$(swift build --package-path Aki/Core -c release --show-bin-path)/aki-census" \
  "$PWD/Resources/Aki/1.1.0.app/Contents/Resources" "$PWD/Resources/Aki/1.2.0.app/Contents/Resources" > /tmp/aki-census.out
echo "exit $?"; tail -n 4 /tmp/aki-census.out
```

Expected: `Build complete!`; `exit 0`; then exactly

```
- PICT: 82 (raw 11, quicktime 71, failed 0)
- PNG: 50 (failed 0)
- Audio: 1.1.0 14 of 14 opened, 1.2.0 15 of 15 opened
- Failures: 0
```

(G5). Spot checks in `/tmp/aki-census.out`: the PICT 135 row reads `| 135 | 2358×68 | raw32 argb | — | ok |`;
the art section has `| 140 | 800×600 | \`background7.png\` |` and `| 164 | 800×600 | \`map.png\` |`.

- [ ] **Step 7.9: Assemble `docs/aki/data-census.md`** (header + the tool's stdout verbatim):

```sh
WT=/Users/andiyar/Developer/Ambrosia-Classics/.claude/worktrees/dazzling-chebyshev-e403ce
mkdir -p "$WT/docs/aki"
cat > /tmp/aki-census-header.md <<'EOF'
# Aki — data census (Phase 0)

> Generated @DATE@ by `aki-census` (`Aki/Core`) through HectorKit `@HK_SHA@`. Everything below the
> rule is the tool's stdout, verbatim. Re-run from the repo root:
>
>     swift build --package-path Aki/Core -c release
>     "$(swift build --package-path Aki/Core -c release --show-bin-path)/aki-census" \
>         "$PWD/Resources/Aki/1.1.0.app/Contents/Resources" "$PWD/Resources/Aki/1.2.0.app/Contents/Resources"
>
> `Resources/Aki/*.app` are git-ignored symlinks (docs/DECISIONS.md D1, written in Phase-0 Task 8) to the archive copies:
> 1.1.0 → `~/Developer/Ambrosia/Aki/Aki - Mahjong Solitaire/Aki - Mahjong Solitaire.app`;
> 1.2.0 → `~/Developer/Ambrosia/Resources/ambrosia-extracted/Action-Adventure/Aki - Mahjong Solitaire/Aki 1.2 UB/Aki.app`.

## Spec-vs-data deltas (design-2026-10-03 §4/§5)

1. **71 QuickTime-JPEG PICTs + 11 raw, not 70 + 12.** The raw ones are DirectBitsRect: 7 × 16-bit
   (128, 129, 131, 133, 134, 168, 314) and 4 × 32-bit (135, 5591, 8715, 23098); PICT 135 (2358×68) is
   32-bit **cmpCount 4** — a real alpha plane ("raw32 argb" below), which the decoder carries into the
   RGBA's A channel (a fact for Phase 1's compositing).
2. **0 `'snd '` resources.** The 1.1.0 resource file holds CHNK, STR, PICT, pnot, icns, 8BIM, TEXT, ANPA
   only; every sound is a loose AIFF/MP3 (section 5). HectorKit's `snd` decoder keeps EV's oracle.
3. **The QuickTime PICTs are banded.** Each is `0x0011 · 0x0C00 · 0x00A1 LongComment (kind 498) · 0x0001
   Clip · N × [0x8200 JPEG band · 0x0098 1-bit "decompressor required" BitMap] · 0x00FF`, N ∈ {1, 2, 4, 6}
   (45 / 5 / 20 / 1 PICTs); bands are full-width strips at their matrix ty that tile the frame exactly.
   HectorKit composites them (`PICT.decodeQuickTime`, HectorKit DECISIONS D2) and skips the placeholders.

---

EOF
HK_SHA=$(git -C /Users/andiyar/Developer/HectorKit rev-parse --short HEAD)
sed -e "s/@HK_SHA@/$HK_SHA/" -e "s/@DATE@/$(date +%Y-%m-%d)/" /tmp/aki-census-header.md > "$WT/docs/aki/data-census.md"
cat /tmp/aki-census.out >> "$WT/docs/aki/data-census.md"
head -n 3 "$WT/docs/aki/data-census.md"; grep -c '@HK_SHA@\|@DATE@' "$WT/docs/aki/data-census.md"; tail -n 4 "$WT/docs/aki/data-census.md"
```

Expected: the first line `# Aki — data census (Phase 0)`, line 3 naming today's date and the HectorKit short SHA
(the Task 6 commit); `0` leftover tokens; the four totals lines of Step 7.8.

- [ ] **Step 7.10: Whole package still green, then commit.**

```sh
WT=/Users/andiyar/Developer/Ambrosia-Classics/.claude/worktrees/dazzling-chebyshev-e403ce
cd "$WT/Aki/Core" && swift test > /tmp/aki-t7-10.log 2>&1
grep -cE "^Test Case '.*' (passed|failed|skipped) \(" /tmp/aki-t7-10.log; grep -cE "^Test Case '.*' (failed|skipped) \(" /tmp/aki-t7-10.log
git -C "$WT" add Aki/Core/Package.swift Aki/Core/Sources/aki-census docs/aki/data-census.md
git -C "$WT" commit -F - <<'EOF'
aki-census tool + docs/aki/data-census.md (82 PICT 11/71, 50 PNG, 14+15 audio, 1.1->1.2 art map)

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>
EOF
git -C "$WT" status --porcelain | grep -v '^??'
```

Expected: `6` then `0`; no output from the filtered porcelain after the commit.

- **Verify:** 7.3 (G4), 7.4, 7.8 (G5), 7.9, 7.10 as stated.

---

### Task 8 — Final gates, Classics DECISIONS, HectorKit STATE, tag `v0.1.0`

**Files:** Create `$WT/docs/DECISIONS.md`; replace `$HK/docs/STATE.md`; tag HectorKit.

- [ ] **Step 8.1: Re-run every machine gate from cold.**

```sh
/Users/andiyar/Developer/HectorKit/tools/check-zero-skip.sh 2>&1 | tail -n 1
WT=/Users/andiyar/Developer/Ambrosia-Classics/.claude/worktrees/dazzling-chebyshev-e403ce
cd "$WT/Aki/Core" && swift test > /tmp/aki-g4.log 2>&1
grep -cE "^Test Case '.*' (passed|failed|skipped) \(" /tmp/aki-g4.log; grep -cE "^Test Case '.*' (failed|skipped) \(" /tmp/aki-g4.log
git -C /Users/andiyar/Developer/Ambrosia rev-parse HEAD | diff - /tmp/phase0-ev-head.txt && \
git -C /Users/andiyar/Developer/Ambrosia status --porcelain | diff - /tmp/phase0-ev-porcelain.txt && echo "EV untouched"
```

Expected: `PASS: zero skips, zero failures, executed 112 == floor 112` (G1–G3); `6` and `0` (G4);
`EV untouched` (G7). Any miss → STOP, no tag.

- [ ] **Step 8.2: Write `$WT/docs/DECISIONS.md`:**

```markdown
# DECISIONS.md — Ambrosia Classics

> Append-only. Numbered. Never re-litigate a locked decision — supersede it with a new numbered
> entry that references the old one. Record rejected alternatives with the reason.
> Two rules that were paid for (fable-kit): a ledger line is NOT consent to remove something Ben uses;
> record the rejected alternatives — they stop the next session proposing them again.

---

## D1 — Phase 0 rulings: census numbers, tool placement, local paths (2026-10-03)

**Decided:**
1. **Aki 1.1.0 has 71 QuickTime-JPEG PICTs and 11 raw, not 70/12** (design §4). The opcode-stream census
   and the `aki-census` tool agree; `docs/aki/data-census.md` states the tool's numbers. The design doc is
   left as Ben approved it; this entry is the correction.
2. **Aki 1.1.0 has 0 `'snd '` resources** — its sounds are 10 AIFF (ima4) + 4 MP3 files (1.2.0: 10 + 5).
   The design §5 "every snd opens" gate is vacuous for Aki; HectorKit's `snd` decoder keeps EV's Override
   Sounds as its oracle; Aki's sounds are gated by `AVAudioFile` opening every file.
3. **The census tool lives in `Aki/Core` (`aki-census` executable target), not in HectorKit** — it knows
   the word "Aki" (HectorKit rule). HectorKit carries only the Aki PICT census as a *test*.
4. **Local paths.** `Aki/Core/Package.swift` depends on HectorKit at `../../../HectorKit` (design §3). In a
   `.claude/worktrees/<name>` session that resolves to `.claude/worktrees/HectorKit`, an untracked symlink
   to `~/Developer/HectorKit` (the main checkout's `.git/info/exclude` already ignores `.claude/worktrees/`).
   The originals are reached through git-ignored symlinks `Resources/Aki/1.1.0.app` and
   `Resources/Aki/1.2.0.app` (archive copies; paths in `docs/aki/data-census.md`); the Aki tests default
   to them and `AKI_DATA_11` / `AKI_DATA_12` override.
5. **A decoded composite must match its 1.2.0 twin**, not just its size: 1.2.0 re-shipped the same art as
   PNG, so `AkiCensusTests` pins five QuickTime PICTs against their PNGs (mean |ΔRGB| < 6).

**Because:** numbers come only from tool output; game knowledge stays out of the kit; one checkout layout
must work in both the main checkout and agent worktrees without editing `Package.swift`.
**Rejected:** editing the design doc's 70/12 in place (it is Ben's reviewed text) · an Aki census tool inside
HectorKit (kit rule) · absolute paths in `Package.swift` (breaks every other machine) · size-only gates for
QuickTime art (a band swap keeps the size).
**Approved by:** Phase-0 orchestrator rulings R4/R5/B7 (2026-10-03) under the design doc; Ben's review pending.
```

```sh
WT=/Users/andiyar/Developer/Ambrosia-Classics/.claude/worktrees/dazzling-chebyshev-e403ce
git -C "$WT" add docs/DECISIONS.md
git -C "$WT" commit -F - <<'EOF'
docs/DECISIONS.md: D1 Phase-0 rulings (71/11, 0 snd, census tool placement, local paths, 1.2 twins)

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>
EOF
git -C "$WT" status --porcelain | grep -v '^??'
```

- [ ] **Step 8.3: Replace `$HK/docs/STATE.md` with:**

```markdown
# STATE — HectorKit — 2026-10-03

> Live state only. Dated; re-verify before acting. Forks go in `docs/DECISIONS.md`.

## Where we are

- **v0.1.0** (Phase 0 done, 2026-10-03). Modules: `HectorResources` (classic map, BRGR, reader, MacRoman),
  `HectorGraphics` (`PICT` raster + banded QuickTime `quickTimeBands`/`decodeQuickTime`, `CodecImage`,
  `Ditl`), `HectorAudio` (`SndSound`), + test-only `HectorTestSupport`. Lifted from EV `e23122f` (D1).
- **Gate:** `tools/check-zero-skip.sh` — zero skips, zero failures, **floor 112** (2026-10-03).
- **Census:** all 82 Aki 1.1.0 PICTs decode to their frames (11 raw DirectBitsRect, 71 banded QuickTime-JPEG;
  `AkiPICTCensusTests`); EV Nova Override data green (resources, PICT, DITL, snd).
- Real data via env vars (D3): `HECTORKIT_DATA_NOVA`, `HECTORKIT_DATA_NOVA_REFERENCE`, `HECTORKIT_DATA_AKI11`.

## Open, ordered

1. Phase 1: `HectorShell` (design §2) — planned from Ambrosia-Classics.
2. EV adopts HectorKit via a re-export shim — EV's own machine-gated PR, after its open lanes merge.

## Carried (not blockers)

- The banded QuickTime walk is census-verified on Aki only; EV's QuickTime ship pics (5027/5030) are a
  different shape (pen/text-state + LongText fallback after the band, refused at 0x0007) and stay on
  `compressedQuickTimePayload` (D2).
- Aki PICT 135 (`plate`, 2358×68) is 32-bit cmpCount 4: its alpha plane is real — Phase 1 composites with it.
- `ContainerBackend.swift`'s `static let backends` draws a Swift 6 concurrency warning — lifted as-is (D1).
```

- [ ] **Step 8.4: Commit, tag, push HectorKit.**

```sh
HK=/Users/andiyar/Developer/HectorKit
git -C "$HK" add docs/STATE.md
git -C "$HK" commit -F - <<'EOF'
STATE: v0.1.0 — Phase 0 done (floor 112, all 82 Aki PICTs, EV data green)

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>
EOF
git -C "$HK" tag -a v0.1.0 -m "HectorKit v0.1.0 — EV lift (e23122f) + banded QuickTime PICTs; zero-skip floor 112; Aki 1.1.0 PICT census green"
git -C "$HK" push origin main && git -C "$HK" push origin v0.1.0
git -C "$HK" ls-remote --tags origin v0.1.0; git -C "$HK" status --porcelain | grep -v '^??'
```

Expected: the `ls-remote` line ends `refs/tags/v0.1.0` (G8); no output from the filtered porcelain.

- [ ] **Step 8.5: Report to the orchestrator** — the G1–G8 lines verbatim, the HectorKit commit list
  (`git -C "$HK" log --oneline 8c614f1..v0.1.0`), the worktree commit list
  (`git -C "$WT" log --oneline c80e2d4..HEAD`), and anything that needed a STOP. The orchestrator updates
  Ambrosia-Classics `docs/STATE.md`, writes the handoff, merges the branch, and issues the Phase 1 chip.

- **Verify:** 8.1 three lines exact; 8.4 tag on origin.

---

## Execution order

Harden first, then march: every lifted byte is diffed against EV and green at a floor (Wave 1) before a line
of new decoder code exists, so Task 5's red/green signals cannot be confused with lift damage.

| wave | tasks | why this order | gate to leave the wave |
|---|---|---|---|
| 0 | Task 0 | pins EV, proves both repos clean, lays the symlinks every later path relies on | 0.1–0.6 exact |
| 1 — harden | Tasks 1 → 2 → 3 → 4 (strictly sequential: each grows `Package.swift`) | the lift is pure risk-reduction: prefix-only diffs + EV's own oracle tests on EV's data | Task 4: `PASS … 89 == floor 89`, negative run FAILs |
| 2 — new code | Task 5 (⚑ MAJOR, two review legs) → Task 6 | the only new decoder logic; synthetic TDD first, then the second game's real data | Task 5 legs signed off; Task 6 `PASS … 112` |
| 3 — census | Task 7 (needs the Task 5/6 API through the path dependency) | game-side tooling only after the kit is final | G4 + G5 |
| 4 — close | Task 8 | gates from cold, ledgers, tag | G1–G8 |

No parallelism: Tasks 1–6 share one `Package.swift`, and Task 7 consumes Task 5's API.
Model routing (fable-kit): Opus implementers per task; Fable reviewers report everything with confidence.

---

## Pre-execution self-audit

Adversarial pass by the planner against its own plan (a second reviewer should repeat it). Outcomes inline.

1. **Every spec item has a task or a named deferral.** Design §2 rows → Tasks 1/2/3 (+5 for QuickTime);
   `HectorShell` → Phase 1. §5 machine gates → zero-skip floor (Tasks 4–6), "all 82 PICTs to declared frame"
   (Tasks 6 + 7), "snd/AIFF open every shipped sound" (snd: EV oracle, Task 3 — Aki has none; AIFF/MP3: Task 7);
   Aki-core logic tests + boot smoke → Phases 1–3. §6 step 0: census ✅ Task 7; Ghidra/diff/RE bank → RE lane;
   **add-ons fetch had no owner** → ✅→FIXED: listed under Scope › Explicitly deferred, owner = orchestrator.
2. **Brief B3 says all four 32-bit raw PICTs are cmpCount 3** — census3.out line 34 says PICT 135 is
   `direct32 pack4 cmp4`. ✅→FIXED: Known delta 4, Research note 12, and the census tool labels it `raw32 argb`.
   R4's size pins are unaffected.
3. **Ruling R3 is internally inconsistent for paint ops** ("handles every opcode `PICT.init` handles" vs
   `droppedPaintOps = []`; EV 5027 carries a 0x0032 before its band). The first draft refused paint ops.
   ✅→FIXED per orchestrator ruling 2026-10-03: skip-and-record exactly as `PICT.init`, `quickTimeBands` returns
   a fourth element `droppedPaintOps`, `decodeQuickTime` carries it; pinned by
   `testRectPaintOpIsSkippedAndRecordedInBandedWalk`; 5027 now refused at 0x0007. Raster ops stay refused
   (separate ruling, Invariant 13, D2).
4. **"Existing 5027 test still passes" after the extractor fix** — 5027's pre-band ops are 0011/0C00/001E/0001/
   0032/001F (no 0x00A0/0x00A1), so the walk is unchanged for it. ✅ ok (Step 5.11 runs it).
5. **`PICT.Cursor` is `private`** — a second file cannot use it. ✅→FIXED: one-line visibility hunk (Step 5.7),
   counted in Invariant 2c and D2.
6. **`PICT`'s memberwise init is suppressed** by `init(data:)`. ✅→FIXED: internal `init(width:height:rgba:droppedPaintOps:)`
   in the extension (same module — allowed to assign `let`s).
7. **Name clash `be16`/`be32`** (SndSoundTests' local helpers vs HectorTestSupport's public ones). ✅→FIXED:
   `import func HectorTestSupport.novaFork`.
8. **Public structs' memberwise inits are internal** — `FixtureType(code:resources:)` would not compile from
   test targets. ✅→FIXED: explicit `public init`s (Fixtures diff shows them).
9. **XCTest from a non-test target** (`HectorTestSupport`). ✅ ok — verified by the plan review's replica and
   toy builds (Research note 21); the STOP rule stays only as a generic guard.
10. **SwiftPM rejects targets without sources.** ✅→FIXED: `Package.swift` staged (HectorKit 1/2/3; Aki 7a/7b).
11. **Shell redirection order.** A first draft used `cmd 2>&1 > log` (stderr escapes the log). ✅→FIXED: every
    logged command is `cmd > log 2>&1`.
12. **Negative gate run.** A first draft used `HECTORKIT_DATA_NOVA=/var/empty`: the folder test would *fail*
    (empty merge) rather than skip, and messages would show `/private/var/empty`. ✅→FIXED: `/nonexistent`
    (13 clean skips, all naming the variable).
13. **Size-only gates cannot see a misplaced band.** ✅→FIXED: exact-pixel synthetic composite test, mutant M2
    proves it bites, and the real-data 1.1.0↔1.2.0 twin test (MAD < 6; a band swap costs 10–30).
14. **Colour management could break an exact-pixel PNG assertion** (sRGB round trip of mid-tones). ✅→FIXED:
    exact tests use only 0/255 components; real data is compared by MAD with margin (worst measured 4.98).
15. **`swift run` would mix build logs into the census document.** ✅→FIXED: build, then exec from `--show-bin-path`.
16. **Debug-mode cost** of the tool's ~400 same-size image comparisons. ✅→FIXED: the tool is built `-c release`;
    the debug test compares only 5 pairs.
17. **Worktree vs main checkout paths** (`../../../HectorKit`, `Resources/Aki`). ✅→FIXED: HectorKit symlink in
    `.claude/worktrees/` (git-excluded), `Resources/Aki` symlinks in both checkouts (git-ignored), checked in 0.4/0.5.
18. **Skip message said "unset" when the variable was set but wrong** (Classics locator). ✅→FIXED: two messages.
19. **Test arithmetic.** 39 + 40 + 10 = 89 → +20 = 109 → +3 = 112; `grep -c "func test"` over the type-checked
    dry tree = 112; the review's replica ran 112 (bundles 39 / 63 / 10). ✅ ok — counted as `Test Case` lines,
    never from one bundle's summary (see R-C1/R-C2).
20. **Filter regexes.** `PICTTests` matches class `PICTTests` only (not `RealPICTCensusTests`, not
    `AkiPICTCensusTests`); Step 5.5 expects 23 = 2 + 21. ✅ ok.
21. **Floor discipline.** R2's "filled from the first green run" = Step 4.2 (STOP if ≠ 89); bumped in the tasks
    that add tests (5.11 → 109, 6.3 → 112), each with a fresh script run. ✅ ok.
22. **Commit hygiene.** Explicit paths everywhere; no modified tracked files checked after each commit; HectorKit pushed
    after each green task (Task 5's interim commits are pushed at 5.12, after its floor run). ✅ ok.
23. **EV untouched** is proven (HEAD + porcelain snapshot vs Task 8), not asserted. ✅ ok.
24. **Commit trailer.** ✅→FIXED per orchestrator ruling 2026-10-03: every commit in both repos ends with exactly
    `Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>`, whichever model implements, no other trailer
    (Invariant 4).
25. **Classics → HectorKit test-only target leak.** `AkiCoreTests` depends on products `HectorResources` /
    `HectorGraphics` only, so `HectorTestSupport` (XCTest) is never built for Aki. ✅ ok.
26. **Audio pins.** Channel counts and 44.1 kHz come from `afinfo` (same AudioToolbox stack as `AVAudioFile`). ✅ ok.
27. **Mutation restore safety.** `git checkout -- <one file>` restores the Step 5.9 commit's bytes; no stash used
    (shared stash stack). `restored` is printed only if `git diff --quiet` agrees. ✅ ok.
28. **Census doc's HectorKit SHA** is the Task 6 commit (decoder-final); Task 8 adds only a STATE commit + tag. ✅ ok.
29. **Placeholders.** The only tokens are `@HK_SHA@`/`@DATE@`, replaced by Step 7.9's own `sed` and checked (count 0). ✅ ok.
30. **"≥ N" skip-message counts** (Steps 1.8, 4.3, 6.2, 7.4): the review's replica shows XCTest echoes every
    skip message (20 in the no-data run). ✅ ok — the "if 0" fallback was removed (R-M6).
31. **Beyond-ruling additions** (kept small, each flagged): the census tool's art-correspondence section and the
    twin MAD test (both serve "decodes correctly", not just "to size"); `AkiBundle.resourceFile` is `URL?` because
    1.2.0 has no `.rsrc`; the whole-pixel-translation matrix check (refuse rather than mis-place). ✅ ok.
32. **Every task has a Verify and a Commit/save point** (Task 0: nothing tracked to commit, by design). ✅ ok.

**Fix pass — one line per Fable review finding (2026-10-03):**

- R-C1 ✅→FIXED: `check-zero-skip.sh` counts `^Test Case '…' (passed|failed|skipped) (` lines (executed, failed,
  skipped) instead of the last bundle's summary; prints the per-bundle `'All tests'` lines for the human; "no
  tests ran" guard on `executed -eq 0`; `test_status` kept as a second failure signal.
- R-C2 ✅→FIXED: every whole-suite expectation (1.8, 1.9, 2.5, 3.4, 7.3, 7.10, 8.1, G4) is a counted total;
  every filtered expectation (5.3, 5.4, 5.5, 5.8, 5.10, 6.2, G2) takes the non-`Executed 0 tests` line;
  2.5 and 3.4 also list the per-bundle lines (39/40; 39/40/10); the verification model states bundles 39/63/10.
- R-C3 ✅→FIXED (all 12 sites): Known delta 5 (+ new delta 9), Research note 14, Scope deferral, D2 (b) /
  5027 sentence / Rejected bullet / rulings line, `quickTimeBands` docstring + 4-element signature + `dropped`
  + 0x0030–0x0034 case + return, `decodeQuickTime` docstring + `walk.droppedPaintOps`, file header comment,
  test renamed `testRectPaintOpIsSkippedAndRecordedInBandedWalk` (still one test: 16 / 109 / 112 stand),
  `droppedPaintOps == []` added to the walk test, 5027 test pins `.unsupportedOpcode(0x0007)`, Step 5.9 commit
  message, STATE "Carried" bullet, self-audit 3. The renamed test checks the composite's size, not its pixels,
  so mutant M2 (Step 5.10) still turns exactly one test red.
- R-I1 ✅→FIXED: no bare `grep -c skipped` remains; all anchored on `^Test Case`; Invariant 6 + note 18 warn why.
- R-I2 ✅→FIXED: Step 5.4 expects `Executed 2 tests, with 1 failure (1 unexpected)`.
- R-I3 ✅→FIXED (orchestrator ruling): every Classics/HectorKit/main-checkout porcelain check is
  `git status --porcelain | grep -v '^??'` → no modified tracked files (EV's snapshot comparison is unchanged);
  Step 0.3 names the expected untracked `docs/plans/`; Invariant 3 reworded.
- R-I4 ✅→FIXED: `testAki11QuickTimeCompositesMatchTheirAki12PNGs` un-nests `aki11()` from `XCTUnwrap` (with a
  comment why); Step 7.4 explains the `0 failures`.
- R-I5 ✅→FIXED with R-C1 (failures and skips counted across all bundles).
- R-I6 ✅→FIXED (orchestrator ruling): Invariant 13 and D2 record "raster ops in the banded walk: REFUSED
  (ruled 2026-10-03)"; the docstring cites it.
- R-I7 ✅→FIXED: Research note 18 rewritten as the review words it (+ idioms, the throw = unexpected fact);
  the brief's B5 premise is corrected there.
- R-M1 ✅→FIXED: note 10 says 526 B incl. opcode (524 after), pad byte inside opSize.
- R-M2 ✅→FIXED: twin-test comment and note 16 give 1.77 (ImageIO path) beside PIL's 1.78.
- R-M3 ✅→FIXED: Step 4.3 notes 13 skips at Task 4, 14 after Task 5.
- R-M4 ✅→FIXED: Invariant 12 forbids git WRITE commands in the main checkout; Task 0's status is read-only.
- R-M5 ✅→FIXED: Step 4.1 states why `FLOOR=89` is R2's "fill from the first green run" (Step 3.4's 89).
- R-M6 ✅→FIXED: Step 1.8's "if 0" fallback dropped.
- R-M7 ✅→FIXED: Task 5's env sentence now says only 5.8/5.10 pass `HECTORKIT_DATA_NOVA` (5.11's script sets all).
- R-M8 ✅→FIXED: 5027's fallback described as pen/text state + LongText (`0007 · 0003 · 0004 · 000D · 0010 · 0028`)
  in Known delta 5, note 14, D2, STATE, the source header comment and the 5027 test doc.
- R-M9 ✅ no change needed: Step 7.5 records the replica's "no `Package.resolved`" confirmation.
- R-M10 ✅→FIXED: Research note 21 is now a verified fact with a generic guard.
- R-M11 ✅→FIXED: census header reads "(docs/DECISIONS.md D1, written in Phase-0 Task 8)".
- R-M12 ✅→FIXED: `aki-census` writes the unreadable-`.rsrc` FAIL to stderr.
- Ruling 3 (PICT 135) ✅→FIXED: Known delta 4, Research note 12, census-doc delta 1, `AkiPICTCensusTests`
  comment and STATE "Carried" record that its alpha plane is real (lifted cmpCount-4 path) — a Phase-1 fact.
