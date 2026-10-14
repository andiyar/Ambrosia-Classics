# Plan — Ferazel's Wand Phase 3 "Front end + saves": title, menu, options, world map, chapter and stats screens, save points, Resume/Continue, death screen, conversations, pause and Esc — 2026-10-14

> Status: **DRAFT — planner Opus 5.5, loop run 8 (2026-10-14); awaiting two Opus review legs + one Fable leg (D34)**.
> Implements `docs/plans/2026-10-06-ferazel-design.md` (APPROVED) **§8 Phase 3 only** (+ §9 (d)), written against what
> Phases 1–2 landed (Classics main 1d66b5e: D26 as built, D32, D33 as built through loop run 7; `Ferazel/Core` 256/0).
> **Format (Ben, 2026-10-03): CONTRACTS, not code.** Files, public names (signatures only where they pin a seam),
> behaviour with bank + dump anchors, test names with the number each checks and where it came from, gate commands,
> commit messages. No implementations.
> **Numbers:** every expected value is from the committed dump (`ghidra/ferazel/Ferazel_pef.decompiled.c`, 88,106
> lines, cited "M l. N"; `Ferazel_pef.disasm.txt`, cited "raw XXXXXXXX"), from the original data (decoded by the
> planner's research legs on 2026-10-14 — five digests A front end, B world map, C level start/end, D saves, E talk;
> F = the code/kit inventory; not committed), or is hand arithmetic shown inline. Where the dump disagrees with the
> bank, **the dump wins** (Ben 2026-10-07, "follow the binary") and "Bank corrections to append" says so.
> ⚠️ The bank's M-line citations in `save-continue.md`, `engine.md` and `world-data-format.md` are from an older dump
> (≈ +35 lines drift around 5000–7500, more past 40000). **Use the M lines in this plan.**

**Goal.** Ferazel's Wand starts like the original and goes from the title to level 2 and back the original's way:
the publisher logo and loading bar (PICT 131, PICT 136, the 3-D progress bar), the main menu (PICT 130, clut 130, music
24, five image buttons, keys N/O/R/I/P/C/Q/X), Options (DLOG 6900 with its three panels incl. key remapping), Credits
(DLOG 600), New Game → the chapter card (level 1: PICT 4610, clut 281) → level 1 with the original level-entry sequence
(stage-load popup, gamma fade-out/in, music fade-in) → save points (type 1065) writing the original 965,208-byte saved
game → the exit → the stage-complete panel with its three percentage bars → the world map (PICT 7000, nodes, the new
link animation, the marker walk) → level 2 → Esc/⌘W abort → the main menu → Resume (the saved game) → death → the
death screen (PICT 138, Continue/Abort, WandGlow/TurnGray). In between: Caps Lock pause (PICT 4921), ⌘Q/⌘W/⌘P, the
conversations (Mcnv) and signs (STR# 500) placed on levels 1–2, the prefs file (`'Pref'` 0, 0x942 bytes), the menu bar
(MBAR 128). **Ben's gate: "title → level 2 and back."**

**Scope rulings (D35, recorded at merge; the orchestrator copies the "Rulings" section at the end):**
- **In:** design §8 row 3 in full, design §9 (d) (a save naming a missing level is refused with a dialog), and the
  Phase 2 carries listed under "Phase 2 carries owned".
- **Out (later phases, named):** inventory display/selection and pickups (Phase 4: Rojinko's shop writes G inventory
  slots but the HUD keeps showing the start inventory; the USE-item hint texts; the Escape Ring path is built as read
  but unreachable), enemies (Phase 5), bosses + `.Victory` + track-30 rule beyond what Setup already sets (Phase 6),
  InputSprocket (never — design §7.3), resolution switching / DLOG 1300 (never — design §7.1; prefs +0x32/+0x34 kept),
  the CD check, birthday, debug keys (bank out-of-scope; F4 0x76 is NOT a debug key — see L1).
- **Only levels 1 and 2 can be entered (◇ D35 seat stub `BuiltLevels = 1...2`).** The map unlocks and draws every node
  exactly as the original; choosing a node whose level's Setups are not yet transcribed shows a stand-in report
  dialog and stays on the map (F1b). Each later phase widens `BuiltLevels` as it transcribes a level.

**Architecture (design §3, unchanged in shape).** `FerazelCore` gains the **front-end state machines** (a tick-driven
`GameFlow` owning boot, menu, the New Game / Continue loops, `LevelRun`, `WorldMapRun`, the death screen, pause, the
conversation interpreter), the **byte images** of G, the save block and the prefs record, the saved-game and prefs
**file codecs**, and a resumable frame (`FrameSuspension`) for the modal moments the original runs inside a frame.
`FerazelRender` gains a level-less `ScreenRenderer` sharing one `ScreenSurface` with `FrameRenderer`, the timed gamma
fades, the map/stats/chapter/death/pause/conversation drawing and text layout through `TextRasterizer`. `Ferazel/App`
drives `GameFlow` from `ShellClock` ticks, translates mouse/keys/Caps Lock, shows the original's dialogs (adapted from
the BTX `CarbonDialog` precedent) and menus, and reads/writes the prefs and saved-game files. **HectorKit: one small
task (K1)** — a classic resource-file writer in `HectorResources` and `ShellMixer.unload(id:)`.

**Tech:** Swift 6.4 / Xcode 27 beta, SwiftPM tools 6.0, XCTest, macOS 15, xcodegen.

**Paths:**
```
WT      = /Users/andiyar/Developer/Ambrosia-Classics/.claude/worktrees/<lane worktree>   (branched from Classics main)
HK      = /Users/andiyar/Developer/HectorKit   (main 0c65dcb, zero-skip FLOOR 328; written only by K1, own HK worktree)
SCRATCH = the executing session's scratchpad directory (mktemp -d)
DUMPS   = $WT/ghidra/ferazel/Ferazel_pef.decompiled.c ("M l. N"), Ferazel_handlers.decompiled.c,
          Ferazel_pef.disasm.txt ("raw XXXXXXXX") — committed; never regenerated in this phase.
          Function finder: python3 $WT/ghidra/find_func.py '<regex>' --file <dump>.
          Bank tools: FZ_PEF=$WT/ghidra/ferazel/Ferazel_pef python3 $WT/docs/ferazel/tools/{const,pef,tocrefs,rsrc_census}.py
```

---

## Verification model (read first)

**Machine gates — executors close these alone** (copy the fenced commands literally):

| # | gate | expected |
|---|---|---|
| G1 | HectorKit | before K1: clean at `0c65dcb`. From K1 on: clean at **K1's HK local-main SHA** (recorded in STATE by K1), never written by any other task |
| G1k | HK zero-skip floor (K1 only) | `PASS`, Executed ≥ **331** (328 + K1's 3 tests); `FLOOR` bumped to the executed count in the same HK commit |
| G2 | `Ferazel/Core` suite | the task's ladder total, then `0` |
| G3 | census unchanged | `0`, `Totals: items 1,108 decoded, failures 0` (once per wave end) |
| G5 | app builds | `** BUILD SUCCEEDED **` — every task touching `Ferazel/App` or `project.yml`, and every wave end. Aki/BTX/Deimos/Cythera only if `project.yml` or HectorKit changes: **K1 changes HectorKit → K1 builds all five app schemes** |
| G6 | scope fence | ⊆ the task's **Files** (+ `docs/DECISIONS.md` / the bank file named by the task) |
| G7 | layering | both greps empty (`Sources/ferazel-census` excluded); **plus G7b:** no `UserDefaults`, `NSSavePanel`, `NSOpenPanel` in `Ferazel/Core/Sources` |
| G8 | file hygiene | `git -C "$WT" status --porcelain --ignored -- Resources ghidra` prints nothing new; tests write files only under `FileManager.default.temporaryDirectory` |
| G9 | staged app boots (A2) | Phase 2's G9, plus: the boot reaches the main menu (no crash report), quit via the File menu |
| G10 | clean tree per commit | empty |

```sh
WT=$PWD; SCRATCH=$(mktemp -d)
# G1
git -C ~/Developer/HectorKit status --porcelain; git -C ~/Developer/HectorKit log --oneline -1
# G1k (K1 only, run inside the HK worktree)
tools/check-zero-skip.sh | tail -n 3
# G2
cd "$WT/Ferazel/Core" && swift test > "$SCRATCH/fz.log" 2>&1; grep -cE "^Test Case '.*' (passed|failed|skipped) \(" "$SCRATCH/fz.log"; grep -cE "^Test Case '.*' (failed|skipped) \(" "$SCRATCH/fz.log"
# G3
cd "$WT/Ferazel/Core" && swift build -c release --product ferazel-census > /dev/null && "$(swift build -c release --show-bin-path)/ferazel-census" "$WT/Resources/Ferazel" > "$SCRATCH/census.md"; echo $?; tail -n 1 "$SCRATCH/census.md"
# G5
cd "$WT" && xcodegen generate --quiet && xcodebuild -scheme Ferazel -derivedDataPath "$SCRATCH/dd" build 2>&1 | grep -E "BUILD (SUCCEEDED|FAILED)"
# G6
git -C "$WT" diff --name-only "$TASK_BASE"..HEAD
# G7 + G7b
grep -rlE '^import (AppKit|CoreGraphics|AVFoundation|Metal|QuartzCore|SwiftUI|UIKit)' "$WT/Ferazel/Core/Sources" | grep -v ferazel-census
grep -rnE 'UserDefaults|NSSavePanel|NSOpenPanel' "$WT/Ferazel/Core/Sources"
# G8
git -C "$WT" status --porcelain --ignored -- Resources ghidra
# G10
git -C "$WT" status --porcelain | grep -v '^??'
```

**Test ladder (`Ferazel/Core`, cumulative; canonical order = execution order; STOP if different):** base **256** →
K1 256 (HK +3) → X1 **256** → R1 **260** → SV1 **266** → SV2 **272** → FE0 **278** → O1 **283** → L1 **291** → L2
**296** → M1 **304** → M2 **307** → F1a **312** → D1 **316** → F1b **322** → S1 **329** → P1 **334** → C1 **341** → C2
**344** (then A1a, A1b, A2: no tests). Merged in another order: previous total + the task's N. Review fix rounds add
asserts, not tests, unless the orchestrator rules otherwise (recorded "As executed").

**Goldens (◈).** Phase 1/2 goldens (STATE: `9db8f32f7e3d88b4`, `b80b0efd384ffdb9`, pan `172596fa2f3b6c58` /
`cc9786ba763d383a` / chain `b4230ba5a643c5b5`; L2 `565e867a02736c18` / `df22325e851e782d`, jump `e4f4bf977dd98eaa`, swim
`95ff5176412df650`, 600-frame `9532d65a42d39666` / cues `a875a96c2801dbe9`) are **not expected to move in Phase 3**:
every Phase-3 sequence wraps the session (`LevelRun`) and a `FerazelSession` built directly (as all existing tests do)
behaves exactly as today. **No task is ◈.** Any existing golden or count that moves is a STOP (Invariant 10). New
goldens (FE0, M2, C2) are self-derived on first green and re-run twice by the reviewer.

**Honesty gate (Ben only):** the Phase 3 gate card ("title → level 2 and back"). Completion is phrased "machine gates
green; Ben's gate pending".

**What the machine does NOT prove:** dialog look and feel (AppKit panels drawn from DITLs), the Monitor Tool's fade
curves in real time (MED), Times 18 / Times 12 glyph shapes (CoreText stands in for the classic bitmap strikes), the
feel of the menu and map; agents cannot screenshot on this machine.

---

## Non-negotiable invariants

1. **Layering** (Phase 1 Invariant 1 + G7b). Core: Foundation + HectorResources only — state machines, byte images,
   file codecs (`FileManager`/`Data` are Foundation). Render: pixels and text layout via the `TextRasterizer`
   protocol. App: AppKit, HectorShell, file panels, the Application Support folder lookup, `UserDefaults` (hidden
   switches only).
2. **Transcribe, don't reinvent.** Every behaviour cites its bank section and the dump. A contract here never
   overrides the dump: if they disagree, STOP and report; the orchestrator rules under "follow the binary" and
   records a bank correction.
3. **Time is ticks.** Every front-end sequence the original runs on `TickCount` (fades, waits, `Delay(n)`, the map
   loop, typing, the chapter card, the pause loop) is a Core state machine advanced by `tick(now: UInt32, input:)`
   with absolute 60 Hz ticks from `ShellClock.ticks()` (D30 precedent: the replica's tick is 60 Hz). Core never reads
   a clock. **Blocking** original loops (a `GammaFadeOut(6)`, `FadeAIFFMusic(1,4)`'s 96 ticks) block the flow — no
   game step, no input action — for exactly their tick count. Millisecond-timed Monitor-Tool fades convert as
   `ticks = ceil(ms · 60 / 1000)` [MED: library internals, lighting-tables §10].
4. **The in-level cadence moves into Core.** `LevelRun` steps the session when `now − lastStart ≥ 2` (prefs+0 = 0) or
   runs the skipped + drawn pair under the 4-tick cap (prefs+0 ≠ 0) — today's `FerazelController.idleFired` rule
   (engine §4, M l. 5229–5294), moved verbatim. A blocked flow does not accumulate steps (fixed step, no catch-up).
5. **One RNG stream across the whole game.** `GameFlow` owns `FastRand` between levels (seeded once at launch with
   `FastRand.clockSeed`, as today); the map's draws (one `FastRand(15)` per visible node, 3 × 50 per `.DrawNewLink`,
   M l. 66700ff, 67171–67274) and every session consume it in the binary's order. Phase 2 Invariant 4 (sound-rate
   draws at the call site) unchanged.
6. **Modal moments happen where the original has them.** A conversation, a sign, a save-point save and its file
   dialog run **inside** the special collision pass; Esc/⌘Q/⌘W/⌘P/Caps Lock run inside `.CheckGameLoopKeys` (after
   `.PaintFrameWrap`, before `.UpdateSprites`). The session suspends at that point (`FrameSuspension`), the flow runs
   the modal over ticks, and `resume` finishes the **same** frame. Never deferred to the next frame (it would reorder
   their effects on coins, records and the status bar).
7. **Byte-exact persistence.** The save block (0xebe58 = 965,208 B), G (0x19978 = 104,824 B) and the prefs record
   (0x942 = 2,370 B) are written as the PPC laid them out: big-endian, every field at its offset, gaps and
   never-accessed ranges written as **0** (the state of a fresh run's first game; the original leaves some stale —
   digest D §2). Readers accept any well-formed file; no size or version check beyond the original's (none for the
   save; the prefs record grows to 0x942).
8. **Never destroy Ben's state.** Never delete or reset `com.ambrosiaclassics.*` defaults domains (the hidden switches
   `FerazelLevel`, `ColorTieBreak`, `MacGamma` stay there). The prefs and saved games live in
   `~/Library/Application Support/Ambrosia Classics/Ferazel's Wand/` (design §7.5); tests never touch that folder
   (temporary directories only); the staged app may create it.
9. **Seam types are LOCKED** (design §3): cases and fields may be **added**, never renamed or retyped. This phase adds
   exactly the S3 list. `ShellRequest.loadLevel`/`.deathEffect` and `FerazelSession.deathEffectDone()` stay until A1a
   switches the app to `GameFlow` (G5 must hold at every wave end); A1a removes only the Phase-2 ◇ helpers that S3
   marks removable.
10. **STOP on any unexpected number** — test totals, hashes, census lines, digest numbers. Report; never edit an
    expectation or the code to make them agree.
11. **Stubs are named** (`// later: <phase>`), never simplified away. This phase's ◇: `BuiltLevels` (1...2), the HUD's
    start inventory under a G that may hold more (Phase 4), the USE-item hints (Phase 4), `.Victory` (Phase 6).
12. **No modern affordances.** No "are you sure" the original lacks, no autosave, no slots, no skip buttons, no
    remembered menu position, no mouse on the map, no keyboard navigation on the main menu beyond its letters.
    Deviations forced by the platform are listed in "Known deviations" and nowhere else.
13. **Commits.** Explicit paths only; never `git add -A`/`.`; never `git stash`; verify `git branch --show-current`
    before every commit; trailer `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`. G10 after each commit.
14. ⚠️ **Landmines** (Phase 2 Invariant 12 (a)–(g) still apply). (h) D-numbers: this plan's rulings are **D35**; K1's
    HectorKit ruling is **HK D16** — confirm both are free at commit time, renumber in the same commit if taken.
    (i) `Ferazel/FerazelCore` is a symlink to `Core`; the app name has an apostrophe — quote every path.

### Hazards for every implementer (read before any dump reading)
Phase 1 + Phase 2 hazards apply verbatim (`lwzu/stwu` +8 copy loops — the save-block G copy is one: first store at
+0x18, raw `1000c1cc..1000c1e0`; a TOC-load count is not a write count; SSH zeroes per-frame fields; the signed-compare
idiom; live key reads; globals vs fields). Added for Phase 3:
- **Nested blocking loops become explicit states.** The original nests `MainMenu → NewGame → GameLoop ⇄ ShowWorldMap →
  AskToContinue`; a return value or flag (`_DAT_1009fd48` continue-requested, `fd4c` aborted, `fd50` quit, `fe00`
  saved-this-game, `fd54` save-file-known, `fd5c` default world, `ffa8` died, `DAT_100a5106` loop end, `*_DAT_100a0088`
  level complete, `fd64` escape ring) is a named field of `GameFlow`, under the binary's address in a comment.
- **Polled keys, not events.** The original polls `GetKeys` (`IsPressed`) in the menu, the map, pause and the
  conversation loops; it reads ⌘ as key 0x37 (also action 6, use item). AppKit key equivalents must not swallow ⌘Q/⌘W/
  ⌘P/⌘N/⌘O while the original would see them as polled keys (A1b's menu-enable rule).
- **Which screen is current.** One `ScreenSurface` (640×480 indices + screen CLUT + gamma) is shared by the level
  renderer and the front-end renderer; the popup and the stage-complete panel draw over whatever is on it (after the
  map: the map). Never present a second buffer.
- **CopyBits semantics.** `CopyBits` with a smaller/larger destination stretches (QuickDraw nearest-row sampling
  [MED]); `CopyBitsCTForce` forces the source clut; mode **0x24 = transparent** (white source pixels skipped) on the
  conversation frame (raw `10079870`); plain `CopyBits` from a port built on another clut remaps by colour (Color2Index,
  LOW).
- **Slop-8 ports.** `NewBlitPortSlop(640,416,0,8)` puts blit (x, y) at QuickDraw (x+8, y+8): a 24×24 map node face
  blitted at (h−20, v−20) is centred on (h, v); map point (h, v) lands at screen (h+16, v+8) (digest B §1).
- **Mac Roman.** STR#, Mcnv, DITL text and the prefs pstrs are Mac Roman; `HectorResources.MacRoman` decodes. Widths
  in the conversation wrap are per byte.
- **Two PICT 7000s.** The app fork's copy is drawn (save-continue §8.4); the `.frontEnd` chain (Sprites → Sounds →
  Titles → app) resolves it correctly; never load it through `.level`.

---

## Shared architecture (LOCKED — every task codes against these names)

### S1. Package `Ferazel/Core` — unchanged targets
New folders: `Sources/FerazelCore/{Front,Saves,Talk}/`, `Sources/FerazelRender/Screens/`; `Ferazel/App/Dialogs/`.
New test files named per task. No new target.

### S2. FerazelCore additions (★ LOCKED after Phase 3; ◇ = Phase-3 stub, replaced later)
- ★ `GameGlobals` (SV1) — keeps every existing field name; gains every G field of digest D §2 by name with its offset
  (`darknessOverride` +0x20 u8, `savedDarkness` +0x22, `inventory: [InventorySlot]` 27 × 10 B at +0x24, `omniPxActive`
  +0x174, `hasSnapshot: [Int16]` +0x176 ×100, `unlocked: [Int16]` +0x23e ×100, `achieved: [[Int16]]` 5 × 100 at +0x306
  + 200k, `totals: [[Int16]]` 5 × 100 at +0x6ee + 200k, `worldFlags: [Int16]` +0xad8 ×1024, the crunch arrays as
  today's `crunchLog`), `static let byteCount = 0x19978`, `init(image: Data) throws`, `func image() -> Data`,
  `static func initGameGlobals() -> GameGlobals` (`.InitGameGlobals @ 10001498`, M l. 582–812).
- ★ `SaveBlock` (SV1, `Saves/SaveBlock.swift`) — `static let byteCount = 0xebe58`; fields `worldStamp`, `preview`,
  `demo`, `isCheckpoint`, `level`, `playerX`, `playerY`, `globals: GameGlobals`, `date`, `snapshots` (100 × 511 × 16 B),
  `worldName`; `init(image:)`, `image()`; `mutating savePointSave(...)` / `endLevelSGUpdate(...)` (the shared write
  core, M l. 6322ff / 6501ff) and `restoreSnapshot(level:into:)` (+6).
- ★ `PrefsRecord` coding on `FerazelPrefs` (SV2) — `FerazelPrefs.init(record: Data)`, `record() -> Data` (0x942,
  unknown bytes preserved), `savedGameName` pstr, `recentNames` (+0x142, 8 pstr[256], write-only).
- ★ `SavedGameFile`, `PrefsFile` (SV2, `Saves/`) — resource-file codecs over HK K1's writer and `ClassicResourceMap`.
- ★ `DialogResources` (R1, `Front/DialogResources.swift`) — Foundation-only parsers: `DialogTemplate` (DLOG/ALRT),
  `DialogItemList` (DITL items with type, rect, text, resource id), `ControlTemplate` (CNTL), `MenuTemplate` (MENU with
  items, ⌘ keys, enable flags), `MenuBarTemplate` (MBAR).
- ★ `ScreenFade` (FE0, `Front/ScreenFade.swift`) — the global fade state the original keeps in `*_DAT_1009fde8`
  (screen faded), `DAT_100a53d6` (no async fade running), `DAT_100a53c2` (fading enabled) and the timelines of
  `.GammaFadeOut(n)` / `.GammaFadeIn(n)` / `.GammaFadeInSlow(n)` (lighting-tables §10; digest A §1).
- ★ `MusicFade` (FE0, `Front/MusicFade.swift`) — `.SetAIFFMusic` (start at volume 0, `ShutDownAIFFMusic` first),
  `.FadeAIFFMusic(dir, t)` blocking (24 steps, V·s/24 / V·(24−s)/24, V = prefs+0x10·256/9, gates `*0448`),
  `.FadeAIFFMusicAsync(dir, N)` (digest C §6) — emitting `MusicCue`s.
- ★ `GameFlow` (F1a/F1b, `Front/GameFlow.swift`) — `final class GameFlow { init(resources:prefs:seed:files:) ;
  func tick(now: UInt32, input: FrontInput) -> FrontOutput ; func dialogDone(_ result: DialogResult) ; func
  fileDone(_ result: FileResult) ; var state: GameFlow.State }`; owns `FastRand`, `GameGlobals`, `SaveBlock`,
  `ScreenFade`, the flags above. `FrontInput = { keys: KeyState, capsLock: Bool, mouse: (h: Int, v: Int)?, button:
  Bool, active: Bool }` (mouse in 640×480 canvas coordinates; nil outside the canvas). `FrontOutput = { draws: [DrawOp],
  sounds: [SoundCue], soundStops: [Int16], soundStopAt: [Int], music: [MusicCue], requests: [ShellRequest], present: Bool }` (the same play/stop interleave rule as `FrameOps.soundStopAt`). `Rect16` (FE0, `Seams/Rect16.swift`) = QuickDraw rect `{top, left, bottom, right}: Int16`.
- ★ `LevelRun` (L1, `Front/LevelRun.swift`) — wraps one `FerazelSession`: entry sequence, cadence (Invariant 4),
  suspensions, exit sequence; reports `LevelEnd { case died, completed(exit1: Int16, exit2: Int16), aborted, quit }`.
- ★ `StageScreens` (L2, `Front/StageScreens.swift`) — `.ChapterScreen`, `.PopupStageLoad`/`.UpdateStageLoad`,
  `.StageCompleteEffect`, `.CalcPercent`, `.FillPercent` as tick machines.
- ★ `WorldMapRun` (M1, `Front/WorldMapRun.swift`) — `.ShowWorldMap` and callees as a tick machine; returns the level
  number or −1.
- ★ `DeathScreen` (D1, `Front/DeathScreen.swift`) — `.AskToContinue`, `.TrackClickOnCommandButtonDeath`, `.WandGlow`,
  `.TurnGray`.
- ★ `PauseRun` + `GameLoopKeys` (P1, `Front/Pause.swift`) — `.CheckGameLoopKeys`, `.Pause`.
- ★ `PrefsDialogModel` (O1, `Front/PrefsDialogModel.swift`) — the logic of `.PreferencesDialog`/`.UpdatePrefsPanel`/
  `.PrefDialogFilter`/`.AlreadyUsingKey`/`.ConvertKeyName`; the App renders it.
- ★ `ConversationRun` (C1, `Talk/ConversationRun.swift`) — `.Conversation`/`.HandleConvLine`/`.HandleLineResponses`/
  `.HandleLineActions`/`.SimpleConv` as a tick machine over the existing `Conversation` parser.
- ★ `FrameSuspension` (S1, `Seams/FrameSuspension.swift`) + `FerazelSession.resume(_:) -> FrameOps` (S1) — see S3.
- ◇ `BuiltLevels` (F1b, `Front/BuiltLevels.swift`) — `static let range = 1...2` (D35 seat stub).

### S3. Seam additions (cases/fields ADDED only; Invariant 9)
```swift
// DrawOp — new cases (FE0 unless noted)
case fillRect(left: Int, top: Int, right: Int, bottom: Int, rgb: RGB16)          // PaintRect in a colour (Color2Index)
case copyPicture(id: Int16, chain: ResourceChain, source: Rect16, dest: Rect16, forceClut: Int16?,
                 transparent: Bool)                                              // CopyBits / CopyBitsCTForce / mode 0x24
case drawFace(set: FrontFaceSet, index: Int, h: Int, v: Int)                     // map node / marker faces (M2)
case drawLine(h1: Int, v1: Int, h2: Int, v2: Int, rgb: RGB16)                    // map links (M2)
case drawText(TextRun)                                                           // TextRun = {bytes, font, size, face, h, v, rgb, mode}
case restoreView                                                                 // .WrapCopyToScreen of the last drawn frame (C2)
case screenGamma(ScreenGammaOp)                                                  // tint fade %, FadeToColor %, identity (FE0)
// FrameOps — new field: suspension: FrameSuspension? = nil                     (S1)
// FrameSuspension — enum { savePoint(record: Int), conversation(id: Int16, record: Int, sprite: Int),
//                          sign(text: [UInt8]), gameLoopKeys(GameLoopKeyEvent) }  (S1; P1 adds gameLoopKeys)
// ShellRequest — new cases: dialog(FerazelDialog), putFile(PutFileRequest), getFile(prompt: String), quit,
//                showMenuBarItems(MenuState)                                   (FE0; F1b, S1, P1, A1b use them)
// FerazelDialog — enum { confirm(text: String) /*DLOG 202*/, report(text: String) /*DLOG 200*/,
//                        error(text: String, code: Int16), preferences, credits }
//   (.preferences carries no payload: the flow owns O1's PrefsDialogModel and the App reads it through GameFlow)
// MenuState — struct { menusLive: Bool /*main-menu or pause loop*/, paused: Bool, musicOn: Bool, soundOn: Bool } (FE0)
// SoundCue, MusicCue — unchanged (fades are .volume(Int) cues at their ticks; .play starts at volume 0 from A1a on)
// Removable at A1a (Phase-2 ◇ only): LevelFlow.phase2Level/exitRequest, FerazelSession.deathEffectDone() +
//   restartWithFreshGlobals, the App's `Ending` struct. ShellRequest.loadLevel/.deathEffect cases STAY (locked).
```

### S4. FerazelRender additions
- `ScreenSurface` (FE0, `Screens/ScreenSurface.swift`) — `final class` holding the 640×480 `IndexedFrame`, the screen
  CLUT and the `ScreenGamma`; `FrameRenderer.init(…, surface: ScreenSurface? = nil)` (defaulted: today's tests build
  their own); `presentedClut` reads it.
- `ScreenRenderer` (FE0) — level-less executor of the S3 front-end ops onto a `ScreenSurface` (full-screen PICTs under
  a clut via `ConvertedPicture`, stretched rect copies, fills/lines/text through `ColorSearch`), the timed gamma
  (`ScreenGamma.tintFade(mode: 3, percent:)` = `.TintFadeProc` red-first, lighting-tables §10).
- `TextRasterizer` gains `charWidth(_ byte: UInt8, font:size:face:) -> Int`, `fontInfo(font:size:face:) ->
  (ascent: Int, descent: Int, leading: Int)` and per-character drawing (C2); `TextLayout` (C2) = the 214-px wrap
  (`.DrawConvTextString`) and TextEdit line heights.
- `MapRenderer` (M2), `ConversationRenderer` (C2), death/pause/stats/chapter drawing in `ScreenRenderer` (L2, D1, P1).

### S5. App (A1a, A1b)
`FerazelController` drives `GameFlow.tick(now: ShellClock.ticks(), input:)` from the 240 Hz idle timer; presents the
shared `ScreenSurface` when `present`; honours requests (dialogs, file panels, quit, cursor, menu bar);
`FerazelAudio` handles `MusicCue` with `.play` starting at volume 0 and `.stop` unloading the track (K1). Dialogs in
`Ferazel/App/Dialogs/` (adapted from `BubbleTroubleX/App/BTXCarbonDialog.swift` + `BTXDialogResources.swift` patterns,
on R1's `DialogResources`); menus from MBAR 128.

---

## Tasks

Legend as Phase 2: ⚑ MAJOR = **two Opus review legs** (spec/fidelity, then quality/mutation); minor = one Opus leg.
"→ N" = ladder total after the task. Sections are in the canonical order, which is the execution order. Every task:
G2, G6, G7(+b), G8, G10; G3 once at each wave end; G5 in every task that touches `Ferazel/App`, and at every wave end.
**All implementers and reviewers are Opus 5.5 (D34).** Each task's precondition: read the named bank sections, then
**re-read the named dump ranges** before writing code; the digests' numbers in this plan are the planner's reading,
not a substitute.

### Wave 3.0 — kit and foundations (nothing visible changes)

#### K1 — minor — HectorKit: classic resource-file writer + `ShellMixer.unload` (Classics → 256; HK floor → 331)
- **Repo:** HectorKit, own HK worktree (`git -C ~/Developer/HectorKit worktree add …`, D34); ff-only to HK **local**
  main; never push. Classics side: STATE pins the new HK SHA (in the run's close).
- **Files (HK):** `Sources/HectorResources/ClassicResourceWriter.swift` (new), `Sources/HectorShell/ShellMixer.swift`,
  the matching test files under `Tests/` (one new `ClassicResourceWriterTests.swift`, one test added to the mixer
  tests), `tools/check-zero-skip.sh` (`FLOOR` → the executed count), `docs/DECISIONS.md` (**HK D16**).
- **Contract:** `ClassicResourceWriter.encode(_ resources: [ResourceEntry]) -> Data` where `ResourceEntry = {type:
  FourCharCode-as-4-bytes, id: Int16, name: [UInt8]? (Mac Roman pstr), attributes: UInt8, data: Data}` — the standard
  resource-fork layout (Inside Macintosh: More Toolbox, "Resource Manager": 16-byte header {data offset 256, map
  offset, data length, map length}, 240 reserved bytes (zero), data area of length-prefixed bodies, map {header copy,
  next-map 0, file ref 0, attributes 0, type-list offset 28, name-list offset}, type list, reference lists, name list),
  types and ids in ascending order; Foundation-only (HK D6). Round-trips through the existing `ClassicResourceMap`
  parser. `ShellMixer.unload(id:)` releases a loaded sample buffer (stops any voice playing it first); unknown id is a
  no-op. No other API change.
- **Tests (HK, 3):** `testWriterRoundTripsThroughParser` (two types, three resources incl. one named, one empty body:
  parse(encode(x)) == x) · `testWriterHeaderLayout` (one 'FWSg' id 0 "Ferazel Saved Game" body of 965,208 zero bytes:
  data offset 256, data length 965,212, map offset 256 + 965,212, the name list holds the 18-byte name) ·
  `testUnloadReleasesSample` (load, play, unload → not loaded, voice stopped; unload of an unknown id is harmless).
- **Gate:** G1k (PASS, executed ≥ 331, FLOOR bumped); **G5 for all five app schemes** (HectorKit changed:
  `Aki`, `BubbleTroubleX`, `Deimos`, `Cythera` if a scheme exists, `Ferazel`); Classics G2 = 256.
- **Commit (HK):** `HectorResources: ClassicResourceWriter (classic resource fork encoder); HectorShell: ShellMixer.unload(id:); HK D16; floor 331`.

#### X1 — minor — Phase 2 carry sweep (→ 256)
- **Files:** `Sources/FerazelCore/Random/FastRand.swift` (doc cite), `Sources/FerazelCore/Sprites/SetupFaces.swift` +
  `Sources/FerazelCore/Player/PlayerTiles.swift` (the `200..<210` literals → one named `LiquidTiles.range` constant in
  `Physics/UnderWater.swift`, behaviour unchanged), `Ferazel/App/FerazelAudio.swift` (the redundant `stopEffects` in
  `stopAll`), `Tests/FerazelCoreTests/SoundCueTests.swift` (~l. 69), `Tests/FerazelCoreTests/PlayerTileTests.swift` or
  the file holding the `.PlayerConstraints` frame test, `docs/ferazel/INDEX.md` (provenance: the M-line drift note).
- **Contract:** no behaviour change. (1) `FastRand` doc: the clock reseed cites `LMGetTime` M l. 31295–31298, not M l.
  334. (2) `200..<210` literals named. (3) `stopAll` stops effects once. (4) Assert `soundStopAt` of the real jump
  frame in `SoundCueTests` (the value the code produces today, recorded; Invariant 10 if it surprises). (5) The
  `.PlayerConstraints` frame test distinguishes "row 38" from "after row 39" (a fixture where the two orders differ)
  and asserts the glider order. (6) INDEX provenance gains the note "bank M-line citations predate the 2026-10-08
  regeneration; Phase-3 plan M lines are current". Carried by name, not swept: M6 (Bonus guard `p1Negative: false`) and
  M7 (`TileHotRects.init(level:)`) → Phase 4 (Bonus class rework); `ParticleLife` vs CLUT 222 rows → the phase that
  first loads level 52 or 55; lost coins drawing when `.MTNewSprite` finds no record → Phase 4; the later-phase
  `3DSoundRand` idle-only sites (M l. 62997, 63199–63257, 61047–61057) → the Phase 4/5 plans (Invariant 4 conflict).
  `beginEnding`'s placeholder phase goes with the `Ending` struct in A1a.
- **Gate:** G2 = 256 (asserts only), G5 (touches the App). **Commit:** `Phase 2 carry sweep: FastRand cite, liquid tile range constant, stopAll, jump-frame soundStopAt and PlayerConstraints order asserts`.

#### R1 — minor — Dialog and menu resources (→ 260)
- **Files:** `Sources/FerazelCore/Front/DialogResources.swift`; `Tests/FerazelCoreTests/DialogResourceTests.swift`.
- **Contract:** Foundation-only parsers over `FerazelResources.resource(type:id:chain:)` (app fork): DLOG/ALRT
  (bounds, procID, visible, DITL id), DITL (count−1 prefix; per item: 4-byte placeholder, rect t,l,b,r, type byte with
  the 0x80 disabled bit, payload: Mac Roman text for button/check/radio/static/edit, resource id for control/icon/
  picture, padded to even), CNTL (rect, value, visible, max, min, procID, refCon, title; popup menu id = min/max per
  the popup CDEF convention — read the six shipped CNTLs 600–605 and record which field holds the MENU id), MENU (id,
  enable flags, title, items with icon/⌘ key/mark/style), MBAR (count + ids). No drawing.
- **Tests (4; data: digest A §3, §5, §6):** `testAbortWarningDialog` (DLOG 202 rect (114,144,256,439); DITL 202: 1
  button "OK" (113,226,133,284), 2 "Cancel" (113,161,133,219), 3 picture 145 (10,10,42,42), 4 static "^0"
  (10,53,97,264)) · `testPrefsPanels` (DLOG 6900 (56,20,330,471); DITL 6900 six items incl. control 3 → CNTL 600 →
  MENU 600 "Game Options"/"Controls"/"Sound & Music"; DITL 6902 edit items 7–15 at (67|93|119|145|171, 132) and (67|93|
  119|145, 342), 85 px wide; item 26 check "Use InputSprocket" (197,34,215,185)) · `testMenuBar` (MBAR 128 = [128,
  129, 130]; MENU 129 items New Game ⌘N, Restore Game... ⌘O, –, Abort Game ⌘W, –, Quit ⌘Q; MENU 130 Music ⌘M, Sound
  Effects ⌘F, –, Preferences… ⌘P; MENU 128 "About Ferazel's Wand…") · `testStandardFileDitls` (DITL 1003 item 13
  static "Your saved game will reflect your position as of the most recent checkpoint."; DITL 1500 item 10 "^0"
  (166,11,203,334)).
- **Commit:** `FerazelCore: DLOG/ALRT/DITL/CNTL/MENU/MBAR parsers (dialog and menu resources); 4 tests`.

### Wave 3.1 — byte images, files, the front-end seam

#### SV1 — ⚑ MAJOR — G image and the save block (→ 266)
- **Files:** `Sources/FerazelCore/Session/GameGlobals.swift`, `Sources/FerazelCore/Saves/{SaveBlock,InventorySlot}.swift`,
  `Sources/FerazelCore/Flow/LevelFlow.swift` (`LevelCarry.globals` keeps working with the wider struct);
  `Tests/FerazelCoreTests/SaveBlockTests.swift`; bank: `save-continue.md` + `engine.md` (corrections BC2, BC7).
- **Contract:** digest D §1–§2, save-continue §3.3, engine §9. `GameGlobals` covers all 0x19978 bytes by named field
  (S2); `image()` writes big-endian at the binary's offsets, gaps/never-accessed ranges 0 (Invariant 7);
  `init(image:)` reads every field back (the gaps are not stored). `initGameGlobals()` = M l. 582–812: health,
  breath, max health, max magic, magic **0x230**; `+0x12` 3; `unlocked[1]` (+0x240) **1**, others 0; inventory slot 0
  {id 0, count 1, +4 −1, +6 0, spell flag 1}, slot 1 {0, 1, −1, 0, 0}, slots 2…26 {−1, 0, −1, 0, 0}; crunch levels
  `+0x12d8` 0xff × 20000, count 0; `+0x16`, `+0x20`, `+0x22`, crunch pairs **not** written by InitGameGlobals (they keep
  the previous value — the flow passes the old struct through; the very first game sees 0). `SaveBlock`: offsets
  0x00 stamp u32, 0x04 preview u8, 0x05 demo u8, 0x06 checkpoint u8, 0x08 level i16, 0x0c x i32, 0x10 y i32, 0x18 G,
  0x19990 date u32 (seconds since 1904), 0x19998 + 0x2000·L + 16·i snapshots (L < 100, i < 511; the 512th slot and
  0xe1998..0xe7d97 never accessed), 0xe7d98 world name pstr, rest zero. `savePointSave(level:x:y:stamp:date:header:)`
  = raw order `1000c104…`: stamp (`Mwld+0x100`, `WorldFile.stamp`), date, `+6 = 1`, `+8 = level`,
  `globals.hasSnapshot[L] = 1` **before** the G copy, G copy, x/y (sign-extended i16), `+4 = +5 = 0`, then the 511
  records of the live header with record `+0xe` (x) and `+0xc` (y) each **−6** (raw `1000c2a4..1000c2d8`).
  `endLevelSGUpdate` = the same without `+4/+5` (M l. 6501ff). `restoreSnapshot(level:into header:)` = +6 on both
  (M l. 2405–2409, 6744–6747). The level header's 511 placement records must be writable in place (the live
  `Mlvl` copy the session uses) — expose them through `LevelFile` (Phase 2 W-tasks already write records: reuse that
  path, do not fork a second copy).
- **Tests (6):** `testInitGameGlobalsImage` (size 104,824; bytes 4–5 = 0x0230; `+0x12` = 3; `+0x240` = 1; `+0x24`
  slot 0 = 00 00 00 01 FF FF 00 00 01 00; `+0x12d8` = 0xff ×20000) · `testGameGlobalsRoundTrip` (a G with every named
  field non-default → image → init(image:) → equal) · `testCrunchLogImage` (three entries → `+0xad6` = 3, levels at
  `+0x12d8…`, row at `+0x60f8`, col at `+0x60fa`) · `testSaveBlockLayout` (size 965,208; the field offsets above
  read back from a hand-built image) · `testSavePointSaveWritesSnapshotMinus6` (level 1 header: record 24 (the save
  point, x 2377 y 878) stored at 0x19998 + 0x2000 + 16·24 with y 872, x 2371; `+6` = 1; `hasSnapshot[1]` = 1 inside the
  G copy) · `testRestoreSnapshotPlus6` (round trip leaves the header's records unchanged).
- **Commit:** `FerazelCore: G as a byte image (every field), the 965,208-byte save block (SavePointSave/EndLevelSGUpdate writers, snapshots ±6); 6 tests`.

#### SV2 — minor — Prefs record, prefs file, saved-game file (→ 272)
- **Precondition:** K1 merged (HK writer).
- **Files:** `Sources/FerazelCore/Input/FerazelPrefs.swift`, `Sources/FerazelCore/Saves/{PrefsFile,SavedGameFile,SaveName}.swift`;
  `Tests/FerazelCoreTests/SavedFileTests.swift`; bank `engine.md` §8 (BC17).
- **Contract:** digest A §4, digest D §4. `FerazelPrefs.record()` = 0x942 bytes, every field at its offset
  (engine §8 as corrected: +0x0e sound-effects volume, +0x36 "set system volume on startup", +0x24/+0x26/+0x28/+0x2c/
  +0x2e never written by `.InitPrefs` → 0 [MED: NewHandle junk in the original], +0x42 pstr "@@@@@", +0x142 eight
  empty pstr[256]); `init(record:)` preserves unknown bytes and grows a short record to 0x942 (`SetHandleSize`, no
  version check, M l. 7694–7768; the grown tail 0). `PrefsFile`: a classic resource file holding `'Pref'` id 0 named
  "Preferences" (M l. 7694ff), read/written at a URL the App passes. `SavedGameFile`: `write(_ block: SaveBlock, to:)`
  = one `'FWSg'` id 0 named "Ferazel Saved Game" (pstr 0x100a586c) holding the 965,208-byte block, encoded with K1's
  writer **into the data fork** (D35 ruling; HFS type `'FWSg'` / creator `'Msct'` set through Foundation's
  `FileAttributeKey.hfsTypeCode/.hfsCreatorCode`); `read(from:)` accepts the data fork **or** the file's resource fork
  (`<path>/..namedfork/rsrc`), so a save from a real Mac resumes; missing `'FWSg'` 0 → `.notASavedGame` (string
  "Sorry, this does not appear to be a saved game file.", 0x100a5a3d); no size check (`.OpenSG`, M l. 41315ff).
  `SaveName.increment(_:)` = `.IncrementLastSGString` (M l. 41115): chars 1…4 "@@@@" → "Ferazel Saved Game"; else
  only when length < 31: trailing digits → value + 1; trailing space → append "2"; else append " 2". Error mapping
  for the App: −34 / −33 / −44 / other → the four strings (0x100a58d1, 0x100a5908, 0x100a5944, 0x100a597f).
- **Tests (6):** `testPrefsDefaultsRecord` (0x942 bytes; keys at +0x12 = 00 56 00 58 00 5B 00 57 00 38 00 3A 00 37 00
  59 00 5C; +0x0e = 7; +0x10 = 9; +0x3a = 0xffff; +0x42 = 05 40 40 40 40 40) · `testPrefsShortRecordGrows` (a 0x40-byte
  record → 0x942, first 0x40 kept) · `testPrefsFileRoundTrip` (temp dir) · `testSavedGameFileRoundTrip` (temp dir;
  type/creator read back as 'FWSg'/'Msct'; bytes equal) · `testSavedGameFromResourceFork` (a file whose resource fork
  holds the map and whose data fork is empty reads the same block) · `testSaveNameSequence` ("@@@@@" → "Ferazel Saved
  Game" → "Ferazel Saved Game 2" → "… 3"; "Game " → "Game 2"; a 31-char name unchanged).
- **Commit:** `FerazelCore: prefs record (0x942) + prefs file, saved-game file (FWSg 0, data fork or resource fork), IncrementLastSGString; 6 tests`.

#### FE0 — ⚑ MAJOR — Front-end seam, `ScreenSurface`/`ScreenRenderer`, timed fades, music fades (→ 278)
- **Files:** `Sources/FerazelCore/Seams/{DrawOp,ShellRequest,Rect16,TextRun,FerazelDialog}.swift`,
  `Sources/FerazelCore/Front/{ScreenFade,MusicFade,FrontIO}.swift` (`FrontInput`, `FrontOutput`),
  `Sources/FerazelRender/Screens/{ScreenSurface,ScreenRenderer}.swift`, `Sources/FerazelRender/Effects/ScreenGamma.swift`,
  `Sources/FerazelRender/Frame/FrameRenderer.swift` (the `surface:` parameter, defaulted), `Tests/FerazelCoreTests/SessionTests.swift`
  and `Tests/FerazelRenderTests/FrameGoldenTests.swift` (only the exhaustive `switch op` arms for the new cases),
  `Ferazel/App/FerazelController.swift` (no-op arms for the new `ShellRequest` cases); `Tests/FerazelRenderTests/ScreenTests.swift`;
  bank `rendering-omnipx-titles.md` §4.3 (BC16).
- **Contract:** S3 cases + S4 types. `ScreenRenderer.apply(_ ops:)` executes `setScreenClut`, `drawPicture`
  (full-screen or at (h, v)), `copyPicture` (source → dest rect with nearest-row/column stretch [MED], `forceClut` =
  `CopyBitsCTForce` (the source converted under that clut, then copied by colour into the screen clut), `transparent`
  = mode 0x24 (white source pixels skipped)), `fillRect`, `drawLine` (1-px QuickDraw line, pen 1×1), `drawText`
  (through the injected `TextRasterizer`, srcOr), `screenGamma`. `ScreenFade` (Core) timelines:
  `.GammaFadeOut(n)` = `MT_FadeCustom` over `ms = trunc(0.7·55·trunc(2.3·n))` (raw `10035310..10035420`; n 3 → 230,
  6 → 500, 10 → 885, 12 → 1039, 30 → 2656 ms) through `.TintFadeProc` mode 3 (B·(1−t), G·max(1−1.35t, 0),
  R·max(1−2.5t, 0)), one `screenGamma` op per tick, ticks by Invariant 3 (500 → 30, 885 → 54, 2656 → 160); sets
  faded; no-op when fading is disabled or already faded. `.GammaFadeIn(n)` (raw `10035444..10035560`): s = max(1,
  100/(3n)); for p = 0, s, 2s … ≤ 100 one `FadeToColor(nil, min(100, p·3n/100))` per tick (compounding, as
  `ScreenGamma.fade` already models), then 100; clears faded; **n 6 → 21 steps passing 0…18, then 100**.
  `.GammaFadeInSlow(n)`: ms = max(33n, 100) (n 0x37 → 1815 ms → 109 ticks), linear. Gates: `DAT_100a53c2` fading
  enabled (initial 1), `*_DAT_1009fde8` faded, `DAT_100a53d6` async-done (initial 1). `MusicFade` (Core): `SetAIFFMusic(n)` → `.stop` then `.play(track: n)` then `.volume(0)` (M l. 41852ff; n −1 → nothing,
  n < 1 or > 32 → 1; missing file → n − 1 stays the App's resolver), faded flag `*0448 = 1`; `FadeAIFFMusic(dir, t)`
  blocking: out only when `*0448 == 0`, in only when ≠ 0; 24 steps of t ticks with `.volume(V·(24−s)/24)` /
  `.volume(V·s/24)`, then 0 / V (V = prefs+0x10·256/9, signed divide); gates music on (prefs+0x0c) and loaded;
  `FadeAIFFMusicAsync(dir, N)` per frame (V·(N−i)/N, V·i/N; done when i > N). `FrontOutput.present` is true on every
  tick that changed the surface or the gamma.
- **Tests (6; digest A §1, C §1, lighting-tables §10):** `testMainMenuScreenGolden` (Render: `setScreenClut(130)` +
  PICT 130 at (0,0) on a fresh surface: FNV-1a of the indices + the CLUT, self-derived, recorded) ·
  `testStretchedPanelRows` (PICT 140 copied 320×110 → (150+s,160,260−s,480) for s = 52, 26, 0: row counts 6, 58, 110;
  the source row each dest row samples, recorded) · `testTransparentCopySkipsWhite` (a 2×2 source with one white
  pixel leaves that screen pixel unchanged) · `testGammaFadeOutTimeline` (n 6 → 30 ticks, red channel first: at t =
  0.4 R factor 0, G 0.46, B 0.6 — `.TintFadeProc` mode 3) · `testGammaFadeInSteps` (n 6 → 21 one-tick steps passing
  trunc(p·18/100) for p = 0, 5 … 100 = 0, 0, 1, 1, 2 … 18, then 100; n 15 → s 2, 51 steps) · `testMusicFadeVolumes` (V 256: in
  t 4 → 24 cues 0, 10, 21 … 245 at ticks 0, 4 … 92, then 256; out t 2 → 256·(24−s)/24 …, then 0; no cue when
  already faded/unfaded).
- **Commit:** `Front-end seam: ScreenSurface + ScreenRenderer (picture/stretch/transparent/fill/line/text ops), timed gamma fades (TintFadeProc), music fades; 6 tests`.

#### O1 — minor — Options dialog model (→ 283)
- **Files:** `Sources/FerazelCore/Front/PrefsDialogModel.swift`; `Tests/FerazelCoreTests/PrefsDialogTests.swift`; bank
  `save-continue.md` §8.2 (BC18).
- **Contract:** digest A §3 (M l. 7254, 63949–64030, 64233–64700). Panels n = 1 Game Options (DITL 6901), 2 Controls
  (6902), 3 Sound & Music (6903); switching = `ShortenDITL`/`AppendDITL`, panel items from 7. Item ↔ field: 6901
  7 → +0x00, 8 → +0x01, 9 → +0x08, 10 popup → +0x02 (1 High / 2 Low / 3 Line-skipped), 11 popup → +0x06 (1 Enhanced /
  2 Normal / 3 Reduced), 14 → +0x32 (the click updates **item 16**, which does not exist — the box does not visibly
  change until a redraw; raw `100767fc`); 6902 edit items 7…15 ↔ keys +0x12 + 2(i−7), item 26 → +0x0a (updates item
  30, raw `10076944`; disabled and forced 0 — no InputSprocket), item 27 "Configure…" disabled; 6903 7 → +0x0b, 8 →
  +0x0c, popups 9/10/15 → +0x0e/+0x10/+0x38 with control value v ↔ pref **10 − v**, 16 → +0x36. Key capture
  (`.PrefDialogFilter`): the focused edit item takes the key code (message >> 8 & 0xff) unless `.AlreadyUsingKey`
  (scans **10** slots +0x12…+0x24 — slot 9 is +0x24, 0 in the replica, so key code 0x00 'A' reads as used [LOW];
  Up (2) and Jump (5) may share) → report "That key is already being used for another action. Please try another one.";
  modifiers from the event's modifier bits → 0x37/0x38/0x3a/0x3b; focus moves to the next item (15 → 7); on panel 2
  Return/Enter/Esc/⌘. are captured as keys, elsewhere they are OK/Cancel. `.ConvertKeyName` fixed table (digest A §3)
  else an injected `keyCharacter(code) -> String?` (the App's keyboard layout), uppercased. Buttons: OK → working copy
  into the record; Cancel → only the system volume restored (live music/sound changes stay); **Default Settings** per
  panel — Controls and Sound reset the working copy; **Game Options writes the defaults into the record, not the
  working copy** (raw `10076520..10076528`), so nothing visibly changes, OK then overwrites them and Cancel keeps them;
  the record is written to the prefs file on every close (`.Options`, M l. 7254). Live effects: Music toggle stops the
  music / restarts it at its volume; volume popups apply at once (sound v·28, music v·256/9).
- **Tests (5):** `testPanelItemMapping` · `testKeyCaptureRules` (dup rejected with the message; Up+Jump share; ⌘ → 0x37;
  focus 15 → 7; 'A' (0x00) rejected [LOW, recorded]) · `testConvertKeyNameTable` (0x24 Return, 0x31 Space Bar, 0x37
  Command, 0x56 Keypad 4, 0x5b Keypad 8, 0x7e Up Arrow, 0x52 → the injected layout char) · `testVolumeControlMapping`
  (v 3 → pref 7; pref 9 → v 1) · `testGameOptionsDefaultSettingsBug` (defaults land in the record; OK overwrites them
  with the working copy; Cancel keeps them).
- **Commit:** `FerazelCore: Options dialog model (three panels, key capture, AlreadyUsingKey, ConvertKeyName, Default Settings as written); 5 tests`.

### Wave 3.2 — between two levels

#### L1 — ⚑ MAJOR — `LevelRun`: level entry, cadence, exit; `.SetupLevel`'s restore branch (→ 291)
- **Files:** `Sources/FerazelCore/Front/LevelRun.swift`, `Sources/FerazelCore/Session/FerazelSession.swift` (entry hooks
  and `LevelEnd`; the Phase-2 `ended`/`deathEffectDone` path untouched), `Sources/FerazelCore/Session/SpriteWorld.swift`
  (the async fade honours `ScreenFade`'s gates), `Sources/FerazelCore/Flow/LevelFlow.swift` (`LevelCarry` gains the
  G image path; Phase-2 helpers untouched); `Tests/FerazelCoreTests/LevelRunTests.swift`; bank `save-continue.md` §6
  (BC8), `engine.md` §4/§6 (BC11, BC12, BC13).
- **Contract:** digest C §1, §2, §5, §6; M l. 2189–2590 (`.SetupLevel`), 5093–5325 (`.GameLoop`). **Entry, in order:**
  `FadeAIFFMusic(0,4)` + shutdown (M l. 5161–5163); `.SetupLevel`: `.PopupStageLoad` (L2's machine) +
  `UpdateStageLoad(50,100)` / `(100,100)` (and `(25,100)` on the same-level fast path, M l. 2270), `G+0x20 = 0`
  (byte), `G+0x22 ← hdr+0x2706`, **key 0x76 (F4) held → `hasSnapshot[L] = 0` (ungated, raw `100047e0..10004810`)**;
  `hasSnapshot[L] == 1` → re-apply the crunch log entries of L with the **explode flag 0** (raw `10004874`; no
  `.ExplodeCrunchedTile`, **no FastRand draws**) and `restoreSnapshot` (+6) before the Setups; first visit → tallies
  0, after `.SetupLevelSprites` `achieved[0…2][L] = 0`, `totals[0][L] ← enemies (*ffb4)`, `totals[1][L] ← Xichrons
  (*ffb0)`, `totals[2][L] ← secrets (*ffac)` (M l. 2528–2536); revisit keeps both; `G+0x174 = 0`; `GammaFadeOut(6)`
  (M l. 2570); level CLUT; PICT 129; then the session's existing level-start work (spawn, AnimateCLUT, tint, first
  redraw, status bar); `unlocked[L] = 1` (M l. 5180); `GammaFadeIn(8)` only when a4 ∧ hdr+0x2712 ≠ 0 (never in the
  data); boss music rule (M l. 5218); `SetAIFFMusic(hdr+0x284a)` + **`FadeAIFFMusic(1,4)` blocking 96 ticks**
  (M l. 5221–5222; owns Phase-2 carry M13); chapter gate `hdr+0x273c ≠ 0 ∧ hasSnapshot[L] == 0` → L2's `.ChapterScreen`
  (M l. 5223–5227); **`GammaFadeInAsync(0x28)` on every entry** (M l. 5228; owns the Phase-2 "no fade-in after
  restart" carry), stepped once per iteration by the session's existing `AsyncGammaFade`, gated by `ScreenFade`
  (faded must be set — `.SetupLevel`'s fade-out always sets it; a death inside the first 41 iterations keeps driving the
  fade-in, digest C §4). **Cadence:** Invariant 4. **Exit (M l. 5296–5325):** stop 452 and 511; died (`G+4 < 1`,
  tested first) → `ffa8 = 1`, `FadeAIFFMusic(0,2)` (48 ticks), `.DeathEffect` (50 steps, the Render wipe A3 drives
  today, now driven by the flow); completed → stop 452, 453, 511, `endLevelSGUpdate` (SV1), `.StageCompleteEffect`
  unless `fd64` (L2's machine), `fd64 = 0`, `FadeAIFFMusic(0,2)`, `GammaFadeOut(6)`; aborted (Esc/⌘W OK with HP ≥ 1,
  not complete) → neither branch; all → `ShutDownAIFFMusic` (`.stop`), `ShowCursorSafe`. `LevelEnd` carries `exit1`
  (`uRam100a5116`) / `exit2` (`_DAT_100a5118`, stored only when p2 ≠ 0, M l. 49738). `LevelRun` never emits the
  Phase-2 `ShellRequest.loadLevel`/`.deathEffect` (those stay for the App until A1a).
- **Tests (8; self-derived numbers recorded on first green, re-derived by the reviewer from the dump):**
  `testEntrySequenceOrder` (L1 first visit: the op/music/tick sequence from `FadeAIFFMusic(0,4)` to the first step:
  popup, bars 146/293, GammaFadeOut(6) 30 ticks, PICT 129, music play + 24 volume cues over 96 ticks, chapter screen,
  then the first `step` with the async fade-in armed for 41 iterations) · `testCadenceTwoTicks` (steps at ticks t, t+2,
  …; prefs+0 = 1: skipped + drawn pairs every 4 ticks; a 30-tick block → no catch-up) · `testFirstVisitTotalsLevel1`
  (`totals[0…2][1]` = the `.SetupLevelSprites` tallies of level 1, self-derived and recorded; achieved 0) ·
  `testRevisitKeepsCountersAndSnapshot` (a G with `hasSnapshot[1] = 1` and a snapshot with record 24 p1 = 2: the
  rebuilt level shows the save point at face 2; counters kept; no chapter screen) · `testCrunchReapplyDrawsNothing`
  (a logged crunch on L1 (119,36): the tiles re-destroyed, the session's seed after level start equals a fresh L1
  start's 0x2c1b1519) · `testF4ClearsSnapshotFlag` · `testDeathExitSequence` (stops [452, 511] → 24 music cues over 48
  ticks → 50 wipe steps → `.stop`; `ffa8` set) · `testCompleteExitSequence` (stops [452, 511], [452, 453, 511] →
  EndLevelSGUpdate (`+6` = 1, `hasSnapshot[1]` = 1) → stage-complete machine → music fade 48 ticks → GammaFadeOut(6) 30
  ticks → `.stop`; `exit1` 0 for L1's rec 66).
- **Commit:** `FerazelCore: LevelRun — level entry (SetupLevel restore/first visit, fades, music fade-in, chapter gate, async fade-in), 2-tick cadence, death/complete/abort exits; 8 tests`.

#### L2 — minor — Chapter card, stage-load popup, stage-complete panel (→ 296)
- **Files:** `Sources/FerazelCore/Front/StageScreens.swift`, `Sources/FerazelRender/Screens/ScreenRenderer.swift`
  (nothing new beyond FE0's ops unless a test needs it); `Tests/FerazelCoreTests/StageScreenTests.swift`; bank
  `world-data-format.md` §4.3 (BC9).
- **Contract:** digest C §1, §3. `.PopupStageLoad` (M l. 2946–2990): PICT 142 (320×64, port built on clut 199) copied
  with plain CopyBits (remapped by colour) to (173+s, 160, 237−s, 480), s = 30, 28 … 0, one tick each (16 ticks).
  `.UpdateStageLoad(p,q)` (M l. 2993–3029): w = (int)((float)p/(float)q·293.0f) clamped 0…293, `PaintRect(172, 213,
  172+w, 224)` (l,t,r,b) in RGB 0x59d8 ×3; no wait. `.ChapterScreen(n)` (M l. 5038–5089): clut 280+n (nil → skip
  all), PICT 4600+10n at (0,0,640,480), `GammaFadeInSlow(0x37)` (109 ticks), up to **1200** one-tick iterations
  ending early on any key or the mouse button (the current tick finishes; a key held on entry skips at once),
  `GammaFadeOut(0x1e)` (2656 ms → 160 ticks), the level clut back, PICT 129, `UpdateStatusBar(0,0,0)`.
  `.StageCompleteEffect` (M l. 2870–2943): snd **805** (prio 1, vol 0x100); 27 frames s = 52, 50 … 0 of PICT 140
  (`CopyBitsCTForce`, clut 200) at (150+s, 160, 260−s, 480), one tick each; wait 15 ticks; three `.FillPercent`
  bars at screen (413, 200 / 218 / 236) for enemies `(achieved[0], totals[0])`, Xichrons `[1]`, secrets `[2]`; wait
  40 ticks. `.CalcPercent(a,b)` (M l. 2843–2865): b 0 → 100; a 0 → 0; else (int)(100.0f·a/b) clamped 2…100.
  `.FillPercent` (M l. 2752–2836): n2 = (pct/2)·2; tick = 1 if pct > 45 else 2; when n2 > 0: snd **803** (prio 1, vol
  0xab), rows j = 0 … n2/2 − 1 of PICT 141 (source (0, 14j, 52, 14j+14)), restarting 803 when its voice ended, then
  stop it; always: snd **804** (vol 0x100) + the final row n2/2, wait until 804 ends (2304 samples → 7 ticks at
  22,050 Hz, rounded up [MED]), 4 ticks, band snd **800** (n2 < 11, vol 0x100) / **801** (< 100, vol **0xab**) /
  **802** (vol 0x100), wait until it ends, then 22 ticks (n2 < 11) else 12. Sound lengths come from `SoundBank`
  sample counts (Core receives them as an injected table — no PCM in Core).
- **Tests (5):** `testCalcPercentTable` ((0,0) 100; (0,5) 0; (1,100) 2; (7,7) 100; (9,8) 100; (1,3) 33) ·
  `testFillPercentTimeline` (pct 0 → no 803, final row 0, 800, wait 22; 11 → rows 0…4 at 2 ticks, 800; 46 → 23 rows at
  1 tick, 801 at 0xab; 100 → 50 rows, 802, wait 12) · `testStageCompleteTimeline` (805, 27 panel frames with the rects,
  15, three bars in order at y 200/218/236, 40) · `testChapterScreenLevel1` (clut 281, PICT 4610, 109-tick fade-in, key
  on tick 300 → fade-out 160 ticks, clut back, PICT 129; untouched → 1200 ticks) · `testPopupAndLoadBar` (16 rects
  (203,160,207,480) … (173,160,237,480); bar widths 73/146/293).
- **Commit:** `FerazelCore: chapter card, stage-load popup and bar, stage-complete panel with CalcPercent/FillPercent; 5 tests`.

### Wave 3.3 — the world map

#### M1 — ⚑ MAJOR — `WorldMapRun` (→ 304)
- **Files:** `Sources/FerazelCore/Front/WorldMapRun.swift`, `Sources/FerazelCore/World/WorldMap.swift` (lookups only);
  `Tests/FerazelCoreTests/WorldMapRunTests.swift`; bank `world-data-format.md` §4.2 (BC14).
- **Contract:** digest B §1–§3; `.ShowWorldMap @ 1007c494` (M l. 67432–67658) and callees. Entry: level-complete flag
  required (else "Error showing world map", return 1); `cur = FindCurrNode(hdr+0x26c4)` (first node whose level
  matches; none → "Current node could not be found!" + quit; node 60 ↔ level 62, node 62 ↔ level 67); clut 700 on the
  ports and screen; PICT 129 (0,0,640,480); status bar; PICT **7000** (app fork) into the background at
  (0,0,608,384); unlock `unlocked[node[node[cur].links[exit]].level] = 1` for exit1 and exit2 ≥ 0 (M l. 67513–67524);
  ambient sprite type 100 at (38, 168) counter −4; `.MakeNodeSprites` over nodes 0…127: each existing, unlocked node
  → sprite at (h−20, v−20), type = node face, counter **`FastRand(15)`** (one draw per visible node, node order), and
  `.DrawLink` for every link slot > 0 whose target is unlocked (drawn from both ends); marker type 0x45 at (h−20, v−20);
  music: `SetAIFFMusic(25)` + `FadeAIFFMusic(1,2)` + `GammaFadeIn(15)` (M l. 67540–67542); `walkTarget = cur`,
  `walkStep = 0`; for exit1 ≥ 0: `.DrawNewLink(cur, exit1)`; for exit2 ≥ 0: `.DrawNewLink(cur, exit2)` then
  `walkTarget = cur`, `walkStep = 0` (M l. 67558–67559); exit1 = exit2 = −1; abort = 0; on-map flag 1.
  `.DrawNewLink` (M l. 67171–67274): snd **420** (`STPlayRegSound(…, 1, 0x100)`) once; **50** iterations of 3
  `FastRand(32000)·2` (random RGB, **150 draws**) + the three lines, dirty rect = bbox ±10, wait 2 ticks each; end:
  restore the plain link, `walkTarget = target`, `walkStep = 1` (auto-walk). `.UpdateNodeSprites`: types 0/1 counter
  +1 wrapping after 15, face = c >> 1; 0x45 fixed; 100: counter +1 wrapping after 127, face = c >> 4 when c ≥ 0.
  `.FindPlayerNodeLoc` (M l. 67008–67054): walking → step += 1, pos = trunc(t·step/30) + trunc(c·(30−step)/30) per
  axis; step > 29 → cur = target, step 0. `.CheckPlayerNodeMovement` (M l. 67281–67429): per non-zero link slot,
  primary/secondary directions (target above: left → (1,3) if dv < dh else (3,1), right → (2,3)/(3,2); level or below:
  (1,4)/(4,1), (2,4)/(4,2); a tie makes the vertical primary); keys left = action 0 or 0x7b, right = action 1 or 0x7c,
  up = action 2 or 0x7e, down = action 3 or 0x7d; pass 1 primaries in slot order, first held direction whose target
  is unlocked wins; pass 2 secondaries; sets walkTarget, step 1. Loop (M l. 67567–67650): runs while (no Return 0x24,
  no Enter 0x4c, no action 6, no action 5) or walking, and not aborted; per iteration: `.FindPlayerNodeLoc`; if not
  walking: movement test + level name `STR# 1000[node[cur].level]` → header name → status bar; draw; wait ≥ 1 tick;
  Caps Lock → P1's pause (with the 608×384 save/restore); ⌘ or Esc held: + Q → confirm "Are you sure you want to
  quit?" (0x100a6d69) → OK: abort + quit; + W or Esc → confirm "Are you sure you want to abort this game?"
  (0x100a6d88) → OK: abort (dialog = `ShellRequest.dialog(.confirm)`; the flow waits). Exit: `FadeAIFFMusic(0,2)`,
  on-map 0; return −1 if aborted else `node[cur].level`. The held-⌘ quirk is kept: an idle ⌘ (action 6) ends the loop
  and enters the current level before the ⌘Q test can see it [MED, gate card].
- **Tests (8; digest B §3):** `testNodeTableAndNames` (24 nodes; boss faces on nodes 5, 18, 25, 55, 62; FindCurrNode(62)
  = 60, (67) = 62; STR# 1000 has 99 entries, [1] "A Scent of Peril", [2] "Central Caverns", [51] "If You Can't Stand
  The Heat…") · `testDirectionsFromNode2` (left → 1, right → 4, down → 3, up → 1) · `testWalkThirtyFrames` (1 → 2: the 30
  positions of the formula, self-derived from M l. 67008–67054 and recorded; step 30 at (330, 269), cur = 2 after it) · `testUnlockAfterLevel1` (exit1 0 → `unlocked[2]`,
  DrawNewLink 50 × 2 ticks with snd 420 and 150 draws, then auto-walk to node 2) · `testLevel2ExitsUnlock3And4` (p1 1
  → node 3 auto-walk; p1 2 → node 4) · `testTwoExitsNoAutoWalk` (level 15 exit1 1 / exit2 2: 20 and 30 unlocked,
  marker stays) · `testMapExitKeys` (Return/Enter/Option/⌘ when idle → returns the current level; ignored while
  walking; Esc → confirm → OK → −1; ⌘Q → quit flag) · `testMapDrawsPerVisibleNode` (after level 1: 2 visible nodes → 2
  `FastRand(15)` draws + 150; the stream state recorded).
- **Commit:** `FerazelCore: WorldMapRun — ShowWorldMap, node sprites, DrawNewLink, the 30-frame walk, CheckPlayerNodeMovement, unlocks, exit keys; 8 tests`.

#### M2 — minor — Map drawing (→ 307)
- **Files:** `Sources/FerazelRender/Screens/MapRenderer.swift`, `Sources/FerazelRender/Screens/ScreenRenderer.swift`;
  `Tests/FerazelRenderTests/MapRenderTests.swift`.
- **Contract:** digest B §1 (`.InitMapFaces @ 1007ac38`, `.DrawLink @ 1007b7c8`, `.DrawNodeSprites`/`.EraseNodeSprites`/
  `.CopyNodeSpritesToScreen`, M l. 66859–66960). Faces converted under clut 700: PICT 8000 marker 24×24, 8001 normal
  node 8 × 24×24, 8002 boss node 8 × 24×24, 8004 ambient 8 × 64×86 (Sprites file); 8003 is never read. Node faces drawn
  at slop-8 blit (x, y) = screen-view (x+8, y+8) → centred on (h, v); the view sits at screen (16, 8). `.DrawLink`:
  ForeColor 33 (black) lines (h1,v1)→(h2,v2), +1/+1, −1/−1, then ForeColor 30 (white) the centre line, into the
  background; DrawNewLink's random RGB lines go through `ColorSearch` under clut 700. The ambient sprite is never
  erased. The level name in the status bar: Times (20) 12 bold white at port (27, 46) → the existing `StatusBar` path.
- **Tests (3):** `testMapFirstFrameGolden` (after level 1 with seed 1: the flow's first map frame, FNV-1a of the
  indices + CLUT, self-derived) · `testLinkPixels` (the 1 → 2 link: a white centre pixel flanked by black on both
  diagonals) · `testNodeFaceCentred` (node 1 face covers screen (h+16−12 … h+16+11, v+8−12 … v+8+11)).
- **Commit:** `FerazelRender: world map — PICT 7000, node faces (slop-8 centring), links, new-link flashes; 3 tests`.

### Wave 3.4 — the game flow: title, menu, New Game, death, Continue

#### F1a — minor — `GameFlow` part 1: boot, title, main menu, Credits timing (→ 312)
- **Files:** `Sources/FerazelCore/Front/{GameFlow,MainMenu,BootSequence,CreditsScroll}.swift`;
  `Tests/FerazelCoreTests/GameFlowMenuTests.swift`; bank `rendering-omnipx-titles.md` §4.1 (BC19), `engine.md` §2.
- **Contract:** digest A §1, §2, §5 (Credits). Boot (`.main`, M l. 8136–8358): `GammaFadeOut(6)`; PICT **131** at
  (0,0,640,480) (clut 128 set later — the logo is drawn under the CLUT current at boot: the App's default = clut 128
  [MED]); `SetMusicAIFFVolume(V)`, `FadeAIFFMusic(0,99)` (no-op: nothing loaded), `SetAIFFMusic(24)`,
  `FadeAIFFMusic(1,6)` (blocking 144 ticks); `GammaFadeIn(6)`; boot keys polled once: N+F (0x2d + 0x03) → fading
  disabled (`53c2 = 0`) + report "Fading disabled."; F1 (0x7a) → "Sound loading turned off." and no effects loaded;
  the logo stays up for the load time only (the App reports loading progress; no timed wait, no skip);
  `GammaFadeOut(6)`; `SetScreenClut(128)`; PICT **136** (the replica's screen is always 640×480); `GammaFadeIn(6)`;
  the 3-D progress bar (`.Init3DProgBar(36, 440, 190)`, `.Update3DProgBar`, M l. 32050–32170: progress 16.16, +0x48
  per face loaded, final 0x10000; redraw only when the filled width changes by ≥ 8 px − 5 or p ≥ 58000; the colour
  ramp of digest A §1) driven by the App's load callback (`GameFlow.loadProgress(faces:)`); then `.MainMenu`:
  idle up to 60 ticks (`WaitNextEvent` sleep 60), `GammaFadeOut(6)`, `.DrawMainMenu` (clut 130, PICT 130),
  `GammaFadeIn(6)`. Menu loop (M l. 7303–7445), only while `active`: mouse over a hot rect (427,263,581,305) New
  Game, (434,305,626,345) Continue, (441,346,612,388) Options, (448,387,562,427) Credits, (456,429,539,471) Quit (l,t,r,b)
  with the button down → `.TrackClickOnCommandButton(n, 1)` (highlight PICT 4900+n / normal 4910+n, snd 4803 on
  entry, 4804 on exit and release, both `STPlayRegSound(…, 10, 0x55)`; more than 9 entries → snd 199, absent from
  every fork → silent); pointer over no button: v < 21 → `showMenuBar` request, else hide; keys polled in order N (0x2d)
  → `Track(1,0)` + New Game; O (0x1f) / R (0x0f) → Continue; I (0x22) / P (0x23) → Options; C (0x08) → Credits; Q
  (0x0c) → Quit; X (0x07) with the cooldown 0 → cooldown **30** + report "Coming soon: Ferazel's Destiny; …" (the
  string at its address, verbatim); keyboard track = highlight + 4803, **10 ticks**, normal + 4804; every pass:
  `fd48` → Continue with the last reply; cooldown −1. Quit (`.Quit @ 1000e9d4`): `FadeAIFFMusic(0,1)`, stop,
  `GammaFadeOut(6)`, then `ShellRequest.quit`; prefs are **not** written at quit. `CreditsScroll` (`.DoAboutDialog`,
  M l. 65263–65435): the PICT 4803 strip (144×811) moves up 1 px per 3 ticks inside clip (34,120)–(170,270), starting
  at y 270, wrapping after 961 steps; the App draws it; a click inside ends it, outside beeps.
- **Tests (5):** `testBootSequence` (op/music/fade order and tick counts up to the first menu frame: 30 + 144 + 21 +
  load + 30 + 21 + idle ≤ 60 + 30 + 21) · `testMainMenuHotRects` (each rect's corners in/out; v 20 shows the menu bar,
  v 21 hides) · `testTrackClickKeyboardPath` (N: PICT 4901, 4803, 10 ticks, PICT 4911, 4804, then New Game) ·
  `testMouseTrackSlideOut` (press in, slide out, release outside → no action; 4803/4804 per crossing) ·
  `testXCooldownAndCredits` (X twice within 30 passes → one report; credits strip offset after 300 ticks = 100 px).
- **Commit:** `FerazelCore: GameFlow — boot (logo, loading bar), main menu (buttons, keys, X joke), Quit, Credits scroll timing; 5 tests`.

#### D1 — minor — The death screen (→ 316)
- **Files:** `Sources/FerazelCore/Front/DeathScreen.swift`, `Sources/FerazelRender/Screens/ScreenRenderer.swift`
  (`TurnGray` CLUT writes); `Tests/FerazelCoreTests/DeathScreenTests.swift`; bank `save-continue.md` §5 (BC10).
- **Contract:** digest C §4 (`.AskToContinue` M l. 3718–3858). `fe00 == 0` → returns false with no drawing. Else clut
  132, PICT 138, `GammaFadeIn(6)`, cursor shown; loop: mouse down in (252,390,389,411) → `TrackClickDeath(1,1)`, in
  (262,413,378,433) → `(2,1)` (l,t,r,b); Return/Enter → button 1 (InputSprocket is never on: prefs+0x0a forced 0);
  Esc or ⌘Q → button 2; `.TrackClickOnCommandButtonDeath` (raw `10006970`): rects (252,390,390,412) / (262,413,379,434),
  pressed PICT 4979+n, idle 4969+n, 4803/4804 at (10, 0x55), keyboard press holds 10 ticks. Button 1 → `.WandGlow`
  (wait 6 ticks, snd 606 (10, 0x100), 11 frames of 5 ticks: PICT 172…177 then 176…172 at (138,286,220,368)); button 2
  → `.TurnGray` (snd 435 via `STPlay3DSoundPitched(…, 10, 0x100, view centre, 35000)`; frames f = 0…150, ≥ 1 tick
  each; k = max(0, 1 − 100f/7500); for clut-132 entries 0…254 gray = (r+g+b) >> 2, scaled by (150−f)/75 when f > 75;
  c → (int)(c·k + gray·(1−k)) clamped; written as the screen CLUT every frame). Returns continue = button 1.
- **Tests (4):** `testNoSaveNoDeathScreen` · `testDeathButtonsKeysAndMouse` (Return → 1; Esc → 2; ⌘Q → 2; a click in
  the 1-px-smaller hit rect) · `testWandGlowTimeline` (6 + 55 ticks; frame ids 172…177, 176…172; snd 606) ·
  `testTurnGrayClut` (entry values at f 0 (unchanged), 75 (gray), 150 (black) for two clut-132 entries).
- **Commit:** `FerazelCore: the death screen — AskToContinue, death buttons, WandGlow, TurnGray; 4 tests`.

#### F1b — ⚑ MAJOR — `GameFlow` part 2: New Game, the level ⇄ map loop, Continue, death (→ 322)
- **Files:** `Sources/FerazelCore/Front/{GameFlow,NewGame,ContinueGame,BuiltLevels}.swift`;
  `Tests/FerazelCoreTests/GameFlowGameTests.swift`; bank `save-continue.md` §4 (BC3, BC4, BC5).
- **Contract:** digest D §5, B §4; `.NewGame @ 1000b11c` (M l. 5704–5874), `.ContinueGame @ 1000d004` (M l.
  6663–7154). **New Game:** `*fd5c = 1` (menu path); Option held → report "Ferazel sez:\rNo more cheating!" then level
  1 (no debug flag); `InitGameGlobals` (passing the previous G's uninitialised fields through, SV1), `save+6 = 0`,
  `fe00 = 0`, `fd54 = 0`; level **1** (literal, raw `1000b2b8..1000b2cc`); loop while not `DAT_100a5106`:
  `FadeAIFFMusic(0,4)`, stop, `G+0x16 ← hdr[0x26c8]`, `LevelRun(x: hdr+0x2848 − 32, y: hdr+0x2846 − 32, a4: 1)`;
  completed ∧ no victory → `WorldMapRun`: −1 → `GammaFadeOut(10)` + end; else open level n (◇ **`BuiltLevels`**: n
  outside 1...2 → report "◇ Level n is not built yet (Phase 4–6)." — the only invented text, D35 — and re-enter the
  map at the same node without unlocking anything new); quit flag → Quit; not aborted → `save+0xc/+0x10 ← hdr+0x2848
  − 32 / +0x2846 − 32` of the next level (M l. 5837–5838). After the loop: died → `AskToContinue` (D1): continue →
  `fd48 = 1` → Continue with the last reply; else menu return: `GammaFadeOut(6)`, `.DrawMainMenu`,
  `SetAIFFMusic(24)`, `FadeAIFFMusic(1,4)`, `GammaFadeIn(6)`, cursor (M l. 5842–5874). **Continue:** `InitGameGlobals`,
  `OpenSG` (`fd18` reply or `ShellRequest.getFile("Please select the saved game from which you would like to
  continue.")` after `GammaFadeIn(0x14)` if faded; read through SV2); failure → report the SV2 error, back to the menu;
  level ← save+8 (also `_DAT_100ab9ba`), G ← save+0x18; refusals are **three independent tests** (+4 == 1 →
  "…preview version…" 0x100a2ec9; +5 == 1 → "…demo version…" 0x100a2f33; level ≥ 80 → the same demo text — a demo save
  at ≥ 80 shows two dialogs) then back to the menu; **design §9 (d): the level resource is missing → report "Tried to
  open a level that wasn't there!" (pstr 0x100a5af7) and back to the menu** (the original dereferences nil; D35);
  default branch only (the replica always opens its default world; no stamp check): save+6 == 0 → `G+0x16 ←
  hdr[0x26c8]` else `restoreSnapshot(save+8)` into the header; `FadeAIFFMusic(0,2)` + stop; loop as New Game but
  `LevelRun(x: save+0xc, y: save+0x10, a4: 0)` and **no `G+0x16` refresh** (M l. 7044–7064); the post-map save
  position write; `ffa8` → `AskToContinue`. Death on the first game without a save → straight back to the menu
  (the Phase-2 ◇ restart is gone from the flow; it stays in the App until A1a). `FerazelLevel` (hidden switch, kept):
  New Game starting at level N ∈ `BuiltLevels` instead of 1 — the App passes it (D35).
- **Tests (6; headless, scripted input; exits reached with `LevelFlowTests.touchExit`'s helper):**
  `testNewGameStartsLevel1` (G = InitGameGlobals, chapter card, `G+0x16` from hdr) · `testLevel1ToMapToLevel2`
  (exit → stats → map → auto-walk to 2 → Return → level 2 entered with G carried (HP, coins), `save+0xc` = L2
  hdr+0x2848 − 32 (`LevelHeader.startX` − 32; W4's `testLevel2Header` pins the start, the implementer records the value); level 2's exit p1 1 → map → node 3 → Return → the ◇ report, still on the map) ·
  `testMapAbortReturnsToMenu` (Esc → OK → `GammaFadeOut(10)` → menu sequence with music 24) ·
  `testDeathWithoutSaveGoesToMenu` (no death screen; menu sequence) · `testContinueRefusals` (preview; demo; level 80;
  demo + 80 → two reports) · `testContinueFromCheckpoint` (a block saved at L1 rec 24: level 1 at the saved x/y with
  the snapshot (save point face 1/2), no chapter card, `G+0x16` not refreshed on the next level; a block naming level
  9 → the nil-level report).
- **Commit:** `FerazelCore: GameFlow — New Game and Continue loops, level ⇄ map, death → AskToContinue → reload, refusals incl. the missing level (design §9 d); 6 tests`.

### Wave 3.5 — in-level modal moments: save points, keys, pause

#### S1 — ⚑ MAJOR — The frame suspension seam and the save point (→ 329)
- **Files:** `Sources/FerazelCore/Seams/{FrameOps,FrameSuspension}.swift`, `Sources/FerazelCore/Session/{FerazelSession,SpriteWorld}.swift`
  (resumable special pass), `Sources/FerazelCore/Player/HitPlayerSprite.swift` (the 0x429 arm),
  `Sources/FerazelCore/World/Movers/BoxSprite.swift` (the 0x429 Handle re-face), `Sources/FerazelCore/Front/{LevelRun,SaveGame}.swift`
  (`.SavePointSave`/`.SaveSG` flow); `Tests/FerazelCoreTests/SavePointTests.swift`; bank `save-continue.md` §2.1, §3.1
  (BC1, BC6).
- **Contract:** Invariant 6. `FerazelSession.step` returns `FrameOps.suspension` set when the special pass reaches a
  modal hit; the ops so far (the drawn part of the frame) are returned; `resume(_ outcome:)` continues the special pass
  with the **next** contact (the pass's iteration state is kept) and finishes the frame (particles, erase, status bar,
  the rest), returning those ops. `step` while suspended is a precondition failure. Save point (`.HitPlayerSprite`
  Box arm, M l. 49471–49504, raw `10057714..10057858`): type 0x429 on a **landing** (`.PlatformBounce` = 1); gate 1
  `DAT_100a53d6` (no async fade running) else return; gate 2 record p1 == 0; `C = *_DAT_100a0684 + 2`, fire only when
  C > 15 (`PlayerState.savePointHold`, its decay already built, raw `1004de68..98`); fire: C = −150, `MTSetPortScreen`,
  p1 ← facing + 1, `ShowCursorSafe`, `G+0x16` ← facing, **suspend** with `.savePoint(record)`. The flow runs
  `.SavePointSave` (SV1's writer at that moment: the player's whole-pixel x/y `fe68/fe64` of this frame's handler
  pass) → `.SaveSG(prefs[1] == 0)`: reuse (`prompt == 0 ∧ fd54`) → no dialog; else `^0` text built and unused,
  `SaveName.increment(prefs+0x42)` (the shown default is already incremented), `ShellRequest.putFile` (prompt "Please
  name your saved game.", default name, message = DITL 1003 item 13); on a good reply: `fd54 = 1` and the reply kept
  **before** writing, the name → prefs+0x42 and the prefs file written (`.UpdateSGString`, every save incl. reuse),
  then `SavedGameFile.write`; success → `fe00 = 1`; Cancel → old name back, result 0; write errors → the SV2 error
  report, result 0. `resume(.savePoint(saved:))`: success → snd 420 then 421 (`STPlayRegSound(…, 1, 0x100)`),
  `GammaFadeOutAsync(2, white 0xFFFF ×3)` + three synchronous `HandleAsyncGammaFade` steps (0 %, 50 %, 100 %) +
  `GammaFadeInAsync(0x2d)` (45 frames back from white; gate 1 stays shut until it ends); failure → p1 ← 0;
  `HideCursorSafe` both ways. The Box Handle re-faces from p1 every frame (`+0xc0 = face base + p1·0x34`, M l.
  60191–60195): face 1 statue facing right, 2 facing left, first drawn at frame n+2 (save-continue §9.1).
- **Tests (7):** `testSavePointRecordsLevels1And2` (L1 recs 24 (2377, 878), 70 (5134, 435); L2 recs 68, 76, 81; all
  p1 0, rect (0x21,0x3f,0x33,99), gravity 0, one-way) · `testHoldFiresOn15thLanding` (C after each landing frame
  2, 3 … 16 → fire on 15) · `testRefireOn56thAfterCancel` (C = −150 + 3j; fires at j = 56) · `testSuspendAndResume
  SameFrame` (the frame's ops before + after the suspension equal one uninterrupted frame's ops when the outcome is
  "cancelled" and nothing else changed) · `testSaveBlockAtSavePoint` (level 1, x/y = the handler-pass position, `+6`
  = 1, `hasSnapshot[1]` = 1, record 24 p1 = facing + 1 in the snapshot (−6 positions)) · `testSuccessFlashSequence`
  (420, 421, three gamma steps to white, then 45 fade-in frames; a second landing during them does nothing) ·
  `testReuseSavedGamesSkipsPrompt` (prefs+1 = 1 after a first save: the second save writes to the same file with no
  `putFile` request; prefs+0x42 unchanged).
- **Commit:** `FerazelCore: resumable frame (FrameSuspension) and the save point — hold counter, SavePointSave/SaveSG flow, success flash, statue faces; 7 tests`.

#### P1 — minor — `.CheckGameLoopKeys` and `.Pause` (→ 334)
- **Files:** `Sources/FerazelCore/Front/{Pause,LevelRun}.swift`, `Sources/FerazelCore/Session/FerazelSession.swift`
  (the second suspension point), `Sources/FerazelCore/Seams/FrameSuspension.swift` (`gameLoopKeys`);
  `Tests/FerazelCoreTests/PauseKeysTests.swift`; bank `engine.md` §7.2, `save-continue.md` §6 (BC15).
- **Contract:** digest A §6 (M l. 3861–4030, 3136–3270, 3380–3430). Position: after the paint wrap, before
  `.UpdateSprites` (M l. 5251–5252). Skipped while faded or an async fade runs. ⌘ (0x37) held: S (0x01) → nothing; Q
  (0x0c) → confirm "Are you sure you want to quit?" (0x100a2ccd) → OK: `PaintFrameWrap(1,1)`, `DAT_100a5106 = 1`,
  status bar, **Quit**; Cancel: redraw grid + status bar; W (0x0d) → confirm "Are you sure you want to abort this
  game?" (0x100a2cec) → OK: `DAT_100a5106 = 1` (an abort: no fades, music cut by the exit's stop); P (0x23) → Options
  (O1 model; music not paused) then redraw. Else Esc (0x35) → the abort confirm (Cancel path includes
  `PaintFrameWrap(1,1)`). Then the debounce counters (never set > 0 — dead) and Caps Lock (`BitTst(keys, 0x3e)` → key
  0x39; the App passes `capsLock`) → `.Pause`: gate `53d6`; `InputActivate(0,0)`, cursor; snd **198** (100, 0x100);
  `PaintFrameWrap(1,0)` onto the back screen + the status strip; PICT **4921** at (207,152)–(432,248); pause flag;
  stop voices `*fe24`/`*fe20` (452, 511); `FadeAIFFMusic(0,1)`; menu bar shown + menus enabled per `.UpdateMenus`
  (paused: New Game/Restore disabled, Abort Game enabled); loop: counter starts **10**, −1 per poll while Caps Lock is
  up and the app active, reset to **5** otherwise; unpause at 0 (Caps Lock already up on entry → immediate); File ▸
  Abort Game while paused → `.AbortGame` confirm → OK ends the pause and the level (abort); exit: `FadeAIFFMusic(1,2)`,
  menu bar hidden, full redraw, cursor hidden. ⌘ held alone is still use-item in `.HandleKeys` (no exclusion, M l.
  47311/47353) — kept. The world map's own Caps Lock / ⌘ / Esc handling is M1's (it reuses this pause).
- **Tests (5):** `testPauseCounter` (Caps Lock up after k down polls → unpause 5 polls later; up on entry → immediate;
  released before the first poll → 10) · `testPauseEntryAndExit` (198, banner rect, stops 452/511, music out 24 × 1 tick,
  menu state paused; exit music in 24 × 2 ticks) · `testEscAbortEndsLevelWithoutFades` (LevelEnd .aborted; no
  `FadeAIFFMusic(0,2)`, no GammaFadeOut; `.stop`) · `testCommandQConfirmQuits` (OK → quit request; Cancel → the frame
  resumes, the same frame's `.UpdateSprites` runs) · `testKeysIgnoredWhileFading` (during the first 41 iterations'
  async fade-in Esc does nothing).
- **Commit:** `FerazelCore: CheckGameLoopKeys (⌘Q/⌘W/⌘P/Esc) and Pause (Caps Lock, banner, music, menus); 5 tests`.

### Wave 3.6 — talk

#### C1 — ⚑ MAJOR — Conversations and signs (→ 341)
- **Files:** `Sources/FerazelCore/Talk/{ConversationRun,ConvActions}.swift`, `Sources/FerazelCore/Player/HitPlayerSprite.swift`
  (NPC and sign arms), `Sources/FerazelCore/World/Movers/BoxSprite.swift` (the NPC Handle's rect arm),
  `Sources/FerazelCore/Player/{Player,PlayerState}.swift` (talk cooldown `*PTR_DAT_100a06cc`),
  `Sources/FerazelCore/Front/LevelRun.swift`; `Tests/FerazelCoreTests/ConversationTests.swift`; bank
  `conversations-mcnv.md` (BC20).
- **Contract:** digest E §1–§4 (M l. 49199–49303, 65678–65940, 66025–66560, 61120–61134). NPC arm (types
  0xb87…0xb99): `+0xb0 == 0` ∧ cooldown 0 → cooldown **150**, suspend `.conversation(p1, rec, sprite)`, return (never
  `.PlatformBounce`). Sign arm (2902…2909 except 2907, 2833…2836): (UP held ∨ record p4 == 0) ∧ p1 ≠ 0 ∧ cooldown 0 →
  cooldown **90**, p4 ← 1, then 2902 with p1 > 0 → `.sign(STR# 500[p1])` (`.SimpleConv(4020, "Wooden Sign", text)`),
  other types with p1 > 100 → `.conversation`; 2902 then falls through to `.PlatformBounce` (`+0x15c` = 1). The cooldown
  is cleared by `.ClearPlayerVars` and decremented in `.HandlePlayerSprite` (M l. 42585, 44912). NPC hot rect from the
  Handle's NPC arm (M l. 61120–61134: `+0x34/+0x38` from the face's +8/+0xc; 2957 with p3 → facing left).
  `ConversationRun` (`.Conversation`, `.HandleConvLine`, `.HandleLineResponses`, `.HandleLineActions`, `.SimpleConv`):
  index 19 entry; Escape (0x35) → index 21 + abort; negative index → silent jump; portrait/erase rules (index 0 skips
  both); typing at **2 ticks per character** (any input key held → no delay), the 10-slot trail, the final 9-step
  flush; `ConvPressAnyKeyDeadTime` (any key or the button); all-keys-up waits; the response menu (portrait 4001, name
  "Ferazel", input 2 up, input 3 down (only to a response with a target), inputs 5–8, Return, Enter confirm);
  conditions 1 coins ≥ A, 2 item A count ≥ B (spell flag 0), 3 never, 4 own record p(A+1) ≠ 0, 5 world flag A == B;
  a true condition jumps to its target and skips the actions and next; actions 1 coins −= A (floor 0) + coin text
  redraw, 2 give item A × max(B,1) (first empty-or-matching slot, count ≤ 99, snd 501 [MED id], HUD ◇ Phase 4), 3
  remove item A × max(B,1), 4 own record p(A+1) = 1, 5 world flag A = B, 6 record A p(B+1) = 1, 9 the talker's
  `+0xe9 = 1` + its record spawn byte 0, 10 the save block's snapshot record A of level B spawn byte = 1; 0/7/8 nothing.
  Targets: 20 → 999, t > 0 → t − 1, t < 0 → t + 1; next 0 → i + 1 wrapping 19 → 0; ≥ 20 ends. On end: restore the
  view (`restoreView`), wait for all keys up, resume the frame. Text layout (wrap 214 px, line step 18) is Render's (C2);
  Core counts characters and lines in bytes.
- **Tests (7; data: digest E §1, §6):** `testTalkersAndSignsLevels1And2` (L1: signs recs 1/6/48/125 → STR# 500 [12]/[11]/
  [4]/[13], merchant rec 12 → Mcnv 200, Geroditus rec 157 → 201; L2: signs 14/185 → [7]/[9], Serinus rec 188 → 203) ·
  `testMcnv201FirstVisitAndRevisit` (first: #1, then #2 … #15 (14 lines), own p2 set; next touch after the cooldown: #16
  only) · `testMcnv203FiveLines` · `testMcnv200NotEnoughCoins` (coins 0: menu #3 with 4 replies → shop #5 → Magic Potion
  → #12 "not enough"; coins 30 → #7: coins 0, item 4 ×1 in G) · `testSignAutoReadThenUp` (first touch reads (p4 0 → 1);
  no re-read without UP; UP re-reads after 90 frames) · `testTypingTimeline` (a 20-character line → 40 ticks; key held
  → 0; trail greys 36000 … 4000 on odd ages) · `testEscapeAtAnyKeyStillRunsActions` (Esc at "press any key" on a line
  with an action → the action runs, then the conversation ends).
- **Commit:** `FerazelCore: conversations (Mcnv interpreter, NPC arm, cooldown 150) and signs (STR# 500, cooldown 90) in the suspended frame; 7 tests`.

#### C2 — minor — Conversation drawing and text layout (→ 344)
- **Files:** `Sources/FerazelRender/Screens/ConversationRenderer.swift`, `Sources/FerazelRender/Frame/{TextRasterizer,StatusBar}.swift`
  (protocol additions; the status bar keeps its output), `Ferazel/App/CoreTextRasterizer.swift`,
  `Tests/FerazelRenderTests/StatusBarTests.swift` (`BoxRasterizer` gains the new requirements),
  `Tests/FerazelRenderTests/ConversationRenderTests.swift`.
- **Contract:** digest E §3, §7. Frame PICT **4000** (Sprites, 387×308) at origin (126, 46) copied with mode 0x24
  (its 18,627 pure-white pixels show the game view through); portraits 3999…4033 (96×96, 32-bit, ditherCopy → the
  existing `ConvertedPicture`/`Dither` path) at frame (24,49,120,145); name centred in 180 px from x 19, baseline 276,
  black; text Times (20) 18 plain srcOr from x 154, first baseline 43, wrap at 214 px (the running CharWidth sum incl.
  spaces; break at the last space, the space dropped), line step 18; trail greys (10−age)·4000 per component through
  `ColorSearch`; responses grey 0x5555, the selection black, row offsets from TextEdit line heights
  ((lines+1)·lineHeight of a 214 × 400 box); erase rects (154,29,372,221), (19,260,199,300); the sign uses portrait
  4020 and "Wooden Sign". `TextRasterizer` additions (S4) implemented by `CoreTextRasterizer` (CoreText Times 18,
  thresholded at coverage ≥ 0x80 like the status bar) and the tests' `BoxRasterizer` (fixed 6-px advance).
- **Tests (3):** `testConversationFrameTransparent` (18,627 view pixels unchanged under the frame) · `testWrapAt214`
  (`BoxRasterizer`: a 60-byte line breaks after the last space before 214 px; lines at baselines 89, 107 on screen) ·
  `testSignFrameGolden` (L1 sign rec 1 fully typed over a level-1 frame, `BoxRasterizer`, FNV-1a, self-derived).
- **Gate:** G5 (touches the App). **Commit:** `FerazelRender: conversation frame (transparent copy), portraits, Times 18 layout and wrap, trail colours; TextRasterizer widths/metrics; 3 tests`.

### Wave 3.7 — the app

#### A1a — ⚑ MAJOR — App on `GameFlow`: ticks, input, music, files, Finder open
- **Files:** `Ferazel/App/{FerazelController,FerazelAudio,FerazelFiles}.swift`, `Ferazel/App/Info.plist` (document type
  'FWSg' / `CFBundleDocumentTypes` for Finder opening), `Sources/FerazelCore/Flow/LevelFlow.swift` +
  `Sources/FerazelCore/Session/FerazelSession.swift` (remove the Phase-2 ◇ helpers listed removable in S3),
  `Tests/FerazelCoreTests/LevelFlowTests.swift` (its three ◇ tests rewritten for the Phase-3 contract — `LevelFlow.next`
  only, the death path via `LevelRun`, carried G — names may change, **count stays 6**).
- **Contract:** S5. The idle timer calls `GameFlow.tick(now: ShellClock.ticks(), input:)`; input = `pollKeyState()`
  (held → `KeyState`, `capsLock`), the mouse in canvas coordinates (`ShellScaling.logicalPoint`, nil outside),
  `NSEvent.pressedMouseButtons & 1`, `NSApp.isActive`. The `Ending` struct and the 2-tick logic leave the App (Core
  owns them). One `ScreenSurface` shared by the level `FrameRenderer` (rebuilt per level) and the `ScreenRenderer`;
  present through `presentedClut` then MacGamma as today. Music: `.play` starts at volume 0; `.volume` applies; `.stop`
  stops and **unloads** the track (K1; owns the Phase-2 "tracks never unloaded" carry). Effects as today (`SoundTool`).
  Files: the folder `~/Library/Application Support/Ambrosia Classics/Ferazel's Wand/` (created on demand); prefs file
  "Ferazel's Wand Prefs" read at launch (absent → defaults written, `.InitPrefs`), written when the flow asks (Options
  close, music/sound toggles, save name); `putFile` → `NSSavePanel` (title/prompt "Please name your saved game.",
  message = DITL 1003 item 13, default name, initial folder = the Ferazel's Wand folder); `getFile` → `NSOpenPanel`
  (message "Please select the saved game from which you would like to continue.", type 'FWSg' or any file); results
  back through `fileDone`. `application(_:open:)` (Finder open, `.DoOpenDocAE`) → Continue with that file when no level
  is running (else ignored). `FerazelLevel` launch switch → `GameFlow` New Game at that level (1...2). Load progress
  callback while the renderers load faces (the boot bar). Quit request → `NSApp.terminate`; `applicationShouldTerminate`
  from the system → the flow's Quit sequence first.
- **Gate:** G5; G2 = 344 (LevelFlowTests rewritten, count unchanged). **Commit:** `Ferazel app: driven by GameFlow (ticks, mouse, Caps Lock), shared screen, music fades + unload, prefs and saved-game files, Finder open`.

#### A1b — ⚑ MAJOR — App dialogs and menus
- **Files:** `Ferazel/App/Dialogs/{FerazelCarbonDialog,DialogViews,FerazelDialogs,PrefsDialogView,CreditsDialog}.swift`,
  `Ferazel/App/FerazelMenus.swift`, `Ferazel/App/FerazelController.swift`.
- **Contract:** `ShellRequest.dialog` cases rendered as the original's Dialog Manager windows from R1's templates
  (adapting `BubbleTroubleX/App/BTXCarbonDialog.swift`: an `NSPanel` per DLOG with the DITL items at their rects in
  points, default button framed (3 px, radius 15), ParamText `^0`, `AppendDITL`/`ShortenDITL`, popups from CNTL → MENU,
  checkboxes, edit fields): DLOG 202 confirm (OK = item 1, Cancel = item 2, PICT 145), DLOG 200 report, error alerts
  (report with the code), DLOG 6900 Options over `PrefsDialogModel` (O1; `HiliteColor` (30000,30000,65535); the grey
  outline user item; key capture through the model; key names via the current keyboard layout), DLOG 600 Credits
  (PICT 4804 + the scrolling 4803 strip from `CreditsScroll`, click inside to close, outside beeps). While a dialog is
  up the flow does not tick (BTX D13.6 precedent). Menus: MBAR 128 → AppKit: Apple menu "About Ferazel's Wand…" (→
  Credits) inside the app menu; File (New Game ⌘N, Restore Game... ⌘O, Abort Game ⌘W, Quit ⌘Q); Game (Music ⌘M, Sound
  Effects ⌘F, Preferences… ⌘P); check marks from prefs +0x0c/+0x0b; enable rules `.UpdateMenus` (paused vs not);
  **menus act only where the original processed menu events — the main menu loop and the pause loop** (`MenuState`
  from the flow); elsewhere every item is disabled so ⌘-keys fall through to the polled game keys (owns the Phase-2
  "⌘Q quits without asking" carry). The macOS app menu keeps only About and the existing hidden Full Screen item; the
  system Quit item is replaced by File ▸ Quit. In full screen the menu bar shows on the flow's `showMenuBar` request
  (pointer v < 21 at the menu, during pause) and hides otherwise; windowed, the macOS menu bar stays visible (D35
  deviation).
- **Gate:** G5. **Commit:** `Ferazel app: the original's dialogs (abort/quit confirm, reports, Options with key remapping, Credits) and menus (MBAR 128, enabled where the original listened)`.

### Wave 3.8 — phase end

#### A2 — minor — Stage + WHAT-TO-EXPECT + the Phase 3 gate card
- **Files:** `Ferazel/WHAT-TO-EXPECT.md` (rewritten for Phase 3), `tools/stage-ferazel.sh` (only if needed).
- **Gate:** G1, G2 = 344/0, G3, G5, G7, G9 (+ the boot reaches the menu), G10. Then the FABLE-GRADE phase review over
  the phase diff + the card (D34), its fixes, re-stage. **STOP for Ben** (QUESTIONS item).
- **Commit:** `WHAT-TO-EXPECT: Phase 3 gate card (title → level 2 and back)`.

---

## What Ben checks — the Phase 3 gate card ("title → level 2 and back")

Play `~/Desktop/Ferazel's Wand.app` from a cold start, with the keypad (4/6 walk, 8 up, 5 down, Shift run, Option jump,
⌘ use), side by side with the Let's Play (https://www.youtube.com/watch?v=ESuyxMUEzDw) and longplays.
1. **Title** — black, the Ambrosia publisher logo fades in with the title music (track 24), stays while it loads, fades;
   the loading screen with the 3-D progress bar at the bottom left fills; fade to the main menu. No timed wait, no skip
   (the original's).
2. **Main menu** — five image buttons light when pressed (click and hold; slide off and back), with the click sounds;
   letters N / O or R / I or P / C / Q do the same; X shows the "Coming soon" joke. The mouse at the very top shows
   the menu bar in full screen.
3. **Options (I)** — three panels from the popup: Game Options, Controls (click a key box, press a key; a key already
   in use is refused; Up and Jump may share), Sound & Music (volume popups 1–9 act at once). "Default Settings" on
   Game Options seems to do nothing until you press Cancel — the original's bug, kept. The settings survive a relaunch.
4. **Credits (C)** — the scrolling credits window; click inside it to close.
5. **New Game (N)** — the chapter card "intro" fades in slowly (any key skips; it waits about 20 s otherwise), fades out,
   then the loading popup, then level 1 fades in while the music fades up.
6. **Talk** — near the start Geroditus talks (text types at about 30 letters a second, fading in); signs read
   themselves the first time you touch them and again with 8. Esc ends a conversation. The trader at the far right
   (Rojinko) talks and offers potions (buying needs coins; the potions you'd get don't show in the HUD until Phase 4).
7. **Save point** — the pedestal with the green check (level 1 near x 2377): stand on it ~½ s → the save panel (macOS's
   own, see deviations) suggesting "Ferazel Saved Game"; save → a white flash, the pedestal becomes the stone statue
   facing your way; it works once. Cancel → the point stays usable (it re-arms after ~2 s of standing).
8. **Caps Lock** — pause: the pause banner, the music fades out, the menu bar appears (File ▸ Abort Game works here);
   Caps Lock up → resumes with the music fading back.
9. **Exit level 1** — the stage-complete panel unfolds, three bars fill with the ticking sound and a final chime per
   bar (enemies, Xichrons, secrets — enemies don't die until Phase 5, so expect a low first bar), then fade.
10. **World map** — fades in with its own music; the new link to Central Caverns flashes in random colours, the marker
    walks there by itself; arrows or keypad move along links (unlocked only); Return / Option / ⌘ enters. The status bar
    shows the level name.
11. **Level 2** — enters like level 1 (no chapter card: level 2 has none). Its exits unlock Western/Eastern Reaches on
    the map; choosing them shows a stand-in "not built yet" message (levels 3+ come with Phases 4–6).
12. **"…and back"** — Esc (or ⌘W) → "Are you sure you want to abort this game?" → OK → the main menu with its music.
    ⌘Q in a level asks "Are you sure you want to quit?" first.
13. **Resume (O)** — pick the saved game: level 1 at the save point, the statue still there, no chapter card.
14. **Death** — die (drown or the acid): the border wipe; with a save this game → the death screen (Continue / Abort):
    Continue → the wand glow, back at the save point; Abort → the screen turns gray and black, back to the menu.
    Without any save this game → straight back to the menu (the original has no death screen then).
15. **Readings Ben can't see but may feel (MED):** fade speeds (the Monitor Tool's timing, converted to 60 Hz ticks), the
    held-⌘ quirk on the map (an idle ⌘ enters the level), the stretched panel rows, the boot logo under clut 128, Times
    18 drawn by modern CoreText.
Known stand-ins/deviations: only levels 1–2 can be entered; the HUD shows the start inventory whatever G holds (Phase
4); enemies stand still (Phase 5); the macOS save/open panels replace Standard File; in a window the macOS menu bar
stays visible (its items are disabled during play); `-FerazelLevel 2` still starts a New Game on level 2.

---

## Execution order

The canonical order is the execution order (each task starts from the previous task's merge):

| wave | tasks, in order | review legs (all Opus) | run (2 tasks, 3 when ≤ 1 ⚑) |
|---|---|---|---|
| 3.0 | K1 → X1 → R1 | one each | run 1: [K1 X1 R1] |
| 3.1 | SV1 ⚑ → SV2 → FE0 ⚑ → O1 | SV1, FE0 two; SV2, O1 one | run 2: [SV1 SV2]; run 3: [FE0 O1] |
| 3.2 | L1 ⚑ → L2 | L1 two; L2 one | run 4: [L1 L2] |
| 3.3 | M1 ⚑ → M2 | M1 two; M2 one | run 5: [M1 M2] |
| 3.4 | F1a → D1 → F1b ⚑ | F1b two; F1a, D1 one | run 6: [F1a D1 F1b] |
| 3.5 | S1 ⚑ → P1 | S1 two; P1 one | run 7: [S1 P1] |
| 3.6 | C1 ⚑ → C2 | C1 two; C2 one | run 8: [C1 C2] |
| 3.7 | A1a ⚑ → A1b ⚑ | two each | run 9: [A1a A1b] |
| 3.8 | A2 (+ FABLE-GRADE phase review + fixes) | one + Fable | run 10: phase end |

- **Dependencies:** SV2 after K1 (writer); FE0 after R1 (`FerazelDialog` texts) and SV1 (G in `FrontOutput`'s flow);
  O1 after R1 + SV2; L1 after SV1 + FE0; L2 after FE0; M1 after SV1 + FE0 (+ L1's `LevelEnd`); F1a after FE0; D1 after
  FE0; F1b after L1, L2, M1, D1, SV2; S1 after L1 + SV2; P1 after S1 (suspension) + O1; C1 after S1; C2 after C1; A1a
  after every Core task; A1b after A1a + O1 + R1.
- **File overlaps that force order:** `FerazelSession.swift` (L1, S1, P1, A1a), `LevelRun.swift` (L1, S1, P1, C1),
  `GameFlow.swift` (F1a, F1b), `HitPlayerSprite.swift` (S1, C1), `BoxSprite.swift` (S1, C1), `ScreenRenderer.swift`
  (FE0, L2, M2, D1), `FerazelController.swift` (FE0 no-op arms, A1a, A1b), `GameGlobals.swift` (SV1 only),
  `FerazelPrefs.swift` (SV2 only), `LevelFlow.swift` (SV1, L1, A1a).
- No ◈ task (see Verification model). A task merged out of order rebases; the orchestrator adjusts the ladder by N.

---

## Stand-ins kept (◇, named) and the phase that replaces them

| ◇ | where | replaced by |
|---|---|---|
| `BuiltLevels = 1...2` + the "not built yet" report | F1b | Phases 4–6 widen it level by level as each level's Setups are transcribed |
| HUD shows `StatusBar.startInventory`, not G's inventory (conversation action 2/3 write G) | C1 | Phase 4 (inventory) |
| USE-item hint `.SimpleConv`s (keys/shields/red Xichrons) | not built | Phase 4 |
| Escape Ring (`fd64`, exit −1) built as read, unreachable | L1 | Phase 4 (the item) |
| `.Victory` after the loop (`*ffc4`) — never set | F1b | Phase 6 |
| 1058 world-flag trigger (L2 rec 228) not handled — flags saved but never set on L1/L2 | SV1 | Phase 4 (Bonus class) |
| `FerazelLevel` hidden switch = New Game at level N ∈ 1...2 | A1a | kept as a hidden test path (D35); widens with `BuiltLevels` |
| Phase-2 ◇ `LevelFlow` mapping, restart-after-death, App `Ending` | removed in A1a | — (gone) |

## Phase 2 carries owned (from STATE / D33 as built)

| carry | owner |
|---|---|
| death restart has no `GammaFadeInAsync(0x28)` (M l. 5228) | L1 (every entry) |
| exit skips `.StageCompleteEffect` / `GammaFadeOut(6)` / `.EndLevelSGUpdate`, loads level 2 at once | L1 + L2 + M1 + F1b |
| no music fade-in (M13) | FE0 (`MusicFade`) + L1 (`FadeAIFFMusic(1,4)`) + A1a (`.play` at volume 0) |
| music tracks never unloaded | K1 (`ShellMixer.unload`) + A1a (`.stop` unloads; `SetAIFFMusic` stops first) |
| Caps Lock / Esc do nothing | P1 (+ M1 on the map) |
| ⌘ is use-item and also ⌘Q (quits without asking) | P1 (polled ⌘Q confirm; ⌘ held stays use-item — the original) + A1b (menus disabled during play) |
| `FerazelLevel` loads 1–2 only | F1b/A1a (`BuiltLevels`) |
| level 2's exits restart level 2 | M1 + F1b (map unlocks 3/4; ◇ report) |
| crunch-log re-apply on revisit; G fields not modelled; G+0x176 | SV1 + L1 |
| `200..<210` literals; FastRand doc cite; redundant `stopEffects`; jump-frame `soundStopAt`; PlayerConstraints order test | X1 |
| `beginEnding` placeholder phase | A1a (the `Ending` struct goes) |
| M6, M7 | carried → Phase 4 (named in X1's commit body) |
| `ParticleLife` vs CLUT 222 rows (levels 52/55) | carried → the phase that loads 52/55 |
| lost coins drawing with no free record | carried → Phase 4 |
| later-phase `3DSoundRand` idle-only sites (M l. 62997, 63199–63257, 61047–61057) | carried → Phase 4/5 plans (Invariant 4 conflict) |

## Known deviations (forced by the platform; recorded in D35)

1. **File dialogs:** macOS `NSSavePanel`/`NSOpenPanel` replace Standard File's `CustomPutFile`/`CustomGetFile` (DITL
   1003/1500); the prompt and DITL 1003's static text are carried into the panel.
2. **Saved-game file:** the classic resource map is written **into the data fork** (portable, Windows-ready, survives
   git/zip), with HFS type 'FWSg' / creator 'Msct'; the reader also accepts a real resource fork, so an original save
   resumes. A save written here is not readable by the original 1.0.3 without moving the map into the resource fork.
3. **Prefs file:** "Ferazel's Wand Prefs" (same record) in Application Support, not the System Folder's Preferences.
4. **Menu bar:** hidden only in full screen (HectorShell); windowed, the macOS menu bar stays visible with its items
   disabled wherever the original did not listen for menus.
5. **Fonts:** Times 18 / Times 12 bold come from CoreText (the game ships no bitmap fonts; digest E §7).
6. **Tick:** 60 Hz (D30), not 60.15 Hz; Monitor-Tool millisecond fades rounded up to ticks.
7. Never-initialised bytes of G, the prefs record and the save block are written as 0 (Invariant 7).

---

## Pre-execution self-audit

1. **Design §8 Phase 3 row coverage.** title (F1a, FE0) ✅; menu (F1a, A1b) ✅; options/prefs (O1, SV2, A1b) ✅; world
   map + unlock (M1, M2) ✅; chapter screens (L2) ✅; save points (S1) ✅; Resume/Continue (F1b) ✅; death (L1, D1, F1b)
   ✅; level complete + stats (L1, L2) ✅; conversations (C1, C2) ✅; Esc/pause (P1, M1) ✅; design §9 (d) (F1b) ✅.
   Gate "title → level 2 and back" walks every task (card items 1–14).
2. **Numbers sourced.** Every number cites an M line / raw address / digest section; self-derived numbers are named
   (L1 totals, FE0/M2/C2 goldens, map stream state, M1 walk positions, L2 sound lengths) and re-derived by a second
   run. Digest numbers re-checked by the planner against the dump: `.GameLoop` entry M l. 5180–5228 (unlock, `GammaFadeIn(8)`
   gate, `SetAIFFMusic`, `FadeAIFFMusic(1,4)`, chapter gate, `GammaFadeInAsync(0x28)`), exit M l. 5296–5325, `.StageCompleteEffect`
   M l. 2896–2943, `.NewGame` loop/tail M l. 5808–5874, function heads (`.SetupLevel` 2189, `.Pause` 3136, `.AskToContinue`
   3718, `.CheckGameLoopKeys` 3861, `.ChapterScreen` 5038, `.NewGame` 5704, `.SavePointSave` 6322, `.ContinueGame` 6663,
   `.MainMenu` 7303, `.InitPrefs` 7694, `.SaveSG` 41179, `.OpenSG` 41315, `.PreferencesDialog` 64233, `.SimpleConv` 65940,
   `.HandleConvLine` 66378, `.Conversation` 66441, `.ShowWorldMap` 67432).
3. **Names checked against the code.** `FerazelSession.step(keys:)`, `.carry`, `.rngSeed`, `.deathEffectDone()`,
   `restartWithFreshGlobals`; `LevelFlow.next/phase2Level/exitRequest`, `LevelCarry`; `GameGlobals` fields;
   `FerazelPrefs` fields; `DrawOp.drawPicture(id:chain:h:v:)` with `ResourceChain`; `DrawOp.gammaStep`; `RGB16`;
   `MusicCue .play/.stop/.volume`; `ShellRequest` six cases; `WorldMap`, `WorldFile.stamp`, `Conversation`,
   `StringList`; `FrameRenderer`, `ScreenGamma`, `DeathEffect`, `StatusBar`, `TextRasterizer`, `ConvertedPicture`,
   `ColorSearch`, `SoundTool`, `SoundBank`; App `FerazelController`/`FerazelAudio`/`CoreTextRasterizer`, `Ending`;
   HectorKit `ClassicResourceMap`, `ShellMixer`, `ShellClock.ticks()`, `ShellView.pollKeyState().capsLock`,
   `ShellScaling.logicalPoint` (digest F). New names are defined once in S2–S5.
4. **Ladder arithmetic.** 256 + (R1 4 + SV1 6 + SV2 6 + FE0 6 + O1 5 + L1 8 + L2 5 + M1 8 + M2 3 + F1a 5 + D1 4 + F1b 6 +
   S1 7 + P1 5 + C1 7 + C2 3 = 88) = **344** ✅; cumulative: 260, 266, 272, 278, 283, 291, 296, 304, 307, 312, 316, 322,
   329, 334, 341, 344 ✅. K1's 3 tests are HectorKit's (floor 328 → 331).
5. **Layering.** Core gains no AppKit/CoreGraphics; file I/O is Foundation; text metrics live behind `TextRasterizer`
   in Render/App; G7b added. HectorKit change is generic (resource writer, mixer unload; no game words).
6. **Risk.** Biggest: the resumable frame (S1) — the special pass must resume at the next contact with identical state;
   `testSuspendAndResumeSameFrame` pins it. Second: `GameFlow` size — split F1a/F1b, pause and talk in their own
   tasks. Third: dialogs on AppKit (A1b) — adapted from BTX's proven code, no kit lift this phase.

---

## Open questions for Ben (non-blocking; execution does not wait — D34)

1. **Saved games in the data fork** (deviation 2): fine, or should the replica write a real resource fork (readable by
   the original on a classic Mac, but stripped by zip/git/Windows)? Default: data fork, reads both.
2. **macOS save/open panels** instead of the 1997 Standard File dialogs — fine? Default: yes.
3. **Windowed menu bar** stays visible (items disabled during play) — or would you rather the windowed game hide it
   while a level runs, as the original did on its full screen? Default: visible.
4. **`-FerazelLevel N`** kept as a hidden "New Game at level N" path for testing — keep or retire? Default: keep.
5. **Death without a save** now returns to the main menu, as the original (no restart any more). Just so you know.
6. **Prefs 'A' key:** the original's key scan reads an uninitialised slot, the replica's is 0, so the A key is refused
   as "already used" in Controls (LOW). Keep (faithful to a zeroed record) or treat the slot as empty?

---

## Bank corrections to append (each as a ⚑ planner note in the named file, by the task named)

BC1 save-continue §2.1 — success flash colour **white** (0x100a53ca FFFF×3); `GammaFadeOutAsync`'s r6/r7 (0xc, 0x10)
unread; `MTSetPortScreen` (1005777c), `ShowCursorSafe` (100577a4), `HideCursorSafe` (10057858) (S1).
BC2 save-continue §3.3 — 0xe1998..0xe7d97 never accessed; L < 100; the 512th 16-byte slot unused (SV1).
BC3 save-continue §4 — the three refusals are independent tests (a demo save at ≥ 80 shows two dialogs) (F1b).
BC4 save-continue §4 — `_DAT_100ab9ba ← save+8` (F1b).
BC5 save-continue §3.4 — `.OpenSG` disposes the old block before `GetResource`; on "not a saved game" the handle stays
nil and the file open; `GammaFadeIn(0x14)` before the dialog (F1b).
BC6 save-continue §3.1 — `.SaveSG` commits `fd54`/`fd18` before writing and calls `.UpdateSGString` on reuse saves too (S1).
BC7 engine §9 — G+0x20 is a u8; +0x16, +0x20, +0x22 and the crunch pairs are not initialised by `.InitGameGlobals`;
+0x55e/+0x626/+0x946/+0xa0e never accessed; no pointers in G (SV1).
BC8 save-continue §6 — key 0x76 (F4) during `.SetupLevel` clears `G+0x176+2L` **ungated** (raw `100047e0..10004810`) (L1).
BC9 world-data §4.3 — `.FillPercent` animates pct/2 rows + one final row; bands on n2 = (pct/2)·2; 801 at vol 0xab; 804
before the band; waits 4 then 22/12 (raw `10005684..100057bc`) (L2).
BC10 save-continue §5 — the death-screen cursor move plays snd **4803** at prio 10 / vol 0x55 (not "snd 10") (D1).
BC11 engine §4 / STATE carry text — `SetAIFFMusic` stops and disposes the previous track; every track starts at volume 0
and `FadeAIFFMusic(1,4)` fades it in (raw `10049388..`, `1004974c..`) (L1).
BC12 Phase-2 plan F1 review note — re-entering a level with its snapshot flag re-destroys crunch tiles with explode 0:
**no** `.ExplodeFaceIntoParticles` draws (raw `10004874`) (L1).
BC13 engine §4/§6 — `GammaFadeInAsync(0x28)` is unconditional at every level entry (M l. 5228); only `GammaFadeIn(8)`
uses a4 ∧ hdr+0x2712 (L1).
BC14 world-data §4.2 — ⌘Q on the map → quit confirm, ⌘W/Esc → abort confirm; moves = actions 0–3 **and** arrows
0x7b–0x7e; select = Return/Enter/actions 5/6; ties make the vertical primary; `.InitPlayerMapData`'s copy is dead;
node faces centred on (h, v) (slop 8); the auto-walk after one new link; p2 stored only when ≠ 0; the map draws
FastRand; STR# 1000 spellings differ from Mlvl names on levels 1, 10, 50, 51, 67 (M1).
BC15 engine §7.2 — pause counter starts 10, resets to 5; the debounce `PTR_DAT_1009fe14` is never set > 0;
save-continue §6 — the menu bar and menus are live inside `.Pause`; reveal at v < 0x15, accept at v < 0x14 (P1, F1a).
BC16 rendering-omnipx-titles §4.3 — `GammaFadeIn(n)` passes min(100, p·3n/100) (0…18 for n 6), not a 0→100 percent
(lighting-tables §10 is right) (FE0).
BC17 engine §8 — +0x0e sound-effects volume (play scale v·28); +0x36 "Set system volume on startup"; +0x24/+0x26/+0x28/
+0x2c/+0x2e never initialised; +0x2a/+0x30 reset by the Controls defaults (SV2).
BC18 save-continue §8.2 — Game Options "Default Settings" writes the record, not the working copy (raw `10076528`); the
item 26 → 30 slip (raw `10076944`); panels DITL 6902 (Controls, key capture) and 6903 (Sound & Music) (O1).
BC19 rendering-omnipx-titles §4.1 — snd 199 (the slide-in/out joke) exists in no fork: silent (F1a).
BC20 conversations-mcnv §3.2/§6 — both frame copies use CopyBits mode 0x24 (transparent; raw `10079870`); index 0 skips
the erase too; the per-line DeadTime is for spoken text only and not after the last line; Escape at "press any key"
still runs the line's menu/actions (HIGH); the conversation GWorld is made at boot with a nil ctab [MED] (C1, C2).

---

## Research notes (where every number came from)

Five research digests (2026-10-14, Opus legs, read-only, not committed): **A** boot/menu/options/prefs/menus/in-game
keys (DLOG/DITL/MENU/CNTL decoded from the app fork); **B** world map + unlock (Mmap 200 and STR# 1000 decoded; the
exit table of all 24 levels); **C** level entry/exit, chapter, stats, death screen, `.SetupLevel` restore, music
fades; **D** save block, G layout, save point, SaveSG/OpenSG/ContinueGame (L1/L2 save-point records decoded); **E**
conversations, signs, NPCs, text (L1/L2 talker/sign records, Mcnv 200/201/203 flows, PICT 4000 white count); **F**
the replica's code and HectorKit inventory (names, seams, 256 tests by file, `project.yml`, HectorShell abilities).
No shipped `.FWSg` save exists in the repo or the archive mirror (digest D §7) → save tests use synthetic blocks.

---

## Rulings (→ DECISIONS D35, copied by the orchestrator)

1. **Scope:** design §8 row 3 in full + design §9 (d); out: inventory/pickups (4), enemies (5), bosses + `.Victory` (6),
   InputSprocket, resolution switching, CD check, birthday, debug keys (F4 0x76 is not debug-gated and is built).
2. **◇ `BuiltLevels = 1...2`:** the map behaves as the original; entering a level whose Setups are not transcribed
   shows a stand-in report and stays on the map; later phases widen it.
3. **The front end is Core state machines on 60 Hz ticks** (`GameFlow` and its parts); the in-level 2/4-tick cadence
   moves from the App into Core (`LevelRun`); blocking original loops block the flow; ms fades → ticks rounded up [MED].
4. **Modal moments run inside the frame** (resumable frame, `FrameSuspension`): save point, conversation, sign at the
   special pass; Esc/⌘Q/⌘W/⌘P/Caps Lock at `.CheckGameLoopKeys`.
5. **One RNG stream for the whole game**, owned by `GameFlow` between levels; the map draws from it.
6. **Byte-exact persistence:** G 0x19978, save block 0xebe58, prefs 0x942, big-endian; never-initialised bytes as 0.
7. **Files:** prefs and saves under `~/Library/Application Support/Ambrosia Classics/Ferazel's Wand/` (design §7.5);
   saved games = a classic resource map in the **data fork** + type 'FWSg'/creator 'Msct'; reader also takes a real
   resource fork; macOS save/open panels replace Standard File. `UserDefaults` keeps only the hidden switches.
8. **Menus:** MBAR 128 transcribed; items act only in the main-menu and pause loops (elsewhere disabled so ⌘-keys reach
   the polled game keys); windowed the macOS menu bar stays visible.
9. **Dialogs:** the original's DLOG/DITL dialogs on AppKit, adapted from BTX's `CarbonDialog` into `Ferazel/App/Dialogs/`
   (no HectorKit lift this phase; revisit when Phase 7 needs in-window dialogs on Windows).
10. **HectorKit K1 (HK D16):** `ClassicResourceWriter` + `ShellMixer.unload(id:)`, floor 328 → 331.
11. **Design §9 (d):** a save naming a missing level is refused with "Tried to open a level that wasn't there!" (the
    original's own unshown string) and returns to the menu.
12. **Death without a save returns to the menu** (the original); D33's restart stub is retired with the App's `Ending`.
13. **`-FerazelLevel N` kept** as a hidden New-Game-at-level-N path within `BuiltLevels`.
14. **Text:** Core never measures text; Render lays it out through `TextRasterizer` (widths, metrics, per-char draw);
    the App's `CoreTextRasterizer` stands in for the classic Times bitmap strikes.

---

## Review ledger

_(to be filled: Opus leg 1 — plan vs design + bank + dump; Opus leg 2 — plan vs the code that exists; fix round;
FABLE-GRADE plan leg; fixes.)_
