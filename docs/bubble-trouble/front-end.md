# Bubble Trouble X 1.1 — front-end / shell inventory (for the playable-app plan)

> Origin: Opus research 2026-10-04 (front-end inventory for the playable-app plan `docs/plans/2026-10-04-btx-playable.md`, where it is cited as **FI §n**), filed into the bank verbatim by plan task T0. Only edits: this header, the scratch-render wording in the preamble, and the ⚑ notes from the plan review (R9).

Read-only research, 2026-10-04. Anchors: `fn @ addr` = Ghidra dump `~/Developer/Ambrosia/ghidra/BTX_i386.decompiled.c`
(via `ghidra/find_func.py --func`); `disasm` = `otool -tV BTX_i386`; `bank §` = `docs/bubble-trouble/*.md`;
`rsrc TYPE id` = decoded with `docs/bubble-trouble/tools/rsrc_census.py` (+ a throwaway cicn→PNG render, not checked in, for the notice
sprites). `R/` = `…/BubbleTroubleX_1.1_UB/Bubble Trouble X.app/Contents/Resources`. Labels: [H] read directly,
[M] inferred from code shape / Carbon semantics, **UNRESOLVED** = not established. Sound slot n = `snd 9000+n`
(`_PlayMySnd @ 00026a7b` indexes `gSound[n]`, loaded 9000..9047 by `_LoadSounds @ 00026a20`) [H].

## 0. What ships in the app bundle
| item | content | anchor |
|---|---|---|
| `R/Bubble Trouble X.rsrc` | MENU/MBAR (legacy), DLOG 11, DITL 42, ALRT 28, STR#, PICT 15 (200, 900, 912, 913, 998, 999, 2910, 7000, 8001, 9012, 9030, 9031, 9077, 29401, 29402), cicn 4 (prefs area icons), CURS 8, crsr 200, Rect 1–7, SCOR 128, SPIN 1/2, DARK, snd 9047 | INDEX census [H] |
| `R/BT Levels.rsrc` | LEVL/MAZE 1–50, PICT 13000–13005 (JPEG backgrounds), ppat 912/13000–13005 (unused by levels), FILM 1–4 | bank data-formats §2,§3,§7 [H] |
| `R/BT Sprites.rsrc` | SpIL 128 → SpIc 1000 (52 sprite sets), cicn 331, btSP 325 (dead on OS X) | data-formats §4 [H] |
| `R/BT Sounds.rsrc` | snd 9000–9046 (8-bit PCM) + 11001–11004 music (ima4 stereo 22254.5 Hz) | data-census §5 [H] |
| `R/BT Titles.rsrc` | PICT 9001/9002 Letters (+highlighted), 9010 Small title, 9011 Title, 9020 High Scores, 9099 Register please, 9100 menu buttons | data-census §4 [H] |
| `R/English.lproj/main.nib` | Carbon nib: menu bar "MenuBar" (the live menu bar) | `_LoadMenuBar @ 000084d7` `SetMenuBarFromNib(nib,"MenuBar")` [H] |
| `R/English.lproj/AboutCredits1.rtf` | About-box credits (Metcalf, Wareing, Conge, Sutherland) — shown by the ASW About-box bridge bundle | file + `_HandleMenuChoice` menu 128 item 1 [H] |
| `Frameworks/` | AmbrosiaTools, ASW* (registration, Sparkle, about box) — out of scope | ls [H] |
| `extras/` | `Bubble Trouble guide/*.html` (rules; no key/pause/high-score text), `BT Level Editor.app`, `BT Editor read me.txt` ("30 frames in 1 second") | files [H] |
No music folder/files on disk: music is the 4 `snd` in BT Sounds (STR# 131 still names a legacy ":BT Music:" folder) [H].

⚑ corrected (plan review R9, 2026-10-04; re-checked with `rsrc_census.py`): `Bubble Trouble X.rsrc` holds **cicn 128, 1000, 1001, 1002** (the prefs area icons + 128) and **snd 9047**; `BT Sprites.rsrc` holds cicn 25000..31723 and `BT Sounds.rsrc` snd 9000..9046 + 11001..11004. A loader for sprites or sounds must therefore search all five `.rsrc` files, not only the sprite/sound file. The `SpIc 1000` set-count field is stored **n − 1** (it reads 51 for the 52 sets).

## 1. Startup → front end
### 1a. Launch sequence (`_main @ 00005586` → oapp AE → `_InitMac @ 0000563c` → `_Interface @ 0000b500`)
| step | detail | anchor |
|---|---|---|
| menu bar | nib "MenuBar" loaded before the event loop; Key Sets submenu (id 140) built at run time | `_main`, `_LoadMenuBar` [H] |
| prefs | `_InitPrefs`, `_AlexPrefsInit` (defaults), `_LoadDefaultHiScores` (SCOR 128), `_LoadGamePrefs` | `_InitMac` [H] |
| birthday check | DLOG 3000 (David Wareing) / 3001 (Alex Metcalf) on their birthdays | `_DoBirthdaysCheck`, DITL 3000/3001 [H]; dates **UNRESOLVED** |
| window | `CreateNewWindow(kDocumentWindowClass 6, attrs 0x2800000, 0,0,640,480)`, title "Bubble Trouble X", `RepositionWindow(…,1)` (centre on main screen) | `_CreateGameWindow @ 00010144` [H]; attr bits meaning [M] |
| full screen at launch | if bool pref 0x37 → `_GoFullScreenMode`, else windowed | `_PrepareMonitor @ 0000ffd8` [H] |
| splash 1 | black, then `PICT 200` (Large Ambrosia logo, 300×341, opaque — alpha plane all 0) centred; held until 130 ticks (0x82) after drawing; fade in/out 0.1 s / 0.6 s via CGDisplayFade (full screen only); windowed: `_WipeScreenOut(4)` / `_WipeScreen(4)` | `_InitMac` [H] |
| splash 2 | `PICT 9011` "Title" (640×480) centred, then progress bar | `_InitMac` `_DrawAndCentrePict(0x2333)` [H] |
| progress bar | rect L250 T445 R390 B451 (6 px tall, 140 wide) with 2-px border (`gPBorderCol1/2`), filled `gPInside1`, grown with `gPInside2` per `_UpdateProgress` (steps: 1 + sprites + orbit + 48 sounds); colours **UNRESOLVED** (globals not read) | `_InitProgressBar @ 00006f83`, `_UpdateProgress @ 000071c5`, `_LoadSounds` [H] |
| intro sound | `snd 9027` "Bubbles" played at splash 2, at SFX volume; splash 2 stays ≥ 60 ticks | `_PlayIntroSound @ 00026986` (0x2343), `_InitMac` tail [H] |
| main menu | `_Interface`: menu stars reset, session latches `_Get0To6/_Get13To22`, title music loaded (`_LoadMusic(0)`), `_DrawMainMenu`, `_CheckNumRecordings`, crsr 200, `_WipeScreen(6)` reveal, music starts if registered | `_Interface` [H] |

### 1b. Main menu screen (`_DrawMainMenu @ 00009eb3`)
- Background: `PICT 913` (app rsrc, 640×480) centred into comp (`_PatternFillCompGWorld(0x391)`) [H]. `PICT 9010` "Small title" is loaded into `gTitlePict` but never drawn (no draw site) [H — grep].
- Credit line: `PICT 9012` "By Alex Metcalf & David Wareing" at T187 L229 B201 R411 [H].
- Buttons: source `PICT 9100` (300×300) drawn into bgnd; normal state at source x 0, highlighted at x +150 (`_FlashButton` `OffsetRect(+0x96)`) [H]. Copied transparently to the Rect-resource destinations. **Rect resources are Left,Top,Right,Bottom** (`TMPL 128`, `_GetRectRsrc @ 0000c9e9`) — note: bank data-formats §7 reads Rect 1 as top,left,… which is wrong [H]:

| # | button | src rect (L,T,R,B) in 9100 | dest rect (L,T,R,B) | key(s) |
|---|---|---|---|---|
| 1 | New Game | 0,0,150,34 | 165,228,315,262 | N, Return, Enter |
| 2 | Demo | 0,34,71,68 | 165,276,236,310 | D |
| 3 | Scores | 0,68,101,102 | 165,324,266,358 | S (option-click → reset dialog) |
| 4 | Prefs | 0,102,80,136 | 394,228,474,262 | P |
| 5 | Credits | 0,136,104,170 | 373,276,477,310 | C (+ modifier = secret pages) |
| 6 | Quit | 0,170,67,204 | 409,324,476,358 | Q |
| 7 | Register | 0,204,123,238 | 259,372,382,406 — drawn only if unregistered | R (unregistered only) |
Hidden keys: L = level select; B → snd 47 "Squeak squeak", W → snd 46 "Non the dog"; X → "Scribblings" (DLOG 290 = PICT 8001), Z → "Musings" (DLOG 291 = PICT 2910). Keys with ⌘ held are ignored here (event modifiers bit) [H] (`_Interface` switch).
- Click handling: button highlights while pressed, acts on release inside (classic tracking); click snd 17 "Bloop" [H] `_HandleMSMouse @ 0000b001`.
- Modifier-click on the logo rect `gLogoR` (L171 T25 R469 B173, inset 5) → credits; option-click the info box → random easter-egg message (msg 3..33) + snd 0 [H].
- Info text box `gTextRect` L157 T425 R482 B445: 50 % darkened box, border RGB (0xffff,0x9999,0), Geneva 9 centred, colour index 0x111 (cyan) or 0x45 (yellow, nag); cycles every 180 ticks through msgs 0..3 then redraws: 0 "Copyright 1995-2008 Alex Metcalf/David Wareing & Ambrosia", 1 "Version 1.1.0", 2 "Registered To: <name> [n copy/copies]" (or unregistered nag), 3 occasion/thanks text [H] (`_DrawInterfaceText @ 0000898d`, `_InitLetterRects`… SetRect at dump line 20390). Messages 4..33 (easter eggs/quotes) full list **UNRESOLVED** (strings partly inline).
- Mouse-trail stars: when the mouse moves (≥2 ticks apart) a 26×26 star (sprite set 0x28) spawns at mouse −13 ± 10 px, 30 slots, animates frames 1..6 one per >3 ticks [H] `_ProcessMenuStars @ 0001075d`.
- Idle attract: see §2.

### 1c. Menu bar (live = nib; legacy MENU/MBAR 128–131 not used on OS X) [H nib + `_HandleMenuChoice @ 0000a482`]
| menu (id) | items (key equiv.) | action |
|---|---|---|
| Bubble Trouble X (128) | About Bubble Trouble X; Register Bubble Trouble X…; — ; Check for Updates…; — ; Preferences… (⌘,) ; + standard Hide/Quit (⌘Q) supplied by Carbon | 1 About bridge; 2 ASW registration; 4 Sparkle; 6 → `_PrefsButton` |
| Edit (130) | Undo ⌘Z, Redo ⇧⌘Z ("Z"), Cut ⌘X, Copy ⌘C, Paste ⌘V, Delete, Select All ⌘A, Special Characters… | standard (dialog text fields) |
| Options (131) | Full Screen ⌘F (checkmark = bool 0x37); — ; Sound Effects "A" (likely ⇧⌘A [M]) ✓; Music ⌘M ✓; — ; Key Sets ▸ (submenu 140: "Default", then the user sets 2..n after a separator; ✓ = short 0x38) | toggles prefs, saves prefs |
| Window | Minimize ⌘M, Minimize All ⌥⌘M, Zoom, Bring All to Front, Arrange in Front | standard |
- Sound Effects toggle: on→off stores short 0x33=1; off→on restores short 0x34. Music likewise 0x35/0x36 [H].
- Quit: menu 129 item 1 handler (`gFinished`, save prefs) is legacy; the nib quit goes via the quit AE (`_QuitAppleEventHandler`) [M]. ⌘M collision (Music vs Minimize) — which wins **UNRESOLVED**.
- During play: About, Preferences, Full Screen commands disabled; re-enabled while paused [H] (`_RequestGame`, `_PlayGame` Disable/EnableMenuCommand 'abou','pref','Full'; `_PauseGame`).
- `_HideGameMenuBar` / `_ShowGameMenuBar` are empty stubs on this build [H] — the menu bar is never hidden explicitly; in full screen it is covered by the captured-display shield level [M].

### 1d. Dialogs (DLOG/DITL, `Bubble Trouble X.rsrc`) [H texts]
| DLOG | size | items | used by |
|---|---|---|---|
| 160 Level Select | 350×104 | "Go go go!", Cancel, "Start at which level (2 - ^0)? High Scores will be disabled.", edit (default "2"), PICT 999 | `_DoLevelSelect @ 0000d31e` (L key) |
| 190 Preferences… | 450×350 | Save, Cancel, Defaults, Revert; area tabs Sound / Keys / Misc (cicn 1000 Sound, 1001 Keys, 1002 Game); header PICT 7000; help text line (STR# 132–135) | `_PrefsDialog @ 0000ea93` |
| DITL 191 sound area | SFX popup (MENU 1001 Off/Quiet/Medium/Full), Music popup (MENU 1000), chk "Title screen music" | |
| DITL 192 keys area | 5 key edit fields (Left/Right/Up/Down/Push), "New Set...", "Delete Set", Key Sets popup (MENU 1009) | |
| DITL 193 game area | chk Full screen mode / Show Bubbles / Show Stars / Hold Escape to exit | |
| 200 Key set name | 285×129 | Create, Cancel, edit default "Sheryn", PICT 998; ALRT 201 (<10 chars), 202 (≤20 sets) | |
| 1000 High Score Name | 329×91 | "OK!", name edit, "You made it into the High Scores! Please enter your name:", PICT 999 | `_CheckHiScore` |
| 1001 High Score Erase | 300×104 | Reset, Cancel, "Are you sure you want to reset the High Scores?" | option-click Scores |
| 1002 High Score Null / 1003 "That's enough levels" | unregistered only (skip) | | |
| 290 Scribblings (PICT 8001) / 291 Musings (PICT 2910) | X / Z keys | `_DisplayPoem`, `_DisplayQuote` |
| ALRT 203/204/205 | "changes won't take effect…/re-open…/factory settings" | prefs |
Dialogs are raised into a window group at `CGShieldingWindowLevel` in full screen, `kCGFloatingWindowLevelKey(4)`-level windowed [H] (`_CheckHiScore`). About box and registration are ASW framework bundles (out of scope).

⚑ (R9) The prefs area icons cicn 1000/1001/1002 are in `Bubble Trouble X.rsrc` (see the §0 note).

### 1e. Window, depth, full screen [H unless marked]
- Logical screen 640×480 (`environment+0x12`), window content 640×480, offscreen GWorlds comp/bgnd/sprite (depth 0 = screen depth), score 640×40, trans 32-bit (`_Create*GWorld`). On OS X `_IsDoubleBuffered()` = true → frame drawn straight to the window port then `QDFlushPortBuffer` [H].
- Full screen (`_GoFullScreenMode @ 0000fb21`): keep current bits-per-pixel, `CGDisplayBestModeForParameters(640,480)`, `CGCaptureAllDisplays`, switch mode, window at shielding level, fade 0.4 s out/in; strips ⌘H/⌥⌘H key equivs. Window mode restores saved mode/bounds (`_GoWindowMode @ 0000fde1`). Default = windowed (bool 0x37 = 0).
- Colour: no palette work on OS X; backgrounds are 32-bit/JPEG PICTs; sprites are indexed cicns with their own value-indexed CLUTs (data-formats §4 ⚑) → render as true colour [H/M].
- Cursor: `crsr 200` (hand) in menus/dialogs; hidden in play, mouse dissociated (`CGAssociateMouseAndMouseCursorPosition(0)`) and warped to screen centre, restored on exit/pause [H] (`_PlayGame` start/end, `_PauseGame`).
- App deactivation: menu → `_SuspendGame` (pause music); in play → pause (§3g); in demo → suspend + end demo [H].

## 2. Attract / demo mode
| fact | detail | anchor |
|---|---|---|
| trigger | menu idle 1200 ticks (20 s) with no click/key → alternately Demo, Scores, Demo, … (first = Demo); timer reset by any input/return | `_Interface` (`0x4b0`, `bVar2` toggle) [H] |
| D key / Demo button | same `_DemoButton` | [H] |
| film order | `FILM id = gFilmCounter+1`; counter advances mod `gNumFilmsAvailable` (=4, counted at menu entry) → 1,2,3,4,1… shared by idle and D | `_DemoButton @ 0000af71`, `_PlayGame` [H]; initial counter 0 [M] |
| level/seed | level = film id (1..4); `SetQDGlobalsRandomSeed(FILM.seed)`; lives 3, score 0, mult 1, EXTRA clear | bank replay-oracle §3 [H] |
| demo look | cursor stays visible/not warped; music never plays (`_StartMusic` returns if demo); no "Get Ready!"/hero-start "Hahohaho" sounds, no end-of-level sound; notice at level start = **"GAME OVER"** (notice 4, sprite set 0xc) and it stays up all demo (hero-appear `PrepareNotice(0)` skipped in demo); hero appear still plays snd 27 | `_NewLevel` (`gGameMode==1 → 4`), `_PlayGame` [H]; sprite content from cicn 26508–26510 render [H] |
| pause | pause key ignored in demo | `_PlayGame` [H] |
| end conditions | samples exhausted (`FILM.count <= counter`), hero death anim done (state-4 timeout), level complete +70 frames, any key-down / mouse-down / app activate event (kind 1), app deactivate (suspend + end) | `_PlayGame` wait loop [H] |
| after demo | no high-score check; `_DrawMainMenu` + `_WipeScreen(12)`; menu stars reset | `_RequestGame`, `_DemoButton` [H] |
| known | FILMs 2–4 predate X 1.1 and probably die early in the original too (D8, NR-10) | DECISIONS D8 |

## 3. Play loop beyond the core
### 3a. New game
- New Game / N / Return / Enter: snd 36 "AllRightyThen!", stop+unload title music, `_RequestGame(1,0)` [H] `_NewGameButton`.
- Level select (L): start level 2..`short 0x3a` (default 10; `_LoadLevel` raises it to any level reached while < 31 → max offer 30; unregistered forced 8); out-of-range → SysBeep; any start level > 1 sets `gPlayerIsCheating` → **no high score** [H] (`_DoLevelSelect`, `_RequestGame`, `_LoadLevel`).
- `_PlayGame`: frame timer installed, seed = TickCount (play), `SetLevel(start−1)`, lives 3 (`_ResetHeroLives`), score 0 + next extra life 10000 (`_ResetScore`), mult 1, EXTRA cleared, `_NewLevel` [H].

### 3b. Level start (`_NewLevel @ 0001735f`) [H]
`gIsEndOfLevel=0; frame=0; NextLevel; LoadLevel; …inits…; DrawMaze` (background PICT into bgnd+comp, darken score bar, maze bubbles) → `_WipeScreen(12)` reveal → score bar drawn (reserve hero, score, time bonus, multiplier, EXTRA) → notice "LEVEL n" (6; demo: "GAME OVER") → `_LoadMusic(1)` (not demo) → snd 2 "Get Ready!" (not demo). Hero appears after 70 frames (60 on respawn): maze cell cleared, notice cleared (not demo), reserve-hero icon redrawn, `_StartMusic`, star group 0, snd 8 "Hahohaho" (not demo) + snd 27 "Bubbles" [H] `_PlayGame` state 1.
`_LoadLevel` calls `_SaveGamePrefs` every level (prefs + high scores hit disk here) [H].

### 3c. Level complete
| step | detail | anchor |
|---|---|---|
| trigger | all enemies squished (`_AreAllEnemiesSquished`), hero state 1/2; or all normal bubbles gone (snd 33 + 2000×mult + stars + popup, `_FinishLevel` marks all squished) | `_PlayGame` [H] |
| | snd 35 "End of Level" (not demo); play continues 70 more frames (`gEndOfLevelTime+0x46 < frame`, needs lives>0, state 1/2) | [H] |
| then | EXTRA reset if its completion anim is running; `_StopMusic` (blocking fade: volume −5 per tick from 0x40/0x80/0x100) | `_StopMusic @ 0001afac` [H] |
| `_TimeBonus_CountDown @ 00006dcb` | if mult>1: multiplier flashes 3× (8-tick waits, snd 32 each), bonus ×= mult (cap 99950), snd 9, bonus digits flash (set 0x22), wait 60 ticks; then snd 42 "Oh No" if bonus 0, snd 41 "Oh My" if ≥10000; transfer in chunks 500/200/100/50 (≥50000/≥10000/≥5000/else) to score (no re-multiply), 3 ticks per chunk, snd 17 every 3rd chunk; final wait 15 ticks. Uses TickCount waits (blocking, outside the frame timer) | [H] |
| then | snd 27 "Bubbles"; unload music; (unregistered & level>7 → nag + end — skipped, registered) → `_NewLevel` (n+1) | [H] |

### 3d. Death / lives / respawn / game over [H] (`_PlayGame`, bank hero-and-input §5)
- Catch → state 3 ("Erk!" speech bubble, sprite set 0x10, frame 1 = left-facing default / 2 when facing right; placed at hero x−37 / y−30 clamped to 0..595 / 0..391) → after 30 frames: state 4, lose a life, enemies vanish, music stops (no fade), snd 34 "Death Groan", reserve-hero icon animates (set 8, 12 frames counted down, 2 cycles).
- After 65 frames: respawn (state 1) at `_ResetHeroPosition`, multiplier → 1; if lives ≥ 1 and not end-of-level: snd 2 "Get Ready!" + notice "GET READY!" (1); if lives < 1: notice **"FIN!"** (2, sprite set 0xb) + snd 3 "Game Over!", and the game ends 95 frames later.
- Extra lives: 10000, 40000, then +40000 (`_AddToScore`); +1 on EXTRA; cap 9; `_AddHero` plays snd 13 twice [H].
- Lives display: frame `max(lives,1)` of set 0x21, and frame k = digit k−1 (per `_DrawScore`), so it shows **lives − 1** (spare lives): 3 lives → "2", last life → "0" [H `_DrawReserveHeroNumber`].

### 3e. Game end → high score
- Exit path: menu re-enabled, cursor restored, music unloaded, `ST_HaltSound`, snd 27 [H] `_PlayGame` exit.
- `_CheckHiScore @ 00024b34` (only start level 1, not cheating, not demo; runs for Esc-quit games too): qualifies if score > entry #7. Screen overlaid with system pattern 4 (`GetIndPattern(0,4)`, patOr) [H; visual **UNRESOLVED**]. Table 7 entries; shift down, insert score + level reached; DLOG 1000 (snd 13), default text = last name entered (SCOR slot 0); name max ~10 chars (beep when ≥10 and no selection); typing click snd 1 (arrows/backspace snd 6); OK snd 15. Empty name → "Maniac"/"Swoop" by `GetRandomFast(0,1)`; ~13 typed names (Wareing, Metcalf, Luke, Han, Darth, Homer, Bart, Steve, Apple, Dog, Ben…) are replaced by joke names (Swoop, Maniac, Skywalker, Solo, Vader, Simpson, Doh, Woz, Moof, Boogle…) with snd 13/46 — exact pairs **UNRESOLVED** (compare chain not fully transcribed); custom-levels games append "^" (drawn as PICT 9077 badge). Then high-score screen (snd 19) [H].
- High-score screen `_DisplayHiScores @ 00025733`: bgnd PICT 912 centred; PICT 9020 "High Scores" at L209 T80 R431 B117; headers "Name" x116, "Score" x337, "Level" x451 at y145 in the Letters font (PICT 9001); rows y 188 + 35·i, name x116, score right-ish at x340, level x472; new entry flashes 6× (5-tick halves); `_WipeScreen(12)` reveal; stays 600 ticks (10 s) or until key/click (snd 17); **N** starts a new game; ⌘Q quits [H].
- Storage: in-memory table saved inside the prefs file (0x8a block after 0x800 prefs; layout bank data-formats §8–§9); defaults SCOR 128 ("The Fonz", Potsie 4500 L4 …); option-click Scores → DLOG 1001 → reload defaults [H].

### 3f. After the last level
`NextLevel` keeps counting; `_LoadLevel`: level ≥ 51 → random LEVL 21..50 (`GetRandomFast(0x15,0x32)`); level ≥ 100 → counter set to 99. So play is endless, level number shows 51…99 then sticks at 99 [H] `_LoadLevel @ 00002ef7`. No ending screen exists [M — no other path].

### 3g. Pause (`_PauseGame @ 0001767b`) [H]
- Key: **Caps Lock** (`_PauseKey` = `GameKeyDown(0x39)`; GetKeys reports the lock *state*) — the game stays paused while Caps Lock is engaged and resumes when it is released/unlocked [H code; "lock state" semantics M]. App deactivation also pauses (resume on reactivation unless Caps Lock on).
- Shown: notice "PAUSED" (set 0xa, 2×64 px at x265 y221) + PICT 9030 "Pause 1" (L155 T279 R485 B295) + PICT 9031 "Pause 2" (L190 T299 R450 B315) [H]; their text **UNRESOLVED** (masked QT PICTs not rendered here).
- On entry: all sound halted, music paused, snd 22 "Stretch Bounce", cursor shown/re-associated, Prefs + Full Screen enabled; on exit music resumes, previous notice restored, cursor hidden & recentred.
- Not available in demo.
### 3h. Cheats (typed while paused; hash of last 5 chars `(c0+410)(c1+106)(c2+333)+3+(c3+280)(c4+560)`; buffer starts "OOGLE") [H]
Hash → effect: 0x227742c FPS display; 0x20ec7c5 score reset; 0x22a51cf daddy mode (15 fps); 0x211e290 star burst (orbit stars); 0x249007e toggle frame limit; 0x242795e play all 48 sounds; 0x20df815 3 squishes (no effect); 0x224fc15 regenerate bubbles; 0x21d95f1 end level; 0x21dd0a7 ghost icons; 0x22badb8 3 squeaks; 0x252bb8b +1 life; 0x21ba771 +9000; 0x23ba91e invisibility; 0x20a59aa capture all; 0x26e29e4/0x26e4547/0x26e3f83/0x26e3ca1/0x26e2420 EXTRA E/X/T/R/A; 0x232858f/0x23286f2/0x2328855/0x23289b8 multiplier 2/3/4/5. All set `gHacked`; most set `gPlayerIsCheating` (no high score). Plain-text codes **UNRESOLVED** (hash only; MENU 1020 "Cheats" names are a joke list, unused).
### 3i. Orbit stars, air bubbles, stars
Orbit stars only from the star-burst cheat; invisible on Intel (SPIN 1 read unswapped) — replica draws nothing [H bank data-formats §5]. Air bubbles = bool 0x36 "Show Bubbles", stars = bool 0x35 "Show Stars", both default ON and RNG-relevant [H bank replay-oracle §4.1].

## 4. Input
| key | context | action | anchor |
|---|---|---|---|
| key set 1 "Default" ← → ↑ ↓ Space | play | left/right/up/down/push (levels via `GetKeys`, sampled once per `_CheckHeroMovement`) | `_AlexPrefsKeysInit @ 0000f790`, `_InitControls` [H] |
| key sets 2–8 (left,right,up,down,push; Mac virtual codes) | | 2 "Keypad 1" kp4,kp6,kp8,kp2,Space · 3 "Keypad 2" kp4,kp6,kp8,kp5,Space · 4 "Keypad 3" kp4,kp6,kp8,kp2,kp0 · 5 "Keypad 4" kp4,kp6,kp8,kp5,kp0 · 6 "Keyboard" J,L,I,K,Space · 7 "Classic" Z,X,',/,Space · 8 "Spectrum" Q,W,E,R,T | same [H] (codes 0x56/58/5b/54/57/52, 0x26/25/22/28, 6/7/0x27/0x2c, 0xc/d/e/f/0x11) |
| user key sets | ≤ 20 sets, names < 10 chars, made in prefs | ALRT 201/202 [H] |
| Caps Lock | play | pause (state) | §3g |
| Esc | play/demo | end game immediately; if bool 0x3d "Hold Escape to exit": must be held > 30 frames | `_PlayGame` [H] |
| ⌘Q | play | quit app immediately (`_CleanUp`, no prefs save) | `_PlayGame` `GameKeyDown(0xc)`+⌘ [H] |
| ⌘Q / menu Quit | menus | quit (prefs saved) | `_main`, `_HandleMenuChoice` [H] |
| N/Return/Enter, D, S, P, C, Q, L, (R), B, W, X, Z | main menu | §1b | `_Interface` [H] |
| N | scores/credits screens | start new game; any other key/click returns | `_DisplayHiScores`, `_DisplayCredits` [H] |
| Credits + ctrl / option / ⌘ / shift (key C or button) | menu | secret credit pages 14–22 / 23–26 / 27–29 / 30–33 (+ snd 38/40/44/39); normal pages 0–13, 240 ticks each | `_CreditsButton`, `_DisplayCredits @ 0002145a` [H] |
| Option-click Scores | menu | reset high scores dialog | `_HandleMSMouse` [H] |
- Key repeat: gameplay keys are polled levels (held = pressed every sample; no OS repeat). Menu keys come from keyDown *and* autoKey events (kinds 3 and 5 both handled) [H].
- Movement priority Up>Down>Left>Right when aligned; reversal mid-cell (bank hero-and-input §2–§3) [H].
- Mouse: unused in play (cursor hidden); mouse-down ends a demo; menus/dialogs use it [H].
- InputSprockets: bool 0x41, stubs on OS X (`_TurnISpOn` etc. empty) [H].

## 5. Timing
| fact | anchor |
|---|---|
| Frame step paced by a Carbon event-loop timer, interval 0.033 s → nominal 30.3 fps; loop spins `ReceiveNextEvent` (0.001 s timeouts) until `gTimerFired` | bank engine-loop §2; `_PlayGame` [H] |
| No frame skipping: one sim step + one draw per timer tick; if a frame overruns, the next waits for the next timer fire (timer fires are a flag, not a count → missed fires are dropped, game slows) | `_PlayGame` [H code, M consequence] |
| Daddy mode (cheat) 15 fps, frame-limit cheat = unthrottled — non-OS X TickCount paths; on OS X the limit flag skips the wait | [H] |
| All in-game times are frames (u16 counter, reset per level); menu/front-end timings are TickCount (1/60 s): idle 1200, info msg 180, scores 600, credits page 240, splash 130/60, countdown 3 per chunk | §1–§3 [H] |
| `_WipeScreen(step)`: reveals comp→screen as two bands (top moving down, bottom moving up) by `step` rows per tick until 240+2·step rows → ~20 ticks at step 12 | `_WipeScreen @ 000076d3` [H] |
| Delivered fps on real hardware — NR-11 **UNRESOLVED** | INDEX |

## 6. Rendering
### 6a. Layout (640×480) [H]
- Playfield 640×440 at (0,0), 16×11 cells of 40 px; level background = PICT LEVL.w1 centred (912 → `Bubble Trouble X.rsrc`; 13000–13005 → BT Levels). Background/music by level: 1–3 912/m1 · 4–6 13001/m2 · 7–9 13004/m3 · 10–11 13000/m4 · 12 13002/m4 · 13–14 13002/m1 · 15 13003/m1 · 16–17 13003/m2 · 18 13005/m2 · 19–20 13005/m3 · 21 912/m3 · 22–23 912/m4 · 24 13001/m4 · 25–26 13001/m1 · 27 13004/m1 · 28–29 13004/m2 · 30 13000/m2 · 31–32 13000/m3 · 33 13002/m3 · 34–35 13002/m4 · 36 13003/m4 · 37–38 13003/m1 · 39 13005/m1 · 40–41 13005/m2 · 42 912/m2 · 43–44 912/m3 · 45 13001/m3 · 46–47 13001/m4 · 48–49 13004/m4 · 50 13004/m1 (LEVL w1/w2 dump).
- Score bar y 440–480: the background's bottom 40 px blended 50 % toward black (`OpColor 0x7fff`, `PenMode blend`) + 2-px green (QuickDraw `greenColor` 341) line at y 440; cached in the score GWorld (`_PrepareScoreBar @ 00025c65`).

| HUD item | sprite set (cicn ids) | position | anchor |
|---|---|---|---|
| reserve-hero icon | 8 (26000–26011, 32×32, Blinky turning) | x16 y445 | `_DrawReserveHeroImage` |
| lives digit | 0x21 (30000–30009, 22×30; frame k = digit k−1) | x55 y446 | `_DrawReserveHeroNumber` |
| score | 0x21, up to 8 digits, no leading zeros, 24 px pitch | from x132, y446 | `_DrawScore @ 00028168` |
| EXTRA | 0x24 lit / 0x25 unlit (30700/30750, 22×32), frames 1–5 = E,X,T,R,A | x 322,338,359,381,403, y446 | `_EXTRA_Draw` |
| time bonus | 0x21 normal / 0x22 flashing (30500–30509); 5 digits, leading zeros blank (last kept), 23 px pitch, shifted +22 when < 10000 | from x480, y446 | `_TimeBonus_Draw @ 00006b3a` |
| multiplier | 0x23 (30600–30603 = x2..x5, 28×28), hidden at 1x | x601 y448 | `_Multiplier_Draw` |
| notices | 1 GET READY! set 9 (3×64×38) x236 · 2 FIN! set 0xb (2×64×64) x256 · 3 PAUSED set 0xa x265 + PICT 9030/9031 · 4 GAME OVER set 0xc x234 · 5 HURRY UP! set 0xd x234 · 6 LEVEL set 0xe (x254, or x241 when ≥10) + digits set 0xf (26700–26709, 27×35) at x358 / x345+x372; all at y221 (= (480−38)/2) | `_ResetNotices`, `_DrawNotice @ 00027948` |
| FPS (cheat) | text "FPS: n", red if < 30 | bottom-right | `_DrawFPS` |
### 6b. Per-frame draw order (`_PlayGame`) [H]
RestoreBgnd (dirty rects) → hurt blocks → hero → enemies → balloons → blocks → splats → bonus bubbles → stars → "Erk!" → score popups → air bubbles → score → time bonus → reserve info → notice → (flush). Maze bubbles live in the comp/bgnd image drawn by `_DrawMaze`; moving/animating ones are blocks. Notice erase is queued before processing (`_EraseNotice`).
### 6c. Sprite sets (SpIc 1000; frame f of set s = cicn `start[s]+f−1`, data-formats §4) — sets added here [H, cicn render]
⚑ (R9) The `SpIc 1000` count field is stored n − 1 (reads 51 for 52 sets; sets s = 1…52 address entry s − 1, data-formats §4).
8 reserve hero (26000,12) · 9 GET READY (26500,3) · 0xa PAUSED (26503,2) · 0xb FIN! (26505,2) · 0xc GAME OVER (26508,3) · 0xd HURRY UP (26511,3) · 0xe LEVEL (26600,2) · 0xf big digits (26700,10) · 0x10 "Erk!" bubble (26900,2; named "Erk! Left/Right") · 0x20 (28900,4: piranha/eel/shark/starfish icons) — caller **UNRESOLVED** (only dead `_DrawNumEnemies` candidates). Others (hero 1–7, maze 0x11–0x17, pop 0x18, bonus 0x19/0x1a, enemies 0x1b–0x1f, digits 0x21–0x25, splats 0x26/27, stars 0x28–0x2c, air bubbles 0x2d–0x30, balloons 0x31–0x33, popups 0x34): bank data-formats §4.
### 6d. Fonts
- Letters font: PICT 9001 "Letters" / 9002 highlighted (546×46 strip) cut by `_InitLetterRects` (glyph rects in code), drawn by `_DrawCustomString` — used for the high-score table [H]; glyph table **UNRESOLVED** (not transcribed).
- System fonts: Geneva 9 (info box), Chicago 12 (`_SetChicagoTwelve`, use **UNRESOLVED**) [H].

## 7. Sound & music
- Engine: AmbrosiaTools Sound Tool, 4 channels (`ST_Open(4,0)`), `ST_PlaySound(snd, priority, volume)`; priorities used 10/20/30; channel-stealing rules **UNRESOLVED** (external framework). Delayed sounds: 5-slot queue, `delay` frames ahead, flushed each frame [H] `_PlayMySnd`, `_Sounds_CheckDelayedSounds`.
- SFX volume (short 0x33): 1 off, 2 → 0x10, 3 (default) → 0x40, 4 → 0x100 [H].

| slot (snd) | name | played by |
|---|---|---|
| 0 (9000) | Squish | enemy squish, egg kill, ballooned-enemy pop, hero squashed (kind 2), cheat confirm, info-box egg |
| 1 | Click | high-score name typing |
| 2 | Get Ready! | level start (play), respawn |
| 3 | Game Over! | lives exhausted; score-reset cheat |
| 4 | Bop | regenerate / invisibility bonus |
| 5 | Push - Successful | `_PushBlock` (disasm 0001be28) |
| 6 | Pop | bubble pop (`_CrushBlock`), egg, bonus bubble pop/leaves screen; name-field edit keys |
| 7 | Push - Failed | thud (`_HeroPushCrushCheck`) |
| 8 | Hahohaho | hero appears (not demo) |
| 9 | Minor Jewel Join | jewel join; countdown multiplier apply |
| 10 / 37 | Oooer / Ayeeee | caught by enemy (random) |
| 11 / 45 | Zoiks / Yeow | squashed/blasted (random, +5 frames) |
| 13 | Extra Life | `_AddHero` (×2), high-score dialog, registration thanks |
| 14 | Balloon Launch | shark fires |
| 15 | Enemy Ballooned | captures; high-score OK |
| 16 | Enemy Hatch | `_Balloons_PopBalloon`; one `_ProcessBlocks` site (egg hatch [M]) |
| 17 | Bloop | UI click, countdown tick (every 3rd chunk) |
| 18 | Boing! | high-score reset |
| 19 | Harp | bonus bubble launch (+5); hi-score screen; credits |
| 20 | Bounce | block bounces (`_MoveBlock`, `_ProcessBlocks`) |
| 21 | Bonus Timer Warning | each −50 step while bonus < 500 |
| 22 | Stretch Bounce | pause; prefs/level-select open |
| 23 / 30 | No Bonus Points / Hurry Up! | time bonus hits 0 (+ notice 5 "HURRY UP!", jewels revert; `_TimeBonus_Process`) |
| 24 / 25 | Ignite / Dull Explosion | dynamite lit / explodes |
| 26 | Get Bonus | bonus pop, time reward |
| 27 | Bubbles | intro, hero appears, level end, game end; air-bubble group 8 (priority 1) and the hero-death group 0xb (priority 10) — `_Bubbles_NewGroup` tail [H, C2] |
| 28 | Short Bubbles | air-bubble groups 4, 5, 6, 9, 10 (priority 1; `_Bubbles_NewGroup` tail `jmp` 000166bc) |
| 29 | More Bubbles | air-bubble group 7 (priority 1; args at 0001676a) [H, C2] |
| 31 | Invisibility Bonus | EXTRA-letter / regen / invisibility rewards |
| 32 | Bonus Multiplier Flash | multiplier change/flash |
| 33 | All Jewels Joined | jewel bonus; all bubbles cleared |
| 34 | Hero Death Groan | state 3→4 |
| 35 | End of Level | all enemies squished |
| 36 | AllRightyThen! | new game / level-select go |
| 38 | Eat Seaweed… | 3rd squish of a multi-squish (+15 frames); credits |
| 39/40/44 | Heyahoo / Hooley Dooleys / Shazam | credits pages; 39 also hero trapped in a balloon (+5) and high-score reset; 40 = 5000/10000 time reward; 44 = (dead) multiplier reward |
| 41 / 42 | Oh My / Oh No | countdown ≥10000 / 0 |
| 43 | Oooch | blast catches hero (+5) |
| 46 / 47 | Non the dog / Squeak squeak | W / B on menu |
(12 Warble: no `_PlayMySnd` site found except the 48-sound cheat → likely unused [M]. 29 More Bubbles IS used — C2 correction 2026-10-04: the tail-jump args of `_Bubbles_NewGroup` were not visible in the decompile. Also C2: "Bounce" 20 is not played on a right-moving blue/purple block's step-4 reversal (`_MoveBlock` 0001d221 skips the shared call at 0001cfeb).)
- Music [H]: one `snd` per set, named "Level set N music.1" (11001–11004, ima4 stereo); level music = LEVL w2; **title music = "Level set 3 music"**. `_StartMusic` queues the segment 50× on one channel (effective loop ≈ 50 plays) [H `_StartMusic` loop to 0x33]. Starts: title (after load if registered; re-started whenever not playing on the menu), hero appearance each life. Stops: death (no fade), level end (fade), new game (fade), pause (pause/resume). Never in demo. Volume (short 0x35): 1 off, 2 → 0x40, 3 → 0x80, 4 (default) → 0x100; title-screen volume 0 unless bool 0x40 "Title screen music" (default ON).

## 8. Preferences (file "Bubble Trouble X Prefs", Preferences folder, data fork: version 0x17, 100 bool / 100 short / 100 long / 20 key sets / legacy scores, + 0x8a high-score block — bank data-formats §9) [H]
| pref | meaning | default | UI |
|---|---|---|---|
| short 0x33 / 0x34 | SFX volume 1–4 / last non-off | 3 / 3 | prefs popup, Options ▸ Sound Effects |
| short 0x35 / 0x36 | music volume 1–4 / last non-off | 4 / 4 | prefs popup, Options ▸ Music |
| bool 0x40 | title-screen music | 1 | prefs checkbox |
| bool 0x37 | full screen | 0 | prefs, Options ▸ Full Screen ⌘F |
| bool 0x35 | show stars | 1 | prefs |
| bool 0x36 | show (air) bubbles | 1 | prefs |
| bool 0x3d | hold Esc > 30 frames to exit | 0 | prefs |
| short 0x37 / 0x38 | key-set count / current set | 8 / 1 | prefs keys area, Options ▸ Key Sets |
| key sets 1–20 | name + 5 virtual key codes | §4 | prefs keys area |
| short 0x3a | highest level offered by level select | 10 | automatic |
| short 0x39 | sprite plotting (QuickDraw/QuickerDraw; forced QD on OS X) | 2 | "OS 9 Drawing" popup (CNTL 1003), OS 9 only |
| bool 0x3f | QuickerDraw-related, = !OSX | 0 on OS X | — |
| bool 0x41 | InputSprockets | 0 | — |
| bools 0x33,0x34,0x38,0x39,0x3a,0x3b,0x3c,0x3e | bookkeeping / unused here (0x3e "default scores loaded") | 0 | — |
Saved: every `_LoadLevel`, menu toggles, prefs Save, quit via menu/AE (`_main` after the event loop); not on in-game ⌘Q [H].

## UNRESOLVED (consolidated)
U1 Text content of PICT 9030/9031 (pause instructions) and of PICT 913 title art (needs HectorKit render + Ben's eyes).
U2 Plain-text pause cheat codes (only hashes known).
U3 Info-box messages 4–33 and occasion texts; birthday dates.
U4 Letters-font glyph rects (`_InitLetterRects`), progress-bar colours, high-score overlay pattern look.
U5 Sound Tool channel allocation / priority / stealing semantics (AmbrosiaTools, external).
U6 ⌘M Music vs Minimize conflict; whether "A" = ⇧⌘A; Carbon-supplied app-menu items.
U7 Sprite set 0x20 (enemy icons) consumer; snd 12/29 usage.
U8 Delivered frame rate on real hardware (NR-11); exact behaviour when a frame overruns the 0.033 s timer.
U9 Prefs-dialog item ↔ pref wiring beyond the item labels (dialog filter not fully read).
U10 Initial `gFilmCounter` (assumed 0 → FILM 1 first).
U11 High-score joke-name substitution pairs.
U12 Where `_SetChicagoTwelve` text is used.
Note for the bank: data-formats §7 decodes `Rect 1` as top,left,bottom,right; TMPL 128 + `_GetRectRsrc` show the stored order is Left,Top,Right,Bottom (New button = L165 T228 R315 B262). ⚑ Applied: `data-formats.md` §7 corrected (T0, 2026-10-04).
