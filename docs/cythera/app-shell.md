# Cythera 1.0.4 — application shell: startup, event loop, task scheduler, menus, files, prefs

⚑ wave 2 (2026-10-06) — new file (reader R3, census group **C**). Register: code reading only. Line
numbers `m:NNNN` are lines of `ghidra/Cythera_missing.decompiled.c`, `p:NNNN` of
`ghidra/Cythera_pef.decompiled.c` (main dump), `x:NNNN` of `Cythera_extra.decompiled.c`. Labels:
HIGH / MED / LOW / NOT RESOLVED as in the brief. Related banks: pacing → `engine-classes.md` §3.4;
behaviour editor / AI debugger → `ai-scripts.md` §9; prefs word layout → `data-format.md` §8.

---------------------------------------------------------------------------------------------
## 0. Provenance and covered functions

Group C membership re-derived from the census classifier (missing-census.md §0 python, class
column) and filtered to the C classes: **125 rows / 30,876 B — agrees with the census**.
```sh
python3 - bi.txt > classes.txt <<'EOF'   # census §0 classifier, printing "addr len class name"
…
EOF
grep -E ' (TApp|TDelverApp|TTaskMaster|TAdjustTaskMaster|TRunStart|TCreatePlayerDialog|TArchetypeList|TPortraitList|TApPrefWindow|TEditUserBehavior|TAIDebug|TAIList|TAudio|FREE:(PlayOnceCB|LoopSpotCB|LoopCB|Handle\w+|MyGrowZone|MyNav\w+|RemoveConsole)|TAudit|XI\w+|XInterp|VAddr|TMemoryStream|TCache|TPixCache\w*|TImageObject|TFadeInTextImageObject|TStringFadeInTextImageObject|TScrollingCreditImageObject|TSTRScrollingCreditImageObject|TImageCompositor) ' classes.txt > C.txt
grep mappingentry classes.txt >> C.txt; wc -l < C.txt; awk '{s+=$2} END{print s}' C.txt   # 125 / 30876
```
`TApWindow`/`TApWidget` are **not** in C (census group H). Every body below was read whole
(125/125). Pointer calls (`FUN_100c50e8(...)`, the ptr-call glue) were resolved by slot with a
helper that walks `ppcdis.py` output for `lwz r12,N(r12); bl 0x100c50e8` and names slot N of a
vtable (TVector recipe of dialogue.md §0); the app vtable is `PTR_PTR_100d4358`
(`__ct__10TDelverAppFv @ 10011d84`: `*param_1 = &PTR_PTR_100d4358;`, p:4174 area). Slots used here:
+0x0C InitMac, +0x10 PostInitMac, +0x14 ChangeMenuBar, +0x18 MEL, +0x1C DefaultCommand,
+0x20 DefaultMenu, +0x24 LoopTask, +0x2C MoveableModal, +0x40 RedrawAllNow, +0x44 MyGetEvent,
+0x4C SetupEmergencyMem, +0x50 LowOnMemory, +0x60 HideMenuBar, +0x64 ShowMenuBar, +0x68 GetOneFile,
+0x6C PutOneFile, +0x70 GetAppSignature, +0x74 OpenFromFS, +0x78 DoStartup, +0x7C DoQuit,
+0x80 DoMonitorChanged, +0x88 HandleIdle, +0x94 HandleCommand, +0x98 HandleMouseDown,
+0x9C HandleKeyDown, +0xA0 HandleActivateEvt, +0xA4 HandleUpdateEvt, +0xA8 HandleOSEvt,
+0xAC HandleEvent, +0xB4 TranslateKey. TWindow slots (vtable `PTR_PTR_100d7930`, TApPrefWindow):
+0x0C DrawRoutine, +0x1C MenuRoutine, +0x20 CommandRoutine, +0x24 CloseRoutine, +0x2C KeyRoutine,
+0x3C CursorRoutine, +0x40 IdleRoutine, +0x44 LoopTask, +0x54 HandleMonitorChanged, +0x68 Select,
+0x6C Show, +0x70 Hide, +0x74 HandleDeactivate, +0x78 HandleActivate. [HIGH: vtable words]

Covered (name @ addr, length in bytes):
```
TApp::ChangeMenuBar @1000bfe4 344 · HandleOpenDocuments @1000c228 356
HandleQuitApplication @1000c3b4 136 · HandleOpenApplication @1000c464 108
HandleDisplayNotice @1000c4f8 412 · TApp::DoStartup @1000c6e8 4 · TApp::OpenFromFS @1000c714 4
TApp::DoMonitorChanged @1000c748 444 · MyGrowZone @1000c948 152
TApp::SetupEmergencyMem @1000ca00 148 · TApp::LowOnMemory @1000cac4 4 · TApp::InitMac @1000caf0 1264
TApp::PostInitMac @1000d004 4 · TApp::HideMenuBar @1000d234 408 · TApp::ResetCursor @1000d570 44
TApp::MEL @1000d6c4 444 · TApp::HandleEvent @1000d934 456 · TApp::HandleCursor @1000dca4 568
TApp::LoopTask @1000e02c 128 · TApp::Modeless @1000e0d0 4 · TApp::CenterWindow @1000e104 4
TApp::AlignWindowTo @1000e13c 4 · TApp::RelativeMoveWindow @1000e174 296 · TApp::ShowErr @1000e2d8 4
TApp::FatalErr @1000e300 4 · TApp::WarnErr @1000e32c 4 · TApp::HandleContextMenu @1000e358 88
TApp::HandleCommand @1000e894 372 · TApp::HandleKeyDown @1000ea34 336
TApp::HandleActivateEvt @1000ebb0 188 · TApp::HandleUpdateEvt @1000ec9c 156
TApp::RedrawAllNow @1000ee08 168 · TApp::MoveableModal @1000eed8 168
TApp::MoveableModalDialog @1000f128 148 · MyNavEventProc @1000fde8 172
MyNavFilterProc @1000feb8 176 · TApp::GetOneFile @1000ff8c 968 · TApp::GetAppSignature @1001038c 12
TApp::PutOneFile @100103c4 592 · TApp::Log @1001064c 28 · TDelverApp::dt @10011e0c 140
TDelverApp::HandleIdle @10011ec0 244 · TDelverApp::HandleOSEvt @10011fe4 328
TDelverApp::PostInitMac @1001215c 2112 · TDelverApp::TranslateKey @10012b0c 140
TDelverApp::ResetCursor @10012bcc 40 · TDelverApp::MyGetEvent @10012c24 468
TDelverApp::DoQuit @10013a58 384 · TDelverApp::OpenFromFS @10014ef8 428
TDelverApp::ShowMenuBar @1001555c 60 · TDelverApp::GetGDevContent @100155c8 96
TDelverApp::HandleMouseDown @10015668 188 · TDelverApp::DefaultCommand @10015888 596
TDelverApp::DefaultMenu @10015b10 1432 · TRunStart::KeyRoutine @10016690 520
TRunStart::MouseRoutine @100169fc 568 · TRunStart::IdleRoutine @10016c68 340
TRunStart::DrawRoutine @10016f84 464 · TRunStart::CloseRoutine @10017180 172
TRunStart::dt @10017408 100 · TDelverApp::DoStartup @10017494 52
TDelverApp::LowOnMemory @100174f4 108 · TDelverApp::GetAppSignature @10017908 12
TDelverApp::Log @10017948 28 · TMemoryStream::Align @10018448 44
TMemoryStream::GetSize @100184dc 16 · TMemoryStream::SetPos @1001851c 16
TMemoryStream::Write @10018558 88 · TMemoryStream::Read @100185e0 88
TMemoryStream::ReadTo @10018664 92 · PlayOnceCB @1001ad44 96 · LoopSpotCB @1001add4 120
LoopCB @1001ae7c 276 · TAudio::dt @1001b00c 152 · TAdjustTaskMaster::dt @1001cb0c 88
TTaskMaster::MyScheduler @1001cb94 836 · TTaskMaster::TaskThread @1001d334 1572
TPixCacheFromCachedSegFiles::GetData @10074224 64 · TPixCacheFromCachedSegFiles::DoneData @100742a0 84
TPixCacheBase::DoneData @10074660 4 · TCache::WriteBlock @1007c920 4
XIInvalidOpcode::dt @100807c8 100 · XIInvalidSegment::dt @10080858 100 · XInterp::dt @100808ec 84
XIEndGame::dt @100825cc 100 · XIInvalidVAddr::dt @1008332c 100 · XIRaise::dt @100840a4 100
VAddr::ct @1008418c 12 · TImageObject::Tick @1009d7e0 4 · TImageObject::Apply @1009d810 4
TFadeInTextImageObject::Tick @1009d9ac 516 · TFadeInTextImageObject::Apply @1009de14 376
TStringFadeInTextImageObject::Render @1009e0ec 500
TScrollingCreditImageObject::Tick @1009e478 356 · TScrollingCreditImageObject::Apply @1009e614 188
TSTRScrollingCreditImageObject::RenderNextLine @1009e7d0 364 · TPortraitList::LDEFDraw @100a06f8 412
TPortraitList::LDEFHilite @100a08d4 4 · TArchetypeList::LDEFDraw @100a09e0 120
TCreatePlayerDialog::DrawRoutine @100a114c 84 · TCreatePlayerDialog::dt @100a11d8 252
TPortraitList::dt @100a1304 100 · TCreatePlayerDialog::DialogItemRoutine @100a140c 460
TCreatePlayerDialog::DialogDrawRoutine @100a1618 212
TCreatePlayerDialog::MouseRoutine @100a172c 344 · TImageCompositor::dt @100a2028 156
TApPrefWindow::KeyRoutine @100a3578 332 · TApPrefWindow::HandleMessage @100a36f4 872
TApPrefWindow::dt @100a3d1c 100 · TArchetypeList::dt @100a3dac 100 · RemoveConsole @100a3e68 4
THeapDict::mappingentry::ct @100aa448 12 · TAIDebug::dt @100ad774 160
TAIDebug::DialogItemRoutine @100ada10 88 · TAIDebug::DialogDrawRoutine @100ada9c 564
TAIDebug::DrawRoutine @100add04 44 · TAIDebug::MouseRoutine @100add5c 164
TAIList::LDEFDraw @100b1290 268 · TEditUserBehavior::DrawRoutine @100b1588 84
TEditUserBehavior::dt @100b1614 180 · TAIList::dt @100b16f8 100
TEditUserBehavior::DialogItemRoutine @100b1780 364
TEditUserBehavior::DialogDrawRoutine @100b1928 128 · TEditUserBehavior::MouseRoutine @100b19e4 280
TAudit::AuditStartup @100b1e80 4
```
Context read from the main dump (not counted): `main @ 10017590`, `RunStart`, `DoItemHit`,
`TRunStart` ctor, `NewGame`, `DoOpen`, `CreatePlayer`, `TCreatePlayerDialog` ctor/`AdjustCurArch`/
`GetPortrait`, `DoPrefs`, `TApPrefWindow::{GetCurSettings,AdjustSettings,ApplySettings,SaveSettings,
AddContent}`, `TPrefs::*`, `TTaskMaster::*` (InitTaskMaster … ScheduleSkill), `MoveAll`,
`TApp::{DoQuit,MyGetEvent,DefaultMenu,DefaultCommand,HandleIdle,TranslateKey}`, `DoSplash`,
`InitWorld`, `EditUserBehaviors`, `TEditUserBehavior`/`TAIDebug` ctors, `PerformAI`, and
`AnimThread__10TMapWindowFPv @ 10043280` (missing dump, group D, cited for pacing).

Resources quoted below were read with `rsrc.parse()` from `$G/Cythera.rsrc` and
`$G/Cythera Data.rsrc` (`$G` = `…/ambrosia-extracted/RPG/Cythera/Cythera (installed)/files`): a
10-line script printing `MBAR`, `MENU` (title + items), `CMNU 129` bytes, `DITL` items,
`ALRT`, `Pref`, `STR `, `nrct 128`, `PICT` ids.

---------------------------------------------------------------------------------------------
## 1. Startup sequence

### 1.1 `main @ 10017590` (main dump, p:5960 area) [HIGH]
`new TDelverApp` (0x7C bytes) → vslot +0x0C **InitMac** → abort with `StopAlert(0x400)` +
`ExitToShell` if the Thread Manager flag (+0x1B) or the QuickTime flag (+0x19) is clear (messages
TOC 0x100ce2b0 / 0x100ce2ac: "need to install the thread manager" / "QuickTime 3.0 or later") →
note whether the main device is the chosen monitor → **HideMenuBar(0)** → `HideCursor` →
`DoSplash(0)` (PICT 0 "Large Ambrosia logo" in `Cythera.rsrc`, centred on a black window) → unless
prefs byte 3 bit 0 is set, a **0x78-tick (2 s) busy wait**:
```
100176c8: 3862eba0  addi r3,r2,-5216  ; = 0x100d3e20
100176cc: 88630003  lbz r3,3(r3)            100176e0: 3b830078  addi r28,r3,120
```
(`python3 docs/cythera/tools/ppcdis.py 100176a0 10017700`) → `InitTaskMaster` → `OpenScenFile` →
vslot +0x18 **MEL** (the main loop) inside a try block → `HandleISStop` → delete app →
`GammaFadeIn(10)`. Four catch handlers (`ppcdis.py 10017700 100178f0`) each call DoQuit (+0x7C)
and set the quit flag: out-of-memory alert (TOC 0x100ce2a8), fatal error with text (0x100ce2a4),
unknown fatal error (0x100ce2a0), and one that calls `EndTalking__13TStatusWindowFv` with no alert.
[HIGH as code; which C++ type each handler catches is MED — inferred from the messages]

### 1.2 `TApp::InitMac @ 1000caf0` (m:2951–3076) [HIGH]
`MaxApplZone`, `MoreMasters`×4, InitGraf/Fonts/Windows/Menus/TEInit/InitDialogs/InitCursor,
`SetEventMask(0xffff)`, vslot +0x4C **SetupEmergencyMem(0x14000)** (80 KB `NewPtr` reserve at +0x60,
grow-zone proc `MyGrowZone`; `NewPtr` failure throws `bad_alloc`). Gestalt probes → app flags:

| field | probe | rule |
|---|---|---|
| +0x14 | `'qd  '` | ≥ 0x100 → Color QuickDraw |
| +0x1B | `'thds'` | bits 0 and 2 set → Thread Manager present |
| +0x15 | `'evnt'` | bit 0 → AppleEvents; then install handlers (below) |
| +0x16 | `'appr'` | bit 0 → Appearance; `RegisterAppearanceClient()` |
| +0x17 | `'cmnu'` | bit 1 and `InitContextualMenus()==0` (PostInitMac forces it back to 0) |
| +0x18 | `NavLibraryVersion` linked and `NavServicesCanRun()` → Navigation Services |
| +0x19 | `'qtim'` ok, `'qtrs'` bit 0, `EnterMovies` linked → QuickTime |

Defaults: +0x34 thread-to-yield 0, +0x1F 0, **+0x3A WaitNextEvent sleep = 3**, +0x1E foreground 1,
+0x30 modal window 0, **+0x3C idle interval 0**, +0x64…+0x76 menu-bar/drag flags 0. AppleEvent
handlers (`AEInstallEventHandler('aevt', …)`; TVectors resolved with `toc.tocval` + `tb.py --at`):
`'oapp'` → HandleOpenApplication, `'odoc'` **and** `'pdoc'` → HandleOpenDocuments, `'quit'` →
HandleQuitApplication, `'cnfg'` → HandleDisplayNotice. A self-addressed `'psn '` descriptor
{0, 2} is built at +0x26. Ends with vslot +0x14 **ChangeMenuBar(0x80)** and vslot +0x10
**PostInitMac**.

### 1.3 `TDelverApp::PostInitMac @ 1001215c` (m:4213–4471) [HIGH unless marked]
1. `GetProcessInformation`; construct `TAudit` (its `AuditStartup @ 100b1e80` is an empty body).
2. `TRegistry::RegisterClass('ScrW', …)` and `('ChrW', …)` — stream classes for saved windows.
3. app +0x17 = 0 (no contextual menus), **+0x21 = 1** (autoKey events ignored, §2.2), +0x22 = 1
   (heap check each loop — but `HeapCheck__FP4Zone @ 10008e94` is 8 bytes, a stub; `tb.py --at`).
4. `InitISSupport` (InputSprocket).
5. `GetString(0x81)` = STR 129 "Cythera Data" → `FSMakeFSSpec` → `FSpOpenResFile` (fatal
   "Unknown scenario data" / "Unable to refer to scenario data" / "Unable to open data file"; TOC
   0x100ce398/394/390). `GetString(0x82)` = STR 130 "Cythera Patch" opened if present.
6. CD-audio glue `FUN_100bebec` (Gestalt `'aucd'`, `STR# 990`) → status at TOC 0x100cdd0c; 0x7B on
   a fallback path. [MED: unnamed glue]
7. `SetupGammaTools`, `TAudio::Init`.
8. **Prefs word**: `TPrefs::LoadPrefs("UI Prefs", &DAT_100d3e20, 4)`; on a miss, a CPU-class
   default (`Gestalt('cput')`, else `Gestalt('proc') − 1`) is stored and saved — table and bit
   meanings in `data-format.md` §8 (word values `toc.data_u32(0x100d426c,4)` = 0x18800000,
   0x18800000, 0x99800000, 0xDBC80000). Below 68040 it also calls `SetMusicVolume(0, 1)`.
9. App +0x67/+0x68/+0x69 = prefs bit 0 (live dragging), +0x66 = 1.
10. Options-menu check marks **only if `GetMenuHandle(0x88)` is non-NULL** — see §4.3: it is not
    in 1.0.4's menu bar.
11. Memory: `MaxMem` vs `'MemU' 129` ("PPC Mem Usage", 9 B: `00560000 000c0000 50` → base 0x560000,
    minimum 0xC0000, percent 0x50 = 80): cache size = (free − base)/100 × 80 %; below the minimum →
    "Not enough memory". Builds `TCache(size)` and `TCachedSegFiles` (global 0x100cdbc4).
    [HIGH arithmetic; field names MED]
12. Monitor: if (prefs byte 1 bit 4 "don't ask again" is clear) **or** Shift/Option is held
    (`(modifiers & 0xa00) != 0` from `EventAvail`), `PickAMonitor`; if that monitor is deeper than
    8 bits, DLOG/DITL 140: item 1 "Switch to 256 Colors" sets byte 1 bit 5, item 2 "Run Slower" clears
    it, item 3 checkbox "Don't Ask Again" → byte 1 bit 4; then re-pick and save prefs. Otherwise
    just `PickAMonitor`.

### 1.4 From MEL to the start screen [HIGH]
The first `'oapp'` AppleEvent (`HandleOpenApplication @ 1000c464`) sets the "AE seen" flag (TOC
0x100ce284) and calls vslot +0x78 **DoStartup** = `InitWorld` (cursors, `GammaFadeOut(200)`,
`CreateGlobals`, interface caches, `TBackdropWind`) + **`RunStart`**. `'odoc'`/`'pdoc'` instead
call vslot +0x74 **OpenFromFS** per file (§5.4). Until one of these arrives, menu commands are
ignored: `TApp::HandleCommand @ 1000e894`: `if ((*(char *)(param_1 + 0x15) == '\0') ||
(*PTR_DAT_100ce284 != '\0'))` gates the whole dispatch (m:3501).

---------------------------------------------------------------------------------------------
## 2. Main loop and event dispatch

### 2.1 `TApp::MEL @ 1000d6c4` (m:3163–3218) [HIGH]
Loop until quit (+0x1C) or end-modal (+0x1D with a modal window at +0x30; +0x1D is then cleared —
so nested MEL calls implement modal windows, §2.4). Each pass:
1. emergency reserve gone (`*(app+0x60) == 0`) → vslot +0x50 **LowOnMemory** (TDelverApp version
   throws `bad_alloc`, caught in `main`);
2. Thread Manager present and no modal window → `YieldToThread(+0x34)` or `YieldToAnyThread()`;
3. pending `DrawMenuBar` (+0x1F); heap check (+0x22; stub);
4. vslot +0x24 **LoopTask** (`GetKeys(app+0x40)`; front TWindow's LoopTask, slot +0x44);
5. if +0x3C == 0 or `TickCount() > next`: spin-cursor reset, `next = TickCount() + *(short*)(app+0x3c)`,
   vslot +0x44 **MyGetEvent(everyEvent, app+4, 1)**, vslot +0xAC **HandleEvent**.
InitMac sets +0x3C = 0, so an event is fetched every pass; no writer of +0x3C was found in this
group [MED]. The census phrase "idle every TApp+0x3C ticks" is literally right but the interval is 0.

### 2.2 `TApp::HandleEvent @ 1000d934` (m:3224–3277) [HIGH]
Auto-hide menu bar first: when the bar is hidden (+0x64) and the pointer reaches y ≤ 0 → vslot +0x64
ShowMenuBar; when shown and y > saved bar height (+0x76) → HideMenuBar(1). Then a jump table
(`toc.data_u32(0x100d3f98,24)`): 1 mouseDown → +0x98 HandleMouseDown; 3 keyDown → `NoDA()` → +0x9C
HandleKeyDown; **5 autoKey → dropped when +0x21 is set** (always, after PostInitMac), else as
keyDown; 6 update → +0xA4; 8 activate → +0xA0; 15 OS event → +0xA8; 23 high-level →
`AEProcessAppleEvent`; everything else (null) → +0x88 HandleIdle.

### 2.3 Input routing [HIGH unless marked]
- `TDelverApp::MyGetEvent @ 10012c24` (m:4546–4614): InputSprocket event first
  (`CheckForISEvent`), else `TApp::MyGetEvent` (`WaitNextEvent(mask, ev, sleep = +0x3A = 3, 0)`).
  On an event: records `TickCount()` (TOC 0x100ce364). If prefs byte 1 bit 2 is set, a mouseDown
  from `ButtonNumber()` 2/3/4/5 gets modifier 0x100 (cmd) / 0x1000 (control) / 0x800 (option) /
  0x200 (shift) (no writer of that bit exists — §8 of data-format.md). **No event**, the app in
  front, keyDown in the mask, no conversation window (TOC 0x100cdd00), the turn-mode flag TOC
  0x100cdd04 set, and > 0x14 ticks since the last event → it **fabricates a keyDown, char 0x20
  (space)**: `*param_3 = 3; … param_3[2] = 0x20;` (m:4575–4578). 0x100cdd04 is toggled by
  `TMapWindow::KeyRoutine` key 0xCA (x:619) with messages "Disabling/Enabling turn based
  movement" (TOC 0x100ce810/80c); its initial data bytes are 0 (`toc.D[0x62604:0x6260c]` = zeros).
  So **turn-based is the default; in "real-time" mode an idle player passes a turn every 20 ticks**.
  [HIGH as code; 0xCA = Option-Space in MacRoman is MED; what the space key does is the map
  window's (ui-play.md)]
- `TApp::HandleKeyDown @ 1000ea34` (m:3542–3577): vslot +0xB4 TranslateKey(message, +0x20); with
  Appearance, `MenuEvent` → HandleCommand; keys without ⌘, arrows 0x1C–0x1F and translated codes
  > 0xFF go to the modal (+0x30) / target (+0x70) / front-layer window's KeyRoutine (+0x2C); ⌘-keys →
  `MenuKey` → HandleCommand. `TDelverApp::TranslateKey @ 10012b0c`: ⌘ + '1'..'9' → 0x100..0x108,
  ⌘ + '0' → 0x109.
- `TDelverApp::HandleMouseDown @ 10015668`: during a conversation (0x100cdd00) a click on a window
  that is neither kind-1 (`(*(ushort *)(win + 8) & 7) != 1`) nor the front layer plays
  interface sound 0 and is dropped.
- `TApp::HandleCursor @ 1000dca4`: front-layer / modal window's CursorRoutine (+0x3C) when the
  pointer is inside it and below y 20 (or the bar is hidden); else ResetCursor (TDelverApp: cursor
  0x2A). `TApp::HandleActivateEvt`/`HandleUpdateEvt`/`RedrawAllNow` act only on windows of kind > 7
  (`7 < *(short *)(win + 0x6c)`), calling HandleActivate/HandleDeactivate or DrawRoutine between
  `BeginUpdate`/`EndUpdate`.
- `TDelverApp::HandleIdle @ 10011ec0`: `TAudio::Idle`, `TApp::HandleIdle`, `HandleISPseudoMouse`,
  then copies the main device's colour-table seed into the game palette globals (0x100cdc78,
  0x100cdc6c). [MED: purpose]
- `TDelverApp::HandleOSEvt @ 10011fe4`: resume → `SwitchedIn`, show + hilite all windows,
  `TAudio::Resume`, `HandleISResume`, stamp `GetDateTime` (TOC 0x100ce3c4); suspend → add the
  seconds since that stamp to TOC 0x100ce3c8 (foreground-time total), hide windows,
  `SwitchedOut`, `TAudio::Suspend`, `HandleISSuspend`. [HIGH; "play time" naming MED]
- `TDelverApp::GetGDevContent @ 100155c8`: on the game monitor the usable rect loses 0x90 = 144 px at
  the bottom (`*(short *)(param_3 + 4) + -0x90`). [HIGH; why = MED]
- `HideMenuBar @ 1000d234`: hides the Control Strip if `'sdev'` and visible, sets
  `LMSetMBarHeight(0)`, unions the bar rect into the gray region, repaints behind.

### 2.4 Modal windows [HIGH]
`TApp::MoveableModal @ 1000eed8` (m:3656–3672): saves +0x30, sets it to the window, `BeginModal`,
window Show (+0x6C) and Select (+0x68), **nested MEL**, window Hide (+0x70), `EndModal`, clears
quit flag +0x1C, restores +0x30. A dialog ends its modal loop by setting app **+0x1D = 1**
(e.g. `TCreatePlayerDialog::DialogItemRoutine`, m:20884). `MoveableModalDialog @ 1000f128` is
`ModalDialog` with filter `MoveableDialogerRoutine`.

### 2.5 Memory [HIGH]
`MyGrowZone @ 1000c948`: frees the 0x14000 reserve and returns its size; the next MEL pass (or the
task thread, §3.2) sees +0x60 == 0 and throws `bad_alloc`; `main` shows the out-of-memory alert and
quits. `TDelverApp::LowOnMemory @ 100174f4` throws directly.

---------------------------------------------------------------------------------------------
## 3. Threads and the task scheduler

### 3.1 Threads [HIGH]
`InitTaskMaster @ 1001c9a8` (p:7690): `SetThreadScheduler(MyScheduler)` (TVector 0x2950 →
0x1001CB94) and `NewThread(…, TaskThread)` (TVector 0x2948 → 0x1001D334), id at TOC 0x100cdd8c;
mode word (TOC 0x100cdd84) = 1. `TMapWindow` ctor (p:19110) creates a second thread
`AnimThread__10TMapWindowFPv @ 10043280` (TVector 0x2E90), id at TOC 0x100cdd88. Resolution:
`python3 -c "…toc.data_u32(toc.DB+w)…"` for w in (0x2e90, 0x2948, 0x2950), then `tb.py --at`.
AnimThread loops: `DrawRoutine__11TGameViewerFs(viewer, 1)`, `ColorCycle` (empty), frame counter
viewer+0xBA = (+1) mod 8, `AdvanceDisplacementFilters`, `CloseDistantWindows` (when 0x100d53b8),
`YieldToAnyThread()` (m:10843–10857). TOC aliases (scan of every TOC word for the data offsets):
0x100cdd74 lock-out-UI counter, 0x100cdd84 mode, 0x100cdd88 anim thread, 0x100cdd8c task thread,
0x100ce4d4 slice counter, 0x100ce4dc last app-pick tick, 0x100ce4e4 wait-until tick, 0x100ce4ec
**next-frame deadline**, 0x100ce4fc `deque<TaskEvent>`, 0x100ce500 kind mask.

### 3.2 `TTaskMaster::TaskThread @ 1001d334` (m:5793–5911) [HIGH]
Forever: throw `bad_alloc` if the emergency reserve is gone; while the queue is empty
`YieldToAnyThread()`; pop a 16-byte `TaskEvent` {short kind, short arg, window, Point, short key};
drop it if its kind's bit is set in the mask (0x100ce500). Kinds (queued by
`ScheduleMouseDown`/`ScheduleKeyDown`/`ScheduleMonster`/`ScheduleSkill`, p:7790–7850, each then
`SetThreadState(task, ready)` + `YieldToAnyThread`):
| kind | action |
|---|---|
| 1 mouse | coalesce following mouse events (arg low bits forced to 2), `TDroppableWindow::MouseRoutine(win, pt, arg)` |
| 2 key | `TDroppableWindow::KeyRoutine(win, key)` |
| 3 turn | `TActiveMonster::MoveAll()` (queued when MoveAll is called off the task thread) |
| 4 skill | `FindSkill(leader, key)`; if absent and key ≥ 0xC0, a scratch prop 0x3FFF (kind 0x1C, type = key & 0x3FF) is written; if the prop has property 9: `MakeActive(arg)`, busy-depth++, `TGameSys::DoUse(prop)`, busy-depth−−, restore active, **`HeartBeat(3)`** |
| 5 | clear mask bit `arg` |
Discarded `TickCount()` calls precede kinds 1–3 (dead).

### 3.3 `TTaskMaster::MyScheduler @ 1001cb94` (m:5660–5785) [HIGH as code]
Called by the Thread Manager at each reschedule; returns the thread to run (2 = the application
thread, the event loop). Steps: `CheckSanity`, `HandleISPseudoMouse`; first call sets `next =
TickCount()`; **spin while `TickCount() < waitUntil`** (m:5715); if the anim thread is not ready →
app. Else: conversation window up → keep the current thread; any window needs redraw → app;
mouseDown/keyDown pending (`OSEventAvail(10)`) and UI not locked → app; app in background → app;
mode 2 and slice counter < 1 → counter = 1, run task thread; mode 1 and queue non-empty → task;
mode 0, current ≠ task and suggested ≠ anim → task; otherwise the frame path: in mode 3 with
`now < next` set `waitUntil = next` and spin to it (m:5740–5744); if still early (mode ≠ 3) or the
anim thread is current → app; else **advance `next` by `(DAT_100d3e20 >> 2 & 0xf)` ticks** (from
`next` if early, from `now` if late, m:5753/5756), counter−−, mode 3 → 2, **run the anim thread**.
The field is read with `lbz r0,0(r26)` (r26 = 0x100d3e20) and `rlwinm r0,r0,30,28,31` (`ppcdis.py
1001cb94 1001ced8`), i.e. byte 0 bits 2–5. Consequence and per-speed numbers: engine-classes.md
§3.4. `TAdjustTaskMaster::dt @ 1001cb0c` restores the saved mode word (`*_DAT_100cdd84 = *param_1`)
— an RAII mode guard.

---------------------------------------------------------------------------------------------
## 4. Menus and commands

### 4.1 Menu bar [HIGH]
`TApp::ChangeMenuBar(0x80) @ 1000bfe4`: `ClearMenuBar`; `MBAR 128` = [128, 129] each →
`TCommandMenu::CreateMenu(id, 0)`; `MBAR 129` = [135] → `CreateMenu(id, -1)` (hierarchical); Apple
menu (id 1 or 0x80) item count → +0x38, `AppendResMenu('DRVR')` when < 5 items. Resources: MENU 128
Apple (About Cythera…), CMNU 129 File, MENU 135 Strategy (Edit User Strategies…).

### 4.2 Commands — `TApp::HandleCommand` → window → `TDelverApp::DefaultCommand @ 10015888` [HIGH]
A command word is (menu << 16 | item); `TCommandMenu::GetCommand` maps it to a command number via
`CMNU 129`; the target is the modal window (+0x30) or the target window (+0x70) or the front layer;
order: window CommandRoutine (+0x20) → window MenuRoutine (+0x1C) → app DefaultCommand (+0x1C) →
app DefaultMenu (+0x20); then `HiliteMenu(0)`. CMNU 129 (bytes: title, then per item pstring +
icon/key/mark/style + u32 command):

| File item | cmd | `DefaultCommand` action |
|---|---|---|
| Open Game ⌘O | 3 | ALRT 134 (Save / Cancel / Don't Save before closing) → `DoOpen` → `OpenAndSetPlayerFileFromFS`, log "[Game Opened]" |
| Close Window ⌘W | 1000 | beep if TOC 0x100cdcc8 ≠ 0; ignored with a modal up; else the first window with a close box (`win+0x70`) → CloseRoutine (+0x24) |
| Save ⌘S | 5 | `DoSave(1, 0)`, log "[Game Saved]" |
| Save As… | 6 | `DoSaveAs(1)` |
| Backup As… ⌘B | 0x6A | `DoSaveAs(0)` |
| Revert To Saved ⌘R | 7 | ALRT 135 → reopen the current file (`_DAT_100cdd44`), log "[Game Reverted]" |
| Preferences… | 750 | `DoPrefs()` (§7) |
| Quit ⌘Q | 10 | `TApp::DefaultCommand`: quit flag = vslot +0x7C **DoQuit** |
There is **no New Game command**; a new game starts only from the start screen (§5.1).

### 4.3 `TDelverApp::DefaultMenu @ 10015b10` (m:4888–5004) [HIGH as code]
- (0x80, 1) → `DoCredits()`.
- **0x88 = MENU 136 "Preferences"**: 1/2 container placement (byte 0 bit 6 set/clear); 4 Live
  Dragging (toggle bit 0, copy to app +0x67..69); 6/7/8 movement (`& 0x7d | 0x82` / `| 0x80` /
  none); **10/11/12 → `DAT_100d3e20 & 0xc3 | 0x10 / 0x18 / 0x20`** (item texts "Limit to 16 / 10 /
  8 FPS"); every branch then `SavePrefs("UI Prefs", word, 4)`.
- 200 Party: item 1 "Party Mode" → party flag (0x100cdbe8) = 1, leader (0x100cdbec) = 1; item n ≥ 3 →
  flag 0, leader = party slot table (0x100cdbe4)[n − 3]; then `RebuildParty`, viewer redraw.
- 0x83 = MENU 131 "Audio": 1 System Volume → `SetSoundVolume(-1)`; 2..10 → volume 0..8; 12
  ambient toggle by its mark; 14..17 → `SetMusicVolume(0..3)`.
- else `TApp::DefaultMenu` (desk accessories for Apple-menu items past +0x38; Edit → `SystemEdit`).
**Menus 0x83 and 0x88 are never inserted in 1.0.4** [MED: absence scan]: MBAR 128/129 hold
128, 129, 135; the only `InsertMenu` sites are TCommandMenu (MBAR ids), `GetMenu(0x86)`
(p:11422), `GetMenu(0x89)` (m:13377), status-window `NewMenu(5000+i)` (p:14984) and a popup helper
(p:15133) (`grep -n 'InsertMenu(\|GetMenu(0x8' …` over the three dumps). So `GetMenuHandle(0x88)`
is NULL, PostInitMac's check-mark block never runs and the 0x88/0x83 branches cannot be reached
from a menu selection: 1.0.4 has the preferences window (§7) instead.

---------------------------------------------------------------------------------------------
## 5. New game, open, save, quit

### 5.1 Start screen `TRunStart` (DoStartup → `RunStart @ 1001725c`) [HIGH]
`RunStart` disables MENU 0x81 (File), runs `TRunStart` with vslot +0x2C MoveableModal, then either
sets the quit flag or (a file was chosen, +0x52) creates the windows and `OpenPlayerFile(spec, 1)`.
Ctor (p:5601): `'nrct' 128` (Cythera Data.rsrc; 8 rects: buttons 0–2 at x 166–317, y 102/179/255,
buttons 3–5 at x 430–581, rect 6 (19,279,47,465) player name, rect 7 (0,0,155,88) animation),
PICT 132 background, PICT 133–138 animation frames, `TPrefs::GetFile("CurPlayer")` → last saved game
(+0xB8 = found). Buttons → `DoItemHit(n)` (p:5720):
| n | key(s) (`KeyRoutine @ 10016690`) | action |
|---|---|---|
| 0 | G g Return Enter | play the CurPlayer file (needs +0xB8 and `CheckPlayerFile`): fade, end modal |
| 1 | N n | `NewGame` (§5.2); success → set CurPlayer, end modal and play |
| 2 | O o | `DoOpen` → set CurPlayer, show name, then item 0 |
| 3 | P p | `DoPrefs` |
| 4 | A a | `DoCredits` |
| 5 | Q q Esc | quit: end modal + quit flag |
| — | X x | re-roll the footer index (+0xBA = `Random()` mod 8, different) and redraw |
`MouseRoutine @ 100169fc`: hit-test the six rects (button 0 only when +0xB8), interface sound 6,
track with `StillDown` drawing PICT 139+n (pressed) or the background, sound 7, hit on release.
`IdleRoutine @ 10016c68`: every 5 ticks frame = (frame+1) mod 7 into rect 7 (frame 0 = background).
`DrawRoutine @ 10016f84`: background, name, PICT 145 over button 0 when no file, footer at
(10, bottom−10): unregistered → "Not Registered"; registered → index 0 "Registered To: " + name,
else one of 7 jokes at 0x100d4280 (`toc.cstr_code`). `CloseRoutine @ 10017180` releases the
background PICT seven times and never the frames — the loop tests `+0x98+i*4` but loads
`lwz r3,148(r30)` (= +0x94) (`ppcdis.py 100171c0 1001722c`). [HIGH; harmless]

### 5.2 New game and character creation [HIGH unless marked]
`NewGame @ 100152a4` (p:5458): vslot +0x6C **PutOneFile**("Create Player:", default name
"Bellerophon", &replacing); delete a replaced file; `TSegFile(spec, 'Delv', 'DelP')`;
**`CreatePlayer()`**; on success `SaveSegment(0xF009, CharEntry table, 0x4000)`, copy the 0x80-byte
scenario header and put the save-file name (≤ 0x1F) at +0x20, `WriteHeader`, then a resource fork
with an `'SCEN' 0x80` alias to the scenario file (alert "Could not make alias to scenario" on
failure). The file is deleted if anything failed.
`CreatePlayer @ 100a18c4` runs **`TCreatePlayerDialog`** (DLOG/DITL 133) modally:
| item | role (DITL 133 text) | code |
|---|---|---|
| 1 / 2 | OK / Cancel | result +0xC = 1/0, end modal (`DialogItemRoutine @ 100a140c`) |
| 3 | portrait list (`TPortraitList`, 64×64 cells) | `LDEFDraw @ 100a06f8`: segment `cell.v + cell.h*6 + 0x88EF`, `LZUnpack`, `CopyBits` |
| 5 / 6 | Male / Female radios | +0xE = 1/0; `LScroll(∓1, 0, list)` shifts the portrait list one column |
| 7 | archetype list (`TArchetypeList`, names from segment 0x203) | click → `AdjustCurArch(sel)` |
| 8 / 9 / 10 | description / Attributes / Aptitudes | `TETextBox` of segments 0x204 / 0x205 / 0x206 entry `sel` |
Each of 0x203–0x206 is `Decrypt`ed and indexed as u16 count (`& 0xfff`) + u32 offsets (low 16 bits).
On OK: portrait index p = visible.top + visible.left × 6 (`GetPortrait`, +0xF0); segment
**0x87FF + p + 0xF0 = 0x88EF + p** is copied to the save as **segment 0x8800**; then
`DoInterp(sel 0, receiver VAddr 0x40400001, arg = *(Male ? TOC 0x100cde70 : 0x100cddec), archetype)`.
[HIGH as code; the two VAddrs are 0 in the static data (`toc.tocval` → 0x7736c/0x77370, words 0) —
set at run time, MED; what script runs = script-library territory]

### 5.3 Open / save dialogs [HIGH]
`TApp::GetOneFile @ 1000ff8c (spec, nTypes, types, preview, prompt)`: with Navigation Services
(+0x18): `NavGetFile` with `'open' 128`, the type list in a handle, option flags `& ~0x80 | 6`
(`| 0x46` with preview, `| 1` for one type), event proc `MyNavEventProc` (routes update → +0xA4 and
null → +0x88 to the app while the dialog is up), filter `MyNavFilterProc` (only listed types; it
compares the file type at +0x18 of the info block); the menu bar is shown for the dialog and
re-hidden after. Fallback `StandardGetFile`/`StandardGetFilePreview`. `PutOneFile @ 100103c4`:
`NavPutFile(…, type '????', creator = GetAppSignature)`, `NavCompleteSave`; reports "replacing";
fallback `StandardPutFile`. Signatures: `TApp` `'????'`, `TDelverApp` `'Delv'`. `DoOpen`
(p:5426): GetOneFile for type `'DelP'`, prompt "Select Player File", preview on; same file as current
→ true; else `CheckPlayerFile`.

### 5.4 Finder open, quit [HIGH]
`TDelverApp::OpenFromFS @ 10014ef8`: type `'DelP'` and `CheckPlayerFile`: no game open → `InitWorld`;
if unregistered (`FUN_100b8f80` registration check, resource 900) the registration reminder runs
between `ShowMenuBar`/`HideMenuBar(1)` [MED: `FUN_100b9064` not read]; `SetFile("CurPlayer")`,
`CreateWindows`, `OpenPlayerFile(spec, 1)`. Game open → ALRT 134 then `OpenAndSetPlayerFileFromFS`.
Other types → DoStartup. `HandleQuitApplication @ 1000c3b4`: quit flag = DoQuit; returns −128
(userCanceled) when refused. `TDelverApp::DoQuit @ 10013a58`: with a game open — refuse during a
conversation; ALRT 129 "Save Game before Quitting?" (1 Save → `DoSave(0, 1)`, 2 Cancel → refuse);
then save the map window's global rect as `"Map Window Loc"` (8 B), `TAudio::Halt`,
`NukeScratchFile`, hide all windows, `SwitchedAndGone`, CD-audio shutdown when it was started.
`HandleDisplayNotice @ 1000c4f8`: for each display in `'dspl'`, old/new `'dddr'` rects and the
`'dmdd'` device → DoMonitorChanged → each overlapping window's HandleMonitorChanged (+0x54).

---------------------------------------------------------------------------------------------
## 6. Small classes [HIGH]
- `TMemoryStream` (+8 base, +0xC pos, +0x10 end): `SetPos` = base + n; `GetSize` = end − base;
  `Align(n)` rounds pos up to a multiple of n; `Read`/`Write` `BlockMove` + advance. **`ReadTo(buf,
  &len)` copies into `&len`, not `buf`**: `addi r31,r5,0; mr r4,r31; lwz r5,0(r5); lwz r3,12(r3);
  bl BlockMove` (`ppcdis.py 10018664 100186c0`). Callers not traced.
- Pixel cache: `TPixCacheFromCachedSegFiles::GetData(i)` = `GetSegment(i + 0x8F00)`; `DoneData` →
  `TCache::Free(p, 1)`; `TPixCacheBase::DoneData`, `TCache::WriteBlock` empty.
- Sound callbacks: `PlayOnceCB` unlocks on states 1/2; `LoopSpotCB` re-queues on 1, unlocks on 2;
  `LoopCB` refreshes the two per-channel levels from tables (0x100ce444/440), stops when both are 0,
  re-queues otherwise, state 3 → `FUN_100b80f4`. `TAudio::dt` → `GMSQuit`, unlock queue.
- Interpreter exceptions `XInterp` and `XIInvalidOpcode/Segment/VAddr`, `XIEndGame`, `XIRaise`: dtors
  only (vtables 0x100d6940 base). `VAddr::ct` = 0; `THeapDict::mappingentry::ct` sets +4 = 0.
  `RemoveConsole`, `TApp::{DoStartup, OpenFromFS, LowOnMemory, PostInitMac, Modeless, CenterWindow,
  AlignWindowTo, ShowErr, FatalErr, WarnErr, Log}`, `TDelverApp::Log` are empty.
- `TApp::RelativeMoveWindow`: centre a window on the main device scaled by `ScalePt`.
- Credits objects (`DoCredits`, main dump): `TFadeInTextImageObject::Tick` renders once via its
  Render slot (`TStringFadeInTextImageObject::Render`: word-wrapped with `StyledLineBreak`, centred
  vertically, colour 0x111) then multiplies three 16-bit levels by 6/5 from 0x400 up to 0xFFFF;
  `Apply` dissolves with `DisBits(…, tick*10, …)` until done, then `CopyBits`.
  `TScrollingCreditImageObject::Tick` scrolls 1 px per tick and asks `RenderNextLine` for a new line
  when its countdown ends; `TSTRScrollingCreditImageObject::RenderNextLine` takes the next `STR#`
  item (wrapping to 1): `-` = 6-px gap, a line starting 0xA5 is drawn in colour 0x111 offset left of
  centre, others centred in colour 0x45.

---------------------------------------------------------------------------------------------
## 7. Preferences window and persistence [HIGH unless marked]
`DoPrefs @ 100a3a9c` builds a `TApPrefWindow` (0x214×0x118, centred above the bottom 0x90 px) and
runs it with MoveableModal. Content (`AddContent`, p:50941; labels from TOC strings 0x100cef04…
0x100ceee4): Sound (slider `'svol'`, Mute `'smut'`, System Volume `'ssys'`), Music (slider `'mvol'`,
mute `'mmut'`), Game Control ("Set Controls…" → `'iscf'` InputSprocket), Graphics Quality (3-step:
Better Performance … Better Quality), Walk around obstacles, Motion Filters, Miscellaneous: Ambient
Sounds (`'ambs'`), Live Dragging, Manually Place Containers, Use 'ZoomRects'; Save / Cancel.
`HandleMessage @ 100a36f4`: slider/mute/system/ambient messages recompute `AudioSettings`
{u8 ambient, i16 music, i16 sound (−1 = system, 0 = mute)} and **apply immediately**
(`SetSoundVolume`/`SetMusicVolume`/`EnableAmbient`) with interface sound 5; `'canc'` re-applies the
settings captured on open (+0x74) and ends the modal; `'save'` ends it and `SaveSettings`.
`KeyRoutine @ 100a3578`: Esc → `'canc'`, Return/Enter → `'save'`, `i` → `'iscf'` (if InputSprocket).
Storage (`TPrefs`, p:3837–4140): file named by STR 128 "Cythera Preferences" in the Preferences
folder (`FindFolder(kOnSystemDisk, 'pref')`, created as type `'pref'` creator `'????'`), holding
**named `'Pref'` resources**; `LoadPrefs` uses `GetNamedResource`, so the app's own `Pref 128
"Volume"` = 5 and `Pref 129 "Music"` = 2 act as first-run defaults. Keys: "UI Prefs" (4 B, the word
of data-format.md §8), "Volume"/"Music"/"Ambient" (u32 ordinals; defaults 5 / 8 / 1 in code),
"Backdrop" (ordinal, default 0), "Map Window Loc" (8 B rect), "CurPlayer" and "CurScen" (aliases).
`GetOrdinal` returns the stored value only when `size >> 2 <= idx + 1` (inverted bound; every
caller passes idx 0, so harmless). `SaveSettings` writes the UI bits listed in data-format.md §8.

---------------------------------------------------------------------------------------------
## 8. AI tools (summary; detail in ai-scripts.md §9)
`EditUserBehaviors` (Strategy menu / character-window popup) runs `TEditUserBehavior` (DITL 141:
Done, Import, list, Debug); `PerformAI` opens `TAIDebug` (DITL 142: Step, Clear Debug, list, Go)
when the slot's debug flag is set.

## 9. Open
- Who inserts MENU 200 "Party" (only `GetMenu(200)` reads at p:764/p:1964 were seen). [NOT RESOLVED]
- `FUN_100b9064` (registration reminder) and `FUN_100bebec/bed54/bee50/becb0` (CD audio) not read.
- Which exception type each `main` catch handler takes (§1.1). [MED]
