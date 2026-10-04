# Plan — Bubble Trouble X 1.1 playable app on HectorShell — 2026-10-04

> Status: **REVIEWED — READY_WITH_FIXES applied** (planner Opus 5.5; adversarial Opus review 2026-10-04; fixes R1–R14 in
> "Amendments after plan review" at the end — they OVERRIDE task text where they conflict; every implementer reads them).
> **Format (Ben's ruling 2026-10-03): CONTRACTS, not code.** Each task names files, public types/APIs (signatures only
> where they pin a seam), behaviour contracts with decompile/bank anchors, test names, gate commands and — where his eyes
> are needed — "What Ben checks". Implementers (Opus, fresh context) write tests and code under TDD from the contract.
> Literal text appears only where the wording is the spec (`project.yml` block, stage script name, bundle id).

**Goal:** Ben can play Bubble Trouble X **1.1** on Apple Silicon exactly as the 2008 UB app played: title, menus, attract
demos, level-to-level play with graphics, sound, music, lives, time bonus, high scores, prefs, pause and cheats. 100 %
faithful, no modern affordances (CLAUDE.md standing ruling; D8 item 1). Progress is measured by what Ben can play.

**Inputs:** front-end inventory `scratchpad/btx-frontend-inventory.md` (cited **FI §n**; to be filed into the bank by T0 as
`docs/bubble-trouble/front-end.md`), code-surface map `scratchpad/btx-code-surface.md` (cited **CS §n**, gaps **G1–G10**),
RE bank `docs/bubble-trouble/*.md`, DECISIONS D3/D4/D5/D8/D10, core plan `docs/plans/2026-10-03-btx-core-and-film-harness.md`
(its Known delta 7 is this plan's scope). Decompile oracle (read-only): `DC=~/Developer/Ambrosia/ghidra/BTX_i386.decompiled.c`
(`fn @ addr` anchors; `ghidra/find_func.py --func` to jump).

**Repos:** `HKWT` = the HectorKit lane worktree. `WT=/Users/andiyar/Developer/Ambrosia-Classics/.claude/worktrees/<lane worktree>` (one worktree per lane, branched
from Classics `main`; the orchestrator merges) · `HK=~/Developer/HectorKit` — kit tasks work in a HectorKit worktree on
branch `btx-shell`, **rebased onto HK `main` immediately before each ff-merge** (the Aki-iPad / Remaster sessions may push to
HK main concurrently). Classics consumes merged HK `main` only, through the `.claude/worktrees/HectorKit` symlink (D1).
**Data:** `BTXR="/Users/andiyar/Developer/Ambrosia/Resources/ambrosia-extracted/Action-Adventure/Bubble Trouble X/BubbleTroubleX_1.1_UB/Bubble Trouble X.app/Contents/Resources"`.

**Out of scope here:** diagnosing FILMs 2–4 dying (D8 side lane; the attract mode simply replays FILMs 1–4 through the core
as it stands — if the original dies there too, that IS the faithful demo).

---

## Verification model (read first)

Gate commands (copy literally; `$WT` = your worktree, `$SCRATCH` = your scratch dir, `$BTXR` as above):

```sh
# G1 — core package suite, zero skips. Expect: the task's stated total, then 0.
cd "$WT/BubbleTrouble/Core" && HECTORKIT_DATA_BTX="$BTXR" swift test > "$SCRATCH/g1.log" 2>&1
grep -cE "^Test Case '.*' (passed|failed|skipped) \(" "$SCRATCH/g1.log"
grep -cE "^Test Case '.*' (failed|skipped) \(" "$SCRATCH/g1.log"

# G2 — app builds clean (from A1 on). Expect: ** BUILD SUCCEEDED **, then 0. Aki must stay green too.
cd "$WT" && xcodegen generate && xcodebuild -scheme BubbleTroubleX build > "$SCRATCH/g2.log" 2>&1; tail -n 1 "$SCRATCH/g2.log"
grep -E ": warning:" "$SCRATCH/g2.log" | grep -v "/HectorKit/" | sort -u | wc -l
xcodebuild -scheme Aki build 2>&1 | tail -n 1

# G3 — HectorKit zero-skip floor (K-tasks). Expect: PASS at FLOOR = HK main's floor when the task starts
# (201 at 465200a on 2026-10-04; the Remaster session moves it) + the task's N; the task bumps FLOOR in the script.
HECTORKIT_TEST_LOG="$SCRATCH/hk.log" "$HKWT/tools/check-zero-skip.sh" 2>&1 | tail -n 1

# G4 — FILM replay unchanged (every task touching Sources/BubbleTroubleCore/Sim/ or Session/). Expect: no diff.
cd "$WT/BubbleTrouble/Core" && swift build -c release --product btx-replay > /dev/null
for f in 1 2 3 4; do .build/release/btx-replay --data "$BTXR" --trace $f; done > "$SCRATCH/replay.txt" 2>&1
diff "$SCRATCH/replay.txt" "<baseline path from the dispatch>"

# G5 — staged app boots. Expect: pid found; clean quit; no new crash log.
open "out/BubbleTroubleX/Bubble Trouble X.app"; sleep 5; pgrep -x "Bubble Trouble X"
osascript -e 'quit app "Bubble Trouble X"'; ls -t ~/Library/Logs/DiagnosticReports | head -3
```
G4 runs the built binary with `--trace` (per-frame, catches any moved RNG draw), never `swift run` (core Invariant 16).
G4 only exercises demo-mode paths; play-mode-only branches are covered by C2–C4 unit tests.

Count `Test Case` lines, never bare `skipped`. **Expected G1 totals in canonical merge order:** 130 → C1 136 → C2 144 →
C3 152 → C4 164 → R1 174 → C5 182 → C6 194 → C7 202 → C8 208. If lanes merge in another order, the expected total is
130 + Σ N of merged tasks. **HK floor:** F → K1 F+4 → K2 F+9 → K3 F+12 (F = 201 at HK 465200a today — re-read it when the K-task starts; if K3 merges before K2, F+7 then F+12).

**Honesty gates (Ben only — phrase completion as "machine gates green", never "plays like Bubble Trouble"):** see the final
section. Every task with visible/audible output carries a "What Ben checks" line that the gate stage collects.

---

## Non-negotiable invariants

1. **Portability split (HectorKit D6).** `BubbleTroubleCore` stays Foundation + HectorResources only (core plan Invariant 1:
   no HectorGraphics/HectorAudio import). A new library target **`BubbleTroubleRender`** in the same package (Foundation +
   HectorGraphics + HectorAudio — the kit's decoder layer, no AppKit/AVFoundation) owns pixels and PCM. The app
   (`BubbleTroubleX/App`) is the only code that imports AppKit/HectorShell. **Why this split (Aki exemplar, CS §2):** Aki put
   all logic + rects in Foundation-only Core with TDD and kept the App test-less; BTX goes one step further because its
   screen is a QuickDraw sprite pipeline whose correctness is pixel arithmetic — so the compositor is headless and golden-
   tested, and the App only presents a finished 640×480 buffer, plays PCM, and translates events.
2. **Transcribe, don't reinvent.** The core records *what the original did* each frame — `_PlayMySnd` calls and the
   QuickDraw call sites (`_AddRectToBgnd`, `_RestoreBgnd`, `_SpriteToComp`, …) — as ordered op lists at the original's call
   sites. The renderer executes those ops on persistent bgnd/comp/screen buffers exactly as QuickDraw did, artefacts
   included. No "redraw the world from state" shortcut.
3. **The simulation is frozen.** No task changes an RNG draw, a state transition or a FILM outcome: G4 must show no diff.
   New behaviour (level transitions, pause, cheats) is added around/after `stepFrame`, transcribed from `_PlayGame`.
4. **Time bases.** In-game time is frames (0.033 s Carbon timer, `_PlayGame @ 00018247` disasm 00018326..00018355,
   engine-loop §2 — nominal 30.3 fps; missed fires are dropped, never caught up). Front-end and blocking sequences
   (countdown, wipes, splashes, menus, scores) are TickCount (1/60 s) (FI §5). The session API takes both explicitly; the
   App owns the clocks.
5. **Registered, valid licence; prefs at defaults** (stars/air bubbles ON, core assumption). Unregistered paths (Register
   button/key R, DLOG 1002/1003, level-7 nag, forced level-select 8) are not built.
6. **No affordance the original lacks.** No debug overlays, no launch flags, no extra menu items in Release. A DEBUG-only
   "data missing → run tools/stage-btx.sh" alert is allowed (Aki Known delta 7 precedent), compiled out of Release.
7. Implementer commits carry `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`; never `git add -A`.

---

## Shared architecture (LOCKED — every task codes against these names)

### S1. Package `BubbleTrouble/Core` (products added)
- `BubbleTroubleCore` (existing) + new public surface: `BTXGameData`, `SpriteIndex`, `RectResources`, `SoundCue`,
  `DrawOp`, `Notice`, `GameSession`, `KeyboardInput`, `FrontEnd`, `HighScoreTable`, `BTXPrefs`, `BTXPrefsStore`, `Cheats`.
- `BubbleTroubleRender` (new library target; deps `BubbleTroubleCore`, HectorGraphics, HectorAudio): `RGBAImage`,
  `ArtBank`, `Compositor`, `LettersFont`, `SoundBankPCM`, protocol `TextRasterizer`.
- Tests: `BubbleTroubleCoreTests` (existing), `BubbleTroubleRenderTests` (new; data-gated on `HECTORKIT_DATA_BTX`, skips are
  failures under G1 because the var is always set).

### S2. Seams (signatures that pin interfaces)
- `public struct SoundCue: Equatable, Sendable { public let slot: Int /*0…47 → snd 9000+slot*/; public let priority: Int; public let delayFrames: Int }`
- `public enum MusicCue: Equatable, Sendable { case load(set: Int), start, stopFade, stopNow, pause, resume, unload }`
- `public enum DrawOp: Equatable, Sendable` — cases mirror QuickDraw call sites: `drawMaze(pictID:)`, `restoreBgnd(QDRect)`,
  `sprite(set:frame:h:v:mode:)` (`mode`: `.normal`, `.transparent` — `_SpriteToCompTransparent`), `spriteToBgnd(…)`,
  `prepareScoreBar`, `compToScreen(QDRect)`, `pict(id:dst:)`, `pictSlice(id:src:dst:)` (`_BgndToCompTransparent`),
  `string(text:h:v:highlighted:)` (Letters font), `infoText(String, colour:)`, `darkenRect(QDRect)`, `frameRect(QDRect, rgb:)`,
  `fillBlack`, `patternOverlay(index:)`, `wipe(step:)`, `fps(Int)`. Tasks may ADD cases (additive), never rename.
- `GameState.stepFrame` keeps its signature; `FrameReport` gains `public let sounds: [SoundCue]` and
  `public let drawOps: [DrawOp]` (default-empty in replays; FILM goldens unaffected).
- `public final class GameSession` (Foundation; not Sendable, used on the main actor by the App):
  `init(data: BTXGameData, prefs: BTXPrefs, mode: GameMode, startLevel: Int, seed: UInt32, film: Film?)`;
  `func frame(keys: HeldKeys) -> SessionOutput` (one 0.033 s tick); `func tick(now: UInt32, keys: HeldKeys) -> SessionOutput`
  (1/60 s, for countdown/blocking phases); `var phase: SessionPhase { get }`; `var wantsFrameTimer: Bool { get }`.
- `public struct SessionOutput { sounds: [SoundCue]; music: [MusicCue]; drawOps: [DrawOp]; requests: [ShellRequest]; ended: SessionEnd? }`
  where `ShellRequest` = `.hideCursor`, `.showCursor`, `.enableMenus(Bool)`, `.haltAllSound`, `.highScoreEntry(rank:)`,
  `.quitNow` (⌘Q in play: no prefs save), `.savePrefs`.
- `public struct HeldKeys { var codes: Set<UInt16>; var capsLock: Bool; var command: Bool }` (Mac virtual key codes).
- `public final class FrontEnd` (tick-driven, owns `GameSession` while a game/demo runs): `func tick(now:keys:mouse:) -> SessionOutput`,
  `func key(_ code: UInt16, chars: String, modifiers: ShellModifiersLite) -> SessionOutput`, `func mouseDown/Up(h:v:modifiers:)`.
- `public protocol TextRasterizer { func rasterize(_ s: String, font: String, size: Int, rgb: UInt32, into: inout RGBAImage, at: (h: Int, v: Int), centredIn: QDRect?) }`
  — implemented by the App with CoreText (Geneva 9); a test stub in Render tests.
- `public final class Compositor { init(art: ArtBank, text: TextRasterizer); func apply(_ ops: [DrawOp]); var screen: RGBAImage { get } }`
  — persistent `bgnd`, `comp`, `screen` 640×480 buffers, 0xAARRGGBB, row 0 top (matches `ShellBitmap.pixels`, CS §1a).

### S3. App (`BubbleTroubleX/App`, AppKit, `@MainActor`)
`BTXMain` (entry, Aqua forced — D4.1), `BTXController` (app delegate, `ShellInputHandler`, owns timers/session/compositor),
`BTXAssets` (bundle locator), `BTXAudio` (SFX voices + music voice on `ShellMixer`), `BTXMenus`, `BTXDialogs`,
`BTXPrefsWindow`, `CoreTextRasterizer`, `Info.plist`. No test target (Aki precedent, CS §2): verified by G2 + G5 + Ben.

### S4. `project.yml` additions (literal)
```yaml
packages:
  BubbleTroubleCore:
    path: BubbleTrouble/Core
targets:
  BubbleTroubleX:
    type: application
    platform: macOS
    sources:
      - path: BubbleTroubleX/App
        excludes: ["Info.plist"]
    dependencies:
      - package: BubbleTroubleCore
        product: BubbleTroubleCore
      - package: BubbleTroubleCore
        product: BubbleTroubleRender
      - package: HectorKit
        product: HectorShell
    settings:
      base:
        PRODUCT_NAME: "Bubble Trouble X"
        PRODUCT_BUNDLE_IDENTIFIER: com.ambrosiaclassics.bubbletroublex
        INFOPLIST_FILE: BubbleTroubleX/App/Info.plist
        GENERATE_INFOPLIST_FILE: NO
        ENABLE_APP_SANDBOX: NO
schemes:
  BubbleTroubleX:
    build:
      targets:
        BubbleTroubleX: all
```

### S5. Runtime data
The staged `.app` carries the original's `Contents/Resources` files under its own `Contents/Resources`: `Bubble Trouble
X.rsrc`, `BT Levels.rsrc`, `BT Sprites.rsrc`, `BT Sounds.rsrc`, `BT Titles.rsrc`, `English.lproj/AboutCredits1.rtf` (D10
permits shipping). `BTXAssets` resolves them from `Bundle.main.resourceURL` by original file name (Aki `AkiAssets` pattern).

---

## Tasks

Legend: ⚑ MAJOR = two Opus review legs (spec compliance, then quality — Ben: every subagent Opus); minor = one Opus reviewer doing spec-then-quality. "+N" = new `Test Case`s.

### T0 — minor — Preflight, baselines, bank corrections
- **Files:** `docs/bubble-trouble/front-end.md` (new: the inventory filed into the bank verbatim with its anchors and U1–U12),
  `docs/bubble-trouble/data-formats.md` (§7 correction), `docs/bubble-trouble/INDEX.md` (link), `docs/DECISIONS.md` (next
  free D-number: "BTX playable — architecture split S1/Invariant 1–2, time bases Invariant 4"; check the number is unused on
  `main` first — D-numbers have collided before).
- **Steps:** (1) worktree + `.claude/worktrees/HectorKit` symlink present; (2) G1 = 130/0; (3) capture
  `$SCRATCH/btx-replay-baseline.txt` (G4's reference; record its path in the handoff); (4) bank correction: §7 `Rect` 1..7
  are stored **Left, Top, Right, Bottom** (`TMPL 128`, `_GetRectRsrc @ 0000c9e9`; New button = L165 T228 R315 B262), not
  "QuickDraw order top,left,bottom,right" — append a ⚑ corrected note, keep the old text struck through.
- **Verify:** G1 130/0. **Commit:** docs only.

### K1 — minor — HectorKit: held-key state and Caps Lock (HectorShell) (+4, kit)
- **Files (HK):** `Sources/HectorShell/ShellView.swift`, new `Sources/HectorShell/ShellKeyState.swift`, tests in `Tests/HectorShellTests/`.
- **Contract (additive only; Aki unchanged):** `ShellInputHandler` gains `shellView(_:keyUp:)` and `shellView(_:flagsChanged:)`
  with default no-op implementations in a protocol extension. `ShellView` forwards `keyUp`/`flagsChanged` and maintains
  `public private(set) var keyState: ShellKeyState` = `{ held: Set<UInt16> (virtual key codes), capsLock: Bool, modifiers: ShellModifiers }`;
  key repeats do not double-insert; `held` is cleared on window resign-key / app deactivate (the original polls `GetKeys`, which
  reads nothing while inactive — FI §4).
- **Tests:** `testKeyDownUpTracksHeldSet`, `testRepeatDoesNotDuplicate`, `testFlagsChangedTracksCapsLock`, `testResignKeyClearsHeld` (synthesised `NSEvent`s).
- **Verify:** G3 floor F+4; Aki G2 still green. **Merge:** rebase on HK main, ff-merge, push.

### K2 — minor — HectorKit: `snd` → linear PCM, exact rate, IMA4 stereo (HectorAudio) (+5, kit)
- **Files (HK):** `Sources/HectorAudio/SndSound.swift` (+ new `IMA4.swift`), `Tests/HectorAudioTests/`.
- **Contract:** `public struct SndPCM: Sendable { sampleRate: Double; channels: Int; frames: Int; samples: [Int16] /*interleaved*/ }`;
  `SndSound.linearPCM() throws -> SndPCM`: `pcm8` unsigned → `(s − 128) << 8`; `.compressed` codec `ima4` → Apple IMA4
  (34-byte packets: 2-byte preamble = 9-bit predictor + 7-bit step index; 64 nibbles low-first; stereo packets alternate L/R);
  `sampleRate` from the header's UnsignedFixed **un-truncated** (22254.545… for BTX music — data-formats §6 deferral closed
  here). Foundation only.
- **Tests:** `testPCM8Converts` (synthetic), `testIMA4KnownVector` (hand-built packet with a precomputed output),
  `testIMA4StereoInterleave`, `testExactFixedRate`, data-gated `testBTXMusic11001DecodesFullLength` (frames = packets × 64).
- **Verify:** G3 floor F+4+5.

### K3 — minor — HectorKit: `ShellMixer` voices (HectorShell) (+3, kit)
- **Files (HK):** new `Sources/HectorShell/ShellMixer.swift`, tests.
- **Contract:** AVAudioEngine with `voices` player nodes. `init(voices: Int) throws`; `load(id: Int, samples: [Int16], channels: Int, sampleRate: Double)`;
  `play(id:on voice: Int, volume: Float, loops: Int)`; `stop(voice:)`; `stopAll()`; `pauseAll()`/`resumeAll()`;
  `isPlaying(voice:) -> Bool`; `setVolume(voice:_:)`. Independent of K2's type (takes raw samples) so K2 ∥ K3.
  Volume law matches `ShellSoundBank` (0x100 = full, linear).
- **Tests:** manual-rendering-mode engine (headless): `testPlayRendersNonSilence`, `testStopSilencesVoice`, `testLoopsRepeat`.
- **Verify:** G3 floor F+12.

### C1 — minor — Core: all five files, sprite index, rects, level tables (+6 → 136)
- **Files:** `Sources/BubbleTroubleCore/Data/BTXGameData.swift`, `SpriteIndex.swift`, `RectResources.swift`, tests `GameDataTests.swift`.
- **Contract:** `BTXGameData(resourcesDirectory:)` opens all five `.rsrc` (data-fork maps, `ResourceReader.read(fileAt:)`),
  wraps the existing `BTXResourceFiles` (levels/FILMs unchanged), adds named lookup (`snd` "Level set N music.1" → id; G7).
  `SpriteIndex` parses `SpIL 128` → `SpIc 1000` (52 × start,count; data-formats §4): `cicnID(set:frame:)` = start[set−1] + frame − 1.
  `RectResources` decodes `Rect 1…7` **L,T,R,B** (T0 correction) into `QDRect`. `LevelPresentation.background(level:)`,
  `.musicSet(level:)` read LEVL w1/w2 (FI §6a table is the oracle). `ResourceCollection` is not Sendable — `BTXGameData` is a
  final class, main-actor-used.
- **Tests:** `testOpensAllFiveFiles`, `testSpriteIndex52Sets` (set 1 → 25000, 0x34 → 31700), `testRectsLeftTopRightBottom`
  (Rect 1 = 165,228,315,262), `testLevelBackgroundAndMusicTable` (levels 1, 12, 21, 50 vs FI §6a), `testNamedMusicLookup`
  (sets 1–4 → 11001–11004), `testTitleMusicIsSet3`.
- **Verify:** G1 136/0.

### C2 — ⚑ MAJOR — Core: sound cues from the simulation (+8 → 144)
- **Files:** `Sources/BubbleTroubleCore/Sim/*.swift` (sound sites only), new `Sim/Sounds.swift`, `FrameStep.swift` (report field), tests `SoundCueTests.swift`.
- **Contract:** every `_PlayMySnd` call reachable from the `_PlayGame` frame body (FI §7 table; 152 call sites in `DC`, of which
  the sim-reachable ones are transcribed — list each with its `fn @ addr` in `Sounds.swift`'s header) appends a `SoundCue` at
  the same point in the same order. `_PlayMySnd @ 00026a7b` semantics: slot n → snd 9000+n, priority as passed (10/20/30),
  `delay > 0` enters the 5-slot delayed queue flushed each frame by `_Sounds_CheckDelayedSounds @ 000268a1` (overflow
  behaviour as the decompile shows). Random sound choices (Oooer/Ayeeee, Zoiks/Yeow) consume exactly the draws the core
  already makes — attach the cue to the existing draw result, add none. Demo suppressions are NOT here (they live in
  `_NewLevel`/`_PlayGame` state code → C4) unless the site itself tests `gGameMode`.
- **Tests:** `testPushSuccessCuesSlot5`, `testPushFailCuesSlot7`, `testBubblePopCuesSlot6`, `testCatchCuesOooerOrAyeeeeWithoutExtraDraw`,
  `testDelayedCueFiresAfterDelayFrames`, `testDelayedQueueHoldsFive`, `testExtraLifeCuesSlot13Twice`, `testFilm1CueCountIsStable` (self-derived golden).
- **Verify:** G1 144/0; **G4 no diff**.

### C3 — ⚑ MAJOR — Core: draw-op recording, notices, HUD (+8 → 152)
- **Files:** `Sim/FrameStep.swift` (draw pass), new `Sim/DrawOps.swift`, `Sim/Notices.swift`, `Sim/HUD.swift`, `_AddRectToBgnd` sites
  in `Sim/*`, tests `DrawOpTests.swift`.
- **Contract:** `FrameReport.drawOps` = the `_PlayGame` frame's QuickDraw calls in order (FI §6b): `_RestoreBgnd @ 00015dbe`
  over the dirty list filled by every `_AddRectToBgnd @ 00015e09` site → `_DrawHurtBlocksToComp` → hero → enemies → balloons
  → blocks → splats → bonus → stars → `_DrawOuchToComp @ 00022d03` ("Erk!", set 0x10, FI §3d placement) → points → air
  bubbles → `_DrawScore @ 00028168` → `_TimeBonus_Draw @ 00006b3a` → `_DrawReserveHeroImage/Number` → `_DrawNotice @ 00027948`
  → `_CompToScreen` rects (`_AddRectToScreen @ 0002635a`). Ops are recorded **at the original's draw point, before the slot
  is freed** (fixes G4 of CS: dead enemies/balloons/bonus draw on their freeing frame exactly as the original did or did not).
  Level start: `levelStartOps()` = `_DrawMaze` (PICT LEVL.w1 into bgnd+comp, `_PrepareScoreBar @ 00025c65`, maze cells
  10/15/16/20/30/52 → sets 0x11/0x14/0x15/0x16/0x17/0x12-or-0x13 by level < 12; `DC` `_DrawMaze` switch). Notice state
  (`_PrepareNotice @ 00027829`, `_EraseNotice @ 0002784e`, ids 1–6, rects FI §6a) lives in `GameState`. HUD positions FI §6a
  (score 8 digits x132 pitch 24 — ⚑ C3: padded with leading zeros to 5 digits, `_DrawScore` buffer 0,0,0,0,0,ff,ff,ff, lives digit = lives−1, EXTRA x322…403, time bonus 5 digits x480 (+22 when < 10000),
  multiplier x601 hidden at 1×). Orbit stars draw nothing (Intel unswapped SPIN 1, data-formats §5).
- **Tests:** `testLevelStartOpsLevel1` (PICT 912, score bar, N sprite ops = maze bubble count), `testDrawOrderMatchesPlayGame`,
  `testRestoreBgndPrecedesSprites`, `testDeadEnemyDrawnOnFreeingFrameAsOriginal`, `testScoreDigitsNoLeadingZeros` (⚑ C3: `testScoreDigitsPadToFiveDigits` — the original pads to 5),
  `testLivesDigitShowsSpareLives`, `testTimeBonusShiftBelow10000`, `testNoticeLevelTwoDigitPlacement`.
- **Verify:** G1 152/0; **G4 no diff**.

### C4 — ⚑ MAJOR — Core: `GameSession` — the play loop around `stepFrame` (+12 → 164)
- **Files:** new `Sources/BubbleTroubleCore/Session/GameSession.swift`, `KeyboardInput.swift`, `TimeBonusCountdown.swift`,
  `Pause.swift`; `Sim/LevelBuild.swift` (`newLevel` → public `advanceLevel(data:)`), tests `GameSessionTests.swift`.
- **Contract (anchors FI §3, engine-loop §5):**
  1. `KeyboardInput: InputSource` maps `HeldKeys` through the current key set (default ←→↑↓ Space = 0x7b,0x7c,0x7e,0x7d,0x31;
     sets 2–8 FI §4) to one `FilmSample` per `_CheckHeroMovement @ 00021f49` read (level-sampled, no repeat semantics).
  2. New game (`_RequestGame @ 0000a9a1` → `_PlayGame`): seed = caller's TickCount; `SetLevel(start−1)`, lives 3, score 0,
     next extra 10000, mult 1, EXTRA clear; `gPlayerIsCheating` = start > 1.
  3. Level start (`_NewLevel @ 0001735f`): `levelStartOps` + `wipe(step: 12)` + notice LEVEL n (demo: GAME OVER, kept all
     demo) + `MusicCue.load(set:)` (not demo) + snd 2 (not demo); hero appears at frame 70 / 60 on respawn (core) → notice
     cleared (not demo), `MusicCue.start` (not demo), snd 8 (not demo) + snd 27.
  4. Level complete: snd 35 (not demo) at the trigger; +70 frames (core `checkEndOfLevel`) → `stopFade` (`_StopMusic
     @ 0001afac`: −5/tick from 0x40/0x80/0x100) → phase `.countdown` driven by `tick(now:)`: `_TimeBonus_CountDown @ 00006dcb`
     exactly (multiplier flash 3× 8-tick + snd 32, bonus ×mult cap 99950, snd 9, 60-tick wait, snd 42 if 0 / 41 if ≥ 10000,
     chunks 500/200/100/50 by remaining, 3 ticks/chunk, snd 17 every 3rd, final 15) → snd 27, `unload` → `advanceLevel`:
     `_LoadLevel @ 00002ef7` (≥ 51 → random LEVL 21…50 via `GetRandomFast(0x15,0x32)`, ≥ 100 → 99; raise level-select max
     while < 31). Demo instead ends (`.levelCompleted`).
  5. Death: state 3→4 `stopNow`, snd 34; respawn: `lives ≥ 1` → snd 2 + GET READY!; else FIN! + snd 3, game ends 95 frames later.
  6. Esc: ends the game at once, or held > 30 frames when bool 0x3d (`_PlayGame`). ⌘Q in play → `.quitNow`.
  7. Pause (`_PauseGame @ 0001767b`): entered while `capsLock` (key 0x39 state) in play, never in demo; `haltAllSound`,
     `MusicCue.pause`, snd 22, `showCursor`, `enableMenus(true)`, notice PAUSED + `pict(9030)` L155 T279 R485 B295 +
     `pict(9031)` L190 T299 R450 B315; exit restores the previous notice, `resume`, `hideCursor`. Cheat typing is C8.
  8. Demo: `GameSession(mode: .demo, film:)` — level = FILM id, seed = FILM seed (replay-oracle §3), ends on the core stops +
     any key/mouse (`FrontEnd` forwards). No music ever.
  9. `wantsFrameTimer` is true only while frames run (phase `.playing`); `.countdown`, wipes and `.paused` are tick-driven.
- **Tests:** `testKeyboardInputDefaultSet`, `testKeyboardInputKeySet7Classic`, `testNewGameStartsLevel1ThreeLives`,
  `testLevelStartCuesGetReadyNotInDemo`, `testHeroAppearStartsMusic`, `testCountdownChunksAndSounds` (bonus 12345 ×2),
  `testCountdownCap99950`, `testLevelAdvanceAfterCountdown`, `testLevel51PicksRandom21to50`, `testGameOverAfter95Frames`,
  `testEscHoldPref`, `testCapsLockPausesNotInDemo`.
- **Verify:** G1 164/0; **G4 no diff**.

### R1 — ⚑ MAJOR — Render: `ArtBank`, `Compositor`, `LettersFont`, `SoundBankPCM` (+10 → 174)
- **Files:** `Package.swift` (new target + test target), `Sources/BubbleTroubleRender/*.swift`, `Tests/BubbleTroubleRenderTests/*.swift`.
- **Contract:** `ArtBank(data:)` decodes every cicn (331, `CIcon(data:)`), every PICT (`PICT.decodeAny` / `decodeMasked`
  for 9030/9031/9077/7000/2910 mattes, regions for 9001/9002/9012/9020) to `RGBAImage` once, lazily. `Compositor.apply`
  executes `DrawOp`s with QuickDraw semantics: `_DrawAndCentrePict` centring in 640×480; `_SpriteToComp @ 00015398` = cicn
  mask-keyed copy at (h,v); `_SpriteToCompTransparent @ 0001518d` = the blend the decompile uses (transcribe its op colour);
  `restoreBgnd` = bgnd→comp rect copy; `compToScreen` = comp→screen; `prepareScoreBar` = bottom 40 px blended 50 % to black
  (OpColor 0x7fff, blend) + 2-px QuickDraw `greenColor` line at y 440; `wipe(step)` = `_WipeScreen @ 000076d3` two-band reveal
  exposed as `wipeSteps(step) -> Int` + `applyWipe(row:)` so the App paces it per tick; `LettersFont` = PICT 9001/9002 cut by
  the glyph rects transcribed from `_InitLetterRects @ 0001d6e9` (closes U4 part 1), drawn like `_DrawCustomString @ 0001e4c0`.
  `SoundBankPCM` = snd 9000–9047 + 11001–11004 → K2 `SndPCM` (requires K2 merged; until then this one file waits — sequence
  it last in the task).
- **Tests (data-gated, goldens self-derived from the original's resources, recorded as FNV-1a of the screen buffer + named
  pixel probes):** `testAllSpritesDecode331`, `testCentredPict912Level1`, `testScoreBarBlendAndGreenLine`, `testSpriteMaskKeyed`
  (hero idle cicn 25000 pixels land exactly), `testRestoreBgndCopiesOnlyRect`, `testLevel1FirstFrameGolden` (C3 `levelStartOps`
  + frame 1 ops), `testWipeRevealsBandsStep12` (20 ticks), `testLettersFontHighScoresHeader`, `testPauseMattePictsDecode`,
  `testSoundBankDecodes52`.
- **What Ben checks (at M1):** level 1 looks like the original — background, bubbles, score bar tint and green line, digits.
- **Verify:** G1 174/0 (after C3; if R1 merges first, its golden test for frame 1 lands with C3 — orchestrator's call).

### A1 — ⚑ MAJOR — App skeleton: window, frame timer, present, keyboard, sound, music → **first playable**
- **Files:** `project.yml` (S4), `BubbleTroubleX/App/{BTXMain,BTXController,BTXAssets,BTXAudio,CoreTextRasterizer}.swift`,
  `BubbleTroubleX/App/Info.plist` (bundle id, `NSPrincipalClass`, display name "Bubble Trouble X", min macOS 15),
  `tools/stage-btx.sh`, `BubbleTroubleX/WHAT-TO-EXPECT.md`.
- **Contract:** `ShellWindowController(title: "Bubble Trouble X", logicalWidth: 640, logicalHeight: 480)` centred
  (`_CreateGameWindow @ 00010144`); `ShellIdleTimer(interval: 0.033)` drives `GameSession.frame` → `Compositor.apply` →
  copy `compositor.screen` into a `ShellBitmap` (opaque, so premultiplied = straight) → `present` — one sim step + one
  present per fire, missed fires dropped (Invariant 4). A 1/60 s timer drives `tick(now: ShellClock.ticks())` in tick
  phases (only one timer runs at a time, chosen by `wantsFrameTimer`). Keys: K1 `keyState` → `HeldKeys` each frame.
  `BTXAudio`: one `ShellMixer` with **4 SFX voices** (`ST_Open(4,0)`, FI §7) + 1 music voice; voice choice = free voice,
  else steal the lowest-priority voice whose priority ≤ the cue's, else drop (Q6 default); SFX volume short 0x33 map
  1→0, 2→0x10, 3→0x40, 4→0x100; music 0x35 map 1→0, 2→0x40, 3→0x80, 4→0x100; `MusicCue.start` = play the set's PCM with
  `loops: 50` (`_StartMusic @ 0001ad8c`); `stopFade` steps volume −5/tick. Cursor hidden + `CGAssociateMouseAndMouseCursorPosition(0)`
  + warp to centre in play, restored on exit (`_PlayGame`). **At this task the app launches straight into a new game at
  level 1** (temporary; A2 inserts the front end before it) and returns to a new game after game over.
  `tools/stage-btx.sh` (Aki `stage-aki.sh` shape): xcodegen → Release build (`.build/xcode-btx`) → ditto to
  `out/BubbleTroubleX/Bubble Trouble X.app` → copy S5 files from `${BTX_DATA:-$BTXR}` → `xattr -cr` → ad-hoc
  `codesign --deep` → copy WHAT-TO-EXPECT → also `ditto` both to `~/Desktop/` (hidden worktrees are unopenable).
- **Verify:** G2 (both schemes), G5 on the staged app.
- **🎮 Milestone M1 — first playable:** stage and offer Ben: "level 1 → 2 → … plays with keyboard, graphics, sound and
  music in a window; dying, lives, game over, time-bonus count-down work; no title/menus yet". **What Ben checks:** arrow
  keys + Space feel right (push, reversal mid-cell), speed feels like the original (30 fps), sounds are the right ones at
  the right moments, music per level set.

### C5 — minor — Core: prefs blob, key sets, high-score table (+8 → 182)
- **Files:** `Sources/BubbleTroubleCore/Prefs/{BTXPrefs,BTXPrefsStore,HighScoreTable,KeySet}.swift`, tests `PrefsTests.swift`.
- **Contract:** `BTXPrefs` = the 0x800 blob of data-formats §9 (version 0x17; 100 bool / 100 short / 100 long / 20 key sets),
  defaults from `_AlexPrefsGameInit`/`_AlexPrefsKeysInit @ 0000f790` (FI §8 table), typed accessors for every pref FI §8 names.
  `HighScoreTable` = the 0x8a block (§8), defaults from `SCOR 128`; `qualifies(score:)` (> entry 7), `insert(name:score:level:)`
  (shift down), `defaultName`; name rules of `_CheckHiScore @ 00024b34`: empty → "Maniac"/"Swoop" by `GetRandomFast(0,1)`
  (session RNG, not the sim's), joke-name substitutions **transcribed in full from the compare chain** (closes U11; each pair
  cites its disasm address), custom-level "^" suffix not reachable (Known delta 3). `BTXPrefsStore` persists blob+table as
  one `Data` under UserDefaults key `Prefs` (domain `com.ambrosiaclassics.bubbletroublex`); on first run, if
  `~/Library/Preferences/Bubble Trouble X Prefs` exists with version 0x17, import it read-only (`_LoadGamePrefs @ 00027306`;
  wrong version → defaults, as the original deletes and re-inits).
- **Tests:** `testDefaultsMatchAlexPrefsInit`, `testKeySets1to8`, `testBlobRoundTrip`, `testScor128Defaults` (The Fonz; Potsie
  4500 L4…), `testQualifiesAboveSeventh`, `testInsertShiftsDown`, `testJokeNameSubstitution` (every transcribed pair),
  `testLegacyFileImportVersionGate`.
- **Verify:** G1 182/0.

### C6 — ⚑ MAJOR — Core: `FrontEnd` — splash, main menu, attract, demo, level select (+12 → 194)
- **Files:** `Sources/BubbleTroubleCore/FrontEnd/{FrontEnd,MainMenu,Attract,Splash,MenuStars,InfoBox}.swift`, tests `FrontEndTests.swift`.
- **Contract (FI §1–§2):** Splash (`_InitMac @ 0000563c`): black → PICT 200 centred, held 130 ticks after draw (windowed:
  `WipeScreenOut(4)`/`WipeScreen(4)`); PICT 9011 + progress bar L250 T445 R390 B451 (2-px border; steps 1 + sprites + orbit
  + 48 sounds; colours read from the `gPBorderCol1/2`, `gPInside1/2` initialisers in the binary's data — closes U4 part 2 or
  becomes Q13) + snd 27, ≥ 60 ticks. Main menu (`_Interface @ 0000b500`, `_DrawMainMenu @ 00009eb3`): PICT 913 centred,
  PICT 9012 at L229 T187 R411 B201, buttons from PICT 9100 (normal x 0, highlighted x +150) to Rect 1–6 destinations
  (Register omitted, Invariant 5); keys N/Return/Enter, D, S (option-click → reset request), P, C (+modifiers → secret pages),
  Q, L, B (snd 47), W (snd 46), X (poem request), Z (quote request); ⌘-held keys ignored; mouse tracking = highlight while
  pressed, act on release inside, snd 17 (`_HandleMSMouse @ 0000b001`); logo rect L171 T25 R469 B173 inset 5 modifier-click →
  credits; option-click info box → random egg message + snd 0. Info box (`_DrawInterfaceText @ 0000898d`) L157 T425 R482
  B445, 50 % darkened, border RGB (0xffff,0x9999,0), Geneva 9 centred, cyan (0x111) — cycles msgs 0–3 every 180 ticks (msg 2
  = "Registered To: <name>" — Q15); messages 4–33 transcribed as far as `DC` shows them (U3). Menu stars
  (`_ProcessMenuStars @ 0001075d`): 30 slots, 26×26 set 0x28, spawn at mouse −13 ± 10 when moved ≥ 2 ticks apart, frames
  1–6 one per > 3 ticks. Idle 1200 ticks without input → Demo, Scores, Demo, … (`bVar2` toggle); `_DemoButton @ 0000af71`:
  FILM id = counter+1, counter mod 4, initial 0 (U10 → Q11). Title music: `load(set: 3)`, start if bool 0x40 and not
  playing. New Game: snd 36, stop+unload title music, `GameSession(.play, startLevel: 1)`. Level select (`_DoLevelSelect
  @ 0000d31e`): request DLOG 160 with range 2…short 0x3a; out of range → beep; snd 22 on open. Demo end / game end →
  `_DrawMainMenu` + `wipe(12)`, stars reset; game end → C7's high-score check first.
- **Tests:** `testSplashTimings`, `testMenuButtonRectsAndSources`, `testKeyNStartsGame`, `testCommandHeldKeysIgnored`,
  `testButtonActsOnReleaseInside`, `testIdleAlternatesDemoScores`, `testFilmCounterCycles1to4`, `testInfoBoxCycles180Ticks`,
  `testMenuStarsSpawnAndAnimate`, `testHiddenKeysSounds`, `testLevelSelectRangeAndCheatFlag`, `testDemoEndsOnKey`.
- **Verify:** G1 194/0; G4 no diff.

### C7 — minor — Core: high-score entry + screen, credits (+8 → 202)
- **Files:** `FrontEnd/{HighScores,Credits}.swift`, tests `HighScoreScreenTests.swift`.
- **Contract:** Game end → `_CheckHiScore` (start level 1, not cheating, not demo; Esc-quit games too): pattern-4 overlay
  (`GetIndPattern(0,4)`, patOr — Q12), request DLOG 1000 (snd 13), default text = slot-0 name, max 10 chars, typing snd 1,
  arrows/backspace snd 6, OK snd 15 → C5 insert → scores screen (snd 19). `_DisplayHiScores @ 00025733`: PICT 912 centred,
  PICT 9020 at L209 T80 R431 B117, headers Name x116 / Score x337 / Level x451 at y145 (Letters font), rows y 188+35·i,
  new entry flashes 6× (5-tick halves), `wipe(12)`, 600 ticks or key/click (snd 17), N = new game. Credits
  (`_DisplayCredits @ 0002145a`, `_CreditsButton @ 0000ae16`): pages 0–13, 240 ticks each; ctrl/option/⌘/shift → secret
  pages 14–22/23–26/27–29/30–33 + snd 38/40/44/39; page strings transcribed verbatim from `DC` (e.g. "Coding + Design
  Maestros", y 200); N = new game, other key/click returns.
- **Tests:** `testHighScoreOnlyFromLevel1`, `testEntryDialogRequestDefaults`, `testScoresScreenLayoutOps`, `testNewEntryFlashes6`,
  `testScoresTimeout600`, `testCreditsPageTiming`, `testSecretPagesByModifier`, `testCreditsNStartsGame`.
- **Verify:** G1 202/0.

### C8 — minor — Core: pause cheats (+6 → 208)
- **Files:** `Session/Cheats.swift`, `Session/Pause.swift`, small public mutators on `GameState` (score, lives, EXTRA, multiplier,
  end level, regenerate, invisibility, capture all — each transcribed from the cheat's call in `_PauseGame`), tests `CheatTests.swift`.
- **Contract:** while paused, typed chars feed a 5-char buffer seeded "OOGLE" (`DC` 15115); hash
  `(c0+410)(c1+106)(c2+333)+3+(c3+280)(c4+560)` (transcribe the exact integer arithmetic/overflow from `_PauseGame`) matched
  against the 24 hashes of FI §3h → effect + confirm snd 0; all set `gHacked`, the listed ones set `gPlayerIsCheating`. OS X
  build semantics: daddy mode sets its flag only (15 fps path is non-OS X); frame-limit toggle → unthrottled frames (App runs
  frames on a 0.001 s timer, the `ReceiveNextEvent` spin); FPS cheat → `DrawOp.fps` bottom-right, red < 30; star burst draws
  nothing (orbit stars invisible on Intel). Plain-text codes unknown (U2 → Q2): the hash check is implemented so any real
  code works.
- **Tests:** `testBufferSeedOOGLE`, `testHashFormula` (vector from the formula), `testExtraLetterCheats`, `testMultiplierCheats`,
  `testCheatSetsCheatingFlag`, `testUnknownStringNoEffect`.
- **Verify:** G1 208/0; G4 no diff.

### A2 — ⚑ MAJOR — App: front end wired (splash → menu → game/demo/scores/credits)
- **Files:** `BTXController.swift`, `BTXAudio.swift`, `CoreTextRasterizer.swift`.
- **Contract:** launch → `FrontEnd` splash (replaces A1's straight-to-game); main menu idle loop on the 1/60 timer; mouse
  (`logicalMouseLocation`, `mouseDown`/`mouseUp` forwarded — add `mouseUp` forwarding to K1's protocol extension if absent,
  as a K1 follow-up commit), `crsr 200` hand cursor in menus (decode via HectorGraphics if the kit has `crsr`, else Q16),
  modifier-aware keys (`keyDown` + autoKey both, FI §4); demo: cursor visible, any key/mouse ends; app deactivate → suspend
  music / pause game / end demo (FI §1e). Info-box text through `CoreTextRasterizer` (Geneva 9; Geneva ships with macOS).
  `ShellRequest.highScoreEntry` → A4's dialog. Prefs/high scores saved at every `_LoadLevel` (C4 emits `.savePrefs`), menu
  toggles, prefs Save, quit via menu.
- **What Ben checks:** splash logo, title screen, buttons highlight, mouse-trail stars, 20 s idle → demo then scores.
- **Verify:** G2, G5.

### A3 — minor — App: menu bar, full screen, lifecycle
- **Files:** `BTXMenus.swift`, `BTXController.swift`.
- **Contract:** menu bar transcribed from `English.lproj/main.nib` "MenuBar" (read the nib XML; FI §1c is the summary):
  app menu (About Bubble Trouble X = standard panel with `AboutCredits1.rtf` — Aki Known delta 5 precedent; Preferences… ⌘,;
  Hide/Quit; **no** Register/Check for Updates — Known delta 1), Edit (standard, for dialog fields), Options (Full Screen ⌘F
  ✓ bool 0x37; Sound Effects ✓ with its nib key equivalent; Music ⌘M ✓; Key Sets ▸ "Default" + separator + user sets ✓ short
  0x38), Window (standard). Toggle semantics: SFX off stores 1 and restores short 0x34 (music 0x35/0x36), saves prefs
  (`_HandleMenuChoice @ 0000a482`). About/Preferences/Full Screen disabled in play, enabled while paused. Full screen:
  `enterFullscreen()`/`exitFullscreen()` (D3: fill the main screen, integer-crisp, no display-mode switch — Q8); at launch if
  bool 0x37. Quit via menu/AE saves prefs; ⌘Q in play quits without saving (`_PlayGame`). Suppress AppKit additions per D4.3.
- **What Ben checks:** the menus read like the original's; ⌘F toggles; Music/Sound toggles stick.
- **Verify:** G2, G5.

### A4 — ⚑ MAJOR — App: dialogs and Preferences window
- **Files:** `BTXDialogs.swift`, `BTXPrefsWindow.swift`.
- **Contract:** a Carbon-dialog builder from `DLOG`/`DITL` (HectorGraphics `Ditl`; rects in dialog coords, PICT items via
  `ArtBank`, static/edit text, buttons, default ring), modal, floating level windowed / shielding level in full screen (FI §1d).
  Dialogs: 160 Level Select ("Go go go!" → snd 36 + start), 1000 High Score Name (≤ 10 chars + beep, sounds per C7), 1001
  High Score Erase (Reset → C5 defaults, snd 18 + 39), 200 Key-set name (default "Sheryn"; ALRT 201 if ≥ 10 chars, ALRT 202
  at 20 sets), 290/291 PICT 8001/2910, ALRTs 203/204/205. Preferences (DLOG 190, `_PrefsDialog @ 0000ea93`): header PICT
  7000, area icons cicn 1000/1001/1002 switching DITL 191/192/193, Save/Cancel/Defaults/Revert, help line from STR# 132–135;
  Sound area popups MENU 1001/1000 + "Title screen music"; Keys area five key fields capture virtual key codes, New Set…/Delete
  Set, Key Sets popup MENU 1009; Game area Full screen / Show Bubbles / Show Stars / Hold Escape to exit. Item ↔ pref wiring
  read from the dialog filter (closes U9). Esc → Cancel (D6.2 precedent). snd 22 on open.
- **What Ben checks:** each dialog's look and wording; key redefinition works in play.
- **Verify:** G2, G5.

### A5 — minor — Stage + Ben's play gate
- **Files:** `tools/stage-btx.sh` (final), `BubbleTroubleX/WHAT-TO-EXPECT.md`, `docs/STATE.md`, handoff.
- **Steps:** G1 208/0, G2, G3 (HK main), G4; stage → `out/BubbleTroubleX/` + `~/Desktop/Bubble Trouble X.app` +
  WHAT-TO-EXPECT (keys, Caps Lock pause, Esc, Known deltas, the questions Ben is asked); G5; never delete the prefs domain
  `com.ambrosiaclassics.bubbletroublex` after Ben has played (his high scores live there). **STOP for Ben.**

---

## Dependency graph and parallel lanes

```
T0 ─┬─ Lane K (HK worktree, branch btx-shell):  K1 ──► K2 ∥ K3 (disjoint files; ff-merge each after rebase)
    ├─ Lane S (Classics wt "btx-sim"):           C2 ──► C3 ──► C4 ─────────────► C8
    ├─ Lane D (Classics wt "btx-data"):          C1 ──► R1 (SoundBankPCM step needs K2) ──► C5
    │                                                   (R1 golden for frame 1 needs C3 merged)
    └─ join ─► A1 (needs K1,K2,K3,C1,C2,C3,C4,R1)  ══ M1 FIRST PLAYABLE ══
                 ├─► C6 (needs C4,C5) ──► C7 ──► A2 ──► A3 ∥ A4 ──► A5 (needs C8 too)
                 └─ Lane S continues C8 in parallel with C6/C7
```
- **Parallel now:** K (kit), S (sim plumbing), D (data/render) — three implementers, disjoint repos/dirs (S touches
  `Sim/` + `Session/`; D touches `Data/`, `Prefs/`, `BubbleTroubleRender/`, `Package.swift`). Only shared file: `Package.swift`
  (D only). `FrameReport` fields are added by S only.
- **Serial by necessity:** C2 → C3 (both edit `Sim/*` sites and `FrameReport`); C6 → C7 (shared `FrontEnd`); A-tasks share
  `BTXController` except A3 (`BTXMenus`) ∥ A4 (`BTXDialogs`/`BTXPrefsWindow`) — each touches `BTXController` only through one
  small hook; rebase the second.
- **M1 task set:** T0, K1, K2, K3, C1, C2, C3, C4, R1, A1 (10 tasks, critical path T0→C2→C3→C4→A1).
- **Full loop:** already inside M1 (C4 carries level-to-level, lives, game over, countdown). **Front end:** C5–C8, A2–A4.

---

## Known deltas / out of scope (disclose up front)
1. Registration, Sparkle "Check for Updates…", the ASW About-box bundle, the unregistered nag paths — not built; the replica
   behaves as registered; About = AppKit panel with `AboutCredits1.rtf`.
2. **Level editor:** the 1.1 game app has none — `BT Level Editor.app` is a separate program in `extras/` (with `BT Editor
   read me.txt`). Out of scope for this plan: it is its own app with its own UI, and Ben's measure is playing the game.
3. Custom-level play (the "^" high-score badge, PICT 9077) is reachable only with editor-made level files → out of scope with 2.
4. Full screen fills the main screen (integer-crisp, black border) instead of switching the display to 640×480 (D3.3; Q8).
5. InputSprockets, "OS 9 Drawing" (QuickerDraw), mode-2 recording, orbit stars (invisible on Intel anyway) — not built.
6. Prefs live in UserDefaults under the replica's bundle id; a surviving original prefs file is imported once (C5).
7. FILMs 2–4 end with the hero dying (D8): the attract mode shows exactly what the core replays; not "fixed" here.
8. Sound Tool channel stealing (U5) is an informed default (Q6), not a transcription.
9. CURS 256–263 (the spinning cursor) are not built: their only user, `_SpinMyCursor @ 00025c1b`, has no caller in the
   binary (A2, R10).
10. `_WatchCursor` (the system watch, `GetCursor(4)`, during the windowed splash) shows the arrow: AppKit has no public
    busy cursor (A2).

## Questions (defaults in force until Ben rules)
| Q | question | default | who |
|---|---|---|---|
| Q1 | PICT 913 (title), 9030/9031 (pause lines) — what do they say/look like? (U1) | render them as decoded; Ben compares with memory | Ben |
| Q2 | Do you remember any pause cheat codes? Only hashes are known (U2) | hash check implemented, any real code works; none advertised | Ben |
| Q3 | Pause = Caps Lock *state* (paused while engaged) | as the code reads (`GameKeyDown(0x39)` = lock state) | Ben (feel) |
| Q4 | ⌘M is both Options ▸ Music and Window ▸ Minimize (U6) | menus as the nib; AppKit matches menus left→right, so Music wins | Ben |
| Q5 | Sound Effects key equivalent "A" — ⌘A collides with Select All (U6) | transcribe the nib literally; Edit precedes Options → Select All wins outside text fields too (as the original would) | Ben |
| Q6 | 4-channel priority/stealing (U5) | free voice → else steal lowest priority ≤ new → else drop | Ben (ear) |
| Q7 | Game speed: 0.033 s timer = 30.3 fps (NR-11 delivered rate unknown) | 30.3 fps, missed frames dropped | Ben (feel) |
| Q8 | Full screen: fill main screen vs switch to 640×480 | fill, integer-crisp (D3 precedent) | Ben |
| Q9 | Info-box messages 4–33, occasion texts, birthday dialogs (DLOG 3000/3001) (U3) | transcribe what `DC` shows; birthdays built from `_DoBirthdaysCheck @ 0000c78e` dates if readable, else omitted | orchestrator, Ben sees |
| Q10 | Joke-name pairs (U11) | transcribed in C5 from the compare chain | orchestrator |
| Q11 | First demo = FILM 1 (U10, counter starts 0) | FILM 1 first | Ben (memory) |
| Q12 | High-score overlay "pattern 4" look (U4) | the classic System pattern list item 4 if the bits are recoverable, else a 50 % checker; Ben compares | Ben |
| Q13 | Progress-bar colours (U4) | read from the binary's initialised data in C6; grey ramp if unreadable | Ben |
| Q14 | Sprite set 0x20 (enemy icons) and snd 12/29 (U7) | unused — not drawn/played | orchestrator |
| Q15 | Info msg 2 "Registered To: <name> [n copies]" — what name? | the macOS account's full name, "1 copy" | Ben |
| Q16 | Hand cursor `crsr 200` — kit has no `crsr` decoder? | add a tiny decoder in Render (1-bit/colour crsr = cicn-like) or fall back to `NSCursor.pointingHand`; ask | Ben |
| Q17 | Commit BTX's original data to git? | **closed for this lane:** the session brief says game data (Resources/, ghidra/*.c, out/) never enters git; stage from `BTX_DATA`/`$BTXR` | Ben (brief 2026-10-04) |

## Ben's play gates (honesty gates — his eyes/ears only)
1. **M1 (after A1):** "level 1 onwards plays like Bubble Trouble" — controls, push/thud, enemy behaviour, speed, sounds,
   music, dying, game over, time-bonus count-down. Rulings → DECISIONS.
2. **Final (A5): "it plays like Bubble Trouble X"** — splash → title → New Game → several levels → game over → high-score
   entry → scores; Prefs (keys, sound), Caps Lock pause, Esc, ⌘F; Q1–Q17 answered where he can.
3. **Attract demo (NR-10):** watch our demo 4 — the hero is caught about 15 s in (frame 447). **Needs Ben's eyes on the
   original too** (the 1.1 UB app under Rosetta/an Intel Mac or an archive capture): does the original's demo 4 also end
   with the hero caught ~15 s in? Same question for demos 2 (≈ 21 s) and 3 (≈ 36 s). Yes → the replica is faithful and the
   core goldens freeze (core plan Task 11.5); no → the D8 side lane reopens. Nothing in this plan changes either way.
4. **FILM 1 flag:** demo 1 completes its level ~2 s before its recording runs out (`end = count,level`, frame 1167 of 1227);
   the demo then ends on level completion +70 frames. Ben: does the original's demo 1 also end right after clearing the level?

## Execution notes
- One Opus implementer per task, in its lane worktree; reviewers per the legend; orchestrator merges, re-runs G1–G4 at the
  merge head, updates STATE the same session, ends with a handoff + `spawn_task` chip (fable-kit method).
- If a gate number differs from this plan: STOP and report — do not edit expectations to fit.

---

## Amendments after plan review (2026-10-04, orchestrator rulings — override the task text above)

- **R1 (T0 grows shared types).** T0 also lands, in `BubbleTroubleCore`, the LOCKED seam *types* with no behaviour:
  `SoundCue`, `MusicCue` (+ `case volume(Int)`, see R6), `DrawOp` (all S2 cases), `FrameReport.sounds`/`.drawOps` (always
  empty until C2/C3), `HeldKeys`, `KeyModifiers` (replaces the undefined `ShellModifiersLite`: `command, shift, option,
  control, capsLock: Bool`), `SessionOutput`, `ShellRequest`, `SessionEnd`, `GameMode`. Tests +2 (`testSeamTypesEquatable`,
  `testFrameReportDefaultsEmpty`) → T0 total 132; every later expected total shifts by +2 (C1 138 … C8 210). T0 is then a
  minor *code* task with one Opus reviewer. This lets lanes S and P run in parallel.
- **R2 (dependencies).** C4 needs C1 (`BTXGameData`) and C5 (`BTXPrefs`, key sets 2–8, bool 0x3d Esc-hold, short 0x3a
  level-select max). New lanes: **D** C1 → C5 → R1; **S** C2 → C3; **P** C4 starts when C1 + C5 are merged (parallel to
  C2/C3; C4 touches `Session/` + `LevelBuild.swift`'s `newLevel` visibility only — S must not touch `LevelBuild.swift`).
  A1 joins after K1–K3, C1–C5, R1. Canonical order for totals: T0, C1, C5, C2, C3, C4, R1, C6, C7, C8 — expected total =
  132 + Σ N of merged tasks; the orchestrator states the number in each dispatch.
- **R3 (countdown).** `_TimeBonus_CountDown`: snd 41 when bonus ≥ 10001 (`< 0x2711` test), snd 42 when 0. Each chunk also
  calls `_AdvanceFrameCounter` and `_DrawReserveInfo` three times (the bonus-digit flash timer reads that counter) —
  transcribe the loop body exactly. Input is ignored throughout (busy `_WaitFor`).
- **R4 (music fade blocks).** `_StopMusic` fade is a blocking loop, −5 per tick (≈ 52 ticks from 0x100), no frames run.
  The session models it as a tick phase `.musicFade` that emits `MusicCue.volume(v)` each tick and enters `.countdown`
  only when it reaches 0. The App applies volumes; it never fades on its own. Same for any other `_WaitFor` blocking
  sequence: tick phases, input ignored.
- **R5 (window).** `CreateNewWindow(6, 0x2800000)` → `ShellWindowController` with `styleMask: [.titled]` only (no close,
  no miniaturize, no resize). If the kit init lacks a style-mask parameter, K1 adds it additively. Q4 closes: no Window ▸
  Minimize to collide with ⌘M — but read the nib, the Window menu may still list it; transcribe the nib.
- **R6 (K1 keyboard edges).** Caps Lock state is read from `NSEvent.modifierFlags` (polled each frame via
  `ShellKeyState.capsLock`, so a lock already on at launch counts). Keys pressed while ⌘ is held receive no keyUp: when ⌘
  is released, drop from `held` every key whose keyDown arrived with ⌘ down. K1 also forwards `mouseUp` (default no-op).
  HectorKit main is being edited by the Remaster session (ShellView/ShellBitmap scale factor): K1 rebases onto HK main
  immediately before merge and keeps edits additive.
- **R7 (⌘Q in play).** The original quits without saving prefs when ⌘Q is pressed in play. The App's terminate path
  checks `session.phase` — in `.playing` it skips the prefs save; elsewhere it saves.
- **R8 (pause details).** `_PauseGame` also calls `_DisableAboutMenu` (About stays disabled while paused — A3 corrected),
  sets the `crsr 200` cursor, and restores the mouse position on exit; C4 item 7 adds both as `ShellRequest`s.
- **R9 (resources).** cicn 1000–1002 + 128 and snd 9047 live in `Bubble Trouble X.rsrc`, not the sprite/sound files —
  `ArtBank` and `SoundBankPCM` load across all five files. The SpIc count field is stored n−1 (reads 51 for 52 sets).
  S5 adds `BubbleTrouble.icns` (Info.plist `CFBundleIconFile`).
- **R10 (unlisted resources).** ALRT 206–218 → A4 (transcribe every ALRT the code shows, with its call site); CURS 256–263
  → A2 (find their use in `DC`; if unused, list them as Known delta, not built).
- **R11 (project.yml).** S4 is a *merge* into the existing top-level `packages:`/`targets:`/`schemes:` keys; never a second
  copy of those keys (it would replace Aki's).
- **R12 (K2 ruling).** K2 reverses the kit's "no IMA4 codec — CoreAudio decodes natively" note in `SndSound`'s doc comment;
  K2 records that in HectorKit `docs/DECISIONS.md` (next free number there) with the reason: one Foundation-only decode
  path for every shell.
- **R13 (Q17).** Closed by Ben's brief for this lane: original data never enters git; staging copies it (D10 permits
  shipping). (The older "shareware data goes in git" preference is not exercised here.)
- **R14 (M1 critical path).** K-lane runs in parallel from the start, so sound is not on the critical path. If C2/C3 slip,
  the orchestrator may stage an interim build from A1 with whatever cues exist — never block Ben's first play on polish.
