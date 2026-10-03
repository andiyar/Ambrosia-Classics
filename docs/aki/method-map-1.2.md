# Aki 1.2.0 — method map (i386 slice)

Every ObjC method (77, from `nm ghidra/Aki12_i386 | grep -cE '[-+]\['` → 77) and every named C
function of the game layer, one line each. Methods marked *(no block)* have no decompile block in
the dump (Ghidra failed or they are trivial); where they matter they were read with
`otool -tV ghidra/Aki12_i386 -p '<symbol>'`. Labels: a line without a label is a one-line summary
of a function read in full this session ([HIGH] by default); `[LOW]` = described from its name /
callers only.

## 1. ObjC classes and methods

### Controller (NSObject; app delegate + window/menu owner; ivars from `otool -oV`)
ivars: `_window` 0x04, `_view` 0x08, `_firstLaunch` 0x0c, `_updateAvailable` 0x0d, `_launched`
0x0e, `_sparkle` 0x10, `_aboutBox` 0x14, `_acknowledgementsViewer` 0x18, `_releaseNotesViewer` 0x1c,
`_preferences` 0x20, `_fullscreenWindow` 0x24, `_savedDisplayMode` 0x28, `_fullscreen` 0x2c,
`_inactivePause` 0x2d, `_idleTimer` 0x30, `LastTimeCount` 0x34, `LastMouseCount` 0x38,
`UpdateTimeCount` 0x3c, `Flash` 0x40, `lastTick` 0x44, `LastColor` 0x48, `MusicCheck` 0x4c,
`ColorDown` 0x4d, `lastPreview` 0x4e, `lastMouse` 0x50.
| method | addr | does / calls |
|---|---|---|
| +sharedController | 0x2887 | *(no block)* singleton accessor [LOW] |
| -dealloc | 0x2891 | releases windows/viewers |
| -awakeFromNib | 0x2924 | stores shared instance, `srandom(time(0))` (used by the proverb pick), `_Initialize`, `_RedrawMapScreen` |
| -applicationDidFinishLaunching: | 0x2951 | Sparkle setup; RT3_Open + registration panel (out of scope); `_LoopMusic(1)` (license→p+0x20e bit0), `_PlayMovie(0x80)`; inits tick ivars; **schedules `idleTimerFired:` every 0.05 s** (`scheduledTimerWithTimeInterval:` double 0x3fa999999999999a = 0.05, repeats) in default, modal and event-tracking run-loop modes; `finishLaunch:` after 0.5 s |
| -finishLaunch: | 0x41d4 | windowed or `_enterFullscreen` per p+0x212; first launch (p+0x215) → `SplashScreen("welcome")` |
| -applicationShouldTerminate: | 0x2cf7 | in game → `abortGame` (confirm); in editor → save alert (`_RunModalSaveAlert`, `_DoSaveAs`) |
| -applicationWillTerminate: | 0x2d7d | unregistered nag view (out of scope); invalidates timer, `ExitMovies`, `RT3_Close`, `FT_Close`, exits fullscreen |
| -applicationWillResignActive: | 0x2ecb | stops music (temporarily sets paused flag around `_PlayMovie`) — does **not** pause the game |
| -applicationDidBecomeActive: | 0x2efe | RT3 refresh; restarts music unless in game with "no pairs" |
| -applicationShouldTerminateAfterLastWindowClosed: | 0x2f7e | returns YES [LOW — 14-line block] |
| -application:openFile: | 0x2f99 | defers to `openFile:` |
| -openFile: | 0x2fda | Finder-opened level: leave editor (save prompt), registered → if in game confirm abandon (dialog 0x57) then `_TriggerGameToMap`; `_LoadCustomLevel` with the given path; unregistered → dialog 0x55 |
| -windowDidResignMain: | 0x30c0 | windowed & not paused → `pause`, `_inactivePause = 1` |
| -windowDidBecomeMain: | 0x30f6 | `_redrawWindow`; if `_inactivePause` → `unpause` |
| -windowShouldClose: | 0x3153 | close = quit path [LOW] |
| -checkForUpdates: | 0x31c1 | Sparkle — out of scope |
| -gameMenuAction: | 0x31db | `[sender tag]` → `_HandleMenuCommand(tag)` |
| -performClose: | 0x31fe | [LOW] window close |
| -showAboutBox: / -showAcknowledgements: / -showReleaseNotes: | 0x327a/0x32bc/0x358e | info windows (rtf) [LOW] |
| -showHandbook: / -showHelp: | 0x33b2/0x342c | opens `Aki Handbook.pdf` [LOW] |
| -showPreferences: | 0x3443 | creates `Preferences`; fullscreen → `runModal`; windowed → `pause` + sheet. The fullscreen branch lost its message arguments in the decompile: whether it pauses is NOT RESOLVED (INDEX #12) ⚑ corrected (review 2026-10-03) |
| -preferencesSheetDidEnd:returnCode:contextInfo: | 0x41c3 | *(no block)* sends `unpause` (otool) |
| -showRegistration: | 0x350e | RT3/ASWRegistration — out of scope |
| -toggleFullscreen: / -isFullscreen | 0x3684/0x36ec | flips `_fullscreen` via enter/exit |
| -_enterFullscreen | 0x36f8 | `CGDisplayBestModeForParameters(main, 32?, 800, 600)`, fade out 0.25 s, `CGCaptureAllDisplays`, `CGDisplaySwitchToMode`, shielding-level 800×600 window, fade in [MED: bpp arg not resolved] |
| -_exitFullscreen / -_finishExitFullscreen: | 0x3a05/0x3b52 | restore saved display mode, release displays |
| -_redrawWindow | 0x3bde | `_RedrawEntireWindow` / map redraw [LOW] |
| -pause | 0x3c1f | in game: stop tick sound; if pairs: if not paused `_PauseGame(1)` else mark g+0x7f (already paused by user) |
| -unpause | 0x3c85 | *(no block)* in game, pairs ≠ 0, g+0x7f == 0 → `_PauseGame(0)` (otool) |
| -abortGame | 0x3cbc | dialog 0x57 "LoadLevel" (confirm); OK → give-ups[level]++ (level < 12), end level, return YES |
| -exitLevelEditor | 0x3d4b | save prompt if dirty (g+0x1f0); stop music; `_AnimationEditorScreenToMap` |
| -validateMenuItem: | 0x3de5 | per-screen enabling and retitling (table §4) |
| -updaterWillDisplay: | 0x4280 | Sparkle — out of scope |
| -window | 0x42be | accessor |
| -keyDown: | 0x42eb | game: Esc → `abortGame`; editor: Esc → `exitLevelEditor`, arrows → `_SlideRight/Left/Down/Up` (0xF703/0xF702/0xF701/0xF700), '1'..'7' → `_SelectLevelButton` |
| -mouseDown: | 0x4489 | map: bottom bar (v 559..588) → `_SelectMenuOptions` (time frozen meanwhile) else `_SelectMapArea`; game/editor: v 555..587 → `_SelectCGButton` / `_SelectLevelButton`; else editor `_CreateTile`, game `_SelectCGTile` with double-click guard (rules §7) |
| -idleTimerFired: | 0x4686 | **main loop**: map → `_MapScreen(&LastTimeCount,&LastMouseCount,&LastColor,&ColorDown,&lastPreview,&MusicCheck)`; editor → `_EditorScreen()`; game → `_CustomGameScreen(&UpdateTimeCount,&Flash)` (args from otool) |

### Preferences (NSWindowController, nib "Preferences")
ivars `_soundCheckbox` 0x28, `_fullscreenCheckbox` 0x2c, `_animationCheckbox` 0x30,
`_musicCheckbox` 0x34, `_descriptionCheckbox` 0x38, `_sheet` 0x3c.
| -init 0x6232 | initWithWindowNibName:@"Preferences" |
|---|---|
| -_updateUI 0x6584 | *(no block)* sets checkboxes from `_p` [LOW] |
| -cancel: 0x6264 | ends modal / sheet |
| -save: 0x62ee | writes the five prefs (file-formats §2.2), toggles fullscreen if changed, `_SavePrefs`, `_PlayMovie` |
| -beginSheetModalForWindow:… 0x647b / -runModal 0x64fc | presentation |

### LevelDescriptionWindowController (NSWindowController, nib "LevelDescription")
ivars `_checkbox` 0x28, `_imageView` 0x2c, `_titleTextField` 0x30, `_descriptionTextField` 0x34.
| +runModalWithLayout:custom: 0x29d40 | *(no block)* builds keys `level%d_title` / `level%d_custom_title`, `level%d_description`, image `preview%d` with n = layout+1, calls the next method (otool; levels.md §3) |
|---|---|
| +runModalWithTitle:description:image: 0x29e86 | shared instance, `_setupWithTitle…`, run modal |
| -init 0x29f79 / -_setupWithTitle:description:image: 0x2a0a7 | nib load, fill fields |
| -cancel: 0x29fcd | g+0x7c = 1 (level not started), stop modal (otool) |
| -continue: 0x2a02e | p+0x214 = checkbox state, stop modal (otool) |

### Views and windows
| -[AkiView drawGWorld:src:dst:display:] 0x2a1b8 | copies a GWorld rect into a CGImage and draws it into the view (flip y: 600 − …); the bridge from the QuickDraw off-screen pipeline to Cocoa |
|---|---|
| -[AkiView keyDown:] 0x2a146 / mouseDown: 0x2a17f / acceptsFirstResponder 0x2a13c *(no block)* | forward to Controller |
| -[AkiWindow setFrame:display:] 0x2ac38 | [LOW] frame clamp |
| -[AkiFullscreenWindow canBecomeKeyWindow] 0x28504 *(no block)* | YES [LOW] |
| -[AkiQuitView drawRect:/performKeyEquivalent:/_done/acceptsFirstResponder/keyUp:/mouseUp:] 0x2a867.. | unregistered quit nag (`buyaki.png`) — out of scope |
| -[AkiSplashWindow initWithImage:timeout:/center/_done/canBecomeKeyWindow/keyDown:/mouseDown:] 0x2a94a.. | borderless splash; closes on key/click/timeout |
| -[AkiSplashView mouseDown:] 0x2ac01 | dismiss |
| -[PaperBackgroundView drawRect:] 0x2850e | tiles `paper.png` behind dialogs |
| -[NSWindow(AkiAdditions) centerWithCGDisplaySize/scheduleSetShieldingLevel/…NoCenter] 0x2a4fb.. | fullscreen helpers |

## 2. C helper families (game layer)
**Screens / state machine** — `_MapScreen` 0x6652 (per tick: lantern blink, hover preview,
plays Preview sound), `_RedrawMapScreen` 0x70cd (map + unlocked lanterns + difficulty word; shows
proverb / TryAgain / reload after a loss), `_SelectMapArea` 0x78c2 (level pick, lock, Option
bypass, practice alert, description, `_LoadLayout`), `_SelectMenuOptions` 0x8041 (Preferences /
difficulty ± / Quit buttons on the map bar), `_AnimationMapScreenToCustom` 0x10f5f (1-s split
slide-in, `background%d`, LevelStart sound, timer init, menu enables, "Give Up" title),
`_AnimationCustomGameScreenToMap` 0xdca0 (reverse slide, GameOver sound if lost, "New Game"/"Replay"
titles), `_TriggerGameToMap` 0xe5a2, `_AnimationMapScreenToLevelEditor` 0xb2c0,
`_AnimationEditorScreenToMap` 0x8598, `_CustomGameScreen` 0x12dbc (game tick, rules §10/§14),
`_EditorScreen` 0xbf37 (editor tick: ghost tile under the cursor at the current layer).

**Game logic** — `_LoadLayout` 0x132f1, `_Layout1..12`, `_AddTile` 0x146bc, `_LoadCustomLevel`
0x14177, `_ShuffleCustomTiles` 0x12763, `_ReshuffleCustomTiles` 0x133ff, `_SetVisibleTiles`
0x12328, `_SetOpenTiles` 0x1245e, `_CountOpenPairs` 0xe5e4, `_SelectCGTile` 0x13eec,
`_SelectCGButton` 0x1356f (hint / reshuffle / pause buttons at h 24..49, 62..87, 100..125),
`_RedrawMatchedTiles` 0x13af5, `_ShowNextCGHint` 0x12622, `_UndoLastCGMove` 0x128cb, `_PauseGame`
0xd34b, `_HandleMenuCommand` 0xd465, `_RandomBackground` 0x12d60, list plumbing `_DeleteTile`
0x12caa, `_DeleteDeadTile` 0x12d35 (frees removed tiles; no caller in the 1.2 dump — `find_func.py '_DeleteDeadTile\(' --names` hits only itself; 1.1 calls it),
`_DeleteAllCGTiles` 0xd7f2, `_DeleteAllSTTiles` 0xd880, `_WriteCustomStruct` 0x12c4e /
`_WriteSurroundingTiles` 0x12b6f (allocate-and-forget leftovers, leak), `FUN_00012bb9` /
`FUN_00012c06` (inlined list-append helpers for ST/CG lists), `_CalculateSurroundingTiles` 0x138a7.

**Game drawing** — `_DrawGameTiles` 0xfe0a (full board compose: z 0→6, diagonal sweep
x−y descending, face from `tile_pictures.png` onto the blank of `tiles.png`, overlays: selected
row 69, hint row 138, greyed row 207, masks at 276.. and 1035), `_DrawBufferTiles` 0x11495 /
`_DrawFadeBufferTiles` 0x11e6d (partial recompose around the matched pair, fade frames
`face*0x45+0x114`), `_RedrawTile` 0x11c93, `_RedrawCustomGameScreen` 0x10a07,
`_RedrawCustomTimeBar` 0xefa0, `_RedrawCustomTimeAccumulated` 0xe6e4, `_RedrawCustomOpenPairs`
0x103f5, `_RedrawNoMorePairs` 0x10854, `_FlashCGButton` 0xd90e (button highlight cycling
6-frame counter g+0x88), `_RedrawEntireWindow` 0x10975.

**Level editor** — `_CreateTile` 0xc6ec, `_CheckNotOverlap` 0xa5e5, `_RemoveTile` 0xa531,
`_CountTiles` 0x9a39, `_CountTilesAtCurrentLayer` 0xa910, `_DrawEditorTiles` 0x9a66,
`_DrawTempToWindow` 0x9f92, `_RedrawLevelEditorScreen` 0xb0cd, `_RedrawLayerButtons` 0x8d0d,
`_RedrawNudgeArrows` 0x956a, `_RedrawTileCount` 0xa93d, `_SelectLevelButton` 0xa28d (layer 0..6
buttons at h 37..69 step 42; Option-click = show only that layer; nudge arrows h 367..549),
`_SlideLeft/Up/Down/Right` 0xa0a9.., `_UndoLastLEMove` 0xc89b (one step; layer/all clears undoable
via undo list, `undoLayer == 9` marks a group), `_DoClearLayer` 0xc5c3, `_DoClearAll` 0xc4c6,
`_DeleteAllTiles` 0xa774, `_DeleteAllUndoTiles` 0xa802, `_WriteStruct` 0xa47a / `_WriteUndoStruct`
0xa890 (allocate-and-forget leftovers), `FUN_0000a8d3` (undo-list append), `_DoSaveAs` 0xb89d,
`_LoadFile` 0xcb60, `_RunModalSaveAlert` 0x4d0a (Save / Don't Save / Cancel).

**Dialogs (Carbon nib windows in `Aki.nib`)** — `_CreateNewDialog(id)` 0x4ef9: 0x1e Warning,
0x28 Unavailable, 0x3c Stats (fills the 12×5 + 3 total fields), 0x47 Stacked, 0x50 Incomplete,
0x51 Transfer, 0x53 TryAgain, 0x55 PleaseReg, 0x56 Permissions, 0x57 LoadLevel, 0x58 FileNotFound;
each centred, paper background, app-modal. Handlers `_WarningEventHandler` 0x5a87 …
`_LoadLevelEventHandler` 0x5e89 set g+0x81 (OK) / g+0x22a (TryAgain OK) and quit the modal loop.
`_ShowSplashScreenWithImage` 0x5f06, `_SplashScreen` 0x6069 (by image name), `_RandomProverbScreen`
0x60c8.

**Graphics core** — `_InitializeGWorlds` 0x27a36 (loads the PNGs into 800×600-or-image-size
GWorlds: misc→g+0x00, tiles→+0x04, proverbs→+0x08, tile_pictures→+0x0c, pause→+0x10,
background1→+0x14 (replaced per level), previews→+0x18, plate→+0x1c, map→+0x20, nopairs→+0x24,
notavail→+0x28, four scratch buffers +0x2c/+0x30/+0x38/+0x3c, arrow→+0x34, layer_buttons→+0x40),
`_CreateGWorld` 0x485c (PNG via CGImage into a 32-bit GWorld), `_DrawToGWorld` 0x4a04 (CopyBits /
CopyDeepMask with a mask rect; mode −9 = plain copy), `_DrawToWindow` 0x4b40 (CopyBits to the
window port, optional flush), `_DrawFromWindow` 0x4c48, `_GetMouseLocation` 0x46ee. 800×600 fixed
canvas. [HIGH for the table; CopyDeepMask semantics MED — library behaviour]

**Sound / music (QuickTime Movies, not NSSound)** — `_InitializeSound` 0x27cea registers 11
effects (id → file): 0x4b chime.aiff (pause), 0x14 Reshuffle.aiff (no more pairs), 0x1e
LevelComplete.aiff, 0x28 GameOver.aiff, 0x32 LevelStart.aiff, 0x3c Preview.aiff (map hover),
0x46 TileMatch.aiff, 0x50 cancel.aiff (mismatch / editor overlap), 0x5a unclick.aiff (deselect),
100 tick.mp3 (low time loop), 10 tilehit.mp3 (select / editor place). `_AddSoundInfo` 0xcfb7,
`_LoadSoundIntoMemory` 0xd066 (`NewMovieFromFile`), `_PlaySound(id, vol)` 0xd28c (rewind, volume,
`StartMovie`; muted unless p+0x210 ≠ 0), `_LoopSound` 0xd21f (restart tick when done), `_StopSound`
0xd305. Music: `_InitializeMusic` 0x27ca2 — track 0 "Aki Theme 3.mp3" (map), 1 "Aki Theme 1.mp3",
2 "Aki Theme 2.mp3" (game); g+0x5c current, g+0x5e last game track; `_LoopMusic(0)` 0x275e5
loops track 0 and alternates 1↔2 in game; `_PlayMovie(vol)` 0x2755c starts/stops per music pref
(p+0x20e ≥ 2) and pause. `tick.aiff` is in the bundle but never registered. [HIGH]
`_LoopMusic(1)` is the obfuscated RT3 license check (with `_Useless8` 0x272ce as filler) —
registration, out of scope.

**Prefs / files / misc** — `_LoadPrefs` 0x293f6, `_SavePrefs` 0x2882c, `_Initialize` 0x27dd2
(`SetQDGlobalsRandomSeed(TickCount)`, prefs, QuickTime, Matt Slot toolkits `_PlatformOpen`/
`_FT_Open`/`_DT_Open`/`_IT_Open`, RT3, GWorlds, g init incl. g+0xc4 = 0x2a30, sound, music),
`_POSIXPathToFSSpec` 0x280f9, `_MakeRelativeAliasFile` 0x283a2 (no caller).

## 3. Out of scope (identified only)
RT3 registration layer: `__RT3_*`, `_RT3_*` (0x2b4b3..0x2f4b8), `_EncodeParameterSafe`,
`_RenewLicenseTCP/UDP`, clock-server `__Clock*`/`_Clock*`, proxy lookups `_Get*Proxy`,
`_GetSOCKSServer`, `_GetNoProxyList`, `_GetPathToSystemPreferences`, `_WriteToFileAsSuperUser`,
FUN_0002b4b3/b4d1/b4e3/b4ff/b626/b6a3/b776 (RT3 accessors) — registration/licensing.
Sparkle: `checkForUpdates:`, `updaterWillDisplay:`, SU* defaults — update check.
"Download Levels…" (tag 15): opens `http://www.ambrosiasw.com/games/aki/addons` — network.
`-[AkiQuitView …]`, `buyaki.png`, `_PleaseRegEventHandler`, demo gates on p+0x20e bit 0 — nags.
No Reggie tracker symbols exist in the 1.2 slice (`nm | grep -i reggie` empty) — it is 1.1-only.
The 18 `FUN_0003xxxx` blocks (`grep -c '^// ==== FUN_0003'` → 18) sit in the `__jump_table` import stubs (0x380c0..) — thunks.

## 4. Menu commands (tags from `MainMenu.nib`, handlers `_HandleMenuCommand` / `validateMenuItem:`)
| tag | title (key) | map | game | editor |
|---|---|---|---|---|
| 2 | New Game (⌘N) → "Give Up" in game | disabled | `abortGame` | exit editor |
| 3 | Undo Last Move (⌘Z) | — | enabled after a match if diff > 1 (g+0x1f1); runs only diff > 1 and b8 ≠ 0 | `_UndoLastLEMove` |
| 4 | Show Next Tip (⌘T) | — | not paused | — |
| 6 | Reshuffle (⌘R) | — | not paused | — |
| 7 | Pause (⌘P) | — | always | — |
| 9 | Level Statistics… (⌘L) | yes | yes (pauses) | yes |
| 10 | Open Level Editor (⌘E) / Exit Level Editor | open (random bg 13–17) | — | exit |
| 11 | Open Level File… (⌘O) | — | — | `_LoadFile(0)` |
| 12 / 13 | Save As… (⌘⇧S) / Save (⌘S) | — | — | dirty and > 0 tiles |
| 14 | Play Custom Level… (⌘⇧N) | registered | — | — |
| 15 | Download Levels… (⌘D) | out of scope | — | — |
| 16 / 17 | Clear Current Layer (⌘X) / Clear All Layers | — | — | if tiles |
| 18 | Replay Last Level → "Replay %@" | if a custom file was played | — | "Replay Last Level" |
| 19 | Try This Level | — | — | exactly 144 tiles |
Untagged: Preferences… (⌘,), Toggle Fullscreen (⌘F), Aki Handbook, Help, About, Quit.

## 5. Screen state machine [HIGH]
```
launch → (first launch: "welcome" splash) → MAP ──lantern──▶ [description] ─▶ GAME ─win/loss/give-up─▶ MAP
                                      │  Play Custom / Replay / Finder open ─▶ GAME (custom)
                                      └─ Open Level Editor ─▶ EDITOR ─Try This Level─▶ GAME (custom)
                                                                └─ Exit (Esc) ─▶ MAP
```
Flags: g+0x66 in-game-or-editor, g+0x80 editor, g+0x67 paused, g+0x68 "leave level next tick".
Transitions are 60-tick (1 s) horizontal split-slide animations drawn synchronously
(`FLOAT_00033b38` = 400, `FLOAT_00033b2c` = 60, `FLOAT_00033b30` = 65536 for the tick→float
conversion).

## 6. `_g` fields used by the rules (offsets into `_g` @ 0x34780) [HIGH unless noted]
0x4c last click tick · 0x5c/0x5e music track now/last · 0x60 open pairs · 0x62 tiles left ·
0x66 in game/editor · 0x67 paused · 0x68 end level · 0x7c cancel start · 0x7d lost · 0x7f
paused-before-external-pause · 0x80 editor · 0x81 dialog OK · 0x82 tick-sound latch · 0x84 idle
hint flash · 0x85 no-pairs flash · 0x86 pause flash · 0x87/0x88 flash phase · 0x8e background no.
· 0x90 level index · 0x94/0x98 layout pixel offset · 0xa8 timer base tick · 0xac penalty s · 0xb0
bonus s · 0xb4 elapsed s · 0xb8 remaining s · 0xbc frozen remaining · 0xc0 freeze/pause tick ·
0xc4 (initialised 0x2a30, decremented by elapsed·60 when leaving a level; never read for rules —
NOT RESOLVED purpose) · 0xcc window ref · 0xd0/0xd8 last custom file ref/name · 0x1d8/0x1e0/0x1e8
scratch x/y/layer · 0x1ec selected tile · 0x1f0 editor dirty · 0x1f1 undo enabled · 0x1f2 editor
has 144 · 0x228 saved incomplete · 0x229 custom lost · 0x22a TryAgain OK · 0x22b first-run guide.
