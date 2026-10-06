# Cythera 1.0.4 — the play windows (character, status, map, inventory, journal, to-do)

⚑ wave 2 (2026-10-06) — new file (reader R1, census groups **D** and **G**). Code readings only;
nothing here is behaviour-verified (Ben's eyes are the behaviour oracle). Labels: **HIGH** = whole
body read, every callee named or plain arithmetic; **MED** = an unnamed glue callee, a virtual slot
named from a vtable, or an inferred meaning; **LOW** = from names only; **NOT RESOLVED**. `m:NNNN` =
line of `ghidra/Cythera_missing.decompiled.c`; "main dump" = `ghidra/Cythera_pef.decompiled.c`
(context reads, not part of the 105-body coverage). CharEntry offsets are data-format.md §6.1,
prop fields §4.2.

---------------------------------------------------------------------------------------------
## 0. Provenance, method, coverage

**Bodies.** The 105 rows of `docs/cythera/tools/missing-addrs.txt` in census groups D (92) and G
(13) — 27,040 B, matching missing-census.md §3's R1 row. Command (membership and total):
```sh
grep -v '^#' docs/cythera/tools/missing-addrs.txt | grep -E 'TCharacterWindow|TStatusWindow|TMapWindow|TInventoryWindow|TInventoryList|TInventoryPile|cmpprops|TDroppableWindow|TAbilityList|cmpskills|TBackdropWind|TJournal|TToDo|ToDoEntry|TMissile|TLineEffect|TTileShower|TCircleShower|TBurstShower|TStraightBres|TBres|TGameViewer|RenderMissiles' | grep -v -E 'TRegistrar|std84' > r1.txt
python3 -c "L=[l.split() for l in open('r1.txt')];print(len(L),sum(int(x[1],16) for x in L))"   # 105 27040
```
(The two rows dropped by `grep -v` are `TRegistrar<TCharacterWindow>` (group F) and the
`std::vector<TInventoryPile::PileEntry>` dtor (group B).) Every body below was read whole.

**Coverage list** (address, hex length) — read N = 105/105:
- `TDroppableWindow` (13): PointToProp 100259E4 8 · PointToContainterProp 10025A28 8 · PropToPoint
  10025A74 8 · IsReadOnly 10025BFC 8 · PointToCoordinate 10025C38 8 · CanSearch 10025C84 1E0 ·
  GetGesture 10026AA8 2A0 · ChildToGlobalCoord 1002A724 14 · BecomeKeyTarget 1002A77C 8 ·
  KeyTargetToProp 1002A7BC 8 · StopKeyTarget 1002A7FC 4 · MoveKeyTarget 1002A838 4 · dtor 1002AA20 64.
- `TCharacterWindow` (14): CloseRoutine 1002B2D4 D4 · CloseAtDistance 1002B500 228 ·
  CalcSubRefreshRect 1002BDA0 18C · DrawIntoPort 1002BF6C 2A0 · CanDrop 1002DCF8 9C8 · DoDrop
  1002E6F8 B8 · PointToProp 1002E7E8 130 · PropToPoint 1002E954 190 · CanSearch 1002EB20 8 ·
  MouseRoutine 1002F104 814 · IsReadOnly 1002F9C0 58 · RenumberChild 1002FA4C D4 · Marshal 100309C4 D4
  · dtor 10030AD0 64.
- `TStatusWindow` (11): HandleMonitorChanged 100339AC 6C · GetOwningGD 10033A68 C · DrawRoutine
  10034708 274 · PointToProp 10034C68 230 · PropToPoint 10034ED0 FC · CursorRoutine 10035004 260 ·
  MouseRoutine 100352A0 66C · ForceOut 10035D48 48 · dtor 10035F60 74 · CanDrop 100366E4 E0 · DoDrop
  100367F8 3C.
- `TMapWindow` (17): BeginAnim 10042A8C 3C · StopAnim 10042AF4 38 · DrawRoutine 10042B58 54 ·
  PointToCoordinate 10042BDC 170 · PointToProp 10042D8C 234 · PropToPoint 10042FF4 EC · IdleRoutine
  1004320C 44 · AnimThread 10043280 CC · HandleResizeWindow 1004337C 9C · ResizeRoutine 10043454 164 ·
  CanDrop 100435E8 128 · DoDrop 10043744 44 · BecomeKeyTarget 100446F8 50 · StopKeyTarget 1004477C
  2C · MoveKeyTarget 100447D8 110 · KeyTargetToProp 10044930 60 · dtor 100449C4 74.
- inventory (11): `TInventoryWindow` RenumberChild 100314EC 4 · Invalidate 10031BB4 A8 · NeedsRedraw
  10031C90 48 · DrawRoutine 1003254C 18C · CloseAtDistance 100327D8 150; `TInventoryList` dtor
  1002B470 64 · LDEFDraw 10038C0C 13C · LDEFHilite 10038D88 50 · GetSelection 10038E18 90; `cmpprops`
  100388A8 F8; `TInventoryPile::DrawIntoPort` 100A948C C8.
- skills (3): `TAbilityList` LDEFDraw 1002ABDC 50C · dtor 1002B3E0 64; `cmpskills` 1002BB64 88.
- `TBackdropWind` (5): DrawRoutine 10038440 94 · MouseRoutine 10038508 4 · CursorRoutine 10038544 4C
  · HandleMonitorChanged 100385CC F4 · dtor 10038710 64.
- journal (8): `TJournal` dtor 10078954 74 · CloseRoutine 100789EC 7C · DrawRoutine 10078B24 54 ·
  MouseRoutine 10078BA4 5C8 · ResizeRoutine 100791A0 70; `TJournalList` LDEFDraw 10078100 2D8 ·
  LDEFHilite 10078414 40 · dtor 10078A94 64.
- to-do (10): `TToDo` dtor 10077188 80 · CloseRoutine 1007722C 88 · DrawRoutine 1007736C 54 ·
  MouseRoutine 100773E8 1A4 · ResizeRoutine 100775BC 68 · BecomeVisible 10077650 2C; `TToDoList`
  LDEFDraw 10076A44 230 · LDEFHilite 10076CAC 40 · dtor 100772E0 64; `ToDoEntry` ctor 10077A44 C.
- G — FX (13): `TGameViewer::RenderMissiles` 1005E4F8 1AC · `TTileShower::Show` 1005E9A0 38 ·
  `TMissileThrower::DoBresPixel` 1005EAD0 D4 · `TMissileSpinner::DoBresPixel` 1005ECC8 108 ·
  `TMissileStream::DoBresPixel` 1005EEA4 AC · `TMissileStream::Show` 1005EF84 4C ·
  `TCircleShower::Show` 1005F8CC 28 · `TBurstShower::Show` 1005F920 68 · `TGameViewer` dtor 10061A04
  64 · `TViewer::RenderMissiles` 100693B0 4 · `TStraightBres::DoBresPixel` 1006BDBC 30 ·
  `TBres::DoBresPixel` 10074A54 8 · `TLineEffect::DoBresPixel` 1009930C F8. → banked in magic.md §11.

**Virtual calls.** Every `FUN_100c50e8(...)` is `__ptr_glue` (`ppcdis.py 100c50e8 +5` → `lwz
r0,0(r12)` … `bctr`); the slot is the `lwz r12,N(r12)` before it (`ppcdis.py --func '<name>' | grep
-B4 'bl 0x100c50e8'`). Slots are named from the class vtables (dtor `*param_1 = &PTR_PTR_…`):
`python3 -c "import sys;sys.path.insert(0,'docs/cythera/tools');import toc;A=0x100d47f4;[print(hex(4*i),hex(0x10000000+toc.data_u32(toc.DB+toc.data_u32(A+4*i)[0])[0])) for i in range(2,52)]"`
then `tb.py --at` on each address. Slots used below (TDroppableWindow layout, vtable 0x100D4614,
same in the subclasses 0x100D47F4 / 0x100D4B08 / 0x100D53F4): +0x0C DrawRoutine, +0x24
CloseRoutine, +0x28 MouseRoutine, +0x34 ResizeRoutine, +0x4C HandleSelectWindow, +0x68 Select,
+0x84 PointToProp, +0x90 IsReadOnly, +0x94 PointToCoordinate, +0x98 CanSearch, +0x9C CanDrop, +0xA8
DoDrop, +0xAC PropToPoint, +0xB0 GetGesture, +0xB8 StopKeyTarget, +0xC4 Invalidate, +0xC8
DrawIntoPort, +0xCC CalcSubRefreshRect. List boxes (vtable 0x100D490C / 0x100D4CBC): +0x08
GetSelection, +0x30 Click, +0x34 Update, +0x3C dtor. [HIGH]

**Globals** (from bank usage, re-checked here): `PTR_DAT_100cdbec` → index of the **leader**
(ai-scripts.md §4.1 object table, row main 0xF1; every play window below uses it as the acting character),
`PTR_DAT_100cdb9c` party size, `PTR_DAT_100cdbe4` party list (shorts), `PTR_DAT_100cdb98` the status
window, `PTR_DAT_100cdbb8` the viewer, `_DAT_100cdcd0` TGameSys, `PTR_DAT_100cdc44` prop table,
`PTR_DAT_100cdbf0` CharEntry table, `PTR_DAT_100cdbb0` Nil. New this reading: **`PTR_DAT_100cdd00`
= "interaction panel up"** — only writers `Show__12TInteractionFv @ 1003b5dc` (`*PTR_DAT_100cdd00 =
1;`, main dump) and `Hide__12TInteractionFv @ 1003bbc4` (m:8817 `*PTR_DAT_100cdd00 = 0;`)
(`grep -n '\*PTR_DAT_100cdd00 = ' ghidra/Cythera_*.decompiled.c`). [HIGH]

**The hint line.** Every drag-over verdict is `AutoEye__13TStatusWindowFPc(statuswindow, str)` —
the status window's one-line hint (cleared with `AutoEye(…, 0)`). Every string pointer in the 105 bodies was resolved with
`grep -o 'PTR_s_[A-Za-z0-9_]*_100c[0-9a-f]*' r1.c | sort -u | sed -E 's/.*_(100c[0-9a-f]{4})$/\1/' | xargs python3 docs/cythera/tools/toc.py`
(32 words; `r1.c` = the 105 bodies cut from the missing dump). The hints are bracketed one- or
two-word verbs and refusals (take, wear, wield, give to, drop, throw, abort, occupied, and the
per-slot refusals of §2.3); they are named below without quoting. [HIGH]

**Resources.** MENU/CNTL contents come from `Cythera.rsrc` through `tools/rsrc.py`'s `parse`:
`python3 -c "import sys,struct;sys.path.insert(0,'docs/cythera/tools');import rsrc;res,d=rsrc.parse(sys.argv[1]);[print(rid,d[off:off+ln]) for t,rid,n,ln,off,a in res if t=='MENU' and rid in (134,135,137)]" "$G/Cythera.rsrc"`
(item texts = the Pascal strings after the title; `$G` = the installed `files` folder, seg.py's
`DATA` directory). [HIGH]

---------------------------------------------------------------------------------------------
## 1. Shared machinery — `TDroppableWindow`, `TInventoryWindow`, lists

### 1.1 Gesture timing — `GetGesture @ 10026aa8` [HIGH; slot +0x44 of the app = `MyGetEvent` MED]
Called by the generic `MouseRoutine__16TDroppableWindowF5Points @ 1002706c` (main dump) with the
mouse-down point, the down time `TickCount()` and the modifiers. Plays interface sound 6 first
(`_PlayIFSound__6TAudioFQ26TAudio11EIntfSounds(_DAT_100cdd24,6);`). Result:

| result | when (quoted test) | sounds |
|---|---|---|
| **3** hold | control key: `if ((param_4 & 0x1000) == 0)` else 3; or still held after `param_3 + LMGetDoubleTime()*2` ticks: `if ((uint)(param_3 + iVar5 * 2) < uVar7) return 3;` | — |
| **1** double | option key (`param_4 & 0x800`), or `(param_4 & 3) >= 2`, or the button is released and a second mouse-down arrives within `LMGetDoubleTime()` ticks (app slot +0x44 called with mask 2, peek then remove) | 5, 7 |
| **0** single | released and no second mouse-down within `LMGetDoubleTime()` ticks: `if ((uint)(iVar6 + iVar5) < uVar7) return 0;` | — |
| **2** drag | while held, the mouse leaves ±3 px of the down point: `(int)sStack_44 < (short)param_2 + -3 … sVar9 + 3 < (int)sStack_46) break;` → `uVar4 = 2` | — |

While waiting it yields (`YieldToAnyThread`) with `_DAT_100cdd84` zeroed and bumps a re-entry
counter at app +0x24. What `(param_4 & 3)` carries is not resolved (MED). The consumer (main dump,
context): 0 → Look, 1 → the prop's default command (`PropToCommand`: Talk / Use / Attack / Look),
2 → drag with `TBaseDragger`, 3 → popup MENU 134 (title Commands; items Examine, Use, Talk,
Attack, Take). [MED for the consumer]

### 1.2 Search reach — `CanSearch @ 10025c84` [HIGH code; MED the meaning of the tile bits]
Returns 0 / 1 / 2 for a clicked map point. The point goes through slot +0x94
(`PointToCoordinate`; `ppcdis.py 10025c84 +30` → `lwz r12,148(r12)`); off-map → 0. Then:
- **Reach = the leader's cell and its 8 neighbours** (Chebyshev ≤ 1): `if (((((int)asStack_36[0] <
  (short)uVar1 + -1) || ((short)uVar1 + 1 < (int)asStack_36[0])) || …)) { uVar6 = 0; }` with
  `uVar1/uVar2` = the leader's CharEntry x/y (`*(uint *)(puVar4 + *(short *)puVar3 * 0x20) >> 0xc &
  0xfff`, `& 0xfff`) → else 0.
- For the cell **east** of the leader (x = lx+1) and the cell **south** (y = ly+1) only, the tile
  bits of the target cell decide (`GetTileBits__7TViewerFssss(viewer, x<<2, y<<2, 4, 4)`):
  bit 8 set or bit 4 clear → 1; else `(bits & 0x600) == 0x600` and **0x4000 clear** (east) / **0x2000
  clear** (south) → **2**. Every other in-reach cell → 1.
- The generic consumer turns 2 into 1 only when the clicked prop's tile flag 0x20 is set, else 0
  (`if ((local_58 == 0) || … & 0x20) == 0)) { local_5c = 0; } else { local_5c = 1; }`, main dump
  `MouseRoutine__16TDroppableWindow`). Reading: 2 = "across a wall edge on the east/south side", where
  only wall-mounted props (tile flag 0x20) stay reachable [MED].
- Overrides: `TCharacterWindow::CanSearch @ 1002eb20` → always 1 (inventory items are always in
  reach). The base stubs `PointToProp`, `PointToContainterProp`, `PropToPoint`, `IsReadOnly`,
  `PointToCoordinate`, `BecomeKeyTarget`, `KeyTargetToProp` return 0; `StopKeyTarget`,
  `MoveKeyTarget` are empty; `ChildToGlobalCoord` writes (0,0). [HIGH]

### 1.3 `TInventoryWindow` redraw flags (`+0x12`) [HIGH]
- `Invalidate(flags) @ 10031bb4`: `+0x12 |= flags`; if bit 0x8000 is clear → `InvalRect(port)`,
  else draw now (slot +0x0C) and clear the word. `NeedsRedraw @ 10031c90`: any flag → 1.
- `DrawRoutine @ 1003254c` clears 0x8000, then: flags == 0x4000 → draw into the backing store only;
  flags == 0 → refresh from the backing store (redraw it first if invalid); otherwise the partial
  rect from slot +0xCC (`CalcSubRefreshRect`) through the backing store or a buffer. Clears `+0x12`.
- Flag bits seen across the play windows: 0x0002 inventory list, 0x0100 wield list, 0x0200
  skills, 0x0400 stats header only, 0x0800 (skills-pane only), 0x1000 user-AI menu, 0x4000
  off-screen redraw, 0x8000 immediate (`CalcSubRefreshRect__16TCharacterWindow`, §2.1).
- `RenumberChild @ 100314ec` is empty in the base class.

### 1.4 Containers close at distance — `TInventoryWindow::CloseAtDistance @ 100327d8` [HIGH]
Called (via `CloseDistantWindows`) with the leader's x, y from the map animation thread (§5.3). The
window's prop is `+0x10`; its tile flags `PTR_DAT_100cdc14[base[type] + frame]` give the multi-tile
extension: bit 0x40 → extends one cell **up**, 0x80 → one cell **left**, swapped when the prop's
byte-4 bit 7 (mirror) is set (`if (*(char *)(puVar5 + 1) < '\0') { uVar3 = … & 0x40 …`). The
window closes (slot +0x24) unless `lx−1 ≤ cx` and `cx − extLeft ≤ lx+1`, and the same in y:
`(int)sVar1 < param_2 + -1 || param_2 + 1 < (int)sVar1 - (int)(short)uVar3 …` (m:7701–7704). So a
container window stays open while the leader is within one cell of any cell the object covers.

### 1.5 Inventory list cells, sort, piles [HIGH]
- `TInventoryList::LDEFDraw @ 10038c0c`: cell index `h + v·columns`; cells with index `< list+0x10`
  are filled with pattern +0xAA and framed 2 px, others erased; each cell then
  `DrawInventoryIcon(left+1, top+1, prop)`; selection = `InvertRect`. `RebuildInventory` (main dump)
  writes `+0x10 = 0` and no other writer was seen in this reading, so the framed-cell branch is
  [MED: dead or set elsewhere]. `LDEFHilite` inverts. `GetSelection @ 10038e18`: first selected
  cell's 2-byte data = prop index, else −1.
- Contents (main dump `RebuildInventory__14TInventoryListFs`, context): owner < 0x100 → props of kind
  0x10 parented to it; owner ≥ 0x100 → kinds 9 or 8 parented to it; sorted by `cmpprops`.
- **`cmpprops @ 100388a8`**: type (10 bits) ascending; then frame `(byte4 >> 2) & 0x1f` — but the
  second frame test repeats the first (`(*(byte *)(iVar3 + 4) >> 2 & 0x1f) < (*(byte *)(iVar2 + 4) >> 2
  & 0x1f)` twice, m:8424/8427), so `a.frame > b.frame` falls through; then byte 6 (quality)
  ascending. The comparator is therefore not antisymmetric on frames: equal types order by frame
  only when `a.frame < b.frame`, otherwise by quality. [HIGH]
- **`TInventoryPile::DrawIntoPort @ 100a948c`**: entries of 6 bytes (prop, h, v) are drawn from the
  **last to the first** (`uStack_28 = begin + n*6; … uStack_28 + -6`), icon at (h+1, v+1) — the first
  entry ends up on top.

---------------------------------------------------------------------------------------------
## 2. The character window — `TCharacterWindow` (derives from `TInventoryWindow`)

### 2.1 Layout, panes, drawing [HIGH code; coordinates from `PostInit @ 1002fb58` (main dump)]
Object: `+0x1C` character index, `+0x20` TInventoryList, `+0x24` list rect, `+0x2C..+0x3E` the ten
equipment slots (shorts), `+0x40..+0x5C` eight tactic radio controls, `+0x60` strategy popup,
`+0x64/+0x68/+0x6C` buttons Set Key / Explain / Perform (`toc.py`-resolved Pascal titles at
TOC 0x100ce574 / 0x100ce570 / 0x100ce56c), `+0x70` TAbilityList, `+0x74` its rect, `+0x86` pane.
Window 0xDC × 0x110 (220 × 272).
- **Panes** (`ChangePane`, main dump): 0 = inventory, list full width (`left 0, width 0xCC`, 6
  columns); 1 = **wield** — paper doll + one-column list at x 0xAA; 2 = skills/tactics: for the
  **leader** the three buttons are shown and the skill list rebuilt (`RecalcSkills`), for **anyone
  else** the 8 tactic radios + strategy popup are shown instead
  (`if (*(short *)(param_1 + 0x1c) == *(short *)PTR_DAT_100cdbec) { ShowControl(+100 …) } else { …
  ShowControl(radios) … ShowControl(+0x60) }`). [HIGH, main dump]
- **Tabs**: a click with `v ≥ 0x111` selects pane `h / 0x49` (73 px per tab):
  `iVar6 = (int)(short)param_2 / 0x49 …; _ChangePane__16TCharacterWindowFs(param_1,(int)sStack_48);`
  (m:7410–7413), after slot +0x4C (select window). [HIGH]
- **`DrawIntoPort @ 1002bf6c`**: flags == 0x400 → stats strip only (`DrawStatPart`). Else fills with
  tile pattern 0x1A4, bevels (0x12,0x40)–(0x40,…), rebuilds lists per flags, then: pane ≠ 2 →
  `DrawInvPart`; pane 2 → `DrawSkillPart`; pane 1 → `DrawWieldPart`, plus `DrawWeightPart` for party
  members; always `DrawStatPart`; pane 2 **and leader** → `DrawStat2Part` (exp / training,
  data-format §6.1); `DrawTabsPart`, `DrawPortraitPart`; the window title follows
  `GetCharacterName` (re-titled when it differs). [HIGH]
- **`CalcSubRefreshRect @ 1002bda0`**: 0x200 → `RecalcSkills` unless pane 2; 0x100 → `RecalcWieldList`
  unless pane 1; 0x2 → `RecalcInventory` in pane 2; 0x1000 → `RecalcUserAIMenu`; flags == 0x400 →
  rect (0x12, 0x42)–(0x40, 0xDA) inset 2 (the stats text); else the base class rect. [HIGH]

### 2.2 Equipment slots — geometry and the wield list [HIGH]
`PostInit` fills the 10 slot rects (table at TOC `_DAT_100cddc4`, runtime-filled — the word is
data offset 0x62D08, inside the zero-fill part of the 0x7934E-byte data section: `toc.py 100cddc4`,
`pef.secs`) as 32×32 squares at `top = listTop(0x44) + dv`, `left = dh`:
`SetRect(slot, 0, top, 0x20, top + 0x20)` then `OffsetRect(slot0,0x40,5)` … :

| slot | (left, top) px | holds property-0x26 class | role (from the refusal string) |
|---|---|---|---|
| 0 | (64, 73) | 0 | head |
| 1 | (121, 101) | 1 | neck |
| 5 | (7, 101) | 9 | cloak |
| 2 | (7, 136) | 2 | armour |
| 3 | (121, 136) | 7 | waist |
| 6 | (7, 171) | 3, 4 (one hand), 5 (two hands) | weapon hand A |
| 7 | (121, 171) | 3, 4; −prop ghost of a class-5 item | weapon hand B |
| 8 | (7, 206) | 6 | ring |
| 9 | (121, 206) | 6 | ring |
| 4 | (64, 235) | 8 | feet |

The doll picture (PICT 0x81, `DrawWieldPart`) sits in (40,105)–(120,235)
(`SetRect(PTR_DAT_100cddc8,0x28,top+0x25,0x78,top+0xa7)`). `RecalcWieldList` (main dump) puts each
kind-0x18 prop of the character into the slot of its property 0x26 class; classes 3/4 fill slot 6
then 7, class 6 fills 8 then 9, and **class 5 writes slot 6 = prop, slot 7 = −prop**
(`*(ushort *)(param_1 + 0x3a) = -uVar5;`) — a two-handed item blocks the second hand. Property
0x26 (= 38) values are the 28-bit integer of the script value (`(v << 4 | v >> 0x1c) >> 4`).

### 2.3 `CanDrop @ 1002dcf8` — what may go where [HIGH]
`CanDrop(prop, point)`; result 1 = accept (hint shows a verb), 0 = refuse (hint shows why).
1. **Not a party member** (`(puStack_9c[8] & 0x40) == 0`) → refuse with the not-your-stuff hint.
2. **Pane 0**: inside (listTop, 0)–(listBottom, 0xCC) → accept (take hint), except a kind-0x10 prop already
   parented to this character → abort hint; outside → the can't-drop-there hint.
3. **Pane 1**, inside the one-column list rect (right edge − 16): same rule as pane 0 (own
   inventory item → Abort, else Take — an equipped item dropped here is taken back into the pack).
4. **Pane 1**, an item already **equipped by this character** (kind 0x18, parent = it) → abort hint
   wherever it is dropped — equipped items cannot be moved slot to slot.
5. **Pane 1**, on slot *s*: occupied (`+0x2C + 2s ≠ 0`, including the −prop ghost) → occupied hint.
   Else accept only if the item's class fits: class 0→slot 0, 1→1, 2→2, 7→3, 8→4, 9→5, 6→8/9,
   3/4→6/7, **5→6/7 only when both hands are empty** (`(*(short *)(param_1 + 0x38) == 0)) &&
   (*(short *)(param_1 + 0x3a) == 0)`); hint verb wield for classes 3–5, wear otherwise. A misfit
   prints the slot's refusal: not worn on head / neck / waist, not armour, not footgear, not a
   cloak, not a ring, and for the hand slots the needs-both-hands refusal when the item is class 5, else "(Not
   weildable)" (sic; string @ 0x100C60CC).
6. **Pane 1**, on the doll's body area — `top = slot0.bottom (105)`, `left = slot6.right (39)`,
   `bottom = slot4.top (235)`, `right = slot7.left (121)` (`uStack_60 = *(tbl + 4)`, `+0x36`,
   `+0x20`, `+0x3a`, m:6943–6946) — **auto-placement check**:
   - no property 0x26 (`HasProperty` → Nil) → the can't-wear/wield refusal;
   - count hands in use over every kind-0x18 prop of the character (class 5 → +2, 3/4 → +1) and
     rings (class 6 → +1); any other class equal to the new item's → occupied;
   - new item hands (5 → 2, 3/4 → 1): `if (2 < hands + new)` → needs-both-hands;
   - rings: `if (rings + newRing < 3)` accept, else refuse with the **same** needs-both-hands
     string (m:6990–7001) — a third ring is refused with the two-hands message [HIGH, quirk];
   - accept: wield for classes 3–5 (`(sStack_68 < 6) && (2 < sStack_68)`), else wear.
7. Pane 2, or anything else → the can't-drop-there hint.

### 2.4 `DoDrop @ 1002e6f8` and the hit tests [HIGH]
- `DoDrop(prop, pt)`: pane ≠ 2 and `pt` in the list rect → `TakeCommand(prop, char)`; else pane 1 →
  `WieldCommand(prop, char)` (TGameSys, main dump; `WieldCommand__8TGameSysFss` takes no point).
  So the slot and body drops of §2.3 all end in the same call, and the slot shown afterwards is
  recomputed by `RecalcWieldList` from the class in prop-index order (§2.2) — a one-handed item
  dropped on slot 7 is drawn in slot 6 if 6 is free [MED: inference from the two bodies].
  `WieldCommand` applies the equipment-weight limit (Body × 10,
  trade-economy.md §2.1; combat.md §14); `TakeCommand` applies the inventory
  limit (Body × 20). The window adds **no weight test** of its own.
- `PointToProp @ 1002e7e8`: pane 2 → 0 (skills are not draggable); list rect →
  `LocToProp(list, pt)` (negative → 0); pane 1 → the slot's prop when `> 0` (the class-5 ghost in
  slot 7 is not pickable). `PropToPoint @ 1002e954`: pane 1 → slot centre; else the list cell;
  converted to global coordinates.
- `IsReadOnly @ 1002f9c0`: **1 when the character is not in the party and is alive**
  (`(+8 & 0x40) == 0 && (+6 & 1) != 0`). The generic MouseRoutine returns at once on a read-only
  window and `FindDrop` refuses drops into one (main dump) — a living stranger's window can be
  looked at but not looted; a dead one can. [HIGH code / MED consumer]
- `RenumberChild @ 1002fa4c` (prop renumbering): kind 0x1C → the ability list; else the inventory
  list and any equipment slot holding the old index.

### 2.5 `MouseRoutine @ 1002f104` — clicks [HIGH; list slots MED]
- `v ≥ 0x111` → tabs (§2.1).
- Pane 0/1, no control hit → generic `MouseRoutine__16TDroppableWindow` (gestures §1.1, drags).
  Control hit (the list's scroll bar) → select window, `Invalidate(0x4000)`, list `Click`.
- Pane 2 (after slot +0x4C select):
  - **Tactic radios** (`+0x40 + 4i`, i < 8): `TrackControl`; if the radio's refcon ≠ CharEntry
    `+0x1E` → uncheck the radio whose refcon equals the old `+0x1E`, check this one, **write `+0x1E`
    := refcon** (`puVar5[*(short *)(param_1 + 0x1c) * 0x20 + 0x1e] = uVar10;`, m:7279),
    `Invalidate(0x4000)`. Refcons (3, 4, 5, 6, 7, 8, 13, X) from data 0x100D4784
    (`python3 -c "…toc.D[0x100d4784-toc.DB:…]"` → `(3, 4, 5, 6, 7, 8, 13, 176)`); the 8th's X is set by
    `RecalcUserAIMenu` (0xB0 if `+0x1E < 0xB0`, else `+0x1E`). Labels = STR# 502 (schedules-npcs.md
    §2.3 order).
  - **Strategy popup** (`+0x60`, MENU 135 (title Strategy): item 1 edit-user-strategies, item 2 a
    separator, items 3+ appended by `AppendUserBehaviors`) — **item 14**, §6.1.
  - Set Key (`+0x64`): the selected skill row → if its class-0x50 object has property 9 (use) →
    `DefineFKey(statuswindow, prop)`; on success the list redraws.
  - Perform (`+0x6C`): selected skill → `ScheduleSkill(type, char)` if it has property 9.
  - Explain (`+0x68`): selected skill → `DoInterp(8, VAddr(4, 0x50, prop))` — selector 8 (search),
    the skill's description text (magic.md §1).
  - Click in the list rect `+0x74`: list `Click` (returns double-click), `Invalidate(0x4000)`; if the
    window is the **leader's** and a row is selected: double-click → `ScheduleSkill(type, leader)`;
    then `AdjustSkillControls` (buttons dimmed with no selection).

### 2.6 Distance, closing, saving [HIGH]
- **`CloseAtDistance @ 1002b500`** (non-party characters only; party windows never auto-close),
  with the leader's x, y: the character must be inside the view square (`|dx|, |dy| ≤ viewer+2`) and
  its view-cell byte at `viewer + 0xC0C8 + (dx+half) + stride·(dy+half)` (stride = viewer +4) must
  have bits 0–1 set (`& 3) != 0`, m:6534–6539) — the same byte and test `IsStraightRel__7TViewerFss
  @ 1006b904` (main dump) requires before its line walk, i.e. "the cell is visible" [MED name];
  otherwise the window closes
  (slot +0x24). Visible and **adjacent** (Chebyshev ≤ 1) → full height 0x110 and redraw; visible but
  farther → shrunk to **0x42** (66 px: portrait + stats strip only) — you see a stranger's
  belongings only while standing next to them.
- `CloseRoutine @ 1002b2d4`: hide + delete both lists (slots +0x10, +0x3C), then the base close.
- `Marshal @ 100309c4`: tag `'ChrW'` (`0x43687257`, written with format "l"), the base window,
  then format "hhh" = window origin h, v (global) and the pane (`toc.py`-resolved formats at TOC
  0x100ce55c / 0x100ce560). Restored windows reopen on the same pane. `__dt__` @ 10030ad0 plain.

---------------------------------------------------------------------------------------------
## 3. The skill list — `TAbilityList`, `cmpskills` [HIGH]
- Rows (built by `RecalcSkills`, main dump) = the character's **kind-0x1C** props, sorted by
  `cmpskills @ 1002bb64`: type ascending, nothing else (`(*(ushort *)(iVar3 + 4) & 0x3ff) <
  (*(ushort *)(iVar2 + 4) & 0x3ff)`).
- `LDEFDraw @ 1002abdc` per row: name = `DoInterp(2, VAddr(4, 0x50, prop))` (selector 2, the name);
  **F-key tag** F + number at `left + 2` when `SkillToFKey(type) ≠ 0` (condensed face for n > 9); name
  at `left + 20` for type `< 0xC0` and `left + 8` for skill types `≥ 0xC0`; frame 0 → name only;
  frame ≠ 0 → name, then `frame & 0xF` in parentheses — italic when frame bit 0x10 (aptitude) is set
  (`TextFace(2)`; strings at TOC 0x100ce6b8/0x100ce6b4); then, if segment `0x8A00 + type` exists in
  the segment file, its 0x200 bytes are copied as a **32×16 icon** at the row's top-right
  (`SetRect(…,0,0,0x20,0x10)`, `LoadSegment(…, uVar11 + 0x8a00, …, 0x200)`). Selection inverts.
- Frame = level 0–15 + aptitude bit, as magic.md §1; the list shows it, nothing here changes it.

---------------------------------------------------------------------------------------------
## 4. The status window — `TStatusWindow` (bottom panel)

### 4.1 Layout [HIGH; `LayoutObjects @ 100334f4`, main dump]
With `k = (screen width − 640) / 3`: text log `+0x24` = 0xEA × 0x60 at (0x5E + 1.5k, 0x18), widened by
k; hint/status line `+0x1C` = 0xEA × 0x10 at (0x5E + 1.5k, 8); sky strip `+0x38` = 0x120 × 0x20 at
(0x158 + 2k, 8); **8 party portraits** `+0x40 + 8i` = 32 × 46 at (0x15A + 0x24·i + 2k, 0x30), each
with a popup-arrow rect (`PTR_DAT_100ce760`); **10 F-key macro buttons** 32 × 16 in two columns at x
= k + 8 (F1–F5) and k + 0x2E (F6–F10), y = 0x0C + 0x16·row.

### 4.2 `DrawRoutine @ 10034708` [HIGH]
Background `SpanBits` from the panel art, `DrawControls`, frame art round the log, log list `Update`
(slot +0x34), status line widened to 0x19C, hint cleared, `KeyboardMode(*0x100ce73c)`, sky GWorld
(`+0x80`) copied into `+0x38`, `DrawCharStatus` for 8 slots (party member or empty), the popup arrow
for each party member (`DrawDoPopUp(i,0)`), `DrawMacros`, `ValidRect`.

### 4.3 `MouseRoutine @ 100352a0` [HIGH]
In order:
1. In the text log → the log list's `Click` (slot +0x30).
2. If the interaction panel is up (`*PTR_DAT_100cdd00 != 0`) nothing else responds.
3. **Command buttons** (`FindControl` hit): `TrackControl` — **its result is not tested**
   (`ppcdis.py --func 'MouseRoutine__13TStatusWindow'`: `1003536c: bl 0x100c2bf8` then straight to
   `10035374`), so the command fires even if the mouse is released off the button. The code builds
   the scratch prop **0x3FFF**: kind byte 0x1C (skill), type `0xFF − refcon`, low 16 bits of the
   location word 0x3FFF (`*puVar7 = *puVar7 & 0xff0000 | 0x3fff | *puVar7 & 0xff000000;`), then
   `DoUse(VAddr 0x40503FFF)` (class 0x50 of that prop = the type's command script) and
   `HeartBeat(0)` (m:8061–8073). The buttons' refcons were not found (no CNTL resource carries them;
   NOT RESOLVED). The status-window ctor (main dump) walks the same pseudo-types downward from 0xFF
   (`0xffU - sVar9`) until selector 2 returns Nil to build the per-member skill menus.
4. A pending target / keyboard command (`*PTR_DAT_100cddac != 0 || *PTR_DAT_100cdda8 != 0`) → the
   generic MouseRoutine (targeting, magic.md §2.3).
5. **F-key buttons** (10 rects): the bound skill type is `table[i]` at **0x100D4A7C** (`addi
   r25,r2,-2052 ; = 0x100d4a7c`; shipped data = ten −1, `toc.D` read → `(-1, …, -1)`, i.e. nothing bound
   at start). −1 or `FindSkill(leader, type) == 0` → log line `F%d: Undefined`; else the button tracks
   press/release (`DrawAMacro` highlight) and on release inside → log `F%d: %s` with the skill name (selector 2)
   and **`ScheduleSkill(type, leader)`** — F-keys always act for the leader.
6. **Party portrait** click-release inside → open that member's `TCharacterWindow`
   (`FindInventory`; existing → slot +0x68 `Select`, else `new TCharacterWindow(member)`).
7. **Portrait popup arrow** → `PopUpMenuSelectWithCurFont(menu[i], …, font 3, size 9)`; item n ≥ 1 →
   `ScheduleSkill(list[i].types[n−1], member)` (records at `PTR_DAT_100ce724`, 12 bytes, `+8` → the
   type array; `sStack_6c = *(short *)(*(int *)(PTR_DAT_100ce724 + sVar8 * 0xc + 8) + (uVar9 - 1) *
   2);`) — the per-member do-menu acts for **that** member, not the leader.

### 4.4 Cursor, drops, geometry [HIGH]
- `CursorRoutine @ 10035004`: panel up → cursor 0x2B. Else over the F-key block (rect 0 ∪ rect 9) →
  help balloon 1; over an F-key → the same two formats in the hint line; else the generic cursor.
- `CanDrop @ 100366e4`: only on a party portrait; writes the member's index into the drop point
  (`*(undefined2 *)param_3 = *(undefined2 *)(puVar3 + sVar8 * 2);`); hint take if the member is
  the leader, give-to otherwise. `DoDrop @ 100367f8` → `TakeCommand(prop, member)` (index read
  back from the point). So **giving an item = dropping it on a portrait**; capacity is
  `TakeCommand`'s (Body × 20).
- `PointToProp @ 10034c68`: records what is under the point for help (2 portraits strip, 3 log, 4
  status line, 5 sky — globals 0x100cddb8/b4/b0) and returns the party member under it (its body
  prop = its index) or 0. `PropToPoint @ 10034ed0`: member → (portrait centre h, top + 0x14).
- `HandleMonitorChanged @ 100339ac` relayouts only for the main device; `GetOwningGD @ 10033a68`
  always returns it. `ForceOut @ 10035d48`: if `+0x34` is set, its slot +0x104 [MED: unnamed class].

---------------------------------------------------------------------------------------------
## 5. The map window — `TMapWindow`

### 5.1 Point ↔ cell [HIGH]
- `PointToCoordinate @ 10042bdc`: **refused while the leader is mid-slide under smooth movement** —
  prefs bit 0x80 (`DAT_100d3e20 < '\0'`) and the leader prop's byte-6 sub-step bits (`& 3`, `>> 4 &
  3`) non-zero → 0. Else `x = floor((h + 16) / 32) − half + leaderX`, same for y with v
  (`half = viewer +2`); 0 outside `[0, mapW) × [0, mapH)` (viewer +0x20C1C / +0x20C1E). The leader's
  cell is centred: the grid is offset 16 px.
- `PointToProp @ 10042d8c`: same refusal; relative cell `(h+16)/32 − half`, kept only within ±15
  (`-0x10 < sVar10 < 0x10`); quarter-cell resolution = `rel·4`, plus `((h+16) mod 32) / 8` under
  smooth movement; → `GetBestPropRel(viewer, qx, qy)`.
- `PropToPoint @ 10042ff4`: `((propX − viewer+8) + half)·32` for h, `((propY − viewer+10) + half)·32`
  for v, global; false for a free prop (kind 0xFF).

### 5.2 Drop = drop or throw [HIGH; DropCommand MED-context]
- `CanDrop @ 100435e8`: valid cell (slot +0x94) → writes (x, y) into the point; hint **drop**
  within one cell of the leader (Chebyshev ≤ 1), **throw** farther; invalid → the can't-drop-there hint.
  No range limit here. `DoDrop @ 10043744` → `DropCommand(prop, x, y)`.
- `DropCommand__8TGameSysFsss @ 10054cc0` (main dump, context): refuses (a "blocked" log line)
  unless `IsStraightAbs(viewer, x, y)` → `IsStraightRel(x − centreX, y − centreY)` @ 1006b904: the
  target is inside the view square (`|d| ≤ viewer+2`), its view-cell byte at viewer +0xC0C8 has bits
  0–1 set (visible), and a `TStraightBres` walk from the centre cell meets no tile flag 4 (magic.md
  §11.3); it also refuses when the
  target cell's tile bits `& 0x60200 == 0x200`; asks how many for stacks; animates `DoMissile`
  from the item's outermost owner to the cell; sends selector 17 (dropped), 14 if it was equipped,
  25 when the item's outermost owner is more than √2 from the leader. So the **native throw range =
  the visible view** with a clear line; the scripts behind selectors 17/25 were not read (magic.md
  §11 for the animation).

### 5.3 Thread, idle, resize, keyboard targeting [HIGH]
- `AnimThread @ 10043280` — an endless thread: `DrawRoutine(viewer, 1)`, `ColorCycle`, viewer +0xBA :=
  (+1) mod 8 (the animation phase), `AdvanceDisplacementFilters`, and when `_DAT_100d53b8 ≠ 0`
  `CloseDistantWindows(leaderX, leaderY)` (§1.4, §2.6), then `YieldToAnyThread`. **No tick wait in
  the loop** (item 16 lead: the animation rate is whatever the scheduler gives the thread).
  `BeginAnim`/`StopAnim` set the thread ready (0) / stopped (1).
- `IdleRoutine @ 1004320c`: when the interaction panel is up, forwards idle to the interaction object
  (`*0x100cde3c`, slot +0x40). `DrawRoutine @ 10042b58` → `DrawRoutine(viewer, 0)`.
- `HandleResizeWindow @ 1004337c`: grow limits 128..448 px both ways, then slot +0x34.
  `ResizeRoutine @ 10043454`: `n = ((min(w,h) + 32) / 64)·2 + 1` cells (odd), `Resize(viewer, n)`
  (clamped 5..15, engine-classes §5), window `n·32 − 32` square, viewer clip rect, `SetLight`, redraw.
- Keyboard target: `BecomeKeyTarget @ 100446f8` puts a selector at (0,0) = the leader;
  `MoveKeyTarget @ 100447d8` steps it — directions 0 N, 1 NE, 2 E, 3 SE, 4 S, 5 SW, 6 W, 7 NW (dx = +1
  for 1–3, −1 for 5–7; dy = −1 for 0, 1, 7, +1 for 3–5); 8 → `StopKeyTarget` (slot +0xB8) and clears
  `0x100cdd94`. `KeyTargetToProp @ 10044930` → `GetBestPropRel(selector·4)`. `StopKeyTarget` hides it.

---------------------------------------------------------------------------------------------
## 6. Item 14 and the backdrop

### 6.1 Item 14 — the strategy popup writes CharEntry +0x1E [HIGH]
`MouseRoutine @ 1002f104`, pane 2, control `+0x60`:
`sVar9 = GetControlValue(popup)` after `TrackControl` (m:7290–7291), then
- **v = 1** (the edit-strategies item): `_EditUserBehaviors__Fv();` (m:7293; the orchestrator's
  `1002f390: bl 0x100b1b38 ; .EditUserBehaviors__Fv` after `cmpwi r0,1`), the popup value is put
  back (`SetControlValue(popup, sStack_4e)`), and every party member's window gets
  `Invalidate(member, 0x1000)` so its menu is rebuilt. **+0x1E is not written.**
- **any other v**: radio 8's refcon := `v + 0xAD`; the radio matching the old `+0x1E` is unchecked;
  **`+0x1E := (byte)(v − 0x53)`** (`(char)sVar9 + -0x53`, m:7307) = `v + 0xAD` mod 256; radio 8 is
  checked; `Invalidate(0x4000)`. Menu item 3 (the first appended user strategy) → **0xB0**, item 4 →
  0xB1, …; item 2 is the separator (disabled, MED unreachable; it would write 0xAF).
- Tie to schedules-npcs.md §2.3: values `< 0xB0` are the radio activity codes (3 Attack Strongest, 4
  Defend, 5 Attack Weakest, 6 Beserk, 7 Retreat, 8 Attack Nearest, 13 Target Attack); values
  `≥ 0xB0` are user-AI slots run by `DoMove` → `PerformAI(m, value)` (segment 0x360 + value;
  §9 there). `RecalcUserAIMenu` is the inverse (`< 0xB0 → item 3`, else `+0x1E − 0xAD`).
- Only non-leader characters see these controls (§2.1). Closes nothing beyond schedules §2.3/§9:
  it confirms the **native writer** of +0x1E from the UI (the radios and the popup).

### 6.2 `TBackdropWind` [HIGH]
Full-screen backdrop: `HandleMonitorChanged @ 100385cc` moves/sizes it to the union of all screens
with device attribute 13 (`TestDeviceAttribute(piVar1,0xd)`); `DrawRoutine @ 10038440` fills with a
colour pattern (`*0x100ce77c`) or the black pattern; clicks do nothing (`MouseRoutine @ 10038508`
empty); `CursorRoutine @ 10038544` clears the hint and sets cursor 0x2A.

---------------------------------------------------------------------------------------------
## 7. The to-do list — `TToDo`, `TToDoList`, `ToDoEntry` [HIGH]
- Entry (`__ct__Q25TToDo9ToDoEntryFv @ 10077a44` zeroes `+4`): byte 0 = **done**, `+4` = a script
  `VAddr` of the task title. Built by builtins F2/F3 (`cbAddToDo`, `cbDoneToDo`, script-builtins.md).
- `LDEFDraw @ 10076a44` (cell data = entry pointer): a 16×16 box image from the pixel cache
  (`+0x6AC00`, source (0,0,16,16) from 0x100D6418), shifted 16 px right when done (the ticked box), at
  (left + 2, vcentre − 8); then the title (`VAddrToPtr(entry+4)`) at (iconRight + 3, iconBottom − 4).
- `MouseRoutine @ 100773e8`: list `Click`; on a selected row the log prints a details header, then
  — if the title VAddr has tag 3 (string) — the **details string = the same VAddr with its index
  field + 0x400** (`(uStack_38._0_2_ & 0xfff) + 0x400`, m:13095), else the title with a no-further-info
  suffix; then a done / not-yet-completed line (strings at TOC 0x100cec00 / 0x100cebfc); then
  deselects.
- `ResizeRoutine` → list size (w − 16, h); `DrawRoutine` erase + `Update`; `BecomeVisible` →
  `RebuildList`; `CloseRoutine` hides, deletes the list, disposes the window and deletes itself;
  dtor clears the global `0x100cddfc`. Window created by the status-window ctor (id 0x421).

---------------------------------------------------------------------------------------------
## 8. The journal — `TJournal`, `TJournalList` [HIGH]
- **Storage** (`RebuildList__12TJournalListFv`, main dump, context): `TJournalSegment` records, each
  a 6-byte header {u16 length, …, byte 3 kind, …, byte 5 **category**} + text. The list is rebuilt
  **category by category, 0 to 3**, skipping kind **3** (`if (local_37 == uVar4) { if (local_39 !=
  '\x03') AppendEntry…`).
- `LDEFDraw @ 10078100`: row byte 0 = category → colour via the table at 0x100D6578 = palette
  indices **(255, 1, 5, 8)** (`toc.D` read) through the window's colour table; row byte 1 = kind:
  0xFF = a text line (journal segment offset at +4, length at +8) drawn indented 12 px; kinds 0–2 =
  an entry header: `Day %d` (byte 8) at the left, and at mid-row kind 0 → `%s said:` with the name of
  character byte 9, kind 2 → the Pascal string at TOC 0x100cec28 (a memo label), kind 1 → no label.
- `MouseRoutine @ 10078ba4` — popup MENU 137 (title Journal; items 1 take-note, 2 delete-entry,
  3 separator, 4–7 the categories Important, Useful, General, Background):
  - empty area: only item 1 enabled → `MakeNote` (player memo).
  - on an entry (walks up to its header, selects all its lines, ticks the current category item
    `4 + byte0`): 1 → `MakeNote`; **2 → header byte 3 := 3** (`uStack_65 = 3`, `Write`+`Flush`) =
    delete (the rebuild skips kind 3; the record stays in the segment); **4–7 → header byte 5 := item
    − 4** when it differs = re-file under Important / Useful / General / Background; then
    `RebuildList`. Control hits → list `Click` (scroll bar).
- `ResizeRoutine` rebuilds then sizes the list (w − 16, h); `DrawRoutine` erase + `Update`;
  `CloseRoutine` hides, deletes the list, deletes itself (window kept — `+4 = 0`); window id 0x521.

---------------------------------------------------------------------------------------------
## 9. FX classes in one paragraph (full reading: magic.md §11)
`TMissileThrower` / `TMissileSpinner` redraw the viewer every 16th pixel of a Bresenham walk (32
px per cell); `TMissileStream` stamps every 12th pixel; `TLineEffect` marks every character on a
line; `TStraightBres` is the straight-line test used by throws and targeting bit 0x4000;
`TGameViewer::RenderMissiles` shows the one in-flight FX object at the start of render pass 5 of
6 and then places ambient sounds. [HIGH]

---------------------------------------------------------------------------------------------
## 10. Open items (this file)
1. Status-window command-button refcons (→ pseudo-types `0xFF − refcon`): not in any CNTL resource;
   the creator was not found (`grep -n 'NewControl\|GetNewControl'` over the main dump shows none for
   this window). NOT RESOLVED.
2. `TInventoryList +0x10` (framed-cell count) — only writer seen is `RebuildInventory`'s 0.
3. What `GetGesture`'s `(param_4 & 3) >= 2` carries (a click count from the task queue?) — MED.
4. The meaning of `CanSearch` result 2's tile bits 0x200/0x400/0x2000/0x4000 (wall edges and doors?)
   — code HIGH, names MED; data-format.md §5 lists the tile-flag table without these per-bit names.
5. The view-cell byte at viewer +0xC0C8 used by `TCharacterWindow::CloseAtDistance` (seen / lit) —
   writer not traced here.

Proposed INDEX lines are in notes-w2-play.md.
