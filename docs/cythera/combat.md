# Cythera 1.0.4 — combat (to-hit, damage, armour, death, experience)

Register: **code reading** (bytecode listings + decompiled native code; nothing behaviour-verified —
Ben's eyes are the behaviour oracle). Settles INDEX NOT RESOLVED 15 (combat part) and extends
rules.md §1/§2 and data-format.md §5/§6. Labels: **HIGH** = quoted bytecode or decompiled lines prove
it; **MED** = inferred from structure, names or a single source; **LOW** = conjecture.

---------------------------------------------------------------------------------------------
## 0. Scope, method, what was not read

- Sources read this session: listings `ghidra/cythera-scripts/<seg>.txt` for 301C 301D 301F 3040
  3041 3042 3043, 0E81–0E8F 0E90 0E95 0E96 0EA3 0EAC 0EB8, 0F0C 0F0D, 0C49, 1801 (sel 29), 185C,
  1914/1916/191A/191D/1923/1924, 1AC0–1AD6 (skill names), the weapon/armour classes in 105E–1187;
  `Cythera_pef.decompiled.c`: `AttackCommand__8TGameSysFs/Fss`, `DoAttack__14TActiveMonsterFv`,
  `DeathRites__9CharEntryFv`, `HatchEgg`, `CreateMonster`, `__ct__14TActiveMonsterFs`,
  `__dt__14TActiveMonsterFv`, `ObjToMonst__Fs`, `Ctor__Fsss`, `GetField__Fsss`, `SetField__Fsss5VAddr`
  (cases 0x13–0x2A), `GetGlobal__Fs`, `DoExpr` cases 0x4A–0x4E, 0x56, 0x60–0x63, `AddAbility__8TSpellFX`,
  `FindSkill__Fss`, `MoveAll` (the `cdd98` store), `DoInterp__7TInterpFs5VAddr[5VAddr]`, the
  `TakeCommand`/`WieldCommand` encumbrance tests; `Cythera_builtins.decompiled.c` `Builtin_AC`,
  `Builtin_F5`; segment 0xF008 and CharEntry 0–2 of 0xF009 (raw, via `tools/seg.py`); STR# 500/501.
- ⚑ corrected (wave 1 2026-10-03): native bodies the main dump lacks come from `Cythera_extra.decompiled.c` (CyDecompAt.java,
  extra-addrs.txt): `Die__14TActiveMonsterFv @ 100469c0` and `LeaveLevel__14TActiveMonsterFv @
  100465a4` (§12.2). Listings and names from the banked tools only: `docs/cythera/tools/ppcdis.py`
  (the `DeathRites` virtual call), `tb.py --at` (names), `toc.py`'s `data_u32` (vtable words, §12.1).
  The earlier throw-away decoder is no longer cited.
- Not read: the hintbook PDFs and the Documentation viewer (no LOW claim below cites them); the
  `TMissile*` / `TBres` / `ShowAttack` / `ShowHit` bodies (animation only — see §1 why they cannot
  hold arithmetic); `DoDefend`/`DoRetreat` and the AI choice of target (ai-scripts.md owns it); spell
  internals beyond the combat entry points (R0EA3, R0EB8 callers).
- Notation: `rnd(lo,hi)` = builtin 0xAC (§2.3); integer arithmetic is DoExpr's (C `int`, `/`
  truncates toward zero, `/0 → 0`, a non-integer operand leaves the left operand unchanged). Field
  names `.fNN:name` are scriptdis's `GetField` names; CharEntry offsets are data-format.md §6.1.

---------------------------------------------------------------------------------------------
## 1. Verdict: combat arithmetic is script bytecode on pages 0x30 and 0x0E [HIGH]

No class answers any combat selector itself (census §5: sel 28 `attack` 0 methods; sel 64, 66, 67
0 methods; sel 65 has 19 methods, **all on prop classes 0x10xx/0x11xx**, none on characters —
dictionary scan of the listings). So `DoInterp0`'s `0x3000+selector` fallback (script-vm.md §2.1)
runs one routine per selector for every creature:

| selector | default routine | role (this file) |
|---|---|---|
| 28 attack (sent natively) | 0x301C | reach/time wrapper → sends 66 |
| 66 | 0x3042 | choose melee / unarmed / thrown / launched attack |
| 64 | 0x3040 | damage **absorption** (resistances, armour, Defense) |
| 65 | 0x3041 | **apply** damage, status side-effects, wound messages |
| 67 | 0x3043 | victim is provoked (combat mode, party rally, guard signal) |
| 29 death (sent natively) | 0x301D | death effects (delegates to the creature class) |

The arithmetic routines they call are 0x0E81–0x0E96, 0x0EAC (census symtab leaves them unnamed).
Native code only sends 28/29, stores the returned delay, and runs `DeathRites` when a script writes
health < 1 (§12). The native `TMissile*`/`TBres` path is reached only through builtin 0xE2, which
returns Nil and only marks burst victims (script-builtins.md row E2); `ShowAttack`/`ShowHit` are the
visual builtins 0xE4/0xE3. [HIGH: census §5 + the listings below; MED for "animation only" of the
unread native bodies]

Call graph (one attack): `AttackCommand`/`DoAttack` → sel 28 → **0x301C** → sel 66 → **0x3042** →
R0E88 (melee/unarmed) or R0E89 (ranged) → **R0E87** (parry, damage roll, messages) → sel 64
**0x3040** → sel 65 **0x3041** → [SetField health → `DeathRites`] → R0E8B (XP) → R0E86 (level up);
0x3042 then sends sel 67 → **0x3043**.

---------------------------------------------------------------------------------------------
## 2. Native plumbing

### 2.1 Who attacks [HIGH]
`AttackCommand__8TGameSysFs @ 10055288` sends 28 to the **leader** (`VAddr(4,0x40,*leader)`) with the
target (character object if it has an active monster, else prop object), after setting the
target's status bit 8 (IsAngry); an integer result is the time cost:
```
*(ushort *)(*piVar5 + 6) = *(ushort *)(*piVar5 + 6) | 8;
_DoInterp__7TInterpFs5VAddr5VAddr(local_48,0x1c,local_4c,uVar4);
if ((local_48[0] & 0xf0000000) == 0) {
  _HeartBeat__8TGameSysFs(param_1,(int)(short)((int)(local_48[0] << 4 | local_48[0] >> 0x1c) >> 4));
```
`DoAttack__14TActiveMonsterFv @ 10047e6c` (monsters and auto-fighting party members) sends the same
selector; an integer result **overwrites** the busy byte, a non-integer gives busy 8 + `GoTowards`:
`*(char *)(*param_1 + 0x12) = (char)((int)(local_3c << 4 | local_3c >> 0x1c) >> 4);`
The cell form `AttackCommand__8TGameSysFss @ 10055254` is an empty stub (`{ return; }`) — clicking
empty ground does nothing. [HIGH]

### 2.2 0x301C — sel 28 default: time cost [HIGH]
```
0003: jf  is_char(A31) -> 0086
000A: jf  (A30 == char#1"Hero") -> 0051          ; Hero attacks: every other party member
003A: setfield L00.f15:activity = L00.f16:behaviour ;   switches to its combat behaviour
0057: jf  A30.sel66(A31) -> 007C                 ; Nil → "It is too far away to attack"
0060: set L04 = (192 / A30.f18:reflex)
006C: setfield A30.f23:busy = (A30.f23:busy + L04) ; return L04
```
Prop targets: `jf A30.sel66(A31) -> 00A1`, `busy + 12`, `return 10`. Delay per attack = `192 /
Reflex` (integer; Reflex 0 → 0 by DoExpr's `/0`). `f23:busy` is CharEntry +0x12 (GetField case 0x23)
and SetField stores it as a **byte**. For monsters the script's `+=` is then overwritten by
`DoAttack`'s store (§2.1). [HIGH]

### 2.3 `random` (builtin 0xAC) [HIGH]
```
sVar4 = .glue::Random();
uVar2 = (int)sVar1 - (int)sVar3;
*param_1 = (int)sVar3 + ((int)sVar4 - ((uint)(int)sVar4 / uVar2) * uVar2) & 0xfffffff;
```
`rnd(lo,hi)` = `lo + (unsigned)(signed 16-bit Random()) mod (hi−lo)` → **lo … hi−1** (exclusive);
`hi ≤ lo` → `lo`. So `rnd(0,30)` is 0–29 and `rnd(0, n+1)` is 0–n. The modulo is taken on the
**unsigned** 32-bit value of the sign-extended 16-bit `Random()` (a negative result becomes
2³²−k), so results over lo…hi−1 are not exactly uniform (⚑ corrected (wave 1 2026-10-03): code fact only). [HIGH]

---------------------------------------------------------------------------------------------
## 3. Item properties that combat reads [HIGH for the reads, MED for the role names]

Properties are class-dictionary lists read with 0x61 `prop(obj, sel, i)`; a non-object receiver
yields **Nil** (DoExpr 0x61: `else { … *(iVar8 + sVar18*4) = *(undefined4 *)puVar4; }`, `puVar4 =
PTR_DAT_100cdbb0` = Nil). Element meanings below are fixed by the reading sites quoted in §5–§9.

| sel | element → used as (site) |
|---|---|
| 42 melee weapon | [0] damage base (3042 @0071) · [1] reach, compared as `[1]*[1] >= d²−1` (3042 @0062) · [2] damage-type flags (R0E87 @02A7) · [3] skill id (R0E87 @0081, but see §7.3) · [4] miss sound (R0E87 @03CA) · [5] hit sound (@00D5) · [6] attack-animation list for `show_attack` (@00E4) |
| 43 throwable | [0] damage base · [1] range · [2] missile style flag (`L06 = 1`) · [3] missile tile/arg 7 of 0xE2 (3042 @00EA–@012B) |
| 46 launcher | [0] ammo kind · [1] range · [2] damage base · [3] fire sound (3042 @017F–@01FB) |
| 45 ammunition | [0] ammo kind (must equal launcher [0]) · [1] missile arg · [2] damage-type flags (R0E87 @02B8) |
| 44 armour | [0] armour value, summed by R0E81 |
| 47 parry item | [0] parry value · [1] skill id (R0E87 @0037) |
| 38 `p26` | [0] item class; R0E81 tests `& 8`; R0E87 requires its presence for the quality bonus |
| 36 `p_weight` | weight only — **no combat routine reads it** (none of the listed routines contains `sel36`) |

Quality = prop byte 6 (`.f06:quality`), added to to-hit and damage when the weapon has sel 42
**and** sel 38 (R0E87 @006A–@007B). Shipped values (`.dict` lines of the class listings, arrays
resolved from the same listing):

| class | item | weight | p26 | 42 / 43 / 44 / 45 / 46 / 47 |
|---|---|---|---|---|
| 105F | dagger | 4 | 4 | 42=[6,1,1,196,16,17,…] 43=[6,3,True,14] |
| 1060 | club | 15 | 4 | 42=[8,1,4,198,16,18,…] |
| 105E | mace | 18 | 4 | 42=[15,1,4,198,16,18,…] |
| 1063 / 1062 | sword / sword | 14 / 34 | 4 / 5 | 42=[15,1,1,196,…] / [20,1,1,196,…] |
| 1061 | axe | 47 | 5 | 42=[22,1,1,197,16,17,…] |
| 1064 | spear | 12 | 5 | 42=[10,2,2,196,16,18,…] 43=[10,4,False,13] |
| 1178 | mystic spear | 20 | 5 | 42=[35,1,130,196,…] 43=[25,8,False,13] |
| 1119 | sword (type 281) | 20 | 4 | 42=[30,1,129,196,…] |
| 1155 | gauntlets | 10 | 5 | 42=[20,1,132,199,16,18,Nil] 47=[4,199] |
| 1067 / 1069 | bow / sling | 10 / 6 | 5 / 4 | 46=[1,5,10,11] / [2,4,6,0,12] |
| 1066 / 1065 / 1068 | arrow / magic arrow / sling stone | 1 | — | 45=[1,13,1026] / [1,13,1154] / [2,13,1028] |
| 106A / 106B / 1177 | cuirass / breast plate / mystic armor | 24/68/75 | 2 | 44=[3] / [6] / [11] |
| 1070 / 1071 / 1072 / 1176 | leather helmet / helmet / full helmet / mystic helmet | 4/10/24/24 | 0 | 44=[1]/[2]/[3]/[6] |
| 1088 / 1153 | cloak / fur cloak | 10 / 20 | 9 | 44=[1] / [10] |
| 106C–106F | buckler … full shield | 10–40 | 3 | 47=[1..4, 201] |

Skill ids are kind-0x1C props of type 192+ (class 0x50 → segment 0x1A00+type); their `name`
methods return 192 "Attack", 193 "Defense", 194 "Mana", 196 "Sword", 197 "Axe", 198 "Mace",
199 "Barehand", 200 "Missile", 201 "Shield" (`1AC0 @0005: return "Attack"` … `1AC9 @0005`). [HIGH]

**Skill level** R0EAC(char, id): `L00 = find_skill(A30, A31)`; Nil → 0; `jf (L00.f03:frame & 16)`
→ frame & 16 set → **0**; else the skill prop's **frame** (0–15). [HIGH]

**Damage-type flags** (values from the sites above and §11): 1 edged, 2 piercing, 4 blunt (also
the unarmed default), 8 checked against IsLavaProof (fire), 128 magic (set by quality > 0, or in
the weapon's own flags 129/130/132), 256 "poisonous" (natural attacks of creatures with record
`f33 & 8`), 0x400 on all ammunition; 32, 64, 0x800, 0x1000 come only from spell/trap callers of
R0EB8. [HIGH for which bit each routine tests; MED for the element names "fire/magic/edged…"]

---------------------------------------------------------------------------------------------
## 4. Creature table 0xF008 = class 0x48 (`as_cls48`) [HIGH]

`Ctor__Fsss @ 10091dd4` casts a character to class 0x48 via its CharEntry +0x14 type:
`iVar5 = _ObjToMonst__Fs(*(ushort *)(PTR_DAT_100cdbf0 + sVar6 * 0x20 + 0x14) & 0x3ff);` and
`ObjToMonst__Fs @ 10044a60` scans **128 records of 16 bytes** keyed by u16 +0xC (`if (0x7f < sVar1)
return 0; … if (*(short *)(iVar2 + 0xc) == param_1) return iVar2;`). ⚑ This corrects data-format.md
§5's "first 0x800 bytes = header … 0 records": the first 0x800 bytes **are** this table;
`LoadGlobals` points a second list `PTR_DAT_100cdc30` at base + 0x800 with count
`(size − 0x800) >> 4` (`*(int *)PTR_DAT_100cdc30 = *(int *)puVar3 + 0x800;`), which is the empty
one. The shipped file has **50 records** (record 50 is zero). Field map (`GetField__Fsss` class 0x48 cases):

| byte | field | meaning (reader) |
|---|---|---|
| 0, 1, 2 | 0x2C, 0x2D, 0x2E | base Body, Reflex, Mind (monster ctor, §4.1) |
| 3 | 0x30 | natural armour (0x3040 `L00.f30`) |
| 4 | 0x31 | natural damage base (0x3042 @0258 `L00.f31`) |
| 5 | 0x2F | base Health (monster ctor) |
| 6 | 0x35 | alignment → CharEntry +0x19 (ctor); karma table index (R0E8D) |
| 7 | — | **open** ⚑ corrected (wave 1 2026-10-03): no `GetField` class-0x48 case (the cases are 0x2C–0x33, 0x35, 0x36), and neither the monster ctor (bytes 0, 1, 2, 5, 6) nor `Die` (+0xE) reads it [HIGH for those three readers; "no reader anywhere" MED] |
| 8–9 | 0x33 | flags A: 1 = to-hit uses Body, 2 = immune to all damage, 4 = immune to flag 1, 8 = natural hits add flag 256 |
| 10–11 | 0x32 | flags B: resistances (§9), 64 = poison-immune (0x3041), 0x2000 = group death (R0E8D), 0x4000 = leaves blood (R0E8D) |
| 12–13 | — | object-type key |
| 14–15 | 0x36 | s16 corpse item (type \| frame<<10) created on death, 0 = none — `Die` reads `*(ushort *)(param_1[1] + 0xe)` (§12.2) ⚑ corrected (wave 1 2026-10-03) |

Examples (`python3` over `seg.toc()`, 16 bytes per row): rec 0 key 32 "hero" `0c 0c 0c 00 03 14 02
00 00 00 00 04 00 20 11 1b` (12/12/12, armour 0, fist 3, health 20, align 2, corpse 0x111B = type
283 "corpse" frame 4); rec 1 key 47 "ruffian" `0f 0c 08 02 04 14 01 00 00 01 40 04 00 2f 04 4e`;
rec 3 key 34 "king" `1e 1e 1e 1e 64 ff 02 00 80 02 01 f4 …` (f33 = 0x8002 → immune). Flag census
over the 50 records: f33 bit 8 on 5 (e.g. rec 20 key 88 "asp" `… 40 08 40 40 00 58 …`).
[HIGH for bytes/readers; MED for the role names in the last column]

### 4.1 Spawned-monster statistics (`__ct__14TActiveMonsterFs @ 10044b98`) [HIGH]
For prop index ≥ 0x100 the ctor takes the first free CharEntry 0x100–0x1FF and rolls a **scale** s
from the save-stream word `DAT_100d73f2` (called "difficulty" here — the name is MED, ⚑ corrected (wave 1 2026-10-03)): 0 → `Random()%40+10`, 1 → `%75+25`,
2 → `%100+50`, 3 → `%100+100`, 4 → `%150+150`, other → 100 (`uVar5` is `ushort`). Then
```
*(char *)(*param_1 + 0x1f) = (char)sVar6;                                   /* +0x1F = scale % */
*(char *)(*param_1 + 9) = (char)(((uint)*(byte *)param_1[1] * (int)sVar6 + 0x32) / 100);
*(char *)(*param_1 + 0xe) = (char)(((uint)*(byte *)(param_1[1] + 5) * (int)sVar6 + 0x32) / 100);
*(char *)(*param_1 + 0x13) = (char)((((uint)*(byte *)(*param_1 + 0xe) * 10) / (uint)*(byte *)(*param_1 + 9) +
         ((uint)*(byte *)(*param_1 + 9) + (uint)*(byte *)(*param_1 + 10)) * 10) / 10);
```
i.e. Body/Reflex/Mind/Health = `(base·s + 50) / 100`, each floored at 1; Health max = Health;
alignment = byte 6; **Level = ((Health·10 / Body + (Body+Reflex)·10) / 10 · s + 50) / 100**. All
stores are `(char)` byte casts, so a scale ≥ 256 (difficulty 4) wraps in +0x1F, and any stat > 255
wraps too.
This settles CharEntry **+0x1F** (INDEX item 7) as the spawn scale. The data-section initial value
of `DAT_100d73f2` is **2** (unpacked data section, `toc.D[0xA170:0xA174]` = `00 37 00 02`). ⚑ corrected (wave 1 2026-10-03): the whole code section has exactly three
r2-relative references to it (`python3 docs/cythera/tools/ppcdis.py 10000000 100cd280 | grep
'r2,8562'` → `100130f4: 38e22172  addi r7,r2,8562` in `SaveToFile__10TDelverAppFR6FSSpecP8TSegFileUc`
(passes the value), `10014180` in `RestoreModel__10TDelverAppFv` (passes `&DAT_100d73f2` to the
`"hhhh"` stream read — the only writer), `10044ba8: 3aa22172  addi r21,r2,8562` in this ctor
(reads)); no script global maps to it [HIGH: writers = restore only]. Named characters (< 0x100)
keep their 0xF009 values.

---------------------------------------------------------------------------------------------
## 5. 0x3042 — choosing the attack (sel 66 default) [HIGH]
Args A30 attacker, A31 target; L00 = `as_cls48(A30)`.
1. **Special attack**: `jf (has(A30, sel68) || has(L00, sel68)) -> 0029`; `L01 = R0EA3(A30, A31)`;
   True → done. R0EA3 rolls `rnd(0,100)` against a weighted spell list (sel 68, e.g. 0x1802 dict
   `68: @0002`) up to 3 times, creates the spell prop (`create_prop(28, 0, A30, 0, L09, 0, 0)`) and
   sends it `use`/`use_on`; it prefers spells when the caster's activity is 7, 4 (3 in 4), or
   `health*3 < health_max` (2 in 3). Spell internals are not banked here. [HIGH bytes; MED roles]
2. `L02 = R0E8C(A30, A31) − 1` where R0E8C returns `dx*dx + dy*dy` (0E8C @0003–@0023).
3. **Melee**: first equipped item (`iterate_equipped(&L04,0,A30)`, kind 0x18) with sel 42 and
   `[1]*[1] >= L02`: `R0E88(A30, A31, item, [0] + rnd(0, R0E90(A30.f17:body) + 1))`. Reach 1 ⇒
   `dx²+dy² ≤ 2` (adjacent incl. diagonal); reach 2 ⇒ `≤ 5`.
4. Else if `L02 > 1` (not adjacent) and `straight_line(…)` is True: equipped **throwable** (sel 43,
   `[1]² >= L02`): `missile_burst`, then `R0E89(A30, A31, item, [0] + rnd(0, R0E90(A30.f18:reflex)+1))`;
   hit → the item becomes kind 9 inside the target (`setfield L03.f00:kind = 9; L03.f0B:loc16 =
   as_prop(A31)`), miss → kind 1 on the target's cell. Else an equipped **launcher** (sel 46) and
   a carried ammo stack whose `45[0] == 46[0]`: one round fired (`R0E89(…, ammo, 46[2] + rnd(0,
   R0E90(reflex)+1))`), the stack loses one **hit or miss** (`delete_prop` at count 1 else
   `count − 1`).
5. Else if adjacent (`L02 ≤ 1`): **natural/unarmed**: `R0E88(A30, A31, Nil, L00.f31 + rnd(0,
   R0E90(A30.f17:body) + 1))`.
6. If anything was attempted: `send A31.sel67(A30)`; return L01 (True/False). Not adjacent with
   no usable ranged option → False → 0x301C returns Nil → "too far away".
`R0E90(x) = (x − 12) / 4` (0E90 @0003 `return ((A30 - 12) / 4)`), truncating toward zero, so the
strength/agility bonus roll is `rnd(0, (stat−12)/4 + 1)` = 0 … (stat−12)/4 (0 for stat ≤ 15).
[HIGH]

---------------------------------------------------------------------------------------------
## 6. To-hit margin

### 6.1 Melee / natural — R0E88 (A30 att, A31 tgt, A32 weapon or Nil, A33 damage max) [HIGH]
```
002A: set L01 = A30.f18:reflex
0036: jf  (L00.f33 & 1) -> 0046        ; creature record flag 1 → Body instead of Reflex
0040: set L01 = A30.f17:body
0046: jf  (A32 == Nil) -> 006B
0051: set L01 = (L01 + R0EAC(A30, 199)) ; Barehand skill: +to-hit …
005E: set A33 = (A33 + R0EAC(A30, 199)) ; … and +damage max
006B: set L01 = ((((L01 + random(0, 30)) - (A31.f18:reflex + random(0, 30))) + R0E84(A30, False)) - R0E84(A31, True))
```
Non-character targets skip all this: `R0E8F` sends `A31.sel65(rnd(0, A33) + 1, flags)` (flags =
weapon 42[2] or 45[2], else 0) — doors/chests apply their own sel-65 method. [HIGH]

### 6.2 Ranged — R0E89 [HIGH]
`L01 = A30.f18:reflex + R0EAC(A30, 200)` (Missile skill), same `±rnd(0,30)` / R0E84 expression, and
damage max `A33 + R0EAC(A30, 200)` (0E89 @002A, @0039, @0065). No Body option.

### 6.3 Offence / defence bonus — R0E84(char, defending) and R0E95 [HIGH]
⚑ corrected (wave 1 2026-10-03): **R0E84 is the to-hit attack/defence bonus** (this section is the source of truth for it);
it is not a health or magic maximum — those are R0E82/R0E83 (§13.2).
`defending` False → skill 192 Attack, True → skill 193 Defense (`R0EAC(A30, 192/193)`); if that
skill is **0**, fall back to `R0E95`: `switch (A30.f20:ce1D & 3)` → 0, `level / 2`, `level`,
`level * 2`. Non-characters → 0. `f20:ce1D` is CharEntry **+0x1D** (GetField case 0x20) — bits 0–1
are a combat-growth class (closes part of INDEX item 7) [HIGH for the read, MED for the name].
Evaluation order of the RPN expression = attacker roll, defender roll, R0E84(att), R0E84(tgt) — the
order `Random()` is consumed.

Margin = `(base_att + rnd(0,30)) − (Reflex_tgt + rnd(0,30)) + off_att − def_tgt`.

---------------------------------------------------------------------------------------------
## 7. R0E87 — parry, hit or miss (A30 att, A31 tgt, A32 weapon/ammo/Nil, A33 margin, A34 damage max)

### 7.1 Parry pool [HIGH]
```
0010: set L02 = iterate_equipped(&L03, 0, A31)
002A: jf  has(L02, sel47) -> 0051
0031: set L01 = L02.f0A:tile
0037: set L00 = (L00 + random(0, ((prop(L02, sel47, 0) + 1) + R0EAC(A31, prop(L02, sel47, 1)))))
```
Each equipped parry item of the **target** adds `rnd(0, parry + 1 + skill)` = 0 … parry+skill
(shields use skill 201 Shield, gauntlets 199 Barehand).

### 7.2 Outcome [HIGH]
`jf (A33 > 0) -> 03A2` → margin ≤ 0: **miss** ("… missed …", miss sound 42[4] or creature p3B[1],
return False). Margin > 0 and `A33 < L00` (`011B: jf (A33 < L00) -> 0148`): **parried** ("… parries
…", `show_hit` with the parrying item's tile, return True — no damage, no XP). Otherwise damage
(§8). Natural `rnd(0,30)` spread means no automatic hit or miss and **no critical-hit rule** exists
in any combat routine (the only "critical" is the wound message, §10). [HIGH]

### 7.3 Weapon quality and the dead skill bonus [HIGH]
```
006A: jf  (has(A32, sel42) && has(A32, sel38/p26)) -> 009D
0075: set L05 = A32.f06:quality
007B: set A33 = (A33 + L05)
0081: set A33 = (A33 + R0EAC(A30, prop(L02, sel42, 3)))     ; bytes 82 33 33 9f 0e ac 30 02 61 2a 03 40
008F: set A34 = (A34 + R0EAC(A30, prop(L02, sel42, 3)))
```
The weapon-skill bonus reads **L02** (slot byte `02`), the armour iterator, not A32. After the loop
L02 is Nil (iterators return Nil at the end — script-builtins.md §1), `prop(Nil,…)` is Nil, and
`find_skill(A30, Nil)` passes `(short)int(Nil)` = −1 to `FindSkill__Fss`, which compares
`(*(ushort *)(puVar2 + 1) & 0x3ff) == (int)param_2` — never true → 0. **Sword/Axe/Mace skills
never add to melee to-hit or damage in 1.0.4**; only Attack/Defense (§6.3), Barehand, Missile and
parry skills do. [HIGH] (⚑ corrected (wave 1 2026-10-03): replication advice removed — code fact only.)
**No durability**: no combat routine writes item byte 6. `grep -n 'f06' ghidra/cythera-scripts/0e*.txt
ghidra/cythera-scripts/30*.txt` finds `0E87 @0075: set L05 = A32.f06:quality` as the only `.f06`
access in the combat routines (§1 call graph, 0x0E81–0x0E96, 0x0EAC, 0x0EB8, 0x301C–0x3043) — a
read; the only `setfield … .f06` on those pages are 0E0A @0113, 0E0B @00AD, 0E0C @0048/@0055,
none of them in the combat call graph. ⚑ corrected (wave 1 2026-10-03) [HIGH]

---------------------------------------------------------------------------------------------
## 8. Damage roll, type flags, message [HIGH]
```
0148: set L09 = ((random(0, A34) + 1) + L05)     ; 1 … A34 (+ quality)
015A: jf  (L09 < 3) -> 0170                       ; "grazed"
```
Raw damage = `rnd(0, A34) + 1 + quality`, where A34 = the base from §5 (weapon [0] or creature f31,
plus `rnd(0,(stat−12)/4+1)`, plus Barehand/Missile skill). Verb ladder on raw damage: < 3 grazed;
< 6 hit; < 9 hit hard; < 12 hit very hard; < 16 hit extremely hard; < 20 crushed very hard; < 25
smashed (with a bone-crunching sound); < 35 ground to dust; else shredded to pieces. Flags L0C:
weapon 42[2] or ammo 45[2], `| 128` if quality ≠ 0; with no weapon: creature-class sel 42[2] /
45[2], else 4, and `| 256` if record `f33 & 8` (@02D1–@0302). Then `L09 = A31.sel64(L09, L0C)`
(§9). L09 ≤ 0 → ", but to no effect" (`show_hit` 439), no XP. Else `send A31.sel65(L09, L0C)` (§10)
and XP (§11).

---------------------------------------------------------------------------------------------
## 9. 0x3040 — absorption (receiver = target, A31 damage, A32 flags) [HIGH]
L00 = target's creature record. In order (each `return 0` = fully absorbed):
```
0009: jf (L00.f33 & 2) -> 0017                         ; immune → 0
0017: jf ((L00.f32 & 128) && (A32 & 8)) -> 002D        ; → 0
002D: jf ((L00.f32 & 32768) && (A32 & 32)) -> 0043     ; → 0
0043: jf ((L00.f32 & 2048) && (A32 & 64)) -> 005C      ; A31 = A31 / 2
005C: jf ((L00.f32 & 512) && (A32 & 8)) -> 0075        ; A31 = A31 * 2
```
then `has_ability(A30, 23) && (A32 & 8)` → 0 (ability 23 = status bit 15 IsLavaProof, §10);
`(f32 & 1024) && !(A32 & 4) && (A32 & 3)` → halve; `(f32 & 256) && !(A32 & 192)` → 0;
`(f33 & 4) && (A32 & 1)` → 0. Finally
```
00D3: set L01 = (L00.f30 + R0E81(A30, A32))
00E0: set A31 = ((A31 - random(0, (L01 + 1))) - random(0, (R0EAC(A30, 193) + 1)))
00FD: jf  (A31 < 0) -> 010C                            ; negative → 0, else A31
```
i.e. damage − `rnd(0, armour+1)` − `rnd(0, Defense+1)`, floored at 0. Armour = record natural
armour + **R0E81**: Σ sel-44[0] over equipped items, except flag 0x1000 counts only items whose
`p26 & 8` (cloaks, p26 = 9) and flag 0x800 counts **none** (`prop(L01, sel38/p26, 0) & 0` —
always false); `has_ability(A30, 20)` (IsBlessed) adds `1 + rnd(0,4)`. A target without a record
(as_cls48 = Nil) fails every flag test (`Nil & n` keeps Nil → false) and its armour sum is Nil, so
`rnd(0, Nil)` returns 0. [HIGH]

---------------------------------------------------------------------------------------------
## 10. 0x3041 — applying damage and status effects (receiver = victim, A31 damage, A32 flags) [HIGH]
```
000E: builtin show_hit(A30.f01:x, A30.f02:y, 434)
001B: builtin remove_ability(L00, 22)                       ; any hit wakes (IsSleep)
0020: jf has_ability(L00, 14) -> 003A
0029: jf (random((A31 + 20)) < A31) -> 003A                 ; one-arg call: hi = stale slot
0035: builtin remove_ability(L00, 14)                       ; breaks IsParalyse
008E: jf (A31 >= L00.f1C:health) -> 00C9                    ; → "killed!", health = 0
```
Ability n maps to status bits (`AddAbility__8TSpellFX @ 10056448`: n < 8 → CharEntry +8 bit n;
n < 0x18 → `+6` bit n−8; n < 0x20 → +0x1A bit n−24), so 9 = Poisoned (0x2), 14 = Paralyzed (0x40),
20 = IsBlessed, 22 = IsSleep (0x4000), 23 = IsLavaProof. The paralysis-break test is the banked
stale-slot call (script-vm.md §8): `random` reads its `hi` from whatever sits above the stack top.
Not killed: `health -= A31`; "Critically wounded" if `health ≤ health_max / 4`, "Wounded" if `≤
health_max / 2`; hurt sounds come from sel 59 of the victim or its class (default list
`[0,16,17,19,20,21,22]`, [6] = death). **Poison**: `jf (A32 & 256)`, then unless the victim's record
has `f32 & 64`, `add_ability(A30, 9)` — only on non-lethal hits (the killed branch jumps past it).
Poison then ticks natively (rules.md §4: −1 HP per 1/10 h, `DeathRites` at HP < 2). Writing
`health` goes through `SetField` case 0x1C, which clamps to max and calls `DeathRites` when the
value is < 1 (§12.1). [HIGH]

---------------------------------------------------------------------------------------------
## 11. 0x3043 — provocation (sel 67; receiver = victim, A31 = attacker) [HIGH bytes, MED meaning]
`A30.f2A = A31` (SetField 0x2A stores the attacker's monster at monster +0x20) and
`A30.f15:activity = A30.f16:behaviour`; if the victim is the Hero or `inparty`, every party member
not already in its behaviour gets the same two stores. If the victim is **not** in the party, the
attacker **is**, and the victim's record alignment `f35` is 0 or 2 (neutral/good), `send_signal(321)`
— the scripts' alarm signal. ⚑ corrected (wave 1 2026-10-03): 321 is answered by `3015` (default sel 21 for characters
without their own signal method): record byte 6 = 0 → `R0D06` (`0D06 @0081: jf (A31 == 321)`,
then `leader_can_see(A30)` → `target := leader`, `activity := 6`), = 2 → `R0D07` (`0D07 @0014: jf
((A31 == 320) || (A31 == 321)) -> 003B`, same two stores, no sight test); the guard type 0x102E
and chars 0x1846–0x1849, 0x1864, 0x1865 use `0D07` itself as their selector-21 method (dictionary
`21/signal: @0D07:0000`; schedules-npcs.md §6.3). Other damage sources: 0x0EB8 (spells,
traps: sel 64 then 65 then the same XP rule) with flags 4, 8, 32, 64, 66, 68, 1026, 2052, 4098 at
its 16 call sites; 0x301F (sel 31, stepping on terrain): codes −5…−2 → 1 in 9 `rnd(1,10)==3` "something
bit me" poison + 1 damage (flags 2) unless ability 31 or record `f32 & 64`, code −221 → `rnd(0,4)+1` fire damage (flags 8) unless
IsLavaProof or `f32 & 128`. [HIGH]

---------------------------------------------------------------------------------------------
## 12. Death

### 12.1 Native entry [HIGH]
`SetField__Fsss5VAddr` case 0x1C: `if ((int)(param_4 << 4 | param_4 >> 0x1c) >> 4 < 1) {
_DeathRites__9CharEntryFv(puVar12); }`. `DeathRites @ 1004fc50` writes health 0, then
- **no active monster**: `DoInterp(0x1d, char)` (one value pushed — `DoInterp__7TInterpFs5VAddr`
  pushes only the receiver); health still 0 → clear alive bit, leave party (`RebuildParty`); revived
  → `RemoveStackedAbility` 0xD, 0xE, 0x16, 0x15 and set alive (rules.md §1);
- **active monster**: a virtual call (⚑ corrected (wave 1 2026-10-03); `python3 docs/cythera/tools/ppcdis.py 1004fc78 +8`):
  `1004fc84: 819c0048  lwz r12,72(r28)` · `1004fc88: 818c0018  lwz r12,24(r12)` · `1004fc8c:
  4807545d  bl 0x100c50e8` — monster +0x48 holds `&PTR_PTR_100d5bac` (ctor: `param_1[0x12] =
  (int)&PTR_PTR_100d5bac;`). The vtable words (`python3 -c "import sys;
  sys.path.insert(0,'docs/cythera/tools'); import toc; print([hex(w) for w in
  toc.data_u32(0x100d5bac,8)])"`) are data-section offsets of TVectors; base 0x100CD280 + word →
  TVector, TVector word 0 + 0x10000000 → code, named by `python3 docs/cythera/tools/tb.py --at
  <code>`:

| slot | word | TVector | code | `tb.py --at` |
|---|---|---|---|---|
| +8 | 0x2fb0 | 0x100D0230 | 0x100463D0 | `__dt__14TActiveMonsterFv` |
| +12 | 0x2fa8 | 0x100D0228 | 0x100459A8 | `Save__14TActiveMonsterFP7TStream` |
| +16 | 0x2eb8 | 0x100D0138 | 0x1004B8E8 | `DoMove__14TActiveMonsterFss` |
| +20 | 0x2f88 | 0x100D0208 | 0x100465A4 | `LeaveLevel__14TActiveMonsterFv` |
| +24 | 0x2f68 | 0x100D01E8 | **0x100469C0** | `Die__14TActiveMonsterFv` |
| +28 | 0x2eb0 | 0x100D0130 | 0x1004D7AC | `IsPartOfMonster__14TActiveMonsterFs` |

  [HIGH: every slot lands on a TActiveMonster traceback entry; the two base additions are the PEF
  section bases, applied by hand]

### 12.2 Monster death — `Die__14TActiveMonsterFv @ 100469c0` [HIGH] ⚑ corrected (wave 1 2026-10-03)
Read from the decompile (`python3 ghidra/find_func.py 'Die__14TActiveMonster' --file
ghidra/Cythera_extra.decompiled.c`; `Cythera_extra.decompiled.c` (CyDecompAt.java, extra-addrs.txt)),
replacing the earlier branch-level disassembly reading. `param_1[0]` = CharEntry, `param_1[1]` =
creature record (`ObjToMonst`), `param_1[4]` = the body prop's 16-byte entry, `param_1[5]` = the
egg-contents prop (`HatchEgg`: `piVar3[5] = (int)puVar11;`), short at `param_1 + 2` = the index.
- First `_DoInterp__7TInterpFs5VAddr(auStack_54,0x1d,uStack_58);` (sel 29, one value pushed), then
  `if (*(char *)(*param_1 + 0xe) == '\0')` — health still 0 → dead. Else revived:
  `RemoveStackedAbility` 0xd, 0xe, 0x16, 0x15 (13, 14, 22, 21) and `*(ushort *)(*param_1 + 6) |
  1` (alive bit).
- Dead, all cases: if `FindInventory__16TInventoryWindowFs(index)` finds a window, an indirect call
  through `FUN_100c50e8` (the glue; its target — closing the window — is MED); then alive bit cleared
  (`& 0xfffe`).
- **Named** (index < 0x100): party bit `+8 & 0x40` cleared → `RebuildParty`. Corpse word
  `uStack_4e = *(ushort *)(param_1[1] + 0xe);` (record bytes 14–15):
  - **0**: every prop from 0x100 up with kind 0x10, 0x18 or 0x09 (`'\x10'`, `'\x18'`, `'\t'`) whose
    low 16 bits are this index becomes kind 1 at the body prop's x/y; kind-0x1C props of the index
    (skills) → `DeleteProp`. Body prop kind := 0xFF; `ForceReset__5THoodFv`.
  - **≠ 0**: `NewProp`, kind 1, type `& 0x3ff`, frame `>> 10`, byte 6 = the index
    (`*(char *)((int)puVar6 + 6) = (char)*(undefined2 *)(param_1 + 2);` — what Resurrection's
    `as_char(quality)` reads, magic.md §3 row 2F), byte 7 = 0, at the body's cell; carried kind
    0x10/0x18/0x09 props → kind 9 inside the new prop; skill props are **not** deleted on this
    path. Body prop kind := 0xFF; `AddToHood(new prop)`.
  - Then `if (*(short *)(param_1 + 2) == *(short *)PTR_DAT_100cdbec) { *(undefined2 *)(param_1 + 2)
    = 1; }`, `RebuildParty` if entry [index] has `+8 & 0x40`, and `if (*(short *)(param_1 + 2) == 1)
    { *(undefined1 *)(*(int *)PTR_DAT_100cdb84 + 0x1c) = 1; }` — the byte is set when the Hero dies
    **or** when the dying named character is the index held in `PTR_DAT_100cdbec` (the word the
    spawn ctor copies the current level byte from — the leader, MED). Its reader is not traced.
- **Spawned** (index ≥ 0x100): `if (((*(ushort *)(param_1[5] + 4) & 0x3ff) == (*(ushort
  *)(param_1[4] + 4) & 0x3ff)) && ((*(byte *)(*(int *)PTR_DAT_100cdc44 + (*(uint *)param_1[5] &
  0xffff) * 0x10 + 6) & 4) == 4)) { *(char *)(param_1[5] + 7) = *(char *)(param_1[5] + 7) + '\x01'; }`
  (the middle term reads byte 6 of the prop whose index is the contents' parent field, i.e. the egg) — the egg-**contents** prop's byte 7 (the count
  `HatchEgg` decrements per hatch) goes back up by one when it has the dead monster's type and its
  egg has byte 6 bit 4. There is no test that `param_1[5]` is non-zero (`__ct__14TActiveMonsterFs`
  sets `param_1[5] = 0`; `HatchEgg` and the stream ctor set it) [HIGH for the missing test; the
  effect for a non-egg monster is not traced].
  - corpse **0**: as for named (carried → kind 1 on the cell, skill props deleted, body kind 0xFF,
    `ForceReset`).
  - corpse **≠ 0**: the body prop itself becomes the corpse — kind 0x21, type/frame from the corpse
    word, bytes 6 and 7 = 0; carried kind 0x10/0x18/0x09 props → kind 9 (parent unchanged = the body
    prop); index := 0.
- `LeaveLevel__14TActiveMonsterFv @ 100465a4` (vtable +20, same extra dump): spawned monsters do the
  contents increment **without** the type/egg-bit test (`*(char *)(param_1[5] + 7) = *(char
  *)(param_1[5] + 7) + '\x01';`); a named character's body prop becomes kind 0xFF (alive bit
  clear) or 0x42 (alive). [HIGH]

### 12.3 Script side — sel 29 [HIGH]
0x301D (default): `jf is_char(A30)`; `L00 = as_cls48(A30)`; `send L00.sel29(A30)`; else
`R0E8D(A31)`. A class-0x48 receiver without its own death method falls back into 0x301D again with
A30 = record object, A31 = the character → **R0E8D(character)**. Creature classes with death
methods (`1914`, `191A` "something smells bad" → R0E8D; `1916`, `191D`, `1923`, `1924` →
`create_prop(9, 0, as_prop(A31), frame, 69, 0, 0)` ×1–6 = carried loot of type 69, frames 7/8/10/12,
which §12.2 then moves into the corpse). R0E8D: record `f32 & 0x4000` → `create_prop(33, x, y,
rnd(0,4), 77, 0, 0)` (type 77 "blood"); `f32 & 0x2000` → every same-group prop gets `tblC40 = 31`,
kind `| 2`, `show_tile_animate(16)`; if `G09 == Hero`, karma `G0C += [1, 4, -10, 0][f35]`
(alignment 0 neutral +1, 1 evil +4, 2 good −10, 3 feral 0; SetGlobal clamps 0..100). `G09` is the
monster `MoveAll` is ticking (`*(int *)PTR_DAT_100cdd98 = iVar14;`); with none, `GetGlobal` case 9
falls through into case 0x13 and yields True/False, never the Hero — so karma moves only on kills
made during the Hero's own monster tick [MED: inferred from the fall-through]. A dying character
**without** a creature record reaches `R0E8D(A31)` with A31 never pushed (one-value `DoInterp`) —
it aliases the frame's first local (script-vm.md §3 layout) [MED].
Hero (0x1801 @0133): screen fade; if CharEntry +8 bit 0 → `R301D(A30)`; else an equipped type-244
amulet with quality > 0 loses one charge (deleted at 0); with karma `G0C > 45` the Hero is revived
at `health_max / 3 + 1`, teleported (`teleport(1,1,0)`) and the script raises out; otherwise the
death pictures and `end_game(...)`. The charge is spent even when karma ≤ 45. [HIGH]

---------------------------------------------------------------------------------------------
## 13. Experience and levels (extends rules.md §2)

### 13.1 Award per hit — R0E87 @0347–@0391 (also 0x0EB8) [HIGH]
```
0353: set L0F = ((L0E.f1B:level - L0D.f1B:level) + 1)   ; L0E = target, L0D = attacker
0366: jf  (L0F > 0) -> 0387
036E: jf  (L09 <= L0F) -> 037E                           ; XP = min(damage, L0F)
0387: jf  (L09 > (0 - L0F)) -> 0398                       ; else 1 XP if damage > −L0F
```
XP goes to the attacker after the damage is applied (also to monsters). Damage here is the
**post-absorption** amount. Spawned monsters' level ≈ Body + Reflex (§4.1), so against them XP ≈
damage dealt. Fixed quest awards: 38 of the 48 `R0E8B` call sites pass a constant 5…200 to the leader or the
Hero (`grep -h 'R0E8B(' ghidra/cythera-scripts/*.txt`).

### 13.2 R0E8B (char, n) and level-up [HIGH]
`exp = min(exp + n, 65535)` (`jf ((L00 + A31) < 65535)`), then `jf (A30.f1A:exp > ((1 << (A30.f1B:level
- 1)) * 100)) -> 0048` → `R0E86(A30, 1)`: **at most one level per award**; level L → L+1 when exp >
100·2^(L−1) (101, 201, 401, 801, …; character 2's data, level 8 with exp 9600, sits between 6400 and
12800). R0E86(char, n):
```
0003: setfield A30.f1B:level = (A30.f1B:level + A31)
0013: setfield A30.f1D:health_max = R0E82(A30)
001D: setfield A30.f1C:health = ((A30.f1C:health * A30.f1D:health_max) / L00)   ; L00 = old max
0036: setfield A30.f1F:magic_max = R0E83(A30)            ; only if old magic_max ≠ 0, same rescale
004E: setfield A30.f21:training = (A30.f21:training + ((6 - G11:g11_unhandled) * A31))
```
`G11` is Nil — `GetGlobal__Fs @ 1009376c` has no case 0x11 and its `default: *param_1 = *(uint
*)PTR_DAT_100cdbb0;` pushes Nil — and `6 − Nil` = 6: `DoExpr__7TInterpFRPUc @ 1007ddfc` case 0x4b
subtracts only when both operands are integers, else `*(uint *)(iVar8 + sVar18 * 4) = uVar17;`
pushes the left operand. So **+6 training points per level** [HIGH; one label for this rule across
the banks, ⚑ corrected (wave 1 2026-10-03)]. Max health **R0E82** = `Body + Reflex/2 + level
+ ((D·5)·Reflex)/15` with D = Defense skill, or R0E95 if 0; max magic **R0E83** = `Mind + M`
with M = Mana skill (194), or `R0E96` (`(ce1D >> 2) & 3` → 0, level/2, level, level·2) if 0, and 0
when M = 0. Check on data: character 2 (Body 20, Reflex 20, Mind 20, level 8, +0x1D = 15) →
`20 + 10 + 8 + (16·5·20)/15 = 144` and `20 + 16 = 36`, exactly its stored 144/144 and 36/36
(0xF009 entry 2 bytes `… 90 90 24 24 00 08 …`) [HIGH, assuming no Defense/Mana skill props].
All these fields are bytes on write (SetField `(char)` stores) except exp (u16).

---------------------------------------------------------------------------------------------
## 14. Encumbrance and regeneration [HIGH]
No combat routine reads weight (§3). Over-encumbrance cannot arise from the player's own actions:
`TakeCommand` refuses with "There isn't room" when `max < weight + cur + …` and `WieldCommand` with
"It's too much to equip" (`if ((int)local_5a < (int)sVar6 + (int)sVar5 + (int)local_5c)`); script
`give_item` (0xA8) does not check. Effect of an over-limit state: none found [MED: absence].
Regeneration is native and not combat-specific (rules.md §4); combat adds only poison (§10) and the
level-up rescale (§13.2).

---------------------------------------------------------------------------------------------
## 15. Worked example — one sword blow
Attacker: character 2 (0xF009: Body 20, Reflex 20, level 8, +0x1D = 15, exp 9600) [HIGH inputs],
assumed to carry no skill props and no sel-68 spell pick (R0EA3 returns 0) [LOW assumption],
wielding the type-98 sword (42 = [20, 1, 1, 196, …], quality 0) [HIGH]. Target: a spawned ruffian
(record 1: base 15/12/8, armour 2, health 20, f33 = 1, f32 = 0x4004) at scale s = 100 → Body 15,
Reflex 12, Health 20, Level `((200/15 + 270)/10·100 + 50)/100 = 28`, +0x1D = 0, nothing equipped
[HIGH formula, LOW chosen s]. Rolls are assumed values within each range [LOW].
1. 0x3042: d² = 1 → L02 = 0; `1·1 ≥ 0` → melee. Damage max A33 = `20 + rnd(0, (20−12)/4 + 1)` =
   20 + rnd(0,3) → roll 2 → **22**.
2. R0E88: base = Reflex 20 (attacker record "king" f33 = 0x8002, bit 1 clear). off = R0E95 with
   `15 & 3 = 3` → level·2 = **16**; def(ruffian) = `0 & 3` → 0. Rolls 15 and 10:
   margin = `(20+15) − (12+10) + 16 − 0` = **29**.
3. R0E87: no parry items → L00 = 0. Quality 0 → L05 = 0; skill bonus 0 (§7.3). 29 > 0, not < 0 →
   damage: `rnd(0,22)` → 13, raw = 13 + 1 + 0 = **14** → "hit … extremely hard". Flags = 1.
4. 0x3040 (ruffian): no immunity bits apply; armour = 2 + 0 → `14 − rnd(0,3)` (roll 1) `− rnd(0,1)`
   (always 0) = **13**.
5. 0x3041: 13 < 20 → health **7**; 7 > 20/4 = 5 and 7 ≤ 10 → "Wounded". Flag 256 absent → no poison.
6. XP: L0F = 28 − 8 + 1 = 21 > 0; 13 ≤ 21 → **+13** → exp 9613 < 12800, no level-up.
7. 0x3043: ruffian enters its combat behaviour; attacker → busy += 192/20 = **9**, returned as the
   time cost (HeartBeat(9) if the leader attacked; `DoAttack` stores 9 otherwise).
(Note the "king" record has f33 & 2: character 2 itself can never be damaged through 0x3040.)

---------------------------------------------------------------------------------------------
## 16. Open items
1. ~~DoMove/Die/LeaveLevel absent from the dump~~ — resolved ⚑ corrected (wave 1 2026-10-03): `DoMove` 0x1004B8E8, `Die`
   0x100469C0, `LeaveLevel` 0x100465A4 are in `Cythera_extra.decompiled.c` (CyDecompAt.java,
   extra-addrs.txt); §12.2 is read from it. Still open: the reader of `*PTR_DAT_100cdb84 + 0x1C`,
   the identity of `PTR_DAT_100cdbec`, the glue call on an open inventory window, and `Die` on a
   spawned monster whose `param_1[5]` is 0.
2. ~~Who answers signal 321~~ — resolved ⚑ corrected (wave 1 2026-10-03): `3015` → `R0D06`/`R0D07` by record byte 6, and the
   guards' shared `0D07` method (§11). Still open: what `f2A` (monster +0x20) drives in `DoTick`.
3. ~~`DAT_100d73f2` writers~~ — resolved ⚑ corrected (wave 1 2026-10-03): three r2-relative references in the code section,
   the only writer is the `RestoreModel` stream read (§4.1, HIGH); no UI writer. The name
   "difficulty" stays MED.
4. ⚑ corrected (wave 1 2026-10-03): creature-record **byte 7** has no reader (§4) — open; bytes 14–15 are the corpse word
   (§12.2). f32 bits 1, 2, 4, 16, 32 and f33 bits 0x1000–0x8000 have no reader in the combat
   routines read here.
5. R0EA3 spell selection (weights, sel 54 target classes) — belongs with the spells bank.
6. The A31-aliasing reading of 0x301D for record-less characters (§12.3) — trace the stack layout
   of `DoInterp0` → `DoInterpAt` for a 1-value send with a 2-arg frame.
7. Behaviour-verify the to-hit/damage numbers against play (Ben) — every number above is a code
   reading.
