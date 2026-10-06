# Cythera 1.0.4 — census of the 840 missing-dump bodies (wave 2 triage)

⚑ wave 2 (2026-10-06) — new file. Classification only: which bodies exist, what each family does
(from skimming, labelled), which bank each belongs in, which open items they touch, and how wave-2
readers split them. No rule is banked here; the readers bank. Line numbers `m:NNNN` are lines of
`ghidra/Cythera_missing.decompiled.c` as regenerated this session (23,585 lines).

## 0. Provenance and grouping

Dump recipe: INDEX.md provenance row **missing dump** (`CyDecompAt.java` over
`docs/cythera/tools/missing-addrs.txt`, 840/840). `LEN` in `missing-addrs.txt` is hex.

```sh
grep -o '^// ==== .* @ [0-9a-f]*' ghidra/Cythera_missing.decompiled.c | sed 's,^// ==== ,,' > names.txt   # 840
python3 docs/cythera/tools/demangle.py names.txt counts   # TApp 33 … 178 <free functions> (orchestrator's counts)
grep '^// ==== Builtin_' ghidra/Cythera_builtins.decompiled.c | sed -E 's/^\/\/ ==== (Builtin_..) @ ([0-9a-f]+).*/\2/' > bi.txt
python3 - bi.txt <<'EOF'      # class → rows, bytes (prints 840 158680)
import re,sys,collections
bi=set(open(sys.argv[1]).read().split()); R=collections.Counter(); B=collections.Counter()
for l in open('docs/cythera/tools/missing-addrs.txt'):
    if l[0]=='#': continue
    a,n,s=l.split(); s=s.lstrip('.')
    m=re.match(r'(.*?[^_])__(\d+)(\w+)',s); q=re.match(r'(.*?[^_])__Q215TScriptedWindow7TWidget',s)
    k=('BUILTIN' if a in bi else 'STD' if re.match(r'(__dt__|__ct__|what__)Q23std|__arraydtor',s)
       else 'TScriptedWindow::TWidget' if q else re.sub(r'<.*','<*>',m.group(3)[:int(m.group(2))]) if m
       else s.split('__Q2')[0] if '__Q2' in s else 'FREE:'+s.split('__')[0])
    R[k]+=1; B[k]+=int(n,16)
for k in sorted(R,key=lambda k:-B[k]): print(R[k],B[k],k)
print(sum(R.values()),sum(B.values()))
EOF
python3 docs/cythera/tools/ppcdis.py 10000000 100cd280 > all.dis     # 212,074 lines; used by the §2 scans
```
(`__ct` 2/24 in that output = `__ct__Q25TToDo9ToDoEntryFv` @ 10077A44 and
`__ct__Q29THeapDict12mappingentryFv` @ 100AA448, 12 B each.)

**Counts vs the orchestrator's probe.** Total 840 rows / 158,680 B — agrees. Class counts agree
(TApp 33 … TStatusWindow 11; TScriptedWindow 16 counts `DispatchCommand__15TScriptedWindowFPQ2…TWidget`;
TInteraction 16 likewise). One correction: nested `TScriptedWindow::TWidget` is **17** rows (16 methods
+ its own `__dt__Q215TScriptedWindow7TWidgetFv` @ 1003B41C). The 178 "free functions" of `demangle.py`
= 95 builtins + 41 std + 17 `TWidget` + 2 nested ctors + **23** true free functions.

| family (→ §1 block) | rows | bytes | treatment |
|---|---|---|---|
| A script builtins (`cb…`, `RangeIter`, `EachIter`) | 95 | 23,544 | already read (wave 1); names only → §4 |
| B std-library template ctors/dtors/`what` | 41 | 4,564 | census only |
| C app shell, scheduler, prefs, AppleEvents, AI tools, credits | 125 | 30,876 | read (game pacing lives here) |
| D play windows (character, status, map, inventory, journal, to-do) | 92 | 25,280 | read |
| E conversation + interaction modes | 71 | 15,788 | read |
| F scripted windows + `TW*` widgets + registrars | 128 | 18,292 | read |
| G missile / line FX + viewer audio | 13 | 1,760 | read |
| H UI toolkit (appearance adapters, CDEF/WDEF/LDEF, list box, dialogs) | 275 | 38,576 | census only — identify, do not bank in depth |
| **total** | **840** | **158,680** | new non-builtin non-std code = 130,572 B |

## 1. Group table

Role label: **HIGH** = whole body read; **MED** = the two largest bodies skimmed (calls, constants,
strings); **LOW** = name and callee list only (`.debug::` callees per group, this session). "Items" =
NOT RESOLVED number / review note, only where a body touches it (line cited).

### C — app shell (bank: NEW `app-shell.md`; AI tools → `ai-scripts.md`)
| group | rows/B | largest | role | label | items |
|---|---|---|---|---|---|
| `TApp` | 33/7,808 | InitMac @1000CAF0 1264; GetOneFile @1000FF8C 968 | Toolbox init + Gestalt probes (`'qd  '`, `'thds'`, `'evnt'`), Nav file dialogs, main event loop `MEL` @1000D6C4 (idle every `TApp+0x3C` ticks, m:3205–3213) | MED (MEL HIGH) | 16 |
| `TDelverApp` | 18/6,856 | PostInitMac @1001215C 2112; DefaultMenu @10015B10 1432 | game app: registers `'ScrW'`/`'ChrW'` stream classes, opens data files, loads the 4-byte prefs word `DAT_100d3e20` (CPU-based default, m:4333–4356), Options menu 0x88 sets its bits, party menu 200, volume menu 0x83; `MyGetEvent` @10012C24 synthesises a space keyDown every 0x14 ticks (m:4569–4578) | MED (DefaultMenu, MyGetEvent HIGH) | 16 |
| `TTaskMaster` (+`TAdjustTaskMaster` dtor) | 3/2,496 | TaskThread @1001D334 1572; MyScheduler @1001CB94 836 | **game thread**: pops `TaskEvent`s — 1 mouse, 2 key, 3 `MoveAll`, 4 use skill (`FindSkill`→`DoUse`→`HeartBeat(3)`), 5 clear mask bit; the Thread-Manager scheduler busy-waits on TickCount and spaces turns by `DAT_100d3e20 >> 2 & 0xf` ticks ⚑ corrected (review wave 2 2026-10-06): it spaces **animation frames**, not turns (engine-classes.md §3.4, m:5753/5756) | HIGH | 16 |
| `TRunStart` | 6/2,164 | MouseRoutine @100169FC 568; KeyRoutine @10016690 520 | start screen: 6 PICT buttons, keys → `DoItemHit(0..5)` | MED | — |
| player creation: `TCreatePlayerDialog`, `TArchetypeList`, `TPortraitList` | 10/2,088 | DialogItemRoutine @100A140C 460; LDEFDraw @100A06F8 412 | new-character dialog (radio items 5/6, archetype list, 64×64 portraits from `GetSegment`) | MED | — |
| `TApPrefWindow` | 3/1,304 | HandleMessage @100A36F4 872; KeyRoutine @100A3578 332 | audio prefs window; messages `'mvol'`, `'ambs'`, `'canc'` → Adjust/ApplySettings; InputSprocket config | MED | — |
| AI tools: `TEditUserBehavior`, `TAIDebug`, `TAIList` | 12/2,424 | TAIDebug::DialogDrawRoutine @100ADA9C 564; TEditUserBehavior::DialogItemRoutine @100B1780 364 | user-AI editor (list row → `CompileAIFile(spec, row + 0xb0)`, m:23502) and AI debug window (`GetCombatAIName`, portraits) | MED | **14** |
| audio: `TAudio` dtor, `PlayOnceCB`, `LoopSpotCB`, `LoopCB` | 4/644 | LoopCB @1001AE7C 276; TAudio dtor @1001B00C 152 | Sound-Manager completion callbacks (`QueueUnlock`), audio shutdown (`GMSQuit`) | MED | 19 (context) |
| OS glue: 4 AppleEvent handlers, `MyGrowZone`, 2 Nav procs, `RemoveConsole`, `TAudit::AuditStartup` | 9/1,520 | HandleDisplayNotice @1000C4F8 412; HandleOpenDocuments @1000C228 356 | `'aevt'` odoc/oapp/quit/notice, grow-zone purge, Nav filter; out of scope per INDEX | MED | — |
| interpreter exceptions `XI*`, `XInterp`, `VAddr`, `THeapDict` entry ctor | 8/608 | XIInvalidOpcode … XIRaise @100807C8… 100 each | exception-object dtors only (no VM logic) | MED | 21 (no) |
| `TMemoryStream`; caches `TCache`, `TPixCacheFromCachedSegFiles`, `TPixCacheBase` | 10/500 | ReadTo @10018664 92; DoneData @100742A0 84 | `BlockMove` stream; pixel-cache segment fetch/free | MED | — |
| credits: `TImageObject`, `TFadeInText…`, `TStringFadeIn…`, `TScrollingCredit…`, `TSTRScrolling…`, `TImageCompositor` | 9/2,464 | TFadeInTextImageObject::Tick @1009D9AC 516; ::Render @1009E0EC 500 | GWorld fade-in / scrolling text (`GetIndString` lines) | MED | — |

### D — play windows (bank: NEW `ui-play.md`)
| group | rows/B | largest | role | label | items |
|---|---|---|---|---|---|
| `TCharacterWindow` | 14/7,912 | CanDrop @1002DCF8 2504; MouseRoutine @1002F104 2068 | equip-slot legality by property 0x26 (slots 0–9, "Not a ring", "Needs both hands" strings), tabs (inventory/wield/skills), **tactic radio buttons write CharEntry +0x1E**, user-AI popup → `EditUserBehaviors` (m:7293, m:7307) | MED | **14**, N3 (sel 8) |
| `TStatusWindow` | 11/4,284 | MouseRoutine @100352A0 1644; DrawRoutine @10034708 628 | command buttons → `DoUse` of class-0x50 prop 0x3FFF typed `0xFF − refcon` then `HeartBeat(0)` (m:8061–8073); F1–F10 macro slots → `DoInterp(2)` + `ScheduleSkill` (m:8112–8117); party portraits | MED | N3 (sel 2) |
| `TMapWindow` | 17/3,124 | PointToProp @10042D8C 564; PointToCoordinate @10042BDC 368 | click → cell (32-px cells; refuses while the leader is mid-slide under smooth movement, m:10656–10664), drop/throw targeting, resize, colour cycling | MED | — |
| inventory: `TInventoryWindow`, `TInventoryList`, `TInventoryPile`, `cmpprops` | 11/2,064 | DrawRoutine @1003254C 396; CloseAtDistance @100327D8 336 | container windows close when the player is > 1 cell away (m:7701); backing-store redraw; `cmpprops` sort = type, then byte-4 bits 2–6, then byte 6 — its second byte-4 test repeats the first (m:8424–8428) | MED (`cmpprops` HIGH) | — |
| `TDroppableWindow` | 13/1,336 | GetGesture @10026AA8 672; CanSearch @10025C84 480 | click/drag/double-click gesture timing (`LMGetDoubleTime`); search reach = adjacent cell not walled (`GetTileBits` bits 4/8/0x600/0x2000/0x4000, m:6079–6097) | MED | — |
| skills: `TAbilityList`, `cmpskills` | 3/1,528 | LDEFDraw @1002ABDC 1292; cmpskills @1002BB64 136 | skill list rows: name via `DoInterp(2)` on class-0x50 object, F-key tag via `SkillToFKey`; sort by type | MED (`cmpskills` HIGH) | N3 (sel 2) |
| `TBackdropWind` | 5/572 | HandleMonitorChanged @100385CC 244 | full-screen backdrop over all main-screen devices | MED | — |
| journal: `TJournal`, `TJournalList` | 8/2,808 | MouseRoutine @10078BA4 1480; LDEFDraw @10078100 728 | journal list ("Day %d", "%s said"), menu 0x89, `MakeNote`, `TJournalSegment` read/write | MED | — |
| to-do: `TToDo`, `TToDoList`, `ToDoEntry` ctor | 10/1,652 | MouseRoutine @100773E8 420; LDEFDraw @10076A44 560 | quest to-do list; details via `VAddrToPtr` of id + 0x400; "This task is done/not yet completed" | MED | — |

### E — conversation and interaction modes (bank: NEW `dialogue-ui.md`; dialogue.md is FULL)
| group | rows/B | largest | role | label | items |
|---|---|---|---|---|---|
| `TConversation` | 14/3,552 | WriteJournal @1003C628 508; myprintstr @1003D054 436 | conversation window text: `*` = page break (`ConvMore`), `"` toggles speech vs narration (m:9329–9353); journal button writes said/heard text | MED | — |
| `TInteraction`, `TSimpleInteraction` | 18/1,900 | DrawRoutine @1003BD48 496; Hide @1003BBC4 288 | modal interaction panel host (GWorld bevel copy, keyboard disable, `Perform`) | MED | — |
| `TConvResponseMode` | 6/2,548 | MouseRoutine @1003E378 844; KeyRoutine @1003E8EC 780 | answer choice / typed keyword (TE field, Return/Enter → `Done`, letter hot-keys) | MED | — |
| `TPickMode`, `TScriptPickItemDrawer` | 7/4,564 | MouseRoutine @10040200 1672; DrawItem @100961A4 1460 | pick-an-item list (rows drawn from script values via `TInterp::At`, tile icons 32×32) — UI of `cbPickItem` | MED | — |
| `THowManyMode` | 5/1,464 | MouseRoutine @10041644 664; KeyRoutine @10041A78 428 | quantity slider: arrows ± step, Esc = min, Return = done — UI of `cbhowmany` | MED | — |
| `TConvMoreMode`, `TConvMode`, `TModalMode`, `TTextOut`, `TBark` | 21/1,760 | TTextOut::LDEFDraw @10039480 544; TConvMoreMode::MouseRoutine @1003CCE4 224 | "MORE" wait, base mode (`WantAutoKey` returns 1, m:9208), modal forwarder, text-log list, bark dtor | MED | — |

### F — scripted windows and widgets (bank: NEW `scripted-windows.md`)
| group | rows/B | largest | role | label | items |
|---|---|---|---|---|---|
| `TScriptedWindow` | 16/2,276 | Marshal @1008F5F0 328; CloseRoutine @10086340 208 | script-built window: close sends selector 1 to its owner (m:13827–13828); saved as `'ScrW'` chunk | MED | N3 (sel 1) |
| `TScriptedWindow::TWidget` | 17/464 | KeyRoutine @10087854 168; dtor @1003B41C 84 | widget base: key letter matching (upper→lower), field get/set, drop hooks (stubs) | MED | — |
| `TWText`, `TWScrollText`, `TWTextEntry` | 21/4,628 | TWText::Draw @1008872C 1020; TWScrollText::MouseRoutine @1008A0E4 488 | text widgets; fields 0x37/0x3C/0x3D/0x40/0x41 (m:14510–14535) | MED | — |
| `TWPixButton`, `TWPix`, `TWIcon`, `TWButton`, `TWControl` | 25/4,904 | TWPixButton::SetField @1008BF64 520; ::MouseRoutine @1008C1A0 448 | picture/button widgets; clicks → `DoInterp(-1, …)` widget method | MED | N3 (sel −1) |
| `TWList`, `TWListList`, `TWInvent` | 24/3,208 | TWList::MouseRoutine @1008E7F4 372; TWInvent::CanDrop @1008DAE0 344 | container widgets: drop asks owner selector 0x17 "fits?" ("Doesn't fit"/"Put In", m:16152–16159); TWList clicks send 8 and 10 | MED | N3 (sel 8/10/23) |
| `TWMusicBox` | 4/1,088 | MouseRoutine @1008D328 576; Draw @1008D1EC 268 | instrument keyboard: plays `PlayNote`, appends the note nibble to a 28-bit history and sends selector 10 with it (m:15741–15745) | MED | **23** |
| `TWAutoMap`, `TWNumberEntry`, `TWNumber` | 9/1,336 | TWAutoMap::Draw @1008C814 252; TWNumberEntry::MouseRoutine @1008CCB0 204 | auto-map widget (`MagicMap`), number fields | MED | — |
| `TRegistrar<…>` ×15 | 15/1,148 | CreateFromStream @100129CC 80 (each ~76–80) | stream factories (`CreateFromStream` → class ctor from `TStream`) for the window/widget classes whose `Marshal` bodies write tags `'ScrW'`, `'ChrW'`, `'wTxt'`, `'wMus'` … | MED | — |

### G — FX (bank: `magic.md` append)
| group | rows/B | largest | role | label | items |
|---|---|---|---|---|---|
| missiles/showers/lines: `TMissileSpinner`, `TMissileStream`, `TMissileThrower`, `TLineEffect`, `TTileShower`, `TCircleShower`, `TBurstShower`, `TStraightBres`, `TBres` | 10/1,228 | TMissileSpinner::DoBresPixel @1005ECC8 264; TLineEffect::DoBresPixel @1009930C 248 | per-pixel missile steps redraw via `DrawRoutine__11TGameViewerFs(…, 2)` (m:11285); `TLineEffect` marks each character on the line (m:19361–19368) | MED | 16 |
| `TGameViewer` (`RenderMissiles`, dtor), `TViewer::RenderMissiles` stub | 3/532 | RenderMissiles @1005E4F8 428 | despite the name: missile object tick + `PostProcessSounds` + ambient-sound placement per frame (m:11184–11208) | MED | 16 |

### H — UI toolkit (bank: NEW `ui-toolkit.md`, census only)
| group | rows/B | largest | role | label |
|---|---|---|---|---|
| `TAppearanceAdapter`, `T7Adapter` | 50/4,492 | T7Adapter::NewSlider @1000355C 244; TAppearanceAdapter::NewStaticText @10000E24 264 | Appearance-Manager vs System-7 control factories (`NewControl` / `T7*Widget` ctors) | MED |
| `TApWidget`, `T7Widget`, `T7ControlWidget`, `T7SliderWidget`, `T7LabelWidget`, `T7GroupBox`, `T7IconWidget` | 53/4,312 | T7Widget::Embed @100012C0 492; T7ControlWidget::FindWidgetUnderMouse @10001DD0 180 | widget tree, hit-testing, label/group drawing | MED |
| `TApWindow`, `TAppearanceMenu` | 7/724 | MouseRoutine @10003F4C 336 | adapter-window event forwarding | MED |
| `TWindow` | 24/4,288 | HandleDragWindow @1000A404 996; Select @1000B384 496 | window layers (`FindLayer`), drag, select/send-behind | MED |
| `TDialog` + dialog procs (`MyDrawDialogItem`, `DelverDialogerRoutine`, `MoveableDialogerRoutine`, `ExactMatchRoutine`) | 13/2,328 | DelverDialogerRoutine @1007305C 668; MoveableDialogerRoutine @1000EFB4 328 | dialog filters, edit-menu keys, button flash `Delay(8)` | MED |
| `TListBox`, `MyLDEF`, `myListSearch` | 20/5,220 | Key @1006DA58 1120; DrawIntoPort @1006E474 652 | List-Manager wrapper (keyboard selection, drawing) | MED |
| CDEFs: `TCDEF`, `TScrollBarCDEF`, `TEditNumberCDEF`, `TProgBarCDEF`, `TCheck/Radio/PushButtonCDEF`, `TNumberCDEF`, `MyCDEF` | 57/8,348 | TScrollBarCDEF::DrawAPart @100A7D88 1292; MyCDEF @1006E738 1156 | custom controls drawn from pixel-cache art (`PTR_DAT_100cdc64` + 0x6B400 …); `MyCDEF` = CDEF message switch (its `case 0x11:` m:12109 is a CDEF message, not a prop kind) | MED |
| WDEFs: `TWDEF`, `TPixsWDEF`, `TDrawerWDEF`, `TBorderWDEF`, `TThinBorderWDEF`, `MyWDEF`, `TDrawerWindow` | 44/8,132 | TDrawerWindow::HandleResizeWindow @100A5E6C 1044; TPixsWDEF::DrawUnhilited @100A4DCC 1004 | custom window frames, drawer windows | MED |
| menus `MyMenuDef`, `MyMenuHook`, `TCMNU`; savers `TSaveFont/Port/GWorld`, `THandleLocker` | 7/732 | MyMenuDef @100A8360 188 | MDEF, state savers | LOW |
| **B** std templates (41) | 41/4,564 | `__dt__…deque<9TaskEvent…>` @10022C80 168 | `std::` dtors, `what()`, `vector<short>` ctor/dtor, `__arraydtor$2299` | LOW |

## 2. Leads per NOT RESOLVED item

- **5 kind 0x11** — no new body touches it. `grep -c -F "'\x11'" ghidra/Cythera_missing.decompiled.c` = 0;
  prop-kind compares in new bodies (`grep -n -E "\* 0x10\) (==|!=) '"`) are 0x10/0x18/0x1C only
  (TCharacterWindow::CanDrop, ::RenumberChild, cbWorn); the one `case 0x11:` is `MyCDEF` (m:12109).
- **6 0xF005/0xF007** — no new body. `grep -c -i -E '0xf005|0xf007|61445|61447|-0xffb|-0xff9'` = 0 each
  (the wave-1 disasm scan already covered the whole code section).
- **10 PORT** — no new body. `0x504f5254`/`'PORT'` = 0; 4CC census of the dump
  (`grep -o -E '0x[2-7][0-9a-f]{7}\b'`, printable only) finds resource reads `'MBAR'`, `'open'`, `'MemU'`,
  file type `'TEXT'`, widget tags `'w…'`, AE codes — no PORT.
- **14 indirect CompileAIFile/PerformAI callers** — **closable.** No data word equals the code offsets
  0xB0BA4 (`PerformAI`) or 0xB0EF8 (`CompileAIFile`) or 0xB1B38 (`EditUserBehaviors`); TVector words hold
  code-section offsets (control: `RangeIter` 0x83CA8 found at 0x100D05C8):
  `python3 -c "import sys,struct;sys.path.insert(0,'docs/cythera/tools');import toc;D=toc.D;[print(hex(toc.DB+o),hex(v)) for o in range(0,len(D)-3,4) for v in [struct.unpack('>I',D[o:o+4])[0]] if v in (0x83ca8,0xb0ba4,0xb0ef8,0xb1b38)]"`
  → only `0x100d05c8 0x83ca8` (absolute values 0x100B0BA4 etc. also absent).
  So every caller is a direct `bl` (`grep -E 'bl 0x100b0ba4|bl 0x100b0ef8|bl 0x100b1b38' all.dis`): DoMove ×6,
  `100b1854` (TEditUserBehavior::DialogItemRoutine), and `1002f390: bl 0x100b1b38` in
  **TCharacterWindow::MouseRoutine @ 1002F104** (popup value 1 → `_EditUserBehaviors__Fv();`, m:7293; other
  values `… * 0x20 + 0x1e] = (char)sVar9 + -0x53;`, m:7307, i.e. CharEntry +0x1E = value + 0xAD).
- **16 Render order / wall-clock wait** — strong lead for the wait, none for layer order.
  TTaskMaster::MyScheduler @ 1001CB94: `while (uVar11 < *(uint *)puVar7) { uVar11 = .glue::TickCount(); }`
  (m:5715) and `*(uint *)puVar8 = uVar11 + (DAT_100d3e20 >> 2 & 0xf);` (m:5756); TDelverApp::DefaultMenu
  @ 10015B10 menu 0x88 items 10/11/12 set `DAT_100d3e20 & 0xc3 | 0x10` / `0x18` / `0x20` (m:4949–4961) → 4/6/8
  ticks; TaskThread event 3 → `MoveAll` (m:5846); PostInitMac picks the default word by `'cput'` CPU class
  (`toc.py 100d4270 100d4274 100d4278` → 0x18800000, 0x99800000, 0xDBC80000). Render: no `Render__7TViewer`
  among the 840 (`grep -n Render`); only TGameViewer::RenderMissiles (missiles + ambient audio) and the
  missile `DrawRoutine(…, 2)` calls.
- **19 D4 flag** — the name closes the reading: 0xD4 = `cbPlaySoundSync`. Its call passes 1 as
  `PlaySound`'s 5th arg (m:19006–19007); `PlaySound__6TAudioFUsssUcUc @ 1001BE98` (main dump,
  `find_func.py … --file ghidra/Cythera_pef.decompiled.c`): `else if (param_5 != '\0') { do { sVar5 =
  FUN_100b7f40(iVar4); } while (sVar5 != 0); }` — waits for the channel [MED: `FUN_100b7f40` unnamed].
  Its 6th arg (`uVar2`, 1 when the source is outside the viewer range or the viewer cell's low 2 bits
  are 0, m:18990–19004) halves both stereo levels in `PlaySound`.
- **21 0x9C FFFF** — no new body. `grep -c -i '0x9c\b'` = 0; the `XI*` classes are dtors only.
- **22 crystal quality** — no new non-builtin body writes prop byte 6 (`grep -n -E '\+ 6\) = '` → only
  cbaddinv, cbcreateprop, cbRenderAt and non-prop structs); `GetItemQuality` callers are builtins
  (m:17079 cbsetpropowner, m:17333 cbsubinv). The hintbook remains the only lead.
- **23 signals 1/34/35/100+frame/129–135** — no new native sender: `grep -B3 SendSignal all.dis` → `bl
  0x10053794` at 100542F8, 1005CBA0, 1005CC00 (main dump) and 1009844C (cbSendSignal). Lead [MED]:
  TWMusicBox::MouseRoutine @ 1008D328 feeds the instrument scripts — `*(int *)(param_1 + 0x48) << 4 |
  note` then `DoInterp…(auStack_2c,10,uStack_30,uVar4 & 0xfffffff)` (m:15741–15745); the panpipes/lyre
  senders of 129–135 are likely its selector-10 receivers.
- **24 0xF008 byte 7 / flag bits** — no new body: `grep -c 'PTR_DAT_100cdbd8\|ObjToMonst'` = 0.
- **25 egg re-arm / activity restore** — no new body: no `| 0x80`/`^ 0x80`/`& 0x7f` on a prop kind
  (the one `| 0x80`, m:4937, is the prefs byte in DefaultMenu); prop byte 7 written only by cbaddinv
  (m:16982) and cbcreateprop (m:17157).
- **N2 "served"** — no new body sends selector 32 (scan below).
- **N3 native senders** — liftable. Scan: for each `bl` to the four `DoInterp__7TInterpFs…` entries
  (0x10082658, 0x100826F4, 0x100827C8, 0x100828C4; `grep DoInterp ghidra/Cythera_pef.tb.txt`), the nearest
  preceding `li r4,N` within 13 lines of `all.dis`; function = the `missing-addrs.txt` range holding the
  site. Command:
  ```sh
  python3 -c "
  import re,collections;T={0x10082658,0x100826f4,0x100827c8,0x100828c4};h=[];C=collections.Counter()
  for l in open('all.dis'):
      m=re.match(r'([0-9a-f]{8}):\s+\S+\s+(.*)',l)
      if not m: continue
      h=(h+[m.group(2)])[-14:];b=re.match(r'bl 0x([0-9a-f]+)',m.group(2))
      if b and int(b.group(1),16) in T:
          s=[re.match(r'li r4,(-?\d+)',x).group(1) for x in h[:-1] if re.match(r'li r4,(-?\d+)',x)];C[s[-1] if s else '?']+=1
  print(sorted(C.items()))"
  ```
  Totals: 0 (3), 1 (1), 2 (9), 3 (1), 4 (3), 5 (1), 7 (1),
  8 (4), 9 (3), 10 (3), 11 (1), 12 (2), 13 (1), 14 (3), 15–17 (1 each), 20 (4), 21 (20), 23 (2), 24 (1),
  25 (1), 26 (2), 27–28 (3 each), 29 (2), 31 (4), 32 (2), 33 (1), −1 (5) — matches script-library §9
  except 0 (3 vs 2) and −1 (not listed there). New bodies own: sel 1 TScriptedWindow::CloseRoutine; sel 2
  TStatusWindow::MouseRoutine/CursorRoutine, TAbilityList::LDEFDraw; sel 8 TCharacterWindow::MouseRoutine,
  TWList::MouseRoutine; sel 10 TWList::MouseRoutine, TWMusicBox::MouseRoutine; sel 23 TWList/TWInvent::CanDrop;
  sel −1 TWText/TWControl/TWPixButton/TWNumberEntry::MouseRoutine, TWButton::Flash.

## 3. Proposed reader split (disjoint write sets)

| reader | groups | new bytes | writes (owns whole files) | items to carry |
|---|---|---|---|---|
| R1 play | D + G | 27,040 | NEW `ui-play.md`; appends `magic.md` (398, FX §) and `combat.md` (585, one cross-ref § for equip slots / search reach) | 16 (missile redraw), 14 (CharEntry +0x1E popup, cross-ref R3) |
| R2 dialogue + scripts | E + F (+ A names) | 34,080 | NEW `dialogue-ui.md` (dialogue.md is FULL — no write), NEW `scripted-windows.md`; appends `script-builtins.md` (187: adopt §4 names, D4) and `script-library.md` (519: N3 table) | 19, 23, N3 |
| R3 app shell | C | 30,876 | NEW `app-shell.md`; appends `engine-classes.md` (175: TTaskMaster pacing), `ai-scripts.md` (312: item 14 close), `data-format.md` (508: prefs word) | 16 (wall clock), 14 |
| R4 toolkit census | H + B | 43,140 (identify only) | NEW `ui-toolkit.md` (≤ ~200 lines: class → role → one quoted line each) | none — census only, no game-rule content found |

Unowned this wave (no new body touches them): `dialogue.md`, `schedules-npcs.md`, `quests-flags.md`,
`trade-economy.md`. Items 5, 6, 10, 21, 22, 24, 25 and N2 get only the negative results above
(orchestrator → INDEX). The builtin bodies (23,544 B) need no re-reading.

## 4. The 95 builtin names — HIGH (mechanical)

Command: `join` of the builtins dump headers with `missing-addrs.txt` (brief recipe; `join … | wc -l` = 95).
Opcodes 0xA0–0xFE; 0xFF is the null TVector (script-vm.md §8).

| op | name | addr | op | name | addr | op | name | addr |
|---|---|---|---|---|---|---|---|---|
| A0 | `RangeIter` | 10083CA8 | A1 | `EachIter` | 10083DB0 | A2 | `cbEndGame` | 10093F90 |
| A3 | `cbHeartBeat` | 100941F4 | A4 | `cbsetportrait` | 10094258 | A5 | `cbanimatetiles` | 1009430C |
| A6 | `cbrender` | 100943FC | A7 | `cbdeleteprop` | 10094678 | A8 | `cbaddinv` | 10094730 |
| A9 | `cbgetmap` | 10094954 | AA | `cbsetmap` | 1009491C | AB | `cbsetpropowner` | 10094A24 |
| AC | `cbrnd` | 10094BBC | AD | `cbcreateprop` | 10094C80 | AE | `cbwhohas` | 10094E44 |
| AF | `cbgetinv` | 10094FB4 | B0 | `cbcountinv` | 10095118 | B1 | `cbsubinv` | 10095244 |
| B2 | `cbpartychar` | 1009541C | B3 | `cbwhowill` | 10095544 | B4 | `cbhowmany` | 100955FC |
| B5 | `cbgetdigit` | 100956B4 | B6 | `cbwhosaid` | 10095770 | B7 | `cbinvspace` | 100957A8 |
| B8 | `cbgetweight` | 10095868 | B9 | `cbpartyjoin` | 10095918 | BA | `cbpartyleave` | 10095A10 |
| BB | `cbwhichofyou` | 10095AF0 | BC | `cbnearby` | 10095BC0 | BD | `cbpasstime` | 10096058 |
| BE | `cbRecalcLight` | 100991B8 | BF | `cbteleport` | 10098E60 | C0 | `cbPickItem` | 10096798 |
| C1 | `cbAddAbility` | 10096DEC | C2 | `cbRemoveAbility` | 10096E80 | C3 | `cbTempAbility` | 10096F14 |
| C4 | `cbHasAbility` | 10096FB8 | C5 | `cbSendSignal` | 10098418 | C6 | `cbShortName` | 100984A0 |
| C7 | `cbAllProps` | 10097080 | C8 | `cbInventory` | 100971E0 | C9 | `cbWithin` | 100973BC |
| CA | `cbInParty` | 100975B8 | CB | `cbPropsAt` | 100976FC | CC | `cbWorn` | 10097CE8 |
| CD | `cbPropsOf` | 10097B58 | CE | `cbEnemies` | 10098028 | CF | `cbAreaOfEffect` | 10097EDC |
| D0 | `cbMonsterParts` | 10098204 | D1 | `cbInRange` | 100978F0 | D2 | `cbPlayNote` | 1009851C |
| D3 | `cbPlaySound` | 100985C0 | D4 | `cbPlaySoundSync` | 1009874C | D5 | `cbPlayMusic` | 100988DC |
| D6 | `cbPlayAmbientMusic` | 10098994 | D7 | `cbPlayAmbientSound` | 10098A54 | D8 | `cbSetAmbientLight` | 10098BE4 |
| D9 | `cbSetZonePic` | 10098CA0 | DA | `cbSetZoneName` | 10098D78 | DB | `cbShowWindow` | 10098F08 |
| DC | `cbGetQV` | 10098FB0 | DD | `cbSetQV` | 10098FF8 | DE | `cbGetQF` | 1009904C |
| DF | `cbSetQF` | 100990CC | E0 | `cbReschedule` | 1009ABD4 | E1 | `cbCastSpellFX` | 10099720 |
| E2 | `cbMissileFX` | 10099434 | E3 | `cbHitFX` | 100997B8 | E4 | `cbAttackFX` | 10099860 |
| E5 | `cbNext` | 100999B0 | E6 | `cbFadeFX` | 10099AB0 | E7 | `cbScreenFX` | 10099B08 |
| E8 | `cbBeginConversation` | 1009A12C | E9 | `cbEndConversation` | 1009A1B0 | EA | `cbHideConversation` | 1009A090 |
| EB | `cbShowConversation` | 10099FF4 | EC | `cbBeginCutScene` | 1009A234 | ED | `cbEndCutScene` | 1009A354 |
| EE | `cbScrollText` | 1009A40C | EF | `cbSetWaypoint` | 10099CD4 | F0 | `cbQueueAction` | 10099D9C |
| F1 | `cbWaitForFlag` | 10099E78 | F2 | `cbAddToDo` | 1009AA14 | F3 | `cbDoneToDo` | 1009AA98 |
| F4 | `cbAddKeyword` | 10096D54 | F5 | `cbGetSkill` | 1009AB14 | F6 | `cbRenderAt` | 100944D8 |
| F7 | `cbIsLOS` | 10099240 | F8 | `cbCD_Tool` | 1009AEC0 | F9 | `cbNewUniqueName` | 1009AD40 |
| FA | `cbGetNamedProp` | 1009AC8C | FB | `cbGetNamedProxy` | 1009AC50 | FC | `cbEnableAutoMap` | 1009AD94 |
| FD | `cbSetFillColor` | 1009AE38 | FE | `cbDebugStr` | 1009B12C |  |  |  |
