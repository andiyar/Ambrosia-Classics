# Plan — Ferazel's Wand Phase 0 + Phase 1: data, decoders, census, level 1 look-and-feel — 2026-10-06

> Status: **REVIEWED — ACCEPT_WITH_FIXES applied (Fable review 2026-10-06, 3 Important / 12 Minor); ready to execute**
> (planner Opus 5.5, 2026-10-06; fixes listed in "Review ledger" at the end). Implements `docs/plans/2026-10-06-ferazel-design.md` (APPROVED) **§8 Phases 0 and 1 only**.
> **Format (Ben, 2026-10-03): CONTRACTS, not code.** Files, public names (signatures only where they pin a seam),
> behaviour with bank anchors, test names verbatim with the number each checks and where it came from, gate commands,
> commit messages. No implementations.
> **Numbers:** every expected value is either from a planner probe run on this machine on 2026-10-06 (cited
> "probe pNN") or from the bank with its section and label. Probe scripts + outputs (not committed):
> `$SCRATCH/probes/p01_census.py … p21` and `out01 … out21` (list in Research notes). Where a probe disagrees with the
> bank, the probe wins and "Bank corrections to append" says so.

**Goal.** Phase 0: the original Ferazel's Wand 1.0.3 data is in git and every resource the game reads decodes
(levels, world, map, conversations, 770 PICTs, 79 cluts, 172 `snd `, 28 AIFC tracks), proven by `ferazel-census` whose
stdout is `docs/ferazel/data-census.md` with 0 failures, plus the Color2Index measurement the design's §6 ruling asked
for. Phase 1: a staged `Ferazel's Wand.app` shows level 1 "A Scent Of Peril" drawn the way `.PaintFrameWrap` draws it —
tiles, blend, overlay, parallax, ambient darkness, water tint, every placed sprite in its Setup face, the status bar at
its start values, through the level CLUT — with the camera driven by the keys and Ferazel standing at his start point,
walking/running in place on left/right. **No physics.** Ben's gate: "does it look like Ferazel".

**Scope.** Design §8 Phases 0 and 1, plus one seat addition: `ferazel-census --render` (PNGs of the level-1 start frame
and two sheets for Ben to look at before the app exists, C6) — not in the design, kept as the seat's addition. Not in
scope: physics, sounds, front end, Caps Lock pause and the Esc abort dialog (all Phase 2–3).

**Architecture (design §3).** Three layers plus the kit. HectorKit (game-agnostic) gains one decoder surface: PICT
pixels as stored (indices + the PICT's own 16-bit colour table, all depths 1/2/4/8, PICT v1 BitMaps) and DirectBits RGB
with its transfer mode (K1). `Ferazel/Core` is one SwiftPM package with two libraries: **FerazelCore** (Foundation +
HectorResources: formats, tables as requested RGB, camera, sprite list, session, seam types) and **FerazelRender**
(+ HectorGraphics/HectorAudio: colour search, faces, tile sets, frame/mask ports, blitters, parallax, status bar, one
indexed 640×480 frame + CLUT → RGBA, PCM). The executable `ferazel-census` is a thin `main` over
`FerazelRender.FerazelCensus`. **Ferazel/App** (AppKit + HectorShell) presents RGBA, plays PCM, maps keys; nothing else.

**Tech:** Swift 6.4 / Xcode 27 beta, SwiftPM tools 6.0, XCTest, macOS 15 deployment, xcodegen (`project.yml` is the
truth). Python 3 only as the planner's probe (never a build or test dependency).

**Paths:**
```
WT      = /Users/andiyar/Developer/Ambrosia-Classics/.claude/worktrees/<lane worktree>   (branched from Classics main)
HK      = /Users/andiyar/Developer/HectorKit            (main 13c8f9b, tag v0.3.0, zero-skip FLOOR 289 at plan time)
HKWT    = /Users/andiyar/Developer/HectorKit-worktrees/ferazel-k1   (branch ferazel-k1, for K1 only)
FW      = "/Users/andiyar/Developer/Ambrosia/Resources/ambrosia-extracted/Action-Adventure/Ferazel's Wand/Ferazel's Wand (installed)/files"
SCRATCH = the executing session's scratchpad directory (logs, PNG dumps, never the repo)
DUMPS   = /Users/andiyar/Developer/Ambrosia-Classics/.claude/worktrees/ferazel-wave2/ghidra/Ferazel_{pef,handlers}.decompiled.c
          (read-only copies in a LOCKED sibling worktree — copy into $WT/ghidra/ (git-ignored) or regenerate with
          ghidra/regen-ferazel.sh; never write into the sibling)
```

---

## Verification model (read first)

**Machine gates — executors close these alone** (copy literally; `$SCRATCH`, `$WT`, `$HKWT` as above):

| # | gate | command | expected |
|---|---|---|---|
| G1 | HectorKit zero-skip (K1 only) | `HECTORKIT_TEST_LOG="$SCRATCH/hk.log" "$HKWT/tools/check-zero-skip.sh" 2>&1 \| tail -n 1` | `PASS: zero skips, zero failures, executed 301 == floor 301` (289 + K1's 12; floor-delta rule, Invariant 9) |
| G2 | `Ferazel/Core` suite | `cd "$WT/Ferazel/Core" && swift test > "$SCRATCH/fz.log" 2>&1; grep -cE "^Test Case '.*' (passed\|failed\|skipped) \(" "$SCRATCH/fz.log"; grep -cE "^Test Case '.*' (failed\|skipped) \(" "$SCRATCH/fz.log"` | the task's ladder total (below), then `0` |
| G3 | census = committed doc (C6 on) | `cd "$WT/Ferazel/Core" && swift build -c release --product ferazel-census > /dev/null && "$(swift build -c release --show-bin-path)/ferazel-census" "$WT/Resources/Ferazel" > "$SCRATCH/census.md"; echo $?; tail -n 1 "$SCRATCH/census.md"` + `testStdoutEqualsCommittedCensus` green | `0`, then `Totals: items 1,108 decoded, failures 0` |
| G4 | data = archive (C0 on) | `cd "$WT/Resources/Ferazel" && for f in *.rsrc; do cmp "$f" "$FW/$f"; done; for f in "Ferazel's Wand Music"/*; do cmp "$f" "$FW/$(basename "$f")"; done; ls *.rsrc \| wc -l; ls "Ferazel's Wand Music" \| wc -l` | no `cmp` output, `6`, `28` |
| G5 | apps build (A1 on; Aki + BTX from C0 on) | `cd "$WT" && xcodegen generate && for s in Ferazel Aki BubbleTroubleX; do xcodebuild -scheme "$s" build 2>&1 \| tail -n 1; done` | `** BUILD SUCCEEDED **` ×3 (Ferazel absent before A1) |
| G6 | scope fence | `git -C "$WT" diff --name-only <task base>..HEAD` | ⊆ the task's **Files** list (+ `docs/DECISIONS.md` where the task says so) |
| G7 | layering (every Ferazel task) | `grep -rnE --exclude-dir=ferazel-census "^import (AppKit\|UIKit\|SwiftUI\|CoreGraphics\|CoreText\|ImageIO\|AVFoundation\|QuartzCore)" "$WT/Ferazel/Core/Sources"`; `grep -rnE "^import (HectorGraphics\|HectorAudio)" "$WT/Ferazel/Core/Sources/FerazelCore"` | both empty. The one exception, excluded from the first grep: `Sources/ferazel-census` may import ImageIO (behind `#if canImport(ImageIO)`) for `--render`, as the Deimos census does (Invariant 1) |
| G8 | kit game-agnostic (K1) | `grep -rniE "ferazel\|ambrosia" "$HKWT/Sources" --include=*.swift \| grep -v HectorTestSupport` | empty |
| G9 | staged app boots (A2) | `open "$WT/out/Ferazel/Ferazel's Wand.app"; sleep 6; pgrep -x "Ferazel's Wand"; osascript -e 'quit app "Ferazel'"'"'s Wand"'; ls -t ~/Library/Logs/DiagnosticReports \| head -3` | a pid; clean quit; no new crash report naming the app |
| G10 | clean tree per commit | `git -C "$WT" status --porcelain \| grep -v '^??'` | empty after every commit |

**Test ladder (`Ferazel/Core`, cumulative, canonical merge order; STOP if different):**
C1 **6** → C2 **21** → C3 **28** → C4 **43** → C5 **56** → C6 **60** → R1 **69** → R2 **74** → R3 **81** → R4 **88**
→ R5 **94** → R6 **100**. If lanes merge in another order the expected total is the previous total + the merged task's N.
HectorKit: 289 → K1 **301**.

**Honesty gate (Ben only):** the Phase 1 gate card (A2, "What Ben checks"). Completion is phrased "machine gates
green; Ben's gate pending" — never "looks like Ferazel" until he says so. Phase 0 has no Ben gate (design §8).

**What the machine does NOT prove:** which palette index QuickDraw's `Color2Index` really chose (LOW, design §6 — now
known to reach every face pixel, not only the computed tables: Research note 9); QuickDraw's `ditherCopy` algorithm for
the 326 32-bit PICTs (LOW, Research note 10); every MED surface on the gate card.

---

## Non-negotiable invariants

1. **Layering (HectorKit D6, Classics D12, design §3).** `FerazelCore` imports Foundation + HectorResources only.
   `FerazelRender` adds FerazelCore, HectorGraphics, HectorAudio — no Apple UI/graphics/audio framework. `Ferazel/App`
   is the only code importing AppKit/HectorShell (CoreText only inside its `TextRasterizer`). Tests may use Apple
   frameworks as oracles. **The only exception:** the `ferazel-census` executable target may import ImageIO behind
`#if canImport(ImageIO)` for `--render` (Deimos census precedent; G7 excludes `Sources/ferazel-census`; `FerazelCensus`
in FerazelRender stays framework-free and hands the executable indexed frames + CLUTs). Windows traps
   (D18/W0.5): no `String.Encoding.macOSRoman` (use `HectorResources.MacRoman`), resolve symlinks before enumerating.
2. **Kit stays game-agnostic.** No type, symbol or doc comment under `$HKWT/Sources` (outside `HectorTestSupport`)
   says "Ferazel" or "Ambrosia" (G8). Game names live in test files and the `HectorData+Ferazel.swift` locator only.
3. **Transcribe, don't reinvent.** Core records what the original drew at its call sites (`FrameOps`); Render executes
   the transcribed blitters on persistent 8-bit ports, artefacts included (the ring-buffer split, the as-written PxMid
   row arithmetic, the word-add blend rules). Every behaviour cites its bank section; a contract here never overrides
   the bank — if they disagree, STOP and report.
4. **No modern affordances** (CLAUDE.md standing ruling). The only Phase-1 additions are the disclosed stubs
   (PlayerPose, the camera-focus key driver, SetupFaces) and the design §7 deviations; each is listed on the gate card.
5. **Data in git, tests never skip.** Tests read the committed `Resources/Ferazel` (found by walking up from
   `#filePath`); `FERAZEL_DATA` overrides the folder. A missing file is a test FAILURE with the path named, never a skip.
6. **Refuse what the census hasn't shown** (HectorKit D2/D5 style). K1's pixel path and C5's face encoder throw a named
   error, with a synthetic test, for any shape outside the census (Research notes 4–6): more than one bits opcode, a
   DirectBits pack type ≠ 4 or cmpCount ≠ 3, an indexed transfer mode ≠ 0, a DirectBits mode ≠ 64, a v1 opcode other
   than 0x11/0x01/0x98(BitMap)/0xFF, an RLE token ≥ 4.
7. **Both colour models live, one ruled.** `ColorSearch` implements `.exactNearest` and `.ruled` (design §6: exact match
   → lowest index, else the 4-bit inverse table) and the 5-bit variant; every table and every face conversion takes the
   model as a parameter; the app default is `.ruled`. Same for dithering (`.none` / `.errorDiffusion`, default
   `.errorDiffusion`, Research note 10). Never hard-code one model inside a blitter.
8. **Commits.** Explicit paths only — never `git add -A` / `git add .`; never `git stash`. Trailer on every commit, both
   repos, nothing else: `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`. G10 after each commit.
9. **HectorKit floor-delta rule.** K1 works in `$HKWT` (branch `ferazel-k1`), rebases onto `origin/main` immediately
   before the fast-forward push, re-runs G1 on the rebased tree and sets `FLOOR` to the printed total (other sessions may
   have landed tests). Classics consumes HectorKit only from `~/Developer/HectorKit` main after `git -C ~/Developer/HectorKit
   pull --ff-only` (clean checkout, no builds there), through the `.claude/worktrees/HectorKit` symlink (D1).
10. **STOP on any unexpected number** — counts, hashes, test totals, census lines. Report the command output; never
    edit an expectation or the code to make them agree.
11. ⚠️ **LANDMINES.** (a) `swift test` has no package-wide total: count `^Test Case` lines (G2). (b) `swift run` mixes
    build output into stdout: run the built binary (G3). (c) SwiftPM rejects a declared target with no sources:
    `Package.swift` grows task by task. (d) Names with apostrophes and spaces (`Ferazel's Wand Music`, the app) — quote
    every path in scripts and tests. (e) D-numbers collide across sessions: the design's rulings are **D26**
    (D25 is taken on `origin/main` by the BTX 1.0 release, `b7560ab`; D24 by the Deimos branch). Confirm D26 is still
    the next free number on `main` at commit time; if not, take the next free one and renumber every reference in the
    same commit.

---

## Shared architecture (LOCKED — every task codes against these names)

### S1. Package `Ferazel/Core`
`Package.swift` (tools 6.0, `platforms: [.macOS(.v15)]`, header comment naming this plan), dependency
`.package(path: Context.environment["HECTORKIT_PATH"] ?? "../../../HectorKit")` (Deimos precedent). Products: library
`FerazelCore`, library `FerazelRender`, executable `ferazel-census`. Targets: `FerazelCore` (HectorResources),
`FerazelRender` (FerazelCore, HectorResources, HectorGraphics, HectorAudio), `ferazel-census` (FerazelRender only + the
kit products it needs), test targets `FerazelCoreTests` (FerazelCore, HectorResources) and `FerazelRenderTests`
(FerazelRender, FerazelCore + kit). Targets are added only when their first source lands (Landmine c).

### S2. FerazelCore public surface (by task; ★ = LOCKED after Phase 1, ◇ = Phase-1-only stub, replaced later)
- ★ `FerazelData` — `static func dataDirectory() throws -> URL` (`FERAZEL_DATA` else walk up from `#filePath` to
  `Resources/Ferazel`); `static func open(_ directory: URL) throws -> FerazelResources`; error `FerazelDataError.missing(String)`.
- ★ `FerazelResources` — the six resource collections (`app`, `world`, `backgrounds`, `sprites`, `sounds`, `titles`),
  `musicDirectory: URL`, and `func resource(type: String, id: Int16, chain: ResourceChain) -> Resource?` with
  `enum ResourceChain { case frontEnd /* Sprites → Sounds → Titles → app (engine §2, rendering §4) */, level /* World
  → Backgrounds → Sprites → Sounds → Titles → app (sprites-backgrounds §1) */ }`.
- ★ `LevelFile` (`Mlvl`), `LevelHeader` (named fields, Research note 7), `TileMap` (`width`, `height`, raw `UInt16`
  cells, `cell(col:row:)` clamping through `.ConstrainXY` semantics, world-data §3.3 — **(column, row)** order),
  decoded accessors `bgTile/lightByte/fgTile/crunchKind/crunchDir/overlay1/overlay2(col:row:)`, `fgKind(tile:)` /
  `bgKind(tile:)` (header tables, FG kinds 0x50..0x5f overwritten by 80..95), `backFactors/midFactors: [Int16]` (8192
  each), `Placement` (`index, flag, byte1, type, p1, p2, p3, p4, y, x`), `placements` (511), `activePlacements`.
- ★ `WorldFile` (`Mwld 0`), `WorldMap` (`Mmap 200` nodes), `Conversation` (`Mcnv` 20 line records), `StringList`
  (`STR#`, Mac Roman).
- ★ `SpriteClass` (23 cases incl. `.effect`), `SpriteClassTable.classify(type:p1Negative:) -> (SpriteClass, Spawn)?`
  with `enum Spawn { case now, idle }` — world-data §3.5 transcribed (cross-check: `docs/ferazel/tools/gensprite_map.py`).
- ★ `ColorLUT` (`clut`: name, seed, 256 × 16-bit RGB, `value` fields rewritten to the index as `.SetScreenClut` does).
- ★ `TableRequests` — the requested 16-bit RGB of every computed table entry (lighting-tables §3 tint bank incl. the
  fixed-index and `sel`-only rows and table 0xa with an injected random source, §4 water, §5 redden A/B, §6.1 pair
  tables, §7.3 ambient + light groups). Pure arithmetic, HIGH; never an index.
- ★ Seams (S3). ★ `FerazelPrefs`, `InputActions`, `KeyState`, `GameGlobals` (start values only in Phase 1).
- ★ `Camera` (engine §5 `.FindUpperLeftCorner` arithmetic, LOCKED) with ◇ `CameraFocusDriver` (Phase 1: keys move the
  focus point; replaced by `.PlayerScroll` in Phase 2).
- ★ `SpriteSlot` + `ActiveList` (layer-sorted insertion rule, physics §0 `+0x80`; platforms-ropes-radial-2 §8) and
  `IdleSprites` (triggers-background-2 §8.3); ◇ `SetupFaces` (per placed type: the face, layer, `+0xb8`, `+0x17e`,
  `+0x88/+0x89`, position adjustment and idle margins the class Setup leaves — replaced by the class Setup routines in
  Phases 4–5); ◇ `PlayerPose` (start position, facing, stand/turn/walk/run/fidget faces of player-states §3.11 — replaced
  by `.HandlePlayerSprite` in Phase 2).
- ★ `FerazelSession` — `init(resources: FerazelResources, prefs: FerazelPrefs, level: Int) throws`;
  `func step(keys: KeyState) -> FrameOps` (one `.GameLoop` iteration; draws then logic, engine §4).

### S3. Seam types (FerazelCore; ★ LOCKED once Phase 1 lands — cases may be added, never renamed)
```swift
public struct FrameOps: Equatable, Sendable {
    public var draws: [DrawOp]; public var sounds: [SoundCue]; public var music: [MusicCue]
    public var requests: [ShellRequest]; public var drawn: Bool        // false on a skipped draw (prefs[0] odd frame)
}
public enum DrawOp: Equatable, Sendable {                // one case per original call site, in .PaintFrameWrap order
    case setScreenClut(id: Int16)                           // .SetupLevel → .SetScreenClut(level+base)
    case drawPicture(id: Int16, chain: ResourceChain, h: Int, v: Int)   // PICT 129 'Game Screen' at level start
    case redrawScrollGrid(h: Int, v: Int)                  // .SetScrollLocation → .RedrawScrollGrid
    case drawLightsOntoTiles                               // skipped by the caller when prefs+6 == 3
    case wrapDrawSprites([SpriteDraw])                     // active-list order (draw-effects §1.1)
    case copyToScreen(h: Int, v: Int, graphicsMode: Int, backdrop: Bool)   // .WrapCopyToScreen (rendering §1.1)
    case statusBar(StatusBarState)                         // .UpdateStatusBar(1,0,0)
}
public struct SpriteDraw: Equatable, Sendable {           // what .WrapDrawSprites reads per sprite
    public var face: FaceRef; public var x: Int; public var y: Int; public var mode: UInt32   // effective +0xb8
    public var mirrored: Bool; public var clip: SpriteClip   // +0x1b6 left / +0x1b8 right / +0x1ba bottom / +0x1bc top
    public var lightOverlay: Bool; public var waterRow: Int  // +0x88 gate result; +0x11c (0 in Phase 1)
}
public struct FaceRef: Hashable, Sendable { public var pict: Int16; public var index: Int; public var set: FaceSetKind }
public struct SoundCue: Equatable, Sendable { public var snd: Int16; public var priority: Int; public var left: Int; public var right: Int; public var rate: UInt32 }
public enum MusicCue: Equatable, Sendable { case play(track: Int), stop, volume(Int) }
public enum ShellRequest: Equatable, Sendable { case hideCursor, showCursor, hideMenuBar, showMenuBar }
```
`FaceSetKind` (`.encoded`, `.flipped`, `.fgWater`, `.plain`), `SpriteClip`, `StatusBarState` (score, coins, health,
breath, magic, level name, selected slot) are plain value types beside them.

### S4. FerazelRender public surface
- `PictureSource` — wraps K1 `PICT.decodePixels`; `ColorSearch` (`enum Model { case exactNearest, ruled, inverseTable(bits: Int) }`,
  `func index(of rgb: RGB16, in: ColorLUT) -> UInt8`, inverse tables cached per (CLUT seed, bits)); `DitherModel`
  (`.none`, `.errorDiffusion`); `ConvertedPicture` (PICT → 8-bit indices under a conversion CLUT, the loader's path:
  sprites-backgrounds §2 "Conversion path").
- `EncodedFace` (face record fields §2.1 + RLE token stream §2.2), `FaceEncoder` (`.EncodeRect`), `FaceSheet`
  (`.LoadEncFaceSetFromPICT` cell arguments), `PlainFaceSheet` (`.LoadPlainFaceSetFromPICT`), `WaterFaceSheet`
  (`.LoadEncWaterFaceSetFromPICT`), `BlendFaces` (`.ProcessFGBlendTileFace`), `TileSets` (BG, FG, FG-water, pattern
  encoded + plain, PxBack, PxMid pair; fixed sets 183, 185), `LevelTables` (TableRequests resolved through ColorSearch).
- `FramePorts` (640×416 frame `000c`, mask `0008`, third `0004`, ring addressing `x mod 640`, `y mod 416`),
  `TileGridRenderer`, `LightRenderer`, `ParallaxBlitter`, `SpriteBlitter`, `StatusBar`, `protocol TextRasterizer`
  (the App implements it; BTX precedent), `FrameRenderer` (`init(resources:level:search:dither:text:) throws`,
  `func apply(_ ops: FrameOps)`, `var screen: IndexedFrame`, `var screenClut: ColorLUT`), `IndexedFrame` (640×480
  indices; `func rgba(through: ColorLUT) -> [UInt32]`, 0xAARRGGBB row 0 top = `ShellBitmap.pixels`).
- `SoundBank` (`snd ` → kit `SndPCM`), `MusicTrack` (AIFC file → kit `AIFFAudio` → `SndPCM`), `FerazelCensus`
  (`static func render(dataDirectory: URL) -> (stdout: String, failures: Int)`).

### S5. App `Ferazel/App` (AppKit, `@MainActor`, no test target — Aki/BTX precedent)
`FerazelMain.swift` (entry, Aqua forced, D4.1), `FerazelController.swift` (app delegate, `ShellInputHandler`, owns the
timer/session/renderer/mixer), `FerazelAssets.swift` (bundle locator: `Contents/Resources/Ferazel/`), `FerazelAudio.swift`
(music voice on `ShellMixer`), `CoreTextRasterizer.swift`, `Info.plist`, `AppIcon.icon`.

### S6. `project.yml` additions (a MERGE into the existing top-level keys — never a second copy; BTX R11)
```yaml
packages:
  FerazelCore:
    path: Ferazel/Core
targets:
  Ferazel:
    type: application
    platform: macOS
    sources:
      - path: Ferazel/App
        excludes: ["Info.plist"]
    dependencies:
      - package: FerazelCore
        product: FerazelCore
      - package: FerazelCore
        product: FerazelRender
      - package: HectorKit
        product: HectorShell
    settings:
      base:
        PRODUCT_NAME: "Ferazel's Wand"
        PRODUCT_BUNDLE_IDENTIFIER: com.ambrosiaclassics.ferazel
        INFOPLIST_FILE: Ferazel/App/Info.plist
        GENERATE_INFOPLIST_FILE: NO
        ASSETCATALOG_COMPILER_APPICON_NAME: AppIcon
        ENABLE_APP_SANDBOX: NO
schemes:
  Ferazel:
    build:
      targets:
        Ferazel: all
```

### S7. Runtime data
`Resources/Ferazel/` (committed, C0) = the six `.rsrc` files under their original names + folder
`Ferazel's Wand Music/` holding `01`..`30` (28 files; the original install path, world-data §1). The staged `.app`
carries the same tree under `Contents/Resources/Ferazel/` (D10); `FerazelAssets` resolves it from `Bundle.main`.

---

## Tasks

Legend: ⚑ MAJOR = two review legs (spec compliance, then quality; Fable reviewers, report everything with
confidence); minor = one leg doing both. "+N" = new `Test Case`s. Every task: G6, G7, G10; the gates named per task.

### K1 — ⚑ MAJOR (new public kit API + refusals; two review legs) — HectorKit: PICT pixels as stored, public 16-bit ColorTable, v1 BitMaps (+12, kit)
- **Files ($HKWT):** new `Sources/HectorGraphics/PICT+Pixels.swift`; `Sources/HectorGraphics/PixMapRecord.swift`
  (ColorTable public + 16-bit channels, additive); new `Sources/HectorTestSupport/HectorData+Ferazel.swift`; new
  `Tests/HectorGraphicsTests/PICTPixelsTests.swift`, `Tests/HectorGraphicsTests/FerazelPICTCensusTests.swift`;
  `tools/check-zero-skip.sh` (export + echo `HECTORKIT_DATA_FERAZEL`, default `$FW`; FLOOR); `docs/DECISIONS.md`
  (next free HectorKit D-number, expected **D11**); `docs/STATE.md` (one line).
- **Contract (additive; `PICT.init` / `decodeAny` unchanged):**
  ```swift
  public enum PICTPixels: Sendable, Equatable { case indexed(IndexedPICT), direct(DirectPICT) }
  public struct IndexedPICT: Sendable, Equatable {
      public let width: Int, height: Int, depth: Int        // 1, 2, 4 or 8
      public let pixels: [UInt8]                            // one value per pixel, frame-sized, row-major from the frame's top-left
      public let colorTable: ColorTable?                    // nil for a BitMap (bit 1 = foreground, 0 = background)
      public let transferMode: Int, version: Int            // as stored; version 1 or 2
  }
  public struct DirectPICT: Sendable, Equatable { public let width: Int, height: Int; public let rgb: [UInt8]; public let transferMode: Int }
  extension PICT { public static func decodePixels(data: Data) throws -> PICTPixels }
  ```
  `ColorTable` becomes `public` with `seed: UInt32`, `flags: UInt16`, `entries: [ColorSpec]` (`value`, 16-bit `r/g/b`)
  and `func rgb16(index: Int) -> (r: UInt16, g: UInt16, b: UInt16)?` (same index rule as today: `ctFlags & 0x8000` →
  position, else `value`). Version 2: opcodes 0x0011/0x0C00/0x0001/0x001E/0x001F/0x00A0/0x00A1 skipped as `PICT.init`
  does; exactly one 0x0098 (PixMap 1/2/4/8-bit, high bits first) or 0x009A (32-bit packType 4, cmpCount 3) per picture.
  Version 1 (`0x11 0x01`, byte opcodes, no word alignment): 0x01 clip, 0x98 with a **BitMap** (rowBytes bit 15 clear,
  1 bit/pixel), 0xFF end. Bounds ≠ frame are placed as `PICT.init` places them. Refusals (Invariant 6, named
  `PICT.DecodeError.unsupportedPixels(String)`: `"bitsCount"`, `"directPack"`, `"cmpCount"`, `"indexedMode"`,
  `"directMode"`, `"v1Opcode"`). Doc comments describe formats, never a game.
- **Tests — `PICTPixelsTests` (synthetic, 8):** `testIndexed8BitReturnsIndicesAndTable` · `testIndexed4And2And1BitHighBitsFirst`
  · `testDeviceRelativeTableIndexesByPosition` · `testColorTableKeeps16BitChannels` (0x8282 stays 0x8282) ·
  `testVersion1BitMapDecodes` · `testDirectBitsReturnsRGBAndMode` (mode 64 round-trips) ·
  `testRefusesUncensusedShapes` (each of the six refusal strings) · `testTruncatedAndHostileInputThrowsNeverTraps`
  (every prefix of a valid v1 and v2 picture throws).
- **Tests — `FerazelPICTCensusTests` (`HECTORKIT_DATA_FERAZEL`, 4):** `testAllPICTsDecodeByPath` — Sprites 584 = 8-bit
  284 · 4-bit 9 · direct 290 · v1 1; Backgrounds 113 = 88 · 1 · 20 · v1 4; Titles 67 = 8-bit 49 · 4-bit 1 · 2-bit 1 ·
  direct 16; app fork 5 8-bit; World Data 1 8-bit; 770 total, 0 throws (probes p03, p15) ·
  `testTablesFlagsAndModes` — every indexed table `ctFlags` 0 (439/439), every indexed mode 0, every direct mode 64
  (326/326) (p04, p15) · `testVersion1MaskSheets` — Sprites 183 256×384 with 29,595 set bits; Backgrounds 319/329/339
  768×256 with 44,880 / 40,153 / 42,935; 350 768×768 with 294,912 (p16) · `testWalkSheet1020` — 400×480, 8-bit, 51
  table entries, index 0 used by 169,957 pixels (p05).
- **Gate:** G1 = **301** (or rebased base + 12), G8. **Commit:** `HectorGraphics: PICT.decodePixels — indices + 16-bit ColorTable for 1/2/4/8-bit and v1 BitMaps, DirectBits RGB + mode; HECTORKIT_DATA_FERAZEL census; floor <n>`.
  Rebase on `origin/main`, re-gate, `git push origin HEAD:main`, then clean `pull --ff-only` in `~/Developer/HectorKit`.
- **Deviations the seat may settle alone:** helper/internal names; whether `IndexedPICT` keeps the frame origin.
  **Ben's:** none.

### C0 — minor — Data into git + D-entry
- **Files:** `Resources/Ferazel/{Ferazel's Wand.rsrc, Ferazel's Wand World Data.rsrc, Ferazel's Wand Backgrounds.rsrc, Ferazel's Wand Sprites.rsrc, Ferazel's Wand Sounds.rsrc, Ferazel's Wand Titles.rsrc}`,
  `Resources/Ferazel/Ferazel's Wand Music/{01..20,22..26,28..30}` (copied byte-identical from `$FW`, `cp -p`);
  `.gitignore`; `.gitattributes`; `docs/DECISIONS.md`.
- **Steps / contract:** `.gitignore`: if `/Resources/` is still a whole-directory ignore (main today), change it to
  `/Resources/*` and add `!/Resources/Ferazel/`; if the Deimos merge already made it `/Resources/*`, add only
  `!/Resources/Ferazel/`. `.gitattributes`: add `Resources/Ferazel/** binary`. `git status --porcelain --ignored
  Resources` must show `Resources/Aki/` still ignored and exactly 34 new files under `Resources/Ferazel/`. Not
  committed: the PEF binary, `Ferazel's Wand Documentation*`, the 28 `NN.rsrc` SoundEdit leftovers, the Notes/License
  texts, `Icon_*`, InputSprocket files, the `.pict` files, `.DS_Store` (design §4). DECISIONS (**D26**, Landmine e): **"Ferazel's Wand build: Ben's five rulings; data in git; layering"** — the design §10
  rulings 1–5 verbatim; the seat rulings (three layers §3, data-in-git D24 shape, Color2Index model §6, deviations §7,
  phase scoping §8; **PICT 257's short last row reads 0** — seat ruling, alternative named and rejected: design §11's
"whatever the port held" (undefined, not reproducible); the census flags the sheet, C5); the committed tree with sizes and SHA-256 (Research note 1; total 85,281,911 B, largest file
  15,821,213 B — no GitHub size warning); `FERAZEL_DATA` override; rejected: LFS, symlinked data (D24 reasons).
- **Gate:** G4; G5 (Aki + BubbleTroubleX only); G10. **Commit:** `Resources/Ferazel: original Ferazel's Wand 1.0.3 data (6 resource files + 28 music tracks) in git; .gitignore/.gitattributes; DECISIONS D<n>`.
- **Seat alone:** the `.gitignore` comment wording. **Ben's:** none (standing ruling).

### C1 — minor — `Ferazel/Core` skeleton, data locator, resource files (→ 6)
- **Files:** `Ferazel/Core/Package.swift` (FerazelCore + FerazelCoreTests only); `Sources/FerazelCore/Data/{FerazelData,FerazelResources,ResourceChain}.swift`;
  `Tests/FerazelCoreTests/FerazelDataTests.swift`.
- **Contract:** S2 rows `FerazelData`, `FerazelResources`, `ResourceChain`. Opens the six data-fork resource maps through
  HectorResources (`ClassicResourceMap`); music = files named `NN` in `Ferazel's Wand Music` (no decode here).
- **Tests (6):** `testDataDirectoryResolvesCommittedFolder` · `testOverrideAndMissingFileNamed` (temp dir lacking
  Sounds → `missing("Ferazel's Wand Sounds.rsrc")`) · `testSixResourceFilesCounts` — resources/types: app 164/28,
  World Data 60/7, Backgrounds 194/7, Sprites 587/3, Sounds 175/3, Titles 86/4 (p01 = INDEX census) ·
  `testKeyTypeCounts` — PICT 5/1/113/584/0/67, clut 6/0/57/0/0/16, `snd ` 172, Mlvl 24, Mcnv 29, Mmap 1, Mwld 1,
  STR# app 2 + World 2 (p01) · `testMusicFolderTwentyEightTracks` — 01..30 minus 21 and 27, sizes of Research note 1
  (p08) · `testResourceChainOrder` — `PICT 7000` in `.frontEnd` resolves to the app fork's copy (save-continue §8.4,
  rendering §6.2); `PICT 183` in `.level` resolves to Sprites; `clut 200` is byte-identical in app and Backgrounds (p06).
- **Gate:** G2 = **6/0**. **Commit:** `Ferazel/Core: package, FerazelData locator, six resource files + music folder, resource chains; 6 tests`.

### C2 — ⚑ MAJOR — World data parsers: Mlvl, Mwld, Mmap, Mcnv, STR#, sprite type → class (→ 21)
- **Files:** `Sources/FerazelCore/World/{LevelFile,LevelHeader,TileMap,Placement,WorldFile,WorldMap,Conversation,StringList,SpriteClassTable}.swift`;
  `Tests/FerazelCoreTests/{LevelFileTests,WorldDataTests,SpriteClassTableTests}.swift`.
- **Contract:** world-data §2–§4 (HIGH) and conversations-mcnv §2.2 (HIGH). Mlvl layout §3.1: header 0xb29c B, then
  PxBack w0×h0, PxMid w1×h1, then BG, FG, map #5, overlay at w2×h2 (u16 big-endian, row-major); the stale runtime
  pointers 0xb284..0xb298 are ignored; refuse a resource whose length ≠ `0xb29c + 2(w0h0 + w1h1) + 8·w2h2`.
  Header fields of Research note 7 by name. Cell decodes §3.3 (BG low byte −1 tile / high byte −1 light; FG bits 0–7
  −1, 8–11 crunch kind, 12–15 crunch dir; overlay low −1 = o1, high −1 = o2; PxMid 0xFFFF kept as −1). Placement record
  §3.4, spawn order (type 0x51b first, then 0x578..0x595, then the rest). Mmap §4.2 (128 × 0x128 + 256 zero bytes).
  Mcnv: 0x100 header pstr + 20 × 0x72a line records, fields of conversations-mcnv §2.2. `SpriteClassTable` = world-data
  §3.5 table (incl. the p1 < 0 "now" rule for 1090..1099 and the dead `0x726 → Effect` arm); unknown types → nil.
- **Tests (15):** `LevelFileTests` (8): `testTwentyFourLevelIdsAndExactLayout` — ids 1,2,3,4,5,10,11,15,18,20,21,22,25,30,31,40,45,50,51,52,55,62,67,70, sizes of Research note 7, every layout exact (p02) ·
  `testLevel1Header` — every field of Research note 7's level-1 row (p02) · `testAllLevelsHeaderCensus` — OmniPx modes
  {0: 20 levels, 1: L15, 2: L5, 5: L25, 6: L70}; PxMid enabled in exactly 10,15,21,22,30,31,40,45,50,51,52,55,62,70;
  strip PICTs L10 265 · L30 275 · L40/L45 315 · L62 345 · L67 385; start-left (0x26c8 = 1) in 3,5,11,18,40,45; flame
  L52 = 1, L55 = 2; CLUT animation L50/L51 mode 1, L67 mode 3; chapters 1→1, 10→2, 40→3, 50→4, 22→5, 30→6, 62→7;
  0x26cc = 1 in 62 and 70 (p02) · `testLevel1Maps` — BG: 8,353 cells with no tile, 73 distinct tiles (74 counted the none value), light bytes
  {1:1931, 2:472, 3:491, 4:449, 5:511, 6:656, 7:880, 8:1166, 9:1048, 10:1060, 11:1293, 12:43}; FG: 7,274 non-zero
  cells (world-data §3.3), 7,270 with a tile, 5,710 pattern-tile (95) cells, crunch kind set in 3, crunch-dir nibble set
  in 225; map #5 all zero; overlay 20 non-zero, all o1 = 100 (12 × o2 95, 3 × 0, 2 × 2, 1 each × 8, 9, 10); PxMid 256
  cells all −1; PxBack 256 cells (cell 16 × 69) (p02) · `testLevel1KindTablesAndWater` — FG/BG kind tables of
  Research note 8; water cells kind 0 (BG kind 200) 268 and kind 1 (201) 24 (p02, p18) · `testFactorTablesLevel1` —
  back factors 128 except virtual rows 276..412 = 64; mid factors all 128 (p19) · `testPlacementsLevel1` — 162 active;
  Bonus 81, Box 43, Background 16, Platform 7, Walker 7, Roach 5, Crawler 3; 2 flag-0 records with a type; rec 0 =
  (type 2922, y 666, x 5455), rec 1 = (2902, p1 12, y 439, x 406) (p02; world-data §3.4 worked decode) ·
  `testAllLevelsPlacementCensus` — 5,641 active, 243 distinct types, 48 flag-0 typed, exactly one other flag: 99 at
  level 11 record 283 type 2956 (p21; world-data §3.4).
  `WorldDataTests` (4): `testMwld` — name "Teraknorn", stamp 0x152be0ed, +0x144 = 2, +0x1c4 = 1, +0x1c6 = 100 (p12) ·
  `testMmapTwentyFourNodes` — the node list of Research note 11 (node 60 → level 62, node 62 → level 67; face 1 on
  nodes 5, 18, 25, 55, 62; 256 zero tail bytes) (p12) · `testStringLists` — STR# 1000 has 99 strings (string 1 "A
  Scent of Peril", 51 "If You Can't Stand The Heat…"), STR# 500 has 19 (p02, p12) · `testMcnvRecords` — 29 ids
  200..401 (list in Research note 11), 580 line slots, 198 with text, 183 with portrait ≠ 0, Mcnv 200 header
  "Rojinko Conv" (p12).
  `SpriteClassTableTests` (3): `testEveryPlacedTypeHasAClass` — all 243 placed types classify; class totals over 24
  levels of Research note 12 (p21) · `testLevel1ClassesAndSpawn` — L1 spawn-now: Platform 7, Bonus 1 (type 1335),
  Background 2 (1485 ×2); every other L1 record idle (p02) · `testSpawnOrder` — level 1 spawn sequence starts with the
  22 records of type 1307 (0x51b), then the 7 platforms (p02).
- **Gate:** G2 = **21/0**. **Commit:** `FerazelCore: Mlvl/Mwld/Mmap/Mcnv/STR# parsers, tile-map decodes, placements, sprite type → class table; 15 tests`.
- **Seat alone:** internal decomposition, error names. **Ben's:** none.

### C3 — minor — CLUTs, `snd `, AIFC music (→ 28)
- **Files:** `Package.swift` (add `FerazelRender`, `FerazelRenderTests`); `Sources/FerazelCore/Color/ColorLUT.swift`;
  `Sources/FerazelRender/Audio/{SoundBank,MusicTrack}.swift`; `Tests/FerazelCoreTests/ColorLUTTests.swift`;
  `Tests/FerazelRenderTests/AudioDecodeTests.swift`.
- **Contract:** `ColorLUT` parses `clut` (ctSeed, ctFlags 0, 256 `ColorSpec`s), all 79 across app/Backgrounds/Titles
  (sprites-backgrounds §4, lighting-tables §1). `SoundBank` decodes `snd ` through `SndSound(data:)` +
  `linearPCM()` (format 1, one `bufferCmd`, 8-bit offset binary, sprites-backgrounds §6.1; the Sound Tool's own
  `−0x80` load path §6.2 is Phase 2's mixer, not here). `MusicTrack` opens `NN` through `AIFFAudio` and decodes
  `ima4` with the kit (design §7.7; world-data §1).
- **Tests (7):** Core (4): `testSeventyNineCLUTsAll256Entries` — app 6, Backgrounds 57, Titles 16, all ctFlags 0
  (p06) · `testDuplicateCLUTIdsIdentical` — 198, 199, 200, 700, 801, 4000 byte-identical in app and Backgrounds (p06;
  lighting-tables §1.1) · `testPlusBaseCLUTsShareSpriteRange` — 24 '+ base' CLUTs (202, 204, …, 232, 236, …, 248 — the 23 named "+ base" — and 322) have entries
  0x00..0x9f equal to clut 200 and 0xff equal; 0xa0 equal only in 202 (p06; corrects the bank's "23") ·
  `testSixteenLevelCLUTs` — the level+base CLUTs the 24 levels name: 202, 210, 212, 214, 216, 218, 220, 222, 224, 228,
  236, 238, 240, 242, 246, 248 (p02). Render (3): `testAll172SndDecode` — format 1 ×172, rates 22050 Hz ×138,
  11025 Hz ×33, 22254.545… Hz ×1, total 2,432,217 samples (p07; sprites-backgrounds §6.1) · `testSnd128SoftImpact` —
  8,896 samples, 22050 Hz, first three PCM samples 512, 512, 256 ((s − 128) << 8 of 0x82 0x82 0x81) (p07;
  sprites-backgrounds §6.1 xxd) · `testTwentyEightAIFCTracksDecode` — each track 2 ch, 22050 Hz, `ima4`, packets of
  Research note 13 (total 694,051 packets = 44,419,264 frames); decode one at a time (p08).
- **Gate:** G2 = **28/0**. **Commit:** `Ferazel/Core: ColorLUT (79 cluts), SoundBank (172 snd), MusicTrack (28 AIFC) over HectorAudio; 7 tests`.

### C4 — ⚑ MAJOR — Table requests, ColorSearch, the Color2Index measurement (→ 43)
- **Files:** `Sources/FerazelCore/Tables/TableRequests.swift`; `Sources/FerazelRender/Color/{ColorSearch,InverseTable}.swift`;
  `Tests/FerazelCoreTests/TableRequestsTests.swift`; `Tests/FerazelRenderTests/ColorSearchTests.swift`; `docs/DECISIONS.md`
  (append to C0's entry: "Color2Index measured" + the dither ruling, Research notes 9–10).
- **Contract:** `TableRequests` transcribes lighting-tables §3.1 (25 tint tables; `lum = (R+G+B)/3` truncating; "sel"
  indices 0x24, 0x3b, 0x3f, 0x40, 0x4e, 0x53, 0x57, 0x5b, 0x71..0x76; fixed-index rows as constants; 0xa with an
  injected random source), §4 (water w 0..3, 5; table 4 never written = all index 0), §5 (redden A n 0..7 with the
  `& 0xfffe` wrap and entry 0xff forced; B n 0..15), §6.1 (pair tables, 256×256, row = sprite pixel), §7.2–§7.3
  (`.CalcAmbientDarken` in **single precision**, `fctiwz` then `sth` wrap; ambient D 0..15; light groups g 0..9 ×
  k 0..10 × D 0..15). Constants' widths: the §3/§4 multipliers are f64 (`tools/const.py`, Research note 14). Output is
  16-bit RGB requests, never an index. `ColorSearch` (S4): `.exactNearest` = least squared Euclidean distance on the
  16-bit channels over all 256 entries, ties → lowest index; `.inverseTable(bits: n)` = a 2^(3n)-cell table whose cell
  colour is each channel's n-bit value **bit-replicated** to 16 bits, each cell mapped by `.exactNearest`, a request
  looked up by its top n bits per channel; `.ruled` = an entry whose RGB equals the request exactly → the lowest such
  index, else `.inverseTable(bits: 4)` (design §6). The measurement is a test, and C6 prints it.
- **Tests (15):** Core (7): `testTintRequestsCLUT202` — the requested-RGB cells of lighting-tables §3.2 (high bytes),
  e.g. k1 @00 ff0000, k2 @00 ffff9c, k0xe @2a 3f1f00, k0x16 @06 bf5f5f · `testFixedIndexTables` — 0xf, 0x12, 0x13,
  0x14, 0x15, 0x17, 0x18 rows of §3.1 (e.g. 0x17 @31 → 0xff) · `testWaterRequestsCLUT202` — §4 table (w0 @00 7f7fff,
  w1 @00 c7ff71, w3 @00 ff3fff, w5 @00 b5a068) · `testReddenRequestsWrap` — A7 @06 → 540000, A0 @00 ffdfdf, B14 @00
  ffff87 (§5) · `testAmbientDarkenFloat32` — white at D 1/5/10/15 → f1f1f1 / b7b7b7 / 6f6f6f / 272727
  (high bytes; exact 16-bit per channel 0xf198 / 0xb7ff / 0x6fff / 0x27ff); L 10, D 15 on
  white → 0x17fe per channel (§7.2–§7.3) · `testPairTableRequests` — 0154/015c/0158/0160/0150 formulas on (src, dst)
  = (0xffff, 0) and (0x8000, 0x8000) (§6.1 arithmetic) · `testLightGroupRequests` — white k 0/5/10 at D 0 = §7.3's
  listed row (group 1: ffffff 8c8c8c 191919; group 6: ffffff ff1dfa ff3af4), D 5 group 0 k 10 = 525252, group 3 k 10 =
  1b2f7d, group 9 k 10 = 0f0f0f (§7.3).
  Render (8): `testExactNearestTiesLowest` — black in CLUT 202 (entries 0x60, 0xa0, 0xfe, 0xff) → 0x60 (p06) ·
  `testInverseTableBitReplicatedCells` — 4-bit cell 1 = 0x1111, 15 = 0xffff; 5-bit cell 1 = 0x0842 (p09 helper) ·
  `testRuledModelExactFirst` · `testBankAgreementFiguresCLUT202` — agreement of `.inverseTable(4)` with `.exactNearest`
  over indices 0..0x9f per tint table: 1:143 2:116 3:107 4:134 5:130 6:107 7:65 8:143 9:151 0xb:103 0xc:153 0xd:138
  0xe:39 0x10:10/14 0x11:10/14 0x16:118; `.inverseTable(5)`: 145 149 147 145 150 124 104 152 156 127 157 147 66 12 12
  138 — **reproduces lighting-tables §1.2's 39..153 and 66..157** (p09 part A) · `testBankLevelSpreadFigures` — sprite
  indices whose 4-bit-mapped RGB differs across the 16 level CLUTs: 1:138 2:32 3:76 4:77 5:87 6:97 7:111 8:62 9:55
  0xb:106 0xc:157 0xd:66 0xe:76 0x10:3 0x11:12 0x16:71 — **reproduces §1.4** (p09 part B) · `testWaterTable0Index9E`
  — 0x84 exact, 0x49 4-bit (lighting-tables §4; p09) · `testDisagreementCensusCLUT202` — `.ruled` vs `.exactNearest`:
  tint 1,168/3,603 · water 397/1,280 · redden 1,885/6,144 · ambient 1,887/4,096 · pairs 0154+015c+0158 70,124/196,608 ·
  total 75,461/211,731 (p09 part C, p14) · `testDisagreementCensusAllSixteen` — per-CLUT totals of Research note 9,
  grand total 1,178,143 of 3,387,696 (p14).
- **Gate:** G2 = **43/0**. **Commit:** `Ferazel/Core: TableRequests (tint/water/redden/pair/ambient/light), ColorSearch (exact, inverse 4/5-bit, ruled); Color2Index measured; 15 tests`.
- **Seat alone:** caching strategy; vectorisation. **Ben's:** none (the model is ruled; Ben sees it at the gate).

### C5 — ⚑ MAJOR — Faces: PICT → indices under a CLUT, RLE encoder, loaders with the original cell arguments (→ 56)
- **Precondition:** K1 on HectorKit main and pulled into `~/Developer/HectorKit`; C4 merged.
- **Files:** `Sources/FerazelRender/Faces/{PictureSource,ConvertedPicture,Dither,EncodedFace,FaceEncoder,FaceSheet,PlainFaceSheet,WaterFaceSheet,BlendFaces,TileSets}.swift`;
  `Tests/FerazelRenderTests/FaceTests.swift`.
- **Contract (sprites-backgrounds §1–§3, lighting-tables §8; HIGH unless marked):** the loader's conversion path — the
  PICT is drawn into an 8-bit port carrying the conversion CLUT (`*_DAT_1009ff94`): **every source colour goes through
  `ColorSearch`** (indexed PICTs: once per table entry, 16-bit RGB from the PICT's own table; DirectBits: per pixel,
  8-bit components × 257); a DirectBits PICT (transfer mode 64 = ditherCopy, all 326) is additionally dithered by
  `DitherModel` (default `.errorDiffusion`: Floyd–Steinberg 7/16 · 3/16 · 5/16 · 1/16 in 16-bit RGB, rows top-down,
  left-to-right — LOW, Research note 10). **A 1-bit v1 BitMap bypasses `ColorSearch`:** set bits → 0xff, clear bits →
  0x00, fixed, under every model (the FG water mask 183 and the PxMid mask sheets 319/329/339/350 need K == 0xFF
  exactly, rendering-omnipx-titles §1.2). ⚠️ **Hazard (why the model is selectable):** `DrawPicture` into the non-GWorld
  back port may match colours through the current **GDevice's** inverse table rather than the port's CLUT
  (sprites-backgrounds §2 conversion path) — the replica cannot tell which; `ColorSearch.Model` stays a parameter and
  the surface is on the gate card (item 1). Sheets that fit 640×416 go through the shared back port, whose CLUT copies entries 0..254 only
  (`.ChangeBlitPortClut`, lighting-tables §1.2) — entry 0xff is black in every conversion CLUT used (p06), so no effect;
  record it in a doc comment. Conversion CLUTs: sprite sheets 200; BG tileset level+base (202 for L1; sprites §3 HIGH);
  PxBack/PxMid the level CLUT `hdr+0x285c` (201 for L1) unless `hdr+0x26cc` (bosses-3 §8 HIGH); **FG, FG-water and
  pattern: the bank does not say — use level+base like BG [MED, gate card]**; PICT 185 blend under 200 (weights depend on
  CLUT-200 indices, lighting-tables §8). Face record §2.1 (frame rect, tight bounds `top, left−1, bottom+1, right+2`
  clamped ≥ 0, `+0x18` "has a 0 pixel", `+0x1c` 0x100, `+0x30` source id); RLE tokens §2.2 (op 1 row + byte length,
  op 3 skip n (0 = transparent), op 2 copy n + pad to 4, op 0 end; op ≥ 4 refused on decode). Cell `i` = rect
  (`(i % cols)·w`, `(i / cols)·h`, +w, +h). Tile sets §3 with the original arguments (BG/FG 96 of 32×32, 8 cols;
  pattern 64 of 32×32 loaded encoded **and** plain; PxBack 36 of 128×128, 6 cols; PxMid 12 + 12 from id / id+1);
  fixed sets: 183 (FG water mask, 96 cells) stamped into the FG-water cells by kind (`.LoadEncWaterFaceSetFromPICT`,
  MED purpose) and 185 (blend) rewritten to weights 0..3 (`.ProcessFGBlendTileFace`). Player sheets per player-states
  §7 (29 sheets 1003..1039 except 1026; 1022 is 150×120, 1023 120×120, glider 1050..1053 cached 160×160 not needed in
  Phase 1). A cell reaching past the frame (PICT 257: 768×708, cells 30..35 lose 60 of 128 rows) reads 0 there and the
  sheet is flagged `shortRows` (design §11; sprites §3 MED).
- **Tests (13):** `testIndexedConversionWalkSheet1020` — 51 colours, 6 exact in clut 200, `.ruled` ≠ `.exactNearest` on
  5 colours / 1,333 pixels; transparent pixels 169,957 under both (p10, p11) · `testPxBack207AllExact` — 52 colours,
  all exact in clut 201, 0 differ (p10) · `testTileSheetConversionExposure` — under 202: FG 200 239 colours / 30 exact
  / 62 differ / 7,193 px; BG 203 234 / 28 / 67 / 13,898; pattern 206 200 / 30 / 73 / 8,606 (p10) ·
  `testDirectBitsDitherModelsSelectable` — PICT 2922 (56×60 32-bit) converts under both `.none` and
  `.errorDiffusion`; the two differ; pixel counts self-derived and recorded · `testEncodeRectTokenGrammar` (synthetic
  rows: leading/trailing/inner skips, odd literal lengths padded to 4) · `testEncodeRoundTripPhase1Faces` (every face of
  the level-1 tile sets and the 29 player sheets decodes back to its source indices) · `testFaceRecordBoundsRule` ·
  `testFaceSetCellGeometry` (1020: 16 cells 100×120, 4 cols; cell 5 = x 100..199, y 120..239) ·
  `testPlayerFaceSetsTable` (29 sheets, cell counts and sizes of player-states §7) · `testWaterMask183` (96 cells,
  29,595 set bits, p16) · `testBlendFaceWeights` (185: weight counts per value self-derived; the §8 mapping 0/0x97/0x98
  → 3, 0x99..0x9b → 2, 0x9c..0x9e → 1, else 0) · `testShortSheet257Flagged` (768×708; cells 30..35 flagged; 60 rows) ·
  `testOneBitBitMapsBypassColorSearch` (183 and 319 under `.ruled`, `.exactNearest`, `.inverseTable(bits: 5)`: every
  pixel 0x00 or 0xff, 0xff count 29,595 / 44,880 = the set bits, identical under all three; p16).
- **Gate:** G2 = **56/0**. **Commit:** `FerazelRender: PICT → indices through ColorSearch (+ ditherCopy model, 1-bit bypass), EncodeRect RLE faces, face/plain/water/blend sheets, tile sets; 13 tests`.
- **Seat alone:** memory layout of tokens. **Ben's:** none (dither and FG conversion CLUT are on the gate card).

### C6 — minor — `ferazel-census` + `docs/ferazel/data-census.md` (→ 60)
- **Files:** `Package.swift` (executable); `Sources/FerazelRender/Census/FerazelCensus.swift`; `Sources/ferazel-census/main.swift`;
  `Tests/FerazelRenderTests/CensusTests.swift`; `docs/ferazel/data-census.md` (new); `docs/ferazel/INDEX.md` (one
  pointer row); `docs/DECISIONS.md` (as-built paragraph on C0's entry: census Totals, test total, HectorKit sha).
- **Tool contract:** `ferazel-census <Resources/Ferazel dir> [--render <out dir>]`; Markdown on stdout, names never
  machine paths; exit 0 / 1 (any failure, each named) / 2 (bad args). Sections: files · resources per file · one line per
  item (770 PICT with path/size/depth, 79 clut, 172 snd, 24 Mlvl, 29 Mcnv, 28 music, Mwld, Mmap, 4 STR#) · Color2Index
  per level CLUT (16 lines) · Phase-1 face conversion exposure · Totals. `--render` writes `level1-start.png`,
  `pict-1020.png`, `pict-207.png` (ImageIO in `Sources/ferazel-census` only; the seat's addition, see Scope).
- **Exact summary lines** (each a whole stdout line, in this order, Totals last; numbers p01–p21):
  ```
  # Ferazel's Wand 1.0.3 — data census
  files 34 · resource files 6 · music 28 of 30 (21, 27 absent) · bytes 85,281,911
  resources app 164/28 · World Data 60/7 · Backgrounds 194/7 · Sprites 587/3 · Sounds 175/3 · Titles 86/4
  PICT 770 · v2 765 (indexed 8-bit 427 · 4-bit 11 · 2-bit 1 · direct 32-bit 326 mode 64) · v1 1-bit 5 · failures 0
  clut 79 · app 6 · Backgrounds 57 · Titles 16 · 256 entries each · duplicate ids identical 6 · + base 24 (0x00..0x9f = clut 200)
  snd 172 · format 1 · 22050 Hz 138 · 11025 Hz 33 · 22254.545 Hz 1 · samples 2,432,217
  music 28 · AIFC ima4 stereo 22050 Hz · packets 694,051 · frames 44,419,264
  Mlvl 24 · active records 5,641 · placed types 243 · flag-0 typed 48 · flag 99 1 · unmapped types 0
  classes Bonus 2895 · Background 1274 · Box 759 · Platform 169 · Walker 158 · Bat 89 · Gremlin 50 · Rope 49 · Frog 41 · Crawler 31 · Blob 29 · Button 24 · Salamander 22 · Dillo 20 · Roach 16 · Floater 7 · Crab 3 · Chief 1 · Demon 1 · Warrior 1 · Wizard 1 · Xichra 1
  world Mwld Teraknorn 0x152be0ed · Mmap nodes 24 · Mcnv 29 (lines 580, text 198, portrait 183) · STR# 1000 99 · STR# 500 19
  color2index CLUT 202 ruled vs exact: tint 1168/3603 · water 397/1280 · redden 1885/6144 · ambient 1887/4096 · pairs 70124/196608 · total 75461/211731
  color2index 16 level CLUTs: 1,178,143 of 3,387,696 requests differ
  faces level 1 ruled vs exact: FG 200 62/239 colours 7,193 px · BG 203 67/234 13,898 px · pattern 206 73/200 8,606 px · PxBack 207 0/52 · walk 1020 5/51 1,333 px
  short sheet PICT 257 768×708 (cells 30..35, 60 rows)
  Totals: items 1,108 decoded, failures 0
  ```
  (1,108 = 770 + 79 + 172 + 24 + 29 + 28 + 1 + 1 + 4.)
- **Doc:** header (generated date, HectorKit sha + tag, Classics sha, the two re-run commands of G3), a "Spec-vs-data
  deltas" list (= "Bank corrections to append" 1–6, two lines each), a rule `---`, then stdout verbatim.
- **Tests (4):** `testSummaryLinesExact` (the 15 lines above verbatim, in order) · `testStdoutEqualsCommittedCensus`
  (stdout byte-equals the doc body below its rule, via `#filePath`) · `testExitCodes` (bad args → 2; a temp folder
  with one truncated PICT → 1 and the line names it) · `testOneLinePerItem` (1,108 item lines).
- **Gate:** G2 = **60/0**, G3. **Commit:** `Ferazel/Core: ferazel-census + data-census.md (1,108 items, 0 failures, Color2Index measured); D<n> as built`.

### Hazards for every R implementer (read before any dump reading in R1–R6)
Quoted from `docs/ferazel/INDEX.md` "Reviewer notes"; every R task's precondition points here.
- **`lwzu`/`stwu` +8 copy loops.** 8-byte copy loops written as `p[2] = q[2]` after `p = base−8` / `base+0x10` hide a
  +8 offset (pre-increment); re-check any offset derived from such a loop against the raw disassembly.
- **A TOC-load count is not a write count.** A slot loaded once into a callee-saved register may be stored through
  many times; follow the loaded register through the function before claiming "no writer".
- **`.StandardSpriteHandles` zeroes per-frame fields** (`+0x11c`, the clips `+0x1b6..+0x1bc`, the latch `+0x180`) every
  frame, so a read of those fields depends on **call order** relative to SSH.
- **Signed-compare idiom.** Ghidra renders `eqv; subfc; rlwinm; addze; rlwinm` (= `rB < rA` signed) as
  `(uint)(x <= y) - (~(int)(x ^ y) >> 0x1f) & 1`; the first term alone gives the opposite answer when the operands
  share a sign.
Dumps: if `$WT/ghidra/Ferazel_pef.decompiled.c` is absent, copy from `$DUMPS` or regenerate with
`ghidra/regen-ferazel.sh` (~6 min from the saved Ghidra project named in INDEX provenance). Cite raw addresses.

### R1 — ⚑ MAJOR — Seams, level tables, frame ports, tile grid (→ 69)
- **Precondition (read Hazards first):** read `.RedrawScrollGrid`, `.PlainWrapFGTile`, `.PlainWrapFGOverlayTile`,
  `.SetScrollLocation`, `.BlitEncBoolTile` in the dumps (Invariant 3): (a) record in the commit body whether
  `.RedrawScrollGrid` refills the whole 20×13(+1) cell window or only newly exposed strips, and transcribe that. If it
  is strip-incremental, build it incrementally (the third port `0004` and `.WrapEraseSprites` then belong to R4); if
  whole, say so. (b) **Mask-port values (the bank does not say):** who fills mask port `0008` per frame and with what
  value (`.RedrawScrollGrid`), and what value the FG boolean stamp writes (`.PlainWrapFGTile` step 4 →
  `.BlitEncBoolTile`). Write both values into this plan's "Bank corrections to append" as a ⚑ note with raw
  addresses **before** writing `testMaskPortTransparencyRule`; the test pins what was read.
- **Files:** `Sources/FerazelCore/Seams/{FrameOps,DrawOp,SpriteDraw,FaceRef,SoundCue,MusicCue,ShellRequest,StatusBarState}.swift`,
  `Sources/FerazelCore/Input/{InputActions,KeyState,FerazelPrefs}.swift`; `Sources/FerazelRender/Frame/{LevelTables,FramePorts,TileGridRenderer,TileBlitters}.swift`;
  `Tests/FerazelCoreTests/SeamTests.swift`; `Tests/FerazelRenderTests/TileGridTests.swift`;
  `docs/plans/2026-10-06-ferazel-phase1.md` ("Bank corrections to append", the ⚑ mask-port note only).
- **Contract:** S3 types verbatim. `FerazelPrefs` = engine §8 record with `.InitPrefs` defaults (Graphics 1, Parallax 2,
  Effects 1 — a modern Mac passes the `cput ≥ 0x108` test, save-continue §8.2; sound/music on; keys of engine §7.1).
  `LevelTables` resolves C4's requests for the level's working CLUT through the chosen model (tint bank, water incl.
  table 4 = 0, redden A/B, ambient, pair tables, light) — built at the original's moment (lighting-tables §1.3). Frame
  ports per rendering §1.1–§1.2: frame `000c` (tiles+sprites, empty = 0), mask `0008` (backdrop gate; its per-frame
  fill and stamp values are the precondition (b) reading), ring addressing. `TileGridRenderer` = `.RedrawScrollGrid` for the cell window of scroll (h, v): BG face, then
  the FG rule of sprites-backgrounds §3.1 (steps 1–4: FG face, FG-water face + water table w when the BG kind is
  200..209 and `hdr+0x26c6 == 0`, tinted face when ≠ 0; blend face `k = FGkind mod 100` (0..94) mixed with the pattern
  tile through pair tables 0154/015c/0158 by weight (lighting-tables §8); tile 95 = pattern tile; FG boolean mask into
  `0008` where the BG face has transparency), overlay cells §3.3 (o1 100 → FG face o2, 101 → BG face o2, o2 ≥ 95 →
  pattern, tinted in water), pattern index `(x mod 8) + 8·(y mod 8)` floor-mod or the 6×6 rule when `hdr+0x26cb ≠ 0`.
- **Tests (9):** Core (1): `testSeamTypesEquatableAndDefaults` (FrameOps empty default; prefs defaults of engine §8).
  Render (8): `testLevelTablesLevel1` (disagreement counts equal C4's CLUT-202 line under `.ruled` vs `.exactNearest`) ·
  `testFramePortsRingAddressing` (h 630 / v 410 wrap) · `testPatternTileIndexRule` (L1 8×8; L2 `0x26cb = 1` → 6×6) ·
  `testTileFrameLevel1Start` — scroll (h 0, v 10): cell window cols 0..19 × rows 0..13 (280 cells), 189 FG non-empty,
  116 pattern cells, 162 BG non-empty, 0 water, 0 overlay (p17); frame FNV-1a self-derived and recorded ·
  `testFGWaterCellRule` (an L1 kind-0 water cell inside cols 4..193 × rows 19..49 draws the FG-water face through water
  table 0; p18) · `testBlendCellMix` (one blend cell: weights 0..3 map to pattern / ¾p / ½ / ¼p as §8) ·
  `testOverlayCellsLevel1` (the 20 overlay cells draw FG face o2 over the cell; 12 draw the pattern) ·
  `testMaskPortTransparencyRule` (`0008` holds the precondition-(b) fill value where nothing opaque was drawn and the
  read stamp value under the FG boolean stamp — the values recorded in the ⚑ note, nothing assumed).
- **Gate:** G2 = **69/0**. **Commit:** `Ferazel: LOCKED seam types, prefs defaults; LevelTables, frame/mask ports, RedrawScrollGrid (FG rule, blend, overlay, pattern); 9 tests`.

### R2 — minor — Darkness and lights on tiles, water tint (→ 74) — ∥ R3
- **Review:** the reviewer MUST re-read the dump readings this task records, not just the diff.
- **Precondition (read Hazards first):** read in `$DUMPS` how per-cell darkness reaches **tiles** (`.RedrawScrollGrid`'s tile blitters vs
  `.DrawLightsOntoTiles`/`.DrawLightOps` — the bank documents only the sprite path, draw-effects §3, and the light-op
  path, lighting-tables §7.4); append the reading to `docs/ferazel/lighting-tables.md` §7.4 as a ⚑ Phase-1 note
  [MED unless every link is raw-read].
- **Files:** `Sources/FerazelRender/Frame/LightRenderer.swift`, `Sources/FerazelRender/Faces/LightFaces.swift`;
  `Tests/FerazelRenderTests/LightingTests.swift`; `docs/ferazel/lighting-tables.md` (the note only).
- **Contract:** lighting-tables §7: D = BG light byte − 1, enabled by `hdr+0x2706 ≠ 0` (L1 = 5); ambient table
  `[D·0x100 + i]`; light faces (PICTs 801.., CLUT 801, `.Load1LightFaceFromPICT`); `.DrawLightsOntoTiles` (op grid
  20×13, `.CalcLightOps`, `.DrawLightOps`, ambient fallback) as read; skipped when prefs+6 == 3. Water tint on tiles is
  R1's FG rule; R2 adds nothing there beyond tests. No lights exist at level-1 start (none of the 42 placed types adds
  one in its Setup per the class files [MED]; Effect explosions add them later, triggers-background-2 §2.1).
- **Tests (5):** `testAmbientTilesLevel1Start` — light bytes in the start window {1:16, 2:27, 3:33, 4:28, 5:28, 6:29,
  7:29, 8:29, 9:27, 10:25, 11:9} (p17) and the darkened frame FNV self-derived · `testAmbientEnableGate`
  (`hdr+0x2706 = 0` → untouched) · `testEffectsReducedSkipsLights` (prefs+6 = 3) · `testWaterTable0Entry0xFFIsBlack`
  (→ 0x60, lighting-tables §4) · `testLightTablesCensusLine` (light-table disagreement count, ruled vs exact, CLUT 202
  — self-derived, recorded in the commit body; planner did not measure the light groups).
- **Gate:** G2 = **74/0**. **Commit:** `FerazelRender: per-cell darkness and lights on tiles (ambient/light tables, light faces); 5 tests`.

### R3 — ⚑ MAJOR — Parallax as written: PxBack/PxMid rows, ring split, strip sprites (→ 81) — ∥ R2
- **Precondition:** read Hazards first wherever the dumps are consulted.
- **Files:** `Sources/FerazelRender/Frame/ParallaxBlitter.swift`, `Sources/FerazelCore/Sprites/PxSprites.swift`;
  `Tests/FerazelRenderTests/ParallaxTests.swift`.
- **Contract:** rendering-omnipx-titles §1.1–§1.5 **literally**: the copy-to-screen composites the backdrop
  (`.DoubleBlitPPCParallaxOneLayer`), gates of §1.1 (prefs+9, prefs+4 = 3, Fire variant out of scope until levels
  52/55, graphics modes 1/2/3 → (0,0)/(0,1)/(1,0)); ring split when `v' − 32 ≥ 1` into two calls; the byte/word rules
  of §1.2 (back: `M == 0xff ? I : F`, word `F + (M & I)` 32-bit add; mid: `K == 0 ? I : F`, word `(K & F) + I`); the
  row state machine of §1.3 incl. the as-written mid-row y and the "mode re-decided only where a factor changes" rule;
  PxMid −1 read as entry [−1] (§2 — never reached with shipped data); `.GetPxBackTile` returns 0 while OmniPx is on
  (OmniPx itself is not built in Phase 1: level 1 mode 0). Strip sprites (triggers-background-2 §4): `N = ⌊((fx·W·32)
  >> 8) / 768⌋ + 1` copies at layer −500, mode 0x80000 (behind tiles, draw-effects §2.5 word add, MED), position
  `x = x0 − (viewX·fx >> 8) + viewX`, `y = y0 − (viewY·fy >> 8) + viewY + 232`. Level 1 has no strip.
- **Tests (7):** `testBackRowByteAndWordRules` (synthetic M/F/I words incl. a carry) · `testMidRowRules` (synthetic) ·
  `testRingSplitTwoCalls` (v' = 100 → view rows 0..315 and 316..383, dst tops 8 and 324) ·
  `testLevel1FactorChangeRows` — V 10: v0b = 10·74 >> 8 = 2; view rows 274..410 carry factor 64, so the back row is
  re-decided at 273→274 and 410→411 (p19; world-data §3.2 0xb26c) · `testMidBandLevel10` — level 10 at V in
  1392..1536 draws PxMid cell rows 16 and 17 (rendering §1.5 table, MED simulation) · `testGraphicsModeRowSteps`
  (prefs+2 = 2 doubles rows, = 3 skips alternate rows) · `testStripSpriteCopies` — N = 8 (L10), 11 (L30), 11 (L40),
  2 (L45), 8 (L62), 1 (L67); L1 none (p02 header + T2 §4 formula).
- **Gate:** G2 = **81/0**. **Commit:** `FerazelRender: DoubleBlitPPCParallaxOneLayer as written (row state machine, ring split, byte/word rules), Px strip sprites; 7 tests`.

### R4 — ⚑ MAJOR — Placed sprites in their Setup faces, active list, idle activation, WrapDrawSprites (→ 88)
- **Precondition:** read Hazards first (the `.StandardSpriteHandles` call-order trap applies to every Setup field).
- **Files:** `Sources/FerazelCore/Sprites/{SpriteSlot,ActiveList,IdleSprites,SetupFaces}.swift`;
  `Sources/FerazelRender/Frame/SpriteBlitter.swift`; `Tests/FerazelCoreTests/SpriteListTests.swift`;
  `Tests/FerazelRenderTests/SpriteDrawTests.swift`.
- **Contract:** ◇ `SetupFaces` — for each of the **42 placed types of level 1** (Research note 15), what the class
  Setup leaves: sheet + cell arguments, face index (params p1..p4 honoured where Setup reads them), layer `+0x80`,
  `+0xb8`, `+0x17e`, `+0x88`/`+0x89`, position adjustment, idle margins `+0x1c8..+0x1ce`; transcribed from the class
  file named per type in Research note 15 (coverage §3 index). No Handle runs. A type whose Setup face depends on
  state Phase 1 lacks is drawn with the Setup's first face and listed on the gate card. `ActiveList`: ascending signed
  layer, a new sprite after every sprite of equal or lower layer (physics §0 `+0x80`, platforms-ropes-radial-2 §8);
  spawn order world-data §3.4. `IdleSprites` (triggers-background-2 §8.3): window = view origin h −24..+632, v −24..+408
  ∪ player hot rect, the mandatory outset 96, per-sprite margins, 511 of 512 entries scanned, one rule both ways. `SpriteBlitter` =
  `.WrapDrawSprites` steps 1–8 (draw-effects §1.1) for the modes Setup stores in level 1 — 0, 1 (tint table), 9 (water
  table 0), 0xc via `+0x89` (ambient/light table), 0xb arg from the D = −1 case — through `.BlitEncFaceX` dispatch
  (§1.2: NoClip/Clip, Flip, Special) + the mask pass (silhouette 0 into `0008`) + the `+0x88` light-overlay pass
  (`.BlitAmbDarkenOverFace*`, draw-effects §3); hurt flash, burn, rotation/scale, diffuse, ripple and squash are not
  reached in Phase 1 (refused with a named error if asked).
- **Tests (7):** Core (5): `testSetupFacesLevel1Types` (42 types resolve; none unmapped) · `testActiveListLayerOrder`
  (ties after existing; negative layers first) · `testSpawnOrderLevel1` (the 22 type-1307 records, then the 7 platform
  records (types 1400..1403) in record order, then the rest in record order; world-data §3.4) · `testIdleActivationRule` (synthetic margins, both directions) ·
  `testIdleWindowAtStartLevel1` (count of sprites active at scroll (0, 10) — self-derived from the transcribed margins;
  the window includes the mandatory 96-px outset (triggers-background-2 §8.3), with which the point test without
  per-sprite margins gives **13** records (Fable review; p17's 8 omitted the outset); the margins can only add).
  Render (2): `testWrapDrawSpritesClipAndMaskPass` · `testSpecialTableModes` (modes 1, 9, 0xc remap through
  LevelTables).
- **Gate:** G2 = **88/0**. **Commit:** `Ferazel: level-1 placed sprites in their Setup faces, active list, idle activation, WrapDrawSprites (modes 0/1/9/0xb/0xc + light overlay); 7 tests`.

### R5 — minor — Player pose, camera, session step (→ 94)
- **Precondition (read Hazards first):** read the focus base in `.GameLoop` / `.PlayerScroll` (below) and record it in
  this plan's "Bank corrections to append" as a ⚑ note with raw addresses.
- **Files:** `Sources/FerazelCore/Player/PlayerPose.swift`, `Sources/FerazelCore/Camera/{Camera,CameraFocusDriver}.swift`,
  `Sources/FerazelCore/Session/{FerazelSession,GameGlobals}.swift`; `Tests/FerazelCoreTests/SessionTests.swift`;
  `docs/plans/2026-10-06-ferazel-phase1.md` (the ⚑ focus-base note only).
- **Contract:** `FerazelSession.step(keys:)` = one `.GameLoop` iteration in `.PaintFrameWrap` order (engine §3–§4):
  if drawing this iteration → `redrawScrollGrid`, `drawLightsOntoTiles` (unless prefs+6 = 3), `wrapDrawSprites`,
  `copyToScreen`, then logic (idle sprites, the stubbed player), then `statusBar`; prefs[0] "Reduce frame rate"
  alternates draw/skip (`drawn = false`). Level start ops once: `setScreenClut(202)`, `drawPicture(129, .frontEnd,
  0, 0)`, `MusicCue.play(track: 1)` (`hdr+0x284a`), `ShellRequest.hideCursor`, `.hideMenuBar`. ◇ `PlayerPose`:
  sprite top-left = (`hdr+0x2848` − 32, `hdr+0x2846` − 32) = **(83, 143)** for L1, layer 10, facing from `0x26c8`
  (L1 0 → right), hot rect (0x26,0x22,0x3e,0x55); faces of player-states §3.11: stand = `1003[chestFrame]` (3 on entry,
  breathing cadence physics-sprites §8.8), walk while L/R held = phase `+0x46` starts 0xc, += 2 per frame, wraps past
  0x1f, face `1020[phase >> 1]`; run (Shift) = `1024[phase >> 1]`, wraps past 0x17; turn on a facing change = countdown
  4 → `1030[0]`, `[1]`, `[2]` mirrored, `[1]`, `[0]`; fidget after 150 idle frames per §3.11.4. No physics, no sound.
  `Camera` = `.FindUpperLeftCorner` (engine §5): target = focus − (304, 192) + (`0x270a`, `0x270c`), 16-px x-snap rule,
  ease `max(|Δ|/6, 1)` per axis, clamp `0 ≤ h ≤ 32·W − 640`, `0 ≤ v ≤ 32·H − 384` (L1: 5,760 / 1,216). ◇
  `CameraFocusDriver`: focus starts at base + (50, 59) (engine §5 "start+50/start+59") — **the base is a reading
  [MED]**: on the sprite origin (x − 32) it gives (133, 202) → first scroll **(0, 10)** (p17); on the header start
  (115, 175) it gives (165, 234) → first scroll **(0, 42)**. The implementer uses whichever `.GameLoop` /
  `.PlayerScroll` shows (precondition). Held left/right/up/down — **arrow keys or keypad 4/6/8/5** (stub only; replaced
  by `.PlayerScroll` in Phase 2) — move the focus 1900/256 px per frame (walk max, physics §4), 3200/256 with run
  held; the first frame's scroll is the clamped target (no pan-in — the bank does not say, MED, gate card).
- **Tests (6):** `testPlayerStartPose` ((83, 143), facing right, face 1003[3], layer 10) · `testWalkCycleFaces`
  (first walking frame sets phase 0xc, then +2 per frame in the order player-states §3.11.3 states; face = phase >> 1
  of 1020's 16; wrap past 0x1f) · `testRunCycleFaces` (12 faces, wrap past 0x17) ·
  `testTurnSequence` (5 frames, first three mirrored) · `testCameraStartScroll` (the first scroll of the read base —
  (0, 10) or (0, 42) [MED], as the ⚑ note records; clamps 5,760 / 1,216; p17) ·
  `testStepOrderAndSkippedDraw` (the DrawOp order above; prefs[0] = 1 alternates `drawn`).
- **Gate:** G2 = **94/0**. **Commit:** `FerazelCore: FerazelSession.step (PaintFrameWrap order), Camera (FindUpperLeftCorner), Phase-1 player pose and focus driver stubs; 6 tests`.

### R6 — minor — Status bar, game-screen frame, CLUT → RGBA, frame goldens (→ 100)
- **Review:** the reviewer MUST re-read the dump readings this task records, not just the diff.
- **Precondition (read Hazards first):** read `.UpdateTextStats`, `.UpdateItemStat` and `.UpdateHealthMagic` in `$DUMPS` for text size,
  colour, transfer mode and the empty-inventory drawing (spells-items §6 gives positions and font id 20 only); append
  the reading to `docs/ferazel/spells-items.md` §6 as a ⚑ Phase-1 note.
- **Files:** `Sources/FerazelRender/Frame/{StatusBar,TextRasterizer,FrameRenderer,IndexedFrame}.swift`;
  `Tests/FerazelRenderTests/{StatusBarTests,FrameGoldenTests}.swift`; `docs/ferazel/spells-items.md` (the note only).
- **Contract:** status-bar port 640×88 from Titles PICT 132 copied to (0, 392) (spells-items §6, engine §3); HUD piece
  PICT 133 at x 214: health bar `G+4 >> 3` = 70 px, breath overlay `G+6 >> 3`, magic `G+0xe >> 3` = 70 px (start values
  560, physics §5.1, engine §9); score `G+0` "0" at (27, 19), coins `G+0x10` "0" at (150, 19), level name
  "A Scent Of Peril" (`hdr+0x25c4`) at (27, 46), font id 20 (Times) through `TextRasterizer`. PICT 129 'Game Screen'
  (640×480, 4-bit) drawn at level start around the 608×384 view (rendering §4.1). `FrameRenderer.apply` executes
  `FrameOps` on the ports; `IndexedFrame.rgba(through:)` maps through the **current screen CLUT** on every present
  (design §5): `.SetScreenClut` rewrites `value` to the index (lighting-tables §1.2). A `TextRasterizer` test stub draws
  fixed glyph boxes so goldens are font-independent.
- **Tests (6):** `testStatusBarStartValues` (bars 70 px; text origins as above; stub rasterizer calls recorded) ·
  `testGameScreenFrame129` (4-bit PICT through its own table into the level CLUT; view rect (16,8)–(624,392) left for
  the copy) · `testIndexedFrameToRGBA` (entry 0 → 0xFFFFFFFF, 0xff → 0xFF000000 under 202) ·
  `testFirstFrameGoldenLevel1` (step 1 at R5's first scroll: FNV-1a of the 640×480 indices self-derived and recorded; PNG
  to `$FERAZEL_PNG_OUT` when set, ImageIO in the test only) · `testPanFrameGoldens` (60 frames of right held: scroll and
  FNV self-derived) · `testFirstFrameOpsOrder` (the R5 order, as executed).
- **Gate:** G2 = **100/0**. **Commit:** `FerazelRender: status bar at start values, Game Screen frame, FrameRenderer, CLUT → RGBA; level-1 frame goldens; 6 tests`.

### A1 — ⚑ MAJOR — App target `Ferazel` on HectorShell
- **Files:** `project.yml` (S6, merged); `Ferazel/App/{FerazelMain,FerazelController,FerazelAssets,FerazelAudio,CoreTextRasterizer}.swift`,
  `Ferazel/App/Info.plist`, `Ferazel/App/AppIcon.icon/` (Icon Composer document + `Assets/`).
- **Contract:** window `ShellWindowController(title: "Ferazel's Wand", logicalWidth: 640, logicalHeight: 480)` with
  content size 640k × 480k points, k = 3 when the main screen's visible frame holds 1920×1440, else 2 when it holds
  1280×960, else 1 — crisp integer scale (Ben's ruling 4, design §5; HectorShell D3/D7 R3); full screen = the shell's
  `enterFullscreen()` (largest whole multiple, black border) on ⌃⌘F. Clock: a 1/60 s `ShellIdleTimer` runs one
  `session.step` when `ShellClock.ticks() − lastStepStart ≥ 2` (the 2-tick cap, engine §4; missed steps dropped, never
  caught up), then `renderer.apply`, `IndexedFrame.rgba` into a `ShellBitmap`, `present`. **Both arms of the clock**
  (design §3.2, engine §4): prefs[0] "Reduce frame rate" = 0 → every step draws, 2-tick cap; prefs[0] set → even
  iterations skip the screen copy (`drawn = false`) and the draw/skip **pair** is capped at 4 ticks. Phase 1 ships
  prefs at their defaults (prefs[0] = 0), but the clock implements both. Keys: `ShellView.pollKeyState()`
  → `KeyState` each step; actions via `FerazelPrefs` key codes (engine §7.1 defaults: keypad 4/6/8/5, Shift, Option,
  ⌘, keypad 7/9). **Q1 ruled by the seat:** the Phase 1 camera/pose stub accepts the arrow keys **and** the keypad
  (it is a stub, replaced in Phase 2); from Phase 2 on the game proper ships the original defaults only, and the
  original Options dialog (Phase 3) rebinds them. ⌘Q quits. Caps Lock (pause) and Esc (abort dialog) do **nothing**
  in Phase 1 (design §3.3; both arrive in Phase 3). `MusicCue.play` → `FerazelAudio`: one `ShellMixer` music
  voice, track decoded by `MusicTrack`, looped, volume prefs+0x10 (9 → 256/256). `.hideMenuBar` honoured in full screen
  only (windowed macOS keeps the bar — design §7.4). Info.plist: `CFBundleName`/display "Ferazel's Wand",
  `CFBundleShortVersionString` 1.0.3 (the replicated game, D23(b)), `CFBundleVersion` 0.1, `LSMinimumSystemVersion`
  15.0, `NSPrincipalClass` NSApplication. Icon: the original application icon is `icl8`/`ICN#` 128 (BNDL → FREF APPL
  local id 0 → 128), 32×32 — the largest original (p20b) — scaled ×16 nearest-neighbour into the Icon Composer document
  (D22/D23 practice: previews go to Ben on the gate card). A DEBUG-only "data missing → run tools/stage-ferazel.sh"
  alert (design §7.8).
- **Gate:** G5 ×3. **Commit:** `Ferazel app: window (whole-number scale), 2-tick step clock, keys, music voice, CoreText status text, Info.plist, icon; project.yml target`.
- **Seat alone:** controller structure, the icon document layout. **Ben's:** the icon pick.

### A2 — minor — Stage script, WHAT-TO-EXPECT, the Phase 1 gate card
- **Files:** `tools/stage-ferazel.sh`, `Ferazel/WHAT-TO-EXPECT.md`.
- **Contract:** `stage-btx.sh` shape: xcodegen → Release build (`.build/xcode-ferazel`) → ditto to
  `out/Ferazel/Ferazel's Wand.app` → copy `Resources/Ferazel/` (from the repo, `FERAZEL_DATA` overrides) into
  `Contents/Resources/Ferazel/` → `xattr -cr` → ad-hoc `codesign --force --deep --sign -` + verify → copy
  WHAT-TO-EXPECT → `ditto` both to `~/Desktop/` unless `FERAZEL_STAGE_NO_DESKTOP=1`. Every path quoted (Landmine d).
  WHAT-TO-EXPECT = what Phase 1 is and is not (no physics, no front end, no sounds, chapter screen skipped), the keys,
  the known deviations (design §7 + the three stubs), and the gate card below verbatim.
- **Gate:** G2 = 100/0, G1 on HK main, G3, G4, G5, G9. **STOP for Ben.**
- **Commit:** `tools/stage-ferazel.sh + WHAT-TO-EXPECT (Phase 1 gate card)`.

---

## What Ben checks — the Phase 1 gate card ("does it look like Ferazel")

Compare with the longplays and Ben's Let's Play link. Each line names the surface, its label, and where to look.
1. **Colours of every tile and sprite** — LOW: every face is converted through the colour search (Color2Index model,
   design §6); e.g. under CLUT 202 the FG sheet has 62 of 239 colours where the two models disagree. If colours look
   off, the exact and 5-bit models are a one-line switch. (The original may even have matched colours through the
   screen's colour table rather than the sheet's — another reason the model is switchable.)
2. **Dithered 32-bit art** — LOW: barrel 2922, chair 2924, table 2927, Geroditus 2951, merchant 2952, book pile 2842,
   sign 2902, moss 2713, Walker 1700, Roach 1720, the HUD piece 133 are 32-bit PICTs the original dithered into 8 bits;
   the replica's dither is Floyd–Steinberg. Look for dot patterns on those sprites.
3. **Grass/edge blending** (FG blend faces through the pattern texture, 1,335 FG cells in level 1) — the pair tables
   are where the two colour models disagree most (35 % of entries).
4. **Water** — kind 0 water in level 1 spans x 128..6208, y 608..1600; **acid** (kind 1) 24 cells at x 6016..6272,
   y 544..640. Wrong would look like: the water or acid the wrong colour, or the ground at the water's edge cut off
   with a hard square edge / the far background showing through where solid ground should be (colour LOW, edges MED).
5. **Darkness per cell** (light bytes 1..12 everywhere in level 1) — MED for tiles (R2's reading).
6. **Parallax** — the far background scrolls slower than the level, and one horizontal band of it moves even slower
   sideways than the rest (as the original does). Wrong would look like: the background hills jumping, tearing or
   repeating a strip while you scroll, or the background showing through things it shouldn't.
7. **Status bar** — text font/size/colour (MED, R6's reading); bars full (70 px).
8. **Camera** — the level opens already on Ferazel (no pan-in) — MED; his exact height in the view is a reading
   (MED). Arrows or keypad scroll; this is Phase 1 only (Phase 2 brings the original keys and real movement).
9. **Ferazel** — stands at the start, breathes, turns, walks/runs in place on left/right (stub; Phase 2 makes him move).
10. **Placed sprites** — every sprite in its Setup face; any listed as "first face only" in WHAT-TO-EXPECT is deferred.
11. **Ground and wall tile colours** (MED: which palette the original used for them is assumed). Wrong would look
    like: the ground tiles' colours off or banded compared with the longplays, while the background looks right.
12. **Music** — track 1 loops.
13. **Icon** — previews of the original 32×32 icon scaled to a modern icon; pick one.
Deviations Ben will see by design: no chapter-1 screen, no menus/front end, no sounds, window scaled ×2/×3; Caps Lock
(pause) and Esc (abort dialog) do nothing until Phase 3 — ⌘Q quits.

---

## Execution order

| wave | HectorKit (`$HKWT`) | Classics lane A | Classics lane B | review legs (Fable) |
|---|---|---|---|---|
| 0.1 | K1 ⚑ (push, pull --ff-only) | C0 → C1 | — | K1 two; C0+C1 (minor, one leg) |
| 0.2 | — | C2 ⚑ | C3 → C4 ⚑ | C2 two legs; C3 one; C4 two |
| 0.3 | — | C5 ⚑ (needs K1 + C4) → C6 | — | C5 two; C6 one |
| 1.1 | — | R1 ⚑ | — | two |
| 1.2 | — | R2 | R3 ⚑ | R2 one; R3 two |
| 1.3 | — | R4 ⚑ → R5 → R6 | — | R4 two; R5, R6 one each |
| 1.4 | — | A1 ⚑ → A2 | — | A1 two; A2 one; then Ben |

- Disjoint files: C2 touches only `Sources/FerazelCore/World/` + its tests; C3/C4 touch `Package.swift`,
  `Color/`, `Tables/`, `Audio/` — lane B owns `Package.swift` in wave 0.2. R2 (`LightRenderer`, `LightFaces`) ∥ R3
  (`ParallaxBlitter`, `PxSprites`); both rebase onto R1.
- Orchestrator sessions are 2–3 tasks (fable-kit §5); one Opus implementer per task in the lane worktree; the
  orchestrator merges, re-runs G1–G10 at the merge head, updates STATE, ends each session with a handoff + chip.

---

## Pre-execution self-audit

1. **Design coverage (§3–§8, Phase 0/1 rows).** Data in git (C0) ✅; kit PICT indexed + ColorTable (K1) ✅; AIFC via
   Deimos K2 — on HK main since v0.3.0 (13c8f9b), used in C3, not redone ✅; skeleton (C1) ✅; Mlvl/Mwld/Mmap/Mcnv
   parsers (C2) ✅, `snd`/clut (C3) ✅; face loader + RLE (C5) ✅; census with 0 failures (C6) ✅; Color2Index measured
   (C4, C6) ✅. Phase 1: tiles FG/BG/overlay/pattern/blend (R1) ✅; parallax PxBack + strip (R3) ✅; lighting/darkness
   (R2) ✅; water (R1 rule, R2 test) ✅; placed sprites in Setup faces (R4) ✅; status bar at start values (R6) ✅;
   level CLUT (R1 tables, R6 present) ✅; camera on keys + Ferazel at start + walk cycle, no physics (R5) ✅; app on
   HectorShell, staged to ~/Desktop (A1, A2) ✅; seam types LOCKED (R1) ✅; Windows-twin portability (Invariant 1) ✅.
2. **Placeholder scan.** Self-derived numbers are named as such (FNV goldens, dither pixel counts, blend weight counts,
   idle window count, light-table census) and each is recorded by its first green run, reviewed by a second leg.
   No "TBD". The dump readings (R1 ×2, R2, R5, R6) are preconditions with a written output, not guesses.
3. **Type-name consistency.** `FrameOps/DrawOp/SpriteDraw/FaceRef/SoundCue/MusicCue/ShellRequest/StatusBarState`
   (S3) are created in R1 and only used after; `ColorSearch.Model` cases `.exactNearest/.ruled/.inverseTable(bits:)`
   are the same in C4, C5, R1, A1; the new test `testOneBitBitMapsBypassColorSearch` names no new type; `DitherModel` `.none/.errorDiffusion` in C5 and A1; `ResourceChain.frontEnd/.level`
   in C1 and R5; `TableRequests` (Core) → `LevelTables` (Render). Every ruling reference is D26; "D25" appears only as the taken number (Landmine e).
4. **Ladder arithmetic** re-added from the named tests (after the review fixes): C1 6, C2 8+4+3, C3 4+3, C4 7+8,
   C5 13 (+ `testOneBitBitMapsBypassColorSearch`), C6 4, R1 1+8, R2 5, R3 7, R4 5+2, R5 6, R6 6 → 6, 21, 28, 43, 56,
   60, 69, 74, 81, 88, 94, 100 ✅ (the 13-record idle window changes a number inside a test, not the count). K1 8+4 =
   12 → 301 ✅. Placed types in level 1: 42 everywhere (R2, R4, Research note 15) ✅.
5. **Census-line arithmetic.** 427 + 11 + 1 + 326 = 765, + 5 = 770 ✅; 6 + 57 + 16 = 79 ✅; 211,731 × 16 = 3,387,696 ✅;
   items 1,108 ✅; class totals sum 5,641 ✅.
6. **The brief's suggested split, adjusted with evidence:** ColorSearch moved before faces (C4 before C5) because p05/p10
   show face conversion itself goes through the colour search; the old R4 split into R4 (sprites) / R5 (player,
   camera, session) / R6 (status bar, goldens) to size each for one implementer; the census logic lives in FerazelRender
   so no third test target is needed.
7. **Things the brief named that Phase 1 does not need:** PxMid draws (level 1 has none — built and tested on level 10
   data anyway, R3); `.AnimateCLUT`, flame, OmniPx (level 1 off) — not built; `Mcnv` interpreter (Phase 3).
8. **Risk carried from design §11:** line numbers (dumps regenerated or copied, raw addresses preferred) ✅; decompiler
   traps (INDEX reviewer notes) quoted in "Hazards for every R implementer", pointed at by R1–R6 ✅; PICT 257 (C5) ✅; ring split (R3) ✅; AIFFAudio on main
   ✅; D-number collision (Landmine e) ✅.

---

## Open questions for Ben (real forks only)

None. (Q1, arrow keys, was ruled by the seat in the review fix pass: the Phase 1 stub takes arrows and keypad; the
game proper ships the original defaults — A1.)

---

## Bank corrections to append (each as a ⚑ planner-probe note in the named file; no file is edited by this plan)

R1 (mask-port fill and stamp values) and R5 (focus base) add their ⚑ dump readings at the end of this list, with raw
addresses, before writing the tests that pin them.

1. **sprites-backgrounds §1–§2 (conversion path) and design §6's "sprite source pixels copy through exactly":** the
   sheets are not authored in the conversion CLUT. Indexed PICTs carry their own colour tables (walk sheet 1020: 51
   colours, 6 present in clut 200; FG 200: 239 colours, 30 present in 202) and 326 PICTs are 32-bit, so **every face
   index comes out of `Color2Index` at load time** — the same LOW as the tables. §1.4's statement remains true for the
   face-index → level-CLUT step only (p05, p10).
2. **sprites-backgrounds §1:** all 326 DirectBits PICTs (Sprites 290, Backgrounds 20, Titles 16) carry transfer mode
   **64 (ditherCopy)**; QuickDraw dithers them into the 8-bit port — a second LOW the bank does not mention (p15).
3. **sprites-backgrounds §1 "every … is a version-2 PICT":** five are **version 1 1-bit BitMaps** — Sprites 183 (the FG
   water mask) and Backgrounds 319, 329, 339, 350 (PxMid mask sheets / 350). Indexed depths: 8-bit 427, 4-bit 11
   (Sprites 658, 1840, 1928, 1929, 3090, 3099, 3104, 3105, 3106; Backgrounds 246; Titles 129), 2-bit 1 (Titles 4803)
   (p03, p15, p16).
4. **lighting-tables §1.4 "23 '+ base' CLUTs":** there are **24** — clut 322 'Upper Fire Caverns flame + base o' also
   has entries 0x00..0x9f equal to clut 200 (unused by the 24 levels) (p06).
5. **rendering-omnipx-titles §3.3, mode 0 "other 19":** **20** levels have OmniPx mode 0 (24 − levels 5, 15, 25, 70)
   (p02).
6. **world-data §3.3 level-1 census "FG 7,274 non-zero cells":** 7,274 counts whole cells; 4 of them carry only high
   bits, so 7,270 cells hold an FG tile; 225 shipped cells already carry a crunch-dir nibble (bits 12–15), which the
   row describes only as "written by `.SetFGCrunchDirTile`" (p02, p17).
7. **Gaps, not errors** (each filled by a Phase 1 precondition): the conversion CLUT of the FG / FG-water / pattern
   tile sets (sprites §3 names it only for BG; bosses-3 §8 for PxBack); how per-cell darkness reaches tiles (R2); the
   initial scroll at level start (R5 rules "converged target", MED); `.UpdateTextStats` size/colour (R6); whether
   `.RedrawScrollGrid` is strip-incremental (R1).
8. **Confirmations worth recording:** lighting-tables §1.2's agreement range (39..153 at 4 bits, 66..157 at 5 bits) and
   §1.4's per-table level spread (1:138 … 0x16:71) reproduce exactly with the bit-replicated inverse-table model (p09);
   water table 0 @0x9e = 0x84 exact / 0x49 4-bit as §4 states.
9. ⚑ **R1 dump reading (2026-10-07) — the mask port `0008` and `.RedrawScrollGrid` (sprites-backgrounds §3.1,
   rendering-omnipx-titles §1.2; `ghidra/ferazel/Ferazel_pef.decompiled.c` l. 9464–10088, disasm cited raw).**
   (a) **Strip-incremental, not whole-window.** `.PaintFrameWrap` calls `.SetScrollLocation(h, v) @ 10012848` every
   drawn frame; it redraws only the newly exposed row strip (v changed: rows old/32+13 .. new/32+12 down, new/32 ..
   old/32−1 up, at the OLD h's 21 columns) and column strip (h changed: cols old/32+20 .. new/32+20 right, new/32 ..
   old/32 left, at the OLD v's 14 rows), each through `.RedrawScrollGrid(rect, 0) @ 10013498` (l. 9534–9539). The whole
   window (cols h/32 .. +20, rows v/32 .. +13, `.RedrawEntireScrollGrid @ 10013fd0`) is drawn only at level start
   (`.GameLoop` l. 5210–5211) and on full redraws. Every per-cell blit culls to x ∈ [h−32, h+608], y ∈ [v−32, v+384]
   (`.WrapDrawTile @ 100169f4`, `.WrapDrawBoolTile @ 10016f84`), so at scroll (0, 10) 20×13 of the 21×14 iterated
   cells are drawn. Tiles go into the **third port `0004`**, not the frame: `.RedrawScrollGrid` draws every tile into
   `_DAT_100a0004` and ends with `.WrapRectBlitX(0004 → 000c, union of the iterated cell rects) @ 100142fc` (l. 10065, raw `10013f90`).
   (b) **Mask values.** Per redrawn cell — not per frame; nothing fills `0008` wholesale — the first two calls
   (raw `10013688 bl .WrapEraseBoolTile`, `100136ac bl .WrapDrawBoolTile`) use `_DAT_100a0108` = PICT 1002 (32×32,
   all black, opaque; `.PreparePaintFrame` l. 8419–8420): `.BlitEncEraseBoolTileUnmasked @ 100246b4` writes **0xFF**
   over the cell of `0008` (`10024738 li r4,-1`, `1002474c..` `stw`), and `.BlitEncBoolTileUnmasked @ 10023260` writes
   **0x00** over the cell of `0004` (`10023378 lfd f0,-0x61b0(r2)` = `0x100a1690` = 0.0, `100232f4..` `stfd`). Every
   boolean stamp into `0008` — BG face, FG face (the §3.1 step-4 stamp: FG face when the FG face is opaque or there is
   no BG; BG then FG when the BG face has a transparent pixel), overlay o2 faces — writes **0x00** over the stamped
   face's copy-run pixels and leaves skip runs (`.BlitEncBoolTile @ 100230bc`: `10023148 li r4,0`, `10023164..` `stw`;
   the Unmasked twin for opaque faces as above). So `0008` = 0xFF where nothing opaque was stamped (backdrop shows),
   0x00 under opaque BG/FG/overlay pixels; `0004` starts each redrawn cell at 0x00.
10. ⚑ **R5 dump reading (2026-10-10) — the camera focus base and the level-start scroll (engine §5, Research note 16;
   `ghidra/ferazel/Ferazel_pef.decompiled.c`).** Two point pairs exist. `(_DAT_1009fd94, _DAT_1009fd90)` is the
   player's hot-rect centre: `.GameLoop @ 10009d48` sets it to the sprite origin + (0x32, 0x3b) = **(133, 202)** on
   level 1 (l. 5149–5150; origin = (hdr 0x2848 − 0x20, hdr 0x2846 − 0x20) = (83, 143), `.NewGame` l. 5823) and the
   player Handle rewrites it each frame (l. 46376–46388). `.FindUpperLeftCorner @ 1000b5ec` does **not** read it: it
   reads `(_DAT_1009fd44, _DAT_1009fd40)` (l. 5932–5933), which `.SetupPlayerSprite @ 1004aefc` sets to the **sprite
   origin (83, 143)** (`+8`/`+6`, l. 42834–42840) and `.PlayerScroll @ 1004c528` — called from the player Handle inside
   `.PaintFrameWrap`'s `.HandleSprites`, after the draw — sets to `fd44 = fd94 + (_DAT_100a0680 >> 8)` (l. 43794) and,
   with `DAT_100a5f58` set (`.ClearPlayerVars` l. 42577), `fd40 = fd90` (l. 43809–43816). The eased camera
   `(_DAT_1009fd84 + 2, _DAT_1009fd84)` and the scroll point `PTR_DAT_1009fe78` start at the sprite origin − 0xd0 =
   (−125, −65) (l. 5168–5195), and `.FindUpperLeftCorner` eases by `max(Δ/6, 1)` without clamping that pair (the
   clamps apply to `fe78` only, l. 6095–6191). So the view **pans in**: level start (l. 5209) → (−141, −63), iteration 1
   → (−154, −61), both clamped to scroll **(0, 0)**; from iteration 2 the target is (−176 after the 16-px snap, 10) and
   v reaches **10 on the 24th `.FindUpperLeftCorner`** of the level (iteration 23); h stays clamped at 0 (eased −176).
   Neither of the planner's readings ((0, 10) as the first scroll, or (0, 42)) is the first scroll; (0, 10) is where it
   settles. Also: `.SetupLevel` itself zeroes `fe78` and draws `.RedrawEntireScrollGrid` at (0, 0) (l. 2577–2582)
   before `.GameLoop`'s own (l. 5211); the snap tests the player vx `_DAT_1009fd3c` (stored from `+0x24`, handler dump
   l. 2745–2748) and `cRam100a5114` (set each Handle, l. 46393).

---

## Research notes (every probe result the executor needs; probes in `$SCRATCH/probes`, run 2026-10-06)

1. **Files (p01, p08, p20).** SHA-256 / bytes: `Ferazel's Wand.rsrc` 5d1165339d64b4dd360043e62e1baa888762bac69d3555e985a9ce54ec7b401a / 264,712 ·
   `World Data.rsrc` c1b208543ee501219a631ce0a5a0151c818ff15f9aa41090afb5586c8500d541 / 5,511,430 ·
   `Backgrounds.rsrc` 110db531084f970473497f25541736906fa621970c654758b46a28d2ffcf9b1b / 15,821,213 ·
   `Sprites.rsrc` 795ac20d2a5a61ac2f18a31802a76ebd871e028f4bacd1e5bdaa38493e6608f4 / 10,028,422 ·
   `Sounds.rsrc` 39cd36d5bd56908afa6bc607d360592db2172e140be231bbfeaecb8c61c5893f / 2,448,841 ·
   `Titles.rsrc` b1d30e7720f8b30d782824216fea52527a78c2bff761ba744a227d98d210df9b / 4,005,325.
   Music bytes: 01 1,935,726 · 02 1,831,606 · 03 1,650,862 · 04 1,401,574 · 05 2,059,814 · 06 1,685,474 · 07 1,684,318 ·
   08 1,544,918 · 09 3,299,070 · 10 1,607,206 · 11 1,503,166 · 12 1,431,358 · 13 2,089,326 · 14 1,499,902 · 15 1,206,142 ·
   16 1,556,886 · 17 1,469,438 · 18 2,152,702 · 19 1,535,410 · 20 1,687,242 · 22 1,800,882 · 23 1,526,694 · 24 2,202,342 ·
   25 1,306,238 · 26 1,575,654 · 28 1,426,054 · 29 1,310,726 · 30 1,221,238 (music SHA-256 in `out20_sha.txt`; C0 checks
   by `cmp`). Totals: rsrc 38,079,943 + music 47,201,968 = 85,281,911.
2. **Resource census (p01)** = INDEX "Resource census" exactly (counts, ranges); app-fork `DITL` ids −6043..16903.
3. **PICT frame sizes (p03):** Backgrounds 256×384 ×36, 256×256 ×26, 768×256 ×23, 768×768 ×20, 768×708 ×1 (257), strips
   768×{30,44,25,33,57,46,60}; Titles 640×480 ×11, 608×480 ×4, 640×416 ×2, 640×88 (132), 196×45 (133), 52×714 (141), …;
   Sprites: 96×96 ×30, 100×100 ×25, 128×128 ×24, 32×32 ×22, … (full list `out03_picts.txt`). Every v2 picture has
   exactly one bits opcode and bounds = frame (p03, p16).
4. **PICT opcode census (p15):** v2 opcode sets are exactly {0x0001, 0x0011, 0x0098, 0x0C00, 0x00FF} (439) and
   {0x0001, 0x0011, 0x009A, 0x0C00, 0x00FF} (326); DirectBits all packType 4 / cmpCount 3 / 32-bit / mode 64;
   PackBits all mode 0; indexed tables all ctFlags 0 (439) (p04).
5. **v1 BitMaps (p16):** ops 0x11, 0x01, 0x98, 0xFF; rowBytes 0x20 (183) / 0x60 (319, 329, 339, 350); src = dst = frame;
   mode 0; set bits 29,595 / 44,880 / 40,153 / 42,935 / 294,912.
6. **Phase-1 sheets (p03, p04):** L1 tiles FG 200 (256×384, 8-bit), BG 203, pattern 206 (256×256), PxBack 207
   (768×768); fixed 183 (v1), 185 (256×384, 8-bit); Titles 129 (640×480, **4-bit**), 132 (640×88, 8-bit), 133 (196×45,
   **32-bit**); player 1003 400×120, 1004 100×120, 1010 1000×120, 1011 400×120 (32-bit), 1012 600×120, 1013 400×120,
   1014 600×120, 1015 400×240, 1016 700×120, 1017 400×240, 1020 400×480, 1021 500×120 (32-bit), 1022 1500×120,
   1023 1200×120, 1024 400×360, 1025 800×120, 1027 600×120, 1028 1000×120, 1029 600×120, 1030 300×120, 1031..1033
   600×120, 1034/1035 500×120, 1036 600×120, 1037 400×120, 1038 400×120, 1039 900×120 (all 8-bit unless noted);
   1026 (400×152, 32-bit) and 1008/1009 (64×64) exist but are not player face sets (player-states §7).
7. **Mlvl headers (p02).** Sizes: L1 126,748 · L2 126,748 · L3 197,724 · L4 197,724 · L5 53,916 · L10 231,004 ·
   L11 183,292 · L15 257,724 · L18 66,140 · L20 201,452 · L21 234,524 · L22 328,348 · L25 66,140 · L30 183,772 ·
   L31 231,004 · L40 305,884 · L45 145,052 · L50 231,004 · L51 198,972 · L52 128,284 · L55 53,916 · L62 231,004 ·
   L67 52,140 · L70 113,308 (all layout-exact). **Level 1:** name "A Scent Of Peril" (STR# 1000 #1 reads "A Scent of
   Peril"); 0x26c4 = 1; OmniPx 0; 0x26c6 0; start facing 0 (right); 0x26c9 0; ripple 0; pattern period 8×8 (0x26cb 0);
   0x26cc 0; darkness enable 5; camera offsets 0/0; strip 0; alt CLUT 0; flame 0; arena 0; auto-scroll 0; CLUT anim 0;
   chapter 1; start y 175, x 115; music 1; PxBack 207; PxMid 0; FG 200; BG 203; pattern 206; CLUT 201; CLUT+base 202;
   PxMid enable 0; yb 74; ym 128; PxBack 32×8, PxMid 32×8, main 200×50 (6,400×1,600 px). All-level rows: `out02_mlvl.txt`.
8. **Level-1 kind tables (p02):** FG tiles 0..47 → kinds 0..47; 48..51 → 3; 52..55 → 1; 56..59 → 0; 60..63 → 2; 64 → 203;
   65 → 34; 66 → 35; 67 → 32; 68 → 33; 69..95 → −1. BG tiles 0,1 → 200; 2,3 → 201; 4,5 → 202; 6,7 → 103; 11 → 104;
   12 → 107; 13 → 104; 22,23 → 103; rest −1. FG cells drawing a blend face (kind mod 100 in 0..94, tile < 95): 1,335.
9. **Color2Index measurement (p09, p14).** Models: exact = least squared Euclidean on 16-bit channels, ties lowest;
   n-bit inverse table = bit-replicated cell colours (0x1111 steps at 4 bits). Bank §1.2/§1.4 figures reproduced
   exactly (C4 tests). `.ruled` vs `.exactNearest`, per level CLUT (tint 3,603 · water 1,280 · redden 6,144 · ambient
   4,096 · pairs 196,608 requests = 211,731): 202 75,461 · 210 77,037 · 212 73,640 · 214 72,846 · 216 78,302 · 218 74,681 ·
   220 71,105 · 222 63,107 · 224 68,551 · 228 67,848 · 236 79,478 · 238 73,737 · 240 78,219 · 242 73,025 · 246 77,463 ·
   248 73,643 = 1,178,143. CLUT 202 per table (ruled vs exact): k1 36, k2 69, k3 82, k4 56, k5 67, k6 123, k7 160, k8 59,
   k9 32, k0xb 114, k0xc 22, k0xd 43, k0xe 186, k0x10 4/14, k0x11 4/14, k0x16 111; water w0 56, w1 96, w2 130, w3 48,
   w5 67; redden A 843/2,048, B 1,042/4,096; ambient 1,887/4,096; pairs 0154 23,561, 015c 23,002, 0158 23,561 of 65,536
   each. **In one sentence: the ruled 4-bit model and exact-nearest disagree on about a third of every level's computed
   table entries (75,461 of 211,731 on CLUT 202), dominated by the blend pair tables, and on 5–73 source colours per
   Phase-1 sheet.** Face conversion (p10, p11): see C5 tests; transparency is unaffected except 10 px of PICT 185.
10. **ditherCopy (p15).** Every 32-bit PICT says mode 64. Ruling for the build (record in C4's DECISIONS append):
    `.errorDiffusion` (Floyd–Steinberg, top-down, left-to-right, in 16-bit RGB, quantised by the active `ColorSearch`
    model) is the default, `.none` selectable; LOW; on the gate card. Rejected: silently ignoring the mode (would drop
    a visible property of 290 sprite sheets).
11. **World (p12).** Mmap nodes (node → level, (v,h), links, face): 1→1 (307,237) {2}; 2→2 (330,269) {1,3,4}; 3→3
    (355,228) {2}; 4→4 (329,297) {2,5}; 5→5 (294,319) {4,10} f1; 10→10 (230,300) {5,11,15}; 11→11 (227,272) {10,18};
    15→15 (235,358) {10,20,30}; 18→18 (222,225) {11,40} f1; 20→20 (229,393) {15,21}; 21→21 (220,431) {20,22,70};
    22→22 (191,453) {21,25}; 25→25 (136,460) {22} f1; 30→30 (266,476) {15,31}; 31→31 (344,492) {30}; 40→40 (214,143)
    {18,45,60}; 45→45 (241,91) {40,50}; 50→50 (265,51) {45,51}; 51→51 (300,52) {50,52}; 52→52 (328,62) {51,55};
    55→55 (358,71) {52} f1; 60→62 (159,34) {40,62}; 62→67 (77,90) {60} f1; 70→70 (235,469) {21}. Mcnv ids 200..214,
    220, 221, 250..252, 260, 261, 280..283, 300, 400, 401.
12. **Class totals, 24 levels (p21):** as the census `classes` line; unmapped 0.
13. **AIFC (p08):** every track FORM size + 8 = file size; chunks FVER, COMM, INST, SSND, APPL; packets 01 28,463 ·
    02 26,932 · 03 24,274 · 04 20,608 · 05 30,288 · 06 24,783 · 07 24,766 · 08 22,716 · 09 48,512 · 10 23,632 · 11 22,102 ·
    12 21,046 · 13 30,722 · 14 22,054 · 15 17,734 · 16 22,892 · 17 21,606 · 18 31,654 · 19 22,576 · 20 24,809 ·
    22 26,480 · 23 22,448 · 24 32,384 · 25 19,206 · 26 23,168 · 28 20,968 · 29 19,272 · 30 17,956; SSND bytes =
    packets × 68 exactly.
14. **Constants (p13, `tools/const.py` with `FZ_PEF=$FW/Ferazel's Wand`):** 0x100a1728 1.5, 16a8 2.5, 16b0 0.75, 16a0 1.7,
    1698 1.2, 1708 0.15, 1700 0.85, 16f8 0.7, 16f0 0.25, 16e8 29998.08, 16e0 24760.32, 16d8 10475.52 — all **f64**;
    1670 1.0f, 1674 10.0f, 1678 0.0625f — **f32** (ambient darken).
15. **Level-1 placed types (p02; 42 distinct) → bank section for the Setup face (coverage §3):** Background 1090 ×3 (cannon,
    triggers-background §2.2), 1485 ×2 (bars/spiked balls §2.5, "now"), 2710/2713/2714 ×2/3/4 (plants §2.9), 3002 ×1
    (wall tunnel §2.12), 3249 ×1 (level exit, §2.x / world-data §3.4); Bonus 1055 ×43, 1059 ×10, 1292, 1303 ×3, 1307
    ×22, 1335 (now), 3204 (pickups-boxes §1.3–§1.11); Box 1062 ×3, 1065 ×2 (save point, save-continue §2/§9.1), 1308 ×5,
    1464 (rope bridge, platforms-ropes-radial §3.7), 2842 ×3, 2853, 2870 ×7, 2871, 2874, 2883 ×3 (decoration rows,
    pickups-boxes-2 §9), 2902 ×4 (sign), 2910, 2922 ×3, 2924, 2927, 2951, 2952 (talkers/furniture, pickups-boxes §2.2,
    conversations-mcnv §1.2), 3090 ×3, 3092 (crates §2.2); Platform 1400 ×3, 1401 ×2, 1402, 1403 (platforms-ropes-radial
    §2.2); Walker 1700 ×2, 1705 ×4, 1760 (enemies-ground §3.1); Crawler 1712 ×3 (§4); Roach 1720 ×5 (§5). PICTs named
    by type exist for most (p03 list in `out03`); 1401..1403 and 3249 have no same-numbered PICT.
16. **Level-1 start view (p17):** sprite top-left (83, 143); focus (133, 202); target (−176 after the snap, 10) → scroll
    (0, 10); cell window cols 0..19, rows 0..13; 8 placed records inside the margin-free window **without** the
    mandatory 96-px outset, **13 with it** (Fable review; triggers-background-2 §8.3). The focus base is a reading (R5):
    header-based gives focus (165, 234) → scroll (0, 42) [MED].
17. **Probe index:** p01 census · p02 Mlvl · p03 PICT sizes/paths · p04 PICT tables vs CLUTs · p05 used indices ·
    p06 CLUTs · p07 snd · p08 AIFC · p09 Color2Index (A/B/C) · p10 face exposure · p11 transparency · p12 world ·
    p13 constants · p14 per-CLUT disagreement · p15 opcode census · p16 v1 BitMaps · p17 L1 start view · p18 water extent
    · p19 L1 factor tables · p20 SHA-256 / sizes · p20b app icon resources · p21 all-level placements. Libraries:
    `fwlib.py`, `pictlib.py`, `colorsearch.py`, `tables.py`, `gensprite_map.py` (bank copy).

---

## Review ledger

**2026-10-06 — Fable review, verdict ACCEPT_WITH_FIXES (3 Important / 12 Minor); fix pass applied the orchestrator's
rulings.** One line per finding, where it landed:
1. Level 1 has 42 placed types, not 41 → R2 contract, R4 contract + `testSetupFacesLevel1Types`, Research note 15.
2. 1-bit BitMaps bypass `ColorSearch` (0xff / 0x00 fixed) → C5 contract + `testOneBitBitMapsBypassColorSearch`; ladder
   +1 from C5 on (C5 56 … R6 100), self-audit 4.
3. Mask-port fill/stamp values unknown → R1 precondition (b) + ⚑ note in "Bank corrections" before
   `testMaskPortTransparencyRule`; R1 Files.
4. 74 → 73 distinct BG tiles → C2 `testLevel1Maps`.
5. Ambient values are high bytes; 16-bit 0xf198/0xb7ff/0x6fff/0x27ff → C4 `testAmbientDarkenFloat32`.
6. Census may import ImageIO for `--render` → G7 excludes `Sources/ferazel-census`; Invariant 1 names the exception.
7. Activation window includes the 96-px outset → 13 records → R4 `testIdleWindowAtStartLevel1`, Research note 16.
8. "Reduce frame rate" arm (skip on even iterations, pair capped at 4 ticks) → A1 clock contract.
9. Caps Lock / Esc not in Phase 1; Esc does nothing, ⌘Q quits → A1 contract, gate card deviations, Scope.
10. Decompiler traps quoted → "Hazards for every R implementer" block before R1; R1–R6 point at it; self-audit 8.
11. K1 ⚑ MAJOR (two legs) → K1 heading, execution table; R2/R6 reviewer must re-read the dump readings.
12. Gate card items 4, 6, 11 in plain English (what Ben would see if wrong) → gate card.
13. `--render` is the seat's addition → Scope, C6; PICT 257 reads 0 as a seat ruling with the alternative → C0 D26.
14. Focus base is a MED reading; (0, 10) vs (0, 42) → R5 precondition, contract, `testCameraStartScroll`; R6 golden;
    gate card 8; Research note 16.
15. `DrawPicture` may match through the GDevice inverse table → C5 contract hazard; gate card item 1.
Also: every D25 → D26 (Landmine e, C0); Q1 ruled and removed from Open questions (A1, gate card 8); status line.
