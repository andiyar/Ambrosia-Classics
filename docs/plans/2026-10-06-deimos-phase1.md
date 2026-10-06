# Plan — Deimos Rising Phase 1: level 1 look (gate 1) — 2026-10-06

> Status: **REVIEWED — ACCEPT_WITH_FIXES, fixes applied** (planner: Claude Opus 5.5, 2026-10-06; Fable 5.1 review
> 2026-10-06: 0 Critical / 4 Important / 9 Minor, 61 claims PASS; I1–I4 and M1–M4, M7–M9 applied here, M5 moot, M6 is a
> Phase 2 design note). Implements
> `docs/plans/2026-10-06-deimos-design.md` §8 **Phase 1 only** under Ben's rulings **D27** (first gate = level 1 look, no
> gameplay; 640×480 whole-number scale; feel oracle = longplays + his eyes).
> **Format (Ben, 2026-10-03): CONTRACTS, not code** — files, public names (signatures only where they pin a seam),
> behaviour with bank anchors, test names verbatim with the number each checks and where it came from, gate commands,
> commit messages. No implementations.
> **Numbers:** every expected value is from the bank (file § + label), a listing address in
> `~/Developer/Ambrosia-Classics/ghidra/deimos-proj/disasm-review3-all.txt`, or a planner probe run on this machine on 2026-10-06 over the committed
> `Resources/Deimos` (cited "probe pNN", Research notes). Self-derived goldens are named as such. Where a probe and the
> bank disagree, the probe wins and "Bank corrections" says so (none so far).

**Goal.** A staged `Deimos Rising.app` opens a 640×480 window at a whole-number scale and plays the start of sector 1,
Mariner Valley, exactly in the original's frame order: two unpresented ticks, the 9-step fade from black, the jungle map
(`jum2`) scrolling 1 px per tick from row 3120 toward the top at the limiter's 2 Mac ticks per frame, the black 32-px
borders, the score bar at its start values (score `0000000`, two reserve lives, the Ion Cannon icon, the shield meter
filling from empty once the ship is active, the power meter dark, Player 2's block dimmed), the ship absent for 55
ticks, then fading in at (208, 330) with its half-size shadow and the plasma-bomb crosshair 121 px ahead. Left/right
bank the ship and pan the 480-wide map ±32 px; **the ship does not move** (no gameplay). Ben's gate: "does it look like
Deimos".

**Scope.** Design §8 Phase 1. Not in scope (Phase 2+): units/entities of any kind (no enemies, ground objects, level-name
notice `no01`, warp-in `plen`, multiplier/money units), firing, ship velocity/collision, sounds and music, level end
beyond the scroll stopping, pause (Caps Lock), console, `-`/`=`/F6, front end.

**Architecture (design §3).** `Deimos/Core` (one SwiftPM package, Phase 0's) grows: **DeimosCore** (Foundation +
HectorResources + HectorAudio — rules, seams, session), new **DeimosRender** (Foundation + DeimosCore — RGB555 buffers,
blitters, presents), new **DeimosHost** (Foundation + Core + Render — the shell-neutral driver). **Deimos/App** (AppKit +
HectorShell) shows the screen and delivers keys. HectorKit gains one additive API (K1: `ShellView.scalingPolicy` on macOS).

**Tech:** Swift 6.4 / Xcode 27, SwiftPM tools 6.0, XCTest, macOS 15 deployment, xcodegen (`project.yml` is truth).
Python 3 only as the planner's probe tool (never a build or test dependency).

**Paths:**
```
WT      = /Users/andiyar/Developer/Ambrosia-Classics/.claude/worktrees/<lane worktree>  (branched from Classics main)
HK      = /Users/andiyar/Developer/HectorKit        (main 522feb8 = K1 landed, zero-skip FLOOR 316, HectorKit D13 — review fix I1)
HKWT    = /Users/andiyar/Developer/HectorKit-worktrees/deimos-k1   (branch deimos-k1, for K1 only)
LISTING = /Users/andiyar/Developer/Ambrosia-Classics/ghidra/deimos-proj/disasm-review3-all.txt  (+ mem/10000000.bin code, mem/100de330.bin data; r2 = 0x100e6330)
SCRATCH = the executing session's scratchpad directory (logs, dumps; never the repo)
```

---

## Verification model (read first)

**Machine gates — executors close these alone** (copy literally):

| # | gate | command | expected |
|---|---|---|---|
| G1 | HectorKit zero-skip (K1) | `HECTORKIT_TEST_LOG="$SCRATCH/hk.log" "$HKWT/tools/check-zero-skip.sh" 2>&1 \| tail -n 1` | `PASS: zero skips, zero failures, executed 316 == floor 316` (K1 landed at 522feb8; re-run at every merge head) |
| G2 | `Deimos/Core` suite | `cd "$WT/Deimos/Core" && swift test > "$SCRATCH/dm.log" 2>&1; grep -cE "^Test Case '.*' (passed\|failed\|skipped) \(" "$SCRATCH/dm.log"; grep -cE "^Test Case '.*' (failed\|skipped) \(" "$SCRATCH/dm.log"` | the task's ladder total, then `0` |
| G3 | census unchanged | `testStdoutEqualsCommittedCensus` inside G2 is green; `git -C "$WT" diff --stat main -- docs/deimos/data-census.md` | empty (Phase 1 does not touch the census) |
| G5 | apps build (A1 on; Aki + BTX always) | `cd "$WT" && xcodegen generate && for s in Deimos Aki BubbleTroubleX; do xcodebuild -scheme "$s" build 2>&1 \| tail -n 1; done` | `** BUILD SUCCEEDED **` ×3 (Deimos absent before A1) |
| G6 | scope fence | `git -C "$WT" diff --name-only <task base>..HEAD` | ⊆ the task's **Files** (+ `docs/DECISIONS.md` where the task says so) |
| G7 | layering | `grep -rnE "^import (AppKit\|UIKit\|SwiftUI\|CoreGraphics\|CoreText\|ImageIO\|AVFoundation\|QuartzCore\|HectorGraphics\|HectorShell)" "$WT/Deimos/Core/Sources/DeimosCore" "$WT/Deimos/Core/Sources/DeimosRender" "$WT/Deimos/Core/Sources/DeimosHost"` | empty (the census executable keeps its Phase 0 ImageIO/HectorGraphics exception) |
| G8 | kit game-agnostic (K1) | `grep -rniE "deimos\|ambrosia" "$HKWT/Sources" --include=*.swift \| grep -v HectorTestSupport` | empty |
| G9 | staged app boots (A2) | `open "$WT/out/Deimos/Deimos Rising.app"; sleep 8; pgrep -x "Deimos Rising"; osascript -e 'quit app "Deimos Rising"'; ls -t ~/Library/Logs/DiagnosticReports \| head -3` | a pid; clean quit; no new crash report naming the app |
| G10 | clean tree per commit | `git -C "$WT" status --porcelain \| grep -v '^??'` | empty after every commit |

**Test ladder (`Deimos/Core`, cumulative, canonical merge order; STOP if different):** baseline **104** (Phase 0, D24) →
C1 **110** → C2 **116** → C3 **122** → C4 **130** → C5 **139** → C6 **146** → R1 **153** → R2 **164** → R3 **171** →
H1 **177**. Lanes may merge in another order (R1/R2 run beside C2–C6): expected total = previous total + the task's N.
HectorKit: K1 **DONE** — main 522feb8, floor **316** (313 + 3), D13.

**Honesty gate (Ben only):** the gate card (A2). Completion is phrased "machine gates green; Ben's gate pending".

**What the machine does NOT prove:** the 24→16 colour truncation of the sprite plates (Phase 0 note 15, MED); that
the map TGAs are upright (INDEX #10 rule, MED); the TickCount rate (Q1); whether the original showed tearing (it could;
the replica presents whole frames — design §7.1); every MED surface on the gate card.

---

## Non-negotiable invariants

1. **Layering (HectorKit D6, D12, design §3).** DeimosCore: Foundation + HectorResources + HectorAudio. DeimosRender:
   Foundation + DeimosCore. DeimosHost: Foundation + DeimosCore + DeimosRender. `Deimos/App` alone imports AppKit /
   HectorShell. Tests may use Apple frameworks as oracles. Windows traps (D18/W0.5): no `String.Encoding.macOSRoman`
   (use `HectorResources.MacRoman`), no `UserDefaults` below the App.
2. **Kit stays game-agnostic** (G8). K1's doc comments describe scaling, never a game.
3. **Transcribe, don't reinvent.** Core records the original's draw calls at its call sites, in its order, as
   `RenderOp`s; Render executes them on persistent buffers (artefacts included: the score bar persists in the back
   buffer between passes; HUD elements are restored from the save buffer before each redraw). Every behaviour cites
   its bank section or listing address; a contract here never overrides the bank — if they disagree, STOP and report.
4. **No modern affordances** (CLAUDE.md). Phase 1's only additions are the disclosed stubs (◇ in S2) and design §7's
   deviations; each is on the gate card.
5. **Data in git, tests never skip.** Tests read the committed `Resources/Deimos/Data` through Phase 0's
   `DeimosData.dataDirectory()` (`DEIMOS_DATA` overrides). A missing file is a FAILURE naming the path.
6. **Every RNG draw at its original site and order.** Phase 1 has exactly one per in-game player per level start
   (`FUN_100269a0` `10026a9c`: `R(400, 2000)`, player-physics §4.2) after `srand(seed)` (`100057d4`). No other draw. (Before `srand` the session set-up makes one pre-seed
   `FUN_10046580(400, 2000)` draw — the unregistered cut-off, engine-loop §3; it does not affect the seeded sequence; a
   Phase-2 replay implementer must not move it after the seed — review M8.)
7. **Commits:** explicit paths only (never `git add -A` / `.`, never `git stash`); trailer on every commit, both repos:
   `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`. G10 after each.
8. **HectorKit floor-delta rule.** K1 works in `$HKWT` (branch `deimos-k1`), rebases onto `origin/main` immediately
   before the fast-forward push, re-runs G1 on the rebased tree and sets `FLOOR` to the printed total. Classics consumes
   HectorKit only from `~/Developer/HectorKit` main after a clean `pull --ff-only`, through the `.claude/worktrees/HectorKit`
   symlink (D1).
9. **STOP on any unexpected number** (counts, hashes, totals, pixels). Report the output; never edit an expectation.
10. ⚠️ **Landmines.** (a) `swift test` has no package total: count `^Test Case` lines (G2). (b) SwiftPM rejects a
    declared target with no sources — `Package.swift` grows task by task. (c) Quote every path (`Deimos Rising.app`,
    `Deimos Rising.rsrc`). (d) **D-numbers collide** (D23/D24 did; a Ferazel session is active): the next free number on
    `main` at plan time was D28, taken by Cythera — Phase 1 uses **D29** (review I2); confirm at commit and renumber every reference in the same commit if taken. (e) Decoding
    all 2,554 frames per test is slow: cache sprite groups per test process (static), load only what a test needs.

---

## Hazards for every implementer reading the listing (from the bank; read before any listing work)

- **No decompile exists** (`ghidra/Deimos_pef.decompiled.c` was never produced for 1.0.6). Cite listing addresses only.
  Some bank lines (e.g. hud-scorebar's header) cite "the dump" from an earlier partial pass: re-read those in the listing
  when a test pins them (review M7). Listing + memory images: `~/Developer/Ghidra/deimos/proj/` (symlinked as
  `ghidra/deimos-proj` in the main checkout).
- **Static initialisers rewrite templates before `main`** (INDEX #56): the runtime draw-command template is
  `0x100e63e4` with clip {0,0,480,416}, layer 7, scale 1.0, colour 0x7fff (sprite-geometry-draw §3.1) — not the data
  image bytes. HUD template `0x100eb228` (hud-scorebar §4; the `subi r5,r7,0x4` copy loop hides +4/+8 — the
  `lwzu/stwu` trap).
- **Signed-compare idiom** `eqv; subfc; rlwinm; addze; rlwinm` = `rB < rA` signed (timing-frame §7).
- **Float precision:** single-precision `fsubs/fmuls/fdivs/fadds/fmadds` wherever the listing says so (visibility alpha,
  RandomRange, scaled-blit anchors, mode-2 α); emulate with `Float`, never `Double`.

---

## Shared architecture (LOCKED — every task codes against these names)

### S1. Package `Deimos/Core`
Existing `Package.swift` (tools 6.0, macOS 15, `HECTORKIT_PATH` fallback) gains, task by task: library products
`DeimosRender` (R1) and `DeimosHost` (H1); targets `DeimosRender` (deps `DeimosCore`), `DeimosHost` (deps `DeimosCore`,
`DeimosRender`), test targets `DeimosRenderTests` (`DeimosRender`, `DeimosCore`), `DeimosHostTests` (`DeimosHost`,
`DeimosRender`, `DeimosCore`). New Core sources go under `Sources/DeimosCore/{Seams,Game,Player,ScoreBar,Draw,Text}/`.

### S2. DeimosCore public surface (★ LOCKED after Phase 1 · ◇ Phase-1 stub, replaced in Phase 2)
- ★ `DeimosAssets` — `static func load(index: TagIndex) throws -> DeimosAssets`: the permanent lists as `FUN_1001fcf0`/
  `FUN_1001fe60` load them — `floats` (flli `gafl`, 220), `gameStrings` (stli `pgsl`), `formats: [TextFormat]` (54, in
  `idli gate` order — format i = item i), `objects`/`sounds`/`sprites` (idli `gaob`/`gaso`/`gasp`), `fonts` (`tesp`),
  `rects` (reli `inre`), `colors` (coli `gaco`), `definitions: DefinitionLists`, and `func spriteGroup(_ id: FourCC)
  throws -> SpriteGroup` (cached, `SpriteGroup.load`).
- ★ `LevelOrder` — the 12 identifiers of engine-loop §6 (Lucena, Yippe, Vista, Swoop, Conrad, Delos, Sparta, Saratoga,
  Hannibal, Leonidas, Thebes, Yamato) matched against `#indentifier_STR`: `func level(sector: Int) -> FourCC`
  (`none` outside 1…12), `func sector(of: FourCC) -> Int?`.
- ★ `DeimosPrefs` — the 0x34f0 record's fields used so far with the fresh-prefs defaults of timing-frame §6 / engine-loop
  §10 (byte prefs; int prefs 0..3; the 14-code key table at `+0x14b8`; default high scores + names). File I/O is Phase 4.
- ★ `MSLRandom` — `srand`, `rand` (engine-loop §9), `range(_ min: Int32, _ max: Int32) -> Int32` (`FUN_10046580`),
  `range(_ lo: Float, _ hi: Float) -> Float` (`FUN_100465e0`, float32).
- ★ `FrameController` — the 0x38-byte object's arithmetic (timing-frame §1–§2): tick flag, frames presented, Esc hold.
- ★ `ScrollState` — G_Background (level-scroll-objects §1–§5, §9).
- ★ `Player` — the player object fields used in Phase 1 (player-physics §1) with ◇ `Player.updatePhase1` (S2 note).
- ★ `ScoreBarState` — hud-scorebar §2–§3, §6–§7.
- ★ `EntityDraw` (draw-command builders), `TextLayout`, `GlyphMap`, `ScoreBarDraw`.
- ★ `DeimosSession` — `init(assets: DeimosAssets, prefs: DeimosPrefs, start: SessionStart, seed: UInt32) throws`;
  `mutating func pass(keys: HeldKeys) -> PassOutput` (one iteration of the `FUN_100051a0` while loop, engine-loop §3).
  `SessionStart` = (`sector` 1…12, `players` 1…2, `film: Film?` — film unused in Phase 1).
- ◇ **Phase-1 stubs (gate card lists them):** `Player.updatePhase1` runs the life-state step for states 2 → 4, the appear
  and glow step, the size refresh, and in state 4 only: the crosshair part of the weapon-handler tick, the banking frame
  and the view-shift calls — **no velocity, integration, clamp, firing, power-up or overload**; the ship stays at
  (208, 330). Entities are not built: `plen` (entry spawn), the multiplier unit and `no01` are not spawned.

### S3. Seam types (DeimosCore; ★ LOCKED once Phase 1 lands — cases may be added, never renamed)
```swift
public struct HeldKeys: Equatable, Sendable { public var held: Set<UInt16>; public var capsLock: Bool }   // Mac virtual key codes (GetKeys)
public struct PlayerInput: OptionSet, Sendable { /* bits = film byte: left 0, right 1, up 2, down 3, fireGround 4, fireAir 5, select 6 */ }
public enum BufferID: Sendable { case back /* D+0x68 640×480 */, terrain /* D+0x6c, level map */, scoreSave /* D+0x70 160×480 */ }
public enum PresentKind: Sendable { case gameScreen /* FUN_1000beb0 */, gameLayout /* FUN_1000bd80 */, fullScreen /* FUN_1000bc60 */ }
public enum FadeKind: Sendable { case fromBlack /* FUN_1000ba70, 9 steps */, toBlack /* FUN_1000b9a0, 33 steps */ }
public struct DrawCommand: Equatable, Sendable {      // the 0x4c-byte command (sprite-geometry-draw §3.1, runtime template)
    public var face: FourCC; public var frame: Int; public var x: Int32; public var y: Int32   // face/frame +0x0c/+0x10; centre x/y +0x04/+0x08
    public var flags: UInt32                         // 1 fade, 2 shadow, 4 tint, 8 terrain buffer (+0x14)
    public var scale: Float; public var alpha: UInt32 // +0x18, +0x1c (0..32; 32 = not drawn)
    public var clip: MacRect; public var layer: UInt8; public var drawNow: Bool; public var colour: UInt16   // +0x20, +0x30, +0x31, +0x34
    public var costRect: MacRect?; public var costColour: UInt16   // face 'COST' only (+0x38..+0x44, +0x48)
    public static let template: DrawCommand           // face none, frame 0, x/y 0, flags 0, scale 1, alpha 0, clip {0,0,480,416}, layer 7, drawNow false, colour 0x7fff
}
public enum RenderOp: Equatable, Sendable {           // one per original call site, in pass order
    case loadTerrain(image: FourCC)                                        // FUN_1000fbc0: terrain buffer ← im16, resized
    case fill(BufferID, colour: UInt16)                                    // FUN_10009f00: PaintRect portRect (level start: back ← 0, 1000690c; review I4)
    case loadImage(image: FourCC, into: BufferID, dst: MacRect)            // FUN_10031400 'scor'
    case copy(from: BufferID, to: BufferID, src: MacRect?, dst: MacRect?, interlaced: Bool)   // FUN_10009fd0
    case draw(DrawCommand)                                                 // FUN_10019570 (drawNow) or the queue FUN_1001a450
    case clearLayers                                                       // FUN_100189f0
    case flushLayers(ClosedRange<Int>)                                     // FUN_10018b20: 0...1, 2...5, 6...15
    case screenBlit(src: MacRect, dst: MacRect)                            // FUN_1000bbd0: back → screen (HUD dirty rects)
    case fade(FadeKind, PresentKind)                                       // blocking; the host steps it
    case limit                                                             // FPS limiter point (host waits)
    case present(PresentKind)                                              // end-frame present
}
public struct PassOutput: Equatable, Sendable {
    public var ops: [RenderOp]; public var sounds: [SoundCue]; public var music: [MusicCue]
    public var requests: [ShellRequest]; public var ticked: Bool; public var sessionEnded: Bool
}
public struct SoundCue: Equatable, Sendable { public var id: FourCC; public var priority: Int32; public var volume: Int32; public var pitch: Float; public var allowMultiple: Bool }
public enum MusicCue: Equatable, Sendable { case play(FourCC, loop: Bool), stop, pause, resume, level(Int32) }
public enum ShellRequest: Equatable, Sendable { case hideCursor, showCursor }
```
`SoundCue`/`MusicCue` stay empty in Phase 1 (declared now so they are locked with the rest).

### S4. DeimosRender public surface
`Pixmap555` (width, height, `[UInt16]` x1R5G5B5 row 0 top), `DeimosRenderer` (`init(assets:) `; `func apply(_ op:
RenderOp)` for every op except `.fade`/`.limit`; `func fadeBegin(_:)`, `func fadeStep(_ kind: FadeKind, a: Int, present:
PresentKind)`, `func fadeEnd()`; `var screen: Pixmap555`; `func buffer(_ id: BufferID) -> Pixmap555`),
`SpriteBlitter`, `Blend555`, `CopyBits`, `ScreenRGBA` (`static func convert(_ screen: Pixmap555, into: UnsafeMutablePointer<UInt32>)`,
0xAARRGGBB, row 0 top = `ShellBitmap.pixels`).

### S5. DeimosHost public surface
`MacTicks` (`static func ticks(seconds: Double, rate: Double) -> UInt32`), `TickRate` (`.classic` 60.15 — default per Q1,
`.osx` 60.0), `KeyTable` (prefs key table → `PlayerInput` per player), `DeimosDriver` (`init(assets:prefs:rate:start:)`,
`mutating func idle(seconds: Double, keys: HeldKeys) -> DriverOutput`, `var screen: Pixmap555`), `DriverOutput`
(`screenChanged: Bool`, `requests: [ShellRequest]`).

### S6. App `Deimos/App` (AppKit, `@MainActor`, no test target — Aki/BTX precedent)
`DeimosMain.swift`, `DeimosController.swift`, `DeimosAssets+Bundle.swift`, `Info.plist`, `AppIcon.icns`.

### S7. `project.yml` (a MERGE into the existing top-level keys — never a second copy; BTX R11)
```yaml
packages:
  DeimosCore:
    path: Deimos/Core
targets:
  Deimos:
    type: application
    platform: macOS
    sources:
      - path: Deimos/App
        excludes: ["Info.plist"]
    dependencies:
      - { package: DeimosCore, product: DeimosCore }
      - { package: DeimosCore, product: DeimosRender }
      - { package: DeimosCore, product: DeimosHost }
      - { package: HectorKit, product: HectorShell }
    settings:
      base:
        PRODUCT_NAME: "Deimos Rising"
        PRODUCT_BUNDLE_IDENTIFIER: com.ambrosiaclassics.deimos
        INFOPLIST_FILE: Deimos/App/Info.plist
        GENERATE_INFOPLIST_FILE: NO
        ENABLE_APP_SANDBOX: NO
schemes:
  Deimos:
    build:
      targets:
        Deimos: all
```

### S8. Runtime data
The staged `.app` carries `Resources/Deimos/Data/{Paks,Local}` under `Contents/Resources/Deimos/Data/` (D10/D24); the
App's locator resolves it from `Bundle.main` and hands it to `TagIndex(dataDirectory:)`.

---

## Tasks

Legend: ⚑ MAJOR = two review legs (spec compliance, then quality; Fable reviewers, report everything with confidence);
minor = one leg. "+N" = new `Test Case`s. Every task: G6, G7, G10, plus the gates named.

### K1 — minor — HectorKit: `ShellView.scalingPolicy` on macOS (+3, kit)
- **Files ($HKWT):** `Sources/HectorShell/ShellView.swift`, `Sources/HectorShell/ShellWindowController.swift`,
  `Tests/HectorShellTests/ShellViewScalingPolicyTests.swift` (new), `tools/check-zero-skip.sh` (FLOOR), `docs/DECISIONS.md`
  (next free HectorKit D-number, expected **D12**), `docs/STATE.md` (one line; also fix its stale "floor 300" → current).
- **Contract (additive):** `ShellView.scalingPolicy: ShellScalingPolicy` (macOS), default **`.aspectFit`** = today's
  `ShellScaling.layout(...)` exactly (Aki, BTX unchanged); `.integerFit` = `ShellScaling.integerFit` (largest whole
  multiple that fits, centred, nearest-neighbour, black surround — the iOS `ShellTouchView` rule); setting it relays out
  at once and re-applies the contents filters. `ShellWindowController.init(..., scalingPolicy: ShellScalingPolicy =
  .aspectFit)` passes it to its view (windowed and full screen share the view). Doc comments describe the policies only.
- **Tests (3):** `testDefaultPolicyIsAspectFitUnchanged` (view 3024×1964 px → the existing smooth rect (202, 0, 2619, 1964))
  · `testIntegerFitFullscreenPanel` (640×480 canvas in 3024×1964 px → k 4, rect (232, 22, 2560, 1920), integerScale 4)
  · `testIntegerFitExactWindow` (1280×960 px → k 2, the whole view).
- **DONE (2026-10-06):** HectorKit 522feb8 (D13, floor 316), Fable review MERGEABLE (3 Minor: test seam `backingPixelSizeOverride` ships un-gated, harmless; one doc rewrap); Classics Aki + BTX BUILD SUCCEEDED against it. Ferazel's session told.
  Rebase, re-gate, `git push origin HEAD:main`, clean `pull --ff-only` in `~/Developer/HectorKit`.
- **Shared with Ferazel:** Ferazel's A1 assumes integer full screen (`docs/plans/2026-10-06-ferazel-phase1.md` A1) but
  has no kit task for it. Whichever session lands first, the other reuses it — the orchestrator tells the Ferazel session.

### C1 — minor — Seams, assets, prefs defaults, level order, D29 (→ 110)
- **Files:** `Sources/DeimosCore/Seams/{HeldKeys,PlayerInput,DrawCommand,RenderOp,PassOutput,SoundCue,MusicCue,ShellRequest}.swift`,
  `Sources/DeimosCore/Game/{DeimosAssets,LevelOrder,DeimosPrefs}.swift`; `Tests/DeimosCoreTests/{SeamTests,AssetsTests}.swift`;
  `docs/DECISIONS.md`.
- **Contract:** S2/S3 verbatim. `DrawCommand.template` = the runtime template (Hazards). `DeimosPrefs.fresh` = timing-frame
  §6 table (byte 2 = 0, 4 = 1, 5 = 0, 6 = 0, 7 = 0, 8 = 0, 9 = 0, 10 = 1; int 0 = 50, 1 = 100, 2 = 50, 3 = 1; key table
  0x7E 0x7B 0x7C 0x7D 0x37 0x3A 0x31 | 0x5B 0x56 0x58 0x57 0x77 0x75 0x79) + engine-loop §10 defaults (scores 15000…1000;
  names Mars … Electrofryer; player names "Player 1/2"; sector name "New Atlantis"). DECISIONS **D29** "Deimos Rising build:
  design + Phase 1 rulings (seat)": design §3 layers incl. DeimosHost (rejected: per-shell controllers, D15 cost), §5 render
  model incl. RGB555→RGBA bit replication (`(c<<3)|(c>>2)`, the kit's PICT rule) and whole-frame presents, §7 deviations,
  §8 phase proposal pending Q7, Q1 default 60.15 Hz pending Ben, the Phase-1 stubs (S2 ◇), key table as the input source.
- **Tests (6):** `testDrawCommandRuntimeTemplate` (fields above; sprite-geometry-draw §3.1) · `testFreshPrefs` (the
  defaults above) · `testPermanentLists` (220 floats; `floats[18]` 2, `[33]` 2, `[54]` 416, `[55]` 480, `[59]` 32, `[166]` 1,
  `[183]` 13; 54 formats with `[41]` sbsh, `[43]` sbs1, `[45]` sbl1, `[47]` sll1; probe p04/p05) · `testLevelOrder` (sectors
  1…12 → le07 le06 le02 le08 le11 le04 le12 le03 le05 le01 le10 le09; engine-loop §6 HIGH) · `testLevelOneDefinition` (le07
  "Mariner Valley": map `jum2`, mask `jut2`, music `mu03`, rect (0, 0, 3600, 480), 38 objects, none with yLoc ≥ 3056 — so
  no load-time spawns; p01) · `testSectorOneWeapons` (PEAA defs containing sector 1 = `aiic` only; P1 face `pl1o`, P2 `pl2o`;
  preview `wesy` 0; p02).
- **Gate:** G2 = **110/0**. **Commit:** `DeimosCore: LOCKED seam types, DeimosAssets, LevelOrder, fresh prefs; DECISIONS D29; 6 tests`.

### C2 — minor — RNG and the frame controller (→ 116) — ∥ C3
- **Files:** `Sources/DeimosCore/Game/{MSLRandom,FrameController}.swift`; `Tests/DeimosCoreTests/{RandomTests,FrameControllerTests}.swift`.
- **Contract:** engine-loop §9 (HIGH): `state = state·0x41c64e6d + 0x3039`, `rand = state >> 16 & 0x7fff`; int range
  `min == max ? min (no draw) : min + rand % (max − min + 1)`; float range `lo == hi ? lo (no draw) : m + (hi − lo)·rand /
  32767.0f` with m = (lo > hi ? hi : lo), every operation float32 (`100465fc…1004665c`). `FrameController` (timing-frame
  §1–§2.5, HIGH): divider 0 forever → tick flag 1 on every pass; frames-presented `+8` and window counter `+0x20` +1 per end
  frame; Esc (`FUN_100307c0`): pref 8 = 0 → quit on the first pass Esc is down; pref 8 = 1 → counter bumped at begin frame
  and again at the end-frame wrapper, quit when > 30 at a begin-frame call (the 16th held pass); release resets. The FPS
  monitor and auto-interlace are Phase 2 (they show only with pref 9 / never with stock prefs).
- **Tests (6):** `testRandSeedOne` (16838, 5758, 10113; p08) · `testRandSeedDemo01` (seed 0x469c2 → 26662, 28174, 2951;
  p08) · `testIntRange` (after `srand(0x469c2)`: `range(400, 2000)` = 1446; `range(5, 5)` = 5 and the state is unchanged)
  · `testFloatRange` (each call after its OWN fresh `srand(1)` — review I3; sequential after one `srand(1)` the triple is 1.5138707, 0.8242744, 0.9234535, also pinned: `range(1.0, 2.0)` = 1.5138707 (float32 bits exact); `range(2.0, 1.0)` = 0.48612934;
  `range(0.8, 1.2)` = 1.0055482; `range(1.5, 1.5)` = 1.5 with no draw; p08) · `testTickEveryPass` · `testEscRule`.
- **Gate:** G2 = **116/0**. **Commit:** `DeimosCore: MSL rand + int/float RandomRange (float32), frame controller tick/Esc arithmetic; 6 tests`.

### C3 — minor — Scroll and the terrain window (→ 122) — ∥ C2
- **Files:** `Sources/DeimosCore/Game/ScrollState.swift`; `Tests/DeimosCoreTests/ScrollStateTests.swift`.
- **Contract:** level-scroll-objects §1–§5, §9 (HIGH): `levelStart(rect:)` (`FUN_1000fa90`: speed 1, end flag 0, scrolled 0,
  offset 0, step 0; window (top 3120, left 32, bottom 3600, right 448); progress 481); `advance()` (`FUN_10010220`: top −=
  speed, progress += speed clamped [0, 3600], bottom −= speed, top < 1 → (0, 480), reverse guard, scrolled = old − new);
  `step() -> Bool` (`FUN_10010000`: advance; speed 0 → return end flag; progress ≥ 3600 → progress = 3600, end = 1, speed 0,
  return true; the spawn-row call is Phase 2); `pause()`/`resume()` (`FUN_1000ffe0`/`FUN_1000ffc0`, resume refused once
  ended); `shift(right: Bool)` (`FUN_100100b0`, clamp [−32, 31], last step stored); `terrainBlit(interlaced:) -> RenderOp`
  (`FUN_10010120`: `.copy(from: .terrain, to: .back, src: (top, max(0, off + 32), top + 480, off + 448), dst: (0, 0, 480,
  416), interlaced: pref 5)`).
- **Tests (6):** `testLevelStartWindow` · `testAdvanceOnePixelPerTick` (after k steps top 3120 − k, progress 481 + k) ·
  `testLevelEndOnScrollTick3119` (no end through k = 3118; k = 3119 → end, top 1, speed 0; sticky; `resume` refused; §3) ·
  `testPauseResume` · `testShiftClamp` (40 × left → −32; 70 × right → 31) · `testTerrainBlitRects` (offsets −32, 0, 31).
- **Gate:** G2 = **122/0** (canonical). **Commit:** `DeimosCore: ScrollState (G_Background window, 1 px/tick, level end at progress 3600, h-shift [−32, 31]); 6 tests`.

### C4 — ⚑ MAJOR — Player (Phase-1 subset) and score-bar state (→ 130)
- **Precondition (read Hazards):** read in `$LISTING` and record (one paragraph each, in the task's PR notes and as doc
  comments): `FUN_1002a150` state 2 compare (`1002a1b4..1002a1e4`, `now > enter + 55`); `FUN_10029cc0` (`10029d00..10029e34`);
  `FUN_100269a0` (`…10026a9c`); `FUN_10012750` (`10012750..10012838`, below); the crosshair reset in `FUN_1003af90`
  (`1003b148..1003b15c`) and where `FUN_1003b3c0` steps the crosshair visibility (loose-ends-combat §6.2); `FUN_100317e0`
  (`10031810…10031aac`). If a reading disagrees with this contract: STOP.
- **Files:** `Sources/DeimosCore/Player/{Player,PlayerPhase1}.swift`, `Sources/DeimosCore/ScoreBar/ScoreBarState.swift`;
  `Tests/DeimosCoreTests/{PlayerPhase1Tests,ScoreBarStateTests}.swift`.
- **Contract:**
  - `Player.setup(index:players:sector:)` (`FUN_10026410` subset, player-physics §7): in game = index 0, or both when
    players ≠ 1; lives 3 at sector 1 else 1 (0 when not in game); score 0; shield 100; state 2 if in game else 1.
  - `Player.levelStart(now:rng:)` (`FUN_100269a0`, §4.2): returns at once when not in game; else sprite = the air weapon's
    appearance face (`aiic` → `pl1o`/`pl2o`), frame 0, `+0xd4` = 0, position (208, 330) solo / (104 | 312, 330) multi,
    velocity 0, **state 2 at now**, appear fade (0, 100, 2.0) (flli 163–165), crosshair visibility (0, 100, flli 149 = 6),
    then exactly one `rng.range(400, 2000)` (result stored for P1 only, §9).
  - ◇ `Player.updatePhase1(now:input:scroll:scoreBar:)` (⚑ as built: `scoreBar` inout keeps `FUN_10031710` at its call
    site `1002a1dc`; orchestrator ruling) in `FUN_10028170`'s order (§2): life-state step (state 2: after `now > enter
    + 55` → respawn path `FUN_10029cc0` subset: frame 0, `+0xd4` 0, position, velocity 0, appear fade reset, crosshair reset,
    **state 4 at now**; else score-bar shield display forced 0); input bytes from `input` in state 4 only (⚑ as built + C4 spec review: untouched otherwise —
    `1002a3c4 lbz 0xc6; cmplwi 4; bne exit`); `FUN_10012750` step — **[HIGH, listing `10012750..10012838`]**: if cur > req: cur −= δ, < 0 → 0, < req → req;
    else if cur < req: cur += δ, > req → req; same rule for the glow triple +0x58/+0x5c/+0x60; clear `+0xc5` when cur ==
    req; size refresh (53×43 → half 26×21); state 4 only: crosshair flag = 1 and one crosshair visibility step, banking
    (`now > +0xd4 + 1` → `+0xd4` = now, then the three 7-entry tables of §2.4), view shift (left → `scroll.shift(false)`,
    else right → `shift(true)`), crosshair position (cx = x + 0, cy = y − 121 + adj 0, floored at half-height 6; §2.6).
  - `ScoreBarState` (hud-scorebar §2–§3, §6–§7): init (`FUN_10030f40`); `levelStart(players:)` (`FUN_10031400` state part:
    all six dirty, displayed shield/power 0, last score/lives = current, `+0x12e = +0x12f` = in game; icons via
    `FUN_1003bb40`); `update(players:)` (`FUN_100317e0`: clear dirty; not in game → one dim redraw then frozen; score/lives
    change → dirty; handler `+0x08` (stays 1) → dirty weapons + icon rebuild; shield follower −3/+2 (rise only in state 4);
    power follower −4/+2 then the < 1 → 0, > 100 → 100 clamp; power target 0 in Phase 1).
- **Tests (8):** `testLevelStartPlayerOne` (fields above; RNG advanced by exactly one draw; with `srand(0x469c2)` the draw
  is 1446) · `testSoloPlayerTwoMakesNoDraw` · `testEntersActiveAtTick56` (state 2 for t ≤ 55; 4 entered at 56) ·
  `testAppearFade` (visibility 2 at t 56, 4 at 57, …, 100 at 105; `+0xc5` cleared at 105; overshoot clamps both ways,
  synthetic) · `testBankingTables` (tables of §2.4 verbatim; with left held from t 56 frames 1, 2, 3, 3 at t 56, 58, 60, 62;
  then right: 2, 1, 0, 4, 5, 6, 6; left from frame 4 → 3) · `testViewShiftFromInput` (left 40 ticks → −32; nothing before
  t 56; left wins over right) · `testCrosshair` (flag 0 through t 55; at t 56 position (208, 209), visibility 6; 100 at
  t 72) · `testScoreBarFollowersAndIcons` (displayed shield 0 through t 55, 2·(t − 55) from 56, 100 at 105; power stays 0;
  P1 icon slot 0 = (`wesy`, 0), slots 1–2 `none` because the cycle at sector 1 wraps to `aiic`; weapons dirty every tick;
  P2 dims once at level start and never again).
- **Gate:** G2 = **130/0**. **Commit:** `DeimosCore: player Phase-1 subset (life states 2→4, appear fade, banking, view shift, crosshair), score-bar state; 8 tests`.
- **Seat alone:** internal decomposition. **Ben's:** none (stubs are on the gate card).

### C5 — ⚑ MAJOR — Draw-command builders, text layout, score-bar draw (→ 139)
- **Precondition (read Hazards):** read `FUN_10012650` (base reset: `+0x18/+0x19/+0x1a/+0x37/+0x38/+0x4c/+0x68`
  defaults) and the crosshair object's set-up in `FUN_1003ade0`/`FUN_1003af90` (handler `+0x8c`): record its draw layer,
  `+0x19`, `+0x37/+0x38` (does the crosshair cast a shadow?) and clip. Read `FUN_1000e670` (glyph draw) and the element
  order inside `FUN_10031ae0` (`10031b04…10031d3c`). Record each as a doc comment with addresses; anything left MED goes
  on the gate card (A2).
- **Files:** `Sources/DeimosCore/Draw/EntityDraw.swift`, `Sources/DeimosCore/Text/{GlyphMap,TextLayout}.swift`,
  `Sources/DeimosCore/ScoreBar/ScoreBarDraw.swift`; `Tests/DeimosCoreTests/{EntityDrawTests,TextLayoutTests,ScoreBarDrawTests}.swift`.
- **Contract:**
  - `EntityDraw` (sprite-geometry-draw §3–§6, HIGH): entry `FUN_10012f20` (nothing when visibility ≤ 0; shadow pass if
    `+0x38` and the SHADOWS byte (always 1, §3.2); sprite pass if `+0x37`); sprite command `FUN_10012fa0` (x = trunc(e.x) −
    hOffset when `+0x18`; layer from the 4CC table — `play` 10; flags |1 and alpha = `FUN_10010c20` when visibility ≠ 100;
    tint pass when `+0x58 > 0`; hit pass when `+0x74`); shadow command `FUN_10013460` (`play` row: layer 6, scale 0.5·s,
    offset (trunc(k·−48), trunc(k·104)) with k = 0.5 (`+0x1a` clear) = (−24, +52); flags |2; alpha 20, or max(20, alpha(v))
    when visibility ≠ 100); visibility → alpha `min(32, trunc(|32·v/100 − 32|))` in float32 (§4.1). Player draw order
    `FUN_100298c0` (micro-wave §3.9, HIGH): state 4 only — crosshair (`FUN_1003bd00` → entry on handler `+0x8c` when
    `+0x120`), shadow-only pass, sprite-only pass.
  - `GlyphMap` (text-metrics-lists §1.1, data-tags §5): chars 0x21…0x7e → frames of the table; everything else → 90.
  - `TextLayout` (hud-scorebar §9, text-metrics-lists §1.5–§2.4, HIGH): first-call digit cache (`DAT_100e0124` = '2' →
    mono cell = width of frame 53 = 6); width pass `W = Σ (spacing + width)`; start x CENT `fctiwz(X − 0.5·W)` (float32),
    RIGH `X − W`, CEBU/CEGA centred in 640/416, LEFT X; per char `cell = x + spacing`, glyph command centred at (cell + w/2,
    Y + h/2), `x = cell + width`; space advances 4 (frame 90), never drawn; colourise → flags 4 + colour (alpha = blend),
    else blend > 0 → flags 1; layer `+0x10c`, clip select `+0x10d`, draw-now `+0x110`; colour strip as §2.3 (queued).
  - `ScoreBarDraw` (hud-scorebar §4–§5, §7): `levelStartOps` (`FUN_10031400`: `loadImage(scor, .back, (0, 416, 480, 576))`,
    `loadImage(scor, .scoreSave, (0, 0, 480, 160))`, then `FUN_10031ae0`'s element ops with screen blits off);
    `drawOps(blitToScreen:)` per dirty element: `copy(from: .scoreSave, to: .back, src: local, dst: buffer)`, the element's
    draws (score `%0.7i` tefo 43/44; lives symbol `play` frame 0/1 at F112–115; count `n = max(lives − 1, 0)` capped 9, tefo
    45/46 or red 47/48 when active and n = 0; icons F128–139 with blend 6 / 16 and scale 0.7; meters `shme` at F116–125 +
    `COST` {top, left + fill, bottom, right}, `fill = fctiwz(v/100·width)`, blend 8 colour 0 when v < 100; dim = blend
    halfway to 32 / flag 1 blend 16), then `screenBlit` of the element rect (+ (0, 448)) when `blitToScreen`.
- **Tests (9):** `testVisibilityAlpha` (v 100 → 0, 50 → 16, 6 → 30, 2 → 31, 1 → 31, 96 → 1, 97 → 0, 150 → 16; 0 → not drawn) ·
  `testPlayerSpriteCommand` (v 100: `pl1o` 0 at (208, 330), layer 10, flags 0, scale 1, alpha 0, clip {0,0,480,416}, queued)
  · `testPlayerShadowCommand` (v 100: layer 6, flags 2, scale 0.5, (184, 382), alpha 20; v 2: alpha 31 and the sprite flags
  1 alpha 31) · `testPlayerDrawOrder` (crosshair, shadow, sprite; nothing in state 2) · `testHOffsetPans` (offset −5 → sprite
  x 213, shadow x 189) · `testGlyphMap` ('A' 0, 'a' 26, '1' 52, '0' 61, '(' '[' '{' 69, ' ' 90, 0x80 90) ·
  `testDigitCacheQuirk` (cell 6, not 7; tesm widths 5 6 7 7 7 7 6 7 7 7 for frames 52–61; p06) · `testScoreAndLivesLayout`
  ("0000000" sbs1: start 459, glyph lefts 463 473 483 493 503 513 523, top 83, flags 4, colour 0x4B7C, alpha 0, draw-now;
  P1 lives "2" at 496, top 50, frame 53; P2 score at top 318 alpha 16; P2 lives "0" at 495 top 285 alpha 16; hud worked
  example + p05) · `testScoreBarLevelStartOps` (the exact op list for a solo game: two `loadImage`s, P1 elements in the
  listing's order with their commands — symbol (515..552 × 22..59), meters (447..542, COST from x 447 = fill 0), slot 0
  `wesy` 0 at (467, 199) flags 1 alpha 6 — P2 dimmed, no `screenBlit`).
- **Gate:** G2 = **139/0**. **Commit:** `DeimosCore: draw-command builders (sprite, shadow, visibility alpha, layers), glyph map + text layout, score-bar draw ops; 9 tests`.

### C6 — ⚑ MAJOR — `DeimosSession.pass`: the frame, in the original's order (→ 146)
- **Precondition:** read `FUN_100051a0` `100058f8..10005ab0` (loop body), `FUN_10030360` begin frame, `FUN_10007070`
  (`1000708c…10007108`, below), `FUN_10030bc0` end frame, `FUN_100064d0` level start (Phase-1 subset); record the order
  as the doc comment of `pass`.
- **Files:** `Sources/DeimosCore/Game/DeimosSession.swift`; `Tests/DeimosCoreTests/DeimosSessionTests.swift`.
- **Contract:**
  - `init` = `FUN_100051a0` set-up subset: `srand(seed)` (`100057d4`); both player objects, `setup` for index 0 and 1;
    frame-controller start; then level start `FUN_100064d0` subset (level-scroll-objects §8): game time 0, appeared 0,
    level = `LevelOrder.level(sector:)`, each player `levelStart` (P1 then P2), `ScrollState.levelStart`, ops
    `loadTerrain(jum2)`, `fill(.back, colour: 0)` (`1000690c`, after the (absent) notice spawn — review I4), the score-bar
    level-start ops (bracketed `FUN_10031ad0(0)`/`(1)`), the first terrain blit. Doc-comment (review M3): `FUN_100189f0`
    clears the layer lists at level start (`10006824`, a no-op at init); if byte pref 5 is set at level start, `game+0xf`
    = 1 and pref 5 is cleared, restored at appear (`1000693c..10006970`, `10005990..100059b0`) — moot with fresh prefs. Init ops are returned by the first `pass`.
  - `pass(keys:)` — one loop iteration (engine-loop §3, timing-frame §2.1–§2.4):
    1. Begin frame: `clearLayers`; Esc rule (C2) — quit clears the run flag only (`FUN_100064c0` = `stb 0, 0x8(game)`): the pass still ticks, draws and
       presents, and its output carries `sessionEnded = true` (the `while` exits before the next pass; review M1); Caps Lock, console, volume
       and F6 are not acted on (Phase 2; gate card); input from `keys` through the prefs key table.
    2. Tick (always): if not appeared and game time == flli 18 (2): `fade(.fromBlack, .gameLayout)`, appeared = 1 (music
       is Phase 2). Update world subset in `FUN_10006b50` order: players (P1, P2) → score-bar update → `scroll.step()`
       (pauses never requested — no entities). Game time += 1.
    3. Draw world `FUN_10007070` (every pass): [entity groups, blurs — none] → each player's draw → [tally, notices — none]
       → score-bar draw with screen blits only when appeared (`DAT_100e01ff` bracket, `100070d0..10007108`).
    4. End frame `FUN_10030bc0`: [messages, FPS, console — none] → `flushLayers(0...1)` → terrain blit (pref 5) →
       `flushLayers(2...5)` → [particles — none] → `flushLayers(6...15)` → `limit` (pref 10) → `present(.gameScreen)` only
       when appeared.
- **Tests (7):** `testInitOps` (loadTerrain jum2, `fill(.back, 0)`, two scor loads + P1/P2 elements, terrain blit top 3120, no present) ·
  `testPassesZeroAndOneUnpresented` (`limit` but no `present`) · `testFadeAtTick2` (pass 2 begins `clearLayers`,
  `fade(.fromBlack, .gameLayout)` before the tick's updates; ends `present(.gameScreen)`) · `testSteadyPassOrder` (pass 200:
  the op-kind sequence above exactly) · `testTerrainTopPerPass` (pass t blits top 3119 − t for t ≤ 3118, then 1 forever)
  · `testEscEndsSession` · `testDeterministicReplay` (same seed + key script → identical `PassOutput`s over 400 passes;
  a different seed gives the same outputs — the one Phase-1 draw has no visible effect).
- **Gate:** G2 = **146/0**. **Commit:** `DeimosCore: DeimosSession.pass — level start + loop pass in FUN_100051a0 order (Phase-1 subset); 7 tests`.

### R1 — minor — Render buffers, CopyBits, presents, fade from black, RGBA (→ +7) — ∥ lane C after C1
- **Files:** `Package.swift` (library + target `DeimosRender`, test target `DeimosRenderTests`);
  `Sources/DeimosRender/{Pixmap555,Blend555,CopyBits,Presents,Fades,ScreenRGBA}.swift`; `Tests/DeimosRenderTests/BufferTests.swift`.
- **Contract (display-window-present §1–§5, loose-ends-session §6, blit-pixel-rules §2; HIGH):** buffers black at
  creation (`FUN_10009f00` colour 0); `CopyBits` srcCopy with `FUN_10009fd0` rect defaults (src → src bounds; dst → **src**
  bounds), the second identical CopyBits documented as a no-op; interlaced variant (`FUN_100450e0`: every other row, start
  one row lower on odd parity, parity ^= 1 per call); presents: game screen (paint (0,0,480,32) and (0,608,480,640) black;
  back (0,0,480,416) → screen (0,32,480,448); back (0,416,480,576) → screen (0,448,480,608)), game layout (back
  (0,0,480,608) → screen (0,32,480,640); screen x 0..31 untouched), full screen (1:1); `Blend555` kernel
  `⌊(A·a + B·(32 − a))/32⌋` per 5-bit channel (`FUN_1001e9d0`); fades: from black (`1000ba70..1000bbc0`: snapshot of
  back, black clone; for a = 0, 4, …, 32: back = blend(snapshot, black, a), present) (fade to black, `FUN_1000b9a0`, uses the MED
  `FUN_1001ec80` kernel and moves to R2 after its reading — review M2; `Fades` exposes the from-black half only here); `ScreenRGBA` per channel `(c<<3)|(c>>2)`, alpha 0xFF.
- **Tests (7):** `testBlendKernelFloor` (per-channel floor, no carry between fields; 0x7FFF·a 16 with 0 = 0x3DEF) ·
  `testCopyBitsRectDefaults` · `testInterlacedCopyParity` · `testGameScreenPresent` · `testGameLayoutPresent` ·
  `testFadeFromBlackSteps` (9 steps; step a = 0 is black, a = 32 equals the snapshot; mid step = ⌊c·a/32⌋) ·
  `testRGBAConversion`
  (0x4B7C → 0xFF94DEE7, 0x7FFF → 0xFFFFFFFF, 0 → 0xFF000000).
- **Gate:** G2 = previous + **7** (canonical **153**). **Commit:** `DeimosRender: RGB555 buffers, CopyBits (double/interlaced), presents, fade from black, blend kernel, RGBA; 7 tests`.

### R2 — ⚑ MAJOR — The sprite blitters + fade to black (→ +11)
- **Precondition (read Hazards):** read `FUN_1001ec80` (`COST` rect / in-place scale toward a colour) in `$LISTING` — the
  bank has only usage (hud-scorebar §5 MED) — and record its kernel and clipping; re-read the dispatcher
  `10019570..10019ab4`.
- **Files:** `Sources/DeimosRender/Blit/{SpriteBlitter,UnscaledLeaves,ScaledLeaves,CostRect}.swift`,
  `Sources/DeimosRender/FadeToBlack.swift` (extends R1's `Fades`); `Tests/DeimosRenderTests/BlitTests.swift`.
- **Contract (blit-pixel-rules §1–§5, sprite-geometry-draw §3.3; HIGH):** dispatch: alpha 32 → nothing; mode = 1 if flags
  &1, 2 if &2, 3 if &4, else 0; port = terrain if &8 else back; unscaled: left = X − w/2, top = Y − h/2 (C division);
  inside / reject / clipped classification exactly as §1.1 (strict `X + w < clipR`); map path when the frame has a map
  (all three global switches are 1 in 1.0.6); key path otherwise; per-mode per-pixel rules of §3 (mode 0 copy p 0, blend
  α = p, skip 32, ignore command alpha; mode 1 additive α = a + p, skip ≥ 32; mode 2 α = trunc(fl32(p·fl32(0.032·p) + a))
  skip ≥ 32, dst·α/32; mode 3 colour for src); 1000 = empty row (unscaled) / pixel (scaled); clipped twins = same kernel +
  per-pixel clip; scaled: W = w·s (float32), w′ = trunc(W), left = trunc(X − 0.5·W), sampling `sx = (w·(dx − left)) div w′`,
  `sy` likewise; unclipped scaled leaves (clip == {0,0,480,416}) clamp to x ∈ [0, 416), y ∈ [0, 480); other clips test per
  pixel; mode ≥ 4 → nothing. `COST` per the precondition reading. Fade to black (`FUN_1000b9a0`, moved from R1 — review
  M2): a = 32 … 0, back scaled in place toward 0 by the `FUN_1001ec80` kernel as read, present — compounding.
- **Tests (11):** `testDispatchSelection` · `testUnscaledMode0` · `testUnscaledMode1Additive` · `testMode2AlphaTables`
  (a = 20: p 1…19 → 20 20 20 20 20 21 21 22 22 23 23 24 25 26 27 28 29 30 31, p ≥ 20 skipped; a = 0: 0 0 0 0 0 1 1 2 2 3 3 4 5
  6 7 8 9 10 11 12 14 15 16 18 20 21 23 25 26 28 30; §3.1) · `testMode3Tint` · `testClippedTwinsMatchUnclipped` (randomised,
  seeded; a frame ending exactly on the clip edge takes the twin with identical pixels) · `testScaledHalfShipShadow`
  (`pl1o` frame 0 at (184, 382), scale 0.5 → 26 × 21 at left 170, top 371) · `testScaledClampVersusClip` ·
  `testCostRect` (meter darkening at blend 8; ⚑ as built + R2 spec review: the command clip only REJECTS a COST rect wholly
  outside it (`100197ac..100197c8`); `FUN_1001ec80` clips to the PORT bounds and addresses from the unclamped top/left) · `testCentreAnchorOddWidth` ·
  `testFadeToBlackCompounds` (33 steps; after step a the buffer is the product of the factors so far, per the kernel read).
- **Gate:** G2 = previous + **11** (canonical **164**). **Commit:** `DeimosRender: sprite blitters — dispatcher, 4 unscaled modes + clipped twins, 16 scaled leaves, COST, fade to black; 11 tests`.

### R3 — ⚑ MAJOR — `DeimosRenderer.apply`, render lists, level-1 frame goldens (→ +7) — needs C6 + R2
- **Files:** `Sources/DeimosRender/DeimosRenderer.swift`, `Sources/DeimosRender/RenderLists.swift`;
  `Tests/DeimosRenderTests/{RendererTests,LevelOneFrameTests}.swift`.
- **Contract:** `apply` executes every non-yield op (S3) on the persistent buffers; `.draw` with `drawNow` blits at once,
  else appends to layer `cmd.layer`'s list (`FUN_1001a450`, insertion order, lists grow); `.flushLayers(r)` draws each layer
  of r in order (`FUN_1001a650`; layers 0–1 into the terrain buffer by flag 8, their commands turned `none` after drawing);
  `.clearLayers` empties all 16; `.loadTerrain` resizes the terrain buffer to the image (480 × 3600 for `jum2`);
  `.loadImage` decodes the TGA and copies it to `dst`; `.screenBlit` back → screen. Sprite frames come from
  `DeimosAssets.spriteGroup` (cached). A test helper runs a headless session for N passes (fades applied as their 9 steps,
  `limit` ignored) and, when `DEIMOS_FRAME_DUMP` names a folder, writes `pass-NNNN.ppm` files there for reviewers (no
  framework).
- **Tests (7):** `testRenderListsOrderAndFlush` (synthetic) · `testTerrainOracle` (pass 200: every game-area screen pixel
  outside the ship, shadow and crosshair rects equals `jum2[(2919 + y)][32 + x]` at screen (32 + x, y); borders 0; top-left
  anchor: after the init ops the back buffer's (0, 0) is `jum2` (32, 3120) = 0x1040; p07) · `testScoreBarOracle` (pass 200:
  bar pixels outside the element rects equal `scor`; a score-glyph pixel with map 0 is 0x4B7C) · `testShipAndShadowOracle`
  (pass 200: ship-rect pixels with map 0 equal `pl1o` frame 0; shadow pixels with map 0 not under the ship equal
  ⌊map·20/32⌋) · `testFadeFromBlackFrames` (pass 2: 9 screens, the first all black, the last = the back buffer of pass 1 in
  game layout) · `testFrameGoldens` (FNV-1a 64 of the screen at passes 2, 56, 72, 105, 600, 3118, 3200 and of the back
  buffer at pass 0 — **self-derived** on the first green run, recorded with the HectorKit + Classics SHAs, re-derived by
  the second review leg) · `testPanAndBankGolden` (left held passes 200–240: offset reaches −32 at pass 231, frame 3 from
  pass 204; FNV golden self-derived; oracle: terrain source column = offset + 32).
- **Gate:** G2 = previous + **7** (canonical **171**). **Commit:** `DeimosRender: renderer (ops, 16 render lists, flush order); level-1 frame goldens + pixel oracles; 7 tests`.

### H1 — minor — `DeimosHost`: the driver (→ +6)
- **Files:** `Package.swift` (library + target `DeimosHost`, test target `DeimosHostTests`);
  `Sources/DeimosHost/{MacTicks,KeyTable,DeimosDriver}.swift`; `Tests/DeimosHostTests/DriverTests.swift`.
- **Contract:** `MacTicks.ticks(seconds:rate:)` = `UInt32(truncatingIfNeeded: UInt64((seconds · rate).rounded(.down)))`;
  rate `.classic` 60.15 (default, Q1) / `.osx` 60. `DeimosDriver.idle` runs the session's ops sequentially and yields where
  the original waited: **`.limit`** — continue only when `ticks ≥ lastPresent + 2` (unsigned compare), then `lastPresent
  = ticks` (`10030ce4..10030d30`; pref 10 off → no wait); **`.fade`** — `fadeBegin`; t0 = ticks; for each step: `fadeStep`
  (present), then wait until `ticks ≥ t0 + 1`, t0 = ticks (`1000bac4..1000bb78`); `fadeEnd`; **`.present`** — screen
  changed. A pass begins only after the previous pass's ops finished; keys are sampled at the pass start (begin frame).
  No catch-up: a stall yields exactly one late pass. `sessionEnded` (Esc) → ◇ a new session at sector 1 with seed =
  current ticks (the original's `srand(TickCount())`, `100057c8`) — the Phase-1 stand-in for "back to the menu".
  `KeyTable` maps `HeldKeys` through the prefs key table (P1: 0x7B left, 0x7C right, 0x7E up, 0x7D down, 0x37/0x3A/0x31
  the buttons; P2 keypad) to `PlayerInput`.
- **Tests (6):** `testTicksAtRate` (60.15: 1 s → 60, 10 s → 601, 100 s → 6015; 60: 10 s → 600) ·
  `testLimiterTwoTicksPolledEvery4ms` (fake clock: present stamps exactly 2 ticks apart over 300 passes) ·
  `testFadeYieldsNineSteps` (9 screen changes ≥ 1 tick apart, then the pass resumes) · `testNoCatchUp` (1 s stall → one
  pass) · `testEscStartsNewSession` (game time 0, fade sequence again) · `testKeyTableDefaults`.
- **Gate:** G2 = previous + **6** (canonical **177**). **Commit:** `DeimosHost: driver — Mac-tick clock (60.15 default), FPS limiter, fade yields, key table, Esc restart; 6 tests`.

### A1 — ⚑ MAJOR — App target `Deimos` on HectorShell — needs K1 on HK main, H1
- **Files:** `project.yml` (S7, merged); `Deimos/App/{DeimosMain,DeimosController,DeimosAssets+Bundle}.swift`,
  `Deimos/App/Info.plist`, `Deimos/App/AppIcon.icns`.
- **Contract:** `ShellWindowController(title: "Deimos Rising", logicalWidth: 640, logicalHeight: 480, scalingPolicy:
  .integerFit)`; window content 640k × 480k points with k the largest whole number whose rect fits the main screen's
  visible frame (min 1) — crisp (D27.3); ⌃⌘F toggles full screen (largest whole multiple, black border). A `ShellIdleTimer`
  at 1/240 s calls `driver.idle(seconds: ProcessInfo.processInfo.systemUptime, keys: view.pollKeyState())` (held codes +
  Caps Lock) and, when `screenChanged`, converts `driver.screen` into a 640×480 `ShellBitmap` (k = 1) with `ScreenRGBA`
  and presents it. `.hideCursor` honoured in the game area while the window is key (the original hid it). Menu: the app
  menu only (About hidden, Quit ⌘Q) — no game menus (the original had none in play). Info.plist: `CFBundleName`/display
  "Deimos Rising", `CFBundleShortVersionString` 1.0.6 (the replicated game, D23 practice), `CFBundleVersion` 0.1,
  `LSMinimumSystemVersion` 15.0, `NSPrincipalClass` NSApplication, `CFBundleIconFile` AppIcon. **Icon:** `AppIcon.icns` =
  the app fork's `icns 128` bytes verbatim (63,938 B, 20 elements incl. `it32` 128×128; p09) — the original's own OS X
  icon, no redraw. DEBUG-only "data missing → run tools/stage-deimos.sh" alert (design §7.7).
- **Gate:** G5 ×3. **Commit:** `Deimos app: window (integer scale), 1/240 s driver timer, RGB555 present, keys, icns 128, Info.plist; project.yml target`.
- **Seat alone:** controller structure. **Ben's:** none.

### A2 — minor — Stage script, WHAT-TO-EXPECT, the gate card
- **Files:** `tools/stage-deimos.sh`, `Deimos/WHAT-TO-EXPECT.md`.
- **Contract:** `stage-btx.sh` shape: xcodegen → Release build (`.build/xcode-deimos`) → `ditto` to
  `out/Deimos/Deimos Rising.app` → copy `Resources/Deimos/Data` (`DEIMOS_DATA` overrides) into
  `Contents/Resources/Deimos/Data` → `xattr -cr` → ad-hoc `codesign --force --deep --sign -` + verify → copy
  WHAT-TO-EXPECT → `ditto` both to `~/Desktop/` (`Deimos Rising.app`, `Deimos Rising — WHAT-TO-EXPECT.md`) unless
  `DEIMOS_STAGE_NO_DESKTOP=1`. WHAT-TO-EXPECT = what Phase 1 is and is not, the keys, the deviations (design §7 + the S2
  stubs) and the gate card below verbatim, plus every MED item C5 left open.
- **Gate:** G1 on HK main, G2 = **177/0**, G3, G5, G9. **STOP for Ben.** **Commit:** `tools/stage-deimos.sh + WHAT-TO-EXPECT (Phase 1 gate card)`.

---

## What Ben checks — the Phase 1 gate card ("does it look like Deimos")

Open `~/Desktop/Deimos Rising.app`; compare with a longplay of Mariner Valley's opening. Each line names what you'll see
and what would be wrong.
1. **The opening** — black for a moment, a quick fade up (~0.15 s) straight into the jungle map, already scrolling.
   Wrong: a pan-in, a slow fade, or the score bar fading separately from the map.
2. **The map** (sector 1, Mariner Valley, `jum2`) — scrolls down the screen 1 pixel per frame, smooth, about 30 px a
   second; nothing else on it yet (no enemies, ground objects or level-name title — Phase 2). Wrong: upside down (would
   also mean the title screen is — INDEX #10), mirrored, or the wrong speed.
3. **The frame** — 32-px black bars left and right of the playfield, the score bar on the right; a whole-number scale with
   black around it in the window and in full screen (⌃⌘F).
4. **The score bar** — `0000000` in pale cyan monospaced digits, reserve lives "2", the ship symbol, the Ion Cannon icon
   (no second/third icon — at sector 1 the Ion Cannon is the only air weapon), both meters dark; the shield meter fills
   from empty in about 1.7 s once the ship is in; Player 2's block below is drawn dimmed and never changes. Wrong: digits
   spaced unevenly (the original uses a 6-px cell even though most digits are 7 px — a quirk we copy), wrong colours.
5. **The ship** — nothing for about 1.9 s, then the orange ship fades in (~1.7 s) at the bottom-centre, with a half-size
   dark shadow down and to the left (ground under it at 62.5 % brightness). Wrong: a hard pop-in, a full-size shadow, a
   shadow on the wrong side.
6. **The crosshair** — the plasma-bomb target fades in ~121 px ahead of the ship, 0 → 100 at 6 per tick from the ship's
   first active tick (~0.6 s; loose-ends-combat §6.2, `1003b148..1003b15c`) — a quick fade, not a pop. *Its layer and whether it casts
   a shadow are read from the code in this phase (C5) — any item still MED is listed below.*
7. **Left / right** — the ship banks (3 frames each way, one step every 2 frames) and the whole map pans up to 32 px;
   **the ship itself does not move** (that is Phase 2). Up/down, fire and select do nothing yet.
8. **Colours of the sprites** (ship, shadow, HUD art) — the plates are 24-bit GIFs the game drew into 16-bit, which keeps
   the top 5 bits of each channel (MED). If the ship or HUD look a shade dark or off against the video, this is the suspect.
9. **Speed** — 30.07 frames a second (Mac OS 9's 60.15 Hz tick, Q1). If you ran it on OS X, it would be 30.00.
10. **After ~104 s** the map reaches its top and stops (the level end, tallies and next sector come with Phase 2).
11. **Keys** — Esc starts level 1 again (stand-in for the main menu); ⌘Q quits. Caps Lock, `-`/`=`, F6 and `~` do nothing yet.
12. **Silence** — no sound or music yet (Phase 2).
13. **The icon** — the original OS X icon (`icns 128`), unchanged.
Known by design: whole frames, no tearing (the original could tear); a window instead of a screen switch.

---

## Execution order

| wave | HectorKit | Classics lane A (Core) | Classics lane B (Render) | review legs (Fable) |
|---|---|---|---|---|
| 1.0 | K1 (push, pull --ff-only) | C1 | — | K1 one; C1 one |
| 1.1 | — | C2 ∥ C3 → C4 ⚑ | R1 → R2 ⚑ | C2, C3, R1 one each; C4, R2 two |
| 1.2 | — | C5 ⚑ → C6 ⚑ | — | two each |
| 1.3 | — | R3 ⚑ → H1 | — | R3 two; H1 one |
| 1.4 | — | A1 ⚑ → A2 | — | A1 two; A2 one; then Ben |

- Disjoint files: lane A touches `Sources/DeimosCore/**` + its tests; lane B owns `Package.swift` (R1) and
  `Sources/DeimosRender/**`. C2 ∥ C3 touch different files. R3 and H1 need both lanes.
- One Opus implementer per task in the lane worktree; the orchestrator merges, re-runs G1–G10 at the merge head, updates
  STATE, ends each session with a handoff + `spawn_task` chip (2–3 tasks per session, fable-kit §5).

---

## Pre-execution self-audit

1. **D27.2 coverage.** Scrolling background (C3, C6, R1, R3) ✅; ship drawn in place (C4, C5, R2, R3) ✅; HUD/score bar
   (C4, C5, R3) ✅; original frame order (C6 from the `FUN_100051a0`/`FUN_10007070`/`FUN_10030bc0` listings) ✅; 640×480
   integer scale + black border (K1, A1) ✅; staged to `~/Desktop` with WHAT-TO-EXPECT (A2) ✅; no gameplay (S2 ◇) ✅.
2. **Ladder arithmetic** from the named tests: C1 6, C2 6, C3 6, C4 8, C5 9, C6 7, R1 7, R2 11, R3 7, H1 6 = 73 →
   104 + 73 = **177** ✅; K1 landed, 316 ✅.
3. **Type names:** `HeldKeys`, `PlayerInput`, `DrawCommand`, `RenderOp`, `BufferID`, `PresentKind`, `FadeKind`,
   `PassOutput`, `SoundCue`, `MusicCue`, `ShellRequest`, `DeimosPrefs` created in C1 and used unchanged in C3–A1 ✅.
4. **Numbers re-derived by probe** (Research notes): level order and le07 header, sector-1 weapon, flli/tefo values, frame
   sizes, TGA sizes and anchor pixels, RNG values, icns ✅. Derived arithmetic (start 459, cells, shadow 184/382 →
   170/371, alpha table, fill widths) re-computed from the bank's formulas ✅. Self-derived only: FNV goldens (R3).
5. **The bank's MED items Phase 1 touches:** 24→16 (gate card 8); crosshair layer/shadow (C5 precondition → gate card 6);
   TGA orientation (gate card 2); `FUN_1001ec80` COST kernel (R2 precondition reads it). `FUN_10012750` was MED in
   player-physics §4.3; the planner read its listing (`10012750..10012838`) — the C4 contract cites it as HIGH.
6. **Risks:** RNG order (Invariant 6) ✅; D-number collision (Landmine d) ✅; slow decodes (Landmine e) ✅; the Ferazel
   overlap is the kit's K1 only ✅.

---

## Open questions for Ben (Phase 1 needs one)

- **Q1 — TickCount rate** (design §11.1): 60.15 Hz (default, classic Mac OS) or 60.00 Hz (Mac OS X)? The plan builds
  `TickRate` with both; switching is one line in A1.
Everything else the design lists (Q2–Q8) belongs to later phases.

---

## Bank corrections to append (each as a ⚑ planner-probe note in the named file; no file is edited by this plan)

1. player-physics.md §4.3: `FUN_10012750`'s step is now listing-read (`10012750..10012838`): cur > req → cur −= δ, floored
   at 0 then raised to req; cur < req → cur += δ, capped at req; the same for the glow triple `+0x58/+0x5c/+0x60`
   (MED → HIGH).
2. function-roles.md `FUN_10007070` (draw world, MED "callees"): listing `1000708c…10007108` = `FUN_100345f0` →
   `FUN_10046ae0` → `FUN_100298c0` ×2 (P1, P2) → `FUN_10007d60` → `FUN_100184b0` → (`FUN_10031ad0(0)` while game `+0x38`
   = 0) `FUN_10031ae0` (→ `FUN_10031ad0(1)`) (MED → HIGH).
3. loose-ends-session.md §6: `FUN_1000ba70`'s wait is "t0 = TickCount before the loop; after each present spin until
   TickCount ≥ t0 + 1, then t0 = TickCount" (`1000bac4`, `1000bb50..1000bb78`).

---

## Research notes (planner probes, 2026-10-06, `$SCRATCH/probes/{pak,tga,frames}.py` over the committed data; not committed)

- **p01** `leve/Level 07[le07].leve`: name Mariner Valley, identifier Lucena, map `jum2`, preview `jup2`, music `mu03`, mask
  `jut2`, rect <0, 0, 480, 3600>, 38 objects of 11 units (01b1 01m1 bsat bsgr bu01 gebd geys grob plla sels tapu), max
  yLoc < 3056.
- **p02** `wede`: `aiic` PEAA levels 1–3, faces `pl1o`/`pl2o`, preview `wesy` 0; `aibg` 2–9999 (`wesy` 1), `airg` 3–9999
  (3), `aipb` 5–9999 (2); `plbo` PEAG, crosshair `pbta` 0 / locked 1, offset (0, −121).
- **p03** `plde pl01`: spriteScoreBar `play` 0, power `shme` 1, shield `shme` 0, defaultShield 100, lives 3, solo start
  (208, 330), InitialDelay 55, Invulnerability 60, entry spawn `plen`, money counter `p1mc`.
- **p04** `flli gafl` (220): 18 = 2, 32 = 30, 33 = 2, 48/49 = −48/104, 50/51 = −6/8, 52–60 = 640 480 416 480 16 160 480 32
  32, 112–143 as hud-scorebar (534/41, 495/124, 2, 3, 495/159, 2, 4, 467/199, 502/199, 16, 6, 0.7, 9), 149/150 = 6/6,
  163–166 = 0/100/2/1, 183 = 13, 185–187 = 3/−4/80.
- **p05** `tefo`: gate order 41 sbsh, 42 sbpm, 43 sbs1 (494, 83, CENT, mono, spacing 4, colourise 94dee6, blend 0), 44 sbs2
  (494, 318), 45 sbl1 (499, 50, spacing 0), 46 sbl2 (498, 285), 47/48 sll1/sll2 (ff0000); sbsh/sbpm strip blend 8 colour
  000000. 0x94dee6 → RGB555 0x4B7C; 0xff0000 → 0x7C00.
- **p06** frame sizes (RGB plate scan; Phase 0's 8-bit scan agrees except `GLOW`): `pl1o` 7 × 53×43; `pbta` 14×13, 14×13,
  12×13; `play` 2 × 38×38; `shme` 2 × 96×13; `wesy` 6 × 26×26; `tesm` 91 frames, 52–61 widths 5 6 7 7 7 7 6 7 7 7 (h 13),
  90 = 4×13.
- **p07** TGA (descriptor bit 5 honoured): `jum2` 480×3600, top-down (32, 3120) = 0x1040, (447, 3599) = 0x22C4, (0, 0) =
  0x314A; `scor` 160×480, (0, 0) = 0x0021; `jut2` 96×720.
- **p08** MSL rand: srand(1) → 16838, 5758, 10113; srand(0x469c2) → 26662, 28174, 2951 and R(400, 2000) = 1446; float32
  RandomRange, each after a fresh srand(1): (1, 2) 1.5138707, (2, 1) 0.48612934, (0.8, 1.2) 1.0055482; sequential after one srand(1): 1.5138707, 0.8242744, 0.9234535 (review I3).
- **p09** `Deimos Rising.rsrc` `icns 128`: 63,938 B, elements ICN# icl4 icl8 il32 l8mk ich# ich4 ich8 ih32 h8mk ics# ics4
  ics8 is32 s8mk icm# icm4 icm8 it32 t8mk; `sips` reads it as 128 px.
- **p10** listing reads: `FUN_10007070` order (Bank corrections 2); `FUN_1000ba70` (Bank corrections 3); `FUN_10012750`
  (Bank corrections 1); `FUN_1003bd00` = `if (handler+0x120) FUN_10012f20(handler+0x8c)`.
- **Derived (bank formulas):** score start fctiwz(494 − 35.0) = 459, cells 463 + 10i; P1 lives start fctiwz(499 − 3.0) = 496;
  P2 lives 495; ship rect 182..234 × 309..351; shadow centre (184, 382), scaled 26×21 at (170, 371); crosshair centre
  (208, 209); level end at game time 3118 (scroll tick 3119, top 1); first ship pass t = 56, opaque t = 105; crosshair
  opaque t = 72; shield meter full t = 105.
