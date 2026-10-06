# Bubble Trouble X on Windows — plan (contracts, not code)

> **For agentic workers:** use superpowers:subagent-driven-development. One Opus implementer + one Opus reviewer
> per task (two review legs on ⚑ MAJOR). Contracts, not code (Ben's rule): each task names the API, the files, the
> acceptance bar and the tests; the implementer writes the code TDD.

**Goal:** a Windows build of Bubble Trouble X — a plain folder (`.exe` + DLLs + `Data/`) that plays the game exactly as
the Mac replica does, cross-compiled on this Mac and smoke-tested in CrossOver.

**Rulings (Ben, 2026-10-06 — DECISIONS D15):** BTX first · cross-compile on the Mac (open-source Swift toolchain +
Swift's Windows SDK + Microsoft's SDK/CRT via `xwin`, licence accepted by Ben) and test in CrossOver; Windows PC is the
fallback only if W0 fails · the Mac UI (menu bar, Carbon dialogs) is **drawn in-window**, Ctrl for ⌘ · original data
**bundled** beside the `.exe` (D10) · **the Mac app is not touched**: Windows gets its own port of the controller
logic in a new package; shared pieces are added as NEW files only (HectorKit `HectorAudio`, `HectorSDL`).

**Architecture.**
- `BubbleTroubleCore` / `BubbleTroubleRender` (existing, Foundation-only, unchanged) compile for Windows as-is.
- HectorKit (engine): `HectorAudio.PCMMixer` — Foundation-only software mixer, same surface as `ShellMixer`;
  `HectorKit/SDL/` — a SEPARATE SwiftPM package (main package stays zero-dependency) with `CSDL3` (C module for SDL3)
  and `HectorSDL` (window + scaled present of an RGBA buffer, keyboard/mouse events mapped to Mac virtual keycodes,
  monotonic clock, audio stream pulling `PCMMixer`). Builds on macOS too (brew `sdl3`) so the Windows app runs on the
  Mac for development.
- Classics: `BubbleTroubleX/Windows/` — a SwiftPM package: `BTXWinKit` (Foundation-only library: the controller port
  `WinGameDriver`, `BitmapFontRasterizer`, the in-window menu bar and dialogs, all drawing into RGBA buffers — fully
  `swift test`-able on the Mac) + `BubbleTroubleXWin` (thin executable: SDL glue only).
- Tools: `tools/windows/` — toolchain setup, cross-build, CrossOver run, stage.

**Never:** edit `BubbleTroubleX/App/*`, `project.yml`, `BubbleTrouble/Core/Sources/**` (a core change needs a ruling),
or `HectorShell`. No installers, signing, publishing. No real-time audio from automated runs (CoreAudio wedged once;
SDL/Wine audio also lands on CoreAudio): every automated SDL run sets `SDL_AUDIO_DRIVER=dummy`; real sound is Ben's ear.

**Mac gates (green after EVERY task):** HectorKit `HECTORKIT_TEST_LOG=<log> tools/check-zero-skip.sh` PASS at the
current floor (222 at start; each HectorKit task raises it by its new tests); BTX core `swift test` with
`HECTORKIT_DATA_BTX` = 258 / 0 / 0; `cd Aki/Core && swift test` green; `xcodegen generate && xcodebuild -scheme
BubbleTroubleX build` and `-scheme Aki build` BUILD SUCCEEDED, 0 warnings in our code.

---

## W0 ⚑ MAJOR — Toolchain proof: Swift → Windows from this Mac, run in CrossOver

**Files:** `tools/windows/setup-toolchain.sh`, `tools/windows/env.sh`, `tools/windows/build.sh`,
`tools/windows/run-in-crossover.sh`, `tools/windows/README.md`, `tools/windows/hello/` (a tiny SwiftPM package).
HectorKit: portability guards only (see 4).

**Contract.**
1. `setup-toolchain.sh` is idempotent and caches everything under `~/Developer/Toolchains/windows-cross/` (outside
   git): an open-source Swift toolchain for macOS whose compiler version **exactly matches** the Windows SDK it
   targets (the Xcode toolchain cannot load SDK modules from another compiler build); the Swift Windows SDK for
   **x86_64** (from swift.org's Windows release — extracted, not installed); the MSVC CRT + Windows SDK sysroot via
   `xwin --accept-license splat` (Ben accepted, D15); SDL3's official Windows VC dev zip (libsdl-org GitHub release).
   It prints each pinned version + SHA-256. Downloads only from swift.org, github.com/swiftlang, github.com/libsdl-org,
   github.com/Jake-Shadle/xwin (or crates.io), Microsoft's servers via xwin.
2. `build.sh <package-dir> <product> [--tests]` cross-builds a SwiftPM package for `x86_64-unknown-windows-msvc`
   (SwiftPM `--swift-sdk`/toolset JSON preferred; whatever works, documented in README with why).
3. `run-in-crossover.sh <exe> [args]` runs it in a dedicated CrossOver bottle (`hector-win`, Windows 10 64-bit,
   created on first use, command-line only), with the Swift runtime DLLs (+ ICU, Foundation, dispatch, vcruntime) on
   the path, returning the exe's exit code and stdout.
4. **Proof A:** `tools/windows/hello` prints `Date()`, `String(format:)`, a `FileManager` listing, a
   `UserDefaults` round-trip, a `Mutex` from Synchronization → runs in CrossOver, exit 0, expected lines.
   **Proof B (the real one):** cross-build `BubbleTrouble/Core` **with tests** and run the XCTest bundle in CrossOver
   with `HECTORKIT_DATA_BTX` pointing at the data (a Windows path to the same folder): **258 / 0 failed / 0 skipped**
   (or every difference explained). Any HectorKit file that blocks compilation gets a portability guard ONLY —
   expected: `HectorGraphics/CodecImage.swift` (`#if canImport(ImageIO)`; on Windows `decode` throws
   `unsupported`), `HectorGraphics/Ditl.swift` (`import CoreGraphics` → `#if canImport(CoreGraphics)`, Foundation
   provides `CGRect`). Mac behaviour byte-identical; HectorKit floor unchanged.
**Stop rule:** if Proof A cannot run after an honest attempt, STOP and report BLOCKED with the exact failing step;
the seat asks Ben about the Windows-PC fallback. Do not hack around a compiler-version mismatch.
**Report:** versions pinned, total download size, exact commands, Proof A output, Proof B counts.

## W0.5 ⚑ MAJOR — Windows parity fixes (from W0 Proof B; rulings D16)

**Files:** HectorKit `Sources/HectorResources/MacRoman.swift` (+ every `.macOSRoman` call site in HectorResources),
`Sources/HectorGraphics/CodecImage.swift` (precomputed table), tests; Classics core: the four `.macOSRoman` sites
(`BTXPrefs.swift:195,199`, `BTXGameData.swift:120`, `LettersFont.swift:66`), `BTXPrefsStore.swift` (additive
backing protocol), tests; `BubbleTroubleX/Windows/Sources/btx-predecode/` (Mac-only tool).
**Contract.** (1) `MacRoman` — a hard-coded 256-entry table, `decode([UInt8]) -> String`, `encode(String, lossy:) ->
[UInt8]?`; every HectorKit and core `.macOSRoman` use goes through it; Mac output byte-identical (test: all 256 bytes
equal Foundation's `.macOSRoman` on the Mac, round-trip). (2) `CodecImage` off Apple looks up a precomputed RGBA8
result keyed by (length, FNV-1a 64 of the bytes) registered via `CodecImage.registerPrecomputed(directory:)`; on
Apple it is never consulted. `btx-predecode` (Mac) decodes every QuickTime-JPEG PICT the BTX data carries through
the real `CodecImage` and writes `<key>.rgba` files (header: w, h) — staged into `Data/Decoded/`. (3)
`BTXPrefsStore` gains `protocol BTXPrefsBacking { data(forKey:), set(_ Data, forKey:), removeObject(forKey:) }`,
`UserDefaults` conforms by extension, the existing `init(defaults: UserDefaults, …)` stays (Mac app unchanged), a new
`init(backing:…)`; Windows will pass a file-backed store (W4).
**Acceptance:** Mac gates green and unchanged counts + new tests; Proof B re-run in CrossOver → **258 / 0 / 0**
(with `Data/Decoded` registered by the test harness off Apple).

## W1 — `HectorAudio.PCMMixer` (HectorKit)

**Files:** `Sources/HectorAudio/PCMMixer.swift`, `Tests/HectorAudioTests/PCMMixerTests.swift`, a Mac-only oracle
test comparing against `ShellMixer` (new test target or in `HectorShellTests`; offline render only — never a device).

**Contract.** `public final class PCMMixer: @unchecked Sendable` — `init(voices: Int, outputRate: Double)`;
`load(id:samples:channels:sampleRate:)`, `isLoaded(_:)`, `play(id:on:volume:loops:)`, `stop(voice:)`, `stopAll()`,
`pause(voice:)`, `resume(voice:)`, `pauseAll()`, `resumeAll()`, `isPlaying(voice:)`, `setVolume(voice:_:)` —
identical semantics to `ShellMixer` (HectorKit d9fdfa4: linear interpolation at a fractional source position in render — as-built, ShellMixer does not resample at load — seamless loops by in-render linear
interpolation, volume law `min(max(v/256,0),1)` (BTX applies its own Sound Tool scaling before calling — D14),
setVolume from the next sample). `render(into: UnsafeMutableBufferPointer<Float>, frames: Int)` writes interleaved
stereo Float32 at `outputRate`; called from the audio thread, everything else from the main thread — guarded by a
`Mutex` (Synchronization), never allocating or freeing on the render path.
**Tests:** silence when idle; a loaded mono 22050 Hz ramp plays resampled to 48 kHz; loops N times then
`isPlaying` false; stop/pause/resume/setVolume mid-buffer; **oracle:** for a scripted sequence of calls, `PCMMixer`
output equals `ShellMixer`'s offline render within 1e-5 per sample.

## W2 — Bitmap font: bake on the Mac, draw anywhere

**Files:** `BubbleTroubleX/Windows/Package.swift` (created here: `BTXWinKit` library + test target; depends on
`../../BubbleTrouble/Core` and HectorKit by path, following the core package's path convention),
`BubbleTroubleX/Windows/Sources/BTXWinKit/BitmapFontRasterizer.swift`,
`BubbleTroubleX/Windows/Sources/btx-bake-font/` (Mac-only executable, `#if canImport(CoreText)`),
`BubbleTroubleX/Windows/Resources/Fonts/*.btxfont` (committed), tests.

**Contract.** The baker renders every MacRoman printable character (0x20–0xFF) for each face the game and the
in-window chrome use — `Geneva 9`, `System 12` (as `CoreTextRasterizer` resolves "System"), plus the faces W5/W6
need (`System 12` bold if the menu/dialog chrome uses it) — with the SAME CoreText path as
`BubbleTroubleX/App/CoreTextRasterizer.swift` (read it; do not edit it), storing per glyph: 8-bit coverage bitmap,
origin offset, advance; plus ascent/descent. Format: small documented binary (`BTXF` magic, version, little-endian).
`BitmapFontRasterizer: TextRasterizer` loads them and implements `rasterize`/`width` with the same blending rule
(coverage toward `rgb`, every touched pixel opaque).
**Tests:** width of the info-box and FPS strings equals `CoreTextRasterizer`'s within 1 px (Mac-only test, CoreText
oracle re-derived in the test target); a rendered string's pixels differ from the CoreText render in ≤ 2 % of touched
pixels (whole-string kerning is the only allowed source); unknown character → advance of `?`.

## W3 ⚑ MAJOR — `HectorSDL` (HectorKit/SDL package)

**Files:** `HectorKit/SDL/Package.swift`, `Sources/CSDL3/` (module map + shim header; macOS: brew `sdl3` via
pkg-config; Windows: header/lib paths from `tools/windows/env.sh` in Classics — document the flags in the package
README), `Sources/HectorSDL/{SDLHost,SDLKeymap,SDLAudioOut,SDLClock}.swift`, `Sources/hector-sdl-smoke/`, tests.

**Contract.** `SDLHost(title:logicalWidth:logicalHeight:scale:)` opens a window, `present(rgba: [UInt8])` uploads
one streaming texture and renders it nearest-neighbour at an integer scale (the HectorShell D7 integer-fit rule);
`pollEvents() -> [HostEvent]` maps SDL key events to **Mac virtual keycodes** (the table `ShellKeyState` uses: arrows,
space, return, esc, Caps Lock 0x39, letters, digits, Cmd → **Ctrl**), mouse down/up/move in logical coordinates,
quit, focus lost/gained; `SDLClock.now` monotonic seconds; `SDLAudioOut(mixer: PCMMixer)` opens a 48 kHz stereo
float stream whose callback calls `mixer.render`. `hector-sdl-smoke --frames N --dump <file.ppm>` draws a test
pattern, runs N frames with `SDL_AUDIO_DRIVER=dummy` and writes the last presented buffer.
**Tests:** keymap table; the smoke on the Mac (`SDL_VIDEO_DRIVER=dummy` or offscreen) and **cross-built and run in
CrossOver**, dump byte-identical to the expected pattern.

## W4 ⚑ MAJOR — `WinGameDriver` + `BubbleTroubleXWin`: playable on Windows

**Files:** `BTXWinKit/{WinGameDriver,WinHost,WinAudio,WinInput}.swift`, `Sources/BubbleTroubleXWin/main.swift`,
tests.

**Contract.** Port — do not import — `BubbleTroubleX/App/BTXController.swift` and `BTXAudio.swift` (read them in
full; they are the spec): data load from `Data/` beside the exe (or `--data <dir>`), the three clocks (TickCount
1/60 s, Carbon frame 0.033 s, the frame-limit cheat's 0.001 s) — exactly one runs, missed fires dropped; wipes,
`displayFade`, cursor requests, `enableMenus`/`disableAbout` (recorded for W5), `beep`, `haltAllSound`,
`savePrefs` (`BTXPrefsStore` with `UserDefaults.standard`; legacy file nil), quit rules (`quitNow` no save, pause
quit saves, front-end quit saves, Ctrl+Q injected as ⌘+0x0C), all the BTX cue → voice logic over a
`PCMMixer`-backed `BTXAudioOutput`-shaped protocol (4 effect voices + 1 music voice, D14 volume law). Dialog requests
are answered by a `WinDialogs` protocol whose W4 stub returns defaults (Cancel / prefs unchanged / default name) —
W6 replaces it. `WinHost` protocol = present, events, clock, cursor, quit; `BubbleTroubleXWin` implements it with
`HectorSDL`, canvas 640×480 under a 20 px reserved menu strip (blank until W5). Debug flags: `--frames N --dump f.ppm`,
`--keys <script>` (timed key presses) for headless smokes.
**Tests (Mac, headless, real data):** the driver with a scripted host runs splash → main menu → attract demo 1;
the demo's game-state trace equals `btx-replay`'s for FILM 1 (the existing baseline); frame dumps at fixed ticks are
stable. **CrossOver:** the cross-built exe with `--frames 600 --dump` reaches the main menu; dump equals the Mac SDL
build's dump at the same tick. **Seat:** plays it on the Mac SDL build and screenshots it; then Ben.

## W5 — In-window menu bar

**Files:** `BTXWinKit/{MenuModel,MenuBarView}.swift`, tests.
**Contract.** The menus and items of `BubbleTroubleX/App/BTXMenus.swift` (read it; transcribe titles, order,
separators, enable rules, key equivalents → Ctrl), minus macOS-only items (Services, Hide/Show All, Window's
system items — listed in the report). Drawn in the 20 px strip above the canvas in the Mac replica's light menu-bar
look, `System 12` from W2; press-drag-release tracking; Ctrl shortcuts; enabled state from `enableMenus` /
`disableAbout`; choosing an item does exactly what the Mac item's action does (driver entry points).
**Tests:** model transcription table; hit-testing; tracking state machine; disabled items inert; golden PNG of the
open Options menu, shown to Ben with the W7 build.

## W6 ⚑ MAJOR — In-window dialogs (DLOG/DITL)

**Files:** `BTXWinKit/{DialogRenderer,DialogController,WinPrefsDialog}.swift`, tests.
**Contract.** `WinDialogs` real implementation drawing every dialog of `BubbleTroubleX/App/BTXDialogs.swift`'s table
(DLOG 160, 190 + 200, 290/291, 1000, 1001, 3000/3001, every reachable ALRT) modally over the canvas, centred, from
the original `DLOG`/`DITL` via `HectorGraphics.Ditl`: push buttons (default ring), static text with `^0` params,
edit text (caret, typing, backspace, Return/Enter = default, Esc = Cancel, `_HiScoreNameFilter` rules), checkboxes,
radios, the prefs dialog's controls as `BTXPrefsWindow.swift` behaves (read it). Behaviour per the Mac files; looks
in the Mac replica's style. Answers go to the same `FrontEnd` calls the Mac uses.
**Tests:** per dialog: layout from DITL, keyboard + mouse answering, `^0` substitution, name filter, prefs
round-trip; goldens for DLOG 1000 and 190.

## W7 — Stage for Ben

**Files:** `tools/windows/stage-btx.sh`, `docs/bubble-trouble/WINDOWS-WHAT-TO-EXPECT.md`.
**Contract.** Release cross-build → `out/Windows/Bubble Trouble X/` = `Bubble Trouble X.exe`, every DLL it needs
(found by walking imports from the exe in a clean CrossOver bottle, not by guess), `Data/` (the five `.rsrc` files +
fonts), `WHAT-TO-EXPECT.txt`; copied to `~/Desktop/Bubble Trouble X (Windows)/` + a `.zip`. No installer, no signing.
**Acceptance:** runs from a FRESH CrossOver bottle (no Swift toolchain on its path) to the main menu and through a
scripted game start (dump + seat screenshot); Mac gates green.

## Ben's gates
W4: the Mac SDL build or CrossOver — "it's Bubble Trouble on Windows". W7: the zip on a real Windows PC (his
brother's), sound by ear, menus and dialogs by eye.

## Orchestration notes
- HectorKit tasks (W0 guards, W1, W3) land on HectorKit `main` as soon as reviewed (Classics' path dependency sees
  main). Check `git worktree list` in HectorKit before each — the Aki remaster lane has a `remaster` worktree.
- W1 and W2 are Mac-only and run in parallel with W0. W3 needs W0 + W1; W4 needs W2 + W3; W5/W6 parallel after W4.
- Seat may settle alone: font metric differences ≤ the W2 bar; macOS-only menu items omitted; build-script shape.
  Ben's: anything that changes how the game plays or looks vs the Mac replica; a Windows-PC fallback.
