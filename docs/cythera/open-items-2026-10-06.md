# Cythera 1.0.4 — open items, wave 2 (2026-10-06) ⚑ wave 2 (2026-10-06)

Reader R5. Items 5, 6, 10, 21, 22, 24, 25, N2 and the script side of 23 (INDEX "NOT RESOLVED"
list; missing-census.md §2 showed no new body touches them). With 100 % of named functions now
decompiled, every negative below covers the whole program. Code readings only.

Evidence base (all run this session from the worktree root; `$S` = the session scratchpad):
- `python3 docs/cythera/tools/ppcdis.py 10000000 100cd280 > $S/r5all.dis` — whole code section,
  212,074 lines; functions named with `python3 docs/cythera/tools/tb.py --at HEX`.
- the three code dumps + the builtins dump (`ghidra/Cythera_{pef,extra,missing,builtins}.decompiled.c`),
  the 958 listings `ghidra/cythera-scripts/<seg>.txt`, `seg.py` (scenario segments), `rsrc.py`.
- prop decoder `$S/r5props.py`: for every segment 0x8100+L, 16-byte records (data-format.md §4.2),
  kind = byte 0, x = bits 12–23 / y = bits 0–11 of the u32 at +0, type = u16@4 & 0x3FF, frame =
  (byte 4 >> 2) & 0x1F, quality = byte 6. Control: the kind census it prints
  (`0:12104, 0x11:55, 0x42:879, 0x80:52 …`, 40 levels) equals data-format.md §4.3.

| item | verdict | label |
|---|---|---|
| 21 0x9C FFFF stack effect | **CLOSED** — non-routine target: expression form leaves +1 stale slot under the result, statement form +1 stale slot; reclaimed when the frame returns; no shipped site is affected | HIGH |
| 24 0xF008 byte 7, f32/f33 bits | **CLOSED** — byte 7 is 0 in all 50 records and has no reader; f32 1/2/4 and f33 0x1000–0x8000 **are read** natively as movement attributes; f32 16/32 have no reader | HIGH (readers) / MED (bit meanings) |
| 25 egg re-arm; activity restore | **CLOSED** — nothing re-arms a spent egg; nothing reads prop byte 7 back (the next hourly schedule pass does the restore) | HIGH |
| 5 prop kind 0x11 | **CLOSED** — 55 records of NPC weapons/armour/clothes (parent = character); no code or script selects kind 0x11, so they are inert | HIGH (no reader) / MED ("leftover equipment") |
| 6 0xF005 / 0xF007 | **CLOSED as "data present, no reader"**; F005 decoded (5 palette ranges), F007 shape decoded | HIGH (no reader) / MED (F005 role) / LOW (F007 role) |
| 10 PORT | **CLOSED** — both are LZ streams of 4096 bytes; PORT 0 = a 64×64 line-art face placeholder, PORT 1 = non-image bytes; no reader | HIGH (no reader, decode) / LOW (PORT 1 role) |
| 22 crystal quality | **CLOSED** — Charax charges the distiller (quality 1); the charged distiller used on the joined crystal sets crystal quality 1, which leads to the **saved** ending. Wave 1 had this branch inverted; quality 0 is the damned ending | HIGH |
| N2 "served" | **NARROWED** — the innkeeper routine 0C80 picks whom to serve by customer bits **6/7**, not by the latch bits 4/5 | HIGH (bytes) / MED (intent) |
| 23 script side | **CLOSED** — every signal in 1/34/35/100+frame/129–135 has a script sender and receivers (table §8) | HIGH |

---------------------------------------------------------------------------------------------
## 1. Item 21 — `0x9C FFFF` with a non-routine target [HIGH]

**Expression form** (`DoExpr__7TInterpFRPUc @ 1007ddfc`, `case 0x9c`, main dump; disasm
`python3 docs/cythera/tools/ppcdis.py --func 'DoExpr__7TInterpFRPUc'`):
```
1007ec88: cmpwi r3,-1 / bne 0x1007eea0          ; seg operand == 0xFFFF
1007ec98: bl DoExpr ; 1007ec9c: lha r3,0(r31) ; addi r4,r3,-1 ; sth r4,0(r31)   ; pop the target value T
...       tag 6 → 1007ecec (routine), tag −1 → 1007eda0 (seg:off code), else ↓
1007ee24: lha r5,0(r31) ; … add r6,r30,r0 ; stw r6,896(r1)    ; base = &stack[top]
1007ee3c: bl DoExpr                                            ; push the args (n values)
1007ee54: subf r0,r3,r5 ; srawi r3,r0,2 ; addze r3,r3          ; (base − &stack[top]) / 4 = −n
1007ee60: addi r5,r3,1                                         ; −n + 1
1007ee6c: add r4,r6,r4 ; sth r4,0(r31)                         ; top += −n + 1
1007ee7c: lha r5,0(r31) ; addi r3,r5,1 ; sth r3,0(r31) ; … stwx r0,r30,r5   ; push T
```
Decompiled: `*psVar7 = *psVar7 + (short)((int)uVar17 >> 2) + (…) + 1;` then
`*(uint *)(iVar8 + sVar18 * 4) = local_44;`. If the stack top is `t` before the target is pushed,
the target is popped back to `t`, the args fill slots `t … t+n−1`, the top is reset to `t+1` and
T goes to slot `t+1`. **Net: top = t+2 — the result T is on top and one stale slot sits under it**
(it holds the first argument, or T itself when there are no arguments, because popping does not
clear slots — script-vm.md §8). A correct expression would end at `t+1`. The `+1` is the same
code as 0x9D's non-object path (`1007f250: addze r5,r5` / `1007f254: addi r0,r5,1`), but 0x9D
never popped its receiver, so there the `+1` is the result slot. In 0x9C the target was already
popped and is pushed again, so the slot is counted twice.

**Statement form** (`DoInterpAt__7TInterpFsP5VAddr @ 10080c98`; `ppcdis.py --func
'DoInterpAt__7TInterpFsP5VAddr'`): `10082114: cmpwi r5,-1` … non-routine path `1008227c: bl DoExpr`,
`10082294: subf r5,r4,r0 ; srawi ; addze ; 100822a0: addi r4,r3,1 ; 100822ac: add ; sth` and no push
— **net +1 stale slot** (a correct statement would end at `t`). The two routine paths (tag 6, tag −1)
push nothing in the statement form and one result in the expression form: correct.

**Lifetime.** Every frame resets the top to its own argument base when it ends. At `return`
(0x8B; `10081794: lwz r0,0(r28)` = `TInterp[0]`, the args base set from `param_4` in the prologue
`10080d3c: stw r0,0(r28)`; then `100817a4: subf r6,r5,r0 ; srawi ; addze ; 100817bc: add ; sth`).
At end of code or on a non-local exit the same happens (`10080d7c`–`10080da8`). So a leak never
leaves its frame. It does grow inside a loop until the routine returns. Nothing checks the
0x400-slot bound: pushes are a bare `stwx`.

**Shipped sites** (`grep -n callx ghidra/cythera-scripts/*.txt`; only four use seg 0xFFFF):
| site | form | leak |
|---|---|---|
| 0C00 @0010 `return callx[L00](A30)` | expr inside 0x8B | absorbed at once by the return reset |
| 0C43 @0003 `return callx[A33](A30, A31, A32)` | same | same |
| 0816 @007C `set L08 = callx[L08](A30)` | expr inside 0x82 (pops exactly one: `*psVar7 = sVar14 + -1;` then the store) | +1 slot per loop pass with a non-routine entry (the `iterate_range` loop @004D–@0115) — 113 of 114 entries (script-library §10.1) |
| 0EA5 @003B `set L05 = callx[L05](L02)` | same | +1 per stock entry (`iterate_list` loop @0027–@006E) |

L08 and L05 get the right value (the top slot is T). The stray slots sit above the frame's locals
and below every later argument base, so no later call or builtin reads them. Neither site is
nested inside another call's argument list. The leak can only cost stack depth (≈ 113 slots for
0816 at most), so **no shipped behaviour depends on it**. Correct value in `L08`/`L05` [HIGH];
the depth estimate [HIGH for 0816's 114-entry table per script-library §10.1].

---------------------------------------------------------------------------------------------
## 2. Item 24 — 0xF008 creature record byte 7 and the "unread" flag bits

### 2.1 Data census [HIGH]
```
python3 -c "import sys,struct;sys.path.insert(0,'docs/cythera/tools');import seg; d,s,p=seg.toc(); o,l=s[0xF008]; raw=d[o:o+l]; …"
records 50 byte7 {0: 50}
f33 bits [(1,21),(2,6),(8,5),(4096,5),(8192,2),(16384,2),(32768,1)]
f32 bits [(1,9),(2,5),(4,23),(16,16),(32,10),(64,15),(128,8),(256,5),(512,5),(1024,1),(2048,2),(4096,3),(8192,8),(16384,30),(32768,3)]
```
The segment is stored in plain bytes: record 0 reads `0c 0c 0c 00 03 14 02 00 00 00 00 04 00 20 11 1b` raw, the same as combat.md §4. Records that
carry the listed bits: f33 0x1000 on keys 79, 84, 90, 225, 204; 0x2000 on 205, 206; 0x4000 on 88
("asp"), 115; 0x8000 on 34 ("king", f33 = 0x8002).

### 2.2 Byte 7 — no reader, all zero [HIGH]
- Script side: `GetField__Fsss` class 0x48 has cases 0x2C–0x33, 0x35, 0x36 only (combat.md §4). It
  maps 0x32 → `*(uint *)(pbVar7 + 8) & 0xffff` and 0x33 → `*(int *)(pbVar7 + 8) >> 0x10`. No field
  reaches byte 7, so scripts cannot read it.
- Native: the table base `PTR_DAT_100cdbd8` (TOC r2−30376) is loaded only in `LoadGlobals`,
  `ObjToMonst`, `Ctor__Fsss` ×2 and `GetField__Fsss`
  (`grep -- '-30376(r2)' $S/r5all.dis`). `ObjToMonst` (`bl 0x10044a60`) is called only from
  `__ct__14TActiveMonsterFs`, `__ct__14TActiveMonsterFP7TStream`, `HatchEgg`, `Ctor__Fsss` ×2.
- Every `[1] + N` / `(param_1 + 4) + N` record read in monster code, across all four dumps:
  ctor +1/+2/+5/+6 (and +0); `Die` +0xE ×2; `GetMonstAttrs`, `HandleMove`,
  `TActiveMonster::CanMove` +8 only.
- Disasm heuristic (`$S/r5scan7.py`: a register loaded by `lwz rA,4(rB)` or the r3 of
  `bl ObjToMonst`, then `lbz/lhz/lha/lwz …,N(rA)` within 8 instructions): **N = 7 → 0 hits**. Control:
  N ∈ {5, 6, 8, 14} → 38 hits, including the ctor ×3, `Die` ×2, `HatchEgg`, `GetMonstAttrs`, `HandleMove`,
  `TActiveMonster::CanMove`.
⇒ byte 7 is padding in 1.0.4.

### 2.3 The flag word is a native movement-attribute mask [HIGH code / MED meaning]
`GetMonstAttrs__14TActiveMonsterFv @ 10049cdc` returns the record's **u32 at +8 = f33 << 16 | f32**:
```c
uVar1 = *(uint *)(param_1[1] + 8);
if ((*(byte *)(*param_1 + 8) & 0x40) != 0) uVar1 = uVar1 | 0x80000000;   /* CharEntry +8 bit 6 (party) */
if ((*(ushort *)(*param_1 + 6) & 0x8000) != 0) uVar1 = uVar1 | 0x80;     /* status bit 15 */
```
Consumers: `TActiveMonster::CanMove` → `TryMove`. `CalcTowards` → `CanSimpleNavigate` → `TryMove`.
`TPathFinder::FindPath` stores `attrs | 0x8000000` (no monster: `0x88000004`) for `TryMove`.
`MoveCommand` builds the player's value as `*(uint *)(local_54[1] + 8) | 0x80000000`.
`CanPMove` passes `param_5 | 0x80`. `HatchEgg` passes the template's raw record word to `CanMove`.
All of them end in **`CanMove__8TGameSysFssl @ 10051218`**, tests against the stage-entry word
`local_38` of the destination cell (masks checked in the disasm:
`ppcdis.py --func 'CanMove__8TGameSysFssl'` → `andi. r0,r30,0xb`, `rlwinm. r0,r30,0,28,29` = 0xC,
`lis r3,16384 ; addi r3,r3,8` = 0x40000008, `rlwinm. …,0,4,4` = 0x08000000, `0,2,2` = 0x20000000,
`0,3,3` = 0x10000000, `0,24,24` = 0x80):
| attrs bit | record bit | CanMove use (cell bits are `local_38`) |
|---|---|---|
| 0x80000000 | **f33 0x8000** | passes everything while viewer +0x20c26 is set; also passes a blocked (0x200) cell occupied by a character < 0x100 whose CharEntry +8 has 0x40 |
| 0x40000000 | **f33 0x4000** | (with f32 8) passes a blocked cell that has 0x80000000 |
| 0x20000000 | **f33 0x2000** | refused unless the cell has 0x100 |
| 0x10000000 | **f33 0x1000** | refused where the cell has 0x40000000 |
| 0x08000000 | f33 0x0800 | with (attrs & 0xC) passes a blocked cell that has 0x20000000 (path-finder sets it always) |
| 0x1, 0x2, 0x8 (`& 0xb`) | **f32 1, 2**, 8 | pass a blocked cell that has 0x100 |
| 0x4, 0x8 (`& 0xc`) | **f32 4**, 8 | see 0x08000000 |
| 0x80 | f32 128 / status bit 15 / `CanPMove` | needed to enter a cell with 0x10800 set |
Two more direct readers. **f32 2** — `HandleMove__14TActiveMonsterFsssss @ 100488e4`:
`if ((*(uint *)(param_1[1] + 8) & 2) != 0) { return; }` skips the step-on reaction. That reaction
sends selector 0x1F to the mover with the prop under it (and clears that prop's kind bit 2) or with
−tile. **f32 4** — `CanMove__14TActiveMonsterFRsRsRsRs @ 10049d60`: after a refused move,
`if ((*(uint *)(*(int *)(param_1 + 4) + 8) & 4) != 0)` and the target cell holds a prop whose
type flag 0x40 is set → `DoInterp(9, prop)` (selector 9 = use) on it, i.e. the creature **uses
(opens) a door** in its way. ⚑ wave 2 (2026-10-06): so combat.md §16.4's "f32 1/2/4, f33
0x1000–0x8000 have no reader" holds only for the combat routines; they are movement bits.
**f32 16 and 32 — no reader [HIGH]**. No native consumer of the attrs word tests 0x10/0x20 (the
list above is every function that loads it). The scripts test f32 64…32768 and f33 1/2/4/8 only:
`grep -ho 'f3[23] & [0-9]*' ghidra/cythera-scripts/*.txt | sort | uniq -c`. A side effect of the
OR in `GetMonstAttrs`: f32 128 (resistance bit, combat §9, 8 records) also acts as the 0x80
movement bit, so those creatures can enter 0x10800 cells [HIGH code / MED that it is unintended].
Meaning names (flying/swimming/door-opener) are MED: only the cell bits are known, not what the tiles are.

---------------------------------------------------------------------------------------------
## 3. Item 25 — egg re-arming and the activity restore after a visible walk

### 3.1 Nothing re-arms a spent egg [HIGH]
Who **clears** kind bit 0x80 anywhere:
- Native — disasm scan (`$S/clr80.txt`): a byte whose 0x80 bit is cleared or toggled
  (`rlwinm …,0,25,23|0,25,31`, `andi. …,0x7f`, `xori …,0x80`) and then stored by `stb …,0(` or
  `stbx` within 4 instructions. **2 hits**: `FollowLeader__14TActiveMonsterFs` (a follower's
  body prop) and `DrawRoutine__11TGameViewerFs`, frame 7 (`1005caf0: rlwinm r0,r0,0,25,23 ;
  1005caf4: stb r0,0(r28)`). Whole-byte writers: `RepositionChar` / `LeaveLevel` write 0x42 to
  **character** bodies only (props < 0x100). `SetField` case 0 is the script path. `LoadLevelProps`
  merge loop handles kinds `'!'`, `' '` and 0 only (`if ((*pcVar17 == '!') || (*pcVar17 == ' '))` /
  `else if (*pcVar17 == '\0') …`).
- Frame-7 groups in data cover no egg. `$S/r5props.py` → `L9 0x101 frame7 n=1 cond=0x2 arg=65` →
  `next 0x102 kind 0x0 type 62`; `L9 0x401 … arg=64` → type 62; `L27 0x124 … n=0`. Type 62 = "hole".
  Frame 7 also sets its own 0x80 first (`*pbVar15 = *pbVar15 | 0x80;`), so each group runs once.
  Side note: it calls `AddToHood(iVar10)` with the hood-list counter, not the prop index [MED].
- Scripts: `grep -n 'f00:kind = ' ghidra/cythera-scripts/*.txt` → clears/toggles of 0x80 only
  target types 39, 62, 120, 192, 200–202, 257, 258, 267, 356, 392 (the receiver's own class or an
  explicit type test, e.g. 1419@004A `(L00.f04:type == 267)`). The 312 frame-0 eggs have types
  0, 1, 3, 4, 6, 11, 12, 14, 15, 18, 24, 27–29, 51, 52, 57, 84, 93, 130, 131, 185, 192, 206, 212, 228,
  330, 338. The only overlap is type 192: 1025@0559 toggles type 192 props **at (168,79)**, and
  the only prop there is `L1 0x13a kind 0x80 … type 192 frame 3` ("cave"), not an egg. The type-192
  eggs are at L27 (33,7), L31 (30,32), L33 (28,16).
- Persistence: `GoToLocation @ 1005c434` calls `SaveLevelProps` (`1005c474`) then `LoadLevelProps`
  (`1005c494`). `SaveLevelProps` writes the prop array verbatim to 0x8100+L in the top overlay
  (`_SaveSegment__15TCachedSegFilesFUsPvl(*puVar1,param_1 + 0x8100,…)`, writes go to slot 0,
  data-format §1.4). `LoadLevelProps` reads `_HomeSegFile__15TCachedSegFilesFUs(…,param_1 + 0x8100)`
  = the topmost file holding the id. So a spent egg (kind 0xC2) comes back spent.
⇒ an egg hatches at most once per game: after the hatch, or after a failed chance roll
(`if ((uint)local_44[7] < ((int)sVar6 & 0x7fffU) % 100) { *local_44 = *local_44 | 0x80; }`).
A failed day/night gate leaves it armed.
Consequence: the template-count refunds are inert in 1.0.4. They are `Die`: `if (template type ==
body type && (egg byte 6 & 4) == 4) template byte 7 += 1` and `LeaveLevel`:
`*(char *)(param_1[5] + 7) = *(char *)(param_1[5] + 7) + '\x01';`. Only `HatchEgg` of that same
egg reads the template count (templates match `(*puVar11 & 0xffff) == param_1`) [HIGH code /
MED "inert", which rests on the scan above].

### 3.2 Activity after a walk [HIGH]
`RepositionChar__FP9CharEntryP8PropItemlsUc @ 100064a0`, verified on the disasm
(`ppcdis.py --func 'RepositionChar…'`). r19 = old location visible, r23 = new location visible,
r24 = same level as the leader, r25 = the target activity:
- not forced, **old visible**, same level: `100066a4: stb r25,22(r31)` (activity := target) and
  `100066ac: stb r25,7(r30)` (prop byte 7 := target), then `SetWaypoint`.
- not forced, old **not** visible, new visible, an active monster exists: `10006724: li r0,128 ;
  10006728: stb r0,22(r31)` (activity := 0x80), `10006734: stb r25,7(r30)`, `SetWaypoint`.
- the other paths also set activity := target: a forced or neither-visible move snaps the prop;
  with no active monster the prop is placed at `FurthestPoint` toward the target, hatched and
  walked in (`10006818: stb r25,22(r31)`).
⚑ wave 2 (2026-10-06): rules.md §3.4's last bullet ("old visible … activity → 0x80") has the
condition backwards. 0x80 is used when an NPC that is **off-screen** walks to a destination that is
**on-screen**. An NPC that is already visible walks in its target activity.
Nobody reads byte 7 back. Writers of CharEntry +0x16 (`stb …,22(`, 26 sites) and readers of byte
+7 (`lbz …,7(`, 27 sites) share only `HatchEgg`, which copies the template's byte **6**:
```
grep -E 'stb r[0-9]+,22\(' $S/r5all.dis ; grep -E 'lbz r[0-9]+,7\(' $S/r5all.dis   # → tb.py --at, comm -12
```
`DoMove`'s waypoint arrival only clears the walk flag: `*(undefined1 *)(param_1 + 0x13) = 0;`.
`ppcdis.py --func 'DoMove__14TActiveMonsterFss' | grep 'lbz r[0-9]*,7('` → nothing. Scripts: no
`activity == 128` test, and all 53 `f07:byte7` uses are item props (levers, buttons, bombs, etc.).
⇒ an NPC parked at 0x80 stays idle (DoMove: no case, busy 20; its selector-32 hook still runs)
until something rewrites +0x16. That is the next `ScheduleTime` pass (hourly or on a time jump, rules
§3.1, which does not skip 0x80), builtin E0 `reschedule`, or a script `setfield …f15:activity`. Each
of these re-runs `RepositionChar`, which sets the target directly unless the same off-screen →
on-screen case recurs.

---------------------------------------------------------------------------------------------
## 4. Item 5 — prop kind 0x11 (55 records) [HIGH no reader / MED reading]
Decode (`$S/r5props.py`, kind 0x11 rows): all 55 have byte 6 = 0, frame 0. The low 16 bits are a
**character index** (21 owners: 4, 9–14, 16, 23, 24, 31, 56, 59, 62, 64, 71–73, 79, 91, 95; levels 3,
6, 8, 11, 13, 17, 24, each the owner's CharEntry level byte, e.g. char 4 `CE+0 0301902a` on L3).
Byte 1 is 0–6, constant per owner, role unknown. Example: `L3 0x34f raw 11 01 00 04 00 72 00 00 …`
= owner 4, type 114. Types (tile names from the listing headers): mace, dagger ×9, club, axe,
sword ×3, arrows ×2 (byte 7 = 20, 10 = count), bow ×2, cuirass ×3, metal breast plate ×3, buckler ×2,
light shield, round shield, leather helmet ×2, full helmet ×2, cloak ×9, sandals ×9, boots ×3, type
129 (no class script). The kind-0x18 ("equipped") records have the same shape: the same item types,
owner in the low 16 bits, small byte 1 (e.g. owner 109: dagger/cloak/sandals). The two owner sets
are disjoint. Owners 11 and 13 also hold kind-0x10 items.
No reader:
- `grep -E 'cmpl?wi r[0-9]+,(17|0x11)$' $S/r5all.dis` → 8 compares, all non-prop:
  `DefaultMenu`, `Set{Music,Sound}Volume` ×3, `DoMove` ×2 (activity 0x11), `CreateSysObj`,
  `TGremlin::GetField`.
- `case 0x11:` / `'\x11'` in all four dumps → `GetField__Fsss` (field 0x11), `DoMove` (activity),
  `MyCDEF`.
- Kind selection elsewhere excludes it: `SetStage` (not staged); `GetPropParent` (0x08–0x0B, 0x10,
  0x18, 0x1C, 0x42/9); inventory/equip/skill tests `== 0x10 / 0x18 / 0x1C`; `cbPropsAt` and
  `cbInRange` skip `(*pbVar5 & 0x1a) != 0` (0x11 & 0x1A = 0x10); `SendSignal` takes
  `kind & 0x5D ∈ {0,1}` (0x11 & 0x5D = 0x11). Only `cbAllProps` (C7) yields it, unfiltered, and no
  script tests kind 17 (wave 1).
⇒ these NPCs never carry, wear or drop the gear; it sits in the level arrays and is saved and
loaded as is. "Leftover equipment records from an older kind numbering" is MED (same shape as
0x18, no reader).

---------------------------------------------------------------------------------------------
## 5. Item 6 — globals 0xF005 / 0xF007: data present, no reader

No reader [HIGH]: `grep -c -E ',-4091$|,-4089$' $S/r5all.dis` = 0 and 0 (0xF005/0xF007 as
`addi …,-409x` after `lis …,1`). Control: -4094 (F002) → `100057ec: addi r4,r4,-4094` in
`LoadGlobals`, -4088 (F008) → 1 hit. No data-section halfword equals 0xF005/0xF007 (`toc.D` scan → `[]`).
Dumps: census §2 (0 hits). Dump: `python3 -c "…seg.toc(); o,l=s[sid]; b=d[o:o+l] …"`.

**0xF005** (16 B at file 0x507905): `d0 08 01 | d8 08 01 | e0 04 01 | e4 04 01 | e8 04 01 | 00`
= five {first index, count, 1} triples plus a 0 terminator. The ranges are contiguous: 0xD0–0xD7,
0xD8–0xDF, 0xE0–0xE3, 0xE4–0xE7, 0xE8–0xEB. In the game `clut` 256 (`Cythera Data.rsrc`, `rsrc.py`
parse, entries 0xC8–0xEF) these are colour ramps: D0–D7 white → blue-grey, D8–DF grey-blue →
black, E0–E3 red → orange, E4–E7 orange → yellow, E8–EB blue. So F005 is most likely a
**colour-cycling table** (fire/water cycling) [MED]. Consistent with that, `ColorCycle__FP8GrafPort
@ 10008694` is a bare `10008694: 4e800020 blr` with no `bl` caller and no TVector word
(`toc.D` scan for 0x8694 / 0x10008694 → none). The engine ships with colour cycling stubbed out.
**0xF007** (167 B at 0x507915): u16 count 0x21 = 33, then 33 × 5-byte records `{u8 a, u8 b, 00 05 00}`
(`(167−2)/5 = 33.0`). Pairs (a,b): (0,0) (1,0x1A) (4,0x01) (4,0x30) (4,0x40) (4,0x0E) (4,0x45)
(4,0x20) (4,0x48) (4,0x4C) (4,0x50) (4,0x10) (3,0x02) (3,0x06) (3,0x10) (3,0x20) (3,0x30) (3,0x07)
(3,0x09) (3,0x3C) (3,0x3E) (3,0x50) (3,0x59) (3,0x5A) (3,0x5D) (3,0x6A) (2,0x40) (3,0x41) (3,0x42)
(3,0x45) (3,0x46) (2,0x28) (7,0). (a<<8|b) is not a segment id (31 of 33 absent). Role **LOW**
(editor or build data).

---------------------------------------------------------------------------------------------
## 6. Item 10 — `PORT` resources 0/1 in `Cythera Data.rsrc`

`rsrc.py` census: `PORT 2 413..2351`. `python3 -c "…rsrc.parse(…); lz.unlz(b)…"`:
`PORT 0 skip 0 -> 4096 bytes, consumed 413 of 413`, `PORT 1 … consumed 2351 of 2351` (other
offsets fail). Both are **complete LZ streams** in the engine's portrait/tile codec (data-format §2)
and decode to 4096 B, the size of a 64×64 8-bit portrait (`0x8800+n`) [HIGH].
- PORT 0: two values only (`0` ×3830, `255` ×266). Rendered with `clut` 256 (`$S/r5_port0.png`)
  it is a **black-on-white line sketch of a face in profile** (a placeholder portrait) [HIGH
  decode / MED "placeholder"]. Nearest shipped portrait differs in 584 pixels (segment 35004 =
  0x88BC).
- PORT 1: 204 distinct values. It renders as noise, and its first words look like pointers
  (`00 0b 5d e8 01 3e 75 40 …`) — not image data. Role LOW (an editor buffer).
No reader [HIGH]: `grep -c -i -E "0x504f5254|1347375700|'PORT'|0x504f[^0-9a-f]"` = 0 in all four
dumps (control: `'Lite'` is found as `GetResource(0x4c697465,…)`, m:30899). `grep -E 'lis
r[0-9]+,20559$' $S/r5all.dis` (0x504F) = 0. `toc.D.count(b'PORT')` = 0.

---------------------------------------------------------------------------------------------
## 7. Item 22 — the crystal's quality and the two endings [HIGH]
⚑ wave 2 (2026-10-06): **quests-flags.md §5 step 12 has the quality test inverted.**
1025@0445 is `8d 30 62 06 41 00 54 40 04 58` = `jf (A30.f06:quality == 0) -> 0458`. Quality **0**
falls through to `044F set_variable(0, 2)`. Quality **≠ 0** jumps to `0458 set_variable(0, 1)`.
Alaric 1802@02F8 `jf (get_variable(0) == 2) -> 0539`: var 0 = 2 runs the Pelagon scene and
`050A end_game("You have damned Cythera to darkness.")`. Otherwise 0539 → `06E3 end_game(… saved …)`.
So **an uncharged crystal (quality 0) damns Cythera; a non-zero quality saves it.**
The writer that wave 1 did not find, all in bytes:
1. Charax 184F talk @0360–@05F8 (needs his bit 3; the player holds item 271, the Sabinate spores):
   `04B7 remove_items(1, 271, 0)`, then
   `05B2 iterate_props_at(&L02, 0, 7, 5)` … `05CF jf (L01.f04:type == 233)` → `05DA setfield
   L01.f04:type = 234`, `05E2 setfield L01.f06:quality = 1`. In the data the only distiller at
   (7,5) is `L17 0x10e kind 0x0 (7,5) type 233` (Charax's house).
2. Distiller 10EA use_on @00A5: `00A8 jf (A30.f06:quality == 1) -> 0569`, `00B2 jf (A31.f05:item ==
   6181) -> 0548`, then `00BF A30.f06 = 0`, `00C6 A30.f04:type = 233`, **`00CE setfield
   A31.f06:quality = 1`**, `R0E8B(leader, 50)` (exp), a scream line and Omen's vision (portrait 126).
   6181 = 0x1825 = type 37 frame 6, the joined crystal.
3. 1025@0396 (crystal used on type 34 = Alaric) then sets var 0 = **1** (quality ≠ 0): good ending.
Other quality writers checked (`grep -n 'f06:quality = '`, 52 sites) never touch type 37: e.g. the
pitcher 10A0@0264 copies between pitchers (A31 type 160), 1136@01BD needs A31 type 301. All
`give_item` of a crystal piece pass quality 0 (`184A@09E9`, `180D@0A4D`). An uncharged distiller
(type 234, quality 0, filled with water by 0E0A@01D4) only takes the "distil an element" path
(@0569).
Documentation agrees — hintbook (documentation): the walkthrough says to bring the spores to
Charax and "Use the spell in the Distiller on the joined Crolna." (`pdftotext -layout
Cythera_Hintbook.pdf`, line 1611). It calls Charax responsible for purifying the corrupted Crolna
(line 563) and names Omen as Pelagon's alias (line 1959). That fits Omen's protest in 10EA@013F and
Pelagon's thanks in the damned ending.

---------------------------------------------------------------------------------------------
## 8. Item 23 (script side) — who sends and who receives signals 1, 34, 35, 100+frame, 129–135 [HIGH]
Receivers follow `SendSignal @ 10053794` (schedules-npcs §6.1): the zone and current room, then
on-map props of the **leader's level** with `kind & 0x5D ∈ {0,1}`, type flag 0x10000 and
**byte 6 == n**, then the characters on that level. Type flag 0x10000 = the type has property
0x15 (= selector 21) (data-format §4.4). Hidden kind-0x80 props qualify (0x80 & 0x5D = 0).
Senders: `grep -n 'send_signal(' ghidra/cythera-scripts/*.txt` (25 sites). Wired props:
`$S/r5props.py` rows with quality n whose type has a `sel21/signal` method (types 10, 38, 39, 46,
51, 143, 144, 253, 257–259, 311, 320, 322, 333, 355, 356, 392 — `grep -l 'sel21/signal'`, 40 files).
| n | sender (bytes) | receivers |
|---|---|---|
| 1 | Gate Guard 1864@0516 (Ariadne returned), @05E1 (Ariadne dead), @075F (asked "gate") | portcullises (type 39, 1027: `kind = 128 ^ kind` + sound) L2 (10,32), L24 (16,44)h, L25 (31,56), L28 ×3, L40 (31,27); secret passage L8 (23,116); secret door L26 (15,29); wall L40 (30,25)h; zone 1428 `jf (A31 == 1) -> 0065` (empty branch, no-op) |
| 34 / 35 | bell 10C1 use: rings shift the bell's quality into the class word `seg[0008] = ((seg[0008]*16) + quality) & 65535` (not persisted); `== 12865` (0x3241: bells 3,2,4,1) → 34, `== 4675` (0x1243: 1,2,4,3) → 35 | L25 portcullis (15,41) q34, hidden portcullis (15,47) q35; the four L25 bells carry qualities 1–4 at (10..19,62) |
| 100+frame | half disk 10E8 sel26/sel27 when A31 is type 184, quality 4, byte 7 == the disk's frame | Tomb zone 1419: 100 → reveal type-267 props whose kind is exactly 128; 101 → sound, `screen_effect(0)`, reveal types 200–202. L11 hidden floors (type 257) q100 (32,20–21), q101 (32,23–24) |
| 129 | panpipes 1099 sel10 (use_on) `((A31 & 1048575) == 1014211) && (A30.f06:quality == 1)` | L12 hidden wall (41,51), L13 secret doors (47,28) (47,26) |
| 130 | zone 1417 "Kosha Grotto" enter, once (`!test_flag(15)` → `set_flag(15)`) | L12 hidden wall (52,52); Myus 180A@070F, Naxos 180B@0640, Darius 180C@0676 `health = 0`; Pelagon 180D@0D2B `type = 35` |
| 131 | lyre 109A sel10 `(A31 & 4095) == 4038` | L21 secret door (53,43) |
| 132–134 | strange device 1175 use → `sub_0063(A30, pattern, 132/133/134)`: sends when all 8 entries of `A30.f12:frame_dict[256]` match the pattern | stone doors (type 10, 100A: `R0E40` DoDoor) L9 (34,64), L34 (53,9), L27 (50,15) |
| 135 | glowing crystal 1025@05D7, used on a type-179 prop of quality 4 | L1 hidden stepping stones (type 392) (152–154,170) |
Instrument input (the native side, `TWMusicBox::MouseRoutine`, is R2's): the instrument's selector
10 gets `A31` = the running note word (`<<4 | note`, missing-census §2). The panpipes test the
last 5 nibbles = 0xF79C3 → notes 15, 7, 9, 12, 3. The quality-1 panpipes show notes [15,12,9,7,3]
instead of [15,12,9,6,3] (1099@003A/@0067), so only they can play 7. The lyre tests the last 3
nibbles 0xFC6 → 15, 12, 6, on notes [18,15,12,9,6,3] (109A@002A). In the data both instruments
have quality 0 (`L8 0x292/0x2f2` type 153, `L8 0x2f0` type 154). The quality-3/8 ones at L12 are
'B' frame-8 markers. So where a quality-1 panpipe comes from is not traced here.
Not in the list but seen: q128 portcullis L12 (29,52) has no script sender. The black disk 1100
sends 201–216 and the buttons 1104 send `L01.f06:quality`; both are outside this item.

---------------------------------------------------------------------------------------------
## 9. N2 — quests-flags.md §2.3 "served" [NARROWED: HIGH bytes / MED intent]
0C80 in full (`ghidra/cythera-scripts/0c80.txt`, 484 B; args A30 = innkeeper, A31 = customer
list, A32 = kitchen x,y, A33 = dishes, A34 = table spots), looping over customers L00:
- `001D jf R0F02(L00, 6) -> 00B1`: **bit 6** (0x40, party member, §2.2) set → a bark (68), walk
  to the kitchen (160 to A32), go to the customer (162), a second bark, **`007F
  queue_activity(A30, 167, L00, 4, False)`** (clear bit 4), walk back, `return True`.
- `00B1 jf R0F02(L00, 7) -> 01CA`: **bit 7** (0x80, name known) set → barks, a random dish from A33
  named to the customer, a walk to a random A34 spot, go to the customer, **`01B6
  queue_activity(A30, 167, L00, 5, 0)`** (clear bit 5), `return True`.
- no customer matched → `01D9 return False`.
DoMove 0xA7 uses x = character and y = bit index: `iVar8 = 1 << ((int)*(short *)(iStack_a4 + 0xc)
& 0x3fU); … puStack_fc = puVar5 + *(short *)(iStack_a4 + 10) * 0x20; … puStack_fc[8] & ~bVar2`.
Callers: Crito 1829@0147 with customers [52, 55, 101] = Ascalon, Tlepolemus, Thersites, the only
callers of 0C84/0C85. Dares 182D@00F7 with [37, 36, 64, 77, 21, 22, 86, 67, 85, 51, 59], none of
whom sets bit 4 or 5. Initial CharEntry +8 = 0 for all of them (`seg.py` over 0xF009).
Reading: the latch half of §2.3 stands (0C84/0C85 set bit 4/5 and wait on 166 until it clears).
But the innkeeper **does not choose customers by bits 4/5**. Bit 4 (Ascalon's wine order, 1834@0012) is
cleared only for a party member. Bit 5 is cleared once the player knows the customer's name (setbit 7: 1834 ×2, 1837 ×1, 1865 ×2
`R0F00(A30, 7)`). Dares serves name-known patrons who never wait. The label "served" is right for
what 0C80 does. "The waiting patron is the one served" is not what the bytes do. Whether 6/7 was
meant to be 4/5 is MED.

---------------------------------------------------------------------------------------------
## 10. Cross-file corrections this file raises (for the orchestrator / other owners)
- combat.md §16.4 (not R5's file): byte 7 closed (§2.2); f32 1/2/4 and f33 0x1000–0x8000 are
  movement bits (§2.3); f32 16/32 still unread.
- rules.md §3.4 (not R5's file): the 0x80 "walking" condition is old-not-visible / new-visible (§3.2).
- data-format.md §4.3 (not R5's file): kind 0x11 row (§4); §5 F005/F007 rows (§5); open-items-2026-10-03
  §10 PORT row (§6).
