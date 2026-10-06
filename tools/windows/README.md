# tools/windows — Swift → Windows x86_64 from this Mac, tested in CrossOver

Plan: `docs/plans/2026-10-06-btx-windows.md` (W0). Rulings: DECISIONS D15. Nothing here installs anything
into the system; everything big is cached in `~/Developer/Toolchains/windows-cross/` (outside git, ~12 GB on
disk). The two exceptions are listed under "What it writes where" below.

```sh
tools/windows/setup-toolchain.sh                     # idempotent; first run ~4.2 GB of downloads
tools/windows/build.sh tools/windows/hello hello     # → …/windows-cross/build/hello/x86_64-unknown-windows-msvc/debug/hello.exe
HECTOR_SDL_AUDIO_DRIVER=dummy HECTOR_SDL_VIDEO_DRIVER=dummy tools/windows/run-in-crossover.sh <that exe> --skip-userdefaults
HECTORKIT_DIR=<HectorKit checkout with the W0 guards> tools/windows/proof-b.sh
```

| Script | Does |
|---|---|
| `env.sh` | Pins + paths (sourced by the others). `win_path` maps a Mac path to `Z:\…` |
| `setup-toolchain.sh` | Fetches, verifies (SHA-256) and extracts everything below; writes the Swift SDK bundle |
| `build.sh <pkg> <product\|all> [--tests] [--release] [--sdl] [-- args]` | SwiftPM cross-build; test bundles are copied to `…PackageTests.exe`. `--sdl` writes a Windows `sdl3.pc` for the SDL3 VC zip. The Mac's pkg-config/brew search paths are always hidden (shims on `PATH`), so an SDL package built without `--sdl` fails loudly (`'SDL3/SDL.h' file not found`) rather than reaching brew's Mac SDL. `WIN_SWIFT_FLAGS` is appended to **every** build that inherits it (proof-b unsets it); prefer `-- …` for one build |
| `run-in-crossover.sh <exe> [args]` | Runs in bottle `hector-win` (win10_64, created on first use, crash dialog off), DLLs via `WINEPATH`, exit code passed through **truncated to 8 bits** (see below), watchdog `WIN_RUN_TIMEOUT` (default 900 s). **Refuses to run (exit 64) unless `HECTOR_SDL_AUDIO_DRIVER` is set** — see "SDL drivers under CrossOver" |
| `proof-b.sh` | Copies `BubbleTrouble/Core` (laid out like the repo; its sources unmodified, but the copy's test-only `PNGWriter.swift` is patched — see the end of this file) + a symlinked HectorKit, cross-builds the tests, runs each test class in CrossOver, tallies verdicts; exits 1 if `--list-tests` finds no tests |
| `hello/` | Proof A package |
| `btx-predecode` (`BubbleTroubleX/Windows`, Mac-only) | Decodes BTX's QuickTime-JPEG PICT bands with ImageIO into `<key>.rgba` files (D16.1); `proof-b.sh` runs it first into `$WIN_CROSS/work/proof-b/decoded` |
| `HECTORKIT_DECODED_DIR` (env) | Off Apple, the core's data-gated render/census tests register this directory of `.rgba` files once (`CodecImage.registerPrecomputed`); unset there → XCTSkip. Ignored on the Mac |

## Pinned versions (2026-10-06)

| Piece | Version | Source | SHA-256 |
|---|---|---|---|
| Swift toolchain, macOS host (open source) | 6.4.0-RELEASE (`swift-6.4-RELEASE`) | download.swift.org `swift-6.4.0-RELEASE-osx.pkg` (1.59 GB) | `8fd03185b98fe27f54a54631c2449decf75d5b466ce8e34abbd414141063c6aa` |
| Swift Windows SDK + runtime | 6.4.0-RELEASE | download.swift.org `swift-6.4.0-RELEASE-windows10.exe` (2.10 GB) | `76169a85bcba82854a0cd8f9655ffb74b3758d60c35a245457510095f2823c03` |
| MSVC CRT | 14.44.17.14 | xwin 0.10.0 (brew) — Microsoft licence accepted by Ben, D15 | per-file, xwin manifest |
| Windows SDK | 10.0.26100 | xwin 0.10.0 | per-file, xwin manifest |
| UCRT headers + libs | 10.0.26100 (the SDK's own UCRT msi + 11 cabs, 112 MB) | Microsoft, URLs + SHA-256 from xwin's cached VS manifest | verified against the manifest |
| SDL3 | 3.4.16 (= brew `sdl3` on the Mac) | github.com/libsdl-org `SDL3-devel-3.4.16-VC.zip` (17 MB) | `1a784cb2a5c64d56fe7a62090fe9d242d9865f235e4ea9678f1a6ba4e693e7de` |
| CrossOver | /Applications/CrossOver.app (installed) | — | — |

Total download ≈ 4.2 GB, decimal units, measured from the cache 2026-10-06: swift.org 3.69 GB
(3,688,745,265 bytes = 3.44 GiB), xwin 0.42 GB, UCRT 0.11 GB, SDL 17 MB. (`du -sh downloads` prints `3.6G`:
that is GiB and includes the UCRT and SDL files.) The Xcode Swift
(`swiftlang-6.4.0.27.1`) cannot be used: its module format does not load swift.org's Windows SDK modules.

## What it writes where

- `$WIN_CROSS` (`~/Developer/Toolchains/windows-cross/`): every download, extraction, the Swift SDK bundle,
  build products (`build/`, `work/`). Deleting it undoes everything except the Homebrew and bottle items below.
- **Homebrew (opt-in only):** `setup-toolchain.sh` needs `7z`, `msiextract` and `xwin` on `PATH`. If one is
  missing it stops and names the formula (`sevenzip`, `msitools`, `xwin`); with `WIN_SETUP_BREW=1` it runs
  `brew install` itself instead, which writes into Homebrew's prefix, outside the cache.
- **CrossOver bottle:** `run-in-crossover.sh` creates `~/Library/Application Support/CrossOver/Bottles/hector-win`
  on first use (and sets one registry value in it: crash dialog off). Nothing else is installed into it.
- Nothing is written to the repo (`proof-b.sh` works on a copy under `$WIN_CROSS/work/`).

## Trust boundaries

- swift.org and SDL downloads are checked against SHA-256 digests pinned in `setup-toolchain.sh`.
- The MSVC CRT / Windows SDK (xwin) and the UCRT msi + cabs are **not** pinned by us: they are verified against
  the SHA-256 values in Microsoft's VS package manifest, which xwin fetches over HTTPS and caches
  (`xwin-cache/dl/pkg_manifest_*.vsman`). So their integrity rests on TLS to Microsoft and on xwin itself; a
  changed manifest would be accepted silently. Pinning the manifest's own digest would close that (not done).

## Exit codes under Wine

`run-in-crossover.sh` passes the program's exit status through as a Unix status, which is 8 bits: a Windows
exit code is reported modulo 256 (e.g. `0xC0000005` access violation → 5, 256 → 0). Treat only 0 as success and
read the log for crashes; a non-zero code's exact value is not reliable. 124 = the watchdog fired.

## How it fits together (and why)

- **Toolchain.** The `.pkg` is unpacked with `pkgutil --expand-full`; its `Payload` *is* the `.xctoolchain`.
  It ships `lld-link`, used via `-use-ld=lld`.
- **Windows SDK.** The Windows installer is a WiX burn bundle. `setup-toolchain.sh` reads the burn manifest
  from the UX cabinet, carves the attached container (the cabinet whose header size matches the manifest),
  pulls `windows.msi` + its cabs (all three `sdk.windows.*.cab` are needed or msiextract stops early) and
  `rtl.amd64.msi`, and `msiextract`s them: `Windows.platform/` (Windows.sdk, XCTest-6.4.0, Testing-6.4.0) and
  `runtime-x64/` (swiftCore, Foundation*, `_FoundationICU`, dispatch, BlocksRuntime, vcruntime140, msvcp140…).
- **UCRT fix-up.** xwin's UCRT package is the old 10.0.10240 header set (no `corecrt_math.h` — it is folded
  into `math.h` there), and Swift's `ucrt.modulemap` needs `corecrt_math.h`. The setup therefore swaps in
  the UCRT from the *same* Windows SDK 10.0.26100 (the SDK package's own "Universal CRT Headers Libraries and
  Sources" msi), headers and x64 libs.
- **xwin layout.** `--use-winsysroot-style --preserve-ms-arch-notation` gives a real-Windows layout, so the
  driver's own `-windows-sdk-root/-windows-sdk-version/-visualc-tools-root/-visualc-tools-version` work: it
  builds the ucrt/WinSDK/vcruntime module-map VFS overlay itself. Import-library dirs go to lld-link via `-L`.
  (Re-splatting needs a fresh `xwin-cache/unpack`: splat *moves* files out of it — the script deletes it.)
- **SwiftPM.** A Swift SDK artifact bundle (`swift-sdks/windows-x86_64.artifactbundle`, `--swift-sdks-path`,
  `--swift-sdk x86_64-unknown-windows-msvc`) with a toolset JSON carrying the flags above. Two traps:
  bare `--triple/--sdk` makes SwiftPM add host flags (`-Xcc -fPIC`, macOS `-F` paths) that clang rejects for
  msvc; and SwiftPM 6.4's default build system (swift-build) says `unable to find platform for 'windows'`, so
  `build.sh` passes `--build-system native` (deprecated warning, works).
- **CrossOver.** `wine --bottle hector-win --cx-app <Z:\ path>`; Wine maps `/` to `Z:`. Environment variables
  pass through (`HECTORKIT_DATA_BTX="Z:\…"`) — **except `SDL_*`, which CrossOver strips** (next section). Wine
  intercepts some argument spellings (`--help`) before the program sees them. Output lines end in CRLF.

## SDL drivers under CrossOver

CrossOver's wine launcher **strips every `SDL_*` environment variable** (measured 2026-10-06:
`SDL_VIDEO_DRIVER=dummy` never reaches the program, an unrelated `FOO=bar` does). So `SDL_AUDIO_DRIVER=dummy`
does nothing under CrossOver, and an automated run would open the real audio device. HectorSDL reads
`HECTOR_SDL_AUDIO_DRIVER` / `HECTOR_SDL_VIDEO_DRIVER` instead (`SDLHost.applyDriverOverridesFromEnvironment`,
applied as overriding SDL hints; the test bundle also forces `dummy` in-process).

- **Automation (every scripted run):** `HECTOR_SDL_AUDIO_DRIVER=dummy HECTOR_SDL_VIDEO_DRIVER=dummy`.
- **A human playing with sound:** name SDL's Windows audio driver, `HECTOR_SDL_AUDIO_DRIVER=wasapi` (or
  `directsound`). There is no `default` value — an unknown driver name makes SDL's audio init fail.

`run-in-crossover.sh` exits 64 unless `HECTOR_SDL_AUDIO_DRIVER` is set (to anything non-empty), for every
program — non-SDL ones too — so no run reaches a real device by forgetting it. `proof-b.sh` exports `dummy`.

## The game: `BubbleTroubleXWin` (W4)

`BubbleTroubleX/Windows` product `BubbleTroubleXWin` — `WinGameDriver` (BTXWinKit, the port of the Mac
`BTXController` + `BTXAudio`) on HectorSDL. It loads `Data/` beside the `.exe` (or `--data DIR`): the five
`.rsrc` files, `Fonts/*.btxfont` (copied from `BubbleTroubleX/Windows/Resources/Fonts`) and, for Windows,
`Decoded/*.rgba` (`btx-predecode <BTX Contents/Resources> Data/Decoded`). Prefs: `%APPDATA%\Ambrosia
Classics\Bubble Trouble X\Prefs.bin` (Mac SDL build: `~/Library/Application Support/Ambrosia Classics/Bubble
Trouble X (SDL)/Prefs.bin`; `--prefs FILE` overrides) — never `UserDefaults`, never the Mac app's domain.

```sh
tools/windows/build.sh BubbleTroubleX/Windows BubbleTroubleXWin --sdl
HECTOR_SDL_AUDIO_DRIVER=dummy HECTOR_SDL_VIDEO_DRIVER=dummy tools/windows/run-in-crossover.sh \
  <build>/BubbleTroubleXWin.exe --data 'Z:\…\Data' --frames 600 --dump 'Z:\…\win.ppm'
# Mac SDL build (same flags; the dump must be byte-identical — cmp):
SDL_AUDIO_DRIVER=dummy SDL_VIDEO_DRIVER=dummy swift run --package-path BubbleTroubleX/Windows \
  BubbleTroubleXWin --data <Data> --frames 600 --dump mac.ppm
```

**Window (W4.5):** the in-window menu bar in the 20 px strip, the original dialogs drawn over the game (DLOG/DITL),
the About panel; resizable, opening at the largest integer scale whose window fits the screen's usable area
(`--scale N` overrides); Options ▸ Full Screen (Ctrl+F, saved in the prefs and restored at launch) hides the strip
and integer-fits the game screen on black; Window ▸ Minimize and Zoom are disabled, as on the Mac (its window is
titled only). While the window is dragged or resized (Windows' modal move/size loop blocks the event poll) the game
keeps its clocks and picture through HectorSDL's live-redraw handler (`WinGameDriver.liveStep`). The loop sleeps
until the next timer is due (`SDLClock.sleepPrecise`). Layout-aware text (SDL text
input, AltGr) while a dialog's edit field has the focus. `--auto-dialogs` answers every dialog at once with its
default instead (the old W4 behaviour).

**Window scale on a 1080p Windows 11 screen:** the initial scale stays integer-fit (HectorShell D7), so 2× (1280×1000
plus the title bar) does not fit above the taskbar and the window opens at 1× — Full Screen (Ctrl+F) gives 2×.

**Headless smoke mode** (`--frames N`): N main-loop iterations on a fixed-step clock (one TickCount, 1/60 s,
each), then the last presented canvas (640×500; 640×480 in full screen) → `--dump` (binary PPM) and exit 0. It forces SDL's `dummy` audio
driver in-process, keeps prefs in memory (unless `--prefs`), uses the name "Player" and 3 March, and ignores
focus events — so a dump depends only on N, the script and the data. `--keys FILE` plays timed input, one
command per line (`#` comments): `<frame> press|down|up <key> [cmd|shift|option|control]`, `<frame> click <x>
<y>` (canvas pixels; the menu strip is rows 0–19), `<frame> move <x> <y>` (the pointer, no button), `<frame> text <string>` (typed text, as SDL text input delivers it
after the key), `<frame> caps on|off`, `<frame> quit`. Keys: a–z, 0–9, space,
return, enter, tab, delete, esc, left/right/up/down, command/shift/capslock/option/control, or `0x..`
(Carbon key codes). Ctrl+Q on Windows is `press q cmd`. Example: `620 press return` starts a game from the menu.

W4 results (2026-10-06): `--frames 600` reaches the main menu; `--frames 900` with `620 press return` is in
level 1 (its JPEG background from `Decoded/`); both CrossOver dumps `cmp`-identical to the Mac SDL build's.

W4.5 results (2026-10-06): `--frames 610` with `600 click 180 10` + `602 move 220 84` shows the Options menu open
over the main menu (Music highlighted); `--frames 660` with `600 press 0x2b cmd` (Ctrl+,) shows DLOG 190 over it;
both CrossOver dumps (`HECTOR_SDL_*_DRIVER=dummy`, `--prefs` in scratch) exit 0 and are `cmp`-identical to the Mac
SDL build's.

## Results (W0, 2026-10-06)

**Proof A** (`hello`, CrossOver, `--skip-userdefaults`): exit 0 —
`platform Windows` · `Date 2026-10-05T23:26:22Z` · `String(format:) 03.14|BEEF|ok` ·
`FileManager listing ["a.txt", "b.txt"]` · `Mutex 1000` · `OK`. Without the flag the UserDefaults step crashes
(finding 2).

**Proof B** (`proof-b.sh`, HectorKit with the W0 guards): **250 passed / 6 failed / 0 skipped / 2 crashed of 258**
(Mac: 258 / 0 / 0). All eight are explained by three findings; everything else — data loading, PICT/cicn/ppat
decode, snd (pcm8 + ima4), the frame-exact simulation, FILM replays, the render compositor's FNV hashes —
is byte-identical on Windows.

### Findings

1. **No codec-compressed images on Windows** (5 tests: `RenderTests.testAllSpritesDecode331`,
   `.testCentredPict912Level1`, `BTXCensusTests.testEveryPICTClassified`, `.testSummaryLinesExact`,
   `.testStdoutEqualsCommittedCensus`). `CodecImage.decode` throws `unsupported` off Apple (the W0 guard), and
   BTX has eight QuickTime-JPEG PICTs: the six level backgrounds 13000–13005 and the David/Alex portraits
   29401/29402. The census differs from the committed one in exactly those eight rows + the totals. The game
   needs a portable JPEG decode before W4 can draw levels (a HectorKit decoder, or a pre-decoded bundle — a
   ruling).
2. **`UserDefaults` crashes under CrossOver** (2 tests: `PrefsTests.testBlobRoundTrip`,
   `.testLegacyFileImportVersionGate`; and Proof A's last step). Any first touch of a defaults domain — even
   `register(defaults:)` — dies in CoreFoundation's preferences code (inside Foundation.dll) with a `memcpy`
   of a ~8 GB length (r8 ≈ 0x1_ffff_xxxx) reading off the end of a heap block; the stack holds the
   preferences URL `file:///C:/users/crossover/AppData/Local/…`. Wine's ucrtbase is the faulting frame but the
   length comes from Foundation. Not yet known whether a real Windows PC behaves the same. `BTXPrefsStore`
   (core) uses UserDefaults, so W4 must either avoid it (file-backed store) or prove it on real Windows.
3. **`.macOSRoman` is wrong in Foundation on Windows** (1 test: `FrontEndShellTests.testPausedCheatBufferTakesKeyDownsOnly`,
   é → 0xBC instead of 0x8E). Decoding byte 0x80…0xFF gives the Mac Roman repertoire *sorted by Unicode
   value* (0x80 → U+00A0, 0x81 → U+00A1, … 0x8E → U+00B1) — a Foundation table bug, not Wine: Wine's own
   code page 10000 (`MultiByteToWideChar`) gets those right (0x80 → U+00C4, 0x8E → U+00E9) but is *also* wrong
   at 0xBD: it follows Microsoft's cp10000 table, 0xBD → U+2126 OHM SIGN, where Apple's table (since Mac OS 8.5)
   gives U+03A9 GREEK CAPITAL OMEGA. So it is no fallback either. Encoding is equally
   wrong, and decomposed input (`e` + U+0301) fails outright. Real Windows will do the same. Affects every
   `.macOSRoman` use in the core (`MacText` prefs strings, `STR#` lists, `LettersFont`) and HectorKit's
   `MacRoman.bytes`; ASCII is unaffected. Fix = HectorKit owns the table (`MacRoman`), ruled in D16.2 — neither
   Foundation's nor the OS's code page is trusted.

Mac-side W0 code changes: HectorKit `CodecImage.swift` + `Ditl.swift` portability guards only (`#if
canImport`), Mac behaviour byte-identical. `proof-b.sh` adds one test-only shim to its *copy* of the core:
`Tests/BubbleTroubleRenderTests/Support/PNGWriter.swift` (ImageIO, the opt-in `BTX_RENDER_PNG_DIR` dump)
returns false off Apple. The repo's core is untouched.
