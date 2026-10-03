# Cythera 1.0.4 — schedules, NPC behaviour, signals, map hooks

Register: **code reading**. Every claim is labelled **HIGH** (quoted bytecode or decompiled /
disassembled lines prove it), **MED** (inferred from code read) or **LOW** (conjecture). Citations:
`segid @ offset` = a line of `ghidra/cythera-scripts/<segid>.txt`; `Function @ addr` = a function of
`ghidra/Cythera_pef.decompiled.c` unless marked *(extra dump)* = `ghidra/Cythera_extra.decompiled.c`
(CyDecompAt.java, extra-addrs.txt) or cited with a `ppcdis.py` / `tb.py` / `toc.py` command — see §0
⚑ corrected (wave 1 2026-10-03). Cross-references: rules.md §3
(ScheduleOne/EvalCondition/RepositionChar — cited, not repeated), engine-classes.md §3 (clock),
ai-scripts.md (the `.ai` language), script-builtins.md (builtins), data-format.md §6 (CharEntry).

---------------------------------------------------------------------------------------------
## 0. Scope, method, what was not read

**Read this session:** script-census.md, script-vm.md, script-builtins.md, rules.md, engine-classes.md
§1–5, data-format.md §6, ai-scripts.md, INDEX items 14/16/18; all 19 page-0x09 listings; 0x0C40–0x0C55,
0x0C00, 0x0D06, 0x0D07, 0x0E8C, 0x0F15, 0x3000, 0x3007, 0x3014, 0x3015, 0x301C, 0x3020, 0x3021, 0x3043;
samples 0x1401, 0x1B01, 0x181E, 0x1032, 0x1864, 0x1802 @14AD–1502, 0x10BB, 0x1107, 0x1162, 0x1165,
0x108E. Native: `DoTick`, `MoveAll`, `Guide`, `QueueActivity`, `HatchEgg`, `CreateMonster`, the four
monster ctors, `DoAttack/DoDefend/DoRetreat/DoRoam/PaceNS`, `JoinParty/LeaveParty`, `SendSignal`,
`HeartBeat`, `GetRoom`, `DrawRoutine` trigger loop, `DoTicks` timer loop, `ScheduleOne/ScheduleTime/
RepositionChar`, `SetWaypoint`, `TPathFinder::{ResetPaths,CalcWeight,AddCandidate,FindPath,
FindWaypoint,CanSimpleNavigate}`, `PerformAI`, `PerformAction`, `EvaluateCondition` (≥0x80 branch),
`CalculateObject`, `DoInterpRoutine`, `TGremlin::OnEnter/OnSignal`, `GetField/SetField` (cases cited),
`RecalcUserAIMenu`, `TCharacterWindow::PostInit` (behaviour radios).

**Method — banked tools (`docs/cythera/tools/`, recipes in `tools/README.md`)** ⚑ corrected (wave 1
2026-10-03; every quote below re-run with the command named beside it):
1. *Traceback tables name the functions the main dump lacks* — `python3 docs/cythera/tools/tb.py`
   (1,994 tables, `--cxx-only` 1,952). `ppcdis.py --hex 1004d6d4 +5` prints the DoMove table:
   `00000000 00092041 80120000 00001dec 001c2e44` (zero word … tb_offset 0x1DEC, name length 0x1C,
   ".D"); `tb.py --tb --grep DoMove` → `1004b8e8  1dec .DoMove__14TActiveMonsterFss  tb@1004d6d4
   name@1004d6e4` — the 7.9 KB **activity dispatcher**. `tb.py --tb --grep` also gives `Die`
   0x100469C0, `LeaveLevel` 0x100465A4, `CanFace` 0x1004A358 (TCrawlMonster's 0x1004A3A4),
   `AdjustAspect` 0x1004ACC8, and every Crawl/Octo/Dragon override. [HIGH]
2. *Bodies* — the 37 functions the main dump lacks (DoMove, Die, LeaveLevel, the subclass
   overrides…) are in `ghidra/Cythera_extra.decompiled.c` (CyDecompAt.java, extra-addrs.txt); DoMove =
   `python3 ghidra/find_func.py 'DoMove__14TActiveMonster' --file ghidra/Cythera_extra.decompiled.c`.
   Disassembly = `python3 docs/cythera/tools/ppcdis.py <start> <end>` (r2 = 0x100D5280 annotated);
   data words (vtables, jump tables) = `toc.py <addr>` over the data section `pef.py` unpacks (loaded
   at 0x100CD280). [HIGH]
   Consolidated item 20 (DoMove/Die/LeaveLevel absent from the dump) is resolved by the extra dump;
   `tb.py --missing ghidra/Cythera_pef.decompiled.c` still lists **877** named functions absent from
   the main dump (840 with the extra dump concatenated).

**Not read:** `FollowLeader` (only called from `TeleportTo`), `GotAway`, `HandleMove` and the
subclass `HandleMove/CanMove` bodies beyond their vtable slots, `Die`, `LeaveLevel` (the subclass
bodies, `Die` and `LeaveLevel` are now in the extra dump, not read for this bank ⚑ corrected (wave 1
2026-10-03)), `ShowBarks`
internals, `FurthestPoint`, `FindFirstStep/Waypoint`, `Render`, the 0x0C00–0x0C3F routines other
than 0x0C00, the 146 room/zone first-visit texts beyond counts, the hintbook.

---------------------------------------------------------------------------------------------
## 1. Page 0x09 — the 19 combat-AI scenario routines (tables first)

Entry (`EvaluateCondition @ 100affe8`, `PerformAction @ 100b0698`): the AI entry's index byte
already carries +0x80, so test k (STR# 9307 item k) runs **0x0880+0x80+k = 0x0900+k** and action k
(STR# 9308 item k) runs **0x0900+0x80+k = 0x0980+k**. [HIGH]
```
_DoInterpRoutine__7TInterpFUs5VAddr5VAddr5VAddr(local_58,*(byte *)(param_1 + 1) + 0x880,
   … & 0xffff | 0x40400000, uVar3 & 0xffff | 0x40400000, *(undefined1 *)(param_1 + 3));
_DoInterpRoutine__7TInterpFUs5VAddr5VAddr5VAddr(auStack_2c,*(byte *)(param_1 + 1) + 0x900, …
```
Arguments: **A30 = self** (char object), **A31 = object** = `CalculateObject` result as a char object,
**A32 = the raw parameter byte** (entry byte 3). [HIGH] When the AI line has **no object** (object
byte 0, e.g. `OutOfAmmo()`, `EquipMelee()`, `EquipRanged(#)`), `CalculateObject` takes the group
path with no group matching 0 and no modifier, and returns 0 → **A31 = char 0** (`local_44 = bVar12
!= 0xf0;` … `return uVar10;`). [MED — group path read to its end; char 0 having no active monster is
inferred: CharEntry 0 is a one-entry placeholder, data-format §6.3]

Tests return True/False (`IsTrue` read by the evaluator); actions return 0 and only **queue
activities** on the monster (builtin F0 → `TActiveMonster::QueueActivity`, §3). [HIGH]

| seg | AI name (STR#) | what the bytecode does | conf |
|---|---|---|---|
| 0901 | HasSpell(#) | True if `find_skill(A30, A32)`; else reads list = `prop(A30,sel68,0)` (or of `as_cls48(A30)`) and compares **every second element** with A32 (L02 toggles: first element skipped, then every other) | HIGH |
| 0902 | HasMeleeWeapon(@) | any `iterate_descendants(A31)` item has property sel42 | HIGH |
| 0903 | HasRangedWeapon(@,#) | any descendant with sel43[1] ≥ A32, or sel49[2] ≥ A32, or sel46[1] ≥ A32 and (sel46[0] == 0 or some descendant has sel45[0] == sel46[0] — matching ammo) | HIGH |
| 0904 | UsingMeleeWeapon(@) | as 0902 over `iterate_equipped(A31)` | HIGH |
| 0905 | UsingRangedWeapon(@,#) | as 0903, weapon from `iterate_equipped`, ammo from descendants | HIGH |
| 0906 | OutOfAmmo() | equipped sel43 → False; sel49 → False if `.f07` ≠ 0 else True; sel46 in range: needs no ammo → False, ammo found → False, else True. **Uses A31**, which is char 0 for this no-object test ⇒ empty iteration ⇒ **always False** | HIGH code / MED consequence |
| 0981 | CastSpell(@,#) | if R0901 (has spell): temp skill prop `create_prop(28, 0, A30, 0, A32, 0, 0)` as class 0x50; L01 = its sel54[0]; 3 or 5 → queue (A30, **0x4B**, A32); 1 → if `R0E8C(A30,A31) > 2` (squared distance) give up, else queue (A30, **0x4C**, A32, 0, A31); other → queue 0x4C; then `delete_prop` | HIGH code / MED sel54 meaning |
| 0982 | SetTarget(@) | queue (A30, **0x53**, 0, 0, A31) | HIGH |
| 0983 | Retreat() | queue (A30, **0x52**, 7, 0, 0) — 0x0C52 sets activity := 7 | HIGH |
| 0984 | Pass(#) | queue (A30, **0x42**, A32, 0, 0) — 0x0C42 adds A32 to busy | HIGH |
| 0985 | WalkTo(@) | queue (A30, **0xA2**, as_prop(A31), 0, 0) — native: walk until dist² < 2 of that prop | HIGH |
| 0986 | BattleCry() | queue (A30, **0x44**, 0, 0, one of "Die!"/"Argh!") — 0x0C44 sets the bark field f26 | HIGH |
| 0987 | EquipMelee() | if not R0904 then scans `iterate_equipped(A31)` testing **`has(A31, sel42)`** (the char, not the item) and queues (A30, 0x54, …, item). With A31 = char 0 nothing is ever found ⇒ **no-op** | HIGH code / MED consequence |
| 0988 | EquipRanged(#) | same shape over `iterate_descendants(A31)` with the 0903 tests, queues 0x54. A31 = char 0 (shipped lines `A88/00`) ⇒ **no-op** | HIGH code / MED consequence |
| 0989 | RunAwayFrom(@,#) | d² = R0E8C(A30,A31); d² ≥ A32² → nothing; d² = 0 → random cardinal offset ±A32; else target = self + (self−obj)·A32²/d²; queue (A30, **0xA0**, x, y, Nil) | HIGH |
| 098A | RunToward(@,#) | d² ≤ A32² → nothing; else computes the **same away-point** into L01/L02 but queues (A30, **0xA0, 0, 0**, Nil) — walks toward map cell (0,0) | HIGH bytes / MED consequence |
| 098B | DoAttack() | queue (A30, **0x49**, 0, 0, Nil) | HIGH |
| 098C | FinishCombat() | `target := 0`; then queue (A30, 0x52, x) with x = **2** if A30 is the leader, **1** if another party member, **113 (0x71)** otherwise | HIGH |
| 098D | SetProtecting(@) | queue (A30, **0x55**, 0, 0, A31) — 0x0C55 sets f2B (monster +0x24) but **returns 0, not True**, so the entry is never popped (§3.3) | HIGH |

Quotes for the three defects (raw bytes decrypted this session with `seg.py dec`):
```
098A @0040: f0 30 43 00 00 00 a0 41 00 41 00 43 50 00 ff ff 40   queue_activity(A30, 160, 0, 0, Nil)
0989 @00A1: f0 30 43 00 00 00 a0 01 02 43 50 00 ff ff 40         queue_activity(A30, 160, L01, L02, Nil)
0987 @0034: 8d 31 60 2a 40 00 42                                  jf has(A31, sel42) -> 0042
0C55 @0003: 86 2b 30 40 33 40                                     setfield A30.f2B = A33
0C55 @0009: 8b 41 00 40                                           return 0
```
(0C55: two consecutive lines, `ghidra/cythera-scripts/0c55.txt` @0003 and @0009 ⚑ corrected (wave 1
2026-10-03).)
Shipped use (segments 0x0410–0x0416/0x0430–0x0436, `entry` lines of `ghidra/cythera-scripts/04xx.txt`
with byte 1 ≥ 0x80; ⚑ corrected (wave 1 2026-10-03): an entry is a **test** when byte 0 is a condition
class 0x65–0x68 — shipped only 0x65 ×18 / 0x66 ×4, e.g. `0020: entry 65 82 f0 …` in 0410 — and an
**action** when byte 0 is a weight 0..100, e.g. `0048: entry 00 8b …`; ai-scripts.md §3.2, the
`EvaluateAI` switch): tests 0x81 ×6,
0x82 ×6, 0x83 ×4, 0x85 ×4, 0x86 ×2; actions 0x81 ×6, 0x82 ×22, 0x83 ×4, 0x84 ×4, 0x88 ×4, 0x89 ×4,
0x8A ×2, 0x8B ×22, 0x8C ×10. So **OutOfAmmo, EquipRanged and RunToward — all three defective — are
used by "Missile Script" (0x0415/0x0435)**, EquipRanged also by "Defend"; SetProtecting, EquipMelee,
WalkTo and BattleCry are unused. [HIGH counts]

---------------------------------------------------------------------------------------------
## 2. The activity ("work type") byte — CharEntry +0x16

Field 0x15 `activity` = CharEntry +0x16; field 0x16 `behaviour` = **+0x1E** (`SetField`: `case
0x15: *(char *)((int)puVar12 + 0x16) = …; case 0x16: *(char *)((int)puVar12 + 0x1e) = …`).
`setworktype` (0x0F03) is `activity = A31`. GetField 0x15 returns **0x7F** while the monster walks to a
waypoint (`_GetWaypoint… != '\0') { *param_1 = 0x7f;`). [HIGH]

### 2.1 What each value makes an NPC do natively (`DoMove @ 1004b8e8` *(extra dump)*, empty queue)
The switch reads `uStack_78 = (ushort)*(byte *)(*param_1 + 0x16);` (or the queue head's code,
`uStack_78 = (ushort)*(byte *)(piStack_80 + 2);`, §3) — quotes from `find_func.py
'DoMove__14TActiveMonster' --file ghidra/Cythera_extra.decompiled.c` ⚑ corrected (wave 1
2026-10-03: the earlier quote lacked the `(ushort)` cast). Busy = the tick count written to CharEntry
+0x12 before the next decision. [HIGH — every case read in the extra dump]

| value | native behaviour | busy | conf |
|---|---|---|---|
| 0x00, 0x0C, 0x0E, 0x70 | idle | 8 | HIGH |
| 0x01, 0x11 | **party follower** (only when not leader and party mode `cdbe8` == 1): formation slot from tables 0x100D565C/0x100D56DC indexed `rank + 8·leaderFacing`; else step onto the leader's 32-cell trail (MoveAll keeps it at 0x100D54C0); 0x11 uses `TPathFinder::FindPath` and drops to 1 when it fails or arrives | leader's +0x3E | HIGH |
| 0x02 | nothing (leader / player-driven) | — | HIGH |
| 0x03 | Attack Strongest: `PerformAI(m, 0xD1)` else `FindStrongest(0)`/(1) + `DoAttack` | per attack | HIGH |
| 0x04 | Defend: `PerformAI(0xD4)` else `DoDefend` (attack nearest if cur·2 > max HP, else retreat) | — | HIGH |
| 0x05 | Attack Weakest: `PerformAI(0xD2)` else `FindWeakest` + `DoAttack` | — | HIGH |
| 0x06 | Beserk: `PerformAI(0xD3)` else keep target (or strongest) + `DoAttack` | — | HIGH |
| 0x07 | Retreat: `DoRetreat` (step away from target / strongest; no AI) | 8 | HIGH |
| 0x08 | Attack Nearest: `PerformAI(0xD0)` else `FindNearest(1)` + `DoAttack` | — | HIGH |
| 0x09, 0x0A, 0x0B | roam (`DoRoam`: random 8-way step) | 16 | HIGH |
| 0x0D | Target Attack: no target → activity := 0x0C, busy 8; else `DoAttack` | — | HIGH |
| 0x0F / 0x10 | pace E–W / N–S | 12 | HIGH |
| 0x71 | return from combat: party member → activity 1; else if the egg template's (+0x14) type equals the body type → activity := template byte 6, otherwise `ScheduleOne(char, hour, 1)`; **falls through** to 0x93 (so food := 30 too). For a non-spawned NPC +0x14 is 0 (ctor `param_1[5] = 0`) and the compare reads address 4 — no fault on classic Mac OS; the outcome depends on the low-memory word there [MED] ⚑ corrected (wave 1 2026-10-03: register) | 32 | HIGH |
| 0x93 | eating: **food (+0x1B) := 30** | 32 | HIGH |
| 0x86–0x89 | stand still facing 0–3 (`AdjustAspect(1, dir)`, vtable +0x30 — case 0x88: `ppcdis.py 1004d02c 1004d060` → `1004d040: li r4,1` … `1004d048: li r5,2` … `1004d050: lwz r12,48(r12)` ⚑ corrected (wave 1 2026-10-03)) | 20 | HIGH |
| 0x8A / 0x8B | pace N–S / E–W | 12 | HIGH |
| 0x8C / 0x8D | pace N–S / E–W (slower) | 16 | HIGH |
| 0x8F, 0x97 / 0x90 | roam | 12 / 20 | HIGH |
| 0x94 | farming: 1 in 3 turn (`CanFace`, `AdjustAspect`), else `PaceNS` | 20 | HIGH |
| 0x96 | **seek the player and talk**: if leader is char 1, visible and dist² < 10 → activity := 0x97 and `TalkCommand(self)`; else walk to CharEntry[1] | 8 | HIGH |
| 0xA4, 0xA6 | wait | 8 | HIGH |
| 0xA0–0xA3, 0xAA | queue-only (§3) | — | HIGH |
| 0xB0–0xFF | **custom AI slot**: `PerformAI(m, value)`; none loaded → "Uknown combat AI…", busy 20 | — | HIGH |
| other < 0x80 | prints "Uknown behavior for prop %d…", busy 20 | 20 | HIGH |
| other 0x80–0xAF (0x80 walking, 0x8E, 0x91 sleep, 0x92 sit, 0x90 "working"…) | nothing native | 20 | HIGH |

Native strings for 0x90–0x94 come from the default selector-7 routine: `3007 @001C` `jf (A30.f15:activity
== 144)` → "working"; 145 "sleeping", 147 "eating", 148 "farming", 146 "sitting", 134–137 "standing
still", else "nearby". [HIGH] Their *visuals* (work animations, "Zzzz…", sleeping-in-bed frames)
are script: `3020 @0010`–`@0112` (activity 145 → bed tile swap, bark "Zzzz...", ambient sound 35) and
per-character selector-32 methods such as `181E @0005` `jf (A30.f15:activity == 144)` → `R0C86(A30,
[46,47], [43,44], 6, …)`. [HIGH bytes / MED "animation" reading of 0x0C86]

Census (this session, `seg.py` over 0xF009/0xF00B): schedule activities (entries with loc ≠ 0):
0x93 ×133, 0x91 ×99, 0x92 ×93, 0x90 ×82, 0x8F ×39, 0x8B ×25, 0x8A ×24, 0x8E ×20, 0x00 ×18, 0x94 ×12,
0x8D ×9, 0x96 ×8, 0x88 ×6, 0x8C ×6, 0x87 ×5, 0x89 ×5, 0x0F ×5, 0x86 ×2, 0x0C ×2, 0x10 ×2 (617
entries). Initial CharEntry +0x16 (131 non-empty entries, same command as §2.3 with `r[0x16]`):
0x91 ×87, 0x00 ×17 (16 without placeholder entry 0), 0x92 ×6, 0x88 ×4 … [HIGH] ⚑ corrected (wave 1
2026-10-03)

### 2.2 Pre-emption before the switch (DoMove head, *(extra dump)* ⚑ corrected (wave 1 2026-10-03)) [HIGH]
Status bit 0x20 (Afraid) → `DoRetreat`; 0x40 (Paralysed) or 0x4000 (Asleep) → busy 20, nothing;
0x2000 (Confused) and `Random() & 3 != 0` → busy 12, step to a random diagonal neighbour.
```
cStack_b9 = '\x01' - ((*(ushort *)(PTR_DAT_100cdbf0 + sStack_58 * 0x20 + 6) & 0x20) == 0);
if (cStack_b9 != '\0') { uVar15 = .debug::_DoRetreat__14TActiveMonsterFv(param_1); return uVar15; }
```
Then the queue head (§3), then the waypoint walk (+0x4C flag, destination +0x4E/+0x50, next
waypoint +0x52/+0x54): if neither the destination nor the monster is visible the monster **snaps**
to the destination (busy 20, return 1); else `FindWaypoint` + `GoTowards`, busy 8. Then, **only when
the queue is empty**, selector **32** is sent to the character; a **True** result skips the native
behaviour for this tick:
```
.debug::_DoInterp__7TInterpFs5VAddr(&iStack_ac,0x20,uStack_b0);
if (iStack_ac == *(int *)PTR_DAT_100cddec) { return 1; }
```
⇒ selector 32 is the **per-tick NPC "think" hook**, not only "spawned" (HatchEgg also sends it once).
The default `3020` returns False after flavour barks; e.g. `1864 @0005` (Gate Guard, activity 150)
returns True while it greets the player. [HIGH]

### 2.3 Behaviour byte +0x1E — INDEX 14 settled
`TCharacterWindow::PostInit @ 1002fb58` builds 8 radio buttons from `STR# 0x1F6` (502) with values from
data 0x100D4784 = **(3, 4, 5, 6, 7, 8, 13, 0xB0)** (read with `tools/pef.py` this session), checked when
equal to +0x1E; the 8th opens the user-AI popup (`RecalcUserAIMenu`: `< 0xb0 → value 3`, else
`+0x1E − 0xAD`). With ai-scripts.md §6's STR# 502 order, **+0x1E < 0xB0 values are activity codes**:
3 Attack Strongest, 4 Defend, 5 Attack Weakest, 6 Beserk, 7 Retreat, 8 Attack Nearest, 13 Target
Attack; their native meaning is §2.1 (3/4/5/6/8 run scenario AIs 0xD1/0xD4/0xD2/0xD3/0xD0 =
segments 0x0431/0x0434/0x0432/0x0433/0x0430, whose names match). [HIGH]
- **Native code never copies +0x1E into +0x16**; scripts do: `3043 @0009` `setfield
  A30.f15:activity = A30.f16:behaviour` (selector 67 "provoked", §6) and `301C @003A` (selector 28
  default, the Hero's attack puts every party member into its behaviour). [HIGH]
- `HatchEgg @ 1004f420` sets spawned monsters' +0x1E from the template activity: 3–8 → same; 9 → 3;
  10 → 4; 11 → 5; 0x0C/0x0F/0x10 → 6; anything else 7 (Retreat). [HIGH]
- Data census +0x1E over the **131 non-empty** 0xF009 CharEntries: {0:11, 2:1, 3:7, 4:7, 5:1, 6:5,
  7:8, 8:91} — the 0s are entries 0, 15, 43, 44, 47, 99, 126–129, 190 (10 without placeholder entry
  0); agrees with data-format.md §6.1. Command: `python3 -c "import sys,collections;
  sys.path.insert(0,'docs/cythera/tools'); import seg; d,s,p=seg.toc(); o,l=s[0xF009]; R=[d[o+i:o+i+32]
  for i in range(0,l,32)]; print(collections.Counter(r[0x1e] for r in R if any(r)))"` (0xF009 is read
  raw, not XOR-decrypted). [HIGH] ⚑ corrected (wave 1 2026-10-03: was 0:10)

---------------------------------------------------------------------------------------------
## 3. The activity queue (`ActivityQueueEntry`, builtin F0)

### 3.1 Layout [HIGH]
`QueueActivity @ 1004b824` inserts {act u8, x i16, y i16, value VAddr} at the **end** of the
`std::list` at monster +0x2C (`_insert…(auStack_28,param_1 + 0x2c,local_24,local_20)`, `local_24 =
param_1 + 0x30`). DoMove reads node +8 act, +0xA x, +0xC y, +0x10 value; non-empty test `param_1[0xb]
!= 0`, head `param_1[0xd]`.

### 3.2 Head codes handled natively (`DoMove` *(extra dump)*) [HIGH]
⚑ corrected (wave 1 2026-10-03): the head switch is `switch(*(undefined1 *)(iStack_a4 + 8))` (extra
dump), compiled as a jump table at 0x100D5A1C (`ppcdis.py 1004bb20 +1` → `addi r3,r2,1948  ; =
0x100d5a1c`), whose 11 words (`toc.py 100d5a1c … 100d5a44`, code offsets) send 0xA0–0xAA to
0x1004BB34, BBA0, BC40, BCFC, **BD8C (0xA4), BE24 (0xA5), BEB4 (0xA6), BF78 (0xA7)**, C01C, C054, C0B4.
0xA6 / 0xA7 lines: `if (((byte)puStack_f4[8] & uStack_f8) == 0) { cStack_64 = '\x01'; }` (value ≠
True: popped when the bit is clear) and `if ((bool)uStack_fe) { puStack_fc[8] = puStack_fc[8] | bVar2; }
else { puStack_fc[8] = puStack_fc[8] & ~bVar2; }` (`uStack_fe = True == value`).
| code | meaning (x, y, value) | popped when |
|---|---|---|
| 0xA0 | walk to (x, y) — sets waypoint if not walking | at (x, y) |
| 0xA1 | walk to prop x's cell | on that cell |
| 0xA2 | walk to prop x | dist² < 2 |
| 0xA3 | walk to (x, y) | dist² < 2 |
| 0xA4 | wait for global flag x; if y == 0 also clear it | flag set |
| 0xA5 | set (y ≠ 0) / clear global flag x | at once |
| 0xA6 | **wait until** CharEntry[x] +8 bit y is set (value True) / clear (any other value, e.g. False) ⚑ | condition |
| 0xA7 | set / clear CharEntry[x] +8 bit y (value True / any other value) ⚑ | at once |
| 0xA8 | drop y entries starting with itself | at once |
| 0xA9 | wait until `EvalCondition(x>>8, x&0xFF)`, then drop y entries from the head | condition |
| 0xAA | one `GoTowards` step to prop x | after the step |
| 0x86–0x8D | counted stand/pace: x = repetitions | x reaches 0 |
| **any other** | selector **33** sent to the character with (act, x, y, value) | script returns **True** |

```
.debug::_DoInterp__7TInterpFs5VAddr5VAddr5VAddr5VAddr5VAddr(&iStack_b4,0x21,uStack_b8,uVar1,
          (int)sVar9 & 0xfffffff,(int)sVar16 & 0xfffffff,iVar8);
if (iStack_b4 == *(int *)PTR_DAT_100cddec) { cStack_7a = '\x01'; }
```
(the default-case lines above: extra dump, DoMove ⚑ corrected (wave 1 2026-10-03).) While an 0xA4 or
0xA6 head waits, the main switch's `case 0xa4: case 0xa6:` sets busy 8. No class defines selector 33,
so it lands in **0x3021** `return R[0C00+A31](A30, A32, A33, A34)` —
the "never called" routines 0x0C40–0x0C55 of census §7 are the **queued-activity handlers**. [HIGH]

### 3.3 Script handlers 0x0C40–0x0C55 (A30 = char, A31 = x, A32 = y, A33 = value)
| act | routine body | conf |
|---|---|---|
| 0x40 | prop A33: parent := A30, kind 16 (put in inventory) | HIGH |
| 0x41 | prop A33: kind 1, location (A31, A32) (drop on map) | HIGH |
| 0x42 | busy += A31 (Pass) | HIGH |
| 0x43 | `callx[A33](A30, A31, A32)` (run a routine) | HIGH |
| 0x44 | bark A33 on A30 (or on char A31 if non-zero) | HIGH |
| 0x45 | print A33 | HIGH |
| 0x46 | delete prop A33 | HIGH |
| 0x47 | prop A33 item := A31 | HIGH |
| 0x48 | `send_signal(A31)` | HIGH |
| 0x49 | attack (sel 28) A33 or current target; failure (falsy) → queue 0xAA toward it | HIGH |
| 0x4A, 0x4D | no-op, True | HIGH |
| 0x4B / 0x4C | cast spell A31 (self / on char A33): temp skill prop, sel 9 (use), sel 10 on target; party casters print "X casts Y [on Z]."; when the use succeeded (L02) and `sel54[0] ≠ 0` (`0C4C @006D` `jf (L03 != 0) -> 007A`) it sends **sel 67** to the target (hostile spell) | HIGH code / MED sel54 |
| 0x4E / 0x4F / 0x50 | prop A31: sel 9 / sel 10(A33) / sel 11(A32, A33) | HIGH |
| 0x51 | `positional_sound(A33, A31, A32)` | HIGH |
| 0x52 | activity := A31 | HIGH |
| 0x53 | target := A33 | HIGH |
| 0x54 | `R0EB7(A30, A33)` (equip; 0x0EB7 not read) | HIGH call / LOW name |
| 0x55 | f2B := A33, **returns 0** → never popped; DoMove does nothing else that tick (the default branch only calls the script) ⇒ a monster executing SetProtecting **freezes until its queue is cleared** — no native clear was found | HIGH code / MED consequence |

Census of `queue_activity` codes in all scripts (this session): 0xA0 ×41, 0x42 ×19, 0x44 ×16, 0xA2 ×10,
0xA5 ×10, 0x47 ×8, 0x52 ×4, 0xA4 ×4, 0xA3 ×3, others ≤ 2. [HIGH]

### 3.4 Cut-scene choreography [HIGH]
Scripts drive NPCs through the queue and block on global flags with builtin F1 `wait_for_flag`
(script-builtins: `LockOutUI`, loops `TActiveMonster::Guide()` until the flag is set). `1802 @14AD–1502`:
```
queue_activity(3, 160, 24, 23, Nil)    ; Magpie walks to (24,23)
queue_activity(3, 165, 255, 1, Nil)    ; … then sets flag 255
queue_activity(1, 164, 255, 0, Nil)    ; Hero waits for flag 255, clears it
queue_activity(1, 165, 254, 1, Nil)    ; … then sets flag 254
wait_for_flag(254)                     ; script resumes when both are done
```
`Guide @ 1004dbc0` runs one `DoTick(m, 1)` per active monster per call and `YieldToAnyThread`s. [HIGH]

---------------------------------------------------------------------------------------------
## 4. Pacing: `MoveAll`, `DoTick`, the clock — INDEX 16

### 4.1 When the world moves [HIGH]
`MoveAll @ 1004e334` is called from `HeartBeat` (after every player command, `HeartBeat(n)` first adds
n to the leader's busy), `BeginPlay`, `KeyRoutine`, `MouseRoutine`, `XDirection` (×2). It is **turn-
driven, not real-time**: it loops `DoTick(m, 0)` round-robin over the active list (starting after the
leader) and returns when a `DoTick` result is 3 or 4, i.e. when the **leader is free for input** or the
level changed:
```
if (((*(short *)(param_1 + 2) == *(short *)PTR_DAT_100cdbec) && … (param_1[0xb] == 0)) {
  if ((… & 0x20) == 0) && (… & 0x40) == 0) && (… & 0x4000) == 0 && (… & 0x2000) == 0)) { return 3; }
```
(`DoTick @ 1004ded8`: leader, not busy, not walking, empty queue, not afraid/paralysed/asleep/confused).
Off its game thread `MoveAll` only calls `TTaskMaster::ScheduleMonster`. [HIGH]

### 4.2 One tick per monster (`DoTick`) [HIGH]
- not alive (+6 bit 0) → 2: `MoveAll` destroys it (vtable +0x08, `FUN_100c50e8(iVar14,1)`);
- busy (+0x12) ≠ 0 → busy −1; **for the leader `DoTicks(viewer, 1, 0)` — the game clock advances
  1 unit (1/4096 h) per leader tick** (engine-classes §3.1); return 0;
- +0x18 ≠ 0 → `HandleSubMove` (vtable +0x2C): **+0x18 is the sub-tile movement phase** (HandleSubMove
  advances it by 1 or 2 per tick by preference bit `DAT_100d3e20 & 2`, then lands the move and zeroes
  it) — settles data-format §6.1's LOW row [HIGH];
- `GotAway` → 1 (`MoveAll` calls `LeaveLevel`, vtable +0x14);
- else, only if the monster is within **±13 cells** of the view centre: `ClearMonstStage`, `DoMove(
  leaderX, leaderY)` (vtable +0x10), `SetMonstStage`; a monster further away does **nothing**.
```
if (((-0xe < sVar12) && (sVar12 < 0xe)) && ((-0xe < sVar11 && (sVar11 < 0xe)))) { bVar4 = true; }
```
Vtable slots of the TActiveMonster table at 0x100D5BAC (`[0]` RTTI, `[4]` 0) ⚑ corrected (wave 1
2026-10-03): `toc.py 100d5bb4 … 100d5be4` gives each slot's TVector data offset (e.g. `100d5bbc
0x2eb8`), `toc.py <0x100CD280 + off>` its code offset — the sum done by hand, e.g. 0x100CD280 +
0x2EB8 = 0x100D0138 → `toc.py 100d0138` → `100d0138 0x4b8e8` ⚑ corrected (wave 1 2026-10-03); same
chain as combat.md §12.1's one-liner — `tb.py --at` the name
(`1004b8e8  1dec .DoMove__14TActiveMonsterFss`); 13/13 slots re-resolved:
+0x08 dtor, +0x0C Save, +0x10 DoMove, +0x14 LeaveLevel, +0x18 Die, +0x1C IsPartOfMonster, +0x20
CanFace, +0x24 CanMove, +0x28 HandleMove, +0x2C HandleSubMove, +0x30 AdjustAspect, +0x34
ClearMonstStage, +0x38 SetMonstStage. [HIGH]

### 4.3 Wall clock [HIGH for the disasm / MED for "no throttle"]
`MoveAll` computes a budget of 0x10 or 0x20 Mac ticks (sign bit of `DAT_100d3e20`) and only clamps the
global at 0x100CE898 with it; a scan of the whole code section (`ppcdis.py 10000000 100cd280 | grep --
'-27112(r2)'`) finds that global's TOC slot (−0x69E8) read **only in `MoveAll`** (0x1004E4F4,
0x1004E538, 0x1004E55C) and never compared again ⚑ corrected (wave 1 2026-10-03):
```
$ python3 docs/cythera/tools/ppcdis.py 1004e544 1004e568
1004e548: cmplw r3,r0 ; 1004e54c: ble 0x1004e568 ; … 1004e560: subf r0,r0,r3 ; 1004e564: stw r0,0(r4)
```
So **game logic has no wall-clock rate**: a step costs the leader busy 10 (≈ 10 clock units) and every
other monster gets the same number of `DoTick`s. The only timing in `MoveAll` is a 60-tick (1 s) guard
(`if (iVar10 + 0x3cU < uVar11) cdc40[leader] = 1`) after which pending mouse/key events are flushed
(`FlushEvents(0x2a,0)`, `FlushKeyDown`). Visible speed comes from sub-move animation and
`DrawRoutine` (17 `TickCount` uses; the 5-tick waits read are arrival transitions) — the per-frame
wait, if any, is NOT traced.

### 4.4 Schedules inside the tick loop [HIGH]
`ScheduleTime(hour, force)` (rules.md §3.1) is called from `DoTicks` (hour change / > 100 units),
`GoToLocation`, `NewModel`, builtin E0 `reschedule`; so during `MoveAll` it runs at the leader tick
that crosses the hour. Builtin BD `pass_time(n)` = `DoTicks(n,0)` — shipped calls use n = 1024
(¼ h: `1091 @011D`, `0E93 @00C1`). ScheduleTime also re-points tiles by hour for every type with
property 41 (`_GetProperty__7TInterpFs5VAddrs(&local_54,0x29,local_4c,(int)(short)param_1)`).
`RepositionChar` (rules.md §3.4) sets activity 0x80 while a visible NPC walks; **nothing native
restores the target activity it parks in prop byte 7** (grep of the dump and DoMove) — the NPC idles
(0x80 → busy 20) until the next hourly pass. [MED: absence]

---------------------------------------------------------------------------------------------
## 5. Party follow, leader busy (A3), join/leave [HIGH]
- Builtin A3 `add_leader_busy(n)`: leader +0x12 += n. Shipped: `1025 @0472` (40), `1AFF @0027` (10).
- `JoinParty`: activity := 1, alignment +0x19 := 2 (good). `LeaveParty`: activity := **0x8F** (roam).
  `RebuildParty`: hatched-egg party members get activity 2 (leader) / 1.
- `DoAttack`, `DoDefend`, `DoRetreat` with no target: party members fall back to activity 2 (char 1)
  or 1; others roam (busy 8).
- Formation (activity 1, party mode 1): offsets (dx, dy) for rank r and leader facing f =
  `565C[r + 8f]`, `56DC[r + 8f]`; f = 0: dx (−1, 1, 0, −2, 2, −1, 1, 0), dy (1, 1, 2, 2, 2, 3, 3, 4) — a
  wedge behind the leader. ⚑ corrected (wave 1 2026-10-03): both tables are **i32 words** — DoMove
  `iVar8 = (int)param_2 + *(int *)(&DAT_100d565c + ((int)sStack_86 + sStack_88 * 8) * 4);`
  (`Cythera_extra.decompiled.c` (CyDecompAt.java, extra-addrs.txt)); values by `python3 -c "import sys;sys.path.insert(0,'docs/cythera/tools');import toc;print([x-(1<<32) if x>>31 else x for x in toc.data_u32(0x100d565c,8)],[x-(1<<32) if x>>31 else x for x in toc.data_u32(0x100d56dc,8)])"`
  → the two rows above (read as i16/i8 they are not). Followers take busy = leader monster
  +0x3E. Mode 2 snapping is rules.md §2.

---------------------------------------------------------------------------------------------
## 6. Signals (selector 21) and hostility

### 6.1 Who receives `SendSignal(n)` (`SendSignal @ 10053794`) [HIGH]
For n ≠ 0, selector 21 with arg n goes to: the **zone** object (class 0x20, id = leader's level byte),
the **current room** (class 0x58), then (n < 0x100 only) every on-map prop (`kind & 0x5D` ∈ {0, 1})
whose type flag 0x10000 is set **and whose byte 6 (quality) == n** — the wiring channel; then every
alive character **on the leader's level** (chars < 0x100 as class 0x40, runtime chars as their body
prop); then `TGremlin::OnSignal(n)` (256 gremlin slots, class 0x78; no 0x1Fxx segments ship, so they
fall to `3015`). Other selector-21 senders: `DoTicks` (0x101 hourly chime to props with property 39
bit 0x100; timer props, §7.2), `TSpellFX::PassTime/RemoveAllAbility`.

### 6.2 Signal numbers seen [HIGH unless marked]
| n | sender | meaning |
|---|---|---|
| quality / byte7 of the prop | levers `10BB @001F/@002B`, buttons `1107 @0045`, `1104`, `1110`, loose board `1162 @001B`, fine wire `1165 @005F`, coffer slide `108E @00B8` | lever/door/trap chains: the receiving props carry the same number in byte 6 |
| type of a 'B' trigger | `DrawRoutine` frames 2 and 6 (§7.1) | step-on / area triggers |
| 0x100 (256) | `TakeCommand`: `if (local_60 != *(int *)puVar3) { _SendSignal__8TGameSysFs(param_1,0x100); }` after sending selector 15 to the item; `puVar3 = PTR_DAT_100cdbb0;` (Nil) and, just before, `if (local_60 == *(int *)PTR_DAT_100cde70) { return; }` (False) | **theft** — the take hook (default 300F) returned neither False (abort) nor Nil (quiet take) ⚑ corrected (wave 1 2026-10-03: `puVar3` identified, same reading as script-library §9 300F) [HIGH] |
| 320 | `0D06 @0077` | alarm raised by a witness |
| 321 | `3043 @0096` | a party member provoked a neutral/good non-party character |
| 0x101 | `DoTicks` | hourly chime |
| 1, 34, 35, 100+frame, 129–135 | 0x1864 (Gate Guard), bell 0x10C1, half disk 0x10E8, panpipes/lyre/crystal/zone 0x1417 | scenario-specific — not traced |
| A31 | 0x0C48 (queued activity 0x48) | scripted |

### 6.3 Theft and assault — the reaction chain [HIGH]
- `3015` (default selector 21 for characters): on 256, if the current zone has property 36 → ignore;
  else by the character's monster-record byte 6 (`as_cls48(A30).f35`; `GetField` class 0x48 `case
  0x35: *param_1 = (uint)pbVar7[6];` = the record's default alignment, cf. ctor `+0x19 = rec[6]`):
  **0 (neutral) → `0D06`**, **2 (good) → `0D07`**, others ignore.
- `0D06`: on 256, if `leader_can_see(self)` → bark "Hey! Stop that!" / … and `send_signal(320)`; on
  321, if seen → `target := leader`, `activity := 6` (Beserk).
- `0D07` (also the shared selector-21 method of 0x102E, 0x1846–0x1849, 0x1864, 0x1865 — guards): on 256
  → `0D06`; on **320 or 321 → target := leader, activity := 6 with no sight check**.
```
0D07 @0014: jf ((A31 == 320) || (A31 == 321)) -> 003B
0D07 @002D: setfield L00.f22:target = G05:leader
0D07 @0034: setfield L00.f15:activity = 6
```
- Selector **67** ("provoked by A31"; no class defines it, default `3043`): last attacker (f2A →
  monster +0x20) := A31; activity := behaviour; if the victim is the Hero or in the party, every other
  party member not already in its behaviour switches too; if A31 is in the party and the victim is not
  and the victim's record alignment is 0 or 2 → `send_signal(321)`. Senders: `3042 @0282` (selector 66
  default), `0EA3 @0221`, spell classes 0x1A06/0x1A12/0x1A1D/0x1A22/0x1A2D, `0C4C @0075`.
Net effect: stealing in sight of a neutral → alarm 320 → every good/guard character on the level goes
Beserk on the leader; hurting a neutral/good NPC → 321 → guards and seeing neutrals attack. Who
attacks whom afterwards still goes through `GetEnemyStatus` (rules.md §1); the targeting itself is
the f22 field, so a neutral on Beserk attacks its set target. [HIGH code / MED combat consequence]

### 6.4 The all-ally override byte — INDEX 18 settled [HIGH disasm / MED key name]
A scan of the whole code section for the TOC slot of `PTR_DAT_100cde4c` (r2 − 0x7434;
`ppcdis.py 10000000 100cd280 | grep -- '-29748(r2)'`, builtin block included) finds three uses: the
read in `GetEnemyStatus` (0x100487DC) and a **toggle** in `TMapWindow::KeyRoutine` (`tb.py --tb --grep
KeyRoutine__10TMapWindow` → entry 0x100437B8) ⚑ corrected (wave 1 2026-10-03):
```
$ python3 docs/cythera/tools/ppcdis.py --hex 10043c58 10043c60 ; … --hex 10043fcc 10043ff0
10043c58: cmpwi r0,0xfa ; 10043c5c: beq 0x10043fcc
10043fcc: lbz r0,0x0(r28) ; 10043fd0: cmplwi r0,0x0 ; 10043fd4: beq 0x100446b4
10043fd8: lwz r4,-0x7434(r2) ; 10043fdc: lwz r3,-0x7434(r2) ; 10043fe0: lbz r0,0x0(r4)
10043fe4: cntlzw r0,r0 ; 10043fe8: rlwinm r0,r0,27,5,31 ; 10043fec: stb r0,0x0(r3)
```
i.e. key code **0xFA** (Mac Roman "˙", Option-h) toggles it when the byte at r2 − 0x7430 (0x100CDE50;
`100437d4: lwz r28,-29744(r2)`) is set. That byte is toggled at 0x10043844 when the last four keys are
**0xA9 'g' 'r' 'a'** (`ppcdis.py 10043814 10043888`: `10043828: addis r0,r4,22169` = 0x5699,
`1004382c: cmplwi r0,0x7261` ⇒ buffer 0xA9677261) and bit 0 of byte 0x100D3E23 is set. So the
override is a **debug cheat ("everyone is an ally")**, not game logic; nothing else writes it and it
is not saved. ⚑ corrected (wave 1 2026-10-03): a design sentence was removed here (house register).

---------------------------------------------------------------------------------------------
## 7. Map and room hooks

### 7.1 'B' (kind 0x42) trigger props — `DrawRoutine @ 1005c844` loop [HIGH]
On a full redraw, `cde74` (current room) := 0, then for every hood prop of kind 0x42 that is
`InZone`: index < 0x100 (an unhatched character body) → `HatchEgg(index, leaderX, leaderY)`; else by
**frame**: 0 egg spawner (`HatchEgg`, §8); 1 teleport when the leader is in its area (`GoToLocation` from table `cdc00[type]`, arrival byte
`cdbfc[type]` — the teleport tables of rules.md §2 [MED identity]); 2 step-on (leader exactly on it) → `SendSignal(type)`, then disabled
(kind |= 0x80); 4 `ChangeZone(type)`; 5 `PlayMusic(type)`; 6 area trigger → `SendSignal(type)`,
disabled; 7 conditional visibility: `EvalCondition(byte6, byte7)` shows (clears 0x80, `AddToHood`) or
hides the next `type` props; **8 room rectangle** → `cde74 := type` (`GetRoom` uses the same 'B'
frame-8 rectangles, width byte 6, height byte 7); 10 countdown of byte 6. Frame 3 is not handled here.
Frame **9 = timer** (`DoTicks`, rate 16 units): byte 6 counts down; at 0 selector 21 goes to the owner
(location low 16: 0 → current zone, < 0x100 → that character, else that prop) with **the timer prop
as argument**. Scripts create timers with `0F15` = `create_prop(66, 0, owner, 9, type, count,
byte7)`, e.g. `1401 @00AF` `R0F15(1, 4, 2, 0)`. [HIGH]

### 7.2 Enter / first visit (`HeartBeat @ 10053a80`) [HIGH]
When `cde74` changed to a non-zero room: selector **20** to the room (class 0x58, `|0x40580000`), to
every non-party character whose `GetRoom` is that room, `TGremlin::OnEnter(room)`; then, if room flag
bit 0 is clear, selector **7** to the room and set the bit. Zones get 20 from `ChangeZone`.
Census of methods (listing headers): selector 7 — rooms only (0x1B ×110, 0x1C ×36), bodies are
narration (157 text runs, 6 `show_portrait`, 3 `begin/end_talking`…); selector 20 — zones 0x14 ×42,
0x15 ×3, rooms ×9 (0x1B0F, 0x1B11, 0x1B3B, 0x1B5E, 0x1BCA, 0x1BD5, 0x1C2D, 0x1CC5, 0x1CC6), 0x1E20 ×1;
zone bodies set the environment (`set_map_title` 44, `play_music2` 43, `set_zone_light_minimum` 42,
`set_outdoor_sky` 42, `set_erase_colour` 12) and advance plot variables (`1401 @0020–@008D`). The
default for selector 7 (`3007`) prints what a character is doing (§2.1), so a selector-7 send to a
character is a "look" description. [HIGH counts / MED "look" reading — no native sender of 7 to
characters was found]

### 7.3 Script prop creation [HIGH]
The 56 `create_prop` calls use kinds 28 (×17, temporary skills/spells), 9 (×15, contained), 24 (×11,
equipped), 33 (×5, plain spawned prop — e.g. `0E8D @0016` type 77), 1 (×3, on map), 16 (×2,
inventory), 66 (×1, the 0F15 timer) and two computed kinds. **No script spawns a monster**: monsters
come only from 'B' frame-0 eggs and character bodies (§8).

---------------------------------------------------------------------------------------------
## 8. Spawning and monster classes

### 8.1 `HatchEgg(egg, x, y)` for an egg prop ≥ 0x100 [HIGH]
- Chance: `if (egg.byte7 < (Random() & 0x7fff) % 100) egg.kind |= 0x80` (fails → dormant).
- Time gate on egg byte 6: 0x20 → only when clock ≤ 0x6000 or > 0x12000 (**night**, before 6:00 /
  after 18:00); 0x10 → only 6:00–18:00 (**day**); 0x01 → egg.byte7 := 0x65 (always hatches next time).
- Templates: every prop whose location word has bit 0x8000000 and low 16 bits = the egg index; its
  byte 7 = how many; property 55 (monster class) Nil → plain prop kind 0x21 (count kept if egg byte 6
  & 4), else kind 0x24 + `CreateMonster(class, newProp)`, activity := template byte 6, behaviour per
  §2.3, monster +0x14 := template, then selector 32 to the new character and selector 0 to the prop.
- Placement: random walk of up to 16 steps from the egg, each step `CanMove`-checked, kept within ±15
  of (x, y) and on a cell whose quarter-grid owner (viewer +0x15FF4) is empty. After the loop the egg
  is disabled (kind |= 0x80). Who re-arms eggs is NOT traced.
- Runtime characters: for a body prop ≥ 0x100 the `TActiveMonster` ctor takes the first free
  CharEntry 0x100–0x1FF and rolls a strength percentage by `_DAT_100d73f2` (0: 10–49, 1: 25–99, 2:
  50–149, 3: 100–199, 4: 150–299, else 100) applied to the monster record's Body/Reflex/Mind/Health
  (record bytes 0, 1, 2, 5); alignment := record byte 6; level from HP and stats; +0x1F := the roll.
  [HIGH code] ⚑ corrected (wave 1 2026-10-03): writers of `_DAT_100d73f2` — HIGH: the only r2-relative
  references in the code section (`ppcdis.py 10000000 100cd280 | grep 'r2,8562'`) are the ctor
  `10044ba8: addi r21,r2,8562`, `SaveToFile` `100130f4: addi r7,r2,8562` and `RestoreModel`
  `10014180: addi r7,r2,8562` (the 'Char' stream `hhhh` save/restore), so only the restore writes it;
  the name "difficulty" — MED (open-items §8, combat §4.1).

### 8.2 Classes by property 55 (`CreateMonster @ 1004eb08`) [HIGH]
| prop 55 | class (size) | difference |
|---|---|---|
| 9, 10 | `TCrawlMonster` (0x9C) | a chain of N body props (N = property 54, or 1 when prop 55 == 10) at +0x5C…; own `CanMove`, `HandleMove`, `HandleSubMove`, `IsPartOfMonster`, stage methods; **`CanFace` returns 0** (cannot turn in place) |
| 11 | `TDragonMonster` (0x68) | 4 extra props at +0x58 (copies of the body) arranged by its own `AdjustAspect` (0x1004AF1C) |
| 12 | `TOctoMonster` (0x78) | 8 extra props at +0x58 at the 8 compass offsets (0x100D55B4/C4: dx 0,1,1,1,0,−1,−1,−1; dy −1,−1,0,1,1,1,0,−1), frames 4·i, type = property 54; own `HandleMove/HandleSubMove/IsPartOfMonster` |
| other | `TActiveMonster` (0x58) | single tile; `CanFace` returns 1 |
Sprite layout (base `AdjustAspect`, ctor) by the same property: 0, 1, 10 → 2 frames per facing; 3 →
1; 4 → 4; 7 → facing·8 + 3 (+4 alternate); 9 → facing·8; others a single frame. [HIGH]

### 8.3 Pathfinding limits (`TPathFinder`) [HIGH]
Greedy best-first, not A*: candidates ordered by **Manhattan distance to the goal only**
(`CalcWeight`: `|dx| + |dy|`), 8 neighbours tried through `TGameSys::TryMove` with the monster's
attributes | 0x8000000; a **31×31** visited grid centred on the view (`ResetPaths`: clears 0x3C1 =
961 bytes); a pool of **100** candidates (`if (*(short *)(param_1 + 0x880) == 100) return;`); start
must be within ±15 of the view centre, else 0x7FFF (no path); result = the best weight reached, 0x7FFF
when nothing beats the start. `SetWaypoint` stores the destination and the first waypoint; `DoMove`
re-plans on arrival at each waypoint.

---------------------------------------------------------------------------------------------
## 9. `PerformAI` and `CompileAIFile` callers — INDEX 14 (second half)
- `PerformAI(m, slot)` (`tb.py --grep PerformAI` → entry 0x100B0BA4) is called **six times, all from
  `DoMove`** ⚑ corrected (wave 1 2026-10-03): `ppcdis.py 1004b8e8 1004d6d4 | grep 'bl 0x100b0ba4'` →
  `1004c51c`, `1004c57c`, `1004c5a8`, `1004c608`, `1004c688`, `1004d5bc`, each preceded by `li
  r4,209`/`212`/`210`/`211`/`208` (0xD1/0xD4/0xD2/0xD3/0xD0) or `1004d5b8: lha r4,376(r1)`; the same
  grep over the whole code section (`ppcdis.py 10000000 100cd280`) finds no other `bl 0x100b0ba4`.
  Slots 0xD1/0xD4/0xD2/0xD3/0xD0 serve activities 3/4/5/6/8 (extra dump: `case 3:
  cVar11 = .debug::_PerformAI__FP14TActiveMonsters(param_1,0xd1);` …) and the activity value itself
  for 0xB0–0xFF. The main dump showed no caller because DoMove was never made a function there. It
  loads segment 0x360 + slot (≥ 0x20 bytes), opens `TAIDebug` for flagged slots 0xB0–0xCE, runs
  `EvaluateAI`, returns 1; missing segment → 0 (native fallback). [HIGH]
- `CompileAIFile` (entry 0x100B0EF8): ⚑ corrected (wave 1 2026-10-03) the whole-code-section scan
  (`ppcdis.py 10000000 100cd280 | grep 'bl 0x100b0ef8'`) finds one direct call, `100b1854: bl
  0x100b0ef8  ; .CompileAIFile__FR6FSSpecs`, inside `DialogItemRoutine__17TEditUserBehaviorFs`
  (`tb.py --at 100b1854` → entry 0x100B1780) — the `EditUserBehaviors` lead of ai-scripts §6 [HIGH
  direct call; indirect calls through a TVector not searched, MED that it is the only path].

---------------------------------------------------------------------------------------------
## 10. Open items
1. **Done** ⚑ corrected (wave 1 2026-10-03): the tools are banked (`tools/tb.py`, `tools/ppcdis.py`,
   `tools/CyDecompAt.java` + `extra-addrs.txt`) and DoMove, Die, LeaveLevel, CanFace and the subclass
   overrides are in `ghidra/Cythera_extra.decompiled.c`; still absent from the main dump: 877 named
   functions (`tb.py --missing ghidra/Cythera_pef.decompiled.c`), 840 counting the extra dump.
2. **Done** ⚑ corrected (wave 1 2026-10-03): `CompileAIFile` direct caller =
   `TEditUserBehavior::DialogItemRoutine` (§9); TVector (indirect) callers not searched.
3. Per-frame wall-clock wait in `DrawRoutine` / `HandleMove` (what Ben's "feel" pacing is).
4. Who re-arms spent 'B' eggs (kind bit 0x80); 'B' frame 3; what restores an NPC's activity after a
   visible walk (prop byte 7).
5. Party mode values (`cdbe8`): 1 = formation follow, 2 = snap (rules.md); 0 not traced.
6. `_DAT_100d73f2` (strength roll) — writer settled (restore stream only, §8.1 ⚑ corrected (wave 1
   2026-10-03)); no menu or UI writer found (absence of a reference, MED).
7. Routines 0x0C86 (work animation), 0x0EB7 (equip), 0x0C00 callers; 0x3042 (selector 66) fully.
8. Signal numbers 1, 34, 35, 100+frame, 129–135: receivers.
9. Confirm in play (Ben's eyes): Missile-Script monsters wandering toward the map's top-left corner
   (098A), OutOfAmmo never firing, SetProtecting freezing a monster (unused in shipped AIs).
