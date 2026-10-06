# Cythera 1.0.4 — engine structure, class roles, main loop, clock, screen pipeline

Register: **code reading only**. The exhaustive one-line-per-method listing is mechanical and lives
in `engine-classmap-1.md` / `-2.md` (139 classes, 793 methods) and `engine-classmap-3.md` (263 free
functions). This file explains what the classes are and pins the timing/screen constants.

---------------------------------------------------------------------------------------------
## 1. Program shape
- PEF container (`Joy!peffpwpc`), 3 sections (`tools/pef.py` output): code 0xCD280 bytes at file
  0x3470 (Ghidra base 0x10000000); pattern-initialised data, packed 0x86BA → unpacked 0xC18C,
  total size 0x7934E (Ghidra base 0x100CD280); loader section. TOC entries hold
  section-relative offsets (verified: TOC 0x100CE1B8 → code offset 0xC536F = the string "Out of
  space for new props" at file 0xC87DF = 0x3470 + 0xC536F). [HIGH]
- Fat application: `Cythera.rsrc` also carries 9 `CODE` resources (68K build, 610,529 B) and a
  `cfrg`. Only the PPC fork is in the dump. [HIGH: census]
- CodeWarrior C++ with MSL (`std::deque<TaskEvent>`, `std::list<ActivityQueueEntry>`,
  `std::map<TSpellFX,…>`, `std::vector`, `std::basic_string`). Static-init list (`FUN_10000000`)
  names the source modules: TStream, TAudio, TTaskMaster, TDroppableWindow, TStatusWindow,
  TConversation, Spells, THood, TToDo, DSInterp2, TSanity, THeap. [HIGH]
- Engine name "Delver" (`TDelverApp`, `Delv` resource, `'Delv'/'Temp'` scratch file, help `Page`
  resources "The Delver Engine …"). The data credits (`STR# 255` in `Cythera Data.rsrc`) list
  "Delver Engine" under Glenn Andreas. [HIGH]

## 2. Class roles (by family; counts = demangled methods in the dump)
Command: `python3 docs/cythera/tools/demangle.py <names.txt> counts` (names extracted from the dump
headers). Top counts: TActiveMonster 45, TScriptedWindow 38, TViewer 36, TGameSys 32,
TGameViewer 28, TStatusWindow 26, TSegFile 24, TInventoryWindow 22, TInterp 21, TAudio 20,
TWindow 18, TDroppableWindow 18, TCachedSegFiles 18, TCharacterWindow 17, TDelverApp 16,
TConversation 16, THeap 15, TPathFinder 13.

### 2.1 Application / OS framework (Glenn Andreas' own; not PowerPlant/MacApp — no `L*`/`T*` MacApp names)
| class | role |
|---|---|
| `TApp` → `TDelverApp` | event loop (`MyGetEvent`, `HandleIdle`, `HandleMouseDown`, `HandleOSEvt`, `TranslateKey`), menus (`TCommandMenu`, `TCMNU`), file open/save/new game (`DoOpen`, `NewGame`, `DoSave(As)`, `SaveToFile`, `OpenScenFile`, `OpenPlayerFile`, `RunStart`) |
| `TWindow`, `TDialog` | window base: layers (`PutInALayer`), modal (`BeginModal/EndModal`), redraw, monitor change |
| `TDroppableWindow` | windows accepting drag-and-drop of props (map, inventories): `FindDrop/CanDrop/DoDrop`, keyboard targeting, look/help |
| `TInventoryWindow`, `TCharacterWindow`, `TStatusWindow`, `TMapWindow`, `TBackdropWind` | game windows; `TStatusWindow` = roster, text log (`myprintf`), macros/function keys, sky strip (`ChangeOutdoor`, `DrawSky`) |
| `TScriptedWindow` + `TW*` widgets (`TWText`, `TWTextEntry`, `TWScrollText`, `TWButton`, `TWIcon`, `TWPix`, `TWPixButton`, `TWNumberEntry`, `TWNumber`, `TWMusicBox`, `TWInvent`, `TWList`, `TWAutoMap`, `TWControl`) | **windows built by scripts** (system-object class 4/5 in the VM: `DisplayAddText`, `DisplayAddButton`, … `DispatchUIMethod`); serialisable (`Marshal`/`__ct(TStream*)`) |
| `TApWidget`, `TApWindow`, `TAppearanceAdapter::NewTApControl`, `T7Adapter::NewT7Control`, `T7Widget`, `T7ControlWidget`, `T7GroupBox`, `T7IconWidget`, `T7LabelWidget`, `T7SliderWidget`, `TApPrefWindow` | dual-path control layer: Appearance Manager controls vs "System 7" self-drawn equivalents (`T7*`); used by the preferences window. [MED: inferred from names + `RegisterAppearanceClient` import] |
| `TWDEFRegister`, `TCDEFRegister`, `TBorderWDEF`, `TThinBorderWDEF`, `TDrawerWDEF`, `TPixsWDEF`, `TPushButtonCDEF`, `TCheckButtonCDEF`, `TRadioButtonCDEF`, `TNumberCDEF`, `TEditNumberCDEF`, `TProgBarCDEF`, `TScrollBarCDEF` | custom window/control definition procs implemented in-app; the 6-byte `WDEF`/`CDEF` resources are stubs [MED] |
| `TListBox`, `TInventoryList`, `TInventoryPile`, `TAbilityList`, `TJournalList`, `TPortraitList`, `TArchetypeList`, `TAIList`, `TWListList` | list views (LDEF-based) |
| `TStream`, `TMemoryStream`, `TRegistry` | serialisation; `TRegistry::RegisterClass(4CC, factory)` |
| `TPrefs` | preferences file (`Pref` resources "Volume", "Music") |
| `TTaskMaster`, `TaskEvent` deque | cooperative threads (Thread Manager `YieldToAnyThread`), input event queue |
| `TCache`, `TPixCacheBase` | purgeable memory cache for segments/pixmaps |
| `TSpinCursor`, `TBaseDragger`, `TDrawToGWorld`, `TBufferGWorld`, `TDisableAntiAliasText`, `TImageCompositor` + `T*ImageObject` (credits) | utilities |

### 2.2 World / data
| class | role | file |
|---|---|---|
| `TSegFile`, `TSegFileIterator`, `TSegLoad`, `TSegStream`, `SegFileHeader`, `TCachedSegFiles` | segment container + overlay | data-format.md §1 |
| `PropItem`, `CharEntry`, `CompoTileRecord`, `VAddr` | records | data-format.md §3–6 |
| `THood` | the set of props near the viewer (`MoveHood/AddToHood/RemoveFromHood/ResetHood`) | — |
| `TJournal`, `TJournalSegment` | journal text in 0xE000+ segments | data-format.md §1.5 |
| `TToDo`, `TToDoList` | to-do list (segment 0x0401) | — |
| `THeap`, `THeapObj`, `THeapList`, `THeapDict`, `MemRange`, `TSanityChunk` | persistent script heap; `TSanity` = debug memory checker (`CalcChecksum` returns 0) | script-vm.md §7 |

### 2.3 Game logic
| class | role |
|---|---|
| `TGameSys` | player command layer: `MoveCommand`, `WalkToLocation`, `TeleportTo`, `CanMove/TryMove/CanSlide`, `SwitchParty`, `Look/Talk/Search/Use/UseOn/Take/Wield/Drop/Attack/SlideItem` commands, `SendSignal`, `HeartBeat`, `IsTakable` — each mostly sends a selector to scripts |
| `TActiveMonster` (+ `TDragonMonster` type 0xB, `TOctoMonster` 0xC, `TCrawlMonster` 9–10: multi-tile bodies) | every on-stage creature incl. party: movement (`PaceNS/PaceEW/DoRoam/GoTowards/HandleMove/HandleSubMove`), combat (`DoAttack/DoDefend/DoRetreat/FindStrongest/Weakest/Nearest/GetEnemyStatus/CountAttackers`), party (`JoinParty/LeaveParty/FollowLeader`), lifecycle (`HatchEgg`, `CreateMonster`, `Save/LoadMonsters`), barks |
| `TPathFinder` | A*-like candidate search (`AddCandidate/NextCandidate/CalcWeight/FindPath/FindWaypoint/FurthestPoint`) |
| `TSpellFX` | timed abilities/spell effects queue (`PassTime`, `HasAbility`, `RemoveStackedAbility`, FX queue saved in the 'Char' stream) |
| `TGremlin` | script-attached invisible agents with frames (`OnEnter`, `OnSignal`, saved) |
| `TConversation`, `TInteraction`, `TConvMode`, `TConvResponseMode`, `TPickMode`, `THowManyMode`, `TModalMode`, `TBark`, `TTextContext`, `TStyleRun`, `TTextOut` | conversation window & modal input used by script statements 0x8E/0x8F/0x90 (keyword answers `AddAnswer/FindAnswer`, `ScanForHints`) |
| `SCombatAIHeader`, `SCombatAIEntry`, `TAIDebug`, `TEditUserBehavior` | combat AI (ai-scripts.md); ⚑ corrected (review 2026-10-03): `EditUserBehaviors__Fv @ 100b1b38` constructs `TEditUserBehavior` (0x18 bytes) and runs it through the pointer-call glue — the likely owner of the `.ai` → `CompileAIFile` path [MED] |
| `TInterp` (+ free `DoExpr` helpers, `GetField/SetField/GetGlobal/CreateSysObj…`) | script VM (script-vm.md) |
| `TAudio`, `GMSTune`, `GMS*`, `TSoundTracker` | sound (Sound Manager double-buffer, spot/ambient sounds with stereo `CalcStereo`) and music (QuickTime Tune player imports `TuneQueue/TunePreroll…`) |

⚑ corrected (review 2026-10-03) — game-logic free functions present in the dump but not described elsewhere in
this bank (names only; LOW until read): `ShuffleUpPartyInventory`, `CopyProp` / `CloneProp` /
`ConjoinProp` (ConjoinProp = merge a new stack into an existing one — used by builtin 0xA8),
`GetPropUltimateParent` (used by the inventory builtins 0xAB/0xAE/0xAF/0xB0/0xB1), `InFrontOf`,
`FindSurface`, `RecalcFX` / `DoPropFX` / `AdjustPropFX`, `IsInArea`, `RotateTile`, `ObjToMonst`,
`PropToCommand` (sends selectors 12/30/55), `VAddrToStr`, `SysObjToString`, `GetTileName`. A further
352 methods of already-mentioned classes appear only in the mechanical classmap (acceptable).

### 2.4 Rendering
`TViewer` (tile renderer) → `TGameViewer` (game view: clock, light, missiles, magic map, zones);
missile/FX helpers `TMissileThrower`, `TMissileSpinner`, `TMissileStream`, `TCircleShower`,
`TTileShower`, `TBres`. See §5.

### 2.5 Out of scope for the replica (identified only)
Registration (`Register Cythera` app, `STR# 900 "-Reg Strings"` "NOT REGISTERED"); InputSprocket
(`InitISSupport` … `HandleISPseudoMouse`); CD-audio strings (`STR# 990`); desktop-database comment
copying (`DTCopyComment`, `FSpFileCopy` = MoreFiles); AppleEvent glue; `TSanity` memory checker;
`Audt` resource ("Windstup…" tags); gamma fades (`GammaFadeIn/Out` — a visual nicety, keep only
if Ben wants).

---------------------------------------------------------------------------------------------
## 3. Clock and timing

### 3.1 The game clock [HIGH]
`DAT_100d3e18` (u32) = time of day in **units of 1/4096 hour**; `DAT_100d3e1c` (i16) = day count.
`DoTicks__11TGameViewerFlUc @ 1005b6e4`:
```c
for (; 0x17fff < _DAT_100d3e18; _DAT_100d3e18 -= 0x18000) _DAT_100d3e1c++;   // 24 h = 0x18000
if (forced || 100 < n || (clock >> 0xc) != oldHour) ScheduleTime(clock >> 0xc, …);  // hourly schedules
DayTimeChanged(this, forced || (clock >> 10) != oldQuarter);                       // quarter-hour light
```
- hour = clock >> 12 (0..23); quarter-hour = clock >> 10 (0..95). A game minute is 4096/60 ≈
  68.3 units (not an integer — the engine has no minute unit). [HIGH]
- Periodic rates (data `DAT_100d5c40`, read with `tools/pef.py` + offset 0x100d5c40−0x100cd280):
  **[4096, 2048, 1365, 1024, 819, 409, 16]** units = 1 h, ½ h, ⅓ h, ¼ h, ⅕ h, 1/10 h, 16 units.
  `DoTicks` counts boundary crossings of each rate (rounded: `(clock + rate/4) / rate`). Uses:
  rate 0 → food countdown (CharEntry +0x1B) per hour and the hourly "chime" (selector 21, arg
  0x101) to props whose property 0x27 has bit 0x100; rate `min(level>>1, 4)` → +1 Health and +1
  Magic regeneration per crossing while fed; rate 5 (1/10 h) → poison −1 HP / regeneration +1 HP
  per crossing, and countdown props (type flag 0x20); rate 6 (16 units) → countdown props (flag
  0x8000000) and 'B' frame-9 triggers. [HIGH as code; the "chime" naming LOW]

### 3.2 Turn pacing [MED]
- Each creature has a busy counter (CharEntry +0x12). `MoveCommand` sets the leader's to 10 on a
  successful step (4 on a bump), `TGameSys::HeartBeat(n)` adds n and runs
  `TActiveMonster::MoveAll`, which loops `DoTick` over the active-monster list. `DoTick`:
  if busy ≠ 0 → busy−1 and, **for the party leader, `DoTicks(viewer, 1, 0)` → the clock advances
  1 unit per leader tick**. So a step costs ≈ 10–11 units ≈ 9–10 game seconds. Attack delay is
  whatever the script returns for selector 28 (`DoAttack` stores it in +0x12). Roaming = 8.
- Real-time throttle in `MoveAll`: frame budget `TickCount` 0x10 or 0x20 ticks (≈ 0.27 / 0.53 s)
  depending on the sign bit of preference byte `DAT_100d3e20`; a 0x3C-tick (1 s) loop guard.
  Exact wall-clock pacing NOT RESOLVED (several unnamed calls in the loop).
  ⚑ wave 2 (2026-10-06): superseded — the 0x10/0x20 "frame budget" (TOC 0x100ce898, its only TOC
  alias) is clamped in `MoveAll` and **never read anywhere**, so it delays nothing; the 0x3C guard
  only sets a per-character flag that makes `MoveAll` flush queued mouse/key events on exit. The
  real wall clock is the thread scheduler — §3.4. [HIGH]

### 3.3 Day/night and sky [HIGH unless marked]
- Sunrise/sunset constants `DAT_100d60b4 = 20480` (5:00) and `DAT_100d60b8 = 77824` (19:00) —
  never written by PPC code (grep shows reads only). `GetBrightness__Fsl @ 1006c0ac` (result
  >>4): 0 before 3:00; linear ramp 3:00→8:00 reaching 159 just before 8:00; **800** from 8:00 to
  17:00; ramp down from 17:00 to 22:00; 0 after. `AmbientLight__7TViewerFss`: brightness < 160 →
  ambient level = b/5 (0..31), else 32 (full). Brightness is floored by the current zone's
  minimum (`PTR_DAT_100cdea4`; negative = fixed). [HIGH arithmetic; the zone-minimum meaning MED]
⚑ corrected (review 2026-10-03): the floor is **`zoneMin / 3`**, not the raw minimum — `AmbientLight @ 10063fc0`
divides by 3 with the `0x55555556` multiply. [MED as the review labels it] The zone minimum is set
by script builtin 0xD8 (`script-builtins.md`).
- Party light: `Lite` resources 140+(radius/100) in `Cythera.rsrc` (byte n, then n×n intensity
  bytes: `Lite 140` = 65 B = 1+8², `Lite 158` = 14401 = 1+120²) are stamped around the party
  (`CopyLight`); `Lite 128..133` other light shapes. [HIGH sizes; usage of 128..133 NOT RESOLVED]
- Sky objects: `CalcLocations__Fss @ 1006be68` positions `DAT_100d6080 = 2` bodies on a 96-step
  day (quarter hours) with per-body rate {4, 20}, phase {48, 36}, phase-count {8, 1} (data read
  with `tools/pef.py`) — body 0 has 8 phases (a moon), body 1 has 1 (sun?). Drawn by `DrawSky` into
  the 288×32 strip (`0x8400+n` backgrounds). [MED: semantics of the three per-body numbers
  inferred from the arithmetic]
- `ColorCycle__FP8GrafPort @ 10008694` is an **empty function** in 1.0.4 PPC (`return;`). The
  palette reserves entries 0xE0–0xFB with usage 0x0C (`CreateGlobals`: `SetEntryUsage(…, 0xc,
  0x1500)` for 0xE0..0xFB) — animated-palette slots that this build never cycles. [HIGH]
- Time-of-day word (`GetGlobStr(1)`): hour < 4 or > 21 → "night"; < 12 → "morning"; otherwise
  `if (5 < hour) "evening" else "afternoon"` — as decompiled, **"afternoon" is unreachable**
  (12..21 → "evening"). ⚑ corrected (review 2026-10-03): confirmed by disassembly — `GetGlobStr` 0x10093D60: `cmpwi
  r31,0xc; bge 0x10093d70; … cmpwi r31,6; bge → "evening"`; 12–21 always yields "evening" and
  "afternoon" (100cee40) is unreachable. [HIGH]

### 3.4 Wall-clock pacing — ⚑ wave 2 (2026-10-06); item 16, wall-clock half: CLOSED
Source: `app-shell.md` §3 (threads, scheduler, task queue). Bodies: `MyScheduler__11TTaskMaster
FP16SchedulerInfoRec @ 1001cb94` and `TaskThread__11TTaskMasterFPv @ 1001d334` (missing dump),
`AnimThread__10TMapWindowFPv @ 10043280` (missing dump), `MoveAll`, `DoTick`, `Guide`,
`HandleMove`, `HandleSubMove`, `DrawRoutine__11TGameViewerFs` (main dump).
- **What is paced: the animation thread.** `AnimThread` loops `DrawRoutine__11TGameViewerFs(viewer,
  1)`, frame counter viewer+0xBA = (+1) mod 8, `AdvanceDisplacementFilters`, `YieldToAnyThread()`
  (m:10843–10857). It has no wait of its own; the Thread-Manager scheduler decides when it runs. [HIGH]
- **The pace.** Before choosing the anim thread, `MyScheduler` spins on `TickCount` (m:5715 `while
  (uVar11 < *(uint *)puVar7) { uVar11 = .glue::TickCount(); }`; m:5742 the same up to the deadline in
  mode 3) and then re-arms the deadline: m:5756 `*(uint *)puVar8 = uVar11 + (DAT_100d3e20 >> 2 &
  0xf);` (m:5753 adds to the old deadline when early). The read is the prefs **byte** at 0x100d3e20:
  `881a0000 lbz r0,0(r26)` / `5400f73e rlwinm r0,r0,30,28,31` with r26 = 0x100d3e20 (`ppcdis.py
  1001cb94 1001ced8`). So anim frames are ≥ F ticks apart, F = byte-0 bits 2–5. [HIGH]
- **Per setting.** `DefaultMenu__10TDelverAppFss @ 10015b10` menu 0x88 items 10/11/12 set
  `DAT_100d3e20 & 0xc3 | 0x10` / `| 0x18` / `| 0x20` (m:4949/4955/4961) → **F = 4 / 6 / 8 ticks =
  15 / 10 / 7.5 frames per second** at 60 ticks/s (MENU 136 labels them 16 / 10 / 8 FPS). The four
  CPU-class defaults (`python3 -c "…toc.data_u32(0x100d426c,4)"` → 0x18800000, 0x18800000,
  0x99800000, 0xDBC80000) all have byte 0 bits 2–5 = 6. A census of every read/write of
  0x100d3e20–23 in the four dumps (`grep -n 'd3e2[0-3]'`) finds bits 2–5 written only by those menu
  items and the PostInitMac default; `SaveSettings__13TApPrefWindowFv` masks preserve them
  (`& 0x7d`, `& 0xbf`, `& 0xfe`). MENU 0x88 is never inserted into the 1.0.4 menu bar
  (app-shell.md §4.3, MED absence scan), so **in practice F = 6: 10 frames/s**, unless a prefs file
  already holds another value. [HIGH arithmetic; "in practice" MED]
  ⚑ corrected (review wave 2 2026-10-06): read "**at most** 10 frames/s". `MyScheduler` only
  enforces a minimum spacing (m:5753 `*(uint *)puVar8 = *(int *)puVar8 + (DAT_100d3e20 >> 2 & 0xf);`
  when early, m:5756 `= uVar11 + (…)` otherwise) and runs a frame only when no event, redraw, task
  slice, conversation or background state takes precedence (app-shell.md §3.3), so 10 fps is an
  upper bound, not a rate. [HIGH]
- **Which game events wait for a frame.** `DoTick__14TActiveMonsterFUc @ 1004ded8` (p:21418,
  p:21461–21467) and `Guide__14TActiveMonsterFv @ 1004dbc0` (p:21320) set the mode word to 3 and
  `YieldToAnyThread()` around a visible move of the party leader — p:21461 `if (*(short *)(param_1 +
  2) == *(short *)puVar7) { … *puVar8 = 3; .glue::YieldToAnyThread(); …` after a sub-move step —
  so each displayed leader sub-step costs one paced frame. Sub-steps per tile come from the movement
  bits (byte 0 bit 7 = sub-tile movement on, bit 1 = finer): `HandleSubMove @ 10048fb0` advances the
  phase by 2 up to 2, or by 1 up to 3, and divides the busy counter by 2 or 4 (p:20576–20592) —
  about **1 / 2 / 4 frames per tile** for Fastest / Faster / Smoother (= Graphics Quality
  Performance … Quality), i.e. ≥ 6 / 12 / 24 ticks per leader step at F = 6. [MED: starting phase
  `param_6` of HandleMove not traced; non-leader steps do not yield]
- **The player turn itself** is not clocked: keys/clicks are queued to the task thread
  (`TaskThread`, kinds 1/2) and processed when the scheduler runs it (mode 2 alternates one task
  slice per anim frame; mouseDown/keyDown pending or a window needing redraw hands the CPU to the
  event loop first). In "real-time" mode (flag TOC 0x100cdd04, off by default, toggled by
  `TMapWindow::KeyRoutine` key 0xCA) `MyGetEvent__10TDelverAppFsP11EventRecordUc @ 10012c24`
  fabricates a space keyDown after 0x14 idle ticks (m:4569–4578) — an idle turn every 1/3 s. [HIGH]
  ⚑ corrected (review wave 2 2026-10-06): the "idle turn" meaning is now traced, so the HIGH stands
  on this chain (all read this session):
  1. `KeyRoutine__10TMapWindowFs @ 100437b8` (x:759–762; `find_func.py
     'KeyRoutine__10TMapWindowFs' --file ghidra/Cythera_extra.decompiled.c`, last statement): `if (((sVar16 == 0x20) || (… PerformDoKey
     … == '\0')) && (*(short *)(*(int *)puVar1 + 4) == 3)) { …ScheduleKeyDown…(param_1,param_2); }`.
  2. `ScheduleKeyDown__11TTaskMasterFP16TDroppableWindows @ 1001d05c` (p:7783):
     `_QueueTaskEvent__FssP16TDroppableWindow5Points(2,0,param_1,…,(int)param_2);` then
     `YieldToAnyThread()`; `TaskThread__11TTaskMasterFPv @ 1001d334` (m:5876) runs a kind-2 event as
     `.debug::_KeyRoutine__16TDroppableWindowFs(uStack_8c,(int)(short)uStack_84._0_2_);`.
  3. `KeyRoutine__16TDroppableWindowFs @ 1002a07c` (p:12430; label p:12559, call p:12566): 0x20 falls through to `LAB_1002a3a4`
     (`if (0x20 < param_2) return;` just above it): key target active → `FUN_100c50e8(target, 8)` and
     return; else mode word := 0, `KeyboardMode(status, 0)`, `XDirection…(param_1,8);`.
  4. `XDirection__16TDroppableWindowFQ28TGameSys10EDirection @ 10028ff4` (p:11966): `bVar1 = param_2
     != 8;` (p:12026) so modifier actions are skipped; the hold loop (p:12137–12138) does `if (param_2 == 8) {
     _HeartBeat__8TGameSysFs(*puVar10,10); }` (else `MoveCommand`), re-reads `GetKeys` and repeats
     with 8 while KeyMap byte 6 bit 1 (`local_7a & 2`, p:12167, Mac key code 0x31 = space) is held.
  So space = `HeartBeat(10)`: ten busy units, the same as a successful step (§3.2) — a turn spent
  standing still. [HIGH as code; "key code 0x31 = space" is the standard Mac KeyMap, MED]
- **Other waits.** `DrawRoutine__11TGameViewerFs`: only while a screen transition is pending
  (viewer +0x20C28 kinds 1–8), 5 ticks per transition step (p:28009 `do { uVar7 =
  .glue::TickCount(); } while (uVar7 < iVar9 + 5U);`), then cleared (p:28153). `HandleMove`,
  `HandleSubMove`, `Render__7TViewerFssss`: no `TickCount`, `Delay`, `Yield` or `WaitNextEvent`
  (scan of their bodies for those names: only prefs-bit tests). [HIGH]
- ⚑ wave 3 (2026-10-06): **item 16 layer half CLOSED** — the wave-2 LOW outline of
  `Render__7TViewerFssss @ 10066ac0` is replaced by a full reading in `render.md`: backdrop pre-pass
  (+0xB8) → ground cells → passes 0, 1, (2 dead), 3, creatures (4), FX, 5 → backdrop post-pass, then
  `ApplyRoof`, colour filter and lighting in `DrawRoutine`; pass selection = per-pass kind mask + tile-flag
  mask tables at 0x100D5FA4–0x100D6003 (render.md §2.4). [HIGH]

---------------------------------------------------------------------------------------------
## 4. Party, schedules, movement (pointers)
Schedules and `EvalCondition`: rules.md §3. `MovePartyBetweenLevels`, `RepositionChar`,
`CueCharacters`, `RebuildParty`: rules.md §2.

---------------------------------------------------------------------------------------------
## 5. Screen pipeline (coordinates fixed by code)
- **Tile = 32×32 px, 8-bit indexed**, palette = `clut 128`-style 256-entry CTab from
  `GetCTable(0x100)` (`CreateGlobals`). [HIGH]
- **Map view = odd N×N tiles, N clamped to 5..15** (`Resize__7TViewerFRs @ 10062b50`: force odd,
  `< 5 → 5`, `> 15 → 15`); `TGameViewer` ctor passes `(rect.right − rect.left)/32 + 1` (view width in tiles + 1). Centre tile =
  `(N−1)/2`; a second size `N+2` (one-tile border) is kept for scrolling. [HIGH]
- **Stage = 31×31 cells (−15..+15) around the leader**, rebuilt by `SetStage__7TViewerFss` every
  move: per cell 8 bytes {u32 OR of tile flags, u16 best prop | priority nibble | tile bits}
  (0x1E08 = 31·31·8 bytes) plus a **124×124 quarter-tile grid** (0x7820 = 124·124·2) for roof/
  overlay ownership (`(dy·4+0x3C)·0xF8 + (dx·4+0x3C)·2`). Props draw at priority 1..8 chosen from
  tile flags and type flags (the ladder in `SetStage`; data-format.md §4–5); multi-tile objects
  extend left (tile flag 0x80: tile−1 at x−1), up (0x40: tile−1 at y−1) or both (0xC0: tile−1 up, −2 left, −3 up-left). [HIGH as code;
  priority semantics MED]
  ⚑ wave 3 (2026-10-06): the priority does **not** order drawing — `Render` never reads the stage;
  the ladder picks each cell's best prop for `GetBestProp`/`GetBestPropRel`/`GetBestTile` (look,
  search, use-on, cursor, keyboard target, missiles) [HIGH]. Priority 7 (kinds 4/0x24, type flag
  0x400000) is never a cell's best prop: it goes into the 124×124 quarter grid, which is a
  **creature/occupant grid** (readers `HatchEgg`, `SwitchParty`, `InteractProps`), not roof
  ownership [HIGH code; name MED]. `Render` draws 0xC0 objects as tile−1 **left**, −2 **up** (unmirrored),
  the transpose of this stage layout (render.md §2.5, §5). Ladder table: render.md §5.
- Lighting per stage cell (`CalcLighting`, `ApplyLight`, `DimOffLevel`, `BuildFilters`,
  `ApplyFilter`), line of sight (`LOS`, `NoLOS`, `IsStraightAbs/Rel`), roofs (`ApplyRoof`),
  displacement filters (data-format.md §3.4). ⚑ wave 3 (2026-10-06): rendering
  `Render__7TViewerFssss` (8.8 KB) and its place in `DrawRoutine` are read in `render.md` (layer
  order, pass tables, sprite offsets, prop FX byte, staged lists, roofs/filter/light after it).
- Portraits 64×64; macro icons 32×16; sky strip 288×32; inventory icons are the 32×32 tile
  centred, with a count (≥2) or letter (A + n) outlined in the corner (`DrawInventoryIcon`). [HIGH]
