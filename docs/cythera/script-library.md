# Cythera 1.0.4 — the shared script routine library (pages 0x08, 0x0A–0x0F, 0x30)

Register: **code reading**. Every row/claim carries HIGH (quoted bytecode proves it), MED (inferred
from structure, names or callers) or LOW (conjecture), and cites `segid @ offset` from the listings
`ghidra/cythera-scripts/<segid>.txt` (produced by `docs/cythera/tools/scriptdis.py`). Readers of
combat, magic, dialogue, trade, schedules and quests cite this file for helper semantics.

## 0. Scope, method, what was not read

- **Scope**: all 199 routine segments on pages 0x08 (22), 0x0A (8), 0x0B (1), 0x0C (30), 0x0D (10),
  0x0E (66), 0x0F (22), 0x30 (40). Page 0x09 (combat-AI tests/actions) belongs to `ai-scripts.md`.
- **Method**: every listing above was read this session (statement lines; inline-block contents only
  where cited). Calls-in over **all 958 listings** ⚑ corrected (wave 1 2026-10-03): static `R<seg>(`
  calls (0x9F, 0x9C with a constant) on live lines, plus dictionary code pointers `@seg:off` —
  `grep -h '^[0-9A-F]\{4\}:[ >]' ghidra/cythera-scripts/*.txt | grep -o 'R\(08\|0A\|0B\|0C\|0D\|0E\|0F\|30\)[0-9A-F][0-9A-F](' | sort | uniq -c`
  (per routine) and `grep -h '^; dictionary' ghidra/cythera-scripts/*.txt | grep -o '@0D07:'` (7);
  per-routine segments: `grep -l '^[0-9A-F]\{4\}:[ >].*R0F15(' ghidra/cythera-scripts/*.txt | wc -l`.
  Page totals reproduce census §7 exactly (08: 269, 0C: 15, 0D: 90 + 7 = 97, 0E: 367, 0F: 636,
  30: 20). "calls (segs)" = call sites (distinct calling segments). Liveness was closed transitively
  (§11). Native reach was measured with a raw-PEF scan (code section at file offset 0x3470, base
  0x10000000) for `bl` to the four `DoInterp` wrappers, taking the nearest preceding `li r4,imm` as
  the selector (§9) — a heuristic, so native-only claims built on it are MED.
- Arg slots: **A30 = first argument (receiver for methods)**, A31.. next; L00.. locals (script-vm §3).
  `jf c -> X` jumps when `c` is **false**. `random(lo,hi)` returns lo..hi−1 (script-builtins AC).
- **Not read**: the bodies of the ~600 class segments that call into the library (only their call
  lines and a few inline tables); page 0x09. (The native sender at 0x1004d554 is `DoMove`, now in
  `Cythera_extra.decompiled.c` — §5. ⚑ corrected (wave 1 2026-10-03))
  Activity codes ≥ 0x80 (160, 162 …) used in `queue_activity` are native and not interpreted here.

## 1. How each page is entered

| page | entry | evidence | conf |
|---|---|---|---|
| 0x08 | static 0x9F calls from character talk methods (page 0x18) and from 0x08 itself; 0x0816 only from page 0x08; 0x0814 unreached | `0801 @0AE7 9f 08 16 30 45 01 4a … call R0816(A30, blk@0AEE, 10)` | HIGH |
| 0x0A | only the computed call in potion class 0x101F: frame 0–7 → 0x0A00–0x0A07 | `101F @00FE 9c 0a 00 30 62 03 40 31 63 40 40  callx R[0A00+A30.f03:frame](as_char(A31))` | HIGH |
| 0x0B | nothing (no call, pointer, computed base or native formula reaches 0x0B00) | §11 | HIGH |
| 0x0C | 0x0C00: static calls from three `spawned` methods; 0x0C40–0x0C55: **only** `R[0C00+A31]` in 0x3021, the selector-33 default; 0x0C80–0x0C86: static calls from 18xx | `3021 @0003 8b 9c 0c 00 31 40 30 32 33 34 40 40  return R[0C00+A31](A30, A32, A33, A34)` | HIGH |
| 0x0D | static calls (money helpers); 0x0D07 also as the **shared `signal` method** of 7 classes (dictionary value `0x8D070000`) and from 0x3015 | `102E @00F7 … dict[7] {12/talk: @000C, 21/signal: @0D07:0000 …}` | HIGH |
| 0x0E | static calls only; no computed base on 0x0E | census §7 | HIGH |
| 0x0F | static calls only (636); 15 helpers never called | census §7, §11 | HIGH |
| 0x30 | `DoInterp0` falls back to `0x3000+selector` when `Dispatch` finds no value; plus 20 static calls (0x301D, 0x3020, 0x3041) | script-vm §2.1; selector senders §9 | HIGH |

## 2. Page 0x08 — conversation topic library (22 routines, 34,380 B)

Shape (HIGH, e.g. `0801 @0003 match atti else -> 0046` … `@003F return True`): `frame 1 0`, a chain
of `match kw[,kw] else -> next` blocks each printing a quoted answer and `return True`; falls off with
`return False` (`0801 @0C42`). Talk methods call them as "did a shared topic answer the keyword?".
Zone gates read `G10:zone` (1 Cythera overland, 2 Odemia, 6 Catamarca, 8 Cademia, 12/14 Pnyx, 13 Kosha,
24 Mining Camp — names from `set_map_title` in 0x14xx) [HIGH].

| id | name | sig (args; returns) | behaviour | calls (segs) | conf |
|---|---|---|---|---|---|
| 0801 | CommonTopics [named here] | A30 speaker; Bool | Common-knowledge answers (Houses, towns, Alaric, Metics, profanity "Rudeness is not rewarded."); on overland (`@0AD6 jf (G10:zone == 1)`) `wher` → `R0816(A30, blk@0AEE, 10)` | 95 (91) | HIGH |
| 0802 | AttisTopics [named here] | A30; Bool | House Attis household answers ("The iron mine has proved to be quite useful for House Attis.") | 5 (5) | HIGH |
| 0803 | NoTopics [named here] | A30; False | Stub: `@0003 return False` | 3 (3) | HIGH |
| 0804 | ComanaTopics [named here] | A30; Bool | Kosha / House Comana household answers (`match kosh`, `myus`, `dari`) | 5 (5) | HIGH |
| 0805 | InnkeeperKinTopics [named here] | A30; Bool | Innkeeper family answers ("My cousin Parium runs the Green Goat…"); callers 1828 Parium, 1829, 182A, 182D, 182E, 1857, 1858 | 7 (7) | MED |
| 0806 | NicanderTopics [named here] | A30; Bool | House Nicander household answers ("Watch your words about our noble House.") | 3 (3) | HIGH |
| 0807 | StrymonTopics [named here] | A30; Bool | House Strymon household answers ("We are House Strymon.") | 4 (3) | HIGH |
| 0808 | ScholarTopics [named here] | A30; Bool | Judges' and Magisterium answers (judges by town, runes, training, golem, `y`/`n`); callers judges 1846–1853, students 186E–1876, and 0810 | 25 (25) | MED |
| 0809 | LandKingHallTopics [named here] | A30; Bool | LandKing Hall answers (dim light, tremors) + `wher` → `R0816(A30, blk@0138, 1)` (Kitchen, Dining Room, Library, Throne Room…) | 5 (5) | HIGH |
| 080A | OdemiaTopics [named here] | A30; Bool | Odemia answers; zone 2 `wher` → `R0816(A30, blk@00E6, 1)` | 12 (12) | HIGH |
| 080B | CatamarcaTopics [named here] | A30; Bool | Catamarca answers (plague, Andr/Hapm); zone 6 `wher` → R0816 | 9 (9) | HIGH |
| 080C | PnyxTopics [named here] | A30; Bool | Pnyx / Magisterium answers; two `wher` tables, zone 12 (`blk@0372`, 16 entries, 1555 B) and zone 14 (`blk@09AA`, 15 entries, 1539 B) | 18 (18) | HIGH |
| 080D | KoshaTopics [named here] | A30; Bool | Kosha answers; zone 13 `wher` → R0816 | 8 (8) | HIGH |
| 080E | CademiaTopics [named here] | A30; Bool | Cademia answers (judge Berossus, rats, murder); zone 8 `wher` → R0816; holds a nested condition routine @0006 (§10.1) | 30 (27) | HIGH |
| 080F | SabinateTopics [named here] | A30; Bool | Answers of Sabinate's group ("Sabinate is our leader.", sea/earth/air/fire, "We do not speak of that one."); callers 1878, 187A–187C | 5 (4) | MED |
| 0810 | StudentTopics [named here] | A30; Bool | Magisterium student roster answers ("Thrasymedes is another student.") and falls through to `R0808(A30)` | 9 (9) | HIGH |
| 0811 | MiningCampTopics [named here] | A30; Bool | Iron-mine answers; zone 24 `wher` → R0816 | 3 (3) | HIGH |
| 0812 | DiceGame [named here] | A30; 0 | Three-dice gambling for 1 obol a throw (R0D04 purse, R0D05 pay, R0D09 win; skill 207 rigs a match) | 3 (3) | HIGH |
| 0813 | TavernRumour [named here] | A30, A31 draws; 0 | Prints one rumour: fixed lines by zone/flags, else the max of A31 `random` picks from a zone table (§10.3) | 7 (7) | HIGH |
| 0814 | (none) [named here: Nop0814] | A30; 0 | `@0003 return 0`; never reached | 0 | HIGH |
| 0816 | WhereIs [named here] | A30 speaker, A31 table, A32 distance scale; 0 | "Directions to Where?" menu over a 6-field table, filtered by a per-entry condition, prints directions via R0EAA (§10.1) | 9 (8) | HIGH |
| 0817 | JudgeDutyTopics [named here] | A30; Bool | Judges' office answers (`duty,duti,serv`, `disp`, `coun`, `popu`); callers 1846–1849 | 4 (4) | HIGH |

## 3. Page 0x0A — potion effects (8 routines, 561 B)

Entered only by `101F @00FE` (above) after the potion's name list `101F @000B` (`[0] "Sustenance
Potion"`, `[1] "Healing Potion"`, `[2] "Mage's Friend Potion"`, `[3] "Free Motion Potion"`, `[4]
"Antidote Potion"`, `[5] "Clear Mind Potion"`, `[6] "Smith's Friend Potion"`, `[7] "Far Sight
Potion"`); 101F then `delete_prop(A30)` (`@0109`). Index = prop frame → mapping HIGH. All take A30 =
drinker, print only if `A30 == G05:leader`, return 0.

| id | name | behaviour | key line | calls | conf |
|---|---|---|---|---|---|
| 0A00 | SustenancePotion [named here] | food := 24, "You feel fully sated…" | `@0003 setfield A30.f28:food = 24` | computed only | HIGH |
| 0A01 | HealingPotion [named here] | health += 10 + random(1,10) (11–19; no cap) | `@0003 setfield A30.f1C:health = ((A30.f1C:health + 10) + random(1, 10))` | computed | HIGH |
| 0A02 | MagesFriendPotion [named here] | moves up to 10+random(1,10) from health to magic, capped by magic room and health−1; else "Nothing seems to happen." | `@00A0 setfield A30.f1E:magic = (A30.f1E:magic + L00)` / `@00AA … health - L00` | computed | HIGH |
| 0A03 | FreeMotionPotion [named here] | removes abilities 22 and 14 | `@0003 remove_ability(A30, 22)`, `@0008 remove_ability(A30, 14)` | computed | HIGH |
| 0A04 | AntidotePotion [named here] | removes ability 9 (poison; 3041/301F add 9) | `@0003 remove_ability(A30, 9)` | computed | HIGH |
| 0A05 | ClearMindPotion [named here] | removes ability 21 ("Your head starts to clear."); 0EA2 grants 21 | `@0003 remove_ability(A30, 21)` | computed | HIGH |
| 0A06 | SmithsFriendPotion [named here] | temp ability 23 (fire immunity: 301F, 3040) for 100+10·random(1,10) | `@0003 temp_ability(A30, 23, (100 + (10 * random(1, 10))))` | computed | HIGH |
| 0A07 | FarSightPotion [named here] | `screen_effect(2)` | `@0003 e7 41 02 40` | computed | HIGH |

## 4. Page 0x0B (1 routine, 7 B)

| id | name | sig | behaviour | calls | conf |
|---|---|---|---|---|---|
| 0B00 | Nop0B00 [named here] | A30; 0 | `@0003 8b 41 00 40 return 0`; nothing reaches it (no 0x0B base in any computed call; native formulas yield 0x09xx/0x30xx only) | 0 | HIGH |

## 5. Page 0x0C — activity dispatch and NPC chores (30 routines, 2,202 B)

**Selector 33 = activity step.** ⚑ corrected (wave 1 2026-10-03): the sender is
`DoMove__14TActiveMonsterFss` (`tb.py --at 1004d554` → 0x1004b8e8, extent 0x1dec; `ppcdis.py 1004d530
1004d558`: `1004d538: 38800021  li r4,33`, `1004d554: 48035371  bl 0x100828c4  ;
.DoInterp__7TInterpFs5VAddr5VAddr5VAddr5VAddr5VAddr`). Its decompile (`Cythera_extra.decompiled.c`
(CyDecompAt.java, extra-addrs.txt); schedules-npcs §0, §3.2) packs the queue head:
`_DoInterp…(&iStack_b4,0x21,uStack_b8,uVar1,(int)sVar9 & 0xfffffff,(int)sVar16 & 0xfffffff,iVar8)` with
`uStack_b8` = VAddr(4, 0x40, char), `uVar1` = node byte +8 (act), `sVar9` = +0xA (x), `sVar16` = +0xC
(y), `iVar8` = +0x10 (value). No class defines 33, so 0x3021 runs `return R[0C00+A31](A30, A32, A33,
A34)`: the handlers see **A30 = char, A31 = x, A32 = y, A33 = value**, act 64–85 selects. [HIGH] The
queue head is erased only when the result is True (`if (iStack_b4 == *(int *)PTR_DAT_100cddec)
{ cStack_7a = '\x01'; }` → `erase`). Every
`queue_activity` in the corpus has a literal act; codes used: 64×2 65×2 66×19 68×16 70 71×8 73 75 76×2
78 79 81×2 82×4 83 84×2 85; **never queued: 67, 69, 72, 74, 77, 80** (0C43, 0C45, 0C48, 0C4A, 0C4D,
0C50) [HIGH for literals]. All return True except 0C43 (the callee's value) and 0C55 (0).

| id | name | sig | behaviour | calls | conf |
|---|---|---|---|---|---|
| 0C00 | SpawnedByActivity [named here] | A30 char, A31 dict {activity: code}; value | `L00 = A31[A30.f15:activity]`; code → call it, else `R3020(A30)` (spawned default) (§10.4) | 3 (3: 184E 1852 1853) | HIGH |
| 0C40 | act40_PickUp [named here] | A33 prop | prop parent := char, kind := 16 (into inventory): `@0003 setfield A33.f0B:loc16 = A30` | 0 static | HIGH bytes / MED meaning |
| 0C41 | act41_PutDown [named here] | A31 x, A32 y, A33 prop | kind := 1, x/y := A31/A32 (on map): `@000A setfield A33.f01:x = A31` | 0 | HIGH / MED |
| 0C42 | act42_Wait [named here] | A31 ticks | busy += A31: `@0003 … A30.f23:busy = (A30.f23:busy + A31)` | 0 | HIGH |
| 0C43 | act43_Call [named here] | A33 routine/code | `return callx[A33](A30, A31, A32)`; act 67 never queued → unexercised | 0 | HIGH |
| 0C44 | act44_Say [named here] | A31 other char or 0, A33 text | sets speech bubble `f26` of A31 (if non-zero) else of A30 | 0 | HIGH bytes / MED "bubble" |
| 0C45 | act45_Print [named here] | A33 | `print A33`; unqueued | 0 | HIGH |
| 0C46 | act46_Delete [named here] | A33 prop | `delete_prop(A33)` | 0 | HIGH |
| 0C47 | act47_SetItem [named here] | A31 value, A33 prop | `A33.f05:item = A31` (shutters pass 34104/1336/36152/3384 or `1024 \| type`) | 0 | HIGH |
| 0C48 | act48_Signal [named here] | A31 n | `send_signal(A31)`; unqueued | 0 | HIGH |
| 0C49 | act49_Attack [named here] | A33 target or 0 | `A30.attack(A33 or A30.f22:target)`; on Nil result re-queues act 170 against it | 0 | HIGH |
| 0C4A | act4A_Nop [named here] | — | `return True`; unqueued | 0 | HIGH |
| 0C4B | act4B_CastSelf [named here] | A31 spell type | if `R0901(A30, Nil, A31)`: temp spell prop `create_prop(28,0,A30,0,A31,0,0)`, `.use()`, "X casts …" if in party, delete | 0 | HIGH |
| 0C4C | act4C_CastAt [named here] | A31 spell, A33 target | as 0C4B plus `use_on(target)`; if spell prop `sel54[0] != 0` sends target `sel67` (provoked) | 0 | HIGH |
| 0C4D | act4D_Nop [named here] | — | `return True`; unqueued | 0 | HIGH |
| 0C4E | act4E_Use [named here] | A31 prop | `A31.use()` | 0 | HIGH |
| 0C4F | act4F_UseOn [named here] | A31 prop, A33 | `A31.use_on(A33)` | 0 | HIGH |
| 0C50 | act50_Sel11 [named here] | A31 prop, A32, A33 | `A31.sel11(A32, A33)`; unqueued | 0 | HIGH |
| 0C51 | act51_Sound [named here] | A31 x, A32 y, A33 id | `positional_sound(A33, A31, A32)` | 0 | HIGH |
| 0C52 | act52_SetActivity [named here] | A31 | `A30.f15:activity = A31` | 0 | HIGH |
| 0C53 | act53_SetTarget [named here] | A33 | `A30.f22:target = A33` | 0 | HIGH |
| 0C54 | act54_Wield [named here] | A33 item | `R0EB7(A30, A33)` | 0 | HIGH |
| 0C55 | act55_SetF2B [named here] | A33 | `A30.f2B = A33`; **returns 0, not True** (`@0009 8b 41 00 40`) | 0 | HIGH |
| 0C80 | ServeCustomers [named here] | A30 server, A31 customers, A32 bar x/y, A33 lines, A34 spots; Bool | first listed character with flag bit 6 (`@001D R0F02(L00, 6)` = the party bit 64 of 0F13) or bit 7 → queue wait / "Right away!" / walk to bar / approach / "There you go" / act 167 …; False if nobody waiting | 2 (1829 182D) | MED |
| 0C81 | OpenShutters [named here] | A30, A31 props; Bool | first `find_unique_prop` with frame 1 → approach, "These should be open", act 71 with 34104 (mirror) or 1336 | 1 (1829) | MED |
| 0C82 | CloseShutters [named here] | A30, A31; Bool | same for frame 3, "These should be closed", 36152/3384 | 1 (1829) | MED |
| 0C83 | FixProp [named here] | A30, A31; Bool | frame-1 prop → act 71 with `1024 \| type`, "That's better" | 2 (1829 182D) | MED |
| 0C84 | StartChore4 [named here] | A30, A31 bubbles, A32 lines | bubble from A31, `R0F00(A30, 4)`, act 166 (A30, 4, False), say from A32 | 1 (1834) | MED |
| 0C85 | StartChore5 [named here] | A30, A31, A32 | as 0C84 with bit 5 and a trailing wait 40 | 3 (3) | MED |
| 0C86 | Errand [named here] | A30, A31/A32/A34 x-y pairs, A33/A35 unique props | random route between spots; **`@005F queue_activity(A30, 66, 5)` under-supplies x/y/value** (script-vm §8) | 2 (181E 1844) | HIGH bytes / MED meaning |

## 6. Page 0x0D — money and signal reactions (10 routines, 936 B)

Money = props carrying property `sel60` (coin value); purse value = Σ `sel60[0] × count` [HIGH from
`0D01 @0029 set L00 = (L00 + (prop(L01, sel60, 0) * L01.f09:count))`]. Item 130 = obol (0D09) [MED].

| id | name | sig | behaviour | calls (segs) | conf |
|---|---|---|---|---|---|
| 0D01 | Purse [named here] | A30 char; int | Σ value×count over `iterate_descendants(A30)` | 8 (8) | HIGH |
| 0D02 | Pay [named here] | A30 char, A31 amount | deletes coin stacks until paid; partial stack gets `count = (L04 - (A31 / value))` where L04 = value×count — **mixes value and count units** unless value = 1 (`@003B`) | 8 (7) | HIGH |
| 0D03 | PayWeight [named here] | A30, A31; int | weight of the coins 0D02 would take (via `weight_if_added`, whose char/item argument quirk applies: script-builtins B8); only callers are dead → **transitively dead** | 4 (4) | HIGH |
| 0D04 | PartyPurse [named here] | —; int | Σ R0D01 over `iterate_party(…, True)` | 32 (17) | HIGH |
| 0D05 | PartyPay [named here] | A30 amount | pays from each member in turn via R0D02 | 26 (16) | HIGH |
| 0D06 | TheftReaction [named here] | A30 char, A31 signal | 256 and leader visible → bubble "Hey! Stop that!"/… and `send_signal(320)`; 321 and visible → target leader, activity 6 | 5 (5) | HIGH bytes / MED meaning |
| 0D07 | GuardSignal [named here] | A30, A31 signal | 256 → R0D06; 320 or 321 → target leader, activity 6 (§10.5) | 8 (8: 7 dict + 3015) | HIGH |
| 0D08 | Nop0D08 [named here] | A30, A31; 0 | `@0003 return 0`; unreached | 0 | HIGH |
| 0D09 | GiveMoney [named here] | A30 char, A31 n | `give_item(A30, 130, 0, n)`; overflow beyond `free_capacity` dropped at feet as `create_prop(1, x, y, 0, 130, 0, rest)` ("Some money falls to the floor.") | 4 (3) | HIGH |
| 0D0A | SplitMoney [named here] | A30 amount | divides by `G07:party_size7`, remainder 1 each to the first members, via R0D09 | 2 (2) | HIGH |

## 7. Page 0x0E — game-rule helpers (66 routines, 17,989 B)

Names in quotes come from 0x0101 (`[from 0x0101 symtab]`, mapping MED per census §2); the rest are
`[named here]`.

### 7a. Liquids, doors, containers, displays (0E0A–0E67)

| id | name | sig | behaviour | calls (segs) | conf |
|---|---|---|---|---|---|
| 0E0A | PourWater [named here] | A30 target; Bool | flour 167→168 (skill 208 else lost), pitcher 160 quality 1, bucket 120→121, distiller 233→234 (skill 210) | 5 (4) | HIGH |
| 0E0B | PourMilk [named here] | A30; Bool | churn 172 → butter (`create_prop(16,0,leader,0,132,0,0)`), pitcher quality 2, bucket →122 | 2 (2) | HIGH |
| 0E0C | PourOil [named here] | A30; Bool | lamp 143: quality := 60 (or 188 keeping bit 128) if `(quality & -129) < 60` | 2 (2) | HIGH |
| 0E0D | PourWine [named here] | A30; Bool | pitcher: prints "now filled with wine" and returns True **without setting quality** (`@003C`…`@0061 return True`) | 3 (3) | HIGH |
| 0E40 | "DoDoor" | A30 door, A31–A38 frames; 0 | fires+deletes children with `kind & 2` via `use_on(G09)`; toggles A31↔A33 / A32↔A34; A35/A36 "Locked!", A37/A38 "Magically Locked!" | 9 (7) | HIGH |
| 0E41 | "DoToggle" | A30, A31–A34 | frame A31↔A32, A33↔A34 | 15 (8) | HIGH |
| 0E42 | "DoLockable" | A30, A31–A34 | A32→A31, A31→A32, A33 "It is locked.", A34 "magically locked" | 2 (2) | HIGH |
| 0E43 | "DoKey" | A30 key, A31 offset (255 = lockpick), A32 lock | key fits if `A32.quality == A30.quality + A31` → `A32.sel53()`; lockpick: fails if `reflex+rand(0,19) < 20+rand(0,19)+((q+19)/20)·5` → "The lockpick broke.", count−1 | 3 (3) | HIGH |
| 0E44 | "DoToggleLock" | A30, A31–A38 | A35→A33 / A36→A34 "now unlocked"; A33,A31→A35 / A34,A32→A36 "now locked"; A37/A38 magic | 5 (5) | HIGH |
| 0E45 | "DoVolumeCheck" | A30 box, A31 cap, A32 item; Bool | content weight + item > A31 → "It doesn't fit."; **dead** | 0 | HIGH |
| 0E46 | "DoFood" | A30 food, A31 heal, A32 taste; 0 | leader heals A31 (×1.5 / 0 by taste roll), prints one of 7 taste lines `L03[A32]`, count−1; **dead** | 0 | HIGH |
| 0E47 | "DoClock" | A30, A31 mode bits; 0 | clock/sundial time text; afternoon branch prints "It is  in the afternoon." with no hour (`@0113`); **dead** | 0 | HIGH |
| 0E48 | "SpillOut" | A30 container, A31 lead text, A32 Bool | lists children ("A31 a, b" / " nothing."); with A32 moves them to A30's x,y, clears kind bit 8 | 5 (4) | HIGH |
| 0E49 | BashDoor [named here] | A30 door, A31 force, A32–A39 frames | trap children; `A31 > sel52[0]·5` destroys (kind \|= 2); `A31 > byte7` opens; else byte7−1 / "doesn't budge"; unlocked doors just open | 4 (4) | HIGH |
| 0E4A | BashContainer [named here] | A30, A31 force, A32–A35 frames, A36 toughness | `A31 > A36·3` destroys (kind \|= 128) and `R0E48(A30, "It contained", True)`; else busts/dents | 2 (2) | HIGH |
| 0E64 | "DisplaySign" | A30 obj, A31 text, A32, A33–A37 rect | `sysnew_window` + text widget (`f41 = A32`) unless already shown | 11 (7) | HIGH |
| 0E65 | "DisplayScroll" | A30, A31, A32–A36 | window + scroll widget `sysnew_07` | 3 (3) | HIGH |
| 0E66 | "DisplayContainer" | A30, A31–A35 | trap children, then window + container widget `sysnew_0B` | 18 (10) | HIGH |
| 0E67 | "DisplayInstrument" | A30, A31–A38 | window + A38 key widgets `sysnew_0A`; **dead** | 0 | HIGH |

### 7b. Character statistics, combat, magic (0E80–0E90, 0EA1–0EA3, 0EB5, 0EB8)

Skill numbers ⚑ corrected (wave 1 2026-10-03): the class-0x50 `name` methods `1AC0 @0005 return
"Attack"` … `1AD6 @0005` name all 23 (192 Attack, 193 Defense, 194 Mana, 195 Casting, 196–198 Sword/Axe/
Mace, 199 Barehand, 200 Missile, 201 Shield, 202 Traps, 203 Persuasion, 204 Haggling, 205 Awareness,
206 Fishing, 207 Gambling, 208 Cooking, 209 Weaving, 210 Alchemy, 211 Runic Magic, 212 Healing Magic,
213 Lock Picking, 214 Thievery) [HIGH; combat §3, magic §6]; their roles below are read from use sites.

| id | name | sig | behaviour | calls (segs) | conf |
|---|---|---|---|---|---|
| 0E80 | BestWeaponDamage [named here] | A30; int | max `sel42[0]` over equipped, floor 1; **dead** | 0 | HIGH |
| 0E81 | ArmourTotal [named here] | A30, A31 dmg flags; int | Σ `sel44[0]` of equipped (flag 4096: only `p26 & 8` items; flag 2048: `p26 & 0` — **never true**, `@0056`); ability 20 adds 1+rand(0,4) | 1 (3040) | HIGH |
| 0E82 | MaxHealth [named here] | A30; int | `body + reflex/2 + level + (L01·5·reflex)/15`, L01 = skill 193 or R0E95 | 2 (2) | HIGH |
| 0E83 | MaxMagic [named here] | A30; int | `mind + (skill 194 or R0E96)`, 0 when both 0 | 3 (3) | HIGH |
| 0E84 | CombatBonus [named here] | A30, A31 defending?; int | skill 192 (attack) / 193 (defence), else R0E95; non-char 0 | 4 (2) | HIGH |
| 0E85 | SpellPower [named here] | A30; int | skill 195 or R0E96 | 9 (9) | HIGH |
| 0E86 | LevelUp [named here] | A30, A31 levels | level += A31; rescales health/magic to new maxima; `training += (6 - G11)·A31` — G11 reads Nil (GetGlobal `default: *param_1 = *(uint *)PTR_DAT_100cdbb0;`) and DoExpr case 0x4b pushes the left operand when either tag is non-integer (`else { … *(uint *)(iVar8 + sVar18 * 4) = uVar17; }`, `.DoExpr__7TInterpFRPUc @ 1007ddfc` in the main dump), so **+6·A31** ⚑ corrected (wave 1 2026-10-03; combat §13.2) | 4 (3) | HIGH |
| 0E87 | ResolveHit [named here] | A30 att, A31 def, A32 weapon/Nil, A33 to-hit, A34 dmg die; Bool | parry, damage words, armour, damage, XP (§10.6) | 2 (0E88 0E89) | HIGH |
| 0E88 | MeleeAttack [named here] | A30, A31, A32 weapon/Nil, A33 dmg; Bool | to-hit = reflex (body if cls48 `f33&1`) [+skill 199 unarmed] + rand(0,30) − (def.reflex + rand(0,30)) + R0E84(att,F) − R0E84(def,T) → R0E87; non-char target → R0E8F | 2 (3042) | HIGH |
| 0E89 | MissileAttack [named here] | same | as 0E88 with reflex + skill 200 (to-hit and damage) | 2 (3042) | HIGH |
| 0E8A | CanLearnSpell [named here] | A30, A31 spell level; Bool | known-skill count (types 0–127) ≥ R0EB5 → "can't learn another"; A31 > R0E85 → "beyond your current skills" | 1 (301A) | HIGH |
| 0E8B | GainExp [named here] | A30, A31 xp | exp += A31 capped 65535; `exp > 2^(level−1)·100` → `R0E86(A30, 1)` (§10.7) | 48 (32) | HIGH |
| 0E8C | DistSq [named here] | A30, A31; int | dx² + dy² | 5 (5) | HIGH |
| 0E8D | DeathEffects [named here] | A30 corpse; 0 | remains prop `create_prop(33, x, y, random(0,4), 77, 0, 0)` if cls48 `f32 & 16384` — type 77 = "blood" (`104D` header `tile-name "blood"`) ⚑ corrected (wave 1 2026-10-03); group flags if `& 8192`; Hero kill → `G0C += L05[cls48.f35]` (karma) | 4 (4) | HIGH bytes / MED karma |
| 0E8E | SplitExp [named here] | A30 xp | R0E8B(member, A30/G07) for each member; **dead** | 0 | HIGH |
| 0E8F | HitObject [named here] | A30, A31 obj, A32 weapon, A33 die | `A31.sel65(rand(0,A33)+1, weapon sel42[2] or sel45[2])` | 2 (0E88 0E89) | HIGH |
| 0E90 | AttrBonus [named here] | A30 attr; int | `(A30 − 12) / 4` | 4 (3042) | HIGH |
| 0EA1 | CastCheck [named here] | A30 caster (0 = none), A31 spell level, A32 mana; Bool | §10.8 | 49 (49) | HIGH |
| 0EA2 | DrunkParty [named here] | A30 strength | each member: `rand(0,6) + 3·A30 > body + level` → temp ability 21 for (A30+2)·3 (cured by 0A05) | 7 (7) | HIGH bytes / MED "drunk" |
| 0EA3 | MonsterCastAI [named here] | A30 caster, A31 target; Bool | picks from weighted `sel68` spell list (3 tries), filters by spell `sel54[0]` kind vs flee state (activity 7, 4, low health), casts on self/target, provokes target; False if no `sel68` | 1 (3042) | HIGH |
| 0EB5 | MaxSpells [named here] | A30; int | `mind/2 + level + 4·(skill 195 or R0E96)` | 5 (4) | HIGH |
| 0EB8 | ApplyDamage [named here] | A30 victim, A31 dmg, A32 flags, A33 source/Nil | `A31 = A30.sel64(A31, A32)` (absorb); if > 0: `A30.sel65(A31, A32)` and XP to A33 as 0E87 | 16 (12) | HIGH |

### 7c. Trade, haggling, training, misc (0E91–0E96, 0EA4–0EB4, 0EB6–0EB7)

| id | name | sig | behaviour | calls (segs) | conf |
|---|---|---|---|---|---|
| 0E91 | BuyOne [named here] | A30 prompt, A31 price, A32 item; Bool | `who_will_prompt`, money and room checks, R0D02, `give_item`; **dead** | 0 | HIGH |
| 0E92 | BuyMany [named here] | A30, A31 unit price, A32 per-unit count, A33 item; Bool | asks how many (0–200); checks `A31·n` but **pays `R0D02(L00, A31)` once** (`@011D`); **dead** | 0 | HIGH |
| 0E93 | Sleep [named here] | A30 hours, A31/A32 bed x/y, A33 bed quality | snapshots party HP/MP, `pass_time(1024)` ×4·A30, owner in bed kicks you out; A33 = 0 → no rest; else boosts gains ×A33/2 — magic is tested and capped against **health_max** (`@0214`, `@0243`) | 1 (100E) | HIGH |
| 0E94 | BuyFromMenu [named here] | A30, A31 prices, A32 items, A33 names; Bool | menu via R0EA6, index 0 = cancel; room test **subtracts** coin weight (0E91 adds); **dead** | 0 | HIGH |
| 0E95 | ClassBonusA [named here] | A30; int | switch `ce1D & 3` → 0, level/2, level, 2·level | 3 (2) | HIGH |
| 0E96 | ClassBonusB [named here] | A30; int | same on `(ce1D >> 2) & 3` | 3 (3) | HIGH |
| 0EA4 | BuyManyFromMenu [named here] | A30, A31, A32, A33; Bool | as 0E94 with quantity, pays `L03·L04`; **dead** | 0 | HIGH |
| 0EA5 | Shop [named here] | A30 title, A31 stock, A32 price factor (tenths), A33 haggle lines/Nil; new factor | §10.2 | 23 (22) | HIGH |
| 0EA6 | PickName [named here] | A30 list; index | `pick_item(Nil, "%s", A30, Nil)`; callers dead → **transitively dead** | 2 (0E94 0EA4) | HIGH |
| 0EA7 | HaggleText [named here] | A30 base, A31 factor, …; | text-only haggle loop; `pick_item("Haggle", "%s", blk@0037)` passes **3 of 4** args; no accept path; **dead** | 0 | HIGH |
| 0EA8 | HaggleButtons [named here] | A30 buttons, A31 line sets, A32 out map, A33 exclude | fills 3 reply buttons with distinct random categories ≠ A33 (`f3D` text, `f40` True) | 2 (0EA5) | HIGH |
| 0EA9 | SellToMerchant [named here] | A30 title, A31 wanted list, A32 factor (0 → 10); factor | gathers matching party items, window with quantity, pays `R0D0A(total)` and removes stacks; reads `len(L02)` **after** `release L02` (`@0373`/`@0376`) | 2 (1810 1823) | HIGH |
| 0EAA | DirectionsFrom [named here] | A30 speaker, A31 x, A32 y, A33 scale | `R0EAB(A30.x, A30.y, A31, A32, A33)` | 1 (0816) | HIGH |
| 0EAB | PrintDirections [named here] | x0, y0, x1, y1, scale | integer √dist·scale/10 → "just over there"/"about N paces"/"over one hundred paces"/"around two hundred paces"; 16-point compass; " of here" only when beyond 300 | 1 (0EAA) | HIGH |
| 0EAC | SkillLevel [named here] | A30 char, A31 skill; int | `find_skill`; frame if bit 16 clear, else 0; none → 0 | 29 (17) | HIGH |
| 0EAD | PendingSkill [named here] | A30, A31; int/Nil | frame&15 if bit 16 set, 0 if clear, Nil if absent | 2 (1802) | HIGH |
| 0EAE | CanTrain [named here] | A30, A31 skill, A32 is-spell; Bool | pending → True; known spell → False; mastery 15 → False; else `training > 0` | 4 (4) | HIGH |
| 0EAF | Train [named here] | A30, A31, A32; Nil/string | pending → clear bit, `init`, R0E86(A30,0); else spends 1 training: frame+1 or new skill prop (frame 1 for spells, 0 else); error strings | 4 (4) | HIGH |
| 0EB0 | PrintLines [named here] | A30 list, A31 name | prints each element, Nil → A31 | 6 (0EB1) | HIGH |
| 0EB1 | TrainDialogue [named here] | A30 trainee, A31 trainer name, A32 skill, A33 spell?; skill/Nil/False | known/mastered messages, "You need some more experience…", R0EAF and the skill's `sel54` lines | 14 (10) | HIGH |
| 0EB2 | AppraiseWeapon [named here] | A30, A31 item | damage words from `sel42[0]` ("graze"… "shred") | 2 (1806 1822) | HIGH |
| 0EB3 | AppraiseArmour [named here] | A30, A31 | same scale on `sel44[0]·2` | 2 (2) | HIGH |
| 0EB4 | AppraiseParry [named here] | A30, A31 | "can parry a … blow" from `sel47[0]−1` | 2 (2) | HIGH |
| 0EB6 | DescribeFor [named here] | A30 char, A31 prop; Bool | prints `sel51[0]` if `sel51[1]` is Nil or lists A30 | 3 (3) | HIGH |
| 0EB7 | NpcWield [named here] | A30 char, A31 item; Bool | hand budget 2 (`p26` 4/3 = one hand, 5 = two): unequips to make room, `A31.wield(A30)`; final `setfield L03.f00:kind = 24` writes the **iterator variable**, not A31 (`@0236`) | 1 (0C54) | HIGH bytes / MED slot meaning |

## 8. Page 0x0F — bit/field helpers (22 routines, 517 B)

All `as_char(A30)` then one field op; names 0F00–0F13 from 0x0101 [HIGH bodies, MED names].

| id | name | sig | behaviour (key line) | calls (segs) | conf |
|---|---|---|---|---|---|
| 0F00 | "setbit" | A30 char, A31 bit; 0 | `@0009 L00.f13:flags = (L00.f13:flags \| (1 << A31))` | 246 (107) | HIGH |
| 0F01 | "clrbit" | A30, A31; 0 | `flags & ~(1 << A31)` | 17 (12) | HIGH |
| 0F02 | "tstbit" | A30, A31; Bool | `@0009 return ((L00.f13:flags & (1 << A31)) != 0)` | 297 (84) | HIGH |
| 0F03 | "setworktype" | A30, A31 | `activity = A31`; dead | 0 | HIGH |
| 0F04 | "getworktype" | A30; int | `return activity`; dead | 0 | HIGH |
| 0F05 | "heal" | A30 | `health = health_max`; dead | 0 | HIGH |
| 0F06 | "curepoison" | A30 | `status & -3`; dead | 0 | HIGH |
| 0F07 | "raisedead" | A30 | `status \| 1; health = health_max`; dead | 0 | HIGH |
| 0F08 | "enhorse" | A30 | `status \| 4`; dead | 0 | HIGH |
| 0F09 | "adjint" | A30, A31; int | `mind += A31`, returns mind; dead | 0 | HIGH |
| 0F0A | "adjdex" | A30, A31; int | `reflex += A31`; dead | 0 | HIGH |
| 0F0B | "adjstr" | A30, A31; int | `body += A31`; dead | 0 | HIGH |
| 0F0C | "adjexp" | A30, A31; int | `exp += A31` (no cap, no level-up, unlike 0E8B); dead | 0 | HIGH |
| 0F0D | "adjlevel" | A30, A31; int | `level += A31` (no rescale, unlike 0E86); dead | 0 | HIGH |
| 0F0E | "getinjury" | A30; int | `health_max − health`; dead | 0 | HIGH |
| 0F0F | "ispoisoned" | A30; int | `status & 2`; dead | 0 | HIGH |
| 0F10 | "ishorsed" | A30; int | `status & 4`; dead | 0 | HIGH |
| 0F11 | "deckarma" | A30 n | `G0C = G0C − A30` (SetGlobal clamps 0..100) | 2 (1811 185D) | HIGH |
| 0F12 | "inckarma" | A30 n | `G0C = G0C + A30` | 2 (2) | HIGH |
| 0F13 | "inparty" | A30; int | `@0009 return (L00.f13:flags & 64)` | 64 (36) | HIGH |
| 0F14 | AddSkill [named here] | A30 char, A31 type; prop | `create_prop(28, 0, A30, 0, A31, 0, 0)` (kind 0x1C skill, as 0C4B/0EAF); dead | 0 | HIGH bytes / MED name |
| 0F15 | SetTimer [named here] | A30 owner (location), A31 type, A32 byte 6 (countdown), A33 byte 7; prop | `create_prop(66, 0, A30, 9, A31, A32, A33)` = kind 0x42 frame 9 countdown trigger (data-format §4.3; fires selector 21 at the owner with the prop, schedules §7.1). ⚑ corrected (wave 1 2026-10-03): all 8 sites are `R0F15(1, k, d, 0)` — `42 00 01` = 1 (the Hero), k 0–8 = vision type, d ∈ {5, 2, 1}: 1025 @012A (1,1,5,0), @0290 (1,8,2,0), @035C (1,3,1,0); 1401 @00AF (1,4,2,0); 1408 @002B (1,5,2,0); 141D @0041 (1,7,2,0); 1502 @0033 (1,6,2,0); 1802 @199C (1,0,2,0) (quests §6) | 8 (6) | HIGH |

## 9. Page 0x30 — default handlers (40 routines, 4,224 B)

Native senders from the raw `bl`+`li r4` scan (count of sites): 0 (2), 1 (1), 2 (9), 3 (1), 4 (3),
5 (1, DoInterp×3), 7 (1), 8 (4), 9 (3), 10 (3), 11 (1), 12 (2), 13 (1), 14 (3), 15 (1), 16 (1), 17 (1),
20 (4), 21 (20), 23 (2), 24 (1), 25 (1), 26 (2), 27 (3), 28 (3), 29 (2), 31 (4), **32 (2: 0x1004fa70,
0x1004c3e4)**, **33 (1: 0x1004d554, 5-arg)** [MED: heuristic] — ⚑ corrected (wave 1 2026-10-03):
0x1004c3e4 and 0x1004d554 lie in `DoMove`, 0x1004fa70 in `HatchEgg` (`tb.py --at`). Script 0x9D sends: census §5. Selectors
18, 19, 61, 62 have **no** sender of either kind; every shipped `sel6` receiver is a `sysnew_01` list
(handled natively), so 3006 is unreached too.

| id | selector (name) | sig | behaviour | reach | conf |
|---|---|---|---|---|---|
| 3000 | 0 init | A30 | forwards `init(A30)` to the object's class-0x48 record if any | native 2 + script 3 | HIGH |
| 3001 | 1 [unnamed] | A30; 0 | `return 0` | native 1 | HIGH |
| 3002 | 2 name | A30; Nil | `return Nil` | native 9 + 46 | HIGH |
| 3003 | 3 len | A30; 0 | `return 0` | native 1 (`Len`) | HIGH |
| 3004 | 4 index | A30, A31 | prop with `f11:has_frame` → `f12:frame_dict[A31]`, else Nil | native 3 + 4 | HIGH |
| 3005 | 5 atput [named here] | A30, A31, A32 | `frame_dict[A31] = A32` for props | native 1 | HIGH bytes / MED name |
| 3006 | 6 append [named here] | A30, A31; 0 | `return 0`; **unreached** (all sends hit lists) | none | MED |
| 3007 | 7 first_visit | A30 | characters: "^X is working/sleeping/eating/farming/sitting/standing still/nearby." or "The body of X is nearby."; props "X is nearby." — reads as a look/notice default [MED] | native 1 + 2 | HIGH |
| 3008 | 8 search | A30 | char → `R0E48(A30, "They are carrying", False)`, else `R0E48(A30, "Searching reveals", True)` | native 4 + 9 | HIGH |
| 3009 | 9 use | A30; 0 | `return 0` | native 3 + 14 | HIGH |
| 300A | 10 use_on | A30, A31; 0 | `return 0` | native 3 + 13 | HIGH |
| 300B | 11 use_at [named here] | A30, A31 x, A32 y; 0 | `return 0` (native sender passes obj, x, y) | native 1 + 2 | HIGH / MED name |
| 300C | 12 talk | A30 | "You are met with stony silence." | native 2 + 3 | HIGH |
| 300D | 13 wield | A30; 0 | `return 0` | native 1 + 1 | HIGH |
| 300E | 14 take_drop_14 | A30; 0 | `return 0` | native 3 + 2 | HIGH |
| 300F | 15 take_drop_15 | A30 item; Nil/True/False | ownership check: zone **having** `sel36` → Nil (`@000A jf has(L00, sel36/p_weight) -> 0018` falls into `return Nil`); leader with neither skill 205 nor 214 → True; else window "That doesn't seem to belong to you…" ("…watching you 'borrow' that…" with 214) Take/Steal → True, Leave → False; Steal then gets one `random(0, 6) == 3` chance per skill-214 level to return Nil (unseen) before returning True. TakeCommand: False aborts, Nil takes quietly, other → `SendSignal(0x100)` (`TakeCommand @ 10053fd8`) | native 1 | HIGH |
| 3010 | 16 take_drop_16 | A30; 0 | `return 0` | native 1 | HIGH |
| 3011 | 17 take_drop_17 | A30; 0 | `return 0` | native 1 | HIGH |
| 3012 | 18 [unnamed] | A30; True | `return True`; **unreached** | none | MED |
| 3013 | 19 [unnamed] | A30; True | `return True`; **unreached** | none | MED |
| 3014 | 20 enter | A30; 0 | `return 0` | native 4 | HIGH |
| 3015 | 21 signal | A30, A31 | 256 in a `sel36` zone → ignore; characters: cls48 `f35 == 0` → R0D06, `== 2` → R0D07 | native 20 + 4 | HIGH |
| 3017 | 23 [unnamed] | A30, A31; False | `return False` | native 2 | HIGH |
| 3018 | 24 take_drop_24 | A30; True | `return True` | native 1 | HIGH |
| 3019 | 25 take_drop_25 | A30 | deletes the prop if `p_typeflags27[0] & 16` | native 1 | HIGH |
| 301A | 26 can_learn [named here] | A30 spell, A31 char; Bool | prerequisite skill `sel51[1]` missing → "You haven't mastered the prerequisites (…)" False; type ≥ 192 → True; else `R0E8A(A31, sel51[0])` | native 2 + 2 | HIGH |
| 301B | 27 wield_slide | A30, A31; 0 | `return 0` | native 3 | HIGH |
| 301C | 28 attack | A30, A31; delay/Nil | §10.9 | native 3 + 2 | HIGH |
| 301D | 29 death | A30, A31 | §10.9 | native 2 + 1 + static 1 (1801) | HIGH |
| 301F | 31 moved | A30, A31 terrain/prop | −5..−2: 1-in-9 (`random(1, 10) == 3`) snake bite (unless ability 31 / cls48 `f32&64`): "Ouch! Something bit me!", ability 9, `sel65(1, 2)`; −221: "Ouch! That's hot!", `sel65(rand(0,4)+1, 8)` unless ability 23 / `f32&128`; else `prop.use_on(A30)` | native 4 | HIGH |
| 3020 | 32 spawned | A30; False/0 | §10.10 | native 2 + 1 + static 18 (17) | HIGH |
| 3021 | 33 activity_step [named here] | A30–A34 | `return R[0C00+A31](A30, A32, A33, A34)` (§5) | native 1 | HIGH |
| 3035 | 53 toggle_lock [named here] | A30; 0 | `return 0` (0E43 sends `A32.sel53()`) | script 2 | HIGH / MED name |
| 3039 | 57 dig [named here] | A30 | "You can't dig here!" | script 2 | HIGH |
| 303D | 61 [unnamed] | A30, A31; 0 | `return 0`; **unreached** | none | MED |
| 303E | 62 [unnamed] | A30, A31; False | `return False`; **unreached** | none | MED |
| 3040 | 64 absorb [named here] | A30 victim, A31 dmg, A32 flags; int | cls48 immunity/resistance bits (`f33`, `f32`) zero/halve/double; ability 23 blocks fire (flag 8); then `A31 − rand(0, f30 + R0E81 + 1) − rand(0, skill193 + 1)`, floor 0 | script 2 (0E87, 0EB8) | HIGH |
| 3041 | 65 take_damage [named here] | A30, A31 dmg, A32 flags | removes ability 22, may break ability 14 (`random((A31 + 20)) < A31` — **one-argument random**, stale slot, script-vm §8); "killed!" (health 0) / "Critically wounded!" / "Wounded" + sounds from `sel59`; flag 256 poisons (ability 9) unless cls48 `f32&64` | script 5 + static 1 (1036) | HIGH |
| 3042 | 66 strike [named here] | A30, A31; Bool | §10.11 | script 2 (301C) | HIGH |
| 3043 | 67 provoked [named here] | A30 victim, A31 aggressor | `f2A = A31`, activity := behaviour; Hero/party victims rally the idle party; party aggressor vs non-party cls48 `f35` 0/2 → `send_signal(321)` | script 8 | HIGH |

## 10. Heavy routines — detail (calls × bytes)

### 10.1 0x0816 WhereIs and the 330-byte table at 0801 @0AEE [HIGH]
The task's "330-byte 0x45 table" is the **argument** block, not inside 0816: `0801 @0AE7 9f 08 16 30
45 01 4a 90 06 … call R0816(A30, blk@0AEE, 10)`, block 0AEE–0C38 = 330 B, `.array[6]` of 6-field
entries `[cond, label, text…, x, y, text]` (e.g. `[0] Nil [1] "LandKing Hall" [2] "LandKing Hall lies "
[3] 163 [4] 20 [5] "."`). 0816 builds a menu list, per entry:
```
0060: 82 08 07 41 00 46 40          set   L08 = L07[0]
0067: 8d 08 43 50 00 00 00 54 02 5c 40 00 …   jf ((L08 == False) && L02) -> 007C
007C:>82 08 9c ff ff 08 40 30 40 40          set   L08 = callx[L08](A30)
00CA:>8d 08 64 40 40 00 eb          jf    is_char(L08) -> 00EB
00EB:>8d 08 64 58 40 01 09          jf    is_room(L08) -> 0109
0118:>82 09 c0 44 44 69 72 65 63 74 69 6f …   set L09 = pick_item("Directions to Where?", "%p%s", L01, L00)
```
Condition semantics: Nil/True → listed; `False` → an *else* entry, listed only while the flag L02 is
set by the entry before it (a hidden entry sets L02); a character → hidden when the speaker *is* that character; a room → hidden when
`as_room(G12:room)` is that room. Then each field from index 2 prints; strings print, and two
consecutive non-strings (x, y) trigger `R0EAA(A30, x, y, A32)` → compass text. Across all 9 tables
(114 entries) `[0]` is Nil 56, character 35, room 20, False 2, and **one code pointer** (`080E @068F
[0] @0006 (code)`, a nested routine returning False for Opheltius or when `get_variable(3)` is set).
So the 0x9C FFFF site receives a **non-routine value in 113 of 114 entries**; the open stack-slot
question of script-vm §8 is exercised by shipped data [HIGH from listings].

### 10.2 0x0EA5 Shop (2602 B, 23 merchant calls) [HIGH]
R0EA5 = the player **buys** (trade-economy §3). ⚑ corrected (wave 1 2026-10-03), `grep -n 'R0EA5('
ghidra/cythera-scripts/*.txt`: 23 calls in 22 segments; 21 write `setfield A30.f27:ce17 = R0EA5("…",
blk, A30.f27:ce17, blk|Nil)`, so the merchant's price factor persists in CharEntry field 0x27; the
other two are `call` with a literal 10 — `186A @0447 call R0EA5("Cheese", blk@0455, 10, Nil)`, `1869
@0215 call R0EA5("Flax", blk@0221, 10, Nil)` — fixed factor 10, no haggling. The third literal-10 call
is the sell side, `1823 @0474 call R0EA9("Flax", blk@0480, 10)`. `@0003 jf (A32 < 9) -> 0010` / `@000B set A32 = 20` (a factor under 9,
e.g. a fresh 0, starts at 20 = 200 %). Stock entries are `[item, name, price, count]`;
`@0034 set L05 = L02[3]` / `@003B set L05 = callx[L05](L02)` — the counts are integers (71×1, 1×12 over
all 23 tables), so this callx always takes the **non-routine path** and yields the integer itself.
Price = `@0234 (((L07[4] * A32) + 9) / 10)`. With A33 = Nil no haggling (3 callers);
otherwise three reply buttons (R0EA8) move the factor by −1/−2 per good answer, floor 10 ("This is the
best I can do"), or end it: `@09E6 return (L00 + 1)` (insulted: factor +1). Normal exit `@0A23 return A32`.
Purchase: `R0D05(L15)` then `give_item(leader, L07[0], 0, (L07[3] * qty))`.

### 10.3 0x0813 TavernRumour [HIGH]
`@0003 jf (random(0, 4) == 2)` gates the fixed-line block; the table choice `@02A7 jf (random(0, 1) ==
0) -> 0630` is **always true** (`random(0,1)` is always 0), so zone 8/13 tables are always used there.
Final pick: max of A31 draws `random(0, len(L00))`, biasing towards later lines.

### 10.4 0x0C00 / 0x0C43 / 0x3021 dispatchers [HIGH]
```
0C00 0003: 82 00 31 30 62 15 46 40     set L00 = A31[A30.f15:activity]
0C00 000B: 8d 00 40 00 19              jf L00 -> 0019
0C00 0010: 8b 9c ff ff 00 40 30 40 40  return callx[L00](A30)
0C00 0019:>8b 9f 30 20 30 40 40        return R3020(A30)
0C43 0003: 8b 9c ff ff 33 40 30 31 32 40 40  return callx[A33](A30, A31, A32)
3021 0003: 8b 9c 0c 00 31 40 30 32 33 34 40 40  return R[0C00+A31](A30, A32, A33, A34)
```
0C00 is a `spawned` method body shared by 184E/1852/1853 whose A31 is a 1-key dictionary
(`key 140 @003A (code)` in 184E): the matching activity's code runs, anything else falls back to the
selector-32 default. Its callx only ever sees code (Nil is filtered by `jf`). 0C43 would call any
value queued with act 67, but no shipped `queue_activity` uses 67. 3021's `0x9C 0C00 <A31>` (seg +
int) can reach any segment 0x0C00+A31; shipped acts stay in 0x40–0x55 [HIGH literals; native-made
activities MED].

### 10.5 0x0D07 shared signal method and 0x0D06 [HIGH] (lines re-checked against `0d07.txt` ⚑ corrected (wave 1 2026-10-03))
```
0D07 0003: 8d 31 43 00 00 01 00 54 40 00 14   jf (A31 == 256) -> 0014
0D07 000E: 9f 0d 06 30 31 40                  call R0D06(A30, A31)
0D07 0014:>8d 31 43 00 00 01 40 54 31 43 …    jf ((A31 == 320) || (A31 == 321)) -> 003B
0D07 002D: 86 22 00 40 48 05 40               setfield L00.f22:target = G05:leader
0D07 0034: 86 15 00 40 41 06 40               setfield L00.f15:activity = 6
```
Dictionary users 102E, 1846–1849, 1864, 1865 plus 3015 when cls48 `f35 == 2`. Signal 256 is native:
TakeCommand calls `SendSignal(param_1,0x100)` when selector 15 returns neither False nor Nil. 0D06
(the `f35 == 0` default) protests ("Hey! Stop that!") and `send_signal(320)` (`0D06 @0077 c5 43 00 00
01 40 40`) — calling the 0D07 guards — and on 321 attacks only if `leader_can_see`. 321 comes from
3043 (party struck a non-party civilian). Activity 6 = attack target [MED].

### 10.6 0x0E87 ResolveHit (1073 B) [HIGH]
```
009D:>8d 33 41 00 51 40 03 a2       jf (A33 > 0) -> 03A2          ; to-hit ≤ 0 → "missed"
011B: 8d 33 00 4f 40 01 48          jf (A33 < L00) -> 0148        ; L00 = Σ rand over defender's sel47 parry items
0148:>82 09 ac 41 00 34 40 41 01 4a 05 4a …   set L09 = ((random(0, A34) + 1) + L05)
030C:>82 09 9d 40 31 09 0c 40 40    set L09 = A31.sel64(L09, L0C)  ; absorb (3040)
0360: 9d 41 31 09 0c 40             send A31.sel65(L09, L0C)       ; take damage (3041)
```
Damage words: <3 grazed, <6 hit, <9 hit hard, <12 very hard, <16 extremely hard, <20 crushed very
hard, <25 smashed…bonecrunching, <35 ground to dust, else shredded to pieces. XP to attacker via
R0E8B: level gap `L0F = def.level − att.level + 1`; L0F > 0 → min(damage, L0F); else 1 only if
damage > −L0F. Quirk: `@0081 set A33 = (A33 + R0EAC(A30, prop(L02, sel42, 3)))` reads **L02, the
defender-equipment iterator variable**, not the weapon A32 (same at `@008F` for A34) [HIGH bytes].

### 10.7 0x0E8B GainExp (48 calls) [HIGH]
`@0009 jf ((L00 + A31) < 65535) -> 0023` (cap), `@002D jf (A30.f1A:exp > ((1 << (A30.f1B:level - 1))
* 100)) -> 0048`, `@0041 call R0E86(A30, 1)`. One level per award.

### 10.8 0x0EA1 CastCheck (49 spell classes on page 0x1A) [HIGH]
Called as `R0EA1(A30.f0B:loc16, level, mana)`. Caster 0 → only `busy += 5 + A31`, True. Casters whose
class has `sel68` (monster spell list) cast free. Otherwise:
```
003F:>8d 32 30 62 1e 51 40 00 aa    jf (A32 > A30.f1E:magic) -> 00AA   ; else "requires more power"
00AA:>86 1e 30 40 30 62 1e 32 4b 40 setfield A30.f1E:magic = (A30.f1E:magic - A32)
00B4: 82 01 9f 0e 85 30 40 40       set L01 = R0E85(A30)
00BC: 86 23 30 40 30 62 23 41 0a 41 02 31 …   busy += (10 + (2 * A31))
00CC: 8d ac 41 00 01 40 ac 41 00 01 40 4a …   jf ((random(0, L01) + random(0, L01)) < random(0, A31)) -> 012A
```
Failure (mana already spent) prints "You failed to cast the spell." or bubble "Spell failed".

### 10.9 0x301C attack / 0x301D death defaults [HIGH]
```
301C 0057: 8d 9d 42 30 31 40 40 00 7c      jf A30.sel66(A31) -> 007C
301C 0060: 82 04 43 00 00 00 c0 30 62 18 4d 40   set L04 = (192 / A30.f18:reflex)
301C 006C: 86 23 30 40 30 62 23 04 4a 40   setfield A30.f23:busy = (A30.f23:busy + L04)
301C 008F: 86 23 30 40 30 62 23 41 0c 4a 40   (non-char target) busy += 12
301C 009A: 8b 41 0a 40                     return 10
```
Character target: if the Hero attacks, other party members' activity := behaviour (join the fight);
the strike (selector 66 → 3042) decides; delay = 192 / reflex, added to `busy` **and** returned
(TActiveMonster::DoAttack also stores an integer result as busy ticks, rules.md) — reflex 0 gives 0
(÷0 → 0). Failed strike → Nil. 301D: characters forward `death` to their cls48 record
(`@0015 9d 1d 00 30 40 send L00.sel29/death(A30)`); otherwise `@001E 9f 0e 8d 31 40 call R0E8D(A31)`.
Also called statically once (1801).

### 10.10 0x3020 spawned default (805 B, 18 static calls) [HIGH bytes / MED role]
Asleep (`@0010 activity == 145`): bed orientation for type 264 from adjacent props (item 3086/1038),
"Zzzz..." bubble and ambient sound 35. Awake: type 264 → `home`. Party members (`flags & 64`):
idle chatter when activity 3–13; `@01AF jf (A30.f28:food < 4)` → eats a carried 69/213/231 prop
(`@01EE send L00.sel10/use_on(A30)`) or complains; fatigue lines weighted by G0D². Others:
`@031B return L00.sel32/spawned()` (re-sent to the body prop's class). Native senders of 32 include one
inside `DoMove` (0x1004c3e4, `tb.py --at`; ⚑ corrected (wave 1 2026-10-03)), so this runs as a periodic idle tick, not only at hatch [MED].

### 10.11 0x3042 strike (654 B) [HIGH]
```
0009: 8d 30 60 44 00 60 44 5d 40 00 29   jf (has(A30, sel68) || has(L00, sel68)) -> 0029
0014: 82 01 9f 0e a3 30 31 40 40         set L01 = R0EA3(A30, A31)       ; casters try a spell first
0071: 9f 0e 88 30 31 03 03 61 2a 00 ac …  call R0E88(A30, A31, L03, (prop(L03, sel42, 0) + random(0, (R0E90(A30.f17:body) + 1))))
00AB: 8d 02 41 01 51 40 02 58            jf (L02 > 1) -> 0258
0258:>9f 0e 88 30 31 43 50 00 ff ff 00 62 …  call R0E88(A30, A31, Nil, (L00.f31 + random(0, (R0E90(A30.f17:body) + 1))))
0282: 9d 43 31 30 40                     send A31.sel67(A30)
```
Order: melee weapon (`sel42`, reach² ≥ dist²−1) → else at range: thrown weapon (`sel43`; the item
itself moves — on hit kind 9 inside the target, on miss kind 1 at the target's square) or launcher
(`sel46`) with matching ammo child (`sel45`), each via `missile_burst` + R0E89 → else adjacent
unarmed with cls48 `f31` damage. Any strike provokes the target (sel67 → 3043).

### 10.12 0x0F02 tstbit / 0x0F00 setbit / 0x0F13 inparty (607 calls together) [HIGH]
`0F02 @0009 8b 00 62 13 41 01 31 5a 56 41 00 53 … return ((L00.f13:flags & (1 << A31)) != 0)`: talk
methods open with `R0F02(A30, 1)` (script-vm §5 worked decode). Flags field 0x13 also holds the party
bit: `0F13 @0009 8b 00 62 13 41 40 56 40 return (L00.f13:flags & 64)` = bit 6. Literal bit numbers over
all `R0F00/R0F01/R0F02` calls: 0×53, 1×154, 2×84, 3×36, 4×21, 5×6, 6×1, 7×205 — the single bit-6 use
is `0C80 @001D R0F02(L00, 6)`, a party test spelled through tstbit. Bits 0–7 of field 0x13 are thus
per-character quest/conversation flags apart from bit 6 [HIGH counts; "quest flags" MED].

### 10.13 0x0801 CommonTopics (95 callers, 3149 B) — see §2 and §10.1 [HIGH]

## 11. Unreached in 1.0.4 (dead) — confirmed and corrected

Roots: all class segments (pages 0x10–0x1E), page 0x09, the 35 0x30 handlers with a sender, 0x0A00–07
(via 101F) and 0x0C40–0x0C55 (via 3021); closure over static calls. **36 dead**:
0814, 0B00, 0D03*, 0D08, 0E45, 0E46, 0E47, 0E67, 0E80, 0E8E, 0E91, 0E92, 0E94, 0EA4, 0EA6*, 0EA7, 0F03–0F10
(14), 0F14, 3006, 3012, 3013, 303D, 303E.
- Census §7 corrections: **0D03 and 0EA6 are transitively dead** (only callers 0E91/0E92/0E94/0EA4 are
  dead) though census counts them as called; census lists 37 uncalled 0x30 segments, but 32 of those
  are reached natively — only **3006, 3012, 3013, 303D, 303E** are dead. 0C40–0C55 are live through 3021
  but six are never exercised by shipped data (0C43, 0C45, 0C48, 0C4A, 0C4D, 0C50, §5).
- Census never-called lists for 0x08 (0814), 0x0D (0D08), 0x0E (11) and 0x0F (15, incl. 0F14) are
  confirmed; 0x0A's 8 are live via 101F; 0x0B00 dead.

## 12. Open items

1. ⚑ corrected (wave 1 2026-10-03) **Closed**: the 0x1004b824–0x1004d704 gap holds `DoMove` (0x1004B8E8, extent 0x1DEC),
   now in `Cythera_extra.decompiled.c` (CyDecompAt.java, extra-addrs.txt; schedules-npcs §0, §3.2):
   the 5-argument packing and the True-pops rule are in §5 (0C55's `0` leaves the entry queued).
2. script-vm §8 stack-leak question for 0x9C FFFF with non-routine targets is **live**: 0816 (113 of
   114 entries) and 0EA5 (every entry) take that path; the VM's handling of that path is not yet
   read from the code (⚑ corrected (wave 1 2026-10-03)).
3. ⚑ corrected (wave 1 2026-10-03) **Closed**: 0F15's location is 1 (the Hero) at every site (§8).
4. ⚑ corrected (wave 1 2026-10-03) **Closed**: `6 − G11` = 6 (DoExpr case 0x4b, §7b row 0E86).
5. Selector names left `[unnamed]` (1, 18, 19, 23, 61, 62) and the role of selector 7 for non-rooms.
6. ⚑ corrected (wave 1 2026-10-03) **Closed** for names (1AC0–1AD6 `name` methods, §7b); the roles of
   202–214 beyond their use sites in this library stay MED.
