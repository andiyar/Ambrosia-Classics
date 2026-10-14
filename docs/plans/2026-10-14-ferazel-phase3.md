# Plan — Ferazel's Wand Phase 3 "Front end + saves": title, menu, options, world map, chapter and stats screens, save points, Resume/Continue, death screen, conversations, pause and Esc — 2026-10-14

> Status: **DRAFT, review fix round applied — planner Opus 5.5, loop run 8 (2026-10-14); two Opus legs SOUND WITH
> FIXES + four dump verifiers folded in (see "Review ledger"); awaiting the Fable leg (D34)**.
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
(stage-load popup, gamma fade-out/in, music fade-in) → save points (type 1065) writing the original 966,232-byte saved
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
the BTX `CarbonDialog` precedent) and menus, and reads/writes the prefs and saved-game files. **HectorKit: untouched
this phase** (fix round, R-a): the resource-file writer already exists (`ClassicResourceMap.serialize(_:)`,
HK `Sources/HectorResources/ClassicResourceMap.swift:69`, with `ClassicResourceMapWriterTests`), and
`ShellMixer.load(id:…)` replaces a sound under the same id (`ShellMixer.swift:103`), so the App loads every music
track under one fixed id (the original disposes the previous track — the same observable bound on memory).

**Tech:** Swift 6.4 / Xcode 27 beta, SwiftPM tools 6.0, XCTest, macOS 15, xcodegen.

**Paths:**
```
WT      = /Users/andiyar/Developer/Ambrosia-Classics/.claude/worktrees/<lane worktree>   (branched from Classics main)
HK      = /Users/andiyar/Developer/HectorKit   (main 0c65dcb, zero-skip FLOOR 328; read-only this phase)
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
| G1 | HectorKit | clean at `0c65dcb`, floor 328, **untouched by every task** (no HK change this phase; no HK D-number) |
| G2 | `Ferazel/Core` suite | the task's ladder total, then `0` |
| G3 | census unchanged | `0`, `Totals: items 1,108 decoded, failures 0` (once per wave end) |
| G5 | app builds | `** BUILD SUCCEEDED **` — the `Ferazel` scheme in every task touching `Ferazel/App` or `project.yml`, and every wave end. No task changes `project.yml` or HectorKit, so no other app is rebuilt (Ben 2026-10-09). If one ever must, "all apps" = the schemes `Aki`, `AkiPad` (iOS: `-destination 'generic/platform=iOS'`), `BubbleTroubleX`, `Deimos`, `Ferazel` |
| G6 | scope fence | ⊆ the task's **Files** (+ `docs/DECISIONS.md` / the bank file named by the task) |
| G7 | layering | both greps empty (`Sources/ferazel-census` excluded); **plus G7b:** no `UserDefaults`, `NSSavePanel`, `NSOpenPanel` in `Ferazel/Core/Sources` |
| G8 | file hygiene | `git -C "$WT" status --porcelain --ignored -- Resources ghidra` prints nothing new; tests write files only under `FileManager.default.temporaryDirectory` |
| G9 | staged app boots (A2) | Phase 2's G9, plus: the boot reaches the main menu (no crash report), quit via the File menu |
| G10 | clean tree per commit | empty |

```sh
WT=$PWD; SCRATCH=$(mktemp -d)
# G1
git -C ~/Developer/HectorKit status --porcelain; git -C ~/Developer/HectorKit log --oneline -1   # expect 0c65dcb
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
X1 **256** → R1 **260** → SV1 **266** → SV2 **272** → FE0 **278** → O1 **284** → L2 **289** → L1 **297** → M1
**305** → M2 **308** → F1a **313** → D1 **317** → F1b **323** → S1 **330** → P1 **335** → C1 **342** → C2 **345**
(then A1a, A1b, A2: no tests). Merged in another order: previous total + the task's N. Review fix rounds add
asserts, not tests, unless the orchestrator rules otherwise (recorded "As executed").

**Goldens (◈).** Phase 1/2 goldens (STATE: `9db8f32f7e3d88b4`, `b80b0efd384ffdb9`, pan `172596fa2f3b6c58` /
`cc9786ba763d383a` / chain `b4230ba5a643c5b5`; L2 `565e867a02736c18` / `df22325e851e782d`, jump `e4f4bf977dd98eaa`, swim
`95ff5176412df650`, 600-frame `9532d65a42d39666` / cues `a875a96c2801dbe9`) are **not expected to move in Phase 3**:
every Phase-3 sequence wraps the session (`LevelRun`) and a `FerazelSession` built directly (as all existing tests do)
behaves exactly as today (the new init parameters — L1's `hostedByLevelRun`, start position, `refreshFacing` — default
to today's behaviour). **No task is ◈.** Any existing golden or count that moves is a STOP (Invariant 10). New
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
7. **Byte-exact persistence.** The save block (0xebe58 = 966,232 B), G (0x19978 = 104,824 B) and the prefs record
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
14. ⚠️ **Landmines** (Phase 2 Invariant 12 (a)–(g) still apply). (h) D-numbers: this plan's rulings are **D35** — confirm it
    is free at commit time, renumber in the same commit if taken (no HectorKit ruling this phase).
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
  `static func initGameGlobals(previous: GameGlobals?) -> GameGlobals` (`.InitGameGlobals @ 10001498`, M l. 582–825:
  the G part; `previous` supplies the fields the routine never writes, nil → 0).
- ★ `SaveBlock` (SV1, `Saves/SaveBlock.swift`) — `static let byteCount = 0xebe58`; fields `worldStamp`, `preview`,
  `demo`, `isCheckpoint`, `level`, `playerX`, `playerY`, `globals: GameGlobals`, `date`, `snapshots` (100 × 511 × 16 B),
  `worldName`; `init(image:)`, `image()`; `mutating savePointSave(…, records: [Placement])` / `endLevelSGUpdate(…,
  records:)` (the shared write core, M l. 6322ff / 6501ff; the records are the session's live `world.records`) and
  `restoreSnapshot(level:) -> [Placement]` (+6). ⚑ As built (SV1, run 9): both writers also take `globals: inout GameGlobals` — the live G — because the binary sets `hasSnapshot[L]` in the live G (raw `1000c1c0`) before the copy; G gains `appendCrunch(_:)` (O(1)).
- ★ `PrefsRecord` coding on `FerazelPrefs` (SV2) — `FerazelPrefs.init(record: Data)`, `record() -> Data` (0x942,
  unknown bytes preserved), `savedGameName` pstr, `recentNames` (+0x142, 8 pstr[256], write-only).
- ★ `SavedGameFile`, `PrefsFile` (SV2, `Saves/`) — resource-file codecs over HK's existing
  `ClassicResourceMap` (parse) and `ClassicResourceMap.serialize(_:)` (write).
- ★ `DialogResources` (R1, `Front/DialogResources.swift`) — Foundation-only parsers: `DialogTemplate` (DLOG/ALRT),
  `DialogItemList` (DITL items with type, rect, text, resource id), `ControlTemplate` (CNTL), `MenuTemplate` (MENU with
  items, ⌘ keys, enable flags), `MenuBarTemplate` (MBAR).
- ★ `ScreenFade` (FE0, `Front/ScreenFade.swift`) — the global fade state the original keeps in `*_DAT_1009fde8`
  (screen faded), `DAT_100a53d6` (no async fade running), `DAT_100a53c2` (fading enabled) and the timelines of
  `.GammaFadeOut(n)` / `.GammaFadeIn(n)` / `.GammaFadeInSlow(n)` (lighting-tables §10; digest A §1).
- ★ `MusicFade` (FE0, `Front/MusicFade.swift`) — `.SetAIFFMusic` (start at volume 0, `ShutDownAIFFMusic` first),
  `.FadeAIFFMusic(dir, t)` blocking (24 steps, V·s/24 / V·(24−s)/24, V = prefs+0x10·256/9, gates `*0448`),
  `.FadeAIFFMusicAsync(dir, N)` (digest C §6) — emitting `MusicCue`s.
- ★ `GameFlow` (F1a/F1b, `Front/GameFlow.swift`) — `final class GameFlow { init(resources: FerazelResources, prefs:
  FerazelPrefs, seed: Int32, files: FrontFiles, levels: LevelServices) ; func tick(now: UInt32, input: FrontInput) ->
  FrontOutput ; func dialogDone(_ result: DialogResult) ; func fileDone(_ result: FileResult) ; func
  loadProgress(faces: Int) /*the boot bar, F1a*/ ; var prefsDialog: PrefsDialogModel? /*while DLOG 6900 is up, O1*/ ;
  var state: GameFlow.State }`; owns `FastRand`, `GameGlobals`, `SaveBlock`, `ScreenFade`, the flags above.
- ★ `FrontFiles` (F1a, `Front/FrontFiles.swift`) — the Core-side file protocol the App implements (Foundation types
  only): `loadPrefs() -> Data?`, `storePrefs(_ record: Data) throws`, `readSavedGame(_ ref: SavedGameRef) throws ->
  SaveBlock`, `writeSavedGame(_ block: SaveBlock, to ref: SavedGameRef) throws(SaveWriteError)` (`SavedGameRef` = a
  file URL + display name; `SaveWriteError` carries the OSErr-style code SV2 maps to the four strings). Tests pass an
  in-memory or temp-directory implementation.
- ★ `LevelServices` (L1, `Front/LevelServices.swift`) — how `LevelRun` gets the renderer-side inputs a session needs
  (today the App builds the `FrameRenderer` first and passes `faceBounds:`/`particleFaces:` to `FerazelSession.init`,
  then feeds `session.lights`/`session.tintTableDraws` back, `FerazelController.swift:148–158`):
  `func prepare(level: Int) throws -> LevelFaces` (`faceBounds` + `particleFaces`) and `func attach(lights:
  tintTableDraws:) throws`. Core tests pass a stub (frame-rect bounds, no particle faces — today's session defaults);
  the App's implementation builds the per-level `FrameRenderer` on the shared `ScreenSurface`. `FrontInput = { keys: KeyState, capsLock: Bool, mouse: (h: Int, v: Int)?, button:
  Bool, active: Bool }` (mouse in 640×480 canvas coordinates; nil outside the canvas). `FrontOutput = { draws: [DrawOp],
  sounds: [SoundCue], soundStops: [Int16], soundStopAt: [Int], music: [MusicCue], requests: [ShellRequest], present: Bool,
  prefs: FerazelPrefs? }` (the same play/stop interleave rule as `FrameOps.soundStopAt`; `prefs` is set on the tick a
  `.MakeCurrPrefs` ran — Options close, ⌘M/⌘F — so the App and `FerazelAudio` refresh their copies). `Rect16` (FE0, `Seams/Rect16.swift`) = QuickDraw rect `{top, left, bottom, right}: Int16`.
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
// DrawOp — new cases, ALL added by FE0 (with every exhaustive `switch` given an arm: FrameRenderer.swift:280ff,
// SessionTests.swift:288); later tasks only give them behaviour (M2 drawFace/drawLine, C2 restoreView/drawText layout)
case fillRect(left: Int, top: Int, right: Int, bottom: Int, rgb: RGB16)          // PaintRect in a colour (Color2Index)
case copyPicture(id: Int16, chain: ResourceChain, source: Rect16, dest: Rect16, forceClut: Int16?,
                 transparent: Bool)                                              // CopyBits / CopyBitsCTForce / mode 0x24
case drawFace(set: FrontFaceSet, index: Int, h: Int, v: Int)                     // map node / marker faces (M2)
case drawLine(h1: Int, v1: Int, h2: Int, v2: Int, rgb: RGB16)                    // map links (M2)
case drawText(TextRun)                                                           // TextRun = {bytes, font, size, face, h, v, rgb, mode}
case restoreView                                                                 // .WrapCopyToScreen of the last drawn frame (C2)
case screenGamma(ScreenGammaOp)                                                  // tint fade %, FadeToColor %, identity (FE0)
// FrontFaceSet (FE0, Seams/FrontFaceSet.swift) — enum { mapMarker /*8000*/, mapNode /*8001*/, mapBoss /*8002*/,
//   mapAmbient /*8004*/ }; ScreenGammaOp (FE0, Seams/ScreenGammaOp.swift) — enum { tint(mode: Int, percent: Int),
//   fadeToColor(percent: Int, rgb: RGB16?), identity, clut(entries: [RGB16]) /*TurnGray, D1*/ }
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
`FerazelAudio` handles `MusicCue` with `.play` starting at volume 0, every track loaded under **one fixed mixer id**
(`ShellMixer.load(id:)` replaces the previous track — no HectorKit change), `.volume(v)` on the 0…256 scale. Dialogs in
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

### Wave 3.0 — foundations (nothing visible changes)

#### ~~K1~~ — dropped in the review fix round (R-a)
HectorKit already has what K1 would have built: `ClassicResourceMap.serialize(_:)` (HK
`Sources/HectorResources/ClassicResourceMap.swift:69`, round-trip tested by `ClassicResourceMapWriterTests`) writes the
saved-game and prefs files (SV2), and `ShellMixer.load(id:…)` replaces a sound under the same id
(`Sources/HectorShell/ShellMixer.swift:103`; a voice already playing the old buffer keeps it until stopped, so
`FerazelAudio` stops the music voice first — `SetAIFFMusic` stops first anyway), so A1a loads every music track under
one fixed id and no `unload` is needed. No HK task, no HK D-number, HK floor stays 328, no five-app rebuild.

#### X1 — minor — Phase 2 carry sweep (→ 256)
- **Files:** `Sources/FerazelCore/Random/FastRand.swift` (doc cite), `Sources/FerazelCore/Sprites/SetupFaces.swift` +
  `Sources/FerazelCore/Player/PlayerTiles.swift` (l. 73) + `Sources/FerazelRender/Frame/TileGridRenderer.swift` (l. 233)
  + `Sources/FerazelRender/Frame/LightRenderer.swift` (l. 404) (the `200..<210` literals → one named public
  `LiquidTiles.range` constant in `Physics/UnderWater.swift`, behaviour unchanged; test files keep their literals),
  `Ferazel/App/FerazelAudio.swift` (the redundant `stopEffects` in `stopAll`), `Ferazel/App/FerazelController.swift`
  (l. 115: the same stale `M l. 334` seed cite), `Tests/FerazelCoreTests/SoundCueTests.swift` (~l. 69),
  `Tests/FerazelCoreTests/PlayerMotionTests.swift` (l. 593, `testPlayerConstraintsMapClamps` — the `.PlayerConstraints`
  frame test), `docs/ferazel/INDEX.md` (provenance: the M-line drift note).
- **Contract:** no behaviour change. (1) `FastRand` doc (l. 10, l. 30) and the App's comment: the clock reseed cites
  `LMGetTime` M l. 31295–31298, not M l. 334. (2) `200..<210` literals named. (3) `stopAll` stops effects once.
  (4) Assert `soundStopAt` of the real jump
  frame in `SoundCueTests` (the value the code produces today, recorded; Invariant 10 if it surprises). (5) The
  `.PlayerConstraints` frame test distinguishes "row 38" from "after row 39" (a fixture where the two orders differ)
  and asserts the glider order. (6) INDEX provenance gains the note "bank M-line citations predate the 2026-10-08
  regeneration; Phase-3 plan M lines are current". Carried by name, not swept: M6 (Bonus guard `p1Negative: false`) and
  M7 (`TileHotRects.init(level:)`) → Phase 4 (Bonus class rework); `ParticleLife` vs CLUT 222 rows → the phase that
  first loads level 52 or 55; lost coins drawing when `.MTNewSprite` finds no record → Phase 4; the later-phase
  `3DSoundRand` idle-only sites (M l. 62997, 63199–63257, 61047–61057) → the Phase 4/5 plans (Invariant 4 conflict).
  `beginEnding`'s placeholder phase goes with the `Ending` struct in A1a.
- **Gate:** G2 = 256 (asserts only), G5 (touches the App), G6, G7(+b), G8, G10. **Commit:** `Phase 2 carry sweep: FastRand cite, liquid tile range constant, stopAll, jump-frame soundStopAt and PlayerConstraints order asserts`.
- ⚑ **As executed (X1, loop run 9, 2026-10-14; 6c32f4e + review fixes ebed14e):** G2 256 (asserts only; 260 on the
  branch with R1). Two contract items were wrong and were not done as written: (3) `stopAll` is **not** redundant —
  `ShellMixer.stopAll()` stops mixer voices only, the Sound Tool is a separate attached stream, so `stopEffects()` is the
  only effects stop and already runs once (left unchanged); (5) the glider-floor vs y-clamp order is unobservable (the
  clamp zeroes any vy < −0x100 and the glider floor −0x9c4 is below it), so the test pins row 38 → row 39 through the
  fields only row 39 writes (fe68/fe64, fd94/fd90; swapping the rows fails 4 asserts). M l. 334 is the `_FastRand(0)`
  call site (kept) — the clock reseed cite is `LMGetTime` M l. 31295–31298. Jump frame `soundStopAt == [1]`.
  `LiquidTiles.range` in `Physics/UnderWater.swift`. One Opus leg MERGEABLE (minors fixed).

#### R1 — minor — Dialog and menu resources (→ 260)
- **Files:** `Sources/FerazelCore/Front/DialogResources.swift`; `Tests/FerazelCoreTests/DialogResourceTests.swift`.
- **Contract:** Foundation-only parsers over `FerazelResources.resource(type:id:chain:)` (app fork): DLOG/ALRT
  (bounds, procID, visible, DITL id), DITL (count−1 prefix; per item: 4-byte placeholder, rect t,l,b,r, type byte with
  the 0x80 disabled bit, payload: Mac Roman text for button/check/radio/static/edit, resource id for control/icon/
  picture, padded to even), CNTL (rect, value, visible, max, min, procID, refCon, title; **the popup's MENU id is the
  `min` field** — verified on the shipped data: CNTLs 600–605 all have value 1, max 0, procID 1008, refCon 0, min 600,
  601, 602, 603, 604 and **601** (CNTL 605 → MENU 601, not 605); MENU 605 (with its extra "0") is referenced by no
  CNTL, and CNTLs 604/605 by no DITL), MENU (id,
  enable flags, title, items with icon/⌘ key/mark/style), MBAR (count + ids). No drawing.
- **Tests (4; data: digest A §3, §5, §6):** `testAbortWarningDialog` (DLOG 202 rect (114,144,256,439); DITL 202: 1
  button "OK" (113,226,133,284), 2 "Cancel" (113,161,133,219), 3 picture 145 (10,10,42,42), 4 static "^0"
  (10,53,97,264)) · `testPrefsPanels` (DLOG 6900 (56,20,330,471); DITL 6900 six items incl. control 3 → CNTL 600 →
  MENU 600 "Game Options"/"Controls"/"Sound & Music"; DITL 6903 items 3, 4, 9 (dialog items 9, 10, 15) → CNTL 601 →
  MENU 601 "9"…"1"; CNTL 605's min = 601; DITL 6902 edit items 7–15 at (67|93|119|145|171, 132) and (67|93|
  119|145, 342), 85 px wide; item 26 check "Use InputSprocket" (197,34,215,185)) · `testMenuBar` (MBAR 128 = [128,
  129, 130]; MENU 129 items New Game ⌘N, Restore Game... ⌘O, –, Abort Game ⌘W, –, Quit ⌘Q; MENU 130 Music ⌘M, Sound
  Effects ⌘F, –, Preferences… ⌘P; MENU 128 "About Ferazel's Wand…") · `testStandardFileDitls` (DITL 1003 item 13
  static "Your saved game will reflect your position as of the most recent checkpoint."; DITL 1500 item 10 "^0"
  (166,11,203,334)).
- **Gate:** G2 = 260, G6, G7(+b), G8, G10; wave 3.0 end: G3, G5.
- **Commit:** `FerazelCore: DLOG/ALRT/DITL/CNTL/MENU/MBAR parsers (dialog and menu resources); 4 tests`.
- ⚑ **As executed (R1, loop run 9; 5c91bd3 + ebed14e):** G2 260. The DITL 6902 item numbers above (7–15, 26) are
  **dialog** item numbers (DITL 6900's six come first); in DITL 6902 itself they are items 1–9 and 20. ALRT `stages` is
  2 bytes, then a position word (ALRT 500 0x300A, 501 0x280A). MENU 128's title is the single byte 0x14 (Apple menu,
  decoded U+0014 — A1b must recognise it). DITL 1003 item 12 → CNTL −6046, not in the app fork (O1/A1b cope). Every
  DLOG (20), ALRT (2), DITL (30), CNTL (7), MENU (9) and MBAR parses (reviewer scratch run). For O1/A1b, review minors
  left as they are: `isItemEnabled` ignores the menu-enable bit 0; ⌘ bytes 0x1B–0x1F (none in the data) decode as
  characters. One Opus leg MERGEABLE.

### Wave 3.1 — byte images, files, the front-end seam

#### SV1 — ⚑ MAJOR — G image and the save block (→ 266)
- **Files:** `Sources/FerazelCore/Session/GameGlobals.swift`, `Sources/FerazelCore/Saves/{SaveBlock,InventorySlot}.swift`,
  `Sources/FerazelCore/Flow/LevelFlow.swift` (`LevelCarry.globals` keeps working with the wider struct),
  `Sources/FerazelCore/World/LevelFile.swift` (only a 16-byte `Placement` image codec if none exists — the record
  layout the file already parses); `Tests/FerazelCoreTests/SaveBlockTests.swift`; bank: `save-continue.md` + `engine.md`
  (corrections BC2, BC7, BC21).
- **Contract:** digest D §1–§2, save-continue §3.3, engine §9. `GameGlobals` covers all 0x19978 bytes by named field
  (S2); `image()` writes big-endian at the binary's offsets, gaps/never-accessed ranges 0 (Invariant 7);
  `init(image:)` reads every field back (the gaps are not stored). `initGameGlobals(previous:)` = M l. 582–812: health,
  breath, max health, max magic, magic **0x230**; `+0x12` 3; `unlocked[1]` (+0x240) **1**, others 0; inventory slot 0
  {id 0, count 1, +4 −1, +6 0, spell flag 1}, slot 1 {0, 1, −1, 0, 0}, slots 2…26 {−1, 0, −1, 0, 0}; crunch levels
  `+0x12d8` 0xff × 20000, count 0; `+0x16`, `+0x20`, `+0x22`, crunch pairs **not** written by InitGameGlobals (they keep
  the previous value — `previous` passes the old struct through; nil (the very first game) → 0). **The routine's
  tail (M l. 815–825) also zeroes non-G state** — 8 stores, in this order: `*ffac`, `*ffb0`, `*ffb4` (the secrets /
  Xichrons / enemies tallies), **`G+0` (score, u32) = 0** (M l. 818, raw `10001a3c stw r24,0x0(r4)` — a G field, so
  `initGameGlobals` writes it), `*ffa8` (died), `*ffa4`, `*ffa0`, `*ff9c`, then **`save+6 = 0`** when the save block exists
  (`*_DAT_100a0054 ≠ nil`, always true after `.InitAppGlobals`' `NewHandleClear(0xebe58)`, M l. 345). SV1 documents the
  list in `initGameGlobals(previous:)`'s doc comment and exposes `SaveBlock.isCheckpoint` writable; F1b's
  `GameFlow.initGameGlobals()` performs the tail on the flow's fields and the block. `SaveBlock`: offsets
  0x00 stamp u32, 0x04 preview u8, 0x05 demo u8, 0x06 checkpoint u8, 0x08 level i16, 0x0c x i32, 0x10 y i32, 0x18 G,
  0x19990 date u32 (seconds since 1904), 0x19998 + 0x2000·L + 16·i snapshots (L < 100, i < 511; the 512th slot and
  0xe1998..0xe7d97 never accessed), 0xe7d98 world name pstr (written only by `.DoSaveGame`, whose sole caller is the
  dead DLOG 202 item-5 branch of `.ConfirmAbortGameDialog` — DITL 202 has 4 items, raw `100068b4`, BC26 — so always 0
  in 1.0.3; the field is kept and read, never written), rest zero. `savePointSave(level:x:y:stamp:date:records:)`
  = raw order `1000c104…`: stamp (`Mwld+0x100`, `WorldFile.stamp`), date, `+6 = 1`, `+8 = level`,
  `globals.hasSnapshot[L] = 1` **before** the G copy, G copy, x/y (sign-extended i16), `+4 = +5 = 0`, then the 511
  live records with record `+0xe` (x) and `+0xc` (y) each **−6** (raw `1000c2a4..1000c2d8`).
  `endLevelSGUpdate(level:x:y:stamp:date:records:)` = the same without `+4/+5` (M l. 6501ff).
  `restoreSnapshot(level:) -> [Placement]` = the 511 stored records with +6 on both (M l. 2405–2409, 6744–6747).
  **Records are values, not the file:** `LevelFile.placements` is an immutable `let` (the file); the game's live copy is
  `SpriteWorld.records` (`SpriteWorld.swift:28–31`), and the Setups read `c.level.placements` / `spawnOrder`
  (`SetupFaces.swift:552–553`). So the writers **take** `[Placement]` (the session's `world.records` at that moment) and
  the reader **returns** `[Placement]`; L1 adds the seam that starts a session from them (no second copy, no
  mutable `LevelFile`).
- **Tests (6):** `testInitGameGlobalsImage` (size 104,824; bytes 4–5 = 0x0230; `+0x12` = 3; `+0x240` = 1; `+0x24`
  slot 0 = 00 00 00 01 FF FF 00 00 01 00; `+0x12d8` = 0xff ×20000) · `testGameGlobalsRoundTrip` (a G with every named
  field non-default → image → init(image:) → equal) · `testCrunchLogImage` (three entries → `+0xad6` = 3, levels at
  `+0x12d8…`, row at `+0x60f8`, col at `+0x60fa`) · `testSaveBlockLayout` (size 966,232; the field offsets above
  read back from a hand-built image) · `testSavePointSaveWritesSnapshotMinus6` (level 1 header: record 24 (the save
  point, x 2377 y 878) stored at 0x19998 + 0x2000 + 16·24 with y 872, x 2371; `+6` = 1; `hasSnapshot[1]` = 1 inside the
  G copy) · `testRestoreSnapshotPlus6` (save then restore returns records equal to the ones written; the
  `initGameGlobals(previous:)` tail list is not testable on G alone and is pinned by F1b's `testNewGameStartsLevel1`).
- **Gate:** G2 = 266, G6, G7(+b), G8, G10.
- **Commit:** `FerazelCore: G as a byte image (every field), the 966,232-byte save block (SavePointSave/EndLevelSGUpdate writers, snapshots ±6); 6 tests`.
- ⚑ **As executed (SV1, loop run 9; ebbd7aa + review fixes d8f2ebe):** G2 266. Dump beat plan: BC7's "+0x55e/+0x626/
  +0x946/+0xa0e never accessed" is wrong — `.InitGameGlobals` zeroes all five 200-byte rows (M l. 725–761), play uses
  rows 0–2 (bank note says so); `+0x174` is a u8 (M l. 797); the writers take `globals: inout` (live G, raw `1000c1c0`);
  inventory slot byte +9 is copied as half of a halfword when slots move (always 0 in practice). Crunch log stored as
  the binary's three 20000-entry arrays + count (`crunchLog` computed over the first count; `appendCrunch` O(1)), so the
  round trip is byte-exact incl. pairs `initGameGlobals(previous:)` carries over. All 511 records are written −6 with no
  flag check. Leg 1 (fidelity: 64 G-pointer loads scanned, every offset/width covered) MERGEABLE; leg 2 (quality, 20
  mutations) MERGEABLE with 4 surviving offset mutations → fix round pinned every scalar offset by raw bytes → Opus
  re-review MERGEABLE (all caught). Carried to F1b: `.NewGame` also writes save +0xc/+0x10 from header 0x2848/0x2846 − 0x20
  (raw `1000b498`/`1000b4b4`) — `SaveBlock` has no method for it yet; untested `appendCrunch` 20000 cap; `.RemoveItem`
  leaves the last slot's +8..+9 (raw `100456a0..100456ac`).

#### SV2 — minor — Prefs record, prefs file, saved-game file (→ 272)
- **Precondition:** SV1 merged (`SaveBlock`). No HectorKit precondition: the writer is HK's existing
  `ClassicResourceMap.serialize(_:)` (HK 0c65dcb, untouched).
- **Files:** `Sources/FerazelCore/Input/FerazelPrefs.swift`, `Sources/FerazelCore/Saves/{PrefsFile,SavedGameFile,SaveName}.swift`;
  `Tests/FerazelCoreTests/SavedFileTests.swift`; bank `engine.md` §8 (BC17, BC27's `.InitPrefs` part).
- **Contract:** digest A §4, digest D §4. `FerazelPrefs.record()` = 0x942 bytes, every field at its offset
  (engine §8 as corrected: +0x0e sound-effects volume, +0x36 "set system volume on startup", +0x42 pstr "@@@@@",
  +0x142 eight empty pstr[256]). **Never written by `.InitPrefs`** (M l. 7714–7756) → written as 0 by the replica
  (Invariant 7; NewHandle junk in the original [MED]): +0x0d (byte), +0x24/+0x26/+0x28, +0x2c/+0x2e, +0x48…+0x141 (the
  rest of the 256-byte pstr after "@@@@@"), and bytes 1…255 of each of the eight pstr[256] at +0x142 (`CopyPString`
  writes only the empty length byte). `init(record:)` preserves unknown bytes and grows a short record to 0x942
  (`SetHandleSize`, no version check, M l. 7694–7768; the grown tail is junk in the original — **0 is the replica's
  choice**, Invariant 7). `PrefsFile`: a classic resource file holding `'Pref'` id 0 named
  "Preferences" (M l. 7694ff), read/written at a URL the App passes. `SavedGameFile`: `write(_ block: SaveBlock, to:)`
  = one `'FWSg'` id 0 named "Ferazel Saved Game" (pstr 0x100a586c) holding the 966,232-byte block, encoded with
  `ClassicResourceMap.serialize(_:)` **into the data fork** (D35 ruling); HFS type `'FWSg'` / creator `'Msct'` set through
  `FileAttributeKey.hfsTypeCode/.hfsCreatorCode`; `read(from:)` accepts the data fork **or** the file's resource fork
  (`<path>/..namedfork/rsrc`), so a save from a real Mac resumes. **The two Darwin-only parts (the `..namedfork/rsrc`
  read and the HFS type/creator attributes) sit under `#if os(macOS)`** (Core stays portable for the Phase-7 Windows
  shell; elsewhere the data fork is the only fork and type/creator are skipped); `testSavedGameFromResourceFork` and the
  type/creator asserts are `#if os(macOS)` too. Missing `'FWSg'` 0 → `.notASavedGame` (string "Sorry, this does not
  appear to be a saved game file.", 0x100a5a3d); `.OpenSG` uses `GetResource` (the whole resource chain, not
  `Get1Resource`) — the replica looks only in the opened file [deviation-free: nothing else in the chain holds
  'FWSg']; a failing close → `.openFailed` ("Error opening the saved game.", 0x100a5a1f, the fifth string); no size
  check (`.OpenSG`, M l. 41315ff).
  `SaveName.increment(_:)` = `.IncrementLastSGString` (M l. 41115): chars 1…4 "@@@@" → "Ferazel Saved Game"; else
  only when length < 31: trailing digits → value + 1; trailing space → append "2"; else append " 2". Error mapping
  for the App: −34 / −33 / −44 / other → the four strings (0x100a58d1, 0x100a5908, 0x100a5944, 0x100a597f — only the
  last passes the error code, `.SaveSG`).
- **Tests (6):** `testPrefsDefaultsRecord` (0x942 bytes; keys at +0x12 = 00 56 00 58 00 5B 00 57 00 38 00 3A 00 37 00
  59 00 5C; +0x0e = 7; +0x10 = 9; +0x3a = 0xffff; +0x42 = 05 40 40 40 40 40) · `testPrefsShortRecordGrows` (a 0x40-byte
  record → 0x942, first 0x40 kept) · `testPrefsFileRoundTrip` (temp dir) · `testSavedGameFileRoundTrip` (temp dir;
  type/creator read back as 'FWSg'/'Msct'; bytes equal) · `testSavedGameFromResourceFork` (a file whose resource fork
  holds the map and whose data fork is empty reads the same block) · `testSaveNameSequence` ("@@@@@" → "Ferazel Saved
  Game" → "Ferazel Saved Game 2" → "… 3"; "Game " → "Game 2"; a 31-char name unchanged).
- **Gate:** G2 = 272, G6, G7(+b), G8, G10.
- **Commit:** `FerazelCore: prefs record (0x942) + prefs file, saved-game file (FWSg 0, data fork or resource fork), IncrementLastSGString; 6 tests`.
- ⚑ **As executed (SV2, loop run 10, 2026-10-14; d88a7f1 + review fixes 6d919da):** G2 272. Dump beat plan: a record
  longer than 0x942 keeps its tail (`.InitPrefs` only grows, M l. 7760–7766); `SaveName` tests chars 1…4 "@@@@" past
  the length byte (M l. 41135); a short saved-game body is zero-padded (no size check in `.OpenSG`); `.openFailed` is
  unreachable in the replica (no `CloseResFile` failure) — case and string kept. `FerazelPrefs ==` compares the whole
  record (stale bytes after a pstr included, as `CopyPString` leaves them). Fix round: an existing but unreadable prefs
  file → nil (defaults), as the original's failed `Get1Resource`; citations (AddResource M l. 7758, FSpCreate ≈ 41253,
  D35 ruling numbers per DECISIONS). One Opus leg MERGEABLE (probe: type/creator FWSg/Msct, resource-fork fallback,
  HK serialize round-trips name + id). Carried: OSErr mapping from Foundation errors → F1a/A1; prefs file has no
  type/creator (not asked); the old save is deleted before the write, as `FSpDelete` (not atomic).

#### FE0 — ⚑ MAJOR — Front-end seam, `ScreenSurface`/`ScreenRenderer`, timed fades, music fades (→ 278)
- **Files:** `Sources/FerazelCore/Seams/{DrawOp,ShellRequest,Rect16,TextRun,FerazelDialog,FrontFaceSet,ScreenGammaOp,MenuState}.swift`,
  `Sources/FerazelCore/Front/{ScreenFade,MusicFade,FrontIO}.swift` (`FrontInput`, `FrontOutput`),
  `Sources/FerazelRender/Screens/{ScreenSurface,ScreenRenderer}.swift`, `Sources/FerazelRender/Effects/ScreenGamma.swift`,
  `Sources/FerazelRender/Frame/FrameRenderer.swift` (the `surface:` parameter, defaulted, + no-op arms for the new
  cases in its exhaustive `switch op`, l. 280ff), `Tests/FerazelCoreTests/SessionTests.swift` (only the exhaustive
  `switch op` at l. 288 gains arms; no expectation changes), `Ferazel/App/FerazelController.swift` (no-op arms for the
  new `ShellRequest` cases); `Tests/FerazelRenderTests/ScreenTests.swift`; bank `rendering-omnipx-titles.md` §4.3 +
  `lighting-tables.md` §10 (BC16, BC28).
- **Contract:** **every** S3 case is added here, up front (`fillRect`, `copyPicture`, `drawFace`, `drawLine`,
  `drawText`, `restoreView`, `screenGamma`; `FrontFaceSet`, `ScreenGammaOp`, `MenuState`, the `ShellRequest` and
  `FerazelDialog` cases; `FrameOps.suspension` stays S1's), so no later task edits an exhaustive switch outside its
  Files; cases a later task owns (`drawFace`/`drawLine` M2, `restoreView` C2) are accepted by `ScreenRenderer` as
  documented no-ops with `// later: <task>`. S4 types. `ScreenRenderer.apply(_ ops:)` executes `setScreenClut`, `drawPicture`
  (full-screen or at (h, v)), `copyPicture` (source → dest rect with nearest-row/column stretch [MED], `forceClut` =
  `CopyBitsCTForce` (the source converted under that clut, then copied by colour into the screen clut), `transparent`
  = mode 0x24 (white source pixels skipped)), `fillRect`, `drawLine` (1-px QuickDraw line, pen 1×1), `drawText`
  (through the injected `TextRasterizer`, srcOr), `screenGamma`. `ScreenFade` (Core) timelines:
  `.GammaFadeOut(n)` = `MT_FadeCustom` over **`ms = trunc(0.7 · Double(55 · m))` with `m = trunc(2.3 · n)`** — the
  binary's order (`fctiwz(2.3·n)`, then the integer `m·0x37`, then × 0.7; constants 2.3 @0x100a1940, 0.7 @0x100a1938;
  raw `10035310..10035420`, code `10035338..100353bc`). Written left to right as `0.7·55·m` the double rounding gives
  n 3 → **231**; the binary order gives **230** (n 3 → 230, 6 → 500, 10 → 885, 12 → 1039, 30 → 2656 ms) — the test
  pins n 3. Through `.TintFadeProc` mode 3 (raw `10035200..10035264`: t = param · 0.01 **rounded to single precision**
  (`frsp`); [3] = B·(1−t), [2] = G·max(1−1.35t, 0) (1.35 @0x100a1960), [1] = R·max(1−2.5t, 0) (2.5 @0x100a1958); the
  proc writes the scaled values back into the list in place — whether that compounds tick to tick depends on the
  library `MT_FadeCustom` [MED]: the replica scales the **unfaded** table each tick), one `screenGamma` op per tick,
  ticks by Invariant 3 (500 → 30, 885 → 54, 2656 → 160); sets faded **and `53d6 = 1`** (M l. 31799); no-op when
  fading is disabled or already faded. `.GammaFadeIn(n)` (M l. 31819–31840, raw `10035444..10035560`): s = max(1,
  100/(3n)); for p = 0, s, 2s … ≤ 100 one `FadeToColor(nil, trunc(min(100, p·3n/100)))` per tick (compounding, as
  `ScreenGamma.fade` already models), then 100; clears faded; ends with `ShowCursorSafe` (a `showCursor` request);
  **n 6 → 21 steps passing 0, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 9, 10 … 18, then 100**. `.GammaFadeInSlow(n)` (M l.
  31859–31862): ms = 33n, replaced by 100 when below 0x65 (n 0x37 → 1815 ms → 109 ticks), linear [MED: library
  `MT_FadeToColor`]. Gates: `DAT_100a53c2` fading enabled (initial 1), `*_DAT_1009fde8` faded, `DAT_100a53d6` no async
  fade running (initial 1). `MusicFade` (Core) keeps `currentTrack` (`5be0`) and `musicFaded` (`*0448`):
  `SetAIFFMusic(n)` (M l. 41852ff) — n −1 → **nothing at all** (the current music is not stopped); else `.stop`, then
  (file opened) `SetMovieVolume(0)` **before** the start, `*0448 = 1`, `5be0 = n`, load, preroll, start → emitted as
  `.stop`, `.play(track: n)` (`.play` starts at volume 0 — no separate `.volume(0)` cue); n < 1 or > 32 → 1; a missing
  file → n − 1 recursively stays the App's resolver (`FerazelAudio.resolveTrack`); everything is gated on QuickTime
  present (`DAT_100a5104`, always true in the replica). `FadeAIFFMusic(dir, t)` (M l. 41993–42050) blocking: gates
  `5104`, music on (prefs+0x0c) and loaded; out only when `*0448 == 0`, in only when ≠ 0 (fade-in clears `*0448` at its
  start); 24 steps s = 0…23 of t ticks with `.volume(V·(24−s)/24)` / `.volume(V·s/24)`, then 0 / V (V = prefs+0x10·256/9,
  signed divide); the original's redundant first `SetMovieVolume` (V for out, 0 for in) coincides with s = 0 and is
  not emitted twice; the current-volume global `*1009fd6c` is updated only at the end. `FadeAIFFMusicAsync(dir, N)`
  (M l. 42061–42140) per frame (V·(N−i)/N, V·i/N; done when i > N): `*0448` only decides whether the flag gets set — the
  per-frame handler runs regardless (`5be2 = 0` always), and the async fade-in clears `*0448` only at its end.
  `FrontOutput.present` is true on every tick that changed the surface or the gamma.
- **Tests (6; digest A §1, C §1, lighting-tables §10):** `testMainMenuScreenGolden` (Render: `setScreenClut(130)` +
  PICT 130 at (0,0) on a fresh surface: FNV-1a of the indices + the CLUT, self-derived, recorded) ·
  `testStretchedPanelRows` (the whole PICT 140, 320×110, stretched into (t 150+s, l 160, b 260−s, r 480) for s = 52,
  26, 0: row counts 6, 58, 110;
  the source row each dest row samples, recorded) · `testTransparentCopySkipsWhite` (a 2×2 source with one white
  pixel leaves that screen pixel unchanged) · `testGammaFadeOutTimeline` (n 6 → 30 ticks, red channel first: at t =
  0.4 R factor 0, G 0.46, B 0.6 — `.TintFadeProc` mode 3; n 3 → 230 ms → 14 ticks, the binary order) ·
  `testGammaFadeInSteps` (n 6 → 21 one-tick steps passing trunc(p·18/100) for p = 0, 5 … 100 = **0, 0, 1, 2, 3, 4, 5,
  6, 7, 8, 9, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18**, then 100; n 15 → s 2, 51 steps) · `testMusicFadeVolumes` (V 256: in
  t 4 → 24 cues 0, 10, 21 … 245 at ticks 0, 4 … 92, then 256; out t 2 → 256·(24−s)/24 …, then 0; no cue when
  already faded/unfaded; `SetAIFFMusic(−1)` → no cue at all, not even `.stop`).
- **Gate:** G2 = 278, G5 (touches the App), G6, G7(+b), G8, G10.
- **Commit:** `Front-end seam: ScreenSurface + ScreenRenderer (picture/stretch/transparent/fill/line/text ops), timed gamma fades (TintFadeProc), music fades; 6 tests`.
- ⚑ **As executed (FE0 ⚑, loop run 10; 9bd5d1e + review fixes 6d919da):** G2 278. **Plan wrong against the dump:** the
  async music fade-in clears `*0448` at its **start** too (`li r6,0` 10049bec, `stb r6` raw 10049c5c), not only at its
  end (contract above) — built as the binary. Added outside S3's list: `PutFileRequest {prompt, defaultName, message}`
  in `ShellRequest.swift` (the plan named the type, never defined it — F1b/A1 consume these fields) and, in the fix
  round, `ScreenGammaOp.timedFadeToColor(tick:milliseconds:rgb:)` (the slow fade-in was compounding floored percents —
  0 % for 9 ticks, then 25 → 34 → 52 → 100; now tick 0 records the start gamma and each tick is an absolute linear
  fraction, n 0x37 → 109 ticks [MED, library `MT_FadeToColor`]). `drawLine` implemented (Bresenham [MED vs QuickDraw's
  tie rule]; M2 may revisit); `drawFace`/`restoreView`/`ScreenGammaOp.clut` (TurnGray) are `// later` no-ops (M2/C2/D1).
  `drawText` is srcOr only (the game never calls `TextMode`). `forceClut` loads on the picture's chain; `ScreenRenderer.chain`
  (default `.frontEnd`) for `setScreenClut` — untested, set to `.level` by whoever draws the pause screen (P1/A1a).
  Fix round also: `.stop` only when music is loaded (`ShutDownAIFFMusic` M l. 41877ff/41943), `present` asserted on gamma
  ticks. Main-menu golden `ed142fed9e3bdce7` is self-derived under `.ruled` (pins the code, eyeballed right — PICT 130
  under clut 130; stretched PICT 140 "Stage Complete" checked as an image). Two Opus legs MERGEABLE (A: every timeline
  re-derived from the dump; B: renderer/seam, images), fix round re-reviewed MERGEABLE. Carried to A1a: with a shared
  surface `FrameRenderer` no longer sets the level CLUT at init — `deathEffect` before the level's `setScreenClut`
  would use the previous screen's CLUT; replica-only: a gamma op landing mid-timed-fade re-bases the fade.

#### O1 — minor — Options dialog model, `.MakeCurrPrefs`, the Music / Sound Effects toggles (→ 284)
- **Files:** `Sources/FerazelCore/Front/{PrefsDialogModel,PrefsToggles}.swift`; `Tests/FerazelCoreTests/PrefsDialogTests.swift`;
  bank `save-continue.md` §8.2 (BC18, BC27).
- **Contract:** digest A §3 (M l. 7254, 63949–64030, 64233–64700). Panels n = 1 Game Options (DITL 6901), 2 Controls
  (6902), 3 Sound & Music (6903); switching = `ShortenDITL`/`AppendDITL`, panel items from 7. Item ↔ field: 6901
  7 → +0x00, 8 → +0x01, 9 → +0x08, 10 popup → +0x02 (1 High / 2 Low / 3 Line-skipped), 11 popup → +0x06 (1 Enhanced /
  2 Normal / 3 Reduced), 14 → +0x32 (the click updates **item 16**, which does not exist — the box does not visibly
  change until a redraw; raw `100767fc`); 6902 edit items 7…15 ↔ keys +0x12 + 2(i−7), item 26 → +0x0a (updates item
  30, raw `10076944`; disabled and forced 0 — no InputSprocket), item 27 "Configure…" disabled; 6903 7 → +0x0b, 8 →
  +0x0c, popups 9/10/15 (all CNTL 601 → MENU 601 "9"…"1", R1) → +0x0e/+0x10/+0x38 with control value v ↔ pref
  **10 − v**, 16 → +0x36; a dead branch maps item 12 → +0x04 (no such item on any panel — not built, noted). Key capture
  (`.PrefDialogFilter`): the focused edit item takes the key code (message >> 8 & 0xff) unless `.AlreadyUsingKey`
  (M l. 63963; scans **10** slots +0x12…+0x24, and the result is the **last matching slot's verdict**, not an OR of
  all matches — slot 9 is +0x24, never written by `.InitPrefs` and 0 in the replica, so key code 0x00 'A' reads as used:
  **ruled D35 — the refusal follows the zeroed record**; Up (2) and Jump (5) may share) → report "That key is already
  being used for another action. Please try another one." (0x100a694e); modifiers from the event's modifier bits
  0x100/0x200/0x800/0x1000 → 0x37/0x38/0x3a/0x3b — a modifier already in use is **ignored silently** (no report);
  focus moves to the next item (15 → 7); on panel 2
  Return/Enter/Esc/⌘. are captured as keys, elsewhere they are OK/Cancel. `.ConvertKeyName` fixed table (digest A §3)
  else an injected `keyCharacter(code) -> String?` (the App's keyboard layout), uppercased. Buttons: OK → working copy
  into the record; Cancel → only the system volume restored (live music/sound changes stay); **Default Settings** per
  panel — Controls and Sound reset the working copy; **Game Options writes the defaults into the record, not the
  working copy** (raw `10076520..10076528`; writes `100764f4..1007654c`; the +6 default is 2 if `_DAT_100a511a` <
  0x108 else 1, as `.InitPrefs`), so nothing visibly changes, OK then overwrites them and Cancel keeps them;
  `.Options` (M l. 7254–7289): `FlushEvents`, `InputActivate(0,0)`, cursor shown, the prefs file opened
  (`.SetPrefFile`, M l. 7269) and **re-read** (`.InitPrefs`, M l. 7273), `.PreferencesDialog` (M l. 7275), then the
  'Pref' record is written back on **every** close, OK or Cancel (`ChangedResource` + `WriteResource`, M l.
  7276–7277), `MTRedraw`, `.MakeCurrPrefs`, `.UpdateMenus`, the file closed (M l. 7284), `fe0c = 1`, `511e = 1`.
  Live effects inside the dialog: the Music checkbox writes the **live** prefs `_DAT_1009fe44`+0x0c directly; off →
  `ShutDownAIFFMusic` (`.stop`); on → `SetMusicAIFFVolume(V)` only, which does nothing because the shutdown cleared the
  loaded flag (`1992`; M l. 64546–64565, 41958) — **the dialog never restarts the music**; the Sound Effects volume
  popup sets live +0x0b = 1; volume popups apply at once (sound pref·28, music pref·256/9; the system volume pref·28
  via `STSetVolume` is stored but not applied — Known deviation 8); Cancel restores only the system volume
  (`STSetVolume(local_6c)`, likewise a no-op here).
  **`PrefsToggles` (`Front/PrefsToggles.swift`):** `.MakeCurrPrefs` (M l. 7216–7251): the record → the live prefs
  (0x942 bytes), `5107 = (+9 == 0)`; when **not paused** (`*_DAT_100a0050 == 0` — the pause flag `.Pause` sets, M l.
  3198; true in the main menu and for ⌘P Options inside a level) and +0x0c differs from the
  last applied music flag `fd20`: `.volume(0)`, then `SetAIFFMusic(5be0)` if on, then `.volume(V)` (on) or `.volume(0)`;
  sound volume `510c = +0x0e·28`; `fd20 = +0x0c`; emits `FrontOutput.prefs`. **Game ▸ Music ⌘M = `.ToggleMusic`**
  (M l. 7105–7183): re-read the prefs file (`.InitPrefs`), flip +0x0c — on: requires QuickTime (always present in the
  replica; the "QuickTime not installed" report 0x100a2fe1 is not reachable), off: `ShutDownAIFFMusic` (`.stop`) — then
  write the prefs file, `.MakeCurrPrefs`, `.UpdateMenus` (the check mark). So in the main menu ⌘M off stops the music
  and ⌘M on restarts track `5be0` at V; inside the pause loop (paused) on stays silent until the pause exit
  re-applies it (P1). **Game ▸ Sound Effects ⌘F = `.ToggleSound`** (M l. 7185–7214): re-read, flip +0x0b, write,
  `.MakeCurrPrefs`, `.UpdateMenus`. Both are reachable only where menus are live (A1b: main menu and pause loops).
- **Tests (6):** `testPanelItemMapping` · `testKeyCaptureRules` (dup rejected with the message; Up+Jump share; ⌘ → 0x37;
  focus 15 → 7; 'A' (0x00) rejected [LOW, recorded]) · `testConvertKeyNameTable` (0x24 Return, 0x31 Space Bar, 0x37
  Command, 0x56 Keypad 4, 0x5b Keypad 8, 0x7e Up Arrow, 0x52 → the injected layout char) · `testVolumeControlMapping`
  (v 3 → pref 7; pref 9 → v 1; the Music checkbox on → no `.play`) · `testGameOptionsDefaultSettingsBug` (defaults
  land in the record; OK overwrites them with the working copy; Cancel keeps them) · `testToggleMusicAndSound` (no game
  running, music on, track 24: ⌘M → `.stop`, +0x0c 0, prefs written; ⌘M again → `.volume(0)`, `.play(track: 24)`,
  `.volume(256)` with prefs+0x10 = 9; paused: ⌘M on → no music cue; ⌘F flips +0x0b and writes; both emit
  `FrontOutput.prefs`).
- **Gate:** G2 = 284, G6, G7(+b), G8, G10; wave 3.1 end: G3, G5.
- **Commit:** `FerazelCore: Options dialog model (three panels, key capture, AlreadyUsingKey, ConvertKeyName, Default Settings as written), MakeCurrPrefs, Music/Sound Effects toggles; 6 tests`.
- ⚑ **As executed (O1, loop run 10; 0810ff3 + 6d919da):** G2 284. Dump beat plan: ⌘M back on (no game) emits
  `.play(track: 24)`, `.volume(256)` — not `.volume(0)` first — because `SetMusicAIFFVolume` and `ShutDownAIFFMusic` act
  only on a loaded movie (M l. 41943, 41959–41971; the stop happened at ⌘M off). Plan errors: the Music checkbox is at
  M l. 64494–64524 (not 64546–64565); item 12 does exist — the disabled "Graphics:" label on 6901 (the dead branch's
  target). `.ConvertKeyName` matches all 45 table cases. Items 14 → 16 / 26 → 30 built as "no visible change" [LOW:
  `GetDialogItem` on a missing item may leave the clicked item's handle, making the slip invisible]. The dialog works on
  its own copy of the live prefs + music player (GameFlow takes `live` back at close); `lastModifier` is carried by the
  caller. Not built (unreachable): the no-QuickTime branches (M l. 64650). Carried to A1b: the `.Options` sequence itself
  (prefs re-read, write back on every close, `MTRedraw`, `fe0c`/`511e`) has no Core function yet; `uppercased()` ≠
  `UpperString` for non-ASCII; a key with no character gives "". One Opus leg MERGEABLE.

### Wave 3.2 — between two levels

#### L2 — minor — Chapter card, stage-load popup, stage-complete panel (→ 289)
- **Files:** `Sources/FerazelCore/Front/StageScreens.swift`, `Sources/FerazelRender/Screens/ScreenRenderer.swift`
  (nothing new beyond FE0's ops unless a test needs it); `Tests/FerazelCoreTests/StageScreenTests.swift`; bank
  `world-data-format.md` §4.3 (BC9).
- **Contract:** digest C §1, §3. **Rect conventions are mixed in the dump — every rect below is labelled.** The popup
  and stage-complete rects are QuickDraw **(top, left, bottom, right)** — `CONCAT22(hi+s, lo)` adds s to `top`, and the
  offset is (h 160, v 173 / 150) — so (203,160,207,480) is a 320-wide, 4-high strip at v 203, **not** a 4-px-wide
  column; `SetRect` arguments (the load bar, D1's hit rects, F1a's hot rects) are **(left, top, right, bottom)**.
  `Rect16` stores {top, left, bottom, right}; the tests construct it by field name. `.PopupStageLoad` (M l.
  2946–2990): the **whole** PICT 142 (320×64, port built on clut 199, source `&local_2a`) copied with plain CopyBits
  (remapped by colour, **stretched** into the shrinking rect, not cropped) to (t 173+s, l 160, b 237−s, r 480), s = 30,
  28 … 0, one tick each (16 ticks), no DeadTime. `.UpdateStageLoad(p,q)` (M l. 2993–3029): w =
  (int)((float)p/(float)q·293.0f) (293.0f @`100a156c`) clamped 0…293, `SetRect(172, 213, 172+w, 224)` (l,t,r,b) +
  `PaintRect` in RGB 0x59d8 ×3; no wait. (The sequence of bars a level entry draws is L1's.) `.ChapterScreen(n)` (M l. 5038–5089): clut 280+n (nil → skip
  all), PICT 4600+10n at (0,0,640,480), `GammaFadeInSlow(0x37)` (109 ticks), up to **1200** one-tick iterations
  ending early on any key or the mouse button (the current tick finishes; a key held on entry skips at once),
  `GammaFadeOut(0x1e)` (2656 ms → 160 ticks), the level clut back, PICT 129, `UpdateStatusBar(0,0,0)`.
  `.StageCompleteEffect` (M l. 2870–2943): snd **805** (prio 1, vol 0x100); 27 frames s = 52, 50 … 0 of PICT 140
  (the whole picture, `CopyBitsCTForce`, port on clut 200, M l. 483) stretched into (t 150+s, l 160, b 260−s, r 480),
  one tick each; wait 15 ticks; three `.FillPercent` bars at screen (h 413, v 200 / 218 / 236) for enemies `(achieved[0], totals[0])`, Xichrons `[1]`, secrets `[2]`; wait
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
  on tick 300 → fade-out 160 ticks, clut back, PICT 129; untouched → 1200 ticks) · `testPopupAndLoadBar` (16 rects,
  built by field name, (top 203, left 160, bottom 207, right 480) … (top 173, left 160, bottom 237, right 480), each
  with the whole 320×64 source; the bar formula alone: (25, 50, 100)/100 → widths 73, 146, 293 — not an entry sequence,
  which L1 pins).
- **Gate:** G2 = 289, G6, G7(+b), G8, G10.
- **Commit:** `FerazelCore: chapter card, stage-load popup and bar, stage-complete panel with CalcPercent/FillPercent; 5 tests`.
- ⚑ **As executed (L2, loop run 11; d144872 + a5c1beb):** G2 289. API: `StageScreens.popupStageLoad()`,
  `fillPercent(…)`, `stageCompleteEffect(globals:level:sounds:)` → `FrontTimeline` (played by `TimelineRun`);
  `updateStageLoad(_:of:)` → `FrontOutput`; `calcPercent`, `stageLoadWidth`; `ChapterScreenRun(…)` (nil when clut 280+n
  is missing) ticked until `isDone`; `StageSounds(prefs:lengths:)` takes per-snd play lengths in ticks (the App fills them
  from `SoundBank` sample counts). Dump beat/added to the plan: the band snd + wait are chosen on n2 (M l. 2810–2830);
  with sound off `STPlayRegSound` returns −1 (M l. 40619) so every wait-on-sound is 0 ticks; the chapter card is
  DrawPicture'd into (0,0,640,480), so the four 608-wide cards stretch; the popup's plain CopyBits from a clut-199 port is
  emitted as `forceClut: 199` (same colours). Review fix (a5c1beb): "any key" is `.IsAnyKeyDown` (M l. 31579–31595, via
  `.IsAnyInputKeyDown` M l. 42364) — keycodes 1–127 only (A = 0 alone does not skip) and a locked Caps Lock counts
  (`FrontInput.capsLock`; the shell must fill it — carry to A1a); FillPercent's pct-45 case pinned. [LOW] the fade-out
  colour global assumed black (same global as every GammaFadeOut). One Opus leg MERGEABLE (+ fix round).

#### L1 — ⚑ MAJOR — `LevelRun`: level entry, cadence, exit; `.SetupLevel`'s restore branch (→ 297)
- **Precondition:** L2 merged (FABLE-GRADE fix: L1's entry and exit sequences and its tests drive L2's
  `StageScreens` — `.PopupStageLoad`, `.UpdateStageLoad`, `.ChapterScreen`, `.StageCompleteEffect` — no stub), SV1, FE0.
- **Files:** `Sources/FerazelCore/Front/{LevelRun,LevelServices}.swift`, `Sources/FerazelCore/Session/FerazelSession.swift`
  (the new init parameters below, `startOps()`, the `LevelEnd` source; the Phase-2 `ended`/`deathEffectDone` path kept
  for directly built sessions), `Sources/FerazelCore/Session/SpriteWorld.swift` (the async fade honours `ScreenFade`'s
  gates; `records` seeded from the override), `Sources/FerazelCore/Sprites/SetupFaces.swift` (the records override seam:
  `Context` gains the live records, which `spawnLevelSprites` reads instead of `c.level.placements` at l. 552–553;
  `spawnOrder` unchanged), `Sources/FerazelCore/Flow/LevelFlow.swift` (`LevelCarry` gains the G image path; Phase-2
  helpers untouched); `Tests/FerazelCoreTests/LevelRunTests.swift`; bank `save-continue.md` §6 (BC8), `engine.md` §4/§6
  (BC11, BC12, BC13, BC29).
- **Session seams (Invariant 9: parameters added, defaulted to today's behaviour):** `FerazelSession.init(…,
  start: (x: Int, y: Int)? = nil /*nil → hdr+0x2848 − 32, hdr+0x2846 − 32 as today (l. 137); Continue passes
  save+0xc/+0x10*/, refreshFacing: Bool = true /*G+0x16 ← hdr+0x26c8 on a carried G (today's W4 rule); Continue's
  loop passes false (M l. 7044–7064)*/, records: [Placement]? = nil /*SV1's restored snapshot*/, hostedByLevelRun:
  Bool = false)`. **With `hostedByLevelRun: true`:** (a) step 1 omits the iteration-0 block (`FerazelSession.swift:245–
  255`: `setScreenClut`, PICT 129, the scroll redraws, the status bar, `.play(track:)`, `hideMenuBar`, `hideCursor`) —
  `LevelRun` emits each at its binary place (level CLUT + PICT 129 after `.SetupLevel`'s `GammaFadeOut(6)`; the redraws
  and status bar through the session's `startOps()` at M l. 5204–5216; `HideCursorSafe` M l. 5203; the music through
  `MusicFade`), so **no second `.play` reaches the shell**; (b) the loop end appends **no** `.loadLevel`/`.deathEffect`
  request (today `loopEnd()`, `FerazelSession.swift` ~l. 369) — `LevelRun` builds `LevelEnd` from the session's end
  state instead; the after-loop stops the session's last step already emits (452/511, then 452/453/511 on a completion,
  ~l. 380) are not repeated by `LevelRun`. **Existing tests:** none changes in L1 — `SessionTests.
  testStepOrderAndSkippedDraw` (l. 328, `first.music == [.play(track: 1)]`) and `LevelFlowTests.testLevel2Header`
  (l. 225, `.play(track: 3)`) build sessions directly (`hostedByLevelRun` false) and keep their expectations; the three
  Phase-2 ◇ `LevelFlowTests` that pin `.loadLevel`/`.deathEffect` are A1a's (Invariant 10: an expectation changes only
  where the plan names it, with the reason). **Level services:** `LevelRun` opens a level through `LevelServices`
  (S2): `prepare(level:)` before the session init (its `faceBounds`/`particleFaces`), `attach(lights:tintTableDraws:)`
  after it — the App's order today (`FerazelController.swift:148–158`).
- **Contract:** digest C §1, §2, §5, §6; M l. 2189–2590 (`.SetupLevel`), 5093–5325 (`.GameLoop`). **Entry, in order:**
  `FadeAIFFMusic(0,4)` + shutdown (M l. 5161–5163; ⚑ run 11: NOT skipped by Continue — they are inside `.GameLoop`, which Continue calls, M l. 7046); `.SetupLevel`: `.PopupStageLoad`
  (L2's machine), then the load bar (`UpdateStageLoad`, L2): **first visit / other level** (the else branch, M l.
  2350–2362, always `.LoadLevelTilesets`) → 15, 20, 25, 35, 40 (M l. 1588–1629; widths 43, 58, 73, 102, 117), then
  50 (M l. 2519; 146), then one bar per cached face set in `.LoadCachedSpriteFaces` (M l. 73832/73859; p/q with q = 2 ×
  the face count, so each ≥ 50 %; self-derived and recorded), then 100 (M l. 73864; 293) and 100 again (M l. 2569; 293);
  **same level with `267d == 0`** (the restart fast path, M l. 2252–2271) → 25 (73), then 50, the face-set bars, 293,
  293. `G+0x20 = 0` (byte), `G+0x22 ← hdr+0x2706`, **key 0x76 (F4) held → `hasSnapshot[L] = 0` (ungated, raw
  `100047e0..10004810`)**; `hasSnapshot[L] == 1` → re-apply the crunch log entries of L with the **explode flag 0**
  (raw `10004874`; no `.ExplodeCrunchedTile`, **no FastRand draws**), each emitted as `setTile` **before the first
  redraw**, and `restoreSnapshot` (+6) → the session's `records:` before the Setups; first visit → tallies 0, after
  `.SetupLevelSprites` `achieved[0…2][L] = 0`, `totals[0][L] ← enemies (*ffb4)`, `totals[1][L] ← Xichrons (*ffb0)`,
  `totals[2][L] ← secrets (*ffac)` (M l. 2528–2536); revisit keeps both; `G+0x174 = 0`; `GammaFadeOut(6)` (M l. 2570);
  level CLUT; PICT 129. `.GameLoop` pre-loop: **`unlocked[L] = 1` (M l. 5180) before the player spawn
  (`MTNewSprite(0,…)`, M l. 5181)**; `GammaFadeIn(8)` only when a4 ∧ hdr+0x2712 ≠ 0 (M l. 5196–5197; never in the data);
  `LoadLevelSounds` (M l. 5199), `DAT_100a5106 = 0` (the loop-exit flag, M l. 5200); `HideCursorSafe` (M l. 5203); the
  session's `startOps()` (AnimateCLUT, tint/redden tables, FindUpperLeftCorner, the entire-grid redraw, status bar,
  M l. 5204–5216); `*fd74 = 0x200` (M l. 5217, after the status bar); boss music rule (M l. 5218); `SetAIFFMusic(hdr+0x284a)` +
  **`FadeAIFFMusic(1,4)` blocking 96 ticks** (M l. 5221–5222; owns Phase-2 carry M13); chapter gate `hdr+0x273c ≠ 0 ∧
  hasSnapshot[L] == 0` → **`InputActivate(1,1)`** then L2's `.ChapterScreen` (M l. 5223–5227); **`GammaFadeInAsync(0x28)`
  on every entry** (M l. 5228; owns the Phase-2 "no fade-in after restart" carry), stepped once per iteration by the
  session's existing `AsyncGammaFade`, gated by `ScreenFade` (faded must be set — `.SetupLevel`'s fade-out always sets
  it; a death inside the first 41 iterations keeps driving the fade-in, digest C §4). **Cadence:** Invariant 4.
  **Exit (M l. 5296–5325):** (the session's last step has emitted stop 452 and 511, and on a completion 452, 453, 511)
  died (`G+4 < 1`, tested first) → `ffa8 = 1`, `FadeAIFFMusic(0,2)` (48 ticks), `.DeathEffect` (50 steps, the Render
  wipe A3 drives today, now driven by the flow); completed → `endLevelSGUpdate` (SV1, with the session's
  `world.records`), `.StageCompleteEffect` unless `fd64` (L2's machine), `fd64 = 0`, `FadeAIFFMusic(0,2)`,
  `GammaFadeOut(6)`; aborted (Esc/⌘W OK with HP ≥ 1, not complete) → neither branch; all → `ShutDownAIFFMusic`
  (`.stop`), `ShowCursorSafe`. `LevelEnd` carries `exit1` (`uRam100a5116`) / `exit2` (`_DAT_100a5118`, stored only
  when p2 ≠ 0, M l. 49738).
- **Tests (8; self-derived numbers recorded on first green, re-derived by the reviewer from the dump):**
  `testEntrySequenceOrder` (L1 first visit: the op/music/tick sequence from `FadeAIFFMusic(0,4)` to the first step:
  popup, bars **43, 58, 73, 102, 117, 146**, the face-set bars (recorded), **293, 293**, GammaFadeOut(6) 30 ticks, level
  CLUT + PICT 129, `unlocked[1]` set before the player spawn, the start ops, **exactly one** `.play(track: 1)` + 24
  volume cues over 96 ticks, `InputActivate(1,1)` then the chapter screen, then the first `step` (no start ops in it)
  with the async fade-in armed for 41 iterations; the restart fast path's bars 73, 146, …, 293, 293) ·
  `testCadenceTwoTicks` (steps at ticks t, t+2, …; prefs+0 = 1: skipped + drawn pairs every 4 ticks; a 30-tick block →
  no catch-up) · `testFirstVisitTotalsLevel1` (`totals[0…2][1]` = the `.SetupLevelSprites` tallies of level 1,
  self-derived and recorded; achieved 0) · `testRevisitKeepsCountersAndSnapshot` (a G with `hasSnapshot[1] = 1` and a
  snapshot with record 24 p1 = 2: the rebuilt level shows the save point at face 2; counters kept; no chapter screen) ·
  `testCrunchReapplyDrawsNothing` (a logged crunch on L1 (119,36): the tiles re-destroyed as `setTile` ops before the
  first redraw, the session's seed after level start equals a fresh L1 start's 0x2c1b1519) · `testF4ClearsSnapshotFlag`
  · `testDeathExitSequence` (24 music cues over 48 ticks → 50 wipe steps → `.stop`; `ffa8` set; no `.deathEffect`
  request) · `testCompleteExitSequence` (EndLevelSGUpdate (`+6` = 1, `hasSnapshot[1]` = 1) → stage-complete machine →
  music fade 48 ticks → GammaFadeOut(6) 30 ticks → `.stop`; `exit1` 0 for L1's rec 66; no `.loadLevel` request).
- **Gate:** G2 = 297, G6, G7(+b), G8, G10; wave 3.2 end: G3, G5.
- **Commit:** `FerazelCore: LevelRun — level entry (SetupLevel restore/first visit, fades, music fade-in, chapter gate, async fade-in), 2-tick cadence, death/complete/abort exits; 8 tests`.
- ⚑ **As executed (L1, loop run 11; 6db035d + 6615728 + aa78964):** G2 297 (no existing test or golden moved). API:
  `LevelRun` (`tick` → `LevelRunOutput`: ordered segments tagged `.level` → FrameRenderer / `.screen` → ScreenRenderer,
  plus `merged`; the chapter card's CLUT 281 is `.screen`, its tail — level CLUT, PICT 129, status bar — `.level`),
  `LevelEnd`, `LevelServices` (+ `deathEffectStep`, bands only), `LevelFaces`, `CachedFaces`, `SetupFaces.Tallies`;
  session init `start:`, `refreshFacing:`, `records:`, `hostedByLevelRun:` + `startOps()`; `LevelCarry` + `globalsImage`,
  tileset state, `cachedFaces`. Self-derived (re-derived by review leg A): L1 face cache n 90 / q 180 → 30 bars (12 sets =
  72 faces + 18 singles, `.InitSprites` order) from width 156; L1 totals enemies 15, Xichrons 43, secrets 10; L2 after L1
  n 31 / q 62; an L1 restart reloads 6 flag-1 singles (bars 7…12 of 12, the fast path never updates the CLUT ids). Dump
  beat plan: `FadeAIFFMusic(0,4)` + shutdown are inside `.GameLoop` (M l. 5161–5163) so Continue runs them (F1b: correct
  your text); crunch re-apply = explode 0, clearDir 1 (raw `10004874–78`); F4 ungated (the bank's "debug only" wrong);
  `*fd74` is the renderer's ripple phase (not Core). **Review fixes:** (HIGH) the completion save stores the player's
  EXIT position — `*fe68/*fe64` are rewritten every frame (M l. 46367–46376, read M l. 6541–6542), not the level start;
  six surviving mutations killed (died/completed order, unlocked-before-spawn, revisit fade-in, first-visit crunch, fd64,
  G+0x174); ops routing tagged (above); `PlatformSprite` reads the live records (deviation: outside Files, no golden
  moved); `ShowCursorSafe` at the async fade-in's end (M l. 31945) + `HideCursorSafe` at the top of every iteration
  (M l. 5233) — **hosted sessions only**: the non-hosted (Phase-2 app) path keeps its one start-block hide because the
  per-iteration hide moves SessionTests/LevelFlowTests/SoundCueTests expectations (Invariant 10). Not landed: the Roach
  Setup's p3 0 → 0xaa write-back (M l. 64940–64944) moves `BackgroundMoverTests.testBackgroundRecordDefaultsWrittenBack`
  → named task **RX** (wave 3.3, first). Stand-ins: `InputActivate(1,1)` no-op; boss-music flag stubbed. **Carries:**
  `.hideMenuBar` is not sent by a hosted session → **F1a** (`.main` M l. 8280, `.MainMenu` 7349) and **F1b** (`.ContinueGame`
  6877); exit2 (`_DAT_100a5118`) is a global only `ShowWorldMap` resets (M l. 67561) → **M1/F1b**; the face cache + the
  tileset globals 267d/267e persist across games in the original but `LevelCarry()` starts fresh → **F1b**; **A1a**
  routes `LevelRunOutput` segments to the two renderers, moves the app onto LevelRun (the non-hosted cursor path and the
  three ◇ `.loadLevel`/`.deathEffect` LevelFlowTests go then), fills `FrontInput.capsLock` and the `StageSounds` length
  table from `SoundBank`; **F1b**'s `GameFlow.tick` keeps the segments. After-loop stops land 2 ticks before the binary's
  (accepted by the plan). Minor open: `SetupFaces.spawnOrder` duplicates `LevelFile.spawnOrder`; `checkRouting` in the
  tests restates the routing rule. Two Opus legs (A NEEDS FIXES, B MERGEABLE) → fix round → Opus re-review (cursor
  regression) → fix round 2 → Opus re-review MERGEABLE.

### Wave 3.3 — the world map

#### RX — minor — Roach Setup p3 write-back (added by loop run 11; → 297, no new test)
- **Why:** L1's review (loop run 11) found `.SetupRoachSprite` writes **p3 0 → 0xaa (170)** back into the live record
  (M l. 64940–64944). The replica does not, and since L1 `endLevelSGUpdate` saves `world.records`, a saved snapshot
  differs from the binary's. L1's fix round built it and reverted it, because it moves an existing expectation.
- **Files:** the Roach arm in `Sources/FerazelCore/Sprites/SetupFaces.swift`;
  `Tests/FerazelCoreTests/BackgroundMoverTests.swift` (`testBackgroundRecordDefaultsWrittenBack`, l. ~1090–1118).
- **Expectation change named here (Invariant 10):** the level-1 loop "every other record as loaded" also exempts the
  Roach records whose p3 is 0 on file (L1's fix round found records 15, 19, 27, 30, 163 → p3 170; re-derive them from
  the level file + M l. 64940–64944 before pinning). Add an assertion on one Roach record; no other golden or expectation
  may move (if one does, STOP and record it). Also check the other Setups `.SetupLevelSprites` calls on L1/L2 for any
  further unbuilt record write-backs, and list them in the as-executed bullet (build them only if no golden moves).
- **Gate:** G2 = 297 (no new test function), G6, G7, G10. One Opus leg. Runs first in [RX M1 M2].
- ⚑ **As executed (RX, loop run 12; 83786a7):** G2 297. `.SetupRoachSprite`'s p3 0 → 0xaa write-back (M l. 64940–64944,
  offset +0xc = p3) built; the named expectation exempts level-1 Roach records 15, 19, 27, 30, 163 (derived from the level
  file in the test), record 19 pinned; no other expectation moved. No other Setup placed on levels 1–2 writes back (the
  reviewer scanned every `.Setup*` incl. split-index forms). Listed, unbuilt (not on L1/L2): box pipes 0x5d2–0x5d5 p2
  0 → 100 (l. 59327–59330); Background 0x76c–0x76f p1 0 → 0x2d, p2 0 → 0x32 (l. 62507–62514); Dillo / Warrior / Wizard p2
  0 → 0x96 (l. 72354, 73056, 75662); cannons 0x69/0x6a p2 → 4 (l. 62125). Carried: `.HandleRoachSprite` (unbuilt) must read
  the written-back p3; the binary also writes for record index 0x1ff (not from a record). One Opus leg MERGEABLE.

#### M1 — ⚑ MAJOR — `WorldMapRun` (→ 305)
- **Files:** `Sources/FerazelCore/Front/WorldMapRun.swift`, `Sources/FerazelCore/World/WorldMap.swift` (lookups only);
  `Tests/FerazelCoreTests/WorldMapRunTests.swift`; bank `world-data-format.md` §4.2 (BC14, BC24).
- **Coordinates:** every map point is written **(h, v)** (node 1 = (h 237, v 307), node 2 = (h 269, v 330)); the
  node table stores (v, h) — convert at the lookup.
- **Contract:** digest B §1–§3; `.ShowWorldMap @ 1007c494` (M l. 67432–67658) and callees. Entry: level-complete flag
  (`_DAT_100a0088`, set by the exit sprite 0xcb1, M l. 49740) and a non-null node handle required (else "Error showing
  world map" 0x100a6d51, return 1); `cur = FindCurrNode(hdr+0x26c4)` (first node that exists and whose level matches;
  none → "Current node could not be found!" 0x100a6d30 + quit; node 60 ↔ level 62, node 62 ↔ level 67);
  **`.ReInitWorldMapGraphics`** (PICTs 600/601, Sprites, 20×20 and 12×12, into two blit ports — loaded for parity,
  M2 draws nothing from them); clut 700 on the ports and screen; PICT 129 (0,0,640,480); status bar; PICT **7000**
  (app fork) into the background at (0,0,608,384) (l,t,r,b), view offset (16, 8); unlock
  `unlocked[node[node[cur].links[exit]].level] = 1` for exit1 and exit2 ≥ 0 (M l. 67513–67524; the exit index is the
  link slot); ambient sprite type 100 at (h 38, v 168) counter −4 (`AddNodeSprite(38,168,100,−4,0)`);
  `.MakeNodeSprites` (M l. 66696) over nodes 0…127: each existing node whose level is unlocked → `FastRand(15)` (drawn
  **before** `AddNodeSprite`; one draw per visible node, node order), sprite at (h−20, v−20), type = node `+0x116`, and
  `.DrawLink(node, link)` for every link slot > 0 whose target's **level** is unlocked (target existence not checked;
  drawn from both ends); marker type 0x45 at (h−20, v−20); **`.UpdateNodeSprites` once before the first draw** (M l.
  67530: the first frame shows node counters `FastRand(15)+1`, the ambient counter −3 → no face);
  music: `SetAIFFMusic(25)` + `FadeAIFFMusic(1,2)` + `GammaFadeIn(15)` (M l. 67540–67542); `walkTarget = cur`,
  `walkStep = 0` (M l. 67543–67544); for exit1 ≥ 0: the unlock again (idempotent, M l. 67545–67557) then
  `.DrawNewLink(cur, exit1)`; for exit2 ≥ 0: the unlock again, `.DrawNewLink(cur, exit2)`, then `walkTarget = cur`,
  `walkStep = 0` (M l. 67558–67559; two new links → no auto-walk); exit1 = exit2 = −1; abort = 0; on-map flag
  `1009fe2c` = 1; **then `InputActivate(1,1)`** (M l. 67561–67565: after the music, the fade-in and the `.DrawNewLink`s,
  just before the map loop). `.DrawNewLink(cur, exit)` (M l. 67171–67274; r3 = cur, r4 = exit, raw `1007c7c0..c860`): snd **420**
  (handle `100a03e0` = load(0x1a4); `STPlayRegSound(…, 1, 0x100)`) once; **50** iterations of 3 `FastRand(32000) << 1`
  (R, G, B — **150 draws**) and three lines in that one colour, **order centre, −1/−1, +1/+1** (`.DrawLink`'s order
  differs, M2), dirty rect = bbox ±10 offset (16, 8), each iteration ≥ 2 ticks from its own start; end: restore the
  plain link from the background, `walkTarget = links[exit]`, `walkStep = 1` (auto-walk). `.UpdateNodeSprites`: types
  0/1 counter +1 wrapping after 15, face = c >> 1 (type 0 → set 8001, type 1 → 8002); 0x45 fixed marker face; 100:
  counter +1 wrapping after 127, face = c >> 4 when c ≥ 0, else none. `.DrawNodeSprites` calls **`.RedrawLinks`**
  (every link via `DrawLinkScratch` into the work port, PenPat black) whenever a drawn sprite has its `+0xd` flag —
  only the ambient sprite, only while its face is non-nil (from about the 4th frame on every frame; links 45–50 and
  50–51 cross its rect); during `.DrawNewLink` the ambient face is nil, so the flashes are not overdrawn (M2 draws it;
  M1 emits it). `.FindPlayerNodeLoc` (M l. 67008–67054, raw `1007b674..1007b788`): **walking ⇔ `cur ≠ walkTarget`**
  (not `step ≠ 0`); step is incremented **before** use; each axis = `trunc(cur·(30−step)/30) + trunc(tgt·step/30)`
  (each product divided separately, truncating signed division); `step ≥ 30` → `cur = target`, `step = 0` **in the
  same call** that computed step 30 — so the walk draws **29 frames, steps 2…30** (both `.CheckPlayerNodeMovement` and
  `.DrawNewLink` set step 1, and the next call raises it to 2 before computing; on the frame a key-move is detected the
  marker is still drawn at `cur`), and on the arrival iteration the movement test and the name update run at once.
  `.CheckPlayerNodeMovement` (M l. 67281–67429): per non-zero link slot, primary/secondary directions (target above =
  `tgt.v < cur.v` strictly: left (`tgt.h < cur.h`) → (1,3) if dv < dh else (3,1), right → (2,3)/(3,2); level or below:
  (1,4)/(4,1), (2,4)/(4,2); a tie makes the vertical primary; equal h takes the "right" branch; zero slots' arrays are
  uninitialised stack in the original — harmless, never read for a real node); keys left = action 0 or 0x7b, right =
  action 1 or 0x7c, up = action 2 or 0x7e, down = action 3 or 0x7d; pass 1 primaries in slot order, first held
  direction whose target **exists and** is unlocked wins; pass 2 secondaries; sets walkTarget, step 1. Loop (M l.
  67567–67650): runs while (no Return 0x24, no Enter 0x4c, no action 6, no action 5) or walking, and not aborted; per
  iteration: `.FindPlayerNodeLoc`; if not walking: movement test + level name `STR# 1000[node[cur].level]` → header
  name → status bar (so **until arrival the bar shows the Mlvl spelling**, e.g. "A Scent Of Peril", BC14); draw; wait
  ≥ 1 tick; Caps Lock (gated on `PTR_DAT_1009fe14 == 0`) → P1's pause (the work port copied to the port at
  `*(1009ff58+0xc)` before, to the screen after) — **M1 leaves a named `// later: P1` stub** at this point (P1 does
  not exist yet; P1 replaces it); ⌘ or Esc held: + Q → confirm "Are you
  sure you want to quit?" (0x100a6d69) → OK: abort + quit flag `1009fd50`; else + W or Esc → confirm "Are you sure you
  want to abort this game?" (0x100a6d88) → OK: abort; Cancel → `HideCursorSafe` (dialog = `ShellRequest.dialog
  (.confirm)`; the flow waits; Esc+Q also reaches the quit confirm). (corrected loop run 12) `FlushEvents(0xff7f)` + `ShowCursorSafe` run only
  inside the Q and the W/Esc branches, just before each confirm (M l. 67602–67646) — not whenever ⌘ or Esc is held. Exit: `FadeAIFFMusic(0,2)`, on-map 0, **the
  node-sprite count `*_DAT_100a0c50 = 0`** (M l. 67652; re-entry starts an empty list); return −1 if aborted else
  `node[cur].level`. The held-⌘ quirk is kept: an idle ⌘ (action 6) ends the loop and enters the current level before
  the ⌘Q test can see it (⌘Q fires only if ⌘ and Q go down inside the same iteration; while walking ⌘Q works) [MED,
  gate card]. Action 5 = jump (default Option 0x3a), action 6 = use (default ⌘ 0x37) — engine §7.1, default bindings.
- **Tests (8; digest B §3):** `testNodeTableAndNames` (24 nodes; boss faces on nodes 5, 18, 25, 55, 62; FindCurrNode(62)
  = 60, (67) = 62; STR# 1000 has 99 entries, [1] "A Scent of Peril", [2] "Central Caverns", [51] "If You Can't Stand
  The Heat…") · `testDirectionsFromNode2` (links 1, 3, 4: left → 1, right → 4, down → 3, up → 1) ·
  `testWalkTwentyNineFrames` (node 1 → 2 after the auto-walk: the marker (h, v) per drawn frame, steps 2…30 = (238,308),
  (239,309), (240,310), (241,310), (242,311), (243,312), (244,313), (245,313), (247,314), (248,315), (249,316),
  (250,316), (251,317), (252,318), (253,319), (254,320), (255,320), (256,321), (258,322), (259,323), (260,323),
  (261,324), (262,325), (263,326), (264,326), (265,327), (266,328), (267,329), **(269,330)** — 29 frames, sprite at
  (h−20, v−20); before the walk the sprite sits at (217,287); `cur = 2` and the name update on the step-30 iteration) ·
  `testUnlockAfterLevel1` (exit1 0 → `unlocked[2]`, DrawNewLink 50 × ≥ 2 ticks with snd 420 and 150 draws, then the
  auto-walk to node 2; the status bar shows "A Scent Of Peril" until arrival, then "Central Caverns") ·
  `testLevel2ExitsUnlock3And4` (p1 1 → node 3 auto-walk; p1 2 → node 4) · `testTwoExitsNoAutoWalk` (level 15 exit1 1 /
  exit2 2: 20 and 30 unlocked, marker stays) · `testMapExitKeys` (Return/Enter/Option/⌘ when idle → returns the
  current level; ignored while walking; Esc → confirm → OK → −1; ⌘Q → quit flag; a second map entry after an exit
  starts with only its own node sprites — the count reset) · `testMapDrawsPerVisibleNode` (after level 1: 2 visible
  nodes → 2 `FastRand(15)` draws + 150; the first frame's node counters = draw + 1, ambient −3; the stream state
  recorded).
- **Gate:** G2 = 305, G6, G7(+b), G8, G10.
- **Commit:** `FerazelCore: WorldMapRun — ShowWorldMap, node sprites, DrawNewLink, the 29-frame walk, CheckPlayerNodeMovement, unlocks, exit keys; 8 tests`.
- ⚑ **As executed (M1, loop run 12; 072bf8b + review fix 70384af):** G2 305 (308 with M2). API for F1b: `WorldMapRun.init(
  resources:prefs:globals:level:levelName:exit1:exit2:levelComplete:seed:fade:music:sprites:)`, `tick(now:input:)`,
  `dialogDone(ok:)`, `result` (nil on the quit paths), `quitRequested`, `aborted`, `mapMissing`, read-back of `globals`,
  `rng`, `fade`, `music`, `exit1`/`exit2` (both −1 once the loop starts — the exit2 global reset), `sprites` (the node-sprite
  list carried across entries: emptied on exit, M l. 67652, and by `.InitPlayerMapData` l. 66610 — not on entry). For M2:
  `WorldMapOutput`, `MapOp` (`.draw(DrawOp, port:)`, `.portsClut`, `.loadMapGraphics`, `.drawLink`, `.redrawLinks`,
  `.copy`), `MapPort`, `MapLink`, `MapFace`, `MapSprite`, `viewRect`/`viewOffset`. **The dump beat the plan (BC31):** the
  map loop's walking test is `step ≠ 0` (only `.FindPlayerNodeLoc` tests `cur ≠ walkTarget`); entry order is clut 700 →
  PICT 129 → status bar → `.ReInitWorldMapGraphics` → PICT 7000 (l. 67498–67512); a second status-bar update follows the
  first frame (l. 67539); a clear level-complete flag — or a nil/empty Mmap — returns **1** (l. 67492–67496); no current
  node → ReportError + `ExitToShell` (l. 67154–67155) → a `.quit` request, no result; FlushEvents + ShowCursorSafe only in
  the Q and W/Esc branches (plan sentence corrected). BC14 checked against STR# 1000: the spellings differ on levels 1, 10,
  50, 51, 67. RNG state after entry + 150 flash draws pinned `0x7b052a62` (self-derived). Held-⌘ quirk modelled as the
  tail keys and the next loop test read on the same tick [MED, gate card]. Caps Lock pause = `// later: P1`. Carried
  (minor): `UpdateStatusBar(1,…)` and `(0,…)` emit the same op; a wrong-length Mmap still throws; the re-entry check can't
  tell "no reset on entry" from "reset on entry" (unobservable); F1b must test `result == nil` with `quitRequested`.
  Two Opus legs MERGEABLE (both: named rules unpinned — 10 mutations survived) → fix round pinned tie / strict above /
  equal-h / unlock-by-level / wraps 15 and 127 / exit2-only / re-entry / ⌘Q while walking / the two error paths → Opus
  re-review MERGEABLE.

#### M2 — minor — Map drawing (→ 308)
- **Files:** `Sources/FerazelRender/Screens/MapRenderer.swift`, `Sources/FerazelRender/Screens/ScreenRenderer.swift`;
  `Tests/FerazelRenderTests/MapRenderTests.swift`.
- **Contract:** digest B §1 (`.InitMapFaces @ 1007ac38`, `.DrawLink @ 1007b7c8`, `.DrawNodeSprites`/`.EraseNodeSprites`/
  `.CopyNodeSpritesToScreen`, `.RedrawLinks`, M l. 66859–66960). `.InitMapFaces` swaps in clut 700 while it loads:
  PICT 8000 marker (one face, 24×24), 8001 normal node and 8002 boss node (`LoadEncFaceSetFromPICT(id, 8, 24, 24, …)`,
  PICT 192×24), 8004 ambient (`(…, 8, 64, 86, …)`, PICT 512×86) (Sprites file); **8003 is loaded, never drawn**
  (`Load1EncFaceFromPICT(0x1f43)` into `_DAT_100a0c40`, M l. 66635–66636, no other reader — the replica skips the
  load, nothing observable). Node faces drawn at slop-8 blit (x, y) = screen-view (x+8, y+8) → centred on (h, v); the
  view sits at screen (16, 8); erase/copy rects (x+4, y+4, x+w+12, y+h+12) (l,t,r,b). `.DrawLink` (into the
  background, pen 1×1): ForeColor 33 (black) the centre line (h1,v1)→(h2,v2), then **+1/+1, then −1/−1**, then
  ForeColor 30 (white) the centre line again, then ForeColor 33. `.DrawNewLink`'s flashes: one random RGB colour
  (through `ColorSearch` under clut 700 [MED: QuickDraw `RGBForeColor` behaviour]) for **centre, −1/−1, +1/+1**, in
  that order. `.RedrawLinks` (when M1 emits it): every link through `DrawLinkScratch` into the **work** port with
  PenPat black — drawn over the ambient sprite. The ambient sprite is never erased (`.EraseNodeSprites` skips type
  100). The level name in the status bar: Times (20) 12 bold white `0xffff` at `MoveTo(27, 46)` (`.UpdateTextStats`,
  M l. 4612–4666) → the existing `StatusBar` path.
- **Tests (3):** `testMapFirstFrameGolden` (after level 1 with seed 1: the flow's first map frame, FNV-1a of the
  indices + CLUT, self-derived) · `testLinkPixels` (the 1 → 2 link (dx 32, dy 23): a white centre pixel on a **flat
  run** of the centre line — not a diagonal step, where the white centre line overwrites a neighbour — flanked by black
  at (+1, +1) and (−1, −1); a flash frame's three lines all in its one colour) · `testNodeFaceCentred` (node 1 face covers screen (h+16−12 … h+16+11, v+8−12 … v+8+11)).
- **Gate:** G2 = 308, G6, G7(+b), G8, G10; wave 3.3 end: G3, G5.
- **Commit:** `FerazelRender: world map — PICT 7000, node faces (slop-8 centring), links, new-link flashes; 3 tests`.
- ⚑ **As executed (M2, loop run 12; b79e58e + review fix 548019f):** G2 308. `MapRenderer` (FerazelRender) draws M1's
  `MapOp` stream into two 656×432 QuickDraw-coordinate ports (faces at slop +8, M l. 31490) and the screen; first-frame
  golden `38563faaa2276f05` (after level 1, seed 1, self-derived). **The plan was wrong on `testLinkPixels`:** a stepped
  line (237,307)→(269,330) never has more than two pixels per row, so no centre pixel has black on both diagonals — the
  test checks each flat pair instead (white pair, black at (+1,+1) of the left, (−1,−1) of the right); flash colours are
  checked on the screen (`.EraseNodeSprites` restores sprite rects in the work port within the iteration). Lines are
  rasterised from the upper end point so a link drawn from both ends hits the same pixels [MED: QuickDraw's ROM line code
  may break ties differently]. The status bar is always drawn in full (M1's op has no full/incremental flag; pixel-identical
  for the shipped nodes, max v 358). Review fix 548019f pins "the ambient sprite is never erased" (a mutation survived).
  Carried (minor, unbuilt): ports start at index 0, not the original's gray fill (nothing visible); an undecodable face
  is skipped silently; `ScreenRenderer` ignores a face op aimed at the screen. One Opus leg MERGEABLE.

### Wave 3.4 — the game flow: title, menu, New Game, death, Continue

#### F1a — minor — `GameFlow` part 1: boot, title, main menu, Credits timing (→ 313)
- **Files:** `Sources/FerazelCore/Front/{GameFlow,MainMenu,BootSequence,CreditsScroll,FrontFiles}.swift`;
  `Tests/FerazelCoreTests/GameFlowMenuTests.swift`; bank `rendering-omnipx-titles.md` §4.1 (BC19), `engine.md` §2.
- **Contract:** digest A §1, §2, §5 (Credits). `GameFlow.init` per S2 (typed `files: FrontFiles`, `levels:
  LevelServices` — L1's protocol, unused until F1b); `loadProgress(faces:)` and the `prefsDialog` accessor (O1's model
  while DLOG 6900 is up) are F1a's. Boot (`.main`, M l. 8136–8358): `GammaFadeOut(6)`; PICT **131** at
  (t 0, l 0, b 480, r 640) (clut 128 set later — the logo is drawn under the CLUT current at boot: the App's default = clut 128
  [MED]); `SetMusicAIFFVolume(V)` (no-op: no music loaded yet), `FadeAIFFMusic(0,99)` (no-op: nothing loaded), `SetAIFFMusic(24)`,
  `FadeAIFFMusic(1,6)` (blocking 144 ticks); `GammaFadeIn(6)`; boot keys polled once: N+F (0x2d + 0x03) → fading
  disabled (`53c2 = 0`) + report "Fading disabled." (0x100a36d0); F1 (0x7a) → "Sound loading turned off."
  (0x100a36e1), `5105 = 0`, and `.InitSounds` loads no effects (M l. 39746);
  the logo stays up for the load time only (the App reports loading progress; no timed wait, no skip);
  `GammaFadeOut(6)`; `SetScreenClut(128)`; PICT **136** (the replica's screen is always 640×480); `GammaFadeIn(6)`;
  the 3-D progress bar (`.Init3DProgBar(36, 440, 190)`, `.Update3DProgBar`, M l. 32050–32170: progress 16.16, +0x48
  per face loaded (the `Load*FaceFromPICT` / `Load*FaceSetFromPICT` loaders), final 0x10000; **skip when |Δw| + 5 <
  8 and p < 58000** — i.e. redraw when the filled width changed by ≥ 3 px or p ≥ 58000; a skipped call does **not**
  update the stored width; the colour ramp of digest A §1) driven by the App's load callback
  (`GameFlow.loadProgress(faces:)`); then `.MainMenu`:
  idle up to 60 ticks (`WaitNextEvent` sleep 60), `GammaFadeOut(6)`, `.DrawMainMenu` (clut 130, PICT 130),
  `GammaFadeIn(6)`. Menu loop (M l. 7303–7445; the whole loop runs only while `DAT_100a5108` is set), only while
  `active`: mouse over a hot rect (427,263,581,305) New
  Game, (434,305,626,345) Continue, (441,346,612,388) Options, (448,387,562,427) Credits, (456,429,539,471) Quit (l,t,r,b)
  with the button down → `.TrackClickOnCommandButton(n, 1)` (highlight PICT 4900+n / normal 4910+n, snd 4803 on
  entry, 4804 on exit and release, both `STPlayRegSound(…, 10, 0x55)`; more than 9 entries → snd 199, absent from
  every fork → silent; button 5 uses PICT 4925 when the screen is not 640×480 — never in the replica); the **mouse**
  New Game path also calls `GammaFadeIn(6)`, the keyboard path does not; pointer over no button: global v < 0x15 (21)
  → `showMenuBar` request, else hide; keys polled in order N (0x2d) → `Track(1,0)` + New Game; O (0x1f) / R (0x0f) → Continue; I (0x22) / P (0x23) → Options; C (0x08) → Credits; Q
  (0x0c) → Quit; X (0x07) with the cooldown 0 → cooldown **30** + report "Coming soon: Ferazel's Destiny; …" (the
  string at its address, verbatim); keyboard track = highlight + 4803, **10 ticks**, normal + 4804; every pass:
  `fd48` → `ContinueGame(_DAT_1009fd18)` (the last reply); cooldown −1. Quit (`.Quit @ 1000e9d4`): `FadeAIFFMusic(0,1)`,
  `ShutDownAIFFMusic` (`.stop`), hide the menu bar, `GammaFadeOut(6)`, if prefs+0x36 ≠ 0 the startup system volume
  restored (`STSetVolume(uRam100a2680)`, M l. 7473 — not reproduced: the replica never sets the macOS system volume,
  Known deviation 8), then `ShellRequest.quit`; prefs are **not** written at quit. `CreditsScroll` (`.DoAboutDialog`,
  M l. 65263–65435): the PICT 4803 strip (144×811) moves up 1 px per 3 ticks inside clip (34,120)–(170,270), starting
  at y 270, wrapping after 961 steps; the App draws it; a click inside ends it, outside beeps.
- **Tests (5):** `testBootSequence` (op/music/fade order and tick counts up to the first menu frame: 30 + 144 + 21 +
  load + 30 + 21 + idle ≤ 60 + 30 + 21) · `testMainMenuHotRects` (each rect's corners in/out; v 20 shows the menu bar,
  v 21 hides) · `testTrackClickKeyboardPath` (N: PICT 4901, 4803, 10 ticks, PICT 4911, 4804, then New Game) ·
  `testMouseTrackSlideOut` (press in, slide out, release outside → no action; 4803/4804 per crossing) ·
  `testXCooldownAndCredits` (X twice within 30 passes → one report; credits strip offset after 300 ticks = 100 px).
- **Gate:** G2 = 313, G6, G7(+b), G8, G10.
- **Commit:** `FerazelCore: GameFlow — boot (logo, loading bar), main menu (buttons, keys, X joke), Quit, Credits scroll timing; 5 tests`.

#### D1 — minor — The death screen (→ 317)
- **Files:** `Sources/FerazelCore/Front/DeathScreen.swift` (incl. the `TurnGray` CLUT maths — **in Core**, because
  `FerazelCoreTests` cannot import FerazelRender; the clut-132 RGBs come from Core's existing `ColorLUT` loader),
  `Sources/FerazelRender/Screens/ScreenRenderer.swift` (applies FE0's `screenGamma(.clut(entries:))` as the screen
  CLUT — no maths in Render); `Tests/FerazelCoreTests/DeathScreenTests.swift`; bank `save-continue.md` §5 (BC10).
- **Contract:** digest C §4 (`.AskToContinue` M l. 3718–3858). `FlushEvents` runs first even when `fe00 == 0`;
  `fe00 == 0` → returns false with no drawing. Else clut
  132 (`100a0014` = `GetCTable(0x84)`), PICT 138, `GammaFadeIn(6)`, cursor shown; loop: mouse down in (252,390,389,411) → `TrackClickDeath(1,1)`, in
  (262,413,378,433) → `(2,1)` (l,t,r,b); Return/Enter → button 1 (InputSprocket is never on: prefs+0x0a forced 0);
  Esc or ⌘Q → button 2; `.TrackClickOnCommandButtonDeath` (raw `10006970`): rects (252,390,390,412) / (262,413,379,434),
  pressed PICT 4979+n, idle 4969+n, 4803/4804 at (10, 0x55), keyboard press holds 10 ticks. Button 1 → `.WandGlow`
  (wait 6 ticks, snd 606 (10, 0x100), 11 frames of 5 ticks: PICT 172…177 then 176…172 at (138,286,220,368)); button 2
  → `.TurnGray` (snd 435 via `STPlay3DSoundPitched(…, 10, 0x100, view centre, 35000)`; frames f = 0…150, ≥ 1 tick
  each; k = max(0, 1 − 100f/7500) (7500.0 @`100a1560`); for clut-132 entries 0…254 gray = (r+g+b) >> 2, scaled by
  (150−f)/75 when f > 75 (75.0 @`100a1540`); c → (int)(c·k + gray·(1−k)) clamped 0…0xffff; `SetEntries(0, 0xff)` as
  the screen CLUT every frame; **afterwards the working table is restored from `1009ff8c`** (the level CLUT copy) —
  a `setScreenClut`-equivalent op before the menu return draws). Returns continue = button 1.
- **Tests (4):** `testNoSaveNoDeathScreen` · `testDeathButtonsKeysAndMouse` (Return → 1; Esc → 2; ⌘Q → 2; a click in
  the 1-px-smaller hit rect) · `testWandGlowTimeline` (6 + 55 ticks; frame ids 172…177, 176…172; snd 606) ·
  `testTurnGrayClut` (Core maths: entry values at f 0 (unchanged), 75 (gray), 150 (black) for two clut-132 entries;
  151 `.clut` ops, then the restore).
- **Gate:** G2 = 317, G6, G7(+b), G8, G10.
- **Commit:** `FerazelCore: the death screen — AskToContinue, death buttons, WandGlow, TurnGray; 4 tests`.

#### F1b — ⚑ MAJOR — `GameFlow` part 2: New Game, the level ⇄ map loop, Continue, death (→ 323)
- **Files:** `Sources/FerazelCore/Front/{GameFlow,NewGame,ContinueGame,BuiltLevels}.swift`;
  `Tests/FerazelCoreTests/GameFlowGameTests.swift`, `Tests/FerazelCoreTests/LevelTestHelpers.swift` (new: the private
  `touchExit(_:record:)` helper moved out of `LevelFlowTests.swift:31` so both suites share it),
  `Tests/FerazelCoreTests/LevelFlowTests.swift` (only the helper removed and its call sites pointed at the shared one —
  no expectation changes); bank `save-continue.md` §4 (BC3, BC4, BC5, BC25).
- **Contract:** digest D §5, B §4; `.NewGame @ 1000b11c` (M l. 5704–5874), `.ContinueGame @ 1000d004` (M l.
  6663–~7102; `.ToggleMusic` starts at 7105). **New Game:** `*fd5c = 1` (set by the callers: File menu M l. 28857 and
  `.MainMenu`); Option held → report "Ferazel sez:\rNo more cheating!" (0x100a2e31) then level 1 (no debug flag);
  `GameFlow.initGameGlobals()` = SV1's `GameGlobals.initGameGlobals(previous:)` + the routine's tail (M l. 815–825:
  `*ffac`, `*ffb0`, `*ffb4`, `*ffa8`, `*ffa4`, `*ffa0`, `*ff9c` = 0, then **`save+6 = 0`** — it is
  `.InitGameGlobals` that clears it, M l. 822–825), then `fe00 = 0`, `fd54 = 0`; level **1** (literal, raw
  `1000b2b8..1000b2cc`); a nil level → `ReportDialog` "An unexpected error occurred -- the level could not be loaded
  from the world file!" (0x100a2e76, M l. 5809 — never reached with the shipped world); loop while not `DAT_100a5106`
  (M l. 5815ff): `FadeAIFFMusic(0,4)`, `ShutDownAIFFMusic`, `ResetCursor`, `G+0x16 ← hdr[0x26c8]`,
  `LevelRun(x: hdr+0x2848 − 32, y: hdr+0x2846 − 32, a3: 0, a4: 1)` (`param_1` → `fe68` player x, `param_2` → `fe64`
  player y); completed ∧ no victory → `WorldMapRun`: −1 → `GammaFadeOut(10)` + end; else open level n (◇
  **`BuiltLevels`**: n outside 1...2 → report "Level n is not built yet (Phases 4-6)." — the only invented text, D35,
  plain Mac Roman, no symbols — and re-enter the map at the same node without unlocking anything new); quit flag →
  Quit; not aborted → `save+0xc/+0x10 ← hdr+0x2848 − 32 / +0x2846 − 32` of the next level (M l. 5838–5839). After the
  loop: died (`G+4 < 1`) → `AskToContinue` (D1): continue → `fd48 = 1` → return (the menu loop's `fd48` →
  Continue with the last reply); else menu return: `GammaFadeOut(6)`, `.DrawMainMenu`, `SetAIFFMusic(24)`,
  `FadeAIFFMusic(1,4)`, `GammaFadeIn(6)`, cursor (M l. 5842–5874). **Continue:** `GameFlow.initGameGlobals()`,
  `OpenSG` (`fd18` reply or `ShellRequest.getFile("Please select the saved game from which you would like to
  continue.")` (0x100a59db) after `GammaFadeIn(0x14)` only if faded; read through `FrontFiles.readSavedGame` / SV2);
  failure → report the SV2 error, back to the menu; level ← save+8 (also `_DAT_100ab9ba`), G ← save+0x18; refusals
  are **three independent tests** (+4 == 1 → "…preview version…" 0x100a2ec9; +5 == 1 → "…demo version…" 0x100a2f33;
  level > 0x4f → the same demo text — a demo save at ≥ 80 shows two dialogs) then back to the menu; **design §9 (d):
  the level resource is missing → report "An unexpected error occurred -- the level could not be loaded from the world
  file!" (0x100a2e76) and back to the menu** — the original's only *displayed* text for a nil level (`.NewGame`,
  M l. 5809); `.ContinueGame` itself dereferences nil, and its `.OpenDefaultWorldLevel` passes "Tried to open a level
  that wasn't there!" (0x100a5af7, raw `10048c44`) to `.SafeReportStr`, which never shows it (fade-in +
  `InputActivate` only, M l. 31976) — D35; default branch only (the replica always opens its default world; no stamp
  check): save+6 == 0 → `G+0x16 ← hdr[0x26c8]` (raw `1000d684/88`) else the session's `records:` ←
  `restoreSnapshot(save+8)` (+6 on x and y); **`FadeAIFFMusic(0,2)` + `ShutDownAIFFMusic` once, before the loop** (M l.
  7040–7041); the loop body (M l. 7044–7064) is **only** `ResetCursor` + `LevelRun(x: save+0xc, y: save+0x10, a3: 0,
  a4: 0, refreshFacing: false)` + the map logic — **no per-level `FadeAIFFMusic(0,4)`/shutdown and no `G+0x16`
  refresh** (unlike New Game); the post-map save position write; death tested via `ffa8` → `AskToContinue`; Continue's
  menu return orders `UpdateMenus` / `MTRedraw` **before** `SetAIFFMusic(24)` (New Game's does not). **Death without
  a save this game** (`fe00 == 0`): `AskToContinue` returns false with no drawing → the menu return — **ruled D35 as
  the original** (no restart; the Phase-2 ◇ restart is gone from the flow; it stays in the App until A1a).
  `FerazelLevel` (hidden switch, kept): New Game starting at level N ∈ `BuiltLevels` instead of 1 — the App passes it
  (D35).
- **Tests (6; headless, scripted input; exits reached with the shared `touchExit` helper):**
  `testNewGameStartsLevel1` (G = `initGameGlobals(previous:)`, the tail's globals 0 and `save+6` = 0 after a
  checkpoint save, chapter card, `G+0x16` from hdr) · `testLevel1ToMapToLevel2`
  (exit → stats → map → auto-walk to 2 → Return → level 2 entered with G carried (HP, coins), `save+0xc` = L2
  hdr+0x2848 − 32 (`LevelHeader.startX` 901 − 32 = 869, pinned by `LevelFlowTests.testLevel2Header`); level 2's exit
  p1 1 → map → node 3 → Return → the "not built yet" report, still on the map) ·
  `testMapAbortReturnsToMenu` (Esc → OK → `GammaFadeOut(10)` → menu sequence with music 24) ·
  `testDeathWithoutSaveGoesToMenu` (no death screen; menu sequence) · `testContinueRefusals` (preview; demo; level 80;
  demo + 80 → two reports) · `testContinueFromCheckpoint` (a block saved at L1 rec 24: one `FadeAIFFMusic(0,2)` before
  the loop and none per level; level 1 at the saved x/y with the snapshot (save point face 1/2), no chapter card,
  `G+0x16` not refreshed on the next level; a block naming level 9 (no `Mlvl` 9) → the 0x100a2e76 report, menu).
- **Gate:** G2 = 323, G6, G7(+b), G8, G10; wave 3.4 end: G3, G5.
- **Commit:** `FerazelCore: GameFlow — New Game and Continue loops, level ⇄ map, death → AskToContinue → reload, refusals incl. the missing level (design §9 d); 6 tests`.

### Wave 3.5 — in-level modal moments: save points, keys, pause

#### S1 — ⚑ MAJOR — The frame suspension seam and the save point (→ 330)
- **Files:** `Sources/FerazelCore/Seams/{FrameOps,FrameSuspension}.swift`, `Sources/FerazelCore/Session/{FerazelSession,SpriteWorld}.swift`
  (resumable special pass), `Sources/FerazelCore/Player/HitPlayerSprite.swift` (the 0x429 arm),
  `Sources/FerazelCore/World/Movers/BoxSprite.swift` (the 0x429 Handle re-face), `Sources/FerazelCore/Front/{LevelRun,SaveGame}.swift`
  (`.SavePointSave`/`.SaveSG` flow); `Tests/FerazelCoreTests/SavePointTests.swift`; bank `save-continue.md` §2.1, §3.1,
  §9.2 (BC1, BC6, BC22, BC23).
- **Contract:** Invariant 6. `FerazelSession.step` returns `FrameOps.suspension` set when the special pass reaches a
  modal hit; the ops so far (the drawn part of the frame) are returned; `resume(_ outcome:)` continues the special pass
  with the **next** contact (the pass's iteration state is kept) and finishes the frame (particles, erase, status bar,
  the rest), returning those ops. `step` while suspended is a precondition failure. Save point (`.HitPlayerSprite`
  Box arm, M l. 49471–49504, raw `10057714..10057858`): type 0x429 on a **landing** (`.PlatformBounce` = 1); gate 1
  `DAT_100a53d6` (no async fade running) else return; gate 2 record p1 == 0; `C = *_DAT_100a0684 + 2`, fire only when
  C > 15 (`cmpwi 0xf; ble`; `PlayerState.savePointHold`, its decay already built — **one step toward 0 per frame in
  both directions**: > 0 → −1, < 0 → +1, 0 stays, raw `1004de68..1004de98`; the landing adds +2, raw
  `10057754..1005775c`); fire: C = −150, `MTSetPortScreen`,
  p1 ← `+0x17e` (facing) + 1, `ShowCursorSafe`, `G+0x16` ← facing, **suspend** with `.savePoint(record)`. The flow runs
  `.SavePointSave` (M l. 6322ff): `InputActivate(0,0)`, `FlushEvents(0xff7f)`, then SV1's writer at that moment (the
  stamp at save+0, `GetDateTime` at +0x19990, the player's whole-pixel x/y `fe68/fe64` of this frame's handler pass,
  sign-extended, the session's `world.records`) → `.SaveSG(prefs[1] == 0)` → after it `MTRedraw`, then when not
  paused (`*_DAT_100a0050 == 0`, always inside a frame) `RedrawEntireScrollGrid`, `ResetCursor`, `HideCursorSafe`,
  `fe0c = 1`, `511e = 1`, `RedrawGameArea`, `UpdateStatusBar(0,0,0)` (raw `1000c804..1000c888`); returns `.SaveSG`'s
  result. `.SaveSG` (M l. 41179ff): reuse (`!param ∧ fd54`) → no dialog; else `^0` text built and unused,
  `SaveName.increment(prefs+0x42)` (the shown default is already incremented), `ShellRequest.putFile` (prompt "Please
  name your saved game.", default name, message = DITL 1003 item 13); on a good reply, **in this order**: `fd54 = 1`
  and the reply kept, **the target file deleted** (`FSpDelete`), the name → prefs+0x42 and the prefs file written
  (`.UpdateSGString`, every save incl. reuse), then `SavedGameFile.write` (type/creator `FWSg`/`Msct`); success →
  `fe00 = 1`, result 1; Cancel → old name back, result 0 (the only path that restores the name); **a write error** →
  the SV2 error report, result 0, and the state the order leaves: the old file already deleted, the new name in
  prefs, reuse armed (`fd54 = 1`) — kept as the original. `resume(.savePoint(saved:))`: success → snd 420 then 421
  (M l. 39787–39790; `STPlayRegSound(…, 1, 0x100)`), `GammaFadeOutAsync(2, white 0xFFFF ×3)` (it calls
  `HideCursorSafe` itself) + three synchronous `HandleAsyncGammaFade` steps (0 %, 50 %, 100 %) +
  `GammaFadeInAsync(0x2d)` = **46** `HandleAsyncGammaFade` calls (k = 0…45, ending when the counter exceeds 45; gate 1
  stays shut until it ends), the completed fade-in ending with `ShowCursorSafe` (M l. 31929–31947); the whole flash is
  skipped when fading is disabled (`DAT_100a53c2 == 0`, gate 1 then stays open); failure → p1 ← 0; `HideCursorSafe`
  both ways. The Box Handle re-faces from p1 every frame (`+0xc0 = face base + p1·0x34`, M l.
  60191–60195): face 1 statue facing right, 2 facing left, first drawn at frame n+2 (save-continue §9.1).
- **Tests (7):** `testSavePointRecordsLevels1And2` (L1 recs 24 (2377, 878), 70 (5134, 435); L2 recs 68, 76, 81; all
  p1 0, rect (0x21,0x3f,0x33,99), gravity 0, one-way) · `testHoldFiresOn15thLanding` (C after each landing frame
  2, 3 … 16 → fire on 15) · `testRefireOn65thAfterCancel` (standing on the point after a cancel: C = −150 + 3j up to
  j = 50 (C = 0), then +1 a frame (2, 3 …) → fires at **j = 65**, both handler/collision orders) ·
  `testSuspendAndResumeSameFrame` (the frame's ops before + after the suspension equal one uninterrupted frame's ops when the outcome is
  "cancelled" and nothing else changed) · `testSaveBlockAtSavePoint` (level 1, x/y = the handler-pass position, `+6`
  = 1, `hasSnapshot[1]` = 1, record 24 p1 = facing + 1 in the snapshot (−6 positions)) · `testSuccessFlashSequence`
  (420, 421, three gamma steps to white, then **46** fade-in steps ending with a `showCursor` request; a second landing
  during them does nothing; with fading disabled no flash and the point re-arms) ·
  `testReuseSavedGamesSkipsPrompt` (prefs+1 = 1 after a first save: the second save writes to the same file with no
  `putFile` request; prefs+0x42 unchanged; a failing write after a fresh prompt leaves the new name in prefs and
  `fd54` set).
- **Gate:** G2 = 330, G6, G7(+b), G8, G10.
- **Commit:** `FerazelCore: resumable frame (FrameSuspension) and the save point — hold counter, SavePointSave/SaveSG flow, success flash, statue faces; 7 tests`.

#### P1 — minor — `.CheckGameLoopKeys` and `.Pause` (→ 335)
- **Files:** `Sources/FerazelCore/Front/{Pause,LevelRun,WorldMapRun}.swift` (WorldMapRun: M1's `// later: P1` stub
  replaced by this pause), `Sources/FerazelCore/Session/FerazelSession.swift` (the second suspension point; **`prefs`
  becomes `public var`** — written by the flow after ⌘P Options' `.MakeCurrPrefs`, so the running session sees the new
  keys/volumes/graphics mid-level; the App and `FerazelAudio` refresh their copies from `FrontOutput.prefs`, A1a),
  `Sources/FerazelCore/Seams/FrameSuspension.swift` (`gameLoopKeys`); `Tests/FerazelCoreTests/PauseKeysTests.swift`;
  bank `engine.md` §7.2, `save-continue.md` §6 (BC15, BC26).
- **Contract:** digest A §6 (M l. 3861–4030, 3136–3270, 3380–3430). Position (M l. 5247–5274): `PaintFrameWrap` (5247)
  → `CheckGameEvents` (5250) → **`.CheckGameLoopKeys` (5251)** → `UpdateDynamicSounds` → `UpdateTrackMap` → FPS → the
  music-cue block → `.UpdateSprites` (5274). Skipped while faded (`fde8`) or an async fade runs (`53d6 == 0`). Every
  confirm is preceded by `RestoreWindowBackground`, `ShowCursorSafe`, `FlushEvents`, `InputActivate(0,0)`. ⌘ (0x37)
  held: S (0x01) → nothing; Q (0x0c) → confirm "Are you sure you want to quit?" (0x100a2ccd) → OK: `PaintFrameWrap(1,1)`,
  `DrawBlackLines` (graphics mode 3 only), `FlushEvents`, `DAT_100a5106 = 1`, `UpdateStatusBar`, **Quit**; Cancel:
  `DrawBlackLines` (mode 3), redraw grid + status bar (no `PaintFrameWrap`); W (0x0d) → confirm "Are you sure you want
  to abort this game?" (0x100a2cec; DLOG 202 — its dead item-5 Save branch, BC26, is not built) → OK: **the same as
  Q's OK minus `Quit`** — `PaintFrameWrap(1,1)`, `DrawBlackLines`
  (mode 3), `FlushEvents`, `DAT_100a5106 = 1`, `UpdateStatusBar` (an abort: no fades, music cut by the exit's stop);
  Cancel as Q's; P (0x23) → `.Options` (O1: the dialog, prefs file, `.MakeCurrPrefs` — not paused, so a changed music
  flag re-applies at once; music not paused) then redraw. Else Esc (0x35) → the abort confirm (OK as W's; its Cancel
  path includes `PaintFrameWrap(1,1)` and `DrawBlackLines` (mode 3)). The ⌘⇧⌥; 0 debug chord after P (M l.
  3938–3947) is reachable in the original but out of scope (debug keys, Rulings 1). Then the debounce counters
  (`fddc`, `fe14` — never set > 0, dead) and Caps Lock (`BitTst(keys, 0x3e)` → key 0x39; the App passes `capsLock`) →
  `.Pause`: gate `53d6`; `InputActivate(0,0)`, cursor; snd **198** (100, 0x100); `*fe28 = 0`, `*fe88 = 0`; if not on
  the map (`fe2c == 0`) `SetScreenClut(level clut)`; `PaintFrameWrap(1,0)` onto the back screen + the status strip;
  PICT **4921** at (207,152)–(432,248) (l,t,r,b) **offset by the back-screen port's (+0x48, +0x46)**; pause flag
  (`*_DAT_100a0050 = 1`, M l. 3198); stop voices `*fe24`/`*fe20` (452, 511); `FadeAIFFMusic(0,1)`; menu bar shown
  (unconditionally inside `.Pause`) + menus enabled per `.UpdateMenus` (paused: New Game/Restore disabled, Abort Game
  enabled; menu clicks accepted at global v < 0x14 by `.HandleMouseEvent`, M l. 7542, app-active gated); loop: counter
  starts **10**, −1 per poll while Caps Lock is up **and** the app is active **and** no sleep is pending (`*fe40 == 0`,
  set by `.MySleepProc`, M l. 3102/3111 — always 0 in the replica), reset to **5** otherwise; unpause at 0 (Caps Lock
  already up on entry → immediate); File ▸ Abort Game while paused → `.AbortGame` confirm → OK clears the pause flag,
  sets `5106` and ends the level (abort); ⌘M/⌘F while paused → O1's toggles (paused: music on stays silent). Exit:
  `FadeAIFFMusic(1,2)`; the volume sync (prefs+0x36/+0x38); if Game ▸ Music was toggled during the pause:
  `SetMusicAIFFVolume(0)`, `SetAIFFMusic(current)`, volume prefs+0x10·256/9 (or 0 when off); `SwitchTo8BitColorMT`
  (nothing in the replica); `fe14 = 0`; if not on the map: `RedrawEntireScrollGrid` + `RedrawGameArea`; `fe0c = 1`,
  `511e = 1`; `InputActivate(1,0)`; menu bar hidden, cursor hidden. ⌘ held alone is still use-item in `.HandleKeys`
  (no exclusion, M l. 47311/47353) — kept. The world map's own Caps Lock / ⌘ / Esc handling is M1's; it calls this
  pause with `fe2c = 1` (no level clut, no level redraw; the work port saved to `*(1009ff58+0xc)` before, copied to
  the screen after).
- **Tests (5):** `testPauseCounter` (Caps Lock up after k down polls → unpause 5 polls later; up on entry → immediate;
  released before the first poll → 10; app inactive holds the counter at 5) · `testPauseEntryAndExit` (198, the
  level clut, the offset banner rect, stops 452/511, music out 24 × 1 tick, menu state paused; exit music in 24 × 2
  ticks, the full redraw, `InputActivate(1,0)`; from the map: no level clut, no level redraw) ·
  `testEscAbortEndsLevelWithoutFades` (LevelEnd .aborted; `PaintFrameWrap(1,1)` + status bar on OK; no
  `FadeAIFFMusic(0,2)`, no GammaFadeOut; `.stop`; ⌘W OK the same) · `testCommandQConfirmQuits` (OK → quit request;
  Cancel → no `PaintFrameWrap`, the frame resumes, the same frame's `.UpdateSprites` runs) · `testKeysIgnoredWhileFading`
  (during the first 41 iterations' async fade-in Esc does nothing).
- **Gate:** G2 = 335, G6, G7(+b), G8, G10; wave 3.5 end: G3, G5.
- **Commit:** `FerazelCore: CheckGameLoopKeys (⌘Q/⌘W/⌘P/Esc) and Pause (Caps Lock, banner, music, menus); 5 tests`.

### Wave 3.6 — talk

#### C1 — ⚑ MAJOR — Conversations and signs (→ 342)
- **Files:** `Sources/FerazelCore/Talk/{ConversationRun,ConvActions}.swift`, `Sources/FerazelCore/Player/HitPlayerSprite.swift`
  (NPC and sign arms), `Sources/FerazelCore/World/Movers/BoxSprite.swift` (the NPC Handle's rect arm),
  `Sources/FerazelCore/Player/{Player,PlayerState}.swift` (talk cooldown `*PTR_DAT_100a06cc`),
  `Sources/FerazelCore/Front/LevelRun.swift`; `Tests/FerazelCoreTests/ConversationTests.swift`; bank
  `conversations-mcnv.md` (BC20, BC30).
- **Contract:** digest E §1–§4 (M l. 49199–49303, 65678–65940, 66025–66560, 61120–61134). NPC arm (types
  0xb87…0xb99): `+0xb0 == 0` ∧ cooldown 0 → cooldown **150**, suspend `.conversation(p1, rec, sprite)`, return (never
  `.PlatformBounce`). Sign arm (2902…2909 except 2907, 2833…2836): (UP held ∨ record p4 == 0) ∧ p1 ≠ 0 ∧ cooldown 0 →
  cooldown **90**, p4 ← 1, then 2902 with p1 > 0 → `.sign(STR# 500[p1])` (`.SimpleConv(4020, "Wooden Sign", text)`),
  other types with p1 > 100 → `.conversation`; **the `.PlatformBounce` fall-through:** 2902 (`+0x15c` = 1) and 2907
  (0xb5b — its Setup also sets `+0x15c = 1`, M l. 59309–59310) fall through when the flag is set; 2833…2836 fall
  through unconditionally. The cooldown
  is cleared by `.ClearPlayerVars` and decremented in `.HandlePlayerSprite` (M l. 42585, 44912). NPC hot rect from the
  Handle's NPC arm (M l. 61120–61134: `+0x34/+0x38` from the face's +8/+0xc; 2957 with p3 → facing left).
  `ConversationRun` (`.Conversation`, `.HandleConvLine`, `.HandleLineResponses`, `.HandleLineActions`, `.SimpleConv`):
  index 19 entry; Escape (0x35) → index 21 + abort; negative index → silent jump; portrait/erase rules (index 0 skips
  both); typing at **2 ticks per character** (any input key held → no delay), the 10-slot trail, the final 9-step
  flush; `ConvPressAnyKeyDeadTime` (any key or the button); all-keys-up waits; the response menu (portrait 4001, name
  "Ferazel", input 2 up, input 3 down (only to a response with a target), inputs 5–8, Return, Enter confirm);
  conditions 1 coins ≥ A, 2 item A count ≥ B (spell flag 0), 3 never, 4 the **low byte** of own record p(A+1) ≠ 0
  (`& 0xff`), 5 world flag A == B;
  a true condition jumps to its target and skips the actions and next; actions 1 coins −= A (floor 0) + coin text
  redraw, 2 give item A × (B == 0 ? 1 : B) — **not** `max(B,1)`: a negative B is added as-is (M l. 66288–66290) — (first
  empty-or-matching slot, count ≤ 99, snd 501 [MED id], HUD ◇ Phase 4), 3 remove item A × max(B,1), 4 own record p(A+1) = 1, 5 world flag A = B, 6 record A p(B+1) = 1, 9 the talker's
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
- **Gate:** G2 = 342, G6, G7(+b), G8, G10.
- **Commit:** `FerazelCore: conversations (Mcnv interpreter, NPC arm, cooldown 150) and signs (STR# 500, cooldown 90) in the suspended frame; 7 tests`.

#### C2 — minor — Conversation drawing and text layout (→ 345)
- **Files:** `Sources/FerazelRender/Screens/ConversationRenderer.swift`, `Sources/FerazelRender/Frame/{TextRasterizer,StatusBar}.swift`
  (protocol additions; the status bar keeps its output), `Ferazel/App/CoreTextRasterizer.swift`,
  `Tests/FerazelRenderTests/StatusBarTests.swift` (`BoxRasterizer` gains the new requirements),
  `Tests/FerazelRenderTests/ConversationRenderTests.swift`.
- **Contract:** digest E §3, §7. Frame PICT **4000** (Sprites, 387×308) at origin (126, 46) copied with mode 0x24
  (its 18,627 pure-white pixels show the game view through); portraits 3999…4025 and 4030…4033 (**no 4026–4029**; 96×96, 32-bit, ditherCopy → the
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
- **Gate:** G2 = 345, G5 (touches the App), G6, G7(+b), G8, G10; wave 3.6 end: G3. **Commit:** `FerazelRender: conversation frame (transparent copy), portraits, Times 18 layout and wrap, trail colours; TextRasterizer widths/metrics; 3 tests`.

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
  present through `presentedClut` then MacGamma as today. `FerazelFiles` implements `FrontFiles`; the controller
  implements `LevelServices` (builds the per-level `FrameRenderer` on the shared surface, hands back `faceBounds` /
  `particleFaces`, takes `lights` / `tintTableDraws` — today's `openLevel` order, `FerazelController.swift:148–158`).
  `FrontOutput.prefs` → the controller's and `FerazelAudio`'s copies replaced. Music: `.play` stops the music voice,
  loads the track under **one fixed mixer id** (`ShellMixer.load(id:)` replaces the previous buffer — owns the Phase-2
  "tracks never unloaded" carry with no HectorKit change) and starts it at volume 0; **`.volume(v)` now carries the
  0…256 scale** (`MusicFade`'s V·s/24) → `setVolume(voice:, Float(v))` directly (today `FerazelAudio.swift:134–136`
  reads it as the 0…9 prefs scale through `musicVolume(_:)` — that conversion is removed for `.volume`; the prefs
  scale stays only where V is computed); `.stop` stops the voice. Effects as today (`SoundTool`).
  Files: the folder `~/Library/Application Support/Ambrosia Classics/Ferazel's Wand/` (created on demand); prefs file
  "Ferazel's Wand Prefs" read at launch (absent → defaults written, `.InitPrefs`), written when the flow asks (Options
  close, music/sound toggles, save name); `putFile` → `NSSavePanel` (title/prompt "Please name your saved game.",
  message = DITL 1003 item 13, default name, initial folder = the Ferazel's Wand folder); `getFile` → `NSOpenPanel`
  (message "Please select the saved game from which you would like to continue.", type 'FWSg' or any file); results
  back through `fileDone`. `application(_:open:)` (Finder open, `.DoOpenDocAE`) → Continue with that file when no level
  is running (else ignored). `FerazelLevel` launch switch → `GameFlow` New Game at that level (1...2). Load progress
  callback while the renderers load faces (the boot bar). Quit request → `NSApp.terminate`; `applicationShouldTerminate`
  from the system → the flow's Quit sequence first.
- **Gate:** G2 = 345 (LevelFlowTests rewritten, count unchanged), G5, G6, G7(+b), G8, G10. **Commit:** `Ferazel app: driven by GameFlow (ticks, mouse, Caps Lock), shared screen, music fades (one track id, 0…256 volume), prefs and saved-game files, Finder open`.

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
- **Gate:** G2 = 345, G5, G6, G7(+b), G8, G10; wave 3.7 end: G3. **Commit:** `Ferazel app: the original's dialogs (abort/quit confirm, reports, Options with key remapping, Credits) and menus (MBAR 128, enabled where the original listened)`.

### Wave 3.8 — phase end

#### A2 — minor — Stage + WHAT-TO-EXPECT + the Phase 3 gate card
- **Files:** `Ferazel/WHAT-TO-EXPECT.md` (rewritten for Phase 3), `tools/stage-ferazel.sh` (only if needed).
- **Gate:** G1 (HK still 0c65dcb), G2 = 345/0, G3, G5, G7, G9 (+ the boot reaches the menu), G10. Then the FABLE-GRADE phase review over
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
| 3.0 | X1 → R1 | one each | run 1: [X1 R1 SV1] (spans into 3.1; one ⚑) |
| 3.1 | SV1 ⚑ → SV2 → FE0 ⚑ → O1 | SV1, FE0 two; SV2, O1 one | run 2: [SV2 FE0 O1] (one ⚑) |
| 3.2 | L2 → L1 ⚑ | L2 one; L1 two | run 3: [L2 L1] |
| 3.3 | RX → M1 ⚑ → M2 | RX one; M1 two; M2 one | run 4: [RX M1 M2] (RX added by run 11) |
| 3.4 | F1a → D1 → F1b ⚑ | F1b two; F1a, D1 one | run 5: [F1a D1 F1b] |
| 3.5 | S1 ⚑ → P1 | S1 two; P1 one | run 6: [S1 P1] |
| 3.6 | C1 ⚑ → C2 | C1 two; C2 one | run 7: [C1 C2] |
| 3.7 | A1a ⚑ → A1b ⚑ | two each | run 8: [A1a A1b] |
| 3.8 | A2 (+ FABLE-GRADE phase review + fixes) | one + Fable | run 9: phase end |

G3 still runs at each **wave** end (a run that spans two waves runs it at the wave boundary too). No HectorKit task:
G1 = HK `0c65dcb` untouched for the whole phase.

- **Dependencies:** SV2 after SV1 (`SaveBlock`); FE0 after R1 (`FerazelDialog` texts) and SV1 (G in `FrontOutput`'s
  flow); O1 after R1 + SV2; L2 after FE0; L1 after SV1 + FE0 + L2 (its entry/exit sequences run L2's `StageScreens`); M1 after SV1 + FE0 (+ L1's `LevelEnd`); F1a after FE0 +
  L1 (`LevelServices`); D1 after FE0; F1b after L1, L2, M1, D1, SV2; S1 after L1 + SV2; P1 after S1 (suspension) + O1
  + M1 (replaces M1's pause stub); C1 after S1; C2 after C1; A1a after every Core task; A1b after A1a + O1 + R1.
- **File overlaps that force order:** `FerazelSession.swift` (L1, S1, P1, A1a), `LevelRun.swift` (L1, S1, P1, C1),
  `WorldMapRun.swift` (M1, P1), `GameFlow.swift` (F1a, F1b), `HitPlayerSprite.swift` (S1, C1), `BoxSprite.swift` (S1,
  C1), `SetupFaces.swift` (X1, L1), `ScreenRenderer.swift` (FE0, L2, M2, D1), `FrameRenderer.swift` (FE0 only),
  `FerazelController.swift` (X1 comment, FE0 no-op arms, A1a, A1b), `FerazelAudio.swift` (X1, A1a), `GameGlobals.swift`
  (SV1 only), `FerazelPrefs.swift` (SV2 only), `LevelFlow.swift` (SV1, L1, A1a), `LevelFlowTests.swift` (F1b helper
  move, A1a).
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
| the map's Caps Lock pause (`// later: P1`) | M1 | P1 (same phase) |
| `ScreenRenderer` no-op arms for `drawFace`/`drawLine` and `restoreView` (`// later: M2` / `// later: C2`) | FE0 | M2 / C2 (same phase) |
| Phase-2 ◇ `LevelFlow` mapping, restart-after-death, App `Ending` | removed in A1a | — (gone) |

## Phase 2 carries owned (from STATE / D33 as built)

| carry | owner |
|---|---|
| death restart has no `GammaFadeInAsync(0x28)` (M l. 5228) | L1 (every entry) |
| exit skips `.StageCompleteEffect` / `GammaFadeOut(6)` / `.EndLevelSGUpdate`, loads level 2 at once | L1 + L2 + M1 + F1b |
| no music fade-in (M13) | FE0 (`MusicFade`) + L1 (`FadeAIFFMusic(1,4)`) + A1a (`.play` at volume 0) |
| music tracks never unloaded | A1a (every track under one fixed mixer id — `ShellMixer.load(id:)` replaces it; `SetAIFFMusic` stops first; no HectorKit change) |
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
   disabled wherever the original did not listen for menus. **This changes design §7.4** ("the original hides it
   during play … HectorShell does the same thing on the Mac") for the windowed case — open question 3.
5. **Fonts:** Times 18 / Times 12 bold come from CoreText (the game ships no bitmap fonts; digest E §7).
6. **Tick:** 60 Hz (D30), not 60.15 Hz; Monitor-Tool millisecond fades rounded up to ticks.
7. Never-initialised bytes of G, the prefs record (incl. the `SetHandleSize` grown tail) and the save block are
   written as 0 (Invariant 7).
8. **System volume:** the original's "set system volume" option (prefs+0x36/+0x38, the Sound & Music popup, `.Quit`'s
   restore of the startup volume, Cancel's restore) sets the Mac's system volume; the replica stores the values and
   never touches the macOS system volume.
9. **Non-macOS builds** (Phase 7): the resource-fork read and the HFS type/creator are `#if os(macOS)`; elsewhere a
   saved game is the data-fork map only.

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
   `ShellScaling.logicalPoint` (digest F); fix round (Opus leg 2): `FerazelSession.init(…faceBounds:particleFaces:)`
   and its iteration-0 block (`FerazelSession.swift:245–255`), `loopEnd()` (~l. 369), `SpriteWorld.records`
   (`SpriteWorld.swift:28–31`), `SetupFaces.spawnLevelSprites` (l. 552–553), `FerazelController.openLevel` (l. 148–158),
   `FerazelAudio` `.volume` (l. 134–136), `ClassicResourceMap.serialize(_:)` (HK l. 69), `ShellMixer.load(id:)` (HK
   l. 103), the `switch op` sites (`FrameRenderer.swift:280ff`, `SessionTests.swift:288`), `LevelFlowTests.touchExit`
   (l. 31). New names are defined once in S2–S5.
4. **Ladder arithmetic (fix round).** 256 + (X1 0 + R1 4 + SV1 6 + SV2 6 + FE0 6 + O1 **6** + L2 5 + L1 8 + M1 8 + M2 3 +
   F1a 5 + D1 4 + F1b 6 + S1 7 + P1 5 + C1 7 + C2 3 = 89) = **345** ✅; cumulative: 256, 260, 266, 272, 278, 284, 289, 297,
   305, 308, 313, 317, 323, 330, 335, 342, 345 ✅ (each task's "Tests (N)" count equals the names it lists). The only
   count change from the draft: O1 +1 (`testToggleMusicAndSound`, ⌘M/⌘F). No HectorKit tests: K1 dropped, HK floor 328.
5. **Layering.** Core gains no AppKit/CoreGraphics; file I/O is Foundation (the two Darwin-only file APIs under
   `#if os(macOS)`, SV2); text metrics live behind `TextRasterizer` in Render/App; G7b added; `TurnGray`'s maths is in
   Core (D1). No HectorKit change.
6. **Risk.** Biggest: the resumable frame (S1) — the special pass must resume at the next contact with identical state;
   `testSuspendAndResumeSameFrame` pins it. Second: `GameFlow` size — split F1a/F1b, pause and talk in their own
   tasks. Third: dialogs on AppKit (A1b) — adapted from BTX's proven code, no kit lift this phase.

---

## Open questions for Ben (non-blocking; execution does not wait — D34)

1. **Saved games in the data fork** (deviation 2): fine, or should the replica write a real resource fork (readable by
   the original on a classic Mac, but stripped by zip/git/Windows)? Default: data fork, reads both.
2. **macOS save/open panels** instead of the 1997 Standard File dialogs — fine? Default: yes.
3. **Windowed menu bar** stays visible (items disabled during play) — or would you rather the windowed game hide it
   while a level runs, as the original did on its full screen? Default: visible. **Note: the default changes design
   §7.4** ("the original hides it during play … HectorShell does the same thing on the Mac") for the windowed case;
   full screen still hides it as §7.4 says.
4. **`-FerazelLevel N`** kept as a hidden "New Game at level N" path for testing — keep or retire? Default: keep.

(The draft's questions 5 and 6 are settled by the binary and are now Rulings 12 and 15: death without a save returns
to the menu as the original; the A-key refusal follows the zeroed record.)

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
save-continue §6 — the menu bar and menus are live inside `.Pause`, where the bar is shown **unconditionally**; the
"reveal at v < 0x15" is `.MainMenu`'s hover (M l. 7345) and "accept at v < 0x14" is `.HandleMouseEvent` (M l. 7542,
app-active gated); the countdown also needs `*fe40 == 0` (sleep pending, `.MySleepProc`, M l. 3102/3111); ⌘W's OK is
⌘Q's OK minus `Quit` (P1, F1a; fix round).
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

*Added by the review fix round (Opus legs 1 + 2 and the four dump verifiers, 2026-10-14):*

BC21 save-continue §3.3 (l. 162) — the save block 0xebe58 is **966,232** bytes; the bank's "965,208" is a decimal slip
(SV1).
BC22 save-continue §9.2 — after a cancelled save the point fires again on the **65th** landing frame, not the 56th: the
hold counter decays one step toward 0 per frame in **both** directions (raw `1004de68..1004de98`), so standing nets +3
only until C reaches 0 at j = 50, then +1 a frame (S1).
BC23 save-continue §2.1/§3.1 — `GammaFadeInAsync(0x2d)` is **46** `HandleAsyncGammaFade` calls and ends with
`ShowCursorSafe` (M l. 31929–31947); the flash is skipped when fading is disabled; `.SavePointSave` starts with
`InputActivate(0,0)` + `FlushEvents(0xff7f)` and ends with `MTRedraw` + the redraw block (raw `1000c804..1000c888`),
returning `.SaveSG`'s result; `.SaveSG` deletes the target file **after** committing `fd54`/the reply and **before**
writing, so a write error leaves the old file deleted, the new name in prefs and reuse armed (S1).
BC24 world-data §4.2 (+ M2's drawing notes) — the map walk draws **29** frames (steps 2…30; step 1 is never drawn;
walking = `cur ≠ walkTarget`); the unlock runs twice (idempotent, M l. 67545–67557); `.UpdateNodeSprites` once before
the first draw (M l. 67530); `.ReInitWorldMapGraphics` (PICTs 600/601) at entry and `InputActivate(1,1)` last before the map loop (M l. 67565,
after the `.DrawNewLink`s and `fe2c = 1`); the
node-sprite count is reset on exit (M l. 67652); `.DrawNodeSprites` calls `.RedrawLinks` while the ambient sprite has
a face; the status bar keeps the Mlvl spelling until arrival; `.DrawNewLink`'s line order is centre, −1/−1, +1/+1
(`.DrawLink`'s is centre, +1/+1, −1/−1, white centre); PICT 8003 is **loaded, never drawn** (M l. 66635–66636), not
"never read" (M1, M2).
BC25 save-continue §4 — Continue's loop has **no** per-level `FadeAIFFMusic(0,4)` + shutdown (one `FadeAIFFMusic(0,2)`
+ shutdown before the loop, M l. 7040–7041); Continue's menu return puts `UpdateMenus`/`MTRedraw` before
`SetAIFFMusic(24)`; "Tried to open a level that wasn't there!" (0x100a5af7) is never displayed (`.SafeReportStr`, M l.
31976) — New Game's "An unexpected error occurred -- the level could not be loaded from the world file!" (0x100a2e76,
M l. 5809) is the original's shown missing-level text; `save+6 = 0` is done by `.InitGameGlobals` (M l. 822–825);
`.ContinueGame` ends ≈ M l. 7102 (F1b).
BC26 engine §9 / save-continue §3.3 — confirmed: DLOG 202's item-5 (Save) branch of `.ConfirmAbortGameDialog` is dead
(DITL 202 has 4 items; raw `100068b4`), so `.DoSaveGame` and the block's world-name pstr (0xe7d98) are never written in
1.0.3; the branch is not built (SV1, P1).
BC27 save-continue §8.2 / engine §8 — the Options Music checkbox never restarts the music (`SetMusicAIFFVolume` after
the shutdown is a no-op, M l. 64546–64565, 41958); `.MakeCurrPrefs` (M l. 7216–7251) restarts track `5be0` when not
paused and +0x0c changed; ⌘M/⌘F are `.ToggleMusic`/`.ToggleSound` (M l. 7105–7214); `.AlreadyUsingKey` returns the
last matching slot's verdict; a modifier key already in use is ignored silently; `.InitPrefs` never writes +0x0d,
+0x48…+0x141 or the pstr tails at +0x142; a CNTL popup's MENU id is its `min` field and CNTL 605 → MENU 601 (MENU 605
unused) (O1, SV2, R1).
BC28 lighting-tables §10 / rendering-omnipx-titles §4.3 — `.GammaFadeOut` ms = `trunc(0.7 · Double(55 · trunc(2.3n)))`
in that order (n 3 → 230, not 231); it also sets `53d6 = 1`; `.TintFadeProc`'s t is rounded to single precision and
the scaled values are written back in place; `.GammaFadeIn` ends with `ShowCursorSafe`; `.SetAIFFMusic(−1)` does nothing
(no stop); `SetMovieVolume(0)` precedes `StartMovie`; `.GammaFadeIn(6)`'s sequence is 0, 0, 1, 2, … 9, 9, 10 … 18 (FE0).
BC29 world-data §4.3 / save-continue §6 — the level-entry load bar: a first visit draws 15, 20, 25, 35, 40
(`.LoadLevelTilesets`), 50, the face-set bars, then 100 twice (M l. 73864, 2569); the restart fast path draws 25, 50,
the face-set bars, 100, 100; `.GameLoop` sets `unlocked[L]` before the player spawn and calls `InputActivate(1,1)`
before `.ChapterScreen` (M l. 5180, 5224) (L1).
BC30 conversations-mcnv — action 2 gives `B == 0 ? 1 : B` (a negative B is added as-is, M l. 66288–66290); condition 4 tests
only the low byte of p(A+1); 2907 and 2833…2836 also fall through to `.PlatformBounce`; portraits 4026–4029 do not
exist (C1, C2).

*Added by M1 (loop run 12):*

BC31 world-data §4.2 — `.ShowWorldMap`'s own "walking" test (the loop condition and the movement/name gate, M l. 67567–67579)
is **step `*_DAT_100a0c18` ≠ 0**; only `.FindPlayerNodeLoc` tests `cur ≠ walkTarget`. Entry order is clut 700 → PICT
129 → `UpdateStatusBar(0,0,0)` → `.ReInitWorldMapGraphics` → PICT 7000 (M l. 67498–67512), and a second
`UpdateStatusBar(0,0,0)` follows the first frame (M l. 67539). A clear level-complete flag returns **1** (not −1) after
"Error showing world map" (M l. 67493–67496). The node sprite's `+0xc` byte has no reader; `+0xd` is written only for
type 100 (the array is static, so 0 elsewhere). `.DrawNewLink`'s end draws the sprites twice around the background
restore (M l. 67263–67270) (M1).

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
10. **No HectorKit change this phase** (fix round; K1 dropped): saved-game and prefs files are written with HK's
    existing `ClassicResourceMap.serialize(_:)`; music tracks load under one fixed mixer id (`ShellMixer.load(id:)`
    replaces the previous track — the same observable bound as the original's dispose). HK stays `0c65dcb`, floor 328,
    no HK D-number, no rebuild of the other apps.
11. **Design §9 (d):** a save naming a missing level is refused with "An unexpected error occurred -- the level could
    not be loaded from the world file!" (0x100a2e76 — the original's only *displayed* text for a nil level, `.NewGame`
    M l. 5809) and returns to the menu. (The draft chose "Tried to open a level that wasn't there!", 0x100a5af7, which
    the original passes to `.SafeReportStr` and never shows.)
12. **Death without a save returns to the menu** — settled by the binary (`.AskToContinue` returns false when `fe00 ==
    0`, M l. 3718ff); D33's restart stub is retired with the App's `Ending`. (Was open question 5.)
13. **`-FerazelLevel N` kept** as a hidden New-Game-at-level-N path within `BuiltLevels`.
14. **Text:** Core never measures text; Render lays it out through `TextRasterizer` (widths, metrics, per-char draw);
    the App's `CoreTextRasterizer` stands in for the classic Times bitmap strikes.
15. **The Controls panel refuses the A key (0x00)** as "already used": `.AlreadyUsingKey` scans 10 slots and slot 9
    (+0x24) is never written by `.InitPrefs`; the replica's record holds 0 there, and the refusal follows that zeroed
    record (settled by the binary + Invariant 7; was open question 6).
16. **The macOS system volume is never set** (Known deviation 8); the prefs fields are kept.
17. **Session seams for the front end** (Invariant 9, defaulted): `FerazelSession.init` gains `start:`,
    `refreshFacing:`, `records:`, `hostedByLevelRun:`; `LevelServices` and `FrontFiles` are the Core protocols the App
    implements; `FerazelSession.prefs` becomes settable (⌘P mid-level).

---

## Review ledger

- **Opus leg 1 — plan vs design + bank + dump: SOUND WITH FIXES.** Findings: the save block is 0xebe58 = 966,232 B
  (965,208 was the bank's slip); FE0 `testGammaFadeInSteps` sequence wrong (0, 0, 1, 2 … 9, 9, 10 … 18); S1's fade-in
  is 46 calls + `ShowCursorSafe`; M1's walk is 29 drawn frames (steps 2…30) with (h, v) order stated; a block of
  omissions (`.RedrawLinks`, `.UpdateNodeSprites` before the first draw, `.ReInitWorldMapGraphics` PICT 600/601,
  `InputActivate`, the node-sprite count reset, the second idempotent unlock, the Mlvl spelling until arrival,
  `.DrawNewLink` line order, PICT 8003 "loaded, never drawn", `.GammaFadeOut`'s formula order, the `.InitPrefs`
  unwritten-field list, the Options music toggle not restarting music, the CNTL popup MENU id in `min` with CNTL 605 →
  MENU 601); `save+6 = 0` belongs to `.InitGameGlobals`; P1's ⌘W OK path and the pause's `*fe40` gate; DLOG 202
  item 5 dead; Q3 vs design §7.4; ⌘M/⌘F unowned; L1's unlock-before-spawn and `InputActivate(1,1)` order. With it,
  **four dump verifiers** (L1/L2/F1b/D1; M1/M2/walk; FE0/F1a/O1/SV2/R1; S1/C1/C2), each with addresses: L1's bar
  sequence, L2's mixed rect conventions, Continue's loop body, the shown missing-level text, `testRefireOn56thAfterCancel`
  wrong (65th), SavePointSave/SaveSG extra steps and the write-error path, C1's action 2 / condition 4 / fall-throughs,
  C2's portrait gap.
- **Opus leg 2 — plan vs the code that exists: SOUND WITH FIXES.** Findings: K1 redundant (`ClassicResourceMap.
  serialize`, `ShellMixer.load(id:)` replaces); L1 must own the session's iteration-0 start ops (no second `.play`) and
  the `ended` requests, naming the tests that would change; the renderer-before-session order needs a level-services
  seam; start x/y + `refreshFacing` session params; placements are an immutable `let` (live copy `SpriteWorld.records`;
  Setups read `c.level.placements`); FE0 must add every S3 case up front with the exhaustive switches in its Files; M1
  uses P1's pause before P1 exists; n 3 fade = 230 ms; "all apps" scheme list; X1's missing files and stale cite; no
  FrameGoldenTests in FE0; F1b's `touchExit` helper; A1a's `.volume` scale; `FerazelSession.prefs` must be settable;
  S2's typed `files:`/`loadProgress`/Options accessor; SV2's Darwin-only APIs; `TurnGray` maths in Core; no "◇" in
  user-facing text; the split test name.
- **Fix round (Opus, 2026-10-14) — what changed:** K1 dropped (R-a; G1 = HK 0c65dcb untouched, floor 328, no HK D16, no
  five-app rebuild; SV2 on `serialize`, A1a one fixed music id; Rulings 10, wave 3.0, execution order, self-audit and
  verification model updated); 966,232 everywhere (R-b, BC21); Q5/Q6 → Rulings 12/15, Q3 notes design §7.4 (R-c); every
  WRONG item applied and every omission folded into its task contract/test; BC21–BC30 added and BC15 corrected; new
  seams `LevelServices`, `FrontFiles`, `FrontOutput.prefs`, `FrontFaceSet`, `ScreenGammaOp`; `PrefsToggles` (⌘M/⌘F,
  `.MakeCurrPrefs`) given to O1 with `testToggleMusicAndSound`; tests renamed `testWalkTwentyNineFrames`,
  `testRefireOn65thAfterCancel`; ladder recomputed **256 → 345** (O1 +1). Chosen differently from a finding: none
  overridden; one decision the legs left open — design §9 (d)'s text is now the original's *shown* missing-level
  string 0x100a2e76 (verifier 1, item 4), recorded in Ruling 11 and BC25. Runs re-sized to 9 (X1 R1 SV1 | SV2 FE0 O1 |
  …).
- **FABLE-GRADE plan leg:** PASS WITH FIXES (G2 256/0 re-run in archive; 7 findings: 1 MAJOR wave order L2→L1, 6 MINOR) — fixed in this round.
