# Deimos Rising Phase 4 — grounding appendix D: the stand-in sweep, the Swift seams, how to cut the work

> Read-only grounding for the Phase 4 (front end) plan, 2026-11-20, at worktree head 68b93b6 (= main; HectorKit
> ef2c341). Appendices A–C ground the original's behaviour; this one grounds the **Swift side**. Line numbers are
> this head's; grep the quoted symbol if a line has moved. Nothing here is a ruling: the seat decides.
> Abbreviations: **RP** = `docs/superpowers/plans/2026-11-05-deimos-remainder.md`; **P3** =
> `docs/superpowers/plans/2026-11-14-deimos-phase3.md`; **GA / GB** = its grounding appendices A / B; **WTE** =
> `Deimos/WHAT-TO-EXPECT.md`; **DEC** = `docs/DECISIONS.md`; **FE** = `docs/deimos/front-end.md`; **Core/Host/
> Render/Audio** = `Deimos/Core/Sources/Deimos{Core,Host,Render,Audio}/`; **App** = `Deimos/App/`.

## Part 1 — the stand-in sweep

Sources swept: RP (stand-ins 163–183, A3 653–668, A4 673–682, gate card 683–722, Phase 4 card 738–743), P3 (goal
15, rulings 53–64, AP 229–240, ST 242–251, gate card 278/287, self-review 300–301), GA 44/76/117/129–130, GB 14/
26/90–94/128–131/162–173/180/200, STATE 150–165, WTE 16–135/230–285, DEC D27 (838), D29 (940–980), D31 (1014–1017,
1023), D45 Deimos (2097–2183), D50 (2344–2472), handoffs 2026-11-14 wave-2b/3 and 2026-11-15 LT/32/33/34, and
`grep -rn "Phase 4\|◇\|stand-in\|until the menu\|front end"` over `Deimos/`. No `docs/handoff-2026-11-2*` exists.

**Work kinds:** **FE** = a front-end screen/flow replaces it · **SEAM** = an additive seam change (rule 7) ·
**DEL** = delete code/argument and re-specify its tests (same names and counts) · **IO** = file I/O · **APP** = AppKit
shell only · **DATA** = data/staging · **Q** = needs a ruling.

| id | What the stand-in does today | What the original does | Recorded (doc:line) | Code (file:line) | Phase 4 work |
|---|---|---|---|---|---|
| S1 | **Game over** ends the session; the driver at once starts a new game (launch's sector, players, seed = TickCount) | game-over notice inside the game (F13 = 110 ticks), return to `FUN_100234d0`: fade, `back`, fade in, best sector → int pref 3, high-score check → name entry, menu (FE §3 steps 4–7) | RP 167–168; WTE 36, 267; DEC 1014–1017 | Host `DeimosDriver.swift:43-53` (doc), `:221-236` (restart block); test `DriverTests.swift:555` (gameover restart) | FE + DEL: the driver hands the ended session to the front end instead of `newSession` |
| S2 | **Esc** ends the session → new game; ended session's Esc **latched** until any `idle` sees it up | Esc quits the game to the same post-game path (FE §3 step 5 tests only app-quit `b8` and cheats — legs A–C to confirm a scores check after Esc); end-of-session FlushEvents; menu has no Esc action (FE §2.8) | RP 169; WTE 37, 99, 279; DEC 973–975 | Host `DeimosDriver.swift:51-53,116,196,234`; tests `DriverTests.swift:135-138` `testEscStartsNewSession`, `:245` `testEscHeldRestartsOnceAndIdleReturns`, `:523-526` `testEscLatchClearsOnSubPassRelease` | FE + DEL: the latch becomes the front end's FlushEvents; the three tests are re-specified |
| S3 | **Campaign end** (after the finale, level `none`) → new game | int pref 3 = 12, fade to black (33), `back`, fade in (9), high-score check, menu; no credits after the finale | P3 15, 63–64, 287; GB 90–94; WTE 38, 230; DEC 2353 | Host `DeimosDriver.swift:43-45`; `HeadlessRunner.swift:115` (`.campaignEnd`); test `DriverTests.swift:661` | FE (same path as S1) |
| S4 | **A film that ends** (runs out, Esc, level complete, game over) **restarts the same film** | demo/`last` mode returns to the menu; film modes never stop `inmu` and never set `b6` (FE §3, NR 4) | DEC 2177; STATE 155–156; WTE 84–85; wave-3 handoff 44 | Host `DeimosDriver.swift:233` (`start` keeps the film) | FE + DEL |
| S5 | **Where a new game starts** = the launch's sector with the launch's player count | each game starts from the menu's 1/2 PLAYER then the level select | P3 55–58 (ruling 1), 229–240 (AP); WTE 40–41; DEC 2434 | Host `DeimosDriver.swift:44-47,233`; `DriverTests.swift:135` | FE + DEL (falls with S1–S3) |
| S6 | ◇ **`-players 2`** launch argument (refused unless 1/2; ignored with `-film`) | 2 PLAYER button (id 2) or the `2` key → `FUN_100234d0(0, 2)` | P3 55; GB 14, 170–173, 200; WTE 42, 71–73; DEC 2351 | App `DeimosMain.swift:24-29,66-69,86-88`; `DeimosController.swift:88-101` | FE (menu) + **Q1** (keep as hidden switch or delete) |
| S7 | ◇ **`-sector N`** (1–12; one life above 1; no finale) | level select `FUN_1002e310`: any sector ≤ int pref 3 (best reached), accept/fail flash (INDEX #62 open); `startedLater` blocks scores and pref 3 | P3 55–58; WTE 43–46, 72, 224–225, 236; DEC 2434, 2456–2460 | App `DeimosMain.swift:30-33,70-73,91-93`; one-life rule already in Core `Player.swift:270` | FE (level select) + **Q1** |
| S8 | ◇ **Level-1 music**: a non-film session emits `[.play(ammu), .stop]` at load (net silence) then `.level(int pref 1)` | the level select plays `ammu` (FE §3 step 3); at level 1's load the `ammu` branch is gated by `FUN_10047f80` = "music playing" (P3 correction 5) — with the select's `ammu` playing only the stop at `100067c4` runs; levels 2+ are unchanged (GB 130: their sequence is already the original's) | RP 170–173, 525; WTE 47–49; DEC 1014–1016; GA 44 | Core `DeimosSession.swift:60,478`; tests `DeimosSessionTests.swift:75`, `FilmPlaybackTests.swift:68,93`, `LevelEndTests.swift:471`, `LevelTransitionTests.swift:137` | FE (select plays `ammu`) + SEAM: the session needs the "music playing" bit at level start (an additive `SessionStart` field, or Core tracking its own music state) — level-1 pins in two tests change, the transition pins do not |
| S9 | ◇ **`-film deNN`** plays a shipped demo (de01–de04, also `last`) | DEMOS button (id 5) / `D` key: the next film whose name contains `Demo`, cycling counter G+0x24; `F` key replays `last` (the previous game) | RP 174–178, 666, 720; WTE 50–52, 74, 284–285; DEC 2468 | App `DeimosMain.swift:20-23,62-65`; `DeimosController.swift:76-87`; Host `FilmLookup.swift:16-20` | FE (demos, F key) + **Q2** (keep `-film` hidden or delete) |
| S10 | **No menu music under a film** | `inmu` (started at boot, §2.4 step 3) keeps playing under demos | RP 177–178, 720; WTE 51–52, 285 | none (absence) | FE (boot/menu music; film modes leave it) |
| S11 | ◇ **Prefs in memory only**: F6, FPS, `supermunki`, volume carry across ◇ restarts, lost at quit | prefs file (0x34f0 record, obfuscated) read at boot, written at quit; first launch shows the configuration dialog (byte pref 2) | RP 179–180, 741–742; WTE 53–54, 135; DEC 954–955, 1016–1017; design 2026-10-06 §7.5 | Core `DeimosPrefs.swift:3-5` ("File I/O … Phase 4"), `KeyTable.swift:14`; Host `DeimosDriver.swift:49-50,85-86,232`; test `DriverTests.swift:553-558` `testPrefsSurviveRestart` | IO (codec in Core, path in Host/App) + DEL (carry moves to the front end, which owns prefs for the app's life) |
| S12 | ◇ **One player in the app** (Phase 2) | — | RP 181; DEC 1017 | — | **closed** by S6 in Phase 3; listed so the sweep is complete |
| S13 | ◇ **The mouse does not end a film**; `HeldKeys` has no mouse | `FUN_10048e60` (mouse button, `10048e6c`) ends a film at `10005a24`; menu hover polls `GetMouse`; clicks track with `StillDown` | RP 182–183, 551, 743; WTE 55; STATE 154; DEC 2137–2140; wave-3 handoff 48 | Core `DeimosSession.swift:235,299`; `Seams/HeldKeys.swift:7-19`; App `DeimosController.swift:410` (empty `mouseDown`) | SEAM (mouse in `HeldKeys`) + Core one-line film rule + APP |
| S14 | **The quit flag inside the Caps Lock wait** is not modelled (`+0x02` always false) | the pause loop also ends when `b8` (app quit) is set → controller `+2` → the session quits (FE §8) | STATE 154–155; wave-3 handoff 48 | Core `FrameController.swift:14-15,51`; `FrameKeys.swift:216`; Host `DeimosDriver.swift:276-281` (wait) | SEAM (an app-quit request into the driver/session) + FE |
| S15 | **⌘Q terminates at once** (`NSApp.terminate`); nothing saved | File▸Quit, `Q`, or the Quit AppleEvent set `b8` → QUIT hilite 10 ticks, element fade-out, music stop with fade (`FUN_10048120(1)`, ≤ 600 ticks), prefs written (FE §2.4 step 1, "On b9") | — (not recorded as ◇) | App `DeimosController.swift:229-230`, `:347-356` | APP + FE + **Q5** (⌘Q during a game) |
| S16 | **Menu bar = app menu only** (Quit + hidden ⌃⌘F) | `GetNewMBar(128)`: Apple▸About (= credits) and File▸Quit; About disabled during a game (FE §2.3, §3 step 2) | — | App `DeimosController.swift:215-234` | APP + SEAM (a request to enable/disable About) |
| S17 | **The session hides the cursor** on its first pass; nothing shows it again | the front end hides it before the game (`10023550`) and shows it after (`InitCursor`, `100238b4`/`10023ad0`); the menu shows it | DEC 975; RP — ; Core doc | Core `DeimosSession.swift:90-93`; test `DeimosSessionTests.swift:180-186` `testCursorHiddenAtSessionStart` | FE (move or keep the hide; add `.showCursor` after) — `ShellRequest` already has both |
| S18 | **Attract counter G+0x24 not kept** | the DEMOS cycle counter (wraps) | — | Core `GameFlags.swift:7-9` | FE (front-end state, not `GameFlags`) |
| S19 | **"Last Film" recorder not modelled**; `Film` decodes only | every non-film game records both players' input bytes + score (`FUN_10009710`, `FUN_10009830` at `1002a414..1002a42c`), saved as `last`, tag index rebuilt | GA 76; design §7.6; RP 741 | Core `DeimosSession.swift:44`; `Player/PlayerUpdate.swift:14-15,78`; `Film.swift:56` (decoder, no encoder); `TagIndex.swift:94-100` (one `Data/Local` root) | Core (recorder at the input step — a gameplay file) + IO (encoder, write to the user's Local folder) + Core `TagIndex` second Local root |
| S20 | **Highest sector, cheat and cut-off results not produced**; the session reports only `sessionEnded: Bool` | the game fills a result record (`[0x15]` cheat, `[0x16]` unregistered cut-off); the front end writes best sector → int pref 3 (scoring-bonuses §9.2) and checks the 15th score | FE §3 step 5 | Core `Seams/PassOutput.swift:22`; cheat counters `GameFlags.swift:60-66`; Host infers the end in `HeadlessRunner.swift:110-118` (traps on an unknown end) | SEAM (an additive session result) |
| S21 | **Volume keys only in play** (ruled silent, D31.8) | the menu also takes charCodes 0x9D/0x8A for int pref 0 ∓ 10 (FE §2.8) | DEC 1023–1026; design 2026-10-06 §11 Q4 "Phase 4 (menu)" | — | FE + **Q6** (extend D31.8 to the menu) |
| S22 | **No boot**: the app opens straight into a game | loading screen + progress lines (MED), logos `pucr`/`publ`, developer logo + `inmu` (FE §9, worked example) | WTE 20–21; RP 740; spec 2026-11-05 §Phase 4 | App `DeimosController.swift:62-142` | FE |
| S23 | **No menu, scores, name entry, credits, configuration dialog, controls window** | FE §2, §4, §6; DITL 190 configuration; DITL 191 controls (PICT 190–197) | WTE 20–21; RP 740–743; P3 300–301 | — | FE + Core dialog decoder (see Part 2 §8) + **Q3, Q4** |
| S24 | **Player 2's keys cannot be changed** (keypad defaults; laptop has none) | changed in the controls window (InputSprocket's on OS 9; the replica builds DITL 191 — design Q8 default) | P3 60–62 (ruling 2), 278; GB 180; WTE 105–116 | Core `DeimosPrefs.swift:15-17`, `KeyTable.swift:13-39` | FE (controls window) writes `prefs.keyTable` |
| S25 | **No game controller** | — (InputSprocket) ; Ben ruled a pad as the original's keys (D45.5, D36/D37 shape) | DEC 2110; RP 742 | — | APP (`ShellView.padMapping`) + **Q7** (button layout) |
| S26 | **A bad launch value quits silently in Release** (alert is DEBUG-only) | — | STATE 158; DEC 2460 | App `DeimosController.swift:177-187` | moot if Q1/Q2 delete the arguments; else **Q1** |
| S27 | DEBUG **`-debugCapsLock <s>`** (A3 machine check); swallows a following flag | — | STATE 159 follow-ups; DEC (A3) | App `DeimosMain.swift:37-42,74-80`; `DeimosController.swift:276-278,414-426` | DEL or keep DEBUG-only (planner) |
| S28 | DEBUG **audio counter** wrapper and its logs | — | RP 663–668 (A3 gate) | App `DeimosController.swift:39-44,196-201,242-248,428-497` | keep DEBUG-only or DEL (planner) |
| S29 | **Resume shows the held screen** at once (original: black window until the next present) — disclosed; the comment already names the menu | the menu redraws on the update event (FE §2.5 what 6) | DEC 979–980 | App `DeimosController.swift:297-304` | carry the disclosure into the menu (no change, or redraw on update) |
| S30 | **App resource fork not in the app**: `Resources/Deimos/Deimos Rising.rsrc` (MBAR 128, DITL 190/191, PICT 190–197) is beside `Data`, not staged | the app's own fork | — | `tools/stage-deimos.sh:12,38-41` (copies `Data/` only); census reads it `Sources/deimos-census/AppResourceFork.swift:1-30` | DATA (stage it) or transcribe the few rects into Core (Ferazel’s way, Part 2 §8) |

**Launch arguments and DEBUG switches when the menu exists**

| Switch | Today | Options (the visible ones are Q1/Q2 for Ben) |
|---|---|---|
| `-players N` | Release, refused unless 1/2 | (a) delete with its parser and `BadValue` (`DeimosMain.swift:24-36,85-119`); (b) keep as a hidden test path that skips the menu — Ferazel kept `-FerazelLevel` this way (`Ferazel/Shared/FerazelDriver.swift:6-16`, D33/D35); (c) keep but only preselect the level select |
| `-sector N` | Release, 1–12 | as above; note it bypasses the level-select unlock (int pref 3), so (b) is a cheat the original lacks |
| `-film deNN` / `last` | Release | (a) delete — DEMOS/`D` and `F` replace it; (b) keep hidden (it is Ben's fallback oracle for G4 on the gate cards) — then decide whether it returns to the menu (S4) |
| `-debugCapsLock s` | DEBUG only | keep (A3's check), fix the swallowed-flag bug, or delete |
| `DEIMOS_DATA` env | DEBUG only in the app (`DeimosAssets+Bundle.swift:13-25`); tests/tools always | unchanged |

**Other notes.** ◇ stubs of Phases 1–2 (D29.6, Phase-1 driver Esc, `Player.updatePhase1`) are already deleted. STATE's
small follow-ups that fall inside Phase 4's files: the app's parser has no test target; its two data alerts bypass
`refuseLaunch`; `HeadlessRunner.reason` traps on an unknown end (a quit end will need a case); four private film
lookups in the Core test bundle; a failed `--frames` write hides a film's line (tool, not Phase 4).

## Part 2 — the Swift seams Phase 4 builds on

### 1. Package (`Deimos/Core/Package.swift`)
Products: libraries `DeimosCore`, `DeimosRender`, `DeimosHost`, `DeimosAudio`; executables `deimos-census`,
`deimos-replay` (:14-21). Deps (:26-57): Core ← HectorResources + HectorAudio; Render ← Core; Audio ← Core +
HectorAudio; Host ← Core + Render + Audio; census ← Core + HectorResources/Audio/**Graphics**; replay ← the four.
Test targets (:58-73) and counts today (`^func test` per target; G2 = 372):

| Target | Deps | Tests | Data locator |
|---|---|---|---|
| DeimosCoreTests (49 files) | Core + HectorResources/Audio/Graphics | 303 | `RealData` (`DeimosDataTests.swift:6`) over Core's `DeimosData.dataDirectory()` (`DeimosData.swift:13`) |
| DeimosRenderTests (5) | Render, Core | 32 | `DeimosData.dataDirectory()` (`RendererTests.swift:8`) |
| DeimosHostTests (2) | Host, Render, Core, Audio | 17 (DriverTests 14, ReplayHarnessTests 3) | same (`DriverTests.swift:10`) |
| DeimosAudioTests (3) | Audio, Core | 15 | own `AudioTestData` |
| DeimosCensusTests (1) | census, Core | 5 | — |
| DeimosReplayTests (G4, skipped by G2) | replay, Host, Core | 4 | own `ReplayTestData` |
| DeimosCampaignTests (G8, skipped by G2) | Host, Core | 3 | own `CampaignTestData` |

New source files inside an existing target need no `Package.swift` change (SwiftPM globs the folder). A new
library or test target does (rule 9: one task at a time).

### 2. `DeimosSession` (Core `Game/DeimosSession.swift`, ★ LOCKED S2)
- Start: `SessionStart(sector:players:film:)` (:5-18). `init(assets:prefs:start:seed:ticks:levels:) throws` (:131)
  runs `FUN_100051a0`'s set-up and the level start; throws `SessionError` (:20-29). `levels:` reuses a loaded
  `LevelSet` (restarts decode no masks).
- Pass: `mutating pass(keys: HeldKeys, ticks: UInt32) -> PassOutput` (:270; old `pass(keys:)` :337 kept);
  `transitionFadeEnded(ticks:)` (:366). Public read-outs (:77-124): `assets`, `start`, `game` (internal set),
  `controller`, `console`, `levelInfo`, `prefs`, `rng`, `players`, `scoreBar`, `scroll`, `level`, `sector`,
  `gameTime`, `appeared`, `running`, `restoreInterlace`.
- End: the pass that clears `G+0x08` carries `sessionEnded = true` (`PassOutput.swift:22`); non-film it appends
  the halt and `.stop` (:319-322). **No end reason or result** is returned: `HeadlessRunner.reason` (:110-118)
  re-derives game over / level complete / campaign end / film end from `game.flags` and traps otherwise. The
  ended session stays readable (scores, `flags.levelsStarted`, `flags.allLevels`, cheat counters), so a front end
  can read it — but an explicit result (quit vs Esc, cheated, best sector) is the additive seam S20 needs.

### 3. The seams (Core `Seams/`) — LOCKED, additive only (RP rule 7, DEC D29.1/D31)
| Seam | Shape today | Phase 4 needs |
|---|---|---|
| `HeldKeys` (:7-19, S3) | `held: Set<UInt16>`, `capsLock`, `typed: [UInt8]` | **mouse**: logical point + button (held) + click edges (down/up, for `StillDown` tracking) — S13, menu |
| `PlayerInput` (S3) | OptionSet, 7 bits = film byte | none |
| `RenderOp` (:34-61, S3, "cases may be added, never renamed") | `loadTerrain`, `fill`, `loadImage` (im16 only — the renderer decodes TGA alone, `DeimosRenderer.swift:116`), `copy`, `draw`, `clearLayers`, `flushLayers`, `screenBlit`, `fade(FadeKind, PresentKind)`, `limit`, `present`, `particles`, `pauseWait`; host ops = `fade`/`limit`/`pauseWait` (:64-69) | a **tick wait** (button flash F61 = 10 ticks, element-fade steps every F160 tick, the advert/flash waits) and maybe a **wait-for-click/key** op; element fades (FE §5.2, 32 steps) can be draws with alpha + a tick wait. Each new case updates the 4 exhaustive switches: `RenderOp.isHostOp` (:65), `DeimosRenderer.apply` (`:53`), `DeimosDriver.idle` (`:246`), `HeadlessRunner.apply` (`:123`) |
| `FadeKind` / `PresentKind` / `BufferID` | 9-step from black, 33-step to black; 3 presents incl. `.fullScreen` (the menu's) | enough for FE §5.1 (only these two screen fades exist) |
| `ShellRequest` (:4-7) | `hideCursor`, `showCursor` | quit-the-app, About enable/disable, possibly OS alert / URL / dialog requests (S15, S16, S23) |
| `MusicCue` (:4-10) | `play(tag, loop)`, `stop`, `pause`, `resume`, `level` | **stop with fade** (`FUN_10048120(1)`; today "no fade from a cue", `DeimosAudioEngine.swift:117`, `MusicStream.swift:113-114`); a "music still playing" answer (FE §2.4 step 3; S8) — tracked in Core from its own cues (looped tracks only end on stop) rather than read back from the audio thread (cf. the AllowOnlyOneInstance hazard, RP rule 10). Switches: `DeimosAudioEngine.swift:109`, `DebugAudioCounter` (App) |
| `SoundCue` | id, priority, volume, pitch, allowMultiple | none (`mbro`, `incl`, `tran` are ordinary cues) |
| `PassOutput` (:15-43, S3) | ops, sounds, music, requests, ticked, sessionEnded, haltEffectsAt, fadeToBlackAt | reuse for front-end passes; an end-result field if S20 goes here |

### 4. Prefs, keys, assets (Core `Game/`)
- `DeimosPrefs` (★ LOCKED S2, :6-61): `version`, `bytePrefs[0x64]` (2 config done, 4 full screen, 5 interlace, 6 auto,
  7 bypass volume, 8 Esc-hold, 9 FPS, 10 limiter, 11 cheats), `intPrefs` (0 sound vol, 1 music vol, 3 best sector),
  `keyTable[14]`, `highScores[15]`, `highScoreNames`, `highScoreSectorNames`, `playerNames[2]`; `.fresh` (:46-61) =
  `FUN_10004540` defaults. **No codec**: the 0x34f0 layout, obfuscation and on-disk score form (+0x24a8903) are
  Phase 4. Core may do Foundation file I/O, but design §7.5 / spec puts the file's owner in Host; never
  `UserDefaults` below the App (rule 1, Wine).
- `KeyTable` (:13-39): `codes`, `slotBits`, `input(_:player:)`, `inputs(_:)` — the controls window edits
  `prefs.keyTable`; a gamepad maps buttons to these same codes in the shell.
- `FrameKeys` (★ name; :65-257): begin/end frame, `startSession`, `levelTransitionReset`, `endFrameWrapper`,
  `fpsCounterRequest`; key constants (Esc 0x35, F6, `-`/`=`, console).
- `DeimosAssets` (★ S2, :10-98): `index: TagIndex`, `floats`, `gameStrings` (37 × 0x80), `formats` (54 `tefo`),
  `objects`, `sounds`, `sprites`, `fonts`, `rects`, `colors`, `definitions`, `unitIndex`, `levelOrder`;
  `gameString(_:)`, `spriteGroup(_:)` (cached). No `inte` string list (FE §2.3 loads 28) — `StringList` decodes any.
- `TagIndex(dataDirectory:)` (`TagIndex.swift:94`) scans `Data/Local` then the paks, Local overriding — one root.

### 5. Text and element drawing reusable by menus (Core)
`DeimosText.decode/decodeCString` (obfuscation, :7-17); `TextFormat` (`tefo` fields, :19-50); `StringList`
(:18-35, `string(at:)`); `Text/TextLayout` (★; `TextRequest` :8-28 with layer/drawNow/scale/keepTemplateClip,
`TextLayout.init(assets:)` :104, `measure` :115, `layout` :127, `draw` :208 → `[DrawCommand]`); `GlyphMap`;
`Seams/DrawCommand` (alpha, flags, layer — the blend a 32-step element fade needs); `ScoreBar/` (game-only);
`NoticeSlot` (its reset `FUN_10018130` is also called by the level select, :92); `MessageQueue`; `GIFImage`
(im08 plates) and `TGAImage` (im16) decoders. Menus are thus draws on the layer queue + `.present(.fullScreen)`.

### 6. Render (`DeimosRenderer.swift`, `Presents.swift`, `Fades.swift`, `FadeToBlack.swift`)
`final class DeimosRenderer`: `init(assets:)` (:43), `screen` (:48), `buffer(_:)` (:50), `apply(_:)` (:52, traps on
host ops), `fadeBegin/fadeStep(_:a:present:)/fadeEnd` (:82-88); buffers back 640×480, terrain (resized per level),
scoreSave 160×480, screen (`Presents.swift:42-55`); presents `gameScreen`/`gameLayout`/`fullScreen` (:12-40);
levels `Fades.fromBlackLevels` 0…32 by 4, `toBlackLevels` 32…0. A menu `back` TGA loads with `.loadImage(into:
.back/.terrain)` (FE §2.3 draws it into both buffers +0x68/+0x6c — terrain is the menu's restore buffer).

### 7. Host (`DeimosDriver.swift`, `HeadlessRunner.swift`, `FilmLookup.swift`, `MacTicks.swift`)
- `DeimosDriver` (struct): `init(assets:prefs:rate:start:audio:) throws` (:152); `suspend()`/`resume()` (:166/:174);
  `screen` (:183); `idle(seconds:keys:) -> DriverOutput` (:189; `DriverOutput` = `screenChanged`, `requests`, :7-18).
  Loop (:189-295): fade steps (t0 + 1 tick), pass end → ◇ restart block (:221-236), `.limit` (FPS_Delay 2 ticks),
  `.fade`, `.present` (one per call), `.screenBlit`, `.pauseWait` (Caps Lock up, not suspended). `beginPass`
  (:298), `route` cues (:333), `newSession` (:399). Holds `session` (internal var, :95), `prefs` (:87), `start`
  (:91). Bounded work per `idle`: one limiter release, one present, one restart.
- Sinks: audio `DeimosAudioSink.apply(sounds:music:haltEffectsAt:)` (`DeimosAudioEngine.swift:8-12`); frames are
  pulled (`screen`), not pushed. Typed characters accumulate in `typedQueue` across `idle` calls, flushed at a
  restart, at the pause wait and after a transition fade; held keys are sampled at pass begin.
- Clock: `MacTicks.ticks(seconds:rate:)`, `TickRate.osx` 60.0 / `.classic` 60.15. Tests use a file-private
  `FakeClock` (`DriverTests.swift:15-20`) that owns the seconds handed to `idle`.
- `HeadlessRunner` (:51-136): `init(assets:start:seed:prefs:render:)` (:63), `init(assets:film:render:)` (:72),
  `run(maxPasses:) -> ReplayResult` (:81); applies ops straight to a renderer, skips host waits — a session-only
  runner. `FilmLookup.film(_:in:)` (:16) is the one tag lookup.

### 8. App and HectorShell
- `DeimosMain.swift`: `@main` (:5-15) builds `DeimosController(options: LaunchOptions(arguments:))`; `LaunchOptions`
  (:19-120). `DeimosController.swift`: data load (:62-118), 640×480 `ShellWindowController` `.integerFit`,
  `[.titled, .miniaturizable]` (:120-150), 1/240 s `ShellIdleTimer` → `driver.idle` (:138-140, :239-257),
  `heldKeys` = `pollKeyState` once per Mac tick + typed (:266-283), key-down → Mac charCodes (:362-402), cursor
  requests honoured over the image only (:334-345), suspend on background/miniaturise (:310-328), ⌃⌘F full
  screen (:405-408), `mouseDown` empty (:410). `project.yml:146-169`: the Deimos target links the four Deimos
  products + HectorShell; sources `Deimos/App` only.
- HectorShell (kit ef2c341): `ShellInputHandler` mouseDown/Up, keyDown/Up, flagsChanged, padKeyDown/Up
  (`ShellView.swift:7-17`); `ShellView.logicalMouseLocation()` → canvas point (:168); `keyState`/`pollKeyState()`
  (:48, :265); `padMapping: ShellPadMapping?` (:56) folds `GCController` buttons into `keyState.held` as Mac key
  codes (`ShellGamepad.swift:21`; BTX `BTXController.swift:657`, Ferazel `FerazelController.swift:509`);
  `ShellPadMapping`/`ShellPadTranslator` live in Foundation-only **HectorInput** (Windows-usable). Full screen:
  `ShellWindowController.enterFullscreen/exitFullscreen` (:37/:58). **No file-location helper** in the kit:
  Application Support (`~/Library/Application Support/Ambrosia Classics/Deimos Rising/`) and `%APPDATA%` are
  computed by the shell. No menu-bar helper beyond AppKit. **DITL decode is `HectorGraphics/Ditl.swift`
  (CoreGraphics `CGRect`)** — not importable by Core (G7); Ferazel wrote Foundation-only DITL/DLOG/MENU/MBAR
  decoders in `FerazelCore/Front/DialogResources.swift:97-281`. PICT 190–197 need HectorGraphics' PICT path
  (ImageIO) — census-only today.

### 9. Goldens and gates today
Frame goldens are **self-derived FNV-1a 64** over a `Pixmap555` (`fnv1a64`, `LevelOneFrameTests.swift:82`; the
`HeadlessRun` helper :9; `testFrameGoldens` :318 after passes 2…3200 with seed 0x469c2; `testPanAndBankGolden`
:360, recorded with the HectorKit + Classics SHAs), backed by **pixel oracles read straight from the source
images** (`jum2`, `scor`, `pl1o`); a trace hash in `ReplayGateTests.swift:64`; table hashes in
`EffectsTests.swift:170`. The helpers are internal to DeimosRenderTests: per-screen goldens either join that
bundle or a new bundle copies them (Package change). Gates: RP G1–G11 (RP 33–84; G2 ladder by `^Test Case` count,
G4 4/0, G5 three app builds, G7 layering grep, G9 muted boot with Ben's say-so); P3 adds G8 (`DeimosCampaignTests`
3/0) and the four-heavy-process cap (P3 24–46). Staging: `tools/stage-deimos.sh` (Release build, copies `Data/`
only, ad-hoc sign, `out/Deimos/` + Desktop, WTE beside it).

### 10. Shared files — what forces tasks to run one at a time
| File | Why every front-end task wants it |
|---|---|
| `Seams/HeldKeys.swift`, `RenderOp.swift`, `MusicCue.swift`, `ShellRequest.swift`, `PassOutput.swift` | each addition updates every exhaustive switch in the same commit (rule 7) |
| `Host/DeimosDriver.swift` (+ `DriverTests.swift`) | the loop, the restart block, new host ops, quit |
| `App/DeimosController.swift`, `DeimosMain.swift` | mouse, menu bar, quit, prefs path, gamepad, arguments |
| `Package.swift`, `project.yml` | any new target/product (rule 9) |
| `Game/DeimosSession.swift`, `Game/DeimosPrefs.swift` | result record, ammu gate, mouse film end; LOCKED prefs gains no fields but a codec beside it |
| a new `FrontEnd` state type (its screen enum) | every screen task adds a case unless the skeleton declares them all as ◇ stubs (D31.3 pattern) |
| `tools/stage-deimos.sh`, `Deimos/WHAT-TO-EXPECT.md` | staging (rsrc) and the card |

## Part 3 — where a `FrontEnd` could sit (options, not a decision)

| | (a) **Core** state machine owning screens and creating `DeimosSession`s; the driver calls it | (b) **Host**: the driver grows into the screen machine | (c) **App**: AppKit screens around the driver |
|---|---|---|---|
| Files | new `Core/FrontEnd/*.swift` (no Package change); `DeimosDriver.swift` swaps `session` for the front end (restart block :221-236, `beginPass` :298, `newSession` :399); seams per Part 2 §3; App passes mouse/quit and honours new requests | `DeimosDriver.swift` (or new Host files) hold the screens and call `DeimosRenderer` directly; Core gains only the session result | `DeimosController.swift` + new App files; driver keeps one screen |
| Headless tests | all of it: menu logic as op lists, timings via `FakeClock` through the driver, per-screen goldens via the renderer | yes via `FakeClock`, but screens that draw directly are pixels-only (no op-list asserts); Host tests file grows | none — the app has no test target (STATE follow-up) |
| Windows (Phase 5) | free: Core + Host shared; the SDL shell supplies mouse, menu substitutes, file paths, pad | free as well | re-port everything (the BTX cost D15 that D29.1 was written to avoid) |
| Fit | the 2026-11-05 spec's ownership table (`FrontEnd (DeimosCore, new)`, prefs file in Host); Ferazel's precedent `FerazelCore/Front/GameFlow.swift` + 20 screen files | keeps clock waits in one place, but mixes rules with timing and makes `DeimosDriver.swift` the collision point of every screen | only the OS pieces belong here: menu bar, quit, cursor, file locations, gamepad device, native alerts if ruled |

**Screens that could be built side by side once a skeleton exists.** Skeleton (serial, one ⚑ task): the
front-end type with every screen as a ◇ stub case; the driver calling it; the seam additions (mouse in `HeldKeys`,
a tick-wait op, music stop-with-fade, quit/About requests, the session result); the ◇ restart deleted and the
restart tests re-specified; a test bundle if goldens leave DeimosRenderTests. Then, on disjoint files:
1. **Boot + logos + loading lines** (Core `FrontEnd/Boot*`).
2. **Main menu**: buttons, layout, hover, keyboard, copyright/registration flip (`FrontEnd/MainMenu*`).
3. **Level select** + flash (INDEX #62) + `ammu` (`FrontEnd/LevelSelect*`; the S8 session gate is a one-line
   Core change best kept in the skeleton or this task alone).
4. **Scores + name entry + erase prompt** (`FrontEnd/Scores*`, `NameEntry*`).
5. **Credits** (`FrontEnd/Credits*`).
6. **Prefs file codec** (Core `PrefsFile*`, Foundation; path wiring in Host/App later, serial).
7. **Films**: demo cycle (G+0x24), `F` key, Last Film recorder + `Film` encoder + `TagIndex` second root —
   touches `PlayerUpdate.swift` and `Film.swift`, disjoint from the screens but not from gameplay; G4 must stay 4/0.
8. **Dialogs**: configuration (DITL 190), controls (DITL 191), a Foundation-only DITL reader in Core; the gamepad
   mapping in the App (serial with any other App task).
App wiring for each group lands in a final serial task (DeimosController/DeimosMain/project.yml/stage script).

**Questions for Ben** (each changes what he sees): **Q1** keep `-players`/`-sector` as hidden switches or delete
them; **Q2** keep `-film` hidden (and what it returns to) or delete it; **Q3** the registered banner's text and
name (the replica is the registered game; pgsl 34/35 print a registrant); **Q4** the REGISTER and web-link
buttons in a registered build (the link's site is gone) and whether OS alerts (erase scores, web link) are native
macOS alerts or drawn; **Q5** what ⌘Q does mid-game; **Q6** the menu's volume keys follow his D31.8 ruling
(silent); **Q7** the gamepad's button layout. For the planner, not Ben: whether goldens get their own bundle;
where the "music playing" bit lives; whether the app fork is staged or its few records transcribed.
